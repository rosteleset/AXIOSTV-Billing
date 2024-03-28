=head1 qtech

  qtech
  MODEL:
    epon
      QSW-9001

  DATE: 20240601
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
=head2 _qtech_get_ports($attr) - Get OLT slots and connect ONU

  Arguments:
    $attr

  Results:
    $ports_info_hash_ref

=cut
#**********************************************************
sub _qtech_get_ports {
  my ($attr) = @_;
  my $res = ();

  my $ports_info = equipment_test({
    %{$attr},
    TIMEOUT   => 5,
    VERSION   => 2,
    PORT_INFO => 'PORT_NAME,PORT_TYPE,PORT_DESCR,PORT_STATUS,PORT_SPEED,PORT_ALIAS,TRAFFIC,PORT_IN_ERR,PORT_OUT_ERR'
  });

  if ($attr->{MODEL_NAME} =~ 'QSW-9001') {
    foreach my $key (sort keys %{$ports_info}) {
      if ($ports_info->{$key}{PORT_NAME} && $ports_info->{$key}{PORT_NAME} =~ /^p((\d+)\/(\d+))$/) {
        $ports_info->{$key}{PON_TYPE} = 'epon';
        $ports_info->{$key}{BRANCH} = $1;
        $ports_info->{$key}{BRANCH_DESC} = $ports_info->{$key}{PORT_NAME};
        my $onus = snmp_get({
          %{$attr},
          OID => "1.3.6.1.4.1.27514.1.13.3.5.1.2.0.$2.$3",
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
=head2 _qtech_onu_list($port_list, $attr)

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
sub _qtech_onu_list {
  my ($port_list, $attr) = @_;
  my @onu_list = ();
  my %port_ids = ();
  my $debug = $attr->{DEBUG} || 0;
  my $telnet_session_open = '0';

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

  if ($attr->{MODEL_NAME} =~ 'QSW-9001') {
    $snmp = _qtech({TYPE => 'epon', TEMPLATE => 'qtech.snmp'});
    $pon_type = 'epon';
  } else { exit 0; }

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
        VERSION => 2,
	DEBUG => $debug
      });

      foreach my $line (@$result) {
        my (undef, $value) = split(/:/, $line, 2);
        my ($port_index, $onu_index) = $line =~ /(\d+\.\d+)\.(\d+)/;
        my $function = $snmp->{$oid_name}->{PARSER};

        if ($function && defined(&{$function})){
          ($value) = &{\&$function}($value, "$port_index.$onu_index", $attr);
        }

        $onu_snmp_info{$port_index}{$onu_index}{$oid_name} = $value;

	if (($oid_name eq 'ONU_RX_POWER') && (!$value || $value == 0)) {
	   $onu_snmp_info{$port_index}{$onu_index}{$oid_name} = _qtech_get_power_telnet($attr, "$port_index.$onu_index", $telnet_session_open);
           $telnet_session_open++;
	}
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
=head2 _qtech($attr)

  Arguments:
    $attr
      TYPE - PON type. If set, returns only that OID's

=cut
#**********************************************************
sub _qtech {
  my ($attr) = @_;
  my $TEMPLATE_DIR = $base_dir . 'AXbills/modules/Equipment/snmp_tpl/';
  my $template = $attr->{TEMPLATE} || 'qtech.snmp';

  my $file_content = file_op({
    FILENAME   => $template,
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
=head2 _qtech_onu_status()

=cut
#**********************************************************
sub _qtech_onu_status {
  my %status = (
    0 => $ONU_STATUS_TEXT_CODES{OFFLINE}, #down
    1 => $ONU_STATUS_TEXT_CODES{ONLINE}   #up
  );

  return \%status;
}

#**********************************************************
=head2 _qtech_convert_distance($distance)

=cut
#**********************************************************
sub _qtech_convert_distance {
  my ($distance) = @_;

  $distance //= 0;

  if ($distance =~ /(\d+)/) {
	$distance = ($distance - 100) * 0.001;
  	if ($distance > '1000') {
  		$distance .= ' km';
  	} else { 
		$distance = $distance * 1000;
		$distance .= ' meters';
  	}
  }

  return $distance;
}

#**********************************************************
=head2 _qtech_convert_voltage($voltage)

=cut
#**********************************************************
sub _qtech_convert_voltage {
  my ($voltage) = @_;

  $voltage //= 0;

#  $voltage = $voltage * 0.01;
  $voltage = $voltage * 1;
  $voltage .= ' V';
  return $voltage;
}

#**********************************************************
=head2 _qtech_convert_power();

=cut
#**********************************************************
sub _qtech_convert_power {
  my ($power) = @_;

  return 0 if (!$power);

  if ($power > '0') { 
  $power = $power * 0.01;
  	$power = 10 * (log($power/1)/(log(10)));
  	$power = sprintf("%.2f", $power);
  }

  return $power;
}

#**********************************************************
=head2 _qtech_get_power_telnet();

=cut
#**********************************************************
sub _qtech_get_power_telnet {
  my ($attr, $onu_index, $skip_login) = @_;

  $skip_login = $skip_login || 0;
  my $Telnet;
  my $power;
  my $user_name = $attr->{NAS_MNG_USER};
  my $password = $conf{EQUIPMENT_OLT_PASSWORD} || $attr->{NAS_MNG_PASSWORD};
  my $enable_password = $conf{EQUIPMENT_BDCOM_ENABLE_PASSWORD} || $password;
  my ($ip) = split(/:/, $attr->{NAS_MNG_IP_PORT});

  return 0 if (!$onu_index);
  return 0 if (!$attr);
  return 0 if (!$attr->{NAS_MNG_USER});
  return 0 if (!$password);
  return 0 if (!$ip);

  $onu_index =~ tr/./\//;

#  if ($skip_login == '0') {

   my $load_data = load_pmodule('Net::Telnet::Cisco', { SHOW_RETURN => 1 });
   if ($load_data) {
  	print "$load_data";
  	return [];
   }

   $Telnet = Net::Telnet::Cisco->new(
   	Host => $ip,
   	Port => '23',
	Timeout => 15,
	Prompt => '/.*(#|>)$/'
   );

   $Telnet->waitfor_pause(1);
   $Telnet->print($user_name);
   print "user logged\n";
   $Telnet->print($password);
   print "went thru\n";
   $Telnet->cmd('enable');
   $Telnet->print($enable_password);
   $Telnet->cmd('conf t');
#  }

      # Execute a command
   $Telnet->cmd("onu $onu_index");
   my @cmd_output = $Telnet->cmd( 'sh onu-opm-diagnosis' );

   foreach my $line (@cmd_output) {
       next if ($line !~ m/RX/i);
       (undef, $power) = split(/:/, $line, 2);
       ($power, undef) = split(/\(/, $power, 2);
        $power =~ s/[^.0-9]+//g;

	if ($power > '0') {
	    $power = $power * 100;
	    $power = _qtech_convert_power($power);
	} else { return 0; }
      }

      $Telnet->close;
 
  print "onu $onu_index $power\n";
  return $power;
}

#**********************************************************
=head2 _cdata_convert_power();

=cut
#**********************************************************
sub _qtech_convert_temp {

  my ($temp) = @_;
  return 0 if (!$temp);

  $temp = $temp * 0.01 if ($temp > '100');
  return $temp;
}

1

