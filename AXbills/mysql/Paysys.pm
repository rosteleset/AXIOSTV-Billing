package Paysys;
#*********************** ABillS ***********************************
# Copyright (с) 2003-2023 Andy Gulay (ABillS DevTeam) Ukraine
#
# See COPYRIGHT section in pod text below for usage and distribution rights.
#
#******************************************************************
=head1 NAME

  Finance module for external payments

=head1 VERSION

  VERSION: 9.34
  UPDATE: 20230905

=cut

use strict;
use parent qw(dbcore);

our $VERSION = 9.34;
my $MODULE = 'Paysys';

my ($admin, $CONF);

#**********************************************************
=head2 function new() - create object;

  Return:
    self object

  Examples:
    my $Paysys   = Paysys->new($db, $admin, \%conf);
=cut
#**********************************************************
sub new {
  my $class = shift;
  my $db    = shift;
  ($admin, $CONF) = @_;

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $CONF
  };

  bless($self, $class);

  $admin->{MODULE}=$MODULE;

  return $self;
}

#**********************************************************
=head2 function defaults() - create object with default data;

  Returns:
   self object

  Examples:

=cut
#**********************************************************
# sub defaults {
#   my $self = shift;
#
#   my %DATA = (
#     SYSTEM_ID      => 0,
#     DATETIME       => '',
#     SUM            => 0.00,
#     UID            => 0,
#     IP             => '0.0.0.0',
#     TRANSACTION_ID => '',
#     INFO           => '',
#     CODE           => '',
#     PAYSYS_IP      => '0.0.0.0',
#     STATUS         => 0,
#     DOMAIN_ID      => 0,
#     COMMISSION     => 0.00
#   );
#
#   $self = \%DATA;
#   return $self;
# }

#**********************************************************
=head2 function add() - add data to database;

  Arguments:
    SYSTEM_ID      - payment system number;
    DATETIME       - date and time;
    SUM            - amount;
    UID            - user's identifier;
    IP             - user's IP;
    TRANSACTION_ID - external identifier;
    INFO           - information about payment;
    USER_INFO      - additional information;
    PAYSYS_IP      - systems IP;
    STATUS         - status code;
  Returns:
    self object;

  Examples:
    $Paysys->add(
          {
            SYSTEM_ID      => 100,
            DATETIME       => 2015-12-12,
            SUM            => 100.00,
            UID            => 1,
            IP             => 192.10.10.10,
            TRANSACTION_ID => "$payment_system:$ext_id",
            INFO           => %DATA%,
            USER_INFO      => Success,
            PAYSYS_IP      => 255.255.255.255,
            STATUS         => 0
          }
      );

=cut
#**********************************************************
sub add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('paysys_log', {
    %$attr,
    DATETIME  => $attr->{DATETIME} || 'NOW()',
    CODE      => ($attr->{CODE}) ? "ENCODE('$attr->{CODE}', '$CONF->{secretkey}')" : undef,
    PAYSYS_IP => "INET_ATON('". ($attr->{PAYSYS_IP} || '0.0.0.0') ."')",
  });

  return $self;
}

#**********************************************************
=head2 function del() - delete data from database;
  Arguments:

  Returns:
    self object;

  Examples:
    $Paysys->del($FORM{del});

=cut
#**********************************************************
sub del {
  my $self = shift;
  my ($id, $attr) = @_;

  $self->query_del('paysys_log', { ID => $id }, { uid => $attr->{UID} });

  if (!$self->{errno}) {
    $self->{admin}->{MODULE} = 'Paysys';
    $admin->system_action_add("DELETE payment_id: $id", { TYPE => 10 });
  }

  return $self;
}

#**********************************************************
=head2 function list() - take list data from database

  Arguments:
    TRANSACTION_ID - transiction_s identifier;
    STATUS         - status code;
    COLS_NAME      - columns name;
  Returns:
    self object;

  Examples:
    my $list = $Paysys->list({ TRANSACTION_ID => "$payment_system:$ext_id",
                               STATUS => '_SHOW',
                               COLS_NAME => 1 });

=cut
#**********************************************************
sub list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  my $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  $attr->{DOMAIN_ID} ||= $admin->{DOMAIN_ID} || '_SHOW';

  my $WHERE =  $self->search_former($attr, [
    ['IP',                'IP',  'ps.ip',     'INET_NTOA(ps.ip) AS ip'    ],
    ['PAYMENT_SYSTEM',    'INT', 'ps.system_id'                           ],
    ['TRANSACTION_ID',    'STR', 'ps.transaction_id'                      ],
    ['INFO',              'STR', 'ps.info',                             1 ],
    ['SUM',               'INT', 'ps.sum',                                ],
    ['USER_INFO',         'STR', 'ps.user_info',                        1 ],
    ['ID',                'INT', 'ps.id'                                  ],
    ['STATUS',            'INT', 'ps.status'                              ],
    ['DATE',              'DATE',"DATE_FORMAT(ps.datetime, '%Y-%m-%d')"   ],
    ['MONTH',             'DATE',"DATE_FORMAT(ps.datetime, '%Y-%m')"      ],
    ['FROM_DATE|TO_DATE', 'DATE',"DATE_FORMAT(ps.datetime, '%Y-%m-%d')"   ],
  ], {
    WHERE        => 1,
    USERS_FIELDS => 1,
    USE_USER_PI  => 1,
  });

  if ($attr->{INFO}) {
    delete $attr->{INFO};
  }

  my $EXT_TABLES = $self->{EXT_TABLES} || '';

  $self->query("SELECT ps.id, u.id AS login, ps.datetime, ps.sum, ps.system_id, ps.transaction_id,
      ps.status,
      $self->{SEARCH_FIELDS}
      ps.uid
    FROM paysys_log ps
    LEFT JOIN users u ON (u.uid=ps.uid)
    $EXT_TABLES
    $WHERE
    GROUP BY ps.id
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list} || [];

  $self->{SUM} = '0.00';

  return [] if ($self->{TOTAL} < 1);

  $self->query("SELECT COUNT(ps.id) AS total,
      SUM(ps.sum) AS sum,
      SUM(IF (ps.status=2, 1, 0)) AS total_complete,
      SUM(IF (ps.status=2, ps.sum, 0))  AS sum_complete
   FROM paysys_log ps
   LEFT JOIN users u ON (u.uid=ps.uid)
   $WHERE",
    undef,
    { INFO => 1 }
  );

  return $list;
}

#**********************************************************
=head2 function change() - change data in database

  Arguments:
    ID        - system identifier;
    STATUS    - status code;
    PAYSYS_IP - system_s IP;
    INFO      - information about payment;
    USER_INFO - additional information;

  Returns:
    self object;

  Examples:
    $Paysys->change(
          {
            ID        => 100,
            STATUS    => 2,
            PAYSYS_IP => 255.255.255.255,
            INFO      => 'DATA',
            USER_INFO => 'Success'
            }
        );

