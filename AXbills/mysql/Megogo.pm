
=head1 NAME

  Megogo - module for Megogo service

=head1 SYNOPSIS

  use Megogo;
  my $Megogo = Megogo->new($db, $admin, \%conf);

=cut

package Megogo;

use strict;
use parent qw(main);

my ($admin, $CONF);

#*******************************************************************
#  Инициализация обьекта
#*******************************************************************
sub new {
  my $class = shift;
  my $db    = shift;
  ($admin, $CONF) = @_;

  my $self = {};
  bless($self, $class);

  $self->{db}    = $db;
  $self->{admin} = $admin;
  $self->{conf}  = $CONF;

  return $self;
}

#*******************************************************************

=head2 function add_tp() - add TP's information to datebase

  Arguments:
    $attr

  Returns:
    $self object

  Examples:
    $Megogo->add_tp({
      NAME   => test,
      AMOUNT => 10,
    });
    $Megogo->add_tp({
      %FORM
    });

=cut

#*******************************************************************
sub add_tp {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('megogo_tp', {%$attr});

  return $self;
}

#*******************************************************************

=head2 function del_tp() - delete TP's information from datebase

  Arguments:
    $attr

  Returns:

  Examples:
    $Megogo->del_tp( {ID => 1} );

=cut

#*******************************************************************
sub del_tp {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('megogo_tp', $attr);

  return $self;
}

#*******************************************************************

=head2 function change_tp() - change TP's information in datebase

  Arguments:
    $attr

  Returns:
    $self object

  Examples:
    $Megogo->change_tp({
      ID     => 1,
      AMOUNT => 10,
    });
    $Megogo->change_tp({
      %FORM
    });

=cut

#*******************************************************************
sub change_tp {
  my $self = shift;
  my ($attr) = @_;

  $self->changes2(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'megogo_tp',
      DATA         => $attr
    }
  );

  return $self;
}

#*******************************************************************

=head2 function tp_list() - get list of all TP in database

  Arguments:
    $attr

  Returns:
    @list

  Examples:
    my @list = $Megogo->tp_list({ COLS_NAME => 1});

=cut

#*******************************************************************
sub list_tp {
  my $self = shift;
  my ($attr) = @_;

  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  my $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  $self->query2(
    "SELECT * FROM megogo_tp
    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list};

  return $self->{list} if ($self->{TOTAL} < 1);

  $self->query2(
    "SELECT count(*) AS total
   FROM megogo_tp",
    undef,
    { INFO => 1 }
  );

  return $list;
}

#*******************************************************************

=head2 function select_tp() - get information for one TP by name or any other attribute

  Arguments:
    $attr
      TP    - TP's name;
      TP_ID - TP's identifier;

  Returns:
    $self object

  Examples:
    my $tp_info = $Megogo->select_tp({ TP => test });
    my $tp_info = $Megogo->select_tp({ TP_ID => 1 });
=cut

#*******************************************************************
sub select_tp {
  my $self = shift;
  my ($attr) = @_;

  if ($attr->{TP}) {
    $self->query2(
      "SELECT * FROM megogo_tp
      WHERE name = ?;", undef, { INFO => 1, Bind => [ $attr->{TP} ] }
    );
  }

  if ($attr->{TP_ID}) {
    $self->query2(
      "SELECT * FROM megogo_tp
      WHERE id = ?;", undef, { INFO => 1, Bind => [ $attr->{TP_ID} ] }
    );
  }

  return $self;
}



#**********************************************************
=head2 add_user($attr) - add user subscribes

  Arguments:


  Returns:

=cut
#**********************************************************
sub add_user {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('megogo_users', {SUBSCRIBE_DATE => 'NOW()', %$attr});

  return $self;
}

#**********************************************************
=head2 list_user($attr)

  Arguments:
    $attr
      UID        - user's id
      ADDITIONAL - check if TP primary

  Returns:

  Example:
    my $user_primary_tarif = $Megogo->list_user({ COLS_NAME => 1, UID => $user->{UID}, ADDITIONAL => 0 });
=cut
#**********************************************************
sub list_user {
  my $self = shift;
  my ($attr) = @_;

  my @WHERE_RULES = ();
  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  my $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  if (defined($attr->{UID})) {
    push @WHERE_RULES, "mu.uid = '$attr->{UID}'";
  }

  if (defined($attr->{TP_ID})) {
    push @WHERE_RULES, "mu.tp_id = '$attr->{TP_ID}'";
  }

  if (defined($attr->{ADDITIONAL})) {
    push @WHERE_RULES, "mt.additional = '$attr->{ADDITIONAL}'";
  }

  my $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

  $self->query2(
    "SELECT
    mu.uid,
    mu.tp_id,
    mu.next_tp_id,
    mu.subscribe_date,
    mu.expiry_date,
    mu.suspend,
    mu.active,
    mt.amount,
    mt.additional,
    mt.name
    FROM megogo_users as mu
    LEFT JOIN megogo_tp mt ON mt.id = mu.tp_id
    $WHERE
    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list};

  return $self->{list} if ($self->{TOTAL} < 1);

  $self->query2(
    "SELECT count(*) AS total
   FROM megogo_users",
    undef,
    { INFO => 1 }
  );

  return $list;

}

#**********************************************************
=head2 select_user($attr) - get info about user by UID & TP_ID

  Arguments:
    UID   - user's id
    TP_ID - tp's id


  Returns:
    $self

  Example:
    my $check_active_tp = $Megogo->select_user({ COLS_NAME => 1, UID => $user->{UID}, TP_ID => $tp->{id} });

