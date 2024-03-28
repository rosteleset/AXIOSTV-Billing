package AXbills::Backend::Plugin::Satellite::Server;
use strict;
use warnings FATAL => 'all';

=head1 NAME

  AXbills::Backend::Plugin::Satellite::Server -

=head2 SYNOPSIS

  This package

=cut

use AXbills::Base qw/_bp/;
use AXbills::Backend::Utils qw/json_decode_safe json_encode_safe/;

use AXbills::Backend::Log;
use Sysinfo;
use Admins;
use AXbills::SQL;

my AXbills::SQL $db;
my Admins $admin;
my Sysinfo $Sysinfo;

my AXbills::Backend::Log $Log;

#**********************************************************
=head2 new($CONF)

  Arguments:
    $CONF  - ref to %conf
    
  Returns:
    object
    
=cut
#**********************************************************
sub new {
  my $class = shift;
  
  my ($CONF, $attr) = @_;
  
  my $self = {
    conf        => $CONF,
    server_host => $CONF->{SATELLITE_SERVER_HOST} || 0,
    server_port => $CONF->{SATELLITE_SERVER_PORT} || 19422,
    statuses    => {},
    commands    => {}
  };
  
  $Log = $attr->{LOG} || die "No log passed \t";
  
  my %conf = %{$CONF};
  $db = AXbills::SQL->connect(@conf{'dbtype', 'dbhost', 'dbname', 'dbuser', 'dbpasswd'}, {
      CHARSET => $conf{dbcharset},
      SCOPE   => __FILE__ . __LINE__
    });
  $admin = Admins->new($db, \%conf);
  
  $Sysinfo = Sysinfo->new($db, $admin, \%conf);
  
  bless($self, $class);
  
  return $self;
}


#**********************************************************
=head2 init($attr) - starts server

  Arguments:
    $attr -
      SERVER_PORT
      SERVER_HOST
      SERVER_KEY
      
  Returns:
    $self
    
=cut
#**********************************************************
sub init {
  my ($self, $attr) = @_;
  
  AnyEvent::Socket::tcp_server ($self->{server_host}, $self->{server_port}, sub {
      $self->new_client_connection(@_);
    }, sub {
      $Log->notice("Server started on $_[1]:$_[2]");
      return 0; # Listen queue length
    });
  
  $self->{type_handle} = {
    SERVICE_STATUS   => \&update_service_status,
    SERVICES_REQUEST => \&list_of_services_request,
  };
  
  return $self;
}

#**********************************************************
=head2 new_client_connection($fh) -

  Arguments:
    $fh -
    
  Returns:
  
  
=cut
#**********************************************************
sub new_client_connection {
  my ($self, $socket_pipe_handle, $host, $port) = @_;
  
  my $socket_id = "$host:$port";
  $Log->notice("Internal connection : $socket_id");
  
  my $handle = AnyEvent::Handle->new(
    fh       => $socket_pipe_handle,
    no_delay => 1,
    #    tls       => 'accept',
    #    tls_ctx   => {
    #      sslv3          => 0,
    #      verify         => 1,
    #      session_ticket => 1,
    #    },
  );
  
  # On message
  $handle->on_read(sub {$self->process_message(@_, $host)});
  
  $handle->on_eof(
    sub {
      my AnyEvent::Handle $this_client_handle = shift;
      $Log->notice("EOF $socket_id");
      $this_client_handle->push_shutdown;
      $this_client_handle = undef;
    }
  );
  
  $handle->on_error(
    sub {
      my AnyEvent::Handle $read_handle = shift;
      $Log->notice("ERROR $socket_id");
      $Log->critical("Error happened with internal $socket_id ");
      $read_handle->push_shutdown;
      undef $handle;
    }
  )
}

#**********************************************************
=head2 process_message($fh) -

