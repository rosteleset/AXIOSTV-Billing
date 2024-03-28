package Info;
use warnings FATAL => 'all';
use strict;

use POSIX qw( strftime );

=head1 NAME

Info - module for extra information about DB Objects

Supports
 * Comments     (1.1)
 * Images       (1.1)
 * Geolocation  (1.2)
 * Documents    (1.3)

=head1 VERSION

  VERSION = 1.5

=cut

our $VERSION = 1.5;
#**********************************************************
=head1 SYNOPSIS
  By simply calling info_show_comments('table_name', object_id),
  you will get a comments block with dynamic available adding and removing comments

=head1 EXAMPLES

  Look in modules/Info/webinterface

=cut
#**********************************************************

use parent 'dbcore';
use Attach;
my Attach $Attach;

# Singleton reference;
my dbcore $instance;
my $MODULE = 'Info';
my ($db, $admin, $CONF);

use constant {
  COMMENT_TABLE  => {
    TYPE    => 'comment',
    NAME    => 'info_comments',
    ALIAS   => 'ic',
    COLUMNS => [ 'ic.id', 'ic.text', 'i.date', 'a.name' ]
  },
  IMAGE_TABLE    => {
    TYPE    => 'media',
    NAME    => 'info_media',
    ALIAS   => 'im',
    COLUMNS => [ 'im.id', 'im.filename', 'im.real_name',
      'im.content_type', 'im.file', 'im.content_size', 'im.file IS NOT NULL AS in_db' ]
  },
  LOCATION_TABLE => {
    TYPE    => 'location',
    NAME    => 'info_locations',
    ALIAS   => 'il',
    COLUMNS => [ 'il.id', 'i.date', 'il.timestamp', 'il.coordx', 'il.coordy', 'il.comment', 'a.name AS admin' ]
  },
  DOCUMENT_TABLE => {
    TYPE    => 'document',
    NAME    => 'info_documents',
    ALIAS   => 'id',
    COLUMNS => [ 'id.id', 'id.filename',
      'id.real_name', 'id.content_type', 'id.file', 'id.content_size', 'id.file IS NOT NULL AS in_db',
      'a.name AS admin', 'i.date' ]
  }
};

#**********************************************************
=head2 new

Instantiation of singleton db object

=cut
#**********************************************************
sub new {
  unless (defined $instance) {
    my $class = shift;
    ($db, $admin, $CONF) = @_;
    
    my $self = {
      db    => $db,
      admin => $admin,
      conf  => $CONF,
    };
    
    bless($self, $class);
    $admin->{MODULE}=$MODULE;

    $instance = $self;
  }

  $Attach //= Attach->new(@{$instance}{qw/db admin conf/}, { ATTACH_PATH => 'info' });

  return $instance;
}

#**********************************************************
=head2 get_comments ($type, $id)

 Main function to get comments for $type, $id
   $type - The table name for object you want get comments for
   $id   - id of object you want get comments for
   $attr - hash reference of extra arguments

 if $attr contains {COLS_NAME}
  returns array of hashes representing comments for an object
 else
  returns array of arrays

=head2 EXAMPLES
  Get comments for Administrator with aid = 2
    my $comments = $Info->get_comments('admins', 2, { COLS_NAME => 1 });

  Will return:
    [
      {
        'id'         => 2,                        # Id of comment in `comments` table
        'text'       => 'This guy is awesome',    # Text of comment
        'date'       => '01.01.2016 01:02:59',    # DateTime when comment was leaved
        'name'       => 'John'                    # Name of administrator who leaved comment
      }
    ]
=cut
#**********************************************************
sub get_comments {
  my $self = shift;
  my ($obj_type, $id, $attr) = @_;

  if (!(defined $obj_type && defined $id)) {
    $self->{errno} = 2;
    $self->{errstr} = 'Parameters error';
    return 0;
  }
  return _get_info_list($obj_type, $id, COMMENT_TABLE, $attr);
}

#**********************************************************