=cut
#**********************************************************
sub select_user {
  my $self = shift;
  my ($attr) = @_;

  $self->query2(
    "SELECT
    mu.uid,
    mu.tp_id,
    mu.next_tp_id,
    mu.subscribe_date,
    mu.expiry_date,
    mu.suspend,
    mu.active,
    mt.amount,
    mt.additional
    FROM megogo_users as mu
    LEFT JOIN megogo_tp mt ON mt.id = mu.tp_id
      WHERE uid = $attr->{UID} and tp_id = $attr->{TP_ID};", undef, { COLS_NAME => 1 }
    );

  return $self;
}

#*******************************************************************
#
#*******************************************************************
sub select_user_full {
  my $self = shift;
  my ($attr) = @_;

  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  my $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  $self->query2(
    "SELECT * FROM megogo_users
    WHERE uid = $attr->{UID}
    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr,
    { INFO => 1 }
  );

  my $list = $self->{list};

  return $self->{list} if ($self->{TOTAL} < 1);

  $self->query2(
    "SELECT count(*) AS total
   FROM megogo_users WHERE uid = $attr->{UID}",
    undef,
    { INFO => 1 }
  );

  return $list;
}

#*******************************************************************

=head2 function delete_user() - delete user's information from datebase

  Arguments:
    $attr
      UID - user's UID;

  Returns:
    $self object
  Examples:
    $Megogo->delete_user( {UID => 1, TP_ID => 2} );

=cut

#*******************************************************************
sub delete_user {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('megogo_users', $attr, { uid => $attr->{UID}, tp_id => $attr->{TP_ID} });

  return $self;
}

#*******************************************************************

=head2 function change_user() - change user's information by TP_ID

  Arguments:
    UID     - user's id
    TP_ID   - tp's id

  Returns:
    $self object

  Examples:
    $Megogo->change_user({
      UID         => 1,
      TP_ID       => 1,
      EXPIRY_DATE => "2015-11-11",
      ACTIVE      => 1,
    });

=cut

#*******************************************************************
sub change_user {
  my $self = shift;
  my ($attr) = @_;

  $self->changes2(
    {
      CHANGE_PARAM => 'TP_ID',
      SECOND_PARAM => 'UID',
      TABLE        => 'megogo_users',
      DATA         => $attr,
    }
  );

  return $self;
}


#*******************************************************************
=head2 function change_tp_id() - change user info by NEXT_TP_ID
  Arguments:
    $attr

  Returns:
    $self object

  Examples:
    $Megogo->change_tp_id(
                  {
                    UID            => 13,
                    TP_ID          => 3,
                    NEXT_TP_ID     => 3,
                    EXPIRY_DATE    => 2016-03-01,
                    SUSPEND        => 0,
                    ACTIVE         => 0
                  }
                );

=cut
#*******************************************************************
sub change_tp_id {
 my $self = shift;
  my ($attr) = @_;

  $self->changes2(
    {
      CHANGE_PARAM => 'UID,NEXT_TP_ID',
      TABLE        => 'megogo_users',
      DATA         => $attr,
    }
  );

  return $self;
}

#*******************************************************************
=head2 function add_user_free() - add user to table, if he used free period
  Arguments:
    $attr
      UID    - user's identifier,
      USED   - true or false
  Returns:
    $self object

  Examples:
    $Megogo->add_user_free({
      UID         => 1,
      USED        => 1,
    });

=cut
#*******************************************************************
sub add_user_free {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add(
    'megogo_free_period',
    {
      UID            => $attr->{UID},
      USED           => $attr->{FP},
      DATE_START     => 'CURDATE()'
    }
  );


  return $self;
}

#*******************************************************************
=head2 function select_user_free() - select user's info about free period
  Arguments:
    $attr
      UID - user's identifier
  Returns:
    $self object

  Examples:
    $Megogo->select_user_free({
      UID         => 1
    });

=cut
#*******************************************************************
sub select_user_free {
  my $self = shift;
  my ($attr) = @_;

  $self->query2(
    "SELECT * FROM megogo_free_period
    WHERE uid = ?;", undef, { INFO => 1, Bind => [ $attr->{UID} ] }
  );
  return $self;
}

#*******************************************************************
=head2 function add_tp_report() - add tariff plan to report table
  Arguments:
    $attr

  Returns:
    $self object

  Examples:
    $Megogo->add_tp_report({ %$FORM });

=cut
#*******************************************************************
sub add_tp_report {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('megogo_report', {%$attr});

  return $self;
}

#*******************************************************************
=head2 function report_lists() - get report data for month and year
  Arguments:
    $attr
      MONTH - month id
      YEAR  - year

  Returns:
    $self object

  Examples:
    my $report_data = $Megogo->report_lists(
    {
      MONTH => 3,
      YEAR  => 2016,
      COLS_NAME => 1
    }
  );

=cut
#*******************************************************************
sub report_lists {
  my $self = shift;
  my ($attr) = @_;

  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  my $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  $self->query2(
    "SELECT * FROM megogo_report
    WHERE month = $attr->{MONTH} && year = $attr->{YEAR}
    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr,
    { INFO => 1 }
  );

  my $list = $self->{list};

  return $self->{list} if ($self->{TOTAL} < 1);

  $self->query2(
    "SELECT count(*) AS total
   FROM megogo_report WHERE month = $attr->{MONTH} && year = $attr->{YEAR}",
    undef,
    { INFO => 1 }
  );

  return $list;
}

1