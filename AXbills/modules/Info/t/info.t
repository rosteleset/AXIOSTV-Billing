#!/usr/bin/perl
#use strict;
use warnings;

use Test::More tests => 8;

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

open ( my $HOLE, '>>', '/dev/null' );
disable_output();
require_ok( "../cgi-bin/admin/index.cgi" );
require_ok( "../AXbills/modules/Info/webinterface" );
enable_otput();

#Initialization
require_ok( 'Info' );

my $Info = Info->new( $db, $admin, \%conf );

test_test_();
test_info_defined();
test_info_comments_webinterface();

sub test_test_{
  ok( 1, "True is defined as true" );
  return 1;
}

sub test_info_defined{
  ok( defined $Info, 'Info module defined' );
}

sub test_info_comments_webinterface{
  #add
  $FORM{OBJ_TYPE} = "test";
  $FORM{OBJ_ID} = "1";
  $FORM{TEXT} = "Test comment";

  disable_output();
  my $add_result = info_comment_add();
  enable_otput();
  ok( $add_result, "Can add comment" );

  $FORM{OBJ_ID} = $add_result;

  disable_output();
  my $delete_result = info_comment_del();
  enable_otput();
  ok( $delete_result, "Can delete comment" );

}

sub disable_output{
  select $HOLE;
}

sub enable_otput{
  select STDOUT;
}
