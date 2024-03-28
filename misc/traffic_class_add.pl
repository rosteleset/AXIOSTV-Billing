#!/usr/bin/perl -w
#**********************************************************
=head1 NAME

 GEt peering networks

=cut
#**********************************************************


BEGIN {
  use warnings;
  use FindBin '$Bin';
  our %conf;

  require $Bin . '/../libexec/config.pl';
  unshift( @INC,
    $Bin . '/../lib/',
    $Bin . '/../',
    $Bin . '/../AXbills',
    $Bin . '/../AXbills/modules/',
    $Bin . "/../AXbills/" . $conf{dbtype} );
}

#TRaffic Class source - Class ID => Source URL
# 2 is first peer network
my %class_source = (
  #UA-IX
  2 => 'https://noc.ix.net.ua/ua-list.txt', #'http://noc.ua-ix.net.ua/ua-list.txt',
  #Crimea IX
  # 3 => 'http://193.33.236.1/crimea-ix.txt'
  # Belarus AX
  #2 => 'http://datacenter.by/ip/bynets.txt'
);

use strict;
use FindBin '$Bin';
use Encode;
use Sys::Hostname;
use AXbills::SQL;
use AXbills::Base qw(int2ip ip2int parse_arguments ssh_cmd load_pmodule check_time gen_time);
use Admins;
use Tariffs;
use Data::Dumper;
use Log;
use MIME::Base64;
use XML::Simple;
#use Sys::Syslog qw(:DEFAULT setlogsock);
use POSIX qw(strftime);

load_pmodule('SOAP::Lite');

my $WGET = 'wget -qO-';
if (-f '/usr/bin/fetch') {
  $WGET = '/usr/bin/fetch -q -o -';
}

my $IPFW    = '/sbin/ipfw';
my $debug   = 0;
my $version = 0.30;
our %conf;
our $base_dir;
my $begin_time = check_time();
my $argv    = parse_arguments(\@ARGV);
$debug      = $argv->{DEBUG} if ($argv->{DEBUG});

my $db = AXbills::SQL->connect($conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd}, { CHARSET => ($conf{dbcharset}) ? $conf{dbcharset} : undef });

my $Admin = Admins->new( $db, \%conf );
my $Log   = Log->new( $db, \%conf, { LOG_FILE => $base_dir . '/var/log/ros_com.log' } );

if($debug > 4) {
  $Log->{PRINT}=1;
}

$Admin->info( $conf{SYSTEM_ADMIN_ID}, { IP => '127.0.0.1' } );
if ( $Admin->{errno} ){
  print "AID: $conf{SYSTEM_ADMIN_ID} [$Admin->{errno}] $Admin->{errstr}\n";
  exit 0;
}
my $Tariffs = Tariffs->new($db, \%conf, $Admin);

if (defined($argv->{help})) {
  help();
}
elsif($argv->{type} && $argv->{type} eq 'ros_com') {
	my $return = 0;
  if(! defined($argv->{parse})) {
    $return = get_ros_com();
  }
  else {
    $return=1;
  }

  if($return) {
    my ($export_list, $export_domain) = ruscom_parse_xml();
    add_2_mikrotik($export_list,
      { EXPORT_LIST => $argv->{EXPORT_LIST},
        DOMAIN_LIST => $export_domain
      });
  }
}
else {
  get_networks();
}

#**********************************************************
=head2 get_ros_com()

