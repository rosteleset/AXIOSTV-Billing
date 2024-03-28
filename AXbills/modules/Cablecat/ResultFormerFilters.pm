use strict;
use warnings FATAL => 'all';

use v5.16;

our (
  $Cablecat, $Maps, $html, %lang, %conf, $admin, $db,
  @CABLECAT_EXTRA_COLORS, @CABLECAT_COLORS,
  %MAP_TYPE_ID, %MAP_LAYER_ID,
  %permissions
);

use Maps::Auxiliary;
my $Auxiliary = Maps::Auxiliary->new($db, $admin, \%conf, { HTML => $html, LANG => \%lang });

#**********************************************************
=head2 _cablecat_result_former_color_scheme_filter()

=cut
#**********************************************************
sub _cablecat_result_former_color_scheme_filter {
  my ($colors_text) = @_;
  return '' if (!$colors_text);

  my @colors_raw = split(',', $colors_text);

  my @colors = map {'#' . $_} @colors_raw;

  my $i = 1;
  my $create_colored_div = sub {
    my $text = $conf{CABLECAT_COLOR_SCHEME_NUMBERS} ? $i++ : '&nbsp;&nbsp;&nbsp;';
    my $color = $_;

    if ($_ =~ /\+$/) {
      if ($conf{CABLECAT_COLOR_SCHEME_NUMBERS}) {
        $text .= '+';
      }
      else {
        $text = '+';
      }

      ($color) = $_ =~ /(.*)\+/;
    }

    return $html->element('div', $text, { style => "display: inline-block; padding: 3px 5px; background-color : $color; color: white" });
  };

  return join('', map {$create_colored_div->($_)} @colors);
}

#**********************************************************
=head2 _cablecat_result_former_point_id_filter()

  Arguments:
    $point_id - Maps object id
    $attr     - hash ref
      PARAMS - arr ref
        0  - layer_id

=cut
#**********************************************************
sub _cablecat_result_former_point_id_filter {
  my ($point_id, $attr) = @_;

  state $map_points_by_id;
  if (!defined $map_points_by_id) {
    my $points_list = $Maps->points_list({
      COORDX    => '_SHOW',
      COORDY    => '_SHOW',
      EXTERNAL  => 1,
      PAGE_ROWS => 10000
    });
    $map_points_by_id = sort_array_to_hash($points_list);
  }
  state $map_index = undef;
  if (!$map_index) {
    $map_index = get_function_index('maps_main');
  }

  my $layer_id = ($attr && $attr->{PARAMS} && $attr->{PARAMS}->[0]) ? $attr->{PARAMS}->[0] : 1;

  if ($point_id) {
    my $link = "index=$map_index&LAYER=$layer_id&OBJECT_ID=$point_id";
    my $icon = 'fa fa-globe';

    # If have location, we can show it on map
    if (!$map_points_by_id->{$point_id}{coordx} || !$map_points_by_id->{$point_id}{coordy}) {
      $icon = 'fa fa-map-marker-alt';
      $link .= '&ADD_POINT=1'
    }

    return $html->button('', $link, { ICON => $icon });
  }
  # If no object defined, propose to add it
  else {
    return '';
  }

}

#**********************************************************
=head2 _cablecat_result_former_cable_point_id_filter($point_id)

=cut
#**********************************************************
sub _cablecat_result_former_cable_point_id_filter {
  my ($point_id, $attr) = @_;

  return '' if (!$point_id);

  my $polyline_id = $attr->{VALUES}{POLYLINE_ID};

  $Maps->points_info($point_id);
  return '' if !$Maps->{TOTAL};

  return $Auxiliary->maps_show_object_button($MAP_LAYER_ID{CABLE}, $point_id, {
    GO_TO_MAP => 1,
    POINT_ID  => $point_id,
    SINGLE    => $point_id,
    ADD_POINT => $polyline_id ? '' : 1
  })
}

#**********************************************************
=head2 _cablecat_result_former_parent_id_filter()

=cut
#**********************************************************
sub _cablecat_result_former_parent_id_filter {
  my $well_id = shift;
  return '' unless ($well_id);

  # Next block should be called only once
  state $well_by_id = undef;
  if (!$well_by_id) {
    my $well_list = $Cablecat->wells_list({ ID => '_SHOW', NAME => '_SHOW', COLS_NAME => 1 });
    _error_show($Cablecat);

    $well_by_id = sort_array_to_hash($well_list);
  }

  my $well = $well_by_id->{$well_id};
  return '' unless (defined $well);

  return $html->button($well->{name}, "index=" . get_function_index('cablecat_wells') . "&chg=$well->{id}", {});
}

#**********************************************************
=head2 _cablecat_result_former_named_chg_link_filter($names, $attr)

  Result former function to make links from raw name.
  
  Arguments:
    $names - string or comma separated strings for button(s)_name (object name(s))
    $attr  -
      VALUES
        FUNCTION     - function to go
        PARAM_NAME   - name of VALUES key, to read id(s) from
        %PARAM_NAME% - value(s) for id
        
  Returns:
    html - link(s) to FUNCTION with chg=%ID%

=cut
#**********************************************************
sub _cablecat_result_former_named_chg_link_filter {
  my ($names, $attr) = @_;

  return '' unless $names;

  my %params = %{$attr->{VALUES}};
  my $function = $params{FUNCTION};

  if (!exists $params{PARAM_NAME} || !exists $params{uc $params{PARAM_NAME}}) {
    return ''
  }

  my @ids = split(',\s?', $params{uc $params{PARAM_NAME}});
  my @names = split(',\s?', $names);

  my $index = get_function_index($function);

  my @links = ();
  for (my $i = 0; $i <= $#ids; $i++) {
    push(@links, $html->button($names[$i], "index=$index&chg=$ids[$i]", {}));
  }

  return join(', ', @links);
}

#**********************************************************
=head2 _cablecat_result_former_icon_filter()

=cut
#**********************************************************
sub _cablecat_result_former_icon_filter {
  my ($icon_name) = @_;

  my $folder = '/images/maps/icons/';

  $icon_name .= '.png' if ($icon_name !~ /\.png$/);

  return "<img src='$folder$icon_name' alt='$icon_name' />";
}

1;