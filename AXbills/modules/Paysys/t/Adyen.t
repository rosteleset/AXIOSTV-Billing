#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use lib '.';
use lib '../../';
use Paysys::t::Init_t;
require Paysys::systems::Adyen;

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

my $Payment_plugin = Paysys::systems::Adyen->new($db, $admin, \%conf);
my $Paysys = Paysys->new($db, $admin, \%conf);
$payment_id = int(rand(10000));
$user_id = $argv->{user} || $Payment_plugin->{conf}->{PAYSYS_TEST_USER} || '';
if ($debug > 3) {
  $Payment_plugin->{DEBUG}=7;
}

$Paysys->add({
  SYSTEM_ID      => 159,
  SUM            => 1.00,
  UID            => $user_id,
  IP             => '127.0.0.1',
  TRANSACTION_ID => "ADYEN:$payment_id",
  INFO           => "Test payment",
  PAYSYS_IP      => "127.0.0.1",
  STATUS         => 1,
});

our @requests = (
  {
    name    => 'PAY',
    request => qq/
      {
  "live": "false",
  "notificationItems": [
    {
      "NotificationRequestItem": {
        "additionalData": {
          "paymentLinkId": "PL8CBA12FA51390D01"
        },
        "amount": {
          "currency": "PLN",
          "value": 100
        },
        "eventCode": "AUTHORISATION",
        "eventDate": "2022-08-13T15:56:43+02:00",
        "merchantAccountCode": "ABillSECOM",
        "merchantReference": "ADYEN:$payment_id",
        "paymentMethod": "dotpay",
        "pspReference": "XL32LLKZTP4WHD82",
        "reason": "null",
        "success": "true"
      }
    }
  ]
}
   /,
    result  => q{}
  },
);

test_runner($Payment_plugin, \@requests);

1;
