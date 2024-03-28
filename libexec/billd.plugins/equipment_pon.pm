=head1 NAME

 billd plugin

 DESCRIBE: PON load onu info

 Arguments:

   TIMEOUT - SNMP timeout
   RELOAD  - Reload onu
   STEP
   SKIP_RRD - Skip gen rrd
   NAS_IDS
   multi
   THREADS - threads number for multi
   CPE_CHECK
   CPE_FILL
   FORCE_FILL
   VLANS - used with CPE_CHECK/CPE_FILL/FORCE_FILL. check or fill abonent's VLAN/SERVER_VLAN
   FILL_CPE_FROM_NAS_AND_PORT
   FILL_SWITCH_PORT_FROM_CID
   SERIAL_SCAN
   SNMP_SERIAL_SCAN_ALL
   QUERY_OIDS - query only this OIDs
   TRANSACTION - perform all grabber queries to DB in one transaction
   ALERT - send event if RX signal is worth or bad
   CLEAN_DELETED - clean all deleted ONU
   DEBUG - debug level

=cut

use strict;
use warnings;
use AXbills::Filters;
use SNMP_Session;
use SNMP_util;
use Equipment;
use Events;
use Events::API;
use Data::Dumper;
use AXbills::Base qw(load_pmodule in_array check_time gen_time);
use FindBin '$Bin';

use threads;
our (
  $argv,
  $debug,
  %conf,
  $Admin,
  $db,
  $OS,
  $var_dir
);

my $running_threads = $argv->{THREADS} || 10;
our $Equipment = Equipment->new($db, $Admin, \%conf);
my $Events = Events::API->new($db, $Admin, \%conf);

do 'AXbills/Misc.pm';

require Equipment::Grabbers;
require Equipment::Pon_mng;
require Equipment::Graph;

our @ONU_ONLINE_STATUSES;

if ($argv->{SERIAL_SCAN}) {
  _scan_mac_serial();
}
elsif ($argv->{SNMP_SERIAL_SCAN_ALL}) {
  _scan_mac_serial_on_all_nas();
}
elsif ($argv->{CPE_FILL} || $argv->{FORCE_FILL} || $argv->{CPE_CHECK}) {
  _save_port_and_nas_to_internet_main();
}
elsif ($argv->{FILL_CPE_FROM_NAS_AND_PORT}) {
  _fill_cpe_from_nas_and_port();
}
elsif ($argv->{FILL_SWITCH_PORT_FROM_CID}) {
  _fill_switch_port_from_cid();
}
elsif ($argv->{CLEAN_DELETED}) {
  _clean_deleted_onu();
}
else {
  _equipment_pon();
}


#**********************************************************
=head2 _equipment_pon($attr)

  Arguments:


  Returns:

=cut
#**********************************************************
sub _equipment_pon {

  if ($debug > 6) {
    $Equipment->{debug} = 1;
  }
  my $equipment_list = $Equipment->_list({
    NAS_ID           => $argv->{NAS_IDS},
    NAS_NAME         => '_SHOW',
    MODEL_ID         => '_SHOW',
    REVISION         => '_SHOW',
    TYPE             => '_SHOW',
    SYSTEM_ID        => '_SHOW',
    NAS_TYPE         => '_SHOW',
    MODEL_NAME       => '_SHOW',
    VENDOR_NAME      => '_SHOW',
    STATUS           => '_SHOW',
    NAS_IP           => '_SHOW',
    NAS_MNG_HOST_PORT=> '_SHOW',
    NAS_MNG_USER     => '_SHOW',
    NAS_MNG_PASSWORD => '_SHOW',
    SNMP_TPL         => '_SHOW',
    LOCATION_ID      => '_SHOW',
    VENDOR_NAME      => '_SHOW',
    SNMP_VERSION     => '_SHOW',
    TYPE_NAME        => $argv->{NAS_IDS} ? '' : '4',
    STATUS           => $argv->{NAS_IDS} ? '_SHOW' : '0',
    PAGE_ROWS        => 100000,
    COLS_NAME        => 1
  });

  if ($Equipment->{TOTAL} < 1) {
    print "Not found any pon equipment\n";
    return 1;
  }

  if ($argv->{RELOAD} && !$argv->{NAS_IDS}) {
    $Equipment->onu_del(0, { ALL => 1 });
    $Equipment->pon_port_del(0, { ALL => 1});
    delete $argv->{RELOAD};
  }

  if ($argv->{multi}) {
    my @threads = ();
    foreach my $line (@$equipment_list) {
      my threads $t = threads->create(\&_equipment_pon_load, $line);
      push @threads, $t;
      $t->detach();

      while (wait_ps(\@threads, $running_threads)) {

      }
    }

    while (wait_ps(\@threads, 0)) {
      print "Wait finish\n" if ($debug > 3);
    }
  }
  else {
    foreach my $line (@$equipment_list) {
      _equipment_pon_load($line);
    }
  }

  return 1;
}

