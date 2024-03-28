=head2 NAME

  Accident events

=cut

use warnings;
use strict;
use AXbills::Base qw(date_diff days_in_month date_inc next_month );
use AXbills::Filters qw(_mac_former);

our (
  $db,
  $admin,
  %conf,
  %lang,
  @WEEKDAYS,
  @MONTHES
);

our Users $user;
our AXbills::HTML $html;

my $Accident = Accident ->new($db, $admin, \%conf);


#**********************************************************
=head2 accident_user_planned_events($attr) - planned_events for user portal
 = msgs_task_board

  Arguments:

  Results:

=cut
#**********************************************************
sub accident_user_planned_events {

  my $date = (defined $FORM{DATE}) ? $FORM{DATE} : $DATE;
  my ($year, $month, $day) = _accident_current_date($date);
  my $index = get_function_index("accident_user_planned_events");
  my $uid = $LIST_PARAMS{UID};
  my $table;
  my @weekdays = @WEEKDAYS;
  shift @weekdays;
  my @result_accident;

  if ($FORM{LIST}){
    $table = $html->table({
      ID             => 'ACCIDENT_USER_EVENTS_LIST',
      width          => '100%',
      border         => 1,
      title          => [$lang{NAME}, $lang{DESC}, $lang{DATE}, $lang{WORK_END_DATE}],
      pages          => $Accident->{TOTAL},
    });
  } else {
    $table = $html->table({
      ID             => 'ACCIDENT_USER_EVENTS_CALENDAR',
      width          => '100%',
      border         => 1,
      title_plain    => \@weekdays,
      class          => "table work-table-month no-highlight\" data-year='$year' data-month='$month'",
      NOT_RESPONSIVE => 1,
      rows           => _accident_user_get_calendar_rows($month, $year, days_in_month({ DATE => $date }) )
    });
  };

  my $calendar_button = $html->button($lang{CALENDAR}, "index=" . $index . "&CALENDAR=1", { BUTTON => 1 });
  my $list_button = $html->button($lang{LIST}, "index=" . $index . "&LIST=1",{ BUTTON => 1 });
  my ($next_month, $prev_month) = _accident_user_get_next_prev_date($year, $month);

  my $list = $Accident->user_accident_list({
    UID       => $uid,
    FROM_DATE => ($FORM{LIST}) ? '': "$year-$month-01",
    TO_DATE   => ($FORM{LIST}) ? '': "$year-$month-".days_in_month({ DATE => $date }),
    COLS_NAME => 1
  });

    foreach my $line (@{$list}) {

      if ($FORM{LIST}) {
        $table->addrow(
          $line->{name},
          $line->{descr},
          substr("$line->{date}",0,16),
          substr("$line->{end_time}",0,16) || '',
        );
      } else {
        push @result_accident, {
          ID           => $line->{id},
          NAME         => $line->{name},
          DATE_OPEN    => substr("$line->{date}",0,16),
          DATE_END     => substr("$line->{end_time}",0,16) || '',
        };
      }
    }

  my $month_switch = '';
  if (!$FORM{LIST}) {
    $month_switch = "
    <div class=\'card-body\'>
      <div class='col-md-12 text-center'>
      <a href='/index.cgi?index=$index&DATE=$prev_month'>
        <button type='submit' class='btn btn-default btn-sm'>
          <span class='fa fa-arrow-left' aria-hidden='true'></span>
        </button>
      </a>
      <label class='control-label' style='margin: 0 20px'>$MONTHES[$month - 1] $year</label>
      <a href='/index.cgi?index=$index&DATE=$next_month'>
        <button type='submit' class='btn btn-default btn-sm'>
          <span class='fa fa-arrow-right' aria-hidden='true'></span>
        </button>
      </a>
      </div>
    </div>
    ";
  }


  my $json_data = json_former(\@result_accident);

  $html->tpl_show(_include('accident_user_planned_events', 'Accident'), {
    CALENDAR_BUTTON => $calendar_button,
    LIST_BUTTON     => $list_button,
    TABLE           => $table->show({ OUTPUT2RETURN => 1 }),
    MONTH_SWITCH    => $month_switch,
    JSON_LIST       => $json_data
  });

  return 1;

}

#**********************************************************
=head2 _accident_current_date($date) - additional function for 'sub accident_user_planned_events'

   ATTR:
     date

   RETURN:
     cur_year
     cur_month
     cur_day

=cut
#**********************************************************
sub _accident_current_date {
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
=head2 _accident_user_get_calendar_rows($mon, $year, $days) - additional function for 'sub accident_user_planned_events'
 analog function: _msgs_get_calendar_rows

   ATTR:
    month
    year
    days

   RETURN:
    calendar_rows

=cut
#**********************************************************
sub _accident_user_get_calendar_rows {
  my ($mon, $year, $days) = @_;

  my $columns = ();
  my @calendar_rows = ();
  my $link = "index=" . get_function_index("accident_user_planned_events") . "&DATE=$year-$mon-$days";

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
      push (@calendar_rows, $columns);
      $columns = [];
    };

    my $format_day = sprintf("%.2d", $day);
    my $dayBtn = $html->button($day, $link, { ex_params => "class='mday$is_weekday'"});
    # my $dayBtn = $html->element('div', $day, { class => "mday$is_weekday", OUTPUT2RETURN => 1 });

    my $infoBlock = "<div class='month-accident-container' data-plan-date='$year-$mon-$format_day'></div>";
    push (@{$columns}, $dayBtn . $infoBlock);
  };

  my $columns_count = @{$columns};
  my $days_left = $columns_count ? 7 - $columns_count : 0;
  for ( my $i = 0; $i < $days_left; $i++ ) {
    push (@{$columns}, $html->element('span', '', { class => 'disabled', OUTPUT2RETURN => 1 }));
  };

  push (@calendar_rows, $columns);

  return \@calendar_rows;
}

#**********************************************************
=head2 _accident_user_get_next_prev_date ($year, $month) - additional function for 'sub accident_user_planned_events'
  analog function: _msgs_get_next_prev_date

  ATTR
    year
    month

  RETURN
    next_month
    prev_month

=cut
#**********************************************************
sub _accident_user_get_next_prev_date {
  my ($year, $month) = @_;

  my @parts = localtime(POSIX::mktime(1, 0, 0, 1, $month - 1, $year - 1900));
  $parts[4]++;
  my $next_month = strftime('%Y-%m-%d', localtime mktime @parts);

  $parts[4] -= 2;
  my $prev_month = strftime('%Y-%m-%d', localtime mktime @parts);

  return ($next_month, $prev_month);
}