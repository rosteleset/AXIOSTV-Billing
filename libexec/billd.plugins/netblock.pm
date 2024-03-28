=head1 NAME

   Netblock

   Arguments:

     TIMEOUT
     DOMAIN_REDIRECT  -
     FTP_UPLOAD

     UNBOUND - User unbound DNS
     BIND9   - Use BIND9 under construction
     RESOLV_LIST - show resolve list
     CERT_PEM - Certificate path

=cut

use Encode;
use utf8;
use Time::Piece;
use AXbills::Fetcher;
#binmode(STDOUT,':utf8');
use Data::Dumper;
use AXbills::Base qw(int2ip ip2int date_diff
  decode_base64 encode_base64 ssh_cmd gen_time load_pmodule convert dirname);
use Netblock;
use Events;
use strict;
use warnings;

load_pmodule('URI::UTF8::Punycode');
load_pmodule('SOAP::Lite');
load_pmodule('XML::LibXML');
use XML::Simple qw(:strict);

#use AXbills::Base qw/_bp/;

$SOAP::Constants::PREFIX_ENV = 'SOAP-ENV';

our (
  $Admin,
  $db,
  %conf,
  $argv,
  $debug,
  $DATE,
  $var_dir,
  $base_dir
);

my $Netblock = Netblock->new($db, $Admin, \%conf);
my $Log = Log->new(undef, \%conf);
my $Conf = Conf->new($db, $Admin, \%conf);
my $Events = Events->new($db, $Admin, \%conf);

$Log->{LOG_FILE} = $var_dir . "log/netblock.log";
if ($debug > 0) {
  $Log->{PRINT} = 1;
}

my $total_added_main = 0;
my $total_added_ip = 0;
my $total_added_name = 0;
my $total_added_url = 0;
my $total_dns_mask = 0;
my $BASE = $var_dir . 'db/netblock/';

if (!-d $BASE) {
  mkdir($BASE);
}

$conf{NETBLOCK_SKIP_NAME} =~ s/\n//gi if $conf{NETBLOCK_SKIP_NAME};
my @dns_skip_arr = ();
@dns_skip_arr = split(/,/, $conf{NETBLOCK_SKIP_NAME}) if $conf{NETBLOCK_SKIP_NAME};
$conf{NETBLOCK_SKIP_IP} =~ s/\n//gi if $conf{NETBLOCK_SKIP_IP};
my @ip_skip_arr = ();
@ip_skip_arr = split(/,/, $conf{NETBLOCK_SKIP_IP}) if $conf{NETBLOCK_SKIP_IP};
my $download_type = $argv->{TYPE} || q{};
my $domain_redirect = $argv->{DOMAIN_REDIRECT} || '10.0.0.1';

if ($argv->{INIT}) {
  $Netblock->init();
  exit 255
}
elsif ($argv->{PARSE}) {
  parse_xml($argv->{PARSE})
}
elsif ($argv->{CONF} && $argv->{CONF} == 1) {
  sign_request()
}
elsif ($download_type eq 'uablock') {
  uablock({
    FETCH    => $argv->{FETCH},
    ACTIVATE => 1
  });
}
elsif ($download_type eq 'byblock') {
  byblock({
    FETCH    => $argv->{FETCH},
    ACTIVATE => 1
  });
}
else {
  rkn();
}

if ($argv->{ACTIVE_BLOCK}) {
  active_block($argv);
}

#**********************************************************
=head2 uablock($attr) - Doblocka UA list

  Arguments:


  Returns:

=cut
#**********************************************************
sub uablock {
  my ($attr) = @_;

  if ($debug > 1) {
    print "UA block\n";
  }

  if ($attr->{FETCH}) {
    my $uablock_url = 'http://axbills.net.ua/uablock.txt';
    #my $BASE = $var_dir.'db/uablock/';
    my $block_domains;

    if (!-f 'uablock.txt') {
      $block_domains = get_networks($uablock_url);
    }

    #Add to db
    my $i = 1;
    foreach my $domain (@$block_domains) {
      $Netblock->add({
        BLOCKTYPE => 'domain',
        HASH      => $domain,
        ID        => $i,
        INCTIME   => 'NOW()'
      });

      if ($Netblock->{errno}) {
        print "Error: $Netblock->{errno} $Netblock->{errstr}\n";
      }

      $i++;
    }
  }

  return 1;
}

#**********************************************************
=head2 byblock($attr) - Doblocka BY list

  Arguments:


  Returns:

