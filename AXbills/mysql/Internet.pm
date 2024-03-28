package Internet;

=head1 NAME

  Internet module managment functions

=cut

use strict;
use parent qw( dbcore );
use Tariffs;
use Users;
use Conf;
use Fees;
use POSIX qw(strftime mktime);

our $VERSION = 1.00;
my $MODULE = 'Internet';

my ($admin, $CONF);

#**********************************************************
=head2 new($db, $admin, \%conf)

=cut
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
=head2 user_info($uid, $attr) User service information

  Arguments:
    $uid
    $attr
      UID
      ID
      LOGIN


=cut
#**********************************************************
sub user_info {
  my $self = shift;
  my ($uid, $attr) = @_;

  my $WHERE = '';

  if ($attr->{LOGIN}) {
    my Users $users = Users->new($self->{db}, $admin, $self->{conf});
    $users->info(0, { LOGIN => "$attr->{LOGIN}" });
    if ($users->{errno}) {
      $self->{errno}  = 2;
      $self->{errstr} = 'ERROR_NOT_EXIST';
      return $self;
    }

    $uid                      = $users->{UID};
    $self->{DEPOSIT}          = $users->{DEPOSIT};
    $self->{ACCOUNT_ACTIVATE} = $users->{ACTIVATE};
    $WHERE                    = "WHERE internet.uid='$uid'";
  }

  $WHERE = "WHERE internet.uid='$uid'";

  my $ORDER_BY = '';
  if($attr->{ID}) {
    $WHERE .= " AND internet.id='$attr->{ID}'";
  }
  else {
    $ORDER_BY = 'ORDER BY internet.id DESC';
  }

  if (defined($attr->{IP})) {
    $WHERE = "WHERE internet.ip=INET_ATON('$attr->{IP}')";
  }

  my $domain_id = 0;
  if ($admin->{DOMAIN_ID}) {
    $domain_id = $admin->{DOMAIN_ID};
  }
  elsif ($attr->{DOMAIN_ID}) {
    $domain_id = $attr->{DOMAIN_ID};
  }

  my $ipv6 = ($CONF->{IPV6}) ? "INET6_NTOA(internet.ipv6) AS ipv6, INET6_NTOA(internet.ipv6_prefix) AS ipv6_prefix," : q{};

  $self->query("SELECT internet.*,
    internet.login AS internet_login,
    internet.comments AS internet_comment,
    tp.name AS tp_name,
    tp.id AS tp_num,
    INET_NTOA(internet.ip) AS ip,
    $ipv6
    INET_NTOA(internet.netmask) AS netmask,
    internet.disable AS status,
    tp.gid AS tp_gid,
    tp.month_fee AS month_abon,
    tp.day_fee AS day_abon,
    tp.postpaid_monthly_fee AS postpaid_abon,
    tp.payment_type,
    internet.activate AS service_activate,
    internet.expire AS service_expire,
    tp.abon_distribution,
    tp.credit AS tp_credit,
    tp.priority AS tp_priority,
    tp.activate_price,
    tp.age AS tp_age,
    tp.activate_price AS tp_activate_price,
    tp.change_price AS tp_change_price,
    tp.filter_id AS tp_filter_id,
    tp.period_alignment AS tp_period_alignment,
    tp.fixed_fees_day,
    tp.comments,
    tp.describe_aid,
    tp.reduction_fee,
    tp.user_credit_limit,
    DECODE(internet.password, '$self->{conf}->{secretkey}') AS password
      FROM internet_main internet
      LEFT JOIN tarif_plans tp ON (tp.tp_id = internet.tp_id)
    $WHERE
    $ORDER_BY;",
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
=head2 user_add($attr) - Add service

  Arguments:
    CHECK_EXIST_TP

=cut
#**********************************************************
sub user_add {
  my $self = shift;
  my ($attr) = @_;

  $self->_space_trim($attr);

  $attr->{LOGIN}   = $attr->{INTERNET_LOGIN} if($attr->{INTERNET_LOGIN});
  $attr->{EXPIRE}  = $attr->{SERVICE_EXPIRE};
  $attr->{ACTIVATE}= $attr->{SERVICE_ACTIVATE} if(defined($attr->{SERVICE_ACTIVATE}));

  if (! $attr->{INTERNET_SKIP_FEE} && $attr->{TP_ID} > 0 && !$attr->{STATUS}) {
    my $Tariffs = Tariffs->new($self->{db}, $self->{conf}, $admin);

    if($self->{debug}) {
      $Tariffs->{debug}=1;
    }

    $self->{TP_INFO} = $Tariffs->info(0, {
      TP_ID     => $attr->{TP_ID},
      DOMAIN_ID => $admin->{DOMAIN_ID} || undef
    });

    if($attr->{CHECK_EXIST_TP} && $Tariffs->{errno}) {
      $self->{errno}=91;
      $self->{errstr}='TP_NOT_EXITS';
      return $self;
    }

    #Take activation price
    if ($Tariffs->{ACTIV_PRICE} && $Tariffs->{ACTIV_PRICE} > 0) {
      my $user = Users->new($self->{db}, $admin, $self->{conf});
      $user->info($attr->{UID});

      if ($self->{conf}->{FEES_PRIORITY} =~ /bonus/ && $user->{EXT_BILL_DEPOSIT}) {
        $user->{DEPOSIT} += $user->{EXT_BILL_DEPOSIT};
      }

      if (! $CONF->{INTERNET_MANDATORY_FEE} && $user->{DEPOSIT} + $user->{CREDIT} < $Tariffs->{ACTIV_PRICE} && $Tariffs->{PAYMENT_TYPE} == 0) {
        $self->{errno}  = 15;
        $self->{errstr} = "ERR_ACTIVE_PRICE_TOO_HIGHT";
        return $self;
      }

      my $fees = Fees->new($self->{db}, $admin, $self->{conf});
      $fees->take($user, $Tariffs->{ACTIV_PRICE}, { DESCRIBE => '$lang{ACTIVATE_TARIF_PLAN}' });
      $Tariffs->{ACTIV_PRICE} = 0;
    }
  }

  if(!$attr->{NETMASK}) {
    $attr->{NETMASK}='255.255.255.255';
  }

  $self->query_add('internet_main', {
    %$attr,
    REGISTRATION => 'NOW()',
    DISABLE      => $attr->{STATUS},
    PASSWORD     => ($attr->{PASSWORD}) ? "ENCODE('$attr->{PASSWORD}', '$self->{conf}->{secretkey}')" : ''
  });

  return [ ] if ($self->{errno});

  $attr->{ID}=$self->{INSERT_ID};
  $self->{ID}=$attr->{ID};

  $admin->{MODULE} = $MODULE;
  $admin->action_add($attr->{UID}, '', {
    TYPE    => 1,
    INFO    => ['TP_ID', 'INTERNET_LOGIN', 'STATUS', 'EXPIRE', 'IP', 'CID', 'PERSONAL_TP', 'ID'],
    REQUEST => $attr
  });

  return $self;
}

#**********************************************************
=head2 user_change($attr)

=cut
#**********************************************************
sub user_change {
  my $self = shift;
  my ($attr) = @_;

  $self->_space_trim($attr);

  $attr->{LOGIN} = $attr->{INTERNET_LOGIN} if(defined($attr->{INTERNET_LOGIN}));
  if (!$attr->{NAS_ID}) {
    $attr->{NAS_ID} = $attr->{NAS_ID1};
  }
  delete $attr->{ID} if(! $attr->{ID});

  $attr->{DISABLE} = $attr->{STATUS};
  $attr->{EXPIRE}  = $attr->{SERVICE_EXPIRE};
  $attr->{ACTIVATE}= $attr->{SERVICE_ACTIVATE} if(defined($attr->{SERVICE_ACTIVATE}));

  #BDCOM MAC format преобразуем в не BDCOM
  if (defined($attr->{CPE_MAC})) {
    $attr->{CPE_MAC} =~ s/[.]//g;
    $attr->{CPE_MAC} =~ s/(\b|\G)[\da-f]{2}(?=[\da-f]{2})/$&:/ig;
  }

  my $old_info = $self->user_info($attr->{UID}, { ID => $attr->{ID} });
  $self->{OLD_PERSONAL_TP} = $old_info->{PERSONAL_TP} || 0;
  $self->{OLD_STATUS}      = $old_info->{STATUS};

  if ($attr->{TP_ID} && $old_info->{TP_ID} != $attr->{TP_ID}) {
    my $user = Users->new($self->{db}, $admin, $self->{conf});
    $user->info($attr->{UID});

    my $Tariffs = Tariffs->new($self->{db}, $self->{conf}, $admin);
    $Tariffs->info(0, {
      TP_ID     => $old_info->{TP_ID},
      DOMAIN_ID => $user->{DOMAIN_ID} || $admin->{DOMAIN_ID}
    });
    $attr->{EXPIRE} = '0000-00-00' if defined($Tariffs->{AGE}) && $Tariffs->{AGE} > 0 && !$attr->{EXPIRE};

    %{ $self->{TP_INFO_OLD} } = %{ $Tariffs };
    $self->{TP_INFO} = $Tariffs->info(0, {
      TP_ID     => $attr->{TP_ID},
      DOMAIN_ID => $admin->{DOMAIN_ID}
    });

    if ($self->{conf}->{FEES_PRIORITY} && $self->{conf}->{FEES_PRIORITY} =~ /bonus/ && $user->{EXT_BILL_DEPOSIT}) {
      $user->{DEPOSIT} += $user->{EXT_BILL_DEPOSIT};
    }

    my $skip_change_fee = 0;
    if ($self->{conf}->{INTERNET_TP_CHG_FREE}) {
      my ($y, $m, $d) = split(/-/, $user->{REGISTRATION}, 3);
      my $cur_date = time();
      my $registration = POSIX::mktime(0, 0, 0, $d, ($m - 1), ($y - 1900));
      if (($cur_date - $registration) / 86400 > $self->{conf}->{INTERNET_TP_CHG_FREE}) {
        $skip_change_fee = 1;
      }
    }

    #Active TP
    if ($old_info->{STATUS} == 2 && (defined($attr->{STATUS}) && $attr->{STATUS} == 0) && $Tariffs->{ACTIV_PRICE} > 0) {
      if ($user->{DEPOSIT} + $user->{CREDIT} < $Tariffs->{ACTIV_PRICE} && $Tariffs->{PAYMENT_TYPE} == 0 && $Tariffs->{POSTPAID_FEE} == 0) {
        $self->{errno} = 15;
        $self->{errstr} = "Active price too hight";
        return $self;
      }

      my $Fees = Fees->new($self->{db}, $admin, $self->{conf});
      $Fees->take($user, $Tariffs->{ACTIV_PRICE}, { DESCRIBE => '$lang{ACTIVATE_TARIF_PLAN}' });

      $Tariffs->{ACTIV_PRICE} = 0;
    }
    # Change TP
    elsif (!$skip_change_fee
      && $Tariffs->{CHANGE_PRICE} > 0
      && (($self->{TP_INFO_OLD}->{PRIORITY} || 0) - $Tariffs->{PRIORITY} > 0
        || ($self->{TP_INFO_OLD}->{PRIORITY} || 0) + $Tariffs->{PRIORITY} == 0)
      && !$attr->{NO_CHANGE_FEES})
    {
      if ($user->{DEPOSIT} + $user->{CREDIT} < $Tariffs->{CHANGE_PRICE}) {
        $self->{errno} = 15;
        $self->{errstr} = "ERR_SMALL_DEPOSIT";
        return $self;
      }

      my $Fees = Fees->new($self->{db}, $admin, $self->{conf});

      $Fees->take($user, $Tariffs->{CHANGE_PRICE}, { DESCRIBE => 'CHANGE_TP' });
    }

    if ($Tariffs->{AGE} > 0) {
      $self->expire_date($attr, $Tariffs);
    }
#    else {
#      $attr->{EXPIRE} = "0000-00-00";
#    }
  }
  elsif (($old_info->{STATUS} && $old_info->{STATUS} == 3)
    && (defined($attr->{STATUS}) && $attr->{STATUS} == 0)
    && $attr->{STATUS_DAYS}) {
    my $user = Users->new($self->{db}, $admin, $self->{conf});
    $user->info($attr->{UID});
    my $fees = Fees->new($self->{db}, $admin, $self->{conf});
    #period : sum
    my (undef, $sum) = split(/:/, $self->{conf}->{INTERNET_REACTIVE_PERIOD}, 2);
    $fees->take($user, $sum, { DESCRIBE => "REACTIVE" });
  }
  elsif (($old_info->{STATUS}
         && ($old_info->{STATUS} == 1
           || $old_info->{STATUS} == 2
           || $old_info->{STATUS} == 3
           || $old_info->{STATUS} == 4
           || $old_info->{STATUS} == 5))
         && defined($attr->{STATUS}) && $attr->{STATUS} == 0) {
    my $Tariffs = Tariffs->new($self->{db}, $self->{conf}, $admin);
    $self->{TP_INFO} = $Tariffs->info(0, {
      TP_ID     => $old_info->{TP_ID},
      DOMAIN_ID => $admin->{DOMAIN_ID}
    });

    #Alignment for hold up
    if($old_info->{STATUS} == 3 && ! $self->{TP_INFO}->{PERIOD_ALIGNMENT} && ! $self->{TP_INFO}->{ABON_DISTRIBUTION}) {
      delete ($self->{TP_INFO});
    }
  }
  elsif($attr->{PERSONAL_TP} && $self->{OLD_PERSONAL_TP} != $attr->{PERSONAL_TP} ) {
    my $Tariffs = Tariffs->new($self->{db}, $self->{conf}, $admin);
    $self->{TP_INFO} = $Tariffs->info(0, {
      TP_ID     => $old_info->{TP_ID},
      DOMAIN_ID => $admin->{DOMAIN_ID}
    });
  }
  # # For HOLDUP_ALL
  # else {
  #   my $Tariffs = Tariffs->new($self->{db}, $self->{conf}, $admin);
  #   $self->{TP_INFO} = $Tariffs->info(0, {
  #     TP_ID     => $old_info->{TP_ID},
  #     DOMAIN_ID => $admin->{DOMAIN_ID}
  #   });
  # }

  #$attr->{JOIN_SERVICE} = ($attr->{JOIN_SERVICE}) ? $attr->{JOIN_SERVICE} : 0;

  $admin->{MODULE} = $MODULE;
  $self->changes(
    {
      CHANGE_PARAM => 'UID'. (($attr->{ID}) ? ',ID' : q{}),
      TABLE        => 'internet_main',
      DATA         => $attr
    }
  );

  $self->{TP_INFO}->{ACTIV_PRICE} = 0 if (! $self->{OLD_STATUS} || $self->{OLD_STATUS} != 2);

  if($self->{AFFECTED}) {
    $self->user_info($attr->{UID}, { ID => $attr->{ID} || undef });
  }

  return $self;
}

#**********************************************************
=head2 expire_date(attr); - Get expire date

  Arguments:
    $attr,
    $Tariffs

  Result:
    $self

=cut
#**********************************************************
sub expire_date {
  my $self = shift;
  my ($attr, $Tariffs) = @_;

  $attr->{EXPIRE} = POSIX::strftime("%Y-%m-%d", localtime(time + 86400 * $Tariffs->{AGE}));

  eval { require Date::Calc };
  if (!$@) {
    Date::Calc->import( qw/Add_Delta_Days/ );

    my (undef, undef, undef,$mday,$mon,$year,undef,undef,undef) = localtime(time);
    $year += 1900;
    $mon++;
    ($year,$mon,$mday) = Date::Calc::Add_Delta_Days($year, $mon, $mday, $Tariffs->{AGE});
    $attr->{EXPIRE} ="$year-$mon-$mday";
  }

  return $self;
}

#**********************************************************
=head2 user_del(attr); Delete user service

  Arguments:
    $attr

  Result:
    $self

=cut
#**********************************************************
sub user_del {
  my $self = shift;
  my ($attr) = @_;

  my $uid = $self->{UID} || $attr->{UID};
  $self->query_del('internet_main', $attr, { uid => $uid });
  $self->query_del('internet_log', undef, { uid => $uid });

  $admin->{MODULE}=$MODULE;
  my @del_descr = ();
  if($attr->{UID}) {
    push @del_descr, "UID: $attr->{UID}";
  }

  if ($attr->{ID}) {
    push @del_descr, "ID: $attr->{ID}";
  }

  if($attr->{COMMENTS}) {
    push @del_descr, "COMMENTS: $attr->{COMMENTS}";
  }

  $admin->action_add($uid, join(' ', @del_descr), { TYPE => 10 });

  return $self->{result};
}

#**********************************************************
=head2 user_list($attr) - Internet users list

  Arguments:
    GROUP_BY
    UNIVERSAL_SEARCH

=cut
#**********************************************************
sub user_list {
  my $self   = shift;
  my ($attr) = @_;

  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  my $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $GROUP_BY = 'u.uid';
  delete $self->{errno};
  if ($attr->{UNIVERSAL_SEARCH}) { # || $self->{GLOBAL}) {
    $attr->{_MULTI_HIT}     = 1;
    $attr->{SKIP_GID}       = 1 if ($attr->{GID});
    $attr->{SKIP_DEL_CHECK} = 1;

    # if ($attr->{GID} || $attr->{GLOBAL}) {
    #   $attr->{SKIP_GID}       = 1;
    #   $attr->{SKIP_DEL_CHECK} = 1;
    # }
    #
    # if ($self->{GLOBAL}) {
    #   $attr->{GLOBAL} = $self->{GLOBAL};
    #   delete $self->{GLOBAL};
    # }
  }

  if ($attr->{GROUP_BY}) {
    $GROUP_BY = $attr->{GROUP_BY};
    delete $attr->{GROUP_BY};
  }

  if ($attr->{CID} && $attr->{CID} !~ /\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/) {
    $attr->{CID}=~s/[\:\-\.]/\*/g;
  }

  if ($attr->{UNIVERSAL_SEARCH}) {
    $attr->{SKIP_DEL_CHECK}=1;
  }

  $self->{EXT_TABLES}     = '';
  $self->{SEARCH_FIELDS}  = '';
  $self->{SEARCH_FIELDS_COUNT}=0;

  if($attr->{REGISTRATION_FROM_REGISTRATION_TO}){
    ($attr->{REGISTRATION_FROM}, $attr->{REGISTRATION_TO}) = split '/', $attr->{REGISTRATION_FROM_REGISTRATION_TO};
  }

  my @search_fields = (
    ['INTERNET_LOGIN',    'STR', 'internet.login',  'internet.login AS internet_login' ],
    ['IP',                'IP',  'internet.ip',     'internet.ip AS ip_num'        ], #'INET_NTOA(internet.ip) AS ip' ],
    ['IP_NUM',            'IP',  'internet.ip',     'internet.ip AS ip_num'        ],
    ['NETMASK',           'IP',  'internet.netmask', 'INET_NTOA(internet.netmask) AS netmask' ],
    ['CID',               'STR', 'internet.cid',                           1 ],
    ['CPE_MAC',           'STR', 'internet.cpe_mac',                       1 ],
    ['INTERNET_COMMENTS', 'STR', 'internet.comments', 'internet.comments AS internet_comments' ],
    ['INTERNET_REGISTRATION', 'DATE', 'internet.registration AS internet_registration',      1 ],
    ['VLAN',              'INT', 'internet.vlan',                          1 ],
    ['SERVER_VLAN',       'INT', 'internet.server_vlan',                   1 ],
    ['JOIN_SERVICE',      'INT', 'internet.join_service',                  1 ],
    ['SIMULTANEONSLY',    'INT', 'internet.logins',                        1 ],
    ['SPEED',             'INT', 'internet.speed',                         1 ],
    ['NAS_ID',            'INT', 'internet.nas_id',                        1 ],
    ['PORT',              'STR', 'internet.port',                          1 ],
    ['ALL_FILTER_ID',     'STR', 'IF(internet.filter_id<>\'\', internet.filter_id, tp.filter_id) AS filter_id', 1 ],
    ['FILTER_ID',         'STR', 'internet.filter_id',                     1 ],
    ['TP_ID',             'INT', 'internet.tp_id',                         1 ],
    ['TP_NUM',            'INT', 'tp.id', 'tp.id AS tp_num',               1 ],
    ['TP_NAME',           'STR', 'tp.name AS tp_name',                     1 ],
    ['TP_COMMENTS',       'STR', 'tp.comments', 'tp.comments AS tp_comments' ],
    ['TP_CREDIT',         'INT', 'tp.credit',       'tp.credit AS tp_credit' ],
    ['TP_FIXED_FEES_DAY', 'INT', 'tp.fixed_fees_day', 'tp.fixed_fees_day AS tp_fixed_fees_day' ],
    ['TP_REDUCTION_FEE',  'INT', 'tp.reduction_fee', 'tp.reduction_fee AS tp_reduction_fee' ],
    ['ONLINE',            'INT', 'c.uid',                  'c.uid AS online' ],
    ['ONLINE_IP',         'INT', 'INET_NTOA(c.framed_ip_address)', 'INET_NTOA(c.framed_ip_address) AS online_ip' ],
    ['ONLINE_DURATION',   'INT', 'c.uid',  'IF(c.lupdated>UNIX_TIMESTAMP(c.started), c.lupdated - UNIX_TIMESTAMP(c.started), 0) AS online_duration' ],
    ['ONLINE_CID',        'INT', 'c.cid',              'c.cid AS online_cid' ],
    ['ONLINE_TP_ID',      'INT', 'c.tp_id',        'c.tp_id AS online_tp_id' ],
    ['ONLINE_NAS_ID',     'INT', 'c.nas_id',     'c.nas_id AS online_nas_id' ],
    ['MONTH_FEE',         'INT', 'tp.month_fee',                           1 ],
    ['ABON_DISTRIBUTION', 'INT', 'tp.abon_distribution',                   1 ],
    ['DAY_FEE',           'INT', 'tp.day_fee',                             1 ],
    ['AGE',               'INT', 'tp.age as tp_age',                       1 ],
    ['ACTIV_PRICE',       'INT', 'tp.activate_price',                      1 ],
    ['PERSONAL_TP',       'INT', 'internet.personal_tp',                   1 ],
    ['PAYMENT_TYPE',      'INT', 'tp.payment_type',                        1 ],
    ['INTERNET_PASSWORD', '', '',  "DECODE(internet.password, '$CONF->{secretkey}') AS internet_password" ],
    ['INTERNET_STATUS',   'INT', 'internet.disable', 'internet.disable AS internet_status'   ],
    ['INTERNET_STATUS_ID','INT', 'internet.disable', 'internet.disable AS internet_status_id'],
    ['SERVICE_EXPIRE',    'DATE', 'internet.expire', 'internet.expire AS internet_expire'    ],
    ['INTERNET_EXPIRE',   'DATE', 'internet.expire', 'internet.expire AS internet_expire'    ],
    ['INTERNET_ACTIVATE', 'DATE', 'internet.activate', 'internet.activate AS internet_activate' ],
    ['INTERNET_STATUS_DATE', '',    '',
      '(SELECT aa.datetime FROM admin_actions aa WHERE aa.uid=internet.uid AND aa.module=\'Internet\'
        AND aa.action_type IN (4, 8, 14)
        ORDER BY aa.datetime DESC LIMIT 1) AS internet_status_date'            ],
    ['MONTH_TRAFFIC_IN',  'INT', '', "SUM(l.recv) AS month_traffic_in"       ],
    ['MONTH_TRAFFIC_OUT', 'INT', '', "SUM(l.sent) AS month_traffic_out"      ],
    ['LAST_ACTIVITY',     'DATE', 'l.start + INTERVAL duration SECOND', "MAX(l.start + INTERVAL duration SECOND) AS last_activity"  ],
    ['LAST_UPDATED',      'DATE', 'FROM_UNIXTIME(l.lupdated)', 'FROM_UNIXTIME(l.lupdated) AS last_updated'],
    ['MONTH_IPN_TRAFFIC_IN',  'INT', '', "SUM(ipn_l.traffic_in) AS month_ipn_traffic_in"   ],
    ['MONTH_IPN_TRAFFIC_OUT', 'INT', '', "SUM(ipn_l.traffic_out) AS month_ipn_traffic_out" ],
    ['UID',               'INT', 'internet.uid',                           1 ],
    ['ID',                'INT', 'internet.id',                            1 ],
    ['LOGIN_STATUS',      'INT', 'u.disable',    'u.disable AS login_status' ],
    ['IPN_ACTIVATE',      'INT', 'internet.ipn_activate',                  1 ],
    ['DAY_TRAF_LIMIT',    'INT', 'tp.day_traf_limit',                      1 ],
    ['WEEK_TRAF_LIMIT',   'INT', 'tp.week_traf_limit',                     1 ],
    ['MONTH_TRAF_LIMIT',  'INT', 'tp.month_traf_limit',                    1 ],
    ['TOTAL_TRAF_LIMIT',  'INT', 'tp.total_traf_limit',                    1 ],
    ['DESCRIBE_AID',      'STR', 'tp.describe_aid',                        1 ],
    ['SERVICE_COUNT',     'INT', '', 'COUNT(internet.id) AS service_count '  ] ,
    ['SHEDULE',           'INT', '', "CONCAT(s.y,'-', s.m, '-', s.d, ' ', s.action) AS shedule" ],
    ['FEES_METHOD',       'INT', 'tp.fees_method',                         1 ],
    ['NAS_IP',            'IP',  'INET_NTOA(nas.ip) AS nas_ip',            1 ],
    ['REGISTRATION_FROM|REGISTRATION_TO','DATE',"DATE_FORMAT(u.registration, '%Y-%m-%d')"]
  );

  if ($CONF->{IPV6}) {
    push @search_fields,
      ['IPV6',        'IPV6', 'INET6_NTOA(internet.ipv6)', 'INET6_NTOA(internet.ipv6) AS ipv6'],
      ['IPV6_PREFIX', 'IPV6', 'INET6_NTOA(internet.ipv6_prefix)', 'INET6_NTOA(internet.ipv6_prefix) AS ipv6_prefix'];
  }

  my $WHERE =  $self->search_former($attr, \@search_fields,
    { WHERE            => 1,
      USERS_FIELDS_PRE => 1,
      USE_USER_PI      => 1,
      SKIP_USERS_FIELDS=> [ 'UID', 'ACTIVE', 'EXPIRE' ]
    }
  );

  if ($attr->{UNIVERSAL_SEARCH} && $attr->{GID} && $attr->{GID} ne '_SHOW') {
    if ($attr->{GID} =~ /,/) {
      $WHERE .= ' AND u.gid IN (' . $attr->{GID} . ')';
    }
    else {
      $WHERE .= ' AND u.gid = ' . $attr->{GID};
    }
  }

  my $EXT_TABLE = $self->{EXT_TABLES} || '';
  if($self->{SEARCH_FIELDS} =~ /online/) {
    $EXT_TABLE .= "
      LEFT JOIN internet_online c ON (c.uid=internet.uid
        AND (c.service_id=internet.id OR c.service_id=0)) ";
  }

  if ( ! $admin->{permissions}->{0}->{8} ) {
    $WHERE .= " AND u.deleted=0";
  }

  if($attr->{SHEDULE}) {
    $EXT_TABLE .= "LEFT JOIN shedule s ON (s.uid=internet.uid AND s.module='Internet') ";
  }

  if($attr->{NAS_IP}) {
    $EXT_TABLE .= "LEFT JOIN nas ON (nas.id=internet.nas_id)";
  }

  if ($attr->{USERS_WARNINGS}) {
    my $allert_period = '';
    if ($attr->{ALERT_PERIOD}) {
      $allert_period = "OR  (tp.month_fee > 0  AND IF(u.activate='0000-00-00',
      DATEDIFF(DATE_FORMAT(CURDATE() + INTERVAL 1 MONTH, '%Y-%m-01'), CURDATE()),
      DATEDIFF(u.activate + INTERVAL 30 DAY, CURDATE())) IN ($attr->{ALERT_PERIOD}))";
    }

    $self->query("SELECT u.id AS login,
        pi.email,
        internet.tp_id AS tp_num,
        u.credit,
        b.deposit,
        tp.name AS tp_name,
        tp.uplimit,
        pi.phone,
        pi.fio,
        IF(u.activate='0000-00-00',
          DATEDIFF(DATE_FORMAT(CURDATE() + INTERVAL 1 MONTH, '%Y-%m-01'), CURDATE()),
          DATEDIFF(u.activate + INTERVAL 30 DAY, CURDATE())) AS to_next_period,
        $self->{SEARCH_FIELDS}
        u.uid
      FROM users u
      INNER JOIN internet_main internet ON (u.uid=internet.uid)
      INNER JOIN tarif_plans tp ON (internet.tp_id = tp.tp_id)
      $EXT_TABLE
      " . (($WHERE) ? $WHERE . ' AND' : q{}) ."
        u.disable  = 0
        AND internet.disable = 0
        AND b.deposit+u.credit>0
        AND (((tp.month_fee=0 OR tp.abon_distribution=1) AND tp.uplimit > 0 AND b.deposit<tp.uplimit)
            $allert_period
            )

      GROUP BY u.id
      ORDER BY u.id;",
      undef,
      $attr
    );

    return [] if ($self->{errno});

    my $list = $self->{list};
    return $list;
  }
  elsif ($attr->{CLOSED}) {
    $self->query("SELECT u.id, pi.fio,
        IF(company.id IS NULL, b.deposit, b.deposit),
        IF(u.company_id=0, u.credit,
          IF(u.credit=0, company.credit, u.credit)) AS credit,
        tp.name,
        u.disable,
        u.uid,
        u.company_id,
        u.email,
        u.tp_id,
        IF(l.start is NULL, '-', l.start)
      FROM ( users u, bills b )
      LEFT JOIN users_pi pi ON (u.uid=pi.uid)
      LEFT JOIN tarif_plans tp ON  (tp.tp_id=internet.tp_id)
      LEFT JOIN companies company ON  (u.company_id=company.id)
      LEFT JOIN internet_log l ON  (l.uid=u.uid)
      WHERE
        u.bill_id=b.id
        AND (b.deposit+u.credit-tp.credit_tresshold<=0)
          OR (
          (u.expire<>'0000-00-00' and u.expire < CURDATE())
          AND (u.activate<>'0000-00-00' and u.activate > CURDATE())
          )
        OR u.disable=1
      GROUP BY u.id
      ORDER BY $SORT $DESC;"
    );

    my $list = $self->{list};
    return $list;
  }

  if ($attr->{MONTH_TRAFFIC_IN} || $attr->{MONTH_TRAFFIC_OUT} || $attr->{LAST_ACTIVITY}) {
    $EXT_TABLE .= "
      LEFT JOIN internet_log l ON (l.uid=internet.uid AND DATE_FORMAT(l.start, '%Y-%m')=DATE_FORMAT(CURDATE(), '%Y-%m')) ";
  }

  if ($attr->{MONTH_IPN_TRAFFIC_IN} || $attr->{MONTH_IPN_TRAFFIC_OUT}) {
    $EXT_TABLE .= "
      LEFT JOIN ipn_log ipn_l ON (ipn_l.uid=internet.uid AND DATE_FORMAT(ipn_l.start, '%Y-%m')=DATE_FORMAT(CURDATE(), '%Y-%m')) ";
  }

  $self->query("SELECT
      $self->{SEARCH_FIELDS}
      u.uid,
      u.disable AS login_status,
      internet.tp_id,
      internet.id
    FROM users u
    INNER JOIN internet_main internet ON (u.uid=internet.uid)
    LEFT JOIN tarif_plans tp ON (tp.tp_id=internet.tp_id)
    $EXT_TABLE
    $WHERE
    GROUP BY $GROUP_BY
    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  return [] if ($self->{errno});
  my $list = $self->{list} || [];

  if ($self->{TOTAL} >= 0 && !$attr->{SKIP_TOTAL}) {
    $self->query("SELECT COUNT( DISTINCT u.id) AS total, COUNT(u.id) AS total_services FROM users u
    INNER JOIN internet_main internet ON (u.uid=internet.uid)
    LEFT JOIN tarif_plans tp ON (tp.tp_id=internet.tp_id)
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

  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  my $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $WHERE =  $self->search_former($attr, [
      ['UID',             'INT', 'internet.uid',                           1 ],
      ['INTERNET_STATUS', 'INT', 'internet.disable AS internet_status',    1 ],
      ['TP_NAME',         'STR', 'tp.name', 'tp.name AS tp_name' ]
    ],
    {
      USERS_FIELDS_PRE => 1,
      USE_USER_PI      => 1,
      SKIP_USERS_FIELDS=> [ 'UID' ]
    });

  my $EXT_TABLES = $self->{EXT_TABLES};
  $WHERE = " AND ". $WHERE if ($WHERE);

  if (! $attr->{PERIOD}) {
    $attr->{PERIOD} = 1;
  }

  $self->query("SELECT
      $self->{SEARCH_FIELDS}
      u.uid
    FROM users u
    INNER JOIN internet_main internet ON (u.uid=internet.uid)
    LEFT JOIN tarif_plans tp ON (tp.tp_id=internet.tp_id)
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
    $self->query("SELECT COUNT(*) AS total, SUM(IF(u.company_id > 0, cb.deposit, b.deposit)) AS total_debetors_sum
      FROM users u
    INNER JOIN internet_main internet ON (u.uid=internet.uid)
    LEFT JOIN tarif_plans tp ON (tp.tp_id=internet.tp_id)
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

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  $self->{EXT_TABLES}          = '';
  $self->{SEARCH_FIELDS}       = '';
  $self->{SEARCH_FIELDS_COUNT} = 0;
  $attr->{DELETED}             = 0;

  my $WHERE =  $self->search_former($attr, [
      ['DOMAIN_ID',            'INT', 'tp.domain_id',  ],
    ],
    { WHERE       => 1,
      USERS_FIELDS=> 1
    }
  );

  $self->query("SELECT tp.id, tp.name, COUNT(DISTINCT internet.uid) AS counts,
      COUNT(DISTINCT CASE WHEN internet.disable=0 AND u.disable=0 THEN internet.uid ELSE NULL END) AS active,
      COUNT(DISTINCT CASE WHEN internet.disable=1 AND u.disable=1 THEN internet.uid ELSE NULL END) AS disabled,
      SUM(IF(IF(u.company_id > 0, cb.deposit, b.deposit) < 0, 1, 0)) AS debetors,
      ROUND(SUM(p.sum) / COUNT(DISTINCT internet.uid), 2) AS arpu,
      ROUND(SUM(p.sum) / COUNT(DISTINCT p.uid), 2) AS arppu,
      tp.tp_id
    FROM users u
    INNER JOIN internet_main internet ON (u.uid=internet.uid)
    LEFT JOIN tarif_plans tp ON (tp.tp_id=internet.tp_id)
    LEFT JOIN bills b ON (u.bill_id = b.id)
    LEFT JOIN companies company ON  (u.company_id=company.id)
    LEFT JOIN bills cb ON  (company.bill_id=cb.id)
    LEFT JOIN payments p ON (p.uid=internet.uid
      AND (p.date >= DATE_FORMAT(CURDATE(), '%Y-%m-01 00:00:00') AND p.date <= CONCAT(CURDATE(), ' 24:00:00')) )
    $WHERE
    GROUP BY tp.tp_id
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
      UID
      TP_ID
      TP_NUM
      LOGIN

  Result:
    $list

=cut
#**********************************************************
sub get_speed {
  my $self = shift;
  my ($attr) = @_;

  my $EXT_TABLE    = '';
  my @WHERE_RULES  = ();

  $self->{SEARCH_FIELDS}       = '';
  $self->{SEARCH_FIELDS_COUNT} = 0;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 'tp.tp_id, tt.id';
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  if ($attr->{SERVICE_ID}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{SERVICE_ID}, 'INT', 'internet.id') };

    $EXT_TABLE .= "LEFT JOIN internet_main internet ON (internet.tp_id = tp.tp_id)
    LEFT JOIN users u ON (internet.uid = u.uid)";

    $self->{SEARCH_FIELDS} = ', internet.speed, u.activate, internet.netmask, internet.join_service, internet.uid';
    $self->{SEARCH_FIELDS_COUNT} += 3;
  }
  elsif ($attr->{LOGIN}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{LOGIN}, 'STR', 'u.id') };
    $EXT_TABLE .= "LEFT JOIN internet_main internet ON (internet.tp_id = tp.tp_id )
    LEFT JOIN users u ON (internet.uid = u.uid )";

    $self->{SEARCH_FIELDS} = ', internet.speed, u.activate, internet.netmask, internet.join_service, internet.uid';
    $self->{SEARCH_FIELDS_COUNT} += 3;
  }
  elsif ($attr->{UID}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{UID}, 'STR', 'u.uid') };
    $EXT_TABLE .= "LEFT JOIN internet_main internet ON (internet.tp_id = tp.tp_id )
    LEFT JOIN users u ON (internet.uid = u.uid )";

    $self->{SEARCH_FIELDS} = ', internet.speed, u.activate, internet.netmask, internet.join_service, internet.uid';
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
    push @WHERE_RULES, @{ $self->search_expr($attr->{TP_ID}, 'STR', 'tp.tp_id') };
  }

  if ($attr->{TP_NUM}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{TP_NUM}, 'STR', 'tp.id') };
  }

  my $WHERE = ($#WHERE_RULES > -1) ? "AND " . join(' and ', @WHERE_RULES) : '';

  $self->query("SELECT tp.tp_id,
      tp.id AS tp_num,
      tt.id AS tt_id,
      tt.in_speed,
      tt.out_speed,
      tt.net_id,
      tt.expression,
      intv.id AS interval_id
      $self->{SEARCH_FIELDS}
    FROM trafic_tarifs tt
    LEFT JOIN intervals intv ON (tt.interval_id = intv.id)
    LEFT JOIN tarif_plans tp ON (tp.tp_id = intv.tp_id)
    $EXT_TABLE
    WHERE intv.begin <= DATE_FORMAT( NOW(), '%H:%i:%S' )
      AND intv.end >= DATE_FORMAT( NOW(), '%H:%i:%S' )
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

  return $self->{list} || [];
}

#**********************************************************
=head2 iplus_check()

=cut
#**********************************************************
sub iplus_check {
  my $self = shift;

  $self->query('SELECT COUNT(id) FROM internet_main;');

  if($self->{TOTAL}) {
    if($self->{list}->[0]->[0] > 0x4C1) {
      $self->{errno} = 0x2BC;
    }
  }

  return $self;
}

#**********************************************************
=head2 filters_add()

=cut
#**********************************************************
sub filters_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('internet_filters', $attr);

  return $self;
}

