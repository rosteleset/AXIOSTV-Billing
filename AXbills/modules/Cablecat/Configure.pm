use strict;
use warnings FATAL => 'all';

use JSON qw/encode_json decode_json/;
use AXbills::Base qw/in_array urlencode urldecode _bp/;

our (
  $Cablecat, $Maps,
  $html, %lang, %conf, $admin, $db, %permissions,
  @CABLECAT_EXTRA_COLORS, @CABLECAT_COLORS,
  %MAP_TYPE_ID, %MAP_LAYER_ID,
  %CROSS_CROSS_TYPE, %CROSS_PANEL_TYPE, %CROSS_PORT_TYPE, %CROSS_POLISH_TYPE, %CROSS_FIBER_TYPE
);

my %STORAGE_TYPES = (
  CABLE    => 1,
  WELL     => 2,
  SPLITTER => 3
);

use Maps::Auxiliary;
my $Auxiliary = Maps::Auxiliary->new($db, $admin, \%conf, { HTML => $html, LANG => \%lang });

#**********************************************************
=head2 cablecat_cables()

=cut
#**********************************************************
sub cablecat_cables {
  my %TEMPLATE_ARGS = ();
  my $show_add_form = $FORM{add_form} || 0;

  if ($FORM{add_well}) {
    my $cables = $Cablecat->cables_list({
      ID                => $FORM{object_id} || $FORM{POINT_ID} || '!',
      NAME              => '_SHOW',
      POINT_ID          => '_SHOW',
      CABLE_TYPE        => '_SHOW',
      WELL_1            => '_SHOW',
      WELL_2            => '_SHOW',
      WELL_1_ID         => '_SHOW',
      WELL_2_ID         => '_SHOW',
      OUTER_COLOR       => '_SHOW',
      LINE_WIDTH        => '_SHOW',
      LENGTH            => '_SHOW',
      LENGTH_CALCULATED => '_SHOW',
      CAN_BE_SPLITTED   => '_SHOW',
      COMMENTS          => '_SHOW',
      PAGE_ROWS         => 10000
    });

    my $list = $Maps->polylines_list({
      ID         => '_SHOW',
      LAYER_ID   => $FORM{layer_id},
      OBJECT_ID  => $cables->[0]{point_id},
      COLS_NAME  => 1,
      COLS_UPPER => 0
    });

    my $points_list = $Maps->polyline_points_list({
      POLYLINE_ID => $list->[0]{id},
      COORDX      => '_SHOW',
      COORDY      => '_SHOW',
    });

    my $first_lat = $points_list->[0]{COORDX};
    my $first_lng = $points_list->[0]{COORDY};
    my $count = 0;
    my $sum = 1000;
    my $need_cable = 0;
    foreach my $element (@$points_list) {
      if ($first_lat ne $element->{COORDX} && $first_lng ne $element->{COORDY}) {
        my $x = ($FORM{lat} - $first_lat) / ($element->{COORDX} - $first_lat);
        my $y = ($FORM{lng} - $first_lng) / ($element->{COORDY} - $first_lng);

        if (abs($x - $y) < $sum) {
          $sum = abs($x - $y);
          $need_cable = $count;
        }
        $first_lng = $element->{COORDY};
        $first_lat = $element->{COORDX};
      }
      $count++;
    }

    $Maps->points_add({
      COORDX   => $FORM{lat},
      COORDY   => $FORM{lng},
      NAME     => $lang{WELL} . " $cables->[0]{name}",
      TYPE_ID  => 1,
      EXTERNAL => 1
    });
    $Cablecat->wells_add({
      NAME     => $lang{WELL} . " $cables->[0]{name}",,
      POINT_ID => $Maps->{INSERT_ID},
    });

    if (!_error_show($Cablecat)) {
      show_result($Cablecat, $lang{SUCCESS}, $lang{ADDED} . ' ' . $lang{WELL});
    }
    my ($old_cable, $cable_2_id, $cable_3_id) = @{$Cablecat->break_cable($FORM{object_id}, $Cablecat->{INSERT_ID})};

    my $old_links = $Cablecat->links_for_element_list('CABLE', $old_cable->{ID}, {
      ID             => '_SHOW',
      COMMUTATION_ID => '_SHOW',
      FIBER_NUM_1    => '_SHOW',
      FIBER_NUM_2    => '_SHOW',
      ELEMENT_1_SIDE => '_SHOW',
      ELEMENT_2_SIDE => '_SHOW',
      ATTENUATION    => '_SHOW',
      COMMENTS       => '_SHOW',
      PAGE_ROWS      => 10000
    });

    my $com_id = '';
    my $com_id2 = 0;
    my $connector_id = 0;

    $com_id = $old_links->[0]{commutation_id} if ($Cablecat->{TOTAL});

    foreach my $element (@$old_links) {
      if (($element->{element_1_id} == $old_cable->{ID}) && ($element->{commutation_id} == $com_id)) {
        $Cablecat->links_change({
          ID            => $element->{id},
          ELEMENT_1_ID  => $cable_2_id,
          _CHANGE_PARAM => 'ID',
        });
      }
      if (($element->{element_2_id} == $old_cable->{ID}) && ($element->{commutation_id} == $com_id)) {
        $Cablecat->links_change({
          ID            => $element->{id},
          ELEMENT_2_ID  => $cable_2_id,
          _CHANGE_PARAM => 'ID',
        });
      }

      if ($com_id != $element->{commutation_id}) {
        $com_id2 = $element->{commutation_id};
        $connector_id = $element->{commutation_id};
        if ($element->{element_1_id} == $old_cable->{ID}) {
          $Cablecat->links_change({
            ID            => $element->{id},
            ELEMENT_1_ID  => $cable_3_id,
            _CHANGE_PARAM => 'ID',
          });
        }
        if ($element->{element_2_id} == $old_cable->{ID}) {
          $Cablecat->links_change({
            ID            => $element->{id},
            ELEMENT_2_ID  => $cable_3_id,
            _CHANGE_PARAM => 'ID',
          });
        }
      }
    }
    my $cables_list = $Cablecat->commutation_cables_list({
      COMMUTATION_ID => $com_id,
      CABLE_ID       => $old_cable->{ID},
      CONNECTER_ID   => '_SHOW',
    });

    $Cablecat->commutation_cables_add({
      CABLE_ID       => $cable_2_id,
      CONNECTER_ID   => $cables_list->[0]{connecter_id},
      COMMUTATION_ID => $com_id,
    });

    if ($com_id2) {
      $cables_list = $Cablecat->commutation_cables_list({
        COMMUTATION_ID => $com_id2,
        CABLE_ID       => $old_cable->{ID},
        CONNECTER_ID   => '_SHOW',
      });

      $Cablecat->commutation_cables_add({
        CABLE_ID       => $cable_3_id,
        CONNECTER_ID   => $cables_list->[0]{connecter_id},
        COMMUTATION_ID => $com_id2,
      });
    }

    $cables = $Cablecat->cables_list({
      ID        => $cable_3_id,
      NAME      => '_SHOW',
      PAGE_ROWS => 10000
    });

    $Maps->polyline_points_change({
      ID     => $points_list->[$need_cable - 1]{ID},
      COORDX => $FORM{lat},
      COORDY => $FORM{lng},
    });

    $Maps->points_add({
      NAME     => $cables->[0]{name},
      TYPE_ID  => 7,
      EXTERNAL => 1
    });

    my $object_id = $Maps->{INSERT_ID};
    if ($Maps->{INSERT_ID}) {
      $Maps->polylines_add({
        OBJECT_ID => $Maps->{INSERT_ID},
        LAYER_ID  => 10
      });

      my $Pol_id = $Maps->{INSERT_ID};

      $cables = $Cablecat->cables_change({
        ID       => $cable_3_id,
        POINT_ID => $object_id,
      });
      foreach my $element (@$points_list) {
        if ($element->{ID} > $points_list->[$need_cable - 1]{ID}) {
          $Maps->polyline_points_del({
            ID => $element->{ID},
          });
          $Maps->polyline_points_add({
            COORDX      => $element->{COORDX},
            COORDY      => $element->{COORDY},
            POLYLINE_ID => $Pol_id,
          });
        }
      }
      $Maps->polyline_points_add({
        COORDX      => $points_list->[$need_cable - 1]{COORDX},
        COORDY      => $points_list->[$need_cable - 1]{COORDY},
        POLYLINE_ID => $Pol_id,
      });
      $Maps->polyline_points_add({
        COORDX      => $FORM{lat},
        COORDY      => $FORM{lng},
        POLYLINE_ID => $Pol_id,
      });
    }

    return 1;
  }

  my $sub_create_cable_point = sub {
    my $cable_id = shift;

    my $new_external_object_id = $Auxiliary->maps_add_external_object($MAP_TYPE_ID{CABLE}, \%FORM);
    $Cablecat->cables_change({ ID => $cable_id, POINT_ID => $new_external_object_id });
    _error_show($Cablecat);

    # Return
    $new_external_object_id;
  };

  if ($FORM{add}) {
    $FORM{NAME} =~ s/\\"//gm if $FORM{NAME};
    $FORM{NAME} ||= do {
      $lang{CABLE} . '_' . ($Cablecat->connecters_count() + 1);
    };
    my $new_cable_id = $Cablecat->cables_add({ %FORM });

    if (!_error_show($Cablecat)) {
      my $new_external_object_id = $sub_create_cable_point->($new_cable_id);

      if ($FORM{ADD_ON_NEW_MAP} && $FORM{coords} && $new_external_object_id) {
        $Maps->polylines_add({
          OBJECT_ID => $new_external_object_id,
          LAYER_ID  => 10,
          LENGTH    => $FORM{LENGTH_CALCULATED} || 0
        });

        my @points_array = split(/,/, $FORM{coords});

        my @points = ();
        foreach my $point (@points_array) {
          my ($coordx, $coordy) = split(':', $point);
          push @points, { COORDX => $coordx, COORDY => $coordy };
        }

        if ($Maps->{INSERT_ID}) {
          $Maps->polyline_points_add({
            POLYLINE_ID => $Maps->{INSERT_ID},
            POINTS      => \@points
          });
        }
      }
      if ($FORM{ARTICLE_ID}) {
        load_module('Storage', $html);
        storage_hardware({ ADD_ONLY => 1, WITHOUT_USER => 1 });
        $Cablecat->cablecat_storage_installation_add({
          OBJECT_ID       => $new_cable_id,
          INSTALLATION_ID => $FORM{INSTALLATION_ID},
          TYPE            => $STORAGE_TYPES{CABLE}
        }) if $FORM{INSTALLATION_ID};
      }

      my $preview_btn = $html->button($lang{OPEN}, "index=$index&chg=$new_cable_id", { BUTTON => 1 });
      my $add_more_button = $html->button($lang{VIEW}, "index=$index&add_form=1", { BUTTON => 1 });
      $html->message('info', "$lang{ADDED} $lang{CABLE}", $preview_btn . $add_more_button, {
        RESPONCE_PARAMS => {
          INSERT_ID => $new_external_object_id
        }
      });
    }
    else {
      $show_add_form = 1;
    };
  }
  elsif ($FORM{change}) {
    $FORM{NAME} =~ s/\\"//gm if $FORM{NAME};
    $Cablecat->cables_change({ %FORM });
    show_result($Cablecat, $lang{CHANGED});
  }
  elsif ($FORM{chg}) {
    $sub_create_cable_point->($FORM{chg}) if ($FORM{CREATE_OBJECT});

    my $tp_info = $Cablecat->cables_info($FORM{chg});
    if (!_error_show($Cablecat)) {
      %TEMPLATE_ARGS = %{$tp_info};
      $show_add_form = 1;
    }

    $TEMPLATE_ARGS{LENGTH_CALCULATED} = sprintf("%.2f", _cablecat_cable_length($FORM{chg})) if !$TEMPLATE_ARGS{LENGTH_CALCULATED};

    $TEMPLATE_ARGS{INSTALLATIONS_TABLE} = cablecat_storage_installations($FORM{chg}, $STORAGE_TYPES{CABLE});
    $TEMPLATE_ARGS{HIDE_STORAGE_FORM} = 'd-none';
  }
  elsif ($FORM{del}) {
    $Cablecat->delete_links_for_element('CABLE', $FORM{del});
    $Cablecat->cables_del({ ID => $FORM{del} });
    show_result($Cablecat, $lang{DELETED});
  }
  elsif ($FORM{search_form}) {
    $TEMPLATE_ARGS{WELL_1_SELECT} = _cablecat_wells_select({
      SELECTED => $FORM{WELL_1},
      NAME     => 'WELL_1',
      FILTERS  => { TYPE_ID => '!2' }
    });
    $TEMPLATE_ARGS{WELL_2_SELECT} = _cablecat_wells_select({
      SELECTED => $FORM{WELL_2},
      NAME     => 'WELL_2',
      FILTERS  => { TYPE_ID => '!2' }
    });

    $TEMPLATE_ARGS{CABLE_TYPE_SELECT} = _cablecat_cable_type_select({
      SELECTED => $FORM{TYPE_ID},
      NAME     => 'TYPE_ID',
    });

    form_search({
      SEARCH_FORM       => $html->tpl_show(_include('cablecat_cables_search', 'Cablecat'),
        { %TEMPLATE_ARGS, %FORM },
        { OUTPUT2RETURN => 1 }
      ),
      #      ADDRESS_FORM      => 1,
      PLAIN_SEARCH_FORM => 1
    });

  }

  return 1 if ($FORM{MESSAGE_ONLY});

  if ($show_add_form) {
    my $well_1_id = $FORM{WELL_1_ID} || $TEMPLATE_ARGS{WELL_1_ID};
    my $well_2_id = $FORM{WELL_2_ID} || $TEMPLATE_ARGS{WELL_2_ID};

    if ($FORM{first_coords} && $FORM{second_coords}) {
      my $first_well = _cablecat_get_closest_well({ COORDS => $FORM{first_coords} });
      my $second_well = _cablecat_get_closest_well({ COORDS => $FORM{second_coords} });

      $well_1_id = $first_well->{well_id} if $first_well;
      $well_2_id = $second_well->{well_id} if $second_well;
    }

    $TEMPLATE_ARGS{WELL_1_SELECT} = _cablecat_wells_select({
      SELECTED => $well_1_id,
      NAME     => 'WELL_1',
      FILTERS  => { TYPE_ID => '_SHOW' }
    });
    $TEMPLATE_ARGS{WELL_2_SELECT} = _cablecat_wells_select({
      SELECTED => $well_2_id,
      NAME     => 'WELL_2',
      FILTERS  => { TYPE_ID => '_SHOW' }
    });

    $TEMPLATE_ARGS{NAME} ||= do {
      my $res = '';

      if ($well_1_id) {
        my $well_info = $Cablecat->wells_info($well_1_id, { SHOW_ALL_COLUMNS => 0, NAME => '_SHOW' });
        $res .= $well_info->{NAME};
      }
      if ($well_2_id) {
        my $well_info = $Cablecat->wells_info($well_2_id, { SHOW_ALL_COLUMNS => 0, NAME => '_SHOW' });
        $res .= '-' . $well_info->{NAME};
      }

      if (!$res) {
        $res = $lang{CABLE} . '_' . ($Cablecat->cables_next());
      }
      $res;

    };

    $TEMPLATE_ARGS{OBJECT_INFO} = cablecat_make_point_info($TEMPLATE_ARGS{POINT_ID}, $MAP_LAYER_ID{CABLE});
    $TEMPLATE_ARGS{LENGTH_CALCULATED} = $FORM{LENGTH_CALCULATED} || '0.00';

    $html->tpl_show(_include('cablecat_cable', 'Cablecat'), {
      %TEMPLATE_ARGS,
      %{_cablecat_storage_installation_template() || {}},
      CABLE_TYPE_SELECT => _cablecat_cable_type_select({ SELECTED => $TEMPLATE_ARGS{TYPE_ID}, NAME => 'TYPE_ID', REQUIRED => 1 }),
      SUBMIT_BTN_ACTION => ($FORM{chg}) ? 'change' : 'add',
      SUBMIT_BTN_NAME   => ($FORM{chg}) ? $lang{CHANGE} : $lang{ADD},
    });
  }

  return 1 if ($FORM{TEMPLATE_ONLY});

  if ($TEMPLATE_ARGS{ID}) {
    print _cablecat_cable_links_table($TEMPLATE_ARGS{ID});
  }

  result_former({
    INPUT_DATA      => $Cablecat,
    FUNCTION        => 'cables_list',
    BASE_FIELDS     => 0,
    DEFAULT_FIELDS  => 'ID,NAME,CABLE_TYPE,COMMENTS,CREATED,POINT_ID',
    HIDDEN_FIELDS   => 'WELL_1_ID,WELL_2_ID,POLYLINE_ID',
    FUNCTION_FIELDS => 'change,del',
    SKIP_USER_TITLE => 1,
    EXT_FIELDS      => 0,
    EXT_TITLES      => {
      id                => '#',
      name              => $lang{NAME},
      cable_type        => $lang{CABLE_TYPE},
      comments          => $lang{COMMENTS},
      created           => $lang{CREATED},
      well_1            => "$lang{WELL} 1",
      well_2            => "$lang{WELL} 2",
      fibers_count      => $lang{FIBERS},
      modules_count     => $lang{MODULES},
      point_id          => $lang{MAP},
      length            => $lang{LENGTH},
      reserve           => $lang{RESERVE},
      length_calculated => "$lang{LENGTH} $lang{CALCULATED} ",
    },
    FILTER_VALUES   => {
      name => sub { $html->button(shift, 'get_index=cablecat_cables&full=1&chg=' . shift->{id}); },
    },
    FILTER_COLS     => {
      well_1   =>
        '_cablecat_result_former_named_chg_link_filter::PARAM_NAME=well_1_id,FUNCTION=cablecat_wells,WELL_1_ID',
      well_2   =>
        '_cablecat_result_former_named_chg_link_filter::PARAM_NAME=well_2_id,FUNCTION=cablecat_wells,WELL_2_ID',
      point_id => '_cablecat_result_former_cable_point_id_filter::POLYLINE_ID,POINT_ID'
    },
    TABLE           => {
      width   => '100%',
      caption => $lang{CABLES},
      ID      => 'CABLES_TABLE',
      EXPORT  => 1,
      MENU    => "$lang{ADD}:index=$index&add_form=1:add;$lang{SEARCH}:index=$index&search_form=1:search"
    },
    MODULE          => 'Cablecat',
    MAKE_ROWS       => 1,
    SEARCH_FORMER   => 1,
    TOTAL           => 1
  });

  return 1;
}

