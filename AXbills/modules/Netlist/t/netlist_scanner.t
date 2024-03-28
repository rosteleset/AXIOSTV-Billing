#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use AXbills::Base qw/_bp/;
#BEGIN {
#  use FindBin '$Bin';
#  use lib $Bin . '/../';
#}

our ($db, $admin, %conf);
require_ok 'libexec/config.pl';

my $test_network = '192.168.1.0/24';
my %online_hosts = (
  '192.168.1.62' => 1,
  '192.168.1.1'  => 1
);

my %disabled_hosts = (
  '192.168.1.60' => 1,
);

require_ok( 'Nmap::Parser' );
require_ok( 'Netlist::Scanner' );

my $scanner = new_ok('Netlist::Scanner' => [ $db, $admin, \%conf ] );

$scanner->set_target( $test_network );
$scanner->set_timeout( 200 );

my $Results = $scanner->scan();

#_bp('Results', $Results, { TO_CONSOLE => 1 });

foreach my $must_be_alive_ip ( keys %online_hosts ) {
  ok( exists $Results->{$must_be_alive_ip}, "Found alive $must_be_alive_ip"  );
}

foreach my $must_be_dead_ip ( keys %disabled_hosts ) {
  ok( !exists $Results->{$must_be_dead_ip}, "Dead $must_be_dead_ip"  );
}

done_testing(scalar (keys %online_hosts) + scalar (keys %disabled_hosts) + 4);

