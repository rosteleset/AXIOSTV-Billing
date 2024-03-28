#!/usr/bin/perl -w

=head1 Ibox

 Paysys tests for Ibox

=cut

use strict;
use warnings;
use Test::More tests => 17;
use Data::Dumper;

our (%FORM, %LIST_PARAMS, %functions, %conf, $html, %lang, @_COLORS);

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
  print " help - man\n\n KEY= - enter pay_system account key or default(UID)\n\n  NAME= - enter pay_system name or default(IBOX)\n\n ID= - enter pay_system id or default\n\n URL= - enter IP:PORT for web_requests or default(127.0.0.1:9443)\n\n";
  exit;
}

if ($ARGV[0] eq 'help') {
  print " help - man\n\n KEY= - enter pay_system account key or default(UID)\n\n  NAME= - enter pay_system name or default(IBOX)\n\n ID= - enter pay_system id or default\n\n URL= - enter IP:PORT for web_requests or default(127.0.0.1:9443)\n\n";
  exit;
}

my $begin_time = AXbills::Base::check_time();

use_ok('Paysys');
use_ok('Paysys::systems::Ibox');
use_ok('Conf');
use_ok('AXbills::Fetcher', qw/web_request/);
use_ok('AXbills::Base', qw/mk_unique_value parse_arguments/);
use_ok('XML::Simple');

use AXbills::Init qw/$db $admin $users/;
use Paysys;
my $Conf = Conf->new($db, $admin, \%conf);
my $attr = parse_arguments(\@ARGV);
my $url = $attr->{URL} || '127.0.0.1:9443';
my $user_id = $attr->{USER} || '1';

my $random_number = int(rand(10000));
my $Ibox = Paysys::systems::Ibox->new($db, $admin, \%conf, {
  CUSTOM_NAME => $attr->{NAME} || '',
  CUSTOM_ID   => $attr->{ID} || '',
});

# checking function check with valid account
my $result = $Ibox->proccess(
  {
    account => "$user_id",
    command => 'check',
    sum     => '1.00',
    txn_id  => "$random_number",
    test    => 1,
  }
);
my $res = '';
($res) = ($result =~ /\<result\>(\d+)\<\/result\>/g);
ok($res eq '0', 'User Exist(function check)');

# checking function check with invalid account
$result = $Ibox->proccess(
  {
    account => '1232124',
    command => 'check',
    sum     => '1.00',
    txn_id  => "$random_number",
    test    => 1,
  }
);
$res = '';
($res) = ($result =~ /\<result\>(\d+)\<\/result\>/g);
ok($res eq '5', 'User not Exist(function check)');

# checking function check without one parameter
$result = $Ibox->proccess(
  {
    account => "$user_id",
    command => 'check',
    txn_id  => "$random_number",
    test    => 1,
  }
);
$res = '';
($res) = ($result =~ /\<result\>(\d+)\<\/result\>/g);
ok($res eq '300', "There isn't attr summ(function check)");

# checking function pay with valid account
$result = $Ibox->proccess(
  {
    account => "$user_id",
    command => 'pay',
    txn_id  => "$random_number",
    sum     => '1.00',
    test    => 1,
  }
);
$res = '';
my $prv_txn_id1 = '';
($res) = ($result =~ /\<result\>(\d+)\<\/result\>/g);
($prv_txn_id1) = ($result =~ /\<prv_txn\>(\d+)\<\/prv_txn\>/g);
ok($res eq '0', "Payment completed(function pay)");

# checking function pay with invalid account
$result = $Ibox->proccess(
  {
    account => '1232124',
    command => 'pay',
    txn_id  => "$random_number",
    sum     => '1.00',
    test    => 1,
  }
);
$res = '';
($res) = ($result =~ /\<result\>(\d+)\<\/result\>/g);
ok($res eq '5', "Not exist user(function pay)checking with not existed account");

# checking function pay without one parameter
$result = $Ibox->proccess(
  {
    account => "$user_id",
    command => 'pay',
    txn_id  => "$random_number",
    test    => 1,
  }
);
$res = '';
($res) = ($result =~ /\<result\>(\d+)\<\/result\>/g);
ok($res eq '300', "There isn't attr sum(function pay)");

# checking function pay with valid account again
$result = $Ibox->proccess(
  {
    account => "$user_id",
    command => 'pay',
    txn_id  => "$random_number",
    sum     => '1.00',
    test    => 1,
  }
);
$res = '';
my $prv_txn_id2 = '';
($res) = ($result =~ /\<result\>(\d+)\<\/result\>/g);
($prv_txn_id2) = ($result =~ /\<prv_txn\>(\d+)\<\/prv_txn\>/g);
ok($prv_txn_id1 && $prv_txn_id2 && "$prv_txn_id1" eq "$prv_txn_id2", "Payment exist (function pay) checking with same Transaction");

# checking function cancel
if ($prv_txn_id1) {
  $result = $Ibox->proccess(
    {
      command => 'cancel',
      prv_txn => "$prv_txn_id1",
      test    => 1,
    }
  );
  $res = '';
  ($res) = ($result =~ /\<result\>(\d+)\<\/result\>/g);
  ok($res eq '0', 'Transaction was canceled(function cancel)');
}
else {
  print "You entered incorrect parameter!!!!!!!!!!!\n";
}

#Web test
print "________________\nWeb test\n\n";
#Web test check
$result = AXbills::Fetcher::web_request("https://$url/paysys_check.cgi?command=check&txn_id=$random_number&account=$user_id&sum=1.00", {
  INSECURE => 1,
});
my $req_xml_check = XML::Simple::XMLin($result, ForceArray => 0, KeyAttr => 1);
ok(defined($req_xml_check->{result}) && $req_xml_check->{result} == 0, "Function check - ok, User exist.");
#Web test pay
my $txn_num = int(rand(10000));
$result = AXbills::Fetcher::web_request("https://$url/paysys_check.cgi?command=pay&txn_id=$txn_num&account=$user_id&sum=1.00&txn_date=20050815120133", {
  INSECURE => 1,
});
my $req_xml_pay = XML::Simple::XMLin($result, ForceArray => 0, KeyAttr => 1);
ok(defined($req_xml_pay->{result}) && $req_xml_pay->{result} == 0, "Function pay - ok, Payment is maked for Payment_id:"
  . $req_xml_pay->{prv_txn} || '' . ".");

#Web pay for cancel
my $txn_number = int(rand(10000));
my $response = AXbills::Fetcher::web_request("https://$url/paysys_check.cgi?command=pay&txn_id=$txn_number&account=$user_id&sum=1.00&txn_date=20050815120133", {
  INSECURE => 1,
});
my $req_xml_pyament_id = XML::Simple::XMLin($response, ForceArray => 0, KeyAttr => 1);
#Web cancel check
$result = AXbills::Fetcher::web_request("https://$url/paysys_check.cgi?command=cancel&prv_txn=$req_xml_pyament_id->{prv_txn}", {
  INSECURE => 1,
});
my $req_xml_cancel = XML::Simple::XMLin($result, ForceArray => 0, KeyAttr => 1);
ok(defined($req_xml_cancel->{result}) && $req_xml_cancel->{result} == 0, "Function cancel - ok, Payment is canceled for Payment_id:"
  . $req_xml_pyament_id->{prv_txn} || '' . ".");

print "\nTest time: "  . AXbills::Base::gen_time($begin_time) . "\n\n";
