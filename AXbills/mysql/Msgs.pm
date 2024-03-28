package Msgs;

=head1 NAME

 Message system
 Help Desk SQL

=cut

use strict;
our $VERSION = 7.00;
use parent qw(dbcore);
use POSIX qw(strftime);
use AXbills::Base qw(in_array);
use Admins;

my $MODULE = 'Msgs';
our Admins $admin;
our ($triggers, $actions);
my $SORT = 1;
my $DESC = '';
my $PG = 0;
my $PAGE_ROWS = 25;

#**********************************************************
# Init
#**********************************************************
sub new {
  my $class = shift;
  my $db = shift;
  $admin = shift;
  my $CONF = shift;

  $admin->{MODULE} = $MODULE;
  my $self = {};

  bless($self, $class);

  $self->{db} = $db;
  $self->{admin} = $admin;
  $self->{conf} = $CONF;

  $CONF->{BUILD_DELIMITER} = ', ' if (!defined($CONF->{BUILD_DELIMITER}));
  $triggers = $self->_msgs_trigger_handlers() if !$triggers;
  $actions = $self->_msgs_action_handlers() if !$actions;

  return $self;
}

#**********************************************************
=head1 messages_new($attr) - Show new message

=cut
#**********************************************************
sub messages_new {
  my $self = shift;
  my ($attr) = @_;

  my @WHERE_RULES = ();
  my $EXT_TABLE = '';
  my $fields = '';

  if ($attr->{USER_READ}) {
    push @WHERE_RULES, "m.user_read='$attr->{USER_READ}' AND admin_read>'0000-00-00 00:00:00' AND m.inner_msg='0'";
    $fields = 'COUNT(*) AS total, \'\', \'\', max(m.id), m.chapter, m.id, 1';
  }
  elsif ($attr->{ADMIN_UNREAD}) {
    $fields = 'COUNT(*) AS total, \'\', \'\', max(m.id), m.chapter, m.id, 1';
  }
  elsif ($attr->{ADMIN_READ}) {
    $fields = "SUM(if(admin_read='0000-00-00 00:00:00', 1, 0)) AS admin_unread_count,
     SUM(IF(plan_date=CURDATE(), 1, 0)) AS today_plan_count,
     SUM(IF(state = 0, 1, 0)) AS open_count,
    1,1,1,1
      ";
  }

  if ($attr->{UID}) {
    push @WHERE_RULES, "m.uid='$attr->{UID}'";

    if ($admin->{DOMAIN_ID}) {
      $admin->{DOMAIN_ID} =~ s/;/,/g;
      push @WHERE_RULES, "u.domain_id IN ($admin->{DOMAIN_ID})";
    }
  }
  elsif ($admin->{DOMAIN_ID}) {
    $admin->{DOMAIN_ID} =~ s/;/,/g;
    push @WHERE_RULES, "c.domain_id IN ($admin->{DOMAIN_ID})";
  }

  if ($attr->{CHAPTER}) {
    $attr->{CHAPTER} =~ s/,/;/g;
    push @WHERE_RULES, @{$self->search_expr($attr->{CHAPTER}, 'INT', 'c.id')};
  }

  if (defined($attr->{STATE}) && $attr->{STATE} ne '') {
    push @WHERE_RULES, @{$self->search_expr($attr->{STATE}, 'INT', 'm.state')};
  }

  push @WHERE_RULES, "u.gid IN ($attr->{GID})" if ($attr->{GID});

  $EXT_TABLE = " LEFT JOIN users u ON (m.uid = u.uid)" if ($attr->{GID} || $attr->{UID});

  my $WHERE = ($#WHERE_RULES > -1) ? 'WHERE ' . join(' and ', @WHERE_RULES) : '';

  if ($attr->{SHOW_CHAPTERS}) {
    $self->query("SELECT c.id,
     c.name,
     SUM(IF(admin_read='0000-00-00 00:00:00', 1, 0)) AS admin_unread_count,
     SUM(IF(plan_date=CURDATE(), 1, 0)) AS today_plan_count,
     SUM(IF(state = 0, 1, 0)) AS open_count,
     SUM(IF(resposible = $admin->{AID}, 1, 0)) AS resposible_count,
     1, 1, 1
    FROM msgs_chapters c
    LEFT JOIN msgs_messages m ON (m.chapter= c.id AND m.state=0)
    $EXT_TABLE
    $WHERE
    GROUP BY c.id;",
      undef,
      $attr
    );

    return $self->{list};
  }

  $EXT_TABLE .= "\nLEFT JOIN msgs_chapters c ON (m.chapter=c.id)" if $attr->{CHAPTER};

  if ($attr->{GID}) {
    $self->query('SELECT '. $fields
      .' FROM (msgs_messages m, users u) '
      . $EXT_TABLE
      . ' '
      . $WHERE . ' AND u.uid=m.uid GROUP BY 7;'
    );
  }
  else {
    $self->query('SELECT ' . $fields
      . ' FROM msgs_messages m '
      . $EXT_TABLE
      . ' '
      . $WHERE
      . ' GROUP BY 7;'
    );
  }

  if ($self->{TOTAL} && $self->{TOTAL} > 0) {
    ($self->{UNREAD}, $self->{TODAY}, $self->{OPENED}, $self->{LAST_ID}, $self->{CHAPTER}, $self->{MSG_ID}) = @{$self->{list}->[0]};
  }

  return $self;
}

#**********************************************************
=head2 messages_list($attr) -  Show message

  Arguments:
    $attr

  Returns:
     array_hash_ref

=cut
#**********************************************************
sub messages_list {
  my $self = shift;
  my ($attr) = @_;

  my $GROUP_BY = ($attr->{GROUP_BY}) ? $attr->{GROUP_BY} : 'm.id';
  
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;
  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  $PG = ($attr->{PG}) ? $attr->{PG} : 0;

  delete $self->{COL_NAMES_ARR};
  delete $self->{SEARCH_FIELDS};
  $self->{EXT_TABLES} = '';
  my @WHERE_RULES = ();
  if ($attr->{PLAN_FROM_DATE}) {
    push @WHERE_RULES, "(DATE_FORMAT(m.plan_date, '%Y-%m-%d')>='$attr->{PLAN_FROM_DATE}' and DATE_FORMAT(m.plan_date, '%Y-%m-%d')<='$attr->{PLAN_TO_DATE}')";
  }
  elsif ($attr->{PLAN_WEEK}) {
    push @WHERE_RULES, "(WEEK(m.plan_date)=WEEK(CURDATE()) and DATE_FORMAT(m.plan_date, '%Y')=DATE_FORMAT(CURDATE(), '%Y'))";
  }
  elsif ($attr->{PLAN_MONTH}) {
    push @WHERE_RULES, "DATE_FORMAT(m.plan_date, '%Y-%m')=DATE_FORMAT(CURDATE(), '%Y-%m')";
  }

  if ($attr->{CHAPTERS_DELIGATION}) {
    my @WHERE_RULES_pre = ();
    while (my ($chapter, $deligation) = each %{$attr->{CHAPTERS_DELIGATION}}) {
      my $privileges = '';
      if ($attr->{PRIVILEGES}) {
        if ($attr->{PRIVILEGES}->{$chapter} <= 2) {
          $privileges = " AND (m.resposible=0 or m.aid='$admin->{AID}' OR m.resposible='$admin->{AID}')";
        }
      }
      push @WHERE_RULES_pre, "(m.chapter='$chapter' AND m.deligation<='$deligation' $privileges)";
    }
    push @WHERE_RULES, "(" . join(" OR ", @WHERE_RULES_pre) . ")";
  }

  if (!defined $attr->{STATE}) {

  }
  elsif ($attr->{STATE} !~ /^\d$/) {

    if ($attr->{STATE} eq '_SHOW' && $attr->{SHOW_UNREAD}) {
      push @WHERE_RULES, "(m.state=0 OR m.admin_read='0000-00-00 00:00:00')";
    }
    else {
      push @WHERE_RULES, @{$self->search_expr($attr->{STATE}, 'INT', 'm.state')};
    }
  }
  elsif ($attr->{STATE} == 0 && $attr->{SHOW_UNREAD}) {
    push @WHERE_RULES, "(m.state=0 OR m.admin_read='0000-00-00 00:00:00')";
  }
  elsif ($attr->{STATE} == 0 && $attr->{USER_UNREAD}) {
    push @WHERE_RULES, "(m.state=0 OR m.state=6 OR m.user_read='0000-00-00 00:00:00')";
  }
  elsif ($attr->{STATE} == 4) {
    push @WHERE_RULES, @{$self->search_expr('0000-00-00 00:00:00', 'DATE', 'm.admin_read')};
  }
  elsif ($attr->{STATE} == 7) {
    push @WHERE_RULES, @{$self->search_expr(">0", 'INT', 'm.deligation')};
  }
  elsif ($attr->{STATE} == 8) {
    push @WHERE_RULES, @{$self->search_expr($admin->{AID}, 'INT', 'm.resposible')};
    push @WHERE_RULES, @{$self->search_expr("0;3;6", 'INT', 'm.state')};
    delete $attr->{DELIGATION};
  }
  elsif ($attr->{STATE} == 12) {
    my $DATE = POSIX::strftime("%Y-%m-%d", localtime(time));
    push @WHERE_RULES, @{$self->search_expr(">0000-00-00;<$DATE", 'INT', 'm.plan_date')};
    push @WHERE_RULES, @{$self->search_expr('0', 'INT', 'm.state')};
  }
  else {
    push @WHERE_RULES, @{$self->search_expr($attr->{STATE}, 'INT', 'm.state')};
  }

  if ($admin->{GID}) {
    $attr->{SKIP_GID} = 1;
    $admin->{GID} =~ s/;/,/g;
    push @WHERE_RULES, "(u.gid IN ($admin->{GID}) OR m.gid IN ($admin->{GID}))";
  }

  if ($attr->{SEARCH_MSGS_BY_WORD}) {
    push @WHERE_RULES, "(m.subject LIKE '%$attr->{SEARCH_MSGS_BY_WORD}%' OR m.message LIKE '%$attr->{SEARCH_MSGS_BY_WORD}%'
      OR r.text LIKE '%$attr->{SEARCH_MSGS_BY_WORD}%')";
  }

  if ($attr->{SEARCH_MSGS}) {
    push @WHERE_RULES, "(m.subject LIKE '%$attr->{SEARCH_MSGS}%' OR u.id LIKE '%$attr->{SEARCH_MSGS}%'
      OR CONCAT_WS(' ', pi.fio, pi.fio2, pi.fio3) LIKE '%$attr->{SEARCH_MSGS}%')";
  }

  my @search_params = (
    [ 'MSG_ID',                 'INT',    'm.id',                                                                        ],
    [ 'CLIENT_ID',              'STR',    'if(m.uid>0, u.id, mg.name)', 'if(m.uid>0, u.id, mg.name) AS client_id'        ],
    [ 'SUBJECT',                'STR',    'm.subject',                                                                 1 ],
    [ 'CHAPTER_NAME',           'STR',    'mc.name', 'mc.name AS chapter_name'                                           ],
    [ 'CHAPTER_COLOR',          'STR',    'mc.color', 'mc.color AS chapter_color'                                        ],
    [ 'CHAPTER',                'INT',    'm.chapter'                                                                    ],
    [ 'DATETIME',               'DATE',   "m.date AS datetime",                                                        1 ],
    [ 'DATE',                   'DATE',   "DATE_FORMAT(m.date, '%Y-%m-%d')", "DATE_FORMAT(m.date, '%Y-%m-%d') AS date"   ],
    [ 'STATE',                  'INT',    '', 'm.state'                                                                  ],
    [ 'REPLY_STATUS',           'INT',    'r.status', 'r.status AS reply_status'                                         ],
    [ 'RESPOSIBLE_ADMIN_LOGIN', 'STR',    'ra.id', 'ra.id AS resposible_admin_login'                                     ],
    [ 'LAST_REPLIE_DATE',       'DATE',   'MAX(r.datetime)  AS last_replie_date',                                      1 ],
    [ 'PLAN_DATE_TIME',         'DATE',   "CONCAT(m.plan_date, ' ', m.plan_time)",
      "CONCAT(m.plan_date, ' ', m.plan_time) AS plan_date_time"                                                          ],
    [ 'DISABLE',                'INT',    'u.disable',                                                                 1 ],
    [ 'INNER_MSG',              'INT',    'm.inner_msg',                                                               1 ],
    [ 'MESSAGE',                'STR',    'm.message',                                                                 1 ],
    [ 'REPLY',                  'STR',    'm.user_read',                                                               1 ],
    [ 'MSG_PHONE',              'STR',    'm.phone', 'm.phone AS msg_phone'                                              ],
    [ 'USER_READ',              'INT',    'm.user_read',                                                               1 ],
    [ 'CLOSED_DATE',            'DATE',   'm.closed_date',                                                             1 ],
    [ 'MONTH_CLOSED',           'DATE',   'DATE_FORMAT(m.closed_date, \'%Y-%m\')',                                     1 ],
    [ 'RUN_TIME',               'DATE',   'SEC_TO_TIME(SUM(r.run_time))', 'SEC_TO_TIME(SUM(r.run_time)) AS run_time'     ],
    [ 'DONE_DATE',              'DATE',   'm.done_date',                                                               1 ],
    [ 'UID',                    'INT',    'm.uid',                                                                      1 ],
    [ 'DELIGATION',             'INT',    'm.delegation',                                                              1 ],
    [ 'RESPOSIBLE',             'INT',    'm.resposible',                                                                ],
    [ 'PLAN_DATE',              'DATE',   'm.plan_date',                                                               1 ],
    [ 'SOFT_DEADLINE',          'DATE',   "DATEDIFF(curdate(), m.date)", "DATEDIFF(curdate(), m.date) as soft_deadline"  ],
    [ 'HARD_DEADLINE',          'DATE',   "DATEDIFF(curdate(), MAX(r.datetime))",
      "DATEDIFF(curdate(), MAX(r.datetime)) as hard_deadline"                                                            ],
    [ 'ADMIN_READ',             'INT',    'm.admin_read',                                                              1 ],
    [ 'PLAN_TIME',              'INT',    'm.plan_time',                                                               1 ],
    [ 'DISPATCH_ID',            'INT',    'm.dispatch_id',                                                             1 ],
    [ 'IP',                     'IP',     'm.ip', 'INET_NTOA(m.ip) AS ip'                                                ],
    [ 'FROM_DATE|TO_DATE',      'DATE',   "DATE_FORMAT(m.date, '%Y-%m-%d')"                                              ],
    [ 'CLOSED_FROM_DATE|CLOSED_TO_DATE',      'DATE',   "DATE_FORMAT(m.closed_date, '%Y-%m-%d')"                         ],
    [ 'ADMIN_LOGIN',            'INT',    'a.aid', 'a.id AS admin_login',                                              1 ],
    [ 'A_NAME',                 'INT',    'a.name', 'a.name AS admin_name',                                            1 ],
    [ 'REPLIES_COUNTS',         '',       '', 'IF(r.id IS NULL, 0, COUNT(r.id)) AS replies_counts'                       ],
    [ 'RATING',                 'INT',    'm.rating',                                                                  1 ],
    [ 'LOCATION_ID',            'INT',    'builds.id AS location_id',                                                             1 ],
    [ 'LOCATION_ID_MSG',        'INT',    'm.location_id as location_id_msg',                                          1 ],
    [ 'RATING_COMMENT',         'STR',    'm.comment',                                                                 1 ],
    [ 'STATE_ID',               'INT',    'm.state', 'm.state AS state_id'                                               ],
    [ 'PRIORITY_ID',            'INT',    'm.priority', 'm.priority AS priority_id'                                      ],
    [ 'CHG_MSGS',               'INT',    'm.id', 'm.id AS chg_msgs'                                                     ],
    [ 'DEL_MSGS',               'INT',    'm.id', 'm.id AS del_msgs'                                                     ],
    [ 'PAR',                    'INT',    'm.par',                                                                     1 ],
    [ 'MSGS_TAGS',              'INT',    'qrt.quick_reply_id', 'qrt.quick_reply_id AS msgs_tags'                        ],
    [ 'DOWNTIME',               '',       '',
      "TIMEDIFF(IF(r.datetime <> '0000-00-00 00:00:00', r.datetime, NOW()), m.date) AS downtime"                         ],
    [ 'REPLY_TEXT',             'STR',    'r.text', 'GROUP_CONCAT(r.text) AS reply_text'                                 ],
    [ 'MONTH',                  'DATE',   'DATE_FORMAT(m.date, \'%Y-%m\')'                                               ],
    [ 'USER_NAME',              'STR',    'u.id', 'u.id AS user_name'                                                    ],
    [ 'ADMIN_DISABLE',          'INT',   'ra.disable', 'ra.disable AS admin_disable',                                  1 ],
    [ 'DONE_SUM',               'INT',   'SUM(m.resposible && m.state) AS done_sum',                                   1 ],
    [ 'PLAN_INTERVAL',          'INT',   'm.plan_interval',                                                            1 ],
    [ 'PLAN_POSITION',          'INT',   'm.plan_position',                                                            1 ],
    [ 'ADDRESS_FULL',           'STR',   "CONCAT(districts.name, ', ',streets.name, ', ', builds.number, " .
      "IF(pi.address_flat IS NOT NULL, CONCAT(', ', pi.address_flat), '')) AS address_full",                           1 ],
    [ 'SEND_TYPE',              'INT',   'm.send_type',                                                                1 ],
    [ 'MSGS_TAGS_IDS',          'INT',    'GROUP_CONCAT(DISTINCT qrt.quick_reply_id  ORDER BY qrt.quick_reply_id SEPARATOR ", ") AS msgs_tags',
      'GROUP_CONCAT(DISTINCT qrt.quick_reply_id  ORDER BY qrt.quick_reply_id SEPARATOR ", ") AS msgs_tags_ids'],
    [ 'CLOSED_ADMIN',           'INT',    'ca.name', 'ca.name AS closed_admin',                                        1 ],
    [ 'WATCHERS',               'INT',   "(SELECT GROUP_CONCAT(DISTINCT admins.name SEPARATOR ', ') FROM msgs_watch mw
      LEFT JOIN admins ON mw.aid = admins.aid WHERE mw.main_msg = m.id GROUP BY mw.main_msg) AS watchers",             1 ]
  );

  push(@search_params, [ 'PERFORMERS', 'INT', 'GROUP_CONCAT(DISTINCT ea.name) AS performers', 1 ]) if (AXbills::Base::in_array('Employees', \@main::MODULES));

  if ($attr->{GET_NEW}) {
    push @WHERE_RULES, " m.date > NOW() - INTERVAL $attr->{GET_NEW} SECOND";
  }

  $admin->{permissions}{0}{8} = 1;
  my $WHERE = $self->search_former($attr, \@search_params, {
    WHERE             => 1,
    WHERE_RULES       => \@WHERE_RULES,
    USERS_FIELDS      => 1,
    SKIP_USERS_FIELDS => [ 'GID', 'UID', 'ADDRESS_FULL', 'LOCATION_ID' ],
    USE_USER_PI       => 1
  });

  my $EXT_TABLES = $self->{EXT_TABLES};

  if ($self->{SEARCH_FIELDS} =~ /u\./ || $EXT_TABLES =~ /u\./ || $WHERE =~ /u\./) {
    $EXT_TABLES = "LEFT JOIN users u ON (m.uid=u.uid)\n" . $EXT_TABLES;
  }

  if ($self->{SEARCH_FIELDS} =~ /r\./ || $WHERE =~ /r\./ || $attr->{GET_NEW}) {
    my $reply_new = q{};
    if ($attr->{GET_NEW}) {
      $reply_new = qq{AND r.datetime > NOW() - INTERVAL $attr->{GET_NEW} SECOND};
    }
    $EXT_TABLES .= "\nLEFT JOIN msgs_reply r FORCE INDEX FOR JOIN (`main_msg`) ON (m.id=r.main_msg $reply_new)";
  }

  if ($self->{SEARCH_FIELDS} =~ /qrt\./ || $WHERE =~ /qrt\./) {
    $EXT_TABLES .= "\nLEFT JOIN msgs_quick_replys_tags qrt FORCE INDEX FOR JOIN (`msg_id`) ON (m.id=qrt.msg_id)";
  }

  if ($self->{SEARCH_FIELDS} =~ /mc\./ || $WHERE =~ /mc\./) {
    $EXT_TABLES .= "\nLEFT JOIN msgs_chapters mc ON (m.chapter=mc.id)";
  }

  if ($self->{SEARCH_FIELDS} =~ /ca\./ || $WHERE =~ /ca\./) {
    $EXT_TABLES .= "\nLEFT JOIN admins ca ON (m.closed_aid=ca.aid)";
  }

  if ($self->{SEARCH_FIELDS} =~ /ea\./) {
    $EXT_TABLES .= "\nLEFT JOIN employees_works em FORCE INDEX FOR JOIN (`ext_id`) ON (em.ext_id=m.id)";
    $EXT_TABLES .= "\nLEFT JOIN admins ea ON (em.employee_id=ea.aid)";
  }

  if ($self->{SEARCH_FIELDS} =~ /builds\./) {
    $EXT_TABLES .= "\nLEFT JOIN `users_pi` pi ON (pi.uid=u.uid)" if $EXT_TABLES !~ 'JOIN \`?users_pi';
    if ($EXT_TABLES =~ 'LEFT JOIN \`?builds') {
      $EXT_TABLES =~ s/builds.id=pi.location_id/builds.id=IF(pi.location_id IS NOT NULL, pi.location_id, m.location_id)/;
    }
    else {
      $EXT_TABLES .= "\nLEFT JOIN `builds` ON (builds.id=IF(pi.location_id IS NOT NULL, pi.location_id, m.location_id))";
      $EXT_TABLES .= "\nLEFT JOIN `streets` ON (streets.id=builds.street_id)";
    }
    $EXT_TABLES .= "\nLEFT JOIN `streets` ON (streets.id=builds.street_id)" if ($EXT_TABLES !~ 'JOIN \`?streets');
    $EXT_TABLES .= "\nLEFT JOIN `districts` ON (districts.id=streets.district_id)" if ($EXT_TABLES !~ 'JOIN \`?districts');
  }

  if ($admin->{DOMAIN_ID}) {
    $admin->{DOMAIN_ID} =~ s/;/,/g;

    if ($WHERE && $WHERE =~ /u.domain_id='\d+'/) {
      $WHERE =~ s/u.domain_id='\d+'/(CASE WHEN m.uid=0 THEN m.domain_id IN ($admin->{DOMAIN_ID}) ELSE u.domain_id IN ($admin->{DOMAIN_ID}) END)/g;
    }
    elsif ($WHERE) {
      $WHERE .= " AND (CASE WHEN m.uid=0 THEN m.domain_id IN ($admin->{DOMAIN_ID}) ELSE u.domain_id IN ($admin->{DOMAIN_ID}) END)";
    }
    else {
      $WHERE = "WHERE (CASE WHEN m.uid=0 THEN m.domain_id IN ($admin->{DOMAIN_ID}) ELSE u.domain_id IN ($admin->{DOMAIN_ID}) END)";
    }
  }

  delete $self->{list};
  $self->query("SELECT m.id, $self->{SEARCH_FIELDS}
       m.uid,
       a.aid,
       m.chapter AS chapter_id,
       m.deligation,
       m.inner_msg,
       m.plan_time,
       m.resposible
      FROM msgs_messages m
      $EXT_TABLES
      LEFT JOIN `admins` a ON (m.aid=a.aid)
      LEFT JOIN `groups` mg ON (m.gid=mg.gid)
      LEFT JOIN `admins` ra ON (m.resposible=ra.aid)
      $WHERE
      GROUP BY $GROUP_BY
      ORDER BY $SORT $DESC
      LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list} || [];

  $self->query("SELECT COUNT(DISTINCT m.id) AS total,
    SUM(IF(m.admin_read = '0000-00-00 00:00:00', 1, 0)) AS in_work,
    SUM(IF(m.state = 0, 1, 0)) AS open,
    SUM(IF(m.state = 1, 1, 0)) AS unmaked,
    SUM(IF(m.state = 2, 1, 0)) AS closed
    FROM `msgs_messages` m
    LEFT JOIN `admins` a ON (m.aid=a.aid)
    $EXT_TABLES
    $WHERE",
    undef,
    { INFO => 1 }
  );

  return $list;
}

