package Sharing;

=head1 NAME

 Sharing module DB functions

=cut

use strict;
use parent qw(dbcore);

my $MODULE = 'Sharing';

my ($admin, $CONF);

#**********************************************************
# Init
#**********************************************************
sub new {
  my $class = shift;
  my $db = shift;
  ($admin, $CONF) = @_;
  my $self = {};
  bless($self, $class);

  $admin->{MODULE} = $MODULE;

  $self->{db} = $db;
  $self->{admin} = $admin;
  $self->{conf} = $CONF;

  if ($CONF->{DELETE_USER}) {
    $self->del({ UID => $CONF->{DELETE_USER}, DELETE_USER => $CONF->{DELETE_USER} });
  }

  return $self;
}

#**********************************************************
# del
#**********************************************************
sub session_del {
  my $self = shift;
  my ($attr) = @_;

  if ($attr->{DELETE_USER}) {
    $self->query("DELETE FROM sharing_log WHERE uid='" . $attr->{DELETE_USER} . "';", 'do');
  }
  else {
    $self->query("DELETE FROM sharing_log
     WHERE start='$attr->{START}' and username='$attr->{USER_NAME}' and url='$attr->{FILE}';", 'do'
    );
  }

  return $self;
}

#**********************************************************
# online()
#**********************************************************
sub online_update {
  my $self = shift;
  my ($attr) = @_;

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

  my $SET = ($#SET_RULES > -1) ? join(', ', @SET_RULES) : '';

  $self->query("UPDATE sharing_calls SET $SET
   WHERE
    user_name='$attr->{USER_NAME}'
    and acct_session_id='$attr->{ACCT_SESSION_ID}'; ", 'do'
  );

  return $self;
}

#**********************************************************
# online()
#**********************************************************
sub online {
  my $self = shift;
  my ($attr) = @_;

  my @FIELDS_ALL = (
    'c.user_name',
    'pi.fio',
    'c.nas_port_id',
    'c.framed_ip_address',
    'SEC_TO_TIME(UNIX_TIMESTAMP() - UNIX_TIMESTAMP(c.started))',

    'c.acct_input_octets', 'c.acct_output_octets', 'c.ex_input_octets', 'c.ex_output_octets',

    'c.CID',
    'c.acct_session_id',
    'sharing.tp_id',
    'c.CONNECT_INFO',
    'sharing.speed',
    'c.sum',
    'c.status',

    'pi.phone',
    'INET_NTOA(c.framed_ip_address)',
    'u.uid',
    'INET_NTOA(c.nas_ip_address)',
    'if(company.name IS NULL, b.deposit, cb.deposit)',
    'u.credit',
    'if(date_format(c.started, "%Y-%m-%d")=curdate(), date_format(c.started, "%H:%i:%s"), c.started)',
    'c.nas_id',
    'UNIX_TIMESTAMP()-c.lupdated',
    'c.acct_session_time',
    'c.lupdated - UNIX_TIMESTAMP(c.started)'
  );

  my @RES_FIELDS = (0, 1, 2, 3, 4, 5, 6, 7, 8);

  if ($attr->{FIELDS}) {
    @RES_FIELDS = @{$attr->{FIELDS}};
  }

  my $fields = '';
  my $port_id = 0;
  for (my $i = 0; $i <= $#RES_FIELDS; $i++) {
    $port_id = $i if ($RES_FIELDS[$i] == 2);
    $fields .= "$FIELDS_ALL[$RES_FIELDS[$i]], ";
  }

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  my @WHERE_RULES = ();

  if (defined($attr->{ZAPED})) {
    push @WHERE_RULES, "c.status=2";
  }
  elsif ($attr->{ALL}) {

  }
  else {
    push @WHERE_RULES, "(c.status=1 or c.status>=3)";
  }

  if (defined($attr->{USER_NAME})) {
    push @WHERE_RULES, "c.user_name='$attr->{USER_NAME}'";
  }

  # Show groups
  if ($attr->{GIDS}) {
    push @WHERE_RULES, "u.gid IN ($attr->{GIDS})";
  }
  elsif ($attr->{GID}) {
    push @WHERE_RULES, "u.gid='$attr->{GID}'";
  }

  if (defined($attr->{FRAMED_IP_ADDRESS})) {
    push @WHERE_RULES, "framed_ip_address=INET_ATON('$attr->{FRAMED_IP_ADDRESS}')";
  }

  if (defined($attr->{NAS_ID})) {
    push @WHERE_RULES, "nas_id='$attr->{NAS_ID}'";
  }

  if ($attr->{FILTER}) {
    push @WHERE_RULES, "$FIELDS_ALL[$attr->{FILTER_FIELD}]='$attr->{FILTER}'";
  }

  my $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

  $self->query("SELECT  $fields
   pi.phone,
   INET_NTOA(c.framed_ip_address),
   u.uid,
   INET_NTOA(c.nas_ip_address),
   if(company.name IS NULL, b.deposit, cb.deposit),
   u.credit,
   if(date_format(c.started, '%Y-%m-%d')=curdate(), date_format(c.started, '%H:%i:%s'), c.started),
   UNIX_TIMESTAMP()-c.lupdated,
   c.status,
   c.nas_id,
   c.user_name,
   c.nas_port_id,
   c.acct_session_id,
   c.CID,
   sharing.tp_id

 FROM sharing_calls c
 LEFT JOIN users u     ON (u.id=user_name)
 LEFT JOIN sharing_main dv  ON (sharing.uid=u.uid)
 LEFT JOIN users_pi pi ON (pi.uid=u.uid)

 LEFT JOIN bills b ON (u.bill_id=b.id)
 LEFT JOIN companies company ON (u.company_id=company.id)
 LEFT JOIN bills cb ON (company.bill_id=cb.id)

 $WHERE
 ORDER BY $SORT $DESC;"
  );

  my %dub_logins = ();
  my %dub_ports = ();
  my %nas_sorted = ();

  if ($self->{TOTAL} < 1) {
    $self->{dub_ports} = \%dub_ports;
    $self->{dub_logins} = \%dub_logins;
    $self->{nas_sorted} = \%nas_sorted;

    return $self->{list};
  }

  my $list = $self->{list};

  my $nas_id_field = $#RES_FIELDS + 10;

  foreach my $line (@{$list}) {

    $dub_logins{ $line->[0] }++;
    $dub_ports{ $line->[$nas_id_field] }{ $line->[$port_id] }++;

    my @fields = ();
    for (my $i = 0; $i <= $#RES_FIELDS + 15; $i++) {
      push @fields, $line->[$i];
    }

    push(@{$nas_sorted{"$line->[$nas_id_field]"}}, [ @fields ]);

  }

  $self->{dub_ports} = \%dub_ports;
  $self->{dub_logins} = \%dub_logins;
  $self->{nas_sorted} = \%nas_sorted;

  return $self->{list};
}

#**********************************************************
# online_del()
#**********************************************************
sub online_del {
  my $self = shift;
  my ($attr) = @_;

  my $WHERE = '';
  if ($attr->{SESSIONS_LIST}) {
    my $session_list = join("', '", @{$attr->{SESSIONS_LIST}});
    $WHERE = "acct_session_id in ( '$session_list' )";
  }
  else {
    my $NAS_ID = (defined($attr->{NAS_ID})) ? $attr->{NAS_ID} : '';
    my $NAS_PORT = (defined($attr->{NAS_PORT})) ? $attr->{NAS_PORT} : '';
    my $ACCT_SESSION_ID = (defined($attr->{ACCT_SESSION_ID})) ? $attr->{ACCT_SESSION_ID} : '';
    $WHERE = "nas_id='$NAS_ID'
            and nas_port_id='$NAS_PORT'
            and acct_session_id='$ACCT_SESSION_ID'";
  }

  $self->query("DELETE FROM sharing_calls WHERE $WHERE;", 'do');

  return $self;
}

#**********************************************************
# Add online session to log
# online2log()
#
#**********************************************************
sub online2log {
  my $self = shift;

  $self->query("SELECT c.user_name, ", 'do');
}

#**********************************************************
# Add online session to log
# online2log()
#**********************************************************
sub online_info {
  my $self = shift;
  my ($attr) = @_;

  my @WHERE_RULES = ();

  if ($attr->{NAS_ID}) {
    push @WHERE_RULES, "nas_id='$attr->{NAS_ID}'";
  }
  elsif (defined($attr->{NAS_IP_ADDRESS})) {
    push @WHERE_RULES, "nas_ip_address=INET_ATON('$attr->{NAS_IP_ADDRESS}')";
  }

  if (defined($attr->{NAS_PORT})) {
    push @WHERE_RULES, "nas_port_id='$attr->{NAS_PORT}'";
  }

  if (defined($attr->{ACCT_SESSION_ID})) {
    push @WHERE_RULES, "acct_session_id='$attr->{ACCT_SESSION_ID}'";
  }

  my $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

  $self->query("SELECT user_name, UNIX_TIMESTAMP(started), acct_session_time,
   acct_input_octets,
   acct_output_octets,
   ex_input_octets,
   ex_output_octets,
   connect_term_reason,
   INET_NTOA(framed_ip_address),
   lupdated,
   nas_port_id,
   INET_NTOA(nas_ip_address),
      CID,
      CONNECT_INFO,
      acct_session_id,
      nas_id,
      started
      FROM sharing_calls
   $WHERE
   "
  );

  if ($self->{TOTAL} < 1) {
    $self->{errno} = 2;
    $self->{errstr} = 'ERROR_NOT_EXIST';
    return $self;
  }

  (
    $self->{USER_NAME}, $self->{SESSION_START}, $self->{ACCT_SESSION_TIME}, $self->{ACCT_INPUT_OCTETS},
    $self->{ACCT_OUTPUT_OCTETS}, $self->{ACCT_EX_INPUT_OCTETS}, $self->{ACCT_EX_OUTPUT_OCTETS},
    $self->{CONNECT_TERM_REASON}, $self->{FRAMED_IP_ADDRESS},
    $self->{LAST_UPDATE}, $self->{NAS_PORT}, $self->{NAS_IP_ADDRESS}, $self->{CALLING_STATION_ID}, $self->{CONNECT_INFO}
    , $self->{ACCT_SESSION_ID}, $self->{NAS_ID}, $self->{ACCT_SESSION_STARTED}
  ) = @{$self->{list}->[0]};

  return $self;
}

#**********************************************************
# Session zap
#**********************************************************
sub zap {
  my $self = shift;
  my ($nas_id, $nas_port_id, $acct_session_id, $attr) = @_;

  my $WHERE = '';

  if (!defined($attr->{ALL})) {
    $WHERE = "WHERE nas_id='$nas_id' and nas_port_id='$nas_port_id' and acct_session_id='$acct_session_id'";
  }

  $self->query("UPDATE sharing_calls SET status='2' $WHERE;", 'do');
  return $self;
}

#**********************************************************
# Session detail
#**********************************************************
sub session_detail {
  my $self = shift;
  my ($attr) = @_;

  my $WHERE = q{};
  $WHERE = " and l.uid='$attr->{UID}'" if ($attr->{UID});

  $self->query("SELECT
  l.start,
  l.start + INTERVAL l.duration SECOND,
  l.duration,
  l.tp_id,
  tp.name,

  l.sent,
  l.recv,
  l.sent2,
  l.recv2,

  INET_NTOA(l.ip),
  l.CID,
  l.nas_id,
  n.name,
  n.ip,
  l.port_id,

  l.minp,
  l.kb,
  l.sum,

  l.bill_id,
  u.id,

  l.uid,
  l.acct_session_id,
  l.terminate_cause
 FROM (sharing_log l, users u)
 LEFT JOIN tarif_plans tp ON (l.tp_id=tp.id)
 LEFT JOIN nas n ON (l.nas_id=n.id)
 WHERE l.uid=u.uid
 $WHERE
 and acct_session_id='$attr->{SESSION_ID}';"
  );

  if ($self->{TOTAL} < 1) {
    $self->{errno} = 2;
    $self->{errstr} = 'ERROR_NOT_EXIST';
    return $self;
  }

  my $ar = $self->{list}->[0];

  (
    $self->{START},
    $self->{STOP},
    $self->{DURATION},
    $self->{TP_ID},
    $self->{TP_NAME},
    $self->{SENT},
    $self->{RECV},
    $self->{SENT2}, #?
    $self->{RECV2}, #?
    $self->{IP},
    $self->{CID},
    $self->{NAS_ID},
    $self->{NAS_NAME},
    $self->{NAS_IP},
    $self->{NAS_PORT},

    $self->{TIME_TARIFF},
    $self->{TRAF_TARIFF},
    $self->{SUM},

    $self->{BILL_ID},
    $self->{LOGIN},

    $self->{UID},
    $self->{SESSION_ID},
    $self->{ACCT_TERMINATE_CAUSE}
  ) = @{$ar};

  return $self;
}

#**********************************************************
# Periods totals
# periods_totals($self, $attr);
#**********************************************************
sub periods_totals {
  my $self = shift;
  my ($attr) = @_;

  my $WHERE = '';

  if ($attr->{LOGIN}) {
    $WHERE .= "WHERE username='$attr->{LOGIN}' ";
  }

  $self->query("SELECT
   SUM(if(date_format(start, '%Y-%m-%d')=curdate(), sent, 0)),
   SUM(if(date_format(start, '%Y-%m-%d')=curdate(), recv, 0)),
   SEC_TO_TIME(SUM(if(date_format(start, '%Y-%m-%d')=curdate(), duration, 0))),
   SUM(if(TO_DAYS(curdate()) - TO_DAYS(start) = 1, sent, 0)),
   SUM(if(TO_DAYS(curdate()) - TO_DAYS(start) = 1, recv, 0)),
   SEC_TO_TIME(SUM(if(TO_DAYS(curdate()) - TO_DAYS(start) = 1, duration, 0))),

   SUM(if((YEAR(curdate())=YEAR(start)) and (WEEK(curdate()) = WEEK(start)), sent, 0)),
   SUM(if((YEAR(curdate())=YEAR(start)) and  WEEK(curdate()) = WEEK(start), recv, 0)),
   SEC_TO_TIME(SUM(if((YEAR(curdate())=YEAR(start)) and WEEK(curdate()) = WEEK(start), duration, 0))),

   SUM(if(date_format(start, '%Y-%m')=date_format(curdate(), '%Y-%m'), sent, 0)),
   SUM(if(date_format(start, '%Y-%m')=date_format(curdate(), '%Y-%m'), recv, 0)),
   SEC_TO_TIME(SUM(if(date_format(start, '%Y-%m')=date_format(curdate(), '%Y-%m'), duration, 0))),

   SUM(sent), SUM(recv), SEC_TO_TIME(SUM(duration))
   FROM (sharing_log sl)
   LEFT join  sharing_priority sp ON (sl.url = sp.file)
   $WHERE;"
  );

  ($self->{sent_0}, $self->{recv_0}, $self->{duration_0}, $self->{sent_1}, $self->{recv_1}, $self->{duration_1},
    $self->{sent_2}, $self->{recv_2}, $self->{duration_2}, $self->{sent_3}, $self->{recv_3}, $self->{duration_3},
    $self->{sent_4}, $self->{recv_4}, $self->{duration_4}) =
    @{$self->{list}->[0]};

  for (my $i = 0; $i < 5; $i++) {
    $self->{ 'sum_' . $i } = $self->{ 'sent_' . $i } + $self->{ 'recv_' . $i };
  }

  return $self;
}

#**********************************************************
#
#**********************************************************
sub prepaid_rest {
  my $self = shift;
  my ($attr) = @_;

  $CONF->{MB_SIZE} = $CONF->{KBYTE_SIZE} * $CONF->{KBYTE_SIZE};

  #Get User TP and intervals
  $self->query("select tt.id,
    if(u.activate<>'0000-00-00', u.activate, DATE_FORMAT(curdate(), '%Y-%m-01')),
     tt.prepaid,
     u.id,
     tp.octets_direction,
     u.uid,
     sm.tp_id,
     tp.name,
     tp.month_traf_limit,
     sm.extra_byte,
     COUNT(sa.tp_id)
  from (users u,
        sharing_main sm,
        tarif_plans tp,
        sharing_trafic_tarifs tt
        )
  LEFT JOIN sharing_additions sa ON (tp.id=sa.tp_id)
 WHERE
     u.uid=sm.uid
 and sm.tp_id=tp.id
 and tp.id=tt.tp_id
 and u.uid='$attr->{UID}'
 and tp.module='Sharing'
 GROUP BY 1
 ORDER BY 1

 "
  );

  if ($self->{TOTAL} < 1) {
    return 1;
  }

  my %rest = (
    0 => 0,
    1 => 0
  );

  foreach my $line (@{$self->{list}}) {
    $rest{ $line->[0] } = $line->[2];
  }

  $self->{INFO_LIST} = $self->{list};
  my $login = $self->{INFO_LIST}->[0]->[3];

  return 1 if ($attr->{INFO_ONLY});

  $self->{EXTRA_TRAFIC} = $self->{INFO_LIST}->[0]->[9];
  $self->{EXTRA_TRAFIC_USE} = $self->{INFO_LIST}->[0]->[10];

  #Check sessions
  #Get using traffic
  $self->query("select
  $rest{0} - SUM(sl.recv + sl.sent) / $CONF->{MB_SIZE}
 FROM sharing_log sl
 INNER JOIN sharing_priority sp ON (sl.url = sp.file)
 WHERE sl.username='$login'
 and DATE_FORMAT(sl.start, '%Y-%m-%d')>='$self->{INFO_LIST}->[0]->[1]'
 and sp.priority='0'
 GROUP BY sl.username
 ;"
  );

  if ($self->{TOTAL} > 0) {
    ($rest{0},) = @{$self->{list}->[0]};
  }

  if ($self->{EXTRA_TRAFIC_USE} > 0 && $rest{0} < 0) {
    $self->{EXTRA_TRAFIC} = $self->{EXTRA_TRAFIC} - abs($rest{0});
  }

  #else {
  #  $self->{EXTRA_TRAFIC}=undef;
  #}

  $self->{REST} = \%rest;

  return 1;
}

#**********************************************************
# session calculation
# min max average
#**********************************************************
sub calculation {
  my ($self) = shift;
  my ($attr) = @_;

  my @WHERE_RULES = ();

  #Login
  if ($attr->{UID}) {
    push @WHERE_RULES, "l.uid='$attr->{UID}'";
  }

  if ($attr->{INTERVAL}) {
    my ($from, $to) = split(/\//, $attr->{INTERVAL}, 2);
    push @WHERE_RULES, "date_format(start, '%Y-%m-%d')>='$from' and date_format(start, '%Y-%m-%d')<='$to'";
  }

  #Period
  elsif (defined($attr->{PERIOD})) {
    my $period = int($attr->{PERIOD});
    if ($period == 4) {

    }
    else {
      if ($period == 0) {push @WHERE_RULES, "date_format(start, '%Y-%m-%d')=curdate()";}
      elsif ($period == 1) {push @WHERE_RULES, "TO_DAYS(curdate()) - TO_DAYS(start) = 1 ";}
      elsif ($period == 2) {push @WHERE_RULES, "YEAR(curdate()) = YEAR(start) and (WEEK(curdate()) = WEEK(start)) ";}
      elsif ($period == 3) {push @WHERE_RULES, "date_format(start, '%Y-%m')=date_format(curdate(), '%Y-%m') ";}
      elsif ($period == 5) {push @WHERE_RULES, "date_format(start, '%Y-%m-%d')='$attr->{DATE}' ";}
    }
  }

  my $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

  $self->query("SELECT
  SEC_TO_TIME(min(l.duration)), SEC_TO_TIME(max(l.duration)), SEC_TO_TIME(avg(l.duration)), SEC_TO_TIME(SUM(l.duration)),
  min(l.sent), max(l.sent), avg(l.sent), SUM(l.sent),
  min(l.recv), max(l.recv), avg(l.recv), SUM(l.recv),
  min(l.recv+l.sent), max(l.recv+l.sent), avg(l.recv+l.sent), SUM(l.recv+l.sent)
  FROM sharing_log l $WHERE"
  );

  my $ar = $self->{list}->[0];

  (
    $self->{min_dur},
    $self->{max_dur},
    $self->{avg_dur},
    $self->{total_dur},

    $self->{min_sent},
    $self->{max_sent},
    $self->{avg_sent},
    $self->{total_sent},

    $self->{min_recv},
    $self->{max_recv},
    $self->{avg_recv},
    $self->{total_recv},

    $self->{min_sum},
    $self->{max_sum},
    $self->{avg_sum},
    $self->{total_sum}
  ) = @{$ar};

  return $self;
}

#**********************************************************
# Use
#**********************************************************
sub reports {
  my ($self) = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  my @WHERE_RULES = ();

  my $date = '';

  my @FIELDS_ARR = ('DATE', 'USERS', 'SESSIONS', 'TRAFFIC_RECV', 'TRAFFIC_SENT', 'TRAFFIC_SUM', 'TRAFFIC_2_SUM',
    'DURATION', 'SUM');

  $self->{REPORT_FIELDS} = {
    DATE          => '',
    USERS         => 'u.id',
    SESSIONS      => 'COUNT(l.uid)',
    TRAFFIC_SUM   => 'SUM(l.sent + l.recv)',
    TRAFFIC_2_SUM => 'SUM(l.sent2 + l.recv2)',
    DURATION      => 'sec_to_time(SUM(l.duration))',
    SUM           => 'SUM(l.sum)',
    TRAFFIC_RECV  => 'SUM(l.recv)',
    TRAFFIC_SENT  => 'SUM(l.sent)'
  };

  if ($attr->{GID}) {
    push @WHERE_RULES, "u.gid='$attr->{GID}'";
  }

  if (defined($attr->{DATE})) {
    push @WHERE_RULES, " date_format(l.start, '%Y-%m-%d')='$attr->{DATE}'";
  }
  elsif ($attr->{INTERVAL}) {
    my ($from, $to) = split(/\//, $attr->{INTERVAL}, 2);
    push @WHERE_RULES, "date_format(l.start, '%Y-%m-%d')>='$from' and date_format(l.start, '%Y-%m-%d')<='$to'";
    if ($attr->{TYPE} eq 'HOURS') {
      $date = "date_format(l.start, '%H')";
    }
    elsif ($attr->{TYPE} eq 'DAYS') {
      $date = "date_format(l.start, '%Y-%m-%d')";
    }
    else {
      $date = "u.id";
    }
  }
  elsif (defined($attr->{MONTH})) {
    push @WHERE_RULES, "date_format(l.start, '%Y-%m')='$attr->{MONTH}'";
    $date = "date_format(l.start, '%Y-%m-%d')";
  }
  else {
    $date = "date_format(l.start, '%Y-%m')";
  }

  if ($attr->{GID}) {
    push @WHERE_RULES, "u.gid='$attr->{GID}'";
  }

  my $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

  $self->{REPORT_FIELDS}{DATE} = $date;
  my $fields = "$date, COUNT(DISTINCT l.uid),
      COUNT(l.uid),
      SUM(l.sent + l.recv),
      SUM(l.sent2 + l.recv2),
      sec_to_time(SUM(l.duration)),
      SUM(l.sum)";

  if ($attr->{FIELDS}) {
    my @fields_array = split(/, /, $attr->{FIELDS});
    my @show_fields = ();
    my %get_fields_hash = ();

    foreach my $line (@fields_array) {
      $get_fields_hash{$line} = 1;
    }

    foreach my $k (@FIELDS_ARR) {
      push @show_fields, $self->{REPORT_FIELDS}{$k} if ($get_fields_hash{$k});
    }

    $fields = join(', ', @show_fields);
  }

  if (defined($attr->{DATE})) {
    if (defined($attr->{HOURS})) {
      $self->query("select date_format(l.start, '%Y-%m-%d %H')start, '%Y-%m-%d %H')start, '%Y-%m-%d %H'), COUNT(DISTINCT l.uid), COUNT(l.uid),
    SUM(l.sent + l.recv), SUM(l.sent2 + l.recv2), sec_to_time(SUM(l.duration)), SUM(l.sum), l.uid
      FROM sharing_log l
      LEFT JOIN users u ON (u.uid=l.uid)
      $WHERE
      GROUP BY 1
      ORDER BY $SORT $DESC"
      );
    }
    else {
      $self->query("select date_format(l.start, '%Y-%m-%d'), if(u.id is NULL, CONCAT('> ', l.uid, ' <'), u.id), COUNT(l.uid),
    SUM(l.sent + l.recv), SUM(l.sent2 + l.recv2), sec_to_time(SUM(l.duration)), SUM(l.sum), l.uid
      FROM sharing_log l
      LEFT JOIN users u ON (u.uid=l.uid)
      $WHERE
      GROUP BY l.uid
      ORDER BY $SORT $DESC"
      );
    }
  }
  else {
    $self->query("select $fields,
      l.uid
       FROM sharing_log l
       LEFT JOIN users u ON (u.uid=l.uid)
       $WHERE
       GROUP BY 1
       ORDER BY $SORT $DESC;"
    );
  }

  my $list = $self->{list};

  $self->{USERS} = 0;
  $self->{SESSIONS} = 0;
  $self->{TRAFFIC} = 0;
  $self->{TRAFFIC_2} = 0;
  $self->{DURATION} = 0;
  $self->{SUM} = 0;

  return $list if ($self->{TOTAL} < 1);

  $self->query("select COUNT(DISTINCT l.uid),
      COUNT(l.uid),
      SUM(l.sent + l.recv),
      SUM(l.sent2 + l.recv2),
      sec_to_time(SUM(l.duration)),
      SUM(l.sum)
       FROM sharing_log l
       LEFT JOIN users u ON (u.uid=l.uid)
       $WHERE;"
  );

  ($self->{USERS}, $self->{SESSIONS}, $self->{TRAFFIC}, $self->{TRAFFIC_2}, $self->{DURATION},
    $self->{SUM}) = @{$self->{list}->[0]};

  return $list;
}

#**********************************************************
# User information
# info()
#**********************************************************
sub samba_info {
  my $self = shift;
  my ($attr) = @_;

  $self->query("SELECT *
     FROM user
   WHERE username='$attr->{LOGIN}';"
  );

  return $self;
}

#**********************************************************
# User information
# info()
#**********************************************************
sub info {
  my $self = shift;
  my ($uid, $attr) = @_;

  my $WHERE = '';

  if (defined($attr->{LOGIN})) {
    use Users;
    my $users = Users->new($self->{db}, $admin, $CONF);
    $users->info(0, { LOGIN => "$attr->{LOGIN}" });
    if ($users->{errno}) {
      $self->{errno} = 2;
      $self->{errstr} = 'ERROR_NOT_EXIST';
      return $self;
    }

    $uid = $users->{UID};
    $self->{DEPOSIT} = $users->{DEPOSIT};
    $self->{ACCOUNT_ACTIVATE} = $users->{ACTIVATE};
    $WHERE = "WHERE sharing.uid='$uid'";
  }

  $WHERE = "WHERE sharing.uid='$uid'";

  if (defined($attr->{IP})) {
    $WHERE = "WHERE sharing.ip=INET_ATON('$attr->{IP}')";
  }

  $self->query("SELECT sharing.uid,
   sharing.tp_id,
   tp.name,
   sharing.logins,
   sharing.speed,
   sharing.filter_id,
   sharing.cid,
   sharing.disable,
   sharing.type,
   tp.gid,
   sharing.extra_byte
     FROM sharing_main sharing
     LEFT JOIN tarif_plans tp ON (sharing.tp_id=tp.id and tp.module='Sharing')
   $WHERE;"
  );

  $self->{TP_GID} = 0;

  if ($self->{TOTAL} < 1) {
    $self->{errno} = 2;
    $self->{errstr} = 'ERROR_NOT_EXIST';
    return $self;
  }

  ($self->{UID}, $self->{TP_ID}, $self->{TP_NAME}, $self->{SIMULTANEONSLY}, $self->{SPEED}, $self->{FILTER_ID},
    $self->{CID}, $self->{DISABLE}, $self->{TYPE}, $self->{TP_GID}, $self->{EXTRA_TRAFIC}) = @{$self->{list}->[0]};

  return $self;
}

#**********************************************************
#
#**********************************************************
sub defaults {
  my $self = shift;

  my %DATA = (
    TP_ID          => 0,
    SIMULTANEONSLY => 0,
    DISABLE        => 0,
    IP             => '0.0.0.0',
    NETMASK        => '255.255.255.255',
    SPEED          => 0,
    FILTER_ID      => '',
    CID            => '',
    TYPE           => 0
  );

  foreach my $key (keys %DATA) {
    $self->{$key} = $DATA{$key};
  }

  return $self;
}

#**********************************************************
# add()
#**********************************************************
sub add {
  my $self = shift;
  my ($attr) = @_;

  my %DATA = $self->get_data($attr, { default => defaults() });

  if ($DATA{TP_ID} > 0) {
    my $tariffs = Tariffs->new($self->{db}, $CONF, $admin);
    $tariffs->info($DATA{TP_ID});
    if ($tariffs->{ACTIV_PRICE} > 0) {
      my $user = Users->new($self->{db}, $admin, $CONF);
      $user->info($DATA{UID});

      if ($user->{DEPOSIT} + $user->{CREDIT} < $tariffs->{ACTIV_PRICE}) {
        $self->{errno} = 15;
        return $self;
      }
      my $fees = Fees->new($self->{db}, $admin, $CONF);
      $fees->take($user, $tariffs->{ACTIV_PRICE}, { DESCRIBE => "ACTIV TP" });
    }
  }

  $self->query("INSERT INTO sharing_main (uid,
             tp_id,
             type,
             logins,
             disable,
             speed,
             filter_id,
             cid
              )
        VALUES ('$DATA{UID}',
        '$DATA{TP_ID}',
        '$DATA{TYPE}',
        '$DATA{SIMULTANEONSLY}', '$DATA{DISABLE}',
        '$DATA{SPEED}', '$DATA{FILTER_ID}', LOWER('$DATA{CID}')
         );", 'do'
  );

  return [] if ($self->{errno});

  $admin->action_add("$DATA{UID}", "ACTIVE");

  return $self;
}

#**********************************************************
# change()
#**********************************************************
sub change {
  my $self = shift;
  my ($attr) = @_;

  my %FIELDS = (
    SIMULTANEONSLY => 'logins',
    DISABLE        => 'disable',
    TP_ID          => 'tp_id',
    SPEED          => 'speed',
    CID            => 'cid',
    UID            => 'uid',
    FILTER_ID      => 'filter_id',
    TYPE           => 'type',
    EXTRA_TRAFIC   => 'extra_byte'
  );

  my $old_info = $self->info($attr->{UID});

  if ($attr->{TP_ID} && $old_info->{TP_ID} != $attr->{TP_ID}) {
    my $tariffs = Tariffs->new($self->{db}, $CONF, $admin);
    $tariffs->info(0, { ID => $attr->{TP_ID} });

    if ($tariffs->{CHANGE_PRICE} > 0) {
      my $user = Users->new($self->{db}, $admin, $CONF);
      $user->info($attr->{UID});

      if ($user->{DEPOSIT} + $user->{CREDIT} < $tariffs->{CHANGE_PRICE}) {
        $self->{errno} = 15;
        return $self;
      }
      my $fees = Fees->new($self->{db}, $admin, $CONF);
      $fees->take($user, $tariffs->{CHANGE_PRICE}, { DESCRIBE => 'CHANGE_TP'. [$attr->{TP_ID}] });
    }

    if ($tariffs->{AGE} > 0) {
      my $user = Users->new($self->{db}, $admin, $CONF);

      use POSIX qw(strftime);
      my $EXPITE_DATE = POSIX::strftime("%Y-%m-%d", localtime(time + 86400 * $tariffs->{AGE}));
      my $ACTIVATE_DATE = POSIX::strftime("%Y-%m-%d", localtime(time));
      $user->change(
        $attr->{UID},
        {
          EXPIRE   => $EXPITE_DATE,
          ACTIVATE => $ACTIVATE_DATE,
          UID      => $attr->{UID}
        }
      );
    }
  }

  $admin->{MODULE} = $MODULE;
  $self->changes(
    {
      CHANGE_PARAM => 'UID',
      TABLE        => 'sharing_main',
      FIELDS       => \%FIELDS,
      OLD_INFO     => $old_info,
      DATA         => $attr
    }
  );

  return $self->{result};
}

#**********************************************************
# Delete user info from all tables
#
# del(attr);
#**********************************************************
sub del {
  my $self = shift;
  my ($attr) = @_;

  $self->query("DELETE from sharing_main WHERE uid='$attr->{UID}';", 'do');

  $admin->action_add($attr->{UID}, "$attr->{UID}", { TYPE => 10 });
  return $self->{result};
}

#**********************************************************
# list()
#**********************************************************
sub list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my @WHERE_RULES = ("u.uid = sharing.uid");
  push @WHERE_RULES, @{$self->search_expr_users($attr)};
  my $EXT_TABLE = $self->{EXT_TABLES};

  if ($attr->{IP}) {
    push @WHERE_RULES, @{$self->search_expr($attr->{IP}, 'IP', 'sharing.ip', { EXT_FIELD => 1 })};
  }

  if ($attr->{EXTRA_TRAFIC}) {
    push @WHERE_RULES, @{$self->search_expr($attr->{EXTRA_TRAFIC}, 'INT', 'sharing.extra_byte', { EXT_FIELD => 1 })}
  }

  if ($attr->{SPEED}) {
    push @WHERE_RULES, @{$self->search_expr($attr->{SPEED}, 'INT', 'sharing.speed', { EXT_FIELD => 1 })}
  }

  if ($attr->{CID}) {
    push @WHERE_RULES, @{$self->search_expr($attr->{CID}, 'INT', 'sharing.cid', { EXT_FIELD => 1 })}
  }

  if (defined($attr->{TP_ID})) {
    push @WHERE_RULES, "sharing.tp_id='$attr->{TP_ID}'";
  }

  my $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

  $self->query("SELECT u.id,
      pi.fio, if(u.company_id > 0, cb.deposit, b.deposit) AS deposit,
      u.credit,
      tp.name AS tp_name,
      sharing.type,
      u.disable,
      $self->{SEARCH_FIELDS}
      u.uid,
      u.company_id,
      pi.email,
      sharing.tp_id,
      u.activate,
      u.expire,
      if(u.company_id > 0, company.bill_id, u.bill_id) AS bill_id,
      u.reduction
     FROM (users u, sharing_main sharing)
     LEFT JOIN users_pi pi ON (u.uid = pi.uid)
     LEFT JOIN bills b ON (u.bill_id = b.id)
     LEFT JOIN tarif_plans tp ON (tp.id=sharing.tp_id and tp.module='Sharing')
     $EXT_TABLE
     $WHERE
     GROUP BY u.uid
     ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;"
  );

  return [] if ($self->{errno});

  my $list = $self->{list};

  if ($self->{TOTAL} >= 0) {
    $self->query("SELECT COUNT(u.id) AS total FROM (users u, sharing_main sharing) $WHERE", undef, { INFO => 1 });
  }

  return $list;
}

#**********************************************************
#
#**********************************************************
sub sessions_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $WHERE = '';
  my @WHERE_RULES = ();

  # Show debeters
  if ($attr->{LOGIN}) {
    push @WHERE_RULES, @{$self->search_expr($attr->{LOGIN}, 'STR', 'sl.username')};
  }

  #NAS ID
  if ($attr->{NAS_ID}) {
    push @WHERE_RULES, "sl.nas_id='$attr->{NAS_ID}'";
  }

  #NAS ID
  if ($attr->{CID}) {
    if ($attr->{CID}) {
      $attr->{CID} =~ s/\*/\%/ig;
      push @WHERE_RULES, "sl.cid LIKE '$attr->{CID}'";
    }
    else {
      push @WHERE_RULES, "sl.cid='$attr->{CID}'";
    }
  }

  #TARIF_PLAN
  if ($attr->{TARIF_PLAN}) {
    push @WHERE_RULES, "sl.tp_id='$attr->{TARIF_PLAN}'";
  }

  if ($attr->{GID}) {
    push @WHERE_RULES, "u.gid='$attr->{GID}'";
  }

  if ($attr->{TERMINATE_CAUSE}) {
    push @WHERE_RULES, "sl.terminate_cause='$attr->{TERMINATE_CAUSE}'";
  }

  if ($attr->{FROM_DATE}) {
    push @WHERE_RULES,
      "(date_format(sl.start, '%Y-%m-%d')>='$attr->{FROM_DATE}' and date_format(sl.start, '%Y-%m-%d')<='$attr->{TO_DATE}')";
  }

  if ($attr->{DATE}) {
    push @WHERE_RULES, "date_format(sl.start, '%Y-%m-%d')>='$attr->{DATE}'";
  }

  if ($attr->{MONTH}) {
    push @WHERE_RULES, "date_format(sl.start, '%Y-%m')>='$attr->{MONTH}'";
  }

  #Interval from date to date
  if ($attr->{INTERVAL}) {
    my ($from, $to) = split(/\//, $attr->{INTERVAL}, 2);
    push @WHERE_RULES, "date_format(start, '%Y-%m-%d')>='$from' and date_format(start, '%Y-%m-%d')<='$to'";
  }

  #Period
  elsif (defined($attr->{PERIOD})) {
    my $period = int($attr->{PERIOD});
    if ($period == 4) {$WHERE .= '';}
    else {
      $WHERE .= ($WHERE ne '') ? ' and ' : 'WHERE ';
      if ($period == 0) {push @WHERE_RULES, "date_format(start, '%Y-%m-%d')=curdate()";}
      elsif ($period == 1) {push @WHERE_RULES, "TO_DAYS(curdate()) - TO_DAYS(start) = 1 ";}
      elsif ($period == 2) {push @WHERE_RULES, "YEAR(curdate()) = YEAR(start) and (WEEK(curdate()) = WEEK(start)) ";}
      elsif ($period == 3) {push @WHERE_RULES, "date_format(start, '%Y-%m')=date_format(curdate(), '%Y-%m') ";}
      elsif ($period == 5) {push @WHERE_RULES, "date_format(start, '%Y-%m-%d')='$attr->{DATE}' ";}
      else {$WHERE .= "date_format(start, '%Y-%m-%d')=curdate() ";}
    }
  }
  elsif ($attr->{DATE}) {
    push @WHERE_RULES, "date_format(start, '%Y-%m-%d')='$attr->{DATE}'";
  }

  #else {
  #   push @WHERE_RULES, "date_format(start, '%Y-%m-%d')=curdate()";
  #}
  #From To

  $WHERE = "WHERE " . join(' and ', @WHERE_RULES) if ($#WHERE_RULES > -1);

  $self->query("select
  sl.username,
  sl.start,
  SEC_TO_TIME(sl.duration),
  sl.sent,
  sl.recv,
  INET_NTOA(sl.remoteip),
  sl.virtualhost,
  sl.connectionstatus,
  sl.url,
  sl.bytescontent,
  if(sp.priority IS NULL, 1, 0),
  sl.statusbeforeredir,
  sl.statusafterredir,
  sl.remoteport,
  sl.serverid,
  sl.requestmethod,

  sl.protocol,
  sl.processid,
  sl.threadid,
  sl.useragent,
  sl.referer,
  sl.uniqueid,

  sl.identuser,
  sl.microseconds

  FROM (sharing_log sl)
  LEFT join sharing_priority sp ON (sl.url = sp.file)
  $WHERE
  ORDER BY $SORT $DESC
  LIMIT $PG, $PAGE_ROWS;
 ;"
  );

  return [] if ($self->{errno});

  my $list = $self->{list};

  if ($self->{TOTAL} > 0) {
    $self->query("SELECT COUNT(sl.username) AS total,
     SEC_TO_TIME(SUM(sl.duration)) AS duration,
     SUM(sl.sent) AS traffic_in,
     SUM(sl.recv) AS traffic_out
     FROM (sharing_log sl)
     INNER join  sharing_priority sp ON (sl.url=sp.file)
     $WHERE;",
      undef,
      { INFO => 1 }
    );
  }

  return $list;
}

#**********************************************************
# tt_defaults
#**********************************************************
sub tt_defaults {
  my $self = shift;

  my %TT_DEFAULTS = (
    TT_DESCRIBE  => '',
    TT_PRICE_IN  => '0.00000',
    TT_PRICE_OUT => '0.00000',
    TT_NETS      => '',
    TT_PREPAID   => 0,
    TT_SPEED_IN  => 0,
    TT_SPEED_OUT => 0
  );

  while (my ($k, $v) = each %TT_DEFAULTS) {
    $self->{$k} = $v;
  }

  return $self;
}

#**********************************************************
# tt_info
#**********************************************************
sub tt_list {
  my $self = shift;
  my ($attr) = @_;

  if (defined($attr->{TI_ID})) {
    $self->query("SELECT id, in_price, out_price, prepaid, in_speed, out_speed, descr, nets, expression
     FROM sharing_trafic_tarifs WHERE interval_id='$attr->{TI_ID}'
     ORDER BY id DESC;"
    );
  }
  else {
    $self->query("SELECT id, in_price, out_price, prepaid, in_speed, out_speed, descr, nets, expression
     FROM sharing_trafic_tarifs
     WHERE tp_id='$attr->{TP_ID}'
     ORDER BY id;"
    );
  }

  if (defined($attr->{form})) {
    my $a_ref = $self->{list};

    foreach my $row (@{$a_ref}) {
      my ($id, $tarif_in, $tarif_out, $prepaid, $speed_in, $speed_out, $describe, $nets) = @{$row};
      $self->{ 'TT_DESCRIBE_' . $id } = $describe;
      $self->{ 'TT_PRICE_IN_' . $id } = $tarif_in;
      $self->{ 'TT_PRICE_OUT_' . $id } = $tarif_out;
      $self->{ 'TT_NETS_' . $id } = $nets;
      $self->{ 'TT_PREPAID_' . $id } = $prepaid;
      $self->{ 'TT_SPEED_IN' . $id } = $speed_in;
      $self->{ 'TT_SPEED_OUT' . $id } = $speed_out;
    }

    return $self;
  }

  return $self->{list};
}

#**********************************************************
# tt_info
#**********************************************************
sub tt_info {
  my $self = shift;
  my ($attr) = @_;

  $self->query("SELECT id, interval_id, in_price, out_price, prepaid, in_speed, out_speed,
       descr,
       nets,
       expression,
       tp_id
     FROM sharing_trafic_tarifs
     WHERE
     tp_id='$attr->{TP_ID}'
     and id='$attr->{TT_ID}';"
  );

  ($self->{TT_ID}, $self->{TI_ID}, $self->{TT_PRICE_IN}, $self->{TT_PRICE_OUT}, $self->{TT_PREPAID},
    $self->{TT_SPEED_IN}, $self->{TT_SPEED_OUT}, $self->{TT_DESCRIBE}, $self->{TT_NETS}, $self->{TT_EXPRASSION},
    $self->{TP_ID}) = @{$self->{list}->[0]};

  return $self;
}

#**********************************************************
# tt_add
#**********************************************************
sub tt_add {
  my $self = shift;
  my ($attr) = @_;

  my %DATA = $self->get_data($attr, { default => $self->tt_defaults() });

  $self->query("INSERT INTO sharing_trafic_tarifs
    (tp_id, id, descr,  in_price,  out_price,  nets,  prepaid,  in_speed, out_speed, expression)
    VALUES
    ('$DATA{TP_ID}', '$DATA{TT_ID}',   '$DATA{TT_DESCRIBE}', '$DATA{TT_PRICE_IN}',  '$DATA{TT_PRICE_OUT}',
     '$DATA{TT_NETS}', '$DATA{TT_PREPAID}', '$DATA{TT_SPEED_IN}', '$DATA{TT_SPEED_OUT}', '$DATA{TT_EXPRASSION}')", 'do'
  );

  return $self;
}

#**********************************************************
# tt_change
#**********************************************************
sub tt_change {
  my $self = shift;
  my ($attr) = @_;

  $self->query("UPDATE sharing_trafic_tarifs SET
    descr='" . $attr->{TT_DESCRIBE} . "',
    in_price='" . $attr->{TT_PRICE_IN} . "',
    out_price='" . $attr->{TT_PRICE_OUT} . "',
    nets='" . $attr->{TT_NETS} . "',
    prepaid='" . $attr->{TT_PREPAID} . "',
    in_speed='" . $attr->{TT_SPEED_IN} . "',
    out_speed='" . $attr->{TT_SPEED_OUT} . "',
    expression = '" . $attr->{TT_EXPRASSION} . "'
    WHERE
    TP_id='$attr->{TP_ID}' and id='$attr->{TT_ID}';", 'do'
  );

  return $self;
}

#**********************************************************
# Time_intervals
# ti_add
#**********************************************************
sub tt_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query("DELETE FROM sharing_trafic_tarifs
   WHERE  tp_id='$attr->{TI_ID}'  and id='$attr->{TT_ID}' ;", 'do'
  );

  return $self;
}

#**********************************************************
# tt_info
#**********************************************************
sub errors_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my @WHERE_RULES = ();

  if ($attr->{LOGIN}) {
    push @WHERE_RULES, @{$self->search_expr($attr->{LOGIN}, 'STR', 'username')};
  }

  my $WHERE = $self->search_former($attr, [
    [ 'LOGIN', 'STR', 'username', 1 ],
    [ 'IP', 'STR', 'sharing.ip', 1 ],
    [ 'ID', 'INT', 'id', ],
  ],
    { WHERE => 1,
    }
  );

  $self->query("SELECT datetime,
   uid,
   username,
   file_and_path,
   client_name,
   INET_NTOA(ip),
   client_command
     FROM sharing_errors
     $WHERE
     ORDER BY $SORT $DESC
     LIMIT $PG, $PAGE_ROWS;"
  );

  return [] if ($self->{errno});

  my $list = $self->{list};

  if ($self->{TOTAL} >= 0) {
    $self->query("SELECT COUNT(*) AS total FROM sharing_errors $WHERE", undef, { INFO => 1 });
  }

  return $list;
}

