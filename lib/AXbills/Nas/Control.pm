package AXbills::Nas::Control;

#***********************************************************
=head1 NAME

  NAS controlling functions
    get_acct_info
    hangup
    check_activity

=cut
#***********************************************************

use strict;
use warnings;
use BER;
use SNMP_Session;
use SNMP_util;
use Socket;
use Radius;
use AXbills::Defs;
use AXbills::Base qw(ip2int cmd in_array);
use parent 'Exporter';
use FindBin '$Bin';
use Log;

our @EXPORT = qw(
  hangup
  telnet_cmd
  telnet_cmd2
  telnet_cmd3
  hangup_snmp
  rsh_cmd
  hascoa
  setspeed
);

our @EXPORT_OK = qw(
  hangup
  telnet_cmd
  telnet_cmd2
  telnet_cmd3
  hangup_snmp
  rsh_cmd
  hascoa
  setspeed
);

my $USER_NAME = '';
my $debug = 0;
our $base_dir;
my $Log;
my $CONF;
my $db;

sub new {
  my $class = shift;
  $db = shift;
  ($CONF) = @_;

  my $self = {};

  bless($self, $class);

  if ($db) {
    $Log = Log->new($db, $CONF);
  }

  if (!$base_dir) {
    $base_dir = '/usr/axbills/';
  }

  return $self;
}

#***********************************************************
=head1 hangup($Nas, $attr);

  Hangup active port (user,cids)

  Arguments:
    $NAS_HASH_REF - NAS information
    $PORT         - NAS port
    $USER         - User LOGIN
    $attr         - Extra atttributes
      SESSION_ID
      ACCT_SESSION_ID
      CALLING_STATION_ID
      FRAMED_IP_ADDRESS
      UID
      NETMASK
      FILTER_ID
      CID
      LOG         - Log object
      COA_ACTION  - ARRAY_ref of RADIUS pairs

  Returns:

=cut
#***********************************************************
sub hangup {
  my $self = shift;
  my ($Nas, $PORT, $USER, $attr) = @_;

  my $nas_type = $Nas->{NAS_TYPE} || '';
  my %params = ();
  if ($attr && (ref $attr eq 'HASH' || ref $attr eq 'Internet::Sessions')) {%params = %$attr;
    $params{SESSION_ID} = $attr->{ACCT_SESSION_ID} if ($attr->{ACCT_SESSION_ID});
  }

  if ($attr->{DEBUG}) {
    $debug = $attr->{DEBUG};
  }

  $params{PORT} = $PORT;
  $params{USER} = $USER;
  $USER_NAME = $USER;

  if (-f "Nas/$nas_type" . '.pm') {
    do "Nas/$nas_type" . '.pm';
    my $fn = 'hangup_' . $nas_type;
    if (defined($fn)) {
      $fn->($Nas, \%params);
    }
  }
  elsif ($attr->{COA_ACTION}) {
    $params{COA}=1;

    if (ref $attr->{COA_ACTION} eq 'ARRAY') {
      foreach my $coa_request ( @{ $attr->{COA_ACTION} } ) {
        $params{RAD_PAIRS} = $coa_request;

        $self->radius_request($Nas, \%params);
      }
    }
    else {
      $params{RAD_PAIRS} = $attr->{COA_ACTION};
      $self->radius_request($Nas, \%params);
    }
  }
  elsif ($nas_type eq 'mikrotik') {
    my ($ip, $mng_port, $second_port, undef) = split(/:/, $Nas->{NAS_MNG_IP_PORT} || q{}, 4);
    #IPN Hangup if COA port 0
    if ($ip && !$mng_port && $second_port && $second_port > 0) {
      #$Nas->{NAS_MNG_IP_PORT} = "$ip:$second_port";
      hangup_ipoe($Nas, \%params);
    }
    else {
      $params{RAD_PAIRS} = {
        'User-Name'        => $USER_NAME,
        'Framed-IP-Address'=> $attr->{FRAMED_IP_ADDRESS},
        'Acct-Session-Id'  => $attr->{SESSION_ID} || $attr->{ACCT_SESSION_ID}
      };

      $self->radius_request($Nas, \%params);
    }
  }
  elsif ($nas_type eq 'huawei_me60') {
    $params{RAD_PAIRS} = {
      'Acct-Session-Id'  => $attr->{SESSION_ID} || $attr->{ACCT_SESSION_ID}
    };

    $self->radius_request($Nas, \%params);
  }
  elsif ($nas_type eq 'radpppd') {
    hangup_radpppd($Nas, \%params);
  }
  elsif ($nas_type eq 'chillispot') {
    $Nas->{NAS_MNG_IP_PORT} = "$Nas->{NAS_IP}:3799" if (!$Nas->{NAS_MNG_IP_PORT});
    $self->radius_request($Nas, \%params);
  }
  elsif ($nas_type eq 'usr') {
    hangup_snmp(
      $Nas, $PORT,
      {
        OID   => '.1.3.6.1.4.1.429.4.10.13.' . $PORT,
        TYPE  => 'integer',
        VALUE => 9
      }
    );
  }
  elsif ($nas_type eq 'cisco') {
    $self->hangup_cisco($Nas, \%params);
  }
  elsif ($nas_type eq 'unifi') {
    hangup_unifi($Nas, \%params)
  }
  elsif ($nas_type eq 'cisco_isg') {
    $self->hangup_cisco_isg($Nas, \%params);
  }
  elsif ($nas_type eq 'mpd5') {
    $self->hangup_mpd5($Nas, \%params);
  }
  elsif ($nas_type eq 'openvpn') {
    $self->hangup_openvpn($Nas, \%params);
  }
  elsif ($nas_type eq 'ipcad'
    || $nas_type eq 'mikrotik_dhcp'
    || $nas_type eq 'dhcp'
    || $nas_type eq 'ipn'
    || ( $CONF->{INTERNET_IPOE_NAS_TYPES} && $CONF->{INTERNET_IPOE_NAS_TYPES} =~ /$nas_type/)
  ) {
    hangup_ipoe($Nas, \%params);
  }
  elsif ($nas_type eq 'pppd' || $nas_type eq 'lepppd') {
    hangup_pppd($Nas, \%params);
  }
  # http://sourceforge.net/projects/radcoad/
  elsif ($nas_type eq 'pppd_coa') {
    hangup_pppd_coa($Nas, \%params);
  }
  elsif ($nas_type eq 'accel_ppp' || $nas_type eq 'accel_ipoe') {
    $USER =~ s/^!\s?//;
    $params{RAD_PAIRS} = {
      # 'User-Name' => $USER,
      'Acct-Session-Id' => $attr->{SESSION_ID} || $attr->{ACCT_SESSION_ID}
    };

    $self->radius_request($Nas, \%params);
  }
  elsif ( $nas_type eq 'redback' || $nas_type eq 'zte_m6000'){
    if($attr->{CONNECT_INFO} && $attr->{CONNECT_INFO} !~ /pppoe/) {
      my $cid = $attr->{CID} || $attr->{CALLING_STATION_ID} || '';
      $cid =~ s/\-/:/g;
      $params{RAD_PAIRS}->{'User-Name'} = $cid;
    }
    $self->radius_request( $Nas, \%params );
  }
  elsif ($nas_type eq 'mx80') {
    $params{RAD_PAIRS}->{'Acct-Session-Id'} = $params{SESSION_ID};
    $self->radius_request($Nas, \%params);
  }
  elsif ($Nas->{NAS_MNG_IP_PORT} && $Nas->{NAS_MNG_IP_PORT} =~ /\d+\.\d+\.\d+\.\d+:\d+:/) {
    $self->radius_request($Nas, \%params);
  }
  elsif ($nas_type eq 'lisg_cst') {
    $self->radius_request($Nas, \%params);
  }
  else {
    return 1;
  }

  return 0;
}

