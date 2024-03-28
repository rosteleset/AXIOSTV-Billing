use strict;
use warnings FATAL => 'all';

our ($Cablecat, $html, %lang, %conf, $admin, $db, @CABLECAT_EXTRA_COLORS, %permissions, %LIST_PARAMS);

use Address;
my $Address = Address->new($db, $admin, \%conf);

#**********************************************************
=head2 cablecat_cable_reports()

=cut
#**********************************************************
sub cablecat_cable_reports {

  my $cable_types_select = make_select_from_db_table($Cablecat, 'Cablecat', 'cable_types', 'TYPE_ID', {
    NO_EXT_MENU => 1
  })->({
    AUTOSUBMIT => 'form',
    SELECTED   => $FORM{TYPE_ID} || ''
  });

  my %ADDRESS_PARAMS = _get_address_named_params(\%FORM);

  my $choose_address_form = form_address_select2({ HIDE_FLAT => 1, HIDE_ADD_BUILD_BUTTON => 1 });

  my $planned_input = $html->tpl_show(templates('form_row_checkbox'), {
    INPUT => $html->form_input('PLANNED', '', { TYPE => 'checkbox', STATE => $FORM{planned} }),
    NAME  => $lang{PLANNED}
  }, { OUTPUT2RETURN => 1 });

  require Control::Reports;
  reports({
    EX_INPUTS       => [ $choose_address_form, $planned_input ],
    EXT_SELECT      => $cable_types_select,
    EXT_SELECT_NAME => $lang{CABLE_TYPE},
    PERIOD_FORM     => 1,
    DATE_RANGE      => 1,
    NO_GROUP        => 1,
  });

  delete $LIST_PARAMS{DISTRICT_ID};

  $LIST_PARAMS{TYPE_ID} = $FORM{TYPE_ID} || '_SHOW';
  $LIST_PARAMS{CREATED} = ($FORM{FROM_DATE} && $FORM{TO_DATE}) ? "$FORM{FROM_DATE}/$FORM{TO_DATE}" : '_SHOW';

  $LIST_PARAMS{DISTRICT_ID} = $FORM{ADDRESS_DISTRICT} || '_SHOW';
  $LIST_PARAMS{STREET_ID} = $FORM{ADDRESS_STREET} || '_SHOW';
  $LIST_PARAMS{LOCATION_ID} = $FORM{ADDRESS_BUILD} || '_SHOW';

  ## Table
  my AXbills::HTML $table;
  my $cables_list;

  ($table, $cables_list) = result_former({
    INPUT_DATA      => $Cablecat,
    FUNCTION        => 'cables_list',
    BASE_FIELDS     => 0,
    DEFAULT_FIELDS  => 'ID,NAME,CREATED,LENGTH,RESERVE,LENGTH_CALCULATED,POINT_ID',
    HIDDEN_FIELDS   => 'TYPE_ID,POLYLINE_ID,BUILDS_ID,STREET_ID,DISTRICT_ID',
    SKIP_USER_TITLE => 1,
    EXT_FIELDS      => 0,
    EXT_TITLES      => {
      id                => '#',
      name              => $lang{NAME},
      length            => "$lang{LENGTH} $lang{IN_FACT}",
      reserve           => $lang{RESERVE},
      length_calculated => "$lang{LENGTH} $lang{CALCULATED}",
      created           => $lang{CREATED},
      point_id          => $lang{MAPS}
    },
    FILTER_COLS     => {
      point_id => '_cablecat_result_former_cable_point_id_filter::POLYLINE_ID,POINT_ID',
      name     => '_cablecat_result_former_named_chg_link_filter::PARAM_NAME=id,FUNCTION=cablecat_cables,ID',
    },
    TABLE           => {
      width   => '100%',
      caption => "Cablecat : $lang{CABLE} $lang{LENGTH}",
      ID      => 'CABLE_REPORT_TABLE',
      EXPORT  => 1,
    },
    MAKE_ROWS       => 1,
    SEARCH_FORMER   => 1,
    MODULE          => 'Cablecat',
  });

  print $table->show();

  my $total_table = $html->table({
    title => [ '', '', '', $lang{IN_FACT}, $lang{RESERVE}, $lang{CALCULATED} ],
    pages => $cables_list ? scalar @{$cables_list} : 0,
    qs    => $pages_qs,
    ID    => 'TOTAL_CABLE_ID'
  });

  my ($length_sum, $length_calc, $reserve_sum) = (0, 0, 0);
  foreach (@{$cables_list}) {
    $length_sum += $_->{length} // 0;
    $length_calc += $_->{length_calculated} // 0;
    $reserve_sum += $_->{reserve} // 0;
  }
  $total_table->addrow($lang{TOTAL}, '', '', $length_sum, $reserve_sum, $length_calc);
  print $total_table->show();

  return 1;
}

#**********************************************************
=head2 _get_address_named_params()

=cut
#**********************************************************
sub _get_address_named_params {
  my ($attr) = @_;

  my %result = ();

  if ($attr->{ADDRESS_DISTRICT}) {
    my $districts_list = $Address->district_list({
      ID        => $attr->{ADDRESS_DISTRICT},
      NAME      => '_SHOW',
      COLS_NAME => 1,
      PAGE_ROWS => 1
    });

    if ($districts_list && ref $districts_list eq 'ARRAY' && scalar @{$districts_list}) {
      $result{ADDRESS_DISTRICT} = $districts_list->[0]->{name};
    }

  }

  if ($attr->{ADDRESS_STREET}) {
    my $streets_list = $Address->street_list({
      ID          => $attr->{ADDRESS_STREET},
      STREET_NAME => '_SHOW',
      COLS_NAME   => 1,
      PAGE_ROWS   => 1
    });

    if ($streets_list && ref $streets_list eq 'ARRAY' && scalar @{$streets_list}) {
      $result{ADDRESS_STREET} = $streets_list->[0]->{street_name};
    }

  }

  if ($attr->{ADDRESS_BUILD}) {
    my $builds_list = $Address->build_list({
      LOCATION_ID => $attr->{ADDRESS_BUILD},
      NUMBER      => '_SHOW',
      COLS_NAME   => 1,
      PAGE_ROWS   => 1
    });

    if ($builds_list && ref $builds_list eq 'ARRAY' && scalar @{$builds_list}) {
      $result{ADDRESS_BUILD} = $builds_list->[0]->{number};
    }

  }
  return %result;
}
1;