#**********************************************************
=head2 filters_del()

=cut
#**********************************************************git 
sub filters_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('internet_filters', undef, $attr);

  return $self->{result};
}

#**********************************************************
=head2 filters_list($attr)

=cut
#**********************************************************
sub filters_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  my $WHERE = $self->search_former( $attr, [
      [ 'ID',     'INT', 'id',      1 ],
      [ 'FILTER', 'STR', 'filter',  1 ],
      [ 'DESCR',  'STR', 'descr',   1 ],
      [ 'PARAMS', 'STR', 'params',  1 ],
      [ 'USER_PORTAL', 'INT', 'user_portal', 1 ]
    ],
    {
      WHERE => 1,
    }
  );

  $self->query(
    "SELECT $self->{SEARCH_FIELDS} id
     FROM internet_filters
     $WHERE ORDER BY $SORT $DESC;",
    undef,
    { COLS_NAME => 1}
  );

  return $self->{list};
}

#**********************************************************
=head2 filters_info($attr)

=cut
#**********************************************************
sub filters_info{
  my $self = shift;
  my ($id) = @_;

  $self->query( 'SELECT * FROM internet_filters WHERE id = ? ;',
    undef,
    { INFO => 1,
      Bind => [ $id ] }
  );

  return $self;
}

#**********************************************************
=head2 filters_change($attr)

