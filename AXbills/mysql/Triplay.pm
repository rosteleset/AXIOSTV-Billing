=head1 3play

3play - module for connecting Internet, IPTV and VOIP tarifs in one


  VERSION: 8.04
  UPDATED: 20211201

=head1 Synopsis

use Triplay;

my $triplay = Triplay->new($db, $admin, \%conf);

=cut

package Triplay;

use strict;

use parent 'dbcore';
use Tariffs;

our $VERSION = 8.04;
my ($admin, $CONF);
my $MODULE = 'Triplay';

#*******************************************************************

=head2 function new() - initialize Triplay object

  Arguments:
    $db    -
    $admin -
    %conf  -
  Returns:
    $self object

  Examples:
    $Triplay = Triplay->new($db, $admin, \%conf);

=cut

#*******************************************************************
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

  return $self;
}

#*******************************************************************
=head2 function add_tp() - adding new Triplay tariff plan

	Arguments:
    %$attr
      NAME        - tp's name;
      INTERNET_TP - DV tp's id;
      IPTV_TP     - IPTV tp's id;
      VOIP_TP     - VOIP tp's id;
      COMMENT     - tp's description;

	Returns:
    $self object;

	Examples:
    $Triplay->add_tp({
      NAME        => $FORM{NAME},
      INTERNET_TP => $FORM{INTERNET_TP},
      VOIP_TP     => $FORM{VOIP_TP},
      IPTV_TP     => $FORM{IPTV_TP},
      COMMENT     => $FORM{COMMENT}
    });



=cut
#*******************************************************************
sub tp_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('triplay_tps', {%$attr});

  return $self;
}


#**********************************************************
=head2 change_tp($attr) - change Triplay tariff plan

  Arguments:
    %$attr
      NAME        - tp's name;
      INTERNET_TP - DV tp's id;
      IPTV_TP     - IPTV tp's id;
      VOIP_TP     - VOIP tp's id;
      COMMENT     - tp's description;

  Returns:
    $self object;

  Examples:
    $Triplay->change_tp({
                        ID => $FORM{id},
                        %FORM
    });

=cut
#**********************************************************
sub tp_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'triplay_tps',
    DATA         => $attr
  });

  if ($attr->{ID}) {
    my $Tariffs = Tariffs->new($self->{db}, $self->{conf}, $self->{admin});
    $self->{TP_INFO} = $Tariffs->info(0, {
      TP_ID     => $self->{TP_ID},
      DOMAIN_ID => $admin->{DOMAIN_ID} || undef
    });

    $self->tp_info({ ID => $attr->{ID} });
  }

  return $self;
}

#**********************************************************
=head2 del_tp($attr) - delete Triplay tariff plan

  Arguments:
    ID   - tp's ID;

  Returns:
    $self object;

  Examples:
    $Triplay->del_tp({ID => $FORM{del}});

=cut
#**********************************************************
sub tp_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('triplay_tps', $attr);

  return $self;
}

#**********************************************************
=head2 info_tp($attr) - get information about Triplay tariff

  Arguments:
    ID      - tp's ID

  Returns:

  Examples:
    $tp_info = $Triplay->info_tp({COLS_NAME => 1, ID => 1});

=cut
#**********************************************************
sub tp_info {
  my $self = shift;
  my ($attr) = @_;

  my $WHERE = '';
  if ($attr->{TP_ID}) {
    $WHERE = " tt.tp_id='$attr->{TP_ID}'";
  }
  else {
    $WHERE = " tt.id='$attr->{ID}'";
  }

  $self->query("SELECT tt.id AS triplay_tp_id,
    tt.name,
    (SELECT name FROM  tarif_plans tp WHERE tp.tp_id=tt.internet_tp) AS internet_name,
    (SELECT name FROM  tarif_plans tp WHERE tp.tp_id=tt.iptv_tp) AS iptv_name,
    (SELECT name FROM  tarif_plans tp WHERE tp.tp_id=tt.voip_tp) AS voip_name,
    tt.comment,
    tt.internet_tp,
    tt.voip_tp,
    tt.iptv_tp,
    tp.*
    FROM tarif_plans tp
    INNER JOIN triplay_tps AS tt ON (tt.tp_id=tp.tp_id)
    WHERE tp.tp_id=tt.tp_id
      AND $WHERE;",
      undef,
      { INFO => 1 }
    );

  return $self;
}