#***********************************************************
=head2 get_stats($nas, $PORT, $attr) - Get stats

=cut
#***********************************************************
sub get_stats {
  my (undef, $Nas, $PORT) = @_;

  my $nas_type = $Nas->{NAS_TYPE};
  my %stats;
  if ($nas_type eq 'usr') {
    %stats = stats_usrns($Nas, $PORT);
  }
  else {
    return 0;
  }

  return \%stats;
}

#***********************************************************
=head2 telnet_cmd($hostname, $commands, $attr)

=cut
#***********************************************************
sub telnet_cmd {
  my ($hostname, $commands) = @_;
  my $port = 23;

  if ($hostname =~ /:/) {
    ($hostname, $port) = split(/:/, $hostname, 2);
  }

  #my $timeout = defined($attr->{'TimeOut'}) ? $attr->{'TimeOut'} : 5;

  my $dest = sockaddr_in($port, Socket::inet_aton("$hostname"));
  my $SH;

  if (!socket($SH, PF_INET, SOCK_STREAM, getprotobyname('tcp'))) {
    print "ERR: Can't init '$hostname:$port' $!";
    return 0;
  }

  if (!CORE::connect($SH, $dest)) {
    print "ERR: Can't connect to '$hostname:$port' $!";
    return 0;
  }

  $Log->log_print('LOG_DEBUG', "$USER_NAME", "Connected to $hostname:$port", { ACTION => 'CMD' });

  #my $sock   = $SH;
  my $MAXBUF = 512;
  my $input = '';
  my $len = 0;
  my $text = '';
  my $inbuf = '';
  my $res = '';

  my $old_fh = select($SH);
  $| = 1;
  select($old_fh);

  $SH->autoflush(1);

  foreach my $line (@{$commands}) {
    my ($waitfor, $sendtext) = split(/\t/, $line, 2);
    my $wait_len = length($waitfor);
    $input = '';

    if ($waitfor eq '-') {
      send($SH, "$sendtext\n", 0, $dest) or die $Log->log_print('LOG_INFO', "$USER_NAME", "Can't send: '$text' $!",
        { ACTION => 'CMD' });
    }

    do {
      eval {
        local $SIG{ALRM} = sub {die "alarm\n"}; # NB: \n обязателен
        alarm 5;
        recv($SH, $inbuf, $MAXBUF, 0);
        alarm 0;
      };

      if ($@) {
        return $res;
      }

      $input .= $inbuf;
      $len = length($inbuf);
    } while ($len >= $MAXBUF || $len < $wait_len);

    $Log->log_print('LOG_DEBUG', "$USER_NAME", "Get: \"$input\"\nLength: $len", { ACTION => 'CMD' });
    $Log->log_print('LOG_DEBUG', "$USER_NAME", " Wait for: '$waitfor'", { ACTION => 'CMD' });

    if ($input =~ /$waitfor/ig) {
      # || $waitfor eq '') {
      $text = $sendtext;
      $Log->log_print('LOG_DEBUG', "$USER_NAME", "Send: $text", { ACTION => 'CMD' });
      send($SH, "$text\n", 0, $dest) or die $Log->log_print('LOG_INFO', "$USER_NAME", "Can't send: '$text' $!",
        { ACTION => 'CMD' });
    }

    $res .= "$input\n";
  }

  close($SH);
  return $res;
}

#**********************************************************
=head2 telnet_cmd2($host, $commands, $attr)

=cut
#**********************************************************
sub telnet_cmd2 {
  my ($host, $commands, $attr) = @_;
  my $port = 23;

  if ($host =~ /:/) {
    ($host, $port) = split(/:/, $host, 2);
  }

  if(! $Log) {
    $Log = Log->new($db, $CONF);
  }

  use IO::Socket;
  use IO::Select;
  my $res;

  my $timeout = defined($attr->{'TimeOut'}) ? $attr->{'TimeOut'} : 5;
  my $socket = IO::Socket::INET->new(
    PeerAddr => $host,
    PeerPort => $port,
    Proto    => 'tcp',
    TimeOut  => $timeout
  ) or $Log->log_print('LOG_DEBUG', "$USER_NAME", "ERR: Can't connect to '$host:$port' $!", { ACTION => 'CMD' });

  if (! $socket) {
    print "ERR: Can't connect to '$host:$port' $!";
    return $res;
  }

  $Log->log_print('LOG_DEBUG', '', "Connected to $host:$port");

  foreach my $line (@{$commands}) {
    my ($waitfor, $sendtext) = split(/\t/, $line, 2);

    $Log->log_print('LOG_DEBUG', "$USER_NAME", " Wait for: '$waitfor' Send: '$sendtext'", { ACTION => 'CMD' });

    $socket->send("$sendtext");
    while (<$socket>) {
      $res .= $_;
    }
  }

  close($socket);

  return $res;
}

