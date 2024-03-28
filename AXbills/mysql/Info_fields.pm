package Info_fields;

=head2

  Info_fields

=cut

use strict;
use parent qw(dbcore);
my $MODULE = 'Info_fields';

#**********************************************************
# Init
#**********************************************************
sub new {
  my $class = shift;
  my ($db, $admin, $CONF) = @_;

  my $self = {};
  bless($self, $class);

  $admin->{MODULE} = $MODULE;
  $self->{db} = $db;
  $self->{admin} = $admin;
  $self->{conf} = $CONF;

  return $self;
}

#**********************************************************

=head2  fields_add() - Add info

=cut

#**********************************************************
sub fields_add {
  my $self = shift;
  my ($attr) = @_;

  $attr->{SQL_FIELD} = "_" . $attr->{SQL_FIELD};

  $self->query_add('info_fields', $attr);

  return $self;
}

#**********************************************************

=head2  fields_del() - Delete info

=cut

#**********************************************************
sub fields_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('info_fields', { ID => $attr });

  return $self->{result};
}

#**********************************************************
=head2 fields_list($attr) - list

=cut
#**********************************************************
sub fields_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  my $WHERE = $self->search_former($attr, [
    [ 'ID',          'INT', 'id',          1 ],
    [ 'NAME',        'STR', 'name',        1 ],
    [ 'SQL_FIELD',   'STR', 'sql_field',   1 ],
    [ 'TYPE',        'INT', 'type',        1 ],
    [ 'PRIORITY',    'INT', 'priority',    1 ],
    [ 'COMPANY',     'INT', 'company',     1 ],
    [ 'ABON_PORTAL', 'INT', 'abon_portal', 1 ],
    [ 'USER_CHG',    'INT', 'user_chg',    1 ],
    [ 'REQUIRED',    'INT', 'required',    1 ],
    [ 'MODULE',      'STR', 'module',      1 ],
    [ 'COMMENT',     'STR', 'comment',     1 ],
    [ 'DOMAIN_ID',   'INT', 'domain_id',   1 ],
  ], { WHERE => 1 });

  if ($attr->{NOT_ALL_FIELDS}) {
    $self->query("SELECT $self->{SEARCH_FIELDS} id
      FROM info_fields
    $WHERE
    ORDER BY $SORT $DESC",
      undef,
      $attr
    );
  }
  else {
    $self->query(
      "SELECT *
     FROM info_fields
     $WHERE
     ORDER BY $SORT $DESC;",
      undef,
      { COLS_NAME => 1, COLS_UPPER => 1 }
    );
  }

  return $self->{list} || [];
}


#**********************************************************
=head2 fields_change($attr) - change

=cut
#**********************************************************
sub fields_change {
  my $self = shift;
  my ($attr) = @_;

  $attr->{REQUIRED} //= 0;
  $attr->{ABON_PORTAL} //= 0;
  $attr->{USER_CHG} //= 0;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'info_fields',
    DATA         => $attr,
  });

  return $self->{result};
}

1;