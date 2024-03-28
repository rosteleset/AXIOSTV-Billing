package Extreceipt;

=head1 NAME

 Extreceipt sql functions

=cut

use strict;
use parent 'dbcore';
my $MODULE = 'Extreceipt';

#**********************************************************
=head2 new($db, $admin, \%conf)

=cut
#**********************************************************
sub new {
  my $class = shift;
  my ($db, $admin, $conf) = @_;

  $admin->{MODULE} = $MODULE;
  
  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $conf
  };
  
  bless($self, $class);
  return $self;
}

#**********************************************************
=head2 list($attr)

=cut
#**********************************************************
sub list {
  my $self = shift;
  my ($attr) = @_;

  my $WHERE =  $self->search_former($attr, [
      ['STATUS',            'INT', 'e.status',                            1],
      ['UID',               'INT', 'p.uid',                               1],
      ['PAYMENT_ID',        'INT', 'p.id',                                1],
      ['FROM_DATE|TO_DATE', 'DATE', 'DATE_FORMAT(p.date, \'%Y-%m-%d\')'   ],
      ['PAYMENT_METHOD',    'INT', 'p.id',    'p.id AS payment_method'    ],
    ],
    { WHERE => 1 }
  );

  my $limit = '';
  if($attr->{PAGE_ROWS}) {
    $limit = " LIMIT $attr->{PAGE_ROWS}";
  }

  $self->query("SELECT
      $self->{SEARCH_FIELDS}
      e.*,
      ek.api_id,
      ek.kkt_group,
      p.sum,
      p.uid,
      p.date,
      p.method AS payment_method,
      ucc.value AS c_phone,
      IF(ucp.value is NULL, pi.phone, ucp.value) AS phone,
      IF(ucm.value is NULL, pi.email, ucp.value) AS mail
      FROM extreceipts e
      LEFT JOIN extreceipts_kkt ek ON (e.kkt_id = ek.kkt_id)
      LEFT JOIN payments p ON (p.id = e.payments_id)
      LEFT JOIN users_pi pi ON (pi.uid = p.uid)
      LEFT JOIN users_contacts ucc ON (ucc.uid = p.uid AND ucc.type_id=1)
      LEFT JOIN users_contacts ucp ON (ucp.uid = p.uid AND ucp.type_id=2)
      LEFT JOIN users_contacts ucm ON (ucm.uid = p.uid AND ucm.type_id=9)
      $WHERE
      GROUP BY e.payments_id
      $limit;",
    undef,
    { %$attr,
      COLS_NAME => 1,
      COLS_UPPER => 1
    }
  );

  return $self->{list};
}

#**********************************************************
=head2 info($payments_id)

=cut
#**********************************************************
sub info {
  my $self = shift;
  my ($id) = @_;

  my $EXT_TABLES = '';

  if ($self->{conf}->{EXTRECEIPTS_USER_CELL_PHONE}) {
    $EXT_TABLES = " LEFT JOIN users_contacts ucp ON (ucp.uid = p.uid AND ucp.type_id=1)";
  } else {
    $EXT_TABLES = " LEFT JOIN users_contacts ucp ON (ucp.uid = p.uid AND ucp.type_id=2)";
  }

  $self->query("SELECT
      e.*,
      ek.api_id,
      ek.kkt_group,
      ek.aid,
      p.sum,
      p.uid,
      p.method AS payment_method,
      IF(ucp.value IS NULL, pi.phone,  ucp.value) AS phone,
      IF(ucm.value IS NULL, pi.email, ucm.value) AS mail
      FROM extreceipts e
      LEFT JOIN extreceipts_kkt ek ON (e.kkt_id = ek.kkt_id)
      LEFT JOIN payments p ON (p.id = e.payments_id)
      LEFT JOIN users_contacts ucm ON (ucm.uid = p.uid AND ucm.type_id=9)
      LEFT JOIN users_pi pi ON (pi.uid = p.uid)
      $EXT_TABLES
      WHERE e.payments_id = ?;",
    undef,
    { Bind => [ $id ], COLS_NAME => 1 }
  );

  return $self->{list} || [];
}

#**********************************************************
=head2 add($payments_id, $api)

=cut
#**********************************************************
sub add {
  my $self = shift;
  my ($payment_id, $api) = @_;

  $self->query('INSERT INTO extreceipts (`payments_id`, `api`)
      VALUES (?, ?);',
    'do',
    { Bind => [ $payment_id, $api ] }
  );

  return 1;
}

#**********************************************************
=head2 get_new_payments($start_id)

=cut
#**********************************************************
sub get_new_payments {
  my $self = shift;
  my ($start_id) = @_;

  $self->query('SELECT id FROM payments ORDER BY id DESC LIMIT 1;',
    undef,
    { }
  );
  my $last_id = $self->{list}[0][0];

  if ($self->{TOTAL} < 1) {
    $self->{error}=111;
    $self->{errstr}="NO KKT_LIST VALUES";
    return 0;
  }

  my $kkt_list = $self->kkt_list();

  my $CASE = "CASE\n";
  foreach my $kkt (@$kkt_list) {
    my @request_params = ();
    if (!$kkt->{methods}) {
      next;
    }

    if ($kkt->{groups}) {
      push @request_params, "u.gid IN ($kkt->{groups})";
    }

    if($kkt->{aid}){
      push @request_params, "p.aid IN ($kkt->{aid})";
    }

    push @request_params, "p.method IN ($kkt->{methods})";
    $CASE .= ' WHEN ' . join(' AND ', @request_params) ." THEN $kkt->{kkt_id}\n";
  }

  $CASE .= "ELSE 0\nEND as kkt_id\n";

  $self->query('INSERT INTO extreceipts (payments_id, kkt_id) '
      . 'SELECT p.id, '. $CASE .'
      FROM payments p
      LEFT JOIN users u ON (u.uid = p.uid)
      WHERE p.id NOT IN (SELECT payments_id FROM extreceipts)
      AND p.id > ? AND p.id <= ? 
      HAVING kkt_id > 0;',
    'do',
    { Bind => [ $start_id, $last_id ] }
  );

  $self->{LAST_ID} = $last_id;

  return 1;
}

