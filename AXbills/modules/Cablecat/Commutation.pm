#package Cablecat::Commutation;
use strict;
use warnings FATAL => 'all';

=head1 NAME

  Cablecat::Commutation

=head2 SYNOPSIS

  This file contains functions for commutation show and editing

=cut
our ($db, $admin, %conf, %lang, $html, %permissions, $Cablecat, $Maps, $Equipment, %MAP_LAYER_ID);
use AXbills::Base qw/in_array/;
use Maps::Auxiliary;
use Internet;
use AXbills::Experimental;
my $Auxiliary = Maps::Auxiliary->new($db, $admin, \%conf, { HTML => $html, LANG => \%lang });
my $Internet = Internet->new($db, $admin, \%conf);

#**********************************************************
=head2 cablecat_commutation()

=cut
#**********************************************************
sub cablecat_commutation {

  #  _bp('', 'TEST');
  #  return $html->tpl_show(_include('cablecat_temp', 'Cablecat'));
  #
  my %TEMPLATE_ARGS = ();
  my $show_add_form = $FORM{add_form} || 0;

  # Handling AJAX requests
  if ($FORM{commutation}) {
    return &cablecat_commutation_ajax;
  }
  elsif ($FORM{operation}) {
    return &cablecat_commutation_operations;
  }

  if ($FORM{ID}) {
    my $commutation_info = $Cablecat->commutations_info($FORM{ID});
    if (!_error_show($Cablecat)) {
      %TEMPLATE_ARGS = %{$commutation_info};
      $show_add_form = 1;
    }
  }

  return 1 if ($FORM{MESSAGE_ONLY});

  my $cable_ids = $TEMPLATE_ARGS{CABLE_IDS} || $FORM{CABLE_IDS};
  my $links_table = '';

  if ($show_add_form) {

    if (defined $TEMPLATE_ARGS{ID}) {
      my $cables = '';
      if ($cable_ids) {
        $cables = _cablecat_commutation_cables_prepare_json($cable_ids, { COMMUTATION_ID => $TEMPLATE_ARGS{ID} });
        return 0 if (!$cables);
      }
      else {
        $html->message('warn', $lang{WARNING}, "No cables defined for this comutation");
      }

      my $splitters = _cablecat_commutation_splitters(undef, { COMMUTATION_ID => $TEMPLATE_ARGS{ID} });
      return 0 if (!$splitters);

      my $equipment = _cablecat_commutation_equipment(undef, { COMMUTATION_ID => $TEMPLATE_ARGS{ID} });
      return 0 if (!$equipment);

      my $crosses = _cablecat_commutation_crosses(undef, { COMMUTATION_ID => $TEMPLATE_ARGS{ID} });
      return 0 if (!$crosses);

      my $ONUS = _cablecat_commutation_onus(undef, { COMMUTATION_ID => $TEMPLATE_ARGS{ID} });
      return 0 if (!$ONUS);

      $TEMPLATE_ARGS{INFO_TABLE} = _cablecat_commutation_info_table($TEMPLATE_ARGS{ID}, \%TEMPLATE_ARGS);

      (my $com_links_list, $TEMPLATE_ARGS{LINKS}) = cablecat_commutation_links($TEMPLATE_ARGS{ID});

      $TEMPLATE_ARGS{CABLES} = JSON::to_json($cables || []);
      $TEMPLATE_ARGS{SPLITTERS} = JSON::to_json($splitters);
      $TEMPLATE_ARGS{EQUIPMENT} = JSON::to_json($equipment);
      $TEMPLATE_ARGS{CROSSES} = JSON::to_json($crosses);
      $TEMPLATE_ARGS{ONUS} = JSON::to_json($ONUS);
      $TEMPLATE_ARGS{BTN} = $html->button($lang{PRINT_SCHEME}, "header=2&qindex=" .
        get_function_index('show_box') . "&print=1&ID=" . $FORM{ID}, { target => '_new', class => 'btn btn-default' });

      $links_table = _cablecat_commutation_links_table($com_links_list, { ID => $FORM{ID} });
    }

    $html->tpl_show(_include('cablecat_commutation', 'Cablecat'), \%TEMPLATE_ARGS);

    print $html->br();

    print $links_table->show() if $links_table;
  }

  return 1;
}

#**********************************************************
=head2 cablecat_commutation_ajax()

=cut
#**********************************************************
sub cablecat_commutation_ajax {
  return unless ($FORM{commutation});

  my @link_required_params = qw/
    COMMUTATION_ID
    ELEMENT_1_TYPE ELEMENT_1_ID
    ELEMENT_2_TYPE ELEMENT_2_ID
    FIBER_NUM_1 FIBER_NUM_2
  /;

  # Add link
  if ($FORM{add}) {
    # Check we have all arguments to add link
    if (grep {!$FORM{$_}} @link_required_params) {
      $html->message('err', 'No param', $_);
      return 0;
    }

    my $link_id = $Cablecat->links_add({
      %FORM,
    });

    show_result($Cablecat, $lang{ADDED}, '', { ID => 'LINK_ADDED', RESPONCE_PARAMS => { LINK_ID => $link_id } });
  }

  if ($FORM{del}) {
    $Cablecat->links_del({ ID => $FORM{del} });
    show_result($Cablecat, $lang{DEL}, '', { ID => 'LINK_REMOVED', RESPONCE_PARAMS => { LINK_ID => $FORM{del} } });
  }

  if ($FORM{change}) {
    $Cablecat->links_change({ %FORM, ID => $FORM{change} });
    show_result($Cablecat, $lang{CHANGED}, '', { ID => 'LINK_CHANGED', RESPONCE_PARAMS => { LINK_ID => $FORM{change} } });
  }

  if ($FORM{change_height} && $FORM{COMMUTATION_ID}) {
    $Cablecat->commutations_change({ ID => $FORM{COMMUTATION_ID}, HEIGHT => $FORM{change_height} });
  }

  return 1;
}

#**********************************************************
=head2 cablecat_commutation_operations()

