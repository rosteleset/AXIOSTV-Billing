#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use lib '.';
use lib '../../';
use Paysys::t::Init_t;
use AXbills::Base qw(encode_base64);
require Paysys::systems::WhitePay;

use Digest::SHA qw(hmac_sha256_hex);

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

my $Payment_plugin = Paysys::systems::WhitePay->new($db, $admin, \%conf);
if ($debug > 3) {
  $Payment_plugin->{DEBUG} = 7;
}

$payment_id = int(rand(10000)) + 100000;
$user_id = $argv->{user} || $Payment_plugin->{conf}->{PAYSYS_TEST_USER} || '';

my $Paysys = Paysys->new($db, $admin, \%conf);
$Paysys->add({
  SYSTEM_ID      => 159,
  SUM            => 1.00,
  UID            => $user_id,
  IP             => '127.0.0.1',
  TRANSACTION_ID => "ADYEN:$payment_id",
  INFO           => 'Test payment',
  PAYSYS_IP      => '127.0.0.1',
  STATUS         => 1,
});

our @requests = (
  {
    name    => 'PAY',
    request =>
qq({
  "order": {
    "id": "08d585b1-86c6-496d-b493-ab17a574fdd6",
    "currency": "UAH",
    "value": $payment_sum,
    "expected_amount": $payment_sum,
    "status": "COMPLETE",
    "external_order_id": "WP:$payment_id",
    "created_at": "2022-03-22 14:01:34",
    "completed_at": "2022-03-27 14:01:34",
    "acquiring_url": "https://merchant.pay.whitepay.org/fiat-order/08d585b1-86c6-496d-b493-ab17a574fdd6"
  }
}),
  },
);

my $secret = $conf{PAYSYS_WP_SECRET} || q{};
my $signature = Digest::SHA::hmac_sha256_hex($requests[0]->{request}, $secret);
$ENV{HTTP_SIGNATURE} = $signature;

test_runner($Payment_plugin, \@requests);

1;
