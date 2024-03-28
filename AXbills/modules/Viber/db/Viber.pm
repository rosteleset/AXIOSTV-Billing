package Viber;

=head1 NAME

 viber_bot sql functions

=cut

use strict;
use parent 'dbcore';
my $MODULE = 'Viber';

#**********************************************************
=head2 new($db, $admin, \%conf)

=cut
#**********************************************************
sub new {
  my $class = shift;
  my ($db, $admin, $conf) = @_;

  $admin->{MODULE} = $MODULE;
  
  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $conf
  };
  
  bless($self, $class);
  
  return $self;
}

#**********************************************************
=head2 info($uid)

=cut
#**********************************************************
sub info {
  my $self = shift;
  my ($uid) = @_;

  $self->query("SELECT * FROM viber_tmp WHERE uid = ?;",
    undef,
    { Bind => [ $uid ], COLS_NAME => 1, COLS_UPPER => 1}
  );

  return [] if ($self->{errno});

  return $self->{list}->[0];
}

#**********************************************************
=head2 add($attr)

=cut
#**********************************************************
sub add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('viber_tmp', $attr);

  return $self;
}

#**********************************************************
=head2 change($attr)

=cut
#**********************************************************
sub change {
  my $self = shift;
  my ($attr) = @_;
  
  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'viber_tmp',
    DATA         => $attr,
  });

  return $self;
}

#**********************************************************
=head2 del($uid)

=cut
#**********************************************************
sub del {
  my $self = shift;
  my ($uid) = @_;

  $self->query_del("viber_tmp", {}, { UID => $uid });

  return $self;
}

#**********************************************************
=head2 truncate()

=cut
#**********************************************************
sub truncate {
  my $self = shift;

  $self->query_del("viber_tmp", {}, {}, {CLEAR_TABLE => 1});

  return 1;
}

1;
