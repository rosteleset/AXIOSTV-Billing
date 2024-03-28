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

my $counter = 10;
plan tests => ($counter + 4);

require_ok("../libexec/config.pl");

open (my $HOLE, '>>', '/dev/null');
disable_output();
require_ok("../cgi-bin/admin/index.cgi");
require_ok("../AXbills/modules/Events/webinterface");
enable_otput();

#Initialization
require_ok('Events');

my $Events = Events->new($db, $admin, \%conf);

#$Hotspot->{debug} = 1;

my $test_session_id = mk_unique_value(32);

my $test_event = {
  MODULE      => 'Test',
  COMMENTS    => 'Generated',
  EXTRA       => 'https://billing.axiostv.ru',
  STATE_ID    => 1,
  PRIORITY_ID => 1,
  PRIVACY_ID  => 1
};

event_add();

sub event_add {
  for my $group_id ( 1 .. $counter ) {
    $Events->events_add({
      %{$test_event},
      GROUP_ID    => 1,
      PRIORITY_ID => ($group_id % 3),
      STATE_ID    => 1,
    });
    ok(!$Events->{errno}, 'Added');
  }
}



sub disable_output {
  select $HOLE;
}

sub enable_otput {
  select STDOUT;
}