#**********************************************************
=head2 _equipment_pon_load($nas_id)

=cut
#**********************************************************
sub _equipment_pon_load {
  my ($nas_info) = @_;
  my $nas_id = $nas_info->{nas_id};

  my $pon_begin_time = check_time();
  our $SNMP_TPL_DIR = $Bin . "/../AXbills/modules/Equipment/snmp_tpl/";
  #"/usr/axbills/AXbills/modules/Equipment/snmp_tpl/";

  if ($argv->{multi}) {
    #needed for multi, each thread must have its own connection
    $db = AXbills::SQL->connect($conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd}, { CHARSET => ($conf{dbcharset}) ? $conf{dbcharset} : undef }, \%conf);
    if (!$db->{db}) {
      print "Error: SQL connect error\n";
      exit;
    }

    $Admin = Admins->new($db, \%conf);
    $Admin->info($conf{SYSTEM_ADMIN_ID}, { IP => '127.0.0.1' });
    $Equipment = Equipment->new($db, $Admin, \%conf);
  }

  if (!$nas_info->{nas_ip}) {
    print "NAS_ID: $nas_info->{nas_id} deleted\n";
    return 1;
  }
  elsif (!$nas_info->{nas_mng_password}) {
    print "NAS_ID: $nas_info->{nas_id} COMMUNITY not defined\n";
    $nas_info->{nas_mng_password} = 'public';
  }

  my $SNMP_COMMUNITY = "$nas_info->{nas_mng_password}\@" . (($nas_info->{nas_mng_ip_port}) ? $nas_info->{nas_mng_ip_port} : $nas_info->{nas_ip});
  my $onu_counts = 0;

  if ($nas_info->{status} eq 0) {
    $nas_info->{NAME} = $nas_info->{vendor_name};
    my $nas_type = equipment_pon_init({ NAS_INFO => $nas_info });
    if (!$nas_type) {
      return 0;
    }

    if ($argv->{TRANSACTION}) {
      $Equipment->{db}->{db}->begin_work();
    }

    my $onu_list_fn = $nas_type . '_onu_list';

    if (defined(&{$onu_list_fn})) {
      my $olt_ports = ();
      my $port_list = $Equipment->pon_port_list({
        COLS_NAME  => 1,
        COLS_UPPER => 1,
        NAS_ID     => $nas_id
      });

      if ($argv->{RELOAD}) {
        if ($debug > 2) {
          print "Reload ports: $Equipment->{TOTAL}\n";
        }

        my @del_ports = map { $_->{ID} } @$port_list;
        if (@del_ports) {
          my $del_ports_str = join (',', @del_ports);

          if ($debug > 1) {
            print "Delete onu ports: $del_ports_str\n";
          }

          $Equipment->onu_del(0, { PORT_ID => \@del_ports });
          $Equipment->pon_port_del($del_ports_str);
        }

        $Equipment->{TOTAL} = 0;
      }

      if (!$Equipment->{TOTAL}) {
        equipment_pon_get_ports({
          VERSION        => $nas_info->{snmp_version} || 1,
          SNMP_COMMUNITY => $SNMP_COMMUNITY,
          NAS_ID         => $nas_id,
          NAS_TYPE       => $nas_type,
          MODEL_NAME     => $nas_info->{model_name},
          SNMP_TPL       => $nas_info->{snmp_tpl},
          TIMEOUT        => $argv->{TIMEOUT}
        });

        $port_list = $Equipment->pon_port_list({
          COLS_NAME  => 1,
          COLS_UPPER => 1,
          NAS_ID     => $nas_id
        });

        if ($Equipment->{TOTAL} < 1) {
          _generate_new_event("NAS_ID: $nas_id CANT_GET_PORTS");
          return 1;
        }
      }

      foreach my $line (@$port_list) {
        $olt_ports->{$line->{snmp_id}} = $line;
      }

      my $query_oids;
      if (defined $argv->{QUERY_OIDS}) {
        if ($argv->{QUERY_OIDS} eq 'only_required') {
          @$query_oids = ();
        }
        else {
          @$query_oids = split(';', $argv->{QUERY_OIDS});
        }
        push @$query_oids, 'ONU_MAC_SERIAL', 'ONU_STATUS';
      }

      my $onu_snmp_list = &{\&$onu_list_fn}($olt_ports, {
        VERSION        => $nas_info->{snmp_version} || 1,
        SNMP_COMMUNITY => $SNMP_COMMUNITY,
        TIMEOUT        => $argv->{TIMEOUT} || 5,
        SKIP_TIMEOUT   => 1,
        DEBUG          => $debug,
        MODEL_NAME     => $nas_info->{model_name},
        QUERY_OIDS     => $query_oids,
	NAS_ID         => $nas_id,
	NAS_MNG_USER   => $nas_info->{nas_mng_user},
	NAS_MNG_PASSWORD   => $nas_info->{nas_mng_password},
	NAS_MNG_IP_PORT => $nas_info->{nas_mng_ip_port},
        TYPE           => 'dhcp'
      });

      if (! $onu_snmp_list || $#{$onu_snmp_list} < 0) {
        _generate_new_event("NAS_ID: $nas_id NOT_RESPONSE_SNMP ($onu_list_fn)");
        return 1;
      }

      $onu_counts = $#{$onu_snmp_list} + 1;

      my $onu_database_list = $Equipment->onu_list({
        NAS_ID     => $nas_id,
        COLS_NAME  => 1,
        SKIP_DOMAIN=> 1,
        PAGE_ROWS  => 100000,
        ONU_GRAPH  => '_SHOW',
        STATUS     => '_SHOW',
        DELETED    => '_SHOW'
      });

      my $created_onu = ();
      foreach my $onu (@$onu_database_list) {
        $created_onu->{ $onu->{onu_snmp_id} }->{ONU_GRAPH} = $onu->{onu_graph};
        $created_onu->{ $onu->{onu_snmp_id} }->{ID} = $onu->{id};
        $created_onu->{ $onu->{onu_snmp_id} }->{ONU_STATUS} = $onu->{status};
        $created_onu->{ $onu->{onu_snmp_id} }->{DELETED} = $onu->{deleted};
      }

      my $onu_status_fn = $nas_type . '_onu_status';

      my @MULTI_QUERY = ();
      my @ONU_ADD = ();
      my %pon_types_oids = ();
      foreach my $onu (@$onu_snmp_list) {
        if (!$onu->{PORT_ID}) {
          $onu_counts--;
          next;
        }
        my $onu_status_converter = &{\&$onu_status_fn}($onu->{PON_TYPE});
        if ($onu_status_converter) {
          if (defined $onu->{ONU_STATUS}) {
            $onu->{ONU_STATUS} = $onu_status_converter->{$onu->{ONU_STATUS}};
          }
          if (!defined $onu->{ONU_STATUS}) {
            $onu->{ONU_STATUS} = 1000; #NOT_EXPECTED_STATUS
          }
        }

        if ($created_onu->{ $onu->{ONU_SNMP_ID} }) {
          if (! $pon_types_oids{$onu->{PON_TYPE}}) {
            $pon_types_oids{$onu->{PON_TYPE}} = &{\&{$nas_type}}({ TYPE => $onu->{PON_TYPE}, MODEL => ($nas_info->{model_name} || '') });
          }
          my $snmp = $pon_types_oids{$onu->{PON_TYPE}};
          my @onu_graph_types = split(',', $created_onu->{ $onu->{ONU_SNMP_ID} }->{ONU_GRAPH});
          foreach my $graph_type (@onu_graph_types) {
            my @onu_graph_data = ();
            if ($graph_type eq 'SIGNAL' && ($snmp->{ONU_RX_POWER}->{OIDS} || $snmp->{OLT_RX_POWER}->{OIDS})) {
              push @onu_graph_data, { DATA => $onu->{ONU_RX_POWER} || 0, SOURCE => $snmp->{ONU_RX_POWER}->{NAME} || q{}, TYPE => 'GAUGE' };
              push @onu_graph_data, { DATA => $onu->{OLT_RX_POWER} || 0, SOURCE => $snmp->{OLT_RX_POWER}->{NAME} || q{OLT_RX_POWER}, TYPE => 'GAUGE' };
            }
            elsif ($graph_type eq 'TEMPERATURE' && $snmp->{TEMPERATURE}->{OIDS}) {
              push @onu_graph_data, { DATA => $onu->{TEMPERATURE} || 0, SOURCE => $snmp->{TEMPERATURE}->{NAME}, TYPE => 'GAUGE' };
            }
            elsif ($graph_type eq 'SPEED' && ($snmp->{ONU_IN_BYTE}->{OIDS} || $snmp->{ONU_OUT_BYTE}->{OIDS})) {
              push @onu_graph_data, { DATA => $onu->{ONU_IN_BYTE} || 0, SOURCE => $snmp->{ONU_IN_BYTE}->{NAME}, TYPE => 'COUNTER' };
              push @onu_graph_data, { DATA => $onu->{ONU_OUT_BYTE} || 0, SOURCE => $snmp->{ONU_OUT_BYTE}->{NAME}, TYPE => 'COUNTER' };
            }

            if ($#onu_graph_data > -1 && !$argv->{SKIP_RRD}) {
              if ($debug > 3) {
                print "NAS_ID => $nas_id, PORT => $onu->{ONU_SNMP_ID}, TYPE => $graph_type, DATA => " . join(',', @onu_graph_data) . " STEP => ". ($argv->{STEP} || '300'). "\n";
              }
              eval {
                add_graph({ NAS_ID => $nas_id, PORT => $onu->{ONU_SNMP_ID}, TYPE => $graph_type, DATA => \@onu_graph_data, STEP => $argv->{STEP} || '300' });
              };
              if ( $@ ){
                print "Failed to update RRD database:\n";
                print $@;
              }
            }
          }

          push @MULTI_QUERY, [
            $onu->{OLT_RX_POWER} || '',
            $onu->{ONU_RX_POWER} || '',
            $onu->{ONU_TX_POWER} || '',
            $onu->{ONU_STATUS},
            $onu->{ONU_IN_BYTE} || 0,
            $onu->{ONU_OUT_BYTE} || 0,
            $onu->{ONU_DHCP_PORT},
            $onu->{PORT_ID},
            $onu->{ONU_MAC_SERIAL},
            $onu->{VLAN} || 0,
            $onu->{ONU_DESC} || '',
            $onu->{ONU_ID},
            $onu->{LINE_PROFILE} || 'ONU',
            $onu->{SRV_PROFILE} || 'ALL',
            '0',
            $created_onu->{ $onu->{ONU_SNMP_ID} }->{ID}
          ];

          delete $created_onu->{ $onu->{ONU_SNMP_ID} };
        }
        else {
          push @ONU_ADD, [
            $onu->{OLT_RX_POWER} || '',
            $onu->{ONU_RX_POWER} || '',
            $onu->{ONU_TX_POWER} || '',
            $onu->{ONU_STATUS} || 0,
            $onu->{ONU_IN_BYTE} || 0,
            $onu->{ONU_OUT_BYTE} || 0,
            $onu->{ONU_DHCP_PORT} || '',
            $onu->{PORT_ID} || '',
            $onu->{ONU_MAC_SERIAL} || '',
            $onu->{VLAN} || 0,
            $onu->{ONU_DESC} || '',
            $onu->{ONU_ID},
            $onu->{ONU_SNMP_ID},
            $onu->{LINE_PROFILE} || 'ONU',
            $onu->{SRV_PROFILE} || 'ALL',
          ];
        }
        if( in_array( 'Events', \@MODULES ) && $argv->{ALERT} ){
          pon_alert($onu->{ONU_RX_POWER});
        }
      }

      my $time=0;

      foreach my $snmp_id (keys %{$created_onu}) {
        if (!$created_onu->{ $snmp_id }->{DELETED}) {
          $time = check_time() if ($debug > 2);
          $Equipment->onu_change({
            ID         => $created_onu->{ $snmp_id }->{ID},
            DELETED    => 1
          });
          print "UPDATE EXPIRED ONU." if ($debug > 2);
          print " " . gen_time($time) . "\n" if ($debug > 2);
        }
      }

      if ($#ONU_ADD > -1) {
        $time = check_time() if ($debug > 2);
        print "ADD ONU." if ($debug > 2);
        $Equipment->onu_add({ MULTI_QUERY => \@ONU_ADD });
        print " " . gen_time($time) . "\n" if ($debug > 2);
        my $serials_with_descriptions = join(', ', map { $_->[8] . " ($_->[10])" } @ONU_ADD);

        if ($argv->{multi}) {
          $Events = Events::API->new($db, $Admin, \%conf);
        }
        $Events->add_event({
          MODULE      => 'Equipment',
          TITLE       => "Add new ONU",
          COMMENTS    => "Add " . ($#ONU_ADD + 1) . " new onu on NAS_ID: $nas_id (" . ($nas_info->{NAME} || q{}) . ") Serials (descriptions): $serials_with_descriptions",
          PRIORITY_ID => 3
        });

      }
      if ($#MULTI_QUERY > -1) {
        $time = check_time() if ($debug > 2);
        print "UPDATE ONU info." if ($debug > 2);
        $Equipment->onu_change({ MULTI_QUERY => \@MULTI_QUERY });
        print " " . gen_time($time) . "\n" if ($debug > 2);
      }
    }

    if ($argv->{TRANSACTION}) {
      $Equipment->{db}->{db}->commit();
    }
  }

  if ($debug) {
    print "NAS_TYPE : " . ($nas_info->{NAME} || q{}) . " MODEL_NAME: " . ($nas_info->{model_name} || q{}) . ", NAS_IP: $nas_info->{nas_ip}"
      . " NAS_ID: $nas_id, ONU: $onu_counts " . gen_time($pon_begin_time) . "\n";
  }

  return 1;
}

