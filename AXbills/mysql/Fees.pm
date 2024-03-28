package Fees;

=head1 NAME

  Finance (fees) module DB frontend

=cut

use strict;
use parent qw(dbcore Finance);
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
  my $self = {};
  bless($self, $class);

  $self->{db}=$db;
  $self->{admin}=$admin;
  $self->{conf}=$CONF;

  $CONF->{BUILD_DELIMITER} = ', ' if (!defined($CONF->{BUILD_DELIMITER}));

  $Bill = Bills->new($db, $admin, $CONF);

  return $self;
}

#**********************************************************
=head2 take($user, $sum, $attr) - Take sum from bill account

  Arguments:
    $user
    $sum
    $attr
      SKIP_PRIORITY
      BILL_ID

  Resturn:
    $self

=cut
#**********************************************************
sub take {
  my $self = shift;
  my ($user, $sum, $attr) = @_;

  if ($sum <= 0) {
    $self->{errno}  = 12;
    $self->{errstr} = 'ERROR_ENTER_SUM';
    return $self;
  }
  elsif ($user->{UID} <= 0) {
    $self->{errno}  = 18;
    $self->{errstr} = 'ERROR_ENTER_UID';
    return $self;
  }

  my $fees_priority = $CONF->{FEES_PRIORITY} || q{};

  if($attr->{SKIP_PRIORITY}) {
    $fees_priority = q{};
    $user->{BILL_ID} = $attr->{BILL_ID} if($attr->{BILL_ID});
  }

  $attr->{UID}     = $user->{UID};
  $attr->{BILL_ID} = $user->{BILL_ID} if(! $attr->{BILL_ID});
  $attr->{DATE}    = ($attr->{DATE}) ? $attr->{DATE} : 'NOW()';
  $attr->{DSC}     = $attr->{DESCRIBE} || '';
  $attr->{IP}      = $admin->{SESSION_IP};
  $attr->{AID}     = $admin->{AID} || 1;
  $attr->{VAT}     = $user->{COMPANY_VAT};

  $sum = sprintf("%.4f", $sum);
  $self->{db}{db}->{AutoCommit} = 0;

  if ($fees_priority) {
    if ($fees_priority =~ /^bonus/ && $user->{EXT_BILL_ID}) {
      if ($user->{EXT_BILL_ID} && !defined($self->{EXT_BILL_DEPOSIT})) {
        if (! $user->{EXT_BILL_ID} || ! defined($self->{EXT_BILL_DEPOSIT})) {
          my $uid = $user->{UID};
          my $fn  = 'user::info';
          if (! defined( &$fn )) {
            $user = Users->new($self->{db}, $admin, $CONF);
          }
          $user->info($uid);
        }

        $user->info($user->{UID});
      }

      if ($fees_priority =~ /main/ && $user->{EXT_BILL_DEPOSIT} < $sum) {
        if ($user->{EXT_BILL_DEPOSIT} > 0) {
          $Bill->action('take', $user->{EXT_BILL_ID}, $user->{EXT_BILL_DEPOSIT});
          if ($Bill->{errno}) {
            $self->{errno}  = $Bill->{errno};
            $self->{errstr} = $Bill->{errstr};
            return $self;
          }

          $self->{SUM} = $self->{EXT_BILL_DEPOSIT};

          $self->query_add('fees', {
            %$attr,
            SUM          => $self->{SUM},
            LAST_DEPOSIT => $Bill->{DEPOSIT},
            METHOD       => $attr->{EXT_BILL_METHOD} || $attr->{METHOD}
          });

          $sum = $sum - $user->{EXT_BILL_DEPOSIT};
        }
      }
      else {
        $user->{BILL_ID} = $user->{EXT_BILL_ID};
        if($attr->{EXT_BILL_METHOD}) {
          $attr->{METHOD} = $attr->{EXT_BILL_METHOD};
        }
      }
    }
    elsif ($fees_priority =~ /^main,bonus/) {
      if (! $user->{EXT_BILL_ID} || ! defined($self->{EXT_BILL_DEPOSIT})) {
        my $uid = $user->{UID}; 
        my $fn  = 'user::info';
        if (! defined( &$fn )) {
           $user = Users->new($self->{db}, $admin, $CONF);
        }
        $user->info($uid);
      }

      if ($user->{EXT_BILL_DEPOSIT} && $user->{DEPOSIT} < $sum) {
        if ($user->{EXT_BILL_DEPOSIT} + $user->{DEPOSIT} > $sum) {
          $self->{SUM} = $user->{DEPOSIT};
        }
        else {
          $self->{SUM} = $sum - $user->{EXT_BILL_DEPOSIT};
        }

        if ($self->{SUM} > 0) {
          $Bill->action('take', $user->{BILL_ID}, $self->{SUM});
          if ($Bill->{errno}) {
            $self->{errno}  = $Bill->{errno};
            $self->{errstr} = $Bill->{errstr};
            return $self;
          }

          $self->query_add('fees', {
            %$attr,
            BILL_ID      => $user->{BILL_ID},
            SUM          => $self->{SUM},
            LAST_DEPOSIT => $Bill->{DEPOSIT},
          });

          $sum = $sum - $self->{SUM};
        }
        $user->{BILL_ID} = $user->{EXT_BILL_ID};
        if($attr->{EXT_BILL_METHOD}) {
          $attr->{METHOD} = $attr->{EXT_BILL_METHOD};
        }
      }
    }

    if ($sum == 0) {
      if (!$attr->{NO_AUTOCOMMIT} && ! $self->{db}->{TRANSACTION}) {
        $self->{db}{db}->{AutoCommit} = 1;
      }
      return $self;
    }
  }

  if ($attr->{BILL_ID} && ! $user->{BILL_ID}) {
    $user->{BILL_ID} = $attr->{BILL_ID};
  }

  if ($user->{BILL_ID} && $user->{BILL_ID} > 0) {
    $Bill->info({ BILL_ID => $user->{BILL_ID} });

    $Bill->action('take', $user->{BILL_ID}, $sum);
    if ($Bill->{errno}) {
      $self->{errno}  = $Bill->{errno};
      $self->{errstr} = $Bill->{errstr};
      return $self;
    }

    $self->{SUM} = $sum;
    $self->query_add('fees', {
      %$attr,
      BILL_ID      => $user->{BILL_ID},
      SUM          => $self->{SUM},
      LAST_DEPOSIT => $Bill->{DEPOSIT},
      REG_DATE     => 'NOW()'
    });

    if ($self->{errno}) {
      $self->{db}{db}->rollback();
      return $self;
    }
    else {
      $self->{db}{db}->commit() if(! $self->{db}->{TRANSACTION});
    }

    $self->{FEES_ID} = $self->{INSERT_ID};
  }
  else {
    $self->{errno}  = 14;
    $self->{errstr} = 'No Bill';
  }

  if (! $self->{db}->{TRANSACTION} && !$attr->{NO_AUTOCOMMIT} && !$attr->{TRANSACTION}) {
    $self->{db}{db}->{AutoCommit} = 1 ;
  }

  return $self;
}

