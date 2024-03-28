package Mdelivery;

=head1 NAME

  Mail delivery functions

=cut

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION
);

use Exporter;
$VERSION = 2.00;
@ISA     = ('Exporter');

@EXPORT = qw();

@EXPORT_OK   = ();
%EXPORT_TAGS = ();

use main;
@ISA = ("main");

my ($admin, $CONF);
my ($SORT, $DESC, $PG, $PAGE_ROWS);

#**********************************************************
# Init
#**********************************************************
sub new{
  my $class = shift;
  my $db = shift;
  ($self->{admin}, $CONF) = @_;

  $self->{admin}->{MODULE} = 'Mdelivery';
  my $self = { };

  bless( $self, $class );
  $self->{db} = $db;
  $self->{admin} = $admin;
  $self->{conf} = $CONF;

  return $self;
}

#**********************************************************
#
#**********************************************************
sub defaults {
  my $self = shift;

  my %DATA = (
    DATE     => '0000-00-00',
    SUBJECT  => '',
    AID      => 0,
    FROM     => '',
    TEXT     => '',
    UID      => 0,
    GID      => 0,
    PRIORITY => 3
  );

  $self = \%DATA;
  return $self;
}

#**********************************************************
# User information
# info()
#**********************************************************
sub info {
  my $self = shift;
  my ($id) = @_;

  my $WHERE;

  $self->query2("SELECT
     md.id,
     md.date,
     md.subject,
     md.sender,
     a.id AS admin,
     md.added,
     md.text,
     md.priority,
     u.id AS login,
     g.name AS group_name
     FROM mdelivery_list md
     LEFT JOIN admins a ON (md.aid=a.aid)
     LEFT JOIN groups g ON (md.gid=g.gid)
     LEFT JOIN users u ON (md.uid=u.uid)
     WHERE md.id='$id';",
    undef,
    { INFO => 1 }
  );

  return $self;
}

#**********************************************************
# User information
# info()
#**********************************************************
sub change {
  my $self = shift;
  my ($attr) = @_;

  $self->query2("UPDATE mdelivery_list SET status=1 WHERE id='$attr->{ID}';", 'do');

  return $self;
}

#**********************************************************
# Delete user info from all tables
#
# del(attr);
#**********************************************************
sub del {
  my $self = shift;
  my ($id) = @_;

  $self->query2("DELETE from mdelivery_list WHERE id='$id';", 'do');
  $self->user_list_del({ MDELIVERY_ID => $id });

  $self->{admin}->system_action_add("$id", { TYPE => 10 });

  return $self->{result};
}

#**********************************************************
# User information
# info()
#**********************************************************
sub add {
  my $self = shift;
  my ($attr) = @_;

  my %DATA = $self->get_data($attr, { default => defaults() });

  $self->query2("INSERT INTO mdelivery_list (date, added, subject, sender, aid, text, uid, gid,
     priority)
     values ('$DATA{DATE}', now(), '$DATA{SUBJECT}',
     '$DATA{FROM}',
     '$self->{admin}->{AID}',
     '$DATA{TEXT}',
     '$DATA{UID}',
     '$DATA{GID}',
     '$DATA{PRIORITY}');", 'do'
  );

  $self->{MDELIVERY_ID} = $self->{INSERT_ID};

  $self->user_list_add({ %$attr, MDELIVERY_ID => $self->{MDELIVERY_ID} });

  $self->{admin}->system_action_add("$self->{MDELIVERY_ID}", { TYPE => 1 });

  return $self;
}

