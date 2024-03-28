package Dv_Sessions;

=head1 NAME

  Dv Stats functions
    time
    traffic

=cut

use strict;
our $VERSION = 2.00;
use parent qw( dbcore );

my $SORT      = 1;
my $DESC      = '';
my $PG        = 0;
my $PAGE_ROWS = 25;
my ($admin, $CONF);

#**********************************************************
# Init
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

  if ($CONF->{DELETE_USER}) {
    $self->del($CONF->{DELETE_USER}, '', '', '', { DELETE_USER => $CONF->{DELETE_USER} });
  }

  return $self;
}

#**********************************************************
=head2 del($uid, $session_id, $nas_id, $session_start, $attr) - Del user statistic

=cut
#**********************************************************
sub del {
  my $self = shift;
  my ($uid, $session_id, $nas_id, $session_start, $attr) = @_;

  if ($attr->{DELETE_USER}) {
    $self->query_del('dv_log', undef, { uid => $attr->{DELETE_USER} });
  }
  else {
    $self->query("SHOW TABLES LIKE 'traffic_prepaid_sum';");

    if ($self->{TOTAL} > 0) {
      $self->query(
         "UPDATE traffic_prepaid_sum pl, dv_log l SET
           traffic_in=traffic_in-(l.recv + 4294967296 * acct_input_gigawords),
           traffic_out=traffic_out-(l.sent + 4294967296 * acct_output_gigawords)
         WHERE pl.uid=l.uid
           AND l.uid='$uid'
           AND l.start='$session_start'
           AND l.nas_id='$nas_id'
           AND l.acct_session_id='$session_id';", 'do'
      );
    }

    #update log_intervals old way
#    $self->query(
#         "UPDATE dv_log_intervals li, dv_log l SET
#           li.recv=li.recv-(l.recv + 4294967296 * l.acct_input_gigawords),
#           li.sent=li.sent-(l.sent + 4294967296 * l.acct_output_gigawords),
#           li.sum=li.sum-l.sum
#         WHERE li.uid=l.uid
#           AND li.acct_session_id=l.acct_session_id
#           AND l.uid='$uid'
#           AND l.acct_session_id='$session_id';", 'do'
#    );
    $self->query_del('dv_log_intervals', undef, {
      uid            => $uid,
      acct_session_id=> $session_id
    });

    $self->query_del('dv_log', undef, {
      uid             => $uid,
      start           => $session_start,
      nas_id          => $nas_id,
      acct_session_id => $session_id || '-'
    });
  }

  return $self;
}

#**********************************************************
=head2 online_update($attr) - Update online sessions

=cut
#**********************************************************
sub online_update {
  my $self      = shift;
  my ($attr)    = @_;
  my @SET_RULES = ();

  push @SET_RULES, 'lupdated=UNIX_TIMESTAMP()' if (defined($attr->{STATUS}) && $attr->{STATUS} == 5);

  if (defined($attr->{in})) {
    push @SET_RULES, "acct_input_octets='$attr->{in}'";
  }
  if (defined($attr->{out})) {
    push @SET_RULES, "acct_output_octets='$attr->{out}'";
  }

  if (defined($attr->{STATUS})) {
    push @SET_RULES, "status='$attr->{STATUS}'";
  }

  if ($attr->{FRAMED_IP_ADDRESS}) {
    push @SET_RULES, "framed_ip_address=$attr->{FRAMED_IP_ADDRESS}";
  }

  if ($attr->{ACCT_INPUT_OCTETS}) {
    push @SET_RULES, "acct_input_octets='$attr->{ACCT_INPUT_OCTETS}'";
  }

  if ($attr->{ACCT_OUTPUT_OCTETS}) {
    push @SET_RULES, "acct_output_octets='$attr->{ACCT_OUTPUT_OCTETS}'";
  }

  push @SET_RULES, "lupdated=UNIX_TIMESTAMP()";

  my $SET = ($#SET_RULES > -1) ? join(', ', @SET_RULES) : '';

  $self->query("UPDATE dv_calls SET $SET
   WHERE
     user_name= ? AND acct_session_id= ?; ", 'do',
    { Bind => [
       $attr->{USER_NAME},
       $attr->{ACCT_SESSION_ID} ]
    }
  );

  return $self;
}

#**********************************************************
=head2 online_count($attr) - Count online sessions

=cut
#**********************************************************
sub online_count {
  my $self = shift;
  my ($attr) = @_;

  #my $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  #my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;

  my $EXT_TABLE   = '';
  my @WHERE_RULES = ();

  if($attr->{DOMAIN_ID}) {
    @WHERE_RULES = ("u.domain_id='$attr->{DOMAIN_ID}'");
  }

  my $WHERE = $self->search_former($attr, [ ],
    {
      USERS_FIELDS  => 1,
      WHERE_RULES   => \@WHERE_RULES,
      WHERE         => 1
    }
  );

  if ($WHERE =~ /u\./) {
    $EXT_TABLE = ' INNER JOIN users u ON (c.uid=u.uid)';
  }

  $self->query("SELECT n.id AS nas_id,
   n.name AS nas_name, INET_NTOA(n.ip) AS nas_ip, n.nas_type,
   SUM(if (c.status=1 or c.status>=3, 1, 0)) AS nas_total_sessions,
   COUNT(distinct c.uid) AS nas_total_users,
   SUM(if (c.status=2, 1, 0)) AS nas_zaped,
   SUM(if (c.status>3 AND c.status<>6, 1, 0)) AS nas_error_sessions,
   SUM(if (c.guest=1, 1, 0)) AS guest
 FROM dv_calls c
 INNER JOIN nas n ON (c.nas_id=n.id)
 $EXT_TABLE
 $WHERE
 GROUP BY c.nas_id
 ORDER BY $SORT $DESC;",
 undef,
 $attr
  );

  my $list = $self->{list};
  $self->{ONLINE}=0;
  if ($self->{TOTAL} > 0) {
    $WHERE = ($WHERE) ? "$WHERE AND c.status<11" : " WHERE c.status<11";

    $self->query(
      "SELECT 1, COUNT(c.uid) AS total_users,
      SUM(if (c.status=1 or c.status>=3, 1, 0)) AS online,
      SUM(if (c.status=2, 1, 0)) AS zaped
   FROM dv_calls c
   $EXT_TABLE
   $WHERE
   GROUP BY 1;",
   undef,
   { INFO => 1 }
    );
   $self->{TOTAL} = $self->{TOTAL_USERS};
  }

  return $list;
}

#**********************************************************
=head2 online_add($attr) - Add online session

=cut
#**********************************************************
sub online_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('dv_calls', { %$attr }, { REPLACE => $attr->{REPLACE_RECORDS} });

  return $self;
}


#**********************************************************
=head2 online($attr) - Make online (active sessions) list

  Arguments:
    $attr
      COUNT        - Count sessions
      ZAPPED       - Show zapped count
      STATUS_COUNT - Show status count
      STATUS       - Show sessions with status
      NAS_ERROR_SESSIONS - Show NAS error sessions
      FILTER       - Filter fields
      ALL          - SHow all sessions

  Result:
    hash_ref_array
    OBJECT
      dub_ports    - Duplicate ports
      dub_logins   - Duplicate logins
      dub_ips      - Duplicate ips
      nas_sorted   - NAS sorted hash_ref_array

