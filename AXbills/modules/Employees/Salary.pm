=head1 NAME

  Employees:Salary

=head2 SYNOPSIS

  This is code about cashbox, spending and coming in cashbox .
  Works with PrivatBank Api for mobile.

=cut


use strict;
use warnings FATAL => 'all';
use Employees;
use AXbills::Base;

use Admins;

our (
  $db,
  %conf,
  $admin,
  %lang,
  $html,
  @PRIORITY,
  @MONTHES,
  %permissions,
);

my $Employees = Employees->new($db, $admin, \%conf);
my $Admins = Admins->new($db, $admin, \%conf);

#**********************************************************

=head2 employees_cashbox_main() - menu for adding, changing and deleting cashbox

  Arguments:

  Returns:
    true
=cut

#**********************************************************
sub employees_cashbox_main {
  my $action = 'add';
  my $action_lang = $lang{ADD};
  my $action_title = $lang{ADD_CASHBOX};
  my %CASHBOX;
  my $cashbox = '';

  if ($FORM{add}) {
    $cashbox = $Employees->employees_add_cashbox({ AID => $FORM{ADMIN_DEFAULT}, %FORM });
    if (!$Employees->{errno}) {
      $html->message("success", "$lang{SUCCESS}", "$lang{CASHBOX_ADDED}");
      $Employees->employees_cashbox_admins_add({ IDS => $FORM{ADMINS}, CASHBOX_ID => $cashbox->{INSERT_ID} });
    }
    else {
      $html->message("err", "$lang{ERROR}", "$lang{CASHBOX_NOT_ADDED}");
    }
  }
  elsif ($FORM{change}) {
    $Employees->employees_change_cashbox({ AID => $FORM{ADMIN_DEFAULT}, %FORM });

    if (!$Employees->{errno}) {
      $html->message("success", "$lang{SUCCESS}", "$lang{CHANGED}");
      $Employees->employees_cashbox_admins_del({ CASHBOX_ID => $FORM{ID} });
      $Employees->employees_cashbox_admins_add({ IDS => $FORM{ADMINS}, CASHBOX_ID => $FORM{ID} });
    }
    else {
      $html->message("err", "$lang{ERROR}", "$lang{NOT_CHANGED}");
    }
  }
  elsif ($FORM{chg}) {
    $action = 'change';
    $action_lang = $lang{CHANGE};
    $action_title = $lang{CHANGE_CASHBOX};

    my $cashbox_info = $Employees->employees_info_cashbox({ ID => $FORM{chg} });

    $CASHBOX{ID} = $FORM{chg};
    $CASHBOX{NAME} = $cashbox_info->{NAME};
    $CASHBOX{ADMIN_DEFAULT} = $cashbox_info->{AID};
    $CASHBOX{ADMINS} = $cashbox_info->{ADMINS};
    $CASHBOX{COMMENTS} = $cashbox_info->{COMMENTS};
  }
  elsif ($FORM{del}) {
    $Employees->employees_delete_cashbox({ ID => $FORM{del} });
    if (!$Employees->{errno}) {
      $html->message("success", "$lang{SUCCESS}", "$lang{CASHBOX_DELETED}");
      $Employees->employees_cashbox_admins_del({ CASHBOX_ID => $FORM{del} });
    }
    else {
      $html->message("err", "$lang{ERROR}", "$lang{CASHBOX_NOT_DELETED}");
    }
  }

  $CASHBOX{ADMINS_SELECT} = sel_admins({ NAME => 'ADMINS', SELECTED => $CASHBOX{ADMINS}, MULTIPLE => 1 });
  $CASHBOX{ADMIN_DEFAULT_SELECT} = sel_admins({ NAME => 'ADMIN_DEFAULT', SELECTED => $CASHBOX{ADMIN_DEFAULT}});

  if ($FORM{add_form} || $FORM{chg}) {
    $html->tpl_show(
      _include('employees_cashbox_add', 'Employees'),
      {
        %CASHBOX,
        ACTION       => $action,
        ACTION_LANG  => $action_lang,
        ACTION_TITLE => $action_title
      }
    );
  }

  my $types = translate_list($Employees->employees_list_cashbox({ COLS_NAME => 1 }));

  result_former(
    {
      INPUT_DATA      => $Employees,
      LIST            => $types,
      FUNCTION        => 'employees_list_cashbox',
      BASE_FIELDS     => 0,
      DEFAULT_FIELDS  => "ID, NAME, ADMINS, ADMIN, COMMENTS",
      FUNCTION_FIELDS => 'employees_cashbox_balance:$lang{BALANCE}:id, change, del',
      EXT_TITLES      => {
        'name'          => "$lang{NAME}",
        'id'            => "ID",
        'admin_default' => "$lang{ADMIN_DEFAULT}",
        'admins'        => "$lang{ADMINS}",
        'comments'      => "$lang{COMMENTS}"
      },
      TABLE           => {
        width   => '100%',
        caption => "$lang{CASHBOXS}",
        qs      => $pages_qs,
        ID      => 'EMPLOYEES',
        header  => '',
        EXPORT  => 1,
        MENU    => "$lang{ADD}:index=$index&add_form=1:add;",
      },
      MAKE_ROWS       => 1,
      SEARCH_FORMER   => 1,
      MODULE          => 'Employees',
      TOTAL           => 1
    }
  );

  return 1;
}

#**********************************************************
=head2 employees_cashbox_balance() -

  Arguments:

  Returns:

=cut
#**********************************************************
sub employees_cashbox_balance {

  my $action = 'choose';
  my $action_lang = "$lang{CHOOSE}";
  my %CASHBOX;

  my ($from_date, $to_date);

  # get dates
  if ($FORM{FROM_DATE}) {
    $from_date = $FORM{FROM_DATE};
  }
  else {
    my ($y, $m, undef) = split('-', $DATE);
    $from_date = "$y-$m-01";
  }

  if ($FORM{TO_DATE}) {
    $to_date = $FORM{TO_DATE};
  }
  else {
    my ($y, $m, undef) = split('-', $DATE);
    my $days_in_month = days_in_month();
    $to_date = "$y-$m-$days_in_month";
  }

  # get list of comings and spendings
  my $coming_cashbox_list = $Employees->employees_list_coming({
    COLS_NAME      => 1,
    CASHBOX_ID     => $FORM{ID} || $FORM{CASHBOX_ID},
    COMING_TYPE_ID => $FORM{COMING_TYPE_ID} || '',
    FROM_DATE      => $from_date,
    TO_DATE        => $to_date,
    SORT           => 5,
    PAGE_ROWS      => 9999,
    DESC           => 'desc',
  });

  my $spending_cashbox_list = $Employees->employees_list_spending({
    COLS_NAME        => 1,
    CASHBOX_ID       => $FORM{ID} || $FORM{CASHBOX_ID},
    SPENDING_TYPE_ID => $FORM{SPENDING_TYPE_ID} || '',
    FROM_DATE        => $from_date,
    TO_DATE          => $to_date,
    SORT             => 5,
    PAGE_ROWS        => 9999,
    DESC             => 'desc',
  });

  my $total_coming_amount = 0.00;
  my $total_spending_amount = 0.00;

  my %dates_hash; # hash with dates and spending/comings

  # make dates hash
  foreach my $coming (@$coming_cashbox_list) {
    $total_coming_amount += $coming->{amount} || 0;
    push(@{$dates_hash{ ($coming->{date} || 'NODATE') }{coming}}, ($coming->{amount} || 0));
  }

  foreach my $spending (@$spending_cashbox_list) {
    $total_spending_amount += $spending->{amount} || 0;
    push(@{$dates_hash{ ($spending->{date} || 'NODATE') }{spending}}, ($spending->{amount} || 0));
  }

  my $balance = $total_coming_amount - $total_spending_amount;

  my @dates;             # date array
  my @coming_per_date;   # incoming sum per date
  my @spending_per_date; # spending sum per date

  # make data for graphics
  foreach my $key (sort keys %dates_hash) {
    push(@dates, $key);
    my $spending_sum = 0;
    my $coming_sum = 0;

    foreach my $each_spend (@{$dates_hash{$key}{spending}}) {
      $spending_sum += $each_spend || 0;
    }
    foreach my $each_come (@{$dates_hash{$key}{coming}}) {
      $coming_sum += $each_come || 0;
    }
    push(@coming_per_date, $coming_sum);
    push(@spending_per_date, $spending_sum);
  }

  $CASHBOX{CASHBOX_SELECT} = employees_cashbox_select({ ID => $FORM{ID} });
  $CASHBOX{COMING_TYPE_SELECT} = employees_coming_select({ ID => $FORM{ID} });
  $CASHBOX{SPENDING_TYPE_SELECT} = employees_spending_select({ ID => $FORM{ID} });
  $CASHBOX{PERIOD} = $html->form_daterangepicker({
    NAME      => 'FROM_DATE/TO_DATE',
    FORM_NAME => 'report_panel',
    VALUE     => $FORM{'FROM_DATE_TO_DATE'},
    WITH_TIME => 0,
  });

  $CASHBOX{CHART} = $html->chart({
    TYPE              => 'bar',
    X_LABELS          => \@dates,
    DATA              => {
      "$lang{SPENDING}" => \@spending_per_date,
      "$lang{COMING}"   => \@coming_per_date
    },
    BACKGROUND_COLORS => {
      "$lang{COMING}"   => 'rgba(2, 99, 2, 0.5)',
      "$lang{SPENDING}" => 'rgba(5, 99, 132, 0.5)'
    },
    OUTPUT2RETURN     => 1,
    IN_CONTAINER      => 1
  });

  #COMING BALANCE TABLE
  my @coming_title_plain = ($lang{SUM}, $lang{CASHBOX}, "$lang{COMING} $lang{TYPE}", $lang{DATE}, $lang{ADMIN}, $lang{COMMENTS});

  my $coming_list = $Employees->employees_list_coming({
    FROM_DATE      => $from_date,
    TO_DATE        => $to_date,
    CASHBOX_ID     => $FORM{CASHBOX_ID} || '',
    COMING_TYPE_ID => $FORM{COMING_TYPE_ID} || '',
    PAGE_ROWS      => 9999,
    COLS_NAME      => 1,
  });

  my $coming_report_table = $html->table({
    width       => '100%',
    caption     => $lang{COMING},
    title_plain => \@coming_title_plain,
    ID          => 'EMPLOYEES_COMING_REPORT',
    DATA_TABLE  => 1,
    DT_CLICK    => 1
  });

  my $month_total_sum = 0.00;
  my $month_total_count = 0;

  foreach my $coming (@$coming_list) {
    $coming_report_table->addrow(
      $coming->{amount},
      $coming->{cashbox_name},
      $coming->{coming_type_name},
      $coming->{date},
      $coming->{admin},
      $coming->{comments},
    );

    $month_total_count += 1;
    $month_total_sum += $coming->{amount};
  }
  my @coming_total_rows = ();
  push @coming_total_rows, [ "$lang{SUM}:", $html->b(sprintf('%.2f', $month_total_sum)) ];
  push @coming_total_rows, [ "$lang{COUNT}", $html->b($month_total_count) ];

  my $coming_total_table = $html->table({
    width      => '100%',
    cols_align => [ 'right', 'right' ],
    rows       => \@coming_total_rows
  });

  $CASHBOX{COMING_TABLE} = $coming_report_table->show();
  $CASHBOX{TOTAL_COMING_TABLE} = $coming_total_table->show();

  #SPENDING BALANCE TABLE
  my @spending_title_plain = ($lang{SUM},
    $lang{CASHBOX},
    "$lang{SPENDING} $lang{TYPE}",
    $lang{DATE},
    $lang{ADMIN},
    $lang{COMMENTS}
  );

  my $spending_list = $Employees->employees_list_spending({
    FROM_DATE        => $from_date,
    TO_DATE          => $to_date,
    CASHBOX_ID       => $FORM{CASHBOX_ID} || '',
    SPENDING_TYPE_ID => $FORM{SPENDING_TYPE_ID} || '',
    PAGE_ROWS        => 9999,
    COLS_NAME        => 1,
  });

  my $spending_report_table = $html->table({
    width       => '100%',
    caption     => $lang{SPENDING},
    title_plain => \@spending_title_plain,
    ID          => 'EMPLOYEES_SPENDING_REPORT',
    DATA_TABLE  => 1,
    DT_CLICK    => 1,
  });

  my $spending_month_total_sum = 0.00;
  my $spending_month_total_count = 0;

  foreach my $coming (@$spending_list) {
    $spending_report_table->addrow(
      $coming->{amount},
      $coming->{cashbox_name},
      $coming->{spending_type_name},
      $coming->{date},
      $coming->{admin},
      $coming->{comments},
    );

    $spending_month_total_count += 1;
    $spending_month_total_sum += $coming->{amount};
  }
  my @spending_total_rows = ();
  push @spending_total_rows, [ "$lang{SUM}:", $html->b(sprintf('%.2f', $spending_month_total_sum)) ];
  push @spending_total_rows, [ "$lang{COUNT}", $html->b($spending_month_total_count) ];

  my $spending_total_table = $html->table({
    width      => '100%',
    cols_align => [ 'right', 'right' ],
    rows       => \@spending_total_rows
  });

  $CASHBOX{SPENDING_TABLE} = $spending_report_table->show();
  $CASHBOX{TOTAL_SPENDING_TABLE} = $spending_total_table->show();

  $html->tpl_show(_include('employees_balance', 'Employees'), {
    %CASHBOX,
    FROM_DATE      => $from_date,
    TO_DATE        => $to_date,
    ACTION         => $action,
    ACTION_LANG    => $action_lang,
    BALANCE        => $balance,
    TOTAL_COMING   => $total_coming_amount,
    TOTAL_SPENDING => $total_spending_amount,
  });

  return 1;
}

