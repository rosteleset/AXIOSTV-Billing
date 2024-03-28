=head1 Cdata

  C-data
  MODEL:
    epon
      FD1104SN
      FD1216S

    gpon

    testing
      FD1208S

  DATE: 04.07.2019
  UPDATE: 21.11.2019

=cut

use strict;
use warnings;
use AXbills::Base qw(in_array);
use AXbills::Filters qw(bin2mac);

our (
  %lang,
  %conf,
  %FORM
);

#**********************************************************
=head2 _cdata_get_ports($attr) - Get OLT slots and connect ONU

  Arguments:
    $attr

  Results:
    $ports_info_hash_ref

=cut
#**********************************************************
sub _cdata_get_ports {
  my ($attr) = @_;
  #my $res = ();

  my $ports_info = equipment_test({
    %{$attr},
    TIMEOUT   => 5,
    VERSION   => 2,
    PORT_INFO => 'PORT_NAME,PORT_TYPE,PORT_DESCR,PORT_STATUS,PORT_SPEED,PORT_ALIAS,TRAFFIC,PORT_INFO'
  });

  foreach my $key (sort keys %{$ports_info}) {

    if ($ports_info->{$key}{PORT_TYPE} && $ports_info->{$key}{PORT_TYPE} =~ /^1$/ && $ports_info->{$key}{PORT_NAME}
      && $ports_info->{$key}{PORT_NAME} =~ /^(.PON).+PON-(\d+)/) {
      my $type = lc($1);
      $ports_info->{$key}{PON_TYPE} = $type;
      $ports_info->{$key}{SNMP_ID} = $key;
      $ports_info->{$key}{BRANCH_DESC} = $ports_info->{$key}{PORT_NAME};
      $ports_info->{$key}{BRANCH} = $2;
      $ports_info->{$key}{PORT_ALIAS} = $ports_info->{$key}{PORT_NAME};
      $ports_info->{$key}{onu_count} = (snmp_get({ %{$attr},
        OID => "1.3.6.1.4.1.34592.1.3.3.1.1.6.1.$2",
      }) || 0);
    }
    elsif ($ports_info->{$key}{PORT_TYPE} && $ports_info->{$key}{PORT_TYPE} =~ /^1$/ && $ports_info->{$key}{PORT_DESCR}
      && $ports_info->{$key}{PORT_DESCR} =~ /^(.PON).+PON-(\d+)/) {
      my $type = lc($1);
      $ports_info->{$key}{PON_TYPE} = $type;
      $ports_info->{$key}{SNMP_ID} = $key;
      $ports_info->{$key}{BRANCH_DESC} = $ports_info->{$key}{PORT_DESCR};
      $ports_info->{$key}{BRANCH} = $2;
      $ports_info->{$key}{PORT_ALIAS} = $ports_info->{$key}{PORT_DESCR};
      $ports_info->{$key}{onu_count} = (snmp_get({ %{$attr},
        OID => "1.3.6.1.4.1.34592.1.3.3.1.1.6.1.$2",
      }) || 0);
    }
    elsif (
      $ports_info->{$key}{PORT_TYPE} &&
      $ports_info->{$key}{PORT_TYPE} == 117 &&
      $ports_info->{$key}{PORT_DESCR} &&
      $ports_info->{$key}{PORT_DESCR} =~ /^(pon)(.+)/) {
      my $type = lc($1);
      # my $branch = $2;
      my $bin_index =  dec2bin($key);
      my (undef, $port_num, undef) = $bin_index =~ /(\d{9})(\d{8})(\d{8})/;
      my $port_snmp = bin2dec($port_num);
      my $port = $port_snmp - 2 - 8;

      if ($port < 10){
        $port = "0".$port;
      }
      $ports_info->{$key}{PON_TYPE} = "e" . $type;
      $ports_info->{$key}{SNMP_ID} = $key;
      $ports_info->{$key}{BRANCH} = $port;
      $ports_info->{$key}{BRANCH_DESC} = $ports_info->{$key}{PORT_DESCR};
      $ports_info->{$key}{PORT_ALIAS} = $ports_info->{$key}{PORT_DESCR};
      $ports_info->{$key}{ONU_COUNT} = (snmp_get({ %{$attr},
        OID => "1.3.6.1.4.1.17409.2.3.3.1.1.8.1.0." . ($port_snmp),
      }) || 0);
      $ports_info->{$key}{onu_count} = $ports_info->{$key}{ONU_COUNT};
    }
    else {
      delete($ports_info->{$key});
    }
  }

  return $ports_info;
}

