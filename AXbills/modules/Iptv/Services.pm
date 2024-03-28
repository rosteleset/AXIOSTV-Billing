=head1 NAME

  TV services

=cut

use strict;
use warnings FATAL => 'all';
use AXbills::Filters qw(_utf8_encode);

our (
  $html,
  %lang,
  $db,
  $admin,
  %conf,
  %FORM,
  $pages_qs,
  $index,
  %permissions,
  $DATE,
);

our Iptv $Iptv;

#**********************************************************
=head2 tv_services($attr)

  Arguments:
    $attr

  Results:

=cut
#**********************************************************
sub tv_services {

  $Iptv->{ACTION} = 'add';
  $Iptv->{LNG_ACTION} = $lang{ADD};

  if ($FORM{extra_params}) {
    _service_extra_params();
    return 1;
  }
  elsif ($FORM{add}) {
    $Iptv->services_add({ %FORM });
    $FORM{DEBUG} = 0;
    if (!$Iptv->{errno}) {
      $html->message('info', $lang{SERVICES}, $lang{ADDED});
      tv_service_info($Iptv->{INSERT_ID});
    }
  }
  elsif ($FORM{change}) {
    $FORM{STATUS} ||= 0;
    $Iptv->services_change(\%FORM);
    $FORM{DEBUG} = 0;
    if (!_error_show($Iptv)) {
      $html->message('info', $lang{SERVICES}, $lang{CHANGED});
      tv_service_info($FORM{ID});
    }
  }
  elsif ($FORM{chg}) {
    tv_service_info($FORM{chg});
  }
  elsif ($FORM{del} && $FORM{COMMENTS}) {
    $Iptv->services_del($FORM{del});
    if (!$Iptv->{errno}) {
      $html->message('info', $lang{SERVICES}, $lang{DELETED});
    }
  }
  _error_show($Iptv);

  $Iptv->{USER_PORTAL_SEL} = $html->form_select('USER_PORTAL', {
    SELECTED => $Iptv->{USER_PORTAL} || $FORM{USER_PORTAL} || 0,
    SEL_HASH => {
      0 => '--',
      1 => $lang{INFO},
      2 => $lang{CONTROL} || 'Control'
    },
    NO_ID    => 1
  });

  $Iptv->{DEBUG_SEL} = $html->form_select('DEBUG', {
    SELECTED  => $Iptv->{DEBUG} || $FORM{DEBUG} || 0,
    SEL_ARRAY => [ 0, 1, 2, 3, 4, 5, 6, 7 ],
  });

  $html->tpl_show(_include('iptv_services_add', 'Iptv'), { %FORM, %$Iptv });

  my @service_functions = ();
  push @service_functions, 'change' if $permissions{4} && $permissions{4}{2};
  push @service_functions, 'del' if $permissions{4} && $permissions{4}{3};

  result_former({
    INPUT_DATA        => $Iptv,
    FUNCTION          => 'services_list',
    DEFAULT_FIELDS    => 'NAME,MODULE,STATUS,COMMENT',
    FUNCTION_FIELDS   => join(',', @service_functions),
    EXT_TITLES        => {
      comment => $lang{COMMENTS},
      name    => $lang{NAME},
      module  => $lang{MODULE},
      status  => $lang{STATUS}
    },
    SKIP_USERS_FIELDS => 1,
    TABLE             => {
      width   => '100%',
      caption => "$lang{TV} $lang{SERVICES}",
      qs      => $pages_qs,
      ID      => 'TV_SERVICES',
      MENU    => "$lang{ADD}:index=" . get_function_index('tv_services') . "&add_form=1:add"
    },
    MAKE_ROWS         => 1,
    TOTAL             => 1,
  });

  return 1;
}


#**********************************************************
=head2 tv_service_info($id)

  Arguments:
    $id

  Results:

=cut
#**********************************************************
sub tv_service_info {
  my ($id, $attr) = @_;

  $Iptv->services_info($id);
  if (!$Iptv->{errno}) {
    $FORM{add_form} = 1;
    $Iptv->{ACTION} = 'change';
    $Iptv->{LNG_ACTION} = $lang{CHANGE};
    if ($Iptv->{PROVIDER_PORTAL_URL}) {
      $Iptv->{PROVIDER_PORTAL_BUTTON} = _service_portal_filter($Iptv->{PROVIDER_PORTAL_URL});
    }
    $html->message('info', $lang{SERVICES}, $lang{CHANGING});

    if ($Iptv->{MODULE}) {
      my $Tv_service = tv_load_service($Iptv->{MODULE}, { SERVICE_ID => $Iptv->{ID}, SOFT_EXCEPTION => 1 });
      if ($Tv_service && $Tv_service->{VERSION}) {
        $Iptv->{MODULE_VERSION} = $Tv_service->{VERSION};
      }

      if ($Tv_service && $Tv_service->can('tp_export')) {
        $Iptv->{TP_IMPORT} = $html->button("$lang{IMPORT} $lang{TARIF_PLAN}", "index=$index&tp_import=1&chg=$Iptv->{ID}",
          { class => 'btn btn-secondary btn-success' });
        if (!tv_service_import_tp($Tv_service)) {
          return 0;
        }
      }

      if ($Tv_service && $Tv_service->can('channel_export')) {
        $Iptv->{CHANNEL_IMPORT} = $html->button("$lang{IMPORT} $lang{CHANNELS}", "index=$index&channel_import=1&chg=$Iptv->{ID}",
          { class => 'btn btn-secondary btn-success' });
        tv_service_import_channels($Tv_service);
      }

      if ($Tv_service && $Tv_service->can('test')) {
        if ($FORM{test}) {
          my $result = $Tv_service->test();
          if (!$Tv_service->{errno}) {
            $html->message('info', $lang{INFO}, "$lang{TEST}\n$result");
          }
          else {
            _error_show($Tv_service, { MESSAGE => 'Test:' });
          }
        }

        $Iptv->{SERVICE_TEST} = $html->button($lang{TEST}, "index=$index&test=1&chg=$Iptv->{ID}",
          { class => 'btn btn-info' });
      }

      if ($Tv_service && $Tv_service->can('user_params')) {
        $Iptv->{SERVICE_PARAMS} = $html->button($lang{PARAMS}, "index=$index&extra_params=1&service_id=$Iptv->{ID}",
          { class => 'btn btn-default' });
      }

      $Iptv->{CONSOLE} = $html->button('Console', "index=" . get_function_index('iptv_console') . "&SERVICE_ID=$Iptv->{ID}",
        { class => 'btn btn-default' });
    }
  }

  #$Iptv->{USER_PORTAL} = ($Iptv->{USER_PORTAL}) ? 'checked' : '';
  $Iptv->{STATUS} = ($Iptv->{STATUS}) ? 'checked' : '';

  return 1;
}

#**********************************************************
=head2 tp_service_import_tp($attr)

  Arguments:

  Returns:

=cut
#**********************************************************
sub tv_service_import_channels {
  my ($Tv_service) = @_;

  my $channel_list = $Tv_service->channel_export();
  if ($FORM{channel_import}) {
    my $message = '';
    my @tp_ids = split(/,\s?/, $FORM{IDS} || q{});

    foreach my $tp_id (@tp_ids) {
      my $iptv_tp_id = 0;
      $Iptv->channel_add({
        NUM       => $tp_id,
        NAME      => $FORM{'NAME_' . $tp_id},
        FILTER_ID => $tp_id,
      });
      _error_show($Iptv, { MESSAGE => "$lang{CHANNEL}: " . $tp_id });

      $message .= "$Iptv->{ID} $tp_id - $FORM{'NAME_' . $tp_id} $lang{TYPE}:"
        . $lang{CHANNELS}
        . (($iptv_tp_id) ? ' ' . $html->button('', "index=" . get_function_index('iptv_tp') . "&TP_ID=" . $iptv_tp_id, { class => 'change' }) : '')
        . "\n";
    }
    $html->message('info', $lang{INFO}, $message);
    tv_service_export_form($Tv_service, $channel_list);
  }

  return 1;
}

#**********************************************************
=head2 tv_service_import_tp($attr)

  Arguments:

  Returns:

=cut
#**********************************************************
sub tv_service_import_tp {
  my ($Tv_service) = @_;

  if ($FORM{tp_import}) {
    my %SUBCRIBES_TYPE = (
      0 => $lang{TARIF_PLAN},
      1 => $lang{CHANNELS}
    );

    $Tv_service->{SERVICE_ID} = $FORM{chg} if $FORM{chg};
    my $tp_list = $Tv_service->tp_export();

    if($Tv_service->{errno}) {
      _error_show($Tv_service, { MESSAGE => "$lang{TARIF_PLANS} $lang{IMPORT}" });
      return 0;
    }

    if ($FORM{tp_import} == 2) {
      my $Tariffs = Tariffs->new($db, \%conf, $admin);
      my $message = '';
      my @tp_ids = split(/,\s?/, $FORM{IDS} || q{});

      foreach my $tp_id (@tp_ids) {
        my $iptv_tp_id = 0;
        if ($FORM{'TP_TYPE_' . $tp_id}) {
          $Iptv->channel_add({
            NUM       => $tp_id,
            NAME      => $FORM{'NAME_' . $tp_id},
            FILTER_ID => $tp_id,
          });

          _error_show($Iptv, { MESSAGE => "$lang{CHANNEL}: " . $tp_id });
        }
        else {
          $Tariffs->add({
            SERVICE_ID => $Iptv->{ID},
            NAME       => $FORM{'NAME_' . $tp_id},
            FILTER_ID  => $tp_id,
            ID         => $tp_id,
            MODULE     => 'Iptv'
          });
          $iptv_tp_id = $Tariffs->{TP_ID};
          _error_show($Tariffs, { MESSAGE => "$lang{TARIF_PLAN}: " . $tp_id });
        }

        $message .= "$Iptv->{ID} $tp_id - $FORM{'NAME_' . $tp_id} $lang{TYPE}:"
          . $SUBCRIBES_TYPE{$FORM{'TP_TYPE_' . $tp_id}}
          . (($iptv_tp_id) ? ' ' . $html->button('', "index=" . get_function_index('iptv_tp') . "&TP_ID=" . $iptv_tp_id, { class => 'change' }) : '')
          . "\n";
      }
      $html->message('info', $lang{INFO}, $message);
    }
    else {
      tv_service_export_form($Tv_service, $tp_list);
      return 0;
    }
  }

  return 1;
}

#**********************************************************
=head2 tv_service_export_form($tp_list)

  Arguments:
    $Tv_service
    $tp_list
    $attr

  Results:

=cut
#**********************************************************
sub tv_service_export_form {
  my ($Tv_service, $tp_list) = @_;

  my %SUBCRIBES_TYPE = (
    0 => $lang{TARIF_PLAN},
    1 => $lang{CHANNELS}
  );

  my $table = $html->table({
    width       => '100%',
    caption     => $lang{SUBSCRIBES},
    title_plain => [ '#', $lang{NUM}, $lang{NAME}, $lang{TYPE} ],
    ID          => 'IPTV_EXPORT_TPS',
    EXPORT      => 1
  });

  foreach my $tp (@$tp_list) {
    my $tp_type = q{};

    if ($Tv_service->{TP_LIST}) {
      $tp_type = $lang{TARIF_PLAN} . $html->form_input('TP_TYPE_' . $tp->{ID}, 0, { EX_PARAMS => 'readonly', TYPE => 'hidden' });
    }
    elsif ($Tv_service->{CHANNEL_LIST}) {
      $tp_type = $lang{CHANNEL} . $html->form_input('TP_TYPE_' . $tp->{ID}, 0, { EX_PARAMS => 'readonly', TYPE => 'hidden' });
    }
    else {
      $tp_type = $html->form_select('TP_TYPE_' . $tp->{ID}, {
        SELECTED => 0,
        SEL_HASH => \%SUBCRIBES_TYPE,
        NO_ID    => 1
      });
    }

    my $tp_name = $tp->{NAME};
    my $is_utf = Encode::is_utf8($tp_name);
    if (!$is_utf) {
      Encode::_utf8_off($tp_name);
    }

    $table->addrow(
      $html->form_input('IDS', $tp->{ID}, { TYPE => 'checkbox' }),
      $tp->{ID},
      $html->form_input('NAME_' . $tp->{ID}, $tp_name, { EX_PARAMS => 'readonly' }),
      $tp_type
    );
  }

  my %extra_option = (tp_import => 2);

  if ($Tv_service->{CHANNEL_LIST}) {
    %extra_option = (channel_import => 1);
  }

  print $html->form_main({
    CONTENT => $table->show({ OUTPUT2RETURN => 1 }),
    HIDDEN  => {
      index     => $index,
      %extra_option,
      chg       => $Iptv->{ID},
    },
    METHOD  => 'post',
    SUBMIT  => { import => $lang{IMPORT} }
  });

  return 1;
}


