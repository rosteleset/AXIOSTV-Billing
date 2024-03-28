package Attach;
=head1 NAME

  Attach DB managment

=cut

use strict;
use warnings FATAL => 'all';

use strict;
use parent 'dbcore';
use Conf;

use Admins;
my Admins $admin;
my $CONF;

#my $SORT = 1;
#my $DESC = '';
#my $PG   = 1;
#my $PAGE_ROWS = 25;


#**********************************************************
=head2 new($db, $admin, $CONF)

  Arguments:
    $db
    $admin
    $CONF
      ATTACH2FILE - will save files to disk instead of DB
      
    $attr  - hash_ref
      ATTACH_PATH - directory inside $conf{TPL_DIR}/attach/ to work with

=cut
#**********************************************************
sub new {
  my $class = shift;
  my ($db, $admin_, $CONF_, $attr) = @_;
  
  $admin = $admin_;
  $CONF = $CONF_;
  $attr //= {};
  
  my $self = {
    db          => $db,
    admin       => $admin,
    conf        => $CONF,
    ATTACH2FILE => ($CONF->{TPL_DIR} || '/usr/axbills/AXbills/templates') . '/attach/',
  };
  
  if ( $CONF->{ATTACH2FILE} || $attr->{ATTACH_PATH} ) {
    my $dir_postfix = $attr->{ATTACH_PATH} || '';
    $self->{ATTACH2FILE} .= "$dir_postfix";
  }
  
  bless($self, $class);
  
  return $self;
}

#**********************************************************
=head2 save_file_to_disk($attr) - Add to disk

  Arguments:
    $attr
      FILENAME
      UID
      DIRECTORY_TO_SAVE - Directory to save
      ATTACH2FILE - Directory to save (for sql table store to disc migrate)
      DISK_FILENAME - Disk filename
      FIELD_NAME

  Returns:
    $self
    
  $self->{LAST_SAVE_PATH} will contain full path to saved file

=cut
#**********************************************************
sub save_file_to_disk {
  my $self = shift;
  my ($attr) = @_;
  
  $self->{LAST_SAVE_PATH} = '';
  
  my $directory_to_save = $self->{ATTACH2FILE};
  my $original_filename = $attr->{FILENAME};
  
  # Can be changed later
  my $filename_to_save = $attr->{DISK_FILENAME} || $original_filename;

  if ($attr->{UID}) {
    # Add additional directory level
    $directory_to_save .= '/' . $attr->{UID} . '/';
    if (!$attr->{DISK_FILENAME}) {
      #YYYYMMDD-HHMMSS-RAND-FieldName-OriginalName
      my $file_date = POSIX::strftime('%y%m%d%H%M%S', localtime(POSIX::mktime(localtime)));
      my $field_name = ($attr->{FIELD_NAME}) ? "_$attr->{FIELD_NAME}" : '';
      $filename_to_save = $file_date . $field_name . '_' . $attr->{FILENAME};
    }
  }
  elsif ($attr->{DIRECTORY_TO_SAVE}) {
    $directory_to_save .= $attr->{DIRECTORY_TO_SAVE};
  }
  
  # Now check if directory we want to write is not a file
  #  exists
  if ( -f $directory_to_save ) {
    $self->{errno} = 111;
    $self->{errstr} = "Trying to use file as a directory '$self->{ATTACH2FILE}'";
    return $self;
  }
  elsif ( ! -e $directory_to_save ) {
    # Recursive create directory
    
    # Core module from 5.001;
    require File::Path;
    File::Path->import('make_path');
    
    #https://perldoc.perl.org/File/Path.html#ERROR-HANDLING
    my $make_path_errors = [];
    File::Path::make_path($directory_to_save, { error => \$make_path_errors });
    if ( @{$make_path_errors} ) {
      # Build full error string
      my $error_string = '';
      for my $diag (@$make_path_errors) {
        my ($file, $message) = %$diag;
        if ($file eq '') {
          $error_string .= "General error: $message\n";
        }
        else {
          $error_string .= "$file: $message\n";
        }
      }
      $self->{errno} = 110;
      $self->{errstr} = "Can't create directory '$self->{ATTACH2FILE}' : $error_string";
      return $self;
    }
  }
#  use AXbills::Base qw/_bp/;
#  _bp("", $filename_to_save, { EXIT => 1 });
  
  
  # Finally can write to file
  my $full_file_path = $directory_to_save . '/' . $filename_to_save;
  if ( open(my $fh, '>', $full_file_path) ) {
    binmode $fh;
    print $fh $attr->{CONTENT};
    close($fh);
    $admin->action_add($attr->{UID}, "FILE:$full_file_path", { TYPE => 1 });
    $self->{LAST_SAVE_PATH} = $full_file_path;
  }
  else {
    $self->{errno} = 112;
    $self->{errstr} = "Can't create file '$full_file_path' $!";
  }
  
  return $self->{LAST_SAVE_PATH};
}

