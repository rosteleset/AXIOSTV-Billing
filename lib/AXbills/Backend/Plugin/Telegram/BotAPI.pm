package AXbills::Backend::Plugin::Telegram::BotAPI;
use strict;
use warnings 'FATAL' => 'all';
=head1 NAME
  
  AXbills::Backend::Plugin::Telegram::BotAPI - Interface to Telegram Bot API
  
=cut

our $libpath;
BEGIN {
  our $Bin;
  use FindBin '$Bin';
  
  $libpath = $Bin . '/../'; #assuming we are in /usr/axbills/misc/
  if ( $Bin =~ m/\/axbills(\/)/ ) {
    $libpath = substr($Bin, 0, $-[1]);
  }
  
  unshift(@INC,
    "$libpath/lib/AXbills/Backend/",
  );
}

use AXbills::Base qw/_bp load_pmodule/;

if ( my $module_load_error = load_pmodule("LWP::UserAgent", { SHOW_RETURN => 1 }) ) {
  die $module_load_error;
}

if ( my $module_load_error = load_pmodule("HTTP::Request::Common", { SHOW_RETURN => 1 }) ) {
  die $module_load_error;
}

if ( my $module_load_error = load_pmodule("JSON", { SHOW_RETURN => 1 }) ) {
  die $module_load_error;
}

if ( my $module_load_error = load_pmodule("IO::Socket::SSL", { SHOW_RETURN => 1 }) ) {
  die $module_load_error;
}



use LWP::UserAgent;
use HTTP::Request::Common;

require JSON;
JSON->import();

my JSON $json = JSON->new->utf8(0)->allow_nonref(1);

require AXbills::Backend::Log unless $AXbills::Backend::Log::VERSION;
AXbills::Backend::Log->import(':levels');

my AXbills::Backend::Log $Log;

#**********************************************************
=head2 AUTOLOAD()

=cut
#**********************************************************
sub AUTOLOAD {
  our ($AUTOLOAD);
  my $name = $AUTOLOAD;
  return if ( $name =~ /^.*::[A-Z]+$/ );
  
  my $self = shift;
  $name =~ s/^.*:://;   # strip fully-qualified portion
  
  my $res = 0;
  eval {
    $res = $self->make_request($name, @_);
  };
  return $res;
}

#**********************************************************
=head2 new($attr)

  Arguments:
    $attr -
      token   - auth token
      api_host - (optional), where to send requests. Default is 'api.telegram.org'
      debug   - debug level
      
  Returns:
    AXbills::Backend::Plugin::Telegram::BotAPI instance
  
=cut
#**********************************************************
sub new {
  my $class = shift;
  my ($conf, $attr) = @_;
  
  die "No token" unless ( $attr->{token} );
  
  my $self = {
    token    => $attr->{token} || $conf->{TELEGRAM_TOKEN},
    api_host => $attr->{api_url} || 'api.telegram.org',
    debug    => $attr->{debug} || $conf->{TELEGRAM_API_DEBUG} || 0
  };
  
  $Log = AXbills::Backend::Log->new(
    'FILE',
    $self->{debug} || 7,
    'Telegram API',
    {
      FILE => $conf->{TELEGRAM_API_DEBUG_FILE} || \*STDOUT
    }
  );
  
  bless($self, $class);
}