#**********************************************************
=head2 message_add($attr)

=cut
#**********************************************************
sub message_add {
  my $self = shift;
  my ($attr) = @_;

  $attr->{CLOSED_DATE} = ($attr->{STATE} == 1 || $attr->{STATE} == 2) ? 'NOW()' : "0000-00-00 00:00:00";
  $attr->{CLOSED_AID} = $admin->{AID} if $attr->{CLOSED_DATE} ne "0000-00-00 00:00:00";

  $self->query_add('msgs_messages', {
    %$attr,
    AID         => ($attr->{USER_SEND}) ? 0 : $admin->{AID},
    DATE        => 'NOW()',
    DOMAIN_ID   => $attr->{UID} ? 0 : $admin->{DOMAIN_ID} || $attr->{DOMAIN_ID},
  });

  $self->{MSG_ID} = $self->{INSERT_ID};

  $self->_msgs_workflow('isNew', $self->{MSG_ID}, $attr);

  return $self;
}

#**********************************************************
=head2 message_del($attr)

  Arguments:
    $attr
      UID
      ID

  Results:
    $self

=cut
#**********************************************************
sub message_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('msgs_messages', $attr, {
    uid => $attr->{UID}
  });

  $self->message_reply_del({
    MAIN_MSG => $attr->{ID},
    UID      => $attr->{UID}
  });

  if ($attr->{ID}) {
    my @id_arr = split(/,/, $attr->{ID});
    my $msg_ids = join(',', map {'?'} @id_arr);
    $self->query('DELETE FROM msgs_attachments
      WHERE message_id IN ('. $msg_ids . ')
      AND message_type=0', 'do', { Bind => \@id_arr }
    );

    $self->query('DELETE FROM msgs_watch WHERE main_msg IN ('
      . join(',', map {'?'} @id_arr) . ')',
      'do', { Bind => \@id_arr }
    );
  }

  if ($attr->{UID}) {
    $self->query('
        DELETE FROM msgs_attachments 
        WHERE create_by = ?
        AND message_type=0 ;',
      'do',
      { Bind => [ $attr->{UID} ] });

    $self->query('UPDATE msgs_unreg_requests SET
      state = 0,
      uid   = 0
      WHERE uid = ? ;', 'do', { Bind => [ $attr->{UID} ] }
    );
  }

  return $self;
}

#**********************************************************
=head2 message_info($id, $attr)

=cut
#**********************************************************
sub message_info {
  my $self = shift;
  my ($id, $attr) = @_;

  my $WHERE = ($attr->{UID}) ? "AND m.uid='$attr->{UID}'" : '';

  $self->query("SELECT m.*,
  INET_NTOA(m.ip) AS ip,
  u.id AS login,
  a.id AS a_name,
  mc.name AS chapter_name,
  g.name AS fg_name,
  ar.id AS responsible_name,
  SEC_TO_TIME(SUM(r.run_time)) AS ticket_run_time,
  MAX(r.datetime) AS last_replie_date
    FROM `msgs_messages` m
    LEFT JOIN `msgs_chapters` mc ON (m.chapter=mc.id)
    LEFT JOIN `users` u ON (m.uid=u.uid)
    LEFT JOIN `admins` a ON (m.aid=a.aid)
    LEFT JOIN `admins` ar ON (m.resposible=ar.aid)
    LEFT JOIN `groups` g ON (m.gid=g.gid)
    LEFT JOIN `msgs_reply` r FORCE INDEX FOR JOIN (`main_msg`) ON (m.id=r.main_msg)
  WHERE m.id= ? $WHERE
  GROUP BY m.id;",
    undef,
    { INFO => 1,
      Bind => [ $id ] }
  );

  #TODO: created fix returns error if no attachment
  #TODO: so need to check was error before if dont return error
  #TODO: because mostly all messages dont have attachments

  $self->attachment_info({ MSG_ID => $self->{ID} });

  delete @{$self}{qw/errno errstr/} if (!$self->{errno} && $self->{errstr});

  return $self;
}

#**********************************************************
=head2 message_change($attr)

=cut
#**********************************************************
sub message_change {
  my $self = shift;
  my ($attr) = @_;

  $attr->{PAR} = $attr->{PARENT_ID} if ($attr->{PARENT_ID});
  $attr->{STATUS} = ($attr->{STATUS}) ? $attr->{STATUS} : 0;
  $attr->{CLOSED_AID} = $admin->{AID} if $attr->{CLOSED_DATE};

  $admin->{MODULE} = $MODULE;
  my $old_info = $self->message_info($attr->{ID});

  if (defined $attr->{STATE} && $attr->{STATE} ne $old_info->{STATE} && !$attr->{CLOSED_DATE}) {
    $attr->{CLOSED_AID} = '';
    $attr->{CLOSED_DATE} = '0000-00-00';
  }

  $self->changes({
    CHANGE_PARAM    => 'ID',
    TABLE           => 'msgs_messages',
    DATA            => $attr,
    EXT_CHANGE_INFO => "MSG_ID:$attr->{ID}"
  });

  $self->_msgs_workflow('isChanged', $self->{ID}, { OLD_INFO => $old_info, %{$attr}, CHANGED => 1 }) if !$self->{errno};

  return $self->{result};
}

#**********************************************************
=head2 chapters_list($attr)

=cut
#**********************************************************
sub chapters_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  $self->{EXT_TABLES} = '';

  my $WHERE = $self->search_former($attr, [
    [ 'INNER_CHAPTER', 'INT', 'mc.inner_chapter'                                                 ],
    [ 'NAME',          'STR', 'mc.name'                                                          ],
    [ 'CHAPTER',       'STR', 'mc.id'                                                            ],
    [ 'MSG_COUNTS',    '',    'COUNT(m.chapter) AS msg_counts', 'COUNT(m.chapter) AS msg_counts' ],
    [ 'RESPONSIBLE',   'INT', 'mc.responsible'                                                   ],
    [ 'AUTOCLOSE',     'INT', 'mc.autoclose'                                                     ],
    [ 'COLOR',         'STR', 'mc.color',                                                      1 ],
  ],
    { WHERE => 1 }
  );

  my $EXT_TABLES = $self->{EXT_TABLES};

  if ($self->{SEARCH_FIELDS} =~ /m\./ || $WHERE =~ /m\./) {
    $EXT_TABLES .= "LEFT JOIN msgs_messages m ON (mc.id=m.chapter)";
  }

  my $domain_id = $attr->{DOMAIN_ID} || $admin->{DOMAIN_ID} || q{};

  if ($domain_id) {
    $domain_id =~ s/;/,/g;
    $WHERE .= (($WHERE) ? 'AND' : 'WHERE ') ." mc.domain_id IN ($domain_id)";
  }

  $self->query("SELECT mc.id, $self->{SEARCH_FIELDS}
     mc.name, mc.inner_chapter, mc.responsible,
     mc.autoclose, ra.id AS admin_login
    FROM msgs_chapters mc
    LEFT JOIN admins ra ON (ra.aid=mc.responsible)
    $EXT_TABLES
    $WHERE
    GROUP BY mc.id
    ORDER BY $SORT $DESC;",
    undef,
    $attr
  );

  if ($self->{TOTAL}) {
    return $self->{list};
  }

  return [];
}

#**********************************************************
=head2 chapter_add($attr)

=cut
#**********************************************************
sub chapter_add {
  my $self = shift;
  my ($attr) = @_;

  $attr->{DOMAIN_ID} = $admin->{DOMAIN_ID} if ($admin->{DOMAIN_ID});
  $self->query_add('msgs_chapters', $attr);

  $admin->system_action_add("MGSG_CHAPTER:$self->{INSERT_ID}", { TYPE => 1 });
  return $self;
}

#**********************************************************
=head2 chapter_del($attr)

=cut
#**********************************************************
sub chapter_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('msgs_chapters', $attr);

  return $self;
}

#**********************************************************
=head2 chapter_info($id, $attr)

=cut
#**********************************************************
sub chapter_info {
  my $self = shift;
  my ($id) = @_;

  $self->query('SELECT *
    FROM msgs_chapters
    WHERE id= ? ',
    undef,
    { INFO => 1,
      Bind => [ $id ] }
  );

  return $self;
}

#**********************************************************
=head2 chapter_change($attr)

=cut
#**********************************************************
sub chapter_change {
  my $self = shift;
  my ($attr) = @_;

  $attr->{INNER_CHAPTER} = ($attr->{INNER_CHAPTER}) ? 1 : 0;

  $admin->{MODULE} = $MODULE;
  $self->changes(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'msgs_chapters',
      DATA         => $attr,
    }
  );

  return $self->{result};
}

#**********************************************************
=head2 admins_list($attr)

=cut
#**********************************************************
sub admins_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  my $WHERE = $self->search_former($attr, [
    [ 'AID',          'INT', 'ma.aid'          ],
    [ 'CHAPTER_ID',   'INT', 'ma.chapter_id'   ],
    [ 'DISABLE',      'INT', 'a.disable'       ]
  ], { WHERE => 1 });

 ### START KTK-39
  $self->query("SELECT a.id AS admin_login,
	 a.name as admin_name,
     mc.name AS chapter_name,
     ma.deligation_level,
     a.aid,
     IF(ma.chapter_id IS NULL, 0, ma.chapter_id) AS chapter_id
    FROM admins a
    LEFT join msgs_admins ma ON (a.aid=ma.aid)
    LEFT join msgs_chapters mc ON (ma.chapter_id=mc.id)
    $WHERE
    ORDER BY $SORT $DESC;",
    undef,
    $attr
  );
  ### END KTK-39

  my $list = $self->{list};

  return $list;
}

#**********************************************************
=head2 admin_change($attr)

=cut
#**********************************************************
sub admin_change {
  my $self = shift;
  my ($attr) = @_;

  $self->admin_del({ AID => $attr->{AID} });

  my @chapters = split(/, /, $attr->{IDS});
  my @MULTI_QUERY = ();

  foreach my $id (@chapters) {
    next if !$attr->{ 'DELIGATION_LEVEL_' . $id};
    push @MULTI_QUERY, [ $attr->{AID}, $id, $attr->{ 'DELIGATION_LEVEL_' . $id } ];
  }

  $self->query("INSERT INTO msgs_admins (aid, chapter_id, deligation_level) VALUES (?, ?, ?);",
    undef, { MULTI_QUERY => \@MULTI_QUERY });

  return $self;
}

#**********************************************************
=head2 admin_del($attr)

=cut
#**********************************************************
sub admin_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('msgs_admins', undef, { aid => $attr->{AID} });

  return $self;
}

#**********************************************************
=head2 message_reply_del($attr)

=cut
#**********************************************************
sub message_reply_del {
  my $self = shift;
  my ($attr) = @_;

  my @WHERE_FIELDS = ();
  my @WHERE_VALUES = ();

  if ($attr->{MAIN_MSG}) {
    my @id_arr = split(/,/, $attr->{MAIN_MSG});
    push @WHERE_FIELDS, "main_msg IN (" . join(',', map {'?'} @id_arr) . ')';
    push @WHERE_VALUES, @id_arr;

    $self->query("
        DELETE FROM msgs_attachments 
        WHERE message_id IN (SELECT id FROM msgs_reply WHERE $WHERE_FIELDS[0])
        AND message_type=1",
      'do',
      { Bind => \@WHERE_VALUES }
    );
  }
  elsif ($attr->{ID}) {
    push @WHERE_FIELDS, 'id = ?';
    push @WHERE_VALUES, $attr->{ID};

    $self->query("DELETE FROM msgs_attachments WHERE message_id= ? and message_type=1", 'do', { Bind => [ $attr->{ID} ] });
  }
  elsif ($attr->{UID}) {
    push @WHERE_FIELDS, 'uid = ?';
    push @WHERE_VALUES, $attr->{UID};

    $self->query("
        DELETE FROM msgs_attachments 
        WHERE message_id IN (SELECT id FROM msgs_reply WHERE uid = ?)
        AND message_type=1",
      'do',
      { Bind => [ $attr->{UID} ] }
    );
  }

  if ($#WHERE_FIELDS == -1) {
    return $self;
  }

  my $WHERE = join(' AND ', @WHERE_FIELDS);
  $self->query('DELETE FROM msgs_reply WHERE ' . $WHERE,
    'do', { Bind => \@WHERE_VALUES });

  return $self;
}

#**********************************************************
=head2 messages_reply_list($attr)

=cut
#**********************************************************
sub messages_reply_list {
  my $self = shift;
  my ($attr) = @_;

  my $GROUP_BY = ($attr->{GROUP_BY}) ? $attr->{GROUP_BY} : 'mr.id';

  $SORT = ($attr->{SORT} ? $attr->{SORT} : 'datetime');
  $DESC = ($attr->{DESC} ? $attr->{DESC} : 'ASC');
  my $EXT_TABLES = '';

  if ($attr->{PAGE_ROWS}) {
    if ($attr->{PAGE_ROWS} =~ /LIMIT/) {
      $PAGE_ROWS = $attr->{PAGE_ROWS}
    }
    else {
      $PAGE_ROWS = 'LIMIT ' . $attr->{PAGE_ROWS}
    }
  }
  else {
    $PAGE_ROWS = ' ';
  }

  $self->{SEARCH_FIELDS} = '';
  $self->{SEARCH_FIELDS_COUNT} = 0;

  my @WHERE_RULES = ();

  if ($attr->{FROM_DATE} && $attr->{TO_DATE}) {
    push @WHERE_RULES, "mr.datetime BETWEEN '$attr->{FROM_DATE} 00:00:00' AND '$attr->{TO_DATE} 23:59:59'";
  }

  if ($attr->{MSGS_IDS}) {
    push @WHERE_RULES, "mr.main_msg IN ($attr->{MSGS_IDS})";
  }

  my $WHERE = $self->search_former($attr, [
    [ 'ID',            'INT',  'mr.id',                   ],
    [ 'MSG_ID',        'INT',  'mr.main_msg',           1 ],
    [ 'LOGIN',         'INT',  'u.id'                     ],
    [ 'UID',           'INT',  'm.uid'                    ],
    [ 'INNER_MSG',     'INT',  'mr.inner_msg'             ],
    [ 'REPLY',         'STR',  'm.reply',                 ],
    [ 'STATE',         'INT',  'm.state'                  ],
    [ 'FILE_NAME',     'INT',  'ma.filename',             ],
    [ 'CONTENT_SIZE',  'INT',  'ma.content_size',       1 ],
    [ 'CONTENT_TYPE',  'INT',  'ma.content_type',       1 ],
    [ 'ATTACH_COORDX', 'INT',  'ma.coordx',             1 ],
    [ 'ATTACH_COORDY', 'INT',  'ma.coordy',             1 ],
    [ 'ADMIN',         'STR',  'a.id', 'a.id AS admin', 1 ],
    [ 'AID',           'INT',  'mr.aid',                1 ],
    [ 'DATETIME',      'DATE', "mr.datetime",         '1' ],
    [ 'SURVEY_ID',     'INT',  'mr.survey_id',          1 ],
    [ 'STATUS',        'INT',  'mr.status',             1 ],
  ],
    {
      WHERE_RULES => \@WHERE_RULES,
      WHERE       => 1,
    }
  );

  if ($self->{SEARCH_FIELDS} =~ /m\./ || $WHERE =~ /m\./) {
    $EXT_TABLES = " LEFT JOIN msgs_messages m ON (mr.main_msg=m.id) ";
  }

  $self->query("SELECT mr.id,
    $self->{SEARCH_FIELDS}
    mr.datetime,
    mr.text,
    if(mr.aid>0, a.id, u.id) AS creator_id,
    if(mr.aid>0, a.name, u.id) AS creator_fio,
    mr.status,
    mr.caption,
    INET_NTOA(mr.ip) AS ip,
    ma.filename,
    ma.content_size,
    ma.id AS attachment_id,
    mr.uid,
    SEC_TO_TIME(mr.run_time) AS run_time,
    mr.aid,
    mr.inner_msg,
    mr.survey_id
    FROM msgs_reply mr
    LEFT JOIN users u ON (mr.uid=u.uid)
    LEFT JOIN admins a ON (mr.aid=a.aid)
    LEFT JOIN msgs_attachments ma ON (mr.id=ma.message_id and ma.message_type=1 )
    $EXT_TABLES
    $WHERE
    GROUP BY $GROUP_BY
    ORDER BY $SORT $DESC
    $PAGE_ROWS;",
    undef,
    $attr
  );

  return $self->{list};
}

