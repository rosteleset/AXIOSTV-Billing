=head NAME

  Cams Users

=cut

use strict;
use warnings FATAL => 'all';
use AXbills::Base qw(in_array cmd _bp);
require AXbills::Misc;
use Cams::Axiostv_cams; 

our (
  %FORM,
  $html,
  %lang,
  $db,
  %conf,
  $admin,
  $Cams_service,
  $users,
  $user,
  @MODULES,
  $DATE,
  $TIME,
  $index,
  %LIST_PARAMS,
);

my $Cams = Cams->new($db, $admin, \%conf);
my $Address = Address->new($db, $admin, \%conf);
my $Users = Users->new($db, $admin, \%conf);

#**********************************************************
=head2 cams_user($attr) - Users info

=cut
#**********************************************************
sub cams_user {

  $Cams->{db}{db}->{AutoCommit} = 0;
  $Cams->{db}->{TRANSACTION} = 1;
  $Cams->{ACTION} = 'add';
  $Cams->{LNG_ACTION} = $lang{ADD};
  my $uid = $FORM{UID} || " ";
  my $user_groups = '';

  if ($FORM{add}) {
    $Cams->users_list({ UID => $uid, TP_ID => $FORM{TP_ID} || 0 });

    if ($Cams->{TOTAL}) {
      $html->message('err', $lang{ERROR}, "This tariff already used");
      return 1;
    }

    $Cams->user_add({
      UID    => $FORM{UID} || "",
      TP_ID  => $FORM{TP_ID} || 0,
      STATUS => $FORM{STATUS} || 0,
      ACTIVATE => $FORM{ACTIVATE} || "",
      EXPIRE   => $FORM{EXPIRE} || ""
    });

    show_result($Cams, $lang{ADDED}) if !$Cams->{errno};

    if (!$Cams->{errno}) {
      $Cams->{ID} = $Cams->{INSERT_ID};

      if (!$FORM{STATUS}) {
        $Cams->_info($Cams->{ID});

        if ($Cams->{ACTIVATE}) {
          ($Cams->{ACTIVATE}, undef) = split(" ", $Cams->{ACTIVATE});
        }

        ::service_get_month_fee($Cams, {
          UID                        => $FORM{UID} || $Cams->{UID} || "",
          SERVICE_NAME               => $lang{CAMERAS},
          DO_NOT_USE_GLOBAL_USER_PLS => 1
        });
      }
    }

    _cams_autofill_groups() if ($conf{CAMS_CHECK_USER_GROUPS} && $Cams->{ID});
    _cams_autofill_folders() if ($conf{CAMS_CHECK_USER_FOLDERS} && $Cams->{ID});
  }
  elsif ($FORM{change}) {
    $Cams->user_change(\%FORM);

    if ($Cams->{OLD_STATUS} && !$Cams->{STATUS}) {
      if (cams_user_activate($Cams, { USER => $users, REACTIVATE => (!$Cams->{STATUS}) ? 1 : 0, })) {
        $Cams->user_change(\%FORM);
      }
    }
    $FORM{chg} = $FORM{ID};
  }
  elsif ($FORM{del} && $FORM{COMMENTS}) {
    my $result = $Cams->_list({
      SERVICE_ID => '_SHOW',
      ID         => $FORM{del},
      COLS_NAME  => 1,
      COLS_UPPER => 1,
    });

    if ($Cams->{TOTAL}) {
      $FORM{SERVICE_ID} = $result->[0]{SERVICE_ID};
    }

    $Cams->_info($FORM{del});
    if (!$Cams->{errno}) {
      $Cams->_del($FORM{del}, { %FORM, ID => $FORM{del} });
      if (!$Cams->{errno}) {
        $Cams->{ID} = $FORM{del};
        $html->message('info', $lang{INFO}, "$lang{DELETED} [ $Cams->{ID} ]");
        delete $Cams->{ID};
      }
    }
  }
  elsif (!$FORM{add_form}) {
    my $list = $Cams->users_list({ UID => $FORM{UID}, ID => '_SHOW', COLS_NAME => 1 });
    $FORM{chg} = $list->[0]->{id} if $Cams->{TOTAL} == 1;
  }

  if ($FORM{chg} || ($FORM{ID} && !$FORM{del})) {
    $Cams->{ACTION} = 'change';
    $Cams->{LNG_ACTION} = $lang{CHANGE};

    my $result = $Cams->_info($FORM{chg});

    if ($Cams->{TOTAL} > 0) {
      $Cams->{SERVICE_ID} = $result->{SERVICE_ID};
      $Cams->{TP_ID} = $result->{TP_ID};
      $Cams->{STATUS} = $result->{STATUS};
      $Cams->{ACTIVATE} = $result->{ACTIVATE};
      $Cams->{EXPIRE} = $result->{EXPIRE};
    }

    if ($FORM{UID}) {
      my $user_folders = cams_user_folders({ SERVICE_INFO => $Cams, UID => $FORM{UID}, SERVICE_ID => $Cams->{SERVICE_ID} });

      $user_groups .= defined($user_folders) ?
        $user_folders : cams_user_groups({ SERVICE_INFO => $Cams, UID => $FORM{UID}, SERVICE_ID => $Cams->{SERVICE_ID} });

      $user_groups .= "<br>";

    }
  }

  $Cams_service = cams_user_services(\%FORM);

  $FORM{SUBSCRIBE_FORM} = cams_services_sel({ %FORM, %$Cams, FORM_ROW => 1, UNKNOWN => 1 });

  if (!$Cams->{ID} || $FORM{ID}) {
    $Cams->{TP_ADD} = $html->form_select('TP_ID', {
      SELECTED  => $FORM{TP_ID} || $Cams->{TP_ID} || '',
      SEL_LIST  => $Cams->tp_list({ TP_ID => '_SHOW', NAME => '_SHOW', SERVICE_ID => ($FORM{SERVICE_ID} || $Cams->{SERVICE_ID} || "_SHOW") }),
      SEL_KEY   => 'tp_id',
      SEL_VALUE => 'tp_id,name',
    });

    $Cams->{TP_DISPLAY_NONE} = "style='display:none'";
  }

  $Cams->{STATUS_SEL} = sel_status({ STATUS => $FORM{STATUS} || $Cams->{STATUS} });

  $html->tpl_show(_include('cams_user', 'Cams'), { %FORM, %$Cams, });

# Перед выводом таблички
  if ($FORM{add_user_rights}) {
    my $service_id = $FORM{SERVICE_ID} || $Cams->{SERVICE_ID};
    my $cams_object = Cams::Axiostv_cams->new($db, $admin, \%conf);
    my $auth_data = $Cams->services_info($service_id);


    my $user_rights_array = $cams_object->dph_keys_get_devices_list({ UID => $FORM{UID}, URL=> $auth_data->{URL}, PASSWORD => $auth_data->{PASSWORD}, LOGIN => $auth_data->{LOGIN} });
    my $user_rights_array_items = $user_rights_array->{devices};  

    my $html_txt = "<table class='table table-striped table-hover ' id='add_user_rights'>"; 
    #for (my $i = 0; $i <= $#user_rights_array_items; $i++) {
    foreach my $el (@$user_rights_array_items) {

      my $checkbox = $html->form_input('ADD_IDS', $el->{device_id}, {
        TYPE          => 'checkbox',
        STATE         => undef,
        OUTPUT2RETURN => 1,
      });

      $html_txt .= '<tr><td>'.$checkbox.'</td><td>'.$el->{device_id}.'</td><td>'.$el->{device_type}.'</td><td>'.$el->{title}.'</td></tr>';
    }  
    $html_txt .= '</table>';
    $FORM{html} = $html_txt;

    $html->tpl_show(_include('cams_user_add_user_rights', 'Cams'), { %FORM, %$Cams, });  

  } else {

    print $user_groups  if ($user_groups);
    print cams_user_rights({ SERVICE_INFO => $Cams, UID => $FORM{UID}, SERVICE_ID => $Cams->{SERVICE_ID} })  if ($user_groups);
    print $html->br();print $html->br();
    if ($FORM{UID}) {
      my $user_keys = cams_user_keys({ SERVICE_INFO => $Cams, UID => $FORM{UID}, SERVICE_ID => $Cams->{SERVICE_ID} });
      print $user_keys;
      print $html->br();
      print $html->br();

    }

  }

  $LIST_PARAMS{SERVICE_NAME} = "_SHOW";
  result_former({
    INPUT_DATA      => $Cams,
    FUNCTION        => 'users_list',
    BASE_FIELDS     => 0,
    DEFAULT_FIELDS  => 'ID,TP_NAME,SERVICE_STATUS,SERVICE_NAME,ACTIVATE,EXPIRE',
    FUNCTION_FIELDS => 'change, del',
    SKIP_USER_TITLE => 1,
    EXT_TITLES      => {
      id             => "#",
      tp_name        => $lang{TARIF_PLAN},
      service_status => $lang{STATUS},
      service_name   => $lang{SERVICE},
      activate       => $lang{ACTIVATE},
      expire         => $lang{EXPIRE}
    },
    STATUS_VALS     => sel_status({ HASH_RESULT => 1 }),
    TABLE           => {
      width   => '100%',
      caption => $lang{TARIF_PLANS},
      qs      => $pages_qs,
      ID      => 'CAMS_MAIN',
      header  => '',
      EXPORT  => 1,
      MENU    => "$lang{ADD}:index=$index&UID=$uid&add_form=1" . ':add',
    },
    MAKE_ROWS       => 1,
    TOTAL           => 1
  });

  return 0;
}