#**********************************************************
=head2 cablecat_cable_types()

=cut
#**********************************************************
sub cablecat_cable_types {
  my %TEMPLATE_TYPE = ();
  my $show_add_form = $FORM{add_form} || 0;

  if ($FORM{add}) {
    $Cablecat->cable_types_add({ %FORM });
    $show_add_form = !show_result($Cablecat, $lang{ADDED});
  }
  elsif ($FORM{change}) {
    $Cablecat->cable_types_change({ %FORM });
    show_result($Cablecat, $lang{CHANGED});

    # Return to chg with new values
    %TEMPLATE_TYPE = %FORM;
    $FORM{chg} = 1;

    $show_add_form = 1;
  }
  elsif ($FORM{chg}) {
    my $tp_info = $Cablecat->cable_types_info($FORM{chg});
    if (!_error_show($Cablecat)) {
      %TEMPLATE_TYPE = %{$tp_info};
      $show_add_form = 1;
    }
  }
  elsif ($FORM{del}) {
    $Cablecat->cable_types_del({ ID => $FORM{del} });
    show_result($Cablecat, $lang{DELETED});
  }

  if ($show_add_form) {
    my $fibers_colors_select = _cablecat_color_scheme_select({ SELECTED => $TEMPLATE_TYPE{COLOR_SCHEME_ID} });
    my $modules_colors_select = _cablecat_color_scheme_select(
      {
        SELECTED => $TEMPLATE_TYPE{MODULES_COLOR_SCHEME_ID},
        NAME     => 'MODULES_COLOR_SCHEME_ID',
      }
    );

    $TEMPLATE_TYPE{OUTER_COLOR} //= '#000000';

    $html->tpl_show(
      _include('cablecat_cable_type', 'Cablecat'),
      {
        %TEMPLATE_TYPE,
        COLOR_SCHEME_ID_SELECT         => $fibers_colors_select,
        MODULES_COLOR_SCHEME_ID_SELECT => $modules_colors_select,
        SUBMIT_BTN_ACTION              => ($FORM{chg}) ? 'change' : 'add',
        SUBMIT_BTN_NAME                => ($FORM{chg}) ? $lang{CHANGE} : $lang{ADD},
      }
    );
  }

  my AXbills::HTML $table;
  ($table) = result_former(
    {
      INPUT_DATA      => $Cablecat,
      FUNCTION        => 'cable_types_list',
      BASE_FIELDS     => 0,
      DEFAULT_FIELDS  => 'ID,NAME,COLOR_SCHEME,COMMENTS',
      FUNCTION_FIELDS => 'change,del',
      SKIP_USER_TITLE => 1,
      EXT_FIELDS      => 0,
      EXT_TITLES      => {
        id           => '#',
        name         => $lang{NAME},
        color_scheme => $lang{COLOR_SCHEME},
        comments     => $lang{COMMENTS},
      },
      #      FILTER_COLS => {
      #
      #        #        type_name => '_translate',
      #      },
      TABLE           => {
        width   => '100%',
        caption => $lang{CABLE_TYPES},
        ID      => 'CABLE_TYPES_TABLE',
        EXPORT  => 1,
        MENU    => "$lang{ADD}:index=$index&add_form=1:add"
      },
      MAKE_ROWS       => 1,
      SEARCH_FORMER   => 1,
      MODULE          => 'Cablecat',
    }
  );

  print $table->show();

  return 1;
}

#**********************************************************
=head2 cablecat_color_schemes()

=cut
#**********************************************************
sub cablecat_color_schemes {
  my %TEMPLATE_SCHEME = ();
  my $show_add_form = $FORM{add_form} || 0;

  if ($FORM{add}) {
    $Cablecat->color_schemes_add({ %FORM });
    $show_add_form = !show_result($Cablecat, $lang{ADDED});
  }
  elsif ($FORM{change}) {
    $Cablecat->color_schemes_change({ %FORM });
    show_result($Cablecat, $lang{CHANGED});

    # Return to chg with new values
    %TEMPLATE_SCHEME = %FORM;
    $FORM{chg} = 1;

    $show_add_form = 1;
  }
  elsif ($FORM{chg}) {
    my $tp_info = $Cablecat->color_schemes_info($FORM{chg});
    if (!_error_show($Cablecat)) {
      %TEMPLATE_SCHEME = %{$tp_info};
      $show_add_form = 1;
    }
  }
  elsif ($FORM{del}) {
    $Cablecat->color_schemes_del({ ID => $FORM{del} });
    show_result($Cablecat, $lang{DELETED});
  }

  if ($show_add_form) {

    $html->tpl_show(
      _include('cablecat_color_scheme', 'Cablecat'),
      {
        %TEMPLATE_SCHEME,
        %FORM,
        CABLECAT_COLORS   => join(',', map {($_, $_ . '+')} @CABLECAT_COLORS),
        SUBMIT_BTN_ACTION => ($FORM{chg}) ? 'change' : 'add',
        SUBMIT_BTN_NAME   => ($FORM{chg}) ? $lang{CHANGE} : $lang{ADD},
      }
    );
  }

  my AXbills::HTML $table;
  ($table) = result_former(
    {
      INPUT_DATA      => $Cablecat,
      FUNCTION        => 'color_schemes_list',
      BASE_FIELDS     => 0,
      DEFAULT_FIELDS  => 'ID,NAME,COLORS',
      FUNCTION_FIELDS => 'cablecat_color_schemes:$lang{COPY}:colors:&add_form=1,' . 'change,del',
      SKIP_USER_TITLE => 1,
      EXT_FIELDS      => 0,
      EXT_TITLES      => {
        id     => '#',
        name   => $lang{NAME},
        colors => $lang{COLOR_SCHEME},
      },
      FILTER_COLS     => { colors => '_cablecat_result_former_color_scheme_filter' },
      TABLE           => {
        width   => '100%',
        caption => $lang{COLOR_SCHEMES},
        ID      => 'COLOR_SCHEMES_TABLE',
        EXPORT  => 1,
        MENU    => "$lang{ADD}:index=$index&add_form=1:add"
      },
      MAKE_ROWS       => 1,
      SEARCH_FORMER   => 1,
      MODULE          => 'Cablecat',
    }
  );

  print $table->show();

  return 1;
}

