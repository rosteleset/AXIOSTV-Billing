#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use lib '.';
use lib '../../';
use Paysys::t::Init_t;
require Paysys::systems::Fcsystem;

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

my $Payment_plugin = Paysys::systems::Fcsystem->new($db, $admin, \%conf);
if ($debug > 3) {
  $Payment_plugin->{DEBUG} = 7;
}

$payment_id = int(rand(10000));
$user_id = $argv->{user} || $Payment_plugin->{conf}->{PAYSYS_TEST_USER} || '';

our @requests = (
  {
    name    => 'CHECK',
    request => qq{
cmd=check
merchantid=fcsistema
id=$payment_id},
    get     => 1,
    result  => qq{}
  },
  {
    name    => 'PAY',
    request => qq{
cmd=pay
merchantid=fcsistema
account=$user_id
sum=$payment_sum
id=$payment_id},
    get     => 1,
    result  => qq{}
  },
  {
    name    => 'CANCEL',
    request => qq{
cmd=cancel
merchantid=fcsistema
id=$payment_id
providerid=25478
account=$user_id
sum=$payment_sum},
    get     => 1,
    result  => qq{}
  },
  {
    name    => 'VERIFY',
    request => qq{
cmd=verify
merchantid=fcsistema
account=$user_id
id_project=222},
    get     => 1,
    result  => qq{}
  }
);

test_runner($Payment_plugin, \@requests, { VALIDATE => 'xml_compare' });

1;