=cut
#**********************************************************
sub byblock {
  my ($attr) = @_;

  if ($debug > 1) {
    print "BY block\n";
  }

  if ($attr->{FETCH}) {
    my $i                 = 1;
    my $byblock_url       = '';
    my $block_domains     = '';
    my %request_params    = ();
    $request_params{name} = $conf{NETBLOCK_BY_NAME};

    if($conf{NETBLOCK_BY_PASS_LIMITATION}){
      $request_params{pass} = $conf{NETBLOCK_BY_PASS_LIMITATION};
      $byblock_url          = web_request($conf{NETBLOCK_BY_URL_LIMITATION}, {REQUEST_PARAMS => \%request_params} );
      $block_domains        = XMLin($byblock_url, ForceArray => 1, KeyAttr => 1);

      
      foreach my $domain (keys %$block_domains) {
        if($domain eq 'res'){
          foreach my $index (@{$block_domains->{$domain}}){
            $Netblock->add({
              BLOCKTYPE => 'domain',
              HASH      => $index->{ip}->[0],
              ID        => $i,
              INCTIME   => 'NOW()'
            });

            if ($Netblock->{errno}) {
              print "Error: $Netblock->{errno} $Netblock->{errstr}\n";
            }
            $i++;
          }
        }
      }
    }

    if($conf{NETBLOCK_BY_PASS_ANONYMOUS}){
      $request_params{pass} = $conf{NETBLOCK_BY_PASS_ANONYMOUS};
      $byblock_url          = web_request($conf{NETBLOCK_BY_URL_ANONYMOUS}, {REQUEST_PARAMS => \%request_params} );
      $block_domains        = XMLin($byblock_url, KeyAttr => { resource  => 'id' }, ForceArray => [ 'resource' ]);

      foreach my $index (keys %{$block_domains->{resource}}){
        if($block_domains->{resource}->{$index}->{ip} ne '-'){
          $Netblock->add({
            BLOCKTYPE => 'domain',
            HASH      => $block_domains->{resource}->{$index}->{ip},
            ID        => $i,
            INCTIME   => 'NOW()'
          });

          if ($Netblock->{errno}) {
            print "Error: $Netblock->{errno} $Netblock->{errstr}\n";
          }
          $i++;
        }     
      }
    }
  }
 
  return 1;
}


#**********************************************************
=head2 rkn($attr) - Doblocka RKN list

  Arguments:
    
    
  Returns:
  
=cut
#**********************************************************
sub rkn {

  my @dirs = (
    $var_dir . 'db',
    $var_dir . 'db/netblock/',
    $var_dir . 'db/netblock/cfg',
    $var_dir . 'db/netblock/arch'
  );

  #make dirs
  foreach my $dir (@dirs) {
    if (!-d $dir) {
      print "Create '$dir'\n";
      mkdir $dir;
    }
  }

  undef $/;
  my $dt = POSIX::strftime("%F_%H-%M", localtime(time));
  my $newf = $BASE . "arch/" . $dt . ".zip";
  my $certificate = $BASE . "cfg/certificate.pem";

  if($argv->{CERT_PEM}) {
    $certificate = $argv->{CERT_PEM};
  }

  if (!-f $certificate) {
    print "File not exist '$certificate'\n";
    return 0;
  }

  my $tout = cmd("openssl x509 -enddate -noout < $certificate", { SHOW_RESULT => 1 });

  if (!$tout) {
    print "Can't make x509\n";
    return 0;
  }

  $tout = (split(/=/, $tout))[1];
  my $nday = Time::Piece->strptime($tout, '%b %e %H:%M:%S %Y %Z ');
  if ($conf{NETBLOCK_CRT_ALERT} && (date_diff($DATE, $nday->date) <= $conf{NETBLOCK_CRT_ALERT})) {
    $Events->events_add({ MODULE => "Rkn", COMMENTS => "Certificate expires: " . $tout });
  }

  #if ($argv->{CONF} && $argv->{CONF} == 2) {
  sign_request();
  #}

  if (! -f $BASE . "cfg/request.xml") {
    print "Request xml not found please form it '$BASE/cfg/request.xml'\n";
    return 0;
  }

  open(my $REQ, '<', $BASE . "cfg/request.xml") or die "Can't open REQ! '$BASE/cfg/request.xml' $!\n";
    my $req = <$REQ>;
  close($REQ);

  encode_base64($req);

  open(my $SIG, '<', $BASE . "cfg/request.xml.sign") or die "Can't open SIG! '$BASE/cfg/request.xml.sign' $!\n";
    my $sig = <$SIG>;
  close $SIG;

  my $soap = SOAP::Lite->service("http://vigruzki.rkn.gov.ru/services/OperatorRequest/?wsdl");
  #  my $last = $soap->getLastDumpDate();

  my @sendresult = $soap->sendRequest($req, $sig, "2.0");
  if ($sendresult[0] eq 'false') {
    $Log->log_print('LOG_INFO', "Rkn", $sendresult[1]);
    $Events->events_add({ MODULE => "Rkn", COMMENTS => "Send result: $sendresult[1]" });
  }

  my $request_count = 0;
  my $tries = 10;
  my @getresult = ();

  while ($request_count < $tries) {
    $request_count++;
    sleep 30;
    @getresult = $soap->getResult($sendresult[2]);
    last if $getresult[0] eq 'true';
  }

  if ($getresult[0] eq 'true') {
    open(my $ZIP, '>', $newf);
    print $ZIP decode_base64($getresult[1]);
    close($ZIP);
  }
  else {
    $Log->log_print('LOG_INFO', "Rkn", $getresult[1]);
  }

  if (-e $newf) {
    system("/usr/bin/unzip -o $newf -d $BASE");
    parse_xml();
    unlink "$BASE/dump.xml", "$BASE/dump.xml.sig";
  }
  else {
    $Events->events_add({ MODULE => "Rkn", COMMENTS => "Don't get file: $getresult[1]" });
  }

  return 1
}

