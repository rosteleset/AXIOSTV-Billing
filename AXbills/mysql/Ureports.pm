package Ureports;
#*********************** ABillS ***********************************
# Copyright (с) 2003-2023 Andy Gulay (ABillS DevTeam) Ukraine
#
# See COPYRIGHT section in pod text below for usage and distribution rights.
#
#******************************************************************
=head1 NAME

  Ureports - DB functions

=head1 VERSION

  VERSION: 8.05
  UPDATE: 20230627

=cut

use strict;
use parent qw(dbcore);
use Tariffs;

our $VERSION = 8.05;
my $MODULE = 'Ureports';

my Tariffs $Tariffs;
my $admin;
my $CONF;

#**********************************************************
# Init
#**********************************************************
sub new {
  my $class = shift;
  my ($db)  = shift;
  ($admin, $CONF) = @_;
  $admin->{MODULE} = $MODULE;

  my $self = {
    db   => $db,
    admin=> $admin,
    conf => $CONF
  };
  bless($self, $class);

  if ($CONF->{DELETE_USER}) {
    $self->{UID} = $CONF->{DELETE_USER};
    $self->user_del({ UID => $CONF->{DELETE_USER} });
  }

  $Tariffs = Tariffs->new($self->{db}, $CONF, $admin);

  return $self;
}

#**********************************************************
=head2 user_info($uid, $attr) - User information

=cut
#**********************************************************
sub user_info {
  my $self = shift;
  my ($uid, $attr) = @_;

  $attr->{UID} = $uid;

  my $WHERE = $self->search_former($attr, [ [ 'UID', 'INT', 'um.uid' ] ], { WHERE => 1 });

  $self->query("SELECT
  um.uid,
  um.tp_id,
  tp.name AS tp_name,
  um.registration,
  um.status,
  tp.id AS tp_num,
  GROUP_CONCAT(ust.type) AS types,
  GROUP_CONCAT(CONCAT(ust.type, '|', IF(ust.destination <> '', ust.destination, ' '))) AS destinations
     FROM ureports_main um
     LEFT JOIN tarif_plans tp ON (um.tp_id=tp.tp_id)
     LEFT JOIN ureports_user_send_types ust ON (ust.uid=um.uid)
   $WHERE
   GROUP BY um.uid;",
    undef,
    { INFO => 1 }
  );

  return $self;
}

#**********************************************************
=head2 user_add()

=cut
#**********************************************************
sub user_add {
  my $self = shift;
  my ($attr) = @_;

  if ($attr->{TP_ID} > 0 && !$attr->{STATUS}) {
    $self->{TP_INFO} = $Tariffs->info($attr->{TP_ID});

    #Take activation price
    if ($Tariffs->{ACTIV_PRICE} > 0) {
      require Users;
      Users->import();
      my $user = Users->new($self->{db}, $admin, $CONF);
      $user->info($attr->{UID});

      if ($user->{DEPOSIT} + $user->{CREDIT} < $Tariffs->{ACTIV_PRICE} && $Tariffs->{PAYMENT_TYPE} == 0) {
        $self->{errno} = 15;
        return $self;
      }

      require Fees;
      Fees->import();
      my $fees = Fees->new($self->{db}, $admin, $CONF);
      $fees->take($user, $Tariffs->{ACTIV_PRICE}, { DESCRIBE => "Ureports: ACTIV TP" });

      $Tariffs->{ACTIV_PRICE} = 0;
    }
  }

  $self->query_add('ureports_main', { %$attr, REGISTRATION => 'NOW()' });

  return $self if ($self->{errno});

  $self->user_send_types_add($attr);

  $admin->{MODULE} = $MODULE;
  $admin->action_add($attr->{UID}, "TP_ID: $attr->{TP_ID}", { TYPE => 1 });

  return $self;
}

#**********************************************************
=head2 user_send_types_add()

=cut
#**********************************************************
sub user_send_types_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('ureports_user_send_types', undef, { uid => $attr->{UID} });
  my @types = split(/,\s?/, $attr->{TYPE});
  my @MULTI_QUERY = ();

  foreach my $type (@types) {
    push @MULTI_QUERY, [ $attr->{UID}, $type, $attr->{'DESTINATION_' . $type} || '' ];
  }

  $self->query("INSERT INTO ureports_user_send_types (uid, type, destination) VALUES (?, ?, ?);",
    undef, { MULTI_QUERY =>  \@MULTI_QUERY });

  return $self;
}

