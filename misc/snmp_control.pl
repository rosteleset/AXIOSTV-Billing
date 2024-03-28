#!/usr/bin/perl

=head1 NAME

  Switch mac and speed assign

  snmp_control.pl (ONLINE_ENABLE|ONLINE_DISABLE|HANGUP) %LOGIN %FILTER_ID %PORT

=cut

use strict;
use warnings FATAL => 'all';
use FindBin '$Bin';

my $debug   = 0;
our $VERSION = 0.70;
BEGIN {
  our %conf;
  require $Bin.'/../libexec/config.pl';
  unshift(@INC,
    $Bin.'/../',
    $Bin.'/../lib/',
    $Bin.'/../AXbills/modules/',
    $Bin."/../AXbills/$conf{dbtype}");
}

use AXbills::SQL;
use AXbills::Base;
use Admins;
use Dv_Sessions;
use Dv;
use Dhcphosts;
use Nas;
use Socket;
use Snmputils;
use SNMP_Session;
use SNMP_util;
use BER;
use Billing;

require AXbills::Misc;

my $argv = parse_arguments(\@ARGV);

if ($argv->{help} || $#ARGV == -1) {
  print << "[END]";
Version: $VERSION
snmp_control.pl (ONLINE_ENABLE|ONLINE_DISABLE|HANGUP) %LOGIN %FILTER_ID %PORT
  SHOW_VLANS=[NAS_ID] - Show Vlan on switch
  FILTER_ID=...       - Filter syntax VLAN:PORT_SPEED
     PORT_STATUS      - Change port status
     PORT_SPEED:[speed] - Change port speed
     [main_vlan]:[guest_vlan]:[speed]
     [main_vlan]:[speed]
  PORT=...            - Switch port
  TP_SPEED=1          - get speed From TP
  IN_ONLY=1           - Input shape speed only
  OUT_ONLY=1          - Output shape speed only
  MAIN_VLAN=...       - main Vlan
  GUEST_VLAN=...      - guest Vlan
  RESERV_PORTS=...,.. - reserv ports (Default: 25,26,27,28)
  RESET=1             - reset ports
  DEBUG=1..6          - Debug mode
  DHCP_NAS_INFO       - get Nas info from dhcphosts
  IP=...              - Client IP
  
  DEVICE_INFO=txt_file- Get inforamtion abount devices in file
  SNMP_COMMUNITY      - SNMP community for DEVICE_INFO (default: public)
  MAC=...             - Search only first  MAC

  help                - This help
  
[END]
  exit;
}

our %conf;
my $VLAN        = $argv->{MAIN_VLAN}  || 3256;
my $GUEST_VLAN  = $argv->{GUEST_VLAN} || 3257;
my $db         = AXbills::SQL->connect($conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd}, { CHARSET => ($conf{dbcharset}) ? $conf{dbcharset} : undef });
my $admin       = Admins->new($db, \%conf);
$admin->info($conf{SYSTEM_ADMIN_ID}, { IP => '127.0.0.1' });
my $Nas         = Nas->new($db, \%conf);
my $Dv_sessions = Dv_Sessions->new($db, $admin, \%conf);
my $Dv          = Dv->new($db, $admin, \%conf);
my $Dhcphosts   = Dhcphosts->new($db, $admin, \%conf);
#my $Snmputils   = Snmputils->new($db, $admin, \%conf);
my $Billing     = Billing->new($db, \%conf);

my $NAS_ID          = $ENV{NAS_ID}          || 1;
my $NAS_MNG_IP_PORT = $ENV{NAS_MNG_IP_PORT} || $argv->{NAS_MNG_IP_PORT} || '';
my $NAS_MNG_PASSWD  = $ENV{NAS_MNG_PASSWD}  || $argv->{NAS_MNG_PASSWD} || '';
my $NAS_TYPE        = $ENV{NAS_TYPE}        || '';
my $NAS_MNG_USER    = $ENV{NAS_MNG_USER}    || $argv->{NAS_MNG_USER} || '';
my @RESERV_PORTS    = (25, 26, 27, 28);
my $sw_info;
my $ports;

`echo "NAS_ID: $NAS_ID  IP: $NAS_MNG_IP_PORT PASSWD: $NAS_MNG_PASSWD TYPE: $NAS_TYPE USER: $NAS_MNG_USER " >> /tmp/test_snmp `;


if ($argv->{DEBUG}) {
  $debug = $argv->{DEBUG};
  if ($debug > 6) {
    $Dv_sessions->{debug}=1;
    $Dhcphosts->{debug}=1;
  }
}

if($argv->{DEVICE_INFO}) {
	devices_info($argv->{DEVICE_INFO});
	exit;
}
elsif ($argv->{RESERV_PORTS}) {
  @RESERV_PORTS = split(/,/, $argv->{RESERV_PORTS});
}

if ($argv->{NAS_ID}) {
  $NAS_ID = $argv->{NAS_ID};
}

my $ACTION       = $ARGV[0];
my $LOGIN        = $ARGV[1];
my $FILTER_ID    = $ARGV[2];
my $PORT         = $ARGV[3];
my $get_tp_speed = 0;
#my %RESULT       = ();

$FILTER_ID =~ s/Session-Timeout=\d+,//g;

#Get NAS info from dhcphosts
if ($argv->{DHCP_NAS_INFO}) {
  $Dhcphosts->host_info(0, { IP => $argv->{IP} });
  $PORT = $Dhcphosts->{PORTS};
  if ($Dhcphosts->{TOTAL} < 1) {
    print "IP '$argv->{IP}' not registred in Dhcphosts\n";
    exit;
  }
  $NAS_ID = $Dhcphosts->{NAS_ID};
}

if ($NAS_ID) {
  $Nas->info({ NAS_ID => $NAS_ID });
  $NAS_MNG_IP_PORT = $Nas->{NAS_MNG_IP_PORT};
  $NAS_MNG_PASSWD  = $Nas->{NAS_MNG_PASSWORD};
  $NAS_TYPE        = $Nas->{NAS_TYPE};
  $NAS_MNG_USER    = $Nas->{NAS_MNG_USER} || $Nas->{NAS_MNG_PASSWORD};
}

if ($argv->{TP_SPEED}) {
  $get_tp_speed = 1;
  $FILTER_ID = "PORT_SPEED:0" if ($FILTER_ID =~ /PORT_SPEED/);
}

# 1 auto
# 2 half 10
# 3 full 10
# 4 half 100
# 5 full 100
# 6 half 1000
# 7 full 1000
my %speeds = (
  auto => 1,
  10   => 3,
  100  => 5,
  1000 => 7,
);

my $SPEED = 3;

#For Edgecore
# For Dlink              1.3.6.1.2.1.17.7.1.4.2.1.5
#                         1.3.6.1.2.1.17.7.1.4.3.1.4
my $untaged_ports_mib = '1.3.6.1.2.1.17.7.1.4.2.1.5';
my $taged_ports_mib   = '1.3.6.1.2.1.17.7.1.4.3.1.2';
my $all_ports_mib     = '1.3.6.1.2.1.17.7.1.4.2.1.4';
my $ports_mib         = $untaged_ports_mib;
my $type              = '';

