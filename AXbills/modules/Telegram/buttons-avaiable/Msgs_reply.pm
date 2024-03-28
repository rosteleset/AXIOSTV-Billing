package Msgs_reply;

use strict;
use warnings FATAL => 'all';
use Encode qw/encode_utf8/;
use JSON;
use AXbills::Sender::Core;

require 'buttons-enabled/Send_message.pm';

#**********************************************************
=head2 new($db, $admin, $conf, $bot_api, $bot_db)

=cut
#**********************************************************
sub new {
  my $class = shift;
  my ($db, $admin, $conf, $bot, $bot_db) = @_;
  
  my $self = {
    db     => $db,
    admin  => $admin,
    conf   => $conf,
    bot    => $bot,
    bot_db => $bot_db
  };
  
  bless($self, $class);
  
  return $self;
}

#**********************************************************
=head2 reply()

=cut
#**********************************************************
sub reply {
  my $self = shift;
  my ($attr) = @_;

  return 0 unless ($attr->{argv}[2]);

  my $message = "$self->{bot}->{lang}->{WRITE_TEXT}\n";
  $message   .= "$self->{bot}->{lang}->{SEND_FILE}\n";
  $message   .= "$self->{bot}->{lang}->{CANCEL}";

  my @keyboard = ();
  my $button = {
    text => "$self->{bot}->{lang}->{CANCEL_TEXT}",
  };
  push (@keyboard, [$button]);

  $self->{bot}->send_message({
    text         => $message,
    reply_markup => {
      keyboard        => \@keyboard,
      resize_keyboard => "true",
    },
    parse_mode   => 'HTML'
  });

  $self->{bot_db}->add({
    UID    => $self->{bot}->{uid},
    BUTTON => "Msgs_reply",
    FN     => "send_reply",
    ARGS   => '{"message":{"text":"","id":"' . $attr->{argv}[2] .'"}}',
  });

  return 1;
}

#**********************************************************
=head2 send_reply()

=cut
#**********************************************************
sub send_reply {
  my $self = shift;
  my ($attr) = @_;

  my $Send_message = Send_message->new($self->{db}, $self->{admin},
    $self->{conf}, $self->{bot}, $self->{bot_db});

  if ($attr->{message}->{text}) {
    my $text = encode_utf8($attr->{message}->{text});
    if ($text eq "$self->{bot}->{lang}->{CANCEL_TEXT}") {
      $Send_message->cancel_msg();
      return 0;
    }
    elsif ($text eq "$self->{bot}->{lang}->{SEND}") {
      $self->send_msg($attr);
      return 0;
    }
    $Send_message->add_text_to_msg($attr);
  }
  elsif ($attr->{message}->{photo}) {
    my $photo = pop @{$attr->{message}->{photo}};
    $Send_message->add_file_to_msg($attr, $photo->{file_id});
  }
  elsif ($attr->{message}->{document}) {
    $Send_message->add_file_to_msg($attr, $attr->{message}->{document}->{file_id});
  }
  else {
    return 1;
  }

  $self->send_msgs_main_menu($attr->{step_info});
  return 1;
}


#**********************************************************
=head2 send_msg()

=cut
#**********************************************************
sub send_msg {
  my $self = shift;
  my ($attr) = @_;

  my $info = $attr->{step_info};
  my $msg_hash = decode_json($info->{args});

  my $text = $msg_hash->{message}->{text} || "";


  if(!$text && !$msg_hash->{message}->{files}){
    $self->{bot}->send_message({
      text => "$self->{bot}->{lang}->{NOT_SEND_MSGS}",
    });
    return 0;
  }

  my $Msgs = Msgs->new($self->{db}, $self->{admin}, $self->{conf});


  $Msgs->message_reply_add({
    ID         => $msg_hash->{message}->{id},
    UID        => $self->{bot}->{uid},
    REPLY_TEXT => $text,
  });

  my $reply_id = $Msgs->{REPLY_ID};

  $Msgs->message_change({
    ID         => $msg_hash->{message}->{id},
    STATE      => 0,
  });

  if (!$Msgs->{errno} && $msg_hash->{message}->{files}) {
    use Msgs::Misc::Attachments;

    for my $file (@{$msg_hash->{message}->{files}}) {

      my $Attachments = Msgs::Misc::Attachments->new($self->{db}, $self->{admin}, $self->{conf});
      my ($file_path, $file_size, $file_content) = $self->{bot}->get_file($file);
      my ($file_name, $file_extension) = $file_path =~ m/.*\/(.*)\.(.*)/;

      next unless ($file_content && $file_size && $file_name && $file_extension);

      my $file_content_type = main::file_content_type($file_extension);

      delete($Attachments->{save_to_disk});

      $Attachments->attachment_add({
        MSG_ID       => $Msgs->{MSG_ID},
        REPLY_ID     => $reply_id,
        MESSAGE_TYPE => 1,
        UID          => $self->{bot}->{uid},
        FILENAME     => "$file_name.$file_extension",
        CONTENT_TYPE => $file_content_type,
        FILESIZE     => $file_size,
        CONTENT      => $file_content,
      });
    }
  }

  use AXbills::HTML;
  use Msgs::Notify;

  my $html = AXbills::HTML->new({
    CONF     => $self->{conf},
    NO_PRINT => 0,
    PATH     => $self->{conf}->{WEB_IMG_SCRIPT_PATH} || '../',
    CHARSET  => $self->{conf}->{default_charset},
  });


  my $Notify = Msgs::Notify->new($self->{db}, $self->{admin}, $self->{conf}, {LANG => $self->{bot}->{lang}, HTML => $html});

  $Notify->notify_admins({
    MSG_ID        => $msg_hash->{message}->{id},
    MESSAGE       => $text,
  });

  $self->{bot_db}->del($self->{bot}->{uid});
  $self->{bot}->send_message({
    text => "$self->{bot}->{lang}->{SEND_MSGS}",
  });

  return 1;
}

#**********************************************************
=head2 send_msgs_main_menu

=cut
#**********************************************************
sub send_msgs_main_menu {
  my $self = shift;
  my $info = shift;

  my @keyboard = ();
  my $button2 = {
    text => "$self->{bot}->{lang}->{SEND}",
  };
  my $button3 = {
    text => "$self->{bot}->{lang}->{CANCEL_TEXT}",
  };

  my $msg_hash = decode_json($info->{args});

  push @keyboard, [$button2] if($msg_hash->{message}->{text} || $msg_hash->{message}->{files});
  push @keyboard, [$button3];

  my $message   .= "$self->{bot}->{lang}->{SEND_OR_CANCEL}\n";

  $self->{bot}->send_message({
    text         => $message,
    reply_markup => {
      keyboard        => \@keyboard,
      resize_keyboard => "true",
    },
    parse_mode   => 'HTML'
  });

  return 1;
}



1;