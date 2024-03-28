#!/usr/bin/perl
use strict;
use warnings;
use Test::More;


our ($db, $admin, %conf);
require '../libexec/config.pl'; # assunming we are in /usr/axbills/t/
use lib '../lib';
use lib '../AXbills/mysql';
use AXbills::Base qw/_bp/;
_bp(undef, undef, { SET_ARGS => { TO_CONSOLE => 1 } });

use JSON qw/decode_json encode_json/;

my $plans_count = 21 -1 ;
plan tests => $plans_count;

my $test_aid = 1;

my $ping_request = {"TYPE" => "PING"};
#my $ping_responce = {"TYPE" => "PONG"};

my $test_notification = "Test notification";

# Create new Connection
require_ok( 'AnyEvent' );
require_ok( 'AnyEvent::Socket' );
require_ok( 'AnyEvent::Handle' );
require_ok( 'AnyEvent::Impl::Perl' );

SKIP : {
  skip ('No Asterisk::AMI tests required', 1) if (!$conf{EVENTS_ASTERISK});
  require_ok( 'Asterisk::AMI' );
}

if (require_ok( 'AXbills::Sender::Browser' )){
  require AXbills::Sender::Browser;
  AXbills::Sender::Browser->import();
};

if (require_ok( 'AXbills::Backend::API' )){
  require AXbills::Backend::API;
  AXbills::Backend::API->import();
};


my AXbills::Sender::Browser $Browser = new_ok( 'AXbills::Sender::Browser' => [ \%conf ] );
my AXbills::Backend::API $api = new_ok('AXbills::Backend::API', [ \%conf ]);

can_ok( $api, 'is_connected' );
can_ok( $api, 'call' );

can_ok( $Browser, 'connected_admins' );
can_ok( $Browser, 'has_connected_admin' );
can_ok( $Browser, 'send_message' );

ok( $api->is_connected(), 'Browser connected to backend server' );
ok( $Browser->connected_admins(), 'Should have clients connected to run tests' );

SKIP_BROWSER_CLIENT_CHECK : {
  my $test_admin_connected = $Browser->has_connected_admin( $test_aid );
  skip ( 'No test admin connected', 3 ) if (!$test_admin_connected);
  ok( $test_admin_connected, 'Our test admin ' . $test_aid . ' should be connected' );
  ok( $Browser->send_message( { AID => $test_aid, MESSAGE => $test_notification } ), 'Should be able to send message' );
#  ok( $Browser->send_message( { AID => $test_aid, MESSAGE => $test_notification, NON_SAFE => 1 } ), 'Just check Instant send message' );
  
  my $ping_res = $api->call( $test_aid, $ping_request );
  ok( $ping_res && $ping_res->{TYPE} && $ping_res->{TYPE} eq 'RESULT', "Responce for ping_request should be ping_responce" );
  
  my $command_request1 = $api->json_request( {
    MESSAGE => {
      TYPE    => 'COMMAND',
      AID     => 1,
#      PROGRAM => '/usr/bin/mysqldump --verbose=1 axbills users > /tmp/axbills_users.sql',
      PROGRAM => 'ping',
      PROGRAM_ARGS => [ '-c 3', '-q', '192.168.1.1' ],
      ARGS => {
        timeout => 10
      }
    }
  });

  
  ok ($command_request1, 'Call command request' );
  
#  my $message_callback = sub {
#    ok( 1, 'Should be able to send ASYNC message' );
#  };
#  $Browser->send_message( { AID => $test_aid, MESSAGE => $test_notification, ASYNC => $message_callback });
  

  #Extensive ping
#  my $count = 10000;
#  while($count--){
#    ok( $Browser->send_message( { AID => $test_aid, MESSAGE => $test_notification } ), 'Should be able to send message' );
#  };
}


# TODO: check asterisk connection

done_testing();