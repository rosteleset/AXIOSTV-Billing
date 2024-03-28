=head1 NAME

  Gathers MACs from equipment

  Params:
    NAS_IPS="IP1,IP2,..." - get MACs only from given IPs
    TRANSACTION=1         - perform all grabber queries to DB in one transaction
    DEL_MAC=1             - delete old MACs from DB
    SNMP_COMMUNITY        - use this SNMP community instead of community configured on NAS
    SEARCH_MAC            - add event when given MAC(s) appears. now is not working

=cut


use strict;
use warnings;
use AXbills::Filters;
use AXbills::Base qw(in_array gen_time check_time);
use Nas;
use Equipment;
use Events;
use Events::API;
use JSON;

our $SNMP_TPL_DIR = "../AXbills/modules/Equipment/snmp_tpl/";

require AXbills::Misc;
require Equipment::Pon_mng;
require Equipment::Grabbers;

our (
  $db,
  %conf,
  $argv,
  $debug,
  $var_dir,
  %lang
);

our Admins $Admin;

$Admin->info($conf{SYSTEM_ADMIN_ID}, { IP => '127.0.0.1' });
my $Equipment = Equipment->new($db, $Admin, \%conf);
my $Events = Events::API->new($db, $Admin, \%conf);
my $Log = Log->new($db, $Admin);

if ($debug > 2) {
  $Log->{PRINT} = 1;
}
else {
  $Log->{LOG_FILE} = $var_dir . '/log/equipment_check.log';
}

if ($argv->{TRANSACTION}) {
  $Equipment->{db}->{db}->begin_work();
}

if ($argv->{DEL_MAC}) {
  $Equipment->mac_log_del({
    DEL_PERIOD => $conf{EQUIPMENT_MAC_EXPIRE},
  });
}
else {
  equipment_check();
}

if ($argv->{TRANSACTION}) {
  $Equipment->{db}->{db}->commit();
}

#**********************************************************
=head2 equipment_check()

