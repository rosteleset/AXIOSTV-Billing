package Control::Service_control;

=head1 NAME

  Users service manage functions

=cut

use strict;
use warnings FATAL => 'all';
no warnings 'numeric';

my (
  $admin,
  $CONF,
  $db,
  $lang,
);

my AXbills::HTML $html;

require Internet;
require Users;
require Finance;
require Shedule;
require Tariffs;
my ($Internet);

my Users $Users;
my Tariffs $Tariffs;
my Shedule $Shedule;

use AXbills::Base qw(in_array date_diff cmd days_in_month next_month camelize);

#**********************************************************
# Init
#**********************************************************
sub new {
  my $class = shift;
  $db = shift;
  $admin = shift;
  $CONF = shift;
  my ($attr) = @_;

  my $self = { db => $db, admin => $admin, conf => $CONF };

  $html = $attr->{HTML} if $attr->{HTML};
  $lang = $attr->{LANG} if $attr->{LANG};

  bless($self, $class);

  $Internet = Internet->new($self->{db}, $self->{admin}, $self->{conf});
  $Users = Users->new($self->{db}, $self->{admin}, $self->{conf});
  $Shedule = Shedule->new($self->{db}, $self->{admin}, $self->{conf});
  $Tariffs = Tariffs->new($self->{db}, $self->{conf}, $self->{admin});

  return $self;
}

#**********************************************************
=head2 user_set_credit()

  Arguments:
    $attr
       UID
       REDUCTION

  Returns:
    Success:
      credit_info
    Error:
      error
      errstr

=cut
#**********************************************************
sub user_set_credit {
  my $self = shift;
  my ($attr) = @_;
	### START KTK-39
  #return { error => 4301, errstr => 'ERR_UID_NOT_DEFINED' } if (!$attr->{UID});
	### END KTK-39
  return { error => 4302, errstr => 'ERR_NO_CREDIT_CHANGE_ACCESS' } if (!$self->{conf}{user_credit_change});

  my $credit_info = { REDUCTION => $attr->{REDUCTION}, UID => $attr->{UID} };
  my $credit_rule = $attr->{CREDIT_RULE};
  my @credit_rules = split(/;/, $self->{conf}{user_credit_change});

  $Users->info($attr->{UID});
  $Users->group_info($Users->{GID});

  return { error => 4303, errstr => 'ERR_NO_CREDIT_CHANGE_ACCESS' } if ($Users->{TOTAL} > 0 && (!$Users->{ALLOW_CREDIT} || $Users->{DISABLE}));

  if ($#credit_rules > 0 && ! defined($credit_rule)) {
    $self->{CREDIT_RULES} = \@credit_rules;
    return $self;
  } 

  my ($sum, $days, $price, $month_changes, $payments_expr) = split(/:/, $credit_rules[$credit_rule || 0]);
  $credit_info->{CREDIT_DAYS} = $days || q{};
  $credit_info->{CREDIT_MONTH_CHANGES} = $month_changes || q{};

  $sum = $self->_get_credit_limit($credit_info) if (!$sum || ($sum =~ /\d+/ && $sum == 0));

  #Credit functions
  $month_changes = 0 if (!$month_changes);
  my $credit_date = POSIX::strftime("%Y-%m-%d", localtime(time + int($days || 0) * 86400));

  if ($month_changes && $main::DATE) {
    my ($y, $m) = split(/\-/, $main::DATE);
    $admin->action_list({
      UID       => $attr->{UID},
      TYPE      => 5,
      AID       => $admin->{AID},
      FROM_DATE => "$y-$m-01",
      TO_DATE   => "$y-$m-31"
    });

    if ($admin->{TOTAL} >= $month_changes) {
      return { error => 4304, errstr => 'ERR_CREDIT_CHANGE_LIMIT_REACH', MONTH_CHANGES => $month_changes };
    }
  }
  $credit_info->{CREDIT_SUM} = sprintf("%.2f", $sum);

  $sum = $self->_check_payments_exp($attr->{UID}, $payments_expr) if ($payments_expr && $sum != 1);
	### START КТК-39 ###
  return { errstr => 'ERR_CREDIT_UNAVAILABLE' } if ($Users->{CREDIT} >= sprintf("%.2f", $sum));
	### END ### КТК-39 ### ###
  if ($attr->{change_credit}) {
    if ($CONF->{user_confirm_changes}) {
      return {} if !$attr->{PASSWORD};

      $Users->info($attr->{UID}, { SHOW_PASSWORD => 1 });
      if ($attr->{PASSWORD} ne $Users->{PASSWORD}) {
        $self->_show_message('err', '$lang{ERROR}', '$lang{ERR_WRONG_PASSWD}');
        return { error => 4306, errstr => 'ERR_WRONG_PASSWD' };
      }
    }
    $Users->change($attr->{UID}, { UID => $attr->{UID}, CREDIT => $sum, CREDIT_DATE => $credit_date });

    return { error => $Users->{errno}, errstr => $Users->{errstr} } if $Users->{errno};

    my $user_info = $Users->info($attr->{UID}, { SHOW_PASSWORD => 1 });
    $self->_show_message('info', '$lang{CHANGED}', '$lang{CREDIT}: ' . $sum);
    if ($price && $price > 0) {
      my $Fees = Finance->fees($db, $admin, $CONF);
      $Fees->take($Users, $price, { DESCRIBE => ::_translate('$lang{CREDIT} $lang{ENABLE}'), METHOD => 5 });
    }

																			
    ::cross_modules('payments_maked', { USER_INFO => $user_info, SUM => $sum, SILENT => 1, CREDIT_NOTIFICATION => 1 });
    if ($CONF->{external_userchange}) {
      return () if (!::_external($CONF->{external_userchange}, $user_info));
    }

    return $credit_info;
  }

  $credit_info->{CREDIT_CHG_PRICE} = sprintf("%.2f", $price);
  $credit_info->{CREDIT_SUM} = sprintf("%.2f", $sum);
  $credit_info->{OPEN_CREDIT_MODAL} = $attr->{OPEN_CREDIT_MODAL} || '';

  return $credit_info;
}

#**********************************************************
=head2 internet_add_compensation()

  Arguments:
    $attr
       UID
       FROM_DATE
       TO_DATE
       HOLD_UP
       DESCRIBE
       INNER_DESCRIBE

  Returns:
    TABLE_ROWS
    SUM
    DAYS

=cut
#**********************************************************
sub internet_add_compensation {
  my $self = shift;
  my ($attr) = @_;

  return () if !$attr->{FROM_DATE} || !$attr->{TO_DATE} || !$attr->{UID};

  my ($FROM_Y, $FROM_M, $FROM_D) = split(/-/, $attr->{FROM_DATE}, 3);
  my ($TO_Y, $TO_M, $TO_D) = split(/-/, $attr->{TO_DATE}, 3);
  my $sum = 0.00;
  my $days = 0;
  my $days_in_month = 31;
  my @table_rows = ();

  $Users->info($attr->{UID});
  $Internet->user_info($attr->{UID});
  $Internet->{DAY_ABON} ||= 0;
  $Internet->{MONTH_ABON} ||= 0;

  my $month_abon = $Internet->{MONTH_ABON} || 0;
  $month_abon = $Internet->{PERSONAL_TP} if ($Internet->{PERSONAL_TP} && $Internet->{PERSONAL_TP} > 0);

  if ($Internet->{ACTIVATE} && $Internet->{ACTIVATE} ne '0000-00-00') {
    $days = date_diff($attr->{FROM_DATE}, $attr->{TO_DATE});
    $sum = $days * ($month_abon / 30);
    if ($Internet->{DAY_ABON} > 0 && !$attr->{HOLD_UP}) {
      $sum += $days * $Internet->{DAY_ABON};
    }
  }
  else {
    if ("$FROM_Y-$FROM_M" eq "$TO_Y-$TO_M") {
      $days = $TO_D - $FROM_D + 1;
      $days_in_month = days_in_month({ DATE => "$FROM_Y-$FROM_M-01" });
      $sum = sprintf("%.2f", $days * ($Internet->{DAY_ABON}) + $days * (($month_abon || 0) / $days_in_month));
      push(@table_rows, [ "$FROM_Y-$FROM_M", $days, $sum ]);
    }
    else {
      $FROM_D--;
      do {
        $days_in_month = days_in_month({ DATE => "$FROM_Y-$FROM_M-01" });
        my $month_days = ($FROM_M == $TO_M) ? $TO_D : $days_in_month - $FROM_D;
        $FROM_D = 0;
        my $month_sum = sprintf("%.2f",
          $month_days * $Internet->{DAY_ABON} + $month_days * ($month_abon / $days_in_month));
        $sum += $month_sum;
        $days += $month_days;
        push(@table_rows, [ "$FROM_Y-$FROM_M", $month_days, $month_sum ]);

        if ($FROM_M < 12) {
          $FROM_M = sprintf("%02d", $FROM_M + 1);
        }
        else {
          $FROM_M = sprintf("%02d", 1);
          $FROM_Y += 1;
        }

        return { RETURN_HOLDUP => "HOLLDDDD", SUM => $sum, DAYS => $days } if ($attr->{HOLD_UP});
      } while (($FROM_Y < $TO_Y) || ($FROM_M <= $TO_M && $FROM_Y == $TO_Y));
    }
  }

  $sum = $sum - (($sum / 100) * $Users->{REDUCTION}) if ($Users->{REDUCTION});

  if ($Internet->{ACTIVATE} && $Internet->{ACTIVATE} ne '0000-00-00') {
    my $days_to_holdup = date_diff($main::DATE, $attr->{TO_DATE});
    $sum = 0 if ($attr->{HOLD_UP} && $days_to_holdup > 30);
  }
  else {
    $attr->{FROM_DATE} =~ m/(\d{2}\-\d{2})/;
    my $from_date = $1 || '';
    $main::DATE =~ m/(\d{2}\-\d{2})/;
    my $cur_date = $1 || '';
    $sum = 0 if ($from_date ne $cur_date && $attr->{HOLD_UP});
  }

  if ($sum > 0) {
    require Payments;
    my $Payments = Payments->new($db, $admin, $CONF);
    $Payments->add({ BILL_ID => $Users->{BILL_ID}, UID => $attr->{UID} }, {
      SUM            => $sum,
      METHOD         => 6,
      DESCRIBE       => ::_translate('$lang{COMPENSATION}. $lang{DAYS}:' .
        "$attr->{FROM_DATE}/$attr->{TO_DATE} ($days)" . (($attr->{DESCRIBE}) ? ". $attr->{DESCRIBE}" : '')),
      INNER_DESCRIBE => $attr->{INNER_DESCRIBE}
    });

    return { errno => $Payments->{errno}, errstr => $Payments->{errstr}, MODULE => 'Payments' } if ($Payments->{errno});
  }

  return {
    TABLE_ROWS => \@table_rows,
    SUM        => $sum,
    DAYS       => $days
  };
}

