=head1 NAME

 billd plugin

 DESCRIBE: Internet status fee

 Make fee 3 days after blovk account with status: too small deposit

=head1 ARGUMENTS


=cut

use strict;
use warnings FATAL => 'all';
use Tariffs;
use Fees;
require AXbills::Misc;

our (
  $argv,
  $debug,
  $Sessions,
  %LIST_PARAMS,
  $debug_output,
  %conf,
  $db,
  $DATE,
  %lang,
  $base_dir
);

our Internet $Internet;
our Admins $Admin;
my $fee_period = 3;
my %ADMIN_REPORT = ();

internet_status_fee();

#**********************************************************
=head2 internet_status_fee($attr) - Internet_status fee

=cut
#**********************************************************
sub internet_status_fee {

  my $language = $conf{default_language} || 'english';
  my $main_file = $base_dir . '/language/'. $language .'.pl';
  require $main_file;

  my $Tariffs = Tariffs->new($db, \%conf, $Admin);
  my $Fees = Fees->new($db, $Admin, \%conf);

  $ADMIN_REPORT{DATE}=$argv->{DATE} || $DATE;

  my $list = $Tariffs->list({
    %LIST_PARAMS,
    MODULE            => 'Internet',
    MONTH_FEE         => '>0',
    ABON_DISTRIBUTION => 1,
    FIXED_FEES_DAY    => '_SHOW',
    COLS_NAME         => 1,
    COLS_UPPER        => 1
  });

  my ($y, $m, undef) = split(/-/, $ADMIN_REPORT{DATE}, 3);
  my $days_in_month = days_in_month({ DATE => $ADMIN_REPORT{DATE} });
  my $cure_month_begin = "$y-$m-01";
  my $cure_month_end = "$y-$m-$days_in_month";

  my %USERS_LIST_PARAMS = ();

  if ($argv->{LOGIN}) {
    $USERS_LIST_PARAMS{LOGIN}=$argv->{LOGIN};
  }

  foreach my $TP_INFO (@$list) {
    my $month_fee = $TP_INFO->{MONTH_FEE};
    my $activate_date = "<=$ADMIN_REPORT{DATE}";
    my $postpaid = $TP_INFO->{POSTPAID_MONTHLY_FEE} || $TP_INFO->{PAYMENT_TYPE} || 0;

    #Monthfee & min use
    $debug_output .= "TP ID: $TP_INFO->{ID} MF: $TP_INFO->{MONTH_FEE} POSTPAID: $postpaid "
      . "REDUCTION: $TP_INFO->{REDUCTION_FEE} EXT_BILL_ID: $TP_INFO->{EXT_BILL_ACCOUNT} CREDIT: $TP_INFO->{CREDIT} "
      . "MIN_USE: $TP_INFO->{MIN_USE} ABON_DISTR: $TP_INFO->{ABON_DISTRIBUTION}\n" if ($debug > 1);

    if ($TP_INFO->{ABON_DISTRIBUTION}) {
      $month_fee = $month_fee / $days_in_month;
    }

    $Internet->{debug} = 1 if ($debug > 5);
    my $ulist = $Internet->user_list(
      {
        INTERNET_ACTIVATE => "$activate_date",
        #EXPIRE       => "0000-00-00,>$ADMIN_REPORT{DATE}",
        INTERNET_EXPIRE   => "0000-00-00,>$ADMIN_REPORT{DATE}",
        INTERNET_STATUS   => "5",
        JOIN_SERVICE      => "<2",
        LOGIN_STATUS      => 0,
        TP_ID             => $TP_INFO->{TP_ID},
        SORT              => 1,
        PAGE_ROWS         => 1000000,
        TP_CREDIT         => '_SHOW',
        DELETED           => 0,
        LOGIN             => '_SHOW',
        BILL_ID           => '_SHOW',
        REDUCTION         => '_SHOW',
        DEPOSIT           => '_SHOW',
        CREDIT            => '_SHOW',
        COMPANY_ID        => '_SHOW',
        PERSONAL_TP       => '_SHOW',
        EXT_DEPOSIT       => '_SHOW',
        ACTION_TYPE       => 4,
        ACTION_DATE       => '_SHOW',
        COLS_NAME         => 1,
        GROUP_BY          => 'internet.id',
        %USERS_LIST_PARAMS
      }
    );

    foreach my $u (@$ulist) {
      my ($change_date, undef)=split(/ /, $u->{action_datetime});

      if (date_diff($change_date, $DATE) > $fee_period) {
        next;
      }

      my $EXT_INFO = '';
      my $ext_deposit_op = $TP_INFO->{EXT_BILL_ACCOUNT};
      my %user = (
        LOGIN           => $u->{login},
        UID             => $u->{uid},
        ID              => $u->{id},
        BILL_ID         => ($ext_deposit_op) ? $u->{ext_bill_id} : $u->{bill_id},
        MAIN_BILL_ID    => ($ext_deposit_op) ? $u->{bill_id} : 0,
        REDUCTION       => $u->{reduction},
        ACTIVATE        => $u->{internet_activate},
        DEPOSIT         => $u->{deposit},
        CREDIT          => ($u->{credit} > 0) ? $u->{credit} : $TP_INFO->{CREDIT},
        #Old
        # CREDIT       => ($u->{credit} > 0) ? $u->{credit} : ($conf{user_credit_change}) ? 0 : $TP_INFO->{CREDIT},
        COMPANY_ID      => $u->{company_id},
        INTERNET_STATUS => $u->{internet_status},
        EXT_DEPOSIT     => ($u->{ext_deposit}) ? $u->{ext_deposit} : 0,
      );

      my %FEES_DSC = (
        MODULE            => 'Internet',
        TP_ID             => $TP_INFO->{TP_ID},
        TP_NAME           => $TP_INFO->{NAME},
        FEES_PERIOD_MONTH => $lang{MONTH_FEE_SHORT},
        #FEES_METHOD       => $FEES_METHODS{$TP_INFO->{FEES_METHOD}}
      );

      if ($debug > 3) {
        $debug_output .= " Login: $user{LOGIN} ($user{UID}) TP_ID: $u->{tp_id} Fees: $TP_INFO->{MONTH_FEE}"
          . "REDUCTION: $user{REDUCTION} DEPOSIT: $user{DEPOSIT} CREDIT $user{CREDIT} ACTIVE: $user{ACTIVATE} TP: $u->{tp_id}\n";
      }

      my %FEES_PARAMS = (
        DATE   => $ADMIN_REPORT{DATE},
        METHOD => ($TP_INFO->{FEES_METHOD}) ? $TP_INFO->{FEES_METHOD} : 1,
      );
      my $sum = 0;

      #Make sum
      if ($u->{personal_tp} > 0) {
        if ($TP_INFO->{ABON_DISTRIBUTION}) {
          $sum = $u->{personal_tp} / $days_in_month;
        }
        else {
          $sum = $u->{personal_tp};
        }
      }
      else {
        $sum = $month_fee;
      }

      if ($TP_INFO->{REDUCTION_FEE} == 1 && $user{REDUCTION} > 0) {
        $sum = $sum * (100 - $user{REDUCTION}) / 100;
      }

      #take fees in first day of month
      $FEES_PARAMS{DESCRIBE} = fees_dsc_former(\%FEES_DSC);
      $FEES_PARAMS{DESCRIBE} .= " - $lang{ABON_DISTRIBUTION}" if ($TP_INFO->{ABON_DISTRIBUTION});

      # get fees
      if ($debug > 4) {
        $debug_output .= " UID: $user{UID} SUM: $sum REDUCTION: $user{REDUCTION}\n";
      }

      if ($debug < 8) {
        $FEES_PARAMS{DESCRIBE} .= " ($cure_month_begin-$cure_month_end)" if (!$TP_INFO->{ABON_DISTRIBUTION});
        if ($sum > 0) {
          $Fees->take(\%user, $sum, { %FEES_PARAMS });
        }
        $debug_output .= " $user{LOGIN}  UID: $user{UID} SUM: $sum REDUCTION: $user{REDUCTION} $EXT_INFO\n" if ($debug > 0);
      }
    }
  }

  return 1;
}


1;