#**********************************************************
=head2 parse_xml() - Parse file

=cut
#**********************************************************
sub parse_xml {

  my ($filename) = @_;
  if (!$filename) {
    $filename = "$BASE/dump.xml";
  }

  my $blocklist = $Netblock->list({ HASH => '_SHOW', COLS_NAME => 1 });
  my $ip_skiplist = $Netblock->_list({ TABLE => 'netblock_ip', GROUP => 'ip', IP => '_SHOW', SKIP => 1 });
  my $dns_skiplist = $Netblock->_list({ TABLE => 'netblock_domain', GROUP => 'name', NAME => '_SHOW', SKIP => 1 });

  foreach my $name (@$dns_skiplist) {
    push @dns_skip_arr, $name->[0];
  }

  foreach my $ip (@$ip_skiplist) {
    push @ip_skip_arr, $ip->[0];
  }

  my %tmp_hash;

  foreach my $bl (@$blocklist) {
    $tmp_hash{$bl->{id}} = $bl->{hash};
  }

  my $parser = XML::LibXML->new();
  my $dom = $parser->parse_file($filename) or die "Can't parse file '$filename' $!\n";

  my $root = $dom->getDocumentElement();
  my @nodes = $root->childNodes;

  $db->{db}->{AutoCommit} = 0;
  $db->{TRANSACTION} = 1;

  foreach my $node (@nodes) {
    my $blocktype = $node->getAttribute("blockType") || 'undef';
    my $id = $node->getAttribute("id");
    my $inctime = $node->getAttribute("includeTime") || 'NOW()';
    my $hash = $node->getAttribute("hash");
    $inctime =~ s/T/ /g;
    if (!exists $tmp_hash{$id} || $hash ne $tmp_hash{$id}) {
      if ($tmp_hash{$id} && $hash ne $tmp_hash{$id}) {
        $Netblock->del({ID => $id});
        unblock($id) if $debug < 4;
        delete $tmp_hash{$id};
        $Log->log_print('LOG_INFO', "Rkn", "Changed $id, $hash, $inctime");
      }

      $Netblock->add({
        ID        => $id,
        BLOCKTYPE => $blocktype,
        HASH      => $hash,
        INCTIME   => $inctime,
      });

      $total_added_main++;
      $Log->log_print('LOG_INFO', "Rkn", "New $id, $hash, $inctime") if ($debug > 5);
      block_ip($id, $node->getElementsByTagName("ip")) if ($blocktype eq 'ip' || $blocktype eq 'undef');
      block_dns($id, $node->getElementsByTagName("domain")) if ($blocktype eq 'domain' || $blocktype eq 'undef');
      block_dns_mask($id, $node->getElementsByTagName("domain-mask")) if $blocktype eq 'domain-mask';
      block_url($id, $node->getElementsByTagName("url"));
    }
    else {
      delete $tmp_hash{$id};
    }
  }
  # if (!$error) {
  $db->{db}->commit();
  $db->{db}->{AutoCommit} = 1;
  #    } else {
  #      $db->{db}->rollback();
  #    }

  foreach my $key (keys %tmp_hash) {
    $Netblock->del({ID => $key});
    unblock($key) if $debug < 4;
    print "Delete $key \n" if ($debug > 5);
  }

  my $ips = $Netblock->_list({
    TABLE => 'netblock_ip',
    GROUP => 'ip',
    IP    => '_SHOW',
    SKIP  => 0
  });

  open(my $fh, '>', $BASE . "ip_list") or die "Can't create file";
  foreach my $ip (@$ips) {
    print $fh "$ip->[0]\n";
  }
  close($fh);

  open(my $fh_ip_skip, '>', $BASE . "ip_skip_list") or die "Can't create file";
  foreach my $skip (@ip_skip_arr) {
    print $fh_ip_skip "$skip\n";
  }
  close($fh_ip_skip);

  my $urls = $Netblock->_list({ TABLE => 'netblock_url', GROUP => 'url', URL => '_SHOW', SKIP => 0 });
  open(my $fh_url_list, '>', $BASE . "url_list") or die "Can't create file";
  foreach my $u (@$urls) {
    my $url = $u->[0];
    $url =~ s/\[\]/\\\[\\\]/g;
    print $fh_url_list "$url\n";
  }
  close($fh_url_list);

  $Log->log_print('LOG_INFO', "Rkn",
    "$total_added_main NEW: $total_added_ip IP, $total_added_name NAME, $total_added_url URL." .
      keys(%tmp_hash) . " DELETED");

  return 1
}

