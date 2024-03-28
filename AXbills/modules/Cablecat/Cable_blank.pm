=head1 NAME

  Cable_blank

=cut

use strict;
use warnings;
use GD::Simple;
use utf8;
use AXbills::Base qw(_bp in_array);
use Cablecat;
use Encode;

our (%FORM, $db, %conf, $admin, %lang, %CROSS_PORT_TYPE, %CROSS_POLISH_TYPE, %CROSS_FIBER_TYPE);
our Cablecat $Cablecat;
our AXbills::HTML $html;
our @port_types = ('', 'RJ45', 'GBIC', 'Gigabit', 'SFP', 'QSFP', 'EPON', 'GPON', 'SFP-RJ45');

my %OBJECTS = ();

my %SCHEME_OPTIONS = (
  PORT_WIDTH          => 40,
  PORT_HEIGHT         => 20,

  HEADER_WIDTH        => 300,
  HEADER_HEIGHT       => 50,

  PAGE_WIDTH          => 1050,
  PAGE_HEIGHT         => 1515,
  PAGE_INDENT         => 35,
  PAGE_PADDING_BOTTOM => 20,
  PAGE_PADDING_TOP    => 20,

  X_LEFT              => 20,
  START_Y             => 40,
  START_Y_LEFT        => 20,
  START_Y_RIGHT       => 20,

  OBJECT_INDENT       => 20,
  OBJECT_NUMBER_WIDTH => 50,

  LINK_INDENT         => 7,
);
$SCHEME_OPTIONS{PORT_HEIGHT_TEXT_CENTER} = $SCHEME_OPTIONS{PORT_HEIGHT} / 1.5;
$SCHEME_OPTIONS{LEFT_LINK_X} = $SCHEME_OPTIONS{X_LEFT} + $SCHEME_OPTIONS{HEADER_WIDTH} + 8;
$SCHEME_OPTIONS{X_RIGHT} = $SCHEME_OPTIONS{PAGE_WIDTH} - $SCHEME_OPTIONS{HEADER_WIDTH} - 25;
$SCHEME_OPTIONS{RIGHT_LINK_X} = $SCHEME_OPTIONS{X_RIGHT} - 8;

my %CABLE_OPTIONS = (
  ADDRESS_COLUMN_WIDTH => 110,
  MODULES_COLUMN_WIDTH => 70
);
$CABLE_OPTIONS{COLOR_COLUMN_WIDTH} = $SCHEME_OPTIONS{HEADER_WIDTH} - ($CABLE_OPTIONS{ADDRESS_COLUMN_WIDTH} +
  $CABLE_OPTIONS{MODULES_COLUMN_WIDTH} + $SCHEME_OPTIONS{PORT_WIDTH});

my %SPLITTER_OPTIONS = (
  ATTENUATION_COLUMN_WIDTH => 70,
  TYPE_COLUMN_WIDTH        => 70
);
$SPLITTER_OPTIONS{COLOR_COLUMN_WIDTH} = $SCHEME_OPTIONS{HEADER_WIDTH} - ($SPLITTER_OPTIONS{ATTENUATION_COLUMN_WIDTH} +
  $SPLITTER_OPTIONS{TYPE_COLUMN_WIDTH} + $SCHEME_OPTIONS{PORT_WIDTH});

my %CROSS_OPTIONS = (
  FIBER_TYPE_COLUMN_WIDTH  => 70,
  POLISH_TYPE_COLUMN_WIDTH => 88,
  PORT_TYPE_COLUMN_WIDTH   => 70
);
$CROSS_OPTIONS{COLOR_COLUMN_WIDTH} = $SCHEME_OPTIONS{HEADER_WIDTH} - ($CROSS_OPTIONS{FIBER_TYPE_COLUMN_WIDTH} +
  $CROSS_OPTIONS{POLISH_TYPE_COLUMN_WIDTH} + $CROSS_OPTIONS{PORT_TYPE_COLUMN_WIDTH} + $SCHEME_OPTIONS{PORT_WIDTH});

my %EQUIPMENT_OPTIONS = (
  PORT_TYPE_COLUMN_WIDTH => 130,
  COLOR_COLUMN_WIDTH     => 130
);

my @PAGES = ();

my $img = ();
my $black = '';

our %CABLE_COLORS = (
  'fcfefc' => 'white',
  '04fefc' => 'sea',
  'fcfe04' => 'yellow',
  '048204' => 'green',
  '840204' => 'brown',
  'fc0204' => 'red',
  'fc9a04' => 'orange',
  'fc9acc' => 'pink',
  '848284' => 'gray',
  '0402fc' => 'blue',
  '840284' => 'violet',
  '040204' => 'black',
  '04fe04' => 'yellowgreen',
  '9cce04' => 'olive',
  'fcfe9c' => 'beige',
  'dbefdb' => 'natural',
  'fde910' => 'lemon',
  '9c3232' => 'cherry',
);

