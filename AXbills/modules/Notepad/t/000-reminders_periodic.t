#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 4;

use_ok('Notepad::Reminders', qw/calculate_next_periodic_time/);

use Notepad::Reminders;

use constant {
  PERIODIC_RULE_ONCE          => 0,
  PERIODIC_RULE_EVERY_DAY     => 1,
  PERIODIC_RULE_ON_WEEKDAYS   => 2,
  PERIODIC_RULE_WEEKDAYS_LIST => 3,
  PERIODIC_RULE_EVERY_WEEK    => 4,
  PERIODIC_RULE_EVERY_MONTH   => 5,
  SECONDS_IN_DAY              => 86400,
};

ok(
  calculate_next_periodic_time(
    '2017-01-01 09:00:00',
    { rule_id => PERIODIC_RULE_EVERY_DAY },
    '2017-01-01 09:00:05',
  )
    eq '2017-01-02 09:00:00' ,
  
  'If seen at the same moment, should add one day'
);

ok(
  calculate_next_periodic_time(
    '2017-01-01 09:00:00',
    { rule_id => PERIODIC_RULE_EVERY_DAY },
    '2017-01-02 08:00:05',
  )
    eq '2017-01-02 09:00:00' ,
  
  'If seen at next day but time not yet come, should return same day with another time'
);

ok(
  calculate_next_periodic_time(
    '2017-01-01 09:00:00',
    {
      rule_id => PERIODIC_RULE_ON_WEEKDAYS,
      week_day => '0,1,2,3,4,5,6'
    },
    '2017-01-01 09:00:05',
  )
    eq '2017-01-02 09:00:00' ,
  
  'If seen at the same moment, should add one day'
);


done_testing();

