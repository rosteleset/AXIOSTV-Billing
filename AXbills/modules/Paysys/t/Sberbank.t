#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use lib '.';
use lib '../../';
use Paysys::t::Init_t;
use Paysys;
require Paysys::systems::Sberbank;

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

my $Paysys = Paysys->new($db, $admin, \%conf);
my $Payment_plugin = Paysys::systems::Sberbank->new($db, $admin, \%conf);
if ($debug > 3) {
  $Payment_plugin->{DEBUG}=7;
}

$payment_id = int(rand(10000));
$user_id = $argv->{user} || $Payment_plugin->{conf}->{PAYSYS_TEST_USER} || '';

$Paysys->add({
  SYSTEM_ID      => 127,
  SUM            => $payment_sum,
  UID            => $user_id,
  IP             => $ENV{'REMOTE_ADDR'},
  TRANSACTION_ID => "SB:$payment_id",
  STATUS         => 1,
});

our @requests = (
  {
    name    => 'PAY',
    request => qq{
mdOrder=881ed8c1-32c8-7cca-ac24-a84401f18538
status=1
orderNumber=$payment_id
operation=deposited},
    get     => 1,
    result  => qq{}
  },
);

test_runner($Payment_plugin, \@requests, { VALIDATE => 'xml_compare' });

1;