#**********************************************************
# Time_intervals
# ti_add
#**********************************************************
sub errors_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query("DELETE FROM sharing_trafic_tarifs
   WHERE  tp_id='$attr->{TI_ID}'  and id='$attr->{TT_ID}' ;", 'do'
  );

  return $self;
}

#**********************************************************
# User information
# info()
#**********************************************************
sub additions_info {
  my $self = shift;
  my ($id) = @_;

  $self->query("SELECT id,
   tp_id,
   name,
   quantity,
   price
     FROM sharing_additions
   WHERE id='$id';"
  );

  $self->{TP_GID} = 0;

  if ($self->{TOTAL} < 1) {
    $self->{errno} = 2;
    $self->{errstr} = 'ERROR_NOT_EXIST';
    return $self;
  }

  ($self->{ID}, $self->{TP_ID}, $self->{NAME}, $self->{QUANTITY}, $self->{PRICE}) = @{$self->{list}->[0]};

  return $self;
}

#**********************************************************
#
#**********************************************************
sub additions_defaults {
  my $self = shift;

  my %DATA = (
    ID       => 0,
    TP_ID    => 0,
    QUANTITY => 0,
    NAME     => '',
    PRICE    => 0
  );

  $self = \%DATA;
  return $self;
}

#**********************************************************
# additions_add()
#**********************************************************
sub additions_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('sharing_additions', $attr);

  return $self;
}

