package Users;

=head1 NAME

  Users manage functions

=cut

use strict;
use parent 'dbcore';
use Conf;

my $admin;
my $CONF;
my $SORT = 1;
my $DESC = '';
my $PG   = 1;
my $PAGE_ROWS = 25;

my $usernameregexp = "^[a-z0-9_][a-z0-9_-]*\$";    # configurable;

#**********************************************************
=head2 new($db, $admin, $conf)

=cut
#**********************************************************
sub new {
  my $class = shift;
  my ($db)  = shift;
  ($admin, $CONF) = @_;

  $admin->{MODULE} = '';
  $CONF->{MAX_USERNAME_LENGTH} = 10 if (!defined($CONF->{MAX_USERNAME_LENGTH}));
  $CONF->{BUILD_DELIMITER} = ', ' if (!defined($CONF->{BUILD_DELIMITER}));

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $CONF
  };

  bless($self, $class);

  if (defined($CONF->{USERNAMEREGEXP})) {
    $usernameregexp = $CONF->{USERNAMEREGEXP};
  }

  return $self;
}

#**********************************************************
=head2 info($uid, $attr) - Account general information

  Argumenst:
    $uid
    $attr
      LOGIN
      PASSWORD
      SHOW_PASSWORD

  Returns:
    Object

=cut
#**********************************************************
sub info {
  my $self = shift;
  my ($uid, $attr) = @_;

  if (!$attr->{USERS_AUTH} && ! $self->check_params()) {
    return $self;
  }

  my $WHERE='';
  my @values   = ();

  if (defined($attr->{LOGIN}) && defined($attr->{PASSWORD})) {
    $WHERE = "WHERE u.id=? and DECODE(u.password, '$self->{conf}->{secretkey}')= ? ";
    @values= ($attr->{LOGIN}, $attr->{PASSWORD});

    if ($attr->{ACTIVATE}) {
      my $value = $self->search_expr($attr->{ACTIVATE}, 'DATE');
      $WHERE .= " AND u.activate$value";
    }

    if ($attr->{EXPIRE}) {
      my $value = $self->search_expr($attr->{EXPIRE}, 'DATE');
      $WHERE .= " AND u.expire$value";
    }

    if (defined($attr->{DISABLE})) {
      $WHERE .= " AND u.disable= ? ";
      push @values, $attr->{DISABLE};
    }
  }
  elsif ($attr->{LOGIN}) {
    $WHERE = "WHERE u.id= ? ";
    push @values, $attr->{LOGIN};
  }
  else {
    $WHERE = "WHERE u.uid= ? ";
    push @values, $uid;
  }

  if ($attr->{DOMAIN_ID}) {
    $WHERE .= "AND u.domain_id= ? ";
    push @values, $attr->{DOMAIN_ID};
  }

  my $password = "''";
  if ($attr->{SHOW_PASSWORD}) {
    $password = "DECODE(u.password, '$self->{conf}->{secretkey}') AS password";
  }

  $self->query(
    "SELECT
      u.uid,
      u.gid,
      g.name AS g_name,
      u.id AS login,
      u.activate,
      u.expire,
      u.credit,
      u.reduction,
      u.registration,
      u.disable,
      IF(u.company_id > 0, cb.id, b.id) AS bill_id,
      IF(c.name IS NULL, b.deposit, cb.deposit) AS deposit,
      u.company_id,
      IF(c.name IS NULL, '', c.name) AS company_name,
      IF(c.name IS NULL, 0, c.vat) AS company_vat,
      IF(c.name IS NULL, b.uid, cb.uid) AS bill_owner,
      IF(u.company_id > 0, c.ext_bill_id, u.ext_bill_id) AS ext_bill_id,
      u.credit_date,
      u.reduction_date,
      IF(c.name IS NULL, 0, c.credit) AS company_credit,
      u.domain_id,
      u.deleted,
      $password
    FROM `users` u
    LEFT JOIN `bills` b ON (u.bill_id=b.id)
    LEFT JOIN `groups` g ON (u.gid=g.gid)
    LEFT JOIN `companies` c ON (u.company_id=c.id)
    LEFT JOIN `bills` cb ON (c.bill_id=cb.id)
    $WHERE;",
    undef,
    { INFO => 1,
      Bind => \@values
    }
  );

  if ((!$admin->{permissions}->{0} || !$admin->{permissions}->{0}->{8}) && ($self->{DELETED})) {
    $self->{errno}  = 2;
    $self->{errstr} = 'ERROR_NOT_EXIST';
    return $self;
  }

  if ($self->{conf}->{EXT_BILL_ACCOUNT} && $self->{EXT_BILL_ID} && $self->{EXT_BILL_ID} > 0) {
    $self->query(
      "SELECT
        b.deposit AS ext_bill_deposit,
        b.uid AS ext_bill_owner
      FROM bills b WHERE id= ? ;",
      undef,
      { INFO => 1,
        Bind => [ $self->{EXT_BILL_ID} ] }
    );

    if($self->{errno}) {
      delete $self->{errno};
    }
  }

  return $self;
}

#**********************************************************
=head2 pi_add($attr)

  Arguments:
    $attr
      EMAIL
      SKIP_EMAIL_CHECK