=cut
#**********************************************************
sub online {
  my $self = shift;
  my ($attr) = @_;

  my $EXT_TABLE = '';
  $admin->{DOMAIN_ID} = 0 if (!$admin->{DOMAIN_ID});
  my $WHERE     = '';

  if ($attr->{COUNT}) {
    if ($attr->{ZAPED}) {
      $WHERE = 'WHERE c.status=2';
    }
    else {
      $WHERE = 'WHERE ((c.status=1 OR c.status>=3) AND c.status<11)';
    }

    $self->query("SELECT COUNT(*) AS total FROM dv_calls c $WHERE;", undef, { INFO => 1 });
    return $self;
  }
  elsif ($attr->{STATUS_COUNT}) {
    $self->query("SELECT SUM(IF ((c.status=1 OR c.status>=3) AND c.status<11, 1, 0)) AS online_count,
      SUM(IF (status=2, 1, 0)) AS zapped_count,
      SUM(IF (status=6, 1, 0)) AS reconnect_count,
      SUM(IF (status=9, 1, 0)) AS recover_count
    FROM dv_calls c $WHERE;", undef, { INFO => 1  });

    return $self;
  }

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  my @WHERE_RULES = ();

  if ($attr->{ZAPED}) {
    push @WHERE_RULES, "c.status=2";
  }
  elsif($attr->{NAS_ERROR_SESSIONS}) {
    push @WHERE_RULES, "(c.status>3 AND c.status<>6)";
  }
  elsif ($attr->{ALL} || $attr->{STATUS}) {
  }
  else {
    push @WHERE_RULES, "((c.status=1 OR c.status>=3) AND c.status<11)";
  }

  if ($attr->{FILTER}) {
    $attr->{$attr->{FILTER_FIELD}} = $attr->{FILTER};
  }

  $attr->{SKIP_DEL_CHECK}=1;
  $attr->{SORT_SHIFT}=1;
  $WHERE = $self->search_former($attr, [
      ['LOGIN',             'STR', 'IF(c.uid>0, u.id, c.user_name) AS login',      1 ],
      ['USER_NAME',         'STR', 'c.user_name',                                  1 ],
      ['DURATION',          'INT', 'SEC_TO_TIME(UNIX_TIMESTAMP() - UNIX_TIMESTAMP(c.started))', 'SEC_TO_TIME(UNIX_TIMESTAMP() - UNIX_TIMESTAMP(c.started)) AS duration', 1 ],
      ['DURATION_SEC',      'INT', 'IF(c.lupdated>UNIX_TIMESTAMP(c.started), c.lupdated - UNIX_TIMESTAMP(c.started), 0) AS duration_sec',        1 ],
      ['DURATION_SEC2',     'INT', 'UNIX_TIMESTAMP() - UNIX_TIMESTAMP(c.started) AS duration_sec2', 1 ],
      ['NAS_PORT_ID',       'INT', 'c.nas_port_id',                                1 ],
      ['CLIENT_IP_NUM',     'INT', 'c.framed_ip_address',    'c.framed_ip_address AS client_ip_num' ],
      ['CLIENT_IP',         'IP',  'c.framed_ip_address',   'INET_NTOA(c.framed_ip_address) AS client_ip',  1 ],
      ['ACCT_INPUT_OCTETS', 'INT', 'c.acct_input_octets + 4294967296 * acct_input_gigawords AS acct_input_octets',    1 ],
      ['ACCT_OUTPUT_OCTETS','INT', 'c.acct_output_octets + 4294967296 * acct_output_gigawords AS acct_output_octets', 1 ],
      ['EX_INPUT_OCTETS',   'INT', 'c.ex_input_octets',                            1 ],
      ['EX_OUTPUT_OCTETS',  'INT', 'c.ex_output_octets',                           1 ],
      ['CID',               'STR', 'c.CID',                                        1 ],
      ['TP_NAME',           'STR', 'tp.name AS tp_name',                           1 ],
      ['STARTED',           'DATE', 'IF(DATE_FORMAT(c.started, "%Y-%m-%d")=CURDATE(), DATE_FORMAT(c.started, "%H:%i:%s"), c.started) AS started', 1],
      ['NETMASK',           'IP',  'service.netmask',        'INET_NTOA(service.netmask) AS netmask'],
      ['CONNECT_INFO',      'STR', 'c.CONNECT_INFO',                               1 ],
      ['SPEED',             'INT', 'service.speed',                                1 ],
      ['SESSION_SUM',       'INT', 'c.sum AS session_sum',                         1 ],
      ['CALLS_TP_ID',       'INT', 'c.tp_id AS calls_tp_id',                       1 ],
      ['STATUS',            'INT', 'c.status',                                     1 ],
      ['TP_ID',             'INT', 'service.tp_id',                                1 ],
      ['SERVICE_CID',       'STR', 'service.cid',                                  1 ],
      ['GUEST',             'INT', 'c.guest',                                      1 ],
      ['TURBO_MODE',        'INT', 'c.turbo_mode',                                 1 ],
      ['JOIN_SERVICE',      'INT', 'c.join_service',                               1 ],
      ['NAS_IP',            'IP',  'c.nas_ip_address',  'c.nas_ip_address AS nas_ip' ],
      ['ACCT_SESSION_TIME', 'INT', 'UNIX_TIMESTAMP() - UNIX_TIMESTAMP(c.started) AS acct_session_time',1 ],
      ['FILTER_ID',         'STR', 'IF(service.filter_id<>\'\', service.filter_id, tp.filter_id) AS filter_id',  1 ],
      ['SESSION_START',     'INT', 'UNIX_TIMESTAMP(started) AS started_unixtime',  1 ],
      ['SERVICE_STATUS',    'INT', 'service.disable AS service_status',            1 ],
      ['TP_BILLS_PRIORITY', 'INT', 'tp.bills_priority',                            1 ],
      ['TP_CREDIT',         'INT', 'tp.credit',             'tp.credit AS tp_credit' ],
      ['TP_MONTH_FEE',      'INT', 'tp.month_fee',    'tp.month_fee AS tp_month_fee' ],
      ['TP_DAY_FEE',        'INT', 'tp.day_fee',          'tp.day_fee AS tp_day_fee' ],
      ['TP_ABON_DISTRIBUTION', 'INT', 'tp.abon_distribution',   'tp.abon_distribution AS tp_abon_distribution' ],
      ['NAS_NAME',          'STR', 'nas.name AS nas_name',                         1 ],
      ['PAYMENT_METHOD',    'INT', 'tp.payment_type',                              1 ],
      ['TP_CREDIT_TRESSHOLD','INT','tp.credit_tresshold',                          1 ],
      ['ACTIVATE',          'DATE','u.activate',                                   1 ],
      ['EXPIRED',           'DATE',"IF(u.expire>'0000-00-00' AND u.expire <= CURDATE(), 1, 0) AS expired", 1 ],
      ['EXPIRE',            'DATE','u.expire',                                     1 ],
      ['DV_EXPIRED',        'DATE',"IF(service.expire>'0000-00-00' AND service.expire <= CURDATE(), 1, 0) AS dv_expired", 1 ],
      ['DV_EXPIRE',         'DATE','service.expire AS dv_expire',                  1 ],
      ['IP',                'IP',  'service.ip',          'INET_NTOA(service.ip) AS ip' ],
      # Duplicate ['NETMASK',           'IP',  'service.netmask',     'INET_NTOA(service.netmask) AS netmask' ],
      ['SIMULTANEONSLY',    'INT', 'service.logins',                              1 ],
      ['PORT',              'INT', 'service.port',                                1 ],
      #['SERVICE_FILTER_ID', 'STR', 'service.filter_id',                           1 ],
      ['DV_STATUS',         'INT', 'service.disable AS dv_status',                1 ],
      ['FRAMED_IP_ADDRESS', 'IP',  'c.framed_ip_address',                         1 ],
      ['NAS_ID',            'INT', 'c.nas_id',                                    1 ],
      ['ACCT_SESSION_ID',   'STR', 'c.acct_session_id',                           1 ],
      ['UID',               'INT', 'c.uid'                                          ],
      ['LAST_ALIVE',        'INT', 'UNIX_TIMESTAMP() - c.lupdated AS last_alive', 1 ],
      ['ONLINE_BASE',       '',    '', 'c.CID, c.acct_session_id, UNIX_TIMESTAMP() - c.lupdated AS last_alive, c.uid' ],
      ['SHOW_TP_ID',        'INT', 'tp.tp_id', 'tp.tp_id AS real_tp_id' ]
    ],
    { WHERE             => 1,
      WHERE_RULES       => \@WHERE_RULES,
      USERS_FIELDS      => 1,
      SKIP_USERS_FIELDS => [ 'UID', 'LOGIN' ],
      USE_USER_PI       => 1
    }
  );

  foreach my $field ( keys %$attr ) {
    if (! $field) {
      print "dv_calls/online: Wrong field name\n";
    }
    elsif ($field =~ /TP_BILLS_PRIORITY|TP_NAME|FILTER_ID|TP_CREDIT|PAYMENT_METHOD|SHOW_TP_ID/ && $EXT_TABLE !~ /tarif_plans/) {
      $EXT_TABLE .= " LEFT JOIN tarif_plans tp ON (tp.id=service.tp_id AND MODULE='Dv' AND tp.domain_id=u.domain_id)";
    }
    elsif ($field =~ /NAS_NAME/ && $EXT_TABLE !~ / nas /) {
      $EXT_TABLE .= " LEFT JOIN nas ON (nas.id=c.nas_id)";
    }
  }

  $EXT_TABLE .= $self->{EXT_TABLES} if ($self->{EXT_TABLES});

  delete $self->{COL_NAMES_ARR};

  my $LIMIT = '';

  if ($attr->{LIMIT} && $attr->{PAGE_ROWS}) {
    $PG = ($attr->{PG}) ? $attr->{PG} : 0;
    $LIMIT = " LIMIT $PG, $attr->{PAGE_ROWS} ";
  }

  if($self->{SORT_BY}) {
    $SORT = $self->{SORT_BY};
  }

  $self->query("SELECT $self->{SEARCH_FIELDS}
    c.uid,c.nas_id,c.acct_session_id,c.user_name
       FROM dv_calls c
       LEFT JOIN users u ON (u.uid=c.uid)
       LEFT JOIN dv_main service ON (service.uid=u.uid)
       $EXT_TABLE
       $WHERE
       ORDER BY $SORT $DESC
       $LIMIT;",
   undef,
   { COLS_NAME => 1 }
  );

  my %dub_logins = ();
  my %dub_ports  = ();
  my %dub_ips    = ();
  my %nas_sorted = ();

  if ($self->{TOTAL} < 1) {
    $self->{dub_ports}  = \%dub_ports;
    $self->{dub_logins} = \%dub_logins;
    $self->{nas_sorted} = \%nas_sorted;
    $self->{dub_ips}    = \%dub_ips;
    return $self->{list};
  }

  my $list = $self->{list};
  foreach my $line (@$list) {
    push @{ $nas_sorted{$line->{nas_id}} }, $line ;
    $dub_logins{ $line->{user_name} }++ if ($line->{user_name});
    $dub_ports{ $line->{nas_id} }{ $line->{nas_port_id} }++ if ($line->{nas_port_id});
    if ($line->{client_ip}
      && ($line->{status}
          && ($line->{status}==1 || ($line->{status}>=3 && $line->{status}<11))
          && $line->{status}!=6) ) {
      $dub_ips{ $line->{nas_id} }{ $line->{client_ip} }++
    }
  }

  $self->{dub_ports}  = \%dub_ports;
  $self->{dub_logins} = \%dub_logins;
  $self->{dub_ips}    = \%dub_ips;
  $self->{nas_sorted} = \%nas_sorted;

  return $self->{list};
}

#**********************************************************
# online_join_services()
#**********************************************************
sub online_join_services {
  my $self = shift;

  $self->query(
    "SELECT  join_service,
   SUM(c.acct_input_octets) + 4294967296 * SUM(acct_input_gigawords),
   SUM(c.acct_output_octets) + 4294967296 * SUM(acct_output_gigawords)
 FROM dv_calls c
 GROUP BY join_service;"
  );

  return $self->{list};
}

#**********************************************************
=head2 online_del() - Del online session

=cut
#**********************************************************
sub online_del {
  my $self = shift;
  my ($attr) = @_;

  my $WHERE = '';

  if ($attr->{SESSIONS_LIST}) {
    my $session_list = join("', '", @{ $attr->{SESSIONS_LIST} });
    $WHERE = "acct_session_id in ( '$session_list' )";

    if ($attr->{QUICK}) {
      $self->query("DELETE FROM dv_calls WHERE $WHERE;", 'do');
      return $self;
    }
  }
  else {
    my $NAS_ID          = (defined($attr->{NAS_ID}))          ? $attr->{NAS_ID}          : '';
    my $NAS_PORT        = (defined($attr->{NAS_PORT}))        ? $attr->{NAS_PORT}        : '';
    my $ACCT_SESSION_ID = (defined($attr->{ACCT_SESSION_ID})) ? $attr->{ACCT_SESSION_ID} : '';
    $WHERE = "nas_id='$NAS_ID'
            AND nas_port_id='$NAS_PORT'
            AND acct_session_id='$ACCT_SESSION_ID'";
  }

  $self->query("SELECT uid, user_name, started, IF(lupdated>0, SEC_TO_TIME(lupdated-UNIX_TIMESTAMP(started)), '00:00:00'), sum FROM dv_calls WHERE $WHERE");
  foreach my $line (@{ $self->{list} }) {
    $admin->action_add("$line->[0]", "START: $line->[2] DURATION: $line->[3] SUM: $line->[4]", { MODULE => 'Dv', TYPE => 13 });
  }

  $self->query("DELETE FROM dv_calls WHERE $WHERE;", 'do');

  return $self;
}

#**********************************************************
=head2 online_info($attr) - Online session information

=cut
#**********************************************************
sub online_info {
  my $self = shift;
  my ($attr) = @_;

  my $WHERE =  $self->search_former($attr, [
      ['NAS_ID',           'INT', 'nas_id'            ],
      ['NAS_IP_ADDRESS',   'IP',  'nas_ip_address'    ],
      ['NAS_PORT',         'INT', 'nas_port_id',      ],
      ['ACCT_SESSION_ID',  'STR', 'acct_session_id'   ],
      ['UID',              'INT', 'c.uid'             ],
      ['FRAMED_IP_ADDRESS','IP',  'framed_ip_address' ]
    ],
    { WHERE => 1,
    }
    );

  $self->query("SELECT c.user_name,
    UNIX_TIMESTAMP(c.started) AS session_start,
    c.acct_session_time,
   c.acct_input_octets,
   c.acct_output_octets,
   c.ex_input_octets,
   c.ex_output_octets,
   c.connect_term_reason,
   INET_NTOA(c.framed_ip_address) AS framed_ip_address,
   c.lupdated as last_update,
   c.nas_port_id as nas_port,
   INET_NTOA(c.nas_ip_address) AS nas_ip_address ,
   c.CID AS calling_station_id,
   c.CONNECT_INFO,
   c.acct_session_id,
   c.nas_id,
   c.started AS acct_session_started,
   c.acct_input_gigawords,
   c.acct_output_gigawords,
   IF(dv.filter_id != '', dv.filter_id, IF(tp.filter_id is null, '', tp.filter_id)) AS filter_id,
   c.uid
   FROM dv_calls c
   LEFT JOIN dv_main dv ON (c.uid=dv.uid)
   LEFT JOIN tarif_plans tp ON (dv.tp_id=tp.id and module='Dv')
   $WHERE",
   undef,
   { INFO => 1 }
  );

  $self->{CID} = $self->{CALLING_STATION_ID};

  return $self;
}

#**********************************************************
=head2 zap($nas_id, $nas_port_id, $acct_session_id, $attr) - Session zap

=cut
#**********************************************************
sub zap {
  my $self = shift;
  my ($nas_id, $nas_port_id, $acct_session_id, $attr) = @_;

  my $WHERE = '';

  if ($attr->{NAS_ID}) {
    $WHERE = "WHERE nas_id='$attr->{NAS_ID}'";
  }
  elsif (!defined($attr->{ALL})) {
    $WHERE = "WHERE nas_id='$nas_id' and nas_port_id='$nas_port_id'";
  }

  if ($acct_session_id) {
    $WHERE .= "and acct_session_id='$acct_session_id'";
  }

  $self->query("UPDATE dv_calls SET status='2' $WHERE;", 'do');
  return $self;
}

#**********************************************************
=head2 session_detail($attr) - Session detail information

=cut
#**********************************************************
sub session_detail {
  my $self = shift;
  my ($attr) = @_;

  my $WHERE = q{};
  $WHERE = " AND l.uid='$attr->{UID}'" if ($attr->{UID});

  $self->query("SELECT
  l.start,
  l.start + INTERVAL l.duration SECOND AS stop,
  l.duration,
  l.tp_id,
  tp.name AS tp_name,
  l.sent + 4294967296 * acct_output_gigawords AS sent,
  l.recv + 4294967296 * acct_input_gigawords AS recv,
  l.recv2 AS sent2,
  l.sent2 AS recv2,
  INET_NTOA(l.ip) AS ip,
  l.CID,
  l.nas_id,
  n.name AS nas_name,
  INET_NTOA(n.ip) AS nas_ip,
  l.port_id AS nas_port,
  l.sum,
  l.bill_id,
  u.id AS login,
  l.uid,
  l.acct_session_id AS session_id,
  l.terminate_cause AS acct_terminate_cause,
  UNIX_TIMESTAMP(l.start) AS start_unixtime,
  tp.tp_id AS tp_num
 FROM (dv_log l, users u)
 LEFT JOIN tarif_plans tp ON (l.tp_id=tp.id AND module='Dv')
 LEFT JOIN nas n ON (l.nas_id=n.id)
 WHERE l.uid=u.uid
   $WHERE
   AND acct_session_id= ? ;",
 undef,
 { INFO => 1,
   Bind => [ $attr->{SESSION_ID} ] }
  );

  return $self;
}

#**********************************************************
=head2 detail_list($attr)

=cut
#**********************************************************
sub detail_list {
  my $self = shift;
  my ($attr) = @_;

  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;
  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 2;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';

  my $lupdate;

  my $WHERE = ($attr->{SESSION_ID}) ? "and acct_session_id='$attr->{SESSION_ID}'" : '';
  my $GROUP;

  if ($attr->{PERIOD} eq 'days') {
    $lupdate = "DATE_FORMAT(FROM_UNIXTIME(last_update), '%Y-%m-%d')";
    $GROUP   = $lupdate;
    $WHERE   = '';
  }
  elsif ($attr->{PERIOD} eq 'hours') {
    $lupdate = "DATE_FORMAT(FROM_UNIXTIME(last_update), '%Y-%m-%d %H')";
    $GROUP   = $lupdate;
    $WHERE   = '';
  }
  elsif ($attr->{PERIOD} eq 'sessions') {
    $WHERE   = '';
    $lupdate = "FROM_UNIXTIME(last_update)";
    $GROUP   = 'acct_session_id';
  }
  else {
    $lupdate = "FROM_UNIXTIME(last_update)";
    $GROUP   = $lupdate;
  }

  $self->query("SELECT $lupdate, acct_session_id, nas_id,
   SUM(sent1), SUM(recv1), SUM(recv2), SUM(sent2), sum
  FROM s_detail
  WHERE uid='$attr->{UID}' $WHERE
  GROUP BY $GROUP
  ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;"
  );

  my $list = $self->{list};

  if ($self->{TOTAL} > 0) {
    $self->query("SELECT COUNT(DISTINCT $lupdate) AS total
      FROM s_detail
     WHERE uid='$attr->{UID}' $WHERE ;",
     undef,
     { INFO => 1 }
    );
  }

  return $list;
}

#**********************************************************
=head2 detail_sum($attr)

=cut
#**********************************************************
sub detail_sum {
  my $self = shift;
  my ($attr) = @_;

  my $interval = 3600;
  if ($attr->{INTERVAL}) {
    $interval = $attr->{INTERVAL};
  }

  $self->query("SELECT ((SELECT  sent1+recv1
  FROM s_detail
  WHERE id='$attr->{LOGIN}' AND last_update>UNIX_TIMESTAMP()-$interval
  ORDER BY last_update DESC
  LIMIT 1 ) - (SELECT  sent1+recv1
  FROM s_detail
  WHERE uid='$attr->{UID}' AND last_update>UNIX_TIMESTAMP()-$interval
  ORDER BY last_update
  LIMIT 1));"
  );

  my $speed = 0;

  if ($self->{TOTAL} > 0) {
    $self->{TOTAL_TRAFFIC} = $self->{list}->[0]->[0] || 0;
    $speed = int($self->{TOTAL_TRAFFIC} / $interval);
  }

  return $speed;
}

