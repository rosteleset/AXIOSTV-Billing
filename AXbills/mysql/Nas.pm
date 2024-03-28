package Nas;

=head1 NAME

  NAS Server configuration and managing

=cut

use strict;
use parent 'main';
my $SECRETKEY = '';
my $IPV6 = 0;
my $admin;

#**********************************************************
# new
#**********************************************************
sub new {
  my $class = shift;
  my $db    = shift;
  my $CONF  = shift;
  $admin    = shift;

  $SECRETKEY = (defined($CONF->{secretkey})) ? $CONF->{secretkey} : '';

  if($CONF->{IPV6}) {
    $IPV6 = 1;
  }

  my $self = {};
  bless($self, $class);

  $self->{db}    = $db;
  $self->{conf}  = $CONF;
  $self->{admin} = $admin if ($admin);

  $CONF->{BUILD_DELIMITER} = ', ' if (!defined($CONF->{BUILD_DELIMITER}));

  return $self;
}

#**********************************************************
=head2 list($attr)

=cut
#**********************************************************
sub list {
  my $self = shift;
  my ($attr) = @_;

  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;
  my $SORT      = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC      = ($attr->{DESC}) ? $attr->{DESC} : '';

  delete($self->{COL_NAMES_ARR});

  my $EXT_TABLES = '';
  my $build_delimiter = $attr->{BUILD_DELIMITER} || $self->{conf}{BUILD_DELIMITER} || ', ';

  my $WHERE =  $self->search_former($attr, [
      ['NAS_ID',           'INT', 'nas.id',      'nas.id AS nas_id'      ],
      ['NAS_NAME',         'STR', 'nas.name',    'nas.name AS nas_name'  ],
      ['NAS_IDENTIFIER',   'STR', 'nas.nas_identifier',                1 ],
      ['NAS_IP',           'IP',  'nas.ip',      'INET_NTOA(ip) AS ip'   ],
      ['NAS_TYPE',         'STR', 'nas.nas_type',                      1 ],
      ['DISABLE',          'INT', 'nas.disable',                       1 ],
      ['DESCR',            'STR', 'nas.descr',                         1 ],
      ['NAS_GROUP_NAME',   'STR', 'ng.name',  'ng.name AS nas_group_name'],
      ['ALIVE',            'INT', 'nas.alive',                         1 ],
      ['DOMAIN_ID',        'INT', 'nas.domain_id',                     1 ],
      ['MAC',              'INT', 'nas.mac',                           1 ],
      ['GID',              'INT', 'nas.gid',                           1 ],
      ['DISTRICT_ID',      'INT', 'streets.district_id', 'districts.name'],
      ['LOCATION_ID',      'INT', 'nas.location_id',                   1 ],
      #['MNG_HOST_PORT',    'STR', 'nas.mng_host_port', 'nas.mng_host_port AS nas_mng_ip_port', ],
      #['MNG_USER',         'STR', 'nas.mng_user', 'nas.mng_user AS nas_mng_user', ],
      ['NAS_MNG_HOST_PORT','STR', 'nas.mng_host_port', 'nas.mng_host_port AS nas_mng_ip_port' ],
      ['NAS_MNG_USER',     'STR', 'nas.mng_user', 'nas.mng_user AS nas_mng_user',       ],
      ['NAS_MNG_PASSWORD', 'STR', '',    "DECODE(nas.mng_password, '$SECRETKEY') AS nas_mng_password"],
      ['NAS_RAD_PAIRS',    'STR', 'nas.rad_pairs', 'nas.rad_pairs AS nas_rad_pairs'     ],
      ['SHOW_MAPS_GOOGLE', 'SHOW_MAPS_GOOGLE', 'builds.coordx, builds.coordy'           ],
      ['NAS_IDS',          'INT', 'nas.id'                                              ],
      ['NAS_FLOOR',        'STR', 'nas.floor',          'nas.floor AS nas_floor'        ],
      ['NAS_ENTRANCE',     'STR', 'nas.entrance',      'nas.entrance AS nas_entrance'   ],
      ['ADDRESS_FULL',     'STR', "CONCAT(" . ($self->{conf}{ADDRESS_FULL_SHOW_DISTRICT} ? "districts.name, '$build_delimiter'," : "") .
        "streets.name, '$build_delimiter', builds.number, '$build_delimiter', nas.address_flat)",
        "CONCAT(" . ($self->{conf}{ADDRESS_FULL_SHOW_DISTRICT} ? "districts.name, '$build_delimiter'," : "") .
          "streets.name, '$build_delimiter', builds.number, '$build_delimiter', nas.address_flat) AS address_full" ],
      ['ZABBIX_HOSTID',  'INT', 'nas.zabbix_hostid', 1 ]
	  
    ],
    { WHERE => 1 }
  );

  if ($attr->{SHOW_MAPS_GOOGLE}) {
    $EXT_TABLES = "INNER JOIN builds ON (builds.id=nas.location_id)";
    if ($attr->{DISTRICT_ID}) {
      $EXT_TABLES .= "LEFT JOIN streets ON (streets.id=builds.street_id)
      LEFT JOIN districts ON (districts.id=streets.district_id) ";
    }
  }
  elsif ($attr->{DISTRICT_ID} || $attr->{ADDRESS_FULL}) {
    $EXT_TABLES = "LEFT JOIN builds ON (builds.id=nas.location_id)";
    $EXT_TABLES .= "LEFT JOIN streets ON (streets.id=builds.street_id)
      LEFT JOIN districts ON (districts.id=streets.district_id) ";
  }

  my $ext_fields = '';

  if (! $attr->{SHORT}) {
    $ext_fields = "nas.id AS nas_id,
    nas.name AS nas_name,
    nas.nas_identifier,
    INET_NTOA(nas.ip) AS nas_ip,
    nas.nas_type,
    ng.name as nas_group_name,
    nas.disable as nas_disable,
    nas.descr,
    nas.alive as nas_alive,
    nas.mng_host_port as nas_mng_ip_port,
    nas.mng_user as nas_mng_user,
    DECODE(nas.mng_password, '$SECRETKEY') AS nas_mng_password,
    nas.rad_pairs as nas_rad_pairs,
    nas.ext_acct,
    nas.auth_type,";
  }

  if ($attr->{USED_PORTS}) {     
     $ext_fields .= " (SELECT COUNT(*) FROM internet_main im WHERE im.nas_id = nas.id) as used_ports,";
  }

  $self->query2(
    "SELECT
      $ext_fields
      $self->{SEARCH_FIELDS}
      nas.mac,
      nas.id
    FROM nas
    LEFT JOIN nas_groups ng ON (ng.id=nas.gid)
    $EXT_TABLES
    $WHERE
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list};
  if ($self->{TOTAL} >= 0 && !$attr->{SKIP_TOTAL}) {
    $self->query2("SELECT COUNT(*) AS total
    FROM nas
    LEFT JOIN nas_groups ng ON (ng.id=nas.gid)
    $EXT_TABLES
    $WHERE",
      undef,
      { INFO => 1 }
    );
  }

  return $list || [];
}

