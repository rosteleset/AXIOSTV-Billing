=head1 NAME

  Dv Periodic

=cut

use strict;
use warnings FATAL => 'all';
use AXbills::Base qw(days_in_month in_array sendmail int2byte sec2time);

our(
  $db,
  $admin,
  %conf,
  %ADMIN_REPORT,
  %lang,
  $html
);

my $Dv       = Dv->new($db, $admin, \%conf);
my $Sessions = Dv_Sessions->new($db, $admin, \%conf);
my $Fees     = Fees->new($db, $admin, \%conf);
my $Payments = Finance->payments($db, $admin, \%conf);
my $Tariffs  = Tariffs->new($db, \%conf, $admin);

#**********************************************************
=head2 dv_periodic_logrotate($attr)

=cut
#**********************************************************
sub dv_periodic_logrotate {
  my ($attr) = @_;
  my $debug = $attr->{DEBUG} || 0;

  return '' if ($attr->{SKIP_ROTATE});
  return '' if ($attr->{LOGIN});

  # Clean s_detail table
  my (undef, undef, $d) = split(/-/, $ADMIN_REPORT{DATE}, 3);
  $conf{DV_LOG_CLEAN_PERIOD} = 180 if (!$conf{DV_LOG_CLEAN_PERIOD});

  if ($d == 1 && $conf{DV_LOG_CLEAN_PERIOD}) {
    $DEBUG .= "Make log rotate\n" if ($debug > 0);

    $Sessions->log_rotate(
      {
        TYPES  => [ 'SESSION_DETAILS', 'SESSION_INTERVALS' ],
        PERIOD => $conf{DV_LOG_CLEAN_PERIOD}
      }
    );
  }
  else {
    $Sessions->log_rotate({ DAILY => 1 });
  }

  return 1;
}

#**********************************************************
=head2 dv_daily_fees($attr) - daily fees

=cut
#**********************************************************
sub dv_daily_fees {
  my ($attr) = @_;

  my $debug        = $attr->{DEBUG} || 0;
  my $debug_output = '';
  my $DOMAIN_ID    = $attr->{DOMAIN_ID} || 0;

  if ($attr->{USERS_WARNINGS_TEST}) {
    return $debug_output;
  }

  if (!$ADMIN_REPORT{DATE}) {
    $ADMIN_REPORT{DATE} = $DATE ;
  }

  $debug_output .= "DV: Daily periodic fees\n" if ($debug > 1);

  $LIST_PARAMS{TP_ID}     = $attr->{TP_ID} if ($attr->{TP_ID});
  $LIST_PARAMS{DOMAIN_ID} = $DOMAIN_ID;
  my %USERS_LIST_PARAMS         = ( REGISTRATION => "<$ADMIN_REPORT{DATE}" );
  $USERS_LIST_PARAMS{LOGIN}     = $attr->{LOGIN} if ($attr->{LOGIN});
  $USERS_LIST_PARAMS{GID}       = $attr->{GID} if ($attr->{GID});

  #$USERS_LIST_PARAMS{ACTIVE_DAY_FEE} = 1;
  $Tariffs->{debug} = 1 if ($debug > 6);

  my $list = $Tariffs->list({
    %LIST_PARAMS,
    MODULE     => 'Dv',
    COLS_NAME  => 1,
    COLS_UPPER => 1
  });

  my %FEES_METHODS = %{ get_fees_types({ SHORT => 1 }) };

  foreach my $TP_INFO (@$list) {
    my %FEES_PARAMS = ();
    if ($TP_INFO->{DAY_FEE} > 0) {
      $debug_output .= "TP ID: $TP_INFO->{ID} DF: $TP_INFO->{DAY_FEE} POSTPAID: $TP_INFO->{POSTPAID_DAILY_FEE} REDUCTION: $TP_INFO->{REDUCTION_FEE} EXT_BILL: $TP_INFO->{EXT_BILL_ACCOUNT} CREDIT: $TP_INFO->{CREDIT}\n" if ($debug > 1);

      $USERS_LIST_PARAMS{DOMAIN_ID} = $TP_INFO->{DOMAIN_ID};
      #Get active yesterdays logins
      my %active_logins = ();
      if ($TP_INFO->{ACTIVE_DAY_FEE} > 0) {
        my $report_list = $Sessions->reports(
          {
            INTERVAL => "$attr->{YESTERDAY}/$attr->{YESTERDAY}",
            TP_ID    => $TP_INFO->{ID},
          }
        );

        foreach my $l (@$report_list) {
          $active_logins{ $l->[0] } = $l->[7];
        }
      }

      $Dv->{debug} = 1 if ($debug > 6);
      my $ulist = $Dv->list(
        {
          LOGIN        => '_SHOW',
          ACTIVATE     => "<=$ADMIN_REPORT{DATE}",
          EXPIRE       => "0000-00-00,>$ADMIN_REPORT{DATE}",
          DV_EXPIRE    => "0000-00-00,>$ADMIN_REPORT{DATE}",
          JOIN_SERVICE => "<2",
          DV_STATUS    => "0", # Old "0;5"
          LOGIN_STATUS => 0,
          TP_ID        => $TP_INFO->{ID},
          SORT         => 1,
          PAGE_ROWS    => 1000000,
          TP_CREDIT    => '_SHOW',
          REDUCTION    => '_SHOW',
          BILL_ID      => '_SHOW',
          DEPOSIT      => '_SHOW',
          CREDIT       => '_SHOW',
          DELETED      => 0,
          COLS_NAME    => 1,
          %USERS_LIST_PARAMS
        }
      );

      foreach my $u (@$ulist) {
        #Check bill id and deposit
        my %user = (
          LOGIN     => $u->{login},
          UID       => $u->{uid},
          #Check ext deposit
          BILL_ID   => ($TP_INFO->{EXT_BILL_ACCOUNT} > 0) ? $u->{ext_bill_id} : $u->{bill_id},
          REDUCTION => $u->{reduction},
          ACTIVATE  => $u->{activate},
          DEPOSIT   => $u->{deposit},
          #CREDIT    => ($u->{credit} > 0) ? $u->{credit} : ($conf{user_credit_change}) ? 0 : $TP_INFO->{CREDIT},
          CREDIT    => ($u->{credit} > 0) ? $u->{credit} : $TP_INFO->{CREDIT},
          DV_STATUS => $u->{dv_status},
        );

        if (defined($user{BILL_ID}) && $user{BILL_ID} > 0 && defined($user{DEPOSIT})) {
          #If deposit is above-zero or TARIF PALIN is POST PAID or PERIODIC PAYMENTS is POSTPAID
          #Active day fees
          if ( (($user{DEPOSIT} + $user{CREDIT} > 0 || $TP_INFO->{PAYMENT_TYPE} == 1 || $TP_INFO->{POSTPAID_DAILY_FEE} == 1) && $TP_INFO->{ACTIVE_DAY_FEE} == 0)
            || ($TP_INFO->{ACTIVE_DAY_FEE} == 1 && $active_logins{ $user{LOGIN} }))
          {
            my $sum = $TP_INFO->{DAY_FEE};

            # IF TP have PARIODIC PAYMENTS USER reduction
            if ($TP_INFO->{REDUCTION_FEE} == 1 && $user{REDUCTION} > 0) {
              if ($user{REDUCTION} >= 100) {
                $debug_output .= "UID: $user{UID} SUM: $sum REDUCTION: $user{REDUCTION} next\n" if ($debug > 3);
                next;
              }
              $sum = $sum * (100 - $user{REDUCTION}) / 100;
            }

            my %FEES_DSC = (
              MODULE          => 'Internet',
              TP_ID           => $TP_INFO->{ID},
              TP_NAME         => $TP_INFO->{NAME},
              FEES_PERIOD_DAY => $lang{DAY_FEE_SHORT},
              FEES_METHOD     => $FEES_METHODS{$TP_INFO->{FEES_METHOD}},
            );

            my %PARAMS = (
              DATE     => "$ADMIN_REPORT{DATE} $TIME",
              METHOD   => ($TP_INFO->{FEES_METHOD}) ? $TP_INFO->{FEES_METHOD} : 1,
              DESCRIBE => fees_dsc_former(\%FEES_DSC),
            );

            if ($debug > 4) {
              $debug_output .= " UID: $user{UID} SUM: $sum REDUCTION: $user{REDUCTION}\n";
            }
            else {
              $Fees->take(\%user, $sum, {%PARAMS});
              if ($Fees->{errno}) {
                print "Dv Error: [ $user{UID} ] $user{LOGIN} SUM: $sum [$Fees->{errno}] $Fees->{errstr} ";
                if ($Fees->{errno} == 14) {
                  print "[ $user{UID} ] $user{LOGIN} - Don't have money account";
                }
                print "\n";
              }
              elsif ($debug > 0) {
                $debug_output .= " $user{LOGIN}  UID: $user{UID} SUM: $sum REDUCTION: $user{REDUCTION}\n" if ($debug > 0);
              }
            }
          }

          # If status too small deposit get fine from user
          elsif ($TP_INFO->{FINE} > 0) {
            if ($conf{DV_FINE_LIMIT} && $user{DEPOSIT} + $user{CREDIT} < $conf{DV_FINE_LIMIT}) {
              next;
            }

            %FEES_PARAMS = (
              DESCRIBE => "$lang{FINE}",
              METHOD   => 2,
              DATE     => $ADMIN_REPORT{DATE},
            );
            #$EXT_INFO = "FINE";
            $Fees->take(\%user, $TP_INFO->{FINE}, {%FEES_PARAMS});
            $debug_output .= " $user{LOGIN}  UID: $user{UID} SUM: $TP_INFO->{FINE} REDUCTION: $user{REDUCTION} FINE\n" if ($debug > 0);
          }
        }
        else {
          print "[ $user{UID} ] $user{LOGIN} - Don't have money account (Dv)\n";
        }
      }
    }
  }

  #Daily bonus PAYMENTS
  #Make traffic recalculation for expration
  $list = $Tariffs->list({%LIST_PARAMS, MODULE => 'Dv' });
  $debug_output .= "Bonus payments\n";
  require Billing;
  Billing->import();
  my $Billing = Billing->new($db, \%conf);

  foreach my $tp_line (@$list) {
    my $ti_list = $Tariffs->ti_list({ TP_ID => $tp_line->[18] });
    next if ($Tariffs->{TOTAL} != 1);

    $debug_output .= "TP_ID: $tp_line->[0]\n" if ($debug > 6);
    foreach my $ti (@$ti_list) {

      my $tt_list = $Tariffs->tt_list({ EXPRESSION => '_SHOW',
        TI_ID     => $ti->[0],
        COLS_NAME => 1, });
      next if ($Tariffs->{TOTAL} < 1);

      my %expr_hash     = ();
      my $traffic_class = 0;

      foreach my $tt (@$tt_list) {
        my $expression = $tt->{expression};
        next if ($expression !~ /BONUS_TRAFFIC_/);

        $expression =~ s/BONUS_TRAFFIC/TRAFFIC/g;

        $debug_output .= "TP: $tp_line->[0] TI: $ti->[0] TT: $tt->{id}\n";
        $debug_output .= "  Expr: $expression\n" if ($debug > 3);
        $traffic_class = $tt->{id};

        $expr_hash{$traffic_class} = $expression;

        #last;

        if (!defined($expr_hash{$traffic_class})) {
          next;
        }

        #Get users for bonus payments
        #Ipn users for daily payments
        my $ulist = $Dv->list(
          {
            LOGIN        => '_SHOW',
            ACTIVATE     => "<=$ADMIN_REPORT{DATE}",
            EXPIRE       => "0000-00-00,>$ADMIN_REPORT{DATE}",
            DV_EXPIRE    => "0000-00-00,>$ADMIN_REPORT{DATE}",
            DV_STATUS    => 0,
            LOGIN_STATUS => 0,
            TP_ID        => $tp_line->[0],
            SORT         => 1,
            PAGE_ROWS    => 1000000,
            TP_CREDIT    => '_SHOW',
            COMPANY_ID   => '_SHOW',
            COLS_NAME    => 1,
            LOGIN        => '_SHOW',
            BILL_ID      => '_SHOW',
            REDUCTION    => '_SHOW',
            DEPOSIT      => '_SHOW',
            CREDIT       => '_SHOW',
            COMPANY_ID   => '_SHOW',
            %USERS_LIST_PARAMS
          }
        );

        foreach my $u (@$ulist) {
          my %user = (
            LOGIN      => $u->{login},
            UID        => $u->{uid},
            BILL_ID    => ($tp_line->[14] > 0) ? $u->{bill_id} : $u->{ext_bill_id},
            REDUCTION  => $u->{reduction},
            ACTIVATE   => $u->{activate},
            DEPOSIT    => $u->{deposit},
            CREDIT     => ($u->{credit} > 0) ? $u->{credit} : $tp_line->[15],
            COMPANY_ID => $u->{company_id}
          );

          $Billing->{PERIOD_TRAFFIC} = undef;

          my $RESULT = $Billing->expression(
            $user{UID},
            \%expr_hash,
            {
              START_PERIOD  => $attr->{YESTERDAY},
              STOP_PERIOD   => $attr->{DATE},
              debug         => 0,
              IPN           => 1,
              TRAFFIC_CLASS => $traffic_class
            }
          );

          #my $message = '';
          my $sum     = 0;

          my %FEES_PARAMS = (
            DATE   => $ADMIN_REPORT{DATE},
            METHOD => 0
          );

          if ($RESULT->{'TRAFFIC_IN'}) {
            $FEES_PARAMS{DESCRIBE} = "$lang{USED} $lang{TRAFFIC}: " . $RESULT->{'TRAFFIC_IN'} . "SUM: $RESULT->{PRICE_IN}";
            $sum = $RESULT->{'TRAFFIC_IN'} * $RESULT->{PRICE_IN};    #(($RESULT->{PRICE_IN}) ? $RESULT->{PRICE_IN} : 0);
          }

          if ($RESULT->{'TRAFFIC_OUT'}) {
            $FEES_PARAMS{DESCRIBE} = "$lang{USED} $lang{TRAFFIC}: " . $RESULT->{'TRAFFIC_OUT'} . "SUM: $RESULT->{PRICE_OUT}";
            $sum = $RESULT->{'TRAFFIC_OUT'} * $RESULT->{PRICE_OUT};
          }
          elsif ($RESULT->{'TRAFFIC_SUM'}) {
            $FEES_PARAMS{DESCRIBE} = "$lang{USED} $lang{TRAFFIC}: " . $RESULT->{'TRAFFIC_SUM'} . " SUM: $RESULT->{PRICE}";
            $sum = $RESULT->{'TRAFFIC_SUM'} * $RESULT->{PRICE};
          }

          if ($sum > 0 && $debug < 5) {
            $Payments->add(
              \%user,
              {
                SUM      => $sum,
                METHOD   => 4,
                DESCRIBE => "$lang{TRAFFIC_CLASS}: $traffic_class $lang{BONUS}",
              }
            );
          }

          $debug_output .= " Login: $u->{login} ($u->{uid})  TP_ID: $u->{tp_id} Payments: $sum REDUCTION: $u->{reduction} $u->{deposit} $u->{credit} - $user{ACTIVATE}\n" if ($debug > 0);
        }
      }
    }
  }

  $DEBUG .= $debug_output;
  return $debug_output;
}

