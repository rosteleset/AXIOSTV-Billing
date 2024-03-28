package Send_message;

use strict;
use warnings FATAL => 'all';
use Encode qw/encode_utf8/;
use JSON;

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
=head2 btn_name()

=cut
#**********************************************************
sub btn_name {
  my $self = shift;

  return $self->{bot}->{lang}->{CREATE_MSGS};
}

#**********************************************************
=head2 click()

=cut
#**********************************************************
sub click {
  my $self = shift;
  my ($attr) = @_;

  my $message = "$self->{bot}->{lang}->{WRITE_TEXT}\\n";
  $message   .= "$self->{bot}->{lang}->{CHANCEL}\\n\\n";

  my @keyboard = $self->get_keyboard();

  $self->{bot}->send_message({
    text         => $message,
    keyboard => {
      Type          => 'keyboard',
      DefaultHeight => "true",
      Buttons => \@keyboard
    },
    type   => 'text'
  });


  $self->{bot_db}->add({
    UID    => $self->{bot}->{uid},
    BUTTON => "Send_message",
    FN     => "fn:Send_message&add_to_msg",
    ARGS   => '{"message":{"text":""}}',
  }) if(!$attr->{NO_MSG});

  return "NO_MENU";
}

#**********************************************************
=head2 simple_msgs()

=cut
#**********************************************************
sub simple_msgs {
  my $self = shift;
  my ($attr) = @_;

  my $subject = "Viber Bot";
  my $chapter = 1;

  use Msgs;
  my $Msgs = Msgs->new($self->{db}, $self->{admin}, $self->{conf});

  $Msgs->message_add({
    USER_SEND => 1,
    UID       => $attr->{uid},
    MESSAGE   => $attr->{text},
    SUBJECT   => $subject,
    CHAPTER   => $chapter,
    PRIORITY  => 2,
  });


  if (!$Msgs->{errno} && $attr->{photo}) {
    use Msgs::Misc::Attachments;

    my $Attachments = Msgs::Misc::Attachments->new($self->{db}, $self->{admin}, $self->{conf});
    my ($file_path, $file_size, $file_content) = $self->{bot}->get_file($attr->{photo});
    my ($file_name, $file_extension) = $file_path =~ m/.*\/(.*)\.(.*)/;

    next unless ($file_content && $file_size && $file_name && $file_extension);

    my $file_content_type = main::file_content_type($file_extension);

    delete($Attachments->{save_to_disk});

    $Attachments->attachment_add({
      MSG_ID       => $Msgs->{MSG_ID},
      UID          => $attr->{uid},
      FILENAME     => "$file_name.$file_extension",
      CONTENT_TYPE => $file_content_type,
      FILESIZE     => $file_size,
      CONTENT      => $file_content,
    });
  }

  $self->{bot}->send_message({
    text => "$self->{bot}->{lang}->{SEND_MSGS}",
    type => "text"
  });

  return 1;
}

#**********************************************************
=head2 add_to_msg()

=cut
#**********************************************************
sub add_to_msg {
  my $self = shift;
  my ($attr) = @_;

  if ($attr->{message}->{type} eq "text") {
    $self->add_text_to_msg($attr);
  }
  elsif ($attr->{message}->{type} eq "picture") {
    my $file_id = $attr->{message}->{media}.'|'.$attr->{message}->{file_name}.'|'.$attr->{message}->{size};
    $self->add_file_to_msg($attr, $file_id);
  }
  elsif ($attr->{message}->{type} eq "file") {
    my $file_id = $attr->{message}->{media}.'|'.$attr->{message}->{file_name}.'|'.$attr->{message}->{size};
    $self->add_file_to_msg($attr, $file_id);
  }
  else {
    return 1;
  }

  $self->send_msgs_main_menu();
  return 1;
}

#**********************************************************
=head2 add_text_to_msg()

=cut
#**********************************************************
sub add_text_to_msg {
  my $self = shift;
  my ($attr) = @_;
  my $info = $attr->{step_info};
  my $text = $attr->{message}->{text};
  my $msg_hash = decode_json($info->{args});
  $msg_hash->{message}->{text} .= "$text\n";
  $info->{ARGS} = encode_json($msg_hash);
  $self->{bot_db}->change($info);

  my @keyboard = $self->get_keyboard();

  $self->{bot}->send_message({
    text => "$self->{bot}->{lang}->{ADD_MSGS_TEXT}",
    type => "text",
    keyboard => {
        Type          => 'keyboard',
        DefaultHeight => "true",
        Buttons       => \@keyboard
    }
  });
  return 1;
}

#**********************************************************
=head2 add_title_to_msg()

=cut
#**********************************************************
sub add_title_to_msg {
  my $self = shift;
  my ($attr) = @_;
  my $info = $attr->{step_info};

  if ($attr->{message}->{type} eq "text") {
      my $title = $attr->{message}->{text};
      my $msg_hash = decode_json($info->{args});
      $msg_hash->{message}->{title} = $title;
      $info->{ARGS} = encode_json($msg_hash);
      $self->{bot}->send_message({
        text => "$self->{bot}->{lang}->{SUBJECT_EDIT}",
        type => 'text'
      });
  }
  else {
    return 1;
  }

  $info->{FN} = "fn:Send_message&add_to_msg";
  $self->{bot_db}->change($info);

  $self->send_msgs_main_menu();
  return 1;
}

#**********************************************************
=head2 add_title()

