package Internet::Ipoe;

=head1 NAME

  Internet IPoE module managment functions

=cut

use strict;
use parent qw( dbcore );
use Tariffs;
use Users;
use Fees;
use POSIX qw(strftime mktime);
use AXbills::Base qw(ip2int int2ip);

our $VERSION = 1.00;
my $MODULE = 'Internet_ipoe';

my ($admin, $CONF);

#my $SORT      = 1;
#my $DESC      = '';
#my $PG        = 0;
#my $PAGE_ROWS = 25;

#**********************************************************
# Init
#**********************************************************
sub new {
  my $class = shift;
  my $db    = shift;
  ($admin, $CONF) = @_;

  $admin->{MODULE} = $MODULE;

  $CONF->{BUILD_DELIMITER} = ', ' if (!defined($CONF->{BUILD_DELIMITER}));

  my $self = {
    db          => $db,
    admin       => $admin,
    conf        => $CONF,
    module_name => $MODULE,
  };

  bless($self, $class);

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

  return $self;
}

#*******************************************************************
=head2 online_alive($attr) -  Alive Check

  Arguments:
    $attr

  online_alive($i);

=cut
#*******************************************************************
sub online_alive {
  my $self = shift;
  my ($attr) = @_;

  my $session_id = ($attr->{SESSION_ID}) ? "AND acct_session_id='$attr->{SESSION_ID}'" : '';

  $self->query("SELECT cid FROM internet_online
   WHERE  user_name='$attr->{LOGIN}'
    AND framed_ip_address=INET_ATON('$attr->{REMOTE_ADDR}');"
  );

  if ($self->{TOTAL} > 0) {
    my $sql = "UPDATE internet_online SET  lupdated=UNIX_TIMESTAMP(),
    CONNECT_INFO='$attr->{CONNECT_INFO}',
    status=3
     WHERE user_name = '$attr->{LOGIN}'
    $session_id
    AND framed_ip_address=INET_ATON('$attr->{REMOTE_ADDR}')";

    $self->query($sql, 'do');
    $self->{TOTAL} = 1;
  }

  return $self;
}

#**********************************************************
=head1 user_status($DATA)



