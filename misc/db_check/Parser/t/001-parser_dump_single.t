#!/usr/bin/perl
use strict;
use warnings;
use Test::More;


BEGIN {
  use FindBin '$Bin';
  use lib $Bin . '/../';
  use lib $Bin . '/../../';
  use lib $Bin . '/../../../../lib';
  use lib $Bin . '/../../../../libexec';
  use lib $Bin . '/../../../../AXbills';
  use lib $Bin . '/../../../../AXbills/mysql';
}

plan tests => 7;


use_ok('Parser::Dump');

my $test_table_text = <<'[STATEMENT]';
CREATE TABLE temp_table(
  id INT(11) UNSIGNED KEY AUTO_INCREMENT,
  name VARCHAR(32) NOT NULL DEFAULT '',
  value INT(11) NOT NULL DEFAULT 0
)
  COMMENT = 'Temprorary table';
[STATEMENT]

my $test_expected = {
  temp_table => {
    columns   => {
      id => {
        Type => 'INT(11) UNSIGNED',
        Null => 'No'
      },
      name => {
       Type => 'VARCHAR(32)',
      },
      value => {
        Type => 'INT(11)',
      }
    }
  }
};


my $real_data = <<'[REAL_DATA]';
CREATE TABLE IF NOT EXISTS `users_pi` (
  `uid` INT(11) UNSIGNED NOT NULL DEFAULT 0,
  `fio` VARCHAR(120) NOT NULL DEFAULT '',
  `phone` VARCHAR(16) NOT NULL DEFAULT '',
  `email` VARCHAR(250) NOT NULL DEFAULT '',
  `country_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `address_street` VARCHAR(100) NOT NULL DEFAULT '',
  `address_build` VARCHAR(10) NOT NULL DEFAULT '',
  `address_flat` VARCHAR(10) NOT NULL DEFAULT '',
  `comments` TEXT NOT NULL,
  `contract_id` VARCHAR(10) NOT NULL DEFAULT '',
  `contract_date` DATE NOT NULL DEFAULT '0000-00-00',
  `contract_sufix` VARCHAR(5) NOT NULL DEFAULT '',
  `pasport_num` VARCHAR(16) NOT NULL DEFAULT '',
  `pasport_date` DATE NOT NULL DEFAULT '0000-00-00',
  `pasport_grant` VARCHAR(100) NOT NULL DEFAULT '',
  `zip` VARCHAR(7) NOT NULL DEFAULT '',
  `city` VARCHAR(20) NOT NULL DEFAULT '',
  `accept_rules` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  `location_id` INTEGER(11) UNSIGNED NOT NULL DEFAULT '0',
  PRIMARY KEY (`uid`),
  KEY `location_id` (`location_id`)
)
  COMMENT = 'Users personal info';
[REAL_DATA]

my $real_expected = {
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

my $parsed_text = Parser::Dump::parse_statement($test_table_text);
ok($parsed_text, 'Parsed statement without errors');
ok(ref $parsed_text eq 'HASH', 'Parsed statement is HASH ref');
is_deeply($parsed_text, $test_expected, 'Got and expected equals');


my $parsed_real = Parser::Dump::parse_statement($real_data);
ok($parsed_real, 'Parsed real statement without errors');
ok(ref $parsed_real eq 'HASH', 'Parsed real statement is HASH ref');
is_deeply($parsed_real, $real_expected, 'Got and expected equals');

1;