=cut
#**********************************************************
sub cablecat_commutation_operations {
  return 0 unless ($FORM{COMMUTATION_ID});

  my $info = $Cablecat->commutations_info($FORM{COMMUTATION_ID});

  if (!$FORM{entity}) {

  }
  elsif ($FORM{entity} eq 'CABLE') {
    return cablecat_commutation_cables($info);
  }
  elsif ($FORM{entity} eq 'SPLITTER') {
    return cablecat_commutation_splitters($info);
  }
  elsif ($FORM{entity} eq 'EQUIPMENT') {
    return cablecat_commutation_equipment($info);
  }
  elsif ($FORM{entity} eq 'CROSS') {
    return cablecat_commutation_crosses($info);
  }
  elsif($FORM{entity} eq 'ONU'){
    return cablecat_commutation_onu($info);
  }

  if ($FORM{operation} eq 'CLEAR_COMMUTATION') {
    $Cablecat->links_del({}, {
      COMMUTATION_ID => $FORM{COMMUTATION_ID},
    });
    _error_show($Cablecat);
    $Cablecat->commutation_equipment_del({}, {
      COMMUTATION_ID => $FORM{COMMUTATION_ID},
    });
    _error_show($Cablecat);
    $Cablecat->splitters_del({
      COMMUTATION_ID => $FORM{COMMUTATION_ID},
    });
    _error_show($Cablecat);
    $Cablecat->commutation_onu_del({},{
      COMMUTATION_ID => $FORM{COMMUTATION_ID},
    });
    _error_show($Cablecat);

    show_result($Cablecat, "$lang{DELETED} $lang{ALL}", '', { ID => 'COMMUTATION_CLEARED' });
  }
  elsif ($FORM{operation} eq 'CONNECT_BY_NUMBERS') {
    # Get cables for commutation
    my $cables_list = $Cablecat->commutation_cables_list({
      COMMUTATION_ID => $FORM{COMMUTATION_ID},
      CABLE_ID       => '_SHOW',
      CABLE_NAME     => '_SHOW',
    });
    _error_show($Cablecat) and return 0;

    my $has_only_to_cables = $Cablecat->{TOTAL} == 2;
    my $selected_1 = '';
    my $selected_2 = '';
    if ($has_only_to_cables) {
      $selected_1 = $cables_list->[0]->{cable_id};
      $selected_2 = $cables_list->[1]->{cable_id};
    }

    my $cable_1_select = make_select_from_list("CABLE_1", $cables_list,
      {
        SELECTED     => $selected_1,
        SEL_KEY      => 'cable_id',
        SEL_VALUE    => 'cable_name',
        NORMAL_WIDTH => 1,
      }
    );
    my $cable_2_select = make_select_from_list("CABLE_2", $cables_list,
      {
        SELECTED     => $selected_2,
        SEL_KEY      => 'cable_id',
        SEL_VALUE    => 'cable_name',
        NORMAL_WIDTH => 1,
      }
    );

    # Get number of fibers for each cable

    # Show template
    $html->tpl_show(
      _include('cablecat_commutation_connect_by_numbers', 'Cablecat'),
      {
        CABLE_1_SELECT => $cable_1_select,
        CABLE_2_SELECT => $cable_2_select
      }
    );

  }
  else {
    print "Wrong params";
  }

  return 1;
}

#**********************************************************
=head2 cablecat_commutation_cables()

=cut
#**********************************************************
sub cablecat_commutation_cables {
  my ($commutation) = @_;

  if ($FORM{operation} eq 'LIST' && $FORM{WELL_ID}) {
    my $cables_inputs = _cablecat_well_cables_checkbox_form(
      $FORM{WELL_ID},
      {
        SKIP => [ split(',\s?', $commutation->{CABLE_IDS} || '') ]
      }
    );

    if (!$cables_inputs || (ref $cables_inputs eq 'ARRAY' && !scalar @{$cables_inputs})) {
      $html->message('err', $lang{CABLES} . ' ' . $lang{WELL} . '_#' . $FORM{WELL_ID}, $lang{NO_DATA});
      return 0;
    }

    $html->tpl_show(_include('cablecat_commutation_cable_add_modal', 'Cablecat'), {
      CABLES_CHECKBOXES => join($FORM{json} ? ', ' : '', @{$cables_inputs}),
      SUBMIT_BTN_NAME   => $lang{ADD},
      SUBMIT_BTN_ACTION => 'change',
      %FORM
    }
    );
  }
  elsif ($FORM{operation} eq 'ADD') {
    my $info = $Cablecat->commutations_info($FORM{COMMUTATION_ID});

    # Will compare given in $FORM{CABLE_IDS} to already existing cables $info->{CABLE_IDS};
    my $current_cable_ids = [ split(',\s?', $info->{CABLE_IDS} || '') ];
    foreach my $cable_id (split(',\s?', $FORM{CABLE_IDS})) {

      # Already exists
      next if (in_array($cable_id, $current_cable_ids));

      $Cablecat->commutation_cables_add({
        CABLE_ID       => $cable_id,
        CONNECTER_ID   => $FORM{CONNECTER_ID},
        COMMUTATION_ID => $FORM{COMMUTATION_ID}
      });

      show_result($Cablecat, $lang{ADDED}, '', { ID => 'CABLE_ADDED' });

      $html->redirect('?index=' . (get_function_index('cablecat_commutation') . '&ID=' . $FORM{COMMUTATION_ID}));
    }
  }
  elsif ($FORM{operation} eq 'DELETE' && $FORM{ID}) {
    $Cablecat->delete_links_for_element('CABLE', $FORM{ID});

    $Cablecat->commutation_cables_del({}, {
      commutation_id => $FORM{COMMUTATION_ID},
      connecter_id   => $FORM{CONNECTER_ID},
      cable_id       => $FORM{ID}
    });

    show_result($Cablecat, $lang{DEL}, '', { ID => 'ELEMENT_DELETED' });
  }
  elsif ($FORM{operation} eq 'SAVE_COORDS') {
    $Cablecat->commutation_cables_change({
      CABLE_ID      => $FORM{ID},
      COMMUTATION_X => $FORM{X},
      COMMUTATION_Y => $FORM{Y},
      POSITION      => $FORM{POSITION},
      _CHANGE_PARAM => 'CABLE_ID'
    });
    show_result($Cablecat, $lang{CHANGED}, '', { ID => 'COORDS_CHANGED' });
  }
}

#**********************************************************
=head2 cablecat_commutation_splitters()