#**********************************************************
=head2 wait_ps($threads, $max_threads) - Wait until ps end for next thread

  Arguments:
    $threads     - thread id arrays
    $max_threads - Max thread running

  Return:
     1 - wait
     0 - run


=cut
#**********************************************************
sub wait_ps {
  my ($threads, $max_threads) = @_;

  my $running_ps = 0;

  foreach my threads $th (@$threads) {
    my $running = $th->is_running();
    if ($running) {
      $running_ps++
    }
    #else {
    #  $running_ps--;
    #}
  }

  if ($running_ps > $max_threads) {
    print "Sleep: Running: $running_ps Total: $#{$threads}\n" if ($debug > 3);
    sleep 1;
    #run
    return 1;
  }

  #Finish
  return 0;
}

#**********************************************************
=head2 pon_alert($attr)

=cut
#**********************************************************
sub pon_alert {
  my ($parameter) = @_;

  if (!$parameter) {
    return 0;
  }

  my %parameters = (
    # Name for module
    MODULE      => 'Equipment',
    # Text
    COMMENTS    => 'PON ALERT: ' . $parameter,
    # Link to see external info
    EXTRA       => '',
    # 1..5 Bigger is more important
    PRIORITY_ID => 2,
  );

  if (!$parameter || $parameter == 65535) {
    return 0;
  }
  elsif ($parameter > 0) {
    return 0;
  }
  elsif ($parameter > -8 || $parameter < -30) {
    #$parameter = $html->color_mark($parameter, 'text-red' );
  }
  elsif ($parameter > -10 || $parameter < -27) {
    $parameters{PRIORITY_ID} = 1;
  }
  else {
    return 0;
  }

  $Events->events_add(\%parameters);

  return 1;
}