#**********************************************************
=head2 show_box ()

=cut
#**********************************************************
sub show_box {

  push @PAGES, {
    X       => 0,
    Y       => 0,
    Y_LEFT  => 10,
    Y_RIGHT => 10,
    WIDTH   => $SCHEME_OPTIONS{PAGE_WIDTH},
    HEIGHT  => $SCHEME_OPTIONS{PAGE_HEIGHT} - $SCHEME_OPTIONS{PAGE_PADDING_BOTTOM},
  };

  my $commutation_info = $Cablecat->commutations_info($FORM{ID});
  $OBJECTS{CABLE} = _get_cables();
  $OBJECTS{SPLITTER} = _get_splitters();
  $OBJECTS{CROSS} = _get_crosses();
  $OBJECTS{EQUIPMENT} = _get_equipments();

  my $last_side = 'RIGHT';
  foreach my $key (sort keys %OBJECTS) {
    foreach my $object (values %{$OBJECTS{$key}}) {
      my $new_side = $last_side eq 'LEFT' ? 'RIGHT' : 'LEFT';
      size_calculations($object, $new_side);
      $last_side = $new_side;
    }
  }

  my $last_page = $PAGES[-1];
  $img = GD::Simple->new($SCHEME_OPTIONS{PAGE_WIDTH} + 5, $last_page->{Y} + $SCHEME_OPTIONS{PAGE_HEIGHT} + 5);
  $img->font('Italic');
  $img->fontsize(10);
  my $count = 1;
  foreach my $page (@PAGES) {
    $img->rectangle($page->{X}, $page->{Y}, $SCHEME_OPTIONS{PAGE_WIDTH}, $page->{Y} + $SCHEME_OPTIONS{PAGE_HEIGHT});
    $img->moveTo($SCHEME_OPTIONS{PAGE_WIDTH} - 40, $page->{Y} + 20);
    $img->string("AXbills");

    if ($commutation_info->{NAME}) {
      $img->moveTo($page->{X} + 20, $page->{Y} + $SCHEME_OPTIONS{PAGE_HEIGHT} - 10);
      $img->string($commutation_info->{NAME});
    }

    _print_string($SCHEME_OPTIONS{PAGE_WIDTH} / 2, $page->{Y} + $SCHEME_OPTIONS{PAGE_HEIGHT} - 10, $count);
    $count += 1;
  }

  $img->fontsize(8);
  foreach my $key (sort keys %OBJECTS) {
    foreach my $object (values %{$OBJECTS{$key}}) {
      _draw_base($object);
    }
  }

  print_links();

  open(my $out, '>', 'img.png') or die "Write image $!\n";
  binmode $out;
  print $out $img->png;

  if ($FORM{print} && $FORM{print} == 1) {
    $html->tpl_show(_include('cable_blank_print', 'Cablecat'));
    print qq(<img src="img.png" alt="Smiley face">);

    return 1;
  }

  print qq(<img src="img.png" alt="Smiley face">);

  return;
}

#**********************************************************
=head2 print_links ()

=cut
#**********************************************************
sub print_links {

  $img->penSize(2);
  my $letter_center = $SCHEME_OPTIONS{PAGE_WIDTH} / 2;
  my $commutations = $Cablecat->links_list({ ID => $FORM{COMMUTATION_ID}, SHOW_ALL_COLUMNS => 1, PAGE_ROWS => 10000 });
  foreach my $commutation (@{$commutations}) {
    my $element_1 = $OBJECTS{$commutation->{element_1_type}}{$commutation->{element_1_id}};
    my $element_2 = $OBJECTS{$commutation->{element_2_type}}{$commutation->{element_2_id}};

    next if !$element_1 || !$element_2;

    my $element_1_coords = $element_1->{FIBERS}{$commutation->{fiber_num_1}};
    my $element_2_coords = $element_2->{FIBERS}{$commutation->{fiber_num_2}};

    next if !$element_1_coords || !$element_2_coords;

    my $center_x = $element_1->{SIDE} eq 'LEFT' ?
      $SCHEME_OPTIONS{LEFT_LINK_X} + $SCHEME_OPTIONS{LINK_INDENT} : $SCHEME_OPTIONS{RIGHT_LINK_X} - $SCHEME_OPTIONS{LINK_INDENT};

    if ($element_1_coords->{y} == $element_2_coords->{y}) {
      $img->{fgcolor} = $img->translate_color(unpack('C*', pack('H*', $element_1_coords->{COLOR} || 'cecece')));
      $img->line($element_1_coords->{x}, $element_1_coords->{y}, $center_x, $element_1_coords->{y});
      $img->line($center_x, $element_1_coords->{y}, $element_2_coords->{x}, $element_1_coords->{y});
      next;
    }

    $img->{fgcolor} = $img->translate_color(unpack('C*', pack('H*', $element_1_coords->{COLOR} || 'cecece')));
    $img->line($element_1_coords->{x}, $element_1_coords->{y}, $center_x, $element_1_coords->{y});
    $img->line($center_x, $element_1_coords->{y}, $center_x, ($element_2_coords->{y} + $element_1_coords->{y}) / 2);

    $img->{fgcolor} = $img->translate_color(unpack('C*', pack('H*', $element_2_coords->{COLOR} || 'cecece')));
    $img->line($center_x, ($element_2_coords->{y} + $element_1_coords->{y}) / 2, $center_x, $element_2_coords->{y});
    $img->line($center_x, $element_2_coords->{y}, $element_2_coords->{x}, $element_2_coords->{y});

    if ($element_1->{SIDE} eq 'LEFT') {
      $SCHEME_OPTIONS{LEFT_LINK_X} += $SCHEME_OPTIONS{LINK_INDENT};
    }
    else {
      $SCHEME_OPTIONS{RIGHT_LINK_X} -= $SCHEME_OPTIONS{LINK_INDENT};
    }
  }
}

