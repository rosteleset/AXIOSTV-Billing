package AXbills::Backend::Plugin::Telegram::ModuleInterface;
use strict;
use warnings FATAL => 'all';

=head2 NAME

  AXbills::Backend::Plugin::Telegram::ModuleInterface
  
=cut

# Msgs. will generify later

our ($db, $admin, %conf, $base_dir);
use AXbills::Backend::Plugin::Telegram::Operation;
use AXbills::Experimental::Language;
use AXbills::Base qw/_bp/;

use AXbills::Backend::Log;
my $log_file = $conf{TELEGRAM_LOG} || (($base_dir || '/usr/axbills') . '/var/log/telegram.log');
my $debug = $conf{TELEGRAM_DEBUG} || 7;
my $Log = AXbills::Backend::Log->new('STDOUT', $debug, 'ModuleInterface',);#; { FILE => $log_file });


require Msgs::Messaging;

#**********************************************************
=head2 process_data()
  
  Arguments:
    $api      - API for Telegram plugin
    $data_raw - data as got from callback_query
    $attr     - hash_ref
      SENDER - hash_ref
        CHAT_ID - chat_id
        TYPE    - string, 'AID' or 'UID'
  
  Returns:
    0 on error
    instance of AXbills::Backend::Plugin::Telegram::Operation
    
=cut
#**********************************************************
sub process_data {
  my AXbills::Backend::Plugin::Telegram $api = shift;
  
  my ($data_arr, $attr) = @_;
  return if ( !$attr->{CHAT_ID} || !$data_arr );
  
  # Parse data
  my @data = ();
  if ( ref $data_arr eq 'ARRAY' ) {
    @data = @{$data_arr};
  }
  else {
    @data = split(':', $data_arr);
  }
  
  my $method = shift @data;
  
  my $client_type = $attr->{CLIENT_TYPE};
  my $client_id = $attr->{CLIENT_ID};
  my $chat_id = $attr->{CHAT_ID};
  
  # Load msgs lang vars
  my $lang_name = $api->get_lang_for_chat_id($chat_id) || 'russian';
  my AXbills::Experimental::Language $Language = $api->{Language};
  $Language->load($lang_name, 'Msgs');
  
  if ( $method && $method eq 'REPLY' ) {
    $Log->debug("Got REPLY");
    
    my $msg_id = shift @data;
    my $callback_id = $attr->{callback_query_id};
    
    if ( !$msg_id ) {
      $Log->debug("No MSGS id");
      $api->send_callback_answer($attr->{callback_query_id}, "No MSG id", $chat_id);
      return 0;
    }
    
    
    if ($client_type eq 'UID'){
      my $user_can_reply = msgs_user_can_reply_to_theme($msg_id);
      $Log->debug('Error while checking user can reply') unless defined $user_can_reply;
      if (!$user_can_reply){
        $api->send_text("_{YOU_CANT_REPLY_TO_THIS_MESSAGE}_", $chat_id);
        return 0;
      }
    }
    
    # Create new operation
    return AXbills::Backend::Plugin::Telegram::Operation->new({
      NAME       => 'Reply',
      MSGS_ID    => $msg_id,
      ON_START   => sub {
        $Log->debug("Operation started");
        $api->send_text('_{TYPE_YOUR_RESPONSE}_', $chat_id);
      },
      ON_MESSAGE => sub {
        my ($self, $message) = @_;
        if ( !$message->{text} ) {
          $api->send_text('_{TEXT_NOT_FOUND}_. _{TRY_AGAIN}_', $chat_id);
          return 0;
        }
        
        my $saved = 0;
        eval {
          $Log->debug("Saving reply $client_type");
          $saved = msgs_messaging_save_reply($client_type, $client_id, $msg_id, $message->{text});
          $Log->debug("Reply has been saved");
          $api->send_text('_{SENDED}_', $chat_id);
        };
        if ( !$saved || $@ ) {
          my $err = $@ || '_{UNKNOWN_ERROR}_';
          $Log->debug("Error while replying");
          $api->send_text("$err . _{TRY_AGAIN}_ or use '/cancel' to stop reply", $chat_id);
        }
        $saved;
      },
      ON_FINISH  => sub {
        $Log->debug("Operation finished");
        $api->send_callback_answer($callback_id, '_{SENDED}_', $chat_id);
      },
      %{ $attr },
      
    });
  }
  
  return 0;
}

#**********************************************************
=head2 msgs_messaging_save_reply()

=cut
#**********************************************************
sub msgs_messaging_save_reply {
  my ($client_type, $client_id, $msg_id, $text) = @_;
  
  my $result = 0;
  
  $Log->debug(" Reply goes in Msgs::Messaging");
  
  if ( $client_type eq 'UID' ) {
    $result = msgs_user_reply($msg_id, {
        REPLY_TEXT => $text,
        UID        => $client_id,
        #        STATE => 6
      });
  }
  else {
    $result = msgs_admin_reply($msg_id, {
        REPLY_TEXT => $text,
        AID        => $client_id,
      });
  }
  
  $Log->debug(" Reply goes out from Msgs::Messaging");
  
  return $result
}

1;