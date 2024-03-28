=head2 NAME

  Voip User portal

=cut

use warnings;
use strict;

our (
  $db,
  $admin,
  %conf,
  %lang,
  @WEEKDAYS,
  @MONTHES,
  @PERIODS,
  @status
);

our AXbills::HTML $html;

my $Voip = Voip->new($db, $admin, \%conf);
my $Sessions = Voip_Sessions->new($db, $admin, \%conf);

require Shedule;
Shedule->import();
my $Shedule  = Shedule->new($db, $admin, \%conf);

require Tariffs;
Tariffs->import();
my $Tariffs  = Tariffs->new($db, \%conf, $admin);

require Control::Service_control;
Control::Service_control->import();
my $Service_control = Control::Service_control->new($db, $admin, \%conf, { HTML => $html, LANG => \%lang });

#**********************************************************
=head2 voip_user_info();

=cut
#**********************************************************
sub voip_user_info {

  my $user = $Voip->user_info($user->{UID});

  if ($user->{TOTAL} < 1) {
    $html->message('info', $lang{INFO}, $lang{NOT_ACTIVE});
    return 0;
  }

  # Check for sheduled tp change
  my $sheduled_tp_actions_list = $Shedule->list({
    SERVICE_ID => $user->{ID},
    UID        => $user->{UID},
    TYPE       => 'tp',
    MODULE     => 'Voip',
    COLS_NAME  => 1
  });

  if ($Shedule->{TOTAL} && $Shedule->{TOTAL} > 0){
    my $next_tp_action = $sheduled_tp_actions_list->[0];
    my $next_tp_date   = "$next_tp_action->{y}-$next_tp_action->{m}-$next_tp_action->{d}";

    my $next_tp_id = $next_tp_action->{action};
    if ($next_tp_id =~ /:/) {
      ($user->{ID}, $next_tp_id) = split(/:/, $next_tp_id);
    }

    # Get info about next TP
    my $tp_list = $Tariffs->list({
      INNER_TP_ID => $next_tp_id,
      NAME        => '_SHOW',
      COLS_NAME   => 1
    });

    if ($Tariffs->{TOTAL} && $Tariffs->{TOTAL} > 0){
      my $next_tp_name = $tp_list->[0]{name};
      $Voip->{TP_CHANGE_WARNING} = $html->message("info", $lang{TP_CHANGE_SHEDULED}." ($next_tp_date)", $next_tp_name, { OUTPUT2RETURN => 1 });
    }
  }

  $Voip->{ALLOW_ANSWER} = $Voip->{ALLOW_ANSWER} ? $lang{YES} : $lang{NO};
  $Voip->{ALLOW_CALLS} = $Voip->{ALLOW_CALLS} ? $lang{YES} : $lang{NO};
  if ($conf{VOIP_USER_CHG_TP}) {
    $Voip->{TP_CHANGE} = $html->button($lang{CHANGE}, 'index=' . get_function_index('voip_user_portal_chg_tp')
      . '&ID=' . $Voip->{ID} . '&sid=' . $sid, { class => 'float-right', ICON => 'fa fa-pencil-alt' });

  }
  $Voip->{DISABLE} = $Voip->{DISABLE} ? $html->color_mark($lang{DISABLE}, 'danger') : $html->color_mark($lang{ENABLE}, 'success');
  $html->tpl_show(_include('voip_user_info', 'Voip'), $Voip);

  voip_user_phone_aliases($Voip);

  return 1;
}

#**********************************************************
=head2 voip_user_stats()