#***********************************************************
=head2 telnet_cmd3($hostname, $commands, $attr)

  Arguments:
    $hostname
    $commands
    $attr
      DEBUG
      LOG   - Log identifier

  Results:


=cut
#***********************************************************
sub telnet_cmd3 {
  my ($hostname, $commands, $attr) = @_;
  my $port = 23;

  if ($hostname =~ /:/) {
    ($hostname, $port) = split(/:/, $hostname, 2);
  }

  if ($attr->{LOG}) {
    $Log = $attr->{LOG};
  }
  #  my $timeout = defined($attr->{'TimeOut'}) ? $attr->{'TimeOut'} : 5;

  my $dest = sockaddr_in($port, inet_aton("$hostname"));
  my $SH;

  if (!socket($SH, PF_INET, SOCK_STREAM, getprotobyname('tcp'))) {
    print "ERR: Can't init '$hostname:$port' $!";
    return 0;
  }

  if (!CORE::connect($SH, $dest)) {
    print "ERR: Can't connect to '$hostname:$port' $!";
    return 0;
  }

  $Log->log_print('LOG_DEBUG', "$USER_NAME", "Connected to $hostname:$port", { ACTION => 'CMD' });

  my $MAXBUF = 512;
  my $input = '';
  #my $len    = 0;
  #my $text   = '';
  my $inbuf = '';
  #my $res    = '';

  my $old_fh = select($SH);
  $| = 1;
  select($old_fh);

  $SH->autoflush(1);
  my $i = 0;
  foreach my $line (@{$commands}) {
    my ($waitfor, $sendtext) = split(/\t/, $line, 2);
    $input = '';
    $i++;

    while (1) {
      if ($debug > 0) {
        print $i . "\n";
      }

      eval {
        local $SIG{ALRM} = sub {die "alarm\n"}; # NB: \n обязателен
        alarm 5;
        recv($SH, $inbuf, $MAXBUF, 0);
        $input .= $inbuf;
        alarm 0;
      };
      if ($@) {
        if ($debug > 0) {
          print "Error:";
          print $@;
          print "-----\n";
        }
        last;
      }

      if ($input =~ /$waitfor/g) {
        last;
      }
      $i++
    };

    send($SH, "$sendtext\n", 0, $dest) or die "Can't send: '$sendtext' $!";

    if ($debug > 0) {
      print "Input: '$input'\n";
      print "Send: '$sendtext'\n";
    }
  }

  close($SH);

  return $input;
}


# #***********************************************************
# =head2 stats_pm25($NAS, $PORT) - Get stats from Livingston Portmaster
#
# =cut
# #***********************************************************
# sub stats_pm25 {
#   my ($NAS, $attr) = @_;
#
#   my %stats = (
#     in  => 0,
#     out => 0
#   );
#
#   my $PORT = $attr->{PORT};
#   my $PM25_PORT = $PORT + 2;
#   my $SNMP_COM = $NAS->{NAS_MNG_PASSWORD} || '';
#
#   my ($in) = snmpget($SNMP_COM . '@' . $NAS->{NAS_IP}, ".1.3.6.1.2.1.2.2.1.10.$PM25_PORT");
#   my ($out) = snmpget($SNMP_COM . '@' . $NAS->{NAS_IP}, ".1.3.6.1.2.1.2.2.1.16.$PM25_PORT");
#
#   if (!defined($in)) {
#     $stats{error} = 1;
#   }
#   elsif (int($in) + int($out) > 0) {
#     $stats{in} = int($in);
#     $stats{out} = int($out);
#   }
#
#   return %stats;
# }

# #***********************************************************
# # HANGUP pm25
# # hangup_pm25($SERVER, $PORT)
# #***********************************************************
# sub hangup_pm25 {
#   my ($NAS, $attr) = @_;
#
#   my $PORT = $attr->{PORT};
#   my @commands = ();
#   push @commands, "login:\t$NAS->{NAS_MNG_USER}";
#   push @commands, "Password:\t$NAS->{NAS_MNG_PASSWORD}";
#   push @commands, ">\treset S$PORT";
#   push @commands, ">exit";
#
#   my $result = telnet_cmd("$NAS->{NAS_IP}", \@commands);
#   print $result;
#
#   return 0;
# }

#***********************************************************
=head2 stats_usrns($NAS, $PORT) - Get stats from USR Netserver 8/16

=cut
#***********************************************************
# sub stats_usrns {
#   my ($NAS, $attr) = @_;
#
#   my $SNMP_COM = $NAS->{NAS_MNG_PASSWORD} || '';
#   my $PORT = $attr->{PORT};
#   my %stats = ();
#   #USR trafic taker
#   my $in = snmpget("$SNMP_COM\@$NAS->{NAS_IP}", "interfaces.ifTable.ifEntry.ifInOctets.$PORT");
#   my $out = snmpget("$SNMP_COM\@$NAS->{NAS_IP}", "interfaces.ifTable.ifEntry.ifOutOctets.$PORT");
#
#   $stats{in} = int($in);
#   $stats{out} = int($out);
#
#   return %stats;
# }

####################################################################
=head2 stats_ppp($NAS)

   Standart FreeBSD ppp

   get accounting information from FreeBSD ppp using remove accountin
   scrips
   stats_ppp($NAS)

=cut
#************************************************************
sub stats_ppp {
  my ($NAS) = @_;

  use IO::Socket;
  my $port = 30006;

  my %stats = ();
  my ($ip, $mng_port) = split(/:/, $NAS->{NAS_MNG_IP_PORT}, 3);
  $port = $mng_port || 0;

  my $remote = IO::Socket::INET->new(
    Proto    => "tcp",
    PeerAddr => $ip,
    PeerPort => $port
  ) or print "cannot connect to pppcons port at $NAS->{NAS_IP}:$port $!\n";

  while (<$remote>) {
    my ($radport, $in, $out, $tun) = split(/ +/, $_);
    $stats{ $NAS->{NAS_IP} }{$radport}{in} = $in;
    $stats{ $NAS->{NAS_IP} }{$radport}{out} = $out;
    $stats{ $NAS->{NAS_IP} }{$radport}{tun} = $tun;
  }

  return %stats;
}


#**********************************************************
=head2 hangup_snmp($NAS, $attr) Base SNMP set hangup function

