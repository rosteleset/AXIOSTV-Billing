package Docs;

=head1 NAME

 Documents functions functions

=cut

use strict;
use parent qw(dbcore);
my $MODULE = 'Docs';
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

  $self->{DOCS_ACCOUNT_EXPIRE_PERIOD} = ($CONF->{DOCS_ACCOUNT_EXPIRE_PERIOD}) ? $CONF->{DOCS_ACCOUNT_EXPIRE_PERIOD} : 30;
  $CONF->{DOCS_INVOICE_ORDERS}=12 if (! $CONF->{DOCS_INVOICE_ORDERS});
  $CONF->{DOCS_ACCOUNT_EXPIRE_DAY}=0 if (! $CONF->{DOCS_ACCOUNT_EXPIRE_DAY});
  $CONF->{DOCS_PRE_INVOICE_PERIOD}=10 if (! defined($CONF->{DOCS_PRE_INVOICE_PERIOD}));

  $self->{db}=$db;
  $self->{admin}=$admin;
  $self->{conf}=$CONF;

  return $self;
}

#**********************************************************
# Default values
#**********************************************************
sub invoice_defaults {
  my $self = shift;

  my %DATA = (
    SUM             => '0.00',
    COUNTS          => 1,
    UNIT            => 1,
    PAYMENT_ID      => 0,
    PHONE           => '',
    VAT             => '',
    DEPOSIT         => 0,
    DELIVERY_STATUS => 0,
    EXCHANGE_RATE   => 0,
    DOCS_CURRENCY   => 0,
    CUSTOMER        => '',
  );

  $self = \%DATA;
  return $self;
}

#**********************************************************
=head2 docs_receipt_list($attr)

=cut
#**********************************************************
sub docs_receipt_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT      = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC      = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  $self->{SEARCH_FIELDS} = 0;
  my $WHERE =  $self->search_former($attr, [
      ['RECEIPT_NUM',    'INT', 'd.receipt_num',                      ],
      ['DATETIME',       'DATE','d.date',   'd.date AS datetime',   1 ],
      ['CUSTOMER',       'STR', "d.customer", 1],
      #"if(d.customer='-' or d.customer='', pi.fio, d.customer) AS customer" ],
      ['TOTAL_SUM',      'INT', 'o.price * o.counts', 'SUM(o.price * o.counts) AS total_sum' ],
      ['LOGIN',          'STR', 'u.id', 'u.id AS login',              ],
      ['PAYMENT_METHOD', 'INT', 'p.method',   'p.method AS payment_method' ],
      ['PAYMENT_ID',     'INT', 'd.payment_id',                     1 ],
      ['ADMIN_NAME',            'INT', 'a.id', 'a.name AS admin_name'        ],
      ['FROM_DATE|TO_DATE','INT', "DATE_FORMAT(d.date, '%Y-%m-%d')"   ],
      ['PHONE',          'INT', 'IF(d.phone<>0, d.phone, pi.phone)', 'IF(d.phone<>0, d.phone, pi.phone) AS phone'   ],
      ['UID',            'INT', 'd.uid',                             1  ],
      ['CREATED',        'INT', 'd.created' ,                             1 ],
      ['AID',            'INT', 'd.aid' ,                              ],
    ],
    { WHERE        => 1,
      USERS_FIELDS => 1,
      SKIP_USERS_FIELDS=> [ 'PHONE', 'UID', 'LOGIN' ],
      USE_USER_PI  => 1
    }
  );

  if ($attr->{ORDERS_LIST}) {
    $self->query("SELECT o.receipt_id, o.orders, o.unit, o.counts, o.price, o.fees_id
      FROM docs_receipts d
      INNER JOIN docs_receipt_orders o ON (d.id=o.receipt_id)
      $WHERE;"
    );

    return $self->{list} if ($self->{TOTAL} < 1);
    my $list = $self->{list};
    return $list;
  }

  my $EXT_TABLES = $self->{EXT_TABLES} || '';

  if ($self->{SEARCH_FIELDS} =~ /a\./) {
    $EXT_TABLES .= 'LEFT JOIN admins a ON (d.aid=a.aid)';
  }

  if ($self->{SEARCH_FIELDS} =~ /p\./) {
    $EXT_TABLES .= 'LEFT JOIN payments p ON (d.payment_id=p.id)';
  }

  $self->query("SELECT d.receipt_num,
     $self->{SEARCH_FIELDS}
     d.uid,
     d.id
    FROM docs_receipts d
    LEFT JOIN docs_receipt_orders o ON (o.receipt_id=d.id)
    LEFT JOIN users u ON (d.uid=u.uid)
    $EXT_TABLES
    $WHERE
    GROUP BY d.id
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  return $self->{list} if ($self->{TOTAL} < 1);
  my $list = $self->{list};

  $self->query("SELECT COUNT(DISTINCT d.receipt_num) AS total
    FROM docs_receipts d
    LEFT JOIN docs_receipt_orders o ON (d.id=o.receipt_id)
    LEFT JOIN users u ON (d.uid=u.uid)
    $EXT_TABLES
    $WHERE", undef, { INFO => 1 }
  );

  return $list;
}

#**********************************************************
=head2 docs_receipt_new()

=cut
#**********************************************************
sub docs_receipt_new {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $WHERE =  $self->search_former($attr, [
    ['UID',            'INT', 'f.uid'                              ],
    ['LOGIN',          'STR', 'u.id'                               ],
    ['BILL_ID',        'INT', 'f.bill_id'                          ],
    ['COMPANY_ID',     'INT', 'u.company_id',                      ],
    ['AID',            'INT', 'f.aid',                             ],
    ['ID',             'INT', 'f.id',                              ],
    ['A_LOGIN',        'STR', 'a.id',                              ],
    ['SUM',            'INT', 'f.sum',                             ],
    ['DOMAIN_ID',      'INT', 'u.domain_id',                       ],
    ['METHOD',         'INT', 'f.method',                          ],
    ['DESCRIBE',       'STR', 'f.dsc',                             ],
    ['INNER_DESCRIBE', 'STR', 'f.inner_describe',                  ],
    ['DATE',           'DATE',   'DATE_FORMAT(f.date, \'%Y-%m-%d\')',  ],
    ['FROM_DATE|TO_DATE','DATE', 'DATE_FORMAT(f.date, \'%Y-%m-%d\')'   ],
    ['MONTH',          'DATE',   "DATE_FORMAT(f.date, '%Y-%m')"   ],
  ],
    { WHERE => 1,
    }
  );

  $self->query("SELECT f.id, u.id, f.date, f.dsc, f.sum, io.fees_id,
    f.last_deposit,
    f.method,
    f.bill_id,
    IF(a.name is NULL, 'Unknown', a.name),
    INET_NTOA(f.ip),
    f.uid,
    f.inner_describe
  FROM fees f
  LEFT JOIN users u ON (u.uid=f.uid)
  LEFT JOIN admins a ON (a.aid=f.aid)
  LEFT JOIN docs_receipt_orders io ON (io.fees_id=f.id)
  $WHERE
  GROUP BY f.id
  ORDER BY $SORT $DESC
  LIMIT $PG, $PAGE_ROWS;"
  );

  my $list = $self->{list};

  return $list;
}

#**********************************************************
=head2 docs_receipt_info($id, $attr)

=cut
#**********************************************************
sub docs_receipt_info {
  my $self = shift;
  my ($id, $attr) = @_;

  my $WHERE = ($attr->{UID}) ? "AND d.uid='$attr->{UID}'" : '';

  $self->query("SELECT
   d.receipt_num,
   d.date,
   d.customer,
   SUM(o.price * o.counts) AS total_sum,
   d.phone,
   IF(d.vat>0, FORMAT(SUM(o.price * o.counts) / ((100+d.vat)/ d.vat), 2), FORMAT(0, 2)) AS vat,
   a.name AS admin,
   u.id AS login,
   d.created,
   d.by_proxy_seria,
   d.by_proxy_person,
   d.by_proxy_date,
   d.id AS doc_id,
   d.uid,
   d.date + interval $self->{DOCS_ACCOUNT_EXPIRE_PERIOD} day AS expire_date,
   d.payment_id,
   d.deposit,
   d.delivery_status,
   d.exchange_rate,
   d.currency,
   p.method AS payment_method

  FROM docs_receipts d
  LEFT JOIN docs_receipt_orders o ON (d.id=o.receipt_id)
  LEFT JOIN users u ON (d.uid=u.uid)
  LEFT JOIN admins a ON (d.aid=a.aid)
  LEFT JOIN payments p ON (d.payment_id=p.id)
  WHERE d.id=? $WHERE
  GROUP BY d.id;",
    undef,
    { INFO => 1,
      Bind => [ $id ] }
  );

  $self->{AMOUNT_FOR_PAY} = ($self->{DEPOSIT} < 0) ? abs($self->{DEPOSIT}) : 0 - $self->{DEPOSIT};

  if ($self->{TOTAL} > 0) {
    $self->{NUMBER} = $self->{RECEIPT_NUM};
    $self->query("SELECT receipt_id, orders, unit, counts, price, fees_id, '$self->{LOGIN}'
        FROM docs_receipt_orders WHERE receipt_id= ? ",
      undef,
      { Bind => [ $id ] });

    $self->{ORDERS} = $self->{list};
  }

  return $self;
}