#**********************************************************
=head2 user_holdup()

  Arguments:
    $attr
       UID
       ID  - Internet Service ID
       USER_INFO - user_info_obj

  Returns:
    Success:

    Error:
      error
      errstr

=cut
#**********************************************************
sub user_holdup {
  my $self = shift;
  my ($attr) = @_;

  return { error => 4401, errstr => 'ERR_UID_NOT_DEFINED' } if (!$attr->{UID});

  return $self->_iptv_holdup_functions($attr) if ($attr->{MODULE} && uc($attr->{MODULE}) eq 'IPTV');

  my $user_info = $attr->{USER_INFO} || $Users->info($attr->{UID});
  my $internet_info;
  my $status = 0;
  if ($CONF->{HOLDUP_ALL}) {
    $CONF->{INTERNET_USER_SERVICE_HOLDUP}=$CONF->{HOLDUP_ALL};
    $status = $user_info->{DISABLE};
  }
  else {
    return { error => 4402, errstr => 'ERR_INTERNET_ID_NOT_DEFINED' } if (!$attr->{ID});
    return { error => 4403, errstr => 'ERR_NO_SERVICE_HOLDUP_ACCESS' } if (!$CONF->{INTERNET_USER_SERVICE_HOLDUP});
    $internet_info = $Internet->user_info($attr->{UID}, { ID => $attr->{ID} });
    $status = $internet_info->{DISABLE};
    if (!$Internet->{TOTAL} || $Internet->{TOTAL} < 1) {
      return { error => 4406, errstr => 'ERR_NO_SERVICE_ID' };
    }
    elsif ($attr->{add} && $Internet->{STATUS}) {
      return { error => 4409, errstr => 'ERR_NOT_ALLOWED' };
    }
    return q{} if ($CONF->{HOLDUP_ALL});
  }

  my $block_days = 0;
  if ($attr->{FROM_DATE} && $attr->{TO_DATE}) {
    my $err_msg = '';
    my $errstr = '';
    my $err_status = 0;
    my ($from_year, $from_month, $from_day) = split(/-/, $attr->{FROM_DATE}, 3);
    my ($to_year, $to_month, $to_day) = split(/-/, $attr->{TO_DATE}, 3);

    if (!$from_day || !$from_month || !$from_year) {
      $err_msg = '$lang{ERR_WRONG_DATA}\n $lang{FROM}: ' . $attr->{FROM_DATE};
      $errstr = "Wrong param fromDate $attr->{FROM_DATE}";
      $err_status = 4426;
    }
    elsif (!$to_year || !$to_month || !$to_day) {
      $err_msg = '$lang{ERR_WRONG_DATA}\n $lang{TO}: ' . $attr->{TO_DATE};
      $errstr = "Wrong param toDate $attr->{TO_DATE}";
      $err_status = 4427;
    }

    if ($err_msg) {
      $self->_show_message('err', '$lang{ERR_WRONG_DATA}', $err_msg);
      return { error => $err_status, errstr => $errstr };
    }

   $block_days = date_diff($attr->{TO_DATE}, $attr->{FROM_DATE});
  }

  my @holdup_rules = split(/;/, $CONF->{INTERNET_USER_SERVICE_HOLDUP});
  my ($hold_up_min_period, $hold_up_max_period, $hold_up_period, $hold_up_day_fee,
    undef, $active_fees, $holdup_skip_gids, $user_del_shedule, $expr_);

  foreach my $holdup_rule (@holdup_rules) {
    my ($_hold_up_min_period, $_hold_up_max_period, $_hold_up_period, $_hold_up_day_fee,
      undef, $_active_fees, $_holdup_skip_gids, $_user_del_shedule, $_expr_) = split(/:/, $holdup_rule);

#  if (!$attr->{add} || ($block_days && $block_days < $_hold_up_max_period)) {
    if (!$attr->{add} || ($block_days && $_hold_up_max_period && $block_days < $_hold_up_max_period)) {
      ($hold_up_min_period, $hold_up_max_period, $hold_up_period, $hold_up_day_fee,
        undef, $active_fees, $holdup_skip_gids, $user_del_shedule, $expr_) =
        ($_hold_up_min_period, $_hold_up_max_period, $_hold_up_period, $_hold_up_day_fee,
          undef, $_active_fees, $_holdup_skip_gids, $_user_del_shedule, $_expr_);

      last;
    }

    push @{$self->{HOLDUP_INFOS}}, {
      MAX_PERIOD => $_hold_up_max_period,
      PRICE      => $_active_fees
    };
  }

  if ($holdup_skip_gids) {
    my @holdup_skip_gids_arr = split(/,\s?/, $holdup_skip_gids);
    if ($user_info->{GID} && in_array($user_info->{GID}, \@holdup_skip_gids_arr)) {
      return { error => 4404, errstr => 'ERR_WRONG_GID' };
    }
  }

  my $check_exp_result = $self->_check_holdup_exp($expr_, $user_info);
  return $check_exp_result if ($check_exp_result->{error});

  if ($attr->{add} && $active_fees && $active_fees > 0 && $user_info->{DEPOSIT} < $active_fees) {
    $self->_show_message('err', '$lang{HOLD_UP}', '$lang{ERR_SMALL_DEPOSIT}');
    return { error => 4407, errstr => 'ERR_SMALL_DEPOSIT' };
  }

  if ($hold_up_day_fee && $hold_up_day_fee > 0) {
    $internet_info->{DAY_FEES} = ::_translate('$_' .'DAY_FEE') . ": " . sprintf("%.2f", $hold_up_day_fee);
  }

  if ($attr->{del} && $user_del_shedule) {
    return $self->_del_holdup({ %{$attr}, INTERNET_STATUS => $internet_info->{DISABLE} });
  }

  if ($attr->{add} && $attr->{ACCEPT_RULES}) {
    return $self->_add_holdup({
      %{$attr},
      HOLD_UP_MAX_PERIOD => $hold_up_max_period,
      HOLD_UP_MIN_PERIOD => $hold_up_min_period,
      MODULE             => ($CONF->{HOLDUP_ALL}) ? 'ALL' : undef
    });
  }

  my ($y, $m) = split(/\-/, $main::DATE);
  if ($hold_up_max_period && $CONF->{INTERNET_USER_SERVICE_HOLDUP_MP}) {
    $self->{TO_DATE} = POSIX::strftime("%Y-%m-%d", localtime(time + 86400 * $hold_up_max_period));
  }

  if ($hold_up_period) {
    my $action_list = $admin->action_list({
      UID       => $attr->{UID},
	  TYPE      => '14',
      DATETIME  => '_SHOW',
      FROM_DATE => ($CONF->{INTERNET_USER_SERVICE_HOLDUP_MP}) ? "$y-$m-01" : POSIX::strftime("%Y-%m-%d", localtime(time - 86400 * $hold_up_period)),
      DATE      => '_SHOW',
      TO_DATE   => $main::DATE,
	  ACTIONS   => '*->3',
      COLS_NAME => 1
    });

    #If holdup period not expire can't holdup
    if ($admin->{TOTAL} > 0) {
      my $hold_up_days  = 0;
      my $min_period    = 0;
	  
      foreach my $action (@$action_list) {
	if ($action->{action_type} == 14) {
		$min_period = date_diff($action->{date}, $main::DATE);
        }
      }

	if ($min_period <= $hold_up_period) {
        return { error => 4410, errstr => 'HOLDUP_PERIOD_NOT_EXPIRE' };
      }
	  ### START КТК-39 ###
      if($CONF->{INTERNET_USER_SERVICE_HOLDUP_MP}) {
      ### END КТК-39 ### elsif($CONF->{INTERNET_USER_SERVICE_HOLDUP_MP}) {
         $self->{TO_DATE} = POSIX::strftime("%Y-%m-%d", localtime(time + 86400 * ($hold_up_max_period - $hold_up_days)))
       }
    }
  }

  my ($del_ids, $shedule_date) = $self->_get_holdup_ids($attr->{UID}, $attr->{ID});

  if ($Shedule->{TOTAL} && $Shedule->{TOTAL} > 0 && !$status) {
    return {
      DEL           => 1,
      DEL_IDS       => (($Shedule->{TOTAL} > 1 && $user_del_shedule) ? $del_ids : ''),
      DATE_FROM     => $shedule_date->{3} || '-',
      DATE_TO       => $shedule_date->{0} || '-',
      CAN_CANCEL    => $user_del_shedule ? 'true' : 'false'
    };
  }

  return ();
}

#**********************************************************
=head2 available_tariffs()

  Arguments:
    $attr
       UID
       MODULE
       SKIP_NOT_AVAILABLE_TARIFFS
       ADD_FIRST_SERVICE

  Returns:
    \@tariffs

=cut
#**********************************************************
sub available_tariffs {
  my $self = shift;
  my ($attr) = @_;

  if ($attr->{ADD_FIRST_SERVICE}) {
    return $self->_get_tariffs($attr, { TP_ID => 0, SERVICE_ID => $attr->{SERVICE_ID} || '--' }, $Users->info($attr->{UID}));
  }

  return {
    message       => '$lang{NOT_ALLOWED_TO_CHANGE_TP}',
    message_type  => 'err',
    message_title => '$lang{ERROR}',
    error         => 4504,
    errstr        => 'Not allowed to change tariff plan',
  } if (!$CONF->{uc $attr->{MODULE} . '_USER_CHG_TP'});

  my $service_info = $self->_service_info($attr);
  return $service_info if $service_info->{errno};

  my $user_info = $Users->info($attr->{UID});

  if ($user_info->{GID}) {
    $Users->group_info($user_info->{GID});
    if ($user_info->{DISABLE_CHG_TP}) {
      return {
        error   => 4505,
        errstr  => 'Not allowed to change tariff plan',
        message => '$lang{NOT_ALLOWED_TO_CHANGE_TP}',
        MODULE  => $attr->{MODULE}
      };
    }
  }

  if ($service_info->{UID} && $attr->{UID} ne $service_info->{UID}) {
    return {
      error   => 4520,
      errstr  => 'Unknown parameter id',
      message => '$lang{NOT_ALLOWED_TO_CHANGE_TP}',
      MODULE  => $attr->{MODULE}
    };
  }

  $Tariffs->tp_group_info($service_info->{TP_GID});
  if (!$Tariffs->{USER_CHG_TP}) {
    return {
      error   => 4506,
      errstr  => 'Not allowed to change tariff plan',
      message => '$lang{NOT_ALLOWED_TO_CHANGE_TP}',
      MODULE  => $attr->{MODULE}
    };
  }

  return $self->_get_tariffs($attr, $service_info, $user_info);
}

