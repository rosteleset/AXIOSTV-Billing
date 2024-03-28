=head1 NAME

  V-SOLUTION

=head TESTING

  V1600D4
  V1600D8
  V1600D16
  V1600G-1B

=cut

use strict;
use warnings;
use AXbills::Base qw(in_array);
use AXbills::Filters qw(bin2mac _mac_former dec2hex);
use JSON qw(decode_json);

our (
  $base_dir,
  %lang,
  %ONU_STATUS_TEXT_CODES
);



#**********************************************************
=head2 _vsolution_get_ports($attr) - Get OLT slots and connect ONU

=cut
#**********************************************************
sub _vsolution_get_ports {
  my ($attr) = @_;

  my $ports_info = equipment_test({
    %{$attr},
    TIMEOUT   => 5,
    VERSION   => 2,
    PORT_INFO => 'PORT_NAME,PORT_TYPE,PORT_DESCR,PORT_STATUS,PORT_SPEED,IN,OUT,PORT_IN_ERR,PORT_OUT_ERR'
  });

  foreach my $key (keys %{$ports_info}) {
    if ($ports_info->{$key}{PORT_TYPE} && $ports_info->{$key}{PORT_TYPE} =~ /^1$/ && $ports_info->{$key}{PORT_NAME} =~ /(.PON)(\d+\/\d+)$/) {
      my $type = lc($1);
      #my $branch = decode_port($key);
      $ports_info->{$key}{BRANCH} = $2;
      $ports_info->{$key}{PON_TYPE} = $type;
      $ports_info->{$key}{SNMP_ID} = $key;
      $ports_info->{$key}{BRANCH_DESC} = $ports_info->{$key}{PORT_DESCR};
    }
    else {
      delete($ports_info->{$key});
    }
  }

  return $ports_info;
}

#**********************************************************
=head2 _vsolution_get_onu_info($id, $attr) - Get specific ONU's info

  Arguments:
    $id - ONU's SNMP ID
    $attr

  Returns:
    %onu_info

=cut
#**********************************************************
sub _vsolution_get_onu_info {
  my ($id, $attr) = @_;

  my @oid_names = grep { $_ ne 'ONU_IN_BYTE' && $_ ne 'ONU_OUT_BYTE' } (sort keys %{$attr->{SNMP_INFO}});
  push @oid_names, 'ONU_OUT_BYTE', 'ONU_IN_BYTE';

  return default_get_onu_info($id, {%$attr, CUSTOM_OID_ORDER => \@oid_names});
}

#**********************************************************
=head2 _vsolution_onu_list($attr)

  Arguments:
    $attr
      COLS       - ARRAY refs
      INFO_OIDS  - Hash refs
      NAS_ID
      TIMEOUT