#**********************************************************
=head2 user_send_type_add()

=cut
#**********************************************************
sub user_send_type_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('ureports_user_send_types', $attr, { REPLACE => ($attr->{REPLACE}) ? 1 : undef });

  return $self;
}

#**********************************************************
=head2 user_send_type_del()

=cut
#**********************************************************
sub user_send_type_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('ureports_user_send_types', undef, $attr);

  return $self;
}

#**********************************************************
=head2 user_list_add($attr)

=cut
#**********************************************************
sub user_list_add {
  my $self = shift;
  my ($attr) = @_;

  my @uids = split(/,\s?/, $attr->{UIDS});
  my @MULTI_QUERY = ();
  $self->{errnostr} = '';
  $admin->{MODULE} = $MODULE;

  if ($attr->{TP_ID} > 0) {
    require Contacts;
    Contacts->import();
    require Users;
    Users->import();
    require Fees;
    Fees->import();
    my $Contacts = Contacts->new($self->{db}, $admin, $self->{conf});
    my $user = Users->new($self->{db}, $admin, $CONF);
    my $fees = Fees->new($self->{db}, $admin, $CONF);
    my %contacts_hash = ();

    $self->{TP_INFO} = $Tariffs->info($attr->{TP_ID});
    # Make Contacts type hash
    my $uids = $attr->{UIDS};
    $uids =~ s/,/;/g;
    my $contacts_list = $Contacts->contacts_list({
      UID       => $uids || '_SHOW',
      VALUE     => '_SHOW',
      TYPE      => '_SHOW',
      COLS_NAME => 1
    });

    foreach my $line (@$contacts_list) {
      $contacts_hash{$line->{uid}}{$line->{type_id}} = $line->{value};
    }

    foreach my $uid (@uids) {
      # get user info
      my $user_info = $user->list({
        UID        => $uid,
        CREDIT     => '_SHOW',
        DEPOSIT    => '_SHOW',
        BILL_ID    => '_SHOW',
        PHONE      => '_SHOW',
        EMAIL      => '_SHOW',
        COLS_NAME  => 1,
        COLS_UPPER => 1
      });
      $user_info = $user_info->[0];
      if ($attr->{TYPE} && $attr->{TYPE} eq 9) {
        $attr->{DESTINATION_9} = $contacts_hash{$uid}{$attr->{TYPE}} || q{};
      }
      elsif ($attr->{TYPE} && $attr->{TYPE} eq 1) {
        $attr->{DESTINATION_1} = $contacts_hash{$uid}{$attr->{TYPE}} || $contacts_hash{$uid}{'2'} || q{};
      }
      elsif ($attr->{TYPE} && $attr->{TYPE} eq 14) {
        $attr->{DESTINATION_14} = $contacts_hash{$uid}{$attr->{TYPE}} || $contacts_hash{$uid}{'1'} || q{};
      }

      if ((defined($attr->{DESTINATION_9}) && !$attr->{DESTINATION_9}) || ((defined($attr->{DESTINATION_1}) && !$attr->{DESTINATION_1}))) {
        $self->{errnostr} .= "$uid,";
        next;
      }

      if ($Tariffs->{ACTIVATE_PRICE} > 0) {
        if ($user_info->{DEPOSIT} + $user_info->{CREDIT} < $Tariffs->{ACTIVATE_PRICE} && $Tariffs->{PAYMENT_TYPE} == 0) {
          $self->{errnostr} .= "$uid,";
          next;
        }
        else {
          # make fees for user
          $fees->take($user_info, $Tariffs->{ACTIVATE_PRICE}, { DESCRIBE => "Ureports: ACTIVE Tariff plan" });
          push @MULTI_QUERY, [ $uid, $attr->{TP_ID} || '', $attr->{STATUS} || '' ];
        }
      }
      else {
        push @MULTI_QUERY, [ $uid, $attr->{TP_ID} || '', $attr->{STATUS} || '' ];
      }

      $self->user_send_types_add({ UID => $uid, %{$attr} });
      # Make action log
      $admin->action_add($uid, "TP_ID: $attr->{TP_ID}", { TYPE => 1 });
    }
  }

  $self->query(
    "REPLACE INTO ureports_main (uid, tp_id, status, registration)
        VALUES (?, ?, ?, NOW());",
    undef,
    { MULTI_QUERY => \@MULTI_QUERY }
  );

  return $self if ($self->{errno});

  $self->{TOTAL} = scalar(@MULTI_QUERY);

  return $self;
}