#**********************************************************
=head2 cams_cameras($attr) - Actions on cameras

=cut
#**********************************************************
sub cams_cameras {
  my ($attr) = @_;

  my $tariff = '';
  my %CAMS_STREAM = ();
  my $show_add_form = 0;
  my $correct_name = 1;
  my $services = $html->form_main({
    CONTENT => cams_tariffs_sel({
      UID        => $attr->{UID} || $FORM{UID},
      AUTOSUBMIT => 'form'
    }),
    HIDDEN  => {
      index => $index,
      UID => $FORM{UID},
      show => 1
    },
    class   => 'form-inline ml-auto flex-nowrap',
  });

  func_menu({ $lang{NAME} => $services });

  if ($FORM{show} && !$FORM{TP_ID}) {
    $html->message('err', $lang{ERROR}, "$lang{NO_TARIFF_PLAN_SELECTED}");
    return 1;
  }

  return 1 if !$FORM{TP_ID};

  $tariff = $Cams->tp_info($FORM{TP_ID});

  if ($FORM{add_form}) {
    $show_add_form = 1;

    # Default params
    $CAMS_STREAM{RTSP_PORT} = '554';
    $CAMS_STREAM{LOGIN} = 'admin';
    $CAMS_STREAM{PASSWORD} = 'admin';
  }

  if ($FORM{add_cam}) {
    if (!$FORM{TP_ID}) {
      $html->message('err', $lang{ERROR}, $lang{NO_TARIFF_PLAN_SELECTED});
      return 1;
    }

    $correct_name = _cams_add_user_stream(\%FORM);
  }
  elsif ($FORM{change_cam}) {
    my $uid = $FORM{UID};

    $FORM{HOST} = _cams_correct_host($FORM{HOST}) if !$conf{CAMS_SKIP_CHECK_HOST};
    if ($FORM{NAME} =~ /^[aA-zZ\d_-]+$/mg && $FORM{HOST}) {
      $Cams->stream_change(\%FORM);
      if (!_error_show($Cams)) {
        show_result($Cams, $lang{CHANGED});
        my $camera_info = $Cams->stream_info($FORM{ID});
        $FORM{FOLDER_ID} //= $camera_info->{FOLDER_ID};
      }
    }
    else {
      $html->message('err', $lang{ERROR}, $lang{ONLY_LATIN_LETTER}) if $FORM{HOST};
      $correct_name = 0;
    }

    $FORM{UID} = $uid;
  }
  elsif ($FORM{chg_cam}) {
    my $camera = $Cams->stream_info($FORM{chg_cam});
    if (!_error_show($Cams)) {
      %CAMS_STREAM = %{$camera};

      if ($camera->{FOLDER_ID}) {
        $Cams->folder_info($camera->{FOLDER_ID});
        $CAMS_STREAM{PRIVATE_CAMERA} = 'checked' if $Cams->{UID};
      }

      $show_add_form = 1;
    }
  }
  elsif ($FORM{del_cam}) {
    my $cams_info = $Cams->stream_info($FORM{del_cam});
    $FORM{CAM_NAME} = $cams_info->{NAME} || "";
    $Cams->stream_del({ ID => $FORM{del_cam} });
    show_result($Cams, $lang{DELETED});
  }

  my $uid = $user->{UID} || $FORM{UID};
  return 0 unless ($uid);

  $FORM{CAMS_TP_ID} ||= $tariff->{TP_ID};
  $FORM{SERVICE_ID} ||= $tariff->{SERVICE_ID};

  my $user_tps = $Cams->_list({
    SERVICE_ID       => '_SHOW',
    TP_ID            => $tariff->{TP_ID},
    STATUS           => '_SHOW',
    ID               => '_SHOW',
    TP_STREAMS_COUNT => '_SHOW',
    UID              => $uid,
    COLS_NAME        => 1,
    COLS_UPPER       => 1,
    PAGE_ROWS        => 99999,
  });

  if ($FORM{change_camera_now} && $Cams->{TOTAL}) {
    my @cameras = $FORM{IDS} ? split(',', $FORM{IDS}) : ();
    my $cameras_count = @cameras;

    if ($cameras_count > $user_tps->[0]{TP_STREAMS_COUNT}) {
      $html->message('err', $lang{ERROR}, "$lang{EXCEEDED_THE_NUMBER}: $user_tps->[0]{TP_STREAMS_COUNT}");
      $correct_name = 0;
    }
    else {
      $Cams->user_cameras({
        TP_ID => $FORM{CAMS_TP_ID},
        ID    => $user_tps->[0]{id},
        IDS   => $FORM{IDS},
      });
    }
  }

  if ($FORM{SERVICE_ID} && $correct_name) {
    $Cams->{SERVICE_ID} = $FORM{SERVICE_ID};
    $Cams_service = cams_user_services(\%FORM);
  }

  if ($show_add_form && $user_tps->[0]{id}) {
    $CAMS_STREAM{GROUPS_SELECT} = _cams_groups_select({
      TP_ID      => $FORM{CAMS_TP_ID},
      ID         => $user_tps->[0]{id},
      UID        => $FORM{UID},
      SERVICE_ID => $FORM{SERVICE_ID},
    });

    $CAMS_STREAM{FOLDERS_SELECT} = _cams_folders_select({
      TP_ID      => $FORM{CAMS_TP_ID},
      ID         => $user_tps->[0]{id},
      UID        => $FORM{UID},
      SERVICE_ID => $FORM{SERVICE_ID},
    });

    $CAMS_STREAM{ORIENTATION_SELECT} = _cams_orientation_select({ SELECTED => ($CAMS_STREAM{ORIENTATION} || 0) });
    $CAMS_STREAM{ARCHIVE_SELECT} = _cams_archive_select({ SELECTED => $CAMS_STREAM{ARCHIVE} });
    $CAMS_STREAM{TYPE_SELECT} = _cams_type_select({ SELECTED => ($CAMS_STREAM{TYPE} || 0) });
    $CAMS_STREAM{TRANS_SELECT} = _cams_transport_select({ SELECTED => ($CAMS_STREAM{TRANSPORT} || 0) });
    $CAMS_STREAM{SOUND_SELECT} = $html->form_select('SOUND', {
      SELECTED => $CAMS_STREAM{SOUND} || q{},
      SEL_LIST => [
        { id => 1, name => "PCMA/PCMU" },
        { id => 2, name => "AAC" },
      ],
      NO_ID    => 1
    });
    $html->tpl_show(_include('cams_stream_add_user', 'Cams'), {
      %CAMS_STREAM, %FORM,
      LIMIT_ARCHIVE      => $CAMS_STREAM{LIMIT_ARCHIVE} ? 'checked' : '',
      PRE_IMAGE          => $CAMS_STREAM{PRE_IMAGE} ? 'checked' : '',
      CONSTANTLY_WORKING => $CAMS_STREAM{CONSTANTLY_WORKING} ? 'checked' : '',
      ONLY_VIDEO         => $CAMS_STREAM{ONLY_VIDEO} ? 'checked' : '',
      UID                => $user->{UID} || $FORM{UID},
      DISABLED_CHECKED   => $CAMS_STREAM{DISABLED} ? 'checked' : '',
      SUBMIT_BTN_ACTION  => ($FORM{chg_cam}) ? 'change_cam' : 'add_cam',
      SUBMIT_BTN_NAME    => ($FORM{chg_cam}) ? $lang{CHANGE} : $lang{ADD},
      FUNCTION_NAME      => 'cams_get_group_folders'
    });
  }

  my @access_cameras = ();
  my @active_streams = ();
  my @private_cameras = ();
  foreach my $user_tp (@$user_tps) {
    @active_streams = _cams_get_active_user_cameras({
      TP_ID => $user_tp->{tp_id},
      ID    => $user_tp->{id},
    });

    @access_cameras = _cams_get_access_user_cameras({
      TP_ID => $user_tp->{tp_id},
      ID    => $user_tp->{id},
      UID   => $FORM{UID},
    });

    @private_cameras = _cams_get_private_user_cameras({
      TP_ID => $user_tp->{tp_id},
      ID    => $user_tp->{id},
      UID   => $FORM{UID},
    });
  }

  my @titles = ('#', $lang{NAME}, $lang{CAM_TITLE}, 'Host', $lang{LOGIN}, $lang{DISABLED}, '', '');
  $FORM{SERVICE_ID} ||= "";
  $FORM{CAMS_TP_ID} ||= "";
  my $table = $html->table({
    width      => '100%',
    caption    => $lang{CAMERAS},
    title      => \@titles,
    pages      => $Cams->{TOTAL},
    qs         => $pages_qs,
    ID         => 'CAMERAS_STREAMS_ID',
    MENU       => "$lang{ADD}:index=$index&add_form=1&SERVICE_ID=$FORM{SERVICE_ID}&UID=$uid&TP_ID=$FORM{TP_ID}&CAMS_TP_ID=$FORM{CAMS_TP_ID}" . ':add',
    DATA_TABLE => 1,
  });

  foreach my $stream (@access_cameras) {
    my $checkbox = $html->form_input('IDS', $stream->{id}, { TYPE => 'checkbox',
      EX_PARAMS                                                   => (in_array($stream->{id}, \@active_streams) ? 'checked' : '') });
    $table->addrow($checkbox, $stream->{name}, $stream->{title}, $stream->{host}, $stream->{login},
      ($stream->{disabled} eq '1') ? $lang{YES} : $lang{NO}, '-', '-');
  }

  foreach my $stream (@private_cameras) {
    my $checkbox = $html->form_input('IDS', $stream->{id}, { TYPE => 'checkbox',
      EX_PARAMS                                                   => (in_array($stream->{id}, \@active_streams) ? 'checked' : '') });
    my $change_button = $html->button($lang{CHANGE}, "index=$index&chg_cam=$stream->{id}&SERVICE_ID=$FORM{SERVICE_ID}&UID=$uid" .
      "&TP_ID=$FORM{TP_ID}&CAMS_TP_ID=$FORM{CAMS_TP_ID}", { class => 'change' });
    my $del_button = $html->button($lang{DEL}, "index=$index&del_cam=$stream->{id}&SERVICE_ID=$FORM{SERVICE_ID}&UID=$uid" .
      "&TP_ID=$FORM{TP_ID}&CAMS_TP_ID=$FORM{CAMS_TP_ID}", { MESSAGE => "$lang{DEL} $stream->{id}?", class => 'del' });
    $table->addrow($checkbox, $stream->{name}, $stream->{title}, $stream->{host}, $stream->{login},
      ($stream->{disabled} eq '1') ? $lang{YES} : $lang{NO}, $change_button, $del_button);
  }

  my %submit_h = ();
  $submit_h{change_camera_now} = $lang{CHANGE};

  print $html->form_main({
    CONTENT => $table->show({ OUTPUT2RETURN => 1 }),
    HIDDEN  => {
      UID        => $FORM{UID},
      ID         => $FORM{chg} || $FORM{ID},
      TP_ID      => $FORM{TP_ID} || $Cams->{TP_ID},
      CAMS_TP_ID => $FORM{CAMS_TP_ID},
      index      => $index,
    },
    METHOD  => 'get',
    SUBMIT  => \%submit_h
  });

  return 1;
}