#**********************************************************
=head2 list_tp($attr) - return list of tariff plans

  Arguments:


  Returns:
    $self object;

  Examples:
    my $tp_list = $Triplay->list_tp({COLS_NAME => 1});

=cut
#**********************************************************
sub tp_list {
  my $self = shift;
  my ($attr) = @_;

  delete $self->{COL_NAMES_ARR};

  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  my $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my @search_columns = (
    [ 'TP_ID',               'INT', 'tp.id',                         ],
    [ 'NAME',                'STR', 'tp.name',                       ],
    [ 'TIME_TARIFS',         'INT', '', "IF(SUM(i.tarif) is NULL or sum(i.tarif)=0, 0, 1) AS time_tarifs" ],
    [ 'TRAF_TARIFS',         'INT', '', "IF(SUM(tt.in_price + tt.out_price)> 0, 1, 0) AS traf_tarifs"     ],
    [ 'TP_GID',              'INT', 'tp.gid AS tp_gid',            1 ],
    [ 'TP_GROUP_NAME',       'STR', 'tp_g.name', 'tp_g.name AS tp_group_name'],
    [ 'UPLIMIT',             'INT', 'tp.uplimit',                  1 ],
    [ 'LOGINS',              'INT', 'tp.logins',                   1 ],
    [ 'DAY_FEE',             'INT', 'tp.day_fee',                  1 ],
    [ 'ACTIVE_DAY_FEE',      'INT', 'tp.active_day_fee',           1 ],
    [ 'POSTPAID_DAY_FEE',    'INT', 'tp.postpaid_daily_fee',       1 ],
    [ 'POSTPAID_DAILY_FEE',    'INT', 'tp.postpaid_daily_fee',     1 ],
    [ 'MONTH_FEE',           'INT', 'tp.month_fee',                1 ],
    [ 'POSTPAID_MONTH_FEE',  'INT', 'tp.postpaid_monthly_fee',     1 ],
    [ 'POSTPAID_MONTHLY_FEE',  'INT', 'tp.postpaid_monthly_fee',   1 ],
    [ 'PERIOD_ALIGNMENT',    'INT', 'tp.period_alignment',         1 ],
    [ 'ABON_DISTRIBUTION',   'INT', 'tp.abon_distribution',        1 ],
    [ 'FIXED_FEES_DAY',      'INT', 'tp.fixed_fees_day',           1 ],
    [ 'SMALL_DEPOSIT_ACTION','INT', 'tp.small_deposit_action',     1 ],
    [ 'REDUCTION_FEE',       'INT', 'tp.reduction_fee',            1 ],
    [ 'FEES_METHOD',         'INT', 'tp.fees_method',              1 ],
    [ 'DAY_TIME_LIMIT',      'INT', 'tp.day_time_limit',           1 ],
    [ 'WEEK_TIME_LIMIT',     'INT', 'tp.week_time_limit',          1 ],
    [ 'MONTH_TIME_LIMIT',    'INT', 'tp.month_time_limit',         1 ],
    [ 'TOTAL_TIME_LIMIT',    'INT', 'tp.total_time_limit',         1 ],
    [ 'DAY_TRAF_LIMIT',      'INT', 'tp.day_traf_limit',           1 ],
    [ 'WEEK_TRAF_LIMIT',     'INT', 'tp.week_traf_limit',          1 ],
    [ 'MONTH_TRAF_LIMIT',    'INT', 'tp.month_traf_limit',         1 ],
    [ 'TOTAL_TRAF_LIMIT',    'INT', 'tp.total_traf_limit',         1 ],
    [ 'OCTETS_DIRECTION',    'INT', 'tp.octets_direction',         1 ],
    [ 'ACTIV_PRICE',         'INT', 'tp.activate_price',           1 ],
    [ 'CHANGE_PRICE',        'INT', 'tp.change_price',             1 ],
    [ 'CREDIT_TRESSHOLD',    'INT', 'tp.credit_tresshold',         1 ],
    [ 'CREDIT',              'STR', 'tp.credit',                   1 ],
    [ 'USER_CREDIT_LIMIT',   'STR', 'tp.user_credit_limit',        1 ],
    [ 'MAX_SESSION_DURATION','INT', 'tp.max_session_duration',     1 ],
    [ 'FILTER_ID',           'STR', 'tp.filter_id',                1 ],
    [ 'AGE',                 'INT', 'tp.age',                      1 ],
    [ 'PAYMENT_TYPE',        'INT', 'tp.payment_type',             1 ],
    [ 'MIN_SESSION_COST',    'STR', 'min_session_cost',            1 ],
    [ 'MIN_USE',             'INT', 'tp.min_use',                  1 ],
    [ 'TRAFFIC_TRANSFER_PERIOD','INT','traffic_transfer_period',   1 ],
    [ 'NEG_DEPOSIT_FILTER_ID','STR',  'tp.neg_deposit_filter_id',  1 ],
    [ 'NEG_DEPOSIT_IPPOOL',  'STR', 'tp.neg_deposit_ippool',       1 ],
    [ 'PRIORITY',            'INT', 'tp.priority',                 1 ],
    [ 'FINE',                'INT', 'tp.fine',                     1 ],
    [ 'NEXT_TARIF_PLAN',     'INT', 'tp.next_tp_id',               1 ],
    [ 'RAD_PAIRS',           'STR', 'tp.rad_pairs',                1 ],
    [ 'COMMENTS',            'STR', 'tp.comments',                 1 ],
    [ 'DOMAIN_ID',           'INT', 'tp.domain_id',                1 ],
    [ 'EXT_BILL_ACCOUNT',    'INT', 'tp.ext_bill_account',         1 ],
    [ 'INNER_TP_ID',         'INT', 'tp.tp_id',                    1 ],
    [ 'TP_ID_',              'INT', 'tp.tp_id', 'tp.tp_id AS tp_id_' ],
    [ 'MODULE',              'STR', 'tp.module',                   1 ],
    [ 'SERVICE_ID',          'INT', 'tp.service_id',               1 ],
    [ 'SERVICE_NAME',        'INT', 'tp.service_id', 'tp.service_id AS service_name' ],
    [ 'INTERVALS',           'INT', 'ti.id',   'COUNT(i.id) AS intervals' ],
    [ 'STATUS',              'INT', 'tp.status',                   1 ],
    [ 'DESCRIBE_AID',        'STR', 'tp.describe_aid',             1 ],
    [ 'IPPOOL',              'STR', 'tp.ippool',                   1 ],
  );

  my $WHERE =  $self->search_former($attr, \@search_columns, {
    WHERE => 1,
    #WHERE_RULES => \@WHERE_RULES
  });

  $self->query(
    "SELECT
    tt.id,
    tt.name,
    (SELECT name FROM  tarif_plans tp WHERE tp.tp_id=tt.internet_tp) as internet_name,
    (SELECT name FROM  tarif_plans tp WHERE tp.tp_id=tt.voip_tp) as voip_name,
    (SELECT name FROM  tarif_plans tp WHERE tp.tp_id=tt.iptv_tp) as iptv_name,
    $self->{SEARCH_FIELDS}
    tt.comment,
    tp.tp_id
    FROM tarif_plans tp
    INNER JOIN triplay_tps AS tt ON (tt.tp_id=tp.tp_id)
    $WHERE
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list};

  return $self->{list} if ($self->{TOTAL} < 1);

  $self->query(
    "SELECT COUNT(*) AS total
     FROM triplay_tps",
    undef,
    { INFO => 1 }
  );

  return $list;
}