#**********************************************************
=head2 del($user, $id, $attr)

=cut
#**********************************************************
sub del {
  my $self = shift;
  my ($user, $id, $attr) = @_;

  $self->query("SELECT sum, bill_id from fees WHERE id= ? ;", undef, { Bind => [ $id ] });

  if ($self->{TOTAL} < 1) {
    $self->{errno}  = 2;
    $self->{errstr} = 'ERROR_NOT_EXIST';
    return $self;
  }
  elsif ($self->{errno}) {
    return $self;
  }

  my ($sum, $bill_id) = @{ $self->{list}->[0] };

  $Bill->action('add', $bill_id, $sum);

  $self->query_del('fees', { ID => $id });

   my $comments = ($attr->{COMMENTS}) ? $attr->{COMMENTS} : '';

  $admin->action_add($user->{UID}, "$id $sum $comments", { TYPE => 17 });

  return $self;
}

#**********************************************************
=head2  list($attr) - Fees list

=cut
#**********************************************************
sub list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  my $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;
  my $GROUP_BY  = $attr->{GROUP_BY} || 'f.id';

  my @WHERE_RULES = ();
  if($attr->{FEES_MONTHES}){
    push @WHERE_RULES, "f.date >= CURDATE() - INTERVAL $attr->{FEES_MONTHES} MONTH";
  }

  my $WHERE =  $self->search_former($attr, [
      ['ID',             'INT', 'f.id',                              ],
      ['DATETIME',       'DATE','f.date',        'f.date AS datetime'],
      ['LAST_DATE',      'DATE','MAX(f.date)',  'MAX(f.date) AS date'],
      ['LOGIN',          'STR', 'u.id',              'u.id AS login' ],
      ['FIO',            'STR', 'pi.fio',                            ],
      ['DESCRIBE',       'STR', 'f.dsc',                           1 ],
      ['DSC',            'STR', 'f.dsc',                           1 ],
      ['SUM',            'INT', 'f.sum',                           1 ],
      ['LAST_DEPOSIT',   'INT', 'f.last_deposit',                  1 ],
      ['METHOD',         'INT', 'f.method',                        1 ],
      ['METHOD_ID',      'INT', 'f.method', 'f.method AS method_id'  ],
      ['COMPANY_ID',     'INT', 'u.company_id',                      ],
      ['A_LOGIN',        'STR', 'a.id', 'a.id as a_login',         1 ],
      # ['ADMIN_NAME',     'STR', 'a.id'                               ],
      ['ADMIN_NAME',     'STR', 'a.name', "IF(a.name is NULL, 'Unknown', a.name) AS admin_name" ],
      ['BILL_ID',        'INT', 'f.bill_id',                       1 ],
      ['IP',             'INT', 'INET_NTOA(f.ip)', 'INET_NTOA(f.ip) AS ip'  ],
      ['AID',            'INT', 'f.aid',                           1 ],
      ['DOMAIN_ID',      'INT', 'u.domain_id',                       ],
      ['UID',            'INT', 'f.uid',                           1 ],
      ['INNER_DESCRIBE', 'STR', 'f.inner_describe',                  ],
      ['DATE',           'DATE','DATE_FORMAT(f.date, \'%Y-%m-%d\')'  ],
      ['FROM_DATE|TO_DATE','DATE', 'DATE_FORMAT(f.date, \'%Y-%m-%d\')'  ],
      ['FROM_DATE_TIME|TO_DATE_TIME','DATE', "f.date"                   ],
      ['MONTH',          'DATE', "DATE_FORMAT(f.date, '%Y-%m')", "DATE_FORMAT(f.date, '%Y-%m') as month"],
      ['REG_DATE',       'DATE', "f.reg_date", "f.reg_date",       1 ],
      ['TAX',            'INT',  'ft.tax',                         1 ],
      ['TAX_SUM',        'INT',  '', 'IF(ft.tax>0, SUM(f.sum) / 100 * ft.tax, 0) AS tax_sum'],
      ['ADMIN_DISABLE',  'INT', 'a.disable', 'a.disable AS admin_disable',               1 ],
      ['INVOICE_NUM',    'INT', 'd.invoice_num',                                         1 ],
      ['INVOICE_ID',     'INT', 'd.id',  'd.id AS invoice_id'                              ],
    ],
    { WHERE             => 1,
      USERS_FIELDS      => 1,
      SKIP_USERS_FIELDS => [ 'BILL_ID', 'UID', 'LOGIN' ],
      USE_USER_PI       => 1,
      WHERE_RULES       => \@WHERE_RULES,
    });

  my $EXT_TABLES  = $self->{EXT_TABLES};

  if ($attr->{INVOICE_ID}) {
    $EXT_TABLES  .= '  LEFT JOIN docs_invoice_orders invoice_orders ON (f.id=invoice_orders.fees_id)
  LEFT JOIN docs_invoices d ON (d.id=invoice_orders.invoice_id)
';
  }

  if($attr->{TAX} || $attr->{TAX_SUM}) {
    $EXT_TABLES  .= " LEFT JOIN fees_types ft ON (ft.id=f.method)";
  }

  if($self->{SEARCH_FIELDS} =~ /u\.|pi\./ || $WHERE =~ /u\.|pi\./) {
    $EXT_TABLES = 'LEFT JOIN users u ON (u.uid=f.uid) ' . $EXT_TABLES;
  }

  if($self->{SEARCH_FIELDS} =~ /a\./ || $WHERE =~ /a\./) {
    $EXT_TABLES = 'LEFT JOIN admins a ON (a.aid=f.aid) ' . $EXT_TABLES;
  }

  #TODO we really need in default params inner_describe
  $self->query("SELECT f.id,
     $self->{SEARCH_FIELDS}
   f.inner_describe,
   f.uid
    FROM fees f
    $EXT_TABLES
    $WHERE 
    GROUP BY $GROUP_BY
    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  $self->{SUM}         = '0.00';
  $self->{TOTAL_USERS} = 0;

  return [] if ($self->{TOTAL} < 1);
  my $list = $self->{list};

  if ($self->{TOTAL} > 0) {
    $self->query("SELECT COUNT(*) AS total, SUM(f.sum) AS sum, COUNT(DISTINCT f.uid) AS total_users FROM fees f
  $EXT_TABLES
  $WHERE",
  undef,
  { INFO => 1 }
    );
  }

  return $list;
}