#**********************************************************
=head2 docs_receipt_add($attr)

=cut
#**********************************************************
sub docs_receipt_add {
  my $self = shift;
  my ($attr) = @_;

  if ($attr->{ORDER}) {
    $attr->{IDS}       = 1;
    $attr->{'ORDER_1'} = $attr->{ORDER};
    $attr->{'SUM_1'}   = $attr->{SUM};
  }

  if (!$attr->{IDS}) {
    $self->{errno}  = 1;
    $self->{errstr} = "No orders";
    return $self;
  }

  $attr->{RECEIPT_NUM} = ($attr->{RECEIPT_NUM}) ? $attr->{RECEIPT_NUM} : $self->docs_nextid({ TYPE => 'RECEIPT' });

  $self->query_add('docs_receipts', {
    %$attr,
    DATE     => ($attr->{DATE}) ? "$attr->{DATE}" : 'NOW()',
    CREATED  => 'NOW()',
    AID      => $admin->{AID},
    CURRENCY => $attr->{DOCS_CURRENCY},
  });

  return [ ] if ($self->{errno});
  $self->{DOC_ID} = $self->{INSERT_ID};

  my @ids = split(/, /, $attr->{IDS});
  my @MULTI_QUERY = ();

  foreach my $id (@ids) {
    push @MULTI_QUERY, [ $self->{DOC_ID},
      $attr->{ 'ORDER_' . $id } || '',
      ((!$attr->{ 'COUNT_' . $id }) ? 1 : $attr->{ 'COUNT_' . $id }),
      $attr->{ 'UNIT_' . $id } || 0,
      $attr->{ 'SUM_' . $id } || 0,
      $attr->{ 'FEES_ID_' . $id } || 0
    ];
  }

  $self->query("INSERT INTO docs_receipt_orders (receipt_id, orders, counts, unit, price, fees_id)
        VALUES (?, ?, ?, ?, ?, ?);",
    undef,
    { MULTI_QUERY =>  \@MULTI_QUERY });

  return [ ] if ($self->{errno});

  $self->docs_receipt_info($self->{DOC_ID});

  return $self;
}

#**********************************************************
=head2 docs_receipt_del($id, $attr)

=cut
#**********************************************************
sub docs_receipt_del {
  my $self = shift;
  my ($id) = @_;

  $self->query_del('docs_receipt_orders', undef, { receipt_id => $id  });
  $self->query_del('docs_receipts', { ID  => $id });

  return $self;
}

#**********************************************************
=head2 invoices2payments($attr)

=cut
#**********************************************************
sub invoices2payments {
  my $self =shift;
  my ($attr) = @_;

  $self->query_add('docs_invoice2payments', $attr);

  return $self;
}

#**********************************************************
=head2 invoices2payments_list($attr)

=cut
#**********************************************************
sub invoices2payments_list {
  my $self =shift;
  my ($attr) = @_;

  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  my $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my @WHERE_RULES = ();

  if ($attr->{UNINVOICED}) {
    push @WHERE_RULES, '(i2p.invoice_id IS NULL OR p.sum>(SELECT SUM(sum) FROM docs_invoice2payments WHERE payment_id=p.id))';
  }

  my $WHERE =  $self->search_former($attr, [
    ['UID',              'INT',  'p.uid'                              ],
    ['INVOICE_ID',       'INT',  'i2p.invoice_id'                     ],
    ['PAYMENT_ID',       'INT',  'i2p.payment_id',                    ],
    ['DATE',             'DATE', 'date_format(d.date, \'%Y-%m-%d\')'  ],
    ['FROM_DATE|TO_DATE','DATE', 'date_format(d.date, \'%Y-%m-%d\')'  ],
  ],
    { WHERE => 1,
      WHERE_RULES => \@WHERE_RULES
    }
  );

  $self->query("SELECT p.id AS payment_id, p.date, p.dsc,
      p.sum AS payment_sum,
      i2p.sum AS invoiced_sum,
      i2p.invoice_id,
      p.uid,
      p.amount,
      d.invoice_num
   FROM payments p
   LEFT JOIN docs_invoice2payments i2p ON (p.id=i2p.payment_id)
   LEFT JOIN docs_invoices d ON (d.id=i2p.invoice_id)
   $WHERE
   ORDER BY $SORT $DESC
   LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr);

  return $self->{list};
}

#**********************************************************
=head2 invoices_list($attr)

