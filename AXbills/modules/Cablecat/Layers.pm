#package Cablecat::Layers;
use strict;
use warnings FATAL => 'all';

=head1 NAME

  Cablecat::Layers

=head2 SYNOPSIS

  This package aggregates Maps integration

=cut

our (%lang, $html, %permissions, $Cablecat, $Maps, %MAP_TYPE_ID, %MAP_LAYER_ID);

#**********************************************************
=head2 cablecat_maps_layers()

=cut
#**********************************************************
sub cablecat_maps_layers {
  return {
    LAYERS      => [
      {
        id            => 10,
        name          => 'CABLES',
        lang_name     => $lang{CABLES},
        module        => 'Cablecat',
        structure     => 'POLYLINE',
        clustering    => 0,
        add_func      => 'cablecat_cables',
        custom_params => {
          OBJECT_TYPE_ID               => $MAP_TYPE_ID{CABLE},
          SAVE_AS_GEOMETRY             => 1,
          CALCULATE_PARAMS_JS_FUNCTION => 'findClosestWellsForCable'
        }
      }, {
      id            => 11,
      name          => 'WELLS',
      lang_name     => $lang{WELLS},
      module        => 'Cablecat',
      structure     => 'MARKER',
      clustering    => 1,
      add_func      => 'cablecat_wells',
      custom_params => {
        OBJECT_TYPE_ID => $MAP_TYPE_ID{WELL}
      }
    }
    ],
    SCRIPTS     => [ '/styles/default_adm/js/maps/modules/cablecat.js' ],
    EXPORT_FUNC => {
      10 => 'cablecat_maps2_cables',
      11 => 'cablecat_maps_wells',
    }
  }
}

#**********************************************************
=head2 cablecat_maps_cables_geometry_filter($object_id, $objects_array)

