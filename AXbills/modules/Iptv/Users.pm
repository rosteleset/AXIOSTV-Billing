=head NAME


=cut

use strict;
use warnings FATAL => 'all';
use AXbills::Base qw(in_array cmd);
use Shedule;
require AXbills::Misc;
require Control::Service_control;
require Control::Services;


our (
  %FORM,
  %lang,
  $db,
  %conf,
  $admin,
  %permissions,
  @MONTHES_LIT,
  $Tv_service,
  $user,
  @MODULES,
  $DATE,
  $TIME,
  $index,
  %LIST_PARAMS,
);

our AXbills::HTML $html;
our Iptv $Iptv;
our Users $users;

my $Tariffs = Tariffs->new($db, \%conf, $admin);
my $Shedule = Shedule->new($db, $admin, \%conf);
my $Service_control = Control::Service_control->new($db, $admin, \%conf, { HTML => $html, LANG => \%lang });
#my $Iptv = Iptv->new( $db, $admin, \%conf );

#**********************************************************
=head2 iptv_user($attr) - Users info

=cut
#**********************************************************
sub iptv_user {
  my ($attr) = @_;

  $Iptv->{UID} = $FORM{UID};
  $FORM{CID} = $FORM{CID2} if ($FORM{CID2});
  $Iptv->{db}{db}->{AutoCommit} = 0;
  $Iptv->{db}->{TRANSACTION} = 1;
  my $subscribe_count = 0;
  my $additional_infos = '';

  if ($FORM{REGISTRATION_INFO}) {
    # Info
    load_module('Docs', $html);
    $users = Users->new($db, $admin, \%conf);
    $Iptv = $Iptv->user_info($Iptv->{ID});
    my $pi = $users->pi({ UID => $Iptv->{UID} });
    $user = $users->info($Iptv->{UID}, { SHOW_PASSWORD => $permissions{0}{3} });

    ($Iptv->{Y}, $Iptv->{M}, $Iptv->{D}) = split(/-/, (($pi->{CONTRACT_DATE}) ? $pi->{CONTRACT_DATE} : $DATE), 3);
    $pi->{CONTRACT_DATE_LIT} = "$Iptv->{D} " . $MONTHES_LIT[ int($Iptv->{M}) - 1 ] . " $Iptv->{Y} $lang{YEAR}";
    $Iptv->{MONTH_LIT} = $MONTHES_LIT[ int($Iptv->{M}) - 1 ];

    if ($Iptv->{Y} =~ /(\d{2})$/) {
      $Iptv->{YY} = $1;
    }

    if (!$FORM{pdf}) {
      if (in_array('Mail', \@MODULES)) {
        load_module('Mail', $html);
        my $Mail = Mail->new($db, $admin, \%conf);
        my $list = $Mail->mbox_list({ UID => $Iptv->{UID} });
        foreach my $line (@{$list}) {
          $Mail->{EMAIL_ADDR} = $line->[0] . '@' . $line->[1];
          $user->{EMAIL_INFO} .= $html->tpl_show(_include('mail_user_info', 'Mail'), $Mail, { OUTPUT2RETURN => 1 });
        }
      }
    }
    print $html->header();
    $Iptv->{PASSWORD} = $user->{PASSWORD} if (!$Iptv->{PASSWORD});
    return $html->tpl_show(
      _include('iptv_user_memo', 'Iptv', { pdf => $FORM{pdf} }),
      {
        %{$user},
        %{$pi},
        DATE => $DATE,
        TIME => $TIME,
        %{$Iptv},
      }
    );
  }
  elsif ($FORM{send_message} && !$FORM{send}) {
    $user->{IPTV_MODEMS} = $html->tpl_show(_include('iptv_send_message', 'Iptv'), { %{$attr}, %{$user} });
    return 0;
  }
  elsif ($FORM{new}) {

  }
  elsif ($FORM{import}) {

    _iptv_users_import();
    return 1;
  }
  elsif ($FORM{add}) {
    if (!iptv_user_add({ %FORM, %{($attr) ? $attr : {}} })) {
      delete $Iptv->{ID};
      delete $Iptv->{UID};
      $FORM{add_form} = 1;
    }
  }
  elsif ($FORM{change}) {
    iptv_user_change({ %FORM, USER_INFO => $attr->{USER_INFO} || {} });
  }
  elsif ($FORM{del} && $FORM{COMMENTS}) {
    $Iptv->user_info($FORM{del});
    if (!$Iptv->{errno}) {
      $Iptv->user_del({ ID => $FORM{del} });
      if (!$Iptv->{errno}) {
        $Iptv->{ID} = $FORM{del};
        $html->message('info', $lang{INFO}, "$lang{DELETED} [ $Iptv->{ID} ]");
        delete $Iptv->{ID};
      }
    }
  }
  else {
    my $list = $Iptv->user_list({ UID => $FORM{UID}, COLS_NAME => 1 });
    $subscribe_count = $Iptv->{TOTAL};
    if ($Iptv->{TOTAL} == 1) {
      $FORM{chg} = $list->[0]->{id};
    }
    elsif ($Iptv->{TOTAL} == 0) {
      $FORM{add_form} = 1;
    }
  }

  $Iptv->user_info($FORM{chg}) if ($FORM{chg});

  $Tv_service = iptv_user_services(\%FORM);

  if ($FORM{additional_functions}) {
    iptv_additional_functions();
    return 1;
  }
  elsif ($FORM{new_device}) {
    iptv_new_devices();
    return 1;
  }
  elsif ($FORM{activation_code}) {
    iptv_activation_code();
    return 1;
  }
  elsif ($FORM{watch_now}) {
    iptv_watch_now();
    return 1;
  }
  elsif ($attr->{REGISTRATION} && $FORM{add}) {
    return 1;
  }

  $Iptv->{SUBSCRIBE_FORM} = tv_services_sel({ %$Iptv, FORM_ROW => 1, UNKNOWN => 1 });

  if (!$Iptv->{ID}) {
    if ($attr->{ACTION}) {
      $user->{ACTION} = $attr->{ACTION};
      $user->{LNG_ACTION} = $attr->{LNG_ACTION};
    }
    else {
      $user->{ACTION} = 'add';
      $user->{LNG_ACTION} = $lang{ACTIVATE};
    }

    $Iptv->{TP_ADD} = sel_tp({
      SELECT      => 'TP_ID',
      USER_INFO   => $users,
      MODULE      => 'Iptv',
      TP_ID       => $Iptv->{TP_ID},
      SERVICE_ID  => $Iptv->{SERVICE_ID},
      STATUS      => '0'
    });

    $Iptv->{TP_DISPLAY_NONE} = "style='display:none'";
  }
  elsif ($Iptv->{UID}) {
    $Iptv->{REGISTRATION_INFO} = $html->button($lang{MEMO},
      "qindex=$index&UID=$Iptv->{UID}&ID=$Iptv->{ID}&REGISTRATION_INFO=1",
      { BUTTON => 1, ex_params => 'target=_new' });

    if ($conf{DOCS_PDF_PRINT}) {
      $Iptv->{REGISTRATION_INFO_PDF} = $html->button("$lang{MEMO} (PDF)",
        "qindex=$index&UID=$Iptv->{UID}&ID=$Iptv->{ID}&REGISTRATION_INFO=1&pdf=1",
        { ex_params => 'target=_new', BUTTON => 1 });
    }

    iptv_user_channels_list({ ID => $FORM{ID}, TP_ID => $Iptv->{TP_ID} });

    $user->{TP_IDS} = $Iptv->{TP_ID};
    if ($attr->{ACTION}) {
      $user->{ACTION} = $attr->{ACTION};
      $user->{LNG_ACTION} = $attr->{LNG_ACTION};
    }
    else {
      $user->{ACTION} = 'change';
      $user->{LNG_ACTION} = $lang{CHANGE};
    }

    $FORM{chg} = $Iptv->{ID} if (!$FORM{chg});
    $user->{CHANGE_TP_BUTTON} = $html->button($lang{CHANGE},
      'UID=' . $Iptv->{UID} . '&index=' . get_function_index('iptv_chg_tp') . '&ID=' . $Iptv->{ID}
        . (($Iptv->{SERVICE_ID}) ? "&SERVICE_ID=$Iptv->{SERVICE_ID}" : q{}),
      { class => 'change' });

    if ($Tv_service && $Tv_service->{SEND_MESSAGE}) {
      $user->{SEND_MESSAGE} = $html->button("$lang{SEND} $lang{MESSAGE}",
        "index=$index&ID=$Iptv->{ID}&UID=" . $Iptv->{UID} . "&send_message=1"
          . (($Iptv->{SERVICE_ID}) ? "&SERVICE_ID=$Iptv->{SERVICE_ID}" : q{}),
        { BUTTON => 1 });
    }

    my $warning_info = $Service_control->service_warning({
      UID         => $Iptv->{UID},
      ID          => $Iptv->{ID},
      MODULE      => 'Iptv',
      DATE        => $DATE
    });

    if (defined $warning_info->{WARNING}) {
      $Iptv->{NEXT_FEES_WARNING} = $warning_info->{WARNING};
      $Iptv->{NEXT_FEES_MESSAGE_TYPE} = $warning_info->{MESSAGE_TYPE};
    }

    $Iptv->{NEXT_FEES_WARNING} = $html->message($Iptv->{NEXT_FEES_MESSAGE_TYPE}, $Iptv->{TP_NAME},
      $Iptv->{NEXT_FEES_WARNING}, { OUTPUT2RETURN => 1 }) if ($Iptv->{NEXT_FEES_WARNING});

    _iptv_user_shedules($users);
  }

  $Iptv->{STATUS_SEL} = sel_status({ STATUS => $Iptv->{STATUS} });
  $Iptv->{DESCRIBE_AID} = ($Iptv->{DESCRIBE_AID}) ? ('['.$Iptv->{DESCRIBE_AID}.']') : '';
  my $service_info1 = q{};
  my $service_info2 = q{};
  my $service_info_subscribes = q{};

  if ($FORM{chg} || $FORM{USER_CHANNELS} || $FORM{add_form} || $attr->{REGISTRATION}) {
    iptv_users_screens($Iptv);
    if (!$FORM{screen}) {
      if ($Tv_service->{SERVICE_USER_FORM}) {
        my $fn = $Tv_service->{SERVICE_USER_FORM};
        &{\&$fn}({ %{$attr}, %{$user}, %{$Iptv}, SHOW_USER_FORM => 1 });
      }
      elsif ($Iptv->{SUBSCRIBE_FORM_FULL}) {
        $service_info_subscribes = $Iptv->{SUBSCRIBE_FORM_FULL};
      }
      else {
        $service_info1 = $html->tpl_show(_include('iptv_user', 'Iptv'), {
          %{($attr) ? $attr : {}},
          %{$Iptv},
          %{($user) ? $user : {}} },
          { ID => 'iptv_user', OUTPUT2RETURN => ($FORM{json}) ? undef : 1 });
      }

      $service_info_subscribes .= iptv_user_channels({ SERVICE_INFO => $Iptv }) if $Iptv->{ID};
    }

    if (($Iptv->{UID} && $Iptv->{SERVICE_ID} && $Iptv->{SERVICE_MODULE} && $Iptv->{TP_ID})
      || ($Iptv->{SERVICE_MODULE} && ($Iptv->{SERVICE_MODULE} eq "SmartUp" || $Iptv->{SERVICE_MODULE} eq "Olltv"))) {
      my $chg_dev = $FORM{chg} || "";
      my $module_dev = $FORM{MODULE} || "";
      my $service_dev = $Iptv->{SERVICE_ID} || "";
      if ($Tv_service->can('customer_add_device')) {
        print $html->button($lang{ADD_DEVICE_BY_UNIQ},
          "get_index=iptv_user&new_device=1&header=2&UID=$Iptv->{UID}&SERVICE_ID=$service_dev&MODULE=$module_dev&chg_d=$chg_dev",
          {
            class         => 'btn-xs',
            LOAD_TO_MODAL => 1,
            BUTTON        => 1,
          });
      }
      if ($Tv_service->can('get_code')) {
        print $html->button($lang{ACTIVATION_CODE},
          "get_index=iptv_user&activation_code=1&header=2&UID=$Iptv->{UID}&SERVICE_ID=$service_dev&MODULE=$module_dev&activ_code=$chg_dev",
          {
            class         => 'btn-xs',
            LOAD_TO_MODAL => 1,
            BUTTON        => 1,
          });
      }
      if ($Tv_service->can('get_url')) {
        print $html->button($lang{WATCH_NOW},
          "get_index=iptv_user&watch_now=1&header=2&UID=$Iptv->{UID}&SERVICE_ID=$service_dev&MODULE=$module_dev&watch_now=$chg_dev",
          {
            class  => 'btn-xs',
            BUTTON => 1,
            target => '_new',
          });
      }

      if ($Tv_service && $Tv_service->can('additional_info')) {
        my $additional_tables = iptv_additional_info();
        map $additional_infos .= $_->show(), @{$additional_tables} if ($additional_tables && ref $additional_tables eq 'ARRAY');
      }
    }

    return 1 if ($attr->{ACCOUNT_INFO});
    delete $FORM{chg};
  }

  $service_info_subscribes .= iptv_users_list({ USER_ACCOUNT => 1 });
  $service_info_subscribes .= $additional_infos if ($additional_infos);

  if ($attr->{PROFILE_MODE}) {
    return '', ($service_info1 || q{}), $service_info2, ($Tv_service->{SERVICE_RESULT_FORM} || q{}) . $service_info_subscribes;
  }

  print(($Tv_service->{SERVICE_RESULT_FORM} || q{}) . ($service_info1 || q{}) . $service_info2 . $service_info_subscribes);

  return 1;
}