#**********************************************************
=head2 message_reply_add($attr)

  Arguments:
    $attr - hash_ref
      ID               - message reply is attached to
      REPLY_SUBJECT
      REPLY_TEXT
      STATE            - state that was sent with reply
      REPLY_INNER_MSG  - is this reply inner ( administrators visible only )

  Returns:
    $self

=cut
#**********************************************************
sub message_reply_add {
  my $self = shift;
  my ($attr) = @_;

  my $old_info = $self->message_info($attr->{ID});
  $self->query_add('msgs_reply', {
    %$attr,
    MAIN_MSG  => $attr->{ID},
    CAPTION   => $attr->{REPLY_SUBJECT},
    TEXT      => $attr->{REPLY_TEXT},
    DATETIME  => 'NOW()',
    STATUS    => $attr->{STATE},
    INNER_MSG => $attr->{REPLY_INNER_MSG},
    ID        => undef, # Remove main ID
  });

  $self->{REPLY_ID} = $self->{INSERT_ID};
  my %insert_result = %{$self};

  $self->_msgs_workflow('replyAdded', $attr->{ID}, { OLD_INFO => $old_info, %{$attr} });

  return \%insert_result;
}

#**********************************************************
=head2 message_reply_change()

=cut
#**********************************************************
sub message_reply_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'msgs_reply',
    DATA         => $attr
  });

  return $self;
}

#**********************************************************
=head2 attachments_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut
#**********************************************************
sub attachments_list {
  my ($self, $attr) = @_;

  $SORT = $attr->{SORT} || 'id';
  $DESC = ($attr->{DESC}) ? '' : 'DESC';
  $PG = $attr->{PG} || '0';
  $PAGE_ROWS = $attr->{PAGE_ROWS} || 25;

  # Both values are stored in single column
  if ($attr->{REPLY_ID}) {
    $attr->{MESSAGE_ID} = $attr->{REPLY_ID};
    $attr->{MESSAGE_TYPE} = 1;
  }

  my $search_columns = [
    [ 'ID',           'INT',  'ma.id',           1 ],
    [ 'MESSAGE_ID',   'INT',  'ma.message_id',   1 ],
    [ 'FILENAME',     'STR',  'ma.filename',     1 ],
    [ 'CONTENT_SIZE', 'STR',  'ma.content_size', 1 ],
    [ 'CONTENT_TYPE', 'STR',  'ma.content_type', 1 ],
    [ 'CONTENT',      'STR',  'ma.content',      1 ],
    [ 'CREATE_TIME',  'DATE', 'ma.create_time',  1 ],
    [ 'CREATE_BY',    'INT',  'ma.create_by',    1 ],
    [ 'CHANGE_TIME',  'DATE', 'ma.change_time',  1 ],
    [ 'CHANGE_BY',    'INT',  'ma.change_by',    1 ],
    [ 'MESSAGE_TYPE', 'INT',  'ma.message_type', 1 ],
    [ 'COORDX',       'INT',  'ma.coordx',       1 ],
    [ 'COORDY',       'INT',  'ma.coordy',       1 ],
    [ 'DELIVERY_ID',  'INT',  'ma.delivery_id',  1 ]
  ];

  if ($attr->{SHOW_ALL_COLUMNS}) {
    map {$attr->{$_->[0]} = '_SHOW' unless exists $attr->{$_->[0]}} @$search_columns;
  }

  my $WHERE = $self->search_former($attr, $search_columns, { WHERE => 1 });

  $self->query("SELECT $self->{SEARCH_FIELDS} ma.id
   FROM msgs_attachments ma
   $WHERE ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;", undef, {
    COLS_NAME => 1, COLS_UPPER => 1,
    %{$attr // {}} }
  );

  return [] if $self->{errno};

  return $self->{list};
}

#**********************************************************
=head2 attachment_add($attr) Add attachments

=cut
#**********************************************************
sub attachment_add {
  my $self = shift;
  my ($attr) = @_;

  # Message type and reply id are stored in single column ( Curious )
  my @msgs_ids = ($attr->{REPLY_ID})
    ? $attr->{REPLY_ID}
    : (ref $attr->{MSG_ID} eq 'ARRAY') ? @{$attr->{MSG_ID}} : ($attr->{MSG_ID});

  foreach my $id (@msgs_ids) {
    $self->query(
      "INSERT INTO msgs_attachments
      (message_id, filename, content_type, content_size, content,
       create_time, create_by, change_time, change_by, message_type,
       coordx, coordy, delivery_id)
       VALUES
      (?, ?, ?, ?, ?, current_timestamp, ?, current_timestamp, '0', ?, ?, ?, ?)",
      'do',
      { Bind => [
        $id || 0,
        $attr->{FILENAME},
        $attr->{CONTENT_TYPE},
        $attr->{FILESIZE} || 0,
        $attr->{CONTENT},
        $attr->{UID} || 0,
        $attr->{MESSAGE_TYPE} || 0,
        $attr->{COORDX} || 0,
        $attr->{COORDY} || 0,
        $attr->{DELIVERY_ID} || 0
      ] }
    );
  }

  return $self;
}

#**********************************************************
=head2 attachment_change($attr) change attachments

=cut
#**********************************************************
sub attachment_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'msgs_attachments',
    DATA         => $attr,
  });

  return $self->{result};
}

#**********************************************************
=head2 attachment_info($attr)

=cut
#**********************************************************
sub attachment_info {
  my $self = shift;
  my ($attr) = @_;

  my $WHERE = '';

  if ($attr->{MSG_ID}) {
    $WHERE = "message_id='$attr->{MSG_ID}' and message_type='0'";
  }
  elsif ($attr->{REPLY_ID}) {
    $WHERE = "message_id='$attr->{REPLY_ID}' and message_type='1'";
  }
  elsif ($attr->{DELIVERY_ID}) {
    $WHERE = "delivery_id='$attr->{DELIVERY_ID}'";
  }
  elsif ($attr->{ID}) {
    $WHERE = "id='$attr->{ID}'";
  }

  $WHERE .= " AND (create_by='$attr->{UID}' or create_by='0')" if ($attr->{UID});
  return $self if (!$WHERE);

  $self->query("SELECT id AS attachment_id, filename,
    content_type,
    content_size,
    content
   FROM  msgs_attachments
   WHERE $WHERE",
    undef,
    { INFO => 1 }
  );

  $self->{errno} = undef if ($self->{errno} && $self->{errno} == 2);

  return $self;
}

#**********************************************************
=head2 attachment_del($attachment_id) - deletes attachment by id

  Arguments:
    $attachment_id -
    
  Returns:
    1
    
=cut
#**********************************************************
sub attachment_del {
  my ($self, $attachment_id) = @_;

  $self->query_del('msgs_attachments', { ID => $attachment_id });

  return 1;
}

#**********************************************************
=head2 messages_reports($attr)

=cut
#**********************************************************
sub messages_reports {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 100;

  my $GROUP_BY = '1';
  my %EXT_TABLE_JOINS_HASH = ();
  my $ext_fields = '';

  $self->{SEARCH_FIELDS} = '';
  $self->{SEARCH_FIELDS_COUNT} = 0;

  my @WHERE_RULES = ();

  my $date = 'DATE_FORMAT(m.date, \'%Y-%m-%d\') AS date';
  if ($attr->{TYPE}) {
    my $type = $attr->{TYPE};
    if ($type eq 'ADMINS') {
      $date = 'a.id AS admin_name, a.aid AS aid';
      $EXT_TABLE_JOINS_HASH{admins} = 1;
    }
    elsif ($type eq 'USER') {
      $date = 'u.id AS login';
      $EXT_TABLE_JOINS_HASH{users} = 1;
    }
    elsif ($type eq 'RESPOSIBLE') {
      $date = "a.id AS admin_name, a.aid AS aid";
      $EXT_TABLE_JOINS_HASH{admins} = 1;
    }
    elsif ($type eq 'HOURS') {
      $date = 'DATE_FORMAT(m.date, \'%H\') AS hours';
    }
    elsif ($type eq 'CHAPTERS') {
      $date = "c.name AS chapter_name";
      $EXT_TABLE_JOINS_HASH{chapters} = 1;
    }
    elsif ($type eq 'DISTRICT') {
      $date = "districts.name AS district_name";
      $EXT_TABLE_JOINS_HASH{users} = 1;
      $EXT_TABLE_JOINS_HASH{users_pi} = 1;
      $EXT_TABLE_JOINS_HASH{builds} = 1;
      $EXT_TABLE_JOINS_HASH{streets} = 1;
      $EXT_TABLE_JOINS_HASH{districts} = 1;
    }
    elsif ($type eq 'STREET') {
      $date = "streets.name AS street_name";
      $EXT_TABLE_JOINS_HASH{users} = 1;
      $EXT_TABLE_JOINS_HASH{users_pi} = 1;
      $EXT_TABLE_JOINS_HASH{builds} = 1;
      $EXT_TABLE_JOINS_HASH{streets} = 1;
    }
    elsif ($type eq 'BUILD') {
      $date = "CONCAT(streets.name, '$self->{conf}->{BUILD_DELIMITER}', builds.number) AS build";
      $EXT_TABLE_JOINS_HASH{users} = 1;
      $EXT_TABLE_JOINS_HASH{users_pi} = 1;
      $EXT_TABLE_JOINS_HASH{builds} = 1;
      $EXT_TABLE_JOINS_HASH{streets} = 1;
    }
    elsif ($type eq 'REPLY') {
      $ext_fields = "COUNT(r.id) AS replies_count, ";
      $EXT_TABLE_JOINS_HASH{reply} = 1;
    }
    elsif ($type eq 'PER_MONTH') {
      $date = "DATE_FORMAT(m.date, \'%Y-%m\') AS month ";
    }
    #else {
    #  $date = "u.id AS login";
    #  $EXT_TABLE_JOINS_HASH{users}=1;
    #}
  }

  if ($attr->{DATE}) {
    push @WHERE_RULES, "DATE_FORMAT(m.date, '%Y-%m-%d')='$attr->{DATE}'";
    $date = "DATE_FORMAT(m.date, '%Y-%m-%d') AS date";
  }
  elsif ($attr->{INTERVAL}) {
    my ($from, $to) = split(/\//, $attr->{INTERVAL}, 2);
    push @WHERE_RULES, "DATE_FORMAT(m.date, '%Y-%m-%d')>='$from' AND DATE_FORMAT(m.date, '%Y-%m-%d')<='$to'";
  }
  elsif (defined($attr->{MONTH})) {
    push @WHERE_RULES, "DATE_FORMAT(m.date, '%Y-%m')='$attr->{MONTH}'";
    $date = "DATE_FORMAT(m.date, '%Y-%m-%d') AS date";
  }
  else {
    $date = "DATE_FORMAT(m.date, '%Y-%m') AS month";
  }

  my $WHERE = $self->search_former($attr, [
    [ 'LOGIN', 'STR', 'u.id', ],
    [ 'STATUS', 'INT', 'm.state' ],
    [ 'GID', 'INT', 'm.gid', ],
    [ 'UID', 'INT', 'm.uid', ],
    [ 'MSG_ID', 'INT', 'm.id', ],
  ],
    {
      WHERE       => 1,
      WHERE_RULES => \@WHERE_RULES,
    }
  );

  my $EXT_TABLES = $self->mk_ext_tables({
    JOIN_TABLES    => \%EXT_TABLE_JOINS_HASH,
    EXTRA_PRE_JOIN => [
      'users:LEFT JOIN users u ON (m.uid=u.uid)',
      'admins:LEFT JOIN admins a ON (m.resposible=a.aid)',
      'chapters:LEFT JOIN msgs_chapters c ON (m.chapter=c.id)',
      'reply:LEFT JOIN msgs_reply r FORCE INDEX FOR JOIN (`main_msg`) ON (m.id=r.main_msg)',
    ]
  });

  $self->query("SELECT $date,
   COUNT(DISTINCT IF (m.state=0, m.id, NULL)) AS open,
   COUNT(DISTINCT IF (m.state=1, m.id, NULL)) AS unmaked,
   COUNT(DISTINCT IF (m.state=2, m.id, NULL)) AS maked,
   COUNT(DISTINCT IF (m.state>2, m.id, NULL)) AS other,
   COUNT(DISTINCT m.id) AS total_msgs,
   SEC_TO_TIME(SUM(mr.run_time)) AS run_time,
   $ext_fields
   m.uid,
   m.chapter
  FROM msgs_messages m
  LEFT JOIN  msgs_reply mr ON (m.id=mr.main_msg)
  $EXT_TABLES
  $WHERE
  GROUP BY $GROUP_BY
  ORDER BY $SORT $DESC ; ",
    undef,
    $attr
  );

  my $list = $self->{list};

  if ($self->{TOTAL} > 0 || $PG > 0) {
    $self->query("SELECT COUNT(DISTINCT m.id) AS total,
      SUM(IF (m.state=0, 1, 0)) AS open,
      SUM(IF (m.state=1, 1, 0)) AS unmaked,
      SUM(IF (m.state=2, 1, 0)) AS maked,
      SUM(IF (m.state>2, 1, 0)) AS other,
      SEC_TO_TIME(SUM(t1.run_time)) AS run_time,
      SUM(IF(m.admin_read = '0000-00-00 00:00:00', 1, 0)) AS in_work
     FROM msgs_messages m
     LEFT JOIN (SELECT mr.main_msg, SUM(mr.run_time) as run_time FROM msgs_reply mr GROUP BY mr.main_msg) as t1 ON (m.id=t1.main_msg)
     $EXT_TABLES
    $WHERE;",
      undef,
      { INFO => 1 }
    );
  }

  return $list;
}

#**********************************************************
=head2 dispatch_list($attr)

=cut
#**********************************************************
sub dispatch_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : 'DESC';
  $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my @WHERE_RULES = ();

  if (defined($attr->{STATE}) && $attr->{STATE} ne '') {
    if ($attr->{STATE} == 4) {
      push @WHERE_RULES, @{$self->search_expr('0000-00-00 00:00:00', 'INT', 'm.admin_read')};
    }
    else {
      push @WHERE_RULES, @{$self->search_expr($attr->{STATE}, 'INT', 'd.state')};
    }
  }

  if ($attr->{FROM_DATE} && $attr->{TO_DATE}) {
    push @WHERE_RULES, "d.plan_date BETWEEN '$attr->{FROM_DATE} 00:00:00' AND '$attr->{TO_DATE} 23:59:59'";
  }

  my $WHERE = $self->search_former($attr, [
    [ 'ID',               'INT',  'd.id',                                                           1 ],
    [ 'COMMENTS',         'STR',  'd.comments',                                                     1 ],
    [ 'CREATED',          'STR',  'd.created',                                                      1 ],
    [ 'PLAN_DATE',        'DATE', 'd.plan_date',                                                    1 ],
    [ 'MESSAGE_COUNT',    'INT',  'COUNT(m.id) AS message_count',                                   1 ],
    [ 'CREATED_ADMIN',    'STR',  'a.name AS created_admin',                                        1 ],
    [ 'RESPOSIBLE_ADMIN', 'STR',  'ad.name AS resposible_admin',                                    1 ],
    [ 'DS_STATUS',        'INT',  'd.state AS ds_status',                                           1 ],
    [ 'START_DATE',       'DATE', 'd.start_date',                                                   1 ],
    [ 'END_DATE',         'DATE', 'd.end_date',                                                     1 ],
    [ 'ACTUAL_END_DATE',  'DATE', 'd.actual_end_date',                                              1 ],
    [ 'CATEGORY',         'STR',  'dc.name AS category',                                            1 ],
    [ 'CATEGORY_ID',      'INT',  'dc.id AS category_id',                                           1 ],
    [ 'CREATED_BY',       'INT',  'd.created_by',                                                     ],
    [ 'RESPOSIBLE',       'INT',  'd.resposible',                                                     ],
    [ 'AID',              'INT',  'd.aid',                                                            ],
    [ 'CHAPTER',          'INT',  'd.id'                                                              ],
    [ 'MSGS_DONE',        'INT',  'SUM(IF(m.state=2, 1, 0))', 'SUM(IF(m.state=2, 1, 0)) AS msgs_done' ],
    [ 'CLOSED_DATE',      'DATE', 'd.closed_date',                                                    ],
  ],
    { WHERE       => 1,
      WHERE_RULES => \@WHERE_RULES
    }
  );

  my $EXT_TABLES = "LEFT JOIN msgs_dispatch_category dc FORCE INDEX FOR JOIN (`PRIMARY`) ON (d.category=dc.id)
  LEFT JOIN msgs_messages m ON (d.id=m.dispatch_id)
  LEFT JOIN admins a ON (d.created_by=a.aid)
  LEFT JOIN admins ad ON (d.resposible=ad.aid)";

  if ($admin->{DOMAIN_ID}) {
    $admin->{DOMAIN_ID} =~ s/;/,/g;
    $WHERE .= (($WHERE) ? 'AND' : 'WHERE ') ." d.domain_id IN ($admin->{DOMAIN_ID})";
  }

  $self->query("SELECT
     $self->{SEARCH_FIELDS}
     d.id
  FROM msgs_dispatch d
  $EXT_TABLES
  $WHERE
  GROUP BY d.id
  ORDER BY $SORT $DESC
  LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list};

  $self->query("SELECT COUNT(*) AS total
    FROM msgs_dispatch d
    $EXT_TABLES
    $WHERE;",
    undef,
    { INFO => 1 },
  );

  return $list;
}

#**********************************************************
=head2 chapter_add($attr)

=cut
#**********************************************************
sub dispatch_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('msgs_dispatch', { %$attr,
    COMMENTS  => $attr->{COMMENTS} || '',
    CREATED   => 'now()',
    DOMAIN_ID => $admin->{DOMAIN_ID} || $attr->{DOMAIN_ID}
  });
  $self->{DISPATCH_ID} = $self->{INSERT_ID};

  $admin->system_action_add("MGSG_DISPATCH:$self->{INSERT_ID}", { TYPE => 1 });
  return $self;
}

#**********************************************************
=head2 chapter_del