#***************************************************************
=head2 service_warning($attr) - Show warning message and tips

  Arguments:
    $attr
      SERVICE - Service object
      USER     - User object
      DATE     - Cur date
      USER_PORTAL - Call from user portal

  Return:
    {
      WARNING      => $warning,
      MESSAGE_TYPE => $message_type
    }

  Examples:

     $self->service_warning({
       ID     => $Internet->{ID},
       UID    => $uid,
       DATE   => '2017-12-01',
       MODULE => 'Internet'
     });

     $self->service_warning({
       SERVICE_INFO => $Internet->{ID},
       USER_INFO    => $user,
       DATE         => '2017-12-01',
       MODULE       => 'Internet'
     });

=cut
#***************************************************************
sub service_warning {
  my $self = shift;
  my ($attr) = @_;

  my $service_info = $attr->{SERVICE_INFO} || $self->_service_info($attr);
  return $service_info if $service_info->{errno};

  my $user_info = $attr->{USER_INFO} || $Users->info($attr->{UID});
  my $warning = '';
  my $message_type = 'info';
  my %return_info = ();

  $main::DATE = $attr->{DATE} if ($attr->{DATE});
  $user_info->{DEPOSIT} = 0 if (!$user_info->{DEPOSIT} || $user_info->{DEPOSIT} !~ /^[0-9\.\,\-]+$/);
  $user_info->{CREDIT} ||= $user_info->{COMPANY_CREDIT} || 0;
  $self->{DAYS_TO_FEE} = 0;

  if ($service_info->{EXPIRE} && $service_info->{EXPIRE} ne '0000-00-00') {
    my $expire = date_diff($service_info->{EXPIRE}, $main::DATE);
    if ($expire >= 0) {
      $warning = ::_translate('$lang{EXPIRE}') . ": $service_info->{EXPIRE}";
      $message_type = 'err';
      return {
        WARNING      => $warning,
        MESSAGE_TYPE => $message_type
      };
    }

    $message_type = 'warn';
    $warning = ::_translate('$lang{EXPIRE}') . ": $service_info->{EXPIRE}";
  }
  elsif ($service_info->{JOIN_SERVICE} && $service_info->{JOIN_SERVICE} > 1) {
    $message_type = 'warn';
    return {
      WARNING      => $warning,
      MESSAGE_TYPE => $message_type
    };
  }

  if ($service_info->{PERSONAL_TP} && $service_info->{PERSONAL_TP} > 0) {
    $service_info->{MONTH_ABON} = $service_info->{PERSONAL_TP};
  }

  $user_info->{REDUCTION} = 0 if (!$service_info->{REDUCTION_FEE} || !$user_info->{REDUCTION});
  my $reduction_division = ($user_info->{REDUCTION} && $user_info->{REDUCTION} >= 100) ? 0 : ((100 - $user_info->{REDUCTION}) / 100);

  if ($self->{conf}{uc $attr->{MODULE} . '_WARNING_EXPR'}) {
    if ($self->{conf}{uc $attr->{MODULE} . '_WARNING_EXPR'} =~ /CMD:(.+)/) {
      $warning = ::cmd($1, {
        PARAMS => {
          language    => $html ? $html->{language} : 'english',
          USER_PORTAL => $attr->{USER_PORTAL},
          %{$user_info},
          %{$service_info}
        }
      });
    }
  }
  elsif (!$reduction_division) {
    return {
      WARNING      => '',
      MESSAGE_TYPE => $message_type
    };
  }
  # Get next payment period
  elsif (
    (!$service_info->{STATUS} || $service_info->{STATUS} == 10)
      && !$user_info->{DISABLE}
      && ($user_info->{DEPOSIT} + (($user_info->{CREDIT} && $user_info->{CREDIT} > 0) ?
      $user_info->{CREDIT} : ($service_info->{TP_CREDIT} || 0)) > 0
      || ($service_info->{POSTPAID_ABON} || 0)
      || ($service_info->{PAYMENT_TYPE} && $service_info->{PAYMENT_TYPE} == 1))
  ) {
    my $days_to_fee = 0;
    my ($from_year, $from_month, $from_day) = split(/-/, $main::DATE, 3);
    if ($service_info->{MONTH_ABON} && $service_info->{MONTH_ABON} > 0) {
      if ($service_info->{ABON_DISTRIBUTION} && $service_info->{MONTH_ABON} > 0) {
        my $days_in_month = 30;

        if ($service_info->{ACTIVATE} eq '0000-00-00') {
          my ($y, $m, $d) = split(/-/, $main::DATE);
          $return_info{ACTIVATE_DATE} = "$y-$m-01";
          my $rest_days = 0;
          my $rest_day_sum = 0;
          my $deposit = $user_info->{DEPOSIT} + $user_info->{CREDIT};

          while ($rest_day_sum < $deposit) {
            $days_in_month = days_in_month({ DATE => "$y-$m" });
            my $month_day_fee = ($service_info->{MONTH_ABON} * $reduction_division) / $days_in_month;
            $rest_days = $days_in_month - $d;
            $rest_day_sum = $rest_days * $month_day_fee;

            if ($rest_day_sum > $deposit) {
              $days_to_fee += int($deposit / $month_day_fee);
            }
            else {
              $deposit = $deposit - $month_day_fee * $rest_days;
              $days_to_fee += $rest_days;
              $rest_day_sum = 0;
              $d = 1;
              $m++;
              if ($m > 12) {
                $m = 1;
                $y++;
              }
            }
          }
        }
        else {
          $days_to_fee = int(($user_info->{DEPOSIT} + $user_info->{CREDIT}) /
            (($service_info->{MONTH_ABON} * $reduction_division) / $days_in_month));
          $return_info{ACTIVATE_DATE} = $service_info->{ACTIVATE};
        }
        $warning = ::_translate('$lang{SERVICE_ENDED}') || q{};
      }
      else {
        if ($service_info->{ACTIVATE} && $service_info->{ACTIVATE} ne '0000-00-00') {
          $return_info{ACTIVATE_DATE} = $service_info->{ACTIVATE};
          my ($Y, $M, $D) = split(/-/, $service_info->{ACTIVATE}, 3);
          if ($service_info->{FIXED_FEES_DAY}) {
            if ($M == 12) {
              $M = 0;
              $Y++;
            }

            $self->{ABON_DATE} = POSIX::strftime("%Y-%m-%d", localtime(POSIX::mktime(0, 0, 12, $D, $M, ($Y - 1900), 0, 0, 0)));
          }
          else {
            $M--;
            $self->{ABON_DATE} = POSIX::strftime("%Y-%m-%d", localtime((POSIX::mktime(0, 0, 12, $D, $M, ($Y - 1900), 0, 0, 0) + 31 * 86400)));
          }
        }
        else {
          my ($Y, $M, $D) = split(/-/, $main::DATE, 3);
          $return_info{ACTIVATE_DATE} = "$Y-$M-01";
          if ($self->{conf}{START_PERIOD_DAY} && $self->{conf}{START_PERIOD_DAY} > $D) {
          }
          else {
            $M++;
          }

          if ($M == 13) {
            $M = 1;
            $Y++;
          }
          if ($self->{conf}{START_PERIOD_DAY}) {
            $D = $self->{conf}{START_PERIOD_DAY};
          }
          else {
            $D = '01';
          }
          $self->{ABON_DATE} = sprintf("%d-%02d-%02d", $Y, $M, $D);
        }

        $days_to_fee = date_diff($main::DATE, $self->{ABON_DATE});
        if ($days_to_fee > 0) {
          $warning = ::_translate('$lang{NEXT_FEES_THROUGHT}');
        }
      }
    }
    elsif ($service_info->{DAY_ABON} && $service_info->{DAY_ABON} > 0) {
      $return_info{ACTIVATE_DATE} = '0000-00-00';
      $days_to_fee = int(($user_info->{DEPOSIT} + $user_info->{CREDIT} > 0) ?
        ($user_info->{DEPOSIT} + $user_info->{CREDIT}) / ($service_info->{DAY_ABON} * $reduction_division) : 0);
      $warning = ::_translate('$lang{SERVICE_ENDED}');
    }

    if ($days_to_fee && $days_to_fee < 5) {
      $message_type = 'warn';
    }
    elsif ($days_to_fee eq 0) {
      $message_type = 'err' if (!$message_type);
    }
    else {
      $message_type = 'success';
    }

    if ($service_info->{EXPIRE} && $service_info->{EXPIRE} ne '0000-00-00') {
      my $to_expire = date_diff($main::DATE, $service_info->{EXPIRE});
      if ($days_to_fee > $to_expire) {
        $days_to_fee = $to_expire;
      }
    }

    $self->{DAYS_TO_FEE} = $days_to_fee;
    $warning =~ s/\%DAYS\%/$days_to_fee/g;

    if ($days_to_fee > 0) {
      #Calculate days from net day
      my $expire_date = POSIX::strftime("%Y-%m-%d", localtime(POSIX::mktime(0, 0, 12, $from_day, ($from_month - 1), ($from_year - 1900))
        + 86400 * $days_to_fee + (($service_info->{DAY_ABON} && $service_info->{DAY_ABON} > 0) ? 86400 : 0)));
      $self->{ABON_DATE} = $expire_date;
      $warning =~ s/\%EXPIRE_DATE\%/$expire_date/g;
      if ($service_info->{MONTH_ABON} && $service_info->{MONTH_ABON} > 0) {
        $warning .= "\n" . ::_translate('$lang{SUM}') . ": " . sprintf("%.2f", $service_info->{MONTH_ABON} * $reduction_division);
        $return_info{SUM} = $service_info->{MONTH_ABON} * $reduction_division;
      }
    }
    $return_info{DAYS_TO_FEE} = $days_to_fee;
    $return_info{ABON_DATE} = $self->{ABON_DATE};
  }

  return {
    WARNING      => $warning,
    MESSAGE_TYPE => $message_type,
    %return_info
  };
}

