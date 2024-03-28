#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use lib '.';
use lib '../../';
use Paysys::t::Init_t;
require Paysys::systems::Paymasterru;

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

my $Payment_plugin = Paysys::systems::Paymasterru->new($db, $admin, \%conf);
if ($debug > 3) {
  $Payment_plugin->{DEBUG} = 7;
}

$user_id = $argv->{user} || $Payment_plugin->{conf}->{PAYSYS_TEST_USER} || '';
$payment_id = int(rand(10000));

my %FORM = (
  LMI_MERCHANT_ID      => '085415af-10dd-4654-9a56-1f98836dfc30',
  LMI_PAYMENT_NO       => $payment_id,
  LMI_SYS_PAYMENT_ID   => $payment_id,
  LMI_PAYMENT_AMOUNT   => $payment_sum,
  LMI_PAID_AMOUNT      => $payment_sum,
  LMI_PAYMENT_SYSTEM   => '165',
  LMI_SYS_PAYMENT_DATE => '2021-09-01T05:57:51',
  LMI_PAID_CURRENCY    => 'RUB',
  LMI_CURRENCY         => 'RUB',
  LMI_HASH             => ''
);

my $signature = $Payment_plugin->mk_sign(\%FORM);

our @requests = (
  {
    name    => 'PAY',
    get     => 1,
    request => qq{LMI_PAYMENT_NO=$payment_id
LMI_SYS_PAYMENT_ID=$payment_id
LMI_PAYMENT_AMOUNT=$payment_sum
LMI_PAYMENT_DESC=Internet
LMI_PAID_CURRENCY=RUB
LMI_CURRENCY=RUB
LMI_PAID_AMOUNT=$payment_sum
LMI_SYS_PAYMENT_DATE=2021-09-01T05:57:51
LMI_PAYMENT_METHOD=BankCard
LMI_HASH=$signature
LMI_PAYER_IDENTIFIER=521324XXXXXX7147
LMI_SHOP_ID=200000000025260/200038961/503655
LMI_PAYER_IP_ADDRESS=95.153.135.20
LMI_MERCHANT_ID=085415af-10dd-4654-9a56-1f98836dfc30
LMI_PAYMENT_SYSTEM=165
USER=$user_id
},
    result  => q{},
  },
  {
    name    => 'PREREQUEST',
    get     => 1,
    request => qq{LMI_MERCHANT_ID=085415af-10dd-4654-9a56-1f98836dfc30
LMI_PAYMENT_SYSTEM=165
LMI_PREREQUEST=1
LMI_PAYMENT_DESC=Internet
LMI_PAYMENT_NO=$payment_id
LMI_CURRENCY=RUB
LMI_SHOP_ID=1
LMI_PAID_AMOUNT=$payment_sum
LMI_PAID_CURRENCY=RUB
LMI_PAYMENT_METHOD=BankCard
LMI_PAYMENT_AMOUNT=$payment_sum
USER=$user_id
},
    result  => q{},
  }
);

test_runner($Payment_plugin, \@requests, { VALIDATE => 'xml_compare' });

1;