#**********************************************************
=head2 block_ip($ip, @ips) - Block by IP

=cut
#**********************************************************
sub block_ip {
  my ( $id, @ips ) = @_;

  foreach my $ip (@ips) {
    my $skip = 0;
    my $curip = $ip->firstChild()->data;
    $Netblock->add_ip({ ID => $id, IP => $curip });

    if (grep {$_ eq $curip} @ip_skip_arr) {
      $skip = 1;
      if ($conf{NETBLOCK_FW_SKIP_CMD} && $debug < 4) {
        my $cmd = $conf{NETBLOCK_FW_SKIP_CMD};
        $cmd =~ s/%IP/$curip/g;
        cmd($cmd);
      }
    }

    if ($conf{NETBLOCK_FW_ADD_CMD} && $debug < 4) {
      my $cmd = $conf{NETBLOCK_FW_ADD_CMD};
      $cmd =~ s/%IP/$curip/g;
      cmd($cmd);
    }

    $total_added_ip++;
    $Log->log_print('LOG_INFO', "Rkn", "Added IP $curip") if ($debug > 5);
  }

  return 1;
}

#**********************************************************
=head2 block_dns($ip, @ips)

=cut
#**********************************************************
sub block_dns {
  my ( $id, @dnames ) = @_;

  foreach my $name (@dnames) {
    my $skip = 0;
    $name = puny_encode($name->firstChild()->data);
    if (grep {$_ eq $name} @dns_skip_arr) {
      $skip = 1;
    }
    elsif ($conf{NETBLOCK_DNS_ADD_CMD} && $debug < 4) {
      my $cmd = $conf{NETBLOCK_DNS_ADD_CMD};
      $cmd =~ s/%NAME/$name/g;
      cmd($cmd);
    }
    $Netblock->add_domain({
      ID   => $id,
      NAME => $name,
      SKIP => $skip
    });

    $total_added_name++;
    $Log->log_print('LOG_INFO', "Rkn", "Added NAME $name") if ($debug > 5);
  }

  return 1;
}


#**********************************************************
=head2 block_dns_mask($ip, @ips)

=cut
#**********************************************************
sub block_dns_mask {
  my ( $id, @dnames ) = @_;

  foreach my $name (@dnames) {
    $name = puny_encode($name->firstChild()->data);
    $Netblock->add_domain_mask({ ID => $id, MASK => $name });
    $total_dns_mask++;
    $Log->log_print('LOG_INFO', "Rkn", "Added ZONE $name") if ($debug > 5);
  }

  return 1;
}

#**********************************************************
=head2 block_dns_mask($ip, @ips)

=cut
#**********************************************************
sub block_url {
  my ( $id, @urls ) = @_;

  foreach my $url (@urls) {
    $url = puny_encode($url->firstChild()->data);
    $Netblock->add_url({ ID => $id, URL => $url });
    $total_added_url++;
    $Log->log_print('LOG_INFO', "Rkn", "Added URL $url") if ($debug > 5);
  }

  return 1;
}

#**********************************************************
=head2 unblock($ip, @ips)

=cut
#**********************************************************
sub unblock {
  my ( $id ) = @_;

  my $unlist = $Netblock->list({
    NAME      => '_SHOW',
    IP        => '_SHOW',
    ID        => $id,
    COLS_NAME => 1
  });

  foreach my $item (@$unlist) {
    if ($conf{NETBLOCK_FW_DEL_CMD} && $item->{ip} && $debug < 4) {
      my $ip = $item->{ip};
      my $cmd = $conf{NETBLOCK_FW_DEL_CMD};
      $cmd =~ s/%IP/$ip/g;
      cmd($cmd);
      $Log->log_print('LOG_INFO', "Rkn", "Unblock IP $ip") if ($debug > 5);
    }

    if ($conf{NETBLOCK_DNS_DEL_CMD} && $item->{name} && $debug < 4) {
      my $name = $item->{name};
      my $cmd = $conf{NETBLOCK_DNS_DEL_CMD};
      $cmd =~ s/%NAME/$name/g;
      cmd($cmd);
      $Log->log_print('LOG_INFO', "Rkn", "Unblock NAME $name") if ($debug > 5);
    }
  }

  return 1;
}


