package Companies;

=head1 NAME

  Companies

=cut

use strict;
use parent qw(dbcore);
use Users;
use Conf;
use Bills;

my $users;
my $admin;
my $CONF;
my $MODULE = 'Companies';

#**********************************************************
# Init
#**********************************************************
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

  $users = Users->new($db, $admin, $CONF);

  return $self;
}

#**********************************************************
=head2 add($attr) - Add companies

=cut
#**********************************************************
sub add {
  my $self = shift;
  my ($attr) = @_;

  if (! $attr->{NAME}) {
    $self->{errno}  = 8;
    $self->{errstr} = 'ERROR_ENTER_NAME';
    return $self;
  }

  if ($attr->{CONTRACT_TYPE}) {
    my (undef, $sufix) = split(/\|/, $attr->{CONTRACT_TYPE});
    $attr->{CONTRACT_SUFIX} = $sufix;
  }

  $attr = $users->info_field_attach_add({ %$attr, COMPANY_PREFIX => 1 });

  $self->query_add('companies', { %$attr,
    REGISTRATION   => $attr->{REGISTRATION} || 'NOW()',
  });

  if ($self->{errno}) {
    return $self;
  }

  $self->{COMPANY_ID} = $self->{INSERT_ID};

  if ($attr->{CREATE_BILL}) {
    $self->change({
      DISABLE         => int($attr->{DISABLE} || 0),
      ID              => $self->{COMPANY_ID},
      CREATE_BILL     => 1,
      CREATE_EXT_BILL => $attr->{CREATE_EXT_BILL}
    });
  }

  $admin->{MODULE} = $MODULE;

  my @info = ('CREATE_BILL', 'CREDIT', 'BANK_NAME', 'BANK_ACCOUNT', 'BANK_BIC', 'COR_BANK_ACCOUNT', 'TAX_NUMBER', 'REPRESENTATIVE');
  my %actions_history = ();

  foreach my $param (@info) {
    next if ! $attr->{$param};
    $actions_history{$param} = $attr->{$param};
  }

  $admin->action_add(0, join(", ", map { "$_: $actions_history{$_}" } keys %actions_history), { TYPE => 1 } );

  return $self;
}

#**********************************************************
=head2 change($attr) Change

  Arguments:
    $attr
      ID - Main parameter

  Resturn:
    $self

=cut
#**********************************************************
sub change {
  my $self = shift;
  my ($attr) = @_;

  if (!defined($attr->{DISABLE})) {
    $attr->{DISABLE} = 0;
  }

  if ($attr->{CREATE_BILL}) {
    my $Bill = Bills->new($self->{db}, $admin, $CONF);
    $Bill->create({
      COMPANY_ID => $self->{ID} || $attr->{ID},
      UID        => 0
    });
    if ($Bill->{errno}) {
      $self->{errno}  = $Bill->{errno};
      $self->{errstr} = $Bill->{errstr};
      return $self;
    }
    $attr->{BILL_ID} = $Bill->{BILL_ID};

    if ($attr->{CREATE_EXT_BILL}) {
      $Bill->create({ COMPANY_ID => $self->{ID} || $attr->{ID} });
      if ($Bill->{errno}) {
        $self->{errno}  = $Bill->{errno};
        $self->{errstr} = $Bill->{errstr};
        return $self;
      }
      $attr->{EXT_BILL_ID} = $Bill->{BILL_ID};
    }
  }
  elsif ($attr->{CREATE_EXT_BILL}) {
    my $Bill = Bills->new($self->{db}, $admin, $CONF);
    $Bill->create({ COMPANY_ID => $self->{ID} });

    if ($Bill->{errno}) {
      $self->{errno}  = $Bill->{errno};
      $self->{errstr} = $Bill->{errstr};
      return $self;
    }
    $attr->{EXT_BILL_ID} = $Bill->{BILL_ID};
  }

  $attr->{DOMAIN_ID} = $admin->{DOMAIN_ID};
  $attr = $users->info_field_attach_add({ %$attr, COMPANY_PREFIX => 1 });

  my ($prefix, $sufix);
  if ($attr->{CONTRACT_TYPE}) {
    ($prefix, $sufix) = split(/\|/, $attr->{CONTRACT_TYPE});
    $attr->{CONTRACT_SUFIX} = $sufix;
  }

  $self->changes(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'companies',
      #FIELDS       => \%FIELDS,
      #OLD_INFO     => $old_info,
      DATA         => $attr
    }
  );

  $admin->{MODULE} = $MODULE;

  my @info = ('CREATE_BILL', 'CREDIT', 'BANK_NAME', 'BANK_ACCOUNT', 'BANK_BIC', 'COR_BANK_ACCOUNT', 'TAX_NUMBER', 'REPRESENTATIVE');
  my %actions_history = ();

  foreach my $param (@info) {
    next if ! $attr->{$param};
    $actions_history{$param} = $attr->{$param};
  }

  $admin->action_add(0, join(", ", map { "$_: $actions_history{$_}" } keys %actions_history), { TYPE => 2 } );


  $self->info($attr->{ID});

  return $self;
}