=cut
#**********************************************************
sub change {
  my $self = shift;
  my ($attr) = @_;

  if ($attr->{PAYSYS_IP}) {
    $attr->{PAYSYS_IP} = "INET_ATON('" . $attr->{PAYSYS_IP} . "')";
  }

  $self->{admin}->{MODULE} = 'Paysys';

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'paysys_log',
    DATA         => $attr
  });

  return $self;
}

#**********************************************************
=head2 function info() - show info about transaction

  Arguments:
    ID             - system identifier;
    TRANSACTION_ID - transaction identifier;
  Returns:
    self object;

  Examples:
    $Paysys->info({ ID => 100
                    TRANSACTION_ID => 11111
                });

=cut
#**********************************************************
sub info {
  my $self = shift;
  my ($attr) = @_;

  my @WHERE_RULES = ();
  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  my $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  if ($attr->{CODE}) {
    push @WHERE_RULES, "ps.code=ENCODE('$attr->{CODE}', '$CONF->{secretkey}')";
  }

  if ($attr->{ID}) {
    push @WHERE_RULES, "ps.id='$attr->{ID}'";
  }

  if ($attr->{TRANSACTION_ID}) {
    push @WHERE_RULES, "ps.transaction_id='$attr->{TRANSACTION_ID}'";
  }

  my $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

  $self->query("SELECT
      ps.*,
      u.id AS login,
      INET_NTOA(ps.ip) AS client_ip,
      INET_NTOA(ps.paysys_ip) AS paysys_ip
    FROM paysys_log ps
    LEFT JOIN users u ON (u.uid=ps.uid)
    $WHERE
    GROUP BY ps.id
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;",
    undef,
    { INFO => 1 }
  );

  return $self;
}

#**********************************************************
=head2 function reports() - ;
  Arguments:

  Returns:
    self object;

  Examples:
    $Paysys->reports(
    {

    });

=cut
#**********************************************************
sub reports {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $date = '';
  my @WHERE_RULES = ();

  if ($attr->{GID}) {
    push @WHERE_RULES, "u.gid='$attr->{GID}'";
  }

  if (defined($attr->{DATE})) {
    push @WHERE_RULES, "DATE_FORMAT(p.date, '%Y-%m-%d')='$attr->{DATE}'";
  }
  elsif ($attr->{INTERVAL}) {
    my ($from, $to) = split(/\//, $attr->{INTERVAL}, 2);
    push @WHERE_RULES, "DATE_FORMAT(p.date, '%Y-%m-%d')>='$from' AND DATE_FORMAT(p.date, '%Y-%m-%d')<='$to'";
    if ($attr->{TYPE} eq 'HOURS') {
      $date = "DATE_FORMAT(p.date, '%H')";
    }
    elsif ($attr->{TYPE} eq 'DAYS') {
      $date = "DATE_FORMAT(p.date, '%Y-%m-%d')";
    }
    else {
      $date = "u.id";
    }
  }
  elsif (defined($attr->{MONTH})) {
    push @WHERE_RULES, "DATE_FORMAT(p.date, '%Y-%m')='$attr->{MONTH}'";
    $date = "DATE_FORMAT(p.date, '%Y-%m-%d')";
  }
  else {
    $date = "DATE_FORMAT(p.date, '%Y-%m')";
  }

  my $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

  $self->query("SELECT $date, COUNT(*), SUM(p.sum)
      FROM payments p
      LEFT JOIN users u ON (u.uid=p.uid)
      $WHERE
      GROUP BY 1
      ORDER BY $SORT $DESC;",
    undef,
    $attr
  );

  my $list = $self->{list} || [];

  $self->query("SELECT COUNT(*) AS total, SUM(p.sum) AS sum
      FROM payments p
      LEFT JOIN users u ON (u.uid=p.uid)
      $WHERE;",
    undef,
    { INFO => 1 }
  );

  return $list;
}

#**********************************************************
=head2 user_add() - add user to regular payments databse;

  Arguments:
    UID       - users identifier;
    TOKEN     - token for regular pay;
    SUM       - amount;
    PAYSYS_ID - system identifier;
  Returns:
    self object;

  Examples:
    $Paysys->user_add(
    {
      UID       => 1,
      TOKEN     => jkvhe2k3h4jv2h3423c432vbkiumo76,
      SUM       => 100,00,
      PAYSYS_ID => 100
    }
  );

=cut
#**********************************************************
sub user_add {
  my $self = shift;
  my($attr) = @_;

  $self->query_add('paysys_main', {
    %$attr,
    EXTERNAL_USER_IP   => "INET_ATON('". ($attr->{EXTERNAL_USER_IP} || '0.0.0.0') ."')",
    DATE               => 'NOW()',
    EXTERNAL_LAST_DATE => 'NOW()'
  });

  return $self;
}

#**********************************************************
=head2 user_info($attr) -

  Arguments:
    $attr -
      UID          - get info by UID
      RECURRENT_ID - get info by RECURRENT_ID
  Returns:

  Examples:

=cut
#**********************************************************
sub user_info {
  my $self = shift;
  my ($attr) = @_;

  my $WHERE =  $self->search_former($attr, [
    ['RECURRENT_ID',  'INT', 'pm.recurrent_id' ],
    ['UID',           'INT', 'pm.uid'    ],
  ],
    { WHERE       => 1 }
  );

  $self->query(
    "SELECT
      pm.*,
      INET_NTOA(pm.external_user_ip) AS external_user_ip
    FROM paysys_main AS pm
    $WHERE ;",
    undef,
    { INFO => 1});

  return $self;
}

#**********************************************************
=head2 user_change($attr) - change data in database;

  Arguments:
    $attr

  Returns:
    self object;

  Examples:

=cut
#**********************************************************
sub user_change {
  my $self = shift;
  my ($attr) = @_;

  $self->{admin}->{MODULE} = 'Paysys';

  $self->changes({
    CHANGE_PARAM => 'UID',
    SECOND_PARAM => 'PAYSYS_ID',
    TABLE        => 'paysys_main',
    DATA         => $attr,
  });

  return $self;
}

#**********************************************************
=head2 user_del($attr) - delete data from database;

  Arguments:
    $attr - any column from paysys_main

  Returns:
    self object;

=cut
#**********************************************************
sub user_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('paysys_main', undef, $attr);

  return $self;
}

#**********************************************************
=head2 user_list($attr) - get users list from regular payments database;

  Arguments:
    $attr

  Returns:
    self object;

  Examples:
    my $list = $Paysys->paysys_list(
    {
      PAYSYS_ID => '_SHOW',
      PAGE_ROWS => 100000,
      COLS_NAME => 1
    }
  );