#**********************************************************
=head2 dv_holdup_fees($attr) - holdup fees

=cut
#**********************************************************
sub dv_holdup_fees {
  my ($attr) = @_;

  my $debug = $attr->{DEBUG} || 0;
  my $debug_output = '';
  $debug_output .= "DV: Holdup abon\n" if ($debug > 1);
  return $debug_output if (!$conf{DV_USER_SERVICE_HOLDUP});
  my $holdup_fees = (split(/:/, $conf{DV_USER_SERVICE_HOLDUP}))[3];
  return $debug_output if (!$holdup_fees || $holdup_fees == 0);

  my %USERS_LIST_PARAMS = ();
  $USERS_LIST_PARAMS{LOGIN}    = $attr->{LOGIN} if ($attr->{LOGIN});
  $USERS_LIST_PARAMS{EXT_BILL} = 1              if ($conf{BONUS_EXT_FUNCTIONS});
  $USERS_LIST_PARAMS{TP_ID}    = $attr->{TP_ID} if ($attr->{TP_ID});

  my $ulist = $Dv->list(
    {
      ACTIVATE     => "<=$ADMIN_REPORT{DATE}",
      EXPIRE       => "0000-00-00,>$ADMIN_REPORT{DATE}",
      DV_EXPIRE    => "0000-00-00,>$ADMIN_REPORT{DATE}",
      DV_STATUS    => "3",
      LOGIN_STATUS => 0,
      SORT         => 1,
      PAGE_ROWS    => 1000000,
      TP_CREDIT    => '_SHOW',
      LOGIN        => '_SHOW',
      BILL_ID      => '_SHOW',
      REDUCTION    => '_SHOW',
      DEPOSIT      => '_SHOW',
      CREDIT       => '_SHOW',
      COMPANY_ID   => '_SHOW',
      EXT_DEPOSIT  => '_SHOW',
      COLS_NAME    => 1,
      %USERS_LIST_PARAMS
    }
  );

  my $ext_deposit_op = 0;

  foreach my $u (@$ulist) {
    my %user = (
      LOGIN        => $u->{login},
      UID          => $u->{uid},
      BILL_ID      => ($ext_deposit_op > 0) ? $u->{ext_bill_id} : $u->{bill_id},
      MAIN_BILL_ID => ($ext_deposit_op > 0) ? $u->{bill_id} : 0,
      REDUCTION    => $u->{reduction},
      ACTIVATE     => $u->{activate},
      DEPOSIT      => $u->{deposit},
      CREDIT       => ($u->{credit} > 0) ? $u->{credit} : 0,
      COMPANY_ID   => $u->{company_id},
      DV_STATUS    => $u->{dv_status},
      EXT_DEPOSIT  => ($u->{ext_deposit}) ? $u->{ext_deposit} : 0,
    );

    $debug_output .= " Login: $user{LOGIN} ($user{UID}) TP_ID: ($u->{tp_id} Fees: $holdup_fees REDUCTION: $user{REDUCTION} DEPOSIT: $u->{deposit} CREDIT $user{CREDIT} ACTIVE: $user{ACTIVATE} TP: $u->{tp_num}\n" if ($debug > 3);

    if (($user{BILL_ID} && $user{BILL_ID} > 0) && defined($user{DEPOSIT})) {
      if ($debug > 4) {
        $debug_output .= " UID: $user{UID} SUM: $holdup_fees REDUCTION: $user{REDUCTION}\n";
      }
      else {
        my %FEES_PARAMS = (
          DATE     => $ADMIN_REPORT{DATE},
          METHOD   => 1,
          DESCRIBE => "$lang{HOLD_UP}"
        );
        $Fees->take(\%user, $holdup_fees, {%FEES_PARAMS});
        $debug_output .= " $user{LOGIN}  UID: $user{UID} SUM: $holdup_fees REDUCTION: $user{REDUCTION}\n" if ($debug > 0);
      }
    }
    else {
      my $ext = ($ext_deposit_op > 0) ? 'Ext bill' : '';
      print "UID: $user{UID} LOGIN: $user{LOGIN} Don't have $ext money account\n";
    }
  }

  $DEBUG .= $debug_output;
  return $debug_output;
}

