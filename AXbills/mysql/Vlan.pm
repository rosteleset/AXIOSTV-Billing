package Vlan;

=head1 NAME

  Vlan  managment functions

=cut

use strict;
our $VERSION = 2.00;
use parent 'main';
my $MODULE = 'Vlan';
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
  my $self = {};

  bless($self, $class);

  $self->{db}=$db;

  return $self;
}

#**********************************************************
# User information
# info()
#**********************************************************
sub info {
  my $self = shift;
  my ($uid, $attr) = @_;

  my $WHERE = "WHERE uid='$uid'";

  if (defined($attr->{IP})) {
    $WHERE = "WHERE ip=INET_ATON('$attr->{IP}')";
  }

  $self->query2("SELECT vlan_id,
   INET_NTOA(ip) AS ip, 
   INET_NTOA(netmask) AS netmask, 
   disable, 
   dhcp,
   pppoe,
   nas_id,
   INET_NTOA(unnumbered_ip) AS unnumbered_ip
     FROM vlan_main
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
    VLAN_ID       => 0,
    DISABLE       => 0,
    IP            => '0.0.0.0',
    NETMASK       => '255.255.255.255',
    DHCP          => 0,
    NAS_ID        => 0,
    PPPOE         => 0,
    UNNUMBERED_IP => 0
  );

  $self = \%DATA;
  return $self;
}

#**********************************************************
# add()
#**********************************************************
sub add {
  my $self = shift;
  my ($attr) = @_;

  my %DATA = $self->get_data($attr, { default => defaults() });

  $self->query2("INSERT INTO vlan_main (uid, vlan_id, 
             ip, 
             netmask, 
             disable, 
             dhcp,
             pppoe,
             nas_id,
             unnumbered_ip
           )
        VALUES ('$DATA{UID}', '$DATA{VLAN_ID}', INET_ATON('$DATA{IP}'), 
        INET_ATON('$DATA{NETMASK}'), '$DATA{DISABLE}', 
        '$DATA{DHCP}',
        '$DATA{PPPOE}',
        '$DATA{NAS_ID}',
        INET_ATON('$DATA{UNNUMBERED_IP}'));", 'do'
  );

  return [ ] if ($self->{errno});
  $admin->action_add("$DATA{UID}", "$DATA{VLAN_ID}", { TYPE => 1 });
  return $self;
}

#**********************************************************
# change()
#**********************************************************
sub change {
  my $self = shift;
  my ($attr) = @_;

  $attr->{DHCP}    = ($attr->{DHCP})    ? $attr->{DHCP}    : 0;
  $attr->{PPPOE}   = ($attr->{PPPOE})   ? $attr->{PPPOE}   : 0;
  $attr->{DISABLE} = ($attr->{DISABLE}) ? $attr->{DISABLE} : 0;

  $admin->{MODULE} = $MODULE;
  $self->changes2(
    {
      CHANGE_PARAM => 'UID',
      TABLE        => 'vlan_main',
      DATA         => $attr
    }
  );

  return $self->{result};
}

#**********************************************************
# Delete user info from all tables
#
# del(attr);
#**********************************************************
sub del {
  my $self = shift;

  $self->query2("DELETE from vlan_main WHERE uid='$self->{UID}';", 'do');

  $admin->action_add($self->{UID}, "$self->{UID}", { TYPE => 10 });
  return $self->{result};
}