#**********************************************************
=head2 cams_user_services($form_) - Service add

  Arguments:
    $form_ - INPUT FORM arguments

  Results:
    $Tv_service [obj]

=cut
#**********************************************************
sub cams_user_services {
  my ($form_) = @_;

  $Cams->{SERVICE_ID} = $form_->{SERVICE_ID} if $form_->{SERVICE_ID};
  $Cams_service = undef;
  my DBI $db_ = $Cams->{db}{db};

  if ($Cams->{SERVICE_ID}) {
    $Cams_service = cams_load_service($Cams->{MODULE}, { SERVICE_ID => $Cams->{SERVICE_ID} });
  }
  else {
    delete($Cams->{db}->{TRANSACTION});
    if (! $db_->{AutoCommit}) {
      $db_->commit();
      $db_->{AutoCommit} = 1;
    }
    return $Cams_service;
  }

  if (!_error_show($Cams) && $Cams_service) {

    my $action_result = cams_account_action({
      %$form_,
      ID           => $Cams->{ID} || $form_->{ID},
      SUBSCRIBE_ID => $form_->{SUBSCRIBE_ID} || $Cams->{SUBSCRIBE_ID} || '',
    });

    if ($action_result) {
      _error_show($Cams, {
        ID          => 4035,
        MODULE_NAME => $Cams_service->{SERVICE_NAME}
      });

      $db_->rollback();
      delete $Cams->{ID};
    }
    else {
      $html->message('info', $lang{INFO}, $Cams->{MESSAGE}) if ($Cams->{MESSAGE});
    }
    delete($Cams->{db}->{TRANSACTION});
    if (! $db_->{AutoCommit}) {
      $db_->commit();
      $db_->{AutoCommit} = 1;
    }
  }
  else {
    delete($Cams->{db}->{TRANSACTION});
    if (! $db_->{AutoCommit}) {
      $db_->commit();
      $db_->{AutoCommit} = 1;
    }
  }

  return $Cams_service;
}

