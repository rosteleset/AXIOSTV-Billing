package Bonus;

=head1 NAME

 Bonus modules

=cut

use strict;
use parent 'dbcore';

use Tariffs;
use Users;
use Fees;
use Bills;

our $VERSION = 2.08;

my $Bill;
my $MODULE = 'Bonus';
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
  $self->{admin}=$admin;
  $self->{conf}=$CONF;

  $Bill = Bills->new($db, $admin, $CONF);

  return $self;
}

#**********************************************************
# User information
# info()
#**********************************************************
sub info {
  my $self = shift;
  my ($id) = @_;

  $self->query('SELECT *
    FROM bonus_main
    WHERE id = ? ;',
    undef,
    { INFO => 1,
      Bind => [ $id ] }
  );

  return $self;
}

#**********************************************************
#
#**********************************************************
sub defaults {
  my $self = shift;

  my %DATA = (
    TP_ID          => 0,
    PERIOD         => 0,
    RANGE_BEGIN    => 0,
    RANGE_END      => 0,
    SUM            => '0.00',
    COMMENTS       => '',
    EXPIRE         => '0000-00-00',
    DESCRIBE       => '',
    METHOD         => 0,
    EXT_ID         => '',
    INNER_DESCRIBE => ''
  );

  $self = \%DATA;
  return $self;
}

#**********************************************************
# change()
#**********************************************************
sub change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'bonus_main',
      DATA         => $attr
    }
  );

  return $self->{result};
}


#**********************************************************
# list()
#**********************************************************
sub list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  my $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';

  my @WHERE_RULES = ();
  my $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

  $self->query("SELECT tp_id, period, range_begin, range_end, sum, comments, id
     FROM bonus_main
     $WHERE 
     ORDER BY $SORT $DESC;",
     undef,
     $attr
  );

  return [ ] if ($self->{errno});

  my $list = $self->{list};

  if ($self->{TOTAL} >= 0) {
    $self->query("SELECT count(b.id) AS total FROM bonus_main b $WHERE", undef, { INFO => 1 });
  }

  return $list;
}

#**********************************************************
# Periodic
#**********************************************************
sub periodic {
  my $self = shift;
  my ($period) = @_;

  if ($period eq 'daily') {
    #$self->daily_fees();
  }

  return $self;
}

#**********************************************************
# 
# tp_info()
#**********************************************************
sub tp_info {
  my $self = shift;
  my ($id) = @_;

  $self->query("SELECT id AS tp_id, 
    name,
    state
     FROM bonus_tps 
   WHERE id = ?;",
   undef,
   { INFO => 1,
     Bind => [ $id ] }
  );

  return $self;
}

#**********************************************************
# tp_add()
#**********************************************************
sub tp_add {
  my $self   = shift;
  my ($attr) = @_;

  $self->query_add('bonus_tps', $attr);

  return $self;
}

#**********************************************************
# change()
#**********************************************************
sub tp_change {
  my $self = shift;
  my ($attr) = @_;

  $attr->{STATE} = ($attr->{STATE}) ? 1 : 0;

  $self->changes(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'bonus_tps',
      DATA         => $attr
    }
  );
  return $self->{result};
}

#**********************************************************
# Delete user info from all tables
#
# del(attr);
#**********************************************************
sub tp_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('bonus_tps', $attr);

  return $self->{result};
}

#**********************************************************
# list()
#**********************************************************
sub tp_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  my $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';

  my @WHERE_RULES = ();
  my $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

  $self->query("SELECT *
     FROM bonus_tps
     $WHERE 
     ORDER BY $SORT $DESC;",
     undef,
     $attr
  );

  return [ ] if ($self->{errno});

  my $list = $self->{list};

  if ($self->{TOTAL} >= 0) {
    $self->query("SELECT count(b.id) AS total FROM bonus_tps b $WHERE", undef, { INFO => 1 });
  }

  return $list;
}

#**********************************************************
# User information
# rule_info()
#**********************************************************
sub rule_info {
  my $self = shift;
  my ($id) = @_;

  $self->query("SELECT tp_id,
    period,
    rules,
    rule_value,
    actions,
    id
     FROM bonus_rules 
   WHERE id = ? ;",
   undef,
   { INFO => 1,
     Bind => [ $id ] 
    }
  );

  return $self;
}

