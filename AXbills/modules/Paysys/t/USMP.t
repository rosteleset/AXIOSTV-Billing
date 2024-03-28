#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use lib '.';
use lib '../../';
use Paysys::t::Init_t;
require Paysys::systems::USMP;

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

my $Payment_plugin = Paysys::systems::USMP->new($db, $admin, \%conf);
$user_id = $argv->{user} || $Payment_plugin->{conf}->{PAYSYS_TEST_USER} || '';
my $transaction_id = int(rand(10000));
my $transaction_start_date = POSIX::strftime('%Y-%m-%d %H:%M:%S', localtime(time - 86400 * 3));
my $transaction_end_date = POSIX::strftime('%Y-%m-%d %H:%M:%S', localtime());
$transaction_end_date =~ s/[-: ]//g;
$transaction_start_date =~ s/[-: ]//g;

if ($debug > 3) {
  $Payment_plugin->{DEBUG}=7;
}

our @requests = (
  {
    name    => 'CHECK',
    request => qq{
QueryType=check
Account=$user_id
TransactionId=$transaction_id},
    get     => 1,
    result  => qq{}
  },
  {
    name    => 'PAY',
    request => qq{
QueryType=pay
Account=$user_id
TransactionDate=$transaction_end_date
TransactionId=$transaction_id
Amount=$payment_sum},
    get     => 1,
    result  => qq{}
  },
  {
    name    => 'CANCEL',
    request => qq{
QueryType=cancel
RevertDate=$transaction_end_date
RevertId=$transaction_id
TransactionId=$transaction_id
time_p=1630059104
Amount=$payment_sum
Account=$user_id},
    get     => 1,
    result  => qq{}
  },
  {
    name    => 'CHECK_PAYMENTS',
    request => qq{
CheckDateBegin=$transaction_start_date
CheckDateEnd=$transaction_end_date},
    get     => 1,
    result  => qq{}
  },
);

test_runner($Payment_plugin, \@requests, { VALIDATE => 'xml_compare' });

1;

