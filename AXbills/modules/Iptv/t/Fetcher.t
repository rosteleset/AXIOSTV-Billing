#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 2;
use Getopt::Long;
our $libpath;
BEGIN {
  our $Bin;
  use FindBin '$Bin';
  
  $libpath = $Bin . '/../';
  if ( $Bin =~ m/\/axbills(\/)/ ) {
    $libpath = substr($Bin, 0, $-[1]);
  }
  
  unshift @INC, $libpath . '/lib';
  unshift @INC, $libpath . '/AXbills/modules';
  unshift @INC, $libpath . '/AXbills/mysql';
}
use AXbills::Fetcher;

my %opts;  
GetOptions('mac=s' => \$opts{mac}, 'pin=s' => \$opts{pin});
my $request = ($opts{mac}) ? 'mac=' . $opts{mac} : (($opts{pin}) ? 'pin=' . $opts{pin} : '');
my $web_request1 = web_request("https://127.0.0.1:9443/get_pl.cgi",             {INSECURE => 1});
my $web_request2 = web_request("https://127.0.0.1:9443/get_pl.cgi?" . $request, {INSECURE => 1});
like($web_request1, qr/No user found/, 'No user found');
like($web_request2, qr/#EXTM3U/, 	   'User found'   );

