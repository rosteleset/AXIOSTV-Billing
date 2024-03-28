#!/usr/bin/perl -w

=head1 NAME

 Paysys Liqpay tests

=cut

use strict;
use warnings;
use Test::More tests => 5;
use Data::Dumper;

our (%FORM, %LIST_PARAMS, %functions, %conf, $html, %lang, @_COLORS, $base_dir, $db, $admin);

BEGIN {
  our $libpath = '../../../../';
  unshift(@INC, $libpath);
  unshift(@INC, $libpath . 'lib/');
  unshift(@INC, $libpath . 'libexec/');
  unshift(@INC, $libpath . 'AXbills/');
  unshift(@INC, $libpath . 'AXbills/modules/');
  unshift(@INC, $libpath . "AXbills/mysql/");
}

my $begin_time = AXbills::Base::check_time();
do "libexec/config.pl";
$conf{language} = 'english';
do $base_dir . "/language/$conf{language}.pl";
do $base_dir . "/AXbills/modules/Paysys/lng_$conf{language}.pl";

use AXbills::Base qw(check_time mk_unique_value);
Test::More::use_ok('Paysys');
Test::More::use_ok('Paysys::systems::Liqpay');
Test::More::use_ok('Conf');
Test::More::use_ok('AXbills::Base', qw/mk_unique_value check_time/);
Test::More::use_ok('Paysys::t::Init_t');

my $Conf = Conf->new($db, $admin, \%conf);
my $Paysys = Paysys->new($db, $admin, \%conf);
my $argv = AXbills::Base::parse_arguments( \@ARGV );

my $user_id = $argv->{UID} || '1';
my $random_number = int(rand(100000));

my $Liqpay = Paysys::systems::Liqpay->new($db, $admin, \%conf, {
  CUSTOM_NAME => $argv->{CUSTOM_NAME} || '',
  CUSTOM_ID   => $argv->{CUSTOM_ID} || '',
  lang        => \%lang
});

if($argv->{HOTSPOT} && $argv->{HOTSPOT} == 1){
  $user_id = $random_number;
}

$Paysys->add({
  SYSTEM_ID      => 62,
  SUM            => 1.00,
  UID            => $user_id,
  IP             => '127.0.0.1',
  TRANSACTION_ID => "Liqpay:$random_number",
  INFO           => "Test payment",
  PAYSYS_IP      => "127.0.0.1",
  STATUS         => 1,
});

our @requests = (
  {
    name    => 'PAY',
    request => qq/{"action": "hold",
	"payment_id": 976121473,
	"status": "hold_wait",
	"version": 3,
	"type": "hold",
	"paytype": "privat24",
	"public_key": "i69039701232",
	"acq_id": 414963,
	"order_id": "Liqpay:$random_number",
	"liqpay_order_id": "80QNTUA81552846436143063",
	"description": "PaymentId $random_number, UID $user_id;",
	"sender_phone": "380996506807",
	"sender_card_mask2": "516875*70",
	"sender_card_bank": "pb",
	"sender_card_type": "mc",
	"sender_card_country": 804,
	"amount": 1.00,
	"currency": "UAH",
	"sender_commission": 0.0,
	"receiver_commission": 0.68,
	"agent_commission": 0.0,
	"amount_debit": 24.71,
	"amount_credit": 24.71,
	"commission_debit": 0.0,
	"commission_credit": 0.68,
	"currency_debit": "UAH",
	"currency_credit": "UAH",
	"sender_bonus": 0.0,
	"amount_bonus": 0.0,
	"authcode_debit": "069344",
	"rrn_debit": "001164584057",
	"mpi_eci": "7",
	"is_3ds": false,
	"language": "ru",
	"create_date": 1552846436151,
	"transaction_id": 976121473}
   /,
    result  => qq/{"result": "ok",
	"action": "hold",
	"payment_id": 976121473,
	"status": "success",
	"version": 3,
	"type": "hold",
	"paytype": "privat24",
	"public_key": "i69039701232",
	"acq_id": 414963,
	"order_id": "Liqpay:$random_number",
	"liqpay_order_id": "80QNTUA81552846436143063",
	"description": "PaymentId $random_number, UID $user_id;",
	"sender_phone": "380996506807",
	"sender_card_mask2": "516875*70",
	"sender_card_bank": "pb",
	"sender_card_type": "mc",
	"sender_card_country": 804,
	"amount": 24.0,
	"currency": "UAH",
	"sender_commission": 0.0,
	"receiver_commission": 0.66,
	"agent_commission": 0.0,
	"amount_debit": 24.0,
	"amount_credit": 24.0,
	"commission_debit": 0.0,
	"commission_credit": 0.66,
	"currency_debit": "UAH",
	"currency_credit": "UAH",
	"sender_bonus": 0.0,
	"amount_bonus": 0.0,
	"authcode_debit": "069344",
	"rrn_debit": "001164584057",
	"mpi_eci": "7",
	"is_3ds": false,
	"language": "ru",
	"create_date": 1552846436151,
	"end_date": 1552846439818,
	"completion_date": 1552846439783,
	"transaction_id": 976121473}
  /
  },
    {
      name    => 'PAY',
      request => qq/{"payment_id":1699007412,"action":"pay","status":"success","version":3,"type":"buy","paytype":"card","public_key":"i8317458350","acq_id":414963,"order_id":"Liqpay:80160743","liqpay_order_id":"T13IBLW71625663549706863","description":"Payments ID: 80160743 FIO : Ковбасюк Леонід Іванович;  UID: 158102; ","sender_card_mask2":"516874*90","sender_card_bank":"pb","sender_card_type":"mc","sender_card_country":804,"ip":"188.191.235.122","card_token":"58D19A71E802334948F1FFC7E6626DFC6F424DDA","amount":1.04,"currency":"UAH","sender_commission":0.0,"receiver_commission":0.03,"agent_commission":0.0,"amount_debit":1.04,"amount_credit":1.04,"commission_debit":0.0,"commission_credit":0.03,"currency_debit":"UAH","currency_credit":"UAH","sender_bonus":0.0,"amount_bonus":0.0,"authcode_debit":"067175","rrn_debit":"002791387605","mpi_eci":"7","is_3ds":false,"language":"en","create_date":1625663549710,"end_date":1625663552170,"transaction_id":1699007412}/,
      result => qq{}
    }
);
my %hold_wait_hash = ();

$hold_wait_hash{data} = AXbills::Base::encode_base64($requests[0]->{request});
print $Liqpay->proccess(\%hold_wait_hash);

print "\nTest time: " . AXbills::Base::gen_time($begin_time) . "\n\n";

1;