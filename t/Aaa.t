#!/usr/bin/perl

=head1 NAME

  Mac_auth test

=cut

use warnings;
use strict;
use Test::Simple tests => 5;
use Memoize;
use Benchmark qw/:all/;
use threads;

BEGIN {
  our %conf;
  use FindBin '$Bin';
  unshift(@INC, $Bin."/../libexec/");

  do "config.pl";

  unshift(@INC,
    $Bin."/../lib/",
    $Bin."/../AXbills/$conf{dbtype}");
}


our (
  %conf,
  %AUTH,
  %RAD_REQUEST,
  %RAD_REPLY,
  %RAD_CHECK,
  $begin_time,
  @MODULES
);

use AXbills::Base qw(check_time parse_arguments mk_unique_value in_array);
use AXbills::SQL;

$begin_time = check_time();
my $db    = AXbills::SQL->connect($conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd}, \%conf);
my $argv  = parse_arguments(\@ARGV);

my $debug = $argv->{debug} || 1;
my $count = $argv->{count} || 1000; #24000; # Test iterations.

if ($argv->{nas}) {
  get_nas_info();
}
elsif ($argv->{get_ip}) {
  _get_ip();
}
elsif ($argv->{online_add}) {
  #online_add();
}
elsif (defined($argv->{rad_auth})) {
  _rad({ auth => 1 });
}
elsif (defined($argv->{dhcp_test})) {
  _rad({ dhcp_test => 1 });
  #mac_auth();
}
elsif (defined($argv->{rad_acct})) {
  _rad({ acct => 1 });
}
elsif (defined($argv->{unifi})) {
  unifi();
}
elsif(defined($argv->{help})) {
  print "Select test\n";
  help();
}
else {
  _rad();
}

#**********************************************************
=head2 umac_auth()

=cut
#**********************************************************
sub mac_auth{
  print "Mac_auth test\n";

  my $rad_pairs;
  if ( $ARGV[1] ) {
    $rad_pairs = load_rad_pairs( $ARGV[1] );
  }

  %RAD_REQUEST = %{ $rad_pairs };
  $Bin = $Bin .'/../libexec/';
  if($argv->{mac_auth2}) {
    print "Mac_auth2\n";
    require Mac_auth2;
  }
  # else {
  #   require Mac_auth;
  # }

  do "rlm_perl.pl";

  post_auth();

  show_reply(\%RAD_REPLY);

  return 1;
}


#**********************************************************
=head2 show_reply($RAD_REPLY)

=cut
#**********************************************************
sub show_reply{
  my($RAD_REPLY, $message)=@_;

  print (($message) ? $message : "RAD_REPLY");
  print ":\n";

  foreach my $k (sort keys %$RAD_REPLY) {
    my $v = $RAD_REPLY->{$k};
    if ( ref $v eq 'ARRAY' ){
      foreach my $value (@$v) {
        print "  $k -> $value\n";
      }
    }
    else{
      print "  $k -> $v\n";
    }
  }
  print "\n";

  return 1;
}

#**********************************************************
=head2 unifi()

