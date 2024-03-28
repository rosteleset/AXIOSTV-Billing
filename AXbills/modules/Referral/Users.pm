package Referral::Users;
use strict;
use warnings FATAL => 'all';
use POSIX qw(strftime);

=head1 NAME

  Referral users function

  ERROR ID: 410xx

=cut

use AXbills::Base qw(date_diff load_pmodule);
use Referral;
use Users;

my Referral $Referral;
my Users $Users;

my AXbills::HTML $html;

my %lang;
my $DATE;

#**********************************************************
=head2 new($db, $conf, $admin, $lang)

=cut
#**********************************************************
sub new {
  my ($class, $db, $admin, $conf, $attr) = @_;

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $conf,
  };

  %lang = %{$attr->{lang} || {}};
  $html = $attr->{html};

  $Users = Users->new($db, $admin, $conf);
  $Referral = Referral->new($db, $admin, $conf, { SKIP_CONF => 1 });
  $DATE = POSIX::strftime("%Y-%m-%d", localtime(time));

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 referral_friend_manage() add friend by user

=cut
#**********************************************************
sub referral_user_manage {
  my $self = shift;
  my ($attr) = @_;

  my $phone_format = $self->{conf}->{PHONE_FORMAT} || $self->{conf}->{CELL_PHONE_FORMAT};

  if ((!$attr->{PHONE} || !$attr->{FIO}) && $attr->{add}) {
    return {
      errno   => 41003,
      errstr  => 'No fields fio or number',
      element => [ 'err', $lang{ERROR}, "$lang{FIO} $lang{OR} $lang{PHONE} $lang{EMPTY}", { ID => 41003 } ]
    };
  }
  elsif ($attr->{PHONE} && (($phone_format && $attr->{PHONE} !~ /$phone_format/) || $attr->{PHONE} !~ /^\d+$/g)) {
    return {
      errno   => 41001,
      errstr  => 'Invalid phone',
      element => [ 'err', $lang{ERROR}, $lang{ERR_ONLY_NUMBER}, { ID => 41001 } ]
    };
  }
  elsif ($attr->{PHONE} && $attr->{add}) {
    $Referral->request_list({
      REFERRER     => $Users->{UID},
      phone        => $attr->{PHONE},
      COLS_NAME    => 1,
    });

    if ($Referral->{TOTAL} && $Referral->{TOTAL} > 0) {
      return {
        errno   => 41002,
        errstr  => 'Referral already exists with this number',
        element => [ 'err', $lang{ERROR}, "$lang{PHONE} $lang{EXIST}", { ID => 41002 } ]
      };
    }
  }

  my %params = ();
  my @allowed_params = ('FIO', 'PHONE', 'ADDRESS', 'COMMENTS');

  foreach my $param (@allowed_params) {
    $params{$param} = $attr->{$param} if ($attr->{$param});
  }

  if ($attr->{add}) {
    my $result = $Referral->add_request({
      %params,
      REFERRER      => $attr->{UID},
      LOCATION_ID   => $attr->{LOCATION_ID},
      ADDRESS_FLAT  => $attr->{ADDRESS_FLAT},
    });

    return {
      result      => 'Successfully added',
      referral_id => $result->{INSERT_ID},
    };
  }
  elsif ($attr->{change}) {
    my $referral = $Referral->request_list({
      REFERRER     => $attr->{UID},
      ID           => $attr->{ID},
      REFERRAL_UID => '_SHOW',
      COLS_NAME    => 1,
    });

    if ($referral && scalar @{$referral}) {
      return {
        errno   => 41004,
        errstr  => 'Referral already is user',
        element => [ 'err', $lang{ERROR}, $lang{USER_EXIST}, { ID => 41004 } ]
      } if ($referral->[0]->{referral_uid});
    }
    else {
      return {
        errno   => 41005,
        errstr  => 'Referral does not exist',
        element => [ 'err', $lang{ERROR}, $lang{USER_NOT_FOUND}, { ID => 41005 } ]
      }
    }

    $Referral->change_request({
      %params,
      ID       => $attr->{ID} || '',
      REFERRER => $attr->{UID},
    });

    my $referrals = $self->referrals_list({ UID => $attr->{UID} || '--' });

    return {
      result      => 'Successfully changed',
      referral_id => $attr->{ID},
      referral    => $referrals && $referrals->{referrals} ? $referrals->{referrals}->[0] : {}
    };
  }
  else {
    return {
      result => 'OK',
    };
  }
}