=cut
#**********************************************************
sub dispatch_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('msgs_dispatch', $attr);

  if (!$self->{errno}) {
    $self->query("UPDATE `msgs_messages` SET dispatch_id='0' WHERE dispatch_id=?;", 'do', {
      Bind => [ $attr->{ID} ]
    });
  }

  $admin->system_action_add("MGSG_DISPATCH:$attr->{ID}", { TYPE => 10 });

  return $self;
}

#**********************************************************
=head2 dispatch_info()

=cut
#**********************************************************
sub dispatch_info {
  my $self = shift;
  my ($id) = @_;

  $self->query("SELECT md.*,
      a.aid,
      ra.aid AS resposible_id,
      a.name AS admin_fio,
      ra.name AS resposible_fio,
      cra.name AS admin_create
    FROM msgs_dispatch md
    LEFT JOIN admins a ON (a.aid=md.aid)
    LEFT JOIN admins ra ON (ra.aid=md.resposible)
    LEFT JOIN admins cra ON (cra.aid=md.created_by)
    WHERE md.id= ?", undef, { INFO => 1, Bind => [ $id ] }
  );

  return $self;
}

#**********************************************************
=head2 dispatch_change()

=cut
#**********************************************************
sub dispatch_change {
  my $self = shift;
  my ($attr) = @_;

  $attr->{INNER_CHAPTER} = ($attr->{INNER_CHAPTER}) ? 1 : 0;

  $admin->{MODULE} = $MODULE;
  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'msgs_dispatch',
    DATA         => $attr,
  });

  return $self->{result};
}

#**********************************************************
=head2 dispatch_admins_change

=cut
#**********************************************************
sub dispatch_admins_change {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('msgs_dispatch_admins', undef, { dispatch_id => $attr->{DISPATCH_ID} });
  my @admins = split(/, /, $attr->{AIDS});
  my @MULTI_QUERY = ();
  foreach my $aid (@admins) {
    push @MULTI_QUERY, [ $attr->{DISPATCH_ID}, $aid ];
  }

  $self->query("INSERT INTO msgs_dispatch_admins (dispatch_id, aid) VALUES (?, ?);", undef, { MULTI_QUERY => \@MULTI_QUERY });

  return $self;
}

#**********************************************************
=head2 dispatch_admins_list($attr)

=cut
#**********************************************************
sub dispatch_admins_list {
  my $self = shift;
  my ($attr) = @_;

  $self->query("SELECT  mda.dispatch_id, mda.aid, a.name, e.position as admin_position
      FROM msgs_dispatch_admins mda
      LEFT JOIN admins a ON mda.aid = a.aid
      LEFT JOIN employees_positions e ON a.position = e.id
      WHERE dispatch_id= ?;",
    undef,
    { %$attr, Bind => [ $attr->{DISPATCH_ID} ] });

  return $self->{list};
}

#**********************************************************
=head2 chapter_info($id, $attr)

=cut
#**********************************************************
sub dispatch_category_info {
  my $self = shift;
  my ($id) = @_;

  $self->query("SELECT *
    FROM msgs_dispatch_category
    WHERE id= ? ",
    undef, { INFO => 1, Bind => [ $id ] }
  );

  return $self;
}

#**********************************************************
=head2 chapter_change($attr)

=cut
#**********************************************************
sub dispatch_category_change {
  my $self = shift;
  my ($attr) = @_;

  $admin->{MODULE} = $MODULE;
  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'msgs_dispatch_category',
    DATA         => $attr,
  });

  return $self->{result};
}

#**********************************************************
=head2 chapter_del

=cut
#**********************************************************
sub dispatch_category_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('msgs_dispatch_category', $attr);

  $admin->system_action_add("MGSG_DISPATCH_CATEGORY:$attr->{ID}", { TYPE => 10 });

  return $self;
}

#**********************************************************
=head2 dispatch_category_add($attr)

=cut
#**********************************************************
sub dispatch_category_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('msgs_dispatch_category', $attr);

  $admin->system_action_add("MGSG_DISPATCH_CATEGORY:$self->{INSERT_ID}", { TYPE => 1 });
  return $self;
}

#**********************************************************
=head2 dispatch_category_list($attr)

=cut
#**********************************************************
sub dispatch_category_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : 'DESC';
  $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my @WHERE_RULES = ();

  my $WHERE = $self->search_former($attr, [
    [ 'ID',   'INT', 'dc.id',   1 ],
    [ 'NAME', 'STR', 'dc.name', 1 ],
  ], { WHERE => 1, WHERE_RULES => \@WHERE_RULES });

  $self->query("SELECT dc.id,
     dc.name
  FROM msgs_dispatch_category dc
  $WHERE
  GROUP BY dc.id
  ORDER BY $SORT $DESC
  LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list};

  $self->query("SELECT COUNT(*) AS total FROM msgs_dispatch_category dc $WHERE;", undef, { INFO => 1 });

  return $list;
}

#**********************************************************
=head2 unreg_requests_count($attr) - Count unreg message

=cut
#**********************************************************
sub unreg_requests_count {
  my $self = shift;

  my $WHERE = "WHERE state=0 ";
  if ($admin->{DOMAIN_ID}) {
    $admin->{DOMAIN_ID} =~ s/;/,/g;
    $WHERE .= (($WHERE) ? 'AND' : 'WHERE ') ." m.domain_id IN ($admin->{DOMAIN_ID})";
  }

  $self->query("SELECT COUNT(m.id) AS unreg_count FROM msgs_unreg_requests m $WHERE", undef, { INFO => 1 });

  return $self;
}

#**********************************************************
=head2 unreg_requests_list($attr) - Unreg request list

=cut
#**********************************************************
sub unreg_requests_list {
  my $self = shift;
  my ($attr) = @_;

  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;
  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = (defined($attr->{DESC})) ? $attr->{DESC} : 'DESC';
  $PG = ($attr->{PG}) ? $attr->{PG} : 0;

  my @WHERE_RULES = ();
  $self->{COL_NAMES_ARR} = undef;
  $self->{SEARCH_FIELDS} = undef;
  $self->{SEARCH_FIELDS_COUNT} = 0;

  if (defined($attr->{STATE})) {
    if ($attr->{STATE} == 7) {
      push @WHERE_RULES, @{$self->search_expr(">0", 'INT', 'm.deligation')};
    }
    elsif ($attr->{STATE} == 8) {
      push @WHERE_RULES, @{$self->search_expr("$admin->{AID}", 'INT', 'm.resposible')};
      push @WHERE_RULES, @{$self->search_expr("0;3;6", 'INT', 'm.state')};
      delete $attr->{DELIGATION};
    }
    else {
      push @WHERE_RULES, @{$self->search_expr($attr->{STATE}, 'INT', 'm.state')};
    }
  }

  if ($attr->{LOCATION_ID}) {
    push @WHERE_RULES, @{$self->search_expr($attr->{LOCATION_ID}, 'INT', 'm.location_id', { EXT_FIELD => 'streets.name AS address_street, builds.number AS address_build, m.address_flat, builds.id AS build_id' })};
    $self->{EXT_TABLES} .= "LEFT JOIN builds ON (builds.id=m.location_id)
   LEFT JOIN streets ON (streets.id=builds.street_id)";
    $self->{SEARCH_FIELDS_COUNT} += 3;
  }
  else {
    if ($attr->{STREET_ID}) {
      push @WHERE_RULES, @{$self->search_expr($attr->{STREET_ID}, 'INT', 'builds.street_id', { EXT_FIELD => 'streets.name AS address_street, builds.number AS address_build' })};
      $self->{EXT_TABLES} .= "LEFT JOIN builds ON (builds.id=m.location_id)
     LEFT JOIN streets ON (streets.id=builds.street_id)";
      $self->{SEARCH_FIELDS_COUNT} += 1;
    }
    elsif ($attr->{DISTRICT_ID}) {
      push @WHERE_RULES, @{$self->search_expr($attr->{DISTRICT_ID}, 'INT', 'streets.district_id', { EXT_FIELD => 'districts.name AS district_name' })};
      $self->{EXT_TABLES} .= " LEFT JOIN builds ON (builds.id=m.location_id)
      LEFT JOIN streets ON (streets.id=builds.street_id)
      LEFT JOIN districts ON (districts.id=streets.district_id) ";
    }
    elsif ($self->{conf}->{ADDRESS_REGISTER}) {
      if ($attr->{CITY}) {
        push @WHERE_RULES, @{$self->search_expr($attr->{CITY}, 'STR', 'city', { EXT_FIELD => 1 })};
      }

      if ($attr->{DISTRICT_NAME}) {
        push @WHERE_RULES, @{$self->search_expr($attr->{DISTRICT_NAME}, 'INT', 'streets.district_id', { EXT_FIELD => 'districts.name AS district_name' })};
      }

      if ($attr->{ADDRESS_DISTRICT}) {
        push @WHERE_RULES, @{$self->search_expr($attr->{ADDRESS_DISTRICT}, 'INT', 'streets.district_id', { EXT_FIELD => 'districts.name AS district_name' })};
      }

      if ($attr->{ADDRESS_STREET}) {
        push @WHERE_RULES, @{$self->search_expr($attr->{ADDRESS_STREET}, 'STR', 'streets.name AS address_street', { EXT_FIELD => 1 })};
        $self->{EXT_TABLES} .= "LEFT JOIN builds ON (builds.id=m.location_id)
        LEFT JOIN streets ON (streets.id=builds.street_id)" if ($self->{EXT_TABLES} !~ /streets/);
      }
      elsif ($attr->{ADDRESS_FULL}) {
        my $build_delimiter = $attr->{BUILD_DELIMITER} || $self->{conf}{BUILD_DELIMITER} || ', ';
        push @WHERE_RULES, @{$self->search_expr("$attr->{ADDRESS_FULL}", "STR", "CONCAT(streets.name, '$build_delimiter', builds.number, '$build_delimiter', m.address_flat) AS address_full", { EXT_FIELD => 1 })};

        $self->{EXT_TABLES} .= "LEFT JOIN builds ON (builds.id=m.location_id)
          LEFT JOIN streets ON (streets.id=builds.street_id)";
      }

      if ($attr->{ADDRESS_BUILD}) {
        push @WHERE_RULES, @{$self->search_expr($attr->{ADDRESS_BUILD}, 'STR', 'builds.number', { EXT_FIELD => 'builds.number AS address_build' })};

        $self->{EXT_TABLES} .= "LEFT JOIN builds ON (builds.id=m.location_id)" if ($self->{EXT_TABLES} !~ /builds/);
      }
    }
    else {
      if ($attr->{ADDRESS_FULL}) {
        my $build_delimiter = $attr->{BUILD_DELIMITER} || $self->{conf}{BUILD_DELIMITER} || ', ';
        push @WHERE_RULES, @{$self->search_expr("$attr->{ADDRESS_FULL}", "STR", "CONCAT(m.address_street, '$build_delimiter', m.address_build, '$build_delimiter', m.address_flat) AS address_full", { EXT_FIELD => 1 })};
      }

      if ($attr->{ADDRESS_STREET}) {
        push @WHERE_RULES, @{$self->search_expr($attr->{ADDRESS_STREET}, 'STR', 'm.address_street', { EXT_FIELD => 1 })};
      }

      if ($attr->{ADDRESS_BUILD}) {
        push @WHERE_RULES, @{$self->search_expr($attr->{ADDRESS_BUILD}, 'STR', 'm.address_build', { EXT_FIELD => 1 })};
      }

      if ($attr->{COUNTRY_ID}) {
        push @WHERE_RULES, @{$self->search_expr($attr->{COUNTRY_ID}, 'STR', 'm.country_id', { EXT_FIELD => 1 })};
      }
    }
  }

  if ($attr->{ADDRESS_FLAT}) {
    push @WHERE_RULES, @{$self->search_expr($attr->{ADDRESS_FLAT}, 'STR', 'm.address_flat', { EXT_FIELD => 1 })};
  }

  if ($attr->{GET_NEW}) {
    push @WHERE_RULES, " (m.datetime > now() - interval $attr->{GET_NEW} second) ";
  }

  my $search_fields = $self->{SEARCH_FIELDS};
  my $search_fields_count = $self->{SEARCH_FIELDS_COUNT};
  my $WHERE = $self->search_former($attr, [
    [ 'MSG_ID',                        'INT',  'm.id'                                     ],
    [ 'ID',                            'INT',  'm.id'                                     ],
    [ 'DATETIME',                      'DATE', 'm.datetime',                            1 ],
    [ 'SUBJECT',                       'STR',  'm.subject',                             1 ],
    [ 'FIO',                           'STR',  'm.fio',                                 1 ],
    [ 'PHONE',                         'STR',  'm.phone',                               1 ],
    [ 'EMAIL',                         'STR',  'm.email',                               1 ],
    [ 'STATE',                         'INT',  'm.state',                               1 ],
    [ 'CONNECTION_TIME',               'DATE', 'm.connection_time',                     1 ],
    [ 'CHAPTER_NAME',                  'INT',  'm.chapter', 'mc.name AS chapter_name'     ],
    [ 'CLOSED_DATE',                   'DATE', 'm.closed_date',                         1 ],
    [ 'ADMIN_LOGIN',                   'INT',  'a.id', 'a.id AS admin_login'              ],
    [ 'INNER_MSG',                     'INT',  'm.inner_msg',                           1 ],
    [ 'COMMENTS',                      'STR',  'm.comments',                            1 ],
    [ 'REACTION_TIME',                 'STR',  'm.reaction_time'                          ],
    [ 'DONE_DATE',                     'DATE', 'm.done_date',                           1 ],
    [ 'UID',                           'INT',  'm.uid',                                   ],
    [ 'DELIGATION',                    'INT',  'm.delegation',                          1 ],
    [ 'RESPOSIBLE_ADMIN_LOGIN',        'STR',  'ra.id', 'ra.id AS resposible_admin_login' ],
    [ 'RESPOSIBLE',                    'INT',  'm.resposible',                            ],
    [ 'PRIORITY',                      'INT',  'm.priority',                            1 ],
    [ 'IP',                            'IP',   'm.ip', 'INET_NTOA(m.ip) AS ip'            ],
    [ 'DATE',                          'DATE', "DATE_FORMAT(m.datetime, '%Y-%m-%d')"      ],
    [ 'FROM_DATE|TO_DATE',             'DATE', "DATE_FORMAT(m.datetime, '%Y-%m-%d')"      ],
    [ 'CLOSE_FROM_DATE|CLOSE_TO_DATE', 'DATE', "DATE_FORMAT(m.closed_date, '%Y-%m-%d')"   ],
    [ 'SHOW_TEXT',                     '', '', 'm.message'                                ],
    [ 'REACTION_TIME',                 'STR',  'm.reaction_time',                       1 ],
    [ 'CONTACT_NOTE',                  'STR',  'm.contact_note',                        1 ],
    [ 'REFERRAL_UID',                  'INT',  'm.referral_uid',                        1 ]
  ],
    { WHERE       => 1,
      WHERE_RULES => \@WHERE_RULES
    }
  );

  $self->{SEARCH_FIELDS_COUNT} += $search_fields_count;
  my $EXT_TABLES = '';

  if ($self->{conf}->{ADDRESS_REGISTER}) {
    $EXT_TABLES = "LEFT JOIN builds ON builds.id=m.location_id
     LEFT JOIN streets ON (streets.id=builds.street_id)
     LEFT JOIN districts ON (districts.id=streets.district_id)";
  }

  if ($admin->{DOMAIN_ID}) {
    $admin->{DOMAIN_ID} =~ s/;/,/g;
    $WHERE .= (($WHERE) ? 'AND' : 'WHERE ') ." m.domain_id IN ($admin->{DOMAIN_ID})";
  }

  $self->query("SELECT  m.id,
    $self->{SEARCH_FIELDS}
    $search_fields
    m.resposible,
    m.uid,
    m.chapter AS chapter_id
    FROM msgs_unreg_requests m
    LEFT JOIN admins a ON (m.received_admin=a.aid)
    LEFT JOIN admins ra ON (m.resposible=ra.aid)
    LEFT JOIN msgs_chapters mc ON (m.chapter=mc.id)
    $EXT_TABLES
    $WHERE
    GROUP BY m.id
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list};

  if ($self->{TOTAL} > 0 || $PG > 0) {
    $self->query("SELECT count(*) AS total
    FROM msgs_unreg_requests m
    LEFT JOIN msgs_chapters mc ON (m.chapter=mc.id)
    $EXT_TABLES
    $WHERE",
      undef, { INFO => 1 }
    );
  }

  $WHERE = '';
  @WHERE_RULES = ();

  return $list;
}

#**********************************************************
=head2 unreg_requests_add($attr) - add unreg request

=cut
#**********************************************************
sub unreg_requests_add {
  my $self = shift;
  my ($attr) = @_;

  if ($attr->{STREET_ID} && $attr->{ADD_ADDRESS_BUILD} && !$attr->{LOCATION_ID}) {
    require Address;
    Address->import();
    my $Address = Address->new($self->{db}, $self->{admin}, $self->{conf});
    $Address->build_add({
      STREET_ID         => $attr->{STREET_ID},
      ADD_ADDRESS_BUILD => $attr->{ADD_ADDRESS_BUILD}
    });
    $attr->{LOCATION_ID} = $Address->{LOCATION_ID};

    if($attr->{LOCATION_ID}) {
      $Address->address_info($attr->{LOCATION_ID});
      $self->{ADDRESS_DISTRICT} = $Address->{ADDRESS_DISTRICT} || q{};
      $self->{ADDRESS_STREET}   = $Address->{ADDRESS_STREET} || q{};
      $self->{ADDRESS_BUILD}    = $Address->{ADDRESS_BUILD} || q{};
      $self->{ADDRESS_FLAT}     = $Address->{ADDRESS_FLAT} || q{};
    }
  }

  $self->query_add('msgs_unreg_requests', {
    %$attr,
    DATETIME       => 'NOW()',
    RECEIVED_ADMIN => $admin->{AID},
    COMMENTS       => $attr->{COMMENTS} || '',
    IP             => $admin->{SESSION_IP},
    DOMAIN_ID      => $admin->{DOMAIN_ID} || $attr->{DOMAIN_ID}
  });
  $self->{MSG_ID} = $self->{INSERT_ID};
  $attr->{INSERT_ID} = $self->{INSERT_ID};

  $admin->{MODULE} = $MODULE;
  $admin->action_add($attr->{UID}, '', {
    TYPE    => 1,
    INFO    => ['INSERT_ID', 'SUBJECT', 'FIO', 'TP_ID', 'DOMAIN_ID', 'COMMENTS'],
    REQUEST => $attr
  });

  return $self;
}

#**********************************************************
=head2 unreg_requests_del($attr) - del unreg request

=cut
#**********************************************************
sub unreg_requests_del {
  my $self = shift;
  my ($attr) = @_;

  if (!$attr->{ID}) {
    return $self;
  }

  $self->query_del('msgs_unreg_requests', $attr, { ID => $attr->{ID} });

  $admin->{MODULE} = $MODULE;
  $admin->action_add(0, "UNREG_REQUEST_ID: $attr->{ID}", { TYPE => 10 });

  return $self;
}

#**********************************************************
=head2 unreg_requests_info($id, $attr)

