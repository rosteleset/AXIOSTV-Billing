package Cablecat::Maps_info;

=head1 NAME

  Cablecat::Maps_info - info for map

=head1 VERSION

  VERSION: 1.00
  REVISION: 20201021

=cut

use strict;
use warnings FATAL => 'all';
use parent qw(Exporter);

our $VERSION = 1.00;

our (
  $admin,
  $CONF,
  $lang,
  $html,
  $db
);
my ($Cablecat, $Maps, $Auxiliary);

our %MAP_TYPE_ID = (
  'WELL'      => 1,
  'WIFI'      => 2,
  'BUILD'     => 3,
  'ROUTE'     => 4,
  'CONNECTER' => 5,
  'SPLITTER'  => 6,
  'CABLE'     => 7,
  'EQUIPMENT' => 8,
  'PILLAR'    => 9,
);

#**********************************************************
=head2 new()

=cut
#**********************************************************
sub new {
  my $class = shift;
  $db = shift;
  $admin = shift;
  $CONF = shift;
  my $attr = shift;

  my $self = { db => $db, admin => $admin, conf => $CONF };

  bless($self, $class);

  $html = $attr->{HTML} if $attr->{HTML};
  $lang = $attr->{LANG} if $attr->{LANG};

  require Cablecat;
  Cablecat->import();
  $Cablecat = Cablecat->new($db, $admin, $CONF);

  require Maps;
  Maps->import();
  $Maps = Maps->new($db, $admin, $CONF);

  require Maps::Auxiliary;
  Maps::Auxiliary->import();
  $Auxiliary = Maps::Auxiliary->new($db, $admin, $CONF, { HTML => $html, LANG => $lang });

  return $self;
}

#**********************************************************
=head2 maps_layers()

=cut
#**********************************************************
sub maps_layers {
  return {
    LAYERS  => [ {
      id              => '10',
      name            => 'CABLES',
      lang_name       => $lang->{CABLES},
      module          => 'Cablecat',
      structure       => 'POLYLINE',
      clustering      => 0,
      add_func        => 'cablecat_cables',
      custom_params   => {
        OBJECT_TYPE_ID   => $MAP_TYPE_ID{CABLE},
        SAVE_AS_GEOMETRY => 1
      },
      export_function => 'maps_cables'
    }, {
      id              => '11',
      name            => 'WELLS',
      lang_name       => $lang->{WELLS},
      module          => 'Cablecat',
      structure       => 'MARKER',
      clustering      => 1,
      add_func        => 'cablecat_wells',
      custom_params   => {
        OBJECT_TYPE_ID => $MAP_TYPE_ID{WELL}
      },
      export_function => 'maps_wells'
    } ]
  }
}

#**********************************************************
=head2 maps_wells()

=cut
#**********************************************************
sub maps_wells {
  my $self = shift;
  my ($attr) = @_;

  my $wells_list = $Cablecat->wells_with_coords({
    POINT_ID  => $attr->{OBJECT_ID} || $attr->{POINT_ID} || '!',
    NAME      => '_SHOW',
    TYPE_ID   => '_SHOW',
    ICON      => '_SHOW',
    COMMENTS  => '_SHOW',
    PAGE_ROWS => $attr->{NEW_OBJECT} ? 1 : 99999
  });
  ::_error_show($Cablecat);

  return $Cablecat->{TOTAL} if $attr->{ONLY_TOTAL};

  my $user_points = _cablecat_get_user_points();
  my $equipment_points = _cablecat_get_equipment_points();
  my $wells_index = ::get_function_index('cablecat_wells');
  my $reserve_index = ::get_function_index('cablecat_reserve');
  my @layer_objects = ();

  foreach my $well (@{$wells_list}) {
    my $icon_name = $well->{icon} || 'well_green';
    my $marker_info = $self->_cablecat_get_cable_info({ %{$well}, well_index => $wells_index });

    $marker_info = _cablecat_user_trace($user_points, $well->{ids}) . $marker_info;
    $marker_info = _cablecat_equipment_trace($equipment_points, $well->{ids}) . $marker_info;

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
  ::_error_show($Cablecat);

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
  ::_error_show($Maps);

  my $points_by_id = ();
  foreach my $point (@{$points_list}) {
    next unless ($point && $point->{id});
    $points_by_id->{$point->{id}} = $point;
  }

  my $coil_by_point_id = ();
  foreach my $coil (@{$coils_list}) {
    next unless ($coil && $coil->{point_id});
    $coil_by_point_id->{$coil->{id}} = $coil;
  }

  foreach (@object_ids) {
    my $coil = $coil_by_point_id->{$_};
    my $point = $points_by_id->{$_};

    next if (!($point->{coordx} && $point->{coordy}));
    next if !$coil;

    my $marker_info = _cablecat_info_table([
      [ $lang->{CABLE_RESERVE}, $html->button($coil->{name}, "index=$reserve_index&chg=$coil->{id}", { target => '_blank' }) ],
      [ $lang->{INSTALLED}, $point->{planned} ? $lang->{NO} : $lang->{YES} ],
      [ $lang->{CABLE} . " Id", $coil->{cable_id} ],
      [ $lang->{LENGTH}, $coil->{length} ],
    ]);

    $marker_info .= qq{
      <button class="btn btn-danger" onclick="showRemoveConfirmModal({ layer_id : 11, id : $point->{id} })">
        <span class="fa fa-times"></span><span>$lang->{DEL}</span>
      </button>
    } if ($main::permissions{5} && $attr->{EDIT_MODE});

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
        TYPE      => "coil",
        SIZE      => [ 25, 25 ],
        CENTERED  => 1,
      },
      LAYER_ID  => 11
    }
  }

  my $export_string = JSON::to_json(\@layer_objects, { utf8 => 0 });
  if ($attr->{RETURN_JSON}) {
    print $export_string;
    return 1;
  }

  return $export_string;
}