=cut
#**********************************************************
sub invoices_list {
  my $self = shift;
  my ($attr) = @_;

  if ($attr->{ALT_SUM} eq '_SHOW') {
    $attr->{CURRENCY} = '_SHOW';
  }

  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  my $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  delete $self->{ORDERS};
  delete $self->{SEARCH_FIELDS};
  delete $self->{errno};

  my @WHERE_RULES = ();

  if ($SORT == 1 && ! $attr->{DESC}) {
    $SORT = "2 DESC, 1";
    $DESC = "DESC";
  }

  my $vat = ($attr->{VAT}) ? $attr->{VAT} : '20';

  if ($attr->{UNINVOICED}) {
    my $WHERE = '';

    if ($attr->{PAYMENT_ID}) {
      $WHERE = "AND p.id='$attr->{PAYMENT_ID}'";
    }

    $self->query("SELECT p.id, p.date, p.dsc,
      p.sum AS payment_sum,
      SUM(i2p.sum) AS invoiced_sum,
      IF(i2p.sum IS NULL, p.sum, p.sum - SUM(i2p.sum)) AS remains,
      i2p.invoice_id,
      p.uid
    FROM payments p
    LEFT JOIN docs_invoice2payments i2p ON (p.id=i2p.payment_id)
    WHERE p.uid='$attr->{UID}'
      AND (i2p.invoice_id IS NULL OR p.sum>(SELECT SUM(sum) FROM docs_invoice2payments WHERE payment_id=p.id))
      $WHERE
    GROUP BY p.id
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;",
      undef,
      $attr);

    my $list = $self->{list};
    return $list;
  }

  if($attr->{DELL_UNPAID_INVOICE}){
    my $WHERE = $self->search_former($attr, [
      #['LOGIN',          'STR', 'u.id AS login',                   1 ],
      ['ID',             'INT', 'd.id'                               ],
      ['CUSTOMER',       'STR', 'd.customer',                        ], #'IF(d.customer=\'-\' OR d.customer=\'\', pi.fio, d.customer) AS customer ' ],
      ['DOC_ID',         'INT', 'd.invoice_num'                      ],
      ['SUM',            'INT', 'o.price * o.counts'                 ],
      ['SUM_VAT',            'INT', '(o.price * o.counts) * ('. $vat .' / 100)',
        '(o.price * o.counts) * ('. $vat .' / 100)'. ' AS sum_vat'    ],
      ['PAYMENT_METHOD', 'INT', 'p.method AS payment_method',      1 ],
#      ['PAYMENT_ID',     'INT', 'd.payment_id',                      ],
      ['EXT_ID',         'INT', 'p.ext_id',                        1 ],
      ['ADMIN_NAME',     'INT', 'a.id',       'a.name AS admin_name' ],
      ['AID',            'INT', 'a.id',       'a.name AS admin_name' ],
      ['CREATED',        'DATE','d.created',                       1 ],
      ['ALT_SUM',        'INT', 'IF(d.exchange_rate>0, SUM(o.price * o.counts) * d.exchange_rate, 0.00) AS alt_sum', 1 ],
      ['EXCHANGE_RATE',  'INT', 'd.exchange_rate',                 1 ],
      ['CURRENCY',       'INT', 'd.currency',                      1 ],
      ['DOCS_DEPOSIT',   'INT', 'd.deposit',  'd.deposit AS docs_deposit' ],
      ['DATE',           'DATE', "DATE_FORMAT(d.date, '%Y-%m-%d')"   ],
      ['FROM_DATE|TO_DATE','DATE', "DATE_FORMAT(d.date, '%Y-%m-%d')" ],
      ['UID',            'INT', 'd.uid',                             ],
      ['FEES_ID',        'INT', 'o.fees_id', 1                       ]
    ],
      {
        WHERE            => 1,
        WHERE_RULES      => \@WHERE_RULES,
      }
    );

    my $EXT_TABLES  = $self->{EXT_TABLES} || '';

    if ($self->{SEARCH_FIELDS} =~ /p\./) {
      $EXT_TABLES .= "
    LEFT JOIN docs_invoice2payments i2p ON (d.id=i2p.invoice_id)
    LEFT JOIN payments p ON (i2p.payment_id=p.id)
    ";
    }

    $self->query("SELECT d.invoice_num,
     d.date,
     $self->{SEARCH_FIELDS}
      d.uid,
      d.id
    FROM docs_invoices d
    INNER JOIN docs_invoice_orders o ON (d.id=o.invoice_id)
    LEFT JOIN users u ON (d.uid=u.uid)
    LEFT JOIN admins a ON (d.aid=a.aid)
    $EXT_TABLES
    $WHERE
    GROUP BY d.id
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;",
      undef,
      $attr
    );

    my $list = $self->{list};

    return $list;
  }

  if ($attr->{PAID_STATUS}) {
    $attr->{UNPAIMENT}=$attr->{PAID_STATUS};
  }

  my $HAVING = '';
  if ($attr->{UNPAIMENT}) {
    if ($attr->{UNPAIMENT} == 2) {
      push @WHERE_RULES, "(
       ( (SELECT SUM(sum) FROM  docs_invoice2payments WHERE invoice_id=d.id)
       =
        (SELECT SUM(orders.counts*orders.price) FROM docs_invoice_orders orders WHERE orders.invoice_id=d.id)))" . (( $attr->{ID} ) ? "d.id='$attr->{ID}'" : '');
    }
    else {
      $HAVING = "HAVING total_sum - if(payment_sum<>'', payment_sum, 0)  > 0";
    }
  }

  $attr->{FIO}='_SHOW' if ($attr->{CUSTOMER});
  $self->{EXT_TABLES} = '';

  my $WHERE = $self->search_former($attr, [
    ['ID',             'INT', 'd.id'                               ],
    ['CUSTOMER',       'STR', 'IF(d.customer=\'-\' OR d.customer=\'\', pi.fio, d.customer)',
        'IF(d.customer=\'-\' OR d.customer=\'\', pi.fio, d.customer) AS customer ' ], # 'd.customer'
    ['DOC_ID',         'INT', 'd.invoice_num'                      ],
    ['SUM',            'INT', 'o.price * o.counts', 'SUM(o.price * o.counts) AS invoice_sum' ],
    ['SUM_VAT',            'INT', '(o.price * o.counts) * ('. $vat .' / 100)',
      '(o.price * o.counts) * ('. $vat .' / 100)' . ' AS sum_vat'    ],
    ['ORDERS',         'STR', '',
      "(SELECT GROUP_CONCAT(CONCAT(orders, ' - ', counts * price)  SEPARATOR ';;') FROM `docs_invoice_orders` orders WHERE orders.invoice_id=d.id) AS orders" ],
    ['REPRESENTATIVE', 'STR', 'company.representative',          1 ],
    ['PAYMENT_METHOD', 'INT', 'p.method AS payment_method',      1 ],
    ['PAYMENT_ID',     'INT', 'd.payment_id',                      ],
    ['EXT_ID',         'INT', 'p.ext_id',                        1 ],
    ['ADMIN_NAME',     'INT', 'a.id',       'a.name AS admin_name' ],
    ['AID',            'INT', 'a.id',       'a.name AS admin_name' ],
    ['CREATED',        'DATE','d.created',                       1 ],
    ['ALT_SUM',        'INT', 'IF(d.exchange_rate>0, SUM(o.price * o.counts) * d.exchange_rate, 0.00) AS alt_sum', 1 ],
    ['EXCHANGE_RATE',  'INT', 'd.exchange_rate',                 1 ],
    ['CURRENCY',       'INT', 'd.currency',                      1 ],
    ['DOCS_DEPOSIT',   'INT', 'd.deposit',  'd.deposit AS docs_deposit' ],
    ['DATE',           'DATE', "date_format(d.date, '%Y-%m-%d')"   ],
    ['FROM_DATE|TO_DATE','DATE', "date_format(d.date, '%Y-%m-%d')" ],
    ['FULL_INFO',      '',    '', "pi.address_street, pi.address_build, pi.address_flat, if (d.phone<>0, d.phone, pi.phone) AS phone,
   pi.contract_id, pi.contract_date,  if(u.company_id > 0, company.bill_id, u.bill_id) AS bill_id,  pi.email,  pi.fio" ],
    ['UID',            'INT', 'd.uid',                             ],
    ['TYPE_FEES',      'INT', 'o.type_fees_id',                     ],
    ['FEES_ID',        'INT', 'o.fees_id', 1                       ]
  ],
    { WHERE            => 1,
      WHERE_RULES      => \@WHERE_RULES,
      USERS_FIELDS     => 1,
      SKIP_USERS_FIELDS=> [ 'UID' ],
      USE_USER_PI      => 1
    }
  );

  my $EXT_TABLES  = $self->{EXT_TABLES} || '';

  if ($self->{SEARCH_FIELDS} =~ /p\./) {
    $EXT_TABLES .= "
    LEFT JOIN docs_invoice2payments i2p ON (d.id=i2p.invoice_id)
    LEFT JOIN payments p ON (i2p.payment_id=p.id)
    ";
  }

  $self->query("SELECT d.invoice_num,
     d.date,
     SUM(o.price * o.counts) AS total_sum,
     (SELECT SUM(i2p.sum) FROM docs_invoice2payments i2p
              WHERE d.id=i2p.invoice_id
      ) AS payment_sum,
     $self->{SEARCH_FIELDS}
     d.uid,
     d.id
    FROM docs_invoices d
    INNER JOIN docs_invoice_orders o ON (d.id=o.invoice_id)
    LEFT JOIN users u ON (d.uid=u.uid)
    LEFT JOIN admins a ON (d.aid=a.aid)
    $EXT_TABLES
    $WHERE
    GROUP BY d.id
    $HAVING
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  return [] if ($self->{TOTAL} < 1);
  my $list = $self->{list};

  my $q = '';

  if ($attr->{UNPAIMENT}) {
    $q = "SUM((SELECT COUNT(i2p.sum) FROM docs_invoice2payments i2p
         WHERE d.id=i2p.invoice_id
      )) AS payment_count";
  }
  else {
    $q = " SUM((SELECT SUM(i2p.sum) FROM docs_invoice2payments i2p
         WHERE d.id=i2p.invoice_id
      )) AS payment_sum";
  }

  $self->query("SELECT COUNT(DISTINCT d.id) AS total_invoices,
     COUNT(DISTINCT d.uid) AS total_users,
     SUM((SELECT SUM(o.price * o.counts) FROM docs_invoice_orders o WHERE o.invoice_id=d.id)) AS total_sum,
     $q
    FROM docs_invoices d
    INNER JOIN docs_invoice_orders o ON (d.id=o.invoice_id)
    LEFT JOIN users u ON (d.uid=u.uid)
    LEFT JOIN admins a ON (d.aid=a.aid)
    $EXT_TABLES
    $WHERE
    ",
    undef,
    { INFO => 1 }
  );

  $self->{TOTAL_} = $self->{TOTAL_INVOICES};
  if( $self->{PAYMENT_COUNT}) {
    $self->{TOTAL_INVOICES} = $self->{TOTAL_INVOICES} - $self->{PAYMENT_COUNT};
  }

  if ($attr->{ORDERS_LIST}) {
    $self->query("SELECT  o.invoice_id,  o.orders,  o.unit,  o.counts,  o.price,  o.fees_id
    FROM  docs_invoice_orders o
    WHERE o.invoice_id IN (SELECT d.id
      FROM docs_invoices d
      LEFT JOIN users u ON (d.uid=u.uid)
      LEFT JOIN admins a ON (d.aid=a.aid)
      $EXT_TABLES
      $WHERE);",
      undef,
      $attr
    );

    foreach my $line ( @{  $self->{list} } ) {
      if (ref $line eq 'HASH') {
        push @{ $self->{ORDERS}{int($line->{invoice_id})} }, $line;
      }
    }
  }

  $self->{TOTAL}=$self->{TOTAL_} || $self->{TOTAL_INVOICES};

  return $list;
}

#**********************************************************
=head2 docs_invoice_reports($attr)

