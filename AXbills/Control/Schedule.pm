package Control::Schedule;

=head1 NAME

  Schedule functions

=cut

use strict;
use warnings FATAL => 'all';
no warnings 'numeric';

my (
  $admin,
  $CONF,
  $db,
  $lang,
);

my AXbills::HTML $html;
use AXbills::Base qw(days_in_month next_month json_former);

#**********************************************************
# Init
#**********************************************************
sub new {
  my $class = shift;
  $db = shift;
  $admin = shift;
  $CONF = shift;
  my ($attr) = @_;

  my $self = { db => $db, admin => $admin, conf => $CONF };

  $html = $attr->{HTML} if $attr->{HTML};
  $lang = $attr->{LANG} if $attr->{LANG};
  $self->{index} = $attr->{index} || 0;

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 schedule_tasks_board($tasks, $attr)

=cut
#**********************************************************
sub schedule_tasks_board {
  my $self = shift;
  my ($tasks, $attr) = @_;

  my @weekdays = @main::WEEKDAYS;
  shift @weekdays;
  my $date = $attr->{DATE} ? $attr->{DATE} : $main::DATE;
  my ($year, $month, $day) = $date =~ /(\d{4})\-(\d{2})\-(\d{2})/;

  my $table = $html->table({
    width          => '100%',
    border         => 1,
    title_plain    => \@weekdays,
    class          => "table work-table-month no-highlight mb-0 data-year='$year' data-month='$month'",
    ID             => $attr->{ID} || 'SCHEDULE_MONTH_TABLE',
    NOT_RESPONSIVE => 1,
    rows           => $self->_schedule_calendar_rows($month, $year, days_in_month({ DATE => $date }))
  });

  my ($prev_month, $next_month) = _get_previous_and_next_month($year, $month);
  $html->tpl_show(::templates('form_schedule_month'), {
    TABLE           => $table->show(),
    DATE            => $date,
    YEAR            => $year,
    MONTH_NAME      => $main::MONTHES[$month - 1],
    TASKS           => $tasks,
    NEXT_MONTH_DATE => $next_month,
    PREV_MONTH_DATE => $prev_month,
    FILTERS         => $attr->{FILTERS} || ''
  });
}

#**********************************************************
=head2 schedule_hours_tasks_board($tasks)

=cut
#**********************************************************
sub schedule_hours_tasks_board {
  my $self = shift;
  my ($tasks) = @_;

  my $admins_hash = ();
  map $admins_hash->{$_->{aid}} = $_, @{$admin->list({ DISABLE => 0, PAGE_ROWS => 1000, COLS_NAME => 1 })};

  $html->tpl_show(::templates('form_schedule_table'), {
    TASKS  => $tasks,
    ADMINS => json_former($admins_hash)
  });
}

#**********************************************************
=head2 _task_board_calendar_rows()

=cut
#**********************************************************
sub _schedule_calendar_rows {
  my $self = shift;
  my ($mon, $year, $days) = @_;

  my $columns = ();
  my @rows = ();
  my $link = "index=$self->{index}&DATE=$year-$mon-";

  my $first_day_time = POSIX::mktime(1, 0, 0, 1, $mon - 1, $year - 1900);
  my $week_day_counter = (localtime($first_day_time))[6];
  $week_day_counter = 7 if ($week_day_counter == 0);

  for ( my $i = 1; $i < $week_day_counter; $i++ ) {
    push (@{$columns}, $html->element('span', '', { class => 'disabled' }));
  };

  $week_day_counter--;
  for (my $day = 1; $day <= $days; $day++, $week_day_counter++) {

    my $is_weekday = $week_day_counter % 7 > 4 ? ' weekday' : '';

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
=head2 _get_previous_and_next_month($year, $month)

=cut
#**********************************************************
sub _get_previous_and_next_month  {
  my ($year, $month) = @_;

  my $prev_month = $month - 1;
  my $prev_year = $year;
  if ($prev_month == 0) {
    $prev_month = 12;
    $prev_year--;
  }

  my $next_month = $month + 1;
  my $next_year = $year;
  if ($next_month == 13) {
    $next_month = 1;
    $next_year++;
  }

  $prev_month = sprintf("%02d", $prev_month);
  $next_month = sprintf("%02d", $next_month);
  return ("$prev_year-$prev_month-01", "$next_year-$next_month-01");
}
1;