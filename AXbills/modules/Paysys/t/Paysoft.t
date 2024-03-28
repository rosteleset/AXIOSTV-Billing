#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use lib '.';
use lib '../../';
use Paysys::t::Init_t;
require Paysys::systems::Paysoft;

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

my $Payment_plugin = Paysys::systems::Paysoft->new($db, $admin, \%conf);
if ($debug > 3) {
  $Payment_plugin->{DEBUG}=7;
}

$user_id = $argv->{user} || $Payment_plugin->{conf}->{PAYSYS_TEST_USER} || '';
$payment_id = int(rand(10000));

my %FORM = (
  LMI_MERCHANT_ID      => '1234',
  LMI_PAYMENT_NO       => $payment_id,
  LMI_SYS_PAYMENT_ID   => $payment_id,
  LMI_SYS_PAYMENT_DATE => '2021-07-26 12:35:02',
  LMI_PAYMENT_AMOUNT   => $payment_sum,
  LMI_PAID_AMOUNT      => $payment_sum,
  LMI_PAYMENT_SYSTEM   => '21',
  LMI_MODE             => '0',
);

my $signature = $Payment_plugin->mk_sign(\%FORM);

our @requests = (
  {
    name    => 'PAY',
    request => qq{sid=r1gmQ2ibQXiTpxJn
IP=77.75.147.128
UID=$user_id
LMI_PAID_AMOUNT=$payment_sum
LMI_ACQUIRER_ID=33
LMI_PAYMENT_DESC=Login: beloshickiyan, UID: 54785216
LMI_MERCHANT_ID=1234
LMI_RRN=
LMI_PAYMENT_NO=$payment_id
LMI_RESULT_URL=https://bill.ultranetgroup.com.ua:443/paysys_check.cgi
at=
LMI_PAYMENT_SYSTEM=21
LMI_PAYER_IDENTIFIER=438146******1239
LMI_RECEIPT_TOKEN=4e7ce987710e2f303a50c33b80967c338401d64e0c8551a414f0ad2151a8570f
LMI_SYS_PAYMENT_ID=$payment_id
LMI_PAYMENT_AMOUNT=$payment_sum
index=53
LMI_PAYER_PHONE_NUMBER=
LMI_SYS_PAYMENT_DATE=2021-07-26 12:35:02
LMI_HASH=$signature
LMI_MODE=0
LMI_PAYER_EMAIL=
LMI_PAYER_IP=},
    get     => 1,
    result  => qq{}
  },
#   {
#     name    => 'PREREQUEST',
#     request => qq{LMI_PAYMENT_AMOUNT=$payment_sum
# UID=$user_id
# LMI_RESULT_URL=https://bill.ultranetgroup.com.ua:443/paysys_check.cgi
# LMI_PAYMENT_SYSTEM=21
# LMI_PREREQUEST=1
# index=53
# at=
# LMI_PAYMENT_NO=61602223
# LMI_PAYER_PHONE_NUMBER=
# IP=77.75.147.128
# LMI_PAYMENT_DESC=Login: ivanov, UID: $user_id
# LMI_MERCHANT_ID=3762
# LMI_PAYER_EMAIL=
# LMI_MODE=0
# sid=NpdnEExgPScHygDa},
#     get     => 1,
#     result  => qq{}
#   },
);

test_runner($Payment_plugin, \@requests, { VALIDATE => 'xml_compare' });

1;