#**********************************************************
=head2 referral_add_friend() add friend by user

=cut
#**********************************************************
sub referrals_user {
  my $self = shift;
  my ($attr) = @_;

  $Users->info($attr->{UID} || '--');

  my $referrals = $self->referrals_list({ UID => $attr->{UID} || '--' });

  my %params = (
    result          => 'OK',
    referrals       => $referrals->{referrals},
    referrals_total => $referrals->{referrals_total},
    total_bonus     => $referrals->{total_bonus},
  );

  if (scalar @main::REGISTRATION || $self->{conf}->{NEW_REGISTRATION_FORM}) {
    my $referral_link = $main::SELF_URL || q{};
    my $script_name = $ENV{SCRIPT_NAME} || q{};
    $referral_link =~ s/$script_name/\/registration.cgi?REFERRER=$Users->{UID}/;

    $params{referral_link} = $referral_link;
  }

  return \%params;
}

#**********************************************************
=head2 referrals_list()

  ATTR:
    UID: int          - referral user uid in system
    REFERRAL_UID: int - referrer user uid in system

=cut
#**********************************************************
sub referrals_list {
  my $self = shift;
  my ($attr) = @_;

  my @referrals = ();
  my $total_bonus = 0;
  my %status = (
    0 => 'not considered',
    1 => 'in work',
    2 => 'processed',
    3 => 'canceled'
  );

  my $referral_list = $Referral->request_list({
    REFERRER     => $attr->{UID} || '_SHOW',
    phone        => '_SHOW',
    ADDRESS      => '_SHOW',
    FIO          => '_SHOW',
    STATUS       => $attr->{STATUS} || '_SHOW',
    TP_ID        => '_SHOW',
    REFERRAL_UID => $attr->{REFERRAL_UID} || '_SHOW',
    USER_STATUS  => '_SHOW',
    USER_DELETED => '_SHOW',
    COMMENTS     => '_SHOW',
    DATE         => '_SHOW',
    PAYMENTS_TYPE=> '_SHOW',
    FEES_TYPE    => '_SHOW',
    INACTIVE_DAYS => '_SHOW',
    SORT         => 'r.id',
    DESC         => 'DESC',
    COLS_NAME    => 1,
    PAGE_ROWS    => 99999
  });

  foreach my $referral (@{$referral_list}) {
    if ($referral->{referral_uid}) {
      my $payments_bonus = 0;
      my $fees_bonus = 0;
      my $bonus_bill = 1;
      my $referral_bonus = 1;
      my $bonuses = [];

      my $result = $self->_referral_calculate_bonus(0, {
        REFERRER => $referral->{referrer},
        UID      => $referral->{referral_uid},
        TP_ID    => $referral->{referral_tp} || '',
        DATE     => $referral->{date} || '',
        PAYMENTS_TYPE => $referral->{payments_type} || '',
        FEES_TYPE     => $referral->{fees_type} || '',
      });

      if (!$result->{errno}) {
        $total_bonus += $result->{total_bonus} || 0;
        $payments_bonus += $result->{payments_bonus} || 0;
        $fees_bonus += $result->{fees_bonus} || 0;
        $referral_bonus = (($result->{payments_bonus} || 0) + ($result->{fees_bonus} || 0)) || $result->{total_bonus} || 0;
        $bonuses = $result->{bonuses} || [];
        $bonus_bill = defined $result->{bonus_bill} ? $result->{bonus_bill} : 1;
      }

      push @referrals, {
        ID             => $referral->{id} || '',
        FIO            => $referral->{fio} || '',
        PHONE          => $referral->{phone} || '',
        STATUS         => defined $referral->{status} ? $referral->{status} : 999,
        STATUS_NAME    => $status{$referral->{status}} || 'unknown',
        DISABLE        => $referral->{deleted} ? $referral->{deleted} : defined $referral->{disable} ? $referral->{disable} : 1,
        PAYMENT_BONUS  => $payments_bonus,
        SPENDING_BONUS => $fees_bonus,
        TOTAL_BONUS    => $referral_bonus,
        ADDRESS        => $referral->{address},
        IS_USER        => 'true',
        COMMENTS       => $referral->{comments},
        BONUSES        => $bonuses,
        BONUS_BILL     => $bonus_bill,
        REFERRER       => $referral->{referrer},
        UID            => $referral->{referral_uid},
        TP_INACTIVE_DAYS  => $referral->{inactive_days},
      }
    }
    else {
      push @referrals, {
        ID             => $referral->{id} || '',
        FIO            => $referral->{fio} || '',
        PHONE          => $referral->{phone} || '',
        STATUS         => defined $referral->{status} ? $referral->{status} : 999,
        STATUS_NAME    => $status{$referral->{status}} || 'unknown',
        DISABLE        => defined $referral->{disable} ? $referral->{disable} : 1,
        PAYMENT_BONUS  => 0,
        SPENDING_BONUS => 0,
        ADDRESS        => $referral->{address},
        IS_USER        => 'false',
        COMMENTS       => $referral->{comments}
      }
    }
  }

  return {
    referrals       => \@referrals,
    referrals_total => scalar @referrals,
    total_bonus     => $total_bonus,
  };
}

