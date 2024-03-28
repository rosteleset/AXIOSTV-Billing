=head1 NAME

  Reports
  
=cut

use warnings FATAL => 'all';
use strict;
use AXbills::Base qw(time2sec sec2time);
use Timetracker::db::Timetracker;
use AXbills::Fetcher qw/web_request/;
use Time::Piece;

our (%FORM, $db, %conf, $admin, %lang, @WEEKDAYS, $pages_qs, $DATE);
our AXbills::HTML $html;
my $Timetracker = Timetracker->new($db, $admin, \%conf);

#**********************************************************
=head2 all_report_time() - shows a table of repots

=cut
#**********************************************************


sub all_report_time {
  require Timetracker::Redmine;
  if(!$conf{TIMETRACKER_REDMINE_URL}){
    $html->message('err', $lang{NOT_CONFIGURED}, "$lang{NOT_FOUND} \$conf{TIMETRACKER_REDMINE_URL}");
    return 1;
  }
  Redmine->import();
  my $Redmine = Redmine->new($db, $admin, \%conf);

  require Control::Reports;
  reports({
      NO_GROUP    => 1,
      NO_TAGS     => 1,
      DATE_RANGE  => 1,
      DATE        => $FORM{DATE},
      REPORT      => '',
      PERIOD_FORM => 1,
  });

  my $table_support = $html->table({
      width   => "100%",
      caption => $lang{REPORTS_HEADER},
      title   => [
        $lang{ADMINS_LIST},
        $lang{CLOSED_TASKS},
        $lang{SCHEDULED_HOURS},
        $lang{TIME_COMPLEXITY},
        $lang{ACTUALLY_HOURS},
        $lang{CLOSED_TICKETS},
        $lang{TIME_SUPPORT} ],
      qs      => $pages_qs,
      ID      => "TIMETRACKER_REPORT1",
      EXPORT  => 1
  });

  my $admins_list = sel_admins({ HASH=>1, DISABLE => 0 });

  my @admin_aids = ();

  for my $aid (sort keys %{$admins_list}) {
    push(@admin_aids, $aid);
  }

  if (!$FORM{FROM_DATE} || !$FORM{TO_DATE}) {
    my ($day, $month, $year) = (localtime)[3,4,5];
    $FORM{FROM_DATE} = sprintf("%04d-%02d-%02d", $year+1900, $month+1, 1);
    $FORM{TO_DATE}   = sprintf("%04d-%02d-%02d", $year+1900, $month+1, $day);
  }

  my %attr = (
    FROM_DATE => $FORM{FROM_DATE},
    TO_DATE => $FORM{TO_DATE},
    DEBUG => 0,
    ADMIN_AIDS => \@admin_aids,
  );

  my $spent_hours           = $Redmine->get_spent_hours(\%attr);
  my $closed_tasks          = $Redmine->get_closed_tasks(\%attr);
  my $scheduled_hours       = $Redmine->get_scheduled_hours(\%attr);
  my $hours_on_complexity   = $Redmine->get_scheduled_hours_on_complexity(\%attr);
  my $closed_support_ticket = get_closed_support_ticket(\%attr);
  my $run_time_with_support = get_run_time_with_support(\%attr);

  my $total_closed_tasks = 0;
  my $total_points = 0;
  my $total_secs = 0;
  my $total_spent_hours = 0;
  my $total_scheduled_hours = 0;

  for my $aid (sort keys %{$admins_list}) {
    $table_support->addrow(
      $admins_list->{$aid} || 0,
      $closed_tasks->{$aid} || 0,
      $scheduled_hours->{$aid} || 0,
      $hours_on_complexity->{$aid} || 0,
      $spent_hours->{$aid} || 0,
      $closed_support_ticket->{$aid} || 0,
      $run_time_with_support->{$aid} || 0
    );

    $total_closed_tasks += $closed_tasks->{$aid} || 0;
    $total_scheduled_hours += $scheduled_hours->{$aid} || 0;
    $total_spent_hours += $spent_hours->{$aid} || 0;
    $total_points += $hours_on_complexity->{$aid} || 0;
    $total_secs += time2sec($run_time_with_support->{$aid} || 0);
  }

  $table_support->addrow(
    $lang{TOTAL},
    $html->b($total_closed_tasks || 0),
    $html->b($total_scheduled_hours || 0),
    $html->b($total_points || 0),
    $html->b($total_spent_hours || 0),
    0,
    $html->b(sec2time($total_secs, { str => 1 }))
  );

  print $table_support->show();

  return 1;
}

