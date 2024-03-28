#!/usr/bin/perl

=head1 NAME

  Ureports sender

=cut

use strict;
use warnings FATAL => 'all';

BEGIN {
  use FindBin '$Bin';
  our %conf;
  do $Bin . '/config.pl';
  unshift(@INC,
    $Bin . '/../',
    $Bin . "/../AXbills/mysql",
    $Bin . '/../AXbills/',
    $Bin . '/../lib/',
    $Bin . '/../AXbills/modules');
}

my $version = 0.80;
my $debug = 0;
our (
  $db,
  %conf,
  $TIME,
  @MODULES,
  %lang,
  %ADMIN_REPORT,
  %LIST_PARAMS,
  $DATE
);

use AXbills::Defs;
use AXbills::Base qw(int2byte in_array sendmail parse_arguments cmd date_diff);
use AXbills::Templates;
use AXbills::Misc;
use Admins;
use Shedule;
use Internet::Sessions;
use Finance;
use Fees;
use Ureports;
use Ureports::Base;
use Tariffs;
use POSIX qw(strftime);

require Control::Services;

our $html = AXbills::HTML->new({
  IMG_PATH => 'img/',
  NO_PRINT => 1,
  CONF     => \%conf,
  CHARSET  => $conf{default_charset},
  csv      => 1
});


#my $begin_time = check_time();
$db = AXbills::SQL->connect($conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd},
  { CHARSET => ($conf{dbcharset}) ? $conf{dbcharset} : undef });

#Always our for crossmodules
our $admin = Admins->new($db, \%conf);
$admin->info($conf{SYSTEM_ADMIN_ID}, { IP => '127.0.0.1' });

my $Ureports = Ureports->new($db, $admin, \%conf);
my $Fees = Fees->new($db, $admin, \%conf);
my $Tariffs = Tariffs->new($db, \%conf, $admin);
my $Shedule = Shedule->new($db, $admin, \%conf);
my $Sessions = Internet::Sessions->new($db, $admin, \%conf);
my $Ureports_base = Ureports::Base->new($db, $admin, \%conf, { HTML => $html, LANG => \%lang });

if ($html->{language} ne 'english') {
  do $Bin . "/../language/english.pl";
  do $Bin . "/../AXbills/modules/Ureports/lng_english.pl";
}

do $Bin . "/../language/$html->{language}.pl";
do $Bin . "/../AXbills/modules/Ureports/lng_$html->{language}.pl";

#my %FORM_BASE      = ();
#my @service_status = ("$lang{ENABLE}", "$lang{DISABLE}", "$lang{NOT_ACTIVE}");
#my @service_type   = ("E-mail", "SMS", "Fax");

#my %REPORTS        = (
#  1 => "$lang{DEPOSIT_BELOW}",
#  2 => "$lang{PREPAID_TRAFFIC_BELOW}",
#  3 => "$lang{TRAFFIC_BELOW}",
#  4 => "$lang{MONTH_REPORT}",
#);
my %SERVICE_LIST_PARAMS = ();

#Arguments
my $argv = parse_arguments(\@ARGV);

if (defined($argv->{help})) {
  help();
  exit;
}

if ($argv->{DEBUG}) {
  $debug = $argv->{DEBUG};
  print "DEBUG: $debug\n";
}

$DATE = $argv->{DATE} if ($argv->{DATE});

my $debug_output = ureports_periodic_reports($argv);
print $debug_output;

#**********************************************************
=head2 ureports_periodic_reports($attr)

  Arguments:
    $attr