#**********************************************************
=head2 attachment_file_del($attr) - Add to disck

  Arguments:
    $attr
      FILENAME
      UID

  Returns:
    $self

=cut
#**********************************************************
sub attachment_file_del {
  my $self = shift;
  my ($attr) = @_;

  my $filename = $attr->{FILENAME};
  $self->{NEW_FILENAME} = $filename;

  if($attr->{UID}) {
    $filename = $self->{ATTACH2FILE} . '/' . $attr->{UID} .'/'. $self->{NEW_FILENAME};
  }
  else {
    $filename = $self->{ATTACH2FILE} .'/'. $attr->{FILENAME};
  }

  if(! -f $filename && ! $attr->{SKIP_ERROR}) {
    $self->{errno} = 113;
    $self->{errstr} = "File not exist '$filename'";
  }
  elsif (unlink $filename) {
    $self->{FILENAME}=$filename;
    $admin->action_add($attr->{UID}, "FILE:$filename", { TYPE => 10 });
  }
  else {
    $self->{errno} = 114;
    $self->{errstr} = "Can't remove file '$self->{NEW_FILENAME}' $!";
  }

  return $self;
}


#**********************************************************
=head2 attachment_add($attr) - Add attachment

  Arguments:
    $attr
      TABLE      - Table name
      EXTRA_DATA - hash_ref additional table columns => values
      FILENAME
      CONTENT_TYPE
      FILESIZE
      CONTENT

  Returns:
    $self

=cut
#**********************************************************
sub attachment_add{
  my $self = shift;
  my ($attr) = @_;

  if($attr->{FILENAME}) {
    $attr->{FILENAME} =~ s/ /_/g;
    $attr->{FILENAME} =~ s/\%20/_/g;
  }

  if($self->{conf}{ATTACH2FILE}) {
    
    my $saved_filename = $self->save_file_to_disk($attr);
    
    if($self->{errno}) {
      return $self;
    }
    else {
      $attr->{CONTENT} = "FILE: $saved_filename";
    }
  }
  
  # Allow to add extra columns
  my $extra_bind_placeholders = '';
  my $extra_col_names = '';
  my @extra_bind_values = '';
  if ( $attr->{EXTRA_DATA} && ref $attr->{EXTRA_DATA} eq 'HASH'){
    $extra_bind_placeholders = ', ?' x (scalar keys %{$attr->{EXTRA_DATA}});
    foreach my $key (sort keys %{$attr->{EXTRA_DATA}}){
      $extra_col_names .= ", $key";
      push (@extra_bind_values, $attr->{EXTRA_DATA}{$key});
    }
  }

  $self->query( "INSERT INTO `$attr->{TABLE}`
        (filename, content_type, content_size, content, create_time $extra_col_names)
        VALUES (?, ?, ?, ?, NOW() $extra_bind_placeholders)",
    'do', { Bind => [
        $attr->{FILENAME},
        $attr->{CONTENT_TYPE},
        $attr->{FILESIZE},
        $attr->{CONTENT},
        @extra_bind_values
      ]
    }
  );

  return ($attr->{RETURN_ID}) ? $self->{INSERT_ID} : $self ;
}

#**********************************************************
=head2 attachment_del($attr) - Add attachment

  Arguments:
    $attr
      TABLE    - Table name
      ID       - ID

  Returns:
    $self

=cut
#**********************************************************
sub attachment_del {
  my $self = shift;
  my ($attr) = @_;

  $self->attachment_info($attr);
  $self->query_del($attr->{TABLE}, $attr);

  if($self->{conf}{ATTACH2FILE} && $self->{FILENAME}) {
    if ( $self->{CONTENT} =~ /FILE(?:NAME)?: .+\/\/?([a-zA-Z0-9_\-.]+)/ ) {
      $attr->{FILENAME} = $1;
      $self->attachment_file_del($attr);
    }
  }
  elsif($attr->{FULL_DELETE} && $self->{conf}{ATTACH2FILE}) {
    if($attr->{UID} && -d "$self->{ATTACH2FILE}/$attr->{UID}") {
      `rm -R $self->{ATTACH2FILE}/$attr->{UID}`;
    }
  }

  return $self;
}

#**********************************************************
=head2 attachment_info($attr)

=cut
#**********************************************************
sub attachment_info {
  my $self = shift;
  my ($attr) = @_;

  my $content = (!$attr->{INFO_ONLY}) ? ',content' : '';

  if(! $attr->{TABLE}) {
    return $self
  }

  my $table   = $attr->{TABLE};

  $self->query("SELECT id AS attachment_id,
    filename,
    content_type,
    content_size AS filesize
    $content
   FROM `$table`
   WHERE id = ? ",
    undef,
    { INFO => 1,
      Bind => [
        $attr->{ID}
      ]
    }
  );

  return $self;
}


1;
