package Billd;

=head1 NAME

  Billd plugins managment

=cut

use strict;
use parent qw(dbcore);

my $admin;
my $CONF;
my $SORT  = 1;
my $DESC  = '';

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
=head2 add($attr) - Create bill account

=cut
#**********************************************************
sub add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('billd_plugins', $attr);

  return $self;
}

#**********************************************************
=head2 change($attr) -  Change bill account

=cut
#**********************************************************
sub change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'billd_plugins',
      DATA         => $attr,
      SKIP_LOG     => 1
    }
  );

  return $self;
}

#**********************************************************
=head2 list($attr) - list billd plugins

=cut
#**********************************************************
sub list {
  my $self = shift;
  my ($attr) = @_;

  my $WHERE = $self->search_former($attr, [
      ['PLUGIN_NAME',     'STR',  'plugin_name', 1 ],
      ['LAST_EXECUTE',    'DATE', 'last_execute',1 ],
      ['EXECUTE_TIME',    'DATE', '',  'TIMEDIFF(last_end, last_execute) AS execute_time' ],
      ['PERIOD',          'INT',  'period',      1 ],
      ['STATUS',          'INT',  'status',      1 ],
      ['PRIORITY',        'INT',  'priority',    1 ],
      ['THREADS',         'INT',  'threads',     1 ],
      ['MAKE_LOCK',       'INT',  'make_lock',   1 ],
      ['ID',              'INT',  'id',          1 ],
    ],
    { WHERE => 1,  }
    );

  $self->query("SELECT $self->{SEARCH_FIELDS} id
     FROM billd_plugins
     $WHERE 
     GROUP BY 1
     ORDER BY $SORT $DESC;",
     undef,
     $attr
  );

  return $self->{list};
}

#**********************************************************
=head2 del($attr) - Dell billd plugin

=cut
#**********************************************************
sub del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('billd_plugins', $attr);
  return $self;
}

#**********************************************************
=head2 info($attr) - billd plugin information

  Arguments:
    $attr
      ID

  Returns:
    $self

=cut
#**********************************************************
sub info {
  my $self = shift;
  my ($attr) = @_;

  $self->query("SELECT * FROM billd_plugins WHERE id= ? ;",
    undef,
    { INFO => 1,
    	Bind => [ $attr->{ID} ] }
  );

  return $self;
}

1