=cut
#**********************************************************
sub get_ros_com {

  print "CORM fetch start\n" if ($debug > 2);
  my $openssl = '/usr/local/bin/openssl';

  # XXX dirty!!!
  binmode STDOUT, ':utf8';
  binmode STDERR, ':utf8';

  my %n;
  ($n{sec}, $n{min}, $n{hour}, $n{mday}, $n{mon}, $n{year}, $n{wday}, $n{yday}, $n{isdst}) = localtime(time());
  $n{year} += 1900;
  $n{mon}++;
  $n{mon}  =~ s/^(\d)$/0$1/;
  $n{mday} =~ s/^(\d)$/0$1/;
  $n{hour} =~ s/^(\d)$/0$1/;
  $n{min}  =~ s/^(\d)$/0$1/;
  $n{sec}  =~ s/^(\d)$/0$1/;
  my $dt = "$n{year}-$n{mon}-$n{mday}T$n{hour}:$n{min}:$n{sec}.000+04:00";
  my $dd = "$n{year}$n{mon}$n{mday}$n{hour}";
  #my $request_url = "http://www.zapret-info.gov.ru/services/OperatorRequest?wsdl";
  my $request_url = 'http://vigruzki.rkn.gov.ru/services/OperatorRequest/?wsdl';
  my $BASE = "/usr/axbills/var/db/zapret-info";
  my $reqfn    = "$BASE/request-$dd.xml";
  my $binfn    = "$BASE/request-$dd.bin";
  my $certfn   = "$BASE/cfg/cert.pem";

  my @dirs = (
    $base_dir .'/var/db',
    $BASE,
    $base_dir . '/var/db/zapret-info/',
    $base_dir . '/var/db/zapret-info/cfg',
    $base_dir . '/var/db/zapret-info/arch'
  );

  #make dirs
  foreach my $dir ( @dirs ) {
    if (! -d $dir) {
      print "Create '$dir'\n";
      mkdir $dir;
    }
  }

  if (! $conf{ROSCOM_NAME}) {
    print "Configure service\n";
    print q{
  $conf{ROSCOM_NAME}
  $conf{ROSCOM_INN}
  $conf{ROSCOM_OGRN}
  $conf{ROSCOM_EMAIL}
    };
    exit;
  }

  $conf{ROSCOM_NAME} = decode('cp1251',$conf{ROSCOM_NAME});

  my $xml_requset = "<?xml version=\"1.0\" encoding=\"windows-1251\"?>\n"
  . "<request>\n\t<requestTime>$dt</requestTime>\n"
  . "<operatorName>". $conf{ROSCOM_NAME} ."</operatorName>\n"
  . "<inn>$conf{ROSCOM_INN}</inn>\n"
  . "<ogrn>". $conf{ROSCOM_OGRN} ."</ogrn>\n"
  . "<email>$conf{ROSCOM_EMAIL}</email>\n"
  . "</request>";

  Encode::_utf8_off($xml_requset);

  open (my $XMLREQ, '>', $reqfn) or die "Can't create new request $!\n";
    print $XMLREQ $xml_requset;
  close $XMLREQ;

  my $openssl_cmd = "$openssl smime -sign -in $reqfn -out $binfn".
    " -signer $certfn -outform DER -nodetach";

  print $openssl_cmd if($debug > 3);
  system ($openssl_cmd);

  open(my $XMLREQSIG, '<', "$binfn") or die "Can't open $binfn $!\n";
    my $xmlreqsig = do { local $/ = undef; <$XMLREQSIG>; };
  close($XMLREQSIG);

  my $service =  SOAP::Lite->service( $request_url );

  my $request_count = 0;
  my $tries = 5;

  while($request_count < $tries) {
    $request_count++;
    print "Start request: ($request_count) $xml_requset\n" if($debug > 2);

    my @sendresult = $service->sendRequest(
      $xml_requset,
      $xmlreqsig,
      "2.0"
    );

    if ($#sendresult < 0) {
      mylog("Wrong request, try again ($request_count)\n");
      sleep 1;
      next;
    }

    if ($sendresult[0] eq 'false') {
      mylog("error request: $sendresult[1]");
    }
    elsif ($sendresult[0] eq 'true') {
      open (my $CODESTRING, '>', "$BASE/codestring");
        print $CODESTRING $sendresult[2];
      close $CODESTRING;
      mylog("sent request: Code string: $sendresult[2] $binfn: $sendresult[1]");
    };

    if (-e "$BASE/codestring") {
      open( my $CODESTRING, "$BASE/codestring");
        my $codestring = <$CODESTRING>;
      close $CODESTRING;

      my $cnt = 0;
      while(1) {
        my @getresult = $service->getResult( $codestring );
        if ($getresult[0] eq 'false') {
          mylog ("$getresult[1]");
          sleep 60;
        }
        elsif ($getresult[0] eq 'true') {
          my $outarch = decode_base64($getresult[1]);
          open (my $OUT, '>', "$BASE/out.zip");
            print $OUT $outarch;
          close $OUT;
          unlink "$BASE/codestring";

          if (-e "$BASE/out.zip") {
            system("/bin/mv $reqfn $BASE/arch/");
            system("/bin/mv $binfn $BASE/arch/");
            system("/bin/cp $BASE/out.zip $BASE/arch/out-$dt.zip");
            system("/usr/bin/unzip -o $BASE/out.zip -d $BASE/dump");
            unlink "$BASE/out.zip";
            mylog ("Done.  Everything seems to be ok.");
            return 1;
          };

          mylog("Shouldn't reach. DEBUG ME!!!");
          exit 255;
        }
        else {
          mylog ("getresult is unknown");
          exit 255;
        };

        $cnt++;
        if ($cnt > 30) {
          mylog ("too much tries, bailing out");
          exit 255;
        }
      };
      # notreached
    }
    else {
      mylog ("codestring: file not found");
    };
    return 1;
  }

  return 1;
}