=cut
#**********************************************************
sub cablecat_commutation_splitters {

  if ($FORM{operation} eq 'LIST') {
    my $splitters_for_well = $Cablecat->splitters_list({
      ID         => '_SHOW',
      TYPE       => '_SHOW',
      FIBERS_IN  => '_SHOW',
      FIBERS_OUT => '_SHOW',
      WELL_ID    => $FORM{WELL_ID},
    });

    my $splitters_select = $html->form_select('SPLITTER_ID', {
      SEL_LIST    => [ map {$_->{name} = $_->{type} . '_#' . $_->{id};
        $_} @{$splitters_for_well} ],
      SEL_OPTIONS => { '' => '' }
    });

    $html->tpl_show(_include('cablecat_commutation_splitter_add_modal', 'Cablecat'), {
      SPLITTERS_SELECT  => $splitters_select,
      SUBMIT_BTN_NAME   => $lang{ADD},
      SUBMIT_BTN_ACTION => 'change',
      %FORM
    });
  }
  elsif ($FORM{operation} eq 'ADD') {
    # Do splitter adding logic
    my $splitter_info = $Cablecat->splitters_info($FORM{SPLITTER_ID});
    _error_show($Cablecat);

    # Set splitter commutation
    if (!$splitter_info->{commutation_id} || $splitter_info->{commutation_id} ne $FORM{COMMUTATION_ID}) {
      $Cablecat->splitters_change({
        ID             => $FORM{SPLITTER_ID},
        COMMUTATION_ID => $FORM{COMMUTATION_ID}
      })
    }

    show_result($Cablecat, $lang{ADDED}, '', { ID => 'SPLITTER_ADDED' });
  }
  elsif ($FORM{operation} eq 'DELETE' && $FORM{ID}) {
    $Cablecat->delete_links_for_element('SPLITTER', $FORM{ID});
    $Cablecat->splitters_del({ ID => $FORM{ID} });

    show_result($Cablecat, $lang{DEL}, '', { ID => 'ELEMENT_DELETED' });
  }
  elsif ($FORM{operation} eq 'SAVE_COORDS') {
    $Cablecat->splitters_change({
      ID                   => $FORM{ID},
      COMMUTATION_X        => $FORM{X},
      COMMUTATION_Y        => $FORM{Y},
      COMMUTATION_ROTATION => $FORM{COMMUTATION_ROTATION},
    });
    show_result($Cablecat, $lang{CHANGED}, '', { ID => 'COORDS_CHANGED' });
  }
}

#**********************************************************
=head2 cablecat_commutation_equipment()

=cut
#**********************************************************
sub cablecat_commutation_equipment {

  if (!in_array('Equipment', \@MODULES)) {
    $html->message('warn', $lang{WARNING}, "$lang{MODULE} $lang{DISABLED} : 'Equipment'");
    return 0;
  }

  if (!$Equipment) {
    require Equipment;
    Equipment->import();
    $Equipment = Equipment->new($db, $admin, \%conf);
  }

  if ($FORM{operation} eq 'LIST') {

    # Will remove equipment that already is on another commutations
    my @equipment_on_commutation_ids = $Cablecat->commutation_equipment_ids();
    _error_show($Cablecat) and return 0;

    my $equipment_list = $Equipment->_list({
      NAS_NAME  => '_SHOW',
      NAS_ID    => join(',', map {"!$_"} @equipment_on_commutation_ids),
      COLS_NAME => 1,
      PAGE_ROWS => 10000
    });
    _error_show($Equipment) and return 0;

    if (!$equipment_list || ref($equipment_list) ne 'ARRAY' || !scalar(@{$equipment_list})) {
      $html->message("warn", $lang{WARNING}, $lang{NO_FREE_EQUIPMENT});
      print function_button("$lang{GO_TO} $lang{EQUIPMENT}", 'equipment_list');
      return 0;
    }

    my $equipment_select = make_select_from_list('EQUIPMENT_ID', $equipment_list, {
      NO_ID     => 0,
      SEL_KEY   => 'nas_id',
      SEL_VALUE => 'nas_name',
      MAIN_MENU => get_function_index('equipment_list')
    });

    $html->tpl_show(_include('cablecat_commutation_equipment_add_modal', 'Cablecat'), {
      EQUIPMENT_SELECT  => $equipment_select,
      SUBMIT_BTN_NAME   => $lang{ADD},
      SUBMIT_BTN_ACTION => 'change',
      %FORM
    }
    );
  }
  elsif ($FORM{operation} eq 'ADD') {
    # Do equipment adding logic
    my $commutation_info = $Cablecat->commutation_equipment_info(undef, { NAS_ID => $FORM{EQUIPMENT_ID} });

    my $not_added_to_commutation =
      !$commutation_info
        || !$commutation_info->{commutation_id}
        || $commutation_info->{commutation_id} ne $FORM{COMMUTATION_ID};

    # Set splitter commutation
    if ($not_added_to_commutation) {

      # Check if have ports count defined
      my $equipment_info = $Equipment->_info($FORM{EQUIPMENT_ID});
      my $ports_count = $equipment_info->{PORTS};

      if (!$ports_count || $ports_count eq '0') {
        my $model_info = $Equipment->model_info($equipment_info->{MODEL_ID});
        $ports_count = $model_info->{PORTS};

        if (!$ports_count || $ports_count eq '0') {
          $html->message('err', $lang{ERROR}, $lang{NO_PORTS_COUNT});
          return 0;
        }
      }

      $Cablecat->commutation_equipment_add({
        NAS_ID         => $FORM{EQUIPMENT_ID},
        COMMUTATION_ID => $FORM{COMMUTATION_ID}
      });
      show_result($Cablecat, $lang{ADDED}, '', { ID => 'EQUIPMENT_ADDED' });
    }
    else {
      $html->message('err', $lang{ERROR}, $lang{ALREADY_ON_ANOTHER_COMMUTATION});
      return 0;
    }
  }
  elsif ($FORM{operation} eq 'DELETE') {
    $Cablecat->delete_links_for_element('EQUIPMENT', $FORM{ID}, { commutation_id => $FORM{COMMUTATION_ID} });

    $Cablecat->commutation_equipment_del({}, { NAS_ID => $FORM{ID} });
    show_result($Cablecat, $lang{DEL}, '', { ID => 'ELEMENT_DELETED' });
  }
  elsif ($FORM{operation} eq 'SAVE_COORDS') {
    $Cablecat->commutation_equipment_change({
      _CHANGE_PARAM        => 'NAS_ID',
      NAS_ID               => $FORM{ID},
      COMMUTATION_X        => $FORM{X},
      COMMUTATION_Y        => $FORM{Y},
      COMMUTATION_ROTATION => $FORM{COMMUTATION_ROTATION},
    });
    show_result($Cablecat, $lang{CHANGED}, '', { ID => 'COORDS_CHANGED' });
  }
}


#**********************************************************
=head2 cablecat_commutation_onu()