#**********************************************************
=head2 user_change($attr)

=cut
#**********************************************************
sub user_change {
  my $self = shift;
  my ($attr) = @_;

  $admin->{MODULE} = $MODULE;
  $self->changes({
    CHANGE_PARAM => 'UID',
    TABLE        => 'ureports_main',
    DATA         => $attr
  });

  $self->user_send_types_add($attr) if (!$attr->{SKIP_ADD_SEND_TYPES});

  return $self;
}

#**********************************************************
=head2 user_del($attr)

=cut
#**********************************************************
sub user_del {
  my $self = shift;
  my ($attr) = @_;
  if ($attr->{TP_ID}) {
    $self->query_del('ureports_main', undef, { tp_id => $attr->{TP_ID} });
    return $self;
  }

  $self->query_del('ureports_main', $attr, { uid => $self->{UID} });
  my $total = $self->{AFFECTED};

  if (!$self->{errno}) {
    $admin->action_add($self->{UID}, $self->{UID}, { TYPE => 10 });
    $self->query_del('ureports_user_send_types', undef, { uid => $attr->{UID} });
    $self->query_del('ureports_users_reports', undef, { uid => $attr->{UID} });
  }

  $self->{AFFECTED} = $total;
  return $self;
}

#**********************************************************
=head2 user_list($attr)

