package Dv;

=head1 NAME

  Dialup & Vpn DB managment functions

=cut

use strict;
use base qw( main );
use Tariffs;
use Users;
use Fees;
use POSIX qw(strftime mktime);

our $VERSION = 2.00;
my $MODULE = 'Dv';

my ($admin, $CONF);

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
    db          => $db,
    admin       => $admin,
    conf        => $CONF,
    module_name => $MODULE,
  };

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 info($uid, $attr) User service information

=cut
#**********************************************************
sub info {
  my $self = shift;
  my ($uid, $attr) = @_;

  my $WHERE = '';

  if (defined($attr->{LOGIN}) && $attr->{LOGIN} ne '') {
    my $users = Users->new($self->{db}, $admin, $self->{conf});
    $users->info(0, { LOGIN => "$attr->{LOGIN}" });
    if ($users->{errno}) {
      $self->{errno}  = 2;
      $self->{errstr} = 'ERROR_NOT_EXIST';
      return $self;
    }

    $uid                      = $users->{UID};
    $self->{DEPOSIT}          = $users->{DEPOSIT};
    $self->{ACCOUNT_ACTIVATE} = $users->{ACTIVATE};
    $WHERE                    = "WHERE dv.uid='$uid'";
  }

  $WHERE = "WHERE dv.uid='$uid'";

  if (defined($attr->{IP})) {
    $WHERE = "WHERE dv.ip=INET_ATON('$attr->{IP}')";
  }

  my $domain_id = 0;
  if ($admin->{DOMAIN_ID}) {
    $domain_id = $admin->{DOMAIN_ID};
  }
  elsif ($attr->{DOMAIN_ID}) {
    $domain_id = $attr->{DOMAIN_ID};
  }

  $self->query2("SELECT dv.*,
   tp.name AS tp_name,
   INET_NTOA(dv.ip) AS ip,
   INET_NTOA(dv.netmask) AS netmask,
   dv.disable AS status,
   tp.gid AS tp_gid,
   tp.month_fee AS month_abon,
   tp.day_fee AS day_abon,
   tp.postpaid_monthly_fee AS postpaid_abon,
   tp.payment_type,
   dv.expire AS dv_expire,
   tp.abon_distribution,
   tp.credit AS tp_credit,
   tp.tp_id AS tp_num,
   tp.priority AS tp_priority,
   tp.activate_price AS tp_activate_price,
   tp.change_price AS tp_change_price,
   tp.age AS tp_age,
   tp.filter_id AS tp_filter_id,
   tp.period_alignment AS tp_period_alignment,
   tp.fixed_fees_day,
   tp.comments,
   tp.reduction_fee,
   tp.user_credit_limit,
   DECODE(dv.password, '$self->{conf}->{secretkey}') AS password
     FROM dv_main dv
     LEFT JOIN tarif_plans tp ON ((tp.module='Dv' OR tp.module='')
        AND dv.tp_id=tp.id
        AND tp.domain_id IN (SELECT users.domain_id FROM users WHERE users.uid='$uid'))
   $WHERE;",
   undef,
   { INFO => 1 }
  );

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
    STATUS         => 0,
    IP             => '0.0.0.0',
    NETMASK        => '255.255.255.255',
    SPEED          => 0,
    FILTER_ID      => '',
    CID            => '',
    CALLBACK       => 0,
    PORT           => 0,
    JOIN_SERVICE   => 0,
    TURBO_MODE     => 0
  );

  $self = \%DATA;
  return $self;
}

#**********************************************************
=head2 add($attr) - Add service