=cut
#**********************************************************
sub unifi {

  my ($username,
   $password,
   $userip,
   $usermac,
  ) =
  ( 'test',
    '123456',
    '192.168.100.11',
    '00:22:33:44:55:66',
  );

  $conf{'UNIFI_IP'} = '10.244.127.232';
  $debug = 0;

  my %RAD = (
    'Acct-Status-Type'   => 1,
    'User-Name'          => $username,
    'Password'           => $password,
    'Acct-Session-Id'    => '_id' || mk_unique_value(10),
    'Framed-IP-Address'  => $userip || '',
    'Calling-Station-Id' => $usermac || '',
    'Called-Station-Id'  => 'ap_mac',
    'NAS-IP-Address'     => $conf{'UNIFI_IP'},
    #'NAS-Port'          => $Dv->{PORT},
        #'Filter-Id'         => $Dv->{FILTER_ID} || $Dv->{TP_FILTER_ID},
    'Connect-Info'       => '_id',
  );

  require AXbills::SQL;
  AXbills::SQL->import();
  require Nas;
  Nas->import();

  $db = AXbills::SQL->connect($conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd}, { %conf, CHARSET => ($conf{dbcharset}) ? $conf{dbcharset} : undef });
  my $Auth;

  if (in_array('Internet', \@MODULES)) {
    require Auth2;
    Auth2->import();
    $Auth = Auth2->new($db, \%conf);
  }
  else {
    require Auth;
    Auth->import();
    $Auth = Auth->new($db, \%conf);
  }
  my $Nas = Nas->new($db, \%conf);

  if ($debug) {
    $Auth->{debug} = 1;
    $Nas->{debug}  = 1;
  }

  $Nas->info({
    IP     => $conf{'UNIFI_IP'},
    #NAS_ID => $RAD->{'NAS-Identifier'}
  });

  my ($r, $RAD_PAIRS);
  if (in_array('Internet', \@MODULES)) {
    ($r, $RAD_PAIRS) = $Auth->internet_auth(\%RAD, $Nas, { SECRETKEY => $conf{secretkey} });
  }

  my $text = "Result: ($r) ". (($r) ? 'fail' : 'ok' ) ."\n";
  foreach my $key (keys %$RAD_PAIRS) {
    $text .= "$key -> $RAD_PAIRS->{$key}\n";
  }

  print $text;

  return 1;
}

#**********************************************************
=head2 _rad($attr) - Base AAA test