#***************************************************************
=head2 user_chg_tp($attr) - change user tp from user portal

  Arguments:
    $attr
      SERVICE_INFO - Service object
      UID
      MODULE
      ID
      TP_ID
      DATE
      period
        0 - $conf{INTERNET_USER_CHG_TP_NOW}
        1 - $conf{INTERNET_USER_CHG_TP_NEXT_MONTH}
        2 - $conf{INTERNET_USER_CHG_TP_SHEDULE}

  Return:
    SUCCESS:
      {
        success => 1,
        UID     => 195
      }
    ERROR:
      {
        message       => '$lang{ERR_WRONG_PASSWD}',
        message_type  => 'err',
        message_title => '$lang{ERROR}',
        error         => 4508
      }

=cut
#***************************************************************
sub user_chg_tp {
  my $self = shift;
  my ($attr) = @_;

  my $service_info = $attr->{SERVICE_INFO} || $self->_service_info($attr);
  return $service_info if $service_info->{error};

  return {
    message       => '$lang{NOT_ALLOWED_TO_CHANGE_TP}',
    message_type  => 'err',
    message_title => '$lang{ERROR}',
    error         => 139,
    errstr        => 'Unknown service to change',
  } if ($service_info->{errno});

  $attr->{period} ||= $attr->{PERIOD};

  $attr->{UID} ||= $service_info->{UID};
  my $user_info = $Users->info($attr->{UID}, { SHOW_PASSWORD => 1 });
  $Users->group_info($user_info->{GID}) if ($user_info->{GID});
  $Tariffs->tp_group_info($service_info->{TP_GID});

  if (!$CONF->{uc($attr->{MODULE}) . '_USER_CHG_TP'} || $Users->{DISABLE_CHG_TP} || !$Tariffs->{USER_CHG_TP}) {
    return {
      message       => '$lang{NOT_ALLOWED_TO_CHANGE_TP}',
      message_type  => 'err',
      message_title => '$lang{ERROR}',
      error         => 140,
      errstr        => 'Not allowed to change tariff plan',
    };
  }

  my $next_abon = $self->get_next_abon_date({ SERVICE_INFO => $service_info, MODULE => $attr->{MODULE} });
  return $next_abon if !$next_abon->{ABON_DATE};

  $service_info->{ABON_DATE} = $next_abon->{ABON_DATE};

  if ($CONF->{user_confirm_changes}) {
    $Users->info($attr->{UID}, { SHOW_PASSWORD => 1 });
    return {
      message       => '$lang{ERR_WRONG_PASSWD}',
      message_type  => 'err',
      message_title => '$lang{ERROR}',
      error         => 4508,
      errstr        => 'Wrong password',
    } if !$attr->{PASSWORD} || $attr->{PASSWORD} ne $Users->{PASSWORD};
  }

  return {
    message       => '$lang{ERR_WRONG_DATA}: $lang{TARIF_PLAN}',
    message_type  => 'err',
    message_title => '$lang{ERROR}',
    error         => 141,
    errstr        => 'Unknown tpId',
  } if (!$attr->{TP_ID} || $attr->{TP_ID} < 1);

  return {
    message       => '$lang{ERR_WRONG_DATA}: $lang{ERR_NO_DATA}: ID',
    message_type  => 'err',
    message_title => '$lang{ERROR}',
    error         => 4509,
    errstr        => 'Unknown id',
  } if !$attr->{ID};

  return {
    message       => '$lang{ERR_WRONG_DATA}: $lang{TARIF_PLAN}',
    message_type  => 'err',
    message_title => '$lang{ERROR}',
    error         => 4521,
    errstr        => 'This tpId already active in user',
  } if ($service_info->{TP_ID} && $service_info->{TP_ID} eq $attr->{TP_ID});

  if (uc($attr->{MODULE}) eq 'IPTV') {
    require Iptv;
    Iptv->import();

    my $Iptv = Iptv->new($self->{db}, $self->{admin}, $self->{conf});
    $Iptv->services_list({ USER_PORTAL => 2, ID => $service_info->{SERVICE_ID} });

    my $tariffs = $self->available_tariffs({
      SKIP_NOT_AVAILABLE_TARIFFS => 1,
      UID                        => $attr->{UID},
      MODULE                     => 'Iptv',
      ID                         => $attr->{ID},
    });

    if ($tariffs) {
      return $tariffs if (ref $tariffs eq 'HASH');

      my $allowed = 0;
      foreach my $tariff (@{$tariffs}) {
        next if (!$tariff->{tp_id} || $tariff->{tp_id} ne $attr->{TP_ID});
        $allowed = 1;
        last;
      }

      return {
        message       => '$lang{ERR_WRONG_DATA}: $lang{TARIF_PLAN}',
        message_type  => 'err',
        message_title => '$lang{ERROR}',
        errno         => 4513,
        errstr        => 'Unknown tpId',
      } if (!$allowed);
    }
    else {
      return {
        message       => '$lang{ERR_WRONG_DATA}: $lang{TARIF_PLAN}',
        message_type  => 'err',
        message_title => '$lang{ERROR}',
        errno         => 4515,
        errstr        => 'Unknown tpId',
      };
    }
  }

  my $chg_tp_result = $self->_chg_tp_nperiod({ %{$attr}, SERVICE => $service_info });
  return $chg_tp_result if $chg_tp_result && ref($chg_tp_result) eq 'HASH';

  $chg_tp_result = $self->_chg_tp_shedule({ %{$attr}, SERVICE => $service_info });
  return $chg_tp_result if $chg_tp_result && ref($chg_tp_result) eq 'HASH';

  if ($user_info->{CREDIT} + $user_info->{DEPOSIT} < 0) {
    return {
      message       => '$lang{ERR_SMALL_DEPOSIT}- $lang{DEPOSIT}: ' . $user_info->{DEPOSIT} . ' $lang{CREDIT}: ' . $user_info->{CREDIT},
      message_type  => 'err',
      message_title => '$lang{ERROR}',
      error         => 15,
      errstr        => "Small deposit - deposit $user_info->{DEPOSIT} and credit $user_info->{CREDIT}",
    };
  }
  delete $service_info->{ABON_DATE};

  #Next period change
  if (($service_info->{MONTH_ABON} > 0 || $self->{conf}->{uc($attr->{MODULE}) .'_USER_CHG_TP_NEXT_MONTH'}) && !$service_info->{STATUS} && !$user_info->{DISABLE} && !$service_info->{ABON_DISTRIBUTION}) {
    if ($service_info->{ACTIVATE} && $service_info->{ACTIVATE} ne '0000-00-00') {
      my ($Y, $M, $D) = split(/-/, $service_info->{ACTIVATE}, 3);
      $M--;
      $service_info->{ABON_DATE} = POSIX::strftime("%Y-%m-%d", localtime((POSIX::mktime(0, 0, 0, $D, $M, ($Y - 1900), 0, 0, 0) +
        31 * 86400 + (($CONF->{START_PERIOD_DAY}) ? $CONF->{START_PERIOD_DAY} * 86400 : 0))));
    }
    else {
      my ($Y, $M, $D) = split(/-/, $main::DATE, 3);
      $M++;
      if ($M == 13) {
        $M = 1;
        $Y++;
      }

      $D = $CONF->{START_PERIOD_DAY} ? sprintf("%02d", $CONF->{START_PERIOD_DAY}) : '01';
      $service_info->{ABON_DATE} = sprintf("%d-%02d-%02d", $Y, $M, $D);
    }
  }

  if ($service_info->{ABON_DATE} && !$CONF->{uc($attr->{MODULE}) . '_USER_CHG_TP_NOW'}) {
    my ($year, $month, $day) = split(/-/, $service_info->{ABON_DATE}, 3);
    my $seltime = POSIX::mktime(0, 0, 0, $day, ($month - 1), ($year - 1900));

    return {
      message       => '$lang{ERR_WRONG_DATA}: ' . "($year, $month, $day)/$seltime-" . time(),
      message_type  => 'info',
      message_title => '$lang{INFO}',
      error         => 40041,
      errstr        => "Wrong date ($year, $month, $day)/$seltime-" . time(),
    } if ($seltime <= time());

    if ($attr->{date_D} && $attr->{date_D} > ($month != 2 ? (($month % 2) ^ ($month > 7)) + 30 :
      (!($year % 400) || !($year % 4) && ($year % 25) ? 29 : 28))) {
      return {
        message       => '$lang{ERR_WRONG_DATA}: ' . "($year-$month-$day)",
        message_type  => 'info',
        message_title => '$lang{INFO}',
        error         => 40042,
        errstr        => "Wrong date ($year-$month-$day)",
      };
    }

    $Shedule->add({
      UID      => $attr->{UID},
      TYPE     => 'tp',
      ACTION   => "$attr->{ID}:$attr->{TP_ID}",
      D        => $day,
      M        => $month,
      Y        => $year,
      MODULE   => $attr->{MODULE},
      COMMENTS => ::_translate('$lang{FROM}') . ": $service_info->{TP_ID}:$service_info->{TP_NAME}"
    });

    return $Shedule->{errno} ? {
      message       => $Shedule->{errstr},
      message_type  => 'err',
      message_title => '$lang{ERROR}',
      error         => $Shedule->{errno},
      errstr        => 'Error occurred during operation'
    } : { success => 1, UID => $attr->{UID}, ID => $attr->{ID} };
  }

  return $self->_chg_tp_immediately({ %{$attr}, SERVICE => $service_info });
}

#***************************************************************
=head2 del_user_chg_shedule($attr) - del user shedule change tp

  Arguments:
    $attr
      UID
      SHEDULE_ID

  Return:
    SUCCESS:
      {
        success => 1,
        UID     => 195
      }
    ERROR:
      {
        message       => $Shedule->{errstr},
        message_type  => 'err',
        message_title => '$lang{ERROR}',
        error         => $Shedule->{errno}
      }