#**********************************************************
=head2 _scan_mac_serial()

=cut
#**********************************************************
sub _scan_mac_serial {

  my $equipment_list = $Equipment->_list({
    COLS_NAME  => 1,
    PAGE_ROWS  => 100000,
    STATUS     => '0',
    TYPE_NAME  => '4',
    MAC_SERIAL => "_SHOW",
    ID         => "_SHOW",
  });

  my %mac_nas_ids = ();
  foreach my $pon (@$equipment_list) {
    my $onu_list = $Equipment->onu_list({
      COLS_NAME  => 1,
      PAGE_ROWS  => 100000,
      GROUP_BY   => 'onu.id',
      # STATUS     => '0',
      # TYPE_NAME  => '4',
      MAC_SERIAL => "_SHOW",
      NAS_ID     => $pon->{nas_id},
    });

    foreach my $onu (@$onu_list) {
      if ($onu->{mac_serial}) {
        push @{ $mac_nas_ids{$onu->{mac_serial}} }, $onu->{nas_id};
      }
    }
  }

  foreach my $mac (keys %mac_nas_ids) {
    if (@{$mac_nas_ids{$mac}} > 1) {
      my $nas_ids = join (', ', @{$mac_nas_ids{$mac}});
      my $message = "mac_serial " . $mac . " duplicated on NAS ids " . $nas_ids . "\n";
      _generate_new_event($message);
    }
  }

  return 1;
}