#**********************************************************

=head2 employees_cashbox_spending_type() -

  Arguments:

  Returns:

=cut

#**********************************************************
sub employees_cashbox_spending_type {

  my $action = 'add';
  my $action_lang = "$lang{ADD}";
  my %CASHBOX;

  if ($FORM{add}) {
    $Employees->employees_add_type({ %FORM, SPENDING => 1 });

    if (!$Employees->{errno}) {
      $html->message("success", "$lang{SUCCESS}", "$lang{TYPE} $lang{ADDED}");
    }
    else {
      $html->message("err", "$lang{ERROR}", "$lang{TYPE} $lang{NOT} $lang{ADDED}");
    }
  }
  elsif ($FORM{change}) {
    $Employees->employees_change_type({ SPENDING => 1, %FORM });

    if (!$Employees->{errno}) {
      $html->message("success", "$lang{SUCCESS}", "$lang{CHANGED}");
    }
    else {
      $html->message("err", "$lang{ERROR}", "$lang{NOT_CHANGED}");
    }
  }

  if ($FORM{del}) {
    $Employees->employees_delete_type({ SPENDING => 1, ID => $FORM{del} });

    if (!$Employees->{errno}) {
      $html->message("success", "$lang{SUCCESS}", "$lang{TYPE} $lang{DELETED}");
    }
    else {
      $html->message("err", "$lang{ERROR}", "$lang{NOT} $lang{DELETED}");
    }
  }

  if ($FORM{chg}) {
    $action = 'change';
    $action_lang = $lang{CHANGE};

    $html->message("info", $lang{CHANGE});

    my $spending_type = $Employees->employees_info_type({ SPENDING => 1, ID => $FORM{chg} });
    $CASHBOX{ID} = $FORM{chg};
    $CASHBOX{NAME} = $spending_type->{NAME};
    $CASHBOX{COMMENTS} = $spending_type->{COMMENTS};
  }

  $html->tpl_show(_include('employees_spending_type', 'Employees'), {
    %CASHBOX,
    ACTION      => $action,
    ACTION_LANG => $action_lang,
  });

  result_former({
    INPUT_DATA      => $Employees,
    FUNCTION        => 'employees_list_spending_type',
    BASE_FIELDS     => 3,
    DEFAULT_FIELDS  => "id, name, comments",
    FUNCTION_FIELDS => "change, del",
    EXT_TITLES      => {
      'name'     => "$lang{NAME}",
      'id'       => "#",
      'comments' => "$lang{COMMENTS}"
    },
    TABLE           => {
      width   => '100%',
      caption => "$lang{SPENDING} $lang{TYPE}",
      qs      => $pages_qs,
      ID      => 'EMPLOYEES',
      header  => '',
      EXPORT  => 1,
    },
    MAKE_ROWS       => 1,
    SEARCH_FORMER   => 1,
    MODULE          => 'Employees',
    TOTAL           => 1
  });

  return 1;
}

#**********************************************************

=head2 employees_cashbox_coming_type() -

  Arguments:

  Returns:

  Examples:

=cut

#**********************************************************
sub employees_cashbox_coming_type {

  my $action = 'add';
  my $action_lang = "$lang{ADD}";
  my %CASHBOX;

  if ($FORM{add}) {
    if ($FORM{DEFAULT_COMING}) {
      $Employees->coming_default_type();
    }

    $Employees->employees_add_type({ %FORM, COMING => 1 });

    if (!$Employees->{errno}) {
      $html->message("success", "$lang{SUCCESS}", "$lang{TYPE} $lang{ADDED}");
    }
    else {
      $html->message("err", "$lang{ERROR}", "$lang{TYPE} $lang{NOT} $lang{ADDED}");
    }
  }
  elsif ($FORM{change}) {
    if ($FORM{DEFAULT_COMING}) {
      $Employees->coming_default_type();
    }

    $Employees->employees_change_type({ COMING => 1, %FORM });

    if (!$Employees->{errno}) {
      $html->message("success", "$lang{SUCCESS}", "$lang{CHANGED}");
    }
    else {
      $html->message("err", "$lang{ERROR}", "$lang{NOT_CHANGED}");
    }
  }

  if ($FORM{del}) {
    $Employees->employees_delete_type({ COMING => 1, ID => $FORM{del} });

    if (!$Employees->{errno}) {
      $html->message("success", "$lang{SUCCESS}", "$lang{TYPE} $lang{DELETED}");
    }
    else {
      $html->message("err", "$lang{ERROR}", "$lang{TYPE} $lang{NOT_DELETED}");
    }
  }

  if ($FORM{chg}) {
    $action = 'change';
    $action_lang = "$lang{CHANGE}";

    $html->message("info", $lang{CHANGED});

    my $coming_type = $Employees->employees_info_type({ COMING => 1, ID => $FORM{chg} });
    $CASHBOX{ID} = $FORM{chg};
    $CASHBOX{NAME} = $coming_type->{NAME};
    $CASHBOX{CHECK_DEFAULT} = 'checked' if ($coming_type->{DEFAULT_COMING});
    $CASHBOX{COMMENTS} = $coming_type->{COMMENTS};
  }

  $html->tpl_show(
    _include('employees_coming_type', 'Employees'),
    {
      %CASHBOX,
      ACTION      => $action,
      ACTION_LANG => $action_lang,
    }
  );

  my $types = translate_list($Employees->employees_list_coming_type({ COLS_NAME => 1 }));

  foreach my $default_type (@$types) {
    $default_type->{default_coming} = $html->element('label', '', { class => 'fa fa-check' }) if ($default_type->{default_coming});
  }

  result_former(
    {
      INPUT_DATA      => $Employees,
      LIST            => $types,
      BASE_FIELDS     => 4,
      DEFAULT_FIELDS  => "id, name, comments, default_coming",
      FUNCTION_FIELDS => "change, del",
      SKIP_USER_TITLE => 1,
      EXT_TITLES      => {
        'name'           => "$lang{NAME}",
        'id'             => "#",
        'default_coming' => $lang{DEFAULT},
        'comments'       => "$lang{COMMENTS}"
      },
      TABLE           => {
        width   => '100%',
        caption => "$lang{COMING} $lang{TYPE}",
        qs      => $pages_qs,
        ID      => 'EMPLOYEES',
        header  => '',
        EXPORT  => 1,
      },
      MAKE_ROWS       => 1,
      SEARCH_FORMER   => 1,
      MODULE          => 'Employees',
      TOTAL           => 1
    }
  );

  return 1;
}

#**********************************************************
=head2 employees_cashbox_spending_add() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub employees_cashbox_spending_add {

  my $action = 'add';
  my $action_lang = $lang{ADD};
  my %CASHBOX;

  if ($FORM{add}) {
    $Employees->employees_add_spending({ %FORM, AID => $admin->{AID} });

    if (!$Employees->{errno}) {
      $html->message("success", "$lang{SUCCESS}", "$lang{ADDED}");
    }
    else {
      $html->message("err", "$lang{ERROR}", "$lang{NOT_ADDED}");
    }
  }
  elsif ($FORM{change}) {
    $Employees->employees_change_spending({ %FORM, AID => $admin->{AID} });

    if (!$Employees->{errno}) {
      $html->message("success", "$lang{SUCCESS}", "$lang{CHANGED}");
    }
    else {
      $html->message("err", "$lang{ERROR}", "$lang{NOT_CHANGED}");
    }
  }

  if ($FORM{del}) {
    $Employees->employees_delete_spending({ ID => $FORM{del} });

    if (!$Employees->{errno}) {
      $Employees->employees_delete_payed_salary({ SPENDING_ID => $FORM{del} });
      $html->message("success", "$lang{SUCCESS}", "$lang{DELETED}");
    }
    else {
      $html->message("err", "$lang{ERROR}", "$lang{NOT_DELETED}");
    }
  }

  if ($FORM{chg}) {
    $html->message("info", $lang{CHANGE});

    my $spending_info = $Employees->employees_info_spending({ COLS_NAME => 1, ID => $FORM{chg} });

    $action = 'change';
    $action_lang = "$lang{CHANGE}";
    $CASHBOX{DATE} = $spending_info->{DATE};
    $CASHBOX{COMMENTS} = $spending_info->{COMMENTS};
    $CASHBOX{AMOUNT} = $spending_info->{AMOUNT};
    $CASHBOX{SPENDING_TYPE_ID} = $spending_info->{SPENDING_TYPE_ID};
    $CASHBOX{CASHBOX_ID} = $spending_info->{CASHBOX_ID};
    $CASHBOX{ID} = $FORM{chg};
    $CASHBOX{ADMIN_SPENDING} = $spending_info->{ADMIN_SPENDING};
  }

  $CASHBOX{ADMIN_SELECT} = sel_admins({ NAME => 'ADMIN_SPENDING', SELECTED => $CASHBOX{ADMIN_SPENDING} });

  $CASHBOX{SPENDING_TYPE_SELECT} = $html->form_select(
    'SPENDING_TYPE_ID',
    {
      SELECTED    => $FORM{SPENDING_TYPE_ID} || $CASHBOX{SPENDING_TYPE_ID},
      SEL_LIST    => $Employees->employees_list_spending_type({ COLS_NAME => 1 }),
      SEL_KEY     => 'id',
      SEL_VALUE   => 'name',
      NO_ID       => 1,
      SEL_OPTIONS => { "" => "" },
    }
  );

  $CASHBOX{CASHBOX_SELECT} = employees_cashbox_select({ ID => $CASHBOX{CASHBOX_ID} });

  $html->tpl_show(
    _include('employees_spending_add', 'Employees'),
    {
      %CASHBOX,
      ACTION      => $action,
      ACTION_LANG => $action_lang,
      DATE        => $DATE,
    }
  );

  result_former(
    {
      INPUT_DATA      => $Employees,
      FUNCTION        => 'employees_list_spending',
      BASE_FIELDS     => 0,
      DEFAULT_FIELDS  => "ID, AMOUNT, CASHBOX_NAME, SPENDING_TYPE_NAME, DATE, ADMIN, ADMIN_SPENDING, COMMENTS",
      FUNCTION_FIELDS => 'employees_spending_document:$lang{DOCS}:id,change, del',
      EXT_TITLES      => {
        'amount'             => "$lang{SUM}",
        'cashbox_name'       => "$lang{CASHBOX}",
        'spending_type_name' => "$lang{SPENDING} $lang{TYPE}",
        'date'               => "$lang{DATE}",
        'id'                 => "ID",
        'admin'              => "$lang{ADMIN}",
        'comments'           => "$lang{COMMENTS}",
        'admin_spending'     => "$lang{TO_USER}",
      },
      TABLE           => {
        width   => '100%',
        caption => "$lang{SPENDING}",
        qs      => $pages_qs,
        ID      => 'EMPLOYEES',
        header  => '',
        EXPORT  => 1,
      },
      MAKE_ROWS       => 1,
      SEARCH_FORMER   => 1,
      MODULE          => 'Employees',
      TOTAL           => 1
    }
  );

  return 1;
}

