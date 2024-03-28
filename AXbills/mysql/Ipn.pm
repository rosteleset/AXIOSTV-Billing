package Ipn;

=head1 NAME

  Ipn functions

=cut

use strict;
use AXbills::Base qw(ip2int int2ip);
use parent qw(dbcore);
use POSIX qw(strftime);
use Billing;

my ($Billing, $SORT, $DESC, $PG, $PAGE_ROWS);
my $DATE = POSIX::strftime("%Y-%m-%d", localtime(time));
my ($Y, $M, $D) = split(/-/, $DATE, 3);

#my $CONF;
#my $admin;
my $debug = 0;

#**********************************************************
# Init
#**********************************************************
sub new {
  my $class = shift;
  my ($db, $CONF) = @_;

  my $self = {};
  bless($self, $class);

  #$admin->{MODULE} = 'Ipn';

  $self->{db}=$db;
  $self->{conf}=$CONF;

  if (!defined($CONF->{KBYTE_SIZE})) {
    $CONF->{KBYTE_SIZE} = 1024;
  }

  $CONF->{MB_SIZE} = $CONF->{KBYTE_SIZE} * $CONF->{KBYTE_SIZE};

  if ($CONF->{DELETE_USER}) {
    $self->user_del({ UID => $CONF->{DELETE_USER} });
  }

  #alternative host for detail
  if($CONF->{IPN_DBHOST}) {
    require AXbills::SQL;
    AXbills::SQL->import();

    my $sql = AXbills::SQL->connect('mysql', $CONF->{IPN_DBHOST}, $CONF->{IPN_DBNAME}, $CONF->{IPN_DBUSER}, $CONF->{IPN_DBPASSWD}, { CHARSET => ($CONF->{IPN_DBCHARSET}) ? $CONF->{IPN_DBCHARSET} : 'utf8' });
    
    if (! $sql->{db}) {
      exit;
    }
    $self->{db2} = $sql->{db};
  }

  $CONF->{BUILD_DELIMITER} = ', ' if (!defined($CONF->{BUILD_DELIMITER}));

  $self->{TRAFFIC_ROWS} = 0;
  $Billing = Billing->new($self->{db}, $CONF);
  return $self;
}

#**********************************************************
# Delete user log
# user_del
#**********************************************************
sub user_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('ipn_log', undef, { uid => $attr->{UID} });

  return $self;
}

#**********************************************************
=head1 user_status($DATA)