=cut
#***************************************************************
sub del_user_chg_shedule {
  my $self = shift;
  my ($attr) = @_;

  return {
    message       => '$lang{ERR_NO_DATA}',
    message_type  => 'err',
    message_title => '$lang{ERROR}',
    error         => 4501,
    errstr        => 'No data'
  } if (!$attr->{UID} || !$attr->{SHEDULE_ID});

  if ($CONF->{user_confirm_changes}) {
    $Users->info($attr->{UID}, { SHOW_PASSWORD => 1 });

    return {
      message       => '$lang{ERR_WRONG_PASSWD}',
      message_type  => 'err',
      message_title => '$lang{ERROR}',
      error         => 4306,
      errstr        => 'Wrong password'
    } if !$attr->{PASSWORD} || $attr->{PASSWORD} ne $Users->{PASSWORD};
  }

  $Shedule->del({ UID => $attr->{UID} || '-', ID => $attr->{SHEDULE_ID} });

  return $Shedule->{errno} ? return {
    message       => $Shedule->{errstr},
    message_type  => 'err',
    message_title => '$lang{ERROR}',
    error         => $Shedule->{errno},
    errstr        => 'Error occurred during operation'
  } : { success => 1, UID => $attr->{UID} };
}

#***************************************************************
=head2 get_next_abon_date($attr)

  Arguments:
    $attr
      UID       -
      PERIOD    -
      DATE      -
      SERVICE   -
        EXPIRE
        MONTH_ABON
        ABON_DISTRIBUTION
        STATUS


  Results:
    { ABON_DATE => DATE, message => 'STATUS_5' }

=cut
#***************************************************************
sub get_next_abon_date {
  my $self = shift;
  my ($attr) = @_;

  my $start_period_day = $attr->{START_PERIOD_DAY} || $self->{conf}->{START_PERIOD_DAY} || 1;
  my $Service = $attr->{SERVICE_INFO} || $self->_service_info($attr);
  return $Service if $Service->{error};

  my $service_activate = $Service->{ACTIVATE} || $attr->{ACTIVATE} || '0000-00-00';
  my $service_expire = $Service->{EXPIRE} || '0000-00-00';
  my $month_abon = $attr->{MONTH_ABON} || $Service->{MONTH_ABON} || 0;
  my $tp_age = $Service->{TP_INFO}->{AGE} || 0;
  my $service_status = $Service->{STATUS} || 0;
  my $abon_distribution = $Service->{ABON_DISTRIBUTION} || 0;
  my $fixed_fees_day = $Service->{FIXED_FEES_DAY} || $attr->{FIXED_FEES_DAY} || 0;

  $main::DATE = $attr->{DATE} if ($attr->{DATE});

  my ($Y, $M, $D) = split(/-/, $main::DATE, 3);

  return { ABON_DATE => $main::DATE, message => 'STATUS_5' } if ($service_status == 5);

  if ($service_activate ne '0000-00-00' && $service_expire eq '0000-00-00') {
    ($Y, $M, $D) = split(/-/, $service_activate, 3);
  }

  # Renew expired accounts
  if ($service_expire ne '0000-00-00' && $tp_age > 0) {
    # Renew expire tarif
    if (date_diff($service_expire, $main::DATE) > 1) {
      my ($NEXT_EXPIRE_Y, $NEXT_EXPIRE_M, $NEXT_EXPIRE_D) = split(/-/, POSIX::strftime("%Y-%m-%d",
        localtime((POSIX::mktime(0, 0, 0, $D, ($M - 1), ($Y - 1900), 0, 0, 0) + $tp_age * 86400))));

      return {
        ABON_DATE  => $main::DATE,
        NEW_EXPIRE => "$NEXT_EXPIRE_Y-$NEXT_EXPIRE_M-$NEXT_EXPIRE_D",
        message    => "RENEW EXPIRE"
      };
    }
    else {
      return { ABON_DATE => $service_expire };
    }
  }
  #Get next abon day
  elsif ($attr->{MODULE} && !$self->{conf}{uc($attr->{MODULE}) . '_USER_CHG_TP_NEXT_MONTH'} && ($month_abon == 0 || $abon_distribution)) {
    ($Y, $M, $D) = split(/-/, POSIX::strftime("%Y-%m-%d",
      localtime((POSIX::mktime(0, 0, 0, $D, ($M - 1), ($Y - 1900), 0, 0, 0) + 86400))));

    return { ABON_DATE => sprintf("%d-%02d-%02d", $Y, $M, $D), message => "RENEW MONTH_FEE_0" };
  }
  elsif ($month_abon > 0) {
    if ($service_activate ne '0000-00-00') {
      if ($fixed_fees_day) {
        $M++;

        if ($M == 13) {
          $M = 1;
          $Y++;
        }

        return { ABON_DATE => sprintf("%d-%02d-%02d", $Y, $M, $D), message => "FIXED_DAY" };
      }
      else {
        $self->{ABON_DATE} = POSIX::strftime("%Y-%m-%d", localtime((POSIX::mktime(0, 0, 0, $D, ($M - 1), ($Y - 1900),
          0, 0, 0) + 31 * 86400 + (($start_period_day > 1) ? $start_period_day * 86400 : 0))));

        return { ABON_DATE => $self->{ABON_DATE}, message => "NEXT_PERIOD_ABON" };
      }
    }
    else {
      if ($start_period_day > $D) {
        $D = $start_period_day;
      }
      else {
        $M++;
        $D = '01';
      }

      if ($M == 13) {
        $M = 1;
        $Y++;
      }

      return { ABON_DATE => sprintf("%d-%02d-%02d", $Y, $M, $D), message => "NEXT_MONTH_ABON" };
    }
  }

  return { ABON_DATE => $self->{ABON_DATE} || '' };
}

#***************************************************************
=head2 _chg_tp_nperiod($attr)

  Arguments:
    $attr
      SERVICE - Service object
      attr
        MODULE
        UID
        ID
        TP_ID

  Results:
    SUCCESS:
      {
        success => 1,
        UID
        TP_ID
        ID
      }
    ERROR:
      {
        message       => '$lang{ERR_WRONG_PASSWD}',
        message_type  => 'err',
        message_title => '$lang{ERROR}',
        error         => 4508
      }

=cut
#***************************************************************
sub _chg_tp_nperiod {
  my $self = shift;
  my ($attr) = @_;

  my $Service = $attr->{SERVICE};

  return {
    message       => '$lang{ERR_NO_DATA}',
    message_type  => 'err',
    message_title => '$lang{ERROR}',
    error         => 4510,
    errstr        => 'No data'
  } if !$attr->{MODULE} || !$Service;

  return '' if !$CONF->{uc($attr->{MODULE}) . '_USER_CHG_TP_NPERIOD'};

  my ($Y, $M, $D) = split(/-/, $Service->{ABON_DATE}, 3);

  $M = sprintf("%02d", $M);
  $D = sprintf("%02d", $D);
  my $seltime = POSIX::mktime(0, 0, 0, $D, ($M - 1), ($Y - 1900));

  if ($seltime > time()) {
    $Shedule->add({
      UID      => $attr->{UID},
      TYPE     => 'tp',
      ACTION   => "$attr->{ID}:$attr->{TP_ID}",
      D        => $D,
      M        => $M,
      Y        => $Y,
      MODULE   => $attr->{MODULE},
      COMMENTS => ::_translate('$lang{FROM}') . ": $Service->{TP_ID}:$Service->{TP_NAME}"
    });

    return {
      message       => $Shedule->{errstr},
      message_type  => 'err',
      message_title => '$lang{ERROR}',
      error         => $Shedule->{errno},
      errstr        => 'Error occurred during operation'
    } if $Shedule->{errno};
    return { success => 1, UID => $attr->{UID}, TP_ID => $attr->{TP_ID}, ID => $attr->{ID} };
  }

  return $self->_chg_tp_immediately($attr);
}

#***************************************************************
=head2 _chg_tp_immediately($attr)

  Arguments:
    $attr
      SERVICE - Service object
      attr
        MODULE
        UID
        ID
        TP_ID

  Results:
    SUCCESS:
      {
        success => 1,
        UID
        TP_ID
        ID
      }
    ERROR:
      {
        message       => '$lang{ERR_WRONG_PASSWD}',
        message_type  => 'err',
        message_title => '$lang{ERROR}',
        error         => 4508
      }

=cut
#***************************************************************
sub _chg_tp_immediately {
  my $self = shift;
  my ($attr) = @_;

  my $Service = $attr->{SERVICE};
  return {
    message       => '$lang{ERR_NO_DATA}',
    message_type  => 'err',
    message_title => '$lang{ERROR}',
    error         => 4512,
    errstr        => 'No data'
  } if !$attr->{MODULE} || !$Service;

  my $change_params = {
    TP_ID    => $attr->{TP_ID},
    UID      => $attr->{UID},
    STATUS   => ($Service->{STATUS} == 5) ? 0 : ($attr->{STATUS} || 0),
    ACTIVATE => ($Service->{ACTIVATE} ne '0000-00-00') ? "$main::DATE" : undef,
    ID       => $attr->{ID}
  };

  return { CHANGE_DATA => $change_params, UID => $attr->{UID} } if ($attr->{DISABLE_CHANGE_TP} || !$Service->can('user_change'));

  $Service->user_change($change_params);

  if (!$Service->{errno}) {
    $self->_show_message('info', '$lang{CHANGED}', '$lang{CHANGED}');
    ::service_get_month_fee($Service, { USER_INFO => $Users }) if (!$attr->{uc($attr->{MODULE}) . '_NO_ABON'});
    return { success => 1, RESULT => $Service, UID => $attr->{UID}, ID => $attr->{ID} };
  }

  return {
    message       => $Service->{errstr},
    message_type  => 'err',
    message_title => '$lang{ERROR}',
    error         => $Service->{errno},
    errstr        => 'Error occurred during operation'
  };
}

#***************************************************************
=head2 _chg_tp_shedule($attr)

  Arguments:
    $attr
      SERVICE - Service object
      attr
        MODULE
        UID
        ID
        TP_ID

  Results:
    SUCCESS:
      {
        success => 1,
        UID
      }
    ERROR:
      {
        message       => '$lang{ERR_WRONG_PASSWD}',
        message_type  => 'err',
        message_title => '$lang{ERROR}',
        error         => 4508
      }