#**********************************************************
=head2 iptv_new_devices($attr) - New devices

=cut
#**********************************************************
sub iptv_new_devices {

  if ($Tv_service->can('customer_add_device')) {
    $Tv_service->customer_add_device({ %FORM, %LIST_PARAMS, INDEX => $index, DEVICE => 1, });
  }
  else {
    print "New Device";
  }

  return 1;
}

#**********************************************************
=head2 iptv_activation_code($attr) - Activation code

=cut
#**********************************************************
sub iptv_activation_code {

  if ($Tv_service->can('get_code')) {
    $users->info($FORM{UID}, { SHOW_PASSWORD => 1 });
    $Tv_service->get_code({ %{$users}, %FORM, %LIST_PARAMS, INDEX => $index, DEVICE => 1, });
  }

  return 1;
}

#**********************************************************
=head2 iptv_watch_now($attr) - Activation code

=cut
#**********************************************************
sub iptv_watch_now {

  if ($Tv_service->can('get_url')) {
    my $result = $Tv_service->get_url({ %FORM, %LIST_PARAMS, INDEX => $index, DEVICE => 1, });
    if ($result->{result}{web_url}) {
      $html->redirect($result->{result}{web_url});
      return 1;
    }
    print "Error";
  }

  return 1;
}

#**********************************************************
=head2 iptv_additional_info($attr)