=cut
#**********************************************************
sub cablecat_commutation_onu {
  if ($FORM{operation} eq 'LIST') {
    _error_show($Cablecat) and return 0;

    my $user_list = $Internet->user_list({
      COLS_NAME => 1,
      UID       => '_SHOW',
      LOGIN     => '_SHOW',
      PAGE_ROWS     => 999999999,
    });

    my $user_select = make_select_from_list('UID', $user_list, {
      SEL_KEY    => 'uid',
      SEL_VALUE  => 'login',
      SEL_OPTIONS => { 0 => '' },
    });

    $html->tpl_show(_include('cablecat_commutation_onu_add_modal', 'Cablecat'), {
      USER_SELECT => $user_select,
      COMMUTATION_ID => $FORM{COMMUTATION_ID},
      SUBMIT_BTN_NAME    => $lang{ADD},
      %FORM
    }
    );
  } 
  elsif($FORM{operation} eq 'ADD'){

    if($FORM{getServices} && $FORM{UID}){

      my $sercives = $Internet->user_list({
        UID       => $FORM{UID},
        ID        => '_SHOW',
        GROUP_BY  => 'internet.id',
        PORT      => '_SHOW',
        COLS_NAME => 1,
      });

      print make_select_from_list('SERVICE_ID', $sercives, {
        NO_ID            => 1,
        SEL_KEY          => 'id',
        SEL_VALUE        => 'id,port',
        SEL_VALUE_PREFIX => 'INTERNET: , PORT: ',
      });

    } else {

      if(!$FORM{SERVICE_ID}){
        show_result($Cablecat, $lang{ERROR}, 'NO SERVICE_ID!', { ID => 'ONU_ADDED' });
        return 1;
      }

      $Cablecat->commutation_onu_add({
        UID            => $FORM{UID},
        SERVICE_ID     => $FORM{SERVICE_ID},
        COMMUTATION_ID => $FORM{COMMUTATION_ID}
      });

      show_result($Cablecat, $lang{ADDED}, '', { ID => 'ONU_ADDED' });

    }
  }
  elsif ($FORM{operation} eq 'DELETE') {
    $Cablecat->delete_links_for_element('ONU', $FORM{ID}, { commutation_id => $FORM{COMMUTATION_ID} });

    $Cablecat->commutation_onu_del({}, { ID => $FORM{ID} });
    show_result($Cablecat, $lang{DEL}, '', { ID => 'ELEMENT_DELETED' });
  }
  elsif ($FORM{operation} eq 'SAVE_COORDS') {
    $Cablecat->commutation_onu_change({
      _CHANGE_PARAM        => 'ID',
      ID                   => $FORM{ID},
      COMMUTATION_X        => $FORM{X},
      COMMUTATION_Y        => $FORM{Y},
      COMMUTATION_ROTATION => $FORM{COMMUTATION_ROTATION},
    });
    show_result($Cablecat, $lang{CHANGED}, '', { ID => 'COORDS_CHANGED' });
  }
}

#**********************************************************
=head2 cablecat_commutation_crosses()

