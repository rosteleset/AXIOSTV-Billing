=head1 NAME

  PON Manage functions

=cut

use strict;
use warnings FATAL => 'all';
use AXbills::Base qw(load_pmodule in_array int2byte cmd);
use Time::Local qw(timelocal);

our (
  $db,
  $admin,
  %lang,
  %conf,
  %FORM,
  $index,
  @service_status,
  $SNMP_TPL_DIR,
  %permissions,
  %LIST_PARAMS,
  @MODULES,
  $pages_qs
);

our Equipment $Equipment;
#our Internet $Internet;
our AXbills::HTML $html;

require Equipment::Grabbers;

our %ONU_STATUS_TEXT_CODES = (
  'OFFLINE'             => 0,
  'ONLINE'              => 1,
  'AUTHENTICATED'       => 2,
  'REGISTERED'          => 3,
  'DEREGISTERED'        => 4,
  'AUTO_CONFIG'         => 5,
  'UNKNOWN'             => 6,
  'LOS'                 => 7,
  'SYNC'                => 8,
  'DYING_GASP'          => 9,
  'POWER_OFF'           => 10,
  'PENDING'             => 11,
  'ALLOCATED'           => 12,
  'AUTH_IN_PROGRESS'    => 13,
  'CFG_IN_PROGRESS'     => 14,
  'AUTH_FAILED'         => 15,
  'CFG_FAILED'          => 16,
  'REPORT_TIMEOUT'      => 17,
  'AUTH_OK'             => 18,
  'RESET_IN_PROGRESS'   => 19,
  'RESET_OK'            => 20,
  'DISCOVERED'          => 21,
  'BLOCKED'             => 22,
  'CHECK_NEW_FW'        => 23,
  'UNIDENTIFIED'        => 24,
  'UNCONFIGURED'        => 25,
  'FAILED'              => 26,
  'MIBRESET'            => 27,
  'PRECONFIG'           => 28,
  'FW_UPDATING'         => 29,
  'UNACTIVATED'         => 30,
  'REDUNDANT'           => 31,
  'DISABLED'            => 32,
  'LOST'                => 33,
  'STANDBY'             => 34,
  'INACTIVE'            => 35,
  'NOT_EXPECTED_STATUS' => 1000,
);
our %ONU_STATUS_CODE_TO_TEXT = (
  0    => 'Offline:text-red',
  1    => 'Online:text-green',
  2    => 'Authenticated:text-green',
  3    => 'Registered:text-green',
  4    => 'Deregistered:text-red',
  5    => 'Auto_config:text-green',
  6    => 'Unknown:text-orange',
  7    => 'LOS:text-red',
  8    => 'Synchronization:text-red',
  9    => 'Dying_gasp:text-red',
  10   => 'Power_Off:text-orange',
  11   => 'Pending',
  12   => 'Allocated',
  13   => 'Auth in progress',
  14   => 'Cfg in progress',
  15   => 'Auth failed',
  16   => 'Cfg failed',
  17   => 'Report timeout',
  18   => 'Auth ok',
  19   => 'Reset in progress',
  20   => 'Reset ok',
  21   => 'Discovered',
  22   => 'Blocked',
  23   => 'Check new fw',
  24   => 'Unidentified',
  25   => 'Unconfigured',
  26   => 'Failed',
  27   => 'Mibreset',
  28   => 'Preconfig',
  29   => 'Fw updating',
  30   => 'Unactivated',
  31   => 'Redundant',
  32   => 'Disabled',
  33   => 'Lost',
  34   => 'Standby',
  35   => 'Inactive',
  1000 => 'Not expected status:text-orange',
);

our @ONU_ONLINE_STATUSES = (
  $ONU_STATUS_TEXT_CODES{ONLINE},
  $ONU_STATUS_TEXT_CODES{REGISTERED},
  $ONU_STATUS_TEXT_CODES{AUTO_CONFIG},
  $ONU_STATUS_TEXT_CODES{AUTHENTICATED},
  $ONU_STATUS_TEXT_CODES{SYNC}
);

our @ONU_FIELDS = (
  'CATV_PORTS_ADMIN_STATUS',
  'CATV_PORTS_COUNT',
  'CATV_PORTS_STATUS',
  'CVLAN',
  'DISTANCE',
  'EQUIPMENT_ID',
  'ETH_ADMIN_STATE',
  'ETH_DUPLEX',
  'ETH_SPEED',
  'FIRMWARE',
  'HARD_VERSION',
  'LINE_PROFILE',
  'LLID',
  'MAC_BEHIND_ONU',
  'MODEL',
  'OLT_RX_POWER',
  'ONU_DESC',
  'ONU_IN_BYTE',
  'ONU_LAST_DOWN_CAUSE',
  'ONU_MAC_SERIAL',
  'ONU_NAME',
  'ONU_OUT_BYTE',
  'ONU_PORTS_STATUS',
  'ONU_RX_POWER',
  'ONU_STATUS',
  'ONU_TX_POWER',
  'ONU_TYPE',
  'RF_PORT_ON',
  'SOFT_VERSION',
  'SRV_PROFILE',
  'SVLAN',
  'TEMPERATURE',
  'UPTIME',
  'VENDOR',
  'VENDOR_ID',
  'VERSION_ID',
  'VIDEO_RX_POWER',
  'VOLTAGE',
);

our @PORT_FIELDS = (
  'PORT_STATUS',
  'ADMIN_PORT_STATUS',
  'PORT_IN',
  'PORT_OUT',
  'PORT_IN_ERR',
  'PORT_OUT_ERR',
  'PORT_IN_DISCARDS',
  'PORT_OUT_DISCARDS',
  'PORT_UPTIME',
  'CABLE_TESTER'
);

our @SW_FIELDS = (
  'DESCRIBE',
  'SYSTEM_ID',
  'UPTIME'
);

our @CHECKED_FIELDS = (
  'CATV_PORTS_STATUS',
  'DISTANCE',
  'OLT_RX_POWER',
  'ONU_DESC',
  'ONU_IN_BYTE',
  'ONU_LAST_DOWN_CAUSE',
  'ONU_MAC_SERIAL',
  'ONU_OUT_BYTE',
  'ONU_PORTS_STATUS',
  'ONU_RX_POWER',
  'ONU_STATUS',
  'TEMPERATURE',
  'UPTIME',
);

#********************************************************
=head2 equipment_pon_init($attr)

  Arguments:
    $attr
      VENDOR_NAME
      NAS_INFO
        NAME

  Return:

=cut
#********************************************************
sub equipment_pon_init {
  my ($attr) = @_;
  my $nas_type = '';

  unshift(@INC, '../../AXbills/modules/');

  my $vendor_name = $attr->{VENDOR_NAME} || $attr->{NAS_INFO}->{NAME} || q{};

  if (!$vendor_name) {
    return '';
  }

  if ($vendor_name =~ /ELTEX/i) {
    require Equipment::Eltex;
    $nas_type = '_eltex';
  }
  elsif ($vendor_name =~ /ZTE/i) {
    require Equipment::Zte;
    $nas_type = '_zte';
  }
  elsif ($vendor_name =~ /HUAWEI/i) {
    require Equipment::Huawei;
    $nas_type = '_huawei';
  }
  elsif ($vendor_name =~ /BDCOM/i) {
    require Equipment::Bdcom;
    $nas_type = '_bdcom';
  }
  elsif ($vendor_name =~ /V\-SOLUTION/i) {
    require Equipment::Vsolution;
    $nas_type = '_vsolution';
  }
  elsif ($vendor_name =~ /CDATA/i) {
    require Equipment::Cdata;
    $nas_type = '_cdata';
  }
  #elsif ($vendor_name =~ /STELS/i) {
  #  require Equipment::Stels;
  #  $nas_type = '_stels';
  #}
  elsif ($vendor_name =~ /GCOM/i) {
    require Equipment::Gcom;
    $nas_type = '_gcom';
  }
  elsif ($vendor_name =~ /RAISECOM/i) {
    require Equipment::Raisecom;
    $nas_type = '_raisecom';
  }
  elsif ($vendor_name =~ /SMARTFIBER/i) {
    require Equipment::Smartfiber;
    $nas_type = '_smartfiber';
  }
  elsif ($vendor_name =~ /QTECH/i) {
    require Equipment::Qtech;
    $nas_type = '_qtech';
  }

  return $nas_type;
}


#********************************************************
=head2 equipment_pon_get_ports($attr) - Show PON information

  Arguments:
    $attr
      SNMP_COMMUNITY
      NAS_INFO
      NAS_ID
      DEBUG

  Returns:
    $port_hash_ref

=cut
#********************************************************
sub equipment_pon_get_ports {
  my ($attr) = @_;

  my $port_list = $Equipment->pon_port_list({
    %$attr,
    COLS_NAME  => 1,
    COLS_UPPER => 1,
    NAS_ID     => $attr->{NAS_ID}
  });

  my $ports = ();
  foreach my $line (@$port_list) {
    $ports->{$line->{snmp_id}} = $line;
  }

  my $get_ports_fn = $attr->{NAS_TYPE} . '_get_ports';

  if (!$Equipment->{STATUS}) { #XXX check certain equipment statuses, not only Active
    if (defined(&{$get_ports_fn})) {
      my $olt_ports = &{\&$get_ports_fn}({
        %{($attr) ? $attr : {}},
        SNMP_COMMUNITY => $attr->{SNMP_COMMUNITY},
        SNMP_TPL       => $attr->{SNMP_TPL},
        MODEL_NAME     => $attr->{MODEL_NAME}
      });

      foreach my $snmp_id (keys %{$olt_ports}) {
        if (!$ports->{$snmp_id}) {
          $Equipment->pon_port_list({
            %$attr,
            COLS_NAME => 1,
            NAS_ID    => $attr->{NAS_ID},
            SNMP_ID   => $snmp_id
          });
          if (!$Equipment->{TOTAL}) {
            $Equipment->pon_port_add({ SNMP_ID => $snmp_id, NAS_ID => $attr->{NAS_ID}, %{$olt_ports->{$snmp_id}} });
            $olt_ports->{$snmp_id}{ID} = $Equipment->{INSERT_ID};
          }
        }
        else {
          if ($conf{EQUIPMENT_SNMP_WR} && $ports->{$snmp_id}{BRANCH_DESC} && $ports->{$snmp_id}{BRANCH_DESC} ne $olt_ports->{$snmp_id}{BRANCH_DESC}) {
            my $set_desc_fn = $attr->{NAS_TYPE} . '_set_desc';
            if (defined(&{$set_desc_fn})) {
              my $result = &{\&$set_desc_fn}({
                %{($attr) ? $attr : {}},
                SNMP_COMMUNITY => $attr->{SNMP_COMMUNITY},
                PORT           => $snmp_id,
                PORT_TYPE      => $ports->{$snmp_id}{PON_TYPE},
                DESC           => $ports->{$snmp_id}{BRANCH_DESC}
              });

              if (!$result) {
                $html->message('err', $lang{ERROR}, "Can't write port descr");
              }
            }
          }
        }

        foreach my $key (keys %{$olt_ports->{$snmp_id}}) {
          $ports->{$snmp_id}{$key} = $olt_ports->{$snmp_id}{$key};
        }
      }
    }
  }
  else {
    if ($html) {
      $html->message('warn', $lang{INFO}, "$lang{STATUS} $service_status[$Equipment->{STATUS}]");
    }
  }

  return $ports;
}

#********************************************************
=head2 _get_snmp_oid($type, $attr) - Get oid tpl

  Arguments:
    $type
    $attr
      BASE_DIR

=cut
#********************************************************
sub _get_snmp_oid {
  my ($type, $attr) = @_;

  #  if ( !$type ){
  #    return '';
  #  }
  my $path = ($attr->{BASE_DIR}) ? $attr->{BASE_DIR} . '/' : q{};

  my $def_content = file_op({
    FILENAME      => $path . $SNMP_TPL_DIR . '/default.snmp',
    PATH          => $path . $SNMP_TPL_DIR,
    SKIP_COMMENTS => '^\/\/'
  });

  my $def_result;
  if ($def_content) {
    load_pmodule("JSON");
    my $json = JSON->new->allow_nonref;
    $def_content =~ s#//.*$##gm;
    $def_result = $json->decode($def_content);
  }

  my $content;
  $content = file_op({
    FILENAME      => $path . $SNMP_TPL_DIR . '/' . $type,
    PATH          => $path . $SNMP_TPL_DIR,
    SKIP_COMMENTS => '^\/\/'
  }) if ($type);

  my $result = ();

  if ($content) {
    load_pmodule("JSON");
    my $json = JSON->new->allow_nonref;
    $content =~ s#//.*$##gm;
    $result = $json->decode($content);
  }
  my @array_keys = ('info', 'status', 'ports');
  foreach my $key (keys %{$def_result}) {
    if (in_array($key, \@array_keys)) {
      foreach my $key2 (keys %{$def_result->{$key}}) {
        $result->{$key}->{$key2} = $def_result->{$key}->{$key2} if (!$result->{$key}->{$key2});
      }
    }
    else {
      $result->{$key} = $def_result->{$key} if (!$result->{$key});
    }
  }

  return $result;
}


#********************************************************
=head2 equipment_pon($attr) - Show PON information

  Arguments:
    $attr
      SNMP_COMMUNITY
      NAS_INFO
      VENDOR_NAME
      DEBUG

  Returns:
    TRUE or FALSE

