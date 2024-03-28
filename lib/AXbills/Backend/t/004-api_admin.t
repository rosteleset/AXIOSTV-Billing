#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 7;

use lib '../../../';

use AXbills::Base qw(parse_arguments);

our %conf;
my $ARGS = parse_arguments(\@ARGV);

my $test_admin = $ARGS->{admin} || 1;

if (use_ok('AXbills::Backend::API')) {
  require AXbills::Backend::API;
  AXbills::Backend::API->import()
}

my AXbills::Backend::API $api = new_ok('AXbills::Backend::API', [ \%conf ]);

SKIP :{
  skip("Can't connect to Internal server", 4) unless ($api->is_connected);

  # Check we have 1 admin connected
  my $is_admin_connected = $api->is_receiver_connected($test_admin, 'ADMIN');
  skip("No test admin online", 5) unless $is_admin_connected;

  ok($is_admin_connected, "Have admin 1 online");
  # Try to ping admin 1
  ok($api->call($test_admin, '{"TYPE":"PING"}'), 'Ping admin 1');

  ok(!$api->is_receiver_connected(1000000, 'ADMIN'), "Admin 1000000 should not be online");

  # Try intensive ping
  for (1 ... 100) {
    $api->is_receiver_connected(1, 'ADMIN');
  }
  ok($test_admin, "Alive after 100 pings");

  # Try intensive ping
  for (1 ... 100) {
    $api->is_receiver_connected(1, 'ADMIN');
  }

  ok($api->call($test_admin, '{"TYPE":"MESSAGE", "TITLE": "TEST TITLE", "TEXT": "TEST TEXT BODY"}'), "Sent test message to admin");
}

done_testing();

1;
