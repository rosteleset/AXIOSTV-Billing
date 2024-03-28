#!/usr/bin/perl

=head1 NAME

  Auto zap/hangup console utility

  VERSION: 0.29
  REVISION: 20220221

=cut

#**********************************************************

use strict;
use warnings FATAL => 'all';

our (%conf, $DATE, $TIME, $Log, $db, @MODULES);

BEGIN {
  use FindBin '$Bin';
  require $Bin . '/../libexec/config.pl';
  unshift(@INC, $Bin . '/../', $Bin . '/../lib', $Bin . '/../AXbills', $Bin . "/../AXbills/$conf{dbtype}/");
}

my $debug = 0;
my $VERSION = 0.29;

use AXbills::SQL;
use AXbills::Base qw(check_time parse_arguments gen_time days_in_month in_array);
use Admins;
use Nas;
use POSIX qw(strftime);
use Internet::Sessions;
use Internet;

my $begin_time = check_time();

require AXbills::Nas::Control;
AXbills::Nas::Control->import();

my $argv = parse_arguments(\@ARGV);

if ($argv->{help}) {
  print <<"[END]";

autozap.pl Version: $VERSION

  NAS_ID=             - NAS ID for ZAP
  ACTION_EXPR=        - Extr for action (wildcard *)
  ACTION_COUNT=       - Count of some actions default 20
  LAST_ACTIONS_COUNT= - last history actions. default 250.
  NEGATIVE_DEPOSIT=1  - Hangup only with negtive deposit
  DAYS2FINISH="x,x"   - Hangup when les then xx days to finich (Only for days or distributed tarrifs)
  PAYMENT_METHOD      - FIlter only payment type user
  SLEEP=COUNT:TIME    - Sleep after count of actions
  GUEST=1             - Select only guest session
  HANGUP=1            - Make Hangup
  DURATION=           - Max duration more then
  LOGIN=...           - login for hangup
  COUNT=              - Hangup or zap records (Default: infinity)
  UID=...             - UID for hangup
  TP_ID=...           - TP_ID for hangup
  GID=...             - Group ID for hangup
  LIMIT=100           - Hangup limit
  HANGUP_PERIOD       - Hangup only users with hangup period (Extra field: _hangup_period)
  TURBO               - Turbomode manage
  DEBUG=1..6          -
  VLAN                - VLAN of client
  SERVER_VLAN         - VLAN of server
  help                - This help
[END]

  exit;
}

$debug = ($argv->{DEBUG}) ? $argv->{DEBUG} : $debug;

$db = AXbills::SQL->connect($conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd}, { CHARSET => ($conf{dbcharset}) ? $conf{dbcharset} : undef });

require Log;
Log->import('log_add');
my $Nas_cmd = AXbills::Nas::Control->new($db, \%conf);

my $Admin = Admins->new($db, \%conf);
$Admin->info($conf{SYSTEM_ADMIN_ID}, { IP => '127.0.0.1' });

my $Nas = Nas->new($db, \%conf);
$Log = Log->new($db, \%conf);
$Log->{PRINT} = 1;

my $Sessions = Internet::Sessions->new($db, $Admin, \%conf);
#my $Internet = Internet->new($db, $Admin, \%conf);

my %LIST_PARAMS = (
  USER_NAME            => '_SHOW',
  ACCT_SESSION_ID      => '_SHOW',
  NAS_PORT_ID          => '_SHOW',
  NAS_IP               => '_SHOW',
  CLIENT_IP            => '_SHOW',
  CONNECT_INFO         => '_SHOW',
  CID                  => '_SHOW',
  USER_NAME            => '_SHOW',
  UID                  => '_SHOW',
  DEPOSIT              => '_SHOW',
  CREDIT               => '_SHOW',
  TP_CREDIT            => '_SHOW',
  TP_MONTH_FEE         => '_SHOW',
  TP_DAY_FEE           => '_SHOW',
  TP_ABON_DISTRIBUTION => '_SHOW',
);