#**********************************************************
=head2 dv_monthly_next_tp($attr) Change tp in next period

=cut
#**********************************************************
sub dv_monthly_next_tp {
  my ($attr) = @_;

  my $debug         = $attr->{DEBUG} || 0;
  my $debug_output = '';
  $debug_output  = "DV: Next tp\n" if ($debug > 1);
  $Tariffs->{debug}=1 if ($debug > 6);

  my %USERS_LIST_PARAMS = ();
  $USERS_LIST_PARAMS{LOGIN}        = $attr->{LOGIN} if ($attr->{LOGIN});
  $USERS_LIST_PARAMS{EXT_BILL}     = 1 if ($conf{BONUS_EXT_FUNCTIONS});
  $USERS_LIST_PARAMS{REGISTRATION} = "<$ADMIN_REPORT{DATE}";
  $USERS_LIST_PARAMS{GID}          = $attr->{GID} if ($attr->{GID});

  my $tp_list = $Tariffs->list({
    NEXT_TARIF_PLAN => '>0',
    CREDIT          => '_SHOW',
    AGE             => '_SHOW',
    NEXT_TP_ID      => '_SHOW',
    CHANGE_PRICE    => '_SHOW',
    NEW_MODEL_TP    => 1,
    MODULE          => 'Dv',
    COLS_NAME       => 1
  });

  my ($y, $m, $d)   = split(/-/, $ADMIN_REPORT{DATE}, 3);
  my $date_unixtime = POSIX::mktime(0, 0, 0, $d, ($m - 1), $y - 1900, 0, 0, 0);
  my $START_PERIOD_DAY = ($conf{START_PERIOD_DAY}) ? $conf{START_PERIOD_DAY} : 1;
  my %CHANGED_TPS = ();

  my %tp_ages = ();
  foreach my $tp_info (@$tp_list) {
    $tp_ages{$tp_info->{id}}=$tp_info->{age};
  }

  foreach my $tp_info (@$tp_list) {
    $Dv->{debug} = 1 if ($debug > 6);
    my $ulist = $Dv->list({
      ACTIVATE     => "<=$ADMIN_REPORT{DATE}",
      EXPIRE       => "0000-00-00,>$ADMIN_REPORT{DATE}",
      DV_EXPIRE    => "0000-00-00,>$ADMIN_REPORT{DATE}",
      DV_STATUS    => "0",
      LOGIN_STATUS => 0,
      TP_ID        => $tp_info->{id},
      SORT         => 1,
      PAGE_ROWS    => 1000000,
      DELETED      => 0,
      LOGIN        => '_SHOW',
      REDUCTION    => '_SHOW',
      DEPOSIT      => '_SHOW',
      CREDIT       => '_SHOW',
      COMPANY_ID   => '_SHOW',
      DV_EXPIRE    => '_SHOW',
      BILL_ID      => '_SHOW',
      COLS_NAME    => 1,
      %USERS_LIST_PARAMS
    });

    foreach my $u (@$ulist) {
      my %user = (
        LOGIN      => $u->{login},
        UID        => $u->{uid},
        BILL_ID    => $u->{bill_id},
        REDUCTION  => $u->{reduction},
        ACTIVATE   => $u->{activate},
        DEPOSIT    => $u->{deposit},
        CREDIT     => ($u->{credit} > 0) ? $u->{credit} :  $tp_info->{credit},
        COMPANY_ID => $u->{company_id},
        DV_STATUS  => $u->{dv_status},
        EXPIRE     => $u->{dv_expire},
        EXT_DEPOSIT=> ($u->{ext_deposit}) ? $u->{ext_deposit} : 0,
      );

      my $expire = undef;
      if (!$CHANGED_TPS{ $user{UID} }
        && ((!$tp_info->{age} && ($d == $START_PERIOD_DAY) || $user{ACTIVATE} ne '0000-00-00')
           || ($tp_info->{age} && $user{EXPIRE} eq $ADMIN_REPORT{DATE}) )) {

        if($user{EXPIRE} ne '0000-00-00') {
          if($user{EXPIRE} eq $ADMIN_REPORT{DATE}) {
            if (!$tp_ages{$tp_info->{id}}) {
              $expire = '0000-00-00';
            }
            else {
              my $next_age = $tp_ages{$tp_info->{id}};
              $expire = POSIX::strftime("%Y-%m-%d",
                localtime(POSIX::mktime(0, 0, 0, $d, ($m-1), ($y - 1900), 0, 0, 0) + $next_age * 86400));
print " // $expire //\n ";
              #change
            }
          }
          else {
            next;
          }
        }
        elsif ($user{ACTIVATE} ne '0000-00-00') {
          my ($activate_y, $activate_m, $activate_d) = split(/-/, $user{ACTIVATE}, 3);
          my $active_unixtime = POSIX::mktime(0, 0, 0, $activate_d, $activate_m - 1, $activate_y - 1900, 0, 0, 0);
          if ($date_unixtime - $active_unixtime < 31 * 86400) {
            next;
          }
        }

        $debug_output .= " Login: $user{LOGIN} ($user{UID}) ACTIVATE $user{ACTIVATE} TP_ID: $tp_info->{id} -> $tp_info->{next_tp_id}\n";
        $CHANGED_TPS{ $user{UID} } = 1;

        my $status = 0;
        if($conf{DV_CUSTOM_PERIOD} && $u->{deposit} < $tp_info->{change_price}) {
          $status = 5;
          $expire = $ADMIN_REPORT{DATE};
        }

        $Dv->change({
          UID       => $user{UID},
          STATUS    => $status,
          TP_ID     => $tp_info->{next_tp_id},
          DV_EXPIRE => $expire
        });

        if($tp_info->{change_price}
          && $tp_info->{change_price} > 0
          && $tp_info->{next_tp_id} == $tp_info->{id}
          && ! $status) {
          $Fees->take(\%user, $tp_info->{change_price}, { DESCRIBE => $lang{ACTIVATE_TARIF_PLAN} });
          if($Fees->{errno}) {
            print "Error: $Fees->{errno} $Fees->{errstr}\n";
          }
        }
      }
    }
  }

  return $debug_output;
}

#**********************************************************
=head2 dv_monthly_fees($attr) - Monthly fees