#**********************************************************
=head2 get_cloused_support_ticket($attr) - get count cloused support ticket for admin
  Arguments:
    $attr = {
      FROM_DATE => '2020-01-01',
      TO_DATE => '2020-02-20',
      DEBUG => 0,
      ADMIN_AIDS => [1, 2, 3],
    };
  
  Returns:
    $cloused_support_ticket
  
  Example:
    get_cloused_support_ticket($attr)
=cut
#**********************************************************
sub get_closed_support_ticket {
  my ($attr) = @_;
  my %closed_support_ticket = ();

  my $size_support = $Timetracker->change_element_work({
    DATA_DAY    => $attr->{FROM_DATE},
    TO_DATA_DAY => $attr->{TO_DATE},
  });

  for my $admin (@{$size_support}) {
    for my $aid (@{$attr->{ADMIN_AIDS}}) {
      if($aid == $admin->{aid}){
        $closed_support_ticket{$aid} = $admin->{admins_count};
      }
    }
  }

  return \%closed_support_ticket;
}

#**********************************************************
=head2 get_run_time_with_support($attr) - get run time with support ticket for admin
  Arguments:
    $attr = {
      FROM_DATE => '2020-01-01',
      TO_DATE => '2020-02-20',
      DEBUG => 0,
      ADMIN_AIDS => [1, 2, 3],
    };
  
  Returns:
    $time_with_support
  
  Example:
    get_run_time_with_support($attr);
=cut
#**********************************************************
sub get_run_time_with_support {
  my ($attr) = @_;
  my %time_with_support = ();

  my $all_time_with_support = $Timetracker->get_run_time({
    FROM_DATE => $attr->{FROM_DATE}.' 00:00:00',
    TO_DATE   => $attr->{TO_DATE}.' 23:59:59',
  });

  for my $times (@{$all_time_with_support}) {
    for my $aid (@{$attr->{ADMIN_AIDS}}) {
      if($times->{aid} == $aid) {
        $time_with_support{$aid} += $times->{run_time};
        sec2time($times->{run_time}, {format => 1});
      }
    }
  }

  for my $aid (@{$attr->{ADMIN_AIDS}}) {
    $time_with_support{$aid} = sec2time($time_with_support{$aid}, {format => 1});
  }

  return \%time_with_support;
}

#**********************************************************
=head2 report_sprint() - show sprint report