#**********************************************************
=head2 _generate_new_event($comments)

  Arguments:
    $comments - text of message to show

  Returns:

=cut
#**********************************************************
sub _generate_new_event {
  my ($comments) = @_;

  #  print "EVENT: $name, $comments \n";
  _log('LOG_CRIT', $comments);

  $Events->add_event({
    MODULE      => "Equipment",
    PRIORITY_ID => 5,
    STATE_ID    => 1,
    TITLE       => '_{WARNING}_',
    COMMENTS    => $comments,
  });

  return 1;
}

#**********************************************************
=head2 _scan_mac_serial_on_all_nas($comments)

  Arguments:

  Returns:

=cut
#**********************************************************
sub _scan_mac_serial_on_all_nas {

  my $Equipment_list = $Equipment->_list({
    NAS_ID           => '_SHOW',
    NAS_NAME         => '_SHOW',
    MODEL_ID         => '_SHOW',
    REVISION         => '_SHOW',
    TYPE             => '_SHOW',
    SYSTEM_ID        => '_SHOW',
    NAS_TYPE         => '_SHOW',
    MODEL_NAME       => '_SHOW',
    VENDOR_NAME      => '_SHOW',
    STATUS           => '_SHOW',
    NAS_IP           => '_SHOW',
    NAS_MNG_HOST_PORT=> '_SHOW',
    NAS_MNG_USER     => '_SHOW',
    NAS_MNG_PASSWORD => '_SHOW',
    SNMP_TPL         => '_SHOW',
    LOCATION_ID      => '_SHOW',
    VENDOR_NAME      => '_SHOW',
    SNMP_VERSION     => '_SHOW',
    TYPE_NAME        => '4',
    COLS_NAME        => 1,
    COLS_UPPER       => 1,
  });

  my %Nas_macs = ();

  foreach my $nas (@$Equipment_list) {
    my $port_type = $Equipment->pon_port_list({
      NAS_ID    => $nas->{NAS_ID},
      COLS_NAME => 1,
    });

    my $oids = '';
    my $nas_type = equipment_pon_init({ VENDOR_NAME => $nas->{VENDOR_NAME} });
    if ($nas_type eq "_zte") {
      $oids = _zte({ TYPE => $port_type->[0]{pon_type} });
    }
    elsif ($nas_type eq "_eltex") {
      $oids = _eltex({ TYPE => $port_type->[0]{pon_type} });
    }
    elsif ($nas_type eq "_bdcom") {
      $oids = _bdcom({ TYPE => $port_type->[0]{pon_type} });
    }
    elsif ($nas_type eq "_huawei") {
      $oids = _huawei({ TYPE => $port_type->[0]{pon_type} });
    }
    elsif ($nas_type eq "_vsolution") {
      $oids = _vsolution({ TYPE => $port_type->[0]{pon_type} });
    }
    elsif ($nas_type eq "_cdata") {
      $oids = _cdata({ TYPE => $port_type->[0]{pon_type} });
    }
    elsif ($nas_type eq "_smartfiber") {
      $oids = _smartfiber({ TYPE => $port_type->[0]{pon_type} });
    }
    else {
      next;
    }

    my $SNMP_COMMUNITY = $nas->{NAS_MNG_PASSWORD} . '@' . $nas->{NAS_MNG_IP_PORT};

    my $mac_serials = snmp_get({
      %$nas,
      SNMP_COMMUNITY => $SNMP_COMMUNITY,
      WALK           => 1,
      OID            => $oids->{ONU_MAC_SERIAL}{OIDS},
      VERSION        => 2,
      TIMEOUT        => 2
    });

    foreach my $mac (@$mac_serials) {
      if ($Nas_macs{$mac}) {
        my $message = "You have mac_serial duplicate in $Nas_macs{$mac} and $nas->{NAS_ID} $nas->{NAS_NAME} ($mac)\n";
        _generate_new_event($message);
      }
      else {
        $Nas_macs{$mac} = $nas->{NAS_ID} . " " . $nas->{NAS_NAME};
      }
    }
  }

  return 0;
}