#**********************************************************
=head2 _cdata_onu_list($port_list, $attr)

  Arguments:
    $port_list  - OLT ports list
    $attr
      COLS       - ARRAY refs
      INFO_OIDS  - Hash refs
      NAS_ID
      TIMEOUT

  Returns:
    $onu_list [arra_of_hash]

    Example:
      oid result - 2.1:6
      port_descr - '5:EPON System, PON-1'
      port_ids - '1' => '645'

=cut
#**********************************************************
sub _cdata_onu_list {
  my ($port_list, $attr) = @_;

  if ($attr->{MODEL_NAME} && $attr->{MODEL_NAME} eq 'FD1216S') {
   return _cdata2_onu_list($port_list, $attr);
  }

  my $debug = $attr->{DEBUG} || 0;
  my @onu_list = ();
  my %pon_types = ();
  my %port_ids = ();

  my $snmp_info = equipment_test({
    %{$attr},
    TIMEOUT  => 5,
    VERSION  => 2,
    TEST_OID => 'PORTS,UPTIME'
  });

  if (!$snmp_info->{UPTIME}) {
    print "$attr->{SNMP_COMMUNITY} Not response\n";
    return [];
  }

  if ($port_list) {
    foreach my $snmp_id (keys %{$port_list}) {
      $pon_types{ $port_list->{$snmp_id}{PON_TYPE} } = 1;
      $port_ids{$port_list->{$snmp_id}{BRANCH}} = $port_list->{$snmp_id}{ID};
    }
  }
  else {
    %pon_types = (epon => 1, gpon => 1);
  }

  my $ports_descr = snmp_get({
    %$attr,
    WALK    => 1,
    OID     => '.1.3.6.1.2.1.2.2.1.2',
    VERSION => 2,
    TIMEOUT => $attr->{TIMEOUT} || 2
  });

  if (!$ports_descr || $#{$ports_descr} < 1) {
    return [];
  }

  foreach my $pon_type (keys %pon_types) {
    my $snmp = _cdata({ TYPE => $pon_type });

    if (!$snmp->{ONU_STATUS}->{OIDS}) {
      print "$pon_type: no oids\n" if ($debug > 0);
      next;
    }

    my %onu_snmp_info = ();
    foreach my $oid_name (sort keys %{$snmp}) {
      next if ($oid_name eq 'main_onu_info' || $oid_name eq 'reset' );
      if ($snmp->{$oid_name}->{OIDS}) {
        my $oid = $snmp->{$oid_name}->{OIDS};
        my $timeout = $snmp->{$oid_name}->{TIMEOUT};
        print ">> $oid\n" if ($debug > 3);
        my $result = snmp_get({
          %{$attr},
          OID     => $oid,
          VERSION => 2,
          WALK    => 1,
          SILENT  => 1,
          TIMEOUT => $timeout || 2
        });

        foreach my $line (@$result) {
          next if (!$line);

          my (undef, $value) = split(/:/, $line, 2);
          my ($port_index, $onu_index) = $line =~ /(\d+)\.(\d+)/;
          my $function = $snmp->{$oid_name}->{PARSER};

          if (!defined($value)) {
            print ">> $line\n";
          }

          if ($function && defined(&{$function})) {
            ($value) = &{\&$function}($value);
          }

          $onu_snmp_info{$port_index}{$onu_index}{$oid_name} = $value;
        }
      }
    }
#    For checking snmp result
    #    AXbills::Base::_bp('onu_snmp_info', \%onu_snmp_info, { TO_CONSOLE => 1 });

    my %onu_info = ();
    foreach my $key (sort keys %port_ids) {
      next if (!$key);

      foreach my $onu_numb (sort keys %{$onu_snmp_info{$key}}) {
        next if (!$onu_numb);

        $onu_info{ONU_ID} = $onu_numb;
        $onu_info{ONU_SNMP_ID} = "$key.$onu_numb";
        $onu_info{PORT_ID} = $port_ids{$key};
        $onu_info{PON_TYPE} = $pon_type;
        $onu_info{ONU_DHCP_PORT} = "$key/$onu_numb";
        foreach my $oid_name (keys %{$onu_snmp_info{$key}{$onu_numb}}) {
          next if (!$oid_name);
          $onu_info{$oid_name} = $onu_snmp_info{$key}{$onu_numb}{$oid_name} || q{};
        }
        push @onu_list, { %onu_info };
      }
    }
  }

  return \@onu_list;
}

