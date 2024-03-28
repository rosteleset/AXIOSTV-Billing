package Cams::Zoneminder;
use strict;
use warnings FATAL => 'all';

use AXbills::Fetcher qw/web_request/;
use AXbills::Base qw / cmd _bp urlencode /;
use Digest::MD5 qw / md5_base64 /;

=head2 NAME

  Cams::Zoneminder

=head2 SYNOPSIS

  Bridge beetween ABillS and Zoneminder API

=cut

my Cams $Cams;

my %ORIENTATIONS = (
  0 => 0,
  1 => 90,
  2 => 180,
  3 => 270,
  4 => 'hori',
  5 => 'vert',
);
#**********************************************************
=head2 new($Cams, $CONF)

  Arguments:
    $Cams  - ref to Cams DB object
    $CONF  - ref to %conf

  Returns:
    object

=cut
#**********************************************************
sub new {
  my $class = shift;
  my ($Cams_, $CONF) = @_;
  
  my $self = {
    cams => $Cams_,
    conf => $CONF,
  };
  
  $Cams = $Cams_;
  
  bless( $self, $class );
  
  $self->{conf}->{CAMS_SERVER_PORT} //= '80';
  $self->{conf}->{CAMS_SERVER_HOST} //= "localhost";
  $self->{conf}->{CAMS_SERVER_PATH} //= "/zm/";
  $self->{conf}->{CAMS_ZONEMINDER_LOGIN} //= 'admin';
  $self->{conf}->{CAMS_ZONEMINDER_PASSWORD} //= 'admin';
  
  # Generated from above
  $self->{conf}->{CAMS_SERVER_HOST} = $self->{conf}->{CAMS_SERVER_HOST} . ':' . $self->{conf}->{CAMS_SERVER_PORT};
  $self->{conf}->{CAMS_ZONEMINDER_URL} = $self->{conf}->{CAMS_SERVER_HOST} . $self->{conf}->{CAMS_SERVER_PATH};
  
  return $self;
}

#**********************************************************
=head2 autenticate() - Autenticates against API, and saves cookies
    
  Returns:
    1
    
=cut
#**********************************************************
sub autenticate {
  my $self = shift;
  
  my $authenticate_params = "action=login&view=console&username=" . $self->{conf}->{CAMS_ZONEMINDER_LOGIN}
    . "&password=" . $self->{conf}->{CAMS_ZONEMINDER_PASSWORD};
  
  web_request($self->{conf}->{CAMS_ZONEMINDER_URL}, {
      POST       => $authenticate_params,
      CURL       => 1,
      COOKIE     => 1,
      DEBUG      => ($self->{conf}->{CAMS_ZONEMINDER_DEBUG}) ? $self->{conf}->{CAMS_ZONEMINDER_DEBUG} : 0,
      DEBUG2FILE => ($self->{conf}->{CAMS_ZONEMINDER_DEBUG}) ? '/tmp/axbills_zoneminder.log' : 0,
    });
  
  $self->{auth} = 1;
  
  return 1;
}

#**********************************************************
=head2 monitors_list($attr) - retrieves list of all cams on Zoneminder server

  Arguments:
    $attr - hash_ref
    
  Returns:
    hash_ref -
     monitors - list of monitors [ { Monitor => { params } } ]

=cut
#**********************************************************
sub monitors_list {
  my ( $self ) = @_;
  
  $self->autenticate() if (!$self->{auth});
  
  my $result = web_request($self->{conf}->{CAMS_ZONEMINDER_URL} . 'api/monitors.json', {
      CURL        => 1,
      COOKIE      => 1,
      JSON_RETURN => 1,
      DEBUG       => ($self->{conf}->{CAMS_ZONEMINDER_DEBUG}) ? $self->{conf}->{CAMS_ZONEMINDER_DEBUG} : 0,
      DEBUG2FILE  => ($self->{conf}->{CAMS_ZONEMINDER_DEBUG}) ? '/tmp/axbills_zoneminder.log' : 0,
    });
  
  return $result->{monitors};
}

#**********************************************************
=head2 monitors_info($zm_id) - returns Zoneminder stream params

  Arguments:
    $zm_id - Zoneminder stream_id
    
  Returns:
     -
    
