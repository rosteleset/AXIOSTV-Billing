package Price;
use strict;
use parent 'main';
our $VERSION = 0.01;
my ($admin,
  $CONF);
my ($SORT,
  $DESC,
  $PG,
  $PAGE_ROWS);

#*******************************************************************

sub new {
  my $class = shift;
  my $db = shift;
  ($admin, $CONF) = @_;

  my $self = {};
  bless($self, $class);

  $self->{db} = $db;
  $self->{admin} = $admin;
  $self->{conf} = $CONF;

  return $self;
}

#*******************************************************************

#**********************************************************
=head2 add_service($attr) - add service

  Arguments:
    $attr
      ID

=cut
#**********************************************************
sub add_service {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('price_services_list', { %$attr });

  return $self;
}

#**********************************************************
=head2 del_service($attr) - Delete service

  Arguments:
    $attr
      ID


=cut
#**********************************************************
sub del_service {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('price_services_list', $attr);

  return $self;
}

#**********************************************************
=head2 change_service($attr) - change service

  Arguments:
    $attr
      ID

=cut
#**********************************************************
sub change_service {
  my $self = shift;
  my ($attr) = @_;

  $self->changes2(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'price_services_list',
      DATA         => $attr
    }
  );
  return $self;
}

#**********************************************************
=head2 show_services($attr) - list of services

  Arguments:
    $attr
      ID

=cut
#**********************************************************
sub show_services {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  $self->query2(
    "SELECT *
    FROM price_services_list
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;", undef, $attr
  );

  my $list = $self->{list};
  return $list;
}

#**********************************************************
=head2 list($attr)

=cut
#**********************************************************
sub show_services_with_groups {
  my $self = shift;
  my ($attr) = @_;

  $PG   = $attr->{PG} || '0';
  $PAGE_ROWS = $attr->{PAGE_ROWS} || 25;
  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  my $WHERE =  $self->search_former($attr, [
    ['ID',               'INT',         'ps.id',                 1 ],
    ['NAME',             'STR',         'ps.name',               1 ],
    ['PRICE',            'INT',         'ps.price',              1 ],
    ['TYPE',             'INT',         'ps.type',               1 ],
    ['ID_GROUP',         'INT',         'ps.id_group',           1 ],
    ['COMMENTS',         'STR',         'ps.comments',           1 ],
    ['GROUP_NAME',       'STR',         'pg.name as group_name', 1 ],
  ],
    { WHERE => 1 }
  );

  $self->query2("SELECT
      $self->{SEARCH_FIELDS}
      ps.id
      FROM price_services_list ps
      LEFT JOIN price_groups pg ON (ps.id_group=pg.id)
      $WHERE
      ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    {%$attr, COLS_NAME => 1, COLS_UPPER => 1}
  );

  return [] if ($self->{errno});

  my $list = $self->{list};

  if ($self->{TOTAL} >= 0 && !$attr->{SKIP_TOTAL}) {
    $self->query2("SELECT count( DISTINCT ps.id) AS total
        FROM price_services_list ps
        $WHERE",
      undef,
      { INFO => 1 }
    );
  }

  return $list;
}

#**********************************************************
=head2 show_groups($attr) - list of groups

  Arguments:
    $attr
      ID

=cut
#**********************************************************
sub show_groups {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  $self->query2(
    "SELECT *
    FROM price_groups
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;", undef, $attr
  );

  my $list = $self->{list};
  return $list;
}

#**********************************************************
=head2 take_service_info($attr) - list of services

  Arguments:
    $attr
      ID
      GROUP_ID

=cut
#**********************************************************
sub take_service_info {
  my $self = shift;
  my ($attr) = @_;

  if ($attr->{ID}) {
    $self->query2(
      "SELECT *
      FROM price_services_list
      WHERE id = ?;", undef, { INFO => 1, Bind => [ $attr->{ID} ] }
    );
  }
  if ($attr->{GROUP_ID}) {
    $self->query2(
      "SELECT *
      FROM price_services_list
      WHERE id_group = ?;", undef, { INFO => 1, Bind => [ $attr->{GROUP_ID} ] }
    );
  }

  return $self;
}

#**********************************************************
=head2 select_service_with_group($attr) - list of services

  Arguments:
    $attr
      ID

=cut
#**********************************************************
sub select_service_with_group {
  my $self = shift;
  my ($attr) = @_;

  $self->query2(
    "SELECT * FROM price_services_list WHERE id_group = ?;",
    undef,
    { COLS_NAME => 1, Bind => [ $attr->{ID} ] }
  );

  return $self->{list};
}

#**********************************************************
=head2 select_price_groups($attr) - list of groups

  Arguments:
    $attr
      ID

=cut
#**********************************************************
sub select_price_groups {
  my $self = shift;
  my ($attr) = @_;

  if ($attr->{ID}) {
    $self->query2(
      "SELECT *
      FROM price_groups
      WHERE id = ?;",
      undef,
      { INFO => 1, Bind => [ $attr->{ID} ] }
    );
  }
  else {
    $self->query2(
      "SELECT * FROM price_groups",
      undef,
      { COLS_NAME => 1 }
    );
  }

  return $self;
}

#**********************************************************
=head2 add_group($attr) - add group

  Arguments:
    $attr
      Name,
      Comment

=cut
#**********************************************************
sub add_group {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('price_groups', { %$attr });

  return $self;
}

#**********************************************************
=head2 change_group($attr) - change group

  Arguments:
    $attr
      ID

=cut
#**********************************************************
sub change_group {
  my $self = shift;
  my ($attr) = @_;

  $self->changes2(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'price_groups',
      DATA         => $attr
    }
  );
  return $self;
}

#**********************************************************
=head2 del_group($attr) - Delete group

  Arguments:
    $attr
      ID

=cut
#**********************************************************
sub del_group {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('price_groups', $attr);

  return $self;
}

=head2 add_form($attr) - add form

  Arguments:
    $attr
      ID

=cut
#**********************************************************
sub add_form {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('price_form', { %$attr });

  return $self;
}

#**********************************************************
=head2 select_price_form($attr) - list of groups

  Arguments:
    $attr
      LEAD_ID

=cut
#**********************************************************
sub select_price_form {
  my $self = shift;
  my ($attr) = @_;

  $self->query2(
    "SELECT *
      FROM price_form
      WHERE lead_id = ?;",
    undef,
    { COLS_NAME => 1,, Bind => [ $attr->{LEAD_ID} ] }
  );

  return $self->{list};
}

#**********************************************************
=head2 delete_price_form($attr) - delete groups

  Arguments:
    $attr
      ID

=cut
#**********************************************************
sub delete_price_form {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('price_form', {}, $attr);

  return $self;
}

#**********************************************************
=head2 select_lead_id($attr)

  Arguments:
    $attr
      E_MAIL

=cut
#**********************************************************
sub select_lead_id {
  my $self = shift;
  my ($attr) = @_;

  if ($attr->{E_MAIL}) {
    $self->query2(
      "SELECT lead_id
      FROM price_form
      WHERE key_ = E_MAIL and value = ?;",
      undef,
      { COLS_NAME => 1, Bind => [ $attr->{E_MAIL} ] }
    );
  }

  return $self->{list};
}
return 1;

