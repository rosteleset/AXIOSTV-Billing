#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests =>3;
our $libpath;
BEGIN {
  our $Bin;
  use FindBin '$Bin';

  $libpath = $Bin . '/../'; # (default) assuming we are in /usr/axbills/libexec/
  if ( $Bin =~ m/\/axbills(\/)/ ) {
    $libpath = substr($Bin, 0, $-[1]);
  }

  unshift @INC, $libpath . '/lib';
  unshift @INC, $libpath . '/AXbills/modules';
  unshift @INC, $libpath . '/AXbills/mysql';
}

use AXbills::Base;

is(date_diff('2018-03-01', '2018-03-02'), 1, '2018-03-01 - 2018-03-02 = 1');
is(date_diff('2018-03-01', '2018-03-24'), 23, '2018-03-01 - 2018-03-31 = 31');
is(date_diff('2018-03-25', '2018-03-26'), 1, '2018-03-25 - 2018-03-26 = 1');

done_testing;