#**********************************************************
=head2 tv_services_sel($attr)

  Arguments:
     SERVICE_ID
     FORM_ROW
     USER_PORTAL
     HASH_RESULT
     ALL
     SKIP_DEF_SERVICE
     UNKNOWN

  Returns:

=cut
#**********************************************************
sub tv_services_sel {
  my ($attr) = @_;

  my %params = ();

  $params{SEL_OPTIONS} = { '' => $lang{ALL} } if ($attr->{ALL} || $FORM{search_form});
  $params{SEL_OPTIONS}->{0} = $lang{UNKNOWN} if ($attr->{UNKNOWN});
  $params{NO_ID} = $attr->{NO_ID};
  $params{AUTOSUBMIT} = $attr->{AUTOSUBMIT} if defined($attr->{AUTOSUBMIT});

  my $active_service = $attr->{SERVICE_ID} || $FORM{SERVICE_ID};

  my $service_list = $Iptv->services_list({
    STATUS      => 0,
    NAME        => '_SHOW',
    USER_PORTAL => $attr->{USER_PORTAL},
    COLS_NAME   => 1,
    PAGE_ROWS   => 1,
    SORT        => 's.id'
  });

  if ($attr->{HASH_RESULT}) {
    my %service_name = ();

    foreach my $line (@$service_list) {
      $service_name{$line->{id}} = $line->{name};
    }

    return \%service_name;
  }

  if ($Iptv->{TOTAL} && $Iptv->{TOTAL} > 0) {
    if($Iptv->{TOTAL} == 1) {
      delete $params{SEL_OPTIONS};
      $Iptv->{SERVICE_ID} = $service_list->[0]->{id};
    }
    else {
      if (!$FORM{SERVICE_ID} && !$active_service) {
        $FORM{SERVICE_ID} = $service_list->[0]->{id};
        $active_service = $service_list->[0]->{id};
      }
    }
  }

  if (!$attr->{HIDE_MENU_BTN} && $permissions{4} && $permissions{4}{2}) {
    $params{MAIN_MENU} = get_function_index('tv_services');
    $params{MAIN_MENU_ARGV} = ($active_service) ? "chg=$active_service" : q{};
  }

  my $result = $html->form_select('SERVICE_ID', {
    SELECTED  => $active_service,
    SEL_LIST  => $service_list,
    EX_PARAMS => defined($attr->{EX_PARAMS}) ? $attr->{EX_PARAMS} : "onchange='autoReload()'",
    %params
  });

  return $result if $attr->{RETURN_SELECT};

  if (!$active_service && $service_list->[0] && !$FORM{search_form} && ! $attr->{SKIP_DEF_SERVICE}) {
    $FORM{SERVICE_ID} = $service_list->[0]->{id};
  }

  $result = $html->tpl_show(templates('form_row'), {
    ID    => 'SERVICE_ID',
    NAME  => $lang{SERVICE},
    VALUE => $result
  }, { OUTPUT2RETURN => 1 }) if ($attr->{FORM_ROW});

  return $result;
}

#**********************************************************
=head2 tv_load_service($service_name, $attr) - Load service module

  Argumnets:
    $service_name  - service modules name
    $attr
       SERVICE_ID
       SOFT_EXCEPTION
       RETURN_ERROR

  Returns:
    Module object

