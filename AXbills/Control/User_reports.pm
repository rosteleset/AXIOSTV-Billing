=head1 NAME

  User Reports

=cut

use strict;
use warnings FATAL => 'all';
use Users;
use List::Util qw/max min/;
require AXbills::Misc;

our (
  %lang,
  @MONTHES,
  @WEEKDAYS,
  %permissions,
  $db,
  $admin,
);

our AXbills::HTML $html;

my $Users = Users->new($db, $admin, \%conf);

#**********************************************************
=head2 report_new_all_customers() - show chart for new and all customers

  Arguments:
    
  Returns:
    true
=cut
#**********************************************************
sub report_new_all_customers {
  my ($search_year, undef, undef) = split('-', $DATE);
  $search_year = $FORM{NEXT} || $FORM{PRE} if ($FORM{NEXT} || $FORM{PRE});

  my $all_data = $Users->all_new_report({ COLS_NAME => 1, YEAR => $search_year });
  my @new_users = ();
  my @all_users = ();

  foreach my $line (@$all_data) {
    push @new_users, $line->{count_new_users};
    push @all_users, $line->{count_all_users};
  }

  my $chart3 = $html->chart({
    TYPE       => 'line',
    DATA_CHART => {
      datasets => [ {
        data            => \@new_users,
        label           => $lang{NEW_CUST},
        yAxisID         => 'left-y-axis',
        borderColor     => '#5cc',
        fill            => 'false',
        backgroundColor => '#5cc',
        tension         => 0.3
      }, {
        data            => \@all_users,
        label           => $lang{ALL},
        yAxisID         => 'right-y-axis',
        borderColor     => '#a6f',
        fill            => 'false',
        backgroundColor => '#a6f',
        tension         => 0.3
      } ],
      labels   => \@MONTHES
    },
    OPTIONS    => {
      scales => {
        'left-y-axis'  => {
          type     => 'linear',
          position => 'left',
        },
        'right-y-axis' => {
          type     => 'linear',
          position => 'right',
        },
      }
    }
  });

  my $pre_button = $html->button(" ", "index=$index&PRE=" . ($search_year - 1), {
    class => 'btn btn-sm btn-default ml-1 mr-1',
    ICON => 'fa fa-arrow-left',
    TITLE => $lang{BACK}
  });

  my $next_button = $html->button(" ", "index=$index&NEXT=" . ($search_year + 1), {
    class => 'btn btn-sm btn-default ml-1',
    ICON => 'fa fa-arrow-right',
    TITLE => $lang{NEXT}
  });

  print "<div class='pl-0'>
            <div class='card card-primary card-outline'>
              <div class='card-header with-border'>$pre_button $search_year $next_button<h4 class='card-title'>$lang{REPORT_NEW_ALL_USERS}</h4></div>
              <div class='card-body'>
                $chart3
              </div>
          </div>\n";
  return 1;
}

#**********************************************************
=head2 report_new_arpu() - show chart for new and all customers

  Arguments:

  Returns:
    true