=head2 add_comment

 Main function to add comment for $type, $id
   $attr - hash reference of extra arguments
     OBJ_TYPE - The table name for object you want add comments for
     OBJ_ID   - id of object you want add comments for
     TEXT     - text of comment

 Comment will always be added with current system datetime, and aid of current administrator

=cut
#**********************************************************
sub add_comment {
  my $self = shift;
  my ($attr) = @_;

  my $obj_type = $attr->{OBJ_TYPE};
  my $id = $attr->{OBJ_ID};

  $admin->action_add($attr->{OBJ_ID}, $attr->{TEXT}, { TYPE => 1 });

  return _add_info($obj_type, $id, COMMENT_TABLE, $attr);
}

#**********************************************************
=head2 del_comment

 Main function to delete comment by $id
   $attr - hash reference of extra arguments
      -> COMMENT_ID   - id of comment you want to delete

 Removes comment row with specified comment_id from `comments` and `info_info` tables

=cut
#**********************************************************
sub del_comment {
  my $self = shift;
  my ($attr) = @_;

  $admin->action_add($attr->{UID}, $attr->{COMMENTS}, { TYPE => 10 });

  return _del_info(COMMENT_TABLE, $attr);
}


#**********************************************************
=head2 get_comments ($type, $id)

 Main function to get comments for $type, $id
   $type - The table name for object you want get comments for
   $id   - id of object you want get comments for
   $attr - hash reference of extra arguments

 if $attr contains {COLS_NAME}
  returns array of hashes representing comments for an object
 else
  returns array of arrays

=head2 EXAMPLES
  Get comments for Administrator with aid = 2
    my $comments = $Info->get_comments('admins', 2, { COLS_NAME => 1 });

  Will return:
    [
      {
        'id'         => 2,                        # Id of comment in `comments` table
        'text'       => 'This guy is awesome',    # Text of comment
        'date'       => '01.01.2016 01:02:59',    # DateTime when comment was leaved
        'name'       => 'John'                    # Name of administrator who leaved comment
      }
    ]
=cut
#**********************************************************
sub get_images {
  my $self = shift;
  my ($obj_type, $id, $attr) = @_;

  if (!(defined $obj_type && defined $id)) {
    $self->{errno} = 2;
    $self->{errstr} = 'Parameters not defined: OBJ_TYPE || OBJ_ID';
    return 0;
  }
  return _get_info_list($obj_type, $id, IMAGE_TABLE, $attr);
}

#**********************************************************
=head2 get_image_info($image_id, $attr)

=cut
#**********************************************************
sub get_image_info {
  my $self = shift;
  my ($image_id, $attr) = @_;

  return _get_info_info (IMAGE_TABLE, $image_id, $attr);
}

#**********************************************************
=head2 add_comment

 Main function to add comment for $type, $id
   $attr - hash reference of extra arguments
      -> TYPE - The table name for object you want add comments for
      -> ID   - id of object you want add comments for
      -> TEXT - text of comment

 Comment will always be added with current system datetime, and aid of current administrator

=cut
#**********************************************************
sub add_image {
  my $self = shift;
  my ($attr) = @_;

  return _add_info($attr->{OBJ_TYPE}, $attr->{OBJ_ID}, IMAGE_TABLE,
    $attr
  );
}

#**********************************************************
=head2 del_image

 Main function to delete image by $id
   $attr - hash reference of extra arguments
      IMAGE_ID   - id of image you want to delete

 Removes image row with specified image_id from `info_media` and `info_info` tables

=cut
#**********************************************************
sub del_image {
  my $self = shift;
  my ($attr) = @_;

  _del_info(IMAGE_TABLE, $attr);

  return 1;
}

#**********************************************************
=head2 get_locations ($type, $id)

 Main function to get locations for $type, $id
   $type - The table name for object you want get locations for
   $id   - id of object you want get locations for
   $attr - hash reference of extra arguments

 if $attr contains {COLS_NAME}
  returns array of hashes representing locations for an object
 else
  returns array of arrays