=cut
#**********************************************************
sub iptv_additional_info {

  my $uid = $FORM{UID} || q{};
  if ($uid && $FORM{chg}) {
    $Iptv->user_info($FORM{chg});
    $users->info($uid, { SHOW_PASSWORD => 1 });
    my $url = "index=$index&chg=$FORM{chg}&MODULE=Iptv&UID=$uid";
    my $result = $Tv_service->additional_info({ %{$users}, %FORM, %LIST_PARAMS, %{$Iptv}, URL => $url });
    if (ref $result eq "HASH" && $result->{TABLES} && ref $result->{TABLES} eq 'ARRAY') {
      return $result->{TABLES};
    }
  }

  return [];
}

#**********************************************************
=head2 iptv_user_add($attr) - Users add

  Arguments:
    REGISTRATION
    SERVICE_ID
    SERVICE_ADD => 1
    TP_ID
    USER_INFO
    skip_step

  Results:
    TRUE or FALSE

=cut
#**********************************************************
sub iptv_user_add {
  my ($attr) = @_;

  if ($attr->{REGISTRATION}) {
    if (!$attr->{TP_ID}) {
      return 0;
    }
    elsif ($attr->{skip_step}) {
      return 1;
    }
  }

  if (!$users && $attr->{USER_INFO}) {
    $users = $attr->{USER_INFO};
  }

  if (!$attr->{SERVICE_ID}) {
    $Tariffs->{db} = $Iptv->{db};
    my $tp_list = $Tariffs->list({
      INNER_TP_ID  => $attr->{TP_ID},
      SERVICE_ID   => '_SHOW',
      NEW_MODEL_TP => 1,
      COLS_NAME    => 1
    });

    if ($Tariffs->{TOTAL}) {
      $FORM{SERVICE_ID} = $tp_list->[0]->{service_id};
      $attr->{SERVICE_ID} = $tp_list->[0]->{service_id};
    }
  }

  my $service_info = $Iptv->services_info($attr->{SERVICE_ID});

  $Iptv->user_list({
    SERVICE_ID => $attr->{SERVICE_ID},
    UID        => $attr->{UID},
    COLS_NAME  => 1,
    PAGE_ROWS  => 99999,
  });
  if ($service_info->{SUBSCRIBE_COUNT} && $service_info->{SUBSCRIBE_COUNT} == $Iptv->{TOTAL}) {
    $html->message("err", "$lang{ERROR}", "$lang{EXCEEDED_THE_NUMBER_OF_SUBSCRIPTIONS}: $service_info->{SUBSCRIBE_COUNT}");
    return 0;
  }

  if ($conf{IPTV_USER_UNIQUE_TP}) {
    $Iptv->user_list({
      SERVICE_ID => $attr->{SERVICE_ID},
      UID        => $attr->{UID},
      TP_ID      => $attr->{TP_ID},
      COLS_NAME  => 1,
      #PAGE_ROWS     => 99999,
    });

    if ($Iptv->{TOTAL}) {
      $html->message("err", $lang{ERROR}, $lang{THIS_TARIFF_PLAN_IS_ALREADY_CONNECTED}, { ID => 830 });
      return 0;
    }
  }

  $Iptv->user_add($attr);
  return 0 if $Iptv->{errno};

  $Iptv->{ACCOUNT_ACTIVATE} = $attr->{USER_INFO}->{ACTIVATE};
  $Iptv->{ID} = $Iptv->{INSERT_ID};
  $Iptv->{MANDATORY_CHANNELS} = iptv_mandatory_channels($attr->{TP_ID});

  if (!$FORM{STATUS}) {
    $Iptv->user_info($Iptv->{ID});

    ::service_get_month_fee($Iptv, {
      SERVICE_NAME               => $lang{TV},
      DO_NOT_USE_GLOBAL_USER_PLS => 1,
      MODULE                     => 'Iptv'
    });

    if ($attr->{SERVICE_ADD}) {
      $FORM{add} = 1;
      $Tv_service = iptv_user_services($attr);
    }
  }

  return $Iptv->{ID};

}

#**********************************************************
=head2 iptv_user_change($attr) - User change

=cut
#**********************************************************
sub iptv_user_change {
  my ($attr) = @_;

  $Iptv->user_change($attr);

  if ($Iptv->{OLD_STATUS} && !$Iptv->{STATUS}) {
    iptv_user_activate($Iptv, {
      USER       => $users,
      REACTIVATE => (!$Iptv->{STATUS}) ? 1 : 0,
    });
  }
  else {
    _external('', { EXTERNAL_CMD => 'Iptv', %{$Iptv}, QUITE => 1 });
  }

  if (!$Iptv->{errno}) {
    $Iptv->{ACCOUNT_ACTIVATE} = $attr->{USER_INFO}->{ACTIVATE};

    if ($attr->{change_now}) {
      $Iptv->user_channels({ ID => $attr->{ID} });
    }

    $Iptv->{MESSAGE} = "$lang{CHANGED}: $attr->{ID}";
  }
  $Iptv->{MANDATORY_CHANNELS} = iptv_mandatory_channels($attr->{TP_ID} || $Iptv->{TP_ID});
}

#**********************************************************
=head2 iptv_user_services($form_) - Service add

  Arguments:
    $form_ - INPUT FORM arguments
      SERVICE_ID
      SERIAL_NUMBER
      MAC
      CID
      SUBSCRIBE_ID

  Results:
    $Tv_service [obj]

