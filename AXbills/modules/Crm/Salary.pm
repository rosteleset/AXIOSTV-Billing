use strict;
use warnings FATAL => 'all';

our (
  @PRIORITY,
  @MONTHES,
  $html,
  %lang,
  $admin,
  $db,
);

our Crm $Crm;
our Admins $Admins;
our Employees $Employees;

use AXbills::Base qw/in_array mk_unique_value/;


#**********************************************************
=head2 cashbox_salary() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub crm_salary {
#  $Employees = Employees->new($db, $admin, \%conf);

  if ($FORM{confirm}) {
    $Crm->add_spending(
      {
        AMOUNT           => $FORM{SUM},
        CASHBOX_ID       => $FORM{CASHBOX_ID},
        SPENDING_TYPE_ID => $FORM{SPENDING_TYPE_ID},
        DATE             => $DATE,
        ADMIN_SPENDING   => $FORM{AID},
        AID              => $admin->{AID},
      }
    );

    if (!$Crm->{errno}) {
      $Crm->add_payed_salary(
        {
          AID   => $FORM{AID},
          BET   => $FORM{SUM},
          YEAR  => $FORM{YEAR},
          MONTH => $FORM{MONTH},
          SPENDING_ID => $Crm->{INSERT_ID},
        }
      );
      my $payment_statement_button = $html->button("$lang{PRINT}",
        "qindex=" . get_function_index("crm_print_payment_statement"). "&header=2&AID=$FORM{AID}&PRINT_STATEMENT=1", {
          ICON   => 'glyphicon glyphicon-print',
          target => '_blank',
        });
      $html->message("success", "$lang{ADDED}", "Платежная ведомость: $payment_statement_button");
    }
    else {
      $html->message("err", "$lang{ERROR}", "$lang{EXIST}");
    }
    delete $FORM{MONTH};
  }

  my ($year, $month, undef) = split('-', $DATE);
  $month = ($FORM{MONTH} + 1) if (defined $FORM{MONTH} && $FORM{MONTH} =~ /^\d+$/);
  $year = ($FORM{YEAR}) if (defined $FORM{YEAR});

  my $month_start = "$year-$month-1";
  my $month_end = "$year-$month-" . days_in_month();

  if ($FORM{pay_salary}) {
    $Crm->add_payed_salary(
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

  my @YEARS = ('', '2016', '2017', '2018', '2019', '2020', '2021',);
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

  foreach my $key (keys %{$positions_hash}){
    $positions_hash->{$key} = _translate($positions_hash->{$key});
  }

  my $position_select = $html->form_select('POSITION',
    {
      SEL_HASH => $positions_hash,
      SELECTED => $FORM{POSITION},
      NO_ID    => 1,
      SEL_OPTIONS  => {"" => ""},
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
      _include('date_choose', 'Crm'),
      {
        MONTH => $month_select,
        YEAR  => $year_select,
        POSITIONS => $position_select,
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
    push(@{ $admins{$fio}{dates} }, $dates);
  }

  my $salary_table = $html->table(
    {
      width   => '100%',
      caption => "$lang{SALARY}",
      title   => [ '',
        "$lang{FIO}",
        "$lang{TYPE}",
        "$lang{BET}",
        "$lang{BONUS}",
        "$lang{WORK}",
        "$lang{TOTAL}",
        "$lang{SUM} $lang{PAYED}",
        "$lang{LAST_ACTIVITY}",
        "$lang{SUM_TO_PAY}" ,
        ''],
      ID      => 'CRM_SALARY',
      DATA_TABLE => 1,
    }
  );

  my @work_rows = ();
  my $work_time_norms = $Crm->crm_time_norms_list({
    YEAR      => $year,
    MONTH     => $month,
    HOURS     => '_SHOW',
    DAYS      => '_SHOW',
    COLS_NAME => 1,
  });

  if(!$work_time_norms->[0]{hours}){
    $html->message('warn', $lang{WORKING_TIME_NORMS_EMPTY}, $lang{MONTHLY_BET_WILL_NOT_CALC});
  }

  my $plus_button = $html->element('i', "", {
      class => 'fa fa-fw fa-plus-circle tree-button',
      style => 'font-size:16px;color:green;',
    });

  foreach my $key ( sort keys %admins) {
    my $aid = $admins{$key}{aid};
    my $fio = $key;
    my @all_admins_dates = $admins{$key}{dates};
    my $extra_amount = 0;
    my $bet = 0;
    my $sum_for_works = 0;

    my $schedule_info = $Crm->info_bet({ AID => $aid, COLS_NAME => 1 });

    if (!(defined $schedule_info)) {
      next;
    }

    my $admins_works_from_msgs = $Crm->works_list({
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

    my $is_payed = $Crm->info_payed_salary({ AID => $aid, MONTH => $month, YEAR => $year });

    $Crm->crm_salary_bonus_list({ AID => $aid, MONTH => $month, YEAR => $year, COLS_NAME => 1 });
    $extra_amount = $Crm->{TOTAL_BONUS_AMOUNT} || 0;

    my @additional_info_for_admin_rows = ();
    my $total_work_time_for_admin = 0;
    my $total_over_time_for_admin = 0;

    foreach my $each_admin_day (@all_admins_dates) {
      foreach my $admin_day (@$each_admin_day) {
        $total_over_time_for_admin += $admin_day->{overtime};
        $total_work_time_for_admin += $admin_day->{work_time};
#        $extra_amount += $admin_day->{overtime} * $schedule_info->{bet_overtime};

        if ($schedule_info->{type} == 1 ) {
          $bet += $schedule_info->{bet} / $work_time_norms->[0]{hours} * $admin_day->{work_time} if ($work_time_norms->[0]{hours});
        }
        elsif ($schedule_info->{type} == 2) {
          $bet += $schedule_info->{bet_per_hour} * $admin_day->{work_time};
        }
      }
    }

    push @additional_info_for_admin_rows, [$lang{POSITION}, $admins{$key}{position}];
    push @additional_info_for_admin_rows, [$lang{WORK_TIME}, $total_work_time_for_admin];
    push @additional_info_for_admin_rows, [$lang{OVERTIME}, $total_over_time_for_admin];

    my $additional_info_for_admin = $html->table({
      width   => '100%',
      caption => "",
      title   => [ '', '' ],
      ID      => 'CRM_SALARY_ADDITIONAL_INFO',
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
        "qindex=" . get_function_index('crm_pay_salary') . "&aid=$aid&bet=" . sprintf('%.2f', $bet) . "&extra_amount=$extra_amount&sum_to_pay=$sum_to_pay&sum_for_works=$sum_for_works&pay_salary=1&month=$month&year=$year&header=2",
        { ICON => 'fa fa-money',
          target => '_blank',
          LOAD_TO_MODAL => 1,
        })
    );
  }

  my $salary_table_template = $salary_table->show();
  $html->tpl_show(
    _include('date_choose', 'Crm'),
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
        ID      => 'CRM_WORKS_FOR_AID'
      }
    );

    print $works_table->show();
  }

  return 1;
}

#**********************************************************

=head2 crm_admins_bet() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut

#**********************************************************
sub crm_admins_bet {
  my $action = 'chg';
  my $action_lang = "$lang{CHANGE}";
  my @SCHEDULE_TYPES = ("", "$lang{MONTHLY}", "$lang{HOURLY}", "$lang{OTHER}");

  my $admins_list = $Admins->list({ FIO => '_SHOW', POSITION => '_SHOW', COLS_NAME => 1 });

  if ($FORM{chg}) {
    my $aid_schedule = $Crm->info_bet({ COLS_NAME => 1, AID => $FORM{AID} });

    if ($aid_schedule) {
      $Crm->del_bet({ AID => $aid_schedule->{AID} });
      $Crm->add_bet({ %FORM });
    }
    else {
      $Crm->add_bet({ %FORM });
    }
  }

  my $admins_table = $html->table(
    {
      width   => '100%',
      caption => "$lang{BET}",
      title   =>
      [ "AID", $lang{FIO}, $lang{POSITION}, $lang{TYPE}, $lang{BET}, $lang{BET_PER_HOUR}, $lang{BET_OVERTIME} ]
    }
  );

  foreach my $admin_info (@$admins_list) {
    my $position_info = $Employees->position_info({ ID => $admin_info->{position}, COLS_NAME => 1 });
    my $aid_schedule = $Crm->info_bet({ COLS_NAME => 1, AID => $admin_info->{aid} });

    $admins_table->addrow(
      $admin_info->{aid}, $admin_info->{name},
      $position_info->{POSITION},
        $aid_schedule->{type} ? $SCHEDULE_TYPES[ $aid_schedule->{type} ] : '-',
        $aid_schedule->{bet} ? $aid_schedule->{bet} : '-',
        $aid_schedule->{bet_per_hour} ? $aid_schedule->{bet_per_hour} : '-',
        $aid_schedule->{bet_overtime} ? $aid_schedule->{bet_overtime} : '-',
      $html->button('', "index=$index&AID_SCHEDULE=$admin_info->{aid}&FIO=$admin_info->{name}",
        { ICON => 'glyphicon glyphicon-time', })
    );
  }

  if ($FORM{AID_SCHEDULE}) {
    $html->message('info', $lang{CHANGE},);
    my $aid_schedule = $Crm->info_bet({ COLS_NAME => 1, AID => $FORM{AID_SCHEDULE} });

    if ($aid_schedule) {
      $html->tpl_show(
        _include('work_schedule', 'Crm'),
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
        _include('work_schedule', 'Crm'),
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

=head2 crm_pay_bets() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut

#**********************************************************
sub crm_pay_salary {
  my ($attr) = @_;

  my $admin_info = $Admins->info($FORM{aid}, { COLS_NAME => 1 });

  my $cashbox_select = cashbox_select();

  my $spend_types_select = $html->form_select(
    'SPENDING_TYPE_ID',
    {
      SELECTED    => $FORM{SPENDING_TYPE_ID} || $attr->{ID},
      SEL_LIST    => $Crm->list_spending_type({ COLS_NAME => 1 }),
      SEL_KEY     => 'id',
      SEL_VALUE   => 'name',
      NO_ID       => 1,
      SEL_OPTIONS => { "" => "" },
      MAIN_MENU   => get_function_index('crm_cashbox_spending_type'),
    }
  );

  $html->message('info', $lang{CHECK_DATA_AND_CHOOSE_CASHBOX});
  my $month = $FORM{month} || 1;
  my $bet = $FORM{bet} || 0;
  my $extra_amount = $FORM{extra_amount} || 0;
  my $sum_for_works = $FORM{sum_for_works} || 0;
  my $sum_to_pay = $FORM{sum_to_pay} || 0;

  $html->tpl_show(
    _include('crm_salary_confirm', 'Crm'),
    {
      FIO              => $admin_info->{A_FIO} || q{},
      BET              => $FORM{bet},
      EXTRA_AMOUNT     => $FORM{extra_amount},
      SUM              => sprintf('%.2f', $sum_to_pay), #sprintf('%.2f', $bet + $extra_amount + $sum_for_works),
      TEXT_MONTH       => $MONTHES[ $month - 1 ],
      MONTH            => $month,
      YEAR             => $FORM{year},
      CASHBOX          => $cashbox_select,
      SPENDING_TYPE_ID => $spend_types_select,
      AID              => $FORM{aid},
      INDEX            => get_function_index("crm_salary")
    }
  );

  return 1;
}


#**********************************************************
=head2 crm_working_time_norms()

=cut
#**********************************************************
sub crm_working_time_norms {
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

    $Crm->crm_time_norms_add({
      WORKING_NORMS => \@each_month_time_norms,
      YEAR          => $year,
    });

    _error_show($Crm);
  }

  my $working_time_norms = $Crm->crm_time_norms_list({
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
      { class => 'btn btn-xs btn-default glyphicon glyphicon-arrow-left' })
      . $html->button("$year", "index=$index", { class => 'btn btn-xs btn-primary' })
      . $html->button('', "index=$index&DATE=$next_year",
      { class => 'btn btn-xs btn-default glyphicon glyphicon-arrow-right' }),
  });

  $html->tpl_show(_include('crm_working_time_norms', 'Crm'), {
      TABLE => $normies_input_table->show(),
      DATE  => $FORM{DATE} || $DATE,
    });
}

#**********************************************************
=head2 crm_print_payment_statement()

=cut
#**********************************************************
sub crm_print_payment_statement {
  $html->tpl_show(_include('crm_print_payment_statement', 'Crm'), {
    });
  return 1;
}

#**********************************************************
=head2 crm_bonus_types()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub crm_bonus_types {
  my %TEMPLATE_ARGS = (
    ACTION      => "add",
    ACTION_LANG => $lang{ADD}
  );

  if($FORM{add}){
    $Crm->crm_bonus_type_add({%FORM});

    if(!$Crm->{errno}){
      $html->message('info', $lang{SUCCESS}, $lang{ADDED});
    }
    else{
      $html->message('err', $lang{ERROR}, $Crm->{errstr});
    }
  }
  elsif($FORM{chg}){
    my $bonus_type_info = $Crm->crm_bonus_type_info({
      ID       => $FORM{chg},
      NAME     => '_SHOW',
      AMOUNT   => '_SHOW',
      COMMENTS => '_SHOW',
      COLS_NAME => '_SHOW',
      COLS_UPPER => 1,
    });

    if($Crm->{errno}){
      $html->message('err', $lang{ERROR}, $Crm->{errstr});
      return 1;
    }

    %TEMPLATE_ARGS = %{$bonus_type_info};
    $TEMPLATE_ARGS{ACTION} = 'change';
    $TEMPLATE_ARGS{ACTION_LANG} = "$lang{CHANGE}";
  }
  elsif($FORM{change}){
    $Crm->crm_bonus_type_change({%FORM});
    if(!$Crm->{errno}){
      $html->message('info', $lang{SUCCESS}, $lang{CHANGED});
    }
    else{
      $html->message('err', $lang{ERROR}, $Crm->{errstr});
    }
  }
  elsif($FORM{del}){
    $Crm->crm_bonus_type_del({ID => $FORM{del}, %FORM});
    if(!$Crm->{errno}){
      $html->message('info', $lang{SUCCESS}, $lang{DELETED});
    }
    else{
      $html->message('err', $lang{ERROR}, $Crm->{errstr});
    }
  }

  $html->tpl_show(
    _include('crm_bonus_type_add', 'Crm'),
    {%TEMPLATE_ARGS}
  );

  result_former(
    {
      INPUT_DATA      => $Crm,
      FUNCTION        => 'crm_bonus_types_list',
      BASE_FIELDS     => 0,
      DEFAULT_FIELDS  => "ID, NAME, AMOUNT, COMMENTS",
      FUNCTION_FIELDS => 'change, del',
      FILTER_COLS     => {
      },
      EXT_TITLES      => {
        'id'           => "#",
        'name'         => $lang{NAME},
        'amount'       => $lang{SUM},
        'comments'     => $lang{COMMENTS},
      },
      SKIP_PAGES      => 1,
      TABLE           => {
        width       => '100%',
        caption     => "$lang{TYPE} $lang{BONUS}",
        qs          => $pages_qs,
        ID          => 'CRM_BONUS_TYPES',
        #        MENU        => "$lang{ADD}:index=$index&add_form=1:add",
        DATA_TABLE  => 1,
        title_plain => 1,
      },
      MAKE_ROWS       => 1,
      SEARCH_FORMER   => 1,
      MODULE          => 'Crm',
      TOTAL           => 1,
      SKIP_TOTAL_FORM => 1
    }
  );


  return 1;
}

#**********************************************************
=head2 crm_salary_bonus()

  Arguments:
     -
    
  Returns:
  
=cut
#**********************************************************
sub crm_salary_bonus {
  my ($current_year, $current_month, $current_day) = split("-", $DATE);

  my $bonus_types_select = $html->form_select(
    'BONUS_TYPE_ID',
    {
      SELECTED    => $FORM{BONUS_TYPE_ID} || '',
      SEL_LIST    => $Crm->crm_bonus_types_list({ COLS_NAME => 1, NAME => '_SHOW' }),
      SEL_KEY     => 'id',
      SEL_VALUE   => 'name',
      NO_ID       => 1,
      SEL_OPTIONS => { "" => "" },
#      MAIN_MENU   => get_function_index('crm_bonus_types'),
    }
  );

  my @YEARS = ( $current_year - 1, $current_year, $current_year + 1 );

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

  if($FORM{add}){
    my $amount = 0;
    if($FORM{BONUS_TYPE_ID}){
      my $bonus_type_info = $Crm->crm_bonus_type_info({
        ID        => $FORM{BONUS_TYPE_ID},
        AMOUNT    => '_SHOW',
        COLS_NAME => 1,
      });
      $amount = $bonus_type_info->{amount};
    }

    $Crm->crm_salary_bonus_add({
      %FORM,
      AMOUNT => $amount,
      MONTH  => $FORM{MONTH} ? $FORM{MONTH} + 1 : 1,
    });

    if(!$Crm->{errno}){
      $html->message('info', $lang{SUCCESS}, $lang{ADDED});
    }
    else{
      $html->message('err', $lang{ERROR}, $Crm->{errstr});
    }
  }
  elsif($FORM{del}){
    $Crm->crm_salary_bonus_del({ID => $FORM{del}});

    if(!$Crm->{errno}){
      $html->message('info', $lang{SUCCESS}, $lang{DELETED});
    }
    else{
      $html->message('err', $lang{ERROR}, $Crm->{errstr});
    }
  }

  if($FORM{add_form}){
    my %TEMPLATE_ARGS = (
      ACTION      => 'add',
      ACTION_LANG => $lang{ADD},
    );

    $html->tpl_show(
      _include('crm_bonus_give', 'Crm'),
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
      INPUT_DATA      => $Crm,
      FUNCTION        => 'crm_salary_bonus_list',
      BASE_FIELDS     => 0,
      DEFAULT_FIELDS  => "ID, AMOUNT, ADMIN_NAME, BONUS_NAME, YEAR",
      HIDDEN_FIELDS   => 'MONTH',
      FUNCTION_FIELDS => 'del',
      FILTER_COLS     => {
        year => '_crm_readable_date::MONTH,YEAR',
      },
      EXT_TITLES      => {
        'id'          => "#",
        'amount'      => $lang{SUM},
        'admin_name'  => $lang{EMPLOYEE},
        'bonus_name'  => "$lang{NAME} $lang{BONUS}",
        'year'        => $lang{MONTH},
      },
      SKIP_PAGES      => 1,
      TABLE           => {
        width       => '100%',
        caption     => "$lang{BONUS}",
        qs          => $pages_qs,
        ID          => 'CRM_BONUS_LIST',
        MENU        => "$lang{ADD}:index=$index&add_form=1:add",
        DATA_TABLE  => { "order"=> [[ 0, "desc" ]]},
        DT_CLICK    => 1,
        title_plain => 1,
      },
      MAKE_ROWS       => 1,
      SEARCH_FORMER   => 1,
      MODULE          => 'Crm',
      TOTAL           => 1,
      SKIP_TOTAL_FORM => 1
    }
  );


  return 1;
}

#**********************************************************
=head2 _crm_readable_date()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub _crm_readable_date {
  my (undef, $attr) = @_;
  my $month = $MONTHES[$attr->{VALUES}{MONTH} - 1] || '---';
  my $year  = $attr->{VALUES}{YEAR}            || 0;

  return "$month $year";
}

1;