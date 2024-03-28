package Cams;

=name2

  Cams

=VERSION

  VERSION = 0.04

=cut

use strict;
use warnings FATAL => 'all';
use parent qw(dbcore);

use Tariffs;
my $Tariffs;

my $MODULE = 'Cams';
my ($SORT, $DESC, $PG, $PAGE_ROWS);
my ($db, $admin, $CONF);

#**********************************************************

=head2 new($db, $admin, $CONF)

  Arguments:
    $db    - ref to DB
    $admin - current Web session admin
    $CONF  - ref to %conf

  Returns:
    object

=cut

#**********************************************************
sub new {
  my $class = shift;
  ($db, $admin, $CONF) = @_;

  my $self = {
    db     => $db,
    admin  => $admin,
    conf   => $CONF,
    MODULE => 'Cams'
  };

  $Tariffs = Tariffs->new($self->{db}, $CONF, $admin);

  bless($self, $class);

  return $self;
}

#**********************************************************
sub _list {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : '';
  $DESC = ($attr->{DESC}) ? '' : 'DESC';
  $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 1000;

  my $search_columns = [
    [ 'UID',                'INT',  'cm.uid',                                1 ],
    [ 'LOGIN',              'STR',  'u.id as login',                         1 ],
    [ 'ID',                 'INT',  'cm.id',                                 1 ],
    [ 'TARIFF_ID',          'INT',  'tp.id as tariff_id',                    1 ],
    [ 'ACTIVATE',           'DATE', 'cm.activate',                           1 ],
    [ 'EXPIRE',             'DATE', 'cm.expire',                             1 ],
    [ 'TP_ID',              'INT',  'cm.tp_id',                              1 ],
    [ 'STATUS',             'INT',  'cm.status',                             1 ],
    [ 'TP_NAME',            'STR',  'tp.name as tp_name',                    1 ],
    [ 'TP_STREAMS_COUNT',   'INT',  'ctp.streams_count as tp_streams_count', 1 ],
    [ 'USER_STREAMS_COUNT', 'INT',  'COUNT(*) as user_streams_count',        1 ],
    [ 'SERVICE_ID',         'INT',  'ctp.service_id as service_id',          1 ],
    [ 'SERVICE_NAME',       'STR',  's.name as service_name',                1 ],
    [ 'SUBSCRIBE_ID',       'STR',  'cm.subscribe_id',                       1 ]
  ];

  if ($attr->{SHOW_ALL_COLUMNS}) {
    map {$attr->{ $_->[0] } = '_SHOW' unless (exists $attr->{ $_->[0] })} @{$search_columns};
  }

  my $WHERE = $self->search_former($attr, $search_columns, {
    WHERE             => 1,
    USE_USER_PI       => 1,
    USERS_FIELDS_PRE  => 1,
    SKIP_USERS_FIELDS => [ 'UID', 'ACTIVE', 'EXPIRE' ]
  });

  if ( ! $admin->{permissions}->{0}->{8} ) {
    $WHERE .= " AND u.deleted=0";
  }

  my $EXT_TABLE = $self->{EXT_TABLES} || '';

  $self->query(
    "SELECT $self->{SEARCH_FIELDS} cm.uid
   FROM cams_main cm
   LEFT JOIN users u           ON (cm.uid=u.uid)
   LEFT JOIN cams_streams cs   ON (cm.uid=cs.uid)
   LEFT JOIN cams_tp ctp       ON (cm.tp_id=ctp.tp_id)
   LEFT JOIN tarif_plans tp    ON (cm.tp_id=tp.tp_id)
   LEFT JOIN cams_services s   ON (ctp.service_id=s.id)
   $EXT_TABLE
   $WHERE GROUP BY cm.id;",
    undef,
    {
      COLS_NAME => 1,
      %{$attr ? $attr : {}}
    }
  );

  return [] if ($self->{errno});

  return $self->{list};
}

#**********************************************************

=head2 _info($id)

  Arguments:
    $id - id for cams_users

  Returns:
    hash_ref

=cut

#**********************************************************
sub _info {
  my $self = shift;
  my ($id, $attr) = @_;

  if (defined($attr->{LOGIN})) {
    use Users;
    my $users = Users->new($self->{db}, $admin, $CONF);
    $users->info(0, { LOGIN => $attr->{LOGIN} });
    if ($users->{errno}) {
      $self->{errno} = 2;
      $self->{errstr} = 'ERROR_NOT_EXIST';
      return $self;
    }

    $self->{DEPOSIT} = $users->{DEPOSIT};
    $self->{ACCOUNT_ACTIVATE} = $users->{ACTIVATE};
  }

  $self->query(
    "SELECT
   tp.name AS tp_name,
   tp.gid AS tp_gid,
   tp.month_fee,
   tp.month_fee AS month_abon,
   tp.abon_distribution,
   tp.day_fee,
   tp.activate_price,
   tp.postpaid_monthly_fee,
   tp.payment_type,
   tp.period_alignment,
   tp.id AS tp_num,
   tp.filter_id AS tp_filter_id,
   tp.credit AS tp_credit,
   tp.age AS tp_age,
   tp.activate_price AS tp_activate_price,
   tp.change_price AS tp_change_price,
   tp.period_alignment AS tp_period_alignment,
   cs_services.module AS service_module,
   c_tp.*,
   service.*
     FROM cams_main service
     LEFT JOIN tarif_plans tp ON (service.tp_id=tp.tp_id)
     LEFT JOIN cams_tp c_tp ON (c_tp.tp_id=tp.tp_id)
     LEFT JOIN cams_services cs_services ON (cs_services.id=tp.service_id)
   WHERE service.id= ? ;",
    undef,
    {
      INFO => 1,
      Bind => [ $id ]
    }
  );

  return $self;
}

#**********************************************************
=head2 _del($id)

