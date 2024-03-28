#!/usr/bin/perl -w

=head1 NAME

  Iptv access control

=cut

use vars qw($begin_time %FORM %LANG
$DATE $TIME
$CHARSET
@MODULES
$SNMP_Session

);



BEGIN {
 my $libpath = '../../../';
 $sql_type='mysql';
 unshift(@INC, './');
 unshift(@INC, $libpath ."AXbills/$sql_type/");
 #unshift(@INC, "/usr/axbills/AXbills/$sql_type/");
 #unshift(@INC, "/usr/axbills/");
 unshift(@INC, $libpath);
 unshift(@INC, '../../');
 unshift(@INC, '../../AXbills/mysql');
 unshift(@INC, '../../AXbills/');
 unshift(@INC, $libpath . 'libexec/');
 #unshift(@INC, "/usr/axbills/");
 #unshift(@INC, "/usr/axbills/AXbills/$sql_type/");

 eval { require Time::HiRes; };
 if (! $@) {
    Time::HiRes->import(qw(gettimeofday));
    $begin_time = gettimeofday();
   }
 else {
    $begin_time = 0;
  }
}

use FindBin '$Bin';

require $Bin . '/../../../libexec/config.pl';

use AXbills::Base;
use AXbills::SQL;
use AXbills::HTML;
use Users;
use Iptv;
use Finance;
use Admins;


require Snmputils;
Snmputils->import();
require SNMP_Session;
SNMP_Session->import();
require SNMP_util;
SNMP_util->import();
require BER;
BER->import();


my $sql  = AXbills::SQL->connect($conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd});
my $db   = $sql->{db};
#Operation status

my $admin    = Admins->new($db, \%conf);
$admin->info($conf{SYSTEM_ADMIN_ID}, { IP => '127.0.0.1' });
my $Iptv     = Iptv->new($db, $admin, \%conf);
my $Users    = Users->new($db, $admin, \%conf);
my $debug    = 0;
my $version  = 0.08;
my $error_str= '';

#Arguments
my $ARGV = parse_arguments(\@ARGV);

if (defined($ARGV->{help})) {
	help();
	exit;
}

if ($ARGV->{DEBUG}) {
	$debug=$ARGV->{DEBUG};
	print "DEBUG: $debug\n";
}

my $default_igmp_group = $conf{IPTV_IGMP_GROUP} || '232.0.0.0';
my $default_deny_profile = $conf{IPTV_IGMP_DENY} || 40;

# igmp_group
# ip_mask
my $filter_param       = 'ip_mask';

$DATE = $ARGV->{DATE} if ($ARGV->{DATE});
$LIST_PARAMS{PAGE_ROWS}        = 1000000;
$LIST_PARAMS{LOGIN}            = $ARGV->{LOGIN};
$LIST_PARAMS{NAS_ID}           = $ARGV->{NAS_ID};
$LIST_PARAMS{TP_ID}            = $ARGV->{TP_ID} || ">0";


iptv_config_push();


#**********************************************************
#
#**********************************************************
sub iptv_config_push {
	my ($attr)=@_;

  if($debug>6) {
  	$Iptv->{debug}=1;
  }

  $LIST_PARAMS{SHOW_CONNECTIONS} = 1,

  my $list = $Iptv->user_list({
          SHOW_CONNECTIONS => 1,
          LOGIN    => '_SHOW',
          DEPOSIT  => '_SHOW',
          CREDIT   => '_SHOW',
          TP_ID    => '_SHOW',
          TP_NUM   => '_SHOW',
	        NAS_IP   => '_SHOW',
	        PORT_ID  => '_SHOW',
	        IPTV_STATUS=>'_SHOW',
	        TP_FILTER=> '_SHOW',
          %LIST_PARAMS,
          COLS_NAME => 1,
          COLS_UPPER=> 1,
                          });	

foreach my $info (@$list) {
  if($debug > 0) {
    print "LOGIN: $info->{LOGIN} TP_ID: $info->{TP_NUM}/$info->{TP_ID} STATUS: $info->{IPTV_STATUS} HOST: $info->{NAS_IP} PORT: $info->{PORTS} TYPE: $info->{NAS_TYPE} NAS_IP: $info->{NAS_IP} / $info->{MNG_PASSWORD}\@$info->{MNG_HOST_PORT}\n";
  }

	if (! $info->{NAS_IP} || ! $info->{PORTS}) {
		print "Error: $info->{LOGIN} Unknown client switch \n";
	  next;	
  }
  elsif(! $info->{MNG_HOST_PORT}) {
		print "Error: $info->{LOGIN} NAS MNG_HOST_PORT not specify \n";
	  next;	
  }


  my $action = 'DOWN';
  if ($info->{DEPOSIT} + $info->{CREDIT} > 0 && ! $info->{iptv_status}) {
    $action = 'UP';
  }

  my $result;
  if ($ARGV->{$action.'_CMD'}) {
    $result = make_cmd({ $action => 1, INFO => $info });
  }
  else {
    $result = make_snmp({ $action => 1, INFO => $info });
  }

  if ($debug > 1) {
    print "Result: $result";
  }
}
	
	return 0;
}