#**********************************************************
=head2 _referral_calculate_bonus()

=cut
#**********************************************************
sub _referral_calculate_bonus {
  my $self = shift;
  my ($register, $attr) = @_;

  return {
    errno  => 41021,
    errstr => 'No params referrer and uid'
  } if (!$attr->{REFERRER} || !$attr->{UID});

  my $tariff_settings;
  if ($attr->{TP_ID}) {
    $tariff_settings = $Referral->tp_info($attr->{TP_ID} || '--');
  }
  else {
    $tariff_settings = $Referral->get_default_tp();
  }

  return {
    errno  => 4102,
    errstr => 'Tariff not found'
  } if ($Referral->{errno});

  my $recharge_percent  = $tariff_settings->{REPL_PERCENT};
  my $spend_percent = $tariff_settings->{SPEND_PERCENT};
  my @bonuses = ();

  my $bonus_amount = 0;
  my $payments_bonus = 0;
  my $fees_bonus = 0;
  my $max_bonus = 0;

  if ($tariff_settings->{MAX_BONUS_AMOUNT} && $tariff_settings->{MAX_BONUS_AMOUNT} > 0) {
    $Referral->get_total_bonus($attr->{UID});
    my $max_amount = sprintf('%.2f', $tariff_settings->{MAX_BONUS_AMOUNT} || 0);
    my $curr_total_sum = sprintf('%.2f', $Referral->{TOTAL_SUM} || 0);

    return {
      errno  => 41030,
      errstr => 'Max bonus referral amount reached',
    } if ($curr_total_sum >= $max_amount);

    $max_bonus = $max_amount - $curr_total_sum;
  }

  if (!$register && ($recharge_percent || $spend_percent || $tariff_settings->{STATIC_ACCRUAL})) {
    if ($tariff_settings->{PERIOD}) {
      if ($attr->{DATE} && $attr->{DATE} =~ /(\d{4})-(\d{2})-(\d{2})/g) {
        my $allowed_days = $tariff_settings->{PERIOD} * 30;
        my $days = date_diff("$1-$2-$3", $main::DATE);

        return {
          errno  => 41029,
          errstr => 'The bonus accrual period expired',
        } if ($days > $allowed_days);
      }
      else {
        return {
          errno  => 41028,
          errstr => 'The bonus accrual period expired'
        };
      }
    }

    if ($tariff_settings->{PAYMENT_ARREARS}) {
      require Fees;
      my $Fees = Fees->new($self->{db}, $self->{admin}, $self->{conf});

      my $fees_list = $Fees->list({
        UID       => $attr->{UID},
        DATETIME  => '_SHOW',
        SUM       => '_SHOW',
        BILL_ID   => '_SHOW',
        SORT      => 'datetime DESC',
        COLS_NAME => 1,
      });

      if ($Fees->{TOTAL} && $Fees->{TOTAL} > 0) {
        my $left_part  = date_diff($fees_list->[0]->{datetime}, $main::DATE);
        my $right_part = 30 * ($tariff_settings->{PAYMENT_ARREARS} || 0);

        if ($left_part >= $right_part) {
          return {
            errno  => 4114,
            errstr => 'User not using services'
          };
        }
      }
    }

    if ($tariff_settings->{STATIC_ACCRUAL}) {
      return {
        errno  => 4117,
        errstr => 'Not first day of month'
      } if ($main::DATE !~ /^\d{4}-\d{2}-01$/g);

      my $default_bonus = sprintf('%.2f', $tariff_settings->{BONUS_AMOUNT} || 0);

      $bonus_amount = $default_bonus;
      push @bonuses, {
        UID        => $attr->{UID},
        REFERRER   => $attr->{REFERRER},
        SUM        => $default_bonus,
        PAYMENT_ID => 0,
        FEE_ID     => 0,
      };
    }
    else {
      if ($recharge_percent) {
        my $payments = $Referral->get_payments_bonus($attr);
        if (!$Referral->{errno} && scalar @{$payments}) {
          foreach my $payment (@{$payments}) {
            next if (!$payment->{sum});
            my $bonus = $payment->{sum} * ($recharge_percent / 100);
            $bonus_amount += $bonus;
            $payments_bonus += $bonus;
            push @bonuses, {
              UID        => $attr->{UID},
              REFERRER   => $attr->{REFERRER},
              SUM        => $bonus,
              PAYMENT_ID => $payment->{id},
              FEE_ID     => 0,
            };
          }
        }
      }

      if ($spend_percent) {
        my $fees = $Referral->get_fees_bonus($attr);
        if (!$Referral->{errno} && scalar @{$fees}) {
          foreach my $fee (@{$fees}) {
            next if (!$fee->{sum});
            my $bonus = $fee->{sum} * ($spend_percent / 100);
            $bonus_amount += $bonus;
            $fees_bonus += $bonus;
            push @bonuses, {
              UID        => $attr->{UID},
              REFERRER   => $attr->{REFERRER},
              SUM        => $bonus,
              PAYMENT_ID => 0,
              FEE_ID     => $fee->{id},
            };
          }
        }
      }
    }
  }
  else {
    my $result = $Referral->get_single_bonus($attr->{UID});

    if ($result && scalar @{$result}) {
      return {
        errno  => 4115,
        errstr => 'Bonus already added'
      };
    }
    else {
      my $default_bonus = sprintf('%.2f', $tariff_settings->{BONUS_AMOUNT} || 0);
      $bonus_amount = $default_bonus;
      push @bonuses, {
        UID        => $attr->{UID},
        REFERRER   => $attr->{REFERRER},
        SUM        => $default_bonus,
        PAYMENT_ID => 0,
        FEE_ID     => 0,
      };
    }
  }

  if ($max_bonus && $max_bonus < $bonus_amount) {
    $bonus_amount = $max_bonus;
    $fees_bonus = 0;
    $payments_bonus = 0;
    my @updated_bonuses = ();

    foreach my $bonus (@bonuses) {
      last if ($max_bonus < 0);
      if ($bonus->{SUM} < $max_bonus) {
        $max_bonus -= $bonus->{SUM};
      }
      else {
        $bonus->{SUM} = $max_bonus;
        $max_bonus = -1;
      }
      $fees_bonus += $bonus->{SUM} if ($bonus->{FEE_ID});
      $payments_bonus += $bonus->{SUM} if ($bonus->{PAYMENT_ID});
      push @updated_bonuses, $bonus;
    }

    @bonuses = @updated_bonuses;
  }

  return {
    total_bonus    => $bonus_amount,
    fees_bonus     => $fees_bonus,
    payments_bonus => $payments_bonus,
    bonuses        => \@bonuses,
    bonus_bill     => $tariff_settings->{BONUS_BILL} ? 1 : 0,
  };
}

