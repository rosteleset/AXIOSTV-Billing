package Voip_Sessions;

=head2 NAME

  VOIP Stats functions

=cut

use strict;
our $VERSION = 7.00;
use parent qw(dbcore);

my ($admin, $CONF);

#**********************************************************
# Init
#**********************************************************
sub new{
  my $class = shift;
  my $db = shift;
  ($admin, $CONF) = @_;
  my $self = { };
  bless( $self, $class );

  $self->{db} = $db;
  $self->{admin} = $admin;
  $self->{conf} = $CONF;

  if ( $CONF->{DELETE_USER} ){
    $self->del( $CONF->{DELETE_USER}, '', '', '', { DELETE_USER => $CONF->{DELETE_USER} } );
  }

  return $self;
}

#**********************************************************
# del
#**********************************************************
sub del{
  my $self = shift;
  my ($uid, $session_id, $nas_id, $session_start, $attr) = @_;

  if ( $attr->{DELETE_USER} ){
    $self->query( "DELETE FROM voip_log WHERE uid='$attr->{DELETE_USER}';", 'do' );
  }
  else{
    $self->query( "DELETE FROM voip_log
      WHERE uid='$uid' and start='$session_start' and nas_id='$nas_id' and acct_session_id='$session_id';", 'do'
    );
  }

  return $self;
}

#**********************************************************
=head2 online($attr)

=cut
#**********************************************************
sub online{
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $WHERE = q{};

  if ( defined( $attr->{ZAPED} ) ){
    $WHERE = "c.status=2";
  }
  else{
    $WHERE = "c.status=1 or c.status>=3";
  }

  $self->query( "SELECT c.user_name,
    pi.fio,
    calling_station_id,
    called_station_id,
    SEC_TO_TIME(UNIX_TIMESTAMP() - UNIX_TIMESTAMP(c.started)) AS duration,
    c.call_origin,
    INET_NTOA(c.client_ip_address),
    c.status,
    c.nas_id,
    c.uid,
    c.acct_session_id,
    pi.phone,
    service.tp_id,
    0,
    u.credit,
    if(DATE_FORMAT(c.started, '%Y-%m-%d')=CURDATE(), DATE_FORMAT(c.started, '%H:%i:%s'), c.started)

 FROM voip_calls c
 LEFT JOIN users u  ON (u.uid=c.uid)
 LEFT JOIN voip_main service  ON (service.uid=u.uid)
 LEFT JOIN users_pi pi ON (pi.uid=u.uid)
 WHERE $WHERE
 ORDER BY $SORT $DESC;",
    undef,
    $attr
  );

  if ( $self->{TOTAL} < 1 ){
    return $self;
  }

  my $list = $self->{list};
  my %dub_logins = ();
  my %nas_sorted = ();

  foreach my $line ( @{$list} ){
    $dub_logins{ $line->[0] }++;
    push(
      @{ $nas_sorted{$line->[8]} },
      [
        $line->[0], $line->[1], $line->[2], $line->[3], $line->[4], $line->[5], $line->[6], $line->[7], $line->[8],
        $line->[9], $line->[10], $line->[11],
        $line->[13], $line->[14], $line->[15], $line->[16], $line->[17], $line->[18], $line->[19], $line->[20],
        $line->[21], $line->[22]
      ]
    );
  }

  $self->{dub_logins} = \%dub_logins;
  $self->{nas_sorted} = \%nas_sorted;

  my $_list = $self->{list} || [];

  return $_list;
}

#**********************************************************
# online_del()
#**********************************************************
sub online_del{
  my $self = shift;
  my ($attr) = @_;

  my $WHERE = '';

  if ( $attr->{SESSIONS_LIST} ){
    my $session_list = join( "', '", @{ $attr->{SESSIONS_LIST} } );
    $WHERE = "acct_session_id in ( '$session_list' )";
  }
  else{
    my $NAS_ID = (defined( $attr->{NAS_ID} )) ? $attr->{NAS_ID} : '';
    my $ACCT_SESSION_ID = (defined( $attr->{ACCT_SESSION_ID} )) ? $attr->{ACCT_SESSION_ID} : '';
    $WHERE = "nas_id='$NAS_ID'
            and acct_session_id='$ACCT_SESSION_ID'";
  }

  $self->query( "DELETE FROM voip_calls WHERE $WHERE;", 'do' );

  return $self;
}