#**********************************************************
=head2 del($company_id)

=cut
#**********************************************************
sub del {
  my $self = shift;
  my ($company_id) = @_;

  $self->query_del('companies', { ID => $company_id });

  $admin->{MODULE} = $MODULE;

  $admin->action_add(0, "DELETED COMPANY: $company_id", { TYPE => 10 } );

  return $self;
}

#**********************************************************
=head2 info($company_id) - Info

  Arguments:
    $company_info

=cut
#**********************************************************
sub info {
  my $self = shift;
  my ($company_id) = @_;

  $self->query("SELECT c.*,
     b.deposit
    FROM companies c
    LEFT JOIN bills b ON (c.bill_id=b.id)
    WHERE c.id= ? ;",
    undef,
    { INFO => 1,
    	Bind => [ 
    	  $company_id
    ]}
  );

  if ($self->{TOTAL} < 1) {
    $self->{errno}  = 2;
    $self->{errstr} = 'ERROR_NOT_EXIST';
    return $self;
  }

  if ($CONF->{EXT_BILL_ACCOUNT} && $self->{EXT_BILL_ID} > 0) {
    $self->query("SELECT b.deposit AS ext_bill_deposit, b.uid AS ext_bill_owner
     FROM bills b WHERE id= ? ;",
     undef,
     { INFO => 1, Bind => [ $self->{EXT_BILL_ID} ] }
    );
  }

  return $self;
}

#**********************************************************
=head2 list($attr) - List