#**********************************************************
=head2 puny_encode($ip, @ips)

=cut
#**********************************************************
sub puny_encode {
  my $word = shift;
  my @puny_words = ();

  foreach my $char (split(/\./, $word)) {
    if (($char !~ m/[a-z]/i) && ($char =~ /[^0-9-]/)) {
      $char = URI::UTF8::Punycode::puny_enc($char);
    }
    push(@puny_words, $char);
  }
  my $result = join('.', @puny_words);

  return $result;
}

#**********************************************************
=head2 get_networks($url) - Download networks

=cut
#**********************************************************
sub get_networks {
  my ($url) = @_;
  #add traffic to axbills nets

  my $WGET = 'wget -qO-';
  if (-f '/usr/bin/fetch') {
    $WGET = '/usr/bin/fetch -q -o -';
  }

  my $nets = '';
  print "Url: $url\n$WGET \"$url\"\n" if ($debug > 1);

  my @url_arr = split(/;/, $url);
  foreach my $_url (@url_arr) {
    $nets .= `$WGET "$_url"`;
  }

  my @nets_arr = split(/\n/, $nets);
  my @sorted_net_arr = sort @nets_arr;

  return \@sorted_net_arr;
}


#**********************************************************
=head2 resolv_list($attr) - resolv_list

  Arguments:
    DOMAIN_LIST - Resolve list
    HOST        - Resolv host

  Returns;

=cut
#**********************************************************
sub resolv_list {
  my ($attr) = @_;

  my %ips = ();
  my @to_resolv = ();

  if ($attr->{DOMAIN_LIST}) {
    @to_resolv = keys %{ $attr->{DOMAIN_LIST} };
  }
  elsif ($attr->{HOST}) {
    push @to_resolv, $attr->{HOST};
  }

  foreach my $domain (sort @to_resolv) {
    if ($debug > 3) {
      print "Resolve: '$domain'\n";
    }

    if (my (undef, undef, undef,
      undef, @addrs) = gethostbyname($domain)) {

      foreach my $ip_v4 (@addrs) {
        $ips{ join('.', unpack('C4', $ip_v4))} = 1;
      }
    }
    else {
      $ips{$domain} = 1;
    }
  }

  return \%ips;
}


#**********************************************************
=head2 active_block($attr) - Activate blocks

  Arguments:

  Returns;

=cut
#**********************************************************
sub active_block {
  my ($attr) = @_;

  if ($debug > 1) {
    print "Active block\n";
  }

  my @block_ips = ();
  my %block_domains = ();

  my $block_list = $Netblock->list({
    HASH      => '_SHOW',
    BLOCKTYPE => '_SHOW',
    COLS_NAME => 1,
    COLS_NAME => 100000
  });

  foreach my $line (@$block_list) {
    if ($line->{blocktype} && $line->{blocktype} eq 'domain') {
      $block_domains{$line->{hash}}++;
      push @block_ips, { IP => $line->{hash} };
    }
  }

  # DNS
  if (scalar keys %block_domains > 0) {
    $attr->{DOMAIN_LIST} = \%block_domains;
  }

  if ($attr->{UNBOUND}) {
    add_2_unbound($attr);
  }

  if ($attr->{RESOLV_LIST}) {
    print join("\n", keys %{ resolv_list($attr) });
  }

  # Mikrotik
  my $nas_type = $attr->{NAS_TYPE} || q{};
  if ($nas_type =~ /mikrotik/) {
    add_2_mikrotik({
      EXPORT_LIST => \@block_ips,
      DOMAIN_LIST => \%block_domains
    });
  }

  # IPFW
  if ($attr->{IPFW_BLOCK}) {
    add_2_ipfw({
      EXPORT_LIST => \@block_ips,
      DOMAIN_LIST => \%block_domains
    });
  }

  # DPI
  if ($attr->{DPI_BLOCK}) {
    add_2_dpi();
  }

  return 1;
}

#**********************************************************
=head2 mikrotik_block_rules($export_ips, $attr)

=cut
#**********************************************************
sub mikrotik_block_rules {
  my ($attr) = @_;

  my $export_ips = $attr->{EXPORT_LIST};

  my @cmds = ();
  push @cmds, "/ip firewall address-list remove [/ip firewall address-list find list=black_list];";

  foreach my $list (@$export_ips) {
    push @cmds, qq{/ip firewall address-list add list=black_list address=$list->{IP};};
  }

  if ($attr->{DOMAIN_LIST}) {
    #Clear old records
    push @cmds, qq{/ip dns static remove [find address=$domain_redirect];};
    foreach my $domain_name (keys %{ $attr->{DOMAIN_LIST} }) {
      # Block by DNS
      #push @cmds, qq{/ip dns static add name=$domain_name address=$domain_redirect' % name.replace('\n',''));};
      push @cmds, qq{/ip dns static add name=$domain_name address=$domain_redirect};
    }
  }

  return \@cmds;
}