#**********************************************************
=head2 user_add($attr) - add user

  Arguments:
    %$attr
      UID   - user's ID
      TP_ID - tariff plan ID

  Returns:
    $self object

  Examples:
    $Triplay->add_user({
      UID     => $FORM{UID},
      TP_ID   => $FORM{TRIPLAY_TP}
    });

=cut
#**********************************************************
sub user_add {
  my $self = shift;
  my ($attr) = @_;

  if ($attr->{TP_ID} && !$attr->{DISABLE}) {
    my $Tariffs = Tariffs->new($self->{db}, $self->{conf}, $self->{admin});

    if ($self->{debug}) {
      $Tariffs->{debug} = 1;
    }

    $self->{TP_INFO} = $Tariffs->info(0, {
      TP_ID     => $attr->{TP_ID},
      DOMAIN_ID => $admin->{DOMAIN_ID} || undef
    });
  }

  $admin->{MODULE} = $MODULE;
  $self->query_add('triplay_main', $attr);

  return $self;
}

#**********************************************************
=head2 info_user($attr) - get information

  Arguments:
    UID - user's identifier

  Returns:
    $self object

  Examples:
    my $user_info = $Triplay->info_user({COLS_NAME => 1, UID => $FORM{UID}});

=cut
#**********************************************************
sub user_info {
  my $self = shift;
  my ($attr) = @_;

  if ($attr->{UID}) {
    $self->query("SELECT tri.*,
       tp.month_fee AS month_abon,
       tp.day_fee AS day_abon,
       tp.credit AS tp_credit
      FROM triplay_main tri
      LEFT JOIN tarif_plans tp ON (tp.tp_id = tri.tp_id)
      WHERE uid = ?;", undef, { INFO => 1, Bind => [ $attr->{UID} ] }
    );
  }

  return $self;
}