=cut
#**********************************************************
sub list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  my $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  $attr->{SKIP_DEL_CHECK} = 1;

  my @WHERE_RULES = ();
  my $info_fields_list;

  if($CONF->{info_fields_new}) {
    require Info_fields;
    my $Info_fields = Info_fields->new($self->{db}, $admin, $CONF);
    $info_fields_list = $Info_fields->fields_list({ COMPANY => 1 });
  }
  else {
    my $Conf = Conf->new($self->{db}, $admin, $CONF);
    $info_fields_list = $Conf->config_list({ PARAM => 'ifc*', SORT => 2, COLS_NAME => 1 });
  }

  if ($info_fields_list) {
    foreach my $line (@$info_fields_list) {
      my $field_name = '';
      my $db_field_name = '';
      my (undef, $type, undef);

      if($line->{id}) {
        $db_field_name = $line->{sql_field};
        $type = $line->{type};
        $field_name = uc($db_field_name);
      }
      elsif ($line->{param} && $line->{param} =~ /ifc(\S+)/) {
        $field_name = $1;
        (undef, $type, undef) = split(/:/, $line->{value});
        $db_field_name = $field_name;
      }
      else {
        next;
      }

      if (defined($attr->{$field_name}) && $type == 4) {
        push @WHERE_RULES, 'c.' . $db_field_name . "='$attr->{$field_name}'";
      }
      #Skip for bloab
      elsif ($type == 5) {
        next;
      }
      elsif ($attr->{$field_name}) {
        if ($type == 1) {
          my $value = $self->search_expr($attr->{$field_name}, 'INT');
          push @WHERE_RULES, "(c." .  $db_field_name . "$value)";
        }
        elsif ($type == 2) {
          push @WHERE_RULES, "(c.$db_field_name='$attr->{$field_name}')";
          $self->{SEARCH_FIELDS} .= "$db_field_name" . '_list.name AS ' .  $db_field_name . '_list_name, ';
          $self->{SEARCH_FIELDS_COUNT}++;
          $self->{EXT_TABLES} .= "LEFT JOIN  $db_field_name" . "_list ON (c. $db_field_name =  $db_field_name" . "_list.id)";
          next;
        }
        else {
          $attr->{$field_name} =~ s/\*/\%/ig;
          if($attr->{$field_name} ne '_SHOW') {
            push @WHERE_RULES, "c.$db_field_name LIKE '$attr->{$field_name}'";
          }
        }

        $self->{SEARCH_FIELDS} .= "c.$db_field_name, ";
        $self->{SEARCH_FIELDS_COUNT}++;
      }
    }

    $self->{EXTRA_FIELDS} = $info_fields_list;
  }

  my $WHERE =  $self->search_former($attr, [
    ['COMPANY_NAME',   'STR',  'c.name',            ],
    ['DEPOSIT',        'INT',  'cb.deposit',      1 ],
    ['CREDIT',         'INT',  'c.credit',        1 ],
    ['USERS_COUNT',    'INT',  'COUNT(u.uid) AS users_count', 1 ],
    ['CREDIT_DATE',    'DATE', 'c.credit_date',   1 ],
    ['ADDRESS',        'STR',  'c.address',       1 ],
    ['REGISTRATION',   'DATE', 'c.registration',  1 ],
    ['DISABLE',        'INT',  'c.disable AS status',  1 ],
    ['CONTRACT_ID',    'INT',  'c.contract_id',   1 ],
    ['CONTRACT_DATE',  'DATE', 'c.contract_date', 1 ],
    ['CONTRACT_SUFIX', 'STR',  'c.contract_sufix',1 ],
    ['ID',             'INT',  'c.id'               ],
    ['BILL_ID',        'INT',  'c.bill_id',       1 ],
    ['TAX_NUMBER',     'STR',  'c.tax_number',    1 ],
    ['BANK_ACCOUNT',   'STR',  'c.bank_account',  1 ],
    ['BANK_NAME',      'STR',  'c.bank_name',     1 ],
    ['COR_BANK_ACCOUNT','STR', 'c.cor_bank_account', 1],
    ['BANK_BIC',       'STR',  'c.bank_bic',      1 ],
    ['PHONE',          'STR',  'c.phone',         1 ],
    ['VAT',            'INT',  'c.vat',           1 ],
    ['EXT_BILL_ID',    'INT',  'c.ext_bill_id',   1 ],
    ['DOMAIN_ID',      'INT',  'c.domain_id',     1 ],
    ['REPRESENTATIVE', 'STR',  'c.representative',1 ],
    ['LOCATION_ID',    'INT',  'c.location_id',   1 ],
    ['ADDRESS_FLAT',   'STR',  'c.address_flat',  1 ],
    ['COMPANY_ADMIN',  'INT',  'u.uid',           1 ],
    ['COMPANY_ID',     'INT',  'c.id',              ],
    ['EDRPOU',         'STR',  'c.edrpou',        1 ],
    #['DOMAIN_ID',      'INT',  'c.domain_id',     1 ],
  ],
    {
      WHERE_RULES      => \@WHERE_RULES,
      USERS_FIELDS_PRE => 1,
      #USE_USER_PI      => 1,
      SKIP_USERS_FIELDS=> [ 'DEPOSIT', 'CREDIT', 'BILL_ID', 'CREDIT_DATE', 'ADDRESS',
        'REGISTRATION', 'CONTRACT_ID', 'CONTRACT_DATE', 'PHONE', 'FIO',
        'DOMAIN_ID', 'LOCATION_ID', 'ADDRESS_FLAT', 'DOMAIN_ID', 'COMPANY_NAME'
      ],
      WHERE            => 1,
    }
  );

  my $EXT_TABLE = $self->{EXT_TABLES};
  if($attr->{COMPANY_ADMIN}) {
    $EXT_TABLE .= "LEFT JOIN companie_admins ca ON (ca.uid = u.uid)";
  }

  #  if($self->{SEARCH_FIELDS} =~ /pi\./) {
#    $EXT_TABLE .= "LEFT JOIN users_pi pi ON (u.uid = pi.uid)";
#  }
  
