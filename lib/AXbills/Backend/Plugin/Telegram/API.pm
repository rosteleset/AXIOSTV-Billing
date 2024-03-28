package AXbills::Backend::Plugin::Telegram::API;
use strict;
use warnings FATAL => 'all';

=head1 NAME

  AXbills::Backend::Plugin::Telegram::API

=head2 SYNOPSIS

  This package aggregates functions to communicate with Telegram plugin

=cut

use AXbills::Backend::Plugin::BaseAPI;
use parent 'AXbills::Backend::Plugin::BaseAPI';

#**********************************************************
=head2 process_internal_message($data)

  Arguments:
    $data -
    
  Returns:
    1
    
=cut
#**********************************************************
sub process_internal_message {
  my ($self, $data) = @_;
  
  my AXbills::Backend::Plugin::Telegram $telegram = $self->{plugin_object};
  
  if ( $data->{SEND_MESSAGE} ) {
    my $message_data = $data->{SEND_MESSAGE};
    
    my $message = $message_data->{MESSAGE};
    my $chat_id = $message_data->{CHAT_ID};
    
    return $telegram->send_text($message, $chat_id, $message_data, 0);
  }
  
  return 0;
}


1;