=cut
#**********************************************************
sub user_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  my $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  $attr->{DOMAIN_ID} ||= $admin->{DOMAIN_ID} || '_SHOW';

  my $WHERE =  $self->search_former($attr, [
    ['CLOSED',        'INT',  'pm.closed',    1 ],
    ['PAYSYS_ID',     'INT',  'pm.paysys_id', 1 ],
    ['DATE',          'DATE', 'pm.date',      1 ],
    ['SUM',           'INT',  'pm.sum',       1 ],
    ['DOMAIN_ID',     'INT',  'pm.domain_id', 1 ],
    ['SUBSCRIBE_DATE_START', 'DATE', 'pm.subscribe_date_start', 1],
  ],
    { WHERE       => 1,
      USERS_FIELDS=> 1,
      USE_USER_PI => 1
    });

  if ($attr->{ONLY_SUBSCRIBES}) {
    $WHERE = ($WHERE) ? "$WHERE AND paysys_id>0" : " WHERE paysys_id>0";
  }

  $self->query("SELECT $self->{SEARCH_FIELDS}
      pm.*,
      INET_NTOA(pm.external_user_ip) AS external_user_ip
    FROM paysys_main pm
    LEFT JOIN users u ON (u.uid=pm.uid) "
    . ($self->{EXT_TABLES} || q{})
    . "$WHERE
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list} || [];

  return $self->{list} if ($self->{TOTAL} < 1);

  $self->query('SELECT COUNT(*) AS total
   FROM paysys_main pm
   LEFT JOIN users u ON (u.uid=pm.uid)'
    . ($self->{EXT_TABLES} || q{})
    . "$WHERE;",
    undef,
    { INFO => 1 }
  );

  return $list;
}

#**********************************************************
=head2 bss_add($attr)

  Arguments:


  Returns:

=cut
#**********************************************************
sub bss_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('bss_payments', {%$attr});

  return $self;
}

#**********************************************************
=head2 bss_list($attr)

  Arguments:


  Returns:

=cut
#**********************************************************
sub bss_list {
  my $self = shift;
  my ($attr) = @_;

  delete $self->{COL_NAMES_ARR};

  my @WHERE_RULES = ();
  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  my $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  if ($attr->{STATUS}) {
    push @WHERE_RULES, "bp.status = '$attr->{STATUS}'";
  }

  if($attr->{DATE_FROM} && $attr->{DATE_TO}){
    push @WHERE_RULES, "bp.date >= '$attr->{DATE_FROM}' and bp.date <= '$attr->{DATE_TO}'";
  }

  my $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

  $self->query(
    "SELECT
    bp.id,
    bp.uid,
    bp.fio,
    bp.date,
    bp.description,
    bp.status,
    bp.ext_id,
    bp.address,
    bp.sum
    FROM bss_payments as bp
    $WHERE
    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list} || [];

  return $self->{list} if ($attr->{TOTAL} < 1);

  $self->query(
    "SELECT COUNT(*) AS total
     FROM bss_payments",
    undef,
    { INFO => 1 }
  );

  return $list;
}

#**********************************************************
=head2 bss_change($attr)

  Arguments:


  Returns:

=cut
#**********************************************************
sub bss_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'bss_payments',
    DATA         => $attr
  });

  return $self;
}

#**********************************************************
=head2 bss_delete($attr)

  Arguments:


  Returns:

=cut
#**********************************************************
sub bss_delete {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('bss_payments', $attr);

  return $self;
}

#**********************************************************
=head2 bss_sum_add() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub bss_sum_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('bss_sum', {%$attr});

  return $self;
}

#**********************************************************
=head2 bss_list($attr)

  Arguments:


  Returns:

=cut
#**********************************************************
sub bss_sum_list {
  my $self = shift;
  my ($attr) = @_;

  delete $self->{COL_NAMES_ARR};

  my @WHERE_RULES = ();
  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  my $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  if ($attr->{STATUS}) {
    push @WHERE_RULES, "bs.status = '$attr->{STATUS}'";
  }

  if($attr->{DATE}){
    push @WHERE_RULES, "bs.date = '$attr->{DATE}'";
  }

  if($attr->{DATE_FROM} && $attr->{DATE_TO}){
    push @WHERE_RULES, "bs.date >= '$attr->{DATE_FROM}' and bs.date <= '$attr->{DATE_TO}'";
  }

  my $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

  $self->query(
    "SELECT
    bs.id,
    bs.date,
    bs.bank_std_sum,
    bs.bank_nstd_sum,
    bs.local_std_sum,
    bs.local_nstd_sum,
    bs.std_count,
    bs.nstd_count
    FROM bss_sum as bs
    $WHERE
    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list} || [];

  return [] if ($attr->{TOTAL} < 1);

  $self->query(
    "SELECT COUNT(*) AS total
     FROM bss_sum",
    undef,
    { INFO => 1 }
  );

  return $list;
}

#**********************************************************
=head2 bss_sum_change($attr)

  Arguments:


  Returns:

=cut
#**********************************************************
sub bss_sum_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'DATE',
    TABLE        => 'bss_sum',
    DATA         => $attr
  });

  return $self;
}

#**********************************************************
=head2 bss_sum_delete($attr)

  Arguments:


  Returns:

=cut
#**********************************************************
sub bss_sum_delete {
  my $self = shift;
  my ($attr) = @_;

  if ($attr->{DATE}) {
    $self->query_del('bss_sum', $attr, { DATE => $attr->{DATE} });
  }

  if ($attr->{ID}) {
    $self->query_del('bss_sum', $attr, { ID => $attr->{ID} });
  }

  return $self;
}

#**********************************************************
=head2 terminal_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut
#**********************************************************
sub terminal_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 'pt.id';
  my $DESC = ($attr->{DESC}) ? 'DESC' : '';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $search_columns = [
    ['ID',             'INT',  'pt.id'                        ,1 ],
    ['TYPE',           'INT',  'ptt.name'                     ,1 ],
    ['TYPE_ID',        'INT',  'pt.type as type_id'           ,1 ],
    ['COMMENT',        'STR',  'pt.comment'                   ,1 ],
    ['DESCRIPTION',    'STR',  'pt.description'               ,1 ],
    ['STATUS',         'INT',  'pt.status'                    ,1 ],
    ['DIS_NAME',       'STR',  'd.name as dis_name'           ,1 ],
    ['ST_NAME',        'STR',  's.name as st_name'            ,1 ],
    ['BD_NUMBER',      'STR',  'b.number as bd_number'        ,1 ],
    ['ADDRESS_FULL',   'STR',   "IF(pt.location_id, CONCAT(d.name, ', ', s.name, ', ',  b.number), '') AS address_full"        , 1 ],
    ['LOCATION_ID',    'INT',  'pt.location_id'               ,1 ],
    ['COORDX',         'INT',  'b.coordx'                     ,1 ],
    ['COORDY',         'INT',  'b.coordy'                     ,1 ],
    ['STREET_ID',      'INT',  'b.street_id',                  1 ],
    ['DISTRICT_ID',    'INT',  's.district_id',                1 ],
    ['WORK_DAYS',      'INT',  'pt.work_days',                 1 ],
    ['START_WORK',     'STR',  'pt.start_work',                1 ],
    ['END_WORK',       'STR',  'pt.end_work',                  1 ],
  ];

  if ($attr->{SHOW_ALL_COLUMNS}){
    map { $attr->{$_->[0]} = '_SHOW' unless exists $attr->{$_->[0]} } @$search_columns;
  }

  my $WHERE = $self->search_former($attr, $search_columns, {
    WHERE => 1
  });

  $self->query( "SELECT $self->{SEARCH_FIELDS} pt.id
  FROM paysys_terminals pt
   LEFT JOIN builds b ON (b.id = pt.location_id)
   LEFT JOIN streets s ON (s.id = b.street_id)
   LEFT JOIN districts d ON (d.id = s.district_id)
   LEFT JOIN paysys_terminals_types ptt ON (ptt.id = pt.type)

  $WHERE
  ORDER BY $SORT $DESC
  LIMIT $PG, $PAGE_ROWS;", undef, {
    COLS_NAME => 1,
    COLS_UPPER => 1,
    %{ $attr ? $attr : {}}}
  );

  return [] if $self->{errno};

  return $self->{list} || [];
}

