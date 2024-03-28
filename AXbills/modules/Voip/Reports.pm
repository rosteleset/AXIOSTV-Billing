use strict;
use warnings FATAL => 'all';

use AXbills::Base;
use Voip::Constants qw/ACCT_TERMINATE_CAUSES/;

our (
  %lang,
  $admin,
  $db,
  %conf,
  @MONTHES,
  @WEEKDAYS,
  %permissions
);

our AXbills::HTML $html;
our Voip $Voip;
my $Log = Log->new($db, \%conf);
my $Sessions = Voip_Sessions->new($db, $admin, \%conf);
my $Nas = Nas->new($db, \%conf, $admin);

#**********************************************************
=head2 voip_error($attr) - show errors

=cut
#**********************************************************
sub voip_error {
  my ($attr) = @_;
  my $login = '';

  my %log_levels_rev = reverse %Log::log_levels;
  my @ACTIONS = ('', 'AUTH', 'ACCT', 'HANGUP', 'CALCULATION', 'CMD');

  if ($attr->{USER_INFO}) {
    $Voip->user_info($attr->{USER_INFO}->{UID});
    $login = $Voip->{NUMBER};
    $LIST_PARAMS{LOGIN} = $Voip->{NUMBER};
  }
  elsif ($FORM{LOGIN_EXPR}) {
    $login = $FORM{LOGIN_EXPR};
    $LIST_PARAMS{LOGIN} = $FORM{LOGIN_EXPR};
    $pages_qs .= "&LOGIN_EXPR=$FORM{LOGIN_EXPR}";
  }
  elsif ($FORM{UID}) {
    voip_user();
    return 0;
  }

  my %nas_ids = (
    '' => '',
    0  => 'UNKNOWN',
  );

  my $list = $Nas->list({
    NAS_TYPE  => 'asterisk,gnugk,cisco_voip,eltex_smg',
    PAGE_ROWS => 50000,
    COLS_NAME => 1
  });

  foreach my $line (@{$list}) {
    $nas_ids{ $line->{nas_id} } = $line->{nas_name};
  }

  $Voip->{LOG_TYPE_SEL} = $html->form_select('LOG_TYPE', {
    SELECTED => $FORM{LOG_TYPE},
    SEL_HASH => { '' => '', %log_levels_rev },
    NO_ID    => 1
  });

  $Voip->{NAS_ID_SEL} = $html->form_select('NAS_ID', {
    SELECTED => $FORM{NAS_ID},
    SEL_HASH => \%nas_ids,
    NO_ID    => 1
  });

  $Voip->{ACTIONS_SEL} = $html->form_select('ACTION', {
    SELECTED  => $FORM{ACTION},
    SEL_ARRAY => \@ACTIONS,
  });

  if ($FORM{search_form}) {
    form_search({
      SEARCH_FORM => $html->tpl_show(
        _include('voip_errors_search', 'Voip'),
        { %FORM, %{$Voip} },
        { OUTPUT2RETURN => 1 }),
      SHOW_PERIOD => 1
    });
  }

  if (!$FORM{sort}) {
    $LIST_PARAMS{SORT} = 1;
    $LIST_PARAMS{DESC} = 'DESC';
  }

  if ($FORM{search} && $FORM{FROM_DATE}) {
    $LIST_PARAMS{INTERVAL} = "$FORM{FROM_DATE}/$FORM{TO_DATE}";
  }

  $LIST_PARAMS{NAS_ID} = join(';', keys %nas_ids);

  $list = $Log->log_list({ %LIST_PARAMS, COLS_NAME => 1 });

  my $all_count = $html->table({
    width => '100%',
  });

  my $total = 0;
  foreach my $line (@{$Log->{list}}) {
    $all_count->addrow($log_levels_rev{ $line->{log_type} }, $line->{count});
    $total += $line->{count};
  }

  $all_count->addrow($html->b("$lang{TOTAL}:"), $html->b($total));

  my $table = $html->table({
    caption => "VoIP $lang{ERROR}",
    width   => '100%',
    title   => [ $lang{DATE}, $lang{TYPE}, $lang{ACTION}, $lang{USER}, $lang{TEXT}, "NAS" ],
    pages   => $total,
    qs      => $pages_qs,
    ID      => 'VOIP_ERRORS',
    EXPORT  => ' XML:&xml=1',
    MENU    => "$lang{SEARCH}:index=$index&search_form=1:search",
  });

  foreach my $line (@{$list}) {
    my $message = $line->{message};

    if ($line->{log_type} < 5) {
      $message = $html->color_mark($line->{message}, "$_COLORS[6]");
    }
    elsif ($line->{action} eq 'GUEST_MODE') {
      $message = $html->color_mark($line->{message}, "$_COLORS[8]");
      $line->{action} = $html->color_mark($line->{action}, "$_COLORS[8]");
    }

    $table->addrow($line->{date}, $log_levels_rev{ $line->{log_type} }, $line->{action},
      $html->button($line->{user},
        "index=" . (get_function_index('voip_users_list')) . "&NUMBER=$line->{user}&search=1&search_form=1"),
      $message, $nas_ids{ $line->{nas_id} });
  }

  print $table->show();
  print $all_count->show();

  return 1;
}

