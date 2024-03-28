package Payments;

=head2  NAME

  Payments Finance module

=cut

use strict;
use Finance;
use parent qw(dbcore Finance);
use AXbills::Base qw(date_diff);
use Conf;
use Bills;
my $Bill;

my ($admin, $CONF);

#**********************************************************
# Init
#**********************************************************
sub new {
  my $class = shift;
  my $db    = shift;
  ($admin, $CONF) = @_;
  my $self = {
    db          => $db,
    admin       => $admin,
    conf        => $CONF,
  };

  bless($self, $class);

  $Bill = Bills->new($db, $admin, $CONF);

  $CONF->{BUILD_DELIMITER} = ', ' if (!defined($CONF->{BUILD_DELIMITER}));

  return $self;
}

#**********************************************************
=head2 add($user, $attr) - Add user payments

  Attributes:
    $user   - User object
    $attr   - Aextra attributes
      CHECK_EXT_ID - Check ext id
      ID
    	BILL_ID
    	DATE
    	DSC
    	IP
    	LAST_DEPOSIT
    	AID
    	REG_DATE
    	SUM

  Return
    Object

=cut
#**********************************************************
sub add {
  my $self = shift;
  my ($user, $attr) = @_;

  if (!$attr->{SUM} || $attr->{SUM} <= 0) {
    $self->{errno}  = 12;
    $self->{errstr} = 'ERROR_ENTER_SUM';
    return $self;
  }

  my DBI $db_ = $self->{db}{db};

  if ($self->{db}->{TRANSACTION}) {
    $db_->{AutoCommit} = 0;
  }

  if ($attr->{CHECK_EXT_ID}) {
    $db_->{AutoCommit} = 0;
    $self->query("SELECT id, date, sum, uid FROM payments WHERE ext_id=? LIMIT 1 LOCK IN SHARE MODE;",
     undef, {
       INFO => 1,
       Bind => [ $attr->{CHECK_EXT_ID} ] });

    if ($self->{error}) {
      $db_->{AutoCommit} = 1 if(! $db_->{AutoCommit});
      return $self;
    }
    elsif ($self->{TOTAL} > 0) {
      $db_->{AutoCommit} = 1 if(! $db_->{AutoCommit});
      $self->{errno}  = 7;
      $self->{errstr} = 'ERROR_DUPLICATE '.$attr->{CHECK_EXT_ID};
      return $self;
    }
  }

  $user->{BILL_ID} = $attr->{BILL_ID} if ($attr->{BILL_ID});
  $attr->{AMOUNT} = $attr->{SUM};

  if ($user->{BILL_ID} > 0) {
    if ($attr->{ER} && $attr->{ER} != 1 && $attr->{ER} > 0) {
      $attr->{SUM} = sprintf("%.2f", $attr->{SUM} / $attr->{ER});
    }

    $Bill->info({ BILL_ID => $user->{BILL_ID} });
    $Bill->action('add', $user->{BILL_ID}, $attr->{SUM});
    if ($Bill->{errno}) {
      $db_->rollback();
      return $self;
    }

    $self->query_add('payments', {
      %$attr,
      UID          => $user->{UID},
      BILL_ID      => $user->{BILL_ID},
      DATE         => ($attr->{DATE}) ? "$attr->{DATE}" : 'NOW()',
      DSC          => $attr->{DESCRIBE},
      IP           => $admin->{SESSION_IP},
      LAST_DEPOSIT => $Bill->{DEPOSIT},
      AID          => $admin->{AID},
      REG_DATE     => 'NOW()',
    });

    if (!$self->{errno}) {
      $self->{SUM} = $attr->{SUM};

      if (! $self->{db}->{TRANSACTION} && !$attr->{TRANSACTION}) {
        $db_->commit() if(! $db_->{AutoCommit});
      }
    }
    else {
      $db_->rollback();
    }

    $self->{PAYMENT_ID} = $self->{INSERT_ID};
  }
  else {
    $self->{errno}  = 14;
    $self->{errstr} = 'NO_BILL';
  }

  if (! $self->{db}->{TRANSACTION} && !$attr->{NO_AUTOCOMMIT} && !$attr->{TRANSACTION}) {
    $db_->{AutoCommit} = 1 ;
  }

  return $self;
}