=cut
#**********************************************************
sub _del {
  my $self = shift;
  my $id = shift;
  my ($attr) = @_;

  $self->query_del('cams_main', undef, { id => $id });

  $admin->{MODULE} = $MODULE;

  my @del_descr = ();
  push @del_descr, "UID: $attr->{UID}" if $attr->{UID};
  push @del_descr, "ID: $attr->{ID}" if $attr->{ID};
  push @del_descr, "COMMENTS: $attr->{COMMENTS}" if $attr->{COMMENTS};

  $admin->action_add($self->{UID}, join(' ', @del_descr), { TYPE => 10 });

  return $self;
}

#**********************************************************

=head2 users_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut

#**********************************************************
sub users_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 1000;

  if ($attr->{PORTAL}) {
    delete $attr->{SERVICE_ID};
  }

  my $search_columns = [
    [ 'UID',                'INT', 'cm.uid',                                  ],
    [ 'ID',                 'INT', 'cm.id',                                 1 ],
    [ 'TP_ID',              'INT', 'cm.tp_id',                              1 ],
    [ 'SERVICE_STATUS',     'INT', 'cm.status as service_status',           1 ],
    [ 'TP_NAME',            'STR', 'tp.name as tp_name',                    1 ],
    [ 'TP_STREAMS_COUNT',   'INT', 'ctp.streams_count as tp_streams_count', 1 ],
    [ 'USER_STREAMS_COUNT', 'INT', 'COUNT(*) as user_streams_count',        1 ],
    [ 'SERVICE_NAME',       'STR', 's.name as service_name',                1 ],
    [ 'MODULE',             'STR', 's.module',                              1 ],
    [ 'SERVICE_ID',         'INT', 'ctp.service_id',                        1 ],
    [ 'MONTH_FEE',          'INT', 'tp.month_fee',                          1 ],
    [ 'PERIOD_ALIGNMENT',   'INT', 'tp.PERIOD_ALIGNMENT',                   1 ],
    [ 'SUBSCRIBE_ID',       'STR', 'cm.subscribe_id',                       1 ],
  ];

  if ($attr->{SHOW_ALL_COLUMNS}) {
    map {$attr->{ $_->[0] } = '_SHOW' unless (exists $attr->{ $_->[0] })} @{$search_columns};
  }

  my $EXT_TABLE = '';
  $self->{EXT_TABLES} = '';

  my $WHERE = $self->search_former($attr, $search_columns, {
    WHERE             => 1,
    USERS_FIELDS_PRE  => 1,
    USE_USER_PI       => 1,
    SKIP_USERS_FIELDS => [ 'UID' ]
  });

  $EXT_TABLE = $self->{EXT_TABLES} if ($self->{EXT_TABLES});

  $self->query(
    "SELECT $self->{SEARCH_FIELDS} cm.uid
   FROM cams_main cm
   LEFT JOIN users u           ON (cm.uid=u.uid)
   LEFT JOIN cams_streams cs   ON (cm.uid=cs.uid)
   LEFT JOIN cams_tp ctp       ON (cm.tp_id=ctp.tp_id)
   LEFT JOIN tarif_plans tp    ON (cm.tp_id=tp.tp_id)
   LEFT JOIN cams_services s   ON (tp.service_id=s.id)
   $EXT_TABLE
   $WHERE GROUP BY cm.id ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS ;",
    undef,
    {
      COLS_NAME => 1,
      %{$attr ? $attr : {}}
    }
  );

  return [] if ($self->{errno});

  my $list = $self->{list} || [];

  $self->query("SELECT count(DISTINCT cm.id) AS total
    FROM cams_main cm
    LEFT JOIN users u           ON (cm.uid=u.uid)
    LEFT JOIN cams_streams cs   ON (cm.uid=cs.uid)
    LEFT JOIN cams_tp ctp       ON (cm.tp_id=ctp.tp_id)
    LEFT JOIN tarif_plans tp    ON (cm.tp_id=tp.tp_id)
    LEFT JOIN cams_services s   ON (tp.service_id=s.id)
    $EXT_TABLE
    $WHERE", undef, { INFO => 1 }
  );

  return $list;
}

#**********************************************************

=head2 user_info($id)

  Arguments:
    $id - id for cams_users

  Returns:
    hash_ref

=cut

#**********************************************************
sub user_info {
  my $self = shift;
  my ($uid) = @_;

  my $list = $self->users_list({ COLS_NAME => 1, UID => $uid, SHOW_ALL_COLUMNS => 1, COLS_UPPER => 1 });

  return $list->[0] || {};
}

#**********************************************************