#**********************************************************
# change()
#**********************************************************
sub additions_change {
  my $self = shift;
  my ($attr) = @_;

  $admin->{MODULE} = $MODULE;
  $self->changes(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'sharing_additions',
      DATA         => $attr
    }
  );

  return $self->{result};
}

#**********************************************************
# Delete user info from all tables
#
# del(attr);
#**********************************************************
sub additions_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('sharing_additions', $attr);

  #$admin->action_add($uid, "DELETE");
  return $self->{result};
}

#**********************************************************
# list()
#**********************************************************
sub additions_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  $self->{SEARCH_FIELDS} = '';
  $self->{SEARCH_FIELDS_COUNT} = 0;

  my @WHERE_RULES = ();
  if ($attr->{TP_ID}) {
    my $value = $self->search_expr($attr->{TP_ID}, 'INT');
    push @WHERE_RULES, "tp_id$value";
  }

  my $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

  $self->query("SELECT id,
      name,
      quantity,
      price,
      tp_id
     FROM sharing_additions
     $WHERE
     GROUP BY id
     ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  return $self->{list};
}

#**********************************************************
# User information
# info()
#**********************************************************
sub priority_info {
  my $self = shift;
  my ($id) = @_;

  $self->query("SELECT server,
   file,
   size,
   priority,
   datetime
     FROM sharing_priority
   WHERE id= ? ;",
    undef,
    { INFO => 1,
      Bind => [ $id ] }
  );

  return $self;
}