#**********************************************************
=head2 _cdata($attr) - for FD1104SN

  Parsms:

=cut
#**********************************************************
sub _cdata {
  my ($attr) = @_;

  if ($attr->{MODEL} && $attr->{MODEL} eq 'FD1216S') {
    return _cdata2($attr);
  }

  my %snmp = (
    epon => {
      'ONU_MAC_SERIAL' => {
        NAME   => 'Mac/Serial',
        OIDS   => '1.3.6.1.4.1.34592.1.3.4.1.1.7.1',
        PARSER => 'bin2mac'
      },
      'ONU_STATUS'     => {
        NAME   => 'STATUS',
        OIDS   => '1.3.6.1.4.1.34592.1.3.4.1.1.11.1',
        PARSER => ''
      },
      'ONU_TX_POWER'   => {
        NAME   => 'ONU_TX_POWER',
        OIDS   => '1.3.6.1.4.1.34592.1.3.4.1.1.37.1',
        PARSER => '_cdata_convert_power'
      },
      'ONU_RX_POWER'   => {
        NAME   => 'ONU_RX_POWER',
        OIDS   => '1.3.6.1.4.1.34592.1.3.4.1.1.36.1',
        PARSER => '_cdata_convert_power'
      },
      'ONU_DESC'       => {
        NAME   => 'ONU_DESC',
        OIDS   => '1.3.6.1.4.1.34592.1.3.4.1.1.4.1',
        PARSER => ''
      },
      #        'ONU_IN_BYTE'    => {
      #          NAME   => '',
      #          OIDS   => '',
      #          PARSER => ''
      #        },
      #        'ONU_OUT_BYTE'   => {
      #          NAME   => '',
      #          OIDS   => '',
      #          PARSER => ''
      #        },
      'TEMPERATURE'    => {
        NAME   => 'TEMPERATURE',
        OIDS   => '1.3.6.1.4.1.34592.1.3.4.1.1.40.1',
        PARSER => '_cdata_convert_temperature'
      },
      #        'reset'          => {
      #          NAME        => '',
      #          OIDS        => '',
      #          RESET_VALUE => 0,
      #          PARSER      => ''
      #        },
      #        'VLAN'           => {
      #          NAME   => '',
      #          OIDS   => '',
      #          PARSER => '',
      #          WALK   => 1
      #        },
      'DISTANCE'       => {
        NAME   => 'DISTANCE',
        OIDS   => '1.3.6.1.4.1.34592.1.3.4.1.1.13.1',
        PARSER => '_cdata_convert_distance'
      },
      main_onu_info    => {
        #          'HARD_VERSION'     => {
        #            NAME   => '',
        #            OIDS   => '',
        #          PARSER => ''
        #      },
        #        'FIRMWARE'         => {
        #          NAME   => '',
        #          OIDS   => '',
        #          PARSER => ''
        #      },
        'VOLTAGE' => {
          NAME   => 'VOLTAGE',
          OIDS   => '1.3.6.1.4.1.34592.1.3.4.1.1.37.1',
          PARSER => '_cdata_convert_voltage'
        }, #voltage = voltage * 0.0001;
        'MAC'     => {
          NAME   => 'MAC',
          OIDS   => '1.3.6.1.4.1.34592.1.3.4.1.1.7.1.1',
          PARSER => 'bin2mac',
          WALK   => 1
        },
        #        'VLAN'             => {
        #          NAME   => '',
        #          OIDS   => '',
        #          PARSER => '',
        #          WALK   => 1
        #        },
        #        'ONU_PORTS_STATUS' => {
        #          NAME   => '',
        #          OIDS   => '',
        #          PARSER => '',
        #          WALK   => 1
        #        }
      }
    },
    gpon => {
    },
    #      unregister => {
    #
    #      }
  );

  if ($attr->{TYPE}) {
    return $snmp{$attr->{TYPE}};
  }

  return \%snmp;
}

#**********************************************************
=head2 _cdata_onu_status()

=cut
#**********************************************************
sub _cdata_onu_status {

  my %status = (
#    0 => 'Authenticated:text-green',
    1 => 'Online:text-green',
    2 => 'Offline:text-red',
    3 => 'Online:text-green',
  );
  return \%status;
}

#**********************************************************
=head2 _cdata_convert_temperature();

=cut
#**********************************************************
sub _cdata_convert_temperature {
  my ($temperature) = @_;

  $temperature //= 0;
  $temperature = ($temperature / 256);
  $temperature = sprintf("%.2f", $temperature);

  return $temperature;
}