=cut
#**********************************************************
sub _vsolution_onu_list {
  my ($port_list, $attr) = @_;

  my @cols      = ('PORT_ID', 'ONU_ID', 'ONU_SNMP_ID', 'PON_TYPE', 'ONU_DHCP_PORT');
  my $debug     = $attr->{DEBUG} || 0;
  my @all_rows  = ();
  my %pon_types = ();
  my %port_ids  = ();

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

  #my $ether_ports = $snmp_info->{PORTS};
  if ($port_list) {
    foreach my $snmp_id (keys %{$port_list}) {
      $pon_types{ $port_list->{$snmp_id}{PON_TYPE} } = 1;
      $port_ids{$port_list->{$snmp_id}{BRANCH}} = $port_list->{$snmp_id}{ID};
    }
  }
  else {
    %pon_types = (epon => 1, gpon => 1);
  }

  my $pon_ports_descr = snmp_get({
    %$attr,
    WALK    => 1,
    OID     => '.1.3.6.1.4.1.37950.1.1.5.10.1.2.1.1.2',
    VERSION => 2,
    TIMEOUT => $attr->{TIMEOUT} || 2
  });

  if (!$pon_ports_descr || $#{$pon_ports_descr} < 1) {
    return [];
  }

  foreach my $pon_type (keys %pon_types) {
    my $snmp = _vsolution({ TYPE => $pon_type });

    if (!$snmp->{ONU_STATUS}->{OIDS}) {
      print "$pon_type: no oids\n" if ($debug > 0);
      next;
    }
    else {
      if($debug > 3) {
        print "PON TYPE: $pon_type\n";
      }
    }

    #    my $onu_status_list = snmp_get({ %$attr,
    #      WALK    => 1,
    #      OID     => $snmp->{ONU_STATUS}->{OIDS},
    #    });

    #    my %onu_cur_status = ();
    #    foreach my $line ( @$onu_status_list ) {
    #      my($port_index, $status)=split(/:/, $line);
    #      $onu_cur_status{$port_index}=$status;
    #    }

    #Get info
    my %onu_snmp_info = ();
    foreach my $oid_name (keys %{$snmp}) {
      if ($snmp->{$oid_name}->{OIDS}) {
        my $oid = $snmp->{$oid_name}->{OIDS};

        if ($oid_name eq 'reset' ||
          $oid_name eq 'ONU_IN_BYTE' || $oid_name eq 'ONU_OUT_BYTE') { #look below for explanation
          next
        }

        push @cols, $oid_name;
        print "PON ONU INFO $oid_name: $oid\n" if ($debug > 3);
        my $result = snmp_get({
          %{$attr},
          OID     => $oid,
          VERSION => 2,
          WALK    => 1,
          SILENT  => 1
        });

        foreach my $line (@$result) {
          next if (!$line);
          my ($interface_index, $value) = split(/:/, $line, 2);
          my $function = $snmp->{$oid_name}->{PARSER};

          if (!defined($value)) {
            print ">> $line\n";
          }
          elsif($debug > 4) {
            print " IF_INDEX: $interface_index RESULT: $line\n";
          }

          if ($function && defined(&{$function})) {
            ($value) = &{\&$function}($value);
          }

          if($interface_index =~ /^\d+$/) {
            print "$oid_name: Index: $interface_index OID: $oid VALUE: $value\n";
            next;
          }

          $onu_snmp_info{$oid_name}{$interface_index} = $value;
        }
      }
    }

    #why we can't query ONU_IN_BYTE and ONU_OUT_BYTE in main loop:
    #if we request ONU_IN_BYTE, OLT almost always incorrectly returns 0.
    #but, if we request ONU_IN_BYTE exactly after ONU_OUT_BYTE, almost always it is returned correctly.
    #ONU_IN_BYTE of specific ONU should be queried exactly after ONU_OUT_BYTE of that specific ONU, so we can't just snmpwalk ONU_OUT_BYTE, then snmpwalk ONU_IN_BYTE.
    #that's why snmp_get is called like this (OID => [ $onu_out_byte_oid, $onu_in_byte_oid ]) - it queries OLT exactly as needed
    #TODO: fix it on ONU page
    my $onu_out_byte_oid = $snmp->{ONU_OUT_BYTE}->{OIDS};
    my $onu_in_byte_oid  = $snmp->{ONU_IN_BYTE}->{OIDS};

    push @cols, 'ONU_OUT_BYTE', 'ONU_IN_BYTE';
    print "PON ONU INFO (ONU_OUT_BYTE, ONU_IN_BYTE): ($onu_out_byte_oid, $onu_in_byte_oid)\n" if ($debug > 3);
    my $onu_traffic = snmp_get({
      %$attr,
      WALK    => 1,
      OID     => [ $onu_out_byte_oid, $onu_in_byte_oid ],
      VERSION => 2,
      TIMEOUT => $attr->{TIMEOUT} || 2
    });

    foreach my $line (@$onu_traffic) {
      my ($oid, $bytes) = split(':', $line, 2);

      if (0 == index $oid, "$onu_in_byte_oid.") {
        my $interface_index = substr $oid, length "$onu_in_byte_oid.";
        $onu_snmp_info{ONU_IN_BYTE}{$interface_index} = $bytes;
      }
      elsif (0 == index $oid, "$onu_out_byte_oid.") {
        my $interface_index = substr $oid, length "$onu_out_byte_oid.";
        $onu_snmp_info{ONU_OUT_BYTE}{$interface_index} = $bytes;
      }
    }

    my $onu_count = 0;
    foreach my $key (sort keys %{ $onu_snmp_info{ONU_MAC_SERIAL} }) {
      my %onu_info = ();
      $onu_count++;
      my ($branch, $onu_id) = split(/\./, $key, 2);

      for (my $i = 0; $i <= $#cols; $i++) {
        my $value = '';
        my $oid_name = $cols[$i];
        if ($oid_name eq 'ONU_ID') {
          $value = $onu_id;
        }
        elsif ($oid_name eq 'PORT_ID') {
          #$value = $port_list->{$snmp_id}->{ID};
          $value = $port_ids{'0/'.$branch} ;
        }
        elsif ($oid_name eq 'PON_TYPE') {
          $value = $pon_type;
        }
        elsif ($oid_name eq 'ONU_DHCP_PORT') {
          $value = $branch . ':' . $onu_id;
        }
        elsif ($oid_name eq 'ONU_SNMP_ID') {
          $value = $key;
        }
        else {
          $value = $onu_snmp_info{$cols[$i]}{$key};
        }
        $onu_info{$oid_name}=$value;
      }

      push @all_rows, \%onu_info;
    }
  }

  return \@all_rows;
}

