package Snmputils;

=head1 NAME

  SNMP managment system

=cut

use strict;
our $VERSION = 2.00;
use parent qw(dbcore);

my ($admin, $CONF);
my $SORT      = 1;
my $DESC      = q{};
my $PG        = 1;
my $PAGE_ROWS = 25;

#**********************************************************
# Init
#**********************************************************
sub new{
  my $class = shift;
  my $db = shift;
  ($admin, $CONF) = @_;

  my $self = { };
  bless( $self, $class );

  $self->{db} = $db;
  $self->{admin} = $admin;
  $self->{conf} = $CONF;

  if ( $CONF->{DELETE_USER} ){
    $self->{UID} = $CONF->{DELETE_USER};
    $self->snmp_binding_del( { UID => $CONF->{DELETE_USER} } );
  }

  return $self;
}

#**********************************************************
=head2 snmputils_nas_ipmac()

=cut
#**********************************************************
sub snmputils_nas_ipmac{
  my $self = shift;
  my ($attr) = @_;

  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;
  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = (defined( $attr->{DESC} )) ? $attr->{DESC} : 'DESC';

  my @WHERE_RULES = ();
  if ( defined( $attr->{DISABLE} ) ){
    push @WHERE_RULES, "u.disable='$attr->{DISABLE}'";
  }

  my $WHERE = ($#WHERE_RULES > -1) ? 'AND ' . join( ' AND ', @WHERE_RULES ) : '';

  $self->query( "SELECT un.nas_id,
     u.uid, 
     INET_NTOA(d.ip) AS ip, 
     d.mac,
     if(u.company_id > 0, cb.deposit+u.credit, ub.deposit+u.credit) AS deposit, 
     d.comments,
     d.vid,
     d.ports,
     d.nas,
     u.id AS login,
     d.network,
     if(u.disable=1, 1,
      if (d.disable=1, 1,
       if((u.expire='0000-00-00' or u.expire > CURDATE())
        AND (u.activate='0000-00-00' or u.activate <= CURDATE()), 0, 1)
      )
     ) AS status
   FROM (users u, dhcphosts_hosts d)
     LEFT JOIN bills ub ON (u.bill_id = ub.id)
     LEFT JOIN companies company ON  (u.company_id=company.id)
     LEFT JOIN bills cb ON  (company.bill_id=cb.id)
     LEFT JOIN users_nas un ON (u.uid=un.uid)
            WHERE u.uid=d.uid
               and (d.nas='$attr->{NAS_ID}' or un.nas_id='$attr->{NAS_ID}')
               $WHERE
            ORDER BY $SORT $DESC
            LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list};
  return $list;
}

#**********************************************************
# Bill
#**********************************************************
sub snmp_binding_add{
  my $self = shift;
  my ($attr) = @_;

  $self->query_add( 'snmputils_binding', $attr );

  return $self;
}

#**********************************************************
# Bill
#**********************************************************
sub snmp_binding_del{
  my $self = shift;
  my ($attr) = @_;

  $self->query_del( 'snmputils_binding', undef, {
      uid     => $attr->{UID},
      binding => $attr->{ID}
    } );
  return $self;
}

#**********************************************************
# group_info()
#**********************************************************
sub snmp_binding_change{
  my $self = shift;
  my ($attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'snmputils_binding',
    DATA         => $attr
  });

  return $self;
}

#**********************************************************
# Bill
#**********************************************************
sub snmp_binding_info{
  my $self = shift;
  my ($id) = @_;

  $self->query( "SELECT  *
    FROM snmputils_binding
   WHERE id= ? ;",
    undef,
    { INFO => 1,
      Bind => [ $id ] }
  );

  return $self;
}

#**********************************************************
=head2 snmputils_binding_list($attr)

=cut
#**********************************************************
sub snmputils_binding_list{
  my $self = shift;
  my ($attr) = @_;

  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;
  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = (defined( $attr->{DESC} )) ? $attr->{DESC} : 'DESC';

  my @WHERE_RULES = ();

  if ( $attr->{BINDING} ){
    push @WHERE_RULES, @{ $self->search_expr($attr->{BINDING}, 'STR', 'b.binding' ) };
  }
  elsif ( $attr->{IDS} ){
    $self->query( "SELECT u.id, b.binding,  b.params, b.comments, b.id,
            b.uid,
            if(u.company_id > 0, cb.deposit+u.credit, ub.deposit+u.credit),
            u.disable
            from snmputils_binding b
            INNER JOIN users u ON (b.uid = u.uid)
            LEFT JOIN bills ub ON (u.bill_id = ub.id)
            LEFT JOIN companies company ON  (u.company_id=company.id)
            LEFT JOIN bills cb ON  (company.bill_id=cb.id)
            WHERE b.binding IN ($attr->{IDS})
            ORDER BY $SORT $DESC
            LIMIT $PG, $PAGE_ROWS;",
      undef,
      $attr
    );

    return $self->{list};
  }

  my $WHERE = $self->search_former( $attr, [
      [ 'LOGIN',  'STR', 'u.id' ],
      [ 'UID',    'INT', 'u.uid' ],
      [ 'PARAMS', 'STR', 'b.params' ],
    ],
    { WHERE       => 1,
      WHERE_RULES => \@WHERE_RULES
    }
  );

  $self->query( "SELECT u.id, b.binding,  b.params, b.comments, b.id, b.uid
    FROM snmputils_binding b
    LEFT JOIN users u ON (u.uid = b.uid)
    $WHERE
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;"
  );

  my $list = $self->{list};

  return $list;
}

1