#**********************************************************
#
#**********************************************************
sub priority_defaults {
  my $self = shift;

  my %DATA = (
    SERVET   => 0,
    FILE     => 0,
    SIZE     => 0,
    PRIORITY => 0
  );

  $self = \%DATA;
  return $self;
}

#**********************************************************
# add()
#**********************************************************
sub priority_add {
  my $self = shift;
  my ($attr) = @_;

  my %DATA = $self->get_data($attr, { default => priority_defaults() });

  $self->query_add('sharing_priority', \%DATA);

  return [] if ($self->{errno});

  #$admin->action_add("$DATA{UID}", "ACTIVE");
  return $self;
}

#**********************************************************
# change()
#**********************************************************
sub priority_change {
  my $self = shift;
  my ($attr) = @_;

  $admin->{MODULE} = $MODULE;
  $self->changes(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'sharing_additions',
      DATA         => $attr
    }
  );

  return $self->{result};
}

#**********************************************************
# Delete user info from all tables
#
# del(attr);
#**********************************************************
sub priority_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('sharing_priority', $attr);

  return $self->{result};
}

#**********************************************************
# list()
#**********************************************************
sub priority_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  $self->{SEARCH_FIELDS} = '';
  $self->{SEARCH_FIELDS_COUNT} = 0;

  my @WHERE_RULES = ();
  my $WHERE = '';

  if ($attr->{SIZE}) {
    my $value = $self->search_expr($attr->{SIZE}, 'INT');
    push @WHERE_RULES, "size$value";
  }

  if ($attr->{PRIORITY}) {
    my $value = $self->search_expr($attr->{PRIORITY}, 'INT');
    push @WHERE_RULES, "priority$value";
  }

  if ($attr->{FILE}) {
    if ($attr->{FILE} =~ s/\*/\%/ig) {
      push @WHERE_RULES, "file LIKE '$attr->{FILE}'";
    }
    else {
      push @WHERE_RULES, "file='$attr->{FILE}'";
    }
  }

  if ($attr->{SERVER}) {
    $attr->{SERVER} =~ s/\*/\%/ig;
    push @WHERE_RULES, "server='$attr->{SERVER}'";
  }

  $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

  $self->query("SELECT server,
      file,
      size,
      priority,
      datetime,
      id
     FROM sharing_priority
     $WHERE
     ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;"
  );

  return [] if ($self->{errno});

  my $list = $self->{list};

  if ($self->{TOTAL} >= 0) {
    $self->query("SELECT COUNT(*) AS total FROM sharing_priority $WHERE", undef, { INFO => 1 });
  }

  return $list;
}

