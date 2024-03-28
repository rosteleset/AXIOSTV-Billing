#!/usr/bin/perl -w

=head1 NAME

 Paysys tests

=cut

use strict;
use warnings;
use Test::More tests => 5;
use Data::Dumper;

our (%FORM, %LIST_PARAMS, %functions, %conf, $html, %lang);


BEGIN {
  our $libpath = '../../../../';
  unshift(@INC, $libpath);
  unshift(@INC, $libpath . 'lib/');
  unshift(@INC, $libpath . 'libexec/');
  unshift(@INC, $libpath . 'AXbills/');
  unshift(@INC, $libpath . 'AXbills/modules/');
  unshift(@INC, $libpath . "AXbills/mysql/");
}
require "libexec/config.pl";
$conf{language} = 'english';
do "language/$conf{language}.pl";
do "/usr/axbills/AXbills/modules/Paysys/lng_$conf{language}.pl";

my $begin_time = AXbills::Base::check_time();
Test::More::use_ok('Paysys');
#Test::More::use_ok('Paysys::systems::PSCB');
Test::More::use_ok('Conf');
Test::More::use_ok('AXbills::Fetcher', qw/web_request/);
Test::More::use_ok('AXbills::Base', qw/mk_unique_value encode_base64 decode_base64 parse_arguments/);
Test::More::use_ok('JSON');

my $argv = AXbills::Base::parse_arguments( \@ARGV );

my $user_id = $argv->{UID} || '1';
my $random_number = int(rand(100000));

# Start validate test
my %validate_request = (
  requisite => $user_id,
);


my $result_validate = AXbills::Fetcher::web_request("https://192.168.1.169:9443/api/validate", {
  REQUEST_PARAMS_JSON => \%validate_request,
  INSECURE            => 1,
});

AXbills::Base::_bp("Validate", $result_validate, {TO_CONSOLE => 1});

# Start pay test
my %pay_request = (
requisite => $user_id,
amount    => 1,
timestamp => "2019-02-22T15:24:30.786Z"
);

my $result_pay = AXbills::Fetcher::web_request("https://192.168.1.169:9443/api/transactions/:$random_number", {
    REQUEST_PARAMS_JSON => \%pay_request,
    INSECURE => 1,
});

AXbills::Base::_bp("Pay", $result_pay, {TO_CONSOLE => 1});

# Start info test
my $result_info = AXbills::Fetcher::web_request("https://192.168.1.169:9443/api/transactions/:$random_number", { INSECURE => 1, });

AXbills::Base::_bp("Info", $result_info, {TO_CONSOLE => 1});

# Start cancel test
my $result_cancel = AXbills::Fetcher::web_request("https://192.168.1.169:9443/api/transactions/:$random_number", {
    CURL_OPTIONS => "-X 'DELETE' ",
    INSECURE => 1,
  });

AXbills::Base::_bp("Cancel", $result_cancel, {TO_CONSOLE => 1});

my $result_list = AXbills::Fetcher::web_request("https://192.168.1.169:9443/api/transactions?begin=2015-10-31T18:00:00.000Z&end=2015-11-30T18:00:00.000Z", {
    INSECURE => 1,
  });

AXbills::Base::_bp("List", $result_list, {TO_CONSOLE => 1});


print "\nTest time: " . AXbills::Base::gen_time($begin_time) . "\n\n";
exit ;