=cut
#**********************************************************
sub hangup_snmp {
  my ($NAS, $attr) = @_;

  my $oid = $attr->{OID};
  my $type = $attr->{TYPE} || 'integer';
  my $value = $attr->{VALUE};

  $Log->log_print('LOG_DEBUG', '', "SNMPSET: $NAS->{NAS_MNG_PASSWORD}\@$NAS->{NAS_IP} $oid $type $value",
    { ACTION => 'CMD' });
  my $result = snmpset("$NAS->{NAS_MNG_PASSWORD}\@$NAS->{NAS_IP}", "$oid", "$type", $value);

  if ($SNMP_Session::errmsg) {
    $Log->log_print('LOG_ERR', '', "$SNMP_Session::suppress_warnings / $SNMP_Session::errmsg", { ACTION => 'CMD' });
  }

  return $result;
}

#***********************************************************
=head2 radius_request($NAS, $attr) - hangup_radius

  Arguments:
    $NAS   -
    $attr  -
      USER
      FRAMED_IP_ADDRESS
      SESSION_ID
      RAD_PAIRS          - Use custom radius pairs form disconnect
      COA                - Change request type to CoA
      DEBUG

  Radius-Disconnect messages
    rfc2882

=cut
#***********************************************************
sub radius_request {
  my $self = shift;
  my ($NAS, $attr) = @_;

  my $USER = $attr->{USER} || q{};
  if (!$NAS->{NAS_MNG_IP_PORT}) {
    print "Radius Hangup failed. Can't find NAS IP and port. NAS: $NAS->{NAS_ID} USER: $USER\n";
    return 'ERR:';
  }

  my ($ip, $mng_port, undef) = split(/:/, $NAS->{NAS_MNG_IP_PORT}, 3);

  if (!$ip) {
    print "Radius Hangup failed. Can't find NAS IP and port. NAS: $NAS->{NAS_ID} USER: $USER\n";
    return 'ERR:';
  }

  $mng_port = 1700 if (!$mng_port);
  my $nas_password = $NAS->{NAS_MNG_PASSWORD} || q{};
  $Log->log_print('LOG_DEBUG', $USER,
    "HANGUP: User-Name=$USER Framed-IP-Address=" . ($attr->{FRAMED_IP_ADDRESS} || q{})
      . " NAS_MNG: $ip:$mng_port '$nas_password'"
    , { ACTION => 'CMD', NAS => $NAS });

  my $type;
  my $r = Radius->new(
    Host   => $ip . ':' . $mng_port,
    Secret => $nas_password,
    Debug  => $attr->{DEBUG} || 0
  ) or return "Can't connect '" . $ip . ':' . $mng_port . "' $!";

  $CONF->{'dictionary'} = $base_dir . '/lib/dictionary' if (!$CONF->{'dictionary'});

  if (!-f $CONF->{'dictionary'}) {
    print "Can't find radius dictionary: $CONF->{'dictionary'}";
    return 0;
  }

  $r->load_dictionary($CONF->{'dictionary'});

  my %rad_pairs = ();

  if ($attr->{RAD_PAIRS}) {
    %rad_pairs = %{$attr->{RAD_PAIRS}};
  }
  else {
    if ($attr->{SESSION_ID}) {
      $rad_pairs{'Acct-Session-Id'} = $attr->{SESSION_ID} if ($USER);
      if ($USER) {
        $USER =~ s/^!\s?//;
        $rad_pairs{'User-Name'} = $USER;
      }
    }
    else {
      $rad_pairs{'Framed-IP-Address'} = $attr->{FRAMED_IP_ADDRESS} if ($attr->{FRAMED_IP_ADDRESS});
    }
  }

  while (my ($k, $v) = each %rad_pairs) {
    print " $k Value => $v \n" if ($attr->{DEBUG});
    $r->add_attributes({ Name => $k, Value => $v });
  }

  my $request_type = ($attr->{COA}) ? 'COA' : 'POD';

  if ($attr->{COA}) {
    $r->send_packet(COA_REQUEST) and $type = $r->recv_packet;
  }
  else {
    $r->send_packet(DISCONNECT_REQUEST) and $type = $r->recv_packet;
  }

  my $result;
  if (!defined $type) {
    # No responce from COA/POD server
    my $message = "No responce from $request_type server '$NAS->{NAS_MNG_IP_PORT}'";
    $result .= $message;
    $self->{error}=3;
    $self->{errstr}=$message;
    $Log->log_print('LOG_DEBUG', "$USER", $message, { ACTION => 'CMD' });
  }

  $self->{rad_return}=$type;
  delete $self->{rad_pairs};
  for my $rad ($r->get_attributes) {
    $result .= ">> ". ($rad->{'Name'} || 'NO_NAME') .' -> '. ($rad->{'Value'} || q{NO_VALUE}) ."\n";
    $self->{rad_pairs}->{$rad->{'Name'}}=$rad->{'Value'};
  }

  if ($attr->{DEBUG}) {
    print "Radius Return: " . ($type || q{}) . "\n Result: " . ($result || "Empty\n");
  }

  $self->{RESULT}=$result;

  return $result;
}

#***********************************************************
=head2 hangup_mikrotik_telnet($NAS, $attr)

=cut
#***********************************************************
sub hangup_mikrotik_telnet {
  my ($NAS, $attr) = @_;

  my $USER = $attr->{USER};
  my @commands = ();

  push @commands, "Login:\t$NAS->{NAS_MNG_USER}";
  push @commands, "Password:\t$NAS->{NAS_MNG_PASSWORD}";
  push @commands, ">/interface pptp-server remove [find user=$USER]";
  push @commands, ">quit";

  my $result = telnet_cmd2("$NAS->{NAS_IP}", \@commands);

  print $result;
}

#***********************************************************
=head2 hangup_ipoe($NAS, $attr)

  Arguments:
    $NAS
    $attr
      FRAMED_IP_ADDRESS
      UID
      NETMASK
      NAS_TYPE
      FILTER_ID

