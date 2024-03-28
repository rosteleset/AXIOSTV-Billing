#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use lib '.';
use lib '../../';
use Paysys::t::Init_t;
require Paysys::systems::NovaPay;

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

my $Payment_plugin = Paysys::systems::NovaPay->new($db, $admin, \%conf);
my $Paysys = Paysys->new($db, $admin, \%conf);
$payment_id = int(rand(10000));
$user_id = $argv->{user} || $Payment_plugin->{conf}->{PAYSYS_TEST_USER} || '';
if ($debug > 3) {
  $Payment_plugin->{DEBUG}=7;
}

$Paysys->add({
  SYSTEM_ID      => 153,
  SUM            => 1.00,
  UID            => $user_id,
  IP             => '127.0.0.1',
  TRANSACTION_ID => "NP:$payment_id-0000-0000-0000-$payment_id",
  INFO           => "Test payment",
  PAYSYS_IP      => "127.0.0.1",
  STATUS         => 1,
});

our @requests = (
  {
    name    => 'PAY',
    request => qq/
      {
        "id": "$payment_id-0000-0000-0000-$payment_id",
        "status": "paid",
        "created_at": "2022-10-16T14:22:26.412+00:00",
        "metadata": {
          "uid": 6550
        },
        "client_first_name": "Іван",
        "client_last_name": "Іваненко",
        "client_patronymic": "Іванович",
        "client_phone": "+380665555555",
        "external_id": "NP:$payment_id",
        "pan": "516875xxxx3251",
        "processing_result": "Successful",
        "amount": 1,
        "products": [
          {
            "count": 1,
            "price": 1,
            "description": "Test desc"
          }
        ]
      }
   /,
    result  => q{}
  },
);

test_runner($Payment_plugin, \@requests);

1;