#**********************************************************
=head2 change_user($attr) - change tp for user

  Arguments:
    UID   - user identifier
    TP_ID - Triplay's tp identifier

  Returns:

  Examples:
    $Triplay->change_user({
        UID        => $FORM{UID},
        TP_ID      => $FORM{TRIPLAY_TP}
    });

=cut
#**********************************************************
sub user_change {
  my $self = shift;
  my ($attr) = @_;

  if (defined($attr->{STATUS})) {
    $attr->{DISABLE} = $attr->{STATUS};
  }

  my $old_info = $self->user_info({ UID => $attr->{UID} });

  $self->changes({
    CHANGE_PARAM => 'UID',
    TABLE        => 'triplay_main',
    DATA         => $attr
  });

  if (! $attr->{DISABLE}) {
    my $Tariffs = Tariffs->new($self->{db}, $self->{conf}, $admin);

    if($self->{debug}) {
      $Tariffs->{debug}=1;
    }

    $self->{TP_INFO} = $Tariffs->info(0, {
      TP_ID     => $attr->{TP_ID} || $old_info->{TP_ID},
      DOMAIN_ID => $admin->{DOMAIN_ID} || undef
    });
  }

  return $self;
}

#**********************************************************
=head2 delete_user($attr) - delete triplay user

  Arguments:
    UID - user identifier

  Returns:
    $self object

  Examples:
    $Triplay->del_user({ UID   => $FORM{UID} });

=cut
#**********************************************************
sub user_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('triplay_main', undef, $attr);

  return $self;
}

#**********************************************************
=head2 user_list($attr)

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub user_list {
  my $self = shift;
  my ($attr) = @_;

  delete $self->{COL_NAMES_ARR};

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : '1';
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : 'desc';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 100;

  my $WHERE = $self->search_former($attr, [
      [ 'UID',         'INT', 'tu.uid as login', 1 ],
      [ 'SERVICE_STATUS', 'INT', 'tu.disable AS service_status',   1 ],
      [ 'TP_ID',       'INT', 'tu.tp_id',        1 ],
      [ 'TP_NAME',     'STR', 'tp.name', 'tp.name AS tp_name' ],
      [ 'MONTH_FEE',   'INT', 'tp.month_fee', 'tp.month_fee'  ],
      [ 'INTERNET_TP', 'INT', 'tt.internet_tp',  1 ],
      [ 'VOIP_TP',     'INT', 'tt.voip_tp',      1 ],
      [ 'IPTV_TP',     'INT', 'tt.iptv_tp',      1 ],
      [ 'INTERNET_TP', 'INT', 'tt.internet_tp',  1 ],
      [ 'VOIP_TP',     'INT', 'tt.voip_tp',      1 ],
      [ 'IPTV_TP',     'INT', 'tt.iptv_tp',      1 ],
      [ 'INTERNET_NAME','STR', 'tp_internet.name as internet_tp_name',      1 ],
      [ 'VOIP_NAME','STR', 'tp_voip.name as voip_tp_name',      1 ],
      [ 'IPTV_NAME','STR', 'tp_iptv.name as iptv_tp_name',      1 ],
      [ 'ABONPLATA','INT', 'tu.uid AS abonplata',      1 ],
      #      ['ADMIN',          'STR',  'admins.name as admin',        1 ],
      #      ['ADDRESS_FULL',    'STR',  "CONCAT(streets.name, ' ', builds.number, ',', pi.address_flat) AS address_full", ]
    ],
    { WHERE            => 1,
      USE_USER_PI      => 1,
      USERS_FIELDS_PRE => 1,
    }
  );

  my $EXT_TABLE = $self->{EXT_TABLES} || '';

  if ($attr->{TP_NAME}) {
    $EXT_TABLE .= "LEFT JOIN tarif_plans AS tp ON (tp.tp_id=tu.tp_id) ";
  }

  $self->query(
    "SELECT
    $self->{SEARCH_FIELDS}

    tu.uid
    FROM triplay_main AS tu
    LEFT JOIN users u ON u.uid=tu.uid
    LEFT JOIN triplay_tps tt ON tt.id=tu.tp_id
    LEFT JOIN tarif_plans tp_internet ON (tp_internet.id=tt.internet_tp AND tp_internet.module='Internet')
    LEFT JOIN tarif_plans tp_voip ON (tp_voip.id=tt.voip_tp AND tp_voip.module='Voip')
    LEFT JOIN tarif_plans tp_iptv ON (tp_iptv.id=tt.iptv_tp AND tp_iptv.module='Iptv')
    $EXT_TABLE
    $WHERE
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;",
    undef,
    { %$attr, COLS_NAME => 1, }
  );

  my $list = $self->{list};

  return $list if ($attr->{TOTAL} < 1);

  $self->query(
    "SELECT COUNT(*) AS total
     FROM triplay_main
     $EXT_TABLE
     $WHERE;",
    undef,
    { INFO => 1 }
  );

  return $list;
}

