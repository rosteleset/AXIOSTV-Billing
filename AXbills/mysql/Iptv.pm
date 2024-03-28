package Iptv;

=head1 NAME

  Iptv module

Iptv db function

=cut

=head1 SYNOPSIS

  use Iptv;
  $Iptv->new($db, $admin, \%conf);

=cut

use strict;
use parent qw(dbcore);
use Tariffs;
use Users;
use Fees;

my $MODULE = 'Iptv';
my ($admin, $CONF);
my ($SORT, $DESC, $PG, $PAGE_ROWS);

#**********************************************************
# Init
#**********************************************************
sub new{
  my $class = shift;
  my $db = shift;
  ($admin, $CONF) = @_;

  $admin->{MODULE} = $MODULE;
  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $CONF
  };

  bless( $self, $class );

  return $self;
}

#**********************************************************
=head2 user_info($id, $attr) - User information

  Arguments:
    $id
    $attr
      LOGIN

=cut
#**********************************************************
sub user_info {
  my $self = shift;
  my ($id, $attr) = @_;

  if ( defined( $attr->{LOGIN} ) ){
    use Users;
    my $users = Users->new( $self->{db}, $admin, $CONF );
    $users->info( 0, { LOGIN => $attr->{LOGIN} } );
    if ( $users->{errno} ){
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
   service.disable AS status,
   tp.gid AS tp_gid,
   tp.month_fee,
   tp.month_fee AS month_abon,
   tp.abon_distribution,
   tp.day_fee,
   tp.day_fee AS day_abon,
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
   tp.reduction_fee AS reduction_fee,
   service.expire AS iptv_expire,
   service.activate AS iptv_activate,
   tv_services.module AS service_module,
   tp.fees_method as fees_method,
   tp.describe_aid as describe_aid,
   tp.comments as comments,
   service.*
     FROM iptv_main service
     LEFT JOIN tarif_plans tp ON (service.tp_id=tp.tp_id)
     LEFT JOIN iptv_services tv_services ON (tv_services.id=service.service_id)
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
=head2 user_add($attr) - Add user

=cut
#**********************************************************
sub user_add {
  my $self = shift;
  my ($attr) = @_;

  if (! $attr->{UID}) {
    $self->{errno}=100;
    $self->{errstr}='No UID';
    return $self;
  }

  $attr->{DISABLE} = $attr->{STATUS};
  if ( $attr->{TP_ID} && $attr->{TP_ID} > 0 && !$attr->{STATUS} ){
    my $Tariffs = Tariffs->new( $self->{db}, $CONF, $admin );
    $self->{TP_INFO} = $Tariffs->info( $attr->{TP_ID} );
    $self->{TP_NUM} = $Tariffs->{ID};

    #Take activation price
    if ( $Tariffs->{ACTIV_PRICE} > 0 ){
      my $User = Users->new( $self->{db}, $admin, $CONF );
      $User->info( $attr->{UID} );

      if ( $User->{DEPOSIT} + $User->{CREDIT} < $Tariffs->{ACTIV_PRICE} && $Tariffs->{PAYMENT_TYPE} == 0 ){
        $self->{errno} = 15;
        $self->{errstr} = 'TOO_SMALL_DEPOSIT';
        return $self;
      }

      my $fees = Fees->new( $self->{db}, $admin, $CONF );
      $fees->take( $User, $Tariffs->{ACTIV_PRICE}, { DESCRIBE => "ACTIV TP", METHOD => $Tariffs->{FEES_METHOD} || '' } );
      $Tariffs->{ACTIV_PRICE} = 0;
    }

    $self->expire_date($attr, $Tariffs) if ($Tariffs->{AGE} > 0);
  }

  $self->query_add('iptv_main', {
    %{$attr},
    REGISTRATION => 'NOW()',
    EXPIRE       => $attr->{IPTV_EXPIRE},
    ACTIVATE     => $attr->{IPTV_ACTIVATE},
  });

  return $self if ($self->{errno});
  $admin->{MODULE} = $MODULE;

  my @info = ('SERVICE_ID', 'ID', 'TP_ID', 'STATUS', 'IPTV_EXPIRE', 'IPTV_ACTIVATE', 'CID', 'EMAIL');
  my @actions_history = ();

  foreach my $param (@info) {
    if (defined($attr->{$param})) {
      push @actions_history, $param . ":" . $attr->{$param};
    }
  }

  $self->{ID} = $self->{INSERT_ID};

  $admin->action_add($attr->{UID}, "ID: $self->{INSERT_ID} ".  join(', ', @actions_history), { TYPE => 1 } );

  return $self;
}

#**********************************************************
=head2 user_change($attr) - Change users

  Arguments:


=cut
#**********************************************************
sub user_change{
  my $self = shift;
  my ($attr) = @_;

  $attr->{EXPIRE} = $attr->{SERVICE_EXPIRE} || $attr->{IPTV_EXPIRE};
  $attr->{ACTIVATE} = $attr->{SERVICE_ACTIVATE} || $attr->{IPTV_ACTIVATE};
  $attr->{VOD} = (!defined( $attr->{VOD} )) ? 0 : 1;
  $attr->{DISABLE} = $attr->{STATUS};
  my $old_info = $self->user_info( $attr->{ID} );
  $self->{OLD_STATUS} = $old_info->{STATUS};

  if ( $attr->{TP_ID} && $attr->{TP_ID} && $old_info->{TP_ID} != $attr->{TP_ID} ){
    my $Tariffs = Tariffs->new( $self->{db}, $CONF, $admin );

    $Tariffs->info( $old_info->{TP_ID} );
    $attr->{EXPIRE} = '0000-00-00' if defined($Tariffs->{AGE}) && $Tariffs->{AGE} > 0 && !$attr->{EXPIRE};

    %{ $self->{TP_INFO_OLD} } = %{$Tariffs};
    $self->{TP_INFO} = $Tariffs->info( $attr->{TP_ID} );
    my $User = Users->new( $self->{db}, $admin, $CONF );

    $self->user_channels({ ID => $attr->{ID} });

    $User->info( $attr->{UID} );
    if ( ( $old_info->{STATUS} && $old_info->{STATUS} == 2 ) && (defined( $attr->{STATUS} ) && $attr->{STATUS} == 0)
      && $Tariffs->{ACTIV_PRICE} > 0 ){
      if ( $User->{DEPOSIT} + $User->{CREDIT} < $Tariffs->{ACTIV_PRICE} && $Tariffs->{PAYMENT_TYPE} == 0 && $Tariffs->{POSTPAID_FEE} == 0 ){
        $self->{errno} = 15;
        $self->{errstr} = 'TOO_SMALL_DEPOSIT';
        return $self;
      }

      my $fees = Fees->new( $self->{db}, $admin, $CONF );
      $fees->take( $User, $Tariffs->{ACTIV_PRICE}, { DESCRIBE => "ACTIV_TP" } );

      $Tariffs->{ACTIV_PRICE} = 0;
    }
    elsif ( $Tariffs->{CHANGE_PRICE} > 0 ){

      if ( $User->{DEPOSIT} + $User->{CREDIT} < $Tariffs->{CHANGE_PRICE} ){
        $self->{errno} = 15;
        $self->{errstr} = 'TOO_SMALL_DEPOSIT';
        return $self;
      }

      my $Fees = Fees->new( $self->{db}, $admin, $CONF );
      $Fees->take( $User, $Tariffs->{CHANGE_PRICE}, { DESCRIBE => "CHANGE_TP" } );
    }

    $self->expire_date($attr, $Tariffs) if $Tariffs->{AGE} > 0;
    $attr->{EXPIRE} = $attr->{IPTV_EXPIRE} if $attr->{IPTV_EXPIRE};
  }
  elsif ( ($old_info->{STATUS}
    && ($old_info->{STATUS} == 1
    || $old_info->{STATUS} == 2
    || $old_info->{STATUS} == 3
    || $old_info->{STATUS} == 4
    || $old_info->{STATUS} == 5))
    && (defined($attr->{STATUS}) && $attr->{STATUS} == 0) ){
    my $tariffs = Tariffs->new( $self->{db}, $CONF, $admin );
    $self->{TP_INFO} = $tariffs->info( $old_info->{TP_ID} );
  }

  $attr->{JOIN_SERVICE} = ($attr->{JOIN_SERVICE}) ? $attr->{JOIN_SERVICE} : 0;

  $admin->{MODULE} = $MODULE;
  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'iptv_main',
    DATA         => $attr
  });

  $self->user_info( $attr->{ID} );
  return $self;
}

#**********************************************************
=head2 user_del(attr);

=cut
#**********************************************************
sub user_del{
  my $self = shift;
  my ($attr) = @_;

  $self->query_del( 'iptv_main', $attr, { uid => $self->{UID} } );

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

  $admin->action_add($self->{UID}, join(' ', @del_descr), { TYPE => 10 });

  return $self->{result};
}

#**********************************************************
=head2 user_list($attr) - Users list

=cut
#**********************************************************
sub user_list{
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;
  my $GROUP_BY = '';

  if ($attr->{GROUP_BY} && $attr->{GROUP_BY} =~ /GROUP/i) {
    $GROUP_BY = $attr->{GROUP_BY};
    delete $attr->{GROUP_BY};
  }
  my $EXT_TABLE = '';
  $self->{EXT_TABLES} = '';
  delete $self->{errno};

  my $WHERE = $self->search_former(
    $attr,
    [
      [ 'TP_NUM',            'INT', 'tp.id',   'tp.id AS tp_num'                                                   ],
      [ 'TP_NAME',           'STR', 'tp.name', 'tp.name AS tp_name'                                                ],
      [ 'TP_COMMENTS',       'STR', 'tp.comments', 'tp.comments AS tp_comments'                                    ],
      [ 'SERVICE_STATUS',    'INT', 'service.disable', 'service.disable AS service_status'                         ],
      [ 'CID',               'STR', 'service.cid',                                                               1 ],
      [ 'PIN',               'STR', 'service.pin',                                                               1 ],
      [ 'ALL_FILTER_ID',     'STR', 'IF(service.filter_id<>\'\', service.filter_id, tp.filter_id) AS filter_id', 1 ],
      [ 'FILTER_ID',         'STR', 'service.filter_id',                                                         1 ],
      [ 'DVCRYPT_ID',        'INT', 'service.dvcrypt_id',                                                        1 ],
      [ 'AGE',               'INT', 'tp.age as tp_age',                                                          1 ],
      [ 'ACTIV_PRICE',       'INT', 'tp.activate_price',                                                         1 ],
      [ 'MONTH_FEE',         'INT', 'tp.month_fee',                                                              1 ],
      [ 'ABON_DISTRIBUTION', 'INT', 'tp.abon_distribution',                                                      1 ],
      [ 'DAY_FEE',           'INT', 'tp.day_fee',                                                                1 ],
      [ 'TP_ID',             'INT', 'service.tp_id',                                                             1 ],
      [ 'TV_SERVICE_ID',     'INT', 'tp.service_id', 'tp.service_id AS tv_service_id'                              ],
      [ 'TV_SERVICE_NAME',   'INT', 'tv_service.name', 'tv_service.name AS tv_service_name'                        ],
      [ 'TV_USER_PORTAL',    'INT', 'tv_service.user_portal', 'tv_service.user_portal AS tv_user_portal'           ],
      [ 'TP_CREDIT',         'INT', 'tp.credit', 'tp.credit AS tp_credit'                                          ],
      [ 'TP_FILTER',         'INT', 'tp.filter_id',                                                              1 ],
      [ 'TP_REDUCTION_FEE',  'INT', 'tp.reduction_fee', 'tp.reduction_fee AS tp_reduction_fee'                     ],
      [ 'PAYMENT_TYPE',      'INT', 'tp.payment_type',                                                           1 ],
      [ 'MONTH_PRICE',       'INT', 'ti_c.month_price',                                                          1 ],
      [ 'DAY_PRICE',         'INT', 'ti_c.day_price',                                                            1 ],
      [ 'IPTV_ACTIVATE',     'DATE','service.activate', 'service.activate AS iptv_activate'                        ],
      [ 'IPTV_EXPIRE',       'DATE','service.expire', 'service.expire AS iptv_expire'                              ],
      [ 'SUBSCRIBE_ID',      'INT', 'service.subscribe_id',                                                      1 ],
      [ 'SERVICE_ID',        'INT', 'service.service_id',                                                        1 ],
      [ 'EMAIL',             'STR', 'service.email',                                                             1 ],
      [ 'SERVICE_COUNT',     'INT', '', 'COUNT(service.id) AS service_count'                                       ] ,
      [ 'ID',                'INT', 'service.id',                                                                1 ],
      [ 'UID',               'INT', 'service.uid',                                                               1 ],
      [ 'IPTV_LOGIN',        'STR', 'service.iptv_login',                                                        1 ],
      [ 'IPTV_PASSWORD',     'STR', 'service.iptv_password',                                                     1 ],
      [ 'MAC_CID',           'STR', 'us.cid AS mac_cid',                                                         1 ],
      [ 'SERIAL',            'STR', 'us.serial',                                                                 1 ],
      [ 'DESCRIBE_AID',      'STR', 'tp.describe_aid',                                                           1 ],
    ],
    {
      WHERE             => 1,
      USERS_FIELDS_PRE  => 1,
      USE_USER_PI       => 1,
      SKIP_USERS_FIELDS => [ 'UID' ]
    }
  );

  $EXT_TABLE = $self->{EXT_TABLES} if ($self->{EXT_TABLES});
  if ( $attr->{SHOW_CONNECTIONS} ){
    $EXT_TABLE .= "LEFT JOIN internet_main dhcp ON (dhcp.uid=u.uid)
                  LEFT JOIN nas  ON (nas.id=dhcp.nas_id)";

    $self->{SEARCH_FIELDS} .= "INET_NTOA(nas.ip) AS nas_ip, dhcp.ports, nas.nas_type, nas.mng_user,
      DECODE(nas.mng_password, '$CONF->{secretkey}') AS mng_password, nas.mng_host_port, nas.id AS nas_id, ";
    $self->{SEARCH_FIELDS_COUNT} += 7;
  }

  if($attr->{TV_SERVICE_NAME}) {
    $EXT_TABLE .= "LEFT JOIN iptv_services tv_service ON (tv_service.id=tp.service_id)";
  }

  if ($attr->{MAC_CID} || $attr->{SERIAL}) {
    $EXT_TABLE .= "LEFT JOIN iptv_users_screens us ON (service.id=us.service_id)" .
      "LEFT JOIN iptv_screens s ON (s.num=us.screen_id)";
  }

  my $list;
  if ( $attr->{SHOW_CHANNELS} ){
    $self->query(
      "SELECT $self->{SEARCH_FIELDS}
        u.uid,
        service.tp_id,
        ti_c.channel_id,
        c.num AS channel_num,
        c.name AS channel_name,
        c.filter_id AS channel_filter,
        ti_c.month_price,
        ti_c.day_price,
        service.id
   FROM intervals i
     INNER JOIN iptv_ti_channels ti_c ON (i.id=ti_c.interval_id)
     INNER JOIN iptv_users_channels uc ON (ti_c.channel_id=uc.channel_id)
     INNER JOIN iptv_channels c ON (uc.channel_id=c.id)

     INNER JOIN iptv_main service ON (service.id = uc.id AND i.tp_id=service.tp_id)
     INNER JOIN users u ON (u.uid=service.uid)

     INNER JOIN tarif_plans tp ON (tp.tp_id=i.tp_id)
     $EXT_TABLE
     $WHERE
   GROUP BY uc.id, uc.channel_id
   ORDER BY $SORT $DESC
   LIMIT $PG, $PAGE_ROWS;",
      undef,
      $attr
    );

    $list = $self->{list};
  }
  else{
    $self->query(
      "SELECT
      $self->{SEARCH_FIELDS}
      service.disable AS service_status,
      service.tp_id,
      u.uid,
      service.id
     FROM iptv_main service
     LEFT JOIN users u ON (u.uid = service.uid)
     LEFT JOIN tarif_plans tp ON (tp.tp_id=service.tp_id)
     $EXT_TABLE
     $WHERE
     $GROUP_BY
     ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
      undef,
      $attr
    );

    return [] if ($self->{errno});

    $list = $self->{list};

    if ( $self->{TOTAL} >= 0 ){
      $self->query(
        "SELECT count(DISTINCT service.id) AS total FROM iptv_main service
       LEFT JOIN users u ON (u.uid = service.uid)
       LEFT JOIN tarif_plans tp ON (tp.tp_id=service.tp_id)
      $EXT_TABLE
      $WHERE", undef, { INFO => 1 }
      );
    }
  }

  return $list || [];
}

#**********************************************************
=head2 user_tp_channels_list($attr) User information

=cut
#**********************************************************
sub user_tp_channels_list{
  my $self = shift;
  my ($attr) = @_;

  my $WHERE = $self->search_former( $attr, [
      [ 'STATUS',       'INT', 'service.disable' ],
      [ 'LOGIN_STATUS', 'INT', 'u.disable', ],
    ], { WHERE => 1, } );

  my $list = $self->{list};
  return [ ] if ($self->{errno});

  if ( $self->{TOTAL} >= 0 ){
    $self->query( "SELECT COUNT(u.id) AS total FROM (users u, iptv_main service) $WHERE", undef, { INFO => 1 } );
  }

  return $list;
}

#**********************************************************
=head2 channel_info($attr) - Channel info

=cut
#**********************************************************
sub channel_info{
  my $self = shift;
  my ($attr) = @_;

  $self->query(
    "SELECT * FROM iptv_channels WHERE id = ?;",
    undef,
    {
      INFO => 1,
      Bind => [ $attr->{ID} ]
    }
  );

  return $self;
}

#**********************************************************
=head2 channel_defaults()

=cut
#**********************************************************
sub channel_defaults{
  my $self = shift;

  my %DATA = (
    ID       => 0,
    NAME     => '',
    NUMBER   => 0,
    PORT     => 0,
    DESCRIBE => '',
    DISABLE  => 0
  );

  $self = \%DATA;
  return $self;
}

#**********************************************************
=head2 channel_add($attr) - Channel add

=cut
#**********************************************************
sub channel_add{
  my $self = shift;
  my ($attr) = @_;

  $self->query_add( 'iptv_channels', $attr );

  return [ ] if ($self->{errno});

  $admin->system_action_add( "CH:$attr->{NUMBER}", { TYPE => 1 } );
  return $self;
}

#**********************************************************
=head2 channel_change($attr) - Channel change

=cut
#**********************************************************
sub channel_change{
  my $self = shift;
  my ($attr) = @_;

  $admin->{MODULE} = $MODULE;
  $self->changes(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'iptv_channels',
      DATA         => $attr
    }
  );

  return [ ] if ($self->{errno});

  $self->channel_info( { ID => $attr->{ID} } );

  return $self;
}

