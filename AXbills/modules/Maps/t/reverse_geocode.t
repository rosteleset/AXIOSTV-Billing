#!/usr/bin/perl
#use strict;
use warnings;

use Test::More;
use AXbills::Base qw/mk_unique_value _bp/;
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

plan tests => 5;

require_ok( "../libexec/config.pl" );

open ( my $HOLE, '>>', '/dev/null' );
select $HOLE;
require_ok( "../cgi-bin/admin/index.cgi" );
require_ok( "../AXbills/modules/Maps/webinterface" );
select STDOUT;

#Initialization
require_ok( 'Maps' );
my $Maps = Maps->new( $db, $admin, \%conf );

my $gma;
if (use_ok('Maps::GMA' => [$db, $admin, \%conf] )){
  $gma = Maps::GMA->new($db, $admin, \%conf);
};

# Leontovycha 10 with reversed coords
my $test_coords = {
  COORDX => 48.54174911679562,
  COORDY => 25.03692448139191,
};

my $geocode_result = $gma->get_address_for($test_coords);

_bp('', $geocode_result, {TO_CONSOLE => 1});




1;