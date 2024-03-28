#!/usr/bin/perl -w
#**********************************************************
=head1 NAME

 Change tariff from config after payment

=cut
#**********************************************************

use strict;
use warnings FATAL => 'all';

BEGIN {
  use FindBin '$Bin';
  our $libpath;
  our $Bin;

  $libpath = $Bin . '/../';
  if ($Bin =~ m/\/axbills(\/)/) {
    $libpath = substr($Bin, 0, $-[1]);
  }

  unshift(@INC, $libpath,
    $libpath . '/AXbills/',
    $libpath . '/AXbills/mysql/',
    $libpath . '/AXbills/Control/',
    $libpath . '/lib/'
  );
}

use AXbills::Base qw(parse_arguments);
use Admins;
use Internet;
use AXbills::SQL;

my $argv = parse_arguments(\@ARGV);

if ($argv->{GET_ABON}) {
  require AXbills::Misc;
}

our (
  %conf
);
do "libexec/config.pl";

our $db = AXbills::SQL->connect(@conf{qw/dbtype dbhost dbname dbuser dbpasswd/}, \%conf);
our $admin = Admins->new($db, \%conf);

$admin->info($conf{SYSTEM_ADMIN_ID}, {
  IP    => '127.0.0.2',
  SHORT => 1
});

my $Internet = Internet->new($db, $admin, \%conf);

process_user_payments();

#**********************************************************
=head2 process_user_payments - process users list

=cut
#**********************************************************
sub process_user_payments {

  if ($argv->{UID}) {
    _change_tariff_after_payment($argv->{UID});
  }
  else {
    #local object for processing query
    my $admin_local = Admins->new($db, \%conf);
    $admin_local->query("SELECT paysys_log.uid
    FROM paysys_log
    INNER JOIN internet_main ON (paysys_log.uid=internet_main.uid)
    WHERE internet_main.tp_id = ? AND DATE(paysys_log.datetime) >= DATE(NOW())- INTERVAL 1 DAY
		GROUP BY paysys_log.uid;",
      undef,
      { COLS_NAME => 1, Bind => [ $conf{PAYSYS_FROM_TARIFF_AFTER_PAYMENT} || '' ] });

    my $users = $admin_local->{list} || [];

    if ($users && scalar @{$users}) {
      foreach my $user (@{$users}) {
        print "User $user->{uid} \n";
        _change_tariff_after_payment($user->{uid});
      }
    }
    else {
      print "No users\n";
    }
  }

  return 1;
}

#**********************************************************
=head2 change_tariff_after_payment ($attr) - Change tariff from config after payment

  Arguments:
    UID

=cut
#**********************************************************
sub _change_tariff_after_payment {
  my ($uid) = @_;
  my $from_tariff = $conf{PAYSYS_FROM_TARIFF_AFTER_PAYMENT} || '';
  my $to_tariff = $conf{PAYSYS_TO_TARIFF_AFTER_PAYMENT} || '';

  if (!$from_tariff) {
    print "Can\'t find the current internet tariff. Please add tp_id to \$conf{PAYSYS_FROM_TARIFF_AFTER_PAYMENT}\n";
    return 1;
  }
  if (!$to_tariff) {
    print "Can\'t find the next internet tariff. Please add tp_id to \$conf{PAYSYS_TO_TARIFF_AFTER_PAYMENT}\n";
    return 1;
  }

  if (!$uid) {
    print "Missing argument UID\n";
    return 1;
  }

  $Internet->user_info($uid);
  return 0 if ($from_tariff != $Internet->{TP_ID});

  if ($argv->{GET_ABON}) {

    require Tariffs;
    require Users;
    my $Users = Users->new($db, $admin, \%conf);
    my $Tariffs = Tariffs->new($db, \%conf, $admin);

    $Users->info($uid);

    my $list = $Tariffs->list({
      INNER_TP_ID   => $to_tariff,
      MONTH_FEE     => '_SHOW',
      COLS_NAME     => 1,
      COLS_UPPER    => 1,
      NEW_MODEL_TP  => 1,
    });

    if (!scalar @{$list}) {
      print "No tp id";
      return 1;
    }

    if ($conf{PAYSYS_FORCE_CHANGE_TP_AFTER_PAYMENT} || $list->[0]->{MONTH_FEE} == 0 ||
      (($Internet->{STATUS} == 2 || $Internet->{STATUS} == 5) &&
        $list->[0]->{MONTH_FEE} && $Users->{DEPOSIT} && $Users->{DEPOSIT} >= $list->[0]->{MONTH_FEE})) {

      $Internet->user_change({
        UID      => $uid,
        TP_ID    => $to_tariff,
        STATUS   => 0,
        ACTIVATE => ($conf{INTERNET_USER_ACTIVATE_DATE}) ? strftime("%Y-%m-%d", localtime(time)) : undef
      });

      if (!$Internet->{errno} && !$Internet->{STATUS}) {
        service_get_month_fee($Internet, { DO_NOT_USE_GLOBAL_USER_PLS => 1 });
        _external('', { EXTERNAL_CMD => 'Internet', %{$Users}, %{$Internet}, QUITE => 1 });
      }
    }
    else {
      $Internet->user_change({
        UID      => $uid,
        TP_ID    => $to_tariff,
      });
    }
  }
  else {
    $Internet->user_change({
      UID   => $uid,
      TP_ID => $to_tariff,
    });
  }

  return 1;
}

1;