=cut
#***********************************************************
sub hangup_ipoe {
  my ($NAS, $attr) = @_;

  my $result = '';
  my $ip = $attr->{FRAMED_IP_ADDRESS} || 0;
  my $PORT = $attr->{PORT};
  my $netmask = $attr->{NETMASK} || $attr->{netmask} || 32;
  my $FILTER_ID = $attr->{FILTER_ID} || '';
  #my $nas_type = $NAS->{NAS_TYPE} || 'ipoe';

  if ($debug > 3) {
    print "Hangup ipcad: \n";
  }

  if ($netmask ne '32') {
    my $ips = 4294967296 - ip2int($netmask);
    $netmask = 32 - length(sprintf("%b", $ips)) + 1;
  }

  require Internet::Collector;
  Internet::Collector->import();
  my $Ipn = Internet::Collector->new($db, $CONF);

  if ($debug > 6) {
    $Ipn->{debug} = 1;
  }

  $Ipn->acct_stop({
    %{$attr},
    CID   => $attr->{CID} || $attr->{CALLING_STATION_ID} || 'nas_hangup',
    GUEST => $attr->{GUEST} || 0
  });

  if ($Ipn->{errno}) {
    print "Error: [ $Ipn->{errno} ] $Ipn->{errstr} \n";
  }

  # if ($nas_type eq 'dhcp'
  #   || $nas_type eq 'mikrotik_dhcp'
  #   || $nas_type eq 'dlink_pb'
  #   || $nas_type eq 'dlink'
  #   || $nas_type eq 'edge_core'
  # ) {
  #   if ($Ipn->can('query2')) {
  #     $Ipn->query2("DELETE FROM dhcphosts_leases WHERE ip=INET_ATON('$ip')", 'do');
  #   }
  #   else {
  #     $Ipn->query("DELETE FROM dhcphosts_leases WHERE ip=INET_ATON('$ip')", 'do');
  #   }
  # }

  my $num = 0;
  if ($attr->{UID} && $CONF->{IPN_FW_RULE_UID}) {
    $num = $attr->{UID} || 0;
  }
  else {
    my @ip_array = split(/\./, $ip, 4);
    $num = $ip_array[3] || 0;
  }

  my $rule_num = $CONF->{IPN_FW_FIRST_RULE} || 20000;
  $rule_num = $rule_num + 10000 + $num;

  if ($NAS->{NAS_MNG_IP_PORT}) {
    # ip / hangup / manage / snmp
    ($ENV{NAS_MNG_IP}, undef, $ENV{NAS_MNG_PORT}) = split(/:/, $NAS->{NAS_MNG_IP_PORT});
    $ENV{NAS_MNG_USER} = $NAS->{NAS_MNG_USER};
    $ENV{NAS_MNG_PASSWORD} = $NAS->{NAS_MNG_PASSWORD};
    $ENV{NAS_MNG_IP_PORT} = $NAS->{NAS_MNG_IP_PORT};
    $ENV{NAS_ID} = $NAS->{NAS_ID};
    $ENV{NAS_TYPE} = $NAS->{NAS_TYPE};
    $ENV{NAS_MNG_PORT} ||= 22;
  }

  my $uid = $attr->{UID};

  my $filter_rule = $CONF->{IPN_FILTER} || $CONF->{IPN_FILTER};
  if ($filter_rule) {
    my $cmd = $filter_rule;
    $cmd =~ s/\%STATUS/HANGUP/g;
    $cmd =~ s/\%IP/$ip/g;
    $cmd =~ s/\%LOGIN/$USER_NAME/g;
    $cmd =~ s/\%FILTER_ID/$FILTER_ID/g;
    $cmd =~ s/\%UID/$uid/g;
    $cmd =~ s/\%PORT/$PORT/g;
    $cmd =~ s/\%MASK/$netmask/g;

    cmd($cmd, {
      COMMENT => "IPoE Filter rule:",
      DEBUG   => ($debug > 5) ? ($debug - 3) : 0
    });
  }

  my $cmd = $CONF->{INTERNET_IPOE_STOP} || $CONF->{IPN_FW_STOP_RULE};
  if ($cmd) {
    $cmd =~ s/\%IP/$ip/g;
    $cmd =~ s/\%MASK/$netmask/g;
    $cmd =~ s/\%NUM/$rule_num/g;
    $cmd =~ s/\%LOGIN/$USER_NAME/g;
    $cmd =~ s/\%MASK/$netmask/g;
    $cmd =~ s/\%OLD_TP_ID/$attr->{OLD_TP_ID}/g;

    $Log->log_print('LOG_DEBUG', '', $cmd, { ACTION => 'CMD' });
    if ($debug > 4) {
      print $cmd . "\n";
    }

    $result = cmd($cmd, {
      COMMENT => "IPoE Stop rule:",
      DEBUG   => ($debug > 5) ? ($debug - 3) : 0
    });
  }

  return $result;
}

#***********************************************************
=head2 hangup_openvpn($NAS, $attr)

  Arguments:
    $NAS
    $attr

  Results:
    $result

=cut
#***********************************************************
sub hangup_openvpn {
  my ($self, $NAS, $attr) = @_;

  my $USER = $attr->{USER};
  my $ip = $attr->{FRAMED_IP_ADDRESS};
  my @commands = (
    "WORD:\t$NAS->{NAS_MNG_PASSWORD}",
    "more info\tstatus",
    "\texit",
#    "more info\tkill $USER",
#    "SUCCESS: common name '$USER' found, 1 client(s) killed\texit"
  );

  my $result = telnet_cmd($NAS->{NAS_MNG_IP_PORT}, \@commands);
  my @rows = split(/\n/, $result);
  my $session = q{};
  foreach my $line (@rows) {
    print "$ip / $line <br>\n" if ($debug);
    if($line =~ /$ip,client,(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}:\d+),/) {
      $session = $1;
      print ">> $session <<" if ($debug);
    }
  }

  if ($session) {
    @commands = (
      "WORD:\t$NAS->{NAS_MNG_PASSWORD}",
      "more info\tkill $session",
      "\texit",
    );

    $result = telnet_cmd($NAS->{NAS_MNG_IP_PORT}, \@commands);
  }

  $Log->log_print('LOG_DEBUG', $USER, "$result", { ACTION => 'CMD' });

  return 0;
}

#***********************************************************
=head2 hangup_cisco_isg($NAS, $attr) - HANGUP Cisco ISG

   Arguments:
     $NAS
     $attr
       USER

   ip rcmd rcp-enable
   ip rcmd rsh-enable
   no ip rcmd domain-lookup
  ! ip rcmd remote-host имя_юзера_на_cisco IP_address_или_имя_компа_с_которого_запускается_скрипт имя_юзера_от_чьего_имени_будет_запукаться_скрипт enable
  ! например
   ip rcmd remote-host admin 192.168.0.254 root enable

