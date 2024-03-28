package Bonus::Base;

use strict;
use warnings FATAL => 'all';

my ($admin, $CONF, $db);
my AXbills::HTML $html;
my $lang;
my Bonus $Bonus;

use AXbills::Base qw/days_in_month in_array/;

#**********************************************************
=head2 new($html, $lang)

=cut
#**********************************************************
sub new {
  my $class = shift;
  $db = shift;
  $admin = shift;
  $CONF = shift;
  my $attr = shift;

  $html = $attr->{HTML} if $attr->{HTML};
  $lang = $attr->{LANG} if $attr->{LANG};

  my $self = {};

  require Bonus;
  Bonus->import();
  $Bonus = Bonus->new($db, $admin, $CONF);

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 bonus_payments_maked($attr) - Cross module payment maked

=cut
#**********************************************************
sub bonus_payments_maked {
  my $self = shift;
  my ($attr) = @_;

  return '' if (!$CONF->{BONUS_PAYMENTS} || !$attr->{SUM});
  my $form = $attr->{FORM} || {};
  my $score = 0;
  my %RESULT = ();
  my $user;
  $user = $attr->{USER_INFO} if $attr->{USER_INFO};

  $form->{METHOD} = 2 if (!defined($form->{METHOD}));

  my $payment_method = $attr->{METHOD} || $form->{METHOD};

  my ($year, $month, $day) = split(/-/,$user->{REGISTRATION}, 3);
  my $seltime = POSIX::mktime(0, 0, 0, $day, ($month - 1), ($year - 1900));
  my $registration_days = int((time() - $seltime) / 86400);

  $Bonus->user_info($user->{UID});

  return '' if (!$Bonus->{STATE} || !$Bonus->{ACCEPT_RULES});

  my $list = $Bonus->service_discount_list({
    REGISTRATION_DAYS => "<=$registration_days,>=0",
    PAGE_ROWS         => 20,
    SORT              => "registration_days DESC, 1 DESC, 2 DESC, pay_method DESC",
    COLS_NAME         => 1
  });

  if ($Bonus->{TOTAL} > 0) {
    foreach my $line (@$list) {
      if (in_array('-1', [ split(', ', $line->{pay_method}) ])
        || in_array($payment_method, [ split(', ', $line->{pay_method}) ])) {
        $RESULT{DISCOUNT} = $line->{discount};
        $RESULT{DISCOUNT_PERIOD} = $line->{discount_days};
        $RESULT{BONUS_SUM} = $line->{bonus_sum};
        $RESULT{BONUS_PERCENT} = $line->{bonus_percent};
        $RESULT{BONUS_EXT_ACCOUNT} = $line->{ext_account};

        if ($RESULT{DISCOUNT_PERIOD} > 0) {
          $RESULT{DISCOUNT_PERIOD} = POSIX::strftime('%Y-%m-%d', localtime(time + 86400 * $RESULT{DISCOUNT_PERIOD}));
        }

        if ($RESULT{BONUS_PERCENT}) {
          $score = $attr->{SUM} / 100 * $RESULT{BONUS_PERCENT};
        }
        last;
      }
    }
  }

  if (!$attr->{QUITE} && $attr->{SUM} > 0) {
    $html->message('info', $lang->{BONUS}, "$lang->{ADD} $lang->{BONUS} " . sprintf('%.2f', $score));
  }

  $Bonus->accomulation_scores_add({ UID => $user->{UID}, SCORE => $score });

  return 1;
}

#**********************************************************
=head2 bonus_pre_payment($attr)

  Arguments:
    $attr
      SUM

=cut
#**********************************************************
sub bonus_pre_payment {
  my $self = shift;
  my ($attr) = @_;

  my $form = $attr->{FORM} || {};
  my $REPORT = '';
  my $sum = $form->{PAYMENT_SUM} || $attr->{SUM} || 0;

  if ($CONF->{BONUS_SERVICE_DISCOUNT} && $sum > 0) {
    $self->bonus_service_discount_mk({ %$attr, SUM => $sum, FORM => $form });
  }

  $self->bonus_turbo_mk({ %$attr, SUM => $sum, FORM => $form }) if $CONF->{BONUS_TURBO} && $sum > 0;

  return $REPORT;
}

#**********************************************************
=head2 bonus_turbo_mk($attr)

=cut
#**********************************************************
sub bonus_turbo_mk {
  my $self = shift;
  my ($attr) = @_;

  my $form = $attr->{FORM} || {};

  return 0 if $form->{METHOD} == 4 || $form->{METHOD} == 6;

  my $Internet;
  if (in_array('Internet', \@main::MODULES)) {
    require Internet;
    Internet->import();
    $Internet = Internet->new($db, $admin, $CONF);
    $Internet->user_info($attr->{USER_INFO}{UID});
  }

  my $periods = 0;
  my $registration_days = 0;

  if ($Internet && $Internet->{MONTH_ABON} > 0) {
    $periods = int($form->{SUM} / $Internet->{MONTH_ABON});
  }

  return 0 if $periods < 1;

  my %RESULT = ();
  my ($year, $month, $day) = split(/-/, $attr->{USER_INFO}->{REGISTRATION}, 3);
  my $seltime = POSIX::mktime(0, 0, 0, $day, ($month - 1), ($year - 1900));
  $registration_days = int((time() - $seltime) / 86400);
  my $list = $Bonus->bonus_turbo_list({
    REGISTRATION_DAYS => "<=$registration_days,>=0",
    PERIODS           => "<=$periods",
    PAGE_ROWS         => 1,
    SORT              => "1 DESC, 2 DESC",
    COLS_NAME         => 1
  });

  $RESULT{TURBO_COUNT} = $list->[0]{turbo_count} if $Bonus->{TOTAL} > 0;

  #Result
  if ($RESULT{TURBO_COUNT} && $RESULT{TURBO_COUNT} > 0) {
    $Internet->user_change({ UID => $attr->{USER_INFO}->{UID}, FREE_TURBO_MODE => $RESULT{TURBO_COUNT} });
    $html->message('info', $lang->{INFO}, "$lang->{BONUS}: \n Turbo: $RESULT{TURBO_COUNT}");
  }

  return 0;
}

#**********************************************************
=head2 bonus_service_discount_mk($attr)

  Arguments:
     $attr
       METHOD
       SUM
       USER_INFO

  Results:

=cut
#**********************************************************
sub bonus_service_discount_mk {
  my $self = shift;
  my ($attr) = @_;

  my $form = $attr->{FORM} || {};
  my @excluder_arr = ();

  my $user_info = $attr->{USER_INFO};
  if ($user_info->{GID}) {
    $user_info->group_info($main::users->{GID});

    if (!$user_info->{BONUS}) {
      $html->message('warn', $lang->{BONUS_DISABLED_FOR_GROUP}, '', { ID => 1901 });
      return 0;
    }
  }

  if (!$CONF->{BONUS_SERVICE_EXCLUDE}) {
    $CONF->{BONUS_SERVICE_EXCLUDE} = '!4,!6';
  }

  my $payment_sum = $attr->{SUM} || $form->{SUM};
  my $pay_method = $attr->{METHOD} || $form->{METHOD};
  my $exclude = $CONF->{BONUS_SERVICE_EXCLUDE};
  $exclude =~ s/!//g;
  @excluder_arr = split(/,\s?/, $exclude);

  return 0 if in_array($pay_method, \@excluder_arr);

  $Bonus->{debug} = 1 if ($CONF->{BONUS_DEBUG} && $CONF->{BONUS_DEBUG} > 6);

  my %RULES = ();
  my $list = $Bonus->service_discount_list({
    PAGE_ROWS           => 1000,
    ONETIME_PAYMENT_SUM => '_SHOW',
    COLS_NAME           => 1
  });

  foreach my $line (@{$list}) {
    if ($line->{registration_days} > 0) {
      $RULES{PERIOD} = 1;
    }
    elsif ($line->{total_payments_sum} > 0) {
      $RULES{TOTAL_PAYMENT} = 1;
    }
    elsif ($line->{onetime_payment_sum} && $line->{onetime_payment_sum} > 0) {
      $RULES{ONETIME_PAYMENT_SUM} = $line->{onetime_payment_sum};
    }
    elsif ($line->{service_period}) {
      $RULES{PERIOD} = 1;
    }
  }

  require Payments;
  Payments->import();
  my $Payments = Payments->new($db, $admin, $CONF);

  my $Internet;
  if (in_array('Internet', \@main::MODULES)) {
    require Internet;
    Internet->import();

    $Internet = Internet->new($db, $admin, $CONF);
    $Internet->user_info($user_info->{UID});
  }

  my $periods = 0;
  my $registration_days = 0;
  my $month_fee = 0;

  if ($Internet->{MONTH_ABON} && $Internet->{MONTH_ABON} > 0) {
    if ($Internet->{PERSONAL_TP} && $Internet->{PERSONAL_TP} > 0) {
      $month_fee = $Internet->{PERSONAL_TP};
    }
    else {
      $month_fee = $Internet->{MONTH_ABON};
    }
  }
  if ($Internet->{DAY_ABON} && $Internet->{DAY_ABON} > 0) {
    $month_fee = $Internet->{DAY_ABON} * 30;
  }

  if ($month_fee > 0) {
    $periods = int($payment_sum / $month_fee);
  }

  my %RESULT = ();
  if ($RULES{PERIOD}) {
    my ($year, $month, $day) = split(/-/, $user_info->{REGISTRATION}, 3);
    my $seltime = POSIX::mktime(0, 0, 0, $day, ($month - 1), ($year - 1900));
    $registration_days = int((time() - $seltime) / 86400);

    $list = $Bonus->service_discount_list({
      REGISTRATION_DAYS   => "<=$registration_days,>=0",
      PERIODS             => "<=$periods",
      PAGE_ROWS           => 1,
      COLS_NAME           => 100,
      SORT                => ($periods) ? 'service_period DESC' : "1 DESC, 2 DESC",
      TP_ID               => '_SHOW',
      ONETIME_PAYMENT_SUM => '_SHOW'
    });

    for (my $i=0; $i < $Bonus->{TOTAL}; $i++) {
      if (!$list->[$i]->{tp_id}
        || ($Internet->{TP_ID} && in_array($Internet->{TP_ID}, [ grep {$_ ne ''} split(',\s?', $list->[$i]->{tp_id}) ]))
      ) {
        $RESULT{DISCOUNT} = $list->[$i]->{discount};
        $RESULT{DISCOUNT_PERIOD} = $list->[$i]->{discount_days};
        $RESULT{BONUS_SUM} = $list->[$i]->{bonus_sum};
        $RESULT{BONUS_PERCENT} = $list->[$i]->{bonus_percent};
        $RESULT{BONUS_EXT_ACCOUNT} = $list->[$i]->{ext_account};
        $RESULT{ID} = $list->[$i]->{id};
        $RESULT{ONETIME_PAYMENT_SUM} = $list->[$i]->{onetime_payment_sum};

        if ($RESULT{DISCOUNT_PERIOD} > 0) {
          $RESULT{DISCOUNT_PERIOD} = POSIX::strftime('%Y-%m-%d', localtime(time + 86400 * $RESULT{DISCOUNT_PERIOD}));
        }
        last;
      }
    }
  }

  if ($RULES{TOTAL_PAYMENT} || ($RULES{ONETIME_PAYMENT_SUM} && $RULES{ONETIME_PAYMENT_SUM} > 0)) {
    my $payments_sum = 0;
    my %get_bonus = (
      #PAGE_ROWS => 1,
      ID        => '_SHOW',
      TP_ID     => '_SHOW',
      NAME      => '_SHOW',
      SORT      => "service_period DESC, registration_days DESC, onetime_payment_sum DESC",
      COLS_NAME => 1
    );

    if ($RULES{ONETIME_PAYMENT_SUM}) {
      $get_bonus{ONETIME_PAYMENT_SUM} = "<=$payment_sum,>=0";
    }
    else {
      $list = $Payments->list({
        UID        => $user_info->{UID},
        TOTAL_ONLY => 1,
        METHOD     => $CONF->{BONUS_SERVICE_EXCLUDE} || '!4,!6'
      });

      $payments_sum = (($Payments->{SUM} || 0) + $payment_sum);
      $get_bonus{TOTAL_PAYMENTS_SUM} = "<=$payments_sum,>=0";
    }

    if ($periods) {
      $get_bonus{PERIODS} = "<=$periods";
    }

    my $discount_list = $Bonus->service_discount_list({ %get_bonus });

    if ($Bonus->{TOTAL} > 0) {
      my $fill_bonus = 0;
      foreach my $discount (@$discount_list) {
        my @pay_methods = ();

        if (defined($discount->{pay_method}) && $discount->{pay_method} ne '-1') {
          @pay_methods = split(/,\s?/, $discount->{pay_method});
        }

        if (!$discount->{tp_id}) {
          $fill_bonus = 1;
        }
        elsif ($Internet->{TP_ID} && in_array($Internet->{TP_ID}, [ grep {$_ ne ''} split(',\s?', $discount->{tp_id}) ])) {
          $fill_bonus = 1;
        }

        if ($#pay_methods > -1 && !in_array($pay_method, \@pay_methods)) {
          #Skip bonus if no other program
          #return 0;
        }
        elsif ($fill_bonus) {
          $RESULT{DISCOUNT}         = $discount->{discount};
          $RESULT{DISCOUNT_PERIOD}  = $discount->{discount_days};
          $RESULT{BONUS_SUM}        = $discount->{bonus_sum};
          $RESULT{BONUS_PERCENT}    = $discount->{bonus_percent};
          $RESULT{BONUS_EXT_ACCOUNT}= $discount->{ext_account};
          $RESULT{ID}               = $discount->{id};
          $RESULT{BONUS_NAME}       = $discount->{name};

          if ($CONF->{BONUS_DEBUG}) {
            print "Bonus activate: $discount->{id}\n";
          }

          if ($RESULT{DISCOUNT_PERIOD} > 0) {
            $RESULT{DISCOUNT_PERIOD} = POSIX::strftime('%Y-%m-%d', localtime(time + 86400 * $RESULT{DISCOUNT_PERIOD}));
          }

          last;
        }
      }

      if (! $fill_bonus) {
        %RESULT = ();
      }
    }
  }

  #Result
  if ($RESULT{DISCOUNT} && $RESULT{DISCOUNT} > 0) {
    $main::users->change($user_info->{UID}, {
      REDUCTION      => $RESULT{DISCOUNT},
      REDUCTION_DATE => $RESULT{DISCOUNT_PERIOD},
      UID            => $user_info->{UID}
    });

    $html->message('info', $lang->{INFO},
      "$lang->{BONUS}: \n $lang->{REDUCTION}: $RESULT{DISCOUNT}\n  $lang->{DATE}: $RESULT{DISCOUNT_PERIOD}");
  }

  if ($RESULT{BONUS_PERCENT} && $RESULT{BONUS_PERCENT} > 0) {
    $RESULT{BONUS_SUM} = sprintf("%.2f", $payment_sum / 100 * $RESULT{BONUS_PERCENT});
  }

  if ($RESULT{BONUS_SUM} && $RESULT{BONUS_SUM} > 0) {
    $main::users->{MAIN_BILL_ID} = $main::users->{BILL_ID};

    $Payments->add($user_info,{
      SUM          => $RESULT{BONUS_SUM},
      METHOD       => 4,
      DESCRIBE     => $RESULT{BONUS_NAME} ? $RESULT{BONUS_NAME}  : $lang->{BONUS} . (($RESULT{ID}) ? " # $RESULT{ID}" : q{}),
      BILL_ID      => ($RESULT{BONUS_EXT_ACCOUNT}) ? $user_info->{EXT_BILL_ID} : $user_info->{BILL_ID},
      EXT_ID       => ($attr->{EXT_ID}) ? 'B_' . $attr->{EXT_ID} : undef,
      CHECK_EXT_ID => ($attr->{EXT_ID}) ? 'B_' . $attr->{EXT_ID} : undef
    });

    if ($Payments->{errno}) {
      if ($Payments->{errno} == 12) {
        $html->message('err', $lang->{ERROR}, $lang->{ERR_WRONG_SUM});
      }
      elsif ($Payments->{errno} == 14) {
        my $message = ($RESULT{BONUS_EXT_ACCOUNT}) ? "$lang->{EXTRA}" : '';
        $html->message('err', $lang->{ERROR}, "$message $lang->{BILL} $lang->{NOT_EXIST} ");
      }
      else {
        $html->message('err', $lang->{ERROR}, "[$Payments->{errno}] $main::err_strs{$Payments->{errno}}");
      }
    }
    else {
      my $message = "$lang->{BONUS} $lang->{SUM}: $RESULT{BONUS_SUM}";
      $message = "$lang->{EXTRA} $lang->{ACCOUNT}\n" . $message if $RESULT{BONUS_EXT_ACCOUNT};
      $html->message('info', $lang->{INFO}, "$message") if !$attr->{QUITE};
    }

    $main::users->{BILL_ID} = $main::users->{MAIN_BILL_ID} if $main::users->{MAIN_BILL_ID};
  }

  return 0;
}

1;