#**********************************************************
=head2  channel_del($id, $attr) - Channel del

=cut
#**********************************************************
sub channel_del{
  my $self = shift;
  my ($id, $attr) = @_;

  if ( $attr->{ALL} ){
    $self->query( 'DELETE FROM `iptv_channels`;', 'do' );
  }
  else{
    $self->query_del( 'iptv_channels', undef, { id => $id } );
  }

  return $self->{result};
}

#**********************************************************
=head2 channel_list($attr)

=cut
#**********************************************************
sub channel_list{
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $WHERE = $self->search_former( $attr, [
      [ 'NUM',      'INT', 'num'         ],
      [ 'NAME',     'STR', 'name'        ],
      [ 'DISABLE',  'INT', 'disable'     ],
      [ 'PORT',     'INT', 'port'        ],
      [ 'DESCRIBE', 'STR', 'comments', 1 ],
      [ 'FILTER',   'STR', 'filter_id',1 ],
      [ 'STREAM',   'STR', 'stream',   1 ],
      [ 'STATE',    'INT', 'state',    1 ],
      [ 'GENRE_ID', 'INT', 'genre_id', 1 ],
      [ 'ID',       'INT', 'id',       1 ],
    ],
    { WHERE => 1, } );

  $self->query(
    "SELECT num, name, comments, port, filter_id, stream, disable AS status,
      $self->{SEARCH_FIELDS}
      id
     FROM iptv_channels
     $WHERE
     ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  return [ ] if ($self->{errno});

  my $list = $self->{list};

  if ( $self->{TOTAL} >= 0 ){
    $self->query( "SELECT count(*) AS total FROM iptv_channels $WHERE", undef, { INFO => 1 } );
  }

  return $list;
}

#**********************************************************
=head2 user_channels($attr) - Users channels

  Arguments:
    $attr
      IDS
      ID
      TP_ID

  Results:
    Objects

=cut
#**********************************************************
sub user_channels{
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('iptv_users_channels', $attr);

  my @ids = split( /,\s?/, $attr->{IDS} );

  my @MULTI_QUERY = ();

  foreach my $id ( @ids ){
    push @MULTI_QUERY, [ $attr->{ID}, $attr->{TP_ID}, $id ];
  }

  $self->query(
    "INSERT INTO iptv_users_channels
     (id, tp_id, channel_id, changed)
        VALUES (?, ?, ?, NOW());",
    undef,
    { MULTI_QUERY => \@MULTI_QUERY }
  );

  return $self;
}

#**********************************************************
=head2 user_channels_list($attr)

  Arguments:
    $attr
      TP_ID  - TP_ID
      ID     - Service ID

=cut
#**********************************************************
sub user_channels_list{
  my $self = shift;
  my ($attr) = @_;

  $self->query(
    "SELECT uid, tp_id, channel_id, changed
     FROM iptv_users_channels
     WHERE tp_id= ? AND id = ?;",
    undef,
    { %{$attr}, Bind => [ $attr->{TP_ID}, $attr->{ID} ] }
  );

  $self->{USER_CHANNELS} = $self->{TOTAL};

  return $self->{list};
}

#**********************************************************
=head2 channel_ti_change($attr)

=cut
#**********************************************************
sub channel_ti_change{
  my $self = shift;
  my ($attr) = @_;

  my %DATA = $self->get_data( $attr );

  $self->query_del( 'iptv_ti_channels', undef, { interval_id => $attr->{INTERVAL_ID} } ),

    my @ids = split( /, /, $attr->{IDS} );

  my @MULTI_QUERY = ();

  foreach my $id ( @ids ){
    push @MULTI_QUERY, [ $DATA{INTERVAL_ID}, $id, $DATA{ 'MONTH_PRICE_' . $id } || 0, $DATA{ 'DAY_PRICE_' . $id } || 0,
        $DATA{ 'MANDATORY_' . $id } || 0 ];
  }

  $self->query(
    "INSERT INTO iptv_ti_channels
     ( interval_id, channel_id, month_price, day_price, mandatory)
        VALUES (?, ?, ?, ?, ?);",
    undef,
    { MULTI_QUERY => \@MULTI_QUERY }
  );

  #$admin->action_add("$DATA{UID}", "ACTIVE");
  return $self;
}

#**********************************************************
=head2 channel_ti_list($attr)

=cut
#**********************************************************
sub channel_ti_list{
  my $self = shift;
  my ($attr) = @_;

  $SORT      = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC      = ($attr->{DESC}) ? $attr->{DESC} : '';
  $PG        = ($attr->{PG}) ? $attr->{PG} : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $WHERE = $self->search_former(
    $attr,
    [
      [ 'DISABLE',          'INT', 'disable',       ],
      [ 'PORT',             'INT', 'port'           ],
      [ 'DESCRIBE',         'STR', 'comments'       ],
      [ 'NUMBER',           'INT', 'number'         ],
      [ 'NAME',             'STR', 'name'           ],
      [ 'FILTER_ID',        'STR', 'c.filter_id', 1 ],
      [ 'IDS',              'INT', 'c.id'           ],
      [ 'ID',               'INT', 'c.id'           ],
      [ 'USER_INTERVAL_ID', 'INT', 'ic.interval_id' ],
      [ 'MANDATORY',        'STR', 'ic.mandatory'   ],
      [ 'STREAM',           'STR', 'c.stream',    1 ],
    ],
    { WHERE => 1, }
  );

  if(! $attr->{INTERVAL_ID} && $attr->{USER_INTERVAL_ID}) {
    $attr->{INTERVAL_ID} = $attr->{USER_INTERVAL_ID};
  }

  $self->query(
    "SELECT IF(ic.channel_id IS NULL, 0, 1) AS interval_channel_id,
   c.num AS channel_num,
   c.name,
   c.comments,
   $self->{SEARCH_FIELDS}
   ic.month_price,
   ic.day_price,
   ic.mandatory,
   c.port,
   c.disable,
   c.id AS channel_id
     FROM iptv_channels c
     LEFT JOIN iptv_ti_channels ic ON (id=ic.channel_id AND ic.interval_id='$attr->{INTERVAL_ID}')
     $WHERE
     ORDER BY $SORT $DESC ;",
    undef,
    $attr
  );

  return [ ] if ($self->{errno});

  my $list = $self->{list};

  if ( $self->{TOTAL} >= 0 ){
    $self->query(
      "SELECT COUNT(*) AS total, SUM(IF (ic.channel_id IS NULL, 0, 1)) AS active
     FROM iptv_channels c
     LEFT JOIN iptv_ti_channels ic ON (c.id=ic.channel_id AND ic.interval_id='$attr->{INTERVAL_ID}')
     $WHERE
    ",
      undef,
      { INFO => 1 }
    );
  }

  return $list;
}

#**********************************************************
=head2 reports_channels_use($attr)

=cut
#**********************************************************
sub reports_channels_use{
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $sql = "SELECT c.num,  c.name, COUNT(uc.uid) AS users, SUM(IF(IF(company.id IS NULL, b.deposit, cb.deposit)>0, 0, 1)) AS debetors
FROM iptv_channels c
LEFT JOIN iptv_users_channels uc ON (c.id=uc.channel_id)
LEFT JOIN iptv_main service ON (service.id=uc.id)
LEFT JOIN users u ON (service.uid=u.uid)
LEFT JOIN bills b ON (u.bill_id = b.id)
LEFT JOIN companies company ON  (u.company_id=company.id)
LEFT JOIN bills cb ON  (company.bill_id=cb.id)
GROUP BY c.id
ORDER BY $SORT $DESC ";

  #  $sql = "select c.num, c.name, count(*), c.id
  #FROM iptv_channels c
  #LEFT JOIN iptv_ti_channels ic  ON (c.id=ic.channel_id)
  #LEFT JOIN intervals i ON (ic.interval_id=i.id)
  #LEFT JOIN tarif_plans tp ON (tp.tp_id=i.tp_id)
  #LEFT JOIN iptv_main u ON (tp.tp_id=u.tp_id)
  #group BY c.id
  #     ORDER BY $SORT $DESC ;";

  $self->query( $sql, undef, $attr );

  return [ ] if ($self->{errno});

  my $list = $self->{list};

  return $list;
}

#**********************************************************
=head2 reports_channels_use($attr)

=cut
#**********************************************************
sub reports_channels_use2{
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  my $sql = "SELECT c.num,  c.name, u.uid, ipm.disable, u.id AS user, IF(company.id IS NULL, b.deposit, cb.deposit) as deposit
              FROM  iptv_channels c
              INNER JOIN iptv_users_channels uc ON (c.id=uc.channel_id)
              INNER JOIN iptv_main ipm ON (ipm.id=uc.id)
              LEFT JOIN users u ON (u.uid=ipm.uid)
              LEFT JOIN bills b ON (u.bill_id = b.id)
              LEFT JOIN companies company ON  (u.company_id=company.id)
              LEFT JOIN bills cb ON  (company.bill_id=cb.id)
              WHERE ipm.disable=0
            UNION
            SELECT c.num,  c.name, us.uid, im.disable, us.id AS user, IF(company.id IS NULL, b.deposit, cb.deposit) as deposit
              FROM  iptv_channels c
              INNER JOIN iptv_ti_channels ti ON (c.id=ti.channel_id AND ti.mandatory = 1)
              LEFT JOIN intervals i ON (ti.interval_id=i.id)
              LEFT JOIN tarif_plans tp ON (tp.tp_id=i.tp_id)
              LEFT JOIN iptv_main im ON (tp.tp_id=im.tp_id)
              LEFT JOIN users us ON (us.uid=im.uid)
              LEFT JOIN bills b ON (us.bill_id = b.id)
              LEFT JOIN companies company ON  (us.company_id=company.id)
              LEFT JOIN bills cb ON  (company.bill_id=cb.id)

              ORDER BY $SORT $DESC";

  $self->query( $sql, undef, $attr );

  return [ ] if ($self->{errno});

  my $list = $self->{list};

  return $list;

}

#**********************************************************
=head2 online($attr)

=cut
#**********************************************************
sub online{
  my $self = shift;
  my ($attr) = @_;

  my $EXT_TABLE = '';
  $admin->{DOMAIN_ID} = 0 if (!$admin->{DOMAIN_ID});
  if ( $attr->{COUNT} ){
    my $WHERE = '';
    if ( $attr->{ZAPED} ){
      $WHERE = 'WHERE c.status=2';
    }
    else{
      $WHERE = 'WHERE ((c.status=1 or c.status>=3) AND c.status<11)';
    }

    $self->query( "SELECT  count(*) AS total FROM iptv_calls c $WHERE;", undef, { INFO => 1 } );
    return $self;
  }

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  my @WHERE_RULES = ();

  if ( $attr->{ZAPED} ){
    push @WHERE_RULES, "c.status=2";
  }
  elsif ( $attr->{ALL} ){

  }
  elsif ( $attr->{STATUS} ){
    push @WHERE_RULES, @{ $self->search_expr( "$attr->{STATUS}", 'INT', 'c.status' ) };
  }
  else{
    push @WHERE_RULES, "((c.status=1 or c.status>=3) AND c.status<11)";
  }

  if ( $attr->{FILTER} ){
    $attr->{ $attr->{FILTER_FIELD} } = $attr->{FILTER};
  }

  my $WHERE = $self->search_former(
    $attr,
    [
      [ 'LOGIN',         'STR',  'u.id AS login', ],
      [ 'FIO',           'STR',  'pi.fio', 1 ],
      [ 'STARTED',       'DATE', 'IF(DATE_FORMAT(c.started, "%Y-%m-%d")=CURDATE(), DATE_FORMAT(c.started, "%H:%i:%s"), c.started) AS started',
        1 ],
      [ 'NAS_PORT_ID',     'INT', 'c.nas_port_id', 1 ],
      [ 'CLIENT_IP_NUM',   'INT', 'c.framed_ip_address',    'c.framed_ip_address AS ip_num' ],
      [ 'DURATION',        'INT', 'SEC_TO_TIME(UNIX_TIMESTAMP() - UNIX_TIMESTAMP(c.started))',
        'SEC_TO_TIME(UNIX_TIMESTAMP() - UNIX_TIMESTAMP(c.started)) AS duration' ],
      [ 'CID',             'STR', 'c.CID', 1 ],
      [ 'SERVICE_CID',     'STR', 'service.cid', 1 ],
      [ 'TP_ID',           'INT', 'service.tp_id', 1 ],
      [ 'ONLINE_TP_ID',     'INT', 'c.tp_id', 'c.tp_id AS online_tp_id' ],
      [ 'CONNECT_INFO',    'STR', 'c.CONNECT_INFO', 1 ],
      [ 'SPEED',           'INT', 'service.speed', 1 ],
      [ 'SUM',             'INT', 'c.sum AS session_sum', 1 ],
      [ 'STATUS',          'INT', 'c.status', 1 ],

      #    ['ADDRESS_FULL',    '' ($CONF->{ADDRESS_REGISTER}) ? 'concat(streets.name,\' \', builds.number, \'/\', pi.address_flat) AS ADDRESS' : 'concat(pi.address_street,\' \', pi.address_build,\'/\', pi.address_flat) AS ADDRESS',
      [ 'GID',              'INT', 'u.gid', 1 ],
      [ 'TURBO_MODE',       'INT', 'c.turbo_mode', 1 ],
      [ 'JOIN_SERVICE',     'INT', 'c.join_service', 1 ],
      [ 'PHONE',            'STR', 'pi.phone', 1 ],

      [ 'CLIENT_IP',        'IP',  'c.framed_ip_address',    'INET_NTOA(c.framed_ip_address) AS client_ip' ],
      [ 'UID',              'INT', 'u.uid', 1 ],
      [ 'NAS_IP',           'IP',  'nas_ip', 'INET_NTOA(c.nas_ip_address) AS nas_ip' ],
      [ 'DEPOSIT',          'INT', 'IF(company.name IS NULL, b.deposit, cb.deposit) AS deposit', 1 ],
      [ 'CREDIT',           'INT', 'IF(u.company_id=0, u.credit, if (u.credit=0, company.credit, u.credit)) AS credit', 1 ],
      [ 'ACCT_SESSION_TIME','INT', 'UNIX_TIMESTAMP() - UNIX_TIMESTAMP(c.started) AS acct_session_time', 1 ],
      [ 'DURATION_SEC',     'INT', 'if(c.lupdated>0, c.lupdated - UNIX_TIMESTAMP(c.started), 0) AS duration_sec', 1 ],
      [ 'FILTER_ID',        'STR', 'if(service.filter_id<>\'\', service.filter_id, tp.filter_id) AS filter_id', 1 ],
      [ 'SESSION_START',    'INT', 'UNIX_TIMESTAMP(started) AS started_unixtime', 1 ],
      [ 'DISABLE',          'INT', 'u.disable AS login_status', 1 ],
      [ 'DV_STATUS',        'INT', 'service.disable AS service_status', 1 ],

      [ 'TP_NAME',          'STR',  'tp.name AS tp_name', 1 ],
      [ 'TP_BILLS_PRIORITY','INT',  'tp.bills_priority', 1 ],
      [ 'TP_CREDIT',        'INT',  'tp.credit', 'tp.credit AS tp_credit' ],
      [ 'NAS_NAME',         'STR',  'nas.name', 1 ],
      [ 'PAYMENT_METHOD',   'INT',  'tp.payment_type', 1 ],
      [ 'EXPIRED',          'DATE', "if(u.expire>'0000-00-00' AND u.expire <= curdate(), 1, 0) AS expired", 1 ],
      [ 'EXPIRE',           'DATE', 'u.expire', 1 ],
      [ 'SIMULTANEONSLY',   'INT',  'service.logins', 1 ],
      #      ['PORT',               'INT', 'service.port',                                1 ],
      [ 'FILTER_ID',        'STR',  'service.filter_id', 1 ],
      [ 'STATUS',           'INT',  'service.disable', 1 ],
      [ 'IPTV_EXPIRE',      'INT',  'service.expire AS iptv_expire', 1 ],
      #      ['USER_NAME',          'STR', 'c.user_name',                                 1 ],
      [ 'FRAMED_IP_ADDRESS','IP',   'c.framed_ip_address', 1 ],
      [ 'NAS_ID',           'INT',  'c.nas_id', 1 ],
      [ 'GUEST',            'INT',  'c.guest', 1 ],
      [ 'ACCT_SESSION_ID',  'STR',  'c.acct_session_id', 1 ],
      [ 'LAST_ALIVE',       'INT',  'UNIX_TIMESTAMP() - c.lupdated AS last_alive', 1 ],
      [ 'ONLINE_BASE',      '',     '', 'c.CID, c.acct_session_id, UNIX_TIMESTAMP() - c.lupdated AS last_alive, c.uid' ],
      [ 'ID',               'INT',  'service.id', 1 ],
    ],
    {
      WHERE       => 1,
      WHERE_RULES => \@WHERE_RULES
    }
  );

  foreach my $field ( keys %{$attr} ){
    if ( !$field ){
      print "iptv_calls/online: Wrong field name\n";
    }
    elsif ( $field =~ /TP_BILLS_PRIORITY|TP_NAME|FILTER_ID|TP_CREDIT|PAYMENT_METHOD/ && $EXT_TABLE !~ /tarif_plans/ ){
      $EXT_TABLE .= " LEFT JOIN tarif_plans tp ON (tp.tp_id=service.tp_id)";
    }
    elsif ( $field =~ /NAS_NAME/ && $EXT_TABLE !~ / nas / ){
      $EXT_TABLE .= "LEFT JOIN nas ON (nas.id=c.nas_id)";
    }
    elsif ( $field =~ /FIO|PHONE/ && $EXT_TABLE !~ / users_pi / ){
      $EXT_TABLE .= "LEFT JOIN users_pi pi ON (pi.uid=u.uid)";
    }
  }

  $self->query(
    "SELECT u.id AS login, $self->{SEARCH_FIELDS}  c.nas_id
  FROM iptv_calls c
  LEFT JOIN iptv_main service ON (service.uid=c.uid AND c.CID=service.CID)
  LEFT JOIN users u ON (u.uid=service.uid)

  LEFT JOIN bills b ON (u.bill_id=b.id)
  LEFT JOIN companies company ON (u.company_id=company.id)
  LEFT JOIN bills cb ON (company.bill_id=cb.id)
  $EXT_TABLE

 $WHERE
 ORDER BY $SORT $DESC;",
    undef,
    $attr
  );

  my %dub_logins = ();
  my %dub_ports = ();
  my %nas_sorted = ();

  if ( $self->{TOTAL} < 1 ){
    $self->{dub_ports} = \%dub_ports;
    $self->{dub_logins} = \%dub_logins;
    $self->{nas_sorted} = \%nas_sorted;
    return $self->{list};
  }

  my $list = $self->{list};
  foreach my $line ( @{$list} ){
    push @{ $nas_sorted{ $line->{nas_id} } }, $line;
  }

  $self->{dub_ports} = \%dub_ports;
  $self->{dub_logins} = \%dub_logins;
  $self->{nas_sorted} = \%nas_sorted;

  return $self->{list};
}

#**********************************************************
=head2 online_add($attr)

=cut
#**********************************************************
sub online_add{
  my $self = shift;
  my ($attr) = @_;

  $self->query(
    "INSERT INTO iptv_calls
  (started, uid, framed_ip_address, nas_id, nas_ip_address, status, acct_session_id, tp_id, CID, guest)
      VALUES (now(), ?, INET_ATON( ? ), ?, INET_ATON( ? ), ?, ?, ?, ?, ?);", 'do',
    { Bind => [
        $attr->{UID},
        (($attr->{IP}) ? $attr->{IP} : '0.0.0.0'),
        $attr->{NAS_ID},
        (($attr->{NAS_IP_ADDRESS}) ? $attr->{NAS_IP_ADDRESS} : '0.0.0.0'),
        $attr->{STATUS},
        $attr->{ACCT_SESSION_ID},
        $attr->{TP_ID},
        $attr->{CID},
        $attr->{GUEST}
      ] }
  );

  return $self;
}

#**********************************************************
=head2 online_count($attr)

=cut
#**********************************************************
sub online_count{
  my $self = shift;
  my ($attr) = @_;

  my $EXT_TABLE = '';
  my $WHERE = '';
  if ( $attr->{DOMAIN_ID} ){
    $EXT_TABLE = ' INNER JOIN users u ON (c.uid=u.uid)';
    $WHERE = " AND u.domain_id='$attr->{DOMAIN_ID}'";
  }

  $self->query(
    "SELECT n.id, n.name, n.ip, n.nas_type,
   SUM(IF (c.status=1 or c.status>=3, 1, 0)),
   COUNT(distinct c.uid),
   SUM(IF (status=2, 1, 0)),
   SUM(IF (status>3, 1, 0))
  FROM iptv_calls c
  INNER JOIN nas n ON (c.nas_id=n.id)
  $EXT_TABLE
  WHERE c.status<11 $WHERE
  GROUP BY c.nas_id
  ORDER BY $SORT $DESC;"
  );

  my $list = $self->{list};
  $self->{ONLINE} = 0;
  if ( $self->{TOTAL} > 0 ){
    $self->query(
      "SELECT 1, count(c.uid) AS total_users,
      SUM(IF (c.status=1 or c.status>=3, 1, 0)) AS online,
      SUM(IF (c.status=2, 1, 0)) AS zaped
   FROM iptv_calls c
   $EXT_TABLE
   WHERE c.status<11 $WHERE
   GROUP BY 1;",
      undef,
      { INFO => 1 }
    );
    $self->{TOTAL} = $self->{TOTAL_USERS};
  }

  return $list;
}

#**********************************************************
=head2 online_update($attr)

=cut
#**********************************************************
sub online_update{
  my $self = shift;
  my ($attr) = @_;

  $self->query(
    "UPDATE iptv_calls SET lupdated=UNIX_TIMESTAMP()
    WHERE
      acct_session_id='$attr->{ACCT_SESSION_ID}' and
      uid='$attr->{UID}' and
      CID='$attr->{CID}';", 'do'
  );

  return $self;
}

#**********************************************************
=head2 online_del($attr)

=cut
#**********************************************************
sub online_del{
  my $self = shift;
  my ($attr) = @_;

  $self->query_del(
    'iptv_calls',
    undef,
    {
      acct_session_id => $attr->{SESSIONS_LIST},
      CID             => $attr->{CID}
    }
  );

  return $self;
}

#**********************************************************
=head2 subsribe_list($attr)

=cut
#**********************************************************
sub subscribe_list{
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $WHERE = $self->search_former(
    $attr,
    [ [ 'ID', 'INT', 's.id', 1 ],
      [ 'STATUS', 'INT', 's.status', 1 ],
      [ 'EXT_ID', 'STR', 's.ext_id', 1 ],
      [ 'TP_ID', 'INT', 's.tp_id', 1 ],
      [ 'EXPIRE', 'DATE', 's.expire', 1 ],
      [ 'CREATED', 'DATE', 's.created', 1 ], ],
    {
      WHERE        => 1,
      USERS_FIELDS => 1,
      USE_USER_PI  => 1,
    }
  );

  my $EXT_TABLES = ($self->{EXT_TABLES}) ? $self->{EXT_TABLES} : '';

  $self->query(
    "SELECT
    s.id,
    if(service.uid IS NOT NULL, u.id, '') AS login,
    s.status,
    s.ext_id,
    tp.name AS tp_name,
    s.expire,
    s.created,
    s.tp_id,
    service.uid
   FROM iptv_subscribes s
   LEFT JOIN iptv_main service ON (s.id=service.subscribe_id)
   LEFT JOIN users u ON (u.uid=service.uid)
   LEFT JOIN tarif_plans tp ON (tp.tp_id=s.tp_id)
   $EXT_TABLES
   $WHERE
   GROUP BY s.id
   ORDER BY $SORT $DESC
   LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list};

  if ( $self->{TOTAL} > 0 ){
    $self->query( "SELECT COUNT(*) AS total
    FROM iptv_subscribes s
    $WHERE;", undef, { INFO => 1 }
    );
  }

  return $list;
}

#**********************************************************
=head2 subscribe_add($attr)

=cut
#**********************************************************
sub subscribe_add{
  my $self = shift;
  my ($attr) = @_;

  if ( $attr->{MULTI_ARR} ){
    my @MULTI_QUERY = ();

    #Parse array
    my @arr = split( /[\r\n]/, $attr->{MULTI_ARR} );
    my @keys_arr = ();
    my @ext_id_arr = ();

    foreach my $line ( @arr ){
      next if ($line =~ /^#/ || $line eq '');
      my @line_arr = split( /\t/, $line );
      my @insert_arr = ();
      @keys_arr = ();

      foreach my $line_vals ( @line_arr ){
        my ($key, $val) = split( /=/, $line_vals );
        $val =~ s/^\"//g;
        $val =~ s/\"$//g;

        if ( $key eq 'EXT_ID' ){
          push @ext_id_arr, $val;
        }

        push @insert_arr, $val;
        push @keys_arr, lc( $key );
      }

      push @MULTI_QUERY, \@insert_arr;
    }

    $self->query(
      "INSERT INTO iptv_subscribes
     (" . join( ', ', @keys_arr ) . ", created)
        VALUES (" . join( ',', ('?') x @keys_arr ) . ", NOW());",
      undef,
      { MULTI_QUERY => \@MULTI_QUERY }
    );
  }
  else{
    $self->query_add( 'iptv_subscribes', $attr );
  }

  return $self;
}

#**********************************************************
=head2 subscribe_change()

=cut
#**********************************************************
sub subscribe_change{
  my $self = shift;
  my ($attr) = @_;

  $self->changes(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'iptv_subscribes',
      DATA         => $attr
    }
  );

  return $self;
}

#**********************************************************
# del
#**********************************************************
sub subscribe_del{
  my $self = shift;
  my ($id) = @_;

  $self->query_del( 'iptv_subscribes', { ID => $id } );

  return $self;
}

#**********************************************************
# Info
#**********************************************************
sub subscribe_info{
  my $self = shift;
  my ($id) = @_;

  $self->query(
    "SELECT * FROM iptv_subscribes
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
# Session zap
#**********************************************************
sub zap{
  my $self = shift;
  my ($nas_id, $nas_port_id, $acct_session_id, $attr) = @_;

  my $WHERE = '';

  if ( $attr->{NAS_ID} ){
    $WHERE = "WHERE nas_id='$attr->{NAS_ID}'";
  }
  elsif ( !defined( $attr->{ALL} ) ){
    $WHERE = "WHERE nas_id='$nas_id' and nas_port_id='$nas_port_id'";
  }

  if ( $acct_session_id ){
    $WHERE .= "and acct_session_id='$acct_session_id'";
  }

  $self->query( "UPDATE iptv_calls SET status='2' $WHERE;", 'do' );
  return $self;
}

#**********************************************************
=head2 screens_list($attr) - list of tp screens

  Arguments:
    $attr

=cut
#**********************************************************
sub screens_list{
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $WHERE = $self->search_former(
    $attr,
    [ [ 'NUM', 'INT', 'num', 1 ],
      [ 'NAME', 'STR', 'name', 1 ],
      [ 'MONTH_FEE', 'INT', 'month_fee', 1 ],
      [ 'DAY_FEE', 'INT', 'day_fee', 1 ],
      [ 'FILTER_ID', 'STR', 'filter_id', 1 ],
      [ 'TP_ID', 'INT', 'tp_id', 1 ],
    ],
    {
      WHERE => 1,
    }
  );

  $self->query( "SELECT $self->{SEARCH_FIELDS} id
   FROM iptv_screens s
    $WHERE
    GROUP BY s.id
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list};

  if ( $self->{TOTAL} > 0 ){
    $self->query(
      "SELECT COUNT(*) AS total
    FROM iptv_screens s
    $WHERE;", undef, { INFO => 1 }
    );
  }

  return $list;
}

#**********************************************************
=head2 screen_add($attr)

=cut
#**********************************************************
sub screens_add{
  my $self = shift;
  my ($attr) = @_;

  $self->query_add( 'iptv_screens', $attr );

  return $self;
}

#**********************************************************
=head2 screen_change($attr)

=cut
#**********************************************************
sub screens_change{
  my $self = shift;
  my ($attr) = @_;

  $self->changes(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'iptv_screens',
      DATA         => $attr
    }
  );

  return $self;
}

#**********************************************************
=head2 screen_del($id, $attr)

=cut
#**********************************************************
sub screens_del{
  my $self = shift;
  my ($id, $attr) = @_;

  $self->query_del( 'iptv_screens', $attr, { ID => $id } );

  return $self;
}

#**********************************************************
=head2 screen_info($id, $attr)

=cut
#**********************************************************
sub screens_info{
  my $self = shift;
  my ($id) = @_;

  $self->query( "SELECT * FROM iptv_screens
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
=head2 users_screens_add($attr)

  Arguments:
    $attr
      CID
      PIN
      SERIAL
      HARDWARE_ID

=cut
#**********************************************************
sub users_screens_add{
  my $self = shift;
  my ($attr) = @_;

  $self->query_add( 'iptv_users_screens', { %{$attr}, DATE => 'NOW()' }, { REPLACE => 1 });

  my @info = ('CID', 'PIN', 'SERIAL', 'HARDWARE_ID');
  my @actions_history = ();
  foreach my $param (@info) {
    if(defined($attr->{$param})) {
      push @actions_history, $param.":".$attr->{$param};
    }
  }

  $admin->action_add( $attr->{UID}, "SERVICE_ID: $attr->{SERVICE_ID} SCREEN_ID: $attr->{SCREEN_ID}"
    .  join(', ', @actions_history), { TYPE => 1 } );

  $self->{SERVICE_ID}=$attr->{SERVICE_ID};
  $self->{SCREEN_ID}=$attr->{SCREEN_ID};

  return $self;
}

#**********************************************************
=head2 users_screens_del($attr)

=cut
#**********************************************************
sub users_screens_del{
  my $self = shift;
  my ($attr) = @_;

  $self->query_del( 'iptv_users_screens', undef, {
    service_id => $attr->{SERVICE_ID},
    screen_id  => $attr->{SCREEN_ID}
  } );

  $admin->action_add( $attr->{UID}, "SERVICE_ID: $attr->{SERVICE_ID} SCREEN_ID: $attr->{SCREEN_ID}", { TYPE => 10 } );

  return $self;
}

#**********************************************************
=head2  users_screens_info($id, $attr) - users_screens_info

  Arguments:
    $id    - Service ID
    $attr
      SCREEN_ID - Screen ID

  Results:

=cut
#**********************************************************
sub users_screens_info{
  my $self = shift;
  my ($id, $attr) = @_;

  $self->query( "SELECT us.*,
    s.filter_id
     FROM iptv_users_screens us
    INNER JOIN iptv_main service  ON (service.id=us.service_id)
    LEFT JOIN iptv_screens s ON  (s.tp_id=service.tp_id AND s.num=us.screen_id)
    WHERE us.service_id = ? AND us.screen_id = ?;",
    undef,
    {
      INFO => 1,
      Bind => [ $id,
        $attr->{SCREEN_ID} || 0,
      ]
    }
  );

  return $self;
}

#**********************************************************
=head2 users_screens_list($attr) - List all users screens

  Arguments:
    $attr
      SERICE_ID

  Returns:
    $list

=cut
#**********************************************************
sub users_screens_list{
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;
  my $GROUP_BY = '';

  my $WHERE = $self->search_former(
    $attr,
    [
      [ 'LOGIN',            'STR',  'u.id', 'u.id AS login'                                     ],
      [ 'NUM',              'INT',  's.num',                                                  1 ],
      [ 'USERS_SERVICE_ID', 'INT',  'us.service_id AS users_service_id',                      1 ],
      [ 'NAME',             'STR',  's.name',                                                 1 ],
      [ 'MONTH_FEE',        'INT',  's.month_fee',                                            1 ],
      [ 'DAY_FEE',          'INT',  's.day_fee',                                              1 ],
      [ 'FILTER_ID',        'STR',  's.filter_id',                                            1 ],
      [ 'TP_ID',            'INT',  's.tp_id',                                                1 ],
      [ 'SERVICE_TP_ID',    'INT',  'service.tp_id',                                          1 ],
      [ 'CID',              'STR',  'us.cid',                                                 1 ],
      [ 'SERIAL',           'STR',  'us.serial',                                              1 ],
      [ 'HARDWARE_ID',      'INT',  'us.hardware_id',                                         1 ],
      [ 'DATE',             'DATE', 'us.date',                                                1 ],
      [ 'UID',              'DATE', 'service.uid',                                            1 ],
      [ 'SCREEN_ID',        'INT',  'us.screen_id',                                           1 ],
      [ 'TP_REDUCTION_FEE', 'INT',  'tp.reduction_fee', 'tp.reduction_fee AS tp_reduction_fee'  ],
    ],
    {
      WHERE             => 1,
      USERS_FIELDS_PRE  => 1,
      USE_USER_PI       => 1,
      SKIP_USERS_FIELDS => [ 'UID' ]
    }
  );

  my $EXT_TABLE = '';
  if ($attr->{SHOW_ASSIGN}) {
    $EXT_TABLE .= 'FROM iptv_users_screens us ';
    $EXT_TABLE .= 'LEFT JOIN iptv_screens s ON (s.num=us.screen_id) ';
    $EXT_TABLE .= 'LEFT JOIN iptv_main service ON (service.id=us.service_id) ';
    $GROUP_BY = 'GROUP BY us.service_id, us.screen_id';
  }
  else {
    my $service_join = $attr->{SERVICE_ID} ? "AND service.id='$attr->{SERVICE_ID}'" : '';
    $WHERE .= $WHERE ? " AND us.service_id<>0" : "us.service_id<>0" unless $attr->{SERVICE_ID};
    $GROUP_BY = 'GROUP BY us.service_id, us.screen_id';

    $EXT_TABLE .= 'FROM iptv_screens s ';
    $EXT_TABLE .= "LEFT JOIN iptv_main service  ON (s.tp_id=service.tp_id $service_join)";
    $EXT_TABLE .= "LEFT JOIN iptv_users_screens us ON (service.id=us.service_id AND s.num=us.screen_id)";
  }
  $EXT_TABLE .= 'LEFT JOIN users u ON (u.uid=service.uid)';

  $EXT_TABLE .= 'LEFT JOIN tarif_plans tp ON (tp.tp_id=service.tp_id)' if $attr->{TP_REDUCTION_FEE};

  $self->query("SELECT $self->{SEARCH_FIELDS} us.service_id, s.id, service.uid
    $EXT_TABLE
    $WHERE
    $GROUP_BY
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list};

  return $list if $attr->{SKIP_TOTAL};

  if ($self->{TOTAL} > 0 && !$attr->{SHOW_ASSIGN}) {
    $self->query("SELECT COUNT(*) AS total
      $EXT_TABLE
      $WHERE;", undef, { INFO => 1 }
    );
  }

  return $list;
}

#**********************************************************
=head2 users_next_screen($attr)

=cut
#**********************************************************
sub users_next_screen {
  my $self = shift;
  my ($attr) = @_;

  return $self if !$attr->{SERVICE_ID} || !$attr->{TP_ID};

  $self->query("SELECT * FROM iptv_screens
    WHERE tp_id=$attr->{TP_ID} AND num NOT IN(SELECT screen_id FROM iptv_users_screens WHERE service_id=$attr->{SERVICE_ID})
    ORDER BY num
    LIMIT 1",
    undef,
    { COLS_NAME => 1, COLS_UPPER => 1 }
  );

  return defined $self->{list}[0] ? $self->{list}[0] : ();
}

#**********************************************************
=head2 users_active_screens_list($attr)

  Arguments:
    $attr

=cut
#**********************************************************
sub users_active_screens_list {
  my $self = shift;
  my ($attr) = @_;

  $self->query("SELECT us.*,
    s.filter_id
     FROM iptv_users_screens us
    LEFT JOIN iptv_main service  ON (service.id=us.service_id)
    LEFT JOIN iptv_screens s ON  (s.tp_id=service.tp_id AND s.num=us.screen_id)
    WHERE us.service_id = ?;",
    undef,
    { %{$attr}, Bind => [ $attr->{SERVICE} ] }
  );

  return $self->{list};
}

#**********************************************************
=head2 services_list($attr) - list of tp services

  Arguments:
    $attr

=cut
#**********************************************************
sub services_list{
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  my $WHERE = $self->search_former(
    $attr,
    [
      [ 'ID',                  'INT', 'id',                        ],
      [ 'NAME',                'STR', 'name',                    1 ],
      [ 'MODULE',              'STR', 'module',                  1 ],
      [ 'STATUS',              'INT', 'status',                  1 ],
      [ 'COMMENT',             'STR', 'comment',                 1 ],
      [ 'PROVIDER_PORTAL_URL', 'STR', 'provider_portal_url',     1 ],
      [ 'USER_PORTAL',         'INT', 'user_portal',             1 ],
      [ 'SUBSCRIBE_COUNT',     'INT', 'subscribe_count',         1 ],
      [ 'LOGIN',               'INT', 'login',                   1 ],
      [ 'PASSWORD',            'INT', '', "DECODE(nas.mng_password, '$CONF->{secretkey}') AS nas_mng_password" ],
    ],
    {
      WHERE => 1,
    }
  );

  $self->query( "SELECT $self->{SEARCH_FIELDS} s.id
   FROM iptv_services s
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
sub services_add{
  my $self = shift;
  my ($attr) = @_;

  $attr->{PASSWORD} = "ENCODE('$attr->{PASSWORD}', '$self->{conf}->{secretkey}')"  if $attr->{PASSWORD};

  $self->query_add('iptv_services', $attr);

  return $self;
}

#**********************************************************
=head2 screen_change($attr)

=cut
#**********************************************************
sub services_change{
  my $self = shift;
  my ($attr) = @_;

  $attr->{USER_PORTAL} //= 0;
  $attr->{DISABLE} //= 0;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'iptv_services',
    DATA         => $attr
  });

  return $self;
}

#**********************************************************
=head2 screen_del($id, $attr)

=cut
#**********************************************************
sub services_del{
  my $self = shift;
  my ($id, $attr) = @_;

  $self->query_del( 'iptv_services', $attr, { ID => $id } );

  return $self;
}

#**********************************************************
=head2 screen_info($id)

  Arguments:
    $id  - Service ID

=cut
#**********************************************************
sub services_info{
  my $self = shift;
  my ($id) = @_;

  $self->query( "SELECT iptv_services.*,
     DECODE(password, '$CONF->{secretkey}') AS password
    FROM iptv_services
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
=head2 services_reports()

=cut
#**********************************************************
sub services_reports{
  my $self = shift;
  my($attr)=@_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  $self->query( "SELECT service.service_id,
     s.name,
     COUNT(DISTINCT service.uid) AS users,
     SUM(IF(service.disable=0, 1, 0)) AS active,
     COUNT(service.id) AS total
  FROM iptv_main service
  LEFT JOIN iptv_services s ON (service.service_id=s.id)
  GROUP BY service.service_id
  ORDER BY $SORT $DESC;",
    undef,
    $attr
  );

  my $list = $self->{list};

  $self->query( "SELECT
     COUNT(s.id) AS subscribes,
     SUM(IF(service.disable=0, 1, 0)) AS total_active_users,
     COUNT(DISTINCT service.uid) AS total_users
  FROM iptv_main service
  LEFT JOIN iptv_services s ON (service.service_id=s.id)
  ",
    undef,
    { INFO => 1 }
  );

  return $list;
}

#**********************************************************
=head2 device_add($attr) - Add user

=cut
#**********************************************************
sub device_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add( 'iptv_devices', $attr );

  return $self;
}

#**********************************************************
=head2 device_info($attr)

=cut
#**********************************************************
sub device_info {
  my $self = shift;
  my ($attr) = @_;

  $self->query( "SELECT * FROM iptv_devices
    WHERE service_id=$attr->{SERVICE_ID} AND dev_id=\"$attr->{DEVICE_ID}\"",
    undef,
    {
      INFO => 1,
    }
  );

  return $self;
}

#**********************************************************
=head2 device_list($attr)

=cut
#**********************************************************
sub device_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  my $WHERE = $self->search_former(
    $attr,
    [
      [ 'UID',          'INT',  'd.uid',         1 ],
      [ 'DEV_ID',       'INT',  'dev_id',        1 ],
      [ 'ENABLE',       'INT',  'enable',        1 ],
      [ 'DATE_ACTIVITY','DATE', 'date_activity', 1 ],
      [ 'IP_ACTIVITY',  'STR',  'ip_activity',   1 ],
      [ 'CODE',         'STR',  'code',          1 ],
      [ 'ID',           'INT',  'd.id',            ],
      [ 'SERVICE_ID',   'INT',  'service_id',    1 ],
    ],
    {
      WHERE => 1,
    }
  );

  if ($attr->{USERS}) {
    $self->query( "SELECT $self->{SEARCH_FIELDS} d.id,
    u.id as LOGIN
   FROM iptv_main d
    LEFT JOIN users u ON (d.uid=u.uid)
    $WHERE
    GROUP BY d.uid
    ORDER BY $SORT $DESC",
      undef,
      {%$attr, COLS_NAME => 1, COLS_UPPER => 1}
    );
  }
  else {
    $self->query( "SELECT $self->{SEARCH_FIELDS} d.id,
    s.name,
    u.id as LOGIN
   FROM iptv_devices d
    INNER JOIN iptv_services s ON (d.service_id=s.id)
    LEFT JOIN users u ON (d.uid=u.uid)
    $WHERE
    GROUP BY d.id
    ORDER BY $SORT $DESC",
      undef,
      {%$attr, COLS_NAME => 1, COLS_UPPER => 1}
    );
  }

  my $list = $self->{list} || [];

  return $list;
}

#**********************************************************
=head2 device_del($id, $attr)

=cut
#**********************************************************
sub device_del{
  my $self = shift;
  my ($id, $attr) = @_;

  $self->query_del( 'iptv_devices', $attr, { ID => $id } );

  return $self;
}

#**********************************************************
=head2 device_change($attr)

=cut
#**********************************************************
sub device_change{
  my $self = shift;
  my ($attr) = @_;

  $self->changes(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'iptv_devices',
      DATA         => $attr
    }
  );

  return $self;
}

#**********************************************************
=head2 extra_params_add($attr) - Add user

=cut
#**********************************************************
sub extra_params_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add( 'iptv_extra_params', $attr );

  return $self;
}

#**********************************************************
=head2 extra_params_info($attr)

=cut
#**********************************************************
sub extra_params_info {
  my $self = shift;
  my ($attr) = @_;

  $self->query( "SELECT * FROM iptv_extra_params
    WHERE service_id=$attr->{SERVICE_ID}",
    undef,
    {
      INFO => 1,
    }
  );

  return $self;
}

#**********************************************************
=head2 extra_params_list($attr)

=cut
#**********************************************************
sub extra_params_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  my $WHERE = $self->search_former(
    $attr,
    [
      [ 'BALANCE',      'DOUBLE',  'e.balance',     1 ],
      [ 'SEND_SMS',     'INT',     'e.send_sms',    1 ],
      [ 'SMS_TEXT',     'STR',     'e.sms_text',    1 ],
      [ 'IP_MAC',       'STR',     'e.ip_mac',      1 ],
      [ 'ID',           'INT',     'e.id',          1 ],
      [ 'SERVICE_ID',   'INT',     'e.service_id',  1 ],
      [ 'GROUP_ID',     'INT',     'e.group_id',    1 ],
      [ 'TP_ID',        'INT',     'e.tp_id',       1 ],
      [ 'MAX_DEVICE',   'INT',     'e.max_device',  1 ],
      [ 'PIN',          'STR',     'e.pin',         1 ],
    ],
    {
      WHERE => 1,
    }
  );

  $self->query("SELECT $self->{SEARCH_FIELDS}
    s.name as SERVICE_NAME,
    s.module as SERVICE_MODULE,
    g.name as GROUP_NAME,
    t.name as TP_NAME
   FROM `iptv_extra_params` e
    LEFT JOIN `iptv_services` s ON (e.service_id=s.id)
    LEFT JOIN `groups` g ON (e.group_id=g.gid)
    LEFT JOIN `tarif_plans` t ON (e.tp_id=t.tp_id)
    $WHERE
    ORDER BY $SORT $DESC",
    undef,
    { %$attr, COLS_NAME => 1, COLS_UPPER => 1 }
  );

  my $list = $self->{list} || [];

  return $list;
}

#**********************************************************
=head2 extra_params_del($id, $attr)

=cut
#**********************************************************
sub extra_params_del{
  my $self = shift;
  my ($id, $attr) = @_;

  $self->query_del( 'iptv_extra_params', $attr, { ID => $id } );

  return $self;
}

#**********************************************************
=head2 extra_params_change($attr)

=cut
#**********************************************************
sub extra_params_change{
  my $self = shift;
  my ($attr) = @_;

  $self->changes(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'iptv_extra_params',
      DATA         => $attr
    }
  );

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

  $attr->{IPTV_EXPIRE} = POSIX::strftime("%Y-%m-%d", localtime(time + 86400 * $Tariffs->{AGE}));

  eval { require Date::Calc };
  if (!$@) {
    Date::Calc->import( qw/Add_Delta_Days/ );

    my (undef, undef, undef,$mday,$mon,$year,undef,undef,undef) = localtime(time);
    $year += 1900;
    $mon++;
    ($year,$mon,$mday) = Date::Calc::Add_Delta_Days($year, $mon, $mday, $Tariffs->{AGE});
    $attr->{IPTV_EXPIRE} ="$year-$mon-$mday";
  }

  return $self;
}

