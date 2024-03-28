=head1

  Tripaly periodic

=cut

use strict;
use warnings;

our(
  $db,
  %conf,
  $admin,
  %ADMIN_REPORT,
  %lang
);

use Triplay;
use Fees;
my $Triplay = Triplay->new($db, $admin, \%conf);
my $Fees     = Fees->new($db, $admin, \%conf);
#my $Tariffs  = Tariffs->new($db, \%conf, $admin);

#**********************************************************
=head2 triplay_daily_fees($attr) - Daily fees

  Arguments:
    $attr

=cut
#**********************************************************
sub triplay_daily_fees {
  my ($attr) = @_;

  my $debug = $attr->{DEBUG} || 0;
  my $debug_output = '';

  return $debug_output if ($attr->{LOGON_ACTIVE_USERS} || $attr->{SRESTART});

  my $fees_priority = $conf{FEES_PRIORITY} || q{};
  $debug_output .= "Triplay: Daily periodic payments\n" if ($debug > 1);

  $ADMIN_REPORT{DATE} = $DATE if (!$ADMIN_REPORT{DATE});
  $LIST_PARAMS{TP_ID} = $attr->{TP_ID} if ($attr->{TP_ID});

  my %USERS_LIST_PARAMS = ();
  $USERS_LIST_PARAMS{LOGIN} = $attr->{LOGIN} if ($attr->{LOGIN});
  $USERS_LIST_PARAMS{UID} = $attr->{UID} if ($attr->{UID});
  $USERS_LIST_PARAMS{REGISTRATION} = "<$ADMIN_REPORT{DATE}";
  $USERS_LIST_PARAMS{GID} = $attr->{GID} if ($attr->{GID});

  my $FEES_METHODS = get_fees_types({ SHORT => 1 });

  $users = Users->new($db, $admin, \%conf);
  $Triplay->{debug} = 1 if ($debug > 5);

  my $tariff_plans = $Triplay->tp_list({
    %LIST_PARAMS,
    NAME         => '_SHOW',
    MODULE       => 'Triplay',
    DOMAIN_ID    => '_SHOW',
    FEES_METHOD  => '_SHOW',
    DAY_FEE      => '>0',
    CREDIT       => '_SHOW',
    MODULES      => 'Triplay',
    PAYMENT_TYPE => '_SHOW',
    COLS_NAME    => 1,
    COLS_UPPER   => 1
  });

  foreach my $tariff (@{$tariff_plans}) {
    next if !$tariff->{DAY_FEE};

    if ($debug > 1) {
      $debug_output .= "TP ID: $tariff->{ID} DF: $tariff->{DAY_FEE}\n";
    }

    $USERS_LIST_PARAMS{DOMAIN_ID} = $tariff->{DOMAIN_ID};

    my $user_list = $Triplay->user_list({
      SERVICE_STATUS => '0',
      LOGIN_STATUS   => 0,
      TP_ID          => $tariff->{TP_ID},
      TP_CREDIT      => '_SHOW',
      DELETED        => 0,
      LOGIN          => '_SHOW',
      BILL_ID        => '_SHOW',
      REDUCTION      => '_SHOW',
      DEPOSIT        => '_SHOW',
      CREDIT         => '_SHOW',
      COMPANY_ID     => '_SHOW',
      PERSONAL_TP    => '_SHOW',
      EXT_DEPOSIT    => '_SHOW',
      PAGE_ROWS      => 1000000,
      SORT           => 1,
      COLS_NAME      => 1,
      %USERS_LIST_PARAMS
    });

    foreach my $u (@$user_list) {
      my %user = (
        LOGIN          => $u->{login},
        UID            => $u->{uid},
        ID             => $u->{id},
        BILL_ID        => $u->{bill_id},
        REDUCTION      => $u->{reduction},
        DEPOSIT        => $u->{deposit},
        SERVICE_STATUS => $u->{service_status},
        CREDIT         => ($u->{credit} > 0) ? $u->{credit} : ($tariff->{CREDIT} || 0),
        COMPANY_ID     => $u->{company_id},
        STATUS         => $u->{service_status},
        TP_ID          => $tariff->{TP_ID}
      );

      my %FEES_DSC = (
        MODULE          => 'Triplay',
        TP_ID           => $tariff->{TP_ID},
        TP_NAME         => $tariff->{NAME},
        SERVICE_NAME    => 'Triplay',
        FEES_PERIOD_DAY => $lang{DAY_FEE_SHORT},
        FEES_METHOD     => $FEES_METHODS->{$tariff->{FEES_METHOD}},
        DATE            => $ADMIN_REPORT{DATE},
        METHOD          => $tariff->{FEES_METHOD} ? $tariff->{FEES_METHOD} : 1,
      );


      my %PARAMS = (
        DESCRIBE => fees_dsc_former(\%FEES_DSC),
        DATE     => "$ADMIN_REPORT{DATE} $TIME",
        METHOD   => $tariff->{fees_method} ? $tariff->{fees_method} : 1
      );

      if ($tariff->{payment_type} || $user{DEPOSIT} + $user{CREDIT} > 0) {
        $Fees->take(\%user, $tariff->{DAY_FEE}, \%PARAMS);
        $debug_output .= "UID: $user{UID} SUM: $tariff->{DAY_FEE} REDUCTION: $user{REDUCTION}\n" if ($debug > 0);
      }
    }
  }

  $DEBUG .= $debug_output;
  return $debug_output;
}