=head2 user_add($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    1

=cut

#**********************************************************
sub user_add {
  my $self = shift;
  my ($attr) = @_;

  my $start_active = $attr->{ACTIVATE};
  $attr->{ACTIVATE} = 'NOW()' if (!$start_active);
  if ($attr->{TP_ID} && $attr->{TP_ID} > 0 && !$attr->{STATUS}) {
    $self->{TP_INFO} = $Tariffs->info($attr->{TP_ID});

    $self->{TP_NUM} = $Tariffs->{ID};

    #Take activation price
    if ($Tariffs->{ACTIV_PRICE} > 0) {
      my $User = Users->new($self->{db}, $self->{admin}, $self->{conf});
      $User->info($attr->{UID});

      if ($User->{DEPOSIT} + $User->{CREDIT} < $Tariffs->{ACTIV_PRICE} && $Tariffs->{PAYMENT_TYPE} == 0) {
        $self->{errno} = 15;
        $self->{errstr} = 'TOO_SMALL_DEPOSIT';
        return $self;
      }

      my $fees = Fees->new($self->{db}, $self->{admin}, $self->{conf});
      $fees->take($User, $Tariffs->{ACTIV_PRICE}, { DESCRIBE => "Cams. Active TP" });
      $Tariffs->{ACTIV_PRICE} = 0;
    }
  }

  $attr->{ACTIVATE} = '0000-00-00' if (!$start_active && !$Tariffs->{AGE});
  $self->query_add('cams_main', $attr);

  return if $self->{errno};

  $admin->{MODULE} = $MODULE;

  my @info = ('SERVICE_ID', 'ID', 'TP_ID', 'STATUS', 'EMAIL');
  my @actions_history = ();

  foreach my $param (@info) {
    next if !defined $attr->{$param};

    push @actions_history, $param . ":" . $attr->{$param};
  }

  $self->{ID} = $self->{INSERT_ID};

  $admin->action_add($attr->{UID}, "ID: $self->{INSERT_ID} ".  join(', ', @actions_history), { TYPE => 1 } );

  return $self->{INSERT_ID};
}

#**********************************************************

=head2 users_del($attr)

  Arguments:
    $attr - hash_ref

  Returns:
   1

=cut

#**********************************************************
sub users_del {
  my $self = shift;
  my ($attr) = @_;

  my $uid = $attr->{UID} || $attr->{del};

  $self->query_del('cams_main', $attr, { 'uid' => [ $uid ] });

  return 1;
}

#**********************************************************

=head2 user_change($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    1

=cut

#**********************************************************
sub user_change {
  my $self = shift;
  my ($attr) = @_;

  my $old_info = $self->_info($attr->{ID});
  $self->{OLD_STATUS} = $old_info->{STATUS};
  $attr->{EXPIRE}  = $attr->{SERVICE_EXPIRE};
  $attr->{DISABLE} = $attr->{STATUS};

  $admin->{MODULE} = $MODULE;
  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'cams_main',
    DATA         => $attr
  });

  $self->_info($attr->{ID});

  return $self;
}

#**********************************************************

=head2 tp_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut

#**********************************************************
sub tp_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $search_columns = [
    [ 'TP_ID',            'INT', 'ctp.tp_id',                        1 ],
    [ 'ID',               'INT', 'tp.id',                            1 ],
    [ 'SERVICE_NAME',     'STR', 's.name as service_name',           1 ],
    [ 'NAME',             'STR', 'tp.name',                          1 ],
    [ 'STREAMS_COUNT',    'INT', 'ctp.streams_count',                1 ],
    [ 'PAYMENT_TYPE',     'INT', 'tp.payment_type',                  1 ],
    [ 'SERVICE_ID',       'INT', 'tp.service_id',                    1 ],
    [ 'MODULE',           'STR', 'tp.module',                        1 ],
    [ 'DAY_FEE',          'INT', 'tp.day_fee',                       1 ],
    [ 'ACTIVE_DAY_FEE',   'INT', 'tp.active_day_fee',                1 ],
    [ 'POSTPAID_DAY_FEE', 'INT', 'tp.postpaid_daily_fee',            1 ],
    [ 'MONTH_FEE',        'INT', 'tp.month_fee',                     1 ],
    [ 'COMMENTS',         'STR', 'tp.comments',                      1 ],
    [ 'FEES_METHOD',      'INT', 'tp.fees_method',                   1 ],
    [ 'DAY_TIME_LIMIT',   'INT', 'tp.day_time_limit',                1 ],
    [ 'WEEK_TIME_LIMIT',  'INT', 'tp.week_time_limit',               1 ],
    [ 'MONTH_TIME_LIMIT', 'INT', 'tp.month_time_limit',              1 ],
    [ 'TOTAL_TIME_LIMIT', 'INT', 'tp.total_time_limit',              1 ],
    [ 'DAY_TRAF_LIMIT',   'INT', 'tp.day_traf_limit',                1 ],
    [ 'WEEK_TRAF_LIMIT',  'INT', 'tp.week_traf_limit',               1 ],
    [ 'MONTH_TRAF_LIMIT', 'INT', 'tp.month_traf_limit',              1 ],
    [ 'TOTAL_TRAF_LIMIT', 'INT', 'tp.total_traf_limit',              1 ],
    [ 'OCTETS_DIRECTION', 'INT', 'tp.octets_direction',              1 ],
    [ 'ACTIV_PRICE',      'INT', 'tp.activate_price',                1 ],
    [ 'CHANGE_PRICE',     'INT', 'tp.change_price',                  1 ],
    [ 'CREDIT_TRESSHOLD', 'INT', 'tp.credit_tresshold',              1 ],
    [ 'CREDIT',           'STR', 'tp.credit',                        1 ],
    [ 'PERIOD_ALIGNMENT', 'INT', 'tp.period_alignment',              1 ],
    [ 'DVR',              'INT', 'ctp.dvr',                          1 ],
    [ 'PTZ',              'INT', 'ctp.ptz',                          1 ],
    [ 'NEXT_TARIF_PLAN',  'INT', 'tp.next_tp_id as next_tarif_plan', 1 ],
    [ 'AGE',              'INT', 'tp.age',                           1 ],
    [ 'ARCHIVE',          'INT', 'ctp.archive',                      1 ]
  ];

  if ($attr->{SHOW_ALL_COLUMNS}) {
    map {$attr->{ $_->[0] } = '_SHOW' unless exists $attr->{ $_->[0] }} @$search_columns;
  }

  my $WHERE = $self->search_former($attr, $search_columns, { WHERE => 1 });

  $self->query(
    "SELECT
    $self->{SEARCH_FIELDS} 1
   FROM cams_tp ctp
   LEFT JOIN tarif_plans   tp ON (ctp.tp_id=tp.tp_id)
   LEFT JOIN cams_services s  ON (ctp.service_id=s.id)
    $WHERE ORDER BY $SORT $DESC;",
    undef,
    {
      COLS_NAME => 1,
      %{$attr ? $attr : {}}
    }
  );

  return [] if $self->{errno};

  return $self->{list};
}

#**********************************************************

=head2 tp_info($id)

  Arguments:
    $id - id for tp

  Returns:
    hash_ref

=cut