=cut
#**********************************************************
sub unreg_requests_info {
  my $self = shift;
  my ($id, $attr) = @_;

  my $WHERE = ($attr->{UID}) ? "AND m.uid='$attr->{UID}'" : '';
  if ($admin->{DOMAIN_ID}) {
    $admin->{DOMAIN_ID} =~ s/;/,/g;
    $WHERE .= " AND m.domain_id IN ($admin->{DOMAIN_ID})";
  }

  $self->query("SELECT
    m.*,
    ra.id AS received_admin,
    mc.name AS chapter,
    m.chapter AS chapter_id,
    INET_NTOA(m.ip) AS ip
    FROM msgs_unreg_requests m
    LEFT JOIN msgs_chapters mc ON (m.chapter=mc.id)
    LEFT JOIN admins ra ON (m.received_admin=ra.aid)
  WHERE m.id=? $WHERE
  GROUP BY m.id;",
    undef,
    { INFO => 1,
      Bind => [ $id ] }
  );

  if ($self->{TOTAL} && $self->{LOCATION_ID} > 0) {
    $self->query("SELECT d.id AS district_id,
      d.city,
      d.name AS address_district,
      s.name AS address_street,
      b.number AS address_build
     FROM builds b
     LEFT JOIN streets s  ON (s.id=b.street_id)
     LEFT JOIN districts d  ON (d.id=s.district_id)
     WHERE b.id= ? ",
      undef,
      { INFO => 1,
        Bind => [ $self->{LOCATION_ID} ]
      }
    );
  }

  return $self;
}


#**********************************************************
=head2 unreg_requests_change($attr)

=cut
#**********************************************************
sub unreg_requests_change {
  my $self = shift;
  my ($attr) = @_;

  if ($attr->{STREET_ID} && $attr->{ADD_ADDRESS_BUILD}) {
    require Address;
    Address->import();
    my $Address = Address->new($self->{db}, $self->{admin}, $self->{conf});
    $Address->build_add({
      STREET_ID         => $attr->{STREET_ID},
      ADD_ADDRESS_BUILD => $attr->{ADD_ADDRESS_BUILD}
    });
    $attr->{LOCATION_ID} = $Address->{LOCATION_ID};
  }
  $attr->{STATUS} = ($attr->{STATUS}) ? $attr->{STATUS} : 0;

  $admin->{MODULE} = $MODULE;

  my $unreg_info = $self->unreg_requests_list({
    ID          => $attr->{ID},
    FIO         => '_SHOW',
    SUBJECT     => '_SHOW',
    PHONE       => '_SHOW',
    EMAIL       => '_SHOW',
    STATE       => '_SHOW',
    COMMENTS    => '_SHOW',
    RESPOSIBLE  => '_SHOW',
    PRIORITY    => '_SHOW',
    LOCATION_ID => '_SHOW',
    COLS_NAME   => 1,
    COLS_UPPER  => 1,
  });

  $attr->{DOMAIN_ID} ||= $admin->{DOMAIN_ID};

  $self->changes({
      CHANGE_PARAM    => 'ID',
      TABLE           => 'msgs_unreg_requests',
      DATA            => $attr,
      EXT_CHANGE_INFO => "MSG_ID:$attr->{ID}"
  });

  if (ref $unreg_info eq "ARRAY" && $unreg_info->[0]) {
    my $changes = "UNREG_REQUEST_ID: $attr->{ID},";
    foreach my $key (keys %{$unreg_info->[0]}) {
      if (defined $attr->{$key} && $attr->{$key} ne $unreg_info->[0]{$key}) {
        $changes .= " $key: $unreg_info->[0]{$key}->$attr->{$key},";
      }
    }

    chop $changes;
    $admin->action_add(0, $changes, { TYPE => 2 });
  }

  return $self->{result};
}

#**********************************************************
=head2 survey_subjects_list($attr)

=cut
#**********************************************************
sub survey_subjects_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  # delete $self->{COL_NAMES_ARR};

  my $WHERE = $self->search_former($attr, [
    [ 'ID',         'INT', 'ms.id',                         ],
    [ 'NAME',       'STR', 'ms.name'                        ],
    [ 'COMMENTS',   'STR', 'ms.comments',                 1 ],
    [ 'TPL',        'STR', 'ms.tpl',                      1 ],
    [ 'STATUS',     'STR', 'ms.status',                   1 ],
    [ 'ADMIN_NAME', 'STR', 'ms.aid', 'ms.aid AS admin_name' ],
    [ 'CREATED',    'STR', 'ms.created',                  1 ],
    [ 'FILENAME',   'STR', 'm.filename',                  1 ],
  ], { WHERE => 1 });

  $self->query("SELECT ms.id, ms.name, $self->{SEARCH_FIELDS} ms.id AS survey_id
    FROM msgs_survey_subjects ms
    $WHERE
    GROUP BY ms.id
    ORDER BY $SORT $DESC;",
    undef,
    $attr
  );

  my $list = $self->{list} || [];
  $self->query("SELECT count(*) AS total FROM msgs_survey_subjects ms $WHERE", undef, { INFO => 1 }) if ($self->{TOTAL} > 0);

  return $list;
}

#**********************************************************
=head2 survey_subjects_add($attr)

=cut
#**********************************************************
sub survey_subject_add {
  my $self = shift;
  my ($attr) = @_;

  return $self if (!$attr->{NAME});

  $self->query_add('msgs_survey_subjects', { %$attr,
    CREATED  => 'NOW()',
    TPL      => $attr->{TPL} || ' ',
    COMMENTS => $attr->{COMMENTS} || ' ',
    CONTENTS => $attr->{CONTENTS} || ' ',
  });

  return $self;
}

#**********************************************************
=head2 survey_subject_del()

=cut
#**********************************************************
sub survey_subject_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('msgs_survey_subjects', $attr);

  return $self;
}

#**********************************************************
=head2 survey_subjects_info($id)

=cut
#**********************************************************
sub survey_subject_info {
  my $self = shift;
  my ($id) = @_;

  $self->query("SELECT *,
     id AS survey_id
    FROM msgs_survey_subjects
    WHERE id= ? ", undef, { INFO => 1, Bind => [ $id ] }
  );

  return $self;
}

#**********************************************************
=head2 survey_subject_change($attr)

=cut
#**********************************************************
sub survey_subject_change {
  my $self = shift;
  my ($attr) = @_;

  $admin->{MODULE} = $MODULE;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'msgs_survey_subjects',
    DATA         => $attr,
  });

  return $self->{result};
}

#**********************************************************
=head2 survey_questions_list($attr)

=cut
#**********************************************************
sub survey_questions_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  my $WHERE = $self->search_former($attr, [ [ 'SURVEY_ID', 'STR', 'mq.survey_id' ], ], { WHERE => 1 });

  $self->query("SELECT  mq.num, mq.question, mq.comments, mq.params, mq.user_comments, mq.fill_default, mq.id
    FROM msgs_survey_questions mq
    $WHERE
    ORDER BY $SORT $DESC;",
    undef,
    $attr
  );

  my $list = $self->{list};
  $self->query("SELECT count(*) AS total FROM msgs_survey_questions mq $WHERE", undef, { INFO => 1 }) if ($self->{TOTAL} > 0);

  return $list;
}

#**********************************************************
=head2 survey_question_add($attr)

=cut
#**********************************************************
sub survey_question_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('msgs_survey_questions', $attr);

  return $self;
}

#**********************************************************
=head2 survey_question_del($attr)

=cut
#**********************************************************
sub survey_question_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('msgs_survey_questions', $attr);

  return $self;
}

#**********************************************************
=head2 survey_question_info($attr)

=cut
#**********************************************************
sub survey_question_info {
  my $self = shift;
  my ($id) = @_;

  $self->query("SELECT * FROM msgs_survey_questions WHERE id= ? ", undef, { INFO => 1, Bind => [ $id ] });

  return $self;
}

#**********************************************************
=head2 survey_questions_change($attr)

=cut
#**********************************************************
sub survey_question_change {
  my $self = shift;
  my ($attr) = @_;

  $attr->{INNER_CHAPTER} = ($attr->{INNER_CHAPTER}) ? 1 : 0;
  $attr->{USER_COMMENTS} = ($attr->{USER_COMMENTS}) ? 1 : 0;
  $attr->{FILL_DEFAULT} = ($attr->{FILL_DEFAULT}) ? 1 : 0;

  $admin->{MODULE} = $MODULE;
  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'msgs_survey_questions',
    DATA         => $attr,
  });

  return $self->{result};
}

#**********************************************************
=head2 survey_answer_show($attr)

  Arguments:
    REPLY_ID
    SURVEY_ID
    UID

  Results:

=cut
#**********************************************************
sub survey_answer_show {
  my $self = shift;
  my ($attr) = @_;

  my $WHERE = ($attr->{REPLY_ID}) ? "AND reply_id='$attr->{REPLY_ID}'" : "AND msg_id='$attr->{MSG_ID}' AND reply_id='0' ";

  $self->query("SELECT question_id,
      uid,
      answer,
      comments,
      date_time,
      survey_id
    FROM msgs_survey_answers
    WHERE survey_id= ?
    AND uid= ? $WHERE;", undef, { Bind => [ $attr->{SURVEY_ID}, $attr->{UID} ], %$attr }
  );

  return $self->{list};
}

#**********************************************************
=head2 survey_answer_list($attr)

=cut
#**********************************************************
sub survey_answer_list {
  my $self = shift;
  my ($attr) = @_;

  $self->query("SELECT
    ma.*,
    u.id as login
    FROM msgs_survey_answers ma
    LEFT JOIN users u ON (u.uid=ma.uid)
    WHERE survey_id= ? ;",
    undef,
    { Bind => [ $attr->{SURVEY_ID} ], COLS_NAME => 1 }
  );

  return $self->{list};

}

#**********************************************************
=head2 survey_answer_add($attr)

=cut
#**********************************************************
sub survey_answer_add {
  my $self = shift;
  my ($attr) = @_;

  my @ids = split(/, /, $attr->{IDS});

  my @fill_default = ();
  my %fill_default_hash = ();
  if ($attr->{FILL_DEFAULT}) {
    @fill_default = split(/, /, $attr->{FILL_DEFAULT});
    foreach my $id (@fill_default) {
      $fill_default_hash{$id} = 1;
    }
  }

  my @MULTI_QUERY = ();

  foreach my $id (@ids) {
    next if ($attr->{FILL_DEFAULT} && !$fill_default_hash{$id});

    push @MULTI_QUERY, [ $id,
      $attr->{UID},
      $attr->{ 'PARAMS_' . $id } || '',
      $attr->{ 'USER_COMMENTS_' . $id } || '',
      $attr->{SURVEY_ID},
      $attr->{MSG_ID},
      $attr->{REPLY_ID}
    ];
  }

  $self->query("INSERT INTO msgs_survey_answers (question_id,
     uid, answer, comments, date_time, survey_id, msg_id, reply_id)
        VALUES (?, ?, ?, ?, NOW(), ?, ?, ?);",
    undef,
    { MULTI_QUERY => \@MULTI_QUERY });

  return $self;
}

#**********************************************************
=head2 survey_answer_del($attr)

=cut
#**********************************************************
sub survey_answer_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('msgs_survey_answers', $attr, {
    SURVEY_ID => $attr->{SURVEY_ID},
    UID       => $attr->{UID},
    REPLY_ID  => ($attr->{REPLY_ID}) ? $attr->{REPLY_ID} : undef,
    MSG_ID    => (!$attr->{REPLY_ID}) ? $attr->{MSG_ID} : undef
  });

  return $self;
}


#**********************************************************
=head2 pb_list($attr)

=cut
#**********************************************************
sub pb_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  delete $self->{COL_NAMES_ARR};

  my $WHERE = $self->search_former($attr, [
    [ 'STEP_NUM',   'INT', 'pb.step_num'   ],
    [ 'STEP_NAME',  'STR', 'pb.step_name'  ],
    [ 'CHAPTER_ID', 'STR', 'pb.chapter_id' ]
  ], { WHERE => 1 });

  $self->query("SELECT pb.step_num, pb.step_name, pb.step_tip, pb.id
    FROM msgs_proggress_bar pb
    $WHERE
    GROUP BY pb.id
    ORDER BY $SORT $DESC;",
    undef,
    $attr
  );

  return $self->{list};
}

#**********************************************************
=head2 pb_add($attr)

=cut
#**********************************************************
sub pb_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('msgs_proggress_bar', $attr);

  $admin->system_action_add("MGSG_PB:$self->{INSERT_ID}", { TYPE => 1 });
  return $self;
}

#**********************************************************
=head2 pb_del($attr)

=cut
#**********************************************************
sub pb_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('msgs_proggress_bar', $attr);

  return $self;
}

#**********************************************************
=head2 pb_info($id)

=cut
#**********************************************************
sub pb_info {
  my $self = shift;
  my ($id) = @_;

  $self->query("SELECT * FROM msgs_proggress_bar WHERE id= ? ", undef, { INFO => 1, Bind => [ $id ] });

  return $self;
}

#**********************************************************
=head2 pb_change($attr)

=cut
#**********************************************************
sub pb_change {
  my $self = shift;
  my ($attr) = @_;

  $admin->{MODULE} = $MODULE;
  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'msgs_proggress_bar',
    DATA         => $attr
  });

  return $self->{result};
}


#**********************************************************
=head2 pb_msg_list($attr)

=cut
#**********************************************************
sub pb_msg_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  my $WHERE = $self->search_former($attr, [
    [ 'MSG_ID',             'INT', 'pb_m.msg_id'           ],
    [ 'STEP_NUM',           'INT', 'pb.step_num'           ],
    [ 'STEP_NAME',          'STR', 'pb.step_name'          ],
    [ 'CHAPTER_ID',         'STR', 'pb.chapter_id'         ],
    [ 'USER_NOTICE',        'STR', 'pb.user_notice'        ],
    [ 'RESPONSIBLE_NOTICE', 'STR', 'pb.responsible_notice' ],
    [ 'FOLLOWER_NOTICE',    'STR', 'pb.follower_notice'    ],
    [ 'MAIN_MSG',           'INT', 'mpb.main_msg'          ],
  ], { WHERE => 1 });

  $self->query("SELECT pb.step_num, pb.step_name, mpb.step_date, pb.step_tip,
    mpb.coordx, mpb.coordy, pb.id, pb.user_notice, pb.responsible_notice, pb.follower_notice, mpb.main_msg
    FROM msgs_proggress_bar pb
    LEFT JOIN msgs_message_pb mpb ON (mpb.main_msg='$attr->{MAIN_MSG}' AND mpb.step_num=pb.step_num)
    $WHERE
    GROUP BY pb.id
    ORDER BY pb.step_num;",
    undef,
    $attr
  );

  return $self->{list};
}

#**********************************************************
=head2 pb_msg_change($attr)

=cut
#**********************************************************
sub pb_msg_change {
  my $self = shift;
  my ($attr) = @_;

  $self->query("DELETE FROM `msgs_message_pb` WHERE step_num>='$attr->{STEP_NUM}' AND main_msg='$attr->{ID}'");

  $self->query_add('msgs_message_pb', { %$attr,
    AID       => ($attr->{USER_SEND}) ? 0 : $admin->{AID},
    MAIN_MSG  => $attr->{ID},
    STEP_DATE => 'NOW()'
  });

  return $self->{list};
}


#**********************************************************
=head2 msg_watch_info($msg_id)

=cut
#**********************************************************
sub msg_watch_info {
  my $self = shift;
  my ($msg_id) = @_;

  $self->query('SELECT * FROM msgs_watch WHERE main_msg = ?', undef, { INFO => 1, Bind => [ $msg_id ] });

  return $self;
}

#**********************************************************
=head2 msg_watch($msg_id, $attr)

  Argumenst:
    $attr
      AID
      ID - Main MSG ID

  Results:
    $self

=cut
#**********************************************************
sub msg_watch {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('msgs_watch', {
    %$attr,
    AID      => $attr->{AID} || $admin->{AID},
    MAIN_MSG => $attr->{ID},
    ADD_DATE => 'NOW()'
  });

  return $self->{list};
}

#**********************************************************
=head2 msg_watch_del($attr)

  Arguments:
    $attr
      ID
      AID
  Result:

=cut
#**********************************************************
sub msg_watch_del {
  my $self = shift;
  my ($attr) = @_;

  my $del_params = { MAIN_MSG => $attr->{ID} };
  $del_params->{AID} = $attr->{AID} if $attr->{AID};

  $self->query_del('msgs_watch', undef, $del_params);

  return $self->{list};
}

#**********************************************************
=head2 msg_watch_list($attr)

=cut
#**********************************************************
sub msg_watch_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  my $WHERE = $self->search_former($attr, [
    [ 'MAIN_MSG', 'INT', 'MAIN_MSG' ],
    [ 'AID',      'INT', 'aid'      ],
    [ 'ADD_DATE', 'INT', 'add_date' ],
  ], { WHERE => 1 });

  $self->query("SELECT main_msg, add_date, aid
    FROM msgs_watch
    $WHERE
    ORDER BY $SORT $DESC;",
    undef,
    $attr
  );

  return $self->{list};
}

#**********************************************************
=head2 status_add($attr) -

  Arguments:
    $attr -

  Returns:

  Examples:

=cut
#**********************************************************
sub status_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('msgs_status', $attr);

  return $self;
}

#**********************************************************
=head2 status_list($attr) -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub status_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT = $attr->{SORT} // 'id';

  my $WHERE = $self->search_former($attr, [
    [ 'ID',          'INT', 'id',          1 ],
    [ 'NAME',        'STR', 'name',        1 ],
    [ 'READINESS',   'INT', 'readiness',   1 ],
    [ 'TASK_CLOSED', 'INT', 'task_closed', 1 ],
    [ 'COLOR',       'INT', 'color',       1 ],
    [ 'ICON',        'STR', 'icon',        1 ],
  ], { WHERE => 1 });

  $self->query("SELECT * FROM msgs_status
    $WHERE
    ORDER BY $SORT $DESC;",
    undef,
    $attr
  );

  my $list = $self->{list};

  return $list if ($attr->{STATUS_ONLY} || !$self->{TOTAL} < 1);

  $self->query("SELECT COUNT(*) AS total FROM msgs_status", undef, { INFO => 1 });

  return $list || [];
}

#**********************************************************
=head2 status_del() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub status_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('msgs_status', $attr);

  return $self;
}


#**********************************************************
=head2 status_info() -

  Arguments:
urns:

  Examples:

=cut
#**********************************************************
sub status_info {
  my $self = shift;
  my ($id) = @_;

  $self->query("SELECT * FROM msgs_status WHERE id= ? ", undef, { INFO => 1, Bind => [ $id ] });

  return $self;
}

#**********************************************************
=head2 status_change() -

  Arguments:
     -
  Returns:

  Examples:

=cut
#**********************************************************
sub status_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'msgs_status',
    DATA         => $attr
  });

  return $self;
}

#**********************************************************
=head2 msgs_delivery_add($attr) -

  Arguments:
    $attr -

  Returns:

  Examples:

=cut
#**********************************************************
sub msgs_delivery_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('msgs_delivery', {
    %$attr,
    ADDED => 'NOW()',
    AID   => $admin->{AID},
  });

  $self->{DELIVERY_ID} = $self->{INSERT_ID};

  return $self;
}

#**********************************************************
=head2 msgs_delivery_list($attr) -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub msgs_delivery_list {
  my $self = shift;
  my ($attr) = @_;

  delete($self->{SEARCH_FIELDS});

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  my $WHERE = $self->search_former(
    $attr,
    [
      [ 'ID',          'INT',      'id',            ],
      [ 'SEND_DATE',   'DATE',     'send_date',   1 ],
      [ 'SEND_TIME',   'TIME',     'send_time',   1 ],
      [ 'SUBJECT',     'STR',      'subject',       ],
      [ 'SEND_METHOD', 'INT',      'send_method', 1 ],
      [ 'PRIORITY',    'INT',      'priority',    1 ],
      [ 'STATUS',      'INT',      'status',      1 ],
      [ 'TEXT',        'STR',      'text',        1 ],
      [ 'ADDED',       'DATETIME', 'added',       1 ],
      [ 'AID',         'INT',      'aid',         1 ],
    ],
    { WHERE => 1, }
  );

  $self->query(
    "SELECT
    id,
    $self->{SEARCH_FIELDS}
    subject
    FROM msgs_delivery
    $WHERE
    GROUP BY id
      ORDER BY $SORT $DESC;",
    undef,
    $attr
  );

  my $list = $self->{list};

  if ($self->{TOTAL} > 0) {
    $self->query("SELECT COUNT(*) AS total FROM msgs_delivery md $WHERE", undef, { INFO => 1 });
  }

  return $list;
}

