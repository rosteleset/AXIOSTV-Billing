#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use lib '.';
use lib '../../';
use Paysys::t::Init_t;
require Paysys::systems::Portmone;

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

my $Payment_plugin = Paysys::systems::Portmone->new($db, $admin, \%conf);
$payment_id = int(rand(10000));
$user_id = $argv->{user} || $Payment_plugin->{conf}->{PAYSYS_TEST_USER} || '';
if ($debug > 3) {
  $Payment_plugin->{DEBUG}=7;
}

our @requests = (
  {
    name    => 'PAY',
    request => qq{
data=<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<BILLS>
    <BILL>
        <BANK>
            <NAME>ГУ Ощадбанку м.Київ</NAME>
            <CODE>399999</CODE>
            <ACCOUNT>UA383226690000029243832900000</ACCOUNT>
        </BANK>
        <BILL_ID>966666666</BILL_ID>
        <BILL_NUMBER>$payment_id</BILL_NUMBER>
        <BILL_DATE>2021-07-14</BILL_DATE>
        <BILL_PERIOD>0721</BILL_PERIOD>
        <PAY_DATE>2021-07-14</PAY_DATE>
        <PAYED_AMOUNT>$payment_sum</PAYED_AMOUNT>
        <PAYED_COMMISSION>0.00</PAYED_COMMISSION>
        <PAYED_DEBT>0.00</PAYED_DEBT>
        <AUTH_CODE>TESTPM</AUTH_CODE>
        <PAYER>
            <CONTRACT_NUMBER>$user_id</CONTRACT_NUMBER>
        </PAYER>
        <PAYEE>
            <NAME>COMPANY_NAME</NAME>
            <CODE>30098</CODE>
        </PAYEE>
        <STATUS>PAYED</STATUS>
        <PAY_TIME>16:25:14</PAY_TIME>
        <CARD_MASK>444433******0000</CARD_MASK>
    </BILL>
</BILLS>
},
    result  => q{}
  },
  {
    name    => 'REQUEST',
    request => qq{
data=<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<REQUESTS>
    <PAYEE>30000</PAYEE>
    <PAYER>
        <CONTRACT_NUMBER>$user_id</CONTRACT_NUMBER>
    </PAYER>
</REQUESTS>
},
    result  => q{}
  }
);

test_runner($Payment_plugin, \@requests, { VALIDATE => 'xml_compare' });

1;

