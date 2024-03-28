#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use lib '.';
use lib '../../';
use Paysys::t::Init_t;
require Paysys::systems::24_non_stop;

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

my $Payment_plugin = Paysys::systems::24_non_stop->new($db, $admin, \%conf);
if ($debug > 3) {
  $Payment_plugin->{DEBUG} = 7;
}

$payment_id = int(rand(10000));
$user_id = $argv->{user} || $Payment_plugin->{conf}->{PAYSYS_TEST_USER} || '';

my $sign_check = $Payment_plugin->mk_checksum({
  ACT         => 1,
  PAY_ACCOUNT => $user_id,
  SERVICE_ID  => "Internet",
  PAY_ID      => $payment_id,
});

my $sign_pay = $Payment_plugin->mk_checksum({
  ACT         => 4,
  PAY_ACCOUNT => $user_id,
  SERVICE_ID  => "Internet",
  PAY_ID      => $payment_id,
  PAY_AMOUNT  => $payment_sum,
});

my $sign_confirm = $Payment_plugin->mk_checksum({
  ACT        => 7,
  SERVICE_ID => "Internet",
  PAY_ID     => $payment_id,
});

my $receip_num = '1846427660';

our @requests = (
  {
    name    => 'CHECK',
    request => qq{
ACT=1
SERVICE_ID=Internet
PAY_ACCOUNT=$user_id
PAY_ID=$payment_id
TRADE_POINT=7523
SIGN=$sign_check
},
    get     => 1,
    result  => qq{}
  },
  {
    name    => 'PAY',
    request => qq{
ACT=4
PAY_AMOUNT=$payment_sum
RECEIPT_NUM=$receip_num
SERVICE_ID=Internet
PAY_ACCOUNT=$user_id
PAY_ID=$payment_id
TRADE_POINT=7523
SIGN=$sign_pay
},
    get     => 1,
    result  => qq{}
  },
  {
    name    => 'CONFIRM',
    request => qq{
ACT=7
SERVICE_ID=Internet
PAY_ID=$payment_id
SIGN=$sign_confirm
},
    get     => 1,
    result  => qq{}
  },
);

test_runner($Payment_plugin, \@requests, { VALIDATE => 'xml_compare' });

1;