#**********************************************************
sub tp_info {
  my $self = shift;
  my ($id) = @_;

  my $list = $self->tp_list({ COLS_NAME => 1, ID => $id, SHOW_ALL_COLUMNS => 1, COLS_UPPER => 1 });

  return $list->[0] || {};
}

#**********************************************************

=head2 tp_add($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    1

=cut

#**********************************************************
sub tp_add {
  my $self = shift;
  my ($attr) = @_;

  if (!$attr->{TP_ID}) {
    $attr->{MODULE} = 'Cams';
    $Tariffs->add({ %$attr });

    if (defined($Tariffs->{errno})) {
      $self->{errno} = $Tariffs->{errno};
      return $self;
    }

    $attr->{TP_ID} = $Tariffs->{INSERT_ID};
    $self->{TP_NUM} = $Tariffs->{TP_NUM};
  }

  $self->query("INSERT INTO cams_tp (streams_count, service_id, tp_id)
    VALUES (?, ?, ?);", 'do',
    { Bind => [ $attr->{STREAMS_COUNT}, $attr->{SERVICE_ID}, $attr->{TP_ID} ] }
  );

  $self->{TP_ID} = $attr->{TP_ID};

  return $self->{INSERT_ID};
}

#**********************************************************

=head2 tp_del($attr)

  Arguments:
    $attr - hash_ref

  Returns:
   1

=cut

#**********************************************************
sub tp_del {
  my $self = shift;
  my ($attr) = @_;

  $Tariffs->del($attr->{TP_ID});
  $self->query_del('cams_tp', undef, { TP_ID => $attr->{TP_ID} });

  return 1;
}

#**********************************************************

=head2 tp_change($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    1

=cut

#**********************************************************
sub tp_change {
  my $self = shift;
  my ($attr) = @_;

  $Tariffs->change($attr->{TP_ID}, { %$attr });
  if (defined($Tariffs->{errno})) {
    $self->{errno} = $Tariffs->{errno};
    return $self;
  }

  $self->changes(
    {
      CHANGE_PARAM => 'TP_ID',
      TABLE        => 'cams_tp',
      DATA         => $attr
    }
  );

  return $self;
}

#**********************************************************
=head2 streams_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut

#**********************************************************
sub streams_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 'g.service_id';
  $DESC = ($attr->{DESC}) ? '' : 'DESC';
  $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : "65000";

  my $search_columns = [
    [ 'ID',                 'INT', 'cs.id',                                                                                1 ],
    [ 'UID',                'INT', 'cs.uid',                                                                               1 ],
    [ 'USER_LOGIN',         'STR', 'u.id AS user_login',                                                                   1 ],
    [ 'DISABLED',           'INT', 'cs.disabled',                                                                          1 ],
    [ 'NAME',               'STR', 'cs.name',                                                                              1 ],
    [ 'TITLE',              'STR', 'cs.title',                                                                             1 ],
    [ 'HOST',               'STR', 'cs.host',                                                                              1 ],
    [ 'LOGIN',              'STR', 'cs.login',                                                                             1 ],
    [ 'PASSWORD',           'STR', 'DECODE(cs.password, "' . $self->{conf}{secretkey} . '") as password',                  1 ],
    [ 'RTSP_PORT',          'INT', 'cs.rtsp_port',                                                                         1 ],
    [ 'RTSP_PATH',          'STR', 'cs.rtsp_path',                                                                         1 ],
    [ 'NAME_HASH',          'STR', qq{CONCAT (MD5( CONCAT (cs.host, cs.login, cs.password) ), '__', cs.id ) AS name_hash}, 1 ],
    [ 'ORIENTATION',        'INT', 'cs.orientation',                                                                       1 ],
    [ 'TYPE',               'INT', 'cs.type',                                                                              1 ],
    [ 'GROUP_ID',           'INT', 'cs.group_id',                                                                          1 ],
    [ 'GROUP_NAME',         'STR', 'g.name as group_name',                                                                 1 ],
    [ 'SERVICE_ID',         'INT', 'g.service_id',                                                                         1 ],
    [ 'SERVICE_MODULE',     'STR', 's.module',                                                                             1 ],
    [ 'SERVICE_NAME',       'STR', 's.name as service_name',                                                               1 ],
    [ 'EXTRA_URL',          'STR', 'cs.extra_url',                                                                         1 ],
    [ 'SCREENSHOT_URL',     'STR', 'cs.screenshot_url',                                                                    1 ],
    [ 'PRE_IMAGE_URL',      'STR', 'cs.pre_image_url',                                                                     1 ],
    [ 'LIMIT_ARCHIVE',      'INT', 'cs.limit_archive',                                                                     1 ],
    [ 'ARCHIVE',            'INT', 'cs.archive',                                                                           1 ],
    [ 'PRE_IMAGE',          'INT', 'cs.pre_image',                                                                         1 ],
    [ 'TRANSPORT',          'INT', 'cs.transport',                                                                         1 ],
    [ 'CONSTANTLY_WORKING', 'INT', 'cs.constantly_working',                                                                1 ],
    [ 'ONLY_VIDEO',         'INT', 'cs.only_video',                                                                        1 ],
    [ 'POINT_ID',           'INT', 'cs.point_id',                                                                          1 ],
    [ 'POINT_CREATED',      'STR', 'mp.created AS point_created',                                                          1 ],
    [ 'LENGTH',             'INT', 'cs.length',                                                                            1 ],
    [ 'ANGEL',              'INT', 'cs.angel',                                                                             1 ],
    [ 'LOCATION_ANGEL',     'INT', 'cs.location_angel',                                                                    1 ],
    [ 'NUMBER_ID',          'STR', 'cs.number_id',                                                                         1 ],
    [ 'FOLDER_ID',          'INT', 'cs.folder_id',                                                                         1 ],
    [ 'FOLDER_NAME',        'STR', 'f.title as folder_name',                                                               1 ],
    [ 'SERVICE_ID_FOLDER',  'INT', 'f.service_id as service_id_folder',                                                    1 ],
  ];

  if ($attr->{SHOW_ALL_COLUMNS}) {
    map {$attr->{ $_->[0] } = '_SHOW' unless (exists $attr->{ $_->[0] })} @{$search_columns};
  }

  my $WHERE = $self->search_former($attr, $search_columns, { WHERE => 1 });

  my $EXTRA_JOIN = "LEFT JOIN cams_services s ON (f.service_id=s.id OR g.service_id=s.id)";
  $EXTRA_JOIN .= "\n LEFT JOIN maps_points mp ON (cs.point_id=mp.id)" if $self->{SEARCH_FIELDS} =~ /mp\./;

  $self->query(
    "SELECT $self->{SEARCH_FIELDS} cs.id, cs.coordx, cs.coordy
   FROM cams_streams cs
   LEFT JOIN users u       ON (cs.uid=u.uid)
   LEFT JOIN cams_groups g ON (cs.group_id=g.id)
   LEFT JOIN cams_folder f ON (cs.folder_id=f.id)
   $EXTRA_JOIN
   $WHERE ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    {
      COLS_NAME  => 1,
      COLS_UPPER => 1,
      %{$attr ? $attr : {}}
    }
  );

  return [] if ($self->{errno});

  return $self->{list};
}

#**********************************************************

=head2 stream_info($id)

  Arguments:
    $id - id for streams

  Returns:
    hash_ref

=cut

#**********************************************************
sub stream_info {
  my $self = shift;
  my ($id) = @_;

  my $list = $self->streams_list({
    COLS_NAME        => 1,
    ID               => $id,
    SHOW_ALL_COLUMNS => 1,
    COLS_UPPER       => 1
  });

  return $list->[0] || {};
}

#**********************************************************

=head2 stream_add($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    1

=cut

#**********************************************************
sub stream_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('cams_streams', {
    %{$attr ? $attr : {}},
    PASSWORD => ($attr->{PASSWORD}) ? "ENCODE('$attr->{PASSWORD}', '$self->{conf}->{secretkey}')" : ''
  });

  return undef if $self->{errno};

  $admin->{MODULE} = $MODULE;
  my @info = ('NAME', 'TITLE');
  my @actions_history = ();

  foreach my $param (@info) {
    if (defined($attr->{$param})) {
      push @actions_history, $param . ":" . $attr->{$param};
    }
  }

  $admin->action_add(0, "CAMERA: ID: $self->{INSERT_ID} ".  join(', ', @actions_history), { TYPE => 1 } );

  return $self->{INSERT_ID};
}

#**********************************************************

=head2 stream_del($attr)

  Arguments:
    $attr - hash_ref

  Returns:
   1

=cut

#**********************************************************
sub stream_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('cams_streams', $attr);

  $admin->{MODULE} = $MODULE;

  my @del_descr = ("CAMERA: ");
  push @del_descr, "ID: $attr->{ID}" if $attr->{ID};
  push @del_descr, "COMMENTS: $attr->{COMMENTS}" if $attr->{COMMENTS};

  $admin->action_add(0, join(' ', @del_descr), { TYPE => 10 });

  return 1;
}

