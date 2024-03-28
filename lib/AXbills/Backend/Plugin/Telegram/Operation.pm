package AXbills::Backend::Plugin::Telegram::Operation;
use strict;
use warnings FATAL => 'all';

=head1 NAME
 
 AXbills::Backend::Plugin::Telegram::Operation
 
=head1 SYNOPSIS

  # Example of returning operation from callback
  
  $Telegram_Bot->add_callback('/echo', sub {
      my ($first_message, $chat_id, $client_type, $client_id) = @_;
    
      my $operation = AXbills::Backend::Plugin::Telegram::Operation->new({
        CHAT_ID    => $chat_id,         # Recepient
        TYPE       => $client_type,     # May be important ('u' for client, 'a' for admin)
        CLIENT_ID  => $client_id,       # May be important (AID or UID)
        CUSTOM_VAR => 'Any var',        # Everything you pass to new() will be available in $self
        NAME       => 'ECHO_OPERATION',
        ON_START   => sub {
        my ($self) = @_;
          $Telegram_Bot->send_text("Print text to echo", $self->{CHAT_ID});
        },
        ON_MESSAGE => sub {
          my ($self, $message) = @_;
          
          if ( !$message->{text} ) {
            $Telegram_Bot->send_text('_{TEXT_NOT_FOUND}_. _{TRY_AGAIN}_', $self->{CHAT_ID});
            # Will not finish operation
            return 0;
          }
          else {
            $Telegram_Bot->send_text($message->{text}, $self->{CHAT_ID});
            # Finish operation
            return 1;
          }
          
        },
        ON_FINISH => sub {
          my ($self) = @_;
          $Telegram_Bot->send_text("Echo operation finished", $self->{CHAT_ID});
        }
      });
      
      return $operation;
    });
    
=cut


#**********************************************************
=head2 new($attr) - constructor for AXbills::Backend::Plugin::Telegram::Operation

  Arguments:
    $attr - hash_ref
      CHAT_ID            -
      TYPE               - string, 'AID' or 'UID'
      NAME               - operation_name (human readable)
      ON_START           - coderef
      ON_MESSAGE         - handler for message
      ON_CALLBACK_QUERY  - handler for callback
      ON_FINISH          - coderef

  Returns:
    $self - AXbills::Backend::Plugin::Telegram::Operation instance
    
=cut
#**********************************************************
sub new {
  my $class = shift;
  my ($attr) = @_;
  
  my $self = \%{$attr};
  
  return 0 unless ( $attr->{CHAT_ID} || $attr->{ON_MESSAGE} );
  
  bless($self, $class);
  
  return $self;
}

#**********************************************************
=head2 start() - run ON_START

  Arguments:
     -
    
  Returns:
  
  
=cut
#**********************************************************
sub start {
  my ($self) = @_;
  
  if ( $self->{ON_START} ) {
    $self->{ON_START}->($self);
  }
  
  return 1;
}

#**********************************************************
=head2 on_message($message) - handle new client message

  Arguments:
    $message -
    
  Returns:
    boolean - 1 if have to finish operation now
    
=cut
#**********************************************************
sub on_message {
  my ($self, $message) = @_;
  return $self->{ON_MESSAGE}->($self, $message);
}

#**********************************************************
=head2 on_callback_query($query_data) -

  Arguments:
    $query_data - content of $update->{callback_query}{data}
    
  Returns:
    boolean - 1 if have to finish operation now
    
=cut
#**********************************************************
sub on_callback_query {
  my ($self,  $query_data) =  @_;
  
  if ( $self->{ON_CALLBACK_QUERY} ) {
    return $self->{ON_CALLBACK_QUERY}->($self, $query_data);
  }
  
  return;
}

#**********************************************************
=head2 on_finish()

=cut
#**********************************************************
sub on_finish {
  my ($self) = @_;
  
  if ( $self->{ON_FINISH} ) {
    $self->{ON_FINISH}->($self);
  }
  
  return 1;
}

1;