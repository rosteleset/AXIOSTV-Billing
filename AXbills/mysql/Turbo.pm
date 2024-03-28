package Turbo;

=head2 NAME

  Turbo  managment functions

=cut

use strict;
use parent qw(dbcore);
use Tariffs;
use Users;
use Fees;

our $VERSION = 7.51;
my $MODULE = 'Turbo';
my ($admin, $CONF);

#**********************************************************
# Init
#**********************************************************
sub new {
  my $class = shift;
  my $db    = shift;
  ($admin, $CONF) = @_;
  $admin->{MODULE} = $MODULE;
  my $self = {
    db    => $db,
    conf  => $CONF,
    admin => $admin
  };

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 info($attr) information

=cut
#**********************************************************
sub info {
  my $self = shift;
  my ($attr) = @_;

  $self->query("SELECT * FROM turbo_mode 
   WHERE uid = ?;",
    undef,
    { INFO => 1,
      Bind => [ $attr->{UID} ] }
  );

  return $self;
}

#**********************************************************
=head2 add($attr)
=cut
#**********************************************************
sub add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('turbo_mode', {
    %$attr,
    START => ($attr->{DATE}) ? "$attr->{DATE}" : 'NOW()'
  });

  $admin->{MODULE} = $MODULE;
  $admin->action_add("$attr->{UID}", "TURBO", { TYPE => 1 });
  return $self;
}

#**********************************************************
=head2 del(attr);

=cut
#**********************************************************
sub del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('turbo_mode', $attr);

  $admin->action_add($self->{UID}, "TURBO $attr->{ID}", { TYPE => 10 });
  return $self->{result};
}

#**********************************************************
=head2 extra_hangup($attr) - manual turbo hangup

=cut
#**********************************************************
sub extra_hangup {
  my $self = shift;
  my ($attr) = @_;

  $self->query(
    'UPDATE turbo_mode SET time = 0 WHERE id = ?;',
    'do',
    {
      Bind => [ $attr->{ID} ]
    });

  return $self;
}

#**********************************************************
=head2 list($attr)

=cut
#**********************************************************
sub list {
  my $self   = shift;
  my ($attr) = @_;

  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  my $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $GROUP_BY = '';

  if (defined($attr->{GROUP_BY})) {
    $GROUP_BY = $attr->{GROUP_BY};
  }

  my @WHERE_RULES = ("u.uid = t.uid");

  if ($attr->{ACTIVE}) {
    push @WHERE_RULES, "UNIX_TIMESTAMP(t.start)+t.time>UNIX_TIMESTAMP()";
  }

  my $WHERE = $self->search_former(
    $attr,
    [ [ 'NAME',     'STR', 'd.name',      1 ],
      [ 'STATE',    'INT', 'd.state',     1 ],
      [ 'COMMENTS', 'STR', 'd.comments'     ],
    ],
    {
      WHERE        => 1,
      WHERE_RULES  => \@WHERE_RULES,
      USERS_FIELDS => 1
    }
  );

  my $EXT_TABLE = $self->{EXT_TABLE} || '';

  $self->query("SELECT u.id AS login,
   t.mode_id,
   if (UNIX_TIMESTAMP(t.start)+t.time > UNIX_TIMESTAMP(), SEC_TO_TIME(UNIX_TIMESTAMP(t.start)+t.time - UNIX_TIMESTAMP()), '00:00:00') AS last_time,
   t.start,
   t.time,
   t.speed,
   t.speed_type,
   t.uid,
   t.id
     FROM (users u, turbo_mode t)
     $EXT_TABLE
     $WHERE 
     $GROUP_BY
     ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
     undef,
     $attr
  );

  return $self if ($self->{errno});

  my $list = $self->{list};

  if ($self->{TOTAL} >= 0 && !$attr->{SKIP_TOTAL}) {
    $self->query("SELECT COUNT(u.id) AS total FROM (users u, turbo_mode t)
    $WHERE", undef, { INFO => 1 }
    );
  }

  return $list;
}

1