#**********************************************************
=head2 service_add($attr) - add user

  Arguments:
    %$attr
      UID   - user's ID
      TP_ID - tariff plan ID

  Returns:
    $self object

  Examples:
    $Triplay->add_user({
      UID     => $FORM{UID},
      TP_ID   => $FORM{TRIPLAY_TP}
    });

=cut
#**********************************************************
sub service_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('triplay_services', $attr);

  return $self;
}

#**********************************************************
=head2 service_user($attr) - get information

  Arguments:
    UID - user's identifier

  Returns:
    $self object

  Examples:
    my $service_info = $Triplay->info_user({COLS_NAME => 1, UID => $FORM{UID}});

=cut
#**********************************************************
sub service_info {
  my $self = shift;
  my ($attr) = @_;

  if ($attr->{UID}) {
    $self->query("SELECT * FROM triplay_services
      WHERE id = ?;",
      undef,
        { INFO => 1, Bind => [ $attr->{ID} ] }
    );
  }

  return $self;
}

#**********************************************************
=head2 service_change($attr) - change tp for user

  Arguments:
    UID   - user identifier
    TP_ID - Triplay's tp identifier

  Returns:

  Examples:
    $Triplay->change_user({
        UID        => $FORM{UID},
        TP_ID      => $FORM{TRIPLAY_TP}
    });

=cut
#**********************************************************
sub service_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'triplay_services',
      DATA         => $attr
    }
  );

  return $self;
}

#**********************************************************
=head2 service_del($attr) - delete triplay user

  Arguments:
    UID - user identifier

  Returns:
    $self object

  Examples:
    $Triplay->del_user({ UID   => $FORM{UID} });

=cut
#**********************************************************
sub service_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('triplay_services', undef, $attr);

  return $self;
}

#**********************************************************
=head2 service_list($attr)

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub service_list {
  my $self = shift;
  my ($attr) = @_;

  delete $self->{COL_NAMES_ARR};

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : '1';
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : 'desc';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 100;

  my $WHERE = $self->search_former($attr, [
    [ 'TP_ID',       'INT', 'ts.tp_id',        1 ],
    [ 'SERVICE_ID',  'INT', 'ts.service_id',   1 ],
    [ 'MODULE',      'STR', 'ts.module',       1 ],
    [ 'COMMENTS',    'STR', 'ts.comments',     1 ],
    [ 'CHANGED',     'DATE','ts.changed',      1 ],
    [ 'STATUS',      'INT', 'ts.status',       1 ],
    [ 'UID',         'INT', 'ts.uid',            ],
  ],
    {
      WHERE            => 1,
    }
  );

  my $EXT_TABLE = $self->{EXT_TABLES} || '';

  $self->query(
    "SELECT
    $self->{SEARCH_FIELDS}
    ts.uid,
    ts.id
    FROM triplay_services AS ts
    $EXT_TABLE
    $WHERE
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;",
    undef,
    { %$attr, COLS_NAME => 1, }
  );

  my $list = $self->{list};

  return $list if ($attr->{TOTAL} < 1);

  $self->query(
    "SELECT COUNT(*) AS total
     FROM triplay_services AS ts
     $EXT_TABLE
     $WHERE",
    undef,
    { INFO => 1 }
  );

  return $list;
}

1
