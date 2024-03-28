#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

our $Bin;

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

plan tests => 10;


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


my $parsed_real = Parser::Dump::parse($Bin . '/Test_dump.sql');
ok($parsed_real, 'Parsed file statement without errors');
ok(ref $parsed_real eq 'HASH', 'Parsed file is HASH ref');
is_deeply($parsed_real, $file_expected, 'Got and expected equals');

my $parsed_two_files = Parser::Dump::parse($Bin . '/Test_dump_two_tables.sql');
ok($parsed_two_files, 'Parsed file without errors');
my $is_hash = ref $parsed_two_files eq 'HASH';
ok($is_hash, 'Parsed file statement is HASH ref');
ok($is_hash && exists $parsed_two_files->{users_pi} && $parsed_two_files->{temp_table}, 'Found both tables');
$is_hash && is_deeply($parsed_two_files->{users_pi}, $file_expected->{users_pi}, 'Parsed table as expected');

my $name =  'axbills';
if ($ARGV[0]){
  $name = $ARGV[0];
  Parser::Dump::set_debug(4);
}

my $file = "/usr/axbills/db/$name.sql";
diag("Parsing $file");
my $parsed_real_file = Parser::Dump::parse($file);
ok($parsed_real_file, "Parsed $file without errors");
ok(ref $parsed_real_file eq 'HASH', 'Parsed file statement is HASH ref');

1;