#***************************************************************
=head2 info($attr)

  Arguments:
    NAS_ID
    IP
    CALLED_STATION_ID

  Returns:
    NAS_INFO

=cut
#***************************************************************
sub info {
  my $self = shift;
  my ($attr) = @_;

  my $WHERE = '';

  if ($attr->{IP}) {
    $WHERE = "ip=INET_ATON('$attr->{IP}')";
    if ($attr->{NAS_IDENTIFIER}) {
      $WHERE .= " AND (nas_identifier='$attr->{NAS_IDENTIFIER}' or nas_identifier='')";
    }
    else {
      $WHERE .= " AND nas_identifier=''";
    }
  }
  elsif ($attr->{CALLED_STATION_ID}) {
    $WHERE = "mac='$attr->{CALLED_STATION_ID}'";
  }
  else {
    $WHERE = "id='$attr->{NAS_ID}'";
  }

  my $fields = '';

  if ( ! $attr->{SHORT}) {
    $fields = " ,name AS nas_name,
    descr AS nas_describe,
    mng_host_port AS nas_mng_ip_port,
    mng_host_port AS nas_mng_host_port,
    mng_user AS nas_mng_user,
    nas.*,
    DECODE(mng_password, '$SECRETKEY') AS nas_mng_password
  ";
  }

  $self->query2(
    "SELECT id as nas_id,
      nas_identifier,
      INET_NTOA(ip) AS nas_ip,
      nas_type,
      auth_type AS nas_auth_type,
      alive AS nas_alive,
      disable AS nas_disable,
      ext_acct AS nas_ext_acct,
      rad_pairs AS nas_rad_pairs,
      mac,
      domain_id
      $fields
    FROM nas
    WHERE $WHERE;",
    undef,
    { INFO => 1 }
  );

  if (! $self->{errno} && $self->{LOCATION_ID}) {
    $self->query2(
      "SELECT
        d.id AS district_id,
        d.city,
        d.name AS address_district,
        s.name AS address_street,
        b.number AS address_build
      FROM builds b
      LEFT JOIN streets s ON (s.id=b.street_id)
      LEFT JOIN districts d ON (d.id=s.district_id)
      WHERE b.id='$self->{LOCATION_ID}'",
      undef,
      { INFO => 1 }
    );

    if ($self->{errno} && $self->{errno} == 2) {
      delete $self->{errno};
    }
  }
  return $self;
}

#**********************************************************
=head2 change($attr)