#**********************************************************
=head2 report($attr) - Fees reports

=cut
#**********************************************************
sub reports {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $PG   = ($attr->{PG})   ? $attr->{PG}   : 0;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $date = "DATE_FORMAT(f.date, '%Y-%m-%d') AS date";
  my @WHERE_RULES = ();
  my %EXT_TABLE_JOINS_HASH = ();

  if ($attr->{ADMINS}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{ADMINS}, 'STR', 'a.id') };
  }

  if ($attr->{INTERVAL}) {
    ($attr->{FROM_DATE}, $attr->{TO_DATE}) = split(/\//, $attr->{INTERVAL}, 2);
  }
  elsif ($attr->{MONTH}) {
    $date = "DATE_FORMAT(f.date, '%Y-%m-%d') AS date";
  }
  else {
    $date = "DATE_FORMAT(f.date, '%Y-%m') AS month";
  }

  my $GROUP = 1;
  my $report_type = ($attr->{TYPE}) ? $attr->{TYPE} : q{};

  if ($report_type eq 'HOURS') {
    $date = "DATE_FORMAT(f.date, '%H') AS hour";
  }
  elsif ($report_type eq 'DAYS') {
    $date = "DATE_FORMAT(f.date, '%Y-%m-%d') AS date";
  }
  elsif ($report_type eq 'METHOD') {
    $date = "f.method";
    $EXT_TABLE_JOINS_HASH{fees_types}=1;
    $attr->{TAX_SUM}='_SHOW';
  }
  elsif ($report_type eq 'ADMINS') {
    $date = "a.id AS admin_name";
    $EXT_TABLE_JOINS_HASH{admins} = 1;
  }
  elsif ($report_type eq 'PER_MONTH') {
    $date = "DATE_FORMAT(f.date, '%Y-%m') AS date";
  }
  elsif ($report_type eq 'FIO') {
    $EXT_TABLE_JOINS_HASH{users_pi} = 1;
    $date       = "pi.fio";
    $GROUP      = 5;
  }
  elsif ($report_type eq 'COMPANIES') {
    $EXT_TABLE_JOINS_HASH{companies}=1;
    $date       = "company.name AS company_name";
    $attr->{COMPANY_ID}='>0';
  }
  elsif ($report_type eq 'DISTRICT') {
    $date = "districts.name AS district_name";
    $self->{SEARCH_FIELDS} = 'districts.id AS district_id,';
    $EXT_TABLE_JOINS_HASH{users}=1;
    $EXT_TABLE_JOINS_HASH{users_pi}=1;
    $EXT_TABLE_JOINS_HASH{builds}=1;
    $EXT_TABLE_JOINS_HASH{streets}=1;
    $EXT_TABLE_JOINS_HASH{districts}=1;
  }
  elsif ($report_type eq 'STREET') {
    $date = "streets.name AS street_name";
    $self->{SEARCH_FIELDS} = 'streets.id AS street_id,';
    $EXT_TABLE_JOINS_HASH{users}=1;
    $EXT_TABLE_JOINS_HASH{users_pi}=1;
    $EXT_TABLE_JOINS_HASH{builds}=1;
    $EXT_TABLE_JOINS_HASH{streets}=1;
  }
  elsif ($report_type eq 'BUILD') {
    $date = "CONCAT(streets.name, '$CONF->{BUILD_DELIMITER}', builds.number) AS build";
    $self->{SEARCH_FIELDS} = 'builds.id AS location_id,';
    $EXT_TABLE_JOINS_HASH{users}=1;
    $EXT_TABLE_JOINS_HASH{users_pi}=1;
    $EXT_TABLE_JOINS_HASH{builds}=1;
    $EXT_TABLE_JOINS_HASH{streets}=1;
  }
  elsif ($report_type eq 'GID') {
    $date = "u.gid";
    $EXT_TABLE_JOINS_HASH{users}=1;
  }
  elsif($report_type eq 'LOGIN'){
    $date = "u.id AS login";
  }

  if($attr->{GID}) {
    $EXT_TABLE_JOINS_HASH{users}=1;
  }

  $attr->{SKIP_DEL_CHECK}=1;
  my $WHERE =  $self->search_former($attr, [
      ['BILL_ID',           'INT',  'f.bill_id',                     1 ],
      ['METHOD',            'INT',  'f.method'                         ],
      ['MONTH',             'DATE', "DATE_FORMAT(f.date, '%Y-%m')"     ],
      ['FROM_DATE|TO_DATE', 'DATE', "DATE_FORMAT(f.date, '%Y-%m-%d')"  ],
      ['DATE',              'DATE', "DATE_FORMAT(f.date, '%Y-%m-%d')"  ],
      ['TAX_SUM',           'INT',  '', 'IF(ft.tax>0, (SUM(f.sum) / (100 + ft.tax) * ft.tax), 0) AS tax_sum'  ],
    ],
    {
      WHERE             => 1,
      USERS_FIELDS      => 1,
      USE_USER_PI       => 1,
      SKIP_USERS_FIELDS => [ 'UID', 'LOGIN' ],
    }
  );

  if ($self->{EXT_TABLES} || $date =~ /u\.|pi\./ || $WHERE =~ /u\.|pi\./) {
    $EXT_TABLE_JOINS_HASH{users}=1;
  }

  if($WHERE =~ /ft\./ || $self->{SEARCH_FIELDS} =~ /ft\./){
    $EXT_TABLE_JOINS_HASH{fees_types}=1;
    $attr->{TAX_SUM}='_SHOW';
  }

  $EXT_TABLE_JOINS_HASH{users}=1 if ($self->{EXT_TABLES});
  my $EXT_TABLES = $self->mk_ext_tables({
    JOIN_TABLES     => \%EXT_TABLE_JOINS_HASH,
    EXTRA_PRE_JOIN  => [ 'users:INNER JOIN users u ON (u.uid=f.uid)',
      'admins:LEFT JOIN admins a ON (a.aid=f.aid)',
      'fees_types:LEFT JOIN fees_types ft ON (ft.id=f.method)'
    ]
  });

  $self->query("SELECT $date, COUNT(DISTINCT f.uid) AS login_count, COUNT(*) AS count,  SUM(f.sum) AS sum,
      $self->{SEARCH_FIELDS} f.uid
    FROM fees f
    $EXT_TABLES
    $WHERE
    GROUP BY $GROUP
    ORDER BY $SORT $DESC;",
    undef,
    $attr
  );

  my $list = $self->{list};

  $self->{SUM}   = '0.00';
  $self->{USERS} = 0;
  if ($self->{TOTAL} > 0 || $PG > 0) {
    $self->query("SELECT COUNT(DISTINCT f.uid) AS users, COUNT(*) AS total, SUM(f.sum) AS sum
      FROM fees f
      $EXT_TABLES
      $WHERE;",
    undef,
    { INFO => 1 }
    );
  }

  return $list;
}