#  if ($self->{SEARCH_FIELDS} =~ /streets\.|builds\./){
#    $EXT_TABLE .= qq{ LEFT JOIN builds ON (builds.id = c.location_id)
#                      LEFT JOIN streets ON (streets.id = builds.street_id)
#                      LEFT JOIN districts ON (districts.id = streets.district_id)
#    };
#  }

  $self->query("SELECT c.name, $self->{SEARCH_FIELDS} c.id
    FROM companies  c
    LEFT JOIN users u ON (u.company_id=c.id)
    $EXT_TABLE
    $WHERE
    GROUP BY c.id
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list};

  if ($self->{TOTAL} > 0 || $PG > 0) {
    $self->query("SELECT COUNT(DISTINCT c.id) AS total
    FROM companies c
    LEFT JOIN users u ON (u.company_id=c.id)
    $EXT_TABLE
    $WHERE;",
    undef,
    { INFO => 1 });
  }

  return $list || [];
}

#**********************************************************
=head2 admins_list($attr)

=cut
#**********************************************************
sub admins_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  my $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;
  my @WHERE_RULES = ();

  if ($attr->{UID}) {
    push @WHERE_RULES, "u.uid='$attr->{UID}'";
  }

  if ($attr->{GET_ADMINS}) {
    push @WHERE_RULES, "ca.uid>0";
  }

  if ($attr->{COMPANY_ID}) {
    push @WHERE_RULES, "c.id='$attr->{COMPANY_ID}'";
  }

  my $WHERE = ($#WHERE_RULES > -1) ? 'WHERE '. join(' AND ', @WHERE_RULES) : q{};

  $self->query("SELECT IF(ca.uid IS null, 0, 1) AS is_company_admin,
      u.id AS login,
      pi.fio,
      (SELECT GROUP_CONCAT(value SEPARATOR ';') FROM `users_contacts` uc WHERE uc.uid=u.uid AND type_id=9) AS email,
      u.uid,
      ca.company_id
    FROM companies  c
    INNER JOIN users u ON (u.company_id=c.id)
    LEFT JOIN companie_admins ca ON (ca.uid=u.uid)
    LEFT JOIN users_pi pi ON (pi.uid=u.uid)
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
=head2 admins_change($attr)

=cut
#**********************************************************
sub admins_change {
  my $self = shift;
  my ($attr) = @_;

  my @ADMINS = split(/, /, $attr->{IDS});

  $self->query_del('companie_admins', undef, { company_id => $attr->{COMPANY_ID} });

  foreach my $uid (@ADMINS) {
    $self->query_add('companie_admins', { %$attr,
    	                                    UID => $uid
    	                                  });
  }

  return $self;
}

#**********************************************************
=head2 with_info_tables($attr) - info from companies WITH info fields

  Experimental

=cut
#**********************************************************
sub with_info_fields {
  my $self = shift;
  my ($attr) = @_;

  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  my $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;
  my @WHERE_RULES = ();

  if ($attr->{UID}) {
    push @WHERE_RULES, "u.uid='$attr->{UID}'";
  }

  if ($attr->{COMPANY_ID}) {
    push @WHERE_RULES, "c.id='$attr->{COMPANY_ID}'";
  }

  my @search_fields = ();
  my $ext_tables = '';

  my $Conf = Conf->new($self->{db}, $admin, $CONF);
  my $info_fields_list = $Conf->config_list({ PARAM => 'ifc*', SORT => 2 });

  if ($info_fields_list && ref $info_fields_list eq 'ARRAY' && scalar(@$info_fields_list)) {
    foreach my $line (@{$info_fields_list}) {
      if ($line->[0] =~ /ifc(\S+)/) {
        my $field_name = $1;
        my (undef, $type, undef) = split(/:/, $line->[1]);

        next if $type ne '2';
        push (@search_fields,
          "$field_name\_list.name AS $field_name",
          "$field_name AS $field_name\_id"
        );
        $ext_tables .= "LEFT JOIN $field_name" . "_list ON (c.$field_name = $field_name" . "_list.id)";
      }
    }
  }


  my $search_fields = join(',', @search_fields);
  $search_fields = ', ' . $search_fields if ($search_fields);

  my $WHERE = ($#WHERE_RULES > -1) ? 'WHERE '. join(' AND ', @WHERE_RULES) : q{};

  $self->query(
    "SELECT c.*
      $search_fields
    FROM companies c
      $ext_tables
      $WHERE
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;",
    undef,
      { INFO => 1 }
  );

  return $self;
}

1
