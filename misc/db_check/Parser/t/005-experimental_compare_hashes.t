#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2;

use AXbills::Experimental;
use AXbills::Base qw/_bp/;

my %hash1 = (
  level1 => {
    level2 => {
      level3 => ''
    }
  }
);

#Simply dereferencing reference to get exact copy
my %hash1_copy = %{\%hash1};

my %another_hash = (
  level1 => {
    level2 => {
      level3 => 'ANOTHER_VALUE'
    }
  }
);

my $differences1 = compare_hashes_deep(\%hash1, \%hash1_copy);
ok(scalar @{$differences1} == 0, 'No differences on equal hashes');

my $differences2 = compare_hashes_deep(\%hash1, \%another_hash);
ok(scalar @{$differences2} == 1, 'One value differs, so show one difference');

1;
