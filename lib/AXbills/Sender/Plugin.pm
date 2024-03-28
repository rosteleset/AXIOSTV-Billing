package AXbills::Sender::Plugin;
use strict;
use warnings FATAL => 'all';

#**********************************************************
=head2 new($db, $admin, $CONF)
  
  Returns:
    object
    
=cut
#**********************************************************
sub new{
  my $class = shift;
  my $self = {};
  
  bless( $self, $class );
  return $self;
}

#**********************************************************
=head2 send_message()

=cut
#**********************************************************
sub send_message {
  "DUMMY";
}

#**********************************************************
=head2 contact_types() -

  Arguments:
    $default -
  Returns:

  Examples:

=cut
#**********************************************************
sub contact_types {
  my ($self, $default) = @_;

  return $self->{CONTACT_TYPE} || $default;
}

#**********************************************************
=head2 support_batch() - tells Sender, we can NOT accept more than one recepient per call

=cut
#**********************************************************
sub support_batch {
  return 0;
}

1;