#**********************************************************
=head2 users_fees($id)

  Arguments:

=cut
#**********************************************************
sub users_fees{
  my $self = shift;
  my ($attr) = @_;

  return [] if !$attr->{FROM_DATE} || !$attr->{TP_NAME} || !$attr->{TP_ID} || !$attr->{TO_DATE};

  $self->query("SELECT im.uid AS UID, u.id AS LOGIN, im.registration  AS Registration, COUNT(distinct case when date<'$attr->{TO_DATE}' then date end) AS Pays_date,
    GROUP_CONCAT(DISTINCT DATE_FORMAT(f.date, '%Y-%m-%d')) AS Pays_dates,
    TO_DAYS('$attr->{TO_DATE}') - TO_DAYS((case when (im.registration<'$attr->{FROM_DATE}') then '$attr->{FROM_DATE}' else im.registration end)) AS COUNT_DAYS_OF_REGISTRATION,
    f.dsc
    FROM iptv_main im
    LEFT JOIN fees f ON(f.uid=im.uid)
    LEFT JOIN users u ON(im.uid=u.uid)
    WHERE im.tp_id=$attr->{TP_ID} AND f.date>=im.registration AND f.date>='$attr->{FROM_DATE}' AND im.disable=0 AND u.disable=0
      AND f.dsc LIKE 'Телевидение:%$attr->{TP_NAME}%'
    GROUP BY f.uid
    HAVING Pays_date <> COUNT_DAYS_OF_REGISTRATION
    ORDER BY im.registration", undef, { COLS_NAME => 1}
  );

  return $self->{list};
}