=cut
#**********************************************************
sub add_title {
  my $self = shift;
  my ($attr) = @_;
  my $info = $attr->{step_info};

  my $message = "$self->{bot}->{lang}->{SUBJECT_MSGS}\\n";
  $message   .= "$self->{bot}->{lang}->{CLICK_BACK}\\n";
  $message   .= "$self->{bot}->{lang}->{CHANCEL}\\n";

  my @keyboard = ();
  my $back_button = {
    Text => "$self->{bot}->{lang}->{BACK}",
    ActionType => 'reply',
    ActionBody => 'fn:Send_message&click',
    TextSize   => 'regular'
  };

  my $cahncle_button = {
    ActionType => 'reply',
    ActionBody => 'fn:Send_message&cancel_msg',
    Text       => $self->{bot}->{lang}->{CHANCEL_TEXT},
    BgColor    => "#FF0000",
    TextSize   => 'regular'
  };

  push (@keyboard, $back_button, $cahncle_button);

  $self->{bot}->send_message({
    text         => $message,
    keyboard => {
      Type          => 'keyboard',
        DefaultHeight => "true",
        Buttons       => \@keyboard
    },
    type   => 'text'
  });

  $info->{FN} = 'fn:Send_message&add_title_to_msg';
  $self->{bot_db}->change($info);

  return "NO_MENU";
}

#**********************************************************
=head2 add_file_to_msg()

=cut
#**********************************************************
sub add_file_to_msg {
  my $self = shift;
  my ($attr, $file_id) = @_;
  my $info = $attr->{step_info};
  my $msg_hash = decode_json($info->{args});
  push(@{$msg_hash->{message}->{files}}, $file_id);

  $info->{ARGS} = encode_json($msg_hash);
  $self->{bot_db}->change($info);

  $self->{bot}->send_message({
    text => "$self->{bot}->{lang}->{ADD_FILE}",
    type => "text"
  });
  return 1;
}

#**********************************************************
=head2 cancel_msg()

=cut
#**********************************************************
sub cancel_msg {
  my $self = shift;
  $self->{bot_db}->del($self->{bot}->{uid});
  $self->{bot}->send_message({
    text => "$self->{bot}->{lang}->{SEND_CHANCEL}",
    type => 'text'
  });

  main::main_menu({NO_MSG=>1});
  return "NO_MENU";
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
      type => "text"
    });
    main::main_menu({NO_MSG=>1});
    return 1;
  }

  my $subject = $msg_hash->{message}->{title} || "Telegram Bot";

  my $chapter = 1;

  use Msgs;
  my $Msgs = Msgs->new($self->{db}, $self->{admin}, $self->{conf});

  $Msgs->message_add({
    USER_SEND => 1,
    UID       => $self->{bot}->{uid},
    MESSAGE   => $text,
    SUBJECT   => $subject,
    CHAPTER   => $chapter,
    PRIORITY  => 2,
    SEND_TYPE => 5
  });


  if (!$Msgs->{errno} && $msg_hash->{message}->{files}) {
    use Msgs::Misc::Attachments;

    for my $file (@{$msg_hash->{message}->{files}}) {

      my $Attachments = Msgs::Misc::Attachments->new($self->{db}, $self->{admin}, $self->{conf});
      my ($file_path, $file_size, $file_content) = $self->{bot}->get_file($file);
      my ($file_name, $file_extension) = $file_path =~ m/(.*)\.(.*)/;

      next unless ($file_content && $file_size && $file_name && $file_extension);

      my $file_content_type = main::file_content_type($file_extension);

      delete($Attachments->{save_to_disk});

      $Attachments->attachment_add({
        MSG_ID       => $Msgs->{MSG_ID},
        UID          => $self->{bot}->{uid},
        FILENAME     => "$file_name.$file_extension",
        CONTENT_TYPE => $file_content_type,
        FILESIZE     => $file_size,
        CONTENT      => $file_content,
      });
    }
  }

  $self->{bot_db}->del($self->{bot}->{uid});

  $self->{bot}->send_message({
    text => "$self->{bot}->{lang}->{SEND_MSGS}",
    type => "text"
  });

  main::main_menu({NO_MSG=>1});
  return "NO_MENU";
}

#**********************************************************
=head2 send_msgs_main_menu()

=cut
#**********************************************************
sub send_msgs_main_menu {
  my $self = shift;

  my @keyboard = $self->get_keyboard();

  my $message   .= "$self->{bot}->{lang}->{SEND_OR_CHANCEL}\\n";

  $self->{bot}->send_message({
    text         => $message,
    keyboard => {
      Type          => 'keyboard',
      DefaultHeight => "true",
      Buttons       => \@keyboard
    },
    type   => 'text'
  });

  return 1;
}


#**********************************************************
=head2 get_keyboard()

=cut
#**********************************************************
sub get_keyboard {
  my $self = shift;

  my @keyboard = ();
  my $send_button = {
    Text => "$self->{bot}->{lang}->{SEND}",
    ActionType => 'reply',
    ActionBody => "fn:Send_message&send_msg",
    TextSize   => 'regular'
  };

  my $subject_button = {
    Text => "$self->{bot}->{lang}->{SUBJECT_EDIT}",
    ActionType => 'reply',
    ActionBody => "fn:Send_message&add_title",
    TextSize   => 'regular'
  };
  my $cahncle_button = {
    ActionType => 'reply',
    ActionBody => 'fn:Send_message&cancel_msg',
    Text       => $self->{bot}->{lang}->{CHANCEL_TEXT},
    BgColor    => "#FF0000",
    TextSize   => 'regular'
  };

  push (@keyboard, $send_button, $subject_button, $cahncle_button);

  return @keyboard;
}
1;