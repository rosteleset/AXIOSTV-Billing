=head1 NAME

  Smartfiber

=cut

use strict;
use warnings;
use AXbills::Base qw(in_array);
use AXbills::Filters qw(bin2mac _mac_former dec2hex);
use Equipment::Misc qw(equipment_get_telnet_tpl);
require Equipment::Snmp_cmd;
use JSON qw(decode_json);

our (
  $base_dir,
  %lang,
  $html,
  %conf,
  %ONU_STATUS_TEXT_CODES
);

#**********************************************************
=head2 _smartfiber_get_ports($attr) - Get OLT slots and connect ONU

  Arguments:
    $attr

  Results:
    $ports_info_hash_ref

=cut
#**********************************************************
sub _smartfiber_get_ports {
  my ($attr) = @_;

  my $ports_info = equipment_test({
    %{$attr},
    TIMEOUT   => 5,
    VERSION   => 2,
    PORT_INFO => 'PORT_NAME,PORT_TYPE,PORT_DESCR,PORT_STATUS,PORT_SPEED,IN,OUT,PORT_IN_ERR,PORT_OUT_ERR'
  });

  foreach my $key (keys %{$ports_info}) {
    if ($ports_info->{$key}{PORT_NAME} =~ /(.pon)(\d+\/\d+\/\d+)$/i) {
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
=head2 _smartfiber_onu_list($port_list, $attr)

  Arguments:
    $port_list  - OLT ports list
    $attr
      COLS       - ARRAY refs
      INFO_OIDS  - Hash refs
      QUERY_OIDS
      NAS_ID
      TIMEOUT

  Returns:
    $onu_list [arra_of_hash]

=cut
#**********************************************************
sub _smartfiber_onu_list {
  my ($port_list, $attr) = @_;

  my $debug = $attr->{DEBUG} || 0;
  my @onu_list = ();

  my $saved_pon_type = '';

  foreach my $snmp_key (keys %{$port_list}) {
    my $snmp_id = substr $port_list->{$snmp_key}{BRANCH_DESC}, -1;
    my $pon_type = $port_list->{$snmp_key}{PON_TYPE};
    $saved_pon_type = $pon_type;
    my $snmp = _smartfiber({ TYPE => $pon_type, MODEL => $attr->{MODEL_NAME} });

    if ($attr->{QUERY_OIDS} && @{$attr->{QUERY_OIDS}}) {
      %$snmp = map {$_ => $snmp->{$_}} @{$attr->{QUERY_OIDS}};
    }

    if (!$snmp->{ONU_STATUS}->{OIDS}) {
      print "$pon_type: no oids\n" if ($debug > 0);
      next;
    }
    my @cols = ('PORT_ID', 'ONU_ID', 'ONU_SNMP_ID', 'PON_TYPE');

    #Get info
    my %onu_snmp_info = ();
    foreach my $oid_name (keys %{$snmp}) {
      next if ($oid_name eq 'main_onu_info' || $oid_name eq 'reset');
      next if ($snmp->{$oid_name}{PARSE_AFTER});
      push @cols, $oid_name;

      if ($snmp->{$oid_name}->{OIDS}) {
        my $oid = $snmp->{$oid_name}->{OIDS};
        print "$oid_name -- " . ($snmp->{$oid_name}->{NAME} || 'Unknown oid') . '--' . ($snmp->{$oid_name}->{OIDS} || 'unknown') . " \n" if ($debug > 1);

        my $result = snmp_get({
          %{$attr},
          OID     => $oid . '.' . $snmp_id,
          VERSION => 2,
          WALK    => 1
        });

        foreach my $line (@$result) {
          next if (!$line);
          my ($onu_index, $value) = split(/:/, $line, 2);
          my $function = $snmp->{$oid_name}->{PARSER};

          if (!defined($value)) {
            print ">> $line\n";
          }

          if ($function && defined(&{$function})) {
            ($value) = &{\&$function}($value);
          }

          $onu_snmp_info{$oid_name}{$snmp_id . '.' . $onu_index} = $value;
        }
      }
    }


    foreach my $key (keys %{$onu_snmp_info{ONU_STATUS}}) {
      my %onu_info = ();

      my ($branch, $onu_id) = split(/\./, $key, 2);
      for (my $i = 0; $i <= $#cols; $i++) {
        my $value = '';
        my $oid_name = $cols[$i];
        if ($oid_name eq 'ONU_ID') {
          $value = $onu_id;
        }
        elsif ($oid_name eq 'PORT_ID') {
          $value = $port_list->{$snmp_key}->{ID};
        }
        elsif ($oid_name eq 'PON_TYPE') {
          $value = $pon_type;
        }
        elsif ($oid_name eq 'ONU_SNMP_ID') {
          $value = $key;
        }
        else {
          $value = $onu_snmp_info{$cols[$i]}{$key};
        }
        $onu_info{$oid_name} = $value;
      }
      push @onu_list, { %onu_info };
    }
  }

  @onu_list = sort {
    substr(reverse($a->{ONU_SNMP_ID}), -1) cmp substr(reverse($b->{ONU_SNMP_ID}), -1)
      or
    $a->{ONU_ID} <=> $b->{ONU_ID}
  } @onu_list;

  return \@onu_list;
}

#**********************************************************
=head2 _smartfiber($attr)

  Arguments:
    $attr
      TYPE - PON type (epon, gpon)
      MODEL - OLT model

=cut
#**********************************************************
sub _smartfiber {
  my ($attr) = @_;
  my $TEMPLATE_DIR = $base_dir . 'AXbills/modules/Equipment/snmp_tpl/';

  my $file_content = file_op({
    FILENAME   => 'smartfiber.snmp',
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
=head2 _smartfiber_pon_vlan() - Tempory VLAN function

=cut
#**********************************************************
sub _smartfiber_pon_vlan {

  return q{};
}

#**********************************************************
=head2 _smartfiber_sec2time($sec)

=cut
#**********************************************************
sub _smartfiber_sec2time {
  my ($sec)=@_;

  return sec2time($sec, { str => 1 });
}

#**********************************************************
=head2 _smartfiber_onu_status()

=cut
#**********************************************************
sub _smartfiber_onu_status {
  my ($pon_type) = @_;

  my %status = ();

  %status = (
    0 => $ONU_STATUS_TEXT_CODES{OFFLINE},
    1 => $ONU_STATUS_TEXT_CODES{ONLINE}
  );

  return \%status;
}

#**********************************************************
=head2 _smartfiber_set_desc($attr) - Set Description to OLT ports

  Arguments:
    $attr

  Returns:
    TRUE or FALSE

=cut
#**********************************************************
sub _smartfiber_set_desc {
  my ($attr) = @_;

  my $oid = $attr->{OID} || '';

  if ($attr->{PORT}) {
    $oid = '1.3.6.1.2.1.31.1.1.1.18.' . $attr->{PORT};
  }

  my $result = snmp_set({
    %$attr,
    SNMP_COMMUNITY => $attr->{SNMP_COMMUNITY},
    OID            => [ $oid, "string", "$attr->{DESC}" ]
  });

  return $result;
}

#**********************************************************
=head2 _smartfiber_convert_power();

=cut
#**********************************************************
sub _smartfiber_convert_power {
  my ($power) = @_;
  $power //= 0;

  $power =~ /(\d+.\d+) dBm/;
  $power = -$1;

  return $power;
}

#**********************************************************
=head2 _smartfiber_convert_temperature();

=cut
#**********************************************************
sub _smartfiber_convert_temperature {
  my ($temperature) = @_;

  $temperature //= 0;
  $temperature = ($temperature / 256);
  $temperature = sprintf("%.2f", $temperature);

  return $temperature;
}

#**********************************************************
=head2 _smartfiber_convert_voltage();

=cut
#**********************************************************
sub _smartfiber_convert_voltage {
  my ($voltage) = @_;

  $voltage //= 0;
  $voltage = sprintf("%.2f", $voltage);
  $voltage .= ' V';

  return $voltage;
}

#**********************************************************
=head2 _smartfiber_convert_distance_epon();

=cut
#**********************************************************
sub _smartfiber_convert_distance_epon {
  my ($distance) = @_;

  $distance //= 0;

  $distance = $distance * 0.001;
  $distance .= ' km';
  return $distance;
}

#**********************************************************
=head2 _smartfiber_convert_distance_gpon();

=cut
#**********************************************************
sub _smartfiber_convert_distance_gpon {
  my ($distance) = @_;

  $distance //= 0;

  $distance = $distance * 0.0001;
  $distance .= ' km';
  return $distance;
}

#**********************************************************
=head2 _smartfiber_convert_onu_last_down_cause($last_down_cause_code)

=cut
#**********************************************************
sub _smartfiber_convert_onu_last_down_cause {
  my ($last_down_cause_code) = @_;

  my %last_down_cause_hash = (
    0  => '',
    1  => 'MPCP_TIMEOUT',
    2  => 'MPCP_RTT_DRIFT',
    3  => 'POWER_OFF',
    4  => 'AUTH_FAILED',
    5  => 'BLACKLIST',
    6  => 'GET_SN_FAILED',
    7  => 'CAP_FAILED',
  );

  return $last_down_cause_hash{$last_down_cause_code};
}

#**********************************************************
=head2 _smartfiber_unregister($attr) - get unregistered (rejected) ONUs

  Needed only when there are manual registration (gpon onu-authen-method sn, epon onu-authen-method mac)
  Uses Telnet, because there are no known SNMP OIDs for unregistered data

  Arguments:
    $attr
      NAS_INFO
        NAS_MNG_USER
        NAS_MNG_PASSWORD
        NAS_MNG_IP_PORT
        MODEL_NAME
      DEBUG

  Returns:
    \@unregister - arrayref of unregistered ONUs:
    [
      {
        pon_type   => ...
        mac_serial => ...
        branch     => ...
      },
      ...
    ]

=cut
#**********************************************************
sub _smartfiber_unregister {
  my ($attr) = @_;

  if (!$conf{EQUIPMENT_Smartfiber_ENABLE_ONU_REGISTRATION}) {
    return [];
  }

  my $debug = $attr->{DEBUG} || 0;

  my $load_data = load_pmodule('Net::Telnet', { SHOW_RETURN => 1 });
  if ($load_data) {
    print "$load_data";
    return [];
  }

  my $user_name = $attr->{NAS_INFO}->{NAS_MNG_USER};
  my $password = $conf{EQUIPMENT_OLT_PASSWORD} || $attr->{NAS_INFO}->{NAS_MNG_PASSWORD};
  my $enable_password = $conf{EQUIPMENT_Smartfiber_ENABLE_PASSWORD} || $password;

  my $Telnet = Net::Telnet->new(
    Prompt  => '/.*(#|>)$/',
    Timeout => 15,
    Errmode => 'return'
  );

  my ($ip) = split(/:/, $attr->{NAS_INFO}->{NAS_MNG_IP_PORT});

  $Telnet->open(
    Host => $ip
  );

  if ($Telnet->errmsg) {
    print "Telnet error: " . $Telnet->errmsg;
    return [];
  }

  $Telnet->login($user_name, $password);

  if ($Telnet->errmsg) {
    print "Telnet error: " . $Telnet->errmsg;
    return [];
  }

  $Telnet->print('enable');
  my ($waitfor_prematch, $waitfor_match) = $Telnet->waitfor(Match => '/(#|>)$/', String => 'password:');
  if ($waitfor_match eq 'password:') {
    $Telnet->print($enable_password);
    ($waitfor_prematch, $waitfor_match) = $Telnet->waitfor('/.*(#|>)$/');
  }

  if ($waitfor_match =~ />$/) {
    print "enable failed: $waitfor_prematch\n";
    return [];
  }

  my @unregister = ();
  if ($attr->{NAS_INFO}->{MODEL_NAME} =~ /\bGP/i) { #seems that model_name of GPON OLT always starts with GP
    my @rejected_onus = $Telnet->cmd('show gpon onu-rejected-information');
    foreach my $line (@rejected_onus) {
      if ($line =~ /\d+\s+([0-9A-F]{16})\s+GPON(\d+\/\d+)/) {
        push @unregister,
          {
            pon_type   => 'gpon',
            mac_serial => $1,
            branch     => $2
          };
      }
    }
  }
  else { #EPON
    my @rejected_onus = $Telnet->cmd('show epon rejected-onu');

    my $current_branch = '';
    foreach my $line (@rejected_onus) {
      if ($debug > 6) {
        print $line."\n";
      }

      if ($line =~ /ONU rejected to register on interface EPON(\d+\/\d+):/) {
        $current_branch = $1;
      }

      if ($line =~ /\s*([0-9a-f]{4}\.[0-9a-f]{4}\.[0-9a-f]{4})\s*/) {
        my $mac_serial = $1;
        $mac_serial =~ s/([0-9a-f]{2})([0-9a-f]{2})\.([0-9a-f]{2})([0-9a-f]{2})\.([0-9a-f]{2})([0-9a-f]{2})/$1:$2:$3:$4:$5:$6/;
        push @unregister,
          {
            pon_type   => 'epon',
            mac_serial => $mac_serial,
            branch     => $current_branch
          };
      }
    }
  }

  if ($Telnet->errmsg) {
    print "Telnet error: " . $Telnet->errmsg;
    return [];
  }

  $Telnet->close();

  return \@unregister;
}

#**********************************************************
=head2 _smartfiber_get_onu_config($attr) - Connect to OLT over telnet and get ONU config

  Arguments:
    $attr
      NAS_INFO
        NAS_MNG_IP_PORT
        NAS_MNG_USER
        NAS_MNG_PASSWORD
      PON_TYPE
      BRANCH
      ONU_ID

  Returns:
    @result - array of [cmd, cmd_result]

  commands (EPON):
    enable
    show running-config interface EPON %BRANCH%:%ONU_ID%

  commands (GPON):
    enable
    show running-config interface GPON %BRANCH%:%ONU_ID%


=cut
#**********************************************************
sub _smartfiber_get_onu_config {
  my ($attr) = @_;

  my $pon_type = $attr->{PON_TYPE};
  my $branch = $attr->{BRANCH};
  my $onu_id = $attr->{ONU_ID};

  my $username = $attr->{NAS_INFO}->{NAS_MNG_USER};
  my $password = $conf{EQUIPMENT_OLT_PASSWORD} || $attr->{NAS_INFO}->{NAS_MNG_PASSWORD};
  my $enable_password = $conf{EQUIPMENT_Smartfiber_ENABLE_PASSWORD} || $password;

  my ($ip, undef) = split (/:/, $attr->{NAS_INFO}->{NAS_MNG_IP_PORT}, 2);

  my @cmds = @{equipment_get_telnet_tpl({
    TEMPLATE => "smartfiber_get_onu_config_$pon_type.tpl",
    BRANCH   => $branch,
    ONU_ID   => $onu_id
  })};

  if (!@cmds) {
    @cmds = @{equipment_get_telnet_tpl({
      TEMPLATE => "smartfiber_get_onu_config_$pon_type.tpl.example",
      BRANCH   => $branch,
      ONU_ID   => $onu_id
    })};
  }

  if (!@cmds) {
    return ([$lang{ERROR}, $lang{FAILED_TO_GET_TELNET_CMDS_FROM_FILE} . " smartfiber_get_onu_config_$pon_type.tpl"]);
  }

  use AXbills::Telnet;

  my $t = AXbills::Telnet->new();

  $t->set_terminal_size(256, 1000); #if terminal size is small, Smartfiber does not print all of command output, but prints first *terminal_height* lines, prints '--More--' and lets user scroll it manually
  $t->prompt('\n.*(#|>)$');

  if (!$t->open($ip)) {
    $html->message('err', $lang{ERROR} . ' Telnet', $t->errstr());
    return ();
  }

  if (!$t->login($username, $password)) {
    $html->message('err', $lang{ERROR} . ' Telnet', $t->errstr());
    return ();
  }

  my @result = ();

  foreach my $cmd (@cmds) {
    if ($cmd eq 'enable') {
      $t->print('enable');
      my $waitfor_prematch = $t->waitfor('(\n.*(#|>)$)|password:$');
      my $waitfor_match = $t->{LAST_PROMPT};
      if ($waitfor_match eq 'password:') {
        $t->print($enable_password);
        $waitfor_prematch = $t->waitfor('\n.*(#|>)$');
        $waitfor_match = $t->{LAST_PROMPT};
      }

      if ($waitfor_match =~ />$/) {
        return [$lang{ERROR}, "enable failed: " . join("\n", @$waitfor_prematch)];
      }
      next;
    }

    my $cmd_result = $t->cmd($cmd);
    if ($cmd_result) {
      push @result, [$cmd, join("\n", @$cmd_result)];
    }
    else {
      push @result, [$cmd, $lang{ERROR} . ' Telnet: ' . $t->errstr()];
    }
  }

  if ($t->errstr()) {
    $html->message('err', $lang{ERROR} . ' Telnet', $t->errstr());
  }

  return @result;
}

#**********************************************************
=head2 _smartfiber_convert_catv_port_admin_status($status_code);

=cut
#**********************************************************
sub _smartfiber_convert_catv_port_admin_status {
  my ($status_code) = @_;

  my $status = 'Unknown';

  my %status_hash = (
    1 => 'Enable',
    2 => 'Disable',
  );

  if ($status_code && $status_hash{ $status_code }) {
    $status = $status_hash{ $status_code };
  }

  return $status;
}

#**********************************************************
=head2 _smartfiber_convert_video_power($video_power);

=cut
#**********************************************************
sub _smartfiber_convert_video_power {
  my ($video_power) = @_;

  return undef if (!defined $video_power || $video_power == 0);

  return $video_power * 0.1;
}

1
