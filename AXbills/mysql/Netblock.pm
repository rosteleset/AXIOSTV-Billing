package Netblock;

=head1 NAME

  Netblock manage functions

=cut

use strict;
use parent qw(dbcore);
my $MODULE = 'Netblock';
my ($admin, $CONF);

my $SORT      = 1;
my $DESC      = '';
my $PG        = 0;
my $PAGE_ROWS = 25;

#**********************************************************
# Init
#**********************************************************
sub new {
  my $class = shift;
  my $db    = shift;
  ($admin, $CONF) = @_;
  $admin->{MODULE} = $MODULE;
  my $self = {
    db          => $db,
    admin       => $admin,
    conf        => $CONF,
  };
  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 list($attr)

=cut
#**********************************************************
sub list {
  my $self = shift;
  my ($attr) = @_;

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 1000000;
  
  my $WHERE = $self->search_former( $attr, [
      [ 'ID',        'INT',  'm.id',                     1 ],
      [ 'BLOCKTYPE', 'STR',  'blocktype',                1 ],
      [ 'HASH',      'STR',  'hash',                     1 ],
      [ 'INCTIME',   'DATE', 'inctime',                  1 ],
      [ 'DBTIME',    'DATE', 'dbtime',                   1 ],
      [ 'URL',       'STR',  'url',                      1 ],
      #[ 'NAME',      'STR',  'name',                     1 ],
      [ 'MASK',      'STR',  'mask',                     1 ],
      #[ 'IP',        'IP',   'm.ip',   'INET_NTOA(m.ip) AS ip' ],
    ],
    {
      WHERE => 1,
    }
  );

  my $JOIN = ($attr->{IP})? 'LEFT JOIN netblock_ip ip ON ip.id=m.id ':'';
  $JOIN .= ($attr->{URL})? 'LEFT JOIN netblock_url url ON url.id=m.id ':'';
  $JOIN .= ($attr->{NAME})? 'LEFT JOIN netblock_domain dn ON dn.id=m.id ':'';
  $JOIN .= ($attr->{MASK})? 'LEFT JOIN netblock_domain_mask dm ON url.id=m.id ':'';
  
  $self->query("SELECT
    $self->{SEARCH_FIELDS} m.id
  FROM netblock_main m
  $JOIN
  $WHERE
  ORDER BY $SORT $DESC
  LIMIT $PG, $PAGE_ROWS;",
  undef,
  $attr
  );
  
  return [] if ($self->{errno});

  my $list = $self->{list};
  if ($self->{TOTAL} > 0) {
    $self->query("SELECT COUNT(id) AS total
    FROM netblock_main m
    $WHERE;", undef, { INFO => 1 }
    );
  }
  return $list;
}

#**********************************************************
=head2 _list($attr)

  Arguments:
    $attr
      TABLE

=cut
#**********************************************************
sub _list {
  my $self = shift;
  my ($attr) = @_;

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 1000000;

  my $GROUP     = ($attr->{GROUP})     ? "GROUP BY $attr->{GROUP}"     : '';

  my $WHERE = $self->search_former( $attr, [
      [ 'ID',        'INT',  'id',                       1 ],
      [ 'BLOCKTYPE', 'STR',  'blocktype',                1 ],
      [ 'HASH',      'STR',  'hash',                     1 ],
      [ 'INCTIME',   'DATE', 'inctime',                  1 ],
      [ 'DBTIME',    'DATE', 'dbtime',                   1 ],
      [ 'URL',       'STR',  'url',                      1 ],
      [ 'MASK',      'STR',  'mask',                     1 ],
      [ 'SSL',       'STR',  'ssl_name',                 1 ],
      [ 'PORTS',     'STR',  'ports',                    1 ],
      [ 'NAME',      'STR',  'name',                     1 ],
      [ 'IP',        'IP',   'ip',   'INET_NTOA(ip) AS ip' ],
      [ 'SKIP',      'INT',  'skip',                     1 ],
    ],
    {
      WHERE => 1,
    }
  );
 
  $self->query("SELECT
    $self->{SEARCH_FIELDS}
    id
    FROM $attr->{TABLE}
    $WHERE $GROUP
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );
  
  return [] if ($self->{errno});

  my $list = $self->{list};
  if ($self->{TOTAL} > 0) {
    $self->query("SELECT COUNT(id) AS total
    FROM $attr->{TABLE}
    $WHERE;", undef, { INFO => 1 }
    );
  }

  return $list;
}

#**********************************************************
=head2 add($attr)

=cut
#**********************************************************
sub add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('netblock_main',
    { %$attr,
      INCTIME => 'NOW()',
      DBTIME => 'NOW()'
      },
    { REPLACE => 1 });

  return $self;
}

#**********************************************************
=head2 add_ip($attr)

=cut
#**********************************************************
sub add_ip {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('netblock_ip', $attr,);

  return $self;
}

#**********************************************************
=head2 add_domain($attr)

=cut
#**********************************************************
sub add_domain {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('netblock_domain', $attr);

  return $self;
}

#**********************************************************
# add_domain_mask()
#**********************************************************
sub add_domain_mask {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('netblock_domain_mask', $attr);

  return $self;
}

#**********************************************************
=head2 add_url($attr)

=cut
#**********************************************************
sub add_url {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('netblock_url', $attr);

  return $self;
}

#**********************************************************
=head2 add_ssl($attr)

=cut
#**********************************************************
sub add_ssl {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('netblock_ssl', $attr);

  return $self;
}

#**********************************************************
=head2 add_ports($attr)

=cut
#**********************************************************
sub add_ports {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('netblock_ports', $attr);

  return $self;
}

#**********************************************************
=head2 change_blocklist($attr)

=cut
#**********************************************************
sub change_blocklist {
  my $self = shift;
  my ($attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'FUNCTION',
    TABLE        => 'netblock_blocklist',
    DATA         => $attr
  });

  return $self->{result};
}

#**********************************************************
=head2 change_blocklist($attr)

=cut
#**********************************************************
sub change {
  my $self = shift;
  my ($attr) = @_;
  my $table = $attr->{TABLE} || 'netblock_main';

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => $table,
    DATA         => $attr
  });

  return $self->{result};
}

#**********************************************************
=head2 info($attr)

=cut
#**********************************************************
sub info {
  my $self = shift;
  my ($attr) = @_;

  $self->query("SELECT *
     FROM netblock_main
     WHERE id= ? ;",
    undef,
    { INFO => 1,
      Bind => [ $attr->{ID} ]
    });

  return $self;
}

#**********************************************************
=head2 del(attr) - Delete block records

=cut
#**********************************************************
sub del {
  my $self = shift;
  my ($attr) = @_;
  my $table = $attr->{TABLE} || 'netblock_main';

  $self->query_del($table, { ID => $attr->{ID} });
  
  return $self->{result};
}

#**********************************************************
=head2 init(attr); Delete block records

=cut
#**********************************************************
sub init {
  my $self = shift;
 # $self->query_del('netblock_main');
  $self->query( "DELETE FROM `netblock_main`",'do');
  
  return $self->{result};
}

1
