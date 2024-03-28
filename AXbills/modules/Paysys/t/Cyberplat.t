#!/usr/bin/perl -w

=head1 NAME

 Paysys tests

=cut

use strict;
use warnings;
use Test::More tests => 12;
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

if (scalar @ARGV == 0) {
  print " help - man\n\n KEY= - enter pay_system number key or default(UID)\n\n  NAME= - enter pay_system name or default(Cyberplat)\n\n ID= - enter pay_system id or default\n\n URL= - enter IP:PORT for web_requests or default(127.0.0.1:9443)\n\n";
  exit;
}

if ($ARGV[0] eq 'help') {
  print " help - man\n\n KEY= - enter pay_system number key or default(UID)\n\n  NAME= - enter pay_system name or default(Cyberplat)\n\n ID= - enter pay_system id or default\n\n URL= - enter IP:PORT for web_requests or default(127.0.0.1:9443)\n\n";
  exit;
}
my $begin_time = AXbills::Base::check_time();

use_ok('Paysys');
use_ok('Paysys::systems::Cyberplat');
use_ok('Conf');
use_ok('AXbills::Base', qw/mk_unique_value parse_arguments/);
use_ok('XML::Simple');

use AXbills::Init qw/$db $admin $users/;
use Paysys;
my $Conf = Conf->new($db, $admin, \%conf);
my $attr = parse_arguments(\@ARGV);
my $url = $attr->{URL} || '127.0.0.1:9443';
my $user_id = $attr->{USER} || '1';

my $random_number = int(rand(1000));

my $Cyberplat = Paysys::systems::Cyberplat->new($db, $admin, \%conf, {
  CUSTOM_NAME => $attr->{NAME} || '',
  CUSTOM_ID   => $attr->{ID} || '',
});

my $result = $Cyberplat->proccess(
  {
    number => "$user_id",
    action => 'check',
    sum     => '1.00',
    receipt  => "$random_number",
    test    => 1,
  });

my $res = '';
($res) = ($result =~ /\<code\>(\d+)\<\/code\>/g);
ok($res eq '0', 'User Exist(function check)');


# checking function check with invalid number
$result = $Cyberplat->proccess(
  {
    number => '1232124',
    action => 'check',
    amount     => '1.00',
    receipt  => "$random_number",
    test    => 1,
  }
);
$res = '';
($res) = ($result =~ /\<code\>(\d+)\<\/code\>/g);
ok($res eq '2', 'User not Exist(function check)');

# checking function pay with valid number
my $prv_receipt1 = $random_number;
$result = $Cyberplat->proccess(
  {
    number => "$user_id",
    action => 'payment',
    receipt  => "$prv_receipt1",
    amount     => '1.00',
    test    => 1,
  }
);
$res = '';
($res)         = ($result =~ /\<code\>(\d+)\<\/code\>/g);
ok($res eq '0', "Payment completed(function pay)");

$result = $Cyberplat->proccess(
  {
    action => 'cancel',
    receipt => "$prv_receipt1",
    test    => 1,
  }
);
$res = '';
($res) = ($result =~ /\<code\>(\d+)\<\/code\>/g);
ok($res eq '0', 'Transaction was canceled(function cancel)');


# checking function pay with invalid number
$result = $Cyberplat->proccess(
  {
    number => '1232124',
    action => 'payment',
    receipt  => "$random_number",
    amount     => '1.00',
    test    => 1,
  }
);
$res = '';
($res) = ($result =~ /\<code\>(\d+)\<\/code\>/g);
ok($res eq '2', "Not exist user(function pay)checking with not existed number");

# checking function pay without one parameter
$result = $Cyberplat->proccess(
  {
    number => "$user_id",
    action => 'payment',
    receipt  => "$random_number",
    test    => 1,
  }
);
$res = '';
($res) = ($result =~ /\<code\>(\d+)\<\/code\>/g);
ok($res eq '14', "There isn't attr sum(function pay)");

#Web test
print "________________\nWeb test\n\n";
#Web test check
$result = AXbills::Fetcher::web_request("https://$url/paysys_check.cgi?action=check&receipt=$random_number&number=$user_id&amount=1.00", {
  INSECURE => 1,
});
my $req_xml_check = XML::Simple::XMLin($result, ForceArray => 0, KeyAttr => 1);
ok(defined($req_xml_check->{code}) && $req_xml_check->{code} == 0, "Function check - ok, User exist.");
#Web test pay
my $txn_num = int(rand(10000));
$result = AXbills::Fetcher::web_request("https://$url/paysys_check.cgi?action=payment&receipt=$txn_num&number=$user_id&amount=1.00&date=2005-09-20T15:53:00", {
  INSECURE => 1,
});
my $req_xml_pay = XML::Simple::XMLin($result, ForceArray => 0, KeyAttr => 1);

ok(defined($req_xml_pay->{code}) && $req_xml_pay->{code} == 0, "Function pay - ok, Payment is maked for Payment_id:"
  . $req_xml_pay->{prv_txn} || '' . ".");

#Web pay for cancel
my $txn_number = int(rand(10000));
my $receipt = $txn_number;
my $response = AXbills::Fetcher::web_request("https://$url/paysys_check.cgi?action=payment&receipt=$receipt&number=$user_id&amount=1.00&date=2005-09-20T15:53:00", {
  INSECURE => 1,
});
my $req_xml_pyament_id = XML::Simple::XMLin($response, ForceArray => 0, KeyAttr => 1);
#Web cancel check
$result = AXbills::Fetcher::web_request("https://$url/paysys_check.cgi?action=cancel&receipt=$receipt", {
  INSECURE => 1,
});
my $req_xml_cancel = XML::Simple::XMLin($result, ForceArray => 0, KeyAttr => 1);
ok(defined($req_xml_cancel->{code}) && $req_xml_cancel->{code} == 0, "Function cancel - ok, Payment is canceled for Payment_id:"
  . $req_xml_pyament_id->{prv_txn} || '' . ".");

print "\nTest time: "  . AXbills::Base::gen_time($begin_time) . "\n\n";