#**********************************************************
# tp_add()
#**********************************************************
sub rule_add {
  my $self   = shift;
  my ($attr) = @_;

  $self->query_add('bonus_rules', $attr);

  return $self;
}

#**********************************************************
# change()
#**********************************************************
sub rule_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'bonus_rules',
      DATA         => $attr
    }
  );

  return $self;
}

#**********************************************************
# Delete user info from all tables
#
# del(attr);
#**********************************************************
sub rule_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('bonus_rules', $attr);

  return $self;
}

#**********************************************************
# list()
#**********************************************************
sub rule_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  my @WHERE_RULES = ();
  if ($attr->{TP_ID}) {
    push @WHERE_RULES, "tp_id='$attr->{TP_ID}'";
  }

  my $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

  $self->query("SELECT period, rules, rule_value, actions, id
     FROM bonus_rules
     $WHERE 
     ORDER BY $SORT $DESC;",
     undef,
     $attr
  );

  return [ ] if ($self->{errno});

  my $list = $self->{list};

  return $list;
}

#**********************************************************
=head2 user_info()

=cut
#**********************************************************
sub user_info {
  my $self = shift;
  my ($id) = @_;

  $self->query("SELECT uid,
    tp_id,
    state,
    accept_rules
     FROM bonus_main
   WHERE uid = ?;",
   undef,
   { INFO => 1,
     Bind => [ $id ] }
  );

  return $self;
}

#**********************************************************
=head2 user_add()

=cut
#**********************************************************
sub user_add {
  my $self   = shift;
  my ($attr) = @_;

  $attr->{STATE} = 1;

  $self->query_add('bonus_main',  $attr);

  if ($CONF->{BONUS_ACCOMULATION}){
    $self->accomulation_first_rule($attr);
  }

  $admin->{MODULE} = $MODULE;
  $admin->action_add("$attr->{UID}", "", { TYPE => 1 });

  return $self;
}

#**********************************************************
=head2 user_change($attr)

=cut
#**********************************************************
sub user_change {
  my $self = shift;
  my ($attr) = @_;

  $attr->{STATE} = ($attr->{STATE}) ? $attr->{STATE} : 0;

  $admin->{MODULE} = $MODULE;

  $attr->{ACCEPT_RULES} = ($attr->{ACCEPT_RULES}) ? 1 : 0;
 
  $self->changes(
    {
      CHANGE_PARAM => 'UID',
      TABLE        => 'bonus_main',
      DATA         => $attr
    }
  );

  return $self;
}

#**********************************************************
=head2 user_del($attr)

=cut
#**********************************************************
sub user_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('bonus_main', undef, { uid => $attr->{UID} });

  return $self;
}

#**********************************************************
=head2 user_list($attr)

=cut
#**********************************************************
sub user_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  my $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my @WHERE_RULES = ("bu.uid = u.uid");
  $self->{EXT_TABLES}='';

  my $WHERE =  $self->search_former($attr, [
      ['TP_ID',          'INT', 'bu.tp_id',  1 ],
      ['DV_TP_ID',       'INT', 'tp.tp_id',  1 ],
      ['TP_NAME',        'STR', 'b_tp.name', 'b_tp.name AS tp_name' ],
      ['STATE',          'INT', 'bu.state',  1 ],
      ['BONUS_ACCOMULATION', '', '', 'ras.cost'],
    ],
  { WHERE             => 1,
    WHERE_RULES       => \@WHERE_RULES,
    USERS_FIELDS_PRE  => 1,
    USE_USER_PI       => 1
  });

  my $EXT_TABLE = q{};

  $EXT_TABLE = $self->{EXT_TABLES} if ($self->{EXT_TABLES});

  if ($CONF->{BONUS_ACCOMULATION}){
    $EXT_TABLE .= "LEFT JOIN bonus_rules_accomulation_scores ras ON (ras.uid = u.uid)";
  }

  if ($attr->{DV_TP_ID}) {
    $EXT_TABLE .= "LEFT JOIN internet_main internet ON (internet.uid = u.uid)
      LEFT JOIN tarif_plans tp  ON (tp.tp_id = internet.tp_id)
    ";
  }

  $self->query("SELECT $self->{SEARCH_FIELDS}
       bu.uid
     FROM (bonus_main bu, users u)
     LEFT JOIN bonus_tps b_tp ON (b_tp.id=bu.tp_id)
     $EXT_TABLE
     $WHERE
     ORDER BY $SORT $DESC
     LIMIT $PG, $PAGE_ROWS;",
     undef,
     $attr
  );

  my $list = $self->{list};

  $self->query("SELECT COUNT(DISTINCT bu.uid) AS total
     FROM (bonus_main bu, users u)
     LEFT JOIN bonus_tps b_tp ON (b_tp.id=bu.tp_id)
     $EXT_TABLE
     $WHERE;",
     undef,
     { INFO => 1 }
  );

  return $list;
}

