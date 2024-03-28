package Help;

=head1 NAME

  Help DB interface

=cut

use strict;
use parent qw(dbcore);
my $MODULE = 'Help';
my ($admin, $CONF);

#**********************************************************
# Init
#**********************************************************
sub new {
  my $class = shift;
  my $db    = shift;
  ($admin, $CONF) = @_;
  $admin->{MODULE} = $MODULE;
  my $self = {};
  bless($self, $class);

  $self->{db}=$db;

  return $self;
}

#**********************************************************
# User information
# info()
#**********************************************************
sub info {
  my $self = shift;
  my ($attr) = @_;

  $self->query("SELECT function, title, help
     FROM help
     WHERE function= ? ;",
     undef, 
     { INFO => 1,
     	 BInd =>  [ $attr->{FUNCTION} ] }
  );

  return $self;
}

#**********************************************************
# add()
#**********************************************************
sub add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('help', $attr);

  return $self;
}

#**********************************************************
# change()
#**********************************************************
sub change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'FUNCTION',
    TABLE        => 'help',
    DATA         => $attr
  });

  return $self->{result};
}

#**********************************************************
# Delete user info from all tables
#
# del(attr);
#**********************************************************
sub del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('help', undef, $attr);
  return $self->{result};
}

1