#**********************************************************
=head2 cams_account_action($attr) - Control external services

  Arguments:
    $attr
      add
      change
      del

  Returns:

    True or False

=cut
#**********************************************************
sub cams_account_action {
  my ($attr) = @_;

  my $result = 0;

  if (($Cams->{SERVICE_ID} || ($attr->{SERVICE_ID} && $attr->{MODULE})) && !$Cams_service) {
    $Cams->{SERVICE_ID} = $Cams->{SERVICE_ID} || $attr->{SERVICE_ID};
    $Cams->{MODULE} = $Cams->{MODULE} && $Cams->{MODULE} ne "Cams" ? $Cams->{MODULE} : $attr->{MODULE};
    $Cams_service = cams_load_service($Cams->{MODULE}, { SERVICE_ID => $Cams->{SERVICE_ID} });
    if ($Cams_service && $Cams_service->{SUBSCRIBE_COUNT}) {
      $attr->{SUBSCRIBE_COUNT} = $Cams_service->{SUBSCRIBE_COUNT};
    }
  }

  $Cams->{TP_ID} = $attr->{TP_ID} if ($attr->{TP_ID} && !$Cams->{TP_ID});
  my $uid = $attr->{UID} || $Cams->{UID} || $FORM{UID};
  if ($attr->{USER_INFO}) {
    $users = $attr->{USER_INFO};
  }

  if ($attr->{NEGDEPOSIT}) {
    if ($Cams_service && $Cams_service->can('user_negdeposit')) {
      $Cams_service->user_negdeposit($attr);
      if ($Cams_service->{errno}) {
        print "$Cams_service->{SERVICE_NAME} Error: [$Cams_service->{errno}]  $Cams_service->{errstr} UID: $uid $attr->{ID}\n";
      }
    }
  }
  elsif ($attr->{add}) {
    if ($Cams_service && $Cams_service->can('user_add')) {
      $users->pi({ UID => $uid });
      $Cams->{PHONE} = $users->{PHONE};
      $users->info($uid, { SHOW_PASSWORD => 1 });
      $Cams->_info($attr->{ID});
      $Cams->{EMAIL} ||= $users->{EMAIL};
      $Cams->{LOGIN} = $users->{LOGIN};

      $Cams_service->user_add({
        %{$users},
        %{$Cams},
        %{$attr},
        ID => $Cams->{ID}
      });

      if ($Cams_service->{errno}) {
        $Cams->{errno} = $Cams_service->{errno};
        $Cams->{errstr} = $Cams_service->{errstr};
        $result = 1;
      }
      else {
        if (($conf{CAMS_CHECK_USER_GROUPS} || $conf{CAMS_CHECK_USER_FOLDERS}) && !$attr->{SERVICE_ACTIVATED}) {
          $attr->{change_now} = 1;
          $attr->{chg} = $Cams->{ID};
        }

        if ($Cams_service->{SUBSCRIBE_ID}) {
          $Cams->user_change({ ID => $Cams->{ID}, SUBSCRIBE_ID => $Cams_service->{SUBSCRIBE_ID} });
        }
        $result = 0;
      }
    }
  }
  elsif ($attr->{change}) {
    if ($Cams_service && $Cams_service->can('user_change')) {
      $users->info($uid, { SHOW_PASSWORD => 1 });
      $users->pi({ UID => $uid });
      $Cams_service->user_change({
        %$attr,
        %$users,
        %$Cams,
        %FORM
      });

      if ($Cams_service->{errno}) {
        $Cams->{errno} = $Cams_service->{errno};
        $Cams->{errstr} = $Cams_service->{errstr};
        $result = 1;
      }
      else {
        if ($Cams_service->{SUBSCRIBE_ID}) {
          $Cams->user_change({
            ID           => $Cams->{ID},
            SUBSCRIBE_ID => $Cams_service->{SUBSCRIBE_ID}
          });
        };
      }
    }
  }
  elsif ($attr->{chg}) {
    if ($Cams_service && $Cams_service->can('user_info')) {
      my $user_info = $Cams->_info($attr->{chg});
      $users->info($uid, { SHOW_PASSWORD => 1 });
      $Cams_service->user_info({ %$attr, %$users, %{$Cams}, %{$user_info} });
    }
  }
  elsif ($attr->{del}) {
    if ($Cams_service && $Cams_service->can('user_del')) {
      $users->info($uid, { SHOW_PASSWORD => 1 });
      $Cams_service->user_del({ %$attr, %{$Cams}, %$users, ID => $attr->{del}, NAME => $attr->{CAM_NAME} });
    }
  }
  elsif ($attr->{change_cam}) {
    if ($Cams_service && $Cams_service->can('camera_change')) {
      my $group_info = ();
      $group_info = $Cams->folder_info($attr->{FOLDER_ID}) if $attr->{FOLDER_ID};
      $group_info = $Cams->group_info($attr->{GROUP_ID}) if $attr->{GROUP_ID} && !$attr->{FOLDER_ID};
      $Cams_service->camera_change({
        %$attr,
        %$Cams,
        %FORM,
        SUBGROUP_ID => $group_info->{SUBGROUP_ID} ? $group_info->{SUBGROUP_ID} : "",
      });

      if ($Cams_service->{errno}) {
        $Cams->{errno} = $Cams_service->{errno};
        $Cams->{errstr} = $Cams_service->{errstr};
        $result = 1;
      }
    }
  }
  elsif ($attr->{add_cam}) {
    if ($Cams_service && $Cams_service->can('camera_add')) {
      my $group_info = ();
      $group_info = $Cams->folder_info($attr->{FOLDER_ID}) if $attr->{FOLDER_ID};
      $group_info = $Cams->group_info($attr->{GROUP_ID}) if $attr->{GROUP_ID} && !$attr->{FOLDER_ID};
      $Cams_service->camera_add({
        %{$Cams},
        %{$attr},
        ID          => $attr->{CAM_ID},
        SUBGROUP_ID => $group_info->{SUBGROUP_ID} ? $group_info->{SUBGROUP_ID} : ($attr->{SUBGROUP_ID} || ''),
      });

      if ($Cams_service->{errno}) {
        $Cams->{errno} = $Cams_service->{errno};
        $Cams->{errstr} = $Cams_service->{errstr};
        $result = 1;
      }
      else {
        if ($Cams_service->{NUMBER_ID}) {
          $Cams->stream_change({
            ID        => $attr->{CAM_ID},
            NUMBER_ID => $Cams_service->{NUMBER_ID}
          });
        };
      }
    }
  }
  elsif ($attr->{chg_cam}) {
    if ($Cams_service && $Cams_service->can('camera_info')) {
      $users->pi({ UID => $uid });
      my $camera_info = $Cams->stream_info($attr->{chg_cam});
      $Cams_service->camera_info({ %{$attr}, %{$users}, %{$Cams}, %{$camera_info} });
      if ($Cams_service->{errno}) {
        $Cams->{errno} = $Cams_service->{errno};
        $Cams->{errstr} = $Cams_service->{errstr};
        $result = 1;
      }
    }
  }
  elsif ($attr->{del_cam}) {
    if ($Cams_service && $Cams_service->can('camera_del')) {
      $Cams->stream_info($attr->{del_cam});
      $Cams_service->camera_del({ %$attr, %{$Cams}, ID => $attr->{del_cam} });
    }
  }
  elsif ($attr->{change_group}) {
    if ($Cams_service && $Cams_service->can('group_change')) {
      $Cams->group_info($FORM{ID});
      $Cams_service->group_change({ %$attr, %$Cams, %FORM });

      if ($Cams_service->{errno}) {
        $Cams->{errno} = $Cams_service->{errno};
        $Cams->{errstr} = $Cams_service->{errstr};
        $result = 1;
      }
    }
  }
  elsif ($attr->{add_group}) {
    if ($Cams_service && $Cams_service->can('group_add')) {
      $Cams_service->group_add({
        %{$Cams},
        %{$attr},
        ID => $Cams->{ID}
      });

      if ($Cams_service->{errno}) {
        $Cams->{errno} = $Cams_service->{errno};
        $Cams->{errstr} = $Cams_service->{errstr};
        $result = 1;
      }
      else {
        if ($Cams_service->{SUBGROUP_ID}) {
          $Cams->group_change({
            ID          => $attr->{GROUP_ID},
            SUBGROUP_ID => $Cams_service->{SUBGROUP_ID}
          });
        };
      }
    }
  }
  elsif ($attr->{chg_group}) {
    if ($Cams_service && $Cams_service->can('group_info')) {
      $Cams->group_info($attr->{chg_group});
      $Cams_service->group_info({ %$attr, %$users, %{$Cams} });
      if ($Cams_service->{errno}) {
        $Cams->{errno} = $Cams_service->{errno};
        $Cams->{errstr} = $Cams_service->{errstr};
        $result = 1;
      }
    }
  }
  elsif ($attr->{del_group}) {
    if ($Cams_service && $Cams_service->can('group_del')) {
      $Cams->group_info($attr->{del_group});
      $Cams_service->group_del({ %$attr, %{$Cams}, ID => $attr->{del_cam} });
      if ($Cams_service->{errno}) {
        $Cams->{errno} = $Cams_service->{errno};
        $Cams->{errstr} = $Cams_service->{errstr};
        $result = 1;
      }
    }
  }
  elsif ($attr->{change_folder}) {
    if ($Cams_service && $Cams_service->can('folder_change')) {
      $Cams->folder_info($attr->{ID});
      $Cams_service->folder_change({ %$attr, %$Cams, %FORM });
      if ($Cams_service->{errno}) {
        $Cams->{errno} = $Cams_service->{errno};
        $Cams->{errstr} = $Cams_service->{errstr};
        $result = 1;
      }
    }
  }
  elsif ($attr->{add_folder}) {
    if ($Cams_service && $Cams_service->can('folder_add')) {
      $Cams_service->folder_add({
        %{$Cams},
        %{$attr},
        ID => $Cams->{ID}
      });

      if ($Cams_service->{errno}) {
        $Cams->{errno} = $Cams_service->{errno};
        $Cams->{errstr} = $Cams_service->{errstr};
        $result = 1;
      }
      else {
        if ($Cams_service->{SUBFOLDER_ID}) {
          $Cams->folder_change({
            ID           => $attr->{INSERT_ID},
            SUBFOLDER_ID => $Cams_service->{SUBFOLDER_ID}
          });
        };
      }
    }
  }
  elsif ($attr->{chg_folder}) {
    if ($Cams_service && $Cams_service->can('folder_info')) {
      $Cams->folder_info($attr->{chg_folder});
      $Cams_service->folder_info({ %$attr, %$users, %{$Cams} });
      if ($Cams_service->{errno}) {
        $Cams->{errno} = $Cams_service->{errno};
        $Cams->{errstr} = $Cams_service->{errstr};
        $result = 1;
      }
    }
  }
  elsif ($attr->{del_folder}) {
    if ($Cams_service && $Cams_service->can('folder_del')) {
      $Cams_service->folder_del({ %$attr, %{$Cams} });
      if ($Cams_service->{errno}) {
        $Cams->{errno} = $Cams_service->{errno};
        $Cams->{errstr} = $Cams_service->{errstr};
        $result = 1;
      }
    }
  }


  if ($attr->{change_now} && $attr->{chg}) {
    if ($Cams_service && $Cams_service->can('change_user_groups') && !$attr->{CHANGE_FOLDERS}) {
      $attr->{IDS} = $attr->{GROUP_IDS} if $attr->{GROUP_IDS};
      $users->info($uid);
      my $tp_params = $Cams->tp_list({
        TP_ID => $attr->{TP_ID} || $Cams->{TP_ID},
        DVR   => '_SHOW',
        PTZ   => '_SHOW',
      });

      if ($Cams->{TOTAL}) {
        $attr->{DVR} = $tp_params->[0]{dvr};
        $attr->{PTZ} = $tp_params->[0]{ptz};
      }

      $Cams_service->change_user_groups({ %$attr, %{$Cams}, %$users });
      if ($Cams_service->{errno}) {
        $Cams->{errno} = $Cams_service->{errno};
        $Cams->{errstr} = $Cams_service->{errstr};
        $result = 1;
      }
    }

    $attr->{CHANGE_FOLDERS} = 1 if $attr->{FOLDER_IDS};
    if ($Cams_service && $Cams_service->can('change_user_folders') && $attr->{CHANGE_FOLDERS}) {
      $attr->{IDS} = $attr->{FOLDER_IDS} if $attr->{FOLDER_IDS};
      $users->info($uid);
      my $tp_params = $Cams->tp_list({
        TP_ID => $attr->{TP_ID} || $Cams->{TP_ID},
        DVR   => '_SHOW',
        PTZ   => '_SHOW',
      });

      if ($Cams->{TOTAL}) {
        $attr->{DVR} = $tp_params->[0]{dvr};
        $attr->{PTZ} = $tp_params->[0]{ptz};
      }

      $Cams_service->change_user_folders({ %$attr, %{$Cams}, %$users });
      if ($Cams_service->{errno}) {
        $Cams->{errno} = $Cams_service->{errno};
        $Cams->{errstr} = $Cams_service->{errstr};
        $result = 1;
      }
    }
  }
  elsif ($attr->{change_camera_now}) {
    if ($Cams_service && $Cams_service->can('change_user_cameras')) {
      $users->info($uid);

      $Cams_service->change_user_cameras({ %$attr, %{$Cams}, %$users });
      if ($Cams_service->{errno}) {
        $Cams->{errno} = $Cams_service->{errno};
        $Cams->{errstr} = $Cams_service->{errstr};
        $result = 1;
      }
    }
  }

  return $result;
}