=cut
#**********************************************************
sub cablecat_commutation_crosses {

  if ($FORM{operation} eq 'LIST') {

    _error_show($Cablecat) and return 0;

    my $crosses_list = $Cablecat->crosses_list({
      NAME        => '_SHOW',
      TYPE        => '_SHOW',
      PORTS_COUNT => '_SHOW',
      CROSS_ID    => '_SHOW',
      COLS_NAME   => 1,
      PAGE_ROWS   => 10000
    });
    _error_show($Cablecat) and return 0;

    if (!$crosses_list || ref($crosses_list) ne 'ARRAY' || !scalar(@{$crosses_list})) {
      $html->message("warn", $lang{WARNING}, $lang{NO_FREE_EQUIPMENT});
      print function_button("$lang{GO_TO} $lang{CROSSES}", 'cablecat_crosses');
      return 0;
    }

    my %cross_used_ports = ();
    # To prevent duplicate adding should pass used ports
    my $cross_ranges = $Cablecat->commutation_crosses_list({
      CROSS_ID    => '_SHOW',
      PORT_START  => '_SHOW',
      PORT_FINISH => '_SHOW',
      PAGE_ROWS   => 10000
    });
    _error_show($Cablecat) and return 0;
    foreach my $cross_range (@$cross_ranges) {
      my %range_hash = (
        start  => $cross_range->{port_start},
        finish => $cross_range->{port_finish},
      );
      if (exists $cross_used_ports{$cross_range->{cross_id}}) {
        push(@{$cross_used_ports{$cross_range->{cross_id}}}, \%range_hash);
      }
      else {
        $cross_used_ports{$cross_range->{cross_id}} = [ \%range_hash ];
      }
    }

    my $cross_select = make_select_from_list('CROSS_ID', $crosses_list, {
      NO_ID         => 0,
      SEL_KEY       => 'id',
      SEL_VALUE     => 'type,name',
      WRITE_TO_DATA => 'ports_count',
      MAIN_MENU     => get_function_index('cablecat_crosses')
    });

    $html->tpl_show(_include('cablecat_commutation_cross_add_modal', 'Cablecat'), {
      CROSS_SELECT       => $cross_select,
      PORT_START_SELECT  => $html->form_select('PORT_START'),
      PORT_FINISH_SELECT => $html->form_select('PORT_FINISH'),
      USED_PORTS         => JSON::to_json(\%cross_used_ports),
      SUBMIT_BTN_NAME    => $lang{ADD},
      SUBMIT_BTN_ACTION  => 'change',
      %FORM
    }
    );
  }
  elsif ($FORM{operation} eq 'ADD') {
    # Do equipment adding logic
    my $commutation_info = $Cablecat->commutation_crosses_info(undef, { CROSS_ID => $FORM{CROSS_ID} });

    my $not_added_to_commutation =
      !$commutation_info
        || !$commutation_info->{commutation_id}
        || $commutation_info->{commutation_id} ne $FORM{COMMUTATION_ID};

    # Set splitter commutation
    if ($not_added_to_commutation) {

      # Check if have ports count defined
      my $cross_info = $Cablecat->crosses_info($FORM{CROSS_ID});
      my $ports_count = $cross_info->{PORTS_COUNT};

      if (!$ports_count || $ports_count eq '0') {
        $html->message('err', $lang{ERROR}, $lang{NO_PORTS_COUNT});
        return 0;
      }

      $Cablecat->commutation_crosses_add({
        %FORM,
        CROSS_ID       => $FORM{CROSS_ID},
        COMMUTATION_ID => $FORM{COMMUTATION_ID}
      });
      show_result($Cablecat, $lang{ADDED}, '', { ID => 'CROSS_ADDED' });
    }
    else {
      $html->message('err', $lang{ERROR}, $lang{ALREADY_ON_ANOTHER_COMMUTATION});
      return 0;
    }
  }
  elsif ($FORM{operation} eq 'DELETE') {
    $Cablecat->delete_links_for_element('CROSS', $FORM{ID}, { commutation_id => $FORM{COMMUTATION_ID} });

    $Cablecat->commutation_crosses_del({}, { cross_id => $FORM{ID}, commutation_id => $FORM{COMMUTATION_ID} });
    show_result($Cablecat, $lang{DEL}, '', { ID => 'ELEMENT_DELETED' });
  }
  elsif ($FORM{operation} eq 'SAVE_COORDS') {
    $Cablecat->commutation_crosses_change({
      _CHANGE_PARAM        => 'CROSS_ID',

      CROSS_ID             => $FORM{ID},
      COMMUTATION_X        => $FORM{X},
      COMMUTATION_Y        => $FORM{Y},
      COMMUTATION_ROTATION => $FORM{COMMUTATION_ROTATION},
    });
    show_result($Cablecat, $lang{CHANGED}, '', { ID => 'COORDS_CHANGED' });
  }
  elsif ($FORM{operation} eq 'SAVE_PORTS') {

    my $check_if_have_links_in_range = sub {
      my ($range_start, $range_finish) = @_;

      my $range_minimized = 0;
      if ($range_finish < $range_start) {
        $range_minimized = 1;
        # Swap (sort)
        ($range_start, $range_finish) = ($range_finish, $range_start);
      }
      # Get all links for this cross
      my $links = $Cablecat->links_for_element_list("CROSS", $FORM{ID}, { COMMUTATION_ID => $FORM{COMMUTATION_ID} });

      # Return 1 as operation error (boolean true)
      _error_show($Cablecat) and return 1;

      my @links_in_range = grep {
        my $is_in_range = 0;
        if ($range_minimized) {
          $is_in_range = $_->{fiber_num_1} > $range_start && $_->{fiber_num_1} <= $range_finish;
        }
        else {
          $is_in_range = $_->{fiber_num_1} >= $range_start && $_->{fiber_num_1} < $range_finish;
        }
        $is_in_range;
      } @$links;

      return scalar(@links_in_range) > 0;
    };

    # Check what range will be changed
    my $prev_start = $FORM{PREVIOUS_PORT_START};
    my $prev_finish = $FORM{PREVIOUS_PORT_FINISH};

    my $new_start = $FORM{PORT_START};
    my $new_finish = $FORM{PORT_FINISH};

    my $links_will_be_dropped = 0;

    if ($prev_start ne $new_start && $new_start > $prev_start) {
      $links_will_be_dropped = $check_if_have_links_in_range->($prev_start, $new_start);
    }

    if (!$links_will_be_dropped
      && $prev_finish ne $new_finish && $new_finish < $prev_finish) {
      $links_will_be_dropped = $check_if_have_links_in_range->($prev_finish, $new_finish);
    }

    # Check if have links for cross ports that will be dropped
    if ($links_will_be_dropped) {
      $html->message('err', $lang{ERROR}, "Links will be dropped on change");
      return 0;
    }

    # Preserve old info
    my $old_info = $Cablecat->commutation_crosses_info(undef, {
      COMMUTATION_ID   => $FORM{COMMUTATION_ID},
      CROSS_ID         => $FORM{ID},
      PORT_START       => $prev_start,
      PORT_FINISH      => $prev_finish,
      SHOW_ALL_COLUMNS => 1
    });

    # Delete old info
    $Cablecat->commutation_crosses_del(undef, {
      commutation_id => $FORM{COMMUTATION_ID},
      cross_id       => $FORM{ID},
      port_start     => $prev_start,
      port_finish    => $prev_finish
    });

    # Insert new info
    $Cablecat->commutation_crosses_add({
      %$old_info,
      PORT_START  => $new_start,
      PORT_FINISH => $new_finish,
    });
    show_result($Cablecat, $lang{SUCCESS}, "$lang{CHANGED}", { ID => 'CROSS_CHANGED' });
  }
  elsif ($FORM{operation} eq 'CHANGE_PORTS') {
    # Get current info
    my $cross = $Cablecat->crosses_info($FORM{ID});
    _error_show($Cablecat) and return 0;

    # Get info for all other ports for this cross on all commutations
    my %cross_used_ports = ();
    # To prevent duplicate adding should pass used ports
    my $cross_ranges = $Cablecat->commutation_crosses_list({
      CROSS_ID    => $FORM{ID},
      PORT_START  => '_SHOW',
      PORT_FINISH => '_SHOW',
      PAGE_ROWS   => 10000
    });
    _error_show($Cablecat) and return 0;

    # Prepare allowed ranges
    foreach my $cross_range (@$cross_ranges) {
      my %range_hash = (
        start  => $cross_range->{port_start},
        finish => $cross_range->{port_finish},
      );

      # Skip current range
      next if ($cross_range->{port_start} eq $FORM{PORT_START} && $cross_range->{port_finish} eq $FORM{PORT_FINISH});

      if (exists $cross_used_ports{$cross_range->{cross_id}}) {
        push(@{$cross_used_ports{$cross_range->{cross_id}}}, \%range_hash);
      }
      else {
        $cross_used_ports{$cross_range->{cross_id}} = [ \%range_hash ];
      }
    }

    # Show template
    $html->tpl_show(_include('cablecat_commutation_cross_change_modal', 'Cablecat'), {
      TOTAL_PORTS        => $cross->{ports_count},
      NAME               => $cross->{name},
      PORT_START_SELECT  => $html->form_select('PORT_START', { SELECTED => $FORM{PORT_START} }),
      PORT_FINISH_SELECT => $html->form_select('PORT_FINISH', { SELECTED => $FORM{PORT_FINISH} }),
      USED_PORTS         => JSON::to_json(\%cross_used_ports),
      SUBMIT_BTN_NAME    => $lang{CHANGE},
      SUBMIT_BTN_ACTION  => 'change',
      %FORM
    }
    );

  }
}

#**********************************************************
=head2 cablecat_commutation_links()

=cut
#**********************************************************
sub cablecat_commutation_links {
  my $commutation_id = shift;

  return '' if !$commutation_id && !$FORM{COMMUTATION_ID};

  my $com_links_list = $Cablecat->links_list({
    COMMUTATION_ID   => $FORM{COMMUTATION_ID} || $commutation_id,
    SHOW_ALL_COLUMNS => 1,
    COLS_UPPER       => 0,
    PAGE_ROWS        => 500000
  });

  my $links = JSON::to_json(
    [
      map {
        $_->{geometry} = JSON::from_json($_->{geometry}) if ($_->{geometry});

        # Commutation works with indexes
        $_->{fiber_num_1} -= 1 if ($_->{fiber_num_1});
        $_->{fiber_num_2} -= 1 if ($_->{fiber_num_2});

        $_;
      } @{$com_links_list}
    ]
  );

  print $links if $FORM{JSON_RESULT};

  return ($com_links_list, $links);
}

#**********************************************************
=head2 cablecat_change_commutation_info()

=cut
#**********************************************************
sub cablecat_change_commutation_info {

  my %result = ();

  if (!$FORM{COMMUTATION_ID} || !$FORM{NAME}) {
    $result{ERROR_MESSAGE} = $lang{FAILED_TO_CHANGE_NAME} || '';
    print JSON::to_json(\%result) if $FORM{JSON_RESULT};
    return \%result;
  }

  $Cablecat->commutations_list({
    ID        => "!$FORM{COMMUTATION_ID}",
    NAME      => $FORM{NAME},
    PAGE_ROWS => 10000
  });

  if ($Cablecat->{TOTAL} > 0) {
    $result{ERROR_MESSAGE} = $lang{NAME_ALREADY_IN_USE} || '';
    print JSON::to_json(\%result) if $FORM{JSON_RESULT};
    return \%result;
  }

  $Cablecat->commutations_change({ ID => $FORM{COMMUTATION_ID}, NAME => $FORM{NAME} });

  if ($Cablecat->{error}) {
    $result{ERROR_MESSAGE} = $lang{ERROR_ON_CHANGE} || '';
    print JSON::to_json(\%result) if $FORM{JSON_RESULT};
    return \%result;
  }

  print JSON::to_json(\%result) if $FORM{JSON_RESULT};
  return \%result;
}

