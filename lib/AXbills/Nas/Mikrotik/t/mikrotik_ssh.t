#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 13;

my $libpath = '';
BEGIN{
  use FindBin '$Bin';
  $libpath = $Bin . '/../../../../../'; # Assuming we are in /usr/axbills/lib/AXbills/Nas/Mikrotik/t
}

use lib $libpath . '/';
use lib $libpath . '/lib';
use lib $libpath . '/lib/AXbills';
use lib $libpath . '/lib/AXbills/Nas';
use lib $libpath . '/AXbills';
use lib $libpath . '/AXbills/mysql';


my $debug = 0;

my $test_comment = "ABills test. you can remove this";

my $test_add_lease_command = "/ip dhcp-server lease add address=192.168.0.2 mac-address=00:27:22:E8:40:F3 server=test_generated disabled=yes comment=\"$test_comment\"";
my $test_add_lease_bad_command = "/ip dhcp-server lease add address=192.168.0.2 mac-address=00:27:22:E8:40:F3 server=dhasdsdfcp1 disabled=yes comment=\"$test_comment\"";
my $remove_lease_command = "/ip dhcp-server lease remove numbers=[find comment=\"$test_comment\"]";

use_ok( 'AXbills::Base' );
use_ok( 'AXbills::Nas::Mikrotik' );

my $test_host = {
  nas_mng_ip_port => "192.168.2.1::22022",
  nas_type        => 'mikrotik',
  nas_mng_user    => 'axbills_admin',
};

my $mt = AXbills::Nas::Mikrotik->new( $test_host,
  undef,
  { DEBUG => $debug, backend => 'ssh' } );

ok( ref $mt eq 'AXbills::Nas::Mikrotik', "Constructor returned AXbills::Nas::Mikrotik object" );
if ( !ok( $mt->has_access(), "Has access to $test_host->{nas_mng_ip_port}" ) ){
  die ( "Host is not accesible\n" );
}

my $system = $mt->execute( [ "/system identity print" ] );

ok( $system, "Execute single" );
ok( $mt->execute( [ "/system identity print", "system resource cpu print" ] ), "Execute 2 commands" );
ok( !$mt->execute( [ "/some undefined command" ] ), "Holding errors (Executing bad command)" );

my $ip_addresses = $mt->get_list( 'ip_a' );
ok( scalar ( @{$ip_addresses} ) > 0 && ref $ip_addresses->[0] eq 'HASH', "Got non-empty list of IP addresses" );

$mt->execute('/ip dhcp-server add name=test_generated interface=ether1 disabled=yes');
my $dhcp_servers_list = $mt->get_list( 'dhcp_servers' );
ok( scalar ( @{$dhcp_servers_list} ) > 0 && ref $dhcp_servers_list->[0] eq 'HASH', "Got non-empty list of DHCP-Servers" );

ok( $mt->execute( $test_add_lease_command ), "Added lease" );

my $leases_list = $mt->get_list( 'dhcp_leases' );
ok( scalar ( @{$leases_list} ) > 0 && ref $leases_list->[0] eq 'HASH', "Got non-empty list of leases" );

ok( $mt->execute( $remove_lease_command ), "Removed test lease" );
ok( $mt->execute( $test_add_lease_bad_command ) == 0, "Added lease with bad dhcp-server name throws error" );

$mt->execute('/ip dhcp-server remove test_generated');

done_testing();