#**********************************************************
=head2 terminal_list_with_coords($attr)

=cut
#**********************************************************
sub terminal_list_with_coords {
  my $self = shift;
  my ($attr) = @_;

  my $WHERE = $self->search_former($attr,
    [
      ['ID',             'INT', 'pt.id',                                                            1 ],
      ['TYPE',           'INT', 'ptt.name',                                                         1 ],
      ['TYPE_ID',        'INT', 'pt.type as type_id',                                               1 ],
      ['COMMENT',        'STR', 'pt.comment',                                                       1 ],
      ['DESCRIPTION',    'STR', 'pt.description',                                                   1 ],
      ['STATUS',         'INT', 'pt.status',                                                        1 ],
      ['DIS_NAME',       'STR', 'd.name as dis_name',                                               1 ],
      ['ST_NAME',        'STR', 's.name as st_name',                                                1 ],
      ['BD_NUMBER',      'STR', 'b.number as bd_number',                                            1 ],
      ['ADDRESS_FULL',   'STR', "IF(pt.location_id, CONCAT(d.name, ', ', s.name, ', ',  b.number), '') AS address_full"        , 1 ],
      ['LOCATION_ID',    'INT', 'pt.location_id',                                                   1 ],
      ['COORDX',         'INT', 'b.coordx',                                                         1 ],
      ['COORDY',         'INT', 'b.coordy',                                                         1 ],
      ['STREET_ID',      'INT', 'b.street_id',                                                      1 ],
      ['DISTRICT_ID',    'INT', 's.district_id',                                                    1 ],
      ['WORK_DAYS',      'INT', 'pt.work_days',                                                     1 ],
      ['START_WORK',     'STR', 'pt.start_work',                                                    1 ],
      ['END_WORK',       'STR', 'pt.end_work',                                                      1 ],
      ['COORDX_CENTER',  'STR', 'SUM(plpoints.coordx)/COUNT(plpoints.polygon_id) AS coordx_center', 1 ],
      ['COORDY_CENTER',  'STR', 'SUM(plpoints.coordy)/COUNT(plpoints.polygon_id) AS coordy_center', 1 ],
    ],
    { WHERE => 1 }
  );

  $self->query("SELECT $self->{SEARCH_FIELDS} pt.id
    FROM paysys_terminals pt
    LEFT JOIN builds b ON (b.id = pt.location_id)
    LEFT JOIN streets s ON (s.id = b.street_id)
    LEFT JOIN districts d ON (d.id = s.district_id)
    LEFT JOIN paysys_terminals_types ptt ON (ptt.id = pt.type)
    LEFT JOIN maps_points mp ON (b.id=mp.location_id)
    LEFT JOIN maps_point_types mt ON (mp.type_id=mt.id)
    LEFT JOIN maps_coords mc ON (mp.coord_id=mc.id)
    LEFT JOIN maps_polygons mgone ON (mgone.object_id=mp.id)
    LEFT JOIN maps_polygon_points plpoints ON(mgone.id=plpoints.polygon_id)
    $WHERE
    GROUP BY pt.id
    HAVING coordx_center <> '' OR coordx <> 0
    ORDER BY pt.id DESC;",
    undef, { COLS_NAME => 1, %{$attr} });

  return $self->{list} || [];
}

#**********************************************************
=head2 terminal_info($id)

  Arguments:
    $id - id for terminals

  Returns:
    hash_ref

=cut
#**********************************************************
sub terminal_info {
  my $self = shift;
  my ($id) = @_;

  my $list = $self->terminal_list({ COLS_NAME => 1, ID => $id, SHOW_ALL_COLUMNS => 1, COLS_UPPER => 1 });

  return $list->[0] || {};
}

#**********************************************************
=head2 terminals_add($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    1

=cut
#**********************************************************
sub terminal_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('paysys_terminals', $attr);

  return $self;
}

#**********************************************************
=head2 terminal_del($attr)

  Arguments:
    $attr - hash_ref

  Returns:
   1

=cut
#**********************************************************
sub terminal_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('paysys_terminals', $attr);

  if (!$self->{errno}) {
    $self->{admin}->{MODULE} = 'Paysys';
    $admin->system_action_add("TERMINAL DELETE", { TYPE => 10 });
  }

  return $self;
}

#**********************************************************
=head2 terminal_change($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    1

=cut
#**********************************************************
sub terminal_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'paysys_terminals',
    DATA         => $attr,
  });

  return $self;
}

#**********************************************************
=head2 terminal_info($id)

  Arguments:
    $id - id for terminals

  Returns:
    hash_ref

=cut
#**********************************************************
sub terminal_type_info {
  my $self = shift;
  my ($id) = @_;

  my $list = $self->terminal_type_list( { COLS_NAME => 1, ID => $id, SHOW_ALL_COLUMNS => 1, COLS_UPPER => 1 } );

  return $list->[0] || {};
}

#**********************************************************
=head2 terminals_add($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    1

=cut
#**********************************************************
sub terminals_type_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('paysys_terminals_types', $attr);

  return $self;
}

#**********************************************************
=head2 terminal_type_delete($attr)

  Arguments:
    $attr - hash_ref

  Returns:
   1

=cut
#**********************************************************
sub terminal_type_delete {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('paysys_terminals_types', $attr);

  return $self;
}

#**********************************************************
=head2 terminal_change($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    1

=cut
#**********************************************************
sub terminal_type_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'paysys_terminals_types',
    DATA         => $attr,
  });

  return $self;
}

#**********************************************************
=head2 terminal_type_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut
#**********************************************************
sub terminal_type_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 'ptt.id';
  my $DESC = ($attr->{DESC}) ? 'DESC' : '';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $search_columns = [
    ['ID',      'INT', 'ptt.id',      1],
    ['NAME',    'STR', 'ptt.name',    1],
    ['COMMENT', 'STR', 'ptt.comment', 1],
  ];

  if ($attr->{SHOW_ALL_COLUMNS}){
    map { $attr->{$_->[0]} = '_SHOW' unless exists $attr->{$_->[0]} } @$search_columns;
  }

  my $WHERE = $self->search_former($attr, $search_columns, {
    WHERE => 1
  });

  $self->query( "SELECT $self->{SEARCH_FIELDS} ptt.id
  FROM paysys_terminals_types ptt

  $WHERE ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;", undef, {
    COLS_NAME => 1,
    COLS_UPPER => 1,
    %{ $attr ? $attr : {}}}
  );

  return [] if $self->{errno};

  return $self->{list} || [];
}

