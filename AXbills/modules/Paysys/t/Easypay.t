#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use lib '.';
use lib '../../';
use Paysys::t::Init_t;

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

require Paysys::systems::Easypay;
my $Payment_plugin = Paysys::systems::Easypay->new($db, $admin, \%conf);
if ($debug > 3) {
  $Payment_plugin->{DEBUG}=7;
}

$user_id = $argv->{user} || $Payment_plugin->{conf}->{PAYSYS_TEST_USER} || q{};
my $sign = q{};
my $service_id = $conf{PAYSYS_EASYPAY_SERVICE_ID} || q{2431};
my $order_id = int(rand(1000000000));
my $date = $main::DATE . 'T' . $main::TIME;

our @requests = (
  {
    name    => 'GET_USER',
    request => qq{<Request>
  <DateTime>$date</DateTime>
  <Sign>$sign</Sign>
  <Check>
    <ServiceId>$service_id</ServiceId>
    <Account>$user_id</Account>
  </Check>
</Request>
     }
  },
  {
    name    => 'PAY',
    request => qq{<Request>
  <DateTime>$date</DateTime>
  <Sign>$sign</Sign>
  <Payment>
    <ServiceId>$service_id</ServiceId>
    <OrderId>$order_id</OrderId>
    <Account>$user_id</Account>
    <Amount>$payment_sum</Amount>
  </Payment>
</Request>
     }
  },
  {
    name    => 'CONFIRM',
    request => qq{<Request>
  <DateTime>$date</DateTime>
  <Sign>$sign</Sign>
  <Confirm>
    <ServiceId>$service_id</ServiceId>
    <PaymentId></PaymentId>
  </Confirm>
</Request>
     }
  },
  {
    name    => 'CANCEL',
    request => qq{<Request>
  <DateTime>$date</DateTime>
  <Sign>$sign</Sign>
  <Cancel>
    <ServiceId>$service_id</ServiceId>
    <PaymentId></PaymentId>
  </Cancel>
</Request>
     }
  },
  # {
  #   name    => 'MERCH_PAY',
  # request => qq{{
  #   "action": "payment",
  #   "merchant_id": 5347,
  #   "order_id": "5",
  #   "version": "v3.0",
  #   "date": "2019-06-19T15:38:10.7802613+03:00",
  #   "details": {
  #     "amount": 1.00,
  #     "desc": "Wooden tables x 10",
  #     "payment_id": 724502946,
  #     "recurrent_id": null
  #   },
  #   "additionalitems": {
  #     "BankName": "CB PRIVATBANK",
  #     "Card.Pan": "414962******6660",
  #     "MerchantKey": "easypay.ua",
  #     "Merchant.OrderId": "5"
  #   }
  # }}
  # },
  # {
  #   name    => 'MERCH_REFUND',
  #   request => qq{{
  #   "action": "refund",
  #   "merchant_id": 5347,
  #   "order_id": "5",
  #   "version": "v3.0",
  #   "date": "2019-06-19T15:38:10.7802613+03:00",
  #   "details": {
  #     "amount": 1.00,
  #     "desc": "Wooden tables x 10",
  #     "payment_id": 724502946,
  #     "recurrent_id": null
  #   },
  #   "additionalitems": {
  #     "BankName": "CB PRIVATBANK",
  #     "Card.Pan": "414962******6660",
  #     "MerchantKey": "easypay.ua",
  #     "Merchant.OrderId": "5"
  #   }
  # }}
  # },
);

test_runner($Payment_plugin, \@requests, { VALIDATE => 'xml_compare' });

1;

