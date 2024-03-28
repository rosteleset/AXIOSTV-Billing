=head1 NAME

  Cams configure

=cut

use strict;
use warnings FATAL => 'all';
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
=head2 cams_tp()

=cut
#**********************************************************
sub cams_tp {

  require Control::Services;

  my %TEMPLATE_CAMS_TP = ();
  my $show_add_form = $FORM{add_form} || 0;
  my %payment_types = (0 => $lang{PREPAID}, 1 => $lang{POSTPAID});

  if ($FORM{add}) {
    $Cams->tp_add({ %FORM });
    $show_add_form = !show_result($Cams, $lang{ADDED});
  }
  elsif ($FORM{change}) {
    $FORM{PTZ} = 0 if !$FORM{PTZ};
    $FORM{DVR} = 0 if !$FORM{DVR};
    $FORM{TP_ID} = _cams_get_tp_id($FORM{ID});
    $Cams->tp_change({ %FORM }) if $FORM{TP_ID};
    show_result($Cams, $lang{CHANGED});
    $show_add_form = 1;
  }
  elsif ($FORM{chg}) {
    my $tp_info = $Cams->tp_info($FORM{chg});
    if (!_error_show($Cams)) {
      %TEMPLATE_CAMS_TP = %{$tp_info ? $tp_info : {}};
      $show_add_form = 1;
    }
    $TEMPLATE_CAMS_TP{PTZ} = 'checked' if $TEMPLATE_CAMS_TP{PTZ};
    $TEMPLATE_CAMS_TP{DVR} = 'checked' if $TEMPLATE_CAMS_TP{DVR};
    $TEMPLATE_CAMS_TP{PERIOD_ALIGNMENT} = 'checked' if $TEMPLATE_CAMS_TP{PERIOD_ALIGNMENT};
  }
  elsif ($FORM{del}) {
    $FORM{TP_ID} = _cams_get_tp_id($FORM{del});
    $Cams->tp_del({ TP_ID => $FORM{TP_ID} }) if $FORM{TP_ID};
    show_result($Cams, $lang{DELETED});
  }

  my $service_select = $html->form_select('SERVICE_ID', {
    SELECTED  => $TEMPLATE_CAMS_TP{SERVICE_ID} || q{},
    SEL_LIST  => $Cams->services_list({
      NAME      => '_SHOW',
      COLS_NAME => 1
    }),
    SEL_NAME  => 'name',
    SEL_KEY   => 'id',
    NO_ID     => 1,
    EX_PARAMS => 'required="required"',
  });

  if ($show_add_form) {
    $TEMPLATE_CAMS_TP{PAYMENT_TYPE_SEL} = $html->form_select('PAYMENT_TYPE', {
      SELECTED => $TEMPLATE_CAMS_TP{PAYMENT_TYPE},
      SEL_HASH => \%payment_types,
    });
    $TEMPLATE_CAMS_TP{NEXT_TARIF_PLAN_SEL} = sel_tp({
      MODULE          => 'Cams',
      SELECT          => 'NEXT_TARIF_PLAN',
      NEXT_TARIF_PLAN => $TEMPLATE_CAMS_TP{NEXT_TARIF_PLAN},
    });
    $TEMPLATE_CAMS_TP{ARCHIVE_SELECT} = _cams_archive_select({ SELECTED => $TEMPLATE_CAMS_TP{ARCHIVE} });

    $html->tpl_show(_include('cams_tp', 'Cams'), {
      %TEMPLATE_CAMS_TP,
      SERVICE_TP        => $service_select,
      SUBMIT_BTN_ACTION => ($FORM{chg}) ? 'change' : 'add',
      SUBMIT_BTN_NAME   => ($FORM{chg}) ? $lang{CHANGE} : $lang{ADD},
    });
  }

  result_former({
    INPUT_DATA      => $Cams,
    FUNCTION        => 'tp_list',
    BASE_FIELDS     => 0,
    DEFAULT_FIELDS  => 'NAME,SERVICE_NAME,COMMENTS,STREAMS_COUNT,MONTH_FEE,PAYMENT_TYPE,ACTIV_PRICE,CHANGE_PRICE',
    HIDDEN_FIELDS   => 'ID,TP_ID,SERVICE_ID',
    FUNCTION_FIELDS => 'change,del',
    EXT_TITLES      => {
      name           => $lang{TARIF_PLAN},
      service_name   => $lang{SERVICE},
      comments       => $lang{COMMENTS},
      streams_count  => $lang{MAX} . " " . $lang{STREAMS_COUNT},
      payment_type   => $lang{PAYMENT_TYPE},
      month_fee      => $lang{MONTH_FEE},
      month_fee      => $lang{MONTH_FEE},
      activate_price => $lang{ACTIVATE},
      change_price   => $lang{CHANGE},
    },
    FILTER_COLS     => { payment_type => '_cams_show_payment_type' },
    TABLE           => {
      width   => '100%',
      caption => "$lang{CAMERAS}: $lang{TARIF_PLANS}",
      qs      => $pages_qs,
      ID      => 'CAMS_TPS',
      MENU    => "$lang{ADD}:index=$index&add_form=1" . ':add',
    },
    MAKE_ROWS       => 1,
    TOTAL           => 1,
    MODULE          => 'Cams'
  });

  return 0;
}