=cut
#**********************************************************
sub equipment_check {
  $Log->log_print('LOG_INFO', '', "Equipment check");

  my $search_mac = '';

  if ($argv->{SEARCH_MAC}) {
    $search_mac = $argv->{SEARCH_MAC};
  }

  if ($debug > 7) {
    $Equipment->{debug} = 1;
  }

  if ($argv->{NAS_IPS}) {
    $LIST_PARAMS{NAS_IP} = $argv->{NAS_IPS};
  }

  my $total_nas = 0;
  my $SNMP_COMMUNITY = $argv->{SNMP_COMMUNITY};
  my $equipment_list = $Equipment->_list({
    COLS_NAME                  => 1,
    COLS_UPPER                 => 1,
    PAGE_ROWS                  => 100000,
    SNMP_VERSION               => '_SHOW',
    NAS_ID                     => '_SHOW',
    MODEL_ID                   => '_SHOW',
    MODEL_NAME                 => '_SHOW',
    VENDOR_NAME                => '_SHOW',
    SNMP_TPL                   => '_SHOW',
    TYPE_ID                    => '_SHOW',
    NAS_IP                     => '_SHOW',
    NAS_NAME                   => '_SHOW',
    NAS_MNG_USER               => '_SHOW',
    NAS_MNG_HOST_PORT          => '_SHOW',
    NAS_MNG_PASSWORD           => '_SHOW',
    STATUS                     => '0',
    PORT_SHIFT                 => '_SHOW',
    AUTO_PORT_SHIFT            => '_SHOW',
    FDB_USES_PORT_NUMBER_INDEX => '_SHOW',
    %LIST_PARAMS
  });

  foreach my $equip (@$equipment_list) {
    if (!$equip->{NAS_IP}) {
      if ($debug > 0) {
        print "Equipment not found: $equip->{NAS_ID}\n";
      }
      next;
    }

    my $mac_list = $Equipment->mac_log_list({
      NAS_ID        => $equip->{NAS_ID},
      COLS_NAME     => 1,
      PAGE_ROWS     => 100000,
      MAC           => '_SHOW',
      VLAN          => '_SHOW',
      PORT          => '_SHOW',
      UNIX_DATETIME => '_SHOW',
      UNIX_REM_TIME => '_SHOW',
    });

    my %mac_log_hash = ();

    foreach my $list (@$mac_list) {
      $list->{port} =~ s/\./_/g;
      my $key = $list->{mac} . '_' . $list->{vlan} . '_' . $list->{port};
      $mac_log_hash{ $key }{id} = $list->{id};
      $mac_log_hash{ $key }{datetime} = $list->{unix_datetime} || 0;
      $mac_log_hash{ $key }{rem_time} = $list->{unix_rem_time} || 0;
    }

    if (!$argv->{SNMP_COMMUNITY}) {
      $SNMP_COMMUNITY = ($equip->{NAS_MNG_PASSWORD} || '') . '@' . (($equip->{NAS_MNG_IP_PORT}) ? $equip->{NAS_MNG_IP_PORT} : $equip->{NAS_IP});
    }
    $Log->log_print('LOG_INFO', '', "NAS_ID: $equip->{NAS_ID} NAS_NAME: " . ($equip->{NAS_NAME} || q{}));

    my $fdb_list = get_fdb({
      %$equip,
      SNMP_COMMUNITY => $SNMP_COMMUNITY,
      NAS_INFO       => $equip,
      DEBUG          => $debug,
      BASE_DIR       => $Bin,
      SKIP_TIMEOUT   => 1,
    });

    my @MAC_LOG_ADD = ();
    my @MAC_LOG_CHG = ();
    my $add_mac_count = 0;
    my $chg_mac_count = 0;
    foreach my $mac_dec (keys %$fdb_list) {
      my $mac = $fdb_list->{$mac_dec}{1} || q{};
      if ($debug > 2) {
        print 'MAC: ' . $mac
          # 2 port
          . ' Port: ' . (($fdb_list->{$mac_dec} && $fdb_list->{$mac_dec}{2}) ? $fdb_list->{$mac_dec}{2} : '')
          # 3 status
          # 4 vlan
          . ' Vlan: ' . (($fdb_list->{$mac_dec} && $fdb_list->{$mac_dec}{4}) ? $fdb_list->{$mac_dec}{4} : '')
          # 5 vlan
          . ' Port name: ' . (($fdb_list->{$mac_dec} && $fdb_list->{$mac_dec}{5}) ? $fdb_list->{$mac_dec}{5} : '')
          . "\n";
      }

      if ($mac eq '00:00:00:00:00:00') {
        next;
      }

      my $vlan = $fdb_list->{$mac_dec}{4} || 0;
      if ($vlan =~ /(\d+)\D+/) {
        $vlan = $1;
      }

      if ($vlan > 65000) {
        $vlan = 0;
      }

      my %data = (
        NAS_ID    => $equip->{NAS_ID},
        MAC       => $mac,
        VLAN      => $vlan,
        PORT      => $fdb_list->{$mac_dec}{2} || 0,
        PORT_NAME => $fdb_list->{$mac_dec}{5} || '',
      );

      if(defined $search_mac && defined $data{MAC}) {
        my @macs = split(/,\s?/, $search_mac);
        for my $mac_s (@macs) {
          if ($data{MAC} =~ /$mac_s/) {
            my %parameters = (
              MODULE      => 'Equipment',
              COMMENTS    => "MAC GRABBER:\n"
                . ' MAC: ' . ($data{MAC} || q{})
                . ' NAS_ID:' . ($data{NAS_ID} || q{})
                . ' VLAN:' . ($data{VLAN} || q{})
                . ' PORT:' . ($data{PORT} || q{})
                . ' PORT_NAME:' . ($data{PORT_NAME} || q{}),
              EXTRA       => 'http://axbills.net.ua',
              PRIORITY_ID => 0,
            );
            $Events->add_event(\%parameters);
          }
        }
      }

      my $key = $data{MAC} . '_' . $data{VLAN} . '_' . $data{PORT};
      $key =~ s/\./_/g;
      if (ref $mac_log_hash{ $key } eq 'HASH' && $mac_log_hash{ $key }{id}) {
        $chg_mac_count++;
        push @MAC_LOG_CHG, [
          $data{PORT_NAME},
          $mac_log_hash{ $key }{id}
        ];
        delete $mac_log_hash{ $key };
      }
      else {
        $add_mac_count++;
        push @MAC_LOG_ADD, [
          $data{MAC} || '',
          $data{NAS_ID} || '',
          $data{VLAN} || '',
          $data{PORT} || 0,
          $data{PORT_NAME} || '',
        ];
      }
    }

    my $time;

    if ($#MAC_LOG_ADD > -1) {
      $time = check_time() if ($debug > 2);
      print "Add NEW MACS COUNT:$add_mac_count" if ($debug > 2);
      $Equipment->mac_log_add({ MULTI_QUERY => \@MAC_LOG_ADD });
      print " " . gen_time($time) . "\n" if ($debug > 2);
    }

    $add_mac_count = 0;
    if ($#MAC_LOG_CHG > -1) {
      $time = check_time() if ($debug > 2);
      print "UPDATE MACS COUNT:$chg_mac_count" if ($debug > 2);
      $Equipment->mac_log_change({ MULTI_QUERY => \@MAC_LOG_CHG });
      print " " . gen_time($time) . "\n" if ($debug > 2);
    }

    $chg_mac_count = 0;
    @MAC_LOG_CHG = ();
    foreach my $key (keys %mac_log_hash) {
      if ($mac_log_hash{ $key }{datetime} >= $mac_log_hash{ $key }{rem_time}) {
        $chg_mac_count++;
        push @MAC_LOG_CHG, [
          $mac_log_hash{ $key }{id}
        ];
      }
    }

    if ($#MAC_LOG_CHG > -1) {
      $time = check_time() if ($debug > 2);
      print "UPDATE EXPIRED MACS COUNT:$chg_mac_count" if ($debug > 2);
      $Equipment->mac_log_change({ REM_TIME => 1, MULTI_QUERY => \@MAC_LOG_CHG });
      print " " . gen_time($time) . "\n" if ($debug > 2);
    }

    $chg_mac_count = 0;
    @MAC_LOG_CHG = ();
    $total_nas++;
  }

  print "Total NAS: $total_nas\n\n" if ($debug);

  if ($conf{EQUIPMENT_MAC_PER_PORT}) {
    print "MAC FLOOD:\n\n" if ($debug);

    mac_flood();
  }

  return 1;
}

#**********************************************************
=head2 mac_flood()

=cut
#**********************************************************
sub mac_flood {
  $Equipment->mac_flood_search({
    MIN_COUNT => $conf{EQUIPMENT_MAC_PER_PORT},
    COLS_NAME => 1,
  }) if ($conf{EQUIPMENT_MAC_PER_PORT});

  foreach my $port (@{$Equipment->{list}}) {
    $Events->add_event({
      MODULE      => 'Equipment',
      TITLE       => "MAC Flood",
      COMMENTS    => "MAC Flood  $port->{NAME} ( $port->{NAS_ID} ): $port->{CNT}",
      EXTRA       => "?get_index=equipment_info&full=1&visual=6&search=1&NAS_ID=$port->{NAS_ID}&PORT=" . $port->{PORT},
      PRIORITY_ID => 3
    });
  }

  return 1;
}

1