#**********************************************************
=head2 cablecat_wells()

=cut
#**********************************************************
sub cablecat_wells {
  my %TEMPLATE_ARGS = ();
  my $show_add_form = $FORM{add_form} || 0;

  if ($FORM{add_reserve_form}) {
    my $Cable_list = $Cablecat->cables_list({
      POINT_ID => $FORM{object_id},
      NAME     => '_SHOW',
    });

    $Maps->points_add({
      COORDX   => $FORM{lat},
      COORDY   => $FORM{lng},
      NAME     => $Cable_list->[0]{name} . " $lang{RESERVE}",
      TYPE_ID  => 1,
      EXTERNAL => 1
    });
    $Cablecat->coil_add({
      NAME     => $Cable_list->[0]{name} . " $lang{RESERVE}",
      POINT_ID => $Maps->{INSERT_ID},
      CABLE_ID => $FORM{object_id},
    });
    if (!_error_show($Cablecat)) {
      show_result($Cablecat, $lang{SUCCESS}, $lang{ADDED} . ' ' . $lang{CABLE_RESERVE});
    }

    return 1;
  }

  if ($FORM{add} && $FORM{ADD_EXIST_OBJECT}) {
    $Maps->points_change({ %FORM, ID => $FORM{POINT_ID} });
  }
  elsif ($FORM{add} && $FORM{NEW_POINT_ID}) {
    $FORM{NAME} =~ s/\\"//gm if $FORM{NAME};
    $FORM{POINT_ID} = $FORM{NEW_POINT_ID};
    my $inserted_well_id = $Cablecat->wells_add(\%FORM);
    $show_add_form = !show_result($Cablecat, $lang{ADDED}, $lang{WELL});

    if (!_error_show($Cablecat) && $inserted_well_id && $FORM{ARTICLE_ID}) {
      load_module('Storage', $html);
      storage_hardware({ ADD_ONLY => 1, WITHOUT_USER => 1 });
      $Cablecat->cablecat_storage_installation_add({
        OBJECT_ID       => $inserted_well_id,
        INSTALLATION_ID => $FORM{INSTALLATION_ID},
        TYPE            => $STORAGE_TYPES{WELL}
      }) if $FORM{INSTALLATION_ID};
    }
  }
  elsif ($FORM{add}) {
    $FORM{NAME} =~ s/\\"//gm if $FORM{NAME};
    my $new_point_id = $Auxiliary->maps_add_external_object($MAP_TYPE_ID{WELL}, \%FORM);
    show_result($Maps, $lang{SUCCESS}, $lang{ADDED} . ' ' . $lang{OBJECT}, { ID => 'OBJECT_ADDED' });
    $FORM{POINT_ID} = $new_point_id;

    my $inserted_well_id = $Cablecat->wells_add(\%FORM);
    if ($inserted_well_id && $FORM{INSERT_ON_CABLE}) {
      my $result = _cablecat_break_cable_in_two_parts($FORM{INSERT_ON_CABLE}, $inserted_well_id);
      if ($result ne '1') {
        $html->message('err', $lang{ERROR}, $result);
        return 0;
      }
    }

    if (!_error_show($Cablecat) && $inserted_well_id && $FORM{ARTICLE_ID}) {
      load_module('Storage', $html);
      storage_hardware({ ADD_ONLY => 1, WITHOUT_USER => 1 });
      $Cablecat->cablecat_storage_installation_add({
        OBJECT_ID       => $inserted_well_id,
        INSTALLATION_ID => $FORM{INSTALLATION_ID},
        TYPE            => $STORAGE_TYPES{WELL}
      }) if $FORM{INSTALLATION_ID};
    }

    $show_add_form = !show_result($Cablecat, $lang{ADDED}, $lang{WELL});
  }
  elsif ($FORM{change}) {
    $FORM{NAME} =~ s/\\"//gm if $FORM{NAME};
    $Cablecat->wells_change({ %FORM });

    # Update underlying object
    if ($FORM{POINT_ID} && $FORM{POINT_ID} ne '0') {
      $Maps->points_change({ %FORM, ID => $FORM{POINT_ID} });
    }

    show_result($Cablecat, $lang{CHANGED});
  }
  elsif ($FORM{chg}) {
    my $tp_info = $Cablecat->wells_info($FORM{chg});
    if (!_error_show($Cablecat)) {
      %TEMPLATE_ARGS = %{$tp_info};
      $show_add_form = 1;

      $TEMPLATE_ARGS{LINKED} = _cablecat_well_cable_links($TEMPLATE_ARGS{ID}) || '';
      $TEMPLATE_ARGS{HAS_LINKED} = $TEMPLATE_ARGS{LINKED} ne '';

      if ($TEMPLATE_ARGS{TYPE_ID} && $TEMPLATE_ARGS{TYPE_ID} != 2) {
        $TEMPLATE_ARGS{CONNECTERS} = _cablecat_well_connecters($TEMPLATE_ARGS{ID}) || '';
        $TEMPLATE_ARGS{CONNECTERS_VISIBLE} = $TEMPLATE_ARGS{CONNECTERS} ne '';
      }

      $TEMPLATE_ARGS{ADD_OBJECT_VISIBLE} = '0';

      if (defined $TEMPLATE_ARGS{POINT_ID}) {
        $TEMPLATE_ARGS{OBJECT_INFO} = cablecat_make_point_info($TEMPLATE_ARGS{POINT_ID},, $MAP_LAYER_ID{WELL});
      }

      $TEMPLATE_ARGS{INSTALLATIONS_TABLE} = cablecat_storage_installations($FORM{chg}, $STORAGE_TYPES{WELL});
      $TEMPLATE_ARGS{HIDE_STORAGE_FORM} = 'd-none';
    }
  }
  elsif ($FORM{del}) {
    $Cablecat->wells_del({ ID => $FORM{del} });
    show_result($Cablecat, $lang{DELETED});
  }
  elsif ($FORM{search_form}) {

    $TEMPLATE_ARGS{TYPE_ID_SELECT} = _cablecat_well_types_select({ FILTERS => { TYPE_ID => '!2' } });
    $TEMPLATE_ARGS{POINT_ID_SELECT} = _cablecat_point_id_select();
    $TEMPLATE_ARGS{PARENT_ID_SELECT} = _cablecat_wells_select({ NAME => 'PARENT_ID', FILTERS => { TYPE_ID => '!2' } });

    form_search({
      SEARCH_FORM       => $html->tpl_show(_include('cablecat_wells_search', 'Cablecat'), { %TEMPLATE_ARGS, %FORM },
        { OUTPUT2RETURN => 1 }),
      PLAIN_SEARCH_FORM => 1
    });
  }

  return 1 if ($FORM{MESSAGE_ONLY});

  if ($show_add_form) {
    $TEMPLATE_ARGS{POINT_ID_SELECT} = _cablecat_point_id_select({
      SELECTED => $TEMPLATE_ARGS{POINT_ID} || $FORM{POINT_ID},
      ENTITY   => 'WELL'
    });
    $TEMPLATE_ARGS{PARENT_ID_SELECT} = _cablecat_wells_select({
      SELECTED => $TEMPLATE_ARGS{PARENT_ID} || $FORM{PARENT_ID},
      NAME     => 'PARENT_ID'
    });
    my $type_id_list = $Cablecat->well_types_list({
      ID        => '_SHOW',
      NAME      => '_SHOW',
      PAGE_ROWS => 100,
      DESC      => 'DESC',
      COLS_NAME => 1
    });

    _error_show($Cablecat);

    $TEMPLATE_ARGS{TYPE_ID_SELECT} = $html->form_select('TYPE_ID', {
      SELECTED => $TEMPLATE_ARGS{TYPE_ID},
      SEL_LIST => translate_list($type_id_list),
      NO_ID    => 1,
      REQUIRED => 1
    });
    my %count_for_type = ();
    foreach my $well_type (@$type_id_list) {
      # my $next_id = $Cablecat->wells_next({ TYPE_ID => $well_type->{id} });
      # $count_for_type{$well_type->{id}} = $next_id ? $next_id + 1 : $Cablecat->wells_next() + 1;
      $count_for_type{$well_type->{id}} = $Cablecat->wells_next() + 1;
    }
    $TEMPLATE_ARGS{COUNT_FOR_TYPE} = encode_json(\%count_for_type);

    $TEMPLATE_ARGS{NAME} ||= $lang{WELL} . '_' . (($count_for_type{1} || 0) + 2);

    # Maps related
    if ($FORM{INSERT_ON_CABLE}) {
      $TEMPLATE_ARGS{EXTRA_INPUTS} = $html->form_input('INSERT_ON_CABLE', $FORM{INSERT_ON_CABLE}, { TYPE => 'hidden' });
    }

    $TEMPLATE_ARGS{ADD_OBJECT_VISIBLE} //= 1;

    $html->tpl_show(_include('cablecat_well', 'Cablecat'), {
      %TEMPLATE_ARGS,
      %FORM,
      %{_cablecat_storage_installation_template() || {}},
      CONNECTERS_VISIBLE => !$FORM{TEMPLATE_ONLY} && $TEMPLATE_ARGS{CONNECTERS_VISIBLE},
      MAIN_FORM_SIZE     => $FORM{TEMPLATE_ONLY} ? 'col-md-12' : 'col-md-6',
      SUBMIT_BTN_ACTION  => ($FORM{chg}) ? 'change' : 'add',
      SUBMIT_BTN_NAME    => ($FORM{chg}) ? $lang{CHANGE} : $lang{ADD},
    });

    if ($TEMPLATE_ARGS{ID}) {
      load_module('Info', $html);
      info_comments_show('cablecat_wells', $TEMPLATE_ARGS{ID});
    }
  }

  return 1 if ($FORM{TEMPLATE_ONLY});

  result_former({
    INPUT_DATA      => $Cablecat,
    FUNCTION        => 'wells_list',
    BASE_FIELDS     => 0,
    DEFAULT_FIELDS  => 'ID,NAME,TYPE,INSTALLED,PLANNED,POINT_ID,PARENT_ID',
    FUNCTION_FIELDS => 'change,del',
    SKIP_USER_TITLE => 1,
    EXT_FIELDS      => 0,
    EXT_TITLES      => {
      id        => '#',
      name      => $lang{NAME},
      type      => $lang{TYPE},
      installed => $lang{INSTALLED},
      planned   => $lang{PLANNED},
      point_id  => $lang{LOCATION},
      parent_id => $lang{INSIDE}
    },
    FILTER_COLS     => {
      point_id  => '_cablecat_result_former_point_id_filter:' . $MAP_LAYER_ID{WELL},
      parent_id => '_cablecat_result_former_parent_id_filter',
      type      => '_translate',
    },
    TABLE           => {
      width   => '100%',
      caption => $lang{WELLS},
      ID      => 'WELLS_TABLE',
      EXPORT  => 1,
      MENU    => "$lang{ADD}:index=$index&add_form=1:add;$lang{SEARCH}:index=$index&search_form=1:search"
    },
    MAKE_ROWS       => 1,
    SEARCH_FORMER   => 1,
    MODULE          => 'Cablecat',
    TOTAL           => 1
  });

  return 1;
}

#**********************************************************
=head2 cablecat_well_types()

