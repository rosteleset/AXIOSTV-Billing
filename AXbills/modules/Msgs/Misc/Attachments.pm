package Msgs::Misc::Attachments;
use strict;
use warnings FATAL => 'all';

=head1 NAME

  Msgs::Attachments - 

=head2 SYNOPSIS

  This package is a transparent layer to work with attachments in DB and on disk

=cut

use Attach;
use Msgs;

my Attach $Attach;
my Msgs $Msgs;

use AXbills::Base qw/_bp/;

my %ATTACH_MSGS_PARAMS = (
  ATTACH_PATH => 'msgs'
);

#**********************************************************
=head2 new($db,$admin,\%conf) - constructor for Msgs::Misc::Attachments

=cut 
#**********************************************************
sub new {
  my $class = shift;
  
  my ($db, $admin, $CONF) = @_;
  
  my $self = {
    db           => $db,
    admin        => $admin,
    conf         => $CONF,
    save_to_disk => $CONF->{MSGS_ATTACH2FILE},
    files_dir    => 'msgs'
  };
  
  bless($self, $class);
  
  # Allow to change directory
  if ( $CONF->{MSGS_ATTACH2FILE} && $CONF->{MSGS_ATTACH2FILE} ne 1 ) {
    $self->{files_dir} = $CONF->{MSGS_ATTACH2FILE};
    $ATTACH_MSGS_PARAMS{ATTACH_PATH} = $self->{files_dir};
  }
  
  $Attach //= Attach->new(@{$self}{qw/db admin conf/}, \%ATTACH_MSGS_PARAMS);
  $Msgs //= Msgs->new(@{$self}{qw/db admin conf/});
  
  return $self;
}


#**********************************************************
=head2 save_attachment($attr) - saves attachment

  Arguments:
    $attr -
    
  Returns:
    
    