#**********************************************************
=head2 add_tyme_report() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub add_tyme_report {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('paysys_tyme_report', { %$attr });

  return $self;
}

#**********************************************************
=head2 list_tyme_report($attr)

  Arguments:


  Returns:

=cut
#**********************************************************
sub list_tyme_report {
  my $self = shift;
  my ($attr) = @_;

  delete $self->{COL_NAMES_ARR};

  my @WHERE_RULES = ();
  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 5;
  my $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : 'desc';
  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 500;

  my $WHERE = $self->search_former($attr, [
    ['ID',             'STR',  'ptr.id',              ],
    ['TXN_ID',         'STR',  'ptr.txn_id',         1],
    ['SUM',            'STR',  'ptr.sum',            1],
    ['DATE',           'DATE', 'ptr.date',           1],
    ['TERMINAL_LOCATION',   'STR',         "IF(pt.location_id, CONCAT(d.name, ', ', s.name, ', ',  b.number), '') AS terminal_location"        , 1 ],
  ], {
    WHERE            => 1,
    USE_USER_PI      => 1,
    USERS_FIELDS_PRE => 1,
    WHERE_RULES      => \@WHERE_RULES,
  });

  if($attr->{TERMINAL} && $attr->{TERMINAL} ne '_SHOW'){
    push @WHERE_RULES, "ptr.terminal = '$attr->{TERMINAL}'";
  }

  if($attr->{DATE_FROM} && $attr->{DATE_TO}){
    push @WHERE_RULES, "ptr.date >= '$attr->{DATE_FROM} 00:00:01' and ptr.date <= '$attr->{DATE_TO} 23:59:59'";
  }

  $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

  $self->query(
    "SELECT
    $self->{SEARCH_FIELDS}
    pi.uid
    FROM paysys_tyme_report as ptr
    LEFT JOIN users u ON u.uid=ptr.user
    LEFT JOIN users_pi pi ON pi.uid=ptr.user
    LEFT JOIN paysys_terminals pt ON pt.comment=ptr.terminal
    LEFT JOIN builds b ON (b.id = pt.location_id)
    LEFT JOIN streets s ON (s.id = b.street_id)
    LEFT JOIN districts d ON (d.id = s.district_id)
    $WHERE
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list} || [];

  return [] if ($attr->{TOTAL} < 1);

  $self->query(
    "SELECT COUNT(*) AS total
     FROM paysys_tyme_report",
    undef,
    { INFO => 1 }
  );

  return $list;
}

#**********************************************************
=head2 list_tyme_report($attr)

  Arguments:
    $attr - hash_ref

  Returns:
   1

=cut
#**********************************************************
sub del_tyme_report {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('paysys_tyme_report', $attr);

  return $self;
}

#**********************************************************
=head2 groups_settings_del()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub groups_settings_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('paysys_groups_settings', undef, $attr);

  if (!$self->{errno}) {
    $self->{admin}->{MODULE} = 'Paysys';
    $admin->system_action_add("DELETE MERCHANT $attr->{GID} PARAMS: $attr->{ID}", { TYPE => 10 });
  }

  return $self;
}

#**********************************************************
=head2 groups_settings_add_user_portal($attr)

  Arguments:
    $attr -

  Returns:

=cut
#**********************************************************
sub groups_settings_add_user_portal {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('paysys_groups_settings', {
    %{$attr},
    DOMAIN_ID => $admin->{DOMAIN_ID} || $attr->{DOMAIN_ID} || 0,
  }, { REPLACE => ($attr->{REPLACE}) ? 1 : undef });

  if (!$self->{errno}) {
    $self->{admin}->{MODULE} = 'Paysys';
    $admin->system_action_add("ADD GROUP_SETTINGS: $attr->{NAME} PAYSYS: $attr->{PAYSYS_ID}", { TYPE => 1 });
  }

  return $self;
}

#**********************************************************
=head2 groups_settings_add($attr)

  Arguments:
    $attr -

  Returns:

=cut
#**********************************************************
sub groups_settings_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 'psg.id';
  my $DESC = ($attr->{DESC}) ? 'DESC' : '';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  $attr->{DOMAIN_ID} ||= $admin->{DOMAIN_ID} || '_SHOW';

  my $search_columns = [
    [ 'ID',            'INT', 'psg.id',         1 ],
    [ 'GID',           'INT', 'psg.gid',        1 ],
    [ 'PAYSYS_ID',     'INT', 'psg.paysys_id',  1 ],
    [ 'DOMAIN_ID',     'INT', 'psg.domain_id',  1 ],
  ];

  if ($attr->{SHOW_ALL_COLUMNS}){
    map { $attr->{$_->[0]} = '_SHOW' unless exists $attr->{$_->[0]} } @$search_columns;
  }

  my $WHERE = $self->search_former($attr, $search_columns, {
    WHERE => 1
  });

  $self->query( "SELECT $self->{SEARCH_FIELDS} psg.id
  FROM paysys_groups_settings psg
  $WHERE
  ORDER BY $SORT $DESC
  LIMIT $PG, $PAGE_ROWS;", undef, {
    COLS_UPPER => 1,
    %{ $attr ? $attr : {}}}
  );

  return [] if $self->{errno} || $self->{TOTAL} == 0;

  return $self->{list} || [];
}

#**********************************************************
=head2 connect()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub paysys_connect_system_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('paysys_connect', {
    %$attr,
  });

  if (!$self->{errno}) {
    $self->{admin}->{MODULE} = 'Paysys';
    $admin->system_action_add("ADD PAYSYS_SYSTEM: $attr->{NAME} ID: $attr->{PAYSYS_ID}", { TYPE => 1 });
  }

  return $self;
}

#**********************************************************
=head2 del_connect_system()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub paysys_connect_system_delete {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('paysys_connect', $attr);

  if (!$self->{errno}) {
    $self->{admin}->{MODULE} = 'Paysys';
    $admin->system_action_add("DELETE PAYSYS_SYSTEM:  $attr->{MODULE} ID: $attr->{PAYSYSTEM_ID}", { TYPE => 10 });
  }

  return $self;
}

#**********************************************************
=head2 paysys_connect_system_list()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub paysys_connect_system_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 'pc.id';
  my $DESC = ($attr->{DESC}) ? 'DESC' : '';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $search_columns = [
    [ 'ID',             'INT', 'pc.id',             1 ],
    [ 'PAYSYS_ID',      'INT', 'pc.paysys_id',      1 ],
    [ 'NAME',           'STR', 'pc.name',           1 ],
    [ 'MODULE',         'STR', 'pc.module',         1 ],
    [ 'STATUS',         'INT', 'pc.status',         1 ],
    [ 'PAYMENT_METHOD', 'INT', 'pc.payment_method', 1 ],
    [ 'IP',             'STR', 'pc.paysys_ip',      1 ],
    [ 'PRIORITY',       'INT', 'pc.priority',       1 ],
    [ 'SUBSYSTEM_ID',   'INT', 'pc.subsystem_id',   1 ],
  ];

  if ($attr->{SHOW_ALL_COLUMNS}){
    map { $attr->{$_->[0]} = '_SHOW' unless exists $attr->{$_->[0]} } @$search_columns;
  }

  my $WHERE =  $self->search_former($attr, $search_columns,
    {
      WHERE => 1
    }
  );

  $self->query( "SELECT $self->{SEARCH_FIELDS} pc.id
  FROM paysys_connect pc
  $WHERE
  ORDER BY $SORT $DESC
  LIMIT $PG, $PAGE_ROWS;", undef, {
    %{ $attr // {}}}
  );

  return [] if $self->{errno};

  return $self->{list} || [];
}