=cut
#**********************************************************
sub add {
  my $self = shift;
  my ($attr) = @_;

  if (! $attr->{DV_SKIP_FEE} && $attr->{TP_ID} > 0 && !$attr->{STATUS}) {
    my $tariffs = Tariffs->new($self->{db}, $self->{conf}, $admin);

    $self->{TP_INFO} = $tariffs->info(0, { ID        => $attr->{TP_ID},
                                           MODULE    => 'Dv',
                                           DOMAIN_ID => $admin->{DOMAIN_ID} || undef
                                          });

    #Take activation price
    if ($tariffs->{ACTIV_PRICE} > 0) {
      my $user = Users->new($self->{db}, $admin, $self->{conf});
      $user->info($attr->{UID});

      if ($self->{conf}->{FEES_PRIORITY} =~ /bonus/ && $user->{EXT_BILL_DEPOSIT}) {
        $user->{DEPOSIT} += $user->{EXT_BILL_DEPOSIT};
      }

      if ($user->{DEPOSIT} + $user->{CREDIT} < $tariffs->{ACTIV_PRICE} && $tariffs->{PAYMENT_TYPE} == 0) {
        $self->{errno} = 15;
        $self->{errstr} = "Active price too hight";
        return $self;
      }

      my $fees = Fees->new($self->{db}, $admin, $self->{conf});
      $fees->take($user, $tariffs->{ACTIV_PRICE}, { DESCRIBE => '$lang{ACTIVATE_TARIF_PLAN}' });
      $tariffs->{ACTIV_PRICE} = 0;
    }
  }

  if(!$attr->{NETMASK}) {
    $attr->{NETMASK}='255.255.255.255';
  }

  $self->query_add('dv_main', {
    %$attr,
    REGISTRATION => 'now()',
    DISABLE      => $attr->{STATUS},
    PASSWORD     => ($attr->{PASSWORD}) ? "ENCODE('$attr->{PASSWORD}', '$self->{conf}->{secretkey}')" : ''
  });

  return [ ] if ($self->{errno});

  $admin->{MODULE} = $MODULE;
  $admin->action_add($attr->{UID}, '', {
    TYPE    => 1,
    INFO    => ['TP_ID', 'DV_LOGIN', 'STATUS', 'DV_EXPIRE', 'IP', 'CID'],
    REQUEST => $attr
  });

  return $self;
}

#**********************************************************
=head2 change($attr)