if ($NAS_TYPE eq 'ipcad') {
  exit;
}

my ($nas_ip)=split(/:/, $NAS_MNG_IP_PORT);

my $SNMP_COMMUNITY = "$NAS_MNG_USER\@$nas_ip";

if ($argv->{RESET}) {
  dlink_vlan_add();
}
elsif ($argv->{SHOW_VLANS}) {
  show_vlans();
}

#Set port speed
elsif ($FILTER_ID =~ /PORT_SPEED:(\S+)/) {
  $SPEED = $1;
  if ($type = nas_version()) {
    set_speed();
  }
}
#Port Enable/Disable
elsif ($FILTER_ID =~ /PORT_STATUS/) {
  if ($type = nas_version()) {
    set_port_status();
  }
}
#main_vlan:guest_vlan:speed
elsif ($FILTER_ID =~ /(\S+):(\S+):(\S+)/) {
  $VLAN       = $1;
  $GUEST_VLAN = $2;
  $SPEED      = $3;

  if ($type = nas_version()) {
    set_speed();
    if ($GUEST_VLAN || $VLAN) { set_vlan(); }
  }
}
#Vlan:SPEED
elsif ($FILTER_ID =~ /(\S+):(\S+)/) {
  $VLAN = $1;    #$VLAN;

  $SPEED = $speeds{ lc($2) };
  dlink_vlan_add();
  dlink_port_speed();
}

#***********************************************************
# enable/disable port
#
#***********************************************************
sub set_port_status {
  #my ($attr) = @_;

  if (!$PORT) {
    $Dv->info(0, { LOGIN => $LOGIN });
    $PORT = $Dv->{PORT};

    if (!$PORT) {
      print "Select port\n";
      exit;
    }
  }

  my $STATUS = 1;
  if ($ACTION eq 'ONLINE_ENABLE') {
    $STATUS = 1;
  }
  elsif ($ACTION eq 'HANGUP' || $ACTION eq 'ONLINE_DISABLE') {
    $STATUS = 2;
  }

  #Edge-core mibs
  my $oid = '.1.3.6.1.2.1.2.2.1.7.';

  snmp_set({ SNMP_COMMUNITY => $SNMP_COMMUNITY, 
             OID            => [ "$oid".$PORT, "integer", $STATUS ]
            });
}

#***********************************************************
#
#***********************************************************
sub show_vlans {
  #my ($attr) = @_;

  $Nas->info({ NAS_ID => $argv->{SHOW_VLANS} });
  #my $RESULT;
  if ($debug < 5) {
    $SNMP_COMMUNITY = "$Nas->{NAS_MNG_USER}\@$Nas->{NAS_MNG_IP_PORT}";
    if ($debug > 1) {
      print "NAS_ID: $Nas->{NAS_ID} SNMP: $Nas->{NAS_MNG_USER}\@$Nas->{NAS_MNG_IP_PORT}\n";
      if ($debug > 2) {
        print "MIB: $ports_mib\n";
      }
    }

    my $version  = snmp_get({ SNMP_COMMUNITY => $SNMP_COMMUNITY, 
                              OID            => ".1.3.6.1.2.1.1.1.0"
                             });

    my $firmvare = snmp_get({ SNMP_COMMUNITY => $SNMP_COMMUNITY, 
                              OID            => ".1.3.6.1.2.1.16.19.2.0"
                            });

    print "Version: $version Firmvare: $firmvare\n";

    my %mibs = (
      ALL_PORTS     => $all_ports_mib,
      UNTAGED_PORTS => $untaged_ports_mib
    );

    while (my ($name, $oid) = each %mibs) {
      my $result = snmp_get({ SNMP_COMMUNITY => $SNMP_COMMUNITY, 
                              OID            => "$oid",
                              WALK           => 1  
                            });

      print "Name: $name\n";
      foreach my $line (@$result) {
        my ($vlan, $ports_bin) = split(/:/, $line, 2);
        my $p = unpack("B64", $ports_bin);
        my $ports = '';
        for (my $i = 0 ; $i < length($p) ; $i++) {
          my $port_val = substr($p, $i, 1);
          if ($port_val == 1) {
            $ports .= ($i + 1) . ", ";
          }
        }

        print "$vlan: \t";
        print "$ports\n";
        if ($debug > 1) { print "$p\n"; }
      }
    }
  }

  return 1;
}

#***********************************************************
#
#***********************************************************
sub get_active_ports {
  #my ($attr) = @_;

  my %LIST_PARAMS = ();
  $LIST_PARAMS{NAS_ID} = $NAS_ID if ($NAS_ID);

  $Dv_sessions->online({
    NAS_PORT_ID => '_SHOW',
    NAS_IP      => '_SHOW',
    CLIENT_IP   => '_SHOW',
    UID         => '_SHOW'
  });

  my $online_list = $Dv_sessions->{nas_sorted};
  my %ports       = ();

  # Billing ports, get active
  foreach my $online (@{ $online_list->{$NAS_ID} }) {
    $ports{ $online->{nas_port_id} } = 1 if ($online->{nas_port_id} && $online->{nas_port_id} > 0);
  }

  #Get all
  my $dhcphosts_list = $Dhcphosts->hosts_list(
    {
      NAS_ID                 => $NAS_ID,
      PORTS                  => '*',
      DHCPHOSTS_DEPOSITCHECK => 1,
      PAGE_ROWS              => 10000,
      COLS_NAME              => 1
    }
  );

  foreach my $host (@{$dhcphosts_list}) {
    my $port = $host->{ports};
    if ($LOGIN eq $host->{login}) {
      $ports{$port} = 0;
      $PORT = $port;
    }
    #elsif ($line->[18] > 0 && 
    elsif($host->{disable} == 0) {
      $ports{$port} = 1;
    }
    else {
      $ports{$port} = 0;
    }
    print "$host->{login} Port: $port STATUS: $ports{$port}\n" if ($debug > 1);
  }

  if ($ACTION eq 'ONLINE_ENABLE') {
    $ports{$PORT} = 1;
  }
  elsif ($ACTION eq 'HANGUP' || $ACTION eq 'ONLINE_DISABLE') {
    $ports{$PORT} = 0;
  }

  return \%ports;
}