#**********************************************************

=head2 stream_change($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    1

=cut

#**********************************************************
sub stream_change {
  my $self = shift;
  my ($attr) = @_;

  $attr->{USER_PORTAL} //= 0;
  $attr->{DISABLE} //= 0;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'cams_streams',
    DATA         => $attr
  });

  return $self;
}


#**********************************************************
=head2 services_list($attr) - list of tp services

  Arguments:
    $attr

=cut
#**********************************************************
sub services_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  my $WHERE = $self->search_former(
    $attr,
    [
      [ 'NAME',                'STR', 'name',                                                1 ],
      [ 'MODULE',              'STR', 'module',                                              1 ],
      [ 'STATUS',              'INT', 'status',                                              1 ],
      [ 'COMMENT',             'STR', 'comment',                                             1 ],
      [ 'PROVIDER_PORTAL_URL', 'STR', 'provider_portal_url',                                 1 ],
      [ 'USER_PORTAL',         'INT', 'user_portal',                                         1 ],
      [ 'DEBUG',               'INT', 'debug',                                               1 ],
      [ 'LOGIN',               'INT', 'login',                                               1 ],
      [ 'PASSWORD',            'INT', '', "DECODE(password, '$CONF->{secretkey}') AS password" ],
    ],
    {
      WHERE => 1,
    }
  );

  $self->query("SELECT $self->{SEARCH_FIELDS} s.id
   FROM cams_services s
    $WHERE
    GROUP BY s.id
    ORDER BY $SORT $DESC",
    undef,
    $attr
  );

  my $list = $self->{list} || [];

  return $list;
}

#**********************************************************
=head2 screen_add($attr)

=cut
#**********************************************************
sub services_add {
  my $self = shift;
  my ($attr) = @_;

  if ($attr->{PASSWORD}) {
    $attr->{PASSWORD} = "ENCODE('$attr->{PASSWORD}', '$self->{conf}->{secretkey}')",
  }

  $self->query_add('cams_services', $attr);

  return $self;
}

#**********************************************************
=head2 screen_change($attr)

=cut
#**********************************************************
sub services_change {
  my $self = shift;
  my ($attr) = @_;

  $attr->{USER_PORTAL} //= 0;
  $attr->{DISABLE} //= 0;

  $self->changes(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'cams_services',
      DATA         => $attr
    }
  );

  return $self;
}

#**********************************************************
=head2 screen_del($id, $attr)

=cut
#**********************************************************
sub services_del {
  my $self = shift;
  my ($id, $attr) = @_;

  $self->query_del('cams_services', $attr, { ID => $id });

  return $self;
}

#**********************************************************
=head2 services_info($id)

  Arguments:
    $id  - Service ID