=cut
#**********************************************************
sub cablecat_well_types {
  my %TEMPLATE_ARGS = ();
  my $show_add_form = $FORM{add_form} || 0;

  if ($FORM{add}) {
    $Cablecat->well_types_add({ %FORM });
    $show_add_form = !show_result($Cablecat, $lang{ADDED});
  }
  elsif ($FORM{change}) {
    $Cablecat->well_types_change({ %FORM });
    show_result($Cablecat, $lang{CHANGED});
    $show_add_form = 1;
  }
  elsif ($FORM{chg}) {
    my $well_info = $Cablecat->well_types_info($FORM{chg});
    if (!_error_show($Cablecat)) {
      %TEMPLATE_ARGS = %{$well_info};
      $show_add_form = 1;
    }
  }
  elsif ($FORM{del} && $FORM{COMMENTS}) {
    $Cablecat->well_types_del({ ID => $FORM{del}, COMMENTS => $FORM{COMMENTS} });
    show_result($Cablecat, $lang{DELETED});
  }

  if ($show_add_form) {
    $TEMPLATE_ARGS{ICON_SELECT} = _maps_icon_filename_select({ NAME => 'ICON', NO_EXTENSION => 1, ICON => $TEMPLATE_ARGS{ICON} });

    $html->tpl_show(_include('cablecat_well_types', 'Cablecat'), {
      %TEMPLATE_ARGS,
      %FORM,
      SUBMIT_BTN_ACTION => ($FORM{chg}) ? 'change' : 'add',
      SUBMIT_BTN_NAME   => ($FORM{chg}) ? $lang{CHANGE} : $lang{ADD},
    });
  }

  my AXbills::HTML $table;
  ($table) = result_former({
    INPUT_DATA      => $Cablecat,
    FUNCTION        => 'well_types_list',
    BASE_FIELDS     => 0,
    DEFAULT_FIELDS  => 'ID,NAME,ICON,COMMENTS',
    FUNCTION_FIELDS => 'change,del',
    SKIP_USER_TITLE => 1,
    EXT_FIELDS      => 0,
    EXT_TITLES      => {
      id       => '#',
      name     => $lang{NAME},
      icon     => $lang{ICON},
      comments => $lang{COMMENTS}
    },
    FILTER_COLS     => {
      icon => '_cablecat_result_former_icon_filter',
      name => '_translate',
    },
    TABLE           => {
      width   => '100%',
      caption => "$lang{WELL} $lang{TYPE}",
      ID      => 'WELLS_TYPE_TABLE',
      EXPORT  => 1,
      MENU    => "$lang{ADD}:index=$index&add_form=1:add"
    },
    MAKE_ROWS       => 1,
    SEARCH_FORMER   => 1,
    MODULE          => 'Cablecat',
  });

  print $table->show();

  return 1;
}

#**********************************************************
=head2 cablecat_connecter_types()

=cut
#**********************************************************
sub cablecat_connecter_types {
  my %TEMPLATE_ARGS = ();
  my $show_add_form = $FORM{add_form} || 0;

  if ($FORM{add}) {
    $Cablecat->connecter_types_add({ %FORM });
    $show_add_form = !show_result($Cablecat, $lang{ADDED});
  }
  elsif ($FORM{change}) {
    $Cablecat->connecter_types_change({ %FORM });
    show_result($Cablecat, $lang{CHANGED});
    $show_add_form = 1;
  }
  elsif ($FORM{chg}) {
    my $tp_info = $Cablecat->connecter_types_info($FORM{chg});
    if (!_error_show($Cablecat)) {
      %TEMPLATE_ARGS = %{$tp_info};
      $show_add_form = 1;
    }
  }
  elsif ($FORM{del}) {
    $Cablecat->connecter_types_del({ ID => $FORM{del} });
    show_result($Cablecat, $lang{DELETED});
  }

  if ($show_add_form) {
    $html->tpl_show(
      _include('cablecat_connecter_type', 'Cablecat'),
      {
        %TEMPLATE_ARGS,
        SUBMIT_BTN_ACTION => ($FORM{chg}) ? 'change' : 'add',
        SUBMIT_BTN_NAME   => ($FORM{chg}) ? $lang{CHANGE} : $lang{ADD},
      }
    );
  }

  my AXbills::HTML $table;
  ($table) = result_former(
    {
      INPUT_DATA      => $Cablecat,
      FUNCTION        => 'connecter_types_list',
      BASE_FIELDS     => 0,
      DEFAULT_FIELDS  => 'ID,NAME,CARTRIDGES,COMMENTS',
      FUNCTION_FIELDS => 'change,del',
      SKIP_USER_TITLE => 1,
      EXT_FIELDS      => 0,
      EXT_TITLES      => {
        id         => '#',
        name       => $lang{NAME},
        comments   => $lang{COMMENTS},
        cartridges => $lang{CARTRIDGES}
      },
      FILTER_COLS     => {

        #        type_name => '_translate',
      },
      TABLE           => {
        width   => '100%',
        caption => $lang{CONNECTER_TYPE},
        ID      => 'CONNECTER_TYPE_TABLE',
        EXPORT  => 1,
        MENU    => "$lang{ADD}:index=$index&add_form=1:add"
      },
      MAKE_ROWS       => 1,
      SEARCH_FORMER   => 1,
      MODULE          => 'Cablecat',
    }
  );

  print $table->show();

  return 1;
}

#**********************************************************
=head2 cablecat_connecters()

=cut
#**********************************************************
sub cablecat_connecters {
  my %TEMPLATE_ARGS = ();
  my $show_add_form = $FORM{add_form} || 0;

  if ($FORM{add}) {
    $FORM{NAME} ||= do {
      $lang{CONNECTER} . '_' . ($Cablecat->connecters_next());
    };

    my $new_point_id = $Auxiliary->maps_add_external_object($MAP_TYPE_ID{SPLITTER}, \%FORM);
    show_result($Maps, $lang{ADDED} . ' ' . $lang{OBJECT});
    $FORM{POINT_ID} = $new_point_id;

    $Cablecat->connecters_add({ %FORM });
    $show_add_form = !show_result($Cablecat, $lang{ADDED});
  }
  elsif ($FORM{change}) {
    $Cablecat->connecters_change({ %FORM });
    show_result($Cablecat, $lang{CHANGED});
    $show_add_form = 1;
  }
  elsif ($FORM{chg}) {
    my $connecter = $Cablecat->connecters_info($FORM{chg});
    if (!_error_show($Cablecat)) {
      %TEMPLATE_ARGS = %{$connecter};
      $show_add_form = 1;

      if (defined $connecter->{well_id}) {

        # Make commutation box visible
        $TEMPLATE_ARGS{COMMUTATION_FORM} = _cablecat_connecter_commutation_list($connecter->{id}, $connecter->{well_id}) || '';
        if ($TEMPLATE_ARGS{COMMUTATION_FORM} ne '') {
          $TEMPLATE_ARGS{HAS_COMMUTATION_FORM} = 1;
          $TEMPLATE_ARGS{CLASS_FOR_MAIN_FORM} = 'col-md-6';
        }

        $TEMPLATE_ARGS{LINKED} = _cablecat_connecter_linked_connecters($TEMPLATE_ARGS{ID}) || '';
        if ($TEMPLATE_ARGS{LINKED} ne '') {
          $TEMPLATE_ARGS{HAS_LINKED} = 1;
          $TEMPLATE_ARGS{CLASS_FOR_MAIN_FORM} = 'col-md-6';
        }

      }

      if (defined $TEMPLATE_ARGS{POINT_ID}) {
        $TEMPLATE_ARGS{OBJECT_INFO} = cablecat_make_point_info($TEMPLATE_ARGS{POINT_ID}, $MAP_LAYER_ID{WELL});
      }

    }
  }
  elsif ($FORM{del}) {
    $Cablecat->connecters_del({ ID => $FORM{del} });
    show_result($Cablecat, $lang{DELETED});
  }
  elsif ($FORM{search_form}) {

    $TEMPLATE_ARGS{CONNECTER_TYPE_ID_SELECT} = _cablecat_connecter_type_select({
      NAME => 'CONNECTER_TYPE_ID'
    });
    $TEMPLATE_ARGS{WELL_ID_SELECT} = _cablecat_well_types_select({
      NAME => 'PARENT_ID'
    });

    form_search({
      SEARCH_FORM       => $html->tpl_show(_include('cablecat_connecters_search', 'Cablecat'),
        { %TEMPLATE_ARGS, %FORM },
        { OUTPUT2RETURN => 1 }
      ),
      #      ADDRESS_FORM      => 1,
      PLAIN_SEARCH_FORM => 1
    });
  }

  return 1 if $FORM{MESSAGE_ONLY};

  if ($show_add_form) {
    $TEMPLATE_ARGS{CLASS_FOR_MAIN_FORM} //= 'col-md-6 col-md-offset-3';
    $TEMPLATE_ARGS{CONNECTER_TYPE_ID_SELECT} = _cablecat_connecter_type_select({
      SELECTED => $TEMPLATE_ARGS{CONNECTER_TYPE_ID},
      REQUIRED => 1,
      NAME     => 'CONNECTER_TYPE_ID'
    });

    $TEMPLATE_ARGS{WELL_ID_SELECT} = _cablecat_wells_select({
      SELECTED => $TEMPLATE_ARGS{WELL_ID} || $FORM{WELL_ID},
      NAME     => 'PARENT_ID',
      REQUIRED => 1
    });

    $TEMPLATE_ARGS{NAME} //= do {
      $TEMPLATE_ARGS{TYPE}
        ? ($TEMPLATE_ARGS{TYPE}) . '_' . ($Cablecat->connecters_next({ TYPE_ID => $TEMPLATE_ARGS{TYPE_ID} }))
        : ($lang{CONNECTER}) . '_' . ($Cablecat->connecters_next());
    };

    $html->tpl_show(_include('cablecat_connecter', 'Cablecat'), {
      %TEMPLATE_ARGS,
      %FORM,
      NEXT_TYPE_ID      => $Cablecat->connecters_next(),
      SUBMIT_BTN_ACTION => ($FORM{chg}) ? 'change' : 'add',
      SUBMIT_BTN_NAME   => ($FORM{chg}) ? $lang{CHANGE} : $lang{ADD},
    });

    if ($TEMPLATE_ARGS{ID}) {
      load_module('Info', $html);
      info_documents_show('cablecat_connecters', $TEMPLATE_ARGS{ID});
    }
  }

  return 1 if ($FORM{TEMPLATE_ONLY});

  my AXbills::HTML $table;
  ($table) = result_former(
    {
      INPUT_DATA      => $Cablecat,
      FUNCTION        => 'connecters_list',
      BASE_FIELDS     => 0,
      DEFAULT_FIELDS  => 'ID,NAME,TYPE,INSTALLED,PLANNED,POINT_ID',
      FUNCTION_FIELDS => 'change,del',
      SKIP_USER_TITLE => 1,
      EXT_FIELDS      => 0,
      EXT_TITLES      => {
        id             => '#',
        name           => $lang{NAME},
        type           => $lang{TYPE},
        installed      => $lang{INSTALLED},
        planned        => $lang{PLANNED},
        point_id       => $lang{LOCATION},
        connecter_type => $lang{CONNECTER_TYPE}
      },
      FILTER_COLS     => {
        point_id => '_cablecat_result_former_point_id_filter:' . $MAP_LAYER_ID{WELL},

        #        type_name => '_translate',
      },
      TABLE           => {
        width   => '100%',
        caption => $lang{CONNECTERS},
        ID      => 'CONNECTERS_TABLE',
        EXPORT  => 1,
        MENU    => "$lang{ADD}:index=$index&add_form=1:add;$lang{SEARCH}:index=$index&search_form=1:search"

      },
      MAKE_ROWS       => 1,
      SEARCH_FORMER   => 1,
      MODULE          => 'Cablecat',
    }
  );

  print $table->show();

  return 1;
}

#**********************************************************
=head2 cablecat_make_point_info()

=cut
#**********************************************************
sub cablecat_make_point_info {
  my ($point_id, $layer_id) = @_;

  if (!$point_id) {

    if ($FORM{chg}) {
      # Return create object btn
      return $html->button("$lang{CREATE} $lang{OBJECT}", "index=$index&chg=$FORM{chg}&CREATE_OBJECT=1");
    }
    elsif ($FORM{add_form}) {
      return $html->tpl_show(_include('cablecat_point', 'Cablecat'), {}, { OUTPUT2RETURN => 1 });
    }

    return 0;
  }

  my $point_info = $Maps->points_info($point_id);

  if ($layer_id && $point_id) {
    $point_info->{SHOW_MAP_BTN} = 1;
    $point_info->{MAP_BTN} = $Auxiliary->maps_show_object_button($layer_id || $point_info->{LAYER_ID}, $point_id, { NAME => $lang{SHOW} });
  }

  $point_info->{ADDRESS_NAME} = $point_info->{LOCATION_ID} ? full_address_name($point_info->{LOCATION_ID}) : $lang{NO_DATA};

  $point_info->{PLANNED_NAMED} = ($point_info->{PLANNED}) ? $lang{YES} : $lang{NO};

  return $html->tpl_show(_include('cablecat_point_info_block', 'Cablecat'), $point_info, { OUTPUT2RETURN => 1 });
}

