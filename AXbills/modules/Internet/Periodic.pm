=head1 NAME

  Internet Periodic

=cut

use strict;
use warnings FATAL => 'all';
use AXbills::Base qw(days_in_month in_array sendmail int2byte sec2time);
use Internet;
use Internet::Sessions;

our(
  $db,
  $admin,
  %conf,
  %ADMIN_REPORT,
  %lang,
  $html
);

my $Internet = Internet->new($db, $admin, \%conf);
my $Sessions = Internet::Sessions->new($db, $admin, \%conf);
my $Fees     = Fees->new($db, $admin, \%conf);
my $Payments = Finance->payments($db, $admin, \%conf);
my $Tariffs  = Tariffs->new($db, \%conf, $admin);

#**********************************************************
=head2 internet_periodic_logrotate($attr)

  Arguments:
    SKIP_ROTATE - Skip all log rotate

=cut
#**********************************************************
sub internet_periodic_logrotate {
  my ($attr) = @_;
  my $debug = $attr->{DEBUG} || 0;

  return '' if ($attr->{SKIP_ROTATE} || $attr->{LOGON_ACTIVE_USERS} || $attr->{LOGIN} || $attr->{SRESTART});

  # Clean s_detail table
  my (undef, undef, $d) = split(/-/, $ADMIN_REPORT{DATE}, 3);
  $conf{INTERNET_LOG_CLEAN_PERIOD} = 180 if (!$conf{INTERNET_LOG_CLEAN_PERIOD});
  if ($d == 1 && $conf{INTERNET_LOG_CLEAN_PERIOD}) {
    $DEBUG .= "Make log rotate\n" if ($debug > 0);

    if($debug > 6) {
      $Sessions->{debug}=1;
    }
    $Sessions->log_rotate(
      {
        TYPES  => [ 'SESSION_DETAILS', 'SESSION_INTERVALS' ],
        PERIOD => $conf{INTERNET_LOG_CLEAN_PERIOD}
      }
    );
  }
  else {
    $Sessions->log_rotate({ DAILY => 1 });
  }

  return 1;
}

#**********************************************************
=head2 internet_daily_fees($attr) - daily fees

