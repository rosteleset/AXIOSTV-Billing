package AXbills::Backend::Plugin::Telegram;
use strict;
use warnings FATAL => 'all';

use AnyEvent;
use AnyEvent::Handle;
use AnyEvent::Socket;
use Encode;
use utf8;

use AXbills::Backend::Plugin::BasePlugin;
use parent 'AXbills::Backend::Plugin::BasePlugin';
use AXbills::Backend::Plugin::Telegram::API;

our Admins $admin;
our (%conf, $db, $base_dir);

BEGIN {
  use AXbills::Backend::Defs;
}

$conf{TELEGRAM_API_REQUEST_INTERVAL} //= 3;

use AXbills::Backend::Plugin::Telegram::BotAPI;
use AXbills::Backend::Plugin::Telegram::Operation;
use AXbills::Backend::Plugin::Telegram::ModuleInterface;

use AXbills::Experimental::Language;

use Contacts;
use Users;

my $Contacts = Contacts->new($db, $admin, \%conf);
my $Users = Users->new($db, $admin, \%conf);

use Data::Dumper;
use AXbills::Base qw/_bp/;
#_bp('', '', { SET_ARGS => { TO_CONSOLE => 1 } });

use AXbills::Backend::Log;
my $log_file = $conf{TELEGRAM_LOG} || (($base_dir || '/usr/axbills') . '/var/log/telegram.log');
my $debug = $conf{TELEGRAM_DEBUG} || 3;
my $Log = AXbills::Backend::Log->new('FILE', $debug, 'Telegram main', { FILE => $log_file });

my $Bot_API;

my %user_for_chat_id = ();
my %admin_for_chat_id = ();

# Operation will get all messages for client while in 'locked' mode
my %operation_lock_on_chat_id = ();


#**********************************************************
=head2 new()

=cut
#**********************************************************
sub new {
  my $class = shift;

  my $self;
  $self = {
    token          => $conf{TELEGRAM_TOKEN},
    last_update_id => 0,
    config         => \%conf,
    debug          => $debug,
    cb             => {
      'default'   => sub {
        $self->action_unknown_command(@_);
      },
      '/balance'  => sub {
        my $message = shift;
        $self->send_text("Sorry, but I can't do it now", $message->{chat}->{id});
      },
      '/hello'    => sub {
        my $message = shift;
        $self->action_greetings($message->{chat}->{id});
      },
      '/language' => sub {
        my $message = shift;
        $self->change_language_operation($message->{chat}->{id})
      }
    }
  };

  bless($self, $class);
  return $self;
}

#**********************************************************
=head2 init() - begins Telegram API work

  Returns:
    AXbills::Backend::Plugin::Telegram::API instance
    
=cut
#**********************************************************
sub init {
  my ($self) = @_;

  $self->{Language} = AXbills::Experimental::Language->new($base_dir || '/usr/axbills/', $conf{default_language});

  $Bot_API = AXbills::Backend::Plugin::Telegram::BotAPI->new(\%conf, {
    token => $self->{token},
    debug => $self->{debug}
  });

  # Set renew clients every 5 min
  $self->{renew_clients_timer} = AnyEvent->timer(
    after    => 1,
    interval => 600,
    cb       => sub {
      # Get authorized clients
      $Log->info('Renewing contact info');
      $self->load_clients();
    }
  );

  if ($conf{TELEGRAM_LOAD_EXTENSIONS}) {
    my @extension_files = split(',\s', $conf{TELEGRAM_LOAD_EXTENSIONS});
    foreach my $extension (@extension_files) {
      eval {
        require "AXbills/Backend/Plugin/Telegram/Extension/$extension.pm";
        "AXbills::Backend::Plugin::Telegram::Extension::$extension"->import();

        my $add_callback_func = "AXbills::Backend::Plugin::Telegram::Extension::$extension\::add_extensions";
        my $ref = \&{$add_callback_func};
        &{$ref}($self);

        $Log->info("Loaded $extension extension");
      };
      if ($@) {
        $Log->warning("Can't load $extension extension. $@");
      }
    }
  }

  $self->set_timer($self->{config}->{TELEGRAM_API_REQUEST_INTERVAL} || 3);

  return AXbills::Backend::Plugin::Telegram::API->new($self->{config}, $self);
}