#**********************************************************
=head2 _save_port_and_nas_to_internet_main() - Fill NAS and PORT BY CPE MAC

=cut
#**********************************************************
sub _save_port_and_nas_to_internet_main {
  require Internet;
  Internet->import();
  my $Internet = Internet->new($db, $Admin, \%conf);

  if($debug > 6) {
    $Equipment->{debug}=1;
  }
  my $onu_list = $Equipment->onu_and_internet_cpe_list({NAS_IDS => $argv->{NAS_IDS}, DELETED => 0});

  my $check_mode = $argv->{CPE_CHECK} && !$argv->{CPE_FILL} && !$argv->{FORCE_FILL};

  my %onus_by_uid = ();
  my %attached_onu_by_uid = ();

  foreach my $onu (@$onu_list) {
    next if (!$onu->{onu_nas});

    push @{$onus_by_uid{$onu->{uid}}}, $onu;

    if ($onu->{user_nas} eq $onu->{onu_nas} && $onu->{user_port} eq $onu->{onu_port}) {
      $attached_onu_by_uid{$onu->{uid}} = $onu;
    }
  }

  foreach my $uid (keys %onus_by_uid) {
    my @uid_onu_list = @{$onus_by_uid{$uid}};
    my $onu_to_set = $uid_onu_list[0];

    if ($check_mode || $argv->{FORCE_FILL} || !$onu_to_set->{user_port} || !$onu_to_set->{user_nas}) {
      if (scalar @uid_onu_list > 1) {
        print "WARNING: there are more than one ONU with MAC $onu_to_set->{cpe}\n";

        my @online_uid_onu_list = grep { in_array($_->{onu_status}, \@ONU_ONLINE_STATUSES) } @uid_onu_list;
        if (scalar @online_uid_onu_list == 1) {
          $onu_to_set = $online_uid_onu_list[0];
          if ($onu_to_set->{user_nas} ne $onu_to_set->{onu_nas} || $onu_to_set->{user_port} ne $onu_to_set->{onu_port}) {
            print "Changing user's ONU to online one\n" if (!$check_mode);
          }
          else {
            print "Not changing user's ONU (User:$onu_to_set->{uid})\n" if (!$check_mode);
          }
        }
        else {
          print "Not changing user's ONU (User:$onu_to_set->{uid})\n" if (!$check_mode);
          $onu_to_set = undef;
        }
      }

      if ($onu_to_set && ($onu_to_set->{user_nas} ne $onu_to_set->{onu_nas} || $onu_to_set->{user_port} ne $onu_to_set->{onu_port})) {
        if ($check_mode) {
          if ($onu_to_set->{onu_port} ne $onu_to_set->{user_port}) {
            print "User:$onu_to_set->{uid},  port does not match. user_port:'$onu_to_set->{user_port}'/onu_port:'$onu_to_set->{onu_port}'\n";
          }
          if ($onu_to_set->{onu_nas} ne $onu_to_set->{user_nas}) {
            print "User:$onu_to_set->{uid},  nas does not match. user_nas:'$onu_to_set->{user_nas}'/onu_nas:'$onu_to_set->{onu_nas}'\n";
          }
        }
        else {
          $Internet->user_change({
            UID    => $onu_to_set->{uid},
            ID     => $onu_to_set->{service_id},
            NAS_ID => $onu_to_set->{onu_nas},
            PORT   => $onu_to_set->{onu_port},
          });
          print "User:$onu_to_set->{uid} add port ($onu_to_set->{onu_port}) and nas ($onu_to_set->{onu_nas})\n";
        }
      }

      if($onu_to_set->{uid}) {
        $attached_onu_by_uid{$onu_to_set->{uid}} = $onu_to_set;
      }
      else {
        _log('LOG_ERR', "ERROR: UID not defined for '$onu_to_set'");
      }
    }

    if ($argv->{VLANS}) {
      my $attached_onu = $attached_onu_by_uid{$uid};
      next if (!$attached_onu);
      if ($attached_onu->{onu_status} && $attached_onu->{onu_status} == 4) {
        next;
      }
      my $pon_port_vlan = $attached_onu->{pon_port_vlan} || 0;
      #$attached_onu->{user_server_vlan} ||= $pon_port_vlan || 0;
      $attached_onu->{onu_server_vlan} ||= $pon_port_vlan || 0;

      if ($check_mode) {
        if ($attached_onu->{onu_vlan} != $attached_onu->{user_vlan}) {
          print "User:$uid,  vlan does not match. user_vlan:'$attached_onu->{user_vlan}'/onu_vlan:'$attached_onu->{onu_vlan}'\n";
        }
        if ($attached_onu->{onu_server_vlan} != $attached_onu->{user_server_vlan}) {
          print "User:$attached_onu->{uid},  server_vlan does not match. user_server_vlan:'$attached_onu->{user_server_vlan}'/onu_server_vlan:'$attached_onu->{onu_server_vlan}'\n";
        }
      }
      elsif (($attached_onu->{onu_vlan} || 0) != ($attached_onu->{user_vlan} || 0)
         || ($attached_onu->{onu_server_vlan} || 0) != ($attached_onu->{user_server_vlan} || 0)) {

 #         print "      elsif (($attached_onu->{onu_vlan} != ($attached_onu->{user_vlan} || q{})
 #          || $attached_onu->{onu_server_vlan} != $attached_onu->{user_server_vlan})) {
 # ";
        my $vlan_to_set = $attached_onu->{user_vlan};
        my $server_vlan_to_set = $attached_onu->{user_server_vlan};

        if (($attached_onu->{onu_vlan} && $attached_onu->{onu_vlan} != ($attached_onu->{user_vlan} || 0))
          && (!$attached_onu->{user_vlan} || $argv->{FORCE_FILL})) {
          $vlan_to_set = $attached_onu->{onu_vlan};
          print "User:$uid add vlan ($attached_onu->{onu_vlan})\n"
        }

        if ($attached_onu->{onu_server_vlan} != $attached_onu->{user_server_vlan}
            && (!$attached_onu->{user_server_vlan} || $argv->{FORCE_FILL})) {
          $server_vlan_to_set = $attached_onu->{onu_server_vlan};
          print "User:$uid MAC/SERIAL: $attached_onu->{cpe} add server_vlan ($attached_onu->{onu_server_vlan})\n"
        }

        $Internet->user_change({
          UID         => $attached_onu->{uid},
          ID          => $attached_onu->{service_id},
          VLAN        => $vlan_to_set,
          SERVER_VLAN => $server_vlan_to_set
        });
      }
    }
  }
  return 1;
}