#**********************************************************
=head2 del($user, $id, $attr) - Delete payments

  Attributes:
    $user  - User object
    $id    - Payments ID
    $attr  - Extra attributes

  Returns:
    Object

=cut
#**********************************************************
sub del {
  my $self = shift;
  my ($user, $id, $attr) = @_;

  $self->query("SELECT sum, bill_id from payments WHERE id= ? ;", undef, { Bind => [ $id ]  });

  $self->{db}{db}->{AutoCommit} = 0;
  if ($self->{TOTAL} < 1) {
    $self->{errno}  = 2;
    $self->{errstr} = 'ERROR_NOT_EXIST';
    return $self;
  }
  elsif ($self->{errno}) {
    return $self;
  }

  my ($sum, $bill_id) = @{ $self->{list}->[0] };

  $Bill->action('take', $bill_id, $sum);
  if (! $Bill->{errno}) {
    $self->query_del('docs_invoice2payments', undef, { payment_id => $id });
    $self->query("DELETE FROM docs_receipt_orders WHERE receipt_id=(SELECT id FROM docs_receipts WHERE payment_id='$id');", 'do');
    $self->query_del('docs_receipts', undef, { payment_id => $id });
    $self->query_del('payments', undef, { id => $id });

    if (! $self->{errno}) {
    	my $comments = ($attr->{COMMENTS}) ? $attr->{COMMENTS} : '';
      $admin->{MODULE}=q{};
      $admin->action_add($user->{UID}, "$id $sum $comments", { TYPE => 16 });
      $self->{db}{db}->commit();
    }
    else {
      $self->{db}{db}->rollback();
    }
  }

  $self->{db}{db}->{AutoCommit} = 1;
  return $self;
}

#**********************************************************
=head2 list($attr) - List of payments

  Attributes:
    $attr   - Extra attributes

  Returns:
    Arrya_refs