#**********************************************************
=head2 _cablecat_commutation_info_table()

=cut
#**********************************************************
sub _cablecat_commutation_info_table {
  my ($commutation_id, $attr) = @_;

  my $commutation;
  if ($attr->{ID}) {
    $commutation = $attr;
  }
  elsif ($commutation_id) {
    $commutation = $Cablecat->commutations_info($commutation_id);
    _error_show($Cablecat);
  }
  else {
    return '';
  }

  my AXbills::HTML $table = $html->table({
    width       => '100%',
    caption     => '',
    title_plain => [ '#', $lang{NAME}, $lang{WELL}, $lang{CONNECTER}, $lang{ADDRESS}, $lang{CREATED} ],
    qs          => $pages_qs,
    ID          => 'CABLECAT_COMMUTATION_INFO_ID',
  });

  if ($commutation->{WELL_ID}) {
    $commutation->{ADDRESS} = _cablecat_address_for_well_id($commutation->{WELL_ID});
  }

  $table->addrow(
    function_button(
      "#$commutation->{ID}",
      'cablecat_commutation',
      $commutation->{ID},
      { ID_PARAM => 'ID' }),
    _cablecat_form_commutation_name($commutation->{ID}, $commutation->{NAME}),
    _cablecat_result_former_named_chg_link_filter($commutation->{WELL}, {
      VALUES => {
        FUNCTION   => 'cablecat_wells',
        PARAM_NAME => 'WELL_ID',
        WELL_ID    => $commutation->{WELL_ID}
      }
    }),
    _cablecat_result_former_named_chg_link_filter($commutation->{CONNECTER}, {
      VALUES => {
        FUNCTION     => 'cablecat_connecters',
        PARAM_NAME   => 'CONNECTER_ID',
        CONNECTER_ID => $commutation->{CONNECTER_ID}
      }
    }),
    $commutation->{ADDRESS} || '',
    $commutation->{CREATED} || '!',
  );

  return $table->show();
}

#**********************************************************
=head2 _cablecat_form_commutation_name($id, name)

=cut
#**********************************************************
sub _cablecat_form_commutation_name {
  my ($id, $name) = @_;

  $name ||= "";
  return $name unless $id;

  $html->tpl_show(_include('cablecat_change_commutation_name', 'Cablecat'), {
    COMMUTATION_ID => $id,
    SAVE_INDEX     => get_function_index('cablecat_change_commutation_info')
  });

  my $invalid_div = $html->element('div', '', { class => 'invalid-feedback', id => 'INVALID_NAME_FEEDBACK' });

  my $check_span = $html->element('span', '', { class => 'fa fa-check' });
  my $pencil_span = $html->element('span', '', { class => 'fa fa-pencil-alt' });

  my $change_input_group = $html->element('a', $pencil_span, {
    class => 'btn input-group-button',
    id    => 'CHANGE_NAME_BTN'
  });
  my $save_input_group = $html->element('a', $check_span, {
    class => 'btn input-group-button d-none',
    id    => 'SAVE_NAME'
  });

  my $input_group_append = $html->element('div', $change_input_group . $save_input_group, { class => 'input-group-append' });
  my $input_name = $html->element('input', '', { class => 'form-control', name => 'NAME', id => 'NAME', readonly => '1', value => $name });

  return $html->element('div', $input_name . $input_group_append . $invalid_div, { class => 'input-group input-group-sm' });
}

#**********************************************************
=head2 _cablecat_commutation_cables_prepare_json($cable_id) - get cable info, and return JSON string ref

  Arguments:
    $cable_id - int, Cablecat cable id

  Returns:
    hash_ref - JSON like structure for cable

=cut
#**********************************************************
sub _cablecat_commutation_cables_prepare_json {
  my ($cable_id, $attr) = @_;
  $cable_id =~ s/,/;/g if ($cable_id);

  my $cables_list = [];
  if ($attr->{COMMUTATION_ID}) {
    # Return info for all cables on commutation
    my $commutation_info = $Cablecat->commutations_info($attr->{COMMUTATION_ID}, {
      SHOW_ALL_COLUMNS => 0,
      CABLE_IDS        => '_SHOW',
      COLS_UPPER       => 0
    });
    $cable_id = $commutation_info->{cable_ids};
    $cable_id =~ s/,/;/g if ($cable_id);

    $cables_list = $Cablecat->cables_list({
      ID               => $cable_id || '_SHOW',
      COMMUTATION_ID   => $attr->{COMMUTATION_ID},
      SHOW_ALL_COLUMNS => 1,
      PAGE_ROWS        => 10000,
      COLS_UPPER       => 0,
    });
    _error_show($Cablecat);
  }
  elsif ($cable_id) {
    # Return info for cable ( cables ) specified by $cable_id
    $cables_list = $Cablecat->cables_list({
      ID               => $cable_id,
      SHOW_ALL_COLUMNS => 1,
      PAGE_ROWS        => 1,
      COLS_UPPER       => 0,
    });
    _error_show($Cablecat);
  }
  else {
    return '';
  }

  my @result_list = ();
  foreach my $cable (@{$cables_list}) {

    if (!defined $cable->{modules_count} || !defined $cable->{fibers_count}) {
      my $cable_link = _cablecat_get_cable_button($cable->{id});
      $html->message('warn', $lang{ERROR},
        "Modules or fibers count is not defined. Can't display cable $cable_link ($cable->{id})");
      return 0;
    }
    _error_show($Cablecat);

    if (!$cable->{modules_colors} || !$cable->{fibers_colors}) {
      $html->message('err', $lang{ERROR}, "$lang{NO} $lang{COLOR_SCHEME} $lang{FOR} "
        . _cablecat_get_cable_button($cable->{id}, { NAME => $cable->{name} })
        . " ( $cable->{id} )"
      );
      return 0;
    }

    my $other_commutations_for_cable = $Cablecat->commutation_cables_list({
      CABLE_ID       => $cable->{id},
      COMMUTATION_ID => ($attr->{COMMUTATION_ID}) ? ('!' . $attr->{COMMUTATION_ID}) : '_SHOW',
      CONNECTER      => '_SHOW',
    });

    my %other_commutation_hash = map {
      $_->{commutation_id} => $_->{connecter}
    } @{$other_commutations_for_cable};

    $cable->{outer_color} //= '#000000';

    my $params = {
      id    => +$cable->{id},
      image => {
        modules              => +$cable->{modules_count},
        fibers               => +$cable->{fibers_count},
        color                => $cable->{outer_color},
        color_scheme         => [ map {'#' . $_} split ',', $cable->{fibers_colors} ],
        modules_color_scheme => [ map {'#' . $_} split ',', $cable->{modules_colors} ],
      },
      meta  => {
        name               => $cable->{name},
        well_1_id          => $cable->{well_1_id},
        well_2_id          => $cable->{well_2_id},
        well_1             => $cable->{well_1},
        well_2             => $cable->{well_2},
        map_btn => $Auxiliary->maps_show_object_button($MAP_LAYER_ID{CABLE}, $cable->{point_id}, {
          RETURN_HREF => 1
        }),
        other_commutations => \%other_commutation_hash
      }
    };

    my $commutations_for_cable = $Cablecat->commutation_cables_list({
      CABLE_ID       => $cable->{id},
      COMMUTATION_ID => $attr->{COMMUTATION_ID},
      COMMUTATION_X  => '_SHOW',
      COMMUTATION_Y  => '_SHOW',
      POSITION       => '_SHOW',
      ID             => '_SHOW',
    });
    
    if ($Cablecat->{TOTAL} > 0) {
      my $cable_info = $commutations_for_cable->[0];
      $params->{start_x} = $cable_info->{commutation_x};
      $params->{start_y} = $cable_info->{commutation_y};
      $params->{change_id} = $cable_info->{id};
      $params->{meta}{position} = $cable_info->{position};
    }

    push @result_list, $params;
  }

  return \@result_list;
}