#**********************************************************
#
#
#**********************************************************
sub user_list_add {
  my $self = shift;
  my ($attr) = @_;

  my @WHERE_RULES = ();
  my $EXT_TABLES  = '';

  if ($CONF->{ADDRESS_REGISTER}) {
    if ($attr->{LOCATION_ID}) {
      push @WHERE_RULES, @{ $self->search_expr($attr->{LOCATION_ID}, 'INT', 'pi.location') };
    }
    elsif ($attr->{STREET_ID}) {
      push @WHERE_RULES, @{ $self->search_expr($attr->{STREET_ID}, 'INT', 'builds.street_id', { EXT_FIELD => 'streets.name' }) };
      $EXT_TABLES .= "INNER JOIN builds ON (builds.id=pi.location_id)";
    }
    elsif ($attr->{DISTRICT_ID}) {
      push @WHERE_RULES, @{ $self->search_expr($attr->{DISTRICT_ID}, 'INT', 'streets.district_id', { EXT_FIELD => 'districts.name' }) };
      $EXT_TABLES .= "INNER JOIN builds ON (builds.id=pi.location_id)
      INNER JOIN streets ON (streets.id=builds.street_id)";
    }

    elsif ($attr->{STREET_ID}) {
      push @WHERE_RULES, @{ $self->search_expr($attr->{STREET_ID}, 'STR', 'pi.address_street') };
    }
    elsif ($attr->{DISTRICT_ID}) {
      push @WHERE_RULES, @{ $self->search_expr($attr->{DISTRICT_ID}, 'STR', 'pi.address_street') };
    }
  }
  else {
    if ($attr->{ADDRESS_STREET}) {
      push @WHERE_RULES, @{ $self->search_expr($attr->{ADDRESS_STREET}, 'STR', 'pi.address_street') };
    }

    if ($attr->{ADDRESS_BUILD}) {
      push @WHERE_RULES, @{ $self->search_expr($attr->{ADDRESS_BUILD}, 'STR', 'pi.address_build') };
    }

    if ($attr->{ADDRESS_FLAT}) {
      push @WHERE_RULES, @{ $self->search_expr($attr->{ADDRESS_FLAT}, 'STR', 'pi.address_flat') };
    }
  }

  if (defined($attr->{DV_STATUS}) && $attr->{DV_STATUS} ne '') {
    push @WHERE_RULES, @{ $self->search_expr($attr->{DV_STATUS}, 'INT', "dv.disable") };
    $EXT_TABLES = "LEFT JOIN dv_main dv ON (u.uid=dv.uid)";
  }

  if ($attr->{TP_ID}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{TP_ID}, 'INT', "dv.tp_id") };
    $EXT_TABLES = "LEFT JOIN dv_main dv ON (u.uid=dv.uid)";
  }

  my $WHERE =  $self->search_former($attr, [
        [ 'STATUS',          'INT', 'u.disable' ],
        [ 'GID',             'INT', 'u.gid' ],
    ],
    { WHERE => 1,
    	WHERE_RULES => \@WHERE_RULES
    }
    );


  $self->query2("INSERT INTO mdelivery_users (uid, mdelivery_id) SELECT u.uid, $attr->{MDELIVERY_ID} FROM users u
     LEFT JOIN users_pi pi ON (u.uid=pi.uid)
     $EXT_TABLES
     $WHERE
     ORDER BY $SORT;",
  undef,
  $attr
  );

  return $self;
}

#**********************************************************
#
#
#**********************************************************
sub user_list_change {
  my $self = shift;
  my ($attr) = @_;

  my @WHERE_RULES = ("mdelivery_id='$attr->{MDELIVERY_ID}'");

  my $WHERE =  $self->search_former($attr, [
        [ 'UID',        'INT', 'uid' ],
        [ 'ID',         'INT', 'id' ],
    ],
    {
    	WHERE_RULES => \@WHERE_RULES
    }
    );

  my $status = 1;
  $self->query2("UPDATE mdelivery_users SET status='$status' WHERE $WHERE;", 'do');

  return $self;
}

#**********************************************************
#
#
#**********************************************************
sub user_list_del {
  my $self = shift;
  my ($attr) = @_;

  my $WHERE =  $self->search_former($attr, [
        [ 'UID',          'INT', 'uid' ],
        [ 'ID',           'INT', 'id' ],
        [ 'MDELIVERY_ID', 'INT', 'mdelivery_id' ],
    ]);

  $self->query2("DELETE FROM mdelivery_users WHERE $WHERE;", 'do');

  return $self;
}

