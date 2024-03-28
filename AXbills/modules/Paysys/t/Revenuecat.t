#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use lib '.';
use lib '../../';
use Paysys::t::Init_t;
use AXbills::Base qw(encode_base64);
require Paysys::systems::Revenuecat;

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

my $Payment_plugin = Paysys::systems::Revenuecat->new($db, $admin, \%conf);
if ($debug > 3) {
  $Payment_plugin->{DEBUG} = 7;
}

$payment_id = int(rand(10000)) + 100000;
$payment_sum = $payment_sum;
$user_id = $argv->{user} || $Payment_plugin->{conf}->{PAYSYS_TEST_USER} || '';

our @requests = (
  {
    name     => 'INITIAL_PURCHASE',
    request  => qq/
{
    "event": {
        "event_timestamp_ms": 1658726378679,
        "product_id": "com.subscription.weekly",
        "period_type": "NORMAL",
        "purchased_at_ms": 1658726374000,
        "expiration_at_ms": 1659331174000,
        "environment": "SANDBOX",
        "entitlement_id": null,
        "entitlement_ids": [
            "pro"
        ],
        "presented_offering_id": null,
        "transaction_id": "1-$payment_id-1",
        "original_transaction_id": "123456789012345",
        "is_family_share": false,
        "country_code": "US",
        "app_user_id": "$user_id",
        "aliases": [
            "\$RCAnonymousID:8069238d6049ce87cc529853916d624c"
        ],
        "original_app_user_id": "\$RCAnonymousID:87c6049c58069238dce29853916d624c",
        "currency": "USD",
        "price": $payment_sum,
        "price_in_purchased_currency": 4.99,
        "subscriber_attributes": {
            "\$email": {
                "updated_at_ms": 1662955084635,
                "value": "firstlast\@gmail.com"
            }
        },
        "store": "APP_STORE",
        "takehome_percentage": 0.7,
        "offer_code": null,
        "type": "INITIAL_PURCHASE",
        "id": "12345678-1234-1234-1234-123456789012",
        "app_id": "1234567890"
    },
    "api_version": "1.0"
}
/,
  },
  {
    name     => 'NON_RENEWING_PURCHASE',
    request  => qq/
{
    "event": {
        "event_timestamp_ms": 1658726522314,
        "product_id": "2100_tokens",
        "period_type": "NORMAL",
        "purchased_at_ms": 1658726519000,
        "expiration_at_ms": null,
        "environment": "SANDBOX",
        "entitlement_id": null,
        "entitlement_ids": [
            "pro"
        ],
        "presented_offering_id": "coins",
        "transaction_id": "2-$payment_id-2",
        "original_transaction_id": "123456789012345",
        "is_family_share": false,
        "country_code": "CA",
        "app_user_id": "$user_id",
        "aliases": [
            "\$RCAnonymousID:8069238d6049ce87cc529853916d624c"
        ],
        "original_app_user_id": "\$RCAnonymousID:87c6049c58069238dce29853916d624c",
        "currency": "CAD",
        "price": $payment_sum,
        "price_in_purchased_currency": 32.99,
        "subscriber_attributes": {
            "\$email": {
                "updated_at_ms": 1662955084635,
                "value": "firstlast\@gmail.com"
            }
        },
        "store": "APP_STORE",
        "takehome_percentage": 0.85,
        "offer_code": null,
        "type": "NON_RENEWING_PURCHASE",
        "id": "12345678-1234-1234-1234-123456789012",
        "app_id": "1234567890"
    },
    "api_version": "1.0"
}
/,
  },
  {
    name     => 'RENEWAL',
    request  => qq/
{
    "event": {
        "event_timestamp_ms": 1658726405017,
        "product_id": "com.subscription.weekly",
        "period_type": "NORMAL",
        "purchased_at_ms": 1658755132000,
        "expiration_at_ms": 1659359932000,
        "environment": "SANDBOX",
        "entitlement_id": null,
        "entitlement_ids": [
            "pro"
        ],
        "presented_offering_id": null,
        "transaction_id": "3-$payment_id-3",
        "original_transaction_id": "123456789012345",
        "is_family_share": false,
        "country_code": "DE",
        "app_user_id": "$user_id",
        "aliases": [
            "\$RCAnonymousID:8069238d6049ce87cc529853916d624c"
        ],
        "original_app_user_id": "\$RCAnonymousID:87c6049c58069238dce29853916d624c",
        "currency": "EUR",
        "is_trial_conversion": false,
        "price": $payment_sum,
        "price_in_purchased_currency": 7.99,
        "subscriber_attributes": {
            "\$email": {
                "updated_at_ms": 1662955084635,
                "value": "firstlast\@gmail.com"
            }
        },
        "store": "APP_STORE",
        "takehome_percentage": 0.7,
        "offer_code": null,
        "type": "RENEWAL",
        "id": "12345678-1234-1234-1234-123456789012",
        "app_id": "1234567890"
    },
    "api_version": "1.0"
}
/,
  },
);

test_runner($Payment_plugin, \@requests);

1;
