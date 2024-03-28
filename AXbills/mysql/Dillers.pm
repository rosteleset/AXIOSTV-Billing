package Dillers;

=head1 NAME

  Cards system

=head1 VERSION

  VERSION: 0.01;
  REVISION: 20171211

=cut

use strict;
use parent qw(dbcore);

my $MODULE   = 'Dillers';
my ($admin, $CONF);


#**********************************************************
=head1 new($db, $admin, \%conf)

=cut
#**********************************************************
sub new {
  my $class = shift;
  my $db    = shift;
  ($admin, $CONF) = @_;

  $admin->{MODULE} = $MODULE;
  my $self = {};
  $CONF->{BUILD_DELIMITER} = ', ' if (!defined($CONF->{BUILD_DELIMITER}));

  bless($self, $class);
  $self->{db}   =$db;
  $self->{admin}=$admin;
  $self->{conf} =$CONF;

  if ($CONF->{DELETE_USER}) {
    $self->{UID} = $CONF->{DELETE_USER};
    $self->diller_del({ UID => $CONF->{DELETE_USER} });
  }

  $self->{CARDS_NUMBER_LENGTH} = (!$CONF->{CARDS_NUMBER_LENGTH}) ? 0 : $CONF->{CARDS_NUMBER_LENGTH};

  return $self;
}


#**********************************************************
=head2 diller_add($attr)

=cut
#**********************************************************
sub diller_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('cards_dillers', { REGISTRATION => 'NOW()',
      %$attr,
      DISABLE => $attr->{DISABLE} || 0
    });

  return $self;
}

#**********************************************************
=head2 diller_info($attr) - User information

=cut
#**********************************************************
sub diller_info {
  my $self = shift;
  my ($attr) = @_;

  my $WHERE = '';

  if ($attr->{UID}) {
    $WHERE = "cd.uid='$attr->{UID}'";
  }
  else {
    $WHERE = "cd.id='$attr->{ID}'";
  }

  $self->query("SELECT
    cd.id,
    cd.disable,
    cd.registration,
    cd.comments,
    cd.percentage,
    cd.tp_id,
    tp.name as tp_name,
    cd.uid,
    pi.fio,
    CONCAT(pi.address_street, ', ', pi.address_build, '/', pi.address_flat) AS address_full,
    pi.phone,
    tp.payment_type,
    tp.operation_payment,
    IF (cd.percentage>0,  cd.percentage, tp.percentage) AS diller_percentage,
    pi.location_id
    FROM cards_dillers cd
    LEFT JOIN users_pi pi ON (cd.uid=pi.uid)
    LEFT JOIN dillers_tps tp ON (tp.id=cd.tp_id)
    WHERE  $WHERE;",
    undef,
    { INFO => 1 }
  );


  if (! $self->{errno} && $self->{LOCATION_ID}) {
    require Address;
    Address->import();
    my $Address = Address->new($self->{db}, $admin, $self->{conf});

    $Address->address_info($self->{LOCATION_ID});

    $self->{DISTRICT_ID}      = $Address->{DISTRICT_ID};
    $self->{CITY}             = $Address->{CITY};
    $self->{ADDRESS_DISTRICT} = $Address->{ADDRESS_DISTRICT};
    $self->{STREET_ID}        = $Address->{STREET_ID};
    $self->{ZIP}              = $Address->{ZIP};
    $self->{COORDX}           = $Address->{COORDX};

    $self->{ADDRESS_STREET}   = $Address->{ADDRESS_STREET};
    $self->{ADDRESS_STREET2}  = $Address->{ADDRESS_STREET2};
    $self->{ADDRESS_BUILD}    = $Address->{ADDRESS_BUILD};
    $self->{ADDRESS_FULL}="$self->{ADDRESS_STREET}$self->{conf}->{BUILD_DELIMITER}$self->{ADDRESS_BUILD}$self->{conf}->{BUILD_DELIMITER}$self->{ADDRESS_FLAT}";
  }


  return $self;
}

#**********************************************************
=head2 diller_change($attr)

=cut
#**********************************************************
sub diller_change {
  my $self = shift;
  my ($attr) = @_;

  $attr->{ID} = $attr->{chg} if ($attr->{chg});
  $attr->{DISABLE} = 0 if (! defined($attr->{DISABLE}));

  $admin->{MODULE} = $MODULE;
  $self->changes(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'cards_dillers',
      DATA         => $attr
    }
  );

  return $self->{result};
}

#**********************************************************
=head2  dillers_list($attr)

