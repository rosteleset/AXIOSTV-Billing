#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';

our $libpath;
BEGIN {
  use FindBin '$Bin';

  our $Bin;
  use FindBin '$Bin';

  $libpath = $Bin . '/../'; #assuming we are in /usr/axbills/libexec/
  if ($Bin =~ m/\/axbills(\/)/) {
    $libpath = substr($Bin, 0, $-[1]);
  }

  unshift (@INC, $libpath,
    $libpath . '/AXbills/',
    $libpath . '/AXbills/mysql/',
    $libpath . '/AXbills/Control/',
    $libpath . '/lib/'
  );
}

our (%conf);
my $VERSION = 0.01;

do "libexec/config.pl";

use Admins;
use Users;
use AXbills::SQL;
use AXbills::Base qw(parse_arguments ip2int _bp);
use AXbills::Nas::Mikrotik;
use Nas;
use Internet;

my $db = AXbills::SQL->connect(@conf{qw/dbtype dbhost dbname dbuser dbpasswd/}, \%conf);
my $admin = Admins->new($db, \%conf);
$admin->info($conf{USERS_WEB_ADMIN_ID} ? $conf{USERS_WEB_ADMIN_ID} : $conf{SYSTEM_ADMIN_ID},
  { IP => '127.0.0.1', SHORT => 1 });

my $Users    = Users->new($db, $admin, \%conf);
my $Internet = Internet->new($db, $admin, \%conf);


# Modules initialisation
my $Nas = Nas->new($db, \%conf);

my %ARGS  = %{ parse_arguments(\@ARGV) };

my $DEBUG = $ARGS{DEBUG} || 0;
my $uid   = $ARGS{UID}   || 0;
my $dhcp_server = $ARGS{DHCP_SERVER};
my $loca_address_ip_pool_id = $conf{INTERNET_LOCAL_ADDRESS_IP_POOL_ID};

my $local_address_ip_pool_info = $Nas->ip_pools_info($loca_address_ip_pool_id);



if (!$uid) {
  print "0:Error: UID is empty\n!";

  exit 0;
};

my $user_info          = $Users->info($uid);
#my $user_personal_info = $Users->pi({UID => $uid});
my $user_internet_info = $Internet->user_info($uid);

_bp("User info",          $user_info,          { TO_CONSOLE => 1 }) if ($DEBUG > 1);
#_bp("User personal info", $user_personal_info, { TO_CONSOLE => 1 }) if ($DEBUG > 1);
_bp("User internet info", $user_internet_info, { TO_CONSOLE => 1 }) if ($DEBUG > 1);

my $user_nas    = $user_internet_info->{NAS_ID} || 0;
my $user_ip_num = ip2int($user_internet_info->{IP});
my $user_ip = $user_internet_info->{IP};

if ($user_nas) {
  print "Info: User nas id - $user_nas\n" if $DEBUG > 1;

  my $nas_info = $Nas->info({ NAS_ID => $user_nas });
  _bp("Nas info", $nas_info, { TO_CONSOLE => 1 }) if ($DEBUG > 1);

  if ($nas_info->{NAS_TYPE} eq 'mikrotik' || $nas_info->{NAS_TYPE} eq 'mikrotik_dhcp') {
    print "Info: Nas is mikrotik\n" if $DEBUG > 0;
    my $vlan_id   = $user_internet_info->{VLAN};
    my $interface = $user_internet_info->{PORT};
    my $nas_mac  = $nas_info->{MAC};

    my @commands_to_execute = ();

    if(!$interface){
      print "0:User inteface is empty\n";
      exit 0;
    }

    my $static_ip_pools = $Nas->ip_pools_list({ STATIC => 1, SHOW_ALL_COLUMNS => 1, COLS_NAME => 1 });
    my $dns = '';
    foreach my $ip_pool (@$static_ip_pools) {
      if ($ip_pool->{ip} <= $user_ip_num && $ip_pool->{last_ip_num} >= $user_ip_num) {
        _bp("", $ip_pool, {TO_CONSOLE => 1}) if ($DEBUG > 1);
        $dns = $ip_pool->{dns};
      }
    }

    if($vlan_id){
      @commands_to_execute = (
        qq{/interface vlan add disabled=no name=$interface-vlan$vlan_id vlan-id=$vlan_id interface=$interface arp=proxy-arp},
        qq{/ip dhcp-relay add add-relay-info=yes dhcp-server=$dhcp_server disabled=no interface=$interface-vlan$vlan_id local-address=0.0.0.0 name=relay-$interface-vlan$vlan_id relay-info-remote-id=$nas_mac-$interface-$vlan_id},
        qq{/ip address add address=$dns network=$user_ip interface=$interface-vlan$vlan_id comment="$user_info->{LOGIN}|$interface|vlan$vlan_id|"},
      );
    }
    else{
      @commands_to_execute = (
        #        qq{/interface vlan add disabled=no name=vlan$vlan_id vlan-id=$vlan_id interface=$interface comment="$user_info->{LOGIN}|vlan$vlan_id|" arp=proxy-arp},
        qq{/ip dhcp-relay add add-relay-info=yes dhcp-server=$dhcp_server disabled=no interface=$interface local-address=0.0.0.0 name=relay$interface relay-info-remote-id=$nas_mac-$interface-0},
        qq{/ip address add address=$dns network=$user_ip interface=$interface comment="$user_info->{LOGIN}|$interface|vlan$vlan_id|"},
      );
    }


    my AXbills::Nas::Mikrotik $mikrotik = AXbills::Nas::Mikrotik->new($nas_info, \%conf, { DEBUG => 0 });
    foreach my $command (@commands_to_execute) {
      $mikrotik->execute($command);
    }

    print "1:Dhcp relay added";
  }
}
else{
  print "0:Empty field user NAS\n";
}