package AXbills::Backend::Plugin::Websocket::Admin;
use strict;
use warnings FATAL => 'all';
use parent 'AXbills::Backend::Plugin::Websocket::Client';

our ($admin, $Log);
use AXbills::Backend::Defs;

#FIXME: Do we really need this test admins?
my %cache = (
  aid_by_sid => {
    'testadmin1' => 1,
    'testadmin2' => 2,
  }
);

#**********************************************************
=head2 authenticate($chunk)

  Authentificate admin by cookies

=cut
#**********************************************************
sub authenticate {
  my ($chunk) = @_;

  if ($chunk && $chunk =~ /^Cookie: .*$/m) {
    my (@sids) = $chunk =~ /sid=([a-zA-Z0-9]*)/gim;

    return -1 unless (scalar @sids);
    my $aid = undef;
    foreach my $sid (@sids) {
      $Log->debug("Will try to authentificate admin with sid $sid") if (defined $Log);

      # Try to retrieve from cache
      if ($aid = $cache{aid_by_sid}->{$sid}) {
        $Log->debug("cache hit $sid") if (defined $Log);
        return $aid;
      }

      my $admin_with_this_sid = $admin->online_info({ SID => $sid, COLS_NAME => 1 });

      if ($admin->{TOTAL}) {
        $aid = $admin_with_this_sid->{AID};
        $cache{aid_by_sid}->{$sid} = $aid;
        return $aid;
      }
    }
  }
  elsif ($chunk && $chunk =~ /(?<=\bADMINSID:\s)(\w+)/gim) {
    my $aid = undef;

    # Try to retrieve from cache
    if ($aid = $cache{aid_by_sid}->{$1}) {
      $Log->debug("cache hit $1") if (defined $Log);
      return $aid;
    }

    my $admin_with_this_sid = $admin->online_info({ SID => $1, COLS_NAME => 1 });
    if ($admin->{TOTAL}) {
      $aid = $admin_with_this_sid->{AID};
      $cache{aid_by_sid}->{$1} = $aid;
      return $aid;
    }
  }

  return -1;
}

1;