#**********************************************************
=head2 set_timer()

=cut
#**********************************************************
sub set_timer {
  my ($self, $interval) = @_;

  $self->{timer} = AnyEvent->timer(
    after    => 0,
    interval => $interval,
    cb       => sub {
      $Log->debug("Requesting updates");

      eval {
        $Bot_API->getUpdates(
          {
            offset          => $self->{last_update_id} + 1,
            timeout         => ($interval > 1 ? $interval - 1 : 1),
            allowed_updates => [ 'message', 'callback_query' ]
          },
          sub {
            my $updates = shift;

            if ($updates->{ok}) {
              if ($updates->{result} && ref $updates->{result} eq 'ARRAY') {
                $self->process_updates(@{$updates->{result}});
                return;
              }
            }

            if ($updates->{error_code}) {
              my $text = $updates->{description} || $updates->{error} || 'Unknown error';
              my $code = $updates->{error_code} || '-1';

              # my $debug_info = q{};
              # foreach my $key ( keys %$updates ) {
              #   $debug_info .= "$key -> $updates->{$key}\n";
              # }

              $Log->warning("Error on request. $code : $text");

              if ($code eq '401') {
                $Log->alert($text . '. Stopping to request Telegram updates');
                $Log->alert('Check $conf{TELEGRAM_TOKEN}');
                delete $self->{timer};
              }

              return;
            }
            else {
              $Log->warning('Error on request : Unknown error');
            }

          }
        );
      };
      if ($@) {
        $Log->error("Can't get updates : " . $@);
      }
    });

  return 1;
}

#**********************************************************
=head2 add_callback($message, $cb)

=cut
#**********************************************************
sub add_callback {
  my ($self, $message, $cb) = @_;
  $self->{cb}->{$message} = $cb;
  return 1;
}

#**********************************************************
=head2 remove_callback()

=cut
#**********************************************************
sub remove_callback {
  my ($self, $name) = @_;
  delete $self->{cb}->{$name};
  return 1;
}

#**********************************************************
=head2 process_updates()

