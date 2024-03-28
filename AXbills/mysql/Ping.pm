package Ping;

=head1 NAME

  Ping plugins diagnostic user internet conection

=cut

use strict;
use parent qw(dbcore);

my $admin;
my $CONF;

#**********************************************************
# Init
#**********************************************************
sub new {
  my $class = shift;
  my $db    = shift;
  ($admin, $CONF) = @_;

  my $self = {
    db    => $db,
    conf  => $CONF,
    admin => $admin
  };
  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 add() - Add ping info

=cut
#**********************************************************
sub add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('ping_actions',
    {
      %$attr,
      DATETIME    => 'now()'
    }
  );
  $self->{ID} = $self->{INSERT_ID};

  return $self;
}

#**********************************************************
=head2 list($attr)

=cut
#**********************************************************
sub list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  my $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;
  my @WHERE_RULES = ();

  if ($attr->{FROM_DATE} && $attr->{TO_DATE}) {
    push @WHERE_RULES, "datetime BETWEEN '$attr->{FROM_DATE}' AND '$attr->{TO_DATE}'";
  }
  my $search_columns = [
    ['ID',               'INT',  'pa.id',                              1],
    ['LOGIN',            'STR',  'u.id AS login',                      1],
    ['LOSS_RATE',        'INT',  'pa.loss_rate',                       1],
    ['TRANSMITTED',      'INT',  'pa.transmitted',                     1],
    ['RACAIVED',         'INT',  'pa.racaived',                        1],
    ['AVG_TIME',         'INT',  'pa.avg_time',                        1],
    ['UID',              'INT',  'pa.uid',                             1],
    ['DATETIME',         'DATE', 'pa.datetime',                        1],
    ['TAGS',             'INT',  'tu.tag_id AS tags',                  1],
    ['GID',              'INT',  'u.gid',                              1],
    ['ADDRESS_STREET',   'STR',  'up.address_street',                  1],
    ['ADDRESS_BUILD',    'STR',  'up.address_build',                   1],
    ['ADDRESS_FLAT',     'STR',  'up.address_flat',                    1],
    ['ADDRESS_DISTRICT', 'INT',  'up.location_id AS address_district', 1],
  ];

  if ($attr->{SHOW_ALL_COLUMNS}) {
    map { $attr->{ $_->[0] } = '_SHOW' unless (exists $attr->{ $_->[0] }) } @{$search_columns};
  }

  my $WHERE = $self->search_former($attr, $search_columns,
    {
      WHERE => 1,
      WHERE_RULES => \@WHERE_RULES,

    }
  );

  $self->query("SELECT  $self->{SEARCH_FIELDS} pa.uid
        FROM ping_actions pa
          LEFT JOIN users u ON(u.uid=pa.uid)
          LEFT JOIN tags_users tu ON(tu.uid=pa.uid)
          LEFT JOIN users_pi up ON(up.uid=pa.uid)
        $WHERE
        GROUP BY pa.id
        ORDER BY $SORT $DESC
        LIMIT $PG, $PAGE_ROWS;",
    undef,
    {
      COLS_NAME => 1,
      %{ $attr ? $attr : {} }
    }
  );

  return [ ] if ($self->{errno});

  my $list = $self->{list};

  if ($self->{TOTAL} >= $attr->{PAGE_ROWS} || $PG > 0) {
    $self->query("SELECT COUNT(*) AS total FROM ping_actions pa $WHERE",
      undef, { INFO => 1 });
  }

  return $list;
}

#**********************************************************
=head2 list($uid)
  Arguments:
    $uid
  Returns:
    $self
  Examples:
    $Ping->info($uid);
=cut
#**********************************************************
sub info {
  my $self = shift;
  my ($uid) = @_;

  $self->query("SELECT * FROM ping_actions WHERE uid = ? ",
    undef,
    {
      INFO => 1,
      Bind => [ $uid ],
    }
  );

  return $self;
}

1