#**********************************************************
=head2 mikrotik_block($export_ips, $attr)

  Arguments:
    $attr
      IP
      PORT
      EXPORT_LIST - Export list to mikrotik and execute it
        $host:$username:$password:$passive_mode
      DOMAIN_LIST -
        { domain_name -> domain_redirect }

  Start rule
    /ip firewall address-list remove [/ip firewall address-list find list=black_list]
    /ip firewall filter add action=reject chain=forward dst-address-list=black_list protocol=tcp dst-port=80 reject-with=icmp-admin-prohibited

   echo "/ip firewall address-list remove numbers=[find list=zapretip]\r" > black_list.rsc
   echo "/ip firewall address-list\r" >> mt_zapretip.rsc
   xmlstarlet pyx dump.xml | grep ^- | sed 's,-,add list=zapretip address=,g;s,$,\r,g' >> mt_zapretip.rsc

=cut
#**********************************************************
sub add_2_mikrotik {
  my ($attr) = @_;

  if ($debug > 2) {
    print "Export to mikrotiks\n";
  }

  load_pmodule2('Net::FTP');
  my $file_name = 'block.rsc';
  my $export_file = $base_dir . '/var/db/' . $file_name;
  my $mikrotik_cms = mikrotik_block_rules($attr);

  if (open(my $fh, '>', $export_file)) {
    print $fh join(";\n", @$mikrotik_cms);
    close($fh);
    $Log->log_print('LOG_INFO', '', "Mikrotik export file created: $export_file");
  }
  else {
    $Log->log_print('LOG_ERR', '', "Can't create created: $export_file $!");
  }

  my $Nas = Nas->new($db, \%conf);
  if ($debug > 5) {
    $Nas->{debug} = 1;
  }

  my $list = $Nas->list({
    %LIST_PARAMS,
    COLS_NAME => 1,
    NAS_IP    => '_SHOW',
    NAS_TYPE  => 'mikrotik,mikrotik_dhcp',
    DISABLE   => 0,
    PAGE_ROWS => 50000
  });

  my $message = q{};
  foreach my $nas (@$list) {
    $Log->log_print('LOG_INFO', '', "Mikrotik upload: $nas->{nas_ip}");

    my ($host, undef, $ssh_port) = split(/:/, $nas->{nas_mng_ip_port});
    $host //= $nas->{nas_ip};
    my $user = $nas->{nas_mng_user} || '';

    my $cmd = "import $file_name";
    #FTP UPLOAD
    if ($argv->{FTP_UPLOAD}) {
      my $ftp = Net::FTP->new($host, Debug => 0, Passive => 1);

      if (!$ftp) {
        $Log->log_print('LOG_ERR', '', "Cannot connect to '$user\@$host': $@");
        next;
      }

      if ($ftp->login("$user", "$nas->{nas_mng_password}")) {
        if ($ftp->put($export_file)) {
          $Log->log_print('LOG_INFO', '', "Uploaded: $export_file");
        }
        else {
          $Log->log_print('LOG_ERR', '', "Ftp upload failed '$export_file' ", $ftp->message);
        }
      }
      else {
        $Log->log_print('LOG_ERR', '',
          "FTP Error: Wrong login or password " . (($debug > 4) ? "($user / $nas->{nas_mng_password})" : '') . " $!");
      }
      $message = "Imported: $export_file"
    }
    else {
      $cmd = $mikrotik_cms;
      $message = "uploaded rules";
    }
    # /ip firewall filter add action=reject chain=forward dst-address-list=black_list reject-with=icmp-admin-prohibited

    my $res = ssh_cmd($cmd, {
        NAS_MNG_IP_PORT => "$host:" . ($ssh_port || 22),
        NAS_MNG_USER    => $user,
        BASE_DIR        => $base_dir,
        DEBUG           => $debug
      });

    my $result = join("\n", @$res);
    $Log->log_print('LOG_INFO', '', "$message ($result)" . gen_time($begin_time));
  }

  return 1;
}

#**********************************************************
=head2 add_2_dpi($attr)

