package AXbills::Backend::Plugin::Websocket::SessionsManager;
use strict;
use warnings FATAL => 'all';

use AXbills::Backend::Plugin::Websocket::Session;
use Module::Load qw/load/;

use AXbills::Backend::Log;
our AXbills::Backend::Log $Log;

# use Contacts;

# our ($admin, $db, %conf);

# Localizing global variables
use AXbills::Backend::Defs;

#**********************************************************
=head2 new($db, $admin, $CONF)

  Arguments:

  Returns:
    object
    
=cut
#**********************************************************
sub new {
  my $class = shift;
  my ($attr) = @_;
  die "No client class defined " unless ($attr->{CLIENT_CLASS});

  my $self = {
    clients     => {},
    client_name => $attr->{CLIENT_CLASS},
  };

  # $self->{Contacts} = Contacts->new($db, $admin, \%conf);

  $self->{client_class} = 'AXbills::Backend::Plugin::Websocket::' . $attr->{CLIENT_CLASS};
  load $self->{client_class};

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 save_handle($self, $handle, $socket_id, $id)

=cut
#**********************************************************
sub save_handle {
  my $self = shift;
  my ($handle, $socket_id, $id) = @_;

  if (!exists $self->{clients}->{$id}) {
    $self->{clients}->{$id} = $self->{client_class}->new($id);
  }

  # if ($self->{client_name} eq 'User') {
  #   my $list = $self->{Contacts}->contacts_list({ UID => $id, TYPE => 20 });
  #
  #   $self->{Contacts}->contacts_add({
  #     TYPE_ID => 20,
  #     VALUE   => $socket_id,
  #     UID     => $id,
  #   }) if ($list && !scalar(@{$list}));
  # }

  $self->{session_handler_for_socket_id}->{$socket_id} = $self->{clients}->{$id};

  $Log->debug(
    " $self->{client_class}. Saved handle $socket_id for $id. Total : " . scalar(keys %{$self->{clients}}));

  $self->{clients}->{$id}->save_handle($handle, $socket_id);

  return 1;
}

#**********************************************************
=head2 get_handle_by_socket_id($socket_id)

  Arguments:
    $socket_id -
    
  Returns:
  
=cut
#**********************************************************
sub get_handle_by_socket_id {
  my $self = shift;
  my ($socket_id) = @_;

  if (my $handler = $self->_find_sessions_handler_for_socket_id($socket_id)) {
    return $handler->get_handle_for($socket_id);
  }

  return 0;
}

#@returns AXbills::Backend::Plugin::Websocket::Client
#**********************************************************
=head2 _find_sessions_handler_for_socket_id($socket_id) -

  Arguments:
    $socket_id -
    
  Returns:
    
    
=cut
#**********************************************************
sub _find_sessions_handler_for_socket_id {
  my $self = shift;
  my ($socket_id) = @_;

  return $self->{session_handler_for_socket_id}->{$socket_id} || 0;
}

#**********************************************************
=head2 remove_session_by_socket_id($socket_id, $reason)

  Destroy and remove known client

=cut
#**********************************************************
sub remove_session_by_socket_id {
  my $self = shift;
  my ($socket_id, $reason) = @_;

  my $sessions_handler = $self->_find_sessions_handler_for_socket_id($socket_id);

  return 0 if (!$sessions_handler);

  $sessions_handler->remove_handle($socket_id, $reason);
  delete $self->{session_handler_for_socket_id}->{$socket_id};

  # if ($self->{client_name} eq 'User') {
  #   $self->{Contacts}->contacts_del({
  #     TYPE_ID => 20,
  #     VALUE   => $socket_id,
  #   });
  # }

  return 1;
}

#**********************************************************
=head2 has_client_with_id($id)

  Arguments:
     $id - unique client identifier
    
  Returns:
    boolean
    
=cut
#**********************************************************
sub has_client_with_id {
  my $self = shift;
  my ($id) = @_;

  return exists $self->{clients}->{$id};
}

#**********************************************************
=head2 has_client_with_socket_id($socket_id)

  Arguments:
    $soket_id -
    
  Returns:
    
    
=cut
#**********************************************************
sub has_client_with_socket_id {
  my $self = shift;
  my ($socket_id) = @_;

  return $self->_find_sessions_handler_for_socket_id($socket_id);
}

#**********************************************************
=head2 get_client_for_id($id) - returns Client object for given id

  Arguments:
    $id -
    
  Returns:
    AXbills::Backend::Plugin::Websocket::Client
    
=cut
#**********************************************************
#@returns AXbills::Backend::Plugin::Websocket::Client
sub get_client_for_id {
  my $self = shift;
  my ($id) = @_;

  return 0 if (!$id);

  return $self->{clients}->{$id};
}

#**********************************************************
=head2 get_all_clients()

=cut
#**********************************************************
sub get_all_clients {
  my $self = shift;

  return [ values %{$self->{clients}} ];
}

#**********************************************************
=head2 get_client_ids() -

  Arguments:
     -
    
  Returns:
    
    
=cut
#**********************************************************
sub get_client_ids {
  my $self = shift;

  return [ keys %{$self->{clients}} ];
}

#**********************************************************
=head2 drop_all_clients($reason)

=cut
#**********************************************************
sub drop_all_clients {
  my $self = shift;
  my ($reason) = @_;

  foreach (values %{$self->{clients}}) {
    $_->kill($reason) if (defined $_);
  }
}

1;