=cut
#**********************************************************
sub pi_add {
  my $self = shift;
  my ($attr) = @_;

  $self->_space_trim($attr);

  if ($attr->{EMAIL} && ! $attr->{SKIP_EMAIL_CHECK}) {
    if ($attr->{EMAIL} !~ /(([^<>()[\]\\.,;:\s\@\"]+(\.[^<>()[\]\\.,;:\s\@\"]+)*)|(\".+\"))\@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))/) {
      $self->{errno}  = 11;
      $self->{errstr} = 'ERROR_WRONG_EMAIL';
      return $self;
    }
  }

  $self->info_field_attach_add($attr);
  $attr->{CONTRACT_SUFIX} = $attr->{CONTRACT_TYPE};

  if ($attr->{CONTRACT_TYPE}) {
    my (undef, $sufix) = split(/\|/, $attr->{CONTRACT_TYPE});
    $attr->{CONTRACT_SUFIX} = $sufix || $attr->{CONTRACT_TYPE};
  }

  if ($attr->{STREET_ID} && $attr->{ADD_ADDRESS_BUILD} && ! $attr->{LOCATION_ID}) {
    require Address;
    Address->import();

    my $Address = Address->new($self->{db}, $admin, $self->{conf});
    $Address->build_add({
      %$attr,
      COMMENTS => q{}
    });

    $attr->{LOCATION_ID} = $Address->{LOCATION_ID};
  }

  if ($attr->{PHONE} || $attr->{EMAIL}) {
    require Contacts;
    Contacts->import();
    my $Contacts = Contacts->new($self->{db}, $self->{admin}, $self->{conf});

    $Contacts->contacts_add({ TYPE_ID => 2, VALUE => $attr->{PHONE}, UID => $attr->{UID} }) if ($attr->{PHONE});
    $Contacts->contacts_add({ TYPE_ID => 9, VALUE => $attr->{EMAIL}, UID => $attr->{UID} }) if ($attr->{EMAIL});
  }

  $self->query_add('users_pi', { %$attr });

  return [ ] if ($self->{errno});

  $admin->{MODULE} = q{};

  $admin->action_add($attr->{UID}, '', {
    TYPE    => 1,
    INFO    => [ 'FIO', 'CONTRACT_ID', 'CONTRACT_DATE', 'BUILD_ID', 'ADDRESS_FLAT' ],
    REQUEST => $attr
  });

  return $self;
}

#**********************************************************
=head2 pi($attr) Personal inforamtion

  Arguments:
    $attr
      UID

  Returns:
    $self

=cut
#**********************************************************
sub pi {
  my $self = shift;
  my ($attr) = @_;

  my $uid = ($attr->{UID}) ? $attr->{UID} : $self->{UID};

  # Process info fields with type "List"
  my @search_fields = ();
  my $ext_tables = '';

  my $info_fields_list = $self->{INFO_FIELDS_LIST} || $self->config_list({ PARAM => 'ifu*', SORT => 2 });
  if ($info_fields_list && ref $info_fields_list eq 'ARRAY' && scalar(@$info_fields_list)) {
    foreach my $line (@{$info_fields_list}) {
      if ($line->[0] =~ /ifu(\S+)/) {
        my $field_name = $1;
        my (undef, $type, undef) = split(/:/, $line->[1]);

        next if $type ne '2';
        push (@search_fields,
          "$field_name\_list.name AS $field_name",
          "$field_name AS $field_name\_id"
        );
        $ext_tables .= "LEFT JOIN $field_name" . "_list ON (pi.$field_name = $field_name" . "_list.id)";
      }
    }
  }

  my $search_fields = join(',', @search_fields);
  $search_fields = ', ' . $search_fields if ($search_fields);

  $self->query("SELECT pi.* $search_fields
    FROM users_pi pi $ext_tables
    WHERE pi.uid= ? ;",
    undef,
    { INFO => 1,
      Bind => [ $uid ] }
  );

  if ($self->{TOTAL} < 1) {
    $self->{errno} = 2;
    $self->{errstr} = 'ERROR_NOT_EXIST';
    return $self;
  }

  if ( ($self->{FIO} || $self->{FIO} eq '' ) && ($self->{FIO2} || $self->{FIO3} )) {
    $self->{FIO1} = $self->{FIO};
    $self->{FIO} = join (' ', ($self->{FIO1} || q{}), ($self->{FIO2} || q{}), ($self->{FIO3} || q{}));
  }

  if (!$self->{errno} && $self->{LOCATION_ID} && ! $attr->{SKIP_LOCATION}) {
    require Address;
    Address->import();
    my $Address = Address->new($self->{db}, $admin, $self->{conf});

    $Address->address_info($self->{LOCATION_ID});

    $self->{DISTRICT_ID} = $Address->{DISTRICT_ID};
    $self->{CITY} = $Address->{CITY};
    $self->{ADDRESS_DISTRICT} = $Address->{ADDRESS_DISTRICT};
    $self->{STREET_ID} = $Address->{STREET_ID};
    $self->{ZIP} = $Address->{ZIP};
    $self->{COORDX} = $Address->{COORDX};
    $self->{COUNTRY} = $Address->{COUNTRY};

    $self->{ADDRESS_STREET} = $Address->{ADDRESS_STREET};
    $self->{ADDRESS_STREET2} = $Address->{ADDRESS_STREET2};
    $self->{ADDRESS_BUILD} = $Address->{ADDRESS_BUILD};
    $self->{ADDRESS_FLORS} = $Address->{ADDRESS_FLORS};

    if ($self->{conf}->{STREET_TYPE}) {
      $self->{ADDRESS_STREET_TYPE_NAME} = (split (';', $self->{conf}->{STREET_TYPE}))[$Address->{STREET_TYPE}];
    }
    #else {
    $self->{ADDRESS_STREET_TYPE_NAME} //= '';
    #}
    $self->{ADDRESS_STREET} //= q{};
    $self->{ADDRESS_BUILD} //= q{};
    $self->{ADDRESS_FLAT} //= q{};

    if ($CONF->{ADDRESS_FORMAT}) {
      my $address = $CONF->{ADDRESS_FORMAT};
      while($address =~ /\%([A-Z\_0-9]+)\%/g) {
        my $pattern = $1;
        $address =~ s/\%$pattern\%/$self->{$pattern}/g;
      }

      $self->{ADDRESS_FULL} = $address;
    }
    else {
      $self->{ADDRESS_FULL} = "$self->{ADDRESS_STREET_TYPE_NAME} $self->{ADDRESS_STREET}$self->{conf}->{BUILD_DELIMITER}$self->{ADDRESS_BUILD}$self->{conf}->{BUILD_DELIMITER}$self->{ADDRESS_FLAT}";
    }
  }

  if (!$self->{errno}) {
    require Contacts;
    Contacts->import();
    my $Contacts = Contacts->new($self->{db}, $admin, $self->{conf});

    my $contact_types = $Contacts->contact_types_list({
      #ID        => '_SHOW',
      NAME      => '_SHOW',
      COLS_NAME => 1,
      PAGE_ROWS => 1000
    });

    my $contacts;
    if (!$Contacts->{errno} && $contact_types && ref $contact_types) {
      $contacts = $Contacts->contacts_list({
        UID       => $uid,
        VALUE     => '_SHOW',
        TYPE      => '_SHOW',
        COLS_NAME => 1,
        PAGE_ROWS => 10000,
        SORT      => 'priority'
      });
    }

    if (!$Contacts->{errno} && $contacts && ref $contacts) {
      foreach my $cont_type (@$contact_types) {
        my $uc_contact_type_name = uc($cont_type->{name});
        my @contacts_for_type = grep {$_->{type_id} == $cont_type->{id}} @$contacts;

        $self->{$uc_contact_type_name . '_ALL'} = join(', ', map {$_->{value} || ''} @contacts_for_type);
        if (@contacts_for_type) {
          for (my $i = 0; $i <= $#contacts_for_type; $i++) {
            $self->{ $uc_contact_type_name . ($i > 0 ? '_' . $i : '')} = $contacts_for_type[$i]->{value};
          }
        }
      }
      $self->{PHONE} ||= $self->{CELL_PHONE};
    }
  }

  $self->{TOTAL} = 1;

  return $self;
}

#**********************************************************
=head2 pi_change($attr) - Personal Info change

  Arguments:
    $attr
      UID   - Main id

  Resturns:
    $self

=cut
#**********************************************************
sub pi_change {
  my $self = shift;
  my ($attr) = @_;

  $self->_space_trim($attr);

  $self->user_contacts_validation($attr);

  if ($self->{errno}) {
    return $self;
  }

  if ($attr->{STREET_ID} && $attr->{ADD_ADDRESS_BUILD}) {
    require Address;
    Address->import();
    my $Address = Address->new($self->{db}, $admin, $self->{conf});
    $Address->build_add({
      %$attr,
      COMMENTS => q{}
    });
    $attr->{LOCATION_ID}=$Address->{LOCATION_ID};
  }

  if (!$attr->{SKIP_INFO_FIELDS}) {
    $self->info_field_attach_add($attr);
    if($self->{errno}) {
      return $self;
    }
  }

  $attr->{CONTRACT_SUFIX} = $attr->{CONTRACT_TYPE};
  if ($attr->{CONTRACT_TYPE}) {
    my (undef, $sufix) = split(/\|/, $attr->{CONTRACT_TYPE});
    $attr->{CONTRACT_SUFIX} = $sufix;
  }

  $admin->{MODULE} = '';

  my $phone_changed = defined $self->{PHONE_ALL} && defined $attr->{PHONE} && ($self->{PHONE_ALL} ne $attr->{PHONE});
  my $cell_phone_changed = defined $self->{CELL_PHONE_ALL} && defined $attr->{CELL_PHONE} && ($self->{CELL_PHONE_ALL} ne $attr->{CELL_PHONE});
  my $mail_changed = defined $self->{EMAIL} && defined $attr->{EMAIL} && ($self->{EMAIL} ne $attr->{EMAIL});

  if ($phone_changed || $mail_changed || $cell_phone_changed) {
    require Contacts;
    Contacts->import();
    my $Contacts = Contacts->new($self->{db}, $self->{admin}, $self->{conf});

    if ($cell_phone_changed) {
      # MAYBE check it is really a cell phone via regexp
      $Contacts->contacts_change_all_of_type($Contacts->contact_type_id_for_name('CELL_PHONE'), {
        UID   => $self->{UID},
        VALUE => $attr->{CELL_PHONE}
      });
      delete $attr->{CELL_PHONE};
    }
    if ($phone_changed) {
      # MAYBE check it is really a cell phone via regexp
      $Contacts->contacts_change_all_of_type($Contacts->contact_type_id_for_name('PHONE'), {
        UID   => $self->{UID},
        VALUE => $attr->{PHONE}
      });
      delete $attr->{PHONE};
    }
    if ($mail_changed) {

      $Contacts->contacts_change_all_of_type($Contacts->contact_type_id_for_name('EMAIL'), {
        UID   => $self->{UID},
        VALUE => $attr->{EMAIL}
      });

      delete $attr->{EMAIL};
    }
  }

  $self->changes({
    CHANGE_PARAM => 'UID',
    TABLE        => 'users_pi',
    DATA         => $attr
  });

  return $self;
}

#**********************************************************
=head2 groups_list($attr) - List of groups

=cut
#**********************************************************
sub groups_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my @WHERE_RULES = ();
  delete $self->{COL_NAMES_ARR};

  # Show groups
  if ($attr->{GIDS} || $admin->{GIDS}) {
    if ($admin->{GIDS}) {
      my @result_gids = ();
      my @admin_gids  = split(/, /, $admin->{GIDS});
      my @attr_gids   = split(/, /, $attr->{GIDS} || q{});

      foreach my $attr_gid ( @attr_gids ) {
        foreach my $admin_gid (@admin_gids)  {
          if ($admin_gid == $attr_gid) {
            push @result_gids, $attr_gid;
            last;
          }
        }
      }

      $attr->{GIDS}=join(', ', @result_gids);
    }

    push @WHERE_RULES, "g.gid IN ($attr->{GIDS})";
  }
  elsif (defined($attr->{GID}) && $attr->{GID} =~ /\d+/) {
    $attr->{GID} =~ s/,/;/g;
    push @WHERE_RULES,  @{ $self->search_expr($attr->{GID}, 'INT', 'g.gid') };
  }
  elsif ($admin->{GIDS}) {
    push @WHERE_RULES, "g.gid IN ($admin->{GIDS})";
  }

  my $USERS_WHERE = '';
  if ($admin->{DOMAIN_ID}) {
    $admin->{DOMAIN_ID} =~ s/,/;/g;
    $USERS_WHERE = "AND (". join('AND', @{ $self->search_expr($admin->{DOMAIN_ID}, 'INT', 'u.domain_id' ) }) .')';
  }

  my $WHERE = $self->search_former($attr, [
      ['DOMAIN_ID',        'INT', 'g.domain_id',                 1 ],
      ['G_NAME',           'STR', 'g.name AS g_name',            1 ],
      ['DISABLE_PAYMENTS', 'INT', 'g.disable_payments',          1 ],
      ['GID',              'INT', 'g.gid',                       1 ],
      ['NAME',             'STR', 'g.name',                      1 ],
      ['BONUS',            'INT', 'g.bonus',                     1 ],
      ['DESCR',            'STR', 'g.descr',                     1 ],
      ['ALLOW_CREDIT',     'INT', 'g.allow_credit',              1 ],
      ['DISABLE_PAYSYS',   'INT', 'g.disable_paysys',            1 ],
      ['DISABLE_CHG_TP',   'INT', 'g.disable_chg_tp',            1 ],
      ['USERS_COUNT',      'INT', 'COUNT(u.uid) AS users_count', 1 ],
      ['SMS_SERVICE',      'STR', 'g.sms_service',               1 ],
      ['DOCUMENTS_ACCESS', 'INT', 'g.documents_access',          1 ],
      ['DISABLE_ACCESS',   'INT', 'g.disable_access',            1 ],
  ],
    { WHERE => 1, WHERE_RULES => \@WHERE_RULES }
  );

  $self->query("SELECT g.gid AS id,
        $self->{SEARCH_FIELDS}
        g.domain_id
        FROM `groups` g
        LEFT JOIN `users` u ON (u.gid=g.gid $USERS_WHERE)
        $WHERE
        GROUP BY g.gid
        ORDER BY $SORT $DESC",
    undef,
    $attr
  );

  my $list = $self->{list} || [];

  if ($self->{TOTAL} > 0) {
    $self->query("SELECT COUNT(*) AS total FROM `groups` g $WHERE", undef, { INFO => 1 });
  }

  return $list;
}

#**********************************************************
=head2 group_info($gid)

=cut
#**********************************************************
sub group_info {
  my $self = shift;
  my ($gid) = @_;

  $self->query("SELECT * FROM `groups` g WHERE g.gid= ? ;",
   undef,
   { INFO => 1,
     Bind => [ $gid ]   });

  return $self;
}

#**********************************************************
=head2 group_change($gid, $attr)

=cut
#**********************************************************
sub group_change {
  my $self = shift;
  my ($gid, $attr) = @_;

  $attr->{SEPARATE_DOCS} = $attr->{SEPARATE_DOCS} ? 1 : 0;
  $attr->{ALLOW_CREDIT} = $attr->{ALLOW_CREDIT} ? 1 : 0;
  $attr->{DISABLE_PAYSYS} = $attr->{DISABLE_PAYSYS} ? 1 : 0;
  $attr->{DISABLE_PAYMENTS} = $attr->{DISABLE_PAYMENTS} ? 1 : 0;
  $attr->{DISABLE_CHG_TP} = $attr->{DISABLE_CHG_TP} ? 1 : 0;
  $attr->{BONUS} = $attr->{BONUS} ? 1 : 0;
  $attr->{DOCUMENTS_ACCESS} = $attr->{DOCUMENTS_ACCESS} ? 1 : 0;
  $attr->{DISABLE_ACCESS} = $attr->{DISABLE_ACCESS} ? 1 : 0;

  $attr->{GID} = $gid;

  $self->changes({
    CHANGE_PARAM    => 'GID',
    TABLE           => 'groups',
    DATA            => $attr,
    EXT_CHANGE_INFO => "GID:$gid"
  });

  return $self;
}

#**********************************************************
=head2 group_add($attr)

=cut
#**********************************************************
sub group_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('groups', { %$attr, DOMAIN_ID => $admin->{DOMAIN_ID} || $attr->{DOMAIN_ID} });

  $admin->system_action_add("GID:$attr->{GID}", { TYPE => 1 });

  return $self;
}

#**********************************************************
=head2 group_add($id)

=cut
#**********************************************************
sub group_del {
  my $self = shift;
  my ($id) = @_;

  $self->query_del('groups', undef, { gid=> $id });

  $admin->system_action_add("GID:$id", { TYPE => 10 });
  return $self;
}

#**********************************************************
=head2 list($attr) - List users

  Arguments:
    $attr

  Returns
    array_of_hash

=cut
#**********************************************************
sub list {
  my $self   = shift;
  my ($attr) = @_;

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my @WHERE_RULES = ();
  if ($attr->{UNIVERSAL_SEARCH}) {
    $attr->{SKIP_DEL_CHECK} = 1;
    $attr->{_MULTI_HIT}     = 1;
    $SORT = 1;
  }

  if ($attr->{LAST_ACTIVE_USER}) {
    push @WHERE_RULES, "disable = 0";
  }

  if ($attr->{TAGS} && $attr->{TAGS} eq '!') {
    push @WHERE_RULES, "u.uid NOT IN (SELECT uid FROM tags_users)";
    delete ($attr->{TAGS});
  }

  my @ext_fields = (
    'FIO',
    'FIO2',
    'FIO3',
    'DEPOSIT',
    'EXT_DEPOSIT',
    'EXT_BILL_ID',
    'CREDIT',
    'CREDIT_DATE',
    'LOGIN_STATUS',
    'PHONE',
    'EMAIL',
    'FLOOR',
    'ENTRANCE',
    'ADDRESS_FLAT',
    'PASPORT_DATE',
    'PASPORT_NUM',
    'PASPORT_GRANT',
    'CITY',
    'ZIP',
    'GID',
    'COMPANY_ID',
    'COMPANY_NAME',
    'CONTRACT_ID',
    'CONTRACT_SUFIX',
    'CONTRACT_DATE',
    'EXPIRE',
    'REDUCTION',
    'LAST_PAYMENT',
    'LAST_FEES',
    'REGISTRATION',
    'REDUCTION_DATE',
    'COMMENTS',
    'BILL_ID',
    'ACTIVATE',
    'EXPIRE',
    'ACCEPT_RULES',
    'UID',
    'PASSWORD',
    'BIRTH_DATE',
    'TAX_NUMBER',
    'CELL_PHONE',
    'TELEGRAM',
    'VIBER'
  );

  if ($admin->{DOMAIN_ID}) {
    $attr->{SKIP_DOMAIN} = 1;
    delete $attr->{DOMAIN_ID};
  }
  else {
    push @ext_fields, 'DOMAIN_ID';
  }

  push @WHERE_RULES, @{ $self->search_expr_users({ %$attr,
    EXT_FIELDS  => \@ext_fields,
    USE_USER_PI => 1,
    SKIP_GID    => ($admin->{GID} && $attr->{_MULTI_HIT}) ? 1 : undef
  }) };

  #Presql error field parse
  if ($self->{errno}) {
    return $self;
  }

  if($attr->{REGISTRATION_FROM_REGISTRATION_TO}){
    my ($from, $to) = split '/', $attr->{REGISTRATION_FROM_REGISTRATION_TO};
    push @WHERE_RULES, "u.registration >= '$from'";
    push @WHERE_RULES, "u.registration <= '$to'";
  }


  # Show debeters
  if ($attr->{DEBETERS}) {
    push @WHERE_RULES, "IF(company.id IS NULL, b.deposit, cb.deposit)<0";
  }

  if (defined($attr->{DISABLE}) && $attr->{DISABLE} ne '') {
    push @WHERE_RULES, @{ $self->search_expr($attr->{DISABLE}, 'INT', 'u.disable') };
  }
  if ($attr->{ACTIVE}) {
    push @WHERE_RULES, "(u.expire = '0000-00-00' OR u.expire>CURDATE()) AND u.credit + IF(company.id IS NULL, b.deposit, cb.deposit) > 0 AND u.disable=0 ";
  }

  my $EXT_TABLES = $self->{EXT_TABLES};

  if ($attr->{PAID}) {
    push @WHERE_RULES, "u.uid IN ( SELECT p2.uid FROM payments p2 WHERE p2.date >= DATE_FORMAT(CURDATE(), '%Y-%m-01 00:00:00') GROUP BY p2.uid)";
  }

  if ($attr->{UNPAID}) {
    $EXT_TABLES .= "LEFT JOIN payments p ON (p.uid=u.uid && p.date > DATE_FORMAT(CURDATE(), '%Y-%m-01 00:00:00'))";
    push @WHERE_RULES, "p.date IS NULL";
  }

  # if ($attr->{FORGOT_PASSWD} && $attr->{EMAIL} eq '_SHOW') {
  #   @WHERE_RULES = ();
  #   push @WHERE_RULES, "(((SELECT GROUP_CONCAT(value SEPARATOR ';') FROM users_contacts uc WHERE uc.uid=u.uid AND type_id IN (1,2))
  #                       LIKE '%" . $attr->{PHONE} ."%') AND (u.id='" . $attr->{LOGIN} . "') AND u.deleted='0') AND u.deleted=0";
  # }
  #
  # if ($attr->{LOCATION_ID}) {
  #   $self->{SEARCH_FIELDS} .= 'pi.location_id, ';
  # }
  #
  # if ($attr->{STREET_ID}) {
  #   $self->{SEARCH_FIELDS} .= 'builds.street_id, ';
  #   $self->{SEARCH_FIELDS} .= 'streets.name, ';
  # }

  #Show last
  if ($attr->{PAYMENTS} || ($attr->{PAYMENT_DAYS} && $attr->{PAYMENT_DAYS} =~ /[0-9\s,<>=]+/)) {
    my @HAVING_RULES = @WHERE_RULES;
    if ($attr->{PAYMENTS}) {
      my $value = @{ $self->search_expr($attr->{PAYMENTS}, 'INT') }[0];
      push @WHERE_RULES,  "DATE_FORMAT(p.date,'%Y-%m-%d')$value";
      push @HAVING_RULES, "MAX(p.date)$value";
      $self->{SEARCH_FIELDS} .= 'MAX(p.date) AS last_payment, ';
      $self->{SEARCH_FIELDS_COUNT}++;
    }
    elsif ($attr->{PAYMENT_DAYS}) {
      my @params = split(/,/, $attr->{PAYMENT_DAYS});

      my @where_ = ();
      my @having_ = ();
      foreach my $payment_days (@params) {
        my $value = "NOW() - INTERVAL $payment_days DAY";
        $value =~ s/([<>=]{1,2})//g;
        $value = $1 . $value;
        push @where_, "DATE_FORMAT(p.date, '%Y-%m-%d')$value";
        push @having_, "MAX(p.date)$value";
      }

      push @WHERE_RULES, '('. join(' AND ', @where_) . ')';
      push @HAVING_RULES, '('. join(' AND ', @having_) . ')';
      $self->{SEARCH_FIELDS} .= 'MAX(p.date) AS last_payment, ';
      $self->{SEARCH_FIELDS_COUNT}++;
    }


    if ($attr->{DEPOSIT} && $attr->{DEPOSIT} ne '_SHOW') {
      $self->{SEARCH_FIELDS} .= 'IF(company.id IS NULL, b.deposit, cb.deposit) AS deposit, ';
      $self->{SEARCH_FIELDS_COUNT}++;
      foreach my $rule (@HAVING_RULES) {
        $rule =~ s/IF\(company\.id IS NULL, b\.deposit, cb\.deposit\)/deposit/;
      }
    }

    my $where_delimeter = ' AND ';
    if ( $attr->{_MULTI_HIT} ) {
      $where_delimeter = ' OR ';
    }

    my $HAVING = ($#HAVING_RULES > -1) ? "HAVING " . join(" $where_delimeter ", @HAVING_RULES) : '';

    $HAVING = _change_having($HAVING);

    $self->query("SELECT u.id AS login,
        $self->{SEARCH_FIELDS}
        u.uid,
        u.company_id,
        u.activate,
        u.expire,
        u.gid,
        u.domain_id,
        u.deleted
      FROM users u
      LEFT JOIN payments p ON (u.uid = p.uid)
      $EXT_TABLES
      GROUP BY u.uid
      $HAVING
      ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
      undef,
      $attr
    );

    return [ ] if ($self->{errno});

    my $list = $self->{list} || [];

    # Total Records
    if ($self->{TOTAL} > 0) {
      if ($attr->{PAYMENT}) {
        $WHERE_RULES[$#WHERE_RULES] = @{ $self->search_expr($attr->{PAYMENTS}, 'INT', 'p.date') };
      }
      elsif ($attr->{PAYMENT_DAYS} && $attr->{PAYMENT_DAYS} =~ /[0-9\s,<>=]+/) {
        my @params = split(/,/, $attr->{PAYMENT_DAYS});

        foreach my $payment_days (@params) {
          my $value = "NOW() - INTERVAL $payment_days DAY";
          $value =~ s/([<>=]{1,2})//g;
          $value = $1 . $value;
          $WHERE_RULES[$#WHERE_RULES] = "p.date$value";
        }
      }

      my $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

      $self->query("SELECT COUNT(DISTINCT u.uid) AS total FROM users u
        $EXT_TABLES
        LEFT JOIN (
          SELECT MAX(date) AS date, uid FROM payments GROUP BY uid
        ) AS p  ON u.uid=p.uid
        $WHERE;",
      undef,
      { INFO => 1 }
      );
    }

    return $list;
  }

  #Show last fees
  if ($attr->{FEES} || ($attr->{FEES_DAYS} && $attr->{FEES_DAYS} =~ /[0-9\s,<>=]+/)) {
    my @HAVING_RULES = @WHERE_RULES;
    if ($attr->{FEES}) {
      my $value = @{ $self->search_expr($attr->{FEES}, 'INT') }[0];
      push @WHERE_RULES,  "DATE_FORMAT(f.date, '%Y-%m-%d')$value";
      push @HAVING_RULES, "MAX(f.date)$value";
      $self->{SEARCH_FIELDS} .= 'MAX(f.date) AS last_fees, ';
      $self->{SEARCH_FIELDS_COUNT}++;
    }
    elsif ($attr->{FEES_DAYS}) {
      my @params = split(/,/, $attr->{FEES_DAYS});

      foreach my $operation_days (@params) {
        my $value = "NOW() - INTERVAL $operation_days DAY";
        $value =~ s/([<>=]{1,2})//g;
        $value = $1 . $value;
        push @WHERE_RULES,  "DATE_FORMAT(p.date, '%Y-%m-%d')$value";
        push @HAVING_RULES, "MAX(f.date)$value";
      }

      $self->{SEARCH_FIELDS} .= 'MAX(f.date) AS last_fees, ';
      $self->{SEARCH_FIELDS_COUNT}++;
    }

    if ($attr->{DEPOSIT} && $attr->{DEPOSIT} ne '_SHOW') {
      $self->{SEARCH_FIELDS} .= 'IF(company.id IS NULL, b.deposit, cb.deposit) AS deposit, ';
      $self->{SEARCH_FIELDS_COUNT}++;
      foreach my $rule (@HAVING_RULES) {
        $rule =~ s/IF\(company\.id IS NULL, b\.deposit, cb\.deposit\)/deposit/;
      }
    }

    my $where_delimeter = ' AND ';
    if ( $attr->{_MULTI_HIT} ) {
      $where_delimeter = ' OR ';
    }

    my $HAVING = ($#HAVING_RULES > -1) ? "HAVING " . join(" $where_delimeter ", @HAVING_RULES) : '';

    $HAVING = _change_having($HAVING);

    $self->query("SELECT u.id AS login,
        $self->{SEARCH_FIELDS}
        u.uid,
        u.company_id,
        u.activate,
        u.expire,
        u.gid,
        u.domain_id,
        u.deleted
      FROM users u
      LEFT JOIN fees f ON (u.uid = f.uid)
      $EXT_TABLES
      GROUP BY u.uid
      $HAVING
      ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
      undef,
      $attr
    );
    return [ ] if ($self->{errno});

    my $list = $self->{list} || [];

    if ($self->{TOTAL} > 0) {
      if ($attr->{FEES}) {
        $WHERE_RULES[$#WHERE_RULES] = @{ $self->search_expr($attr->{PAYMENTS}, 'INT', 'f.date') };
      }
      elsif ($attr->{FEES_DAYS} && $attr->{FEES_DAYS} =~ /[0-9\s,<>=]+/) {
        my @params = split(/,/, $attr->{FEES_DAYS});
        foreach my $operation_days (@params) {
          my $value = "CURDATE() - INTERVAL $operation_days DAY";
          $value =~ s/([<>=]{1,2})//g;
          $value = $1 . $value;
          $WHERE_RULES[$#WHERE_RULES] = "f.date$value";
        }
      }

      if ( $attr->{_MULTI_HIT} ) {
        $where_delimeter = ' OR ';
      }
      else {
        $where_delimeter = ' AND ';
      }

      my $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(" $where_delimeter ", @WHERE_RULES) : '';

      $self->query("SELECT COUNT(DISTINCT u.uid) AS total FROM users u
        LEFT JOIN fees f ON (u.uid = f.uid)
        $EXT_TABLES
        $WHERE;",
      undef,
      { INFO => 1 }
      );
    }

    return $list;
  }

  my $where_delimeter = ' AND ';
  if ( $attr->{_MULTI_HIT} ) {
    $where_delimeter = ' OR ';
  }

  my $WHERE = ($#WHERE_RULES > -1) ? "WHERE (" . join($where_delimeter, @WHERE_RULES) .')' : '';

  if ($admin->{GID}) {
    $WHERE .= (($WHERE) ? 'AND' : 'WHERE ') ." u.gid IN ($admin->{GID})";
  }

  if ($admin->{DOMAIN_ID}) {
    $admin->{DOMAIN_ID} =~ s/;/,/g;
    $WHERE .= (($WHERE) ? 'AND' : 'WHERE ') ." u.domain_id IN ($admin->{DOMAIN_ID})";
  }

  if ( ! $admin->{permissions}->{0}->{8} ) {
    $WHERE .= " AND u.deleted=0";
  }

  if($self->{SORT_BY}) {
    $SORT=$self->{SORT_BY};
  }

  my $GROUP_BY = q{};
  if($attr->{TAGS}) {
    if($attr->{TAG_SEARCH_VAL} == 1){
      my $tags_c = split(',', $attr->{TAGS});
      $GROUP_BY = "GROUP BY u.id HAVING COUNT(tags_users.tag_id ) = '$tags_c'";
    }
    else{
      $GROUP_BY = 'GROUP BY u.id';
    }
  }

  $self->query("SELECT u.id AS login,
      $self->{SEARCH_FIELDS}
      u.uid
    FROM users u
    $EXT_TABLES
    $WHERE
    $GROUP_BY
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  return [ ] if ($self->{errno});
  my $list = $self->{list} || [];

  if ($self->{TOTAL} == $PAGE_ROWS || $PG > 0 || $attr->{FULL_LIST}) {
    $self->query("SELECT COUNT(DISTINCT u.uid) AS total,
      SUM(IF(u.expire<CURDATE() AND u.expire>'0000-00-00', 1, 0)) AS total_expired,
      COUNT( DISTINCT IF(u.disable=1, u.uid, 0)) - 1 AS total_disabled,
      COUNT( DISTINCT IF(u.deleted=1, u.uid, 0)) - 1 AS total_deleted
      FROM users u
      $EXT_TABLES
    $WHERE",
    undef,
    { INFO => 1 }
    );
  }

  return $list;
}

#**********************************************************
=head2 add($attr) - Add user function

  Arguments:
    $attr
      LOGIN
      CREATE_BILL

  Results:

=cut
#**********************************************************
sub add {
  my $self = shift;
  my ($attr) = @_;

  $self->_space_trim($attr);

  delete $self->{PRE_ADD};
  if (! $self->check_params()) {
    return $self;
  }

  if($CONF->{USERNAME_CREATE_FN}) {

  }
  elsif (! $attr->{LOGIN}) {
    #check autofill trigger
    $self->query("SHOW TRIGGERS WHERE `Trigger` = 'login_id';");
    if (! $self->{TOTAL}) {
      $self->{errno}  = 8;
      $self->{errstr} = 'ERROR_ENTER_NAME';
      return $self;
    }

    if ($attr->{REGISTRATION_PREFIX}) {
      $self->query("SET \@login_prefix = '$attr->{REGISTRATION_PREFIX}';");
    }
  }
  elsif (length($attr->{LOGIN}) > $self->{conf}->{MAX_USERNAME_LENGTH}) {
    $self->{errno}  = 9;
    $self->{errstr} = 'ERROR_LONG_USERNAME';
    return $self;
  }
  #ERROR_SHORT_PASSWORD
  elsif ($attr->{LOGIN} !~ /$usernameregexp/) {
    $self->{errno}  = 10;
    $self->{errstr} = 'ERROR_WRONG_NAME';
    return $self;
  }
  elsif ($attr->{EMAIL} && $attr->{EMAIL} ne '') {
    if ($attr->{EMAIL} !~ /(([^<>()[\]\\.,;:\s\@\"]+(\.[^<>()[\]\\.,;:\s\@\"]+)*)|(\".+\"))\@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))/) {
      $self->{errno}  = 11;
      $self->{errstr} = 'ERROR_WRONG_EMAIL';
      return $self;
    }
  }

  my $password = $attr->{PASSWORD} || q{};
  $self->query_add('users', {
    %$attr,
    REGISTRATION => $attr->{REGISTRATION} || 'NOW()',
    DISABLE      => int($attr->{DISABLE} || 0),
    ID           => $attr->{LOGIN},
    PASSWORD     => "ENCODE('$password', '$self->{conf}->{secretkey}')",
    DOMAIN_ID    => $admin->{DOMAIN_ID}
  });

  return $self if ($self->{errno});

  $self->{UID} = $self->{INSERT_ID};

  if($CONF->{USERNAME_CREATE_FN}) {
    my $fn = $CONF->{USERNAME_CREATE_FN};
    my $login = &{ \&$fn  }($self);

    $self->change($self->{UID}, {
      DISABLE => int($attr->{DISABLE} || 0),
      ID      => $login,
      UID     => $self->{UID},
    });
    $self->{LOGIN} = $login;
  }
  else {
    $self->{LOGIN} = $attr->{LOGIN} || $self->{UID};
  }

  $admin->{MODULE} = '';

  $admin->action_add($self->{UID}, '', {
    INFO    => ['LOGIN', 'REDUCTION', 'REDUCTION_DATE', 'CREDIT', 'CREDIT_DATE', 'GID', 'COMPANY_ID' ],
    REQUEST => $attr,
    TYPE    => 7
  });

  if ($attr->{CREATE_BILL}) {
    $self->change($self->{UID}, {
      DISABLE         => int($attr->{DISABLE} || 0),
      UID             => $self->{UID},
      CREATE_BILL     => 1,
      CREATE_EXT_BILL => $attr->{CREATE_EXT_BILL}
    });
  }

  return $self;
}

#**********************************************************
=head2 login_create($self)

=cut
#**********************************************************
sub login_create {
  my($self)=@_;

  my $result = '';

  my $control_num1 = '2 4 10 2 5';
  my @control_arr = split(/ /, $control_num1);
  my @main_arr = split(//, $self->{UID});
  my $sum = 0;
  for(my $i=0; $i<=$#main_arr; $i++) {
    $sum += $main_arr[$i] * $control_arr[$i];
  }
  ($result) = split(//, $sum - int($sum/11)*11);

  return $self->{UID}.$result;
}

#**********************************************************
=head2 change($uid, $attr)

=cut
#**********************************************************
sub change {
  my $self = shift;
  my ($uid, $attr) = @_;

  $self->_space_trim($attr);

  if ($attr->{CREATE_BILL}) {
    require Bills;
    Bills->import();
    my $Bill = Bills->new($self->{db}, $admin, $self->{conf});

    if ($attr->{NEW_CREATE_BILL}) {
      my $bill_info = $Bill->info({ BILL_ID => $attr->{NEW_CREATE_BILL} });

      if (defined $bill_info->{TOTAL} && $bill_info->{TOTAL} < 1) {
        $Bill->create({ ID => $attr->{NEW_CREATE_BILL}, UID => $self->{UID} || $uid });
        if ($Bill->{errno}) {
          $self->{errno}  = $Bill->{errno};
          $self->{errstr} = $Bill->{errstr};
          return $self;
        }
      }
      elsif (!$bill_info->{UID} || $bill_info->{UID} eq ($self->{UID} || $uid)) {
        $Bill->{BILL_ID} = $attr->{NEW_CREATE_BILL};
        $attr->{DEPOSIT} = $bill_info->{DEPOSIT} || 0;
        $Bill->change({ BILL_ID => $Bill->{BILL_ID}, UID => $self->{UID} || $uid });
      }
      else {
        $uid ||= $self->{UID};
        my $user_info = $self->info($bill_info->{UID});
        if (defined $user_info->{TOTAL} && $user_info->{TOTAL} < 1) {
          $Bill->{BILL_ID} = $attr->{NEW_CREATE_BILL};
          $attr->{DEPOSIT} = $bill_info->{DEPOSIT} || 0;
          $Bill->change({ BILL_ID => $Bill->{BILL_ID}, UID => $uid });
          $self->info($uid);
        }
        else {
          $self->info($uid);
          $self->{errno} = 156;
          $self->{errstr} = 'ERR_WRONG_BILL_ID';
          return $self;
        }
      }

    }
    else {
      $Bill->create({ UID => $self->{UID} || $uid });
      if ($Bill->{errno}) {
        $self->{errno}  = $Bill->{errno};
        $self->{errstr} = $Bill->{errstr};
        return $self;
      }
    }

    $attr->{BILL_ID} = $Bill->{BILL_ID};
    $self->{BILL_ID} = $Bill->{BILL_ID};

    if ($attr->{CREATE_EXT_BILL}) {
      $Bill->create({ UID => $self->{UID} });
      if ($Bill->{errno}) {
        $self->{errno}  = $Bill->{errno};
        $self->{errstr} = $Bill->{errstr};
        return $self;
      }
      $attr->{EXT_BILL_ID} = $Bill->{BILL_ID};
    }
  }
  elsif ($attr->{CREATE_EXT_BILL}) {
    require Bills;
    Bills->import();
    my $Bill = Bills->new($self->{db}, $admin, $self->{conf});
    $Bill->create({ UID => $self->{UID} });

    if ($Bill->{errno}) {
      $self->{errno}  = $Bill->{errno};
      $self->{errstr} = $Bill->{errstr};
      return $self;
    }
    $attr->{EXT_BILL_ID} = $Bill->{BILL_ID};
  }

  if (defined($attr->{CREDIT}) && $attr->{CREDIT} == 0) {
    $attr->{CREDIT_DATE} = '0000-00-00';
  }
  if (defined($attr->{REDUCTION}) && $attr->{REDUCTION} == 0) {
    $attr->{REDUCTION_DATE} = '0000-00-00';
  }

  if (!defined($attr->{DISABLE}) && ! $attr->{SKIP_STATUS_CHANGE}) {
    $attr->{DISABLE} = 0;
  }

  #Make extrafields use
  $admin->{MODULE} = '';

  if(defined($attr->{DOMAIN_ID}) && $attr->{DOMAIN_ID} !~ /\d/) {
    delete $attr->{DOMAIN_ID}
  }

  $attr->{UID} ||= $uid;
  $self->changes({
    CHANGE_PARAM    => 'UID',
    TABLE           => 'users',
    DATA            => $attr,
    ACTION_ID       => $attr->{ACTION_ID},
    ACTION_COMMENTS => $attr->{ACTION_COMMENTS}
  });

  return $self;
}

#**********************************************************
=head2 del(attr) - Delete user info from all tables

  Arguments:
    $attr
      COMMENTS
      FULL_DELETE

  Results

=cut
#**********************************************************
sub del {
  my $self = shift;
  my ($attr) = @_;

  $self->{UID} = $self->{UID} || $attr->{UID};

  my $comments = ($attr->{COMMENTS}) ? ' '.$attr->{COMMENTS}: q{};

  $admin->{MODULE} = '';

  if ($attr->{FULL_DELETE}) {
    my @clear_db = (
      'admin_actions',
      'fees',
      'payments',
      'users_nas',
      'users',
      'users_pi',
      'shedule',
      'msgs_messages',
      'msgs_reply',
      'web_users_sessions',
      'users_contacts',
      'users_registration_pin',
      'users_phone_pin'
    );

    $self->{info} = '';

    foreach my $table (@clear_db) {
      if ($table eq 'payments') {
        $self->query("DELETE FROM docs_invoice2payments WHERE payment_id IN (SELECT id FROM payments WHERE uid= ? )", 'do', { Bind => [ $self->{UID} ] });
        $self->query("DELETE FROM docs_receipt_orders WHERE receipt_id IN (SELECT id FROM docs_receipts WHERE uid= ? );", 'do', { Bind => [ $self->{UID} ] });
        $self->query_del('docs_receipts', undef, { uid => $self->{UID} });
      }

      $self->query_del($table, undef, { uid =>  $self->{UID} });
      $self->{info} .= "$table, ";
    }

    require Attach;
    Attach->import();
    my $Attach = Attach->new($self->{db}, $admin, $CONF);
    $Attach->attachment_del({ UID => $self->{UID}, FULL_DELETE => 1 });
    $admin->action_add($self->{UID}, "DELETE $self->{UID}:$self->{LOGIN}$comments", { TYPE => 12 });
  }
  else {
    my $new_login = $self->{LOGIN};

    my @login_suffixes = ();
    my $enought_size_for_suffix = 1;

    push (
      @login_suffixes,
      "-".($CONF->{USER_DELETE_USE_SUFFIX_VALUE} || 'OLD')
    ) if $CONF->{USER_DELETE_USE_SUFFIX};

    push (
      @login_suffixes,
      "-".$attr->{DATE}
    ) if $CONF->{USER_DELETE_USE_SUFFIX_DATE};

    foreach my $suffix (@login_suffixes) {
      if( length($suffix) + length($new_login) <= $CONF->{MAX_USERNAME_LENGTH} ) {
        $new_login .= $suffix;
      }
      else {
        $enought_size_for_suffix = 0;

        last;
      }
    }

    $self->change($self->{UID}, {
      DELETED           => 1,
      ACTION_ID         => 12,
      SKIP_STATUS_CHANGE=> 1,
      ACTION_COMMENTS   => $comments,
      UID               => $self->{UID},
      ID                => $new_login,
    });

    $self->query_del('web_users_sessions', undef, { uid => $self->{UID} });

    $self->{suffix_added} = $enought_size_for_suffix;
  }

  return $self;
}

#**********************************************************
=head2 nas_list() - list_allow nass

=cut
#**********************************************************
sub nas_list {
  my $self = shift;
  my $list;
  $self->query("SELECT nas_id FROM users_nas WHERE uid='$self->{UID}';");

  if ($self->{TOTAL} > 0) {
    $list = $self->{list};
  }
  else {
    $self->query("SELECT nas_id FROM tp_nas WHERE tp_id='$self->{TARIF_PLAN}';");
    $list = $self->{list};
  }

  return $list;
}

#**********************************************************
=head2 nas_add(\@nas)

=cut
#**********************************************************
sub nas_add {
  my $self = shift;
  my ($nas) = @_;

  $self->nas_del();

  my @MULTI_QUERY = ();

  foreach my $id (@$nas) {
    push @MULTI_QUERY, [ $id,
                         $self->{UID}
                        ];
  }

  $self->query("INSERT INTO users_nas (nas_id, uid) VALUES (?, ?);",
      undef,
      { MULTI_QUERY =>  \@MULTI_QUERY });

  $admin->{MODULE}='';
  $admin->action_add($self->{UID}, "NAS " . join(',', @$nas));
  return $self;
}

#**********************************************************
=head2 nas_del()

=cut
#**********************************************************
sub nas_del {
  my $self = shift;

  $self->query_del('users_nas', undef, { uid => $self->{UID} });
  return $self if ($self->{error} > 0);

  $admin->{MODULE}='';
  $admin->action_add($self->{UID}, "DELETE NAS");
  return $self;
}

#**********************************************************
=head2 bruteforce_add($attr)

=cut
#**********************************************************
sub bruteforce_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('users_bruteforce', {
      %$attr,
      IP       => $attr->{REMOTE_ADDR},
      DATETIME => 'NOW()'
    });

  return $self;
}

#**********************************************************
=head2 bruteforce_list($attr)

=cut
#**********************************************************
sub bruteforce_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $GROUP = 'GROUP BY login';
  my $count = 'COUNT(login) AS count';
  my $DISTINCT = 'DISTINCT';

  my $WHERE = $self->search_former($attr, [
      ['LOGIN',             'STR', 'login',         ],
      ['AUTH_STATE',        'INT', 'auth_state',    ],
    ],
    { WHERE       => 1,
    }
    );

  if ($attr->{LOGIN}) {
    $count = 'auth_state';
    $GROUP = '';
  }

  my $list;

  if (!$attr->{CHECK}) {
    $self->query("SELECT login, password, datetime, $count, INET_NTOA(ip) AS ip FROM users_bruteforce
      $WHERE
      $GROUP
      ORDER BY $SORT $DESC
      LIMIT $PG, $PAGE_ROWS;",
      undef,
      $attr
    );
    $list = $self->{list};
  }
  else {
    $DISTINCT='';
  }

  $self->query("SELECT COUNT($DISTINCT login) AS total FROM users_bruteforce $WHERE;", undef, { INFO => 1 });

  return $list;
}

#**********************************************************
=head2 bruteforce_del($attr) - clear bruterforce listing

  Arguments:
    $attr
      DATE
      PERIOD - period in days


=cut
#**********************************************************
sub bruteforce_del {
  my $self = shift;
  my ($attr) = @_;

  my $WHERE = '';

  if ($attr->{DATE}) {
    my $period = 1;
    if($attr->{PERIOD}) {
      $period = int($attr->{PERIOD});
    }

    $WHERE = "datetime <= '$attr->{DATE} 23:59:59' - INTERVAL $period DAY";
  }
  elsif ($attr->{DEL_ALL}) {

  }
  elsif($attr->{LOGIN}){
    $WHERE = "login='$attr->{LOGIN}'";
  }

  $self->query("DELETE FROM users_bruteforce " . ($WHERE ? "WHERE $WHERE" : ''), 'do');

  return $self;
}

#**********************************************************
=head2 web_session_update($attr)

  Attributes:
    $attr
      SID
      REMOTE_ADDR

  Return:
    $self

=cut
#**********************************************************
sub web_session_update {
  my $self = shift;
  my ($attr) = @_;

  my $remote_addr = q{};
  if ($CONF->{USERPORTAL_MULTI_SESSIONS}) {
    $remote_addr = ", remote_addr=INET_ATON('$attr->{REMOTE_ADDR}')"
  }

  $self->query("UPDATE web_users_sessions SET
    datetime = UNIX_TIMESTAMP() $remote_addr
    WHERE sid = ?;", 'do', { Bind => [ $attr->{SID} ] });

  return $self;
}

#**********************************************************
=head2 web_session_add($attr)  - Add web sessions user info

  Arguments:
    $attr
      UID
      LOGIN
      REMOTE_ADDR
      SID
      EXT_INFO

  Returns:
    Object

=cut
#**********************************************************
sub web_session_add {
  my $self = shift;
  my ($attr) = @_;

  if ($CONF->{USERPORTAL_MULTI_SESSIONS}) {
    # $self->query('DELETE FROM web_users_sessions
    #   WHERE uid=? AND remote_addr=INET_ATON( ? );',
    #   'do',
    #   { Bind => [
    #     $attr->{UID},
    #     $attr->{REMOTE_ADDR}
    #   ] });
    $self->query('DELETE FROM web_users_sessions
       WHERE UNIX_TIMESTAMP() - datetime > '. ( $CONF->{web_session_timeout} || 86000 ) .';',
       'do');
  }
  else {
    $self->query("DELETE FROM web_users_sessions WHERE uid=?;", 'do', { Bind => [ $attr->{UID} ] });
  }

  $self->query("INSERT INTO web_users_sessions
      (uid, datetime, login, remote_addr, sid, ext_info, coordx, coordy) VALUES
      (?, UNIX_TIMESTAMP(), ?, INET_ATON( ? ), ?, ?, ?, ?);",
    'do',
    { Bind => [
      $attr->{UID},
      $attr->{LOGIN},
      $attr->{REMOTE_ADDR},
      $attr->{SID},
      $attr->{EXT_INFO} || '',
      $attr->{COORDX} || 0,
      $attr->{COORDY} || 0
    ] }
  );

  return $self;
}

#**********************************************************
=head2 web_session_info($attr) - User information

  Argumnets:
    $attr
      SID
      UID

  Returns:
    Object

=cut
#**********************************************************
sub web_session_info {
  my $self = shift;
  my ($attr) = @_;

  my $WHERE;
  my @request_arr = (  );

  if ($attr->{SID}) {
    $WHERE = "WHERE sid= ? ";
    @request_arr = ($attr->{SID});
  }
  elsif ($attr->{UID}) {
    $WHERE = "WHERE uid= ? ";
    @request_arr = ($attr->{UID});
  }
  else {
    $self->{errno}  = 2;
    $self->{errstr} = 'ERROR_NOT_EXIST';
    return $self;
  }

  $self->query("SELECT uid,
    datetime,
    login,
    INET_NTOA(remote_addr) AS remote_addr,
    UNIX_TIMESTAMP() - datetime AS session_time,
    sid
      FROM web_users_sessions
      $WHERE;",
    undef,
    { INFO => 1,
      Bind => [ @request_arr ] }
  );

  return $self;
}

#**********************************************************
=head2 web_sessions_list() - List of users web sessions

=cut
#**********************************************************
sub web_sessions_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $GROUP = 'GROUP BY login';
  my $count = 'count(login) AS count';
  my @WHERE_RULES = ();

  if ($attr->{LOGIN} && $attr->{LOGIN} ne '_SHOW') {
    $count = 'auth_state';
    $GROUP = '';
  }

  if ($attr->{ACTIVE}) {
    push @WHERE_RULES, "UNIX_TIMESTAMP() - datetime < $attr->{ACTIVE}";
  }

  my $WHERE =  $self->search_former($attr, [
      ['LOGIN',        'INT', 'login',       ],
      ['EXT_INFO',     'INT', 'ext_info',  1 ],
      ['COORDX',       'INT', 'coordx',    1 ],
      ['COORDY',       'INT', 'coordy',    1 ],
      ['UID',          'INT', 'uid',         ],
    ],
    { WHERE             => 1,
      WHERE_RULES       => \@WHERE_RULES,
    }
  );

  my $list;

  if (!$attr->{CHECK}) {
    $self->query("SELECT FROM_UNIXTIME(datetime) AS datetime, login, INET_NTOA(remote_addr) AS ip, sid, $self->{SEARCH_FIELDS} uid
    FROM web_users_sessions
      $WHERE
      $GROUP
      ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
      undef,
      $attr
    );
    $list = $self->{list};
  }

  $self->query("SELECT count(DISTINCT login) AS total FROM web_users_sessions $WHERE;", undef, {INFO => 1 });

  return $list;
}


#**********************************************************
=head2 web_session_del($attr) - Del user web sessions

  Arguments:
    $attr
      SID
      ALL

  Returns:
    Object

=cut
#**********************************************************
sub web_session_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('web_users_sessions', undef,  { sid => $attr->{SID}}, { CLEAR_TABLE => $attr->{ALL}  });

  return $self;
}

#**********************************************************
=head2 web_session_find($sid) - Returns session_info by sid

  Arguments:
    $sid -

  Returns:
    hash_ref - info

=cut
#**********************************************************
sub web_session_find {
  my ($self, $sid) = @_;

  return 0 unless ( $sid );

  $self->query("SELECT uid FROM web_users_sessions WHERE sid= ?", undef, {
      Bind      => [ $sid ]
    });

  return ($self->{list} && $self->{list}->[0]) ? $self->{list}->[0][0] : 0;
}


#**********************************************************
=head2 info_field_attach_add($attr) - Info fields attach add

  Arguments:
    $attr
      COMPANY_PREFIX
  Returns:
    Object

=cut
#**********************************************************
sub info_field_attach_add {
  my $self = shift;
  my ($attr) = @_;
	my $insert_id = 0;

  my $prefix = ($attr->{COMPANY_PREFIX}) ? 'ifc' : 'ifu';

  require Attach;
  Attach->import();
  my $Conf   = Conf->new($self->{db}, $admin, $self->{conf});
  my $Attach = Attach->new($self->{db}, $admin, $CONF);
  my $list   = $Conf->config_list({ PARAM => $prefix .'*' });

  if ($Conf->{TOTAL} && $Conf->{TOTAL} > 0) {
    foreach my $line (@$list) {
      if ($line->[0] =~ /$prefix(\S+)/) {
        my $field_name = $1;
        my (undef, $type, undef) = split(/:/, $line->[1]);
        if ($type == 13) {
          #attach
          if (ref $attr->{uc($field_name)} eq 'HASH' && $attr->{uc($field_name)}{filename}) {
            if($CONF->{ATTACH2FILE}) {
              if($self->{UID}) {
                $self->pi({ UID => $self->{UID} });
                if($self->{uc($field_name)}) {
                  $Attach->attachment_del({
                    ID         => $self->{uc($field_name)},
                    TABLE      => $field_name.'_file',
                    UID        => $self->{UID},
                    SKIP_ERROR => 1
                  })
                }
              }
            }

            $Attach->attachment_add(
              {
                TABLE        => $field_name . '_file',
                CONTENT      => $attr->{uc($field_name)}{Contents},
                FILESIZE     => $attr->{uc($field_name)}{Size},
                FILENAME     => $attr->{uc($field_name)}{filename},
                CONTENT_TYPE => $attr->{uc($field_name)}{'Content-Type'},
                UID          => $attr->{UID},
                FIELD_NAME   => $field_name
              }
            );

            if($Attach->{errno}) {
              $self->{errno} = $Attach->{errno};
              $self->{errstr} = $Attach->{errstr};
            }
            else {
              $attr->{uc($field_name)} = $Attach->{INSERT_ID};
              $insert_id = $Attach->{INSERT_ID};
            }
          }
          else {
            delete $attr->{uc($field_name)};
          }
        }
      }
    }
  }

  return $attr;
}


#**********************************************************
=head2 info_field_add($attr) - Infofields add
  Arguments:
    $attr
      FIELD_ID
      FIELD_TYPE
      COMPANY_ADD
      CAN_BE_CHANGED_BY_USER
      USERS_PORTAL

  Returns:
    $self
=cut
#**********************************************************
sub info_field_add {
  my $self = shift;
  my ($attr) = @_;

  my @column_types = (
    " varchar(120) not null default ''",
    " int(11) NOT NULL default '0'",
    " smallint unsigned NOT NULL default '0' ",
    " text not null ",
    " tinyint(11) NOT NULL default '0' ",
    " content longblob NOT NULL",
    " varchar(100) not null default ''",
    " int(11) unsigned NOT NULL default '0'",
    " varchar(12) not null default ''",
    " varchar(120) not null default ''",
    " varchar(20) not null default ''",
    " varchar(50) not null default ''",
    " varchar(50) not null default ''",
    " int unsigned NOT NULL default '0' ",
    " INT(11) UNSIGNED NOT NULL DEFAULT '0' REFERENCES users(uid) ",
    " varchar(120) not null default ''",
    " varchar(120) not null default ''",
    " varchar(120) not null default ''",
    " varchar(120) not null default ''",
    " tinyint(2) not null default '0' ",
    " DATE not null default '0000-00-00' ",
  );

  $attr->{FIELD_TYPE} = 0 if (!$attr->{FIELD_TYPE});

  my $column_type  = $column_types[ $attr->{FIELD_TYPE} ] || " varchar(120) not null default ''";
  my $field_prefix = 'ifu';

  #Add field to table
  if ($attr->{COMPANY_ADD}) {
    $field_prefix = 'ifc';
    $self->query('ALTER TABLE companies ADD COLUMN ' .'_'. $attr->{FIELD_ID} . " $column_type;", 'do');
  }
  else {
    $self->query('ALTER TABLE users_pi ADD COLUMN ' .'_' . $attr->{FIELD_ID} . " $column_type;", 'do');
  }

  if (!$self->{errno} || ($self->{errno} && $self->{errno} == 3)) {
    if ($attr->{FIELD_TYPE} == 2) {
      $self->query("CREATE TABLE _$attr->{FIELD_ID}_list (
        id smallint unsigned NOT NULL primary key auto_increment,
        name varchar(120) not null default 0
        )DEFAULT CHARSET=$self->{conf}->{dbcharset};", 'do'
      );
    }
    elsif ($attr->{FIELD_TYPE} == 13) {
      $self->query("CREATE TABLE `_$attr->{FIELD_ID}_file` (`id` int(11) unsigned NOT NULL PRIMARY KEY auto_increment,
          `filename` varchar(250) not null default '',
          `content_size` varchar(30) not null  default '',
          `content_type` varchar(250) not null default '',
          `content` longblob NOT NULL,
          `create_time` datetime NOT NULL default '0000-00-00 00:00:00') DEFAULT CHARSET=$self->{conf}->{dbcharset};", 'do'
      );
    }

    my $Conf = Conf->new($self->{db}, $admin, $self->{conf});

    $Conf->config_add(
      {
        PARAM     => $field_prefix . "_$attr->{FIELD_ID}",
        VALUE     => "$attr->{POSITION}:$attr->{FIELD_TYPE}:$attr->{NAME}:$attr->{USERS_PORTAL}:$attr->{CAN_BE_CHANGED_BY_USER}",
        DOMAIN_ID => $admin->{DOMAIN_ID} || 0
      }
    );
  }


  $admin->system_action_add("IF:_$attr->{FIELD_ID}:$attr->{NAME}", { TYPE => 1 });

  return $self;
}

#**********************************************************
=head2 info_field_del($attr)

  Arguments:
    $attr
      FIELD_ID
      SECTION
  Returns:
    Object

=cut
#**********************************************************
sub info_field_del {
  my $self = shift;
  my ($attr) = @_;

  my $sql = '';
  if ($attr->{SECTION} eq 'ifc') {
    $sql = "ALTER TABLE companies DROP COLUMN `$attr->{FIELD_ID}`;";
  }
  else {
    $sql = "ALTER TABLE users_pi DROP COLUMN `$attr->{FIELD_ID}`;";
  }

  $self->query($sql, 'do');

  if (!$self->{errno} || $self->{errno} == 3) {
    my $Conf = Conf->new($self->{db}, $admin, $self->{conf});

    $Conf->config_del("$attr->{SECTION}$attr->{FIELD_ID}");
    $admin->system_action_add("IF:_$attr->{FIELD_ID}", { TYPE => 10 });
  }

  return $self;
}

#**********************************************************
=head2 info_list_add($attr)

=cut
#**********************************************************
sub info_list_add {
  my $self = shift;
  my ($attr) = @_;

  if(! $attr->{LIST_TABLE}) {
    $self->{errno}=100;
    $self->{errstr}='NO list table';
    return $self;
  }

  $self->query_add($attr->{LIST_TABLE}, $attr);

  return $self;
}

#**********************************************************
=head2 info_list_del($attr) - Info list del value

=cut
#**********************************************************
sub info_list_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del($attr->{LIST_TABLE}, $attr);

  return $self;
}

#**********************************************************
=head2 info_lists_list($attr)

=cut
#**********************************************************
sub info_lists_list {
  my $self = shift;
  my ($attr) = @_;

  $self->query("SELECT id, name FROM `$attr->{LIST_TABLE}` ORDER BY name;",
  undef,
  $attr);

  return $self->{list} || [];
}

#**********************************************************
=head2 info_list_info($id, $attr)

=cut
#**********************************************************
sub info_list_info {
  my $self = shift;
  my ($id, $attr) = @_;

  $self->query("SELECT id, name FROM `$attr->{LIST_TABLE}` WHERE id= ? ;",
    undef,
    { INFO => 1,
      Bind => [ $id ]
    }
  );

  return $self;
}

#**********************************************************
=head2 info_list_change($id, $attr)

=cut
#**********************************************************
sub info_list_change {
  my $self = shift;
  my (undef, $attr) = @_;

  $self->changes(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => $attr->{LIST_TABLE},
      DATA         => $attr
    }
  );

  return $self->{result};
}

#**********************************************************
=head2 report_users_summary($attr)

=cut
#**********************************************************
sub report_users_summary {
  my $self = shift;
  #my ($attr) = @_;

  my @WHERE_RULES = ();
  if ($admin->{GID}) {
    $admin->{GID}=~s/,/;/g;
    push @WHERE_RULES,  @{ $self->search_expr($admin->{GID}, 'INT', 'u.gid') };
  }

  if ($admin->{DOMAIN_ID}) {
    push @WHERE_RULES,  @{ $self->search_expr($admin->{DOMAIN_ID}, 'INT', 'u.domain_id') };
  }

  my $WHERE = ($#WHERE_RULES > -1) ? "AND " . join(' AND ', @WHERE_RULES) : '';

  $self->query("SELECT COUNT(*) AS total_users,
      SUM(IF(u.disable>0, 1, 0)) AS disabled_users,
      SUM(IF(u.credit>0, 1, 0)) AS creditors_count,
      SUM(IF(u.credit>0, u.credit, 0)) AS creditors_sum,
      SUM(IF(IF(company.id IS NULL, b.deposit, cb.deposit)<0, 1, 0)) AS debetors_count,
      SUM(IF(IF(company.id IS NULL, b.deposit, cb.deposit)<0, b.deposit, 0)) AS debetors_sum
    FROM users u
      LEFT JOIN bills b ON (u.bill_id = b.id)
      LEFT JOIN companies company ON  (u.company_id=company.id)
      LEFT JOIN bills cb ON (company.bill_id=cb.id)
    WHERE u.deleted=0 $WHERE
    ;",
    undef,
    { INFO => 1 }
  );

  return $self;
}

#**********************************************************
=head2 check_params($attr)

=cut
#**********************************************************
sub check_params {
  my $self = shift;
  $self->query("SELECT count(*) AS count FROM users;");

   my $period_ = 0b10011000100101101000000;

  my $content = '';
  my $string = pack("H*", '6c6963656e73652e6b6579');

  if (-f '/usr/'. 'axbills'. '/libexec/'. $string && open(my $fh, '<', '/usr'. '/axbills'. '/libexec/'. $string)) {
    while(<$fh>) {
      $content .= $_;
    }

    if ($content) {
      $period_ = substr(pack("H*", $content) ^ '1' x 30, 20, 10);
    }
    close($fh);
  }

  if($self->{PRE_ADD}) {
    if($period_-5 < $self->{list}->[0]->[0]) {
      $self->{errno} = 0b1010111011;
      $self->{errstr} = $self->{list}->[0]->[0];
      return 0;
    }
  }
  elsif ($period_ < $self->{list}->[0]->[0]) {
    $self->{errno}  = 0b1010111011;
    $self->{errstr} = $self->{list}->[0]->[0];
    return 0
  }

  return 1;
}

#**********************************************************
=head2 contacts_migrate() - migrates contacts from old to new model

  Returns:
    boolean - success flag

=cut
#**********************************************************
sub contacts_migrate {
  my ($self, $attr) = @_;

  if ($attr->{IGNORE_DUPLICATE}){
    $self->query("ALTER TABLE users_contacts DROP KEY `_type_value`;");
    return 0 if ($self->{errno});
  };

  my %old_type_to_new = (
    EMAIL => 9,
    PHONE => 2
  );

  $self->query("SELECT u.uid, up.phone, up.email
    FROM users u
    LEFT JOIN users_pi up ON (u.uid=up.uid)
    WHERE up.phone <> '' OR up.email <> ''
    ORDER BY u.uid",
    undef,
    { COLS_NAME => 1 }
  );

  return 0 if ($self->{errno});
  return 1 if (!$self->{list} || scalar @{$self->{list}} <= 0);

  # Accumulating requests
  my @contacts_to_add = ();

  foreach my $user_pi ( @{$self->{list}} ) {
    if ( $user_pi->{phone} ) {
      my @phones = split(',\s?', $user_pi->{phone});
      map {
        push @contacts_to_add, [ $user_pi->{uid}, $old_type_to_new{PHONE}, $_ ];
      } @phones;
    }
    if ( $user_pi->{email} ) {
      my @emails = split(',\s?', $user_pi->{email});
      map {
        push @contacts_to_add, [ $user_pi->{uid}, $old_type_to_new{EMAIL}, $_ ];
      } @emails;
    }
  }

  # Start a transaction
  my DBI $db_ = $self->{db}->{db};
  $db_->{AutoCommit} = 0;

  # Add all contacts
  $self->query( "INSERT INTO users_contacts (uid, type_id, value) VALUES (?, ?, ?);",
    undef,
    { MULTI_QUERY => \@contacts_to_add }
  );

  if ( $self->{errno} ) {
    # If error was occured, part of contacts could be inserted,
    # so next time we will get DUPLICATE, need to remove all inserted contacts
    $db_->rollback();
    return 0;
  }

  if ( $self->{errno} ) {
    $db_->rollback();
    return 0;
  }

  $db_->commit();
  $db_->{AutoCommit} = 1;


  # If insert was successful, can remove old info
  $self->query("UPDATE users_pi SET phone='', email='';", 'do');

  return 1;
}

#**********************************************************
=head2 contracts_list()

=cut
#**********************************************************
sub contracts_list {
  my $self = shift;
  my ($attr) = @_;

  my $WHERE = $self->search_former($attr, [
      ['ID',         'INT', 'uc.id'         ],
      ['UID',        'INT', 'uc.uid'        ],
      ['COMPANY_ID', 'INT', 'uc.company_id' ],
    ],
    {
      WHERE => 1
    }
  );

  $self->query("SELECT
    uc.id,
    uc.parrent_id,
    uc.uid,
    uc.company_id,
    uc.number,
    uc.name,
    uc.date,
    uc.end_date,
    uc.type,
    uc.reg_date,
    uc.aid,
    uc.signature,
    ct.name AS type_name,
    ct.template
    FROM users_contracts uc
    LEFT JOIN contracts_type ct ON (uc.type=ct.id)
    $WHERE;",
    undef,
    { COLS_NAME => 1, %$attr }
  );

  my $list = $self->{list};

  $self->query("SELECT COUNT(*) AS total FROM users_contracts uc
    $WHERE;",
    undef,
    { INFO => 1 }
  );

  return $list;
}

#**********************************************************
=head2 contracts_add()

=cut
#**********************************************************
sub contracts_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('users_contracts', $attr);

  return $self;
}

#**********************************************************
=head2 contracts_change()

=cut
#**********************************************************
sub contracts_change {
  my $self = shift;
  my ($id, $attr) = @_;

  $attr->{ID} = $id;

  $self->changes(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'users_contracts',
      DATA         => $attr
    }
  );

  return $self;
}

#**********************************************************
=head2 contracts_del()

=cut
#**********************************************************
sub contracts_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('users_contracts', $attr);

  return $self;
}

#**********************************************************
=head2 contracts_type_list()

=cut
#**********************************************************
sub contracts_type_list {
  my $self = shift;
  my ($attr) = @_;

  my $WHERE = $self->search_former($attr, [
      ['ID',         'INT', 'id'         ],
      ['NAME',       'STR', 'name'       ],
      ['TEMPLATE',   'STR', 'template'   ],
    ],
    {
      WHERE => 1
    }
  );

  $self->query("SELECT
    id,
    name,
    template
    FROM contracts_type
    $WHERE;",
    undef,
    { COLS_NAME => 1, %$attr }
  );

  my $list = $self->{list};

  $self->query("SELECT COUNT(*) AS total FROM contracts_type
    $WHERE;",
    undef,
    { INFO => 1 }
  );

  return $list;
}

#**********************************************************
=head2 contracts_type_add()

=cut
#**********************************************************
sub contracts_type_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('contracts_type', $attr);

  return $self;
}

#**********************************************************
=head2 contracts_type_change()

=cut
#**********************************************************
sub contracts_type_change {
  my $self = shift;
  my ($id, $attr) = @_;

  $attr->{ID} = $id;

  $self->changes(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'contracts_type',
      DATA         => $attr
    }
  );

  return $self;
}

#**********************************************************
=head2 contracts_type_del()

=cut
#**********************************************************
sub contracts_type_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('contracts_type', $attr);

  return $self;
}

#**********************************************************
=head2 min_tarif_val() - Get minimum value for internet tarif

  Arguments:

  Returns:
    $list
=cut
#**********************************************************
sub min_tarif_val {
  my $self = shift;
  my ($attr) = @_;
  my $value = '';

    $self->query("SELECT MIN(tr.month_fee) as min_t
      FROM tarif_plans tr
      WHERE (tr.module='Internet');",
      undef,
      $attr
    );
    $value = $self->{list}[0] || 0;

  return $value;
}

#**********************************************************
=head2 all_data_for_report($attr) - get all data per month

  Arguments:
    $attr -

  Returns:

=cut
#**********************************************************
sub all_data_for_report {
  my $self = shift;
  my ($attr) = @_;

  $self->query("SELECT
    months.month  as month,
    IFNULL((SELECT COUNT(u.uid)
      FROM users u
      WHERE DATE_FORMAT(u.registration, '%Y-%m') <= CONCAT(?,'-', months.month)),0) AS count_all_users,
    IFNULL((SELECT COUNT(u.uid)
      FROM users u
      WHERE DATE_FORMAT(u.registration, '%Y-%m') = CONCAT(?,'-', months.month)),0)  AS count_new_users,
    IFNULL((SELECT SUM(p.sum)
      FROM payments p
      WHERE DATE_FORMAT(p.date, '%Y-%m') = CONCAT(?, '-', months.month)
      AND NOT p.method = '4'), 0)                AS payments_for_every_month,
    IFNULL((SELECT COUNT(distinct internet.uid)
      FROM internet_main internet
      WHERE DATE_FORMAT(internet.registration, '%Y-%m') <= CONCAT(?, '-', months.month)), 0) AS count_activated_users,
    IFNULL((SELECT SUM(f.sum)
      FROM  fees f
      WHERE (DATE_FORMAT(f.date, '%Y-%m')=CONCAT(?, '-', months.month))),0) as fees_sum,
    IFNULL(( SELECT COUNT(internet2.id)
      FROM internet_main internet2
      JOIN tarif_plans tr ON internet2.tp_id=tr.tp_id
      WHERE (DATE_FORMAT(internet2.registration, '%Y-%m')<=CONCAT(?, '-', months.month) AND internet2.disable=0)),0) AS total_active_services,
    IFNULL(( SELECT SUM(tr.month_fee)
      FROM internet_main internet2
      JOIN tarif_plans tr ON internet2.tp_id=tr.tp_id
      WHERE (DATE_FORMAT(internet2.registration, '%Y-%m')<=CONCAT(?, '-', months.month) AND internet2.disable=0)),0) AS month_fee_sum
    FROM (SELECT '01' AS month
      UNION SELECT '02' AS month
      UNION SELECT '03' AS month
      UNION SELECT '04' AS month
      UNION SELECT '05' AS month
      UNION SELECT '06' AS month
      UNION SELECT '07' AS month
      UNION SELECT '08' AS month
      UNION SELECT '09' AS month
      UNION SELECT '10' AS month
      UNION SELECT '11' AS month
      UNION SELECT '12' AS month) as months
    GROUP BY month;",
    undef,
    { %{$attr}, Bind => [ $attr->{YEAR}, $attr->{YEAR}, $attr->{YEAR}, $attr->{YEAR}, $attr->{YEAR}, $attr->{YEAR}, $attr->{YEAR} ] }
  );

  return $self->{list} || {};
}

#**********************************************************
=head2 all_new_report($attr) - get all data per month

  Arguments:
    $attr -

  Returns:

=cut
#**********************************************************
sub all_new_report {
  my $self = shift;
  my ($attr) = @_;

  $self->query("SELECT
    months.month  as month,
    IFNULL((SELECT COUNT(u.uid)
      FROM users u
      WHERE DATE_FORMAT(u.registration, '%Y-%m') <= CONCAT(?,'-', months.month)),0) AS count_all_users,
    IFNULL((SELECT COUNT(u.uid)
      FROM users u
      WHERE DATE_FORMAT(u.registration, '%Y-%m') = CONCAT(?,'-', months.month)),0)  AS count_new_users
    FROM (SELECT '01' AS month
      UNION SELECT '02' AS month
      UNION SELECT '03' AS month
      UNION SELECT '04' AS month
      UNION SELECT '05' AS month
      UNION SELECT '06' AS month
      UNION SELECT '07' AS month
      UNION SELECT '08' AS month
      UNION SELECT '09' AS month
      UNION SELECT '10' AS month
      UNION SELECT '11' AS month
      UNION SELECT '12' AS month) as months
    GROUP BY month;",
    undef,
    { %{$attr}, Bind => [ $attr->{YEAR}, $attr->{YEAR} ] }
  );

  return $self->{list} || {};
}

#**********************************************************
=head2 contacts_validation($attr)

  Status:
    1 - valid contacts
    2 - invalid contacts
  Arguments:
    PHONE
    CELL_PHONE
    EMAIL

  Returns:

=cut
#**********************************************************
sub user_contacts_validation {
  my $self = shift;
  my ($attr) = @_;

  if ($attr->{PHONE} && $self->{conf}{PHONE_FORMAT}) {
    foreach my $item (split(/,\s?/, $attr->{PHONE})) {
      if ($item !~ /$self->{conf}{PHONE_FORMAT}/) {
        $self->{errno} = 21;
        $self->{errstr} = "WRONG_PHONE:" . " " . $item . '. ';
        return 0;
      }
    }
  }

  if ($attr->{CELL_PHONE} && $self->{conf}{CELL_PHONE_FORMAT}) {
    foreach my $item (split(/,\s?/, $attr->{CELL_PHONE})) {
      if ($item !~ /$self->{conf}{CELL_PHONE_FORMAT}/) {
        $self->{errno} = 21;
        $self->{errstr} = "WRONG_CELL_PHONE:" . " " . $item . '. ';
        return 0;
      }
    }
  }

  if ($attr->{EMAIL}) {
    if ($attr->{EMAIL} !~ /$self->{conf}{EMAIL_FORMAT}/) {
      $self->{errno} = 21;
      $self->{errstr} = "WRONG_EMAIL:" . " " . $attr->{EMAIL} . '. ';
      return 0;
    }
  }

  return $self;
}

#**********************************************************
=head2 phone_pin_info($uid)

=cut
#**********************************************************
sub phone_pin_info {
  my $self = shift;
  my ($uid) = @_;

  $self->query("SELECT * FROM users_phone_pin WHERE uid = ? AND time_code > NOW();",
    undef, { INFO => 1, Bind => [ $uid ] });

  return $self;
}

#**********************************************************
=head2 phone_pin_update_attempts($uid)

=cut
#**********************************************************
sub phone_pin_update_attempts {
  my $self = shift;
  my ($uid) = @_;

  $self->query("UPDATE users_phone_pin SET attempts = attempts + 1 WHERE uid = ?", undef, { Bind => [ $uid ] });

  return $self;
}

#**********************************************************
=head2 phone_pin_add($attr)

=cut
#**********************************************************
sub phone_pin_add {
  my $self = shift;
  my ($attr) = @_;

  my $interval = $CONF->{AUTH_BY_PHONE_PIN_INTERVAL} || 5;

  $self->query("REPLACE INTO users_phone_pin (uid, pin_code, time_code)
    VALUES(?, ?, NOW() + INTERVAL $interval MINUTE);", undef, { Bind => [ $attr->{UID}, $attr->{PIN_CODE} ] });

  return $self;
}

#**********************************************************
=head2 phone_pin_del($attr)

=cut
#**********************************************************
sub phone_pin_del {
  my $self = shift;
  my $uid = shift;

  $self->query("DELETE FROM users_phone_pin WHERE uid = ?;", undef, { Bind => [ $uid ] });

  return $self;
}


#**********************************************************
=head2 _change_having($HAVING)

  Arguments:
    HAVING - No valid having params query

  Returns:
    HAVING - Valid having

=cut
#**********************************************************
sub _change_having {
  my ($HAVING) = @_;

  if ($HAVING && $HAVING =~ /CONCAT_WS\(\" \", pi.fio, pi.fio2, pi.fio3\)/) {
    $HAVING =~ s/CONCAT_WS\(\" \", pi.fio, pi.fio2, pi.fio3\)/fio/g;
  }

  if ($HAVING && $HAVING =~ /IF\(u.company_id=0, CONCAT\(pi.contract_id\), CONCAT\(company.contract_id\)\)/) {
    $HAVING =~ s/IF\(u.company_id=0, CONCAT\(pi.contract_id\), CONCAT\(company.contract_id\)\)/contract_id/g;
  }

  if ($HAVING && $HAVING =~ /IF\(u.credit > 0, u.credit, IF\(company.id IS NULL, 0, company.credit\)\)/) {
    $HAVING =~ s/IF\(u.credit > 0, u.credit, IF\(company.id IS NULL, 0, company.credit\)\)/credit/g;
  }

  if ($HAVING && $HAVING =~ /IF\(company.id IS NULL,b.id,cb.id\)/) {
    $HAVING =~ s/IF\(company.id IS NULL,b.id,cb.id\)/bill_id/g;
  }

  if ($HAVING && $HAVING =~ /CONCAT\(streets.name, ' ', builds.number, ',', pi.address_flat\)/) {
    $HAVING =~ s/CONCAT\(streets.name, ' ', builds.number, ',', pi.address_flat\)/address_full/g;
  }

  if ($HAVING && $HAVING =~ /pi.location_id/) {
    $HAVING =~ s/pi.location_id/builds.id/g;
  }

  return $HAVING;
}


#**********************************************************
=head2 switch_list ($attr) - returns list of switches and users

  Arguments:
    $attr - hash_ref

  Returns:
  switch_id
  switch_name
  switch_users
  user_off
  user_on
  users_request

=cut
#**********************************************************
sub switch_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 1000;

  my $search_columns = [
    [ 'EQUIPMENT_ID',               'INT', 'nas.id',                1 ],
    [ 'EQUIPMENT_NAME',             'STR', 'nas.name',              1 ],
    [ 'USER_ID',                    'STR', 'users.uid',             1 ],
    [ 'USER_ACTIVE',                'STR', 'internet_main.disable', 1 ],
    [ 'MESSAGES',                   'STR', 'msgs_messages.uid',     1 ],
  ];

  my $WHERE = $self->search_former($attr, $search_columns, { WHERE => 1 });
  $self->query("
    SELECT nas.id AS switch_id,
       nas.name AS switch_name,
       (SELECT COUNT(uid)
        FROM internet_main
        WHERE internet_main.nas_id = nas.id
       ) AS switch_users,
       (SELECT COUNT(disable)
        FROM internet_main
        WHERE disable = 1
        AND internet_main.nas_id = nas.id
        ) AS user_off,
       (SELECT COUNT(disable)
        FROM internet_main
        WHERE disable = 0
        AND internet_main.nas_id = nas.id
       ) AS user_on,
       SUM((SELECT COUNT(id)
        FROM msgs_messages
        WHERE msgs_messages.date >= (NOW() - INTERVAL 30 DAY)
          AND msgs_messages.uid = users.uid
          AND users.uid = internet_main.uid
          AND internet_main.nas_id = nas.id
       )) AS users_request

    FROM internet_main
    LEFT JOIN nas           ON internet_main.nas_id = nas.id
    LEFT JOIN users         ON internet_main.uid = users.uid
    GROUP BY switch_id
    $WHERE
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;",
    undef, $attr
  );

  my $list = $self->{list};

  return $list;
}

#**********************************************************
=head2 user_status_add($attr) - Create user status

=cut
#**********************************************************
sub user_status_add{
  my $self = shift;
  my ($attr) = @_;

  $self->query_add( 'users_status', $attr );

  return $self;
}

#**********************************************************
=head2 user_status_change($attr) -  Change user status

=cut
#**********************************************************
sub user_status_change{
  my $self = shift;
  my ($attr) = @_;

  $self->changes(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'users_status',
      DATA         => $attr
    }
  );

  return $self;
}

#**********************************************************
=head2 user_status_list($attr) - list user status

=cut
#**********************************************************
sub user_status_list{
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = (defined( $attr->{DESC} )) ? $attr->{DESC} : 'DESC';

  my $WHERE = $self->search_former( $attr, [
    [ 'ID',            'INT', 'id',        1],
    [ 'NAME',          'STR', 'name',      1],
    [ 'DESCR',         'STR', 'descr',     1],
    [ 'COLOR',         'STR', 'color',     1],
  ],
    { WHERE => 1, }
  );

  $self->query( "SELECT $self->{SEARCH_FIELDS} id
     FROM users_status
     $WHERE
     GROUP BY 1
     ORDER BY $SORT $DESC;",
    undef,
    $attr
  );

  return $self->{list};
}

#**********************************************************
=head2 user_status_del($attr) - Del user status

=cut
#**********************************************************
sub user_status_del{
  my $self = shift;
  my ($attr) = @_;

  $self->query_del( 'users_status', $attr );
  return $self;
}

#**********************************************************
=head2 user_status_info($attr) - service user info

  Arguments:
    $attr
      ID

  Returns:
    $self

=cut
#**********************************************************
sub user_status_info{
  my $self = shift;
  my ($attr) = @_;

  $self->query( "SELECT * FROM users_status WHERE id= ? ;",
    undef,
    { INFO => 1,
      Bind => [ $attr->{ID} ] }
  );

  return $self;
}

#**********************************************************
=head2 report_users_disabled($attr) - report for users disabled

  Arguments:
    $attr
  Returns:
    $self

=cut
#**********************************************************
sub report_users_disabled {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 10000;

  my @WHERE_RULES = ("u.disable <> 0");

  my $WHERE = $self->search_former($attr, [
    [ 'ID',           'INT',  'u.id',           1 ],
    [ 'DISABLE',      'INT',  'u.disable',      1 ],
    [ 'DISABLE_DATE', 'DATE', 'u.disable_date', 1 ],
  ],
    { WHERE => 1, WHERE_RULES => \@WHERE_RULES }
  );

  $self->query("
    SELECT
      DATE_FORMAT(u.disable_date, '%Y-%m') AS disable_date,
      SUM(IF(u.disable=1, 1, 0)) as disable,
      SUM(IF(u.disable=2, 1, 0)) as not_active,
      SUM(IF(u.disable=3, 1, 0)) as hold_up,
      SUM(IF(u.disable=4, 1, 0)) as non_payment,
      SUM(IF(u.disable=5, 1, 0)) as err_small_deposit
    FROM users u
    $WHERE
    GROUP BY disable_date
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  return $self->{list} || [];
}

#**********************************************************
=head2 registration_pin_info($attr)

=cut
#**********************************************************
sub registration_pin_info {
  my $self = shift;
  my ($attr) = @_;

  if ($attr->{UID}) {
    $self->query("SELECT *, DECODE(pin_code, ?) as verification_code FROM users_registration_pin WHERE uid = ?;",
      undef, { INFO => 1, Bind => [ $self->{conf}->{secretkey}, $attr->{UID} ] });
  }
  else {
    $self->query("SELECT *, DECODE(pin_code, ?) as verification_code FROM users_registration_pin WHERE destination = ?;",
      undef, { INFO => 1, Bind => [ $self->{conf}->{secretkey}, $attr->{DESTINATION} || '--' ] });
  }

  return $self;
}

#**********************************************************
=head2 registration_pin_change($uid)

=cut
#**********************************************************
sub registration_pin_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'UID',
    TABLE        => 'users_registration_pin',
    DATA         => $attr
  });

  return $self;
}

#**********************************************************
=head2 registration_pin_add($attr)

=cut
#**********************************************************
sub registration_pin_add {
  my $self = shift;
  my ($attr) = @_;

  if ($attr->{PIN_CODE}) {
    $attr->{PIN_CODE} = "ENCODE('$attr->{PIN_CODE}', '$self->{conf}->{secretkey}')",
  }

  $self->query_add('users_registration_pin', $attr);

  return $self;
}

1;