=cut
#**********************************************************
sub list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  my $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my @WHERE_RULES = ();

  if (! $attr->{PAYMENT_DAYS}) {
  	$attr->{PAYMENT_DAYS}=0;
  }
  elsif ($attr->{PAYMENT_DAYS}) {
    my $expr = '=';
    if ($attr->{PAYMENT_DAYS} =~ s/^(<|>)//) {
      $expr = $1;
    }
    push @WHERE_RULES, "p.date $expr CURDATE() - INTERVAL $attr->{PAYMENT_DAYS} DAY";
  }

  if($attr->{PAYMENTS_MONTHES}){
    push @WHERE_RULES, "p.date >= CURDATE() - INTERVAL $attr->{PAYMENTS_MONTHES} MONTH";
  }

  my $WHERE =  $self->search_former($attr, [
      ['DATETIME',       'DATE','p.date',   'p.date AS datetime'                           ],
      ['LOGIN',          'STR', 'u.id',         'u.id AS login'                            ],
      ['PAYMENT_METHOD', 'INT', 'p.method',                                              1 ],
      ['DSC',            'STR', 'p.dsc',                                                 1 ],
      ['INNER_DESCRIBE', 'STR', 'p.inner_describe'                                         ],
      ['DSC2',           'STR', 'p.dsc',  'p.dsc AS dsc2'                                  ],
      ['INNER_DESCRIBE2','STR', 'p.inner_describe', 'p.inner_describe AS inner_describe2'  ],
      ['SUM',            'INT', 'p.sum',                                                 1 ],
      ['LAST_DEPOSIT',   'INT', 'p.last_deposit',                                        1 ],
      ['METHOD',         'INT', 'p.method',                                              1 ],
      ['AMOUNT',         'INT', 'p.amount',                                              1 ],
      ['CURRENCY',       'INT', 'p.currency',                                            1 ],
      ['A_LOGIN',        'STR', 'a.id', 'a.id as a_login'                                  ],
      # ['ADMIN_NAME',     'STR', 'a.id'                                                     ],
      ['PAYMENT_METHOD_ID','INT', 'p.method', 'p.method AS payment_method_id'              ],
      ['BILL_ID',        'INT', 'p.bill_id',                                             1 ],
      ['AID',            'INT', 'p.aid',                                                 1 ],
      ['IP',             'INT', 'INET_NTOA(p.ip)',  'INET_NTOA(p.ip) AS ip'                ],
      ['EXT_ID',         'STR', 'p.ext_id',                                              1 ],
      ['ADMIN_NAME',     'STR', 'a.name', "IF(a.name is null, 'Unknown', a.name) AS admin_name"  ],
      ['INVOICE_NUM',    'INT', 'd.invoice_num',                                         1 ],
      ['INVOICE_DATE',   'INT', 'd.date', 'd.date AS invoice_date',                        ],
      ['DATE',           'DATE','DATE_FORMAT(p.date, \'%Y-%m-%d\')'                        ],
      ['REG_DATE',       'DATE','p.reg_date',                                            1 ],
      ['MONTH',          'DATE', "DATE_FORMAT(p.date, '%Y-%m')", "DATE_FORMAT(p.date, '%Y-%m') as month"],
      ['ID',             'INT', 'p.id'                                                     ],
      ['FROM_DATE_TIME|TO_DATE_TIME','DATE', "p.date"                                      ],
      ['FROM_DATE|TO_DATE', 'DATE', 'DATE_FORMAT(p.date, \'%Y-%m-%d\')'                    ],
      ['UID',            'INT', 'p.uid',                                                 1 ],
      ['AFTER_DEPOSIT',  'INT', '(p.sum+p.last_deposit) as after_deposit',               1 ],
      ['ADMIN_DISABLE',  'INT', 'a.disable', 'a.disable AS admin_disable',               1 ],
    ],
    { WHERE             => 1,
      WHERE_RULES       => \@WHERE_RULES,
      USERS_FIELDS      => 1,
      SKIP_USERS_FIELDS => [ 'BILL_ID', 'UID', 'LOGIN' ],
      USE_USER_PI       => 1
    }
    );

  my $EXT_TABLES  = '';
  $EXT_TABLES  = $self->{EXT_TABLES} if($self->{EXT_TABLES});

  if ($attr->{INVOICE_NUM}) {
    $EXT_TABLES  .= '  LEFT JOIN (SELECT payment_id, invoice_id FROM docs_invoice2payments GROUP BY payment_id) i2p ON (p.id=i2p.payment_id)
  LEFT JOIN (SELECT id, invoice_num, date FROM docs_invoices GROUP BY id) d ON (d.id=i2p.invoice_id)
';
  }

  my $list;
  #TODO we really need in default params inner_describe
  if (!$attr->{TOTAL_ONLY}) {
    $self->query("SELECT p.id,
      $self->{SEARCH_FIELDS}
      p.inner_describe,
      p.uid
    FROM payments p
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

    return [] if ($self->{TOTAL} < 1);
    $list = $self->{list};
  }

  $self->query("SELECT COUNT(tt.id) AS total, SUM(tt.sum) AS sum, COUNT(DISTINCT tt.uid) AS total_users
    FROM (SELECT p.id, p.sum, p.uid
    FROM payments p
    LEFT JOIN users u ON (u.uid=p.uid)
    LEFT JOIN admins a ON (a.aid=p.aid)
    $EXT_TABLES
    $WHERE
    GROUP BY p.id) tt",
  undef,
  { INFO => 1 }
  );

  return $list;
}

#**********************************************************
=head2 pool_add($user, $attr) - Add user payments

  Attributes:
    $attr   - Aextra attributes

  Return
    Object

=cut
#**********************************************************
sub pool_add {
  my $self = shift;
  my ($attr) = @_;

  return $self->query_add('payments_pool', $attr);
}

#**********************************************************
=head2 pool_list($attr) - List of payments pool

  Attributes:
    $attr   - Extra attributes

  Returns:
    Arrya_refs