#**********************************************************
=head2 bonus_operation($user, $attr)

=cut
#**********************************************************
sub bonus_operation {
  my $self = shift;
  my ($user, $attr) = @_;

  if ($attr->{SUM} <= 0) {
    $self->{errno}  = 12;
    $self->{errstr} = 'ERROR_ENTER_SUM';
    return $self;
  }

  if ($attr->{CHECK_EXT_ID}) {
    $self->query("SELECT id, date FROM bonus_log WHERE ext_id='$attr->{CHECK_EXT_ID}';");
    if ($self->{TOTAL} > 0) {
      $self->{errno}  = 7;
      $self->{errstr} = 'ERROR_DUPLICATE';
      $self->{ID}     = $self->{list}->[0][0];
      $self->{DATE}   = $self->{list}->[0][1];
      return $self;
    }
  }

  $user->{EXT_BILL_ID} = $attr->{BILL_ID} if ($attr->{BILL_ID});

  if ($user->{EXT_BILL_ID} > 0) {
    my $bill_action_type = '';
    if ($attr->{ACTION_TYPE}) {
      $bill_action_type = 'take';
    }
    else {
      $bill_action_type = 'add';
    }

    $Bill->info({ BILL_ID => $user->{EXT_BILL_ID} });
    $Bill->action($bill_action_type, $user->{EXT_BILL_ID}, $attr->{SUM});
    if ($Bill->{errno}) {
      return $self;
    }

    my $date = ($attr->{DATE}) ? "'$attr->{DATE}'" : 'now()';
    $self->query("INSERT INTO bonus_log (uid, bill_id, date, sum, dsc, ip, last_deposit, aid, method, ext_id,
           inner_describe, action_type, expire) 
           VALUES (?, ?, ?, ?, ?, INET_ATON(?), ?, ?, ?, ?, ?, ?, ?);", 'do',
      { Bind => [
          $user->{UID},
          $user->{EXT_BILL_ID},
          $date,
          $attr->{SUM},
          $attr->{DESCRIBE},
          $admin->{SESSION_IP},
          $Bill->{DEPOSIT},
          $admin->{AID},
          $attr->{METHOD} || 0,
          $attr->{EXT_ID} || '',
          $attr->{INNER_DESCRIBE} || '',
          $attr->{ACTION_TYPE},
          $attr->{EXPIRE} || '0000-00-00'
        ] }
    );

    $self->{BONUS_PAYMENT_ID} = $self->{INSERT_ID};
  }
  else {
    $self->{errno}  = 14;
    $self->{errstr} = 'No Bill';
  }

  return $self;
}

#**********************************************************
=head2 bonus_operation_del($user, $id)

=cut
#**********************************************************
sub bonus_operation_del {
  my $self = shift;
  my ($user, $id) = @_;

  $self->query("SELECT sum, bill_id, action_type FROM bonus_log WHERE id='$id';");

  if ($self->{TOTAL} < 1) {
    $self->{errno}  = 2;
    $self->{errstr} = 'ERROR_NOT_EXIST';
    return $self;
  }
  elsif ($self->{errno}) {
    return $self;
  }

  my ($sum, $bill_id, $action_type) = @{ $self->{list}->[0] };
  my $bill_action = 'take';
  if ($action_type) {
    $bill_action = 'add';
  }
  $Bill->action($bill_action, $bill_id, $sum);

  $self->query_del('bonus_log', { ID => $id });

  $admin->{MODULE} = $MODULE;
  $admin->action_add($user->{UID}, "BONUS $bill_action:$id SUM:$sum", { TYPE => 10 });

  return $self;
}