#**********************************************************
=head2 file_add($attr) -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub file_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('sharing_files', $attr);

  $self->{admin}->system_action_add("FILE:". ($attr->{NAME} || q{}), { TYPE => 1 });

  return $self;
}

#*******************************************************************
=head2 function file_list() - get list of all files

  Arguments:
    $attr

  Returns:
    @list

  Examples:
    my @list = $Sharing->file_list({ COLS_NAME => 1});

=cut
#*******************************************************************
sub file_list {
  my $self = shift;
  my ($attr) = @_;

  my @WHERE_RULES = ();
  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 999;

  my $WHERE = $self->search_former($attr,
    [
      [ 'ID', 'INT', 'sf.id', 1 ],
      [ 'NAME', 'STR', 'sf.name', 1 ],
      [ 'AMOUNT', 'INT', 'sf.amount', 1 ],
      [ 'COMMENT', 'STR', 'sf.comment', 1 ],
      [ 'VERSION', 'STR', 'sf.version', 1 ],
      # [ 'GROUP_ID',  'INT', 'sf.group_id',  1 ],
      [ 'GROUP_NAME', 'STR', 'sg.name as group_name', 1 ],
      [ 'LINK_TIME', 'INT', 'sf.link_time', 1 ],
      [ 'FILE_TIME', 'INT', 'sf.file_time', 1 ],
      [ 'REMIND_FOR', 'INT', 'sf.remind_for', 1 ],
    ],
    {
      WHERE         => 1,
      SEARCH_FORMER => 1
    });

  if ($attr->{GROUP_ID}) {
    push @WHERE_RULES, "group_id = '$attr->{GROUP_ID}'";
  }

  $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

  $self->query(
    "SELECT $self->{SEARCH_FIELDS} sf.id FROM sharing_files  as sf
    LEFT JOIN sharing_groups sg ON sg.id = sf.group_id
    $WHERE
    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list};

  return $self->{list} if ($self->{TOTAL} < 1);

  $self->query(
    "SELECT COUNT(*) AS total
   FROM sharing_files",
    undef,
    { INFO => 1 }
  );

  return $list;
}

