#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
plan tests => 6;

our ($db, $admin, %conf);

if (use_ok ('AXbills::Backend::API')) {
  require AXbills::Backend::API;
  AXbills::Backend::API->import()
};

my AXbills::Backend::API $api = new_ok('AXbills::Backend::API', [ $db, $admin, \%conf ]);

SKIP :{
  skip("Can't connect to Internal server", 4) unless ($api->is_connected);

  # Check we have 1 admin connected
  my $is_admin_connected = $api->is_admin_connected(1);
  skip("No test admin online", 4) unless $is_admin_connected;

  ok($is_admin_connected, "Have admin 1 online");
  # Try to ping admin 1
  ok($api->call(1, '{"TYPE":"PING"}'), 'Ping admin 1');

  ok(!$api->is_admin_connected(2), "Admin 2 should not be online");

  # Try intensive ping
  for (1 ... 100) {
    $api->is_admin_connected(1);
  }
  ok(1, "Alive after 100 pings");

}
done_testing();

1;