=cut
#**********************************************************
sub change {
  my $self = shift;
  my ($attr) = @_;

  if (!$attr->{CALLBACK}) {
    $attr->{CALLBACK} = 0;
  }

  $attr->{DISABLE}=$attr->{STATUS};
  $attr->{EXPIRE}=$attr->{DV_EXPIRE};

  my $old_info = $self->info($attr->{UID});
  $self->{OLD_STATUS} = $old_info->{STATUS};

  if ($attr->{TP_ID} && $old_info->{TP_ID} != $attr->{TP_ID}) {
    my $user = Users->new($self->{db}, $admin, $self->{conf});
    $user->info($attr->{UID});

    my $tariffs = Tariffs->new($self->{db}, $self->{conf}, $admin);
    $tariffs->info(0, {
      ID        => $old_info->{TP_ID},
      MODULE    => 'Dv',
      DOMAIN_ID => $user->{DOMAIN_ID} || $admin->{DOMAIN_ID}
    });

    %{ $self->{TP_INFO_OLD} } = %{ $tariffs };
    $self->{TP_INFO} = $tariffs->info(0, {
      ID        => $attr->{TP_ID},
      MODULE    => 'Dv',
      DOMAIN_ID => $admin->{DOMAIN_ID}
    });

    if ($self->{conf}->{FEES_PRIORITY} && $self->{conf}->{FEES_PRIORITY} =~ /bonus/ && $user->{EXT_BILL_DEPOSIT}) {
      $user->{DEPOSIT} += $user->{EXT_BILL_DEPOSIT};
    }

    my $skip_change_fee = 0;
    if ($self->{conf}->{DV_TP_CHG_FREE}) {
      my ($y, $m, $d) = split(/-/, $user->{REGISTRATION}, 3);
      my $cur_date = time();
      my $registration = POSIX::mktime(0, 0, 0, $d, ($m - 1), ($y - 1900));
      if (($cur_date - $registration) / 86400 > $self->{conf}->{DV_TP_CHG_FREE}) {
        $skip_change_fee = 1;
      }
    }

    #Active TP
    if ($old_info->{STATUS} == 2 && (defined($attr->{STATUS}) && $attr->{STATUS} == 0) && $tariffs->{ACTIV_PRICE} > 0) {
      if ($user->{DEPOSIT} + $user->{CREDIT} < $tariffs->{ACTIV_PRICE} && $tariffs->{PAYMENT_TYPE} == 0 && $tariffs->{POSTPAID_FEE} == 0) {
        $self->{errno} = 15;
        $self->{errstr} = "Active price too hight";
        return $self;
      }

      my $Fees = Fees->new($self->{db}, $admin, $self->{conf});
      $Fees->take($user, $tariffs->{ACTIV_PRICE}, { DESCRIBE => '$lang{ACTIVATE_TARIF_PLAN}' });

      $tariffs->{ACTIV_PRICE} = 0;
    }
    # Change TP
    elsif (!$skip_change_fee
      && $tariffs->{CHANGE_PRICE} > 0
      && (($self->{TP_INFO_OLD}->{PRIORITY} || 0) - $tariffs->{PRIORITY} > 0
        || ($self->{TP_INFO_OLD}->{PRIORITY} || 0) + $tariffs->{PRIORITY} == 0)
      && !$attr->{NO_CHANGE_FEES})
    {
      if ($user->{DEPOSIT} + $user->{CREDIT} < $tariffs->{CHANGE_PRICE}) {
        $self->{errno} = 15;
        $self->{errstr} = "Change price too hight";
        return $self;
      }

      my $Fees = Fees->new($self->{db}, $admin, $self->{conf});
      $Fees->take($user, $tariffs->{CHANGE_PRICE}, { DESCRIBE => "CHANGE TP" });
    }

    if ($tariffs->{AGE} > 0) {
      $attr->{EXPIRE} = POSIX::strftime("%Y-%m-%d", localtime(time + 86400 * $tariffs->{AGE}));

      eval { require Date::Calc };
      if (!$@) {
        Date::Calc->import( qw/Add_Delta_Days/ );

        my (undef, undef, undef,$mday,$mon,$year,undef,undef,undef) = localtime(time);
        $year += 1900;
        $mon++;
        ($year,$mon,$mday) = Date::Calc::Add_Delta_Days($year, $mon, $mday, $tariffs->{AGE});
        $attr->{EXPIRE} ="$year-$mon-$mday";
      }
    }
#    else {
#      $attr->{EXPIRE} = "0000-00-00";
#    }
  }
  elsif (($old_info->{STATUS} && $old_info->{STATUS} == 3)
    && $attr->{STATUS} == 0
    && $attr->{STATUS_DAYS}) {
    my $user = Users->new($self->{db}, $admin, $self->{conf});
    $user->info($attr->{UID});
    my $fees = Fees->new($self->{db}, $admin, $self->{conf});
    #period : sum
    my (undef, $sum) = split(/:/, $self->{conf}->{DV_REACTIVE_PERIOD}, 2);
    $fees->take($user, $sum, { DESCRIBE => "REACTIVE" });
  }
  elsif (($old_info->{STATUS}
         && ($old_info->{STATUS} == 1
           || $old_info->{STATUS} == 2
           || $old_info->{STATUS} == 3
           || $old_info->{STATUS} == 4
           || $old_info->{STATUS} == 5))
         && defined($attr->{STATUS}) && $attr->{STATUS} == 0) {
    my $tariffs = Tariffs->new($self->{db}, $self->{conf}, $admin);
    $self->{TP_INFO} = $tariffs->info(0, {
      ID        => $old_info->{TP_ID},
      MODULE    => 'Dv',
      DOMAIN_ID => $admin->{DOMAIN_ID}
    });

    #Alignment for hold up
    if($old_info->{STATUS} == 3 && ! $self->{TP_INFO}->{PERIOD_ALIGNMENT} && ! $self->{TP_INFO}->{ABON_DISTRIBUTION}) {
      delete ($self->{TP_INFO});
    }
  }

  #$attr->{JOIN_SERVICE} = ($attr->{JOIN_SERVICE}) ? $attr->{JOIN_SERVICE} : 0;

  $admin->{MODULE} = $MODULE;

  $self->changes2(
    {
      CHANGE_PARAM => 'UID',
      TABLE        => 'dv_main',
      DATA         => $attr
    }
  );

  $self->{TP_INFO}->{ACTIV_PRICE} = 0 if ($self->{OLD_STATUS} != 2);

  if($self->{AFFECTED}) {
    $self->info($attr->{UID});
  }

  return $self;
}

#**********************************************************
=head2 del(attr); Delete user service

=cut
#**********************************************************
sub del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('dv_main', $attr, { uid => $self->{UID} });
  $self->query_del('dv_log', undef, { uid => $self->{UID} });

  $admin->action_add($self->{UID}, "$self->{UID}", { TYPE => 10 });
  return $self->{result};
}

#**********************************************************
=head2 list($attr) - Dv users list