#**********************************************************
=head2 _referral_add_bonus()

=cut
#**********************************************************
sub _referral_add_bonus {
  my $self = shift;
  my ($referral) = @_;

  return {
    errno  => 4112,
    errstr => 'Not valid referral',
  } if (!$referral || ref $referral ne 'HASH');

  return {
    errno  => 4110,
    errstr => 'Not valid parameter totalBonus',
  } if (!$referral->{TOTAL_BONUS});

  return {
    errno  => 4112,
    errstr => 'Not valid parameter bonuses',
  } if (!$referral->{BONUSES} || ref $referral->{BONUSES} ne 'ARRAY');

  my $referral_info = $Users->pi({ UID => $referral->{UID} });
  $Users->info($referral->{REFERRER} || '--');

  return {
    errno  => 4111,
    errstr => 'Not valid parameter referrer',
  } if ($Users->{errno});

  $Referral->referral_bonus_multi_add({ BONUSES => $referral->{BONUSES} });

  require Bills;
  require Payments;
  my $Bills = Bills->new($self->{db}, $self->{admin}, $self->{conf});
  my $Payments = Payments->payments($self->{db}, $self->{admin}, $self->{conf});


  if (!$referral->{BONUS_BILL}) {
    $Payments->add($Users, {
      SUM      => $referral->{TOTAL_BONUS},
      METHOD   => 4,
      DESCRIBE => "$lang{BONUS_DESC} ($referral->{UID}) " . ($referral_info->{FIO} || $referral->{FIO} || ''),
    });
  }
  else {
    if (!$Users->{EXT_BILL_ID}) {
      my $bill = $Bills->create({
        DEPOSIT => $referral->{TOTAL_BONUS},
        UID     => $referral->{REFERRER}
      });

      $Users->change($referral->{REFERRER}, {
        UID         => $referral->{REFERRER},
        EXT_BILL_ID => $bill->{BILL_ID}
      });
    }
    else {
      $Bills->action('add', $Users->{EXT_BILL_ID}, $referral->{TOTAL_BONUS});
    }
  }

  $self->_referral_bonus_report_send($referral) if ($self->{conf}->{REFERRAL_SEND_BONUS_REPORT});

  return {
    result   => 'Successfully added bonus',
    referrer => $referral->{REFERRER},
    uid      => $referral->{UID}
  };
}

