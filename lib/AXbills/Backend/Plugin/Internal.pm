package AXbills::Backend::Plugin::Internal;
use strict;
use warnings FATAL => 'all';

use AXbills::Backend::Plugin::BasePlugin;
use parent 'AXbills::Backend::Plugin::BasePlugin';

use AnyEvent;
use AnyEvent::Handle;
use AnyEvent::Socket;

use Data::Dumper;

our (%conf, $base_dir, $debug);

# Localizing global variables
use AXbills::Backend::Defs;
use AXbills::Backend::Utils qw/json_decode_safe json_encode_safe/;

use AXbills::Backend::Plugin::Internal::Command;
use AXbills::Backend::Plugin::Internal::API;

use AXbills::Backend::Plugin::Websocket::API;
my AXbills::Backend::Plugin::Websocket::API $WEBSOCKET_API;

use AXbills::Backend::Log;
my $local_debug = $conf{WEBSOCKET_INTERNAL_DEBUG} || $debug || 3;
my AXbills::Backend::Log $Log = AXbills::Backend::Log->new('FILE', $local_debug, 'Internal', {
  FILE => $conf{WEBSOCKET_INTERNAL_DEBUG_FILE} || ($base_dir || '/usr/axbills/') . '/var/log/websocket_internal.log'
});

#**********************************************************
=head2 init($attr)

  Arguments:
    $attr -
    
  Returns:
    1
    
=cut
#**********************************************************
sub init {
  my $self = shift;
  my ($attr) = @_;

  my $server_port = $conf{WEBSOCKET_INTERNAL_PORT} || 19444;

  # Starting websocket server
  $Log->info("Starting internal commands server on 127.0.0.1:$server_port");
  AnyEvent::Socket::tcp_server('127.0.0.1', $server_port, sub {
    $self->accept_internal_admin_client(@_);
  });

  $WEBSOCKET_API = get_global('WEBSOCKET_API');

  $self->{type_handle} = {
    MESSAGE      => \&process_browser_message,
    REQUEST_LIST => \&process_list_request,
    COMMAND      => \&process_command,
    PING         => '{"TYPE":"PONG"}',
    PROXY        => \&process_proxy_message
  };

  return AXbills::Backend::Plugin::Internal::API->new($self->{conf}, $self);
}

#**********************************************************
=head2 accept_internal_admin_client()

=cut
#**********************************************************
sub accept_internal_admin_client {
  my $self = shift;
  my ($socket_pipe_handle, $host, $port) = @_;

  my $socket_id = "$host:$port";
  $Log->notice("Internal connection : $socket_id");

  my $handle = AnyEvent::Handle->new(
    fh       => $socket_pipe_handle,
    no_delay => 1
  );

  # On message
  $handle->on_read(sub {$self->process_message(@_)});

  $handle->on_eof(
    sub {
      my AnyEvent::Handle $this_client_handle = shift;
      $this_client_handle->push_shutdown;
      $this_client_handle = undef;
    }
  );

  $handle->on_error(
    sub {
      my AnyEvent::Handle $read_handle = shift;
      $Log->critical("Error happened with internal $socket_id ");
      $read_handle->push_shutdown;
      undef $handle;
    }
  )
}

#**********************************************************
=head2 process_message()

=cut
#**********************************************************
sub process_message {
  my $self = shift;
  my AnyEvent::Handle $this_client_handle = shift;

  my $chunk = $this_client_handle->{rbuf};
  $this_client_handle->{rbuf} = undef;

  $Log->notice("Processing message " . $chunk);

  my $parsed_chunk = json_decode_safe($chunk);
  my %type_handle = %{$self->{type_handle}};
  my $response = '';

  if (!$parsed_chunk || !(ref $parsed_chunk eq 'HASH' && $parsed_chunk->{TYPE})) {
    $Log->debug("Got wrong request ");

    $response = qq{ {"TYPE":"ERROR", "ERROR":"INCORRECT REQUEST"} };

    $this_client_handle->push_write($response);
    return;
  }
  elsif (exists $type_handle{$parsed_chunk->{TYPE}}) {
    my $handler = $type_handle{$parsed_chunk->{TYPE}};

    if (!ref $handler) {
      $response = $handler;
    }
    elsif (ref $handler eq 'CODE') {
      eval {
        # Indirect call of $self->$handler($parsed_chunk)
        $response = $handler->($self, $parsed_chunk);
      };
      if ($@) {
        $response = qq{ {"TYPE":"ERROR", "ERROR":"$@"} }
      }
    }

    # Error handling
    if (!$response) {
      $response = '{"TYPE":"ERROR", "ERROR":"Error while processing request"}';
    }

  }
  else {
    $response = '{"TYPE":"ERROR", "ERROR":"UNKNOWN MESSAGE TYPE"}';
  }

  # Client says he does not want result
  if ($parsed_chunk->{SILENT}) {
    return;
  }

  $this_client_handle->push_write(ref $response ? json_encode_safe($response) : $response);
}

