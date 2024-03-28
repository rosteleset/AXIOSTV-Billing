
=head1 Ring

Megogo - module for redial users

=head1 Synopsis

use Ring;

my $Ring = Ring->new($db, $admin, \%conf);

=cut

package Ring;

use strict;
use parent qw(dbcore);

our $VERSION = 0.04;

my ($admin, $CONF);

#*******************************************************************

=head2 function new() - initialize Ring object

  Arguments:
    $db    -
    $admin -
    %conf  -
  Returns:
    $self object

  Examples:
    $Ring = Ring->new($db, $admin, \%conf);

=cut

#*******************************************************************
sub new {
  my $class = shift;
  my $db    = shift;
  ($admin, $CONF) = @_;

  my $self = {};
  bless($self, $class);

  $self->{db} = $db;
  $self->{admin} = $admin;
  $self->{conf}  = $CONF;

  return $self;
}

#*******************************************************************

=head2 function add_rule() - add rule to table ring_rule

  Arguments:
    %$attr
      $NAME    - rule's name;
      $DATE    - date, when rule will turn on;
      $COMMENT - comments for rule;
  Returns:
    $self object

  Examples:
    $Ring->add_rule({
      NAME    => $FORM{NAME},
      DATE    => $FORM{DATE},
      COMMENT => $FORM{COMMENT}
    });

=cut

#*******************************************************************
sub add_rule {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('ring_rules', {%$attr});

  return $self;
}

#*******************************************************************
=head2 function del_rule() - delete rule's information from datebase

  Arguments:
    $attr

  Returns:

  Examples:
    $Ring->del_rule( {ID => 1} );

=cut
#*******************************************************************
sub del_rule {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('ring_rules', $attr);

  return $self;
}

#*******************************************************************
=head2 function add_rule() - get info about the rule from table ring_rule

  Arguments:
    %$attr
      RULE_ID - identifier;
  Returns:
    $self object

  Examples:
    my $rule_info = $Ring->select_rule({ RULE_ID => 1});

=cut
#*******************************************************************
sub select_rule {
  my $self = shift;
  my ($attr) = @_;

  if ($attr->{RULE_ID}) {
    $self->query(
      "SELECT * FROM ring_rules
      WHERE id = ?;", undef, { INFO => 1, Bind => [ $attr->{RULE_ID} ] }
    );
  }

  return $self;
}

#*******************************************************************
=head2 function change_rule() - change rule's information in datebase

  Arguments:
    $attr

  Returns:
    $self object

  Examples:
    $Megogo->change_rule({
      ID     => 1,
      NAME   => 'test',
    });
    $Ring->change_rule({
      %FORM
    });

=cut
#*******************************************************************
sub change_rule {
  my $self = shift;
  my ($attr) = @_;

  $self->changes(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'ring_rules',
      DATA         => $attr
    }
  );

  return $self;
}

#*******************************************************************
=head2 function list_rule() - get list of rules

  Arguments:
    %$attr

  Returns:
    $self object

  Examples:
    $list = $Ring->list_rule( {} );

=cut
#*******************************************************************
sub list_rule {
  my $self = shift;
  my ($attr) = @_;

  my @WHERE_RULES = ();
  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  my $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  if($attr->{DATE_NOW}){
    push @WHERE_RULES, "DATE_START <= '$attr->{DATE_NOW}' and DATE_END >= '$attr->{DATE_NOW}'";
  }

  my $WHERE = $self->search_former( $attr, [
      [ 'ID',          'INT',  'id',          1],
      [ 'NAME',        'STR',  'name',       1],
      [ 'DATE_START',  'DATE', 'date_start',  1],
      [ 'DATE_END',    'DATE', 'date_end',    1],
      [ 'TIME_START',  'STR',  'time_start',  1],
      [ 'TIME_END',    'STR',  'time_end',    1],
      [ 'FILE',        'STR',  'file',        1],
      [ 'MESSAGE',     'STR',  'message',     1],
      [ 'COMMENT',     'STR',  'comment',     1],
      [ 'EVERY_MONTH', 'INT',  'every_month', 1],
      [ 'UPDATE_DAY',  'INT',  'update_day',  1],
      [ 'SQL_QUERY',   'STR',  'sql_query',   1],
    ],
    {
      WHERE => 1,
    }
  );

  $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

  $self->query(
    "SELECT $self->{SEARCH_FIELDS} id FROM ring_rules
    $WHERE
    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list};

  return $self->{list} if ($self->{TOTAL} < 1);

  $self->query(
    "SELECT COUNT(*) AS total
     FROM ring_rules $WHERE",
    undef,
    { INFO => 1 }
  );

  return $list;
}