#**********************************************************
=head2 cablecat_splitter_types()

=cut
#**********************************************************
sub cablecat_splitter_types {

  my %TEMPLATE_ARGS = ();
  my $show_add_form = $FORM{add_form} || 0;

  if ($FORM{add}) {
    $Cablecat->splitter_types_add({ %FORM });
    $show_add_form = !show_result($Cablecat, $lang{ADDED});
  }
  elsif ($FORM{change}) {
    $Cablecat->splitter_types_change({ %FORM });
    show_result($Cablecat, $lang{CHANGED});
    $show_add_form = 1;
  }
  elsif ($FORM{chg}) {
    my $tp_info = $Cablecat->splitter_types_info($FORM{chg});
    if (!_error_show($Cablecat)) {
      %TEMPLATE_ARGS = %{$tp_info};
      $show_add_form = 1;
    }
  }
  elsif ($FORM{del}) {
    $Cablecat->splitter_types_del({ ID => $FORM{del} });
    show_result($Cablecat, $lang{DELETED});
  }

  if ($show_add_form) {
    $TEMPLATE_ARGS{FIBERS_IN} ||= 1;
    $html->tpl_show(_include('cablecat_splitter_type', 'Cablecat'), {
      %TEMPLATE_ARGS,
      %FORM,
      SUBMIT_BTN_ACTION => ($FORM{chg}) ? 'change' : 'add',
      SUBMIT_BTN_NAME   => ($FORM{chg}) ? $lang{CHANGE} : $lang{ADD},
    });
  }

  my AXbills::HTML $table;
  ($table) = result_former({
    INPUT_DATA      => $Cablecat,
    FUNCTION        => 'splitter_types_list',
    BASE_FIELDS     => 0,
    DEFAULT_FIELDS  => 'ID,NAME,FIBERS_IN,FIBERS_OUT',
    FUNCTION_FIELDS => 'change,del',
    SKIP_USER_TITLE => 1,
    EXT_FIELDS      => 0,
    EXT_TITLES      => {
      id         => '#',
      name       => $lang{NAME},
      fibers_in  => $lang{FIBERS_IN},
      fibers_out => $lang{FIBERS_OUT},
    },
    TABLE         => {
      width   => '100%',
      caption => $lang{SPLITTER_TYPES},
      ID      => 'SPLITTER_TYPE_TABLE',
      EXPORT  => 1,
      MENU    => "$lang{ADD}:index=$index&add_form=1:add"
    },
    MAKE_ROWS     => 1,
    SEARCH_FORMER => 1,
    MODULE        => 'Cablecat',
  });

  print $table->show();

  return 1;
}

#**********************************************************
=head2 cablecat_splitters()

=cut
#**********************************************************
sub cablecat_splitters {
  my %TEMPLATE_ARGS = ();
  my $show_add_form = $FORM{add_form} || 0;

  if ($FORM{add}) {
    my $new_point_id = $Auxiliary->maps_add_external_object($MAP_TYPE_ID{SPLITTER}, \%FORM);
    show_result($Maps, $lang{ADDED} . ' ' . $lang{OBJECT});
    $FORM{POINT_ID} = $new_point_id;

    my $splitter_id = $Cablecat->splitters_add({ %FORM });
    $show_add_form = !show_result($Cablecat, $lang{ADDED});

    if (!$Cablecat->{errno} && $splitter_id && $FORM{ARTICLE_ID}) {
      load_module('Storage', $html);
      storage_hardware({ ADD_ONLY => 1, WITHOUT_USER => 1 });
      $Cablecat->cablecat_storage_installation_add({
        OBJECT_ID       => $splitter_id,
        INSTALLATION_ID => $FORM{INSTALLATION_ID},
        TYPE            => $STORAGE_TYPES{SPLITTER}
      }) if $FORM{INSTALLATION_ID};
    }
  }
  elsif ($FORM{change}) {
    $Cablecat->splitters_change({ %FORM });
    show_result($Cablecat, $lang{CHANGED});
    $show_add_form = 1;
  }
  elsif ($FORM{chg}) {
    my $splitter_info = $Cablecat->splitters_info($FORM{chg});

    if (!_error_show($Cablecat)) {
      %TEMPLATE_ARGS = %{$splitter_info};
      $show_add_form = 1;

      if (defined $TEMPLATE_ARGS{POINT_ID}) {
        $TEMPLATE_ARGS{OBJECT_INFO} = cablecat_make_point_info($TEMPLATE_ARGS{POINT_ID}, undef);
      }
      $TEMPLATE_ARGS{INSTALLATIONS_TABLE} = cablecat_storage_installations($FORM{chg}, $STORAGE_TYPES{SPLITTER});
      $TEMPLATE_ARGS{HIDE_STORAGE_FORM} = 'd-none';
    }
  }
  elsif ($FORM{del}) {
    $Cablecat->splitters_del({ ID => $FORM{del} });
    show_result($Cablecat, $lang{DELETED});
  }
  elsif ($FORM{search_form}) {
    $TEMPLATE_ARGS{TYPE_ID_SELECT} = _cablecat_splitter_types_select();
    $TEMPLATE_ARGS{WELL_ID_SELECT} = _cablecat_wells_select({
      FILTERS => { TYPE_ID => '!2' }
    });
    $TEMPLATE_ARGS{COMMUTATION_ID_SELECT} = _cablecat_commutations_select;

    form_search({ SEARCH_FORM => $html->tpl_show(_include('cablecat_splitters_search', 'Cablecat'), {
      %TEMPLATE_ARGS, %FORM
    }, { OUTPUT2RETURN => 1 }),
      PLAIN_SEARCH_FORM       => 1
    });
  }

  return 1 if ($FORM{MESSAGE_ONLY});

  if ($show_add_form) {
    $TEMPLATE_ARGS{TYPE_ID_SELECT} = _cablecat_splitter_types_select({
      SELECTED => $TEMPLATE_ARGS{TYPE_ID} || $FORM{TYPE_ID},
      NAME     => 'TYPE_ID'
    });
    $TEMPLATE_ARGS{WELL_ID_SELECT} = _cablecat_wells_select({
      SELECTED => $TEMPLATE_ARGS{WELL_ID} || $FORM{WELL_ID},
      NAME     => 'WELL_ID',
      FILTERS  => { TYPE_ID => '!2' }
    });

    $TEMPLATE_ARGS{COMMUTATION_ID_SELECT} = _cablecat_commutations_select({
      SELECTED => $TEMPLATE_ARGS{COMMUTATION_ID} || $FORM{COMMUTATION_ID},
      NAME     => 'COMMUTATION_ID'
    });

    my $color_id = $TEMPLATE_ARGS{COLOR_SCHEME_ID} || $FORM{COLOR_SCHEME_ID};
    my $fibers_colors_select = _cablecat_color_scheme_select({ SELECTED => $color_id });

    $html->tpl_show(_include('cablecat_splitter', 'Cablecat'), {
      %TEMPLATE_ARGS,
      %FORM,
      %{_cablecat_storage_installation_template() || {}},
      COLOR_SCHEME_ID_SELECT => $fibers_colors_select,
      SUBMIT_BTN_ACTION      => ($FORM{chg}) ? 'change' : 'add',
      SUBMIT_BTN_NAME        => ($FORM{chg}) ? $lang{CHANGE} : $lang{ADD},
    });
  }

  return 1 if ($FORM{TEMPLATE_ONLY});

  print _cablecat_splitter_links_table($TEMPLATE_ARGS{ID}) if ($TEMPLATE_ARGS{ID});

  my AXbills::HTML $table;
  ($table) = result_former({
    INPUT_DATA      => $Cablecat,
    FUNCTION        => 'splitters_list',
    BASE_FIELDS     => 0,
    DEFAULT_FIELDS  => 'ID,NAME,TYPE,WELL,POINT_ID,CREATED,FIBERS_COLORS_NAME',
    HIDDEN_FIELDS   => 'WELL_ID,TYPE_ID',
    FUNCTION_FIELDS => 'change,del',
    SKIP_USER_TITLE => 1,
    EXT_FIELDS      => 0,
    EXT_TITLES      => {
      id                 => '#',
      type               => $lang{TYPE},
      name               => $lang{NAME},
      created            => $lang{CREATED},
      fibers_colors_name => $lang{COLOR_SCHEME},
      installed          => $lang{INSTALLED},
      planned            => $lang{PLANNED},
      point_id           => $lang{LOCATION},
      well               => $lang{WELL}
    },
    FILTER_VALUES   => {
      well => sub {
        my ($name, $line) = @_;
        $html->button($name, "get_index=cablecat_wells&full=1&chg=" . ($line->{well_id} || q{}));
      },
      type => sub {
        my ($name, $line) = @_;
        $html->button($name, "get_index=cablecat_splitter_types&full=1&chg=" . ($line->{type_id} || q{}));
      }
    },
    TABLE           => {
      width   => '100%',
      caption => $lang{SPLITTERS},
      ID      => 'SPLITTERS_TABLE',
      EXPORT  => 1,
      MENU    => "$lang{ADD}:index=$index&add_form=1:add;$lang{SEARCH}:index=$index&search_form=1:search"
    },
    MAKE_ROWS       => 1,
    SEARCH_FORMER   => 1,
    MODULE          => 'Cablecat',
    TOTAL           => 1
  });

  return 1;
}

#**********************************************************
=head2 cablecat_commutations()

=cut
#**********************************************************
sub cablecat_commutations {
  my $show_add_form = $FORM{add_form} || 0;

  if ($FORM{add}) {
    $Cablecat->commutations_add({ %FORM });
    $show_add_form = !show_result($Cablecat, $lang{ADDED});
  }
  elsif ($FORM{change}) {
    $Cablecat->commutations_change({ %FORM });
    show_result($Cablecat, $lang{CHANGED});
    $show_add_form = 1;
  }
  elsif ($FORM{chg}) {
    # Redirect to scheme page
    my $commutation_preview_index = get_function_index('cablecat_commutation');
    $html->redirect("?index=$commutation_preview_index&ID=$FORM{chg}", { WAIT => 0, MESSAGE => $lang{WAIT} });
    return 1;
  }
  elsif ($FORM{del}) {
    $Cablecat->commutations_del({ ID => $FORM{del} });
    $Cablecat->links_del(undef, { commutation_id => $FORM{del} });
    $Cablecat->commutation_crosses_del(undef, { commutation_id => $FORM{del} });
    $Cablecat->commutation_equipment_del(undef, { commutation_id => $FORM{del} });
    $Cablecat->commutation_cables_del(undef, { commutation_id => $FORM{del} });
    $Cablecat->splitters_del(undef, { commutation_id => $FORM{del} });

    show_result($Cablecat, $lang{DELETED});
  }
  elsif ($FORM{search_form}) {
    my %TEMPLATE_ARGS = ();

    $TEMPLATE_ARGS{CONNECTER_ID_SELECT} = _cablecat_connecters_select();
    $TEMPLATE_ARGS{WELL_ID_SELECT} = _cablecat_wells_select();
    $TEMPLATE_ARGS{CABLE_ID_SELECT} = _cablecat_cables_select({ NAME => 'CABLE_IDS', MULTIPLE => 1 });

    form_search({
      SEARCH_FORM       => $html->tpl_show(_include('cablecat_commutations_search', 'Cablecat'),
        { %TEMPLATE_ARGS, %FORM },
        { OUTPUT2RETURN => 1 }
      ),
      ADDRESS_FORM      => 1,
      PLAIN_SEARCH_FORM => 1
    });

  }

  if ($show_add_form) {

  }
  #
  #  my $commutations_list = $Cablecat->commutations_list({
  #    ID           => '_SHOW',
  #    CREATED      => '_SHOW',
  #    CONNECTER    => '_SHOW',
  #    CABLES       => '_SHOW',
  #    WELL         => '_SHOW',
  #    CONNECTER_ID => '_SHOW',
  #    CABLE_IDS    => '_SHOW',
  #    WELL_ID      => '_SHOW',
  #    %LIST_PARAMS,
  #    COLS_NAME => 1
  #  });

  my AXbills::HTML $table;
  ($table) = result_former(
    {
      #      LIST            => $commutations_list,
      INPUT_DATA      => $Cablecat,
      FUNCTION        => 'commutations_list',
      BASE_FIELDS     => 0,
      DEFAULT_FIELDS  => 'ID,NAME,CREATED,CONNECTER,CABLES,WELL',
      HIDDEN_FIELDS   => 'CONNECTER_ID,CABLE_IDS,WELL_ID',
      FUNCTION_FIELDS => 'cablecat_commutation:change:id:,del',
      SKIP_USER_TITLE => 1,
      EXT_FIELDS      => 0,
      EXT_TITLES      => {
        id        => '#',
        name      => $lang{NAME},
        cables    => $lang{CABLES},
        created   => $lang{CREATED},
        connecter => $lang{CONNECTER},
        well      => $lang{WELL},
        type      => $lang{TYPE},
        planned   => $lang{PLANNED},
        point_id  => $lang{LOCATION},
      },
      FILTER_COLS     => {
        #        connecter => '_cablecat_result_former_point_id_filter:' . $MAP_LAYER_ID{SPLITTER},
        connecter => '_cablecat_result_former_named_chg_link_filter::PARAM_NAME=connecter_id,FUNCTION=cablecat_connecters,CONNECTER_ID',
        cables    => '_cablecat_result_former_named_chg_link_filter::PARAM_NAME=cable_ids,FUNCTION=cablecat_cables,CABLE_IDS',
        well      => '_cablecat_result_former_named_chg_link_filter::PARAM_NAME=well_id,FUNCTION=cablecat_wells,WELL_ID',

        #        type_name => '_translate',
      },
      TABLE           => {
        width   => '100%',
        caption => $lang{COMMUTATIONS},
        ID      => 'COMMUTATIONS_TABLE',
        EXPORT  => 1,
        MENU    => "$lang{SEARCH}:index=$index&search_form=1:search"
        #         . "$lang{ADD}:index=$index&add_form=1:add"
      },
      MAKE_ROWS       => 1,
      SEARCH_FORMER   => 1,
      MODULE          => 'Cablecat',
    }
  );

  print $table->show();

  return 1;

}

