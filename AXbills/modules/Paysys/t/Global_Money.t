#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use lib '.';
use lib '../../';
use Paysys::t::Init_t;

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

require Paysys::systems::Global_Money;
my $Payment_plugin = Paysys::systems::Global_Money->new($db, $admin, \%conf);
if ($debug > 3) {
  $Payment_plugin->{DEBUG}=7;
}

$user_id = $argv->{user} || $Payment_plugin->{conf}->{PAYSYS_TEST_USER} || q{};
my $sign = q{};
my $service_id = q{2431};
my $order_id = int(rand(1000000000));
my $date = $main::DATE . 'T' . $main::TIME;

our @requests = (
  {
    name    => 'GET_USER',
    request => qq{<Request>
  <DateTime>$date</DateTime>
  <Sign>$sign</Sign>
  <Check>
    <ServiceId>$service_id</ServiceId>
    <Account>$user_id</Account>
  </Check>
</Request>
     }
  },
  {
    name    => 'PAY',
    request => qq{<Request>
  <DateTime>$date</DateTime>
  <Sign>$sign</Sign>
  <Payment>
    <ServiceId>$service_id</ServiceId>
    <OrderId>$order_id</OrderId>
    <Account>$user_id</Account>
    <Amount>$payment_sum</Amount>
  </Payment>
</Request>
     }
  },
  {
    name    => 'CONFIRM',
    request => qq{<Request>
  <DateTime>$date</DateTime>
  <Sign>$sign</Sign>
  <Confirm>
    <ServiceId>$service_id</ServiceId>
    <PaymentId></PaymentId>
  </Confirm>
</Request>
     }
  },
  {
    name    => 'CANCEL',
    request => qq{<Request>
  <DateTime>$date</DateTime>
  <Sign>$sign</Sign>
  <Cancel>
    <ServiceId>$service_id</ServiceId>
    <PaymentId></PaymentId>
  </Cancel>
</Request>
     }
  },
  {
    name    => 'BALANCE',
    request => qq{<Request>
  <DateTime>$date</DateTime>
  <Sign>$sign</Sign>
  <Balance />
</Request>
     }
  },
);

test_runner($Payment_plugin, \@requests, { VALIDATE => 'xml_compare' });

1;

