#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use lib '.';
use lib '../../';
use Paysys::t::Init_t;
require Paysys::systems::Rncb;

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

my $Payment_plugin = Paysys::systems::Rncb->new($db, $admin, \%conf);
if ($debug > 3) {
  $Payment_plugin->{DEBUG}=7;
}

$user_id = $argv->{user} || $Payment_plugin->{conf}->{PAYSYS_TEST_USER} || q{};
$payment_id = int(rand(10000));
my $start_date = POSIX::strftime('%Y%m%d%H%M%S', localtime(time - 86400 * 3));
my $end_date = POSIX::strftime('%Y%m%d%H%M%S', localtime());

our @requests = (
  {
    name    => 'CHECK',
    request => qq{
QueryType=check
Account=$user_id},
    get     => 1,
    result  => qq{<?xml version="1.0" encoding="UTF-8"?>
        <CHECKRESPONSE>
        <BALANCE>.+</BALANCE>
        <FIO>.+</FIO>
        <ADDRESS>.+</ADDRESS>
        <ERROR>0</ERROR>
        <COMMENTS>Success</COMMENTS>
      </CHECKRESPONSE>}
  },
  {
    name    => 'PAY',
    request => qq{
QueryType=pay
Account=$user_id
Summa=$payment_sum
Payment_id=$payment_id},
    get     => 1,
    result  => q{}
  },
  {
    name => 'CHECK_BALANCE',
    request => qq{
QueryType=balance
Date_to=$start_date
Date_from=$end_date},
    get     => 1,
    result  => q{}
  }
);

test_runner($Payment_plugin, \@requests, { VALIDATE => 'xml_compare' });

1;