#**********************************************************
=head2 periods_totals($attr) - Periods totals

  Arguments:
    $attr
      UID
      UIDS

  Results:
    OBJECT
=cut
#**********************************************************
sub periods_totals {
  my $self   = shift;
  my ($attr) = @_;
  my $WHERE  = '';

  if ($attr->{UIDS}) {
    $WHERE .= "WHERE uid IN ($attr->{UIDS})";
  }
  elsif ($attr->{UID}) {
    $WHERE .= "WHERE uid='$attr->{UID}' ";
  }

  $self->query("SELECT
   SUM(IF(start>=DATE_FORMAT(CURDATE(), '%Y-%m-%d 00:00:00'), sent + 4294967296 * acct_output_gigawords, 0)) AS day_sent,
   SUM(IF(start>=DATE_FORMAT(CURDATE(), '%Y-%m-%d 00:00:00'), recv + 4294967296 * acct_input_gigawords, 0)) AS day_recv,
   SUM(IF(start>=DATE_FORMAT(CURDATE(), '%Y-%m-%d 00:00:00'), duration, 0)) AS day_duration,

   SUM(IF(TO_DAYS(CURDATE()) - TO_DAYS(start) = 1, sent + 4294967296 * acct_output_gigawords, 0)) AS yesterday_sent,
   SUM(IF(TO_DAYS(CURDATE()) - TO_DAYS(start) = 1, recv + 4294967296 * acct_input_gigawords, 0)) AS yesterday_resc,
   SUM(IF(TO_DAYS(CURDATE()) - TO_DAYS(start) = 1, duration, 0)) AS yesterday_duration,

   SUM(IF((YEAR(CURDATE())=YEAR(start)) AND (WEEK(CURDATE()) = WEEK(start)), sent + 4294967296 * acct_output_gigawords, 0)) AS week_sent,
   SUM(IF((YEAR(CURDATE())=YEAR(start)) AND  WEEK(CURDATE()) = WEEK(start), recv + 4294967296 * acct_input_gigawords, 0)) AS week_resc,
   SUM(IF((YEAR(CURDATE())=YEAR(start)) AND  WEEK(CURDATE()) = WEEK(start), duration, 0)) AS week_duration,

   SUM(IF(DATE_FORMAT(start, '%Y-%m')=DATE_FORMAT(CURDATE(), '%Y-%m'), sent + 4294967296 * acct_output_gigawords, 0)) AS month_sent,
   SUM(IF(DATE_FORMAT(start, '%Y-%m')=DATE_FORMAT(CURDATE(), '%Y-%m'), recv + 4294967296 * acct_input_gigawords, 0)) AS month_recv,
   SUM(IF(DATE_FORMAT(start, '%Y-%m')=DATE_FORMAT(CURDATE(), '%Y-%m'), duration, 0)) AS month_duration,

   SUM(sent + 4294967296 * acct_output_gigawords) AS total_sent,
   SUM(recv + 4294967296 * acct_input_gigawords)  AS total_recv,
   SUM(duration)  AS total_duration
   FROM dv_log $WHERE;"
  );

  if ($self->{TOTAL} == 0) {
    return $self;
  }

  ($self->{sent_0}, $self->{recv_0}, $self->{duration_0}, $self->{sent_1}, $self->{recv_1}, $self->{duration_1}, $self->{sent_2}, $self->{recv_2}, $self->{duration_2}, $self->{sent_3}, $self->{recv_3}, $self->{duration_3}, $self->{sent_4}, $self->{recv_4}, $self->{duration_4}) =
  @{ $self->{list}->[0] };

  for (my $i = 0 ; $i < 5 ; $i++) {
    $self->{ 'sum_' . $i } = $self->{ 'sent_' . $i } + $self->{ 'recv_' . $i };
  }

  return $self;
}