=cut
#**********************************************************
sub add_2_dpi {
  my ($attr) = @_;

  if ($debug > 2) {
    print "*** Activating DPI\n";
  }

  # get all data from netblock_{domain,ip,ssl,etc} tables
  my $dpi_domains = $Netblock->_list({
      TABLE => 'netblock_domain',
      GROUP => 'name',
      NAME  => '_SHOW',
      SKIP  => 0
    });
  my $dpi_ips = $Netblock->_list({
      TABLE => 'netblock_ip',
      GROUP => 'ip',
      IP  => '_SHOW',
      SKIP  => 0
    });
  my $dpi_urls = $Netblock->_list({
      TABLE => 'netblock_url',
      GROUP => 'url',
      URL  => '_SHOW',
      SKIP  => 0
    });
  my $dpi_ssl = $Netblock->_list({
      TABLE => 'netblock_ssl',
      GROUP => 'ssl_name',
      SSL  => '_SHOW',
      SKIP  => 0
    });
  my $dpi_ports = $Netblock->_list({
      TABLE => 'netblock_ports',
      GROUP => 'ports',
      PORTS  => '_SHOW',
      SKIP  => 0
    });

  # save all data to nfq config files
  my $filename = $conf{NETBLOCK_NFQ_ETC} . "domains" || qq{"/etc/nfq/domains"};
  open(my $FH, '>', $filename) or die "Can't create file '$filename' $!\n";
  foreach my $dpi_domain (@$dpi_domains) {
    print $FH "$dpi_domain->[0]\n";
  }
  close($FH);
  $filename = $conf{NETBLOCK_NFQ_ETC} . "hosts" || qq{"/etc/nfq/hosts"};
  open($FH, '>', $filename) or die "Can't create file '$filename' $!\n";
  foreach my $dpi_ip (@$dpi_ips) {
    print $FH "$dpi_ip->[0]\n";
  }
  close($FH);
  $filename = $conf{NETBLOCK_NFQ_ETC} . "urls" || qq{"/etc/nfq/urls"};
  open($FH, '>', $filename) or die "Can't create file '$filename' $!\n";
  foreach my $dpi_url (@$dpi_urls) {
    print $FH "$dpi_url->[0]\n";
  }
  close($FH);
  $filename = $conf{NETBLOCK_NFQ_ETC} . "ssl_host" || qq{"/etc/nfq/ssl_host"};
  open($FH, '>', $filename) or die "Can't create file '$filename' $!\n";
  foreach my $dpi_sslstr (@$dpi_ssl) {
    print $FH "$dpi_sslstr->[0]\n";
  }
  close($FH);
  $filename = $conf{NETBLOCK_NFQ_ETC} . "protos" || qq{"/etc/nfq/protos"};
  open($FH, '>', $filename) or die "Can't create file '$filename' $!\n";
  foreach my $dpi_port (@$dpi_ports) {
    print $FH "$dpi_port->[0]\n";
  }
  close($FH);


  #restart nfqfilter
  cmd ("kill -9 `cat /var/run/nfqfilter.pid`");
  my $nfq_restart = ($conf{NETBLOCK_NFQ_RESTART}) ? $conf{NETBLOCK_NFQ_RESTART} : "/usr/local/sbin/nfqfilter --daemon --pidfile=/var/run/nfqfilter.pid -c /etc/nfq/nfq.ini";
  cmd ("$nfq_restart");
  
}

#**********************************************************
=head2 add_2_unbound($attr)

=cut
#**********************************************************
sub add_2_unbound {
  my ($attr) = @_;

  if ($debug > 2) {
    print "Unbound activate\n";
  }

  my $dns_tpl = $conf{NETBLOCK_DNS_TPL} || qq{local-data: "%NAME. IN A $domain_redirect"};

  my $filename = $BASE . "domain_list";

  if ($debug > 3) {
    print "Unbound file: $filename\n";
  }

  my $domaiins_list = q{};

  if ($attr->{DOMAIN_LIST}) {
    foreach my $domain (sort keys %{ $attr->{DOMAIN_LIST} }) {
      my $param = $dns_tpl;
      $param =~ s/%NAME/$domain/g;
      $domaiins_list .= $param . "\n";
    }
  }
  else {
    my $names = $Netblock->_list({
      TABLE => 'netblock_domain',
      GROUP => 'name',
      NAME  => '_SHOW',
      SKIP  => 0
    });

    foreach my $name (@$names) {
      my $param = $dns_tpl;
      $param =~ s/%NAME/$name->[0]/g;
      $domaiins_list .= $param . "\n";
    }
  }

  open(my $FH, '>', $filename) or die "Can't create file '$filename' $!\n";
  print $FH $domaiins_list;
  close($FH);

  #restart unbound
  my $unbound_restart = ($conf{UNBOUND_RESTART}) ? $conf{UNBOUND_RESTART} : "/etc/rc.d/local_unbound restart";
  cmd("$unbound_restart");

  #check unbound config

  return 1;
}