=cut
#**********************************************************
sub dv_monthly_fees {
  my ($attr) = @_;

  my $debug = $attr->{DEBUG} || 0;
  my $debug_output = '';
  $debug_output .= "DV: Monthly periodic payments\n" if ($debug > 1);

  $ADMIN_REPORT{DATE} = $DATE if (!$ADMIN_REPORT{DATE});

  $LIST_PARAMS{TP_ID} = $attr->{TP_ID} if ($attr->{TP_ID});

  my %USERS_LIST_PARAMS = ();
  $USERS_LIST_PARAMS{LOGIN} = $attr->{LOGIN} if ($attr->{LOGIN});
  $USERS_LIST_PARAMS{EXT_BILL} = 1 if ($conf{BONUS_EXT_FUNCTIONS});
  $USERS_LIST_PARAMS{REGISTRATION} = "<$ADMIN_REPORT{DATE}";
  $USERS_LIST_PARAMS{GID}   = $attr->{GID} if ($attr->{GID});

  my $START_PERIOD_DAY = ($conf{START_PERIOD_DAY}) ? $conf{START_PERIOD_DAY} : 1;

  #Change TP to next TP
  #$debug_output .= dv_monthly_next_tp($attr);
  $DEBUG .= $debug_output;

  my %FEES_METHODS = %{ get_fees_types({ SHORT => 1 }) };

  $users = Users->new($db, $admin, \%conf);
  $Tariffs->{debug} = 1 if ($debug > 6);
  my $list = $Tariffs->list({
    %LIST_PARAMS,
    MODULE         => 'Dv',
    EXT_BILL_ACCOUNT=>'_SHOW',
    DOMAIN_ID      => '_SHOW',
    FIXED_FEES_DAY => '_SHOW',
    COLS_NAME      => 1,
    COLS_UPPER     => 1
  });

  my ($y, $m, $d)      = split(/-/, $ADMIN_REPORT{DATE}, 3);
  my $days_in_month    = days_in_month({ DATE => $ADMIN_REPORT{DATE} });
  my $cure_month_begin = "$y-$m-01";
  my $cure_month_end   = "$y-$m-$days_in_month";
  $m--;
  my $date_unixtime = POSIX::mktime(0, 0, 0, $d, $m, $y - 1900, 0, 0, 0);

  #Get Preview month begin end days
  if ($m == 0) {
    $m = 12;
    $y--;
  }

  $m = sprintf("%02d", $m);
  my $days_in_pre_month = days_in_month({ DATE => "$y-$m-01" });

  my $pre_month_begin = "$y-$m-01";
  my $pre_month_end   = "$y-$m-$days_in_pre_month";

  foreach my $TP_INFO (@$list) {
    my $month_fee           = $TP_INFO->{MONTH_FEE};
    my $activate_date       = "<=$ADMIN_REPORT{DATE}";
    $USERS_LIST_PARAMS{DOMAIN_ID} = $TP_INFO->{DOMAIN_ID};
    my %used_traffic = ();

    #Monthfee & min use
    if ($month_fee > 0 || $TP_INFO->{MIN_USE} > 0) {
      $debug_output .= "TP ID: $TP_INFO->{ID} MF: $TP_INFO->{MONTH_FEE} POSTPAID: $TP_INFO->{POSTPAID_MONTHLY_FEE} "
       . "REDUCTION: $TP_INFO->{REDUCTION_FEE} EXT_BILL_ID: $TP_INFO->{EXT_BILL_ACCOUNT} CREDIT: $TP_INFO->{CREDIT} "
       . "MIN_USE: $TP_INFO->{MIN_USE} ABON_DISTR: $TP_INFO->{ABON_DISTRIBUTION}\n" if ($debug > 1);

      #get used  traffic for min use functions
      my %processed_users = ();
      if ($TP_INFO->{MIN_USE} > 0 && $START_PERIOD_DAY && $conf{DV_MIN_USER_FULLPERIOD}) {
        my $interval = "$pre_month_begin/$pre_month_end";
        if ($conf{DV_MIN_USER_FULLPERIOD}) {
          $activate_date = POSIX::strftime("%Y-%m-%d", localtime($date_unixtime - 86400 * 30));
          $interval      = "$activate_date/$ADMIN_REPORT{DATE}";
          $activate_date = "=$activate_date";
        }

        my $report_list = $Sessions->reports(
          {
            INTERVAL => $interval,
            TP_ID    => $TP_INFO->{ID},
            COLS_NAME=> 1
          }
        );
        foreach my $l (@$report_list) {
          $used_traffic{ $l->{uid} } = $l->{sum};
        }
      }

      if ($TP_INFO->{ABON_DISTRIBUTION}) {
        $month_fee = $month_fee / $days_in_month;
      }

      if($TP_INFO->{EXT_BILL_ACCOUNT}) {
        $USERS_LIST_PARAMS{EXT_BILL_ID} = '_SHOW';
        $USERS_LIST_PARAMS{EXT_DEPOSIT} = '_SHOW';
      }

      $Dv->{debug} = 1 if ($debug > 5);
      my $ulist = $Dv->list(
        {
          ACTIVATE     => $activate_date,
          EXPIRE       => "0000-00-00,>$ADMIN_REPORT{DATE}",
          DV_EXPIRE    => "0000-00-00,>$ADMIN_REPORT{DATE}",
          DV_STATUS    => "0;5",
          JOIN_SERVICE => "<2",
          LOGIN_STATUS => 0,
          TP_ID        => $TP_INFO->{ID},
          SORT         => 1,
          PAGE_ROWS    => 1000000,
          TP_CREDIT    => '_SHOW',
          DELETED      => 0,
          LOGIN        => '_SHOW',
          BILL_ID      => '_SHOW',
          REDUCTION    => '_SHOW',
          DEPOSIT      => '_SHOW',
          CREDIT       => '_SHOW',
          COMPANY_ID   => '_SHOW',
          PERSONAL_TP  => '_SHOW',
          COLS_NAME    => 1,
          %USERS_LIST_PARAMS
        }
      );

      foreach my $u (@$ulist) {
        my $EXT_INFO       = '';
        my $ext_deposit_op = $TP_INFO->{EXT_BILL_ACCOUNT} || 0;
        my %user           = (
          LOGIN        => $u->{login},
          UID          => $u->{uid},
          BILL_ID      => ($ext_deposit_op) ? $u->{ext_bill_id} : $u->{bill_id},
          MAIN_BILL_ID => ($ext_deposit_op) ? $u->{bill_id} : 0,
          REDUCTION    => $u->{reduction},
          ACTIVATE     => $u->{activate},
          DEPOSIT      => $u->{deposit},
          CREDIT       => ($u->{credit} > 0) ? $u->{credit} : $TP_INFO->{CREDIT},
          #Old
          # CREDIT       => ($u->{credit} > 0) ? $u->{credit} : ($conf{user_credit_change}) ? 0 : $TP_INFO->{CREDIT},
          COMPANY_ID   => $u->{company_id},
          DV_STATUS    => $u->{dv_status},
          EXT_DEPOSIT  => ($u->{ext_deposit}) ? $u->{ext_deposit} : 0,
        );

        my %FEES_DSC = (
          MODULE            => 'Internet',
          TP_ID             => $TP_INFO->{ID},
          TP_NAME           => $TP_INFO->{NAME},
          FEES_PERIOD_MONTH => $lang{MONTH_FEE_SHORT},
          FEES_METHOD       => $FEES_METHODS{$TP_INFO->{FEES_METHOD}}
        );

        $debug_output .= " Login: $user{LOGIN} ($user{UID}) TP_ID: $u->{tp_id} Fees: $TP_INFO->{MONTH_FEE} REDUCTION: $user{REDUCTION} DEPOSIT: $user{DEPOSIT} CREDIT $user{CREDIT} ACTIVE: $user{ACTIVATE} TP: $u->{tp_id}\n" if ($debug > 3);

        if (!$user{BILL_ID} && $user{MAIN_BILL_ID}) {
          $user{BILL_ID}      = $user{MAIN_BILL_ID};
          $user{MAIN_BILL_ID} = 0;
          $ext_deposit_op     = 0;
        }

        if (! $user{BILL_ID} && ! defined($user{DEPOSIT})) {
          my $ext = ($ext_deposit_op > 0) ? 'Ext bill' : '';
          print "UID: $user{UID} LOGIN: $user{LOGIN} Don't have $ext money account\n";
          next;
        }

        my %FEES_PARAMS = (
          DATE   => $ADMIN_REPORT{DATE},
          METHOD => ($TP_INFO->{FEES_METHOD}) ? $TP_INFO->{FEES_METHOD} : 1,
        );
        my $sum = 0;

        #***************************************************************
        #Min use Makes only 1 of month
        if ($TP_INFO->{MIN_USE} > 0 && $d != $START_PERIOD_DAY && !$conf{DV_MIN_USER_FULLPERIOD}) {
          #Check activation date
          my $min_use = $TP_INFO->{MIN_USE};

          if ($user{REDUCTION} > 0) {
            $min_use = $min_use * (100 - $user{REDUCTION}) / 100;
          }

          #Min use Alignment
          if (!$conf{DV_MIN_USER_FULLPERIOD} && $user{ACTIVATE} ne '0000-00-00') {
            $days_in_month = days_in_month({ DATE => $user{ACTIVATE} });
            my (undef, $activated_d)=split(/-/, $user{ACTIVATE});
            $min_use = sprintf("%.5f", $min_use / $days_in_month * ($days_in_month - $activated_d + $START_PERIOD_DAY));
          }

          my $used = ($used_traffic{ $user{UID} }) ? $used_traffic{ $user{UID} } : 0;
          $FEES_PARAMS{DESCRIBE} = "$lang{MIN_USE}";

          #summary for all company users with same tarif plan
          if ($user{COMPANY_ID} > 0 && $processed_users{ $user{COMPANY_ID} }) {
            next;
          }

          if ($user{COMPANY_ID} > 0) {
            my $company_users = $Dv->list(
              {
                TP_ID      => $TP_INFO->{ID},
                LOGIN      => '_SHOW',
                COMPANY_ID => $user{COMPANY_ID},
                COLS_NAME  => 1
              }
            );
            my @UIDS = ();
            foreach my $c_user (@$company_users) {
              push @UIDS, $c_user->{login};
              $used += $used_traffic{ $user{UID} } if ($used_traffic{ $user{UID} });
              $processed_users{ $user{COMPANY_ID} }++;
            }

            $min_use = $min_use * $processed_users{ $user{COMPANY_ID} };
            $FEES_PARAMS{DESCRIBE} .= "$lang{COMPANY} $lang{LOGINS}: " . join(', ', @UIDS);
          }

          #Get Fees sum for min_user
          if ($conf{MIN_USE_FEES_CONSIDE}) {
            $Fees->list(
              {
                UID     => $user{UID},
                DATE    => ($user{ACTIVATE} ne '0000-00-00') ? ">=$user{ACTIVATE}" : $DATE,
                METHODS => "$conf{MIN_USE_FEES_CONSIDE}",
              }
            );
            $used += $Fees->{SUM} if ($Fees->{SUM});
          }

          $debug_output .= "  USED: $used\n" if ($debug > 3);

          #Make payments
          next if ($used >= $min_use);

          $sum = $min_use - $used;

          if ($TP_INFO->{REDUCTION_FEE} == 1 && $user{REDUCTION} > 0) {
            if ($user{REDUCTION} >= 100) {
              $debug_output .= "UID: $user{UID} SUM: $sum REDUCTION: $user{REDUCTION} next\n" if ($debug > 3);
              next;
            }
            $sum = $sum * (100 - $user{REDUCTION}) / 100;
          }

          if ($TP_INFO->{PAYMENT_TYPE} == 1 || $user{DEPOSIT} + $user{CREDIT} > 0 || $TP_INFO->{POSTPAID_MONTHLY_FEE} == 1) {
            if ($d == $START_PERIOD_DAY) {
              if ($debug > 4) {
                $debug_output .= " UID: $user{UID} SUM: $sum REDUCTION: $user{REDUCTION}\n";
              }
              else {
                $Fees->take(\%user, $sum, {%FEES_PARAMS});

                $debug_output .= " $user{LOGIN} UID: $user{UID} SUM: $sum REDUCTION: $user{REDUCTION}\n" if ($debug > 0);
                if ($user{ACTIVATE} ne '0000-00-00') {
                  $users->change(
                    $user{UID},
                    {
                      UID      => $user{UID},
                      ACTIVATE => '0000-00-00'
                    }
                  );
                }
              }
            }
          }
        }

        #***************************************************************
        #Month Fee
        if ($month_fee > 0) {
          #Make sum
          $sum =  ($u->{personal_tp} > 0 ) ? $u->{personal_tp} : $month_fee;
          if ($TP_INFO->{REDUCTION_FEE} == 1 && $user{REDUCTION} > 0) {
            $sum = $sum * (100 - $user{REDUCTION}) / 100;
          }

          my ($activate_y, $activate_m, $activate_d);
          my $active_unixtime = 0;
          if ($user{ACTIVATE} ne '0000-00-00') {
            ($activate_y, $activate_m, $activate_d) = split(/-/, $user{ACTIVATE}, 3);
            $active_unixtime = POSIX::mktime(0, 0, 0, $activate_d, $activate_m - 1, $activate_y - 1900, 0, 0, 0);
          }

          #Get 2 time fees from main account and ext account and from main
          if ($conf{BONUS_EXT_FUNCTIONS} && $ext_deposit_op > 0) {

            # Small deposit
            if ($TP_INFO->{SMALL_DEPOSIT_ACTION} && $user{EXT_DEPOSIT} + $user{DEPOSIT} + $user{CREDIT} < $sum) {
              if (($user{ACTIVATE} eq '0000-00-00' and $d == $START_PERIOD_DAY)
                || $TP_INFO->{ABON_DISTRIBUTION}
                || ($user{ACTIVATE} ne '0000-00-00' && $date_unixtime - $active_unixtime < 30 * 86400)) {
                $debug_output .= small_deposit_action({
                  TP_INFO   => $TP_INFO,
                  USER_INFO => \%user,
                  DBEUG     => $debug
                });
                next;
              }
            }
            elsif ($sum > $user{EXT_DEPOSIT} && $user{EXT_DEPOSIT} > 0) {
              # Take some sum from ext deposit other from main
              if ((($user{ACTIVATE} eq '0000-00-00' and $d == $START_PERIOD_DAY) || $TP_INFO->{ABON_DISTRIBUTION})
                || $user{ACTIVATE} ne '0000-00-00') {

                if ($date_unixtime - $active_unixtime < 30 * 86400) {
                }
                else {
                  my $ext_deposit_sum = $user{EXT_DEPOSIT};

                  $FEES_PARAMS{DESCRIBE} = fees_dsc_former(\%FEES_DSC);

                  $Fees->take(\%user, $ext_deposit_sum, { %FEES_PARAMS });
                  $sum = $sum - $user{EXT_DEPOSIT};
                  $user{BILL_ID} = $user{MAIN_BILL_ID};
                }

                #and after take rest from main DEPOSIT
                #
              }
            }
            elsif ($user{EXT_DEPOSIT} <= 0) {
              $user{BILL_ID} = $user{MAIN_BILL_ID};
            }
            else {
              $user{DEPOSIT} = $user{EXT_DEPOSIT};
            }
          }

          #Prepaid period credit
          if ($conf{DV_PREPAID_PERIOD_CREDIT}
            && ($user{ACTIVATE} eq '0000-00-00' and $d == $START_PERIOD_DAY)
            && $user{CREDIT} == 0
            && ($user{DEPOSIT} < $sum && $user{DEPOSIT} > 0)) {
            my $credit_period = int($user{DEPOSIT} /  ($sum / $days_in_month));
            if ($credit_period > 0) {
              $users->change($user{UID}, {
                  UID         => $user{UID},
                  CREDIT_DATE => sprintf("%04d-%02d-%02d", (($m < 12) ? $y : $y+1), (($m < 12) ? $m+1 : 1),  $credit_period),
                  CREDIT      => $sum
                });
              $user{CREDIT}  = $sum;
            }
            $debug_output .= " $user{LOGIN} UID: $user{UID} SUM: $sum change credit\n";
          }


          #If deposit is above-zero or TARIF PALIN is POST PAID or PERIODIC PAYMENTS is POSTPAID
          if ($TP_INFO->{PAYMENT_TYPE} == 1 || $user{DEPOSIT} + $user{CREDIT} > 0 || $TP_INFO->{POSTPAID_MONTHLY_FEE} == 1) {
            #*******************************************
            #Unblock Small deposit status
            if ($TP_INFO->{SMALL_DEPOSIT_ACTION} && $month_fee < $user{DEPOSIT}) {
              if ($user{DV_STATUS} && $TP_INFO->{ABON_DISTRIBUTION} && $conf{DV_FULL_MONTH} && $sum * $days_in_month > $user{DEPOSIT}) {
                next;
              }
              if ($debug < 7) {
                $Dv->change(
                  {
                    UID    => $user{UID},
                    STATUS => 0
                  }
                );
                $user{DV_STATUS} = 0;
              }
            }

            #take fees in first day of month
            $FEES_PARAMS{DESCRIBE} = fees_dsc_former(\%FEES_DSC);
            $FEES_PARAMS{DESCRIBE} .= " - $lang{ABON_DISTRIBUTION}" if ($TP_INFO->{ABON_DISTRIBUTION});

            if ($user{DV_STATUS} == 5 && $TP_INFO->{FINE} > 0) {
              if ($conf{DV_FINE_LIMIT} && $user{DEPOSIT} + $user{CREDIT} < $conf{DV_FINE_LIMIT}) {
                next;
              }
              $FEES_PARAMS{DESCRIBE} = "$lang{FINE}";
              $FEES_PARAMS{METHOD}   = 2;
              $sum                   = $TP_INFO->{FINE};
              $EXT_INFO              = "FINE";
            }
            # If activation set to monthly fees taken throught 30 days
            elsif ($user{ACTIVATE} ne '0000-00-00') {
              #Block small deposit
              if ($TP_INFO->{SMALL_DEPOSIT_ACTION} && $sum > $user{DEPOSIT} + $user{CREDIT}
                && (($TP_INFO->{FIXED_FEES_DAY} && ($d == $activate_d || ($d == $START_PERIOD_DAY && $activate_d > 28)))
                || ($date_unixtime - $active_unixtime > 30 * 86400))
              ) {
                $debug_output .= small_deposit_action({
                  TP_INFO   => $TP_INFO,
                  USER_INFO => \%user,
                  DBEUG     => $debug
                });

                next;
              }
              #Static day
              if( ($TP_INFO->{FIXED_FEES_DAY} && ($d == $activate_d || ($d == $START_PERIOD_DAY && $activate_d > 28)))
                || ($date_unixtime - $active_unixtime > 30 * 86400) ) {

                if ($debug > 4) {
                  $debug_output .= " $user{LOGIN} UID: $user{UID} SUM: $sum REDUCTION: $user{REDUCTION}\n";
                }
                else {
                  $FEES_PARAMS{DESCRIBE} .= " ($ADMIN_REPORT{DATE}-" . (POSIX::strftime("%Y-%m-%d", localtime($date_unixtime + 86400 * 30))) . ')' if (!$TP_INFO->{ABON_DISTRIBUTION});

                  $Fees->take(\%user, $sum, \%FEES_PARAMS);
                  $debug_output .= " $user{LOGIN} UID: $user{UID} SUM: $sum REDUCTION: $user{REDUCTION} CHANGE ACTIVATE\n" if ($debug > 0);
                  if ($Fees->{errno}) {
                    print "Dv Error: [ $user{UID} ] $user{LOGIN} SUM: $sum [$Fees->{errno}] $Fees->{errstr} ";
                    if ($Fees->{errno} == 14) {
                      print "UID: $user{UID} LOGIN: $user{LOGIN} - Don't have money account";
                    }
                    print "\n";
                  }
                  else {
                    $users->change(
                      $user{UID},
                      {
                        UID      => $user{UID},
                        ACTIVATE => $ADMIN_REPORT{DATE}
                      }
                    );
                  }
                  next;
                }
              }
              elsif ($TP_INFO->{ABON_DISTRIBUTION}) {
                $EXT_INFO .= "CHANGE ACTIVATE\n" if ($debug > 0);
              }
              else {
                next;
              }
            }
            elsif (($user{ACTIVATE} eq '0000-00-00' and $d == $START_PERIOD_DAY) || $TP_INFO->{ABON_DISTRIBUTION}) {
              #Block small deposit
              if ($TP_INFO->{SMALL_DEPOSIT_ACTION} && $sum > $user{DEPOSIT} + $user{CREDIT}) {
                if ($TP_INFO->{SMALL_DEPOSIT_ACTION} == -1) {
                  if($debug < 7) {
                    $Dv->change(
                      {
                        UID    => $user{UID},
                        STATUS => 5
                      }
                    );
                  }
                }
                else {
                  if($debug < 7) {
                    $Dv->change(
                      {
                        UID   => $user{UID},
                        TP_ID => $TP_INFO->{SMALL_DEPOSIT_ACTION}
                      });
                  }
                }
                $debug_output .= " SMALL_DEPOSIT_BLOCK." if ($debug > 3);
                next;
              }
              #Skip fees for small deposit actions
              elsif ($user{DV_STATUS} == 5) {
                $debug_output .= " UID: $user{UID} SUM: $sum REDUCTION: $user{REDUCTION}\n" if ($debug > 2);
                next;
              }
            }
            else {
              next;
            }

            # get fees
            if ($debug > 4) {
              $debug_output .= " UID: $user{UID} SUM: $sum REDUCTION: $user{REDUCTION}\n";
            }
            else {
              $FEES_PARAMS{DESCRIBE} .= " ($cure_month_begin-$cure_month_end)" if (!$TP_INFO->{ABON_DISTRIBUTION});
              $Fees->take(\%user, $sum, {%FEES_PARAMS});
              $debug_output .= " $user{LOGIN}  UID: $user{UID} SUM: $sum REDUCTION: $user{REDUCTION} $EXT_INFO\n" if ($debug > 0);
            }
          }
          else {
            # Get Fine
            if ($TP_INFO->{FINE} > 0) {
              if ($conf{DV_FINE_LIMIT} && $user{DEPOSIT} + $user{CREDIT} < $conf{DV_FINE_LIMIT}) {
                next;
              }
              %FEES_PARAMS = (
                DESCRIBE => "$lang{FINE}",
                METHOD   => 1,
                DATE     => $ADMIN_REPORT{DATE},
              );

              $sum      = $TP_INFO->{FINE};
              $EXT_INFO = "FINE";
              $Fees->take(\%user, $sum, {%FEES_PARAMS});
              $debug_output .= " $user{LOGIN}  UID: $user{UID} SUM: $sum REDUCTION: $user{REDUCTION} FINE\n" if ($debug > 0);
            }

            #Block small deposit
            if ($user{DV_STATUS} == 0 && $TP_INFO->{SMALL_DEPOSIT_ACTION} &&
              (($user{ACTIVATE} ne '0000-00-00' && $date_unixtime - $active_unixtime > 30 * 86400)
                ||
                ($user{ACTIVATE} eq '0000-00-00' && ($d == $START_PERIOD_DAY || $TP_INFO->{ABON_DISTRIBUTION}))
              )
            ) {
              if ($TP_INFO->{SMALL_DEPOSIT_ACTION} == -1) {
                if ($debug < 7){
                  if ($user{DV_STATUS} != 5) {
                    $Dv->change(
                      {
                        UID    => $user{UID},
                        STATUS => 5
                      }
                    );
                  }
                }
              }
              else {
                if ($debug < 7) {
                  $Dv->change(
                    {
                      UID   => $user{UID},
                      TP_ID => $TP_INFO->{SMALL_DEPOSIT_ACTION}
                    }
                  );
                }
              }
              $debug_output .= " SMALL_DEPOSIT_BLOCK" if ($debug > 3);
              next;
            }
          }
        }
      }
    }
  }

  #=====================================

  #Make traffic recalculation for expration
  if ($d == 1) {
    $list = $Tariffs->list({%LIST_PARAMS, MODULE => 'Dv' });
    $debug_output .= "Total month price\n";
    require Billing;
    Billing->import();
    my $Billing = Billing->new($db, \%conf);

    foreach my $tp_line (@$list) {
      my $ti_list = $Tariffs->ti_list({ TP_ID => $tp_line->[18] });
      next if ($Tariffs->{TOTAL} != 1);

      foreach my $ti (@$ti_list) {

        my $tt_list = $Tariffs->tt_list({ TI_ID => $ti->[0], COLS_NAME => 1 });
        next if ($Tariffs->{TOTAL} != 1);

        my %expr_hash = ();
        foreach my $tt (@$tt_list) {
          my $expression = $tt->{expression};
          next if ($expression !~ /MONTH_TRAFFIC_/);

          $expression =~ s/MONTH_TRAFFIC/TRAFFIC/g;

          $debug_output .= "TP: $tp_line->[0] TI: $ti->[0] TT: $tt->{id}\n";
          $debug_output .= "  Expr: $expression\n" if ($debug > 3);

          $expr_hash{ $tt->{id} } = $expression;
        }

        next if (!defined($expr_hash{0}));

        my $ulist = $Dv->list(
          {
            ACTIVATE     => "<=$ADMIN_REPORT{DATE}",
            EXPIRE       => "0000-00-00,>$ADMIN_REPORT{DATE}",
            DV_EXPIRE    => "0000-00-00,>$ADMIN_REPORT{DATE}",
            DV_STATUS    => 0,
            LOGIN_STATUS => 0,
            TP_ID        => $tp_line->[0],
            SORT         => 1,
            PAGE_ROWS    => 1000000,
            TP_CREDIT    => '_SHOW',
            COMPANY_ID   => '_SHOW',
            LOGIN        => '_SHOW',
            BILL_ID      => '_SHOW',
            REDUCTION    => '_SHOW',
            DEPOSIT      => '_SHOW',
            CREDIT       => '_SHOW',
            COLS_NAME    => 1,
            %USERS_LIST_PARAMS
          }
        );

        foreach my $u (@$ulist) {
          my %user = (
            LOGIN      => $u->{login},
            UID        => $u->{uid},
            BILL_ID    => ($tp_line->[14] > 0) ? $u->{ext_bill_id} : $u->{bill_id},
            REDUCTION  => $u->{reduction},
            ACTIVATE   => $u->{activate},
            DEPOSIT    => $u->{deposit},
            CREDIT     => ($u->{credit} > 0) ? $u->{credit} : $tp_line->[15],
            COMPANY_ID => $u->{company_id}
          );

          $debug_output .= " Login: $u->{login} ($u->{uid}) TP_ID: $u->{tp_id} Fees: - REDUCTION: $u->{reduction} $u->{deposit} $u->{credit} - $user{ACTIVATE}\n" if ($debug > 3);

          #Summary for company users
          #         my @UIDS  = ();
          #         if ($$processed_users{$user{COMPANY_ID}}) {
          #            next;
          #          }
          #
          #         if ($user{COMPANY_ID}) {
          #           my $company_users = $ulist = $Dv->list({ TP_ID      => $tp_line->[0],
          #                                                    COMPANY_ID => $user{COMPANY_ID}
          #                                                   });
          #           $$processed_users{$user{COMPANY_ID}}=1;
          #
          #           foreach my $c_user ( @$company_users ) {
          #               push @UIDS, $c_user->[7];
          #            }
          #
          #           print "$user{LOGIN} hello $user{COMPANY_ID} // ";
          #           print @UIDS ,"\n";
          #          }

          $Billing->{PERIOD_TRAFFIC} = undef;
          my $RESULT = $Billing->expression(
            $user{UID},
            \%expr_hash,
            {
              START_PERIOD => $user{ACTIVATE},
              debug        => 0,
              #UIDS         => ($#UIDS > -1) ? join(',', @UIDS) : '',
              #ACCOUNTS_SUMMARY => $#UIDS+1
            }
          );

          #my $message = '';
          my $sum     = 0;

          my %FEES_PARAMS = (
            DATE   => $ADMIN_REPORT{DATE},
            METHOD => 0,
          );

          if ($RESULT->{TRAFFIC_IN}) {
            $FEES_PARAMS{DESCRIBE} = "$lang{USED}\n $lang{TRAFFIC}: $RESULT->{TRAFFIC_IN}\n SUM: $RESULT->{PRICE_IN}";
            $sum = $RESULT->{TRAFFIC_IN} * $RESULT->{PRICE_IN};
          }

          if ($RESULT->{TRAFFIC_OUT}) {
            $FEES_PARAMS{DESCRIBE} = "$lang{USED} $lang{TRAFFIC}: $RESULT->{TRAFFIC_OUT} SUM: $RESULT->{PRICE_OUT}";
            $sum = $RESULT->{TRAFFIC_OUT} * $RESULT->{PRICE_OUT};
          }
          elsif ($RESULT->{TRAFFIC_SUM}) {
            $FEES_PARAMS{DESCRIBE} = "$lang{USED} $lang{TRAFFIC}: $RESULT->{TRAFFIC_SUM} SUM: $RESULT->{PRICE}";
            $sum = $RESULT->{TRAFFIC_SUM} * $RESULT->{PRICE};
          }

          $Fees->take(\%user, $sum, {%FEES_PARAMS});
        }

      }
    }
  }

  $DEBUG .= $debug_output;
  return $debug_output;
}

