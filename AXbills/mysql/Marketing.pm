package Marketing;

=head1 NAME

  Marketing  functions

=cut

use strict;
use parent 'main';

my $MODULE = 'Marketing';
my ($admin, $CONF)=@_;
my $SORT      = 1;
my $DESC      = '';
my $PG        = 0;
my $PAGE_ROWS = 25;


#**********************************************************
# Init
#**********************************************************
sub new {
  my $class = shift;
  my $db    = shift;
  ($admin, $CONF) = @_;

  $admin->{MODULE} = $MODULE;
  my $self = {
    db   => $db,
    conf => $CONF,
    admin=> $admin
  };

  bless($self, $class);

  return $self;
}

#**********************************************************
# report1()
#**********************************************************
sub report1 {
  my $self   = shift;
  my ($attr) = @_;

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  $self->{SEARCH_FIELDS}       = '';
  $self->{SEARCH_FIELDS_COUNT} = 0;

  my @WHERE_RULES = ('u.disable=0',
   'u.uid=pi.uid');

  my $WHERE =  $self->search_former($attr, [
    ],
    { WHERE       => 1,
    	WHERE_RULES => \@WHERE_RULES,
    	USERS_FIELD => 1
    }
    );

  #alter table users_pi  add column _c_address varchar(100) not null default '';
  #alter table users_pi add column _c_build varchar(100) not null default '';

  $self->query2("SELECT 
      if (pi._c_address <> '', pi._c_address, pi.address_street),
      if (pi._c_build <> '', pi._c_build, pi.address_build),
      count(*) 
     FROM (users_pi pi, users u)
     $WHERE
     GROUP BY 1,2
     ORDER BY $SORT $DESC 
     LIMIT $PG, $PAGE_ROWS;",
     undef,
     $attr
  );

  return [ ] if ($self->{errno});

  my $list = $self->{list};

  if ($self->{TOTAL} >= 0) {
    $self->query2("SELECT count(*) AS total FROM (users u, users_pi pi) 
    WHERE u.uid=pi.uid", undef, { INFO => 1 }
    );
  }

  return $list;
}

#**********************************************************
# internet_fees_monitor()
#**********************************************************
sub internet_fees_monitor {
  my $self   = shift;
  my ($attr) = @_;

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my @WHERE_RULES = @{ $self->search_expr_users($attr) };

  if ($attr->{TP_ID}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{TP_ID}, 'INT', 'tp.id') };
  }

  if (defined($attr->{STATUS}) && $attr->{STATUS} ne '') {
    push @WHERE_RULES, @{ $self->search_expr($attr->{STATUS}, 'INT', 'dv.disable') };
  }

  my $date = 'curdate()';

  if ($attr->{FROM_Y}) {
    $date = sprintf("'%s-%.2d-%.2d'", $attr->{FROM_Y}, ($attr->{FROM_M} + 1), $attr->{FROM_D});
    my $date_2 = '';
    if ($date =~ /(\d{4})-(\d{2})/) {
      $date_2 = "$1-$2";
    }
    push @WHERE_RULES, @{ $self->search_expr("$date_2", 'INT', 'DATE_FORMAT(f.date, \'%Y-%m\')') };
  }

  my $WHERE = ($#WHERE_RULES > -1) ? 'WHERE ' . join(' and ', @WHERE_RULES) : '';

  $self->query2("select u.uid,  u.id AS login, 
   u.disable AS account_status,
   dv.disable AS dv_status,
   dv.tp_id, 
   tp.name AS tp_name, 
   tp.month_fee,
   SUM(if (DATE_FORMAT($date, '%Y-%m-01')=DATE_FORMAT(f.date, '%Y-%m-%d'), 1, 0)) AS fees_count,
   MAX(f.date) AS last_fees_date

  FROM users u
  INNER JOIN dv_main dv on (dv.uid=u.uid)
  INNER JOIN tarif_plans tp on (dv.tp_id=tp.id)
  LEFT JOIN fees f on (f.uid=u.uid)
  $WHERE
  GROUP BY u.uid
     ORDER BY $SORT $DESC 
     LIMIT $PG, $PAGE_ROWS;",
  undef,
  $attr
  );

  return [ ] if ($self->{errno});

  my $list = $self->{list};

  if ($self->{TOTAL} >= 0) {
    $self->query2("SELECT count(distinct u.uid) AS total FROM  users u
     inner join dv_main dv on (dv.uid=u.uid)
     inner join tarif_plans tp on (dv.tp_id=tp.id)
     left join fees f on (f.uid=u.uid)
    $WHERE;",
    undef,
    { INFO => 1 }
    );
  }

  return $list;
}

