=head1 RAISECOM

  RAISECOM
  MODEL:
    epon

    gpon
      ISCOM5508-GP

  DATE: 20200112
  UPDATE: 20210325

=cut

use strict;
use warnings;
use AXbills::Base qw(in_array);
use AXbills::Filters qw(bin2mac);
use JSON qw(decode_json);

our (
  $base_dir,
  %lang,
  %conf,
  %FORM,
  %ONU_STATUS_TEXT_CODES
);

#**********************************************************
=head2 _raisecom_get_ports($attr) - Get OLT slots and connect ONU

  Arguments:
    $attr

  Returns:
    $ports_info_hash_ref

=cut
#**********************************************************
sub _raisecom_get_ports {
  my ($attr) = @_;
  my $res = ();

  my $ports_info = equipment_test({
    %{$attr},
    TIMEOUT   => 5,
    VERSION   => 2,
    PORT_INFO => 'PORT_NAME,PORT_TYPE,PORT_DESCR,PORT_STATUS,PORT_SPEED,PORT_ALIAS,TRAFFIC,PORT_IN_ERR,PORT_OUT_ERR'
  });

  foreach my $key (sort keys %{$ports_info}) {
    if ($ports_info->{$key}{PORT_NAME} && $ports_info->{$key}{PORT_NAME} =~ /^gpon-olt((\d+)\/(\d+))$/) {
      $ports_info->{$key}{PON_TYPE} = 'gpon';
      $ports_info->{$key}{BRANCH} = $1;
      $ports_info->{$key}{BRANCH_DESC} = $ports_info->{$key}{PORT_NAME};
    }
    else {
      delete($ports_info->{$key});
    }
  }

  return $ports_info;
}

#**********************************************************
=head2 _raisecom_get_onu_info($id, $attr) - Get specific ONU's info

  Arguments:
    $id - ONU's SNMP ID
    $attr
      TODO: add support for SHOW_FIELDS
      snmp_get attrs

  Returns:
    %onu_info

=cut
#**********************************************************
sub _raisecom_get_onu_info {
  my ($id, $attr) = @_;

  my %onu_info;

  my $snmp_info = _raisecom({TYPE => "gpon"});

  foreach my $oid_name (sort keys %{$snmp_info}) {
    my $oid = $snmp_info->{$oid_name}->{OIDS} || q{};

    if (!$oid || $oid_name eq 'reset' || $snmp_info->{$oid_name}->{SKIP}) {
      next;
    }

    my $add_2_oid = $snmp_info->{$oid_name}->{ADD_2_OID} || '';

    my $onu_index = $id;
    if ($snmp_info->{$oid_name}->{ONU_INDEX_DECODER} == 1) {
      $onu_index = _raisecom_recode_onu_index_2_to_1($onu_index);
    }

    my $value = snmp_get({
      %$attr,
      OID     => $oid . '.' . $onu_index . $add_2_oid,
      SILENT  => 1,
    });

    my $function = $snmp_info->{$oid_name}->{PARSER};

    if ($function && defined(&{$function})) {
      ($value) = &{\&$function}($value);
    }

    if ($snmp_info->{$oid_name}->{NAME}) {
      $oid_name = $snmp_info->{$oid_name}->{NAME};
    }

    if ($oid_name =~ /STATUS/ && defined $value) {
      my $status_hash = _raisecom_onu_status();
      $value = $status_hash->{$value} || $ONU_STATUS_TEXT_CODES{NOT_EXPECTED_STATUS};
    }

    $onu_info{$id}{$oid_name} = $value;
  }

  return %onu_info;
}

#**********************************************************
=head2 _raisecom_onu_list($port_list, $attr)

  Arguments:
    $port_list  - OLT ports list
    $attr
      COLS       - ARRAY refs
      INFO_OIDS  - Hash refs
      NAS_ID
      TIMEOUT

  Returns:
    $onu_list [array_of_hash]