=cut
#***********************************************************
sub hangup_cisco_isg {
  my $self = shift;
  my ($NAS, $attr) = @_;

  my $exec = '';
  my $command = '';
  my $result = q{};
  my $user = $attr->{USER};

  my ($nas_mng_ip, $coa_port, $ssh_port) = split(/:/, $NAS->{NAS_MNG_IP_PORT}, 3);

  if (!$coa_port) {
    $coa_port = 1700;
  }
  if (!$ssh_port) {
    $ssh_port = 22;
  }

  #RSH Version
  if ($attr->{RSH_HANGUP} && $NAS->{NAS_MNG_USER}) {
    my $cisco_user = $NAS->{NAS_MNG_USER};
    $command = "/usr/bin/rsh -l $cisco_user $nas_mng_ip clear ip subscriber ip $attr->{FRAMED_IP_ADDRESS}";
    $Log->log_print('LOG_DEBUG', $user, $command, { ACTION => 'CMD' });
    $exec = cmd($command);
  }

  # RADIUS POD Version
  else {
    my $type;
    my $r = Radius->new(
      Host   => "$nas_mng_ip:$coa_port",
      Secret => "$NAS->{NAS_MNG_PASSWORD}"
    ) or return "Can't connect '$NAS->{NAS_MNG_IP_PORT}' $!";

    $CONF->{'dictionary'} = '/usr/axbills/lib/dictionary' if (!$CONF->{'dictionary'});
    $r->load_dictionary($CONF->{'dictionary'});

    $r->add_attributes({ Name => 'User-Name', Value => "$attr->{USER}" });

    # We cannot uniquely identify a session by IP address when VRFs are used.
    # However, we can do it using a session ID (requires CSCek31466)
    if ($CONF->{INTERNET_ISG_KILL_WITH_SID}) {
      $r->add_attributes({ Name => 'Acct-Session-Id', Value => "$attr->{ACCT_SESSION_ID}" });
    }
    else {
       $r->add_attributes({ Name => 'Cisco-Account-Info', Value => "S$attr->{FRAMED_IP_ADDRESS}" });
    }

    $r->add_attributes({ Name => 'Cisco-AVPair', Value => "subscriber:command=account-logoff" });

    my $request_type = 'COA';
    $r->send_packet(COA_REQUEST) and $type = $r->recv_packet;

    if (!defined $type) {
      # No responce from COA/POD server
      my $message = "NO responce from $request_type server '$NAS->{NAS_MNG_IP_PORT}'";
      $result .= $message;
      $Log->log_print('LOG_DEBUG', "$attr->{USER}", $message, { ACTION => 'CMD' });
    }

    my %RAD_PAIRS = ();
    for my $rad ($r->get_attributes) {
      $RAD_PAIRS{ $rad->{'Name'} } = $rad->{'Value'};
      $result .= ">> $rad->{'Name'} -> $rad->{'Value'}\n";
    }

    if ($RAD_PAIRS{'Error-Cause'}) {
      #log_print('LOG_WARNING', "$RAD_PAIRS{'Error-Cause'} / $RAD_PAIRS{'Reply-Message'}");
      print "Error-Cause: $RAD_PAIRS{'Error-Cause'} Reply-Message: $RAD_PAIRS{'Reply-Message'}\n";

      $self->{RESULT}=$result;

      print %RAD_PAIRS;
    }

    if ($attr->{DEBUG}) {
      print "Radius Return: " . ($type || q{}) . "\n Result: " . ($result || 'Empty');
    }
  }

  return $result;
}

#***********************************************************
=head2 hangup_cisco($NAS, $attr) - HANGUP Cisco

 Cisco config  for rsh functions:
   ip rcmd rcp-enable
   ip rcmd rsh-enable
   no ip rcmd domain-lookup
    ! ip rcmd remote-host имя_юзера_на_cisco IP_address_или_имя_компа_с_которого_запускается_скрипт имя_юзера_от_чьего_имени_будет_запукаться_скрипт enable
    ! например
   ip rcmd remote-host admin 192.168.0.254 root enable

=cut
#***********************************************************
sub hangup_cisco {
  my $self = shift;
  my ($NAS, $attr) = @_;
  my $exec;
  my $command = '';
  my $user = $attr->{USER};
  my $PORT = $attr->{PORT};


  my ($nas_mng_ip, $mng_port) = split(/:/, $NAS->{NAS_MNG_IP_PORT}, 3);

  #POD Version
  if ($mng_port) {
    $self->radius_request($NAS, $attr);
  }
  #Rsh version
  elsif ($NAS->{NAS_MNG_USER}) {
    my $cisco_user = $NAS->{NAS_MNG_USER};
    if ($PORT > 0) {
      $| = 1;
      $command = "(/bin/sleep 5; /bin/echo 'y') | /usr/bin/rsh -4 -l $cisco_user $nas_mng_ip clear line $PORT";
      $Log->log_print('LOG_DEBUG', "$user", "$command", { ACTION => 'CMD' });
      $exec = `$command`;
      return $exec;
    }

    $command = "/usr/bin/rsh -l $cisco_user $nas_mng_ip show users | grep -i \" $user \" ";

    #| awk '{print \$1}';";
    $Log->log_print('LOG_DEBUG', "$command");
    my $out = `$command`;

    if ($out eq '') {
      print 'Can\'t get VIRTUALINT. Check permissions';
      return 'Can\'t get VIRTUALINT. Check permissions';
    }

    my $VIRTUALINT;

    if ($out =~ /\s+(\d+)\s+(\S+)\s+(\d+)\s+(\S+)\s+(\S+)/) {
      $VIRTUALINT = $1;
      my $tty = $2;
      my $line = $3;
      my $cuser = $4;
      my $chost = $5;

      print "$VIRTUALINT, $tty, $line, $cuser, $chost";
    }

    $command = "echo $VIRTUALINT echo  | sed -e \"s/[[:alpha:]]*\\([[:digit:]]\\{1,\\}\\)/\\1/\"";
    $Log->log_print('LOG_DEBUG', "$command");
    $PORT = `$command`;
    $command = "/usr/bin/rsh -4 -n -l $cisco_user $nas_mng_ip clear interface Virtual-Access $PORT";
    $Log->log_print('LOG_DEBUG', $user, "$command", { ACTION => 'CMD' });
    $exec = `$command`;
  }
  else {
    #SNMP version
    my $SNMP_COM = $NAS->{NAS_MNG_PASSWORD} || '';
    my $INTNUM = snmpget("$SNMP_COM\@$nas_mng_ip", ".1.3.6.1.2.1.4.21.1.2.$attr->{FRAMED_IP_ADDRESS}");
    $Log->log_print('LOG_DEBUG', "$user",
      "SNMP: $SNMP_COM\@$nas_mng_ip .1.3.6.1.2.1.4.21.1.2.$attr->{FRAMED_IP_ADDRESS}", { ACTION => 'CMD' });
    $exec = snmpset("$SNMP_COM\@$NAS->{NAS_IP}", ".1.3.6.1.2.1.2.2.1.7.$INTNUM", 'integer', 2);
    $Log->log_print('LOG_DEBUG', "$user", "SNMP: $SNMP_COM\@$nas_mng_ip .1.3.6.1.2.1.2.2.1.7.$INTNUM integer 2",
      { ACTION => 'CMD' });
  }

  return $exec;
}