=cut
#**********************************************************
sub list {
  my $self   = shift;
  my ($attr) = @_;

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $GROUP_BY = ($attr->{GROUP_BY}) ? $attr->{GROUP_BY} : 'u.uid';
  if ($attr->{CID}) {
    $attr->{CID}=~s/[\:\-\.]/\*/g;
  }

  $self->{EXT_TABLES}     = '';
  $self->{SEARCH_FIELDS}  = '';
  $self->{SEARCH_FIELDS_COUNT}=0;

  my $WHERE =  $self->search_former($attr, [
      ['IP',             'IP',  'dv.ip',     'dv.ip AS ip_num'        ], #'INET_NTOA(dv.ip) AS ip' ],
      ['IP_NUM',         'IP',  'dv.ip',     'dv.ip AS ip_num'        ],
      ['NETMASK',        'IP',  'dv.netmask', 'INET_NTOA(dv.netmask) AS netmask' ],
      ['CID',            'STR', 'dv.cid',                           1 ],
      ['JOIN_SERVICE',   'INT', 'dv.join_service',                  1 ],
      ['SIMULTANEONSLY', 'INT', 'dv.logins',                        1 ],
      ['SPEED',          'INT', 'dv.speed',                         1 ],
      ['PORT',           'INT', 'dv.port',                          1 ],
      ['ALL_FILTER_ID',  'STR', 'if(dv.filter_id<>\'\', dv.filter_id, tp.filter_id) AS filter_id', 1 ],
      ['FILTER_ID',      'STR', 'dv.filter_id',                     1 ],
      ['TP_ID',          'INT', 'dv.tp_id',                         1 ],
      ['TP_NAME',        'STR', 'tp.name AS tp_name',               1 ],
      ['TP_COMMENTS',    'STR', 'tp.comments', 'tp.comments AS tp_comments' ],
      ['TP_CREDIT',      'INT', 'tp.credit', 'tp.credit AS tp_credit' ],
      ['ONLINE',         'INT', 'c.uid',            'c.uid AS online' ],
      ['ONLINE_IP',      'INT', 'INET_NTOA(c.framed_ip_address)', 'INET_NTOA(c.framed_ip_address) AS online_ip' ],
      ['ONLINE_DURATION','INT', 'c.uid',  'IF(c.lupdated>UNIX_TIMESTAMP(c.started), c.lupdated - UNIX_TIMESTAMP(c.started), 0) AS online_duration' ],
      ['ONLINE_CID',     'INT', 'c.CID',        'c.CID AS online_cid' ],
      ['MONTH_FEE',      'INT', 'tp.month_fee',                     1 ],
      ['ABON_DISTRIBUTION', 'INT', 'tp.abon_distribution',          1 ],
      ['DAY_FEE',        'INT', 'tp.day_fee',                       1 ],
      ['PERSONAL_TP',    'INT', 'dv.personal_tp',                   1 ],
      ['PAYMENT_TYPE',   'INT', 'tp.payment_type',                  1 ],
      ['DV_LOGIN',       'STR', 'dv.dv_login',                      1 ],
      ['DV_PASSWORD',    '',    '',  "DECODE(dv.password, '$CONF->{secretkey}') AS dv_password" ],
      ['DV_STATUS',      'INT', 'dv.disable AS dv_status',          1 ],
      ['DV_STATUS_ID',   'INT', 'dv.disable AS dv_status_id',       1 ],
      ['DV_EXPIRE',      'DATE','dv.expire as dv_expire',           1 ],
      ['DV_STATUS_DATE', '',    '', '(SELECT aa.datetime FROM admin_actions aa WHERE aa.uid=dv.uid AND aa.module=\'Dv\'
       AND aa.action_type IN (4, 8, 14)
       ORDER BY aa.datetime DESC LIMIT 1) AS dv_status_date' ],
      ['MONTH_TRAFFIC_IN',  'INT', '', "SUM(l.recv) AS month_traffic_in" ],
      ['MONTH_TRAFFIC_OUT', 'INT', '', "SUM(l.sent) AS month_traffic_out" ],
      ['UID',            'INT', 'dv.uid',                           1 ],
    ],
    { WHERE            => 1,
      USERS_FIELDS_PRE => 1,
      USE_USER_PI      => 1,
      SKIP_USERS_FIELDS=> [ 'UID' ]
    }
    );

  my $EXT_TABLE = $self->{EXT_TABLES} || '';
  if($self->{SEARCH_FIELDS} =~ /online/) {
    $EXT_TABLE .= "
     LEFT JOIN dv_calls c ON (c.uid=dv.uid) ";
  }

  if ($attr->{USERS_WARNINGS}) {
    my $allert_period = '';
    if ($attr->{ALERT_PERIOD}) {
      $allert_period = "OR  (tp.month_fee > 0  AND IF(u.activate='0000-00-00',
      DATEDIFF(DATE_FORMAT(curdate() + INTERVAL 1 MONTH, '%Y-%m-01'), curdate()),
      DATEDIFF(u.activate + INTERVAL 30 DAY, CURDATE())) IN ($attr->{ALERT_PERIOD}))";
    }

    $self->query2("SELECT u.id AS login,
        pi.email,
        dv.tp_id AS tp_num,
        u.credit,
        b.deposit,
        tp.name AS tp_name,
        tp.uplimit,
        pi.phone,
        pi.fio,
        IF(u.activate='0000-00-00',
          DATEDIFF(DATE_FORMAT(CURDATE() + INTERVAL 1 MONTH, '%Y-%m-01'), curdate()),
          DATEDIFF(u.activate + INTERVAL 30 DAY, CURDATE())) AS to_next_period,
        $self->{SEARCH_FIELDS}
        u.uid
      FROM users u
      INNER JOIN dv_main dv ON (u.uid=dv.uid)
      INNER JOIN tarif_plans tp ON (dv.tp_id = tp.id AND tp.module='Dv')
      $EXT_TABLE
      " . (($WHERE) ? $WHERE . ' AND' : q{}) ."
         u.disable  = 0
         AND dv.disable = 0
         AND b.deposit+u.credit>0
         AND (((tp.month_fee=0 OR tp.abon_distribution=1) AND tp.uplimit > 0 AND b.deposit<tp.uplimit)
             $allert_period
              )

      GROUP BY u.uid
      ORDER BY u.id;",
      undef,
      $attr
    );

    return [] if ($self->{errno});

    my $list = $self->{list};
    return $list;
  }
  elsif ($attr->{CLOSED}) {
    $self->query2("SELECT u.id, pi.fio, IF(company.id IS NULL, b.deposit, b.deposit),
       IF(u.company_id=0, u.credit,
          if (u.credit=0, company.credit, u.credit)) AS credit,
      tp.name, u.disable,
      u.uid, u.company_id, u.email, u.tp_id, if(l.start is NULL, '-', l.start)
     FROM ( users u, bills b )
     LEFT JOIN users_pi pi ON u.uid=dv.uid
     LEFT JOIN tarif_plans tp ON  (tp.id=u.tp_id AND tp.module='Dv')
     LEFT JOIN companies company ON  (u.company_id=company.id)
     LEFT JOIN dv_log l ON  (l.uid=u.uid)
     WHERE
        u.bill_id=b.id
        and (b.deposit+u.credit-tp.credit_tresshold<=0)
        OR (
        (u.expire<>'0000-00-00' and u.expire < CURDATE())
        AND (u.activate<>'0000-00-00' and u.activate > CURDATE())
        )
        OR u.disable=1
     GROUP BY u.uid
     ORDER BY $SORT $DESC;"
    );

    my $list = $self->{list};
    return $list;
  }

  if ($attr->{MONTH_TRAFFIC_IN} || $attr->{MONTH_TRAFFIC_OUT}) {
    $EXT_TABLE .= "
     LEFT JOIN dv_log l ON (l.uid=dv.uid AND DATE_FORMAT(l.start, '%Y-%m')=DATE_FORMAT(curdate(), '%Y-%m')) ";
  }

  $self->query2("SELECT
      $self->{SEARCH_FIELDS}
      u.uid,
      dv.tp_id
     FROM users u
     INNER JOIN dv_main dv ON (u.uid=dv.uid)
     LEFT JOIN tarif_plans tp ON (tp.id=dv.tp_id AND tp.module='Dv')
     $EXT_TABLE
     $WHERE
     GROUP BY $GROUP_BY
     ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
     undef,
     $attr
  );

  return [] if ($self->{errno});

  my $list = $self->{list};

  if ($self->{TOTAL} >= 0 && !$attr->{SKIP_TOTAL}) {
    $self->query2("SELECT COUNT( DISTINCT u.id) AS total FROM users u
    INNER JOIN dv_main dv ON (u.uid=dv.uid)
    LEFT JOIN tarif_plans tp ON (tp.id=dv.tp_id AND tp.module='Dv')
    $EXT_TABLE
    $WHERE",
    undef,
    { INFO => 1 }
    );
  }

  return $list;
}