=cut
#**********************************************************
sub pool_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  my $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $WHERE =  $self->search_former($attr, [
    ['SUM',            'INT', 'p.sum',                                                 1 ],#
    ['METHOD',         'INT', 'p.method',                                              1 ],#
    ['PAYMENT_ID',     'STR', 'pp.payment_id',                                         1 ],#
    ['EXT_ID',         'STR', 'p.ext_id',                                              1 ],#
    ['DATE',           'DATE','DATE_FORMAT(p.date, \'%Y-%m-%d\')',                     1 ],#
    ['ID',             'INT', 'pp.id',                                                 1 ],#
    ['STATUS',         'INT', 'pp.status',                                             1 ],#
    ['UID',            'INT', 'p.uid',                                                 1 ],#
  ],
    {
      WHERE       => 1,
    }
  );

  my $EXT_TABLES  = '';
  $EXT_TABLES  = $self->{EXT_TABLES} if($self->{EXT_TABLES});

  $self->query("SELECT $self->{SEARCH_FIELDS}
    pp.id
    FROM payments_pool pp
    LEFT JOIN payments p ON (p.id = pp.payment_id)
    $EXT_TABLES
    $WHERE
    GROUP BY pp.id
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;",
      undef,
      $attr
    );

  my $list = $self->{list};

  $self->query("SELECT
    COUNT(*) AS total
    FROM payments_pool pp
    LEFT JOIN payments p ON (p.id = pp.payment_id)
    $WHERE;",
    undef,
    { INFO => 1 }
  );

  return $list;
}

#**********************************************************
=head2 pool_change($attr) - Payments change_ pool status

=cut
#**********************************************************
sub pool_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'payments_pool',
    DATA         => $attr
  });

  return 1;
}

#**********************************************************
=head2 report($attr) - Payments reports