#**********************************************************
=head2 _cams_get_access_user_cameras($attr) - Get all access user cameras

  Arguments:
     $attr
       tp_id - tariff id
       id    - id in `cams_main` table (user subscribe)
       uid   - user id

  Results:
     list of access cameras

=cut
#**********************************************************
sub _cams_get_access_user_cameras {
  my ($attr) = @_;

  my @access_cameras = ();

  my $groups = $Cams->user_folders_list({
    TP_ID                => $attr->{TP_ID},
    ID                   => $attr->{ID},
    SKIP_PRIVATE_CAMERAS => 1,
    PAGE_ROWS            => 10000,
    COLS_NAME            => 1
  });

  $groups = $Cams->user_groups_list({
    TP_ID     => $attr->{TP_ID},
    ID        => $attr->{ID},
    PAGE_ROWS => 10000,
    COLS_NAME => 1
  }) if $Cams->{TOTAL} < 1;

  foreach my $group (@$groups) {
    my $cameras = $Cams->streams_list({
      GROUP_ID         => $group->{group_id} || '_SHOW',
      FOLDER_ID        => $group->{folder_id} || '_SHOW',
      UID              => "0;$attr->{UID}",
      COLS_NAME        => 1,
      SHOW_ALL_COLUMNS => 1,
    });

    @access_cameras = (@access_cameras, @$cameras) if $Cams->{TOTAL};
  }

  return @access_cameras;
}