=head2 EXAMPLES
  Get locations for Administrator with aid = 2
    my $locations = $Info->get_locations('admins', 2, { COLS_NAME => 1 });

  Will return:
    [
      {
        'id'         => 2,                        # Id of location in `locations` table
        'text'       => 'This guy is awesome',    # Text of comment
        'date'       => '01.01.2016 01:02:59',    # DateTime when location was leaved
        'name'       => 'John'                    # Name of administrator who pinned location
      }
    ]
=cut
#**********************************************************
sub get_locations {
  my $self = shift;
  my ($obj_type, $id, $attr) = @_;

  return _get_info_list (
    $obj_type, $id, LOCATION_TABLE, $attr
  );
}

#**********************************************************
=head2 add_location($obj_type, $obj_id, $attr)

=cut
#**********************************************************
sub add_location {
  my $self = shift;
  my ($obj_type, $obj_id, $attr) = @_;

  if ($attr->{TIME}){
    $attr->{TIME} = strftime('%F %T', localtime($attr->{TIME}))
  }
  if ($attr->{TIMESTAMP} && $attr->{TIMESTAMP} =~ /\d*/){
    $attr->{TIMESTAMP} = strftime('%F %T', localtime($attr->{TIMESTAMP}))
  }


  #add location
  return _add_info( $obj_type, $obj_id, LOCATION_TABLE,
    {
      %{$attr},
    }
  );

}

#**********************************************************
=head2 del_location

 Main function to delete location by $id
   $attr - hash reference of extra arguments
      LOCATION_ID   - id of location you want to delete

 Removes location row with specified location_id from `info_locations` and `info_info` tables

=cut
#**********************************************************
sub del_location {
  my $self = shift;
  my ($attr) = @_;

  return _del_info(LOCATION_TABLE, $attr);
}

#**********************************************************
=head2 get_documents ($type, $id)

 Main function to get documents for $type, $id
   $type - The table name for object you want get documents for
   $id   - id of object you want get documents for
   $attr - hash reference of extra arguments

 if $attr contains {COLS_NAME}
  returns array of hashes representing documents for an object
 else
  returns array of arrays

=head2 EXAMPLES
  Get documents for Administrator with aid = 2
    my $documents = $Info->get_documents('admins', 2, { COLS_NAME => 1 });

  Will return:
    [
      {
        'id'         => 2,                        # Id of comment in `documents` table
        'text'       => 'This guy is awesome',    # Text of comment
        'date'       => '01.01.2016 01:02:59',    # DateTime when comment was leaved
        'name'       => 'John'                    # Name of administrator who leaved comment
      }
    ]
=cut
#**********************************************************
sub get_documents {
  my $self = shift;
  my ($obj_type, $id, $attr) = @_;

  return _get_info_list (
    $obj_type, $id, DOCUMENT_TABLE, $attr
  );
}

#**********************************************************
=head2 get_document_info($document_id, $attr)

=cut
#**********************************************************
sub get_document_info {
  my $self = shift;
  my ($document_id, $attr) = @_;

  return _get_info_info (DOCUMENT_TABLE, $document_id, $attr);
}

#**********************************************************
=head2 add_document($obj_type, $obj_id, $attr)

=cut
#**********************************************************
sub add_document {
  my $self = shift;
  my ($obj_type, $obj_id, $attr) = @_;

  #add document
  return _add_info( $obj_type, $obj_id, DOCUMENT_TABLE,$attr );
}

#**********************************************************
=head2 del_document

 Main function to delete document by $id
   $attr - hash reference of extra arguments
      DOCUMENT_ID   - id of document you want to delete

 Removes document row with specified document_id from `info_documents` and `info_info` tables

=cut
#**********************************************************
sub del_document {
  my $self = shift;
  my ($attr) = @_;

  return _del_info(DOCUMENT_TABLE, $attr);
}