=cut
#**********************************************************
sub report_new_arpu {
  my ($search_year, undef, undef) = split('-', $DATE);
  my ($y, $m, undef) = split('-', $DATE);
  if ($FORM{NEXT} || $FORM{PRE}) {
    $search_year = $FORM{NEXT} || $FORM{PRE};
  }

  my $min_tariff_amount = $Users->min_tarif_val({ COLS_NAME => 1 });
  my $data_for_report = $Users->all_data_for_report({
    YEAR      => $search_year,
    COLS_NAME => 1
  });

  my $arpu_val = '';
  my $arpu_chart3 = 0;
  my $info_chart4 = 0;
  my @data_array = ();
  my @data_array2 = ();
  my @data_array3 = ();
  my @data_array4 = ();
  my @data_array5 = ();

  foreach my $data_per_month (@$data_for_report) {
    #    Make array for new users
    push @data_array, $data_per_month->{count_new_users};
    #    ARPU for all
    $arpu_val = ($data_per_month->{payments_for_every_month}) / ($data_per_month->{count_all_users} != '0' ? $data_per_month->{count_all_users} : 1);
    $arpu_val = sprintf("%0.3f", $arpu_val);
    push @data_array2, $arpu_val;
    #    AVR fees per month
    $arpu_chart3 = ($data_per_month->{fees_sum}) / ($data_per_month->{count_activated_users} || 1);
    push @data_array3, sprintf("%0.3f", $arpu_chart3);
    #   The average amount of active services
    $info_chart4 = ($data_per_month->{month_fee_sum} || 0) / ($data_per_month->{total_active_services} || 1);
    if ($data_per_month->{month} gt $m && $search_year eq $y) {
      push @data_array4, sprintf("%0.3f", 0);
    }
    else {
      push @data_array4, sprintf("%0.3f", $info_chart4);
    }

    #   Predicted ARPU
    my $result = ((($data_per_month->{month_fee_sum}) + (($data_per_month->{count_new_users}) * ($min_tariff_amount->{min_t} || 0))) / ($data_per_month->{count_all_users} || 1));
    if ($data_per_month->{month} eq ($m) && $search_year eq $y) {
      push @data_array5, sprintf("%0.3f", $result);
    }
    else {
      push @data_array5, sprintf("%0.3f", 0);
    }
  }

  unshift(@data_array5, 0.000);
  pop(@data_array5);

  my @array_all_data = (@data_array2, @data_array3, @data_array4, @data_array5);

  my $chart3 = $html->chart({
    TYPE       => 'line',
    DATA_CHART => {
      datasets => [
        {
          data            => \@data_array2,
          label           => 'ARPU',
          borderColor     => '#3af',
          fill            => 'false',
          backgroundColor => '#3af',
          tension         => 0.3
        },
        {
          data            => \@data_array,
          label           => $lang{NEW_CUST},
          borderColor     => '#f68',
          fill            => 'false',
          backgroundColor => '#f68',
          tension         => 0.3
        },
        {
          data            => \@data_array3,
          label           => $lang{AVR_FEES_AUTHORIZED},
          borderColor     => '#0f8',
          fill            => 'false',
          backgroundColor => '#0f8',
          tension         => 0.3
        },
        {
          data            => \@data_array4,
          label           => $lang{AVR_AMOUNT_ACTIVE_SERV},
          borderColor     => '#fa1',
          fill            => 'false',
          backgroundColor => '#fa1',
          tension         => 0.3
        },
        {
          data            => \@data_array5,
          label           => $lang{ARPU_FUTURE},
          borderColor     => '#00d',
          fill            => 'false',
          backgroundColor => '#00d',
          tension         => 0.3
        }
      ],
      labels   => \@MONTHES
    },
    OPTIONS    => {}
  });

  my $pre_button = $html->button(" ", "index=$index&PRE=" . ($search_year - 1), {
    class => ' btn btn-sm btn-default',
    ICON  => 'fa fa-arrow-left',
    TITLE => $lang{BACK}
  });
  my $next_button = $html->button(" ", "index=$index&NEXT=" . ($search_year + 1), {
    class => 'btn btn-sm btn-default',
    ICON  => 'fa fa-arrow-right',
    TITLE => $lang{NEXT}
  });
  print " <div class='pl-0'>
            <div class='card card-primary card-outline'>
              <div class='card-header with-border'>$pre_button $search_year $next_button<h4 class='card-title'>$lang{REPORT_NEW_ARPU_USERS}</h4></div>
              <div class='card-body'>
                $chart3
              </div>
          </div>\n";
  return 1;
}

#**********************************************************
=head2 report_balance_by_status() - Shows table with statuses,users count and sum deposits

  Arguments:

  Returns:

=cut
#**********************************************************
sub report_balance_by_status {
  require Service;
  Service->import();
  my $Service = Service->new($db, $admin, \%conf);
  my $status_list = $Service->status_list({
    NAME      => '_SHOW',
    COLOR     => '_SHOW',
    COLS_NAME => 1,
    SORT      => 'id',
    DESC      => 'ASC'
  });

  my $table = $html->table({
    width       => '100%',
    caption     => $lang{REPORT_BALANCE_BY_STATUS},
    title_plain => [ $lang{STATUS}, "$lang{COUNT} $lang{USERS}", $lang{BALANCE} ],
    qs          => $pages_qs,
    ID          => 'BALANCE_BY_STATUS'
  });

  my $list_index = get_function_index('internet_users_list');

  require Internet;
  Internet->import();

  my $Internet = Internet->new($db, $admin, \%conf);
  if ($FORM{DEBUG}) {
    $Internet->{debug} = 1;
  }

  foreach my $item (@$status_list) {
    my $report_data = $Internet->report_user_statuses({ STATUS => $item->{id}, COLS_NAME => 1 });
    $table->addrow(
      $html->color_mark(_translate($item->{name}), $item->{color}),
      (defined $report_data->{status} && ($item->{id} eq $report_data->{status})) ?
        $html->button($report_data->{COUNT},
          'index=' . $list_index . '&header=1&search_form=1&search=1&INTERNET_STATUS=' . $item->{id}) : 0,
      (defined $report_data->{status} && ($item->{id} eq $report_data->{status})) ? format_sum($report_data->{deposit}) : 0,
    );
  }

  print $table->show();

  return 1;
}

