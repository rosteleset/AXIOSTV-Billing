#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use lib '.';
use lib '../../';
use Paysys::t::Init_t;
require Paysys::systems::Easypay_terminal;

our (
  %conf,
  $db,
  $admin,
  $debug,
  $user_id,
  $payment_sum,
  $payment_id
);

my $Payment_plugin = Paysys::systems::Easypay_terminal->new($db, $admin, \%conf);

if ($debug > 3) {
  $Payment_plugin->{DEBUG}=7;
}

my $sign = q{};
my $service_id = q{2431};
my $order_id = q{6223372036854775807};

our @requests = (
  {
    name    => 'GET_USER',
    request => qq{<Request>
  <DateTime>2021-05-21T16:19:50</DateTime>
  <Sign>$sign</Sign>
  <Check>
    <ServiceId>$service_id</ServiceId>
    <Account>54785216</Account>
  </Check>
</Request>
     }
  },
  {
    name    => 'PAY',
    request => qq{<Request>
  <DateTime>2021-05-21T16:19:50</DateTime>
  <Sign>$sign</Sign>
  <Payment>
    <ServiceId>$service_id</ServiceId>
    <OrderId>$order_id</OrderId>
    <Account>54785216</Account>
    <Amount>$payment_sum</Amount>
  </Payment>
</Request>
     }
  },
  {
    name    => 'CONFIRM',
    request => qq{<Request>
  <DateTime>2021-05-21T16:19:50</DateTime>
  <Sign>$sign</Sign>
  <Confirm>
    <ServiceId>$service_id</ServiceId>
    <PaymentId>210</PaymentId>
  </Confirm>
</Request>
     }
  },
  {
    name    => 'CANCEL',
    request => qq{<Request>
  <DateTime>2021-05-21T16:19:50</DateTime>
  <Sign>$sign</Sign>
  <Cancel>
    <ServiceId>$service_id</ServiceId>
    <PaymentId>210</PaymentId>
  </Cancel>
</Request>
     }
  },
);

test_runner($Payment_plugin, \@requests, { VALIDATE => 'xml_compare' });

1;