=cut
#**********************************************************
sub user_list {
  my $self   = shift;
  my ($attr) = @_;

  $self->{EXT_TABLES} = '';

  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  my $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $WHERE =  $self->search_former($attr, [
    ['TP_ID',          'INT', 's.tp_id'                                         ],
    ['TP_NAME',        'INT', 'tp.name', 'tp.name AS tp_name'                   ],
    ['DESTINATION',    'STR', 'GROUP_CONCAT(ust.destination) AS destination', 1 ],
    ['DESTINATION_ID', 'STR', 'ust.destination AS destination_id',            1 ],
    ['TYPE',           'STR', 'GROUP_CONCAT(ust.type) AS type',               1 ],
    ['STATUS',         'INT', 's.status',                                     1 ],
    ['UID',            'INT', 's.uid',                                        1 ],
    ['LAST_MESSAGE',   'STR', 'log.body', 'log.body as last_message'            ],
    ['REPORTS_COUNT',  'INT', '', '(SELECT COUNT(ur.uid) FROM ureports_users_reports ur WHERE ur.uid = s.uid) AS reports_count' ]
  ],
    {
      WHERE            => 1,
      USE_USER_PI      => 1,
      USERS_FIELDS_PRE => 1
    }
  );


  my $EXT_TABLES = $self->{EXT_TABLES} || '';

  if($self->{LAST_MESSAGE}){
    $EXT_TABLES .= 'LEFT JOIN (SELECT * FROM ureports_log ORDER BY id DESC LIMIT 1) log ON (u.uid=log.uid)';
  }

  $self->query("SELECT $self->{SEARCH_FIELDS}
      u.uid, s.tp_id
     FROM users u
     INNER JOIN ureports_main s ON (u.uid = s.uid)
     LEFT JOIN tarif_plans tp ON (tp.tp_id=s.tp_id)
     LEFT JOIN ureports_user_send_types ust ON (ust.uid=s.uid)
     $EXT_TABLES
     $WHERE
     GROUP BY u.uid
     ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  return $self if ($self->{errno});

  my $list = $self->{list} || [];

  if ($self->{TOTAL} >= 0) {
    $self->query("SELECT COUNT(u.id) AS total FROM users u
    INNER JOIN ureports_main s ON (u.uid = s.uid)
    LEFT JOIN tarif_plans tp ON (tp.tp_id=s.tp_id)
    LEFT JOIN ureports_user_send_types ust ON (ust.uid=s.uid)
    $EXT_TABLES
    $WHERE", undef, { INFO => 1 });
  }

  return $list;
}

#**********************************************************
# Periodic
#**********************************************************
#sub periodic {
#  my $self = shift;
#  my ($period) = @_;
#
#  if ($period eq 'daily') {
#    #$self->daily_fees();
#  }
#
#  return $self;
#}

#**********************************************************
=head tp_list($attr)

=cut
#**********************************************************
sub tp_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  my $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';

  $self->query("SELECT tp.id, tp.name, if(sum(i.tarif) is NULL or sum(i.tarif)=0, 0, 1),
    tp.payment_type,
    tp.day_fee, tp.month_fee,
    tp.logins,
    tp.age
    tp.tp_id
    FROM tarif_plans tp
    LEFT JOIN intervals i ON (i.tp_id=tp.id)
    GROUP BY tp.id
    ORDER BY $SORT $DESC;",
    undef,
    $attr
  );

  return $self->{list} || [];
}

#**********************************************************
# Default values
#**********************************************************
# sub tp_defaults {
#   my $self = shift;
#
#   my %DATA = (
#     TP_ID                => 0,
#     NAME                 => '',
#     TIME_TARIF           => '0.00000',
#     DAY_FEE              => '0,00',
#     MONTH_FEE            => '0.00',
#     SIMULTANEOUSLY       => 0,
#     AGE                  => 0,
#     DAY_TIME_LIMIT       => 0,
#     WEEK_TIME_LIMIT      => 0,
#     MONTH_TIME_LIMIT     => 0,
#     ACTIV_PRICE          => '0.00',
#     CHANGE_PRICE         => '0.00',
#     CREDIT_TRESSHOLD     => '0.00',
#     ALERT                => 0,
#     MAX_SESSION_DURATION => 0,
#     PAYMENT_TYPE         => 0,
#     MIN_SESSION_COST     => '0.00000',
#     RAD_PAIRS            => '',
#     FIRST_PERIOD         => 0,
#     FIRST_PERIOD_STEP    => 0,
#     NEXT_PERIOD          => 0,
#     NEXT_PERIOD_STEP     => 0,
#     FREE_TIME            => 0
#   );
#
#   $self->{DATA} = \%DATA;
#
#   return \%DATA;
# }

#**********************************************************
=head2 tp_add($attr) Add tp

=cut
#**********************************************************
sub tp_add {
  my $self = shift;
  my ($attr) = @_;

  if ( ! $attr->{TP_ID}) {
    $Tariffs->add({ %$attr });

    if (defined($Tariffs->{errno})) {
      $self->{errno} = $Tariffs->{errno};
      return $self;
    }

    $attr->{TP_ID} = $Tariffs->{INSERT_ID};
    $self->{TP_NUM} = $Tariffs->{TP_NUM};
  }

  $self->query('INSERT INTO ureports_tp (tp_id, msg_price) VALUES (?, ?);', 'do',
    { Bind => [ $attr->{TP_ID}, $attr->{MSG_PRICE} ] }
  );

  $self->{TP_ID} = $attr->{TP_ID};

  return $self;
}

#**********************************************************
=head2 tp_change($tp_id, $attr)

=cut
#**********************************************************
sub tp_change {
  my $self = shift;
  my ($tp_id, $attr) = @_;

  $Tariffs->change($tp_id, $attr);
  if (defined($Tariffs->{errno})) {
    $self->{errno} = $Tariffs->{errno};
    return $self;
  }

  $self->changes({
    CHANGE_PARAM => 'TP_ID',
    TABLE        => 'ureports_tp',
    DATA         => $attr
  });

  if ( $self->{errno} ) {
    $self->tp_add($attr);
  }

  $self->tp_info($tp_id);

  return $self;
}

#**********************************************************
=head2 tp_del($id)

=cut
#**********************************************************
sub tp_del {
  my $self = shift;
  my ($tp_id) = @_;

  $self->query_del('ureports_tp', undef, { TP_ID => $tp_id });
  $Tariffs->del($tp_id);
  $self->tp_reports_del($tp_id);
  $self->tp_user_reports_del({ TP_ID => $tp_id });
  $self->user_del({ TP_ID => $tp_id });

  return $self;
}

#**********************************************************
=head2 tp_info($id, $attr)

=cut
#**********************************************************
sub tp_info {
  my $self = shift;
  my ($id, $attr) = @_;

  $self->{TP_INFO} = $attr->{CHG_TP_ID} ? $Tariffs->info($attr->{CHG_TP_ID}) : $Tariffs->info($id);

  return $self if (defined($Tariffs->{errno}));

  while (my ($k, $v) = each %{$self->{TP_INFO}}) {
    if (ref $v eq '') {
      $self->{$k} = $v;
    }
  }

  my $tp_id = $Tariffs->{TP_ID};

  my $date = '';
  if ($attr->{DATE}) {
    $date = 'AND last_active <="' . $attr->{DATE} . '"';
  }

  $self->query("SELECT tp_id AS id,
    msg_price, last_active
     FROM ureports_tp
    WHERE tp_id= ? $date;",
    undef,
    {
      INFO => 1,
      Bind => [ $tp_id ],
    }
  );

  if ($self->{errno} && $self->{errno} == 2) {
    delete $self->{errno};
    delete $self->{errstr};
  }

  return $self;
}

#**********************************************************
=head2 tp_reports_list($attr)

=cut
#**********************************************************
sub tp_reports_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  my $WHERE = "WHERE tp_id='$attr->{TP_ID}'";

  $self->query("SELECT report_id, msg_price, comments, module, visual
    FROM ureports_tp_reports
    $WHERE
    ORDER BY $SORT $DESC;",
    undef,
    $attr
  );

  return $self->{list} || [];
}

