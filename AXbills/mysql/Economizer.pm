=head1 Economizer

Economizer - module counts the costs for utilities

=head1 Synopsis

use Economizer;

my $Economizer = Economizer->new($db, $admin, \%conf);

=cut

package Economizer;
use strict;
use parent 'main';
our $VERSION = 0.02;
my ($admin, $CONF);
my ($SORT, $DESC, $PG, $PAGE_ROWS);

#*******************************************************************
=head2 function new() - initialize Economizer object

  Arguments:
    $db    -
    $admin -
    %conf  -
  Returns:
    $self object

  Examples:
    $Economizer = Economizer->new($db, $admin, \%conf);

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
# =head2 add_tariff($attr)

#   Arguments:


#   Returns:

# =cut
# #**********************************************************
sub add_tariff {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('economizer_tariffs', {%$attr});

  return $self;
}

# #**********************************************************
# =head2 change_tariff($attr) - change poll

#   Arguments:

#   Returns:
#     $self object;

#   Examples:
#     $Economizer->change_tariff({ ID => $FORM{id}, %FORM });

# =cut
# #**********************************************************
sub change_tariff {
  my $self = shift;
  my ($attr) = @_;

  $self->changes2(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'economizer_tariffs',
      DATA         => $attr
    }
  );

  return $self;
}

# #**********************************************************
# =head2 delete_tariff($attr) - delete poll

#   Arguments:
#     ID   - poll's ID;

#   Returns:
#     $self object;

#   Examples:
#     $Economizer->delete_tariff({ID => $FORM{del}});

# =cut
# #**********************************************************
sub delete_tariff {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('economizer_tariffs', $attr);

  return $self;
}

#**********************************************************
=head2 add_user_info() - adding counters data for date

  Arguments:

  Returns:

  Examples:
    $Economizer->add_user_info({%FORM});

=cut
#**********************************************************
sub add_user_info {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('economizer_user_info', {%$attr});

  return $self;
}

#**********************************************************
=head2 change_user_info($attr) - change counter information

  Arguments:

  Returns:
    $self object;

  Examples:
    $Economizer->change_user_info({ ID => $FORM{id}, %FORM });

=cut
#**********************************************************
sub change_user_info {
  my $self = shift;
  my ($attr) = @_;

  $self->changes2(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'economizer_user_info',
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
    $Economizer->del_user_info({ID => $FORM{del}});

=cut
#**********************************************************
sub del_user_info {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('economizer_user_info', $attr);

  return $self;
}

#**********************************************************
=head2 list_user_info($attr) - get list of counters information

  Arguments:


  Returns:
    $self object;

  Examples:
    my $data_list = $Economizer->list_user_info({COLS_NAME => 1,
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
      [ 'ID',           'INT',    'eui.id',         ],
      [ 'UID',          'INT',    'eui.uid',        ],
      [ 'DATE',         'DATE',   'eui.date',       1],
      [ 'LIGHT',        'INT',    'eui.light',      1],
      [ 'GAS',          'INT',    'eui.gas',        1],
      [ 'WATER',        'INT',    'eui.water',      1],
      [ 'COMMUNAL',     'DOUBLE', 'eui.communal',   1],
      [ 'COMMENTS',     'STR',    'eui.comments',   1],
    ],
    {
      WHERE => 1,
    }
  );
  my @WHERE_RULES;
  if ( defined( $attr->{FROM_DATE} ) ){
    push @WHERE_RULES, "eui.date > '$attr->{FROM_DATE}'";
  }

  if ( defined( $attr->{TO_DATE} ) ){
    push @WHERE_RULES, "eui.date < '$attr->{TO_DATE}'";
  }

  $WHERE .= ($#WHERE_RULES > -1) ? "and " . join(' and ', @WHERE_RULES) : '';

  $self->query2(
    "SELECT
    $self->{SEARCH_FIELDS}
    eui.id
    FROM economizer_user_info as eui
    $WHERE
    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list};

  return $self->{list} if ($attr->{TOTAL} < 1);

  $self->query2(
    "SELECT count(*) AS total
     FROM economizer_user_info",
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
    $Economizer->info_user_info({ID => $FORM{chg}});

=cut
#**********************************************************
sub info_user_info {
  my $self = shift;
  my ($attr) = @_;

  if($attr->{PREV_DATE}){
    $self->query2(
      "SELECT eui.id,
    eui.uid,
    eui.date,
    eui.light,
    eui.gas,
    eui.water,
    eui.communal,
    eui.comments
    FROM economizer_user_info as eui
    WHERE eui.date < \"$attr->{PREV_DATE}\" && eui.uid = $attr->{UID}
    ORDER BY date desc;", undef, { COLS_NAME => 1}
    );
  }

  if($attr->{NEXT_DATE}){
    $self->query2(
      "SELECT eui.id,
    eui.uid,
    eui.date,
    eui.light,
    eui.gas,
    eui.water,
    eui.communal,
    eui.comments
    FROM economizer_user_info as eui
    WHERE eui.date > \"$attr->{NEXT_DATE}\" && eui.uid = $attr->{UID}
    ORDER BY date;", undef, { COLS_NAME => 1}
    );
  }

  if ($attr->{ID}) {
    $self->query2(
      "SELECT eui.id,
    eui.uid,
    eui.date,
    eui.light,
    eui.gas,
    eui.water,
    eui.communal,
    eui.comments
    FROM economizer_user_info as eui
      WHERE eui.id = ?;", undef, { COLS_NAME => 1, Bind => [ $attr->{ID} ] }
    );
  }

  return $self->{list}->[0];
}

1;