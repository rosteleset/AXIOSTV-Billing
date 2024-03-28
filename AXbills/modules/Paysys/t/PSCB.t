#!/usr/bin/perl -w

=head1 NAME

 Paysys tests

=cut

use strict;
use warnings;
use Test::More tests => 10;
use Data::Dumper;

our (%FORM, %LIST_PARAMS, %functions, %conf, $html, %lang, @_COLORS, );

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
Test::More::use_ok('Paysys::systems::PSCB');
Test::More::use_ok('Conf');
Test::More::use_ok('AXbills::Base', qw/mk_unique_value encode_base64 decode_base64/);
Test::More::use_ok('Crypt::ECB');
#Test::More::use_ok('MIME::Base64');
Test::More::use_ok('Digest::MD5');
Test::More::use_ok('JSON');

use Digest::MD5 qw[md5];
use AXbills::Init qw/$db $admin $users/;
use Paysys;

my $json = JSON->new->allow_nonref;
my $Conf = Conf->new($db, $admin, \%conf);
my $user_id = $ARGV[0] || '1';

my $random_number = int(rand(100000));
my $PSCB = Paysys::systems::PSCB->new($db, $admin, \%conf, {});

my $Paysys = Paysys->new($db, $admin, \%conf);
#Add paysys
$Paysys->add(
  {
    SYSTEM_ID      => 132,
    SUM            => 1,
    UID            => $user_id,
    IP             => $ENV{'REMOTE_ADDR'},
    TRANSACTION_ID => "PSCB:$random_number",
    INFO           => "Test Payment",
#    PAYSYS_IP      => "$ENV{'REMOTE_ADDR'}",
    STATUS         => 1
  }
);

if(!$Paysys->{errno}){
  Test::More::ok(1 == 1, "Payment starterd");
}

my $json_payment = qq/{
 "payments": [
  {
    "orderId": "$random_number",
    "showOrderId": "ЗаказX123",
    "paymentId": "12345",
    "marketPlace": "23",
    "paymentMethod": "ac",
    "state": "end",
    "stateDate": "2013-11-25T18:14:44.931+04:00",
    "amount": 1.00
  }
  ]
}/;

my $key = Digest::MD5::md5($conf{PAYSYS_PSCB_SECRET_KEY});

# Сам алгоритм. см. https://metacpan.org/pod/Crypt::ECB
my $cipher = Crypt::ECB->new({
  cipher  => 'Rijndael',
  padding => 'standard',
  key     => $key,
});

# Base64 кодированный результат шифрования
my $encrypted64 = AXbills::Base::encode_base64($cipher->encrypt($json_payment));
# Он же декодированный
my $decrypted = $cipher->decrypt(AXbills::Base::decode_base64($encrypted64));

# Проверка результата
#print  'Encrypted: ' . $encrypted64;
#print  'Decrypted: ' . $decrypted;
#print "$json_payment eq $decrypted => " . ($json_payment eq $decrypted);

Test::More::ok($json_payment eq $decrypted, "Crypting works fine");

my $result = $PSCB->proccess({ __BUFFER => $encrypted64, test => 1 });
my $res = $json->decode($result);

Test::More::ok($res->[0]{orderID} == $random_number && $res->[0]{action} eq 'CONFIRM', "Payment Done");

print "\nTest time: " . AXbills::Base::gen_time($begin_time) . "\n\n";