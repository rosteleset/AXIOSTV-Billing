#!/usr/bin/perl -w

=head1 24NS

 Paysys tests for 24NS & its emulation
  DATE:19.04.2019
=cut

use strict;
use warnings;
use Test::More tests => 14;
use Data::Dumper;

our (%FORM, %LIST_PARAMS, %functions, %conf, $html, %lang, @_COLORS,);

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

if (scalar @ARGV == 0) {
  print " help - man\n\n KEY= - enter pay_system account key or default(UID)\n\n  NAME= - enter pay_system name or default(24NS)\n\n ID= - enter pay_system id or default\n\n URL= - enter IP:PORT for web_requests or default(127.0.0.1:9443)\n\n";
  exit;
}

if ($ARGV[0] eq 'help') {
  print " help - man\n\n KEY= - enter pay_system account key or default(UID)\n\n  NAME= - enter pay_system name or default(24NS)\n\n ID= - enter pay_system id or default\n\n URL= - enter IP:PORT for web_requests or default(127.0.0.1:9443)\n\n";
  exit;
}

use_ok('Paysys');
use_ok('Paysys::systems::24_non_stop');
use_ok('Conf');
use_ok('AXbills::Base', qw/mk_unique_value parse_arguments/);
use_ok('XML::Simple');
use_ok('Digest::MD5');

use AXbills::Init qw/$db $admin $users/;
use Paysys;
my $Conf = Conf->new($db, $admin, \%conf);
my $md5 = Digest::MD5->new();
$md5->reset();
my $attr = parse_arguments(\@ARGV);
my $url = $attr->{URL} || '127.0.0.1:9443';
my $user_id = $attr->{USER} || 1;
my $service = $attr->{SERVICE_ID} || 1;
my $inc_user_id = 123454321;
my $user_name = uc($attr->{NAME} || '24NS');
my $random_number = int(rand(1000));

my $_24_NS = Paysys::systems::24_non_stop->new($db, $admin, \%conf, {
  CUSTOM_NAME => $user_name,
  CUSTOM_ID   => $attr->{ID} || '',
});
$_24_NS->conf_gid_split($service);
#calculation SIGN check
my $sign_correct_ch = '';
my $sign_incorrect_ch = '';
$sign_correct_ch = $md5->add(1 . '_' . $user_id . '_' . $service . '_' . $random_number . '_' . $conf{"PAYSYS_" . $user_name . "_SECRET"});
$sign_correct_ch = uc($md5->hexdigest());
$sign_incorrect_ch = $md5->add(1 . '_' . $inc_user_id . '_' . $service . '_' . $random_number . '_' . $conf{"PAYSYS_" . $user_name . "_SECRET"});
$sign_incorrect_ch = uc($md5->hexdigest());

# TEST 7 checking function check with valid account
my $user_exist_responce = $_24_NS->proccess(
{
    ACT         => 1,
    PAY_ACCOUNT => $user_id,
    SERVICE_ID  => $service,
    PAY_ID      => $random_number,
    SIGN        => $sign_correct_ch,
    test        => 1,
  }
);

my $res = '';
($res) = ($user_exist_responce =~ /\<status_code\>(\d+)\<\/status_code\>/g);
ok($res && $res eq '21', 'User Exist(function ACT 1)');

# TEST 8 checking function check with invalid account
my $user_not_exist_responce = $_24_NS->proccess(
  {
    ACT         => 1,
    PAY_ACCOUNT => $inc_user_id,
    SERVICE_ID  => $service,
    PAY_ID      => $random_number,
    SIGN        => $sign_incorrect_ch,
    test        => 1,
  }
);
($res) = ($user_not_exist_responce =~ /\<status_code\>(-\d+)\<\/status_code\>/g);
ok($res && $res eq '-40', 'User Not Exist(function ACT 1)');


#calculation SIGN pay
my $sign_correct_p = '';
my $sign_incorrect_p = '';
my $number = '';
$sign_correct_p = $md5->add(4 . '_' . $user_id . '_' . $service . '_' . $random_number . '_' . 1.00 . '_' . $conf{"PAYSYS_" . $user_name . "_SECRET"});
$sign_correct_p = uc($md5->hexdigest());
$sign_incorrect_p = $md5->add(4 . '_' . $inc_user_id . '_' . $service . '_' . $random_number . '_' . 1.00 . '_' . $conf{"PAYSYS_" . $user_name . "_SECRET"});
$sign_incorrect_p = uc($md5->hexdigest());