#**********************************************************
=head2 msgs_delivery_del($attr) -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub msgs_delivery_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('msgs_delivery', $attr);
  $self->query_del('msgs_delivery_users', undef, { mdelivery_id => $attr->{ID} });

  return $self;
}


#**********************************************************
=head2 msgs_delivery_info($id) -

  Arguments:
  $id

  Returns:

=cut
#**********************************************************
sub msgs_delivery_info {
  my $self = shift;
  my ($id) = @_;

  $self->query("SELECT * FROM msgs_delivery WHERE id= ? ", undef, { INFO => 1, Bind => [ $id ] });

  return $self;
}

#**********************************************************
=head2 msgs_delivery_change($attr) -

  Arguments:
     $attr
  Returns:

  Examples:

=cut
#**********************************************************
sub msgs_delivery_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'msgs_delivery',
    DATA         => $attr
  });

  if(defined $attr->{STATUS} && $attr->{STATUS} == 0){
    $self->query("UPDATE msgs_delivery_users SET status = 0
    WHERE mdelivery_id= ? ", undef, { Bind => [ $attr->{ID} ] });
  }

  return $self;
}

#**********************************************************
=head2 delivery_user_list_add($attr)

  Arguments:
    $attr
  Returns:

  Examples:

=cut
#**********************************************************
sub delivery_user_list_add {
  my $self = shift;
  my ($attr) = @_;

  my @ids = split(/,\s?/, $attr->{IDS});
  my @MULTI_QUERY = ();

  foreach my $id (@ids) {
    push @MULTI_QUERY, [ $id,
      $attr->{MDELIVERY_ID} || '',
      $attr->{SENDED_DATE} || '',
      $attr->{SEND_METHOD} || '',
      $attr->{STATUS} || 0,
    ];
  }

  $self->query("INSERT IGNORE INTO msgs_delivery_users (uid, mdelivery_id, sended_date, send_method, status)
        VALUES (?, ?, ?, ?, ?);",
    undef,
    { MULTI_QUERY => \@MULTI_QUERY });

  return $self;
}

#**********************************************************
=head2 delivery_user_list($attr)

  Arguments:
     $attr
  Returns:

  Examples:

=cut
#**********************************************************
sub delivery_user_list {
  my $self = shift;
  my ($attr) = @_;

  delete $self->{COL_NAMES_ARR};

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $WHERE = $self->search_former($attr, [
    [ 'ID',           'INT', 'mdl.id'           ],
    [ 'UID',          'INT', 'u.uid'            ],
    [ 'STATUS',       'INT', 'mdl.status'       ],
    [ 'LOGIN',        'STR', 'u.id'             ],
    [ 'PASSWORD',     'STR', '', "DECODE(u.password, '$self->{conf}->{secretkey}') AS password"      ],
    [ 'MDELIVERY_ID', 'INT', 'mdl.mdelivery_id' ],
    [ 'FIO',          'STR', 'pi.fio'           ],
    [ 'EMAIL',        'STR', 'pi.email'         ],
  ],
    {
      WHERE => 1,
    });

  $self->query("SELECT mdl.id, u.id AS login,
      CONCAT(pi.fio,' ',pi.fio2, ' ', pi.fio3) as fio,
      mdl.status,
      mdl.uid,
      $self->{SEARCH_FIELDS}
      pi.email
     FROM msgs_delivery_users mdl
     INNER JOIN users u ON (u.uid=mdl.uid)
     LEFT JOIN users_pi pi ON (mdl.uid=pi.uid)
     $WHERE
     ORDER BY $SORT $DESC
     LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list};

  $self->query("SELECT COUNT(*) AS total
     FROM msgs_delivery_users mdl
     INNER JOIN users u ON (u.uid=mdl.uid)
     $WHERE;",
    undef, { INFO => 1 }
  );

  return $list;
}

#**********************************************************
=head2 delivery_user_list_del($attr)

  Arguments:
     $attr
  Returns:

  Examples:

=cut
#**********************************************************
sub delivery_user_list_del {
  my $self = shift;
  my ($attr) = @_;

  $admin->{MODULE} = $MODULE;
  $self->query_del('msgs_delivery_users', $attr);

  return $self;
}

#**********************************************************
=head2 delivery_user_list_change($attr)

=cut
#**********************************************************
sub delivery_user_list_change {
  my $self = shift;
  my ($attr) = @_;

  my @WHERE_RULES = ("mdelivery_id='$attr->{MDELIVERY_ID}'");

  my $WHERE = $self->search_former($attr, [
    [ 'UID', 'INT', 'uid' ],
    [ 'ID',  'INT', 'id'  ],
  ], { WHERE_RULES => \@WHERE_RULES });

  my $status = $attr->{STATUS} || 1;
  $self->query("UPDATE msgs_delivery_users SET status='$status' WHERE $WHERE;", 'do');

  return $self;
}

#**********************************************************
=head2 messages_reports($attr)
  Arguments:
     $attr
       $attr->{FROM_DATE} - create date
       $attr->{TO_DATE}  - create date
  Returns:
      $list
=cut
#**********************************************************
sub messages_admins_reports {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my @WHERE_RULES = ();

  if ($attr->{FROM_DATE} && $attr->{TO_DATE}) {
    push @WHERE_RULES, "mur.datetime BETWEEN '$attr->{FROM_DATE}' AND '$attr->{TO_DATE}'";
  }

  my $WHERE = $self->search_former(
    $attr,
    [
      [ 'AID',      'INT',      'ra.aid',       1 ],
      [ 'MSG_ID',   'INT',      'mur.id',       1 ],
      [ 'DATETIME', 'DATETIME', 'mur.datetime', 1 ],
    ],
    {
      WHERE       => 1,
      WHERE_RULES => \@WHERE_RULES,
    }
  );

  $self->query("SELECT
    ra.aid,
    ra.id,
    COUNT(DISTINCT mur.id) AS total_msg,
    COUNT(DISTINCT IF(mur.state = 0, mur.id, NULL)) AS open,
    COUNT(DISTINCT IF(mur.state = 1, mur.id, NULL)) AS unmaked,
    COUNT(DISTINCT IF(mur.state = 2, mur.id, NULL)) AS closed,
    COUNT(DISTINCT IF(mur.state = 11, mur.id, NULL)) AS potential_client,
    COUNT(DISTINCT IF(mur.state = 3, mur.id, NULL)) AS in_process,
    mur.datetime
      FROM admins ra
      LEFT JOIN msgs_unreg_requests mur ON (ra.aid=mur.resposible)
      $WHERE
      GROUP BY ra.aid
      ORDER BY $SORT $DESC
      LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list} || [];

  $self->query("SELECT IF(ra.aid=mur.resposible, COUNT(*), NULL) AS total
      FROM admins ra
      LEFT JOIN msgs_unreg_requests mur ON (ra.aid=mur.resposible)
      $WHERE;",
    undef, { INFO => 1 }
  );
  return $list;
}

#**********************************************************
=head2 messages_quick_replys_types_info($id, $attr)

=cut
#**********************************************************
sub messages_quick_replys_types_info {
  my $self = shift;
  my ($id) = @_;

  $self->query("SELECT * FROM msgs_quick_replys_types WHERE id= ? ", undef, { INFO => 1, Bind => [ $id ] });

  return $self;
}

#**********************************************************
=head2 messages_quick_replys_types_change($attr)

=cut
#**********************************************************
sub messages_quick_replys_types_change {
  my $self = shift;
  my ($attr) = @_;

  $admin->{MODULE} = $MODULE;
  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'msgs_quick_replys_types',
    DATA         => $attr,
  });

  return $self->{result};
}

#**********************************************************
=head2 messages_quick_replys_types_del

=cut
#**********************************************************
sub messages_quick_replys_types_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('msgs_quick_replys', undef, { type_id => $attr->{ID} });

  $self->query_del('msgs_quick_replys_types', $attr);

  $admin->system_action_add("MGSG_QUICK_REPORTS_TYPES_DELL:$attr->{ID}", { TYPE => 10 });

  return $self;
}

#**********************************************************
=head2 messages_quick_replys_types_add($attr)

=cut
#**********************************************************
sub messages_quick_replys_types_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('msgs_quick_replys_types', $attr);

  $admin->system_action_add("MGSG_QUICK_REPORTS_TYPES_ADD:$self->{INSERT_ID}", { TYPE => 1 });

  return $self;
}

#**********************************************************
=head2 messages_quick_replys_types_list($attr)

=cut
#**********************************************************
sub messages_quick_replys_types_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : 'DESC';
  $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my @WHERE_RULES = ();

  my $WHERE = $self->search_former($attr, [
    [ 'ID',   'INT', 'qrt.id',   1 ],
    [ 'NAME', 'STR', 'qrt.name', 1 ],
  ], { WHERE => 1, WHERE_RULES => \@WHERE_RULES });

  $self->query("SELECT qrt.*
  FROM msgs_quick_replys_types qrt ".
  $WHERE
  . "GROUP BY qrt.id
  ORDER BY $SORT $DESC
  LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list};

  $self->query("SELECT COUNT(*) AS total FROM msgs_quick_replys_types qrt $WHERE;", undef, { INFO => 1 });

  return $list;
}

#**********************************************************
=head2 messages_quick_replys_info($id, $attr)

=cut
#**********************************************************
sub messages_quick_replys_info {
  my $self = shift;
  my ($id) = @_;

  $self->query("SELECT * FROM msgs_quick_replys WHERE id= ? ", undef, { INFO => 1, Bind => [ $id ] });

  return $self;
}

#**********************************************************
=head2 messages_quick_replys_change($attr)

=cut
#**********************************************************
sub messages_quick_replys_change {
  my $self = shift;
  my ($attr) = @_;

  $admin->{MODULE} = $MODULE;
  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'msgs_quick_replys',
    DATA         => $attr,
  });

  return $self->{result};
}

#**********************************************************
=head2 messages_quick_replys_del

=cut
#**********************************************************
sub messages_quick_replys_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('msgs_quick_replys', $attr);

  $admin->system_action_add("MSGS_QUICK_REPLYS_DELL:$attr->{ID}", { TYPE => 10 });

  return $self;
}

#**********************************************************
=head2 messages_quick_replys_add($attr)

=cut
#**********************************************************
sub messages_quick_replys_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('msgs_quick_replys', $attr);

  $admin->system_action_add("MSGS_QUICK_REPLYS_ADD:$self->{INSERT_ID}", { TYPE => 1 });
  return $self;
}

#**********************************************************
=head2 messages_quick_replys_list($attr)

=cut
#**********************************************************
sub messages_quick_replys_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my @WHERE_RULES = ();

  my $WHERE = $self->search_former($attr, [
    [ 'ID',      'INT', 'qr.id',            1 ],
    [ 'REPLY',   'STR', 'qr.reply',         1 ],
    [ 'TYPE_ID', 'INT', 'qr.type_id',       1 ],
    [ 'TYPE',    'STR', 'qrt.name AS type', 1 ],
    [ 'COLOR',   'STR', 'qr.color',         1 ],
    [ 'COMMENT', 'STR', 'qr.comment',       1 ],
  ], { WHERE => 1, WHERE_RULES => \@WHERE_RULES });

  $self->query("SELECT $self->{SEARCH_FIELDS} qr.color,
  qr.reply, qrt.name AS type
  FROM msgs_quick_replys qr
  LEFT JOIN msgs_quick_replys_types qrt ON (qrt.id=qr.type_id)
  $WHERE
  GROUP BY qr.id
  ORDER BY $SORT $DESC;",
    undef,
    $attr
  );

  return [] if ($self->{errno});

  my $list = $self->{list};

  $self->query("SELECT COUNT(*) AS total
    FROM msgs_quick_replys qr
    LEFT JOIN msgs_quick_replys_types qrt ON (qrt.id=qr.type_id)
    $WHERE;",
    undef,
    { INFO => 1 },
  );

  return $list;
}

#**********************************************************
=head2 quick_replys_tags_info($id)

=cut
#**********************************************************
sub quick_replys_tags_info {
  my $self = shift;
  my ($id) = @_;

  $self->query('SELECT *
    FROM msgs_quick_replys_tags
  WHERE msg_id = ? ;',
    undef,
    { INFO => 1,
      Bind => [ $id ] }
  );

  return $self;
}

#**********************************************************
=head2 quick_replys_tags_change($attr)

=cut
#**********************************************************
sub quick_replys_tags_change {
  my $self = shift;
  my ($attr) = @_;

  $admin->{MODULE} = $MODULE;
  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'msgs_quick_replys_tags',
    DATA         => $attr
  });

  return $self->{result};
}

#**********************************************************
=head2 quick_replys_tags_del

=cut
#**********************************************************
sub quick_replys_tags_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('msgs_quick_replys_tags', $attr);

  $admin->system_action_add("ADD MSGS TAG:$attr->{ID}", { TYPE => 10 });

  return $self;
}

#**********************************************************
=head2 quick_replys_tags_add($attr)

=cut
#**********************************************************
sub quick_replys_tags_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('msgs_quick_replys_tags', undef, { msg_id => $attr->{MSG_ID} });

  my @ids = split(/,\s?/, $attr->{IDS});
  my @MULTI_QUERY = ();

  foreach my $id (@ids) {
    push @MULTI_QUERY, [ $id, $attr->{MSG_ID} || '' ];
  }

  $self->query("INSERT msgs_quick_replys_tags (quick_reply_id, msg_id) VALUES (?, ?);",
    undef, { MULTI_QUERY => \@MULTI_QUERY });

  return $self;
}

#**********************************************************
=head2 quick_replys_tags_list($attr)

=cut
#**********************************************************
sub quick_replys_tags_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : 'DESC';
  $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my @WHERE_RULES = ();

  my $WHERE = $self->search_former($attr, [
    [ 'MSG_ID',         'INT', 'qrt.msg_id',         1 ],
    [ 'QUICK_REPLY_ID', 'INT', 'qrt.quick_reply_id', 1 ],
    [ 'REPLY',          'STR', 'qr.reply',           1 ],
    [ 'COLOR',          'STR', 'qr.color',           1 ],
    [ 'COMMENT',        'STR', 'qr.comment',         1 ]
  ], { WHERE => 1, WHERE_RULES => \@WHERE_RULES });

  $self->query("SELECT qrt.*,
    qr.reply,
    qr.type_id,
    qr.color,
    qr.comment
  FROM msgs_quick_replys_tags qrt
  LEFT JOIN msgs_quick_replys qr ON(qr.id=qrt.quick_reply_id)
  $WHERE
  ORDER BY $SORT $DESC
  LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list} || [];

  return $list if ($self->{errno});

  $self->query("SELECT COUNT(*) AS total FROM msgs_quick_replys_tags qrt $WHERE;", undef, { INFO => 1 });

  return $list;
}

#**********************************************************
=head2 messages_report_per_month($attr)

=cut
#**********************************************************
sub messages_report_closed {
  my $self = shift;
  my ($attr) = @_;

  $self->query("SELECT DATE_FORMAT(m.closed_date, \'%Y-%m\') AS month,
    COUNT(DISTINCT m.id) AS total_msgs,
    SUM(t1.time) AS run_time,
    SUM(t1.replys) AS total_replys,
    SUM(m.rating) AS total_rating
  FROM msgs_messages m
  LEFT JOIN (SELECT mr.main_msg, SUM(mr.run_time) as time, COUNT(DISTINCT mr.id) AS replys FROM msgs_reply mr GROUP BY mr.main_msg) as t1 ON (m.id=t1.main_msg)
  WHERE m.closed_date >= ? AND m.closed_date <= ?
  GROUP BY month;",
    undef,
    { COLS_NAME => 1, Bind => [ $attr->{F_DATE}, $attr->{T_DATE} ] }
  );

  return $self->{list};
}

#**********************************************************
=head2 messages_report_per_month($attr)

=cut
#**********************************************************
sub messages_report_tags_count {
  my $self = shift;
  my ($attr) = @_;

  my $WHERE = $self->search_former($attr, [
    [ 'FROM_DATE|TO_DATE', 'DATE', "DATE_FORMAT(mm.date, '%Y-%m-%d')" ],
    [ 'SUBTAG',            'INT',  "mt2.quick_reply_id"               ],
    [ 'TAG_ID',            'INT',  "mt1.quick_reply_id"               ],
  ], { WHERE => 1 });
  my $EXT_TABLES = "";

  $EXT_TABLES = "LEFT JOIN msgs_quick_replys_tags mt2 ON (mt1.msg_id = mt2.msg_id)" if ($attr->{SUBTAG});

  $self->query("SELECT count(mt1.msg_id) as count
    FROM msgs_quick_replys_tags mt1
    LEFT JOIN msgs_messages mm ON (mt1.msg_id = mm.id)
    $EXT_TABLES
    $WHERE;",
    undef,
    { COLS_NAME => 1 }
  );

  return $self->{list}->[0]->{count} || 0;
}

#**********************************************************
=head2 messages_report_per_month($attr)

=cut
#**********************************************************
sub messages_tags_total_count {
  my $self = shift;
  my ($attr) = @_;

  my $WHERE = $self->search_former($attr, [ [ 'FROM_DATE|TO_DATE', 'DATE', "DATE_FORMAT(mm.date, '%Y-%m-%d')" ], ], { WHERE => 1 });

  $self->query("SELECT count(*) as total
    FROM msgs_quick_replys_tags mt
    LEFT JOIN msgs_messages mm ON (mt.msg_id = mm.id)
    $WHERE;",
    undef,
    { COLS_NAME => 1 }
  );

  return $self->{list}->[0]->{total};
}

#**********************************************************
=head2 messages_report_replys($attr)

=cut
#**********************************************************
sub messages_report_replys_time {
  my $self = shift;
  my ($attr) = @_;

  my $WHERE = $self->search_former($attr, [
    [ 'FROM_DATE|TO_DATE', 'DATE', "DATE_FORMAT(mr.datetime, '%Y-%m-%d')" ],
    [ 'AID',               'INT',  "mr.aid"                               ],
  ], { WHERE => 1 });

  $self->query("SELECT 
    DATE_FORMAT(mr.datetime, '%Y-%m') AS month,
    SUM(mr.run_time) as run_time,
    COUNT(mr.id) as replys
    FROM msgs_reply mr
    $WHERE
    GROUP BY month;",
    undef,
    { COLS_NAME => 1 }
  );

  return $self->{list};
}

#**********************************************************
=head2 msgs_storage_add()

  Arguments:
    MSGS_ID                      - Identifier of ticket
    STORAGE_INCOMING_ARTICLES_ID - ID from storage_incoming_articles table

  Returns:

=cut
#**********************************************************
sub msgs_storage_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('msgs_storage', {
    %$attr,
    AID  => $self->{admin}{AID},
    DATE => 'NOW()'
  });

  return $self;
}

