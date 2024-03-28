#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use lib '.';
use lib '../../';
use Paysys::t::Init_t;
require Paysys::systems::Ipay;

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

my $Payment_plugin = Paysys::systems::Ipay->new($db, $admin, \%conf);
$Payment_plugin->{TEST}=1;
if ($debug > 3) {
  $Payment_plugin->{DEBUG}=7;
}

$payment_id = int(rand(10000));
$payment_sum = int($payment_sum * 100);

our @requests = (
  {
    name    => 'GET_USER',
    request => qq{xml=<?xml version="1.0" encoding="utf-8"?><check>
          <mch_id>3152312312</mch_id>
    <srv_id>0</srv_id>
          <pay_account>$user_id</pay_account>
    <salt>21321412315123vqweweb</salt>
          <sign>3124iuvy1oivio13</sign>
    </check>},
    result  => qq{}
  },
   {
     name    => 'PAY',
     request => qq{xml=<?xml version="1.0" encoding="utf-8"?>
<payment id="$payment_id">
<ident>520edda7b4e6e20482a30c85c44a1e56d8e8a666</ident>
<status>5</status>
<amount>$payment_sum</amount>
<currency>UAH</currency>
<timestamp>1312201619</timestamp>
<transactions>
<transaction id="431">
<mch_id>7</mch_id>
<srv_id>1</srv_id>
<amount>5077</amount>
<currency>UAH</currency>
<type>10</type>
<status>11</status>
<code>00</code>
<desc>Оплата услуг</desc>
<info>{\"UID\":$user_id, \"amount\": $payment_sum, \"OPERATION_ID\": \"09408753\"}</info>
</transaction>
<transaction id="432">
<mch_id>7</mch_id>
<srv_id>1</srv_id>
<amount>5077</amount>
<currency>UAH</currency>
<type>11</type>
<status>11</status>
<code>00</code>
<desc>Оплата услуг</desc>
<info>{\"UID\":$user_id, \"amount\": $payment_sum, \"OPERATION_ID\": \"09408753\"}</info>
</transaction>
</transactions>
<salt>4bd31cc81bf4a882ec19b3f4a2df9a8b1dd4694b</salt>
<sign>78f1022cb8ffbdcfa0997a5e72…0f324424eb4d2fbffcf21c7426bafe0</sign>
</payment>},
     result  => q{}
   }
);

test_runner($Payment_plugin, \@requests, { VALIDATE => 'xml_compare' });

1;