#**********************************************************
# Make snmp cmd
# Create ACL profile and wait (id 3 for example):
#snmpset -v2c -c solar 10.1.11.10 1.3.6.1.4.1.171.10.75.5.2.15.1.2.1.16.3 i 5
#
#L3v4 ACL profile:
#snmpset -v2c -c solar 10.1.11.10 1.3.6.1.4.1.171.10.75.5.2.15.1.2.1.2.3 i 2
#
#IPv4:
#snmpset -v2c -c solar 10.1.11.10 1.3.6.1.4.1.171.10.75.5.2.15.1.2.1.8.3 i 1
#
#IGMP, IGMP type:
#snmpset -v2c -c solar 10.1.11.10 1.3.6.1.4.1.171.10.75.5.2.15.1.2.1.7.3 i 2
#snmpset -v2c -c solar 10.1.11.10 1.3.6.1.4.1.171.10.75.5.2.15.1.2.1.4.3 x 00000300
#
#IP destination mask (always 8):
#snmpset -v2c -c solar 10.1.11.10 1.3.6.1.4.1.171.10.75.5.2.15.1.2.1.9.3 x ff000000
#
#
#
# userrrrr
#Create ACL rule and wait:
#snmpset -v2c -c solar 10.1.11.10 1.3.6.1.4.1.171.10.75.5.2.15.3.1.1.99.1.3 i 5
#
#Set multicast group to allow (according to tarif):
#snmpset -v2c -c solar 10.1.11.10 1.3.6.1.4.1.171.10.75.5.2.15.3.1.1.6.1.3 a 231.0.0.0
#
#Set user port (port 1 in example):
#snmpset -v2c -c solar 10.1.11.10 1.3.6.1.4.1.171.10.75.5.2.15.3.1.1.22.1.3 x 80000000
#
#Set allow:
#snmpset -v2c -c solar 10.1.11.10 1.3.6.1.4.1.171.10.75.5.2.15.3.1.1.23.1.3 i 1
#
#Activate rule:
#snmpset -v2c -c solar 10.1.11.10 1.3.6.1.4.1.171.10.75.5.2.15.3.1.1.99.1.3 i 1

