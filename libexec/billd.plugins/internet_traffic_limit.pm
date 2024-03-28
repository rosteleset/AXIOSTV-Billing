=head1 NAME

   internet_traffic_limit();

=cut

use strict;
use warnings FATAL => 'all';
use AXbills::Base qw(date_diff in_array);
use Internet;

our (
  $db,
  $admin,
  $Admin,
  %conf,
  %lang,
  $Sessions,
  $debug,
  %LIST_PARAMS,
  $DATE,
  $TIME,
  $Nas,
  $argv,
);

$admin = $Admin;
my $Internet = Internet->new($db, $Admin, \%conf);
my $Tariffs  = Tariffs->new($db, \%conf, $admin);

$conf{MB_SIZE} = $conf{KBYTE_SIZE} * $conf{KBYTE_SIZE};

my (undef, undef, $d) = split(/-/, $DATE);

internet_traffic_limit_block();
internet_traffic_limit_unblock();
compare_start_activate();
internet_ureports_reset();


#**********************************************************
=head2 compare_start_activate();

=cut
#**********************************************************
sub compare_start_activate {

  if($debug > 2) {
    print "compare_start_activate\n";
    if($debug > 6) {
      $Sessions->{debug}=1;
    }
  }

  $Sessions->online(
    {
      'USER_NAME'           => '_SHOW',
      'LOGIN'               => '_SHOW',
      'NAS_PORT_ID'         => '_SHOW',
      'CLIENT_IP'           => '_SHOW',
      'DURATION'            => '_SHOW',
      'ACCT_SESSION_ID'     => '_SHOW',
      'DURATION_SEC'        => '_SHOW',
      'GUEST'               => '_SHOW',
      'CID'                 => '_SHOW',
      'ONLINE_TP_ID'        => '_SHOW',
      'ACTIVATE'            => '>0000-00-00',
      'STARTED'             => '_SHOW',
      'DURATION'            => '_SHOW',
      'LAST_ALIVE'          => '_SHOW',
      'SKIP_DEL_CHECK'      => 1,
      %LIST_PARAMS,
    }
  );

  print "==> check_lines\n" if ($debug > 1);
  my $online_session = $Sessions->{nas_sorted};
  my $nas_list = $Nas->list( { %LIST_PARAMS, COLS_NAME => 1, COLS_UPPER => 1, PAGE_ROWS => 50000 } );

  foreach my $nas ( @{$nas_list} ) {
    #if don't have online users skip it
    my $l = $online_session->{ $nas->{NAS_ID} };
    next if ($#{$l} < 0);

    if ($debug > 0) {
      print "NAS: ($nas->{NAS_ID}) $nas->{NAS_IP} NAS_TYPE: $nas->{NAS_TYPE} STATUS: $nas->{NAS_DISABLE} Alive: $nas->{NAS_ALIVE} Online: " . ($#{$l} + 1) . "\n";
    }


    foreach my $online (@{$l}) {
      my $uid = $online->{uid};
      my ($start_date, $start_time) = split(/ /, $online->{started});

      if (! $start_time) {
        next;
      }

      if(date_diff($online->{activate}, $start_date) < 0) {
        print "$uid ACTIVATE: $online->{activate} STARTED: $online->{started}\n";
        $online->{user_service_state}=0;
        session_hangup($nas, $online, "HANGUP WRONG START UID: $uid");
      }
    }
  }

  return 1;
}

#**********************************************************
=head2 internet_traffic_limit_block();

=cut
#**********************************************************
sub internet_traffic_limit_block {

  if($debug > 1) {
    print "internet_traffic_limit\n";
    if($debug > 6) {
      $Internet->{debug}=1;
      $Tariffs->{debug}=1;
    }
  }

  my $tp_list = $Tariffs->list({
    WEEK_TRAF_LIMIT  => '_SHOW',
    DAY_TRAF_LIMIT   => '_SHOW',
    MONTH_TRAF_LIMIT => '_SHOW',
    TOTAL_TRAF_LIMIT => '_SHOW',
    PREPAID          => '_SHOW',
    DAY_TIME_LIMIT   => '_SHOW',
    WEEK_TIME_LIMIT  => '_SHOW',
    MONTH_TIME_LIMIT => '_SHOW',
    TOTAL_TIME_LIMIT => '_SHOW',
    OCTETS_DIRECTION => '_SHOW',
    %LIST_PARAMS,
    COLS_NAME        => 1,
    COLS_UPPER       => 1
  });

  foreach my $tp ( @$tp_list ) {
    if( ($tp->{PREPAID} || 0)
        + $tp->{WEEK_TRAF_LIMIT}
        + $tp->{DAY_TRAF_LIMIT}
        + $tp->{MONTH_TRAF_LIMIT}
        + $tp->{TOTAL_TRAF_LIMIT}
        + $tp->{DAY_TIME_LIMIT} == 0) {
      next;
    }

    if($tp->{PREPAID}) {
      $tp->{PREPAID_TRAF_LIMIT} = $tp->{PREPAID};
    }

    if($debug > 1) {
      print "  TP_ID: $tp->{tp_id} MONTH_TRAF_LIMIT: $tp->{MONTH_TRAF_LIMIT}\n";
    }

    my $internet_list = $Internet->user_list({
      INTERNET_ACTIVATE => '_SHOW',
      LOGIN           => '_SHOW',
      DEPOSIT         => '_SHOW',
      CREDIT          => '_SHOW',
      TP_CREDIT       => '_SHOW',
      MONTH_FEE       => ($conf{AMOUNT_MONTH_FEE_BLOCK_FROM}) ? $conf{AMOUNT_MONTH_FEE_BLOCK_FROM} : '_SHOW',
      TP_ID           => $tp->{tp_id},
      INTERNET_STATUS => 0,
      #    DAY_TRAF_LIMIT   => '_SHOW',
      #    WEEK_TRAF_LIMIT  => '_SHOW',
      #    MONTH_TRAF_LIMIT => '_SHOW',
      #    TOTAL_TRAF_LIMIT => '_SHOW',
      COLS_NAME       => 1,
      PAGE_ROWS       => 10000000,
      %LIST_PARAMS
    });

    foreach my $u (@$internet_list) {
      my $uid = $u->{uid};
      if ($debug > 1) {
        print "UID: $uid ";
        print "LOGIN: $u->{login} DEPOSIT: $u->{deposit} CREDIT: $u->{credit} STATUS: $u->{internet_status} MONTH_FEE: $u->{month_fee}\n";
        #print "DAY_TRAF_LIMIT: $u->{day_traf_limit} WEEK_TRAF_LIMIT: $u->{week_traf_limit} MONTH_TRAF_LIMIT: $u->{month_traf_limit} TOTAL_TRAF_LIMIT: $u->{total_traf_limit}\n";
      }

      #my $credit = ($u->{tp_credit} > 0) ? $u->{tp_credit} : $u->{credit};

      my @periods = ('TOTAL', 'DAY', 'WEEK', 'MONTH', 'PREPAID');
      my $session_time_limit = 0;
      my @time_limits = ();

      my @direction_sum = (
        "(SUM(sent + recv) / $conf{MB_SIZE} + SUM(acct_output_gigawords) * 4096 + SUM(acct_input_gigawords) * 4096)",
        "(SUM(recv) / $conf{MB_SIZE} + SUM(acct_input_gigawords) * 4096)",
        "(SUM(sent) / $conf{MB_SIZE} + SUM(acct_output_gigawords) * 4096)"
      );

      my $month_start = ($u->{internet_activate} && $u->{internet_activate} eq '0000-00-00') ? q/DATE_FORMAT(CURDATE(), '%Y-%m-01 00:00:00')/ : "'$u->{internet_activate} 00:00:00'";
      my %SQL_params = (
        TOTAL   => '',
        DAY     => "AND (start >= CONCAT(CURDATE(), ' 00:00:00') AND start<=CONCAT(CURDATE(), ' 24:00:00'))",
        WEEK    => "AND (YEAR(CURDATE())=YEAR(start)) AND (WEEK(CURDATE()) = WEEK(start))",
        MONTH   => "AND (start >= $month_start) ", #AND start<=DATE_FORMAT($month_start, '%Y-%m-31 24:00:00'))"
        PREPAID => "AND (start >= $month_start) "
      );

      my $WHERE = "uid='$u->{uid}' AND tp_id='$tp->{tp_id}'";

      my $online_time = 0;

      foreach my $period (@periods) {
        if (($tp->{ $period . '_TIME_LIMIT' } && $tp->{ $period . '_TIME_LIMIT' } > 0) || ($tp->{ $period . '_TRAF_LIMIT' } && $tp->{ $period . '_TRAF_LIMIT' } > 0)) {
          #my $session_time_limit = $time_limit;
          my $session_traf_limit        = 0;

          my $octets_direction          = "(sent + 4294967296 * acct_output_gigawords) + (recv + 4294967296 * acct_input_gigawords) ";
          my $octets_direction2         = "sent2 + recv2";
          my $octets_online_direction   = "acct_input_octets + acct_output_octets";
          my $octets_online_direction2  = "ex_input_octets + ex_output_octets";
          my $octets_direction_interval = "(li.sent + li.recv)";

          if ($tp->{OCTETS_DIRECTION} == 1) {
            $octets_direction          = "recv + 4294967296 * acct_input_gigawords ";
            $octets_direction2         = "recv2";
            $octets_online_direction   = "acct_input_octets + 4294967296 * acct_input_gigawords";
            $octets_online_direction2  = "ex_input_octets";
            $octets_direction_interval = "li.recv";
          }
          elsif ($tp->{OCTETS_DIRECTION} == 2) {
            $octets_direction          = "sent + 4294967296 * acct_output_gigawords ";
            $octets_direction2         = "sent2";
            $octets_online_direction   = "acct_output_octets + 4294967296 * acct_output_gigawords";
            $octets_online_direction2  = "ex_output_octets";
            $octets_direction_interval = "li.sent";
          }

          $Internet->query("SELECT
             SUM($octets_online_direction) / $conf{MB_SIZE} AS online_traffic,
             SUM($octets_online_direction2) / $conf{MB_SIZE} AS online_traffic
          FROM internet_online l
          WHERE uid='$uid' AND tp_id='$tp->{tp_id}'
          GROUP BY l.uid;");

          my $traffic_use = $Internet->{list}->[0]->[0];

          $Internet->query("SELECT IF(" . ($tp->{ $period . '_TIME_LIMIT' } || 0) . " > 0, " . ($tp->{ $period . '_TIME_LIMIT' } || 0) . "- $online_time - SUM(duration), 0),
          IF(" . $tp->{ $period . '_TRAF_LIMIT' } . " > 0, ". $direction_sum[$tp->{OCTETS_DIRECTION}] .", 0) AS used_log_traffic,
          1
         FROM internet_log
         WHERE $WHERE $SQL_params{$period}
         GROUP BY 3;"
          );

          if ($Internet->{TOTAL} && $Internet->{TOTAL} > 0) {
            ($session_time_limit, $session_traf_limit) = @{ $Internet->{list}->[0] };
            push(@time_limits, $session_time_limit) if ($tp->{ $period . '_TIME_LIMIT' } && $tp->{ $period . '_TIME_LIMIT' } > 0);
            $traffic_use += $session_traf_limit;
          }

          if (defined($traffic_use) && $traffic_use >= $tp->{ $period . '_TRAF_LIMIT' }) {
            print "$DATE $TIME UID: $uid Rejected! $period TP_ID: $tp->{tp_id} ACTIVATE: $u->{internet_activate} Traffic limit utilized '$traffic_use/$tp->{ $period . '_TRAF_LIMIT' } Mb'\n";
            if($debug < 6) {
              $Internet->user_change({
                UID    => $uid,
                STATUS => ($argv->{BLOCK_STATUS}) ? ($argv->{BLOCK_STATUS}) : 10,
              });
            }
          }
        }
      }
    }
  }

  return 1;
}

#**********************************************************
=head2 internet_traffic_limit_unblock();

=cut
#**********************************************************
sub internet_traffic_limit_unblock {

  if($debug > 1) {
    print "internet_traffic_limit_unblock\n";
  }

  my $tp_list = $Tariffs->list({
    WEEK_TRAF_LIMIT  => '_SHOW',
    DAY_TRAF_LIMIT   => '_SHOW',
    MONTH_TRAF_LIMIT => '_SHOW',
    TOTAL_TRAF_LIMIT => '_SHOW',
    PREPAID          => '_SHOW',
    DAY_TIME_LIMIT   => '_SHOW',
    WEEK_TIME_LIMIT  => '_SHOW',
    MONTH_TIME_LIMIT => '_SHOW',
    TOTAL_TIME_LIMIT => '_SHOW',
    OCTETS_DIRECTION => '_SHOW',
    %LIST_PARAMS,
    COLS_NAME        => 1,
    COLS_UPPER       => 1
  });

  foreach my $tp ( @$tp_list ) {
    if($tp->{PREPAID} || 0
      + $tp->{WEEK_TRAF_LIMIT}
      + $tp->{DAY_TRAF_LIMIT}
      + $tp->{MONTH_TRAF_LIMIT}
      + $tp->{TOTAL_TRAF_LIMIT}
      + $tp->{DAY_TIME_LIMIT} == 0) {
      next;
    }

    if($debug > 1) {
      print "  TP_ID: $tp->{tp_id} MONTH_TRAF_LIMIT: $tp->{MONTH_TRAF_LIMIT}\n";
    }

    my $internet_list = $Internet->user_list({
      INTERNET_ACTIVATE=> '_SHOW',
      LOGIN            => '_SHOW',
      DEPOSIT          => '_SHOW',
      CREDIT           => '_SHOW',
      TP_CREDIT        => '_SHOW',
      MONTH_FEE        => '>0',
      TP_ID            => $tp->{tp_id},
      INTERNET_STATUS  => 10,
      #    DAY_TRAF_LIMIT   => '_SHOW',
      #    WEEK_TRAF_LIMIT  => '_SHOW',
      #    MONTH_TRAF_LIMIT => '_SHOW',
      #    TOTAL_TRAF_LIMIT => '_SHOW',
      COLS_NAME        => 1,
      PAGE_ROWS        => 10000000,
      %LIST_PARAMS
    });

    foreach my $u (@$internet_list) {
      my $uid = $u->{uid};
      if ($debug > 1) {
        print "UID: $uid ";
        print "LOGIN: $u->{login} ACTIVATE: $u->{internet_activate} DEPOSIT: $u->{deposit} CREDIT: $u->{credit} STATUS: $u->{internet_status} MONTH_FEE: $u->{month_fee}\n";
        #print "DAY_TRAF_LIMIT: $u->{day_traf_limit} WEEK_TRAF_LIMIT: $u->{week_traf_limit} MONTH_TRAF_LIMIT: $u->{month_traf_limit} TOTAL_TRAF_LIMIT: $u->{total_traf_limit}\n";
      }

      if($d == 1 && $u->{internet_activate} eq '0000-00-00') {
        $Internet->user_change({
          UID    => $uid,
          STATUS => 0,
          ID     => $u->{id},
        });

        print "$DATE $TIME UID: $uid unblock\n";
      }
      elsif($u->{internet_activate} ne '0000-00-00' && date_diff($u->{internet_activate}, $DATE) > 30) {
        $Internet->user_change({
          UID    => $uid,
          STATUS => 0,
          ID     => $u->{id},
        });

        print "$DATE $TIME UID: $uid unblock\n";
      }
    }
  }

  return 1;
}

#**********************************************************
=head2 internet_ureports_reset() - Reset ureports for report ;

=cut
#**********************************************************
sub internet_ureports_reset {

  $Internet->query("UPDATE ureports_users_reports users_reports, internet_main internet
SET users_reports.date='0000-00-00'
WHERE internet.uid=users_reports.uid
 AND report_id IN (3,11)
 AND internet.activate > '0000-00-00'
 AND users_reports.date > '0000-00-00'
 AND internet.activate > users_reports.date
", 'do');


  return 1;
}

1;