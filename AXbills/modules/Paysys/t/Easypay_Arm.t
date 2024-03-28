#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use lib '.';
use lib '../../';
use Paysys::t::Init_t;
require Paysys::systems::Easypay_Arm;

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

my $Payment_plugin = Paysys::systems::Easypay_Arm->new($db, $admin, \%conf);
$payment_id = int(rand(10000));
$user_id = $argv->{user} || $Payment_plugin->{conf}->{PAYSYS_TEST_USER} || '';
if ($debug > 3) {
  $Payment_plugin->{DEBUG}=7;
}

my $sign_check = $Payment_plugin->mk_checksum({
  Inputs   => [ $user_id, "", "", "" ],
  Currency => 'AMD',
  Lang     => 'hy'
});

my $sign_pay = $Payment_plugin->mk_checksum({
  Inputs     => [ $user_id, "", "", "" ],
  Currency   => 'AMD',
  TransactID => $payment_id,
  Amount     => $payment_sum
});


our @requests = (
  {
    name    => 'CHECK',
    request => qq/
{
"Checksum":"$sign_check",
"Inputs":["$user_id","","",""],
"Currency":"AMD",
"Lang":"hy"
}
   /,
    result  => q{}
  },
  {
    name    => 'PAY',
    request => qq/
{
"Inputs":["$user_id","","",""],
"Amount":$payment_sum,
"TransactID":"$payment_id",
"Currency": "AMD",
"Checksum":"$sign_pay",
"DtTime":"2017-06-23T16:06:56"
}
   /,
    result  => q{}
  },
);

test_runner($Payment_plugin, \@requests);

1;
