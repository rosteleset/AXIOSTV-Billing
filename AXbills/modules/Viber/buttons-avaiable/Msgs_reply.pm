package Msgs_reply;

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
=head2 reply()

=cut
#**********************************************************
sub reply {
  my $self = shift;
  my ($attr) = @_;

  return 0 unless ($attr->{argv}[2]);

  my $message = "$self->{bot}->{lang}->{WRITE_TEXT}\n";
  $message   .= "$self->{bot}->{lang}->{SEND_FILE}\n";
  $message   .= "$self->{bot}->{lang}->{CHANCEL}";
  
  my @keyboard = ();
  my $button = {
    text => "$self->{bot}->{lang}->{CHANCEL_TEXT}",
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

  my $info = $attr->{step_info};
  my $msg_hash = eval { decode_json($info->{args}) };

  use Msgs;
  
  my $Msgs = Msgs->new($self->{db}, $self->{admin}, $self->{conf});
  my @msgs_text = $attr->{text} =~ /(MSGS_ID=[0-9]+)(\s|\n)*(.+)/gs;
  
  if ($#msgs_text < 0) {
    return 0;
  }

  $msgs_text[0] =~ s/MSGS_ID=//g;

  $Msgs->message_info($msgs_text[0]);
  if ($Msgs->{errno}) {
    $self->{bot}->send_message({
      text => "$self->{bot}->{lang}->{ERROR_DELETE_MSGS}",
    });

    return 0;
  }

  if ($Msgs->{STATE} == 1 || $Msgs->{STATE} == 2) {
    $self->{bot}->send_message({
      text => "$self->{bot}->{lang}->{ERROR_CLOSE_MSGS}",
    });
    
    return 0;
  }

  $Msgs->message_reply_add({
    ID         => $msgs_text[0],
    UID        => $self->{bot}->{uid},
    REPLY_TEXT => $msgs_text[2],
  });

  my $reply_id = $Msgs->{REPLY_ID};

  $Msgs->message_change({
    ID         => $msgs_text[0],
    UID        => $self->{bot}->{uid},
    STATE      => 0,
    ADMIN_READ => '0000-00-00 00:00:00'
  });
  
  if (!$Msgs->{errno} && $attr->{photo}) {
    use Msgs::Misc::Attachments;

    my $Attachments = Msgs::Misc::Attachments->new($self->{db}, $self->{admin}, $self->{conf});
    my ($file_path, $file_size, $file_content) = $self->{bot}->get_file($attr->{photo});
    my ($file_name, $file_extension) = $file_path =~ m/.*\/(.*)\.(.*)/;
    
    next unless ($file_content && $file_size && $file_name && $file_extension);
    
    my $file_content_type = "application/octet-stream";
    
    if ( $file_extension eq 'png'
      || $file_extension eq 'jpg'
      || $file_extension eq 'gif'
      || $file_extension eq 'jpeg'
      || $file_extension eq 'tiff'
    ) {
      $file_content_type = "image/$file_extension";
    }
    elsif ( $file_extension eq "zip" ) {
      $file_content_type = "application/x-zip-compressed";
    }

    $Attachments->attachment_add({
      MSG_ID       => $msgs_text[0],
      REPLY_ID     => $reply_id,
      MESSAGE_TYPE => 1,
      UID          => $self->{bot}->{uid},
      FILENAME     => "$file_name.$file_extension",
      CONTENT_TYPE => $file_content_type,
      FILESIZE     => $file_size,
      CONTENT      => $file_content,
    });
  }

  $self->{bot_db}->del($self->{bot}->{uid});
  $self->{bot}->send_message({
    text => "$self->{bot}->{lang}->{SEND_MSGS}",
  });

  return 1;
}

1;