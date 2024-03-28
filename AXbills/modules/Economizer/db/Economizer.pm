package Economizer;

=head1 Economizer

  Economizer - module counts the costs for utilities

=head1 Synopsis

  use Economizer;

  my $Economizer = Economizer->new($db, $admin, \%conf);

=cut

use strict;
use parent qw(dbcore);

our $VERSION = 0.03;

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

  $self->{db}    = $db;
  $self->{admin} = $admin;
  $self->{conf}  = $CONF;

  return $self;
}

#**********************************************************
=head2 add_tariff($attr)

  Arguments:

  Returns:

=cut
#**********************************************************
sub add_tariff {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('economizer_tariffs', {%$attr});

  return $self;
}

#**********************************************************
=head2 change_tariff($attr) - change poll

  Arguments:

  Returns:
    $self object;

  Examples:
    $Economizer->change_tariff({ ID => $FORM{id}, %FORM });

=cut
#**********************************************************
sub change_tariff {
  my $self = shift;
  my ($attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'economizer_tariffs',
    DATA         => $attr
  });

  return $self;
}

#**********************************************************
=head2 delete_tariff($attr) - delete poll

  Arguments:
    ID   - poll's ID;

  Returns:
    $self object;

  Examples:
    $Economizer->delete_tariff({ID => $FORM{del}});