=cut
#**********************************************************
sub user_status {
  my $self = shift;
  my ($DATA) = @_;

  my $SESSION_START = 'now()';
  my $sql  = '';

  my $nas_id = $DATA->{NAS_ID_SWITCH} || $DATA->{NAS_ID} || 0;

  #Get active session
  $self->query("SELECT framed_ip_address FROM dv_calls WHERE 
    user_name='$DATA->{USER_NAME}'
    AND acct_session_id='IP'
    AND nas_id='$nas_id' LIMIT 1;");

  if ($self->{TOTAL} > 0) {
    $sql = "UPDATE dv_calls SET
    status='$DATA->{ACCT_STATUS_TYPE}',
    started=$SESSION_START, 
    lupdated=UNIX_TIMESTAMP(), 
    nas_port_id='$DATA->{NAS_PORT}', 
    acct_session_id='$DATA->{ACCT_SESSION_ID}', 
    framed_ip_address=INET_ATON('$DATA->{FRAMED_IP_ADDRESS}'), 
    CID='$DATA->{CALLING_STATION_ID}', 
    CONNECT_INFO='$DATA->{CONNECT_INFO}' 
    WHERE user_name='$DATA->{USER_NAME}'
    AND acct_session_id='IP'
    AND nas_id='$nas_id' LIMIT 1;";
    $self->query("$sql", 'do');
  }
  else {
    $self->query_add('dv_calls', {
      %$DATA,
      STATUS          => $DATA->{ACCT_STATUS_TYPE} || 1, 
      STARTED         => $SESSION_START, 
      LUPDATED        => 'UNIX_TIMESTAMP()',
      NAS_PORT_ID     => $DATA->{NAS_PORT}, 
      FRAMED_IP_ADDRESS=>"INET_ATON('$DATA->{FRAMED_IP_ADDRESS}')", 
      CID             => $DATA->{CALLING_STATION_ID}, 
      NAS_ID          => $nas_id,
    });
  }

  return $self;
}

#**********************************************************
# traffic_add_log
#**********************************************************
sub traffic_recalc {
  my $self = shift;
  my ($attr) = @_;

  $self->query("UPDATE ipn_log SET
     sum='$attr->{SUM}'
   WHERE 
         uid='$attr->{UID}' and 
         start='$attr->{START}' and 
         traffic_class='$attr->{TRAFFIC_CLASS}' and 
         traffic_in='$attr->{IN}' and 
         traffic_out='$attr->{OUT}' and
         session_id='$attr->{SESSION_ID}';", 'do'
  );

  return $self;
}

#**********************************************************
# traffic_add_log
#**********************************************************
sub traffic_recalc_bill {
  my $self = shift;
  my ($attr) = @_;

  $self->query("UPDATE bills SET  deposit=deposit + $attr->{SUM}
    WHERE  id= ? ;", 
    'do',
    { Bind => [ $attr->{BILL_ID} ] }
  );

  return $self;
}

#**********************************************************
# List
#**********************************************************
sub list {
  my $self = shift;
  my ($attr) = @_;

  my @WHERE_RULES = ();
  my $WHERE       = '';

  my $table_name = "ipn_traf_log_" . $Y . "_" . $M;

  my $GROUP = '';
  my $size  = 'size';

  if ($attr->{GROUPS}) {
    $GROUP = "GROUP BY $attr->{GROUPS}";
    $size  = "SUM(size)";
  }

  if ($attr->{SRC_ADDR}) {
    push @WHERE_RULES, "src_addr=INET_ATON('$attr->{SRC_ADDR}')";
  }

  if (defined($attr->{SRC_PORT}) && $attr->{SRC_PORT} =~ /^\d+$/) {
    push @WHERE_RULES, "src_port='$attr->{SRC_PORT}'";
  }

  if ($attr->{DST_ADDR}) {
    push @WHERE_RULES, "dst_addr=INET_ATON('$attr->{DST_ADDR}')";
  }

  if (defined($attr->{DST_PORT}) && $attr->{DST_PORT} =~ /^\d+$/) {
    push @WHERE_RULES, "dst_port='$attr->{DST_PORT}'";
  }

  #my $f_time = 'f_time';

  #Interval from date to date
  if ($attr->{INTERVAL}) {
    my ($from, $to) = split(/\//, $attr->{INTERVAL}, 2);
    push @WHERE_RULES, "DATE_FORMAT(f_time, '%Y-%m-%d')>='$from' and DATE_FORMAT(f_time, '%Y-%m-%d')<='$to'";
  }

  #Period
  elsif (defined($attr->{PERIOD})) {
    my $period = $attr->{PERIOD} || 0;
    if ($period == 4) { $WHERE .= ''; }
    else {
      $WHERE .= ($WHERE ne '') ? ' and ' : 'WHERE ';
      if    ($period == 0) { push @WHERE_RULES, "DATE_FORMAT(f_time, '%Y-%m-%d')=CURDATE()"; }
      elsif ($period == 1) { push @WHERE_RULES, "TO_DAYS(CURDATE()) - TO_DAYS(f_time) = 1 "; }
      elsif ($period == 2) { push @WHERE_RULES, "YEAR(CURDATE()) = YEAR(f_time) and (WEEK(CURDATE()) = WEEK(f_time)) "; }
      elsif ($period == 3) { push @WHERE_RULES, "DATE_FORMAT(f_time, '%Y-%m')=DATE_FORMAT(CURDATE(), '%Y-%m') "; }
      elsif ($period == 5) { push @WHERE_RULES, "DATE_FORMAT(f_time, '%Y-%m-%d')='$attr->{DATE}' "; }
      else                 { $WHERE .= "DATE_FORMAT(f_time, '%Y-%m-%d')=CURDATE() "; }
    }
  }
  elsif ($attr->{DATE}) {
    push @WHERE_RULES, "DATE_FORMAT(f_time, '%Y-%m-%d')='$attr->{DATE}'";
  }

  my $lupdate = '';

  if ($attr->{INTERVAL_TYPE} eq 3) {
    $lupdate = "DATE_FORMAT(f_time, '%Y-%m-%d')";
    $GROUP   = "GROUP BY 1";
    $size    = 'SUM(size)';
  }
  elsif ($attr->{INTERVAL_TYPE} eq 2) {
    $lupdate = "DATE_FORMAT(f_time, '%Y-%m-%d %H')";
    $GROUP   = "GROUP BY 1";
    $size    = 'SUM(size)';
  }
  else {
    $lupdate = "f_time";
  }

  $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

  $self->query("SELECT 
  $lupdate,
  $size,
  INET_NTOA(src_addr),
  src_port,
  INET_NTOA(dst_addr),
  dst_port,

  protocol
  FROM $table_name
  $WHERE
  $GROUP
  ORDER BY $SORT $DESC 
  LIMIT $PG, $PAGE_ROWS
  ;",
  undef,
  $attr
  );

  my $list = $self->{list};

  $self->query("SELECT COUNT(*) AS count, SUM(size) AS sum
  FROM $table_name;", undef, { INFO => 1 }
  );

  return $list;
}

#**********************************************************
=head2 stats($attr) - Base stats

=cut
#**********************************************************
sub stats {
  my $self = shift;
  my ($attr) = @_;

  my @WHERE_RULES = ();

  if ($attr->{UID}) {
    push @WHERE_RULES, "l.uid='$attr->{UID}'";
  }

  if ($attr->{SESSION_ID}) {
    push @WHERE_RULES, "l.session_id='$attr->{SESSION_ID}'";
  }

  my $GROUP = 'l.uid, l.ip, l.traffic_class';

  my $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';
  $self->query("SELECT u.id AS login, min(l.start) AS start, INET_NTOA(l.ip) AS ip, 
   l.traffic_class,
   tt.descr,
   SUM(l.traffic_in), SUM(l.traffic_out),
   SUM(sum),
   l.nas_id
   from (ipn_log l)
   LEFT join  users u ON (l.uid=u.uid)
   LEFT join  trafic_tarifs tt ON (l.interval_id=tt.interval_id and l.traffic_class=tt.id)
   $WHERE 
   GROUP BY $GROUP
  ;",
  undef,
  $attr
  );

  my $list = $self->{list};

  $self->query("SELECT count(*) AS count,  SUM(l.traffic_in) AS sum, SUM(l.traffic_out)
  FROM  ipn_log l
  $WHERE
  ;",
  undef,
  { INFO => 1 }
  );

  return $list;
}

#**********************************************************
=head2 reports_users($attr)

  Arguments:
    $attr
      INTERVAL
      FROM_DATE
      TO_DATE
      UID

=cut
#**********************************************************
sub reports_users {
  my $self = shift;
  my ($attr) = @_;

  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;
  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 2;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';

  $self->query("SET SQL_BIG_SELECTS=1;");

  my $GROUP = '1';
  my $date  = '';
  my %EXT_TABLE_JOINS_HASH = ();

  if ($attr->{INTERVAL}) {
    ($attr->{FROM_DATE}, $attr->{TO_DATE}) = split(/\//, $attr->{INTERVAL}, 2);
  }

  $attr->{SKIP_DEL_CHECK}=1;

  my $WHERE =  $self->search_former($attr, [
      [ 'START',        'DATE', "DATE_FORMAT(l.start, '%Y-%m-%d')",     "DATE_FORMAT(l.start, '%Y-%m-%d') AS start"  ],
      [ 'IP',           'IP',   "INET_NTOA(l.ip)",     "INET_NTOA(l.ip) AS ip"  ],
      [ 'USERS_COUNT',  'INT',  'COUNT(DISTINCT l.uid) AS users_count', 'COUNT(DISTINCT l.uid) AS users_count'   ],
      [ 'TRAFFIC_IN',   'INT',  'SUM(l.traffic_in)',                    'SUM(l.traffic_in) AS traffic_in'        ],
      [ 'TRAFFIC_OUT',  'INT',  'SUM(l.traffic_out)',                   'SUM(l.traffic_out) AS traffic_out'      ],
      [ 'TRAFFIC_SUM',  'INT',  'SUM(l.traffic_in+l.traffic_out)',      'SUM(l.traffic_in+l.traffic_out) AS traffic_sum' ],

      [ 'TRAFFIC0_IN',  'INT',  'SUM(if(l.traffic_class=0, l.traffic_in, 0))',               'SUM(if(l.traffic_class=0, l.traffic_in, 0)) AS traffic0_in' ],
      [ 'TRAFFIC0_OUT', 'INT',  'SUM(if(l.traffic_class=0, l.traffic_out, 0))',              'SUM(if(l.traffic_class=0, l.traffic_out, 0)) AS traffic0_out' ],
      [ 'TRAFFIC0_SUM', 'INT',  'SUM(if(l.traffic_class=0, l.traffic_in+l.traffic_out, 0))', 'SUM(if(l.traffic_class=0, l.traffic_in+l.traffic_out, 0)) AS traffic0_sum' ],

      [ 'TRAFFIC1_IN',  'INT',  'SUM(if(l.traffic_class=1, l.traffic_in, 0))',               'SUM(if(l.traffic_class=1, l.traffic_in, 0)) AS traffic1_in' ],
      [ 'TRAFFIC1_OUT', 'INT',  'SUM(if(l.traffic_class=1, l.traffic_out, 0))',              'SUM(if(l.traffic_class=1, l.traffic_out, 0)) AS traffic1_out' ],
      [ 'TRAFFIC1_SUM', 'INT',  'SUM(if(l.traffic_class=1, l.traffic_in+l.traffic_out, 0))', 'SUM(if(l.traffic_class=1, l.traffic_in+l.traffic_out, 0)) AS traffic1_sum' ],

      [ 'SUM',              'INT',   'l.sum',   'SUM(l.sum) AS sum' ],

      ['METHOD',            'INT',   'p.method'                          ],
      ['MONTH',             'DATE',  "DATE_FORMAT(l.start, '%Y-%m')"     ],
      ['FROM_DATE|TO_DATE', 'DATE',  "DATE_FORMAT(l.start, '%Y-%m-%d')"  ],
      ['DATE',              'DATE',  "DATE_FORMAT(l.start, '%Y-%m-%d')"  ],
      ['FROM_TIME|TO_TIME', 'DATE',  "DATE_FORMAT(l.start, '%H-%i')"     ],
      ['HOUR',              'DATE',  "DATE_FORMAT(start, '%Y-%m-%d %H')" ],

      ['SESSION_ID',        'STR',   "l.session_id",                     ],
      ['UID',               'INT',   'l.uid'                             ],
    ],
    { 
      WHERE             => 1,
      USERS_FIELDS      => 1,
      USE_USER_PI       => 1,
      #WHERE_RULES       => \@WHERE_RULES,
      SKIP_USERS_FIELDS => [ 'UID', 'LOGIN' ],
    }
  );

  my @WHERE_RULES = ();
  if ($attr->{UID}) {
    if ($attr->{HOURS}) {
      $date  = "DATE_FORMAT(l.start, '%Y-%m-%d %H') AS hours";
    }
    else {
      $date = "DATE_FORMAT(start, '%Y-%m-%d') AS start";
    }

    $date  = " $date, l.traffic_class, tt.descr";
    $EXT_TABLE_JOINS_HASH{traffic_tarifs}=1;
    $GROUP = '1, 2';
  }
  else {
    $date = " DATE_FORMAT(start, '%Y-%m-%d') AS date, COUNT(DISTINCT l.uid) AS users_count ";
    $self->{SEARCH_FIELDS_COUNT}+=2;
  }

  my @tables = ();
  #Interval from date to date
  if ($attr->{INTERVAL}) {
    my ($from, $to) = split(/\//, $attr->{INTERVAL}, 2);

    my ($from_y, $from_m, $from_d) = split(/-/, $from);
    my ($to_y,   $to_m,   $to_d)   = split(/-/, $to);
    #my ($y,      $m,      $d)      = split(/-/, $attr->{CUR_DATE});
    my $START_DATE      = "$from_y$from_m";
    my $FINISH_DATE     = "$to_y$to_m";
    my $START_DATE_DAY  = "$from_y$from_m$from_d";
    my $FINISH_DATE_DAY = "$to_y$to_m$to_d";

    $self->query("SHOW TABLES LIKE 'ipn_log_%';");
    my $list = $self->{list} || [];

    foreach my $line (@$list) {
      my $table = $line->[0];
      if ($table =~ m/ipn_log_(\d{4})_(\d{2})$/) {
        my $table_date = "$1$2";
        if ($table_date >= $START_DATE && $table_date <= $FINISH_DATE) {
          print $table. "\n" if ($debug > 1);
          push @tables, $table;
        }
      }
      elsif ($table =~ m/ipn_log_(\d{4})_(\d{2})_(\d{2})$/) {
        my $table_date = "$1$2$3";
        if ($table_date >= $START_DATE_DAY && $table_date <= $FINISH_DATE_DAY) {
          print $table. "\n" if ($debug > 1);
          push @tables, $table;
        }
      }
    }

    $attr->{TYPE} = '-' if (!$attr->{TYPE});
    if ($attr->{TYPE} eq 'HOURS') {
      $date = "DATE_FORMAT(l.start, '\%H') AS hours, count(DISTINCT l.uid) AS users_count";
    }
    elsif ($attr->{TYPE} eq 'DAYS_TCLASS') {
      $date  = "DATE_FORMAT(l.start, '%Y-%m-%d') AS start, '-', l.traffic_class, tt.descr";
      $GROUP = '1,3';
    }
    elsif ($attr->{TYPE} eq 'DAYS') {
      $date = "DATE_FORMAT(l.start, '%Y-%m-%d') AS start, count(DISTINCT l.uid) AS users_count";
    }
    elsif ($attr->{TYPE} eq 'TP') {
      $date = "l.tp_id";
    }
    elsif ($attr->{TYPE} eq 'GID') {
      $date = "u.gid";
      $EXT_TABLE_JOINS_HASH{users}=1;
    }
    elsif ($attr->{TYPE} eq 'DISTRICT') {
      $date = "districts.name AS district_name";
      $self->{SEARCH_FIELDS} .= 'districts.id AS district_id,';
      $EXT_TABLE_JOINS_HASH{users}=1;
      $EXT_TABLE_JOINS_HASH{users_pi}=1;
      $EXT_TABLE_JOINS_HASH{builds}=1;
      $EXT_TABLE_JOINS_HASH{streets}=1;
      $EXT_TABLE_JOINS_HASH{districts}=1;
    }
    elsif ($attr->{TYPE} eq 'STREET') {
      $date = "streets.name AS street_name";
      $self->{SEARCH_FIELDS} .= 'streets.id AS street_id,';
      $EXT_TABLE_JOINS_HASH{users}=1;
      $EXT_TABLE_JOINS_HASH{users_pi}=1;
      $EXT_TABLE_JOINS_HASH{builds}=1;
      $EXT_TABLE_JOINS_HASH{streets}=1;
    }
    elsif ($attr->{TYPE} eq 'BUILD') {
      $date = "CONCAT(streets.name, '$self->{conf}->{BUILD_DELIMITER}', builds.number) AS build";
      $self->{SEARCH_FIELDS} .= 'builds.id AS location_id,';
      $EXT_TABLE_JOINS_HASH{users}=1;
      $EXT_TABLE_JOINS_HASH{users_pi}=1;
      $EXT_TABLE_JOINS_HASH{builds}=1;
      $EXT_TABLE_JOINS_HASH{streets}=1;
    }
    elsif ($attr->{TYPE} eq 'USER') {
      $date = "u.id AS login";
      $self->{SEARCH_FIELDS} .= "l.uid,";
      $EXT_TABLE_JOINS_HASH{users}=1;
    }
  }

  #Period
  elsif (defined($attr->{PERIOD})) {
    my $period = $attr->{PERIOD} || 0;
    if ($period == 4) { $WHERE .= ''; }
    else {
      $WHERE .= ($WHERE ne '') ? ' and ' : 'WHERE ';
      if    ($period == 0) { push @WHERE_RULES, "DATE_FORMAT(start, '%Y-%m-%d')=CURDATE()"; }
      elsif ($period == 1) { push @WHERE_RULES, "TO_DAYS(CURDATE()) - TO_DAYS(start) = 1 "; }
      elsif ($period == 2) { push @WHERE_RULES, "YEAR(CURDATE()) = YEAR(start) and (WEEK(CURDATE()) = WEEK(start)) "; }
      elsif ($period == 3) { push @WHERE_RULES, "DATE_FORMAT(start, '%Y-%m')=DATE_FORMAT(CURDATE(), '%Y-%m') "; }
      elsif ($period == 5) { push @WHERE_RULES, "DATE_FORMAT(start, '%Y-%m-%d')='$attr->{DATE}' "; }
      else                 { $WHERE .= "DATE_FORMAT(start, '%Y-%m-%d')=CURDATE() "; }
    }
  }
  elsif ($attr->{HOUR}) {
    #push @WHERE_RULES, "DATE_FORMAT(start, '%Y-%m-%d %H')='$attr->{HOUR}'";
    $GROUP = "1, 2, 3";
    $date  = "DATE_FORMAT(start, '%Y-%m-%d %H') AS hours, u.id AS login, l.traffic_class, tt.descr ";
    $EXT_TABLE_JOINS_HASH{users}=1;
  }
  elsif ($attr->{DATE}) {
    #push @WHERE_RULES, "DATE_FORMAT(start, '%Y-%m-%d')='$attr->{DATE}'";
    if ($attr->{HOURS}) {
      $GROUP = "1, 3";
      $date  = "DATE_FORMAT(start, '%Y-%m-%d %H') AS hours, count(DISTINCT l.uid) AS users_count, l.traffic_class, tt.descr ";
      $EXT_TABLE_JOINS_HASH{traffic_tarifs}=1;
    }
    elsif ($attr->{TYPE} eq 'USER') {
      $date = "u.id AS login";
      $self->{SEARCH_FIELDS} .= "l.uid,";
      $EXT_TABLE_JOINS_HASH{users}=1;
    }
    else {
      $GROUP = "1, 2, 3";
      $date  = "DATE_FORMAT(start, '%Y-%m-%d') AS start, u.id AS login, l.traffic_class, tt.descr ";
      $EXT_TABLE_JOINS_HASH{users}=1;
      $EXT_TABLE_JOINS_HASH{traffic_tarifs}=1;
    }
  }
  elsif ($attr->{MONTH}) {
    #push @WHERE_RULES, "DATE_FORMAT(l.start, '%Y-%m')='$attr->{MONTH}'";
  }
  else {
    $date = "DATE_FORMAT(l.start, '%Y-%m') AS month, count(DISTINCT l.uid) AS users_count, ";
  }

  if ($self->{SEARCH_FIELDS}=~/u\.|pi\./ || $WHERE =~ / u\./) {
    $EXT_TABLE_JOINS_HASH{users}=1;
  }

  my $EXT_TABLES = $self->mk_ext_tables({ JOIN_TABLES     => \%EXT_TABLE_JOINS_HASH,
                                          EXTRA_PRE_JOIN  => [ 'users:LEFT JOIN users u ON (l.uid=u.uid)',
                                                               'traffic_tarifs:LEFT JOIN trafic_tarifs tt ON (l.interval_id=tt.interval_id and l.traffic_class=tt.id)'
                                                              ]
                                       });

  my $sql = "SELECT $date,
     $self->{SEARCH_FIELDS}
   l.nas_id, l.uid
   FROM %TABLE% l
   $EXT_TABLES
   $WHERE
   GROUP BY $GROUP";

  my $sql2 = "SELECT COUNT(DISTINCT l.uid) AS users_count, SUM(l.traffic_in) AS traffic_in_sum,
    SUM(l.traffic_out) AS traffic_out_sum,
    SUM(l.sum) AS sum
  from  %TABLE% l
  $EXT_TABLES
  $WHERE ";

  my $full_sql  = '';
  my $full_sql2 = '';

  if ($#tables > -1) {
    for (my $i = 0 ; $i <= $#tables ; $i++) {
      my $table = $tables[$i];
      my $sql3  = $sql;
      $sql3 =~ s/\%TABLE\%/$table/g;

      $full_sql .= "$sql3\n";

      my $sql4 = $sql2;
      $sql4 =~ s/\%TABLE\%/$table/g;
      $full_sql2 .= "$sql4\n";

      $full_sql  .= " UNION ";
      $full_sql2 .= " UNION ";
    }
  }

  $sql  =~ s/\%TABLE\%/ipn_log/g;
  $sql2 =~ s/\%TABLE\%/ipn_log/g;
  $full_sql  .= $sql;
  $full_sql2 .= $sql2;

  $full_sql .= " 
   ORDER BY $SORT $DESC ";

  #Rows query
  $self->query($full_sql, undef, $attr);
  my $list = $self->{list} || [];

  #totals query
  $self->query($full_sql2, undef, { INFO => 1 });

  return $list || [];
}

#**********************************************************
#
#**********************************************************
sub reports {
  my $self = shift;
  my ($attr) = @_;

  my $table_name = "ipn_traf_log_" . $Y . "_" . $M;
  my @WHERE_RULES= (); 
  my $WHERE      = '';

  my $GROUP = '';
  my $size  = 'size';

  if ($attr->{GROUPS}) {
    $GROUP = "GROUP BY $attr->{GROUPS}";
    $size  = "SUM(size)";
  }

  if ($attr->{SRC_ADDR}) {
    push @WHERE_RULES, "src_addr=INET_ATON('$attr->{SRC_ADDR}')";
  }

  if (defined($attr->{SRC_PORT}) && $attr->{SRC_PORT} =~ /^\d+$/) {
    push @WHERE_RULES, "src_port='$attr->{SRC_PORT}'";
  }

  if ($attr->{DST_ADDR}) {
    push @WHERE_RULES, "dst_addr=INET_ATON('$attr->{DST_ADDR}')";
  }

  if (defined($attr->{DST_PORT}) && $attr->{DST_PORT} =~ /^\d+$/) {
    push @WHERE_RULES, "dst_port='$attr->{DST_PORT}'";
  }

  #my $f_time = 'f_time';

  #Interval from date to date
  if ($attr->{INTERVAL}) {
    my ($from, $to) = split(/\//, $attr->{INTERVAL}, 2);
    push @WHERE_RULES, "DATE_FORMAT(f_time, '%Y-%m-%d')>='$from' and DATE_FORMAT(f_time, '%Y-%m-%d')<='$to'";
  }

  #Period
  elsif (defined($attr->{PERIOD})) {
    my $period = $attr->{PERIOD} || 0;
    if ($period == 4) { $WHERE .= ''; }
    else {
      $WHERE .= ($WHERE ne '') ? ' and ' : 'WHERE ';
      if    ($period == 0) { push @WHERE_RULES, "DATE_FORMAT(f_time, '%Y-%m-%d')=CURDATE()"; }
      elsif ($period == 1) { push @WHERE_RULES, "TO_DAYS(CURDATE()) - TO_DAYS(f_time) = 1 "; }
      elsif ($period == 2) { push @WHERE_RULES, "YEAR(CURDATE()) = YEAR(f_time) AND (WEEK(CURDATE()) = WEEK(f_time)) "; }
      elsif ($period == 3) { push @WHERE_RULES, "DATE_FORMAT(f_time, '%Y-%m')=DATE_FORMAT(CURDATE(), '%Y-%m') "; }
      elsif ($period == 5) { push @WHERE_RULES, "DATE_FORMAT(f_time, '%Y-%m-%d')='$attr->{DATE}' "; }
      else                 { $WHERE .= "DATE_FORMAT(f_time, '%Y-%m-%d')=CURDATE() "; }
    }
  }
  elsif ($attr->{HOUR}) {
    push @WHERE_RULES, "DATE_FORMAT(f_time, '%Y-%m-%d %H')='$attr->{HOUR}'";
  }
  elsif ($attr->{DATE}) {
    push @WHERE_RULES, "DATE_FORMAT(f_time, '%Y-%m-%d')='$attr->{DATE}'";
  }

  my $lupdate = '';

  if ($attr->{INTERVAL_TYPE} eq 3) {
    $lupdate = "DATE_FORMAT(f_time, '%Y-%m-%d')";
    $GROUP   = "GROUP BY 1";
    $size    = 'SUM(size)';
  }
  elsif ($attr->{INTERVAL_TYPE} eq 2) {
    $lupdate = "DATE_FORMAT(f_time, '%Y-%m-%d %H')";
    $GROUP   = "GROUP BY 1";
    $size    = 'SUM(size)';
  }
  else {
    $lupdate = "f_time";
  }

  $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';
  my $list;

  if (defined($attr->{HOSTS})) {
    $self->query("SELECT INET_NTOA(src_addr) AS src_ip, SUM(size) AS size, count(*) AS count
     from $table_name
     $WHERE
     GROUP BY 1
    ORDER BY 2 DESC 
    LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
    );
    $self->{HOSTS_LIST_FROM} = $self->{list};

    $self->query("SELECT INET_NTOA(dst_addr) AS dst_ip, SUM(size) AS size, count(*) AS count
     from $table_name
     $WHERE
     GROUP BY 1
    ORDER BY 2 DESC 
    LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
    );
    $self->{HOSTS_LIST_TO} = $self->{list};
  }
  elsif (defined($attr->{PORTS})) {
    $self->query("SELECT src_port, SUM(size) AS size, count(*) AS count
     FROM  $table_name
     $WHERE
     GROUP BY 1
    ORDER BY 2 DESC 
    LIMIT $PG, $PAGE_ROWS;"
    );
    $self->{PORTS_LIST_FROM} = $self->{list};

    $self->query("SELECT dst_port, SUM(size) AS size, count(*) AS count
     from  $table_name
     $WHERE
     GROUP BY 1
    ORDER BY 2 DESC 
    LIMIT $PG, $PAGE_ROWS;"
    );
    $self->{PORTS_LIST_TO} = $self->{list};
  }
  else {
    $self->query("SELECT   $lupdate,
   SUM(if(src_port=0 && (src_port + dst_port>0), size, 0)),
   SUM(if(dst_port=0 && (src_port + dst_port>0), size, 0)),
   SUM(if(src_port=0 && dst_port=0, size, 0)) AS no_port_size,
   SUM(size) AS size,
   count(*) AS count
   from  $table_name
   $WHERE
   $GROUP
  ORDER BY $SORT $DESC 
  LIMIT $PG, $PAGE_ROWS;
  ;",
  undef, $attr
    );
  }

  $list = $self->{list};

  $self->query("SELECT 
  count(*) AS count,  SUM(size) AS sum
  from  $table_name
  $WHERE;",
  undef,
  { INFO => 1 }
  );
  return $list;
}

#**********************************************************
#
#**********************************************************
sub comps_list {
  my $self = shift;
  #my ($attr) = @_;

  $self->query("SELECT number, name, INET_NTOA(ip), cid, id FROM ipn_club_comps
  ORDER BY $SORT $DESC ;"
  );

  my $list = $self->{list};
  return $list;
}

#**********************************************************
#
#**********************************************************
sub comps_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('ipn_club_comps', $attr);

}

#**********************************************************
#
#**********************************************************
sub comps_info {
  my $self = shift;
  my ($id) = @_;

  $self->query("SELECT 
  number,
  name,
  INET_NTOA(ip) AS ip,
  cid
  FROM ipn_club_comps
  WHERE id='$id';",
  undef,
  { INFO => 1 }
  );

  return $self;
}

#**********************************************************
#
#**********************************************************
sub comps_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'ipn_club_comps',
      DATA         => $attr
    }
  );

  return $self;
}

#**********************************************************
#
#**********************************************************
sub comps_del {
  my $self = shift;
  my ($id) = @_;

  $self->query_del('ipn_club_comps', { ID => $id });

  return $self;
}

#*******************************************************************
# Delete information from user log
# log_del($attr);
#*******************************************************************
sub log_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('ipn_log', undef, { uid       => $attr->{UID},
                                       session_id=> $attr->{SESSION_ID},
                                       });

  return $self;
}