=cut
#********************************************************
sub equipment_pon {
  my ($attr) = @_;

  my $SNMP_COMMUNITY = $attr->{SNMP_COMMUNITY};
  my $nas_id = $FORM{NAS_ID};

  #For old version
  $Equipment->vendor_info($Equipment->{VENDOR_ID});
  if (!$attr->{VENDOR_NAME}) {
    $attr->{VENDOR_NAME} = $Equipment->{NAME};
  }

  if ($attr->{NAS_INFO}) {
    $attr->{VERSION} //= $attr->{NAS_INFO}->{SNMP_VERSION};
  }

  if ($FORM{DEBUG}) {
    $attr->{DEBUG} = $FORM{DEBUG};
  }

  my $nas_type = equipment_pon_init($attr);

  if (!$nas_type) {
    return 0;
  }
  my $snmp = &{\&{$nas_type}}({ TYPE => $FORM{ONU_TYPE}, MODEL => $attr->{NAS_INFO}{MODEL_NAME} });

  if ($FORM{unregister_list}) {
    equipment_unregister_onu_list($attr);
    return 1;
  }
  elsif ($FORM{onuReset}) {
    if ($snmp->{reset} && $snmp->{reset}->{OIDS}) {
      my $reset_result;
      if ($snmp->{reset}->{RESET_FN} && defined(&{$snmp->{reset}->{RESET_FN}})) {
        $reset_result = &{\&{$snmp->{reset}->{RESET_FN}}}({
          SNMP_INFO      => $snmp,
          SNMP_COMMUNITY => $SNMP_COMMUNITY,
          VERSION        => $attr->{VERSION},
          ONU_SNMP_ID    => $FORM{onuReset}
        });
      }
      elsif ($snmp->{reset}->{SEPARATE}) { #specific to Vsolution #XXX move to RESET_FN?
        $FORM{onuReset} =~ /(\d).(\d)/;
        my $pon_id = $1;
        my $onu_id = $2;

        $reset_result = snmp_set({
          SNMP_COMMUNITY => $SNMP_COMMUNITY,
          VERSION        => $attr->{VERSION},
          OID            => [ $snmp->{reset}->{OIDS} . '.1.0', $snmp->{reset}->{VALUE_TYPE} || "integer", $pon_id ]
        });

        if ($reset_result) {
          $reset_result = snmp_set({
            SNMP_COMMUNITY => $SNMP_COMMUNITY,
            VERSION        => $attr->{VERSION},
            OID            => [ $snmp->{reset}->{OIDS} . '.2.0', $snmp->{reset}->{VALUE_TYPE} || "integer", $onu_id ]
          });
        }

      } else {
        my $reset_value = (defined($snmp->{reset}->{RESET_VALUE})) ? $snmp->{reset}->{RESET_VALUE} : 1;

        $reset_result = snmp_set({
          SNMP_COMMUNITY => $SNMP_COMMUNITY,
          VERSION        => $attr->{VERSION},
          OID            => [ $snmp->{reset}->{OIDS} . '.' . $FORM{onuReset}, $snmp->{reset}->{VALUE_TYPE} || "integer", $reset_value ]
        });

      }
      if ($reset_result) {
        $html->message('info', $lang{INFO}, "ONU " . $lang{REBOOTED});
      }
    }
    else {
      $html->message('err', $lang{ERROR}, "Can't find reset SNMP OID", { ID => 499 });
    }
  }
  elsif (($FORM{disable_catv_port} || $FORM{enable_catv_port}) && $FORM{ONU}) {
    my $catv_port_id = $FORM{disable_catv_port} || $FORM{enable_catv_port};

    my $result = equipment_tv_port({
      NAS_INFO       => $attr->{NAS_INFO},
      snmp           => $snmp,
      ONU_SNMP_ID    => $FORM{ONU},
      SNMP_COMMUNITY => $SNMP_COMMUNITY,
      CATV_PORT_ID   => $catv_port_id,
      DISABLE_PORT   => $FORM{disable_catv_port},
      ENABLE_PORT    => $FORM{enable_catv_port}
    });

    if ($result) {
      if ($FORM{disable_catv_port}) {
        $html->message('info', $lang{INFO}, $lang{CATV_PORT_DISABLED});
      }
      elsif ($FORM{enable_catv_port}) {
        $html->message('info', $lang{INFO}, $lang{CATV_PORT_ENABLED});
      }
    }
    else {
      $html->message('err', $lang{ERROR}, $lang{CATV_PORT_STATUS_CHANGING_ERROR});
    }
  }
  elsif (($FORM{disable_eth_port} || $FORM{enable_eth_port}) && $FORM{ONU}) {
    if (! $snmp->{eth_port_manage}) {
      $html->message('info', $lang{INFO}, "ONU PORT MANAGE NOT DEFINED (eth_port_manage)", { ID => 461 });
    }
    else {
      my $port_id = $FORM{disable_eth_port} || $FORM{enable_eth_port};

      my $set_value;
      if ($FORM{disable_eth_port}) {
        $set_value = $snmp->{eth_port_manage}->{DISABLE_VALUE};
      }
      elsif ($FORM{enable_eth_port}) {
        $set_value = $snmp->{eth_port_manage}->{ENABLE_VALUE};
      }
      else {
        print "Disable or enable port? Exiting.\n" if ($attr->{DEBUG});
        return 0;
      }

      my $result = snmp_set({
        SNMP_COMMUNITY => $SNMP_COMMUNITY,
        VERSION        => $attr->{VERSION},
        OID            => [ $snmp->{eth_port_manage}->{OIDS}
          . '.' . $FORM{ONU}
          . '.' . $port_id
          . ($snmp->{eth_port_manage}->{ADD_2_OID} || ''),
          $snmp->{eth_port_manage}->{VALUE_TYPE} || "integer",
          $set_value
        ]
      });

      if ($result) {
        if ($FORM{disable_eth_port}) {
          $html->message('info', $lang{INFO}, $lang{PORT_DISABLED});
        }
        elsif ($FORM{enable_eth_port}) {
          $html->message('info', $lang{INFO}, $lang{PORT_ENABLED});
        }
      }
      else {
        $html->message('err', $lang{ERROR}, $lang{PORT_STATUS_CHANGING_ERROR});
      }
    }
  }

  if ($FORM{ONU}) {
    pon_onu_state($FORM{ONU}, {
      %{$attr // {}},
      snmp        => $snmp,
      ONU_TYPE    => $FORM{ONU_TYPE},
      ONU_SNMP_ID => $FORM{info_pon_onu},
      #BRANCH      => $onu_list->[0]->{branch},
      #ONU_ID      => $onu_list->[0]->{onu_id},
    });

    return 1;
  }
  elsif ($FORM{graph_onu}) {
    equipment_pon_onu_graph({ ONU_SNMP_ID => $FORM{graph_onu}, snmp => $snmp });
  }
  elsif ($FORM{reg_onu}) {
    if (equipment_register_onu({ %FORM, %$attr })) {
      return 1;
    }
  }
  elsif ($FORM{del_onu}) {
    equipment_delete_onu($attr);
  }
  elsif($FORM{unreg_btn_ajax}){
    my $unregister_fn = $nas_type . '_unregister';
    my $macs = &{\&$unregister_fn}({ %$attr });

    print $html->button($lang{UNREGISTER} . ' ' . ($#{$macs} + 1),
      "index=$index&visual=$FORM{visual}&NAS_ID=$nas_id&PON_TYPE=$FORM{PON_TYPE}&unregister_list=1",
      { ID => 'unreg_btn', class => 'btn' . (($#{$macs} > -1) ? ' btn-warning' : ' btn-secondary') });

    return 0;
  }

  if ($SNMP_Session::errmsg) {
    $html->message('err', $lang{ERROR},
      "OID: " . ($attr->{OID} || q{}) . "\n\n $SNMP_Session::errmsg\n\n$SNMP_Session::suppress_warnings\n");
  }

  my $pon_types = ();
  my $olt_ports = ();
  #Port select
  my $port_list = $Equipment->pon_port_list({
    COLS_NAME  => 1,
    COLS_UPPER => 1,
    NAS_ID     => $Equipment->{NAS_ID}
  });

  foreach my $line (@$port_list) {
    $pon_types->{ $line->{pon_type} } = uc($line->{pon_type});
    if ($FORM{PON_TYPE} && $FORM{PON_TYPE} eq $line->{pon_type}) {
      $olt_ports->{ $line->{id} } = "$line->{branch_desc} ($line->{branch})";
    }
    else {
      $olt_ports->{ $line->{id} } = "$line->{pon_type} $line->{branch_desc} ($line->{branch})";
    }
  }

  $FORM{PON_TYPE} = '' if (!$FORM{PON_TYPE});

  my @rows = ();
  if (!$FORM{SERVICE_PORTS} && !$FORM{LINE_PROFILES}) {
    push @rows, $html->element('div', "$lang{TYPE}: " . $html->form_select('PON_TYPE',
      {
        SELECTED    => $FORM{PON_TYPE},
        SEL_HASH    => $pon_types,
        SEL_OPTIONS => { '' => $lang{SELECT_TYPE} },
        EX_PARAMS   => " data-auto-submit='index=$index&visual=$FORM{visual}&NAS_ID=$nas_id' ",
        NO_ID       => 1
      }));

    push @rows, $html->element('div', "$lang{PORTS}: " . $html->form_select('OLT_PORT',
      {
        SELECTED    => $FORM{OLT_PORT},
        SEL_HASH    => $olt_ports,
        SEL_OPTIONS => { '' => $lang{SELECT_PORT} },
        EX_PARAMS   => " data-auto-submit='index=$index&visual=$FORM{visual}&NAS_ID=$nas_id&PON_TYPE=$FORM{PON_TYPE}' ",
        NO_ID       => 1
      }));
  }

  my $unregister_fn = $nas_type . '_unregister';
  if (defined(&$unregister_fn)) {
    if (!$Equipment->{STATUS}) { #XXX get unregistered on certain equipment statuses, not only on Active

      $html->tpl_show(_include('equipment_unreg_button', 'Equipment'),{
        PON_TYPE => $FORM{PON_TYPE},
        NAS_ID   => $nas_id
      });

      push @rows, $html->button($lang{UNREGISTER} . ' ' . $html->element('span', '', { class => 'fa fa-spinner fa-spin' }),
      "index=$index&visual=$FORM{visual}&NAS_ID=$nas_id&PON_TYPE=$FORM{PON_TYPE}&unregister_list=1",
      { ID => 'unreg_btn', class => 'btn btn-secondary' });
    }
    else {
      $html->message('warn', $lang{INFO}, "$lang{STATUS} $service_status[$Equipment->{STATUS}]");
    }
  }

  my %info = ();

  foreach my $val (@rows) {
    $info{ROWS} .= $html->element('div', $val, { class => 'navbar-form form-group' });
  }

  my $report_form = $html->element('div', $info{ROWS}, { class => 'navbar navbar-default' });

  print $html->form_main({
    CONTENT => $report_form,
    HIDDEN  => {
      'index'  => $index,
      'visual' => $FORM{visual},
      'NAS_ID' => $nas_id
    },
    NAME    => 'report_panel',
    ID      => 'report_panel',
    class   => 'form-inline',
  });

  my $page_gs = "&visual=$FORM{visual}&NAS_ID=$nas_id";
  $page_gs .= "&PON_TYPE=$FORM{PON_TYPE}" if ($FORM{PON_TYPE});
  $page_gs .= "&OLT_PORT=$FORM{OLT_PORT}" if ($FORM{OLT_PORT});
  $LIST_PARAMS{NAS_ID} = $nas_id;
  $LIST_PARAMS{PON_TYPE} = $FORM{PON_TYPE} || '';
  $LIST_PARAMS{OLT_PORT} = $FORM{OLT_PORT} || '';
  $LIST_PARAMS{BRANCH} = '_SHOW';
  $LIST_PARAMS{PAGE_ROWS} = 10000;
  $LIST_PARAMS{RX_POWER_SIGNAL} = $FORM{RX_POWER_SIGNAL} || '';

  my %EXT_TITLES = (
    onu_snmp_id          => "SNMP ID",
    branch               => $lang{BRANCH},
    onu_id               => "ONU_ID",
    mac_serial           => "MAC_SERIAL",
    status               => $lang{ONU_STATUS},
    rx_power             => "RX $lang{POWER}",
    tx_power             => "TX $lang{POWER}",
    olt_rx_power         => "OLT RX $lang{POWER}",
    comments             => $lang{COMMENTS},
    onu_desc             => "ONU $lang{COMMENTS}",
    onu_billing_desc     => $lang{ONU_BILLING_DESC},
    address_full         => $lang{ADDRESS},
    district_name        => $lang{DISTRICT},
    login                => $lang{LOGIN},
    traffic              => $lang{TRAFFIC},
    onu_dhcp_port        => "DHCP $lang{PORTS}",
    distance             => $lang{DISTANCE},
    fio                  => $lang{FIO},
    phone                => $lang{PHONE},
    user_mac             => "$lang{USER} MAC",
    mac_behind_onu       => $lang{MAC_BEHIND_ONU},
    vlan_id              => 'Native VLAN Statics',
    onu_vlan             => 'VLAN',
    datetime             => $lang{UPDATED},
    external_system_link => $lang{EXTERNAL_SYSTEM_LINK}
  );

  my ($table, $onu_list) = result_former({
    INPUT_DATA      => $Equipment,
    FUNCTION        => 'onu_list',
    DEFAULT_FIELDS  => 'BRANCH,ONU_ID,MAC_SERIAL,STATUS,RX_POWER',
    HIDDEN_FIELDS   => 'DELETED',
    FUNCTION_FIELDS => ' ', #we have custom function_fields below. need this to add empty column to table header to have same number of columns in table header and the table
    SKIP_PAGES      => 1,
    SKIP_USER_TITLE => 1,
    BASE_FIELDS     => 1,
    EXT_TITLES      => \%EXT_TITLES,
    TABLE           => {
      width            => '100%',
      caption          => "PON ONU",
      qs               => $page_gs,
      SHOW_COLS        => \%EXT_TITLES,
      SHOW_COLS_HIDDEN => {
        PON_TYPE => $FORM{PON_TYPE},
        OLT_PORT => $FORM{OLT_PORT},
        visual   => $FORM{visual},
        NAS_ID   => $nas_id,
      },
      DATA_TABLE       => { lengthMenu => [[25, 50, -1], [25, 50, $lang{ALL}]] },
      ID               => 'EQUIPMENT_ONU',
      EXPORT           => 1,
    }
  });
  _error_show($Equipment);

  my $used_ports = equipments_get_used_ports({
    NAS_ID    => $nas_id,
    FULL_LIST => 1,
  });

  my @cols = ();
  if ($table->{COL_NAMES_ARR}) {
    @cols = @{$table->{COL_NAMES_ARR}};
  }
  my @all_rows = ();


  my %mac_behind_onu = ();
  my %mac_behind_onu_old = ();
  if (in_array('mac_behind_onu', \@cols) ||
       (in_array('external_system_link', \@cols) && $conf{EQUIPMENT_USER_LINK} && $conf{EQUIPMENT_USER_LINK} =~ m/%USER_MAC%/)) {
    my $show_old_mac_behind_onu = $conf{EQUIPMENT_SHOW_OLD_MAC_BEHIND_ONU} && in_array('mac_behind_onu', \@cols);
    my $mac_log = $Equipment->mac_log_list({
      NAS_ID       => $nas_id,
      PORT         => '_SHOW',
      PORT_NAME    => '_SHOW',
      MAC          => '_SHOW',
      ONLY_CURRENT => $show_old_mac_behind_onu ? 0 : 1,
      DATETIME     => $show_old_mac_behind_onu ? '_SHOW' : '',
      REM_TIME     => $show_old_mac_behind_onu ? '_SHOW' : '',
      PAGE_ROWS    => 10000,
      COLS_NAME    => 1
    });

    foreach my $line (@$mac_log) {
      if ($show_old_mac_behind_onu && $line->{rem_time} gt $line->{datetime}) {
        push @{$mac_behind_onu_old{$line->{port} || 0}}, $line->{mac};
        if ($line->{port_name}) { push @{$mac_behind_onu_old{$line->{port_name}}}, $line->{mac} };
      }
      else {
        push @{$mac_behind_onu{$line->{port} || 0}}, $line->{mac};
        if ($line->{port_name}) { push @{$mac_behind_onu{$line->{port_name}}}, $line->{mac} };
      }
    }
  }

  if (in_array('distance', \@cols) && $onu_list->[0]) {
    my $distances;
    foreach my $pon_type (keys %$pon_types) {
      next if ($FORM{OLT_PORT} && $onu_list->[0]->{pon_type} ne $pon_type);
      next if (!$snmp->{$pon_type}->{main_onu_info}->{DISTANCE}->{OIDS});

      my $branch_snmp_id;
      if ($FORM{OLT_PORT} && $onu_list->[0]->{onu_snmp_id} =~ m/^(\d+)\.\d+/) { #on some OLTs it's possible to query single branch
        $branch_snmp_id = $1;
        if ($attr->{VENDOR_NAME} eq 'GCOM' && $pon_type eq 'epon' && $onu_list->[0]->{onu_snmp_id} =~ m/^(\d+\.\d+)\.\d+/) {
          $branch_snmp_id = $1;
        }
      }

      my $result = snmp_get({
        OID            => $snmp->{$pon_type}->{main_onu_info}->{DISTANCE}->{OIDS} . ((defined $branch_snmp_id) ? ".$branch_snmp_id" : ''),
        SNMP_COMMUNITY => $SNMP_COMMUNITY,
        VERSION        => $attr->{VERSION},
        WALK           => 1,
        TIMEOUT        => $conf{EQUIPMENT_INFO_SNMP_TIMEOUT} || 10
      });

      foreach my $line (@$result) {
        my ($snmp_id, $value) = split(/:/, $line);
        $snmp_id = "$branch_snmp_id.$snmp_id" if ($branch_snmp_id);

        my $function = $snmp->{$pon_type}->{main_onu_info}->{DISTANCE}->{PARSER};

        if ($function && defined(&{$function})) {
          ($value) = &{\&$function}($value);
        }

        $distances->{$pon_type}->{$snmp_id} = $value;
      }
    }

    foreach my $line (@$onu_list) {
      $line->{distance} = $distances->{$line->{pon_type}}->{$line->{onu_snmp_id}} || '--';
    }
  }

  my %used_ids;
  foreach my $onu (@$onu_list) {
    next if ($used_ids{$onu->{id}});
    $used_ids{$onu->{id}} = 1;
    my @row = ();
    for (my $i = 0; $i <= $#cols; $i++) {
      my $col_id = $cols[$i];
      last if ($col_id eq 'id');
      if ($col_id eq 'login' || $col_id eq 'address_full' || $col_id eq 'user_mac' || $col_id eq 'fio' || $col_id eq 'comments') {
        my $value;
        if ($used_ports->{$onu->{dhcp_port}}) {
          if ($col_id eq 'login') {
            if (!$FORM{xml} && !$FORM{csv} && !$FORM{json} && !$FORM{xls}) {
              $value .= show_used_info($used_ports->{ $onu->{dhcp_port} });
            }
            else {
              $value .= join ("\n", map { $_->{login} } @{$used_ports->{$onu->{dhcp_port}}});
            }
          }
          else {
            foreach my $uinfo (@{$used_ports->{$onu->{dhcp_port}}}) {
              $value .= $html->br() if ($value);
              if ($col_id eq 'address_full') {
                $value .= $uinfo->{address_full} || "";
              }
              elsif ($col_id eq 'user_mac') {
                $value .= $uinfo->{cid} || ""; #TODO color_mark code
              }
              elsif ($col_id eq 'fio') {
                $value .= $uinfo->{fio} || "";
              }
              elsif ($col_id eq 'comments') {
                $value .= $uinfo->{comments} || "";
              }
            }
          }
        }
        else {
          $value = '';
        }
        push @row, $value;
        next;
      }
      elsif ($col_id eq 'traffic') {
        my ($in, $out) = split(/,/, $onu->{traffic});
        push @row, "in: " . int2byte($in) . $html->br() . "out: " . int2byte($out);
      }
      elsif ($col_id =~ /power/) {
        push @row, pon_tx_alerts($onu->{$col_id});
      }
      elsif ($col_id eq 'status') {
        push @row, ($onu->{deleted}) ? $html->color_mark("Deleted", 'text-red') : pon_onu_convert_state($nas_type, $onu->{status}, $onu->{pon_type});
      }
      elsif ($col_id eq 'branch') {
        my $br = uc($onu->{pon_type}) . ' ' . $onu->{$col_id};
        $br = $html->color_mark($br, 'text-red') if ($onu->{deleted});
        push @row, $br;
      }
      elsif ($col_id eq 'mac_behind_onu') {
        my $macs = [];
        my $macs_old = [];
        if ($onu->{onu_snmp_id}) {
          my $mac_log_search_by_port_name = $snmp->{$onu->{pon_type}}->{main_onu_info}->{MAC_BEHIND_ONU}->{MAC_LOG_SEARCH_BY_PORT_NAME};
          my $mac_behind_onu_index = ($mac_log_search_by_port_name)
            ? (
                (($mac_log_search_by_port_name eq 'no_pon_type') ? '' : uc $onu->{pon_type})
                . "$onu->{branch}:$onu->{onu_id}"
              )
            : ($onu->{onu_snmp_id});
          $macs = $mac_behind_onu{$mac_behind_onu_index} || [];
          $macs_old = $mac_behind_onu_old{$mac_behind_onu_index} || [];
        }
        if (@$macs || @$macs_old) {
          my @macs = sort @{$macs};
          my @macs_old = sort @{$macs_old};
          push @row, join($html->br(),
            (map { $html->color_mark($_, 'code') } @macs),
            (map { $html->color_mark($_, 'code') . ' (old)' } @macs_old)
          );
        }
        else {
          push @row, '--';
        }
      }
      elsif ($col_id eq 'external_system_link') {
        if ($conf{EQUIPMENT_USER_LINK}) {
          my $macs = '';

          my $mac_log_search_by_port_name = $snmp->{$onu->{pon_type}}->{main_onu_info}->{MAC_BEHIND_ONU}->{MAC_LOG_SEARCH_BY_PORT_NAME};
          my $mac_behind_onu_index = ($mac_log_search_by_port_name)
            ? (
                (($mac_log_search_by_port_name eq 'no_pon_type') ? '' : uc $onu->{pon_type})
                . "$onu->{branch}:$onu->{onu_id}"
              )
            : ($onu->{onu_snmp_id});

          if ($onu->{onu_snmp_id} && $mac_behind_onu{$mac_behind_onu_index}) {
            $macs = join(',', sort @{$mac_behind_onu{$mac_behind_onu_index}});
          }

          my $link = $conf{EQUIPMENT_USER_LINK};
          $link =~ s/%CPE_MAC%/$onu->{mac_serial}/g;
          $link =~ s/%SW_PORT%/$onu->{branch}:$onu->{onu_id}/g;
          $link =~ s/%USER_MAC%/$macs/g;

          push @row, $html->button($lang{EXTERNAL_SYSTEM_LINK}, '',
            {
              class      => 'btn btn-secondary',
              ICON       => 'fa fa-external-link-alt',
              GLOBAL_URL => $link
            }
          );
        }
        else {
          push @row, '';
        }
      }
      else {
        if ($col_id ne 'deleted') {
          push @row, ($onu->{deleted}) ? $html->color_mark($onu->{$col_id}, 'text-red') : $onu->{$col_id};
        }
      }
    }

    my @control_row = ();
    if (!$onu->{deleted}) {
      push @control_row, $html->button('', "index=$index" . $page_gs . "&onuReset="
        . $onu->{onu_snmp_id} . "&ONU_TYPE=" . $onu->{pon_type},
        { MESSAGE => "$lang{REBOOT} ONU: ". ($onu->{branch} . q{}) . ':'. ($onu->{onu_id} || q{}) ."?",
          ICON => 'fa fa-retweet',
          TITLE => $lang{REBOOT} . " ONU"
        });
      push @control_row, $html->button($lang{INFO}, "index=$index" . $page_gs . "&info_pon_onu=" . $onu->{id} . "&ONU="
        . $onu->{onu_snmp_id} . "&ONU_TYPE=" . $onu->{pon_type},
        { class => 'info' });
    }
    push @control_row, $html->button($lang{DEL},
      "NAS_ID=$FORM{NAS_ID}&index=" . get_function_index('equipment_info')
        . "&visual=$FORM{visual}&ONU_TYPE=" . ($onu->{pon_type} || 0) . "&del_onu=" . ($onu->{id} || 0),
      { MESSAGE => "$lang{DEL} ONU: $onu->{branch}:$onu->{onu_id}?", class => 'del' });

    push @row, $html->element('span', join(' ', @control_row), { class => 'text-nowrap' });
    push @all_rows, \@row;
  }
  $onu_list = $Equipment->onu_date_status({
    COLS_NAME       => 1,
    NAS_ID          => $Equipment->{NAS_ID},
    OLT_PORT        => $FORM{OLT_PORT} || '',
    RX_POWER_SIGNAL => $FORM{RX_POWER_SIGNAL} || ''
  });
  my $total_off = 0;
  my $total_on = 0;
  my $last_date = '';
  for my $line (@$onu_list) {
    if ($line->{onu_status} == 1 || $line->{onu_status} == 2 || $line->{onu_status} == 3 || $line->{onu_status} == 5 || $line->{onu_status} == 18) {
      $total_on += 1;
    }
    else {
      $total_off += 1;
    }
    if ($last_date lt $line->{datetime}) {
      $last_date = $line->{datetime};
    }
  }
  my $total_table = $html->table({
    width => '100%',
    rows  => [
      [ $html->b("$lang{TOTAL}:"),      $#all_rows + 1 ],
      [ $html->b("$lang{ONLINE}:"),     $total_on      ],
      [ $html->b("$lang{OFFLINE}:"),    $total_off     ],
      [ $html->b("$lang{LAST_POLL}:"),  $last_date     ],
    ]
  });

  print result_row_former({
    table           => $table,
    ROWS            => \@all_rows,
  });
  print $total_table->show();

  return 1;
}

#********************************************************
=head2 equipment_unregister_onu_list($attr) - Show unregister OLN ONU

  Arguments:
    $attr
      NAS_INFO

  Returns:
    TRUE or FALSE

=cut
#********************************************************
sub equipment_unregister_onu_list {
  my ($attr) = @_;

  my $nas_id = $attr->{NAS_ID} || $FORM{NAS_ID};
  #For old version
  $Equipment->vendor_info($Equipment->{VENDOR_ID});
  if (!$attr->{VENDOR_NAME}) {
    $attr->{VENDOR_NAME} = $Equipment->{NAME};
  }

  my $nas_type = equipment_pon_init($attr);
  $attr->{NAS_ID} = $nas_id;
  $attr->{FULL} = 1;

  my $unregister_fn = $nas_type . '_unregister';
  my $unregister_list = &{\&$unregister_fn}({ %$attr });
  $pages_qs = "&visual=$FORM{visual}&NAS_ID=$nas_id&unregister_list=1";
  result_former({
    FUNCTION_FIELDS => ":add:id;mac;sn;branch;onu_type;pon_type;type;mac_serial;equipment_id;vendor;branch_num:&visual=4&NAS_ID=$nas_id&reg_onu=1",
    TABLE           => {
      width            => '100%',
      caption          => $lang{UNREGISTER},
      EXT_TITLES       => {
        sn               => $lang{MAC_SERIAL},
        branch           => $lang{BRANCH},
        ONU_TYPE         => $lang{TYPE},
        SOFTWARE_VERSION => $lang{VERSION}
      },
      qs               => $pages_qs,
      SHOW_COLS_HIDDEN => { visual => $FORM{visual} },
      ID               => 'EQUIPMENT_UNGERISTER',
    },
    DATAHASH        => $unregister_list,
    TOTAL           => 1
  });

  return 1;
}

#********************************************************
=head2 equipment_register_onu($attr) - PON ONU registration

  Arguments:
    $attr
      NAS_INFO
      VENDOR_NAME
      NAS_ID

  Returns:
    TRUE or FALSE

=cut
#********************************************************
sub equipment_register_onu {
  my ($attr) = @_;

  my $nas_id = $attr->{NAS_ID} || $attr->{NAS_INFO}->{NAS_ID};
  #For old version
  $Equipment->vendor_info($Equipment->{VENDOR_ID});
  if (!$attr->{VENDOR_NAME}) {
    $attr->{VENDOR_NAME} = $Equipment->{NAME};
  }

  my $nas_type = equipment_pon_init($attr);

  my $list = $Equipment->_list({
    NAS_ID           => $nas_id,
    NAS_MNG_HOST_PORT=> '_SHOW',
    NAS_MNG_USER     => '_SHOW',
    NAS_MNG_PASSWORD => '_SHOW',
    INTERNET_VLAN    => '_SHOW',
    TR_069_VLAN      => '_SHOW',
    IPTV_VLAN        => '_SHOW',
    COLS_NAME        => 1,
    PAGE_ROWS        => 1,
  });

  if ($Equipment->{TOTAL}) {
    $attr->{NAS_INFO}{NAS_MNG_IP_PORT} = $list->[0]->{nas_mng_ip_port};
    $attr->{NAS_INFO}{NAS_MNG_USER} = $list->[0]->{mng_user};
    $attr->{NAS_INFO}{NAS_MNG_USER} = $list->[0]->{nas_mng_user};
    $attr->{NAS_INFO}{NAS_MNG_PASSWORD} = $conf{EQUIPMENT_OLT_PASSWORD} || $list->[0]->{nas_mng_password};
    $attr->{NAS_INFO}{PROFILE} = $conf{EQUIPMENT_ONU_PROFILE} if ($conf{EQUIPMENT_ONU_PROFILE});
    $attr->{NAS_INFO}{ONU_TYPE} = $conf{EQUIPMENT_ONU_TYPE} if ($conf{EQUIPMENT_ONU_TYPE});
    delete $attr->{NAS_INFO}->{ACTION_LNG};

    my $port_list = $Equipment->pon_port_list({
      %$attr,
      COLS_NAME  => 1,
      COLS_UPPER => 1,
      BRANCH     => $FORM{BRANCH},
      NAS_ID     => $nas_id
    });

    $attr->{DEF_VLAN} = $port_list->[0]->{VLAN_ID} || $list->[0]->{internet_vlan};
    $attr->{PORT_VLAN} = $attr->{DEF_VLAN};
    $attr->{TR_069_VLAN} = $list->[0]->{tr_069_vlan} || '';
    $attr->{IPTV_VLAN} = $list->[0]->{iptv_vlan} || '';

    my $unregister_form_fn = $nas_type . '_unregister_form';

    if ($FORM{reg_onu} && defined(&$unregister_form_fn) && !$FORM{onu_registration}) {
      &{\&$unregister_form_fn}({ %FORM, %$attr });
      return 1;
    }
    else {
      return equipment_register_onu_cmd($nas_type, $nas_id, $port_list, $attr);
    }
  }

  return 0;
}

#********************************************************
=head2 equipment_register_onu_cmd($nas_type, $nas_id, $port_list, $attr) - runs cmds for PON ONU registration

  Arguments:
    $nas_type
    $nas_id
    $port_list
    $attr
      NAS_INFO
      VENDOR_NAME
      NAS_ID

  Returns:
    TRUE or FALSE

=cut
#********************************************************
sub equipment_register_onu_cmd {
  my ($nas_type, $nas_id, $port_list, $attr) = @_;

  my $parse_line_profile = $nas_type . '_prase_line_profile';
  if (defined(&$parse_line_profile)) {
    my $line_profiles = &{\&$parse_line_profile}({ %FORM, %$attr });
    foreach my $key (keys %$line_profiles) {
      $FORM{LINE_PROFILE_DATA} .= "$key:";
      $FORM{LINE_PROFILE_DATA} .= join(',', @{$line_profiles->{$key}});
      # foreach my $vlan (@{$line_profiles->{$key}}) {
      #   $FORM{LINE_PROFILE_DATA} .= "$vlan";
      #   if ($line_profiles->{$key}->[ $#{$line_profiles->{$key}} ] ne $vlan) {
      #     $FORM{LINE_PROFILE_DATA} .= ",";
      #   }
      # }
      $FORM{LINE_PROFILE_DATA} .= ";";
    }
  }

  my $cmd = $SNMP_TPL_DIR . '/register' . $nas_type . '_custom';
  $cmd = $SNMP_TPL_DIR . '/register' . $nas_type if (!-x $cmd);

  my $result = '';
  my $result_code = '';

  if (-x $cmd) {
    $attr->{TR_069_PROFILE} = $conf{TR_069_PROFILE} || 'ACS';
    $attr->{INTERNET_USER_VLAN} = $conf{INTERNET_USER_VLAN} || '101';
    $attr->{TR_069_USER_VLAN} = $conf{TR_069_USER_VLAN} || '102';
    $attr->{IPTV_USER_VLAN} = $conf{IPTV_USER_VLAN} || '103';
    $attr->{VLAN_ID} = $FORM{VLAN_ID_HIDE} || '';

    delete $attr->{NAS_INFO}->{ACTION_LNG};
    delete $attr->{NAS_INFO}->{NAS_ID_INFO};
    $result = cmd($cmd, {
      DEBUG   => $FORM{DEBUG} || 0,
      PARAMS  => { %$attr, %FORM, %{$attr->{NAS_INFO}} },
      ARGV    => 1,
      timeout => 30
    });
    $result_code = $? >> 8;
  }
  elsif (-e $cmd) {
    $result = "$cmd don't have execute permission";
    $result_code = 0;
  }

  if ($result_code) {
    $html->message('info', $lang{INFO}, $result);
    $result =~ s/\n/ /g;
    if ($result =~ /ONU: \d+\/\d+\/\d+\:(\d+) ADDED/) {
      equipment_register_onu_add_default($result, $nas_id, $port_list, $attr);
    }
    elsif ($result =~ /ONU ZTE: (\d+)\/(\d+)\/(\d+)\:(\d+) ADDED/) {
      equipment_register_onu_add_zte($result, $nas_id, $port_list, $attr);
    }
    elsif ($result =~ /ONU ELTEX: (\d+)\/(\d+)\:(\d+) ADDED/) {
      equipment_register_onu_add_eltex($result, $nas_id, $port_list, $attr);
    }
    elsif ($result =~ /ONU BDCOM: (\d+)\/(\d+)\:(\d+) .* SNMP ID (\d+) DHCP PORT ([0-9a-f]{4}) ADDED/) {
      equipment_register_onu_add_bdcom($result, $nas_id, $port_list, $attr);
    }

    return 1;
  }
  else {
    $html->message('err', $lang{ERROR}, "$result");
    return 0;
  }
}

#********************************************************
=head2 equipment_register_onu_add_default($nas_type, $nas_id, $port_list, $attr) - add registered ONU to DB: default version

  Arguments:
    $result - cmd's output
    $nas_id
    $port_list
    $attr
      MAC_SERIAL
      ONU_DESC
      LINE_PROFILE
      SRV_PROFILE

=cut
#********************************************************
sub equipment_register_onu_add_default {
  my ($result, $nas_id, $port_list, $attr) = @_;
  $result =~ /ONU: \d+\/\d+\/\d+\:(\d+) ADDED/;

  my $onu = ();
  $onu->{NAS_ID} = $nas_id;
  $onu->{ONU_ID} = $1 || 0;
  $onu->{ONU_DHCP_PORT} = $port_list->[0]->{BRANCH} . ':' . $onu->{ONU_ID};
  $onu->{PORT_ID} = $port_list->[0]->{ID};
  $onu->{ONU_MAC_SERIAL} = $attr->{MAC_SERIAL};
  $onu->{ONU_DESC} = $attr->{ONU_DESC};
  $onu->{ONU_SNMP_ID} = $port_list->[0]->{SNMP_ID} . '.' . $onu->{ONU_ID};
  $onu->{LINE_PROFILE} = $attr->{LINE_PROFILE};
  $onu->{SRV_PROFILE} = $attr->{SRV_PROFILE};

  my $onu_list = $Equipment->onu_list({ COLS_NAME => 1, OLT_PORT => $onu->{PORT_ID}, ONU_SNMP_ID => $onu->{ONU_SNMP_ID} });
  if ($onu_list->[0]->{id}) {
    $Equipment->onu_change({ ID => $onu_list->[0]->{id}, ONU_STATUS => 0, DELETED => 0, %{$onu} });
  }
  else {
    $Equipment->onu_add({ %{$onu} });
  }

  return $onu;
}

#********************************************************
=head2 equipment_register_onu_add_zte($nas_type, $nas_id, $port_list, $attr) - add registered ONU to DB: ZTE version

  Arguments:
    $result - cmd's output
    $nas_id
    $port_list
    $attr
      NAS_INFO
        MODEL_NAME
      MAC
      SN
      ONU_DESC

=cut
#********************************************************
sub equipment_register_onu_add_zte {
  my ($result, $nas_id, $port_list, $attr) = @_;

  my ($shelf, $slot, $olt, $onu_id) = $result =~ /ONU ZTE: (\d+)\/(\d+)\/(\d+)\:(\d+) ADDED/;

  my $onu = ();
  $onu->{NAS_ID} = $nas_id;
  $onu->{ONU_ID} = $onu_id;

  my $pon_type = $port_list->[0]->{PON_TYPE} || '';

  my $model_name = $attr->{NAS_INFO}->{MODEL_NAME}  || q{};
  my $encoded_onu = ($pon_type eq 'epon') ? _zte_encode_onu(($model_name =~ /_V2$/i) ? 9 : 3, $shelf, $slot, $olt, $onu_id, $model_name) : 0;

  $onu->{ONU_DHCP_PORT} = _zte_dhcp_port({
    SHELF      => $shelf,
    SLOT       => $slot,
    OLT        => $olt,
    ONU        => $onu_id,
    PON_TYPE   => $pon_type,
    MODEL_NAME => $model_name
  });
  $onu->{PORT_ID} = $port_list->[0]->{ID};
  $onu->{ONU_MAC_SERIAL} = ($attr->{MAC} && $attr->{MAC} =~ /^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$/gm) ? $attr->{MAC} : $attr->{SN};
  $onu->{ONU_DESC} = $attr->{ONU_DESC};
  $onu->{ONU_SNMP_ID} = ($encoded_onu != 0) ? $encoded_onu : $port_list->[0]->{SNMP_ID} . '.' . $onu->{ONU_ID};
  $onu->{LINE_PROFILE} = 'ONU';
  $onu->{SRV_PROFILE} = 'ALL';

  my $onu_list = $Equipment->onu_list({ COLS_NAME => 1, OLT_PORT => $onu->{PORT_ID}, ONU_SNMP_ID => $onu->{ONU_SNMP_ID} });
  if ($onu_list->[0]->{id}) {
    $Equipment->onu_change({ ID => $onu_list->[0]->{id}, ONU_STATUS => 0, DELETED => 0, %{$onu} });
  }
  else {
    $Equipment->onu_add({ %{$onu} });
  }

  return $onu;
}

#********************************************************
=head2 equipment_register_onu_add_eltex($nas_type, $nas_id, $port_list, $attr) - add registered ONU to DB: Eltex version

  Arguments:
    $result - cmd's output
    $nas_id
    $port_list
    $attr
      MAC
      ONU_DESC

=cut
#********************************************************
sub equipment_register_onu_add_eltex {
  my ($result, $nas_id, $port_list, $attr) = @_;
  $result =~ /ONU ELTEX: (\d+)\/(\d+)\:(\d+) ADDED/;
  my $slot = $1;
  my $onu_id = $3;

  my $onu = ();
  $onu->{NAS_ID} = $nas_id;
  $onu->{ONU_ID} = $onu_id || 0;
  #$onu->{ONU_DHCP_PORT} = $port_list->[0]->{BRANCH} . ':' . $onu->{ONU_ID};
  $onu->{PORT_ID} = $port_list->[0]->{ID};
  $onu->{ONU_MAC_SERIAL} = $attr->{MAC};
  $onu->{ONU_DESC} = $attr->{ONU_DESC};

  my $mac = $attr->{MAC};
  my $mac_hex = $mac;
  my $mac_text = substr $mac_hex, 0, 4, '';
  my $snmp_id = join('.', $slot+1, 8, unpack("C*", $mac_text . pack("H*", $mac_hex)));

  $onu->{ONU_SNMP_ID} = $snmp_id;

  my $onu_list = $Equipment->onu_list({ COLS_NAME => 1, OLT_PORT => $onu->{PORT_ID}, ONU_SNMP_ID => $onu->{ONU_SNMP_ID} });

  if ($onu_list->[0]->{id}) {
    $Equipment->onu_change({ ID => $onu_list->[0]->{id}, ONU_STATUS => 0, DELETED => 0, %{$onu} });
  }
  else {
    $Equipment->onu_add({ %{$onu} });
  }

  return $onu;
}

#********************************************************
=head2 equipment_register_onu_add_bdcom($nas_type, $nas_id, $port_list, $attr) - add registered ONU to DB: BDCOM version

  Arguments:
    $result - cmd's output
    $nas_id
    $port_list
    $attr
      MAC_SERIAL

=cut
#********************************************************
sub equipment_register_onu_add_bdcom {
  my ($result, $nas_id, $port_list, $attr) = @_;
  $result =~ /ONU BDCOM: (\d+)\/(\d+)\:(\d+) .* SNMP ID (\d+) DHCP PORT ([0-9a-f]{4}) ADDED/;

  my $onu = ();
  $onu->{NAS_ID} = $nas_id;
  $onu->{ONU_ID} = $3;
  $onu->{ONU_SNMP_ID} = $4;
  $onu->{ONU_DHCP_PORT} = $5;
  $onu->{PORT_ID} = $port_list->[0]->{ID};
  $onu->{ONU_MAC_SERIAL} = $attr->{MAC_SERIAL};

  my $onu_list = $Equipment->onu_list({ COLS_NAME => 1, OLT_PORT => $onu->{PORT_ID}, ONU_SNMP_ID => $onu->{ONU_SNMP_ID} });
  if ($onu_list->[0]->{id}) {
    $Equipment->onu_change({ ID => $onu_list->[0]->{id}, ONU_STATUS => 0, DELETED => 0, %{$onu} });
  }
  else {
    $Equipment->onu_add({ %{$onu} });
  }

  return $onu;
}

#********************************************************
=head2 equipment_delete_onu($attr) - Delete PON ONU

  Arguments:
    $attr
      NAS_INFO
      VENDOR_NAME

  Returns:
    TRUE or FALSE

=cut
#********************************************************
sub equipment_delete_onu {
  my ($attr) = @_;

  #my $nas_id = $attr->{NAS_ID} || $attr->{NAS_INFO}->{NAS_ID};
  #For old version
  $Equipment->vendor_info($Equipment->{VENDOR_ID});
  if (!$attr->{VENDOR_NAME}) {
    $attr->{VENDOR_NAME} = $Equipment->{NAME};
  }

  my $nas_type = equipment_pon_init($attr);
  my $onu_info = $Equipment->onu_info($FORM{del_onu});

  $attr->{NAS_INFO}{NAS_MNG_PASSWORD} = $conf{EQUIPMENT_OLT_PASSWORD} if ($conf{EQUIPMENT_OLT_PASSWORD});
  $attr->{NAS_INFO}{PROFILE} = $conf{EQUIPMENT_ONU_PROFILE} if ($conf{EQUIPMENT_ONU_PROFILE});

  my $cmd = $SNMP_TPL_DIR . '/register' . $nas_type . '_custom';
  $cmd = $SNMP_TPL_DIR . '/register' . $nas_type if (!-x $cmd);
  my $result = '';
  my $result_code = '';

  if (-e $cmd && !$onu_info->{DELETED} && $FORM{COMMENTS} ne 'database') {
    if (-x $cmd) {
      delete $attr->{NAS_INFO}->{ACTION_LNG};
      delete $attr->{NAS_INFO}->{NAS_ID_INFO};
      $result = cmd($cmd, {
        DEBUG   => $FORM{DEBUG} || 0,
        PARAMS  => { %$attr, %FORM, %$onu_info, %{$attr->{NAS_INFO}} },
        ARGV    => 1,
        timeout => 30
      });

      $result_code = $? >> 8;
    }
    else {
      $result = "$cmd don't have execute permission";
      $result_code = 0;
    }
  }
  else {
    $result = "ONU: " . $onu_info->{BRANCH} . ":" . $onu_info->{ONU_ID} . " DELETED FROM DATABASE";
    $result_code = 1;
  }

  if ($result_code) {
    $html->message('info', $lang{INFO}, "$result");
    $Equipment->onu_del($FORM{del_onu});
    return 1;
  }
  else {
    $html->message('err', $lang{ERROR}, "$result");
    return 0;
  }
}

#********************************************************
=head2 equipment_pon_onu($attr) - Show PON ONU information

  Arguments:
    $attr
      NAS_INFO

  Returns:
    TRUE or FALSE
=cut
#********************************************************
sub equipment_pon_onu {
  my ($attr) = @_;

  my $nas_id = $attr->{NAS_INFO}{NAS_ID} || $FORM{NAS_ID};
  $Equipment->vendor_info($Equipment->{VENDOR_ID});
  _error_show($Equipment);

  #For old version
  if (!$attr->{VENDOR_NAME}) {
    $attr->{VENDOR_NAME} = $Equipment->{NAME};
  }
  my $nas_type = equipment_pon_init($attr);
  if (!$nas_type) {
    return 0;
  }

  my $used_ports = equipments_get_used_ports({
    NAS_ID     => $nas_id,
    FULL_LIST  => 1,
    PORTS_ONLY => 1,
  });
  _error_show($Equipment);

  my $page_gs = "&visual=$FORM{visual}&NAS_ID=$nas_id";
  $LIST_PARAMS{NAS_ID} = $nas_id;
  $LIST_PARAMS{PON_TYPE} = $FORM{PON_TYPE} || '';
  $LIST_PARAMS{OLT_PORT} = $FORM{OLT_PORT} || '';
  $LIST_PARAMS{BRANCH} = $FORM{BRANCH} || '_SHOW' || '';
  $LIST_PARAMS{DELETED} = 0;
  $LIST_PARAMS{PAGE_ROWS}=10000;
  delete($LIST_PARAMS{GROUP_BY}) if ($LIST_PARAMS{GROUP_BY});

  my %show_cols = ();

  if($FORM{IN_MODAL}) {
    %show_cols = (
      mac_serial   => "MAC_SERIAL",
      status       => $lang{STATUS},
      rx_power     => "RX_POWER",
      tx_power     => "TX_POWER",
      olt_rx_power => "OLT_RX_POWER",
      comments     => $lang{COMMENTS},
      address_full => $lang{ADDRESS},
      login        => $lang{USER},
      traffic      => $lang{TRAFFIC},
      distance     => $lang{DISTANCE},
      datetime     => $lang{UPDATED},
      vlan_id      => 'VLAN'
    );
  }

  my ($table, $list) = result_former({
    INPUT_DATA     => $Equipment,
    FUNCTION       => 'onu_list',
    BASE_FIELDS    => 2,
    DEFAULT_FIELDS => 'COMMENTS,MAC_SERIAL,STATUS,RX_POWER,LOGIN',
    SKIP_PAGES     => 1,
    TABLE          => {
      width            => '100%',
      caption          => "PON ONU",
      qs               => $page_gs,
      SHOW_COLS        => \%show_cols,
      SHOW_COLS_HIDDEN => {
        PON_TYPE => $FORM{PON_TYPE},
        OLT_PORT => $FORM{OLT_PORT},
        visual   => $FORM{visual},
        NAS_ID   => $nas_id,
      },
      ID               => '_EQUIPMENT_ONU',
      EXPORT           => 1,
    },
  });

  my $search_result_input_name = $FORM{PORT_INPUT_NAME} || 'PORTS';
  my $server_vlan = $attr->{NAS_INFO}->{SERVER_VLAN};

  my $port_vlan_list = $Equipment->pon_port_list({
    NAS_ID    => $nas_id,
    COLS_NAME => 1,
  });
  _error_show($Equipment);

  my %vlan_for_port = ();
  $vlan_for_port{$_->{id}} = $_->{vlan_id} foreach (@$port_vlan_list);

  my @cols = ();
  if ($table->{COL_NAMES_ARR}) {
    @cols = @{$table->{COL_NAMES_ARR}};
  }
  my @all_rows = ();

  foreach my $line (@$list) {
    my @row = ();

    for (my $i = 0; $i <= $#cols; $i++) {
      my $col_id = $cols[$i];
      last if ($col_id eq 'id');
      #print "Port: $port col: $i '$col_id' // $olt_ports->{$port}->{$col_id} //<br>";
      if ($col_id eq 'login' || $col_id eq 'address_full' || $col_id eq 'ID') {
        my $value = '';

        if ($used_ports->{$line->{dhcp_port}}) {
          if ($col_id eq 'ID') {
            $value = 'busy'
          }
          else {
            foreach my $uinfo (@{$used_ports->{$line->{dhcp_port}}}) {
              $value .= $html->br() if ($value);
              if ($col_id eq 'login') {
                $value .= $html->button($uinfo->{login}, "index=11&UID=$uinfo->{uid}");
              }
              elsif ($col_id eq 'address_full') {
                $value .= $uinfo->{address_full} || "";
              }
            }
          }
        }
        else {
          if ($col_id eq 'ID') {
            $value = 'free'
          }
          else {
            $value = '';
          }
        }

        push @row, $value;
      }
      elsif ($col_id =~ /power/) {
        push @row, pon_tx_alerts($line->{$col_id});
      }
      elsif ($col_id eq 'status') {
        push @row, pon_onu_convert_state($nas_type, $line->{status}, $line->{pon_type});
      }
      else {
        push @row, $line->{$col_id};
      }
    }

    my $btn_class = ($line->{dhcp_port} && $used_ports->{$line->{dhcp_port}}) ? 'btn-warning' : 'btn-success';

    my $data_value = ''
      . $search_result_input_name . '::' . $line->{dhcp_port}
      . '#@#CPE_MAC::' . $line->{mac_serial}
      . (($server_vlan) ? '#@#' . 'SERVER_VLAN::' . $server_vlan : q{})
      . '#@#' . ($vlan_for_port{$line->{id}} ? "VLAN::$vlan_for_port{$line->{id}}" : ($line->{vlan} ? "VLAN::$line->{vlan}" : '')) #XXX vlan_for_port - how is this supposed to work? it gets equipment_pon_ports.vlan_id when equipment_pon_ports.id = equipment_pon_onu.id, why?
    ;

    push @row, "<div value='$line->{dhcp_port}' class='clickSearchResult'>"
      . "<button title='$line->{dhcp_port}' class='btn $btn_class'"
      . " onclick=\"fillSearchResults('$search_result_input_name', '$data_value')\"  >"
      . uc($line->{pon_type}) . " $line->{branch}:$line->{onu_id}</button>
        </div>";

    #Add to form
    #Equipment attach onu to user
    # $conf{EQUIPMENT_ONU_ATTACH}
    # NAS/PORT (DEFAULT)
    # MAC_SERIAL
    # SERVER_VLAN
    # VLAN

    push @all_rows, \@row;
  }

  print result_row_former({
    table => $table,
    ROWS  => \@all_rows,
  });

  print '<script>' . qq{jQuery(function () {
    var table = jQuery("#_EQUIPMENT_ONU_")
      .DataTable({
        "language": {
          paginate: {
            first:    "«",
            previous: "‹",
            next:     "›",
            last:     "»",
          },
          "zeroRecords":    "$lang{NOT_EXIST}",
          "lengthMenu":     "$lang{SHOW} _MENU_",
          "search":         "$lang{SEARCH}:",
          "info":           "$lang{SHOWING} _START_ - _END_ $lang{OF} _TOTAL_ ",
          "infoEmpty":      "$lang{SHOWING} 0",
          "infoFiltered":   "($lang{TOTAL} _MAX_)",
      },
      "ordering": false,
      "lengthMenu": [[25, 50, -1], [25, 50, "$lang{ALL}"]]
      });
      var column = table.column("0");

      // Toggle the visibility
      column.visible( ! column.visible() );
      table.search( 'free' ).draw();


       //<input type="search" class="form-control input-sm" placeholder="" aria-controls="_EQUIPMENT_ONU_">

      // Separate input for format independent MAC search
      var mac_input = jQuery('<input />', {
        'id' : 'EQUIPMENT_ONU_MAC',
        'class' : 'form-control input-sm',
        'type' : 'search'
        });

      mac_input.on('keyup',
       function(){
        var mac_any_format = this.value;
        var mac_symbols = mac_any_format.replace(/[:.]/gi,'').split('');
        console.log('raw symbols', mac_symbols);

        var mac_table_format = '';

        for (var i=0; i < mac_symbols.length; i++){

          if (i % 2 === 0 && i !== 0){
            mac_table_format += ':';
          }

          mac_table_format += mac_symbols[i];
        }

        console.log('search', mac_table_format);
        table.search(mac_table_format, false, false).draw();
      });

      var mac_label = jQuery('<label/>').text('MAC:').append(mac_input)
      jQuery('#_EQUIPMENT_ONU__filter').append(mac_label);


    });
    } . '</script>';

  return 1;
}

#********************************************************
=head2 pon_onu_state($id, $attr) - Get ONU info

  Arguments:
    $id
    $attr
      SNMP_COMMUNITY
      OUTPUT2RETURN
      VENDOR_ID
      BRANCH
      SHOW_FIELDS   - List fields on result
      NAS_ID        - NAS_ID
      snmp

  Returns:

=cut
#********************************************************
sub pon_onu_state {
  my ($id, $attr) = @_;

  $Equipment->vendor_info($attr->{VENDOR_ID} || $Equipment->{VENDOR_ID});

  if (!$id) {
    return [ [ 'Error:', "Can't find id" ] ];
  }

  #For old version
  my $nas_type = equipment_pon_init({ VENDOR_NAME => $Equipment->{NAME} });
  my $nas_id = $attr->{NAS_ID} || $FORM{NAS_ID};
  my $pon_type = $attr->{PON_TYPE} || $FORM{ONU_TYPE} || 'epon';
  my $vendor_name = $Equipment->{NAME} || '';
  my $model_name = $attr->{MODEL_NAME} || $attr->{NAS_INFO}->{MODEL_NAME} || '';

  if ($FORM{DEBUG}) {
    $attr->{DEBUG} = $FORM{DEBUG};
  }

  if (!$nas_type) {
    print "No PON device init\n";
    return 0;
  }

  if (!$attr->{VERSION}) {
    $attr->{VERSION} = $FORM{SNMP_VERSION} || $Equipment->{SNMP_VERSION};
  }

  if (!$attr->{BRANCH} || !$attr->{PORT}) {
    my $onu_list = $Equipment->onu_list({
      NAS_ID           => $nas_id,
      ONU_SNMP_ID      => $id,
      DELETED          => 0,
      NAS_NAME         => '_SHOW',
      ONU_ID           => '_SHOW',
      MAC_SERIAL       => '_SHOW',
      BRANCH           => '_SHOW',
      ONU_BILLING_DESC => '_SHOW',
      ONU_VLAN         => '_SHOW',
      COLS_NAME        => 1,
      PAGE_ROWS        => 10000
    });
    _error_show($Equipment);

    $attr->{BRANCH} = $onu_list->[0]{branch} || q{};
    $attr->{ONU_SERIAL} = $onu_list->[0]{mac_serial} || q{};
    $attr->{ONU_ID} = $onu_list->[0]{onu_id} || '0';
    $attr->{NAS_NAME} = $onu_list->[0]{nas_name} || q{};
    $attr->{PORT} = $onu_list->[0]{dhcp_port} || q{};
    $attr->{ONU_BILLING_DESC} = $onu_list->[0]{onu_billing_desc} || q{};
    $attr->{VLAN} = $onu_list->[0]{vlan} || q{};
  }

  my $snmp_info;
  if ($attr->{snmp}) {
    $snmp_info = $attr->{snmp};
  }
  else {
    $snmp_info = &{\&{$nas_type}}({ TYPE => $pon_type, MODEL => $model_name });
  }

  my $tr_069_data = tr_069_get_data({
    QUERY => {
      'InternetGatewayDevice.DeviceInfo.SerialNumber'   => $attr->{ONU_SERIAL},
      'InternetGatewayDevice.ManagementServer.Username' => $attr->{NAS_NAME}
    },
    PROJECTION => [ '_id' ], DEBUG => ($FORM{DEBUG} || 0)
  });

  my $tr_069_button = ($tr_069_data->[0]->{_id}) ? $html->button('',
    "NAS_ID=$nas_id&index=" . get_function_index('equipment_info')
      . "&visual=4&ONU=$id&info_pon_onu=" . ($attr->{ONU_SNMP_ID} || q{}) . "&ONU_TYPE=$pon_type&tr_069_id=$tr_069_data->[0]->{_id}",
    { class => 'btn btn-sm btn-success', ICON => 'fa fa-edit', TITLE => "TR-069" }) : '';

  my $get_onu_config_function = $nas_type . '_get_onu_config';

  require Internet;
  Internet->import();
  my $Internet = Internet->new($db, $admin, \%conf);

  # Show NAS_INFO tooltip
  my $select_input_tooltip = '';
  if ($nas_id) {
    my $Nas_info = Nas->new($db, \%conf, $admin);
    $Nas_info->info({ NAS_ID => $nas_id });
    _error_show($Nas_info, { ID => 976, MESSAGE => $lang{NAS} });

    $Internet->{NAS_NAME} = $Nas_info->{NAS_NAME} || '';
    $Internet->{NAS_IP} = $Nas_info->{NAS_IP} || '';
    $Internet->{NAS_MAC} = $Nas_info->{MAC} || '';
    $Internet->{NAS_TYPE} = $Nas_info->{NAS_TYPE} || '';

    $select_input_tooltip =
       $html->b($lang{NAME}) . ': ' . $Internet->{NAS_NAME} . $html->br()
      .$html->b('IP')        . ': ' . $Internet->{NAS_IP}   . $html->br()
      .$html->b('MAC')       . ': ' . $Internet->{NAS_MAC}  . $html->br()
      .$html->b('INFO')      . ': click to telnet'         . $html->br();
  }

# require Internet;

# use Data::Dumper;
# print Dumper($select_input_tooltip);
  my @info = ([
    $html->element( 'i', "", { class => 'fa fa-modal-window' } ) . $html->element('label', "&nbsp;&nbsp;&nbsp;&nbsp; ONU" ),
    # $html->element('span', "$pon_type " . ($attr->{BRANCH} || q{}) . ((defined $attr->{ONU_ID}) ? ":$attr->{ONU_ID}" : q{}),
    #   {class => 'btn btn-sm btn-secondary', TITLE => 'OLT INFO', 'data-tooltip-position' => 'left', 'data-tooltip'  => $select_input_tooltip,})
    $html->button("$pon_type " . ($attr->{BRANCH} || q{}) . ((defined $attr->{ONU_ID}) ? ":$attr->{ONU_ID}" : q{}), 'test',
      {class => 'btn btn-sm btn-secondary',
      TITLE => 'OLT ' . $Internet->{NAS_TYPE} . ' ↓ ↓ ↓ ↓',
      ex_params => "data-tooltip='$select_input_tooltip' data-tooltip-position='left'",
      GLOBAL_URL => 'telnet://' . $Internet->{NAS_IP}})

      . $html->button('', "NAS_ID=$nas_id&index=" . get_function_index('equipment_info') . "&visual=4&ONU=$id&info_pon_onu=" . ($attr->{ONU_SNMP_ID} || q{}) . "&ONU_TYPE=$pon_type",
      { class => 'btn btn-sm btn-success', ICON => 'fa fa-info-circle', TITLE => $lang{INFO} })
      . $tr_069_button
      . $html->button('',
      "NAS_ID=$nas_id&index=" . get_function_index('equipment_info')
        . "&visual=4&onuReset=$id&ONU=$id&tr_069_id=" . ($FORM{tr_069_id} || q{}) . "&info_pon_onu=" . ($attr->{ONU_SNMP_ID} || q{}) . "&ONU_TYPE=$pon_type",
      { MESSAGE => "$lang{REBOOT} ONU: $attr->{BRANCH}:$attr->{ONU_ID}?", class => 'btn btn-sm btn-warning', ICON => 'fa fa-retweet', TITLE => $lang{REBOOT} . " ONU" })
      . $html->button('',
      "NAS_ID=$nas_id&index=" . get_function_index('equipment_info')
        . "&visual=4&ONU_TYPE=$pon_type&del_onu=" . ($FORM{info_pon_onu} || $attr->{ONU_SNMP_ID}),
      { MESSAGE => "$lang{DEL} ONU: $attr->{BRANCH}:$attr->{ONU_ID}?", class => 'btn btn-sm btn-danger', ICON => 'fa fa-ban', TITLE => "$lang{DEL} ONU" })
      . (($get_onu_config_function && defined(&{$get_onu_config_function})) ?
        $html->button($lang{SHOW_ONU_CONFIG},
          "NAS_ID=$nas_id&index=" . get_function_index('equipment_info')
        . "&visual=4&ONU=$id&info_pon_onu=" . ($attr->{ONU_SNMP_ID} || q{}) . "&ONU_TYPE=$pon_type&get_onu_config=1",
          { class => 'btn btn-sm btn-primary', TITLE => $lang{SHOW_ONU_CONFIG} } )
        : "")
      . "($id)"
  ]);

  my $onu_abon = $Internet->user_list({
    LOGIN           => '_SHOW',
    FIO             => '_SHOW',
    ADDRESS_FULL    => '_SHOW',
    CID             => '_SHOW',
    ONLINE          => '_SHOW',
    ONLINE_IP       => '_SHOW',
    ONLINE_CID      => '_SHOW',
    TP_NAME         => '_SHOW',
    IP              => '_SHOW',
    LOGIN_STATUS    => '_SHOW',
    INTERNET_STATUS => '_SHOW',
    NAS_ID          => $nas_id,
    PORT            => $attr->{PORT},
    COLS_NAME       => 1,
    PAGE_ROWS       => 1000000
  });

  if ($onu_abon) {
    push @info, [$lang{LOGIN}, show_used_info($onu_abon)];
  }

  if ($FORM{tr_069_id}) {
    my $table = $html->table({
      width => '100%',
      qs    => $pages_qs,
      ID    => 'EQUIPMENT_ONU_INFO',
      rows  => \@info
    });

    print $table->show();
    tr_069_cpe_info($FORM{tr_069_id}, { %FORM });

    return 1;
  }

  if ($FORM{get_onu_config}) {
    #my $function = $nas_type . '_get_onu_config';
    if ($get_onu_config_function && defined(&{$get_onu_config_function})) {
      my @onu_config_arr = &{\&$get_onu_config_function}({%$attr, PON_TYPE => $pon_type});
      foreach my $line (@onu_config_arr) {
        $line->[1] =~ s/>/&gt;/g;
        $line->[1] =~ s/</&lt;/g;
        push @info, [ $line->[0], $html->element('pre', $line->[1], { class => "table" }) ];
      }
    }
  }

  #FETCH INFO
  my %onu_info = ();
  my $func_get_onu_info = $nas_type . '_get_onu_info';
  if (!$func_get_onu_info || !defined(&{$func_get_onu_info})) {
    $func_get_onu_info = 'default_get_onu_info';
  }
  if ($attr->{SHOW_FIELDS} && $conf{EQUIPMENT_USER_LINK} && $conf{EQUIPMENT_USER_LINK} =~ m/%USER_MAC%/) {
    $attr->{SHOW_FIELDS} .= ',MAC_BEHIND_ONU';
  }

  %onu_info = &{\&$func_get_onu_info}($id, {
    %$attr,
    NAS_TYPE  => $nas_type,
    PON_TYPE  => $pon_type,
    SNMP_INFO => $snmp_info
  });

  if(! $onu_info{$id}{VLAN} && $attr->{VLAN}) {
    $onu_info{$id}{VLAN} = $attr->{VLAN};
  }

  my $color_status = q{};
  if (defined $onu_info{$id}{STATUS}) {
    my $status = $onu_info{$id}{STATUS};

    $color_status = pon_onu_convert_state($nas_type, $status, $pon_type, {RETURN_COLOR => 1});
    $onu_info{$id}{STATUS} = pon_onu_convert_state($nas_type, $status, $pon_type);
  }

  if ($snmp_info->{main_onu_info}->{MAC_BEHIND_ONU}->{USE_MAC_LOG}) {
    my $mac_log_search_by_port_name = $snmp_info->{main_onu_info}->{MAC_BEHIND_ONU}->{MAC_LOG_SEARCH_BY_PORT_NAME};
    my $mac_log = $Equipment->mac_log_list({
      NAS_ID       => $nas_id,
      ($mac_log_search_by_port_name
        ? ( PORT_NAME =>
            (($mac_log_search_by_port_name eq 'no_pon_type') ? '' : uc $pon_type)
            . "$attr->{BRANCH}:$attr->{ONU_ID}"
          )
        : ( PORT => $id )),
      MAC          => '_SHOW',
      VLAN         => '_SHOW',
      ONLY_CURRENT => $conf{EQUIPMENT_SHOW_OLD_MAC_BEHIND_ONU} ? 0 : 1,
      DATETIME     => $conf{EQUIPMENT_SHOW_OLD_MAC_BEHIND_ONU} ? '_SHOW' : '',
      REM_TIME     => $conf{EQUIPMENT_SHOW_OLD_MAC_BEHIND_ONU} ? '_SHOW' : '',
      PAGE_ROWS    => 1000000,
      COLS_NAME    => 1
    });

    my %mac_behind_onu = map { $_->{id} => $_ } @$mac_log;
    if ($conf{EQUIPMENT_SHOW_OLD_MAC_BEHIND_ONU}) {
      map { $_->{old} = ($_->{rem_time} gt $_->{datetime}) } (values %mac_behind_onu);
    }
    $onu_info{$id}{MAC_BEHIND_ONU} = \%mac_behind_onu;
  }

  if ($conf{EQUIPMENT_USER_LINK}) {
    my $macs = '';
    if ($onu_info{$id}{MAC_BEHIND_ONU}) {
      $macs = join(',', sort map { $_->{mac} } grep { !$_->{old} } values %{$onu_info{$id}{MAC_BEHIND_ONU}} );
    }

    my $link = $conf{EQUIPMENT_USER_LINK};
    my $sw_port = ($attr->{BRANCH} && $attr->{ONU_ID}) ? "$attr->{BRANCH}:$attr->{ONU_ID}" : '';
    $link =~ s/%CPE_MAC%/$attr->{ONU_SERIAL}/g;
    $link =~ s/%SW_PORT%/$sw_port/g;
    $link =~ s/%USER_MAC%/$macs/g;

    push @info, [
      $lang{EXTERNAL_SYSTEM_LINK},
      $html->button($lang{EXTERNAL_SYSTEM_LINK}, '',
        {
          class      => 'btn btn-secondary',
          ICON       => 'fa fa-external-link-alt',
          GLOBAL_URL => $link
        }
      )
    ];
  }

  push @info, [
    $lang{ONU_BILLING_DESC} . $html->button('',
    "NAS_ID=$nas_id&header=2&get_index=equipment_change_onu_billing_desc_ajax&ONU=" . ($attr->{ONU_SNMP_ID} || q{}),
    { MESSAGE => $lang{CHANGE_ONU_DESC}, ALLOW_EMPTY_MESSAGE => 1, class => 'fa fa-pencil-alt ml-1', TITLE => $lang{CHANGE_ONU_DESC}, AJAX => 'onu_billing_desc_changed' })
    . "<script>
         Events.on('AJAX_SUBMIT.onu_billing_desc_changed', function(e){
           if (!e.error) {\$('#ONU_BILLING_DESC').text(e.new_desc)}
         });
       </script>",
    $html->element('span', $attr->{ONU_BILLING_DESC}, { id => 'ONU_BILLING_DESC' })
  ];

  $color_status //= 'text-black';

  # foreach my $i ( keys %onu_info) {
  #   print $i;
  #   foreach my $k (keys %{ $onu_info{$i} }) {
  #     print "$k -> " . ($onu_info{$i}->{$k} || '');
  #     print '<br>';
  #   }
  # }

  push @info, @{port_result_former(\%onu_info, {
    PORT         => $id,
    COLOR_STATUS => $color_status,
    #INFO_FIELDS => $info_fields
  })};

  if ($attr->{OUTPUT2RETURN}) {
    return \@info;
  }

  my $function = $nas_type . '_get_service_ports';
  if ($function && defined(&{$function})) {
    my @sp_arr = &{\&$function}({ %{$attr}, ONU_SNMP_ID => $id });
    foreach my $line (@sp_arr) {
      push @info, [ $line->[0], $line->[1] ];
    }
  }

  # check onu by user group permission
  my $admin_ = Admins->new($db, \%conf);
  my $admins_groups_list = $admin_->admins_groups_list({ AID => $admin->{AID} });

  if ($admins_groups_list) {
    my $gid = '';
    foreach my $line (@$admins_groups_list) {
      $gid .= "$line->[0],";
    }

    my $onu_list_gid = $Equipment->onu_list({
      NAS_ID      => $nas_id,
      ONU_SNMP_ID => $id,
      GID         => $gid,
      COLS_NAME   => 1,
    });

    if (!$onu_list_gid->[0]->{id}) {
      $html->message('err', $lang{ERROR}, "$lang{PERMISIION_DENIED}: $lang{GROUP}");
      return;
    }
  }

  my $table = $html->table({
    width => '100%',
    qs    => $pages_qs,
    ID    => 'EQUIPMENT_ONU_INFO',
    rows  => \@info
  });

  print $table->show();

  equipment_pon_onu_graph({
    ONU_SNMP_ID => $attr->{ONU_SNMP_ID},
    PON_TYPE    => $pon_type,
    snmp        => $snmp_info
  });

  if (!$attr->{snmp} || !$attr->{snmp}->{onu_info} || scalar keys %{$attr->{snmp}->{onu_info}} == 0) {
    return 0;
  }

  my %info_oids = ();

  foreach my $oid_name (keys %{$attr->{snmp}->{onu_info}}) {
    $info_oids{ uc($oid_name) } = $oid_name;
  }

  my $list;
  ($table, $list) = result_former({
    DEFAULT_FIELDS => 'ONUUNIIFSPEED,ONUUNIIFSPEEDLIMIT',
    BASE_PREFIX    => 'PORT,STATUS',
    TABLE          => {
      width            => '100%',
      caption          => $lang{PORTS},
      qs               => "&visual=$FORM{visual}&NAS_ID=$FORM{NAS_ID}&ONU=$FORM{ONU}",
      SHOW_COLS        => \%info_oids,
      SHOW_COLS_HIDDEN => {
        visual => $FORM{visual},
        NAS_ID => $FORM{NAS_ID},
        ONU    => $FORM{ONU},
      },
      ID               => 'EQUIPMENT_ONU_PORTS',
    },
  });

  my %ports_info = ();
  my @cols = ();
  if ($table->{COL_NAMES_ARR}) {
    @cols = @{$table->{COL_NAMES_ARR}};
  }

  foreach my $oid_name (@cols) {
    if (!$attr->{snmp}->{onu_info}->{ $info_oids{$oid_name} }) {
      next;
    }
    my $oid = $attr->{snmp}->{onu_info}->{ $info_oids{$oid_name} } . '.' . $id;
    my $value_arr = snmp_get({
      %{$attr},
      OID  => $oid,
      WALK => 1
    });

    foreach my $line (@{$value_arr}) {
      my ($port_id, $value) = split(/:/, $line, 2);
      $ports_info{$oid_name}{$id}{$port_id} = $value;
    }
  }

  my $ports_arr = snmp_get({
    %{$attr},
    WALK => 1,
    OID  => 'enterprises.3320.101.12.1.1.8.' . $id
  });

  my @all_rows = ();

  foreach my $key_ (sort @{$ports_arr}) {
    my ($port_id, $state) = split(/:/, $key_);

    if ($state == 1) {
      $state = "up";
    }
    elsif ($state == 2) {
      $state = "down";
    }

    my @arr = ($port_id, $state);

    for (my $i = 2; $i <= $#cols; $i++) {
      my $val_id = $cols[$i];
      push @arr, $ports_info{$val_id}{$id}{$port_id};
    }

    push @all_rows, \@arr;
  }

  print result_row_former({
    table => $table,
    ROWS  => \@all_rows,
  });

  return 1;
}

#********************************************************
=head2 default_get_onu_info($id, $attr) - Get specific ONU's info

  Arguments:
    $id
    $attr
      NAS_TYPE - result of equipment_pon_init()
      PON_TYPE
      SNMP_INFO - result of &{\&{$nas_type}}()
      SHOW_FIELDS - List fields on result
      CUSTOM_OID_ORDER - query only OIDs from array, in order as in array (main_onu_info is not affected)
      attrs for snmp_get

  Returns:
    %onu_info

=cut
#********************************************************
sub default_get_onu_info {
  my ($id, $attr) = @_;
  my ($nas_type, $pon_type, $snmp_info) = @{$attr}{'NAS_TYPE', 'PON_TYPE', 'SNMP_INFO'};

  my %onu_info = ();


  my @show_fields = ();
  if ($attr->{SHOW_FIELDS}) {
    @show_fields = split(/,\s?/, $attr->{SHOW_FIELDS});
  }

  my @data2hash_param = ('ETH_ADMIN_STATE', 'CATV_PORTS_ADMIN_STATUS', 'ETH_DUPLEX', 'ETH_SPEED', 'VLAN', 'MAC_BEHIND_ONU');
  my @oid_names = (ref $attr->{CUSTOM_OID_ORDER} eq 'ARRAY') ? @{$attr->{CUSTOM_OID_ORDER}} : (sort keys %{$snmp_info});
  foreach my $oid_name (@oid_names) {
    if ($#show_fields > -1 && !in_array($oid_name, \@show_fields)) {
      next;
    }

    my $oid = $snmp_info->{$oid_name}->{OIDS} || q{};
    my $timeout = $snmp_info->{$oid_name}->{TIMEOUT};

    if (!$oid || $oid_name eq 'reset' || $oid_name eq 'catv_port_manage' || $snmp_info->{$oid_name}->{SKIP}) {
      next;
    }

    my $add_2_oid = $snmp_info->{$oid_name}->{ADD_2_OID} || '';

    my $value = snmp_get({
      %$attr,
      OID     => $oid . '.' . $id . $add_2_oid,
      SILENT  => 1,
      TIMEOUT => $timeout || 2,
      WALK    => $snmp_info->{$oid_name}->{WALK}
    });

    my $function = $snmp_info->{$oid_name}->{PARSER};

    if ($function && defined(&{$function})) {
      ($value) = &{\&$function}($value);
    }

    if ($oid_name =~ /STATUS/ && defined $value) {
      my $func_onu_status = $nas_type . '_onu_status';
      if ($func_onu_status && defined(&{$func_onu_status})) {
        my $status_hash = &{\&$func_onu_status}($pon_type);
        $value = $status_hash->{$value} // $ONU_STATUS_TEXT_CODES{NOT_EXPECTED_STATUS};
      }
    }

    if ($snmp_info->{$oid_name}->{NAME}) {
      $oid_name = $snmp_info->{$oid_name}->{NAME};
    }

    if ($nas_type eq '_qtech' && $oid_name eq 'ONU_RX_POWER' && (!$value || $value == '0')) {
      $value = _qtech_get_power_telnet($attr, $id);
    }

    $onu_info{$id}{$oid_name} = $value;
  }

  if ($onu_info{$id}{STATUS} && $onu_info{$id}{STATUS} != $ONU_STATUS_TEXT_CODES{DEREGISTERED}) { #TODO: add statuses to skip?
    foreach my $oid_name (sort keys %{$snmp_info->{main_onu_info}}) {

      if ($#show_fields > -1 && !in_array($oid_name, \@show_fields)) {
        next;
      }

      my $oid = $snmp_info->{main_onu_info}->{$oid_name}->{OIDS};
      my $timeout = $snmp_info->{main_onu_info}->{$oid_name}->{TIMEOUT};

      if (!$oid) {
        next;
      }

      my $value = q{};

      if ($snmp_info->{main_onu_info}->{$oid_name}->{WALK}) {
        my $value_list = snmp_get({
          %{$attr},
          OID     => $oid . '.' . $id,
          TIMEOUT => $timeout || 3,
          WALK    => 1,
        });

        if ($value_list) {
          foreach my $line (@{$value_list}) {
            if (!$line) {
              next;
            }
            my ($oid_, $val) = split(/:/, $line, 2);
            my $function = $snmp_info->{main_onu_info}->{$oid_name}->{PARSER};
            if ($function && defined(&{$function})) {
              ($oid_, $val) = &{\&$function}($line);
            }

            if (in_array($oid_name, \@data2hash_param)) {
              #$onu_info{$id}{$oid_name}{$oid_} = $val;
              if (ref $onu_info{$id}{$oid_name} eq 'HASH') { #XXX always false?
                $onu_info{$id}{$oid_name}{$oid_} = $val;
              }
              else {
                $onu_info{$id}{$oid_name} = { $oid_ => $val };
              }
            }
            else {
              $value .= $oid_ . ' ' . $val . "\n"; #. $html->br();
            }
          }
        }
      }
      else {
        my $add_2_oid = $snmp_info->{main_onu_info}->{$oid_name}->{ADD_2_OID} || '';

        $value = snmp_get({
          %{$attr},
          OID     => $oid . '.' . $id . $add_2_oid,
          TIMEOUT => $timeout || 2,
        });

        my $function = $snmp_info->{main_onu_info}->{$oid_name}->{PARSER};
        if ($function && defined(&{$function})) {
          ($value) = &{\&$function}($value, $id, $attr, '1');
        }
      }

      if ($snmp_info->{main_onu_info}->{$oid_name}->{NAME}) {
        $oid_name = $snmp_info->{main_onu_info}->{$oid_name}->{NAME};
      }

      if (defined $value && $value ne '') {
        $onu_info{$id}{$oid_name} = $value;
      }
    }
  }

  return %onu_info;
}

#********************************************************
=head2 pon_tx_alerts($tx, $returns) - Make pon tx alerts

  Arguments:
    $tx      - Tx value
      Excellent  -10 >= $tx >= -27
      Worth      -30 >= $tx >= -8
      Very bad   $tx < -30 or $tx > -8
    $returns - return signal status code instead of HTML

  Returns:
    $tx - HTML with color marks
    or
    $result - signal status code
      0 - N/A
      1 - Excellent
      2 - Very bad
      3 - Worth

=cut
#********************************************************
sub pon_tx_alerts {
  my ($tx, $returns) = @_;

  my %signals = (
    'BAD'   => {
      'MIN' => ($conf{PON_LEVELS_ALERT}) ? $conf{PON_LEVELS_ALERT}{BAD}{MIN} : -30,
      'MAX' => ($conf{PON_LEVELS_ALERT}) ? $conf{PON_LEVELS_ALERT}{BAD}{MAX} : -8
    },
    'WORTH' => {
      'MIN' => ($conf{PON_LEVELS_ALERT}) ? $conf{PON_LEVELS_ALERT}{WORTH}{MIN} : -27,
      'MAX' => ($conf{PON_LEVELS_ALERT}) ? $conf{PON_LEVELS_ALERT}{WORTH}{MAX} : -10
    }
  );

  if (!$tx || $tx == 65535) {
    return 0 if ($returns);
    $tx = '';
  }
  elsif ($tx > 0) {
    return 1 if ($returns);
    $tx = $html->color_mark($tx, 'text-secondary');
  }
  elsif ($tx > $signals{BAD}{MAX} || $tx < $signals{BAD}{MIN}) {
    return 2 if ($returns);
    $tx = $html->color_mark($tx, 'text-red');
  }
  elsif ($tx > $signals{WORTH}{MAX} || $tx < $signals{WORTH}{MIN}) {
    return 3 if ($returns);
    $tx = $html->color_mark($tx, 'text-yellow');
  }
  else {
    return 1 if ($returns);
    $tx = $html->color_mark($tx, 'text-green');
  }

  return $tx;
}

#********************************************************
=head2 pon_alerts_video($tx, $returns) - Make pon alerts (video signal)

  Arguments:
    $tx      - Tx value
      Excellent  2  >= $tx >= -8
      Worth      3 >= $tx >= 10
      Very bad   $tx < -10 or $tx > 3
    $returns - return signal status code instead of HTML

  Returns:
    $tx - HTML with color marks
    or
    $result - signal status code
      0 - N/A
      1 - Excellent
      2 - Very bad
      3 - Worth

=cut
#********************************************************
sub pon_tx_alerts_video {
  my ($tx, $returns) = @_;

  my %signals = (
    'BAD'   => { 'MIN' => -10, 'MAX' => 3 },
    'WORTH' => { 'MIN' => -8, 'MAX' => 2 }
  );

  if ($tx eq '') {return '';}
  if (!defined $tx || $tx == 32767) {
    return 0 if ($returns);
    $tx = '';
  }

  if ($tx > $signals{BAD}{MAX} || $tx < $signals{BAD}{MIN}) {
    return 2 if ($returns);
    $tx = $html->color_mark($tx, 'text-red');
  }
  elsif ($tx > $signals{WORTH}{MAX} || $tx < $signals{WORTH}{MIN}) {
    return 3 if ($returns);
    $tx = $html->color_mark($tx, 'text-yellow');
  }
  else {
    return 1 if ($returns);
    $tx = $html->color_mark($tx, 'text-green');
  }

  return $tx;
}

#********************************************************
=head2 equipment_pon_ports($attr) - Show PON information

  Arguments:
    $attr
      SNMP_COMMUNITY
      NAS_INFO
      DEBUG

  Returns:
    TRUE or FALSE

=cut
#********************************************************
sub equipment_pon_ports {
  my ($attr) = @_;

  my @ports_state = ('', 'UP', 'DOWN', 'Damage', 'Corp vlan', 'Dormant', 'Not Present', 'lowerLayerDown');
  my @ports_state_color = ('', '#008000', '#FF0000');
  if ($attr->{NAS_INFO}) {
    $attr->{VERSION} //= $attr->{NAS_INFO}->{SNMP_VERSION};
  }

  my $debug = $attr->{DEBUG} || 0;
  my $nas_id = $FORM{NAS_ID} || 0;

  $Equipment->vendor_info($Equipment->{VENDOR_ID});
  #For old version
  if (!$attr->{VENDOR_NAME}) {
    $attr->{VENDOR_NAME} = $Equipment->{NAME};
  }

  my $nas_type = equipment_pon_init($attr);
  if (!$nas_type) {
    return 0;
  }

  my $func_ports_state = $nas_type . '_ports_state';
  if (defined(&{$func_ports_state})) {
    @ports_state = &{\&$func_ports_state}();
  }

  if ($FORM{chg_pon_port}) {
    $Equipment->pon_port_info($FORM{chg_pon_port});

    $Equipment->{ACTION} = 'change_pon_port';
    $Equipment->{ACTION_LNG} = $lang{CHANGE};
    $attr->{SNMP_TPL} = $attr->{NAS_INFO}->{SNMP_TPL};

    my $vlan_hash = get_vlans($attr);
    my %vlans = ();

    foreach my $vlan_id (keys %{$vlan_hash}) {
      $vlans{ $vlan_id } =
        "Vlan$vlan_id (" . (($vlan_hash->{ $vlan_id }->{NAME}) ? $vlan_hash->{ $vlan_id }->{NAME} : q{}) . ")";
    }

    $Equipment->{VLAN_SEL} = $html->form_select('VLAN_ID', {
      SELECTED    => $FORM{VLAN_ID} || '',
      SEL_OPTIONS => { '' => '--' },
      SEL_HASH    => \%vlans,
      NO_ID       => 1
    });

    $html->tpl_show(_include('equipment_pon_port', 'Equipment'), { %{$Equipment}, %FORM });
  }
  elsif ($FORM{change_pon_port}) {
    $Equipment->pon_port_change({ %FORM });
    if (!$Equipment->{errno}) {
      $html->message('info', $lang{INFO}, "$lang{CHANGED}");
    }
  }
  elsif (defined($FORM{del_pon_port}) && $FORM{COMMENTS}) {
    $Equipment->pon_port_del($FORM{del_pon_port});
    if (!$Equipment->{errno}) {
      $html->message('info', $lang{INFO}, "$lang{DELETED}");
    }
    elsif ($Equipment->{ONU_TOTAL}) {
      $html->message('err', $lang{ERROR}, "$lang{REGISTERED} $Equipment->{ONU_TOTAL} onu!");
    }
  }

  my $olt_ports = equipment_pon_get_ports({
    %{$attr},
    ONU_COUNT  => '_SHOW',
    NAS_ID     => $Equipment->{NAS_ID},
    NAS_TYPE   => $nas_type,
    SNMP_TPL   => $Equipment->{SNMP_TPL},
    MODEL_NAME => $Equipment->{MODEL_NAME}
  });

  foreach my $key (keys %$olt_ports) {
    next if (!$olt_ports->{$key}{pon_type});
    if ($olt_ports->{$key}{pon_type} eq 'epon') {
      my $possible_onu_count = $attr->{NAS_INFO}->{EPON_SUPPORTED_ONUS} || 64;
      $olt_ports->{$key}{FREE_ONU} = $possible_onu_count - $olt_ports->{$key}{onu_count};
    }
    elsif ($olt_ports->{$key}{pon_type} eq 'gpon') {
      my $possible_onu_count = $attr->{NAS_INFO}->{GPON_SUPPORTED_ONUS} || 128;
      $olt_ports->{$key}{FREE_ONU} = $possible_onu_count - $olt_ports->{$key}{onu_count};
    }
    elsif ($olt_ports->{$key}{pon_type} eq 'gepon') {
      my $possible_onu_count = $attr->{NAS_INFO}->{GEPON_SUPPORTED_ONUS} || 128;
      $olt_ports->{$key}{FREE_ONU} = $possible_onu_count - $olt_ports->{$key}{onu_count};
    }
  }

  $pages_qs = "&visual=$FORM{visual}&NAS_ID=$nas_id&TYPE=PON";
  my ($table) = result_former({
    DEFAULT_FIELDS => 'PON_TYPE,BRANCH,PORT_ALIAS,VLAN_ID,ONU_COUNT,FREE_ONU,PORT_STATUS,TRAFFIC,PORT_IN_ERR',
    BASE_PREFIX    => 'ID',
    TABLE          => {
      width            => '100%',
      caption          => "PON $lang{PORTS}",
      qs               => $pages_qs,
      SHOW_COLS        => {
        #ID          => 'Billing ID',
        BRANCH       => $lang{BRANCH},
        PON_TYPE     => $lang{TYPE},
        BRANCH_DESC  => "BRANCH_DESC",
        VLAN_ID      => "VLAN",
        TRAFFIC      => $lang{TRAFFIC},
        PORT_STATUS  => $lang{STATUS},
        PORT_SPEED   => $lang{SPEED},
        ONU_COUNT    => "ONU $lang{COUNT}",
        FREE_ONU     => "$lang{COUNT} $lang{FREE_ONU} ONU",
        PORT_NAME    => "BRANCH_NAME",
        PORT_ALIAS   => $lang{COMMENTS},
        PORT_IN_ERR  => "$lang{PACKETS_WITH_ERRORS} (in/out)",
      },
      SHOW_COLS_HIDDEN => {
        PON_TYPE => $FORM{PON_TYPE},
        OLT_PORT => $FORM{OLT_PORT},
        visual   => $FORM{visual},
        NAS_ID   => $nas_id,
        TYPE     => 'PON'
      },
      ID               => 'EQUIPMENT_PON_PORTS',
      EXPORT           => 1,
    }
  });

  my @cols = ();
  if ($table->{COL_NAMES_ARR}) {
    @cols = @{$table->{COL_NAMES_ARR}};
  }


  #Get onu list
  #my %onu_count = ();

  my @all_rows = ();
  my @ports_arr = keys %{$olt_ports};
  foreach my $port (@ports_arr) {
    my @row = ($port);
    for (my $i = 1; $i <= $#cols; $i++) {
      my $col_id = $cols[$i];

      if ($debug) {
        print "Port: $port col: $i '$col_id' // " . ($olt_ports->{$port}->{$col_id} || 'uninicialize') . " //<br>";
      }

      if ($col_id eq 'TRAFFIC') {
        push @row,
          "in: " . int2byte($olt_ports->{$port}{PORT_IN}) . $html->br() . "out: " . int2byte($olt_ports->{$port}{PORT_OUT});
      }
      elsif ($col_id eq 'ONU_COUNT') {
        my $onu = ($olt_ports->{$port}{ONU_COUNT}) ? $html->button($olt_ports->{$port}{ONU_COUNT},
          "index=$index&visual=4&NAS_ID=$FORM{NAS_ID}&PON_TYPE=$olt_ports->{$port}{PON_TYPE}&OLT_PORT=$olt_ports->{$port}{ID}") : q{};

        push @row, $onu;
      }
      elsif($col_id eq 'PORT_IN_ERR') {
        my $value = $html->color_mark(
          ($olt_ports->{$port}->{PORT_IN_ERR} // '?')
          . '/'
          . ($olt_ports->{$port}->{PORT_OUT_ERR} // '?'),
          ( $olt_ports->{$port}->{PORT_OUT_ERR} || $olt_ports->{$port}->{PORT_IN_ERR} ) ? 'text-danger' : undef );
        push @row, $value
      }
      elsif ($olt_ports->{$port} && $olt_ports->{$port}->{$col_id}) {
        if ($col_id eq 'PORT_STATUS') {
          push @row, ($olt_ports->{$port} && $olt_ports->{$port}{PORT_STATUS})
            ? $html->color_mark(
            $ports_state[ $olt_ports->{$port}{PORT_STATUS} ],
            $ports_state_color[ $olt_ports->{$port}{PORT_STATUS} ]) : '';
        }
        else {
          push @row, $olt_ports->{$port}->{$col_id};
        }
      }
      elsif($col_id eq 'PORT_ALIAS') {
        if (!$olt_ports->{$port}{PORT_ALIAS}){
          $olt_ports->{$port}{PORT_ALIAS} = $olt_ports->{$port}{BRANCH_DESC} || '';
        }
        push @row, $olt_ports->{$port}{PORT_ALIAS}
      }
      else {
        push @row, '';
      }
    }

    $olt_ports->{$port}{ID} ||= '';
    $olt_ports->{$port}{VLAN_ID} ||= '';

    push @row, $html->button($lang{INFO},
      "index=$index&chg_pon_port=" . $olt_ports->{$port}{ID}
        . "&VLAN_ID=" . $olt_ports->{$port}{VLAN_ID}
        . "&BRANCH_DESC=" . $olt_ports->{$port}{PORT_ALIAS} . $pages_qs,
      { class => 'change' })
      . $html->button($lang{DEL},
      "index=$index&del_pon_port=" . $olt_ports->{$port}{ID} . $pages_qs,
      { MESSAGE => "$lang{DEL} $lang{PORT}: $port?", class => 'del' });

    push @all_rows, \@row;
  }

  print result_row_former({
    table      => $table,
    ROWS       => \@all_rows,
    TOTAL_SHOW => 1,
  });

  return 1;
}

#********************************************************
=head2 equipment_pon_onu_graph($attr) - show element graphics

  Arguments:
    $attr
      ONU_SNMP_ID
      PON_TYPE
      snmp

=cut
#********************************************************
sub equipment_pon_onu_graph {
  my ($attr) = @_;

  my $snmp_id = $attr->{ONU_SNMP_ID} || $FORM{graph_onu};
  my $onu_info = $Equipment->onu_info($snmp_id);
  my $pon_type = $attr->{PON_TYPE} || $FORM{ONU_TYPE};

  if (!defined($Equipment->{ONU_ID})) {
    return 0;
  }

  my @onu_graph_types = split(',', $onu_info->{ONU_GRAPH} || q{});
  my $snmp_info = $attr->{snmp};
  my %graph_hash = ();
  my $date_picker = '';
  my $result = '';

  my $start_time = time() - 24 * 3600;
  my $end_time = time();

  if ($FORM{FROM_DATE} && $FORM{FROM_DATE} =~ m/(\d+)-(\d+)-(\d+) (\d+):(\d+)/) {
    $start_time =  timelocal(0, $5, $4, $3, $2-1, $1);
  }
  if ($FORM{TO_DATE} && $FORM{TO_DATE} =~ m/(\d+)-(\d+)-(\d+) (\d+):(\d+)/) {
    $end_time =  timelocal(0, $5, $4, $3, $2-1, $1);
  }

  my $daterangepicker_default = strftime("%F %T", localtime($start_time)) . '/' . strftime("%F %T", localtime($end_time));
  $date_picker = $html->form_daterangepicker({
    NAME      =>'FROM_DATE/TO_DATE',
    FORM_NAME => 'TIMERANGE',
    WITH_TIME => 1,
    VALUE     => $daterangepicker_default
  });

  $result .= $html->element('div', "$lang{PERIOD} $lang{FOR_GRAPH}", { class => 'card-header card-title'});
  $result .= $html->element('div', $date_picker, { class => 'card-body' });
  $result .= $html->form_input('show', $lang{SHOW}, { TYPE => 'submit', FORM_ID => 'period_panel' });

  my $report_form = $html->element('div', $result, {
    class => 'card card-primary card-outline card-form',
  });

  require Equipment::Graph;

  foreach my $graph_type (@onu_graph_types) {
    my @onu_ds_names = ();
    if ($graph_type eq 'SIGNAL' && $snmp_info && ($snmp_info->{ONU_RX_POWER}->{OIDS} || $snmp_info->{OLT_RX_POWER}->{OIDS})) {
      push @onu_ds_names, $snmp_info->{ONU_RX_POWER}->{NAME} || q{};
      push @onu_ds_names, $snmp_info->{OLT_RX_POWER}->{NAME} || q{};
      $graph_hash{SIGNAL} = get_graph_data({
        NAS_ID     => $FORM{NAS_ID},
        PORT       => $onu_info->{ONU_SNMP_ID},
        TYPE       => 'SIGNAL',
        DS_NAMES   => \@onu_ds_names,
        START_TIME => $start_time,
        END_TIME   => $end_time
      });

      $graph_hash{SIGNAL}{DIMENSION} = 'dBm' if $graph_hash{SIGNAL};
    }
    elsif ($graph_type eq 'TEMPERATURE' && $snmp_info->{TEMPERATURE}->{OIDS}) {
      push @onu_ds_names, $snmp_info->{TEMPERATURE}->{NAME};
      $graph_hash{TEMPERATURE} = get_graph_data({
        NAS_ID     => $FORM{NAS_ID},
        PORT       => $onu_info->{ONU_SNMP_ID},
        TYPE       => 'TEMPERATURE',
        DS_NAMES   => \@onu_ds_names,
        START_TIME => $start_time,
        END_TIME   => $end_time
      });
      $graph_hash{TEMPERATURE}{DIMENSION} = '?C' if $graph_hash{TEMPERATURE};
    }
    elsif ($graph_type eq 'SPEED' && ($snmp_info->{ONU_IN_BYTE}->{OIDS} || $snmp_info->{ONU_OUT_BYTE}->{OIDS})) {
      push @onu_ds_names, $snmp_info->{ONU_IN_BYTE}->{NAME};
      push @onu_ds_names, $snmp_info->{ONU_OUT_BYTE}->{NAME};
      $graph_hash{SPEED} = get_graph_data({
        NAS_ID     => $FORM{NAS_ID},
        PORT       => $onu_info->{ONU_SNMP_ID},
        TYPE       => 'SPEED',
        DS_NAMES   => \@onu_ds_names,
        START_TIME => $start_time,
        END_TIME   => $end_time
      });

      $graph_hash{SPEED}{DIMENSION} = 'Mbit/s' if $graph_hash{SPEED};
    }
  }

  my @graphs = ();

  foreach my $graph_type (sort keys %graph_hash) {
    my $graph = $graph_hash{ $graph_type };
    my @time_arr = ();
    my %graph_data = ();
    if ($graph) {
      foreach my $val (@{$graph->{data}}) {
        push @time_arr, POSIX::strftime("%b %d %H:%M", localtime($val->[0]));

        for (my $i = 0; $i <= $#{$graph->{meta}->{legend}}; $i++) {
          my $_index = $i + 1;
          if ($graph_type eq 'SPEED') {
            $val->[$_index] = sprintf("%.2f", $val->[$_index] / (1024 * 1024) * 8) if ($val->[$_index]);
          }
          else {
            $val->[$_index] = sprintf("%.2f", $val->[$_index]) if ($val->[$_index]);
          }
          push @{$graph_data{ $graph->{meta}->{legend}->[$i] }}, $val->[$_index];
        }
      }

      push @graphs, $html->make_charts_simple({
        GRAPH_ID      => lc($graph_type),
        DIMENSION     => $graph->{DIMENSION},
        TITLE         => $lang{uc($graph_type)} || $graph_type,
        TRANSITION    => 1,
        X_TEXT        => \@time_arr,
        DATA          => \%graph_data,
        OUTPUT2RETURN => 1
      });
    }
  }
  #_error_show($Equipment);

  print $html->form_main({
    CONTENT => $report_form, #. $FIELDS . $TAGS,
    HIDDEN  => {
      index        => $index,
      visual       => $FORM{visual},
      NAS_ID       => $FORM{NAS_ID},
      #graph_onu => $snmp_id,
      ONU_TYPE     => $pon_type,
      info_pon_onu => $FORM{info_pon_onu},
      ONU          => $FORM{ONU}
    },
    NAME    => 'period_panel',
    ID      => 'period_panel',
    class   => 'card-body',
  });

  $result = '';
  foreach my $graph (@graphs) {
    Encode::_utf8_off($graph);
    $result .= $html->element('div', ($graph || q{}), { class => 'col-md-' . (12 / ($#graphs + 1))});
  }
  print $html->element('div', $result, {class => 'row'});

  return 1;
}

#**********************************************************
=head2 pon_onu_convert_state($nas_type, $status, $pon_type)

  Arguments:
    $nas_type
    $status
    $pon_type

  Results:
    $status

=cut
#**********************************************************
sub pon_onu_convert_state {
  my ($nas_type, $status, $pon_type, $attr) = @_;

  if (!defined $status) {
    $status = $ONU_STATUS_TEXT_CODES{NOT_EXPECTED_STATUS};
  }

  my ($status_desc, $color) = split(/:/, $ONU_STATUS_CODE_TO_TEXT{ $status });
  $status = $html->color_mark($status_desc, $color);

  return $color if ($attr->{RETURN_COLOR});

  return $status;
}
#**********************************************************
=head2 equipment_pon_form()

=cut
#**********************************************************
sub equipment_pon_form {

  $Equipment->{OLT_SEL} = $html->form_select(
    'NAS_ID',
    {
      SEL_OPTIONS => { '' => '--' },
      SEL_LIST    => $Equipment->_list({ NAS_NAME => '_SHOW', COLS_NAME => 1, PAGE_ROWS => 10000, TYPE_NAME => 4 }),
      SEL_KEY     => 'nas_id',
      SEL_VALUE   => 'nas_id,nas_name',
      NO_ID       => 1,
    }
  );
  $FORM{INDEX} = get_function_index('equipment_info');
  $html->tpl_show(_include('equipment_pon', 'Equipment'), { %{$Equipment}, %FORM });

  return 1;
}

#**********************************************************
=head2 equipment_tv_port() - Disable or enable TV Port on ONU

  You may provide all NAS&ONU info, or you may provide only UID - ONU of this user will be used.

  Arguments:
    $attr
      CATV_PORT_ID - ID of CATV port to disable/enable
      DISABLE_PORT - disables TV port
      ENABLE_PORT - enables TV port

      UID - if set, finds ONU of this user and works with this ONU
      or
      snmp - hashref of SNMP OIDs. optional
      SNMP_COMMUNITY - optional. if not set, nas_mng_ip_port and nas_mng_password from NAS_INFO will be used
      ONU_TYPE - required if snmp is not set
      ONU_SNMP_ID - SNMP ID of ONU to work with
      NAS_INFO
        vendor_name
        model_name
        nas_mng_password
        nas_mng_ip_port
        snmp_version

      DEBUG

  Returns:
    TRUE or FALSE

=cut
#**********************************************************
sub equipment_tv_port {
  my ($attr) = @_;

  my $SNMP_COMMUNITY = $attr->{SNMP_COMMUNITY};
  my $nas_info = $attr->{NAS_INFO};
  my $snmp_info = $attr->{snmp};
  my $onu_snmp_id = $attr->{ONU_SNMP_ID};

  my $onu_type = $attr->{ONU_TYPE};
  my $catv_port_id = $attr->{CATV_PORT_ID};

  if ($attr->{UID}) {
    if(!in_array('Internet', \@MODULES)) {
      print "Can't work without module Internet when UID is set\n" if ($attr->{DEBUG});
      return 0;
    }

    require Internet;
    Internet->import();
    my $Internet = Internet->new($db, $admin, \%conf);

    my $internet_info = $Internet->user_info($attr->{UID});
    if (!$internet_info->{TOTAL}) {
      print "No user with UID $attr->{UID}\n" if ($attr->{DEBUG});
    }

    if (!$internet_info->{NAS_ID} || !$internet_info->{PORT}) {
      print "User with UID $attr->{UID} don't have ONU\n" if ($attr->{DEBUG});
      return 0;
    }

    my $nas_list = $Equipment->_list({
      NAS_MNG_HOST_PORT=> '_SHOW',
      NAS_MNG_PASSWORD => '_SHOW',
      VENDOR_NAME      => '_SHOW',
      MODEL_NAME       => '_SHOW',
      SNMP_VERSION     => '_SHOW',
      STATUS           => '_SHOW',
      NAS_ID           => $internet_info->{NAS_ID},
      COLS_NAME        => 1,
      COLS_UPPER       => 1
    });
    $nas_info = $nas_list->[0];

    my $onu_list = $Equipment->onu_list({
      ONU_DHCP_PORT => $internet_info->{PORT},
      NAS_ID        => $internet_info->{NAS_ID},
      DELETED       => 0,
      ONU_SNMP_ID   => '_SHOW',
      COLS_NAME     => 1
    });

    if (!$onu_list) {
      print "Can't find ONU\n" if ($attr->{DEBUG});
      return 0;
    }

    my $onu_info = $onu_list->[0];
    $onu_type = $onu_info->{pon_type};
    $onu_snmp_id = $onu_info->{onu_snmp_id};
  }

  if (!$snmp_info) {
    my $nas_type = equipment_pon_init({VENDOR_NAME => $nas_info->{VENDOR_NAME}});

    if (!$nas_type) {
      return 0;
    }

    $snmp_info = &{\&{$nas_type}}({ TYPE => $onu_type, MODEL => $nas_info->{MODEL_NAME} });
  }

  if (!$SNMP_COMMUNITY) {
    $SNMP_COMMUNITY = ($nas_info->{NAS_MNG_PASSWORD} || '') . '@' . $nas_info->{NAS_MNG_IP_PORT};
  }
  my $snmp_version = $nas_info->{SNMP_VERSION};

  if ($snmp_info->{catv_port_manage}->{USING_CATV_PORT_ID} && !$catv_port_id) {
    print "No CATV port ID\n" if ($attr->{DEBUG});
    return 0;
  }

  my $set_value;
  if ($attr->{DISABLE_PORT}) {
    $set_value = $snmp_info->{catv_port_manage}->{DISABLE_VALUE};
  }
  elsif ($attr->{ENABLE_PORT}) {
    $set_value = $snmp_info->{catv_port_manage}->{ENABLE_VALUE};
  }
  else {
    print "Disable or enable port? Exiting.\n" if ($attr->{DEBUG});
    return 0;
  }

  return if !$snmp_info->{catv_port_manage}->{OIDS};

  my $set_result = snmp_set({
    SNMP_COMMUNITY => $SNMP_COMMUNITY,
    VERSION        => $snmp_version,
    OID            => [ $snmp_info->{catv_port_manage}->{OIDS} .
                          '.' . $onu_snmp_id .
                          (($snmp_info->{catv_port_manage}->{USING_CATV_PORT_ID}) ? ('.' . $catv_port_id) : '') .
                          ($snmp_info->{catv_port_manage}->{ADD_2_OID} || ''),
                        $snmp_info->{catv_port_manage}->{VALUE_TYPE} || "integer",
                        $set_value ]
  });

  return $set_result;
}

#**********************************************************
=head2 equipment_change_onu_billing_desc_ajax($attr) - change ONU billing description. to be called using AJAX

  Arguments:
    $FORM{ONU}      - ONU ID
    $FORM{COMMENTS} - New description

  Return:
    0

  Prints JSON:
    MESSAGE  - message object for tooltip
      caption
      messaga
      message_type
    error    - 0 or 1
    new_desc - new description

=cut
#**********************************************************
sub equipment_change_onu_billing_desc_ajax {

  my $error = 0;
  my $errmsg = '';

  if ($permissions{7} && $permissions{7}{5}) {
    $Equipment->onu_change({ID => $FORM{ONU}, ONU_BILLING_DESC => $FORM{COMMENTS}});
    if ($Equipment->{errno}) {
      $error = 1;
    }
  }
  else {
    $error = 1;
    $errmsg = $lang{ERR_ACCESS_DENY};
  }

  my $json = JSON->new->utf8(0);
  $html->{JSON_OUTPUT} = [
    {
      MESSAGE => $json->encode({
        caption      => $error ? $lang{ONU_DESC_CHANGING_ERROR} : $lang{ONU_DESC_CHANGING_SUCCESS},
        messaga      => $errmsg,
        message_type => $error ? 'err' : 'info'
      }),
    },
    {
      error => $error
    },
    {
      new_desc => ($error ? '""' : "\"$FORM{COMMENTS}\"")
    }
  ];
  return 0;
}

1