=cut
#**********************************************************
sub reports {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $date         = '';
  my $GROUP        = 1;
  my %EXT_TABLE_JOINS_HASH = ();

  if ($attr->{INTERVAL}) {
    ($attr->{FROM_DATE}, $attr->{TO_DATE}) = split(/\//, $attr->{INTERVAL}, 2);
  }

  $attr->{SKIP_DEL_CHECK}=1;
  my $WHERE =  $self->search_former($attr, [
      ['METHOD',            'INT',  'p.method'                         ],
      ['MONTH',             'DATE', "DATE_FORMAT(p.date, '%Y-%m')"     ],
      ['FROM_DATE|TO_DATE', 'DATE', "DATE_FORMAT(p.date, '%Y-%m-%d')"  ],
      ['DATE',              'DATE', "DATE_FORMAT(p.date, '%Y-%m-%d')"  ],
    ],
    {
      WHERE             => 1,
      USERS_FIELDS      => 1,
      USE_USER_PI       => 1,
      SKIP_USERS_FIELDS => [ 'UID', 'LOGIN' ],
    }
  );

  my $type = $attr->{TYPE} || q{};

  if ($attr->{INTERVAL}) {
    if ($type eq 'HOURS') {
      $date = "DATE_FORMAT(p.date, '%H') AS hour";
    }
    elsif ($type eq 'DAYS') {
      $date = "DATE_FORMAT(p.date, '%Y-%m-%d') AS date";
    }
    elsif ($type eq 'PAYMENT_METHOD') {
      $date = "p.method";
    }
    elsif ($type eq 'FIO') {
      $EXT_TABLE_JOINS_HASH{users}=1;
      $EXT_TABLE_JOINS_HASH{users_pi}=1;
      $date       = "pi.fio";
      $GROUP      = 5;
    }
    elsif ($type eq 'PER_MONTH') {
      my $WHERE_USERS = q{};
      if ($attr->{FROM_DATE}) {
        $WHERE_USERS = "WHERE registration <= '$attr->{FROM_DATE} 00:00:00'";
      }
      $self->query("SELECT COUNT(*) FROM users $WHERE_USERS;");
      my $system_users = $self->{list}->[0]->[0] || 0;
      $date = "DATE_FORMAT(p.date, '%Y-%m') AS month";
      $self->{SEARCH_FIELDS} = "ROUND(SUM(p.sum) / COUNT(DISTINCT p.uid), 2) AS arppu,
      ROUND(SUM(p.sum) / $system_users, 2) AS arpu,";

      # $self->{SEARCH_FIELDS}="ROUND(SUM(p.sum) / COUNT(DISTINCT p.uid), 2) AS arppu,
      #                         ROUND(SUM(p.sum) / (SELECT COUNT(*) FROM users WHERE DATE_FORMAT(registration, '%Y-%m') <= DATE_FORMAT(p.date, '%Y-%m')), 2) AS arpu,";
    }
    elsif ($type eq 'GID') {
      $date = "u.gid";
      $EXT_TABLE_JOINS_HASH{users}=1;
    }
    elsif ($type eq 'ADMINS') {
      $date = "a.id AS admin_name";
      $EXT_TABLE_JOINS_HASH{admins}=1;
      $self->{SEARCH_FIELDS} = 'p.aid,';
    }
    elsif ($type eq 'COMPANIES') {
      $date       = "company.name AS company_name";
      $self->{SEARCH_FIELDS} = 'u.company_id,';
      $EXT_TABLE_JOINS_HASH{users}=1;
      $EXT_TABLE_JOINS_HASH{companies}=1;
    }
    elsif ($type eq 'DISTRICT') {
      $date = "districts.name AS district_name";
      $self->{SEARCH_FIELDS} = 'districts.id AS district_id,';
      $EXT_TABLE_JOINS_HASH{users}=1;
      $EXT_TABLE_JOINS_HASH{users_pi}=1;
      $EXT_TABLE_JOINS_HASH{builds}=1;
      $EXT_TABLE_JOINS_HASH{streets}=1;
      $EXT_TABLE_JOINS_HASH{districts}=1;
    }
    elsif ($type eq 'STREET') {
      $date = "streets.name AS street_name";
      $self->{SEARCH_FIELDS} = 'streets.id AS street_id,';
      $EXT_TABLE_JOINS_HASH{users}=1;
      $EXT_TABLE_JOINS_HASH{users_pi}=1;
      $EXT_TABLE_JOINS_HASH{builds}=1;
      $EXT_TABLE_JOINS_HASH{streets}=1;
    }
    elsif ($type eq 'BUILD') {
      $date = "CONCAT(streets.name, '$CONF->{BUILD_DELIMITER}', builds.number) AS build";
      $self->{SEARCH_FIELDS} = 'builds.id AS location_id,';
      $EXT_TABLE_JOINS_HASH{users}=1;
      $EXT_TABLE_JOINS_HASH{users_pi}=1;
      $EXT_TABLE_JOINS_HASH{builds}=1;
      $EXT_TABLE_JOINS_HASH{streets}=1;
    }
    else {
      $date = "u.id AS login";
      $EXT_TABLE_JOINS_HASH{users} = 1;
    }
  }
  elsif ($attr->{MONTH}) {
    $date = "DATE_FORMAT(p.date, '%Y-%m-%d') AS date";
  }
  elsif ($attr->{PAYMENT_DAYS}) {
    my $expr = '=';
    if ($attr->{PAYMENT_DAYS} =~ /(<|>)/) {
      $expr = $1;
    }
  }
  else {
    my $WHERE_USERS = q{};
    if ($attr->{FROM_DATE}) {
      $WHERE_USERS = "WHERE registration <= '$attr->{FROM_DATE} 00:00:00'";
    }
    $self->query("SELECT COUNT(*) FROM users $WHERE_USERS;");
    my $system_users = $self->{list}->[0]->[0] || 0;
    $date = "DATE_FORMAT(p.date, '%Y-%m') AS month";
    $self->{SEARCH_FIELDS} = "ROUND(SUM(p.sum) / COUNT(DISTINCT p.uid), 2) AS arppu,
      ROUND(SUM(p.sum) / $system_users, 2) AS arpu,";

    # $self->{SEARCH_FIELDS} = "ROUND(SUM(p.sum) / count(DISTINCT p.uid), 2) AS arppu,
    #   ROUND(SUM(p.sum) / (SELECT count(*) FROM users WHERE DATE_FORMAT(registration, '%Y-%m') <= DATE_FORMAT(p.date, '%Y-%m')), 2) AS arpu,";
  }

  if ($attr->{ADMINS}) {
    $EXT_TABLE_JOINS_HASH{admins} = 1;
  }

  if ($admin->{DOMAIN_ID} || $attr->{GID} || $attr->{TAGS} || $self->{SEARCH_FIELDS} =~ /gid/ || $WHERE =~ /u.gid/) {
    $EXT_TABLE_JOINS_HASH{users} = 1;
  }

  $EXT_TABLE_JOINS_HASH{users}=1 if ($self->{EXT_TABLES});
  my $EXT_TABLES = $self->mk_ext_tables({
    JOIN_TABLES => \%EXT_TABLE_JOINS_HASH,
    EXTRA_PRE_JOIN  => [
      'users:INNER JOIN users u ON (u.uid=p.uid)',
      'admins:LEFT JOIN admins a ON (a.aid=p.aid)'
    ]
  });

  $self->query("SELECT $date,
    COUNT(DISTINCT p.uid) AS login_count,
    COUNT(DISTINCT p.id) AS count,
    SUM(p.sum) / (COUNT(*) - COUNT(DISTINCT p.id) + 1) AS sum,
    $self->{SEARCH_FIELDS} p.uid
    FROM payments p
      $EXT_TABLES
      $WHERE
      GROUP BY 1
      ORDER BY $SORT $DESC;",
    undef,
    $attr
  );

  my $total= $self->{TOTAL};
  my $list = $self->{list} || [];

  if ($self->{TOTAL} > 0) {
    $self->query("SELECT COUNT(DISTINCT p.uid) AS total_users,
      COUNT(DISTINCT p.id) AS total_operation,
      SUM(p.sum) / (COUNT(*) - COUNT(DISTINCT p.id) + 1) AS total_sum
    FROM payments p
      $EXT_TABLES
      $WHERE;",
      undef,
      { INFO => 1 }
    );
  }
  else {
    $self->{TOTAL_USERS} = 0;
    $self->{TOTAL_OPERATION} = 0;
    $self->{TOTAL_SUM}   = 0.00;
  }

  $self->{TOTAL}=$total;

  return $list;
}

#**********************************************************
=head2 reports_period_summary($attr) - Payments reports fot periods

=cut
#**********************************************************
sub reports_period_summary {
  my $self = shift;

  my @WHERE_RULES = ();
  my $EXT_TABLE = '';
  if ($admin->{GID}) {
    $admin->{GID}=~s/,/;/g;
    push @WHERE_RULES,  @{ $self->search_expr($admin->{GID}, 'INT', 'u.gid') };
  }

  if ($admin->{DOMAIN_ID}) {
    push @WHERE_RULES,  @{ $self->search_expr($admin->{DOMAIN_ID}, 'INT', 'u.domain_id') };
  }

  my $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' AND ', @WHERE_RULES) : '';

  if($WHERE =~ /u\./) {
    $EXT_TABLE .= "INNER JOIN users u ON (p.uid=u.uid)";
  }

  $self->query("SET default_week_format=1", 'do');

  $self->query("SELECT
       SUM(IF(DATE_FORMAT(date, '%Y-%m-%d')=CURDATE(), 1, 0)) AS day_count,
       SUM(IF(YEAR(CURDATE())=YEAR(p.date) AND WEEK(CURDATE()) = WEEK(p.date), 1, 0)) AS week_count,
       SUM(IF(DATE_FORMAT(p.date, '%Y-%m')=DATE_FORMAT(CURDATE(), '%Y-%m'), 1, 0))  AS month_count,

       SUM(IF(DATE_FORMAT(date, '%Y-%m-%d')=CURDATE(), p.sum, 0)) AS day_sum,
       SUM(IF(YEAR(CURDATE())=YEAR(p.date) AND WEEK(CURDATE()) = WEEK(p.date), p.sum, 0)) AS week_sum,
       SUM(IF(DATE_FORMAT(p.date, '%Y-%m')=DATE_FORMAT(CURDATE(), '%Y-%m'), p.sum, 0))  AS month_sum
      FROM payments p
      $EXT_TABLE
      $WHERE",
    undef,
    { INFO => 1 }
  );

  return $self;
}