#**********************************************************
=head2 tp_reports_change($attr)

=cut
#**********************************************************
sub tp_reports_change {
  my $self = shift;
  my ($attr) = @_;

  $self->tp_reports_del($attr->{TP_ID});
  my @ids = split(/,\s?/, $attr->{IDS});

  my @MULTI_QUERY = ();
  foreach my $id (@ids) {
    push @MULTI_QUERY, [
      $attr->{TP_ID},
      $attr->{ 'PRICE_' . $id },
      $id,
      $attr->{ 'COMMENTS_' . $id } || '',
      $attr->{ 'MODULE_' . $id } || '',
      $attr->{ 'VISUAL_' . $id } || 0,
    ];
  }

  $self->query('INSERT INTO ureports_tp_reports (tp_id, msg_price, report_id, comments, module, visual)
      VALUES (?, ?, ?, ?, ?, ?);',
    undef,
    { MULTI_QUERY =>  \@MULTI_QUERY });

  return $self;
}

#**********************************************************
=head2 tp_reports_del($tp_id)

=cut
#**********************************************************
sub tp_reports_del {
  my $self = shift;
  my ($tp_id) = @_;

  $self->query_del('ureports_tp_reports', undef, { tp_id => $tp_id });

  return $self;
}

#**********************************************************
=head2 tp_user_reports_reset_date($attr)

  Arguments:
    $attr
      UID
      REPORT_ID

  Results:

=cut
#**********************************************************
sub tp_user_reports_reset_date {
  my $self = shift;
  my ($attr) = @_;

  my @fields = ();
  my @values = ();

  if($attr->{REPORT_ID}) {
    push @fields, 'report_id = ?';
    push @values, $attr->{REPORT_ID};
  }

  if(! $attr->{ALL_USERS}) {
    push @fields, 'uid = ?';
    push @values, $attr->{UID} || '-';
  }

  $self->query("UPDATE ureports_users_reports
    SET date='0000-00-00'
    WHERE ". join(' AND ', @fields), 'do',
    {
      Bind => \@values
    }
  );

  return $self;
}

#**********************************************************
=head2 tp_user_reports_list($attr)