#***********************************************************
=head2 hangup_dslmax

  HANGUP dslmax
  hangup_dslmax($SERVER, $PORT)

=cut
#***********************************************************
sub hangup_dslmax {
  my ($NAS, $attr) = @_;

  my $PORT = $attr->{PORT};
  #cotrol
  my @commands = ();
  push @commands, "word:\t$NAS->{NAS_MNG_PASSWORD}";
  push @commands, ">\treset S$PORT";
  push @commands, ">exit";

  my $result = telnet_cmd("$NAS->{NAS_IP}", \@commands);

  print $result;

  return 0;
}

#***********************************************************
=head1 hangup_mpd5($NAS, $attr) - HANGUP MPD

=cut
#***********************************************************
sub hangup_mpd5 {
  my $self = shift;
  my ($NAS, $attr) = @_;

  my $PORT = $attr->{PORT};

  if (!$NAS->{NAS_MNG_IP_PORT}) {
    print "MPD Hangup failed. Can't find NAS IP and port. NAS: $NAS->{NAS_ID}\n";
    return "Error";
  }

  my ($hostname, $radius_port, $telnet_port) = ('127.0.0.1', '3799', '5005');

  ($hostname, $radius_port, $telnet_port) = split(/:/, $NAS->{NAS_MNG_IP_PORT}, 4);

  if (!$attr->{LOCAL_HANGUP}) {
    $NAS->{NAS_MNG_IP_PORT} = "$hostname:$radius_port";
    return $self->radius_request($NAS, $attr);
  }

  $hostname = '127.0.0.1';
  $telnet_port //= 5005;
  my $ctl_port = "L-$PORT";
  if ($attr->{ACCT_SESSION_ID}) {
    if ($attr->{ACCT_SESSION_ID} =~ /^\d+\-(.+)/) {
      $ctl_port = $1;
    }
  }

  $Log->log_print('LOG_DEBUG', $USER_NAME,
    " HANGUP: SESSION: $ctl_port NAS_MNG: $NAS->{NAS_MNG_IP_PORT} '$NAS->{NAS_MNG_PASSWORD}'", { ACTION => 'CMD' });

  my @commands = ("\t", "Username: \t$NAS->{NAS_MNG_USER}", "Password: \t$NAS->{NAS_MNG_PASSWORD}",
    "\\[\\] \tlink $ctl_port", "\] \tclose", "\] \texit");

  if ($attr->{IFACE}) {
    $commands[3] = "\\[\\] \tiface $attr->{IFACE}";
  }

  my $result = telnet_cmd("$hostname:$telnet_port", \@commands, { DEBUG => 1 });

  return $result;
}

#***********************************************************
=head2 hangup_radpppd() - radppp functions

  HANGUP radpppd
  hangup_radpppd($SERVER, $PORT)

=cut
#***********************************************************
sub hangup_radpppd {
  my (undef, $PORT) = @_;

  my $RUN_DIR = '/var/run';
  my $CAT = '/bin/cat';
  my $KILL = '/bin/kill';

  my $PID_FILE = "$RUN_DIR/PPP$PORT.pid";
  my $PPP_PID = `$CAT $PID_FILE`;
  my $res = `$KILL -1 $PPP_PID`;

  return $res;
}

#***********************************************************
# Get stats for pppd connection from firewall
#
# get_pppd_stats ($SERVER, $PORT, $IP)
#***********************************************************
# #@deprecated
# sub stats_pppd {
#   my ($NAS, $PORT) = @_;
#
#   my $firstnumber = 1000;
#   my $step = 10;
#   my $innum = $firstnumber + $PORT * $step;
#   my $outnum = $firstnumber + $PORT * $step + 5;
#
#   my %stats = ();
#
#   $stats{ $NAS->{NAS_IP} }{$PORT}{in} = 0;
#   $stats{ $NAS->{NAS_IP} }{$PORT}{out} = 0;
#
#   # 01000    369242     53878162 count ip from any to any in via 217.196.163.253
#   open(my $FW, '|-', "/usr/sbin/ipfw $innum $outnum") || die "Can't open '/usr/sbin/ipfw' $!\n";
#   while (<$FW>) {
#     my ($num, undef, $bytes, undef) = split(/ +/, $_, 4);
#     if ($innum == $num) {
#       $stats{$NAS->{NAS_IP}}{$PORT}{in} = $bytes;
#     }
#     elsif ($outnum == $num) {
#       $stats{$NAS->{NAS_IP}}{$PORT}{in} = $bytes;
#     }
#   }
#   close($FW);
#
#   return 1;
# }

#***********************************************************
=head2 hangup_pppd($NAS, $attr);

 HANGUP pppd
  hangup_pppd($SERVER, $PORT)
  add next string to  /etc/sudoers:

  apache   ALL = NOPASSWD: /usr/axbills/misc/pppd_kill
=cut
#***********************************************************
sub hangup_pppd {
  my ($NAS, $attr) = @_;
  my $IP = $attr->{FRAMED_IP_ADDRESS};
  my $result = '';

  if ($NAS->{NAS_MNG_IP_PORT} =~ /:/) {
    my ($ip, $mng_port) = split(/:/, $NAS->{NAS_MNG_IP_PORT}, 4);
    use IO::Socket;

    my $remote = IO::Socket::INET->new(
      Proto    => "tcp",
      PeerAddr => "$ip",
      PeerPort => $mng_port
    ) or die "cannot connect to pppd disconnect port at $ip:$mng_port $!\n";

    print $remote "$IP\n";
    $result = <$remote>;
    print "Hanguped: $IP\n" if ($debug > 1);
  }
  else {
    $result = system("/usr/bin/sudo /usr/axbills/misc/pppd_kill $IP");
  }

  return $result;
}


