#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use lib '.';
use lib '../../';
use Paysys::t::Init_t;
require Paysys::systems::Monobank;

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

my $Payment_plugin = Paysys::systems::Monobank->new($db, $admin, \%conf);
my $Paysys = Paysys->new($db, $admin, \%conf);
$payment_id = int(rand(10000));
$user_id = $argv->{user} || $Payment_plugin->{conf}->{PAYSYS_TEST_USER} || '';
if ($debug > 3) {
  $Payment_plugin->{DEBUG}=7;
}

$Paysys->add({
  SYSTEM_ID      => 154,
  SUM            => 1.00,
  UID            => $user_id,
  IP             => '127.0.0.1',
  TRANSACTION_ID => "MONO:$payment_id",
  INFO           => "Test payment",
  PAYSYS_IP      => "127.0.0.1",
  STATUS         => 1,
});

our @requests = (
  {
    name    => 'PAY',
    request => qq/
      {
        "invoiceId":"7HRwarbyQTcZ",
        "status":"success",
        "amount":100,
        "ccy":980,
        "finalAmount":100,
        "createdDate":"2022-04-19T13:54:28Z",
        "modifiedDate":"2022-04-19T13:54:45Z",
        "reference":"MONO:$payment_id",
        "cancelList":null
      }
   /,
    result  => q{}
  },
);

test_runner($Payment_plugin, \@requests);

1;