#**********************************************************
=head2 crm_actions_info()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub paysys_connect_system_info {
  my $self = shift;
  my ($attr) = @_;

  my $connect_system_info = $self->paysys_connect_system_list({ %$attr });

  if ($connect_system_info && ref $connect_system_info eq 'ARRAY' && scalar @{$connect_system_info} == 1) {
    return $connect_system_info->[0];
  }
  else {
    return {};
  }
}

#**********************************************************
=head2 change_connect_system($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    1

=cut
#**********************************************************
sub paysys_connect_system_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'paysys_connect',
    DATA         => $attr,
  });

  if (!$self->{errno}) {
    $self->{admin}->{MODULE} = 'Paysys';
    $admin->system_action_add("CHANGE  PAYSYS_SYSTEM: $attr->{NAME} ID: $attr->{PAYSYS_ID}", { TYPE => 2 });
  }

  return $self;
}

#**********************************************************
=head2 paysys_report_add($attr) - add data to db

 Arguments:
    $attr -
      PAYSYS_REPORT_TABLE - Report table name

  Returns:
    $self
  Examples:

=cut
#**********************************************************
sub paysys_report_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add("$attr->{TABLE}", {
    %$attr,
  });

  return $self;
}

#**********************************************************
=head2 paysys_report_list()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub paysys_report_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 'id';
  my $DESC = ($attr->{DESC}) ? 'DESC' : '';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $search_columns = [
    [ 'ID', 'INT', 'id', 1 ],
  ];

  if ($attr->{SHOW_ALL_COLUMNS}) {
    map {$attr->{$_->[0]} = '_SHOW' unless exists $attr->{$_->[0]}} @$search_columns;
  }

  my $WHERE = $self->search_former($attr, $search_columns,
    {
      WHERE => 1
    }
  );

  $self->query("SELECT *
  FROM ". $attr->{TABLE} ."
  $WHERE ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;", undef, {
    %{$attr // {}} }
  );

  return [] if $self->{errno};

  return $self->{list} || [];
}

#**********************************************************
=head2 paysys_easypay_list($attr) - list for easypay report

  Arguments:
    $attr -

  Returns:

=cut
#**********************************************************
sub paysys_easypay_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT        = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC        = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG          = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS   = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $WHERE = $self->search_former(
    $attr,
    [
      [ 'ID', 'INT', 'id', 1 ],
      [ 'UID', 'INT', 'uid', 1 ],
      [ 'SUM', 'STR', 'sum', 1 ],
      [ 'PROV_BILL', 'INT', 'prov_bill', 1 ],
      [ 'MFO', 'INT', 'mfo', 1 ],
      [ 'BANK_NAME', 'STR', 'bank_name', 1 ],
      [ 'CLIENT_CMSN', 'INT', 'client_cmsn', 1 ],
      [ 'COMMISSION', 'INT', 'commission', 1 ],
      [ 'CURRENCY', 'INT', 'currency', 1 ],
      [ 'DATE', 'SRT', 'date', 1 ],
      [ 'DESCRIPTION', 'STR', 'description', 1 ],
      [ 'PROV_NAME', 'STR', 'prov_name', 1 ],
      [ 'OKPO', 'INT', 'okpo', 1 ],
      [ 'COMPANY_NAME', 'STR', 'company_name', 1 ],
      [ 'TERMINAL_ID', 'INT', 'terminal_id', 1 ],
      [ 'TRANSACTION_ID', 'INT', 'transaction_id', 1 ],
    ],
    {
      WHERE       => 1,
    }
  );

  $self->query(
    "SELECT
    $self->{SEARCH_FIELDS}
    id
    FROM paysys_easypay_report
    $WHERE
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list} || [];

  return $self->{list} if ($self->{TOTAL} < 1);

  $self->query(
    "SELECT COUNT(*) AS total
   FROM paysys_easypay_report
   $WHERE",
    undef,
    { INFO => 1 }
  );

  return $list;
}

#**********************************************************
=head2 merchant_settings_delete()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub merchant_settings_delete {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('paysys_merchant_settings', $attr);

  my $value = '';

  foreach  my $key (keys %{$self->{list_hash}}){
    $value .= "$key => $self->{list_hash}{$key}\n";
  }

  if (!$self->{errno}) {
    $self->{admin}->{MODULE} = 'Paysys';
    $admin->system_action_add("DELETE MERCHANT $value PARAMS: $attr->{MERCHANT_ID}", { TYPE => 10 });
  }

  return $self;
}

#**********************************************************
=head2 merchant_settings_add($attr)

  Arguments:
    $attr -

  Returns:

=cut
#**********************************************************
sub merchant_settings_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('paysys_merchant_settings', {
    %$attr,
    DOMAIN_ID => $admin->{DOMAIN_ID} || $attr->{DOMAIN_ID} || 0,
  });

  if (!$self->{errno}) {
    $self->{admin}->{MODULE} = 'Paysys';
    $admin->system_action_add("MERCHANT_NAME: $attr->{MERCHANT_NAME} SYSTEM_ID: $attr->{SYSTEM_ID}", { TYPE => 1 });
  }

  return $self;
}

#**********************************************************
=head2 merchant_settings_change($attr)

  Arguments:
    $attr -

  Returns:

=cut
#**********************************************************
sub merchant_settings_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'paysys_merchant_settings',
    DATA         => $attr
  });

  if (!$self->{errno}) {
    $self->{admin}->{MODULE} = 'Paysys';
    $admin->system_action_add("CHANGE MERCHANT $attr->{MERCHANT_NAME} SYSTEM_ID: $attr->{SYSTEM_ID}", { TYPE => 2 });
  }

  return $self;
}

#**********************************************************
=head2 merchant_params_list($attr)

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub merchant_params_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  my $WHERE = $self->search_former($attr, [
    [ 'ID',           'INT', 'pmp.id',          1 ],
    [ 'PARAM',        'STR', 'pmp.param',       1 ],
    [ 'VALUE',        'STR', 'pmp.value',       1 ],
    [ 'MERCHANT_ID',  'INT', 'pmp.merchant_id', 1 ],
  ], { WHERE => 1, }
  );

  $self->query(
    "SELECT id, param, value, merchant_id
    FROM paysys_merchant_params pmp
    $WHERE
    ORDER BY $SORT $DESC;",
    undef,
    $attr
  );

  return $self->{list} || [];
}

