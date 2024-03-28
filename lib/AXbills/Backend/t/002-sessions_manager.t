#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 12;

use lib '../../../';

our ($base_dir, %conf, $debug);
require 'libexec/config.pl';
$debug = 0;

use AnyEvent::Handle;
use AXbills::Base qw/_bp/;

use AXbills::Base qw/mk_unique_value/;
if ( use_ok('AXbills::Backend::Plugin::Websocket::SessionsManager') ) {
  require AXbills::Backend::Plugin::Websocket::SessionsManager;
  AXbills::Backend::Plugin::Websocket::SessionsManager->import();
};


my AXbills::Backend::Plugin::Websocket::SessionsManager $adminSessionManager
  = new_ok('AXbills::Backend::Plugin::Websocket::SessionsManager',
  [ { CLIENT_CLASS => 'Admin' } ]);

#**********************************************************
=head2 get_new_socket()
  
=cut
#**********************************************************
sub get_new_socket {
  return mk_unique_value(10);
}

my $admin_id = 1;
my $socket_id = get_new_socket();
open(my $fh, '>', '/tmp/test.handle');
my $handle = AnyEvent::Handle->new(fh => $fh);

ok $adminSessionManager->save_handle($handle, $socket_id, $admin_id),
  'Saved handle (Checking it will create new Admin for sessions)';
ok $adminSessionManager->has_client_with_id($admin_id), 'Created Admin for test session';
ok $adminSessionManager->has_client_with_socket_id($socket_id), 'Found admin by socket_id';
ok $adminSessionManager->get_handle_by_socket_id($socket_id) eq $handle, 'Handle was saved';
ok $adminSessionManager->remove_session_by_socket_id($socket_id), 'Handle was removed';

my $second_admin_id = 2;
my $second_socket_id = get_new_socket();
open(my $fh2, '>', '/tmp/test.handle2');
my $second_handle = AnyEvent::Handle->new(fh => $fh2);

ok $adminSessionManager->save_handle($second_handle, $second_socket_id, $second_admin_id),
  'Saved handle (Checking it will create new Admin for sessions)';
ok $adminSessionManager->has_client_with_id($second_admin_id), 'Created Admin for test session';
ok $adminSessionManager->has_client_with_socket_id($second_socket_id), 'Found admin by socket_id';
ok $adminSessionManager->get_handle_by_socket_id($second_socket_id) eq $second_handle, 'Handle was saved';
ok $adminSessionManager->remove_session_by_socket_id($second_socket_id), 'Handle was removed';

# Teardown
unlink '/tmp/test.handle';
unlink '/tmp/test.handle2';

done_testing();

