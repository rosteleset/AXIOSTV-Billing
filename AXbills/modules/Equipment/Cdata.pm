=head1 Cdata

  C-data
  MODEL:
    epon
      FD1104SN
      FD1216S

    gpon

    testing
      FD1204S
      FD1208S
      FD1608SN

  DATE: 20190704
  UPDATE: 20230113

=head1 extra_info

  MIbs
  https://github.com/librenms/librenms/blob/master/mibs/cdata/FD-SYSTEM-MIB

  .1.3.6.1.4.1.17409.2.3.1.2.1.1.2.1 = STRING: "TAsvan_CDATA1608"
  .1.3.6.1.4.1.17409.2.3.1.2.1.1.3.1 = STRING: "FD1608SN-R1"

  ponPortName
    1.3.6.1.4.1.17409.2.3.3.1.1.21.1.0
  ponPortIndex
    1.3.6.1.4.1.17409.2.3.3.1.1.3


=cut

use strict;
use warnings;
use AXbills::Filters qw(bin2mac bin2hex serial2mac);
use JSON qw(decode_json);

our (
  $base_dir,
  %lang,
  %conf,
  %FORM,
  %ONU_STATUS_TEXT_CODES
);

my $TEMPLATE_DIR = $base_dir . 'AXbills/modules/Equipment/snmp_tpl/';

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

  my $debug = $attr->{DEBUG} || 0;

  my $ports_info = equipment_test({
    %{$attr},
    TIMEOUT   => $attr->{TIMEOUT} || 5,
    VERSION   => 2,
    PORT_INFO => 'PORT_NAME,PORT_TYPE,PORT_DESCR,PORT_STATUS,PORT_SPEED,TRAFFIC,PORT_IN_ERR,PORT_OUT_ERR'
  });

  foreach my $key (sort keys %{$ports_info}) {
    print "$key / $ports_info->{$key}{PORT_NAME} / $ports_info->{$key}{PORT_TYPE} //\n" if ($debug);
    if ($ports_info->{$key}{PORT_TYPE} && $ports_info->{$key}{PORT_TYPE} == 1 && $ports_info->{$key}{PORT_NAME} #FD11..
      && $ports_info->{$key}{PORT_NAME} =~ /^(.PON).+PON-(\d+)/) {
      my $type = lc($1);
      $ports_info->{$key}{PON_TYPE} = $type;
      $ports_info->{$key}{SNMP_ID} = $key;
      $ports_info->{$key}{BRANCH_DESC} = $ports_info->{$key}{PORT_NAME};
      $ports_info->{$key}{BRANCH} = $2;
      $ports_info->{$key}{PORT_ALIAS} = $ports_info->{$key}{PORT_NAME};
    }
    elsif ($ports_info->{$key}{PORT_TYPE} && $ports_info->{$key}{PORT_TYPE} == 1 && $ports_info->{$key}{PORT_DESCR} #FD11..
      && $ports_info->{$key}{PORT_DESCR} =~ /^(.PON).+PON-(\d+)/) {
      my $type = lc($1);
      $ports_info->{$key}{PON_TYPE} = $type;
      $ports_info->{$key}{SNMP_ID} = $key;
      $ports_info->{$key}{BRANCH_DESC} = $ports_info->{$key}{PORT_DESCR};
      $ports_info->{$key}{BRANCH} = $2;
      $ports_info->{$key}{PORT_ALIAS} = $ports_info->{$key}{PORT_DESCR};
    }
    elsif ( #FD12 and FD16..
      $ports_info->{$key}{PORT_TYPE} &&
      $ports_info->{$key}{PORT_TYPE} == 117 &&
      $ports_info->{$key}{PORT_DESCR} &&
      $ports_info->{$key}{PORT_DESCR} =~ /^pon(.+)/) {
      my $branch = $1;
      my ($branch_num) = $branch =~ /\d+\/\d+\/(\d+)/;

      if ($branch_num < 10) {
        $branch_num = '0' . $branch_num;
      }

      $ports_info->{$key}{PON_TYPE} = $attr->{MODEL_NAME} =~/^FD16/ ? 'gpon' : 'epon';
      $ports_info->{$key}{SNMP_ID} = $key;
      $ports_info->{$key}{BRANCH} = $branch_num;
      $ports_info->{$key}{BRANCH_DESC} = $ports_info->{$key}{PORT_DESCR};
      $ports_info->{$key}{PORT_ALIAS} = $ports_info->{$key}{PORT_DESCR};
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


  if ($attr->{MODEL_NAME} && $attr->{MODEL_NAME} =~ /^FD12/) {
    return _cdata_fd12_onu_list($port_list, $attr);
  }
  elsif ($attr->{MODEL_NAME} && $attr->{MODEL_NAME} =~/^FD16/) {
    return _cdata_fd16_onu_list($port_list, $attr)
  }

  my $debug = $attr->{DEBUG} || 0;
  my @onu_list = ();
  my %pon_types = ();
  my %port_ids = ();

  my $snmp_info = equipment_test({
    %{$attr},
    TIMEOUT  => $attr->{TIMEOUT} || 5,
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

    foreach my $branch (sort keys %port_ids) {
      next if (!$branch);

      foreach my $onu_id (sort keys %{$onu_snmp_info{$branch}}) {
        next if (!$onu_id);

        my %onu_info = ();

        $onu_info{ONU_ID}      = $onu_id;
        $onu_info{ONU_SNMP_ID} = "$branch.$onu_id";
        $onu_info{PORT_ID}     = $port_ids{$branch};
        $onu_info{PON_TYPE}    = $pon_type;
        $onu_info{ONU_DHCP_PORT} = sprintf("%02x%02x", $branch, $onu_id); #according to #S18564 ONU_DHCP_PORT on FD11* always matches this format
        foreach my $oid_name (keys %{$onu_snmp_info{$branch}{$onu_id}}) {
          next if (!$oid_name);
          $onu_info{$oid_name} = $onu_snmp_info{$branch}{$onu_id}{$oid_name} || q{};
        }
        push @onu_list, { %onu_info };
      }
    }
  }

  return \@onu_list;
}

#**********************************************************
=head2 _cdata($attr) - for FD11..

  Parsms:

=cut
#**********************************************************
sub _cdata {
  my ($attr) = @_;

  if ($attr->{MODEL} && $attr->{MODEL} =~ /^FD12/) {
    return _cdata_fd12($attr);
  }
  elsif ($attr->{MODEL} && $attr->{MODEL} =~ /^FD16/) {
    return _cdata_fd16($attr)
  }

  my $file_content = file_op({
    FILENAME   => 'cdata.snmp',
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
=head2 _cdata_onu_status()

=cut
#**********************************************************
sub _cdata_onu_status {

  my %status = (
#    0 => 'Authenticated:text-green',
    1 => $ONU_STATUS_TEXT_CODES{ONLINE},
    2 => $ONU_STATUS_TEXT_CODES{OFFLINE},
    3 => $ONU_STATUS_TEXT_CODES{ONLINE}
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
sub _cdata_fd12_convert_power {
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
=head2 _cdata_fd12_convert_voltage();

=cut
#**********************************************************
sub _cdata_fd12_convert_voltage {
  my ($voltage) = @_;

  $voltage //= 0;
  $voltage = $voltage * 0.00001;
  $voltage = sprintf("%.2f", $voltage);
  $voltage .= ' V';

  return $voltage;
}

sub _cdata_sec2time {
  my ($sec)=@_;

  return sec2time($sec, { str => 1 });
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
=head2 _cdata_fd12($attr) - for FD12..

  Parsms:

=cut
#**********************************************************
sub _cdata_fd12 {
  my ($attr) = @_;

  my $file_content = file_op({
    FILENAME   => 'cdata_fd12.snmp',
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
=head2 _cdata_fd12_onu_list()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub _cdata_fd12_onu_list { #TODO: merge with _cdata_onu_list
  my ($port_list, $attr) = @_;
  my $debug = $attr->{DEBUG} || 0;
  my @onu_list = ();
  my %pon_types = ();

  my $snmp_info = equipment_test({
    %{$attr},
    TIMEOUT  => $attr->{TIMEOUT} || 5,
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

    my $snmp = _cdata_fd12({ TYPE => $pon_type });

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

    foreach my $onu_snmp_id (sort keys %onu_snmp_info) {
      next if (!$onu_snmp_id);
      next if (!$onu_snmp_info{$onu_snmp_id}{'ONU_MAC_SERIAL'});

      my %onu_info = ();

      my $port_snmp_id_1 = $onu_snmp_id & ~0xFF;
      my $port_snmp_id_2 = ($onu_snmp_id >> 8) & 0xFF;
      my $port = $port_list->{$port_snmp_id_1} || $port_list->{$port_snmp_id_2};

      my $branch = $port->{branch};
      my $onu_id = $onu_snmp_id & 0xFF;

      $onu_info{ONU_ID} = $onu_id;
      $onu_info{ONU_SNMP_ID} = $onu_snmp_id;
      $onu_info{PORT_ID} = $port->{id};
      $onu_info{PON_TYPE} = $pon_type;
      $onu_info{ONU_DHCP_PORT} = sprintf("%02x%02x", $branch, $onu_id);
      foreach my $oid_name (keys %{$onu_snmp_info{$onu_snmp_id}}) {
        next if (!$oid_name);
        $onu_info{$oid_name} = $onu_snmp_info{$onu_snmp_id}{$oid_name} || q{};
      }
      push @onu_list, { %onu_info };
    }
  }

  return \@onu_list;
}

sub _cdata_fd16 {
  my ($attr) = @_;

  my $file_content = file_op({
    FILENAME   => 'cdata_fd16.snmp',
    PATH       => $TEMPLATE_DIR,
  });
  $file_content =~ s#//.*$##gm;

  my $snmp = decode_json($file_content);

  if ($attr->{TYPE}) {
    return $snmp->{$attr->{TYPE}};
  }

  return $snmp;
}

sub _cdata_fd16_onu_list { #TODO: merge with _cdata_onu_list
  my ($port_list, $attr) = @_;
  my $debug = $attr->{DEBUG} || 0;
  my @onu_list = ();
  my %pon_types = ();

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
    my $snmp = _cdata_fd16({ TYPE => $pon_type });

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

    foreach my $onu_snmp_id (sort keys %onu_snmp_info) {
      next if (!$onu_snmp_id);
      next if (!$onu_snmp_info{$onu_snmp_id}{'ONU_MAC_SERIAL'});

      my %onu_info = ();

      my $port_snmp_id_1 = $onu_snmp_id & ~0xFF;
      my $port_snmp_id_2 = ($onu_snmp_id >> 8) & 0xFF;
      my $port = $port_list->{$port_snmp_id_1} || $port_list->{$port_snmp_id_2};

      my $branch = $port->{branch};
      my $onu_id = $onu_snmp_id & 0xFF;

      $onu_info{ONU_ID} = $onu_id;
      $onu_info{ONU_SNMP_ID} = $onu_snmp_id;
      $onu_info{PORT_ID} = $port->{id};
      $onu_info{PON_TYPE} = $pon_type;
      $onu_info{ONU_DHCP_PORT} = sprintf("%02x%02x", $branch, $onu_id);
      foreach my $oid_name (keys %{$onu_snmp_info{$onu_snmp_id}}) {
        next if (!$oid_name);
        $onu_info{$oid_name} = $onu_snmp_info{$onu_snmp_id}{$oid_name} || q{};
      }
      push @onu_list, { %onu_info };
    }
  }

  return \@onu_list;
}


#**********************************************************
=head2 _cdata_use_memory($attr) - Get OLT slots and connect ONU

  Arguments:
    $attr$data, $info_list

  Results:
    $value

=cut
#**********************************************************
sub _cdata_use_memory {
  my($data, $info_list)=@_;

  if ($info_list->{RAM_TOTAL}) {
    $data = 100 - (100 / $info_list->{RAM_TOTAL} * $data);

    $data .= ' %';
  }

  return $data;
}

#**********************************************************
=head2 _cdata_temperature($data, $attr) - Get OLT slots and connect ONU

  Arguments:
    $data,
    $attr

  Results:
    $value

=cut
#**********************************************************
sub _cdata_temperature {
  my ($data)=@_;

  $data //= 0;

  $data = int($data / 10);

  return $data;
}

1
