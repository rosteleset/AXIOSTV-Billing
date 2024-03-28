#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

BEGIN {
  use FindBin '$Bin';
  use lib $Bin ;
  use lib $Bin . '/../';
  use lib $Bin . '/../../';
  use lib $Bin . '/../../../../lib';
  use lib $Bin . '/../../../../libexec';
  use lib $Bin . '/../../../../AXbills';
  use lib $Bin . '/../../../../AXbills/mysql';
}

plan tests => 5;

use_ok('Parser::Dump');

my $file_expected = {
  users_pi => {
    columns   => {
      uid            => {Type => 'INT(11) UNSIGNED'},
      fio            => {Type => 'VARCHAR(120)' },
      phone          => {Type => 'VARCHAR(16)' },
      email          => {Type => 'VARCHAR(250)' },
      country_id     => {Type => 'SMALLINT(6) UNSIGNED' },
      address_street => {Type => 'VARCHAR(100)' },
      address_build  => {Type => 'VARCHAR(10)' },
      address_flat   => {Type => 'VARCHAR(10)' },
      comments       => {Type => 'TEXT' },
      contract_id    => {Type => 'VARCHAR(10)' },
      contract_date  => {Type => 'DATE', Default =>  '0000-00-00'},
      contract_sufix => {Type => 'VARCHAR(5)' },
      pasport_num    => {Type => 'VARCHAR(16)' },
      pasport_date   => {Type => 'DATE', Default =>  '0000-00-00' },
      pasport_grant  => {Type => 'VARCHAR(100)' },
      zip            => {Type => 'VARCHAR(7)' },
      city           => {Type => 'VARCHAR(20)' },
      accept_rules   => {Type => 'TINYINT(1) UNSIGNED' },
      location_id    => {Type => 'INTEGER(11) UNSIGNED' },
    }
  }
};

Parser::Dump::set_debug(1);

my $parsed_files = Parser::Dump::parse('/usr/axbills/db');

use Data::Dumper;
open(my $fh, '>', 'tables_parsed.pl') or die "$!";
print $fh Dumper($parsed_files);

ok($parsed_files, 'Parsed file without errors');
my $is_hash = ref $parsed_files eq 'HASH';

ok($is_hash, 'Parsed file statement is HASH ref');

ok($is_hash && exists $parsed_files->{users_pi} && $parsed_files->{temp_table}, 'Found both tables');
$is_hash && is_deeply($parsed_files->{users_pi}, $file_expected->{users_pi}, 'Parsed table as expected');

1;