=cut
#**********************************************************
sub docs_invoice_reports {
  my $self = shift;
  my ($attr) = @_;

  my $SORT      = ($attr->{sort})      ? $attr->{sort}      : 1;
  my $DESC      = ($attr->{desc})      ? $attr->{desc}      : '';
  my $PG        = ($attr->{pg})        ? $attr->{pg}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $WHERE = $self->search_former($attr, [
    ['FROM_DATE|TO_DATE', 'DATE', "DATE_FORMAT(d.date, '%Y-%m-%d')" ],
  ],
    {
      WHERE            => 1,
      USERS_FIELDS     => 1,
      USE_USER_PI      => 1,
    }
  );

  my $HAVING = "";

  if ($attr->{INVOICES_TYPES} eq 'UNPAID') {
    $HAVING = "HAVING total_sum > if(payment_sum<>'', payment_sum, 0)";
  }

  if ($attr->{INVOICES_TYPES} eq 'PAID') {
    $HAVING = "HAVING total_sum <= if(payment_sum<>'', payment_sum, 0)";
  }

  $self->query("SELECT d.invoice_num,
     d.date,
     if(d.customer='-' or d.customer='', pi.fio, d.customer) AS customer,
     SUM(o.price * o.counts) AS total_sum,
     (SELECT SUM(i2p.sum) FROM docs_invoice2payments i2p
              WHERE d.id=i2p.invoice_id
      ) AS payment_sum,
     d.payment_id,
     d.uid,
     d.id
    FROM docs_invoices d
    INNER JOIN docs_invoice_orders o ON (d.id=o.invoice_id)
    LEFT JOIN users u ON (d.uid=u.uid)
    LEFT JOIN admins a ON (d.aid=a.aid)
    LEFT JOIN docs_invoice2payments i2p ON (d.id=i2p.invoice_id)
    LEFT JOIN payments p ON (i2p.payment_id=p.id)
    LEFT JOIN users_pi pi ON (pi.uid=u.uid)
    LEFT JOIN tags_users ON (u.uid=tags_users.uid )
    $WHERE
    GROUP BY d.id
    $HAVING
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;",
    undef,
    { COLS_NAME => 1 }
  );

  my $list = $self->{list};

  $self->query("SELECT d.invoice_num,
     d.date,
     if(d.customer='-' or d.customer='', pi.fio, d.customer) AS customer,
     SUM(o.price * o.counts) AS total_sum,
     (SELECT SUM(i2p.sum) FROM docs_invoice2payments i2p
              WHERE d.id=i2p.invoice_id
      ) AS payment_sum,
     d.payment_id,
     d.uid,
     d.id
    FROM docs_invoices d
    INNER JOIN docs_invoice_orders o ON (d.id=o.invoice_id)
    LEFT JOIN users u ON (d.uid=u.uid)
    LEFT JOIN admins a ON (d.aid=a.aid)
    LEFT JOIN docs_invoice2payments i2p ON (d.id=i2p.invoice_id)
    LEFT JOIN payments p ON (i2p.payment_id=p.id)
    LEFT JOIN users_pi pi ON (pi.uid=u.uid)
    LEFT JOIN tags_users ON (u.uid=tags_users.uid )
    $WHERE
    GROUP BY d.id
    $HAVING;",
    undef,
    { COLS_NAME => 1 }
  );

  return $list;
}

#**********************************************************
=head2 docs_nextid($attr)

=cut
#**********************************************************
sub docs_nextid {
  my $self = shift;
  my ($attr) = @_;

  my $sql = '';

  my $date = ($attr->{DATE} =~ /\d{4}-\d{2}-\d{2}/) ? "'$attr->{DATE}'" : 'curdate()';

  if ($attr->{TYPE} eq 'INVOICE') {
    $sql = "SELECT MAX(d.invoice_num), COUNT(*) FROM docs_invoices d
     WHERE YEAR(date)=YEAR($date);";
  }
  elsif ($attr->{TYPE} eq 'RECEIPT') {
    $sql = "SELECT MAX(d.receipt_num), COUNT(*) FROM docs_receipts d
     WHERE YEAR(date)=YEAR($date);";
  }
  elsif ($attr->{TYPE} eq 'TAX_INVOICE') {
    $sql = "SELECT MAX(d.tax_invoice_id), COUNT(*) FROM docs_tax_invoices d
     WHERE YEAR(date)=YEAR($date);";
  }
  elsif ($attr->{TYPE} eq 'ACT') {
    $sql = "SELECT MAX(d.act_id), COUNT(*) FROM docs_acts d
     WHERE YEAR(date)=YEAR($date);";
  }

  $self->query("$sql");

  if ($self->{TOTAL} > 0) {
    ($self->{NEXT_ID}, $self->{TOTAL}) = @{ $self->{list}->[0] };
  }

  $self->{NEXT_ID}++;
  return $self->{NEXT_ID};
}

#**********************************************************
=head2 invoice_new($attr)