#**********************************************************
=head2 merchant_params_add($attr)

  Arguments:
    $attr -

  Returns:

=cut
#**********************************************************
sub merchant_params_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('paysys_merchant_params', {
    %$attr,
    DOMAIN_ID => $admin->{DOMAIN_ID} || $attr->{DOMAIN_ID} || 0,
  });

  return $self;
}

#**********************************************************
=head2 merchant_params_change($attr)

  Arguments:
    $attr -

  Returns:

=cut
#**********************************************************
sub merchant_params_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'paysys_merchant_params',
    DATA         => $attr
  });

  return $self;
}

#**********************************************************
=head2 merchant_params_delete($attr)

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub merchant_params_delete {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('paysys_merchant_params', undef, $attr);

  return $self;
}

#**********************************************************
=head2 merchant_settings_list($attr)

  Arguments:
    $attr -

  Returns:

=cut
#**********************************************************
sub merchant_settings_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT        = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC        = ($attr->{DESC}) ? $attr->{DESC} : 'desc';

  $attr->{DOMAIN_ID} ||= $admin->{DOMAIN_ID} || '_SHOW';

  my $WHERE = $self->search_former($attr, [
    [ 'ID',            'INT', 'pms.id',            1 ],
    [ 'MERCHANT_NAME', 'STR', 'pms.merchant_name', 1 ],
    [ 'SYSTEM_ID',     'INT', 'pms.system_id',     1 ],
    [ 'PAYSYSTEM_NAME','STR', 'pc.name',           1 ],
    [ 'MODULE',        'STR', 'pc.module',         1 ],
    [ 'DOMAIN_ID',     'INT', 'pms.domain_id',     1 ],
  ], { WHERE => 1, }
  );

  if ($attr->{PAYSYS_ID}) {
    my $query = "pms.system_id = (SELECT id FROM paysys_connect WHERE paysys_id = '$attr->{PAYSYS_ID}')";
    $WHERE = ($WHERE) ? "$WHERE AND $query" : " WHERE $query";
  }

  $self->query(
    "SELECT  $self->{SEARCH_FIELDS} pms.id
    FROM paysys_merchant_settings pms
    LEFT JOIN paysys_connect pc
    ON (pms.system_id = pc.id)
    $WHERE
    ORDER BY $SORT $DESC;",
    undef,
    $attr
  );

  return ($self->{list_hash} || {}) if ($attr->{LIST2HASH});

  my $list = $self->{list} || [];

  return $list if ($self->{TOTAL} < 1);

  $self->query(
    "SELECT COUNT(*) AS total
   FROM paysys_merchant_settings pms
   LEFT JOIN paysys_connect pc ON (pms.system_id = pc.id)
   $WHERE",
    undef,
    { INFO => 1 }
  );

  return $list;
}

#**********************************************************
=head2 merchant_params_info($attr)

  Arguments:
    $attr

  Returns:

=cut
#**********************************************************
sub merchant_params_info {
  my $self = shift;
  my ($attr) = @_;

  $self->query("SELECT param,value
    FROM paysys_merchant_params
    WHERE merchant_id= ? ;",
    undef,
    { Bind => [ $attr->{MERCHANT_ID} ], LIST2HASH => 'param,value' });

  my $hash = $self->{list_hash} || {};
  $self->{list_hash} = {};

  return $hash;
}

#**********************************************************
=head2 paysys_merchant_to_groups_add($attr)

  Arguments:
    $attr

  Returns:

=cut
#**********************************************************
sub paysys_merchant_to_groups_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('paysys_merchant_to_groups_settings', {
    %$attr,
    DOMAIN_ID => $admin->{DOMAIN_ID} || $attr->{DOMAIN_ID} || 0,
  }, { REPLACE => ($attr->{REPLACE}) ? 1 : undef });

  if (!$self->{errno}) {
    $self->{admin}->{MODULE} = 'Paysys';
    $admin->system_action_add("ADD GROUP_SETTINGS_MERCH $attr->{PAYSYS_ID} GROUPS: $attr->{GID}", { TYPE => 1 });
  }

  return $self;
}

#**********************************************************
=head2 paysys_merchant_to_groups_delete()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub paysys_merchant_to_groups_delete {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('paysys_merchant_to_groups_settings', undef, { %$attr, DOMAIN_ID => $admin->{DOMAIN_ID} || $attr->{DOMAIN_ID} || 0, });

  if (!$self->{errno}) {
    $self->{admin}->{MODULE} = 'Paysys';
    $admin->system_action_add("DELETE GROUP_SETTINGS_MERCH $attr->{PAYSYS_ID} GROUPS: $attr->{GID}", { TYPE => 10 });
  }

  return $self;
}

#**********************************************************
=head2 paysys_merchant_to_groups_info($attr)

  Arguments:
    $attr -

  Returns:

=cut
#**********************************************************
sub paysys_merchant_to_groups_info {
  my $self = shift;
  my ($attr) = @_;

  $attr->{DOMAIN_ID} ||= $admin->{DOMAIN_ID} || '_SHOW';

  my $WHERE = $self->search_former($attr, [
    [ 'DOMAIN_ID', 'INT', 'pms.domain_id',  1 ],
  ],
    { WHERE => 1 }
  );

  $self->query("SELECT *
    FROM paysys_merchant_to_groups_settings pmtg
    LEFT JOIN paysys_merchant_settings pms ON (pmtg.merch_id = pms.id) $WHERE ;",
    undef,
    $attr
  );

  return $self->{list} || [];
}

#**********************************************************
=head2 merchant_for_group_list($attr)

=cut
#**********************************************************
sub merchant_for_group_list {
  my $self = shift;
  my ($attr) = @_;

  delete $self->{list_hash};

  $attr->{DOMAIN_ID} ||= $admin->{DOMAIN_ID} || '_SHOW';

  my $WHERE = $self->search_former($attr, [
    [ 'GID',       'INT', 'gid',        1 ],
    [ 'PAYSYS_ID', 'INT', 'paysys_id',  1 ],
    [ 'MERCH_ID',  'INT', 'merch_id',   1 ],
    [ 'ID',        'INT', 'id',           ],
    [ 'DOMAIN_ID', 'INT', 'domain_id',  1 ],
  ],
    { WHERE => 1 }
  );

  $self->query("SELECT $self->{SEARCH_FIELDS} id
    FROM paysys_merchant_to_groups_settings
    $WHERE ;",
    undef,
    $attr
  );

  return $self->{list_hash} if ($attr->{LIST2HASH});

  return $self->{list} || [];
}

#**********************************************************
=head2 function info_fields() -

  Returns:


  Examples:


=cut
#**********************************************************
sub info_fields {
  my $self = shift;
  my ($attr) = @_;

  $self->query('SELECT * FROM users_pi AS up WHERE up._code_edrpoy = ? ;',
    undef, { Bind => [ $attr->{VALUE} ] }
  );

  return $self->{list} || [];
}