=cut
#**********************************************************
sub monitors_info {
  my ($self, $zm_id) = @_;
  
  return if (!$zm_id || $zm_id == -1);
  
  $self->autenticate() if (!$self->{auth});
  
  return web_request($self->{conf}->{CAMS_ZONEMINDER_URL} . "api/monitors/$zm_id.json", {
      CURL        => 1,
      COOKIE      => 1,
      JSON_RETURN => 1,
      DEBUG       => ($self->{conf}->{CAMS_ZONEMINDER_DEBUG}) ? $self->{conf}->{CAMS_ZONEMINDER_DEBUG} : 0,
      DEBUG2FILE  => ($self->{conf}->{CAMS_ZONEMINDER_DEBUG}) ? '/tmp/axbills_zoneminder.log' : 0,
    });
}

#**********************************************************
=head2 add_cam($attr) - adds new live stream

  Arguments:
    $attr -

  Returns:
    1 - if success

=cut
#**********************************************************
sub add_cam {
  my ($self, $attr) = @_;
  
  $self->autenticate() if (!$self->{auth});
  
  my ($host, $port, $path) = ($attr->{HOST}, $attr->{RTSP_PORT}, $attr->{RTSP_PATH});
  
  my $name = _name_for_stream($attr);
  my $payload = _get_cakephp_data_payload({
      ENTITY   => 'Monitor',
        PARAMS => {
        Host        => $host || '',
        Name        => $name,
        Path        => $path || '/',
        Port        => $port || '554',
        Enabled     => (exists $attr->{DISABLED} && $attr->{DISABLED} == 1) ? 0 : 1,
        Orientation => $ORIENTATIONS{$attr->{ORIENTATION} || 0},
        Function    => 'Monitor',
        Protocol    => 'rtsp',
        Method      => 'rtpRtsp',
        Type        => 'Remote',
        Width       => '704',
        Height      => '480',
        Colours     => '4',
      }
    });
  
  if ( !$payload ) {
    _bp('', 'WTF', { HEADER => 1 });
    return 0;
  }
  
  web_request(($self->{conf}->{CAMS_ZONEMINDER_URL} . 'api/monitors.json'), {
      POST         => $payload,
      CURL         => 1,
      CURL_OPTIONS => '-XPOST',
      COOKIE       => 1,
      DEBUG        => ($self->{conf}->{CAMS_ZONEMINDER_DEBUG}) ? $self->{conf}->{CAMS_ZONEMINDER_DEBUG} : 0,
      DEBUG2FILE   => ($self->{conf}->{CAMS_ZONEMINDER_DEBUG}) ? '/tmp/axbills_zoneminder.log' : 0,
    });
  
  # Should update with new_name
  # Request returns garbage, so we should use another way to get new monitor id
  if ( $attr->{ID} ) {
    my $added_monitor_id = $self->get_monitor_id_by_billing_id( $attr->{ID} );
    return 0 if ($added_monitor_id == -1);
    $Cams->stream_change( { ID => $attr->{ID}, ZONEMINDER_ID => $added_monitor_id } )
  }
  
  return 1;
}

#**********************************************************
=head2 delete_cam($name) - deletes live cam stream

  Arguments:
    $attr - hash_ref
      NAME - to delete by name
      ID   - to delete by id

  Returns:
    1 - if success

=cut
#**********************************************************
sub delete_cam {
  my ($self, $attr) = @_;
  
  $self->autenticate() if (!$self->{auth});
  
  my $monitor_id = $self->get_monitor_id_by_billing_id( $attr->{ID} );
  return 1 if ( $monitor_id < 0 );
  
  web_request(($self->{conf}->{CAMS_ZONEMINDER_URL} . "api/monitors/$monitor_id.json"), {
      CURL         => 1,
      CURL_OPTIONS => '-XDELETE',
      COOKIE       => 1,
      DEBUG        => ($self->{conf}->{CAMS_ZONEMINDER_DEBUG}) ? $self->{conf}->{CAMS_ZONEMINDER_DEBUG} : 0,
      DEBUG2FILE   => ($self->{conf}->{CAMS_ZONEMINDER_DEBUG}) ? '/tmp/axbills_zoneminder.log' : 0,
    });
  
  return 1;
}