#*******************************************************************

=head2 function file_delete() - delete cashbox

  Arguments:
    $attr

  Returns:

  Examples:
    $Sharing->file_delete( {ID => 1} );

=cut

#*******************************************************************
sub file_delete {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('sharing_files', $attr);

  $self->{admin}->system_action_add("ID:" . ($attr->{ID} || q{}), { TYPE => 10 });

  return $self;
}

#*******************************************************************

=head2 function file_info() - get information about file

  Arguments:
    $attr

  Returns:
    $self object

  Examples:
    my $file_info = $Sharing->file_info({ ID => 1 });

=cut

#*******************************************************************
sub file_info {
  my $self = shift;
  my ($attr) = @_;

  $self->query(
    "SELECT * FROM sharing_files
      WHERE id = ?;", undef, { INFO => 1, Bind => [ $attr->{ID} ] }
  );

  return $self;
}

#*******************************************************************

=head2 function file_change() - change file's information in datebase

  Arguments:
    $attr

  Returns:
    $self object

  Examples:
    $Sharing->file_change({
      ID     => 1,
      NAME   => 'TEST'
    });


=cut

#*******************************************************************
sub file_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'sharing_files',
    DATA         => $attr
  });

  return $self;
}

#**********************************************************
=head2 add_user() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub add_user {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('sharing_users', $attr);
  $admin->action_add($attr->{UID}, "FILE: $attr->{NAME} ($attr->{ID})", { TYPE => 1 });

  return $self;
}


