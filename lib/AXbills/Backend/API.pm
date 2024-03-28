package AXbills::Backend::API;
use strict;
use warnings FATAL => 'all';

=head1 NAME

  AXbills::Backend::API - API to Internal plugin

=head2 SYNOPSIS

  This package allows connection and data exchange to Internal plugin

=cut

use AnyEvent::Socket;
use AnyEvent::Handle;
use AXbills::Base qw/_bp in_array/;

use AXbills::Backend::Utils qw/json_decode_safe/;

use JSON qw//;

my $PING_REQUEST = { "TYPE" => "PING" };
my $PING_RESPONSE = { "TYPE" => "PONG" };

my JSON::XS $json = JSON->new->utf8(0)->allow_nonref(1);

#**********************************************************
=head2 new($CONF, $attr)

  Arguments:
    $CONF  - ref to %conf
    $attr
      WEBSOCKET_TOKEN

  Returns:
    object

=cut
#**********************************************************
sub new {
  my $class = shift;
  my ($conf, $attr) = @_;

  my $host = $attr->{HOST} || $conf->{WEBSOCKET_HOST} || '127.0.0.1';
  my $port = $attr->{PORT} || $conf->{WEBSOCKET_INTERNAL_PORT} || '19444';

  my $connection_host = $host . ':' . $port;

  my $self = {
    conf            => $conf,
    connection_host => $connection_host,
    host            => $host,
    port            => $port,
    token           => $attr->{SECRET_TOKEN} || $conf->{WEBSOCKET_TOKEN}
  };

  bless($self, $class);

  unless ($attr->{ASYNC_CONNECT}) {
    $self->connect();
  }

  return $self;
}

#**********************************************************
=head2 connect() -

  Arguments:
     -
    
  Returns:
  
  
=cut
#**********************************************************
sub connect {
  my ($self, $callback) = @_;

  if ($self->{fh}) {
    if ($callback) {
      $callback->($self->{fh});
      return 1;
    }
    else {
      return $self->{fh};
    }
  }

  my $cv = AnyEvent->condvar;
  tcp_connect($self->{host}, $self->{port}, sub {
    my ($fh) = @_;

    my $handler = $fh
      ? AnyEvent::Handle->new(
      fh       => $fh,
      no_delay => 1,
      on_error => sub {
        $self->{fh} = 0;
      },
      on_eof   => sub {
        $self->{fh} = 0;
      }
    )
      : 0;

    $self->{fh} = $handler;
    $cv->send($self->{fh});
  }
  );

  # Wait until got connection TODO: async
  $cv->recv;
  if (!$callback) {
    return $self->{fh}
  }
  else {
    $callback->($self->{fh});
  }
  return 1;
}

#**********************************************************
=head2 is_connected() - check if connected to internal WebSocket server

=cut
#**********************************************************
sub is_connected {
  my ($self) = @_;

  my $response = $self->json_request({ MESSAGE => $PING_REQUEST });

  return $response && ($response->{TYPE} && $response->{TYPE} eq 'PONG');
}

#**********************************************************
=head2 is_receiver_connected($aid) - pings admin browser tabs

  Arguments:
    $aid - AID
    
  Returns:
    boolean
    
=cut
#**********************************************************
sub is_receiver_connected {
  my ($self, $receiver, $type) = @_;
  return unless ($receiver);

  my $res = $self->json_request({
    MESSAGE => {
      TYPE => 'MESSAGE',
      TO   => $type,
      ID   => $receiver,
      DATA => {
        TYPE => 'PING'
      }
    }
  });

  if ($res && ref $res eq 'HASH' && $res->{RESULT} && scalar @{$res->{RESULT}}) {
    # At least one tab responds for ping
    return grep {$_ == 1} @{$res->{RESULT}};
  }

  return 0;
}

#**********************************************************
=head2 call($aid, $message) - send message to Websocket and receive responce

  Arguments:
    $aid     - Admin ID
    $message - json
      DATA

  Returns:
    hash - response

=cut
#**********************************************************
sub call {
  my $self = shift;
  my ($aid, $message, $attr) = @_;

  $attr->{MESSAGE} = {
    TYPE => 'MESSAGE',
    TO   => $attr->{SEND_TO} ? $attr->{SEND_TO} : 'ADMIN',
    ID   => $aid,
    DATA => $message,
  };

  return $self->json_request($attr);
}

#**********************************************************
=head2 call_plugin($plugin, $data, $attr) - will call to plugin's process_internal_message and return result

  Arguments:
    $plugin - name of plugin ('Websocket', 'Telegram', 'Asterisk')
    $data   - hash_ref. payload, data that will be sent to plugin
    $attr   - AXbills::Backend::API->_request params
    
  Returns:
    hash_ref or 0
    
