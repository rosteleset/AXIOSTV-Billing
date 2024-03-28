#!/usr/bin/perl


use warnings FATAL => 'all';
use strict;
use Test::More tests => 2;

BEGIN {
  our $libpath = '../../../../';
  our %conf;

  unshift @INC,
    $libpath . '/lib/',
    $libpath . '/AXbills/mysql/',
    $libpath . '/AXbills/modules/';

  require "$libpath/libexec/config.pl";
}

our %conf;
$ENV{REMOTE_ADDR}='127.0.0.1';
$ENV{QUERY_STRING}='';

if(! $conf{UNIFI_URL}) {
  $conf{UNIFI_URL} = 'http://127.0.0.1/';
}

require_ok( '../unifi/guest/s/default/index.cgi' );

ok(main());

1