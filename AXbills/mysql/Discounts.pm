=head1 NAME

  Discounts - module for discounts

=head1 SYNOPSIS

  use Discounts;
  my $Discounts = Discounts->new($db, $admin, \%conf);

=cut

package Discounts;

use strict;
use parent qw(dbcore);

my ($admin, $CONF);

#*******************************************************************
=head2 function new()

=cut
#*******************************************************************
sub new {
  my $class = shift;
  my $db = shift;
  ($admin, $CONF) = @_;

  my $self = {};
  bless($self, $class);

  $self->{db} = $db;
  $self->{admin} = $admin;
  $self->{conf} = $CONF;

  return $self;
}

#**********************************************************
=head2 add_status() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub add_status {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('discounts_status', { %$attr });

  return $self;
}

#**********************************************************

=head2 discount_status_list() -


=cut
#**********************************************************
sub discount_status_list {
	my $self = shift;
	my ($attr) = @_;
	
	my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
	my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

	$self->query("SELECT id, stat_title FROM discounts_status ORDER BY $SORT $DESC;",
	undef,
	$attr);
   
   return $self->{list};
}

#*******************************************************************
=head2 function change_status() - change discount's status in datebase

  Arguments:
    $attr

  Returns:
    $self object

  Examples:
    $Discounts->change_status({
      ID     => 1,
      SIZE   => 10,
      NAME   => 'TEST'
    });


=cut

#*******************************************************************
sub change_status {
  my $self = shift;
  my ($attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'discounts_status',
    DATA         => $attr
  });

  return $self;
}

#*******************************************************************
=head2 function delete_status() - delete status

  Arguments:
    $attr

  Returns:

  Examples:
    $Discounts->delete_status( {ID => 1} );

=cut

#*******************************************************************
sub delete_status {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('discounts_status', $attr);

  return $self;
}

#*******************************************************************

=head2 function info_status() - get information about status

  Arguments:
    $attr

  Returns:
    $self object

  Examples:
    my $disc_info = $Discounts->info_discount({ ID => 1 });

=cut

#*******************************************************************
sub info_status {
  my $self = shift;
  my ($attr) = @_;

  $self->query("SELECT * FROM discounts_status
      WHERE id = ?;", undef, { INFO => 1, Bind => [ $attr->{ID} ] }
  );

  return $self;
}

#*******************************************************************
=head2 function list_status() - get list of all discounts statuses

  Arguments:
    $attr

  Returns:
    @list

  Examples:
    my @list = $Discounts->list_status({ COLS_NAME => 1});

=cut

#*******************************************************************
sub list_status {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

	$self->query(
		"SELECT * FROM discounts_status ds
		ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
		undef,
		$attr
		);
		
  my $list = $self->{list};

  return $self->{list} if ($self->{TOTAL} < 1);

  $self->query("SELECT COUNT(*) AS total
		FROM discounts_status ds",
		undef,
		{ INFO => 1 }
	);

  return $list;
}

#**********************************************************
=head2 add_discount() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub add_discount {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('discounts_discounts', { %$attr });

  return $self;
}

#*******************************************************************
=head2 function list_discount() - get list of all discounts

  Arguments:
    $attr

  Returns:
    @list

  Examples:
    my @list = $Discounts->list_discount({ COLS_NAME => 1});

=cut

#*******************************************************************
sub list_discount {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

    my $WHERE = $self->search_former($attr, [
    [ 'STAT_ID',	'INT', 'ds.id',        1 ],
  ], { WHERE => 1 });

  $self->query(
	"SELECT dd.id, dd.name, dd.size, dd.description,dd.logo, dd.promocode, dd.url, dd.disc_stat, ds.stat_title, ds.color
	FROM discounts_discounts dd
	$WHERE
    JOIN discounts_status ds on dd.disc_stat = ds.id
    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list};

  return $self->{list} if ($self->{TOTAL} < 1);

  $self->query("SELECT COUNT(*) AS total
   FROM discounts_discounts dd
   JOIN discounts_status ds on dd.disc_stat = ds.id
   $WHERE ",
    undef,
    { INFO => 1 }
  );

  return $list;
}

#*******************************************************************
=head2 function info_discount() - get information about discount

  Arguments:
    $attr

  Returns:
    $self object

  Examples:
    my $disc_info = $Discounts->info_discount({ ID => 1 });

=cut

#*******************************************************************
sub info_discount {
  my $self = shift;
  my ($attr) = @_;

  $self->query("SELECT * FROM discounts_discounts
      WHERE id = ?;", undef, { INFO => 1, Bind => [ $attr->{ID} ] }
  );

  return $self;
}

#*******************************************************************
=head2 function change_discount() - change discount's information in datebase

  Arguments:
    $attr

  Returns:
    $self object

  Examples:
    $Discounts->change_discount({
      ID     => 1,
      SIZE   => 10,
      NAME   => 'TEST'
    });


=cut

#*******************************************************************
sub change_discount {
  my $self = shift;
  my ($attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'discounts_discounts',
    DATA         => $attr
  });

  return $self;
}

#*******************************************************************
=head2 function delete_discount() - delete discount

  Arguments:
    $attr

  Returns:

  Examples:
    $Discounts->delete_discount( {ID => 1} );

=cut

#*******************************************************************
sub delete_discount {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('discounts_discounts', $attr);

  return $self;
}


#**********************************************************
=head2 user_discounts() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub user_discounts_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  $self->query("SELECT dd.name,
       dd.size,
       dd.description,
       dd.id,
       dd.logo,
       dd.promocode,
       dd.url
     FROM discounts_discounts dd
     GROUP BY dd.id
     ORDER BY $SORT $DESC
     LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list};

  return $list;
  
}

#**********************************************************
=head2 discounts_user_list_web($attr)

  Arguments:
     UID - User ID

  Returns:

=cut
#**********************************************************
sub discounts_user_list_web {
  my $self = shift;
  my ($attr) = @_;

  $self->query("SELECT dd.name,
       dd.size,
       dd.description,
       dd.id,
       dd.logo,
       dd.promocode,
       dd.url
     FROM discounts_discounts dd
     WHERE dd.disc_stat <= 1
     GROUP BY dd.id",
    undef, { COLS_NAME => 1 });

  my $list = $self->{list};

  return $list;
}

#**********************************************************
=head2 discounts_user_query($attr)

  Arguments:
     UID - User ID

  Returns:

=cut
#**********************************************************
sub discounts_user_query {
  my $self = shift;
  my ($attr) = @_;

  $self->query("SELECT fio FROM users_pi WHERE uid = $attr->{UID}",
    undef, { COLS_NAME => 1 });

  return $self;
}

1