#**********************************************************
=head2 _fill_cpe_from_nas_and_port() - Find ONU MAC from customer's NAS and port and fill CPE MAC with it if empty

=cut
#**********************************************************
sub _fill_cpe_from_nas_and_port {
  require Internet;
  my $Internet = Internet->new($db, $Admin, \%conf);

  my $internet_list = $Internet->user_list({
    NAS_ID    => ($argv->{NAS_IDS}) ? $argv->{NAS_IDS} : '_SHOW',
    PORT      => '_SHOW',
    CPE_MAC   => '_SHOW',
    PAGE_ROWS => 1000000000,
    COLS_NAME => 1
  });

  my $onu_list = $Equipment->onu_list({
    NAS_ID     => ($argv->{NAS_IDS}) ? $argv->{NAS_IDS} : '_SHOW',
    MAC_SERIAL => '_SHOW',
    COLS_NAME  => 1
  });

  my %macs_by_nas_port = ();

  foreach my $line (@$onu_list) {
    $macs_by_nas_port{$line->{nas_id}}{$line->{dhcp_port}} = $line->{mac_serial};
  }

  foreach my $line (@$internet_list) {
    if ($line->{cpe_mac} || !$line->{nas_id} || !$line->{port}) {
      next;
    }

    if ($macs_by_nas_port{$line->{nas_id}} && $macs_by_nas_port{$line->{nas_id}}{$line->{port}}) {
      $Internet->user_change({
        UID     => $line->{uid},
        ID      => $line->{id},
        CPE_MAC => $macs_by_nas_port{$line->{nas_id}}{$line->{port}}
      });
      print "UID $line->{uid}: filled CPE MAC $macs_by_nas_port{$line->{nas_id}}{$line->{port}}\n";
    }
  }

  return 1;
}