#**********************************************************
=head2 _cablecat_commutation_splitters($splitter_id, $attr)

  $splitter_id - num or array_ref

=cut
#**********************************************************
sub _cablecat_commutation_splitters {
  my ($splitter_id, $attr) = @_;

  my $splitters_list = [];
  if ($attr->{COMMUTATION_ID}) {
    $splitters_list = $Cablecat->splitters_list({
      ID               => $splitter_id || '_SHOW',
      COMMUTATION_ID   => $attr->{COMMUTATION_ID},
      SHOW_ALL_COLUMNS => 1,
      PAGE_ROWS        => 10000,
      COLS_UPPER       => 0,
    });
    _error_show($Cablecat);
  }
  elsif ($splitter_id) {
    $splitters_list = $Cablecat->splitters_list({
      ID               => $splitter_id,
      SHOW_ALL_COLUMNS => 1,
      PAGE_ROWS        => 1,
      COLS_UPPER       => 0,
    });
    _error_show($Cablecat);
  }
  else {
    return '';
  }

  #  my @result_list = ();
  #  foreach my $splitter ( $splitters_list ) {
  #
  #  }
  #
  #  return \@result_list;
  return $splitters_list;
}

#**********************************************************
=head2 _cablecat_commutation_equipment($equipment_id)