#**********************************************************
=head2 msgs_storage_list()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub msgs_storage_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $WHERE = $self->search_former(
    $attr,
    [
      [ 'ID',                    'INT',  'ms.id',                            1 ],
      [ 'MSGS_ID' ,              'INT',  'ms.msgs_id',                       1 ],
      [ 'INSTALLATION_ID' ,      'INT',  'ms.installation_id',               1 ],
      [ 'ARTICLE_TYPE_NAME',     'STR',  'sat.name as article_type_name',    1 ],
      [ 'ARTICLE_NAME',          'STR',  'sa.name as article_name',          1 ],
      [ 'COUNT',                 'STR',  'si.count',                         1 ],
      [ 'MEASURE_NAME',          'STR',  'sm.name as measure_name',          1 ],
      [ 'COUNT_MEASURE',         'STR',  'CONCAT(si.count, " ", sm.name) as count_measure',   1 ],
      [ 'SERIAL',                'STR',  'ss.serial',                        1 ],
      [ 'ADMIN_NAME',            'STR',  'a.name as admin_name',             1 ],
      [ 'DATE',                  'DATE', 'ms.date',                          1 ],
    ],
    { WHERE => 1, }
  );

  $self->query(
    "SELECT
    $self->{SEARCH_FIELDS}
    ms.id
    FROM msgs_storage as ms
    LEFT JOIN admins                    a   ON (ms.aid = a.aid)
    INNER JOIN storage_installation      si  ON (si.id = ms.installation_id)
    LEFT JOIN storage_incoming_articles sia ON (si.storage_incoming_articles_id = sia.id)
    LEFT JOIN storage_articles          sa  ON (sa.id = sia.article_id)
    LEFT JOIN storage_article_types     sat ON (sat.id = sa.article_type)
    LEFT JOIN storage_measure           sm  ON (sm.id = sa.measure)
    LEFT JOIN storage_sn                ss  ON (ss.id= sia.sn)
    $WHERE
    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list};

  return $self->{list} if ($self->{TOTAL} < 1);

  $self->query(
    "SELECT COUNT(*) AS total
   FROM msgs_storage as ms
   LEFT JOIN admins                    a   ON (ms.aid = a.aid)
    LEFT JOIN storage_installation      si  ON (si.id = ms.installation_id)
    LEFT JOIN storage_incoming_articles sia ON (si.storage_incoming_articles_id = sia.id)
    LEFT JOIN storage_articles          sa  ON (sa.id = sia.article_id)
    LEFT JOIN storage_article_types     sat ON (sat.id = sa.article_type)
    LEFT JOIN storage_measure           sm  ON (sm.id = sa.measure)
    $WHERE",
    undef,
    { INFO => 1 }
  );

  return $list || [];
}

#**********************************************************
=head2 message_team_add()

  Arguments:
     ID             - id ticket
     RESPONSIBLE    - ID responsible team
     STATE          - status ticket
     id_team        - id team

  Returns:
    $self

=cut
#**********************************************************
sub message_team_add {
  my $self = shift;
  my ($attr) = @_;

  return $self->query_add('msgs_team_ticket', $attr);
}

#**********************************************************
=head2 message_team_change()

  Arguments:
     ID           - new ticket id
     RESPONSIBLE  - new responsible id
     ID_TEAM      - new id team
     ID_SEARCH    - old id ticket search

  Returns:
    $self

=cut
#**********************************************************
sub message_team_change {
  my $self = shift;
  my ($attr) = @_;

  $self->query("UPDATE msgs_team_ticket AS mdt SET mdt.id = ?, mdt.responsible = ?, mdt.id_team = ? WHERE mdt.id = ?;", undef, {
    Bind => [ $attr->{ID}, $attr->{RESPONSIBLE}, $attr->{ID_TEAM}, $attr->{ID_SEARCH} ]
  });

  return $self;
}

#**********************************************************
=head2 message_team_del()

  Arguments:
     ID         - id dispatch delete value

  Returns:
    $self       - state query

=cut
#**********************************************************
sub message_team_del {
  my $self = shift;
  my ($id) = @_;

  my @id_del_msgs = split(/, /, $id);

  $self->query('DELETE FROM `msgs_team_ticket` WHERE id IN (' . join(',', @id_del_msgs) . ')' );

  return $self;
}

#**********************************************************
=head2 responsible_team_info()

  Arguments:
     ID         - id team

  Returns:
    list        - id and responisble team

=cut
#**********************************************************
sub responsible_team_info {
  my $self = shift;
  my ($id) = @_;

  $self->query("SELECT md.id, md.resposible FROM msgs_dispatch md WHERE md.id = ?", undef, {
    Bind      => [ $id ],
    COLS_NAME => 1,
    INFO      => 1
  });

  return $self->{list};
}

#**********************************************************
=head2 respnosible_info_change()

  Arguments:
     ID         - dispatch change

  Returns:
    dispatch info for id

=cut
#**********************************************************
sub respnosible_info_change {
  my $self = shift;
  my ($id) = @_;

  $self->query("SELECT mdt.id, mdt.responsible, mm.subject FROM msgs_team_ticket AS mdt
    LEFT JOIN msgs_messages AS mm ON mdt.id = mm.id
    WHERE mdt.id = ?;", undef, {
    COLS_NAME => 1,
    INFO      => 1,
    Bind      => [ $id ]
  });

  return $self->{list}[0];
}

#**********************************************************
=head2 ticket_team_list()

  Arguments:
     ID               - id ticket
     RESPONSIBLE      - responsible team
     STATE            - status ticket
     ID_TEAM          - id team
     NAME             - name admin responsible team

  Returns:
    list              - date team ticket

=cut
#**********************************************************
sub ticket_team_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;
  
  my $GROUP_BY = ($attr->{GROUP_BY}) ? 'GROUP BY 1' : '';

  my $WHERE = $self->search_former(
    $attr,
    [
      [ 'ID',                    'INT',  'mdt.id',                            1 ],
      [ 'RESPONSIBLE',           'INT',  'mdt.responsible',                   1 ],
      [ 'STATE' ,                'INT',  'mdt.state',                         1 ],
      [ 'ID_TEAM',               'INT',  'mdt.id_team',                       1 ],
      [ 'LOGIN',                 'STR',  'a.id AS login',                     1 ],
      [ 'NAME',                  'STR',  'a.name',                            1 ],
    ],
    { WHERE => 1 }
  );

  $self->query("SELECT $self->{SEARCH_FIELDS} mdt.id
    FROM msgs_team_ticket
    AS mdt LEFT JOIN admins AS a ON a.aid = mdt.responsible
    $WHERE $GROUP_BY", undef, {
    COLS_NAME => 1,
    INFO      => 1
  });

  return $self->{list} || [];
}

#**********************************************************
=head2 responsible_team_list()

  Arguments:
     -

  Returns:
    list      - admins responsible team

=cut
#**********************************************************
sub responsible_team_list {
  my $self = shift;

  $self->query("SELECT md.id, md.resposible, a.id AS aid, CONCAT(a.name, ' ',  md.id) as name FROM msgs_dispatch AS md
    LEFT JOIN admins a ON md.resposible = a.aid WHERE a.aid IS NOT NULL;",
    undef, { COLS_NAME => 1, INFO => 1 });

  return $self->{list};
}

#**********************************************************
=head2 team_location_add()

  Arguments:
     ID_TEAM        - id team set location
     DISTRICT_ID    -
     STREET_ID      -
     BUILD_ID       -

  Returns:
    $self           - status query

=cut
#**********************************************************
sub team_location_add {
  my $self = shift;
  my ($attr) = @_;

  return $self->query_add('msgs_team_address', $attr);
}

#**********************************************************
=head2 team_location_change()

  Arguments:
     ID             - id team for location
     DISTRICT_ID    -
     STREET_ID      -
     BUILD_ID       -
     $id            - id serach address

  Returns:
    $self           - status query

=cut
#**********************************************************
sub team_location_change {
  my $self = shift;
  my ($id, $attr) = @_;

  $self->query("UPDATE msgs_team_address AS mda SET mda.id_team = ?, mda.district_id = ?, mda.street_id = ?, mda.build_id = ?
    WHERE mda.id = ?;", undef, {
    Bind => [ $attr->{ID}, $attr->{DISTRICT_ID}, $attr->{STREET_ID}, $attr->{BUILD_ID}, $id ]
  });

  return $self;
}

#**********************************************************
=head2 team_location_del()

  Arguments:
     ID         - id dispatch address

  Returns:
    $self       - status query

=cut
#**********************************************************
sub team_location_del {
  my $self = shift;
  my ($id) = @_;

  $self->query_del('msgs_team_address', undef, { ID => $id });

  return $self;
}

#**********************************************************
=head2 team_location_list()

  Arguments:
     ID             - id dispatach address
     ID_TEAM        - id team for address
     DISTRICT_ID    - 
     STREET_ID      -
     BUILD_ID       -
     NUMBER         - number build
     NAME_DISTRICT  -
     NAME_STREET    -

  Returns:
    list location for set team

=cut
#**********************************************************
sub team_location_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $WHERE = $self->search_former(
    $attr,
    [
      [ 'ID',                    'INT',  'mda.id',                            1 ],
      [ 'ID_TEAM',               'INT',  'mda.id_team',                       1 ],
      [ 'DISTRICT_ID',           'INT',  'mda.district_id',                   1 ],
      [ 'STREET_ID' ,            'INT',  'mda.street_id',                     1 ],
      [ 'BUILD_ID',              'INT',  'mda.build_id',                      1 ],
      [ 'NUMBER',                'STR',  'b.number',                          1 ],
      [ 'NAME_DISTRICT',         'STR',  'd.name AS name_district',           1 ],
      [ 'NAME_STREET',           'STR',  's.name AS name_street',             1 ],
    ],
    { WHERE => 1 }
  );

  $self->query("SELECT $self->{SEARCH_FIELDS} mda.id
    FROM msgs_team_address AS mda
    LEFT JOIN districts d on mda.district_id = d.id
    LEFT JOIN builds b on mda.build_id = b.id
    LEFT JOIN  streets s on b.street_id = s.id
    $WHERE", undef, {
    COLS_NAME => 1,
    INFO      => 1
  });

  return $self->{list};
}

#**********************************************************
=head2 msgs_plugin_add($attr)

  Arguments:
    ID      - ID Plugin

  Return:
    query add result

=cut
#**********************************************************
sub msgs_plugin_add {
  my $self = shift;
  my ($attr) = @_;

  return $self->query_add('msgs_admin_plugins', $attr);
}

#**********************************************************
=head2 msgs_plugin_del($attr)

  Arguments:
    ID      - ID Plugin

  Return:
    query delete result

=cut
#**********************************************************
sub msgs_plugin_del {
  my $self = shift;
  my ($attr) = @_;

  return $self->query_del('msgs_admin_plugins', $attr);
}

#**********************************************************
=head2 msgs_plugin_change($attr)

  Arguments:
    ID

  Return:
    query change result

=cut
#**********************************************************
sub msgs_plugin_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes({
    CHANGE_PARAM    => 'PLUGIN_NAME,ID',
    TABLE           => 'msgs_admin_plugins',
    DATA            => $attr,
  });

  return $self->{result};
}

#**********************************************************
=head2 msgs_plugin_list($attr)

  Arguments:
    AID         - Admin aid enabled plugin
    PLUGIN_NAME - Plugin enabled name
    MODULE      - Plugin module

  Return:
    plugin enabled list result

=cut
#**********************************************************
sub msgs_plugin_list {
  my $self = shift;
  my ($attr) = @_;

  my $WHERE = $self->search_former(
    $attr,
    [
      [ 'ID',            'INT',  'map.id AS aid',         1 ],
      [ 'PLUGIN_NAME',   'STR',  'map.plugin_name',       1 ],
      [ 'MODULE',        'STR',  'map.module',            1 ],
      [ 'PRIORITY',      'INT',  'map.priority',          1 ],
    ],
    { WHERE => 1 }
  );

  $self->query("SELECT $self->{SEARCH_FIELDS} map.module FROM msgs_admin_plugins AS map $WHERE GROUP BY map.plugin_name", undef, {
    COLS_NAME => 1,
    INFO      => 1
  });

  return $self->{list} || [ ];
}

#**********************************************************
=head2 total_tickets_by_current_month($attr)

=cut
#**********************************************************
sub total_tickets_by_current_month {
  my $self = shift;
  my ($attr) = @_;

  my $WHERE = 'WHERE MONTH(m.date) = MONTH(CURRENT_DATE()) AND YEAR(m.date) = YEAR(CURRENT_DATE())';
  $WHERE .= " AND m.uid=$attr->{UID}" if $attr->{UID};

  $self->query("SELECT COUNT(*) AS total_tickets, SUM(messages.reply_time) AS total_time FROM (SELECT SUM(r.run_time) AS reply_time
      FROM msgs_messages m
      LEFT JOIN msgs_reply r FORCE INDEX FOR JOIN (`main_msg`) ON (m.id=r.main_msg)
      $WHERE
      GROUP BY m.id
      ORDER BY 1) AS messages",
    undef,
    { INFO => 1 }
  );

  return $self;
}

#**********************************************************
=head2 total_replies_by_time($attr)

=cut
#**********************************************************
sub total_replies_by_time {
  my $self = shift;
  my ($attr) = shift;

  my $date = $attr->{DATE};
  return $self if !$date;

  my $aid_statement = $attr->{AID} ? "AND mr.aid=$attr->{AID} " : "AND mr.aid <> 0";

  $self->query("SELECT DATE_FORMAT(m.date, '%Y-%m') AS month, AVG(m.rating) AS avg_rating
    FROM msgs_messages m
    WHERE DATE_FORMAT(m.closed_date,'%Y-%m') = '$date' AND m.state IN(1,2)" . ($attr->{AID} ? " AND m.resposible=$attr->{AID}" : '') . "
    GROUP BY month",
    undef,
    { INFO => 1 }
  );

  $self->query("SELECT count(m.id) as total, (case

    when ((SELECT MIN(mr.datetime) FROM msgs_reply mr
    WHERE mr.main_msg=m.main_msg AND mr.datetime > m.datetime $aid_statement)) IS NULL then 'empty'

    when (TIMEDIFF((SELECT MIN(mr.datetime) FROM msgs_reply mr
    WHERE mr.main_msg=m.main_msg AND mr.datetime > m.datetime $aid_statement), m.datetime)) <= CAST('00:15:00' AS time) then 'less15min'

    when (TIMEDIFF((SELECT MIN(mr.datetime) FROM msgs_reply mr
    WHERE mr.main_msg=m.main_msg AND mr.datetime > m.datetime $aid_statement), m.datetime)) <= CAST('00:30:00' AS time) then 'between15_30min'

    when (TIMEDIFF((SELECT MIN(mr.datetime) FROM msgs_reply mr
    WHERE mr.main_msg=m.main_msg AND mr.datetime > m.datetime $aid_statement), m.datetime)) <= CAST('01:00:00' AS time) then 'between30_60min'

    when (TIMEDIFF((SELECT MIN(mr.datetime) FROM msgs_reply mr
    WHERE mr.main_msg=m.main_msg AND mr.datetime > m.datetime $aid_statement), m.datetime)) <= CAST('02:00:00' AS time) then 'between1_2hrs'

    when (TIMEDIFF((SELECT MIN(mr.datetime) FROM msgs_reply mr
    WHERE mr.main_msg=m.main_msg AND mr.datetime > m.datetime $aid_statement), m.datetime)) <= CAST('04:00:00' AS time) then 'between2_4hrs'

    when (TIMEDIFF((SELECT MIN(mr.datetime) FROM msgs_reply mr
    WHERE mr.main_msg=m.main_msg AND mr.datetime > m.datetime $aid_statement), m.datetime)) <= CAST('08:00:00' AS time) then 'between4_8hrs'

    when (TIMEDIFF((SELECT MIN(mr.datetime) FROM msgs_reply mr
    WHERE mr.main_msg=m.main_msg AND mr.datetime > m.datetime $aid_statement), m.datetime)) <= CAST('12:00:00' AS time) then 'between8_12hrs'

    when (TIMEDIFF((SELECT MIN(mr.datetime) FROM msgs_reply mr
    WHERE mr.main_msg=m.main_msg AND mr.datetime > m.datetime $aid_statement), m.datetime)) <= CAST('24:00:00' AS time) then 'between12_24hrs'

    when (TIMEDIFF((SELECT MIN(mr.datetime) FROM msgs_reply mr
    WHERE mr.main_msg=m.main_msg AND mr.datetime > m.datetime $aid_statement), m.datetime)) <= CAST('48:00:00' AS time) then 'between24_48hrs'

    when (TIMEDIFF((SELECT MIN(mr.datetime) FROM msgs_reply mr
    WHERE mr.main_msg=m.main_msg AND mr.datetime > m.datetime $aid_statement), m.datetime)) > CAST('48:00:00' AS time) then 'more48'

    end) as period

    FROM msgs_reply m
    WHERE DATE_FORMAT(m.datetime, '%Y-%m') = '$date'
    GROUP BY period

    HAVING period <> 'empty'",
    undef,
    { COLS_NAME => 1 }
  );

  return $self->{list} || [];
}

#**********************************************************
=head2 messages_and_replies_for_two_weeks($attr)

=cut
#**********************************************************
sub messages_and_replies_for_two_weeks {
  my $self = shift;
  my $date = shift;

  if ($date) {
    $self->query("SELECT DATE_FORMAT(closed_date, '%Y-%m-%d') AS day, COUNT(id) as closed_messages
      FROM msgs_messages
      WHERE DATE_FORMAT(closed_date, '%Y-%m-%d') IN ($date) AND state IN (SELECT id FROM msgs_status WHERE task_closed = 1)
      GROUP BY day;",
      undef, { COLS_NAME => 1 }
    );

    return $self->{list} || [];
  }

  $self->query("SELECT
      0 AS replies,
      SUM(IF(uid <> 0, 1, 0)) AS messages,
      DATE_FORMAT(date, '%Y-%m-%d') AS day
    FROM msgs_messages
    WHERE DATEDIFF(DATE_FORMAT(NOW(), '%Y-%m-%d' ), DATE_FORMAT(date, '%Y-%m-%d' )) <= 14
    GROUP BY day

    UNION

    SELECT
      SUM(IF(aid <> 0, 1, 0)) AS replies,
      SUM(IF(uid <> 0 AND aid = 0, 1, 0)) AS messages,
      DATE_FORMAT(datetime, '%Y-%m-%d') AS day
    FROM msgs_reply
    WHERE DATEDIFF(DATE_FORMAT(NOW(), '%Y-%m-%d' ), DATE_FORMAT(datetime, '%Y-%m-%d' )) <= 14 AND inner_msg = 0
    GROUP BY day",
    undef,
    { COLS_NAME => 1 }
  );

  return $self->{list} || [];
}

#**********************************************************
=head2 msgs_messages_and_users_by_months($attr)

=cut
#**********************************************************
sub msgs_messages_and_users_by_months {
  my $self = shift;
  my ($attr) = @_;

  my $from_date = $attr->{FROM_DATE} ? "'$attr->{FROM_DATE}'" : 'NOW() - INTERVAL 1 YEAR';
  my $to_date = $attr->{TO_DATE} ? "'$attr->{TO_DATE}'" : 'NOW()';
  my $closed_status = $attr->{CLOSED_STATUS} || '1,2';

  $self->query("SELECT dates.*,
      (SELECT COUNT(u.uid) FROM users u WHERE DATE_FORMAT(u.registration, '%Y-%m') <= dates.month) as users,
      (SELECT COUNT(m.id) FROM msgs_messages m WHERE DATE_FORMAT(m.date, '%Y-%m') <= dates.month
        AND m.uid <> '') as messages,
      (SELECT COUNT(m.id) FROM msgs_messages m WHERE DATE_FORMAT(m.date, '%Y-%m') <= dates.month
        AND m.uid <> '' AND m.state IN ($closed_status)) as closed_messages
    FROM (
      SELECT DATE_FORMAT(u.registration, '%Y-%m') AS month
      FROM users u
      WHERE DATE_FORMAT(u.registration, '%Y-%m') <= DATE_FORMAT($to_date, '%Y-%m') AND
        DATE_FORMAT(u.registration, '%Y-%m') >= DATE_FORMAT($from_date, '%Y-%m')
      GROUP BY month
    ) AS dates
    GROUP BY dates.month",
    undef,
    { COLS_NAME => 1 }
  );

  return $self->{list} || [];
}

