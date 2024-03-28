package Dhcphosts;

=head1 NAME

 DHCP server managment and user control

=cut

use strict;
use parent qw(dbcore);
my $MODULE = 'Dhcphosts';
my Admins $admin;
my $CONF;
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
    db    => $db,
    admin => $admin,
    conf  => $CONF
  };

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 routes_list($attr)

=cut
#**********************************************************
sub routes_list {
  my $self = shift;
  my ($attr) = @_;

  my $WHERE =  $self->search_former($attr, [
      ['NET_ID',    'INT', 'r.network' ],
      ['RID',       'INT', 'r.id'      ],
    ],
    { WHERE => 1,
    }
  );

  $self->query("SELECT
    r.id, r.network, inet_ntoa(r.src),
    INET_NTOA(r.mask) AS netmask,
    inet_ntoa(r.router) AS router,
    n.name
     FROM dhcphosts_routes r
     left join dhcphosts_networks n on r.network=n.id
     $WHERE
     ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  return [ ] if ($self->{errno});

  my $list = $self->{list};

  if ($self->{TOTAL} > 0) {
    $self->query("SELECT count(*) AS total FROM dhcphosts_routes r $WHERE", undef, { INFO => 1 });
  }

  return $list;
}

#**********************************************************
# host_defaults()
#**********************************************************
sub network_defaults {
  my $self = shift;

  my %DATA = (
    ID                   => '0',
    NAME                 => 'DHCP_NET',
    NETWORK              => '0.0.0.0',
    MASK                 => '255.255.255.0',
    BLOCK_NETWORK        => 0,
    BLOCK_MASK           => 0,
    DOMAINNAME           => '',
    DNS                  => '',
    COORDINATOR          => '',
    PHONE                => '',
    ROUTERS              => '',
    DISABLE              => 0,
    OPTION_82            => 0,
    IP_RANGE_FIRST       => '0.0.0.0',
    IP_RANGE_LAST        => '0.0.0.0',
    COMMENTS             => '',
    DENY_UNKNOWN_CLIENTS => 0,
    AUTHORITATIVE        => 0,
    GUEST_VLAN           => 0,
    STATIC               => 0
  );

  $self = \%DATA;
  return $self;
}

#**********************************************************
=head2 network_add($attr)

=cut
#**********************************************************
sub network_add {
  my $self = shift;
  my ($attr) = @_;

  my %DATA = $self->get_data($attr, { default => network_defaults() });

  if($admin->{DOMAIN_ID}) {
    $DATA{DOMAIN_ID} = $admin->{DOMAIN_ID};
  }

  $self->query_add('dhcphosts_networks',
     { %$attr,
     	 NETWORK        => "INET_ATON('$DATA{NETWORK}')",
     	 MASK           => "INET_ATON('$DATA{MASK}')",
     	 ROUTERS        => "INET_ATON('$DATA{ROUTERS}')",
     	 #BLOCK_NETWORK  => "INET_ATON('$DATA{BLOCK_NETWORK}')",
       #BLOCK_MASK     => "INET_ATON('$DATA{BLOCK_MASK}')",
   	   IP_RANGE_FIRST => "INET_ATON('$DATA{IP_RANGE_FIRST}')",
       IP_RANGE_LAST  => "INET_ATON('$DATA{IP_RANGE_LAST}')",
     }
  );

  $admin->system_action_add("DHCPHOSTS_NET:$self->{INSERT_ID}", { TYPE => 1 });

  return $self;
}

#**********************************************************
=head2 network_del($id)

=cut
#**********************************************************
sub network_del {
  my $self = shift;
  my ($id) = @_;

  $self->query_del('dhcphosts_networks', { ID => $id });
  $self->query_del('dhcphosts_hosts', undef, { network => $id });

  $admin->system_action_add("DHCPHOSTS_NET:$id", { TYPE => 10 });
  return $self;
}

#**********************************************************
=head2 network_change($attr)

=cut
#**********************************************************
sub network_change {
  my $self = shift;
  my ($attr) = @_;

  $attr->{DENY_UNKNOWN_CLIENTS} = (defined($attr->{DENY_UNKNOWN_CLIENTS})) ? 1 : 0;
  $attr->{AUTHORITATIVE}        = (defined($attr->{AUTHORITATIVE}))        ? 1 : 0;
  $attr->{DISABLE}              = (defined($attr->{DISABLE}))              ? 1 : 0;
  $attr->{STATIC}               = (defined($attr->{STATIC}))               ? 1 : 0;

  $self->changes(
    {
      CHANGE_PARAM    => 'ID',
      TABLE           => 'dhcphosts_networks',
      DATA            => $attr,
      EXT_CHANGE_INFO => "DHCPHOSTS_NET:$attr->{ID}"
    }
  );

  return $self;
}

#**********************************************************
=head2 network_info($id)

=cut
#**********************************************************
sub network_info {
  my $self = shift;
  my ($id) = @_;

  $self->query("SELECT *,
   INET_NTOA(network) AS network,
   INET_NTOA(mask) AS mask,
   INET_NTOA(routers) AS routers,
   INET_NTOA(block_network) AS blocK_network,
   INET_NTOA(block_mask) AS block_mask,
   INET_NTOA(ip_range_first) AS ip_range_first,
   INET_NTOA(ip_range_last) AS ip_range_last
  FROM dhcphosts_networks
  WHERE id= ? ;",
  undef,
  { INFO => 1,
  	Bind => [ $id ]}
  );

  return $self;
}

#**********************************************************
=head2 networks_list($attr)

=cut
#**********************************************************
sub networks_list {
  my $self = shift;
  my ($attr) = @_;

  delete $self->{COL_NAMES_ARR};

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my @search_columns = (
    [ 'ID',                   'ID',  'id',                                              1 ],
    [ 'NAME',                 'STR', 'name',                                            1 ],
    [ 'NETWORK',              'IP',  'INET_NTOA(network) AS network',                   1 ],
    [ 'COORDINATOR',          'STR', 'coordinator',                                     1 ],
    [ 'PHONE',                'STR', 'phone',                                           1 ],
    [ 'PARENT',               'INT', 'net_parent',                                      1 ],
    [ 'STATUS',               'INT', 'disable AS status',                               1 ],
    [ 'DISABLE',              'INT', 'disable',                                         1 ],
    [ 'TYPE',                 'STR', 'net_parent',                                      1 ],
    [ 'NET_PARENT',           'STR', 'net_parent',                                      1 ],
    [ 'NETMASK',              'IP',  'INET_NTOA(mask) as netmask',                      1 ],
    [ 'NETWORK_INT',          'INT', 'network', 'network as network_int',                 ],
    [ 'NETMASK_INT',          'IP',  'mask', 'mask as netmask_int',                       ],
    [ 'GUEST_VLAN',           'STR', 'guest_vlan',                                      1 ],
    [ 'NTP',                  'STR', 'ntp',                                             1 ],
    [ 'SUFFIX',               'STR', 'suffix',                                          1 ],
    [ 'COMMENTS',             'STR', 'comments',                                        1 ],
    [ 'DENY_UNKNOWN_CLIENTS', 'INT', 'deny_unknown_clients',                            1 ],
    [ 'DNS',                  'STR', 'dns',                                             1 ],
    [ 'IP_RANGE_FIRST',       'IP',  'INET_NTOA(ip_range_first) AS ip_range_first',     1 ],
    [ 'IP_RANGE_FIRST_INT',   'IP',  'ip_range_last AS ip_range_last_int',              1 ],
    [ 'IP_RANGE_LAST',        'STR', 'INET_NTOA(ip_range_last) AS ip_range_last',       1 ],
    [ 'IP_RANGE_LAST_INT',    'STR', 'ip_range_last AS ip_range_last_int',              1 ],
    [ 'BLOCK_NETWORK_INT',    'IP',  'block_network as block_network_int',              1 ],
    [ 'BLOCK_NETWORK',        'STR', 'INET_NTOA(block_network) as block_network',       1 ],
    [ 'DNS2',                 'STR', 'dns2',                                            1 ],
    [ 'VLAN',                 'INT', 'vlan',                                            1 ],
    [ 'STATIC',               'INT', 'static',                                          1 ],
    [ 'AUTHORITATIVE',        'INT', 'authoritative',                                   1 ],
    [ 'ROUTERS_INT',          'IP',  'routers AS routers_int',                          1 ],
    [ 'ROUTERS',              'INT', 'INET_NTOA(routers) AS routers',                   1 ],
    [ 'BLOCK_MASK',           'INT', 'INET_NTOA(block_mask) AS block_mask',             1 ],
    [ 'DOMAIN_ID',            'INT', 'domain_id',                                       1 ],
    # This hack is needed cause lack of custom params support in FUNCTION_FIELDS
    [ 'BUTTON_FIELD1', 'STR', '1 as button_field1', 1 ], # Users button
    [ 'BUTTON_FIELD2', 'STR', '2 as button_field2', 1 ], # Routes button
  );

  my $WHERE =  $self->search_former($attr, \@search_columns,
    {
      WHERE => 1
    }
  );

  $self->query("SELECT
     $self->{SEARCH_FIELDS} id
     FROM dhcphosts_networks
     $WHERE
     ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
     undef,
     $attr
  );

  return [ ] if ($self->{errno});

  my $list = $self->{list};

  if ($self->{TOTAL} > 0 || $PG > 0) {
    $self->query("SELECT COUNT(*) AS total FROM dhcphosts_networks $WHERE", undef, { INFO => 1 });
  }

  return $list;
}


#**********************************************************
=head2 hosts_list($attr) - List of active DHCP hosts

=cut
#**********************************************************
sub hosts_list{
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $GROUP_BY = '';
  $self->{EXT_TABLES} = '';
  my @searcs_params = (
    [ 'ID',           'INT', 'h.id' ],
    [ 'LOGIN',        'INT', 'u.id', 'u.id AS login' ],
    [ 'IP',           'IP',  'h.ip', 'INET_NTOA(h.ip) AS ip' ],
    [ 'IP_NUM',       'INT', 'h.ip', 'h.ip AS ip_num' ],
    [ 'HOSTNAME',     'STR', 'h.hostname', 1 ],
    [ 'NETWORK_NAME', 'STR', 'n.name AS network_name', 1 ],
    [ 'NETWORK',      'INT', 'h.network', 1 ],
    [ 'MAC',          'STR', 'h.mac', 1 ],
    [ 'STATUS',       'INT', 'h.disable', 'h.disable AS status' ],
    [ 'DV_STATUS',    'INT', 'dv.disable', 'dv.disable dv_status' ],
    [ 'DV_STATUS_ID', 'INT', 'dv.disable', 'dv.disable AS dv_status_id' ],
    [ 'IPN_ACTIVATE', 'INT', 'h.ipn_activate', 1 ],
    [ 'ONLINE',       'INT', 'c.uid', 'c.uid AS online' ],
    [ 'EXPIRE',       'DATE', 'h.expire', 1 ],
    [ 'USER_DISABLE', 'INT', 'u.disable', 1 ],
    [ 'OPTION_82',    'INT', 'h.option_82', 1 ],
    [ 'PORTS',        'STR', 'h.ports', 1 ],
    [ 'VID',          'INT', 'h.vid', 1 ],
    [ 'SERVER_VID',   'INT', 'h.server_vid', 1 ],
    [ 'NAS_ID',       'INT', 'h.nas AS nas_id', 1 ],
    [ 'NAS_IP',       'STR', 'nas.ip', 'INET_NTOA(nas.ip) AS nas_ip' ],
    [ 'NAS_NAME',     'STR', 'nas.name', 'nas.name AS nas_name' ],
    [ 'DHCPHOSTS_EXT_DEPOSITCHECK', '', '', 'if(ext_company.id IS NULL,ext_b.deposit,ext_cb.deposit) AS ext_deposit' ],
    [ 'BOOT_FILE',    'STR', 'h.boot_file', 1 ],
    [ 'NEXT_SERVER',  'STR', 'h.next_server', 1 ],
    [ 'UID',          'INT', 'h.uid', 1 ],
    [ 'SHOW_NAS_MNG_INFO', '', '',
      "nas.mng_host_port, nas.mng_user, DECODE(nas.mng_password, '$self->{conf}->{secretkey}') AS mng_password " ],
    [ 'TP_NAME',          'STR', 'tp.name AS tp_name', 1 ],
    [ 'TP_TP_ID',         'INT', 'tp.tp_id as tp_tp_id', 1 ], # Real id for TP
    [ 'TP_ID',            'INT', 'dv.tp_id', 1 ],
    [ 'MONTH_TRAFFIC_IN', 'INT', '', "SUM(l.recv) AS month_traffic_in" ],
    [ 'MONTH_TRAFFIC_OUT','INT', '', "SUM(l.sent) AS month_traffic_out" ],
    [ 'DOMAIN_ID',    'INT', 'u.domain_id', 1 ],
  );

  if ( $self->{conf}->{DHCPHOSTS_USE_DV_STATUS} ){
    push @searcs_params, [ 'DV_STATUS', 'INT', 'dv.disable', 'dv.disable dv_status' ];
  }

  my %EXT_TABLE_JOINS_HASH = ();
  my @WHERE_RULES = ();

  $self->search_former( $attr, \@searcs_params,
    { WHERE             => 1,
      USERS_FIELDS      => 1,
      WHERE_RULES       => \@WHERE_RULES,
      USE_USER_PI       => 1,
      SKIP_USERS_FIELDS => [ 'UID', 'LOGIN' ]
    }
  );

  my $where_delimeter = ' AND ';
  if ( $attr->{_MULTI_HIT} ) {
    $where_delimeter = ' OR ';
  }

  my $WHERE = ($#WHERE_RULES > -1) ? "WHERE (" . join($where_delimeter, @WHERE_RULES) .')' : '';

  if ( ! $admin->{permissions}->{0}->{8} ) {
    $WHERE .= " AND u.deleted=0";
  }

  if ( $attr->{MONTH_TRAFFIC_IN} || $attr->{MONTH_TRAFFIC_OUT} ){
    $EXT_TABLE_JOINS_HASH{dv_log} = 1;
    $GROUP_BY = 'GROUP BY h.id';
  }

  if ( $attr->{TP_NAME} ){
    $EXT_TABLE_JOINS_HASH{dv_main} = 1;
    $EXT_TABLE_JOINS_HASH{tarrif_plans} = 1;
  }

  if ( $attr->{ONLINE} ){
    $EXT_TABLE_JOINS_HASH{online} = 1;
  }

  if ( $self->{conf}->{DHCPHOSTS_USE_DV_STATUS} || $self->{SEARCH_FIELDS} =~ /dv\./ ){
    $EXT_TABLE_JOINS_HASH{dv_main} = 1;
  }

  if ( defined( $attr->{EXT_DEPOSIT} ) && $attr->{EXT_DEPOSIT} ne '' ){
    $EXT_TABLE_JOINS_HASH{ext_company} = 1;
  }

  if ( $self->{SEARCH_FIELDS} =~ /nas\./ ){
    $EXT_TABLE_JOINS_HASH{nas} = 1;
  }

  my $EXT_TABLES = $self->mk_ext_tables( { JOIN_TABLES => \%EXT_TABLE_JOINS_HASH,
      EXTRA_PRE_JOIN                                   => [
        'dv_log:LEFT JOIN dv_log l ON (l.uid=u.uid AND DATE_FORMAT(l.start, \'%Y-%m\')=DATE_FORMAT(curdate(), \'%Y-%m\'))'
        ,
        'dv_main:LEFT JOIN dv_main dv ON  (dv.uid=u.uid)',
        'online:LEFT JOIN dv_calls c ON (c.uid=h.uid)',
        'tarrif_plans:LEFT JOIN tarif_plans tp ON (tp.id=dv.tp_id AND u.domain_id=tp.domain_id AND tp.module=\'Dv\') ',
        'nas:LEFT JOIN nas ON  (nas.id=h.nas)',
        'ext_company:LEFT JOIN companies ext_company ON  (u.company_id=ext_company.id)'
      ]
    } );

  $SORT =~ s/ip/h.ip/;
  my $select_additional_uid = ($attr->{UID}) ? '' : 'h.uid,';
  $self->query( "SELECT
       h.id,
       $self->{SEARCH_FIELDS}
       $select_additional_uid
       h.network AS network_id,
       if ((u.expire <> '0000-00-00' && curdate() > u.expire) || (h.expire <> '0000-00-00' && curdate() > h.expire), 1, 0) AS expire
     FROM dhcphosts_hosts h
     LEFT JOIN dhcphosts_networks n ON (h.network=n.id)
     LEFT JOIN users u on (h.uid=u.uid)
     $EXT_TABLES
     $WHERE
     $GROUP_BY
     ORDER BY $SORT $DESC
     LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  return [ ] if ($self->{errno});
  my $list = $self->{list};

  if ( $self->{TOTAL} > 0 ){
    $self->query( "SELECT count(*) AS total FROM dhcphosts_hosts h
     left join users u on h.uid=u.uid
     $EXT_TABLES
     $WHERE",
      undef, { INFO => 1 }
    );
  }

  $self->{list} = $list;

  return $list;
}

#**********************************************************
# host_defaults()
#**********************************************************
sub host_defaults {
  my $self = shift;

  my %DATA = (
    MAC          => '00:00:00:00:00:00',
    EXPIRE       => '0000-00-00',
    IP           => '0.0.0.0',
    COMMENTS     => '',
    VID          => 0,
    NAS_ID       => 0,
    OPTION_82    => 0,
    HOSTNAME     => '',
    NETWORK      => 0,
    BLOCKTIME    => '',
    FORCED       => '',
    DISABLE      => '',
    EXPIRE       => '',
    PORTS        => '',
    BOOT_FILE    => '',
    NEXT_SERVER  => '',
    IPN_ACTIVATE => ''
  );

  $self = \%DATA;
  return $self;
}

#**********************************************************
=head2 host_add($attr)

=cut
#**********************************************************
sub host_add {
  my $self = shift;
  my ($attr) = @_;

  $attr->{NAS} = $attr->{NAS_ID};
  $attr->{IP}='0.0.0.0' if (! $attr->{IP});

  $self->query_add('dhcphosts_hosts', $attr);

  $admin->{MODULE} = $MODULE;
  $admin->action_add($attr->{UID}, '', {
    TYPE    => 1,
    INFO    => [ 'IP', 'MAC', 'NAS_ID', 'PORTS', 'VLAN', 'NAS_MAC', 'NETWORK', 'OPTION_82' ],
    REQUEST => $attr
  });

  return $self;
}

#**********************************************************
=head2  host_del($attr)

=cut
#**********************************************************
sub host_del {
  my $self = shift;
  my ($attr) = @_;
  my $uid;
  my $action;
  my $host;

  if ($attr->{UID}) {
    $action = "DELETE ALL HOSTS";
    $uid    = $attr->{UID};
  }
  else {
    $host = $self->host_info($attr->{ID});
    $uid    = $host->{UID};
    $action = "DELETE HOST $host->{HOSTNAME} ($host->{IP}/$host->{MAC}) $host->{NAS_ID}:$host->{PORTS}";
  }

  $self->query_del('dhcphosts_hosts', $attr, { uid => $attr->{UID} });
  $self->query_del('dhcphosts_leases',undef, { uid      => $uid,
  	                                           hardware => $host->{MAC} });

  $admin->action_add($uid, "$action", { TYPE => 10 });

  return $self;
}

#**********************************************************
=head2 host_check($attr) - Get host network and dubling parameters

  Arguments:
    $attr
      NETWORK
      MAC
      IP
      UID

  Returns:
    $self

=cut
#**********************************************************
sub host_check {
  my $self = shift;
  my ($attr) = @_;

  my $net = $self->network_info($attr->{NETWORK});
  if ($self->{TOTAL} == 0){
    $self->{errno} = 17;
    $self->{errstr}= 'Netork not found';
  }

  my $ip   = unpack("N", pack("C4", split(/\./, $attr->{IP})));
  my $mask = unpack("N", pack("C4", split(/\./, $net->{MASK})));
  if ((unpack("N", pack("C4", split(/\./, $net->{NETWORK}))) & $mask) != ($ip & $mask)) {
    if ($ip != 0){
      $self->{errno} = 22;
      $self->{errstr}= 'IP not found in network';
    }
  }

  my %params = ();

  if($attr->{MAC} && $attr->{MAC} ne '00:00:00:00:00:00') {
    $params{MAC}=$attr->{MAC};
  }

  if($attr->{IP} && $attr->{IP} ne '0.0.0.0') {
    $params{IP}=$attr->{IP};
  }

  if(scalar %params > 0) {
    my $list = $self->hosts_list({
      COLS_NAME      => 1,
      PAGE_ROWS      => 5,
      _MULTI_HIT     => ($params{IP}) ? undef : 1,
      %params,
      SKIP_DEL_CHECK => 1,
      SKIP_GID       => 1,
      SKIP_DOMAIN    => 1,
      LOGIN          => '_SHOW'
    });

    if ($self->{TOTAL}) {
      if ($self->{TOTAL} == 1 && $list->[0]->{uid} == $attr->{UID}) {
        return $self;
      }
      elsif($self->{TOTAL} > 0) {
        foreach my $line (@$list) {
          if($line->{uid} != $attr->{UID}) {
            $self->{LOGIN}=$line->{login};
            $self->{UID}=$line->{uid};
            last
          }
        }
      }
      $self->{errno} = 23;
    }
  }

  return $self;
}

#**********************************************************
=head2 host_info($id, $attr) - Host full info

=cut
#**********************************************************
sub host_info {
  my $self = shift;
  my ($id, $attr) = @_;

  my $WHERE     = '';
  my @bind_vals = ();

  if ($attr->{IP}) {
    $WHERE = "ip=INET_ATON( ? )";
    push @bind_vals, $attr->{IP};
  }
  else {
    $WHERE = "id= ? ";
    push @bind_vals, $id;
  }

  $self->query("SELECT
   *,
   INET_NTOA(ip) AS ip,
   nas AS nas_id
  FROM dhcphosts_hosts
  WHERE $WHERE;",
  undef,
  { INFO => 1,
    Bind => \@bind_vals
  }
  );

  return $self;
}

#**********************************************************
=head2 host_change($attr)

=cut
#**********************************************************
sub host_change {
  my $self = shift;
  my ($attr) = @_;

  $attr->{NAS}          = $attr->{NAS_ID};
  $attr->{OPTION_82}    = ($attr->{OPTION_82})    ? 1 : 0;
  $attr->{IPN_ACTIVATE} = ($attr->{IPN_ACTIVATE}) ? 1 : 0;
  $attr->{DISABLE}      = ($attr->{DISABLE})      ? 1 : 0;

  $admin->{MODULE} = $MODULE;
  $self->changes(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'dhcphosts_hosts',
      DATA         => $attr
    }
  );

  return $self;
}

#**********************************************************
=head2 route_add($attr)

=cut
#**********************************************************
sub route_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('dhcphosts_routes', {
  	             NETWORK => $attr->{NET_ID},
  	             SRC     => "INET_ATON('$attr->{SRC}')",
  	             MASK    => "INET_ATON('$attr->{MASK}')",
  	             ROUTER  => "INET_ATON('$attr->{ROUTER}')"
  	           });

  $admin->system_action_add("DHCPHOSTS_NET:$attr->{NET_ID} ROUTE:$self->{INSERT_ID}", { TYPE => 1 });
  return $self;
}

#**********************************************************
=head2 route_del()

=cut
#**********************************************************
sub route_del {
  my $self = shift;
  my ($id) = @_;

  $self->query_del('dhcphosts_routes', { ID => $id });

  $admin->system_action_add("DHCPHOSTS_NET: ROUTE:$id", { TYPE => 10 });
  return $self;
}

#**********************************************************
=head2 route_change($attr)

=cut
#**********************************************************
sub route_change {
  my $self = shift;
  my ($attr) = @_;

  my %FIELDS = (
    ID     => 'id',
    NET_ID => 'network',
    SRC    => 'src',
    MASK   => 'mask',
    ROUTER => 'router'
  );

  $self->changes(
    {
      CHANGE_PARAM    => 'ID',
      TABLE           => 'dhcphosts_routes',
      FIELDS          => \%FIELDS,
      OLD_INFO        => $self->route_info($attr->{ID}),
      DATA            => $attr,
      EXT_CHANGE_INFO => "DHCPHOSTS_ROUTE:$attr->{ID}"
    }
  );

  return [ ] if ($self->{errno});
}

#**********************************************************
=head2 route_info($id)

=cut
#**********************************************************
sub route_info {
  my $self = shift;
  my ($id) = @_;

  $self->query("SELECT
   id AS net_id,
   network,
   INET_NTOA(src) AS src,
   INET_NTOA(mask) AS mask ,
   INET_NTOA(router) AS router
    FROM dhcphosts_routes WHERE id='$id';",
   undef,
   { INFO => 1 }
  );

  return $self;
}

#**********************************************************
=head2 leases_update($attr)

=cut
#**********************************************************
sub leases_update {
  my $self = shift;
  my ($attr) = @_;

  if ($attr->{LEASES_HASH}) {
    my @MULTI_QUERY = ();

    while(my($ip, $hash)=each %{ $attr->{LEASES_HASH} }) {
      push @MULTI_QUERY, [
        $hash->{STARTS},
        $hash->{ENDS},
        $ip || '0.0.0.0',
        $hash->{HARDWARE} || '',
        $attr->{NAS_ID} || 0,
        $hash->{STATE} || 0,
      ];
    }

    $self->query("INSERT INTO dhcphosts_leases ( start, ends, ip, hardware, nas_id, state)
       VALUES (?, ?, INET_ATON( ? ), ?, ?, ?)", undef,
     { MULTI_QUERY =>  \@MULTI_QUERY })
  }
  else {
    $self->query_add('dhcphosts_leases', $attr);
  }

  return $self;
}

#**********************************************************
=head2 leases_list($attr)

=cut
#**********************************************************
sub leases_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my @WHERE_RULES = ();

  if (defined($attr->{STATE}) && $attr->{STATE} ne '_SHOW') {
    if ($attr->{STATE}==4) {
      push @WHERE_RULES, "l.ends < now()";
    }
    if ($attr->{STATE}==2) {
      push @WHERE_RULES, "l.ends > now()";
    }
    else {
      push @WHERE_RULES, "state='$attr->{STATE}'";
    }
  }

  if($admin->{GID}) {
    push @WHERE_RULES, "(u.gid IN ( $admin->{GID} ) OR u.id IS NULL)";
    $attr->{SKIP_GID}=1;
  }

  $attr->{SKIP_DEL_CHECK}=1;

  my $WHERE = $self->search_former($attr, [
     ['NEXT_STATE',      'INT', 'next_state'   ],
     ['NAS_ID',          'INT', 'nas_id'       ],
     ['DHCP_ID',         'INT', 'l.dhcp_id',  1],
     ['REMOTE_ID',       'STR', 'remote_id',  1],
     ['CIRCUIT_ID',      'STR', 'circuit_id', 1],
     ['ENDS',            'DATE','ends'         ],
     ['STARTS',          'DATE','starts'       ],
     ['UID',             'INT', 'l.uid'        ],
     ['HOSTNAME',        'STR', 'hostname'     ],
     ['HARDWARE',        'STR', 'l.hardware'   ],
     ['IP',              'IP',  'l.ip'         ],
     ['USER_DISABLE',    'INT', 'u.disable'    ],
     ['PORTS',           'STR', 'l.port',     1],
     ['GUEST',           'INT', 'l.flag',      ],
     ['VID',             'INT', 'l.vlan',     1],
     ['VLAN',            'INT', 'l.vlan',     1],
     ['SERVER_VLAN',     'INT', 'l.server_vlan', 1],
    ],
    { WHERE         => 1,
    	WHERE_RULES   => \@WHERE_RULES,
      SKIP_USERS_FIELDS => ['LOGIN'],
    	USERS_FIELDS  => 1,
    	USE_USER_PI   => 1
  });

  my $EXT_TABLES = $self->{EXT_TABLES} || '';

  $self->query("SELECT if (l.uid > 0, u.id, '') AS login,
  l.ip,
  l.start,
  l.hardware,
  l.hostname,
  l.ends,
  if (l.ends < NOW(), 4, l.state) AS state,
  l.port,
  l.vlan,
  l.flag,
  l.nas_id,
  l.next_state,
  $self->{SEARCH_FIELDS}
  l.uid
  FROM dhcphosts_leases  l
  LEFT JOIN users u ON (u.uid=l.uid)
  $EXT_TABLES
  $WHERE
  ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS; ",
  undef,
  $attr
  );

  my $list = $self->{list};

  $self->query("SELECT COUNT(*) AS total FROM dhcphosts_leases l
    LEFT JOIN users u ON (u.uid=l.uid)
  $WHERE;", undef, {INFO => 1 });

  return $list;
}

#**********************************************************
=head2 leases_update($attr) - Delete from leases

  Arguments:
    $attr
      ENDED
      NAS_ID
      UID
      MAC

  Results:
    Object

=cut
#**********************************************************
sub leases_clear {
  my $self = shift;
  my ($attr) = @_;

  my @WHERE_RULES=();
  if ($attr->{ENDED}) {
    push @WHERE_RULES, "ends < NOW()";
  }

  my $WHERE = $self->search_former($attr, [
     ['NAS_ID', 'INT', 'nas_id'   ],
     ['UID',    'INT', 'uid',     ],
     ['MAC',    'STR', 'hardware' ],
    ],
    { WHERE => 1,
    	WHERE_RULES => \@WHERE_RULES
    }
  );

  $self->query("DELETE FROM dhcphosts_leases $WHERE;", 'do');
  return $self;
}

#**********************************************************
=head2 log_add($attr) - Add log info to db

  Arguments:

  Result:
    Object

=cut
#**********************************************************
sub log_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('dhcphosts_log', $attr);

  return $self;
}

