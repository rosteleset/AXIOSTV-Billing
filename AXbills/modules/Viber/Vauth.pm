=head1 Vauth

  Viber auth

=cut

use strict;
use warnings FATAL => 'all';

our (
  $Contacts,
  $Users,
  $admin,
  $Bot
);

#**********************************************************
=head2 get_uid($user_id)

=cut
#**********************************************************
sub get_uid {
  my ($user_id) = @_;
  my $list = $Contacts->contacts_list({
    TYPE  => 5,
    VALUE => $user_id,
    UID   => '_SHOW',
  });

  return 0 if ($Contacts->{TOTAL} < 1);

  return $list->[0]->{uid};
}

#**********************************************************
=head2 get_aid($user_id)

=cut
#**********************************************************
sub get_aid {
  my ($user_id) = @_;

  my $list = $admin->admins_contacts_list({
    TYPE  => 5,
    VALUE => $user_id,
    AID   => '_SHOW',
  });

  return 0 if ($admin->{TOTAL} < 1);

  return $list->[0]->{aid};
}

#**********************************************************
=head2 subscribe($message)

=cut
#**********************************************************
sub subscribe {
  my ($message) = @_;
  my ($type, $sid) = $message->{context} =~ m/^([ua])_([a-zA-Z0-9]+)/;

  if ($type && $sid && $type eq 'u') {
    my $uid = $Users->web_session_find($sid);
    if ($uid) {
      my $list = $Contacts->contacts_list({
        TYPE  => 5,
        VALUE => $message->{user}{id},
      });

      if ( !$Contacts->{TOTAL} || scalar (@{$list}) == 0 ) {
        $Contacts->contacts_add({
          UID      => $uid,
          TYPE_ID  => 5,
          VALUE    => $message->{user}{id},
          PRIORITY => 0,
        });
      }
    }
  }
  elsif ($type && $sid && $type eq 'a') {
    $admin->online_info({SID => $sid});
    my $aid = $admin->{AID};
    if ( $aid ) {
      my $list = $admin->admins_contacts_list({
        TYPE  => 5,
        VALUE => $message->{user}{id},
      });

      if ( !$admin->{TOTAL} || scalar (@{$list}) == 0 ) {
        $admin->admin_contacts_add({
          AID      => $aid,
          TYPE_ID  => 5,
          VALUE    => $message->{user}{id},
          PRIORITY => 0,
        });
        $Bot->send_message({
          text => "Welcome admin.",
          type => 'text'
        });
      }
    }
    exit 0;
  }

  return 1;
}

1;
