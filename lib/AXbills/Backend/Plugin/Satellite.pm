package AXbills::Backend::Plugin::Satellite;
use strict;
use warnings FATAL => 'all';

=head1 NAME

  AXbills::Backend::Plugin::Satellite

=head2 SYNOPSIS

  Plugin to control remote servers

=cut

use base 'AXbills::Backend::Plugin::BasePlugin';

our ($base_dir);
if (!$base_dir){
  our $Bin;
  require FindBin;
  FindBin->import('$Bin');
  
  if ($Bin =~ m/\/usr\/axbills(\/)/){
    $base_dir = substr($Bin, 0, $-[1]);
  }
}

use AXbills::Backend::Plugin::Satellite::API;

use AXbills::Backend::Log;
my AXbills::Backend::Log $Log;

#**********************************************************
=head2 new($db, $admin, $CONF)

  Arguments:
    $db    - ref to DB
    $admin - current Web session admin
    $CONF  - ref to %conf
    
  Returns:
    object
    
=cut
#**********************************************************
sub new{
  my $class = shift;

  my ($CONF) = @_;

  if (!$CONF->{SATELLITE_MODE}){
    die '$CONF->{SATELLITE_MODE} is not set' . "\n";
  }
  
  my $self = {
    conf  => $CONF,
  };
  
  $Log = AXbills::Backend::Log->new('FILE', $CONF->{SATELLITE_DEBUG} || 7,
    'Satellite', {
      FILE => $CONF->{SATELLITE_DEBUG_FILE} || ($base_dir || '/usr/axbills/') . '/var/log/satellite.log'
    });
  
  bless( $self, $class );

  return $self;
}



#**********************************************************
=head2 init($conf, $attr) -

  Arguments:
    $conf -
      SATELLITE_MODE         - mode for this daemon ('Client', 'Server')
      SATELLITE_SERVER_PORT  - default is 19422
      SATELLITE_SERVER_HOST  - required for client and is default 0.0.0.0 for server
      SATELLITE_SECRET_KEY   - required or $conf{SECRET_KEY}
      
  Returns:
    API
  
=cut
#**********************************************************
sub init {
  my ($self, $attr) = @_;
  
  my %conf = %{$self->{conf}};
  
  $self->{server_port} = $conf{SATELLITE_SERVER_PORT} || 19422;
  
  if ($conf{SATELLITE_MODE} eq 'Server'){
    $self->{server_host} = $conf{SATELLITE_SERVER_HOST} || '0.0.0.0';
    $Log->notice("Starting server");
    $self->init_server($attr);
  }
  else {
    die "No \$conf->{SATELLITE_SERVER_HOST} specified \n" unless ($conf{SATELLITE_SERVER_HOST});
    $self->{server_host} = $conf{SATELLITE_SERVER_HOST};
    $Log->notice("Starting client");
    $self->init_client($attr);
  }
  
  return AXbills::Backend::Plugin::Satellite::API->new($self->{conf}, $self);
}

#**********************************************************
=head2 init_server($attr) - starts tcp server

  Arguments:
    $attr -
    
  Returns:
  
  
=cut
#**********************************************************
sub init_server {
  my ($self, $attr) = @_;
  
  require AXbills::Backend::Plugin::Satellite::Server;
  
  my $server = AXbills::Backend::Plugin::Satellite::Server->new($self->{conf}, { LOG => $Log });
  
  $server->init({
    SERVER_PORT => $self->{server_port},
    SERVER_HOST => $self->{server_host}
  });
  
  $self->{server} = $server;
  
  return $self;
}

#**********************************************************
=head2 init_client($attr) - receives services to see and start timers for health check

  Arguments:
    $attr -
    
  Returns:
  
  
=cut
#**********************************************************
sub init_client {
  my ($self, $attr) = @_;
  
  require AXbills::Backend::Plugin::Satellite::Client;
  my $client = AXbills::Backend::Plugin::Satellite::Client->new($self->{conf}, { LOG => $Log });
  
  $client->init({
    SERVER_PORT => $self->{server_port},
    SERVER_HOST => $self->{server_host}
  });
  
  $self->{client} = $client;
  
  return $self;
}


1;