#**********************************************************
#
#
#**********************************************************
sub user_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my @WHERE_RULES = ("u.uid=mdl.uid");

  my $WHERE =  $self->search_former($attr, [
        [ 'UID',          'INT', 'uid'          ],
        [ 'STATUS',       'INT', 'mdl.status'   ],
        [ 'LOGIN',        'STR', 'u.id'         ],
        [ 'MDELIVERY_ID', 'INT', 'mdelivery_id' ],
    ],
    {
    	WHERE       => 1,
    	WHERE_RULES => \@WHERE_RULES
    }
    );

  $self->query2("SELECT u.id AS login, pi.fio, mdl.status, mdl.uid, pi.email
     FROM (mdelivery_users mdl, users u)
     LEFT JOIN users_pi pi ON (mdl.uid=pi.uid)
     $WHERE
     ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
  undef,
  $attr
  );

  my $list = $self->{list};

  $self->query2("SELECT count(*) AS total
     FROM mdelivery_users mdl, users u
     $WHERE;",
     undef, {INFO => 1 }
  );

  return $list;
}

#**********************************************************
# User information
# info()
#**********************************************************
sub list {
  my $self = shift;
  my ($attr) = @_;

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $WHERE =  $self->search_former($attr, [
        [ 'subject',      'STR',  'md.date'  ],
        [ 'STATUS',       'INT',  'md.status'],
        [ 'DATE',         'DATE', 'md.date'  ],
        [ 'ID',           'INT',  'md.id'    ],
    ],
    {
    	WHERE       => 1,
    }
    );

  $self->query2("SELECT
    md.id,  md.date, md.subject, md.sender, a.id AS admin_login, md.added, length(md.text) AS message_text, md.status
     FROM mdelivery_list md
     LEFT JOIN admins a ON (md.aid=a.aid)
     $WHERE
     ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
  undef,
  $attr
  );

  my $list = $self->{list};

  if ($self->{TOTAL} > 0) {
    $self->query2("SELECT count(*) AS total
     FROM mdelivery_list md
     LEFT JOIN admins a ON (md.aid=a.aid) $WHERE;",
     undef,
     { INFO => 1 }
    );
  }
  return $list;
}

#**********************************************************
#
#**********************************************************
sub attachment_add () {
  my $self = shift;
  my ($attr) = @_;

  $self->query2("INSERT INTO mdelivery_attachments "
    . " (message_id, filename, content_type, content_size, content, "
    . " create_time, create_by, change_time, change_by) "
    . " VALUES "
    . " ('$attr->{MSG_ID}', '$attr->{FILENAME}', '$attr->{CONTENT_TYPE}', '$attr->{FILESIZE}', ?, "
    . " current_timestamp, '$attr->{UID}', current_timestamp, '0')",
    'do',
    { Bind => [ $attr->{CONTENT} ] }
  );

  return $self;
}

#**********************************************************
#
#**********************************************************
sub attachment_info () {
  my $self = shift;
  my ($attr) = @_;

  my $WHERE = '';

  if ($attr->{MSG_ID}) {
    $WHERE = "message_id='$attr->{MSG_ID}'";
  }
  elsif ($attr->{ID}) {
    $WHERE = "id='$attr->{ID}'";
  }

  $self->query2("SELECT id AS attachment_id, filename,
    content_type,
    content_size AS filesize,
    content
   FROM  mdelivery_attachments
   WHERE $WHERE",
   undef,
   $attr
  );

  return $self;
}

#**********************************************************
#
#**********************************************************
sub reset {
  my ($self) = shift;
  my ($attr) = @_;

  $self->query2("UPDATE mdelivery_list SET status=0 WHERE id='$attr->{ID}';",            'do');
  $self->query2("UPDATE mdelivery_users SET status=0 WHERE mdelivery_id='$attr->{ID}';", 'do');

  return $self;

}

1