=cut
#**********************************************************
sub invoice_new {
  my $self = shift;
  my ($attr) = @_;

  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  my $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $WHERE =  $self->search_former($attr, [
    ['UID',            'INT', 'f.uid'                              ],
    ['LOGIN',          'STR', 'u.id'                               ],
    ['BILL_ID',        'INT', 'f.bill_id'                          ],
    ['COMPANY_ID',     'INT', 'u.company_id',                      ],
    ['AID',            'INT', 'f.aid',                             ],
    ['ID',             'INT', 'f.id',                              ],
    ['A_LOGIN',        'STR', 'a.id',                              ],
    ['SUM',            'INT', 'f.sum',                             ],
    ['DOMAIN_ID',      'INT', 'u.domain_id',                       ],
    ['METHOD',         'INT', 'f.method',                          ],
    ['DESCRIBE',       'STR', 'f.dsc',                             ],
    ['INNER_DESCRIBE', 'STR', 'f.inner_describe',                  ],
    ['MONTH',          'DATE', "DATE_FORMAT(f.date, '%Y-%m')"      ],
    ['DATE',           'DATE', 'DATE_FORMAT(f.date, \'%Y-%m-%d\')' ],
    ['FROM_DATE|TO_DATE','DATE', 'DATE_FORMAT(f.date, \'%Y-%m-%d\')'],
    ['TAX',            'INT', 'ft.tax',                          1 ],
  ],
    { WHERE => 1,
    }
  );

  my $EXT_TABLES = q{};
  if($attr->{TAX}) {
    $EXT_TABLES  .= " LEFT JOIN fees_types ft ON (ft.id=f.method)";
  }

  $self->query("SELECT f.id,
      u.id AS login,
      f.date,
      f.dsc,
      f.sum,
      ao.fees_id,
   f.last_deposit,
   f.method,
   f.bill_id,
   IF(a.name is NULL, 'Unknown', a.name) AS admin_name,
   INET_NTOA(f.ip) as ip,
   f.uid,
   $self->{SEARCH_FIELDS}
   f.inner_describe
  FROM fees f
  $EXT_TABLES
  LEFT JOIN users u ON (u.uid=f.uid)
  LEFT JOIN admins a ON (a.aid=f.aid)
  LEFT JOIN docs_invoice_orders ao ON (ao.fees_id=f.id)
  $WHERE
  GROUP BY f.id
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  return $self->{list} || [] if ($self->{TOTAL} < 1);
  my $list = $self->{list};

  return $list;
}

#**********************************************************
=head2 invoice_add($attr) - Bill

=cut
#**********************************************************
sub invoice_add {
  my $self = shift;
  my ($attr) = @_;

  #invoice_defaults();

  $CONF->{DOCS_INVOICE_ORDERS}=12 if (! $CONF->{DOCS_INVOICE_ORDERS});

  if (! $attr->{IDS} && $attr->{SUM}) {
    $attr->{IDS}       = 1;
    $attr->{SUM_1}     = $attr->{SUM} || 0;
    $attr->{COUNTS_1}  = (!$attr->{COUNTS}) ?  1 : $attr->{COUNTS};
    $attr->{UNIT_1}    = (!$attr->{UNIT}) ? 0 : $attr->{UNIT};
    $attr->{ORDER_1}   = $attr->{ORDER} || '';
    $attr->{FEES_ID_1} = $attr->{FEES_ID} || '';
    $attr->{TYPE_FEES_1} = $attr->{METHOD} || '0';
  }

  my @ids_arr         = split(/, /, $attr->{IDS} || '');
  my $orders          = $#ids_arr + 1;
  my $order_number    = 0;
  my @invoice_num_arr = ();

  while( $order_number <= $orders ) {
    $attr->{INVOICE_NUM} = $self->docs_nextid({ TYPE => 'INVOICE', %$attr }) if (! $attr->{INVOICE_NUM});
    return [ ] if ($self->{errno});
    $self->query_add('docs_invoices', {
      %$attr,
      DATE    => ($attr->{DATE} && $attr->{DATE} =~ /\d{4}\-\d{2}\-\d{2}/) ? $attr->{DATE} : 'NOW()',
      CREATED => 'NOW()',
      AID     => $admin->{AID},
      CURRENCY=> $attr->{DOCS_CURRENCY},
    });

    return [ ] if ($self->{errno});
    $self->{DOC_ID}      = $self->{INSERT_ID};
    $self->{INVOICE_NUM} = $attr->{INVOICE_NUM};
    push @invoice_num_arr, $self->{DOC_ID};

    if ($attr->{IDS}) {
      my @MULTI_QUERY = ();

      for( my $order_num=0; $order_num<$CONF->{DOCS_INVOICE_ORDERS}; $order_num++) {
        my $id = shift @ids_arr;
        next if (! $id);

        if (! $attr->{ 'ORDER_' . $id } && $attr->{ 'SUM_' . $id } == 0) {
          next;
        }

        $attr->{ 'COUNTS_' . $id } = 1 if (!$attr->{ 'COUNTS_' . $id });
        if ($attr->{REVERSE_CURRENCY}) {
          $attr->{ 'SUM_' . $id } = $attr->{ 'SUM_' . $id }/$attr->{EXCHANGE_RATE};
        }

        $attr->{ 'SUM_' . $id } =~ s/\,/\./g;
        if ($attr->{ER} && $attr->{ER} != 1) {
          $attr->{ 'SUM_' . $id } = $attr->{ 'SUM_' . $id } / $attr->{ER};
        }

        push @MULTI_QUERY, [
          $self->{'DOC_ID'},
          $attr->{ 'ORDER_' . $id } || '',
          $attr->{ 'COUNTS_' . $id },
          $attr->{ 'UNIT_' . $id } || 0,
          $attr->{ 'SUM_' . $id },
          $attr->{ 'FEES_ID_' . $id } || 0,
          $attr->{ 'FEES_TYPE_' . $id } || 0,
          $attr->{ 'TYPE_FEES_' . $id } || 0,
        ];
      }

      $self->query("INSERT INTO docs_invoice_orders (invoice_id, orders, counts, unit, price, fees_id, fees_type, type_fees_id)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?);",
        undef,
        { MULTI_QUERY =>  \@MULTI_QUERY });

      $orders-=$CONF->{DOCS_INVOICE_ORDERS};
      delete ($attr->{INVOICE_NUM});
    }
    $order_number++;
    return [ ] if ($self->{errno});
    $self->invoice_info($self->{DOC_ID});
  } ;

  $self->{DOC_IDS} = join(',', @invoice_num_arr);

  return $self;
}

#**********************************************************
=head2 invoice_del($id)

=cut
#**********************************************************
sub invoice_del {
  my $self = shift;
  my ($id, $attr) = @_;

  if ($id == 0 && $attr->{UID}) {
  }
  else {
    $self->query("SELECT invoice_num, uid FROM docs_invoices WHERE id='$id'", undef, { INFO => 1 });
    $self->query_del('docs_invoice2payments',undef,  { invoice_id => $id });
    $self->query_del('docs_invoice_orders', undef, { invoice_id => $id });
    $self->query_del('docs_invoices', { ID => $id });
  }

  $admin->{MODULE}='Docs';
  $admin->action_add("$self->{UID}", "$id:$self->{INVOICE_NUM}", { TYPE => 18 });
  return $self;
}

#**********************************************************
=head2 invoice_info($id, $attr)

  Arguemnst:
    $id
    $attr
      GROUP_ORDERS

=cut
#**********************************************************
sub invoice_info {
  my $self = shift;
  my ($id, $attr) = @_;

  delete($self->{ORDERS});

  my $WHERE = ($attr->{UID}) ? "and d.uid='$attr->{UID}'" : '';

  $self->query("SELECT d.invoice_num,
   d.date,
   d.customer,
   \@TOTAL_SUM := SUM(o.price * o.counts) / IF(COUNT(DISTINCT p.id)>0,COUNT(DISTINCT p.id),1)  AS total_sum ,
   IF(d.vat>0, FORMAT(SUM(o.price * o.counts) / ((100+d.vat)/ d.vat), 2), FORMAT(0, 2)) AS vat,
   u.id AS login,
   a.name AS a_fio,
   d.created,
   d.uid,
   d.id AS doc_id,
   pi.fio,
   pi.address_street,
   pi.address_build,
   pi.address_flat,
   IF (d.phone<>0, d.phone, pi.phone) AS phone,
   pi.contract_id,
   pi.contract_date,
   IF($CONF->{DOCS_ACCOUNT_EXPIRE_DAY}>0, DATE_FORMAT(d.date, '%Y-%m-$CONF->{DOCS_ACCOUNT_EXPIRE_DAY}')
       ,d.date + INTERVAL $self->{DOCS_ACCOUNT_EXPIRE_PERIOD} DAY) AS expire_date,
   u.company_id,
   c.name company_name,
   d.payment_id,
   p.method AS payment_method_id,
   p.ext_id,
   d.deposit,
   d.delivery_status,
   d.exchange_rate,
   d.currency,
   \@CHARGED := SUM(IF (o.fees_id>0, o.price * o.counts, 0)) AS charged_sum,
   \@TOTAL_SUM - \@CHARGED AS pre_payment,
   c.phone AS company_phone,
   (SELECT SUM(i2p.sum) FROM docs_invoice2payments i2p
              WHERE d.id=i2p.invoice_id
      ) AS payment_sum
    FROM (docs_invoices d, docs_invoice_orders o)
    LEFT JOIN users u ON (d.uid=u.uid)
    LEFT JOIN companies c ON (u.company_id=c.id)
    LEFT JOIN users_pi pi ON (pi.uid=u.uid)
    LEFT JOIN admins a ON (d.aid=a.aid)
    LEFT JOIN docs_invoice2payments i2p ON (d.id=i2p.invoice_id)
    LEFT JOIN payments p ON (i2p.payment_id=p.id)
    WHERE d.id=o.invoice_id AND d.id='$id'
      $WHERE
    GROUP BY d.id;",
    undef,
    { INFO => 1 }
  );

  $self->{AMOUNT_FOR_PAY} = ($self->{DEPOSIT} > 0) ? $self->{TOTAL_SUM} - $self->{DEPOSIT} : $self->{TOTAL_SUM} + $self->{DEPOSIT};

  if ($self->{TOTAL} > 0) {
    $self->{NUMBER} = $self->{INVOICE_ID};

    my $sql = q{};
    if($attr->{GROUP_ORDERS}) {
      $sql = "SELECT o.invoice_id,
  o.orders,
  sum(o.counts),
  o.unit,
  o.price,
  IF(ft.tax>0, (sum(o.counts) * o.price) / 100 * ft.tax, 0) AS tax_sum,
  o.fees_id,
  o.fees_type,
  ft.tax,
  o.type_fees_id,
  'c00006'
FROM docs_invoice_orders o
  LEFT JOIN fees_types ft ON (ft.id=o.fees_type)
WHERE invoice_id = ?
GROUP BY o.orders";
    }
    else {
      $sql = "SELECT o.invoice_id,
       o.orders,
       o.counts,
       o.unit,
       o.price,
       IF(ft.tax>0, (o.counts * o.price) / 100 * ft.tax, 0) AS tax_sum,
       o.fees_id,
       o.fees_type,
       ft.tax,
       o.type_fees_id,
       '$self->{LOGIN}'
     FROM docs_invoice_orders o
     LEFT JOIN fees_types ft ON (ft.id=o.fees_type)
     WHERE invoice_id= ? ";
    }


    $self->query($sql,
      undef,
      { Bind => [ $id ] }
    );

    $self->{ORDERS} = $self->{list};
  }

  return $self;
}

#**********************************************************
=head2 invoice_change($attr)

=cut
#**********************************************************
sub invoice_change {
  my $self = shift;
  my ($attr) = @_;

  $admin->{MODULE} = $MODULE;
  $self->changes(
    {
      CHANGE_PARAM    => 'ID',
      TABLE           => 'docs_invoices',
      DATA            => $attr,
      EXT_CHANGE_INFO => 'ACCT'
    }
  );

  return $self;
}

#**********************************************************
=head2 del($attr) - Del invoice

=cut
#**********************************************************
sub del {
  my $self = shift;
  my ($attr) = @_;

  $self->query("DELETE FROM docs_invoice_orders WHERE invoice_id IN (SELECT id FROM docs_invoices WHERE uid='$attr->{UID}')", 'do');
  $self->query("DELETE FROM docs_invoices WHERE uid='$attr->{UID}'",                                                          'do');
  $self->query("DELETE FROM docs_receipt_orders WHERE receipt_id IN (SELECT id FROM docs_receipts WHERE uid='$attr->{UID}')", 'do');
  $self->query("DELETE FROM docs_receipts WHERE uid='$attr->{UID}'",                                                          'do');

  return $self;
}

#**********************************************************
=head2 tax_invoice_list($attr)

=cut
#**********************************************************
sub tax_invoice_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT      = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC      = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $WHERE =  $self->search_former($attr, [
    ['UID',            'INT', 'd.uid'                              ],
    ['DOC_ID',         'INT', 'd.tax_invoice_id'                   ],
    ['SUM',            'INT', 'o.price * o.counts',                             ],
    ['MONTH',          'DATE', "date_format(d.date, '%Y-%m')"      ],
    ['DATE',           'DATE', 'date_format(d.date, \'%Y-%m-%d\')' ],
    ['FROM_DATE|TO_DATE','DATE', 'date_format(d.date, \'%Y-%m-%d\')' ],
  ],
    { WHERE => 1,
    }
  );

  my $EXT_TABLES = '';
  if ($attr->{FULL_INFO}) {
    $EXT_TABLES = "LEFT JOIN users u ON (d.uid=u.uid)
      LEFT JOIN users_pi pi ON (pi.uid=u.uid)";

    $self->{EXT_FIELDS} = ",
   IF(d.vat>0, FORMAT(SUM(o.price * o.counts) / ((100+d.vat)/ d.vat), 2), FORMAT(0, 2)),
   pi.fio,
   pi.address_street,
   pi.address_build,
   pi.address_flat,
   pi.phone,
   c.contract_id,
   c.contract_date,
   d.company_id,
   d.date + interval $self->{DOCS_ACCOUNT_EXPIRE_PERIOD} day";
  }

  $self->query("SELECT d.tax_invoice_id,
    d.date,
    c.name AS company_name,
    SUM(o.price * o.counts) AS total_sum,
    a.name AS admin_name,
    d.created,
    d.uid,
    d.company_id,
    d.id
    $self->{EXT_FIELDS}
    FROM docs_tax_invoices d
    LEFT JOIN docs_tax_invoice_orders o ON (d.id=o.tax_invoice_id)
    LEFT JOIN companies c ON (d.company_id=c.id)
    LEFT JOIN admins a ON (d.aid=a.aid)
    $EXT_TABLES
    $WHERE
    GROUP BY d.tax_invoice_id
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  $self->{SUM} = 0.00;
  return $self->{list} if ($self->{TOTAL} < 1);
  my $list = $self->{list};

  $self->query("SELECT COUNT(DISTINCT d.tax_invoice_id) AS total, SUM(o.price*o.counts) AS sum
    FROM (docs_tax_invoices d)
    LEFT JOIN docs_tax_invoice_orders o ON (d.id=o.tax_invoice_id)
    LEFT JOIN companies c ON (d.company_id=c.id)
    $WHERE",
    undef, { INFO => 1 }
  );

  return $list;
}

#**********************************************************
# tax_invoice_reports
#**********************************************************
sub tax_invoice_reports {
  my $self = shift;
  my ($attr) = @_;

  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  my $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  $self->{EXT_TABLES} = '';

  my $WHERE =  $self->search_former($attr, [
    ['UID',            'INT', 'd.uid'                               ],
    ['LOGIN',          'STR', 'u.id'                                ],
    ['SUM',            'INT', 'o.price * o.counts'                  ],
    ['PAYMENT_METHOD', 'INT', 'p.method',                           ],
    ['PAYMENT_ID',     'INT', 'd.payment_id',                       ],
    ['DOC_ID',         'INT', 'd.tax_invoice_id',                   ],
    ['AID',            'INT', 'a.id',                               ],
    ['CUSTOMER',       'STR', 'd.customer',                         ],
    ['MONTH','INT',    "date_format(d.date, '%Y-%m')"               ],
    ['FROM_DATE|TO_DATE','DATE', "date_format(d.date, '%Y-%m-%d')"   ],
    ['PHONE',          'INT', 'if (d.phone<>0, d.phone, pi.phone)', 'if (d.phone<>0, d.phone, pi.phone) AS phone'   ],
  ],
    { WHERE       => 1,
      USERS_FIELDS=> 1,
      USE_USER_PI => 1
    }
  );

  my $EXT_TABLES = $self->{EXT_TABLES} || '';

  $self->query("SELECT 0, DATE_FORMAT(d.date, '%d%m%Y'), d.receipt_num, pi.fio,
    pi._inn,
    ROUND(SUM(inv_orders.price*counts), 2),
    ROUND(SUM(inv_orders.price*counts) - SUM(inv_orders.price*counts) /6, 2),
    ROUND(SUM(inv_orders.price*counts) / 6, 2),
    '-',  'X', '-', 'X', '-', 'X'

FROM docs_receipts d
  INNER JOIN users u ON (u.uid=d.uid)
$EXT_TABLES
  LEFT JOIN docs_receipt_orders inv_orders ON (inv_orders.receipt_id=d.id)
  $WHERE
  GROUP BY d.id
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;"
  );

  $self->{SUM} = 0.00;
  return $self->{list} if ($self->{TOTAL} < 1);
  my $list = $self->{list};

  return $list;
}

#**********************************************************
# Bill
#**********************************************************
sub tax_invoice_add {
  my $self = shift;
  my ($attr) = @_;

  return [ ] if ($self->{errno});

  $self->query_add('docs_tax_invoices', {
      TAX_INVOICE_ID => $attr->{DOC_ID} = ($attr->{DOC_ID}) ? $attr->{DOC_ID} : $self->docs_nextid({ TYPE => 'TAX_INVOICE' }),
    DATE           => ($attr->{DATE}) ? "$attr->{DATE}" : 'now()',
    CREATED        => 'NOW()',
    AID            => $admin->{AID},
    %$attr
  });

  return [ ] if ($self->{errno});
  $self->{DOC_ID} = $self->{INSERT_ID};

  if (!$attr->{IDS}) {

  }

  if ($attr->{IDS}) {
    my @ids_arr = split(/, /, $attr->{IDS});
    my @MULTI_QUERY = ();
    foreach my $id (@ids_arr) {
      if (! $attr->{ 'ORDER_' . $id } && $attr->{ 'SUM_' . $id } == 0) {
        next;
      }

      $attr->{ 'COUNTS_' . $id } = 1 if (!$attr->{ 'COUNTS_' . $id });
      push @MULTI_QUERY, [ $self->{'DOC_ID'},
        $attr->{ 'ORDER_' . $id },
        $attr->{ 'COUNTS_' . $id },
        $attr->{ 'UNIT_' . $id },
        $attr->{ 'SUM_' . $id }
      ];
    }

    $self->query("INSERT INTO docs_tax_invoice_orders (tax_invoice_id, orders, counts, unit, price)
        VALUES (?, ?, ?, ?, ?);",
      undef,
      { MULTI_QUERY =>  \@MULTI_QUERY });
  }

  return [ ] if ($self->{errno});

  $self->tax_invoice_info($self->{DOC_ID});

  return $self;
}

#**********************************************************
# Bill
#**********************************************************
sub tax_invoice_del {
  my $self = shift;
  my ($id, $attr) = @_;

  if ($id == 0 && $attr->{UID}) {

  }
  else {
    $self->query_del('docs_tax_invoice_orders', undef, { tax_invoice_id => $id });
    $self->query_del('docs_tax_invoices', { ID => $id });
  }

  return $self;
}

#**********************************************************
=head2 tax_invoice_info($id, $attr)

=cut
#**********************************************************
sub tax_invoice_info {
  my $self = shift;
  my ($id, $attr) = @_;

  my $WHERE = ($attr->{UID}) ? "AND d.uid='$attr->{UID}'" : '';

  $self->query("SELECT d.tax_invoice_id,
   d.date,
   SUM(o.price * o.counts) AS total_sum,
   if(d.vat>0, FORMAT(SUM(o.price * o.counts) / ((100+d.vat)/ d.vat), 2), FORMAT(0, 2)) AS vat,
   u.id AS login,
   c.name AS admin,
   d.created,
   d.uid,
   d.id AS doc_id,
   pi.fio,
   pi.address_street,
   pi.address_build,
   pi.address_flat,
   pi.phone,
   c.contract_id,
   c.contract_date,
   d.company_id,
   d.date + interval $self->{DOCS_ACCOUNT_EXPIRE_PERIOD} day As expire_date

    FROM (docs_tax_invoices d, docs_tax_invoice_orders o)
    LEFT JOIN users u ON (d.uid=u.uid)
    LEFT JOIN users_pi pi ON (pi.uid=u.uid)
    LEFT JOIN companies c ON (c.id=d.company_id)
    LEFT JOIN admins a ON (d.aid=a.aid)
    WHERE d.id=o.tax_invoice_id AND d.id='$id' $WHERE
    GROUP BY d.id;",
    undef,
    { INFO => 1 }
  );

  if ($self->{TOTAL} > 0) {
    $self->{NUMBER} = $self->{INVOICE_NUM};

    $self->query("SELECT tax_invoice_id, orders, counts, unit, price
     FROM docs_tax_invoice_orders WHERE tax_invoice_id='$id'"
    );

    $self->{ORDERS} = $self->{list};
  }

  return $self;
}

#**********************************************************
# change()
#**********************************************************
sub tax_invoice_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'docs_tax_invoices',
      DATA         => $attr
    }
  );

  return $self->{result};
}