#**********************************************************
=head2 bonus_operation_list($attr)

=cut
#**********************************************************
sub bonus_operation_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  my $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;
  $self->{SEARCH_FIELDS} = '';
  my @WHERE_RULES = ();

  $self->{EXT_TABLES}     = '';
  $self->{SEARCH_FIELDS}  = '';
  $self->{SEARCH_FIELDS_COUNT}=0;

  my $WHERE =  $self->search_former($attr, [
      ['LOGIN',          'STR', 'u.id'                          ], 
      ['DATETIME',       'DATE','p.date',   'p.date AS datetime'], 
      ['SUM',            'INT', 'p.sum',                        ],
      ['PAYMENT_METHOD', 'INT', 'p.method',                     ],
      ['A_LOGIN',        'STR', 'a.id AS admin_login',        1 ],
      ['DESCRIBE',       'STR', 'p.dsc'                         ],
      ['INNER_DESCRIBE', 'STR', 'p.inner_describe'              ],
      ['METHOD',         'INT', 'p.method',                    1],
      ['BILL_ID',        'INT', 'p.bill_id',                   1],
      ['IP',             'INT', 'INET_NTOA(p.ip)',  'INET_NTOA(p.ip) AS ip'],
      ['EXT_ID',         'STR', 'p.ext_id',                               1],
      ['DATE',           'DATE','DATE_FORMAT(p.date, \'%Y-%m-%d\')'        ],
      ['EXPIRE',         'DATE','DATE_FORMAT(p.expire, \'%Y-%m-%d\')',   'DATE_FORMAT(p.expire, \'%Y-%m-%d\') AS expire' ],
      ['MONTH',          'DATE','DATE_FORMAT(p.date, \'%Y-%m\') AS month'  ],
      ['ID',             'INT', 'p.id'                                     ],
      ['AID',            'INT', 'p.aid',                                   ],
      ['FROM_DATE_TIME|TO_DATE_TIME','DATE', "p.date"                      ],
      ['FROM_DATE|TO_DATE', 'DATE',    'DATE_FORMAT(p.date, \'%Y-%m-%d\')' ],
      ['UID',            'INT', 'p.uid',                                  1],
    ],
    { WHERE       => 1,
      WHERE_RULES => \@WHERE_RULES,
      USERS_FIELDS=> 1,
      SKIP_USERS_FIELDS=> [ 'BILL_ID', 'UID' ]
    }
    );

    my $EXT_TABLES = $self->{EXT_TABLES};

    $self->query("SELECT p.id, u.id AS login, $self->{SEARCH_FIELDS} 
      p.date,
      p.dsc,
      p.sum,
      p.last_deposit,
      p.expire,
      p.method,
      p.ext_id, p.bill_id, if(a.name is null, 'Unknown', a.name),
      INET_NTOA(p.ip) AS ip,
      p.action_type,
      p.uid,
      p.inner_describe
    FROM bonus_log p
    LEFT JOIN users u ON (u.uid=p.uid)
    LEFT JOIN admins a ON (a.aid=p.aid)
    $EXT_TABLES
    $WHERE 
    GROUP BY p.id
    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  $self->{SUM} = '0.00';

  return $self->{list} || [] if ($self->{TOTAL} < 1);
  my $list = $self->{list} || [];

  $self->query("SELECT COUNT(p.id) AS total, SUM(p.sum) AS sum, COUNT(DISTINCT p.uid) AS total_users
    FROM bonus_log p
    LEFT JOIN users u ON (u.uid=p.uid)
    LEFT JOIN admins a ON (a.aid=p.aid)
    $EXT_TABLES
     $WHERE",
  undef,
  { INFO => 1 }
  );

  return $list;
}

#**********************************************************
=head2 service_discount_info($id)

=cut
#**********************************************************
sub service_discount_info {
  my $self = shift;
  my ($id) = @_;

  $self->query("SELECT * FROM bonus_service_discount
   WHERE id = ?;",
   undef,
   { INFO => 1,
     Bind => [ $id ] }
  );

  return $self;
}

#**********************************************************
=head2 service_discount_add($attr)

=cut
#**********************************************************
sub service_discount_add {
  my $self   = shift;
  my ($attr) = @_;

  $self->query_add('bonus_service_discount', $attr);

  return $self;
}