=cut
#***************************************************************
sub _chg_tp_shedule {
  my $self = shift;
  my ($attr) = @_;

  my $Service = $attr->{SERVICE};

  return {
    message       => '$lang{ERR_NO_DATA}',
    message_type  => 'err',
    message_title => '$lang{ERROR}',
    error         => 4511
  } if !$attr->{MODULE} || !$Service;

  return '' if !$attr->{period} || $attr->{period} < 0 || (!$CONF->{uc($attr->{MODULE}) . '_USER_CHG_TP_SHEDULE'}
    && !$CONF->{uc($attr->{MODULE}) . '_USER_CHG_TP_NOW'});

  my ($year, $month, $day) = split(/-/, $attr->{period} == 1 ? $Service->{ABON_DATE} : $attr->{DATE}, 3);
  my $seltime = POSIX::mktime(0, 0, 0, $day, ($month - 1), ($year - 1900));

  return {
    message       => '$lang{ERR_WRONG_DATA}: $lang{DATE}',
    message_type  => 'err',
    message_title => '$lang{ERROR}',
    error         => 145,
    errstr        => 'Wrong data - date'
  } if ($seltime <= time());

  $Shedule->add({
    UID      => $attr->{UID},
    TYPE     => 'tp',
    ACTION   => "$attr->{ID}:$attr->{TP_ID}",
    D        => sprintf("%02d", $day),
    M        => sprintf("%02d", $month),
    Y        => $year,
    MODULE   => $attr->{MODULE},
    COMMENTS => ::_translate('$lang{FROM}') . ": $Service->{TP_ID}:$Service->{TP_NAME}"
  });

  return {
    message       => $Service->{errstr},
    message_type  => 'err',
    message_title => '$lang{ERROR}',
    error         => $Service->{errno},
    errstr        => 'Error occurred during operation'
  } if $Shedule->{errno};
  return { success => 1, UID => $attr->{UID} };
}

#***************************************************************
=head2 _service_info($attr) - Get service info by MODULE

  Arguments:
    $attr
      UID
      ID
      MODULE

  Return:
    SERVICE_INFO

  Examples:

     $self->_service_info({
       ID     => $Internet->{ID},
       UID    => $uid,
       MODULE => 'Internet'
     });

=cut
#***************************************************************
sub _service_info {
  my $self = shift;
  my ($attr) = @_;

  return {
    message       => '$lang{ERR_NO_DATA}',
    message_type  => 'err',
    message_title => '$lang{ERROR}',
    error         => 4601,
    errstr        => 'No data'
  } if (!$attr->{UID} || !$attr->{MODULE});

  my %info_function = ('Iptv' => $attr->{ID});

  return if $attr->{MODULE} =~ /^[\w.]+$/;

  eval {require $attr->{MODULE} . '.pm';};

  return {
    message       => $@,
    message_type  => 'err',
    message_title => '$lang{ERROR}',
    error         => 4602,
    errstr        => 'Error occurred during operation'
  } if ($@);

  my $module = $attr->{MODULE}->new($db, $admin, $CONF);

  return {
    message       => 'CANNOT_GET_SERVICE_INFO',
    message_type  => 'err',
    message_title => '$lang{ERROR}',
    error         => 4603,
    errstr        => 'Unknown operation for this user'
  } if !$module->can('user_info') ;

  return $module->user_info($info_function{$attr->{MODULE}} ?
    $info_function{$attr->{MODULE}} : ($attr->{UID}, { ID => $attr->{ID} }));
}

#**********************************************************	
=head2 _get_credit_limit();

  Arguments:
    $attr
      UID
      REDUCTION

  Results:
    $credit_limit

=cut
#**********************************************************
sub _get_credit_limit {
  my $self = shift;
  my ($attr) = @_;
  my $credit_limit = 0;

  if ($self->{conf}{user_credit_all_services}) {
    # require Control::Services;
    do 'Control/Services.pm';
    # if ($@) {
    #   print "Content-TYpe: text/html\n\n";
    #   print $@;
    # }

    my $service_info = get_services({
      UID          => $attr->{UID},
      REDUCTION    => $attr->{REDUCTION},
      PAYMENT_TYPE => 0
    });

    foreach my $service (@{$service_info->{list}}) {
      $credit_limit += $service->{SUM};
    }

    return ($credit_limit + 1);
  }

  if (in_array('Internet', \@::MODULES)) {
    $Internet->user_info($attr->{UID});
    if ($Internet->{USER_CREDIT_LIMIT} && $Internet->{USER_CREDIT_LIMIT} > 0) {
      $credit_limit = $Internet->{USER_CREDIT_LIMIT};
    }
  }

  return $credit_limit;
}

#**********************************************************
=head2 _check_payments_exp()

  Arguments:
    $uid
    $payments_expr

  Returns:
    $sum

=cut
#**********************************************************
sub _check_payments_exp {
  my $self = shift;
  my $uid = shift;
  my $payments_expr = shift;

  my $sum = 0;
  my %params = (
    PERIOD          => 0,
    MAX_CREDIT_SUM  => 1000,
    MIN_PAYMENT_SUM => 1,
    PERCENT         => 100
  );
  my @params_arr = split(/,/, $payments_expr);

  foreach my $line (@params_arr) {
    my ($k, $v) = split(/=/, $line);
    $params{$k} = $v;
  }

  my $Payments = Finance->payments($db, $admin, $CONF);
  $Payments->list({
    UID          => $uid,
    PAYMENT_DAYS => ">$params{PERIOD}",
    SUM          => ">=$params{MIN_PAYMENT_SUM}"
  });

  return $sum if ($Payments->{TOTAL} < 1);

  $sum = $Payments->{SUM} / 100 * $params{PERCENT};
  $sum = $params{MAX_CREDIT_SUM} if ($sum > $params{MAX_CREDIT_SUM});

  return $sum;
}

#**********************************************************
=head2 _check_holdup_exp()

  Arguments:
    $uid
    $holdup_expr

  Returns:

=cut
#**********************************************************
sub _check_holdup_exp {
  my $self = shift;
  my $expr = shift;
  my $user_info = shift;

  return () if !$expr;

  my @holdup_exprs = split(/,\s?/, $expr);
  my %holdup_params = ();

  foreach my $expr_pair (@holdup_exprs) {
    my ($key, $val) = split(/=/, $expr_pair);
    $holdup_params{$key} = $val;
  }

  return () if !$holdup_params{REGISTRATION};

  $holdup_params{REGISTRATION} =~ s/^([<>])//;
  my $param = $1 || '=';
  $param = $param eq '>' ? '<' : $param eq '<' ? '>' : $param;

  my $days = date_diff($user_info->{REGISTRATION}, $main::DATE);

  if (eval ($days . $param . $holdup_params{REGISTRATION})) {
    $self->_show_message('err', '$lang{ERROR}', '$lang{ERR_WRONG_DATA} $lang{REGISTRATION}');
    return { error => 4405, errstr => 'ERR_WRONG_REGISTRATION_DATA' };
  }

  return ();
}

#**********************************************************
=head2 _add_holdup()

  Arguments:
    $attr
       FROM_DATE
       TO_DATE
       UID
       ID
       MODULES

  Return:


=cut
#**********************************************************
sub _add_holdup {
  my $self = shift;
  my ($attr) = @_;

  my ($from_year, $from_month, $from_day) = split(/-/, $attr->{FROM_DATE}, 3);
  my ($to_year, $to_month, $to_day) = split(/-/, $attr->{TO_DATE}, 3);
  my $block_days = date_diff($attr->{FROM_DATE}, $attr->{TO_DATE});
  my $err_msg = '';
  my $errstr = '';
  my $err_status = 0;

  if ($attr->{HOLD_UP_MIN_PERIOD} && $block_days < $attr->{HOLD_UP_MIN_PERIOD}) {
    $err_msg = '$lang{MIN} $lang{HOLD_UP} ' . $attr->{HOLD_UP_MIN_PERIOD} . ' $lang{DAYS} ' . $block_days;
    $errstr = 'Min holdup ' . $attr->{HOLD_UP_MIN_PERIOD} . ' days ' . $block_days;
    $err_status = 4421;
  }
  elsif ($attr->{HOLD_UP_MAX_PERIOD} && $block_days > $attr->{HOLD_UP_MAX_PERIOD}) {
    $err_msg = '$lang{MAX} $lang{HOLD_UP} (' . $attr->{HOLD_UP_MAX_PERIOD} . ') $lang{DAYS} ' . $block_days;
    $errstr = 'Max holdup ' . $attr->{HOLD_UP_MAX_PERIOD} . ' days ' . $block_days;
    $err_status = 4422;
  }
  elsif (date_diff($main::DATE, $attr->{FROM_DATE}) < 1) {
    $err_msg = '$lang{ERR_WRONG_DATA}\n $lang{FROM}: ' . $attr->{FROM_DATE};
    $errstr = "Wrong param fromDate $attr->{FROM_DATE}";
    $err_status = 4423;
  }
  elsif ($block_days < 1) {
    $err_msg = '$lang{ERR_WRONG_DATA}\n $lang{TO}: ' . $attr->{TO_DATE};
    $errstr = "Wrong param toDate $attr->{TO_DATE}";
    $err_status = 4424;
  }
  elsif (!$attr->{ID} && ! $CONF->{HOLDUP_ALL}) {
    $errstr = "Wrong param id";
    $err_msg = '$lang{ERR_NO_DATA}: ID';
    $err_status = 4425;
  }

  if ($err_msg) {
    $self->_show_message('err', '$lang{ERR_WRONG_DATA}', $err_msg);
    return { error => $err_status, errstr => $errstr };
  }

  $Shedule->add({
    UID      => $attr->{UID},
    TYPE     => 'status',
    ACTION   => ($attr->{ID} || q{}) . ':3',
    D        => $from_day,
    M        => $from_month,
    Y        => $from_year,
    MODULE   => $attr->{MODULE} || 'Internet',
    COMMENTS => "DAYS:" . $block_days
  });

  $Shedule->add({
    UID    => $attr->{UID},
    TYPE   => 'status',
    ACTION => ($attr->{ID} || q{}) . ':0',
    D      => $to_day,
    M      => $to_month,
    Y      => $to_year,
    MODULE => $attr->{MODULE} || 'Internet'
  });

  return { errno => $Shedule->{errno}, errstr => $Shedule->{errstr}, MODULE => 'Shedule' } if ($Shedule->{errno});
  # $self->internet_add_compensation({ HOLD_UP => 1, UP => 1, %{$attr} }) if ($CONF->{INTERNET_HOLDUP_COMPENSATE});

  $self->_show_message('info', '$lang{INFO}', '$lang{HOLD_UP}' . "\n" . '$lang{DATE}: ' . "$attr->{FROM_DATE} -> $attr->{TO_DATE}\n  " .
    '$lang{DAYS}: ' . sprintf("%d", $block_days));
  return { success => 1, msg => 'HOLDUP_ADDED' };
}

#**********************************************************
=head2 _del_holdup()

  Arguments:
    $attr
       UID
       ID
       IDS
       INTERNET_STATUS