#***********************************************************
=head2 hangup_pppd_coa($NAS, $PORT, $attr) - hangup_hangup_pppd_coa

  Radius-Disconnect messages for radcoad
  rfc3576

=cut
#***********************************************************
sub hangup_pppd_coa {
  my ($NAS, $PORT, $attr) = @_;

  my ($ip, $mng_port) = split(/:/, $NAS->{NAS_MNG_IP_PORT}, 3);
  $Log->log_print('LOG_DEBUG', '', " HANGUP: NAS_MNG: $ip:$mng_port '$NAS->{NAS_MNG_PASSWORD}'", { ACTION => 'CMD' });

  my $type;
  my $result = 0;
  my $r = Radius->new(
    Host   => "$NAS->{NAS_MNG_IP_PORT}",
    Secret => "$NAS->{NAS_MNG_PASSWORD}"
  ) or return "Can't connect '$NAS->{NAS_MNG_IP_PORT}' $!";

  $CONF->{'dictionary'} = '/usr/axbills/lib/dictionary' if (!$CONF->{'dictionary'});

  $r->load_dictionary($CONF->{'dictionary'});

  $r->add_attributes({ Name => 'Framed-Protocol', Value => 'PPP' }, { Name => 'NAS-Port', Value => "$PORT" });
  $r->add_attributes({ Name => 'Framed-IP-Address', Value =>
    "$attr->{FRAMED_IP_ADDRESS}" }) if ($attr->{FRAMED_IP_ADDRESS});
  $r->send_packet(DISCONNECT_REQUEST) and $type = $r->recv_packet;

  if (!defined $type) {
    # No responce from POD server
    $result = 1;
    $Log->log_print('LOG_DEBUG', '', "No responce from POD server '$NAS->{NAS_MNG_IP_PORT}' ", { ACTION => '' });
  }

  my $nas_type = $attr->{NAS_TYPE};
  if ($nas_type eq 'pppd_coa' || $nas_type eq 'accel_ppp') {
    return 1;
  }

  return $result;
}

#***********************************************************
=head2 setspeed($NAS_HASH_REF, $nas_port, $user_name, $upspeed, $downspeed, $attr) - Set speed for port

  Arguments:
    $NAS_HASH_REF
    $PORT
    $USER
    $UPSPEED
    $DOWNSPEED
    $attr

  Results:

=cut
#***********************************************************
sub setspeed {
  my $self = shift;
  my ($Nas, $nas_port, $user_name, $upspeed, $downspeed, $attr) = @_;

  my $nas_type = $Nas->{NAS_TYPE};

  if ($nas_type eq 'pppd_coa' || $nas_type eq 'accel_ppp' || $nas_type eq 'accel_ipoe') {
    $attr->{USER}=$user_name || q{};
    my %RAD_PAIRS = (
      'Framed-Protocol' => 'PPP',
      'NAS-Port'        => $nas_port,
      'PPPD-Upstream-Speed-Limit'  => "$upspeed",
      'PPPD-Downstream-Speed-Limit'=> "$downspeed"
    );

    if ($attr->{FRAMED_IP_ADDRESS}) {
      $RAD_PAIRS{'Framed-IP-Address'} = $attr->{FRAMED_IP_ADDRESS};
    }
    return $self->radius_request($Nas, { %$attr, RAD_PAIRS => \%RAD_PAIRS, COA => 1 });
  }
  else {
    return -1;
  }
}

#***********************************************************
=head2  hascoa($NAS); - Check CoA support

=cut
#***********************************************************
sub hascoa {
  my ($NAS) = @_;

  my $nas_type = $NAS->{NAS_TYPE};

  if ($nas_type eq 'pppd_coa') {
    return 1;
  }
  elsif ($CONF->{coa_send} && $nas_type =~ /$CONF->{coa_send}/) {
    return 1;
  }

  return 0;
}

#***************************************************************
=head2 hangup_unifi($NAS, $PORT, $USER, $attr) - Hangup unifi

=cut
#***************************************************************
sub hangup_unifi {
  my ($NAS, $attr) = @_;

  my $USER = $attr->{USER};
  if (!$NAS->{NAS_MNG_IP_PORT}) {
    print "Radius Hangup failed. Can't find NAS IP and port. NAS: $NAS->{NAS_ID} USER: $USER\n";
    return 'ERR:';
  }

  require Unifi::Unifi;
  Unifi->import();

  my $Unifi = Unifi->new($CONF);
  $Unifi->{unifi_url} = 'https://' . $NAS->{NAS_MNG_IP_PORT};
  $Unifi->{login} = $NAS->{NAS_MNG_USER};
  $Unifi->{password} = $NAS->{NAS_MNG_PASSWORD};

  my $result = $Unifi->deauthorize({ MAC => $attr->{CID} || $attr->{CALLING_STATION_ID} });

  return $result;
}

#***************************************************************
=head2 rsh_cmd($command, $attr) - rsh cmd

  Arguments:
    $command
    $attr
       NAS_MNG_USER
       NAS_MNG_IP_PORT
       RSH_CMD =>

  Results:
    command result

=cut
#***************************************************************
sub rsh_cmd {
  my ($cmd, $attr) = @_;

  if (!$cmd) {
    return 0;
  }

  my $mng_port;
  my $mng_user = $attr->{NAS_MNG_USER} || '';
  my $ip;
  ($ip, undef, $mng_port) = split(/:/, $attr->{NAS_MNG_IP_PORT}, 4);

  $cmd =~ s/\\\"/\"/g;

  my $rsh_cmd = ($attr->{RSH_CMD}) ? $attr->{RSH_CMD} : '/usr/bin/rsh -o StrictHostKeyChecking=no';

  my $command = "$rsh_cmd -l $mng_user $ip \"$cmd\"";
  if ($Log) {
    $Log->log_print('LOG_DEBUG', '', "$command", { ACTION => 'CMD' });
  }

  my $result = cmd($command, { RESULT_ARRAY => 1, %{$attr} });

  return $result || [];
}

1