#*******************************************************************
# Delete information from user log
# prepaid_rest($attr);
#*******************************************************************
sub prepaid_rest {
  my $self   = shift;
  my ($attr) = @_;
  my $info   = $attr->{INFO};

  my $octets_direction = "l.traffic_in + l.traffic_out";

  #Recv
  if ($info->[0]->{octets_direction} && $info->[0]->{octets_direction} == 1) {
    $octets_direction = "l.traffic_in";
  }

  #sent
  elsif ($info->[0]->{octets_direction} == 2) {
    $octets_direction = "l.traffic_out";
  }

  $self->query("SELECT l.traffic_class, (SUM($octets_direction)) / $self->{conf}->{MB_SIZE}
   from ipn_log l
   WHERE l.uid='$attr->{UID}' and DATE_FORMAT(start, '%Y-%m-%d')>='$info->[0]->{activate}'
   GROUP BY l.traffic_class, l.uid ;"
  );

  my %traffic = ();
  foreach my $line (@{ $self->{list} }) {
    $traffic{ $line->[0] } = $line->[1];
  }

  $self->{TRAFFIC} = \%traffic;

  return $info;
}

#*******************************************************************
# Delete information from user log
# recalculate($attr);
#*******************************************************************
sub recalculate {
  my $self = shift;
  my ($attr) = @_;

  my ($from, $to) = split(/\//, $attr->{INTERVAL}, 2);

  $self->query("SELECT start,
   traffic_class,
   traffic_in,
   traffic_out,
   nas_id,
   INET_NTOA(ip),
   interval_id,
   sum,
   session_id
   from ipn_log l
   WHERE l.uid='$attr->{UID}' and 
     (
      DATE_FORMAT(start, '%Y-%m-%d')>='$from'
      and DATE_FORMAT(start, '%Y-%m-%d')<='$to'
      )
   ;",
   undef,
   $attr
  );

  return $self;
}

#*******************************************************************
# AMon Alive Check
# online_alive($i);
#*******************************************************************
sub online_alive {
  my $self = shift;
  my ($attr) = @_;

  my $session_id = ($attr->{SESSION_ID}) ? "and acct_session_id='$attr->{SESSION_ID}'" : '';

  $self->query("SELECT CID FROM dv_calls
   WHERE  user_name='$attr->{LOGIN}'
    and framed_ip_address=INET_ATON('$attr->{REMOTE_ADDR}');"
  );

  if ($self->{TOTAL} > 0) {
    my $sql = "UPDATE dv_calls SET  lupdated=UNIX_TIMESTAMP(),
    CONNECT_INFO='$attr->{CONNECT_INFO}',
    status=3
     WHERE user_name = '$attr->{LOGIN}'
    $session_id
    and framed_ip_address=INET_ATON('$attr->{REMOTE_ADDR}')";

    $self->query($sql, 'do');
    $self->{TOTAL} = 1;
  }

  return $self;
}

#*******************************************************************
=head2 ipn_log_rotate($attr) Delete information from detail table and log table

  Arguments:
    $attr
      PERIOD
      DETAIL

  Returns:
    $self     

=cut
#*******************************************************************
sub ipn_log_rotate {
  my $self = shift;
  my ($attr) = @_;

  #yesterday date
  #my $DATE = (strftime("%Y_%m_%d", localtime(time - 86400)));
  #my ($Y, $M, $D) = split(/_/, $DATE);

  $DATE =~ s/\-/\_/g;

  my @rq      = ();
  my $version = $self->db_version();
  $attr->{PERIOD} = 30 if (! $attr->{PERIOD});
  #Detail Daily rotate
  if ($attr->{DETAIL}) {
    $self->query("SELECT count(*) FROM ipn_traf_detail;", undef, { DB_REF => $self->{db2} });

    if ($self->{list}->[0]->[0] > 0) {
      $self->query("SHOW TABLES LIKE 'ipn_traf_detail_$DATE';", undef, { DB_REF => $self->{db2} });
      if ($self->{TOTAL} == 0 && $version > 4.1) {
        @rq = ('CREATE TABLE IF NOT EXISTS ipn_traf_detail_new LIKE ipn_traf_detail;', 
               'RENAME TABLE ipn_traf_detail TO ipn_traf_detail_' . $DATE . ', ipn_traf_detail_new TO ipn_traf_detail;', 
               );
      }
      else {
        @rq = ("DELETE FROM ipn_traf_detail WHERE f_time < f_time - INTERVAL 1 DAY;");
      }
    }

    $self->query("SHOW TABLES LIKE 'ipn_traf_detail_%'", undef,  { DB_REF => $self->{db2} });
    foreach my $table_name (@{ $self->{list} }) {
      $table_name->[0] =~ /(\d{4})\_(\d{2})\_(\d{2})$/;
      my ($log_y, $log_m, $log_d) = ($1, $2, $3);
      my $seltime  = POSIX::mktime(0, 0, 0, $log_d, ($log_m - 1), ($log_y - 1900));
      my $cur_time = time;
      if (($cur_time - $seltime) > (86400 * $attr->{PERIOD})) {
        push @rq, "DROP table `$table_name->[0]`;";
      }
    }

    if($self->{db2}) {
      foreach my $query (@rq) {
        $self->query($query, 'do', { DB_REF => $self->{db2} });
      }
      @rq = ();
    }
    
    push @rq, 'TRUNCATE TABLE ipn_unknow_ips;';
  }

  if($attr->{DAILY_LOG}) {
    push @rq, 'DROP TABLE IF EXISTS ipn_log_new;',
    'CREATE TABLE ipn_log_new LIKE ipn_log;',
    'DROP TABLE IF EXISTS ipn_log_backup;',
    'RENAME TABLE ipn_log TO ipn_log_backup, ipn_log_new TO ipn_log;',
    'CREATE TABLE IF NOT EXISTS ipn_log_' . $Y . '_' . $M . '_'. $D .' LIKE ipn_log;',
    'INSERT INTO ipn_log_' . $Y . '_' . $M . '_' . $D ." (
        uid, 
        start,
        stop,
        traffic_class, 
        traffic_in,
        traffic_out,
        nas_id, ip, 
        interval_id, 
        sum, 
        session_id
         )
       SELECT 
        uid, DATE_FORMAT(start, '%Y-%m-%d %H:00:00'), DATE_FORMAT(stop, '%Y-%m-%d %H:00:00'), traffic_class, 
        SUM(traffic_in), SUM(traffic_out),
        nas_id, ip, interval_id, SUM(sum), session_id
        FROM ipn_log_backup
        WHERE DATE_FORMAT(start, '%Y-%m-%d')='$Y-$M-$D'
        GROUP BY 2, traffic_class, ip, session_id;", 
        "INSERT INTO ipn_log (
        uid, 
        start,
        stop,
        traffic_class, 
        traffic_in,
        traffic_out,
        nas_id, ip, 
        interval_id, 
        sum, 
        session_id
         )
       SELECT 
        uid, DATE_FORMAT(start, '%Y-%m-%d 00:00:00'), DATE_FORMAT(stop, '%Y-%m-%d 00:00:00'), traffic_class, 
        SUM(traffic_in), SUM(traffic_out),
        nas_id, ip, interval_id, SUM(sum), session_id
        FROM ipn_log_backup
        WHERE DATE_FORMAT(start, '%Y-%m-%d')>'$Y-$M-$D'
        GROUP BY 2, traffic_class, ip, session_id;";
  }

  #IPN log rotate
  if ($attr->{LOG} && $version > 4.1) {
    push @rq, 'DROP TABLE IF EXISTS ipn_log_new;',
    'CREATE TABLE ipn_log_new LIKE ipn_log;',
    'DROP TABLE IF EXISTS ipn_log_backup;',
    'RENAME TABLE ipn_log TO ipn_log_backup, ipn_log_new TO ipn_log;',
    'CREATE TABLE IF NOT EXISTS ipn_log_' . $Y . '_' . $M . ' LIKE ipn_log;',
    'INSERT INTO ipn_log_' . $Y . '_' . $M . " (
        uid, 
        start,
        stop,
        traffic_class, 
        traffic_in,
        traffic_out,
        nas_id, ip, 
        interval_id, 
        sum, 
        session_id
         )
       SELECT 
        uid, DATE_FORMAT(start, '%Y-%m-%d'), DATE_FORMAT(stop, '%Y-%m-%d'), traffic_class, 
        SUM(traffic_in), SUM(traffic_out),
        nas_id, ip, interval_id, SUM(sum), session_id
        FROM ipn_log_backup
        WHERE DATE_FORMAT(start, '%Y-%m')='$Y-$M'
        GROUP BY 2, traffic_class, ip, session_id;", "INSERT INTO ipn_log (
        uid, 
        start,
        stop,
        traffic_class, 
        traffic_in,
        traffic_out,
        nas_id, ip, 
        interval_id, 
        sum, 
        session_id
         )
       SELECT 
        uid, DATE_FORMAT(start, '%Y-%m-%d'), DATE_FORMAT(stop, '%Y-%m-%d'), traffic_class, 
        SUM(traffic_in), SUM(traffic_out), 
        nas_id, ip, interval_id, SUM(sum), session_id
        FROM ipn_log_backup
        WHERE DATE_FORMAT(start, '%Y-%m')>'$Y-$M'
        GROUP BY 2, traffic_class, ip, session_id;";
  }

  foreach my $query (@rq) {
    $self->query("$query", 'do');
  }

  return $self;
}