#**********************************************************
=head2 maps_cables()

=cut
#**********************************************************
sub maps_cables {
  my $self = shift;
  my ($attr) = @_;

  my $new_cable_list = $Cablecat->cable_list_with_points($attr);

  return $Cablecat->{TOTAL} if $attr->{ONLY_TOTAL};

  my $well_index = ::get_function_index('cablecat_wells');
  my $cables_index = ::get_function_index('cablecat_cables');
  my $add_inside_link = "$main::SELF_URL?get_index=cablecat_wells&header=2&add_reserve_form=1";
  my $add_well_link = "$main::SELF_URL?get_index=cablecat_cables&header=2&add_well=1";

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

    my $line_info = _cablecat_info_table([
      [ $lang->{CABLE}, $html->button($cable->{name}, "index=$cables_index&chg=$cable->{cable_id}", { target => '_blank' }) ],
      [ $lang->{CABLE_TYPE}, $cable->{cable_type} ],
      [ "$lang->{WELL} 1", ($cable->{well_1} && $cable->{well_1_id})
        ? $html->button($cable->{well_1}, "index=$well_index&chg=$cable->{well_1_id}", { target => '_blank' })
        . $Auxiliary->maps_show_object_button(11, $cable->{well_1_point_id}, { SHOW_IN_MAP => 1 })
        : $lang->{NO}
      ],
      [ "$lang->{WELL} 2", ($cable->{well_2} && $cable->{well_2_id})
        ? $html->button($cable->{well_2}, "index=$well_index&chg=$cable->{well_2_id}", { target => '_blank' })
        . $Auxiliary->maps_show_object_button(11, $cable->{well_2_point_id}, { SHOW_IN_MAP => 1 })
        : $lang->{NO}
      ],
      [ $lang->{LENGTH}, "$cable->{length}, ( $cable->{length_calculated} )" ],
      [ $lang->{COMMENTS}, $cable->{comments} ],
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
    $polyline->{POLYLINE}{CABLE_CAT} = "<span class='fa fa-scissors'></span><span> $lang->{CAT_CABLE}</span>";
    $polyline->{ID} = $cable->{cable_id};
    $polyline->{POLYLINE}{CABLE_ID} = $cable->{cable_id};
    $polyline->{OBJECT_ID} = $cable->{point_id};

    push @objects_to_show, $polyline;
  }

  my $export_string = JSON::to_json(\@objects_to_show, { utf8 => 0 });
  if ($attr->{RETURN_JSON}) {
    print $export_string;
    return 1;
  }

  return $export_string;
}

#**********************************************************
=head2 maps_report_info()

=cut
#**********************************************************
sub maps_report_info {
  my $self = shift;
  my $layer_id = shift;

  return '' if !$layer_id;

  return _maps_cables_report_info() if ($layer_id eq '10');
  return _maps_wells_report_info() if ($layer_id eq '11');
}

#**********************************************************
=head2 _maps_cables_report_info()

=cut
#**********************************************************
sub _maps_cables_report_info {
  my $self = shift;

  my $cables = $Cablecat->cable_list_with_points();

  my $report_table = $html->table({
    width       => '100%',
    caption     => $lang->{CABLES},
    title_plain => [ '#', $lang->{NAME}, $lang->{TYPE}, $lang->{LENGTH}, $lang->{CREATED}, $lang->{LOCATION} ],
    DATA_TABLE  => 1
  });

  my $cables_index = ::get_function_index('cablecat_cables');
  foreach my $cable (@{$cables}) {
    my $location_btn = $Auxiliary->maps_show_object_button(10, $cable->{point_id});
    my $cable_btn = $html->button($cable->{id}, "index=$cables_index&chg=$cable->{id}");
    $report_table->addrow($cable_btn, $cable->{name}, $cable->{cable_type},
      $cable->{length_calculated}, $cable->{created}, $location_btn);
  }

  return $report_table->show();
}

#**********************************************************
=head2 _maps_wells_report_info()

=cut
#**********************************************************
sub _maps_wells_report_info {
  my $wells = $Cablecat->wells_with_coords({
    POINT_ID  => '!',
    NAME      => '_SHOW',
    TYPE_ID   => '_SHOW',
    ICON      => '_SHOW',
    COMMENTS  => '_SHOW',
    GROUP_BY  => 'GROUP BY cw.id',
    PAGE_ROWS => 99999
  });

  my $report_table = $html->table({
    width       => '100%',
    caption     => $lang->{WELLS},
    title_plain => [ '#', $lang->{NAME}, $lang->{TYPE}, $lang->{CREATED}, $lang->{LOCATION} ],
    DATA_TABLE  => 1
  });

  my $wells_index = ::get_function_index('cablecat_wells');
  foreach my $well (@{$wells}) {
    my $location_btn = $Auxiliary->maps_show_object_button(11, $well->{point_id});
    my $well_btn = $html->button($well->{ids}, "index=$wells_index&chg=$well->{ids}");
    $report_table->addrow($well_btn, $well->{names}, ::_translate($well->{type_name}), $well->{created}, $location_btn);
  }

  return $report_table->show();
}

#**********************************************************
=head2 _cablecat_get_equipment_points()

=cut
#**********************************************************
sub _cablecat_get_equipment_points {

  my $equipment_points = {};
  my $equipment_info = $Cablecat->commutation_equipment_list({
    PARENT_ID  => '_SHOW',
    NAS_ID     => '_SHOW',
    MODEL_NAME => '_SHOW',
    MODEL_ID   => '_SHOW',
    COLS_NAME  => 1,
  });
  return $equipment_points if !$Cablecat || $Cablecat->{TOTAL} < 1;

  foreach my $equipment (@{$equipment_info}) {
    next if !$equipment->{parent_id};

    push(@{$equipment_points->{$equipment->{parent_id}}}, $equipment);
  }

  return $equipment_points;
}

#**********************************************************
=head2 _cablecat_get_user_points()

=cut
#**********************************************************
sub _cablecat_get_user_points {

  my $user_points = {};
  my $onu_info = $Cablecat->commutation_onu_list({
    PARENT_ID  => '_SHOW',
    SERVICE_ID => '_SHOW',
    UID        => '_SHOW',
    COLS_NAME  => 1,
  });

  return $user_points if !$Cablecat || $Cablecat->{TOTAL} < 1;

  foreach my $onu (@{$onu_info}) {
    next if !$onu->{parent_id};
    push @{$user_points->{$onu->{parent_id}}}, $onu;
  }

  return $user_points;
}

#**********************************************************
=head2 _cablecat_user_trace($user_points, $id)

=cut
#**********************************************************
sub _cablecat_user_trace {
  my ($user_points, $id) = @_;

  my @ids = split /\|\|/, $id;

  my $user_table = $html->table({
    width       => '100%',
    caption     => $lang->{USERS},
    title_plain => [ 'UID', "$lang->{SERVICE} ID", $lang->{TRACE_UP_TO} ]
  });

  my $have_user = 0;
  my $trace_index = ::get_function_index('cablecat_user_trace_connection_form');

  foreach my $id (@ids) {
    my $onu_info = $user_points->{$id};
    next if (!$onu_info);

    foreach my $onu (@$onu_info) {
      next if (!$onu->{uid});

      $have_user = 1;

      my $link = "?qindex=$trace_index&header=2&UID=$onu->{uid}&USER_SERVICE=$onu->{service_id}&AJAX=1&action=1";
      my $button = qq{
         <button class="btn btn-info btn-sm" title='TRACE UID: $onu->{uid} ($onu->{service_id})'
           onclick="Routes.showRouteFromONUtoOLT(this,'$link')">
            <span class="fa fa-eye"></span>
          </button>
        };
      $user_table->addrow($onu->{uid}, $onu->{service_id}, $button);
    }
  }

  return $have_user ? $user_table->show() : '';
}

#**********************************************************
=head2 _cablecat_equipment_trace($equipment_points, $id)

=cut
#**********************************************************
sub _cablecat_equipment_trace {
  my ($equipment_points, $id) = @_;

  my @ids = split /\|\|/, $id;

  my $equipment_table = $html->table({
    width       => '100%',
    caption     => $lang->{EQUIPMENT},
    title_plain => [ '#', $lang->{MODEL}, $lang->{TRACE_UP_TO} ]
  });

  my $have_equipment = 0;
  my $trace_index = ::get_function_index('cablecat_equipment_trace');

  foreach my $id (@ids) {
    my $equipments = $equipment_points->{$id};
    next if (!$equipments);

    foreach my $equipment (@{$equipments}) {
      $have_equipment = 1;

      my $link = "?qindex=$trace_index&header=2&NAS_ID=$equipment->{nas_id}&AJAX=1&action=1";
      my $button = qq{
         <button class="btn btn-info btn-sm" title='TRACE NAS: #$equipment->{nas_id}'
           onclick="Routes.showRouteFromOLT(this,'$link')">
            <span class="fa fa-eye"></span>
          </button>
        };
      $equipment_table->addrow($equipment->{nas_id}, $equipment->{model_name}, $button);
    }
  }

  return $have_equipment ? $equipment_table->show() : '';
}

#**********************************************************
=head2 _cablecat_get_cable_info()

=cut
#**********************************************************
sub _cablecat_get_cable_info {
  my $self = shift;
  my ($attr) = @_;

  my $marker_info = '';
  my $edit_buttons = '';
  my @names;
  my @ids;
  my @pictures;
  my @commutations = ();

  return '' if !$attr->{total} || $attr->{total} < 0;

  if ($attr->{total} && $attr->{total} < 2) {
    push @names, $attr->{names};
    push @ids, $attr->{ids};
    push @pictures, $attr->{pictures};
  }
  else {
    @names = split('\|\|', $attr->{names});
    @ids = split('\|\|', $attr->{ids});
    @pictures = split('\|\|', $attr->{pictures});
  }

  if ($attr->{commutations}) {
    my @commutations_list = split(',\s?', $attr->{commutations});
    foreach my $commutation (@commutations_list) {
      push(@commutations, $html->button("#$commutation", "get_index=cablecat_commutation&ID=$commutation&full=1", { target => '_blank' }));
    }
  }

  my @objects;
  for (my $i = 0; $i < $attr->{total}; $i++) {
    push @objects, {
      well         => $names[$i],
      installed    => $attr->{planned} ? $lang->{NO} : $lang->{YES},
      comments     => $attr->{comments},
      id           => $ids[$i],
      commutations => join(', ', @commutations),
      picture      => !$pictures[$i] ? '' : $html->button($html->element('img', '', { src => '/images/cablecat/' . $pictures[$i], class => 'w-100' }),
        '', { target => '_blank', GLOBAL_URL => '/images/cablecat/' . $pictures[$i] })
    }
  }

  $marker_info = $Auxiliary->maps_point_info_table({
    OBJECTS           => \@objects,
    TABLE_TITLES      => [ 'WELL', 'INSTALLED', 'COMMUTATIONS', 'PICTURE', 'COMMENTS' ],
    TABLE_LANG_TITLES => [ $lang->{WELL}, $lang->{INSTALLED}, $lang->{COMMUTATIONS}, $lang->{PICTURE}, $lang->{COMMENTS} ],
    LINK_ITEMS        => {
      'well' => {
        'index'        => $attr->{well_index},
        'EXTRA_PARAMS' => {
          'chg' => 'id',
        }
      },
    }
  });

  if ($main::permissions{5}) {
    my $add_inside_link = "$main::SELF_URL?get_index=cablecat_wells&header=2&add_form=1&TEMPLATE_ONLY=1";

    $edit_buttons = qq{
          <button class="btn btn-success btn-sm"
           onclick="Configuration.addAnotherWell('$add_inside_link','$attr->{point_id}')">
            <span class="fa fa-plus"></span><span>$lang->{ADD}</span>
          </button>
        };
  }

  return $marker_info .= $edit_buttons;
}

#**********************************************************
=head2 _cablecat_info_table($lines_array)

=cut
#**********************************************************
sub _cablecat_info_table {
  my ($lines_array) = @_;

  my $table = '<table class="table table-hover">';

  $table .= join('', map {"<tr><td><strong>" . ($_->[0] || q{}) . "</strong></td><td>" . ($_->[1] || q{}) . ' </td></tr>'} @{$lines_array});

  $table .= '</table>'
}

1;