=cut
#**********************************************************
sub cablecat_maps_cables_geometry_filter {
  my ($object_id, $geometry) = @_;

  # Sanitize input
  if (!$object_id
    || !ref $geometry eq 'ARRAY'
    || !scalar(@{$geometry})
    || !$geometry->[0]->{TYPE}
    || !$geometry->[0]->{TYPE} eq 'polyline'
    || !$geometry->[0]->{OBJECT}
    || !$geometry->[0]->{OBJECT}->{POINTS}
    || !ref $geometry->[0]->{OBJECT}->{POINTS} eq 'ARRAY'
    || !scalar(@{$geometry->[0]->{OBJECT}->{POINTS}})
  ) {
    return $geometry;
  };

  # Normally cable will receive only one polyline
  my @polyline_points = @{$geometry->[0]->{OBJECT}->{POINTS}};

  my $cables_list = $Cablecat->cables_list({
    POINT_ID  => $object_id,
    WELL_1_ID => '_SHOW',
    WELL_2_ID => '_SHOW',
  });

  if ($cables_list && ref $cables_list eq 'ARRAY' && scalar @{$cables_list}) {

    # Caching well_id_coords
    my %well_coords = ();

    my $get_cached_coords_for_well = sub {
      my ($well_id) = @_;

      if (!exists $well_coords{$well_id}) {
        my $coords = $Cablecat->wells_coords($well_id);
        $well_coords{$well_id} = [ $coords->{coordx}, $coords->{coordy} ];
      }

      $well_coords{$well_id};
    };

    # Normally, there should be only one object, but should be ready
    foreach my $cable (@{$cables_list}) {
      if ($cable->{well_1_id}) {
        $polyline_points[0] = $get_cached_coords_for_well->($cable->{well_1_id});
      }

      if ($cable->{well_2_id}) {
        $polyline_points[$#polyline_points] = $get_cached_coords_for_well->($cable->{well_2_id});
      }
    }
  }

  $geometry->[0]->{OBJECT}->{POINTS} = \@polyline_points;

  return $geometry;
}

#**********************************************************
=head2 cablecat_maps_wells()

=cut
#**********************************************************
sub cablecat_maps_wells {

  my $wells_list = $Cablecat->wells_with_coords({
    POINT_ID  => $FORM{LAST_OBJECT_ID} ? "> $FORM{LAST_OBJECT_ID}" : $FORM{OBJECT_ID} || $FORM{POINT_ID} || '!',
    NAME      => '_SHOW',
    TYPE_ID   => '_SHOW',
    ICON      => '_SHOW',
    COMMENTS  => '_SHOW',
    PAGE_ROWS => 10000
  });
  _error_show($Cablecat);

  my $wells_index = get_function_index('cablecat_wells');
  my $reserve_index = get_function_index('cablecat_reserve');
  my @layer_objects = ();

  foreach my $well (@{$wells_list}) {
    my $icon_name = $well->{icon} || 'well_green';
    my $marker_info = _cablecat_get_cable_info({ %{$well}, well_index => $wells_index });

    push @layer_objects, {
      ID        => +$well->{ids},
      OBJECT_ID => $well->{point_id},
      MARKER    => {
        OBJECT_ID => $well->{point_id},
        NAME      => $well->{names},
        ID        => +$well->{ids},
        COORDX    => $well->{coordx},
        COORDY    => $well->{coordy},
        INFO      => "$marker_info",
        TYPE      => "$icon_name",
        LAYER_ID  => 11,
        SIZE      => [ 25, 25 ],
        CENTERED  => 1,
      },
      LAYER_ID  => 11
    }
  }

  # Coil information
  my $coils_list = $Cablecat->coil_list({
    POINT_ID  => '_SHOW',
    NAME      => '_SHOW',
    CABLE_ID  => '_SHOW',
    LENGTH    => '_SHOW',
    ID        => '_SHOW',
    PAGE_ROWS => 10000
  });
  _error_show($Cablecat);

  my @object_ids = map {$_->{point_id}} @{$coils_list};
  my $point_ids = join(';', @object_ids);
  my $points_list = $Maps->points_list({
    ID               => $point_ids,
    SHOW_ALL_COLUMNS => 1,
    NAME             => '_SHOW',
    ICON             => '_SHOW',
    TYPE             => '_SHOW',
    TYPE_ID          => '_SHOW',
    COORDX           => '!',
    COORDY           => '!',
    COLS_NAME        => 1,
    ADDRESS_FULL     => '_SHOW',
    EXTERNAL         => 1,
  });
  _error_show($Maps);

  my $points_by_id = sort_array_to_hash($points_list);
  my $coil_by_point_id = sort_array_to_hash($coils_list, 'point_id');
  foreach (@object_ids) {
    my $coil = $coil_by_point_id->{$_};
    my $point = $points_by_id->{$_};

    my $icon_name = 'coil';

    next if (!($point->{coordx} && $point->{coordy}));

    my $marker_info = '';
    my $edit_buttons = '';
    $marker_info = arrays_array2table([
      [ $lang{CABLE_RESERVE}, $html->button($coil->{name}, "index=$reserve_index&chg=$coil->{id}", { target => '_blank' }) ],
      [ $lang{INSTALLED}, $point->{planned} ? $lang{NO} : $lang{YES} ],
      [ $lang{CABLE} . " Id", $coil->{cable_id} ],
      [ $lang{LENGTH}, $coil->{length} ],
    ]);

    if ($permissions{5} && $FORM{EDIT_MODE}) {

      $edit_buttons = qq{
          <button class="btn btn-danger" onclick="showRemoveConfirmModal({ layer_id : 11, id : $point->{id} })">
            <span class="glyphicon glyphicon-remove"></span><span>$lang{DEL}</span>
          </button>
        };
    }

    $marker_info .= $edit_buttons;

    push @layer_objects, {
      ID        => 9999 + $coil->{id},
      OBJECT_ID => $point->{id},
      MARKER    => {
        OBJECT_ID => $point->{id},
        NAME      => $coil->{name},
        ID        => +$coil->{id},
        COORDX    => $point->{coordx},
        COORDY    => $point->{coordy},
        INFO      => "$marker_info",
        TYPE      => "$icon_name",
        SIZE      => [ 25, 25 ],
        CENTERED  => 1,
      },
      LAYER_ID  => 11
    }
  }

  if ($FORM{RETURN_JSON}) {
    print "[" . join(',', map {JSON::to_json($_, { utf8 => 0 })} @layer_objects) . "]";
    return 1;
  }

  return join(',', map {JSON::to_json($_, { utf8 => 0 })} @layer_objects);
}

#**********************************************************
=head2 cablecat_maps_ajax()

=cut
#**********************************************************
sub cablecat_maps_ajax {

  if ($FORM{SPLIT_CABLE} && $FORM{CABLE_ID}) {
    push(@{$html->{JSON_OUTPUT}}, {
      result => _cablecat_break_cable_in_two_parts($FORM{CABLE_ID})
    });
  }

  return 1;
}

#**********************************************************
=head2 _cablecat_get_cable_info()

=cut
#**********************************************************
sub _cablecat_get_cable_info {
  my ($attr) = @_;

  my $marker_info = '';
  my $edit_buttons = '';
  my @names;
  my @ids;

  return '' if !$attr->{total} || $attr->{total} < 0;

  if ($attr->{total} && $attr->{total} < 2) {
    push @names, $attr->{names};
    push @ids, $attr->{ids}
  }
  else {
    @names = split('\|\|', $attr->{names});
    @ids = split('\|\|', $attr->{ids});
  }

  my @objects;
  for (my $i = 0; $i < $attr->{total}; $i++) {
    push @objects, {
      well      => $names[$i],
      installed => $attr->{planned} ? $lang{NO} : $lang{YES},
      comments  => $attr->{comments},
      id        => $ids[$i],
    }
  }

  $marker_info = maps2_point_info_table({
    OBJECTS           => \@objects,
    TABLE_TITLES      => [ 'WELL', 'INSTALLED', 'COMMENTS' ],
    TABLE_LANG_TITLES => [ $lang{WELL}, $lang{INSTALLED}, $lang{COMMENTS} ],
    LINK_ITEMS        => {
      'well' => {
        'index'        => $attr->{well_index},
        'EXTRA_PARAMS' => {
          'chg' => 'id',
        }
      },
    }
  });

  if ($permissions{5}) {
    my $add_inside_link = "$SELF_URL?get_index=cablecat_wells&header=2"
      . "&add_form=1&TEMPLATE_ONLY=1";

    $edit_buttons = qq{
          <button class="btn btn-success btn-sm"
           onclick="Configuration.addAnotherWell('$add_inside_link','$attr->{point_id}')">
            <span class="glyphicon glyphicon-plus"></span><span>$lang{ADD}</span>
          </button>
        };
  }

  return $marker_info .= $edit_buttons;
}

#**********************************************************
=head2 cablecat_maps2_cables()

=cut
#**********************************************************
sub cablecat_maps2_cables {

  my $new_cable_list = $Cablecat->cable_list_with_points(\%FORM);

  # Caching indexes
  my $well_index = get_function_index('cablecat_wells');
  my $cables_index = get_function_index('cablecat_cables');
  my $add_inside_link = "$SELF_URL?get_index=cablecat_wells&header=2&add_reserve_form=1";
  my $add_well_link = "$SELF_URL?get_index=cablecat_cables&header=2&add_well=1";

  my @objects_to_show = ();

  foreach my $cable (@{$new_cable_list}) {
    my $polyline = ();
    my @points = split(',', $cable->{coords});
    foreach my $point (@points) {
      my @point_array = split('\|', $point);
      push @{$polyline->{POLYLINE}{POINTS}}, \@point_array;
    }

    $cable->{name} =~ s/’/\'/g;

    $polyline->{POLYLINE}{NAME} = $cable->{name} || '';
    $polyline->{POLYLINE}{COMMENTS} = $cable->{comments} || '';
    $polyline->{POLYLINE}{STROKECOLOR} = $cable->{outer_color};
    $polyline->{POLYLINE}{STROKEWEIGHT} = $cable->{line_width} || 1;

    my $line_info = arrays_array2table([
      [ $lang{CABLE}, $html->button($cable->{name}, "index=$cables_index&chg=$cable->{id}", { target => '_blank' }) ],
      [ $lang{CABLE_TYPE}, $cable->{cable_type} ],
      [ "$lang{WELL} 1", ($cable->{well_1} && $cable->{well_1_id})
        ? $html->button($cable->{well_1}, "index=$well_index&chg=$cable->{well_1_id}", { target => '_blank' })
        . maps2_show_object_button(11, $cable->{well_1_point_id}, { SHOW_IN_MAP => 1 })
        : $lang{NO}
      ],
      [ "$lang{WELL} 2", ($cable->{well_2} && $cable->{well_2_id})
        ? $html->button($cable->{well_2}, "index=$well_index&chg=$cable->{well_2_id}", { target => '_blank' })
        . maps2_show_object_button(11, $cable->{well_2_point_id}, { SHOW_IN_MAP => 1 })
        : $lang{NO}
      ],
      [ $lang{LENGTH}, "$cable->{length}, ( $cable->{length_calculated} )" ],
      [ $lang{COMMENTS}, $cable->{comments} ],
    ]);

    $cable->{well_1_point_id} ||= '';
    $cable->{well_2_point_id} ||= '';

    $polyline->{POLYLINE}{INFOWINDOW} = $line_info;
    $polyline->{POLYLINE}{LAYER_ID} = 10;
    $polyline->{POLYLINE}{ID} = $cable->{cable_id};
    $polyline->{POLYLINE}{OBJECT_ID} = $cable->{point_id};
    $polyline->{POLYLINE}{REFERENCE_OBJECTS}{LAYER_ID} = 11;
    $polyline->{POLYLINE}{REFERENCE_OBJECTS}{OBJECTS} = [ $cable->{well_1_point_id}, $cable->{well_2_point_id} ];
    $polyline->{LAYER_ID} = 10;
    $polyline->{POLYLINE}{INSIDE_LINK} = $add_inside_link;
    $polyline->{POLYLINE}{ADD_WELL_LINK} = $add_well_link;
    $polyline->{POLYLINE}{CABLE_CAT} = "<span class='glyphicon glyphicon-scissors'></span><span> $lang{CAT_CABLE}</span>";
    $polyline->{ID} = $cable->{cable_id};
    $polyline->{POLYLINE}{CABLE_ID} = $cable->{cable_id};
    $polyline->{OBJECT_ID} = $cable->{point_id};

    push @objects_to_show, $polyline;
  }

  if ($FORM{RETURN_JSON}) {
    print "[" . (join ',', map {JSON::to_json($_, { utf8 => 0 })} @objects_to_show) . "]";
    return 1;
  }

  return join ',', map {JSON::to_json($_, { utf8 => 0 })} @objects_to_show;
}

1;