=head1 NAME

 Eltex snmp monitoring and managment

 DOCS:
   http://eltex.nsk.ru/support/knowledge/upravlenie-po-snmp.php

=head1 VERSION

  VERSION: 0.02
  UPDATED: 20191205

=cut

use strict;
use warnings FATAL => 'all';
use AXbills::Filters qw(bin2mac mac2dec serial2mac);
use AXbills::Base qw(_bp);
use JSON qw(decode_json);

our (
  $base_dir,
  $debug,
  %lang,
  $html,
  %ONU_STATUS_TEXT_CODES
);

#**********************************************************
=head2 _eltex_get_ports($attr) - Get OLT ports

=cut
#**********************************************************
sub _eltex_get_ports {
  my ($attr) = @_;
  #  show_hash($attr, { DELIMITER => '<br>' });
  my $ports_info = ();

  if ($attr->{MODEL_NAME} =~ /(^LTP-[8,4]X|MA4000)/) {
    $ports_info = _eltex_gpon_get_ports($attr);
    return \%{$ports_info};
  }
  my $count_oid = '.1.3.6.1.4.1.35265.1.21.1.8.0';
  my $ports_count = snmp_get({ %{$attr}, OID => $count_oid });
  $ports_count //= 0;
  my $oid = '1.3.6.1.4.1.35265.1.21';
  my @ports_snmp_id = (
    '2.2',
    '2.3',
    '3.2',
    '3.3',
    '4.2',
    '4.3',
    '5.2',
    '4.3'
  );

  my %ports_info_oids = (
    PORT_STATUS => '',
    IN          => '',
    OUT         => '',
    PORT_SPEED  => '.4.0',
    BRANCH_DESC => '.1.0',
  );

  my %speed_type = (2 => '1Gbps', 3 => '2Gbps');
  for (my $i = 0; $i < $ports_count; $i++) {
    my $snmp_id = $ports_snmp_id[ $i ];
    foreach my $type (keys %ports_info_oids) {
      my $type_id = $ports_info_oids{ $type };
      next if (!$type_id);
      $ports_info->{$i}->{$type} = snmp_get({ %{$attr}, OID => $oid . '.' . $snmp_id . $type_id });
      if ($type eq 'PORT_SPEED') {
        #        _bp('', \$ports_info->{$i}->{$type}, {TO_CONSOLE=>1});
        $ports_info->{$i}->{$type} = $speed_type{ $ports_info->{$i}->{$type} };
      }
    }
    $ports_info->{$i}{BRANCH}   = "0/$i";
    $ports_info->{$i}{PON_TYPE} = 'gepon';
    $ports_info->{$i}{SNMP_ID}  = $i;
  }
  $ports_info->{255}{BRANCH}   = 'ANY';
  $ports_info->{255}{PON_TYPE} = 'gepon';
  $ports_info->{255}{SNMP_ID}  = 255;
  $ports_info->{255}{BRANCH_DESC} = 'Not assigned to any tree';

  return \%{$ports_info};
}


#**********************************************************
=head2 _eltex_ltp_get_ports($attr) - Get OLT ports

=cut
#**********************************************************
#sub _eltex_ltp_get_ports {
#  my ($attr) = @_;
#  my $ports_info = equipment_test({
#    %{$attr},
#    TIMEOUT   => 5,
#    VERSION   => 2,
#    PORT_INFO => 'PORT_NAME,PORT_TYPE,PORT_DESCR,PORT_STATUS,PORT_SPEED,IN,OUT'
#  });

#  #  _bp('', \$ports_info, {HEADER=>1});
#  foreach my $key (keys %{$ports_info}) {
#    if ($ports_info->{$key}{PORT_TYPE} && $ports_info->{$key}{PORT_TYPE} =~ /^250$/ && $ports_info->{$key}{PORT_NAME} =~ /PON channel (\d+)/) {
#      my $type = 'gpon';
#      #my $branch = decode_port($key);
#      $ports_info->{$key}{BRANCH} = "0/$1";
#      $ports_info->{$key}{PON_TYPE} = $type;
#      $ports_info->{$key}{SNMP_ID} = $key;
#      $ports_info->{$key}{BRANCH_DESC} = $ports_info->{$key}{PORT_DESCR};
#    }
#    else {
#      delete($ports_info->{$key});
#    }
#  }
#
#  return $ports_info;
#}