=cut
#**********************************************************
sub report_sprint {
  my ($attr) = @_;

  if (!$conf{TIMETRACKER_REDMINE_URL}) {
    $html->message('err', $lang{NOT_CONFIGURED}, "$lang{NOT_FOUND} \$conf{TIMETRACKER_REDMINE_URL}");
    return 1;
  }
  if (!$conf{TIMETRACKER_REDMINE_PROJECT_ID}) {
    $html->message('err', $lang{NOT_CONFIGURED}, "$lang{NOT_FOUND} \$conf{TIMETRACKER_REDMINE_PROJECT_ID}");
    return 1;
  }
  if (!$conf{TIMETRACKER_REDMINE_APIKEY}) {
    $html->message('err', $lang{NOT_CONFIGURED}, "$lang{NOT_FOUND} \$conf{TIMETRACKER_REDMINE_APIKEY}");
    return 1;
  }

  require Timetracker::Redmine;
  Redmine->import();
  my $Redmine = Redmine->new($db, $admin, \%conf);

  my $period_end_sec = Time::Piece->strptime($DATE, '%Y-%m-%d');
  my $period_start_sec = $period_end_sec - 86400 * 90; # last 90 days

  my $sprints_list_all = $Redmine->get_list_sprints();
  my @last_sprints = ();
  my %sprint_sel = ();
  my %responsible_sel = ();

  foreach my $sprint (@$sprints_list_all) {
    my ($sprint_number, $sprint_start_day, $sprint_start_time) = split(' ', $sprint->{name});
    next if ($sprint_start_day !~ m/^\d{2}\.\d{2}\.\d{4}$/);
    my $sprint_start_sec = Time::Piece->strptime($sprint_start_day, '%d.%m.%Y');

    if ($sprint_start_sec <= $period_end_sec && $sprint_start_sec > $period_start_sec) {
      $sprint_sel{$sprint->{id}} = "$sprint_number - $sprint_start_day";
      push @last_sprints, $sprint;

      my $issues_list = $Redmine->get_list_issues({ VERSION_ID => $sprint->{id} });
      foreach my $issue (@$issues_list) {
        next if (!$issue->{assigned_to}->{name});
        $responsible_sel{$issue->{'assigned_to'}->{'id'}} = $issue->{'assigned_to'}->{'name'};
      }
    }
  }

  form_search({ TPL => $html->tpl_show(_include('timetracker_report_search', 'Timetracker'), {
    SELECT_SPRINT      => $html->form_select('SPRINT', {
      SELECTED    => $FORM{SPRINT},
      SEL_HASH    => \%sprint_sel,
      NO_ID       => 1,
      SEL_OPTIONS => { '' => '' }
    }),
    SELECT_RESPONSIBLE => $html->form_select('RESPONSIBLE', {
      SELECTED    => $FORM{RESPONSIBLE},
      SEL_HASH    => \%responsible_sel,
      NO_ID       => 1,
      SEL_OPTIONS => { '' => '' }
    })
  }, { OUTPUT2RETURN => 1 }) });

  if (!$FORM{search}) {
    return 1;
  }

  my @sorted_sprints_list = sort {$b->{'id'} <=> $a->{'id'}} @last_sprints;

  foreach my $sprint (@sorted_sprints_list) {
    next if ($FORM{SPRINT} && $FORM{SPRINT} != $sprint->{id});

    my ($sprint_number, $sprint_start_day, $sprint_start_time) = split(' ', $sprint->{name});
    next if ($sprint_start_day !~ m/^\d{2}\.\d{2}\.\d{4}$/);
    my $sprint_start_sec = Time::Piece->strptime($sprint_start_day, '%d.%m.%Y');

    if ($sprint_start_sec <= $period_end_sec && $sprint_start_sec > $period_start_sec) {
      my $data_for_table = ();

      my $issues_list = $Redmine->get_list_issues({ VERSION_ID => $FORM{SPRINT} || $sprint->{id} });

      foreach my $issue (@$issues_list) {
        next if (!$issue->{assigned_to}->{name});
        next if ($FORM{RESPONSIBLE} && $FORM{RESPONSIBLE} != $issue->{'assigned_to'}->{'id'});
        my $assigned_to_id = $issue->{'assigned_to'}->{'id'};
        my $assigned_to_name = $issue->{'assigned_to'}->{'name'};
        my $complexity = $issue->{'custom_fields'}->[1]->{'value'} || 0;
        my $estimated_hours = $issue->{'estimated_hours'} || 0;
        my $spent_hours = 0;
        my $issues = 1;
        my $issues_completed = 0;
        my $points_completed = 0;

        my $issue_by_id = $Redmine->get_issue_by_id({ ISSUE_ID => $issue->{id} });
        $spent_hours = $issue_by_id->{spent_hours};

        # Search for an element with the same assigned_to_id in the new array
        my $data_for_table_element = _find_element_by_assigned_to_id($data_for_table, $assigned_to_id);

        if ($issue->{status}->{id} == 3 || $issue->{status}->{id} == 4 || $issue->{status}->{id} == 5 || $issue->{status}->{id} == 8) {
          $issues_completed += 1;
          $points_completed += $spent_hours * $complexity;
        }

        if ($data_for_table_element) {
          # If the element is found, we adding data to the existing value
          $data_for_table_element->{'issues'} += 1;
          $data_for_table_element->{'issues_completed'} += $issues_completed;
          $data_for_table_element->{'estimated_hours'} += $estimated_hours;
          $data_for_table_element->{'spent_hours'} += $spent_hours;
          $data_for_table_element->{'points'} += $estimated_hours * $complexity;
          $data_for_table_element->{'points_completed'} += $points_completed;
        }
        else {
          push @$data_for_table, {
            'assigned_to'      => {
              'id'   => $assigned_to_id,
              'name' => $assigned_to_name
            },
            'issues'           => $issues,
            'issues_completed' => $issues_completed,
            'estimated_hours'  => $estimated_hours,
            'spent_hours'      => $spent_hours,
            'points'           => $estimated_hours * $complexity,
            'points_completed' => $points_completed
          };
        }
      }

      if (!$data_for_table) {
        $html->message('warn', $lang{INFO}, "$lang{NO_TASKS_RESPONSIBLE}");
        return 1;
      }

      my $url_sprint_redmine = "$conf{MSGS_REDMINE_APIURL}issues?&set_filter=1&fixed_version_id=$sprint->{id}&status_id=*&per_page=50 target=\'_blank\'";
      my $total_issues = 0;
      my $total_issues_completed = 0;
      my $total_estimated_hours = 0;
      my $total_spent_hours = 0;
      my $total_points = 0;
      my $total_points_completed = 0;
      my @labels_chart = ();
      my @time_task_plan = ();
      my @time_task_fact = ();
      my @point_avarage_plan = ();
      my @point_avarage_fact = ();
      my @success_plan = ();
      my @success_fact = ();

      my $table_sprint = $html->table({
        width   => "100%",
        caption => $html->b("<a href=$url_sprint_redmine> $lang{SPRINT_TIMETRACK} №$sprint_number - $sprint_start_day</a>"),
        title   => [
          $lang{RESPOSIBLE},
          $lang{TASKS},
          $lang{TASK_EXECUTION},
          $lang{SCHEDULED_HOURS},
          $lang{ACTUALLY_HOURS},
          "$lang{AMOUNT_POINTS}, $lang{PLAN}",
          "$lang{AMOUNT_POINTS}, $lang{FACT}",
          "$lang{AVARAGE_POINT} ($lang{AMOUNT_POINTS},$lang{PLAN} / $lang{TASKS})",
          "$lang{AVARAGE_POINT} ($lang{AMOUNT_POINTS},$lang{FACT} / $lang{TASK_EXECUTION})",
          "$lang{AVARAGE_TIME_EXECUTION}, $lang{PLAN} ($lang{SCHEDULED_HOURS} / $lang{TASKS})",
          "$lang{AVARAGE_TIME_EXECUTION}, $lang{FACT} ($lang{ACTUALLY_HOURS} / $lang{TASK_EXECUTION})",
          "$lang{SUCCESS} ($lang{AMOUNT_POINTS},$lang{PLAN} / $lang{SCHEDULED_HOURS})",
          "$lang{SUCCESS} ($lang{AMOUNT_POINTS},$lang{FACT} / $lang{ACTUALLY_HOURS})"
        ],
        qs      => $pages_qs,
        ID      => "SPRINT_REPORT",
        EXPORT  => 1
      });

      foreach my $line (@$data_for_table) {
        my $estimated_hours = sprintf("%.0f", $line->{estimated_hours});
        my $spent_hours = sprintf("%.0f", $line->{spent_hours});
        my $points = sprintf("%.0f", $line->{points});
        my $points_completed = sprintf("%.0f", $line->{points_completed});
        my $issues = $line->{issues};
        my $issues_completed = $line->{issues_completed};

        my $avarage_point_plan = sprintf("%.1f", $line->{points} / $line->{issues});
        my $avarage_point_fact = sprintf("%.1f", $line->{points_completed} / $line->{issues_completed}) if ($issues_completed);
        my $success_plan = sprintf("%.1f", $line->{points} / $line->{estimated_hours}) if ($line->{estimated_hours});
        my $success_fact = sprintf("%.1f", $line->{points_completed} / $line->{spent_hours}) if $spent_hours;
        my $time_task_plan = sprintf("%.2f", $estimated_hours / $issues);
        my $time_task_fact = sprintf("%.2f", $spent_hours / $issues_completed) if $issues_completed;

        $table_sprint->addrow(
          $line->{assigned_to}->{name},
          $issues,
          $issues_completed,
          $estimated_hours,
          $spent_hours,
          $points,
          $points_completed,
          $avarage_point_plan,
          $avarage_point_fact,
          $time_task_plan,
          $time_task_fact,
          $success_plan,
          $success_fact
        );

        $total_estimated_hours += $estimated_hours;
        $total_spent_hours += $spent_hours;
        $total_issues += $issues;
        $total_issues_completed += $issues_completed;
        $total_points += $points;
        $total_points_completed += $points_completed;

        #for chart
        push @labels_chart, ($line->{assigned_to}->{name});
        push @time_task_plan, $time_task_plan;
        push @time_task_fact, $time_task_fact if ($issues_completed);
        push @point_avarage_plan, $avarage_point_plan;
        push @point_avarage_fact, $avarage_point_fact;
        push @success_plan, $success_plan;
        push @success_fact, $success_fact;
      }

      # Show charts
      _sprint_report_chart(\@labels_chart, \@time_task_plan, \@time_task_fact, \@point_avarage_plan, \@point_avarage_fact, \@success_plan, \@success_fact);

      if (!$FORM{RESPONSIBLE}) {
        _sprint_report_chart(
          [ $lang{TOTAL} ],
          [ sprintf("%.1f", $total_estimated_hours / $total_issues) ],
          [ sprintf("%.1f", $total_spent_hours / $total_issues_completed) ],
          [ sprintf("%.1f", $total_points / $total_issues) ],
          [ sprintf("%.1f", $total_points_completed / $total_issues_completed) ],
          [ sprintf("%.1f", $total_points / $total_estimated_hours) ],
          [ sprintf("%.1f", $total_points_completed / $total_spent_hours) ]
        );

        $table_sprint->addfooter(
          "$lang{TOTAL}: ",
          $total_issues,
          $total_issues_completed,
          $total_estimated_hours,
          $total_spent_hours,
          $total_points,
          $total_points_completed,
          sprintf("%.1f", $total_points / $total_issues),
          sprintf("%.1f", $total_points_completed / $total_issues_completed),
          sprintf("%.1f", $total_estimated_hours / $total_issues),
          sprintf("%.1f", $total_spent_hours / $total_issues_completed),
          sprintf("%.1f", $total_points / $total_estimated_hours),
          sprintf("%.1f", $total_points_completed / $total_spent_hours),
        )
      }

      print $table_sprint->show();

      last if ($FORM{SPRINT});
    }
  }

  return 1;
}