#**********************************************************
=head2 info_user() -

  Arguments:
    $attr -
      UID
      FILE_ID

  Returns:

  Examples:

=cut
#**********************************************************
sub info_user {
  my $self = shift;
  my ($attr) = @_;

  $self->query(
    "SELECT
    su.uid,
    su.file_id,
    su.date_to,
    su.demo
    FROM sharing_users AS su
    WHERE uid = ? AND file_id = ?;", undef,
    { INFO => 1,
      Bind => [
        $attr->{UID},
        $attr->{FILE_ID}
      ]
    }
  );

  return $self;
}

#*******************************************************************
=head2 function change_user() - change rule's information in datebase

  Arguments:
    $attr
      UID   - rule's identifier
      UID    - user's identifier
      STATUS - call status
      DATE   - call date

  Returns:
    $self object

  Examples:
    $Sharing->change_user({
      UID => 1,
      FILE_ID  => 1,
      STATUS => 2,
      DATE   => $DATE
    });

=cut
#*******************************************************************
sub change_user {
  my $self = shift;
  my ($attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'UID',
    SECOND_PARAM => 'FILE_ID',
    TABLE        => 'sharing_users',
    DATA         => $attr,
  });

  return $self;
}

#*******************************************************************

=head2 function del_user() - delete user's information from datebase

  Arguments:
    $attr
      UID - user's UID;

  Returns:
    $self object
  Examples:
    $Sharing->del_user( {UID => 1, TP_ID => 2} );

=cut

#*******************************************************************
sub del_user {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('sharing_users', $attr, { uid => $attr->{UID}, file_id => $attr->{FILE_ID} });

  return $self;
}

#**********************************************************
=head2 sharing_log_add() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub sharing_log_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('sharing_download_log', {
    %$attr,
    'DATE' => 'NOW()',
    'IP'   => $attr->{IP} || '0.0.0.0',
  });

  return $self;
}

#**********************************************************
=head2 sharing_log_list() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub sharing_log_list {
  my $self = shift;
  my ($attr) = @_;

  my @WHERE_RULES = ();

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  #my $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

  if ($attr->{DATE_START}) {
    push @WHERE_RULES, "sdl.date >= '$attr->{DATE_START} 00:00:01'";
  }

  if ($attr->{DATE_END}) {
    push @WHERE_RULES, "sdl.date <= '$attr->{DATE_END} 23:59:59'";
  }

  my $WHERE = $self->search_former($attr,
    [
      [ 'ID', 'INT', 'sdl.id', 1 ],
      [ 'FILE_ID', 'INT', 'sdl.file_id', 1 ],
      [ 'DATE', 'DATE', 'sdl.date', 1 ],
      [ 'UID', 'ID', 'sdl.uid', 1 ],
      [ 'IP', 'STR', 'INET_NTOA(sdl.ip) as ip', 1 ],
      [ 'SYSTEM_ID', 'STR', 'sdl.system_id', 1 ],
      [ 'FILE_NAME', 'STR', 'sf.name as file_name', 1 ],
    ],
    {
      WHERE            => 1,
      # SEARCH_FORMER    => 1,
      USE_USER_PI      => 1,
      USERS_FIELDS_PRE => 1,
      WHERE_RULES      => \@WHERE_RULES,
    });

  my $EXT_TABLES = $self->{EXT_TABLES};

  $self->query(
    "SELECT $self->{SEARCH_FIELDS} sdl.id, sdl.uid
    FROM sharing_download_log as sdl
    LEFT JOIN sharing_files sf ON sf.id = sdl.file_id
    LEFT JOIN users u ON u.uid=sdl.uid
    $EXT_TABLES
    $WHERE
    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list};

  return $self->{list} if ($self->{TOTAL} < 1);

  $self->query(
    "SELECT COUNT(*) AS total
   FROM sharing_download_log as sdl
   LEFT JOIN sharing_files sf ON sf.id = sdl.file_id
    LEFT JOIN users u ON u.uid=sdl.uid
    $EXT_TABLES
   $WHERE",
    undef,
    { INFO => 1 }
  );

  return $list;
}

