use strict;
use warnings FATAL => 'all';

our ($Cablecat, $Maps, $html, %lang, %conf, $admin, $db, @CABLECAT_EXTRA_COLORS, %permissions, %MAP_LAYER_ID);

#**********************************************************
=head2 _cablecat_color_scheme_select()

=cut
#**********************************************************
sub _cablecat_color_scheme_select {
  my $attr = shift // {};
  
  my $select_func = make_select_from_db_table(
    $Cablecat,
    'Cablecat',
    'color_schemes',
    $attr->{NAME} || 'COLOR_SCHEME_ID',
    $attr
  );
  
  return &{$select_func};
}

#**********************************************************
=head2 _cablecat_cable_type_select($attr)

=cut
#**********************************************************
sub _cablecat_cable_type_select {
  my $attr = shift // {};
  
  my $select_func = make_select_from_db_table(
    $Cablecat,
    'Cablecat',
    'cable_types',
    $attr->{NAME} || 'CABLE_TYPE_ID',
    $attr
  );
  
  return &{$select_func};
}

#**********************************************************
=head2 _cablecat_point_id_select($attr)

=cut
#**********************************************************
sub _cablecat_point_id_select {
  my $attr = shift // {};
  my $selected = $attr->{SELECTED} || $FORM{POINT_ID} || '';
  
  if ($selected && $attr->{ENTITY}){
    $attr->{EXT_BUTTON} = _cablecat_result_former_point_id_filter($selected, { PARAMS => [ $MAP_LAYER_ID{$attr->{ENTITY}} ] });
  }
  
  return $html->form_select(
    'POINT_ID',
    {
      SELECTED => $selected,
      SEL_LIST => $Maps->points_list(
        {
          ID   => '_SHOW',
          NAME => '_SHOW',
          %{ $attr->{FILTER} ? $attr->{FILTER} : {} },
          PAGE_ROWS => 10000
        }
      ),
      NO_ID       => 1,
      SEL_OPTIONS => { '' => '' },
      
      # MAIN_MENU      => get_function_index('maps_objects_main'),
      MAIN_MENU_ARGV => $selected ? 'chg=' . $selected : '',
      %{$attr},
    }
  );
}

#**********************************************************
=head2 _cablecat_wells_select($attr)

=cut
#**********************************************************
sub _cablecat_wells_select {
  my $attr = shift // {};
  
  my $select_func = make_select_from_db_table($Cablecat, 'Cablecat', 'wells', $attr->{NAME} || 'WELL_ID', { %$attr });
  
  return &{$select_func};
}

#**********************************************************
=head2 _cablecat_commutations_select($attr)

=cut
#**********************************************************
sub _cablecat_commutations_select {
  my $attr = shift // {};
  
  my $select_func = make_select_from_db_table(
    $Cablecat,
    'Cablecat',
    'commutations',
    $attr->{NAME} || 'COMMUTATION_ID',
    {
      %{$attr},
      FORMAT_LIST => sub {
        my $commutations_list = shift;
        [ map { $_->{name} = $lang{COMMUTATION} . '_#' . $_->{id}; $_ } @$commutations_list ];
      }
    }
  );
  
  return &{$select_func};
}

#**********************************************************
=head2 _cablecat_connecters_select($attr)

=cut
#**********************************************************
sub _cablecat_connecters_select {
  
  my $attr = shift // {};
  
  my $select_func = make_select_from_db_table(
    $Cablecat,
    'Cablecat',
    'wells',
    $attr->{NAME} || 'CONNECTER_ID',
    {
      %$attr,
      FILTER => {
        TYPE_ID => 2
      }
    }
  );
  
  return &{$select_func};
}

#**********************************************************
=head2 _cablecat_cables_select($attr)

=cut
#**********************************************************
sub _cablecat_cables_select {
  my $attr = shift // {};
  
  my $select_func = make_select_from_db_table(
    $Cablecat,
    'Cablecat',
    'cables',
    'CABLE_ID',
    $attr
  );
  
  return &{$select_func};
}

#**********************************************************
=head2 _cablecat_connecter_types_select($attr)

=cut
#**********************************************************
sub _cablecat_connecter_type_select {
  my $attr = shift // {};
  
  my $select_func = make_select_from_db_table(
    $Cablecat,
    'Cablecat',
    'connecter_types',
    $attr->{NAME} || 'CONNECTER_TYPE_ID',
    $attr
  );
  
  return &{$select_func};
}

#**********************************************************
=head2 _cablecat_splitter_types_select($attr)

=cut
#**********************************************************
sub _cablecat_splitter_types_select {
  my $attr = shift // {};
  
  my $select_func = make_select_from_db_table(
    $Cablecat,
    'Cablecat',
    'splitter_types',
    $attr->{NAME} || 'TYPE_ID',
    $attr
  );
  
  return &{$select_func};
}

#**********************************************************
=head2 _cablecat_well_types_select($attr)

=cut
#**********************************************************
sub _cablecat_well_types_select {
  my $attr = shift // {};
  
  my $select_func = make_select_from_db_table(
    $Cablecat,
    'Cablecat',
    'well_types',
    $attr->{NAME} || 'TYPE_ID',
  {
    %$attr,
    _TRANSLATE => 1,
  }
  );
  
  return &{$select_func};
}

#**********************************************************
=head2 _cablecat_well_types_select($attr)

=cut
#**********************************************************
sub _cablecat_cross_types_select {
  my $attr = shift // {};
  
  my $select_func = make_select_from_db_table(
    $Cablecat,
    'Cablecat',
    'cross_types',
    $attr->{NAME} || 'TYPE_ID',
    $attr
  );
  
  return &{$select_func};
}


1;