#**********************************************************

=head2 employees_cashbox_coming_add() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut

#**********************************************************
sub employees_cashbox_coming_add {

  my $action = 'add';
  my $action_lang = "$lang{ADD}";
  my %CASHBOX;

  if ($FORM{add}) {
    $Employees->employees_add_coming({ %FORM, AID => $admin->{AID} });

    if (!$Employees->{errno}) {
      $html->message("success", "$lang{SUCCESS}", "$lang{ADDED}");
    }
    else {
      $html->message("err", "$lang{ERROR}", "$lang{NOT_ADDED}");
    }
  }
  elsif ($FORM{change}) {
    $Employees->employees_change_coming({ %FORM, AID => $admin->{AID} });

    if (!$Employees->{errno}) {
      $html->message("success", "$lang{SUCCESS}", "$lang{CHANGED}");
    }
    else {
      $html->message("err", "$lang{ERROR}", "$lang{NOT_CHANGED}");
    }
  }

  if ($FORM{del}) {
    $Employees->employees_delete_coming({ ID => $FORM{del} });

    if (!$Employees->{errno}) {
      $html->message("success", "$lang{SUCCESS}", "$lang{DELETED}");
    }
    else {
      $html->message("err", "$lang{ERROR}", "$lang{NOT_DELETED}");
    }
  }

  if ($FORM{chg}) {
    $html->message("info", $lang{CHANGE});

    my $coming_info = $Employees->employees_info_coming({ COLS_NAME => 1, ID => $FORM{chg} });

    $action = 'change';
    $action_lang = "$lang{CHANGE}";
    $CASHBOX{DATE} = $coming_info->{DATE};
    $CASHBOX{COMMENTS} = $coming_info->{COMMENTS};
    $CASHBOX{AMOUNT} = $coming_info->{AMOUNT};
    $CASHBOX{COMING_TYPE_ID} = $coming_info->{COMING_TYPE_ID};
    $CASHBOX{CASHBOX_ID} = $coming_info->{CASHBOX_ID};
    $CASHBOX{ID} = $FORM{chg};
  }

  $CASHBOX{COMING_TYPE_SELECT} = $html->form_select(
    'COMING_TYPE_ID',
    {
      SELECTED    => $FORM{COMING_TYPE_ID} || $CASHBOX{COMING_TYPE_ID},
      SEL_LIST    => $Employees->employees_list_coming_type({ COLS_NAME => 1 }),
      SEL_KEY     => 'id',
      SEL_VALUE   => 'name',
      NO_ID       => 1,
      SEL_OPTIONS => { "" => "" },
    }
  );

  $CASHBOX{CASHBOX_SELECT} = employees_cashbox_select({ ID => $CASHBOX{CASHBOX_ID} });

  $html->tpl_show(
    _include('employees_coming_add', 'Employees'),
    {
      %CASHBOX,
      ACTION      => $action,
      ACTION_LANG => $action_lang,
      DATE        => $DATE
    }
  );

  result_former(
    {
      INPUT_DATA      => $Employees,
      FUNCTION        => 'employees_list_coming',
      BASE_FIELDS     => 0,
      DEFAULT_FIELDS  => "ID, AMOUNT, CASHBOX_NAME, COMING_TYPE_NAME, ADMIN, DATE, COMMENTS, LOGIN",
      FUNCTION_FIELDS => 'employees_coming_document:$lang{DOCS}:id,change, del',
      EXT_TITLES      => {
        'amount'           => "$lang{SUM}",
        'cashbox_name'     => "$lang{CASHBOX}",
        'coming_type_name' => "$lang{COMING} $lang{TYPE}",
        'date'             => "$lang{DATE}",
        'admin'            => "$lang{ADMIN}",
        'login'            => "$lang{USER}",
        'comments'         => "$lang{COMMENTS}",
        'id'               => "#",
      },
      FUNCTION_INDEX  => $index,
      TABLE           => {
        width   => '100%',
        caption => "$lang{COMING}",
        qs      => $pages_qs,
        ID      => 'EMPLOYEES',
        header  => '',
        EXPORT  => 1,
      },
      MAKE_ROWS       => 1,
      SEARCH_FORMER   => 1,
      MODULE          => 'Employees',
      TOTAL           => 1
    }
  );

  return 1;
}

#**********************************************************
=head2 employees_coming_reports()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub employees_coming_reports {
  require Control::Reports;
  reports(
    {
      DATE_RANGE       => 1,
      DATE             => $FORM{DATE},
      REPORT           => '',
      EX_PARAMS        => {
      },
      PERIOD_FORM      => 1,
      PERIODS          => 1,
      NO_TAGS          => 1,
      NO_GROUP         => 1,
      NO_ACTIVE_ADMINS => 1,
      EXT_TYPE         => {
        ADMINS    => $lang{ADMINS},
        PER_MONTH => $lang{PER_MONTH},
      },
    }
  );
  my ($y, $m, undef) = split('-', $DATE);
  my $from_date = "$y-$m-01";
  my $to_date = "$y-$m-" . days_in_month({ DATE => $DATE });

  my @total_rows = ();
  my $report_table = '';

  if ($FORM{DATE}) {
    my @title_plain = ("$lang{SUM}",
      "$lang{CASHBOX}",
      "$lang{COMING} $lang{TYPE}",
      "$lang{DATE}",
      "$lang{ADMIN}",
      "$lang{COMMENTS}");

    my $coming_list = $Employees->employees_list_coming({
      FROM_DATE => $FORM{DATE} || $from_date,
      TO_DATE   => $FORM{DATE} || $to_date,
      COLS_NAME => 1,
    });

    $report_table = $html->table(
      {
        width       => '100%',
        caption     => $lang{COMING},
        title_plain => \@title_plain,
        ID          => 'EMPLOYEES_COMING_REPORT',
        DATA_TABLE  => 1,
      }
    );

    my $month_total_sum = 0.00;
    my $month_total_count = 0;

    foreach my $coming (@$coming_list) {
      $report_table->addrow(
        $coming->{amount},
        $coming->{cashbox_name},
        $coming->{coming_type_name},
        $coming->{date},
        $coming->{admin},
        $coming->{comments},
      );

      $month_total_count += 1;
      $month_total_sum += $coming->{amount};
    }

    push @total_rows, [ "$lang{SUM}:", $html->b(sprintf('%.2f', $month_total_sum)) ];
    push @total_rows, [ "$lang{COUNT}", $html->b($month_total_count) ];
  }
  else {
    my @title_plain = ($lang{DATE}, "$lang{SUM}", $lang{COUNT});
    $report_table = $html->table(
      {
        width       => '100%',
        caption     => $lang{COMING},
        title_plain => \@title_plain,
        ID          => 'EMPLOYEES_COMING_REPORT',
        DATA_TABLE  => 1,
      }
    );
    my $report_info = $Employees->employees_list_coming_report({
      FROM_DATE => $FORM{FROM_DATE} || $from_date,
      TO_DATE   => $FORM{TO_DATE} || $to_date,
      COLS_NAME => 1,
    });

    my $month_total_sum = 0.00;
    my $month_total_count = 0;
    foreach my $info (@$report_info) {
      $report_table->addrow(
        $html->button($info->{date}, "index=$index&DATE=$info->{date}"),
        $info->{total_sum},
        $info->{total_count});

      $month_total_count += $info->{total_count};
      $month_total_sum += $info->{total_sum};
    }

    push @total_rows, [ "$lang{SUM}:", $html->b(sprintf('%.2f', $month_total_sum)) ];
    push @total_rows, [ "$lang{COUNT}", $html->b($month_total_count) ];
  }

  my $table = $html->table(
    {
      width      => '100%',
      cols_align => [ 'right', 'right' ],
      rows       => \@total_rows
    }
  );

  print $report_table->show();
  print $table->show();

  return 1;
}

