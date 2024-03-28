package Dunes;

=head1 NAME

  Dunes DB

=cut

use strict;
use parent qw(dbcore);

my ($admin, $CONF);

#**********************************************************
# Init 
#**********************************************************
sub new{
  my $class = shift;
  my $db = shift;
  ($admin, $CONF) = @_;

  my $self = { };
  bless( $self, $class );

  $self->{db} = $db;
  $self->{admin} = $admin;
  $self->{conf} = $CONF;

  return $self;
}


#**********************************************************
# User information
# info()
#**********************************************************
sub info{
  my $self = shift;
  my ($id) = @_;

  $self->query( "SELECT *
     FROM dunes WHERE err_id= ?;", undef,
    { INFO => 1,
      Bind => [ $id ] } );

  return $self;
}

#**********************************************************
# list()
#**********************************************************
sub list{
  my $self = shift;
  my ($attr) = @_;

  my @WHERE_RULES = ();
  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  if ( $attr->{ID} ){
    push @WHERE_RULES, "err_id='$attr->{ID}'";
  }

  my $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join( ' and ', @WHERE_RULES ) : '';

  $self->query( "SELECT err_id, win_err_handle, translate, error_text, solution
     FROM dunes
     $WHERE
     ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;", undef, { COLS_NAME => 1 } );

  return [ ] if ($self->{errno});

  my $list = $self->{list};

  if ( $self->{TOTAL} >= 0 ){
    $self->query( "SELECT count(*) AS total FROM dunes $WHERE", undef, { INFO => 1 } );
  }

  return $list;
}


1