#**********************************************************
=head2 process_browser_message() - proxy request to admin browser tab

=cut
#**********************************************************
sub process_browser_message {
  my $self = shift;
  my ($data) = @_;

  my $responce = '';

  # Check who is receiver
  if (!$data->{ID}) {
    $Log->error("Trying to send message without recipient ID specified");
    return 0;
  }
  elsif (!$data->{DATA}) {
    $Log->error("No data in message");
    return 0;
  }
  elsif ($data->{TO} eq 'ADMIN') {
    $Log->debug("Sending data to admin $data->{ID} " . (ref $data->{DATA} ? Dumper($data->{DATA}) : $data->{DATA}));
    my $result = $WEBSOCKET_API->notify_admin($data->{ID}, $data->{DATA}, $data);
    $Log->debug("Received " . (ref $result ? Dumper($result) : $result));

    $responce = json_encode_safe($result);
  }
  elsif ($data->{TO} eq 'USER') {
    $Log->debug("Sending data to user $data->{ID} " . (ref $data->{DATA} ? Dumper($data->{DATA}) : $data->{DATA}));
    $data->{TO} = 'user';
    my $result = $WEBSOCKET_API->notify_admin($data->{ID}, $data->{DATA}, $data);
    $Log->debug("Received " . (ref $result ? Dumper($result) : $result));

    $responce = json_encode_safe($result);
  }

  return $responce;
};

#**********************************************************
=head2 process_list_request()

=cut
#**********************************************************
sub process_list_request {
  my $self = shift;
  my ($data) = @_;

  my $list_type = $data->{LIST_TYPE};

  my @result_list = ();

  return q{{"TYPE":"ERROR", "ERROR":"UNDEFINED 'LIST_TYPE'"}} unless ($list_type);

  if ($list_type eq 'ADMINS') {
    @result_list = $WEBSOCKET_API->clients_connected('admin');
  }
  elsif ($list_type eq 'USERS') {
    @result_list = $WEBSOCKET_API->clients_connected('user');
  }

  my %response = (
    TYPE => "RESULT",
    LIST => \@result_list
  );

  return json_encode_safe(\%response);
}

#**********************************************************
=head2 process_command($attr) - runs command and returns notification

  Arguments:
    $attr   - hash_ref
      AID      - administrator ID
      PROGRAM  - program to run
      ARGS     - array_ref, arguments for program (optional)
      
      SUCCESS  - Text for notification
      ERROR    - Text for notification
      
      ID       - id for this task (will be returned with notification)

  Returns
    1 if command was accepted;

=cut
#**********************************************************
sub process_command {
  my $self = shift;
  my ($data) = @_;

  my $aid = $data->{AID};
  my $program = $data->{PROGRAM};

  return if (!$aid || !$program);

  # Check $program contains only single word
  if ($program =~ /^([-\@\w.]+)$/) {
    $program = $1; # $string now untainted.
  }
  else {
    $Log->error("Insecure command $program");
    return 'Bad command';
  }

  if ($data->{PROGRAM_ARGS} && ref $data->{PROGRAM_ARGS} eq 'ARRAY') {
    foreach my $arg (@{$data->{PROGRAM_ARGS}}) {
      next if ($arg =~ /;/);

      $arg =~ s/"/\'\"\'/;
      $arg =~ s/`/\\\`/;

      $program .= ' ' . $arg;
    }
  }

  my $args = $data->{ARGS} || {};

  my $success_notification = $data->{SUCCESS};
  my $error_notification = $data->{ERROR};

  $Log->notice("Command requested is $program");

  # Create command
  my $command = AXbills::Backend::Plugin::Internal::Command->new($program, $args);

  # Run in new thread with callback
  $command->run(sub {
    my ($status, $result) = @_;

    $Log->info("Command finished $program : " . ($result || 'Error'));

    my $notification = $status ? $success_notification : $error_notification;

    # If user left notifications empty, use command result as notification
    $notification ||= {
      TYPE  => 'MESSAGE',
      TITLE => $program,
      TEXT  => $result || 'Error',
      ID    => $data->{ID} || ''
    };

    $WEBSOCKET_API->notify_admin($aid, $notification);
  });

  return 1;
}

#**********************************************************
=head2 process_proxy_message($data)

  Arguments:
    $data - data as received on socket
      TYPE == 'PROXY' - type of data
      PROXY_TO        - name of plugin to send data
      MESSAGE         - will be sent to plugin
    
  Returns:
    1 if message has been accepted by corresponding plugin
  
=cut
#**********************************************************
sub process_proxy_message {
  my $self = shift;
  my ($data) = @_;

  my $plugin_name = $data->{PROXY_TO};
  return 0 unless ($plugin_name);

  my $plugin_api_name = uc($plugin_name) . "_API";
  my AXbills::Backend::Plugin::BaseAPI $API = get_global($plugin_api_name);

  return 0 unless ($API);

  return $API->process_internal_message($data->{MESSAGE})
}

1;