#**********************************************************
=head2 subjects_list($attr)

=cut
#**********************************************************
sub subjects_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT = $attr->{SORT} // 'id';

  my $WHERE = $self->search_former($attr, [
    [ 'ID',          'INT', 'id',          1 ],
    [ 'NAME',        'STR', 'name',        1 ],
    [ 'DOMAIN_ID',   'INT', 'domain_id',   1 ],
  ], { WHERE => 1 });

  $self->query("SELECT * FROM msgs_subjects
    $WHERE
    ORDER BY $SORT $DESC;",
    undef,
    $attr
  );

  my $list = $self->{list};

  $self->query("SELECT COUNT(*) AS total FROM msgs_subjects", undef, { INFO => 1 });

  return $list || [];
}

#**********************************************************
=head2 subject_info()

=cut
#**********************************************************
sub subject_info {
  my $self = shift;
  my ($id) = @_;

  $self->query("SELECT * FROM msgs_subjects WHERE id= ? ", undef, { INFO => 1, Bind => [ $id ] });

  return $self;
}

#**********************************************************
=head2 subject_add($attr)

=cut
#**********************************************************
sub subject_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('msgs_subjects', $attr);

  return $self;
}

#**********************************************************
=head2 subject_del()

=cut
#**********************************************************
sub subject_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('msgs_subjects', $attr);

  return $self;
}

#**********************************************************
=head2 subject_change()

=cut
#**********************************************************
sub subject_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'msgs_subjects',
    DATA         => $attr
  });

  return $self;
}

#**********************************************************
=head2 permissions_list($aid)

=cut
#**********************************************************
sub permissions_list {
  my $self = shift;
  my $aid = shift;

  if ($aid) {
    $self->query("SELECT section, actions FROM msgs_permits WHERE aid = ?;", undef, { Bind => [ $aid ], COLS_NAME => 1 });
  }
  else {
    $self->query("SELECT aid, section, actions FROM msgs_permits;", undef, { COLS_NAME => 1 });
  }

  my $msgs_permissions = {};
  foreach my $line (@{$self->{list}}) {
    if ($line->{aid}) {
      $msgs_permissions->{$line->{aid}}{$line->{section}}{$line->{actions}} = 1;
      next;
    }

    $msgs_permissions->{$line->{section}}{$line->{actions}} = 1;
  }

  if (!$self->{errno} && $aid) {
    my $admin_info = $self->admins_list({
      CHAPTER_ID => !$msgs_permissions->{4} ? '_SHOW' : join(';', keys %{$msgs_permissions->{4}}),
      AID        => $aid,
      COLS_NAME  => 1
    });

    map $msgs_permissions->{deligation_level}{$_->{chapter_id}} = $_->{deligation_level}, @{$admin_info};
  }

  return $msgs_permissions;
}

#**********************************************************
=head2 set_permissions($aid, $permissions) - Set admin msgs permissions

=cut
#**********************************************************
sub set_permissions {
  my $self = shift;
  my ($aid, $permissions) = @_;

  return $self if !$aid;

  my @MULTI_QUERY = ();
  foreach my $section (sort keys %{$permissions}) {
    foreach my $action (sort keys %{$permissions->{$section}}) {
      push @MULTI_QUERY, [ $aid, $section, $action ];
    }
  }

  $self->query("DELETE FROM `msgs_permits` WHERE `aid`= ? ;", 'do', { Bind => [ $aid ] });

  $self->query("INSERT INTO `msgs_permits` (`aid`, `section`, `actions`) VALUES (?, ?, ?);",
    undef, { MULTI_QUERY => \@MULTI_QUERY });

  return $self;
}

#**********************************************************
=head2 msgs_type_permits_list($attr) - Msgs type permits list

=cut
#**********************************************************
sub msgs_type_permits_list {
  my $self = shift;
  my ($attr) = @_;

  my $WHERE = $self->search_former( $attr, [
    [ 'TYPE',    'STR', 'type',     1],
    [ 'SECTION', 'INT', 'section', 1 ],
    [ 'ACTIONS', 'INT', 'actions', 1 ]
  ], { WHERE => 1 });

  $self->query("SELECT type, section, actions
    FROM msgs_type_permits
    $WHERE;",
    undef,
    { COLS_NAME => 1 }
  );

  return $self->{list} || [];
}

#**********************************************************
=head2 msgs_set_type_permits($permissions) - Set msgs type permits

  Arguments:
    $permissions - hash of permits
    $type - name of template

=cut
#**********************************************************
sub msgs_set_type_permits {
  my $self = shift;
  my ($type, $permissions) = @_;

  return $self if !$type;

  my @MULTI_QUERY = ();
  foreach my $section (sort keys %{$permissions}) {
    foreach my $action (sort keys %{$permissions->{$section}}) {
      push @MULTI_QUERY, [ $type, $section, $action ];
    }
  }

  $self->query("DELETE FROM `msgs_type_permits` WHERE `type` = ? ;", 'do', { Bind => [ $type ] });

  $self->query("INSERT INTO `msgs_type_permits` (`type`, `section`, `actions`) VALUES (?, ?, ?);",
    undef, { MULTI_QUERY => \@MULTI_QUERY });

  return $self;
}

#**********************************************************
=head2 msgs_del_type_permits($type)

  Arguments:
    $type - name of template

=cut
#**********************************************************
sub msgs_del_type_permits {
  my $self = shift;
  my $type = shift;

  $self->query("DELETE FROM msgs_type_permits WHERE type = ? ;", 'do', { Bind => [ $type ] });

  return $self;
}

#**********************************************************
=head2 msgs_workflow_add()

=cut
#**********************************************************
sub msgs_workflow_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('msgs_workflows', $attr);
  return $self if $self->{errno} || !$self->{INSERT_ID};

  my $workflow_id = $self->{INSERT_ID};
  $self->msgs_workflow_triggers_add({ TRIGGERS => $attr->{TRIGGERS}, WORKFLOW_ID => $workflow_id });
  $self->msgs_workflow_actions_add({ ACTIONS => $attr->{ACTIONS}, WORKFLOW_ID => $workflow_id });

  return $workflow_id;
}

#**********************************************************
=head2 msgs_workflow_change()

=cut
#**********************************************************
sub msgs_workflow_change {
  my $self = shift;
  my ($attr) = @_;

  $attr->{DISABLE} = 0 if !$attr->{DISABLE};

  $self->changes({
    CHANGE_PARAM => 'ID',
    FIELDS       => {
      DISABLE => 'disable',
      NAME    => 'name',
      DESCR   => 'DESCR',
    },
    TABLE        => 'msgs_workflows',
    OLD_INFO     => $self->msgs_workflow_info($attr->{ID}),
    DATA         => $attr
  });
  return $self if $self->{errno};

  $self->msgs_workflow_triggers_add({ TRIGGERS => $attr->{TRIGGERS}, WORKFLOW_ID => $attr->{ID} });
  $self->msgs_workflow_actions_add({ ACTIONS => $attr->{ACTIONS}, WORKFLOW_ID => $attr->{ID} });

  return $self;
}

#**********************************************************
=head2 msgs_workflow_triggers_add()

=cut
#**********************************************************
sub msgs_workflow_triggers_add {
  my $self = shift;
  my ($attr) = @_;

  my $workflow_id = $attr->{WORKFLOW_ID};
  return $self if !$workflow_id;

  my @MULTI_QUERY = ();
  foreach my $trigger (@{$attr->{TRIGGERS}}) {
    push @MULTI_QUERY, [ $workflow_id, $trigger->{type}, $trigger->{old_value} || '',
      $trigger->{new_value} || '', $trigger->{contains} || '' ];
  }

  $self->query("DELETE FROM `msgs_workflow_triggers` WHERE `workflow_id` = ? ;", 'do', { Bind => [ $workflow_id ] });
  $self->query("INSERT INTO `msgs_workflow_triggers` (`workflow_id`, `type`, `old_value`, `new_value`, `contains`) VALUES (?, ?, ?, ?, ?);",
    undef, { MULTI_QUERY => \@MULTI_QUERY });

  return $self;
}

#**********************************************************
=head2 msgs_workflow_actions_add()

=cut
#**********************************************************
sub msgs_workflow_actions_add {
  my $self = shift;
  my ($attr) = @_;

  my $workflow_id = $attr->{WORKFLOW_ID};
  return $self if !$workflow_id;

  my @MULTI_QUERY = ();
  foreach my $trigger (@{$attr->{ACTIONS}}) {
    push @MULTI_QUERY, [ $workflow_id, $trigger->{type}, $trigger->{value} || '' ];
  }

  $self->query("DELETE FROM `msgs_workflow_actions` WHERE `workflow_id` = ? ;", 'do', { Bind => [ $workflow_id ] });
  $self->query("INSERT INTO `msgs_workflow_actions` (`workflow_id`, `type`, `value`) VALUES (?, ?, ?);",
    undef, { MULTI_QUERY => \@MULTI_QUERY });

  return $self;
}

#**********************************************************
=head2 msgs_workflow_list()

=cut
#**********************************************************
sub msgs_workflow_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = $attr->{SORT} || 1;
  my $DESC = $attr->{DESC} || '';

  my $WHERE = $self->search_former($attr, [
    [ 'ID',         'INT', 'mw.id',         1 ],
    [ 'NAME',       'STR', 'mw.name',       1 ],
    [ 'DESCR',      'STR', 'mw.descr',      1 ],
    [ 'DISABLE',    'INT', 'mw.disable',    1 ],
    [ 'USED_TIMES', 'INT', 'mw.used_times', 1 ]
  ], { WHERE => 1 });

  $self->query("SELECT $self->{SEARCH_FIELDS} mw.id
    FROM msgs_workflows mw
    $WHERE
    ORDER BY $SORT $DESC;",
    undef,
    $attr
  );

  return $self->{list} || [];
}

#**********************************************************
=head2 msgs_workflow_del()

=cut
#**********************************************************
sub msgs_workflow_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('msgs_workflows', $attr);

  if (!$self->{errno}) {
    $self->query_del('msgs_workflow_triggers', undef, { WORKFLOW_ID => $attr->{ID} });
    $self->query_del('msgs_workflow_actions', undef, { WORKFLOW_ID => $attr->{ID} });
  }

  return $self;
}

#**********************************************************
=head2 msgs_workflow_info()

=cut
#**********************************************************
sub msgs_workflow_info {
  my $self = shift;
  my $id = shift;

  $self->query("SELECT * FROM msgs_workflows WHERE id = ? ", undef, { INFO => 1, Bind => [ $id ] });

  return $self;
}

#**********************************************************
=head2 msgs_workflow_triggers_list()

=cut
#**********************************************************
sub msgs_workflow_triggers_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = $attr->{SORT} || 1;
  my $DESC = $attr->{DESC} || '';

  my $WHERE = $self->search_former($attr, [
    [ 'ID',          'INT', 'mwt.id',          1 ],
    [ 'TYPE',        'STR', 'mwt.type',        1 ],
    [ 'OLD_VALUE',   'STR', 'mwt.old_value',   1 ],
    [ 'NEW_VALUE',   'STR', 'mwt.new_value',   1 ],
    [ 'CONTAINS',    'STR', 'mwt.contains',    1 ],
    [ 'WORKFLOW_ID', 'INT', 'mwt.workflow_id', 1 ]
  ], { WHERE => 1 });

  $self->query("SELECT $self->{SEARCH_FIELDS} mwt.id
    FROM msgs_workflow_triggers mwt
    $WHERE
    ORDER BY $SORT $DESC;",
    undef,
    $attr
  );

  return $self->{list} || [];
}

#**********************************************************
=head2 msgs_workflow_actions_list()

=cut
#**********************************************************
sub msgs_workflow_actions_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = $attr->{SORT} || 1;
  my $DESC = $attr->{DESC} || '';

  my $WHERE = $self->search_former($attr, [
    [ 'ID',          'INT', 'mwa.id',          1 ],
    [ 'TYPE',        'STR', 'mwa.type',        1 ],
    [ 'VALUE',       'STR', 'mwa.value',       1 ],
    [ 'WORKFLOW_ID', 'INT', 'mwa.workflow_id', 1 ]
  ], { WHERE => 1 });

  $self->query("SELECT $self->{SEARCH_FIELDS} mwa.id
    FROM msgs_workflow_actions mwa
    $WHERE
    ORDER BY $SORT $DESC;",
    undef,
    $attr
  );

  return $self->{list} || [];
}


#**********************************************************
=head2 _msgs_workflow($type, $msg_id, $attr)

=cut
#**********************************************************
sub _msgs_workflow {
  my $self = shift;
  my $type = shift;
  my $msg_id = shift;
  my ($attr) = @_;

  return if !$type || !$msg_id;

  $self->query("SELECT * FROM msgs_workflow_triggers WHERE workflow_id IN (
    SELECT workflow_id FROM msgs_workflow_triggers mwt
    LEFT JOIN msgs_workflows mw ON (mw.id = mwt.workflow_id)
    WHERE mwt.type='$type' AND mw.disable = 0);",
    undef,
    { COLS_NAME => 1 }
  );

  return if !$self->{list};

  my $check_workflow = sub {
    my ($workflow) = @_;

    foreach my $trigger (@{$workflow}) {
      my $function = $triggers->{$trigger->{type}};
      return 0 if !$function || ref $function ne 'CODE';

      return 0 if !$function->($self, $trigger, $attr);
    }

    return 1;
  };

  my @checked_workflows = ();
  my $workflows = {};
  foreach my $trigger (@{$self->{list}}) {
    push @{$workflows->{$trigger->{workflow_id}}}, $trigger;
  }

  foreach my $workflow_id (keys %{$workflows}) {
    push(@checked_workflows, $workflow_id) if $check_workflow->($workflows->{$workflow_id});
  }

  my $workflow_ids = join(',', @checked_workflows);
  return if !$workflow_ids;

  $self->query("SELECT * FROM msgs_workflow_actions WHERE workflow_id IN ($workflow_ids) ORDER BY workflow_id;",
    undef, { COLS_NAME => 1 }
  );
  return if !$self->{list};

  foreach my $action (@{$self->{list}}) {
    my $function = $actions->{$action->{type}};
    next if !$function || ref $function ne 'CODE';

    $function->($self, $action, $msg_id);
  }

  return $self
}

#**********************************************************
=head2 _msgs_trigger_handlers()

=cut
#**********************************************************
sub _msgs_trigger_handlers {
  my $self = shift;

  return {
    isNew              => sub {
      my $self = shift;

      return 1 if $self->{MSG_ID};
    },
    isChanged          => sub {
      my $self = shift;
      my (undef, $attr) = @_;

      return 1 if $attr->{CHANGED};
    },
    replyAdded         => sub {
      my $self = shift;

      return 1 if $self->{REPLY_ID};
    },
    responsible        => sub {
      my $self = shift;
      my ($trigger, $attr) = @_;

      return 1 if !$trigger->{new_value};

      $attr->{RESPOSIBLE} //= $attr->{OLD_INFO}{RESPOSIBLE};
      return 0 if !$attr->{RESPOSIBLE};

      return in_array($attr->{RESPOSIBLE}, [ split(',\s?', $trigger->{new_value}) ]) ? 1 : 0;
    },
    chapter            => sub {
      my $self = shift;
      my ($trigger, $attr) = @_;

      return 1 if !$trigger->{new_value};

      $attr->{CHAPTER} //= $attr->{OLD_INFO}{CHAPTER};
      return 0 if !$attr->{CHAPTER};

      return in_array($attr->{CHAPTER}, [ split(',\s?', $trigger->{new_value}) ]) ? 1 : 0;
    },
    status             => sub {
      my $self = shift;
      my ($trigger, $attr) = @_;

      return 1 if !defined $trigger->{new_value};

      $attr->{STATE} //= $attr->{OLD_INFO}{STATE};
      return 0 if !defined $attr->{STATE};

      return in_array($attr->{STATE}, [ split(',\s?', $trigger->{new_value}) ]) ? 1 : 0;
    },
    sender             => sub {
      my $self = shift;
      my ($trigger, $attr) = @_;

      return 1 if !$trigger->{new_value};

      return $trigger->{new_value} eq 'aid' && !$attr->{USER_SEND} ? 1 : $trigger->{new_value} eq 'uid' && $attr->{USER_SEND} ? 1 : 0;
    },
    responsibleChanged => sub {
      my $self = shift;
      my ($trigger, $attr) = @_;

      return 1 if !$trigger->{new_value} && !defined $trigger->{old_value};

      $attr->{OLD_INFO}{RESPOSIBLE} //= '';
      return 0 if !$attr->{RESPOSIBLE};

      return $trigger->{new_value} eq $attr->{RESPOSIBLE} && $trigger->{old_value} eq $attr->{OLD_INFO}{RESPOSIBLE} ? 1 : 0;
    },
    statusChanged      => sub {
      my $self = shift;
      my ($trigger, $attr) = @_;

      return 1 if !defined $trigger->{new_value} && !defined $trigger->{old_value};
      return 0 if !defined $attr->{STATE} || !defined $attr->{OLD_INFO}{STATE};

      return $trigger->{new_value} == $attr->{STATE} && in_array($attr->{OLD_INFO}{STATE}, [ split(',\s?', $trigger->{old_value}) ]) ? 1 : 0;
    },
    subjectContains    => sub {
      my $self = shift;
      my ($trigger, $attr) = @_;

      $attr->{SUBJECT} ||= $attr->{OLD_INFO}{SUBJECT};

      return 0 if !$attr->{SUBJECT} || !$trigger->{contains};

      return 1 if $attr->{SUBJECT} =~ m/$trigger->{contains}/;
    }
  }
}

#**********************************************************
=head2 _msgs_action_handlers()

=cut
#**********************************************************
sub _msgs_action_handlers {

  return {
    sendMessage    => sub {
      my $self = shift;
      my ($action, $msg_id) = @_;

      $self->query_add('msgs_reply', {
        MAIN_MSG => $msg_id,
        TEXT     => $action->{value},
        DATETIME => 'NOW()',
        AID      => $admin->{AID},
        ID       => undef
      });
    },
    setStatus      => sub {
      my $self = shift;
      my ($action, $msg_id) = @_;

      return if !$msg_id || !defined $action->{value};

      $self->changes({
        CHANGE_PARAM => 'ID',
        TABLE        => 'msgs_messages',
        DATA         => {
          STATE => $action->{value},
          ID    => $msg_id
        }
      });
    },
    setResponsible => sub {
      my $self = shift;
      my ($action, $msg_id) = @_;

      return if !$msg_id || !defined $action->{value};

      $self->changes({
        CHANGE_PARAM => 'ID',
        TABLE        => 'msgs_messages',
        DATA         => {
          RESPOSIBLE => $action->{value},
          ID         => $msg_id
        }
      });
    },
    setTags        => sub {
      my $self = shift;
      my ($action, $msg_id) = @_;

      return if !$msg_id || !$action->{value};

      $self->quick_replys_tags_add({ IDS => $action->{value}, MSG_ID => $msg_id });
    }
  }
}

1;