=cut
#**********************************************************
sub iptv_user_services {
  my ($form_) = @_;

  $Iptv->{SERVICE_ID} ||= $form_->{SERVICE_ID};
  $Tv_service = undef;
  my DBI $db_ = $Iptv->{db}{db};

  if ($Iptv->{SERVICE_ID}) {
    $Tv_service = tv_load_service($Iptv->{SERVICE_MODULE}, { SERVICE_ID => $Iptv->{SERVICE_ID} });
  }
  else {
    delete($Iptv->{db}->{TRANSACTION});
    $db_->commit();
    $db_->{AutoCommit} = 1;
    return $Tv_service;
  }

  if (!::_error_show($Iptv) && ($Tv_service || $conf{IPTV_SKIP_CHECK_PLUGIN})) {
    my $action_result = iptv_account_action({
      %$form_,
      ID           => $Iptv->{ID},
      SUBSCRIBE_ID => $form_->{SUBSCRIBE_ID} || $Iptv->{SUBSCRIBE_ID},
      SCREEN_ID    => undef
    });

    if ($action_result) {
      ::_error_show($Iptv, {
        ID          => 835,
        MODULE_NAME => $Tv_service->{SERVICE_NAME}
      });

      $db_->rollback();
      delete $Iptv->{ID};
    }
    else {
      $html->message('info', $lang{INFO}, $Iptv->{MESSAGE}) if ($Iptv->{MESSAGE});
      if ($form_->{ARTICLE_ID} && in_array('Storage', \@MODULES)) {
        load_module('Storage', $html);
        storage_hardware({
          ADD_ONLY => 1,
          SERIAL   => $form_->{SERIAL_NUMBER},
          MAC      => $form_->{CID} || $form_->{MAC},
          add      => 1
        });
      }
    }

    if ($Iptv->{MANDATORY_CHANNELS} && ref $Iptv->{MANDATORY_CHANNELS} eq 'HASH' && !$FORM{change}) {
      my @channel_list = keys %{$Iptv->{MANDATORY_CHANNELS}};
      _iptv_channels_change_now({
        UID                => $Iptv->{UID},
        ID                 => $Iptv->{ID},
        MANDATORY_ARR      => \@channel_list,
        channels           => 1,
        MANDATORY_CHANNELS => 1
      });
      _iptv_get_fees_mandatory_channels($Iptv);
    }

    delete($Iptv->{db}->{TRANSACTION});
    $db_->commit();
    $db_->{AutoCommit} = 1;
  }
  else {
    delete($Iptv->{db}->{TRANSACTION});
    $db_->commit();
    $db_->{AutoCommit} = 1;
  }

  return $Tv_service;
}

#**********************************************************
=head2 iptv_mandatory_channels($tp_id) - Service add

  Arguments:
    $tp_id

  Results:
    $channels{num} => {
      ID
      FILTER_ID
      NAME
    }

=cut
#**********************************************************
sub iptv_mandatory_channels {
  my ($tp_id) = @_;

  my %tp_channels_list = ();
  $Tariffs->ti_list({ TP_ID => $tp_id, COLS_NAME => 1 });

  return \%tp_channels_list if ($Tariffs->{TOTAL} == 0);
  
  my $channels_list = $Iptv->channel_ti_list({
    INTERVAL_ID => $Tariffs->{list}->[0]->{id},
    MANDATORY   => 1,
    FILTER_ID   => '_SHOW',
    COLS_NAME   => 1
  });

  foreach my $line (@{$channels_list}) {
    $tp_channels_list{ $line->{channel_id} }{NUM} = $line->{channel_num};
    $tp_channels_list{ $line->{channel_id} }{NAME} = $line->{name};
    $tp_channels_list{ $line->{channel_id} }{FILTER_ID} = $line->{filter_id};
    $tp_channels_list{ $line->{channel_id} }{MONTH_PRICE} = $line->{month_price};
  }

  return \%tp_channels_list;
}

#**********************************************************
=head2 iptv_account_action($attr) - Control external services

  Arguments:
    $attr
      NEGDEPOSIT
      add
      change
      del
      channels
      PARENT_CONTROL
      USER_CHANNELS  - Chnage user channels
        IDS - Users channels ids
      SCREEN_ID
      SEND_MESSAGE
      ID
      UID
      TP_ID
      LOGIN
      CID
      STATUS
      SUBSCRIBE_ID
      SILENT       = Silent actions,
      USER_INFO

  Returns:

    True or False