#**********************************************************
=head2 _eltex_gpon_get_ports($attr) - Get OLT ports

=cut
#**********************************************************
sub _eltex_gpon_get_ports {
  my ($attr) = @_;
  my $ports_info = ();
  my $ports_tmp = ();

  my $ports = snmp_get({
    %{$attr},
    OID => '1.3.6.1.4.1.35265.1.22.2.1.1.1', #ltp8xPONChannelSlot
    WALK => 1
  });
  foreach my $key (@$ports) {
    my ($snmp_id, $value) = split(/:/, $key, 2);
    $ports_tmp->{$snmp_id}{SNMP_ID} = $snmp_id;
    $ports_tmp->{$snmp_id}{CHANNEL_SLOT} = $value;
  }

  my $ports_channel_id = snmp_get({
    %{$attr},
    OID => '1.3.6.1.4.1.35265.1.22.2.1.1.2', #ltp8xPONChannelID
    WALK => 1
  });
  foreach my $key (@$ports_channel_id) {
    my ($snmp_id, $value) = split(/:/, $key, 2);
    $ports_tmp->{$snmp_id}{CHANNEL_ID} = $value;
  }

  my $ports_ont_count = snmp_get({
    %{$attr},
    OID => '1.3.6.1.4.1.35265.1.22.2.1.1.4', #ltp8xPONChannelONTCount
    WALK => 1
  });
  foreach my $key (@$ports_ont_count) {
    my ($snmp_id, $value) = split(/:/, $key, 2);
    $ports_tmp->{$snmp_id}{ONU_COUNT} = $value;
  }

  my $ports_status = snmp_get({
    %{$attr},
    OID => '1.3.6.1.4.1.35265.1.22.2.1.1.5', #ltp8xPONChannelEnabled
    WALK => 1
  });
  foreach my $key (@$ports_status) {
    my ($snmp_id, $value) = split(/:/, $key, 2);
    $ports_tmp->{$snmp_id}{PORT_STATUS} = $value;
  }

  foreach my $key (sort keys %{$ports_tmp}) {
    my $id = $ports_tmp->{$key}{CHANNEL_SLOT}*8 + $ports_tmp->{$key}{CHANNEL_ID} + 1;
    $ports_info->{$id}{BRANCH} = $ports_tmp->{$key}{CHANNEL_SLOT} . '/' . $ports_tmp->{$key}{CHANNEL_ID};
    $ports_info->{$id}{ONU_COUNT} = $ports_tmp->{$key}{ONU_COUNT};
    $ports_info->{$id}{onu_count} = $ports_tmp->{$key}{ONU_COUNT};
    $ports_info->{$id}{PON_TYPE} = 'gpon';
    $ports_info->{$id}{PORT_STATUS} = $ports_tmp->{$key}{PORT_STATUS};
  }

  return $ports_info;
}

#**********************************************************
=head2 _eltex_onu_list($attr)

  Arguments:
    $attr
      COLS       - ARRAY refs
      INFO_OIDS  - Hash refs
      NAS_ID