=cut
#**********************************************************
sub attachment_add {
  my ($self, $attr) = @_;

  if (length($attr->{CONTENT}) != $attr->{FILESIZE}) {
    $self->{errno} = 50010;
    $self->{errstr} = 'Not valid filesize. Filesize not equal to content length';
    return 0;
  }

  if ($self->{save_to_disk}) {

    # If have one attachment linked to a lot messages, will save it as one file
    my @msgs_ids = (ref $attr->{MSG_ID} eq 'ARRAY') ? @{$attr->{MSG_ID}} : ($attr->{MSG_ID});

    # If have less than 5 ids, will concatenate them all, else just show first and last IDS (hope they will be consistent)
    my $main_message_name = $attr->{DELIVERY_ID} ? ''
      : ($#msgs_ids > 5) ? "$msgs_ids[0]-$msgs_ids[$#msgs_ids]" : join('_', @msgs_ids);

    my $file_path = $self->_save_to_disk($main_message_name, $attr->{REPLY_ID}, $attr->{FILENAME}, $attr);
    return 0 if (!$file_path || $self->{errno});

    $attr->{CONTENT} = "FILE: $file_path";
  }
  
  $Msgs->attachment_add($attr);
  
  #  $Attach->attachment_add({
  #    TABLE        => 'msgs_attachment',
  #    FILENAME     => $attr->{FILENAME},
  #    CONTENT      => $attr->{CONTENT},
  #    CONTENT_TYPE => $attr->{CONTENT},
  #    FILESIZE     => $attr->{FILESIZE},
  #
  #  });
  
  return 0 if ( $Msgs->{errno} );
  
  return $Msgs->{INSERT_ID};
}

#**********************************************************
=head2 attachment_info($attachment_id, $attr) -

  Arguments:
     $attachment_id
     $attr - hash_ref
       WITHOUT_CONTENT - return only metainfo
    
  Returns:
    hashref
    
=cut
#**********************************************************
sub attachment_info {
  my ($self, $attachment_id, $attr) = @_;
  
  my $msgs_object_for_info = Msgs->new(@{$self}{qw/db admin conf/});
  $msgs_object_for_info->attachment_info({ ID => $attachment_id });
  
  return 0 if ( $msgs_object_for_info->{errno} );
  
  if ( $self->{save_to_disk} && !$attr->{WITHOUT_CONTENT} ) {
    my ($directory, $filename) = $self->_read_file_params($msgs_object_for_info->{CONTENT});
    
    #    $self->{LAST_READ_FILE} = "$directory/$filename";
    if ( $directory && $filename && -f "$directory/$filename" ) {
      $msgs_object_for_info->{CONTENT} = $self->_read_file_from_disk($directory, $filename);
      if ( $self->{errno} ) {
        return 0;
      }
    }
  }
  
  return $msgs_object_for_info;
}

#**********************************************************
=head2 delete_attachment($attachment_id) -

  Arguments:
    $attachment_id -
    
  Returns:
    boolean
    
=cut
#**********************************************************
sub delete_attachment {
  my ($self, $attachment_id) = @_;

  if ($self->{save_to_disk}) {
    # Should first get file path to remove it too
    my $attachment_info = $Msgs->attachment_info({ ID => $attachment_id });

    my $path = $self->_read_file_params($attachment_info->{CONTENT});
    unlink $path if ($path && -f $path);
  }
  
  return $Msgs->attachment_del($attachment_id);
}

#**********************************************************
=head2 _save_to_disk($msg_id, $reply_id, $filename, $attr) - writes file to disk

  Arguments:
    $msg_id,
    $reply_id,
    $filename,
    $attr
    
  Returns:
    full file path
    
=cut
#**********************************************************
sub _save_to_disk {
  my ($self, $msg_id, $reply_id, $filename, $attr) = @_;

  # filename should contain only alphanumeric_symbols
  $filename //= '';
  $filename =~ s/[^a-zA-Z0-9._-]/_/g;
  
  # Should change filename. map will replace undefined values with 0
  my $disk_filename = $attr->{DELIVERY_ID} ? $filename : join('_', map {$_ // '0'} ($msg_id, $reply_id, $filename));

  my $final_path = $Attach->save_file_to_disk({
    %{$attr},
    FILENAME          => $filename,
    DISK_FILENAME     => $disk_filename,
    DIRECTORY_TO_SAVE => $attr->{DELIVERY_ID} ? "/delivery/$attr->{DELIVERY_ID}/" : ''
  });

  if ($Attach->{errno}) {
    $self->{errno} = $Attach->{errno};
    $self->{errstr} = $Attach->{errstr};
    return 0;
  }
  
  return $final_path;
}

#**********************************************************
=head2 _read_file_from_disk($filename) -

  Arguments:
     -
    
  Returns:
  
  
=cut
#**********************************************************
sub _read_file_from_disk {
  my ($self, $directory, $filename) = @_;

  return 0 if ($directory =~ /\.\.\//);
  
  if ( open(my $fh, '<', $directory . $filename) ) {
    my $content = '';
    while ( my $line = <$fh> ) {
      $content .= $line;
    }
    return $content;
  }
  else {
    $self->{errno} = 111;
    $self->{errstr} = "Can't read file : $@";
  }
  
  return 0;
}


#**********************************************************
=head2 _read_file_params($content_field_value) -

  Arguments:
    $content_field -
    
  Returns:
  
  
=cut
#**********************************************************
sub _read_file_params {
  my ($self, $content_field_value) = @_;

  if ($content_field_value && $content_field_value =~ /FILE: (.+\/)+\/?([a-zA-Z0-9_\-.]+)/) {
    my $directory = $1;
    my $filename = $2;

    return wantarray ? ($directory, $filename) : "$directory/$filename";
  };
  
  return 0;
}

#**********************************************************
=head2 attachment_copy($old_reply_id, $new_message_id, $uid) -

=cut
#**********************************************************
sub attachment_copy {
  my ($self, $old_id, $new_id, $uid) = @_;

  my $at_list = $Msgs->attachments_list({
    REPLY_ID         => $old_id,
    SHOW_ALL_COLUMNS => 1,
    COLS_NAME        => 1,
    COLS_UPPER       => 1,
  });

  foreach my $line (@$at_list) {
    if ($line->{CONTENT} =~ /^FILE/) {
      my ($directory, $filename) = $self->_read_file_params($line->{CONTENT});
      if ($directory && $filename && -f "$directory/$filename") {
        $line->{CONTENT} = $self->_read_file_from_disk($directory, $filename);
        next if $self->{errno};
      }
    }

    $self->attachment_add({
      MSG_ID       => $new_id,
      MESSAGE_TYPE => 0,
      CONTENT      => $line->{CONTENT},
      FILESIZE     => $line->{CONTENT_SIZE},
      FILENAME     => $line->{FILENAME},
      CONTENT_TYPE => $line->{CONTENT_TYPE},
      UID          => $uid,
    }); 
  }

  return 1;
}

1;