package AXbills::Sender::Telegram;
use strict;
use warnings;

use parent 'AXbills::Sender::Plugin';
use AXbills::Base qw(_bp);

our $VERSION = 0.03;

use AXbills::Backend::Plugin::Telegram::BotAPI;
use AXbills::Fetcher;

my %conf = ();
our %lang = ();

my $api_url = 'api.telegram.org';

#**********************************************************
=head2 new($db, $admin, $CONF, $attr) - Create new Telegram object

  Arguments:
    $attr
      CONF

  Returns:

  Examples:
    my $Telegram = AXbills::Sender::Telegram->new($db, $admin, \%conf);

=cut
#**********************************************************
sub new {
  my $class = shift;
  my ($conf) = @_ or return 0;
  
  %conf = %{$conf};
  
  my $self = {
    token   => $conf{TELEGRAM_TOKEN},
    name    => $conf{TELEGRAM_BOT_NAME},
    api_url => $api_url
  };
  
  $self->{api} = AXbills::Backend::Plugin::Telegram::BotAPI->new(\%conf, {
    token   => $conf{TELEGRAM_TOKEN},
    debug   => $conf{TELEGRAM_API_DEBUG},
    api_url => $api_url
  });
  
  die 'No Telegram token ($conf{TELEGRAM_TOKEN})' if ( !$self->{token} );

  $conf{TELEGRAM_LANG} = 'russian' unless($conf{TELEGRAM_LANG});
  my $base_dir = $main::base_dir || '/usr/axbills/';
  require "$base_dir/AXbills/modules/Msgs/lng_$conf{TELEGRAM_LANG}.pl";

  bless $self, $class;
  
  return $self;
}


#**********************************************************
=head2 send_message() - Send message to user with his chat_id or to channel with username(@<CHANNELNAME>)

  Arguments:
    $attr:
      TO_ADDRESS - Telegram ID
      MESSAGE    - text of the message
      PARSE_MODE - parse mode of the message. u can use 'markdown' or 'html' 
      DEBUG      - debug mode
  
  Returns:

  Examples:
    $Telegram->send_message({
      AID        => "235570079",
      MESSAGE    => "testing",
      PARSE_MODE => 'markdown',
      DEBUG      => 1
    });

