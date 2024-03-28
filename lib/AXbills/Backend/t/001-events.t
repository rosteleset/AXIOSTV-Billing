#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 10;

use_ok('AXbills::Backend::PubSub');
my $Pub = new_ok('AXbills::Backend::PubSub');

my $success_callback = sub {
  ok(1, shift);
};

my $test_topic = 'test_topic';

# Test on
$Pub->on($test_topic, $success_callback);
$Pub->emit($test_topic, 'Test on()');

# Test remove all
$Pub->off($test_topic);
ok(!scalar @{$Pub->{topics}->{$test_topic}}, 'Removed all topics');

# Set again
$Pub->on($test_topic, sub {});
$Pub->on($test_topic, $success_callback);
$Pub->on($test_topic, $success_callback);

$Pub->emit($test_topic, 'Test remove two handlers');
$Pub->off($test_topic, $success_callback);
ok(scalar @{$Pub->{topics}->{$test_topic}} == 1, 'Removed all topics exept another');

# Clearing
$Pub->off($test_topic);
ok(!scalar @{$Pub->{topics}->{$test_topic}}, 'Removed all topics');

# Test once
$Pub->once($test_topic, $success_callback);
$Pub->emit($test_topic, 'Test once');

ok(!scalar @{$Pub->{topics}->{$test_topic}}, 'Removed once handler');

done_testing();