if ($argv->{LOGIN}) {
  $LIST_PARAMS{USER_NAME} = $argv->{LOGIN};
}
elsif ($argv->{UID}) {
  $LIST_PARAMS{UID} = $argv->{UID};
}

if (defined($argv->{GUEST})) {
  $LIST_PARAMS{GUEST} = $argv->{GUEST};
}

if ($argv->{DURATION}) {
  $LIST_PARAMS{DURATION_SEC} = $argv->{DURATION};
}

if (defined($argv->{PAYMENT_METHOD})) {
  $LIST_PARAMS{PAYMENT_METHOD} = $argv->{PAYMENT_METHOD};
}

if ($argv->{TURBO}) {
  $LIST_PARAMS{TURBO_BEGIN}='_SHOW';
  $LIST_PARAMS{TURBO_END}="<$DATE $TIME";
}

if ($argv->{TP_ID}) {
  $LIST_PARAMS{TP_ID} = $argv->{TP_ID};
}

if ($argv->{GID}) {
  $LIST_PARAMS{GID} = $argv->{GID};
}

if ($argv->{COUNT}) {
  $LIST_PARAMS{PAGE_ROWS} = $argv->{COUNT};
  $LIST_PARAMS{LIMIT} = $LIST_PARAMS{PAGE_ROWS};
}

if ($argv->{LIMIT}) {
  $LIST_PARAMS{PAGE_ROWS} = $argv->{LIMIT};
  $LIST_PARAMS{LIMIT} = $LIST_PARAMS{PAGE_ROWS};
}

if ($argv->{HANGUP_PERIOD}) {
  $LIST_PARAMS{_HANGUP_PERIOD} = strftime("%H", localtime(time));
}

$LIST_PARAMS{NAS_ID} = $argv->{NAS_ID} if ($argv->{NAS_ID});
my $count = 0;

if ($debug > 1) {
  print "DATE: $DATE $TIME\n";
}

