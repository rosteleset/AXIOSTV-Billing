#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use lib '.';
use lib '../../';
use Paysys::t::Init_t;
require Paysys::systems::Walletone;

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

my $Payment_plugin = Paysys::systems::Walletone->new($db, $admin, \%conf);
if ($debug > 3) {
  $Payment_plugin->{DEBUG}=7;
}

$user_id = $argv->{user} || $Payment_plugin->{conf}->{PAYSYS_TEST_USER} || '';
$payment_id = int(rand(10000));

our @requests = (
  {
    name    => 'PAY',
    request => qq{WMI_SIGNATURE=
WMI_ORDER_STATE=Accepted
UID=$user_id
WMI_PAYMENT_AMOUNT=1
WMI_PAYMENT_NO=$payment_id
WMI_ORDER_ID=$payment_id},
    get     => 1,
    result  => qq{}
  },
);

test_runner($Payment_plugin, \@requests, { VALIDATE => 'xml_compare' });

1;