#**********************************************************
=head2 small_deposit_action($attr)

  Arguments:
    $attr
      TP_INFO
      USER_INFO
      DEBUG

=cut
#**********************************************************
sub small_deposit_action {
  my ($attr) = @_;

  my $TP_INFO      = $attr->{TP_INFO};
  my $user_info    = $attr->{USER_INFO};
  my $debug_output = q{};
  my $debug        = $attr->{DEBUG} || 0;

  if ($TP_INFO->{SMALL_DEPOSIT_ACTION} == -1) {
    if ($debug < 7) {
      if ($user_info->{DV_STATUS} != 5) {
        $Dv->change(
          {
            UID    => $user_info->{UID},
            STATUS => 5
          }
        );
      }
    }
  }
  else {
    if ($debug < 7) {
      $Dv->change(
        {
          UID   => $user_info->{UID},
          TP_ID => $TP_INFO->{SMALL_DEPOSIT_ACTION}
        }
      );
    }
  }

  $debug_output .= " SMALL_DEPOSIT_BLOCK." if ($debug > 3);

  return $debug_output;
}

#**********************************************************
=head2 dv_users_warning_messages($attr)

=cut
#**********************************************************
sub dv_users_warning_messages {
  my ($attr) = @_;

  $ADMIN_REPORT{USERS_WARNINGS} = sprintf("%-14s| %4s|%-20s| %9s| %8s|\n", $lang{LOGIN}, 'TP', $lang{TARIF_PLAN}, $lang{DEPOSIT}, $lang{CREDIT}) . "---------------------------------------------------------------\n";
  if ($ADMIN_REPORT{NO_USERS_WARNINGS}) {
    return 0;
  }

  require Internet::Negative_deposit;
  my $debug = $attr->{DEBUG} //= 0;
  my $debug_output = '';
  $debug_output .= "DV: Daily warning messages\n" if ($debug > 1);

  my %LIST_PARAMS = (USERS_WARNINGS => 1);
  $LIST_PARAMS{ALERT_PERIOD}=$conf{DV_ALERT_REDIRECT_DAYS} if ($conf{DV_ALERT_REDIRECT_DAYS});
  $LIST_PARAMS{LOGIN} = $attr->{LOGIN} if ($attr->{LOGIN});
  $Dv->{debug}=1 if($debug > 5);
  my $dv_list = $Dv->list({
    %LIST_PARAMS,
    LOGIN             => '_SHOW',
    FIO               => '_SHOW',
    TP_ID             => '_SHOW',
    TP_NAME           => '_SHOW',
    DEPOSIT           => '_SHOW',
    CREDIT            => '_SHOW',
    EMAIL             => '_SHOW',
    CREDIT            => '_SHOW',
    TP_CREDIT         => '_SHOW',
    MONTH_FEE         => '_SHOW',
    DAY_FEE           => '_SHOW',
    ABON_DISTRIBUTION => '_SHOW',
    ONLINE_IP         => '_SHOW',
    _SKIP_NEG_WARN    => '_SHOW',
    DV_STATUS         => 0,
    LOGIN_STATUS      => 0,
    COLS_NAME         => 1,
    COLS_UPPER        => 1
  });

  if ($Dv->{TOTAL} < 1) {
    $DEBUG .= $debug_output;
    return $debug_output;
  }

  my @allert_redirect_days = split(/,\s?/, $conf{DV_ALERT_REDIRECT_DAYS} || '');

  foreach my $u (@$dv_list) {
    if($u->{_SKIP_NEG_WARN}) {
      next;
    }

    my $type='email';
    my $email = ((!defined($u->{EMAIL})) || $u->{EMAIL} eq '') ? (($conf{USERS_MAIL_DOMAIN}) ? "$u->{LOGIN}\@$conf{USERS_MAIL_DOMAIN}" : '') : $u->{EMAIL};

    if (($u->{MONTH_FEE} && $u->{ABON_DISTRIBUTION})
      || $u->{DAY_FEE}) {
      my $day_fee = $u->{DAY_FEE} || 0;
      if ($u->{MONTH_FEE} > 0 && $u->{ABON_DISTRIBUTION}) {
        $day_fee = $u->{MONTH_FEE} / days_in_month({ DATE => $DATE });
      }

      if ($day_fee > 0) {
        #$u->{to_next_period} = ($u->{DEPOSIT} + (($u->{CREDIT}==0) ? $u->{TP_CREDIT} : $u->{CREDIT})) / $day_fee;
        $u->{to_next_period} = int(($u->{DEPOSIT} + (($u->{CREDIT}==0) ? 0 : $u->{CREDIT})) / $day_fee);
      }
    }

    if($conf{DV_ALERT_REDIRECT_FILTER} && in_array($u->{to_next_period}, \@allert_redirect_days)) {
      $debug_output .= "  $u->{login} Redirect\n";
      $type='redirect';
      $Dv->change({
        UID       => $u->{uid},
        FILTER_ID => $conf{DV_ALERT_REDIRECT_FILTER}
      });

      if($u->{client_ip}) {
        mk_redirect({ IP => $u->{client_ip} });
      }
    }

    if ($email eq '') { next; }

    my $info = sprintf("%-14s| %4d|%-20s| %9.4f| %8.2f| %6s|\n", $u->{login},
      $u->{tp_num},
      $u->{tp_name},
      $u->{deposit},
      $u->{credit},
      $type
    );

    $ADMIN_REPORT{USERS_WARNINGS} .= $info;
    $debug_output .= $info if ($debug > 3);

    if ($debug < 5) {
      my $message = $html->tpl_show(_include('dv_users_warning_messages', 'Dv'),
        { %$u, DATE => $DATE, TIME => $TIME },
        { OUTPUT2RETURN => 1 });

      sendmail($conf{ADMIN_MAIL}, $email, $lang{BILL_INFO}, $message,
        "$conf{MAIL_CHARSET}", "2 (High)", { TEST => (($debug>6)?1:0) });
    }
  }

  $ADMIN_REPORT{USERS_WARNINGS} .= "---------------------------------------------------------------
$lang{TOTAL}: $Dv->{TOTAL}\n";

  if ($debug > 5) {
    $debug_output .= $ADMIN_REPORT{USERS_WARNINGS};
  }

  $DEBUG .= $debug_output;
  return $debug_output;
}