#**********************************************************
=head2 iptv_users_fees_by_service($id)

  Arguments:

=cut
#**********************************************************
sub iptv_users_fees_by_service{
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{sort}) ? $attr->{sort} : 'f.date';
  $DESC = (defined $attr->{desc}) ? $attr->{desc} : 'DESC';

  return [] if !$attr->{TP_NAMES} || !$attr->{TP_NAMES}[0];

  $attr->{DESCRIBE} ||= 'Телевидение:';
  my $like_statements = "f.dsc LIKE '$attr->{DESCRIBE}%$attr->{TP_NAMES}[0]%'";
  shift @{$attr->{TP_NAMES}};
  map $like_statements .= " OR f.dsc LIKE '$attr->{DESCRIBE}%$_%'", @{$attr->{TP_NAMES}};

  my $WHERE = "WHERE ($like_statements)";

  if ($attr->{FROM_DATE} && $attr->{TO_DATE}) {
    $WHERE .= " AND f.date>='$attr->{FROM_DATE}' AND f.date<='$attr->{TO_DATE}'";
  }
  
  $self->query("SELECT u.id AS login, f.date, f.sum, f.dsc, f.uid AS uid
    FROM fees f
    LEFT JOIN users u ON(f.uid=u.uid)
    $WHERE ORDER BY $SORT $DESC",
    undef, { COLS_NAME => 1}
  );

  return $self->{list};
}