#**********************************************************
=head2 _cams_get_active_user_cameras($attr) - Get all active user cameras

  Arguments:
     $attr
       tp_id - tariff id
       id    - id in `cams_main` table (user subscribe)

  Results:
     list of active cameras

=cut
#**********************************************************
sub _cams_get_active_user_cameras {
  my ($attr) = @_;

  my @active_streams = ();
  my $current_user_cameras = $Cams->user_cameras_list({
    TP_ID     => $attr->{TP_ID},
    ID        => $attr->{ID},
    PAGE_ROWS => 10000,
    COLS_NAME => 1
  });

  foreach my $cameras (@$current_user_cameras) {
    push @active_streams, $cameras->{camera_id};
  }

  return @active_streams;
}

#**********************************************************
=head2 _cams_get_private_user_cameras($attr) - Get all private user cameras

  Arguments:
     $attr
       uid - user id

  Results:
     list of private cameras

=cut
#**********************************************************
sub _cams_get_private_user_cameras {
  my ($attr) = @_;

  my @access_cameras = ();

  my $groups = $Cams->user_folders_list({
    TP_ID     => $attr->{TP_ID},
    ID        => $attr->{ID},
    PAGE_ROWS => 10000,
    COLS_NAME => 1
  });

  $groups = $Cams->user_groups_list({
    TP_ID     => $attr->{TP_ID},
    ID        => $attr->{ID},
    PAGE_ROWS => 10000,
    COLS_NAME => 1
  }) if $Cams->{TOTAL} < 1;

  foreach my $group (@$groups) {
    my $cameras = $Cams->streams_list({
      GROUP_ID         => $group->{group_id} || '_SHOW',
      FOLDER_ID        => $group->{folder_id} || 0,
      UID              => $attr->{UID},
      COLS_NAME        => 1,
      SHOW_ALL_COLUMNS => 1,
    });

    @access_cameras = (@access_cameras, @$cameras) if $Cams->{TOTAL};
  }

  my $cameras = $Cams->streams_list({
    GROUP_ID         => 0,
    FOLDER_ID        => 0,
    UID              => $attr->{UID},
    COLS_NAME        => 1,
    SHOW_ALL_COLUMNS => 1,
  });

  @access_cameras = (@access_cameras, @$cameras) if $Cams->{TOTAL};

  return @access_cameras;
}