#***********************************************************
=head2 dv_sheduler($type, $action, $uid, $attr)

=cut
#***********************************************************
sub dv_sheduler {
  my ($type, $action, $uid, $attr) = @_;

  my $debug = $attr->{DEBUG} || 0;

  my $user = $Dv->info($uid);
  if ($type eq 'tp') {
    $Dv->change(
      {
        UID   => $uid,
        TP_ID => $action
      }
    );

    if ($attr->{GET_ABON} && $attr->{GET_ABON} eq '-1' && $attr->{RECALCULATE} && $attr->{GET_ABON} eq '-1') {
      print "Skip: GET_ABON, RECALCULATE\n" if ($debug > 1);
      return 0;
    }

    my $d  = (split(/-/, $ADMIN_REPORT{DATE}, 3))[2];
    my $START_PERIOD_DAY = $conf{START_PERIOD_DAY} || 1;
    $FORM{RECALCULATE}= 0;

    if ($Dv->{errno}) {
      return $Dv->{errno};
    }
    else {
      if ($Dv->{TP_INFO}->{ABON_DISTRIBUTION} || $d == $START_PERIOD_DAY) {
        $Dv->{TP_INFO}->{MONTH_FEE} = 0;
      }
      $user = undef;
      $FORM{RECALCULATE} = 1;
      service_get_month_fee($Dv, { QUITE    => 1,
          SHEDULER => 1,
          DATE     => $attr->{DATE}  });
    }
  }
  elsif ($type eq 'status') {
    $Dv->change(
      {
        UID    => $uid,
        STATUS => $action
      }
    );

    #Get fee for holdup service
    if ($action == 3) {
      my $active_fees = 0;
      if ($conf{DV_USER_SERVICE_HOLDUP}) {
        $active_fees =  (split(/:/, $conf{DV_USER_SERVICE_HOLDUP}))[5];
      }

      if ($active_fees && $active_fees > 0) {
        $user = $users->info($uid);
        $Fees->take(
          $user,
          $active_fees,
          {
            DESCRIBE => $lang{HOLD_UP},
            DATE     => "$ADMIN_REPORT{DATE} $TIME",
          }
        );
        if ($Fees->{errno}) {
          print "Error: Holdup fees: $Fees->{errno} $Fees->{errstr}\n";
        }
      }
    }
    elsif ($action == 0) {
      service_get_month_fee($Dv, {
        QUITE    => 1,
        SHEDULER => 1, #($attr->{SHEDULEE_ONLY}) ? undef,
        DATE     => $attr->{DATE}
      });
    }

    if ($Dv->{errno} && $Dv->{errno} == 15) {
      return $Dv->{errno};
    }
  }

  return 1;
}