#**********************************************************
=head2 _cdata_convert_power();

=cut
#**********************************************************
sub _cdata_convert_power {
  my ($power) = @_;

  return 0 if (!$power);

  $power = $power * 0.0001;
  if (-65535 == $power) {
    $power = '';
  }
  else {
    $power = 10 * (log($power/1)/(log(10)));
    $power = sprintf("%.2f", $power);
  }

  return $power;
}
#**********************************************************
=head2 _cdata_convert_power();

=cut
#**********************************************************
sub _cdata2_convert_power {
  my ($power) = @_;

  return 0 if (!$power);

  $power = $power * 0.01;
  if (-65535 == $power) {
    $power = '';
  }
  else {
    $power = sprintf("%.2f", $power);
  }

  return $power;
}
#**********************************************************
=head2 _cdata_convert_distance();

=cut
#**********************************************************
sub _cdata_convert_distance {
  my ($distance) = @_;

  $distance //= 0;

  $distance = $distance * 0.001;
  $distance .= ' km';

  return $distance;
}
#**********************************************************
=head2 _cdata_convert_voltage();

=cut
#**********************************************************
sub _cdata_convert_voltage {
  my ($voltage) = @_;

  $voltage //= 0;
  $voltage = $voltage * 0.0001;
  $voltage = sprintf("%.2f", $voltage);
  $voltage .= ' V';

  return $voltage;
}
#**********************************************************
=head2 _cdata2_convert_voltage();

=cut
#**********************************************************
sub _cdata2_convert_voltage {
  my ($voltage) = @_;

  $voltage //= 0;
  $voltage = $voltage * 0.00001;
  $voltage = sprintf("%.2f", $voltage);
  $voltage .= ' V';

  return $voltage;
}
##**********************************************************
#=head2 _cdata_unregister($attr);
#
#  Arguments:
#    $attr
#
#  Returns;
#    \@unregister
#
#=cut
##**********************************************************
#sub _cdata_unregister {
#  my ($attr) = @_;
#  my @unregister = ();
#
#  #my $unreg_type = ($attr->{NAS_INFO}->{MODEL_NAME} && $attr->{NAS_INFO}->{MODEL_NAME} eq 'C320') ? 'unregister_c320' : 'unregister';
#  my $snmp = _cdata({ TYPE => 'unregister' });
#
##  my $unreg_result = snmp_get({
##    %{$attr},
##    WALK   => 1,
##    OID    => $snmp->{UNREGISTER}->{OIDS},
##    #TIMEOUT => 8,
##    SILENT => 1,
##    DEBUG  => $attr->{DEBUG} || 1
##  });
##
##  my %unreg_info = (
##    2  => 'mac',
##    3  => 'info',
##    #    4  => 'x4',
##    #    5  => 'x5',
##    6  => 'register',
##    #    7  => 'x7',
##    #    8  => 'x8',
##    9  => 'vendor',
##    10 => 'firnware',
##    11 => 'version',
##    #    12 => 'x12',
##  );
##
##  foreach my $line (@$unreg_result) {
##    next if (!$line);
##    my ($id, $value) = split(/:/, $line || q{});
##
##    my ($type, $branch, $num) = split(/\./, $id || q{});
##    next if (!$unreg_info{$type});
##
##    if ($unreg_info{$type} eq 'mac') {
##      $value = bin2mac($value);
##    }
##
##    $unregister[$num - 1]->{$unreg_info{$type}} = $value;
##    $unregister[$num - 1]->{'branch'} = decode_onu($branch, { MODEL_NAME => $attr->{NAS_INFO}->{MODEL_NAME} });
##    $unregister[$num - 1]->{'branch_num'} = $branch;
##    $unregister[$num - 1]->{'pon_type'} = $snmp->{UNREGISTER}->{TYPE};
##  }
#
#  return \@unregister;
#}

#**********************************************************
=head2 _cdata2($attr) - for FD1216S

  Parsms:

=cut
#**********************************************************
sub _cdata2 {
  my ($attr) = @_;

  my %snmp = (
    epon => {
      'ONU_MAC_SERIAL' => {
        NAME      => 'Mac/Serial',
        OIDS      => '1.3.6.1.4.1.17409.2.3.4.1.1.7',
        PARSER    => 'bin2mac'
      },
      'ONU_STATUS'     => {
        NAME      => 'STATUS',
        OIDS      => '1.3.6.1.4.1.17409.2.3.4.1.1.8',
        ADD_2_OID => ''
      },
      'ONU_TX_POWER'   => {
        NAME      => 'ONU_TX_POWER',
        OIDS      => '1.3.6.1.4.1.17409.2.3.4.2.1.5',
        PARSER    => '_cdata2_convert_power',
        ADD_2_OID => '.0.0'
      },
      'ONU_RX_POWER'   => {
        NAME      => 'ONU_RX_POWER',
        OIDS      => '1.3.6.1.4.1.17409.2.3.4.2.1.4',
        PARSER    => '_cdata2_convert_power',
        ADD_2_OID => '.0.0'
      },
      'ONU_DESC'       => {
        NAME      => 'ONU_DESC',
        OIDS      => '1.3.6.1.4.1.17409.2.3.4.1.1.2',
        ADD_2_OID => ''
      },
      'ONU_IN_BYTE'    => {
        NAME   => 'PORT_IN',
        OIDS   => '1.3.6.1.4.1.17409.2.3.10.1.1.4',
        PARSER => ''
      },
      'ONU_OUT_BYTE'   => {
        NAME   => 'PORT_OUT',
        OIDS   => '1.3.6.1.4.1.17409.2.3.10.1.1.26',
        PARSER => ''
      },
      'TEMPERATURE'    => {
        NAME      => 'TEMPERATURE',
        OIDS      => '1.3.6.1.4.1.17409.2.3.4.2.1.8',
        PARSER    => '_cdata_convert_temperature',
        ADD_2_OID => '.0.0'
      },
      'reset'          => {
        NAME        => '',
        OIDS        => '1.3.6.1.4.1.17409.2.3.4.1.1.17',
        RESET_VALUE => 0,
        PARSER      => ''
      },
      #        'VLAN'           => {
      #          NAME   => '',
      #          OIDS   => '',
      #          PARSER => '',
      #          WALK   => 1
      #        },
      'DISTANCE'       => {
        NAME   => 'DISTANCE',
        OIDS   => '1.3.6.1.4.1.17409.2.3.4.1.1.15',
        PARSER => '_cdata_convert_distance'
      },
      'VOLTAGE'        => {
        NAME      => 'VOLTAGE',
        OIDS      => '1.3.6.1.4.1.17409.2.3.4.2.1.7',
        PARSER    => '_cdata2_convert_voltage',
        ADD_2_OID => '.0.0'
      }, #voltage = voltage * 0.0001;
      main_onu_info    => {
        'HARD_VERSION' => {
          NAME   => 'VERSION',
          OIDS   => '1.3.6.1.4.1.17409.2.3.4.1.1.27',
          PARSER => ''
        },
        'FIRMWARE'     => {
          NAME   => 'FIRMWARE',
          OIDS   => '1.3.6.1.4.1.17409.2.3.4.1.1.13',
          PARSER => ''
        },
        'VOLTAGE'      => {
          NAME      => 'VOLTAGE',
          OIDS      => '1.3.6.1.4.1.17409.2.3.4.2.1.7',
          PARSER    => '_cdata2_convert_voltage',
          ADD_2_OID => '.0.0'
        }, #voltage = voltage * 0.0001;
        'MAC'          => {
          NAME   => 'MAC',
          OIDS   => '1.3.6.1.4.1.17409.2.3.4.1.1.7',
          PARSER => 'bin2mac',
          WALK   => 1
        },
        #        'VLAN'             => {
        #          NAME   => '',
        #          OIDS   => '',
        #          PARSER => '',
        #          WALK   => 1
        #        },
        'ONU_PORTS_STATUS' => {
          NAME    => 'ONU_PORTS_STATUS',
          OIDS    => ' 1.3.6.1.4.1.17409.2.3.5.1.1.5',
          PARSER  => '',
          WALK    => 1,
          TIMEOUT => 10
        }
      }
    },
    gpon => {
    },
    #      unregister => {
    #
    #      }
  );

  if ($attr->{TYPE}) {
    return $snmp{$attr->{TYPE}};
  }

  return \%snmp;
}