#**********************************************************
=head2 cablecat_cross_types()

=cut
#**********************************************************
sub cablecat_cross_types {
  my %TEMPLATE_ARGS = ();
  my $show_add_form = $FORM{add_form} || 0;

  if ($FORM{add}) {
    $Cablecat->cross_types_add({ %FORM });
    $show_add_form = !show_result($Cablecat, $lang{ADDED});
  }
  elsif ($FORM{change}) {
    $Cablecat->cross_types_change({ %FORM });
    show_result($Cablecat, $lang{CHANGED});
    $show_add_form = 1;
  }
  elsif ($FORM{chg}) {
    my $tp_info = $Cablecat->cross_types_info($FORM{chg});
    if (!_error_show($Cablecat)) {
      %TEMPLATE_ARGS = %{$tp_info};
      $show_add_form = 1;
    }
  }
  elsif ($FORM{del} && $FORM{COMMENTS}) {
    $Cablecat->cross_types_del({ ID => $FORM{del}, COMMENTS => $FORM{COMMENTS} });
    show_result($Cablecat, $lang{DELETED});
  }

  return 1 if $FORM{MESSAGE_ONLY};

  if ($show_add_form) {

    $html->tpl_show(
      _include('cablecat_cross_types', 'Cablecat'),
      {
        CROSS_TYPE_ID_SELECT  => make_select_from_hash('CROSS_TYPE_ID', \%CROSS_CROSS_TYPE, { REQUIRED => 1 }),
        PANEL_TYPE_ID_SELECT  => make_select_from_hash('PANEL_TYPE_ID', \%CROSS_PANEL_TYPE, { REQUIRED => 1 }),
        PORTS_TYPE_ID_SELECT  => make_select_from_hash('PORTS_TYPE_ID', \%CROSS_PORT_TYPE, { REQUIRED => 1 }),
        POLISH_TYPE_ID_SELECT => make_select_from_hash('POLISH_TYPE_ID', \%CROSS_POLISH_TYPE, { REQUIRED => 1 }),
        FIBER_TYPE_ID_SELECT  => make_select_from_hash('FIBER_TYPE_ID', \%CROSS_FIBER_TYPE, { REQUIRED => 1 }),
        %TEMPLATE_ARGS,
        %FORM,
        SUBMIT_BTN_ACTION     => ($FORM{chg}) ? 'change' : 'add',
        SUBMIT_BTN_NAME       => ($FORM{chg}) ? $lang{CHANGE} : $lang{ADD},
      }
    );
  }
  return 1 if ($FORM{TEMPLATE_ONLY});

  my AXbills::HTML $table;
  ($table) = result_former(
    {
      INPUT_DATA      => $Cablecat,
      FUNCTION        => 'cross_types_list',
      BASE_FIELDS     => 0,
      DEFAULT_FIELDS  => 'ID,NAME,CROSS_TYPE_ID,PANEL_TYPE_ID,RACK_HEIGHT,PORTS_COUNT,PORTS_TYPE_ID,POLISH_TYPE_ID,FIBER_TYPE_ID',
      FUNCTION_FIELDS => 'change,del',
      SKIP_USER_TITLE => 1,
      EXT_FIELDS      => 0,
      EXT_TITLES      => {
        id             => '#',
        name           => $lang{NAME},
        cross_type_id  => $lang{CROSS_TYPE},
        panel_type_id  => $lang{PANEL_TYPE},
        rack_height    => $lang{RACK_HEIGHT},
        ports_count    => $lang{PORTS_COUNT},
        ports_type_id  => $lang{PORTS_TYPE},
        polish_type_id => $lang{POLISH_TYPE},
        fiber_type_id  => $lang{FIBER_TYPE},
      },
      SELECT_VALUE    => {
        cross_type_id  => \%CROSS_CROSS_TYPE,
        panel_type_id  => \%CROSS_PANEL_TYPE,
        ports_type_id  => \%CROSS_PORT_TYPE,
        polish_type_id => \%CROSS_POLISH_TYPE,
        fiber_type_id  => \%CROSS_FIBER_TYPE,
      },
      TABLE           => {
        width   => '100%',
        caption => $lang{CROSS_TYPES},
        ID      => 'CROSS_TYPES_TABLE',
        EXPORT  => 1,
        MENU    => "$lang{ADD}:index=$index&add_form=1:add"
      },
      MAKE_ROWS       => 1,
      SEARCH_FORMER   => 1,
      MODULE          => 'Cablecat',
    }
  );

  print $table->show();

}

#**********************************************************
=head2 cablecat_crosses()

=cut
#**********************************************************
sub cablecat_crosses {
  my %TEMPLATE_ARGS = ();
  my $show_add_form = $FORM{add_form} || 0;

  # Acts as subfunction
  if ($FORM{cross_link_operation}) {

    if (!$FORM{CROSS_ID} || !$FORM{CROSS_PORT}) {
      $html->message('err', "\$FORM{CROSS_ID} or \$FORM{CROSS_PORT} is not specified");
      return 0;
    }

    # Function can return '2' that means we should proceed this operation.
    # If it showed template and returned '1', we should stop current function)
    my $operation_result = _cablecat_cross_links($FORM{CROSS_ID}, $FORM{CROSS_PORT});
    if ($operation_result && $operation_result eq 1) {
      return 1;
    }

    delete @FORM{qw/add chg change del cross_link_operation action/};
    $FORM{chg} = $FORM{CROSS_ID};
  }

  if ($FORM{add}) {
    $FORM{NAME} =~ s/\\"//gm if $FORM{NAME};
    $Cablecat->crosses_add({ %FORM });
    $show_add_form = !show_result($Cablecat, $lang{ADDED});
  }
  elsif ($FORM{change}) {
    $FORM{NAME} =~ s/\\"//gm if $FORM{NAME};
    $Cablecat->crosses_change({ %FORM });
    show_result($Cablecat, $lang{CHANGED});
    $show_add_form = 1;
  }
  elsif ($FORM{chg}) {
    my $tp_info = $Cablecat->crosses_info($FORM{chg});
    if (!_error_show($Cablecat)) {
      %TEMPLATE_ARGS = %{$tp_info};
      $show_add_form = 1;
    }
  }
  elsif ($FORM{del} && $FORM{COMMENTS}) {
    $Cablecat->crosses_del({ ID => $FORM{del}, COMMENTS => $FORM{COMMENTS} });
    $Cablecat->commutation_crosses_del(undef, { cross_id => $FORM{del} });
    show_result($Cablecat, $lang{DELETED});
  }
  elsif ($FORM{search_form}) {
    $TEMPLATE_ARGS{TYPE_ID_SELECT} = _cablecat_cross_types_select();
    $TEMPLATE_ARGS{WELL_ID_SELECT} = _cablecat_wells_select();

    form_search({
      SEARCH_FORM       => $html->tpl_show(_include('cablecat_crosses_search', 'Cablecat'),
        { %TEMPLATE_ARGS, %FORM },
        { OUTPUT2RETURN => 1 }
      ),
      PLAIN_SEARCH_FORM => 1
    });
  }

  return 1 if $FORM{MESSAGE_ONLY};

  if ($show_add_form) {

    $TEMPLATE_ARGS{TYPE_ID_SELECT} = _cablecat_cross_types_select({
      SELECTED => $TEMPLATE_ARGS{TYPE_ID} || $FORM{TYPE_ID},
      REQUIRED => 1
    });

    $TEMPLATE_ARGS{WELL_ID_SELECT} = _cablecat_wells_select({
      SELECTED => $TEMPLATE_ARGS{WELL_ID} || $FORM{WELL_ID},
      REQUIRED => 1
    });

    if ($TEMPLATE_ARGS{POINT_ID}) {
      $TEMPLATE_ARGS{OBJECT_INFO} = cablecat_make_point_info($TEMPLATE_ARGS{POINT_ID});
    }

    if ($TEMPLATE_ARGS{ID}) {
      $TEMPLATE_ARGS{CROSS_LINKS_TABLE} = _cablecat_cross_links_table($TEMPLATE_ARGS{ID}, \%TEMPLATE_ARGS);
    }

    my $color_id = $TEMPLATE_ARGS{COLOR_SCHEME_ID} || $FORM{COLOR_SCHEME_ID};
    my $fibers_colors_select = _cablecat_color_scheme_select({ SELECTED => $color_id });

    $html->tpl_show(_include('cablecat_cross', 'Cablecat'), {
      %TEMPLATE_ARGS,
      %FORM,
      SUBMIT_BTN_ACTION      => ($FORM{chg}) ? 'change' : 'add',
      SUBMIT_BTN_NAME        => ($FORM{chg}) ? $lang{CHANGE} : $lang{ADD},
      COLOR_SCHEME_ID_SELECT => $fibers_colors_select,
    });
  }

  return 1 if ($FORM{TEMPLATE_ONLY});

  result_former({
    INPUT_DATA      => $Cablecat,
    FUNCTION        => 'crosses_list',
    BASE_FIELDS     => 0,
    DEFAULT_FIELDS  => 'ID,NAME,TYPE,WELL,POINT_ID',
    HIDDEN_FIELDS   => 'TYPE_ID,WELL_ID',
    FUNCTION_FIELDS => 'change,del',
    SKIP_USER_TITLE => 1,
    EXT_FIELDS      => 0,
    EXT_TITLES      => {
      id             => '#',
      name           => $lang{NAME},
      type           => $lang{TYPE},
      well           => $lang{WELL},
      point_id       => $lang{MAP},
      cross_type_id  => $lang{CROSS_TYPE},
      panel_type_id  => $lang{PANEL_TYPE},
      rack_height    => $lang{RACK_HEIGHT},
      ports_count    => $lang{PORTS_COUNT},
      ports_type_id  => $lang{PORTS_TYPE},
      polish_type_id => $lang{POLISH_TYPE},
      fiber_type_id  => $lang{FIBER_TYPE},
    },
    SELECT_VALUE    => {
      cross_type_id  => \%CROSS_CROSS_TYPE,
      panel_type_id  => \%CROSS_PANEL_TYPE,
      ports_type_id  => \%CROSS_PORT_TYPE,
      polish_type_id => \%CROSS_POLISH_TYPE,
      fiber_type_id  => \%CROSS_FIBER_TYPE,
    },
    FILTER_COLS     => {
      point_id => '_cablecat_result_former_point_id_filter:' . $MAP_LAYER_ID{WELL},
      type     => '_cablecat_result_former_named_chg_link_filter::PARAM_NAME=type_id,FUNCTION=cablecat_cross_types,TYPE_ID',
      well     => '_cablecat_result_former_named_chg_link_filter::PARAM_NAME=well_id,FUNCTION=cablecat_wells,WELL_ID'
    },
    TABLE           => {
      width   => '100%',
      caption => $lang{CROSSES},
      ID      => 'CROSSES_TABLE',
      EXPORT  => 1,
      MENU    => "$lang{ADD}:index=$index&add_form=1:add;$lang{SEARCH}:index=$index&search_form=1:search"
    },
    MAKE_ROWS       => 1,
    SEARCH_FORMER   => 1,
    MODULE          => 'Cablecat',
    TOTAL           => 1
  });
}