=cut
#**********************************************************
sub tv_load_service {
  my ($service_name, $attr) = @_;
  my $api_object;

  my $Iptv_service = Iptv->new($Iptv->{db}, $Iptv->{admin}, $Iptv->{conf});
  if ($attr->{SERVICE_ID}) {
    $Iptv_service->services_info($attr->{SERVICE_ID});
    $service_name = $Iptv_service->{MODULE} || q{};
  }

  if (!$service_name) {
    return $api_object;
  }

  return if $service_name !~ /^[\w.]+$/;
  $service_name = 'Iptv::' . $service_name;

  eval " require $service_name; ";
  if (!$@) {
    $service_name->import();

    if ($service_name->can('new')) {
      $api_object = $service_name->new($Iptv->{db}, $Iptv->{admin}, $Iptv->{conf}, {
        %$Iptv_service,
        HTML => $html,
        LANG => \%lang
      });
    }
    else {
      if ($attr->{RETURN_ERROR}) {
        return $api_object, {
          errno  => 9901,
          errstr => "Can't load '$service_name'. Purchase this module https://billing.axiostv.ru",
        };
      }
      else {
        $html->message('err', $lang{ERROR}, "Can't load '$service_name'. Purchase this module https://billing.axiostv.ru");
        return $api_object;
      }
    }

    if ($api_object && $api_object->{SERVICE_NAME}) {
      if ($api_object->{SERVICE_NAME} eq 'Olltv') {
        require Iptv::Olltv_web;
      }
      elsif ($api_object->{SERVICE_NAME} eq 'Stalker') {
        require Iptv::Stalker_web;
      }
    }
  }
  else {
    if ($attr->{RETURN_ERROR}) {
      return $api_object, {
        errno  => 9902,
        errstr => "Can't load '$service_name'. Purchase this module https://billing.axiostv.ru",
      };
    }
    else {
      print $@ if ($FORM{DEBUG});
      $html->message('err', $lang{ERROR}, "Can't load '$service_name'. Purchase this module https://billing.axiostv.ru");
      if (!$attr->{SOFT_EXCEPTION}) {
        die "Can't load '$service_name'. Purchase this module https://billing.axiostv.ru";
      }
    }
  }

  return $api_object;
}

#**********************************************************
=head2 _service_portal_filter(url) -

=cut
#**********************************************************
sub _service_portal_filter {
  my ($attr) = @_;

  if ($attr !~ /^http/) {
    $attr = "http://$attr";
  }

  return $html->button("$lang{GO}", '', { GLOBAL_URL => "$attr", class => 'btn input-group-button' });
}

#**********************************************************
=head2 _service_extra_params -