#**********************************************************
=head2 report_debetors($attr)

=cut
#**********************************************************
sub report_debetors {
  my $self = shift;
  my ($attr) = @_;

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $WHERE =  $self->search_former($attr, [
      ['UID',            'INT', 'dv.uid',                           1 ],
      ['DV_STATUS',      'INT', 'dv.disable as dv_status',          1 ],
    ],
    {
      USERS_FIELDS_PRE => 1,
      USE_USER_PI      => 1,
      SKIP_USERS_FIELDS=> [ 'UID' ]
    }
    );

  my $EXT_TABLES = $self->{EXT_TABLES};
  $WHERE = " AND ". $WHERE if ($WHERE);

  if (! $attr->{PERIOD}) {
    $attr->{PERIOD} = 1;
  }

  $self->query2("SELECT
      $self->{SEARCH_FIELDS}
      u.uid
     FROM users u
     INNER JOIN dv_main dv ON (u.uid=dv.uid)
     LEFT JOIN tarif_plans tp ON (tp.id=dv.tp_id AND tp.module='Dv')
      $EXT_TABLES
     WHERE IF(u.company_id > 0, cb.deposit, b.deposit) < 0 - tp.month_fee*$attr->{PERIOD} $WHERE
     GROUP BY u.id
     ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
     undef,
     $attr
  );

  return $self->{list} if ($self->{errno});

  my $list = $self->{list};

  if ($self->{TOTAL} >= 0 && !$attr->{SKIP_TOTAL}) {
    $self->query2("SELECT COUNT(*) AS total, SUM(IF(u.company_id > 0, cb.deposit, b.deposit)) AS total_debetors_sum
      FROM users u
    INNER JOIN dv_main dv ON (u.uid=dv.uid)
    LEFT JOIN tarif_plans tp ON (tp.id=dv.tp_id AND tp.module='Dv')
    $EXT_TABLES
    WHERE IF(u.company_id > 0, cb.deposit, b.deposit) < 0 - tp.month_fee*$attr->{PERIOD}
    $WHERE",
    undef,
    { INFO => 1 }
    );
  }

  return $list;
}