=cut
#**********************************************************
sub _del_holdup {
  my $self = shift;
  my ($attr) = @_;

  return { error => 4408, errstr => 'ERR_DEL_HOLDUP' } if (!$attr->{UID} || (!$attr->{ID} && !$CONF->{HOLDUP_ALL}));

  my ($ids, undef) = $self->_get_holdup_ids($attr->{UID}, $attr->{ID});
  # $attr->{IDS} = $ids if (!$attr->{IDS});
  $attr->{IDS} = $ids;

  $Shedule->del({ UID => $attr->{UID}, IDS => $ids });
  $Internet->{STATUS_DAYS} = 1;

  if ($attr->{INTERNET_STATUS} && $attr->{INTERNET_STATUS} == 3) {
    $Internet->user_change({
      UID    => $attr->{UID},
      ID     => $attr->{ID},
      STATUS => 0,
    });

    ::service_get_month_fee($Internet, { QUITE => 1, USER_INFO => $Users });
    $self->_show_message('info', '$lang{SERVICE}', '$lang{ACTIVATE}');
    return { success => 1, msg => 'Service activate' };
  }

  # if ($CONF->{INTERNET_HOLDUP_COMPENSATE}) {
  #   $Internet->{TP_INFO} = $Tariffs->info(0, { TP_ID => $Internet->{TP_ID} });
  #   ::service_get_month_fee($Internet, { QUITE => 1, USER_INFO => $Users });
  #
  #   # Delete payment created by compensation if it exists
  #   require Payments;
  #   my $Payments = Payments->new($db, $admin, $CONF);
  #   my $payments = $Payments->list({
  #     METHOD    => 6,
  #     UID       => $attr->{UID},
  #     DSC       => ($schedule_date->{3} && $schedule_date->{0}) ? "*$schedule_date->{3}/$schedule_date->{0}*" : '--',
  #     COLS_NAME => 1
  #   });
  #
  #   if (scalar @{$payments}) {
  #     $Payments->del({ UID => $attr->{UID} }, $payments->[0]->{id});
  #
  #     $self->internet_add_compensation({
  #       HOLD_UP   => 1,
  #       UP        => 1,
  #       UID       => $attr->{UID},
  #       FROM_DATE => $attr->{SCHEDULE_DATE}->{3},
  #       TO_DATE   => $main::DATE
  #     });
  #   }
  # }

  $self->_show_message('info', '$lang{HOLD_UP}', '$lang{DELETED}');
  return { success => 1, msg => 'Holdup deleted' };
}

#**********************************************************
=head2 _get_holdup_ids()

  Arguments:
    $uid
    $id

  Returns:
    del_ids, shedule_date

=cut
#**********************************************************
sub _get_holdup_ids {
  shift;
  my $uid = shift;
  my $id = shift;

  my %params = (
    UID        => $uid,
    TYPE       => 'status',
    COLS_NAME  => 1
  );

  $params{SERVICE_ID} = $id if (!$CONF->{HOLDUP_ALL});
  $params{MODULE} = 'ALL' if ($CONF->{HOLDUP_ALL});

  my $list = $Shedule->list(\%params);

  my %shedule_date = ();
  my @del_arr = ();

  foreach my $line (@$list) {
    my (undef, $action) = split(/:/, $line->{action});
    $shedule_date{ $action } = join('-', ($line->{y} || '*', $line->{m} || '*', $line->{d} || '*'));
    push @del_arr, $line->{id};
  }

  return join(', ', @del_arr), \%shedule_date;
}

#**********************************************************
=head2 _show_message()

  Arguments:
    $type
    $title
    $msg

=cut
#**********************************************************
sub _show_message {
  shift;
  my ($type, $title, $msg) = @_;

  return '' if !$html || !$lang;

  $html->message($type, ::_translate($title), ::_translate($msg));
}

#**********************************************************
=head2 all_info($attr) - Get All info about active user tariffs

  Arguments:
    $attr: hash
      MODULE: string        - type of module
      FUNCTION_PARAMS: hash - params for module user_list function
      UID: integer          - user id
      SERVICE_INFO: object  - module object

  Results:
    $result: array of hashes

=cut
#**********************************************************
sub all_info {
  my $self = shift;
  my ($attr)= @_;

  my $service_info = $attr->{SERVICE_INFO} || $self->_service_info($attr);

  my $tariffs_list = $service_info->user_list({
    %{$attr->{FUNCTION_PARAMS} || {}},
    UID              => $attr->{UID},
    CID              => '_SHOW',
    TP_NAME          => '_SHOW',
    TP_COMMENTS      => '_SHOW',
    MONTH_FEE        => '_SHOW',
    DAY_FEE          => '_SHOW',
    TP_ID            => '_SHOW',
    TP_REDUCTION_FEE => '_SHOW',
    AGE              => '_SHOW',
    ACTIV_PRICE      => '_SHOW',
    COLS_NAME        => 1,
  });

  require Service;
  Service->import();
  my $Service = Service->new($self->{db}, $self->{admin}, $self->{conf});
  my $user_info = $Users->info($attr->{UID});

  my $statuses = $Service->status_list({
    NAME      => '_SHOW',
    LIST2HASH => 'id,name'
  });

  if ($attr->{MODULE} eq 'Iptv') {
    %main::FORM = ();
    ::load_module('Iptv::Services', { LOAD_PACKAGE => 1 });
  }

  foreach my $tariff (@{$tariffs_list}) {
    $Shedule->info({ UID => $attr->{UID}, TYPE => 'tp', MODULE => $attr->{MODULE} });

    if ($Shedule->{TOTAL} > 0)  {
      my $action = $Shedule->{ACTION};
      my $service_id = 0;
      if ($action =~ /:/) {
        ($service_id, $action) = split(/:/, $action);
      }

      my $tariff_change = $Tariffs->list({
        INNER_TP_ID   => $action,
        STATUS        => '<1',
        MONTH_FEE     => '_SHOW',
        DAY_FEE       => '_SHOW',
        COMMENTS      => '_SHOW',
        REDUCTION_FEE => '_SHOW',
        NEW_MODEL_TP  => 1,
        DOMAIN_ID     => $admin->{DOMAIN_ID} || 0,
        IN_SPEED      => '_SHOW',
        OUT_SPEED     => '_SHOW',
        COLS_NAME     => 1
      })->[0] || {};

      $tariff->{schedule} = {
        SHEDULE_ID  => $Shedule->{SHEDULE_ID},
        DATE        => $Shedule->{DATE},
        DATE_FROM   => "$Shedule->{Y}-$Shedule->{M}-$Shedule->{D}",
        TP_ID       => $action,
        TP_NAME     => $tariff_change->{name},
        TP_COMMENTS => $tariff_change->{comments},
        MONTH_FEE   => $tariff_change->{month_fee},
        DAY_FEE     => $tariff_change->{day_fee}
      };

      if ($attr->{MODULE} eq 'Internet') {
        $tariff->{schedule}->{IN_SPEED} = $tariff_change->{in_speed};
        $tariff->{schedule}->{OUT_SPEED} = $tariff_change->{out_speed};
      }
    }

    if ($tariff->{tp_reduction_fee} && $user_info->{REDUCTION} && $user_info->{REDUCTION} > 0) {
      $tariff->{original_day_fee} = $tariff->{day_fee};
      $tariff->{original_month_fee} = $tariff->{month_fee};
      $tariff->{day_fee} = $tariff->{day_fee} ? sprintf('%.2f', $tariff->{day_fee} - (($tariff->{day_fee} / 100) * $user_info->{REDUCTION})) : $tariff->{day_fee};
      $tariff->{month_fee} = $tariff->{month_fee} ? sprintf('%.2f', $tariff->{month_fee} - (($tariff->{month_fee} / 100) * $user_info->{REDUCTION})) : $tariff->{month_fee};
    }

    my $next_abon = $self->service_warning({
      UID    => $attr->{UID},
      ID     => $tariff->{id},
      MODULE => $attr->{MODULE}
    });

    if (!$next_abon->{errno}) {
      delete @{$next_abon}{qw/WARNING MESSAGE_TYPE/};
      $tariff->{next_abon} = $next_abon;
    }

    if ($attr->{MODULE} eq 'Internet' || $attr->{MODULE} eq 'Iptv') {
      my $status = defined $tariff->{service_status} ? $tariff->{service_status} : $tariff->{internet_status};
      my ($status_name) = $statuses->{$status} =~ /(?<=\$lang\{)(.*)(?=\})/g;
      $status_name //= q{};
      $tariff->{status_name} = $lang->{$status_name} || camelize($status_name);

      #TODO: Add normal info return for IPTV API if enabled HOLDUP_ALL
      my $holdup = $self->user_holdup({
        UID          => $attr->{UID},
        ID           => $tariff->{id},
        MODULE       => $attr->{MODULE},
        ACCEPT_RULES => 1
      });

      if ($holdup && !$holdup->{result}) {
        $tariff->{holdup} = $holdup;
      }
    }

    if ($attr->{MODULE} eq 'Internet') {
      $tariff->{service_holdup} = (($CONF->{INTERNET_USER_SERVICE_HOLDUP} || $CONF->{HOLDUP_ALL}) && $tariff->{internet_status}) ? 'false' : 'true';

      my $speed = $service_info->get_speed({
        UID       => $attr->{UID},
        TP_ID     => $tariff->{tp_id},
        COLS_NAME => 1,
        PAGE_ROWS => 1
      });

      $tariff->{in_speed} = $speed->[0]->{in_speed};
      $tariff->{out_speed} = $speed->[0]->{out_speed};
    }

    if ($attr->{MODULE} eq 'Iptv') {
      $main::Tv_service = undef;

      if ($tariff->{service_id}) {
        $main::Iptv = $service_info;
        $main::Tv_service = ::tv_load_service($service_info->{SERVICE_MODULE}, { SERVICE_ID => $service_info->{SERVICE_ID} });

        if ($main::Tv_service) {
          $tariff->{get_url} = 'true' if ($main::Tv_service->can('get_url'));
          $tariff->{get_code} = 'true' if ($main::Tv_service->can('get_code'));
          $tariff->{get_playlist} = 'true' if ($main::Tv_service->can('get_playlist_m3u') && $CONF->{IPTV_CLIENT_M3U});
        }
      }

      delete $tariff->{tv_user_portal};
      $tariff->{service_holdup} = ($tariff->{tv_user_portal} && $tariff->{tv_user_portal} > 1 && !$tariff->{service_status}) ? 'false' : 'true';
    }
  }

  return $tariffs_list;
}