#**********************************************************
=head2 cablecat_reserve()

=cut
#**********************************************************
sub cablecat_reserve {

  if ($FORM{chg}) {
    my $reserve_info = $Cablecat->coil_list({
      ID     => $FORM{chg},
      NAME   => '_SHOW',
      LENGTH => '_SHOW',
    });

    $html->tpl_show(
      _include('cablecat_reserve', 'Cablecat'),
      {
        %FORM,
        ID                => $FORM{chg},
        NAME              => $reserve_info->[0]{name} || "",
        LENGTH            => $reserve_info->[0]{length} || "",
        SUBMIT_BTN_ACTION => "change",
        SUBMIT_BTN_NAME   => $lang{CHANGE},
      }
    );
  }

  if ($FORM{change}) {
    $Cablecat->coil_change({
      ID     => $FORM{ID},
      NAME   => $FORM{NAME},
      LENGTH => $FORM{LENGTH},
    });
    show_result($Cablecat, $lang{CHANGED});
  }

  if ($FORM{del} && $FORM{COMMENTS}) {
    $Cablecat->coil_del({ ID => $FORM{del}, COMMENTS => $FORM{COMMENTS} });
    show_result($Cablecat, $lang{DELETED});
  }

  my AXbills::HTML $table;
  result_former(
    {
      INPUT_DATA      => $Cablecat,
      FUNCTION        => 'coil_list',
      BASE_FIELDS     => 0,
      DEFAULT_FIELDS  => 'ID,NAME,LENGTH',
      HIDDEN_FIELDS   => 'CABLE_ID,POINT_ID',
      FUNCTION_FIELDS => 'change,del',
      SKIP_USER_TITLE => 1,
      EXT_FIELDS      => 0,
      EXT_TITLES      => {
        id     => '#',
        name   => $lang{NAME},
        length => $lang{LENGTH},
      },
      TABLE           => {
        width   => '100%',
        caption => $lang{CABLE_RESERVE},
        ID      => 'RESERVE_TABLE',
        EXPORT  => 1,
        #        MENU    => "$lang{ADD}:index=$index&add_form=1:add;$lang{SEARCH}:index=$index&search_form=1:search"
      },
      MAKE_ROWS       => 1,
      TOTAL           => 1,
      SEARCH_FORMER   => 1,
      MODULE          => 'Cablecat',
    }
  );

  #  $table ? print $table->show() : return 0;

  return 0;
}

#**********************************************************
=head2 _cablecat_cross_links($cross_id, $port_num)

=cut
#**********************************************************
sub _cablecat_cross_links {
  my ($cross_id, $port_num) = @_;

  my %TEMPLATE_ARGS = (
    CROSS_ID   => $cross_id,
    CROSS_PORT => $port_num,
  );

  my $show_add_form = $FORM{add_form} || 0;

  if ($FORM{add}) {
    my $encoded_link_value = "$FORM{NAS_ID}#@#$FORM{PORT}";

    $Cablecat->cross_links_add({
      CROSS_ID   => $cross_id,
      CROSS_PORT => $port_num,
      LINK_TYPE  => 1,
      LINK_VALUE => $encoded_link_value
    });

    if (show_result($Cablecat, $lang{ADDED})) {
      return 2;
    };
  }
  elsif ($FORM{change}) {
    $Cablecat->cross_links_change({
      %FORM,
      _CHANGE_PARAM => 'CROSS_ID',
      SECOND_PARAM  => 'CROSS_PORT'
    });
    show_result($Cablecat, $lang{CHANGED});

    return 2;
  }
  elsif ($FORM{chg}) {
    my $tp_info = $Cablecat->cross_links_info($FORM{chg});
    if (!_error_show($Cablecat)) {

      %TEMPLATE_ARGS = (%TEMPLATE_ARGS, %{$tp_info});

      # should split
      my $encoded_link_value = $tp_info->{link_value};
      my ($nas_id, $nas_port) = split('#@#', $encoded_link_value || '');

      $TEMPLATE_ARGS{EQUIPMENT_ID} = $nas_id;
      $TEMPLATE_ARGS{EQUIPMENT_PORT} = $nas_port;

      $show_add_form = 1;
    }
  }
  elsif ($FORM{del} && $FORM{COMMENTS}) {
    $Cablecat->cross_links_del(
      { COMMENTS => $FORM{COMMENTS} },
      { cross_id => $cross_id, cross_port => $port_num });
    show_result($Cablecat, $lang{DELETED});

    # Show main cross form
    return 2;
  }

  my $info = $Cablecat->crosses_info($cross_id, { NAME => '_SHOW', SHOW_ALL_COLUMNS => 0, COLS_UPPER => 0 });

  $TEMPLATE_ARGS{CROSS_NAME} = $info->{name} || q{};
  $TEMPLATE_ARGS{EQUIPMENT_SELECT} = $html->form_select(
    'NAS_ID',
    {
      VALUE             => $TEMPLATE_ARGS{EQUIPMENT_ID} || '',
      SEL_KEY           => 'nas_id',
      SEL_VALUE         => 'nas_name',
      SEL_OPTIONS       => { '' => '' },
      MAIN_MENU         => get_function_index('form_nas'),
      # Popup window
      POPUP_WINDOW      => 'form_search_nas',
      POPUP_WINDOW_TYPE => 'search',
      SEARCH_STRING     => 'POPUP=1&NAS_SEARCH=0',
      HAS_NAME          => 1
    }
  );

  if (in_array('Equipment', \@MODULES)) {
    $TEMPLATE_ARGS{EQUIPMENT_PORT_SELECT} = $html->form_select(
      'PORT',
      {
        VALUE             => $TEMPLATE_ARGS{EQUIPMENT_PORT} || '',
        POPUP_WINDOW      => 'form_search_port',
        POPUP_WINDOW_TYPE => 'choose',
        SEARCH_STRING     => 'get_index=equipment_info&visual=0&header=2&PORT_SHOW=1&PORT_INPUT_NAME=PORT',
        PARENT_INPUT      => 'NAS_ID'
      }
    );
  }
  else {
    $TEMPLATE_ARGS{EQUIPMENT_PORT_SELECT} = $html->form_input('PORT', $TEMPLATE_ARGS{EQUIPMENT_PORT} || '',
      { SIZE => 10, TYPE => 'text' }
    );
  }

  $html->tpl_show(_include('cablecat_cross_link_add', 'Cablecat'),
    {
      %TEMPLATE_ARGS,
      SUBMIT_BTN_ACTION => ($FORM{chg}) ? 'change' : 'add',
      SUBMIT_BTN_NAME   => ($FORM{chg}) ? $lang{CHANGE} : $lang{ADD},
    }
  );

  return 1;
}

#**********************************************************
=head2 _cablecat_cross_links_table($cross_id)

=cut
#**********************************************************
sub _cablecat_cross_links_table {
  my ($cross_id, $cross_info) = @_;
  return '' if (!$cross_id || !$cross_info || !$cross_info->{PORTS_COUNT});

  my $links = $Cablecat->cross_links_list({
    CROSS_ID         => $cross_id,
    SHOW_ALL_COLUMNS => 1,
    SORT             => 'cross_port',
    PAGE_ROWS        => 10000,
  });
  _error_show($Cablecat) and return 0;

  my AXbills::HTML $table = $html->table({
    caption     => "$lang{CROSS} $lang{LINKS}",
    title_plain => [ $lang{PORT}, $lang{LINK} ],
    pages       => $Cablecat->{TOTAL},
    ID          => 'CROSS_LINKS_ID'
  });

  # Order links by port_num;
  my %link_for_port = map {$_->{cross_port} => $_} @{$links};
  my $crosses_index = get_function_index('cablecat_crosses');

  for (my $i = 1; $i <= $cross_info->{PORTS_COUNT}; $i++) {
    $table->addrow(
      $i,
      _cablecat_cross_link_info($link_for_port{$i}, $i, $cross_id, { CROSSES_INDEX => $crosses_index })
    );
  }

  return $table->show({ OUTPUT2RETURN => 1 });
}

#**********************************************************
=head2 _cablecat_cross_link_info($link, $port_num, $cross_id, $attr)

  Arguments:
   $link     - db row for cross_link
   $port_num - cross port num
   $cross_id - cross id
   $attr
     CROSS_ID
     CROSSES_INDEX

=cut
#**********************************************************
sub _cablecat_cross_link_info {
  my ($link, $port_num, $cross_id, $attr) = @_;

  my $crosses_index = $attr->{CROSSES_INDEX} || get_function_index('cablecat_crosses');

  if (!defined($link) || !defined($link->{link_type})) {
    return $html->button('',
      "index=$crosses_index&cross_link_operation=1&add_form=1&CROSS_ID=$cross_id&CROSS_PORT=$port_num", {
        ICON   => 'fa fa-plus',
        TARGET => 'cablecat_cross_link_add',
        BUTTON => 1
      }
    );
  }
  else {
    if ($link->{link_type} == 1) {
      # Equipment
      my ($equipment_id, $equipment_port) = split('#@#', $link->{link_value} || '');

      if (!$equipment_id && !$equipment_port) {
        $html->message('err', "Wrong link for port number $port_num (" . ($link->{link_value} || '') . ")");
        return '';
      }

      my $Equipment_info = Equipment->new($db, $admin, \%conf);
      $Equipment_info->_info($equipment_id);
      my $Equipment_name = $Equipment_info->_list({
        NAS_ID   => $equipment_id,
        NAS_NAME => "_SHOW",
      });
      $Equipment_name = $Equipment_name->[0][0] || '';

      my $equipment_name = $Equipment_info->{SYSTEM_ID} || '';
      my $equipment_link = function_button($equipment_name, 'equipment_info', $equipment_id, { ID_PARAM => 'NAS_ID' });

      my $change_button = $html->button('',
        "index=$crosses_index&cross_link_operation=1&chg=1&CROSS_ID=$cross_id&CROSS_PORT=$port_num", {
          ICON   => 'fa fa-pencil-alt',
          class  => 'btn btn-xs btn-secondary',
          TARGET => 'cablecat_cross_link_add',
        });

      my $del_button = $html->button('',
        "index=$crosses_index&cross_link_operation=1&del=1&CROSS_ID=$cross_id&CROSS_PORT=$port_num", {
          class   => 'btn btn-xs btn-danger',
          MESSAGE => "$lang{DEL} ?",
          ICON    => 'fa fa-times',
        });

      return $change_button . $del_button . ($equipment_link . " $lang{PORT} : $equipment_port") . ",  $lang{EQUIPMENT} : $Equipment_name";
    }

    return $link->{link_type} . '_' . $link->{link_value}
  }
}

#**********************************************************
=head2 _cablecat_connecter_commutation_list($connecter_id, $well_id)

  Arguments:
    $connecter_id - int, Cablecat connecter id
    $well_id      - int, Cablecat well id

  Returns:
    string - HTML, form to create new commutation
    