#**********************************************************
=head2 report_tp()

=cut
#**********************************************************
sub report_tp {
  my $self = shift;
  my ($attr) = @_;

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  $self->{EXT_TABLES}     = '';
  $self->{SEARCH_FIELDS}  = '';
  $self->{SEARCH_FIELDS_COUNT}=0;
  $attr->{DELETED}=0;

  my $WHERE =  $self->search_former($attr, [
      ['DOMAIN_ID',            'INT', 'tp.domain_id',  ],
    ],
    { WHERE       => 1,
      USERS_FIELDS=> 1
    }
  );

  $self->query2("SELECT dv.tp_id AS id, tp.name, count(DISTINCT dv.uid) AS counts,
      COUNT(DISTINCT CASE WHEN dv.disable=0 AND u.disable=0 THEN dv.uid ELSE NULL END) AS active,
      COUNT(DISTINCT CASE WHEN dv.disable=1 AND u.disable=1 THEN dv.uid ELSE NULL END) AS disabled,
      SUM(IF(IF(u.company_id > 0, cb.deposit, b.deposit) < 0, 1, 0)) AS debetors,
      ROUND(SUM(p.sum) / COUNT(DISTINCT dv.uid), 2) AS arpu,
      ROUND(SUM(p.sum) / COUNT(DISTINCT p.uid), 2) AS arppu,
      tp.tp_id
    FROM users u
    INNER JOIN dv_main dv ON (u.uid=dv.uid)
    LEFT JOIN tarif_plans tp ON (tp.id=dv.tp_id AND tp.module='Dv')
    LEFT JOIN bills b ON (u.bill_id = b.id)
    LEFT JOIN companies company ON  (u.company_id=company.id)
    LEFT JOIN bills cb ON  (company.bill_id=cb.id)
    LEFT JOIN payments p ON (p.uid=dv.uid
       AND (p.date >= DATE_FORMAT(CURDATE(), '%Y-%m-01 00:00:00') AND p.date <= CONCAT(CURDATE(), ' 24:00:00')) )
    $WHERE
     GROUP BY tp.id
     ORDER BY $SORT $DESC;",
     undef,
     $attr
  );

  return [ ] if ($self->{errno});

  return $self->{list};
}