=cut
#**********************************************************
sub _raisecom_onu_list {
  my ($port_list, $attr) = @_;
  my @onu_list = ();
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
      $port_ids{$port_list->{$snmp_id}{BRANCH}} = $port_list->{$snmp_id}{ID};
    }
  }

  my $snmp = _raisecom({TYPE => "gpon"});
  my %onu_snmp_info = ();
  foreach my $oid_name (keys %{$snmp}) {
    next if ($oid_name eq 'main_onu_info' || $oid_name eq 'reset');
    if ($snmp->{$oid_name}->{OIDS}) {
      my $oid = $snmp->{$oid_name}->{OIDS};

      my $result = snmp_get ({
        %{$attr},
        OID => $oid,
        WALK => 1,
        VERSION => 2
      });

      foreach my $line (@$result) {
        next if (!$line);
        my ($onu_index, $value) = split(/:/, $line, 2);
        my $function = $snmp->{$oid_name}->{PARSER};

        if ($function && defined(&{$function})){
          ($value) = &{\&$function}($value);
        }

        my ($slot_id, $port_id, $pon_onu_id);
        if ($snmp->{$oid_name}->{ONU_INDEX_DECODER} == 1) {
          ($slot_id, $port_id, $pon_onu_id) = _raisecom_decode_onu_index1($onu_index);
          $onu_index = _raisecom_recode_onu_index_1_to_2($onu_index);
        }
        else {
          ($slot_id, $port_id, $pon_onu_id) = _raisecom_decode_onu_index2($onu_index);
        }
        $onu_snmp_info{"$slot_id/$port_id"}{$onu_index}{$oid_name} = $value;
      }
    }
  };

  foreach my $port_index (keys %onu_snmp_info) {
    next if(!$port_index);

    my $port = $onu_snmp_info{$port_index};
    my %onu_info = ();
    foreach my $onu_index (keys %$port) {
      next if(!$onu_index);

      my $onu = $port->{$onu_index};
      my (undef, undef, $pon_onu_id) = _raisecom_decode_onu_index2($onu_index);
      $onu_info{ONU_ID} = $pon_onu_id;
      $onu_info{ONU_SNMP_ID} = $onu_index;
      $onu_info{PORT_ID} = $port_ids{$port_index};
      $onu_info{ONU_DHCP_PORT} = "$port_index\_$pon_onu_id"; #fake ONU_DHCP_PORT; without this ONU to abonent binding don't work
      $onu_info{PON_TYPE} = "gpon";
      foreach my $oid_name (keys %{$onu}) {
        next if (!$oid_name);
        $onu_info{$oid_name} = $onu->{$oid_name};
      }
      push @onu_list, { %onu_info };
    }
  }

  return \@onu_list;
}

#**********************************************************
=head2 _raisecom($attr)

  Arguments:
    $attr
      TYPE - PON type. If set, returns only that OID's

=cut
#**********************************************************
sub _raisecom { #TODO: move part of OIDs to main_onu_info, fix _raisecom_get_onu_info, _raisecom_onu_list accordingly
  my ($attr) = @_;
  my $TEMPLATE_DIR = $base_dir . 'AXbills/modules/Equipment/snmp_tpl/';

  my $file_content = file_op({
    FILENAME   => 'raisecom.snmp',
    PATH       => $TEMPLATE_DIR,
  });

  $file_content =~ s#//.*$##gm;

  my $snmp = decode_json($file_content);

  if ($attr->{TYPE}) {
    return $snmp->{$attr->{TYPE}};
  }
  return $snmp;
}

#**********************************************************
=head2 _raisecom_onu_status()

=cut
#**********************************************************
sub _raisecom_onu_status {
  my %status = (
    1 => $ONU_STATUS_TEXT_CODES{ONLINE},
    2 => $ONU_STATUS_TEXT_CODES{PENDING},
    3 => $ONU_STATUS_TEXT_CODES{OFFLINE}
  );

  return \%status;
}

#**********************************************************
=head2 _raisecom_convert_distance($distance)

=cut
#**********************************************************
sub _raisecom_convert_distance {
  my ($distance) = @_;

  $distance //= 0;

  if ($distance =~ /<(\d+)/) {
    $distance = '<' . $1 * 0.001 . ' km';
    return $distance;
  }

  $distance = $distance * 0.001;
  $distance .= ' km';
  return $distance;
}

#**********************************************************
=head2 _raisecom_convert_voltage($voltage)

=cut
#**********************************************************
sub _raisecom_convert_voltage {
  my ($voltage) = @_;

  $voltage //= 0;
  $voltage *= 0.02;

  $voltage .= ' V';
  return $voltage;
}

