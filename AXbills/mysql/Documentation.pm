package Documentation;

=head1 NAME

  Documentation SQL

=cut
use strict;
use warnings FATAL => 'all';
use parent qw( dbcore );

#**********************************************************
=head2 new($db, $admin, $CONF)

  Arguments:
    $db    - ref to DB
    $admin - current Web session admin
    $CONF  - ref to %conf

  Returns:
    object

=cut
#**********************************************************
sub new{
  my $class = shift;
  my ($db, $admin, $CONF) = @_;

  my $self = { };
  bless( $self, $class );

  $self->{db} = $db;
  $self->{admin} = $admin;
  $self->{conf} = $CONF;

  return $self;
}


#**********************************************************
=head2 list($attr)

  Arguments:
    $attr - hash_ref

  Returns:

=cut
#**********************************************************
sub list{
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $WHERE = $self->search_former( $attr, [
    [ 'ID', 'INT', 'd.uid' ],
    [ 'WIKI', 'STR', 'd.wiki', ],
    [ 'CONFLUENCE', 'STR', 'd.confluence', ],
  ],
    {
      WHERE => 1
    }
  );

  $self->query(
    "SELECT
    id,
    $self->{SEARCH_FIELDS}
    FROM documentation d
    $WHERE ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;
     ",
    undef,
    $attr
  );

  return $self;
}


#**********************************************************
=head2 add($attr)

  Arguments:
    $attr - hash_ref

  Returns:

=cut
#**********************************************************
sub add{
  my $self = shift;
  my ($attr) = @_;

  return $self->query_add( 'documentation', $attr);
}



#**********************************************************
=head2 del($id)

  Arguments:


  Returns:

=cut
#**********************************************************
sub del{
  my $self = shift;
  my ($id) = @_;

  return $self->query_del( 'documentation', { UID => $id } );
}


#**********************************************************
=head2 change($attr)

  Arguments:


  Returns:

=cut
#**********************************************************
sub change{
  my $self = shift;
  my ($attr) = @_;

  return $self->changes( $attr );
}


1;