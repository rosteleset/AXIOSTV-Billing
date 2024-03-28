package Netlist;

=head1 IPAM service

  IP address managment
  IP Calculator

=cut

use strict;
use parent qw( dbcore );
use Socket;

my ($admin, $CONF);
my ($SORT, $DESC, $PG, $PAGE_ROWS);

sub new {
  my $class = shift;
  my $db    = shift;
  ($admin, $CONF) = @_;
  my $self = {};
  bless($self, $class);

  $self->{db}   = $db;
  $self->{admin}= $admin;
  $self->{conf} = $CONF;

  return $self;
}

#**********************************************************
=head2 groups_list($attr)

=cut
#**********************************************************
sub groups_list {
  my $self = shift;
  my ($attr) = @_;

  my $WHERE = '';

  if (defined $attr->{NOT_PARENT_ID}){
    $WHERE = "WHERE ng.parent_id='$attr->{NOT_PARENT_ID}'";
  }

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  my @list = ();
  $self->query("SELECT
    ng.name,
    ng.comments,
    count(ni.ip) AS count,
    (SELECT name FROM netlist_groups WHERE id=ng.parent_id) AS parent_name,
    ng.parent_id AS parent,
    ng.id,
    ng.id AS gid
    FROM netlist_groups ng
    LEFT JOIN netlist_ips ni ON (ng.id=ni.gid)
    $WHERE
    GROUP BY ng.id
    ORDER BY $SORT $DESC;",
    undef,
    $attr
  );

  if ($self->{errno}) {
    return \@list;
  }

  return $self->{list};
}

#**********************************************************
# Add
#**********************************************************
sub group_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('netlist_groups', $attr);
  $self->{GID} = $self->{INSERT_ID};

  return $self;
}

#**********************************************************
# change
#**********************************************************
sub group_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'netlist_groups',
    DATA         => $attr
  });

  return $self;
}

#**********************************************************
# del
#**********************************************************
sub group_del {
  my $self = shift;
  my ($id) = @_;

  $self->query_del('netlist_groups', {ID => $id });

  return $self;
}

#**********************************************************
# Info
#**********************************************************
sub group_info {
  my $self = shift;
  my ($id) = @_;

  $self->query("SELECT *
    FROM netlist_groups
    WHERE id= ? ;",
    undef,
    { INFO => 1,
      Bind => [ $id ] }
  );

  return $self;
}

#**********************************************************
=head ip_list($attr) - IP lists

=cut
#**********************************************************
sub ip_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $WHERE =  $self->search_former($attr, [
        ['GID',         'INT', 'ni.gid'                   ],
        ['IP',          'IP', "INET_ATON('$attr->{IP}')" ],
        ['IPV6',        'INT', "INET6_ATON('$attr->{IPV6}')"],
        ['IPv6_PREFIX', 'INT', 'ni.ipv6_prefix'       ],
        ['STATUS',      'INT', 'ni.status',               ],
        ['HOSTNAME',    'STR', 'ni.hostname'              ]
      ],
      { WHERE       => 1  }
    );
  #      INET_NTOA(ni.ip) AS ip,

  my $ipv6_field = ($self->db_version() < 5.6) ? 'ipv6' : "INET6_NTOA(ipv6)";

  $self->query("SELECT ni.ip_id as ip_id, ni.ip AS ip_num,
      IF(ip <> 0 and
    INET_NTOA(ip) REGEXP '(25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})',
    INET_NTOA(ni.netmask), ni.ipv6_prefix) AS netmask,
      ni.hostname,
      ni.descr,
      ng.name, 
      ni.status, DATE_FORMAT(ni.date, '%Y-%m-%d') AS date,
      IF(ip <> 0 and
    INET_NTOA(ip) REGEXP '(25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})'
    , INET_NTOA(ip), 
    $ipv6_field) AS ip

    FROM netlist_ips ni
    LEFT JOIN netlist_groups ng ON (ng.id=ni.gid)
    $WHERE
    GROUP BY ni.ip
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list};

  if ($self->{TOTAL} > 0) {
    $self->query("SELECT count(*) AS total
    FROM netlist_ips ni
    LEFT JOIN netlist_groups ng ON (ng.id=ni.gid)
    $WHERE;",
    undef, { INFO => 1 }
    );
  }

  return $list;
}

#**********************************************************
# ip_add
#**********************************************************
sub ip_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('netlist_ips', { %$attr,
  	                                AID  => $admin->{AID},
  	                                DATE => 'now()'
  	                              });

  return $self;
}

#**********************************************************
# ip_change
#**********************************************************
sub ip_change {
  my $self = shift;
  my ($attr) = @_;

  $attr->{MAC_AUTO_DETECT} = (defined($attr->{MAC_AUTO_DETECT})) ? 1 : 0;

  if ($attr->{IDS}) {
    my @ids_array = split(/, /, $attr->{IDS});
    foreach my $id (@ids_array) {
      $attr->{IP_ID} = $id;
      $attr->{HOSTNAME} = gethostbyaddr(inet_aton($id), AF_INET) if ($attr->{RESOLV});

      $self->changes({
        CHANGE_PARAM => 'IP_ID',
        TABLE        => 'netlist_ips',
        DATA         => $attr
      });

      return [ ] if ($self->{errno});
    }
    return 0;
  }

  $self->changes({
    CHANGE_PARAM => 'IP_ID',
    TABLE        => 'netlist_ips',
    DATA         => $attr
  });

  return $self;
}

#**********************************************************
# del
#**********************************************************
sub ip_del {
  my $self = shift;
  my ($ip_id) = @_;
  $self->query_del('netlist_ips', undef, { ip_id => $ip_id });

  return $self;
}

#**********************************************************
# Info
#**********************************************************
sub ip_info {
  my $self = shift;
  my ($ip_id) = @_;

  $self->query("SELECT *,
      IF(ip <> 0 and IS_IPV4(INET_NTOA(ip)), INET_NTOA(ip), INET6_NTOA(ipv6)) as ip,
      IF(ip <> 0 and IS_IPV4(INET_NTOA(ip)), INET_NTOA(netmask), ipv6_prefix) AS netmask,
       ip AS ip_num
    FROM netlist_ips
    WHERE ip_id= ? ;",
    undef,
    { INFO => 1,
      Bind => [ $ip_id ] }
  );

  return $self;
}

1