=cut
#**********************************************************
sub tp_user_reports_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  my $uid = $attr->{UID} || '';
  my $EXT_TABLE  = '';
  if ($attr->{UID}) {
    my $WHERE =  $self->search_former($attr, [
      ['TP_ID',             'INT', 'tpr.tp_id',                                           1 ],
      ['REPORT_ID',         'INT', 'tpr.report_id'                                          ],
      ['COMMENTS',          'STR', 'tpr.comments',                                        1 ],
      ['DESTINATION_TYPE',  'INT', 'GROUP_CONCAT(DISTINCT ust.type) AS destination_type', 1 ],
      ['DESTINATION_ID',    'STR', 'GROUP_CONCAT(ust.destination) AS destination_id',     1 ],
      ['VISUAL',            'STR', 'tpr.visual',                                          1 ],
      ['STATUS',            'INT', 'um.status',                                           1 ],
    ],
      { WHERE => 1 }
    );

    if ($attr->{REPORT_ID}) {
      #  	  $EXT_TABLE = " INNER JOIN ureports_main um ON (ur.uid=um.uid) "
      #        . "INNER JOIN users u ON (um.uid=ur.uid)";
      #$EXT_TABLE = " INNER JOIN users u ON (um.uid=ur.uid)";
      $EXT_TABLE = " INNER JOIN users u ON (um.uid=u.uid)";
    }

    if ($attr->{INTERNET_TP}) {
      $EXT_TABLE .= '
      LEFT JOIN internet_main internet ON  (internet.uid=u.uid)
      LEFT JOIN tarif_plans tp ON  (tp.tp_id=internet.tp_id)';
      $self->{SEARCH_FIELDS} .= 'IF(internet.personal_tp>0, internet.personal_tp, tp.month_fee) AS tp_month_fee,';
    }

    # if ($attr->{DV_TP}) {
    #   $EXT_TABLE .= '
    #   LEFT JOIN dv_main internet ON  (internet.uid=u.uid)
    #   LEFT JOIN tarif_plans tp ON  (tp.tp_id=internet.tp_id)';
    #   $self->{SEARCH_FIELDS} .= 'tp.month_fee AS tp_month_fee,';
    # }

    $self->query("SELECT tpr.report_id,
      ur.value,
      tpr.msg_price,
      $self->{SEARCH_FIELDS}
      ur.date,
      ur.uid
    FROM ureports_tp_reports tpr
    INNER JOIN ureports_main um ON (tpr.tp_id=um.tp_id AND um.uid='$uid')
    LEFT JOIN ureports_user_send_types ust ON (ust.uid=um.uid)
    LEFT JOIN ureports_users_reports ur ON (ur.report_id=tpr.report_id AND ur.uid='$uid')
    $EXT_TABLE
    $WHERE
    GROUP BY 1
    ORDER BY $SORT $DESC;",
      undef,
      $attr
    );
  }
  else {
    my $HAVING     = '';
    my $cure_date = ($attr->{CUR_DATE}) ? "'$attr->{CUR_DATE}'": 'CURDATE()';

    $attr->{INTERNET_EXPIRE} = '_SHOW';

    my $WHERE =  $self->search_former($attr, [
      [ 'DATE',        'DATE', 'ur.date'      ],
      [ 'REPORT_ID',   'INT',  'ur.report_id' ],
      [ 'TP_ID',       'INT',  'um.tp_id'     ],
      [ 'LOGIN',       'STR',  'u.id'         ],
      [ 'ACCOUNT_STATUS','INT','u.disable'    ],
      [ 'STATUS',      'INT',  'um.status'    ],
      [ 'ACTIVATE',    'DATE', 'u.activate', 1],
      [ 'DISABLE',     'INT',  'u.disable',  1],
      [ 'MODULE',      'STR',  'tpr.module', 1],
      [ 'PASSWORD',    'STR',  "DECODE(u.password, '$self->{conf}->{secretkey}')", "DECODE(u.password, '$self->{conf}->{secretkey}') AS password"],
      [ 'INTERNET_STATUS', 'INT', 'internet.disable', 'internet.disable AS internet_status'],
      [ 'INTERNET_EXPIRE', 'INT', '', "DATEDIFF(IF(internet.activate='0000-00-00',
       DATE_FORMAT($cure_date + INTERVAL 1 MONTH, '%Y-%m-01'), internet.activate + INTERVAL 31 DAY), $cure_date) AS internet_expire", ],
      [ 'DEPOSIT',     'INT', 'IF(company.id IS NULL, b.deposit, cb.deposit)'              ],
    ],
      { WHERE => 1 }
    );

    if ($attr->{INTERNET_TP}) {
      $EXT_TABLE = '
      LEFT JOIN internet_main internet ON  (internet.uid=u.uid)
      LEFT JOIN tarif_plans tp ON  (tp.tp_id=internet.tp_id)';
      $self->{SEARCH_FIELDS} .= 'tp.month_fee AS tp_month_fee, tp.name AS tp_name,';
    }

    if ($attr->{INTERNET_STATUS} || $attr->{INTERNET_EXPIRE}) {
      $EXT_TABLE = '
        LEFT JOIN internet_main internet ON  (internet.uid=u.uid)
        LEFT JOIN tarif_plans tp ON  (tp.tp_id=internet.tp_id)';
    }

    # if ($attr->{DV_TP}) {
    #   $EXT_TABLE = '
    #   LEFT JOIN dv_main dv ON  (dv.uid=u.uid)
    #   LEFT JOIN tarif_plans tp ON  (tp.id=dv.tp_id)';
    #   $self->{SEARCH_FIELDS} .= 'tp.month_fee AS tp_month_fee,';
    # }
    #
    # if ($attr->{DV_STATUS}) {
    #   $EXT_TABLE = '
    #     LEFT JOIN dv_main dv ON (dv.uid=u.uid)
    #     LEFT JOIN tarif_plans tp ON (tp.id=dv.tp_id)';
    # }

    if ($attr->{RESET}) {
      $HAVING = 'HAVING ur.value<deposit';
    }

    $self->query("SELECT ur.report_id,
       GROUP_CONCAT(ust.type) AS destination_type,
       GROUP_CONCAT(ust.destination) AS destination_id,
       ur.value,
       tpr.msg_price,
       IF(u.company_id > 0, cb.deposit, b.deposit) AS deposit,
       IF(u.company_id > 0, IF(u.credit=0, company.credit, u.credit), u.credit) AS credit,
       pi.fio,
       ur.uid,
       IF(u.company_id > 0, company.bill_id, u.bill_id) AS bill_id,
       u.disable,
       DATEDIFF(u.credit_date, CURDATE()) AS credit_expire,
       internet.id as service_id,
       pi.contract_id,
       pi.contract_date,
       u.reduction,
       $self->{SEARCH_FIELDS}
       u.id AS login
    FROM ureports_tp_reports tpr
    INNER JOIN ureports_main um ON (um.tp_id=tpr.tp_id)
    LEFT JOIN ureports_user_send_types ust ON (ust.uid=um.uid)
    INNER JOIN ureports_users_reports ur ON (ur.uid=um.uid and ur.report_id=tpr.report_id)
    INNER JOIN users u ON (u.uid=um.uid)
    LEFT JOIN users_pi pi ON (u.uid=pi.uid)
    LEFT JOIN bills b ON (u.bill_id = b.id)
    LEFT JOIN companies company ON  (u.company_id=company.id)
    LEFT JOIN bills cb ON  (company.bill_id=cb.id)
    $EXT_TABLE
    $WHERE
    GROUP BY ur.uid, ur.report_id
    $HAVING
    ORDER BY $SORT $DESC;",
      undef,
      $attr
    );
  }

  return $self->{list} || [];
}