#**********************************************************
=head2 _url()

=cut
#**********************************************************
sub _url {
  eval {
    my $url=shift;
    $url=~s/ //g;
    $url=uri_escape_utf8($url, "^A-Za-z0-9\-\._~:/\?\=\&\%");
    #print(FURL $url."\n");
  }
}

#**********************************************************
=head2 ruscom_parse_xml($filename) - Parse file

  Arguments:
    $filename

  Returns:
    ips
    {
      IP
      PORT
    }

=cut
#**********************************************************
sub ruscom_parse_xml {
  my ($filename) = @_;

  $filename //= $base_dir . '/var/db/zapret-info/dump/dump.xml';
  my $ip_only = 1;
  my %ips = ();

  if ($debug) {
    $Log->log_print('LOG_INFO', '', "Open: $filename");
  }

  if (! -f $filename) {
    $Log->log_print('LOG_ERR', '', "File not exists '$filename'");
    return [];
  }

  my $simple=XML::Simple->new(
    KeepRoot => 1,
    RootName => 'reg:register'
  );

  my $xml   = $simple->XMLin($filename);
  my %list  = %{$xml->{'reg:register'}->{'content'}};
  my $total = 0;
  my @export_ips   = ();
  my %export_domain = ();

  while ( my ($key, $value) = each %list) {
    $total++;
    print "-- $key\n" if ($debug > 3);
    my $domain = $value->{'domain'};
    my $ip     = $value->{'ip'};
    my $url    = $value->{'url'} || '';
    my $etype  = $value->{'entryType'};
    my $port;

    if ($domain) {
      $export_domain{$domain}++;
    }

    if ($etype < 4) {
      if (ref($ip) eq 'ARRAY') {
        foreach $ip (@{$ip}) {
          print(  "$ip eq 80\n" ) if($debug > 3);
          print(  "$ip eq 443\n" )  if($debug > 3);

          if ($ip_only && $ips{$ip}) {
             next;
          }

          push @export_ips, {
            IP   => $ip,
            PORT => 80
          };
          $ips{$ip}=1;
        }
      }
      else {
        my $proto = substr($url, 0, 5);
        if ("\L$proto" eq 'https') {
          $port = 443;
        }
        else {
          $port = 80;
        }

        if ($ip_only && $ips{$ip}) {
          next;
        }

        push @export_ips, {
          IP   => $ip,
          PORT => 80
        };
        $ips{$ip}=1;
      }

      if (ref($url) eq 'ARRAY') {
        foreach $url (@{$url}) {
          _url($url) if ($url);
        }
      }
      else {
        _url($url);
      }
    }
    else {
      print( Dumper($value)."\n<---- END ---->\n" )  if($debug > 1);
    }
  }

  if($debug > 2) {
    $Log->log_print('LOG_INFO', '', "Total: $total");
  }

  return (\@export_ips, \%export_domain);
}

#**********************************************************
=head2 mylog($logstring) - Parse file

=cut
#**********************************************************
sub mylog {
  my $logstring = shift;

  my $now_string = strftime("%d-%m-%Y %H:%M:%S", localtime);
  print(STDERR $now_string." ".$logstring."\n") if ($debug);
  Encode::_utf8_off($logstring);
  $Log->log_print('LOG_INFO', '', $logstring);

  return 1;
}

#**********************************************************
=head2 get_networks() - Download networks

