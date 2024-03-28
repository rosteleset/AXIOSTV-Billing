=head1 NAME

  Cams services

=cut

use strict;
use warnings FATAL => 'all';
use AXbills::Filters qw(_utf8_encode);
use AXbills::Base qw(_bp);
use Cams;

our (
  $html,
  %lang,
  $db,
  $admin,
  %conf,
  %FORM,
  $pages_qs,
  $index
);

my $Cams = Cams->new($db, $admin, \%conf);

#**********************************************************
=head2 cams_services($attr)

  Arguments:
    $attr

  Results:

=cut
#**********************************************************
sub cams_services {

  $Cams->{ACTION} = 'add';
  $Cams->{LNG_ACTION} = $lang{ADD};

  if ($FORM{extra_params}) {
    _service_extra_params();
    return 1;
  }
  elsif ($FORM{add}) {
    $Cams->services_add({ %FORM });
    if (!$Cams->{errno}) {
      $html->message('info', $lang{SCREENS}, $lang{ADDED});
      cams_service_info($Cams->{INSERT_ID});
    }
  }
  elsif ($FORM{change}) {
    $Cams->services_change(\%FORM);
    if (!_error_show($Cams)) {
      $html->message('info', $lang{SCREENS}, $lang{CHANGED});
      cams_service_info($FORM{ID});
    }
  }
  elsif ($FORM{chg}) {
    cams_service_info($FORM{chg});
  }
  elsif ($FORM{del} && $FORM{COMMENTS}) {
    $Cams->services_del($FORM{del});
    $html->message('info', $lang{SCREENS}, $lang{DELETED}) if (!$Cams->{errno});
  }
  _error_show($Cams);

  $Cams->{USER_PORTAL_SEL} = $html->form_select('USER_PORTAL', {
    SELECTED => $Cams->{USER_PORTAL} || $FORM{USER_PORTAL} || 0,
    SEL_HASH => {
      0 => '--',
      1 => $lang{INFO},
      2 => $lang{CONTROL} || 'Control'
    },
    NO_ID    => 1
  });

  $Cams->{DEBUG_SEL} = $html->form_select('DEBUG', {
    SELECTED  => $Cams->{DEBUG} || $FORM{DEBUG} || 0,
    SEL_ARRAY => [ 0, 1, 2, 3, 4, 5, 6, 7 ],
  });

  $html->tpl_show(_include('cams_services_add', 'Cams'), { %FORM, %$Cams });

  result_former({
    INPUT_DATA        => $Cams,
    FUNCTION          => 'services_list',
    DEFAULT_FIELDS    => 'NAME,MODULE,STATUS,COMMENT,LOGIN',
    FUNCTION_FIELDS   => 'change,del',
    EXT_TITLES        => {
      name    => $lang{NAME},
      module  => 'Plug-in',
      status  => $lang{STATUS},
      comment => $lang{COMMENTS},
    },
    SKIP_USERS_FIELDS => 1,
    TABLE             => {
      width   => '100%',
      caption => "$lang{CAMERAS} $lang{SERVICES}",
      qs      => $pages_qs,
      ID      => 'CAMS SERVICES',
      MENU    => "$lang{ADD}:index=" . get_function_index('cams_services') . "&add_form=1:add"
    },
    MAKE_ROWS         => 1,
    TOTAL             => 1,
  });

  return 1;
}

#**********************************************************
=head2 cams_service_info($id)

  Arguments:
    $id

  Results:

=cut
#**********************************************************
sub cams_service_info {
  my ($id, $attr) = @_;

  $Cams->services_info($id);

  $Cams->{USER_PORTAL} = ($Cams->{USER_PORTAL}) ? $Cams->{USER_PORTAL} : '';
  $Cams->{STATUS} = ($Cams->{STATUS}) ? 'checked' : '';

  return 1 if $Cams->{errno};

  $FORM{add_form} = 1;
  $Cams->{ACTION} = 'change';
  $Cams->{LNG_ACTION} = $lang{CHANGE};
  $html->message('info', $lang{SCREENS}, $lang{CHANGING});

  return 1 if !$Cams->{MODULE};

  my $Cams_service = cams_load_service($Cams->{MODULE}, { SERVICE_ID => $Cams->{ID}, SOFT_EXCEPTION => 1 });
  $Cams->{MODULE_VERSION} = $Cams_service->{VERSION} if ($Cams_service && $Cams_service->{VERSION});

  _cams_service_test($Cams_service);
  _cams_service_import_models($Cams_service);
  _cams_service_import_cameras($Cams_service, $Cams->{ID});

  return 1;
}

#**********************************************************
=head2 _cams_service_test($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub _cams_service_test {
  my $Cams_service = shift;

  return 1 if (!$Cams_service || !$Cams_service->can('test'));

  $Cams->{SERVICE_TEST} = $html->button($lang{TEST}, "index=$index&test=1&chg=$Cams->{ID}",
    { class => 'btn btn-default btn-info' });

  return 0 if !$FORM{test};

  my $result = $Cams_service->test();
  if (!$Cams_service->{errno}) {
    $html->message('info', $lang{INFO}, "$lang{TEST}\n$result");
  }
  else {
    _error_show($Cams_service, { MESSAGE => 'Test:' });
  }

  return 0;
}

#**********************************************************
=head2 _cams_service_import_models($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub _cams_service_import_models {
  my $Cams_service = shift;

  return 1 if (!$Cams_service || !$Cams_service->can('import_models') || !in_array('Equipment', \@MODULES));

  if ($FORM{import_models}) {
    my $result = $Cams_service->import_models();
    if (!$Cams_service->{errno}) {
      if (!_cams_import_vendors($result)) {
        $html->message('info', $lang{INFO}, $lang{CAMS_IMPORT_SUCCESSFULLY});
      }
      else {
        $html->message('err', $lang{ERROR}, $lang{CAMS_IMPORT_ERROR});
      }
    }
    else {
      _error_show($Cams_service, { MESSAGE => 'IMPORT MODELS:' });
    }
  }

  $Cams->{IMPORT_MODELS} = $html->button($lang{CAMS_IMPORT_MODELS}, "index=$index&import_models=1&chg=$Cams->{ID}",
    { class => 'btn btn-success' });

  return;
}

#**********************************************************
=head2 _cams_import_vendors($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub _cams_import_vendors {
  my $vendors = shift;

  return 1 if !$vendors || ref $vendors ne 'HASH';

  require Equipment;
  Equipment->import();
  my $Equipment = Equipment->new($db, $admin, \%conf);

  my $cams_type = $Equipment->type_list({ NAME => 'Cams', COLS_NAME => 1 });
  return 1 if $Equipment->{TOTAL} < 1 || !$cams_type->[0]{id};

  my $vendor_id = 0;
  foreach my $key (keys %{$vendors}) {
    next if (!$vendors->{$key} || ref $vendors->{$key} ne 'ARRAY');

    $Equipment->vendor_add({ NAME => $key });
    $vendor_id = $Equipment->{INSERT_ID};

    if ($Equipment->{errno} && $Equipment->{errno} eq '7') {
      my $vendors = $Equipment->vendor_list({ NAME => $key, COLS_NAME => 1 });
      next if ($Equipment->{TOTAL} < 1);

      $vendor_id = $vendors->[0]{id};
    }

    next if !$vendor_id;

    map $Equipment->model_add({
      VENDOR_ID  => $vendor_id,
      TYPE_ID    => $cams_type->[0]{id},
      MODEL_NAME => $_
    }), @{$vendors->{$key}};
  }

  return 0;
}

#**********************************************************
=head2 _cams_service_import_cameras($attr)

=cut
#**********************************************************
sub _cams_service_import_cameras {
  my $Cams_service = shift;
  my $service_id = shift;

  return 1 if (!$Cams_service || !$Cams_service->can('import_cameras'));

  if ($FORM{import_cameras}) {
    my $cameras = $Cams_service->import_cameras($service_id);
    _cams_cameras_import_form($cameras);
  }
  elsif ($FORM{make_cameras_import} && $FORM{IDS}) {
    my $cameras = $Cams_service->import_cameras($service_id);
    my @ids = split(',\s?', $FORM{IDS});
    my @added_cameras = ();
    
    foreach my $id (@ids) {
      my $camera = $cameras->{$id};
      next if !$camera;

      my $group = $Cams->group_list({ SUBGROUP_ID => $camera->{organization_id}, ID => '_SHOW', COLS_NAME => 1 });
      my $group_id = 0;
      if ($Cams->{TOTAL} < 1) {
        next if (!$Cams_service->can('group_info'));

        my $new_group = $Cams_service->group_info({ SUBGROUP_ID => $camera->{organization_id} });
        next if !$new_group->{id};

        $Cams->group_add({
          NAME        => $new_group->{title},
          MAX_USERS   => $new_group->{user_limit},
          MAX_CAMERAS => $new_group->{camera_limit},
          SUBGROUP_ID => $camera->{organization_id},
          SERVICE_ID  => $camera->{service_id}
        });
        next if !$Cams->{INSERT_ID};

        $group_id = $camera->{organization_id};
      }
      else {
        $group_id = $group->[0]{id};
      }

      my $folder_id = $camera->{folder_id} ? _cams_import_folder($Cams_service, {
        FOLDER_ID       => $camera->{folder_id},
        SERVICE_ID      => $service_id,
        ORGANIZATION_ID => $camera->{organization_id},
        GROUP_ID        => $group_id
      }) : 0;

      next if !$folder_id && !$group_id;

      $Cams->stream_add({
        NAME        => $camera->{name},
        TITLE       => $camera->{title},
        HOST        => $camera->{host},
        RTSP_PORT   => $camera->{port},
        RTSP_PATH   => $camera->{path},
        LOGIN       => $camera->{login},
        PASSWORD    => $camera->{password},
        ORIENTATION => 1,
        TYPE        => 1,
        FOLDER_ID   => $folder_id,
        GROUP_ID    => !$folder_id ? $group_id : 0
      });
      next if !$Cams->{INSERT_ID};

      push(@added_cameras, {
        ID    => $Cams->{INSERT_ID},
        NAME  => $camera->{name},
        TITLE => $camera->{title},
        HOST  => $camera->{host},
        PORT  => $camera->{port},
      });
    }

    my $number_of_cameras = @added_cameras;

    if ($number_of_cameras > 0) {
      my $table = $html->table({
        width       => '100%',
        caption     => $lang{ADDED} . ': ' . $lang{CAMERAS},
        title_plain => [ '#', $lang{NAME}, $lang{CAM_TITLE}, 'Host', $lang{PORT} ],
        ID          => 'CAMS_CAMERAS',
        EXPORT      => 1
      });

      foreach my $camera (@added_cameras) {
        $table->addrow(
          $camera->{ID},
          $camera->{NAME},
          $camera->{TITLE},
          $camera->{HOST},
          $camera->{PORT},
          $html->button('', "index=" . get_function_index('cams_main') . "&chg_cam=$camera->{ID}", { class => 'change' })
        );
      }

      print $table->show();
    }
  }
  
  $Cams->{IMPORT_CAMERAS} = $html->button('Импорт камер', "index=$index&import_cameras=1&chg=$Cams->{ID}",
    { class => 'btn btn-success' });
  
  return;
}

#**********************************************************
=head2 _cams_import_folder()

=cut
#**********************************************************
sub _cams_import_folder {
  my $Cams_service = shift;
  my ($attr) = @_;

  return 0 if !$attr->{FOLDER_ID} || !$attr->{SERVICE_ID};

  my $folder = $Cams->folder_list({
    SUBFOLDER_ID => $attr->{FOLDER_ID},
    SERVICE_ID   => $attr->{SERVICE_ID},
    ID           => '_SHOW',
    COLS_NAME    => 1
  });
  return $folder->[0]{id} if $Cams->{TOTAL} > 0;

  return 0 if (!$Cams_service || !$Cams_service->can('folder_info'));
  my $folder_in_service = $Cams_service->folder_info({ SUBFOLDER_ID => $attr->{FOLDER_ID}, SUBGROUP_ID => $attr->{ORGANIZATION_ID} });

  return 0 if !$folder_in_service->{id};

  my $parent_id = 0;
  if ($folder_in_service->{parent_id}) {
    $parent_id = _cams_import_folder($Cams_service, { %{$attr}, FOLDER_ID  => $folder_in_service->{parent_id} });
  }

  $Cams->folder_add({
    PARENT_ID    => $parent_id,
    TITLE        => $folder_in_service->{title} || '',
    GROUP_ID     => $attr->{GROUP_ID} || 0,
    SERVICE_ID   => $attr->{SERVICE_ID},
    SUBFOLDER_ID => $folder_in_service->{id}
  });

  return $Cams->{INSERT_ID} || 0;
}

#**********************************************************
=head2 _cams_cameras_import_form($cameras)

=cut
#**********************************************************
sub _cams_cameras_import_form {
  my ($cameras) = @_;

  my $table = $html->table({
    width       => '100%',
    caption     => $lang{CAMERAS},
    title_plain => [ '#', $lang{NAME}, $lang{CAM_TITLE}, 'Host', $lang{PORT} ],
    ID          => 'CAMS_IMPORT_CAMERAS',
    EXPORT      => 1
  });

  foreach my $key (keys %{$cameras}) {
    my $camera = $cameras->{$key};
    $table->addrow(
      $html->form_input('IDS', $camera->{name}, { TYPE => 'checkbox' }),
      $camera->{name},
      $camera->{title},
      $camera->{host},
      $camera->{port}
    );
  }

  print $html->form_main({
    CONTENT => $table->show({ OUTPUT2RETURN => 1 }),
    HIDDEN  => {
      index               => $index,
      make_cameras_import => 2,
      chg                 => $Cams->{ID},
    },
    METHOD  => 'get',
    SUBMIT  => { import => $lang{IMPORT} }
  });

  return 1;
}

#**********************************************************
=head2 cams_load_service($service_name, $attr) - Load service module

  Argumnets:
    $service_name  - service modules name
    $attr
       SERVICE_ID
       SOFT_EXCEPTION

  Returns:
    Module object

=cut
#**********************************************************
sub cams_load_service {
  my ($service_name, $attr) = @_;
  my $api_object;

  my $Cams_service = Cams->new($db, $admin, \%conf);
  if ($attr->{SERVICE_ID}) {
    $Cams_service->services_info($attr->{SERVICE_ID});
    $service_name = $Cams_service->{TOTAL} && $Cams_service->{TOTAL} > 0 ? $Cams_service->{MODULE} : '';
  }

  return $api_object  if (!$service_name);

  return if $service_name !~ /^[\w.]+$/;
  $service_name = 'Cams::' . $service_name;

  eval " require $service_name; ";
  if (!$@) {
    $service_name->import();

    if ($service_name->can('new')) {
      $Cams_service->{DEBUG} = 0 if $Cams_service->{DEBUG} < 4 && $admin->{AID} eq '3';
      $api_object = $service_name->new($Cams->{db}, $Cams->{admin}, $Cams->{conf}, { %{$Cams_service}, HTML => $html, LANG => \%lang });
    }
    else {
      $html->message('err', $lang{ERROR}, "Can't load '$service_name'. Purchase this module https://billing.axiostv.ru");
      return $api_object;
    }
  }
  else {
    print $@ if ($FORM{DEBUG});
    $html->message('err', $lang{ERROR}, "Can't load '$service_name'. Purchase this module https://billing.axiostv.ru");
    die "Can't load '$service_name'. Purchase this module https://billing.axiostv.ru" if (!$attr->{SOFT_EXCEPTION});
  }

  return $api_object;
}

#**********************************************************
=head2 cams_services_sel($attr)

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
sub cams_services_sel {
  my ($attr) = @_;

  my %params = ();

  $params{SEL_OPTIONS} = { '' => $lang{ALL} } if ($attr->{ALL} || $FORM{search_form});
  $params{SEL_OPTIONS}->{0} = '--' if ($attr->{UNKNOWN});

  my $active_service = $attr->{SERVICE_ID} || $FORM{SERVICE_ID};

  my $service_list = $Cams->services_list({
    STATUS      => 0,
    NAME        => '_SHOW',
    USER_PORTAL => $attr->{USER_PORTAL},
    COLS_NAME   => 1,
    PAGE_ROWS   => 1
  });

  if ($attr->{HASH_RESULT}) {
    my %service_name = ();

    foreach my $line (@$service_list) {
      $service_name{$line->{id}} = $line->{name};
    }

    return \%service_name;
  }

  my $result = $html->form_select('SERVICE_ID', {
    SELECTED       => $active_service,
    SEL_LIST       => $service_list,
    EX_PARAMS      => "onchange='autoReload()'",
    MAIN_MENU      => get_function_index('cams_services'),
    MAIN_MENU_ARGV => ($active_service) ? "chg=$active_service" : q{},
    %params
  });

  if (!$active_service && $service_list->[0] && !$FORM{search_form} && !$attr->{SKIP_DEF_SERVICE}) {
    $FORM{SERVICE_ID} = $service_list->[0]->{id};
  }

  $result = $html->tpl_show(templates('form_row'), {
    ID    => 'SERVICE_ID',
    NAME  => $lang{SERVICE},
    VALUE => $result
  }, { OUTPUT2RETURN => 1 }) if $attr->{FORM_ROW};

  return $result;
}

#**********************************************************
=head2 cams_tariffs_sel($attr)

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
sub cams_tariffs_sel {
  my ($attr, $ext_params) = @_;

  my %params = ();
  $params{SEL_OPTIONS} = { '' => $lang{ALL} } if ($attr->{ALL} || $FORM{search_form});
  $params{SEL_OPTIONS}->{0} = $lang{UNKNOWN} if ($attr->{UNKNOWN});

  my $active_tariff = $attr->{TP_ID} || $FORM{TP_ID};

  my $tariffs = $Cams->_list({
    ID           => '_SHOW',
    TP_ID        => '_SHOW',
    TP_NAME      => '_SHOW',
    SERVICE_NAME => '_SHOW',
    TARIFF_ID    => '_SHOW',
    UID          => $attr->{UID},
    STATUS       => 0,
    SERVICE_ID   => '_SHOW',
    COLS_NAME    => 1,
    PAGE_ROWS    => 1,
    ref($ext_params) eq 'HASH' ? %{$ext_params} : ()
  });

  if ($attr->{HASH_RESULT}) {
    my %tariff_name = ();

    foreach my $line (@$tariffs) {
      $tariff_name{$line->{id}} = $line->{name};
    }

    return \%tariff_name;
  }

  if ($Cams->{TOTAL} && $Cams->{TOTAL} == 1) {
    delete $params{SEL_OPTIONS};
    $Cams->{TP_ID} = $tariffs->[0]->{id};
  }

  my $result = $html->form_select('TP_ID', {
    SELECTED       => $active_tariff,
    SEL_LIST       => $tariffs,
    EX_PARAMS      => "onchange='autoReload()'",
    SEL_VALUE      => 'service_name,tp_name',
    SEL_KEY        => 'tariff_id',
    NO_ID          => 1,
    MAIN_MENU      => get_function_index("cams_tp"),
    MAIN_MENU_ARGV => ($active_tariff) ? "chg=$active_tariff" : q{},
    %params
  });

  if (!$active_tariff && $tariffs->[0] && !$FORM{search_form} && !$attr->{SKIP_DEF_SERVICE}) {
    $FORM{SERVICE_ID} = $tariffs->[0]->{id};
  }

  return $result;
}

1;
