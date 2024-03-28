#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use AXbills::Base qw/_bp/;

my $test_message_id = 69;
require Msgs::Messaging;

our ($db, $admin, %conf);
if (!$conf{TELEGRAM_TOKEN}){
  plan skip_all => 'Telegram token is not specified';
}
else {
  plan tests => 7
}

ok($db && $admin && (scalar %conf), 'Script got global params');

# TODO: Check message exists

use_ok('AXbills::Sender::Core');
my $Sender = new_ok('AXbills::Sender::Core',
  [
    $db, $admin, \%conf,
    {
      SENDER_TYPE => 'Telegram'
    }
  ]
);

#for my $ch ( 1 .. 5 ) {
#  send_plain("TEST SUBJECT $ch", "TEST MESSAGE $ch");
#}

my %admin_reply = (
  AID        => 1,
  REPLY_TEXT => 'Test admin reply to user text',
  SUBJECT    => 'Sender Tests',
);
my $admin_sent = msgs_admin_reply($test_message_id, \%admin_reply);
ok($admin_sent, 'Sent reply as admin');

my %user_reply = (
  UID        => 7,
  REPLY_TEXT => 'Test user to subject reply text',
  SUBJECT    => 'Sender Tests',
  STATE      => 0,
);

my $user_sent = msgs_user_reply($test_message_id, \%user_reply);
ok($user_sent, 'user->admin');

my $lang_sent = msgs_user_reply($test_message_id, { %user_reply, REPLY_TEXT => '_{REPLY}_' });
ok($lang_sent, 'user->admin. localized REPLY -> _{REPLY}_');

my %inner_reply = (
  %admin_reply,
  AID             => 4,
  REPLY_TEXT      => 'SYSTEM ADMIN->admin',
  REPLY_INNER_MSG => 1
);

my $inner_sent = msgs_admin_reply($test_message_id, \%inner_reply);
ok($inner_sent, 'ADMIN->admin. Can sent reply as inner. admin');

done_testing();

sub send_plain {
  my ($subject, $text) = @_;
  
  my $send_trivial_message = $Sender->send_message({
    SUBJECT => $subject,
    MESSAGE => $text,
    AID     => 1
  });
  
  ok($send_trivial_message, "Can send few messages in a row via telegram");
}