#***********************************************************
=head2 dv_report($type, $attr) - Email admin reports

  Arguments:
    $type  - Type of report
               daily
               monthly
    $attr  -
       LIST_PARAMS
       DATE
       DEBUG

  Results:

=cut
#***********************************************************
sub dv_report {
  my ($type, $attr) = @_;
  my $REPORT = "Module: DV ($type)\n";

  %LIST_PARAMS = %{ $attr->{LIST_PARAMS} } if (defined($attr->{LIST_PARAMS}));

  my $debug = $attr->{DEBUG} || 0;
  if ($debug > 6) {
    $Sessions->{debug}=1;
  }

  if ($type eq 'daily') {
    $REPORT .= sprintf("%-14s| %5s| %9s| %9s| %10s| %9s|\n", $lang{LOGIN}, $lang{SESSIONS}, $lang{TRAFFIC}, "$lang{TRAFFIC} 2", $lang{DURATION}, $lang{SUM});
    $REPORT .= "---------------------------------------------------------\n";
    my $list = $Sessions->reports2({
      %LIST_PARAMS,
      #USERS         => '_SHOW',
      SESSIONS      => '_SHOW',
      TRAFFIC_SUM   => '_SHOW',
      TRAFFIC_2_SUM => '_SHOW',
      DURATION_SEC  => '_SHOW',
      SUM           => '_SHOW',
      COLS_NAME     => 1
    });

    if($Sessions->{errno}) {
      $REPORT = "[$Sessions->{errno}] $Sessions->{errstr}\n";
      return $REPORT;
    }

    foreach my $line (@$list) {
      $REPORT .= sprintf("%-14s| %5d| %9s| %9s| %8s| %9.4f|\n",
        $line->{login},
        $line->{sessions},
        int2byte($line->{traffic_sum}),
        int2byte($line->{traffic_2_sum}),
        sec2time($line->{duration_sec}, { str => 1 }),
        $line->{sum}
      );
    }

    $REPORT .= "---------------------------------------------------------\n";
    $REPORT .= sprintf(
      "%-30s| %20s|\n%-30s| %20s|\n%-30s| %20s|\n%-30s| %20s|\n%-30s| %20s|\n%-30s| %20s|\n",
      $lang{USERS}, $Sessions->{USERS},
      $lang{SESSIONS}, $Sessions->{SESSIONS},
      $lang{TRAFFIC}, int2byte($Sessions->{TRAFFIC}),
      "$lang{TRAFFIC} 2", int2byte($Sessions->{TRAFFIC_2}),
      $lang{DURATION}, $Sessions->{DURATION},
      $lang{SUM}, $Sessions->{SUM}
    );

  }
  elsif ($type eq 'monthly') {
    $REPORT .= sprintf(" %12s| %5s| %5s| %10s| %10s| %12s| %9s|\n", $lang{DATE}, $lang{USERS}, $lang{SESSIONS}, $lang{TRAFFIC}, "$lang{TRAFFIC} 2", $lang{DURATION}, $lang{SUM});
    $REPORT .= "---------------------------------------------------------\n";

    my $list = $Sessions->reports2({%LIST_PARAMS,
      USERS_COUNT   => '_SHOW',
      SESSIONS      => '_SHOW',
      TRAFFIC_SUM   => '_SHOW',
      TRAFFIC_2_SUM => '_SHOW',
      DURATION_SEC  => '_SHOW',
      SUM           => '_SHOW',
      COLS_NAME     => 1
    });

    if($Sessions->{errno}) {
      $REPORT = "[$Sessions->{errno}] $Sessions->{errstr}\n";
      return $REPORT;
    }

    foreach my $line (@$list) {
      #   u.id, count(l.id), sum(l.sent + l.recv), sum(l.sent2 + l.recv2), sec_to_time(sum(l.duration)), sum(l.sum), l.id
      $REPORT .= sprintf(" %12s| %5s| %5s| %10s| %10s| %12s| %9.4f|\n",
        $line->{date},
        $line->{users_count},
        $line->{sessions},
        int2byte($line->{traffic_sum}),
        int2byte($line->{traffic_2_sum}),
        sec2time($line->{duration_sec}, { str => 1 }),
        $line->{sum}
      );
    }

    $REPORT .= "---------------------------------------------------------\n";
    $REPORT .= sprintf(
      "%-30s| %20s|\n%-30s| %20s|\n%-30s| %20s|\n%-30s| %20s|\n%-30s| %20s|\n%-30s| %20s|\n",
      $lang{USERS}, $Sessions->{USERS},
      $lang{SESSIONS}, $Sessions->{SESSIONS},
      $lang{TRAFFIC}, int2byte($Sessions->{TRAFFIC}),
      "$lang{TRAFFIC} 2", int2byte($Sessions->{TRAFFIC_2}),
      $lang{DURATION}, $Sessions->{DURATION}, $lang{SUM}, $Sessions->{SUM}
    );
  }

  return $REPORT;
}


1;