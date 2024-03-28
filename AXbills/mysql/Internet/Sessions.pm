package Internet::Sessions;

=head1 NAME

  Internet Stats functions
    time
    traffic

=cut

use strict;
our $VERSION = 2.00;
use parent qw( dbcore );
#use Conf;

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

  $CONF->{BUILD_DELIMITER} = ', ' if (!defined($CONF->{BUILD_DELIMITER}));

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
    $self->query_del('internet_log', undef, { uid => $attr->{DELETE_USER} });
  }
  else {
    $self->query("SHOW TABLES LIKE 'traffic_prepaid_sum';");

    if ($self->{TOTAL} > 0) {
      $self->query(
        "UPDATE traffic_prepaid_sum pl, internet_log l SET
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
    #         "UPDATE internet_log_intervals li, internet_log l SET
    #           li.recv=li.recv-(l.recv + 4294967296 * l.acct_input_gigawords),
    #           li.sent=li.sent-(l.sent + 4294967296 * l.acct_output_gigawords),
    #           li.sum=li.sum-l.sum
    #         WHERE li.uid=l.uid
    #           AND li.acct_session_id=l.acct_session_id
    #           AND l.uid='$uid'
    #           AND l.acct_session_id='$session_id';", 'do'
    #    );
    $self->query_del('internet_log_intervals', undef, {
      uid            => $uid,
      acct_session_id=> $session_id
    });

    $self->query_del('internet_log', undef, {
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

  Arguments:
    $attr
      USER_NAME
      ACCT_SESSION_ID

      GUEST

  Resturns:
    $self

=cut
#**********************************************************
sub online_update {
  my $self      = shift;
  my ($attr)    = @_;
  my @SET_RULES = ();

  push @SET_RULES, 'lupdated=UNIX_TIMESTAMP()' if ($attr->{STATUS} && $attr->{STATUS} == 5);

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

  if (defined($attr->{GUEST})) {
    push @SET_RULES, "guest='$attr->{GUEST}'";
  }

  if ($attr->{TP_ID}) {
    push @SET_RULES, "tp_id='$attr->{TP_ID}'";
  }

  if ($attr->{CONNECT_INFO}) {
    push @SET_RULES, "connect_info='$attr->{CONNECT_INFO}'";
  }

  push @SET_RULES, "lupdated=UNIX_TIMESTAMP()";

  my $SET = ($#SET_RULES > -1) ? join(', ', @SET_RULES) : '';

  $self->query("UPDATE internet_online SET "
   . $SET .
   "WHERE
     user_name= ?
     AND acct_session_id= ?; ", 'do',
    { Bind => [
        $attr->{USER_NAME},
        $attr->{ACCT_SESSION_ID} ]
    }
  );

  if ( $attr->{SUM} && $self->{USERS_INFO}
    && $self->{USERS_INFO}->{DEPOSIT}->{ $attr->{UID} } ){
    #Take money from bill
    if ( $attr->{SUM} > 0 ){
      $self->query( "UPDATE bills SET deposit=deposit- ? WHERE id= ? ;", 'do', { Bind => [
            $attr->{SUM},
            $self->{USERS_INFO}->{BILL_ID}->{$attr->{UID}}
          ] } );
    }

    #If negative deposit hangup
    if ( $self->{USERS_INFO}->{DEPOSIT}->{ $attr->{UID} } - $attr->{SUM} < 0 ){
      $self->{USERS_INFO}->{DEPOSIT}->{ $attr->{UID} } = $self->{USERS_INFO}->{DEPOSIT}->{ $attr->{UID} } - $attr->{SUM};
    }
  }

  return $self;
}

#**********************************************************
=head2 online_count($attr) - Count online sessions

=cut
#**********************************************************
sub online_count {
  my $self = shift;
  my ($attr) = @_;

  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;

  if($SORT > 9) {
    $SORT = 9;
  }

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

  $self->query("SELECT c.nas_id,
   n.name AS nas_name,
   INET_NTOA(n.ip) AS nas_ip,
   n.nas_type,
   SUM(IF (c.status=1 or c.status>=3, 1, 0)) AS nas_total_sessions,
   COUNT(DISTINCT c.uid) AS nas_total_users,
   SUM(IF (c.status=2, 1, 0)) AS nas_zaped,
   SUM(IF (c.status>3 AND c.status<>6, 1, 0)) AS nas_error_sessions,
   SUM(IF (c.guest=1, 1, 0)) AS guest
 FROM internet_online c
 INNER JOIN nas n ON (c.nas_id=n.id)
 $EXT_TABLE
 $WHERE
 GROUP BY c.nas_id
 ORDER BY $SORT $DESC;",
    undef,
    $attr
  );

  my $list = $self->{list};
  $self->{TOTAL_NAS} = $self->{TOTAL};
  $self->{ONLINE}=0;

  if($CONF->{DHCP_LEASES_NAS}) {
    $WHERE = ($WHERE) ? "$WHERE AND c.nas_id NOT IN ($CONF->{DHCP_LEASES_NAS})" : " WHERE c.nas_id NOT IN ($CONF->{DHCP_LEASES_NAS})";
  }

  if ($self->{TOTAL} > 0) {
    $WHERE = ($WHERE) ? "$WHERE AND c.status<11" : " WHERE c.status<11";

    $self->query(
      "SELECT 1, COUNT(DISTINCT c.uid) AS total_users,
      SUM(IF (c.status=1 or c.status>=3, 1, 0)) AS online,
      SUM(IF (c.status=2, 1, 0)) AS zaped
   FROM internet_online c
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

  $self->query_add('internet_online', { %$attr }, { REPLACE => $attr->{REPLACE_RECORDS} });

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

    $self->query("SELECT COUNT(*) AS total FROM internet_online c $WHERE;", undef, { INFO => 1 });
    return $self;
  }
  elsif ($attr->{STATUS_COUNT}) {
    $self->query("SELECT SUM(IF ((c.status=1 OR c.status>=3) AND c.status<11, 1, 0)) AS online_count,
      SUM(IF (c.status=2, 1, 0)) AS zapped_count,
      SUM(IF (c.status=6, 1, 0)) AS reconnect_count,
      SUM(IF (c.status=9, 1, 0)) AS recover_count
    FROM internet_online c $WHERE;", undef, { INFO => 1  });

    return $self;
  }

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  my @WHERE_RULES = ();

  if ($attr->{ZAPED}) {
    push @WHERE_RULES, "c.status=2";
  }
  elsif($attr->{NAS_ERROR_SESSIONS}) {
    push @WHERE_RULES, "(c.status>3 AND c.status<>6)";
    $attr->{GROUP_BY}='c.cid';
  }
  elsif ($attr->{ALL} || ($attr->{STATUS} && $attr->{STATUS} ne '_SHOW')) {
  }
  else {
    push @WHERE_RULES, "((c.status=1 OR c.status>=3) AND c.status<11)";
  }

  if ($attr->{FILTER}) {
    $attr->{$attr->{FILTER_FIELD}} = $attr->{FILTER};
  }

  my $GROUP_BY = ($attr->{GROUP_BY}) ? $attr->{GROUP_BY} : 'c.acct_session_id, c.uid, c.service_id';

  if($attr->{INTERNET_SKIP_SHOW_DHCP}) {
    $attr->{NAS_TYPE}='!dhcp';
  }

  if ($attr->{_WHERE_RULES}) {
    push @WHERE_RULES, $attr->{_WHERE_RULES};
    delete $attr->{_WHERE_RULES};
  }

  $attr->{SKIP_DEL_CHECK}=1;
  $attr->{SORT_SHIFT}=1;

  $WHERE = $self->search_former($attr, [
      ['LOGIN',             'STR', 'IF(c.uid>0, u.id, c.user_name) AS login',      1 ],
      ['USER_NAME',         'STR', 'c.user_name',                                  1 ],
      ['DURATION',          'INT', 'SEC_TO_TIME(UNIX_TIMESTAMP() - UNIX_TIMESTAMP(c.started))', 'SEC_TO_TIME(UNIX_TIMESTAMP() - UNIX_TIMESTAMP(c.started)) AS duration', 1 ],
      ['DURATION_SEC',      'INT', 'IF(c.lupdated>UNIX_TIMESTAMP(c.started), c.lupdated - UNIX_TIMESTAMP(c.started), 0) AS duration_sec',        1 ],
      ['DURATION_SEC2',     'INT', 'UNIX_TIMESTAMP() - UNIX_TIMESTAMP(c.started) AS duration_sec2',         1 ],
      ['NAS_PORT_ID',       'INT', 'c.nas_port_id',                                                         1 ],
      ['CLIENT_IP_NUM',     'INT', 'c.framed_ip_address',   'c.framed_ip_address AS client_ip_num'            ],
      ['CLIENT_IP',         'IP',  'c.framed_ip_address',   'INET_NTOA(c.framed_ip_address) AS client_ip',  1 ],
      ['FRAMED_IPV6_PREFIX',   'IP', 'c.framed_ipv6_prefix',  'INET6_NTOA(c.framed_ipv6_prefix) AS framed_ipv6_prefix', 1 ],
      ['FRAMED_INTERFACE_ID',  'IP', 'c.framed_interface_id', 'INET6_NTOA(c.framed_interface_id) AS ipv6_interface_id', 1 ],
      ['DELEGATED_IPV6_PREFIX','IP', 'c.delegated_ipv6_prefix', 'INET6_NTOA(c.delegated_ipv6_prefix) AS delegated_ipv6_prefix', 1 ],
      ['ACCT_INPUT_OCTETS', 'INT', 'c.acct_input_octets + 4294967296 * acct_input_gigawords AS acct_input_octets',    1 ],
      ['ACCT_OUTPUT_OCTETS','INT', 'c.acct_output_octets + 4294967296 * acct_output_gigawords AS acct_output_octets', 1 ],
      ['EX_INPUT_OCTETS',   'INT', 'c.ex_input_octets',                            1 ],
      ['EX_OUTPUT_OCTETS',  'INT', 'c.ex_output_octets',                           1 ],
      ['CID',               'STR', 'c.cid',                                        1 ],
      ['TP_NAME',           'STR', 'tp.name AS tp_name',                           1 ],
      ['STARTED',           'DATE','c.started', 'IF(DATE_FORMAT(c.started, "%Y-%m-%d")=CURDATE(), DATE_FORMAT(c.started, "%H:%i:%s"), c.started) AS started' ],
      ['NETMASK',           'IP',  'internet.netmask',        'INET_NTOA(internet.netmask) AS netmask'],
      ['CONNECT_INFO',      'STR', 'c.connect_info',                               1 ],
      ['SPEED',             'INT', 'internet.speed',                               1 ],
      ['SESSION_SUM',       'INT', 'c.sum AS session_sum',                         1 ],
      ['ONLINE_TP_ID',      'INT', 'c.tp_id',              'c.tp_id AS online_tp_id' ],
      ['STATUS',            'INT', 'c.status',                                     1 ],
      ['TP_ID',             'INT', 'internet.tp_id',                               1 ],
      ['SERVICE_CID',       'STR', 'internet.cid',     'internet.cid AS service_cid' ],
      ['GUEST',             'INT', 'c.guest',                                      1 ],
      ['TURBO_MODE',        'INT', 'c.turbo_mode',                                 1 ],
      ['TURBO_BEGIN',       'INT', 'tm.start', 'tm.start AS turbo_begin'             ],
      ['TURBO_END',         'STR', 'tm.start + interval tm.time second', 'tm.start + interval tm.time second AS turbo_end' ],
      ['JOIN_SERVICE',      'INT', 'c.join_service',                               1 ],
      ['NAS_IP',            'IP',  'c.nas_ip_address',  'c.nas_ip_address AS nas_ip' ],
      ['ACCT_SESSION_TIME', 'INT', 'UNIX_TIMESTAMP() - UNIX_TIMESTAMP(c.started) AS acct_session_time',1 ],
      ['FILTER_ID',         'STR', 'IF(internet.filter_id<>\'\', internet.filter_id, tp.filter_id) AS filter_id',  1 ],
      ['SESSION_START',     'INT', 'UNIX_TIMESTAMP(started) AS started_unixtime',  1 ],
      ['SERVICE_STATUS',    'INT', 'internet.disable', 'internet.disable AS service_status'],
      ['TP_BILLS_PRIORITY', 'INT', 'tp.bills_priority',                            1 ],
      ['TP_CREDIT',         'INT', 'tp.credit',             'tp.credit AS tp_credit' ],
      ['TP_MONTH_FEE',      'INT', 'tp.month_fee',    'tp.month_fee AS tp_month_fee' ],
      ['TP_DAY_FEE',        'INT', 'tp.day_fee',          'tp.day_fee AS tp_day_fee' ],
      ['TP_ABON_DISTRIBUTION', 'INT', 'tp.abon_distribution',   'tp.abon_distribution AS tp_abon_distribution' ],
      ['NAS_NAME',          'STR', 'nas.name',                'nas.name AS nas_name' ],
      ['PAYMENT_METHOD',    'INT', 'tp.payment_type',                              1 ],
      ['TP_CREDIT_TRESSHOLD','INT','tp.credit_tresshold',                          1 ],
      ['ACTIVATE',          'DATE','internet.activate',                             1 ],
      ['EXPIRED',           'DATE',"IF(u.expire>'0000-00-00' AND u.expire <= CURDATE(), 1, 0) AS expired", 1 ],
      ['EXPIRE',            'DATE','u.expire',                                     1 ],
      ['INTERNET_EXPIRED',        'DATE',"IF(internet.expire>'0000-00-00' AND internet.expire <= CURDATE(), 1, 0) AS internet_expired", 1 ],
      ['INTERNET_EXPIRE',         'DATE','internet.expire AS internet_expire',      1 ],
      ['IP',                'IP',  'internet.ip',       'INET_NTOA(internet.ip) AS ip' ],
      ['SIMULTANEONSLY',    'INT', 'internet.logins',                               1 ],
      ['PORT',              'INT', 'internet.port',                                 1 ],
      #['SERVICE_FILTER_ID', 'STR', 'internet.filter_id',                           1 ],
      ['INTERNET_STATUS',   'INT', 'internet.disable AS internet_status',           1 ],
      ['FRAMED_IP_ADDRESS', 'IP',  'c.framed_ip_address',                          1 ],
      ['HOSTNAME',          'STR', 'c.hostname',                                   1 ],
      ['SWITCH_PORT',       'STR', 'c.switch_port',                                1 ],
      ['VLAN',              'INT', 'c.vlan',                                       1 ],
      ['SERVER_VLAN',       'INT', 'c.server_vlan',                                1 ],
      ['SWITCH_MAC',        'STR', 'c.switch_mac',                                 1 ],
      ['SWITCH_NAME',       'STR', 'switch.name',      'CONCAT(switch.id,\' : \', switch.name) AS switch_name' ],
      ['SWITCH_ID',         'STR', 'switch.id',             'switch.id AS switch_id' ],
      ['DHCP_ID',           'INT', 'c.dhcp_id',                                    1 ],
      ['DHCP_ENDS',         'DATE','c.dhcp_ends',                                  1 ],
      ['REMOTE_ID',         'STR', 'c.remote_id',                                  1 ],
      ['CIRCUIT_ID',        'STR', 'c.circuit_id',                                 1 ],
      ['NAS_ID',            'INT', 'c.nas_id',                                     1 ],
      ['NAS_TYPE',          'INT', 'nas.nas_type',                                 1 ],
      ['CPE_MAC',           'STR', 'internet.cpe_mac',                              1 ],
      #['GID',               'INT', 'u.gid',                                        1 ],
      ['ACCT_SESSION_ID',   'STR', 'c.acct_session_id',                            1 ],
      ['SERVICE_ID',        'INT', 'c.service_id',                                 1 ],
      ['UID',               'INT', 'c.uid'                                           ],
      ['LAST_ALIVE',        'INT', 'UNIX_TIMESTAMP() - MIN(c.lupdated)', 'IF(UNIX_TIMESTAMP() > MIN(c.lupdated), UNIX_TIMESTAMP() - MIN(c.lupdated), 0) AS last_alive', 1 ],
      ['ONLINE_BASE',       '',    '', 'c.cid, c.acct_session_id, UNIX_TIMESTAMP() - c.lupdated AS last_alive, c.uid' ],
      ['SHOW_TP_ID',        'INT', 'tp.tp_id', 'tp.tp_id AS real_tp_id' ],
      ['TP_NUM',            'INT', 'tp.id   AS tp_num',                             1],
    ],
    {
      WHERE             => 1,
      WHERE_RULES       => \@WHERE_RULES,
      USERS_FIELDS      => 1,
      SKIP_USERS_FIELDS => [ 'UID', 'LOGIN', 'ACTIVATE', 'EXPIRE' ],
      USE_USER_PI       => 1
    }
  );

  foreach my $field ( keys %$attr ) {
    if (! $field) {
      print "internet_online/online: Wrong field name\n";
    }
    elsif ($field =~ /TP_BILLS_PRIORITY|TP_NAME|FILTER_ID|TP_CREDIT|PAYMENT_METHOD|SHOW_TP_ID|TP_NUM/ && $EXT_TABLE !~ /tarif_plans/) {
      $EXT_TABLE .= " LEFT JOIN tarif_plans tp ON (tp.tp_id=internet.tp_id)";
    }
    elsif ($field =~ /SWITCH_NAME|SWITCH_ID/ && $EXT_TABLE !~ m/ switch /) {
      $EXT_TABLE .= " LEFT JOIN nas AS switch ON (c.switch_mac <> '' AND c.switch_mac=switch.mac)";
    }
    elsif ($field =~ /NAS_NAME|NAS_TYPE/ && $EXT_TABLE !~ m/ nas ON /) {
      $EXT_TABLE .= " LEFT JOIN nas ON (nas.id=c.nas_id)";
    }
    elsif ($field =~ /TURBO_/ && $EXT_TABLE !~ m/ turbo_mode /) {
      $EXT_TABLE .= " LEFT JOIN turbo_mode tm ON (c.uid=tm.uid AND tm.start + interval tm.time second > c.started)";
    }
  }

  $EXT_TABLE .= $self->{EXT_TABLES} if ($self->{EXT_TABLES});

  delete $self->{COL_NAMES_ARR};

  #	my $sort_position = ($SORT-1 < 1) ? 1 : $SORT-1;
  #  if($self->{SEARCH_FIELDS_ARR}->[$sort_position] =~ /ip/) {
  #  	$SORT = " c.framed_ip_address+0";
  #  }
  my $LIMIT = '';
  my $PG = 0;

  if ($attr->{LIMIT} && $attr->{PAGE_ROWS}) {
    $PG = ($attr->{PG}) ? $attr->{PG} : 0;
    $LIMIT = " LIMIT $PG, $attr->{PAGE_ROWS} ";
  }

  if($self->{SORT_BY}) {
    $SORT = $self->{SORT_BY};
  }

  #       LEFT JOIN internet_main service ON (internet.id = c.service_id OR (c.service_id = 0 AND  internet.uid = c.uid))
  $self->query("SELECT $self->{SEARCH_FIELDS}
    c.uid,c.nas_id,c.acct_session_id,c.user_name
      FROM internet_online c
      LEFT JOIN users u ON (u.uid=c.uid)
      LEFT JOIN internet_main internet ON (internet.id = c.service_id)
      $EXT_TABLE
      $WHERE
      GROUP BY $GROUP_BY
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
    return $self->{list} || [];
  }

  my $list = $self->{list};
  foreach my $line (@$list) {
    push @{ $nas_sorted{$line->{nas_id}} }, $line ;
    if($CONF->{DHCP_LEASES_NAS} && $CONF->{DHCP_LEASES_NAS} eq $line->{nas_id}) {
      next;
    }

    $dub_logins{ $line->{user_name} }++ if ($line->{user_name});
    $dub_ports{ $line->{nas_id} }{ $line->{nas_port_id} }++ if ($line->{nas_port_id});
    if ($line->{client_ip} && ($line->{status} && ($line->{status}==1 || ($line->{status}>=3 && $line->{status}<11))) ) {
      $dub_ips{ $line->{nas_id} }{ $line->{client_ip} }++
    }
  }

  $self->{dub_ports}  = \%dub_ports;
  $self->{dub_logins} = \%dub_logins;
  $self->{dub_ips}    = \%dub_ips;
  $self->{nas_sorted} = \%nas_sorted;

  return $self->{list} || [];
}

#**********************************************************
=head2 online_join_services()

=cut
#**********************************************************
sub online_join_services {
  my $self = shift;

  $self->query(
    "SELECT  join_service,
   SUM(c.acct_input_octets) + 4294967296 * SUM(acct_input_gigawords),
   SUM(c.acct_output_octets) + 4294967296 * SUM(acct_output_gigawords)
 FROM internet_online c
 GROUP BY join_service;"
  );

  return $self->{list};
}

#**********************************************************
=head2 online_del($attr) - Del online session

  Arguments:
    $attr
      STATUS
      SESSIONS_LIST

  Return:
    True or FASE

=cut
#**********************************************************
sub online_del {
  my $self = shift;
  my ($attr) = @_;

  my $WHERE = '';

  if($attr->{STATUS}) {
    $WHERE = "status IN ( '$attr->{STATUS}' )";

    if ($attr->{QUICK}) {
      $self->query("DELETE FROM internet_online WHERE $WHERE;", 'do');
      return $self;
    }
  }
  elsif ($attr->{SESSIONS_LIST}) {
    my $session_list = join("', '", @{ $attr->{SESSIONS_LIST} });
    $WHERE = "acct_session_id IN ( '$session_list' )";

    if ($attr->{QUICK}) {
      $self->query("DELETE FROM internet_online WHERE $WHERE;", 'do');
      return $self;
    }
  }
  else {
    my $NAS_ID          = (defined($attr->{NAS_ID}))          ? $attr->{NAS_ID}          : '';
    #my $NAS_PORT        = (defined($attr->{NAS_PORT}))        ? $attr->{NAS_PORT}        : '';
    my $ACCT_SESSION_ID = (defined($attr->{ACCT_SESSION_ID})) ? $attr->{ACCT_SESSION_ID} : '';
    $WHERE = "nas_id='$NAS_ID'
            AND acct_session_id='$ACCT_SESSION_ID'";
  }

  $self->query("SELECT uid, user_name, started,
    IF(lupdated>0, SEC_TO_TIME(lupdated-UNIX_TIMESTAMP(started)), '00:00:00') AS duration, sum
    FROM internet_online WHERE $WHERE",
    undef,
    { COLS_NAME => 1 }
  );

  foreach my $line (@{ $self->{list} }) {
    $admin->action_add($line->{uid}, "START: $line->{started} DURATION: $line->{duration} SUM: $line->{sum}",
      { MODULE => 'Internet', TYPE => 13 }
    );
  }


  $self->query("DELETE FROM internet_online WHERE $WHERE;", 'do');

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
      ['NAS_ID',           'INT', 'c.nas_id'            ],
      ['NAS_IP_ADDRESS',   'IP',  'c.nas_ip_address'    ],
      ['NAS_PORT',         'INT', 'c.nas_port_id',      ],
      ['ACCT_SESSION_ID',  'STR', 'c.acct_session_id'   ],
      ['UID',              'INT', 'c.uid'               ],
      ['FRAMED_IP_ADDRESS','IP',  'c.framed_ip_address' ],
      ['CID',              'STR', 'c.cid'               ],
      ['GUEST',            'INT', 'c.guest'             ]
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
   c.cid AS calling_station_id,
   c.connect_info,
   c.acct_session_id,
   c.nas_id,
   c.started AS acct_session_started,
   c.acct_input_gigawords,
   c.acct_output_gigawords,
   IF(internet.filter_id != '', internet.filter_id, IF(tp.filter_id IS NULL, '', tp.filter_id)) AS filter_id,
   c.uid,
   c.guest
   FROM internet_online c
   LEFT JOIN internet_main internet ON (c.uid=internet.uid)
   LEFT JOIN tarif_plans tp ON (internet.tp_id=tp.tp_id)
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
  elsif (!$attr->{ALL}) {
    $WHERE = "WHERE nas_id='$nas_id'";
  }

  if($nas_port_id) {
    $WHERE .= " AND nas_port_id='$nas_port_id'";
  }

  if ($acct_session_id) {
    $WHERE .= " AND acct_session_id='$acct_session_id'";
  }

  $self->query('UPDATE internet_online SET status=2 ' . $WHERE .';', 'do');
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
  l.recv2 AS recv2,
  l.sent2 AS sent2,
  INET_NTOA(l.ip) AS ip,
  l.cid,
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
 FROM (internet_log l, users u)
 LEFT JOIN tarif_plans tp ON (l.tp_id=tp.tp_id)
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

  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;
  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 2;
  my $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';

  my $lupdate = '';

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
   FROM internet_log $WHERE;"
  );

  if ($self->{TOTAL} == 0) {
    return $self;
  }

  ($self->{sent_0}, $self->{recv_0}, $self->{duration_0}, $self->{sent_1}, $self->{recv_1}, $self->{duration_1},
    $self->{sent_2}, $self->{recv_2}, $self->{duration_2}, $self->{sent_3}, $self->{recv_3}, $self->{duration_3},
    $self->{sent_4}, $self->{recv_4}, $self->{duration_4}) =
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
    IF(internet.activate<>'0000-00-00', internet.activate, DATE_FORMAT(CURDATE(), '%Y-%m-01')) AS activate,
    tt.prepaid,
    u.id AS login,
    tp.octets_direction,
    u.uid,
    internet.tp_id,
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
  INNER JOIN internet_main internet ON (u.uid=internet.uid)
  INNER JOIN tarif_plans tp ON (internet.tp_id=tp.tp_id)
  INNER JOIN intervals i ON (tp.tp_id=i.tp_id)
  INNER JOIN trafic_tarifs tt ON (i.id=tt.interval_id)
WHERE
   u.uid= ? AND tt.prepaid > 0
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

  if ($CONF->{INTERNET_INTERVAL_PREPAID}) {
    $WHERE =~ s/l.start/li\.added/g;
    $uid =~ s/l.uid/li.uid/g;
    $self->query("SELECT li.traffic_type, SUM($octets_direction_interval) / $CONF->{MB_SIZE}, li.interval_id
       FROM internet_log_intervals li
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
     FROM internet_log l
     WHERE $uid AND l.tp_id='$self->{INFO_LIST}->[0]->{tp_id}' and
      (  $WHERE
        )
     GROUP BY $GROUP
     ;"
    );
  }

  if ($self->{TOTAL} > 0) {
    my ($class1, $class2) = (0, 0);

    if (! $CONF->{INTERNET_INTERVAL_PREPAID}) {
      $self->{INFO_LIST}->[0]->{prepaid} = 0;
      if ($prepaid_traffic{1}) { $self->{INFO_LIST}->[1]->{prepaid} = 0 }
    }

    foreach my $line (@{ $self->{list} }) {
      if ($CONF->{INTERNET_INTERVAL_PREPAID}) {
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
    if (! $CONF->{INTERNET_INTERVAL_PREPAID}) {
      $rest{0} = $class1;
      $rest{1} = $class2;
    }
  }

  if (! $CONF->{INTERNET_INTERVAL_PREPAID}) {
    #Check online
    $self->query("SELECT
       $rest{0} - SUM($octets_online_direction) / $CONF->{MB_SIZE},
       $rest{1} - SUM($octets_online_direction2) / $CONF->{MB_SIZE},
       1
     FROM internet_online l
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

  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;
  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 2;
  my $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';

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
      [ 'FRAMED_IPV6_PREFIX', 'IP', 'l.framed_ipv6_prefix',  'INET6_NTOA(l.framed_ipv6_prefix) AS framed_ipv6_prefix', 1 ],
      [ 'CID',             'STR', 'l.cid',                        1],
      [ 'TP_ID',           'INT', 'l.tp_id',                      1],
      [ 'TP_NUM',          'INT', 'tp.id   AS tp_num',            1],
      [ 'TP_NAME',         'STR', 'tp.name AS tp_name',           1],
      [ 'SUM',             'INT', 'l.sum',                        1],
      [ 'NAS_NAME',        'STR', 'n.name as nas_name',           1],
      [ 'NAS_ID',          'INT', 'l.nas_id',                     1],
      [ 'NAS_PORT',        'INT', 'l.port_id',                    1],
      [ 'ACCT_SESSION_ID', 'STR', 'l.acct_session_id',            1],
      [ 'TERMINATE_CAUSE', 'INT', 'l.terminate_cause',            1],
      [ 'BILL_ID',         'STR', 'l.bill_id',                    1],
      [ 'START_UNIXTIME',  'INT', 'UNIX_TIMESTAMP(l.start) AS start_unixtime', 1],
      [ 'FROM_DATE|TO_DATE','DATE',"DATE_FORMAT(l.start, '%Y-%m-%d')"],
      [ 'MONTH',           'DATE',"DATE_FORMAT(l.start, '%Y-%m')"    ],
      [ 'UID',             'INT', 'l.uid'                            ],
      [ 'GUEST',           'INT', 'l.guest',                      1]
    ],
    {
      WHERE             => 1,
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

  if ($self->{SEARCH_FIELDS} =~ /\s?u\.|pi\./ || $self->{SEARCH_FIELDS} =~ /company\.id/ || $WHERE =~ m/ u\.|pi\./) {
    $EXT_TABLE .= " INNER JOIN users u ON (u.uid=l.uid)";
  }

  if ($self->{SEARCH_FIELDS} =~ /nas_name/ && $EXT_TABLE !~ /nas/) {
    $EXT_TABLE .= " LEFT JOIN nas n ON (n.id=l.nas_id)";
  }

  if ($self->{SEARCH_FIELDS} =~ /tp_bills_priority|tp_name|filter_id|tp_credit|payment_method|show_tp_id|tp_num/ && $EXT_TABLE !~ /tarif_plans/) {
    $EXT_TABLE .= " LEFT JOIN tarif_plans tp ON (tp.tp_id=l.tp_id)";
  }

  $EXT_TABLE .= $self->{EXT_TABLES};
  $SORT = $self->{SEARCH_FIELDS_COUNT}+2 if ($SORT > $self->{SEARCH_FIELDS_COUNT}+2);

  $self->query("SELECT $self->{SEARCH_FIELDS} l.acct_session_id, l.uid
    FROM internet_log l
    $EXT_TABLE
    $WHERE
    $HAVING
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list};
  my $session_log_count = 0;
  if ($self->{TOTAL} > 0) {
    $self->query("SELECT COUNT(l.uid) AS total,
      SUM(l.duration) AS duration,
      SUM(l.sent + 4294967296 * acct_output_gigawords) AS traffic_in,
      SUM(l.recv + 4294967296 * acct_input_gigawords) AS traffic_out,
      SUM(l.sent2) AS traffic2_in,
      SUM(l.recv2) AS traffic2_out,
      SUM(sum) AS sum
    FROM internet_log l
    $EXT_TABLE
    $WHERE;",
      undef,
      { INFO => 1 }
    );
    $session_log_count = $self->{TOTAL};
  }

  #Calculate online sesisons too
  if($attr->{ONLINE}) {
    $self->query("SELECT
      sum(UNIX_TIMESTAMP() - UNIX_TIMESTAMP(l.started)) AS online_duration,
      SUM(l.acct_input_octets) + 4294967296 * SUM(acct_input_gigawords) AS online_traffic_in,
      SUM(l.acct_output_octets) + 4294967296 * SUM(acct_output_gigawords) AS online_traffic_out
    FROM internet_online l
    WHERE uid='$attr->{UID}'
    GROUP BY uid;",
      undef,
      { INFO => 1 }
    );

    $self->{TRAFFIC_IN} += $self->{ONLINE_TRAFFIC_OUT};
    $self->{TRAFFIC_OUT}+= $self->{ONLINE_TRAFFIC_IN};
    $self->{DURATION}   += $self->{ONLINE_DURATION};
  }

  $self->{TOTAL} = $session_log_count;
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

  my $period = $attr->{PERIOD} || 3;

  if ($attr->{INTERVAL}) {
    my ($from, $to) = split(/\//, $attr->{INTERVAL}, 2);
    push @WHERE_RULES, "DATE_FORMAT(start, '%Y-%m-%d')>='$from' and DATE_FORMAT(start, '%Y-%m-%d')<='$to'";
  }
  #Period
  elsif (defined($period)) {
    if    ($period == 0) { push @WHERE_RULES, "DATE_FORMAT(start, '%Y-%m-%d')=CURDATE()"; }
    elsif ($period == 1) { push @WHERE_RULES, "TO_DAYS(CURDATE()) - TO_DAYS(start) = 1 "; }
    elsif ($period == 2) { push @WHERE_RULES, "YEAR(CURDATE()) = YEAR(start) and (WEEK(CURDATE()) = WEEK(start)) "; }
    elsif ($period == 3) { push @WHERE_RULES, "DATE_FORMAT(start, '%Y-%m')=DATE_FORMAT(CURDATE(), '%Y-%m') "; }
    elsif ($period == 5) { push @WHERE_RULES, "DATE_FORMAT(start, '%Y-%m-%d')='$attr->{DATE}' "; }
  }

  my $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

  $self->query("SELECT
  MIN(l.duration) AS min_dur,
  MAX(l.duration) AS max_dur,
  AVG(l.duration) AS avg_dur,
  SUM(l.duration) AS total_dur,
  MIN(l.sent + 4294967296 * acct_output_gigawords) AS min_sent,
  MAX(l.sent + 4294967296 * acct_output_gigawords) AS max_sent,
  AVG(l.sent + 4294967296 * acct_output_gigawords) AS avg_sent,
  SUM(l.sent + 4294967296 * acct_output_gigawords) AS total_sent,
  MIN(l.recv + 4294967296 * acct_input_gigawords) AS min_recv,
  MAX(l.recv + 4294967296 * acct_input_gigawords) AS max_recv,
  AVG(l.recv + 4294967296 * acct_input_gigawords) AS avg_recv,
  SUM(l.recv + 4294967296 * acct_input_gigawords) AS total_recv,
  MIN(l.recv+l.sent) AS min_sum,
  MAX(l.recv+l.sent) AS max_sum,
  AVG(l.recv+l.sent) AS avg_sum,
  SUM(l.recv+l.sent) AS total_sum
  FROM internet_log l $WHERE",
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

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my @WHERE_RULES= ();
  my $date       = '';
  my $EXT_TABLES = '';
  my $ext_fields = ', u.company_id';

  my @FIELDS_ARR = ('DATE', 'USERS', 'USERS_FIO', 'TP', 'SESSIONS', 'TRAFFIC_SENT', 'TRAFFIC_RECV', 'TRAFFIC_SUM', 'TRAFFIC_2_SUM', 'DURATION', 'SUM',);

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
    TRAFFIC_SENT    => 'SUM(l.sent + 4294967296 * acct_output_gigawords)',
    TRAFFIC_RECV    => 'SUM(l.recv + 4294967296 * acct_input_gigawords)',
    USERS_COUNT     => 'COUNT(DISTINCT l.uid)',
    TP              => 'l.tp_id',
    COMPANIES       => 'c.name',
   };

  my $EXT_TABLE = 'users';

  if (defined($attr->{DATE})) {
    push @WHERE_RULES, " DATE_FORMAT(l.start, '%Y-%m-%d')='$attr->{DATE}'";
  }
  elsif ($attr->{INTERVAL}) {
    my ($from, $to) = split(/\//, $attr->{INTERVAL}, 2);
    push @WHERE_RULES, "DATE(l.start)<='$to' and DATE(l.start + INTERVAL l.duration SECOND)>='$from'";
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
       FROM internet_log l
       WHERE uid= ? AND $period
       GROUP BY uid;",
      undef,
      { INFO => 1, Bind => [ $attr->{UID} ] }
    );

    return $self;
  }

  if ($admin->{DOMAIN_ID}) {
    push @WHERE_RULES, @{ $self->search_expr($admin->{DOMAIN_ID}, 'INT', 'u.domain_id', { EXT_FIELD => 0 }) };
  }

  my $WHERE = $self->search_former($attr, [
      [ 'LOGIN',        'STR',  'u.id',   ],
      [ 'GID',          'INT',  'u.gid',  ],
      [ 'UID',          'INT',  'l.uid',  ],
      [ 'COMPANY_ID',   'INT',  'u.company_id' ],
      [ 'TP_ID',        'INT',  'l.tp_id' ],
      [ 'GUEST',        'INT',  'l.guest' ]
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
      FROM internet_log l
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
      FROM internet_log l
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
      FROM internet_log l
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
     FROM internet_log l
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

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG   = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

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
      ['COORDX',          'INT', 'builds.coordx',                                        1 ],
      ['COORDY',          'INT', 'builds.coordy',                                        1 ],
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
    }
    elsif ( $attr->{TYPE} eq 'DAYS' ){
      $main_field = "DATE_FORMAT(l.start, '%Y-%m-%d') AS date";
    }
    elsif ( $attr->{TYPE} eq 'TP' ){
      $main_field = "l.tp_id";
    }
    elsif ( $attr->{TYPE} eq 'TERMINATE_CAUSE' ){
      $main_field = "l.terminate_cause";
    }
    elsif ( $attr->{TYPE} eq 'GID' ){
      $main_field = "u.gid";
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
      $PAGE_ROWS = 1000;
    }
    elsif ( $attr->{TYPE} eq 'STREET' ){
      $main_field = "streets.name AS street_name";
      $self->{SEARCH_FIELDS} .= 'streets.id AS street_id,';
      $EXT_TABLE_JOINS_HASH{users} = 1;
      $EXT_TABLE_JOINS_HASH{users_pi} = 1;
      $EXT_TABLE_JOINS_HASH{builds} = 1;
      $EXT_TABLE_JOINS_HASH{streets} = 1;
      $PAGE_ROWS = 1000;
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

  if ( $attr->{USERS} || $attr->{DEPOSIT} || $attr->{GID} || $admin->{GID} ){
    $EXT_TABLE_JOINS_HASH{users} = 1;
  }

  my $EXT_TABLES = $self->mk_ext_tables( {
    JOIN_TABLES    => \%EXT_TABLE_JOINS_HASH,
    EXTRA_PRE_JOIN => [ 'users:INNER JOIN users u ON (u.uid=l.uid)',
    ]
  } );

  $self->query( "SELECT $main_field, $self->{SEARCH_FIELDS}
      l.uid
       FROM internet_log l
       $EXT_TABLES
       $WHERE2
       GROUP BY 1
       ORDER BY $SORT $DESC
       LIMIT $PG, $PAGE_ROWS;",
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
       FROM internet_log l
       $EXT_TABLES
       $WHERE2;",
    undef,
    { INFO => 1 }
  );
  
  $self->{TOTAL} = $self->{USERS};

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

  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;
  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 2;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

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
  FROM internet_log_intervals l
  $WHERE
  ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list};

  return $list;
}

#**********************************************************
=head2 log_rotate($attr) - Rotate internet logs

  Arguments:
    $attr
      DAILY

=cut
#**********************************************************
sub log_rotate{
  my $self = shift;
  my ($attr) = @_;

  my @rq = ();
  #TODO
  # Remove for partitioning

  if($CONF->{USE_PARTITIONING}) {
    return $self;
  }

  if (! $CONF->{CONNECT_LOG}) {
    push @rq, 'CREATE TABLE IF NOT EXISTS errors_log_new LIKE errors_log;',
      #'CREATE TABLE IF NOT EXISTS errors_log_new_sorted LIKE errors_log;',
      'RENAME TABLE errors_log TO errors_log_old, errors_log_new TO errors_log;',
      #'INSERT INTO errors_log_new_sorted SELECT max(date), log_type, action, user, message, nas_id FROM errors_log_old GROUP BY user ORDER BY 1;'
      ,
      'DROP TABLE errors_log_old;',
      #'INSERT INTO errors_log_new_sorted SELECT max(date), log_type, action, user, message, nas_id FROM errors_log GROUP BY user;'
      ,
      #'RENAME TABLE errors_log TO errors_log_old, errors_log_new_sorted TO errors_log;',
      #'DROP TABLE errors_log_old;'
    ;
  }

  if (!$attr->{DAILY}) {
    use POSIX qw(strftime);
    my $DATE = (POSIX::strftime("%Y_%m_%d", localtime(time - 86400)));
    push @rq,
      'CREATE TABLE IF NOT EXISTS s_detail_new LIKE s_detail;',
      'RENAME TABLE s_detail TO s_detail_' . $DATE . ', s_detail_new TO s_detail;',

#      'CREATE TABLE IF NOT EXISTS errors_log_new LIKE errors_log;',
#      'RENAME TABLE errors_log TO errors_log_'. $DATE .
#        ', errors_log_new TO errors_log;',
      'CREATE TABLE IF NOT EXISTS internet_log_intervals_new LIKE internet_log_intervals;',
      'DROP TABLE internet_log_intervals_old',
      'RENAME TABLE internet_log_intervals TO internet_log_intervals_old, internet_log_intervals_new TO internet_log_intervals;';

    if ($CONF->{INTERNET_INTERVAL_PREPAID}) {
      push @rq,
        'INSERT INTO internet_log_intervals SELECT * FROM internet_log_intervals_old WHERE added>=UNIX_TIMESTAMP()-86400*31;';
    }
  }

  foreach my $query (@rq) {
    $self->query($query, 'do');
  }

  return $self;
}

#**********************************************************
=head2 users_online_count_by_builds() - show users online count by builds

=cut
#**********************************************************
sub users_online_count_by_builds {
  my ($self, $attr) = @_;
  my $WHERE = '';

  if ($attr->{GUEST}) {
    $WHERE = qq{WHERE pi.uid IN ( SELECT uid FROM internet_online WHERE guest>0)};
  }
  else {
    $WHERE = qq{WHERE pi.uid IN ( SELECT uid FROM internet_online WHERE guest=0)};
  }
  $self->query("SELECT b.id, COUNT(pi.uid) as online_count
    FROM builds b
      LEFT JOIN users_pi pi ON (b.id = pi.location_id)
    $WHERE
    GROUP BY b.id",
    undef,
    {
      COLS_NAME => 1,
      %{ $attr // {} }
    }
  );
  
  return $self->{list} || [];
}

#**********************************************************
=head2 session_sum ($attr) - Show session sum from previus mouth

  Arguments:
    $attr:
    FROM_DATE
    TO_DATE

  Result:

=cut
#**********************************************************
sub session_sum {
  my $self = shift;
  my ($attr) = @_;

  my @WHERE_RULES = ("il.sum > 0");
  my $WHERE = $self->search_former(
    $attr,
    [
      [ 'FROM_DATE|TO_DATE', 'DATE', "DATE_FORMAT(il.start, \'%Y-%m-%d\')",  1 ],
    ],
    {
      WHERE       => 1,
      WHERE_RULES => \@WHERE_RULES,
    }
  );

  $self->query("
    SELECT
      uid,
      bill_id,
      SUM(sum) AS sum,
      SUM(sent) AS sent,
      SUM(recv) AS received
      FROM internet_log il
      $WHERE
      GROUP BY uid;",
    undef, $attr
  );

  return $self->{list};

}

1