#**********************************************************
=head2 _cdata2_onu_list()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub _cdata2_onu_list {
  my ($port_list, $attr) = @_;
  my $debug = $attr->{DEBUG} || 0;
  my @onu_list = ();
  my %pon_types = ();
  my %port_ids = ();

  my $snmp_info = equipment_test({
    %{$attr},
    TIMEOUT  => 5,
    VERSION  => 2,
    TEST_OID => 'PORTS,UPTIME'
  });

  if (!$snmp_info->{UPTIME}) {
    print "$attr->{SNMP_COMMUNITY} Not response\n";
    return [];
  }

  if ($port_list) {
    foreach my $snmp_id (keys %{$port_list}) {
      $pon_types{ $port_list->{$snmp_id}{PON_TYPE} } = 1;
      $port_ids{$port_list->{$snmp_id}{BRANCH}} = $port_list->{$snmp_id}{ID};
    }
  }
  else {
    %pon_types = (epon => 1, gpon => 1);
  }

  my $ports_descr = snmp_get({
    %$attr,
    WALK    => 1,
    OID     => '.1.3.6.1.2.1.2.2.1.2',
    VERSION => 2,
    TIMEOUT => $attr->{TIMEOUT} || 2
  });

  if (!$ports_descr || $#{$ports_descr} < 1) {
    return [];
  }

  foreach my $pon_type (keys %pon_types) {
    my $snmp = _cdata2({ TYPE => $pon_type });

    if (!$snmp->{ONU_STATUS}->{OIDS}) {
      print "$pon_type: no oids\n" if ($debug > 0);
      next;
    }

    my %onu_snmp_info = ();
    foreach my $oid_name (sort keys %{$snmp}) {
      next if ($oid_name eq 'main_onu_info' || $oid_name eq 'reset');
      if ($snmp->{$oid_name}->{OIDS}) {
        my $oid = $snmp->{$oid_name}->{OIDS};
        my $timeout = $snmp->{$oid_name}->{TIMEOUT};
        print ">> $oid\n" if ($debug > 3);
        my $result = snmp_get({
          %{$attr},
          OID     => $oid,
          VERSION => 2,
          WALK    => 1,
          SILENT  => 1,
          TIMEOUT => $timeout || 2
        });

        foreach my $line (@$result) {
          next if (!$line);

          my ($onu_index, $value) = split(/:/, $line, 2);
          ($onu_index) = $onu_index =~ /^\d+/g;
          my $function = $snmp->{$oid_name}->{PARSER};

          if (!defined($value)) {
            print ">> $line\n";
          }

          if ($function && defined(&{$function})) {
            ($value) = &{\&$function}($value);
          }

          $onu_snmp_info{$onu_index}{$oid_name} = $value;
        }
      }
    }
    #    For checking snmp result
    # AXbills::Base::_bp('onu_snmp_info', \%onu_snmp_info, { TO_CONSOLE => 1 });

    my %onu_info = ();
    foreach my $key (sort keys %port_ids) {
      next if (!$key);

      foreach my $onu_numb (sort keys %onu_snmp_info) {
        next if (!$onu_numb);
        next if (!$onu_snmp_info{$onu_numb}{'ONU_MAC_SERIAL'});

        my $bin_index =  dec2bin($onu_numb);
        my (undef, $port_bin, $onu_bin) = $bin_index =~ /(\d{9})(\d{8})(\d{8})/;
        my $port_snmp = bin2dec($port_bin);
        my $onu_snmp = bin2dec($onu_bin);
        my $port = $port_snmp - 2 - 8;
        #my $onu_id = $onu_snmp;

        if ($port < 10){
          $port = "0".$port;
        }
        next if ($key ne $port);

        if ($onu_snmp < 10){
          $onu_snmp = "0".$onu_snmp;
        }

        $onu_info{ONU_ID} = $onu_snmp;
        $onu_info{ONU_SNMP_ID} = "$onu_numb";
        $onu_info{PORT_ID} = $port_ids{$key};
        $onu_info{PON_TYPE} = $pon_type;
        $onu_info{ONU_DHCP_PORT} = dec_to_hex($port) . dec_to_hex($onu_snmp);
        foreach my $oid_name (keys %{$onu_snmp_info{$onu_numb}}) {
          next if (!$oid_name);
          $onu_info{$oid_name} = $onu_snmp_info{$onu_numb}{$oid_name} || q{};
        }
        push @onu_list, { %onu_info };
      }
    }
  }

  return \@onu_list;
}
#**********************************************************
=head2 dec2bin()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub dec2bin {
  my $str = unpack("B32", pack("N", shift));
  $str =~ s/^0+(?=\d)//;
  return $str;
}

#**********************************************************
=head2 bin2dec()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub bin2dec {
  return unpack("N", pack("B32", substr("0" x 32 . shift, -32)));
}

#**********************************************************
=head2 dec_to_hex($number)

  Arguments:
    $number -

  Returns:

=cut
#**********************************************************
sub dec_to_hex {
  my ($number) = @_;
  return sprintf("%02x", $number);
}

1
