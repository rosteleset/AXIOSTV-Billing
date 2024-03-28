package AXbills::Backend::Plugin::Websocket::Session;

use strict;
use warnings FATAL => 'all';

use AXbills::Backend::Defs;

use Protocol::WebSocket::Frame;
my $main_frame = Protocol::WebSocket::Frame->new;

#**********************************************************
=head2 new($handle, $socket_id, $aid)

=cut
#**********************************************************
sub new {
  my $class = shift;

  my ($handle, $socket_id, $aid) = @_;
  
  my $self = {
    handle    => $handle,
    socket_id => $socket_id,
    aid       => $aid
  };
  
  bless($self, $class);
  
  return $self;
}


#**********************************************************
=head2 handle() -

  Arguments:
     -
    
  Returns:
    
    
=cut
#**********************************************************
sub handle {
  my $self = shift;

  return $self->{handle};
}

#**********************************************************
=head2 request($data) -

  Arguments:
    $data -
    
  Returns:
    
    
=cut
#**********************************************************
sub request {
  my $self = shift;
  my ( $data ) = @_;

  $self->{handle}->push_write($main_frame->new($data)->to_bytes);
  
  return 1;
}

#**********************************************************
=head2 kill($reason) - sends client 'goodbye' message

  Arguments:
    $reason - human readable reason
    
    
=cut
#**********************************************************
sub kill {
  my $self = shift;
  my ($reason) = @_;

  $reason //= "unknown";
  
  my $handle = $self->{handle};
  
  if ( defined $handle && defined $main_frame && ref $handle && !$handle->destroyed ) {
    $self->request('{"TYPE" : "close", "REASON" : "' . $reason . '"}');
    $handle->destroy;
  }
  
  delete $self->{handle};
  
  return;
}

DESTROY {
  my $self = shift;
  $self->kill('DESTROY');
}

1;