#**********************************************************
=head2 del_info abstraction of deleting Info module related information

 Main function to delete info entity by $id
   $table - hash_ref with `info_*` table info
   $attr - hash reference of extra arguments
      OBJ_ID   - id of document you want to delete

 Removes object row with specified object_id from `info_*` and `info_info` tables

=cut
#**********************************************************
sub _del_info {
  my ($table, $attr) = @_;

  my $key = uc($table->{TYPE})."_ID";

  #delete universl_info
  $instance->query_del('info_info', undef, { "$key" => $attr->{OBJ_ID} });

  if ($instance->{errno}){
    print "$instance->{errstr}";
  }

  #delete referenced object
  $instance->query_del($table->{NAME}, undef, { ID => $attr->{OBJ_ID} });

  return 1;

}

#**********************************************************
=head2 _get_info_info($table, $type_id, $attr) - generalization for DB Select

=cut
#**********************************************************
sub _get_info_info {
  my ($table, $type_id, $attr) = @_;

  if (!defined $type_id) {
    return 0;
  }

  my $COLUMNS = join(', ', @{$table->{COLUMNS}});
  
  my $type = $table->{TYPE};
  my $table_name = $table->{NAME};
  my $table_al = $table->{ALIAS};

  $instance->query(
    "SELECT
      $COLUMNS
      FROM
      $table_name $table_al
      LEFT JOIN info_info i ON ($table_al.id = i.$type\_id)
      LEFT JOIN admins a ON (i.admin_id = a.aid)
      WHERE i.$type\_id <> 0 AND $table_al.id = ?
      LIMIT 1",
    undef,
    {
    %{$attr},
      Bind => [ $type_id ]
    }
  );

  if ($instance->{errno}){
    return {};
  }

  return $instance->{list}->[0];
}

#**********************************************************
=head2 _get_info_list($obj_type, $id, $table, $attr)

=cut
#**********************************************************
sub _get_info_list {
  my ($obj_type, $id, $table, $attr) = @_;

  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  if (!(defined $obj_type && defined $id)) {
    return 0;
  }

  my $COLUMNS = join(', ', @{$table->{COLUMNS}}) || return get_error(1, "Uncorrect Table definition");
  my $ALIAS = $table->{ALIAS} || return get_error(1, "Uncorrect Table definition");
  my $type = $table->{TYPE} || return get_error(1, "Uncorrect Table definition");
  my $table_name = $table->{NAME} || return get_error(1, "Uncorrect Table definition");
  $instance->query(
    "SELECT
      $COLUMNS
      FROM
      info_info i
      LEFT JOIN $table_name $ALIAS ON ($ALIAS.id = i.$type\_id)
      LEFT JOIN admins a ON (i.admin_id = a.aid)
      WHERE i.$type\_id <> 0 AND i.obj_type= ? AND i.obj_id= ?
      LIMIT $PG, $PAGE_ROWS",
    undef,
    {
      %{$attr},
      Bind => [ $obj_type, $id ]
    }
  );

  my $list = $instance->{list};

  if (wantarray) {
    $instance->query("SELECT COUNT(*) AS total
        FROM
        info_info i
        LEFT JOIN $table_name $ALIAS ON ($ALIAS.id = i.comment_id)
        LEFT JOIN admins a ON (i.admin_id = a.aid)
        WHERE i.obj_type= ? AND i.obj_id= ? ",
      undef,
      {
        INFO => 1,
        Bind => [ $obj_type, $id ]
      }
    );

    my $total = $instance->{list};
    return ($list, $total);
  }

  return $list;
}

#**********************************************************
=head2 _add_info($obj_type, $obj_id, $table, $attr)