=cut
#**********************************************************
#@deprecated
# Use internet sessions online
sub user_status {
  my $self = shift;
  my ($DATA) = @_;

  my $SESSION_START = 'now()';
  my $sql  = '';

  my $nas_id = $DATA->{NAS_ID_SWITCH} || $DATA->{NAS_ID} || 0;

  #Get active session
  $self->query("SELECT framed_ip_address FROM internet_online WHERE
    user_name='$DATA->{USER_NAME}'
    AND acct_session_id='IP'
    AND nas_id='$nas_id' LIMIT 1;");

  if ($self->{TOTAL} > 0) {
    $sql = "UPDATE internet_online SET
      status='$DATA->{ACCT_STATUS_TYPE}',
      started=$SESSION_START,
      lupdated=UNIX_TIMESTAMP(),
      nas_port_id='$DATA->{NAS_PORT}',
      acct_session_id='$DATA->{ACCT_SESSION_ID}',
      framed_ip_address=INET_ATON('$DATA->{FRAMED_IP_ADDRESS}'),
      cid='$DATA->{CALLING_STATION_ID}',
      connect_info='$DATA->{CONNECT_INFO}'
    WHERE user_name='$DATA->{USER_NAME}'
      AND acct_session_id='IP'
      AND nas_id='$nas_id' LIMIT 1;";
    $self->query("$sql", 'do');
  }
  else {
    $self->query_add('internet_online', {
      %$DATA,
      STATUS          => $DATA->{ACCT_STATUS_TYPE} || 1,
      STARTED         => $SESSION_START,
      LUPDATED        => 'UNIX_TIMESTAMP()',
      NAS_PORT_ID     => $DATA->{NAS_PORT},
      FRAMED_IP_ADDRESS=>"INET_ATON('$DATA->{FRAMED_IP_ADDRESS}')",
      CID             => $DATA->{CALLING_STATION_ID},
      SERVICE_ID      => $DATA->{SERVICE_ID},
      NAS_ID          => $nas_id,
    });
  }

  return $self;
}

#*******************************************************************
=head2 log_rotate($attr) Delete information from detail table and log table

  Arguments:
    $attr
      PERIOD
      DETAIL
      LOG
      LOG_KEEP_PERIOD - LOg keep period (default 1 month)

  Returns:
    $self

=cut
#*******************************************************************
sub log_rotate {
  my $self = shift;
  my ($attr) = @_;

  #yesterday date
  my $DATE = (strftime("%Y_%m_%d", localtime(time - 86400)));
  #my $DATE = POSIX::strftime("%Y_%m_%d", localtime(time));
  my ($Y, $M, undef) = split(/_/, $DATE);

  my @rq      = ();
  my $version = $self->db_version();
  $attr->{PERIOD} = 30 if (! $attr->{PERIOD});
  #Detail Daily rotate
  if ($attr->{DETAIL}) {
    $self->query("SELECT COUNT(*) FROM ipn_traf_detail;", undef, { DB_REF => $self->{db2} });

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

# if($attr->{DAILY_LOG}) {
#  push @rq, 'DROP TABLE IF EXISTS ipn_log_new;',
#      'CREATE TABLE ipn_log_new LIKE ipn_log;',
#      'DROP TABLE IF EXISTS ipn_log_backup;',
#      'RENAME TABLE ipn_log TO ipn_log_backup, ipn_log_new TO ipn_log;',
#      'CREATE TABLE IF NOT EXISTS ipn_log_' . $Y . '_' . $M . '_'. $D .' LIKE ipn_log;',
#      'INSERT INTO ipn_log_' . $Y . '_' . $M . '_' . $D ." (
#        uid,
#        start,
#        stop,
#        traffic_class,
#        traffic_in,
#        traffic_out,
#        nas_id, ip,
#        interval_id,
#        sum,
#        session_id
#         )
#       SELECT
#        uid, DATE_FORMAT(start, '%Y-%m-%d %H:00:00'), DATE_FORMAT(stop, '%Y-%m-%d %H:00:00'), traffic_class,
#        SUM(traffic_in), SUM(traffic_out),
#        nas_id, ip, interval_id, SUM(sum), session_id
#        FROM ipn_log_backup
#        WHERE DATE_FORMAT(start, '%Y-%m-%d')='$Y-$M-$D'
#        GROUP BY 2, traffic_class, ip, session_id;",
#      "INSERT INTO ipn_log (
#      uid,
#      start,
#      stop,
#      traffic_class,
#      traffic_in,
#      traffic_out,
#      nas_id, ip,
#      interval_id,
#      sum,
#      session_id
#       )
#     SELECT
#      uid, DATE_FORMAT(start, '%Y-%m-%d 00:00:00'), DATE_FORMAT(stop, '%Y-%m-%d 00:00:00'), traffic_class,
#      SUM(traffic_in), SUM(traffic_out),
#      nas_id, ip, interval_id, SUM(sum), session_id
#      FROM ipn_log_backup
#      WHERE DATE_FORMAT(start, '%Y-%m-%d')>'$Y-$M-$D'
#      GROUP BY 2, traffic_class, ip, session_id;";
#   }

  if($attr->{LOG_KEEP_PERIOD}) {
    my $log_period = $attr->{LOG_KEEP_PERIOD} || 1;
    if($log_period > 1) {
      $M-=$log_period;
      while ($M < 0) {
        $M=$M+12;
        $Y--;
      }
    }
  }

  $M = sprintf("%02d", $M);
  if ($attr->{LOG}) {
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
        WHERE DATE_FORMAT(start, '%Y-%m')<='$Y-$M'
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
        uid,
        if(CURDATE() < '$Y-$M-01', DATE_FORMAT(start, '%Y-%m-%d %H'), start) ,
        DATE_FORMAT(stop, '%Y-%m-%d'),
        traffic_class,
        SUM(traffic_in), SUM(traffic_out),
        nas_id, ip, interval_id, SUM(sum), session_id
        FROM ipn_log_backup
        WHERE DATE_FORMAT(start, '%Y-%m')>='$Y-$M'
        GROUP BY 2, traffic_class, ip, session_id;";
  }

  foreach my $query (@rq) {
    $self->query($query, 'do');
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

  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;
  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 2;
  my $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  my $debug     = $attr->{DEBUG} || 0;

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
  $self->query("$sql ORDER BY $SORT $DESC LIMIT $PG,$PAGE_ROWS", undef, { DB_REF => $self->{db2} });
  $list = $self->{list};

  if ($self->{TOTAL} > 0 && $#GROUP_RULES < 0) {
    my $totals = 0;
    foreach my $table (@tables) {
      $self->query("SELECT COUNT(*) AS total from $table $WHERE ;", undef, { INFO => 1, DB_REF => $self->{db2} });
      $totals += $self->{TOTAL};
    }

    $self->{TOTAL} = $totals;
  }

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

  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 's_time';
  my $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';

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

  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;
  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 2;
  my $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';

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

  $self->query("SELECT COUNT(*) AS total, SUM(size) AS total_traffic FROM ipn_unknow_ips;",
    undef, { INFO => 1 });

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

  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 2;
  my $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';

  my $debug = 0;

  $self->query("SET SQL_BIG_SELECTS=1;", 'do');

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
      ['HOUR',              'DATE',  "DATE_FORMAT(l.start, '%Y-%m-%d %H')" ],
      #['HOURS',             'DATE',  "DATE_FORMAT(l.start, '%Y-%m-%d')"  ],
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
      $date = "DATE_FORMAT(l.start, '\%H') AS hours, COUNT(DISTINCT l.uid) AS users_count";
    }
    elsif ($attr->{TYPE} eq 'DAYS_TCLASS') {
      $date  = "DATE_FORMAT(l.start, '%Y-%m-%d') AS start, '-', l.traffic_class, tt.descr";
      $EXT_TABLE_JOINS_HASH{traffic_tarifs}=1;
      $GROUP = '1,3';
    }
    elsif ($attr->{TYPE} eq 'DAYS') {
      $date = "DATE_FORMAT(l.start, '%Y-%m-%d') AS start, COUNT(DISTINCT l.uid) AS users_count";
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
    $EXT_TABLE_JOINS_HASH{traffic_tarifs}=1;
  }
  elsif ($attr->{DATE}) {
    #push @WHERE_RULES, "DATE_FORMAT(start, '%Y-%m-%d')='$attr->{DATE}'";
    if ($attr->{HOURS}) {
      $GROUP = "1, 3";
      $date  = "DATE_FORMAT(start, '%Y-%m-%d %H') AS hours, COUNT(DISTINCT l.uid) AS users_count, l.traffic_class, tt.descr ";
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
    $date = "DATE_FORMAT(l.start, '%Y-%m') AS month, COUNT(DISTINCT l.uid) AS users_count, ";
  }

  if ($self->{SEARCH_FIELDS}=~/u\.|pi\./ || $WHERE =~ / u\./) {
    $EXT_TABLE_JOINS_HASH{users}=1;
  }

  my $EXT_TABLES = $self->mk_ext_tables({
    JOIN_TABLES     => \%EXT_TABLE_JOINS_HASH,
    EXTRA_PRE_JOIN  => [
      'users:LEFT JOIN users u ON (l.uid=u.uid)',
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
  FROM  %TABLE% l
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


#*******************************************************************
=head2  prepaid_rest($attr);

=cut
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
=head2 recalculate($attr); - Delete information from user log

=cut
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

#**********************************************************
=head2 traffic_add_log($attr)

=cut
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
=head2 traffic_add_log()$attr;

=cut
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

1

