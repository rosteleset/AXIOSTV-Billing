package AXbills::Backend::Plugin::Websocket;
use strict;
use warnings FATAL => 'all';

our (%conf);

use AXbills::Backend::Plugin::BasePlugin;
use parent 'AXbills::Backend::Plugin::BasePlugin';

use AXbills::Backend::Log;
our AXbills::Backend::Log $Log;

# Localizing global variables
use AXbills::Backend::Defs;

use AXbills::Backend::Plugin::Websocket::API;
use AXbills::Backend::Plugin::Websocket::SessionsManager;
use AXbills::Backend::Utils qw/json_decode_safe json_encode_safe/;

use Protocol::WebSocket::Handshake::Server;
use Protocol::WebSocket::Frame;

our AXbills::Backend::Plugin::Websocket::SessionsManager $adminSessions;
our AXbills::Backend::Plugin::Websocket::SessionsManager $userSessions;

my $OPCODE_CLOSE = 0x8;
my $OPCODE_PING = 0x9;
my $OPCODE_PONG = 0xA;

my $api;

#**********************************************************
=head2 new($conf) - constructor for AXbills::Backend::Plugin::Websocket

=cut
#**********************************************************
sub new {
  my ($class, $db, $admin, $CONF) = @_;

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $CONF,
  };

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 init($attr)

  Arguments:
     $attr - reserved
    
  Returns:
    1
  
=cut
#**********************************************************
sub init {
  my $self = shift;
  my ($attr) = @_;

  # Starting websocket server
  $Log->info("Starting WebSocket server");

  $self->{session_managers} = {
    admin => AXbills::Backend::Plugin::Websocket::SessionsManager->new({ CLIENT_CLASS => 'Admin' }),
    user  => AXbills::Backend::Plugin::Websocket::SessionsManager->new({ CLIENT_CLASS => 'User' })
  };

  $adminSessions = $self->{session_managers}->{admin};
  $userSessions = $self->{session_managers}->{user};

  AnyEvent::Socket::tcp_server('127.0.0.1', $conf{WEBSOCKET_PORT} || 19443, sub {
    $self->new_websocket_client(@_, 'ADMIN');
  });

  AnyEvent::Socket::tcp_server('127.0.0.1', $conf{USER_WEBSOCKET_PORT} || 19445, sub {
    $self->new_websocket_client(@_, 'USER');
  });

  $api = AXbills::Backend::Plugin::Websocket::API->new($self->{session_managers});

  return $api;
}

#**********************************************************
=head2 new_websocket_client()

=cut
#**********************************************************
sub new_websocket_client {
  my $self = shift;
  my ($socket_pipe_handle, $host, $port, $client) = @_;

  my %client_params_list = (
    ADMIN => {
      sessions => $adminSessions,
      id       => 'aid',
      name     => 'Admin'
    },
    USER  => {
      sessions => $userSessions,
      id       => 'uid',
      name     => 'User'
    }
  );

  my $client_params = $client_params_list{$client};

  my $socket_id = "$host:$port";
  $Log->debug("$client_params->{name} connection : $socket_id");

  my $handshake = Protocol::WebSocket::Handshake::Server->new;

  my $handle = AnyEvent::Handle->new(
    fh       => $socket_pipe_handle,
    no_delay => 1
  );

  # On message
  $handle->on_read(
    sub {
      my AnyEvent::Handle $this_client_handle = shift;

      # Read and clear read buffer
      my $chunk = $this_client_handle->{rbuf};
      $this_client_handle->{rbuf} = undef;

      # If it is handshake, do all protocol related stuff
      if (!$handshake->is_done) {
        $self->_do_handshake($this_client_handle, $chunk, $handshake);
        my $identifier = ($client eq 'ADMIN') ? AXbills::Backend::Plugin::Websocket::Admin::authenticate($chunk) :
          AXbills::Backend::Plugin::Websocket::User::authenticate($chunk);

          if ($identifier == -1) {
            $this_client_handle->push_shutdown;
          }
          else {
            $Log->debug("Authorized $client_params->{name} $identifier ");
            $client_params->{sessions}->save_handle($handle, $socket_id, $identifier);
          }

        return;
      }
      else {
        $self->on_websocket_message($this_client_handle, $socket_id, $chunk);
      }
    }
  );

  # On close
  $handle->on_eof(
    sub {
      # Try to do it "good way"
      unless ($client_params->{sessions}->remove_session_by_socket_id($socket_id)) {
        # And otherwise kick it's face
        $handle->destroy;
        undef $handle;
      }
    }
  );

  $handle->on_error(
    sub {
      my AnyEvent::Handle $read_handle = shift;

      return unless (defined $read_handle);

      $Log->debug("Error happened with $client_params->{name} $socket_id ");

      $read_handle->push_shutdown;
      $read_handle->destroy;

      undef $handle;
    }
  )
}