#**********************************************************
=head2 employees_coming_reports()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub employees_spending_reports {
  require Control::Reports;
  reports(
    {
      DATE_RANGE       => 1,
      DATE             => $FORM{DATE},
      REPORT           => '',
      EX_PARAMS        => {
      },
      PERIOD_FORM      => 1,
      PERIODS          => 1,
      NO_TAGS          => 1,
      NO_GROUP         => 1,
      NO_ACTIVE_ADMINS => 1,
      EXT_TYPE         => {
        ADMINS    => $lang{ADMINS},
        PER_MONTH => $lang{PER_MONTH},
      }
    }
  );
  my ($y, $m, undef) = split('-', $DATE);
  my $from_date = "$y-$m-01";
  my $to_date = "$y-$m-" . days_in_month({ DATE => $DATE });

  my @total_rows = ();
  my $report_table = '';

  if ($FORM{DATE}) {
    my @title_plain = ("$lang{SUM}",
      "$lang{CASHBOX}",
      "$lang{SPENDING} $lang{TYPE}",
      "$lang{DATE}",
      "$lang{ADMIN}",
      "$lang{COMMENTS}");

    my $spending_list = $Employees->employees_list_spending({
      FROM_DATE => $FORM{DATE} || $from_date,
      TO_DATE   => $FORM{DATE} || $to_date,
      COLS_NAME => 1,
    });

    $report_table = $html->table(
      {
        width       => '100%',
        caption     => $lang{SPENDING},
        title_plain => \@title_plain,
        ID          => 'EMPLOYEES_SPENDING_REPORT',
        DATA_TABLE  => 1,
      }
    );

    my $month_total_sum = 0.00;
    my $month_total_count = 0;

    foreach my $coming (@$spending_list) {
      $report_table->addrow(
        $coming->{amount},
        $coming->{cashbox_name},
        $coming->{spending_type_name},
        $coming->{date},
        $coming->{admin},
        $coming->{comments},
      );

      $month_total_count += 1;
      $month_total_sum += $coming->{amount};
    }

    push @total_rows, [ "$lang{SUM}:", $html->b(sprintf('%.2f', $month_total_sum)) ];
    push @total_rows, [ "$lang{COUNT}", $html->b($month_total_count) ];
  }
  else {
    my @title_plain = ($lang{DATE}, "$lang{SUM}", $lang{COUNT});
    $report_table = $html->table(
      {
        width       => '100%',
        caption     => $lang{SPENDING},
        title_plain => \@title_plain,
        ID          => 'EMPLOYEES_SPENDING_REPORT',
        DATA_TABLE  => 1,

      }
    );
    my $report_info = $Employees->employees_list_spending_report({
      FROM_DATE => $FORM{FROM_DATE} || $from_date,
      TO_DATE   => $FORM{TO_DATE} || $to_date,
      COLS_NAME => 1,
    });

    my $month_total_sum = 0.00;
    my $month_total_count = 0;
    foreach my $info (@$report_info) {
      $report_table->addrow(
        $html->button($info->{date}, "index=$index&DATE=$info->{date}"),
        $info->{total_sum},
        $info->{total_count});

      $month_total_count += $info->{total_count};
      $month_total_sum += $info->{total_sum};
    }

    push @total_rows, [ "$lang{SUM}:", $html->b(sprintf('%.2f', $month_total_sum)) ];
    push @total_rows, [ "$lang{COUNT}", $html->b($month_total_count) ];
  }

  my $table = $html->table(
    {
      width      => '100%',
      cols_align => [ 'right', 'right' ],
      rows       => \@total_rows
    }
  );

  print $report_table->show();
  print $table->show();

  return 1;
}

#**********************************************************

=head2 employees_cashbox_select() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut

#**********************************************************
sub employees_cashbox_select {
  my ($attr) = @_;

  my $employees_cashbox_select = $html->form_select(
    $attr->{NAME} || 'CASHBOX_ID',
    {
      SELECTED    => $conf{EMPLOYEES_DEFAULT_CASHBOX} || $FORM{CASHBOX_ID} || $attr->{ID}, # add defalt value
      SEL_LIST    => $Employees->employees_list_cashbox({ COLS_NAME => 1 }),
      SEL_KEY     => 'id',
      SEL_VALUE   => 'name',
      NO_ID       => 1,
      SEL_OPTIONS => { "" => "" },
      MAIN_MENU   => get_function_index('employees_cashbox_main')
    }
  );

  return $employees_cashbox_select;
}

#**********************************************************

=head2 employees_spending_select() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut

#**********************************************************
sub employees_spending_select {
  my ($attr) = @_;

  my $list = $Employees->employees_list_spending_type({ COLS_NAME => 1 });

  push(@$list, { 'id' => '!0', name => "$lang{NO_TYPE}" });

  my $spending_type_select = $html->form_select(
    'SPENDING_TYPE_ID',
    {
      SELECTED    => $FORM{SPENDING_TYPE_ID} || $attr->{ID},
      SEL_LIST    => $list,
      SEL_KEY     => 'id',
      SEL_VALUE   => 'name',
      NO_ID       => 1,
      SEL_OPTIONS => { "" => "" },
      MAIN_MENU   => get_function_index('employees_cashbox_spending_type')
    }
  );

  return $spending_type_select;
}

#**********************************************************

=head2 employees_coming_select() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut

#**********************************************************
sub employees_coming_select {
  my ($attr) = @_;

  my $list = $Employees->employees_list_coming_type({ COLS_NAME => 1 });

  push(@$list, { 'id' => '!0', name => "$lang{NO_TYPE}" });

  my $coming_type_select = $html->form_select(
    'COMING_TYPE_ID',
    {
      SELECTED    => $FORM{COMING_TYPE_ID} || $attr->{ID},
      SEL_LIST    => $list,
      SEL_KEY     => 'id',
      SEL_VALUE   => 'name',
      NO_ID       => 1,
      SEL_OPTIONS => { "" => "" },
      MAIN_MENU   => get_function_index('employees_cashbox_coming_type')
    }
  );

  return $coming_type_select;
}

#**********************************************************

=head2 employees_spending_document() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub employees_spending_document {

  return 1;
}

#**********************************************************

=head2 employees_coming_document() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub employees_coming_document {

  return 1;
}

#**********************************************************
=head2 employees_reference_works() -

=cut
#**********************************************************
sub employees_reference_works {
  my $action = 'add';
  my $action_lang = "$lang{ADD}";
  my %INFO;

  if ($FORM{add}) {
    $Employees->employees_add_reference_works({ %FORM });

    if (!$Employees->{errno}) {
      $html->message('success', "$lang{SUCCESS}", "$lang{ADDED}");
    }
  }
  elsif ($FORM{change}) {
    $Employees->employees_change_reference_works({ %FORM });

    if (!$Employees->{errno}) {
      $html->message('success', "$lang{SUCCESS}", "$lang{CHANGED}");
    }
  }
  elsif ($FORM{chg}) {
    my $info_work = $Employees->employees_info_reference_works({ ID => $FORM{chg} });

    $INFO{NAME} = $info_work->{NAME};
    $INFO{SUM} = $info_work->{SUM};
    $INFO{TIME} = $info_work->{TIME};
    $INFO{UNITS} = $info_work->{UNITS};
    $INFO{DISABLED} = $info_work->{DISABLED};
    $INFO{ID} = $info_work->{ID};
    $INFO{COMMENTS} = $info_work->{COMMENTS};
    $action = 'change';
    $action_lang = "$lang{CHANGE}";
  }
  elsif ($FORM{del} && $FORM{COMMENTS}) {
    $Employees->employees_delete_reference_works({ ID => $FORM{del} });

    if (!$Employees->{errno}) {
      $html->message('success', "$lang{SUCCESS}", "$lang{DELETED}");
    }
  }

  _error_show($Employees);

  $html->tpl_show(_include('employees_reference_works', 'Employees'), {
    ACTION      => $action,
    ACTION_LANG => $action_lang,
    %INFO
  });

  result_former({
    INPUT_DATA      => $Employees,
    FUNCTION        => 'employees_list_reference_works',
    BASE_FIELDS     => 0,
    DEFAULT_FIELDS  => "ID, NAME, SUM, TIME, UNITS, DISABLED, COMMENTS",
    FUNCTION_FIELDS => 'change, del',
    SELECT_VALUE    => {
      disabled => {
        0 => "$lang{ENABLE}:text-primary",
        1 => "$lang{DISABLED}:text-danger"
      },
    },
    EXT_TITLES      => {
      'id'       => "ID",
      'name'     => "$lang{NAME}",
      'sum'      => "$lang{SUM}",
      'TIME'     => "$lang{TIME} ($lang{HOURS})",
      'disabled' => "$lang{DISABLED}",
      'units'    => "$lang{UNITS_}",
      'comments' => "$lang{COMMENTS}",
    },
    TABLE           => {
      width   => '100%',
      caption => "$lang{REFERENCE_WORKS}",
      qs      => $pages_qs,
      ID      => 'REFERENCE_WORKS',
      header  => '',
      EXPORT  => 1,
    },
    MAKE_ROWS       => 1,
    SEARCH_FORMER   => 1,
    MODULE          => 'Employees',
    TOTAL           => 1
  });

  return 1;
}

#**********************************************************

=head2 employees_report_list() -

  Arguments:
    $attr -


  Returns:

  Examples:

=cut

#**********************************************************
sub employees_report_list {

  if ($FORM{wtch}) {
    employees_works_list(
      {
        WORK_ID => $FORM{wtch},
        EXT_ID  => '',
      }
    );
    return 1;
  }

  my %srm_table_info;
  my %srm_table_info_id;
  my %info;

  $info{DATE} = $html->form_daterangepicker({ NAME => 'FROM_DATE/TO_DATE' });
  my $reference_works = $Employees->employees_list_reference_works(
    {
      DISABLED  => $FORM{disable} ? '0,1' : '!1',
      NAME      => '_SHOW',
      SUM       => '_SHOW',
      COLS_NAME => 1,
    }
  );
  my @ids;
  my $ref_work = 0;

  foreach my $ref_id (@$reference_works) {
    $ref_work = push @ids, $ref_id->{id};
  }
  my $id_work_string = join(';', @ids);
  my $workers = $Employees->employees_works_list(
    {
      WORK_ID   => $id_work_string,
      WORK      => '_SHOW',
      NAME      => '_SHOW',
      SUM       => '_SHOW',
      DATE      => $FORM{FROM_DATE_TO_DATE},
      COLS_NAME => 1,
    }
  );
  $srm_table_info{'max_sum'} = 0;
  foreach my $srm_work_info (@$workers) {
    $srm_table_info_id{ $srm_work_info->{work_id} } = $srm_work_info->{work};

    $srm_table_info{ $srm_work_info->{work_id} . '_SUM' } += $srm_work_info->{sum} || 0;
    $srm_table_info{ $srm_work_info->{work_id} . '_WORK_SUM' } += 1;
    $srm_table_info{'total_sum'} += $srm_work_info->{sum};
    $srm_table_info{'total_sum_work'} += 1;
    if ($srm_table_info{ $srm_work_info->{work_id} . '_SUM' } > $srm_table_info{'max_sum'}) {
      $srm_table_info{'max_sum'} = $srm_table_info{ $srm_work_info->{work_id} . '_SUM' };
    }
  }
  my $employees_works_table = $html->table(
    {
      width   => '100%',
      caption => "$lang{WORK}",
      title   => [ "ID", $lang{NAME}, $lang{SUM}, $lang{PERCENTAGE} . ' ' . $lang{SUM}, $lang{EXECUTED},
        $lang{PERCENTAGE} . ' ' . $lang{EXECUTED} ]
    }
  );
  my $bage;
  foreach my $srm_referens (@$reference_works) {
    if ($srm_referens->{disabled} == 0) {
      $bage = '';
    }
    else {
      $bage = $html->element('i', '', { class => 'fa fa-fw fa-times' });
    }

    if (defined($srm_table_info_id{ $srm_referens->{'id'} })) {
      $employees_works_table->addrow(
        $srm_referens->{'id'},
        $bage . $html->button($srm_table_info_id{ $srm_referens->{'id'} },
          "index=" . get_function_index('employees_reference_works') . "&chg=$srm_referens->{'id'}&MODULE=Employees"),
        $srm_table_info{ $srm_referens->{'id'} . '_SUM' },
        $html->progress_bar(
          {
            TOTAL        => $srm_table_info{'total_sum'},
            COMPLETE     => $srm_table_info{ $srm_referens->{'id'} . '_SUM' },
            PERCENT_TYPE => 1,
            COLOR        => 'ADAPTIVE',
            MAX          => $srm_table_info{'max_sum'},
          },
        ),

        $html->button($srm_table_info{ $srm_referens->{'id'} . '_WORK_SUM' },
          "index=$index&wtch=$srm_referens->{'id'}"),
        $html->progress_bar(
          {
            TOTAL        => $srm_table_info{'total_sum_work'},
            COMPLETE     => $srm_table_info{ $srm_referens->{'id'} . '_WORK_SUM' },
            PERCENT_TYPE => 1,
            COLOR        => 'MAX_COLOR',
          },
        ),
      );
    }
    else {
      $employees_works_table->addrow(
        $srm_referens->{'id'},
        $bage . $html->button($srm_referens->{'name'}),
        '0',
        $html->progress_bar(
          {
            TOTAL        => $srm_table_info{'total_sum'},
            COMPLETE     => '0',
            PERCENT_TYPE => 1,
            COLOR        => 'ADAPTIVE',
            MAX          => $srm_table_info{'max_sum'},
          },
        ),
        $html->button('0', "index=$index&wtch=$srm_referens->{'id'}"),
        $html->progress_bar(
          {
            TOTAL        => $srm_table_info{'total_sum_work'},
            COMPLETE     => '0',
            PERCENT_TYPE => 1,
            COLOR        => 'ADAPTIVE',
          },
        )
      );
    }
  }

  $employees_works_table->addrow("$lang{TOTAL}", '', $srm_table_info{'total_sum'}, '', $srm_table_info{'total_sum_work'}, '');
  $html->tpl_show(_include('employees_report_list', 'Employees'), \%info);

  print $employees_works_table->show();

  return 1;

}

