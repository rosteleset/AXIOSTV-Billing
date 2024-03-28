#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 10;

my $libpath = '';
BEGIN{
  use FindBin '$Bin';
  $libpath = $Bin . '/../../../../'; # Assuming we are in /usr/axbills/lib/AXbills/Nas/Mikrotik/t
}

use lib $libpath . '/';
use lib $libpath . '/lib';
use lib $libpath . '/lib/AXbills';
use lib $libpath . '/lib/AXbills/Nas';
use lib $libpath . '/AXbills';
use lib $libpath . '/AXbills/mysql';

use AXbills::Base qw /_bp/;
use_ok( 'AXbills::Nas::Mikrotik' );

use AXbills::Nas::Mikrotik::API;
our %conf;
our $base_dir;
require_ok("libexec/config.pl");

my $test_host = {
  nas_mng_ip_port => "192.168.2.1:0:8728",
  nas_type        => 'mikrotik',
  nas_mng_user    => 'axbills_admin',
  nas_mng_password => 'axbills_admin'
};

my $mt = AXbills::Nas::Mikrotik->new( $test_host, \%conf, {
    backend => 'api',
    DEBUG   => 0,

  } );

is( ref $mt, 'AXbills::Nas::Mikrotik' , 'Got AXbills::Nas::Mikrotik object' );

can_ok( 'AXbills::Nas::Mikrotik', qw/
    has_access
    get_list
    interfaces_list
    addresses_list
    leases_list
    leases_remove
    leases_add
    leases_remove_all_generated
    dhcp_servers_check
    check_defined_networks
    hotspot_configure
    / );

my $has_access = $mt->has_access();
ok ($has_access, 'Has access to mikrotik via API');

$has_access == 1 or die("No access to mikrotik : $has_access \n");

ok (scalar @{$mt->interfaces_list()}, 'Can get interfaces');

my $addresses = $mt->addresses_list();
ok(scalar @{$addresses}, 'Can get IP addresses');

# Check addresses contains address we are talking
my $got_address = 0;
foreach my $element ( @{$addresses} ) {
  if ($element->{address} =~ $mt->{executor}{host}){ $got_address = 1; last };
}

ok($got_address, 'Addresses contains address we are talking');

my AXbills::Nas::Mikrotik::API $api_mt = $mt->{executor};

# Execute custom command
ok($api_mt->execute(['/ip address print ']), 'Custom command execution');
ok($api_mt->execute(['/ip/hotspot/service-port/print',{},{name => 'ftp'}]), "Command with query ");

#ok($api_mt->upload_key() || 1, 'Upload key');


done_testing();