=cut
#**********************************************************
sub _rad {
  my ($attr)=@_;

  if ($debug > 0) {
    print "Test radius\n";
  }

  my $rad_file = $argv->{rad_file} || q{};

  $attr->{rad_file}=$rad_file;

  my @users_arr = ();
  if ( $argv->{get_db_users} ) {
    require Users;

    my $Users = Users->new($db, undef, \%conf);

    my $users_list = $Users->list({
      LOGIN     => '_SHOW',
      PASSWORD  => '_SHOW',
      DOMAIN_ID => 0,
      PAGE_ROWS => $count,
      COLS_NAME => 1
    });

    foreach my $u (@$users_list) {
      push @users_arr, {
        'User-Name'      => $u->{login},
        'Password'       => $u->{password},
        'NAS-IP-Address' => '127.0.0.1'
      };
    }
  }
  elsif($rad_file) {
    my $load_file = (-f $rad_file . '.auth') ? $rad_file . '.auth' : $rad_file;
    %RAD_REQUEST = %{ load_rad_pairs($load_file) };
  }
  else {
    %RAD_REQUEST = (
      'User-Name'      => 'test',
      'Password'       => '123456',
      'NAS-IP-Address' => '127.0.0.1',
      'Acct-Session-Id'=> 'test_id' . mk_unique_value(10)
    );
  }

  if($argv->{NAS_IP}) {
    $RAD_REQUEST{'NAS-IP-Address'}=$argv->{NAS_IP};
  }

  $Bin = $Bin .'/../libexec/';
  do "rlm_perl.pl";
  #my $thread_mode = 1;

  if ($attr->{acct}) {
    print " acct \n";
    timethis($count, sub{ acct => accounting(); });
  }
  elsif($argv->{thread_mode}) {
    print "Thread mode  \n";
    my $thread_count = $argv->{thread_mode} || 5;

    timethis($count, sub{
      my @threads = ();
      for my $i (1..$thread_count) {
        push @threads, threads->create(
          sub{
            %RAD_REQUEST = %{ $users_arr[ rand($#users_arr + 1) ] };
            authenticate();
          },
          $i);
      }

      foreach my $thread (@threads) {
        $thread->join();
      }

                        });
  }
  elsif($attr->{dhcp_test}) {
    print "Mac_auth test\n";
    if($#ARGV < 1) {
      print "use Aaa.t dhcp_test Mac_auth.rad $#ARGV\n";
      exit;
    }
    #post_auth();
    mac_auth();
  }
  elsif($argv->{benchmark}) {
    print " benchmark auth count: $count\n";

    my %RAD = %RAD_REQUEST;

    timethis($count, sub{
      if(%RAD) {
        %RAD_REQUEST = %RAD;
      }
      elsif($#users_arr > -1){
        %RAD_REQUEST = %{ $users_arr[ rand( $#users_arr + 1 ) ] };
      }

      authenticate();
    });
  }
  else {
    aaa_base($attr);
  }

  if ($argv->{show_result} || $debug > 2) {
    show_reply(\%RAD_REPLY);
  }

  return 1;
}


#**********************************************************
=head2 aaa_base($attr); - Load file from file

=cut
#**********************************************************
sub aaa_base{
  my ($attr)=@_;

  if($debug) {
    print "Basic\n";
  }

  my $rad_file = $attr->{rad_file} || q{};

  if ($debug > 4) {
    show_reply(\%RAD_REQUEST, 'authenticate request');
  }

  my $ret = authenticate();
  print "  authenticate: $ret\n";
  ok($ret);
  if(! $ret) {
    show_reply(\%RAD_REPLY);
    %RAD_REPLY = ();
  }

  if($attr->{auth}) {
    return 1;
  }

  if ($debug > 4) {
    show_reply(\%RAD_REQUEST, 'authorize request');
  }

  $ret = authorize();
  print "  authorize: $ret\n";
  ok($ret);

  show_reply(\%RAD_REPLY, 'RAd:REPLY:');

  %RAD_REPLY = ();

  if($rad_file && -f $rad_file.'.acct_start') {
    %RAD_REQUEST = %{ load_rad_pairs($rad_file.'.acct_start') };
  }
  else {
    $RAD_REQUEST{'Acct-Status-Type'} = 'Start';
    $RAD_REQUEST{'Acct-Session-Id'} =  $RAD_REQUEST{'Acct-Session-Id'} || ('test_id' . mk_unique_value(10)),  # 'testsesion_1';
    $RAD_REQUEST{'Framed-IP-Address'} = '192.168.100.20';
  }

  if ($debug > 4) {
    show_reply(\%RAD_REQUEST, 'accounting '. $RAD_REQUEST{'Acct-Status-Type'});
  }

  $ret = accounting();
  print "  accounting 'Start': $ret\n";
  ok($ret);

  if($rad_file && -f $rad_file.'.acct_alive') {
    %RAD_REQUEST = %{ load_rad_pairs($rad_file.'.acct_alive') };
  }

  $RAD_REQUEST{'Acct-Session-Time'}=200;
  $RAD_REQUEST{'Acct-Status-Type'}='Interim-Update';

  if ($debug > 4) {
    show_reply(\%RAD_REQUEST, 'accounting '. $RAD_REQUEST{'Acct-Status-Type'});
  }

  $ret = accounting();
  print "  accounting '$RAD_REQUEST{'Acct-Status-Type'}': $ret\n";
  ok($ret);

  if($rad_file && -f $rad_file.'.acct_stop') {
    %RAD_REQUEST = %{ load_rad_pairs($rad_file.'.acct_stop') };
  }
  else {
    $RAD_REQUEST{'Acct-Session-Time'}  = 300;
    $RAD_REQUEST{'Acct-Output-Octets'} = 11111111;
    $RAD_REQUEST{'Acct-Input-Octets'}  = 22222222;
  }

  $RAD_REQUEST{'Acct-Status-Type'}='Stop';

  if ($debug > 4) {
    show_reply(\%RAD_REQUEST, 'accounting '. $RAD_REQUEST{'Acct-Status-Type'});
  }

  $ret = accounting();
  print "  accounting 'Stop': $ret\n";
  ok($ret);

  return 1;
}

#**********************************************************
=head2 load_rad_pairs($filename); - Load file from file

=cut
#**********************************************************
sub load_rad_pairs {
  my ($filename) = @_;

  if (! $filename || ! -f $filename) {
    print "File not found '$filename'.\n User rad_file=\n";
    exit;
  }

  print "Load rad file: $filename\n" if ($debug > 0);

  my $content   = '';
  my %rad_pairs = ();

  open(my $fh, '<', $filename) or die "Can;t load '$filename' $!";
    while(<$fh>) {
      $content .= $_;
    }
  close($fh);

  my @rows = split(/[\r\n]+/, $content);

  foreach my $line (@rows) {
    my ($key, $val) = split(/\s+\+?=\s+/, $line, 2);
    if (! $key) {
      next;
    }
    $key =~ s/^\s+//;
    $key =~ s/\s+$//;
    $val =~ s/^\s+//;
    $val =~ s/\s+$//;
    $val =~ s/\"$//;
    $val =~ s/^\"//;
    $val =~ s/\'$//;
    $val =~ s/^\'//;
    $rad_pairs{$key}=$val;
  }

  if ($debug > 2) {
    foreach my $key (sort keys %rad_pairs) {
      print "  $key -> $rad_pairs{$key}\n";
    }
  }

  return \%rad_pairs;
}


#**********************************************************
=head2 get_nas_info() - test nas

=cut
#**********************************************************
sub get_nas_info {
  require Nas;
  Nas->import();

  my $Nas = Nas->new($db, \%conf);
  my %NAS_PARAMS = ( IP => '127.0.0.1' );

  cmpthese( $count, {
    #nas_new    => sub{ $Nas = $Nas->info2({ %NAS_PARAMS, SHORT => 1 }) },
    nas_short  => sub{ $Nas = $Nas->info({ %NAS_PARAMS, SHORT => 1 });  },
    nas        => sub{ $Nas = $Nas->info({ %NAS_PARAMS  });   }
  });

  return 1;
}

#**********************************************************
=head2 _get_ip()

=cut
#**********************************************************
sub _get_ip {
  print "Get IP: count: $count\n";

  require Auth2;
  Auth2->import();
  my $Auth = Auth2->new($db, \%conf);

#  my $first_ip = 185273108;
#  my $ip_count = 65000;
#  for (my $i = $first_ip; $i <= $first_ip + $ip_count; $i++) {
#    $Auth->query2("INSERT INTO ippools_ips (ip, status, ippool_id) VALUES ('$i', 0, '44');", 'do');
#  }

  timethis($count, sub{
    $Auth->query2("DELETE FROM internet_online WHERE user_name='test';", 'do');

    #$Auth->{debug}=1;
    $Auth->{USER_NAME}='test';
    my $ip = $Auth->get_ip(7, '127.0.0.1',
      {
        #      TP_IPPOOL => $self->{NEG_DEPOSIT_IPPOOL} || $self->{TP_IPPOOL},
        #      GUEST     => 1,
        #      VLAN      => $self->{SERVER_VLAN}, #$self->{VLAN}
        #      CONNECT_INFO => $self->{IP}
      });
  });

  $conf{GET_IP2}=1;
  $Auth = Auth2->new($db, \%conf);

  timethis($count, sub{
    $Auth->query2("DELETE FROM internet_online WHERE user_name='test';", 'do');
    #$Auth->{debug}=1;
    $Auth->{USER_NAME}='test';
    my $ip = $Auth->get_ip2(7, '127.0.0.1',
      {
        #      TP_IPPOOL => $self->{NEG_DEPOSIT_IPPOOL} || $self->{TP_IPPOOL},
        #      GUEST     => 1,
        #      VLAN      => $self->{SERVER_VLAN}, #$self->{VLAN}
        #      CONNECT_INFO => $self->{IP}
      });
  });


  return 1;
}


#**********************************************************
=head2 help()

=cut
#**********************************************************
sub help  {

print << "[END]";

nas      - Nas get
get_ip   - Get IP
rad_auth - RAD Auth
  benchmark - Make banchmark
  get_db_users - Use db users for auth
  NAS_IP  - Nas IP radius param NAS-IP-Address
rad_acct - RAD Acct
rad_file - RAD File
show_result - Show RAD result
unifi    - unifi test

dhcp_test   - test dhcp (Mac_auth.pm)
thread_mode - Thread mode

debug=   - Debug mode
count=   - Test Count
help     - help

[END]

}

1