=cut
#**********************************************************
sub change {
  my $self = shift;
  my ($attr) = @_;

  $attr->{NAS_DISABLE} = ($attr->{NAS_DISABLE}) ? 1 : 0;


  my %FIELDS = (
    NAS_ID           => 'id',
    NAS_NAME         => 'name',
    NAS_IDENTIFIER   => 'nas_identifier',
    NAS_DESCRIBE     => 'descr',
    IP               => 'ip',
    NAS_TYPE         => 'nas_type',
    NAS_AUTH_TYPE    => 'auth_type',
    NAS_MNG_IP_PORT  => 'mng_host_port',
    NAS_MNG_HOST_PORT=> 'mng_host_port',
    NAS_MNG_USER     => 'mng_user',
    NAS_MNG_PASSWORD => 'mng_password',
    NAS_RAD_PAIRS    => 'rad_pairs',
    NAS_ALIVE        => 'alive',
    NAS_DISABLE      => 'disable',
    NAS_EXT_ACCT     => 'ext_acct',
    ADDRESS_BUILD    => 'address_build',
    ADDRESS_STREET   => 'address_street',
    ADDRESS_FLAT     => 'address_flat',
    ZIP              => 'zip',
    CITY             => 'city',
    COUNTRY          => 'country',
    DOMAIN_ID        => 'domain_id',
    GID              => 'gid',
    MAC              => 'mac',
    CHANGED          => 'changed',
    LOCATION_ID      => 'location_id',
    FLOOR            => 'floor',
    ENTRANCE         => 'entrance',
    ZABBIX_HOSTID    => 'zabbix_hostid',
  );

  $attr->{CHANGED} = 1;
  $admin->{MODULE} = '';

  if(! $attr->{NAS_MNG_PASSWORD}) {
    delete $attr->{NAS_MNG_PASSWORD};
  }

  if ($attr->{STREET_ID} && $attr->{ADD_ADDRESS_BUILD} && ! $attr->{LOCATION_ID}) {
    require Address;
    Address->import();

    my $Address = Address->new($self->{db}, $admin, $self->{conf});

    $Address->build_add($attr);
    $attr->{LOCATION_ID}=$Address->{LOCATION_ID};
  }

  $self->changes2({
    CHANGE_PARAM    => 'NAS_ID',
    TABLE           => 'nas',
    FIELDS          => \%FIELDS,
    OLD_INFO        => $self->info({ NAS_ID => $self->{NAS_ID} || $attr->{NAS_ID} }),
    DATA            => $attr,
    EXT_CHANGE_INFO => "NAS_ID:$self->{NAS_ID}"
  });

  if (! $self->{errno}) {
    $self->info({ NAS_ID => $self->{NAS_ID} });
  }

  return $self;
}

#**********************************************************
=head2 add($attr) - Add nas server

=cut
#**********************************************************
sub add {
  my $self = shift;
  my ($attr) = @_;

  if($admin && $admin->{DOMAIN_ID}) {
    $attr->{DOMAIN_ID} = $admin->{DOMAIN_ID};
  }

  if ($attr->{STREET_ID} && $attr->{ADD_ADDRESS_BUILD} && ! $attr->{LOCATION_ID}) {
    require Address;
    Address->import();

    my $Address = Address->new($self->{db}, $admin, $self->{conf});

    $Address->build_add($attr);
    $attr->{LOCATION_ID}=$Address->{LOCATION_ID};
  }

  $self->query_add('nas', {
    %$attr,
    NAME           => $attr->{NAS_NAME},
    DESCR          => $attr->{NAS_DESCRIBE},
    AUTH_TYPE      => $attr->{NAS_AUTH_TYPE},
    MNG_HOST_PORT  => $attr->{NAS_MNG_HOST_PORT},
    MNG_USER       => $attr->{NAS_MNG_USER},
    MNG_PASSWORD   => ($attr->{NAS_MNG_PASSWORD}) ? "ENCODE('$attr->{NAS_MNG_PASSWORD}', '$SECRETKEY')" : undef,
    RAD_PAIRS      => $attr->{NAS_RAD_PAIRS} || '',
    ALIVE          => $attr->{NAS_ALIVE} || 0,
    DISABLE        => $attr->{NAS_DISABLE},
    EXT_ACCT       => $attr->{NAS_EXT_ACCT},
  });

  $self->{NAS_ID}=$self->{INSERT_ID};

  if ($attr->{ACTION_ADMIN}) {
    return $self;
  }

  $admin->system_action_add("NAS_ID: $self->{NAS_ID}", { TYPE => 1 });

  return $self;
}

#**********************************************************
=head2 del($id) - Del nas server

=cut
#**********************************************************
sub del {
  my $self = shift;
  my ($id) = @_;

  $self->query_del('nas', undef,  { id => $id });
  $self->{nas_deleted} = $self->{AFFECTED};
  $self->query_del('nas_ippools', undef, { nas_id => $id });

  $admin->system_action_add("NAS_ID:$id", { TYPE => 10 });

  return $self;
}