#**********************************************************
=head2 tp_user_reports_change($attr)

=cut
#**********************************************************
sub tp_user_reports_change {
  my $self = shift;
  my ($attr) = @_;

  my @MULTI_QUERY = ();
  my @ids = split(/,\s?/, $attr->{IDS});
  $self->tp_user_reports_del({ UID => $attr->{UID}, VISUAL => $attr->{VISUAL}, IDS => \@ids });

  foreach my $id (@ids) {
    push @MULTI_QUERY, [ $attr->{UID},
      $id,
      ($attr->{ 'VALUE_' . $id }) ? $attr->{ 'VALUE_' . $id } : 0,
      $attr->{TP_ID}
    ];
  }

  $self->query('INSERT INTO ureports_users_reports (uid, report_id, value, tp_id) VALUES (?, ?, ?, ?);',
    undef, { MULTI_QUERY => \@MULTI_QUERY });

  if (!$self->{errno}) {
    $admin->{MODULE} = $MODULE;
    $admin->action_add($attr->{UID}, "REPORT_ID: " . join(', ', @ids), { TYPE => 1 });
  }

  return $self;
}

#**********************************************************
=head2 tp_user_reports_update($attr) - Update report last send date

  Arguments:
    $attr
      UID
      REPORT_ID

  Return:
    $self

=cut
#**********************************************************
sub tp_user_reports_update {
  my $self = shift;
  my ($attr) = @_;

  $self->query('UPDATE ureports_users_reports SET date=NOW() WHERE uid= ? AND  report_id= ? ;',
    'do',
    { Bind => [
      $attr->{UID},
      $attr->{REPORT_ID}
    ]}
  );

  $admin->{MODULE}=$MODULE;
  $admin->action_add($attr->{UID}, "SENDED REPORT_ID: $attr->{REPORT_ID}", { TYPE => 1 });

  return $self;
}

#**********************************************************
=head2 tp_user_reports_del($attr)

  Arguments:
    $attr
      TP_ID
      UID