=cut
#**********************************************************
sub voip_user_stats {

  require Voip::Reports;

  if (!defined($FORM{sort})) {
    $LIST_PARAMS{SORT} = 2;
    $LIST_PARAMS{DESC} = 'DESC';
  }

  my $uid = $FORM{UID} || 0;

  if ($FORM{SESSION_ID}) {
    $pages_qs .= "&SESSION_ID=$FORM{SESSION_ID}";
    voip_session_detail({ USER_INFO => $user });
    return 0;
  }

  if ($FORM{rows}) {
    $LIST_PARAMS{PAGE_ROWS} = $FORM{rows};
    $conf{list_max_recs} = $FORM{rows};
    $pages_qs .= "&rows=$conf{list_max_recs}";
  }

  #Periods totals
  my $list = $Sessions->periods_totals({ %LIST_PARAMS });
  my $table = $html->table({
    width       => '100%',
    caption     => $lang{PERIOD},
    title_plain => [ $lang{PERIOD}, $lang{DURATION}, $lang{SUM} ],
    ID          => 'PERIODS'
  });

  if (!defined($Sessions->{sum_4})) {
    $html->message('info', $lang{INFO}, $lang{NO_RECORD});
    return 1;
  }

  for (my $i = 0; $i < 5; $i++) {
    $table->addrow($html->button("$PERIODS[$i]", "index=$index&period=$i$pages_qs"), "$Sessions->{'duration_'. $i}",
      $Sessions->{ 'sum_' . $i });
  }
  print $table->show();

  $table = $html->table({
    width => '100%',
    rows  => [
      [
        "$lang{FROM}: ", $html->date_fld2('FROM_DATE', { MONTHES => \@MONTHES }),
        "$lang{TO}: ", $html->date_fld2('TO_DATE', { MONTHES => \@MONTHES }),
        "$lang{ROWS}: ",
        $html->form_input('rows', int($conf{list_max_recs}), { SIZE => 4, OUTPUT2RETURN => 1 }),
        $html->form_input('show', $lang{SHOW}, { TYPE => 'submit', OUTPUT2RETURN => 1 })
      ]
    ],
  });

  print $html->form_main({
    CONTENT => $table->show({ OUTPUT2RETURN => 1 }),
    HIDDEN  => {
      sid   => $sid,
      index => $index,
      UID   => $uid
    }
  });

  voip_stats_calculation($Sessions);

  if (defined($FORM{show})) {
    $pages_qs .= "&show=1&FROM_DATE=$FORM{FROM_DATE}&TO_DATE=$FORM{TO_DATE}";
  }
  elsif (defined($FORM{period})) {
    $LIST_PARAMS{PERIOD} = int($FORM{period});
    $pages_qs .= "&period=$FORM{period}";
  }

  #Session List
  $list = $Sessions->list({ %LIST_PARAMS, FROM_DATE => $FORM{FROM_DATE}, TO_DATE => $FORM{TO_DATE} });
  $table = $html->table({
    width       => '640',
    caption     => $lang{TOTAL},
    title_plain => [ $lang{SESSIONS}, $lang{DURATION}, $lang{SUM} ],
    rows        => [ [ $Sessions->{TOTAL}, $Sessions->{DURATION}, $Sessions->{SUM} ] ],
    ID          => 'VOIP_TOTALS'
  });

  print $table->show();

  voip_sessions($list) if ($Sessions->{TOTAL} > 0);

  return 1;
}

#**********************************************************
=head2 voip_user_routes()

=cut
#**********************************************************
sub voip_user_routes {

  my $user = $Voip->user_info($user->{UID});

  $WEEKDAYS[0] = $lang{ALL};
  my $list = $Tariffs->ti_list({ TP_ID => $user->{TP_ID} });
  my @caption = ($lang{PREFIX}, $lang{ROUTES}, "$lang{STATUS}");
  my @aligns = ('left', 'left', 'center');
  my @interval_ids = ();
  my $intervals = 0;

  foreach my $line (@{$list}) {
    push @caption,
      $html->b($WEEKDAYS[ $line->[1] ]) . $html->br() . sec2time($line->[2], { format => 1 }) . '-' . sec2time(
        $line->[3], { format => 1 });
    push @aligns, 'center';
    push @interval_ids, $line->[0];
  }
  $intervals = $Tariffs->{TOTAL};

  $list = $Voip->rp_list({ %LIST_PARAMS, COLS_NAME => 1 });
  my %prices = ();
  foreach my $line (@{$list}) {
    $prices{$line->{interval_id}}{$line->{route_id}} = $line->{price};
  }

  $pages_qs .= "&routes=$FORM{routes}" if ($FORM{routes});
  $list = $Voip->routes_list({ %LIST_PARAMS });

  my $table = $html->table({
    width   => '100%',
    caption => $lang{ROUTES},
    title   => \@caption,
    qs      => $pages_qs,
    pages   => $Voip->{TOTAL},
    ID      => 'VOIP_ROUTES_PRICES',
  });

  my $price = 0;
  foreach my $line (@{$list}) {
    my @l = ();
    for (my $i = 0; $i < $intervals; $i++) {
      if (defined($prices{"$interval_ids[$i]"}{"$line->[4]"})) {
        $price = $prices{ $interval_ids[$i] }{ $line->[4] };
      }
      else {
        $price = "0.00";
      }
      push @l, $price;
    }
    $table->addrow("$line->[0]", "$line->[1]", $status[ $line->[2] ], @l);
  }

  print $table->show();

  return 1;
}