#***********************************************************
#
#***********************************************************
sub dlink_vlan_add {

  my $ports = get_active_ports();

  my $RESULT;
  if ($debug < 5) {
    $RESULT = snmputils_dlink_pb_version({ SNMP_COMMUNITY => "$SNMP_COMMUNITY" });
  }
  print "version: " . $RESULT->{version} . "/" . $RESULT->{PORTS} . "\n" if ($debug > 0);

  my $all_ports_str = '';

  if ($argv->{RESET}) {
    $Nas->info({ NAS_ID => $argv->{SHOW_VLANS} || $argv->{NAS_ID} });

    if ($debug < 5) {
      $SNMP_COMMUNITY = "$Nas->{NAS_MNG_USER}\@$Nas->{NAS_MNG_IP_PORT}";

      if ($debug > 1) {
        print "NAS_ID: $Nas->{NAS_ID} SNMP: $Nas->{NAS_MNG_USER}\@$Nas->{NAS_MNG_IP_PORT}\n";
        if ($debug > 2) {
          print "MIB: $ports_mib\n";
        }
      }
    }

    $all_ports_str = "000000000000000000000000101000000000000000000000";
    my $bin_ports = pack("B64", join("", split(//, $all_ports_str)));
    snmpset($SNMP_COMMUNITY, "$taged_ports_mib.$GUEST_VLAN", "octetstring", pack("B64", join("", split(//, "000000000000000000000000000000000000000000000000"))));
    snmpset($SNMP_COMMUNITY, "$taged_ports_mib.$VLAN", "octetstring", $bin_ports);
    print "Reseted";
    return 0;
  }

  my %PORT_HASH = ();

  $PORT_HASH{MAIN}{all_ports_str}     = unpack("B64", $RESULT->{ALL_PORTS}{$VLAN});
  $PORT_HASH{MAIN}{untaged_ports_str} = unpack("B64", $RESULT->{UNTAGED_PORTS}{$VLAN});
  $RESULT->{TAGED_PORTS}{$VLAN}       = $RESULT->{ALL_PORTS}{$VLAN} ^ $RESULT->{UNTAGED_PORTS}{$VLAN};
  $PORT_HASH{MAIN}{taged_ports}       = unpack("B64", $RESULT->{ALL_PORTS}{$VLAN} ^ $RESULT->{UNTAGED_PORTS}{$VLAN});

  $PORT_HASH{GUEST}{all_ports_str}     = unpack("B64", $RESULT->{ALL_PORTS}{$GUEST_VLAN});
  $PORT_HASH{GUEST}{untaged_ports_str} = unpack("B64", $RESULT->{UNTAGED_PORTS}{$GUEST_VLAN});
  $RESULT->{TAGED_PORTS}{$GUEST_VLAN}  = $RESULT->{ALL_PORTS}{$GUEST_VLAN} ^ $RESULT->{UNTAGED_PORTS}{$GUEST_VLAN};
  $PORT_HASH{GUEST}{taged_ports}       = unpack("B64", $RESULT->{TAGED_PORTS}{$GUEST_VLAN});

  if ($debug > 2) {
    print "
Current MAIN: $VLAN
> A: $PORT_HASH{MAIN}{all_ports_str}
> U: $PORT_HASH{MAIN}{untaged_ports_str} 
> T: $PORT_HASH{MAIN}{taged_ports}
GUEST: $GUEST_VLAN
> A: $PORT_HASH{GUEST}{all_ports_str}
> U: $PORT_HASH{GUEST}{untaged_ports_str}
> T: $PORT_HASH{GUEST}{taged_ports}
";
  }

  #Switch ports
  my @port_array  = split(//, $PORT_HASH{MAIN}{untaged_ports_str});
  my @guest_array = split(//, $PORT_HASH{GUEST}{untaged_ports_str});

  # reserved hash
  my %reserved_ports = ();
  foreach my $id (@RESERV_PORTS) {
    $reserved_ports{$id} = 1;
  }

  for (my $i = 0 ; $i < length($PORT_HASH{MAIN}{all_ports_str}) ; $i++) {
    if ($reserved_ports{ $i + 1 }) {
      next;
    }

    if (defined($ports->{ $i + 1 })) {

      #Active
      if ($ports->{ $i + 1 } > 0) {
        $port_array[$i]  = 1;
        $guest_array[$i] = 0;
        print "Active: " . ($i + 1) . "\n" if ($debug > 1);
      }

      #Blocked
      else {
        $port_array[$i]  = 0;
        $guest_array[$i] = 1;
        print "Guest: " . ($i + 1) . "\n" if ($debug > 1);
      }
    }
    else {
      $port_array[$i]  = 0;
      $guest_array[$i] = 0;
    }
  }

  if ($debug > 0) {
    my $p = join(',', @port_array);
    `echo " >> $PORT $ports->{$PORT} '$ACTION'//$p" >> /tmp/vlan_test `;
  }

  my $bin_ports       = pack("B64", join("", @port_array));
  my $bin_ports_guest = pack("B64", join("", @guest_array));

  if ($debug > 2) {
    print "
New MAIN: $VLAN
> A: $PORT_HASH{MAIN}{all_ports_str}
> U: " . unpack("B64", $bin_ports) . "
> T: $PORT_HASH{MAIN}{taged_ports}
GUEST: $GUEST_VLAN
> A: $PORT_HASH{GUEST}{all_ports_str}
> U: " . unpack("B64", $bin_ports_guest) . "
> T: $PORT_HASH{GUEST}{taged_ports}
";
  }

  if ($debug < 5) {

    #Reset ports
    # Taged
    snmpset($SNMP_COMMUNITY, "1.3.6.1.2.1.17.7.1.4.3.1.2.$GUEST_VLAN", "octetstring", pack("B64", "000000000000000000000000000000000000000000000000"));
    snmpset($SNMP_COMMUNITY, "1.3.6.1.2.1.17.7.1.4.3.1.2.$VLAN",       "octetstring", pack("B64", "000000000000000000000000000000000000000000000000"));

    #Untaged
    snmpset($SNMP_COMMUNITY, "1.3.6.1.2.1.17.7.1.4.3.1.4.$GUEST_VLAN", "octetstring", pack("B64", "000000000000000000000000000000000000000000000000"));
    snmpset($SNMP_COMMUNITY, "1.3.6.1.2.1.17.7.1.4.3.1.4.$VLAN",       "octetstring", pack("B64", "000000000000000000000000000000000000000000000000"));

    if ($SNMP_Session::errmsg) {
      print "Reset ports error
  	$SNMP_Session::suppress_warnings / $SNMP_Session::errmsg";
      exit;
    }

    #Main Section
    #Add taged port
    snmpset($SNMP_COMMUNITY, "1.3.6.1.2.1.17.7.1.4.3.1.2.$VLAN", "octetstring", $RESULT->{TAGED_PORTS}{$VLAN});

    #Add untaged ports
    snmpset($SNMP_COMMUNITY, "1.3.6.1.2.1.17.7.1.4.3.1.4.$VLAN", "string", $bin_ports);

    if ($SNMP_Session::errmsg) {
      print "Main VLAN Section \n $SNMP_Session::suppress_warnings\n" . "
  	$SNMP_COMMUNITY 1.3.6.1.2.1.17.7.1.4.3.1.2.$VLAN -> " . unpack("B64", $RESULT->{TAGED_PORTS}{$VLAN}) . "/" . unpack("H*", $RESULT->{TAGED_PORTS}{$VLAN}) . "\n" . "$SNMP_COMMUNITY 1.3.6.1.2.1.17.7.1.4.3.1.4.$VLAN -> " . unpack("B*", $bin_ports) . "/" . unpack("H*", $bin_ports) . "\n";
      exit;
    }

    #eval {
    #Guest Section
    #Add taged port
    snmpset($SNMP_COMMUNITY, "1.3.6.1.2.1.17.7.1.4.3.1.2.$GUEST_VLAN", "octetstring", $RESULT->{TAGED_PORTS}{$GUEST_VLAN});

    #Add untaged ports
    snmpset($SNMP_COMMUNITY, "1.3.6.1.2.1.17.7.1.4.3.1.4.$GUEST_VLAN", "octetstring", $bin_ports_guest);

    #};

    if ($SNMP_Session::errmsg) {
      print "Guest VLAN Section\n	$SNMP_Session::suppress_warnings \n" . "1.3.6.1.2.1.17.7.1.4.3.1.4.$GUEST_VLAN -> " . unpack("B64", $bin_ports_guest) . "\n";
      exit;
    }

    #Change port state
    snmpset($SNMP_COMMUNITY, "1.3.6.1.4.1.171.11.63.6.2.2.2.1.3." . $PORT . ".100", "integer", 2);
    snmpset($SNMP_COMMUNITY, "1.3.6.1.4.1.171.11.63.6.2.2.2.1.3." . $PORT . ".100", "integer", 3);

    if ($SNMP_Session::errmsg) {
      print "Port change state
  	$SNMP_Session::suppress_warnings / $SNMP_Session::errmsg";
    }

    if ($debug > 2) {
      print "$SNMP_COMMUNITY -> $ports_mib.$VLAN s $bin_ports\n";
    }
  }

  return 1;
}

#**********************************************************
# http://www.mounblan.com/faq.php?prodid=0&deviceid=0&id=100
#**********************************************************
sub edgecore_vlan_get {
  my %RESULT = ();

  #TAGED
  $RESULT{TAGED_PORTS}{$VLAN}         = snmpget($SNMP_COMMUNITY, "1.3.6.1.2.1.17.7.1.4.3.1.2.$VLAN");
  $RESULT{TAGED_PORTS}{$GUEST_VLAN}   = snmpget($SNMP_COMMUNITY, "1.3.6.1.2.1.17.7.1.4.3.1.2.$GUEST_VLAN");

  #UNtaged
  $RESULT{UNTAGED_PORTS}{$VLAN}       = snmpget($SNMP_COMMUNITY, "1.3.6.1.2.1.17.7.1.4.3.1.4.$VLAN");
  $RESULT{UNTAGED_PORTS}{$GUEST_VLAN} = snmpget($SNMP_COMMUNITY, "1.3.6.1.2.1.17.7.1.4.3.1.4.$GUEST_VLAN");

  return \%RESULT;
}

#**********************************************************
# http://www.mounblan.com/faq.php?prodid=0&deviceid=0&id=100
#**********************************************************
sub edgecore_vlan {
  my ($attr) = @_;

  #my $vlan      = $attr->{VLAN};
  #my $ports_bin = $attr->{PORTS_BIN};

  my $RESULT;
  if ($debug < 7) {
    $RESULT = edgecore_vlan_get({ SNMP_COMMUNITY => "$SNMP_COMMUNITY" });
  }

  my %PORT_HASH = ();

  my $zero_fill = pack("B64", '0000000000000000000000000000000000000000000000000000000000000000');

  $PORT_HASH{MAIN}{untaged_ports_str}  = unpack("B64", $RESULT->{UNTAGED_PORTS}{$VLAN} || $zero_fill);
  $PORT_HASH{MAIN}{taged_ports}        = unpack("B64", ($RESULT->{ALL_PORTS}{$VLAN} || $zero_fill) ^ ($RESULT->{UNTAGED_PORTS}{$VLAN}|| $zero_fill));
  $PORT_HASH{MAIN}{all_ports_str}      = $PORT_HASH{MAIN}{taged_ports};

  $PORT_HASH{GUEST}{untaged_ports_str} = unpack("B64", $RESULT->{UNTAGED_PORTS}{$GUEST_VLAN} || $zero_fill);
  $PORT_HASH{GUEST}{taged_ports}       = unpack("B64", $RESULT->{TAGED_PORTS}{$GUEST_VLAN});
  $PORT_HASH{GUEST}{all_ports_str}     = $PORT_HASH{GUEST}{taged_ports};

  if ($debug > 2) {
    print "Switch ports
MAIN: $VLAN
> A: $PORT_HASH{MAIN}{all_ports_str}
> U: $PORT_HASH{MAIN}{untaged_ports_str} 
> T: $PORT_HASH{MAIN}{taged_ports}
GUEST: $GUEST_VLAN
> A: $PORT_HASH{GUEST}{all_ports_str}
> U: $PORT_HASH{GUEST}{untaged_ports_str}
> T: $PORT_HASH{GUEST}{taged_ports}
";
  }

  #Switch ports
  my @port_array  = split(//, $PORT_HASH{MAIN}{untaged_ports_str});
  my @guest_array = split(//, $PORT_HASH{GUEST}{untaged_ports_str});

  # reserved hash
  my %reserved_ports = ();
  foreach my $id (@RESERV_PORTS) {
    $reserved_ports{$id} = 1;
  }

  for (my $i = 0 ; $i < length($PORT_HASH{MAIN}{all_ports_str}) ; $i++) {
    if ($reserved_ports{ $i + 1 }) {
      next;
    }

    if (defined($ports->{ $i + 1 })) {

      #Active
      if ($ports->{ $i + 1 } > 0) {
        $port_array[$i]  = 1;
        $guest_array[$i] = 0;
        print "Active: " . ($i + 1) . "\n" if ($debug > 1);
      }

      #Blocked
      else {
        $port_array[$i]  = 0;
        $guest_array[$i] = 1;
        print "Guest: " . ($i + 1) . "\n" if ($debug > 1);
      }
    }
    else {
      $port_array[$i]  = 0;
      $guest_array[$i] = 0;
    }
  }

  if ($debug > 0) {
    my $p = join(',', @port_array);
    `echo " >> $PORT $ports->{$PORT} '$ACTION'//$p" >> /tmp/vlan_test `;
  }

  my $bin_ports       = pack("B64", join("", @port_array));
  my $bin_ports_guest = pack("B64", join("", @guest_array));

  if ($debug > 2) {
    print "Add ports
MAIN: $VLAN
> A: $PORT_HASH{MAIN}{all_ports_str}
> U: " . unpack("B64", $bin_ports) . "
> T: $PORT_HASH{MAIN}{taged_ports}
GUEST: $GUEST_VLAN
> A: $PORT_HASH{GUEST}{all_ports_str}
> U: " . unpack("B64", $bin_ports_guest) . "
> T: $PORT_HASH{GUEST}{taged_ports}
";
  }

  if ($debug < 5) {
    #Reset ports
    #Taged
    snmpset($SNMP_COMMUNITY, "1.3.6.1.2.1.17.7.1.4.3.1.2.$GUEST_VLAN", "octetstring", pack("B64", $zero_fill));
    snmpset($SNMP_COMMUNITY, "1.3.6.1.2.1.17.7.1.4.3.1.2.$VLAN",       "octetstring", pack("B32", "00000000000000000000000000000000"));
    #untahed
    snmpset($SNMP_COMMUNITY, "1.3.6.1.2.1.17.7.1.4.3.1.4.$GUEST_VLAN", "octetstring", pack("B32", "00000000000000000000000000000000"));
    snmpset($SNMP_COMMUNITY, "1.3.6.1.2.1.17.7.1.4.3.1.4.$VLAN",       "octetstring", pack("B32", "00000000000000000000000000000000"));

exit;
    eval {
      #Guest Section
      #Add taged port
      snmpset($SNMP_COMMUNITY, "1.3.6.1.2.1.17.7.1.4.3.1.2.$GUEST_VLAN", "octetstring", $RESULT->{TAGED_PORTS}{$GUEST_VLAN});

      #Add untaged ports
      snmpset($SNMP_COMMUNITY, "1.3.6.1.2.1.17.7.1.4.3.1.4.$GUEST_VLAN", "octetstring", $bin_ports_guest);
    };

    eval {
      #Main Section
      #Add taged port
      snmpset($SNMP_COMMUNITY, "1.3.6.1.2.1.17.7.1.4.3.1.2.$VLAN", "octetstring", $RESULT->{TAGED_PORTS}{$VLAN});

      #Add untaged ports
      snmpset($SNMP_COMMUNITY, "1.3.6.1.2.1.17.7.1.4.3.1.4.$VLAN", "octetstring", $bin_ports);
    };

    #Change port state
    #snmpset($SNMP_COMMUNITY, "1.3.6.1.4.1.171.11.63.6.2.2.2.1.3.". $PORT .".100", "integer", 2);
    #snmpset($SNMP_COMMUNITY, "1.3.6.1.4.1.171.11.63.6.2.2.2.1.3.". $PORT .".100", "integer", 3);

    if ($debug > 2) {
      print "$SNMP_COMMUNITY -> $ports_mib.$VLAN s $bin_ports\n";
    }
  }

  snmpset($SNMP_COMMUNITY, "1.3.6.1.2.1.17.7.1.4.3.1.4." . $VLAN, "octetstring", $attr->{PORTS_BIN});

  #snmpset -c private -v 2c 192.168.1.137 1.3.6.1.2.1.17.7.1.4.3.1.4.30 x "f0 00 00 00"
}

#**********************************************************
#
#**********************************************************
sub snmputils_dlink_pb_version {
  my ($attr) = @_;

  $SNMP_COMMUNITY = $attr->{SNMP_COMMUNITY} || '';
  my %RESULT = ();

  $RESULT{version}        = '';
  $RESULT{SNMP_COMMUNITY} = $SNMP_COMMUNITY;
  $RESULT{oid_prefix}     = '.1.3.6.1.4.1.171.11.64.1.2.7.';

  if ($RESULT{version} = snmpget($SNMP_COMMUNITY, ".1.3.6.1.2.1.1.1.0")) {
    if ($VLAN !~ /^(\d+)$/) {
      print "Wrong vlan '$VLAN'\n";
      return \%RESULT;
    }

    if ($VLAN) {

      #Full Vlan info
      my %mibs = (
        ALL_PORTS     => $all_ports_mib,
        UNTAGED_PORTS => $untaged_ports_mib
      );
      while (my ($name, $oid) = each %mibs) {
        my @result = snmpwalk($SNMP_COMMUNITY, "$oid");

        foreach my $line (@result) {
          my ($vlan, $ports_bin) = split(/:/, $line, 2);
          $vlan =~ /(\d+)$/;
          my $vlan_id = $1;

          $RESULT{$name}{$vlan_id} = $ports_bin;
          my $p = unpack("B64", $ports_bin);
          print "$name: '$vlan_id' $p\n" if ($debug > 3);
        }
      }
    }
  }
  else {
    print "$SNMP_Session::suppress_warnings / $SNMP_Session::errmsg";
    return 0;
  }

  return \%RESULT;
}

#**********************************************************
#
#**********************************************************
sub dlink_port_speed {
  my ($attr) = @_;

  my $sw_info = $attr->{SWITCH_INFO} || snmputils_dlink_pb_version({ SNMP_COMMUNITY => $SNMP_COMMUNITY });

  if (!$PORT) {
    print "Select port\n";
    exit;
  }

  my %RESULT = ();
  my($in_oid, $out_oid);

  if ($FILTER_ID !~ /PORT_SPEED:(\S+)/) {
    if ($sw_info->{version} =~ /DES-3028/) {
      $RESULT{oid_prefix} = '1.3.6.1.4.1.171.11.63.6.2.2.2.1.4';
    }
    else {
      $RESULT{oid_prefix} = '1.3.6.1.4.1.171.11.63.8.2.2.2.1.4';
    }

    print "$RESULT{oid_prefix}." . $PORT . ".100 -> integer $SPEED\n" if ($debug > 2);
    snmpset($SNMP_COMMUNITY, "$RESULT{oid_prefix}." . $PORT . ".100", "integer", "$SPEED");
    return 0;
  }
  elsif ($sw_info->{version} =~ /DES-3028/) {
    # port speed 10 / 100 /1000
    #$RESULT{oid_prefix} = '1.3.6.1.4.1.171.11.63.6.2.2.2.1.4';
    #dlink 3028 (�������� ������ 1����/�)
    #snmpset -c snmppass -v2c 10.133.251.243 1.3.6.1.4.1.171.11.63.6.2.3.1.1.2.24 i 1024
    #2 - ����
    #3 - �����
    #24 - ����
    #1024 - �������� 1024 ����/�
    #1024000 - �������� no_limit
    #
    $in_oid  = '1.3.6.1.4.1.171.11.63.6.2.3.1.1.2.';
    $out_oid = '1.3.6.1.4.1.171.11.63.6.2.3.1.1.3.';
  }
  elsif ($sw_info->{version} =~ /DES-3526/) {
    #dlink 3526 (�������� ������ 1����/�)
    #snmpset -c snmppass -v2c 10.133.200.102 1.3.6.1.4.1.171.11.64.1.2.6.1.1.2.1 i 2
    #snmpset -c snmppass -v2c 10.133.200.102 1.3.6.1.4.1.171.11.64.1.2.6.1.1.3.1 i 2
    #2 - ����
    #3 - �����
    #1 - port
    #2 - �������� 2 ����/�
    #0 - �������� no_limit

    if ($SPEED > 0 && $SPEED <= 1024) {
      $SPEED = 1;
    }
    elsif ($SPEED > 1024) {
      $SPEED = int($SPEED / 1024);
    }
    else {
      $SPEED = 0;
    }

    $in_oid  = '1.3.6.1.4.1.171.11.64.1.2.6.1.1.2.';
    $out_oid = '1.3.6.1.4.1.171.11.64.1.2.6.1.1.3.';
  }
  elsif ($sw_info->{version} =~ /DES-1210-26/) {
    $in_oid  = '1.3.6.1.4.1.171.10.75.16.1.13.1.2.1.2.';
    $out_oid = '.1.3.6.1.4.1.171.10.75.16.1.13.1.2.1.3.';
  }
  elsif ($sw_info->{version} =~ /DES-1228/) {
    $in_oid  = '1.3.6.1.4.1.171.11.116.2.2.3.1.1.2.';
    $out_oid = '1.3.6.1.4.1.171.11.116.2.2.3.1.1.3.';
  }
  elsif ($sw_info->{version} =~ /DES-3528/) {
    #dlink 3528 (�������� ������ 1����/�)
    #snmpset -c snmppass -v2c 10.133.247.2 1.3.6.1.4.1.171.12.61.3.1.1.2.24 i 1024
    #2 - ����
    #3 - �����
    #24 - port
    #1024 - �������� � ����/�
    #0 - �������� no_limit

    $in_oid  = '1.3.6.1.4.1.171.12.61.3.1.1.2.';
    $out_oid = '1.3.6.1.4.1.171.12.61.3.1.1.3.';
  }

  # DES-3550 and other
  elsif ($sw_info->{version} =~ /DES-3550/) {
    if ($SPEED > 0 && $SPEED < 1024) {
      $SPEED = $1;
    }
    else {
      $SPEED = int($SPEED / 1024);
    }

    $in_oid  = '1.3.6.1.4.1.171.11.64.2.2.6.1.1.2.';
    $out_oid = '1.3.6.1.4.1.171.11.64.2.2.6.1.1.3.';
  }
  elsif ($sw_info->{version} =~ /DES-3052/) {
    $in_oid  = '1.3.6.1.4.1.171.11.63.8.2.3.1.1.2.';
    $out_oid = '1.3.6.1.4.1.171.11.63.8.2.3.1.1.3.';
  }
  elsif ($sw_info->{version} =~ /DES-3200-10/) {
    $in_oid  = '1.3.6.1.4.1.171.11.113.1.1.2.3.1.1.2.';
    $out_oid = '1.3.6.1.4.1.171.11.113.1.1.2.3.1.1.3.';
  }
  elsif ($sw_info->{version} =~ /DES-3200-18/) {
    $in_oid  = '1.3.6.1.4.1.171.11.113.1.2.2.3.1.1.2.';
    $out_oid = '1.3.6.1.4.1.171.11.113.1.2.2.3.1.1.3.';
  }
  # Old
  elsif ($sw_info->{version} =~ /D-Link DES-3200-26/) {
    $in_oid  = '1.3.6.1.4.1.171.11.113.1.5.2.3.1.1.2.';
    $out_oid = '1.3.6.1.4.1.171.11.113.1.5.2.3.1.1.3.';
  }
  # DES-3200-26 ������� C1 3200-52, DES-3200-28/C1 (Last version)
  elsif ($sw_info->{version} =~ /DES-3200-26|3200\-52|DES-3200-28\/C1/) {
    $in_oid  = '.1.3.6.1.4.1.171.12.61.3.1.1.2.';
    $out_oid = '.1.3.6.1.4.1.171.12.61.3.1.1.3.';
  }
  # Old
  elsif ($sw_info->{version} =~ /DES-3200-28/) {
    $in_oid  = '1.3.6.1.4.1.171.11.113.1.3.2.3.1.1.2.';
    $out_oid = '1.3.6.1.4.1.171.11.113.1.3.2.3.1.1.3.';
  }
  else {
    #$RESULT{oid_prefix} = '1.3.6.1.4.1.171.11.63.8.2.2.2.1.4';
    $in_oid  = '1.3.6.1.4.1.171.11.63.6.2.3.1.1.2.';
    $out_oid = '1.3.6.1.4.1.171.11.63.6.2.3.1.1.3.';
  }

  if ($debug > 0) {
    print "Speed:\n $in_oid" . $PORT . " -> $SPEED \n $out_oid" . $PORT . " -> $SPEED\n";
  }

  if (!defined($argv->{IN_ONLY})) {
    snmpset($SNMP_COMMUNITY, "$out_oid" . $PORT, "integer", $SPEED);
  }
  if (!defined($argv->{OUT_ONLY})) {
    snmpset($SNMP_COMMUNITY, "$in_oid" . $PORT, "integer", $SPEED);
  }

  return 1;
}

#**********************************************************
#
#**********************************************************
sub edgecore_port_speed {
#  my ($attr) = @_;

  if (!$PORT) {
    print "Select port\n";
    exit;
  }

  my $in_oid  = '1.3.6.1.4.1.259.6.10.94.1.16.1.2.1.10.';
  my $out_oid = '1.3.6.1.4.1.259.6.10.94.1.16.1.2.1.10.';

  # Oid:type:value
  my @snmp_oids = ();

  if ($sw_info->{version} =~ /3528/) {

    #edge-core 3528 (��������  �� 64kbps �� 100000 kbps ������ 1����/�)
    #snmpset -c snmppass -v2c 10.133.200.101 1.3.6.1.4.1.259.6.10.94.1.16.1.2.1.10.1 i 1024
    #10 - ����
    #11 - �����
    #1   - port
    #1024 - �������� 1024 ����/�
    $in_oid  = '1.3.6.1.4.1.259.6.10.94.1.16.1.2.1.10.';
    $out_oid = '1.3.6.1.4.1.259.6.10.94.1.16.1.2.1.11.';

    # ON/Off
    #snmpset -c snmppass -v2c 10.133.200.101 1.3.6.1.4.1.259.6.10.94.1.16.1.2.1.6.1 i 1
    # 6  - ����
    # 7 -  �����
    # 1 -  port
    # 1 - ��������
    # 2 - ���������

    push @snmp_oids, "$in_oid" . $PORT . ":integer:$SPEED"  if (!defined($argv->{OUT_ONLY}));
    push @snmp_oids, "$out_oid" . $PORT . ":integer:$SPEED" if (!defined($argv->{IN_ONLY}));

    push @snmp_oids, "1.3.6.1.4.1.259.6.10.94.1.16.1.2.1.6." . $PORT . ":integer:1" if (!defined($argv->{OUT_ONLY}));
    push @snmp_oids, "1.3.6.1.4.1.259.6.10.94.1.16.1.2.1.7." . $PORT . ":integer:1" if (!defined($argv->{IN_ONLY}));
  }
  elsif ($sw_info->{version} =~ /3526/) {
    my $byte_speed = $SPEED;
    my $scale      = 3;
    my $port_speed = 0;

    if ($byte_speed < 80) {
      $scale      = 4;
      $port_speed = int($byte_speed / 8);
    }
    elsif ($byte_speed <= 1024) {
      $scale      = 3;
      $port_speed = int($byte_speed / 80);
    }
    elsif ($byte_speed <= 10240) {
      $scale      = 2;
      $port_speed = int($byte_speed / 800);
    }
    elsif ($byte_speed <= 102400) {
      $scale      = 1;
      $port_speed = int($byte_speed / 8000);
    }

    # ON off
    $in_oid  = '1.3.6.1.4.1.259.8.1.5.1.16.1.2.1.6.';
    $out_oid = '1.3.6.1.4.1.259.8.1.5.1.16.1.2.1.7.';

    # Scale
    push @snmp_oids, "$in_oid" . $PORT . ":integer:1"  if (!defined($argv->{OUT_ONLY}));
    push @snmp_oids, "$out_oid" . $PORT . ":integer:2" if (!defined($argv->{IN_ONLY}));

    $in_oid  = '1.3.6.1.4.1.259.8.1.5.1.16.1.2.1.9.';
    $out_oid = '1.3.6.1.4.1.259.8.1.5.1.16.1.2.1.11.';
    push @snmp_oids, "$in_oid" . $PORT . ":integer:$scale"  if (!defined($argv->{OUT_ONLY}));
    push @snmp_oids, "$out_oid" . $PORT . ":integer:$scale" if (!defined($argv->{IN_ONLY}));

    # mnozhnyk
    $in_oid  = '1.3.6.1.4.1.259.8.1.5.1.16.1.2.1.8.';
    $out_oid = '1.3.6.1.4.1.259.8.1.5.1.16.1.2.1.10.';
    push @snmp_oids, "$in_oid" . $PORT . ":integer:$port_speed"  if (!defined($argv->{OUT_ONLY}));
    push @snmp_oids, "$out_oid" . $PORT . ":integer:$port_speed" if (!defined($argv->{IN_ONLY}));
  }

  foreach my $line (@snmp_oids) {
    my ($oid, $type, $value) = split(/:/, $line, 3);
    if ($debug > 3) {
      print "$oid : $type -> $value\n";
    }
    snmpset($SNMP_COMMUNITY, "$oid", "$type", $value);
    if ($SNMP_Session::errmsg) {
      print "Error: Get set: oid : $type -> $value \n 	$SNMP_Session::suppress_warnings\n";
      exit;
    }

  }

  #edge-core 3526 (�������� ���� ����� ���� ������)
  #snmpset -c snmppass -v2c 10.133.254.221 1.3.6.1.4.1.259.8.1.5.1.16.1.2.1.7.24 i 1
  #6 - ����
  #7 - �����
  #24 - port
  #1 - ��������
  #2 - ���������
  #
  #snmpset -c snmppass -v2c 10.133.254.221 1.3.6.1.4.1.259.8.1.5.1.16.1.2.1.9.24 i 2
  #9 - ����
  #11 - �����
  #24 - port
  #2 - scale ( {1, 2, 3, 4}; {8M, 800K, 80K, 8K} �������������� ), �� ���� �������� � ����� ������ ������, ������ � ������ - �������� ���-�� ���������
  #
  #
  #
  #snmpset -c snmppass -v2c 10.133.254.221 1.3.6.1.4.1.259.8.1.5.1.16.1.2.1.8.24 i 3
  #8 - ����
  #10 - �����
  #24 - port
  #3 - level (���������, ���������� �� scale ��� ���������� ��������, 1-127)
}

#**********************************************************
#
#**********************************************************
sub set_speed {

  if ($get_tp_speed) {
    $Dv = Dv->new($db, $admin, \%conf);
    my $user = $Dv->info(0, { LOGIN => $LOGIN });
    if ($Dv->{errno}) {
      print "Error: User not exist '$LOGIN' ([$Dv->{errno}] $Dv->{errstr})\n";
      exit 1;
    }
    elsif ($Dv->{TOTAL} < 1) {
      print "$LOGIN - Not exist\n";
      exit 1;
    }

    #If set individual user speed
    if ($user->{SPEED} > 0) {
      $SPEED = int($user->{SPEED});
    }
    else {
      ($user->{TIME_INTERVALS}, 
      $user->{INTERVAL_TIME_TARIF}, 
      $user->{INTERVAL_TRAF_TARIF}) = $Billing->time_intervals($user->{TP_NUM});

      my (undef, $ret_attr) = $Billing->remaining_time(
        $user->{DEPOSIT},
        {
          TIME_INTERVALS      => $user->{TIME_INTERVALS},
          INTERVAL_TIME_TARIF => $user->{INTERVAL_TIME_TARIF},
          INTERVAL_TRAF_TARIF => $user->{INTERVAL_TRAF_TARIF},
          SESSION_START       => $user->{SESSION_START},
          DAY_BEGIN           => $user->{DAY_BEGIN},
          DAY_OF_WEEK         => $user->{DAY_OF_WEEK},
          DAY_OF_YEAR         => $user->{DAY_OF_YEAR},
          REDUCTION           => $user->{REDUCTION},
          POSTPAID            => 1,
          GET_INTERVAL        => 1,
          #          debug               => ($debug > 0) ? 1 : undef
        }
      );

      #    print "RT: $remaining_time\n"  if ($debug == 1);
      my %TT_IDS = %$ret_attr;

      if (keys %TT_IDS > 0) {
        require Tariffs;
        Tariffs->import();
        my $tariffs = Tariffs->new($db, \%conf, $admin);

        #Get intervals
        while (my ($k, $v) = each(%TT_IDS)) {
          print "$k, $v\n" if ($debug > 0);
          next if ($k ne 'FIRST_INTERVAL');
          $user->{TI_ID} = $v;
          my $list = $tariffs->tt_list({ TI_ID => $v, SHOW_NETS => 1 });
          foreach my $line (@$list) {
            $speeds{ $line->[0] }{IN}  = "$line->[4]";
            $speeds{ $line->[0] }{OUT} = "$line->[5]";
          }
        }
      }
      $SPEED = $speeds{0}{IN} if ($speeds{0}{IN});
    }
  }

  if ($PORT == 0) {
    #Get all
    my $dhcphosts_list = $Dhcphosts->hosts_list(
      {
        NAS_ID    => $NAS_ID,
        LOGIN     => '_SHOW',
        PORTS     => '_SHOW',
        STATUS    => '_SHOW',
        PAGE_ROWS => 10000,
        COLS_NAME => 1
      }
    );
    my %ports = ();
    foreach my $host (@{$dhcphosts_list}) {
      my $port = $host->{port};
      if ($LOGIN eq $host->{login}) {
        $ports{$port} = 0;
        $PORT = $port;
      }
      #elsif ($line->[18] > 0 && 
      elsif ($host->{disable} == 0) {
        $ports{$port} = 1;
      }
      else {
        $ports{$port} = 0;
      }
      print "$host->{login} Port: $port STATUS: $ports{$port}\n" if ($debug > 1);
    }
  }

  print "Speed: $SPEED Type: $type Version: $sw_info->{version}\n" if ($debug > 0);

  if ($type eq 'edge_core') {
    edgecore_port_speed();
  }
  elsif ($type eq 'dlink') {
    dlink_port_speed();
  }
  elsif ($type eq 'bdcom') {
    bdcom_port_speed();
  }

  return 1;
}

#**********************************************************
#
#**********************************************************
sub set_vlan {

  if ($type eq 'edge_core') {
    edgecore_vlan();
  }
  elsif ($type eq 'dlink') {
    dlink_vlan_add();
  }

}

#**********************************************************
# http://sudousers.blogspot.com/
#**********************************************************
#sub get_soft_version {
#  #my ($attr) = @_;
#
#  my $software_oid = '';
#  #edge core
#  if ($sw_info->{version} =~ /3510/) {
#  	$software_oid = '.1.3.6.1.4.1.259.8.1.5.1.1.5.4.0';
#  }
#  else {
#  	#Edge core ES3528M
#  	$software_oid = '.1.3.6.1.4.1.259.6.10.94.1.1.5.4.0';
#  }
#
#  $RESULT{soft_version} = snmpget($SNMP_COMMUNITY, "$software_oid")
#}

#**********************************************************
=head2 nas_version() Get nas info from billing and from switch

=cut
#**********************************************************
sub nas_version {
  #my ($attr) = @_;

  my %RESULT = ();
  $type   = 'Unknown';
  
  if (length($SNMP_COMMUNITY) < 4) {
  	print "Error: NAS_ID: $NAS_ID Not specified SNMP community\n";
  	return 1;
  }
  
  if ($RESULT{version} = snmpget($SNMP_COMMUNITY, ".1.3.6.1.2.1.1.1.0")) {
    if ($SNMP_Session::errmsg) {
      print "Error: Get Version	$SNMP_Session::suppress_warnings\n";
      exit;
    }

    elsif ($RESULT{version} =~ /Edge\-Core|ES3526/) { 
    	$type = 'edge_core'; 
    }
    elsif ($RESULT{version} =~ /DES/) { 
      $type = 'dlink'; 
    }
    elsif ($RESULT{version} =~ /BDCOM/) { 
      $type = 'bdcom'; 
    }

    $sw_info->{TYPE}    = $type;
    $sw_info->{version} = $RESULT{version};
  }

  $Nas->info({ NAS_ID => $NAS_ID });
  $NAS_MNG_IP_PORT = $Nas->{NAS_MNG_IP_PORT};
  $NAS_MNG_PASSWD  = $Nas->{NAS_MNG_PASSWD};
  $NAS_TYPE        = $Nas->{NAS_TYPE};
  $NAS_MNG_USER    = $Nas->{NAS_MNG_USER};

  return $type;
}


#**********************************************************
=head2 devices_info()

=cut
#**********************************************************
sub devices_info {
	my ($device_list)=@_;
	
	$SNMP_COMMUNITY = $argv->{SNMP_COMMUNITY} || 'public';
	
	my $content = '';
	open(my $fh, '<', "$device_list") or die "Can't open file '$device_list' $!\n";
	  while(<$fh>) {
	  	$content .= $_;
	  }
	close($fh);
	
	my @device_arr = split(/[\r\n]+/, $content);
	my %RESULT = ();
  my %dublicates = ();
	my %mac_info   = ();
	
	foreach my $device_ip (@device_arr) {
		print "$device_ip: ";
	  if ($RESULT{version} = snmpget($SNMP_COMMUNITY.'@'.$device_ip, ".1.3.6.1.2.1.1.1.0")) {
      #if ($SNMP_Session::errmsg) {
      #  print "Error: Get Version	$SNMP_Session::suppress_warnings\n";
      #}
      if ($RESULT{version}) {
        print "Version: $RESULT{version}\n";
        # Get posrt
        my @ports = snmpwalk($SNMP_COMMUNITY.'@'.$device_ip, ".1.3.6.1.2.1.2.2.1.1");
        print "   Ports: ". ($#ports+1) ."\n";
        #Get macs
        #For zyxel
        if ($RESULT{version}	=~ /IES1/) {
        	my @macs = snmpwalk($SNMP_COMMUNITY.'@'.$device_ip, ".1.3.6.1.2.1.17.7.1.2.2.1.2");
        	#.1.3.6.1.2.1.17.7.1.2.2.1.2.301.0.3.160.180.156.27 = INTEGER: 49
        	foreach my $line (@macs) {
        		$line =~ /(\d+)\.(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}):(.+)/;
        		my($vlan, $mac_dec, $port) = ($1, $2, $3);
        		
        		my @m_arr = split(/\./, $mac_dec, 6);
        		my @mach_arr = ();
        		foreach my $m (@m_arr)  {
        			push @mach_arr, sprintf('%.2x', $m);
        		}
        		
        		my $mac = join(':', @mach_arr);
            $mac =~ s/[\r]//g;            

            if ($argv->{MAC} && $argv->{MAC} ne $mac) {
            	next;
            }

            $dublicates{$mac}++;
            push @{ $mac_info{$mac} }, "$device_ip:$port:$vlan";
        		print "$vlan\t$mac\t$port\n";
        	}
        }
        #For other
        else {
          my @macs = snmpwalk($SNMP_COMMUNITY.'@'.$device_ip, ".1.3.6.1.2.1.4.22.1");
          print "   Macs: ". ($#macs+1) ."\n";
          foreach my $line (@macs) {
            # 1.1001.10.133.200.124:1001
            if ($line =~ /^(\d+)\.(\d+)\.(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}):(.+)/){
              my ($id, $port, $ip, $value)=($1, $2, $3, $4);
              if ($id == 2) {
                my $mac = '';
                map { $mac .= sprintf("%02X:", $_) } unpack "CCCCCC", $value;

                if ($argv->{MAC} && $argv->{MAC} ne $mac) {
            	    next;
                }

                print "$id, $port, $ip, $mac\n";
                $dublicates{$mac}++;
                push @{ $mac_info{$mac} }, "$device_ip:$port";
              }
            }
          }
          #print join("\n", @macs);
        }
      }
      else {
      	print "!!! error";
      }
    }
	  print "\n";
	}

  #Check dublicates macs
  my @sorted_dub = sort {
    $dublicates{$b} <=> $dublicates{$a}
     ||
    length($a) <=> length($b)
     ||
    $a cmp $b
  } keys %dublicates;       # ���������� �� ��������

  foreach my $mac (@sorted_dub) {
  	if ( $dublicates{$mac} > 1 ) {
  	  print "$mac $dublicates{$mac}\n";
  	  foreach my $info ( @{ $mac_info{$mac} } ) {
  	  	 print "   $info\n";
  	  }
  	}
  }

  return 1;
}


#**********************************************************
#
#**********************************************************
sub bdcom_port_speed {
  #my ($attr) = @_;

  if (!$PORT) {
    print "Select port\n";
    exit;
  }

  my $in_oid  = '1.3.6.1.4.1.259.6.10.94.1.16.1.2.1.10.';
  my $out_oid = '1.3.6.1.4.1.259.6.10.94.1.16.1.2.1.10.';

  # Oid:type:value
  my @snmp_oids = ();

  push @snmp_oids, "$in_oid" . $PORT, 'integer', "$SPEED"  if (!defined($argv->{OUT_ONLY}));
  push @snmp_oids, "$out_oid" . $PORT, 'integer', "$SPEED" if (!defined($argv->{IN_ONLY}));

  if (! snmp_set({
      SNMP_COMMUNITY => $SNMP_COMMUNITY, 
      OID            => \@snmp_oids,
      DEBUG          => $debug 
     }) ) {
    print "Error";
  }

  return 1;
}

1