=cut
#**********************************************************
sub tp_user_reports_del {
  my $self = shift;
  my ($attr) = @_;

  if ($attr->{TP_ID}) {
    $self->query_del('ureports_users_reports', undef, { tp_id => $attr->{TP_ID} });
    return $self;
  }

  if ($attr->{VISUAL} && $attr->{UID}) {
    my $list = $self->tp_user_reports_list({
      UID       => $attr->{UID},
      VISUAL    => 1,
      COLS_NAME => 1
    });
    my @del_ids = map {[ $attr->{UID}, $_->{report_id} ]} @$list;

    $self->query('DELETE FROM ureports_users_reports WHERE uid = ? AND report_id = ? ;',
      undef, { MULTI_QUERY => \@del_ids });

    return $self;
  }
  elsif ($attr->{REPORT_ID} && $attr->{UID}) {
    $self->query_del('ureports_users_reports', undef, { uid => $attr->{UID}, report_id => $attr->{REPORT_ID} });
    return $self;
  }
  $self->query_del('ureports_users_reports', undef, { uid => $attr->{UID} });

  return $self;
}

#**********************************************************
=head2 log_del($attr)

=cut
#**********************************************************
sub log_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('ureports_log', $attr, { uid => $attr->{UID} });

  return $self;
}

#**********************************************************
=head2 log_list($attr)

=cut
#**********************************************************
sub log_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  my $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  if ($attr->{INTERVAL}) {
    ($attr->{FROM_DATE}, $attr->{TO_DATE}) = split(/\//, $attr->{INTERVAL}, 2);
  }

  my $WHERE =  $self->search_former($attr, [
    ['TP_ID',          'INT', 'l.tp_id' ],
    ['UID',            'INT', 'l.uid'   ],
    ['DESTINATION',    'STR', 'l.destination' ],
    ['FROM_DATE|TO_DATE', 'DATE', "DATE_FORMAT(l.execute, '%Y-%m-%d')" ],
  ],
    {
      WHERE            => 1,
      USERS_FIELDS_PRE => 1,
      USE_USER_PI      => 1
    }
  );

  $self->query("SELECT l.id, u.id AS login, l.execute, l.destination, l.tp_id, l.report_id,
    l.status, l.uid
    FROM ureports_log l
    INNER JOIN users u ON (u.uid=l.uid)
    $WHERE
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  return $self->{list} || [];
}

#**********************************************************
=head2 log_add($attr)

=cut
#**********************************************************
sub log_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('ureports_log', { EXECUTE => 'NOW()', %$attr });

  return $self;
}

#**********************************************************
=head2 ureports_session_detail($id)

=cut
#**********************************************************
sub ureports_session_detail {
  my $self = shift;
  my ($id) = @_;

  $self->query("SELECT
  l.id,
  u.id AS login,
  l.execute AS sended,
  l.body,
  l.destination,
  l.report_id,
  tp.name AS tp_name,
  l.status
   FROM (ureports_log l, users u)
     LEFT JOIN tarif_plans tp ON (l.tp_id=tp.id)
   WHERE u.uid=l.uid AND l.id= ? ;",
    undef,
    { INFO => 1,
      Bind => [ $id ] }
  );

  return $self;
}

#**********************************************************
=head2 tp_user_reports_multi_change($attr)

=cut
#**********************************************************
sub tp_user_reports_multi_change {
  my $self = shift;
  my ($attr) = @_;

  my @uids = split(/,\s?/, $attr->{UIDS});
  my @ids = split(/,\s?/, $attr->{IDS});
  my @MULTI_QUERY = ();

  foreach my $uid (@uids) {
    $self->tp_user_reports_del({ UID => $uid });
    foreach my $id (@ids) {
      push @MULTI_QUERY, [ $uid,
        $id,
        ($attr->{ 'VALUE_' . $id }) ? $attr->{ 'VALUE_' . $id } : 0,
        $attr->{TP_ID}
      ];
    }
  }
  $self->query('INSERT INTO ureports_users_reports (uid, report_id, value, tp_id)
      VALUES (?, ?, ?, ?);',
    undef,
    { MULTI_QUERY =>  \@MULTI_QUERY });

  return $self;
}

=head1 COPYRIGHT

  Copyright (с) 2003-2023 Andy Gulay (ABillS DevTeam) Ukraine
  All rights reserved.
  https://axbills.net.ua/

=cut

1;