#**********************************************************
=head2 cashbox_salary() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub employees_salary {
  #  $Employees = Employees->new($db, $admin, \%conf);

  # checking permissions
  if (!$permissions{7}{8}) {
    $html->message('warn', $lang{WARNING}, $lang{ERR_ACCESS_DENY});
    return 1;
  }

  my %sum_all = ();

  if ($FORM{confirm}) {
    $Employees->employees_add_spending(
      {
        AMOUNT           => $FORM{SUM},
        CASHBOX_ID       => $FORM{CASHBOX_ID},
        SPENDING_TYPE_ID => $FORM{SPENDING_TYPE_ID},
        DATE             => $DATE,
        ADMIN_SPENDING   => $FORM{AID},
        AID              => $admin->{AID},
      }
    );

    if (!$Employees->{errno}) {
      $Employees->employees_add_payed_salary(
        {
          AID         => $FORM{AID},
          BET         => $FORM{SUM},
          YEAR        => $FORM{YEAR},
          MONTH       => $FORM{MONTH},
          SPENDING_ID => $Employees->{INSERT_ID},
        }
      );
      my $payment_statement_button = $html->button("$lang{PRINT}",
        "qindex=" . get_function_index("employees_print_payment_statement") . "&header=2&AID=$FORM{AID}&PRINT_STATEMENT=1", {
          ICON   => 'fas fa-print',
          target => '_blank',
        });
      $html->message("success", "$lang{ADDED}", "Платежная ведомость: $payment_statement_button");
    }
    else {
      $html->message("err", "$lang{ERROR}", "$lang{EXIST}");
    }
    delete $FORM{MONTH};
  }

  if ($FORM{all_salary}) {
    employees_pay_salary_all(\%FORM, \%sum_all);
  }

  my ($year, $month, undef) = split('-', $DATE);
  $month = ($FORM{MONTH} + 1) if (defined $FORM{MONTH} && $FORM{MONTH} =~ /^\d+$/);
  $year = ($FORM{YEAR}) if (defined $FORM{YEAR});

  my $month_start = "$year-$month-1";
  my $month_end = "$year-$month-" . days_in_month();

  if ($FORM{pay_salary}) {
    $Employees->employees_add_payed_salary(
      {
        AID   => $FORM{aid},
        BET   => $FORM{bet} + $FORM{extra_amount},
        YEAR  => $FORM{year},
        MONTH => $FORM{month},
      }
    );
  }

  my @SCHEDULE_TYPES = ("", "$lang{MONTHLY}", "$lang{HOURLY}", "$lang{OTHER}");

  my $month_select = $html->form_select(
    'MONTH',
    {
      SELECTED     => $FORM{MONTH} || $month - 1,
      SEL_ARRAY    => \@MONTHES,
      ARRAY_NUM_ID => 1,
    }
  );

  my ($current_year, undef, undef) = split('-', $DATE);
  my @YEARS = reverse ($current_year - 4 ... $current_year);

  my $year_select = $html->form_select(
    'YEAR',
    {
      SELECTED  => $FORM{YEAR} || $year,
      SEL_ARRAY => \@YEARS,
    }
  );

  my $positions_hash = $Employees->position_list({
    ID        => '_SHOW',
    NAME      => '_SHOW',
    LIST2HASH => 'id, position',
  });

  foreach my $key (keys %{$positions_hash}) {
    $positions_hash->{$key} = _translate($positions_hash->{$key});
  }

  my $position_select = $html->form_select('POSITION',
    {
      SEL_HASH    => $positions_hash,
      SELECTED    => $FORM{POSITION},
      NO_ID       => 1,
      SEL_OPTIONS => { "" => "" },
    });

  my $time_sheet_listing = $Employees->time_sheet_list(
    {
      COLS_NAME  => 1,
      DATE_START => $FORM{TIME_START} || $month_start,
      DATE_END   => $FORM{TIME_END} || $month_end,
      POSITION   => $FORM{POSITION} || 0,
    }
  );

  if (!(defined $time_sheet_listing)) {
    $html->tpl_show(
      _include('employees_date_choose', 'Employees'),
      {
        MONTH      => $month_select,
        YEAR       => $year_select,
        POSITIONS  => $position_select,
      }
    );
    $html->message("info", "$lang{TIME_SHEET} $lang{EMPTY}", "$lang{CHANGE} $lang{DATE}");
    return 1;
  }

  my %admins;

  foreach my $admin_ (@$time_sheet_listing) {
    my $aid = $admin_->{aid};
    my $fio = $admin_->{name};
    my $position = _translate($positions_hash->{$admin_->{position}});

    my $dates = {
      'overtime'  => $admin_->{overtime},
      'work_time' => $admin_->{work_time},
      'extra_fee' => $admin_->{extra_fee}
    };

    $admins{$fio}{aid} = $aid;
    $admins{$fio}{position} = $position;
    push(@{$admins{$fio}{dates}}, $dates);
  }

  my $salary_table = $html->table(
    {
      width      => '100%',
      caption    => "$lang{SALARY}",
      title      => [ '',
        "$lang{FIO}",
        "$lang{TYPE}",
        "$lang{BET}",
        "$lang{BONUS}",
        "$lang{WORK}",
        "$lang{TOTAL}",
        "$lang{SUM} $lang{PAYED}",
        "$lang{LAST_ACTIVITY}",
        "$lang{SUM_TO_PAY}",
        '',
        ''],
      ID         => 'EMPLOYEES_SALARY',
      DATA_TABLE => 1,
    }
  );

  my @work_rows = ();
  my $work_time_norms = $Employees->employees_time_norms_list({
    YEAR      => $year,
    MONTH     => $month,
    HOURS     => '_SHOW',
    DAYS      => '_SHOW',
    COLS_NAME => 1,
  });

  if (!$work_time_norms->[0]{hours}) {
    $html->message('warn', $lang{WORKING_TIME_NORMS_EMPTY}, $lang{MONTHLY_BET_WILL_NOT_CALC});
  }

  my $plus_button = $html->element('i', "", {
    class => 'fa fa-fw fa-plus-circle tree-button',
    style => 'font-size:16px;color:green;',
  });

  foreach my $key (sort keys %admins) {
    my $aid = $admins{$key}{aid};
    my $fio = $key;
    my @all_admins_dates = $admins{$key}{dates};
    my $extra_amount = 0;
    my $bet = 0;
    my $sum_for_works = 0;

    my $schedule_info = $Employees->employees_info_bet({ AID => $aid, COLS_NAME => 1 });

    if (!(defined $schedule_info)) {
      next;
    }

    my $admins_works_from_msgs = $Employees->employees_works_list({
      EMPLOYEE_ID => $aid,
      FROM_DATE   => "$year-" . ($month > 9 ? $month : sprintf('0%1d', $month)) . "-01",
      TO_DATE     => "$year-" . ($month > 9 ? $month : sprintf('0%1d', $month)) . "-" . days_in_month({ DATE => "$year-$month-01" }),
      SUM         => '_SHOW',
      EXT_ID      => '_SHOW',
      EMPLOYEE    => '_SHOW',
      WORK        => '_SHOW',
      RATIO       => '_SHOW',
      COLS_NAME   => 1, });

    foreach my $work (@$admins_works_from_msgs) {
      $sum_for_works += $work->{sum};

      if ($FORM{aid} && $aid == $FORM{aid}) {
        #
        push @work_rows,
          [ $html->button("$work->{ext_id}", "index=" . get_function_index("msgs_admin") . "&chg=$work->{ext_id}"),
            $work->{employee},
            $work->{work},
            $work->{sum},
            $work->{ratio}
          ];
      }
    }

    my $is_payed = $Employees->employees_info_payed_salary({ AID => $aid, MONTH => $month, YEAR => $year });

    $Employees->employees_salary_bonus_list({ AID => $aid, MONTH => $month, YEAR => $year, COLS_NAME => 1 });
    $extra_amount = $Employees->{TOTAL_BONUS_AMOUNT} || 0;

    my @additional_info_for_admin_rows = ();
    my $total_work_time_for_admin = 0;
    my $total_over_time_for_admin = 0;

    foreach my $each_admin_day (@all_admins_dates) {
      foreach my $admin_day (@$each_admin_day) {
        $total_over_time_for_admin += $admin_day->{overtime};
        $total_work_time_for_admin += $admin_day->{work_time};
        #        $extra_amount += $admin_day->{overtime} * $schedule_info->{bet_overtime};

        if ($schedule_info->{type} == 1) {
          $bet += $schedule_info->{bet} / $work_time_norms->[0]{hours} * $admin_day->{work_time} if ($work_time_norms->[0]{hours});
        }
        elsif ($schedule_info->{type} == 2) {
          $bet += $schedule_info->{bet_per_hour} * $admin_day->{work_time};
        }
      }
    }

    push @additional_info_for_admin_rows, [ $lang{POSITION}, $admins{$key}{position} ];
    push @additional_info_for_admin_rows, [ $lang{WORK_TIME}, $total_work_time_for_admin ];
    push @additional_info_for_admin_rows, [ $lang{OVERTIME}, $total_over_time_for_admin ];

    my $additional_info_for_admin = $html->table({
      width   => '100%',
      caption => "",
      title   => [ '', '' ],
      ID      => 'EMPLOYEES_SALARY_ADDITIONAL_INFO',
      rows    => [ @additional_info_for_admin_rows ]
    });

    if (defined $is_payed) {
      $salary_table->{rowcolor} = 'success';
    }
    else {
      $salary_table->{rowcolor} = 'danger';
    }

    my $already_payed_sum = 0.00;

    foreach my $each_pay (@$is_payed) {
      $already_payed_sum += $each_pay->{bet};
    }

    my $total = $bet + $extra_amount + $sum_for_works;
    my $sum_to_pay = sprintf('%.2f', $total) - sprintf('%.2f', $already_payed_sum);

    if(defined $sum_to_pay){
      $sum_all{$aid} = $sum_to_pay;
    }

    my @rows;
    my $input_name = "SALARY_$aid";
    my %salary_settings = ();
    my $checked_all_salary = $html->form_input("$input_name", "1",
      { TYPE => 'checkbox', STATE => ($salary_settings{$input_name}) ? 'checked' : '' });

    $salary_table->addrow(
      $plus_button . '<div style="display:none;">' . $additional_info_for_admin->show() . '</div>',
      $fio,
      $SCHEDULE_TYPES[ $schedule_info->{type} ],
      sprintf('%.2f', $schedule_info->{type} == 1 ? $schedule_info->{bet} : $schedule_info->{bet_per_hour}),
      sprintf('%.2f', $extra_amount),
      $html->button("$sum_for_works", "index=$index&MONTH=" . ($month - 1) . "&YEAR=$year&show_works=1&aid=$aid"),
      sprintf('%.2f', $total),

      $html->button(sprintf('%.2f', $already_payed_sum),, "index=$index&MONTH=" . ($month - 1) . "&YEAR=$year&show_payed_salary=1&aid=$aid"),
      (scalar @{$is_payed} > 0 ? $is_payed->[-1]{date} : ''),
      sprintf('%.2f', ($sum_to_pay || 0)),
      $html->button("$lang{PAY}",
        "qindex=" . get_function_index('employees_pay_salary') . "&aid=$aid&bet=" . sprintf('%.2f', $bet) . "&extra_amount=$extra_amount&sum_to_pay=$sum_to_pay&sum_for_works=$sum_for_works&pay_salary=1&month=$month&year=$year&header=2",
        { ICON          => 'fa fa-money',
          target        => '_blank',
          LOAD_TO_MODAL => 1,
        }),
      $checked_all_salary
    );

    if ($permissions{7}{9}){
      $salary_table->addfooter($html->form_input('all_salary', $lang{ALL_SALARY}, { TYPE => 'submit' }));
    }

    $html->form_main(
      {
        CONTENT =>$salary_table->show({ OUTPUT2RETURN => 1 }),
        HIDDEN  => {
          ALL_SALARY => 1,
          AID        => $aid,
          index      => get_function_index('employees_salary'),
        },
        NAME    => 'all_salary',
        class   => 'hidden-print',
        ID      => 'all_salary',
      }
    );

  }

  my $salary_table_template = $html->form_main(
    {
      CONTENT =>$salary_table->show({ OUTPUT2RETURN => 1 }),
      HIDDEN  => {
        ALL_SALARY => 1,
        # UID        => $aid,
        index      => get_function_index('employees_salary'),
      },
      NAME    => 'all_salary',
      class   => 'hidden-print',
      ID      => 'all_salary',
    }
  );
  $html->tpl_show(
    _include('employees_date_choose', 'Employees'),
    {
      MONTH     => $month_select,
      YEAR      => $year_select,
      POSITIONS => $position_select,
      TABLE     => $salary_table_template,
    }
  );

  if ($FORM{show_works}) {
    my $works_table = $html->table(
      {
        width   => '100%',
        caption => "$lang{WORK}",
        title   => [ "#", $lang{FIO}, $lang{WORK}, $lang{SUM}, $lang{RATIO} ],
        rows    => \@work_rows,
        ID      => 'EMPLOYEES_WORKS_FOR_AID'
      }
    );

    print $works_table->show();
  }

  return 1;
}