=cut
#**********************************************************
sub services_info {
  my $self = shift;
  my ($id) = @_;

  $self->query("SELECT cams_services.*, DECODE(password, '$CONF->{secretkey}') AS password
    FROM cams_services
    WHERE id= ? ;",
    undef,
    {
      INFO => 1,
      Bind => [ $id ]
    }
  );

  return $self;
}

#**********************************************************
=head2 group_list($attr) - list of tp group

  Arguments:
    $attr

=cut
#**********************************************************
sub group_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  my $WHERE = $self->search_former(
    $attr,
    [
      [ 'NAME',         'STR', 'g.name',                 1 ],
      [ 'LOCATION_ID',  'INT', 'g.location_id',          1 ],
      [ 'DISTRICT_ID',  'INT', 'g.district_id',          1 ],
      [ 'STREET_ID',    'INT', 'g.street_id',            1 ],
      [ 'BUILD_ID',     'INT', 'g.build_id',             1 ],
      [ 'SERVICE_ID',   'INT', 'g.service_id',           1 ],
      [ 'SERVICE_NAME', 'INT', 's.name as service_name', 1 ],
      [ 'MAX_USERS',    'INT', 'g.max_users',            1 ],
      [ 'MAX_CAMERAS',  'INT', 'g.max_cameras',          1 ],
      [ 'COMMENT',      'STR', 'g.comment',              1 ],
      [ 'SUBGROUP_ID',  'STR', 'g.subgroup_id',          1 ],
    ],
    {
      WHERE       => 1,
      WHERE_RULES => $attr->{WHERE_RULES} && ref $attr->{WHERE_RULES} eq 'ARRAY' ? $attr->{WHERE_RULES} : []
    }
  );

  $self->query("SELECT $self->{SEARCH_FIELDS} g.id
   FROM cams_groups g
   LEFT JOIN cams_services s ON(g.service_id=s.id)
    $WHERE
    GROUP BY g.id
    ORDER BY $SORT $DESC",
    undef,
    $attr
  );

  my $list = $self->{list} || [];

  return $list;
}

#**********************************************************
=head2 group_add($attr)

=cut
#**********************************************************
sub group_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('cams_groups', $attr);

  return $self;
}

#**********************************************************
=head2 group_change($attr)

=cut
#**********************************************************
sub group_change {
  my $self = shift;
  my ($attr) = @_;

  $attr->{USER_PORTAL} //= 0;
  $attr->{DISABLE} //= 0;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'cams_groups',
    DATA         => $attr
  });

  return $self;
}

#**********************************************************
=head2 group_del($id, $attr)

=cut
#**********************************************************
sub group_del {
  my $self = shift;
  my ($id, $attr) = @_;

  $self->query_del('cams_groups', $attr, { ID => $id });

  return $self;
}

#**********************************************************
=head2 group_info($id)

  Arguments:
    $id  - Group ID

=cut
#**********************************************************
sub group_info {
  my $self = shift;
  my ($id) = @_;

  $self->query("SELECT * FROM cams_groups WHERE id= ? ;", undef, { INFO => 1, Bind => [ $id ] });

  return $self;
}

#**********************************************************
=head2 access_group_list($id)

  Arguments:
    $id  - Group ID

=cut
#**********************************************************
sub access_group_list {
  my $self = shift;
  my ($attr) = @_;

  my @WHERE_RULES = ();

  push @WHERE_RULES, "(g.location_id=$attr->{LOCATION_ID})" if $attr->{LOCATION_ID};
  push @WHERE_RULES, "(g.location_id=0 AND g.street_id=$attr->{STREET_ID})" if $attr->{STREET_ID};
  push @WHERE_RULES, "(g.location_id=0 AND g.street_id=0 AND g.district_id=$attr->{DISTRICT_ID})" if $attr->{DISTRICT_ID};
  push @WHERE_RULES, "(g.location_id=0 AND g.street_id=0 AND g.district_id=0)";

  return $self->group_list({
    NAME        => $attr->{NAME} || '_SHOW',
    BUILD_ID    => '_SHOW',
    STREET_ID   => '_SHOW',
    BUILD_ID    => '_SHOW',
    DISTRICT_ID => '_SHOW',
    SERVICE_ID  => $attr->{SERVICE_ID},
    COMMENT     => '_SHOW',
    WHERE_RULES => [ "(" . join(' OR ', @WHERE_RULES) . ")" ],
    COLS_NAME   => 1,
  });
}

#**********************************************************
=head2 access_group_list($id)

  Arguments:
    $id  - Group ID

=cut
#**********************************************************
sub access_folder_list {
  my $self = shift;
  my ($attr) = @_;

  my @WHERE_RULES = ();

  push @WHERE_RULES, "(f.location_id=$attr->{LOCATION_ID})" if $attr->{LOCATION_ID};
  push @WHERE_RULES, "(f.location_id=0 AND f.street_id=$attr->{STREET_ID})" if $attr->{STREET_ID};
  push @WHERE_RULES, "(f.location_id=0 AND f.street_id=0 AND f.district_id=$attr->{DISTRICT_ID})" if $attr->{DISTRICT_ID};
  push @WHERE_RULES, "(f.location_id=0 AND f.street_id=0 AND f.district_id=0)";

  return $self->folder_list({
    ID          => '_SHOW',
    TITLE       => '_SHOW',
    DISTRICT_ID => '_SHOW',
    STREET_ID   => '_SHOW',
    LOCATION_ID => '_SHOW',
    BUILD_ID    => '_SHOW',
    SERVICE_ID  => $attr->{SERVICE_ID},
    GROUP_ID    => $attr->{GROUP_ID} || '_SHOW',
    PARENT_ID   => $attr->{PARENT_ID} || '_SHOW',
    COMMENT     => '_SHOW',
    PARENT_NAME => '_SHOW',
    WHERE_RULES => [ "(" . join(' OR ', @WHERE_RULES) . ")" ],
    UID         => $attr->{UID} ? "0;$attr->{UID}" : '_SHOW',
    COLS_NAME   => 1,
  });
}

