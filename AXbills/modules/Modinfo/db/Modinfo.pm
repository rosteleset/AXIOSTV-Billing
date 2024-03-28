package Modinfo;

use strict;
use warnings FATAL => 'all';

use parent qw(dbcore);

my $MODULE = 'Modinfo';
my Admins $admin;
my $CONF;

#*******************************************************************
=head2 new()
  Arguments:
    $db    - ref to DB
    $admin - current Web session admin
    $CONF  - ref to %conf
  Returns:
    object
=cut
#*******************************************************************
sub new {
    my $class = shift;
    my $db = shift;
    ($admin, $CONF) = @_;

    $admin->{MODULE} = $MODULE;

    my $self = {
        db    => $db,
        admin => $admin,
        conf  => $CONF
    };

    bless($self, $class);

    return $self;
}

#*******************************************************************

=head2 function rand_tip()
  Arguments:

  Returns:
    @list
=cut

#*******************************************************************
sub rand_tip {
    my $self = shift;

    $self->query(
        "SELECT tip from modinfo_tips ORDER BY RAND() LIMIT 1;",
        undef,
        undef
    );
    return [ ] if ($self->{errno});

    return $self->{list}[0][0];
}

1;