=cut
#**********************************************************
sub _cablecat_commutation_equipment {
  my ($equipment_id, $attr) = @_;

  return '' unless (defined $equipment_id || defined $attr->{COMMUTATION_ID});

  my $equipment_list = [];
  $equipment_list = $Cablecat->commutation_equipment_list({
    ID               => ($equipment_id // '_SHOW'),
    COMMUTATION_ID   => ($attr->{COMMUTATION_ID} // '_SHOW'),
    SHOW_ALL_COLUMNS => 1,
    PAGE_ROWS        => 10000,
    COLS_UPPER       => 0,
  });
  _error_show($Cablecat);

  foreach my $equipment (@{$equipment_list}) {
    next if $equipment->{ports_type} ne '4';

    $equipment->{ports_type} = $Cablecat->ports_type_by_equipment($equipment->{nas_id});
  }

  return [
    map {
      $_->{commutation_equipment_id} = $_->{id};
      $_->{id} = $_->{nas_id} if ($_->{nas_id});
      $_
    } @{$equipment_list}
  ];
}

#**********************************************************
=head2 _cablecat_commutation_onus($cross_id)

=cut
#**********************************************************
sub _cablecat_commutation_onus {
  my ($onu_id, $attr) = @_;

  return '' unless (defined $onu_id || defined $attr->{COMMUTATION_ID});
  my $onus_list = [];

  $onus_list = $Cablecat->commutation_onu_list({
    ID               => ($onu_id || '_SHOW'),
    COMMUTATION_ID   => ($attr->{COMMUTATION_ID} || '_SHOW'),
    UID              => '_SHOW',
    SHOW_ALL_COLUMNS => 1,
    PAGE_ROWS        => 10000,
    COLS_UPPER       => 0,
  });
  _error_show($Cablecat);

  return [
    map {
      $_->{commutation_onu_id} = $_->{commutation_id};
      $_->{id} = $_->{id} if ($_->{id});
      $_->{uid} = ($_->{uid}) if($_->{uid});
      $_
    } @{$onus_list}
  ];
}
#**********************************************************
=head2 _cablecat_commutation_crosses($cross_id)

=cut
#**********************************************************
sub _cablecat_commutation_crosses {
  my ($cross_id, $attr) = @_;

  return '' unless (defined $cross_id || defined $attr->{COMMUTATION_ID});

  my $crosses_list = [];
  $crosses_list = $Cablecat->commutation_crosses_list({
    CROSS_ID         => ($cross_id || '_SHOW'),
    COMMUTATION_ID   => ($attr->{COMMUTATION_ID} || '_SHOW'),
    SHOW_ALL_COLUMNS => 1,
    PAGE_ROWS        => 10000,
    COLS_UPPER       => 0,
  });
  _error_show($Cablecat);

  return [
    map {
      $_->{commutation_cross_id} = $_->{commutation_id};
      $_->{id} = $_->{cross_id} if ($_->{cross_id});
      $_->{ports} = ($_->{port_finish} - $_->{port_start}) + 1;
      $_->{name} = ($_->{name} || q{}) . " (" . ($_->{port_start} || q{}) . "-" . ($_->{port_finish} || q{}) . ")";
      $_
    } @{$crosses_list}
  ];
}

#**********************************************************
=head2 _cablecat_cable_element()

=cut
#**********************************************************
sub _cablecat_cable_element {
  my ($element_id, $fiber_num) = @_;

  my %cable = ();

  my $cable_info = $Cablecat->cables_info($element_id);
  return () if !$Cablecat->{TOTAL};

  my @colors = split(',', $cable_info->{fibers_colors});
  my $colors_count = @colors;

  while ($fiber_num >= $colors_count) {
    $fiber_num -= $colors_count;
  }

  $cable{NAME} = $cable_info->{NAME};
  $cable{MODULES_COUNT} = $cable_info->{MODULES_COUNT};
  $cable{FIBERS_COUNT} = $cable_info->{FIBERS_COUNT};
  $cable{COLOR} = $colors[$fiber_num];
  $cable{COLOR} = substr($cable{COLOR}, 0, 6) if (length($cable{COLOR}) > 6);

  @colors = split(',', $cable_info->{modules_colors});
  $colors_count = @colors;

  $fiber_num = $fiber_num ? $fiber_num : 1;
  my $cur_module_first = $fiber_num / ($cable{FIBERS_COUNT} / $cable{MODULES_COUNT});
  $cur_module_first += 1;
  $cable{MODULE} = $cable{MODULES_COUNT} == 1 ? 1 : int $cur_module_first;
  my $module = $cable{MODULE};

  while ($module > $colors_count) {
    $module -= $colors_count;
  }

  $cable{MODULE_COLOR} = $colors[$module - 1];
  $cable{MODULE_COLOR} = substr($cable{MODULE_COLOR}, 0, 6) if (length($cable{MODULE_COLOR}) > 6);
  return %cable;
}

#**********************************************************
=head2 _cablecat_splitter_element()

=cut
#**********************************************************
sub _cablecat_splitter_element {
  my ($element_id, $fiber_num) = @_;

  my %splitter = ();
  my $splitter_info = $Cablecat->splitters_info($element_id);

  if ($Cablecat->{TOTAL}) {
    my @colors = split(',', $splitter_info->{FIBERS_COLORS});
    my $colors_count = @colors;

    while ($fiber_num > $colors_count) {
      $fiber_num -= $colors_count;
    }

    $splitter{COLOR} = $colors[$fiber_num - 1];
    if (length($splitter{COLOR}) > 6) {
      $splitter{COLOR} = substr($splitter{COLOR}, 0, 6);
    }
    $splitter{NAME} = $splitter_info->{TYPE} . "#" . $splitter_info->{ID};
    $splitter{MODULE} = $lang{SPLITTER};
  }
  else {
    $splitter{NAME} = "";
    $splitter{MODULE} = "";
  }

  return %splitter;
}

#**********************************************************
=head2 _cablecat_equipment_element()

=cut
#**********************************************************
sub _cablecat_equipment_element {
  my ($element_id) = @_;

  if (!$Equipment) {
    require Equipment;
    Equipment->import();
    $Equipment = Equipment->new($db, $admin, \%conf);
  }

  my %equipment = ();
  my $equipment_info = $Equipment->_list({
    NAS_ID    => $element_id,
    NAS_NAME  => '_SHOW',
    COLS_NAME => 1,
  });

  if ($Equipment->{TOTAL}) {
    $equipment{NAME} = $equipment_info->[0]{nas_name};
    $equipment{MODULE} = $lang{EQUIPMENT};
  }
  else {
    $equipment{NAME} = "";
    $equipment{MODULE} = "";
  }

  return %equipment;
}

#**********************************************************
=head2 _cablecat_cross_element()

=cut
#**********************************************************
sub _cablecat_cross_element {
  my ($element_id) = @_;

  my %cross = ();
  my $cross_info = $Cablecat->crosses_info($element_id);
  if ($Cablecat->{TOTAL}) {
    $cross{NAME} = $cross_info->{NAME};
    $cross{MODULE} = $lang{CROSS};
  }
  else {
    $cross{NAME} = "";
    $cross{MODULE} = "";
  }

  return %cross;
}

#**********************************************************
=head2 _cablecat_commutation_info_table()

=cut
#**********************************************************
sub _cablecat_commutation_links_table {
  my $com_links_list = shift;
  my ($attr) = @_;

  my $table_links = $html->table({
    width      => '100%',
    caption    => ($lang{COMMUTATION_SCHEME} || "") . ": " . ($attr->{ID} || ""),
    title      => [ $lang{PORT}, $lang{MODULE}, $lang{FIBER}, $lang{LINK}, $lang{PORT}, $lang{MODULE}, $lang{FIBER}, $lang{ATTENUATION} ],
    ID         => 'CABLECAT_ITEMS',
    DATA_TABLE => 1,
  });

  foreach my $link (@$com_links_list) {
    my %first_element = ();
    my %second_element = ();

    if ($link->{element_1_type} eq "CABLE") {
      %first_element = _cablecat_cable_element($link->{element_1_id}, $link->{fiber_num_1});
    }
    elsif ($link->{element_1_type} eq "SPLITTER") {
      %first_element = _cablecat_splitter_element($link->{element_1_id}, $link->{fiber_num_1});
    }
    elsif ($link->{element_1_type} eq "EQUIPMENT") {
      %first_element = _cablecat_equipment_element($link->{element_1_id});
    }
    elsif ($link->{element_1_type} eq "CROSS") {
      %first_element = _cablecat_cross_element($link->{element_1_id});
    }
    else {
      $first_element{NAME} = "";
      $first_element{MODULE} = "";
    }

    if ($link->{element_2_type} eq "CABLE") {
      %second_element = _cablecat_cable_element($link->{element_2_id}, $link->{fiber_num_2});
    }
    elsif ($link->{element_2_type} eq "SPLITTER") {
      %second_element = _cablecat_splitter_element($link->{element_2_id}, $link->{fiber_num_2});
    }
    elsif ($link->{element_2_type} eq "EQUIPMENT") {
      %second_element = _cablecat_equipment_element($link->{element_2_id});
    }
    elsif ($link->{element_2_type} eq "CROSS") {
      %second_element = _cablecat_cross_element($link->{element_2_id});
    }
    else {
      $second_element{NAME} = "";
      $second_element{MODULE} = "";
    }

    $first_element{COLOR} = $first_element{COLOR} ? $first_element{COLOR} : "cccccc";
    $second_element{COLOR} = $second_element{COLOR} ? $second_element{COLOR} : "cccccc";

    $first_element{MODULE_COLOR} = $first_element{MODULE_COLOR} ? $first_element{MODULE_COLOR} : "cccccc";
    $second_element{MODULE_COLOR} = $second_element{MODULE_COLOR} ? $second_element{MODULE_COLOR} : "cccccc";

    $table_links->addrow($first_element{NAME}, $html->badge($first_element{MODULE}, {STYLE => "style=\"background-color: #$first_element{MODULE_COLOR} !important;\""}),
      $html->badge($link->{fiber_num_1} + 1, {STYLE => "style=\"background-color: #$first_element{COLOR} !important;\""}), '',
      $second_element{NAME}, $html->badge($second_element{MODULE}, {STYLE => "style=\"background-color: #$second_element{MODULE_COLOR} !important;\""}),
      $html->badge($link->{fiber_num_2} + 1, {STYLE => "style=\"background-color: #$second_element{COLOR} !important;\""}), '');
  }

  return $table_links;
}


1;