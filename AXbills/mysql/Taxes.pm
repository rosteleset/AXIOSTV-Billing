package Taxes;

=head2

  Taxes

=cut

use strict;
use parent 'dbcore';
my $MODULE = 'Taxes';

#**********************************************************
# Init
#**********************************************************
sub new {
  my $class = shift;
  my ($db, $admin, $CONF) = @_;

  my $self = {};
  bless($self, $class);

  $admin->{MODULE} = $MODULE;
  $self->{db}      = $db;
  $self->{admin}   = $admin;
  $self->{conf}    = $CONF;

  return $self;
}

#**********************************************************
=head2 add_tax()

=cut
#**********************************************************
sub add_tax {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('taxes', $attr);

  return $self;
}

#**********************************************************
=head2  del_tax() 

=cut
#**********************************************************
sub del_tax {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('taxes', undef, $attr);

  return $self->{result};
}

#**********************************************************
=head2 taxes_list ($attr) - taxes_list

=cut
#**********************************************************
sub taxes_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  #my $PG        = ($attr->{PG})        ? $attr->{PG}             : 0;
  #my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? int($attr->{PAGE_ROWS}) : 25;

  my $WHERE = $self->search_former($attr, [ 
    [ 'ID',         'INT', 'id',         1 ], 
    [ 'RATECODE',   'STR', 'ratecode',   1 ], 
    [ 'RATEDESCR',  'STR', 'ratedescr',  1 ], 
    [ 'RATEAMOUNT', 'INT', 'rateamount', 1 ], 
    [ 'CURRENT',    'INT', 'current',    1 ], ], 
    { WHERE => 1, });

  $self->query(
    "SELECT id, ratecode, ratedescr, rateamount, current
     FROM taxes
     $WHERE;",
    undef,
    { COLS_NAME => 1, %$attr }
  );

  return $self->{list};
}

#**********************************************************
=head2 change_tax($attr)

=cut
#**********************************************************
sub change_tax {
  my $self = shift;
  my ($attr) = @_;

  $self->changes(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'taxes',
      DATA         => $attr,
    }
  );

  return $self->{result};
}