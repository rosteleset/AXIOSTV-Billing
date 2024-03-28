=head1 NAME

  Cams User portal

=cut

use strict;
use warnings FATAL => 'all';
use AXbills::Base qw(in_array next_month convert _bp);

our (
  %lang,
  $Cams_service,
  $db,
  $admin,
  @service_status,
  $Cams,
  $users_
);


our AXbills::HTML $html;

$Cams = Cams->new($db, $admin, \%conf);
$users_ = Users->new($db, $admin, \%conf);

#**********************************************************
=head2 cams_user_info() - Cams user interface

=cut
#**********************************************************
sub cams_user_info {

  my %PORTAL_ACTIONS = ();
  my $service_list = $Cams->services_list({ USER_PORTAL => '>0', COLS_NAME => 1 });

  return 1 if (!$Cams->{TOTAL});

  foreach my $service (@$service_list) {
    $PORTAL_ACTIONS{$service->{id}} = $service->{user_portal};
  }

  $Cams->{ACTION} = 'add';
  $Cams->{LNG_ACTION} = $lang{ADD};

  $FORM{UID} = $user->{UID} ? $user->{UID} : "";
  $FORM{USER_INFO} = $user;
  my $user_groups = '';

  if ($FORM{add}) {
    if (!$FORM{SERVICE_ID}) {
      $html->message('err', $lang{ERROR}, $lang{CHOOSE_SERVICE});
      return 1;
    }

    $Cams->{db}{db}->{AutoCommit} = 0;
    $Cams->{db}->{TRANSACTION} = 1;
    $Cams->users_list({
      UID   => $FORM{UID} || "",
      TP_ID => $FORM{TP_ID} || 0,
    });

    if ($Cams->{TOTAL}) {
      $html->message('err', $lang{ERROR}, "This tariff already used");
      return 1;
    }

    $Cams->user_add({
      UID    => $FORM{UID} || "",
      TP_ID  => $FORM{TP_ID} || 0,
      STATUS => $FORM{STATUS} || 0
    });

    show_result($Cams, $lang{ADDED});
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

    _cams_autofill_groups($Cams) if ($conf{CAMS_CHECK_USER_GROUPS} && $Cams->{ID});
    _cams_autofill_folders($Cams) if ($conf{CAMS_CHECK_USER_FOLDERS});
  }
  elsif ($FORM{chg} || ($FORM{ID} && !$FORM{del})) {
    $Cams->{ACTION} = 'change';
    $Cams->{LNG_ACTION} = $lang{CHANGE};

    my $result = $Cams->_info($FORM{chg});

    if ($Cams->{TOTAL} > 0) {
      $FORM{SERVICE_ID} = $result->{SERVICE_ID};
      $Cams->{SERVICE_ID} = $result->{SERVICE_ID};
      $Cams->{TP_ID} = $result->{TP_ID};
      $Cams->{STATUS} = $result->{STATUS};
    }

    if (!$result->{SERVICE_ID} || !$PORTAL_ACTIONS{$result->{SERVICE_ID}}) {
      $html->message('info', $lang{INFO}, $lang{ERROR_VIEW_INFORMATION}, { ID => 804 });
      return 1; 
    }
  }
  elsif ($FORM{change}) {

  }
  elsif ($FORM{del} && $FORM{COMMENTS}) {
    my $result = $Cams->_list({
      TP_ID      => '_SHOW',
      SERVICE_ID => '_SHOW',
      ID         => $FORM{del},
      COLS_NAME  => 1,
      COLS_UPPER => 1,
    });

    if ($Cams->{TOTAL}) {
      $FORM{SERVICE_ID} = $result->[0]{SERVICE_ID};
      $FORM{TP_ID} = $result->[0]{TP_ID};
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

  $Cams_service = cams_user_services(\%FORM, $user, $Cams);

  if (!$Cams->{ID}) {
    $Cams->{TP_ADD} = $html->form_select('TP_ID', {
      SELECTED  => $FORM{TP_ID} || $Cams->{TP_ID} || '',
      SEL_LIST  => !$FORM{SERVICE_ID} && !$Cams->{SERVICE_ID} ? [] : $Cams->tp_list({
        TP_ID      => '_SHOW',
        NAME       => '_SHOW',
        SERVICE_ID => $FORM{SERVICE_ID} || $Cams->{SERVICE_ID}
      }),
      SEL_KEY   => 'tp_id',
      SEL_VALUE => 'tp_id,name',
      EX_PARAMS => 'required="required"',
    });

    $Cams->{TP_DISPLAY_NONE} = "style='display:none'";
  }

  $FORM{SUBSCRIBE_FORM} = cams_services_sel({ %FORM, %$Cams, FORM_ROW => 1, UNKNOWN => 1, USER_PORTAL => '2' });

  $html->tpl_show(_include('cams_user_add_tp', 'Cams'), { %FORM, %$Cams, });

  if ($FORM{UID} && $FORM{chg}) {
    my $user_folders = cams_user_folders({ SERVICE_INFO => $Cams, UID => $FORM{UID}, SERVICE_ID => $Cams->{SERVICE_ID} });

    $user_groups .= defined($user_folders) ?
      $user_folders : cams_user_groups({ SERVICE_INFO => $Cams, UID => $FORM{UID}, SERVICE_ID => $Cams->{SERVICE_ID} });
  }

  $LIST_PARAMS{SERVICE_NAME} = "_SHOW";
  $LIST_PARAMS{PORTAL} = 1;

  result_former({
    INPUT_DATA      => $Cams,
    FUNCTION        => 'users_list',
    BASE_FIELDS     => 0,
    DEFAULT_FIELDS  => 'ID,TP_NAME,SERVICE_STATUS',
    HIDDEN_FIELDS   => 'LOGIN',
    FUNCTION_FIELDS => 'change',
    SKIP_USER_TITLE => 1,
    EXT_TITLES => {
      id             => "#",
      tp_name        => $lang{TARIF_PLAN},
      service_status => $lang{STATUS},
      service_name   => $lang{SERVICE},
    },
    STATUS_VALS     => sel_status({ HASH_RESULT => 1 }),
    TABLE           => {
      width   => '100%',
      caption => $lang{TARIF_PLANS},
      qs      => $pages_qs,
      ID      => 'CAMS_MAIN',
      header  => '',
      EXPORT  => 1,
      MENU    => "$lang{ADD}:index=$index&sid=$FORM{sid}&add_form=1" . ':add',
    },
    MAKE_ROWS       => 1,
    TOTAL           => 1
  });

  return 1;
}

#**********************************************************
=head2 cams_client_streams() - show user his cams

=cut
#**********************************************************
sub cams_clients_streams {

  my $services = $Cams->services_list({ USER_PORTAL => '>0', COLS_NAME => 1 });

  return 1 if (!$Cams->{TOTAL});

  my $uid = $user->{UID};
  return 0 unless ($uid);

  my @tp_array = ();

  my $user_tariffs = $Cams->_list({
    SERVICE_ID => '_SHOW',
    TP_ID      => '_SHOW',
    STATUS     => '_SHOW',
    ID         => '_SHOW',
    UID        => $uid,
    SERVICE_ID => join(';', map { $_->{id} } @{$services}),
    COLS_NAME  => 1,
  });

  foreach my $tariff (@$user_tariffs) {
    next if $tariff->{status};

    my $user_cams = $Cams->user_cameras_list({
      TP_ID     => $tariff->{tp_id},
      ID        => $tariff->{id},
      CAMERA_ID => $FORM{camera} || '_SHOW',
      PAGE_ROWS => 10000,
      COLS_NAME => 1
    });

    next if in_array($tariff->{id}, \@tp_array);

    my $prev_stream = 0;
    my $streams_html = "";
    foreach my $stream (@$user_cams) {
      if (($stream->{service_id} && $stream->{service_id} ne $prev_stream) || ($stream->{service_id} && !$Cams_service)) {
        $Cams_service = cams_load_service($stream->{service_name}, { SERVICE_ID => $stream->{service_id} });
      }

      $prev_stream = $stream->{service_id};

      if ($Cams_service && $Cams_service->can('get_stream')) {
        $users_->info($uid, { SHOW_PASSWORD => 1 });
        $users_->pi({ UID => $uid });
        my $result = $Cams_service->get_stream({ %$stream, %$users_, %FORM });

        if ($result && $result->{CAMERA}) {

          if ($FORM{camera}) {
            print $result->{CAMERA};
            return;
          }

          $streams_html .= $html->tpl_show(_include('cams_stream_div', 'Cams'), {
            CAMERA      => $result->{CAMERA} || '',
            STREAM_NAME => $stream->{title} || $stream->{camera_name},
          }, { OUTPUT2RETURN => 1 });
        }
      }
    }
    $html->tpl_show(_include('cams_streams_wrapper', 'Cams'), { CAMS => $streams_html, EXTRA_LINKS => $conf{CAMS_EXTRA_LINKS} || '' });

    push @tp_array, $tariff->{id};
  }
}

#**********************************************************
=head2 cams_user_streams_management() - manage user streams

=cut
#**********************************************************
  sub cams_user_streams_management {

  my $services = $Cams->services_list({ USER_PORTAL => '>1', COLS_NAME => 1 });

  return 1 if (!$Cams->{TOTAL});

  return cams_user_get_group_folders() if ($FORM{GET_FOLDER_SELECT});

  my %CAMS_STREAM = ();
  my $show_add_form = 0;
  my $correct_name = 1;
  my @access_cameras = ();
  my @active_streams = ();
  my @private_cameras = ();
  my $service_id = '';

  $FORM{UID} = $user->{UID} ? $user->{UID} : '';
  $FORM{USER_INFO} = $user;

  $html->tpl_show(_include('cams_choose_service', 'Cams'), {
    %CAMS_STREAM, %FORM,
    UID           => $user->{UID} || $FORM{UID},
    TARIFF_SELECT => cams_tariffs_sel({ UID => $FORM{UID} }, {
      SERVICE_ID => join(';', map { $_->{id} } @{$services})
    }),
  });

  if ($FORM{show_cameras} && !$FORM{TP_ID}) {
    $html->message('err', $lang{ERROR}, "$lang{CHOOSE} $lang{TARIF_PLAN}");
  }

  return 1 if (!$FORM{TP_ID});

  if (!$Cams_service) {
    my $result = '';
    if ($FORM{TP_ID}) {
      $result = $Cams->tp_info($FORM{TP_ID});
      if ($Cams->{TOTAL}) {
        $service_id = $result->{SERVICE_ID};
        $FORM{CAMS_TP_ID} = $result->{TP_ID};
      }
    }
  }

  if ($FORM{add_form}) {
    $show_add_form = 1;

    # Default params
    $CAMS_STREAM{RTSP_PORT} = '554';
    $CAMS_STREAM{LOGIN} = 'admin';
    $CAMS_STREAM{PASSWORD} = 'admin';
  }

  if ($FORM{add_cam}) {
    $correct_name = _cams_add_user_stream(\%FORM);
  }
  elsif ($FORM{change_cam}) {
    my $uid = $FORM{UID};

    $FORM{HOST} = _cams_correct_host($FORM{HOST}) if !$conf{CAMS_SKIP_CHECK_HOST};
    if ($FORM{NAME} =~ /^[aA-zZ\d_-]+$/mg && $FORM{HOST}) {
      $Cams->stream_change(\%FORM);
      if (!_error_show($Cams)) {
        show_result($Cams, $lang{CHANGED});
      }
      else {
        $correct_name = 0;
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
    $FORM{CAM_NAME} = $cams_info->{NAME} || '';
    $Cams->stream_del({ ID => $FORM{del_cam} });
    show_result($Cams, $lang{DELETED});
  }

  my $user_tps = $Cams->_list({
    SERVICE_ID       => '_SHOW',
    TP_ID            => $FORM{CAMS_TP_ID},
    STATUS           => '_SHOW',
    ID               => '_SHOW',
    TP_STREAMS_COUNT => '_SHOW',
    UID              => $FORM{UID},
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

  if ($service_id && $correct_name) {
    $FORM{SERVICE_ID} = $service_id;
    $Cams_service = cams_user_services(\%FORM);
  }

  if ($show_add_form) {
    $CAMS_STREAM{GROUPS_SELECT} = _cams_groups_select({
      TP_ID      => $FORM{CAMS_TP_ID},
      ID         => $user_tps->[0]{id},
      UID        => $FORM{UID},
      SERVICE_ID => $FORM{SERVICE_ID} || $Cams->{list}[0]{SERVICE_ID},
    });

    $CAMS_STREAM{FOLDERS_SELECT} = _cams_folders_select({
      TP_ID      => $FORM{CAMS_TP_ID},
      ID         => $user_tps->[0]{id},
      UID        => $FORM{UID},
      SERVICE_ID => $FORM{SERVICE_ID} || $Cams->{list}[0]{SERVICE_ID},
    });

    $CAMS_STREAM{ORIENTATION_SELECT} = _cams_orientation_select({ SELECTED => ($CAMS_STREAM{ORIENTATION} || 0) });
    $CAMS_STREAM{ARCHIVE_SELECT} = _cams_archive_select({ SELECTED => $CAMS_STREAM{ARCHIVE} });
    $CAMS_STREAM{TYPE_SELECT} = _cams_type_select({ SELECTED => ($CAMS_STREAM{TYPE} || 0) });
    $CAMS_STREAM{TRANS_SELECT} = _cams_transport_select({ SELECTED => ($CAMS_STREAM{TRANSPORT} || 0) });
    $CAMS_STREAM{SOUND_SELECT} = $html->form_select('SOUND', {
      SELECTED => $CAMS_STREAM{SOUND} || q{},
      SEL_LIST => [
        { id => 1, name => 'PCMA/PCMU' },
        { id => 2, name => 'AAC' },
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
      FUNCTION_INDEX     => get_function_index('cams_user_streams_management')
    });
  }

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
  my $table = $html->table({
    width   => '100%',
    caption => $lang{CAMERAS},
    title   => \@titles,
    ID      => 'CAMERAS_STREAMS_ID',
    MENU    => "$lang{ADD}:index=$index&add_form=1&SERVICE_ID=" . ($FORM{SERVICE_ID} || "") .
      "&UID=$FORM{UID}&TP_ID=$FORM{TP_ID}&CAMS_TP_ID=$FORM{CAMS_TP_ID}" . ':add',
  });

  foreach my $stream (@access_cameras) {
    my $select = $html->form_input('IDS', $stream->{id}, {
      TYPE          => 'checkbox',
      STATE         => (in_array($stream->{id}, \@active_streams) ? 1 : undef),
      OUTPUT2RETURN => 1
    });
    $table->addrow($select, $stream->{name}, $stream->{title}, $stream->{host}, $stream->{login},
      ($stream->{disabled} eq '1') ? $lang{YES} : $lang{NO}, '', '');
  }

  foreach my $stream (@private_cameras) {
    my $select = $html->form_input('IDS', $stream->{id}, {
      TYPE          => 'checkbox',
      STATE         => (in_array($stream->{id}, \@active_streams) ? 1 : undef),
      OUTPUT2RETURN => 1
    });
    my $change_button = $html->button($lang{CHANGE}, "index=$index&chg_cam=$stream->{id}&" . ($FORM{SERVICE_ID} || "") .
      "&UID=$FORM{UID}" . "&TP_ID=$FORM{TP_ID}&CAMS_TP_ID=$FORM{CAMS_TP_ID}", { class => 'change' });
    my $del_button = $html->button($lang{DEL}, "index=$index&del_cam=$stream->{id}&" . ($FORM{SERVICE_ID} || "") .
      "&UID=$FORM{UID}" . "&TP_ID=$FORM{TP_ID}&CAMS_TP_ID=$FORM{CAMS_TP_ID}", { MESSAGE => "$lang{DEL} $stream->{id}?", class => 'del' });
    $table->addrow($select, $stream->{name}, $stream->{title}, $stream->{host}, $stream->{login},
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
=head2 cams_archives()

=cut
#**********************************************************
sub cams_archives {
  my %CAMS_STREAM = ();

  my $services = $Cams->services_list({ USER_PORTAL => '>0', COLS_NAME => 1 });
  return 1 if (!$Cams->{TOTAL});

  $FORM{UID} = $user->{UID} ? $user->{UID} : "";
  $FORM{USER_INFO} = $user;

  $FORM{DATE_SELECT} = $html->form_daterangepicker({
    NAME      => 'date',
    VALUE     => $FORM{date} || "today",
    WITH_TIME => 1,
  });

  my $user_tps = $Cams->_list({
    SHOW_ALL_COLUMNS => '_SHOW',
    UID              => $FORM{UID},
    SERVICE_ID       => join(';', map {$_->{id}} @{$services}),
    COLS_NAME        => 1,
  });

  my @user_cameras = ();

  foreach my $tp (@{$user_tps}) {
    my $cameras = $Cams->user_cameras_list({
      TP_ID     => $tp->{tp_id},
      ID        => $tp->{id},
      COLS_NAME => 1
    });

    @user_cameras = (@user_cameras, @{$cameras}) if $Cams->{TOTAL};
  }

  $FORM{CAMS_SELECT} = $html->form_select('CAMERA_ID', {
    SELECTED  => $FORM{CAMERA_ID} || 0,
    SEL_LIST  => \@user_cameras,
    SEL_VALUE => 'service_name,title',
    SEL_KEY   => 'camera_id',
    NO_ID     => 1,
  });

  $html->tpl_show(_include('cams_choose_camera_data', 'Cams'), {
    %CAMS_STREAM, %FORM,
    UID => $user->{UID} || $FORM{UID},
  });

  cams_show_camera_archive() if $FORM{CAMERA_ID};

  return 1;
}

#**********************************************************
=head2 cams_show_camera_archive()

=cut
#**********************************************************
sub cams_show_camera_archive {

  my $prev_stream = '';
  my $streams_html = '';

  my $camera = $Cams->stream_info($FORM{CAMERA_ID});
  $camera->{service_id} ||= $camera->{service_id_folder};

  if (($camera->{service_id} && $camera->{service_id} ne $prev_stream) || ($camera->{service_id} && !$Cams_service)) {
    $Cams_service = cams_load_service($camera->{service_name}, { SERVICE_ID => $camera->{service_id} });
  }

  $prev_stream = $camera->{service_id};

  return 0 if (!$Cams_service || !$Cams_service->can('get_archive'));

  $users_->info($FORM{UID}, { SHOW_PASSWORD => 1 });
  $users_->pi({ UID => $FORM{UID} });
  $camera->{DATE} = $FORM{date} if $FORM{date};

  my $result = $Cams_service->get_archive({ %$camera, %$users_ });

  return 0 if (!$result || !$result->{CAMERA});

  $result->{CAMERA} = ($result->{CAMERA}) if (ref $result->{CAMERA} ne 'ARRAY');

  for my $cam (@{$result->{CAMERA}}) {
    $streams_html .= $html->tpl_show(_include('cams_stream_div', 'Cams'), {
      CAMERA      => $cam || '',
      STREAM_NAME => $camera->{title} || $camera->{camera_name},
    }, { OUTPUT2RETURN => 1 });
  }

  $html->tpl_show(_include('cams_streams_wrapper', 'Cams'), {
    CAMS              => $streams_html,
    ADDITIONAL_SCRIPT => $result->{ADDITIONAL_SCRIPT} || ''
  });

  return 0;
}

#*******************************************************************
=head2 cams_user_get_group_folders()

=cut
#*******************************************************************
sub cams_user_get_group_folders {

  print $html->form_select('FOLDER_ID', {
    SELECTED  => $FORM{FOLDER_ID} || q{},
    SEL_LIST  => $Cams->folder_list({
      ID          => '_SHOW',
      PARENT_NAME => '_SHOW',
      GROUP_ID    => $FORM{GROUP_ID} || '0',
      COLS_NAME   => 1,
    }),
    SEL_VALUE => 'parent_name,title',
    SEL_KEY   => 'id',
    NO_ID     => 1
  });

  return 1;
}

1;