#**********************************************************
# Add online session to log
# online2log()
#**********************************************************
sub online_info{
  my $self = shift;
  my ($attr) = @_;

  my $NAS_ID = (defined( $attr->{NAS_ID} )) ? $attr->{NAS_ID} : '';

  #  my $NAS_PORT        = (defined($attr->{NAS_PORT})) ? $attr->{NAS_PORT} : '';
  my $ACCT_SESSION_ID = (defined( $attr->{ACCT_SESSION_ID} )) ? $attr->{ACCT_SESSION_ID} : '';

  $self->query( "SELECT user_name,
    UNIX_TIMESTAMP(started) AS session_start,
    UNIX_TIMESTAMP() - UNIX_TIMESTAMP(started) AS acct_session_time,
    INET_NTOA(client_ip_address) AS client_ip_address,
    lupdated AS last_update,
    nas_id,
    calling_station_id,
    called_station_id,
    acct_session_id,
    conf_id AS h323_conf_id,
    call_origin AS h323_call_origin
    FROM voip_calls
    WHERE nas_id='$NAS_ID'
     and acct_session_id='$ACCT_SESSION_ID'",
    undef,
    { INFO => 1 }
  );

  return $self;
}

#**********************************************************
# Session zap
#**********************************************************
sub zap{
  my $self = shift;
  my ($nas_id, $acct_session_id) = @_;

  my $WHERE = ($nas_id && $acct_session_id) ? "WHERE nas_id=INET_ATON('$nas_id') and acct_session_id='$acct_session_id'" : '';
  $self->query( 'UPDATE voip_calls SET status=2 '. $WHERE .';', 'do' );

  return $self;
}

#**********************************************************
# Session detail
#**********************************************************
sub session_detail{
  my $self = shift;
  my ($attr) = @_;

  my $WHERE = ($attr->{UID}) ? " and l.uid='$attr->{UID}'" : q{};

  $self->query( "SELECT
  l.start,
  l.start + INTERVAL l.duration SECOND AS stop,
  l.duration,
  l.tp_id,
  tp.name AS tp_name,
  INET_NTOA(client_ip_address) AS ip,
  l.calling_station_id,
  l.called_station_id,
  l.nas_id,
  n.name,
  n.ip AS nas_ip,
  l.bill_id,
  u.id AS login,
  l.uid,
  l.acct_session_id,
  l.route_id,
  l.terminate_cause,
  l.sum
 FROM (voip_log l, users u)
 LEFT JOIN tarif_plans tp ON (l.tp_id=tp.tp_id)
 LEFT JOIN nas n ON (l.nas_id=n.id)
 WHERE l.uid=u.uid
 $WHERE
 and acct_session_id='$attr->{SESSION_ID}';",
    undef,
    { INFO => 1 }
  );

  return $self;
}

#**********************************************************
# Periods totals
# periods_totals($self, $attr);
#**********************************************************
sub periods_totals{
  my $self = shift;
  my ($attr) = @_;
  my $WHERE = '';

  if ( $attr->{UID} ){
    $WHERE .= ($WHERE ne '') ? " and uid='$attr->{UID}' " : "WHERE uid='$attr->{UID}' ";
  }

  $self->query( "SELECT
   SEC_TO_TIME(sum(if(DATE_FORMAT(start, '%Y-%m-%d')=curdate(), duration, 0))) AS duration_0,
   sum(if(DATE_FORMAT(start, '%Y-%m-%d')=curdate(), sum, 0)) AS sum_0,
   SEC_TO_TIME(sum(if(TO_DAYS(curdate()) - TO_DAYS(start) = 1, duration, 0))) AS duration_1,
   sum(if(TO_DAYS(curdate()) - TO_DAYS(start) = 1, sum, 0)) AS sum_1,

   SEC_TO_TIME(sum(if((YEAR(curdate())=YEAR(start)) and WEEK(curdate()) = WEEK(start), duration, 0))) AS duration_2,
   sum(if((YEAR(curdate())=YEAR(start)) and WEEK(curdate()) = WEEK(start), sum, 0)) AS sum_2,

   SEC_TO_TIME(sum(if(DATE_FORMAT(start, '%Y-%m')=DATE_FORMAT(curdate(), '%Y-%m'), duration, 0))) AS duration_3,
   sum(if(DATE_FORMAT(start, '%Y-%m')=DATE_FORMAT(curdate(), '%Y-%m'), sum, 0)) AS sum_3,

   SEC_TO_TIME(sum(duration)) AS duration_4,
   sum(sum) AS sum_4

   FROM voip_log $WHERE;"
  );

  ($self->{duration_0}, $self->{sum_0}, $self->{duration_1}, $self->{sum_1}, $self->{duration_2}, $self->{sum_2},
    $self->{duration_3}, $self->{sum_3}, $self->{duration_4}, $self->{sum_4}) = @{ $self->{list}->[0] };

  return $self;
}