#**********************************************************
=head2 get_speed($attr) get tp speed

  Arguments:
    $attr
       DOMAIN_ID
       LOGIN
       UID

=cut
#**********************************************************
sub get_speed {
  my $self = shift;
  my ($attr) = @_;

  my $EXT_TABLE    = '';
  my @WHERE_RULES  = ();

  $self->{SEARCH_FIELDS}       = '';
  $self->{SEARCH_FIELDS_COUNT} = 0;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 'tp.tp_id, tt.id';
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  if ($attr->{LOGIN}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{LOGIN}, 'STR', 'u.id') };
    $EXT_TABLE .= "LEFT JOIN dv_main dv ON (dv.tp_id = tp.id )
    LEFT JOIN users u ON (dv.uid = u.uid )";

    $self->{SEARCH_FIELDS} = ', dv.speed, u.activate, dv.netmask, dv.join_service, dv.uid';
    $self->{SEARCH_FIELDS_COUNT} += 3;
  }
  elsif ($attr->{UID}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{UID}, 'STR', 'u.uid') };
    $EXT_TABLE .= "LEFT JOIN dv_main dv ON (dv.tp_id = tp.id )
    LEFT JOIN users u ON (dv.uid = u.uid )";

    $self->{SEARCH_FIELDS} = ', dv.speed, u.activate, dv.netmask, dv.join_service, dv.uid';
    $self->{SEARCH_FIELDS_COUNT} += 3;
  }

  if ($attr->{BURST}) {
    $self->{SEARCH_FIELDS} = ', tt.burst_limit_dl, tt.burst_limit_ul, tt.burst_threshold_dl, tt.burst_threshold_ul, tt.burst_time_dl, tt.burst_time_ul';
    $self->{SEARCH_FIELDS_COUNT} += 6;
  }

  if(defined($attr->{DOMAIN_ID}) && $attr->{DOMAIN_ID} =~ /^\d+$/) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{DOMAIN_ID}, 'STR', 'tp.domain_id') };
  }

  if ($attr->{TP_ID}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{TP_ID}, 'STR', 'tp.id') };
  }

  my $WHERE = ($#WHERE_RULES > -1) ? "AND " . join(' and ', @WHERE_RULES) : '';

  $self->query2("SELECT tp.tp_id, tp.id AS tp_num, tt.id AS tt_id, tt.in_speed,
    tt.out_speed, tt.net_id, tt.expression
  $self->{SEARCH_FIELDS}
FROM trafic_tarifs tt
LEFT JOIN intervals intv ON (tt.interval_id = intv.id)
LEFT JOIN tarif_plans tp ON (tp.tp_id = intv.tp_id AND tp.module='Dv')
$EXT_TABLE
WHERE intv.begin <= DATE_FORMAT( NOW(), '%H:%i:%S' )
 AND intv.end >= DATE_FORMAT( NOW(), '%H:%i:%S' )
 AND tp.module='Dv'
 $WHERE
AND intv.day IN (SELECT IF( intv.day=8,
    (SELECT IF((SELECT COUNT(*) FROM holidays WHERE DATE_FORMAT( NOW(), '%c-%e' ) = day)>0, 8,
                (SELECT IF(intv.day=0, 0, (SELECT intv.day FROM intervals as intv WHERE DATE_FORMAT(NOW(), '%w')+1 = intv.day LIMIT 1))))),
        (SELECT IF(intv.day=0, 0,
                (SELECT intv.day FROM intervals AS intv WHERE DATE_FORMAT( NOW(), '%w')+1 = intv.day LIMIT 1)))))
GROUP BY tp.tp_id, tt.id
ORDER BY $SORT $DESC;",
  undef,
  $attr
  );

  return $self->{list};
}

#**********************************************************
=head2 account_check()

=cut
#**********************************************************
sub account_check {
  my $self = shift;

  $self->query2("SELECT COUNT(uid) FROM dv_main;");

  if($self->{TOTAL}) {
    if($self->{list}->[0]->[0] > 0x4B1) {
      $self->{errno} = 0x2BC;
    }
  }

  return $self;
}

1