#**********************************************************
=head2 on_websocket_message($read_handle)

=cut
#**********************************************************
sub on_websocket_message {
  my $self = shift;
  my ($this_client_handle, $socket_id, $chunk) = @_;

  my $frame = Protocol::WebSocket::Frame->new;

  $frame->append($chunk);

  while (my $message = $frame->next) {
    my $opcode = $frame->opcode;

    # Client breaks connection
    if ($opcode == $OPCODE_CLOSE) {
      $adminSessions->remove_session_by_socket_id($socket_id, "Admin $socket_id breaks connection");
      $userSessions->remove_session_by_socket_id($socket_id, "User $socket_id breaks connection");
      return;
    };

    if ($opcode == $OPCODE_PING || $opcode == $OPCODE_PONG) {
      # Todo treat as alive
      return;
    }

    my $decoded_message = json_decode_safe($message);

    if (!$decoded_message) {
      $Log->debug("Bad JSON");
      return;
    }

    if (defined $decoded_message && ref $decoded_message eq 'HASH' && $decoded_message->{TYPE}) {
      if ($decoded_message->{TYPE} eq 'CLOSE_REQUEST') {
        $self->drop_client($socket_id, 'by client request');
      }
      elsif ($decoded_message->{TYPE} eq 'PONG') {
        # Do nothing TODO: Treat as alive
        return;
      }
      elsif ($decoded_message->{TYPE} eq 'RESPONSE') {
        # Do nothing TODO: Treat as alive
        return;
      }
      else {
        my %response;

        # TODO: define message handlers for types
        if ($decoded_message->{TYPE} eq 'PING') {
          %response = (DATA => 'RESPONSE', TYPE => 'PONG');
        }
        else {
          %response = (DATA => $decoded_message);
        }

        my $response_text = json_encode_safe(\%response);

        $this_client_handle->push_write($frame->new($response_text)->to_bytes);
      }
    }
  }
}

#**********************************************************
=head2 drop_client($socket_id, $reason)

=cut
#**********************************************************
sub drop_client {
  my $self = shift;
  my ($socket_id, $reason) = @_;

  foreach (values %{$self->{session_managers}}) {
    my AXbills::Backend::Plugin::Websocket::SessionsManager $sessions_manager = $_;
    if ($sessions_manager->has_client_with_socket_id($socket_id)) {
      $sessions_manager->remove_session_by_socket_id($socket_id, $reason);
      last;
    }
  }
}

#**********************************************************
=head2 drop_all_clients($reason)

=cut
#**********************************************************
sub drop_all_clients {
  my $self = shift;
  my ($reason) = @_;

  foreach (values %{$self->{session_managers}}) {
    my AXbills::Backend::Plugin::Websocket::SessionsManager $sessions_manager = $_;
    $sessions_manager->drop_all_clients($reason);
  }

  return 1;
}

#**********************************************************
=head2 _do_handshake()

=cut
#**********************************************************
sub _do_handshake {
  my $self = shift;
  my ($this_client_handle, $chunk, $handshake) = @_;

  $handshake->parse($chunk);

  if ($handshake->is_done) {
    $this_client_handle->push_write($handshake->to_string);
    return 1;
  }

  return 0;
}

DESTROY {
  if ($Log) {

    my $caller = q{}; #join(', ', caller());
    my ($package, $filename, $line, $subroutine, $hasargs, $wantarray, $evaltext, $is_require, $hints, $bitmask, $hinthash);
    my $i = 1;
    my @r = ();
    while (@r = caller($i)) {
      ($package, $filename, $line, $subroutine, $hasargs, $wantarray, $evaltext, $is_require, $hints, $bitmask, $hinthash) = @r;
      $caller .= "$filename:$line $subroutine\n";
      $i++;
    }

    $Log->info("\n\nWebsocket server stopped/ $caller");
    $Log->info($@);
  }
}

1;