#**********************************************************
=head2 _fill_switch_port_from_cid () - Find CID and fill out port by uid

=cut
#**********************************************************
sub _fill_switch_port_from_cid {
  require Internet;
  Internet->import();
  require Internet::Sessions;
  Internet::Sessions->import();

  my $Internet = Internet->new($db, $Admin, \%conf);
  my $Sessions = Internet::Sessions->new($db, $Admin, \%conf);

  my $session_list = $Sessions->online({
    NAS_ID             => ($argv->{NAS_IDS}) ? $argv->{NAS_IDS} : '_SHOW',
    ALL                => 1,
    UID                => '_SHOW',
    CID                => '_SHOW',
    SERVICE_ID         => '_SHOW',
    PORT               => '_SHOW', # internet_main.port
    PAGE_ROWS          => 1000000000,
    COLS_NAME          => 1
  });


  foreach my $line (@$session_list) {
    next if (!$line->{cid});
    if ($line->{cid} && !$line->{port}) {

      $Internet->user_change({
        UID     => $line->{uid},
        ID      => $line->{service_id},
        PORT    => $line->{cid}
      });

      print "SERVICE_ID: $line->{service_id}, UID: $line->{uid}, Port: $line->{cid}\n";
    }
  }

  return 1;
}


#**********************************************************
=head2 _clean_deleted_onu() - clean deleted onu from database

=cut
#**********************************************************
sub _clean_deleted_onu {

  if ($debug > 6) {
    $Equipment->{debug} = 1;
  }

  my $equipment_list = $Equipment->onu_list({
    DELETED         => 1,
    PAGE_ROWS       => 10000,
    COLS_NAME       => 1
  });

  if ($Equipment->{TOTAL} < 1) {
    print "Not found any PON ONU equipment\n";
    return 1;
  }
  my $onu_list_id = '';
  my $total_deleted = 0;

  foreach my $deleted_onu(@$equipment_list){
    $onu_list_id .= "$deleted_onu->{id},",
    $total_deleted ++;
  }

  if ($onu_list_id){
    $Equipment->onu_del($onu_list_id);
    if ($debug > 0) {
      print "Total ONU deleted: $total_deleted\n";
    }
  }

  return 1;
}

1