#**********************************************************

=head2 employees_admins_bet() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut

#**********************************************************
sub employees_admins_bet {

  if (!$permissions{7}{8}) {
    $html->message('warn', $lang{WARNING}, $lang{ERR_ACCESS_DENY});
    return 1;
  }

  my $action = 'chg';
  my $action_lang = "$lang{CHANGE}";
  my @SCHEDULE_TYPES = ("", "$lang{MONTHLY}", "$lang{HOURLY}", "$lang{OTHER}");

  my $admins_list = $Admins->list({ FIO => '_SHOW', POSITION => '_SHOW', COLS_NAME => 1, SHOW_EMPLOYEES => 1, DISABLE => '0' });

  if ($FORM{chg}) {
    my $aid_schedule = $Employees->employees_info_bet({ COLS_NAME => 1, AID => $FORM{AID} });

    if ($aid_schedule) {
      $Employees->employees_del_bet({ AID => $aid_schedule->{AID} });
      $Employees->employees_add_bet({ %FORM });
    }
    else {
      $Employees->employees_add_bet({ %FORM });
    }
  }

  my $admins_table = $html->table(
    {
      width      => '100%',
      caption    => "$lang{BET}",
      title      => [ "AID", $lang{FIO}, $lang{POSITION}, $lang{TYPE}, $lang{BET}, $lang{BET_PER_HOUR}, $lang{BET_OVERTIME}, '' ],
      ID         => 'ADMIN_BET_ID',
      DATA_TABLE => 1
    }
  );

  foreach my $admin_info (@$admins_list) {
    #    my $position_info = $Employees->position_info({ ID => $admin_info->{position}, COLS_NAME => 1 });
    my $aid_schedule = $Employees->employees_info_bet({ COLS_NAME => 1, AID => $admin_info->{aid} });

    $admins_table->addrow(
      $admin_info->{aid},
      $admin_info->{name},
      _translate($admin_info->{position}) || '',
      $aid_schedule->{type} ? $SCHEDULE_TYPES[ $aid_schedule->{type} ] : '-',
      $aid_schedule->{bet} ? $aid_schedule->{bet} : '-',
      $aid_schedule->{bet_per_hour} ? $aid_schedule->{bet_per_hour} : '-',
      $aid_schedule->{bet_overtime} ? $aid_schedule->{bet_overtime} : '-',
      $html->button('', "index=$index&AID_SCHEDULE=$admin_info->{aid}&FIO=$admin_info->{name}",
        { ICON => 'fa fa-pencil-alt', })
    );
  }

  if ($FORM{AID_SCHEDULE}) {
    $html->message('info', $lang{CHANGE},);
    my $aid_schedule = $Employees->employees_info_bet({ COLS_NAME => 1, AID => $FORM{AID_SCHEDULE} });

    if ($aid_schedule) {
      $html->tpl_show(
        _include('employees_work_schedule', 'Employees'),
        {
          ACTION     => $action,
          ACTION_LNG => $action_lang,
          FIO        => $FORM{FIO} || '',
          %$aid_schedule
        }
      );
    }
    else {
      $html->tpl_show(
        _include('employees_work_schedule', 'Employees'),
        {
          ACTION     => $action,
          ACTION_LNG => $action_lang,

        }
      );
    }
  }

  print $admins_table->show();

  return 1;
}

#**********************************************************

=head2 employees_pay_salary() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut

#**********************************************************
sub employees_pay_salary {
  my ($attr) = @_;

  my $admin_info = $Admins->info($FORM{aid}, { COLS_NAME => 1 });

  my ($year, $month, undef) = split('-', $DATE);

  $month = ($FORM{MONTH} + 1) if (defined $FORM{MONTH} && $FORM{MONTH} =~ /^\d+$/);
  $year = ($FORM{YEAR}) if ($FORM{YEAR});

  my $month_select = $html->form_select(
    'MONTH',
    {
      SELECTED     => $FORM{MONTH} || $month - 1,
      SEL_ARRAY    => \@MONTHES,
      ARRAY_NUM_ID => 1,
    }
  );

  my ($current_year, undef, undef) = split('-', $DATE);
  my @YEARS = reverse sort ($current_year - 4 ... $current_year);

  my $year_select = $html->form_select(
    'YEAR',
    {
      SELECTED  => $FORM{year},
      SEL_ARRAY => \@YEARS,
    }
  );

  my $cashbox_select = employees_cashbox_select();

  my $spend_types_select = $html->form_select(
    'SPENDING_TYPE_ID',
    {
      SELECTED    => $FORM{SPENDING_TYPE_ID} || $attr->{ID},
      SEL_LIST    => $Employees->employees_list_spending_type({ COLS_NAME => 1 }),
      SEL_KEY     => 'id',
      SEL_VALUE   => 'name',
      NO_ID       => 1,
      SEL_OPTIONS => { "" => "" },
      MAIN_MENU   => get_function_index('employees_cashbox_spending_type'),
    }
  );

  $html->message('info', $lang{CHECK_DATA_AND_CHOOSE_CASHBOX});

  my $sum_to_pay = $FORM{sum_to_pay} || 0;

  $html->tpl_show(
    _include('employees_salary_confirm', 'Employees'),
    {
      FIO              => $admin_info->{A_FIO} || q{},
      BET              => $FORM{bet},
      EXTRA_AMOUNT     => $FORM{extra_amount},
      SUM              => sprintf('%.2f', $sum_to_pay), #sprintf('%.2f', $bet + $extra_amount + $sum_for_works),
      TEXT_MONTH       => $MONTHES[ $month - 1 ],
      MONTH            => $month_select,
      YEAR             => $year_select,
      CASHBOX          => $cashbox_select,
      SPENDING_TYPE_ID => $spend_types_select,
      AID              => $FORM{aid},
      INDEX            => get_function_index("employees_salary")
    }
  );

  return 1;
}


#**********************************************************
=head2 employees_working_time_norms()

=cut
#**********************************************************
sub employees_working_time_norms {

  if (!$permissions{7}{8}) {
    $html->message('warn', $lang{WARNING}, $lang{ERR_ACCESS_DENY});
    return 1;
  }

  my ($year, undef, undef) = split('-', ($FORM{DATE} || $DATE));
  my $prev_year = $year - 1 . "-01-01";
  my $next_year = $year + 1 . "-01-01";

  my $month_number = 1;
  if ($FORM{add_norms}) {
    my @each_month_time_norms = ();
    for my $month_name (@MONTHES) {
      push @each_month_time_norms, {
        MONTH => $month_number,
        HOURS => $FORM{"HOURS_" . $month_number} || 0,
        DAYS  => $FORM{"DAYS_" . $month_number} || 0,
      };
      $month_number++;
    }

    $Employees->employees_time_norms_add({
      WORKING_NORMS => \@each_month_time_norms,
      YEAR          => $year,
    });

    _error_show($Employees);
  }

  my $working_time_norms = $Employees->employees_time_norms_list({
    YEAR      => $year,
    MONTH     => '_SHOW',
    HOURS     => '_SHOW',
    DAYS      => '_SHOW',
    COLS_NAME => 1,
  });

  my %TIME_NORMS_PER_MONTH = ();
  foreach my $working_time_norms_per_month (@$working_time_norms) {
    $TIME_NORMS_PER_MONTH{$working_time_norms_per_month->{month}}{HOURS} = $working_time_norms_per_month->{hours} || 0;
    $TIME_NORMS_PER_MONTH{$working_time_norms_per_month->{month}}{DAYS} = $working_time_norms_per_month->{days} || 0;
  }

  my @month_title = ('');
  my @hours_rows = ($lang{HOURS},);
  my @days_rows = ($lang{DAYS},);
  $month_number = 1;

  for my $month_name (@MONTHES) {
    push @month_title, $month_name;
    push @hours_rows, $html->form_input('HOURS_' . $month_number, $TIME_NORMS_PER_MONTH{$month_number}{HOURS}, {});
    push @days_rows, $html->form_input('DAYS_' . $month_number, $TIME_NORMS_PER_MONTH{$month_number}{DAYS}, {});
    $month_number++;
  }
  my $normies_input_table = $html->table({
    width       => '100%',
    caption     => $lang{WORKING_TIME_NORMS},
    title_plain => \@month_title,
    ID          => 'WORKING_TIME_NORMS',
    rows        => [ \@hours_rows, \@days_rows ],
    header      => $html->button('', "index=$index&DATE=$prev_year",
      { class => 'btn btn-xs btn-secondary fa fa-arrow-left' })
      . $html->button("$year", "index=$index", { class => 'btn btn-xs btn-primary' })
      . $html->button('', "index=$index&DATE=$next_year",
      { class => 'btn btn-xs btn-secondary fa fa-arrow-right' }),
  });

  $html->tpl_show(_include('employees_working_time_norms', 'Employees'), {
    TABLE => $normies_input_table->show(),
    DATE  => $FORM{DATE} || $DATE,
  });
}