#**********************************************************
=head2 add_payment_type($attr)

=cut
#**********************************************************
sub payment_type_add {
  my $self = shift;
  my ($attr) = @_;

 $self->query_add('payments_type',$attr);

 return $self;
}

#**********************************************************
=head2 del_payment_type($attr)

=cut
#**********************************************************
sub payment_type_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('payments_type', $attr);

  return $self;
}

#**********************************************************
=head2 admin_payment_type_list($attr)

=cut
#**********************************************************
sub admin_payment_type_list {
  my $self = shift;
  my ($attr) = @_;

  my $WHERE = $self->search_former($attr, [
      ['AID', 'INT', 'admins.aid'],
    ],
    { WHERE => 1 });

  $self->query("
    SELECT
      admins_payments_types.id,
      admins_payments_types.payments_type_id,
      payments_type.name
    FROM admins_payments_types
    LEFT JOIN admins
      ON admins.aid = admins_payments_types.aid
    LEFT JOIN payments_type
      ON payments_type.id = admins_payments_types.payments_type_id
    $WHERE;",
    undef,
    $attr
  );

  return $self->{list};
}

#**********************************************************
=head2 admin_payment_type_list_add($attr)

=cut
#**********************************************************
sub admin_payment_type_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('admins_payments_types',$attr);

  return $self;
}