#**********************************************************
=head2 _cams_autofill_groups($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub _cams_autofill_groups {
  my ($attr) = @_;

  $Cams->{ID} ||= $Cams->{INSERT_ID} || $attr->{ID} || $attr->{INSERT_ID};
  return 0 if !$Cams->{ID};

  $user = $Users->pi({ UID => $FORM{UID} });
  return 0 if $Users->{TOTAL} < 1;

  my $user_address = $Address->address_info($user->{LOCATION_ID});
  my $user_access_groups = $Cams->access_group_list({
    NAME        => '_SHOW',
    STREET_ID   => $user_address->{STREET_ID} || 0,
    DISTRICT_ID => $user_address->{DISTRICT_ID} || 0,
    LOCATION_ID => $user->{LOCATION_ID} || 0,
    SERVICE_ID  => $FORM{SERVICE_ID} || $Cams->{SERVICE_ID},
    COMMENT     => '_SHOW',
    COLS_NAME   => 1,
  });

  $FORM{GROUP_IDS} = join(', ', map $_->{id}, @{$user_access_groups});
  $FORM{ID} = $Cams->{ID};

  $Cams->user_groups({
    IDS   => $FORM{GROUP_IDS},
    TP_ID => $FORM{TP_ID} || $Cams->{TP_ID},
    ID    => $Cams->{ID},
  });

  return 0;
}

#**********************************************************
=head2 _cams_autofill_folders($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub _cams_autofill_folders {
  my ($attr) = @_;

  $Cams->{ID} ||= $Cams->{INSERT_ID} || $attr->{ID} || $attr->{INSERT_ID};
  return 0 if !$Cams->{ID};

  $user = $Users->pi({ UID => $FORM{UID} });
  return 0 if $Users->{TOTAL} < 1;

  my $user_address = $Address->address_info($user->{LOCATION_ID});
  my $user_access_folders = $Cams->access_folder_list({
    NAME        => '_SHOW',
    STREET_ID   => $user_address->{STREET_ID} || 0,
    DISTRICT_ID => $user_address->{DISTRICT_ID} || 0,
    LOCATION_ID => $user->{LOCATION_ID} || 0,
    SERVICE_ID  => $FORM{SERVICE_ID} || $Cams->{SERVICE_ID},
    COMMENT     => '_SHOW',
    UID         => $FORM{UID},
    COLS_NAME   => 1,
  });

  $FORM{FOLDER_IDS} = join(', ', map $_->{id}, @{$user_access_folders});
  $FORM{ID} = $Cams->{ID};

  $Cams->user_folders({
    IDS   => $FORM{FOLDER_IDS},
    TP_ID => $FORM{TP_ID} || $Cams->{TP_ID},
    ID    => $Cams->{ID},
  });

  return 0;
}

1;