=cut
#**********************************************************
sub call_plugin {
  my ($self, $plugin, $data, $attr) = @_;

  $attr->{MESSAGE} = {
    TYPE     => 'PROXY',
    PROXY_TO => $plugin,
    MESSAGE  => $data
  };

  return $self->json_request($attr);
}

#**********************************************************
=head2 json_request($attr) - simple alias to get perl structure as result

  Arguments:
    $attr - hash_ref
      MESSAGE - JSON string

  Returns:
    hash_ref - result
    undef on timeout

=cut
#**********************************************************
sub json_request {
  my $self = shift;
  my ($attr) = @_;

  if ($attr->{ASYNC}) {
    my $cb = $attr->{ASYNC};

    # Override function to make it receive perl structure
    $attr->{ASYNC} = sub {
      my $res = shift;
      $cb->($res ? json_decode_safe($res) : $res);
    };
  }

  $attr->{RETURN_RESULT} = 1;
  my $response = $self->_request($attr, $attr->{MESSAGE});

  return 0 if (!$response || $response eq q{"0"});
  return json_decode_safe($response);
}

#**********************************************************
=head2 _request($attr) - Request types wrapper

  Arguments:
    $attr -
      NON_SAFE
      ASYNC
      RETURN_RESULT
      
  Returns:
  
  
=cut
#**********************************************************
sub _request {
  my ($self, $attr, $payload) = @_;

  if ($attr->{NON_SAFE}) {
    return $self->_instant_request({
      MESSAGE => $payload,
      SILENT  => 1
    });
  }
  elsif ($attr->{ASYNC} && ref $attr->{ASYNC}) {
    $self->_asynchronous_request({
      MESSAGE  => $payload,
      CALLBACK => $attr->{ASYNC},
    });
    return;
  }

  my $sent = $self->_synchronous_request({
    MESSAGE => $payload
  });

  return ($attr->{RETURN_RESULT}) ? $sent : defined $sent;
}

#**********************************************************
=head2 _asynchronous_request($attr) - will write to socket and run callback, when receive result

  Arguments:
    $attr - hash_ref
      MESSAGE  - text will be send to backend server
      CALLBACK - function($result)
        $result will be
          string - if server responded with message
          ''     - if server accepted message, but not responded nothing
          undef  - if timeout

  Returns:
    undef
    

=cut
#**********************************************************
sub _asynchronous_request {
  my ($self, $attr) = @_;

  my $callback_func = $attr->{CALLBACK};
  my $message = $attr->{MESSAGE};

  $self->connect(sub {
    my AnyEvent::Handle $handle = shift;
    # Setup receive callback
    $handle->on_read(
      sub {
        my ($response_handle) = shift;

        my $read = $response_handle->{rbuf};
        $response_handle->{rbuf} = undef;

        $callback_func->($read);
      }
    );

    $handle->push_write($message);
  });
  return 1;
}

#**********************************************************
=head2 _synchronous_request($attr)

  Arguments:
    $attr - hash_ref
      MESSAGE - text will be send to backend server

  Returns:
    string - if server responded with message
    ''     - if server accepted message, but not responded nothing
    undef  - if timeout

=cut
#**********************************************************
sub _synchronous_request {
  my ($self, $attr) = @_;

  my $message = $attr->{MESSAGE} || do {
    warn 'No $attr->{MESSAGE} in WebSocket::API ' . __LINE__ . " \n";
    return 0;
  };

  # Setup receive callback
  my $operation_end_waiter = AnyEvent->condvar;

  # Set timeout to 2 seconds
  my $timeout_waiter = AnyEvent->timer(
    after => 2,
    cb    => sub {
      _bp("AXbills::Sender::Browser", "$self->{host} Timeout", { TO_CONSOLE => 1 }) if ($self->{debug});
      $operation_end_waiter->send(undef);
    }
  );

  $self->connect unless ($self->{fh});

  my AnyEvent::Handle $handle = $self->{fh};

  return 0 unless $handle;

  $handle->on_read(
    sub {
      my ($response_handle) = shift;

      my $read = $response_handle->{rbuf};
      $response_handle->{rbuf} = undef;

      $operation_end_waiter->send($read);
    }
  );

  $handle->push_write($json->encode($message));

  # Script will hang here until receives result from async operation above
  my $result = $operation_end_waiter->recv;
  undef $timeout_waiter;

  return $result;
};

#**********************************************************
=head2 _instant_request($attr) - will not wait for timeout, but no warranties for receive

  Arguments:
    $attr - hash_ref
      MESSAGE - text will be send to backend server

  Returns:
    1
    
=cut
#**********************************************************
sub _instant_request {
  my $self = shift;
  my ($attr) = @_;

  # Make sub that sends or connects ands sends
  $self->connect(sub {
    my AnyEvent::Handle $fh = shift;
    $fh->push_write($json->encode($attr));
  });

  return 1;
}

1;