#*******************************************************************
=head2 user_detail($attr)

=cut
#*******************************************************************
sub user_detail {
  my $self = shift;
  my ($attr) = @_;
  my $list;

  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;
  #my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 2;
  #my $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';

  my @WHERE_RULES = ();
  my @GROUP_RULES = ();

  if ($attr->{INTERVAL}) {
    my ($from, $to) = split(/\//, $attr->{INTERVAL}, 2);

    #Period
    if ($from) {
      my $s_time = ($from =~ /^\d{4}-\d{2}-\d{2}$/) ? 'DATE_FORMAT(s_time, \'%Y-%m-%d\')' : 's_time';
      push @WHERE_RULES, "$s_time >= '$from'";
      if ($from =~ /(\d{4})-(\d{2})-(\d{2})/) {
        $attr->{START_DATE} = "$1$2$3";
      }
    }

    my $s_time = ($to =~ /^\d{4}-\d{2}-\d{2}$/) ? 'DATE_FORMAT(s_time, \'%Y-%m-%d\')' : 's_time';

    push @WHERE_RULES, "$s_time <= '$to'";
    if ($to =~ /(\d{4})-(\d{2})-(\d{2})/) {
      $attr->{FINISH_DATE} = "$1$2$3";
    }
  }

  #if ($attr->{UID}) {
  #  push @WHERE_RULES, "uid='$attr->{UID}'";
  #}

  if ($attr->{SRC_PORT} eq $attr->{DST_PORT}) {

  }

  if (defined($attr->{SRC_PORT}) && $attr->{SRC_PORT} =~ /^\d+$/) {
    push @WHERE_RULES, "src_port='$attr->{SRC_PORT}'";
  }

  if ($attr->{IP}) {
  	push @WHERE_RULES, "(dst_addr=INET_ATON('$attr->{IP}') OR src_addr=INET_ATON('$attr->{IP}'))";
  }

  if ($attr->{DST_IP}) {
    my @ips_arr = split(/,/, $attr->{DST_IP});
    my @ip_q = ();
    foreach my $ip (sort @ips_arr) {
      if ($ip =~ /(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\/(\d{1,2})/) {
        #my $ip   = $1;
        my $bits = $2;
        my $mask = 0b1111111111111111111111111111111;

        $mask = int(sprintf("%d", $mask >> ($bits - 1)));
        my $last_ip  = ip2int($ip) | $mask;
        my $first_ip = $last_ip - $mask;
        print "IP FROM: " . int2ip($first_ip) . " TO: " . int2ip($last_ip) . "\n" if ($debug > 2);
        push @ip_q, "(
                       (dst_addr>='$first_ip' and dst_addr<='$last_ip' )
                      )";
      }
      elsif ($ip =~ /\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/) {
        push @ip_q, "dst_addr=INET_ATON('$ip')";
      }
    }

    push @WHERE_RULES, '(' . join(' or ', @ip_q) . ')';
  }

  if ($attr->{SRC_IP}) {
    my @ips_arr = split(/,/, $attr->{SRC_IP});
    my @ip_q = ();
    foreach my $ip (sort @ips_arr) {
      if ($ip =~ /(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\/(\d{1,2})/) {
        #my $ip   = $1;
        my $bits = $2;
        my $mask = 0b1111111111111111111111111111111;

        $mask = int(sprintf("%d", $mask >> ($bits - 1)));
        my $last_ip  = ip2int($ip) | $mask;
        my $first_ip = $last_ip - $mask;
        print "IP FROM: " . int2ip($first_ip) . " TO: " . int2ip($last_ip) . "\n" if ($debug > 2);
        push @ip_q, "(
                       (src_addr>='$first_ip' and src_addr<='$last_ip' )
                      )";
      }
      elsif ($ip =~ /\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/) {
        push @ip_q, "src_addr=INET_ATON('$ip')";
      }
    }

    push @WHERE_RULES, '(' . join(' or ', @ip_q) . ')';
  }

  if (defined($attr->{DST_PORT}) && $attr->{DST_PORT} =~ /^\d+$/) {
    push @WHERE_RULES, "dst_port='$attr->{DST_PORT}'";
  }

  if ($attr->{DST_IP_GROUP}) {
    push @GROUP_RULES, 'dst_addr';
  }

  if ($attr->{SRC_IP_GROUP}) {
    push @GROUP_RULES, 'src_addr';
  }

  my $GROUP_BY = '';
  my $size     = 'size';

  my $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

  if ($#GROUP_RULES > -1) {
    $GROUP_BY = "GROUP BY " . join(', ', @GROUP_RULES);
    $size = 'SUM(size)';
  }

  my @tables = ();

  $self->query("SHOW TABLES LIKE 'ipn_traf_detail_%';", undef, { DB_REF => $self->{db2} });
  $list = $self->{list};

  foreach my $line (@$list) {
    my $table = $line->[0];
    if ($table =~ m/ipn_traf_detail_(\d{4})_(\d{2})_(\d{2})/) {
      my $table_date = "$1$2$3";
      if ($table_date >= $attr->{START_DATE} && $table_date <= $attr->{FINISH_DATE}) {
        print $table. "\n" if ($debug > 1);
        push @tables, $table;
      }
    }
  }

  push @tables, 'ipn_traf_detail';
  my @sql_arr = ();
  foreach my $table (@tables) {
    my $date;
    if ($table =~ m/ipn_traf_detail_(\d{4})_(\d{2})_(\d{2})/) {
      $date = "$1-$2-$3";
    }

    push @sql_arr, "SELECT s_time,  f_time,
    INET_NTOA(src_addr) AS src_ip,
    src_port,
    INET_NTOA(dst_addr) AS dst_ip,
    dst_port,
    protocol,
    $size,
    nas_id 
  FROM $table 
    $WHERE
    $GROUP_BY
    ";
  }

  my $sql = join(" UNION ", @sql_arr);
  $self->query("$sql LIMIT $PG,$PAGE_ROWS", undef, { DB_REF => $self->{db2} });
  $list = $self->{list};

  if ($self->{TOTAL} > 0 && $#GROUP_RULES < 0) {
    my $totals = 0;
    foreach my $table (@tables) {
      $self->query("SELECT count(*) AS total from $table $WHERE ;", undef, { INFO => 1, DB_REF => $self->{db2} });
      $totals += $self->{TOTAL};
    }

    $self->{TOTAL} = $totals;
  }

  return $list;
}

#**********************************************************
=head2 unknown_ips_del($attr)

=cut
#**********************************************************
sub unknown_ips_del {
  my $self = shift;

  $self->query('DELETE FROM ipn_unknow_ips;', 'do');

  return $self;
}

#**********************************************************
=head2 unknown_ips_list($attr)

=cut
#**********************************************************
sub unknown_ips_list {
  my $self = shift;
  my ($attr) = @_;
  my $WHERE = '';

  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;
  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 2;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';

  $self->query("SELECT 
   datetime,
   INET_NTOA(src_ip) AS src_ip,
   INET_NTOA(dst_ip) AS dst_ip,
   size,
   nas_id
  FROM ipn_unknow_ips
  $WHERE
  ORDER BY $SORT $DESC 
  LIMIT $PG, $PAGE_ROWS
  ;",
  undef,
  $attr
  );

  my $list = $self->{list};

  $self->query("SELECT count(*) AS total, SUM(size) AS total_traffic FROM ipn_unknow_ips;",
   undef, { INFO => 1 });

  return $list;
}

#**********************************************************
=head2 traffic_by_port_list($attr) - get traffic and ports

  Arguments:
    $attr - hash_ref
      UID
      NAS_ID
      S_TIME
      F_TIME

  Returns:
    list

=cut
#**********************************************************
sub traffic_by_port_list{
  my $self = shift;
  my ($attr) = @_;

  my $WHERE = 'WHERE dst_port<>0 AND ';

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 's_time';
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';

  if ($attr->{UID}){
    $WHERE .= "uid=$attr->{UID} AND";
  }
  elsif ($attr->{NAS_ID}){
    $WHERE .= "nas_id=$attr->{NAS_ID} AND";
  }

  my $datetime_definition = "s_time AS datetime";
  if ($attr->{S_TIME} && $attr->{F_TIME}){
    if ($attr->{S_TIME} == $attr->{F_TIME}){
      $WHERE .= " DATE(s_time)='$attr->{S_TIME}'";
      $datetime_definition = "TIME(s_time) AS datetime";
    }
    else {
      $WHERE .= " s_time>='$attr->{S_TIME} 00:00:00' AND f_time<='$attr->{F_TIME} 23:59:59'";
    }
  }

  if ($attr->{PORTS}){
    if ( $attr->{PORTS} =~ /, /){
      $WHERE .= " AND dst_port IN ($attr->{PORTS})";
    } else {
      $WHERE .= " AND dst_port='$attr->{PORTS}'";
    }
  }


  $self->query("SELECT
   $datetime_definition,
   dst_port,
   SUM(size) AS size,
   nas_id,
   uid
  FROM ipn_traf_detail
  $WHERE
  GROUP BY s_time
  ORDER BY $SORT $DESC ;",
    undef,
      { %$attr, 'COLS_NAME' => 1 }
  );
#
#  my $list = $self->{list};
#
#  $self->query("SELECT count(*) AS total, SUM(size) AS total_traffic FROM ipn_unknow_ips;",
#    undef, { INFO => 1 });

  return $self->{list};
}


1