=cut
#**********************************************************
sub process_updates {
  my ($self, @updates) = @_;

  # Show message
  foreach my $update (@updates) {
    # Sometimes telegram send old (already processed) updates
    next if ($self->{last_update_id} && $update->{update_id} <= $self->{last_update_id});

    $self->{last_update_id} = $update->{update_id};

    my $message = $update->{message};
    #    print Dumper($update) if ( $self->{debug} > 4 );
    #    print Dumper($message) if ( $self->{debug} > 3 );
    #
    #    if ( $message->{contact} ) {
    #      print "Got phone: $message->{contact} $message->{contact}->{phone_number} \n";
    #      next;
    #    }

    my $is_query = exists $update->{callback_query};
    my $is_message = exists $message->{text};

    # Ignore unsupported updates
    next unless ($is_message || $is_query);

    my $chat_id = ($is_query)
      ? $update->{callback_query}->{from}->{id}
      : ($is_message)
      ? $message->{chat}->{id}
      : 0;

    next unless ($chat_id);

    my $authorized = $self->is_authenticated($chat_id);
    my $client_type = ($authorized < 0) ? 'UID' : 'AID',;
    my $client_id = ($authorized < 0) ? $user_for_chat_id{$chat_id} : $admin_for_chat_id{$chat_id};

    # Fix encoding
    if ($is_message && $message->{text}) {
      my $message_decoded = Dumper($message->{text});
      if ($message_decoded =~ /\\x\{/) {
        $message->{text} = Encode::encode_utf8($message->{text});
      }
    }

    if ($chat_id && exists $operation_lock_on_chat_id{$chat_id}) {
      $Log->debug("Sending message|query to operation for $chat_id");
      my AXbills::Backend::Plugin::Telegram::Operation $operation = $operation_lock_on_chat_id{$chat_id};

      my $should_finish_operation = 0;
      if (
        ($is_query && $update->{callback_query}->{data} eq 'cancel')
          || ($is_message && $message->{text} eq '/cancel')
      ) {
        $should_finish_operation = 1;
      }
      else {
        $should_finish_operation = ($is_query)
          ? $operation->on_callback_query($update->{callback_query}->{data})
          : ($is_message)
          ? $operation->on_message($message)
          : 0;
      }

      if ($should_finish_operation) {
        $operation->on_finish();
        delete $operation_lock_on_chat_id{$chat_id};
        $Log->debug("Finished operation for $chat_id");
      }
      else {
        $Log->debug("Operation choosed to go on for $chat_id");
      }

      next;
    }

    if (exists $update->{callback_query}
      && $update->{callback_query}->{from}
      && $update->{callback_query}->{from}->{id}
    ) {

      unless ($authorized) {
        $Log->notice("Unathorized callback query message from $chat_id");
        next;
      };

      $Log->debug("Got callback data request for $client_type#$client_id");

      $self->process_callback_query(
        $update->{callback_query},
        {
          CHAT_ID     => $chat_id,
          CLIENT_TYPE => $client_type,
          CLIENT_ID   => $client_id
        }
      );

      next;
    }


    # Check for start command
    if ($message->{text} && $message->{text} =~ /^\/start/) {
      if ($message->{text} =~ /\/start ([ua])_([a-zA-Z0-9]+)/) {
        my $type = $1;
        my $sid = $2;

        $Log->notice("Auth for $type $sid");

        if ($self->authenticate($type, $sid, $chat_id)) {
          $Log->notice("Registered $type $chat_id  $sid");
          $self->send_text("You've been registered", $chat_id);
          $Pub->emit('user_authenticated', $chat_id);
          next;
        }
      }

      my $username = $message->{from}->{firstname} || $message->{from}->{username} || '';
      $Log->notice("Auth failed for $username ($chat_id)");
      $self->send_text("Sorry, $username, can't authorize you. Please log in to web interface and try again",
        $chat_id);

      next;
    }

    # Check if we have such a client
    if (!$authorized) {
      $self->send_text("Unauthorized", $chat_id);
    }
    else {
      $self->process_message($message, {
        CHAT_ID     => $chat_id,
        CLIENT_TYPE => $client_type,
        CLIENT_ID   => $client_id,
      });
    }
  };

  return $self->{last_update_id};
}


#**********************************************************
=head2 process_message($message) - process messages from commands and text

  Arguments:
    $message -
    $attr
      CHAT_ID
      CLIENT_TYPE
      CLIENT_ID
      
  Returns:
  
  
=cut
#**********************************************************
sub process_message {
  my ($self, $message, $attr) = @_;

  return 0 unless ($attr->{CHAT_ID});

  my $chat_id = $attr->{CHAT_ID};
  my $client_type = $attr->{CLIENT_TYPE};
  my $client_id = $attr->{CLIENT_ID};

  my $message_text = $message->{text} || '';
  # Differentiate a command with data
  if ($message_text =~ /^(\/[a-z]+)/) {
    $message_text = $1;
  }

  $Log->debug("Message from $chat_id ($client_type#$client_id)");

  if (defined $self->{cb}->{$message_text}) {
    eval {
      my $res = $self->{cb}->{$message_text}->($message, $chat_id, $client_type, $client_id);

      if ($res && ref $res && $res->isa('AXbills::Backend::Plugin::Telegram::Operation')) {
        $operation_lock_on_chat_id{$chat_id} = $res;
        $res->start();
      }
    };
    if ($@) {
      $Log->notice("Error happened while processing message : $@");
    }
  }
  else {
    $self->{cb}->{default}->($message, $chat_id, $client_type, $client_id);
  }

  return;
}

#**********************************************************
=head2 process_callback_query($query) - processes update got from message button

  Arguments:
    $query -
    
  Returns:
    1 if started operation
  
=cut
#**********************************************************
sub process_callback_query {
  my ($self, $query, $attr) = @_;

  return 0 unless ($attr->{CHAT_ID});

  # TODO: Check if already in operation

  my $data_raw = $query->{data};
  return 0 unless ($data_raw);

  my (@data) = split(':', $data_raw);
  my $module = shift @data;

  return 0 unless ($module);

  $attr->{callback_query_id} = $query->{id};
  my AXbills::Backend::Plugin::Telegram::Operation $operation = 0;

  if (uc $module eq 'MSGS') {
    $Log->info("Callback query for MSGS");
    $operation = AXbills::Backend::Plugin::Telegram::ModuleInterface::process_data($self, \@data, $attr);
  }
  return 0 unless ($operation);

  # Set lock ( all messages will go to operation )
  $operation_lock_on_chat_id{$attr->{CHAT_ID}} = $operation;

  $operation->start();

  return 1;
}


#**********************************************************
=head2 is_authenticated($chat_id) - checks if is authorized

  Arguments:
    $chat_id - chat_id to check
    
  Returns:
    -1 for user
    1 for admin
    0 if not authorized
    
=cut
#**********************************************************
sub is_authenticated {
  my ($self, $chat_id) = @_;

  return -1 if (exists $user_for_chat_id{$chat_id});
  return 1 if (exists $admin_for_chat_id{$chat_id});

  return 0;
}

#**********************************************************
=head2 send_text($text, $chat_id, $options, $callback) - sends text to admin

  Arguments:
    $text -
    
  Returns:
    1 if sent
    
=cut
#**********************************************************
sub send_text {
  my ($self, $text, $chat_id, $telegram_message_options, $callback) = @_;

  if (!$chat_id) {
    print " Have to send response without \$chat_id. No \n" if ($self->{debug});
    return;
  }

  my %message_hash = (
    chat_id => $chat_id,
    text    => $self->format_text($text, $chat_id),
    %{$telegram_message_options // {}},
  );

  $Log->debug("Sending message to $chat_id" . Dumper(\%message_hash));

  my $result_callback = $callback // sub {
    my $res = shift || 0;
    $Log->debug("Sent message to $chat_id result : " . Dumper($res));

    if ($callback) {
      $callback->($res);
    }
  };

  $Bot_API->sendMessage(\%message_hash, $result_callback);

}

#**********************************************************
=head2 send_callback_answer($chat_id, $callback_query_id, $text) - answer and close callback query

  Arguments:
    $chat_id
    $callback_query_id
    $text
    
  Returns:
  
  
=cut
#**********************************************************
sub send_callback_answer {
  my ($self, $callback_query_id, $text, $chat_id) = @_;

  if (!$callback_query_id) {
    print " Have to send response without \$callback_query_id. No \n" if ($self->{debug});
    return;
  }

  $Log->debug("Answer to callback");

  $Bot_API->answerCallbackQuery({
    callback_query_id => $callback_query_id,
    text              => $self->format_text($text, $chat_id)
  }, sub {
    $Log->debug("Answered to callback");
  }
  );
}

#**********************************************************
=head2 format_text($text, $chat_id) - translation and format text before sending

  Arguments:
    $text
    $chat_id -
    
  Returns:
  
  
=cut
#**********************************************************
sub format_text {
  my ($self, $text, $chat_id) = @_;

  my $language_for_message = $chat_id
    ? ($self->get_lang_for_chat_id($chat_id))
    : ($conf{default_language} || 'russian');

  my AXbills::Experimental::Language $Language = $self->{Language};
  if (!$Language->has_language($language_for_message)) {
    # Load main language
    $Language->load($language_for_message);
  }

  return $Language->translate($text, $language_for_message);
}

#**********************************************************
=head2 get_lang_for_chat_id($chat_id) -

  Arguments:
    $chat_id -
    
  Returns:
  
    
=cut
#**********************************************************
sub get_lang_for_chat_id {
  my ($self, $chat_id) = @_;

  my $default_language = $conf{default_language} || 'russian';

  if (exists $user_for_chat_id{$chat_id}) {
    my $client_info = $self->get_user_info($user_for_chat_id{$chat_id});
    return $client_info->{__LANGUAGE} || $default_language;
  }

  return $default_language;
}

#**********************************************************
=head2 load_language($lang_name, $file_path) - loads and saves lang hash

  Arguments:
    $lang_name -
    $file_path -
    
  Returns:
    1 if loaded
    
=cut
#**********************************************************
sub load_language {
  my ($self, $lang_name, $module) = @_;

  eval {
    my AXbills::Experimental::Language $Language = $self->{Language};
    $Language->load($lang_name, $module);
  };
  if ($@) {
    $Log->critical("Can't load $lang_name language : $@");
    return 0;
  }

  return 1;
}


#**********************************************************
=head2 action_show_message($message_obj) - simply prints to console

  Arguments:
    $message_obj -
    
  Returns:
  
  
=cut
#**********************************************************
sub action_show_message {
  my ($self, $message) = @_;

  if ($self->{debug} > 5) {
    print Dumper $message;
    return 1;
  }

  eval {
    my $name = ($message->{from}->{username} ? $message->{from}->{username} : "$message->{from}->{first_name}");
    print "#$message->{message_id} $name ($message->{from}->{id}) \n$message->{text} \n";
  };
  if ($@) {
    print $@ . "\n";
  }

  return 1;
}


#**********************************************************
=head2 action_greetings($chat_id) - Greets given recipient

  Arguments:
    $chat_id -
    
  Returns:
  
  
=cut
#**********************************************************
sub action_greetings {
  my ($self, $chat_id) = @_;

  if (exists $user_for_chat_id{$chat_id}) {
    $self->send_text("Hello, user", $chat_id);
  }
  elsif (exists $admin_for_chat_id{$chat_id}) {
    $self->send_text("Hello, admin", $chat_id);
  }

  return 1;
}

#**********************************************************
=head2 action_unknown_command($message) - actions defined for undefined command

  Arguments:
    $message -
    
  Returns:
  
  
=cut
#**********************************************************
sub action_unknown_command {
  my ($self, $message) = @_;

  my $chat_id = $message->{chat}->{id};

  # Got 'Wide character ...' without this
  Encode::_utf8_off($message->{text});

  $Log->debug("Don't know how should respond for: $message->{text}\n");

  $self->action_show_message($message);
  $self->send_text("_{ERROR}_. Sorry, can't understand you", $chat_id);

  # Maybe : show commands

  return;
}

#**********************************************************
=head2 change_language_operation($chat_id) - show menu for language selection

  Arguments:
    $chat_id -
    
  Returns:
    Telegram::Operation
    
=cut
#**********************************************************
sub change_language_operation {
  my AXbills::Backend::Plugin::Telegram $Telegram_Bot = shift;
  my ($chat_id) = @_;

  my $client_auth = $Telegram_Bot->is_authenticated($chat_id);
  return 0 unless ($client_auth);

  # TODO: change language for admin
  if ($client_auth == 1) {
    $Log->info('Admin tried to change language');
    $Telegram_Bot->send_text("_{ERR_NOT_IMPLEMENTED}_", $chat_id);
    return 1;
  }

  my $client_type = 'u';
  my $client_id = $user_for_chat_id{$chat_id};

  my $languages_str = $conf{LANGS} || 'russian:Русский;english:English';
  my %language_names = ();
  foreach my $lang_name (split(/;\n?\s?/, $languages_str)) {
    my ($lang, $name) = split(':', $lang_name);

    $language_names{$lang} = $name;
  }

  return AXbills::Backend::Plugin::Telegram::Operation->new({
    CHAT_ID           => $chat_id,
    TYPE              => $client_type,
    CLIENT_ID         => $client_id,
    NAME              => 'CHANGE_LANGUAGE_OPERATION',
    ON_START          => sub {
      my ($self) = @_;

      $Log->debug('LANGUAGE. User starts to change language');

      # Form language keyboard
      my @keyboard = ();
      foreach my $lang_name (sort keys %language_names) {
        # Every should stay on self line
        push(@keyboard, [ { text => $language_names{$lang_name}, callback_data => $lang_name } ])
      }

      my $current_language_string = "_{CURRENT_LANGUAGE}_ : " . ($Telegram_Bot->get_lang_for_chat_id($self->{CHAT_ID}));

      # Send menu
      $Telegram_Bot->send_text("$current_language_string. \n_{AVAILABLE_LANGUAGES}_: ", $self->{CHAT_ID}, {
        reply_markup => {
          inline_keyboard => \@keyboard
        }
      });

      return 0;
    },
    ON_CALLBACK_QUERY => sub {

      $Log->debug('LANGUAGE. User gave callback');

      my ($self, $query_data) = @_;
      $Telegram_Bot->send_text($query_data, $self->{CHAT_ID});

      # Check language exists
      if ($language_names{$query_data}) {
        # Save language
        $Users->pi_change({ UID => $self->{CLIENT_ID}, __LANGUAGE => $query_data });

        # Renew user info
        $Telegram_Bot->{users_info}->{$self->{CLIENT_ID}}->{__LANGUAGE} = $query_data;
        $Log->debug('LANGUAGE. CHANGED');

        return 1;
      }
      else {
        $Log->debug('LANGUAGE. Error');

        $Telegram_Bot->send_text('_{ERROR}_ ( /cancel  ?)', $self->{CHAT_ID});
        return 0;
      }

    },
    ON_MESSAGE        => sub {
      my ($self) = @_;
      $Log->debug('LANGUAGE. Error, got message');

      $Telegram_Bot->send_text('_{ERROR}_. _{PLEASE_CHOOSE_YOUR_LANGUAGE}_. ( /cancel ?)', $self->{CHAT_ID});
      return 0;
    },
    ON_FINISH         => sub {
      my $self = shift;
      $Log->debug('LANGUAGE. Finished');

      my $user_language = $Telegram_Bot->{users_info}->{$self->{CLIENT_ID}}->{__LANGUAGE};

      $Telegram_Bot->send_text(
        '_{CURRENT_LANGUAGE}_ : ' . $user_language,
        $self->{CHAT_ID}
      );
    }
  });
}

#**********************************************************
=head2 authenticate($type, $sid) - authenticates new Telegram receiver

  Arguments:
    $type - u|a
    $sid  -
    
  Returns:
  
  
=cut
#**********************************************************
sub authenticate {
  my ($self, $type, $sid, $chat_id) = @_;

  if ($type eq 'u') {
    my $uid = $Users->web_session_find($sid);

    if ($uid) {

      # Check if already have an account
      my $list = $Contacts->contacts_list({
        TYPE  => $Contacts::TYPES{TELEGRAM},
        VALUE => $chat_id,
      });

      if (!$Contacts->{TOTAL} || scalar(@{$list}) == 0) {
        $Contacts->contacts_add({
          UID      => $uid,
          TYPE_ID  => $Contacts::TYPES{TELEGRAM},
          VALUE    => $chat_id,
          PRIORITY => 0,
        });
      }
      $user_for_chat_id{$chat_id} = $uid;
      return 1;
    }
    return 0;
  }
  elsif ($type eq 'a') {
    $admin->online_info({ SID => $sid });

    my $aid = $admin->{AID};

    if ($aid) {
      my $list = $admin->admins_contacts_list({
        TYPE  => $Contacts::TYPES{TELEGRAM},
        VALUE => $chat_id
      });

      if (!$admin->{TOTAL} || scalar(@{$list}) == 0) {
        $admin->admin_contacts_add({
          AID      => $aid,
          TYPE_ID  => $Contacts::TYPES{TELEGRAM},
          VALUE    => $chat_id,
          PRIORITY => 0,
        });
      }

      $admin_for_chat_id{$chat_id} = $aid;
      return 1;
    }
    return 0;
  }

  return;
}
#**********************************************************
=head2 get_user_info($uid)

=cut
#**********************************************************
sub get_user_info {
  my ($self, $uid) = @_;

  return 0 unless $uid;

  if (!$self->{users_info}{$uid} || ref $self->{users_info}{$uid} ne 'HASH') {
    my $Users_for_pi = Users->new($db, $admin, \%conf);
    $Users_for_pi->pi({ UID => $uid });
    return 0 if ($Users_for_pi->{errno});

    $Log->debug($Users_for_pi->{__LANGUAGE});
    $self->{users_info}->{$uid} = { %$Users_for_pi };
  }

  return $self->{users_info}->{$uid}
}

#**********************************************************
=head2 load_clients() - reads registered contacts from DB (contacts)

=cut
#**********************************************************
sub load_clients {

  my $client_telegram_accounts = $Contacts->contacts_list({
    TYPE  => $Contacts::TYPES{TELEGRAM},
    VALUE => '_SHOW',
    UID   => '_SHOW'
  });
  foreach (@{$client_telegram_accounts}) {
    $user_for_chat_id{$_->{value}} = $_->{uid};
  }

  my $admin_telegram_accounts = $admin->admins_contacts_list({
    TYPE  => $Contacts::TYPES{TELEGRAM},
    VALUE => '_SHOW',
    AID   => '_SHOW'
  });
  foreach (@{$admin_telegram_accounts}) {
    $admin_for_chat_id{$_->{value}} = $_->{aid};
  }

  return 1;
}

1;