=cut
#**********************************************************
sub ureports_periodic_reports {
  my ($attr) = @_;

  $debug = $attr->{DEBUG} || 0;
  $debug_output = '';

  $debug_output .= "Ureports: Daily spool former\n" if ($debug > 1);
  $LIST_PARAMS{MODULE} = 'Ureports';
  $LIST_PARAMS{TP_ID} = $argv->{TP_IDS} if ($argv->{TP_IDS});

  if ($argv->{REPORT_IDS}) {
    $argv->{REPORT_IDS} =~ s/,/;/g;
    $SERVICE_LIST_PARAMS{REPORT_ID} = $argv->{REPORT_IDS} if ($argv->{REPORT_IDS});
  }

  $SERVICE_LIST_PARAMS{LOGIN} = $argv->{LOGIN} if ($argv->{LOGIN});

  $Tariffs->{debug} = 1 if ($debug > 6);
  my $list = $Tariffs->list({
    REDUCTION_FEE    => '_SHOW',
    DAY_FEE          => '_SHOW',
    MONTH_FEE        => '_SHOW',
    PAYMENT_TYPE     => '_SHOW',
    EXT_BILL_ACCOUNT => '_SHOW',
    CREDIT           => '_SHOW',
    %LIST_PARAMS,
    COLS_NAME        => 1
  });

  $ADMIN_REPORT{DATE} = $DATE if (!$ADMIN_REPORT{DATE});
  $SERVICE_LIST_PARAMS{CUR_DATE} = $ADMIN_REPORT{DATE};
  my ($Y, $M, $D) = split(/-/, $ADMIN_REPORT{DATE}, 3);
  #my $reports_type = 0;

  foreach my $tp (@{$list}) {
    $debug_output .= "TP ID: $tp->{tp_id} DF: $tp->{day_fee} MF: $tp->{month_fee} POSTPAID: $tp->{payment_type} REDUCTION: $tp->{reduction_fee} EXT_BILL: $tp->{ext_bill_account} CREDIT: $tp->{credit}\n" if ($debug > 1);

    #Get users
    $Ureports->{debug} = 1 if ($debug > 5);

    my %users_params = (
      DATE           => '0000-00-00',
      TP_ID          => $tp->{tp_id},
      SORT           => 1,
      PAGE_ROWS      => 1000000,
      ACCOUNT_STATUS => 0,
      STATUS         => 0,
      ACTIVATE       => '_SHOW',
      REDUCTION      => '_SHOW',
      PASSWORD       => '_SHOW',
      %SERVICE_LIST_PARAMS,
      MODULE         => '_SHOW',
      COLS_NAME      => 1,
      COLS_UPPER     => 1,
    );

    if (in_array('Internet', \@MODULES)) {
      $users_params{INTERNET_TP} = 1;
      $users_params{INTERNET_STATUS} = '_SHOW';
      #$users_params{INTERNET_EXPIRE} = '_SHOW';
    }

    my $ulist = $Ureports->tp_user_reports_list(\%users_params);
    foreach my $user (@{$ulist}) {
      #Check bill id and deposit
      my %PARAMS = ();
      $user->{TP_ID} = $tp->{tp_id};
      my $internet_status = $user->{INTERNET_STATUS} || 0;
      #Skip disabled user
      next if ($internet_status == 1 || $internet_status == 2 || $internet_status == 3);
      $user->{VALUE} =~ s/,/\./s;

      if (! $user->{DESTINATION_ID}) {
        print "ERROR! LOGIN: $user->{LOGIN} Not defined destination id. \n Check sending information\n";
        next;
      }

      $debug_output .= "LOGIN: $user->{LOGIN} ($user->{UID}) DEPOSIT: $user->{deposit} CREDIT: $user->{credit} Report id: $user->{REPORT_ID} INTERNET STATUS: $internet_status $user->{DESTINATION_ID}\n" if ($debug > 3);

      if ($user->{BILL_ID} && defined($user->{DEPOSIT})) {
        #Skip action for pay opearation
        if ($user->{MSG_PRICE} > 0 && $user->{DEPOSIT} + $user->{CREDIT} < 0 && $tp->{payment_type} == 0) {
          $debug_output .= "UID: $user->{UID} REPORT_ID: $user->{REPORT_ID} DEPOSIT: $user->{DEPOSIT}/$user->{CREDIT} Skip action Small Deposit for sending\n" if ($debug > 0);
          next;
        }

        my $reduction_division = ($user->{REDUCTION} >= 100) ? 1 : ((100 - $user->{REDUCTION}) / 100);

        # Recomended payments
        my $total_daily_fee = 0;
        $user->{RECOMMENDED_PAYMENT} = 0;

        my $service_info = get_services({
          UID           => $user->{UID},
          REDUCTION     => $user->{REDUCTION},
          SKIP_DISABLED => 1,
          PAYMENT_TYPE  => 0
        },
          { SKIP_MODULES => 'Ureports,Sqlcmd' }
        );

        foreach my $service (@{$service_info->{list}}) {
          $user->{RECOMMENDED_PAYMENT} += $service->{SUM};
        }

        if ($service_info->{distribution_fee}) {
          $total_daily_fee = $service_info->{distribution_fee};
        }

        $user->{TOTAL_FEES_SUM} = $user->{RECOMMENDED_PAYMENT};

        if ($user->{DEPOSIT} + $user->{CREDIT} > 0) {
          $user->{RECOMMENDED_PAYMENT} = sprintf("%.2f",
            ($user->{RECOMMENDED_PAYMENT} - $user->{DEPOSIT} > 0) ? ($user->{RECOMMENDED_PAYMENT} - $user->{DEPOSIT} + 0.01) : 0);
        }
        else {
          $user->{RECOMMENDED_PAYMENT} += sprintf("%.2f", abs($user->{DEPOSIT} + $user->{CREDIT}));
        }

        if ($conf{UREPORTS_ROUNDING} && $user->{RECOMMENDED_PAYMENT} > 0) {
          if (int($user->{RECOMMENDED_PAYMENT}) < $user->{RECOMMENDED_PAYMENT}) {
            $user->{RECOMMENDED_PAYMENT} = int($user->{RECOMMENDED_PAYMENT} + 1);
          }
        }

        $user->{DEPOSIT} = sprintf("%.2f", $user->{DEPOSIT});
        $user->{EXPIRE_DAYS} = 0;
        if ($total_daily_fee > 0) {
          $user->{EXPIRE_DAYS} = int($user->{DEPOSIT} / $reduction_division / $total_daily_fee);
        }
        else {
          require Control::Service_control;
          Control::Service_control->import();

          my $Service_control = Control::Service_control->new($db, $admin, \%conf, { HTML => $html, LANG => \%lang });

          my $warnings = $Service_control->service_warning({
            UID    => $user->{UID},
            ID     => $user->{SERVICE_ID},
            MODULE => 'Internet'
          });

          #Internet expire
          $user->{EXPIRE_DAYS} = $warnings->{DAYS_TO_FEE} || 0;
          $user->{TP_EXPIRE} = $user->{EXPIRE_DAYS};
        }

        $user->{EXPIRE_DATE} = POSIX::strftime("%Y-%m-%d", localtime(time + $user->{EXPIRE_DAYS} * 86400));

        #Report 1 Deposit belove and internet status active
        if ($user->{REPORT_ID} == 1) {
          if ($user->{VALUE} > $user->{DEPOSIT} && !$internet_status) {
            %PARAMS = (
              DESCRIBE => "$lang{REPORTS} ($user->{REPORT_ID}) ",
              MESSAGE  => "$lang{DEPOSIT}: $user->{DEPOSIT}",
              SUBJECT  => "$lang{DEPOSIT_BELOW}"
            );
          }
          else {
            next;
          }
        }

        #Report 2 DEposit + credit below
        elsif ($user->{REPORT_ID} == 2) {
          if ($user->{VALUE} > $user->{DEPOSIT} + $user->{CREDIT}) {
            %PARAMS = (
              DESCRIBE => "$lang{REPORTS} ($user->{REPORT_ID}) ",
              MESSAGE  => "$lang{DEPOSIT}: $user->{DEPOSIT} $lang{CREDIT}: $user->{CREDIT}",
              SUBJECT  => "$lang{DEPOSIT_CREDIT_BELOW}"
            );
          }
          else {
            next;
          }
        }

        #Report 3 Prepaid traffic rest
        elsif ($user->{REPORT_ID} == 3) {
          if ($Sessions->prepaid_rest({ UID => $user->{UID}, })) {
            %PARAMS = (
              DESCRIBE => "$lang{REPORTS} ($user->{REPORT_ID}) ",
              SUBJECT  => "$lang{PREPAID_TRAFFIC_BELOW}"
            );

            $list = $Sessions->{INFO_LIST};
            #my $rest_traffic = '';
            my $rest = 0;
            foreach my $line (@{$list}) {
              $rest = ($conf{INTERNET_INTERVAL_PREPAID}) ? $Sessions->{REST}->{ $line->{interval_id} }->{ $line->{traffic_class} } : $Sessions->{REST}->{ $line->{traffic_class} };

              #REST MB
              $PARAMS{REST} = $rest;
              #REST GB
              $PARAMS{REST_GB} = sprintf("%.2f", ($rest / 1024));
              $PARAMS{REST_DIMENSION} = int2byte($rest);
              $PARAMS{PREPAID} = $line->{prepaid};

              $PARAMS{'REST_' . ($line->{traffic_class} || 0)} = $rest;
              $PARAMS{'REST_DIMENSION_' . ($line->{traffic_class} || 0)} = int2byte($rest);
              $PARAMS{'PREPAID_' . ($line->{traffic_class} || 0)} = $line->{prepaid} || 0;

              if ($rest < $user->{VALUE}) {
                $PARAMS{MESSAGE} .= "================\n $lang{TRAFFIC} $lang{TYPE}: $line->{traffic_class}\n$lang{BEGIN}: $line->{interval_begin}\n"
                  . "$lang{END}: $line->{interval_end}\n"
                  . "$lang{TOTAL}: $line->{prepaid}\n"
                  . "\n $lang{REST}: "
                  . $rest . "\n================";
              }
            }

            if (!$PARAMS{MESSAGE}) {
              next;
            }
          }
        }
        elsif ($user->{REPORT_ID} == 5 && $D == 1) {
          $Sessions->list(
            {
              UID    => $user->{UID},
              PERIOD => 6
            }
          );

          my $traffic_in = ($Sessions->{TRAFFIC_IN}) ? $Sessions->{TRAFFIC_IN} : 0;
          my $traffic_out = ($Sessions->{TRAFFIC_OUT}) ? $Sessions->{TRAFFIC_IN} : 0;
          my $traffic_sum = $traffic_in + $traffic_out;

          %PARAMS = (
            DESCRIBE => "$lang{REPORTS} ($user->{REPORT_ID}) ",
            MESSAGE  =>
              "$lang{MONTH}:\n $lang{DEPOSIT}: $user->{DEPOSIT}\n $lang{CREDIT}: $user->{CREDIT}\n $lang{TRAFFIC}: $lang{RECV}: " . int2byte($traffic_in) . " $lang{SEND}: " . int2byte($traffic_out) . " \n  $lang{SUM}: " . int2byte($traffic_sum) . " \n"
              ,
            SUBJECT  => "$lang{MONTH}: $lang{DEPOSIT} / $lang{CREDIT} / $lang{TRAFFIC}",
          );
        }

        # 7 - credit expired
        elsif ($user->{REPORT_ID} == 7) {
          if (defined($user->{CREDIT_EXPIRE}) && $user->{CREDIT_EXPIRE} <= $user->{VALUE}) {
            %PARAMS = (
              DESCRIBE           => "$lang{REPORTS} ($user->{REPORT_ID}) ",
              MESSAGE            => "$lang{CREDIT} $lang{EXPIRE}",
              SUBJECT            => "$lang{CREDIT} $lang{EXPIRE}",
              CREDIT_EXPIRE_DAYS => $user->{CREDIT_EXPIRE}
            );
          }
          else {
            next;
          }
        }

        # 8 - login disable
        elsif ($user->{REPORT_ID} == 8) {
          if ($user->{DISABLE}) {
            %PARAMS = (
              DESCRIBE => "$lang{REPORTS} ($user->{REPORT_ID}) ",
              MESSAGE  => "$lang{LOGIN} $lang{DISABLE}",
              SUBJECT  => "$lang{LOGIN} $lang{DISABLE}"
            );
          }
          else {
            next;
          }
        }

        # 9 - X days for expire
        elsif ($user->{REPORT_ID} == 9) {
          #if ( $user->{TP_EXPIRE} == $user->{VALUE} ){
          if ($user->{EXPIRE_DAYS} == $user->{VALUE}) {
            %PARAMS = (
              DESCRIBE => "$lang{REPORTS} ($user->{REPORT_ID}) ",
              MESSAGE  => "$lang{DAYS_TO_EXPIRE}: " . ($user->{EXPIRE_DAYS} || q{}),
              SUBJECT  => "$lang{TARIF_PLAN} $lang{EXPIRE}"
            );
          }
          else {
            next;
          }
        }

        # 10 - TOO SMALL DEPOSIT FOR NEXT MONTH WORK
        elsif ($user->{REPORT_ID} == 10) {
          if ($user->{RECOMMENDED_PAYMENT} > 0 && $user->{RECOMMENDED_PAYMENT} * $reduction_division > $user->{DEPOSIT} + $user->{CREDIT}) {
            %PARAMS = (
              DESCRIBE            => "$lang{REPORTS} ($user->{REPORT_ID}) ",
              MESSAGE             =>
                "$lang{SMALL_DEPOSIT_FOR_NEXT_MONTH}. $lang{DEPOSIT}: $user->{DEPOSIT} $lang{TARIF_PLAN} $user->{TP_MONTH_FEE} $lang{RECOMMENDED_PAYMENT}: $user->{RECOMMENDED_PAYMENT}"
                ,
              SUBJECT             => $lang{ERR_SMALL_DEPOSIT},
              RECOMMENDED_PAYMENT => $user->{RECOMMENDED_PAYMENT}
            );
          }
          else {
            next;
          }
        }
        #Report 11 - Small deposit for next month activation with predays XX trigger
        elsif ($user->{REPORT_ID} == 11 && $user->{EXPIRE_DAYS} <= $user->{VALUE} && !$internet_status) {
          if ($user->{TP_MONTH_FEE} && $user->{TP_MONTH_FEE} > $user->{DEPOSIT}) {
            my $recharge = $user->{TP_MONTH_FEE} + (($user->{DEPOSIT} < 0) ? abs($user->{DEPOSIT}) : 0);
            %PARAMS = (
              DESCRIBE => "$lang{REPORTS} ($user->{REPORT_ID}) ",
              MESSAGE  => '', #"$lang{SMALL_DEPOSIT_FOR_NEXT_MONTH} $lang{BALANCE_RECHARCHE} $recharge",
              SUBJECT  => $lang{DEPOSIT_BELOW}
            );
          }
          else {
            next;
          }
        }
        #Report 13 All service expired throught
        elsif ($user->{REPORT_ID} == 13 && !$internet_status) {
          if ($user->{EXPIRE_DAYS} && $user->{EXPIRE_DAYS} <= $user->{VALUE}) {
            $debug_output .= "(Day fee: $total_daily_fee / $user->{EXPIRE_DAYS} -> $user->{VALUE} \n" if ($debug > 4);

            if ($user->{EXPIRE_DAYS} <= $user->{VALUE} && $user->{EXPIRE_DAYS} >= 0 && $user->{RECOMMENDED_PAYMENT} > 0) {
              $lang{ALL_SERVICE_EXPIRE} =~ s/XX/ $user->{EXPIRE_DAYS} /;
              %PARAMS = (
                DESCRIBE            => "$lang{REPORTS} ($user->{REPORT_ID}) ",
                MESSAGE             => "",
                SUBJECT             => $lang{ALL_SERVICE_EXPIRE},
                RECOMMENDED_PAYMENT => $user->{RECOMMENDED_PAYMENT}
              );
            }
            else {
              next;
            }
          }
        }
        #Report 14. Notify before abon
        elsif ($user->{REPORT_ID} == 14) {
          if ($user->{EXPIRE_DAYS} <= $user->{VALUE} && $user->{REDUCTION} < 100) {
            %PARAMS = (
              DESCRIBE => $lang{REPORTS},
              MESSAGE  => "",
              SUBJECT  => $lang{CURRENT_DEPOSIT},
              TP_NAME  => $user->{TP_NAME}
            );
          }
          else {
            next;
          }
        }
        #Report 15: Internet change status
        elsif ($user->{REPORT_ID} == 15) {
          if ($internet_status && $internet_status != 3) {
            my @service_status = ($lang{ENABLE}, $lang{DISABLE}, $lang{NOT_ACTIVE}, $lang{HOLD_UP},
              "$lang{DISABLE}: $lang{NON_PAYMENT}", "$lang{ERR_SMALL_DEPOSIT}",
              "$lang{VIRUS_ALERT}");

            my $message = "Internet: $service_status[$internet_status]";
            if ($internet_status == 5) {
              $message .= "\n $lang{RECOMMENDED_PAYMENT}:  $user->{RECOMMENDED_PAYMENT}\n";
            }

            %PARAMS = (
              DESCRIBE => $lang{REPORTS},
              MESSAGE  => $message,
              SUBJECT  => "Internet: $service_status[$internet_status]",
              TP_NAME  => $user->{TP_NAME}
            );
          }
        }
        # Reports 16 Next period TP
        elsif ($user->{REPORT_ID} == 16) {
          # TODO: delete next row if something broken fix for XX report if no needed
          next if ($user->{EXPIRE_DAYS} && $user->{EXPIRE_DAYS} <= $user->{VALUE});
          $Shedule->list({
            UID        => $user->{UID},
            Y          => '',
            M          => '',
            NEXT_MONTH => 1
          });

          my $recomended_payment = $user->{RECOMMENDED_PAYMENT};
          my $message .= "\n $lang{RECOMMENDED_PAYMENT}: $recomended_payment\n";

          %PARAMS = (
            DESCRIBE => "$lang{REPORTS} ($user->{REPORT_ID}) ",
            MESSAGE  => "$message",
            SUBJECT  => "$lang{ALL_SERVICE_EXPIRE}",
          );
        }
        #Custom reports
        elsif ($user->{module}) {
          my $report_module = $user->{module};
          exit if $report_module !~ /^[\w.]+$/;
          my $load_mod = "Ureports::$report_module";
          eval " require $load_mod ";
          if ($@) {
            print $@;
            exit;
          }
          $report_module =~ s/\.pm//;
          my $mod = "Ureports::$report_module";
          my $Report = $mod->new($db, $admin, \%conf);
          if ($debug > 2) {
            $Report->{debug} = 1;
          }
          my $report_function = $Report->{SYS_CONF}{REPORT_FUNCTION};
          if ($debug > 1) {
            print "Function: $report_function Name: $Report->{SYS_CONF}{REPORT_NAME} Tpl: $Report->{SYS_CONF}{TEMPLATE}\n";
          }

          $Report->$report_function($user, { %$argv, DATE => $DATE });
          if ($Report->{errno}) {
            print "ERROR: [$Report->{errno}] $Report->{errstr}\n";
          }

          if ($Report->{PARAMS}) {
            %PARAMS = %{$Report->{PARAMS}};
            if ($debug > 1) {
              print "ADD PARAMS\n";
              foreach my $key (sort keys %PARAMS) {
                print " $key -> $PARAMS{$key}\n";
              }
              print "Template: " . ($Report->{SYS_CONF}{TEMPLATE} || q{}) . "\n";
            }
          }
          else {
            if ($debug > 1) {
              print "NO PARAMS\n";
            }
            next;
          }

          $PARAMS{MESSAGE_TEPLATE} = $Report->{SYS_CONF}{TEMPLATE};
        }
      }
      else {
        print "[ $user->{UID} ] $user->{LOGIN} - Don't have money account\n";
        next;
      }

      next if (scalar keys %PARAMS <= 0);

      #Send reports section
      my $send_status = $Ureports_base->ureports_send_reports(
        $user->{DESTINATION_TYPE},
        $user->{DESTINATION_ID},
        $PARAMS{MESSAGE},
        {
          %{$user},
          %PARAMS,
          SUBJECT         => $PARAMS{SUBJECT},
          REPORT_ID       => $user->{REPORT_ID},
          UID             => $user->{UID},
          TP_ID           => $user->{TP_ID},
          MESSAGE         => $PARAMS{MESSAGE},
          DATE            => "$ADMIN_REPORT{DATE} $TIME",
          METHOD          => 1,
          MESSAGE_TEPLATE => $PARAMS{MESSAGE_TEPLATE},
          DEBUG           => $debug,
          Y               => $Y,
          M               => $M,
          D               => $D
        }
      );

      if ($debug < 5 && !$PARAMS{SKIP_UPDATE_REPORT} && $send_status) {
        $Ureports->tp_user_reports_update({
          UID       => $user->{UID},
          REPORT_ID => $user->{REPORT_ID}
        });
      }

      if ($user->{MSG_PRICE} > 0) {
        my $sum = $user->{MSG_PRICE};

        if ($debug > 4) {
          $debug_output .= " UID: $user->{UID} SUM: $sum REDUCTION: $user->{REDUCTION}\n";
        }
        else {
          $Fees->take($user, $sum, { %PARAMS });
          if ($Fees->{errno}) {
            print "Error: [$Fees->{errno}] $Fees->{errstr} ";
            if ($Fees->{errno} == 14) {
              print "[ $user->{UID} ] $user->{LOGIN} - Don't have money account";
            }
            print "\n";
          }
          elsif ($debug > 0) {
            $debug_output .= " $user->{LOGIN}  UID: $user->{UID} SUM: $sum REDUCTION: $user->{REDUCTION}\n" if ($debug > 0);
          }
        }
      }

      $debug_output .= "UID: $user->{UID} REPORT_ID: $user->{REPORT_ID} DESTINATION_TYPE: $user->{DESTINATION_TYPE} DESTINATION: $user->{DESTINATION_ID}\n" if ($debug > 0);
    }
  }

  return $debug_output;
}


#**********************************************************
#
#**********************************************************
sub help {

  print <<"[END]";
Ureports sender ($version).

  DEBUG=0..6           - Debug mode
  DATE="YYYY-MM-DD"    - Send date
  REPORT_IDS=[1,2,4..] - reports ids
  LOGIN=[...,]         - make reports for some logins
  TP_IDS=[...,]        - make reports for some tarif plans
  help                 - this help
[END]

  return 1;
}

1