#**********************************************************
=head2 voip_sessions() - Show sessions from log

=cut
#**********************************************************
sub voip_sessions {
  my ($list) = @_;

  if (!defined($FORM{sort})) {
    if (!$FORM{UID}) {
      $LIST_PARAMS{SORT} = 2;
    }
    else {
      $LIST_PARAMS{SORT} = 1;
    }
    $LIST_PARAMS{DESC} = 'DESC';
  }

  #Session List
  if (!$list) {
    $Sessions->{SEL_NAS} = $html->form_select('NAS_ID', {
      SELECTED       => $FORM{NAS_ID},
      SEL_LIST       => $Nas->list({ %LIST_PARAMS, COLS_NAME => 1, PAGE_ROWS => 10000 }),
      SEL_KEY        => 'nas_id',
      SEL_VALUE      => 'nas_name',
      MAIN_MENU      => get_function_index('form_nas'),
      MAIN_MENU_ARGV => "NAS_ID=$FORM{NAS_ID}",
      SEL_OPTIONS    => { '' => $lang{ALL} },
    });

    form_search({ SEARCH_FORM => $html->tpl_show(_include('voip_sessions_search', 'Voip'), { %FORM, %{$Sessions} },
      { OUTPUT2RETURN => 1 }) });
  }

  if ($FORM{del} && $FORM{COMMENTS}) {
    if (!defined($permissions{3}{1})) {
      $html->message('err', $lang{ERROR}, 'ACCESS DENY');
      return 0;
    }

    my ($uid, $session_id, $nas_id, $session_start_date, $session_start_time, $sum, $login) = split(/ /, $FORM{del},
      7);

    $Sessions->del($uid, $session_id, $nas_id, "$session_start_date $session_start_time");
    if (!$Sessions->{errno}) {
      $html->message('info', $lang{DELETED},
        "$lang{LOGIN}: " . ($login || q{}) . "\n"
          . "SESSION_ID: $session_id\n"
          . "NAS_ID: $nas_id\n"
          . "SESSION_START: $session_start_date $session_start_time\n"
          . "$lang{SUM}: $sum");

      form_back_money('log', $sum, { UID => $uid });

      return 0;
    }
  }

  _error_show($Sessions);

  my AXbills::HTML $table;
  if ($FORM{FROM_DATE} && $FORM{TO_DATE}) {
    $LIST_PARAMS{INTERVAL} = "$FORM{FROM_DATE}/$FORM{TO_DATE}";
  }
  ($table, $list) = result_former({
    INPUT_DATA      => $Sessions,
    FUNCTION        => 'list',
    DEFAULT_FIELDS  =>
      (($user->{UID}) ? 'DATE,DURATION,CALLING_STATION_ID,CALLED_STATION_ID,TP_ID,IP,CID,SUM' :
        (((!$FORM{UID}) ? 'LOGIN,' : '') . 'DATE,DURATION,CALLING_STATION_ID,CALLED_STATION_ID,TP_ID,IP,SUM,NAS_ID'))
      ,
    FUNCTION_FIELDS => 'detail,del',
    EXT_TITLES      => {
      ip                 => 'IP',
      port_id            => $lang{PORT},
      filter_id          => 'Filter ID',
      tp_id              => $lang{TARIF_PLAN},
      service_status     => $lang{STATUS},
      terminate_cause    => 'TC',
      start              => $lang{START},
      duration           => $lang{DURATION},
      sum                => $lang{SUM},
      nas_id             => $lang{NAS},
      calling_station_id => $lang{CALLING_STATION_ID},
      called_station_id  => $lang{CALLED_STATION_ID}
    },
    TABLE           => {
      width        => '100%',
      caption      => $lang{SESSIONS},
      qs           => $pages_qs,
      recs_on_page => $LIST_PARAMS{PAGE_ROWS},
      ID           => 'VOIP_SESSIONS',
      EXPORT       => 1,
    },
  });

  if ($Sessions->{TOTAL} < 1) {
    $html->message('info', $lang{INFO}, $lang{NO_RECORD});
    return 0;
  }

  foreach my $line (@{$list}) {
    my $delete = ($permissions{3} && $permissions{3}{1})
      ? $html->button($lang{DEL}, 'index'
      . get_function_index('voip_stats') . "$pages_qs&del=$line->{uid}+$line->{acct_session_id}+$line->{nas_id}+$line->{start}+$line->{sum}",
      {
        MESSAGE        => "$lang{DEL} $lang{SESSIONS}: " . ($line->{acct_session_id} || q{}) . "?",
        class          => 'del',
        NO_LINK_FORMER => 1
      }
    ) : '';

    my @fields_array = ();
    for (my $i = 0; $i < $Sessions->{SEARCH_FIELDS_COUNT}; $i++) {
      if ($Sessions->{COL_NAMES_ARR}->[$i] eq 'login' && $line->{uid}) {
        $line->{login} = $html->button($line->{login}, "index=11&UID=$line->{uid}");
      }
      elsif ($Sessions->{COL_NAMES_ARR}->[$i] eq 'terminate_cause') {
        $line->{terminate_cause} = ACCT_TERMINATE_CAUSES->{ $line->{terminate_cause} };
      }
      push @fields_array, $line->{ $Sessions->{COL_NAMES_ARR}->[$i] };
    }

    $table->addrow(@fields_array, $html->button("D",
      "index=" . get_function_index(($user->{UID}) ? 'voip_user_stats' : 'voip_stats') . "&UID=$line->{uid}" . "&SESSION_ID=$line->{acct_session_id}"
      , { TITLE => "$lang{DETAIL}", class => 'stats' }) . ' ' . $delete);
  }

  print $table->show();

  return 1;
}