#**********************************************************
=head2 users_list($nas_id, $attr) - retrieves users bound to this $nas_id

  Arguments:
    - $nas_id
    - $attr

  Returns:
    list

=cut
#**********************************************************
sub users_list {
  my ( $self, $nas_id, $attr ) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  my $WHERE =  $self->search_former($attr, [
      ['NAS_ID',  'INT', 'nas_id'],
      ['UID',     'INT', 'uid'   ],
    ],
    { WHERE => 1 }
  );

  $self->query2("SELECT uid, nas_id
    FROM users_nas
    $WHERE
    ORDER BY $SORT $DESC",
    undef,
    $attr
  );

  return $self->{list} || [];
}

#**********************************************************
=head2 nas_ip_pools_list($attr)

=cut
#**********************************************************
sub nas_ip_pools_list {
  my ($self, $attr) = @_;

  my $SORT      = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC      = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;
  my $PG        = ($attr->{PG}) ? $attr->{PG} : 0;

  # This should go first to keep internal global flags for $self
  my @WHERE_NAS_RULES = ('np.pool_id=pool.id');
  my $WHERE_NAS = $self->search_former($attr, [
      ['NAS_ID', 'INT', 'np.nas_id'  ],
      ['STATIC', 'INT', 'pool.static'],
    ],
    {
      WHERE_RULES => \@WHERE_NAS_RULES
    }
  );

  my $search_columns = [
    [ 'ID',                 'INT', 'pool.id',                                               1],
    [ 'NAS_NAME',           'STR', 'n.name AS nas_name',                                    1],
    [ 'POOL_NAME',          'STR', 'pool.name AS pool_name',                                1],
    [ 'FIRST_IP',           'IP',  'INET_NTOA(pool.ip) AS first_ip',                        1],
    [ 'LAST_IP',            'IP',  'INET_NTOA(pool.ip + if(pool.counts > 0, pool.counts - 1, 0)) AS last_ip',     1],
    [ 'IP',                 'INT', 'pool.ip',                                               1],
    [ 'LAST_IP_NUM',        'INT', '(pool.ip + if(pool.counts > 0, pool.counts - 1, 0)) AS last_ip_num',          1],
    [ 'IP_COUNT',           'INT', 'pool.counts AS ip_count',                               1],
    [ 'INTERNET_IP_FREE',   'INT', '(pool.counts - (SELECT if(COUNT(*) > pool.counts, pool.counts, COUNT(*)) FROM internet_main internet
      WHERE internet.ip >= pool.ip AND internet.ip < pool.ip + pool.counts AND uid > 0 )) AS internet_ip_free', 1],
    [ 'INTERNET_DYNAMIC_IP_FREE',   'INT', '(pool.counts - (SELECT if(COUNT(*) > pool.counts, pool.counts, COUNT(*)) FROM internet_online online
      WHERE online.framed_ip_address >= pool.ip AND online.framed_ip_address < pool.ip + pool.counts )) AS internet_dynamic_ip_free', 1],
    [ 'PRIORITY',           'INT', 'pool.priority',                                         1],
    [ 'SPEED',              'INT', 'pool.speed',                                            1],
    [ 'NAME',               'STR', 'pool.name AS name',                                     1],
    [ 'NAS',                'INT', 'np.nas_id',                                             1],
    [ 'NETMASK',            'IP',  'pool.netmask',                                          1],
    [ 'GATEWAY',            'IP',  'pool.gateway',                                          1],
    [ 'STATIC',             'INT', 'pool.static',                                           1],
    [ 'ACTIVE_NAS_ID',      'INT', 'IF(np.nas_id IS NULL, 0, np.nas_id) AS active_nas_id',  1],
    [ 'IP_SKIP',            'STR', 'pool.ip_skip',                                          1],
    [ 'COMMENTS',           'STR', 'pool.comments',                                         1],
    [ 'DNS',                'STR', 'pool.dns',                                              1],
    [ 'VLAN',               'INT', 'pool.vlan',                                             1],
    [ 'GUEST',              'INT', 'pool.guest',                                            1],
    [ 'NEXT_POOL',          'INT', 'pool.next_pool_id AS next_pool',                        1],
  ];

  if ($IPV6) {
    push @$search_columns, (
      [ 'IPV6_PREFIX',        'STR', 'INET6_NTOA(pool.ipv6_prefix) AS ipv6_prefix',           1],
      [ 'IPV6_MASK',          'IP',  'pool.ipv6_mask',                                        1],
      [ 'IPV6_TEMP',          'STR', 'pool.ipv6_template AS ipv6_temp',                       1],
      [ 'IPV6_PD',            'STR', 'INET6_NTOA(pool.ipv6_pd) AS ipv6_pd',                   1],
      [ 'IPV6_PD_MASK',       'STR', 'pool.ipv6_pd_mask',                                     1],
      [ 'IPV6_PD_TEMP',       'STR', 'pool.ipv6_pd_template AS ipv6_pd_temp',                 1],
    );
  }

  if ($attr->{SHOW_ALL_COLUMNS}){
    map { $attr->{$_->[0]} = '_SHOW' unless (exists $attr->{$_->[0]}) } @$search_columns;
  }

  my $WHERE = $self->search_former($attr, $search_columns,{WHERE => 1});

  $self->query2("SELECT $self->{SEARCH_FIELDS} pool.id
    FROM ippools pool
    LEFT JOIN nas_ippools np ON ($WHERE_NAS)
    LEFT JOIN nas n ON (n.id=np.nas_id)
    $WHERE
      GROUP BY pool.id
      ORDER BY $SORT $DESC
      LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list};

  return [] if ($self->{TOTAL} < 1);

  $self->query2(
    "SELECT COUNT(*) AS total
    FROM ippools pool
    $WHERE",
    undef,
    { INFO => 1 }
  );

  return $list;
}

