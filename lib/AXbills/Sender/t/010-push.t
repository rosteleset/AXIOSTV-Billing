#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use lib '../';
use lib '../../../';
use lib '../../../../';
use lib '../../../../AXbills/mysql';

use AXbills::Base qw/_bp/;

our %conf;
require 'libexec/config.pl';

if (!$conf{PUSH_ENABLED}){
  plan skip_all => 'Push is not enabled on this host';
}
else {
  plan tests => 6
}

use AXbills::Sender::Core;
use AXbills::SQL;
use Admins;

my $db = AXbills::SQL->connect($conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd},
  { CHARSET => ($conf{dbcharset}) ? $conf{dbcharset} : undef });
my $admin = Admins->new($db, \%conf);
$admin->info($conf{SYSTEM_ADMIN_ID} || '2', { IP => '127.0.0.1' });

my $Sender = AXbills::Sender::Core->new($db, $admin, \%conf, {
    SENDER_TYPE => 'Push'
  });


my $CURL_DEBUG = 5;

my $google_sent_normal = $Sender->send_message({
  AID     => 1,
  MESSAGE => 'Google Test1',
  DEBUG   => $CURL_DEBUG
});
ok($google_sent_normal, 'Google Sent normal Push message');

my $google_sent_wrong = $Sender->send_message({
  TO_ADDRESS =>
  'https://android.googleapis.com/gcm/send/edGuPMVkmpY:APA91bHBl9Bh1UcXA5zj9dwtNGsxSMusw6eYVO2HVWjpYt_OkXPJcyfrAZpDda-6JwWGi0hWFMV-XMOCABtcOPsk81uPII8LImWdSVzkzxeIoiEWKAZtrlRT6tT3504GACKw6u6zf9I'
  ,
  MESSAGE    => 'Google Test2',
  DEBUG      => $CURL_DEBUG,
});
ok(!$google_sent_wrong, 'Google Send with wrong endpoint returns error');

my $google_sent_empty = $Sender->send_message({
  TO_ADDRESS => 'https://android.googleapis.com/gcm/send/',
  MESSAGE    => 'Google Test3',
  DEBUG      => $CURL_DEBUG,
});
ok(!$google_sent_empty, 'Google Send with empty id returns error');

my $mozilla_sent_normal = $Sender->send_message({
  UID     => 2,
  MESSAGE => 'Mozilla UID 2 Test1',
  DEBUG   => $CURL_DEBUG,
});
ok($mozilla_sent_normal, 'Firefox Sent normal Push message');
#
my $mozilla_sent_wrong = $Sender->send_message({
  TO_ADDRESS =>
  'https://updates.push.services.mozilla.com/wpush/v1/gAAAAABY-Oijeuri6m8G3zqFsA90uROfy9jSQl1gZWmxwlx74Mk_AJTnMvbBYPh1sgDSEUHPy785Ns3Uoj3JXmj3REIxyFE7cP0TZEXTDxoidwgnwOFic6wGXooQ81-CFLR3_w5FDYg'
  ,
  MESSAGE    => 'Mozilla UID 2 Test2',
  DEBUG      => $CURL_DEBUG,
});
ok(!$mozilla_sent_wrong, 'Firefox Send with wrong endpoint returns error');

my $mozilla_sent_empty = $Sender->send_message({
  TO_ADDRESS => 'https://updates.push.services.mozilla.com/wpush/v1/',
  MESSAGE    => 'Mozilla UID 2 Test3',
  DEBUG      => $CURL_DEBUG,
});
ok(!$mozilla_sent_empty, 'Firefox Send with empty id returns error');

done_testing();

