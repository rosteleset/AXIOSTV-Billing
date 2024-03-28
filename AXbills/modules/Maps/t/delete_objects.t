#!/usr/bin/perl
#use strict;
use warnings;
use v5.16;

use Test::More;
use AXbills::Base qw/mk_unique_value/;
#admin interface
$ENV{'REQUEST_METHOD'} = "GET";
$ENV{'QUERY_STRING'} = "user=axbills&passwd=axbills";

my $BP_ARGS = { TO_CONSOLE => 1};

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

my $count = 1;

plan tests => 4 + $count;

require_ok( "../libexec/config.pl" );

open ( my $HOLE, '>>', '/dev/null' );
select $HOLE;
require_ok( "../cgi-bin/admin/index.cgi" );
require_ok( "../AXbills/modules/Maps/webinterface" );
select STDOUT;

#Initialization
require_ok( 'Maps' );
my $Maps = Maps->new( $db, $admin, \%conf );

ok $Maps->polyline_points_del(undef, { polyline_id => 6 });

_error_show($Maps);

1;