#**********************************************************
=head2 log_del($attr)

=cut
#**********************************************************
sub log_del {
  my $self = shift;
  my ($attr) = @_;

  my $WHERE = '';

  if ($attr->{DAYS_OLD}) {
    $WHERE = "datetime < CURDATE() - INTERVAL $attr->{DAYS_OLD} day";
  }
  elsif ($attr->{DATE}) {
    $WHERE = "datetime='$attr->{DATETIME}'";
  }

  $self->query("DELETE FROM dhcphosts_log WHERE $WHERE", 'do');

  return $self;
}

#**********************************************************
=head2 log_list($attr)

=cut
#**********************************************************
sub log_list {
  my $self = shift;
  my ($attr) = @_;

  my @ids = ();
  if ($attr->{UID}) {
    my $list = $self->hosts_list({ UID => $attr->{UID}, COLS_NAME => 1 });

    if ($self->{TOTAL} > 0) {
      foreach my $line (@$list) {
        push @ids, $line->{ip}, $line->{mac};
      }
    }
    if ($#ids > -1) {
      $attr->{MESSAGE} = '* ' . join(" *,* ", @ids) . ' *';
    }
    $self->{IDS} = \@ids;
  }

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $WHERE = $self->search_former($attr, [
     ['MESSAGE',     'STR', 'l.message'   ],
     ['MAC',         'STR', 'l.mac'       ],
     ['HOSTNAME',    'STR', 'l.hostname'  ],
     ['ID',          'INT', 'l.id'        ],
     ['NAS_ID',      'INT', 'nas_id'      ],
     ['MESSAGE_TYPE','INT', 'message_type'],
     ['FROM_DATE|TO_DATE', 'DATE', "DATE_FORMAT(l.datetime, '%Y-%m-%d')" ],
    ],
    { WHERE => 1,
    }
  );

  my $EXT_TABLES = $self->{EXT_TABLES};
  
  if ($WHERE =~ / u\./) {
    $EXT_TABLES .= "LEFT JOIN users u ON  (u.uid=l.uid)";
  }

  $self->query("SELECT l.datetime, l.hostname, l.message_type, l.message
     FROM dhcphosts_log l
     $WHERE
     ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
  undef,
  $attr);

  my $list = $self->{list};

  return $list if ($self->{errno});

  if ($self->{TOTAL} > 0) {
    $self->query("SELECT COUNT(*) AS total FROM dhcphosts_log l $WHERE", undef, { INFO => 1 });
  }

  return $list;
}

1

