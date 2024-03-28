#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use lib '.';
use lib '../../';
use Paysys::t::Init_t;
require Paysys::systems::Xpay;

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

my $Payment_plugin = Paysys::systems::Xpay->new($db, $admin, \%conf);
$user_id = $argv->{user} || $Payment_plugin->{conf}->{PAYSYS_TEST_USER} || '';
my $transaction_id = int(rand(10000));
my $transaction_date = POSIX::strftime('%Y-%m-%d %H:%M:%S', localtime());
$transaction_date =~ s/[-: ]//g;
$payment_sum = $payment_sum * 100;

if ($debug > 3) {
  $Payment_plugin->{DEBUG} = 7;
}

#TODO: add of creation signature

our @requests = (
  {
    name    => 'CHECK',
    request => qq{
command=check
txn_id=$transaction_id
amount=$payment_sum
account=$user_id},
    get     => 1,
    result  => qq{}
  },
  {
    name    => 'PAY',
    request => qq{
command=pay
account=$user_id
txn_date=$transaction_date
txn_id=$transaction_id
txn_id_own=$transaction_id
sum=$payment_sum},
    get     => 1,
    result  => qq{}
  },
  {
    name    => 'ERROR',
    request => qq{
command=error
account=$user_id
txn_date=$transaction_date
txn_id=$transaction_id
txn_id_own=$transaction_id
sum=$payment_sum},
    get     => 1,
    result  => qq{}
  },
  {
    name    => 'REFUND',
    request => qq{
command=refund
txn_id=$transaction_id
partner_txn_id=$transaction_id},
    get     => 1,
    result  => qq{}
  },
);

test_runner($Payment_plugin, \@requests, { VALIDATE => 'xml_compare' });

1;