#**********************************************************
=head2 triplay_monthly_fees($attr) - Monthly fees

  Arguments:
    $attr

=cut
#**********************************************************
sub triplay_monthly_fees {
  my ($attr) = @_;

  my $debug = $attr->{DEBUG} || 0;
  my $debug_output = '';

  if ($attr->{LOGON_ACTIVE_USERS} || $attr->{SRESTART}) {
    return $debug_output;
  }

  my $fees_priority = $conf{FEES_PRIORITY} || q{};

  $debug_output .= "Triplay: Monthly periodic payments\n" if ($debug > 1);

  $ADMIN_REPORT{DATE} = $DATE if (!$ADMIN_REPORT{DATE});

  $LIST_PARAMS{TP_ID} = $attr->{TP_ID} if ($attr->{TP_ID});

  my %USERS_LIST_PARAMS = ();
  $USERS_LIST_PARAMS{LOGIN} = $attr->{LOGIN} if ($attr->{LOGIN});
  $USERS_LIST_PARAMS{UID} = $attr->{UID} if ($attr->{UID});
  $USERS_LIST_PARAMS{EXT_BILL} = 1 if ($conf{BONUS_EXT_FUNCTIONS});
  $USERS_LIST_PARAMS{REGISTRATION} = "<$ADMIN_REPORT{DATE}";
  $USERS_LIST_PARAMS{GID} = $attr->{GID} if ($attr->{GID});

  my $START_PERIOD_DAY = ($conf{START_PERIOD_DAY}) ? $conf{START_PERIOD_DAY} : 1;
  my ($y, $m, $d) = split(/-/, $ADMIN_REPORT{DATE}, 3);

  if ($d != $START_PERIOD_DAY) {
    $DEBUG .= $debug_output;
    return $debug_output;
  }

  my $days_in_month = days_in_month({ DATE => $ADMIN_REPORT{DATE} });
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

  my $FEES_METHODS = get_fees_types({ SHORT => 1 });

  $users = Users->new($db, $admin, \%conf);
  $Triplay->{debug} = 1 if ($debug > 5);
  my $list = $Triplay->tp_list({
    %LIST_PARAMS,
    NAME        => '_SHOW',
    MODULE      => 'Triplay',
    DOMAIN_ID   => '_SHOW',
    FEES_METHOD => '_SHOW',
    MONTH_FEE   => '>0',
    CREDIT      => '_SHOW',
    MODULES     => 'Triplay',
    PAYMENT_TYPE=> '_SHOW',
    COLS_NAME   => 1,
    COLS_UPPER  => 1
  });

  foreach my $TP_INFO (@$list) {
    my $month_fee = $TP_INFO->{MONTH_FEE} || 0;
    #my $activate_date = "<=$ADMIN_REPORT{DATE}";
    my $postpaid = $TP_INFO->{POSTPAID_MONTHLY_FEE} || $TP_INFO->{PAYMENT_TYPE} || 0;
    $USERS_LIST_PARAMS{DOMAIN_ID} = $TP_INFO->{DOMAIN_ID};

    #Monthfee & min use
    if ($month_fee > 0) {
      $debug_output .= "TP ID: $TP_INFO->{ID} MF: $TP_INFO->{MONTH_FEE} POSTPAID: $postpaid "
        . "CREDIT: $TP_INFO->{CREDIT} "
        . "\n" if ($debug > 1);

      my $user_list = $Triplay->user_list({
        SERVICE_STATUS => "0;5",
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
        %USERS_LIST_PARAMS
      });

      foreach my $u (@$user_list) {
        my %user = (
          LOGIN          => $u->{login},
          UID            => $u->{uid},
          ID             => $u->{id},
          BILL_ID        => $u->{bill_id},
          REDUCTION      => $u->{reduction},
          DEPOSIT        => $u->{deposit},
          SERVICE_STATUS => $u->{service_status},
          CREDIT         => ($u->{credit} > 0) ? $u->{credit} : ($TP_INFO->{CREDIT} || 0),
          #Old
          # CREDIT       => ($u->{credit} > 0) ? $u->{credit} : ($conf{user_credit_change}) ? 0 : $TP_INFO->{CREDIT},
          COMPANY_ID     => $u->{company_id},
          STATUS         => $u->{service_status},
          TP_ID          => $TP_INFO->{TP_ID}
        );

        my %FEES_DSC = (
          MODULE            => 'Triplay',
          TP_ID             => $TP_INFO->{TP_ID},
          TP_NAME           => $TP_INFO->{NAME},
          SERVICE_NAME      => 'Triplay',
          FEES_PERIOD_MONTH => $lang{MONTH_FEE_SHORT},
          FEES_METHOD       => $FEES_METHODS->{$TP_INFO->{FEES_METHOD}},
          DATE              => $ADMIN_REPORT{DATE},
          METHOD            => ($TP_INFO->{FEES_METHOD}) ? $TP_INFO->{FEES_METHOD} : 1,
        );

        if ($debug > 3) {
          $debug_output .= " Login: $user{LOGIN} ($user{UID}) TP_ID: $u->{tp_id} Fees: $TP_INFO->{MONTH_FEE}"
            . "REDUCTION: $user{REDUCTION} DEPOSIT: $user{DEPOSIT} CREDIT $user{CREDIT} TP: $user{TP_ID}\n";
        }

        if (! $postpaid && $user{DEPOSIT} + $user{CREDIT} < $month_fee) {
          #Block services
          $debug_output .= "$user{LOGIN} deactivate";
          triplay_service_deactivate({
            TP_INFO   => $TP_INFO,
            USER_INFO => \%user,
            DEBUG     => $debug
          });
          next;
        }

        if ($user{SERVICE_STATUS} == 5) {
          $debug_output .= "$user{LOGIN} activate";
          triplay_service_activate({
            TP_INFO   => $TP_INFO,
            USER_INFO => \%user,
            DEBUG     => $debug
          });
        }

        if ($debug < 8) {
          if ($month_fee <= 0) {
            $debug_output .= "!!REDUCTION!! $user{LOGIN} UID: $user{UID} SUM: $month_fee REDUCTION: $user{REDUCTION}\n";
            next;
          }

          my %PARAMS = (
            DATE     => "$ADMIN_REPORT{DATE} $TIME",
            METHOD   => ($TP_INFO->{FEES_METHOD}) ? $TP_INFO->{FEES_METHOD} : 1,
            DESCRIBE => fees_dsc_former(\%FEES_DSC),
          );
          $PARAMS{DESCRIBE} .= " ($cure_month_begin-$cure_month_end)";

          $Fees->take(\%user, $month_fee, \%PARAMS);
          if ($Fees->{errno}) {
            print "Triplay Error: [ $user{UID} ] $user{LOGIN} SUM: $month_fee [$Fees->{errno}] $Fees->{errstr} ";
            if ($Fees->{errno} == 14) {
              print "[ $user{UID} ] $user{LOGIN} - Don't have money account";
            }
            print "\n";
          }
          elsif ($debug > 0) {
            $debug_output .= " $user{LOGIN}  UID: $user{UID} SUM: $month_fee REDUCTION: $user{REDUCTION}\n";
          }
        }
      }
    }
  }

  $DEBUG .= $debug_output;
  return $debug_output;
}