#**********************************************************
=head2 iptv_get_channels_by_service($id)

  Arguments:

=cut
#**********************************************************
sub iptv_get_channels_by_service {
  my $self = shift;
  my ($attr) = @_;

  return [] if !$attr->{SERVICE_ID};

  $self->query("SELECT
   c.num AS channel_num,
   c.name,
   c.comments,
   ic.month_price,
   ic.day_price,
   ic.mandatory,
   ic.interval_id,
   c.port,
   c.disable,
   i.tp_id,
   c.id AS channel_id
     FROM iptv_channels c
     LEFT JOIN iptv_ti_channels ic ON (id=ic.channel_id)
     INNER JOIN intervals i ON (ic.interval_id=i.id)
     INNER JOIN tarif_plans tp ON (i.tp_id=tp.tp_id AND tp.service_id=$attr->{SERVICE_ID})
   GROUP BY c.name",
    undef, { COLS_NAME => 1}
  );

  return $self->{list};
}

#**********************************************************
=head2 iptv_promotion_tps()

=cut
#**********************************************************
sub iptv_promotion_tps {
  my $self = shift;

  $self->query("SELECT t.tp_id, t.id, t.name, t.comments, s.module, s.id AS service_id, t.name AS tp_name, t.month_fee, t.day_fee
    FROM  tarif_plans t
    LEFT JOIN iptv_services s ON (s.id = t.service_id)
      WHERE t.promotional <> 0 AND t.module = 'Iptv'
    GROUP BY t.tp_id",
    undef, { COLS_NAME => 1 }
  );

  return $self->{list} || [];
}

1;
