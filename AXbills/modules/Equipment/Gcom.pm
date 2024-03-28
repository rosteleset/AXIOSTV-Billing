=head1 GCOM

  GCOM
  MODEL:
    epon
      EL5610-04P
      EL5610-08P
      EL5610-16P

    gpon
      GL5610-04P
      GL5610-08P
      GL5610-16P


  DATE: 20191118
  UPDATE: 20210324

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
=head2 _gcom_get_ports($attr) - Get OLT slots and connect ONU

  Arguments:
    $attr

  Results:
    $ports_info_hash_ref

=cut
#**********************************************************
sub _gcom_get_ports {
  my ($attr) = @_;
  my $res = ();

  my $ports_info = equipment_test({
    %{$attr},
    TIMEOUT   => 5,
    VERSION   => 2,
    PORT_INFO => 'PORT_NAME,PORT_TYPE,PORT_DESCR,PORT_STATUS,PORT_SPEED,PORT_ALIAS,TRAFFIC,PORT_IN_ERR,PORT_OUT_ERR'
  });

  if ($attr->{MODEL_NAME} =~ 'EL5610') {
    foreach my $key (sort keys %{$ports_info}) {
      if ($ports_info->{$key}{PORT_NAME} && $ports_info->{$key}{PORT_NAME} =~ /^p((\d+)\/(\d+))$/) {
        $ports_info->{$key}{PON_TYPE} = 'epon';
        $ports_info->{$key}{BRANCH} = $1;
        $ports_info->{$key}{BRANCH_DESC} = $ports_info->{$key}{PORT_NAME};
        my $onus = snmp_get({
          %{$attr},
          OID => "1.3.6.1.4.1.13464.1.13.3.1.1.1.$2.$3",
          WALK => 1
        });
        $ports_info->{$key}{onu_count} = scalar @$onus;
        $ports_info->{$key}{ONU_COUNT} = $ports_info->{$key}{onu_count};
      }
      else {
        delete($ports_info->{$key});
      }
    }
  }
  elsif ($attr->{MODEL_NAME} =~ 'GL5610') {
    foreach my $key (sort keys %{$ports_info}) {
      if ($ports_info->{$key}{PORT_NAME} && $ports_info->{$key}{PORT_NAME} =~ /^g((\d+)\/(\d+))$/) {
        $ports_info->{$key}{PON_TYPE} = 'gpon';
        $ports_info->{$key}{BRANCH} = $1;
        $ports_info->{$key}{BRANCH_DESC} = $ports_info->{$key}{PORT_NAME};
        my $onus = snmp_get({
          %{$attr},
          OID => "1.3.6.1.4.1.13464.1.14.2.4.1.1.1.1.$2.$3",
          WALK => 1
        });
        $ports_info->{$key}{onu_count} = scalar @$onus;
        $ports_info->{$key}{ONU_COUNT} = $ports_info->{$key}{onu_count};

      }
      else {
        delete($ports_info->{$key});
      }
    }
  }

  return $ports_info;
}


#**********************************************************
=head2 _gcom_onu_list($port_list, $attr)

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
sub _gcom_onu_list {
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

  my $pon_type;
  my $snmp;
  if ($attr->{MODEL_NAME} =~ 'EL5610') {
    $snmp = _gcom({TYPE => 'epon'});
    $pon_type = 'epon';
  }
  elsif ($attr->{MODEL_NAME} =~ 'GL5610') {
    $snmp = _gcom({TYPE => 'gpon'});
    $pon_type = 'gpon';
  }
  my %onu_snmp_info = ();
  foreach my $oid_name (keys %{$snmp}) {
    next if ($oid_name eq 'main_onu_info' || $oid_name eq 'reset');
    if ($snmp->{$oid_name}->{OIDS}) {
      my $oid = $snmp->{$oid_name}->{OIDS};

      sleep 1;
      my $result = snmp_get ({
        %{$attr},
        OID => $oid,
        WALK => 1,
        VERSION => 2
      });

      foreach my $line (@$result) {
        my (undef, $value) = split(/:/, $line, 2);
        my ($port_index, $onu_index) = $line =~ /(\d+\.\d+)\.(\d+)/;
        my $function = $snmp->{$oid_name}->{PARSER};

        if ($function && defined(&{$function})){
          ($value) = &{\&$function}($value);
        }

        $onu_snmp_info{$port_index}{$onu_index}{$oid_name} = $value;
      }
    }
  };

  my %onu_info = ();
  foreach my $port_index (keys %onu_snmp_info) {
    next if(!$port_index);

    my $port_index_slash = $port_index;
    $port_index_slash =~ s/\./\//;

    my $port = $onu_snmp_info{$port_index};
    foreach my $onu_index (keys %$port){
      next if(!$onu_index);

      my $onu = $port->{$onu_index};
      $onu_info{ONU_ID} = $onu_index;
      $onu_info{ONU_SNMP_ID} = "$port_index.$onu_index";
      $onu_info{ONU_DHCP_PORT} = sprintf('%02x%02x%02x', split('\.', $port_index), $onu_index);
      $onu_info{PORT_ID} = $port_ids{$port_index_slash};
      $onu_info{PON_TYPE} = $pon_type;
      foreach my $oid_name (keys %{$onu}){
        next if (!$oid_name);
        $onu_info{$oid_name} = $onu->{$oid_name};
      }
      push @onu_list, { %onu_info };
    }
  }

  return \@onu_list;
}

#**********************************************************
=head2 _gcom($attr)

  Arguments:
    $attr
      TYPE - PON type. If set, returns only that OID's

=cut
#**********************************************************
sub _gcom {
  my ($attr) = @_;
  my $TEMPLATE_DIR = $base_dir . 'AXbills/modules/Equipment/snmp_tpl/';

  my $file_content = file_op({
    FILENAME   => 'gcom.snmp',
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
=head2 _gcom_onu_status()

=cut
#**********************************************************
sub _gcom_onu_status {
  my %status = (
    0 => $ONU_STATUS_TEXT_CODES{OFFLINE}, #down
    1 => $ONU_STATUS_TEXT_CODES{ONLINE}   #up
  );

  return \%status;
}

#**********************************************************
=head2 _gcom_convert_distance($distance)

=cut
#**********************************************************
sub _gcom_convert_distance {
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
=head2 _gcom_convert_voltage($voltage)

=cut
#**********************************************************
sub _gcom_convert_voltage {
  my ($voltage) = @_;

  $voltage //= 0;

  $voltage .= ' V';
  return $voltage;
}

1