#*******************************************************************
=head2 voip_user_phone_aliases($attr) - Info about extra phone numbers

=cut
#*******************************************************************
sub voip_user_phone_aliases {

  my $alias_list = $Voip->phone_aliases_list({
    %LIST_PARAMS,
    NUMBER    => '_SHOW',
    DISABLE   => '_SHOW',
    CHANGED   => '_SHOW',
    COLS_NAME => 1,
    UID       => $user->{UID},
  });

  my $table = $html->table({
    caption => $lang{EXTRA_NUMBERS} . ': ' . ($Voip->{TOTAL} > 0 ? $Voip->{TOTAL} : 0),
    title   => [ $lang{PHONE}, $lang{STATUS}, $lang{CHANGED} ],
    qs      => $pages_qs,
    ID      => 'VOIP_PHONE_ALIASES'
  });

  foreach my $alias (@$alias_list) {
    $table->addrow($alias->{number}, $status[$alias->{disable}], $alias->{changed});
  }

  $table->show(),

    return 1;
}

#**********************************************************
=head2 voip_user_portal_chg_tp($attr)

=cut
#**********************************************************
sub voip_user_portal_chg_tp {
  my ($attr) = @_;

  my $period = $FORM{period} || 0;
  if (!$conf{VOIP_USER_CHG_TP}) {
    $html->message('err', "$lang{CHANGE} $lang{TARIF_PLAN}", $lang{NOT_ALLOW}, { ID => 140 });
    return 0;
  }

  my $uid = $LIST_PARAMS{UID};

  if (!$uid) {
    $html->message('err', $lang{ERROR}, $lang{USER_NOT_EXIST}, { ID => 19 });
    return 0;
  }

  $Voip = $Voip->user_info($uid, { ID => $FORM{ID} });

  if ($Voip->{TOTAL} < 1) {
    $html->message('info', $lang{INFO}, $lang{NOT_ACTIVE}, { ID => 22 });
    return 0;
  }

  if ($user->{GID}) {
    #Get user groups
    $user->group_info($user->{GID});
    if ($user->{DISABLE_CHG_TP}) {
      $html->message('err', "$lang{CHANGE} $lang{TARIF_PLAN}", $lang{NOT_ALLOW}, { ID => 143 });
      return 0;
    }
  }

  #Get TP groups
  $Tariffs->tp_group_info($Voip->{TP_GID});
  if (!$Tariffs->{USER_CHG_TP}) {
    $html->message('err', "$lang{CHANGE} $lang{TARIF_PLAN}", $lang{NOT_ALLOW}, { ID => 144 });
    return 0;
  }

  my $next_abon = $Service_control->get_next_abon_date({ SERVICE_INFO => $Voip });
  $Voip->{ABON_DATE} = $next_abon->{ABON_DATE};

  if ($FORM{set} && $FORM{ACCEPT_RULES}) {
    my $add_result = $Service_control->user_chg_tp({ %FORM, UID => $uid, SERVICE_INFO => $Voip, MODULE => 'Voip' });
    $html->message('info', $lang{CHANGED}, $lang{CHANGED}) if !_message_show($add_result);
  }
  elsif ($FORM{del} && $FORM{ACCEPT_RULES}) {
    my $del_result = $Service_control->del_user_chg_shedule({ %FORM, UID => $uid });
    $html->message('info', $lang{DELETED}, "$lang{DELETED} [$FORM{SHEDULE_ID}]") if (!_message_show($del_result));
  }

  $Shedule->info({ UID => $user->{UID}, TYPE => 'tp', MODULE => 'Voip' });

  my $table;
  if ($Shedule->{TOTAL} > 0) {
    my $action = $Shedule->{ACTION};
    my $service_id = 0;
    if ($action =~ /:/) {
      ($service_id, $action) = split(/:/, $action);
    }

    $Tariffs->info(0, { TP_ID => $action });

    $table = $html->table({
      width      => '100%',
      caption    => $lang{SHEDULE},
      ID         => 'VOIP_TP_SHEDULE',
      rows       => [
        [ "$lang{TARIF_PLAN}:", "$Tariffs->{ID} : $Tariffs->{NAME}" ],
        [ "$lang{DATE}:", "$Shedule->{Y}-$Shedule->{M}-$Shedule->{D}" ],
        [ "$lang{ADDED}:", $Shedule->{DATE} ],
        [ "ID:", $Shedule->{SHEDULE_ID} ] ]
    });

    $Tariffs->{TARIF_PLAN_SEL} = $table->show({ OUTPUT2RETURN => 1 }) .
      $html->form_input('SHEDULE_ID', $Shedule->{SHEDULE_ID}, { TYPE => 'HIDDEN', OUTPUT2RETURN => 1 });
    $Tariffs->{TARIF_PLAN_TABLE} = $Tariffs->{TARIF_PLAN_SEL};
    if (!$Shedule->{ADMIN_ACTION}) {
      $Tariffs->{ACTION} = 'del';
      $Tariffs->{LNG_ACTION} = "$lang{DEL}  $lang{SHEDULE}";
    }
  }
  else {
    my $available_tariffs = $Service_control->available_tariffs({ %FORM, MODULE => 'Voip', UID => $uid });

    if (ref($available_tariffs) ne 'ARRAY' || $#{$available_tariffs} < 0) {
      $html->message('info', $lang{INFO}, $lang{ERR_NO_AVAILABLE_TP}, { ID => 142 });
      return 0;
    }

    $table = $html->table({
      width   => '100%',
      ID      => 'VOIP_TP',
      title   => [ 'ID', $lang{NAME}, '-' ],
      FIELDS_IDS => $Tariffs->{COL_NAMES_ARR},
      caption => $lang{TARIF_PLANS},
    });

    foreach my $tp (@{$available_tariffs}) {
      my $radio_but = $tp->{ERROR} ? $tp->{ERROR} : $html->form_input('TP_ID', $tp->{tp_id}, { TYPE => 'radio', OUTPUT2RETURN => 1 });

      my $text .= $html->b($tp->{name} || q{});

      if ($tp->{comments}) {
        $text .= $html->br() . $tp->{comments};
      }
      $table->addrow($tp->{id}, $text, $radio_but);
    }

    $Tariffs->{TARIF_PLAN_TABLE} = $table->show({ OUTPUT2RETURN => 1 });

    $Tariffs->{PARAMS} .= form_period($period, {
      ABON_DATE => $Voip->{ABON_DATE},
      TP        => $Tariffs,
      # PERIOD    => $FORM{period}
    });

    $Tariffs->{ACTION} = 'set';
    $Tariffs->{LNG_ACTION} = $lang{CHANGE};
  }

  $Tariffs->{UID} = $attr->{USER_INFO}->{UID};
  $Tariffs->{TP_ID} = $Voip->{TP_ID};
  $Tariffs->{TP_NAME} = "$Voip->{TP_NUM}:$Voip->{TP_NAME}";

  $Tariffs->{CHG_TP_RULES} = $html->tpl_show(_include('voip_chg_tp_rule', 'Voip'), {}, { OUTPUT2RETURN => 1 });

  $html->tpl_show(templates('form_client_chg_tp'), { %$Tariffs, ID => $Voip->{ID} }, { ID => 'VOIP_CHG_TP' });

  return 1;
}

1;
