package Revisor;

=head1 NAME

 Revisor pm

=cut

use strict;
use parent 'dbcore';
my $MODULE = 'Revisor';

my Admins $admin;
my $CONF;

#**********************************************************

=head2 new($db, $admin, \%conf) - constructor for Revisor DB manage module

=cut

#**********************************************************
sub new {
  my $class = shift;
  my $db = shift;
  ($admin, $CONF) = @_;
  
  $admin->{MODULE} = $MODULE;
  
  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $CONF
  };
  
  bless($self, $class);
  
  return $self;
}

#**********************************************************
=head2 users_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut
#**********************************************************
sub user_list {
  my ($self, $attr) = @_;
  
  my $PG   = $attr->{PG} || '0';
  my $PAGE_ROWS = $attr->{PAGE_ROWS} || 25;
  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  
  my $WHERE = $self->search_former($attr, [],
    {
      WHERE             => 1,
      USERS_FIELDS      => 1,
      USE_USER_PI       => 1,
      SKIP_USERS_FIELDS => [ 'UID' ]
    }
  );
  
  my $EXT_TABLES = $self->{EXT_TABLES} || q{};

  $self->query(
    "SELECT $self->{SEARCH_FIELDS} u.uid
   FROM users u
   $EXT_TABLES
   $WHERE
   ORDER BY $SORT $DESC
   LIMIT $PG, $PAGE_ROWS;",
    undef,
    {
      COLS_NAME => 1,
      %{ $attr // { } }
    }
  );
  
  return [ ] if ($self->{errno});
  
  my $list = $self->{list};
  
   if ( $self->{TOTAL} >= 0 ) {
    $self->query("SELECT COUNT(u.uid) AS total FROM users u $EXT_TABLES $WHERE", undef, { INFO => 1 });
  }
  
  return $list;
}

#**********************************************************
=head2 revisor_dv_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut
#**********************************************************
sub revisor_dv_list {
  my ($self, $attr) = @_;
  
  my $SORT = $attr->{SORT} || '1';
  my $DESC = ($attr->{DESC}) ? '' : 'DESC';
  my $PG   = $attr->{PG} || '0';
  my $PAGE_ROWS = $attr->{PAGE_ROWS} || 25;
  
  my $search_columns = [
      ['IP_NUM',         'IP',  'dv.ip',     'INET_NTOA(dv.ip) AS ip_num'        ],
      ['NETMASK',        'IP',  'dv.netmask', 'INET_NTOA(dv.netmask) AS netmask' ],
      ['CID',            'STR', 'dv.cid',                                      1 ],
      ['UID',            'INT', 'dv.uid',                                      1 ],
  ];
  
  my $WHERE = $self->search_former(
    $attr,
    $search_columns,
    {
      WHERE             => 1,
    }
  );
  
  
  $self->query(
    "SELECT $self->{SEARCH_FIELDS} dv.uid
    FROM dv_main dv
    $WHERE
    ORDER BY $SORT $DESC",
    undef,
    {
      COLS_NAME => 1,
      %{ $attr // { } }
    }
  );
  
  return [ ] if ($self->{errno});
  
  return $self->{list};
}

#**********************************************************
=head2 revisor_internet_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut
#**********************************************************
sub revisor_internet_list {
  my ($self, $attr) = @_;
  
  my $SORT = $attr->{SORT} || '1';
  my $DESC = ($attr->{DESC}) ? '' : 'DESC';
  my $PG   = $attr->{PG} || '0';
  my $PAGE_ROWS = $attr->{PAGE_ROWS} || 25;
  
  my $search_columns = [
      ['IP_NUM',         'IP',  'in.ip',     'INET_NTOA(dv.ip) AS ip_num'        ],
      ['NETMASK',        'IP',  'in.netmask', 'INET_NTOA(dv.netmask) AS netmask' ],
      ['CID',            'STR', 'in.cid',                                      1 ],
      ['UID',            'INT', 'in.uid',                                      1 ],
  ];
  
  my $WHERE = $self->search_former(
    $attr,
    $search_columns,
    {
      WHERE             => 1,
    }
  );
  
  
  $self->query(
    "SELECT $self->{SEARCH_FIELDS} in.uid
    FROM internet_main in
    $WHERE
    ORDER BY $SORT $DESC",
    undef,
    {
      COLS_NAME => 1,
      %{ $attr // { } }
    }
  );
  
  return [ ] if ($self->{errno});
  
  return $self->{list};
}

1