#**********************************************************
=head2 log_add() - add info of request on paysys_check.cgi

  Arguments:
    SYSTEM_ID: int      - pay system id
    TRANSACTION_ID: int - id of transaction
    ERROR: string       - info about error code or message
    STATUS: int         - status of requests - finished or not
    IP: strint2int      - ip address of request
    DATETIME: string    - date of request
    UID: int            - uid of user (if determined)
    REQUEST: string     - original body of request
    RESPONSE: string    - original body of response
    HTTP_METHOD:        - http method or request GET, POST, etc
  Returns:
    self object;

=cut
#**********************************************************
sub log_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('paysys_requests', {
    %$attr,
    DATETIME  => $attr->{DATETIME} || 'NOW()',
    PAYSYS_IP => "INET_ATON('" . ($attr->{PAYSYS_IP} || '0.0.0.0') . "')",
  });

  return $self;
}

#**********************************************************
=head2 log_del() - delete info of request on paysys_check.cgi

  Arguments:
    $id: number of request

  Returns:
    self object;

  Examples:
    $Paysys->log_del($FORM{del});

=cut
#**********************************************************
sub log_del {
  my $self = shift;
  my ($id) = @_;

  $self->query_del('paysys_requests', { ID => $id });

  if (!$self->{errno}) {
    $self->{admin}->{MODULE} = 'Paysys';
    $admin->system_action_add("DELETE access_log: $id", { TYPE => 10 });
  }

  return $self;
}

#**********************************************************
=head2 log_change () - change info of requests on paysys_check.cgi

  Arguments:
    SYSTEM_ID: int      - pay system id
    TRANSACTION_ID: int - id of transaction
    ERROR: string       - info about error code or message
    STATUS: int         - status of requests - finished or not
    IP: strint2int      - ip address of request
    DATETIME: string    - date of request
    UID: int            - uid of user (if determined)
    REQUEST: string     - original body of request
    RESPONSE: string    - original body of response
    HTTP_METHOD:        - http method or request GET, POST, etc

  Returns:
    self object;

=cut
#**********************************************************
sub log_change {
  my $self = shift;
  my ($attr) = @_;

  if ($attr->{PAYSYS_IP}) {
    $attr->{PAYSYS_IP} = "INET_ATON('" . $attr->{PAYSYS_IP} . "')";
  }

  $self->{admin}->{MODULE} = 'Paysys';

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'paysys_requests',
    DATA         => $attr
  });

  return $self;
}

#**********************************************************
=head2 function log_list() - history of request on paysys_check.cgi

  Arguments:
    SYSTEM_ID: int            - pay system id
    TRANSACTION_ID: int       - id of transaction
    ERROR: string             - info about error code or message
    STATUS: int               - status of requests - finished or not
    IP: strint2int            - ip address of request
    DATETIME: string          - date of request
    UID: int                  - uid of user (if determined)
    REQUEST: string           - original body of request
    RESPONSE: string          - original body of response
    HTTP_METHOD: string       - http method or request GET, POST, etc
    FROM_DATE|TO_DATE: string - start or end date of request
  Returns:
    self object;

  Examples:
    my $list = $Paysys->log_list({ ... });

=cut
#**********************************************************
sub log_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  my $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $WHERE = $self->search_former($attr, [
    [ 'ID',                 'INT',    'pr.id',                                          1],
    [ 'BILL_ID',            'INT',    'u.bill_id',                                      1],
    [ 'LOGIN',              'STR',    'u.id as login',                                  1],
    [ 'SYSTEM_ID',          'INT',    'pr.system_id',                                   1],
    [ 'TRANSACTION_ID',     'INT',    'pr.transaction_id',                              1],
    [ 'EXT_ID',             'STR',    'ps.transaction_id as ext_id',                    1],
    [ 'SUM',                'INT',    'pr.sum',                                         1],
    [ 'REQUEST_TYPE',       'INT',    'pr.request_type',                                1],
    [ 'ERROR',              'STR',    'pr.error',                                       1],
    [ 'STATUS',             'INT',    'pr.status',                                      1],
    [ 'IP',                 'IP',     'pr.paysys_ip', 'INET_NTOA(pr.paysys_ip) AS ip',  1],
    [ 'DATETIME',           'DATE',   'pr.datetime',                                    1],
    [ 'REQUEST',            'STR',    'pr.request',                                     1],
    [ 'RESPONSE',           'STR',    'pr.response',                                    1],
    [ 'HTTP_METHOD',        'STR',    'pr.http_method',                                 1],
    [ 'FROM_DATE|TO_DATE',  'DATE',   "DATE_FORMAT(pr.datetime, '%Y-%m-%d')",           1],
    [ 'UID',                'INT',    'pr.uid',                                         1],
  ],
    { WHERE => 1 }
  );

  $self->query("
    SELECT
      $self->{SEARCH_FIELDS}
      pc.name as paysys_name,
      pr.uid
    FROM paysys_requests pr
    LEFT JOIN paysys_connect pc ON (pc.paysys_id=pr.system_id)
    LEFT JOIN paysys_log ps ON (ps.id=pr.transaction_id)
    LEFT JOIN users u ON (u.uid=pr.uid)
    $WHERE
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;",
    undef,
    { %$attr,
      COLS_NAME  => 1,
      COLS_UPPER => 1
    }
  );

  my $list = $self->{list} || [];

  return [] if ($self->{errno} || $self->{TOTAL} < 1);

  $self->query("SELECT COUNT(pr.id) AS total
   FROM paysys_requests pr
   LEFT JOIN paysys_connect pc ON (pc.paysys_id=pr.system_id)
   LEFT JOIN paysys_log ps ON (ps.id=pr.transaction_id)
   LEFT JOIN users u ON (u.uid=pr.uid)
   $WHERE",
    undef,
    { INFO => 1 }
  );

  return $list;
}

#**********************************************************
=head2 gid_params() - list of group params

=cut
#**********************************************************
sub gid_params {
  my $self = shift;
  my ($attr) = @_;

  $attr->{GID} .= ',0' if ($attr->{GID});

  $self->query(
    "SELECT * FROM paysys_merchant_params WHERE merchant_id = (
      SELECT merch_id FROM paysys_merchant_to_groups_settings WHERE gid = ? and paysys_id =
       (select id from paysys_connect where paysys_id = ?))",
    undef,
    {
      Bind      => [ defined $attr->{GID} ? $attr->{GID} : '--', $attr->{PAYSYS_ID} || '--' ],
      LIST2HASH => $attr->{LIST2HASH} || '',
      INFO      => $attr->{LIST2HASH} ? 0 : 1,
      COLS_NAME => $attr->{LIST2HASH} ? 0 : 1
    });

  if ($attr->{LIST2HASH}) {
    my $hash = $self->{list_hash} || {};
    $self->{list_hash} = {};
    return $hash;
  }

  my $list = $self->{list} || [];

  return $list;
}

=head1 COPYRIGHT

  Copyright (с) 2003-2023 Andy Gulay (ABillS DevTeam) Ukraine
  All rights reserved.
  https://axbills.net.ua/

=cut

1;
