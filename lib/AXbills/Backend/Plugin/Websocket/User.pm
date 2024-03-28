package AXbills::Backend::Plugin::Websocket::User;
use strict;
use warnings FATAL => 'all';
use parent 'AXbills::Backend::Plugin::Websocket::Client';

our ($Log, $db, $admin, %conf);

use AXbills::Backend::Defs;
use Users;

my Users $user = Users->new($db, $admin, \%conf);

my %cache = (
  uid_by_sid => {}
);

#**********************************************************
=head2 authenticate($chunk)

  Authentificate admin by cookies

=cut
#**********************************************************
sub authenticate {
  my ($chunk) = @_;

  if ($chunk && $chunk =~ /^Cookie: .*$/m) {
    # TODO LOGIN WITH Cookie
    return -1;
  }
  elsif ($chunk && $chunk =~ /(?<=\bUSERSID:\s)(\w+)/gim) {
    my $uid = undef;

    if ($uid = $cache{uid_by_sid}->{$1}) {
      $Log->debug("cache hit $1") if (defined $Log);
      return $uid;
    }

    my $user_with_this_sid = $user->web_session_info({ SID => $1 });

    if ($user->{TOTAL}) {
      $uid = $user_with_this_sid->{UID};
      $cache{uid_by_sid}->{$1} = $uid;
      return $uid;
    }
  }

  return -1;
}

1;