#**********************************************************
# report1()
#**********************************************************
sub evolution_report {
  my $self   = shift;
  my ($attr) = @_;

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  $self->{SEARCH_FIELDS}       = '';
  $self->{SEARCH_FIELDS_COUNT} = 0;

  my @WHERE_RULES   = ();
  my $EXT_TABLES = '';
  my $date = 'DATE_FORMAT(datetime, \'%Y-%m\')';

  if ($attr->{PERIOD}) {
    $date = "DATE_FORMAT(datetime, \'%Y-%m-%d\')";
  }

  if ($attr->{MODULE}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{MODULE}, 'INT', 'aa.module') };
  }
  else {
    push @WHERE_RULES, 'aa.module=\'\'';
  }

  if ($attr->{DATE}) {
  	push @WHERE_RULES, @{ $self->search_expr($attr->{DATE}, 'INT', 'date_format(aa.datetime, \'%Y-%m-%d\')') };
  }
  elsif ($attr->{MONTH}) {
    push @WHERE_RULES, "date_format(aa.datetime, '%Y-%m')='$attr->{MONTH}'";
    $date = "DATE_FORMAT(datetime, \'%Y-%m-%d\')";
  }
  elsif ($attr->{INTERVAL}) {
    my ($from, $to) = split(/\//, $attr->{INTERVAL}, 2);
    push @WHERE_RULES, "date_format(aa.datetime, '%Y-%m-%d')>='$from' and date_format(aa.datetime, '%Y-%m-%d')<='$to'";
  }

  if ($attr->{GID}) {
  	push @WHERE_RULES, @{ $self->search_expr($attr->{GID}, 'INT', 'u.gid') };
  	$EXT_TABLES .= "LEFT JOIN users u ON (u.uid=aa.uid)";
  }

  my $WHERE = ($#WHERE_RULES > -1) ? 'WHERE ' . join(' and ', @WHERE_RULES) : '';

  $self->query2("select $date,
  SUM(if(action_type = 7, 1, 0)),
  SUM(if(action_type = 9, 1, 0))-SUM(if(action_type = 8, 1, 0)),
  SUM(if(action_type = 8, 1, 0)),
  SUM(if(action_type = 12, 1, 0))
  FROM admin_actions aa
  $EXT_TABLES
  $WHERE 
  GROUP BY 1
     ORDER BY $SORT $DESC 
     LIMIT $PG, $PAGE_ROWS;",
  undef,
  $attr
  );

  return [ ] if ($self->{errno});

  my $list = $self->{list};

  if ($self->{TOTAL} >= 0) {
    $self->query2("SELECT count(distinct $date) AS total FROM admin_actions aa
      $EXT_TABLES
      $WHERE;"
    );
  }

  return $list;
}

#**********************************************************
# report1()
#**********************************************************
sub evolution_users_report {
  my $self   = shift;
  my ($attr) = @_;

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  $self->{SEARCH_FIELDS}       = '';
  $self->{SEARCH_FIELDS_COUNT} = 0;

  my @WHERE_RULES = ();

  my $date = 'aa.datetime';

  if ($attr->{MODULE}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{MODULE}, 'INT', 'aa.module') };
  }
  else {
    push @WHERE_RULES, 'aa.module=\'\'';
  }

  if ($attr->{DATE}) {
  	push @WHERE_RULES, @{ $self->search_expr($attr->{DATE}, 'INT', 'date_format(aa.datetime, \'%Y-%m-%d\')') };
  }
  elsif ($attr->{MONTH}) {
    push @WHERE_RULES, "date_format(aa.datetime, '%Y-%m')='$attr->{MONTH}'";
  }
  elsif ($attr->{INTERVAL}) {
    my ($from, $to) = split(/\//, $attr->{INTERVAL}, 2);
    push @WHERE_RULES, "date_format(aa.datetime, '%Y-%m-%d')>='$from' and date_format(aa.datetime, '%Y-%m-%d')<='$to'";
  }

  if ($attr->{GID}) {
  	push @WHERE_RULES, @{ $self->search_expr($attr->{GID}, 'INT', 'u.gid') };
  }

  my $user = 'u.id';
  if ($attr->{ADDED}) {
    push @WHERE_RULES, "aa.action_type=7";
  }
  elsif ($attr->{DISABLED}) {
    my $WHERE = ($#WHERE_RULES > -1) ? 'WHERE ' . join(' and ', @WHERE_RULES) : '';
    $self->query2("select MAX($date), $user, a.id, u.registration, aa.uid,
     SUM(if(aa.action_type=9, 1, 0)) - SUM(if(aa.action_type=8, 1, 0)) As ACTIONS
     FROM admin_actions aa 
     LEFT JOIN users u ON (aa.uid=u.uid) 
     LEFT JOIN admins a ON (a.aid=aa.aid) 
     $WHERE and (aa.action_type=9 or aa.action_type<>8)
     GROUP BY 2 
     HAVING ACTIONS > 0
     ORDER BY $SORT $DESC 
     LIMIT $PG, $PAGE_ROWS;",
     undef,
     $attr
    );

    return [ ] if ($self->{errno});
    my $list = $self->{list};

    # if ($self->{TOTAL} >= 0) {
    #    $self->query($db, "SELECT count(*) FROM (select MAX($date), $user, a.id, u.registration, aa.uid,
    #   SUM(if(aa.action_type=9, 1, 0)) - SUM(if(aa.action_type=8, 1, 0)) As ACTIONS
    #   FROM admin_actions aa
    #   LEFT JOIN users u ON (aa.uid=u.uid)
    #   LEFT JOIN admins a ON (a.aid=aa.aid)
    #   $WHERE and (aa.action_type=9 or aa.action_type<>8)
    #   GROUP BY 2
    #   HAVING ACTIONS > 0)
    #    ;");
    #    ($self->{TOTAL}) = @{ $self->{list}->[0] };
    #   }

    return $list;
  }
  elsif ($attr->{ENABLE}) {
    push @WHERE_RULES, "aa.action_type=8";
  }
  elsif ($attr->{DELETED}) {
    push @WHERE_RULES, "aa.action_type=12";
    $user = 'aa.actions';
  }

  my $WHERE = ($#WHERE_RULES > -1) ? 'WHERE ' . join(' and ', @WHERE_RULES) : '';

  $self->query2("select $date, $user, a.id, u.registration, aa.uid
  FROM admin_actions aa
  LEFT JOIN users u ON (aa.uid=u.uid)
  LEFT JOIN admins a ON (a.aid=aa.aid)
  $WHERE 
  GROUP BY 1
     ORDER BY $SORT $DESC 
     LIMIT $PG, $PAGE_ROWS;",
  undef,
  $attr
  );

  return [ ] if ($self->{errno});

  my $list = $self->{list};

  if ($self->{TOTAL} >= 0) {
    $self->query2("SELECT count(distinct $date) AS total FROM admin_actions aa
       LEFT JOIN users u ON (aa.uid=u.uid)
       $WHERE;",
       undef, { INFO => 1 }
      );
  }

  return $list;
}

#**********************************************************
# report1()
#**********************************************************
sub report_2 {
  my $self   = shift;
  my ($attr) = @_;

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $CHARSET = "CHARACTER SET '$CONF->{dbcharset}'" if ($CONF->{dbcharset});

  my $WHERE =  $self->search_former($attr, [
     ['STATUS',             'INT', 'status'              ],
     ['FORUM',              'STR', 'forum_activity'      ],
     ['BONUS',              'STR', 'bonus'               ],
     ['DISABLE_DATE',       'INT', 'disable_date'        ],
     ['DISABLE_REASON',     'STR', 'disable_comments'    ],
     ['UID',                'INT', 'uid'                 ],
     ['REGISTRATION',       'INT', 'registration'        ],
     ['LOCATION',           'STR', '_segment'            ],
     ['DISTRICT',           'STR', '_district'           ],
     ['DISTRICT_ID',        'INT', 'address_district_id' ],
     ['ADDRESS_STREET',     'STR', 'address_street'      ],
     ['ADDRESS_STREET_ID',  'INT', 'address_street_id'   ],
     ['ADDRESS_BUILD',      'STR', 'address_build'       ],
     ['ENTRANCE',           'STR', '_entrance'           ],
     ['FLOR',               'INT', '_flor'               ],
     ['ADDRESS_FLAT',       'INT', 'address_flat'        ],
     ['TP_ID',              'INT', 'tp_id'               ],
     ['PRE_TP_ID',          'INT', 'last_tp_id'          ],
     ['TARIF_PLAN_CHANGED', 'INT', 'last_tp_changed'     ],
     ['CREDIT',             'INT', 'credit'              ],
     ['DEPOSIT',            'INT', 'deposit'             ],
     ['LAST_PAYMENT_DATE',  'INT', 'last_payment_date'   ],
     ['LAST_PAYMENT_METHOD','INT', 'last_payment_method' ],
     ['LAST_PAYMENT_SUM',   'INT', 'last_payment_sum'    ],
     ['PAYMENT_TO_DATE',    'INT', 'to_payments_date'    ],
     ['DEBTS_DAYS',         'INT', 'prosrochennyh_dney'  ]
    ],
    { WHERE       => 1,
    }
    );

  $self->query2("
CREATE TEMPORARY TABLE IF NOT EXISTS marketing_report_2
(
login varchar(40) not null default '',
fio varchar(40) not null default '',
registration date,
aid smallint unsigned not null default 0,
_segment varchar(40) not null default '',
_district varchar(40) not null default '',
address_district_id smallint unsigned not null default 0,
address_street varchar(40) not null default '',
address_street_id int unsigned not null default 0,
address_build varchar(6) not null default '',
address_flat varchar(6) not null default '',
_entrance tinyint unsigned not null default 0,
_flor tinyint unsigned not null default 0,
tp_id smallint unsigned not null default 0,
last_tp_id smallint unsigned not null default 0,
last_tp_changed date not null default '0000-00-00',

credit double(10,2) unsigned not null default 0,
deposit double(10,2) unsigned not null default 0,

last_payment_sum double(10,2) unsigned not null default 0,
last_payment_date datetime not null,
last_payment_method tinyint unsigned not null default 0,
to_payments_date date not null default '0000-00-00',
prosrochennyh_dney smallint unsigned not null default 0,
status tinyint unsigned not null default 0,
forum_activity varchar(40) not null default '',
bonus varchar(40) not null default '',
disable_date datetime not null,
disable_comments varchar(40) not null default '',
uid int unsigned not null default 0
) $CHARSET ;", 'do'
  );

  $self->query2("
insert into marketing_report_2

SELECT 
u.id,
pi.fio,
u.registration,
'',
_segment.name,
districts.name,
districts.id,
streets.name,
streets.id,
builds.number,
pi.address_flat,
pi._entrance, 
pi._flor,
dv.tp_id,

SUBSTRING_INDEX(\@last_tp_info:=GET_LAST_TP(u.uid), ',', 1 ) AS last_tp_id, 
SUBSTRING_INDEX(SUBSTRING_INDEX(\@last_tp_info, ',', 2 ),',',-1) AS last_tp_changed,


\@user_deposit := if(c.name IS NULL, b.deposit, cb.deposit) AS user_deposit,
\@user_credit := if(c.name IS NULL, 0, c.credit) AS user_credit,


SUBSTRING_INDEX(\@last_payment_info:=GET_LAST_PAYMENT_INFO(u.uid), ',', 1 ) AS last_payment_sum, 
\@last_payment_date := SUBSTRING_INDEX(SUBSTRING_INDEX(\@last_payment_info, ',', 2 ),',',-1) AS last_payment_date,
SUBSTRING_INDEX(SUBSTRING_INDEX(\@last_payment_info, ',', 3 ),',',-1) AS last_payment_method,

if(tp.day_fee>0, curdate() + interval (\@user_deposit / tp.day_fee) day, 0) AS to_payments_date,

if ( \@user_deposit + \@user_credit < 0, NOW()-\@last_payment_date, 0) AS prosrochennyh_dney,

u.disable, 
'activnost na forume',
'bonus actions',

if (u.disable=1, SUBSTRING_INDEX(\@disable_info:=GET_ACTION_INFO(u.uid, 9, ''), ',', 1), '') AS DISABLE_DATE,
if (u.disable=1, SUBSTRING_INDEX(SUBSTRING_INDEX(\@disable_info, ',', 2 ),',',-1), '') AS DISABLE_COMMENTS,

u.uid

FROM users u
INNER JOIN users_pi pi ON (u.uid=pi.uid)
INNER JOIN dv_main  dv ON (u.uid=dv.uid)
INNER JOIN tarif_plans tp ON (tp.id=dv.tp_id)
     LEFT JOIN bills b ON (u.bill_id=b.id)
     LEFT JOIN groups g ON (u.gid=g.gid)
     LEFT JOIN companies c ON (u.company_id=c.id)
     LEFT JOIN bills cb ON (c.bill_id=cb.id)
LEFT JOIN _segment_list _segment ON (_segment.id=pi._segment)
 LEFT JOIN builds ON (builds.id=pi.location_id)
 LEFT JOIN streets  ON (streets.id=builds.street_id)
 LEFT JOIN districts   ON (districts.id=streets.district_id)
WHERE u.domain_id='$admin->{DOMAIN_ID}'
GROUP BY u.uid", 'do'
  );

  $self->query2("SELECT login,
fio,
registration,
aid,
_segment,
_district,
address_street,
address_build,
address_flat,
_entrance,
_flor,
tp_id,
last_tp_id,
last_tp_changed,

credit,
deposit,

last_payment_sum,
last_payment_date,
last_payment_method,
'-',
to_payments_date,
prosrochennyh_dney,
status,
forum_activity,
bonus,
disable_date,
disable_comments,
uid 
FROM marketing_report_2
$WHERE 
    ORDER BY $SORT $DESC 
    LIMIT $PG, $PAGE_ROWS;
 ;", undef, $attr
  );

  return [ ] if ($self->{errno});

  my $list = $self->{list};

  if ($self->{TOTAL} >= 0) {
    $self->query2("SELECT count(*) AS total FROM marketing_report_2
    $WHERE;", undef, { INFO => 1 }
    );
  }

  return $list;
}

#**********************************************************
# report1()
#**********************************************************
sub triplay_stats {
  my $self   = shift;
  my ($attr) = @_;

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $WHERE =  $self->search_former($attr, [
     ['LOCATION_ID', 'INT', 'pi.location_id' ]
    ],
    { WHERE       => 1,
    }
    );

  $self->query2("SELECT CONCAT(s.name, ', ', b.number), pi.address_flat,  u.id,

   dv_tp.name,
   voip_tp.name,
   iptv_tp.name,

   pi.fio,
   pi.phone,
   pi.uid

  FROM streets s
  LEFT JOIN builds b ON (s.id=b.street_id)
  LEFT JOIN users_pi pi ON (b.id=pi.location_id)
  LEFT JOIN dv_main dv ON (pi.uid=dv.uid)
   LEFT JOIN tarif_plans dv_tp ON (dv.tp_id=dv_tp.id AND module='Dv')
  LEFT JOIN voip_main voip ON (pi.uid=voip.uid)
   LEFT JOIN tarif_plans voip_tp ON (voip_tp.tp_id=voip.tp_id)
  LEFT JOIN iptv_main iptv ON (pi.uid=iptv.uid)
   LEFT JOIN tarif_plans iptv_tp ON (iptv_tp.tp_id=iptv.tp_id)

  LEFT JOIN users u ON (u.uid=pi.uid)
$WHERE
   GROUP BY pi.uid
   ORDER BY $SORT $DESC 
   LIMIT $PG, $PAGE_ROWS;",
   undef,
   $attr
  );

  return [ ] if ($self->{errno});

  my $list = $self->{list};

  if ($self->{TOTAL} >= 0) {
    $self->query2("SELECT count(DISTINCT pi.uid)  AS total
      FROM streets s
  LEFT JOIN builds b ON (s.id=b.street_id)
  LEFT JOIN users_pi pi ON (b.id=pi.location_id)
    $WHERE;",
    undef, { INFO => 1 }
    );

  }

  return $list;
}

#**********************************************************
#
#**********************************************************
sub dhcp_full_list {
  my $self   = shift;
  my ($attr) = @_;

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $WHERE =  $self->search_former($attr, [
     ['TP_ID',    'INT', 'dv.tp_id' ],
     ['NAS_ID',   'INT', 'dhcp.nas' ]
    ],
    { WHERE       => 1,
    	USERS_FIELDS=> 1
    }
    );

  $self->query2("SELECT u.id AS login, 
    g.name AS group_name, 
    u.registration, 
if(company.id IS NULL, b.deposit, cb.deposit) AS deposit,
tp.name AS tp_name,
INET_NTOA(dhcp.ip) AS ip,
n.name AS nas_name,
dhcp.ports,
pi.fio,
CONCAT(pi.address_street, ' ', pi.address_build, ',', pi.address_flat) AS address_full,
pi.phone,
dhcp.nas AS nas_id,
u.uid
FROM dhcphosts_hosts dhcp
INNER JOIN users u ON (u.uid=dhcp.uid)
  LEFT JOIN bills b ON (u.bill_id = b.id)
  LEFT JOIN companies company ON  (u.company_id=company.id) 
  LEFT JOIN bills cb ON  (company.bill_id=cb.id)

  LEFT JOIN users_pi pi ON (pi.uid=u.uid)
  LEFT JOIN dv_main dv ON (dv.uid=u.uid)
  LEFT JOIN tarif_plans tp ON (tp.id=dv.tp_id)
  LEFT JOIN nas n ON (dhcp.nas=n.id)
  LEFT JOIN groups g ON (g.gid=u.gid)
$WHERE
GROUP BY dhcp.id
   ORDER BY $SORT $DESC 
   LIMIT $PG, $PAGE_ROWS;",
   undef,
   $attr
  );

  return [ ] if ($self->{errno});
  my $list = $self->{list};


$self->query2("SELECT count(*) AS total_users FROM dhcphosts_hosts dhcp
INNER JOIN users u ON (u.uid=dhcp.uid)
  LEFT JOIN bills b ON (u.bill_id = b.id)
  LEFT JOIN companies company ON  (u.company_id=company.id) 
  LEFT JOIN bills cb ON  (company.bill_id=cb.id)

  LEFT JOIN users_pi pi ON (pi.uid=u.uid)
  LEFT JOIN dv_main dv ON (dv.uid=u.uid)
  LEFT JOIN tarif_plans tp ON (tp.id=dv.tp_id)
  LEFT JOIN nas n ON (dhcp.nas=n.id)
  LEFT JOIN groups g ON (g.gid=u.gid)
$WHERE
;",
   undef,
   { INFO => 1 }
  );


  return $list;
}

1

__END__

CREATE TEMPORARY TABLE IF NOT EXISTS marketing_report_2
(
login varchar(40) not null default '',
fio varchar(40) not null default '',
registration date,
aid smallint unsigned not null default 0,
_segment varchar(40) not null default '',
_district varchar(40) not null default '',
address_street varchar(40) not null default '',
address_build varchar(6) not null default '',
address_flat varchar(6) not null default '',
_entrance tinyint unsigned not null default 0,
_flor tinyint unsigned not null default 0,
tp_id smallint unsigned not null default 0,
last_tp_id smallint unsigned not null default 0,
last_tp_changed date not null default '0000-00-00',

credit double(10,2) unsigned not null default 0,
deposit double(10,2) unsigned not null default 0,

last_payment_sum double(10,2) unsigned not null default 0,
last_payment_date datetime not null,
last_payment_method tinyint unsigned not null default 0,
to_payments_date date not null default '0000-00-00',
prosrochennyh_dney smallint unsigned not null default 0,
status tinyint unsigned not null default 0,
forum_activity varchar(40) not null default '',
bonus varchar(40) not null default '',
disable_date datetime not null,
disable_comments varchar(40) not null default '',
uid int unsigned not null default 0
);

insert into marketing_report_2
(
login,
fio,
registration,
aid,
_segment,
_district,
address_street,
address_build,
address_flat,
_entrance,
_flor,
tp_id,
last_tp_id,
last_tp_changed,

credit,
deposit,

last_payment_sum,
last_payment_date,
last_payment_method,
to_payments_date,
prosrochennyh_dney,
status,
forum_activity,
bonus,
disable_date,
disable_comments,
uid
)

SELECT 
u.id,
pi.fio,
u.registration,
0,
_segment.name,
_district.name,
pi.address_street,
pi.address_build,
pi.address_flat,
pi._entrance, 
pi._flor,

dv.tp_id,
SUBSTRING_INDEX(@last_tp_info:=GET_LAST_TP(u.uid), ',', 1 ) AS last_tp_id, 
SUBSTRING_INDEX(SUBSTRING_INDEX(@last_tp_info, ',', 2 ),',',-1) AS last_tp_changed,

@user_deposit := if(c.name IS NULL, b.deposit, cb.deposit) AS user_deposit,
@user_credit := if(c.name IS NULL, 0, c.credit) AS user_credit,


SUBSTRING_INDEX(@last_payment_info:=GET_LAST_PAYMENT_INFO(u.uid), ',', 1 ) AS last_payment_sum, 
@last_payment_date := SUBSTRING_INDEX(SUBSTRING_INDEX(@last_payment_info, ',', 2 ),',',-1) AS last_payment_date,
SUBSTRING_INDEX(SUBSTRING_INDEX(@last_payment_info, ',', 3 ),',',-1) AS last_payment_method,
if(tp.day_fee>0, curdate() + interval (@user_deposit / tp.day_fee) day, 0) AS to_payments_date,
if ( @user_deposit + @user_credit < 0, NOW()-@last_payment_date, 0) AS prosrochennyh_dney,

u.disable, 
'activnost na forume',
'bonus actions',
if (u.disable=1, SUBSTRING_INDEX(@disable_info:=GET_ACTION_INFO(u.uid, 9, ''), ',', 1), '') AS DISABLE_DATE,
if (u.disable=1, SUBSTRING_INDEX(SUBSTRING_INDEX(@disable_info, ',', 2 ),',',-1), '') AS DISABLE_COMMENTS,
u.uid

FROM users u
INNER JOIN users_pi pi ON (u.uid=pi.uid)
INNER JOIN dv_main  dv ON (u.uid=dv.uid)
INNER JOIN tarif_plans tp ON (tp.id=dv.tp_id)
     LEFT JOIN bills b ON (u.bill_id=b.id)
     LEFT JOIN groups g ON (u.gid=g.gid)
     LEFT JOIN companies c ON (u.company_id=c.id)
     LEFT JOIN bills cb ON (c.bill_id=cb.id)
LEFT JOIN _segment_list _segment ON (_segment.id=pi._segment)
LEFT JOIN _district_list _district ON (_district.id=pi._district)
WHERE u.domain_id='$admin->{DOMAIN_ID}' 
GROUP BY u.uid 
rosrochennyh_dney,

u.disable, 
'activnost na forume',
'bonus actions',
if (u.disable=1, SUBSTRING_INDEX(@disable_info:=GET_ACTION_INFO(u.uid, 9, ''), ',', 1), '') AS DISABLE_DATE,
if (u.disable=1, SUBSTRING_INDEX(SUBSTRING_INDEX(@disable_info, ',', 2 ),',',-1), '') AS DISABLE_COMMENTS,
u.uid

FROM users u
INNER JOIN users_pi pi ON (u.uid=pi.uid)
INNER JOIN dv_main  dv ON (u.uid=dv.uid)
INNER JOIN tarif_plans tp ON (tp.id=dv.tp_id)
     LEFT JOIN bills b ON (u.bill_id=b.id)
     LEFT JOIN groups g ON (u.gid=g.gid)
     LEFT JOIN companies c ON (u.company_id=c.id)
     LEFT JOIN bills cb ON (c.bill_id=cb.id)
LEFT JOIN _segment_list _segment ON (_segment.id=pi._segment)
LEFT JOIN _district_list _district ON (_district.id=pi._district)
WHERE u.domain_id='$admin->{DOMAIN_ID}' 
GROUP BY u.uid 
AS prosrochennyh_dney,

u.disable, 
'activnost na forume',
'bonus actions',
if (u.disable=1, SUBSTRING_INDEX(@disable_info:=GET_ACTION_INFO(u.uid, 9, ''), ',', 1), '') AS DISABLE_DATE,
if (u.disable=1, SUBSTRING_INDEX(SUBSTRING_INDEX(@disable_info, ',', 2 ),',',-1), '') AS DISABLE_COMMENTS,
u.uid

FROM users u
INNER JOIN users_pi pi ON (u.uid=pi.uid)
INNER JOIN dv_main  dv ON (u.uid=dv.uid)
INNER JOIN tarif_plans tp ON (tp.id=dv.tp_id)
     LEFT JOIN bills b ON (u.bill_id=b.id)
     LEFT JOIN groups g ON (u.gid=g.gid)
     LEFT JOIN companies c ON (u.company_id=c.id)
     LEFT JOIN bills cb ON (c.bill_id=cb.id)
LEFT JOIN _segment_list _segment ON (_segment.id=pi._segment)
LEFT JOIN _district_list _district ON (_district.id=pi._district)
WHERE u.domain_id='$admin->{DOMAIN_ID}' 
GROUP BY u.uid 
AS prosrochennyh_dney,

u.disable, 
'activnost na forume',
'bonus actions',
if (u.disable=1, SUBSTRING_INDEX(@disable_info:=GET_ACTION_INFO(u.uid, 9, ''), ',', 1), '') AS DISABLE_DATE,
if (u.disable=1, SUBSTRING_INDEX(SUBSTRING_INDEX(@disable_info, ',', 2 ),',',-1), '') AS DISABLE_COMMENTS,
u.uid

FROM users u
INNER JOIN users_pi pi ON (u.uid=pi.uid)
INNER JOIN dv_main  dv ON (u.uid=dv.uid)
INNER JOIN tarif_plans tp ON (tp.id=dv.tp_id)
     LEFT JOIN bills b ON (u.bill_id=b.id)
     LEFT JOIN groups g ON (u.gid=g.gid)
     LEFT JOIN companies c ON (u.company_id=c.id)
     LEFT JOIN bills cb ON (c.bill_id=cb.id)
LEFT JOIN _segment_list _segment ON (_segment.id=pi._segment)
LEFT JOIN _district_list _district ON (_district.id=pi._district)
WHERE u.domain_id='$admin->{DOMAIN_ID}' 
GROUP BY u.uid 