=cut
#**********************************************************
sub _eltex_onu_list {
  my ($port_list, $attr) = @_;

  #my $debug     = $attr->{DEBUG} || 0;
  my @all_rows  = ();
  my %pon_types = ();
  my %port_ids  = ();
  my $type = '';
  my $port_list_2 = ();
  my $list_ont_id = ();

  if ($port_list) {
    foreach my $snmp_id (keys %{$port_list}) {
      $pon_types{ $port_list->{$snmp_id}{PON_TYPE} } = 1;
      $port_ids{$port_list->{$snmp_id}{BRANCH}} = $port_list->{$snmp_id}{ID};
    }
  }

  foreach my $pon_type (keys %pon_types) {
    my $snmp = _eltex({ TYPE => $pon_type });

    my $onu_status_list = snmp_get({ %$attr,
      WALK => 1,
      OID  => '.1.3.6.1.4.1.35265.1.21.6.10.1.8',
    });

    if (!@$onu_status_list) {
      $onu_status_list = snmp_get({ %$attr,
        WALK => 1,
        OID  => '.1.3.6.1.4.1.35265.1.22.3.1.1.5',
      })
    }

    my $onu_mac_list = snmp_get({ %$attr,
      WALK => 1,
      OID  => '.1.3.6.1.4.1.35265.1.21.16.2.1.3',
    });

    if (!@$onu_mac_list) {
      $onu_mac_list = snmp_get({ %$attr,
        WALK => 1,
        OID  => '.1.3.6.1.4.1.35265.1.22.3.1.1.2',
      });
      $type = 1;
    }

    my %onu_cur_status = ();
    if ($type ne '') {
      $port_list_2 = snmp_get({ %$attr,
        WALK => 1,
        OID  => '1.3.6.1.4.1.35265.1.22.3.1.1.3', #ltp8xONTStateChannel
      });

      foreach my $line (@$port_list_2) {
        next if (!$line);
        my ($index, $port) = split(/:/, $line);
        my @oid_octets = split(/\./, $index);

        my $onu_id;
        if ($attr->{MODEL_NAME} =~ /(^LTP-[8,4]X|MA4000)/) {
          $onu_id = $index;
          $onu_cur_status{$onu_id}{PORT} = (defined $port) ? $oid_octets[0]-1 . '/' . $port : 0;
        }
        else {
          $onu_id = $oid_octets[$#oid_octets];
          $onu_cur_status{$onu_id}{PORT} = ($port) ? $port + 1 : 0;
        }
      }

      $list_ont_id = snmp_get({ %$attr,
        WALK => 1,
        OID  => '1.3.6.1.4.1.35265.1.22.3.1.1.4', #ltp8xONTStateID
      });

      foreach my $line (@$list_ont_id) {
        next if (!$line);
        my ($index, $onu_id2) = split(/:/, $line);
        my $onu_id;
        if ($attr->{MODEL_NAME} =~ /(^LTP-[8,4]X|MA4000)/) {
          $onu_id = $index;
        }
        else {
          my @oid_octets2 = split(/\./, $index);
          my $onu_id = $oid_octets2[$#oid_octets2];
        }
        $onu_cur_status{$onu_id}{ONU_ID2} = ($onu_id2) ? $onu_id2 : 0;
      }

    }

    foreach my $line (@$onu_status_list) {
      next if (!$line);
      my ($index, $status) = split(/:/, $line);
      my ($port, $onu_id)  = split(/\./, $index);

      if ($type ne '') {
        $onu_id = $index;
        if ($attr->{MODEL_NAME} !~ /(^LTP-[8,4]X|MA4000)/) {
          $onu_id =~ s/\d+\.//g;
        }
      }

      $onu_cur_status{$onu_id}{STATUS} = $status;
      $onu_cur_status{$onu_id}{PORT}   = $port if (! $onu_cur_status{$onu_id}{PORT});
    }

    foreach my $line (@{$onu_mac_list}) {
      next if (!$line);
      my ($onu_id, $mac) = split(/:/, $line, 2);
      next if ($onu_cur_status{$onu_id}{STATUS} == 13);

      $type = $onu_id;
      if ($attr->{MODEL_NAME} !~ /(^LTP-[8,4]X|MA4000)/) {
        $onu_id =~ s/\d+\.//g;
      }
      my $onu_mac = '';
      my $onu_snmp_id = '';
      my %onu_info = ();

      if ($type eq '') {
        $onu_mac = bin2mac($mac);
        $onu_snmp_id = mac2dec($onu_mac);
      }
      else {
        $onu_mac = serial2mac($mac);
        $onu_snmp_id = $type;
      }

      my $port_prefix = ($attr->{MODEL_NAME} =~ /(^LTP-[8,4]X|MA4000)/) ? '' : '0/';
      $onu_info{PORT_ID} = (defined($onu_cur_status{$onu_id}{PORT})) ? $port_ids{$port_prefix . $onu_cur_status{$onu_id}{PORT}} : $port_ids{ANY};

      $onu_info{ONU_ID}         = $onu_cur_status{$onu_id}{ONU_ID2}; #$onu_id;
      $onu_info{ONU_SNMP_ID}    = $onu_snmp_id;
      $onu_info{PON_TYPE}       = $pon_type;
      $onu_info{ONU_MAC_SERIAL} = $onu_mac;
      $onu_info{ONU_DHCP_PORT}  = $onu_id;

      foreach my $oid_name (keys %{$snmp}) {
        if ($oid_name eq 'reset' || $oid_name eq 'main_onu_info' || $oid_name eq 'ONU_MAC_SERIAL' || !$onu_cur_status{$onu_id}{STATUS} && $oid_name ne 'ONU_DESC') {
          next;
        }
        elsif ($oid_name =~ /POWER|TEMPERATURE/ && $onu_cur_status{$onu_id}{STATUS} ne '7') {
          $onu_info{$oid_name} = '';
          next;
        }
        elsif ($oid_name eq 'STATUS') {
          $onu_info{$oid_name} = $onu_cur_status{$onu_id}{STATUS};
          next;
        }

        my $oid_value = '';
        if ($snmp->{$oid_name}->{OIDS}) {
          my $oid = '';
          if ($type ne '') {
            $oid = $snmp->{$oid_name}->{OIDS} . '.' . $type;
          }
          else {
            $oid = $snmp->{$oid_name}->{OIDS} . '.' . $onu_snmp_id;
          }

          $oid_value = snmp_get({ %{$attr}, OID => $oid, SILENT => 1 });
        }
        my $function = $snmp->{$oid_name}->{PARSER};
        if ($function && defined(&{$function})) {
          ($oid_value) = &{\&$function}($oid_value);
        }
        $onu_info{$oid_name} = $oid_value;
      }
      push @all_rows, { %onu_info };
    }
  }

  return \@all_rows;
}

#**********************************************************
=head2  _eltex_onu_status($pon_type)

=cut
#**********************************************************
sub _eltex_onu_status {
  my ($pon_type) = @_;

  my %status = ();
  if ($pon_type eq 'gepon') {
    %status = (
      0  => $ONU_STATUS_TEXT_CODES{OFFLINE},           #free
      1  => $ONU_STATUS_TEXT_CODES{ALLOCATED},         #allocated
      2  => $ONU_STATUS_TEXT_CODES{AUTH_IN_PROGRESS},  #authInProgress
      3  => $ONU_STATUS_TEXT_CODES{CFG_IN_PROGRESS},   #cfgInProgress
      4  => $ONU_STATUS_TEXT_CODES{AUTH_FAILED},       #authFailed
      5  => $ONU_STATUS_TEXT_CODES{CFG_FAILED},        #cfgFailed
      6  => $ONU_STATUS_TEXT_CODES{REPORT_TIMEOUT},    #reportTimeout
      7  => $ONU_STATUS_TEXT_CODES{ONLINE},            #ok
      8  => $ONU_STATUS_TEXT_CODES{AUTH_OK},           #authOk
      9  => $ONU_STATUS_TEXT_CODES{RESET_IN_PROGRESS}, #resetInProgress
      10 => $ONU_STATUS_TEXT_CODES{RESET_OK},          #resetOk
      11 => $ONU_STATUS_TEXT_CODES{DISCOVERED},        #discovered
      12 => $ONU_STATUS_TEXT_CODES{BLOCKED},           #blocked
      13 => $ONU_STATUS_TEXT_CODES{CHECK_NEW_FW},      #checkNewFw
      14 => $ONU_STATUS_TEXT_CODES{UNIDENTIFIED},      #unidentified
      15 => $ONU_STATUS_TEXT_CODES{UNCONFIGURED},      #unconfigured
    );
  }
  elsif ($pon_type eq 'gpon') {
    %status = (
      0  => $ONU_STATUS_TEXT_CODES{OFFLINE},           #free
      1  => $ONU_STATUS_TEXT_CODES{ALLOCATED},         #allocated
      2  => $ONU_STATUS_TEXT_CODES{AUTH_IN_PROGRESS},  #authInProgress
      3  => $ONU_STATUS_TEXT_CODES{AUTH_FAILED},       #authFailed
      4  => $ONU_STATUS_TEXT_CODES{AUTH_OK},           #authOk
      5  => $ONU_STATUS_TEXT_CODES{CFG_IN_PROGRESS},   #cfgInProgress
      6  => $ONU_STATUS_TEXT_CODES{CFG_FAILED},        #cfgFailed
      7  => $ONU_STATUS_TEXT_CODES{ONLINE},            #ok
      8  => $ONU_STATUS_TEXT_CODES{FAILED},            #failed
      9  => $ONU_STATUS_TEXT_CODES{BLOCKED},           #blocked
      10 => $ONU_STATUS_TEXT_CODES{MIBRESET},          #mibreset
      11 => $ONU_STATUS_TEXT_CODES{PRECONFIG},         #preconfig
      12 => $ONU_STATUS_TEXT_CODES{FW_UPDATING},       #fwUpdating
      13 => $ONU_STATUS_TEXT_CODES{UNACTIVATED},       #unactivated
      14 => $ONU_STATUS_TEXT_CODES{REDUNDANT},         #redundant
      15 => $ONU_STATUS_TEXT_CODES{DISABLED},          #disabled
      16 => $ONU_STATUS_TEXT_CODES{UNKNOWN}            #unknown
    )
  }

  return \%status;
}

#**********************************************************
=head2 _eltex($attr)

=cut
#**********************************************************
sub _eltex {
  my ($attr) = @_;
  my $TEMPLATE_DIR = $base_dir . 'AXbills/modules/Equipment/snmp_tpl/';

  my $file_content = file_op({
    FILENAME   => 'eltex.snmp',
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
=head2 _dec_div($value);

  Arguments:
    $value

=cut
#**********************************************************
sub _dec_div {
  my ($value) = @_;

  $value = $value * 0.1 if ($value);

  return $value;
}


#**********************************************************
=head2 _eltex_convert_volt($volt);

  Arguments:
    $volt

=cut
#**********************************************************
sub _eltex_convert_volt {
  my ($volt) = @_;

  $volt = $volt * 0.01 if ($volt);

  return $volt;
}

#**********************************************************
=head2 _eltex_convert_power($power);

=cut
#**********************************************************
sub _eltex_convert_power {
  my ($power) = @_;

  $power = $power * 0.001 if ($power);

  return $power;
}

#**********************************************************
=head2 _eltex_convert_video_power($power);

=cut
#**********************************************************
sub _eltex_convert_video_power {
  my ($power) = @_;

  return undef if ( !defined($power) || $power == 32767 );

  $power = $power * 0.001 if ($power);

  return $power;
}

#**********************************************************
=head2 _eltex_convert_rf_port_status($power);

=cut
#**********************************************************
sub _eltex_convert_rf_port_status {
  my ($status_code) = @_;

  return undef if (!$status_code);

  my %status = (
    1   => 'on:text-green',
    2   => 'off',
    255 => 'n/a'
  );

  return $status{$status_code};
}

#**********************************************************
=head2 _eltex_convert_onu_type($id);

=cut
#**********************************************************
sub _eltex_convert_onu_type {
  my ($id) = @_;

  my @types = ('',
    'nte-2',
    'nte-2c',
    'nte-rg-1400f',
    'nte-rg-1400g',
    'nte-rg-1400f-w',
    'nte-rg-1400g-w',
    'nte-rg-1400fc',
    'nte-rg-1400gc',
    'nte-rg-1400fc-w',
    'nte-rg-1400gc-w',
    'nte-rg-1402f',
    'nte-rg-1402g',
    'nte-rg-1402f-w',
    'nte-rg-1402g-w',
    'nte-rg-1402fc',
    'nte-rg-1402gc',
    'nte-rg-1402fc-w',
    'nte-rg-1402gc-w',
    'nte-rg-2400g',
    'nte-rg-2400g-w',
    'nte-rg-2400g-w2',
    'nte-rg-2402g',
    'nte-rg-2402g-w',
    'nte-rg-2402g-w2',
    'nte-rg-2400gc',
    'nte-rg-2400gc-w',
    'nte-rg-2400gc-w2',
    'nte-rg-2402gc',
    'nte-rg-2402gc-w',
    'nte-rg-2402gc-w2',
    'nte-rg-2402gb',
    'nte-rg-2402gb-w',
    'nte-rg-2402gb-w2',
    'nte-rg-2402gcb',
    'nte-rg-2402gcb-w',
    'nte-rg-2402gcb-w2'
  );
  return $types[$id];
}

#**********************************************************
=head2 _eltex_unregister($attr);

  Arguments:
    $attr

  Returns;
    \@unregister

=cut
#**********************************************************
sub _eltex_unregister {
  my ($attr) = @_;

  my @unregister = ();
  my @types = ('gpon', 'epon');
  foreach my $type (@types) {
    my $snmp = _eltex({ TYPE => $type });
    my $all_result = ();
    my $mac_serials = ();
    my @unreg_result = ();

    if ($snmp->{unregister}->{'ONU_STATUS'}->{OIDS}) {
      $all_result = snmp_get({
        SNMP_COMMUNITY => $attr->{SNMP_COMMUNITY},
        WALK           => 1,
        OID            => $snmp->{unregister}->{'ONU_STATUS'}->{OIDS},
        TIMEOUT        => 5
      });
    }

    if ($snmp->{'ONU_MAC_SERIAL'}->{OIDS}) {
      $mac_serials = snmp_get({
        SNMP_COMMUNITY => $attr->{SNMP_COMMUNITY},
        WALK           => 1,
        OID            => $snmp->{'ONU_MAC_SERIAL'}->{OIDS},
        TIMEOUT        => 5
      });
    }

    my $port_list = snmp_get({ %$attr,
      WALK => 1,
      OID  => '1.3.6.1.4.1.35265.1.22.3.1.1.3', #ltp8xONTStateChannel
    });

    foreach my $line (@$all_result) {
      next if (!$line);
      #$id, $value
      my (undef, $value) = split(/:/, $line);

      if ($value eq '13') {
        push @unreg_result, $line;
      }
    }

    my %onus;

    foreach my $line (@unreg_result) {
      next if (!$line);
      my ($snmp_id, undef) = split(/:/, $line);

      #$mac_serial, $mac_bin
      my ($mac_serial, undef) = split(/:/, $line);
      #$snmp_port_id, $onu_id
      my ($snmp_port_id, undef) = split(/\./, $mac_serial, 2);
      my $branch = $snmp_port_id;

      $onus{$snmp_id} = {
        type       => $type,
        branch     => $branch,
        mac_serial => $mac_serial,
      }
    }

    foreach my $line (@{$mac_serials}) {
      next if (!$line);
      my ($snmp_id, $mac) = split(/:/, $line);
      my $onu_mac = serial2mac($mac);
      if($onus{$snmp_id}) {
        $onus{$snmp_id}{mac_serial} = $onu_mac;
      }
    }

    foreach my $line (@{$port_list}) {
      next if (!$line);
      my ($snmp_id, $port) = split(/:/, $line);
      my @oid_octets = split(/\./, $snmp_id);
      if($onus{$snmp_id}) {
        $onus{$snmp_id}{branch} = (defined $port) ? $oid_octets[0]-1 . '/' . $port : 0;
      }
    }

    foreach my $key (keys %onus) {
      push @unregister, $onus{$key};
    }
  }
  return \@unregister;
}

#**********************************************************
=head2 _eltex_unregister_form($attr) - Pre register form

  Arguments:
    $attr
      BRANCH_NUM
      DEBUG

=cut
#**********************************************************
sub _eltex_unregister_form {
  my ($attr) = @_;

  $debug = $attr->{DEBUG} || 0;

  my $onu_templates = snmp_get({
    SNMP_COMMUNITY => $attr->{SNMP_COMMUNITY},
    OID => '1.3.6.1.4.1.35265.1.22.3.24.1.1.2',
    WALK => 1,
    TIMEOUT => 5
  });

  @{$onu_templates} = map {(split (/:/, $_, 2))[1]} @{$onu_templates};

  $attr->{PON_TYPE}   = $attr->{TYPE} || qq{};
  $attr->{MAC}        = $attr->{MAC_SERIAL} || qq{};
  $attr->{ACTION}     = 'onu_registration';
  $attr->{ACTION_LNG} = $lang{ADD};
  $attr->{BRANCH}     = $attr->{BRANCH} || 0;
  $attr->{ONU_TEMPLATE}   = $html->form_select(
    'ONU_TEMPLATE',
    {
      SEL_ARRAY => $onu_templates
    }
  );

  my $template = ($conf{EQUIPMENT_ELTEX_SNMP_REGISTRATION}) ? 'equipment_registred_onu_eltex_snmp' : 'equipment_registred_onu_eltex';
  $html->tpl_show(_include($template, 'Equipment'), $attr);

  return 1;
}

1