#**********************************************************
=head2 user_groups($attr) - Users groups

  Arguments:
    $attr
      IDS
      ID
      TP_ID

  Results:
    Objects

=cut
#**********************************************************
sub user_groups {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('cams_users_groups', $attr);

  return $self if !$attr->{IDS};

  my @ids = split(/,\s?/, $attr->{IDS});

  my @MULTI_QUERY = ();

  foreach my $id (@ids) {
    push @MULTI_QUERY, [ $attr->{ID}, $attr->{TP_ID}, $id ];
  }

  $self->query(
    "INSERT INTO cams_users_groups
     (id, tp_id, group_id, changed)
        VALUES (?, ?, ?, NOW());",
    undef,
    { MULTI_QUERY => \@MULTI_QUERY }
  );

  $admin->{MODULE} = $MODULE;
  $admin->action_add($attr->{UID}, "GROUPS: $attr->{IDS}", { TYPE => 2 } );

  return $self;
}

#**********************************************************
=head2 user_groups_list($attr)

  Arguments:
    $attr
      TP_ID  - TP_ID
      ID     - Service ID

=cut
#**********************************************************
sub user_groups_list {
  my $self = shift;
  my ($attr) = @_;

  $self->query(
    "SELECT tp_id, group_id, changed
     FROM cams_users_groups
     WHERE tp_id= ? AND id = ?;",
    undef,
    { %{$attr}, Bind => [ $attr->{TP_ID}, $attr->{ID} ] }
  );

  $self->{USER_GROUPS} = $self->{TOTAL};

  return $self->{list};
}

#**********************************************************
=head2 users_group_count($attr)

  Arguments:
    $attr

=cut
#**********************************************************
sub users_group_count {
  my $self = shift;
  my ($attr) = @_;

  $self->query("SELECT COUNT(*)
     FROM cams_users_groups
     WHERE group_id = ?;",
    undef,
    { %{$attr}, Bind => [ $attr->{GROUP_ID} ] }
  );

  return $self->{list}[0][0];
}

#**********************************************************
=head2 user_folders($attr) - Users folders

  Arguments:
    $attr
      IDS
      ID
      TP_ID

  Results:
    Objects

=cut
#**********************************************************
sub user_folders {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('cams_users_folders', $attr);

  return $self if !$attr->{IDS};

  my @ids = split(/,\s?/, $attr->{IDS});

  my @MULTI_QUERY = ();

  foreach my $id (@ids) {
    push @MULTI_QUERY, [ $attr->{ID}, $attr->{TP_ID}, $id ];
  }

  $self->query("INSERT INTO cams_users_folders (id, tp_id, folder_id, changed) VALUES (?, ?, ?, NOW());",
    undef, { MULTI_QUERY => \@MULTI_QUERY });

  $admin->{MODULE} = $MODULE;
  $admin->action_add($attr->{UID}, "FOLDERS: $attr->{IDS}", { TYPE => 2 } );
  
  return $self;
}

#**********************************************************
=head2 user_folders_list($attr)

  Arguments:
    $attr
      TP_ID  - TP_ID
      ID     - Service ID

=cut
#**********************************************************
sub user_folders_list {
  my $self = shift;
  my ($attr) = @_;

  if ($attr->{SKIP_PRIVATE_CAMERAS}) {
    $self->query(
      "SELECT cuf.tp_id, cuf.folder_id, cuf.changed
     FROM cams_users_folders cuf
     LEFT JOIN cams_folder cf ON (cf.id = cuf.folder_id)
     WHERE cuf.tp_id= ? AND cuf.id = ? AND cf.uid = '';",
      undef,
      { %{$attr}, Bind => [ $attr->{TP_ID}, $attr->{ID} ] }
    );
  }
  else {
    $self->query(
      "SELECT tp_id, folder_id, changed
     FROM cams_users_folders
     WHERE tp_id= ? AND id = ?;",
      undef,
      { %{$attr}, Bind => [ $attr->{TP_ID}, $attr->{ID} ] }
    );
  }

  $self->{USER_FOLDERS} = $self->{TOTAL};

  return $self->{list};
}

#**********************************************************
=head2 users_group_count($attr)

  Arguments:
    $attr

=cut
#**********************************************************
sub users_folder_count {
  my $self = shift;
  my ($attr) = @_;

  $self->query(
    "SELECT COUNT(*)
     FROM cams_users_folders
     WHERE folder_id = ?;",
    undef,
    { %{$attr}, Bind => [ $attr->{FOLDER_ID} ] }
  );

  return $self->{list}[0][0];
}

#**********************************************************
=head2 user_cameras($attr) - Users cameras

  Arguments:
    $attr
      IDS
      ID
      TP_ID

  Results:
    Objects

=cut
#**********************************************************
sub user_cameras {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('cams_users_cameras', $attr);

  return $self if !$attr->{IDS};

  my @ids = split(/,\s?/, $attr->{IDS});

  my @MULTI_QUERY = ();

  foreach my $id (@ids) {
    push @MULTI_QUERY, [ $attr->{TP_ID}, $attr->{ID}, $id ];
  }

  $self->query(
    "INSERT INTO cams_users_cameras
     (tp_id, id, camera_id, changed)
        VALUES (?, ?, ?, NOW());",
    undef,
    { MULTI_QUERY => \@MULTI_QUERY }
  );

  return $self;
}

#**********************************************************
=head2 user_cameras_list($attr)

  Arguments:
    $attr
      TP_ID  - TP_ID
      ID     - Service ID