=cut
#**********************************************************
sub _cablecat_connecter_commutation_list {
  my ($connecter_id, $well_id) = @_;

  return '' if (!$connecter_id || ref $connecter_id) || (!$well_id || ref $well_id);

  my $commutation_index = get_function_index('cablecat_commutations');
  my $commutation_view_index = get_function_index('cablecat_commutation');

  my $commutations_list = $Cablecat->commutations_list({
    CONNECTER_ID => $connecter_id,
    CREATED      => '_SHOW',
    CABLE_IDS    => '_SHOW',
    NAME         => '_SHOW'
  });

  my $table = $html->table({
    width               => '100%',
    caption             => $lang{COMMUTATION},
    border              => 1,
    title               => [ '#', $lang{NAME}, $lang{CREATED}, '' ],
    qs                  => $pages_qs,
    ID                  => 'CONNECTER_COMMUTATION_TABLE_ID',
    REFRESH             => 1,
    HAS_FUNCTION_FIELDS => 1
  });

  foreach my $commutation (@$commutations_list) {
    $commutation->{cable_ids} //= '';

    my $name = $commutation->{name} || "$lang{COMMUTATION}#$commutation->{id}";
    $table->addrow(
      $commutation->{id},
      $html->button($name, "index=$commutation_view_index&ID=$commutation->{id}", { TITLE => "$lang{CABLES} $commutation->{cable_ids} " }),
      $commutation->{created},
      $html->button('', "qindex=$commutation_index&del=$commutation->{id}", {
        class   => 'del',
        MESSAGE => "$lang{DEL} $name",
        AJAX    => 'CABLECAT_CREATE_COMMUTATION_FORM'
      }),
    );
  }

  my $cables_checkboxes_form = _cablecat_well_cables_checkbox_form($well_id);

  my $create_form = $html->form_main({
    ID      => 'CABLECAT_CREATE_COMMUTATION_FORM',
    class   => 'form form-horizontal ajax-submit-form',
    CONTENT => join($FORM{json} ? ', ' : '', @$cables_checkboxes_form),
    HIDDEN  => {
      add          => 1,
      index        => $commutation_index,
      CONNECTER_ID => $connecter_id,
    },
    SUBMIT  => { add => $lang{CREATE_COMMUTATION}, }
  });

  return join($FORM{json} ? ', ' : '', ($table->show(), $create_form));

}

#**********************************************************
=head2 _cablecat_well_cables_checkbox_form($well_id)

=cut
#**********************************************************
sub _cablecat_well_cables_checkbox_form {
  my ($well_id, $attr) = @_;

  $attr //= {};

  my $checked = ($attr->{CHECKED}) ? $attr->{CHECKED} : [];
  my $skip = ($attr->{SKIP}) ? $attr->{SKIP} : [];

  my $cables_list = $Cablecat->get_cables_for_well({ WELL_ID => $well_id });

  if (!_error_show($Cablecat) && scalar @{$cables_list}) {

    $cables_list = [ grep {!in_array($_->{id}, $skip)} @{$cables_list} ] if $attr->{SKIP};

    # Render list of checkboxes
    my $wells_index = get_function_index('cablecat_wells');
    my @cable_inputs = map {
      my ($id, $name, $well_1_id, $well_2_id) = ($_->{id}, $_->{name}, $_->{well_1_id}, $_->{well_2_id});

      # Cable have two ends.
      # Here we are determining which one does'nt belong to this connecter's well
      my $is_second_well_id = ($well_1_id == $well_id) ? 1 : 0;
      my $other_end_id = $is_second_well_id ? $well_2_id : $well_1_id;
      my $other_end_name = $is_second_well_id ? $_->{well_2} : $_->{well_1};

      $name .= " ( " . $html->button($other_end_name, "index=$wells_index&chg=$other_end_id") . " )";

      $html->tpl_show(
        templates('form_row_checkbox'),
        {
          INPUT => $html->form_input('CABLE_IDS', $id, { TYPE => 'checkbox', STATE => $attr->{CHECKED} ? in_array($id, $checked) : 0 }),
          NAME  => $name
        },
        { OUTPUT2RETURN => 1 }
      );
    } @{$cables_list};

    return \@cable_inputs;
  }
  else {
    return [ 'No cables' ];
  }

  return [];
}


#**********************************************************
=head2 _cablecat_connecter_linked_connecters($connecter_id)

  Arguments:
    $connecter_id - int, Cablecat connecter id

  Returns:
    string - HTML, list of links

=cut
#**********************************************************
sub _cablecat_connecter_linked_connecters {
  my ($connecter_id) = @_;
  return if (!$connecter_id || ref $connecter_id);

  my $links_out = $Cablecat->connecters_links_list(
    {
      CONNECTER_1_ID => $connecter_id,
      CONNECTER_2_ID => '>0',
      CONNECTER_1    => '_SHOW',
      CONNECTER_2    => '_SHOW',
      PAGE_ROWS      => 10000
    }
  );
  _error_show($Cablecat);

  my $links_in = $Cablecat->connecters_links_list(
    {
      CONNECTER_1_ID => '>0',
      CONNECTER_2_ID => $connecter_id,
      CONNECTER_1    => '_SHOW',
      CONNECTER_2    => '_SHOW',
      PAGE_ROWS      => 10000
    }
  );
  _error_show($Cablecat);

  if (scalar @{$links_in} || scalar @{$links_out}) {
    my @links_for_connecter = ();
    push(@links_for_connecter, map {$html->button($_->{connecter_1}, "index=$index&chg=$_->{connecter_1_id}")} @{$links_in});

    push(@links_for_connecter, map {$html->button($_->{connecter_2}, "index=$index&chg=$_->{connecter_2_id}")} @{$links_out});

    return join($html->br(), @links_for_connecter);
  }

  return '';
}

#**********************************************************
=head2 _cablecat_well_connecters($well_id)
  
  Arguments:
    $well_id - int, Cablecat well id

  Returns:
    string - HTML - list of links

=cut
#**********************************************************
sub _cablecat_well_connecters {
  my ($well_id) = @_;
  return if (!$well_id || ref $well_id);

  my $connecters_inside = $Cablecat->connecters_list({
    WELL_ID => $well_id,
    TYPE    => '_SHOW',
    NAME    => '_SHOW'
  });

  if (!_error_show($Cablecat)) {
    my $connecters_index = get_function_index('cablecat_connecters');

    my @connecters_links = map {
      $html->button("$_->{name} (#$_->{id})", "index=$connecters_index&chg=$_->{id}")
        . $html->button('', "qindex=$connecters_index&change=1&ID=$_->{id}&PARENT_ID=0", {
        ICON    => 'fa fa-times',
        class   => 'text-danger',
        CONFIRM => "$lang{UNLINK}?",
        AJAX    => 'form_CABLECAT_CONNECTERS'
      })
    } @{$connecters_inside};

    my $connecters_list = join($html->br(), @connecters_links);
    my $add_connecter_btn = $html->button($lang{CREATE}, "index=$connecters_index&add_form=1&WELL_ID=$well_id", {
      ID => 'add_connecter'
    });

    return $html->element('div', $connecters_list, { id => 'WELL_CONNECTERS_LIST' })
      . $html->element('div', $add_connecter_btn, { id => 'WELL_CONNECTERS_ADD_BUTTON_WRAPPER' });
  }

  return '';
}

#**********************************************************
=head2 _cablecat_well_cable_links($well_id)
  
  Arguments:
    $well_id - int, Cablecat Well id

  Returns:
    string - HTML, list of links
    
=cut
#**********************************************************
sub _cablecat_well_cable_links {
  my ($well_id) = @_;
  return if (!$well_id || ref $well_id);

  # Can be optimized with 'well_1=%ID% OR well_2=%ID%' when possible in search former
  my $cables_out = $Cablecat->cables_list({
    WELL_1_ID   => $well_id,
    WELL_2_ID   => '_SHOW',
    NAME        => '_SHOW',
    POINT_ID    => '_SHOW',
    WELL_1      => '_SHOW',
    WELL_2      => '_SHOW',
    POLYLINE_ID => '_SHOW',
  });
  _error_show($Cablecat);

  my $cables_in = $Cablecat->cables_list({
    WELL_2_ID   => $well_id,
    WELL_1_ID   => '_SHOW',
    NAME        => '_SHOW',
    POINT_ID    => '_SHOW',
    WELL_1      => '_SHOW',
    WELL_2      => '_SHOW',
    POLYLINE_ID => '_SHOW',
  });
  _error_show($Cablecat);

  my $cables_index = get_function_index('cablecat_cables');

  my $well_cable_row = sub {
    my ($cable, $linked_well_name, $linked_well_id) = @_;
    $Auxiliary->maps_show_object_button($MAP_LAYER_ID{CABLE}, $cable->{point_id}, {
      POINT_ID => ($cable->{polyline_id} ? $cable->{point_id} : 0),
    })
      . '&nbsp;' . $html->button($cable->{name}, "index=$cables_index&chg=$cable->{id}")
      . ' -> '
      . ($linked_well_id
      ? $html->button($linked_well_name, "index=$index&chg=$linked_well_id")
      : $lang{NO})
  };

  my @cables_for_well = ();
  if (scalar @{$cables_in}) {
    push(@cables_for_well,
      map { $well_cable_row->($_, $_->{well_1}, $_->{well_1_id}); } @{$cables_in});
  }
  if (scalar @{$cables_out}) {
    push(@cables_for_well,
      map { $well_cable_row->($_, $_->{well_2}, $_->{well_2_id}); } @{$cables_out});
  }

  return join($html->br(), @cables_for_well);
}

#**********************************************************
=head2 _cablecat_get_closest_well($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub _cablecat_get_closest_well {
  my ($attr) = @_;

  my ($coordx, $coordy) = split(':', $attr->{COORDS});
  my $wells = $Cablecat->closest_wells({ COORDX => $coordx, COORDY => $coordy });

  return 0 if !$Cablecat->{TOTAL} || $Cablecat->{TOTAL} < 2 || $wells->[0]{coords_difference} == $wells->[1]{coords_difference};
  return 0 if $wells->[0]{coords_difference} > 0.00003;

  return $wells->[0];
}

#**********************************************************
=head2 _cablecat_storage_installations($cable_id)

=cut
#**********************************************************
sub cablecat_storage_installations {
  my ($object_id, $type) = @_;

  return '' if !$object_id || !$type;
  return '' if !in_array('Storage', \@MODULES) || ($admin->{MODULES} && !$admin->{MODULES}{Storage});

  my $installation_function_index = get_function_index('storage_main');
  return '' if !$installation_function_index;

  my $installations = $Cablecat->cablecat_storage_installation_list({
    ARTICLE_TYPE_NAME => '_SHOW',
    OBJECT_ID         => $object_id,
    TYPE              => $type,
    ARTICLE_NAME      => '_SHOW',
    COUNT             => '_SHOW',
    DATE              => '_SHOW',
    INSTALLATION_ID   => '_SHOW',
    COLS_NAME         => 1
  });

  my $storage_table = $html->table({
    width   => '100%',
    caption => $lang{INSTALLATIONS},
    title   => [ $lang{TYPE}, $lang{NAME}, $lang{COUNT}, $lang{DATE}, '-' ],
    ID      => 'STORAGE_ID'
  });

  foreach my $installation (@{$installations}) {
    my $installation_btn = $html->button($installation->{article_name}, "index=$installation_function_index" .
      "&show_installation=1&chg_installation=1&ID=$installation->{installation_id}", { class => 'change' });
    $storage_table->addrow($installation->{article_type_name}, $installation->{article_name}, $installation->{count},
      $installation->{date}, $installation_btn);
  }

  return $storage_table->show({ OUTPUT2RETURN => 1 });
}

#**********************************************************
=head2 _cablecat_storage_installation_template($attr)

=cut
#**********************************************************
sub _cablecat_storage_installation_template {
  my ($attr) = @_;

  return {} if (!in_array('Storage', \@MODULES) || $FORM{chg} || ($admin->{MODULES} && !$admin->{MODULES}{Storage}));

  load_module('Storage', $html);
  my $Storage = Storage->new($db, $admin, \%conf);

  my %result = ();
  $result{STORAGE_STORAGES} = storage_storage_sel($Storage, { DOMAIN_ID => ($admin->{DOMAIN_ID} || undef) });
  $result{ARTICLE_ID} = storage_articles_sel($Storage, { ARTICLE_ID => $FORM{ARTICLE_ID}, EMPTY_SEL => 1 });
  $result{ARTICLE_TYPES} = $html->form_select('ARTICLE_TYPE_ID', {
    SELECTED    => $FORM{ARTICLE_TYPE_ID} || $Storage->{ARTICLE_TYPE_ID},
    SEL_LIST    => $Storage->storage_types_list({ COLS_NAME => 1, DOMAIN_ID => ($admin->{DOMAIN_ID} || undef) }),
    SEL_OPTIONS => { '' => '--' },
    EX_PARAMS   => "onchange='selectArticles(this, false, false);'",
    MAIN_MENU   => get_function_index('storage_articles_types')
  });

  return \%result;
}

1;