#**********************************************************
=head2 service_discount_change($attr)

=cut
#**********************************************************
sub service_discount_change {
  my $self = shift;
  my ($attr) = @_;

  $attr->{STATE} = ($attr->{STATE}) ? 1 : 0;
  $attr->{EXT_ACCOUNT} = ($attr->{EXT_ACCOUNT}) ? 1 : 0;

  $self->changes(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'bonus_service_discount',
      DATA         => $attr
    }
  );

  $self->service_discount_info($attr->{ID});

  return $self;
}

#**********************************************************
=head2 service_discount_del(attr);

=cut
#**********************************************************
sub service_discount_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('bonus_service_discount', $attr);

  return $self;
}

#**********************************************************
=head2 service_discount_list($attr)

=cut
#**********************************************************
sub service_discount_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  my $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  $self->{SEARCH_FIELDS}      = '';
  $self->{SEARCH_FIELDS_COUNT}= 0;

  my $WHERE =  $self->search_former($attr, [
      ['ID',                  'INT',    'id',                    1 ],
      ['NAME',                'STR',    'name',                  1 ],
      ['TP_ID',               'INT',    'tp_id'                    ],
      ['REGISTRATION_DAYS',   'INT',    'registration_days'        ],
      ['PERIODS',             'INT',    'service_period'           ],
      ['TOTAL_PAYMENTS_SUM',  'INT',    'total_payments_sum'       ],
      ['PAY_METHOD',          'INT',    'pay_method'               ],
      ['COMMENTS',            'STR',    'comments',              1 ],
      ['TP_ID',               'STR',    'tp_id',                 1 ],
      ['ONETIME_PAYMENT_SUM', 'INT',    'onetime_payment_sum',   1 ],
  ],
    { WHERE => 1 }
  );

  $self->query("SELECT
  $self->{SEARCH_FIELDS}
  service_period,
  registration_days,
  total_payments_sum,
  discount,
  discount_days,
  bonus_sum,
  bonus_percent,
  ext_account,
  pay_method
     FROM bonus_service_discount
     $WHERE 
     ORDER BY $SORT $DESC
     LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  return [ ] if ($self->{errno});

  my $list = $self->{list} || [];

  return $list;
}

#**********************************************************
=head2 bonus_turbo_info()

=cut
#**********************************************************
sub bonus_turbo_info {
  my $self = shift;
  my ($id) = @_;

  $self->query("SELECT id,
    service_period,
    registration_days,
    turbo_count,
    comments
     FROM bonus_turbo
   WHERE id = ? ;",
   undef,
   { INFO => 1,
     Bind => [ $id ] 
    }
  );

  return $self;
}

#**********************************************************
=head2 bonus_turbo_add($attr)

=cut
#**********************************************************
sub bonus_turbo_add {
  my $self   = shift;
  my ($attr) = @_;

  $self->query("INSERT INTO bonus_turbo (service_period, registration_days, turbo_count, comments)
        VALUES ('$attr->{SERVICE_PERIOD}', '$attr>{REGISTRATION_DAYS}', '$attr->{TURBO_COUNT}', '$attr->{DESCRIBE}');", 'do'
  );

  return $self;
}

#**********************************************************
# bonus_turbo_change()
#**********************************************************
sub bonus_turbo_change {
  my $self = shift;
  my ($attr) = @_;

  $attr->{STATE} = ($attr->{STATE}) ? 1 : 0;

  $self->changes(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'bonus_turbo',
      DATA         => $attr
    }
  );

  $self->bonus_turbo_info($attr->{ID});

  return $self;
}

#**********************************************************
#
# bonus_turbo_del(attr);
#**********************************************************
sub bonus_turbo_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('bonus_turbo', $attr);

  return $self;
}

#**********************************************************
# bonus_turbo_list()
#**********************************************************
sub bonus_turbo_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  my $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my @WHERE_RULES = ();

  if ($attr->{REGISTRATION_DAYS}) {
    push @WHERE_RULES, @{ $self->search_expr("$attr->{REGISTRATION_DAYS}", 'INT', 'registration_days') };
  }

  if ($attr->{PERIODS}) {
    push @WHERE_RULES, @{ $self->search_expr("$attr->{PERIODS}", 'INT', 'service_period') };
  }

  my $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

  $self->query("SELECT service_period, registration_days, turbo_count, id
     FROM bonus_turbo
     $WHERE 
     ORDER BY $SORT $DESC
     LIMIT $PG, $PAGE_ROWS;",
     undef,
     $attr
  );

  return [ ] if ($self->{errno});

  my $list = $self->{list};

  return $list;
}