#*******************************************************************
=head1 report_switch () - show list of switches with quantity of all users, active and inactive users

=cut
#*******************************************************************
sub report_switch {

  my $switch_list = $Users->switch_list({
    ALL       => 1,
    COLS_NAME => 1,
    SORT      => $FORM{sort},
    DESC      => $FORM{desc},
  });

  my $table = $html->table({
    width               => '100%',
    caption             => $lang{REPORT_SWITCH_WITH_USERS},
    border              => 1,
    title               => [ '#', 'ID', $lang{SWITCHBOARDS}, $lang{USERS}, $lang{DISABLE}, $lang{ENABLED},
      $lang{QUANTITY_USERS_REQUEST}, $lang{COEFFICIENT_OF_DISABLE_USERS}, $lang{COEFFICIENT_OF_REQUESTS_USERS} ],
    ID                  => 'SWITCH_REPORT_ID',
    EXPORT              => 1,
  });

  my $i = 1;
  my ($switch_total, $users_total, $user_off_total, $user_on_total, $users_request_total, $coef_users_off, $coef_users_request_total);

  foreach my $line (@$switch_list) {
    $table->addrow(
      $i,
      $html->button($line->{switch_id},"index=62&NAS_ID=". ($line->{switch_id} || 0)),
      $line->{switch_name},
      $line->{switch_users},
      $line->{user_off},
      $line->{user_on},
      $line->{users_request},
      sprintf("%.2f", ($line->{switch_users}) ? $line->{user_off} / $line->{switch_users} * 100 : 0),
      sprintf("%.2f", ($line->{switch_users}) ? $line->{users_request} / $line->{switch_users} * 100 : 0),
    );

    $i++;
    $switch_total ++;
    $users_total += $line->{switch_users};
    $user_off_total += $line->{user_off};
    $user_on_total += $line->{user_on};
    $users_request_total += $line->{users_request};
  }

  if ($users_total) {
    $coef_users_off = sprintf("%.2f", $user_off_total / $users_total * 100);
    $coef_users_request_total = sprintf("%.2f", $users_request_total / $users_total * 100);
  }

  $table->addfooter(
    "$lang{TOTAL}: ",
    '',
    $switch_total,
    $users_total,
    $user_off_total,
    $user_on_total,
    $users_request_total,
    $coef_users_off,
    $coef_users_request_total,
  );

  print $table->show();

  return 1;
}

#*******************************************************************
=head1 report_users_disabled () - show list with reasons of disabled users

=cut
#*******************************************************************
sub report_users_disabled {

  my $disabled_users_list = $Users->report_users_disabled({
    COLS_NAME    => 1,
    DISABLE      => '_SHOW',
    DISABLE_DATE => '_SHOW',
    SORT         => $FORM{sort},
    DESC         => $FORM{desc}
  });


  my $table = $html->table({
    width   => '100%',
    caption => $lang{REPORT_REASON_USERS_DISABLED},
    border  => 1,
    title   => [ $lang{MONTH}, $lang{DISABLED}, $lang{NOT_ACTIVE}, $lang{HOLD_UP}, "$lang{DISABLE} $lang{NON_PAYMENT}", $lang{ERR_SMALL_DEPOSIT}],
    ID      => 'USER_DISABLED_REPORT',
    EXPORT  => 1,
  });

  foreach my $reason (@$disabled_users_list) {
    my $disable = $reason->{disable} || 0;
    my $not_active = $reason->{not_active} || 0;
    my $hold_up = $reason->{hold_up} || 0;
    my $non_payment = $reason->{non_payment} || 0;
    my $err_small_deposit = $reason->{err_small_deposit} || 0;

    my $quantity_per_month = $disable + $not_active + $hold_up + $non_payment + $err_small_deposit;
    if ($quantity_per_month == 0){
      $html->message('danger', $lang{ERR_NO_DATA});
      return;
    }

    $table->addrow(
        $reason->{disable_date},
        sprintf("%.0f",$disable/$quantity_per_month * 100).'% ('.$disable.')',
        sprintf("%.0f",$not_active/$quantity_per_month * 100).'% ('.$not_active.')',
        sprintf("%.0f",$hold_up/$quantity_per_month * 100).'% ('.$hold_up.')',
        sprintf("%.0f",$non_payment/$quantity_per_month * 100).'% ('.$non_payment.')',
        sprintf("%.0f",$err_small_deposit/$quantity_per_month * 100).'% ('.$err_small_deposit.')',
    );
  }

  print $table->show();

  return 1;
}

1;