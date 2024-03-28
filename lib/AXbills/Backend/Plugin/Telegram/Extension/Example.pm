package AXbills::Backend::Plugin::Telegram::Extension::Example;
use strict;
use warnings FATAL => 'all';

=head2 NAME

  AXbills::Backend::Plugin::Telegram::Extension::Example
  
=head2 SYNOPSIS

  Example extension for ABillS Telegram bot.
  Copy it to Extension/Custom_%YOUR_EXTENSION_NAME%.pm to prevent it from erasing on update,
  and add to $conf{TELEGRAM_LOAD_EXTENSIONS} = 'Custom_%YOUR_EXTENSION_NAME%, Custom_%YOUR_ANOTHER_EXTENSION_NAME%.pm';
  
  You can change anything between this #cccccccccccccccccccccccccc# lines as long as it is correct perl code.
  
  By default you should just define a command and a coderef to call when text was received
  You also can redeclare 'default' callback to receive all messages without callback defined
  
  Each callback recieves this arguments:
    $message - perl structure (hash_ref) for Telegram API Message object (https://core.telegram.org/bots/api#message)
    $chat_id - is id for client who has send the message
    $client_type - can be AID or UID. dependens on how client has been registered.
     If person has contact for both admin and user account, User privileges are used.
    $client_id   - id of person's account in ABillS (uid for client  and  aid for admin)

  
=cut

our ($db, $admin, %conf, $base_dir, $Pub);

use AXbills::Backend::Log;
use AXbills::Backend::Defs;
use AXbills::Backend::Plugin::Telegram;
use AXbills::Backend::Plugin::Telegram::Extension;
use parent 'AXbills::Backend::Plugin::Telegram::Extension';

use AXbills::Backend::Plugin::Telegram::Operation;

#cccccccccccccccccccccccccc#
# you SHOULD change this
my $EXTENSION = 'Example';

# you CAN Delete this if you don't want ( and will not ) use $Log
# Logging levels defined by $conf{TELEGRAM_EXTENSIONS_DEBUG} or $conf{TELEGRAM_EXTENSION_%EXTENSION%_DEBUG} variables
my AXbills::Backend::Log $Log =
  AXbills::Backend::Plugin::Telegram::Extension::build_log_for(
    $EXTENSION,
    '/usr/axbills/var/log/telegram_example.log'
  );
#cccccccccccccccccccccccccc#


#**********************************************************
=head2 add_extensions()

=cut
#**********************************************************
sub add_extensions {
  my AXbills::Backend::Plugin::Telegram $Telegram_Bot = shift;
  
  #cccccccccccccccccccccccccc#
  # Example of sending simple text response
  $Telegram_Bot->add_callback('/help', sub {
      my ($first_message, $chat_id, $client_type, $client_id) = @_;
      $Log->info("$client_type #$client_id requested for /help. Ha-ha");
      $Telegram_Bot->send_text("No help for you now, $client_type #$client_id", $chat_id);
    });
  
  # Example of returning operation
  $Telegram_Bot->add_callback('/echo', sub {
      my ($first_message, $chat_id, $client_type, $client_id) = @_;
    
      my $operation = AXbills::Backend::Plugin::Telegram::Operation->new({
        CHAT_ID    => $chat_id,
        TYPE       => $client_type,
        NAME       => 'ECHO_OPERATION',
        ON_START   => sub {
          $Telegram_Bot->send_text("Print text to echo", $chat_id);
        },
        ON_MESSAGE => sub {
          my ($self, $message) = @_;
          
          if ( !$message->{text} ) {
            $Telegram_Bot->send_text('_{TEXT_NOT_FOUND}_. _{TRY_AGAIN}_', $chat_id);
            return 0;
          }
          else {
            $Telegram_Bot->send_text($message->{text}, $chat_id);
            return 1;
          }
        },
      });
      
      return $operation;
    });
  #cccccccccccccccccccccccccc#
  
  $Pub->on('user_authenticated', sub {
      my ($chat_id) = @_;
      $Telegram_Bot->send_text("/help", $chat_id);
    });
  
  return 1;
}

1;