#package Cablecat::BigCommutation;
use strict;
use warnings FATAL => 'all';

=head1 NAME

  Cablecat::BigCommutation

=head2 SYNOPSIS

=cut
our (%lang, $html, %permissions, $Cablecat, $Maps, $Equipment, %MAP_LAYER_ID);
use AXbills::Base qw/in_array/;

#**********************************************************
=head2 cablecat_big_commutation($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub cablecat_big_commutation {
  my ($attr) = @_;

  if ($FORM{change_element_position}) {
    cablecat_change_coords();
    return;
  }

  if ($FORM{change_link}) {
    cablecat_change_link_geometry();
    return;
  }

  if ($FORM{del} && $FORM{ID}) {
    cablecat_del_commutation();
    return;
  }

  $html->tpl_show(_include('cablecat_big_commutation', 'Cablecat'));

  return 0;
}

#**********************************************************
=head2 cablecat_commutations_select($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub cablecat_commutations_select {
  my ($attr) = @_;

  my $commutations = $Cablecat->commutations_list({
    SHOW_ALL_COLUMNS => 1,
    PAGE_ROWS        => 10000
  });

  my $addedCommutations = $Cablecat->schemes_list({
    ID             => '_SHOW',
    COMMUTATION_ID => '_SHOW',
    PAGE_ROWS      => 10000
  });

  my $addedCommutationsArray = ();
  map push(@{$addedCommutationsArray}, $_->{commutation_id}), @{$addedCommutations};

  my $commutations_select = ();
  foreach my $commutation (@{$commutations}) {
    push(@{$commutations_select}, $commutation) if (!in_array($commutation->{id}, $addedCommutationsArray));
  }
 
  return $html->tpl_show(_include('cablecat_commutations_select', 'Cablecat'), {
    COMMUTATIONS => $html->form_select('COMMUTATION_ID', {
      SEL_LIST  => $commutations_select,
      SEL_VALUE => 'id,connecter',
      SEL_KEY   => 'id',
      NO_ID     => 1,
      EX_PARAMS => 'required="required"',
    })
  });
}

#**********************************************************
=head2 cablecat_get_commutation($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub cablecat_get_commutation {
  my ($attr) = @_;

  $FORM{ID} = $attr->{ID} || $FORM{ID};
  my $commutation = $Cablecat->commutations_info($attr->{ID} || $FORM{ID});

  my $cables = _cablecat_get_cables();

  my $splitters = $Cablecat->scheme_splitters_list({ COMMUTATION_ID => $FORM{ID} });
  map $_->{color_scheme} = $_->{fibers_colors} ? [ map {'#' . ($_ || '000000')} split ',', $_->{fibers_colors} ] : (), @{$splitters};
  return {} if (!$splitters);

  my $equipment = $Cablecat->scheme_equipments_list({ COMMUTATION_ID => $FORM{ID} });
  map {
    $_->{commutation_equipment_id} = $_->{id};
    $_->{id} = $_->{nas_id} if ($_->{nas_id});
    $_
  } @{$equipment};
  return {} if (!$equipment);

  my $crosses = $Cablecat->scheme_crosses_list({ COMMUTATION_ID => $FORM{ID} });

  map {
    $_->{commutation_cross_id} = $_->{commutation_id};
    $_->{id} = $_->{cross_id} if ($_->{cross_id});
    $_->{ports} = (($_->{port_finish} || 0) - ($_->{port_start} || 0)) + 1;
    $_->{name} = ($_->{name} || q{}) . " (" . ($_->{port_start} || q{}) . "-" . ($_->{port_finish} || q{}) . ")";
    $_
  } @{$crosses};

  my $commutation_json = {};

  $commutation_json->{CABLES} = $cables;
  $commutation_json->{SPLITTERS} = $splitters;
  $commutation_json->{EQUIPMENT} = $equipment;
  $commutation_json->{CROSSES} = $crosses;

  $commutation_json->{NAME} = $commutation->{CONNECTER};

  my $com_links_list = $Cablecat->scheme_links_list({ COMMUTATION_ID => $FORM{ID} });

  $commutation_json->{LINKS} = [
    map {
      $_->{geometry} = JSON::from_json($_->{geometry}) if ($_->{geometry});
      $_->{fiber_num_1} -= 1 if ($_->{fiber_num_1});
      $_->{fiber_num_2} -= 1 if ($_->{fiber_num_2});
      $_;
    } @{$com_links_list}
  ];

  if ($FORM{RETURN_JSON}) {
    print JSON::to_json($commutation_json, { utf8 => 0 });
    return 1;
  }

  return $commutation_json;
}

#**********************************************************
=head2 _cablecat_get_cables($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub _cablecat_get_cables {
  my ($attr) = @_;

  my $cables_list = $Cablecat->scheme_cables_list({ COMMUTATION_ID => $FORM{ID} });

  my @cables = ();
  foreach my $cable (@{$cables_list}) {
    next if (!$cable->{modules_colors} || !$cable->{fibers_colors});
    next if (!defined $cable->{modules_count} || !defined $cable->{fibers_count});

    $cable->{outer_color} //= '#000000';
    push @cables, {
      id             => +$cable->{id},
      commutation_x  => $cable->{commutation_x},
      commutation_y  => $cable->{commutation_y},
      changed_coords => $cable->{commutation_x} && $cable->{commutation_y} ? 1 : 0,
      image          => {
        modules              => +$cable->{modules_count},
        fibers               => +$cable->{fibers_count},
        color                => $cable->{outer_color},
        color_scheme         => [ map {'#' . (length($_) > 6 ? substr($_, 0, -1) : $_)} split ',', $cable->{fibers_colors} ],
        modules_color_scheme => [ map {'#' . (length($_) > 6 ? substr($_, 0, -1) : $_)} split ',', $cable->{modules_colors} ],
      },
      meta           => {
        name      => $cable->{name},
        well_1_id => $cable->{well_1_id},
        well_2_id => $cable->{well_2_id},
        well_1    => $cable->{well_1},
        well_2    => $cable->{well_2}
      }
    };
  };

  return \@cables;
}

#**********************************************************
=head2 cablecat_fill_scheme_coords($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub cablecat_fill_scheme_coords {

  if ($FORM{change}) {
    $Cablecat->schemes_change({ _CHANGE_PARAM => 'COMMUTATION_ID', %FORM });

    if ($Cablecat->{error}) {
      print qq{{"error": "$lang{POSITION_CHANGE_ERROR}"}};
    }
    else {
      print qq{{"success": "$lang{POSITION_SUCCESSFULLY_CHANGED}"}};
    }

    return;
  }

  $Cablecat->schemes_add(\%FORM);

  return 0;
}

#**********************************************************
=head2 cablecat_get_added_schemes($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub cablecat_get_added_schemes {

  my $schemes = [];

  my $schemes_list = $Cablecat->schemes_list({
    ID             => '_SHOW',
    COMMUTATION_ID => '_SHOW',
    COMMUTATION_X  => '_SHOW',
    COMMUTATION_Y  => '_SHOW',
    HEIGHT         => '_SHOW',
    WIDTH          => '_SHOW',
    DESC           => '1',
    PAGE_ROWS      => 10000
  });

  if ($Cablecat->{TOTAL} < 1) {
    print qq{{"msg": "empty"}};
    return;
  }

  foreach my $scheme (@{$schemes_list}) {
    my $scheme_info = cablecat_get_commutation({ ID => $scheme->{commutation_id} });
    %{$scheme_info} = (%{$scheme_info}, %{$scheme});
    push(@{$schemes}, $scheme_info);
  }

  print JSON::to_json($schemes, { utf8 => 0 });
  return 1;
}

#**********************************************************
=head2 cablecat_change_coords($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub cablecat_change_coords {
  my ($attr) = @_;

  return 0 if !$FORM{ID} && !$FORM{TYPE};

  my $list = $Cablecat->scheme_elements_list({
    TYPE => $FORM{TYPE},
    ID   => $FORM{ID}
  });

  if ($Cablecat->{TOTAL} > 0) {
    $Cablecat->scheme_elements_change({ _CHANGE_PARAM => 'ID,TYPE', %FORM });
  }
  else {
    $Cablecat->scheme_elements_add(\%FORM);
  }

  return 0;
}

#**********************************************************
=head2 cablecat_change_link_geometry($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub cablecat_change_link_geometry {
  my ($attr) = @_;

  return 0 if !$FORM{ID};

  $Cablecat->scheme_links_list({ ID => $FORM{ID}, ONLY_SCHEME_LINKS => 1 });

  if ($Cablecat->{TOTAL} > 0) {
    $Cablecat->scheme_links_change(\%FORM);
  }
  else {
    $Cablecat->scheme_links_add(\%FORM);
  }

  return 0;
}

#**********************************************************
=head2 cablecat_del_commutation($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub cablecat_del_commutation {
  my ($attr) = @_;

  $Cablecat->schemes_del(undef, { COMMUTATION_ID => $FORM{ID} });
  $Cablecat->scheme_links_del(undef, { COMMUTATION_ID => $FORM{ID} });
  $Cablecat->scheme_elements_del(undef, { COMMUTATION_ID => $FORM{ID} });

  return 0;
}

1;