=cut
#**********************************************************
sub internet_daily_fees {
  my ($attr) = @_;

  my $debug        = $attr->{DEBUG} || 0;
  my $debug_output = '';
  # Fix daily fees: DOMAIN_ID
  # my $DOMAIN_ID    = $attr->{DOMAIN_ID} || 0;

  if ($attr->{USERS_WARNINGS_TEST}) {
    return $debug_output;
  }

  if (!$ADMIN_REPORT{DATE}) {
    $ADMIN_REPORT{DATE} = $DATE ;
  }

  $debug_output .= "Internet: Daily periodic fees\n" if ($debug > 1);

  $LIST_PARAMS{TP_ID}     = $attr->{TP_ID} if ($attr->{TP_ID});
  # $LIST_PARAMS{DOMAIN_ID} = $DOMAIN_ID;
  my %USERS_LIST_PARAMS         = ( REGISTRATION => "<$ADMIN_REPORT{DATE}" );
  $USERS_LIST_PARAMS{LOGIN}     = $attr->{LOGIN} if ($attr->{LOGIN});
  $USERS_LIST_PARAMS{GID}       = $attr->{GID} if ($attr->{GID});
  $USERS_LIST_PARAMS{COMPANY_ID}= $attr->{COMPANY_ID} if ($attr->{COMPANY_ID});

  $Tariffs->{debug} = 1 if ($debug > 6);

  my $list = $Tariffs->list({
    %LIST_PARAMS,
    EXT_BILL_ACCOUNT     =>'_SHOW',
    EXT_BILL_FEES_METHOD => '_SHOW',
    MODULE               => 'Dv;Internet',
    COLS_NAME            => 1,
    COLS_UPPER           => 1
  });

  my %FEES_METHODS = %{ get_fees_types({ SHORT => 1 }) };

  foreach my $TP_INFO (@$list) {
    my %FEES_PARAMS = ();
    if ($TP_INFO->{DAY_FEE} > 0) {
      if ($debug > 1) {
        $debug_output .= "TP ID: $TP_INFO->{ID} DF: $TP_INFO->{DAY_FEE} POSTPAID: $TP_INFO->{POSTPAID_DAILY_FEE} "
          . "REDUCTION: $TP_INFO->{REDUCTION_FEE} EXT_BILL: $TP_INFO->{EXT_BILL_ACCOUNT} CREDIT: $TP_INFO->{CREDIT}\n";
      }

      $USERS_LIST_PARAMS{DOMAIN_ID} = $TP_INFO->{DOMAIN_ID};
      #Get active yesterdays logins
      my %active_logins = ();
      if ($TP_INFO->{ACTIVE_DAY_FEE} > 0) {
        my $online_list = $Sessions->online({
          UID          => '_SHOW',
          LOGIN        => '_SHOW',
          TP_ID        => $TP_INFO->{TP_ID},
          STARTED      => "<$ADMIN_REPORT{DATE} 00:00:00",
          GUEST        => 0
        });

        foreach my $l (@$online_list) {
          $active_logins{ $l->{login} } = $l->{uid};
        }

        my $report_list = $Sessions->reports({
          INTERVAL => "$attr->{YESTERDAY}/$attr->{YESTERDAY}",
          TP_ID    => $TP_INFO->{TP_ID},
          GUEST    => 0,
          COLS_NAME=> 1
        });

        foreach my $l (@$report_list) {
          $active_logins{ $l->{id} } = $l->{uid};
        }
      }

      if($TP_INFO->{EXT_BILL_ACCOUNT}) {
        $USERS_LIST_PARAMS{EXT_BILL_ID} = '_SHOW';
        $USERS_LIST_PARAMS{EXT_DEPOSIT} = '_SHOW';
      }

      $Internet->{debug} = 1 if ($debug > 6);
      my $ulist = $Internet->user_list({
        LOGIN           => '_SHOW',
        ACTIVATE        => "<=$ADMIN_REPORT{DATE}",
        EXPIRE          => "0000-00-00,>$ADMIN_REPORT{DATE}",
        INTERNET_EXPIRE => "0000-00-00,>$ADMIN_REPORT{DATE}",
        JOIN_SERVICE    => "<2",
        INTERNET_STATUS => "0", # Old "0;5"
        LOGIN_STATUS    => 0,
        TP_ID           => $TP_INFO->{TP_ID},
        SORT            => 1,
        PAGE_ROWS       => 1000000,
        TP_CREDIT       => '_SHOW',
        REDUCTION       => '_SHOW',
        BILL_ID         => '_SHOW',
        DEPOSIT         => '_SHOW',
        CREDIT          => '_SHOW',
        DELETED         => 0,
        COLS_NAME       => 1,
        GROUP_BY        => 'internet.id',
        %USERS_LIST_PARAMS
      });

      foreach my $u (@$ulist) {
        #Check bill id and deposit
        my %user = (
          LOGIN     => $u->{login},
          UID       => $u->{uid},
          ID        => $u->{id},
          #Check ext deposit
          BILL_ID   => ($TP_INFO->{EXT_BILL_ACCOUNT} > 0) ? $u->{ext_bill_id} : $u->{bill_id},
          REDUCTION => $u->{reduction},
          ACTIVATE  => $u->{activate},
          DEPOSIT   => $u->{deposit},
          #CREDIT    => ($u->{credit} > 0) ? $u->{credit} : ($conf{user_credit_change}) ? 0 : $TP_INFO->{CREDIT},
          CREDIT    => ($u->{credit} > 0) ? $u->{credit} : $TP_INFO->{CREDIT},
          INTERNET_STATUS => $u->{internet_status},
          EXT_BILL_ID=> $u->{ext_bill_id}
        );

        if (defined($user{BILL_ID}) && $user{BILL_ID} > 0 && defined($user{DEPOSIT})) {
          #If deposit is above-zero or TARIF PALIN is POST PAID or PERIODIC PAYMENTS is POSTPAID
          #Active day fees
          if ( (($user{DEPOSIT} + $user{CREDIT} > 0 || $TP_INFO->{PAYMENT_TYPE} == 1 || $TP_INFO->{POSTPAID_DAILY_FEE} == 1)
                 && $TP_INFO->{ACTIVE_DAY_FEE} == 0)
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
              TP_NUM          => $TP_INFO->{ID},
              TP_ID           => $TP_INFO->{TP_ID},
              TP_NAME         => $TP_INFO->{NAME},
              FEES_PERIOD_DAY => $lang{DAY_FEE_SHORT},
              FEES_METHOD     => $FEES_METHODS{$TP_INFO->{FEES_METHOD}},
              ID              => ($user{ID}) ? ' '. $user{ID} : undef,
            );

            my %PARAMS = (
              DATE     => "$ADMIN_REPORT{DATE} $TIME",
              METHOD   => ($TP_INFO->{FEES_METHOD}) ? $TP_INFO->{FEES_METHOD} : 1,
              EXT_BILL_METHOD => ($TP_INFO->{EXT_BILL_FEES_METHOD}) ? $TP_INFO->{EXT_BILL_FEES_METHOD} : undef,
              DESCRIBE => fees_dsc_former(\%FEES_DSC),
            );

            if ($debug > 4) {
              $debug_output .= " UID: $user{UID} SUM: $sum REDUCTION: $user{REDUCTION}\n";
            }

            if ($debug < 8) {
              if($sum <= 0) {
                $debug_output .= "!!REDUCTION!! $user{LOGIN} UID: $user{UID} SUM: $sum REDUCTION: $user{REDUCTION}\n";
                next;
              }

              $Fees->take(\%user, $sum, {%PARAMS});
              if ($Fees->{errno}) {
                print "Internet Error: [ $user{UID} ] $user{LOGIN} SUM: $sum [$Fees->{errno}] $Fees->{errstr} ";
                if ($Fees->{errno} == 14) {
                  print "[ $user{UID} ] $user{LOGIN} - Don't have money account";
                }
                print "\n";
              }
              elsif ($debug > 0) {
                $debug_output .= " $user{LOGIN}  UID: $user{UID} SUM: $sum REDUCTION: $user{REDUCTION}\n";
              }
            }
          }

          # If status too small deposit get fine from user
          elsif ($TP_INFO->{FINE} > 0 && ( $user{INTERNET_STATUS} == 5 || $user{DEPOSIT} + $user{CREDIT} < 0 )) {
            if ($conf{INTERNET_FINE_LIMIT} && $user{DEPOSIT} + $user{CREDIT} < $conf{INTERNET_FINE_LIMIT}) {
              next;
            }

            %FEES_PARAMS = (
              DESCRIBE => $lang{FINE},
              METHOD   => 2,
              DATE     => $ADMIN_REPORT{DATE},
            );
            #$EXT_INFO = "FINE";
            if($debug < 8) {
              $Fees->take(\%user, $TP_INFO->{FINE}, { %FEES_PARAMS });
            }

            $debug_output .= " $user{LOGIN}  UID: $user{UID} SUM: $TP_INFO->{FINE} REDUCTION: $user{REDUCTION} FINE\n" if ($debug > 0);
          }
        }
        else {
          print "[ $user{UID} ] $user{LOGIN} - Don't have money account (Internet)\n";
        }
      }
    }
  }

  #Daily bonus PAYMENTS
  #Make traffic recalculation for expration
  $list = $Tariffs->list({
    %LIST_PARAMS,
    MODULE    => 'Dv;Internet',
    COLS_NAME => 1
  });
  $debug_output .= "Bonus payments\n";
  require Billing;
  Billing->import();
  my $Billing = Billing->new($db, \%conf);

  foreach my $tp_line (@$list) {
    my $ti_list = $Tariffs->ti_list({ TP_ID => $tp_line->{tp_id} });
    next if ($Tariffs->{TOTAL} != 1);

    $debug_output .= "TP_ID: $tp_line->{tp_id}\n" if ($debug > 6);
    foreach my $ti (@$ti_list) {

      my $tt_list = $Tariffs->tt_list({
        EXPRESSION => '_SHOW',
        TI_ID      => $ti->[0],
        COLS_NAME  => 1
      });
      next if ($Tariffs->{TOTAL} < 1);

      my %expr_hash     = ();
      my $traffic_class = 0;

      foreach my $tt (@$tt_list) {
        my $expression = $tt->{expression};
        next if ($expression !~ /BONUS_TRAFFIC_/);

        $expression =~ s/BONUS_TRAFFIC/TRAFFIC/g;

        $debug_output .= "TP: $tp_line->{id} TI: $ti->[0] TT: $tt->{id}\n";
        $debug_output .= "  Expr: $expression\n" if ($debug > 3);
        $traffic_class = $tt->{id};

        $expr_hash{$traffic_class} = $expression;

        #last;

        if (!defined($expr_hash{$traffic_class})) {
          next;
        }

        #Get users for bonus payments
        #Ipn users for daily payments
        my $ulist = $Internet->user_list(
          {
            LOGIN        => '_SHOW',
            INTERNET_ACTIVATE  => "<=$ADMIN_REPORT{DATE}",
            INTERNET_EXPIRE    => "0000-00-00,>$ADMIN_REPORT{DATE}",
            INTERNET_STATUS    => 0,
            LOGIN_STATUS => 0,
            TP_ID        => $tp_line->{tp_id},
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
            GROUP_BY     => 'internet.id',
            %USERS_LIST_PARAMS
          }
        );

        foreach my $u (@$ulist) {
          my %user = (
            LOGIN      => $u->{login},
            UID        => $u->{uid},
            BILL_ID    => ($tp_line->{ext_bill_account} > 0) ? $u->{bill_id} : $u->{ext_bill_id},
            REDUCTION  => $u->{reduction},
            ACTIVATE   => $u->{internet_activate},
            DEPOSIT    => $u->{deposit},
            CREDIT     => ($u->{credit} > 0) ? $u->{credit} : $tp_line->{credit},
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

          if ($sum > 0 && $debug < 8) {
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
=head2 internet_holdup_fees($attr) - holdup fees

=cut
#**********************************************************
sub internet_holdup_fees {
  my ($attr) = @_;

  my $debug = $attr->{DEBUG} || 0;
  my $debug_output = '';
  $debug_output .= "Internet: Holdup abon\n" if ($debug > 1);
  #@deprecated
  if (! $conf{INTERNET_USER_SERVICE_HOLDUP} && $conf{HOLDUP_ALL}) {
    $conf{INTERNET_USER_SERVICE_HOLDUP} = $conf{HOLDUP_ALL};
  }

  return $debug_output if (!$conf{INTERNET_USER_SERVICE_HOLDUP});
  my $holdup_fees = (split(/:/, $conf{INTERNET_USER_SERVICE_HOLDUP}))[3];
  return $debug_output if (!$holdup_fees || $holdup_fees == 0);

  my %USERS_LIST_PARAMS = ();
  $USERS_LIST_PARAMS{LOGIN}    = $attr->{LOGIN} if ($attr->{LOGIN});
  $USERS_LIST_PARAMS{EXT_BILL} = 1              if ($conf{BONUS_EXT_FUNCTIONS});
  $USERS_LIST_PARAMS{TP_ID}    = $attr->{TP_ID} if ($attr->{TP_ID});

  if ($debug > 6) {
    $Internet->{debug} = 1;
  }

  my $internet_list = $Internet->user_list({
    INTERNET_ACTIVATE => "<=$ADMIN_REPORT{DATE}",
    INTERNET_EXPIRE   => "0000-00-00,>$ADMIN_REPORT{DATE}",
    INTERNET_STATUS   => "0;3",
    LOGIN_STATUS      => "0;3",
    SORT              => 1,
    PAGE_ROWS         => 1000000,
    TP_CREDIT         => '_SHOW',
    LOGIN             => '_SHOW',
    BILL_ID           => '_SHOW',
    REDUCTION         => '_SHOW',
    DEPOSIT           => '_SHOW',
    CREDIT            => '_SHOW',
    COMPANY_ID        => '_SHOW',
    EXT_DEPOSIT       => '_SHOW',
    COLS_NAME         => 1,
    GROUP_BY          => 'internet.id',
    %USERS_LIST_PARAMS
  });

  my $ext_deposit_op = 0;

  foreach my $u (@$internet_list) {
    my %user = (
      LOGIN           => $u->{login},
      UID             => $u->{uid},
      BILL_ID         => ($ext_deposit_op > 0) ? $u->{ext_bill_id} : $u->{bill_id},
      MAIN_BILL_ID    => ($ext_deposit_op > 0) ? $u->{bill_id} : 0,
      REDUCTION       => $u->{reduction},
      ACTIVATE        => $u->{internet_activate},
      DEPOSIT         => $u->{deposit},
      CREDIT          => ($u->{credit} > 0) ? $u->{credit} : 0,
      COMPANY_ID      => $u->{company_id},
      INTERNET_STATUS => $u->{internet_status} || 0,
      EXT_DEPOSIT     => ($u->{ext_deposit}) ? $u->{ext_deposit} : 0,
      LOGIN_STATUS    => $u->{login_status} || 0
    );

    if(! $user{INTERNET_STATUS} && ! $user{LOGIN_STATUS}) {
      next;
    }

    $debug_output .= " Login: $user{LOGIN} ($user{UID}) TP_ID: ($u->{tp_id} Fees: $holdup_fees"
      . " REDUCTION: $user{REDUCTION} DEPOSIT: ". ($u->{deposit} || 'n/d') ." CREDIT $user{CREDIT}"
      . " ACTIVE: $user{ACTIVATE} TP: ". ($u->{tp_num} || q{-}) ."\n" if ($debug > 3);

    if (($user{BILL_ID} && $user{BILL_ID} > 0) && defined($user{DEPOSIT})) {
      if ($debug > 4) {
        $debug_output .= " UID: $user{UID} SUM: $holdup_fees REDUCTION: $user{REDUCTION}\n";
      }

      if( $debug < 8) {
        my %FEES_PARAMS = (
          DATE     => $ADMIN_REPORT{DATE},
          METHOD   => 1,
          DESCRIBE => $lang{HOLD_UP}
        );

        $Fees->take(\%user, $holdup_fees, {%FEES_PARAMS});

        if ($debug > 0) {
          $debug_output .= " $user{LOGIN}  UID: $user{UID} SUM: $holdup_fees REDUCTION: $user{REDUCTION}\n";
        }
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
=head2 internet_monthly_next_tp($attr) Change tp in next period

=cut
#**********************************************************
sub internet_monthly_next_tp {
  my ($attr) = @_;

  my $debug         = $attr->{DEBUG} || 0;
  my $debug_output = '';
  $debug_output  = "Internet: Next tp\n" if ($debug > 1);
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
    MODULE          => 'Dv;Internet',
    COLS_NAME       => 1
  });

  my ($y, $m, $d)   = split(/-/, $ADMIN_REPORT{DATE}, 3);
  my $date_unixtime = POSIX::mktime(0, 0, 0, $d, ($m - 1), $y - 1900, 0, 0, 0);
  my $START_PERIOD_DAY = ($conf{START_PERIOD_DAY}) ? $conf{START_PERIOD_DAY} : 1;
  my %CHANGED_TPS = ();

  my %tp_ages = ();
  foreach my $tp_info (@$tp_list) {
    $tp_ages{$tp_info->{tp_id}}=$tp_info->{age};
  }

  foreach my $tp_info (@$tp_list) {
    $Internet->{debug} = 1 if ($debug > 6);
    my $internet_list = $Internet->user_list({
      INTERNET_ACTIVATE  => "<=$ADMIN_REPORT{DATE}",
      INTERNET_EXPIRE    => "0000-00-00,>$ADMIN_REPORT{DATE}",
      INTERNET_STATUS    => "0;5",
      LOGIN_STATUS       => 0,
      TP_ID              => $tp_info->{tp_id},
      SORT               => 1,
      PAGE_ROWS          => 1000000,
      DELETED            => 0,
      LOGIN              => '_SHOW',
      REDUCTION          => '_SHOW',
      DEPOSIT            => '_SHOW',
      CREDIT             => '_SHOW',
      COMPANY_ID         => '_SHOW',
      INTERNET_EXPIRE    => '_SHOW',
      BILL_ID            => '_SHOW',
      COLS_NAME          => 1,
      GROUP_BY           => 'internet.id',
      %USERS_LIST_PARAMS
    });

    foreach my $u (@$internet_list) {
      my %user = (
        ID         => $u->{id},
        LOGIN      => $u->{login},
        UID        => $u->{uid},
        BILL_ID    => $u->{bill_id},
        REDUCTION  => $u->{reduction},
        ACTIVATE   => $u->{internet_activate},
        EXPIRE     => $u->{internet_expire},
        DEPOSIT    => $u->{deposit},
        CREDIT     => ($u->{credit} > 0) ? $u->{credit} :  $tp_info->{credit},
        COMPANY_ID => $u->{company_id},
        INTERNET_STATUS => $u->{internet_status},
        INTERNET_EXPIRE => $u->{internet_expire},
        EXT_DEPOSIT=> ($u->{ext_deposit}) ? $u->{ext_deposit} : 0,
      );

      my $expire = undef;
      if (!$CHANGED_TPS{ $user{UID} }
        && ((!$tp_info->{age} && ($d == $START_PERIOD_DAY) || $user{ACTIVATE} ne '0000-00-00')
        || ($tp_info->{age} && $user{EXPIRE} eq $ADMIN_REPORT{DATE}) )) {

        if($user{EXPIRE} ne '0000-00-00') {
          if($user{EXPIRE} eq $ADMIN_REPORT{DATE}) {
            # if (!$tp_ages{$tp_info->{tp_id}}) {
            #   $expire = '0000-00-00';
            # }
            # els
            if(!$tp_ages{$tp_info->{next_tp_id}}) {
              $expire = '0000-00-00';
            }
            else {
              my $next_age = $tp_ages{$tp_info->{next_tp_id}};
              $expire = POSIX::strftime("%Y-%m-%d",
                localtime(POSIX::mktime(0, 0, 0, $d, ($m-1), ($y - 1900), 0, 0, 0) + $next_age * 86400));
              #print " // $expire //\n ";
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

        $debug_output .= " Login: $user{LOGIN} ($user{UID}) ACTIVATE $user{ACTIVATE} TP_ID: $tp_info->{tp_id} -> $tp_info->{next_tp_id}\n";
        $CHANGED_TPS{ $user{UID} } = 1;

        my $status = 0;
        if($conf{INTERNET_CUSTOM_PERIOD} && $u->{deposit} < $tp_info->{change_price}) {
          $status = 5;
          $expire = $ADMIN_REPORT{DATE};
        }

        if($debug < 8) {
          $Internet->user_change({
            ID             => $user{ID},
            UID            => $user{UID},
            STATUS         => $status,
            TP_ID          => $tp_info->{next_tp_id},
            SERVICE_EXPIRE => $expire
          });
        }
        if($tp_info->{change_price}
          && $tp_info->{change_price} > 0
          && $tp_info->{next_tp_id} == $tp_info->{tp_id}
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
=head2 internet_monthly_fees($attr) - Monthly fees

  Arguments:
    $attr

=cut
#**********************************************************
sub internet_monthly_fees {
  my ($attr) = @_;

  my $debug = $attr->{DEBUG} || 0;
  my $debug_output = '';

  if($attr->{LOGON_ACTIVE_USERS} || $attr->{SRESTART}) {
    return $debug_output;
  }

  my $fees_priority = $conf{FEES_PRIORITY} || q{};

  $debug_output .= "Internet: Monthly periodic payments\n" if ($debug > 1);

  $ADMIN_REPORT{DATE} = $DATE if (!$ADMIN_REPORT{DATE});

  $LIST_PARAMS{TP_ID} = $attr->{TP_ID} if ($attr->{TP_ID});

  my %USERS_LIST_PARAMS = ();
  $USERS_LIST_PARAMS{LOGIN} = $attr->{LOGIN} if ($attr->{LOGIN});
  $USERS_LIST_PARAMS{UID} = $attr->{UID} if ($attr->{UID});
  $USERS_LIST_PARAMS{EXT_BILL} = 1 if ($conf{BONUS_EXT_FUNCTIONS});
  $USERS_LIST_PARAMS{REGISTRATION} = "<$ADMIN_REPORT{DATE}";
  $USERS_LIST_PARAMS{GID}   = $attr->{GID} if ($attr->{GID});
  $USERS_LIST_PARAMS{INTERNET_STATUS} = $attr->{INTERNET_STATUS} if ($attr->{INTERNET_STATUS});
  $USERS_LIST_PARAMS{COMPANY_ID} = $attr->{COMPANY_ID} if ($attr->{COMPANY_ID});

  my $START_PERIOD_DAY = ($conf{START_PERIOD_DAY}) ? $conf{START_PERIOD_DAY} : 1;

  #Change TP to next TP
  $debug_output .= internet_monthly_next_tp($attr);
  $DEBUG .= $debug_output;

  my %FEES_METHODS = %{ get_fees_types({ SHORT => 1 }) };

  $users = Users->new($db, $admin, \%conf);
  $Tariffs->{debug} = 1 if ($debug > 6);
  my $list = $Tariffs->list({
    %LIST_PARAMS,
    MODULE          => 'Internet',
    EXT_BILL_ACCOUNT=> '_SHOW',
    EXT_BILL_FEES_METHOD=> '_SHOW',
    DOMAIN_ID       => '_SHOW',
    FIXED_FEES_DAY  => '_SHOW',
    ACTIVE_MONTH_FEE=> '_SHOW',
    COLS_NAME       => 1,
    COLS_UPPER      => 1
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
    my $postpaid            = $TP_INFO->{POSTPAID_MONTHLY_FEE} || $TP_INFO->{PAYMENT_TYPE} || 0;
    $USERS_LIST_PARAMS{DOMAIN_ID} = $TP_INFO->{DOMAIN_ID};
    my %used_traffic = ();

    #Monthfee & min use
    if ($month_fee > 0 || $TP_INFO->{MIN_USE} > 0) {
      $debug_output .= "TP ID: $TP_INFO->{ID} MF: $TP_INFO->{MONTH_FEE} POSTPAID: $postpaid "
        . "REDUCTION: $TP_INFO->{REDUCTION_FEE} EXT_BILL_ID: $TP_INFO->{EXT_BILL_ACCOUNT} CREDIT: $TP_INFO->{CREDIT} "
        . "MIN_USE: $TP_INFO->{MIN_USE} ABON_DISTR: $TP_INFO->{ABON_DISTRIBUTION}\n" if ($debug > 1);

      #get used  traffic for min use functions
      my %processed_users = ();
      if ($TP_INFO->{MIN_USE} > 0 && $START_PERIOD_DAY && $conf{INTERNET_MIN_USER_FULLPERIOD}) {
        my $interval = "$pre_month_begin/$pre_month_end";
        if ($conf{INTERNET_MIN_USER_FULLPERIOD}) {
          $activate_date = POSIX::strftime("%Y-%m-%d", localtime($date_unixtime - 86400 * 30));
          $interval      = "$activate_date/$ADMIN_REPORT{DATE}";
          $activate_date = "=$activate_date";
        }

        my $report_list = $Sessions->reports({
          INTERVAL => $interval,
          TP_ID    => $TP_INFO->{TP_ID},
          COLS_NAME=> 1
        });

        foreach my $l (@$report_list) {
          $used_traffic{ $l->{uid} } = $l->{sum};
        }
      }

      if ($TP_INFO->{ABON_DISTRIBUTION}) {
        $month_fee = $month_fee / $days_in_month;
      }

      if($TP_INFO->{EXT_BILL_ACCOUNT}) {
        $USERS_LIST_PARAMS{EXT_BILL_ID} = '_SHOW';
        $USERS_LIST_PARAMS{EXT_BILL_DEPOSIT} = '_SHOW';
      }

      $Internet->{debug} = 1 if ($debug > 5);
      my $ulist = $Internet->user_list({
        INTERNET_ACTIVATE => "$activate_date",
        INTERNET_EXPIRE   => "0000-00-00,>$ADMIN_REPORT{DATE}",
        INTERNET_STATUS   => "0;5",
        JOIN_SERVICE => "<2",
        LOGIN_STATUS => 0,
        TP_ID        => $TP_INFO->{TP_ID},
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
        EXT_DEPOSIT  => '_SHOW',
        COLS_NAME    => 1,
        GROUP_BY     => 'internet.id',
        %USERS_LIST_PARAMS
      });

      foreach my $u (@$ulist) {
        my $EXT_INFO       = '';
        my $ext_deposit_op = $TP_INFO->{EXT_BILL_ACCOUNT};
        my %user           = (
          LOGIN        => $u->{login},
          UID          => $u->{uid},
          ID           => $u->{id},
          BILL_ID      => ($ext_deposit_op) ? $u->{ext_bill_id} : $u->{bill_id},
          MAIN_BILL_ID => ($ext_deposit_op) ? $u->{bill_id} : 0,
          REDUCTION    => $u->{reduction},
          ACTIVATE     => $u->{internet_activate},
          DEPOSIT      => $u->{deposit} || 0,
          CREDIT       => ($u->{credit} > 0) ? $u->{credit} : $TP_INFO->{CREDIT},
          COMPANY_ID   => $u->{company_id},
          INTERNET_STATUS => $u->{internet_status},
          EXT_DEPOSIT  => ($u->{ext_deposit}) ? $u->{ext_deposit} : 0,
          EXT_BILL_ID  => $u->{ext_bill_id}
        );

        #Active month fee
        if ($TP_INFO->{ACTIVE_MONTH_FEE}) {
          $Sessions->{debug} = 1 if ($debug > 6);
          $Sessions->reports({
            INTERVAL    => "$pre_month_begin/$pre_month_end",
            TRAFFIC_SUM => '_SHOW',
            UID         => $u->{uid},
            COLS_NAME   => 1
          });

          if (!$Sessions->{TOTAL}) {
            next;
          }
          elsif ($conf{INTERNET_ACTIVE_MONTH_TRAFFIC}) {
            if ($conf{INTERNET_ACTIVE_MONTH_TRAFFIC} > $Sessions->{list}->[0]->{TRAFFIC_SUM}) {
              next;
            }
          }
        }

        my %FEES_DSC = (
          MODULE            => 'Internet',
          TP_ID             => $TP_INFO->{TP_ID},
          TP_NAME           => $TP_INFO->{NAME},
          FEES_PERIOD_MONTH => $lang{MONTH_FEE_SHORT},
          FEES_METHOD       => $FEES_METHODS{$TP_INFO->{FEES_METHOD}},
          ID                => ($user{ID}) ? ' '. $user{ID} : undef,
        );

        if ($debug > 3) {
          $debug_output .= " Login: $user{LOGIN} ($user{UID}) TP_ID: $u->{tp_id} Fees: $TP_INFO->{MONTH_FEE}"
            . "REDUCTION: $user{REDUCTION} DEPOSIT: $user{DEPOSIT} CREDIT $user{CREDIT} ACTIVE: $user{ACTIVATE} TP: $u->{tp_id}\n";
        }

        if ($fees_priority =~ /bonus/ && $TP_INFO->{SMALL_DEPOSIT_ACTION} && $user{EXT_DEPOSIT}) {
          $user{DEPOSIT} += $user{EXT_DEPOSIT};
        }

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
          DATE            => $ADMIN_REPORT{DATE},
          METHOD          => ($TP_INFO->{FEES_METHOD}) ? $TP_INFO->{FEES_METHOD} : 1,
          EXT_BILL_METHOD => ($TP_INFO->{EXT_BILL_FEES_METHOD}) ? $TP_INFO->{EXT_BILL_FEES_METHOD} : undef,
        );
        my $sum = 0;

        #***************************************************************
        #Min use Makes only 1 of month
        if ($TP_INFO->{MIN_USE} > 0 && $d == $START_PERIOD_DAY && !$conf{INTERNET_MIN_USER_FULLPERIOD}) {
          #Check activation date
          my $min_use = $TP_INFO->{MIN_USE};

          if ($user{REDUCTION} > 0) {
            $min_use = $min_use * (100 - $user{REDUCTION}) / 100;
          }

          #Min use Alignment
          if (!$conf{INTERNET_MIN_USER_FULLPERIOD} && $user{ACTIVATE} ne '0000-00-00') {
            $days_in_month = days_in_month({ DATE => $user{ACTIVATE} });
            my (undef, $activated_d)=split(/-/, $user{ACTIVATE});
            $min_use = sprintf("%.5f", $min_use / $days_in_month * ($days_in_month - $activated_d + $START_PERIOD_DAY));
          }

          my $used = ($used_traffic{ $user{UID} }) ? $used_traffic{ $user{UID} } : 0;
          $FEES_PARAMS{DESCRIBE} = $lang{MIN_USE};

          #summary for all company users with same tarif plan
          if ($user{COMPANY_ID} > 0 && $processed_users{ $user{COMPANY_ID} }) {
            next;
          }

          if ($user{COMPANY_ID} > 0) {
            my $company_users = $Internet->user_list({
              TP_ID      => $TP_INFO->{TP_ID},
              LOGIN      => '_SHOW',
              COMPANY_ID => $user{COMPANY_ID},
              COLS_NAME  => 1
            });

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
          #if ($conf{MIN_USE_FEES_CONSIDE}) {
            $Fees->list({
              UID     => $user{UID},
              DATE    => ($user{ACTIVATE} ne '0000-00-00') ? ">=$user{ACTIVATE}" : $DATE,
              METHODS => $conf{MIN_USE_FEES_CONSIDE},
            });
            $used += $Fees->{SUM} if ($Fees->{SUM});
          #}

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

          if ($postpaid == 1 || $user{DEPOSIT} + $user{CREDIT} > 0) {
            if ($d == $START_PERIOD_DAY) {
              if ($debug > 4) {
                $debug_output .= " UID: $user{UID} SUM: $sum REDUCTION: $user{REDUCTION}\n";
              }

              if ($debug < 8) {
                if($sum > 0) {
                  $Fees->take(\%user, $sum, {
                    %FEES_PARAMS,
                    DATE   => $pre_month_end,
                    METHOD => $conf{MIN_USE_FEES_CONSIDE} || 1,
                    USER   => $users
                  });
                }

                $debug_output .= " $user{LOGIN} UID: $user{UID} SUM: $sum REDUCTION: $user{REDUCTION}\n" if ($debug > 0);
                if ($user{ACTIVATE} ne '0000-00-00') {
                  $Internet->user_change({
                    ID       => $user{ID},
                    UID      => $user{UID},
                    ACTIVATE => '0000-00-00'
                  });
                }
              }
            }
          }
        }

        #***************************************************************
        #Month Fee
        if ($month_fee > 0) {
          #Make sum
          if ($u->{personal_tp} > 0) {
            if($TP_INFO->{ABON_DISTRIBUTION}) {
              $sum = $u->{personal_tp} / $days_in_month;
            }
            else {
              $sum = $u->{personal_tp};
            }
          }
          else {
            $sum =  $month_fee;
          }

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
                $debug_output .= internet_service_deactivate({
                  TP_INFO   => $TP_INFO,
                  USER_INFO => \%user,
                  DEBUG     => $debug
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

                  if($ext_deposit_sum > 0) {
                    $Fees->take(\%user, $ext_deposit_sum, { %FEES_PARAMS });
                  }
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
          if ($conf{INTERNET_PREPAID_PERIOD_CREDIT}
            && ($user{ACTIVATE} eq '0000-00-00' and $d == $START_PERIOD_DAY)
            && $user{CREDIT} == 0
            && ($user{DEPOSIT} < $sum && $user{DEPOSIT} > 0)) {
            my $credit_period = int($user{DEPOSIT} /  ($sum / $days_in_month));
            if ($credit_period > 0) {
              $users->change($user{UID}, {
                ID          => $user{ID},
                UID         => $user{UID},
                CREDIT_DATE => sprintf("%04d-%02d-%02d", (($m < 12) ? $y : $y+1), (($m < 12) ? $m+1 : 1),  $credit_period),
                CREDIT      => $sum
              });
              $user{CREDIT}  = $sum;
            }
            $debug_output .= " $user{LOGIN} UID: $user{UID} SUM: $sum change credit\n";
          }


          #If deposit is above-zero or TARIF PALIN is POST PAID or PERIODIC PAYMENTS is POSTPAID
          if ($postpaid || $user{DEPOSIT} + $user{CREDIT} > 0) {
            #*******************************************
            #Unblock Small deposit status
            if ($TP_INFO->{SMALL_DEPOSIT_ACTION} && $sum < $user{DEPOSIT} + $user{CREDIT}) {
              if ($user{INTERNET_STATUS}
                && $TP_INFO->{ABON_DISTRIBUTION}
                && $conf{INTERNET_FULL_MONTH}
                && $sum * $days_in_month > $user{DEPOSIT}) {
                next;
              }

              if ($debug < 8) {
                internet_service_activate({
                  TP_INFO   => $TP_INFO,
                  USER_INFO => \%user,
                  DEBUG     => $debug
                });
                $user{INTERNET_STATUS} = 0;
              }
            }

            #take fees in first day of month
            $FEES_PARAMS{DESCRIBE} = fees_dsc_former(\%FEES_DSC);
            $FEES_PARAMS{DESCRIBE} .= " - $lang{ABON_DISTRIBUTION}" if ($TP_INFO->{ABON_DISTRIBUTION});

            if ($user{INTERNET_STATUS} == 5 && $TP_INFO->{FINE} > 0) {
              if ($conf{INTERNET_FINE_LIMIT} && $user{DEPOSIT} + $user{CREDIT} < $conf{INTERNET_FINE_LIMIT}) {
                next;
              }
              $FEES_PARAMS{DESCRIBE} = $lang{FINE};
              $FEES_PARAMS{METHOD}   = 2;
              $sum                   = $TP_INFO->{FINE};
              $EXT_INFO              = "FINE";
            }
            # If activation set to monthly fees taken throught 30 days
            elsif ($user{ACTIVATE} ne '0000-00-00') {
              #Block small deposit
              if ($TP_INFO->{SMALL_DEPOSIT_ACTION} && $sum > $user{DEPOSIT} + $user{CREDIT}
                && (($TP_INFO->{FIXED_FEES_DAY} && ($d == $activate_d || ($d == $START_PERIOD_DAY && $activate_d > 28)))
                || ($date_unixtime - $active_unixtime > 30 * 86400) || $TP_INFO->{ABON_DISTRIBUTION} )
              ) {
                $debug_output .= internet_service_deactivate({
                  TP_INFO   => $TP_INFO,
                  USER_INFO => \%user,
                  DEBUG     => $debug
                });

                next;
              }
              #Static day
              if( (($TP_INFO->{FIXED_FEES_DAY} && $m == $activate_m ) && ($d == $activate_d || ($d == $START_PERIOD_DAY && $activate_d > 28)))
                || ($date_unixtime - $active_unixtime > 30 * 86400) ) {

                if ($debug > 4) {
                  $debug_output .= " $user{LOGIN} UID: $user{UID} SUM: $sum REDUCTION: $user{REDUCTION}\n";
                }

                if ($debug < 8) {
                  $FEES_PARAMS{DESCRIBE} .= " ($ADMIN_REPORT{DATE}-" . (POSIX::strftime("%Y-%m-%d", localtime($date_unixtime + 86400 * 30))) . ')' if (!$TP_INFO->{ABON_DISTRIBUTION});

                  if( $sum > 0 ) {
                    $Fees->take(\%user, $sum, \%FEES_PARAMS);
                  }
                  $debug_output .= " $user{LOGIN} UID: $user{UID} SUM: $sum REDUCTION: $user{REDUCTION} CHANGE ACTIVATE\n" if ($debug > 0);
                  if ($Fees->{errno}) {
                    print "Internet Error: [ $user{UID} ] $user{LOGIN} SUM: $sum [$Fees->{errno}] $Fees->{errstr} ";
                    if ($Fees->{errno} == 14) {
                      print "UID: $user{UID} LOGIN: $user{LOGIN} - Don't have money account";
                    }
                    print "\n";
                  }
                  else {
                    $Internet->user_change({
                      UID      => $user{UID},
                      ACTIVATE => $ADMIN_REPORT{DATE}
                    });
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
                $debug_output .= internet_service_deactivate({
                  TP_INFO   => $TP_INFO,
                  USER_INFO => \%user,
                  DEBUG     => $debug
                });
                next;
              }
              #Skip fees for small deposit actions
              elsif ($user{INTERNET_STATUS} == 5) {
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

            if ($debug < 8) {
              $FEES_PARAMS{DESCRIBE} .= " ($cure_month_begin-$cure_month_end)" if (!$TP_INFO->{ABON_DISTRIBUTION});
              if($sum > 0) {
                $Fees->take(\%user, $sum, { %FEES_PARAMS });
              }
              $debug_output .= " $user{LOGIN}  UID: $user{UID} SUM: $sum REDUCTION: $user{REDUCTION} $EXT_INFO\n" if ($debug > 0);
            }
          }
          else {
            # Get Fine
            if ($TP_INFO->{FINE} > 0) {
              if ($conf{INTERNET_FINE_LIMIT} && $user{DEPOSIT} + $user{CREDIT} < $conf{INTERNET_FINE_LIMIT}) {
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
            if (! $user{INTERNET_STATUS}
              && (($user{ACTIVATE} ne '0000-00-00' && $date_unixtime - $active_unixtime > 30 * 86400)
                ||
                ($user{ACTIVATE} eq '0000-00-00' && ($d == $START_PERIOD_DAY || $TP_INFO->{ABON_DISTRIBUTION}))
              )
            ) {
              $debug_output .= internet_service_deactivate({
                TP_INFO   => $TP_INFO,
                USER_INFO => \%user,
                DEBUG     => $debug
              });
            }
          }
        }
      }
    }
  }

  #Make traffic recalculation for expration
  if ($d == 1) {
    $list = $Tariffs->list({
      %LIST_PARAMS,
      MODULE    => 'Internet',
      COLS_NAME => 1
    });

    $debug_output .= "Total month price\n";
    require Billing;
    Billing->import();
    my $Billing = Billing->new($db, \%conf);

    foreach my $tp_line (@$list) {
      my $ti_list = $Tariffs->ti_list({ TP_ID => $tp_line->{tp_id} });
      next if ($Tariffs->{TOTAL} != 1);

      foreach my $ti (@$ti_list) {

        my $tt_list = $Tariffs->tt_list({ TI_ID => $ti->[0], COLS_NAME => 1 });
        next if ($Tariffs->{TOTAL} != 1);

        my %expr_hash = ();
        foreach my $tt (@$tt_list) {
          my $expression = $tt->{expression};
          next if ($expression !~ /MONTH_TRAFFIC_/);

          $expression =~ s/MONTH_TRAFFIC/TRAFFIC/g;

          $debug_output .= "TP: $tp_line->{id} TI: $ti->[0] TT: $tt->{id}\n";
          $debug_output .= "  Expr: $expression\n" if ($debug > 3);

          $expr_hash{ $tt->{id} } = $expression;
        }

        next if (!defined($expr_hash{0}));

        my $ulist = $Internet->user_list(
          {
            ACTIVATE     => "<=$ADMIN_REPORT{DATE}",
            EXPIRE       => "0000-00-00,>$ADMIN_REPORT{DATE}",
            INTERNET_EXPIRE    => "0000-00-00,>$ADMIN_REPORT{DATE}",
            INTERNET_STATUS    => 0,
            LOGIN_STATUS => 0,
            TP_ID        => $tp_line->{tp_id},
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
            GROUP_BY     => 'internet.id',
            %USERS_LIST_PARAMS
          }
        );

        foreach my $u (@$ulist) {
          my %user = (
            LOGIN      => $u->{login},
            UID        => $u->{uid},
            BILL_ID    => ($tp_line->{ext_bill_account} > 0) ? $u->{ext_bill_id} : $u->{bill_id},
            REDUCTION  => $u->{reduction},
            ACTIVATE   => $u->{activate},
            DEPOSIT    => $u->{deposit},
            CREDIT     => ($u->{credit} > 0) ? $u->{credit} : $tp_line->{credit},
            COMPANY_ID => $u->{company_id}
          );

          $debug_output .= " Login: $u->{login} ($u->{uid}) TP_ID: $u->{tp_id} Fees: - REDUCTION: $u->{reduction} $u->{deposit} $u->{credit} - $user{ACTIVATE}\n" if ($debug > 3);

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

          if($sum > 0) {
            $Fees->take(\%user, $sum, { %FEES_PARAMS });
          }
        }

      }
    }
  }

  $DEBUG .= $debug_output;
  return $debug_output;
}

#**********************************************************
=head2 internet_users_warning_messages($attr)

=cut
#**********************************************************
sub internet_users_warning_messages {
  my ($attr) = @_;

  $ADMIN_REPORT{USERS_WARNINGS} = sprintf("%-14s| %4s|%-20s| %9s| %8s|\n", $lang{LOGIN}, 'TP', $lang{TARIF_PLAN}, $lang{DEPOSIT}, $lang{CREDIT}) . "---------------------------------------------------------------\n";
  if ($ADMIN_REPORT{NO_USERS_WARNINGS}) {
    return 0;
  }

  my $debug = $attr->{DEBUG} //= 0;
  my $debug_output = '';
  $debug_output .= "Internet: Daily warning messages\n" if ($debug > 1);

  #Get next abon day
  require Internet::Service_mng;
  my $Service_mng = Internet::Service_mng->new({
    lang  => \%lang,
    admin => $admin,
    conf  => \%conf,
    db    => $db,
    html  => $html
  });

  use Internet::Negative_deposit;

  my %LIST_PARAMS = (USERS_WARNINGS => 1);
  my @allert_redirect_days = ();

  if ($conf{INTERNET_ALERT_REDIRECT_DAYS}) {
    $LIST_PARAMS{ALERT_PERIOD} = $conf{INTERNET_ALERT_REDIRECT_DAYS};
    @allert_redirect_days = split(/,\s?/, $conf{INTERNET_ALERT_REDIRECT_DAYS} || '');
  }

  $LIST_PARAMS{LOGIN} = $attr->{LOGIN} if ($attr->{LOGIN});
  $Internet->{debug}=1 if($debug > 5);
  my $internet_list = $Internet->user_list({
    %LIST_PARAMS,
    LOGIN             => '_SHOW',
    FIO               => '_SHOW',
    TP_ID             => '_SHOW',
    TP_NAME           => '_SHOW',
    DEPOSIT           => '_SHOW',
    CREDIT            => '_SHOW',
    EMAIL             => '_SHOW',
    PHONE             => '_SHOW',
    CREDIT            => '_SHOW',
    TP_CREDIT         => '_SHOW',
    MONTH_FEE         => '_SHOW',
    DAY_FEE           => '_SHOW',
    ABON_DISTRIBUTION => '_SHOW',
    _SKIP_NEG_WARN    => '_SHOW',
    ONLINE_IP         => '_SHOW',
    INTERNET_STATUS   => 0,
    LOGIN_STATUS      => 0,
    COLS_NAME         => 1,
    COLS_UPPER        => 1
  });

  if ($Internet->{TOTAL} < 1) {
    $DEBUG .= $debug_output;
    return $debug_output;
  }

  foreach my $u (@$internet_list) {
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

    if($u->{DEPOSIT}) {
      $u->{DEPOSIT} = format_sum($u->{DEPOSIT});
    }

    if($conf{INTERNET_ALERT_REDIRECT_FILTER} && in_array($u->{to_next_period}, \@allert_redirect_days)) {
      $debug_output .= "  $u->{LOGIN} Redirect\n";
      $type='redirect';
      $Internet->user_change({
        UID       => $u->{UID},
        FILTER_ID => $conf{INTERNET_ALERT_REDIRECT_FILTER}
      });

      if($u->{client_ip}) {
        mk_redirect({ IP => $u->{client_ip} });
      }
    }

    $Internet->user_info($u->{client_ip} , { ID => $u->{id}});
    $Service_mng->get_next_abon_date({
      SERVICE => $Internet
    });

    $u->{ABON_DATE} = $Service_mng->{ABON_DATE};

    if(in_array('Sms', \@MODULES) && $conf{INTERNET_USER_WARNING_SMS} && $u->{PHONE}){
      load_module('Sms', $html);

      my $message   = $html->tpl_show(_include('internet_users_warning_messages_sms', 'Internet'),
        { %$u,
          DATE       => $DATE,
          TIME       => $TIME,
          MONEY_UNIT => ($conf{MONEY_UNIT_NAMES}) ? (split(/;/, $conf{MONEY_UNIT_NAMES}))[0] : q{}
        },
        { OUTPUT2RETURN => 1 });

      my $sms_id    = sms_send(
        {
          NUMBER => $u->{PHONE},
          MESSAGE=> $message,
          UID    => $u->{UID},
          QUITE  => 1,
        });

      if ( $sms_id ) {
        $debug_output .= "\nAlert sms sent for user $u->{LOGIN}\n" if $debug > 5;
      }
      else{
        $debug_output .= "\nAlert sms not sent for user $u->{LOGIN}\n" if $debug > 5;
      }
    }

    if ($email eq '') { next; }

    my $info = sprintf("%-14s| %4d|%-20s| %-14s| %8.2f| %6s|\n", $u->{login},
      $u->{tp_num},
      $u->{tp_name},
      format_sum($u->{deposit}),
      $u->{credit},
      $type
    );

    $ADMIN_REPORT{USERS_WARNINGS} .= $info;
    $debug_output .= $info if ($debug > 3);

    if ($debug < 5) {

      my $message = $html->tpl_show(_include('internet_users_warning_messages', 'Internet'),
        { %$u,
          DATE => $DATE,
          TIME => $TIME,
          MONEY_UNIT => ($conf{MONEY_UNIT_NAMES}) ? (split(/;/, $conf{MONEY_UNIT_NAMES}))[0] : q{}
        },
        { OUTPUT2RETURN => 1 });

      sendmail($conf{ADMIN_MAIL}, $email, $lang{BILL_INFO}, $message,
        "$conf{MAIL_CHARSET}", "2 (High)", { TEST => (($debug>6)?1:0) });
    }
  }

  $ADMIN_REPORT{USERS_WARNINGS} .= "---------------------------------------------------------------
$lang{TOTAL}: $Internet->{TOTAL}\n";

  if ($debug > 5) {
    $debug_output .= $ADMIN_REPORT{USERS_WARNINGS};
  }

  $DEBUG .= $debug_output;
  return $debug_output;
}

#***********************************************************
=head2 internet_sheduler($type, $action, $uid, $attr)

  Arguments:
    $type
    $action
    $uid
    $attr

  Returns:
    TRUE or FALSE

=cut
#***********************************************************
sub internet_sheduler {
  my ($type, $action, $uid, $attr) = @_;

  my $debug = $attr->{DEBUG} || 0;
  $action //= q{};
  my $d  = (split(/-/, $ADMIN_REPORT{DATE}, 3))[2];
  my $START_PERIOD_DAY = $conf{START_PERIOD_DAY} || 1;

  my $user = $users->info($uid);

  if ($type eq 'tp') {
    my $service_id;
    my $tp_id = 0;
    if($action =~ /(\d+):(\d+)/) {
      $service_id = $1;
      $tp_id      = $2;
    }
    else {
      $tp_id = dv2intenet_tp($action);
    }

    my %params = ();
    $Internet->user_info($uid, { ID => $service_id });

    #Change activation date after change TP
    #Date must change after tp fees
    #if ($Internet->{ACTIVATE} && $Internet->{ACTIVATE} ne '0000-00-00' && !$Internet->{STATUS}) {
    #  $params{ACTIVATE} = $ADMIN_REPORT{DATE};
    #}

    $Internet->user_change({
      UID         => $uid,
      TP_ID       => $tp_id,
      ID          => $service_id,
      PERSONAL_TP => 0.00,
      %params
    });

    if ($attr->{GET_ABON} && $attr->{GET_ABON} eq '-1' && $attr->{RECALCULATE} && $attr->{RECALCULATE} eq '-1') {
      print "Skip: GET_ABON, RECALCULATE\n" if ($debug > 1);
      return 0;
    }

    if ($Internet->{errno}) {
      return $Internet->{errno};
    }
    else {
      if ($Internet->{TP_INFO}->{ABON_DISTRIBUTION} || $d == $START_PERIOD_DAY) {
        $Internet->{TP_INFO}->{MONTH_FEE} = 0;
      }

      #$user = undef;
      service_get_month_fee($Internet, {
        QUITE       => 1,
        SHEDULER    => 1,
        DATE        => $attr->{DATE},
        RECALCULATE => 1,
        USER_INFO   => $user
      });
    }
  }
  elsif ($type eq 'status') {
    my $service_id;

    if($action =~ /:/) {
      ($service_id, $action)=split(/:/, $action);
    }

    $Internet->user_change({
      UID        => $uid,
      STATUS     => $action,
      SERVICE_ID => $service_id
    });

    #Get fee for holdup service
    if ($action == 3) {
      my $active_fees = 0;

      #@deprecated
      if (! $conf{INTERNET_USER_SERVICE_HOLDUP} && $conf{HOLDUP_ALL}) {
        $conf{INTERNET_USER_SERVICE_HOLDUP} = $conf{HOLDUP_ALL};
      }

      if ($conf{INTERNET_USER_SERVICE_HOLDUP}) {
        $active_fees =  (split(/:/, $conf{INTERNET_USER_SERVICE_HOLDUP}))[5];
      }

      if ($active_fees && $active_fees > 0) {
        #$user = $users->info($uid);
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

      if ($conf{INTERNET_HOLDUP_COMPENSATE}) {
        $Internet->{TP_INFO_OLD} = $Tariffs->info(0, { TP_ID => $Internet->{TP_ID} });
        if ($Internet->{TP_INFO_OLD}->{PERIOD_ALIGNMENT}) {
          #$Internet->{TP_INFO}->{MONTH_FEE} = 0;
          service_recalculate($Internet,
            { RECALCULATE => 1,
              QUITE       => 1,
              SHEDULER    => 1,
              USER_INFO   => $user,
              DATE        => $ADMIN_REPORT{DATE}
            });
        }
      }

      if ($action) {
        _external('', { EXTERNAL_CMD => 'Internet', %{$Internet} });
      }
    }
    elsif ($action == 0) {
      if ($Internet->{TP_INFO}->{ABON_DISTRIBUTION} || $d == $START_PERIOD_DAY) {
        $Internet->{TP_INFO}->{MONTH_FEE} = 0;
      }

      service_get_month_fee($Internet, {
        QUITE    => 1,
        SHEDULER => 1, #($attr->{SHEDULEE_ONLY}) ? undef,
        DATE     => $attr->{DATE},
        USER_INFO=> $user
      });
    }

    if ($Internet->{errno} && $Internet->{errno} == 15) {
      return $Internet->{errno};
    }
  }

  return 1;
}

#***********************************************************
=head2 internet_report($type, $attr) - Email admin reports

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
sub internet_report {
  my ($type, $attr) = @_;
  my $REPORT = "Module: Internet ($type)\n";

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

#**********************************************************
=head dv2intenet_tp($dv_tp_id)

  Arguments:
    $dv_tp_id

=cut
#**********************************************************
sub dv2intenet_tp {
  my($dv_tp_id) = @_;
  my $tp_id = 0;

  my $tp_list = $Tariffs->list({
    NEW_MODEL_TP => 1,
    TP_ID        => $dv_tp_id,
    MODULE       => 'Dv',
    COLS_NAME    => 1
  });

  if($Tariffs->{TOTAL} > 0) {
    $tp_id = $tp_list->[0]->{tp_id};
  }

  return $tp_id;
}

1;