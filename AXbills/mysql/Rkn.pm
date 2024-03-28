package Rkn;

=head1 NAME

  Accounts manage functions

=cut

use strict;
use parent 'main';
my $MODULE = 'Rkn';
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
# list()
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
      [ 'URL',       'STR',  'url',                      1 ],
      [ 'NAME',      'STR',  'name',                     1 ],
	  [ 'MASK',      'STR',  'mask',                     1 ],
      [ 'IP',        'IP',   'ip',   'INET_NTOA(ip) AS ip' ],
    ],
    {
      WHERE => 1,
    }
  );

  $self->query2("SELECT 
    $self->{SEARCH_FIELDS} m.id
    FROM rkn_main m
	LEFT JOIN rkn_ip ip ON ip.id=m.id
	LEFT JOIN rkn_domain dn ON dn.id=m.id
	LEFT JOIN rkn_url url ON url.id=m.id
	LEFT JOIN rkn_domain_mask dm ON url.id=m.id
    $WHERE
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );
  
  return [] if ($self->{errno});

  my $list = $self->{list};

  return $list;
}
#**********************************************************
# _list()
#**********************************************************
sub _list {
  my $self = shift;
  my ($attr) = @_;

  my $GROUP     = ($attr->{GROUP})     ? "GROUP BY $attr->{GROUP}"     : '';
  my $WHERE = $self->search_former( $attr, [
      [ 'URL',  'STR', 'url',                      1 ],
      [ 'NAME', 'STR', 'name',                     1 ],
      [ 'IP',   'IP',  'ip',   'INET_NTOA(ip) AS ip' ],
      [ 'SKIP', 'INT', 'skip',                     1 ],
    ],
    {
      WHERE => 1,
    }
  );
 
  $self->query2("SELECT 
    $self->{SEARCH_FIELDS}
	id
    FROM $attr->{TABLE}
    $WHERE
	$GROUP",
    undef,
    $attr
  );
  
  return [] if ($self->{errno});

  my $list = $self->{list};

  return $list;
}

#**********************************************************
# add()
#**********************************************************
sub add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('rkn_main', $attr, { REPLACE => 1 });

  return $self;
}

#**********************************************************
# add_ip()
#**********************************************************
sub add_ip {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('rkn_ip', $attr,);

  return $self;
}

#**********************************************************
# add_domain()
#**********************************************************
sub add_domain {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('rkn_domain', $attr);

  return $self;
}

#**********************************************************
# add_domain_mask()
#**********************************************************
sub add_domain_mask {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('rkn_domain_mask', $attr);

  return $self;
}

#**********************************************************
# add_url()
#**********************************************************
sub add_url {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('rkn_url', $attr);

  return $self;
}

#**********************************************************
# change()
#**********************************************************
sub change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes2(
    {
      CHANGE_PARAM => 'FUNCTION',
      TABLE        => 'rkn_blocklist',
      DATA         => $attr
    }
  );

  return $self->{result};
}

#**********************************************************
# Delete block records
#
# del(attr);
#**********************************************************
sub del {
  my $self = shift;
  my ($id) = @_;

  $self->query2("DELETE m.*, ip.*, dn.*, url.*  FROM rkn_main m 
                LEFT JOIN rkn_ip ip ON ip.id=m.id
				LEFT JOIN rkn_domain dn ON dn.id=m.id
				LEFT JOIN rkn_url url ON url.id=m.id
				WHERE m.id=$id;", 'do');
  return $self->{result};
}

1