#**********************************************************
=head2 _vsolution($attr)

  Parsms:
    cur_tx   - current onu TX
    onu_iden - ONU IDENT (MAC SErial or othe)

=cut
#**********************************************************
sub _vsolution {
  my ($attr) = @_;
  my $TEMPLATE_DIR = $base_dir . 'AXbills/modules/Equipment/snmp_tpl/';

  my $file_content = file_op({
    FILENAME   => 'vsolution.snmp',
    PATH       => $TEMPLATE_DIR,
  });

  $file_content =~ s#//.*$##gm;

  my $snmp = decode_json($file_content);

  if ($attr->{TYPE}) {
    return $snmp->{$attr->{TYPE}};
  }
  return $snmp;
}

##**********************************************************
#=head2 _vsolution_mac_list()
#
#=cut
##**********************************************************
#sub _vsolution_mac_list {
#  my ($value) = @_;
#
#  my (undef, $v) = split(/:/, $value);
#  $v = bin2mac($v) . ';';
#
#  return '', $v;
#}

#**********************************************************
=head2 _vsolution_onu_status()

=cut
#**********************************************************
sub _vsolution_onu_status {

  my %status = (
    0 => $ONU_STATUS_TEXT_CODES{OFFLINE},
    1 => $ONU_STATUS_TEXT_CODES{ONLINE}
  );

  return \%status;
}

#**********************************************************
=head2 _vsolution_set_desc_port($attr) - Set Description to OLT ports

=cut
#**********************************************************
sub _vsolution_set_desc {
  my ($attr) = @_;

  my $oid = $attr->{OID} || '';

  if ($attr->{PORT}) {
    #    $oid = '1.3.6.1.2.1.31.1.1.1.18.'.$attr->{PORT};
  }

  snmp_set({
    SNMP_COMMUNITY => $attr->{SNMP_COMMUNITY},
    OID            => [ $oid, "string", "$attr->{DESC}" ]
  });

  return 1;
}

#**********************************************************
=head2 _vsolution_convert_power($power);

  Arguments:
    $power