#**********************************************************
=head2 acts_list($attr)

=cut
#**********************************************************
sub acts_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  $attr->{FIO}='_SHOW';

  my $WHERE =  $self->search_former($attr, [
    ['ACT_ID',         'INT', 'd.act_id',                         1 ],
    ['DATE',           'DATE','d.date',                           1 ],
    ['START_PERIOD',   'DATE','d.start_period',                   1 ],
    ['END_PERIOD',     'DATE','d.end_period',                     1 ],
    ['COMPANY_NAME',   'STR', 'company_d.name', 'company_d.name AS company_name' ],
    ['SUM',            'INT', '', '(SELECT SUM(o.price) FROM docs_act_orders o WHERE d.id=o.act_id) AS sum'  ],
    ['ADMIN_NAME',     'INT', 'd.name', 'a.name AS admin_name',     ],
    ['CREATED',        'DATE','d.created',      1                   ],
    ['UID',            'INT', 'd.uid'                               ],
    ['DOC_ID',         'INT', 'd.act_id',                           ],
    ['AID',            'INT', 'a.id',                               ],
    ['CUSTOMER',       'STR', 'd.customer',                         ],
    ['MONTH',          'INT', "DATE_FORMAT(d.date, '%Y-%m')"        ],
    ['FROM_DATE|TO_DATE','DATE', "DATE_FORMAT(d.date, '%Y-%m-%d')"  ],
    ['COMPANY_ID',     'DATE', "d.company_id"                       ],
  ],
    { WHERE       => 1,
      USERS_FIELDS=> 1,
      USE_USER_PI => 1,
      SKIP_USERS_FIELDS => ['COMPANY_ID', 'UID']
    }
  );

  my $EXT_TABLES = $self->{EXT_TABLES} || q{};

  if ($self->{SEARCH_FIELDS} =~ /a\./) {
    $EXT_TABLES .= 'LEFT JOIN admins a ON (d.aid=a.aid)';
  }

  $self->query("SELECT d.act_id, d.date, company_d.name AS company_name,
      (SELECT SUM(o.price) FROM docs_act_orders o WHERE d.id=o.act_id) AS sum,
      $self->{SEARCH_FIELDS}
      d.created,
      d.uid,
      d.company_id,
      d.id
    FROM docs_acts d
    LEFT JOIN companies company_d  ON (d.company_id=company_d.id)
    LEFT JOIN users u ON (u.company_id=company_d.id)
    $EXT_TABLES
    $WHERE
    GROUP BY d.id
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  $self->{SUM} = 0.00;
  return $self->{list} if ($self->{TOTAL} < 1);
  my $list = $self->{list};

  $self->query("SELECT COUNT(DISTINCT d.act_id) AS total, (SELECT SUM(o.price) FROM docs_act_orders o WHERE d.id=o.act_id) AS sum
    FROM docs_acts d
    LEFT JOIN docs_act_orders ao ON (d.id=ao.act_id)
    LEFT JOIN companies company_d ON (d.company_id=company_d.id)
    LEFT JOIN users u ON (u.company_id=company_d.id)
    $EXT_TABLES
    $WHERE",
    undef, { INFO => 1 }
  );

  return $list;
}

