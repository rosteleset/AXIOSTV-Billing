#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use lib '.';
use lib '../../';
use Paysys::t::Init_t;
require Paysys::systems::Click;

our (
  %conf,
  $db,
  $admin,
  $debug,
  $user_id,
  $payment_sum,
  $payment_id
);

my $Payment_plugin = Paysys::systems::Click->new($db, $admin, \%conf);
if ($debug > 3) {
  $Payment_plugin->{DEBUG} = 7;
}

$user_id = $Payment_plugin->{conf}->{PAYSYS_TEST_USER} || 5317;
$payment_id = q{34367923}; # Your active transaction

our @requests = (
  {
    name    => 'PAY',
    request => qq{
click_trans_id=1485296553
service_id=17449
click_paydoc_id=1574969493
merchant_trans_id=$user_id
amount=110000
action=1
sign_time=2021-10-05+20%3A17%3A14
error=0
error_note=Success
merchant_prepare_id=20226190
sign_string=be6b3f7d1e600b37ece603c08f07a566},
    get     => 1,
    result  => qq{}
  },
);

test_runner($Payment_plugin, \@requests, { VALIDATE => 'xml_compare' });

1;