#**********************************************************
=head2 _cams_show_payment_type()

=cut
#**********************************************************
sub _cams_show_payment_type {
  my ($type) = @_;

  return $type ? $lang{POSTPAID} : $lang{PREPAID};
}

#**********************************************************
=head2 _cams_get_tp_id()

=cut
#**********************************************************
sub _cams_get_tp_id {
  my ($id) = @_;

  my $tp_info = $Cams->tp_info($id);
  return $tp_info->{TP_ID} if !_error_show($Cams);

  return 0;
}

#**********************************************************
=head2 cams_folder()

=cut
#**********************************************************
sub cams_folder {

  my %TEMPLATE_CAMS_TP = ();
  my $errors = 0;

  $Cams->{db}{db}->{AutoCommit} = 0;
  $Cams->{db}->{TRANSACTION} = 1;

  my $service_id = 0;

  if ($FORM{add_folder}) {
    if (!$FORM{TITLE} && !$FORM{DISTRICT_ID} && !$FORM{STREET_ID} && !$FORM{BUILD_ID}) {
      $errors = 1;
      $html->message('err', $lang{ERROR}, $lang{ENTER_GROUP_NAME_OR_ADDRESS});
    }
    else {
      $FORM{TITLE} = $FORM{TITLE} ? $FORM{TITLE} : _cams_show_location('', \%FORM);
      if ($FORM{PARENT_ID}) {
        $Cams->folder_info($FORM{PARENT_ID});
        $service_id = $Cams->{SERVICE_ID} if ($Cams->{TOTAL});
        $FORM{GROUP_ID} = $Cams->{GROUP_ID} if ($Cams->{TOTAL});
      }

      my $group = $Cams->group_info($FORM{GROUP_ID});
      $FORM{SUBGROUP_ID} = $group->{SUBGROUP_ID} if $Cams->{TOTAL};
      $Cams->folder_add({ %FORM, SERVICE_ID => $FORM{SERVICE_ID} || $service_id });
      show_result($Cams, $lang{ADDED});
    }
  }
  elsif ($FORM{del}) {
    $Cams->folder_info($FORM{del});
    $service_id = $Cams->{SERVICE_ID} if ($Cams->{TOTAL});
    $FORM{SUBGROUP_ID} = $Cams->{SUBGROUP_ID};
    $FORM{SUBFOLDER_ID} = $Cams->{SUBFOLDER_ID};
    $Cams->folder_del($FORM{del});
    $FORM{del_folder} = $FORM{del};
    $FORM{ID} = $FORM{del};
    delete $FORM{del};
    show_result($Cams, $lang{DELETED});
  }
  elsif ($FORM{chg}) {
    my $folder = $Cams->folder_info($FORM{chg});
    $service_id = $Cams->{SERVICE_ID} if ($Cams->{TOTAL});
    delete $folder->{SERVICE_ID} if $folder->{PARENT_ID};

    %TEMPLATE_CAMS_TP = %{$folder} if $Cams->{TOTAL};
    $TEMPLATE_CAMS_TP{GROUP_ID_SELECTED} = $folder->{GROUP_ID};
    $FORM{chg_folder} = $FORM{chg};
    $FORM{PARENT_ID} = $folder->{PARENT_ID};
    delete $FORM{chg};
  }
  elsif ($FORM{change_folder}) {
    if (!$FORM{TITLE} && !$FORM{DISTRICT_ID} && !$FORM{STREET_ID} && !$FORM{BUILD_ID}) {
      $errors = 1;
      $html->message('err', $lang{ERROR}, $lang{ENTER_GROUP_NAME_OR_ADDRESS});
    }
    else {
      $FORM{TITLE} = $FORM{TITLE} ? $FORM{TITLE} : _cams_show_location('', \%FORM);
      $Cams->folder_info($FORM{ID});
      $service_id = $Cams->{SERVICE_ID} if ($Cams->{TOTAL});

      $Cams->folder_change({ %FORM });
      show_result($Cams, $lang{CHANGED});
    }
  }

  if ($FORM{ID} || $FORM{chg_folder} && !$service_id) {
    my $parent_folder = $Cams->folder_info($FORM{ID} || $FORM{chg_folder});
    if ($Cams->{TOTAL} && $parent_folder->{SERVICE_ID}) {
      $TEMPLATE_CAMS_TP{SERVICE_ID} = $parent_folder->{SERVICE_ID};
      $FORM{SERVICE_ID} = $parent_folder->{SERVICE_ID};
      $FORM{GROUP_ID} = $parent_folder->{GROUP_ID};
    }
  }

  $TEMPLATE_CAMS_TP{SERVICES_SELECT} = $html->form_select('SERVICE_ID', {
    SELECTED  => $service_id || $TEMPLATE_CAMS_TP{SERVICE_ID} || $FORM{SERVICE_ID} || q{},
    SEL_LIST  => $Cams->services_list({
      NAME      => "_SHOW",
      COLS_NAME => 1,
    }),
    SEL_VALUE => 'name',
    SEL_KEY   => 'id',
    NO_ID     => 1,
    EX_PARAMS => 'required="required" onchange="autoReload()"',
  });

  $TEMPLATE_CAMS_TP{GROUP_SELECT} = _cams_groups_select({
    SERVICE_ID   => $service_id || $TEMPLATE_CAMS_TP{SERVICE_ID} || $FORM{SERVICE_ID} || 0,
    ONLY_SERVICE => 1,
    SELECTED     => $FORM{PARENT_ID} ? $FORM{GROUP_ID} : 0
  });

  if (!$FORM{change_folder}) {
    $FORM{PARENT_ID} = $FORM{ID} ? $FORM{ID} : $FORM{PARENT_ID} ? $FORM{PARENT_ID} : 0;
  }

  $TEMPLATE_CAMS_TP{PARENT_ID} = $FORM{PARENT_ID};

  $service_id = $service_id || $TEMPLATE_CAMS_TP{SERVICE_ID} || $FORM{SERVICE_ID};

  if ($service_id && !$errors) {
    $FORM{SERVICE_ID} = $service_id;
    $FORM{INSERT_ID} = $Cams->{INSERT_ID} || 0;
    cams_user_services(\%FORM, \%TEMPLATE_CAMS_TP);
  }
  else {
    my DBI $db_ = $Cams->{db}{db};
    $db_->commit();
    $db_->{AutoCommit} = 1;
  }

  $TEMPLATE_CAMS_TP{ADDRESS} = form_address_select2({
    HIDE_FLAT             => 1,
    HIDE_ADD_BUILD_BUTTON => 1,
    LOCATION_ID           => $TEMPLATE_CAMS_TP{LOCATION_ID} || 0,
    DISTRICT_ID           => $TEMPLATE_CAMS_TP{DISTRICT_ID} || 0,
    STREET_ID             => $TEMPLATE_CAMS_TP{STREET_ID} || 0,
  });

  $html->tpl_show(_include('cams_folders', 'Cams'), {
    %TEMPLATE_CAMS_TP,
    BTN_ACTION => ($FORM{chg_folder}) ? 'change_folder' : 'add_folder',
    BTN_LNG    => ($FORM{chg_folder}) ? $lang{CHANGE} : $lang{ADD},
  });

  $LIST_PARAMS{PARENT_ID} = $FORM{PARENT_ID};

  result_former({
    INPUT_DATA      => $Cams,
    FUNCTION        => 'folder_list',
    BASE_FIELDS     => 0,
    DEFAULT_FIELDS  => 'ID,TITLE,SERVICE_NAME,PARENT_NAME,GROUP_NAME,COMMENT',
    HIDDEN_FIELDS   => 'PARENT_ID',
    FUNCTION_FIELDS => 'cams_folder:$lang{CHILDREN}:id:&PARENT_ID=1,change,del',
    SKIP_USER_TITLE => 1,
    EXT_TITLES      => {
      'id'           => '#',
      'title'        => $lang{NAME},
      'group_name'   => $lang{GROUP},
      'service_name' => $lang{SERVICE},
      'parent_name'  => $lang{PARENT},
      'comment'      => $lang{COMMENTS},
    },
    FILTER_COLS     => {
      parent_name => '_parent_link:PARENT_NAME',
    },
    TABLE           => {
      width   => '100%',
      caption => $lang{CAMERAS} . ": " . $lang{FOLDER},
      qs      => $pages_qs,
      ID      => 'CAMS_FOLDERS',
      header  => '',
      EXPORT  => 1,
      MENU    => "$lang{ADD}:index=$index&add_form=1" . ($FORM{PARENT_ID} ? "&PARENT_ID=$FORM{PARENT_ID}" : "") . ':add',
    },
    MAKE_ROWS       => 1,
    TOTAL           => 1
  });

  return 0;
}

#**********************************************************
=head2 cams_get_service_groups($attr)

  Arguments:

  Returns:

=cut
#**********************************************************
sub cams_get_service_groups {

  print _cams_groups_select({
    SELECTED     => $FORM{GROUP_ID} || 1,
    SERVICE_ID   => $FORM{SERVICE_ID},
    ONLY_SERVICE => 1
  });

  return 1;
}

#**********************************************************
=head2 _parent_link($attr)

  Arguments:

  Returns:

=cut
#**********************************************************
sub _parent_link {
  my ($attr) = @_;

  return $html->button($attr, "index=$index&chg=$FORM{PARENT_ID}") if ($FORM{PARENT_ID} && $attr);

  return $attr || '';
}

1;