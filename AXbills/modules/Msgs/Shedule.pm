=head1 NAME

  Msgs Shedule

=cut

use strict;
use warnings FATAL => 'all';
use AXbills::Base qw(days_in_month date_diff load_pmodule json_former);

our (
  %lang,
  $admin,
  %conf,
  $db,
  @WEEKDAYS,
  @MONTHES
);

our AXbills::HTML $html;
my $Msgs = Msgs->new($db, $admin, \%conf);

#**********************************************************
=head2 msgs_shedule_month()

=cut
#**********************************************************
sub msgs_task_board {

  if ($FORM{HOURS}) {
    msgs_shedule_hours();
    return 1;
  }

  if ($FORM{change} && $FORM{plan_date} && $FORM{id}) {
    $Msgs->message_change({ ID => $FORM{id}, PLAN_DATE => $FORM{plan_date} });
    return;
  }

  my $date = (defined $FORM{DATE}) ? $FORM{DATE} : $DATE;
  my ($year, $month, $day) = _current_data($date);

  my $tasks = _msgs_shedule_month_get_tasks($year, $month, $FORM{AID});
  my $task_status_select = msgs_sel_status({ NAME => 'TASK_STATUS_SELECT', ALL => 1 });
  my $admins_select = sel_admins();

  my @weekdays = @WEEKDAYS;
  shift @weekdays;

  my $table = $html->table({
    width          => '100%',
    border         => 1,
    title_plain    => \@weekdays,
    class          => "table work-table-month no-highlight\" data-year='$year' data-month='$month'",
    ID             => 'MSGS_SHEDULE_MONTH_TABLE',
    NOT_RESPONSIVE => 1,
    rows           => _msgs_get_calendar_rows($month, $year, days_in_month({ DATE => $date }))
  });

  my ($next_month, $prev_month) = _msgs_get_next_prev_date($year, $month);
  $html->tpl_show(_include('msgs_shedule_month', 'Msgs'), {
    TABLE              => $table->show(),
    TASK_STATUS_SELECT => $task_status_select,
    ADMINS_SELECT      => $admins_select,
    DATE               => $date,
    YEAR               => $year,
    MONTH_NAME         => $MONTHES[$month - 1],
    TASKS              => json_former($tasks),
    NEXT_MONTH_DATE    => $next_month,
    PREV_MONTH_DATE    => $prev_month,
  });

  return 1;
}

#**********************************************************
=head2 _msgs_get_next_prev_date($year, $month)

=cut
#**********************************************************
sub _msgs_get_next_prev_date {
  my ($year, $month) = @_;

  my @parts = localtime(POSIX::mktime(1, 0, 0, 1, $month - 1, $year - 1900));
  $parts[4]++;
  my $next_month = strftime('%Y-%m-%d', localtime mktime @parts);

  $parts[4] -= 2;
  my $prev_month = strftime('%Y-%m-%d', localtime mktime @parts);

  return ($next_month, $prev_month);
}

#**********************************************************
=head2 _msgs_shedule_month_get_tasks($year, $month) - get tasks that have not defined PLAN_DATE date or date && time

  Arguments:
    $year - year with century
    $month - month num 01 to 12

  Returns:
    arr_ref, arr_ref

=cut
#**********************************************************
sub _msgs_shedule_month_get_tasks {
  my ($year, $month, $aid) = @_;

  my $date_interval = "$year-$month-01/$year-$month-" . days_in_month({ DATE => "$year-$month-1" });

  my $messages_list = $Msgs->messages_list({
    RESPOSIBLE_ADMIN_LOGIN => '_SHOW',
    PLAN_INTERVAL          => '_SHOW',
    RESPOSIBLE             => $aid || '_SHOW',
    PLAN_DATE              => $date_interval,
    SUBJECT                => '_SHOW',
    STATE                  => $FORM{TASK_STATUS_SELECT},
    PAGE_ROWS              => 100,
    COLS_NAME              => 1
  });

  my $free_messages_list = $Msgs->messages_list({
    RESPOSIBLE_ADMIN_LOGIN => '_SHOW',
    LOGIN                  => '_SHOW',
    PLAN_DATE              => '0000-00-00',
    RESPOSIBLE             => $aid || '_SHOW',
    STATE                  => $FORM{TASK_STATUS_SELECT},
    SUBJECT                => '_SHOW',
    PLAN_INTERVAL          => '_SHOW',
    COLS_NAME              => 1,
    PAGE_ROWS              => 100
  });

  return [@{$free_messages_list}, @{$messages_list}];
}

#**********************************************************
=head2 _current_data()