#**********************************************************
=head2 triplay_service_activate($attr)

  Arguments:
    $attr
      TP_INFO
      USER_INFO
        UID
        ID
      DEBUG

=cut
#**********************************************************
sub triplay_service_activate {
  my ($attr)=@_;

  my $debug = $attr->{DEBUG} || 0;

  $Triplay->user_change({
    UID    => $attr->{USER_INFO}->{UID},
    DISABLE => 0
  });

  my $service_list = $Triplay->service_list({
    UID        => $attr->{USER_INFO}->{UID},
    MODULE     => '_SHOW',
    SERVICE_ID => '_SHOW'
  });

  foreach my $service  (@$service_list) {
    if ($debug > 1) {
      print "UID: $service->{uid} SERVICE_ID: $service->{service_id} MODULE: $service->{module}\n";
    }
    my $fn = lc($service->{module}) .'_service_activate';
    if (defined(&$fn)) {
      if ($debug > 3) {
        print "run: $fn\n";
      }

      &{ \&$fn }({
        USER_INFO => {
          UID => $service->{uid},
          ID  => $service->{service_id},
        },
        TP_INFO  => {
          SMALL_DEPOSIT_ACTION => -1
        },
        STATUS    => 0
      });
    }
  }

  #_external('', { EXTERNAL_CMD => 'Internet', %{ $attr->{USER_INFO} }, QUITE => 1 });

  return 1;
}