=cut
#**********************************************************
sub _vsolution_convert_power {
  my ($power) = @_;

  $power //= 0;
  $power =~ /\s\(([-0-9.]*)/;
  $power = $1 || 0;

  if (-65535 == $power) {
    $power = '';
  }

  return $power;
}

#**********************************************************
=head2 _vsolution_convert_temperature();

=cut
#**********************************************************
sub _vsolution_convert_temperature {
  my ($temperature) = @_;

  $temperature ||= 0;

  $temperature =~ s/\s+C//;

#@  $temperature = ($temperature / 256);
  $temperature = sprintf("%.2f", $temperature);

  return $temperature;
}

##**********************************************************
#=head2 _vsolution_convert_voltage();
#
#=cut
##**********************************************************
#sub _vsolution_convert_voltage {
#  my ($voltage) = @_;
#
#  $voltage //= 0;
#  $voltage = $voltage * 0.0001;
#  $voltage = sprintf("%.2f", $voltage);
#  $voltage .= ' V';
#
#  return $voltage;
#}

#**********************************************************
=head2 _vsolution_convert_distance();

=cut
#**********************************************************
sub _vsolution_convert_distance {
  my ($distance) = @_;

  $distance //= 0;

  $distance = $distance * 0.001;
  $distance .= ' km';
  return $distance;
}

#**********************************************************
=head2 _vsolution_get_fdb($attr) - Get FDB table

  Arguments:
    $attr
      SNMP_TPL
      SNMP_COMMUNITY
      TIMEOUT
      attrs for snmp_get
      attrs for _get_snmp_oid

  Returns:
    \%fdb_hash

=cut
#**********************************************************
sub _vsolution_get_fdb {
  my ($attr) = @_;
  my %fdb_hash = ();

  my $snmp_template = _get_snmp_oid($attr->{SNMP_TPL} || 'vsolution.snmp', $attr);

  #Get port name list
  my $ports_name;
  my $port_name_oid = $snmp_template->{ports}->{PORT_NAME}->{OIDS} || '';
  if ($port_name_oid) {
    $ports_name = snmp_get({
      %$attr,
      TIMEOUT => $attr->{TIMEOUT} || 8,
      OID     => $port_name_oid,
      WALK    => 1
    });
  }

  my %port_name_to_id = map { my ($id, $port_name) = split(':', $_, 2); $port_name => $id; } @$ports_name;

  return () if (!$ports_name);

  my $mac_vlan_id = snmp_get({
    %$attr,
    TIMEOUT => $attr->{TIMEOUT} || 8,
    OID     => '1.3.6.1.4.1.37950.1.1.5.10.3.2.1.2',
    WALK    => 1
  });

  my %mac_vlan_id = map { split(':', $_, 2) } @$mac_vlan_id;

  my $mac_addr = snmp_get({
    %$attr,
    TIMEOUT => $attr->{TIMEOUT} || 8,
    OID     => '1.3.6.1.4.1.37950.1.1.5.10.3.2.1.3',
    WALK    => 1
  });

  my %mac_addr = map { split(':', $_, 2) } @$mac_addr;

  my $mac_port_name = snmp_get({
    %$attr,
    TIMEOUT => $attr->{TIMEOUT} || 8,
    OID     => '1.3.6.1.4.1.37950.1.1.5.10.3.2.1.5',
    WALK    => 1
  });

  my %mac_port_name = map { split(':', $_, 2) } @$mac_port_name;

  foreach my $id (keys %mac_addr) {
    my $mac = bin2mac($mac_addr{$id});
    my $hash_key = $mac . (($mac_vlan_id{$id}) ? $mac_vlan_id{$id} : '');
    $fdb_hash{$hash_key}{1} = $mac;

    $fdb_hash{$hash_key}{2} = $port_name_to_id{$mac_port_name{$id}};
    if (!$fdb_hash{$hash_key}{2}) {
      my $port_name = $mac_port_name{$id};
      $port_name =~ s/^GE(\d+)$/GE0\/$1/;
      $fdb_hash{$hash_key}{2} = $port_name_to_id{$port_name};
    }
    $fdb_hash{$hash_key}{2} //= 0;

    $fdb_hash{$hash_key}{4} = $mac_vlan_id{$id};
    $fdb_hash{$hash_key}{5} = $mac_port_name{$id};
  }

  return %fdb_hash;
}

1