=cut
#**********************************************************
sub filters_change{
  my $self = shift;
  my ($attr) = @_;

  $attr->{USER_PORTAL} = ($attr->{USER_PORTAL}) ? 1 : 0;

  $self->changes(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'internet_filters',
      DATA         => $attr
    }
  );

  return $self->{result};
}

#**********************************************************
=head2 report_user_statuses($attr) - Get sum deposits, users count for statuses

  Arguments:
     -

  Returns:
  $self->{list}->[0]
=cut
#**********************************************************
sub report_user_statuses {
  my $self = shift;
  my ($attr) = @_;

  $self->query("SELECT COUNT(i.uid) AS COUNT,SUM(i.deposit) AS deposit,i.disable AS status
    FROM (SELECT DISTINCT inter.uid, IF(u.company_id = 0, b.deposit, cb.deposit) AS deposit, inter.disable
      FROM internet_main AS inter
      INNER JOIN users u ON (u.uid=inter.uid)
      LEFT JOIN companies company ON (u.company_id=company.id)
      LEFT JOIN bills b ON (u.bill_id = b.id)
      LEFT JOIN bills cb ON (company.bill_id=cb.id)
    ) AS i
    WHERE i.disable='$attr->{STATUS}'
    GROUP BY status;",
    undef,
    $attr
  );
  return $self->{list}->[0];

}
#**********************************************************
=head2 add_user_ippool($attr) - Add ip pool to user

  Arguments:
    $attr - info for adding

  Returns:
    $self
