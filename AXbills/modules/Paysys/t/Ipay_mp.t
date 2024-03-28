#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use lib '.';
use lib '../../';
use Paysys::t::Init_t;
require Paysys::systems::Ipay_mp;

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

my $Payment_plugin = Paysys::systems::Ipay_mp->new($db, $admin, \%conf);
$Payment_plugin->{TEST}=1;
if ($debug > 3) {
  $Payment_plugin->{DEBUG}=7;
}

$payment_sum = int($payment_sum * 100);

our @requests = (
  {
    name    => 'PAY',
    request => qq{<?xml version="1.0" encoding="utf-8"?>
<payment id="107384240">
  <ident>941a161bdf0d6208a820e4004bc5d2afecdb3efe</ident>
  <status>5</status>
  <amount>500</amount>
  <currency>UAH</currency>
  <timestamp>1631099870</timestamp>
  <transactions>
    <transaction id="211818073">
      <mch_id>3151</mch_id>
      <srv_id>0</srv_id>
      <amount>500</amount>
      <currency>UAH</currency>
      <type>20</type>
      <status>11</status>
      <code>00</code>
      <desc>Login: 22116, Transaction: 30066425, UID: 42365</desc>
      <info>[]</info>
    </transaction>
    <transaction id="211818073">
      <mch_id>3151</mch_id>
      <srv_id>0</srv_id>
      <amount>500</amount>
      <currency>UAH</currency>
      <type>21</type>
      <status>11</status>
      <code>00</code>
      <desc>Login: 22116, Transaction: 30066425, UID: 42365</desc>
      <info>[]</info>
    </transaction>
  </transactions>
  <settlements>
    <settlement>
      <smch_id>7626</smch_id>
      <invoice>500</invoice>
      <fee>0</fee>
      <amount>500</amount>
    </settlement>
  </settlements>
  <salt>bfe63b5d97b5c7903b8a9fdb7bab65b9e10d04cc</salt>
  <sign>52096b12a7b537ea9b7fa90513d5d71c5724eda3a3ef70d52906c2b12ad619433655b72804690912f02a0107ae05e4dcdaa5e9bee9ad572431d496c4b7ca9ca2</sign>
</payment>},
    result  => q{}
  },
    {
      name    => 'check',
      request => qq{xml=<?xml version="1.0" encoding="utf-8"?><check><mch_id>dfcbc8b24aef69c676ed9bff3df3d503b9d15445</mch_id><srv_id>0</srv_id><pay_account>10061</pay_account></check>},
      result  => q{}
    }
);

test_runner($Payment_plugin, \@requests, { VALIDATE => 'xml_compare' });

1;