#**********************************************************
=head2 prepaid_rest($attr) - Prepaid traffic rest

  Arguments:
    $attr
      UID
      UIDS
      INFO_ONLY - User information
      FROM_DATE - From date
      TO_DATE   - To date
  Returns
    List object

=cut
#**********************************************************
sub prepaid_rest {
  my $self = shift;
  my ($attr) = @_;

  $CONF->{MB_SIZE} = $CONF->{KBYTE_SIZE} * $CONF->{KBYTE_SIZE};
  #Get User TP and intervals
  $self->query("SELECT i.day, tt.id AS traffic_class,
    i.begin AS interval_begin,
    i.end AS interval_end,
    IF(u.activate<>'0000-00-00', u.activate, DATE_FORMAT(CURDATE(), '%Y-%m-01')) AS activate,
    tt.prepaid,
    u.id AS login,
    tp.octets_direction,
    u.uid,
    dv.tp_id,
    tp.name AS tp_name,
    IF (PERIOD_DIFF(DATE_FORMAT(CURDATE(),'%Y%m'),DATE_FORMAT(u.registration, '%Y%m')) < tp.traffic_transfer_period,
      PERIOD_DIFF(DATE_FORMAT(CURDATE(),'%Y%m'),DATE_FORMAT(u.registration, '%Y%m'))+1, tp.traffic_transfer_period) AS traffic_transfert,
    tp.day_traf_limit,
    tp.week_traf_limit,
    tp.month_traf_limit,
    tt.interval_id,
    tt.in_price,
    tt.out_price
  FROM users u
  INNER JOIN dv_main dv ON (u.uid=dv.uid)
  INNER JOIN tarif_plans tp ON (dv.tp_id=tp.id)
  INNER JOIN intervals i ON (tp.tp_id=i.tp_id)
  INNER JOIN trafic_tarifs tt ON (i.id=tt.interval_id)
WHERE
   u.uid= ?
ORDER BY 1,2,3
 ",
 undef,
 { COLS_NAME => 1,
 	 Bind      => [ $attr->{UID} ]
 	 }
  );

  if ($self->{TOTAL} < 1) {
    return 0;
  }

  $self->{INFO_LIST}    = $self->{list};
  #my $login             = $self->{INFO_LIST}->[0]->{login};
  my $traffic_transfert = $self->{INFO_LIST}->[0]->{traffic_transfert};

  my %prepaid_traffic = (
    0 => 0,
    1 => 0
  );

  my %rest_intervals = ();

  my %rest = (
    0 => 0,
    1 => 0
  );

  foreach my $line (@{ $self->{list} }) {
    $prepaid_traffic{ $line->{traffic_class} } = $line->{prepaid};
    $rest{ $line->{traffic_class} }            = $line->{prepaid};
    $rest_intervals{$line->{interval_id}}{$line->{traffic_class}} = $line->{prepaid};
  }

  return 1 if ($attr->{INFO_ONLY});

  my $octets_direction          = "(sent + 4294967296 * acct_output_gigawords) + (recv + 4294967296 * acct_input_gigawords) ";
  my $octets_direction2         = "sent2 + recv2";
  my $octets_online_direction   = "acct_input_octets + acct_output_octets";
  my $octets_online_direction2  = "ex_input_octets + ex_output_octets";
  my $octets_direction_interval = "(li.sent + li.recv)";

  if ($self->{INFO_LIST}->[0]->{octets_direction} == 1) {
    $octets_direction          = "recv + 4294967296 * acct_input_gigawords ";
    $octets_direction2         = "recv2";
    $octets_online_direction   = "acct_input_octets + 4294967296 * acct_input_gigawords";
    $octets_online_direction2  = "ex_input_octets";
    $octets_direction_interval = "li.recv";
  }
  elsif ($self->{INFO_LIST}->[0]->{octets_direction} == 2) {
    $octets_direction          = "sent + 4294967296 * acct_output_gigawords ";
    $octets_direction2         = "sent2";
    $octets_online_direction   = "acct_output_octets + 4294967296 * acct_output_gigawords";
    $octets_online_direction2  = "ex_output_octets";
    $octets_direction_interval = "li.sent";
  }

  my $uid = "l.uid='$attr->{UID}'";
  if ($attr->{UIDS}) {
    $uid = "l.uid IN ($attr->{UIDS})";
  }

  #Traffic transfert
  my $GROUP = '4';
  if ($traffic_transfert > 0) {
    $GROUP = '3';
  }

  my $WHERE = '';

  if ($attr->{FROM_DATE}) {
    $WHERE = "l.start>='$attr->{FROM_DATE} 00:00:00' AND l.start<='$attr->{TO_DATE} 00:00:00'";
  }
  else {
    $WHERE = "l.start>=DATE_FORMAT('$self->{INFO_LIST}->[0]->{activate}' - INTERVAL $traffic_transfert MONTH, '%Y-%m-%d 00:00:00') ";
  }

  if ($CONF->{DV_INTERVAL_PREPAID}) {
    $WHERE =~ s/l.start/li\.added/g;
    $uid =~ s/l.uid/li.uid/g;
    $self->query("SELECT li.traffic_type, SUM($octets_direction_interval) / $CONF->{MB_SIZE}, li.interval_id
       FROM dv_log_intervals li
       WHERE $uid AND ($WHERE)
    GROUP BY interval_id, li.traffic_type");
  }
  else {
    #Get using traffic
    $self->query("SELECT
     SUM($octets_direction) / $CONF->{MB_SIZE},
     SUM($octets_direction2) / $CONF->{MB_SIZE},
     DATE_FORMAT(l.start, '%Y-%m'),
     1
     FROM dv_log l
     WHERE $uid AND l.tp_id='$self->{INFO_LIST}->[0]->{tp_id}' and
      (  $WHERE
        )
     GROUP BY $GROUP
     ;"
    );
  }

  if ($self->{TOTAL} > 0) {
    my ($class1, $class2) = (0, 0);

    if (! $CONF->{DV_INTERVAL_PREPAID}) {
      $self->{INFO_LIST}->[0]->{prepaid} = 0;
      if ($prepaid_traffic{1}) { $self->{INFO_LIST}->[1]->{prepaid} = 0 }
    }

    foreach my $line (@{ $self->{list} }) {
      if ($CONF->{DV_INTERVAL_PREPAID}) {
        $rest_intervals{$line->[2]}{$line->[0]} = $rest_intervals{$line->[2]}{$line->[0]} - $line->[1];
      }
      else {
        $class1 = ((($class1 > 0) ? $class1 : 0) + $prepaid_traffic{0}) - $line->[0];
        $class2 = ((($class2 > 0) ? $class2 : 0) + $prepaid_traffic{1}) - $line->[1];

        $self->{INFO_LIST}->[0]->{prepaid} += $prepaid_traffic{0};
        if ($prepaid_traffic{1}) {
          $self->{INFO_LIST}->[1]->{prepaid} += $prepaid_traffic{1};
        }
      }
    }
    if (! $CONF->{DV_INTERVAL_PREPAID}) {
      $rest{0} = $class1;
      $rest{1} = $class2;
    }
  }

  if (! $CONF->{DV_INTERVAL_PREPAID}) {
    #Check online
    $self->query("SELECT
       $rest{0} - SUM($octets_online_direction) / $CONF->{MB_SIZE},
       $rest{1} - SUM($octets_online_direction2) / $CONF->{MB_SIZE},
       1
     FROM dv_calls l
     WHERE $uid
     GROUP BY 3;"
    );

    if ($self->{TOTAL} > 0) {
      ($rest{0}, $rest{1}) = @{ $self->{list}->[0] };
    }
    $self->{REST} = \%rest;
  }
  else {
    $self->{REST} = \%rest_intervals;
  }

  return 1;
}

#**********************************************************
=head2 list($attr) - Show completed sessin list

  Arguments:
    $attr
      INTERVAL  - Show session for intervals
      PERIOD    - Show sessions for period

  Result:
    hash_ref_array

=cut
#**********************************************************
sub list {
  my $self = shift;
  my ($attr) = @_;

  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;
  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 2;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';

  delete $self->{COL_NAMES_ARR};
  delete $self->{EXT_TABLES};
  my @WHERE_RULES = ();

  #Interval from date to date
  if ($attr->{INTERVAL}) {
    ($attr->{FROM_DATE}, $attr->{TO_DATE}) = split(/\//, $attr->{INTERVAL}, 2);
  }
  #Period
  elsif (defined($attr->{PERIOD})) {
    my $period = int($attr->{PERIOD});
    if ($period == 4) { }
    else {
      if    ($period == 0) { push @WHERE_RULES, "DATE_FORMAT(start, '%Y-%m-%d')=CURDATE()"; }
      elsif ($period == 1) { push @WHERE_RULES, "TO_DAYS(CURDATE()) - TO_DAYS(start) = 1 "; }
      elsif ($period == 2) { push @WHERE_RULES, "YEAR(CURDATE()) = YEAR(start) and (WEEK(CURDATE()) = WEEK(start)) "; }
      elsif ($period == 3) { push @WHERE_RULES, "DATE_FORMAT(start, '%Y-%m')=DATE_FORMAT(CURDATE(), '%Y-%m') "; }
      elsif ($period == 5) { push @WHERE_RULES, "DATE_FORMAT(start, '%Y-%m-%d')='$attr->{DATE}' "; }
      #Prev month
      elsif ($period == 6) { push @WHERE_RULES, "DATE_FORMAT(start, '%Y-%m')=DATE_FORMAT(CURDATE() - interval 1 month, '%Y-%m') "; }
      else                 { push @WHERE_RULES, "DATE_FORMAT(start, '%Y-%m-%d')=CURDATE() "; }
    }
  }

  my $EXT_TABLE = '';
  my $WHERE = $self->search_former($attr, [
      [ 'LOGIN',           'STR', 'u.id AS login',                1],
      [ 'DATE',            'DATE','l.start',                      1],
      [ 'START',           'DATE','l.start',                      1],
      [ 'END',             'DATE','l.start+INTERVAL l.duration SECOND', 'l.start+INTERVAL l.duration SECOND AS end '],
      [ 'DURATION',        'DATE','SEC_TO_TIME(l.duration) AS duration',   1 ],
      [ 'DURATION_SEC',    'INT', 'l.duration AS duration_sec',   1],
      [ 'SENT',            'INT', 'l.sent + 4294967296 * acct_output_gigawords AS sent', 1 ],
      [ 'RECV',            'INT', 'l.recv + 4294967296 * acct_input_gigawords AS recv',  1 ],
      [ 'SENT2',           'INT', 'l.sent2',                      1],
      [ 'RECV2',           'INT', 'l.recv2',                      1],
      [ 'IP',              'IP',  'l.ip',   'INET_NTOA(l.ip) AS ip'],
      [ 'CID',             'STR', 'l.cid',                        1],
      [ 'TP_ID',           'INT', 'l.tp_id',                      1],
      [ 'TP_NAME',         'STR', 'tp.name AS tp_name',           1],
      [ 'SUM',             'INT', 'l.sum',                        1],
      [ 'NAS_ID',          'INT', 'l.nas_id',                     1],
      [ 'NAS_PORT',        'INT', 'l.port_id',                    1],
      [ 'ACCT_SESSION_ID', 'STR', 'l.acct_session_id',            1],
      [ 'TERMINATE_CAUSE', 'INT', 'l.terminate_cause',            1],
      [ 'BILL_ID',         'STR', 'l.bill_id',                    1],
      [ 'START_UNIXTIME',  'INT', 'UNIX_TIMESTAMP(l.start) AS start_unixtime', 1],
      [ 'FROM_DATE|TO_DATE','DATE',"DATE_FORMAT(l.start, '%Y-%m-%d')"],
      [ 'MONTH',           'DATE',"DATE_FORMAT(l.start, '%Y-%m')"    ],
      [ 'UID',             'INT', 'l.uid'                            ],
    ],
    { WHERE             => 1,
      WHERE_RULES       => \@WHERE_RULES,
      USERS_FIELDS      => 1,
      SKIP_USERS_FIELDS => [ 'UID', 'LOGIN' ],
      USE_USER_PI       => 1,
    }
    );

  my $HAVING = '';
  if($attr->{LAST_SESSION}) {
    my @HAVING_RULES = ();
    my $value = @{ $self->search_expr($attr->{LAST_SESSION}, 'INT') }[0];
    push @HAVING_RULES, "last_connect$value";

    $self->{SEARCH_FIELDS} .= 'MAX(l.start) AS last_connect, ';
    $self->{SEARCH_FIELDS_COUNT}++;
    $HAVING = ($#HAVING_RULES > -1) ? "HAVING " . join(' AND ', @HAVING_RULES) : '';
  }

  if ($self->{SEARCH_FIELDS} =~ /\s?u\.|pi\./ || $self->{SEARCH_FIELDS} =~ /company\.id/ || $WHERE =~ / u\.|pi\./) {
    $EXT_TABLE .= "INNER JOIN users u ON (u.uid=l.uid)";
  }

  if ($self->{SEARCH_FIELDS} =~ /tp_bills_priority|tp_name|filter_id|tp_credit|payment_method|show_tp_id/ && $EXT_TABLE !~ /tarif_plans/) {
    $EXT_TABLE .= " LEFT JOIN tarif_plans tp ON (tp.id=l.tp_id AND MODULE='Dv')";
  }

  $EXT_TABLE .= $self->{EXT_TABLES};
  $SORT = $self->{SEARCH_FIELDS_COUNT}+2 if ($SORT > $self->{SEARCH_FIELDS_COUNT}+2);

  $self->query("SELECT $self->{SEARCH_FIELDS} l.acct_session_id, l.uid
    FROM dv_log l
    $EXT_TABLE
    $WHERE
    $HAVING
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;",
  undef,
  $attr
  );

  my $list = $self->{list};

  if ($self->{TOTAL} > 0) {
    $self->query("SELECT COUNT(l.uid) AS total,
      SUM(l.duration) AS duration,
      SUM(l.sent + 4294967296 * acct_output_gigawords) AS traffic_in,
      SUM(l.recv + 4294967296 * acct_input_gigawords) AS traffic_out,
      SUM(l.sent2) AS traffic2_in,
      SUM(l.recv2) AS traffic2_out,
      SUM(sum) AS sum
    FROM dv_log l
    $EXT_TABLE
    $WHERE;",
     undef,
     { INFO => 1 }
    );
  }

  return $list;
}

#**********************************************************
=head2 calculation($attr) -  session calculation

  min max average

=cut
#**********************************************************
sub calculation {
  my ($self) = shift;
  my ($attr) = @_;

  my @WHERE_RULES = ();

  #Login
  if ($attr->{UIDS}) {
    push @WHERE_RULES, "l.uid IN ($attr->{UIDS})";
  }
  elsif ($attr->{UID}) {
    push @WHERE_RULES, "l.uid='$attr->{UID}'";
  }

  if ($attr->{INTERVAL}) {
    my ($from, $to) = split(/\//, $attr->{INTERVAL}, 2);
    push @WHERE_RULES, "DATE_FORMAT(start, '%Y-%m-%d')>='$from' and DATE_FORMAT(start, '%Y-%m-%d')<='$to'";
  }

  #Period
  elsif (defined($attr->{PERIOD})) {
    my $period = int($attr->{PERIOD});
    if ($period == 4) {

    }
    else {
      if    ($period == 0) { push @WHERE_RULES, "DATE_FORMAT(start, '%Y-%m-%d')=CURDATE()"; }
      elsif ($period == 1) { push @WHERE_RULES, "TO_DAYS(CURDATE()) - TO_DAYS(start) = 1 "; }
      elsif ($period == 2) { push @WHERE_RULES, "YEAR(CURDATE()) = YEAR(start) and (WEEK(CURDATE()) = WEEK(start)) "; }
      elsif ($period == 3) { push @WHERE_RULES, "DATE_FORMAT(start, '%Y-%m')=DATE_FORMAT(CURDATE(), '%Y-%m') "; }
      elsif ($period == 5) { push @WHERE_RULES, "DATE_FORMAT(start, '%Y-%m-%d')='$attr->{DATE}' "; }
    }
  }

  my $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

  $self->query("SELECT
  min(l.duration) AS min_dur,
  max(l.duration) AS max_dur,
  avg(l.duration) AS avg_dur,
  SUM(l.duration) AS total_dur,
  min(l.sent + 4294967296 * acct_output_gigawords) AS min_sent,
  max(l.sent + 4294967296 * acct_output_gigawords) AS max_sent,
  avg(l.sent + 4294967296 * acct_output_gigawords) AS avg_sent,
  SUM(l.sent + 4294967296 * acct_output_gigawords) AS total_sent,
  min(l.recv + 4294967296 * acct_input_gigawords) AS min_recv,
  max(l.recv + 4294967296 * acct_input_gigawords) AS max_recv,
  avg(l.recv + 4294967296 * acct_input_gigawords) AS avg_recv,
  SUM(l.recv + 4294967296 * acct_input_gigawords) AS total_recv,
  min(l.recv+l.sent) AS min_sum,
  max(l.recv+l.sent) AS max_sum,
  avg(l.recv+l.sent) AS avg_sum,
  SUM(l.recv+l.sent) AS total_sum
  FROM dv_log l $WHERE",
  undef,
  { INFO => 1 }
  );

  return $self;
}

#**********************************************************
=head reports($attr)

=cut
#**********************************************************
sub reports {
  my ($self) = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my @WHERE_RULES= ();
  my $date       = '';
  my $EXT_TABLES = '';
  my $ext_fields = ', u.company_id';

  my @FIELDS_ARR = ('DATE', 'USERS', 'USERS_FIO', 'TP', 'SESSIONS', 'TRAFFIC_RECV', 'TRAFFIC_SENT', 'TRAFFIC_SUM', 'TRAFFIC_2_SUM', 'DURATION', 'SUM',);

  $self->{REPORT_FIELDS} = {
    DATE            => '',
    USERS           => 'u.id',
    USERS_FIO       => 'u.fio',
    SESSIONS        => 'COUNT(l.uid)',
    TERMINATE_CAUSE => 'l.terminate_cause',
    TRAFFIC_SUM     => 'SUM(l.sent + 4294967296 * acct_output_gigawords + l.recv + 4294967296 * acct_input_gigawords)',
    TRAFFIC_2_SUM   => 'SUM(l.sent2 + l.recv2)',
    DURATION        => 'SEC_TO_TIME(SUM(l.duration))',
    SUM             => 'SUM(l.sum)',
    TRAFFIC_RECV    => 'SUM(l.recv + 4294967296 * acct_input_gigawords)',
    TRAFFIC_SENT    => 'SUM(l.sent + 4294967296 * acct_output_gigawords)',
    USERS_COUNT     => 'COUNT(DISTINCT l.uid)',
    TP              => 'l.tp_id',
    COMPANIES       => 'c.name'
  };

  my $EXT_TABLE = 'users';

  if (defined($attr->{DATE})) {
    push @WHERE_RULES, " DATE_FORMAT(l.start, '%Y-%m-%d')='$attr->{DATE}'";
  }
  elsif ($attr->{INTERVAL}) {
    my ($from, $to) = split(/\//, $attr->{INTERVAL}, 2);
    push @WHERE_RULES, "DATE_FORMAT(l.start, '%Y-%m-%d')>='$from' and DATE_FORMAT(l.start, '%Y-%m-%d')<='$to'";
    $attr->{TYPE} = '-' if (!$attr->{TYPE});
    if ($attr->{TYPE} eq 'HOURS') {
      $date = "DATE_FORMAT(l.start, '\%H') AS hour";
    }
    elsif ($attr->{TYPE} eq 'DAYS') {
      $date = "DATE_FORMAT(l.start, '%Y-%m-%d') AS date";
    }
    elsif ($attr->{TYPE} eq 'TP') {
      $date = "l.tp_id";
    }
    elsif ($attr->{TYPE} eq 'TERMINATE_CAUSE') {
      $date = "l.terminate_cause";
    }
    elsif ($attr->{TYPE} eq 'GID') {
      $date = "u.gid";
    }
    elsif ($attr->{TYPE} eq 'COMPANIES') {
      $date       = "c.name";
      $EXT_TABLES = "INNER JOIN companies c ON (c.id=u.company_id)";
    }
    else {
      $date = "u.id";
    }
  }
  elsif ($attr->{MONTH}) {
    push @WHERE_RULES, "DATE_FORMAT(l.start, '%Y-%m')='$attr->{MONTH}'";
    $date = "DATE_FORMAT(l.start, '%Y-%m-%d')";
  }
  else {
    $date = "DATE_FORMAT(l.start, '%Y-%m')";
  }

  if($attr->{USER_SUMMARY}) {
    my $period = 'DATE_FORMAT(start, \'%Y-%m\')=DATE_FORMAT(CURDATE(), \'%Y-%m\')';

    if($attr->{DAILY}) {
      $period = 'DATE_FORMAT(start, \'%Y-%m-%d\')=CURDATE()';
    }

    $self->query("SELECT
       SUM(l.sent + 4294967296 * acct_output_gigawords) AS sent,
       SUM(l.recv + 4294967296 * acct_input_gigawords) AS recv
       FROM dv_log l
       WHERE uid= ? AND $period
       GROUP BY uid;",
      undef,
      { INFO => 1, Bind => [ $attr->{UID} ] }
    );

    return $self;
  }

  if ($admin->{DOMAIN_ID}) {
    push @WHERE_RULES, @{ $self->search_expr("$admin->{DOMAIN_ID}", 'INT', 'u.domain_id', { EXT_FIELD => 0 }) };
  }

  my $WHERE = $self->search_former($attr, [
      [ 'LOGIN',        'STR',  'u.id',   ],
      [ 'GID',          'INT',  'u.gid',  ],
      [ 'UID',          'INT',  'l.uid',  ],
      [ 'COMPANY_ID',   'INT',  'u.company_id' ],
      [ 'TP_ID',        'INT',  'l.tp_id' ],
  ],
    { WHERE             => 1,
      WHERE_RULES       => \@WHERE_RULES,
    }
  );

  $self->{REPORT_FIELDS}{DATE} = $date;
  my $fields = "$date, COUNT(DISTINCT l.uid) AS users_count,
      COUNT(l.uid) AS sessions_count,
      SUM(l.sent + 4294967296 * acct_output_gigawords + l.recv + 4294967296 * acct_input_gigawords) AS sent,
      SUM(l.sent2 + l.recv2) AS sent2,
      SEC_TO_TIME(SUM(l.duration)),
      SUM(l.sum) AS sum";

  if ($attr->{FIELDS}) {
    my @fields_array    = split(/, /, $attr->{FIELDS});
    my @show_fields     = ();
    my %get_fields_hash = ();

    foreach my $line (@fields_array) {
      $get_fields_hash{$line} = 1;
      if ($line eq 'USERS_FIO') {
        $EXT_TABLE = 'users_pi';
        $date      = 'u.fio';
      }
      elsif ($line =~ /^_(\S+)/) {
        my $f = '_' . $1;
        push @FIELDS_ARR, $f;
        $self->{REPORT_FIELDS}{$f} = 'u.' . $f;
        $EXT_TABLE = 'users_pi';
      }
    }

    foreach my $k (@FIELDS_ARR) {
      if ($get_fields_hash{$k}) {
        push @show_fields, $self->{REPORT_FIELDS}{$k};
      }
    }

    $fields = join(', ', @show_fields);
  }

  if (defined($attr->{DATE})) {
    if (defined($attr->{HOURS})) {
      $self->query("SELECT DATE_FORMAT(l.start, '%Y-%m-%d %H') AS start,
        COUNT(DISTINCT l.uid) AS total_users,
        COUNT(l.uid) AS count,
        SUM(l.sent + 4294967296 * acct_output_gigawords + l.recv + 4294967296 * acct_input_gigawords) AS traffic_sum,
        SUM(l.sent2 + l.recv2) AS traffic_2_sum,
        SUM(l.duration) AS duration_sec,
        SUM(l.sum) AS sum,
        l.uid
        $ext_fields
      FROM dv_log l
      LEFT JOIN $EXT_TABLE u ON (u.uid=l.uid)
      $EXT_TABLES
      $WHERE
      GROUP BY 1
      ORDER BY $SORT $DESC",
      undef,
      $attr
      );
    }
    else {
      $self->query("SELECT DATE_FORMAT(l.start, '%Y-%m-%d') AS date,
        IF(u.id is NULL, CONCAT('> ', l.uid, ' <'), u.id) AS login,
        COUNT(l.uid) AS login_count,
        SUM(l.sent + 4294967296 * acct_output_gigawords + l.recv + 4294967296 * acct_input_gigawords) AS traffic_sum,
        SUM(l.sent2 + l.recv2) AS traffic_2_sum,
        SEC_TO_TIME(SUM(l.duration)) AS duration_sec,
        SUM(l.sum) AS sum,
        l.uid ext_fields
      FROM dv_log l
      LEFT JOIN $EXT_TABLE u ON (u.uid=l.uid)
      $EXT_TABLES
      $WHERE
      GROUP BY l.uid
      ORDER BY $SORT $DESC",
      undef,
      $attr
      );
    }
  }
  elsif ($attr->{TP}) {
    print "TP";
  }
  else {
    $self->query("SELECT $fields,
      l.uid $ext_fields
      FROM dv_log l
      LEFT JOIN $EXT_TABLE u ON (u.uid=l.uid)
      $EXT_TABLES
      $WHERE
       GROUP BY 1
       ORDER BY $SORT $DESC;",
      undef,
      $attr
    );
  }

  if($self->{errno}){
    return [];
  }

  my $list = $self->{list};

  $self->{USERS}     = 0;
  $self->{SESSIONS}  = 0;
  $self->{TRAFFIC}   = 0;
  $self->{TRAFFIC_2} = 0;
  $self->{DURATION}  = 0;
  $self->{SUM}       = 0;

  return $list if ($self->{TOTAL} < 1);

  $self->query("SELECT COUNT(DISTINCT l.uid) AS users,
      COUNT(l.uid) AS sessions,
      SUM(l.sent + 4294967296 * acct_output_gigawords) AS traffic_out,
      SUM(l.recv + 4294967296 * acct_input_gigawords) AS traffic_in,
      SUM(l.sent2) AS traffic_2_out,
      SUM(l.recv2) AS traffic_2_in,
      SEC_TO_TIME(SUM(l.duration)) AS duration,
      SUM(l.sum) AS sum
     FROM dv_log l
     LEFT JOIN $EXT_TABLE u ON (u.uid=l.uid)
     $EXT_TABLES
     $WHERE;",
    undef,
    { INFO => 1 }
  );

  $self->{TRAFFIC}   = $self->{TRAFFIC_OUT} + $self->{TRAFFIC_IN};
  $self->{TRAFFIC_2} = $self->{TRAFFIC_2_OUT} + $self->{TRAFFIC_2_IN};

  return $list;
}


#**********************************************************
=head reports2($attr) - Internet using reports

  Arguments:
    $attr

  Returns:
    $list

=cut
#**********************************************************
sub reports2 {
  my ($self) = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  my %EXT_TABLE_JOINS_HASH = ();
  my $main_field           = '';

  if ($admin->{DOMAIN_ID} || $attr->{GID} || $attr->{TAGS}) {
    $EXT_TABLE_JOINS_HASH{users}=1;
  }

  if($attr->{INTERVAL}) {
    ($attr->{FROM_DATE}, $attr->{TO_DATE}) = split(/\//, $attr->{INTERVAL}, 2);
  }

  $attr->{SKIP_DEL_CHECK}=1;

  my $WHERE2 =  $self->search_former($attr, [
      ['DATE',             'DATE',"DATE_FORMAT(l.start, '%Y-%m-%d')", "DATE_FORMAT(l.start, '%Y-%m-%d') AS date"  ],
      ['FIO',              'STR', 'pi.fio', 1         ],
      ['MONTH',            'DATE',"DATE_FORMAT(l.start, '%Y-%m')"   ],
      ['NAS_ID',           'INT', 'nas_id'            ],
      ['NAS_IP_ADDRESS',   'IP',  'nas_ip_address'    ],
      ['NAS_PORT',         'INT', 'nas_port_id',      ],
      ['ACCT_SESSION_ID',  'STR', 'acct_session_id'   ],
      ['UID',              'INT', 'l.uid'             ],

      #['DATE'            => '',
      ['USERS',           'STR', 'u.id', 'u.id AS login' ],
      ['USERS_FIO',       'STR', 'u.fio',              1 ],
      ['SESSIONS',        'INT', 'COUNT(l.uid)',    'COUNT(l.uid) AS sessions' ],
      ['TERMINATE_CAUSE', 'INT', 'l.terminate_cause',  1 ],
      ['TRAFFIC_SUM',     'INT', 'SUM(l.sent + 4294967296 * acct_output_gigawords + l.recv + 4294967296 * acct_input_gigawords)',
            'SUM(l.sent + 4294967296 * acct_output_gigawords + l.recv + 4294967296 * acct_input_gigawords) AS traffic_sum' ],
      ['TRAFFIC_2_SUM',   'INT', 'SUM(l.sent2 + l.recv2)', 'SUM(l.sent2 + l.recv2) AS traffic_2_sum'       ],
      ['DURATION',        'INT', 'SEC_TO_TIME(SUM(l.duration))', 'SEC_TO_TIME(SUM(l.duration)) AS duration' ],
      ['TP_ID',           'INT', 'l.tp_id',            1 ],
      ['COMPANIES',       'STR', 'c.name',             1 ],

      ['USERS_COUNT',     'INT',    '',  'COUNT(DISTINCT l.uid) AS users_count'       ],
      ['SESSIONS_COUNT',  '',    '',  'COUNT(l.uid) AS sessions_count',               ],
      ['TRAFFIC_RECV',    'INT', 'SUM(l.recv + 4294967296 * acct_input_gigawords)',  'SUM(l.recv + 4294967296 * acct_input_gigawords) AS traffic_recv' ],
      ['TRAFFIC_SENT',    'INT', 'SUM(l.sent + 4294967296 * acct_output_gigawords)', 'SUM(l.sent + 4294967296 * acct_output_gigawords) AS traffic_sent' ],
      ['DURATION_SEC',    'INT', 'SUM(l.duration)', 'SUM(l.duration) AS duration_sec' ],
      ['SUM',             'INT', 'SUM(l.sum)',  'SUM(l.sum) AS sum'                   ],
      ['LOCATION_ID',     'INT', 'builds.id', 'builds.id AS location_id',             ],
      ['COORDX',          'INT', 'builds.coordx',                                   1 ],
      ['COORDY',          'INT', 'builds.coordy',                                   1 ],
      ['FROM_DATE|TO_DATE','DATE',"DATE_FORMAT(l.start, '%Y-%m-%d')"                  ],
    ],
    {
      WHERE            => 1,
      USERS_FIELDS     => 1,
      USE_USER_PI      => 1,
      SKIP_USERS_FIELDS => [ 'UID', 'LOGIN' ],
    }
  );

  if ( $attr->{INTERVAL} ){
    ($attr->{FROM_DATE}, $attr->{TO_DATE}) = split( /\//, $attr->{INTERVAL}, 2 );
    $attr->{TYPE} = '-' if (!$attr->{TYPE});

    if ( $attr->{TYPE} eq 'HOURS' ){
      $main_field = "DATE_FORMAT(l.start, '\%H') AS hour";
      #$self->{SEARCH_FIELDS} .= "DATE_FORMAT(l.start, '\%H') AS hour";
    }
    elsif ( $attr->{TYPE} eq 'DAYS' ){
      $main_field = "DATE_FORMAT(l.start, '%Y-%m-%d') AS date";
      #$self->{SEARCH_FIELDS} .= "DATE_FORMAT(l.start, '%Y-%m-%d') AS date";
    }
    elsif ( $attr->{TYPE} eq 'TP' ){
      $main_field = "l.tp_id";
    }
    elsif ( $attr->{TYPE} eq 'TERMINATE_CAUSE' ){
      $main_field = "l.terminate_cause";
      #$self->{SEARCH_FIELDS} = "l.terminate_cause";
    }
    elsif ( $attr->{TYPE} eq 'GID' ){
      $main_field = "u.gid";
      #$self->{SEARCH_FIELDS} = "l.terminate_cause";
      $EXT_TABLE_JOINS_HASH{users} = 1;
    }
    elsif ( $attr->{TYPE} eq 'PER_MONTH' ){
      $main_field = "DATE_FORMAT(l.start, '%Y-%m') AS month";
    }
    elsif ( $attr->{TYPE} eq 'COMPANIES' ){
      $main_field = "company.name AS company_name";
      $self->{SEARCH_FIELDS} .= 'u.company_id,';
      $EXT_TABLE_JOINS_HASH{users} = 1;
      $EXT_TABLE_JOINS_HASH{companies} = 1;
    }
    elsif ( $attr->{TYPE} eq 'DISTRICT' ){
      $main_field = "districts.name AS district_name";
      $self->{SEARCH_FIELDS} .= 'districts.id AS district_id,';
      $EXT_TABLE_JOINS_HASH{users} = 1;
      $EXT_TABLE_JOINS_HASH{users_pi} = 1;
      $EXT_TABLE_JOINS_HASH{builds} = 1;
      $EXT_TABLE_JOINS_HASH{streets} = 1;
      $EXT_TABLE_JOINS_HASH{districts} = 1;
    }
    elsif ( $attr->{TYPE} eq 'STREET' ){
      $main_field = "streets.name AS street_name";
      $self->{SEARCH_FIELDS} .= 'streets.id AS street_id,';
      $EXT_TABLE_JOINS_HASH{users} = 1;
      $EXT_TABLE_JOINS_HASH{users_pi} = 1;
      $EXT_TABLE_JOINS_HASH{builds} = 1;
      $EXT_TABLE_JOINS_HASH{streets} = 1;
    }
    elsif ( $attr->{TYPE} eq 'BUILD' ){
      $main_field = "CONCAT(streets.name, '$CONF->{BUILD_DELIMITER}', builds.number) AS build";
      $attr->{LOCATION_ID} = '_SHOW';
      $EXT_TABLE_JOINS_HASH{users} = 1;
      $EXT_TABLE_JOINS_HASH{users_pi} = 1;
      $EXT_TABLE_JOINS_HASH{builds} = 1;
      $EXT_TABLE_JOINS_HASH{streets} = 1;
    }
    else{
      $main_field = "u.id AS login";
      $EXT_TABLE_JOINS_HASH{users} = 1;
    }
  }
  elsif ( $attr->{DATE} ){
    $main_field = "u.id AS login";
    $EXT_TABLE_JOINS_HASH{users} = 1;
  }
  elsif ( $attr->{MONTH} ){
    $main_field = "DATE_FORMAT(l.start, '%Y-%m-%d') AS date";
  }
  else{
    $main_field = "u.id AS login";
    $EXT_TABLE_JOINS_HASH{users} = 1;
  }

  if ( $attr->{USERS} || $attr->{DEPOSIT} || $attr->{GID} || $admin->{GID}){
    $EXT_TABLE_JOINS_HASH{users} = 1;
  }

  my $EXT_TABLES = $self->mk_ext_tables( {
      JOIN_TABLES    => \%EXT_TABLE_JOINS_HASH,
      EXTRA_PRE_JOIN => [ 'users:INNER JOIN users u ON (u.uid=l.uid)',
      ]
    } );

  $self->query( "SELECT $main_field, $self->{SEARCH_FIELDS}
      l.uid
       FROM dv_log l
       $EXT_TABLES
       $WHERE2
       GROUP BY 1
       ORDER BY $SORT $DESC;",
    undef,
    $attr
  );

  my $list = $self->{list};

  $self->{USERS} = 0;
  $self->{SESSIONS} = 0;
  $self->{TRAFFIC} = 0;
  $self->{TRAFFIC_2} = 0;
  $self->{DURATION} = 0;
  $self->{SUM} = 0;

  return $list if ($self->{TOTAL} < 1);

  $self->query( "SELECT COUNT(DISTINCT l.uid) AS users,
      COUNT(l.uid) AS sessions,
      SUM(l.sent + 4294967296 * acct_output_gigawords) AS traffic_out,
      SUM(l.recv + 4294967296 * acct_input_gigawords) AS traffic_in,
      SUM(l.sent2) AS traffic_2_out,
      SUM(l.recv2) AS traffic_2_in,
      SUM(l.duration) AS duration_sec,
      SUM(l.sum) AS sum
       FROM dv_log l
       $EXT_TABLES
       $WHERE2;",
    undef,
    { INFO => 1 }
  );

  $self->{TRAFFIC} = $self->{TRAFFIC_OUT} + $self->{TRAFFIC_IN};
  $self->{TRAFFIC_2} = $self->{TRAFFIC_2_OUT} + $self->{TRAFFIC_2_IN};

  return $list;
}

#**********************************************************
=head2 list_log_intervals($attr)

=cut
#**********************************************************
sub list_log_intervals{
  my $self = shift;
  my ($attr) = @_;

  $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;
  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 2;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  my @WHERE_RULES = ();

  if ( $attr->{ACCT_SESSION_ID} ){
    push @WHERE_RULES, @{ $self->search_expr($attr->{ACCT_SESSION_ID}, 'STR', 'l.acct_session_id' ) };
  }

  if ( $attr->{UID} ){
    push @WHERE_RULES, @{ $self->search_expr($attr->{UID}, 'STR', 'l.uid' ) };
  }

  my $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join( ' AND ', @WHERE_RULES ) : '';

  $self->query( "SELECT
    interval_id,
    traffic_type,
    sent,
    recv,
    duration,
    sum
  FROM dv_log_intervals l
  $WHERE
  ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list};

  return $list;
}

#**********************************************************
=head2 log_rotate($attr) - Rotate dv logs

=cut
#**********************************************************
sub log_rotate{
  my $self = shift;
  my ($attr) = @_;

  my $version = $self->db_version();
  my @rq = ();

  if ( $version > 4.1 ){
    push @rq, 'CREATE TABLE IF NOT EXISTS errors_log_new LIKE errors_log;',
      'CREATE TABLE IF NOT EXISTS errors_log_new_sorted LIKE errors_log;',
      'RENAME TABLE errors_log TO errors_log_old, errors_log_new TO errors_log;',
      'INSERT INTO errors_log_new_sorted SELECT max(date), log_type, action, user, message, nas_id FROM errors_log_old GROUP BY user ORDER BY 1;'
      ,
      'DROP TABLE errors_log_old;',
      'INSERT INTO errors_log_new_sorted SELECT max(date), log_type, action, user, message, nas_id FROM errors_log GROUP BY user;'
      ,
      'RENAME TABLE errors_log TO errors_log_old, errors_log_new_sorted TO errors_log;',
      'DROP TABLE errors_log_old;';

    if ( !$attr->{DAILY} ){
      use POSIX qw(strftime);
      my $DATE = (POSIX::strftime( "%Y_%m_%d", localtime( time - 86400 ) ));
      push @rq, 'CREATE TABLE IF NOT EXISTS s_detail_new LIKE s_detail;',
        'RENAME TABLE s_detail TO s_detail_' . $DATE . ', s_detail_new TO s_detail;',

        #'CREATE TABLE IF NOT EXISTS errors_log_new LIKE errors_log;',
        #'RENAME TABLE errors_log TO errors_log_'. $DATE .
        # ', errors_log_new TO errors_log;',

        'CREATE TABLE IF NOT EXISTS dv_log_intervals_new LIKE dv_log_intervals;',
        'DROP TABLE dv_log_intervals_old',
        'RENAME TABLE dv_log_intervals TO dv_log_intervals_old, dv_log_intervals_new TO dv_log_intervals;';
      if ( $CONF->{DV_INTERVAL_PREPAID} ){
        push @rq,
          'INSERT INTO dv_log_intervals SELECT * FROM dv_log_intervals_old WHERE added>=UNIX_TIMESTAMP()-86400*31;';
      }
    }
  }
  else{
    push @rq, "DELETE FROM s_detail
            WHERE last_update < UNIX_TIMESTAMP()- $attr->{PERIOD} * 24 * 60 * 60;";

    # LOW_PRIORITY
    push @rq, "DELETE dv_log_intervals from dv_log, dv_log_intervals
     WHERE
     dv_log.acct_session_id=dv_log_intervals.acct_session_id
      and dv_log.start < CURDATE() - INTERVAL $attr->{PERIOD} DAY;";
  }

  foreach my $query ( @rq ){
    $self->query( "$query", 'do' );
  }

  return $self;
}

1