#**********************************************************
=head2 nas_ip_pools_add($attr) add NAS IP Pools

=cut
#**********************************************************
sub nas_ip_pools_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('nas_ippools', $attr, { REPLACE => 1 });

  $admin->system_action_add(
    "NAS_IP_POOL_ADD:$self->{INSERT_ID}",
    { TYPE => 1 }
  );

  return $self;
}

#**********************************************************
=head2 nas_ip_pools_del($attr) delete NAS IP Pools

=cut
#**********************************************************
sub nas_ip_pools_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('nas_ippools', undef, $attr);

  $admin->system_action_add(
    "NAS_IP_POOL_DELETE:NAS_ID" . ($attr->{NAS_ID} || q{}) . ",POOL_ID" . ($attr->{POOL_ID} || q{}),
    { TYPE => 10 }
  );

  return $self;
}

#**********************************************************
=head2 nas_ip_pools_set($attr) NAS IP Pools

=cut
#**********************************************************
sub nas_ip_pools_set {
  my $self = shift;
  my ($attr) = @_;

  $self->query2("DELETE FROM nas_ippools WHERE nas_id = $self->{NAS_ID} AND pool_id IN ($attr->{ids_remove}) ;", undef, {  });

  my @MULTI_QUERY = ();

  foreach my $id ( split(/, /, $attr->{ids}) ) {
    push @MULTI_QUERY, [ $id, $attr->{NAS_ID} ] if ($id);
  }

  $self->query2("INSERT INTO nas_ippools (pool_id, nas_id) VALUES (?, ?);",
      undef,
      { MULTI_QUERY =>  \@MULTI_QUERY });

  if($admin) {
    $admin->system_action_add("NAS_ID:$self->{NAS_ID} POOLS:" . (join(',', split(/, /, $attr->{ids}))), { TYPE => 2 });
  }

  return $self;
}

#**********************************************************
=head2 ip_pools_info($id)

=cut
#**********************************************************
sub ip_pools_info {
  my $self = shift;
  my $id = shift;
  my ($attr) = @_;

  my $EXT_FIELDS = ($IPV6) ? ", INET6_NTOA(ipv6_prefix) AS ipv6_prefix, INET6_NTOA(ipv6_pd) AS ipv6_pd" : '';
  $EXT_FIELDS .= ', (ippools.counts - (SELECT if(COUNT(*) > ippools.counts, ippools.counts, COUNT(*)) FROM internet_main internet
      WHERE internet.ip >= ippools.ip AND internet.ip < ippools.ip + ippools.counts )) AS internet_ip_free' if $attr->{INTERNET_IP_FREE};

  $self->query2("SELECT *,
      INET_NTOA(ip) AS ip
      $EXT_FIELDS
    FROM ippools  WHERE id= ? ;",
    undef,
    { INFO => 1,
      Bind => [ $id ] }
  );

  return $self;
}

#**********************************************************
=head2 ip_pools_change($attr) - NAS IP Pools change

=cut
#**********************************************************
sub ip_pools_change {
  my $self = shift;
  my ($attr) = @_;

  $attr->{STATIC} = ($attr->{STATIC}) ? $attr->{STATIC} : 0;
  $attr->{GUEST} = ($attr->{GUEST}) ? $attr->{GUEST} : 0;

  $self->changes2(
    {
      CHANGE_PARAM    => 'ID',
      TABLE           => 'ippools',
      DATA            => $attr,
      EXT_CHANGE_INFO => "POOL:$attr->{ID}"
    }
  );

  return $self;
}

#**********************************************************
=head2 ip_pools_list($attr)

  Arguments:
    $attr
      STATIC  - Show static pools
      IPV6    - Show ipv6 prefix

  Results:

=cut
#**********************************************************
sub ip_pools_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  my @WHERE_RULES = ();

  if($attr->{DOMAIN_ID}) {
    push @WHERE_RULES, "pool.domain_id='$attr->{DOMAIN_ID}'";
  }

  if (defined($attr->{STATIC})) {
    if($attr->{IPV6}) {
      push @WHERE_RULES, "pool.ipv6_prefix<>''";
    }

    push @WHERE_RULES, "pool.static IN ($attr->{STATIC})";

    my $WHERE = ($#WHERE_RULES > -1) ? join(' AND ', @WHERE_RULES) : '';

    $self->query2(
      "SELECT
        '',
        pool.name,
        pool.ip,
        pool.ip + pool.counts AS last_ip_num,
        pool.counts,
        pool.priority,
        INET_NTOA(pool.ip) AS first_ip,
        INET_NTOA(pool.ip + pool.counts) AS last_ip,
        pool.id,
        pool.nas,
        pool.netmask as netmask,
        pool.gateway,
        pool.dns
      FROM ippools pool
      WHERE $WHERE  ORDER BY $SORT $DESC",
      undef,
      $attr
    );

    return $self->{list} || [];
  }

  if (defined($self->{NAS_ID})) {
    push @WHERE_RULES, "pool.nas='$self->{NAS_ID}'";
  }

  my $WHERE = ($#WHERE_RULES > -1) ? "and " . join(' AND ', @WHERE_RULES) : '';

  $self->query2(
    "SELECT
      nas.name,
      pool.name,
      pool.ip,
      pool.ip + pool.counts AS last_ip_num,
      pool.counts, pool.priority,
      INET_NTOA(pool.ip) AS first_ip,
      INET_NTOA(pool.ip + pool.counts - 1) AS last_ip,
      pool.id,
      pool.nas,
      pool.gateway,
      pool.netmask as netmask
    FROM ippools pool, nas
    WHERE pool.nas=nas.id
    $WHERE  ORDER BY $SORT $DESC",
    undef,
    $attr
  );

  return $self->{list} || [];
}

#**********************************************************
=head2 ip_pools_add($attr)

=cut
#**********************************************************
sub ip_pools_add {
  my $self   = shift;
  my ($attr) = @_;

  $attr->{IPV6_PREFIX}  = undef if (! $IPV6);

  $self->query_add('ippools', {
    %$attr,
    NAS => undef,
  });

  if($admin) {
    $admin->system_action_add("NAS_ID:$attr->{NAS_ID} POOLS:" . (join(',', split(/, /, $attr->{ids}))), { TYPE => 1 });
  }

  return $self;
}

#**********************************************************
=head2 ip_pools_del()

=cut
#**********************************************************
sub ip_pools_del {
  my $self = shift;
  my ($id) = @_;

  $self->query_del('ippools', { ID => $id });

  $admin->system_action_add("POOL:$id", { TYPE => 10 });

  return $self;
}

#**********************************************************
=head2 stats($attr) - Statistic

  Arguments:
    $attr
      INTERNET

  Returns:
    $list

=cut
#**********************************************************
sub stats {
  my $self = shift;
  my ($attr) = @_;

  my $WHERE = "WHERE DATE_FORMAT(start, '%Y-%m')=DATE_FORMAT(CURDATE(), '%Y-%m')";
  my $SORT  = ($attr->{SORT} && $attr->{SORT} == 1) ? "1,2" : ($attr->{SORT} || 1);
  my $DESC  = ($attr->{DESC})      ? $attr->{DESC} : '';

  if (defined($attr->{NAS_ID})) {
    $WHERE .= "AND id='$attr->{NAS_ID}'";
  }

  my $internet_log_table = 'internet_log';


  $self->query2(
    "SELECT
      n.name,
      l.port_id,
      COUNT(*),
      IF(DATE_FORMAT(MAX(l.start), '%Y-%m-%d')=CURDATE(), DATE_FORMAT(MAX(l.start), '%H-%i-%s'), MAX(l.start)),
      SEC_TO_TIME(AVG(l.duration)), SEC_TO_TIME(MIN(l.duration)), SEC_TO_TIME(MAX(l.duration)),
      l.nas_id
    FROM $internet_log_table l
    LEFT JOIN nas n ON (n.id=l.nas_id)
    $WHERE
    GROUP BY l.nas_id, l.port_id
    ORDER BY $SORT $DESC;"
  );

  return $self->{list} || [];
}

#**********************************************************
=head2 nas_group_list($attr)

=cut
#**********************************************************
sub nas_group_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  my $WHERE = $self->search_former($attr, [
    [ 'DOMAIN_ID',  'INT', 'g.domain_id'                ],
    [ 'NAME',       'STR', 'g.name',                  1 ],
    [ 'COUNTS',     'INT', '', 'COUNT(*) AS counts'     ],
  ], { WHERE => 1 });

  my $EXT_TABLES = '';
  if ($attr->{COUNTS}) {
    $EXT_TABLES =  'LEFT JOIN nas n ON (n.gid=g.id)';
  }

  $self->query2(
    "SELECT
      g.id, g.name,
      g.comments,
      g.disable,
      $self->{SEARCH_FIELDS} g.id AS gid
    FROM nas_groups g
    $EXT_TABLES
    $WHERE
    GROUP BY g.id
    ORDER BY $SORT $DESC;",
    undef,
    $attr
  );

  return $self->{list} || [];
}

