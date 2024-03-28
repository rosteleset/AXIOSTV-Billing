#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use lib '.';
use lib '../../';
use Paysys::t::Init_t;
require Paysys::systems::Robokassa;

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

my $Payment_plugin = Paysys::systems::Robokassa->new($db, $admin, \%conf);
if ($debug > 3) {
  $Payment_plugin->{DEBUG} = 7;
}

$payment_id = int(rand(10000));
$user_id = $argv->{user} || $Payment_plugin->{conf}->{PAYSYS_TEST_USER} || q{};

my %FORM = (
  shp_Id         => $user_id,
  OutSum         => $payment_sum,
  InvId          => $payment_id,
  SignatureValue => '',
);

my $signature = $Payment_plugin->mk_sign(\%FORM);

our @requests = (
  {
    name    => 'PAY',
    request => qq{
shp_Id=$user_id
OutSum=$payment_sum
InvId=$payment_id
SignatureValue=$signature},
    get     => 1,
    result  => qq{}
  },
);

test_runner($Payment_plugin, \@requests, { VALIDATE => 'xml_compare' });

1;