#**********************************************************
=head2 accomulation_rule_info()

=cut
#**********************************************************
sub accomulation_rule_info {
  my $self = shift;
  my ($attr) = @_;

  $self->query("SELECT tp_id, dv_tp_id, cost
     FROM bonus_rules 
   WHERE id= ? AND dv_tp_id= ? ;",
   undef,
   { INFO => 1,
     Bind => [ $attr->{TP_ID}, $attr->{DV_TP_ID} ] }
  );

  return $self;
}

#**********************************************************
=head2 accomulation_rule_add($attr)

=cut
#**********************************************************
sub accomulation_rule_change {
  my $self   = shift;
  my ($attr) = @_;

  my @ids = split(/, /, $attr->{DV_TP_ID});

  if ( $#ids > -1 ) {
    my @MULTI_QUERY = ();

    foreach my $id (@ids) {
      push @MULTI_QUERY, [ $attr->{TP_ID} || 0, $id || 0, $attr->{'COST_'.$id} || 0 ];
    }

    $self->query( "REPLACE INTO bonus_rules_accomulation (tp_id, dv_tp_id, cost)
        VALUES ( ? , ? , ? );", undef,
      { MULTI_QUERY => \@MULTI_QUERY }
    );
  }

  return $self;
}

#**********************************************************
=head2 accomulation_rule_list($attr)

=cut
#**********************************************************
sub accomulation_rule_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  my @WHERE_RULES = ("tp.module IN ('Internet', 'Dv')");
 
  my $JOIN_WHERE = '';
  if ($attr->{DV_TP_ID}) {
    push @WHERE_RULES, "br.dv_tp_id='$attr->{DV_TP_ID}'";
    $JOIN_WHERE = "AND br.tp_id='$attr->{TP_ID}'";
  }

  if ($attr->{TP_ID}) {
    $JOIN_WHERE = " AND br.tp_id='$attr->{TP_ID}'";
  }

  if ($attr->{COST}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{COST}, 'INT', 'cost') };
  }
 
  my $WHERE = ($#WHERE_RULES > -1) ? join(' AND ', @WHERE_RULES) : '';
  $self->query("SELECT tp.tp_id AS dv_tp_id, tp.name, br.cost, br.tp_id
     FROM tarif_plans tp
     LEFT JOIN bonus_rules_accomulation br ON (br.dv_tp_id=tp.tp_id $JOIN_WHERE)
     WHERE $WHERE 
     ORDER BY $SORT $DESC;",
    undef,
    $attr
  );

  return [ ] if ($self->{errno});

  my $list = $self->{list};

  return $list;
}


#**********************************************************
=head2 accomulation_scores_info($attr)

=cut
#**********************************************************
sub accomulation_scores_info {
  my $self = shift;
  my ($attr) = @_;

  $self->query("SELECT  dv_tp_id, cost, changed
     FROM bonus_rules_accomulation_scores
   WHERE uid = ?;",
   undef,
   { INFO => 1,
     Bind => [ $attr->{UID} ] }
  );

  return $self;
}

#**********************************************************
=head2 accomulation_scores_change($attr)

  Arguments:
    $attr
      UID
      DV_TP_ID
      SCORE

=cut
#**********************************************************
sub accomulation_scores_change {
  my $self   = shift;
  my ($attr) = @_;

  my $tp_id = $attr->{DV_TP_ID} || 0;
  $self->query("SELECT uid FROM  bonus_rules_accomulation_scores WHERE uid = '$attr->{UID}' ");

  if($self->{TOTAL} && $self->{TOTAL} > 0) {
    $self->query("UPDATE bonus_rules_accomulation_scores SET
         cost='$attr->{SCORE}',
         dv_tp_id='$tp_id'
      WHERE uid='$attr->{UID}';", 'do'
    );
  }
  else {
    $self->query("INSERT INTO bonus_rules_accomulation_scores (uid, dv_tp_id, cost)
        VALUES ('$attr->{UID}', '$tp_id', '$attr->{SCORE}');", 'do'
    );
  }

  $admin->{MODULE} = $MODULE;
  if ($self->{AFFECTED} && $self->{AFFECTED} > 0) {
    $admin->action_add($attr->{UID}, "SCORE: ". $attr->{SCORE}, { TYPE => 2 });
  }

  return $self;
}


