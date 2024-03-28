=head1 Organizer

Organizer - module counts the costs for utilities

=head1 Synopsis

use Organizer;

my $Organizer = Organizer->new($db, $admin, \%conf);

=cut

package Organizer;
use strict;
use parent 'main';
our $VERSION = 0.01;
my ($admin, $CONF);
my ($SORT, $DESC, $PG, $PAGE_ROWS);

#*******************************************************************
=head2 function new() - initialize Organizer object

  Arguments:
    $db    -
    $admin -
    %conf  -
  Returns:
    $self object

  Examples:
    $Organizer = Organizer->new($db, $admin, \%conf);

=cut
#*******************************************************************
sub new {
  my $class = shift;
  my $db    = shift;
  ($admin, $CONF) = @_;

  my $self = {};
  bless($self, $class);

  $self->{db} = $db;
  $self->{admin} = $admin;
  $self->{conf} = $CONF;

  return $self;
}

# #**********************************************************
# =head2 add_type($attr)

#   Arguments:


#   Returns:

# =cut
# #**********************************************************
# sub add_type {
#   my $self = shift;
#   my ($attr) = @_;

#   $self->query_add('o_type', {%$attr});

#   return $self;
# }

# #**********************************************************
# =head2 change_type($attr) - change poll

#   Arguments:

#   Returns:
#     $self object;

#   Examples:
#     $Organizer->change_type({ ID => $FORM{id}, %FORM });

# =cut
# #**********************************************************
# sub change_type {
#   my $self = shift;
#   my ($attr) = @_;

#   $self->changes2(
#     {
#       CHANGE_PARAM => 'ID',
#       TABLE        => 'o_type',
#       DATA         => $attr
#     }
#   );

#   return $self;
# }

# #**********************************************************
# =head2 del_type($attr) - delete poll

#   Arguments:
#     ID   - poll's ID;

#   Returns:
#     $self object;

#   Examples:
#     $Organizer->del_type({ID => $FORM{del}});

# =cut
# #**********************************************************
# sub del_type {
#   my $self = shift;
#   my ($attr) = @_;

#   $self->query_del('o_type', $attr);

#   return $self;
# }

#**********************************************************
=head2 add_user_info() - adding counters data for date

  Arguments:

  Returns:

  Examples:
    $Organizer->add_user_info({%FORM});

=cut
#**********************************************************
sub add_user_info {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('organizer_user_info', {%$attr});

  return $self;
}

#**********************************************************
=head2 change_user_info($attr) - change counter information

  Arguments:

  Returns:
    $self object;

  Examples:
    $Organizer->change_user_info({ ID => $FORM{id}, %FORM });

=cut
#**********************************************************
sub change_user_info {
  my $self = shift;
  my ($attr) = @_;

  $self->changes2(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'organizer_user_info',
      DATA         => $attr
    }
  );

  return $self;
}

#**********************************************************
=head2 del_user_info($attr) - delete counter information

  Arguments:
    ID   - poll's ID;

  Returns:
    $self object;

  Examples:
    $Organizer->del_user_info({ID => $FORM{del}});

=cut
#**********************************************************
sub del_user_info {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('organizer_user_info', $attr);

  return $self;
}

#**********************************************************
=head2 list_user_info($attr) - get list of counters information

  Arguments:


  Returns:
    $self object;

  Examples:
    my $data_list = $Organizer->list_user_info({COLS_NAME => 1,
                                                 UID       => $user->{UID},
                                                 DATE      => '_SHOW',
                                                 LIGHT     => '_SHOW',
                                                 GAS       => '_SHOW',
                                                 WATER     => '_SHOW',});

=cut
#**********************************************************
sub list_user_info {
  my $self = shift;
  my ($attr) = @_;

  delete $self->{COL_NAMES_ARR};

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $WHERE = $self->search_former( $attr, [
      [ 'ID',           'INT',    'oui.id',         ],
      [ 'UID',          'INT',    'oui.uid',        ],
      [ 'DATE',         'DATE',   'oui.date',       1],
      [ 'LIGHT',        'INT',    'oui.light',      1],
      [ 'GAS',          'INT',    'oui.gas',        1],
      [ 'WATER',        'INT',    'oui.water',      1],
      [ 'COMMUNAL',     'DOUBLE', 'oui.communal',   1],
      [ 'COMMENTS',     'STR',    'oui.comments',   1],
    ],
    {
      WHERE => 1,
    }
  );


  #my $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

  $self->query2(
    "SELECT
    $self->{SEARCH_FIELDS}
    oui.id
    FROM organizer_user_info as oui
    $WHERE
    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list};

  return $self->{list} if ($attr->{TOTAL} < 1);

  $self->query2(
    "SELECT count(*) AS total
     FROM organizer_user_info",
    undef,
    { INFO => 1 }
  );

  return $list;
}

#**********************************************************
=head2 info_user_info($attr) - get information for one day

  Arguments:

  Returns:

  Examples:
    $Organizer->info_user_info({ID => $FORM{chg}});

=cut
#**********************************************************
sub info_user_info {
  my $self = shift;
  my ($attr) = @_;

  if($attr->{PREV_DATE}){
    $self->query2(
      "SELECT oui.id,
    oui.uid,
    oui.date,
    oui.light,
    oui.gas,
    oui.water,
    oui.communal,
    oui.comments
    FROM organizer_user_info as oui
    WHERE oui.date < \"$attr->{PREV_DATE}\" && oui.uid = $attr->{UID}
    ORDER BY date desc;", undef, { COLS_NAME => 1}
    );
  }

  if($attr->{NEXT_DATE}){
    $self->query2(
      "SELECT oui.id,
    oui.uid,
    oui.date,
    oui.light,
    oui.gas,
    oui.water,
    oui.communal,
    oui.comments
    FROM organizer_user_info as oui
    WHERE oui.date > \"$attr->{NEXT_DATE}\" && oui.uid = $attr->{UID}
    ORDER BY date;", undef, { COLS_NAME => 1}
    );
  }

  if ($attr->{ID}) {
    $self->query2(
      "SELECT oui.id,
    oui.uid,
    oui.date,
    oui.light,
    oui.gas,
    oui.water,
    oui.communal,
    oui.comments
    FROM organizer_user_info as oui
      WHERE oui.id = ?;", undef, { COLS_NAME => 1, Bind => [ $attr->{ID} ] }
    );
  }

  return $self->{list}->[0];
}

1;