=cut
#**********************************************************
sub _service_extra_params {

  my %other_attr = ();
  $other_attr{BTN_ACTION} = "add";
  $other_attr{BTN_LNG} = "$lang{ADD}";
  $other_attr{PARAMS_ACTION} = "$lang{ADD} $lang{PARAMS}";

  use Users;
  my $Users = Users->new($db, $admin, \%conf);
  my $groups_list = $Users->groups_list({
    COLS_NAME       => 1,
    DISABLE_PAYSYS  => 0,
    GID             => '_SHOW',
    NAME            => '_SHOW',
    DESCR           => '_SHOW',
    ALLOW_CREDIT    => '_SHOW',
    DISABLE_PAYSYS  => '_SHOW',
    DISABLE_CHG_TP  => '_SHOW',
    USERS_COUNT     => '_SHOW',
  });

  require Tariffs;
  Tariffs->import();
  my $Tariffs = Tariffs->new($db, \%conf, $admin);
  my $tariffs = $Tariffs->list({
    MODULE     => 'Iptv',
    SERVICE_ID => $FORM{service_id} || $FORM{SERVICE_ID},
    COLS_NAME  => 1,
  });

  if ($FORM{add}) {
    $Iptv->extra_params_add({
      %FORM,
      IP_MAC => $FORM{IP},
    });
  }
  elsif ($FORM{change}) {
    my $chg_params = $Iptv->extra_params_list({
      ID         => $FORM{change},
      SERVICE_ID => '_SHOW',
      GROUP_ID   => '_SHOW',
      TP_ID      => '_SHOW',
      SMS_TEXT   => '_SHOW',
      SEND_SMS   => '_SHOW',
      IP_MAC     => '_SHOW',
      BALANCE    => '_SHOW',
      MAX_DEVICE => '_SHOW',
      PIN        => '_SHOW',
    });

    $other_attr{IP} = $chg_params->[0]{IP_MAC};
    $other_attr{TP_ID} = $chg_params->[0]{TP_ID};
    $other_attr{GROUP_ID} = $chg_params->[0]{GROUP_ID};
    $other_attr{SMS_TEXT} = $chg_params->[0]{SMS_TEXT};
    $other_attr{BALANCE} = $chg_params->[0]{BALANCE};
    $other_attr{SERVICE_ID} = $chg_params->[0]{SERVICE_ID};
    $other_attr{MAX_DEVICE} = $chg_params->[0]{MAX_DEVICE};
    $other_attr{PIN} = $chg_params->[0]{PIN};
    $other_attr{CHG} = $chg_params->[0]{ID};
    $other_attr{BTN_ACTION} = "chg";
    $other_attr{BTN_LNG} = "$lang{CHANGE}";
    $other_attr{PARAMS_ACTION} = "$lang{CHANGE} $lang{PARAMS}";
    if ($chg_params->[0]{SEND_SMS} eq '1'){
      $other_attr{SEND_SMS} = "1"
    }
  }
  elsif ($FORM{chg}) {
    $Iptv->extra_params_change({
      %FORM,
      ID     => $FORM{chg_param},
      IP_MAC => $FORM{IP},
    });
  }
  elsif ($FORM{delete}) {
    $Iptv->extra_params_del($FORM{delete});
  }

  my $select_group = $html->form_select('GROUP_ID', {
    SELECTED    => $other_attr{GROUP_ID} || 0,
    SEL_LIST    => $groups_list,
    SEL_KEY     => 'gid',
    SEL_VALUE   => 'name',
    NO_ID       => 1,
    SEL_OPTIONS => { '' => '--' },
  });

  my $select_tp = $html->form_select('TP_ID', {
    SELECTED    => $other_attr{TP_ID} || 0,
    SEL_LIST    => $tariffs,
    SEL_KEY     => 'tp_id',
    SEL_VALUE   => 'name',
    NO_ID       => 1,
    SEL_OPTIONS => { '' => '--' },
  });

  $html->tpl_show( _include( 'iptv_extra_params_add', 'Iptv' ), {
    GROUP_LIST => $select_group,
    TP_LIST    => $select_tp,
    SERVICE_ID => $FORM{service_id} || $FORM{SERVICE_ID} || $other_attr{SERVICE_ID},
    %other_attr,
  });

  my $extra_params = $Iptv->extra_params_list({
    SERVICE_ID => $FORM{service_id} || $FORM{SERVICE_ID},
    SMS_TEXT   => '_SHOW',
    SEND_SMS   => '_SHOW',
    IP_MAC     => '_SHOW',
    BALANCE    => '_SHOW',
    ID         => '_SHOW',
    MAX_DEVICE => '_SHOW',
    PIN        => '_SHOW',
  });

  my $table = $html->table(
    {
      width      => '100%',
      title      => [ "ID", "IP", "$lang{GROUP}", "$lang{MAX_DEVICES}", "$lang{DEPOSIT}", "$lang{TARIF_PLAN}", "$lang{SEND} SMS", "SMS $lang{TEXT}" , "PIN"],
      caption    => $lang{PARAMS},
      ID         => 'IPTV_PARAMS',
      DATA_TABLE => 1,
    }
  );

  my $change_buttons = '';
  my $delete_buttons = '';
  foreach my $element (@$extra_params) {
    my $enable = $element->{SEND_SMS} eq '1' ? "$lang{ENABLE}" : "$lang{DISABLE}";
    my $service_id = $FORM{service_id} || $FORM{SERVICE_ID} || '';
    $change_buttons = $html->button($lang{CHANGE}, "index=$index&change=$element->{ID}&extra_params=1&SERVICE_ID=$service_id", { class => 'change' });
    $delete_buttons = $html->button($lang{REMOVE}, "index=$index&delete=$element->{ID}&extra_params=1&SERVICE_ID=$service_id", { class => 'del' });
    $table->addrow($element->{ID}, $element->{IP_MAC} || "", $element->{GROUP_NAME} || "", $element->{MAX_DEVICE} || "", $element->{BALANCE} || "",
      $element->{TP_NAME} || "", $enable, $element->{SMS_TEXT} || "", $element->{PIN}, $change_buttons, $delete_buttons);
  }
  print $table->show();

  return 1;
}