#***************************************************************
=head2 nas_group_info($attr);

=cut
#***************************************************************
sub nas_group_info {
  my $self = shift;
  my ($attr) = @_;

  $self->query2("SELECT * FROM nas_groups WHERE id = ?;",
  undef,
  { INFO => 1,
    Bind => [ $attr->{ID} ] }
  );

  return $self;
}

#**********************************************************
=head2 nas_group_change($attr)

=cut
#**********************************************************
sub nas_group_change {
  my $self = shift;
  my ($attr) = @_;

  $attr->{DISABLE} = (defined($attr->{DISABLE})) ? 1 : 0;

  $self->changes2({
    CHANGE_PARAM    => 'ID',
    TABLE           => 'nas_groups',
    DATA            => $attr,
    EXT_CHANGE_INFO => "NAS_GROUP_ID:$self->{ID}"
  });

  $self->nas_group_info({ ID => $attr->{ID} });

  return $self;
}

#**********************************************************
=head2 nas_group_add($attr)

=cut
#**********************************************************
sub nas_group_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('nas_groups', $attr);

  $admin->system_action_add(
    "NAS_GROUP_ID:$self->{INSERT_ID}",
    { TYPE => 1 }
  );

  return $self;
}

#**********************************************************
=head2 nas_group_del()

=cut
#**********************************************************
sub nas_group_del {
  my $self = shift;
  my ($id) = @_;

  $self->query_del('nas_groups', { ID => $id });

  $admin->system_action_add(
    "NAS_GROUP_ID:$id",
    { TYPE => 10 }
  );

  return $self;
}

#**********************************************************
=head2 function add_radtest_query() - add query to datebase

  Arguments:
    $attr

  Returns:
    $self object

  Examples:
    $nas->add_radtest_query({
      COMMENTS   => 'test',
      RAD_QUERY  => 'User-Name=test',
      DATETIME   => 'NOW()'
    });

    $nas->add_radtest_query({
      %FORM
    });

=cut
#**********************************************************
sub add_radtest_query {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('radtest_history', { %$attr });

  return $self;
}

#**********************************************************
=head2 function query_list() - queries list

  Arguments:
    $attr

  Returns:
    $self object

  Examples:
    $query_list = $nas->query_list({COLS_NAME => 1});

=cut
#**********************************************************
sub query_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  my $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  $self->query2(
    "SELECT * FROM `radtest_history`
    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list};

  return [] if ($self->{TOTAL} < 1);

  $self->query2(
    "SELECT COUNT(*) AS total
    FROM radtest_history",
    undef,
    { INFO => 1 }
  );

  return $list;
}

#**********************************************************
=head2 function del_query() - del query from datebase

  Arguments:
    ID   - query identificator

  Returns:
    $self object

  Examples:
    $nas->del_query({ID => $FORM{query_del}});

=cut
#**********************************************************
sub del_query {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('radtest_history', $attr);

  return $self;
}

#***************************************************************
=head2 function query_info() - query info from datebase

  Arguments:
    ID   - query identificator

  Returns:
    $self object

  Examples:
    $nas->query_info({ID => $FORM{query_info}});

=cut
#***************************************************************
sub query_info {
  my $self = shift;
  my ($attr) = @_;

  $self->query2("SELECT * FROM `radtest_history` WHERE id = ?;",
    undef, {
      INFO => 1,
      Bind => [ $attr->{ID} ]
    });

  return $self;
}

#**********************************************************
=head2 function add_radtest_query() - add query to datebase

  Arguments:
    $attr

  Returns:
    $self object

  Examples:
    $nas->nas_cmd_add({
      COMMENTS   => 'test',
      RAD_QUERY  => 'User-Name=test',
      DATETIME   => 'NOW()'
    });

    $nas->nas_cmd_add({
      %FORM
    });

=cut
#**********************************************************
sub nas_cmd_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('nas_cmd', { %$attr });

  return $self;
}

#**********************************************************
=head2 function nas_cmd_del() - del query from datebase

  Arguments:
    ID   - query identificator

  Returns:
    $self object

  Examples:
    $nas->nas_cmd_del({ID => $FORM{del}});

=cut
#**********************************************************
sub nas_cmd_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('nas_cmd', $attr);

  return $self;
}

#***************************************************************
=head2 function nas_cmd_info() - query info from datebase

  Arguments:
    ID   - query identificator

  Returns:
    $self object

  Examples:
    $nas->nas_cmd_info({ID => $FORM{ID}});