#**********************************************************
=head2 change_cam()

=cut
#**********************************************************
sub change_cam {
  my ($self, $attr) = @_;
  
  $self->autenticate() if (!$self->{auth});
  
  my $zoneminder_id = $self->get_monitor_id_by_billing_id( $attr->{ID} );
  return 0 if (!$zoneminder_id || $zoneminder_id < 1);
  
  my ($host, $port, $path) = ($attr->{HOST}, $attr->{RTSP_PORT}, $attr->{RTSP_PATH});
  
  if ($attr->{LOGIN} && $attr->{PASSWORD}){
    $host = "$attr->{LOGIN}:$attr->{PASSWORD}\@" . $host;
  }
  
  my $new_params = {
    Host        => $host,
    Path        => $path,
    Port        => $port,
    User        => $attr->{LOGIN} || q{},
    Pass        => $attr->{PASSWORD} || q{},
    Enabled     => (exists $attr->{DISABLED} && $attr->{DISABLED} == 1) ? 0 : 1,
    Orientation => $ORIENTATIONS{$attr->{ORIENTATION} || 0}
  };
  my $monitor_json = $self->monitors_info( $zoneminder_id );
  return 0 if (!defined $monitor_json || !defined $monitor_json->{monitor});
  
  my $monitor_params = $monitor_json->{monitor}{Monitor};
  my %changed_params = ();
  # Find changed fields
  foreach my $key ( keys %{$new_params} ) {
    if ( $monitor_params->{$key} ne $new_params->{$key} ) {
      $changed_params{$key} = $new_params->{$key};
    }
  }
  my $payload = _get_cakephp_data_payload({
      ENTITY         => 'Monitor',
        PARAMS       => \%changed_params,
        SKIP_DEFAULT => 1
    });
  
  web_request(($self->{conf}->{CAMS_ZONEMINDER_URL} . "api/monitors/$zoneminder_id.json"), {
      POST         => $payload,
      CURL         => 1,
      CURL_OPTIONS => '-XPUT',
      COOKIE       => 1,
      DEBUG        => ($self->{conf}->{CAMS_ZONEMINDER_DEBUG}) ? $self->{conf}->{CAMS_ZONEMINDER_DEBUG} : 0,
      DEBUG2FILE   => ($self->{conf}->{CAMS_ZONEMINDER_DEBUG}) ? '/tmp/axbills_zoneminder.log' : 0,
    });
  
  return 1;
}

#**********************************************************
=head2 _name_for_stream()

=cut
#**********************************************************
sub _name_for_stream {
  my ($attr) = @_;
  
  return $attr->{ID} || 'CAM';
}

#**********************************************************
=head2 _get_cakephp_data_payload($attr)

  Arguments :
    $attr - hash_ref
      Name - camera name (Required)
      Host - camera host (Required)
      Path - path on camera (Required)
      Port - camera RTSP_PORT (default : 554)
      
  Returns:
   string

=cut
#**********************************************************
sub _get_cakephp_data_payload {
  my ($attr) = shift;
  
  my $entity = $attr->{ENTITY} || '';
  my %params = %{$attr->{PARAMS} ? $attr->{PARAMS} : {}};
  
  if ( $entity eq 'Monitor' ) {
    $attr->{Path} = urlencode($attr->{Path}) if ($attr->{Path});
  }
  
  return join('&', map { $entity . "[$_]=" . $params{$_} } sort keys %params);
}


#**********************************************************
=head2 get_monitor_id_by_billing_id($billing_id)

  Get all streams and return first where billing id is found at the end of name

=cut
#**********************************************************
sub get_monitor_id_by_billing_id {
  my ($self, $billing_id) = @_;
  
  my $zm_streams = $self->monitors_list();
  
  if ( $zm_streams && ref $zm_streams eq 'ARRAY' ) {
    my @streams = grep { $_->{Monitor}->{Name} eq $billing_id } @{$zm_streams};
    if ( scalar @streams > 0 ) {
      return $streams[0]->{Monitor}->{Id};
    }
  }
  
  return -1;
}

1;