=cut
#**********************************************************
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

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'economizer_user_info',
    DATA         => $attr
  });

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

  my $WHERE = $self->search_former(
    $attr,
    [ [ 'ID',       'INT',    'eui.id',         ],
      [ 'UID',      'INT',    'eui.uid',        ],
      [ 'DATE',     'DATE',   'eui.date',     1 ],
      [ 'LIGHT',    'INT',    'eui.light',    1 ],
      [ 'GAS',      'INT',    'eui.gas',      1 ],
      [ 'WATER',    'INT',    'eui.water',    1 ],
      [ 'COMMUNAL', 'DOUBLE', 'eui.communal', 1 ],
      [ 'COMMENTS', 'STR',    'eui.comments', 1 ], ],
    {
      WHERE => 1,
    }
  );
  my @WHERE_RULES;

  if (defined($attr->{FROM_DATE})) {
    push @WHERE_RULES, "eui.date > '$attr->{FROM_DATE}'";
  }

  if (defined($attr->{TO_DATE})) {
    push @WHERE_RULES, "eui.date < '$attr->{TO_DATE}'";
  }

  $WHERE .= ($#WHERE_RULES > -1) ? "and " . join(' and ', @WHERE_RULES) : '';

  $self->query(
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

  $self->query(
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

  if ($attr->{PREV_DATE}) {
    $self->query(
      "SELECT eui.id,
        eui.uid,
        eui.date,
        eui.light,
        eui.gas,
        eui.water,
        eui.communal,
        eui.comments
      FROM economizer_user_info as eui
        WHERE eui.date < ? && eui.uid = ?
      ORDER BY date desc;", undef, {
        COLS_NAME => 1,
        Bind      => [
          $attr->{PREV_DATE},
          $attr->{UID},
        ]
      }
    );
  }

  if ($attr->{NEXT_DATE}) {
    $self->query(
      "SELECT eui.id,
        eui.uid,
        eui.date,
        eui.light,
        eui.gas,
        eui.water,
        eui.communal,
        eui.comments
      FROM economizer_user_info as eui
        WHERE eui.date > ? && eui.uid = ?
      ORDER BY date;", undef, {
        COLS_NAME => 1,
        Bind      => [
          $attr->{NEXT_DATE},
          $attr->{UID},
        ]
      }
    );
  }

  if ($attr->{ID}) {
    $self->query(
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

  return $self->{list}->[0] || {};
}

#**********************************************************
=head2 add_user_metric104() - adding counters data for date

  Arguments:

  Returns:

  Examples:
    $Economizer->add_user_info({%FORM});

=cut
#**********************************************************
sub add_user_metric104 {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('economizer_metric104', $attr);

  return $self;
}

#**********************************************************

=head2 add_user_payment104() - adding counters data for date

  Arguments:

  Returns:

  Examples:
    $Economizer->add_user_payment104({%FORM});

=cut

#**********************************************************
sub add_user_payment104 {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('economizer_payment104', $attr);

  return $self;
}

#**********************************************************
=head2 clear_metric104

  Arguments:

  Returns:

  Examples:

=cut
#**********************************************************
sub clear_metric104 {
  my $self = shift;
  my ($attr) = @_;

  #TODO: check this logic

  $self->query_del('economizer_metric104', {}, { USER_ID => $attr->{USER_ID} });
  $self->query("ALTER TABLE economizer_metric104 MODIFY `id` INT(11);",                                     undef, {});
  $self->query("ALTER TABLE economizer_metric104 DROP PRIMARY KEY;",                                        undef, {});
  $self->query("UPDATE economizer_metric104 SET `id`='0';",                                                 undef, {});
  $self->query("ALTER TABLE economizer_metric104 AUTO_INCREMENT=0;",                                        undef, {});
  $self->query("ALTER TABLE economizer_metric104 MODIFY `id` INT(11) NOT NULL AUTO_INCREMENT PRIMARY KEY;", undef, {});

  $self->query_del('economizer_payment104', {}, { USER_ID => $attr->{USER_ID} });
  $self->query("ALTER TABLE economizer_payment104 MODIFY `id` INT(11);",                                     undef, {});
  $self->query("ALTER TABLE economizer_payment104 DROP PRIMARY KEY;",                                        undef, {});
  $self->query("UPDATE economizer_payment104 SET `id`='0';",                                                 undef, {});
  $self->query("ALTER TABLE economizer_payment104 AUTO_INCREMENT=0;",                                        undef, {});
  $self->query("ALTER TABLE economizer_payment104 MODIFY `id` INT(11) NOT NULL AUTO_INCREMENT PRIMARY KEY;", undef, {});

  return $self;
}

#**********************************************************
=head2 take_indicators 104($attr)

  Arguments:
    $attr - hash_ref
  Returns:

=cut
#**********************************************************
sub clear_electric {
  my $self = shift;
  my ($attr) = @_;

  #TODO: check this logic

  $self->query_del('economizer_electro_money', {}, { USER_ID => $attr->{USER_ID} });
  $self->query("ALTER TABLE economizer_electro_money MODIFY `id` INT(11);",                                     undef, {});
  $self->query("ALTER TABLE economizer_electro_money DROP PRIMARY KEY;",                                        undef, {});
  $self->query("UPDATE economizer_electro_money SET `id`='0';",                                                 undef, {});
  $self->query("ALTER TABLE economizer_electro_money AUTO_INCREMENT=0;",                                        undef, {});
  $self->query("ALTER TABLE economizer_electro_money MODIFY `id` INT(11) NOT NULL AUTO_INCREMENT PRIMARY KEY;", undef, {});

  $self->query_del('economizer_electro_counter', {}, { USER_ID => $attr->{USER_ID} });
  $self->query("ALTER TABLE economizer_electro_counter MODIFY `id` INT(11);",                                     undef, {});
  $self->query("ALTER TABLE economizer_electro_counter DROP PRIMARY KEY;",                                        undef, {});
  $self->query("UPDATE economizer_electro_counter SET `id`='0';",                                                 undef, {});
  $self->query("ALTER TABLE economizer_electro_counter AUTO_INCREMENT=0;",                                        undef, {});
  $self->query("ALTER TABLE economizer_electro_counter MODIFY `id` INT(11) NOT NULL AUTO_INCREMENT PRIMARY KEY;", undef, {});

  return $self;
}

#**********************************************************
=head2 take_indicators 104($attr)

  Arguments:
    $attr - hash_ref
  Returns:

=cut
#**********************************************************
sub take_indicators104 {
  my $self = shift;
  my ($attr) = @_;

  $self->query("SELECT * FROM economizer_metric104; ", undef, $attr);

  return $self->{list} || [];
}

#**********************************************************
=head2 take_payment($attr)

  Arguments:
    $attr - hash_ref
  Returns:

=cut
#**********************************************************
sub take_payment104 {
  my $self = shift;
  my ($attr) = @_;

  $self->query("SELECT * FROM economizer_payment104; ", undef, $attr);

  return $self->{list} || [];
}

#**********************************************************
=head2 add_user_money_electric() - adding counters data for date

  Arguments:

  Returns:

  Examples:
    $Economizer->add_user_info({%FORM});

=cut
#**********************************************************
sub add_user_money_electric {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('economizer_electro_money', {%$attr});

  return $self;
}

#**********************************************************
=head2 take_money_electric($attr)

  Arguments:
    $attr - hash_ref
  Returns:

=cut
#**********************************************************
sub take_money_electric {
  my $self = shift;
  my ($attr) = @_;

  $self->query("SELECT * FROM economizer_electro_money; ", undef, $attr);

  return $self->{list} || [];
}

#**********************************************************
=head2 add_user_money_electric() - adding counters data for date

  Arguments:

  Returns:

  Examples:
    $Economizer->add_user_info({%FORM});

=cut
#**********************************************************
sub add_user_electro_counter {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('economizer_electro_counter', $attr);

  return $self;
}

#**********************************************************
=head2 take_money_electric($attr)

  Arguments:
    $attr - hash_ref
  Returns:

=cut
#**********************************************************
sub take_electro_counter {
  my $self = shift;
  my ($attr) = @_;

  $self->query("SELECT * FROM economizer_electro_counter; ", undef, $attr);

  return $self->{list} || [];
}

#**********************************************************
=head2 add_main () - adding counters data for date

  Arguments:

  Returns:

  Examples:
    $Economizer->add_user_info({%FORM});

=cut
#**********************************************************
sub add_main {
  my $self = shift;
  my ($attr) = @_;

  my $existing_user = $attr->{EXISTING} || '';

  if ($existing_user eq 'yes') {
    $self->query(
      "UPDATE economizer_main
        SET login104 = ?,
            password104 = ENCODE( ?,'$self->{conf}->{secretkey}' ),
            login_electro=?,
            password_electro= ENCODE( ?,'$self->{conf}->{secretkey}' ),
            user_id = ?
        WHERE
            user_id = ?;",
      undef,
      {
        Bind => [
          $attr->{LOGIN104},
          $attr->{PASSWORD104},
          $attr->{LOGIN_ELECTRO},
          $attr->{PASSWORD_ELECTRO},
          $attr->{USER_ID},
          $attr->{USER_ID},
        ]
      }
    );
  }
  else {
    $self->query(
      "INSERT INTO economizer_main
        (login104,password104,
         login_electro,
         password_electro,user_id)
       VALUES
        (?,
         ENCODE( ?,'$self->{conf}->{secretkey}'),
         ?,
         ENCODE( ?,'$self->{conf}->{secretkey}'),
         ? );",
      undef,
      {
        Bind => [
          $attr->{LOGIN104},
          $attr->{PASSWORD104},
          $attr->{LOGIN_ELECTRO},
          $attr->{PASSWORD_ELECTRO},
          $attr->{USER_ID}
        ]
      }
    );
  }

  return $self;
}

#*********************************************************
=head2 take_main_data($attr)

  Arguments:
    $attr - hash_ref
  Returns:

=cut
#**********************************************************
sub take_main_data {
  my $self = shift;
  my ($attr) = @_;

  $self->query(
    "SELECT
      id,
      login104,
      DECODE(password104,'$self->{conf}->{secretkey}'),
      login_electro,
      DECODE( password_electro,'$self->{conf}->{secretkey}'),
      user_id
     FROM economizer_main;",
    undef,
    $attr
  );

  return $self->{list} || [];
}

#**********************************************************
=head2 take_main($attr)

  Arguments:

    $attr - hash_ref
  Returns:

=cut
#**********************************************************
sub take_main {
  my $self = shift;
  my ($attr) = @_;

  $self->query("SELECT * FROM economizer_main; ", undef, $attr);

  return $self->{list} || [];
}

1;
