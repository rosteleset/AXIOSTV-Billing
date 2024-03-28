#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use lib '.';
use lib '../../';
use Paysys::t::Init_t;
require Paysys::systems::Platon;

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

my $Payment_plugin = Paysys::systems::Platon->new($db, $admin, \%conf);
$payment_id = int(rand(10000));
$user_id = $argv->{user} || $Payment_plugin->{conf}->{PAYSYS_TEST_USER} || '';

if ($debug > 3) {
  $Payment_plugin->{DEBUG}=7;
}

my $sign_pay = $Payment_plugin->mk_sign({
  email => 'test@gmail',
  order => $payment_id,
  card  => '44445555****1111',
});

our @requests = (
  {
    name    => 'PAY',
    request => qq{
ip=127.0.0.1
id=12345-12345-12345
amount=$payment_sum
sign=$sign_pay
status=SALE
date=2022-11-01T00:00:00
rrn=123456789123
card=44445555****1111
order=$payment_id
cardholder_email=test\@gmail
email=test\@gmail
description=Test
currency=UAH
approval_code=12345Q
ext1=$user_id
},
    get     => 1,
    result  => q{}
  },
);

test_runner($Payment_plugin, \@requests);

1;
