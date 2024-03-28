#!/usr/bin/perl

use strict;
use warnings;

use Test::More qw/no_plan/;

#admin interface
$ENV{'REQUEST_METHOD'} = "GET";
$ENV{'QUERY_STRING'} = "user=axbills&passwd=axbills";

use vars qw(
  $sql_type
  $global_begin_time
  %conf
  @MODULES
  %functions
  %FORM
  $users
  $db
  $admin
 );

require_ok( "../libexec/config.pl" );
require_ok( "../cgi-bin/admin/index.cgi" );
require_ok( "../AXbills/modules/Equipment/webinterface" );

use AXbills::Filters qw(_mac_former);
require 'AXbills/Misc.pm';

require_ok( 'Equipment' );

my $Equipment = Equipment->new( $db, $admin, \%conf );

use JSON;

my $json = JSON->new->utf8( 0 );

# test
ok( equipment_show_snmp_backup_files(), 'Calling equipment_show_snmp_backup_files without params' );
ok( equipment_backup(), 'Calling equipment_backup without params' );
ok( equipment_snmp_backup(), 'Calling equipment_snmp_backup without params' );
ok( equipment_snmp_upload(), 'Calling equipment_snmp_upload without params' );
ok( equipment_file_exists(), 'Calling equipment_file_exists without params' );