#**********************************************************
=head2 size_calculations ()

=cut
#**********************************************************
sub size_calculations {
  my ($object, $side, $page_was_created) = @_;

  $object->{FIBERS_COUNT} //= 0;
  my $object_height = ($object->{FIBERS_COUNT} + 1) * $SCHEME_OPTIONS{PORT_HEIGHT} + $SCHEME_OPTIONS{HEADER_HEIGHT};
  my $opposite_side = $side eq 'RIGHT' ? 'LEFT' : 'RIGHT';
  my $has_place = 0;

  foreach my $page (@PAGES) {
    my $object_start_y = $page->{'Y_' . $side} + $SCHEME_OPTIONS{OBJECT_INDENT};
    my $object_end_y = $object_start_y + $object_height;
    if ($object_end_y <= $page->{HEIGHT} + $page->{Y}) {
      $object->{START_Y} = $object_start_y;
      $object->{SIDE} = $side;
      $page->{'Y_' . $side} = $object_end_y;
      $has_place = 1;
      last;
    }

    $object_start_y = $page->{'Y_' . $opposite_side} + $SCHEME_OPTIONS{OBJECT_INDENT};
    $object_end_y = $object_start_y + $object_height;
    if ($object_end_y <= $page->{HEIGHT} + $page->{Y}) {
      $object->{START_Y} = $object_start_y;
      $object->{SIDE} = $opposite_side;
      $page->{'Y_' . $opposite_side} = $object_end_y;
      $has_place = 1;
      last;
    }
  }

  return 0 if $has_place;
  return 0 if $page_was_created;

  my $last_page = $PAGES[-1];
  my $page_y = $last_page->{Y} + $SCHEME_OPTIONS{PAGE_HEIGHT} + $SCHEME_OPTIONS{PAGE_INDENT};
  push @PAGES, {
    X       => 0,
    Y       => $page_y,
    Y_LEFT  => $page_y + 10,
    Y_RIGHT => $page_y + 10,
    WIDTH   => $SCHEME_OPTIONS{PAGE_WIDTH},
    HEIGHT  => $SCHEME_OPTIONS{PAGE_HEIGHT} - $SCHEME_OPTIONS{PAGE_PADDING_BOTTOM},
  };

  size_calculations($object, $side, 1);
}

#**********************************************************
=head2 _get_cables ()

=cut
#**********************************************************
sub _get_cables {
  my %cable_objects = ();
  my $commutation_info = $Cablecat->commutations_info($FORM{ID});

  $commutation_info->{CABLE_IDS} =~ s/,/;/ if ($commutation_info->{CABLE_IDS});
  my $cables_list = $Cablecat->cables_list({
    ID               => $commutation_info->{CABLE_IDS} || '_SHOW',
    SHOW_ALL_COLUMNS => 1,
    PAGE_ROWS        => 10000,
    COLS_UPPER       => 0,
  });

  foreach my $cable (@{$cables_list}) {
    my @fibers_colors = $cable->{fibers_colors} ? split(/,\s?/, $cable->{fibers_colors}) : [];
    my @modules_colors = $cable->{modules_colors} ? split(/,\s?/, $cable->{modules_colors}) : [];

    $cable_objects{$cable->{id}} = {
      FIBERS_COUNT   => $cable->{fibers_count},
      FIBERS_COLORS  => \@fibers_colors,
      MODULES_COUNT  => $cable->{modules_count} || 1,
      MODULES_COLORS => \@modules_colors,
      NAME           => $cable->{name},
      TYPE           => 'cable',
      TYPE_NAME      => $cable->{cable_type},
      FIBERS         => {},
      ID             => $cable->{id}
    };
  }

  return \%cable_objects;
}