#**********************************************************
=head2 voip_use();

=cut
#**********************************************************
sub voip_use {

  require Control::Reports;
  reports({
    DATE        => $FORM{DATE},
    REPORT      => '',
    EX_PARAMS   => {
      DATE   => $lang{DATE},
      USERS  => $lang{USERS},
      ADMINS => $lang{ADMINS},
    },
    PERIOD_FORM => 1,
  });

  my ($table_sessions);
  my $type = $FORM{type} || 'DATE';

  if ($FORM{DATE}) {
    $table_sessions = $html->table({
      width   => '100%',
      caption => $lang{SESSIONS},
      title   => [ $lang{DATE}, $lang{USERS}, $lang{SESSIONS}, $lang{DURATION}, $lang{SUM} ],
      qs      => $pages_qs,
      ID      => 'VOIP_SESSIONS'
    });

    my $list = $Sessions->reports({ %LIST_PARAMS });
    foreach my $line (@{$list}) {
      $table_sessions->addrow($html->b($line->[0]),
        $html->button($line->[1], "index=11&subf=22&UID=$line->[5]&DATE=$line->[0]&TYPE=USERS"),
        $line->[2],
        $line->[3],
        $html->b($line->[4])
      );
    }
  }
  else {
    $table_sessions = $html->table({
      width   => '100%',
      caption => $lang{SESSIONS},
      title   => [ $lang{DATE}, $lang{USERS}, $lang{SESSIONS}, $lang{DURATION}, $lang{SUM} ],
      qs      => $pages_qs,
      ID      => 'VOIP_SESSIONS'
    });

    my $list = $Sessions->reports({ %LIST_PARAMS });

    if (_error_show($Voip)) {
      return 0;
    }
    $type='DATE';
    foreach my $line (@{$list}) {
      $table_sessions->addrow($html->button($line->[0], "index=$index&$type=$line->[0]$pages_qs"),
        $line->[1],
        $line->[2],
        $line->[3],
        $html->b($line->[4]));
    }
  }

  my $table = $html->table({
    width   => '100%',
    caption => $lang{SESSIONS},
    rows    =>
      [ [ "$lang{USERS}: " . $html->b($Sessions->{USERS}), "$lang{SESSIONS}: " . $html->b($Sessions->{SESSIONS}),
        "$lang{DURATION}: " . $html->b($Sessions->{DURATION}), "$lang{SUM}: " . $html->b($Sessions->{SUM}) ] ],
  });

  print $table_sessions->show() . $table->show();

  return 1;
}

1;