#**********************************************************
=head2 fees_type_list($attr)

=cut
#**********************************************************
sub fees_type_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  my $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $WHERE =  $self->search_former($attr, [
      ['ID',           'INT', 'id'      ],
      ['NAME',         'STR', 'name'    ],
      ['TAX',          'INT', 'tax',   1],
    ],
  { WHERE => 1, });

  $self->query("SELECT id,
    $self->{SEARCH_FIELDS}
    name, default_describe, sum
  FROM fees_types
  $WHERE
  ORDER BY $SORT $DESC
  LIMIT $PG, $PAGE_ROWS;",
  undef,
  $attr
  );

  my $list = $self->{list};
  if ($self->{TOTAL} > 0 || $PG > 0) {
    $self->query("SELECT COUNT(*) AS total FROM fees_types $WHERE ;",
    undef, { INFO => 1 });
  }

  return $list;
}

#**********************************************************
=head2 fees_types_info($attr)

=cut
#**********************************************************
sub fees_type_info {
  my $self = shift;
  my ($attr) = @_;

  $self->query("SELECT * FROM fees_types WHERE id = ? ;",
  undef,
  { INFO => 1,
    Bind => [ $attr->{ID} ] });

  return $self;
}

#**********************************************************
=head2 fees_types_change($attr)

=cut
#**********************************************************
sub fees_type_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'fees_types',
      DATA         => $attr
    }
  );

  return $self;
}

#**********************************************************
=head2 fees_type_add($attr)

=cut
#**********************************************************
sub fees_type_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('fees_types', $attr);
  if(! $self->{errno}) {
    $admin->system_action_add("FEES_TYPES:$self->{INSERT_ID}:$attr->{NAME}", { TYPE => 1 }) if (!$self->{errno});
  }

  return $self;
}

#**********************************************************
=head2 fees_type_del($id)

=cut
#**********************************************************
sub fees_type_del {
  my $self = shift;
  my ($id) = @_;

  $self->query_del('fees_types', { ID => $id });

  $admin->system_action_add("FEES_TYPES:$id", { TYPE => 10 }) if (!$self->{errno});
  return $self;
}

#**********************************************************
=head2 fees_last_add ($attr)

=cut
#**********************************************************
sub fees_last_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('fees_last', $attr, {REPLACE => 1});

  return $self;
}

1