#**********************************************************
=head2 add_2_ipfw($attr)

  Arguments:
    $attr
      EXPORT_LIST


=cut
#**********************************************************
sub add_2_ipfw {
  my ($attr) = @_;

  if ($debug > 2) {
    print "IPFW add\n";
  }

  my $export_ips = $attr->{EXPORT_LIST};

  my @cmds = ();
  #add deny all from any to "table(13)" via ${nat_interface}
  push @cmds, "/usr/sbin/ipfw table 13 flush";

  my @ips = ();
  foreach my $line (@$export_ips) {
    if ($line->{IP} !~ /(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})/) {
      push @ips, keys %{ resolv_list({ HOST => $line->{IP} }) };
    }
    else {
      push @ips, $line->{IP};
    }
  }

  foreach my $ip (@ips) {
    my $cmd = $conf{NETBLOCK_FW_ADD_CMD} || q{};
    $cmd =~ s/%IP/$ip/g;
    if ($debug > 2) {
      print $cmd . "\n";
    }
    push @cmds, $cmd;
  }

  foreach my $cmd (@cmds) {
    cmd($cmd);
  }

  if ($debug > 0) {
    print "IPFW added: " . ($#cmds + 1) . "\n";
  }

  return 1;
}

#**********************************************************
=head2 sign_request() - Make Request file from config


  $conf{ORGANIZATION_NAME}
  $conf{ORGANIZATION_INN}
  $conf{ORGANIZATION_OGRN}
  $conf{ORGANIZATION_MAIL}

=cut
#**********************************************************
sub sign_request {

  my $list = $Conf->config_list({ CUSTOM => 1, SORT => 2 });
  my %params;
  my $TZ = POSIX::strftime("%z", localtime());

  substr($TZ, - 2, 0) = ":";
  if ($conf{NETBLOCK_TZ}) {
    $TZ = $conf{NETBLOCK_TZ}
  }

  my $dtime = POSIX::strftime("%FT%H:%M:%S.000$TZ", localtime(time));
  foreach my $prm (@$list) {
    $params{$prm->[0]} = $prm->[1];
  }

  my $dom = XML::LibXML::Document->new('1.0', 'windows-1251');
  my $root = $dom->createElement('request');
  $dom->setDocumentElement($root);

  my $doc_time = $dom->createElement('requestTime');
  $doc_time->appendText($dtime);
  $root->appendChild($doc_time);

  my $doc_name = $dom->createElement('operatorName');
  $params{ORGANIZATION_NAME} =~ s/"//g;
  $doc_name->appendText( convert($params{ORGANIZATION_NAME} || q{}, { utf82win=> 1}) );
  $root->appendChild($doc_name);

  my $doc_inn = $dom->createElement('inn');
  $doc_inn->appendText(convert($params{ORGANIZATION_INN} || q{}, { utf82win=> 1}));
  $root->appendChild($doc_inn);

  my $doc_ogrn = $dom->createElement('ogrn');
  $doc_ogrn->appendText(convert($params{ORGANIZATION_OGRN} || q{}, { utf82win=> 1}));
  $root->appendChild($doc_ogrn);
  my $doc_mail = $dom->createElement('email');
  $doc_mail->appendText(convert($params{ORGANIZATION_MAIL}, { utf82win=> 1}));
  $root->appendChild($doc_mail);

  my $reqxml = $BASE . "cfg/request.xml";
  my $cert_dirname = dirname($reqxml);

  if(! -d $cert_dirname) {
    print "ERROR: directory not exists '$cert_dirname'\n";
    exit;
  }

  if (! $dom->toFile($reqxml, 3)) {
    print "ERROR: Cna't create file '$reqxml' $! \n";
  }

  #my $reqxml = $dom->toString(0);
  #encode_base64($reqxml);
  my $certificate = $BASE . "cfg/certificate.pem";

  if($argv->{CERT_PEM}) {
    $certificate = $argv->{CERT_PEM};
  }

  my $sign_req = $BASE . "cfg/request.xml.sign";
  #my $pfx = $BASE."cfg/p12.pfx";
  #my $tout = cmd("echo \"".$reqxml."\" \| $conf{NETBLOCK_OSSL_BIN} smime -sign -binary -signer $certificate -outform PEM",
  #  { SHOW_RESULT => 1 } );

  if(! $conf{NETBLOCK_OSSL_BIN}) {
    $conf{NETBLOCK_OSSL_BIN} = `which openssl`;
    chop($conf{NETBLOCK_OSSL_BIN});
  }

  cmd("$conf{NETBLOCK_OSSL_BIN} smime -sign -in $reqxml -out $sign_req -binary -signer $certificate -outform PEM",
    {
      SHOW_RESULT => 1,
      DEBUG       => $debug
    });

  return 1;
}

1;