#**********************************************************
=head2 admin_payment_type_list_del($attr)

=cut
#**********************************************************
sub admin_payment_type_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('admins_payments_types', undef, $attr);

  return $self;
}

#**********************************************************
=head2 payment_type_list($attr)

=cut
#**********************************************************
sub payment_type_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  my $WHERE = $self->search_former($attr, [
      ['ID',                'INT',  'pt.id'              ],
      ['NAME',              'STR',  'pt.name'            ],
      ['COLOR',             'STR',  'pt.color'           ],
      ['DEFAULT_PAYMENT',   'INT',  'pt.default_payment' ],
      ['FEES_TYPE',         'INT',  'pt.fees_type'       ]
    ],
    { WHERE => 1 });

  if(!$WHERE && $attr->{IDS}) {
    $WHERE .= "WHERE ";
  } elsif ($WHERE && $attr->{IDS}) {
    $WHERE .= " and ";
  }

  if($attr->{IDS}) {
    $WHERE .= "pt.id IN(".join(',', @{$attr->{IDS}}).")"
  }

  $self->query("
    SELECT
      pt.id,
      pt.name,
      pt.color,
      pt.default_payment,
      pt.fees_type".
      (
        $attr->{AID} ?
          (",COUNT(case when admins_payments_types.aid = $attr->{AID} then 1 else null end) AS allowed") :
          ""
      ).
    "
    FROM payments_type pt
    LEFT JOIN admins_payments_types
      ON admins_payments_types.payments_type_id = pt.id
    $WHERE
    GROUP BY pt.id
    ORDER BY $SORT $DESC;",
    undef,
    $attr
  );

  return $self->{list} || [];
}

#**********************************************************
=head2 payment_type_info($attr)

=cut
#**********************************************************
sub payment_type_info {
  my $self = shift;
  my ($attr) = @_;

  $self->query("SELECT * FROM payments_type pt WHERE pt.id= ?;",
  undef,
  { INFO => 1,
    Bind => [ $attr->{ID}] }
  );

  return $self;
}

#**********************************************************
=head2 payment_type_change($attr)

=cut
#**********************************************************
sub payment_type_change {
  my $self = shift;
  my ($attr) = @_;

  if ($attr->{DEFAULT_UNCLICK}) {
    $self->payment_default_type();
    $self->query("UPDATE payments_type SET default_payment = 1 WHERE id = 0;");
  }

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'payments_type',
    DATA         => $attr
  });

  return $self;
}

#**********************************************************
=head2 payment_report_admin($attr)

=cut
#**********************************************************
sub payment_report_admin {
  my $self = shift;
  my ($attr) = @_;
  my $aid = $attr->{AID} || '';
  my $date = $attr->{DATE} || '';

  $self->query("SELECT p.method, COUNT(p.id) AS total, SUM(p.sum) AS sum, COUNT(DISTINCT p.uid) AS total_users
    FROM payments p
    LEFT JOIN users u ON (u.uid=p.uid)
    LEFT JOIN admins a ON (a.aid=p.aid)
    WHERE p.aid='$aid' AND (DATE_FORMAT(p.date, '%Y-%m-%d')='$date')
    GROUP BY 1;
    ",
    undef,
    $attr
  );

  return $self->{list} || [];
}

#**********************************************************
=head2 payment_default_type($attr)

=cut
#**********************************************************
sub payment_default_type {
  my $self = shift;

  $self->query("UPDATE payments_type SET default_payment = 0;");

  return $self;
}

1;