#**********************************************************
=head2 _find_element_by_assigned_to_id($array, $assigned_to_id)

  Arguments:
    $array
    $assigned_to_id

  Returns:
    $element

=cut
#**********************************************************
sub _find_element_by_assigned_to_id {
  my ($array, $assigned_to_id) = @_;

  foreach my $element (@$array) {
    if ($element->{'assigned_to'}->{'id'} == $assigned_to_id) {
      return $element;
    }
  }

  return undef;
}

#**********************************************************
=head2 _sprint_report_chart () - show chart

      Attr:
       $labels_chart
       $time_task_plan
       $time_task_fact
       $point_avarage_plan
       $point_avarage_fact
       $success_plan
       $success_fact

=cut
# **********************************************************
sub _sprint_report_chart {
  my ($labels_chart, $time_task_plan, $time_task_fact, $point_avarage_plan, $point_avarage_fact, $success_plan, $success_fact) = @_;

  print $html->chart({
    TYPE              => 'bar',
    X_LABELS          => $labels_chart,
    DATA              => {
      "$lang{AVARAGE_TIME_EXECUTION}, $lang{PLAN}" => $time_task_plan,
      "$lang{AVARAGE_TIME_EXECUTION}, $lang{FACT}" => $time_task_fact,
      "$lang{AVARAGE_POINT}, $lang{PLAN}"          => $point_avarage_plan,
      "$lang{AVARAGE_POINT}, $lang{FACT}"          => $point_avarage_fact,
      "$lang{SUCCESS}, $lang{PLAN}"                => $success_plan,
      "$lang{SUCCESS}, $lang{FACT}"                => $success_fact
    },
    BACKGROUND_COLORS => {
      "$lang{AVARAGE_TIME_EXECUTION}, $lang{PLAN}" => 'rgba(5, 99, 132, 0.5)',
      "$lang{AVARAGE_TIME_EXECUTION}, $lang{FACT}" => 'rgba(5, 99, 132, 0.8)',
      "$lang{AVARAGE_POINT}, $lang{PLAN}"          => 'rgba(255, 193, 7, 0.5)',
      "$lang{AVARAGE_POINT}, $lang{FACT}"          => 'rgba(255, 193, 7, 0.8)',
      "$lang{SUCCESS}, $lang{PLAN}"                => 'rgba(220, 53, 69, 0.5)',
      "$lang{SUCCESS}, $lang{FACT}"                => 'rgba(220, 53, 69, 0.8)'
    },
    OUTPUT2RETURN     => 1,
    FILL              => 'false',
    IN_CONTAINER      => 1
  });

}

1;