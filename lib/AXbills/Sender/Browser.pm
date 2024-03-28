package AXbills::Sender::Browser;
use strict;
use warnings FATAL => 'all';

use parent 'AXbills::Sender::Plugin';

use AXbills::Base qw/_bp in_array/;
use AXbills::Backend::API;

sub AUTOLOAD{
  our $AUTOLOAD;
  return if ($AUTOLOAD =~ /::DESTROY$/);
  
  my ($func) = $AUTOLOAD =~ /.*::(.*)$/;
  
  # Pass calls to api (Maybe change to inheritance)
  my $self = shift;
  die "Undefined function $func" if (!$self->{api}->can($func));
  return $self->{api}->$func(@_);
}

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
  my ($conf) = @_;
  
  my $self = {
    token => $conf->{WEBSOCKET_TOKEN},
  };
  
  bless $self, $class;
  
  $self->{api} = AXbills::Backend::API->new($conf, {
      TOKEN => $self->{token}
    });
  
  if(!$self->{api}){
    return 0;
  }
  
  return $self;
}


#**********************************************************
=head2 send_message($attr)

  Arguments:
    $attr -
      UID|AID  - string, receiver ( TODO: '*' to send to all of this type)
      MESSAGE  - string, text of message
      
      NON_SAFE - boolean, will use instant request (without confirmation)
     
      ASYNC    - coderef, asynchronous callback

  Returns:
    1 if sended;

=cut
#**********************************************************
sub send_message {
  my ($self, $attr) = @_;
  
  #  return 0 unless $self->{fh};
  
  my $receiver_type = (exists $attr->{AID}) ? 'ADMIN' : 'USER';
  my $receiver_id = $attr->{AID} || $attr->{UID};
  
  # Has no one to send message to
  return undef unless ($receiver_id);
  
  my %payload = (
    TYPE => 'MESSAGE',
    TO   => $receiver_type,
    ID   => $receiver_id,
    TOKEN => $self->{token},
    DATA => {
      TYPE  => 'MESSAGE',
      TITLE => $attr->{TITLE} || $attr->{SUBJECT},
      TEXT  => $attr->{MESSAGE}
    }
  );

  return $self->{api}->_request($attr, \%payload);
}


#**********************************************************
=head2 connected_admins() - Get connected admins

  Returns:
    list - aids of connected admins

=cut
#**********************************************************
sub connected_admins {
  my $self = shift;
  
  my %request = (
    TYPE      => 'REQUEST_LIST',
    LIST_TYPE => 'ADMINS',
  );

  my $responce = $self->{api}->json_request( { MESSAGE => \%request } );

  if(! $responce) {
    return 0;
  }

  #TODO: check for errors
  my $connected = $responce->{LIST};
  
  return $connected;
}

#**********************************************************
=head2 has_connected_admin($aid) - check if certain admin is present in connected sockets

  Arguments:
    $aid - admin ID

  Returns:
    boolean - if connected

=cut
#**********************************************************
sub has_connected_admin {
  my $self = shift;
  my ( $aid ) = @_;

  my $admins = $self->connected_admins();
  
  return in_array( $aid, $admins );
}


1;