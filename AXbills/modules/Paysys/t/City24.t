#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use lib '.';
use lib '../../';
use Paysys::t::Init_t;
require Paysys::systems::City24;

our (
  %conf,
  $db,
  $admin,
  $debug,
  $user_id,
  $payment_sum,
  $payment_id,
  $argv
);

my $login = $argv->{LOGIN} || $conf{PAYSYS_CITY24_LOGIN} || q{};
my $password = $argv->{PASSWORD} || $conf{PAYSYS_CITY24_PASSWORD} || q{};

my $Payment_plugin = Paysys::systems::City24->new($db, $admin, \%conf);
$Payment_plugin->{TEST}=1;
if ($debug > 3) {
  $Payment_plugin->{DEBUG}=7;
}

$payment_sum = int($payment_sum * 100);
$payment_id = int(rand(10000));
$user_id = $argv->{user} || $Payment_plugin->{conf}->{PAYSYS_TEST_USER} || '';
my $date = POSIX::strftime('%Y%m%d%H%M%S', localtime());

our @requests = (
  {
    name    => 'GET_USER',
    request => qq{<?xml version="1.0" encoding="UTF-8"?>
<commandCall>
    <login>$login</login>
    <password>$password</password>
    <command>check</command>
    <transactionID>3362935524</transactionID>
    <payElementID>1</payElementID>
    <account>$user_id</account>
    <payID>$payment_id</payID>
</commandCall>
    },
    result  => qq{
    }
  },
  {
    name    => 'PAY',
    request => qq{<?xml version="1.0" encoding="UTF-8"?>
    <commandCall>
    <login>$login</login>
    <password>$password</password>
    <command>pay</command>
    <transactionID>1234567890123</transactionID>
    <payTimestamp>$date</payTimestamp>
    <payID>$payment_id</payID>
    <payElementID>0</payElementID>
    <account>$user_id</account>
    <amount>$payment_sum</amount>
    <terminalId>11352</terminalId>
    </commandCall>},
    result  => q{}
  }
);

test_runner($Payment_plugin, \@requests, { VALIDATE => 'xml_compare' });

1;