#**********************************************************
=head2 employees_print_payment_statement()

=cut
#**********************************************************
sub employees_print_payment_statement {
  $html->tpl_show(_include('employees_print_payment_statement', 'Employees'), {
  });
  return 1;
}

#**********************************************************
=head2 employees_bonus_types()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub employees_bonus_types {

  if (!$permissions{7}{8}) {
    $html->message('warn', $lang{WARNING}, $lang{ERR_ACCESS_DENY});
    return 1;
  }

  my %TEMPLATE_ARGS = (
    ACTION      => "add",
    ACTION_LANG => $lang{ADD}
  );

  if ($FORM{add}) {
    $Employees->employees_bonus_type_add({ %FORM });

    if (!$Employees->{errno}) {
      $html->message('info', $lang{SUCCESS}, $lang{ADDED});
    }
    else {
      $html->message('err', $lang{ERROR}, $Employees->{errstr});
    }
  }
  elsif ($FORM{chg}) {
    my $bonus_type_info = $Employees->employees_bonus_type_info({
      ID         => $FORM{chg},
      NAME       => '_SHOW',
      AMOUNT     => '_SHOW',
      COMMENTS   => '_SHOW',
      COLS_NAME  => '_SHOW',
      COLS_UPPER => 1,
    });

    if ($Employees->{errno}) {
      $html->message('err', $lang{ERROR}, $Employees->{errstr});
      return 1;
    }

    %TEMPLATE_ARGS = %{$bonus_type_info};
    $TEMPLATE_ARGS{ACTION} = 'change';
    $TEMPLATE_ARGS{ACTION_LANG} = "$lang{CHANGE}";
  }
  elsif ($FORM{change}) {
    $Employees->employees_bonus_type_change({ %FORM });
    if (!$Employees->{errno}) {
      $html->message('info', $lang{SUCCESS}, $lang{CHANGED});
    }
    else {
      $html->message('err', $lang{ERROR}, $Employees->{errstr});
    }
  }
  elsif ($FORM{del}) {
    $Employees->employees_bonus_type_del({ ID => $FORM{del}, %FORM });
    if (!$Employees->{errno}) {
      $html->message('info', $lang{SUCCESS}, $lang{DELETED});
    }
    else {
      $html->message('err', $lang{ERROR}, $Employees->{errstr});
    }
  }

  $html->tpl_show(
    _include('employees_bonus_type_add', 'Employees'),
    { %TEMPLATE_ARGS }
  );

  result_former(
    {
      INPUT_DATA      => $Employees,
      FUNCTION        => 'employees_bonus_types_list',
      BASE_FIELDS     => 0,
      DEFAULT_FIELDS  => "ID, NAME, AMOUNT, COMMENTS",
      FUNCTION_FIELDS => 'change, del',
      FILTER_COLS     => {
      },
      EXT_TITLES      => {
        'id'       => "#",
        'name'     => $lang{NAME},
        'amount'   => $lang{SUM},
        'comments' => $lang{COMMENTS},
      },
      SKIP_PAGES      => 1,
      TABLE           => {
        width       => '100%',
        caption     => "$lang{TYPE} $lang{BONUS}",
        qs          => $pages_qs,
        ID          => 'EMPLOYEES_BONUS_TYPES',
        DATA_TABLE  => 1,
        title_plain => 1,
      },
      MAKE_ROWS       => 1,
      SEARCH_FORMER   => 1,
      MODULE          => 'Employees',
      TOTAL           => 1,
      SKIP_TOTAL_FORM => 1
    }
  );

  return 1;
}

#**********************************************************
=head2 employees_salary_bonus()

  Arguments:
     -
    
  Returns:
  
=cut
#**********************************************************
sub employees_salary_bonus {
  my ($current_year, $current_month, $current_day) = split("-", $DATE);

  my $bonus_types_select = $html->form_select(
    'BONUS_TYPE_ID',
    {
      SELECTED    => $FORM{BONUS_TYPE_ID} || '',
      SEL_LIST    => $Employees->employees_bonus_types_list({ COLS_NAME => 1, NAME => '_SHOW' }),
      SEL_KEY     => 'id',
      SEL_VALUE   => 'name',
      NO_ID       => 1,
      SEL_OPTIONS => { "" => "" },
      #      MAIN_MENU   => get_function_index('employees_bonus_types'),
    }
  );

  my @YEARS = ($current_year - 1, $current_year, $current_year + 1);

  my $year_select = $html->form_select(
    'YEAR',
    {
      SELECTED  => $FORM{YEAR} || $current_year,
      SEL_ARRAY => \@YEARS,
    }
  );

  my $month_select = $html->form_select(
    'MONTH',
    {
      SELECTED     => $FORM{MONTH} || $current_month - 1,
      SEL_ARRAY    => \@MONTHES,
      ARRAY_NUM_ID => 1,
    }
  );

  my $admin_select = sel_admins();

  if ($FORM{add}) {
    my $amount = 0;
    if ($FORM{BONUS_TYPE_ID}) {
      my $bonus_type_info = $Employees->employees_bonus_type_info({
        ID        => $FORM{BONUS_TYPE_ID},
        AMOUNT    => '_SHOW',
        COLS_NAME => 1,
      });
      $amount = $bonus_type_info->{amount};
    }

    $Employees->employees_salary_bonus_add({
      %FORM,
      AMOUNT => $amount,
      MONTH  => $FORM{MONTH} ? $FORM{MONTH} + 1 : 1,
    });

    if (!$Employees->{errno}) {
      $html->message('info', $lang{SUCCESS}, $lang{ADDED});
    }
    else {
      $html->message('err', $lang{ERROR}, $Employees->{errstr});
    }
  }
  elsif ($FORM{del}) {
    $Employees->employees_salary_bonus_del({ ID => $FORM{del} });

    if (!$Employees->{errno}) {
      $html->message('info', $lang{SUCCESS}, $lang{DELETED});
    }
    else {
      $html->message('err', $lang{ERROR}, $Employees->{errstr});
    }
  }

  if ($FORM{add_form}) {
    my %TEMPLATE_ARGS = (
      ACTION      => 'add',
      ACTION_LANG => $lang{ADD},
    );

    $html->tpl_show(
      _include('employees_bonus_give', 'Employees'),
      {
        %TEMPLATE_ARGS,
        BONUS_SELECT => $bonus_types_select,
        YEAR_SELECT  => $year_select,
        MONTH_SELECT => $month_select,
        ADMIN_SELECT => $admin_select,
      }
    );
  }

  result_former(
    {
      INPUT_DATA      => $Employees,
      FUNCTION        => 'employees_salary_bonus_list',
      BASE_FIELDS     => 0,
      DEFAULT_FIELDS  => "ID, AMOUNT, ADMIN_NAME, BONUS_NAME, YEAR",
      HIDDEN_FIELDS   => 'MONTH',
      FUNCTION_FIELDS => 'del',
      FILTER_COLS     => {
        year => '_employees_readable_date::MONTH,YEAR',
      },
      EXT_TITLES      => {
        'id'         => "#",
        'amount'     => $lang{SUM},
        'admin_name' => $lang{EMPLOYEE},
        'bonus_name' => "$lang{NAME} $lang{BONUS}",
        'year'       => $lang{MONTH},
      },
      SKIP_PAGES      => 1,
      TABLE           => {
        width       => '100%',
        caption     => "$lang{BONUS}",
        qs          => $pages_qs,
        ID          => 'EMPLOYEES_BONUS_LIST',
        MENU        => "$lang{ADD}:index=$index&add_form=1:add",
        DATA_TABLE  => { "order" => [ [ 0, "desc" ] ] },
        DT_CLICK    => 1,
        title_plain => 1,
      },
      MAKE_ROWS       => 1,
      SEARCH_FORMER   => 1,
      MODULE          => 'Employees',
      TOTAL           => 1,
      SKIP_TOTAL_FORM => 1
    }
  );

  return 1;
}

#**********************************************************
=head2 _employees_readable_date()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub _employees_readable_date {
  my (undef, $attr) = @_;
  my $month = $MONTHES[$attr->{VALUES}{MONTH} - 1] || '---';
  my $year = $attr->{VALUES}{YEAR} || 0;

  return "$month $year";
}


#**********************************************************
=head2 _fee_taken_msg()

    filter for result former

=cut
#**********************************************************
sub _fee_taken_msg {
  my ($value) = @_;
  my $result = $html->color_mark($lang{NO}, "text-danger");

  if ($value && $value > 0) {
    $result = $html->color_mark($lang{YES}, "text-success");;
  }
  return $result;
}

#**********************************************************

=head2 employees_cashbox_moving_type() -

  Arguments:

  Returns:

=cut

#**********************************************************
sub employees_cashbox_moving_type {

  my $action = 'add';
  my $action_lang = "$lang{ADD}";
  my %CASHBOX;

  if ($FORM{add}) {
    $Employees->employees_add_type({ %FORM, MOVING => 1 });

    if (!$Employees->{errno}) {
      $html->message("success", "$lang{SUCCESS}", "$lang{TYPE} $lang{ADDED}");
    }
    else {
      $html->message("err", "$lang{ERROR}", "$lang{TYPE} $lang{NOT} $lang{ADDED}");
    }
  }
  elsif ($FORM{change}) {
    $Employees->employees_change_type({ MOVING => 1, %FORM });

    if (!$Employees->{errno}) {
      $html->message("success", "$lang{SUCCESS}", "$lang{CHANGED}");
    }
    else {
      $html->message("err", "$lang{ERROR}", "$lang{NOT_CHANGED}");
    }
  }

  if ($FORM{del}) {
    $Employees->employees_delete_type({ MOVING => 1, ID => $FORM{del} });

    if (!$Employees->{errno}) {
      $html->message("success", "$lang{SUCCESS}", "$lang{TYPE} $lang{DELETED}");
    }
    else {
      $html->message("err", "$lang{ERROR}", "$lang{NOT} $lang{DELETED}");
    }
  }

  if ($FORM{chg}) {
    $action = 'change';
    $action_lang = $lang{CHANGE};

    $html->message("info", $lang{CHANGE});

    my $moving_type = $Employees->employees_info_type({ MOVING => 1, ID => $FORM{chg} });
    $CASHBOX{ID} = $FORM{chg};
    $CASHBOX{NAME} = $moving_type->{NAME};
    $CASHBOX{COMMENTS} = $moving_type->{COMMENTS};
    $CASHBOX{SPENDING_TYPE} = $moving_type->{SPENDING_TYPE};
    $CASHBOX{MOVING_TYPE} = $moving_type->{MOVING_TYPE};
  }

  $CASHBOX{SPENDING_TYPE_SELECT} = $html->form_select(
    'SPENDING_TYPE',
    {
      SELECTED    => $FORM{SPENDING_TYPE} || $CASHBOX{SPENDING_TYPE},
      SEL_LIST    => $Employees->employees_list_spending_type({ COLS_NAME => 1 }),
      SEL_KEY     => 'id',
      SEL_VALUE   => 'name',
      NO_ID       => 1,
      SEL_OPTIONS => { "" => "" },
    }
  );

  $CASHBOX{COMING_TYPE_SELECT} = $html->form_select(
    'COMING_TYPE',
    {
      SELECTED    => $FORM{COMING_TYPE} || $CASHBOX{COMING_TYPE},
      SEL_LIST    => $Employees->employees_list_coming_type({ COLS_NAME => 1 }),
      SEL_KEY     => 'id',
      SEL_VALUE   => 'name',
      NO_ID       => 1,
      SEL_OPTIONS => { "" => "" },
    }
  );

  $html->tpl_show(
    _include('employees_moving_type', 'Employees'),
    {
      %CASHBOX,
      ACTION      => $action,
      ACTION_LANG => $action_lang,
    }
  );

  result_former(
    {
      INPUT_DATA      => $Employees,
      FUNCTION        => 'employees_list_moving_type',
      BASE_FIELDS     => 3,
      DEFAULT_FIELDS  => "id, name, comments, spending_name, coming_name",
      FUNCTION_FIELDS => "change, del",
      EXT_TITLES      => {
        'name'          => "$lang{NAME}",
        'id'            => "#",
        'comments'      => "$lang{COMMENTS}",
        'spending_name' => "$lang{TYPE} $lang{SPENDING}",
        'coming_name'   => "$lang{TYPE} $lang{COMING}",
      },
      TABLE           => {
        width   => '100%',
        caption => "$lang{MOVING} $lang{TYPE}",
        qs      => $pages_qs,
        ID      => 'EMPLOYEES',
        header  => '',
        EXPORT  => 1,
      },
      MAKE_ROWS       => 1,
      SEARCH_FORMER   => 1,
      MODULE          => 'Employees',
      TOTAL           => 1
    }
  );

  return 1;
}

