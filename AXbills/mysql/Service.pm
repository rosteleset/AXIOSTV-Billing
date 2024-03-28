package Service;

=head1 NAME

  User Service main functions

=cut

use strict;
our $VERSION = 2.00;
use parent qw(dbcore);

#**********************************************************
# Init
#**********************************************************
sub new {
  my $class = shift;

  my ($db, $admin, $CONF) = @_;

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $CONF,
  };

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 status_add($attr) - Create service status

=cut
#**********************************************************
sub status_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('service_status', $attr);

  return $self;
}

#**********************************************************
=head2 status_change($attr) -  Change service status

=cut
#**********************************************************
sub status_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'service_status',
    DATA         => $attr
  });

  return $self;
}

#**********************************************************
=head2 list($attr) - list service status

=cut
#**********************************************************
sub status_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = (defined($attr->{DESC})) ? $attr->{DESC} : 'DESC';

  my $WHERE = $self->search_former( $attr, [
    [ 'ID',       'INT', 'id',        1],
    [ 'NAME',     'STR', 'name',      1],
    [ 'COLOR',    'STR', 'color',     1],
    [ 'TYPE',     'INT', 'type',      1],
    [ 'GET_FEES', 'INT', 'get_fees',  1],
  ],
    { WHERE => 1, }
  );

  $self->query("SELECT $self->{SEARCH_FIELDS} id
     FROM service_status
     $WHERE
     GROUP BY 1
     ORDER BY $SORT $DESC;",
    undef,
    $attr
  );

  return $self->{list_hash} || {} if ($attr->{LIST2HASH});

  return $self->{list} || [];
}

#**********************************************************
=head2 status_del($attr) - Del service status

=cut
#**********************************************************
sub status_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('service_status', $attr);

  return $self;
}

#**********************************************************
=head2 status_info($attr) - service status info

  Arguments:
    $attr
      ID

  Returns:
    $self

=cut
#**********************************************************
sub status_info {
  my $self = shift;
  my ($attr) = @_;

  $self->query("SELECT * FROM service_status WHERE id= ? ;",
    undef,
    {
      INFO => 1,
      Bind => [ $attr->{ID} ]
    }
  );

  return $self;
}

1;