#**********************************************************
=head2 _get_splitters ()

=cut
#**********************************************************
sub _get_splitters {
  my %splitter_objects = ();
  my $splitters = $Cablecat->splitters_list({ COMMUTATION_ID => $FORM{ID}, SHOW_ALL_COLUMNS => 1 });

  foreach my $splitter (@{$splitters}) {
    my @fibers_colors = $splitter->{fibers_colors} ? split(/,\s?/, $splitter->{fibers_colors}) : ();
    my @attenuation = $splitter->{attenuation} ? split(/\//, $splitter->{attenuation}) : ();

    $splitter->{fibers_in} //= 0;
    $splitter->{fibers_out} //= 0;

    $splitter_objects{$splitter->{id}} = {
      FIBERS_COUNT  => $splitter->{fibers_in} + $splitter->{fibers_out},
      FIBERS_IN     => $splitter->{fibers_in},
      FIBERS_OUT    => $splitter->{fibers_out},
      FIBERS_COLORS => \@fibers_colors,
      ATTENUATION   => \@attenuation,
      NAME          => $splitter->{name},
      TYPE          => 'splitter',
      TYPE_NAME     => $splitter->{type},
      FIBERS        => {},
      ID            => $splitter->{id}
    };
  }

  return \%splitter_objects;
}

#**********************************************************
=head2 _get_crosses ()

=cut
#**********************************************************
sub _get_crosses {
  my %cross_objects = ();

  my $crosses = $Cablecat->commutation_crosses_list({ COMMUTATION_ID => $FORM{ID}, SHOW_ALL_COLUMNS => 1 });
  foreach my $cross (@{$crosses}) {
    my @fibers_colors = $cross->{fibers_colors} ? split(/,\s?/, $cross->{fibers_colors}) : ();

    $cross_objects{$cross->{cross_id}} = {
      FIBERS_COUNT  => $cross->{port_finish} - $cross->{port_start} + 1,
      FIBER_FINISH  => $cross->{port_finish},
      FIBER_START   => $cross->{port_start},
      FIBERS_COLORS => \@fibers_colors,
      PORT_TYPE     => $CROSS_PORT_TYPE{$cross->{ports_type_id}} || '',
      POLISH_TYPE   => $CROSS_POLISH_TYPE{$cross->{polish_type_id}} || '',
      FIBER_TYPE    => $CROSS_FIBER_TYPE{$cross->{fiber_type_id}} || '',
      NAME          => $cross->{name},
      TYPE          => 'cross',
      # TYPE_NAME      => $splitter->{type},
      FIBERS        => {},
      ID            => $cross->{cross_id}
    };
  }

  return \%cross_objects;
}

#**********************************************************
=head2 _get_equipments ()

=cut
#**********************************************************
sub _get_equipments {
  my %equipment_objects = ();
  my $equipments = $Cablecat->commutation_equipment_list({ COMMUTATION_ID => $FORM{ID}, SHOW_ALL_COLUMNS => 1 });

  foreach my $equipment (@{$equipments}) {
    $equipment_objects{$equipment->{nas_id}} = {
      FIBERS_COUNT => $equipment->{ports},
      PORT_TYPE    => $port_types[$equipment->{ports_type}] || '',
      NAME         => $equipment->{model_name},
      TYPE         => 'equipment',
      FIBERS       => {},
      ID           => $equipment->{nas_id}
    };
  }

  return \%equipment_objects;
}

#**********************************************************
=head2 _draw_base ()

=cut
#**********************************************************
sub _draw_base {
  my $object = shift;

  return if !$object->{START_Y};

  $object->{NAME} .= join(' ', (' (', $object->{TYPE_NAME}, ')')) if $object->{TYPE_NAME};
  $object->{START_X} = $object->{SIDE} && $object->{SIDE} eq 'RIGHT' ? $SCHEME_OPTIONS{X_RIGHT} : $SCHEME_OPTIONS{X_LEFT};
  my $fibers_height = ($object->{FIBERS_COUNT} + 1) * $SCHEME_OPTIONS{PORT_HEIGHT};

  $object->{FIBERS_START_Y} = $object->{START_Y} + $SCHEME_OPTIONS{HEADER_HEIGHT};
  $object->{FIBERS_END_Y} = $object->{FIBERS_START_Y} + $fibers_height;
  my $x_with_header = $object->{START_X} + $SCHEME_OPTIONS{HEADER_WIDTH};

  $img->rectangle($object->{START_X}, $object->{START_Y}, $x_with_header, $object->{FIBERS_START_Y});

  $img->rectangle($object->{START_X}, $object->{START_Y}, $object->{START_X} + $SCHEME_OPTIONS{OBJECT_NUMBER_WIDTH}, $object->{FIBERS_START_Y});

  _print_string($object->{START_X} + $SCHEME_OPTIONS{OBJECT_NUMBER_WIDTH} / 2,
    $object->{START_Y} + $SCHEME_OPTIONS{HEADER_HEIGHT} / 2 + 4, $object->{ID});

  _print_name($object->{START_X} + $SCHEME_OPTIONS{OBJECT_NUMBER_WIDTH}, $object->{START_Y} + $SCHEME_OPTIONS{HEADER_HEIGHT} / 2, $object->{NAME});
  $img->rectangle($x_with_header - $SCHEME_OPTIONS{PORT_WIDTH}, $object->{FIBERS_START_Y}, $x_with_header, $object->{FIBERS_END_Y});

  _print_string($x_with_header - $SCHEME_OPTIONS{PORT_WIDTH} / 2, $object->{FIBERS_START_Y} + $SCHEME_OPTIONS{PORT_HEIGHT_TEXT_CENTER}, $lang{PORT});

  for (my $i = 1; $i <= $object->{FIBERS_COUNT}; $i++) {
    $img->line($x_with_header - $SCHEME_OPTIONS{PORT_WIDTH}, $object->{FIBERS_START_Y} + ($i * $SCHEME_OPTIONS{PORT_HEIGHT}),
      $x_with_header, $object->{FIBERS_START_Y} + ($i * $SCHEME_OPTIONS{PORT_HEIGHT}));

    my $port_num = $object->{FIBER_START} ? $i + $object->{FIBER_START} - 1 : $i;
    _print_string($x_with_header - $SCHEME_OPTIONS{PORT_WIDTH} / 2,
      $object->{FIBERS_START_Y} + ($i * $SCHEME_OPTIONS{PORT_HEIGHT}) + $SCHEME_OPTIONS{PORT_HEIGHT_TEXT_CENTER}, $port_num);

    $object->{FIBERS}{$port_num} = {
      x => $object->{SIDE} && $object->{SIDE} eq 'RIGHT' ? $x_with_header - $SCHEME_OPTIONS{HEADER_WIDTH} : $x_with_header,
      y => $object->{FIBERS_START_Y} + ($i * $SCHEME_OPTIONS{PORT_HEIGHT}) + $SCHEME_OPTIONS{PORT_HEIGHT} / 2
    };
  }

  return '' if !$object->{TYPE};

  my $function_name = $object->{TYPE} . '_print_info';
  return if !defined(&$function_name);

  &{\&{$function_name}}($object);
}

#**********************************************************
=head2 cable_print_info ()

=cut
#**********************************************************
sub cable_print_info {
  my $object = shift;

  my $end_x = $object->{START_X} + $SCHEME_OPTIONS{HEADER_WIDTH} - $SCHEME_OPTIONS{PORT_WIDTH};
  $object->{X_END} = $end_x;

  $end_x = _draw_column_block($object, $end_x, 'MODULES', \%CABLE_OPTIONS);
  $end_x = _draw_column_block($object, $end_x, 'ADDRESS', \%CABLE_OPTIONS);
  $end_x = _draw_column_block($object, $end_x, 'COLOR', \%CABLE_OPTIONS);

  $img->line($object->{START_X}, $object->{FIBERS_START_Y} + $SCHEME_OPTIONS{PORT_HEIGHT},
    $object->{X_END}, $object->{FIBERS_START_Y} + $SCHEME_OPTIONS{PORT_HEIGHT});

  my $fibers_colors = $object->{FIBERS_COLORS};
  @{$fibers_colors} = @{$fibers_colors}[0 .. $object->{FIBERS_COUNT} / $object->{MODULES_COUNT} - 1] if $object->{MODULES_COUNT} != 1;

  for (my $i = 1; $i <= $object->{FIBERS_COUNT}; $i++) {
    $img->line(
      $object->{START_X},
      $object->{FIBERS_START_Y} + $i * $SCHEME_OPTIONS{PORT_HEIGHT},
      $object->{X_END} - $CABLE_OPTIONS{MODULES_COLUMN_WIDTH},
      $object->{FIBERS_START_Y} + $i * $SCHEME_OPTIONS{PORT_HEIGHT}
    );

    my $modules_count = $object->{MODULES_COUNT} == 1 ? $object->{MODULES_COUNT} : $object->{MODULES_COUNT} + 1;
    my $color_index = ($i - 1) % ($#{$fibers_colors} + 1);

    my $fiber_color = $object->{FIBERS_COLORS} && ref $object->{FIBERS_COLORS} eq 'ARRAY' ?
      $fibers_colors->[$color_index] : '';

    $fiber_color = substr($fiber_color, 0, 6);
    $img->bgcolor(unpack('C*', pack('H*', $fiber_color)));
    $img->rectangle(
      $object->{START_X} != $SCHEME_OPTIONS{X_LEFT} ? $object->{START_X} + $SCHEME_OPTIONS{HEADER_WIDTH} + 15 : $object->{START_X} - 15,
      $object->{FIBERS_START_Y} + $i * $SCHEME_OPTIONS{PORT_HEIGHT},
      $object->{START_X} != $SCHEME_OPTIONS{X_LEFT} ? $object->{START_X} + $SCHEME_OPTIONS{HEADER_WIDTH} + 5 : $object->{START_X} - 5,
      $object->{FIBERS_START_Y} + ($i + 1) * $SCHEME_OPTIONS{PORT_HEIGHT}
    );

    $object->{FIBERS}{$i}{COLOR} = $fiber_color;

    $img->bgcolor(unpack('C*', pack('H*', 'ffffff')));
    _print_string(
      $object->{COLOR_X_START} + $CABLE_OPTIONS{COLOR_COLUMN_WIDTH} / 2 - 2,
      $object->{FIBERS_START_Y} + $i * $SCHEME_OPTIONS{PORT_HEIGHT} + $SCHEME_OPTIONS{PORT_HEIGHT_TEXT_CENTER},
      $lang{uc($CABLE_COLORS{$fiber_color} || $fiber_color)} || ''
    );
  }

  my $modules_height = $SCHEME_OPTIONS{PORT_HEIGHT} * ($object->{FIBERS_COUNT} / $object->{MODULES_COUNT});
  for (my $i = 1; $i <= $object->{MODULES_COUNT}; $i++) {
    $img->line(
      $object->{MODULES_X_START},
      $object->{FIBERS_START_Y} + $SCHEME_OPTIONS{PORT_HEIGHT} + $i * $modules_height,
      $object->{MODULES_X_START} + $CABLE_OPTIONS{MODULES_COLUMN_WIDTH},
      $object->{FIBERS_START_Y} + $SCHEME_OPTIONS{PORT_HEIGHT} + $i * $modules_height
    );

    my $module_color = $object->{MODULES_COLORS} && ref $object->{MODULES_COLORS} eq 'ARRAY' ?
      $object->{MODULES_COLORS}[($i - 1) % ($#{$object->{MODULES_COLORS}} + 1)] : '';

    _print_string(
      $object->{MODULES_X_START} + $CABLE_OPTIONS{MODULES_COLUMN_WIDTH} / 2,
      $object->{FIBERS_START_Y} + $SCHEME_OPTIONS{PORT_HEIGHT} + $i * $modules_height - ($modules_height / 2 - 5),
      $lang{uc($CABLE_COLORS{$module_color} || $module_color)} || ''
    );
  }
}

#**********************************************************
=head2 splitter_print_info ()

=cut
#**********************************************************
sub splitter_print_info {
  my $object = shift;

  my $end_x = $object->{START_X} + $SCHEME_OPTIONS{HEADER_WIDTH} - $SCHEME_OPTIONS{PORT_WIDTH};
  $object->{X_END} = $end_x;

  $end_x = _draw_column_block($object, $end_x, 'TYPE', \%SPLITTER_OPTIONS);
  $end_x = _draw_column_block($object, $end_x, 'ATTENUATION', \%SPLITTER_OPTIONS);
  $end_x = _draw_column_block($object, $end_x, 'COLOR', \%SPLITTER_OPTIONS);

  $img->line($object->{START_X}, $object->{FIBERS_START_Y} + $SCHEME_OPTIONS{PORT_HEIGHT},
    $object->{X_END}, $object->{FIBERS_START_Y} + $SCHEME_OPTIONS{PORT_HEIGHT});

  $object->{FIBERS_START_Y} += $SCHEME_OPTIONS{PORT_HEIGHT};

  my $fibers_count = 1;

  return if !$object->{FIBERS_IN} || !$object->{FIBERS_OUT};

  for (my $i = 1; $i <= $object->{FIBERS_IN}; $i++) {
    $img->line(
      $object->{X_END},
      $object->{FIBERS_START_Y} + $i * $SCHEME_OPTIONS{PORT_HEIGHT},
      $object->{START_X},
      $object->{FIBERS_START_Y} + $i * $SCHEME_OPTIONS{PORT_HEIGHT}
    );

    my $text_y_coord = $object->{FIBERS_START_Y} + ($i - 1) * $SCHEME_OPTIONS{PORT_HEIGHT} + $SCHEME_OPTIONS{PORT_HEIGHT_TEXT_CENTER};

    _print_string($object->{TYPE_X_START} + $SPLITTER_OPTIONS{TYPE_COLUMN_WIDTH} / 2 - 2, $text_y_coord, $lang{ENTER});

    my $fiber_color = $object->{FIBERS_COLORS} && ref $object->{FIBERS_COLORS} eq 'ARRAY' ? $object->{FIBERS_COLORS}[$fibers_count - 1] : '';
    _print_string(
      $object->{COLOR_X_START} + $SPLITTER_OPTIONS{COLOR_COLUMN_WIDTH} / 2 - 2,
      $text_y_coord,
      $lang{uc($CABLE_COLORS{$fiber_color} || $fiber_color)} || ''
    );

    $object->{FIBERS}{$fibers_count}{COLOR} = $fiber_color;

    $fibers_count += 1;
  }

  for (my $i = 1; $i <= $object->{FIBERS_OUT}; $i++) {
    $img->line(
      $object->{X_END},
      $object->{FIBERS_START_Y} + $fibers_count * $SCHEME_OPTIONS{PORT_HEIGHT},
      $object->{START_X},
      $object->{FIBERS_START_Y} + $fibers_count * $SCHEME_OPTIONS{PORT_HEIGHT}
    );

    my $text_y_coord = $object->{FIBERS_START_Y} + ($fibers_count - 1) * $SCHEME_OPTIONS{PORT_HEIGHT} + $SCHEME_OPTIONS{PORT_HEIGHT_TEXT_CENTER};

    _print_string($object->{TYPE_X_START} + $SPLITTER_OPTIONS{TYPE_COLUMN_WIDTH} / 2 - 2, $text_y_coord, $lang{OUTER});
    _print_string($object->{ATTENUATION_X_START} + $SPLITTER_OPTIONS{ATTENUATION_COLUMN_WIDTH} / 2 - 2, $text_y_coord, $object->{ATTENUATION}[$i - 1] || '');

    my $fiber_color = $object->{FIBERS_COLORS} && ref $object->{FIBERS_COLORS} eq 'ARRAY' ? $object->{FIBERS_COLORS}[$fibers_count - 1] : '';
    _print_string(
      $object->{COLOR_X_START} + $SPLITTER_OPTIONS{COLOR_COLUMN_WIDTH} / 2 - 2,
      $text_y_coord,
      $lang{uc($CABLE_COLORS{$fiber_color} || $fiber_color)} || ''
    );

    $object->{FIBERS}{$fibers_count}{COLOR} = $fiber_color;

    $fibers_count += 1;
  }
}

#**********************************************************
=head2 cross_print_info ()

=cut
#**********************************************************
sub cross_print_info {
  my $object = shift;

  my $end_x = $object->{START_X} + $SCHEME_OPTIONS{HEADER_WIDTH} - $SCHEME_OPTIONS{PORT_WIDTH};
  $object->{X_END} = $end_x;

  $end_x = _draw_column_block($object, $end_x, 'PORT_TYPE', \%CROSS_OPTIONS);
  $end_x = _draw_column_block($object, $end_x, 'FIBER_TYPE', \%CROSS_OPTIONS);
  $end_x = _draw_column_block($object, $end_x, 'POLISH_TYPE', \%CROSS_OPTIONS);
  $end_x = _draw_column_block($object, $end_x, 'COLOR', \%CROSS_OPTIONS);

  $img->line($object->{START_X}, $object->{FIBERS_START_Y} + $SCHEME_OPTIONS{PORT_HEIGHT},
    $object->{X_END}, $object->{FIBERS_START_Y} + $SCHEME_OPTIONS{PORT_HEIGHT});
  $object->{FIBERS_START_Y} += $SCHEME_OPTIONS{PORT_HEIGHT};

  my $fiber_num = $object->{FIBER_START};

  for (my $i = 1; $i <= $object->{FIBERS_COUNT}; $i++) {
    $img->line(
      $object->{X_END},
      $object->{FIBERS_START_Y} + $i * $SCHEME_OPTIONS{PORT_HEIGHT},
      $object->{START_X},
      $object->{FIBERS_START_Y} + $i * $SCHEME_OPTIONS{PORT_HEIGHT}
    );

    my $text_y_coord = $object->{FIBERS_START_Y} + ($i - 1) * $SCHEME_OPTIONS{PORT_HEIGHT} + $SCHEME_OPTIONS{PORT_HEIGHT_TEXT_CENTER};

    _print_string($object->{PORT_TYPE_X_START} + $CROSS_OPTIONS{PORT_TYPE_COLUMN_WIDTH} / 2 - 2, $text_y_coord, $object->{PORT_TYPE});
    _print_string($object->{FIBER_TYPE_X_START} + $CROSS_OPTIONS{FIBER_TYPE_COLUMN_WIDTH} / 2 - 2, $text_y_coord, $object->{FIBER_TYPE});
    _print_string($object->{POLISH_TYPE_X_START} + $CROSS_OPTIONS{POLISH_TYPE_COLUMN_WIDTH} / 2 - 2, $text_y_coord, $object->{POLISH_TYPE});

    my $fiber_color = $object->{FIBERS_COLORS} && ref $object->{FIBERS_COLORS} eq 'ARRAY' ? $object->{FIBERS_COLORS}[$fiber_num - 1] : '';
    $object->{FIBERS}{$fiber_num}{COLOR} = $fiber_color;
    $fiber_color = $lang{uc($CABLE_COLORS{$fiber_color} || $fiber_color)} || $lang{GRAY};
    $fiber_color = substr($fiber_color, 0, 8) . ".";
    _print_string($object->{COLOR_X_START} + $CROSS_OPTIONS{COLOR_COLUMN_WIDTH} / 2, $text_y_coord, $fiber_color);
    $fiber_num += 1;
  }
}

#**********************************************************
=head2 equipment_print_info ()

=cut
#**********************************************************
sub equipment_print_info {
  my $object = shift;

  my $end_x = $object->{START_X} + $SCHEME_OPTIONS{HEADER_WIDTH} - $SCHEME_OPTIONS{PORT_WIDTH};
  $object->{X_END} = $end_x;

  $end_x = _draw_column_block($object, $end_x, 'PORT_TYPE', \%EQUIPMENT_OPTIONS);
  $end_x = _draw_column_block($object, $end_x, 'COLOR', \%EQUIPMENT_OPTIONS);

  $img->line($object->{START_X}, $object->{FIBERS_START_Y} + $SCHEME_OPTIONS{PORT_HEIGHT},
    $object->{X_END}, $object->{FIBERS_START_Y} + $SCHEME_OPTIONS{PORT_HEIGHT});
  $object->{FIBERS_START_Y} += $SCHEME_OPTIONS{PORT_HEIGHT};

  for (my $i = 1; $i <= $object->{FIBERS_COUNT}; $i++) {
    $img->line(
      $object->{X_END},
      $object->{FIBERS_START_Y} + $i * $SCHEME_OPTIONS{PORT_HEIGHT},
      $object->{START_X},
      $object->{FIBERS_START_Y} + $i * $SCHEME_OPTIONS{PORT_HEIGHT}
    );

    my $text_y_coord = $object->{FIBERS_START_Y} + ($i - 1) * $SCHEME_OPTIONS{PORT_HEIGHT} + $SCHEME_OPTIONS{PORT_HEIGHT_TEXT_CENTER};
    _print_string($object->{PORT_TYPE_X_START} + $EQUIPMENT_OPTIONS{PORT_TYPE_COLUMN_WIDTH} / 2 - 2, $text_y_coord, $object->{PORT_TYPE});
    my $fiber_color = $lang{GRAY};
    _print_string($object->{COLOR_X_START} + $EQUIPMENT_OPTIONS{COLOR_COLUMN_WIDTH} / 2, $text_y_coord, $fiber_color);
  }
}

#**********************************************************
=head2 _draw_column_block ()

=cut
#**********************************************************
sub _draw_column_block {
  my ($object, $end_x, $column_name, $options) = @_;

  my $column_width = $options->{$column_name . '_COLUMN_WIDTH'};
  return '' if !$column_width || $column_width < 0;

  $img->rectangle($end_x, $object->{FIBERS_START_Y}, $end_x - $column_width, $object->{FIBERS_END_Y});
  $end_x -= $column_width;
  $object->{$column_name . '_X_START'} = $end_x;
  _print_string($object->{$column_name . '_X_START'} + $column_width / 2 - 2,
    $object->{FIBERS_START_Y} + $SCHEME_OPTIONS{PORT_HEIGHT_TEXT_CENTER}, $lang{$column_name} || $column_name);

  return $end_x;
}

#**********************************************************
=head2 _print_string ()

=cut
#**********************************************************
sub _print_string {
  my ($cx, $cy, $str, $color) = @_;

  $color ||= $black;

  $img->moveTo($cx - length(Encode::decode_utf8($str)) * 3, $cy);
  $img->string($str, $color);
}

#**********************************************************
=head2 _print_name ()

=cut
#**********************************************************
sub _print_name {
  my ($x, $y, $name) = @_;

  my $name_length = length(Encode::decode_utf8($name));

  my @fragments = unpack '(A36)*', Encode::decode_utf8($name);
  my $fragments_length = @fragments;

  if ($fragments_length == 1) {
    $img->moveTo($x + 5, $y + 5);
    $img->string($name, $black);
    return;
  }

  if ($fragments_length == 2) {
    $img->moveTo($x + 5, $y - 5);
    $img->string($fragments[0] . ' -', $black);
    $img->moveTo($x + 5, $y + 15);
    $img->string($fragments[1], $black);
    return;
  }

  if ($fragments_length >= 3) {
    $img->moveTo($x + 5, $y - 10);
    $img->string($fragments[0] . ' -', $black);
    $img->moveTo($x + 5, $y + 5);
    $img->string($fragments[1] . ' -', $black);
    $img->moveTo($x + 5, $y + 20);
    $img->string($fragments[2], $black);
    return;
  }
}

1;

