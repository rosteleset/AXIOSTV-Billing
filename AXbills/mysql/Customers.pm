package Customers;

=head1 NAME

  Accounts manage functions

=cut

use strict;
use Companies;

#**********************************************************
# Init
#**********************************************************
sub new {
  my $class = shift;
  my ($db, $admin, $CONF) = @_;

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $CONF
  };

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2  company()

=cut
#**********************************************************
#@returns Companies
sub company {
  my $self = shift;

  my $Companies = Companies->new($self->{db}, $self->{admin}, $self->{conf});

  return $Companies;
}

1
