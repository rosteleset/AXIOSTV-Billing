#!/usr/bin/perl -w
=head1 NAME

 Paysys tests

=cut

use strict;
use warnings;
use Test::More tests => 9;
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
  print " help - man\n\n KEY= - enter pay_system account key or default(LOGIN)\n\n  NAME= - enter pay_system name or default(GlobalMoney)\n\n ID= - enter pay_system id or default\n\n URL= - enter IP:PORT for web_requests or default(127.0.0.1:9443)\n\n";
  exit;
}

if ($ARGV[0] eq 'help') {
  print " help - man\n\n KEY= - enter pay_system account key or default(LOGIN)\n\n  NAME= - enter pay_system name or default(GlobalMoney)\n\n ID= - enter pay_system id or default\n\n URL= - enter IP:PORT for web_requests or default(127.0.0.1:9443)\n\n";
  exit;
}
my $begin_time = AXbills::Base::check_time();

my $system_name = 'Global_Money';

use_ok('Paysys');
use_ok('Paysys::systems::'.$system_name);
use_ok('Conf');
use_ok('AXbills::Base', qw/mk_unique_value parse_arguments/);
use_ok('XML::Simple');

our ($DATE, $TIME);
use AXbills::Init qw/$db $admin $users/;
use Paysys;
require Paysys::Paysys_Base;

my $Conf = Conf->new($db, $admin, \%conf);
my $attr = parse_arguments(\@ARGV);
my $url = $attr->{URL} || '127.0.0.1:9443';
my $user_login = $attr->{LOGIN} || 'test';

my $system_object = 'Paysys::systems::'.$system_name;
my $random_number = int(rand(1000));
my $Payment_system = $system_object->new($db, $admin, \%conf, {
  CUSTOM_NAME => $attr->{NAME} || '',
  CUSTOM_ID   => $attr->{ID} || '',
});

my (undef, $user_object) = main::paysys_check_user({
  EXTRA_FIELDS => {
    CONTRACT_ID   => '_SHOW',
    CONTRACT_DATE => '_SHOW',
  },
  CHECK_FIELD  => 'LOGIN',
  USER_ID      => $user_login,
});

my $fio = $user_object->{fio} || '';
my $deposit = $user_object->{deposit} || '';
my $contract_id = $user_object->{contract_id} || q{};
my $contract_date = $user_object->{contract_date} || q{};


my $account_info = $Payment_system->_make_account_info({
  CONTRACT_INFO => qq{# $contract_id $contract_date},
 });

my %test_info = ();

# checking function check with valid account
$test_info{Check}{REQUEST} = qq{<?xml version="1.0" encoding="UTF-8"?><Request>
<DateTime>2010-09-01T12:00:00</DateTime><Sign></Sign>
<Check> <ServiceId>1</ServiceId><Account>test</Account></Check></Request>};

my $status = 0;
my %status_hash = (
  '0'    => 'OK',
  '-6'   => 'Payment Exist',
  '-11', => 'Payment operation disable',
  '-300' => 'SQL Error',
  '-200' => 'User not found',
  '-79'  => 'Payment not found',
  '-80'  => 'Wrong Signature',
);

$test_info{Check}{RESPONSE} = "<Response>
<StatusCode>0</StatusCode>
<StatusDetail>$status_hash{$status}</StatusDetail>
<DateTime>$main::DATE" . 'T' . "$main::TIME</DateTime>
<Sign></Sign>
<AccountInfo>
<Login>$user_login</Login>
<Name>$fio $contract_id $contract_date</Name>
<Deposit>$deposit</Deposit>
</AccountInfo>
$account_info
</Response>";

$test_info{Check}{RESPONSE} =~ s/[\r\n]//g;

my $result = $Payment_system->proccess(
  {
    __BUFFER => $test_info{Check}{REQUEST}
  }
);
my $res = ($Payment_system->{RESPONSE} =~ /$test_info{Check}{RESPONSE}/g);
ok($res, 'OK');


#Payments
$test_info{Payment}{REQUEST} = qq{<?xml version="1.0" encoding="UTF-8"?><Request>
<DateTime>2020-02-24T12:00:00</DateTime><Sign></Sign>
<Payment><ServiceId>1</ServiceId><OrderId>$random_number</OrderId>
<Account>$user_login</Account><Amount>1</Amount>
</Payment></Request>};

$test_info{Payment}{RESPONSE} = "<Response>
<StatusCode>0</StatusCode>
<StatusDetail>$status_hash{$status}</StatusDetail>
<DateTime>$main::DATE" . 'T' . "$main::TIME</DateTime>
<Sign></Sign>
<PaymentId>\\d+</PaymentId>
</Response>";

$test_info{Payment}{RESPONSE} =~ s/[\r\n]//g;

  $result = $Payment_system->proccess(
  {
    __BUFFER => $test_info{Payment}{REQUEST}
  }
  );

 $res = ($Payment_system->{RESPONSE}=~ /$test_info{Payment}{RESPONSE}/g);
ok($res, 'OK');

#Confirm
$test_info{Confirm}{REQUEST} = qq{<?xml version="1.0" encoding="UTF-8"?><Request>
<DateTime>2020-02-24T12:00:00</DateTime><Sign></Sign>
<Confirm><ServiceId>1</ServiceId><PaymentId>126</PaymentId></Confirm>
</Request>};

$test_info{Confirm}{RESPONSE} = "<Response>
<StatusCode>0</StatusCode>
<StatusDetail>$status_hash{$status}</StatusDetail>
<DateTime>$main::DATE" . 'T' . "$main::TIME</DateTime>
<Sign></Sign>
<OrderDate>$main::DATE" . 'T' . "$main::TIME</OrderDate>
<Parameters>
<Parameter1>1</Parameter1>
</Parameters>
</Response>";

$test_info{Confirm}{RESPONSE} =~ s/[\r\n]//g;

  $result = $Payment_system->proccess(
  {
    __BUFFER => $test_info{Confirm}{REQUEST}
  }
);

  $res = ($Payment_system->{RESPONSE}  =~ /$test_info{Confirm}{RESPONSE}/g);

ok($res, 'OK');

#Cancel
$test_info{Cancel}{REQUEST} = qq{<?xml version="1.0" encoding="UTF-8"?><Request>
<DateTime>2020-02-24T12:00:00</DateTime><Sign></Sign>
<Cancel><ServiceId>1</ServiceId><PaymentId>126</PaymentId></Cancel>
</Request>};

$test_info{Cancel}{RESPONSE} = "<Response>
<StatusCode>0</StatusCode>
<StatusDetail>$status_hash{$status}</StatusDetail>
<DateTime>$main::DATE" . 'T' . "$main::TIME</DateTime>
<Sign></Sign>
<CancelDate>$main::DATE" . 'T' . "$main::TIME</CancelDate>
</Response>";

$test_info{Cancel}{RESPONSE} =~ s/[\r\n]//g;

  $result = $Payment_system->proccess(
  {
    __BUFFER => $test_info{Cancel}{REQUEST}
  }
);

  $res = ($Payment_system->{RESPONSE}  =~ /$test_info{Cancel}{RESPONSE}/g);
#AXbills::Base::_bp('res', $res, {HEADER=>1});
#print ("\n\nresponse example:\n".$test_info{Cancel}{RESPONSE});
#print ("\n\nresponse two:\n".$Payment_system->{RESPONSE});
ok($res,'OK');

1;