#**********************************************************
=head2 act_add($attr)

  Arguments:
    $attr
      DOC_ID
      DATE
      IDS    - Orders count
      UID
      COMPANY_ID

      Orders:
        ORDER_1
        COUNTS_1
        UNIT_1
        SUM_1
        FEES_ID_1

      CHECK_DUBLICATE

  Returns:

=cut
#**********************************************************
sub act_add {
  my $self = shift;
  my ($attr) = @_;

  delete $self->{errno};
  delete $self->{errstr};

  if($attr->{CHECK_DUBLICATE}) {
    my $list = $self->acts_list({
      DATE       => $attr->{DATE},
      UID        => $attr->{UID},
      COMPANY_ID => $attr->{COMPANY_ID},
      SKIP_DEL_CHECK => 1,
      COLS_NAME  => 1
    });

    if($self->{TOTAL}) {
      $self->{errno}=7;
      $self->{errstr}='Act exists';
      $self->{DOC_ID}=$list->[0]->{act_id};

      return $self;
    }
  }

  $self->query_add('docs_acts', {
    ACT_ID  => ($attr->{DOC_ID}) ? $attr->{DOC_ID} : $self->docs_nextid({ TYPE => 'ACT' }),
    DATE    => ($attr->{DATE}) ? $attr->{DATE} : 'NOW()',
    CREATED => 'NOW()',
    AID     => $admin->{AID},
    %$attr
  });

  return [ ] if ($self->{errno});
  $self->{DOC_ID} = $self->{INSERT_ID};
  $CONF->{DOCS_ACT_ORDERS}=30;

  if ($attr->{IDS}) {
    my @ids_arr         = split(/,\s?/, $attr->{IDS} || '');
    my $orders          = $#ids_arr + 1;

    my @MULTI_QUERY = ();

    for( my $order_num=0; $order_num<$CONF->{DOCS_ACT_ORDERS}; $order_num++) {
      my $id = shift @ids_arr;
      next if (! $id);

      if (! $attr->{ 'ORDER_' . $id } && $attr->{ 'SUM_' . $id } == 0) {
        next;
      }

      $attr->{ 'SUM_' . $id } =~ s/\,/\./g;

      push @MULTI_QUERY, [ $self->{'DOC_ID'},
        $attr->{ 'ORDER_' . $id } || '',
        $attr->{ 'COUNTS_' . $id } || 1,
        $attr->{ 'UNIT_' . $id } || 0,
        $attr->{ 'SUM_' . $id },
        $attr->{ 'FEES_ID_' . $id } || 0
      ];
    }

    $self->query("INSERT INTO docs_act_orders (act_id, orders, counts, unit, price, fees_id)
        VALUES (?, ?, ?, ?, ?, ?);",
      undef,
      { MULTI_QUERY =>  \@MULTI_QUERY });

    $orders-=$CONF->{DOCS_INVOICE_ORDERS};
    delete ($attr->{INVOICE_NUM});
  }

  # $order_number++;
  return $self;
}

#**********************************************************
=head2 act_del($id, $attr)

=cut
#**********************************************************
sub act_del {
  my $self = shift;
  my ($id, $attr) = @_;

  $self->query_del('docs_act_orders', undef, { act_id => $id });
  $self->query_del('docs_acts', { ID => $id }, { uid => $attr->{UID} });

  return $self;
}

#**********************************************************
=head2 act_info($id, $attr)

=cut
#**********************************************************
sub act_info {
  my $self = shift;
  my ($id, $attr) = @_;

  my $WHERE = ($attr->{UID}) ? "AND d.uid='$attr->{UID}'" : '';

  $self->query("SELECT d.act_id,
   d.date,
   DATE_FORMAT(d.date, '%Y-%m') AS month,
   d.sum AS total_sum_main,
   SUM(ao.price) AS total_sum,
   IF(d.vat>0, FORMAT(d.sum / ((100+d.vat)/ d.vat), 2), FORMAT(0, 2)) AS vat,
   u.id AS login,
   a.name AS admin,
   d.created,
   d.uid,
   d.id AS doc_id,
   pi.fio,
   pi.address_street,
   pi.address_build,
   pi.address_flat,
   pi.phone,
   c.contract_id,
   c.contract_date,
   d.company_id,
   c.name AS company_name,
   d.start_period,
   d.end_period,
   d.date + interval $self->{DOCS_ACCOUNT_EXPIRE_PERIOD} day AS expire_date

   FROM docs_acts d
   LEFT JOIN docs_act_orders ao ON (d.id=ao.act_id)
   LEFT JOIN users u ON (d.uid=u.uid)
   LEFT JOIN users_pi pi ON (pi.uid=u.uid)
   LEFT JOIN companies c ON (c.id=d.company_id)
   LEFT JOIN admins a ON (d.aid=a.aid)
   WHERE d.id= ? $WHERE
   GROUP BY d.id;",
    undef,
    { INFO => 1,
      Bind => [ $id ]}
  );

  return [ ] if ($self->{errno});

  ($self->{CREATED_DATE}, $self->{CREATED_TIME}) = split(/ /,  $self->{CREATED});

  $self->{NUMBER} = $self->{ACT_ID};
  my $total = $self->{TOTAL} || 0;

  if ($total > 0) {
    $self->query("SELECT act_id, orders, counts, unit, price, fees_id
     FROM docs_act_orders
     WHERE act_id= ? ;",
      undef,
      { COLS_NAME => 1,
        Bind      => [ $id ]
      }
    );

    $self->{ORDERS} = $self->{list};
  }

  $self->{TOTAL}=$total;

  return $self;
}

#**********************************************************
=head2 act_change($attr)

=cut
#**********************************************************
sub act_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'docs_acts',
      DATA         => $attr
    }
  );

  return $self->{result};
}

#**********************************************************
=head2 user_info($uid) - User information

