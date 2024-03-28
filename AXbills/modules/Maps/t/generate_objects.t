#!/usr/bin/perl
#use strict;
use warnings;

use Test::More;
use AXbills::Base qw/mk_unique_value/;
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

my $count = 200;
my $density = 100;

plan tests => 4 + $count;

require_ok( "../libexec/config.pl" );

open ( my $HOLE, '>>', '/dev/null' );
disable_output();
require_ok( "../cgi-bin/admin/index.cgi" );
require_ok( "../AXbills/modules/Maps/webinterface" );
enable_otput();

#Initialization
require_ok( 'Maps' );

my $Maps = Maps->new( $db, $admin, \%conf );

my $test_object = {
  NAME    => 'TEST_',
  TYPE_ID => '1',
  COORDX  => 25.0411,
  COORDY  => 48.53047,
};

object_add();

sub object_add {
  for my $counter ( 1 .. $count ) {
    my $positive = ($counter % 2 == 0) ? 1 : -1;
    my $comments_id = mk_unique_value(32);
    
    $Maps->points_add( {
        %{$test_object},
        NAME     => $test_object->{NAME} . $counter,
        TYPE_ID  => ($counter % 6) + 1,
        COORDY   => ($test_object->{COORDY} + (rand($density) / 100) * $positive)  ,
        COORDX   => ($test_object->{COORDX} + (rand($density) / 100) * $positive)  ,
        COMMENTS => $comments_id
      } );
    ok(!$Maps->{errno}, 'Added');
  }
}



sub disable_output {
  select $HOLE;
}

sub enable_otput {
  select STDOUT;
}