#Activate profile:
#snmpset -v2c -c solar 10.1.11.10 1.3.6.1.4.1.171.10.75.5.2.15.1.2.1.16.3 i 1
#
# http://dlink-manuals.org/dlink-howto-use-snmp-for-igmp-management-on-des-3026/
#
#**********************************************************
sub snmp_dlink {
  my ($attr) = @_;

  my $SNMP_COMMUNITY = $attr->{INFO}->{SNMP_COMMUNITY};

  #Default  DES-1210-28
  my %oids = (
    main_oid  => '1.3.6.1.4.1.171.10.75.5.2.15.1.2.1',
    acl       => '1.3.6.1.4.1.171.10.75.5.2.15.1.2.1.16',
    l3v4_acl  => '1.3.6.1.4.1.171.10.75.5.2.15.1.2.1.2',
    ipv4      => '1.3.6.1.4.1.171.10.75.5.2.15.1.2.1.8',
    igmp      => '1.3.6.1.4.1.171.10.75.5.2.15.1.2.1.7',
    igmp_type => '1.3.6.1.4.1.171.10.75.5.2.15.1.2.1.4',
    #(always 8):
    ip_mask   => '1.3.6.1.4.1.171.10.75.5.2.15.1.2.1.9',
    active    => '1.3.6.1.4.1.171.10.75.5.2.15.1.2.1.16',

    #Users add
    main_users    => '1.3.6.1.4.1.171.10.75.5.2.15.3.1.1',
    create_acl    => '1.3.6.1.4.1.171.10.75.5.2.15.3.1.1.99',
    set_multicast_group => '1.3.6.1.4.1.171.10.75.5.2.15.3.1.1.6',
    user_port     => '1.3.6.1.4.1.171.10.75.5.2.15.3.1.1.22',
    set_allow     => '1.3.6.1.4.1.171.10.75.5.2.15.3.1.1.23',
    activate_rule => '1.3.6.1.4.1.171.10.75.5.2.15.3.1.1.99',
  );


  if ($attr->{NAS_INFO}->{VERSION} =~ 'DES-1210-52') {
    %oids = (
      main_oid  => '1.3.6.1.4.1.171.10.75.7.15.1.2.1',
      acl       => '1.3.6.1.4.1.171.10.75.7.15.1.2.1.16',
      l3v4_acl  => '1.3.6.1.4.1.171.10.75.7.15.1.2.1.2',
      ipv4      => '1.3.6.1.4.1.171.10.75.7.15.1.2.1.8',
      igmp      => '1.3.6.1.4.1.171.10.75.7.15.1.2.1.7',
      igmp_type => '1.3.6.1.4.1.171.10.75.7.15.1.2.1.4',
      #(always 8):
      ip_mask   => '1.3.6.1.4.1.171.10.75.7.15.1.2.1.9',
      active    => '1.3.6.1.4.1.171.10.75.7.15.1.2.1.16',

      #Users add
      main_users    => '1.3.6.1.4.1.171.10.75.7.15.3.1.1',
      create_acl    => '1.3.6.1.4.1.171.10.75.7.15.3.1.1.99',
      set_multicast_group => '1.3.6.1.4.1.171.10.75.7.15.3.1.1.6',
      user_port     => '1.3.6.1.4.1.171.10.75.7.15.3.1.1.22',
      set_allow     => '1.3.6.1.4.1.171.10.75.7.15.3.1.1.23',
      activate_rule => '1.3.6.1.4.1.171.10.75.7.15.3.1.1.99',
    );
  }


$attr->{OIDS} = \%oids;

my $result     = 0;
my $profiles   = dlink_get_profiles($attr);
my $profile_id = $attr->{INFO}->{TP_NUM};
my $port       = $attr->{INFO}->{PORTS};
my $ports_map  = 'B*';

#Create profile
if (! $profiles->{$profile_id} || $profiles->{$profile_id}{16} != 1 ) {
  if ($debug > 0) {
    if ( $profiles->{$profile_id}{16} && $profiles->{$profile_id}{16} != 1) {
      print "Created but not active ($profiles->{$profile_id}{16})\n";
      $attr->{RECREATE}=$profile_id;
    }
    else {
      print "Profile: $attr->{INFO}->{TP_NUM} not exist. Create it\n";
    }
  }

  dlink_add_profiles($attr);
}


my $active_profiles = dlink_get_activates($attr);

if ($debug > 0) {
  print "Profile:". (($active_profiles->{$port}{$profile_id}{22}) ? " Exist" : "Not set" ) ."\n";
}

my $filter_id = '231.0.0.0';
if ($attr->{INFO}->{FILTER_ID} && $filter_param eq 'igmp_group') {
  $filter_id = $attr->{INFO}->{FILTER_ID};
}
else {
  $filter_id = $default_igmp_group;
}

if ($attr->{UP}) {
  if ($active_profiles->{$port}) {

    foreach my $profile_cur ( keys %{ $active_profiles->{$port} } ) {

      if ($active_profiles->{$port}{$profile_cur} && $profile_cur != $profile_id
       || $active_profiles->{$port}{$profile_cur}{99} && $active_profiles->{$port}{$profile_cur}{99} == 3
       )  {
        snmp_make({ %$attr, OIDS => [ $oids{create_acl} .'.'. $port .'.'. $profile_cur, 'integer', 6 ] });
        print "Del old profile: $profile_cur" if ($debug > 2);
      }
    }
  }

  if (! $active_profiles->{$port}{$profile_id}{22}) {

  snmp_make({ %$attr,
              OIDS => [ $oids{create_acl} .'.'. $port .'.'. $profile_id, 'integer', 5 ]}),

  my $cure_ports = snmpget($SNMP_COMMUNITY, $oids{user_port}.'.'. $port . '.' . $profile_id);

  if (!$cure_ports) {
    print "Can't get ports\n" if ($debug > 2);
  }
  elsif($attr->{NAS_INFO}->{VERSION} =~ /DES-1210-52/) {
    #$cure_ports = '';
  }

  my @switch_ports = split(//, unpack("$ports_map", $cure_ports));

  $switch_ports[$port-1]=1;
  my $ports_bin    = pack("$ports_map", join("", @switch_ports));

  if ($debug > 3) {
    my @ar = unpack("H*", $ports_bin);
    print "Ports: ". join("", @ar);
  }

  my @arr = (
    $oids{set_multicast_group}.'.'. $port .'.'. $profile_id, 'ipaddr', $filter_id,
    $oids{user_port}     .'.'.      $port .'.'. $profile_id, 'string', $ports_bin,
    $oids{set_allow}     .'.'.      $port .'.'. $profile_id, 'integer', 1,
    $oids{activate_rule} .'.'.      $port .'.'. $profile_id, 'integer', 1,
  );

  snmp_make({ %$attr, OIDS => \@arr });
}
}
else {
  if ($active_profiles->{$port}{$profile_id}{22}) {
    my @arr = (
      $oids{create_acl}    .'.'.      $port .'.'. $profile_id, 'integer', 6,
    );

    snmp_make({ %$attr, OIDS => \@arr });
  }
}

#Block
  if ($ARGV->{DENY_PROFILE}) {
    if (! $profiles->{$default_deny_profile}) {
      $attr->{INFO}->{TP_NUM} = $default_deny_profile;
      dlink_add_profiles({ %$attr, IP_MASK => '255.0.0.0' });

      if ($debug > 0) {
         print "Add deny profile: '$default_deny_profile'\n";
      }
    }

    $port = $default_deny_profile;

    if (! $active_profiles->{$port}{$default_deny_profile}{22}) {

      if ($debug > 0) {
        print "Add deny ports: '$default_deny_profile'\n";
      }

      if($attr->{NAS_INFO}->{VERSION} =~ /DES-1210-52/) {
        #$cure_ports = '';
      }

      my $profile_id = $default_deny_profile;

      snmp_make({ %$attr,
              OIDS => [ $oids{create_acl} .'.'. $port .'.'. $profile_id, 'integer', 5 ]}),

      my $cure_ports = snmpget($SNMP_COMMUNITY, $oids{user_port}.'.'. $port . '.' . $profile_id);

      if (!$cure_ports) {
        print "Can't get ports\n" if ($debug > 2);
      }
      elsif($attr->{NAS_INFO}->{VERSION} =~ /DES-1210-52/) {
        # $cure_ports = '';
      }

      my @switch_ports = split(//, unpack("$ports_map", $cure_ports));

      print ">> $#switch_ports\n";

      for($i=0; $i<=(($#switch_ports > 31) ? 47 : 23); $i++) {
        $switch_ports[$i]=1;
      }
      my $ports_bin    = pack("$ports_map", join("", @switch_ports));

      if ($debug > 3) {
        my @ar = unpack("H*", $ports_bin);
        print "Ports: ". join("", @ar) ."\n";
      }

      my @arr = (
      #$oids{create_acl}    .'.'.      $port .'.'. $profile_id, 'integer', 5,
      $oids{set_multicast_group}.'.'. $port .'.'. $profile_id, 'ipaddr', $filter_id,
      $oids{user_port}     .'.'.      $port .'.'. $profile_id, 'string', $ports_bin,
      $oids{set_allow}     .'.'.      $port .'.'. $profile_id, 'integer', 2,
      $oids{activate_rule} .'.'.      $port .'.'. $profile_id, 'integer', 1,
      );

      snmp_make({ %$attr, OIDS => \@arr });

    }
    else {
      if ($debug>0) {
        print "Profile Exist: $port / $default_deny_profile \n";
        #del assign
        #ssnmp_make({ %$attr, OIDS => [ $oids{create_acl} .'.'. $port .'.'. $profile_id, 'integer', 6 ] });
      }
    }
  }


  return $result
}


#**********************************************************
#
#**********************************************************
sub dlink_get_activates {
  my ($attr) = @_;

  my %RESULT         = ();

  my $SNMP_COMMUNITY = $attr->{INFO}->{SNMP_COMMUNITY};

  print "Get activates\n" if ($debug > 1);

  my %type_ids = (
     3  => 'Active',
     6  => 'multicast group',
     22 => 'Ports',
     23 => 'Allow',
     99 => 'Create ACL'
    );

  my @arr = snmpwalk($SNMP_COMMUNITY, $attr->{OIDS}->{main_users});

  foreach my $line (@arr) {
    my ($id, $val) = split(/:/, $line) ;
    my ($type_, $port, $profile_id) = split(/\./, $id);

    print "$id -> $val\n" if($debug > 7);

    if ($type_ == 22) {
      $val = unpack("H*", $val);
    }

    $RESULT{$port}{$profile_id}{$type_} = $val;
  }

  if ($debug > 1) {
    foreach my $port ( sort keys %RESULT) {
      print "Port: $port\n";

      foreach my $profile ( sort keys %{ $RESULT{$port} }) {
        print "Profile: $profile\n";

        foreach my $val ( sort keys %{ $RESULT{$port}{$profile} } ) {
          next if (! $type_ids{$val});
          print "  ". (($type_ids{$val}) ? "($val) $type_ids{$val}" : $val) .": $RESULT{$port}{$profile}{$val}\n";
        }
      }
    }
  }

  return \%RESULT;
}

#**********************************************************
#
#**********************************************************
sub dlink_add_profiles {
  my ($attr) = @_;

  my %RESULT         = ();
  my $SNMP_COMMUNITY = $attr->{INFO}->{SNMP_COMMUNITY};
  my $profile_id     = $attr->{INFO}->{TP_NUM};

  if ($debug > 0) {
    print "Adding profile: $profile_id\n";
  }

  if ($profile_id > 50) {
    print "Max profile number 50\n";
    exit;
  }

  my $oids = $attr->{OIDS};

  my $ip_mask = 'ff000000';
  if($attr->{IP_MASK}) {
    $ip_mask = $attr->{IP_MASK};
  }
  elsif ($filter_param eq 'ip_mask') {
    $ip_mask = $attr->{INFO}->{FILTER_ID};
  }

  if($ip_mask =~ /(\d+)\.(\d+)\.(\d+)\.(\d+)/ ) {
    $ip_mask = sprintf("%02x%02x%02x%02x", $1, $2, $3, $4);
  }

  my @arr = (
    $oids->{acl}       . '.' . $profile_id, 'integer', 5,
    $oids->{l3v4_acl}  . '.' . $profile_id, 'integer', 2,
    $oids->{ipv4}      . '.' . $profile_id, 'integer', 1,
    $oids->{igmp}      . '.' . $profile_id, 'integer', 2,
    $oids->{igmp_type} . '.' . $profile_id, 'string',  pack("H*", '00000300'),
    #IP destination mask (always 8):
    $oids->{ip_mask}   . '.'.  $profile_id, 'string',  pack("H*", $ip_mask),
    $oids->{active}    . '.'.  $profile_id, 'integer', 1
  );

  if ($attr->{RECREATE}) {
    @arr = ( $oids->{active}    . '.'.  $profile_id, 'integer', 6, @arr);
  }

  snmp_make({ %$attr, OIDS => \@arr });

  return 0;
}

#**********************************************************
#
#**********************************************************
sub snmp_make {
  my ($attr) = @_;

  my $SNMP_COMMUNITY = $attr->{INFO}->{SNMP_COMMUNITY};
  my $arr = $attr->{OIDS};

  if ($#{ $arr } == -1) {
    print "No values..........\n";
    return 0;
  }

  for($i=0; $i<=$#{ $arr }; $i+=3) {
    # Create ACL rule and wait

    if ($debug > 3) {
      print "SNMP: $arr->[$i] ". $arr->[$i+1] ." ". $arr->[$i+2] ."\n";
    }

    if (! $arr->[$i] || ! $arr->[$i+1] || ! $arr->[$i+2]) {
      print "Not set $i/ $arr->[$i] ". $arr->[$i+1] ." ". $arr->[$i+2] ."\n";
      exit;
    }

    if (! snmpset($SNMP_COMMUNITY, $arr->[$i], $arr->[$i+1], $arr->[$i+2])) {
      print "Error: $arr->[$i] ". $arr->[$i+1] ." ". $arr->[$i+2] ."\n";
      exit;
    }
  }

}


#**********************************************************
#
#**********************************************************
sub dlink_get_profiles {
  my ($attr) = @_;

  my %RESULT         = ();

  my $SNMP_COMMUNITY = $attr->{INFO}->{SNMP_COMMUNITY};

  my $oid = $attr->{OIDS}->{main_oid} || '1.3.6.1.4.1.171.10.75.5.2.15.1.2.1';

  my %type_ids = (
     1  => 'Active',
     2  => 'L3v4 ACL',
     4  => 'IGMP type',
     7  => 'IGMP',
     8  => 'IPv4',
     9  => 'IP destination mask',
     16 => 'ACL'
    );

  my @arr = snmpwalk($SNMP_COMMUNITY, $oid);
  foreach my $line (@arr) {
    my ($id, $val) = split(/:/, $line) ;
    my ($type_, $profile_id) = split(/\./, $id);

    #print "$id -> $val\n";
    if ($type_ == 4 || $type_ == 9) {
      $val = unpack("H*", $val);
    }

    $RESULT{$profile_id}{$type_} = $val;
  }

  if ($debug > 1) {
    foreach my $profile_id ( sort keys %RESULT) {
      print "Profile: $profile_id\n";
      foreach my $val ( keys %{ $RESULT{$profile_id} } ) {
        next if (! $type_ids{$val});
        print "  ". (($type_ids{$val}) ? "($val) $type_ids{$val}" : $val) .": $RESULT{$profile_id}{$val}\n";
      }
    }
  }

  return \%RESULT;
}

#**********************************************************
# Make snmp cmd
#**********************************************************
sub make_snmp {
  my ($attr) = @_;

  #Get switch model
  $attr->{INFO}->{SNMP_COMMUNITY} = "$attr->{INFO}->{MNG_USER}\@$attr->{INFO}->{MNG_HOST_PORT}";
  my $nas_info = snmp_get_version($attr->{INFO});

  my $type = $nas_info->{TYPE};
  #Send cmd
  my $function = 'snmp_'.$type;

  if ($debug > 3) {
    print "Version: $nas_info->{VERSION} Type: $type\n";
  }

  if (defined(&$function)) {
    $function->({ %$attr, NAS_INFO => $nas_info });
  }
  else {
    print "Unknown: $attr->{INFO}->{MNG_USER}\@$attr->{INFO}->{MNG_HOST_PORT} VERSION: $nas_info->{VERSION} TYPE: $nas_info->{TYPE}\n";
  }
}


#**********************************************************
# Get switch info
#**********************************************************
sub snmp_get_version {
  my ($attr) = @_;

  my %RESULT         = ();
  my $type           = 'Unknown';
  my $SNMP_COMMUNITY = $attr->{SNMP_COMMUNITY};

  if (length($SNMP_COMMUNITY) < 4) {
  	print "Error: NAS_ID: $attr->{NAS_ID} Not specified SNMP community\n";
  	return 1;
  }

  if ($RESULT{VERSION} = snmpget($SNMP_COMMUNITY, ".1.3.6.1.2.1.1.1.0")) {
    if ($SNMP_Session->{errmsg}) {
      print "Error: Get Version	"; #$SNMP_Session::suppress_warnings\n";
      exit;
    }

    elsif ($RESULT{VERSION} =~ /Edge\-Core|ES3526/) {
    	$type = 'edge_core';
    }
    elsif ($RESULT{VERSION} =~ /DES/) {
      $type = 'dlink';
    }

    $RESULT{TYPE}    = $type;
  }

  return \%RESULT;
}

#**********************************************************
# Make external cmd
#**********************************************************
sub make_cmd {
  my ($attr) = @_;

  my $cmd = '';
  if ($attr->{UP}) {
    $cmd = $ARGV->{UP_CMD} || '';
  }
  else {
  	$cmd = $ARGV->{DOWN_CMD} || '';
  }

  #Make cmd
  $cmd = tpl_parse("$cmd", $attr->{INFO});

  if ($debug > 5) {
  	print "CMD: $cmd\n";
  }

  my $output = `$cmd`;
  if ($debug>3) {
    print "CMD: $cmd\n";
    print "RESULT: $output\n";
  }
}




#**********************************************************
#
#**********************************************************
sub	help {

print << "[END]";	
  Iptv switch managment: $version
    LOGIN     -
    NAS_ID    -
    TP_ID     -
    DEBUG=... - debug mode
    ROWS=..   - Rows for analise
    UP_CMD=   - Programs for up routing
    DOWN_CMD= - Programs for down routing
    DENY_PROFILE- Activate deny profile
    SNMP=1    - Use snmp control (Default)
    help      - this help
[END]

}


1