#**********************************************************
=head2 change($attr)

=cut
#**********************************************************
sub change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'PAYMENTS_ID',
    TABLE        => 'extreceipts',
    DATA         => $attr
  });
  
  return 1;
}

#**********************************************************
=head2 payments_list($attr)

=cut
#**********************************************************
sub payments_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  my $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $WHERE =  $self->search_former($attr, [
      ['ID',                'INT', 'p.id',                               1 ],
      ['DATETIME',          'DATE','p.date',   'p.date AS datetime'        ],
      ['LOGIN',             'STR', 'u.id',         'u.id AS login'         ],
      ['SUM',               'INT', 'p.sum',                              1 ],
      ['PAYMENT_METHOD',    'INT', 'p.method', 'p.method as payment_method'],
      ['FROM_DATE|TO_DATE', 'DATE', 'DATE_FORMAT(p.date, \'%Y-%m-%d\')'    ],
      ['FDA',               'STR', 'e.fda',                              1 ],
      ['FDN',               'STR', 'e.fdn',                              1 ],
      ['COMMAND_ID',        'STR', 'e.command_id',                       1 ],
      ['STATUS',            'INT', 'e.status',                           1 ],
      ['EXTST',             'INT', 'e.status as extst',                  1 ],
    ],
    { WHERE => 1 }
  );

  $self->query("SELECT
      $self->{SEARCH_FIELDS}
      p.uid
      FROM payments p
      LEFT JOIN extreceipts e ON (p.id = e.payments_id)
      LEFT JOIN users u ON (u.uid = p.uid)
      $WHERE
      ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    { %$attr, COLS_NAME => 1, COLS_UPPER => 1 }
  );

  my $list = $self->{list};

  $self->query("SELECT COUNT(*) AS total, SUM(sum) AS total_sum
      FROM payments p
      LEFT JOIN extreceipts e ON (p.id = e.payments_id)
      LEFT JOIN users u ON (u.uid = p.uid)
      $WHERE;",
    undef,
    { INFO => 1 }
  );

  return $list;
}

#**********************************************************
=head2 kkt_add($attr)

=cut
#**********************************************************
sub kkt_add {
  my $self = shift;
  my ($attr) = @_;
  
  $self->query_add( 'extreceipts_kkt', $attr );

  return 1;
}

#**********************************************************
=head2 kkt_list($attr)

=cut
#**********************************************************
sub kkt_list {
  my $self = shift;
  my ($attr) = @_;

  my $WHERE =  $self->search_former($attr, [
      ['KKT_ID',   'INT', 'ek.kkt_id',           1],
      ['API_ID',   'INT', 'ek.api_id',           1],
    ],
    { WHERE => 1 }
  );

  $self->query("SELECT
      $self->{SEARCH_FIELDS}
      ek.*,
      ea.api_name,
      ea.conf_name
      FROM extreceipts_kkt ek
      LEFT JOIN extreceipts_api ea ON (ek.api_id = ea.api_id)
      $WHERE;",
    undef,
    { COLS_NAME => 1, COLS_UPPER => 1 }
  );

  return $self->{list};
}

#**********************************************************
=head2 kkt_change($attr)

=cut
#**********************************************************
sub kkt_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'KKT_ID',
    TABLE        => 'extreceipts_kkt',
    DATA         => $attr
  });
  
  return 1;
}

#**********************************************************
=head2 kkt_del($kkt_id)

=cut
#**********************************************************
sub kkt_del {
  my $self = shift;
  my ($kkt_id) = @_;
  
  $self->query_del( 'extreceipts_kkt', {}, { KKT_ID => $kkt_id } );

  return 1;
}

#**********************************************************
=head2 api_add($attr)

=cut
#**********************************************************
sub api_add {
  my $self = shift;
  my ($attr) = @_;

  if ($attr->{PASSWORD}) {
    $attr->{PASSWORD} = "ENCODE('$attr->{PASSWORD}', '$self->{conf}->{secretkey}')",
  }

  $self->query_add( 'extreceipts_api', $attr );

  return 1;
}

#**********************************************************
=head2 api_list($attr)

=cut
#**********************************************************
sub api_list {
  my $self = shift;
  my ($attr) = @_;

  my $WHERE =  $self->search_former($attr, [
      ['CONF_NAME', 'STR', 'ea.conf_name',       1],
      ['API_ID',    'INT', 'ea.api_id',          1],
      ['AID',       'int', 'ea.aid',             1]
    ],
    { WHERE => 1 }
  );

  $self->query(
    "SELECT *, DECODE(password, ?) as password FROM `extreceipts_api` ea ". $WHERE .';',
    undef,
    { COLS_NAME => 1, COLS_UPPER => 1, Bind => [ $self->{conf}->{secretkey} ] }
  );

  return $self->{list};
}

#**********************************************************
=head2 api_change($attr)

=cut
#**********************************************************
sub api_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'API_ID',
    TABLE        => 'extreceipts_api',
    DATA         => $attr
  });
  
  return 1;
}

#**********************************************************
=head2 api_del($api_id)

=cut
#**********************************************************
sub api_del {
  my $self = shift;
  my ($api_id) = @_;
  
  $self->query_del( 'extreceipts_api', {}, { API_ID => $api_id } );

  return 1;
}

1;