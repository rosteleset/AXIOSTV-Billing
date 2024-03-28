=head1 NAME

  Dv rating system

=cut

use strict;
use warnings FATAL => 'all';

our(
  $db,
  %conf,
  $admin,
  %lang,
  $html,
  %permissions,
  $Dv
);

my $Tariffs  = Tariffs->new($db, \%conf, $admin);
my $Fees     = Fees->new($db, $admin, \%conf);

#**********************************************************
=head2 dv_rating_tp($attr)

=cut
#**********************************************************
sub dv_rating_tp {
  my ($attr) = @_;

  eval { require Bonus_rating; };
  if (!$@) {
    Bonus_rating->import();
  }
  else {
    $html->message('err', $lang{ERROR}, "Can't load 'Bonus_rating'. Purchase this module https://billing.axiostv.ru");
    return 0;
  }

  my $Bonus_rating = Bonus_rating->new($db, $admin, \%conf);

  if (defined($attr->{TP})) {
    if ($FORM{change}) {
      $Bonus_rating->change({%FORM});

      if (!$Bonus_rating->{errno}) {
        $html->message('info', $lang{INFO}, "$lang{CHANGED}");
      }
    }
  }
  elsif (defined($FORM{TP_ID})) {
    $FORM{subf} = $index;
    dv_tp();
    return 0;
  }

  _error_show($Bonus_rating);

  $Bonus_rating->info($FORM{TP_ID});

  my $tp_list = $Tariffs->list({ MODULE       => 'Dv',
    DOMAIN_ID    => $admin->{DOMAIN_ID},
    NEW_MODEL_TP => 1,
    COLS_NAME    => 1
  });

  $Bonus_rating->{RATING_ACTION_SEL} = $html->form_select(
    'RATING_ACTION',
    {
      SELECTED    => $Bonus_rating->{RATING_ACTION},
      SEL_LIST    => $tp_list,
      SEL_KEY     => 'tp_id',
      SEL_VALUE   => 'id,name',
      SEL_OPTIONS => { '' => "", '-1' => "$lang{HOLD_UP}" },
      NO_ID       => 1
    }
  );

  $Bonus_rating->{ACTION}           = 'change';
  $Bonus_rating->{LNG_ACTION}       = "$lang{CHANGE}";
  $Bonus_rating->{EXT_BILL_ACCOUNT} = "checked" if ($Bonus_rating->{EXT_BILL_ACCOUNT});

  $html->tpl_show(_include('dv_rating_tp', 'Dv'), $Bonus_rating);

  return 1;
}

#**********************************************************
=head2 dv_rating_periodic($attr)

=cut
#**********************************************************
sub dv_rating_periodic {
  my ($attr) = @_;

  my $debug = $attr->{DEBUG} || 0;
  my $debug_output = '';
  $debug_output .= "DV: Make ratings\n" if ($debug > 1);

  eval { require Bonus_rating; };
  if (!$@) {
    Bonus_rating->import();
  }
  else {
    print "Can't load 'Bonus_rating'. Purchase this module https://billing.axiostv.ru";
    return 0;
  }

  my %LIST_PARAMS = (PAGE_ROWS => 1000000);
  $LIST_PARAMS{LOGIN} = $attr->{LOGIN} if ($attr->{LOGIN});
  $LIST_PARAMS{TP_ID} = $attr->{TP_ID} if ($attr->{TP_ID});

  my $Bonus_rating = Bonus_rating->new($db, $admin, \%conf);

  $Bonus_rating->change_users_rating({%LIST_PARAMS});

  #Change Tps
  my $list = $Bonus_rating->change_users_tps_list({%LIST_PARAMS, COLS_NAME => 1 });

  foreach my $line (@$list) {
    $debug_output .= "UID: $line->{uid} TP: $line->{old_tp_id} -> $line->{tp_id}\n" if ($debug > 0);
    $Dv->change(
      {
        UID            => $line->{uid},
        TP_ID          => $line->{tp_id},
        NO_CHANGE_FEES => 1,
      }
    );

  }

  $DEBUG .= $debug_output;
  return $debug_output;
}

#**********************************************************
=head2 dv_rating_user()

=cut
#**********************************************************
sub dv_rating_user {

  eval { require Bonus_rating; };
  if (!$@) {
    Bonus_rating->import();
  }
  else {
    print "Can't load 'Bonus_rating'. Purchase this module https://billing.axiostv.ru";
    return 0;
  }

  my $Bonus_rating = Bonus_rating->new($db, $admin, \%conf);
  $users = $user if (!$users);

  $Bonus_rating->users_rating_info({ UID => $LIST_PARAMS{UID} });

  if ($Bonus_rating->{TOTAL} == 0) {
    $html->message('info', $lang{INFO}, "$lang{BONUS} $lang{NOT_ACTIVE}");
    return 0;
  }

  if ($FORM{UP_RATING_PRE}) {
    my $need_percents = int(($FORM{UP_RATING} - $Bonus_rating->{RATING_PER}));
    $FORM{NEED_SUM} = sprintf("%.2f", $need_percents * ($Bonus_rating->{ONE_PERCENT_SUM} * $Bonus_rating->{ONE_PERCENT_COUNT}));

    $html->tpl_show(_include('dv_user_rating_pre', 'Dv'), { %$Bonus_rating, %FORM });
    return 0;
  }
  elsif ($FORM{UP_RATING}) {
    my $need_percents = int(($FORM{UP_RATING} - $Bonus_rating->{RATING_PER}));
    my $need_sum = $need_percents * ($Bonus_rating->{ONE_PERCENT_SUM} * $Bonus_rating->{ONE_PERCENT_COUNT});

    if ($users->{CREDIT} + $users->{DEPOSIT} < $need_sum) {
      $html->message('err', $lang{ERROR}, "$lang{ERR_SMALL_DEPOSIT}", {  });
    }
    else {
      for (my $i = 0 ; $i < int($need_percents * $Bonus_rating->{ONE_PERCENT_COUNT}) ; $i++) {
        $Fees->take($users, $Bonus_rating->{ONE_PERCENT_SUM}, { DESCRIBE => "$lang{RATING_UP}" });
        $users->{DEPOSIT} -= $Bonus_rating->{ONE_PERCENT_SUM};
      }
      $Bonus_rating->{RATING_PER} = $FORM{UP_RATING};
      $html->message('info', $lang{INFO}, "$lang{UP_RATING} $FORM{UP_RATING}");

      $users->pi_change({ _rating => $Bonus_rating->{RATING_PER}, UID => $LIST_PARAMS{UID} });
    }
  }

  $Bonus_rating->{UP_RATING} = int(($users->{CREDIT} + $users->{DEPOSIT}) / ($Bonus_rating->{ONE_PERCENT_SUM} * $Bonus_rating->{ONE_PERCENT_COUNT})) + $Bonus_rating->{RATING_PER};

  if ($Bonus_rating->{UP_RATING} > 100) {
    $Bonus_rating->{UP_RATING} = 100;
  }
  elsif ($Bonus_rating->{UP_RATING} < 0) {
    $Bonus_rating->{UP_RATING} = 0;
  }

  $Bonus_rating->{ONE_PERCENT_SUM} = sprintf("%.2f", $Bonus_rating->{ONE_PERCENT_SUM} * $Bonus_rating->{ONE_PERCENT_COUNT});

  $html->tpl_show(_include('dv_user_rating', 'Dv'), $Bonus_rating);

  return 1;
}


1;