if ($argv->{HANGUP}) {
  if ($debug > 6) {
    $Sessions->{debug} = 1;
    $Nas->{debug} = 1;
  }

if ($argv->{VLAN}) {
  $LIST_PARAMS{VLAN} = $argv->{VLAN};
}

if ($argv->{SERVER_VLAN}) {
  $LIST_PARAMS{SERVER_VLAN} = $argv->{SERVER_VLAN};
}

  $Sessions->online(\%LIST_PARAMS);

  if ($Sessions->{errno}) {
    print "Error: $Sessions->{errno} $Sessions->{errstr}\n";
    exit;
  }

  my $online_list = $Sessions->{nas_sorted};
  my $nas_list = $Nas->list({ COLS_NAME => 1, PAGE_ROWS => 60000 });

  foreach my $nas_row (@$nas_list) {
    next if (!defined($online_list->{ $nas_row->{nas_id} }));
    $Nas->info({ NAS_ID => $nas_row->{nas_id} });
    foreach my $online (@{$online_list->{ $nas_row->{nas_id} }}) {
      my %ACCT_INFO = (
        ACCT_SESSION_ID    => $online->{acct_session_id} || q{},
        NAS_PORT           => $online->{nas_port_id},
        NAS_IP_ADDRESS     => $nas_row->{nas_ip},
        FRAMED_IP_ADDRESS  => $online->{client_ip},
        CONNECT_INFO       => $online->{connection_info},
        CALLING_STATION_ID => $online->{cid} || q{},
        USER_NAME          => $online->{user_name},
        UID                => $online->{uid},
        DEPOSIT            => $online->{deposit},
        CREDIT             => ($online->{credit} > 0) ? $online->{credit} : $online->{tp_credit},
      );

      if ($argv->{DAYS2FINISH}) {
        my @day2finish = split(/,/, $argv->{DAYS2FINISH});
        my $day_fee = $online->{tp_day_fee} || 0;

        if ($online->{tp_month_fee} > 0 && $online->{tp_abon_distribution}) {
          $day_fee = $online->{tp_month_fee} / days_in_month({ DATE => $DATE });
        }

        if ($day_fee > 0) {
          my $last_days = int(($ACCT_INFO{DEPOSIT} + $ACCT_INFO{CREDIT}) / $day_fee);
          print "$ACCT_INFO{USER_NAME} days: $last_days\n" if ($debug > 3);
          if (!in_array($last_days, \@day2finish)) {
            next;
          }
          print "$ACCT_INFO{USER_NAME} Days to new period: $last_days\n" if ($debug > 0);
        }
      }

      if (defined($argv->{NEGATIVE_DEPOSIT}) && $ACCT_INFO{DEPOSIT} + $ACCT_INFO{CREDIT} > 0) {
        print "1:INFO=Hangupped '$ACCT_INFO{USER_NAME}'" if ($argv->{LOGIN});
        next;
      }

      if ($debug > 1) {
        print "[$ACCT_INFO{UID}] $ACCT_INFO{USER_NAME} $ACCT_INFO{FRAMED_IP_ADDRESS} $ACCT_INFO{NAS_PORT} $ACCT_INFO{NAS_IP_ADDRESS} $ACCT_INFO{ACCT_SESSION_ID} $ACCT_INFO{CALLING_STATION_ID}\n";
      }

      if ($debug < 5) {
        $Nas_cmd->hangup(
          $Nas,
          $ACCT_INFO{NAS_PORT},
          $ACCT_INFO{USER_NAME},
          {
            ACCT_SESSION_ID   => $ACCT_INFO{ACCT_SESSION_ID},
            FRAMED_IP_ADDRESS => $ACCT_INFO{FRAMED_IP_ADDRESS},
            UID               => $ACCT_INFO{UID},
            DEBUG             => ($debug > 1) ? $debug : 0,
            INTERNET          => in_array('Internet', \@MODULES)
          }
        );

        #          if ($ret == 0) {
        if ($argv->{CREDIT}) {
          print "1:INFO=Hangupped '$ACCT_INFO{USER_NAME}'";
        }

        #           }
      }
      $count++;

      if ($argv->{SLEEP}) {
        my ($action_count, $sleep_time) = split(/:/, $argv->{SLEEP});

        if ($count % $action_count == 0) {
          if ($debug > 1) {
            print "Sleep: $sleep_time ($count)\n";
          }
          sleep $sleep_time;
        }
      }
    }
  }

  if ($LIST_PARAMS{USER_NAME} && $Sessions->{TOTAL} == 0) {
    print "1:INFO=Not online '". (($LIST_PARAMS{USER_NAME} && $LIST_PARAMS{USER_NAME} ne '_SHOW') ? $LIST_PARAMS{USER_NAME} : q{}) ."'";
  }
}
elsif ($argv->{ACTION_EXPR}) {
  $argv->{LAST_ACTIONS_COUNT} = 250 if (!$argv->{LAST_ACTIONS_COUNT});
  $argv->{ACTION_COUNT} = 20 if (!$argv->{ACTION_COUNT});

  if (!$LIST_PARAMS{NAS_ID}) {
    print "Error: Select NAS server\n";
    exit;
  }

  my $list = $Log->log_list({
    MESSAGE   => $argv->{ACTION_EXPR},
    PAGE_ROWS => $argv->{LAST_ACTIONS_COUNT},
    %LIST_PARAMS
  });

  if ($debug > 0) {
    foreach my $line (@$list) {
      print "$line->[4]\n";
    }
  }

  print "$Nas->{OUTPUT_ROWS}\n" if ($debug > 0);
  if ($Nas->{OUTPUT_ROWS} > $argv->{ACTION_COUNT}) {
    print "Zap sessins on: $LIST_PARAMS{NAS_ID}\n";
    goto ZAP_LABEL;
  }
}
else {
  ZAP_LABEL:
  $Sessions->zap(0, 0, 0, { %LIST_PARAMS });
}

if ($debug > 0) {
  print "Total: $count\n";
  gen_time($begin_time);
}

1