=cut
#**********************************************************
sub get_networks {

#add traffic to axbills nets

while (my ($k, $url) = each %class_source) {
  my $nets = '';
  print "Class: $k Url: $url\n$WGET \"$url\"\n" if ($debug > 0);

  my @url_arr = split(/;/, $url);
  foreach $url (@url_arr) {
    $nets .= `$WGET "$url"`;
  }

  my @nets_arr = split(/\n/, $nets);
  my @sorted_net_arr = sort @nets_arr;

  if (defined($argv->{'ipfw'})) {
    add_to_ipfw(
      {
        TABLE_ID      => $k,
        NETS          => \@sorted_net_arr,
        TRAFFIC_CLASS => ($k-1)
      }
    );
  }
  elsif (defined($argv->{'iptables'})) {
    add_to_iptables(
      {
        TABLE_ID => $k,
        NETS     => \@sorted_net_arr
      }
    );
  }
  elsif (-f '/usr/sbin/ipset') {
    add_to_iptables(
      {
        TABLE_ID => $k,
        NETS     => \@sorted_net_arr
      }
    );
  }

  #Update route table
  if ($argv->{route}) {
    my ($net_id, $router_ip) = split(/:/, $argv->{route});
    if ($net_id eq $k) {
      route_add($router_ip, \@sorted_net_arr);
    }
  }

  my $new_net = analize(analize(analize(analize(analize(\@sorted_net_arr)))));
  $nets = join(";\n", @$new_net);
  print $#{$new_net} if ($debug > 1);

  #test new agregation ======================================

=comments
  my $main_mask = 0b0000000000000000000000000000001;
  
  foreach my $net (@nets_arr) {
		$net =~ /(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\/(\d{1,2})/;
		my $ip    = ip2int($1);
		my $mask  = $2;
    
    my $yes = 0;

    #foreach my $new_net_ ( @$new_net ) {
    for(my $i=0; $i<=$#{ $new_net }; $i++) {
      my $new_net_ = $new_net->[$i];
  		$new_net_ =~ /(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\/(\d{1,2})/;
  		my $new_ip    = ip2int($1);
	  	my $new_mask  = $2;
    	my $last_ip   = $new_ip + sprintf("%d", $main_mask << (32  - $new_mask) );
    	
    	#print int2ip($new_ip) ." -> ". int2ip($last_ip) ."\n";
    	
    	if ( $new_ip <= $ip && $last_ip >= $ip) {
    		$yes = 1;
    		next;
    	 }
     }

    if ($yes == 0) {
    	 print int2ip($ip)."/$mask\n";
 	     exit;
     }
  }
=cut

  #==========================================================

  #print  $nets;
  next if ($nets eq '');

  print $nets if ($debug > 1);
  print "Traffic Class: $k Nets: " . ($#nets_arr + 1) . "\n" if ($debug > 0);

  $Tariffs->traffic_class_change(
    {
      ID   => $k,
      NETS => $nets,
    }
  );

}
}

#**********************************************************
=head2 route_add($router_ip, $networks)

=cut
#**********************************************************
sub route_add {
  my ($router_ip, $networks) = @_;

  print "Route add:\n" if ($debug > 0);

  my %cur_routes_hash = ();

  #Get cure address
  my $cure_routes = `netstat -rn | grep '$router_ip'`;
  my @arr = split(/\n/, $cure_routes);
  foreach my $route (@arr) {
    if ($route =~ /(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})[\/]?(\d{0,2})/) {

      my $destination_ip = $1;
      my $mask = $2 || 32;
      next if ($destination_ip eq $router_ip);
      $cur_routes_hash{"$destination_ip/$mask"} = 1;
    }
  }
  foreach my $net (@{$networks}) {
    if ($cur_routes_hash{$net}) {
      delete $cur_routes_hash{$net};
    }
    else {
      print "Add $net -> $router_ip\n" if ($debug > 0);
      cmd("/sbin/route add $net $router_ip") if ($debug < 3);
    }
  }

  #delete old
  while (my ($net) = each %cur_routes_hash) {
    print "delete $net\n" if ($debug > 0);
    `/sbin/route delete $net` if ($debug < 3);
  }
}

#**********************************************************
=head2 analize($nets) - Analize net

=cut
#**********************************************************
sub analize {
  my ($nets) = @_;

  my $main_mask = 0b0000000000000000000000000000001;

  my %agg_nets = ();
  my $last_ip  = '';

  my %net_mask    = ();
  my @ips         = ();
  my $total_count = 0;

  foreach my $net (@$nets) {
    if ($net =~ /(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\/(\d{1,2})/) {
      my $ip   = ip2int($1);
      my $mask = $2;
      push @ips, $ip;
      $net_mask{"$ip"} = $mask;
    }
  }

  my @sorted = sort { $a <=> $b } @ips;

  foreach my $ip (@sorted) {
    my $mask = $net_mask{$ip};
    my $count = sprintf("%d", $main_mask << (32 - $mask));
    print int2ip($ip) . " / $mask " . int2ip($ip + $count) . " count: $count \n" if ($debug > 0);

    if ($agg_nets{$last_ip} && $ip + $count == $last_ip + sprintf("%d", $main_mask << (32 - ($agg_nets{$last_ip} - 1)))) {
      print "   " . int2ip($ip) . " !!  last ip: " . int2ip($last_ip + sprintf("%d", $main_mask << (32 - ($agg_nets{$last_ip} - 1)))) . " / " . int2ip($last_ip) . "/$agg_nets{$last_ip} -> " . ($agg_nets{$last_ip} - 1) . "\n" if ($debug > 0);
      $agg_nets{$last_ip}--;
      $total_count++;
    }
    else {
      $agg_nets{$ip} = $mask;
      $last_ip = $ip;
    }
  }

  my @nets_list = ();
  foreach my $ip (sort { $a <=> $b } keys %agg_nets) {
    push @nets_list, int2ip($ip) . '/' . $agg_nets{$ip};
  }

  print "Count: $total_count\n" if ($debug > 1);
  return \@nets_list;
}

#**********************************************************
=head2 add_to_ipfw($attr) - add to ipfw  table

=cut
#**********************************************************
sub add_to_ipfw {
  my ($attr) = @_;

  my @FW_ACTIONS = ();
  
  if ($debug == 1) {
    print "Add ips to ipfw\n";    	
  }
  
  if ($attr->{TABLE_ID}) {
    push @FW_ACTIONS, "$IPFW table $attr->{TABLE_ID} flush";
    foreach my $ip (@{ $attr->{NETS} }) {
      if ($ip =~ /\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/) {
        push @FW_ACTIONS, "$IPFW table $attr->{TABLE_ID} add $ip $attr->{TRAFFIC_CLASS}";
      }
    }
  }

  #make firewall actions
  foreach my $action (@FW_ACTIONS) {
    if ($debug == 1) {
      print "$action\n";
    }
    else {
      system("$action");
    }
  }

  return 0;
}

#**********************************************************
=head2 add_to_iptables($attr)

=cut
#**********************************************************
sub add_to_iptables {
  my ($attr) = @_;

  if (!-f '/usr/sbin/ipset') {
    print "/usr/sbin/ipset Not found.\n";
    exit;
  }

  my @FW_ACTIONS = ('/sbin/iptables -F -t mangle', 
                    '/sbin/iptables -t mangle -A PREROUTING -j MARK --set-mark 1', '/usr/sbin/ipset -X UKRAINE', 
                    '/usr/sbin/ipset -N UKRAINE nethash');

  if ($attr->{TABLE_ID}) {
    push @FW_ACTIONS, "$IPFW table $attr->{TABLE_ID} flush";
    foreach my $ip (@{ $attr->{NETS} }) {
      if ($ip =~ /\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/) {
        push @FW_ACTIONS, "/usr/sbin/ipset -A UKRAINE $ip";
      }
    }
  }

  push @FW_ACTIONS, '/sbin/iptables -t mangle --flush',
  '/sbin/iptables -t mangle -A PREROUTING -m set --set UKRAINE src -j MARK --set-mark 2', 
  'echo 1 > /proc/sys/vm/drop_caches', 
  'echo 2 > /proc/sys/vm/drop_caches', 
  'echo 3 > /proc/sys/vm/drop_caches', 'sync';

  #make firewall actions
  foreach my $action (@FW_ACTIONS) {
    if ($debug == 1) {
      print "$action\n";
    }
    else {
      cmd("$action");
    }
  }
}

#**********************************************************
=head2 mikrotik_block($export_ips, $attr)

  Arguments:
    $export_ips
    $attr
      IP
      PORT
      EXPORT_LIST - Export list to mikrotik and execute it
        $host:$username:$password:$passive_mode
      DOMAIN_LIST -

  Start rule
    /ip firewall address-list remove [/ip firewall address-list find list=black_list]
    /ip firewall filter add action=reject chain=forward dst-address-list=black_list protocol=tcp dst-port=80 reject-with=icmp-admin-prohibited

   echo "/ip firewall address-list remove numbers=[find list=zapretip]\r" > black_list.rsc
   echo "/ip firewall address-list\r" >> mt_zapretip.rsc
   xmlstarlet pyx dump.xml | grep ^- | sed 's,-,add list=zapretip address=,g;s,$,\r,g' >> mt_zapretip.rsc

=cut
#**********************************************************
sub add_2_mikrotik {
  my($export_ips, $attr)=@_;

  my $domain_redirect = $argv->{DOMAIN_REDIRECT} || '10.0.0.1';

  load_pmodule('Net::FTP');
  my $file_name = 'ros_com.rsc';
  my $export_file = $base_dir . '/var/db/'. $file_name;
  if (open(my $fh, '>', $export_file)) {
    print $fh "/ip firewall address-list remove [/ip firewall address-list find list=black_list];\n";

    foreach my $list (@$export_ips) {
      print $fh qq{/ip firewall address-list add list=black_list address=$list->{IP};\n};
    }

    if ($attr->{DOMAIN_LIST}) {
      #Clear old records
      print $fh qq{/ip dns static remove [find address=$domain_redirect];\n};
      foreach my $domain_name (keys %{ $attr->{DOMAIN_LIST} }) {
        # Block by DNS
        print $fh qq{/ip dns static add name=$domain_name address=$domain_redirect' % name.replace('\n',''));\n};
      }
    }

    close($fh);
    $Log->log_print('LOG_INFO', '', "Mikrotik export file created: $export_file");
  }
  else {
    $Log->log_print('LOG_ERR', '', "Can't create created: $export_file $!");
  }

  use Nas;
  my $Nas = Nas->new( $db, \%conf );
  if($debug > 5) {
    $Nas->{debug}=1;
  }
  my %LIST_PARAMS = ();
  if ($argv->{NAS_ID}) {
    $LIST_PARAMS{NAS_ID}=$argv->{NAS_ID};
  }

  my $list = $Nas->list( {
    %LIST_PARAMS,
    COLS_NAME  => 1,
    NAS_IP     => '_SHOW',
    NAS_TYPE   => 'mikrotik,mikrotik_dhcp',
    DISABLE    => 0,
    PAGE_ROWS  => 50000
  } );

  foreach my $nas (@$list) {
    $Log->log_print('LOG_INFO', '', "Mikrotik upload: $nas->{nas_ip}");

    my ($host, undef, $ssh_port) = split(/:/, $nas->{nas_mng_ip_port});
    $host //= $nas->{nas_ip};
    my $user = $nas->{nas_mng_user} || '';
    my $ftp = Net::FTP->new($host, Debug => 0, Passive => 1);

    if (! $ftp) {
      $Log->log_print('LOG_ERR', '', "Cannot connect to '$user\@$host': $@");
      next;
    }

    if ($ftp->login("$user", "$nas->{nas_mng_password}")) {
      if ($ftp->put($export_file)) {
        $Log->log_print( 'LOG_INFO', '', "Uploaded: $export_file" );
      }
      else {
        $Log->log_print( 'LOG_ERR', '',  "Ftp upload failed '$export_file' ", $ftp->message);
      }
    }
    else {
      $Log->log_print('LOG_ERR', '', "FTP Error: Wrong login or password ". ( ($debug > 4) ? "($user / $nas->{nas_mng_password})" : '') ." $!");
    }

    # /ip firewall filter add action=reject chain=forward dst-address-list=black_list reject-with=icmp-admin-prohibited
    my $cmd = "import $file_name";
    my $res = ssh_cmd( $cmd, {
      NAS_MNG_IP_PORT => "$host:" .($ssh_port  || 22),
      NAS_MNG_USER    => $user,
      BASE_DIR        => $base_dir,
      DEBUG           => $debug
    });
    my $result = join("\n", @$res);
    $Log->log_print( 'LOG_INFO', '', "Imported: $export_file ($result)". gen_time($begin_time));
  }

  return 1;
}



#**********************************************************
#
#**********************************************************
sub help {

  print << "[END]";
traffic_filters.pl version: $version
Get traffic filters add it to NAS servers

mikrotik  - Update mikrotik traffic filters
  NAS_ID

ipfw      - Update ipfw class table tables for FreeBSD
iptables  - Update ipset iptables for Linux
route=net_id:router_ip - update route table

type=ua_ix- filter type. defaklt ua_ix. (ua_ix,ros_com,crimea_ix,belarus_ax)

  ros_com
    DOMAIN_BLOCK=1
    DOMAIN_REDIRECT=1

nas_ip=
nas_login=


help      - this help
DEBUG     - Debug mode

[END]

  exit;
}

1