#**********************************************************
=head2 group_add() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub group_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('sharing_groups', $attr);

  return $self;
}

#*******************************************************************

=head2 function group_list() - get list of all files

  Arguments:
    $attr

  Returns:
    @list

  Examples:
    my @list = $Sharing->group_list({ COLS_NAME => 1});

=cut

#*******************************************************************
sub group_list {
  my $self = shift;
  my ($attr) = @_;

  my @WHERE_RULES = ();
  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $WHERE = $self->search_former($attr,
    [
      [ 'ID', 'INT', 'id', 1 ],
      [ 'NAME', 'STR', 'name', 1 ],
      [ 'COMMENT', 'STR', 'comment', 1 ],
    ],
    {
      WHERE         => 1,
      SEARCH_FORMER => 1
    });

  $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

  $self->query(
    "SELECT $self->{SEARCH_FIELDS} id FROM sharing_groups
    $WHERE
    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list};

  return $self->{list} if ($self->{TOTAL} < 1);

  $self->query(
    "SELECT COUNT(*) AS total
   FROM sharing_groups",
    undef,
    { INFO => 1 }
  );

  return $list;
}

#*******************************************************************

=head2 function group_delete() - delete cashbox

  Arguments:
    $attr

  Returns:

  Examples:
    $Sharing->group_delete( {ID => 1} );

=cut

#*******************************************************************
sub group_delete {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('sharing_groups', $attr);

  return $self;
}

#*******************************************************************

=head2 function group_info() - get information about file

  Arguments:
    $attr

  Returns:
    $self object

  Examples:
    my $group_info = $Sharing->group_info({ ID => 1 });

=cut

#*******************************************************************
sub group_info {
  my $self = shift;
  my ($attr) = @_;

  $self->query('SELECT * FROM sharing_groups WHERE id = ?;', undef,
    { INFO => 1, Bind => [ $attr->{ID} ] }
  );

  return $self;
}

#*******************************************************************

=head2 function group_change() - change file's information in datebase

  Arguments:
    $attr

  Returns:
    $self object

  Examples:
    $Sharing->group_change({
      ID     => 1,
      NAME   => 'TEST'
    });


=cut

#*******************************************************************
sub group_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'sharing_groups',
    DATA         => $attr
  });

  return $self;
}

#*******************************************************************

=head2 get_remind_date() - get info for reminding

  Arguments:
    $attr

  Returns:

=cut

#*******************************************************************
sub get_remind_date {
  my $self = shift;
  my ($attr) = @_;

  my $WHERE = "datediff(su.date_to, curdate())=sf.remind_for";
  if ($attr->{LOGIN}) {
    $WHERE = "u.id='$attr->{LOGIN}' AND datediff(su.date_to, curdate())=sf.remind_for"
  }
  $self->query("
    SELECT *
    FROM sharing_users su
    JOIN sharing_files sf ON (sf.id=su.file_id)
    JOIN users u ON (su.uid=u.uid)
    WHERE $WHERE;
  ", undef, { COLS_NAME => 1 });

  return $self->{list};
}

#*******************************************************************
=head2 sharing_get_bought_files_count() -

  Arguments:
    $attr

  Returns:

=cut
#*******************************************************************
sub sharing_get_bought_files_count {
  my $self = shift;
  my ($attr) = @_;

  $self->query("
    select su.file_id, COUNT(*) as count, sf.name from sharing_users as su
LEFT JOIN sharing_files sf ON (sf.id=su.file_id)
GROUP BY file_id
ORDER BY count DESC;
  ", undef, { COLS_NAME => 1 });

  return $self->{list};
}

#*******************************************************************
=head2 sharing_get_bought_files_count() -

  Arguments:
    $attr

  Returns:

=cut
#*******************************************************************
sub sharing_get_subscriptions {
  my $self = shift;
  my ($attr) = @_;

  $self->query("SELECT
  (SELECT COUNT(*)
   FROM sharing_users
   WHERE '$attr->{DATE}' < sharing_users.date_to) AS active_subscriptions,
  COUNT(*)                                     AS not_active_subscriptions
FROM sharing_users
WHERE '$attr->{DATE}' > sharing_users.date_to;", undef, { COLS_NAME => 1 });

  return $self->{list};
}

#*******************************************************************
=head2 sharing_get_downloaded_files_count() -

  Arguments:
    $attr

  Returns:

=cut
#*******************************************************************
sub sharing_get_downloaded_files_count {
  my $self = shift;

  $self->query("
    select sdl.file_id, COUNT(*) as count, sf.name from sharing_download_log as sdl
  LEFT JOIN sharing_files sf ON (sf.id=sdl.file_id)
GROUP BY file_id
ORDER BY count DESC;
  ", undef, { COLS_NAME => 1 });

  return $self->{list};
}

#*******************************************************************
=head2 sharing_get_demo_files() -

  Arguments:
    $attr

  Returns:

=cut
#*******************************************************************
sub sharing_get_demo_files {
  my $self = shift;

  $self->query("
    select su.uid, u.id, su.file_id, su.date_to, sf.name from sharing_users as su
LEFT JOIN sharing_files sf ON (sf.id=su.file_id)
LEFT JOIN users u ON (u.uid=su.uid)
WHERE su.demo = 1
GROUP BY file_id;
  ", undef, { COLS_NAME => 1 });

  return $self->{list};
}

#**********************************************************
=head2 callcenter_data_report($attr)

  Arguments:
    $attr -

  Returns:

=cut
#**********************************************************
sub sharing_download_dynamic {
  my $self = shift;
  my ($attr) = @_;
  my $param = $attr->{PARAM} || "'%H'";
  delete($self->{list_hash});

  my $WHERE = $self->search_former(
    $attr,
    [
      [ 'DATE', 'DATE', "DATE_FORMAT(date, '%Y-%m-%d')", ],
    ],
    {
      WHERE => 1
    }
  );

  $self->query(
    "SELECT DATE_FORMAT(date, $param) as my_data, COUNT(*) as count
    FROM sharing_download_log
    $WHERE
    GROUP BY my_data;",
    undef,
    $attr
  );

  return $self->{list_hash} if $attr->{LIST2HASH};

  return $self->{list};
}

sub sharing_user_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  my $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 100;

  my $GROUP = '';

  if ( $attr->{SH_FILE} ){
    $GROUP = "GROUP BY s.uid";
  }

  my $WHERE = $self->search_former( $attr, [
    [ 'LOGIN',   'STR',    'u.id AS login',     1],
    [ 'DATE',    'DATE',   's.date_to',         1],
    [ 'DEMO',    'INT',    's.demo',            1],
  ],
    {
      WHERE        => 1,
      USE_USERS_PI => 1,
      SKIP_USERS_FIELDS => ['COMMENTS']
    }
  );

  my $EXT_TABLES = $self->{EXT_TABLES} || '';

  $self->query(
    "SELECT
      s.uid,
    $self->{SEARCH_FIELDS}
      s.file_id
    FROM sharing_users s
    LEFT JOIN users u ON (u.uid=s.uid)
    LEFT JOIN sharing_files sf ON (sf.id=s.file_id)
    WHERE s.file_id = ?
    $EXT_TABLES
    $WHERE
    $GROUP
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;",
    undef,
      {
        %$attr,
        Bind => [ $attr->{SH_FILE} ]
      }
  );

  my $list = $self->{list};

  if ( $self->{TOTAL} > 0 || $PG > 0 ){
    $self->query(
      "SELECT
        COUNT(s.uid) AS total_users,
        SUM(sf.amount) AS total_sum
       FROM sharing_users s
        INNER JOIN sharing_files sf ON (sf.id=s.file_id)
      WHERE s.file_id = ?
      $GROUP
      $EXT_TABLES;",
      undef,
      {
        INFO => 1,
        Bind => [ $attr->{SH_FILE} ]
      }
    );
  }

  return $list;
}
1;