#**********************************************************
=head2 get_next_abon_date($attr)

  Arguments:
    $attr
      UID       -
      PERIOD    -
      DATE      -
      SERVICE   -
        EXPIRE
        MONTH_ABON
        ABON_DISTRIBUTION
        STATUS


  Results:
    $Service_mng->{ABON_DATE}


=cut
#**********************************************************
sub get_next_abon_date {
  my $self = ();
  my ($attr) = @_;

  my $start_period_day = $attr->{START_PERIOD_DAY} || $conf{START_PERIOD_DAY} || 1;
  my $Service = $attr->{SERVICE};
  my $service_activate = $Service->{ACTIVATE} || $attr->{ACTIVATE} || '0000-00-00';
  my $service_expire = $Service->{EXPIRE} || '0000-00-00';
  my $month_abon = $attr->{MONTH_ABON} || $Service->{MONTH_ABON} || 0;
  my $tp_age = $Service->{TP_INFO}->{AGE} || 0;
  my $service_status = $Service->{STATUS} || 0;
  my $abon_distribution = $Service->{ABON_DISTRIBUTION} || 0;
  my $fixed_fees_day = $Service->{FIXED_FEES_DAY} || $attr->{FIXED_FEES_DAY} || 0;

  $DATE = $attr->{DATE} if ($attr->{DATE});

  my ($Y, $M, $D) = split(/-/, $DATE, 3);

  $self->{message} = q{};
  $self->{ABON_DATE} = $DATE;

  if ($service_status == 5) {
    $self->{message} = "STATUS_5";
    return;
  }

  if ($service_activate ne '0000-00-00' && $service_expire eq '0000-00-00') {
    ($Y, $M, $D) = split(/-/, $service_activate, 3);
  }

  # Renew expired accounts
  if ($service_expire ne '0000-00-00' && $tp_age > 0) {
    # Renew expire tarif
    if (date_diff($service_expire, $DATE) > 1) {
      my ($NEXT_EXPIRE_Y, $NEXT_EXPIRE_M, $NEXT_EXPIRE_D) = split(/-/, POSIX::strftime("%Y-%m-%d",
        localtime((POSIX::mktime(0, 0, 0, $D, ($M - 1), ($Y - 1900), 0, 0, 0) + $tp_age * 86400))));

      $self->{NEW_EXPIRE} = "$NEXT_EXPIRE_Y-$NEXT_EXPIRE_M-$NEXT_EXPIRE_D";
      $self->{message} = "RENEW EXPIRE";
      return;
    }
    else {
      $self->{ABON_DATE} = $service_expire;
    }
  }
  #Get next abon day
  elsif (!$conf{IPTV_USER_CHG_TP_NEXT_MONTH} && ($month_abon == 0 || $abon_distribution)) {
    ($Y, $M, $D) = split(/-/, POSIX::strftime("%Y-%m-%d", localtime((POSIX::mktime(0, 0, 0, $D, ($M - 1), ($Y - 1900), 0, 0, 0) + 86400))));

    $self->{ABON_DATE} = sprintf("%d-%02d-%02d", $Y, $M, $D);
    $self->{message} = 'MONTH_FEE_0';
  }
  # next month abon period
  else {
    if ($service_activate ne '0000-00-00') {
      if ($fixed_fees_day) {
        $M++;

        if ($M == 13) {
          $M = 1;
          $Y++;
        }

        $self->{ABON_DATE} = sprintf("%d-%02d-%02d", $Y, $M, $D);
        $self->{message} = 'FIXED_DAY';
      }
      else {
        $self->{ABON_DATE} = POSIX::strftime("%Y-%m-%d", localtime((POSIX::mktime(0, 0, 0, $D, ($M - 1), ($Y - 1900),
          0, 0, 0) + 31 * 86400 + (($start_period_day > 1) ? $start_period_day * 86400 : 0))));
        $self->{message} = 'NEXT_PERIOD_ABON';
      }

    }
    else {
      if ($start_period_day > $D) {
        $D = $start_period_day;
      }
      else {
        $M++;
        $D = '01';
      }

      if ($M == 13) {
        $M = 1;
        $Y++;
      }

      $self->{ABON_DATE} = sprintf("%d-%02d-%02d", $Y, $M, $D);
      $self->{message} = 'NEXT_MONTH_ABON';
    }
  }

  return $self->{ABON_DATE} || undef;
}

1;