=cut
#**********************************************************
sub iptv_account_action {
  my ($attr) = @_;

  my $result = 0;

  if ($Iptv->{SERVICE_ID} && ((!$Tv_service) || ($Tv_service->{SERVICE_NAME} && $Iptv->{SERVICE_MODULE} &&
    $Tv_service->{SERVICE_NAME} ne $Iptv->{SERVICE_MODULE}))) {
    $Tv_service = tv_load_service($Iptv->{SERVICE_MODULE}, { SERVICE_ID => $Iptv->{SERVICE_ID} });
    $attr->{SUBSCRIBE_COUNT} = $Tv_service->{SUBSCRIBE_COUNT} if ($Tv_service && $Tv_service->{SUBSCRIBE_COUNT});
  }

  $Iptv->{TP_ID} = $attr->{TP_ID} if ($attr->{TP_ID} && !$Iptv->{TP_ID});
  my $uid = $attr->{UID} || $Iptv->{UID};
  $users = $attr->{USER_INFO} if ($attr->{USER_INFO});

  my $disable_catv_port = 0;
  my $enable_catv_port  = 0;

  #Get chanels list
  $Iptv->{CHANNELS} = iptv_user_channels_list({
    UID          => $uid,
    TP_ID        => $attr->{TP_ID} || $Iptv->{TP_ID},
    RETURN_PORTS => $conf{IPTV_STALKER_API_HOST}
  }) if $FORM{UID};

  if ($attr->{NEGDEPOSIT}) {
    $disable_catv_port=1;
    if ($Tv_service && $Tv_service->can('user_negdeposit')) {
      $attr->{TP_ID} = $Iptv->{TP_ID} if $Iptv->{TP_ID};
      $Tv_service->user_negdeposit($attr);
      if ($Tv_service->{errno}) {
        print "$Tv_service->{SERVICE_NAME} Error: [$Tv_service->{errno}]  $Tv_service->{errstr} UID: $uid $attr->{ID}\n";
      }
    }
  }
  elsif ($attr->{add}) {
    if ($conf{IPTV_DVCRYPT_FILENAME}) {
      iptv_dv_crypt();
    }

    $enable_catv_port=1;
    _external('', { EXTERNAL_CMD => 'Iptv', %{$users}, %{$Iptv}, ACTION => 'up', QUITE => 1 });

    if ($Tv_service && $Tv_service->can('user_add')) {
      $users->info($uid, { SHOW_PASSWORD => 1 });
      $users->pi({ UID => $uid });
      $Iptv->user_info($attr->{ID});
      $Iptv->{LOGIN} = $users->{LOGIN};

      $Tv_service->user_add({
        %{$users},
        %{$Iptv},
        %{$attr},
        PASSWORD => $users->{PASSWORD},
        ID       => $Iptv->{ID},
        EMAIL    => $attr->{EMAIL} || $Iptv->{EMAIL} || $users->{EMAIL}
      });

      if (!$Tv_service->{errno}) {
        if ($Tv_service->{SUBSCRIBE_ID}) {
          $Iptv->user_change({
            ID           => $Iptv->{ID},
            SUBSCRIBE_ID => $Tv_service->{SUBSCRIBE_ID}
          });
        }

        $result = 0;
      }
      else {
        $Iptv->{errno} = $Tv_service->{errno};
        if ($Tv_service->{errno} == 1000) {
          $Iptv->{errstr} = $lang{WRONG_EMAIL};
        }
        elsif ($Tv_service->{errno} == 1001) {
          $Iptv->{errstr} = 'Create error';
        }
        elsif ($Tv_service->{errno} == 1002) {
          $Iptv->{errstr} = $lang{EXIST};
        }
        elsif ($Tv_service->{errno} == 1003) {
          $Iptv->{errstr} = "E-mail $lang{EXIST}\n$Iptv->{EMAIL}";
        }
        elsif ($Tv_service->{errno} == 1004) {
          $Iptv->{errstr} = "E-mail $lang{ERR_NOT_EXISTS}";
        }
        elsif ($Tv_service->{errno} == 1005) {
          $Iptv->{errstr} = "No password";
        }
        elsif ($Tv_service->{errno} == 1020) {
          $Iptv->{errstr} = "Incorrect response";
        }
        else {
          $Iptv->{errstr} = $Tv_service->{errstr};
        }
        $result = 1;
      }
    }

    if ($attr->{SUBSCRIBE_ID}) {
      $Iptv->subscribe_change({
        ID     => $FORM{SUBSCRIBE_ID},
        STATUS => 0
      });
      if ($conf{IPTV_SUBSCRIBE_CMD}) {
        $Iptv->subscribe_info($attr->{SUBSCRIBE_ID});
        $result = cmd($conf{IPTV_SUBSCRIBE_CMD}, {
          PARAMS => { %{$Iptv}, ACTION => 'SET' },
          ARGV   => 1,
          debug  => $conf{IPTV_CMD_DEBUG}
        });
      }
    }
  }
  elsif ($attr->{change}) {
    iptv_dv_crypt() if ($conf{IPTV_DVCRYPT_FILENAME});

    #if ($attr->{DISABLE}) {
    if ($attr->{STATUS}) {
      $disable_catv_port = 1;
    }

    if ($Tv_service && $Tv_service->can('user_change')) {
      $users->info($uid, { SHOW_PASSWORD => 1 });
      $users->pi({ UID => $uid });
      $Tv_service->user_change({
        %$users,
        %$Iptv,
        %FORM,
        %$attr
      });

      if ($Tv_service->{errno}) {
        $Iptv->{errno} = $Tv_service->{errno};
        $Iptv->{errstr} = $Tv_service->{errstr};
        $result = 1;
      }
      elsif ($Tv_service->{SUBSCRIBE_ID}) {
        $Iptv->user_change({
          ID           => $Iptv->{ID},
          SUBSCRIBE_ID => $Tv_service->{SUBSCRIBE_ID}
        });
      }
    }

    if ($FORM{SUBSCRIBE_ID}) {
      $Iptv->subscribe_change({
        ID     => $attr->{SUBSCRIBE_ID},
        STATUS => 0
      });

      $Iptv->subscribe_info($attr->{SUBSCRIBE_ID});
      cmd($conf{IPTV_SUBSCRIBE_CMD}, {
        PARAMS => { %{$Iptv}, ACTION => 'SET' },
        debug  => $conf{IPTV_CMD_DEBUG}
      }) if $conf{IPTV_SUBSCRIBE_CMD};
    }

    _external('', { EXTERNAL_CMD => 'Iptv', %{$users}, %{$Iptv}, ACTION => 'down', QUITE => 1 });
  }
  elsif ($attr->{channels}) {
    if ($Tv_service && ref $Tv_service ne 'HASH') {
      if ($Tv_service->{SERVICE_USER_CHANNELS_FORM}) {
        my $fn = $Tv_service->{SERVICE_USER_CHANNELS_FORM};
        &{\&$fn}($attr);
      }
      elsif ($Tv_service->can('channels_change')) {
        my @filters_list = ();
        my $channel_ti_list = $Iptv->channel_ti_list({
          ID        => join(';', @{$attr->{ADD_ID}}) || '-',
          FILTER_ID => '_SHOW',
          COLS_NAME => 1
        });

        foreach my $line (@$channel_ti_list) {
          next if !$line->{filter_id};
          push @filters_list, $line->{filter_id};
        }

        $Tv_service->channels_change({
          %{$users},
          %{$Iptv},
          %{$attr},
          FILTER_ID => join(',', @filters_list),
          ID        => $Iptv->{ID},
        });
      }

      if ($Tv_service->{errno}) {
        $Iptv->{errno} = $Tv_service->{errno};
        $Iptv->{errstr} = $Tv_service->{errstr};
        $result = 1;
      }
    }
    elsif ($conf{IPTV_DVCRYPT_FILENAME}) {
      iptv_dv_crypt();
    }
  }
  elsif ($attr->{PARENT_CONTROL}) {
    if ($Tv_service && $Tv_service->can('parent_control')) {
      $Tv_service->parent_control({ %{$users}, %{$Iptv}, %{$attr}, ID => $Iptv->{ID} });
    }
  }
  elsif ($attr->{SCREEN_ID}) {
    my %request = (
      %{$attr},
      CID => $attr->{CID},
    );

    if ($attr->{DEL}) {
      $Iptv->users_screens_info($Iptv->{ID}, { SCREEN_ID => $attr->{SCREEN_ID} });
      ::_error_show($Iptv);
      %request = (
        MAC             => $Iptv->{CID} || $attr->{CID},
        %{$attr},
        CID             => $Iptv->{CID} || $attr->{CID},
        ID              => $Iptv->{ID},
        SERIAL          => $Iptv->{SERIAL} || $attr->{SERIAL},
        TP_FILTER_ID    => $Iptv->{FILTER_ID},
        SUB_ID          => $Iptv->{FILTER_ID},
        del             => 1,
        TYPE            => $attr->{TYPE} || 'subs_break_contract',
        DEVICE_DEL_TYPE => $attr->{DEVICE_DEL_TYPE} || 'device_break_contract'
      );

    }
    else {
      $request{BUNDLE_TYPE} = $attr->{BUNDLE_TYPE} || ($attr->{CID} ? 'subs_free_device' : undef) || 'subs_no_device';
    }

    if ($attr->{chg} || $attr->{ID}) {
      $Iptv->user_info($attr->{chg} || $attr->{ID});
      $request{SUBSCRIBE_ID} = $Iptv->{SUBSCRIBE_ID} if $Iptv->{TOTAL} && $Iptv->{SUBSCRIBE_ID};
      $request{LOGIN} = $users->{LOGIN};

      $users->info($users->{UID}, { SHOW_PASSWORD => 1 });
      $request{PASSWORD} = $users->{PASSWORD};
      $request{DEPOSIT} = $users->{DEPOSIT};
    }

    if ($Tv_service && $Tv_service->can('user_screens')) {
      $Tv_service->user_screens(\%request);
      if (!$Tv_service->{errno}) {

        if ($Tv_service->{CID} || $Tv_service->{SERIAL}) {
          $Iptv->users_screens_add({
            SERVICE_ID => $Iptv->{ID},
            SCREEN_ID  => $Tv_service->{SCREEN_ID} || $Iptv->{SCREEN_ID},
            CID        => $Tv_service->{CID},
            SERIAL     => $Tv_service->{SERIAL} || '',
            COMMENT    => $Tv_service->{COMMENT} || ''
          });
        }

        $result = 0;
      }
      else {
        $result = 1;
      }
    }
    else {
      $result = 1;
    }

    ::_error_show($Tv_service, { ID => 833, MESSAGE => ($Tv_service->{DEVICE_ID} ? "ID: " . $Tv_service->{DEVICE_ID} : q{}) });
  }
  # elsif ($attr->{ACTIVATE}) {
    #iptv_account_action({ add => 1 });
  # }
  elsif ($attr->{chg}) {

    if ($attr->{add_service}) {
      my $return = iptv_account_action({
        %{$attr},
        chg => undef,
        ID  => $attr->{chg},
        add => 1
      });

      $html->message('info', $lang{ADDED}, $lang{ADDED}) if (!$attr->{SILENT} && !$return);

      return 0;
    }

    if ($Tv_service && $Tv_service->can('user_info')) {
      $users->pi({ UID => $uid });
      $Tv_service->user_info({ %$attr, %$users, %{$Iptv} });

      if ($Tv_service->{errno}) {
        my $message = '';
        if ($Tv_service->{errno} == 404) {
          if (!$user && !$user->{UID}) {
            $message = $html->br() . $html->button("$lang{ADD} $Tv_service->{SERVICE_NAME}",
              "index=$index&UID=$uid&chg=$attr->{chg}&add_service=1", { BUTTON => 1 });
            $Tv_service->{errstr} = "$Tv_service->{SERVICE_NAME} $lang{ERR_NOT_EXISTS}";
          }
        }

        ::_error_show($Tv_service, { ID => $Tv_service->{errno}, MESSAGE => $message });
      }
      elsif ($Tv_service->{RESULT} && $Tv_service->{RESULT}->{results} && ref $Tv_service->{RESULT}->{results} eq 'ARRAY') {
        ($Tv_service->{SERVICE_RESULT_FORM}) = result_former({
          TABLE           => {
            width      => '100%',
            HIDE_TABLE => 1,
            caption    => $Tv_service->{SERVICE_NAME} . ' (' . ($#{$Tv_service->{RESULT}->{results}} + 1) . ')',
            ID         => 'IPTV_EXTERNAL_LIST',
          },
          DATAHASH        => $Tv_service->{RESULT}->{results},
          SKIP_TOTAL_FORM => 1,
          TOTAL           => 1,
          OUTPUT2RETURN   => 1
        });
      }
    }

    if ($Tv_service && $Tv_service->can('additional_functions') && !$attr->{additional_functions}) {
      $Tv_service->additional_functions({ %FORM, %$attr, %$Iptv });
    }
  }
  elsif ($attr->{send_message}) {
    if ($Tv_service && $Tv_service->can('send_message')) {
      $Tv_service->send_message($attr);
      if ($Tv_service->{error}) {
        $Iptv->{errno} = $Tv_service->{errno};
        $Iptv->{errstr} = $Tv_service->{errstr};
        $result = 1;
      }
    }
  }
  elsif ($attr->{del}) {
    $disable_catv_port = 1;
    if ($Tv_service && $Tv_service->can('user_del')) {
      $users->pi({ UID => $uid });

      my $user_screens = $Iptv->users_screens_list({
        NUM              => '_SHOW',
        CID              => '_SHOW',
        SERIAL           => '_SHOW',
        USERS_SERVICE_ID => $attr->{del},
        COLS_NAME        => 1,
        COLS_UPPER       => 1,
        SHOW_ASSIGN      => 1
      });
      
      $Tv_service->user_del({ %{$users}, %$attr, %{$Iptv}, ID => $attr->{del}, USER_SCREENS => $user_screens });
      if ($Tv_service->{error} || $Tv_service->{errno}) {
        $Iptv->{errno} = $Tv_service->{errno};
        $Iptv->{errstr} = $Tv_service->{errstr};
        $result = 1;
      }
    }

    if ($attr->{SUBSCRIBE_ID}) {
      $Iptv->subscribe_change({
        ID     => $attr->{SUBSCRIBE_ID},
        STATUS => 6
      });
      $Iptv->subscribe_info($attr->{SUBSCRIBE_ID});
      cmd($conf{IPTV_SUBSCRIBE_CMD}, {
        PARAMS => { %{$Iptv}, ACTION => 'SET' },
        debug  => $conf{IPTV_CMD_DEBUG}
      }) if ($conf{IPTV_SUBSCRIBE_CMD});
    }

    _external('', { EXTERNAL_CMD => 'Iptv', %{($users) ? $users : {} }, %{$Iptv}, ACTION => 'down', QUITE => 1 });
  }
  elsif ($attr->{hangup}) {
    if ($Tv_service && $Tv_service->can('hangup')) {
      $Tv_service->hangup($attr);
      if ($Tv_service->{error}) {
        $Iptv->{errno} = $Tv_service->{errno};
        $Iptv->{errstr} = $Tv_service->{errstr};
        $result = 1;
      }
    }

    $html->message('info', $lang{INFO}, $lang{HANGUPED}) if (!$attr->{SILENT});
  }
  elsif ($attr->{USER_IMPORT}) {
    if ($Tv_service && $Tv_service->can('user_import')) {
      $Tv_service->user_import($attr);
      if ($Tv_service->{errno}) {
        $Iptv->{errno} = $Tv_service->{errno};
        $Iptv->{errstr} = $Tv_service->{errstr};
        $result = 1;
      }
    }
  }

  if ($conf{IPTV_CHANGE_ONU_CATV_PORT_STATUS} && in_array('Equipment', \@MODULES) && ($disable_catv_port || $enable_catv_port)) {
    use Equipment;
    our $Equipment = Equipment->new($db, $admin, \%conf);
    use Equipment::Pon_mng;
    equipment_tv_port({
      UID          => $uid,
      CATV_PORT_ID => 1, #XXX should disable all ports or only first?
      DISABLE_PORT => $disable_catv_port,
      ENABLE_PORT  => $enable_catv_port
    });
  }

  return $result;
}

#*******************************************************************
=head2 iptv_chg_tp($attr) - Change user tarif plan

  Arguments:
    $attr
      USER_INFO


=cut
#*******************************************************************
sub iptv_chg_tp {
  my ($attr) = @_;

  if (!$permissions{0}{10}) {
    $html->message('warn', $lang{WARNING}, $lang{ERR_ACCESS_DENY}, { ID => 843 });
    return 1;
  }

  if (defined($attr->{USER_INFO})) {
    $user = $attr->{USER_INFO};
    $Iptv = $Iptv->user_info($FORM{ID});
    if ($Iptv->{TOTAL} < 1) {
      $html->message('info', $lang{INFO}, $lang{NOT_ACTIVE});
      return 0;
    }
  }
  else {
    $html->message('err', $lang{ERROR}, $lang{USER_NOT_EXIST});
    return 0;
  }

  my $period = $FORM{period} || 0;

  if (_iptv_can_change_tp()) {
    if ($users->{ACTIVATE} ne '0000-00-00') {
      my ($Y, $M, $D) = split(/-/, $users->{ACTIVATE}, 3);
      $M--;
      $Iptv->{ABON_DATE} = POSIX::strftime('%Y-%m-%d', localtime((POSIX::mktime(0, 0, 0, $D, $M, ($Y - 1900), 0, 0,
        0) + 31 * 86400 + (($conf{START_PERIOD_DAY}) ? $conf{START_PERIOD_DAY} * 86400 : 0))));
    }
    else {
      my ($Y, $M, $D) = split(/-/, $DATE, 3);
      $M++;
      if ($M == 13) {
        $M = 1;
        $Y++;
      }
      $D = $conf{START_PERIOD_DAY} ? $conf{START_PERIOD_DAY} : '01';
      $Iptv->{ABON_DATE} = sprintf("%d-%02d-%02d", $Y, $M, $D);
    }
  }

  if ($FORM{set}) {
    if (!$permissions{0}{4}) {
      $html->message('err', $lang{ERROR}, $lang{ERR_ACCESS_DENY});
      return 0;
    }

    if ($period > 0) {
      my ($year, $month, $day) = $period == 1 ? split(/-/, $Iptv->{ABON_DATE}, 3) : split(/-/, $FORM{DATE}, 3);

      $Shedule->add({
        UID          => $user->{UID},
        TYPE         => 'tp',
        ACTION       => "$FORM{ID}:$FORM{TP_ID}",
        D            => $day,
        M            => $month,
        Y            => $year,
        COMMENTS     => "$lang{FROM}: $Iptv->{TP_ID}:"
          . (($Iptv->{TP_NAME}) ? "$Iptv->{TP_NAME}" : q{})
          . ((!$FORM{GET_ABON}) ? "\nGET_ABON=-1" : '') . ((!$FORM{RECALCULATE}) ? "\nRECALCULATE=-1" : ''),
        ADMIN_ACTION => 1,
        MODULE       => 'Iptv'
      });

      if (!_error_show($Shedule)) {
        $html->message('info', $lang{CHANGED}, $lang{CHANGED});
        $Iptv->user_info($FORM{ID} || $Iptv->{UID});
      }
    }
    else {
      $Iptv->user_change({ %FORM });
      if (!_error_show($Iptv)) {

        #Take Fees
        if (!$Iptv->{STATUS} && $FORM{GET_ABON}) {
          service_get_month_fee($Iptv, { SERVICE_NAME => $lang{TV}, MODULE => 'Iptv' });
        }
        $html->message('info', $lang{CHANGED}, "$lang{CHANGED}");
        $Iptv->user_info($FORM{ID} || $user->{UID});
        if ($conf{IPTV_TRANSFER_SERVICE}) {
          my $service_list = iptv_transfer_service($Iptv);
          iptv_transfer_service($Iptv, {
            SERVICE_LIST => $service_list
          }) if $service_list;
        }
        else {
          iptv_user_channels({ QUIET => 1, USER_INFO => $Iptv });
        }

        $Iptv->{MANDATORY_CHANNELS} = iptv_mandatory_channels($FORM{TP_ID});
        $FORM{change} = 1;
        $FORM{CHANGE_TP} = 1;
        _error_show($Iptv) if iptv_user_services(\%FORM);
      }
    }
  }
  elsif ($FORM{del}) {
    $Shedule->del({
      UID => $user->{UID},
      ID  => $FORM{SHEDULE_ID}
    });
    $html->message('info', $lang{DELETED}, "$lang{DELETED} [$FORM{SHEDULE_ID}]");
  }

  _iptv_show_exist_shedule($period);

  $Tariffs->{DESCRIBE_AID} = ($Iptv->{DESCRIBE_AID}) ? ('['.$Iptv->{DESCRIBE_AID}.']') : '';
  $Tariffs->{UID}     = $attr->{USER_INFO}->{UID};
  $Tariffs->{TP_ID}   = $Iptv->{TP_ID};
  $Tariffs->{TP_NAME} = ($Iptv->{TP_NUM}) ? "$Iptv->{TP_NUM}: $Iptv->{TP_NAME}" : $lang{NOT_EXIST};
  $Tariffs->{ID}      = $Iptv->{ID};

  $html->tpl_show(templates('form_chg_tp'), $Tariffs);

  return 1;
}


#*******************************************************************
=head2 iptv_additional_functions($attr)

  Arguments:
    $attr

=cut
#*******************************************************************
sub iptv_additional_functions {

  if ($Tv_service && $Tv_service->can('additional_functions')) {
    my $result = $Tv_service->additional_functions({ %FORM, %LIST_PARAMS });
    return $result->{RETURN} if (ref $result eq "HASH" && $result->{RETURN});
  }
  else {
    $html->message('err', $lang{ERROR}, "Can't load additional functions");
  }
  return 1;
}

#*******************************************************************
=head2 iptv_get_service_tps($attr)

  Arguments:
    $attr

=cut
#*******************************************************************
sub iptv_get_service_tps {
  my ($attr) = @_;

  my $uid = $FORM{UID} || 0;
  my $user_info = $users->pi({ UID => $uid });
  my $tp_gids = ($user_info->{LOCATION_ID}) ? tp_gids_by_geolocation($user_info->{LOCATION_ID}, $Tariffs, $user_info->{GID}) : '';

  $attr->{EX_PARAMS} ||= $FORM{EX_PARAMS};

  my $tp_sel = $html->form_select('TP_ID', {
    SEL_LIST  => $Tariffs->list({
      MODULE       => 'Iptv',
      NEW_MODEL_TP => 1,
      COLS_NAME    => 1,
      DOMAIN_ID    => $admin->{DOMAIN_ID} || '_SHOW',
      SERVICE_ID   => $FORM{SERVICE_ID},
      STATUS       => '0',
      TP_GID       => $tp_gids || '_SHOW',
    }),
    SEL_KEY   => 'tp_id',
    SEL_VALUE => 'id,name',
    EX_PARAMS => $attr->{EX_PARAMS} ? $attr->{EX_PARAMS} : '',
    SELECTED  => $FORM{TP_ID}
  });

  return $tp_sel if $attr->{RETURN_SELECT};

  print $tp_sel;
}

#**********************************************************
=head2 _iptv_can_change_tp($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub _iptv_can_change_tp {

  return $Iptv->{MONTH_FEE} && $Iptv->{MONTH_FEE} > 0 && !$Iptv->{STATUS} && !$users->{DISABLE}
    && ($users->{DEPOSIT} + $users->{CREDIT} > 0 || $Iptv->{POSTPAID_ABON} || $Iptv->{PAYMENT_TYPE} == 1);
}

#**********************************************************
=head2 _iptv_show_exist_shedule($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub _iptv_show_exist_shedule {
  my ($period) = @_;

  _iptv_add_shedule_form($period);

  my $shedules = $Shedule->list({
    UID          => $user->{UID},
    TYPE         => 'tp',
    MODULE       => 'Iptv',
    SHEDULE_DATE => ">$DATE",
    COLS_NAME    => 1,
    COLS_UPPER   => 1
  });

  return 0 if $Shedule->{TOTAL} < 1;

  my $table = $html->table({
    width   => '100%',
    caption => "$lang{SHEDULE}",,
    ID      => 'SHEDULE_INFO',
    title   => ["ID", "$lang{NEW} $lang{TARIF_PLAN}", $lang{DATE}, $lang{ADMIN}, $lang{ADDED} ]
  });

  foreach my $shedule (@{$shedules}) {
    my ($service, $action) = split(':', $shedule->{ACTION});

    next if !$service || $FORM{ID} != $service;

    my $del_btn = $html->button($lang{DEL}, "index=$index&del=$shedule->{ID}&SHEDULE_ID=$shedule->{ID}&UID=$FORM{UID}&" .
      "ID=$FORM{ID}", { MESSAGE => "$lang{DEL} $shedule->{y}-$shedule->{m}-$shedule->{d}?", class => 'del' });

    my $tp_info = $Tariffs->info($action);
    next if !$action || $Tariffs->{TOTAL} < 1;

    $table->addrow($shedule->{ID}, $tp_info->{NAME}, "$shedule->{Y}-$shedule->{M}-$shedule->{D}", $shedule->{ADMIN_NAME}, $shedule->{DATE}, $del_btn);
  }

  $Tariffs->{SHEDULE_LIST} = $table->show();

  return 0;
}

#**********************************************************
=head2 _iptv_user_shedules($attr)

  Arguments:
    $attr

  Return:

=cut
#**********************************************************
sub _iptv_user_shedules {
  my ($attr) = @_;

  $attr->{chg} ||= $FORM{chg};

  return 0 if(! $attr->{chg});
  my $uid = $user->{UID} || $attr->{UID} || $FORM{UID};

  my $shedules = $Shedule->list({
    UID          => $uid,
    TYPE         => 'tp',
    MODULE       => 'Iptv',
    SHEDULE_DATE => ">=$DATE",
    SORT         => 's.y, s.m, s.d',
    COLS_NAME    => 1,
    COLS_UPPER   => 1
  });

  return if $Shedule->{TOTAL} < 1;

  foreach (@{$shedules}) {
    next if !$_->{ACTION};
    my ($service, $action) = split(':', $_->{ACTION});

    next if !$service || $attr->{chg} != $service;

    my $tp_info = $Tariffs->info($action);
    next if !$action || $Tariffs->{TOTAL} < 1;

    $html->message('info', $lang{INFO}, "$lang{CHANGE_OF_TP} $action:$tp_info->{NAME}. $_->{Y}-$_->{M}-$_->{D}");

    return 0 if $attr->{SHOW_FIRST};
  }

  return 0;
}

#**********************************************************
=head2 _iptv_add_shedule_form($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub _iptv_add_shedule_form {
  my ($period) = @_;

  my $uid = $user->{UID} || $FORM{UID} || 0;
  my $user_info = $users->pi({ UID => $uid });
  my $tp_gids = ($user_info->{LOCATION_ID}) ? tp_gids_by_geolocation($user_info->{LOCATION_ID}, $Tariffs, $user_info->{GID}) : '';

  $Tariffs->{TARIF_PLAN_SEL} = $html->form_select('TP_ID', {
    SELECTED       => $Iptv->{TP_ID},
    SEL_LIST       => $Tariffs->list({
      MODULE       => 'Iptv',
      SERVICE_ID   => $FORM{SERVICE_ID},
      NEW_MODEL_TP => 1,
      COLS_NAME    => 1,
      STATUS       => '0',
      TP_GID       => $tp_gids || '_SHOW',
      DOMAIN_ID    => $admin->{DOMAIN_ID} || '_SHOW',
      DESCRIBE_AID => '_SHOW',
    }),
    SEL_KEY        => 'tp_id',
    SEL_VALUE      => "id,name,describe_aid",
    NO_ID          => 1,
    MAIN_MENU      => ($permissions{0}{10}) ? get_function_index('iptv_tp') : undef,
    MAIN_MENU_ARGV => "TP_ID=$Iptv->{TP_ID}"
  });
  $Tariffs->{PARAMS} .= form_period($period, { ABON_DATE => $Iptv->{ABON_DATE} });
  $Tariffs->{ACTION} = 'set';
  $Tariffs->{LNG_ACTION} = $lang{CHANGE};

  return 0;
}

#**********************************************************
=head2 _iptv_users_import($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub _iptv_users_import {
  my ($attr) = @_;
  
  if (!$FORM{add}) {
    $html->tpl_show(templates('form_import'), {
      IMPORT_FIELDS => 'LOGIN,SERVICE_ID,TP_ID,STATUS,SUBSCRIBE_ID',
      CALLBACK_FUNC => 'iptv_user'
    });

    return 0;
  }
  
  my $import_accounts = import_former(\%FORM);
  my $total = $#{$import_accounts} + 1;

  foreach my $account (@{$import_accounts}) {
    my $user_info = $users->info(undef, { LOGIN => $account->{LOGIN} });
    
    next if $users->{TOTAL} < 1;

    $account->{UID} = $users->{UID};

    $Iptv->user_add($account);
    if (!_error_show($Iptv) && $account->{SERVICE_ID}) {

      $Iptv->{SERVICE_ID} = $account->{SERVICE_ID};
      my $action_result = iptv_account_action({
        %{$account},
        ID          => $Iptv->{ID},
        USER_IMPORT => 1
      });

      if ($action_result) {
        ::_error_show($Iptv, {
          ID          => 837,
          MODULE_NAME => $Tv_service->{SERVICE_NAME}
        });

        $Iptv->{db}{db}->rollback();
      }
      else {
        $Iptv->{db}{db}->commit();
      }
    }
  }

  $html->message('info', $lang{INFO},
    "$lang{ADDED}\n $lang{FILE}: $FORM{UPLOAD_FILE}{filename}\n Size: $FORM{UPLOAD_FILE}{Size}\n Count: $total");

  return 1
}

1;