#*******************************************************************
=head2 function add_users() - add user to table ring_users_filters

  Arguments:
    %$attr
      UID     - user's identifier;
      R_ID    - rule's identifier;
      DATE    - date;
      STATUS  - call status;
  Returns:
    $self object

  Examples:
    $Ring->add_rule({
      UID   => 1,
      R_ID  => 1
    });

=cut
#*******************************************************************
sub add_user {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('ring_users_filters', {%$attr});

  return $self;
}

#*******************************************************************
=head2 function rule_users() - get list of users for rule

  Arguments:
    %$attr

  Returns:
    $self object

  Examples:
    $list = $Ring->rule_users( {COLS_NAME => 1} );

=cut
#*******************************************************************
sub rule_users {
  my $self = shift;
  my ($attr) = @_;

  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  my $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my @WHERE_RULES = ();

  if($attr->{RID}){
    push @WHERE_RULES, "r_id = $attr->{RID}";
  }

  if(defined $attr->{STATUS}){
    push @WHERE_RULES, "status = $attr->{STATUS}";
  }

  my $WHERE = $self->search_former( $attr, [
      [ 'UID',          'INT',  'uid',     1],
      [ 'R_ID',         'INT',  'r_id',    1],
      [ 'TIME',         'STR',  'time',    1],
      [ 'DATE',         'DATE', 'date',    1],
      [ 'STATUS',       'INT',  'status',  1],
    ],
    {
      WHERE => 1,
    }
  );

  $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

  $self->query(
    "SELECT * FROM ring_users_filters
    $WHERE
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr,
    { INFO => 1 }
  );

  my $list = $self->{list};

  return $self->{list} if ($self->{TOTAL} < 1);

  $self->query(
    "SELECT COUNT(*) AS total
   FROM ring_users_filters
   $WHERE",
    undef,
    { INFO => 1 }
  );

  return $list;
}

#*******************************************************************
=head2 function change_user() - change rule's information in datebase

  Arguments:
    $attr
      R_ID   - rule's identifier
      UID    - user's identifier
      STATUS - call status
      DATE   - call date

  Returns:
    $self object

  Examples:
    $Ring->change_user({
      R_ID => 1,
      UID  => 1,
      STATUS => 2,
      DATE   => $DATE
    });

=cut
#*******************************************************************
sub change_user {
  my $self = shift;
  my ($attr) = @_;

  $self->changes(
    {
      CHANGE_PARAM => 'UID,R_ID',
      TABLE        => 'ring_users_filters',
      DATA         => $attr,
    }
  );

  return $self;
}

#*******************************************************************
=head2 function del_user() - delete rule's information from datebase

  Arguments:
    $attr

  Returns:

  Examples:
    $Ring->del_user( {UID => 1} );

=cut

#*******************************************************************
sub del_user {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('ring_users_filters', $attr, { UID => $attr->{UID}, R_ID => $attr->{R_ID} });

  return $self;
}

#**********************************************************
=head2 add_users_by_rule($attr)

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub add_users_by_rule {
  my $self = shift;
  my ($attr) = @_;

  $self->query("$attr->{SQL_QUERY}", undef, {COLS_NAME => 1});
  my $list = $self->{list};

  foreach my $item (@$list) {
    $self->query_add('ring_users_filters', {UID => $item->{uid}, R_ID => $attr->{R_ID}});
  }

  return 1;
}

1