#**********************************************************

=head2 employees_moving_between_cashboxes() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut

#**********************************************************
sub employees_moving_between_cashboxes {

  my $action = 'moving';
  my $action_lang = "$lang{MOVING}";
  my %CASHBOX;
  my $coming_id;
  my $spending_id;

  my $moving_info = $Employees->employees_info_moving({ COLS_NAME => 1, ID => $FORM{chg} });

  if ($FORM{moving}) {

    my $list = $Employees->employees_list_moving_type({ COLS_NAME => 1});
    foreach my $line (@$list) {
      my $spend_id = $line->{spending_id};
      my $com_id = $line->{coming_id};

      my $coming = $Employees->employees_add_coming({%FORM, CASHBOX_ID => $FORM{CASHBOX_COMING}, AID => $admin->{AID}, COMING_TYPE_ID => $com_id });
      $coming_id = $coming->{INSERT_ID};

      my $spending = $Employees->employees_add_spending({ %FORM, CASHBOX_ID => $FORM{CASHBOX_SPENDING}, AID => $admin->{AID}, SPENDING_TYPE_ID => $spend_id });
      $spending_id = $spending->{INSERT_ID};
    }

    $Employees->employees_add_moving({ %FORM, AID => $admin->{AID}, ID_SPENDING => $spending_id, ID_COMING => $coming_id, });

    if (!$Employees->{errno}) {
      $html->message("success", "$lang{SUCCESS}", "$lang{ADDED}");
    }
    else {
      $html->message("err", "$lang{ERROR}", "$lang{NOT_ADDED}");
    }
  }
  elsif ($FORM{change}) {
    my $moving_chg = $Employees->employees_info_moving({ COLS_NAME => 1, ID => $FORM{ID} });

    $Employees->employees_change_coming({ %FORM, AID => $admin->{AID}, ID => $moving_chg->{ID_COMING}, CASHBOX_ID => $FORM{CASHBOX_COMING} });

    $Employees->employees_change_spending({ %FORM, AID => $admin->{AID}, ID => $moving_chg->{ID_SPENDING}, CASHBOX_ID => $FORM{CASHBOX_SPENDING} });

    $Employees->employees_change_moving ({ %FORM, AID => $admin->{AID} });

    if (!$Employees->{errno}) {
      $html->message("success", "$lang{SUCCESS}", "$lang{CHANGED}");
    }
    else {
      $html->message("err", "$lang{ERROR}", "$lang{NOT_CHANGED}");
    }
  }

  if ($FORM{del}) {
    my $moving = $Employees->employees_info_moving({ COLS_NAME => 1, ID => $FORM{del} });

    $Employees->employees_delete_moving({ ID => $FORM{del} });

    $Employees->employees_delete_coming({ ID => $moving->{ID_COMING} });

    $Employees->employees_delete_spending({ ID => $moving->{ID_SPENDING} });

    if (!$Employees->{errno}) {
      $html->message("success", "$lang{SUCCESS}", "$lang{DELETED}");
    }
    else {
      $html->message("err", "$lang{ERROR}", "$lang{NOT_DELETED}");
    }
  }

  my $spending_cashbox = 0;
  my $coming_cashbox = 0;
  my $moving_type = 0;
  if ($FORM{chg}) {
    $html->message("info", $lang{CHANGE});

    $spending_cashbox = $moving_info->{CASHBOX_SPENDING};
    $coming_cashbox = $moving_info->{CASHBOX_COMING};
    $moving_type = $moving_info->{MOVING_TYPE_ID};
    $action = 'change';
    $action_lang = "$lang{CHANGE}";
    $CASHBOX{DATE} = $moving_info->{DATE};
    $CASHBOX{COMMENTS} = $moving_info->{COMMENTS};
    $CASHBOX{AMOUNT} = $moving_info->{AMOUNT};
    $CASHBOX{ID} = $FORM{chg};
  }

  $CASHBOX{MOVING_TYPE_SELECT} = $html->form_select(
    'MOVING_TYPE_ID',
    {
      SELECTED    => $FORM{MOVING_TYPE_ID} || $CASHBOX{MOVING_TYPE_ID} || $moving_type,
      SEL_LIST    => $Employees->employees_list_moving_type({ COLS_NAME => 1}),
      SEL_KEY     => 'id',
      SEL_VALUE   => 'name',
      NO_ID       => 1,
      SEL_OPTIONS => { "" => "" },
    }
  );

  $CASHBOX{CASHBOX_SELECT_COMING} = employees_cashbox_select({ NAME => 'CASHBOX_COMING', ID => $coming_cashbox});
  $CASHBOX{CASHBOX_SELECT_SPENDING} = employees_cashbox_select({ NAME => 'CASHBOX_SPENDING', ID => $spending_cashbox });

  $html->tpl_show(
    _include('employees_moving_between_cashboxes', 'Employees'),
    {
      %CASHBOX,
      ACTION      => $action,
      ACTION_LANG => $action_lang,
      DATE        => $DATE
    }
  );

  result_former(
    {
      INPUT_DATA      => $Employees,
      FUNCTION        => 'employees_list_moving',
      BASE_FIELDS     => 1,
      DEFAULT_FIELDS  => "id, amount, name_spending, name_coming, moving_type_name, date, comments, admin",
      FUNCTION_FIELDS => 'employees_coming_document:$lang{DOCS}:id,change, del',
      EXT_TITLES      => {
        'amount'           => "$lang{SUM}",
        'name_spending'    => "$lang{CASHBOX} $lang{SPENDING}",
        'name_coming'      => "$lang{CASHBOX} $lang{COMING}",
        'moving_type_name' => "$lang{MOVING} $lang{TYPE}",
        'date'             => "$lang{DATE}",
        'admin'            => "$lang{ADMIN}",
        'comments'         => "$lang{COMMENTS}",
        'id'               => "#",
      },
      FUNCTION_INDEX  => $index,
      TABLE           => {
        width   => '100%',
        caption => "$lang{MOVING_BETWEEN_CASHBOXES}",
        qs      => $pages_qs,
        ID      => 'EMPLOYEES',
        header  => '',
        EXPORT  => 1,
      },
      MAKE_ROWS       => 1,
      SEARCH_FORMER   => 1,
      MODULE          => 'Employees',
      TOTAL           => 1
    }
  );

  return 1;
}

#**********************************************************

=head2 employees_pay_salary_all() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut

#**********************************************************
sub employees_pay_salary_all {
  my ($attr) = @_;
  my ($FORM) = @_;

 #my %info;
  my $admin_info = '';
  my $all_admins = '';
  my ($year, $month, undef) = split('-', $DATE);

  $month = ($FORM{MONTH} + 1) if (defined $FORM{MONTH} && $FORM{MONTH} =~ /^\d+$/);
  $year = ($FORM{YEAR}) if ($FORM{YEAR});

  my $month_select = $html->form_select(
    'MONTH',
    {
      SELECTED     => $FORM{MONTH} || $month - 1,
      SEL_ARRAY    => \@MONTHES,
      ARRAY_NUM_ID => 1,
    }
  );

  my ($current_year, undef, undef) = split('-', $DATE);
  my @YEARS = reverse sort ($current_year - 4 ... $current_year);

  my $year_select = $html->form_select(
    'YEAR',
    {
      SELECTED  => $FORM{year},
      SEL_ARRAY => \@YEARS,
    }
  );
  
  foreach my $key (keys %FORM) {
    if($key =~ /SALARY_(\d+)/){
      $FORM{aid_salary} = $1;
      $admin_info = $Admins->info($FORM{aid_salary}, { COLS_NAME => 1 });
      $FORM{FIO} = $admin_info->{A_FIO};
      $all_admins .= $html->tpl_show(
        _include('employees_salary_fio', 'Employees'),
        {
          FIO => $FORM{FIO},
        },
        {
          OUTPUT2RETURN => 1
        },
      );
    }
  }

  my $cashbox_select = employees_cashbox_select();

  my $spend_types_select = $html->form_select(
    'SPENDING_TYPE_ID',
    {
      SELECTED    => $FORM{SPENDING_TYPE_ID} || $attr->{ID},
      SEL_LIST    => $Employees->employees_list_spending_type({ COLS_NAME => 1 }),
      SEL_KEY     => 'id',
      SEL_VALUE   => 'name',
      NO_ID       => 1,
      SEL_OPTIONS => { "" => "" },
      MAIN_MENU   => get_function_index('employees_cashbox_spending_type'),
    }
  );

  $html->message('info', $lang{CHECK_DATA_AND_CHOOSE_CASHBOX});

  my $sum_to_pay = $FORM{sum_to_pay} || 0;

  $html->tpl_show(
    _include('employees_salary_confirm_all', 'Employees'),
    {
     # FIO              => $FORM{FIO},
     # BET              => $FORM{bet},
      EXTRA_AMOUNT     => $FORM{extra_amount},
      FIO_1            => $all_admins,
    #  SUM              => sprintf('%.2f', $sum_to_pay), #sprintf('%.2f', $bet + $extra_amount + $sum_for_works),
      TEXT_MONTH       => $MONTHES[ $month - 1 ],
      MONTH            => $month_select,
      YEAR             => $year_select,
      CASHBOX          => $cashbox_select,
      SPENDING_TYPE_ID => $spend_types_select,
     # AID              => $FORM{aid_salary},$FORM{aid_salary},$FORM{aid_salary},
      INDEX            => get_function_index("employees_salary")
    }
  );

  return 1;
}


1;