=cut
#**********************************************************
sub send_message {
  my $self = shift;
  my ($attr) = @_;

  my $text = $attr->{MESSAGE} || '';

  if ( $attr->{PARSE_MODE} ) {
    $attr->{TELEGRAM_ATTR} = {} if ( !$attr->{TELEGRAM_ATTR} );
    $attr->{TELEGRAM_ATTR}->{parse_mode} = $attr->{PARSE_MODE}
  }
  
  if ( $attr->{SUBJECT} ) {
    $text = $attr->{SUBJECT} . "\n\n" . $text;
  }
  
  if ($attr->{DEBUG}){
    $self->{api}{debug} = $attr->{DEBUG};
  }

  $attr->{TELEGRAM_ATTR}->{reply_markup} = make_reply($attr->{MAKE_REPLY}, $attr) if($attr->{MAKE_REPLY});

  if($attr->{ATTACHMENTS}){
    my $result = $self->send_with_attachments($attr);

    if ( $attr->{DEBUG} && $attr->{DEBUG} > 1 ) {
      _bp("Result attachments", $result, { TO_CONSOLE => 1 });
    }
  }

  my $result = $self->{api}->sendMessage({
      chat_id => $attr->{TO_ADDRESS},
      text    => $text,
      %{ $attr->{TELEGRAM_ATTR} // {} }
    });
  
  if ( $attr->{DEBUG} && $attr->{DEBUG} > 1 ) {
    _bp("Result", $result, { TO_CONSOLE => 1 });
  }


  if ( $attr->{RETURN_RESULT} ) {
    return $result;
  }
  
  return $result && $result->{ok};
}

#**********************************************************
=head2 get_updates() -

  Arguments:
    $attr:
      OFFSET - Identifier of the first update to be returned.
               Must be greater by one than the highest among
               the identifiers of previously received updates.
      DEBUG  - debug mode
      
  Returns:
    array_ref of updates or 0
    
  Examples:
    $result = $Telegram->get_updates( { OFFSET => $updateid + 1, DEBUG => 1 } )->{result};

=cut
#**********************************************************
sub get_updates {
  my $self = shift;
  my ($attr) = @_;
  
  my AXbills::Backend::Plugin::Telegram::BotAPI $api = $self->{api};
  
  return $api->getUpdates({ offset => $attr->{OFFSET} || 0 });
}

#**********************************************************
=head2 get_bot_name() - returns this bot name

  Returns:
    string - bot name
    
=cut
#**********************************************************
sub get_bot_name {
  my ($self, $conf, $db) = @_;
  
  $self->{name} //= $conf->{TELEGRAM_BOT_NAME} // $conf->{TELEGRAM_BOT_NAME_AUTO};
  
  if ( !$self->{name} || ($conf->{TELEGRAM_BOT_NAME_AUTO} && $conf->{TELEGRAM_BOT_NAME_AUTO} ne $self->{name}) ) {
    my $bot_url = 'https://' . $self->{api_url} . "/bot$self->{token}/getMe";
    
    my $result = web_request($bot_url, {
        CURL        => 1,
        JSON_RETURN => 1
      });
    
    if ( $result && ref $result eq 'HASH' && $result->{ok} && $result->{result}->{username} ) {
      $self->{name} = $result->{result}->{username};
    }
    
    # Save to conf
    require Conf;
    Conf->import();
    
    require Admins;
    Admins->import();
    
    my $admin_ = Admins->new($db, $conf);
    $admin_->info($conf->{SYSTEM_ADMIN_ID} || 2);
    
    my $Conf = Conf->new($db, $admin_, $conf);
    $Conf->config_add({
      PARAM   => 'TELEGRAM_BOT_NAME_AUTO',
      VALUE   => $self->{name},
      REPLACE => 1,
    });
    
  }
  
  return $self->{name};
}

#**********************************************************
=head2 make_reply() - return reply keyboard

  Returns:
    hash - keyboard

=cut
#**********************************************************
sub make_reply {
  my ($message_id, $sender_attr) = @_;

  my @keyboard = ();

  my $referer = (
    # Allow users to use their own portal URL
    ($sender_attr->{UID} ? $conf{CLIENT_INTERFACE_URL} : '')
      || $conf{BILLING_URL}
      || $ENV{HTTP_REFERER}
      || ''
  );

  my $reply_button = 0;

  my @buttons_files = glob "$conf{base_dir}/AXbills/modules/Telegram/buttons-enabled/*.pm";
  foreach my $file (@buttons_files) {
    my (undef, $button) = $file =~ m/(.*)\/(.*)\.pm/;
    if($button eq 'Msgs_reply'){
      $reply_button = 1;
    }
  }

  if($reply_button && !$sender_attr->{AID}){
      push(@keyboard, { text => $lang{MSGS_REPLY}, 'callback_data' => 'Msgs_reply&reply&' . $message_id });
  } elsif($sender_attr->{AID}){
    push(@keyboard, { text => $lang{MSGS_REPLY},  switch_inline_query_current_chat => "MSGS_ID=$message_id\n" });
  }

  if ($referer =~ /(https?:\/\/[a-zA-Z0-9:\.\-]+)\/?/g) {
    my $site_url = $1;

    if ($site_url) {
      my $link = $site_url;

      if ($sender_attr->{UID}) {
        $link .= "/index.cgi?get_index=msgs_user&ID=$message_id#last_msg";
      }
      elsif ($sender_attr->{AID}) {
        my $receiver_uid = $sender_attr->{SENDER_UID} ? '&UID=' . $sender_attr->{SENDER_UID} : '';
        $link .= "/admin/index.cgi?get_index=msgs_admin&full=1$receiver_uid&chg=$message_id#last_msg";
      }

      push(@keyboard, { text => $lang{MSGS_OPEN}, 'url' => $link });
    }
  }

  return {
    inline_keyboard => [
      \@keyboard
    ]
  }
}

#**********************************************************
=head2 send_with_attachments() - sends message with attachemts

=cut
#**********************************************************
sub send_with_attachments {
  my $self = shift;
  my ($attr) = @_;
  my %groups;

  foreach my $file (@{$attr->{ATTACHMENTS}}){
    my ($type, undef) = split '/', $file->{'content_type'};
    push @{$groups{$type}}, $file;
  }

  my ($fn, $param, $result);

  foreach my $group (keys %groups){
    for my $file (@{$groups{$group}}) {
      if ($group =~ /image/) {
        $fn = 'sendPhoto';
        $param = 'photo';
      }
      elsif ($group =~ /video/) {
        $fn = 'sendVideo';
        $param = 'video';
      }
      else {
        $fn = 'sendDocument';
        $param = 'document';
      }

      my $content = $file->{content} || '';
      if($content =~ /FILE/){
        my ($filename) = $content =~ /FILE: (.*)/;
        open(my $fh, '<', $filename) or next;
        {
          local $/;
          $content = <$fh>;
        }
        close($fh);
      }
      my $filename = $file->{filename};

      $result = $self->{api}->$fn({
        RAW_BODY => 1,
        chat_id  => $attr->{TO_ADDRESS},
        $param    => [ undef, $filename, 'Content', $content, 'Content-Type', $group ],
      });
    }
  }
  return $result
}

1;