=cut
#**********************************************************
sub _add_info {
  my ($obj_type, $obj_id, $table, $attr) = @_;

  #All entities has autoincrement ID. If it was passed here that would cause error writing to DB
  delete $attr->{ID};

  my $type = $table->{TYPE} || return get_error(1, "Uncorrect Table definition");
  my $table_name = $table->{NAME} || return get_error(1, "Uncorrect Table definition");

  my $key = uc $type."_ID";

  #add comment
  $instance->query_add(
    $table_name,
    $attr
  );

  if ($instance->{debug}){
    print "<hr><h1>Last insert id $instance->{INSERT_ID}</h1>"
  }

  if ($instance->{errno}){
    return 0;
  }

  #add info
  $instance->query_add(
    'info_info',
    {
      OBJ_TYPE => $obj_type,
      OBJ_ID   => $obj_id,
      $key     => $instance->{INSERT_ID},
      DATE     => 'NOW()',
      ADMIN_ID => $instance->{admin}{AID}
    }
  );

  return 1;
}

#**********************************************************
=head2 get_error($errno, $errstr)

=cut
#**********************************************************
sub get_error {
  my ($errno, $errstr) = @_;

  $instance->{errno} = $errno;
  $instance->{errstr} = $errstr;

  return 1;
}

#**********************************************************
=head2 search_comments()

  Arguments:
    $comments - search comment

  Returns:
    $self

=cut
#**********************************************************
sub search_comments {
  my $self = shift;
  my ($comments) = @_;

  $self->query("SELECT ic.id, ic.text, ii.date, ii.obj_id, ii.admin_id FROM info_comments AS ic
   LEFT JOIN info_info AS ii ON ic.id = ii.id WHERE ic.text LIKE '\%$comments\%'", undef, {
    COLS_NAME => 1
  });

  return $self;
}

#**********************************************************
=head2 change_comments()

  Arguments:
    ID            - ID change comment
    AID           - admin id changes comment
    UID           - user id save comment
    TEXT          - comment new
    OLD_COMMENTS  - old comment

  Return:
    $self

=cut
#**********************************************************
sub change_comments {
  my $self = shift;
  my ($attr) = @_;

  $self->query("UPDATE info_comments SET text = ? WHERE id = ?", undef, {
    Bind => [ $attr->{TEXT}, $attr->{ID} ]
  });

  $self->query_add('info_change_comments', {
    ID_COMMENTS => $attr->{ID},
    DATE_CHANGE => 'NOW()',
    AID         => $attr->{AID},
    UID         => $attr->{UID},
    TEXT        => $attr->{TEXT},
    OLD_COMMENT => $attr->{OLD_COMMENTS},
  });

  $admin->action_add($attr->{UID}, "$attr->{OLD_COMMENTS} -> $attr->{TEXT}", { TYPE => 2 });

  return $self;
}

#**********************************************************
=head2 change_comments()

  Arguments:
    -

  Returns:
    -

=cut
#**********************************************************
sub log_comments {
  my $self = shift;
  my ($attr) = @_;

  if($attr->{COMMENT_ID}) {
    $self->query("SELECT * FROM info_change_comments WHERE id_comments = ?;", undef, {
      COLS_NAME => 1,
      Bind => [ $attr->{COMMENT_ID} ]
    });
  } else {
    $self->query("SELECT icc.aid, icc.date_change, icc.id_comments,
                icc.old_comment, icc.text, icc.uid
                FROM info_change_comments AS icc;", undef, {
      COLS_NAME => 1
    });
  }

  return $self->{list};
}

#**********************************************************
=head2 info_document_add($attr)

=cut
#**********************************************************
sub info_document_add {
  my $self = shift;
  my ($attr) = @_;

  # If have one attachment linked to a lot messages, will save it as one file
  my $comment_id = $attr->{COMMENT_ID};
  return $self if (!$comment_id);

  $attr->{CONTENT} //= $attr->{FILE};
  my $file_path = $self->_save_to_disk($comment_id, $attr->{FILENAME}, $attr);
  return 0 if (!$file_path || $self->{errno});

  $attr->{FILE} = "FILE: $file_path";

  $self->query_add('info_documents', $attr);
  
  return $self;
}

#**********************************************************
=head2 info_documents_list($attr) - documents list