=cut
#**********************************************************
sub user_cameras_list {
  my $self = shift;
  my ($attr) = @_;

  my $WHERE = $self->search_former($attr,[
    [ 'ID',        'INT', 'uc.id',        1 ],
    [ 'TP_ID',     'INT', 'uc.tp_id',     1 ],
    [ 'CAMERA_ID', 'INT', 'uc.camera_id', 1 ]
  ], { WHERE => 1 });

  $self->query("SELECT uc.tp_id, uc.id, uc.camera_id, uc.changed, c.name as camera_name, c.title,
      s.name as service_name, s.id as service_id, c.number_id as number
    FROM cams_users_cameras uc
    LEFT JOIN cams_tp t ON (uc.tp_id=t.tp_id)
    LEFT JOIN cams_streams c ON (uc.camera_id=c.id)
    LEFT JOIN cams_services s ON (s.id=t.service_id)
    $WHERE",
    undef,
    $attr
  );

  $self->{USER_CAMERAS} = $self->{TOTAL};

  return $self->{list} || [];
}

#**********************************************************
=head2 user_total_cameras($attr)

  Arguments:
    $uid

=cut
#**********************************************************
sub user_total_cameras {
  my $self = shift;
  my $uid = shift;

  return 0 if !$uid;

  $self->query("SELECT COUNT(c.id) AS total FROM cams_users_cameras uc
    LEFT JOIN cams_main c ON (uc.id = c.id AND c.tp_id = uc.tp_id)
    WHERE c.uid = ?;", undef, { INFO => 1, Bind => [ $uid ] }
  );

  return $self;
}

#**********************************************************
=head2 folder_list($attr)

  Arguments:
    $attr

=cut
#**********************************************************
sub folder_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  my $WHERE = $self->search_former($attr, [
    [ 'ID',           'INT', 'f.id',                    1 ],
    [ 'TITLE',        'STR', 'f.title',                 1 ],
    [ 'PARENT_ID',    'INT', 'f.parent_id',             1 ],
    [ 'GROUP_ID',     'INT', 'f.group_id',              1 ],
    [ 'GROUP_NAME',   'STR', 'g.name as group_name',    1 ],
    [ 'SERVICE_ID',   'INT', 'f.service_id',            1 ],
    [ 'SERVICE_NAME', 'STR', 's.name as service_name',  1 ],
    [ 'COMMENT',      'STR', 'f.comment',               1 ],
    [ 'PARENT_NAME',  'STR', 'fd.title as parent_name', 1 ],
    [ 'LOCATION_ID',  'INT', 'f.location_id',           1 ],
    [ 'DISTRICT_ID',  'INT', 'f.district_id',           1 ],
    [ 'STREET_ID',    'INT', 'f.street_id',             1 ],
    [ 'BUILD_ID',     'INT', 'f.build_id',              1 ],
    [ 'UID',          'INT', 'f.uid',                   1 ],
    [ 'SUBFOLDER_ID', 'STR', 'f.subfolder_id',          1 ],
  ], {
    WHERE       => 1,
    WHERE_RULES => $attr->{WHERE_RULES} && ref $attr->{WHERE_RULES} eq 'ARRAY' ? $attr->{WHERE_RULES} : []
  });

  $self->query("SELECT $self->{SEARCH_FIELDS} f.title
   FROM cams_folder f
   LEFT JOIN cams_groups g   ON(g.id=f.group_id)
   LEFT JOIN cams_folder fd  ON(f.parent_id=fd.id)
   LEFT JOIN cams_services s ON(f.service_id=s.id)
    $WHERE
    GROUP BY f.id
    ORDER BY $SORT $DESC",
    undef,
    $attr
  );

  my $list = $self->{list} || [];

  return $list;
}

#**********************************************************
=head2 folder_add($attr)

=cut
#**********************************************************
sub folder_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('cams_folder', $attr);

  return $self;
}

#**********************************************************
=head2 folder_change($attr)

=cut
#**********************************************************
sub folder_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'cams_folder',
    DATA         => $attr
  });

  return $self;
}

#**********************************************************
=head2 group_del($id, $attr)

=cut
#**********************************************************
sub folder_del {
  my $self = shift;
  my ($id, $attr) = @_;

  $self->query_del('cams_folder', $attr, { ID => $id });
  $self->query_del('cams_folder', $attr, { PARENT_ID => $id });

  return $self;
}

#**********************************************************
=head2 folder_info($id)

  Arguments:
    $id  - Folder ID

=cut
#**********************************************************
sub folder_info {
  my $self = shift;
  my ($id) = @_;

  $self->query("SELECT f.*, g.name as group_name, f.service_id as service_id, s.name as service_name, g.subgroup_id as subgroup_id
    FROM cams_folder f
    LEFT JOIN cams_groups g   ON(g.id=f.group_id)
    LEFT JOIN cams_services s ON(f.service_id=s.id)
    WHERE f.id= ? ;",
    undef,
    {
      INFO => 1,
      Bind => [ $id ]
    }
  );

  return $self;
}

#**********************************************************
=head2 model_list($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub model_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  my $WHERE = $self->search_former($attr,
    [
      [ 'MODEL_NAME',   'STR', 'em.model_name AS model_name',                          1 ],
      [ 'MODEL_ID',     'INT', 'em.model_id AS model_id',                              1 ],
      [ 'VENDOR_NAME',  'STR', 'ev.name AS vendor_name',                               1 ],
      [ 'VENDOR_ID',    'INT', 'ev.id AS vendor_id',                                   1 ],
      [ 'TYPE_NAME',    'STR', 'et.name AS type_name',                                 1 ],
      [ 'TYPE_ID',      'INT', 'et.id AS type_id',                                     1 ],
      [ 'VENDOR_MODEL', 'STR', 'CONCAT(ev.name, ": ", em.model_name) AS vendor_model', 1 ],
    ],
    { WHERE => 1, }
  );

  $self->query("SELECT $self->{SEARCH_FIELDS} em.id
    FROM equipment_models em
    INNER JOIN equipment_types et ON (em.type_id=et.id)
    INNER JOIN equipment_vendors ev ON (ev.id=em.vendor_id)
    $WHERE
    ORDER BY $SORT $DESC",
    undef,
    $attr
  );

  return $self->{list} || [];
}

1;