=cut
#***************************************************************
sub nas_cmd_info {
  my $self = shift;
  my ($attr) = @_;

  $self->query2("SELECT * FROM nas_cmd WHERE id = ?;",
  undef,
  { INFO => 1,
    Bind => [ $attr->{ID} ] }
  );

  return $self;
}

#**********************************************************
=head2 function nas_cmd_list() - queries list

  Arguments:
    $attr

  Returns:
    $self object

  Examples:
    $cmd_list = $Nas->nas_cmd_list({COLS_NAME => 1});

=cut
#**********************************************************
sub nas_cmd_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  my $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my @WHERE_RULES = ();

  my $WHERE = $self->search_former($attr, [
      ['ID',             'INT',  'id',         1 ],
      ['NAS_ID',         'INT',  'nas_id',     1 ],
      ['CMD',            'STR',  'cmd',        1 ],
      ['TYPE',           'STR',  'type',       1 ],
      ['COMMENTS',       'STR',  'comments',   1 ],
    ],
    {
      WHERE            => 1,
      WHERE_RULES      => \@WHERE_RULES,
    }
  );

  $self->query2(
    "SELECT 
    id,
    nas_id,
    cmd,
    type,
    comments FROM nas_cmd
    $WHERE
    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list};

  return [] if ($self->{TOTAL} < 1);

  $self->query2(
    "SELECT COUNT(*) AS total FROM nas_cmd",
    undef,
    { INFO => 1 }
  );

  return $list;
}

#**********************************************************
=head2 nas_cmd_change($attr)

=cut
#**********************************************************
sub nas_cmd_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes2({
    CHANGE_PARAM => 'ID',
    TABLE        => 'nas_cmd',
    DATA         => $attr,
  });

  return $self;
}


#*******************************************************************
=head2 divide_ips($attr) - divide ip pool to ips

  Arguments:
   $attr:
    FIRST - start of ip pool
    COUNT - count of ips
    POOL_ID - id of ip pool

  Returns:
    1
=cut
#*******************************************************************
sub divide_ips{
  my $self = shift;
  my ($attr) = (@_);

  $self->query2("INSERT INTO ippools_ips (ip, ippool_id)
  SELECT
    (?+TWO_1.SeqValue + TWO_2.SeqValue + TWO_4.SeqValue + TWO_8.SeqValue + TWO_16.SeqValue + TWO_32.SeqValue + TWO_64.SeqValue + TWO_128.SeqValue + TWO_256.SeqValue + TWO_512.SeqValue + TWO_1024.SeqValue + TWO_2048.SeqValue + TWO_4096.SeqValue + TWO_8192.SeqValue + TWO_16384.SeqValue + TWO_32768.SeqValue+ TWO_65536.SeqValue) SeqValue, ?
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
  ORDER BY 1 LIMIT ?;", 'do', {
    Bind => [$attr->{FIRST}, $attr->{POOL_ID}, $attr->{COUNT}],
  });

  return 1;
}


#*******************************************************************
=head2 remove_ippools_ips($POLL_ID) - remove ippools_ips

  Arguments:
    POLL_ID - id of ip pool

  Returns:
    1
=cut
#*******************************************************************
sub remove_ippools_ips{
  my $self = shift;
  my $POLL_ID = shift;

  if ($POLL_ID->{CHG} || $POLL_ID->{DEL}) {
    $self->query2(
      "DELETE FROM ippools_ips WHERE ippool_id = ?",
      undef,
      {
        Bind => [ ($POLL_ID->{CHG} ? $POLL_ID->{CHG} : $POLL_ID->{DEL}) ]
      }
    );
  }
  elsif ($POLL_ID->{IPPOOL_ID} && $POLL_ID->{IP}) {
    $self->query2(
      "DELETE FROM ippools_ips WHERE ippools_ips.ippool_id = ? AND ippools_ips.ip = ?",
      undef,
      {
        Bind => [ $POLL_ID->{IPPOOL_ID}, $POLL_ID->{IP} ]
      }
    );
  }
  return 1;
}

#*******************************************************************
=head2 ippools_ips_list($attr) - list of ippools ips

  Arguments:
    $attr

  Returns:

=cut
#*******************************************************************
sub ippools_ips_list{
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 1000;

  my $WHERE =  $self->search_former($attr, [
    [ 'IP_POOL_ID',           'INT', 'ii.ippool_id',              1 ],
    [ 'IP',                   'INT', 'ii.ip',                     1 ],
    [ 'STATUS',               'INT', 'ii.status',                 1 ],
  ],{
    WHERE => 1
    }
  );

  $self->query2(
    "SELECT
      ii.ippool_id,
      ii.ip,
      ii.status
    FROM ippools_ips ii
    $WHERE
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;",
    undef, $attr
  );

  return $self->{list};
}


1;
