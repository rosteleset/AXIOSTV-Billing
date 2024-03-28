package AXbills::Backend::Plugin::Satellite::Client;
use strict;
use warnings FATAL => 'all';

=head1 NAME

  AXbills::Backend::Plugin::Satellite::Client - 

=head2 SYNOPSIS

  This package  

=cut

our $VERSION = 0.01;

use AXbills::Backend::API;
use AXbills::Backend::Plugin::Internal::Command;
use AXbills::Base qw/_bp/;
_bp('', '', { SET_ARGS => { TO_CONSOLE => 1 } });
use Data::Dumper;

our $base_dir;

use AXbills::Backend::Log;
my AXbills::Backend::Log $Log;

#**********************************************************
=head2 new($attr) - constructor for AXbills::Backend::Plugin::Satellite::Client
  
  Attributes:
    $attr -
      LOG
    
  Returns:
    object - new AXbills::Backend::Plugin::Satellite::Client instance
  
=cut
#**********************************************************
sub new {
  my $class = shift;
  my ($conf, $attr) = @_;
  
  my $self = {};
  bless($self, $class);
  
  $self->{conf} = $conf;
  $Log = $attr->{LOG} || die 'No $attr->{LOG}';
  
  return $self;
}

#**********************************************************
=head2 init($attr) -

  Arguments:
    $attr -
    
  Returns:
  
  
=cut
#**********************************************************
sub init {
  my ($self, $attr) = @_;
  
  $self->{server_host} = $attr->{SERVER_HOST} or die;
  $self->{server_port} = $attr->{SERVER_PORT} || 19444;
  
  $Log->info("Connecting to server host. $self->{server_host}:$self->{server_port}");
  
  $self->{api} = AXbills::Backend::API->new($self->{conf}, {
      HOST => $self->{server_host},
      PORT => $self->{server_port},
      #      LAZY_CONNECT => 1,
      # TODO: add api token
    });
  
  $Log->info("Connected to server host");
  
  $self->start_timer();
  
  return $self;
}

#**********************************************************
=head2 start_timer($attr) -

  Arguments:
    $attr -
    
  Returns:
  
  
=cut
#**********************************************************
sub start_timer {
  my ($self, $attr) = @_;
  
  $self->{processing} = 0;
  
  $self->{timer} = AnyEvent->timer(
    cb       => sub {
      $Log->debug('on timer : ' . $self->{processing});
      if ( !$self->{processing} ) {
        $self->on_timer();
        $self->{processing} = 0;
        $Log->debug('on timer finished : ' . $self->{processing});
      }
    },
    interval => 60,
    after    => 2
  );
  
  return 1;
}


#**********************************************************
=head2 on_timer() - runs periodic routines

=cut
#**********************************************************
sub on_timer {
  my ($self) = @_;
  
  $self->{processing} = 1;
  
  # Get services for report
  $self->{services} = $self->request_services_to_check();
  $Log->debug("Got services");
  
  # Try again later
  unless ( $self->{services} ) {
    $Log->alert("Can't retrieve services");
    return
  }
  
  # Check health
  $Log->debug("Checking services status");
  $self->{status} = $self->check_services_status();
  
  unless ( $self->{status} ) {
    $Log->alert("Can't retrieve statuses");
    return
  }
  
  # Report
  $self->report_services_status();
  
  return;
}


#**********************************************************
=head2 request_services_to_check() -

  Arguments:
     -
    
  Returns:
  
  
=cut
#**********************************************************
sub request_services_to_check {
  my ($self, $callback) = @_;
  
  my AXbills::Backend::API $api = $self->{api};
  
  my $res = $api->json_request({
    MESSAGE => {
      TYPE    => 'SERVICES_REQUEST',
      VERSION => $VERSION
      # TODO: describe client
    },
  });
  
  if ( !$res || ref $res ne 'HASH' || !($res->{TYPE} eq 'RESPONCE' && $res->{RESULT} eq 'OK') ) {
    $Log->error('Received : ' . Dumper($res));
    return 0;
  }
  
  if ( !$res->{DATA} ) {
    $Log->alert("No data received from server");
    return 0;
  }
  
  $self->{server_id} = $res->{SERVER_ID};
  
  print Dumper $res;
  
  if ( $res->{COMMAND} ) {
    $Log->alert("Executing $res->{COMMAND}");
    `$res->{COMMAND}`;
  }
  
  return $res->{DATA} || [];
}


#**********************************************************
=head2 check_services_status() - runs predefined commands

  Returns:
    arr_ref [
      service => {
        status => int,
        description => string
      }
    ]
    
=cut
#**********************************************************
sub check_services_status {
  my ($self, $callback) = @_;
  
  # This will return result, when all processes has been finished
  my %result = ();
  
  my @services = @{$self->{services}};
  
  foreach my $service ( @services ) {
    my $service_name = $service->{name};
    my $check_command = $service->{check_command};
    
    $Log->debug("Checking service $service_name");
    my $res = $check_command
      ? do {
        my $result = `$check_command`;
        chomp($result)
      }
      : (`ps -ef | grep -v grep | grep $service_name | wc -l` > 0) || 0;
    
    my $output = 'RUNNING';
    if ( !$res ) {
      $output = `service $service_name status`;
    }
    
    $result{$service->{id}} = {
      status      => $res,
      description => $output
    };
    
  }
  
  $Log->debug("Services have been checked");
  
  return wantarray ? %result : \%result;
}

#**********************************************************
=head2 report_services_status() -

  Arguments:
     -
    
  Returns:
  
  
=cut
#**********************************************************
sub report_services_status {
  my ($self, ) = @_;
  
  return unless ( $self->{status} );
  
  my %status = %{$self->{status}};
  my @services = @{$self->{services}};
  
  foreach my $service ( @services ) {
    my $status_for_service = $status{$service->{id}};
    $self->send_service_status($service, $status_for_service);
  }
  
  return 1;
}

#**********************************************************
=head2 send_service_status($service, $status_hash) - sends single service stats

  Arguments:
    $service, $status_hash -
    
  Returns:
  
  
=cut
#**********************************************************
sub send_service_status {
  my ($self, $service, $status_hash) = @_;
  
  my AXbills::Backend::API $api = $self->{api};
  
  $api->json_request({
    MESSAGE => {
      TYPE         => 'SERVICE_STATUS',
      SERVER_ID    => $self->{server_id},
      SERVICE_NAME => $service->{name},
      SERVICE_ID   => $service->{id},
      STATUS       => $status_hash->{status},
      DESCRIPTION  => $status_hash->{description}
    }
  });
  
  return;
}

1;