#**********************************************************
=head2 accomulation_scores_add($attr)

  Arguments:
    $attr
      DV_TP_ID
      UID
      SCORE

=cut
#**********************************************************
sub accomulation_scores_add {
  my $self   = shift;
  my ($attr) = @_;

  my $tp_value = ($attr->{DV_TP_ID}) ? "dv_tp_id='$attr->{DV_TP_ID}'," : q{};

  $self->query('UPDATE bonus_rules_accomulation_scores SET '
      . $tp_value
      . 'cost=cost + '. $attr->{SCORE}
      . " WHERE uid='". $attr->{UID} ."';", 'do'
  );

  if ($self->{AFFECTED} == 0 && $CONF->{BONUS_PAYMENTS_AUTO}){
    $self->accomulation_scores_change({ 
      UID      => $attr->{UID},
      SCORE    => $attr->{SCORE},
      DV_TP_ID => 0
    });
  }

  $admin->{MODULE} = $MODULE;
  if ($self->{AFFECTED} && $self->{AFFECTED} > 0) {
    $admin->action_add($attr->{UID}, "SCORE:$attr->{SCORE}", { TYPE => 1 });
  }

  return $self;
}


#**********************************************************
=head2 accomulation_scores_list($attr)

=cut
#**********************************************************
sub accomulation_scores_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  my $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my @WHERE_RULES = ();

  if ($attr->{REGISTRATION_DAYS}) {
    push @WHERE_RULES, @{ $self->search_expr("$attr->{REGISTRATION_DAYS}", 'INT', 'registration_days') };
  }

  if ($attr->{PERIODS}) {
    push @WHERE_RULES, @{ $self->search_expr("$attr->{PERIODS}", 'INT', 'service_period') };
  }

  my $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' AND ', @WHERE_RULES) : q{};

  $self->query("SELECT service_period, registration_days, turbo_count, id
     FROM bonus_rules_accomulation_scores bs
     INNER JOIN users u ON (u.uid=bs.uid)
     $WHERE 
     ORDER BY $SORT $DESC
     LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  return [ ] if ($self->{errno});

  my $list = $self->{list};

  return $list;
}


#**********************************************************
=head2 accomulation_first_rule()

=cut
#**********************************************************
sub accomulation_first_rule {
  my $self   = shift;
  my ($attr) = @_;

  $CONF->{BONUS_ACCOMULATION_FIRST_BONUS}=0 if (! $CONF->{BONUS_ACCOMULATION_FIRST_BONUS});
  $CONF->{BONUS_ACCOMULATION_FIRST_INTERVAL}=3 if (! defined($CONF->{BONUS_ACCOMULATION_FIRST_INTERVAL}));

  $self->query( "SELECT PERIOD_DIFF(DATE_FORMAT(max(date), '%Y%m'), 
DATE_FORMAT(min(date), '%Y%m')) FROM fees where uid='$attr->{UID}' AND
    date>=curdate() - INTERVAL $CONF->{BONUS_ACCOMULATION_FIRST_INTERVAL} MONTH");

  if ($self->{list}->[0]->[0]>=$CONF->{BONUS_ACCOMULATION_FIRST_INTERVAL}) { 
    $self->query('REPLACE INTO bonus_rules_accomulation_scores (uid, cost, changed)
SELECT '. $attr->{UID} .", IF((SELECT \@A:=MIN(last_deposit)
  FROM fees 
  WHERE uid= ?
    AND date>=CURDATE() - INTERVAL $CONF->{BONUS_ACCOMULATION_FIRST_INTERVAL} MONTH) >= 0
    OR \@A is null, $CONF->{BONUS_ACCOMULATION_FIRST_BONUS}, 0), CURDATE();",
  'do', 
  { Bind => [ $attr->{UID} ] });
  }

  return $self;
}

#**********************************************************
=head2 accomulation_reset_list($attr)

  Arguments:
    $attr

  Results:

=cut
#**********************************************************
sub accomulation_reset_list {
  my $self   = shift;
  my ($attr) = @_;

  $self->query( "SELECT b.cost, MAX(l.start) AS last_connect, b.uid, COUNT(online.uid) AS online
    FROM bonus_rules_accomulation_scores b
    LEFT JOIN internet_log l ON (l.uid=b.uid)
    LEFT JOIN internet_online online ON (online.uid=b.uid)
    WHERE b.cost > 0
    GROUP BY b.uid
    HAVING last_connect < CURDATE() - INTERVAL $attr->{RESET_PERIOD} DAY AND online < 1;",
    undef,
    $attr
  );

  return $self->{list};
}


#**********************************************************
=head2 tp_using_info($id)

=cut
#**********************************************************
sub tp_using_info {
  my $self = shift;
  my ($id) = @_;

  $self->query('SELECT * FROM bonus_tp_using
   WHERE id = ?;',
   undef,
   { INFO => 1,
     Bind => [ $id ]
   }
  );

  return $self;
}

#**********************************************************
# tp_using_add()
#**********************************************************
sub tp_using_add {
  my $self   = shift;
  my ($attr) = @_;

  $self->query_add('bonus_tp_using', $attr);

  return $self;
}

#**********************************************************
# tp_using_change()
#**********************************************************
sub tp_using_change {
  my $self = shift;
  my ($attr) = @_;

  $attr->{STATE} = ($attr->{STATE}) ? 1 : 0;

  $self->changes(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'bonus_tp_using',
      DATA         => $attr
    }
  );
  return $self->{result};
}

#**********************************************************
=head2 tp_using_del(attr);

=cut
#**********************************************************
sub tp_using_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('bonus_tp_using', $attr);

  return $self->{result};
}

#**********************************************************
=head2 tp_using_list($attr)

=cut
#**********************************************************
sub tp_using_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  my $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';

  my $WHERE =  $self->search_former($attr, [
    ['LOGIN',          'STR', 'u.id',               'u.id AS login'    ],
    ['TP_ID',          'INT', 'internet.tp_id',                        1     ],
    ['AGE',            'INT', 'aa.date', '(SELECT DATEDIFF(curdate(), max(datetime)) FROM admin_actions
      WHERE uid=internet.uid AND action_type=3 GROUP BY uid ORDER BY 1) AS age' ],
    ['MONTH_FEE',      'INT', 'tp.month_fee',                    1     ],
    ['FROM_DATE|TO_DATE','INT', "DATE_FORMAT(aa.datetime, '%Y-%m-%d')" ],
    ['UID',            'INT', 'internet.uid',                          1     ],
  ],
  { WHERE        => 1,
    USERS_FIELDS => 1,
    USE_USER_PI  => 1
  }
  );

  my $EXT_TABLES = '';

  if ($self->{SEARCH_FIELDS} =~ /internet\./) {
    $EXT_TABLES = " LEFT JOIN internet_main internet ON (internet.tp_id=bonus.tp_id_bonus)";
    if ($self->{SEARCH_FIELDS}  =~ /u\./) {
      $EXT_TABLES .= " LEFT JOIN users u ON (u.uid=internet.uid)";
    }
    if ($self->{SEARCH_FIELDS}  =~ /tp\./) {
      $EXT_TABLES .= " LEFT JOIN tarif_plans tp ON (tp.id=internet.tp_id)";
    }
  }

  if ($self->{SEARCH_FIELDS} =~ /aa\./ || $WHERE =~ /aa\./) {
    $EXT_TABLES .= " LEFT JOIN admin_actions aa ON (aa.uid=internet.uid)";
  }

  $EXT_TABLES .= $self->{EXT_TABLES};
  $self->query("SELECT bonus.*, $self->{SEARCH_FIELDS} bonus.id
     FROM bonus_tp_using bonus
     $EXT_TABLES
     $WHERE 
     ORDER BY $SORT $DESC;",
     undef,
     $attr
  );

  return [ ] if ($self->{errno});

  my $list = $self->{list};

  if ($self->{TOTAL} >= 0) {
    $self->query("SELECT count(bonus.id) AS total FROM bonus_tp_using bonus $EXT_TABLES $WHERE", undef, { INFO => 1 });
  }

  return $list;
}




1