=cut
#**********************************************************
sub user_info {
  my $self = shift;
  my ($uid) = @_;

  $CONF->{DOCS_PRE_INVOICE_PERIOD}=10 if (! defined($CONF->{DOCS_PRE_INVOICE_PERIOD}));
  $CONF->{FIXED_FEES_DAY} //= '';

  $self->query("SELECT service.uid,
   service.send_docs,
   service.periodic_create_docs,
   service.email,
   service.comments,
   service.personal_delivery,
   service.invoicing_period,
   service.invoice_date,
   IF (u.activate='0000-00-00' OR '$CONF->{FIXED_FEES_DAY}' <> '',  service.invoice_date + INTERVAL service.invoicing_period MONTH - INTERVAL $CONF->{DOCS_PRE_INVOICE_PERIOD} DAY,
     service.invoice_date + INTERVAL 30*service.invoicing_period+service.invoicing_period DAY - INTERVAL $CONF->{DOCS_PRE_INVOICE_PERIOD} DAY) AS next_invoice_date
   FROM docs_main service
   INNER JOIN users u ON (u.uid=service.uid)
   WHERE service.uid= ? ;",
    undef,
    { INFO => 1,
      Bind => [ $uid ] }
  );

  return $self;
}


#**********************************************************
=head2 user_add($attr)

=cut
#**********************************************************
sub user_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('docs_main', $attr);

  return [ ] if ($self->{errno});

  $admin->action_add($attr->{UID}, "", { TYPE => 1 });

  return $self;
}

#**********************************************************
=head2 user_change($attr)

=cut
#**********************************************************
sub user_change {
  my $self = shift;
  my ($attr) = @_;

  if (!$attr->{CHANGE_DATE}) {
    $attr->{SEND_DOCS}            = (!defined($attr->{SEND_DOCS}))            ? 0 : 1;
    $attr->{PERIODIC_CREATE_DOCS} = (!defined($attr->{PERIODIC_CREATE_DOCS})) ? 0 : 1;
    $attr->{PERSONAL_DELIVERY}    = (!defined($attr->{PERSONAL_DELIVERY}))    ? 0 : 1;
  }

  $admin->{MODULE} = $MODULE;

  $self->user_info($attr->{UID});

  if(! $self->{errno}) {
    $self->changes(
      {
        CHANGE_PARAM => 'UID',
        TABLE        => 'docs_main',
        DATA         => $attr
      }
    );

    $self->user_info($attr->{UID});
  }

  return $self;
}

#**********************************************************
=head2 user_del(attr);

=cut
#**********************************************************
sub user_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('docs_main', undef, { uid => $self->{UID} || $attr->{UID} });

  $admin->action_add($self->{UID}, "$self->{UID}", { TYPE => 10 });

  return $self->{result};
}

#**********************************************************
=head2 user_list($attr)

=cut
#**********************************************************
sub user_list {
  my $self   = shift;
  my ($attr) = @_;

  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  my $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  $self->{EXT_TABLES} = '';
  my @WHERE_RULES = (  );

  if ($attr->{PRE_INVOICE_DATE}) {
    if ($attr->{PRE_INVOICE_DATE} =~ /(\d{4}-\d{2}-\d{2})\/(\d{4}-\d{2}-\d{2})/) {
      my $from_date = $1;
      my $to_date   = $2;

      push @WHERE_RULES, "(
      (u.activate='0000-00-00'
           AND service.invoice_date + INTERVAL service.invoicing_period MONTH - INTERVAL $CONF->{DOCS_PRE_INVOICE_PERIOD} day>='$from_date'
           AND service.invoice_date + INTERVAL service.invoicing_period MONTH - INTERVAL $CONF->{DOCS_PRE_INVOICE_PERIOD} day<='$to_date'
      )
      OR ( u.activate<>'0000-00-00'
           AND service.invoice_date + INTERVAL 30*service.invoicing_period+service.invoicing_period-1 DAY - INTERVAL $CONF->{DOCS_PRE_INVOICE_PERIOD} day>='$from_date'
           AND service.invoice_date + INTERVAL 30*service.invoicing_period+service.invoicing_period-1 DAY - INTERVAL $CONF->{DOCS_PRE_INVOICE_PERIOD} day<='$to_date'
      ))";
    }
    elsif($attr->{PRE_INVOICE_DATE} ne '_SHOW') {
      push @WHERE_RULES,  '('. @{ $self->search_expr("$attr->{PRE_INVOICE_DATE}", "DATE","u.activate='0000-00-00' AND service.invoice_date + INTERVAL service.invoicing_period MONTH - INTERVAL $CONF->{DOCS_PRE_INVOICE_PERIOD} day") }[0] . ' OR '.
        @{ $self->search_expr("$attr->{PRE_INVOICE_DATE}", "DATE", "u.activate<>'0000-00-00' AND service.invoice_date + INTERVAL 30*service.invoicing_period+service.invoicing_period DAY - INTERVAL $CONF->{DOCS_PRE_INVOICE_PERIOD} day") }[0] .')';
    }
  }

  my $WHERE =  $self->search_former($attr, [
    ['COMMENTS',            'STR',  'service.comments',   'service.comments AS service_comments' ],
    ['INVOICE_DATE',        'DATE', 'service.invoice_date', 1           ],
    ['NEXT_INVOICE_DATE',   'DATE', '', "if(u.activate='0000-00-00',
       service.invoice_date + INTERVAL service.invoicing_period MONTH,
       service.invoice_date + INTERVAL 30*service.invoicing_period+service.invoicing_period-1 DAY) - INTERVAL $CONF->{DOCS_PRE_INVOICE_PERIOD} day AS pre_invoice_date,
     service.invoicing_period,
     (service.invoice_date + INTERVAL service.invoicing_period MONTH) AS next_invoice_date" ],
    ['EMAIL',               'STR',  'service.email',                  1  ],
    ['PERIODIC_CREATE_DOCS','INT',  'service.periodic_create_docs',   1  ],
    ['SEND_DOCS',           'INT',  'service.send_docs',              1  ],
    ['PERSONAL_DELIVERY',   'INT',  'service.personal_delivery',      1  ],
    ['INVOICING_PERIOD',    'INT',  'service.invoicing_period',       1  ],
  ],
    { WHERE           => 1,
      WHERE_RULES     => \@WHERE_RULES,
      USERS_FIELDS_PRE=> 1,
      USE_USER_PI     => 1
    }
  );

  my $EXT_TABLES  = $self->{EXT_TABLES} || '';
  my $list;

  $self->query("SELECT $self->{SEARCH_FIELDS} service.uid
   FROM users u
   INNER JOIN docs_main service ON (u.uid=service.uid)
   $EXT_TABLES
   $WHERE
   ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  return [ ] if ($self->{errno});

  $list = $self->{list};

  if ($self->{TOTAL} >= 0) {
    $self->query("SELECT COUNT(DISTINCT u.id) AS total  FROM users u
      INNER JOIN docs_main service ON (u.uid=service.uid)
      $EXT_TABLES
      $WHERE", undef, { INFO => 1 }
    );
  }

  return $list;
}


#**********************************************************
=head2 statement_of_account($attr)

=cut
#**********************************************************
sub statement_of_account {
  my $self = shift;
  my ($attr) = @_;

  my $WHERE =  $self->search_former($attr, [
    ['UID',         'INT',  'u.uid',   ],
    ['DATE',        'DATE', 'p.date',  ],
  ],
    { WHERE           => 1,  }
  );

  $self->query("SELECT CURDATE() AS date,
u.id AS login,
pi.fio,
(SELECT SUM(f.sum) FROM fees f WHERE u.uid=f.uid) AS fees_sum,
SUM(p.sum) AS payment_sum,
IF(company.id IS NULL, b.deposit, cb.deposit) AS deposit,
u.uid
FROM users u
  LEFT JOIN users_pi pi ON (u.uid = pi.uid)
  LEFT JOIN bills b ON (u.bill_id = b.id)
  LEFT JOIN companies company ON  (u.company_id=company.id)
  LEFT JOIN bills cb ON  (company.bill_id=cb.id)
  LEFT JOIN payments p ON (p.uid=u.uid)
$WHERE
GROUP BY u.uid;",
    undef,
    $attr
  );

  return [ ] if ($self->{errno});

  my $list = $self->{list};

  if ($self->{TOTAL} >= 0) {
    $self->query("SELECT
COUNT(DISTINCT u.id) AS user_total,
SUM(f.sum) AS total_fees_rm,
SUM(p.sum) AS total_payment_rm

FROM users u
  LEFT JOIN users_pi pi ON (u.uid = pi.uid)
  LEFT JOIN bills b ON (u.bill_id = b.id)
  LEFT JOIN companies company ON  (u.company_id=company.id)
  LEFT JOIN bills cb ON (company.bill_id=cb.id)
  LEFT JOIN payments p ON (p.uid=u.uid)
  LEFT JOIN fees f ON (f.uid=u.uid)
$WHERE", undef, { INFO => 1 }
    );
  }

  return $list;
}

1