#**********************************************************
=head2 _get_tariffs($attr) - Return array with tariff list

  Arguments:
    $attr: hash
       UID: int                             - user id
       MODULE: string                       - module of tariffs
       SKIP_NOT_AVAILABLE_TARIFFS: boolean  - don't return tariffs for which not enough money

  Results:
    \@tariffs: array - list of tariff plans

=cut
#**********************************************************
sub _get_tariffs {
  my $self = shift;
  my ($attr, $service_info, $user_info) = @_;

  my $tariffs = $self->_get_module_tariffs($attr, $service_info, $user_info);
	
  return $tariffs if ($tariffs);

  my @tariffs = ();

  my $tp_list = $Tariffs->list({
    TP_GID            => $service_info->{TP_GID} || '_SHOW',
    CHANGE_PRICE      => ($attr->{skip_check_deposit} || $CONF->{uc $attr->{MODULE} . '_USER_CHG_TP_SMALL_DEPOSIT'}) ?
      undef : '<=' . ($user_info->{DEPOSIT} + $user_info->{CREDIT}),
    MODULE            => $attr->{MODULE},
    STATUS            => '<1',
    MONTH_FEE         => '_SHOW',
    DAY_FEE           => '_SHOW',
    CREDIT            => '_SHOW',
    COMMENTS          => '_SHOW',
    TP_CHG_PRIORITY   => $service_info->{TP_PRIORITY},
    REDUCTION_FEE     => '_SHOW',
    NEW_MODEL_TP      => 1,
    DOMAIN_ID         => $user_info->{DOMAIN_ID},
    REDUCTION         => $user_info->{REDUCTION},
    PAYMENT_TYPE      => '_SHOW',
    ABON_DISTRIBUTION => '_SHOW',
    SERVICE_ID        => $service_info->{SERVICE_ID} || '_SHOW',
    IN_SPEED          => '_SHOW',
    OUT_SPEED         => '_SHOW',
    AGE               => '_SHOW',
    ACTIV_PRICE       => '_SHOW',
    POPULAR           => '_SHOW',
    PRIORITY		  => '_SHOW',
    COLS_NAME         => 1
  });

  my @skip_tp_changes = $CONF->{uc $attr->{MODULE} . '_SKIP_CHG_TPS'} ?
    split(/,\s?/, $CONF->{uc $attr->{MODULE} . '_SKIP_CHG_TPS'}) : ();
	
	my $skip_tp_changes_disc = $CONF->{uc $attr->{MODULE} . '_SKIP_CHG_TPS_DISC'} ?
		split(/,\s?/, $CONF->{uc $attr->{MODULE} . '_SKIP_CHG_TPS_DISC'}) : ();

  foreach my $tp (@$tp_list) {
	next if ($skip_tp_changes_disc && $user_info->{REDUCTION} > 0 && $tp->{priority} < $service_info->{TP_PRIORITY});
    next if (in_array($tp->{id}, \@skip_tp_changes));
    next if ($tp->{tp_id} == $service_info->{TP_ID} && $user_info->{EXPIRE} eq '0000-00-00');
									
    my %tariff = (
      id             => $tp->{id},
      tp_id          => $tp->{tp_id},
      name           => $tp->{name},
      comments       => $tp->{comments},
      service_id     => $tp->{service_id},
      day_fee        => $tp->{day_fee},
      month_fee      => $tp->{month_fee},
      reduction_fee  => $tp->{reduction_fee},
      activate_price => $tp->{activate_price},
      tp_age         => $tp->{age},
      popular        => $tp->{popular}
    );

    my $tp_fee = $tp->{day_fee} + $tp->{month_fee} + ($tp->{change_price} || 0);

    if ($tp->{reduction_fee} && $user_info->{REDUCTION} && $user_info->{REDUCTION} > 0) {
      $tp_fee = $tp_fee - (($tp_fee / 100) * $user_info->{REDUCTION});
      $tariff{original_day_fee} = $tp->{day_fee};
      $tariff{original_month_fee} = $tp->{month_fee};
      $tariff{day_fee} = $tp->{day_fee} ? sprintf('%.2f', $tp->{day_fee} - (($tp->{day_fee} / 100) * $user_info->{REDUCTION})) : $tp->{day_fee};
      $tariff{month_fee} = $tp->{month_fee} ? sprintf('%.2f', $tp->{month_fee} - (($tp->{month_fee} / 100) * $user_info->{REDUCTION})) : $tp->{month_fee};
    }

    $user_info->{CREDIT} = ($user_info->{CREDIT} > 0) ? $user_info->{CREDIT} : (($tp->{credit} > 0) ? $tp->{credit} : 0);

    if (uc $attr->{MODULE} eq 'INTERNET') {
      $tariff{out_speed} = $tp->{out_speed};
      $tariff{in_speed} = $tp->{in_speed};
    }

    $tariff{tp_fee} = $tp_fee;

    if ($tp_fee < $user_info->{DEPOSIT} + $user_info->{CREDIT} || $tp->{payment_type} || $tp->{abon_distribution}) {
      push @tariffs, \%tariff;
      next;
    }

    if ($CONF->{uc $attr->{MODULE} . '_USER_CHG_TP_SMALL_DEPOSIT'}) {
      push @tariffs, \%tariff;
      next;
    }

    next if ($attr->{SKIP_NOT_AVAILABLE_TARIFFS});

    $tariff{ERROR} = ::_translate('$lang{ERR_SMALL_DEPOSIT}');

    push @tariffs, \%tariff;
  }

  return \@tariffs;
}

#**********************************************************
=head2 _iptv_holdup_functions($attr) - IPTV holdup functions

  Arguments:
    $attr: hash
       UID: int     - user id
       ID: int      - service id
       ADD: boolean - add holdup
       DEL: boolean - delete holdup

  Results:
    hash or returns

=cut
#**********************************************************
sub _iptv_holdup_functions {
  my $self = shift;
  my ($attr) = @_;

  return {} if (!$attr->{UID} || !$attr->{ID});

  require Iptv;
  Iptv->import();
  my $Iptv = Iptv->new($self->{db}, $self->{admin}, $self->{conf});

  my $tariffs = $Iptv->user_list({
    ID              => $attr->{ID},
    UID             => $attr->{UID},
    TV_SERVICE_NAME => '_SHOW',
    TV_USER_PORTAL  => '_SHOW',
    SERVICE_STATUS  => '_SHOW',
    COLS_NAME       => 1
  });

  return {
    errno  => 4516,
    errstr => "Unknown iptv id - $attr->{ID}",
  } if (!($Iptv->{TOTAL} && $Iptv->{TOTAL} > 0));

  my $tariff = $tariffs->[0];

  my $schedules = $Shedule->list({
    UID       => $attr->{UID},
    ACTION    => "$attr->{ID}:1",
    TYPE      => 'status',
    MODULE    => 'Iptv',
    COLS_NAME => 1
  });

  if ($attr->{add}) {
    return {
      errno  => 4517,
      errstr => "Not allowed operation for this service" . ($tariff->{tv_service_name} ? " $tariff->{tv_service_name}" : ''),
    } if (!($tariff->{tv_user_portal} && $tariff->{tv_user_portal} > 1 && !$tariff->{service_status}));

    my $disable_date = next_month();
    my ($year, $month, $day) = split(/-/, $disable_date, 3);

    $Shedule->add({
      UID          => $attr->{UID},
      TYPE         => 'status',
      ACTION       => "$attr->{ID}:1",
      D            => $day,
      M            => $month,
      Y            => $year,
      COMMENTS     => "FROM: $tariff->{service_status}->1",
      ADMIN_ACTION => 1,
      MODULE       => 'Iptv'
    });

    if ($Shedule->{errno}) {
      if ($Shedule->{errno} == 7) {
        return {
          result => 'Holdup already exists'
        };
      }
      else {
        return {
          errno  => 4518,
          errstr => "Error during set holdup - $Shedule->{errno}",
        };
      }
    }
    else {
      return {
        result => 'Holdup enabled'
      };
    }
  }
  elsif ($attr->{del}) {
    return {
      errno  => 4519,
      errstr => "Not allowed operation for this service" . ($tariff->{tv_service_name} ? " $tariff->{tv_service_name}" : ''),
    } if (!($tariff->{tv_user_portal} && $tariff->{tv_user_portal} > 1 && !$tariff->{service_status}));

    return {
      result => 'No active holdups',
    } if (!($Shedule->{TOTAL} && $Shedule->{TOTAL} > 0));

    $Shedule->del({ UID => $attr->{UID}, ID => $schedules->[0]->{id} });

    return {
      result => 'Successfully deleted',
    };
  }
  else {
    return {
      result => 'No active holdups',
    } if (!($Shedule->{TOTAL} && $Shedule->{TOTAL} > 0));

    return {
      date_from  => "$schedules->[0]->{y}-$schedules->[0]->{m}-$schedules->[0]->{d}",
      can_cancel => 'true',
    };
  }
}

#**********************************************************
=head2 _get_module_tariffs($attr) - Return array with tariff list

  Arguments:
    $attr: hash
       UID: int                             - user id
       MODULE: string                       - module of tariffs
       SKIP_NOT_AVAILABLE_TARIFFS: boolean  - don't return tariffs for which not enough money

  Results:
    \@tariffs: array - list of tariff plans

=cut
#**********************************************************
sub _get_module_tariffs {
  my $self = shift;
  my ($attr, $service_info, $user_info) = @_;

  my $module = ucfirst(lc($attr->{MODULE} || ''));
  my $dir = ($main::base_dir || '/usr/axbills/') . 'AXbills/modules/';
  my $module_path = $dir . $module . '/Base.pm';

  return 0 if !(-f $module_path);

  return if $module !~ /^[\w.]+$/;

  my $module_name = $module . '::Base';
  # TODO: review string eval
  eval "use $module_name;";
  return 0 if $@;

  my $function = lc $module . '_get_available_tariffs';

  return 0 if (!$module_name->can('new'));
  return 0 if (!$module_name->can($function));

  my $result = 0;

  eval {
    my $module_api = $module_name->new($self->{db}, $self->{admin}, $self->{conf}, { HTML => $html, LANG => $lang });
    $result = $module_api->$function($attr, $service_info, $user_info);
  };

  return {
    message       => '$lang{NOT_ALLOWED}',
    message_type  => 'err',
    message_title => '$lang{ERROR}',
    error         => 4531,
    errstr        => 'Try later'
  } if ($@);

  return $result;
};

1;