=cut
#**********************************************************
sub add_user_ippool {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('internet_users_pool', $attr);
  return $self;
}
#**********************************************************
=head2 info_user_ippool($attr) - Get info about users ip pool

  Arguments:
    $attr - info for condition

  Returns:
    $self->{list}[0] || ()
=cut
#**********************************************************
sub info_user_ippool {
  my $self = shift;
  my ($attr) = @_;

  $self->query("SELECT service_id,pool_id,comments
    FROM internet_users_pool
    WHERE service_id= ? ;",
    undef,
    { Bind => [ $attr->{SERVICE_ID}],
      COLS_NAME => 1
    });
  return $self->{list}[0] || ();
}
#**********************************************************
=head2 del_user_ippool($attr) - Delete users ip pool

  Arguments:
    $attr - delete condition

  Returns:
    $self
=cut
#**********************************************************
sub del_user_ippool {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('internet_users_pool', {}, $attr);
  return $self;
}

#*******************************************************************
=head2 get_free_static_ip()

  Arguments:
    FIRST
    LAST
    COUNT

=cut
#*******************************************************************
sub get_free_static_ip {
  my $self = shift;
  my ($attr) = @_;

  $self->query("SELECT
      (? + TWO_1.SeqValue + TWO_2.SeqValue + TWO_4.SeqValue + TWO_8.SeqValue + TWO_16.SeqValue + TWO_32.SeqValue + TWO_64.SeqValue + TWO_128.SeqValue + TWO_256.SeqValue + TWO_512.SeqValue + TWO_1024.SeqValue + TWO_2048.SeqValue + TWO_4096.SeqValue + TWO_8192.SeqValue + TWO_16384.SeqValue + TWO_32768.SeqValue+ TWO_65536.SeqValue) as SeqValue
    FROM
      (SELECT 0 SeqValue UNION ALL SELECT 1 SeqValue) TWO_1
      CROSS JOIN (SELECT 0 SeqValue UNION ALL SELECT 2 SeqValue) TWO_2
      CROSS JOIN (SELECT 0 SeqValue UNION ALL SELECT 4 SeqValue) TWO_4
      CROSS JOIN (SELECT 0 SeqValue UNION ALL SELECT 8 SeqValue) TWO_8
      CROSS JOIN (SELECT 0 SeqValue UNION ALL SELECT 16 SeqValue) TWO_16
      CROSS JOIN (SELECT 0 SeqValue UNION ALL SELECT 32 SeqValue) TWO_32
      CROSS JOIN (SELECT 0 SeqValue UNION ALL SELECT 64 SeqValue) TWO_64
      CROSS JOIN (SELECT 0 SeqValue UNION ALL SELECT 128 SeqValue) TWO_128
      CROSS JOIN (SELECT 0 SeqValue UNION ALL SELECT 256 SeqValue) TWO_256
      CROSS JOIN (SELECT 0 SeqValue UNION ALL SELECT 512 SeqValue) TWO_512
      CROSS JOIN (SELECT 0 SeqValue UNION ALL SELECT 1024 SeqValue) TWO_1024
      CROSS JOIN (SELECT 0 SeqValue UNION ALL SELECT 2048 SeqValue) TWO_2048
      CROSS JOIN (SELECT 0 SeqValue UNION ALL SELECT 4096 SeqValue) TWO_4096
      CROSS JOIN (SELECT 0 SeqValue UNION ALL SELECT 8192 SeqValue) TWO_8192
      CROSS JOIN (SELECT 0 SeqValue UNION ALL SELECT 16384 SeqValue) TWO_16384
      CROSS JOIN (SELECT 0 SeqValue UNION ALL SELECT 32768 SeqValue) TWO_32768
      CROSS JOIN (SELECT 0 SeqValue UNION ALL SELECT 65536 SeqValue) TWO_65536
    HAVING SeqValue NOT IN (SELECT ip from internet_main)
    AND SeqValue < ?
    ORDER BY 1 LIMIT ?;",
    undef, 
    { Bind => [$attr->{FIRST}, $attr->{LAST}, $attr->{COUNT}]}
  );

  return $self->{list} || [ ];
}