# TEST 9 checking function pay with valid account
my $success_payment_responce = $_24_NS->proccess(
  {
    ACT         => 4,
    PAY_ACCOUNT => $user_id,
    SERVICE_ID  => $service,
    PAY_ID      => $random_number,
    SIGN        => $sign_correct_p,
    PAY_AMOUNT  => 1.00,
    test        => 1,
  }
);
($res) = ($success_payment_responce =~ /\<status_code\>(\d+)\<\/status_code\>/g);
my $number = ($success_payment_responce =~ /\<pay_id\>(\d+)\<\/pay_id\>/g);
ok($res && $res eq '22', 'Success payment(function ACT 4) ' . $user_name . ":" . $number);

# TEST 10 checking function pay with invalid account
my $payment_with_incorrect_user_responce = $_24_NS->proccess(
  {
    ACT         => 4,
    PAY_ACCOUNT => $inc_user_id,
    SERVICE_ID  => $service,
    PAY_ID      => $random_number,
    SIGN        => $sign_incorrect_p,
    PAY_AMOUNT  => 1.00,
    test        => 1,
  }
);
($res) = ($payment_with_incorrect_user_responce =~ /\<status_code\>(-\d+)\<\/status_code\>/g);
ok($res && $res eq '-40', 'Success - no payment created with not existed user(function ACT 4)');

#calculation SIGN confirm
my $sign_confirm = '';
$sign_confirm = $md5->add(7 . '_' . $user_id . '_' . $service . '_' . $random_number . '_' . $conf{"PAYSYS_" . $user_name . "_SECRET"});
$sign_confirm = uc($md5->hexdigest());

# TEST 11 checking function for transaction status
my $confirm_responce = $_24_NS->proccess(
  {
    ACT         => 7,
    PAY_ACCOUNT => $user_id,
    SERVICE_ID  => $service,
    PAY_ID      => $random_number,
    SIGN        => $sign_confirm,
    PAY_AMOUNT  => 1.00,
    test        => 1,
  }
);

($res) = ($confirm_responce =~ /\<status_code\>(\d+)\<\/status_code\>/g);
ok($res && $res eq '11', 'Confirm payment(function ACT 7)');

#Web test
print "________________\nWeb test\n________________\n\n";
my $result = '';
my $pay_id = int(rand(1000));
my $sign_check = $md5->add(1 . '_' . $user_id . '_' . $service . '_' . $pay_id . '_' . $conf{"PAYSYS_" . $user_name . "_SECRET"});
$sign_check = uc($md5->hexdigest());
my $sign_pay = $md5->add(4 . '_' . $user_id . '_' . $service . '_' . $pay_id . '_' . 1.01 . '_' . $conf{"PAYSYS_" . $user_name . "_SECRET"});
$sign_pay = uc($md5->hexdigest());
$sign_confirm = $md5->add(7 . '_' . $user_id . '_' . $service . '_' . $pay_id . '_' . $conf{"PAYSYS_" . $user_name . "_SECRET"});
$sign_confirm = uc($md5->hexdigest());

#Web test 12 check
$result = AXbills::Fetcher::web_request("https://$url/paysys_check.cgi?ACT=1&PAY_ACCOUNT=$user_id&SERVICE_ID=$service&PAY_ID=$pay_id&SIGN=$sign_check", {
  INSECURE => 1,
});
my $req_xml_check = XML::Simple::XMLin($result, ForceArray => 0, KeyAttr => 1);
ok(defined($req_xml_check->{status_code}) && $req_xml_check->{status_code} == 21, "Function check - ok, User exist.");

#Web test 13 pay
$result = AXbills::Fetcher::web_request("https://$url/paysys_check.cgi?ACT=4&PAY_ACCOUNT=$user_id&SERVICE_ID=$service&PAY_ID=$pay_id&PAY_AMOUNT=1.01&SIGN=$sign_pay", {
  INSECURE => 1,
});
my $req_xml_pay = XML::Simple::XMLin($result, ForceArray => 0, KeyAttr => 1);
ok(defined($req_xml_pay->{status_code}) && $req_xml_pay->{status_code} == 22, "Function pay - ok, Payment is maked for $user_name:$pay_id}.");

#Web test 14 confirm(ACT:7)
my $response = AXbills::Fetcher::web_request("https://$url/paysys_check.cgi?ACT=7&PAY_ACCOUNT=$user_id&SERVICE_ID=$service&PAY_ID=$pay_id&SIGN=$sign_confirm", {
  INSECURE => 1,
});
my $req_xml_payment_id = XML::Simple::XMLin($response, ForceArray => 0, KeyAttr => 1);
ok(defined($req_xml_payment_id->{status_code}) && $req_xml_payment_id->{status_code} == 11, "Function confirm payment - ok, Payment is confirmed for $user_name:$pay_id}.");

print "\nTest time: " . AXbills::Base::gen_time($begin_time) . "\n\n";