#**********************************************************
=head2 list($attr)

=cut
#**********************************************************
sub list{
  my $self = shift;
  my ($attr) = @_;

  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;
  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 2;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  my $WHERE = '';
  my @WHERE_RULES = ("u.uid=l.uid");
  delete $self->{SEARCH_FIELDS};

  #Interval from date to date
  if ( $attr->{INTERVAL} ){
    ($attr->{FROM_DATE}, $attr->{TO_DATE}) = split( /\//, $attr->{INTERVAL}, 2 );
  }
  #Period
  elsif ( defined( $attr->{PERIOD} ) ){
    my $period = $attr->{PERIOD};
    if ( $period == 4 ){ $WHERE .= ''; }
    else{
      $WHERE .= ($WHERE ne '') ? ' AND ' : 'WHERE ';
      if ( $period == 0 ){ push @WHERE_RULES, "DATE_FORMAT(start, '%Y-%m-%d')=CURDATE()"; }
      elsif ( $period == 1 ){ push @WHERE_RULES, "TO_DAYS(CURDATE()) - TO_DAYS(l.start) = 1 "; }
      elsif ( $period == 2 ){ push @WHERE_RULES,
        "YEAR(CURDATE()) = YEAR(l.start) and (WEEK(CURDATE()) = WEEK(start)) "; }
      elsif ( $period == 3 ){ push @WHERE_RULES, "DATE_FORMAT(start, '%Y-%m')=DATE_FORMAT(CURDATE(), '%Y-%m') "; }
      elsif ( $period == 5 ){ push @WHERE_RULES, "DATE_FORMAT(start, '%Y-%m-%d')='$attr->{DATE}' "; }
      else{ $WHERE .= "DATE_FORMAT(start, '%Y-%m-%d')=CURDATE() "; }
    }
  }

  $WHERE = $self->search_former( $attr, [
      [ 'LOGIN',              'STR',    'u.id AS login',                                1 ],
      [ 'START',              'DATE',   'l.start',                                      1 ],
      [ 'DATE',               'DATE',   'l.start',                                      1 ],
      [ 'DURATION',           'DATE',   'SEC_TO_TIME(l.duration) AS duration',          1 ],
      [ 'IP',                 'IP',     'l.client_ip_address', 'INET_NTOA(l.client_ip_address) AS ip', 1 ],
      [ 'CALLING_STATION_ID', 'STR',    'l.calling_station_id',                         1 ],
      [ 'CALLED_STATION_ID',  'STR',    'l.called_station_id',                          1 ],
      [ 'TP_ID',              'INT',    'l.tp_id',                                      1 ],
      [ 'SUM',                'INT',    'l.sum',                                        1 ],
      [ 'NAS_ID',             'INT',    'l.nas_id',                                     1 ],
      [ 'ACCT_SESSION_ID',    'STR',    'l.acct_session_id',                              ],
      [ 'TERMINATE_CAUSE',    'INT',    'l.terminate_cause',                            1 ],
      [ 'BILL_ID',            'STR',    'l.bill_id',                                    1 ],
      [ 'DURATION_SEC',       'INT',    'l.duration AS duration_sec',                   1 ],
      #[ 'DATE',              'DATE',   "DATE_FORMAT(start, '%Y-%m-%d')"                  ],
      [ 'START_UNIXTIME',     'INT',    'UNIX_TIMESTAMP(l.start) AS asstart_unixtime',  1 ],
      [ 'FROM_DATE|TO_DATE',  'DATE',   "DATE_FORMAT(l.start, '%Y-%m-%d')"                ],
      [ 'MONTH',              'DATE',   "DATE_FORMAT(l.start, '%Y-%m')"                   ],
      [ 'CALL_ORIGIN',        'INT',    'l.call_origin',                                1 ],
      [ 'ROUTE_ID',           'INT',    'l.route_id',                                   1 ],
    ],
    {
      WHERE        => 1,
      WHERE_RULES  => \@WHERE_RULES,
      USERS_FIELDS => 1,
      USE_USER_PI  => 1,
    }
  );

  my $EXT_TABLES = '';
  $EXT_TABLES = $self->{EXT_TABLES} if ($self->{EXT_TABLES});

  #  if ($WHERE =~ /pi\./ || $self->{SEARCH_FIELDS} =~ /pi\./) {
  #    $EXT_TABLES  .= 'LEFT JOIN users_pi pi ON (u.uid=pi.uid)';
  #  }

  $self->query( "SELECT $self->{SEARCH_FIELDS} l.acct_session_id, l.uid, l.nas_id, l.route_id, l.call_origin,
    UNIX_TIMESTAMP(DATE_FORMAT(FROM_UNIXTIME(UNIX_TIMESTAMP(l.start)), '%Y-%m-%d')) AS day_begin,
    DAYOFWEEK(FROM_UNIXTIME(UNIX_TIMESTAMP(l.start))) AS day_of_week,
    DAYOFYEAR(FROM_UNIXTIME(UNIX_TIMESTAMP(l.start))) AS day_of_year
  FROM (voip_log l, users u)
  $EXT_TABLES
  $WHERE
  ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  return [] if $self->{errno};
  my $list = $self->{list} || [];

  if ( $self->{TOTAL} > 0 ){
    $self->query( "SELECT COUNT(*) AS total, SEC_TO_TIME(SUM(l.duration)) AS duration, SUM(sum) AS sum
      FROM (voip_log l, users u)
     $WHERE;",
      undef,
      { INFO => 1 }
    );
  }

  return $list;
}

#**********************************************************
=head2 change_sum($attr)

=cut
#**********************************************************
sub change_sum {
  my ($self) = shift;
  my ($attr) = @_;

  if ($attr->{SUM} && $attr->{ACCT_SESSION_ID} && $attr->{UID}) {
    $self->query( "UPDATE voip_log SET sum=? WHERE acct_session_id=? AND uid=?;",
      'do',
      { Bind => [ $attr->{SUM}, $attr->{ACCT_SESSION_ID}, $attr->{UID} ] }
    );
  }

  return $self;
}

#**********************************************************
=head2 calculation($attr) - session calculation

=cut
#**********************************************************
sub calculation{
  my ($self) = shift;
  my ($attr) = @_;

  my $WHERE;

  #Login
  if ( $attr->{UID} ){
    $WHERE .= ($WHERE ne '') ? " and l.uid='$attr->{UID}' " : "WHERE l.uid='$attr->{UID}' ";
  }

  $self->query( "SELECT SEC_TO_TIME(MIN(l.duration)) AS min_dur,
     SEC_TO_TIME(MAX(l.duration)) AS max_dur,
     SEC_TO_TIME(AVG(l.duration)) AS avg_dur,
     MIN(l.sum) AS min_sum,
     MAX(l.sum) AS max_sum,
     AVG(l.sum) AS avg_sum
  FROM voip_log l $WHERE",
    undef,
    { INFO => 1 }
  );

  return $self;
}

#**********************************************************
=head2 reports($attr)

=cut
#**********************************************************
sub reports{
  my ($self) = shift;
  my ($attr) = @_;

  my @WHERE_RULES = ();
  my $date = '';
  my $EXT_TABLES = '';
  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  if ( $attr->{INTERVAL} ){
    my ($from, $to) = split( /\//, $attr->{INTERVAL}, 2 );
    push @WHERE_RULES, "DATE_FORMAT(l.start, '%Y-%m-%d')>='$from' and DATE_FORMAT(l.start, '%Y-%m-%d')<='$to'";
    $attr->{TYPE} = '-' if (!$attr->{TYPE});
    if ( $attr->{TYPE} eq 'HOURS' ){
      $date = "DATE_FORMAT(l.start, '\%H')";
    }
    elsif ( $attr->{TYPE} eq 'DAYS' ){
      $date = "DATE_FORMAT(l.start, '%Y-%m-%d')";
    }
    elsif ( $attr->{TYPE} eq 'TP' ){
      $date = "l.tp_id";
    }
    elsif ( $attr->{TYPE} eq 'TERMINATE_CAUSE' ){
      $date = "l.terminate_cause";
    }
    elsif ( $attr->{TYPE} eq 'GID' ){
      $date = "u.gid";
    }
    elsif ( $attr->{TYPE} eq 'COMPANIES' ){
      $date = "c.name";
      $EXT_TABLES = "INNER JOIN companies c ON (c.id=u.company_id)";
    }
    else{
      $date = "u.id";
    }
  }
  elsif ( defined( $attr->{MONTH} ) ){
    push @WHERE_RULES, "DATE_FORMAT(l.start, '%Y-%m')='$attr->{MONTH}'";
    $date = "DATE_FORMAT(l.start, '%Y-%m-%d')";
  }
  else{
    $date = "DATE_FORMAT(l.start, '%Y-%m')";
  }

  if ( $attr->{TYPE} ){
    if ( $attr->{TYPE} eq 'TYPE' ){
      $date = "u.id AS login";
    }
  }

  # Show groups
  if ( $attr->{GIDS} ){
    push @WHERE_RULES, "u.gid IN ($attr->{GIDS})";
  }
  elsif ( $attr->{GID} ){
    push @WHERE_RULES, "u.gid='$attr->{GID}'";
  }

  if ( $attr->{DATE} ){
    push @WHERE_RULES, "DATE_FORMAT(l.start, '%Y-%m-%d')='$attr->{DATE}'";
  }

  my $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join( ' and ', @WHERE_RULES ) : '';

  if ( $attr->{DATE} ){
    $self->query( "SELECT
      $date,
      IF(u.id is NULL, CONCAT('> ', l.uid, ' <'), u.id), COUNT(l.uid),
      SEC_TO_TIME(SUM(l.duration)) AS duration_time,
      SUM(l.sum),
      l.uid,
      SUM(l.duration) AS duration
    FROM voip_log l
    LEFT JOIN users u ON (u.uid=l.uid)
    $WHERE
    GROUP BY l.uid
    ORDER BY $SORT $DESC",
    undef,
    $attr
    );
  }
  else{
    $self->query( "SELECT $date, COUNT(DISTINCT l.uid),
      COUNT(l.uid),
      SEC_TO_TIME(SUM(l.duration)) AS duration_time,
      SUM(l.sum) AS sum,
      u.uid,
      SUM(l.duration) AS duration
       FROM voip_log l
       LEFT JOIN users u ON (u.uid=l.uid)
       $WHERE
       GROUP BY 1 
       ORDER BY $SORT $DESC;",
      undef,
      $attr
    );
  }

  my $list = $self->{list} || [];

  $self->{USERS} = 0;
  $self->{SESSIONS} = 0;
  $self->{DURATION} = 0;
  $self->{SUM} = 0;

  return $list if ($self->{TOTAL} < 1);

  $self->query( "select COUNT(DISTINCT l.uid) AS distinct_count,
      COUNT(l.uid) AS session_count,
      SUM(l.duration) AS duration,
      SUM(l.sum) AS sum
       FROM voip_log l
       LEFT JOIN users u ON (u.uid=l.uid)
       $WHERE;"
  );

  my $a_ref = $self->{list}->[0] || [];

  ($self->{USERS}, $self->{SESSIONS}, $self->{DURATION}, $self->{SUM}) = @{$a_ref};

  return $list;
}

1;