=cut
#**********************************************************
sub info_documents_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = $attr->{SORT} || 'id';
  my $DESC = ($attr->{DESC}) ? '' : 'DESC';
  my $PG = $attr->{PG} || '0';
  my $PAGE_ROWS = $attr->{PAGE_ROWS} || 25;

  # Both values are stored in single column
  if ($attr->{REPLY_ID}) {
    $attr->{MESSAGE_ID} = $attr->{REPLY_ID};
    $attr->{MESSAGE_TYPE} = 1;
  }

  my $search_columns = [
    [ 'ID',           'INT',  'ind.id',           1 ],
    [ 'COMMENT_ID',   'INT',  'ind.comment_id',   1 ],
    [ 'FILENAME',     'STR',  'ind.filename',     1 ],
    [ 'CONTENT_SIZE', 'STR',  'ind.content_size', 1 ],
    [ 'CONTENT_TYPE', 'STR',  'ind.content_type', 1 ],
    [ 'FILE',         'STR',  'ind.file',         1 ]
  ];

  if ($attr->{SHOW_ALL_COLUMNS}) {
    map {$attr->{$_->[0]} = '_SHOW' unless exists $attr->{$_->[0]}} @$search_columns;
  }

  my $WHERE = $self->search_former($attr, $search_columns, { WHERE => 1 });

  $self->query("SELECT $self->{SEARCH_FIELDS} ind.id
   FROM info_documents ind
   $WHERE
   ORDER BY $SORT $DESC
   LIMIT $PG, $PAGE_ROWS;", undef, {
    COLS_NAME => 1,
    COLS_UPPER => 1,
    %{$attr // {}} }
  );

  return [] if $self->{errno};

  return $self->{list};
}

#**********************************************************
=head2 info_document_info($attr) - document info

=cut
#**********************************************************
sub info_document_info {
  my $self = shift;
  my ($id, $attr) = @_;

  $self->query("SELECT * FROM info_documents WHERE id = ?;", undef, { INFO => 1, Bind => [ $id ] });

  return 0 if $self->{errno};

  if (!$attr->{WITHOUT_CONTENT}) {
    my ($directory, $filename) = $self->_read_file_params($self->{FILE});

    if ($directory && $filename && -f "$directory/$filename") {
      $self->{FILE} = $self->_read_file_from_disk($directory, $filename);
      return 0 if $self->{errno};
    }
  }

  return $self;
}

#**********************************************************
=head2 info_document_del($attr) - Del document

=cut
#**********************************************************
sub info_document_del {
  my $self = shift;
  my ($attr) = @_;

  if (!$attr->{ID}) {
    $self->{errno} = 115;
    return $self;
  }

  $self->info_document_info($attr->{ID}, { WITHOUT_CONTENT => 1 });
  $self->query_del('info_documents', undef, { ID => $attr->{ID} });

  if ($self->{FILENAME}) {
    if ($self->{FILE} =~ /FILE(?:NAME)?: .+\/\/?([a-zA-Z0-9_\-.]+)/) {
      $attr->{FILENAME} = $1;
      delete $attr->{UID};
      $Attach->attachment_file_del($attr);
    }
  }

  return $self;
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
  my $self = shift;
  my ($comment_id, $filename, $attr) = @_;

  # filename should contain only alphanumeric_symbols
  $filename //= '';
  $filename =~ s/[^a-zA-Z0-9._-]/_/g;

  # Should change filename. map will replace undefined values with 0
  my $disk_filename = join('_', map {$_ // '0'} ($comment_id, $filename));

  my $final_path = $Attach->save_file_to_disk({
    %{$attr},
    FILENAME          => $filename,
    DISK_FILENAME     => $disk_filename,
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
  my $self = shift;
  my ($directory, $filename) = @_;

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
  my $self = shift;
  my ($content_field_value) = @_;

  if ($content_field_value && $content_field_value =~ /FILE: (.+\/)+\/?([a-zA-Z0-9_\-.]+)/) {
    my $directory = $1;
    my $filename = $2;

    return wantarray ? ($directory, $filename) : "$directory/$filename";
  };

  return 0;
}

1;