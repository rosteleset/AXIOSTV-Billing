#!/usr/bin/perl

=head1 NAME

  Show Internet warning message

=cut

use strict;
use FindBin '$Bin';

my $debug = 0;
my $version = 0.04;
BEGIN {
  our %conf;
  my $prefix = '/../..';
  require $Bin . $prefix . '/../libexec/config.pl';
  unshift(@INC,
    $Bin . $prefix .'/../',
    $Bin . $prefix .'/../AXbills',
    $Bin . $prefix .'/../lib/',
    $Bin . $prefix ."/../AXbills/$conf{dbtype}");
}

our (
  %lang,
  %conf,
  $DATE
);

use AXbills::SQL;
use AXbills::Base;
use Admins;
use Internet::Sessions;
use Internet;
use Finance;
use Users;

my $db    = AXbills::SQL->connect($conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd},
  { CHARSET => ($conf{dbcharset}) ? $conf{dbcharset} : undef });
my $Admin = Admins->new($db, \%conf);
my $Fees  = Finance->fees($db, $Admin, \%conf);
my $Users = Users->new($db, $Admin, \%conf);

$Admin->info($conf{USERS_WEB_ADMIN_ID} ? $conf{USERS_WEB_ADMIN_ID} : $conf{SYSTEM_ADMIN_ID},
  {
    IP    => '127.0.0.1',
    SHORT => 1
  });

require AXbills::Misc;

my $argv = parse_arguments(\@ARGV);

if ($argv->{help}) {
  exit;
}

$lang{START_MONTH_DEPOSIT} = 'Депозит По состоянию на 01.%m%.%Y%: %DEPOSIT%';
$lang{PAYMENT_MESSAGE} = 'Пожалуйста, оплатите платеж до 15.%m%.%Y%';

show_warning();

#**********************************************************
=head2 show_warning()

=cut
#**********************************************************
sub show_warning {

  if ($debug > 1) {
    print "Args: ";
    print %$argv;
    print "\n";
  }

  my ($Y, $m, undef) = split(/\-/, $DATE);

  my $user_list = $Users->list({
    LOGIN     => $argv->{LOGIN},
    DEPOSIT   => '_SHOW',
    COLS_NAME => 1,
    PAGE_ROWS => 1
  });

  my $user_deposit = $user_list->[0]->{deposit};
  my $month_deposit = 0;

  my $list = $Fees->list({
    LOGIN        => $argv->{LOGIN} || '-',
    SUM          => '_SHOW',
    LAST_DEPOSIT => '_SHOW',
    DATE         => "<=$Y-$m-01",
    COLS_NAME    => 1,
    SORT         => 'id',
    DESC         => 'DESC',
    PAGE_ROWS    => 1
  });

  if ($Fees->{TOTAL} > 0) {
    $month_deposit = $list->[0]->{last_deposit} - $list->[0]->{sum};
  }
  else {
    $month_deposit = 0;
  }

  $lang{START_MONTH_DEPOSIT} =~ s/%m%/$m/g;
  $lang{START_MONTH_DEPOSIT} =~ s/%Y%/$Y/g;
  $lang{START_MONTH_DEPOSIT} =~ s/%DEPOSIT%/$month_deposit/g;

  print $lang{START_MONTH_DEPOSIT} . "\n";

  if ($user_deposit < 0 && $user_deposit <= $month_deposit) {
    $lang{PAYMENT_MESSAGE} =~ s/%m%/$m/g;
    $lang{PAYMENT_MESSAGE} =~ s/%Y%/$Y/g;
    $lang{PAYMENT_MESSAGE} =~ s/%DEPOSIT%/$month_deposit/g;
    print "<br><font color='red'>$lang{PAYMENT_MESSAGE}</font>";
  }

  return 1;
}


#**********************************************************
#
#**********************************************************
sub help() {

  print <<"[END]";
Version: $version

[END]

  return 1;
}

1;