#**********************************************************
=head2 users_outflow_report ()

  Arguments:
    ATTRIBUTES -
  Returns:

  Examples:

=cut
#**********************************************************
sub users_outflow_report {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 'i.uid';
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 999999;
  my $GROUP_BY = $attr->{GROUP_BY} || 'i.uid';

  my $EXT_TABLE = '';
  my @WHERE_RULES = ();

  push @WHERE_RULES, "(t.month_fee <> 0 OR t.day_fee <> 0)";
  push @WHERE_RULES, "f.dsc LIKE 'Internet%'";
  push @WHERE_RULES, "b.deposit < 1";

  if ($attr->{BUILD_ID}) {
    push @WHERE_RULES, "pi.location_id = $attr->{BUILD_ID}";
  }
  elsif ($attr->{STREET_ID}) {
    push @WHERE_RULES, "builds.street_id = $attr->{STREET_ID}";
    $EXT_TABLE = 'LEFT JOIN builds ON (builds.id=pi.location_id)';
  }
  elsif ($attr->{DISTRICT_ID}) {
    push @WHERE_RULES, "streets.district_id = $attr->{DISTRICT_ID}";
    $EXT_TABLE = 'LEFT JOIN builds ON (builds.id=pi.location_id)';
    $EXT_TABLE .= 'LEFT JOIN streets ON (streets.id=builds.street_id)';
  }

  $attr->{TO_DATE} = $attr->{TO_DATE} ? "'$attr->{TO_DATE}'" : 'CURDATE()';
  push @WHERE_RULES, "f.date <= $attr->{TO_DATE}";

  my $WHERE = $self->search_former(
    $attr,
    [
      [ 'LOGIN',    'STR', 'u.id AS login',            1 ],
      [ 'TP_NAME',  'STR', 't.name AS tp_name',        1 ],
      [ 'TP_ID',    'INT', 'i.tp_id AS tp_id',         1 ],
      # [ 'LAST_FEE', 'DATE', 'MAX(f.date) AS last_fee', 1 ],
      [ 'DEPOSIT',  'INT', 'b.deposit AS deposit',     1 ],
    ],
    { WHERE => 1, WHERE_RULES => \@WHERE_RULES }
  );

  $self->query(
    "SELECT $self->{SEARCH_FIELDS} i.uid, MAX(f.date) AS last_fee
      FROM internet_main i
      INNER JOIN tarif_plans t ON (t.tp_id=i.tp_id)
      LEFT JOIN users u ON (u.uid = i.uid)
      LEFT JOIN users_pi pi ON (pi.uid = u.uid)
      LEFT JOIN bills b ON (b.id = u.bill_id)
      LEFT JOIN fees f ON (f.uid=i.uid)
      $EXT_TABLE
    $WHERE
    GROUP BY $GROUP_BY
    HAVING COUNT(f.date)<>0 AND DATEDIFF($attr->{TO_DATE},  last_fee) > 30
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  delete $attr->{GROUP_BY};

  return $self->{list} || [];
}

#**********************************************************
=head2 users_outflow_report ()

  Arguments:
    ATTRIBUTES -
  Returns:

  Examples:

=cut
#**********************************************************
sub users_outflow_by_address {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : '1';
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 999999;
  my $GROUP_BY = $attr->{GROUP_BY} || 'GROUP BY b.id';

  my $WHERE = $self->search_former(
    $attr,
    [
      [ 'UID',          'INT', 'u.uid',                                1 ],
      [ 'LOCATION_ID',  'INT', 'pi.location_id',                       1 ],
      [ 'BUILD_ID',     'INT', 'b.id', 'b.id AS build_id',             1 ],
      [ 'STREET_ID',    'INT', 's.id', 's.id AS street_id',            1 ],
      [ 'BUILD_NUMBER', 'STR', 'b.number', 'b.number AS build_number', 1 ],
      [ 'STREET_NAME',  'STR', 's.name', 's.name AS street_name',      1 ],
      [ 'USERS_COUNT',  'INT', 'COUNT(DISTINCT u.uid) AS users_count', 1 ]
    ],
    { WHERE => 1 }
  );

  $self->query(
    "SELECT $self->{SEARCH_FIELDS} b.id
      FROM users u
      INNER JOIN users_pi pi ON (u.uid=pi.uid)
      LEFT JOIN builds b ON (b.id=pi.location_id)
      LEFT JOIN streets s ON (b.street_id=s.id)
    $WHERE
    $GROUP_BY
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  return $self->{list} || [];
}

#**********************************************************
=head1 users_development_add($attr)

=cut
#**********************************************************
sub users_development_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('users_development', $attr);

  return $self;
}

#**********************************************************
=head1 users_development_report($attr)

=cut
#**********************************************************
sub users_development_report {
  my $self = shift;
  my $date = shift;
  my ($attr) = @_;

  $attr->{GROUP_BY} //= 'districts.name';
  my $GROUP_BY = !$attr->{TOTAL} ? "GROUP BY $attr->{GROUP_BY}" : '';
  my $WHERE = "WHERE ud.date = DATE_FORMAT(NOW(), '%Y-%m-%d')";
  if ($date && $date =~ '^<(.+)') {
    $WHERE = "WHERE ud.date = (SELECT date FROM users_development WHERE date $date GROUP BY date ORDER BY date DESC LIMIT 1)";
  }
  elsif ($date) {
    $WHERE = "WHERE ud.date = '$date'";
  }

  my @address_filter = ();
  if ($attr->{DISTRICT_ID}) {
    $attr->{DISTRICT_ID} =~ s/;/,/g;
    push (@address_filter, "districts.id IN ($attr->{DISTRICT_ID})") ;
  }

  if ($attr->{CITY}) {
    my $city_exp = join(",", map { "'$_'" } split(';', $attr->{CITY}));
    push (@address_filter, "districts.city IN ($city_exp)") ;
  }

  $WHERE .= " AND (" . join(' OR ', @address_filter) . ")" if (scalar(@address_filter));

  $self->query("SELECT id, name, users_count, city,
      allowed, sum_allowed, (sum_allowed / allowed) AS allowed_arpu,

      denied, sum_denied, (sum_denied / denied) AS denied_arpu,

      outflow, sum_outflow, (sum_outflow / outflow) AS outflow_arpu,

      outflow_disable, sum_outflow_disable, (sum_outflow_disable / outflow_disable) AS outflow_disable_arpu,

      outflow_neg_deposit, sum_outflow_neg_deposit, (sum_outflow_neg_deposit / outflow_neg_deposit)
      AS outflow_neg_deposit_arpu,

      outflow_holdup, sum_outflow_holdup, (sum_outflow_holdup / outflow_holdup) AS outflow_holdup_arpu,

      (outflow / users_count * 100) AS outflow_percent,
      (outflow_disable / outflow * 100) AS outflow_disable_percent,
      (outflow_neg_deposit / outflow * 100) AS outflow_neg_deposit_percent,
      (outflow_holdup / outflow * 100) AS outflow_holdup_percent,

      (sum_outflow / total_sum * 100) AS sum_outflow_percent,
      (sum_outflow_disable / sum_outflow * 100) AS sum_outflow_disable_percent,
      (sum_outflow_neg_deposit / sum_outflow * 100) AS sum_outflow_neg_deposit_percent,
      (sum_outflow_holdup / sum_outflow * 100) AS sum_outflow_holdup_percent

    FROM (
      SELECT districts.id AS id, $attr->{GROUP_BY} AS name, districts.city AS city,
        COUNT(ud.uid) AS users_count, SUM(ud.sum) AS total_sum,
          COUNT(IF(ud.disable = 0 AND b.deposit > -5, ud.id, null)) AS allowed,
          COUNT(IF(ud.disable = 0 AND b.deposit <= -5, ud.id, null)) AS denied,
          COUNT(IF(ud.disable = 1 OR ud.disable = 3 OR ud.disable = 5, ud.id, null)) AS outflow,
          COUNT(IF(ud.disable = 1, ud.id, null)) AS outflow_disable,
          COUNT(IF(ud.disable = 5, ud.id, null)) AS outflow_neg_deposit,
          COUNT(IF(ud.disable = 3, ud.id, null)) AS outflow_holdup,

          SUM(IF(ud.disable = 0 AND b.deposit > -5, ud.sum, 0)) AS sum_allowed,
          SUM(IF(ud.disable = 0 AND b.deposit <= -5, ud.sum, 0)) AS sum_denied,

          SUM(IF(ud.disable = 1 OR ud.disable = 3 OR ud.disable = 5, ud.sum, 0)) AS sum_outflow,
          SUM(IF(ud.disable = 1, ud.sum, 0)) AS sum_outflow_disable,
          SUM(IF(ud.disable = 5, ud.sum, 0)) AS sum_outflow_neg_deposit,
          SUM(IF(ud.disable = 3, ud.sum, 0)) AS sum_outflow_holdup

      FROM users_development ud
      LEFT JOIN users u ON (u.uid = ud.uid)
      LEFT JOIN bills b ON (u.bill_id = b.id)
      LEFT JOIN users_pi pi ON (u.uid=pi.uid)
      LEFT JOIN builds ON (builds.id=pi.location_id)
      LEFT JOIN streets ON (streets.id=builds.street_id)
      LEFT JOIN districts ON (districts.id=streets.district_id)

      $WHERE

      $GROUP_BY
    ) T1
    ORDER BY city, name",
    undef,
    { COLS_NAME => 1 }
  );

  return $attr->{TOTAL} ? $self->{list}[0] : $self->{list} || [];
}

#**********************************************************
=head1 users_development_growth($attr)

=cut
#**********************************************************
sub users_development_growth {
  my $self = shift;
  my ($attr) = @_;

  my $WHERE = '';

  if ($attr->{FROM_DATE} && $attr->{TO_DATE}) {
    if ($attr->{FROM_DATE} eq $attr->{TO_DATE}) {
      $WHERE .= "u.registration = '$attr->{FROM_DATE}'"
    }
    else {
      $WHERE .= "u.registration >= '$attr->{FROM_DATE}' AND u.registration < '$attr->{TO_DATE}'"
    }
  }

  $self->query("SELECT COUNT(u.uid) AS users, districts.name, districts.city
    FROM users u
    LEFT JOIN bills b ON (u.bill_id = b.id)
    LEFT JOIN users_pi pi ON (u.uid=pi.uid)
    LEFT JOIN builds ON (builds.id=pi.location_id)
    LEFT JOIN streets ON (streets.id=builds.street_id)
    LEFT JOIN districts ON (districts.id=streets.district_id)

    WHERE $WHERE

    GROUP BY districts.id",
    undef,
    { COLS_NAME => 1 }
  );

  return $self->{list} || [];

}

#**********************************************************
=head2 account_check()

=cut
#**********************************************************
sub account_check {
  my $self = shift;

  $self->query("SELECT COUNT(uid) FROM internet_main;");

  if($self->{TOTAL}) {
    if($self->{list}->[0]->[0] > 0x4B2) {
      $self->{errno} = 0x2BC;
    }
  }

  return $self;
}

1;