=cut
#**********************************************************
sub _current_data {
  my ($date) = @_;

  if ( $date =~ /(\d{4})\-(\d{2})\-(\d{2})/ ) {
    my $cur_year = $1;
    my $cur_month = $2;
    my $cur_day = $3;

    return ($cur_year, $cur_month, $cur_day);
  }

  $html->message('err', $lang{ERROR}, "Incorrect DATE");
  return 0;
}

#**********************************************************
=head2 _msgs_get_calendar_rows()

=cut
#**********************************************************
sub _msgs_get_calendar_rows {
  my ($mon, $year, $days) = @_;

  my $columns = ();
  my @rows = ();
  my $link = "index=" . get_function_index("msgs_task_board") . "&DATE=$year-$mon-";

  my $first_day_time = POSIX::mktime(1, 0, 0, 1, $mon - 1, $year - 1900);
  my $week_day_counter = (localtime($first_day_time))[6];
  $week_day_counter = 7 if ($week_day_counter == 0);

  for ( my $i = 1; $i < $week_day_counter; $i++ ) {
    push (@{$columns}, $html->element('span', '', { class => 'disabled' }));
  };

  $week_day_counter--;
  for (my $day = 1; $day <= $days; $day++, $week_day_counter++) {

    my $is_weekday = $week_day_counter % 7 > 4 ? ' weekday' : '';

    # my $current = ($attr->{CURRENT_DAY} == $day) ? ' current' : '';

    if ( $week_day_counter % 7 == 0 ) {
      push (@rows, $columns);
      $columns = [];
    };

    my $format_day = sprintf("%.2d", $day);
    my $dayBtn = $html->button($day, "$link$format_day&HOURS=1", {
      ex_params => "class='mday$is_weekday' target='_blank'"
    });
    my $tasksBlock = "<div class='month-tasks-container' data-plan-date='$year-$mon-$format_day'></div>";
    push (@{$columns}, $dayBtn . $tasksBlock);
  };

  my $columns_count = @{$columns};
  my $days_left = $columns_count ? 7 - $columns_count : 0;
  for ( my $i = 0; $i < $days_left; $i++ ) {
    push (@{$columns}, $html->element('span', '', { class => 'disabled' }));
  };

  push (@rows, $columns);

  return \@rows;
}

#**********************************************************
=head2 msgs_shedule_hourse() - Visualize time and admin task assignment

=cut
#**********************************************************
sub msgs_shedule_hours {

  my $date = $FORM{DATE} || 'NOW()';

  my $messages_list = $Msgs->messages_list({
    LOGIN         => '_SHOW',
    RESPOSIBLE    => '_SHOW',
    PRIORITY_ID   => '_SHOW',
    SUBJECT       => '_SHOW',
    PLAN_DATE     => $date,
    PLAN_INTERVAL => '_SHOW',
    PLAN_POSITION => '_SHOW',
    COLS_NAME     => 1,
  });

  my $admins_hash = ();
  map $admins_hash->{$_->{aid}} = $_, @{$admin->list({ DISABLE => 0, PAGE_ROWS => 1000, COLS_NAME => 1 })};

  my $tasks_json = json_former($messages_list);
  $tasks_json =~ s/[\n\r]+//g;

  $html->tpl_show(_include('msgs_shedule_table', 'Msgs'), {
    INDEX_JOB => get_function_index('shedule_hour_work'),
    TASKS     => $tasks_json,
    ADMINS    => json_former($admins_hash)
  });

  return 1;
}

#**********************************************************
=head2 shedule_hour_work() -

  Arguments:

  Returns:

=cut
#**********************************************************
sub shedule_hour_work {

  if ($FORM{CHANGE_TEMPLATE}) {
    $Msgs->message_info($FORM{id});
    $Msgs->{PLAN_INTERVAL} ||= 120;

    print $html->tpl_show(_include('msgs_message_duration', 'Msgs'), {
      ID      => 'SEND_TYPE',
      HOURS   => int $Msgs->{PLAN_INTERVAL} / 60,
      MINUTES => $Msgs->{PLAN_INTERVAL} % 60,
    }, { OUTPUT2RETURN => 1 });
    return;
  }

  my $params = { ID => $FORM{id} };
  $params->{PLAN_TIME} = $FORM{plan_time} if $FORM{plan_time};
  $params->{RESPOSIBLE} = $FORM{aid} if $FORM{plan_time};
  $params->{PLAN_INTERVAL} = $FORM{minutes} || 0 if defined $FORM{minutes};

  $Msgs->message_change($params)
}

1;