#**********************************************************
=head2 _referral_bonus_report_send() send bonus report

=cut
#**********************************************************
sub _referral_bonus_report_send {
  my $self = shift;
  my ($attr) = @_;

  my $referrals = $Referral->list({
    REFERRAL  => $attr->{UID},
    COLS_NAME => 1,
  });

  my @referrals_list = $referrals->[0] ? @{$referrals} : ();

  my %report = (
    referral_system => {
      withdraw  => {
        uid      => $Users->{UID},
        date     => $main::DATE,
        withdraw => $attr->{TOTAL_BONUS}
      },
      referral => \@referrals_list
    }
  );

  load_pmodule('XML::Simple');
  my $xml = XML::Simple::XMLout(\%report, KeepRoot => 1);
  my $mail = $self->{conf}->{ADMIN_MAIL};

  require AXbills::Sender::Core;
  my $Sender = AXbills::Sender::Core->new($self->{db}, $self->{admin}, $self->{conf});

  $Sender->send_message({
    SENDER_TYPE => 'Mail',
    TO_ADDRESS  => $mail,
    MESSAGE     => $xml,
    SUBJECT     => $lang{REFERRAL_SYSTEM},
    QUITE       => 1
  });

  return 1;
}

#**********************************************************
=head2 referral_registered() referral registered from user portal

=cut
#**********************************************************
sub referral_registered {
  my $self = shift;
  my ($attr) = @_;

  my $calculated_sum = $self->_referral_calculate_bonus(1, {
    REFERRER => $attr->{REFERRER},
    UID      => $attr->{UID},
    TP_ID    => $attr->{TP_ID},
  });

  $self->_referral_add_bonus({
    TOTAL_BONUS => $calculated_sum->{total_bonus},
    BONUSES     => $calculated_sum->{bonuses},
    REFERRER    => $attr->{REFERRER},
    UID         => $attr->{UID},
    BONUS_BILL  => $calculated_sum->{bonus_bill},
  });

}

#**********************************************************
=head2 referral_bonus_add()

=cut
#**********************************************************
sub referral_bonus_add {
  my $self = shift;
  my ($attr) = @_;

  my %params = ();
  $params{REFERRAL_UID} = $attr->{REFERRAL_UID} if ($attr->{REFERRAL_UID});
  $params{UID} = $attr->{UID} if ($attr->{UID});
  $params{STATUS} = 2;

  my $result = $self->referrals_list(\%params);

  if ($result && $result->{referrals_total}) {
    foreach my $referral (@{$result->{referrals}}) {
      if ($referral->{TP_INACTIVE_DAYS} > 0){
        my $check_inactive_days = _referral_check_inactive_days($referral);
        next if ($check_inactive_days);
      }
      $self->_referral_add_bonus($referral);
    }
  }

  return {
    result => 'Bonus added',
  };
}

#**********************************************************
=head2 _referral_check_inactive_days ($referral)

    Attr:
      $referral

    Return
      true or false

=cut
#**********************************************************
sub _referral_check_inactive_days {
  my ($referral) = @_;
  return if !$referral->{UID};

  my $user_info = $Users->info($referral->{UID});
  return if $user_info->{DISABLE_DATE} eq '0000-00-00';

  my $fact_inactive_days = date_diff($user_info->{DISABLE_DATE}, $DATE);
  if ($fact_inactive_days >= $referral->{TP_INACTIVE_DAYS}){
    return 1;
  }

  return;
}


1;