=cut
#**********************************************************
sub dillers_list {
  my $self   = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG   = ($attr->{PG})   ? $attr->{PG}   : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my @WHERE_RULES = ("u.domain_id='$admin->{DOMAIN_ID}'");

  my $WHERE = $self->search_former($attr, [
      ['ADDRESS',      'STR',  'cd.address'      ],
      ['EMAIL',        'STR',  'cd.email'        ],
      ['UID',          'INT',  'cd.uid'          ],
      ['DISABLE',      'INT',  'cd.disable',     ],
      ['NAME',         'STR',  'cd.name',        ],
    ],
    { WHERE => 1,
      WHERE_RULES => \@WHERE_RULES
    }
  );

  $self->query("SELECT cd.id,
      u.id AS login,
      pi.fio,
      CONCAT(pi.address_street, ', ', pi.address_build, '/', pi.address_flat) AS address_full,
      pi.email,
      cd.registration,
      cd.percentage,
      cd.disable,
      COUNT(cu.serial),
      SUM(IF(cu.status=0, 1, 0)),
      cd.uid,
      pi.location_id
    FROM cards_dillers cd
    INNER JOIN users u ON (cd.uid = u.uid)
    LEFT JOIN users_pi pi ON (pi.uid = u.uid)
    LEFT JOIN cards_users cu ON (cd.id = cu.diller_id)
     $WHERE
     GROUP BY cd.id
     ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  return [] if ($self->{errno});
  my $list = $self->{list};

  if ($self->{TOTAL} > 0) {
    $self->query("SELECT COUNT(DISTINCT cd.id) AS total FROM cards_dillers cd
       INNER JOIN users u ON (cd.uid = u.uid)
       LEFT JOIN cards_users cu ON (cd.id = cu.diller_id)
      $WHERE ",
      undef, { INFO => 1 }
    );
  }

  return $list;
}

#**********************************************************
=head2 diller_del($attr) - Delete diller_del

=cut
#**********************************************************
sub diller_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('cards_dillers', $attr, { uid => $attr->{UID} });

  $admin->{MODULE}=$MODULE;
  $admin->action_add($attr->{UID}, $attr->{UID}, { TYPE => 10 });

  return $self->{result};
}

#**********************************************************
=head2 dillers_tp_add($attr)

=cut
#**********************************************************
sub dillers_tp_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('dillers_tps', $attr);

  $self->{TP_ID} = $self->{INSERT_ID};
  $admin->system_action_add("DILLERS_TP:$self->{TP_ID}", { TYPE => 1 });

  return $self;
}

#**********************************************************
=head2 dillers_tp_change($attr)

=cut
#**********************************************************
sub dillers_tp_change {
  my $self = shift;
  my ($attr) = @_;

  $attr->{NAS_TP} = (defined($attr->{NAS_TP})) ? int($attr->{NAS_TP}) : 0;

  $self->changes(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'dillers_tps',
      DATA         => $attr
    }
  );

  return $self->{result};
}

#**********************************************************
=head2 dillers_tp_del(attr);

=cut
#**********************************************************
sub dillers_tp_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('dillers_tps',$attr);

  $admin->system_action_add("DILLERS_TP:$self->{TP_ID}", { TYPE => 10 });
  return $self->{result};
}

#**********************************************************
=head2 dillers_tp_list()

=cut
#**********************************************************
sub dillers_tp_list {
  my $self = shift;
  my ($attr) = @_;

  my $WHERE = $self->search_former($attr, [
      ['ID',      'INT',  'id'      ],
      ['NAME',    'STR',  'name'    ],
      ['NAS_TP',  'INT',  'NAS_TP'  ],
    ],
    { WHERE => 1,
    }
  );

  $self->query("SELECT
      name,
      percentage,
      operation_payment,
      payment_type,
      id,
      comments,
      bonus_cards
    FROM dillers_tps tp
    $WHERE;",
    undef,
    $attr
  );

  return $self->{list};
}

#**********************************************************
=head2 dillers_tp_info($attr)

=cut
#**********************************************************
sub dillers_tp_info {
  my $self = shift;
  my ($attr) = @_;

  $self->query("SELECT
      id,
      name,
      payment_type,
      percentage,
      operation_payment,
      payment_expr,
      activate_price,
      change_price,
      credit,
      min_use,
      nas_tp,
      gid,
      comments,
      bonus_cards
    FROM dillers_tps
    WHERE id= ? ;",
    undef,
    { INFO => 1,
      Bind => [ $attr->{ID} ] }
  );

  return $self;
}

#**********************************************************
=head2 diller_permissions_set()

=cut
#**********************************************************
sub diller_permissions_set {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('dillers_permits', undef, { diller_id => $attr->{DILLER_ID} });

  my @permits = split(/, /, $attr->{PERMITS});
  my @MULTI_QUERY = ();

  foreach my $section (@permits) {
    push @MULTI_QUERY, [ $attr->{DILLER_ID}, $section ];
  }

  $self->query("INSERT INTO dillers_permits (diller_id, section)
        VALUES (?, ?);",
    undef,
    { MULTI_QUERY =>  \@MULTI_QUERY });


  return $self;
}

#**********************************************************
=head2 get_permissions()

=cut
#**********************************************************
sub diller_permissions_list {
  my $self        = shift;
  my ($attr)      = @_;
  my %permissions = ();

  $self->query("SELECT section, actions FROM dillers_permits WHERE diller_id= ? ;", undef, { Bind => [ $attr->{DILLER_ID} ] });

  foreach my $line (@{ $self->{list} }) {
    $permissions{ $line->[0] } = 1;
  }

  $self->{permissions} = \%permissions;

  return $self->{permissions};
}


1;