#
##**********************************************************
#=head2 connect() - opens connection to Telegram API
#
#=cut
##**********************************************************
#sub connect {
#  my ( $self, $callback ) = @_;
#
#  my $endpoint = $self->{api_host};
#
#  my $waiter = undef;
#  if ( !$callback ) {
#    $waiter = AnyEvent->condvar;
#  }
#
#  $self->{connection} = AnyEvent::Socket::tcp_connect ($endpoint, 443,
#    sub {
#      my ($fh) = @_ or die "unable to connect: $!";
#
#      _bp('fh', $fh);
#      exit;
#
#      my $handle; # avoid direct assignment so on_eof has it in scope.
#      $handle = AnyEvent::Handle->new(
#        fh        => $fh,
#        tls       => 'connect',
#        #        no_delay => 1,
#        keepalive => 1,
#        tls_ctx   => {
#          sslv3          => 0,
#          verify         => 1,
#          session_ticket => 1,
#        },
#        on_error  => sub {
#          my (undef, undef, $msg) = @_;
#          $_[0]->destroy;
#          delete $self->{handle};
#
#          $Log->error('connect :' . $msg);
#
#          if ( !$callback ) {
#            $waiter->send(0);
#          }
#          else {
#            $callback->(0);
#          }
#        }
#      );
#
#      $self->{handle} = $handle;
#
#      if ( !$callback ) {
#        $waiter->send(1);
#        return 1;
#      }
#
#      $callback->(1);
#    });
#
#  if ( !$callback ) {
#    my $connected = $waiter->recv;
#    return $connected;
#  }
#}
#
##**********************************************************
#=head2 make_request($method_name, $params, $callback) - async request
#
#  Arguments:
#    $method_name  - API method
#    $params       - hash_ref
#    $callback     - coderef, if given,
#
#  Returns:
#
#
#=cut
##**********************************************************
#sub make_request {
#  my $self = shift;
#  my ($method_name, $params, $callback) = @_;
#
#  # Prepare payload
#  my $params_encoded = '';
#  eval {
#    $params_encoded = $json->encode($params);
#  };
#  if ( $@ ) {
#    $Log->alert('REQUEST PARAMS ERROR : ' . $@);
#    $Log->alert('REQUEST PARAMS ERROR : ' . $params);
#
#    my $res = { error => $@, ok => 0, type => 'on_write' };
#    if ( !$callback ) {
#      return $res;
#    }
#    else {
#      $callback->($res);
#    }
#  }
#
#  my AnyEvent::Handle $handle = $self->{handle};
#  if ( !$handle || $handle->destroyed() ) {
#    $self->connect();
#  }
#
#  my $waiter;
#  if ( !$callback ) {
#    $waiter = AnyEvent->condvar();
#  }
#
#  $handle->on_error(sub {
#    $handle->destroy();
#    delete $self->{handle};
#
#    $Log->error("Error sending request");
#    $Log->error('TELEGRAM SEND ERROR : ' . ($_[2] || ''));
#
#    if ( $waiter ) {
#      $waiter->send(0);
#    }
#    else {
#      return 0;
#    }
#  });
#
#  $handle->on_eof(sub {
#    $handle->destroy();
#    delete $self->{handle};
#    if ( $waiter ) {
#      $waiter->send(0);
#    }
#    else {
#      return 0;
#    }
#  });
#
#  $handle->on_read(sub {
#    my AnyEvent::Handle $hdl = shift;
#    my $raw_content = $hdl->{rbuf};
#
#    _bp(0);
#
#    my (undef, $json_content) = split(/[\r\n]{4}/m, $raw_content);
#
#    my $response = '';
#    eval {
#      _bp(2);
#      $response = $json->decode($json_content);
#    };
#    if ( $@ ) {
#      _bp('params', $params);
#      _bp('raw json', $json_content);
#      _bp('error', $@);
#
#      my %res = (error => $@, ok => 0, type => 'on_read');
#      if ( !$callback ) {return \%res;}
#      else {$callback->(\%res);}
#    }
#    $hdl->{rbuf} = '';
#
#    _bp(3);
##    $Log->debug("Received response for request : $response");
#
#    if ( !$response || ref $response ne 'HASH' ) {
#      $Log->warning("Error in request from API. Raw response : $response");
#      if ( !$callback ) {
#        $waiter->send($response);
#      }
#      else {
#        $callback->($response);
#      }
#    }
#
#    if ( !$response->{ok} ) {
#      if ( $response->{error_code} && $response->{description} ) {
#        $Log->warning($response->{error_code} . ' : ' . $response->{description} || 'Unknown error');
#      }
#    }
#
#    if ( !$callback ) {
#      $waiter->send($response);
#    }
#    else {
#      $callback->($response);
#    }
#  });
#
#  $Log->debug("Sent to sender: $params_encoded") if ($self->{debug} && $self->{debug} >= 7);
#
#  my $length = length $params_encoded;
#  $handle->push_write(qq{GET /bot$self->{token}/$method_name HTTP/1.1
#Host: $self->{api_host}
#Pragma: no-cache
#Cache-Control: no-cache
#Content-Length: $length
#Connection: keep-alive
#Content-Type: application/json; charset=utf-8
#
#$params_encoded});
#
#  if ( !$callback ) {
#    return $waiter->recv();
#  }
#  return 1;
#}

#**********************************************************
=head2 make_request($method_name, $params, $callback) - async request

  Arguments:
    $method_name  - API method
    $params       - hash_ref
    $callback     - coderef, if given,

  Returns:


=cut
#**********************************************************
sub make_request {
  my $self = shift;
  my ($method_name, $params) = @_;
  
  my $endpoint = 'https://' . $self->{api_host} . '/bot' . $self->{token} . '/' . $method_name;

  my $ua = LWP::UserAgent->new(ssl_opts => { verify_hostname => 0 });

  #   Prepare payload
  my $params_encoded = '';
  eval {
    $params_encoded = $json->encode($params);
  };
  if ( $@ ) {
    $Log->alert('REQUEST PARAMS ERROR : ' . $@);
    $Log->alert('REQUEST PARAMS ERROR : ' . $params);

    my $res = { error => $@, ok => 0, type => 'on_write' };
    return $res;
  }

  my $request;

  if($params->{RAW_BODY}){
    delete $params->{RAW_BODY};

    $request = POST $endpoint,
      Content_Type => 'multipart/form-data; boundary=----TELEGRAM7MA4YWxkTrZu0gW',
      Host => $self->{api_host},
      Content      => $params;

    # AXbills::Base::_bp("ASD", $params, {HEADER => 1});
    # exit;
  } else {
    $request = HTTP::Request->new( 'POST', $endpoint );
    $request->header( 'Content-Type' => 'application/json' );
    $request->content( $params_encoded );
  }

  my $result = $ua->request($request);

  return $json->decode($result->{_content}) if($result && $request->{_content});
  return 0;

}

sub DESTROY {

}

1;