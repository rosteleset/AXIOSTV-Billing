#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests =>8;
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
use AXbills::Filters;

ok(_expr('1234','^([0-9]{4,6})$/74832;') eq '74832', '^([0-9]{4,6})$/74832;'); 
ok(_expr('+380972692005','^2([0-9]{6})$/7483;') eq '+380972692005', '^2([0-9]{6})$/7483;');
ok(_expr('9123456789','(^9[0-9]{9})/7;') eq '7', '(^9[0-9]{9})/7;');
ok(_expr('810972692005','^810/;') eq '972692005', '^810/;');
ok(_expr('80972692005','^8/7;') eq '70972692005', '^8/7;');
ok(_expr('8882692005','^8*/7;') eq '72692005', '^*8/7;');
ok(_expr('483272692005','^4832/74832') eq '7483272692005', '^4832/74832');
ok(_expr('0972692005','^0/+380;') eq '+380972692005', '^0/+380;'); 