=cut
#**********************************************************
sub process_message {
  my ($self, $client_ip);
  my AnyEvent::Handle $this_client_handle;
  ($self, $this_client_handle, $client_ip) = @_;
  
  my $chunk = $this_client_handle->{rbuf};
  $this_client_handle->{rbuf} = undef;
  
  $Log->notice("Processing message " . $chunk);
  
  my $message = json_decode_safe($chunk, 1);
  
  my $server_info = $self->get_server_info($message, $client_ip);
  
  return _make_error_message("Server not found. More info in log") unless ( $server_info );
  
  my $responce = '';
  
  if ( !$message || ref $message ne 'HASH' ) {
    $responce = _make_error_message($message);
  }
  elsif ( !$message->{TYPE} ) {
    $responce = _make_error_message('NO TYPE SPECIFIED');
  }
  elsif ( $message->{TYPE} eq 'RESPONCE' ) {
  
  }
  elsif ( $message->{TYPE} eq 'ECHO' ) {
    $responce = $message;
    $responce->{TYPE} = 'ECHO';
  }
  elsif ( exists $self->{type_handle}->{$message->{TYPE}} ) {
    my $handler = $self->{type_handle}->{$message->{TYPE}};
    
    if ( !ref $handler ) {
      $Log->debug("Will use predefined responce");
      $responce = $handler;
    }
    elsif ( ref $handler eq 'CODE' ) {
      $Log->debug("Will use predefined handler");
      eval {
        # Indirect call of $self->$handler($parsed_chunk)
        $responce = $handler->($self, $message, $server_info);
      };
      if ( $@ ) {
        $responce = _make_error_message($@);
      }
    }
  }
  else {
    $responce = _make_error_message('UNKNOWN MESSAGE TYPE');
  }
  
  my $resp_encoded = ref $responce ? json_encode_safe($responce) : $responce;
  $Log->debug("Processed as $resp_encoded");
  
  $this_client_handle->push_write($resp_encoded);
  
  return 1;
}

#**********************************************************
=head2 get_server_id() -

  Arguments:
     -
    
  Returns:
  
  
=cut
#**********************************************************
sub get_server_info {
  my ($self, $data, $client_ip) = @_;
  
  my $servers = $Sysinfo->remote_servers_list({
    IP               => $client_ip,
    SHOW_ALL_COLUMNS => 1
  });
  
  if ( $Sysinfo->{errno} || !$servers || !ref $servers eq 'ARRAY' || !(scalar @{$servers}) ) {
    $Log->alert("Request from unknown server $client_ip");
    return 0;
  }
  
  if ( scalar @{$servers} > 1 ) {
    $Log->alert("More than one server using : $client_ip");
    return 0;
  }
  
  return $servers->[0] || 0;
}

#**********************************************************
=head2 list_of_services_request($data) -

=cut
#**********************************************************
sub list_of_services_request {
  my ($self, $data, $server) = @_;
  
  my $services = $Sysinfo->services_for_server($server->{id});
  
  my %params = ();
  if ( exists $self->{commands}->{$server->{id}} ) {
    $params{COMMAND} = $self->{commands}->{$server->{id}};
    delete $self->{commands}->{$server->{id}};
  }
  
  return {
    "DATA"    => $services,
    SERVER_ID => $server->{id},
    "TYPE"    => "RESPONCE",
    "RESULT"  => "OK",
    %params
  };
}

#**********************************************************
=head2 update_service_status($data) - 

  Arguments:
    $data -
    
  Returns:
    
    
=cut
#**********************************************************
sub update_service_status {
  my ($self, $data, $server_info) = @_;
  
  my $server_id = $data->{SERVER_ID} || '';
  my $service_id = $data->{SERVICE_ID} || return _make_error_message("NO SERVICE_ID SPECIFIED");
  my $service_name = $data->{SERVICE_NAME} || '';
  my $service_status = $data->{STATUS} // return _make_error_message("NO STATUS SPECIFIED");
  
  $self->{statuses}->{$service_id} = $data;
  
  $Log->info(
    "Received service status from $server_info->{ip}. Server $server_id. $service_name - status $service_status",
    'Satellite ' . $server_id
  );
  
  $Sysinfo->server_services_change({
    ID          => $service_id,
    STATUS      => $service_status,
    LAST_UPDATE => 'NOW()'
  });
  
  return q/{"TYPE":"RESPONCE","RESULT":"OK"}/;
}

#**********************************************************
=head2 postpone_service_restart($service_id) -

  Arguments:
    $service_id -
    
  Returns:
  
  
=cut
#**********************************************************
sub postpone_service_restart {
  my ($self, $server_id, $service_name) = @_;
  
  $self->{commands}->{$server_id} = "service $service_name restart";
  
  return 1;
}

#**********************************************************
=head2 _make_error_message($message) -


=cut
#**********************************************************
sub _make_error_message {
  $Log->error("$_[0] was generated at " . join(', ', caller));
  
  return {
    "TYPE"  => "ERROR",
    "ERROR" => "$_[0]"
  };
}

1;