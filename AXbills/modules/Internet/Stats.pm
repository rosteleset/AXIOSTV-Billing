=head1 NAME

  Internet users stats

=cut

use strict;
use warnings FATAL => 'all';
use AXbills::Base qw(int2byte sec2time days_in_month);

our(
  $db,
  $admin,
  %conf,
  %lang,
  %permissions,
  @WEEKDAYS,
  @PERIODS,
  %FORM,
  %LIST_PARAMS,
  %COOKIES,
  $pages_qs,
  $users,
  $index,
  $user,
  $DATE
);

use Internet::Sessions;
use Internet;
use Nas;
our AXbills::HTML $html;
my $Internet = Internet->new($db, $admin, \%conf);
my $Sessions = Internet::Sessions->new($db, $admin, \%conf);
my $Tariffs  = Tariffs->new($db, \%conf, $admin);
my $Nas      = Nas->new($db, \%conf, $admin);

my $chart_embedded_width   = 740;
my $chart_height           = 350;


#**********************************************************
=head internet_stats($attr)

=cut
#**********************************************************
sub internet_stats {
  my ($attr) = @_;

  if($FORM{DEBUG}) {
    $Sessions->{debug}=1;
  }

  my $uid = $FORM{UID};
  if($FORM{ID}) {
    print user_service_menu({
      SERVICE_FUNC_INDEX => get_function_index('internet_user'),
      PAGES_QS           => "&ID=$FORM{ID}",
      UID                => $uid,
      MK_MAIN            => 1
    });
  }

  if ($attr->{USER_INFO}) {
    my $user = $attr->{USER_INFO};

    $uid = $user->{UID} || 0;
    $LIST_PARAMS{UID} = $uid;
    if (!defined($FORM{sort})) {
      $LIST_PARAMS{SORT} = 2;
      $LIST_PARAMS{DESC} = 'DESC';
    }

    if ($FORM{OP_SID} && $COOKIES{OP_SID} && $FORM{OP_SID} eq $COOKIES{OP_SID}) {
      $html->message('err', $lang{ERROR}, "$lang{EXIST} $FORM{OP_SID} eq $COOKIES{OP_SID}");
    }
    elsif ($FORM{bm}) {
      require Bills;
      Bills->import();

      my $Bill = Bills->new($db, $admin, \%conf);
      $Bill->action('add', "$FORM{BILL_ID}", $FORM{sum});
      if (! _error_show($Bill)) {
        $html->message('info', $lang{INFO}, "$lang{ADDED}: SUM $FORM{sum}, BILL_ID: $FORM{BILL_ID}");
      }
    }
    elsif ($FORM{SESSION_ID}) {
      $pages_qs .= "&SESSION_ID=$FORM{SESSION_ID}";
      internet_session_detail({ USER_INFO => $attr->{USER_INFO} });
      return 0;
    }
  }
  elsif ($uid) {
    $LIST_PARAMS{UID} = $uid;
  }

  if ($FORM{del} && $FORM{COMMENTS}) {
    if (!defined($permissions{3}{1})) {
      $html->message('err', $lang{ERROR}, 'ACCESS_DENY');
      return 0;
    }

    my ($session_id, $nas_id);
    ($uid, $session_id, $nas_id) = split(/ /, $FORM{del}, 7);

    my $list = $Sessions->list({
      LOGIN      => '_SHOW',
      START      => '_SHOW',
      DURATION   => '_SHOW',
      SUM        => '_SHOW',
      UID        => $uid,
      ACCT_SESSION_ID => $session_id,
      NAS_ID     => $nas_id,
      COLS_NAME  => 1
    });

    if ($Sessions->{TOTAL}) {
      my $session_info = $list->[0];
      $Sessions->del($uid, $session_id, $nas_id, $session_info->{start});

      if (! _error_show($Sessions)) {
        my $info = qq{
          $lang{LOGIN}:    $session_info->{login}
          SESSION_ID:      $session_id
          NAS_ID:          $nas_id
          $lang{START}:    $session_info->{start}
          $lang{DURATION}: $session_info->{duration}
          $lang{SUM}:      $session_info->{sum}
        };

        $html->message( 'info', $lang{DELETED}, $info);
        form_back_money( 'log', $session_info->{sum}, { UID => $uid } );    #
        return 0;
      }
    }
  }

  $Internet->user_info($uid);

  #Join Service
  if ($users->{COMPANY_ID}) {
    if ($Internet->{JOIN_SERVICE}) {
      my @uids = ();
      my $list = $Internet->user_list(
        {
          JOIN_SERVICE => ($Internet->{JOIN_SERVICE}==1) ? $Internet->{UID} : $Internet->{JOIN_SERVICE},
          COMPANY_ID   => $attr->{USER_INFO}->{COMPANY_ID},
          LOGIN        => '_SHOW',
          PAGE_ROWS    => 10000,
          COLS_NAME    => 1
        }
      );

      foreach my $line (@$list) {
        if ($Internet->{JOIN_SERVICE} && $Internet->{JOIN_SERVICE} == 1) {
          $Internet->{JOIN_SERVICES_USERS} .= $html->button("$line->{login}", "&index=$index&UID=$line->{uid}", { BUTTON => 1 }) . ' ';
        }

        push @uids, $line->{uid};
      }

      $LIST_PARAMS{UIDS} = ($Internet->{JOIN_SERVICE} > 1) ? $Internet->{JOIN_SERVICE} : $uid;
      $LIST_PARAMS{UIDS} .= ',' . join(', ', @uids) if ($#uids > -1);

      if ($Internet->{JOIN_SERVICE} > 1) {
        $Internet->{JOIN_SERVICES_USERS} .= $html->button("$lang{MAIN}", "index=$index&UID=$Internet->{JOIN_SERVICE}", { BUTTON => 1 }) . ' ';
      }

      my $table = $html->table(
        {
          width => '100%',
          rows  => [ [ "$lang{JOIN_SERVICE}:", $Internet->{JOIN_SERVICES_USERS} ] ]
        });
      $Sessions->{JOIN_SERVICE_STATS} .= $table->show();
    }
  }

  if ($FORM{rows}) {
    $LIST_PARAMS{PAGE_ROWS} = $FORM{rows};
    $LIST_PARAMS{FROM_DATE} = $FORM{FROM_DATE};
    $LIST_PARAMS{TO_DATE}   = $FORM{TO_DATE};
    $conf{list_max_recs}    = $FORM{rows};
    $pages_qs .= "&rows=$conf{list_max_recs}";
  }

  if (!$LIST_PARAMS{UID} && $FORM{LOGIN}) {
    $users = Users->new($db, $admin, \%conf);
    my $list = $users->list({
      LOGIN     => $FORM{LOGIN},
      ACTIVATE  => '_SHOW',
      COLS_NAME => 1
    });

    if ($users->{TOTAL} == 1) {
      $LIST_PARAMS{UID}      = $list->[0]->{uid};
      $FORM{UID}             = $LIST_PARAMS{UID};
      #$uid                   = $LIST_PARAMS{UID};
      $LIST_PARAMS{ACTIVATE} = $list->[0]->{activate};
    }
    else {
      $html->message('err', $lang{ERROR}, "'$FORM{LOGIN}' $lang{NOT_EXIST}");
      return 0;
    }

    $pages_qs .= "&UID=$LIST_PARAMS{UID}";
  }

  $Sessions->{PERIOD_STATS} = internet_stats_periods({ UID => $uid });
  $Sessions->{PERIOD_STATS} .= internet_period_select({ UID => $uid, ID => $FORM{ID} });

  if (defined($FORM{show})) {
    $pages_qs .= "&show=1&FROM_DATE=$FORM{FROM_DATE}&TO_DATE=$FORM{TO_DATE}";
  }
  elsif (defined($FORM{PERIOD})) {
    $LIST_PARAMS{PERIOD} = $FORM{PERIOD};
    $pages_qs .= "&PERIOD=$FORM{PERIOD}";
  }
  elsif ($FORM{DATE}) {
    $LIST_PARAMS{DATE} = $FORM{DATE};
    $pages_qs .= "&DATE=$FORM{DATE}";
  }

  my $TRAFFIC_NAMES = internet_traffic_names($Internet->{TP_ID});

  $Sessions->{PREPAID_INFO} = internet_traffic_rest({
    TRAFFIC_NAMES => $TRAFFIC_NAMES,
    UID           => $uid,
    SERVICE_ID    => $FORM{ID}
  });

  $pages_qs .= "&DIMENSION=$FORM{DIMENSION}" if ($FORM{DIMENSION});

  if (!defined($FORM{sort})) {
    $LIST_PARAMS{SORT} = 2;
    $LIST_PARAMS{DESC} = 'DESC';
  }

  $Sessions->{TOTALS_AVG} = internet_stats_calculation($Sessions);

  if($FORM{ONLINE}) {
    $LIST_PARAMS{ONLINE}=$FORM{ONLINE};
  }
  #Session List
  my $list = $Sessions->list({%LIST_PARAMS, COLS_NAME => 1 });

  if ($Sessions->{TOTAL} < 1) {
    $html->message('info', $lang{INFO}, $lang{NO_RECORD}, { ID => 981 });
  }

  my $table = $html->table({
    width       => '100%',
    title_plain => [
      $lang{SESSIONS},
      $lang{DURATION},
      (($TRAFFIC_NAMES->{0}) ? $TRAFFIC_NAMES->{0} : "$lang{TRAFFIC}") . " $lang{SENT}",
      (($TRAFFIC_NAMES->{0}) ? $TRAFFIC_NAMES->{0} : "$lang{TRAFFIC}") . " $lang{RECV}",
      (($TRAFFIC_NAMES->{0}) ? $TRAFFIC_NAMES->{0} : "$lang{TRAFFIC}") . " $lang{SUM}",
      (($TRAFFIC_NAMES->{1}) ? $TRAFFIC_NAMES->{1} : "$lang{TRAFFIC} 2") . " $lang{SENT}",
      (($TRAFFIC_NAMES->{1}) ? $TRAFFIC_NAMES->{1} : "$lang{TRAFFIC} 2") . " $lang{RECV}",
      (($TRAFFIC_NAMES->{1}) ? $TRAFFIC_NAMES->{1} : "$lang{TRAFFIC} 2") . " $lang{SUM}",
      $lang{SUM}
    ],
    rows        => [
      [
        $Sessions->{TOTAL},
        _sec2time_str($Sessions->{DURATION}),
        int2byte($Sessions->{TRAFFIC_IN}, { DIMENSION => $FORM{DIMENSION} }),
        int2byte($Sessions->{TRAFFIC_OUT}, { DIMENSION => $FORM{DIMENSION} }),
        int2byte(($Sessions->{TRAFFIC_OUT} || 0) + ($Sessions->{TRAFFIC_IN} || 0), { DIMENSION => $FORM{DIMENSION} }),
        int2byte($Sessions->{TRAFFIC2_IN}, { DIMENSION => $FORM{DIMENSION} }),
        int2byte($Sessions->{TRAFFIC2_OUT}, { DIMENSION => $FORM{DIMENSION} }),
        int2byte(($Sessions->{TRAFFIC2_OUT} || 0) + ($Sessions->{TRAFFIC2_IN} || 0), { DIMENSION => $FORM{DIMENSION} }),
        $Sessions->{SUM}
      ]
    ],
    ID          => 'TOTALS_FULL'
  });

  $Sessions->{TOTALS_FULL} = $table->show({ OUTPUT2RETURN => 1 });

  if ($Sessions->{TOTAL} > 0) {
    $Sessions->{SESSIONS} = internet_sessions($list, $Sessions, { OUTPUT2RETURN => 1 });
  }

  if (-f '../charts.cgi' || -f 'charts.cgi') {
    if($users->{UID}) {
      $Sessions->{GRAPHS} = internet_get_chart_iframe("UID=$users->{UID}", '1,2');
    }
  }

  $html->tpl_show(_include('internet_stats', 'Internet'), $Sessions);

  return 1;
}

#**********************************************************
=head2 internet_traffic_rest($attr);

  Arguments:
    TRAFFIC_NAMES
    UID
    SERVICE_ID

  Results:


=cut
#**********************************************************
sub internet_traffic_rest {
  my ($attr) = @_;

  my $TRAFFIC_NAMES;

  if( defined($TRAFFIC_NAMES)) {
    $TRAFFIC_NAMES = $attr->{TRAFFIC_NAMES};
  }
  else {
    $TRAFFIC_NAMES = internet_traffic_names($Internet->{TP_ID});
  }

  my $uid  = $attr->{UID} || $LIST_PARAMS{UIDS};
  #Show rest of prepaid traffic
  if (
    $Sessions->prepaid_rest(
      {
        UID  => ($Internet->{JOIN_SERVICE} && $Internet->{JOIN_SERVICE} > 1) ? $Internet->{JOIN_SERVICE} : $uid,
        UIDS => $uid
      }
    )
  )
  {
    #Prepaid: period, traffic_type
    my $list  = $Sessions->{INFO_LIST};
    my $table = $html->table(
      {
        caption     => $lang{PREPAID}.' : '.$lang{TRAFFIC},
        width       => '100%',
        title_plain => [ $lang{DAY}, $lang{TRAFFIC_CLASS}, $lang{BEGIN}, $lang{END}, "$lang{START} $lang{DATE}",
          "$lang{TOTAL} (MB)", "$lang{REST} (MB)", "$lang{OVERQUOTA} (MB)" ],
        ID          => 'PREAPID_TRAFIC'
      }
    );

    foreach my $line (@$list) {
      my $traffic_rest = ($conf{INTERNET_INTERVAL_PREPAID}) ? $Sessions->{REST}->{ $line->{interval_id} }->{ $line->{traffic_class} }  :  $Sessions->{REST}->{ $line->{traffic_class} };
      $table->addrow(
        ($line->{day} == 0 ) ? $lang{ALL}  : $WEEKDAYS[$line->{day}],
        $line->{traffic_class} . ':' . (($TRAFFIC_NAMES->{ $line->{traffic_class} }) ? $TRAFFIC_NAMES->{ $line->{traffic_class} } : '').
        ($conf{INTERNET_INTERVAL_PREPAID} ? "/ $line->{interval_id}" : '') ,
        $line->{interval_begin},
        $line->{interval_end},
        $line->{activate},
        $line->{prepaid},
        ($line->{prepaid} > 0 && $traffic_rest > 0) ? $traffic_rest : 0,
        ($line->{prepaid} > 0 && $traffic_rest < 0) ? $html->color_mark(abs($traffic_rest), 'text-danger') : 0,
      );
    }

    return $table->show({ OUTPUT2RETURN => 1 });
  }

  return '';
}

#**********************************************************
=head2 internet_stats_calculation($sessions);

=cut
#**********************************************************
sub internet_stats_calculation {
  my Internet::Sessions $Sessions_ = shift;

  $Sessions_->calculation({%LIST_PARAMS});
  my $table = $html->table(
    {
      title_plain => [ "-", $lang{MIN}, $lang{MAX}, $lang{AVG}, $lang{TOTAL} ],
      rows        => [
        [ $lang{DURATION},         _sec2time_str($Sessions_->{MIN_DUR}),  _sec2time_str($Sessions_->{MAX_DUR}), _sec2time_str($Sessions_->{AVG_DUR}), _sec2time_str($Sessions_->{TOTAL_DUR}) ],
        [ "$lang{TRAFFIC} $lang{SENT}", int2byte($Sessions_->{MIN_SENT}), int2byte($Sessions_->{MAX_SENT}), int2byte($Sessions_->{AVG_SENT}), int2byte($Sessions_->{TOTAL_SENT}) ],
        [ "$lang{TRAFFIC} $lang{RECV}", int2byte($Sessions_->{MIN_RECV}), int2byte($Sessions_->{MAX_RECV}), int2byte($Sessions_->{AVG_RECV}), int2byte($Sessions_->{TOTAL_RECV}) ],
        [ "$lang{TRAFFIC} $lang{SUM}",  int2byte($Sessions_->{MIN_SUM}),  int2byte($Sessions_->{MAX_SUM}),  int2byte($Sessions_->{AVG_SUM}),  int2byte($Sessions_->{TOTAL_SUM}) ]
      ],
      ID => 'INTERNET_TRAFFIC_CALCULATIONS'
    }
  );

  return $table->show();
}

#**********************************************************
=head2 internet_session_detail($attr)

=cut
#**********************************************************
sub internet_session_detail {
  my ($attr) = @_;
  my $user;

  my $uid= $FORM{UID} || 0;
  if (defined($attr->{USER_INFO})) {
    $user = $attr->{USER_INFO};
    $LIST_PARAMS{LOGIN} = $user->{LOGIN};

    if ($FORM{RECALC}) {
      $Sessions->session_detail({%FORM});

      require Billing;
      Billing->import();
      my $Billing = Billing->new($db, \%conf);

      my (undef, $SUM, undef, $TARIF_PLAN) = $Billing->session_sum(
        $Sessions->{LOGIN},
        $Sessions->{START_UNIXTIME},
        $Sessions->{DURATION},
        {
          OUTBYTE  => $Sessions->{SENT},
          INBYTE   => $Sessions->{RECV},
          OUTBYTE2 => $Sessions->{SENT2},
          INBYTE2  => $Sessions->{RECV2}
        },
        {
          disable_rt_billing => 1,
          TP_NUM             => $Sessions->{TP_ID}
        }
      );

      my $change = '';

      if ($Sessions->{SUM} != $SUM) {
        $change = "$lang{CHANGE}  " . $html->button($lang{YES}, "index=$index&RECALC=1&SESSION_ID=$FORM{SESSION_ID}&UID=$user->{UID}&change=1", { BUTTON => 1 }) . ' ?';

        if ($FORM{change}) {
          require Bills;
          Bills->import();
          my $Bill = Bills->new($db, $admin, \%conf);
          $Bill->action('add',  "$Sessions->{BILL_ID}", $Sessions->{SUM}) if ($Sessions->{SUM});
          $Bill->action('take', "$Sessions->{BILL_ID}", $SUM)             if ($SUM > 0);

          $Sessions->query("UPDATE internet_log SET sum='$SUM' WHERE acct_session_id='$Sessions->{SESSION_ID}';", 'do');

          if (! _error_show($Bill)) {
            $html->message('info', $lang{INFO}, "$lang{ADDED}: SUM $FORM{sum}, BILL_ID: $FORM{BILL_ID}");
          }
          $change = $lang{CHANGED};
        }
      }

      $html->message('info', "$lang{RECALCULATE}", "$lang{TARIF_PLAN}: $TARIF_PLAN, $lang{SUM}: $Sessions->{SUM} -> $SUM  $change");
    }
  }
  elsif (defined($LIST_PARAMS{LOGIN})) {

  }
  elsif ($FORM{UID}) {
    internet_user();
    return 0;
  }

  my $ACCT_TERMINATE_CAUSES = internet_terminate_causes({ REVERSE => 1 });
  $Sessions->session_detail({%FORM});
  if(_error_show($Sessions, { MESSAGE => "$lang{SESSIONS}: $FORM{SESSION_ID}" })) {
    return 0;
  }
  $Sessions->{ACCT_TERMINATE_CAUSE} = ($Sessions->{ACCT_TERMINATE_CAUSE}) ? "$Sessions->{ACCT_TERMINATE_CAUSE} : " . $ACCT_TERMINATE_CAUSES->{ $Sessions->{ACCT_TERMINATE_CAUSE} } : q{};

  $Sessions->{_SENT}  = int2byte($Sessions->{SENT});
  $Sessions->{_RECV}  = int2byte($Sessions->{RECV});
  $Sessions->{_RECV2} = int2byte($Sessions->{RECV2});
  $Sessions->{_SENT2} = int2byte($Sessions->{SENT2});
  $Sessions->{RECALC} = $html->button($lang{RECALCULATE}, "index=$index&RECALC=1&SESSION_ID=$FORM{SESSION_ID}&UID=$uid", { BUTTON => 1 });
  $Sessions->{SUM}    = sprintf("%.6f", $Sessions->{SUM});

  $Internet->user_info($uid);
  my $TRAFFIC_NAMES = internet_traffic_names($Sessions->{TP_ID});

  if ($Tariffs->{TOTAL} && $Tariffs->{TOTAL} > 0) {
    my $list = $Tariffs->tt_list({ TI_ID => $Tariffs->{list}->[0]->[0], COLS_NAME => 1 });
    foreach my $line ( @$list ) {
      $TRAFFIC_NAMES->{ $line->{id} } = $line->{descr};
    }
  }

  $html->tpl_show(
    _include('internet_session_detail', 'Internet'),
    {
      %$Sessions,
      TRAFFIC_NAMES_0 => $TRAFFIC_NAMES->{0},
      TRAFFIC_NAMES_1 => $TRAFFIC_NAMES->{1}
    }
  );

  my %ORDERS = (
    hours    => $lang{HOURS},
    days     => $lang{DAYS},
    sessions => $lang{SESSIONS}
  );

  print $html->form_main(
    {
      CONTENT => $html->form_select(
        'PERIOD',
        {
          SELECTED => $FORM{PERIOD},
          SEL_HASH => \%ORDERS,
          NO_ID    => 1
        }
      )
        . "SESSION_ID:"
        . $html->form_select(
        'SESSION_ID',
        {
          SELECTED    => $FORM{SESSION_ID},
          SEL_OPTIONS => {
            $FORM{SESSION_ID} => $FORM{SESSION_ID},
            '0'               => $lang{ALL}
          },
          NO_ID => 1
        }
      ),
      HIDDEN => {
        index => $index,
        UID   => $user->{UID}
      },
      SUBMIT => { SHOW => $lang{SHOW} }
    }
  );

  $pages_qs .= "&PERIOD=$FORM{PERIOD}" if (defined($FORM{PERIOD}));

  #Log intervals
  my $list = $Sessions->list_log_intervals({
    ACCT_SESSION_ID => $FORM{SESSION_ID},
    UID             => $user->{UID},
    COLS_NAME       => 1
  });

  if ($Sessions->{TOTAL} > 0) {
    my $table = $html->table(
      {
        width      => '100%',
        caption    => $lang{INTERVALS},
        title      => [ $lang{INTERVALS}, $lang{TRAFFIC}, $lang{SENT}, $lang{RECV}, $lang{DURATION}, $lang{SUM} ],
        qs         => $pages_qs,
        ID         => 'INTERNET_SESSION_DETAIL'
      }
    );

    foreach my $line (@$list) {
      $table->addrow(
        $line->{interval_id},
        $line->{traffic_type},
        int2byte($line->{sent}),
        int2byte($line->{recv}),
        sec2time($line->{duration}, { str => 1 }),
        sprintf("%.2f", $line->{sum})
      );
    }

    print $table->show();
  }

  #Log detail list
  if (!$FORM{sort}) {
    $LIST_PARAMS{SORT} = 1;
    $LIST_PARAMS{DESC} = 'DESC';
  }

  $list = $Sessions->detail_list({ %LIST_PARAMS, %FORM });
  my $table = $html->table(
    {
      width      => '100%',
      title      => [ "LAST_UPDATE", $lang{SESSION_ID}, "NAS ID", $lang{RECV}, $lang{SENT}, "$lang{SENT} 2", "$lang{RECV} 2", $lang{SUM} ],
      pages      => $Sessions->{TOTAL},
      qs         => $pages_qs,
      ID         => 'DETAIL_LIST'
    }
  );

  foreach my $line (@$list) {
    $table->addrow($line->[0], $html->button($line->[1], "index=$index&UID=$uid&SESSION_ID=$line->[1]"),
      $line->[2],
      int2byte($line->[3]),
      int2byte($line->[4]),
      int2byte($line->[5]),
      int2byte($line->[6]),
      $line->[7]);
  }

  print $table->show();

  $table = $html->table(
    {
      width => '100%',
      rows  => [ [ "$lang{TOTAL}:", $html->b($Sessions->{TOTAL}) ] ],
      ID    => 'DETAIL_LIST_TOTAL'
    }
  );

  print $table->show();

  return 1;
}

#**********************************************************
=head2 internet_stats_periods() - Summary stats

=cut
#**********************************************************
sub internet_stats_periods {

  $Sessions->periods_totals({ %LIST_PARAMS });
  my $table = $html->table({
    caption     => $lang{PERIOD},
    width       => '100%',
    title_plain => [ $lang{PERIOD}, $lang{DURATION}, $lang{RECV}, $lang{SEND}, $lang{SUM} ],
    ID          => 'INTERNET_STATS_PERIOD'
  });

  for (my $i = 0 ; $i < 5 ; $i++) {
    $table->addrow(
      $html->button($PERIODS[$i], "index=$index&PERIOD=$i$pages_qs"),
      _sec2time_str($Sessions->{ 'duration_' . $i }),
      int2byte($Sessions->{ 'recv_' . $i }),
      int2byte($Sessions->{ 'sent_' . $i }),
      int2byte($Sessions->{ 'sum_' . $i })
    );
  }

  return $table->show({ OUTPUT2RETURN => 1 });
}

#**********************************************************
=head2 internet_sessions($list, $sessions, $attr) - Whow sessions from log

  Arguments:
    $list      - SEssions list
    $sessions  - Sessins obj
    $attr
      INTERNET_UP_SESSIONS


=cut
#**********************************************************
sub internet_sessions {
  my ($list, $sessions, $attr) = @_;

  my $TRAFFIC_NAMES = internet_traffic_names($Internet->{TP_ID});
  my $ACCT_TERMINATE_CAUSES = internet_terminate_causes({ REVERSE => 1 });

  if (! $sessions) {
    $sessions = Internet::Sessions->new($db, $admin, \%conf);
  }

  if (! $list || ref $list eq 'HASH') {
    $sessions->{SEL_NAS} = $html->form_select('NAS_ID', {
      SELECTED       => $FORM{NAS_ID},
      SEL_LIST       => $Nas->list({ %LIST_PARAMS, COLS_NAME => 1 }),
      SEL_KEY        => 'nas_id',
      SEL_VALUE      => 'nas_name',
      MAIN_MENU      => get_function_index('form_nas'),
      MAIN_MENU_ARGV => ($FORM{NAS_ID}) ? "NAS_ID=$FORM{NAS_ID}" : undef,
      SEL_OPTIONS    => { '' => $lang{ALL} },
    });

    $sessions->{TERMINATE_CAUSE_SEL} = $html->form_select('TERMINATE_CAUSE', {
      SELECTED    => $FORM{TERMINATE_CAUSE} || '',
      SEL_HASH    => $ACCT_TERMINATE_CAUSES,
      SEL_OPTIONS => { '' => '--' }
    });

    if(! $FORM{UID}) {
      form_search({ SEARCH_FORM => $html->tpl_show(_include('internet_sessions_search', 'Internet'),
          { %FORM, %$sessions },
          { OUTPUT2RETURN => 1 }),
        ADDRESS_FORM            => 1,
        SHOW_PERIOD             => 1,
      });
    }
    else {
      form_search({ TPL => ' ' }); #we don't need search form if (! FORM{UID}), but call of form_search is needed to set $pages_qs so sorting and pagination will work correctly
    }

    if ($FORM{search}) {
      $sessions = Internet::Sessions->new($db, $admin, \%conf);
    }
    else {
      return 0;
    }
  }

  if (! $FORM{sort}) {
    $LIST_PARAMS{SORT} = 'l.start';
    $LIST_PARAMS{DESC} = 'desc';
  }

  if($user->{UID}) {
    delete $LIST_PARAMS{LOGIN};
  }

  map { $FORM{$_} ? $LIST_PARAMS{$_} = $FORM{$_} : () } keys %FORM;

  $LIST_PARAMS{SKIP_DEL_CHECK} = 1;

  my $default_fields = q{DATE,DURATION_SEC,SENT,RECV,TP_NAME,IP,CID,SUM,NAS_ID};

  if($attr->{INTERNET_UP_SESSIONS}) {
    $default_fields = $attr->{INTERNET_UP_SESSIONS};
  }
  elsif ($user->{UID}) {
    $default_fields = 'DATE,DURATION_SEC,SENT,RECV,TP_NAME,IP,SUM';
  }
  else {
    if(! $FORM{UID}) {
      $default_fields = 'LOGIN,'. $default_fields;
    }
  }

  my AXbills::HTML $table;
  ($table, $list) = result_former({
    INPUT_DATA      => $sessions,
    FUNCTION        => 'list',
    BASE_FIELDS     => 0,
    DEFAULT_FIELDS  => $default_fields,
    FUNCTION_FIELDS => ($user->{UID}) ? undef : 'internet_stats, del',
    EXT_TITLES      => {
      'ip'                 => 'IP',
      'netmask'            => 'NETMASK',
      'framed_ipv6_prefix' => 'FRAMED_IPV6_PREFIX',
      'duration_sec'       => $lang{DURATION},
      'speed'              => $lang{SPEED},
      'port_id'            => $lang{PORT},
      'cid'                => 'CID',
      'filter_id'          => 'Filter ID',
      'tp_id'              => $lang{TARIF_PLAN} . ' (Inner ID)',
      'tp_num'             => $lang{TARIF_PLAN} . ' (ID)',
      'tp_name'            => $lang{TARIF_PLAN},
      'internet_status'    => "Internet $lang{STATUS}",
      'terminate_cause'    => $lang{ACCT_TERMINATE_CAUSE},
      'start'              => "$lang{START} $lang{SESSIONS}",
      'end'                => "$lang{END} $lang{SESSIONS}",
      'duration'           => $lang{DURATION},
      'sent'               => (($TRAFFIC_NAMES->{0}) ? $TRAFFIC_NAMES->{0} : '') . " $lang{SENT}",
      'recv'               => (($TRAFFIC_NAMES->{0}) ? $TRAFFIC_NAMES->{0} : '') . " $lang{RECV}",
      'sum'                => $lang{SUM},
      'nas_id'             => $lang{NAS},
      'nas_name'           => "$lang{NAME} $lang{NAS}",
      'acct_session_id'    => 'Acct-Session-Id',
      'guest'              => $lang{GUEST}
    },
    FILTER_COLS  => {
      duration_sec    => '_sec2time_str',
      sent            => 'int2byte',
      recv            => 'int2byte',
      terminate_cause => 'internet_terminate_causes',
    },
    TABLE           => {
      width        => '100%',
      caption      => ($user->{UID}) ? undef : "$lang{SESSIONS}",
      qs           => $pages_qs,
      recs_on_page => $LIST_PARAMS{PAGE_ROWS},
      ID           => (($user->{UID}) ? 'INTERNET_UP_SESSIONS' : 'INTERNET_SESSIONS'),
      EXPORT       => 1,
    },
  });

  delete $LIST_PARAMS{SORT};

  if ($sessions->{TOTAL} < 1) {
    $html->message('info', $lang{INFO}, $lang{NO_RECORD});
    return 0;
  }

  foreach my $line (@$list) {
    my $delete = ($permissions{3} && $permissions{3}{1}) ? $html->button(
        $lang{DEL},
        "index=". get_function_index('internet_stats') ."$pages_qs&del=$line->{uid}+$line->{acct_session_id}+". ($line->{nas_id} || q{}). ((! $FORM{UID}) ? "&UID=$line->{uid}" : ''),
        {
          MESSAGE => "$lang{DEL} $lang{SESSIONS} $lang{SESSION_ID} " . ($line->{acct_session_id}) . "?",
          class => 'del',
          NO_LINK_FORMER => 1
        }
    ) : '';

    my @fields_array = ();
    for (my $i = 0; $i < $sessions->{SEARCH_FIELDS_COUNT}; $i++) {
      my $field_name = $sessions->{COL_NAMES_ARR}->[$i];
      if ($field_name =~ /sent|recv/) {
        $line->{$field_name} = int2byte($line->{$field_name}, { DIMENSION => $FORM{DIMENSION} });
      }
      elsif ($field_name eq 'login' && $line->{uid}) {
        $line->{login} = $html->button($line->{login}, "index=11&UID=$line->{uid}");
      }
      elsif ($field_name eq 'terminate_cause') {
        $line->{terminate_cause} = $ACCT_TERMINATE_CAUSES->{ $line->{terminate_cause} };
      }
      elsif ($field_name eq 'duration_sec') {
        $line->{duration_sec} = _sec2time_str($line->{duration_sec});
      }
      elsif($field_name eq 'sum') {
        $line->{sum} = sprintf("%.6f", $line->{sum});
      }

      push @fields_array, $line->{$field_name};
    }

    if(! $user->{UID}) {
      push @fields_array, $html->button("D",
          "index=".get_function_index(($user->{UID}) ? 'internet_user_stats' : 'internet_stats')."&UID=$line->{uid}"."&SESSION_ID=$line->{acct_session_id}"
          , { TITLE => "$lang{DETAIL}", class => 'stats' }).' '.$delete
    }

    $table->addrow(
      @fields_array
    );
  }

  if (! $FORM{EXPORT_CONTENT} && $attr->{OUTPUT2RETURN}) {
    return $table->show({ OUTPUT2RETURN => 1 });
  }

  print $table->show();
  return 1;
}

#**********************************************************
=head2 internet_terminate_causes() - Session terminate cause

  Arguments:
    $attr
      REVERSE - Show reverse hash id => name

  Returns:
    Hash_refs

=cut
#**********************************************************
sub internet_terminate_causes {
  my ($attr) = @_;

  my %ACCT_TERMINATE_CAUSES = (
    'Unknown'                      => 0,
    'User-Request'                 => 1,
    'Lost-Carrier'                 => 2,
    'Lost-Service'                 => 3,
    'Idle-Timeout'                 => 4,
    'Session-Timeout'              => 5,
    'Admin-Reset'                  => 6,
    'Admin-Reboot'                 => 7,
    'Port-Error'                   => 8,
    'NAS-Error'                    => 9,
    'NAS-Request'                  => 10,
    'NAS-Reboot'                   => 11,
    'Port-Unneeded'                => 12,
    'Port-Preempted'               => 13,
    'Port-Suspended'               => 14,
    'Service-Unavailable'          => 15,
    'Callback'                     => 16,
    'User-Error'                   => 17,
    'Host-Request'                 => 18,
    'Supplicant-Restart'           => 19,
    'Reauthentication-Failure'     => 20,
    'Port-Reinit'                  => 21,
    'Port-Disabled'                => 22,
    'Lost-Alive/Billd Calculation' => 23
  );

  if (ref $attr eq 'SCALAR') {
    return $ACCT_TERMINATE_CAUSES{$attr};
  }

  return ($attr->{REVERSE}) ? { reverse %ACCT_TERMINATE_CAUSES } : \%ACCT_TERMINATE_CAUSES;
}

#**********************************************************
=head2 internet_get_chart_iframe()  - make an iframe with a chart

=cut
#**********************************************************
sub internet_get_chart_iframe {
  my ($query, $periods) = @_;

  my $frameopts = "width='100%' height='" . $chart_height * 1.4 . "px' frameborder='0' seamless='seamless' scrolling='false'";
  my $chart_query  = internet_get_chart_query($query, $periods);

  if ($FORM{xml}){return 1};

  return "<iframe src='$chart_query' $frameopts></iframe>"
}

#**********************************************************
=head2 internet_get_chart_query() - form query to charts.cgi from given params

=cut
#**********************************************************
sub internet_get_chart_query {
  my ($query, $periods, $width, $height) = @_;

  my $chart_dimensions ='';
  $chart_dimensions.= ($height) ? "&height=$height" : "&height=$chart_height";
  $chart_dimensions.= "px";
  $chart_dimensions.= ($width) ? "&width=$width" : "&width=$chart_embedded_width";
  $chart_dimensions.= "px";

  return "/charts.cgi?$query&periods=$periods&SHOW_GRAPH=1$chart_dimensions";
}

#**********************************************************
=head2 internet_user_add($attr)

  Arguments:
    $Internet_
    $users_
    $attr
      NO_PAYMENT_BTN

=cut
#**********************************************************
sub internet_payment_message {
  my ($Internet_, $users_, $attr) = @_;

  my $total_fee = ($Internet_->{MONTH_ABON} || 0) + ($Internet_->{DAY_ABON} || 0);

  if ($users_->{REDUCTION}) {
    $total_fee = $total_fee * (100 - $users_->{REDUCTION}) / 100;
  }

  my $uid = $users_->{UID} || 0;

  if ($Internet_->{STATUS} && $total_fee > $users_->{DEPOSIT}) {
    my $sum = 0;
    if ($Internet_->{ABON_DISTRIBUTION} && !$conf{INTERNET_FULL_MONTH}) {
      my $days_in_month = days_in_month({ DATE => $DATE });
      my $month_fee = ($total_fee / $days_in_month); # * ($days_in_month - $d);
      if ($month_fee > $users_->{DEPOSIT}) {
        my $full_sum = abs($month_fee - $users_->{DEPOSIT});
        $sum = sprintf("%.2f", $full_sum);
        if ($sum - $full_sum < 0) {
          $sum = sprintf("%.2f", int($sum + 1));
        }
      }
    }
    else {
      $sum = sprintf("%.2f", abs($total_fee - $users_->{DEPOSIT}));
      if ($sum < abs($total_fee - $users_->{DEPOSIT})) {
        $sum = sprintf("%.2f", int($sum + 1));
      }
    }

    if ($sum > 0) {
      $Internet_->{PAYMENT_MESSAGE} = $html->message('warn', '',
        "$lang{ACTIVATION_PAYMENT} $sum " . ((! $attr->{NO_PAYMENT_BTN}) ? $html->button($lang{PAYMENTS},
          "UID=$uid&index=2&SUM=$sum", { class => 'payments' }) : ''), { OUTPUT2RETURN => 1 });

      $Internet_->{HAS_PAYMENT_MESSAGE} = 1;
    }
  }
}


1;