#**********************************************************
=head2 _raisecom_convert_onu_power($power)

=cut
#**********************************************************
sub _raisecom_convert_onu_power {
  my ($power) = @_;

  $power //= 0;

  if ($power & 0x8000) { #convert from unsigned 16bit int to signed
    $power -= 0x10000;
  }

  $power = ($power-15000)/500;
  $power = sprintf("%.2f", $power);

  return $power;
}

#**********************************************************
=head2 _raisecom_convert_olt_power($power)

=cut
#**********************************************************
sub _raisecom_convert_olt_power {
  my ($power) = @_;

  $power //= 0;

  $power *= 0.1;

  return $power;
}

#**********************************************************
=head2 _raisecom_convert_temperature($temperature)

=cut
#**********************************************************
sub _raisecom_convert_temperature {
  my ($temperature) = @_;

  $temperature //= 0;
  $temperature = ($temperature / 256);
  $temperature = sprintf("%.2f", $temperature);

  return $temperature;
}

#**********************************************************
=head2 _raisecom_decode_onu_index1($index) - Decode ONU index type 1

  Arguments:
    $index - ONU index type 1 (examples: 10106001, 815406369)

  Returns:
    ($slot_id, $port_id, $pon_onu_id)

=cut
#**********************************************************
sub _raisecom_decode_onu_index1 {
  my ($index) = @_;
  return if (!$index);

  my $slot_id, my $port_id, my $pon_onu_id;
  $index--;
  if ($index<(3<<28)) {
    $slot_id = int($index/10000000);
    $index %= 10000000;
    $port_id = int($index/100000);
    $index %= 100000;
    $pon_onu_id = int($index/1000);
  }
  else {
    $index -= (3<<28);
    $slot_id = int($index/10000000);
    $index %= 10000000;
    $port_id = int($index/100000);
    $index %= 100000;
    $pon_onu_id = int($index/1000) + 100;

  }

  return ($slot_id, $port_id, $pon_onu_id);
}

#**********************************************************
=head2 _raisecom_decode_onu_index2($index) - Decode ONU index type 2

  Arguments:
    $index - ONU index type 2 (examples: 276889606, 276889700)

  Returns:
    ($slot_id, $port_id, $pon_onu_id)

=cut
#**********************************************************
sub _raisecom_decode_onu_index2 {
  my ($index) = @_;
  return if (!$index);

  my $slot_id = ($index>>23) & 0x1F;
  my $port_id = ($index>>16) & 0x7F;
  my $pon_onu_id = $index & 0xFFFF;

  return ($slot_id, $port_id, $pon_onu_id);
}

#**********************************************************
=head2 _raisecom_recode_onu_index_1_to_2($index) - Recode ONU index type 1 to type 2

  Arguments:
    $index - ONU index type 1 (examples: 10106001, 815406369)

  Returns:
    $index - ONU index type 2 (examples: 276889606, 276889700)

=cut
#**********************************************************
sub _raisecom_recode_onu_index_1_to_2 {
  my ($index) = @_;
  return if (!$index);

  my ($slot_id, $port_id, $pon_onu_id) = _raisecom_decode_onu_index1($index);
  my $result = (1<<28) | ($slot_id<<23) | ($port_id<<16) | ($pon_onu_id);

  return $result;
}

#**********************************************************
=head2 _raisecom_recode_onu_index_2_to_1($index) - Recode ONU index type 2 to type 1

  Arguments:
    $index - ONU index type 2 (examples: 276889606, 276889700)

  Returns:
    $index - ONU index type 1 (examples: 10106001, 815406369)

=cut
#**********************************************************
sub _raisecom_recode_onu_index_2_to_1 {
  my ($index) = @_;
  return if (!$index);

  my ($slot_id, $port_id, $pon_onu_id) = _raisecom_decode_onu_index2($index);
  my $result;
  if ($pon_onu_id < 100) {
    $result = $slot_id * 10000000 + $port_id * 100000 + $pon_onu_id * 1000 + 1;
  }
  else {
    $result = (3<<28) + ($slot_id * 10000000 + $port_id * 100000 + ($pon_onu_id%100) * 1000 + 1);
  }

  return $result;
}

1