#**********************************************************
=head2 triplay_service_deactivate($attr)

  Arguments:
    $attr
      TP_INFO
      USER_INFO
      DEBUG

=cut
#**********************************************************
sub triplay_service_deactivate {
  my ($attr)=@_;

  my $debug_output = q{};
  #my $TP_INFO = $attr->{TP_INFO};
  my $user_info = $attr->{USER_INFO};
  my $debug = $attr->{DEBUG} || 0;
  my $action = 0;

  if (defined($user_info->{SERVICE_STATUS}) && $user_info->{SERVICE_STATUS} != 5) {
    $Triplay->user_change({
      UID    => $user_info->{UID},
      DISABLE => 5
    });
  }

  my $service_list = $Triplay->service_list({
    UID        => $attr->{USER_INFO}->{UID},
    MODULE     => '_SHOW',
    SERVICE_ID => '_SHOW'
  });

  foreach my $service  (@$service_list) {
    if ($debug > 1) {
      print "UID: $service->{uid} SERVICE_ID: $service->{service_id} MODULE: $service->{module}\n";
    }
    my $fn = lc($service->{module}) .'_service_deactivate';

    if (defined(&$fn)) {
      if ($debug > 3) {
        print "run: $fn\n";
      }
      &{ \&$fn }({
        USER_INFO => {
          UID => $service->{uid},
          ID  => $service->{service_id},
        },
        TP_INFO  => {
          SMALL_DEPOSIT_ACTION => -1
        },
        STATUS    => 1
      });
    }
  }

  if ($action) {
    _external('', { EXTERNAL_CMD => 'Internet', %{$attr->{USER_INFO}}, QUITE => 1 });
  }

  return $debug_output;
}


1;