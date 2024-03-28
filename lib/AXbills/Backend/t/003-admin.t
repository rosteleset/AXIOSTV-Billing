#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2;

use lib '../../../';

if (use_ok ('AXbills::Backend::Plugin::Websocket::Admin')) {
  require AXbills::Backend::Plugin::Websocket::Admin;
  AXbills::Backend::API->import()
}

my $test_aid = 1;
my $test_chunk = qq{
Cookie: sid=testadmin1
};

my $authentication = AXbills::Backend::Plugin::Websocket::Admin::authenticate($test_chunk);
ok($authentication == $test_aid, "Authenticated $test_aid as aid : $authentication");

done_testing();