#**********************************************************
# list()
#**********************************************************
sub list {
  my $self   = shift;
  my ($attr) = @_;

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my @WHERE_RULES = ("u.uid = vlan.uid");

  push @WHERE_RULES, @{ $self->search_expr_users({ %$attr, 
                             EXT_FIELDS => [
                                            'PHONE',
                                            'EMAIL',
                                            'ADDRESS_FLAT',
                                            'PASPORT_DATE',
                                            'PASPORT_NUM', 
                                            'PASPORT_GRANT',
                                            'CITY', 
                                            'ZIP',
                                            'GID',
                                            'CONTRACT_ID',
                                            'CONTRACT_SUFIX',
                                            'CONTRACT_DATE',
                                            'EXPIRE',

                                            'CREDIT',
                                            'CREDIT_DATE', 
                                            'REDUCTION',
                                            'REGISTRATION',
                                            'REDUCTION_DATE',
                                            'COMMENTS',
                                            'BILL_ID',

                                            'ACTIVATE',
                                            'EXPIRE',
                                            'DEPOSIT:skip',
                                            'DOMAIN_ID'
                                             ] }) };

  my $GROUP_BY = "GROUP BY u.uid";

  if (defined($attr->{VLAN_GROUP})) {
    $GROUP_BY = "GROUP BY $attr->{VLAN_GROUP}";
    $self->{SEARCH_FIELDS} = 'max(INET_NTOA(vlan.ip)), min(INET_NTOA(vlan.netmask)), INET_NTOA(vlan.unnumbered_ip) AS unnumbered_ip,';
    $self->{SEARCH_FIELDS_COUNT} += 2;
  }

  my $WHERE =  $self->search_former($attr, [
      ['IP',             'IP',  'vlan.ip',             'INET_NTOA(vlan.ip) AS ip' ],
      ['NETMASK',        'IP',  'vlan.netmask',        'INET_NTOA(vlan.netmask) AS netmask' ],
      ['UNNUMBERED_IP',  'IP',  'vlan.unnumbered_ip',  'INET_NTOA(vlan.unnumbered_ip) AS unnumbered_ip'],
      ['PPPOE',          'INT', 'vlan.pppoe',                     ],
      ['DHCP',           'INT', 'vlan.dhcp',                      ],
      ['NAS_ID',         'INT', 'vlan.nas_id',                    ],
      ['VLAN_ID',        'INT', 'vlan.vlan_id',                   ],
      ['DISABLE',        'INT', 'vlan.disable',                   ]
    ],
    { WHERE => 1,
    	WHERE_RULES => \@WHERE_RULES
    }
    );

  $self->query2("SELECT u.id AS login, 
      pi.fio, 
      if(u.company_id > 0, cb.deposit, b.deposit) AS deposit, 
      u.credit, 
      vlan.vlan_id,
      INET_NTOA(vlan.ip) AS ip,
      if (vlan.unnumbered_ip>0, CONCAT(INET_NTOA(vlan.unnumbered_ip),'/', INET_NTOA(vlan.netmask)), 
        if (vlan.ip=0, '', 
          CONCAT(INET_NTOA(vlan.ip+1), ' - ', INET_NTOA(4294967294 + vlan.ip - vlan.netmask - 1))
        ) 
      ) AS ip_range,
      vlan.disable, 
      vlan.dhcp,
      vlan.pppoe,
      INET_NTOA(vlan.netmask) AS netmask,
      $self->{SEARCH_FIELDS}
      u.uid, 
      u.activate, 
      u.expire
     FROM (users u, vlan_main vlan)
     LEFT JOIN users_pi pi ON (u.uid = pi.uid)
     LEFT JOIN bills b ON (u.bill_id = b.id)
     LEFT JOIN companies company ON  (u.company_id=company.id) 
     LEFT JOIN bills cb ON  (company.bill_id=cb.id)
     $WHERE 
     $GROUP_BY
     ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
     undef,
     $attr
  );

  return [ ] if ($self->{errno});

  my $list = $self->{list};

  if ($self->{TOTAL} >= 0) {
    $self->query2("SELECT count(u.id) AS total FROM (users u, vlan_main vlan) $WHERE",
     undef, { INFO => 1 } );
  }

  return $list;
}

#**********************************************************
# Periodic
#**********************************************************
sub periodic {
  my $self = shift;
#  my ($period) = @_;
#  if ($period eq 'daily') {
#    $self->daily_fees();
#  }

  return $self;
}

1
