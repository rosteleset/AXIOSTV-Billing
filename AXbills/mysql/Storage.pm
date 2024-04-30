package Storage;
#*********************** ABillS ***********************************
# Copyright (с) 2003-2023 Andy Gulay (ABillS DevTeam) Ukraine
#
# See COPYRIGHT section in pod text below for usage and distribution rights.
#
#******************************************************************
=head1 NAME

  Storage DB functions module

=head1 VERSION

  VERSION: 8.56
  REVISION: 20221027
  UPDATE: 20230110

=cut

use strict;
use parent 'dbcore';

our $VERSION = 8.56;
my ($admin, $CONF);


#**********************************************************
# Init Storage module
#**********************************************************
sub new {
  my $class = shift;
  my $db = shift;
  ($admin, $CONF) = @_;

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $CONF
  };
  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 storage_articles_list($attr) - Storage list articles

=cut
#**********************************************************
sub storage_articles_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;
  my $EXT_FIELDS = '';
  my $EXT_TABLES = '';

  if (!$admin->{MODULES} || $admin->{MODULES}{'Equipment'}) {
    $EXT_FIELDS = 'm.model_name, m.image_url,';
    $EXT_TABLES = 'LEFT JOIN equipment_models m ON (s.equipment_model_id = m.id)';
  }

  delete $self->{COL_NAMES_ARR};

  $attr->{DOMAIN_ID} ||= $admin->{DOMAIN_ID} || '_SHOW';

  my $WHERE = $self->search_former($attr, [
      [ 'ID',           'INT', 's.id',            ],
      [ 'ARTICLE_TYPE', 'INT', 's.article_type',  ],
      [ 'NAME',         'INT', 's.name',          ],
      [ 'MEASURE',      'INT', 's.measure',       ],
      [ 'DOMAIN_ID',    'INT', 's.domain_id',   1 ],
    ],
    { WHERE => 1 }
  );

  $self->query("SELECT  s.id,
     s.name,
     t.name AS type_name,
     s.measure,
     $EXT_FIELDS
     s.add_date,
     s.comments,
     s.article_type
   FROM storage_articles AS s
   LEFT JOIN storage_article_types t ON (t.id=s.article_type)
   $EXT_TABLES
   $WHERE
   ORDER BY $SORT $DESC
   LIMIT $PG, $PAGE_ROWS;",
    undef, $attr
  );

  my $list = $self->{list} || [];

  $self->query("SELECT  COUNT(s.id) AS total
   FROM storage_articles AS s
   LEFT JOIN storage_article_types t ON (t.id=s.article_type)
   $WHERE;",
    undef, { INFO => 1 }
  );

  return $list;
}

#**********************************************************
=head2 storage_articles_info($attr) - Storage articles info

=cut
#**********************************************************
sub storage_articles_info {
  my $self = shift;
  my ($attr) = @_;

  $self->query("SELECT  *  FROM storage_articles WHERE id= ? ;", undef, { INFO => 1, Bind => [ $attr->{ID} ] });

  return $self;
}

#**********************************************************
=head2 storage_articles_add($attr) - Add Storage articles

=cut
#**********************************************************
sub storage_articles_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('storage_articles', { add_date => 'NOW()', %{$attr}, DOMAIN_ID => $self->{admin}{DOMAIN_ID} || 0 });

  return $self;
}

#**********************************************************
=head2 storage_articles_change($attr) Change storage articles

=cut
#**********************************************************
sub storage_articles_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'storage_articles',
    DATA         => $attr,
  });

  return $self;
}

#**********************************************************
=head2 storage_articles_del($attr) Del storage articles

=cut
#**********************************************************
sub storage_articles_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('storage_articles', $attr);

  return $self->{result};
}

#**********************************************************
=head2 suppliers_list_new($attr) - New suppliers list

=cut
#**********************************************************
sub suppliers_list_new {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;

  $attr->{DOMAIN_ID} ||= $admin->{DOMAIN_ID} || '_SHOW';

  my $WHERE = $self->search_former( $attr, [
      [ 'ID',           'INT',   'id',          1 ],
      [ 'NAME',         'STR',   'name',        1 ],
      [ 'DATE',         'DATE',  'date',        1 ],
      [ 'OKPO',         'STR',   'okpo',        1 ],
      [ 'INN',          'STR',   'inn',         1 ],
      [ 'INN_SVID',     'STR',   'inn_svid',    1 ],
      [ 'BANK_NAME',    'STR',   'bank_name',   1 ],
      [ 'MFO',          'STR',   'mfo',         1 ],
      [ 'ACCOUNT',      'STR',   'account',     1 ],
      [ 'PHONE',        'STR',   'phone',       1 ],
      [ 'PHONE2',       'STR',   'phone2',      1 ],
      [ 'FAX',          'STR',   'fax',         1 ],
      [ 'URL',          'STR',   'url',         1 ],
      [ 'EMAIL',        'STR',   'email',       1 ],
      [ 'TELEGRAM',     'STR',   'telegram',    1 ],
      [ 'ACCOUNTANT',   'STR',   'accountant',  1 ],
      [ 'DIRECTOR',     'STR',   'director',    1 ],
      [ 'MANAGMENT',    'STR',   'managment',   1 ],
      [ 'DOMAIN_ID',    'INT',   'domain_id',   1 ],
      [ 'LOCATION_ID',  'INT',   'location_id', 1 ],
      [ 'COMMENT',      'STR',   'comment',     1 ],
    ], { WHERE => 1 }
  );

  $self->query(
    "SELECT $self->{SEARCH_FIELDS} id FROM storage_suppliers
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
     FROM storage_suppliers
     $WHERE",
    undef,
    { INFO => 1 }
  );

  return $list;
}

#**********************************************************
=head2 suppliers_info($attr) - Get suppliers info

=cut
#**********************************************************
sub suppliers_info {
  my $self = shift;
  my ($attr) = @_;

  $self->query("SELECT * FROM storage_suppliers WHERE id= ? ;", undef,{ INFO => 1, Bind => [ $attr->{ID} ] });

  return $self;
}

#**********************************************************
=head2 suppliers_add($attr) - Add suppliers

=cut
#**********************************************************
sub suppliers_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('storage_suppliers', { %{$attr}, DOMAIN_ID => $self->{admin}{DOMAIN_ID} || 0 });

  return 0;
}

#**********************************************************
=head2 suppliers_del($attr) Del suppliers

=cut
#**********************************************************
sub suppliers_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('storage_suppliers', $attr);

  return $self->{result};
}

#**********************************************************
=head2 suppliers_change($attr) Change suppliers

=cut
#**********************************************************
sub suppliers_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'storage_suppliers',
    DATA         => $attr,
  });

  return $self;
}

#**********************************************************
=head2 storage_incoming_articles_list($attr) -  Storage storage incoming articles list

=cut
#**********************************************************
sub storage_incoming_articles_list {
  my $self = shift;
  my ($attr) = @_;

  my @WHERE_RULES = ();
  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;

  my $EXT_TABLES = '';
  if (defined($attr->{HIDE_ZERO_VALUE})) {
    push @WHERE_RULES,
      "sia.count - (IF(ssub.count IS NULL, 0, "
      . " (SELECT SUM(count) FROM storage_accountability WHERE storage_incoming_articles_id = sia.id GROUP BY storage_incoming_articles_id ))"
      . " + IF(sr.count IS NULL, 0, (SELECT SUM(count) FROM storage_reserve WHERE storage_incoming_articles_id = sia.id GROUP BY storage_incoming_articles_id )))";
  }

  if(defined $attr->{CONSIGNMENT} && $attr->{CONSIGNMENT} ne ''){
    push @WHERE_RULES, "(sia.main_article_id='$attr->{CONSIGNMENT}' OR sia.id='$attr->{CONSIGNMENT}')";
  }

  $attr->{DOMAIN_ID} ||= $admin->{DOMAIN_ID} || '_SHOW';

  my $WHERE = $self->search_former($attr, [
      [ 'ID',              'INT', 'sia.id',               ],
      [ 'MAIN_ARTICLE_ID', 'INT', 'sia.main_article_id',  ],
      [ 'ARTICLE_TYPE',    'INT', 'sat.id',               ],
      [ 'ARTICLE_ID',      'INT', 'sia.article_id',     1 ],
      [ 'STORAGE_ID',      'INT', 'si.storage_id',      1 ],
      [ 'SUPPLIER_ID',     'INT', 'si.supplier_id',     1 ],
      [ 'SN',              'INT', 'sia.sn',             1 ],
      [ 'SERIAL',          'STR', 'sn.serial',          0 ],
      [ 'DOMAIN_ID',       'INT', 'si.domain_id',       0 ],
    ], {
    WHERE             => 1,
    WHERE_RULES       => \@WHERE_RULES,
    SKIP_USERS_FIELDS => [ 'FIO' ]
  });

  my $HAVING = '';
  if ($attr->{UNINSTALL}) {
    $HAVING = "HAVING total > 0";
  }

  $self->query("SELECT  sia.id AS sia_id,
                sia.article_id,
                sia.main_article_id,
                sia.count AS sia_count,
                sia.sum - ((sia.sum/sia.count) * (IF(ssub.count IS NULL, 0,
                  (SELECT SUM(count) FROM storage_accountability WHERE storage_incoming_articles_id = sia.id GROUP BY storage_incoming_articles_id ))
                  + IF(sr.count IS NULL, 0, (SELECT sum(count) FROM storage_reserve WHERE storage_incoming_articles_id = sia.id GROUP BY storage_incoming_articles_id )))) AS sia_sum,
                sn.serial,
                sia.storage_incoming_id,
                si.id AS si_id,
                si.date,
                si.aid AS si_aid,
                INET_NTOA(si.ip) AS ip,
                si.comments AS si_comments,
                si.supplier_id,
                si.storage_id,
                sa.id AS sa_id,
                sa.name AS article_name,
                sa.measure,
                sat.id,
                sat.name AS article_type,
                ss.name AS supplier_name,
                a.name AS admin_name,
                ssub.count AS ssub_count,
                sia.count - (IF(ssub.count IS NULL, 0, (SELECT sum(count) FROM storage_accountability WHERE storage_incoming_articles_id = sia.id GROUP BY storage_incoming_articles_id ))
                  + IF(sr.count IS NULL, 0, (
                      SELECT SUM(count) FROM storage_reserve WHERE storage_incoming_articles_id = sia.id GROUP BY storage_incoming_articles_id ))
                     ) AS total,
                sia.sum / sia.count AS article_price,
                sia.sum AS total_sum,
                si.storage_id,
                (SELECT SUM(count) FROM storage_accountability WHERE storage_incoming_articles_id = sia.id GROUP BY storage_incoming_articles_id ) AS accountability_count,
                (SELECT SUM(count) FROM storage_reserve WHERE storage_incoming_articles_id = sia.id GROUP BY storage_incoming_articles_id ) AS reserve_count,
                (SELECT SUM(count) FROM storage_discard WHERE storage_incoming_articles_id = sia.id GROUP BY storage_incoming_articles_id ) AS discard_count,
                (SELECT SUM(count) FROM storage_installation WHERE storage_incoming_articles_id = sia.id GROUP BY storage_incoming_articles_id ) AS instalation_count,
                (SELECT SUM(count) FROM storage_inner_use WHERE storage_incoming_articles_id = sia.id GROUP BY storage_incoming_articles_id ) AS inner_use_count,

                (SELECT SUM(sum) FROM storage_discard WHERE storage_incoming_articles_id = sia.id GROUP BY storage_incoming_articles_id ) AS discard_sum,
                (SELECT SUM(sum) FROM storage_installation WHERE storage_incoming_articles_id = sia.id GROUP BY storage_incoming_articles_id ) AS instalation_sum,
                (SELECT SUM(sum) FROM storage_inner_use WHERE storage_incoming_articles_id = sia.id GROUP BY storage_incoming_articles_id ) AS inner_use_sum,
                $self->{SEARCH_FIELDS}
                sia.sell_price,
                sia.rent_price,
                sia.sn,
                sia.in_installments_price,
                sn.sn_comments,
                sss.name as storage_name,
                sia.abon_distribution
                FROM storage_incoming_articles AS sia
              LEFT JOIN storage_incoming si ON ( si.id = sia.storage_incoming_id )
              LEFT JOIN storage_articles sa ON ( sa.id = sia.article_id )
              LEFT JOIN storage_article_types sat ON ( sat.id = sa.article_type )
              LEFT JOIN storage_suppliers ss ON ( ss.id = si.supplier_id )
              LEFT JOIN admins a ON ( a.aid = si.aid )
              LEFT JOIN storage_accountability ssub ON ( ssub.storage_incoming_articles_id = sia.id )
              LEFT JOIN storage_reserve sr ON ( sr.storage_incoming_articles_id = sia.id )
              LEFT JOIN storage_sn sn ON (sn.id=sia.sn)
              LEFT JOIN storage_storages sss ON (sss.id=si.storage_id)
                $EXT_TABLES
                $WHERE
                GROUP BY sia.id
                $HAVING
                ORDER BY $SORT DESC;",
    undef,
    $attr
  );

  my $list = $self->{list};

  $self->query("SELECT COUNT(*) AS total, SUM(sia.count) AS count, SUM(sia.sum) as sum FROM storage_incoming_articles AS sia
              LEFT JOIN storage_incoming si ON ( si.id = sia.storage_incoming_id )
              LEFT JOIN storage_articles sa ON ( sa.id = sia.article_id )
              LEFT JOIN storage_article_types sat ON ( sat.id = sa.article_type )
              LEFT JOIN storage_suppliers ss ON ( ss.id = si.supplier_id )
              LEFT JOIN admins a ON ( a.aid = si.aid )
              LEFT JOIN storage_accountability ssub ON ( ssub.storage_incoming_articles_id = sia.id )
              LEFT JOIN storage_reserve sr ON ( sr.storage_incoming_articles_id = sia.id )
              LEFT JOIN storage_sn sn ON (sn.id=sia.sn)
    $EXT_TABLES
    $WHERE
    ;",
    undef,
    { INFO => 1 }
  );

  return $list;
}

#**********************************************************
=head2 storage_incoming_articles_list_lite($attr) - Storage storage incoming articles list

=cut
#**********************************************************
sub storage_incoming_articles_list_lite {
  my $self = shift;
  my ($attr) = @_;

  my @WHERE_RULES = ();
  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $EXT_TABLES = '';

  if (defined($attr->{ID})) {
    push @WHERE_RULES, "sia.id='$attr->{ID}'";
  }
  elsif (defined($attr->{MAIN_ARTICLE_ID})) {
    push @WHERE_RULES, "sia.main_article_id='$attr->{MAIN_ARTICLE_ID}'";
  }

  my $WHERE = ($#WHERE_RULES > - 1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

  $self->query("SELECT  sia.id,
      sia.article_id,
      sia.storage_incoming_id,
      sia.sell_price,
      sia.rent_price,
      sia.in_installments_price,
      sia.main_article_id
    FROM storage_incoming_articles AS sia
    $EXT_TABLES
    $WHERE
    GROUP BY sia.id
    ORDER BY $SORT DESC;",
    undef,
    $attr
  );

  return $self->{list};
}

#**********************************************************
=head2 storage_incoming_articles_info($attr) - Storage incoming articles info

=cut
#**********************************************************
sub storage_incoming_articles_info {
  my $self = shift;
  my ($attr) = @_;

  my $WHERE = $self->search_former($attr, [
      [ 'ID',         'INT', 'sia.id',         ],
      [ 'ARTICLE_ID', 'INT', 'sia.article_id', ]
    ], { WHERE => 1 }
  );

  $self->query("SELECT   sia.*,
                sn.serial,
                si.date,
                si.comments,
                si.storage_id,
                ss.id AS supplier_id,
                sat.id AS article_type_id,
                si.id AS storage_incoming_id,
                sn.sn_comments
          FROM storage_incoming_articles sia
          LEFT JOIN storage_incoming si ON ( si.id = sia.storage_incoming_id )
          LEFT JOIN storage_articles sa ON ( sa.id = sia.article_id )
          LEFT JOIN storage_article_types sat ON ( sat.id = sa.article_type )
          LEFT JOIN storage_suppliers ss ON ( ss.id = si.supplier_id )
          LEFT JOIN storage_sn sn ON (sn.id=sia.sn)
            $WHERE;",
    undef,
    { INFO => 1 }
  );

  return $self;
}

#**********************************************************
=head2 storage_incoming_articles_add($attr) Add Storage incoming articles add

=cut
#**********************************************************
sub storage_incoming_articles_add {
  my $self = shift;
  my ($attr) = @_;

  if (!$self->{errno}) {
    if(!$attr->{INVOICE_ID}){
      $attr->{INVOICE_NUMBER} = $attr->{ADD_INVOICE_NUMBER};
      $self->storage_income_add({ %{$attr}, DOMAIN_ID => ($self->{admin}{DOMAIN_ID} || 0) });
    }
    else{
      $self->{INSERT_ID} = $attr->{INVOICE_ID};
    }
  }

  $self->query_add('storage_incoming_articles', { %{$attr}, STORAGE_INCOMING_ID => $self->{INSERT_ID} });

  if (!$self->{errno}) {
    # add to object INSERT_ID of MAIN ARTICLE ID
    $self->{STORAGE_LAST_INCOMING_ARTICLES_ID} = $self->{INSERT_ID};

    $self->storage_log_add({
      %{$attr},
      DATE            => (!$attr->{DATE} || $attr->{DATE} eq '0000-00-00 00:00:00') ? 'NOW()' : $attr->{DATE},
      STORAGE_MAIN_ID => $self->{INSERT_ID}
    });
  }

  return 0;
}

#**********************************************************
=head2 storage_incoming_articles_return()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub storage_incoming_articles_return {
  my $self = shift;
  my ($attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'storage_incoming_articles',
    DATA         => $attr,
  });

  return $self;
}

#**********************************************************
=head2 storage_incoming_articles_divide($attr) DIVIDE Storage incoming articles

=cut
#**********************************************************
sub storage_incoming_articles_divide {
  my $self = shift;
  my ($attr) = @_;

  if (!$attr->{DIVIDE}) {
    $attr->{DIVIDE} = 1;
  }

  $self->query_add('storage_incoming_articles', { %{$attr}, COUNT => $attr->{DIVIDE} || $attr->{DIVIDE} });

  $self->{INCOMING_ARTICLE_ID} = $self->{INSERT_ID};

  my %UPDATE = (
    ID    => $attr->{MAIN_ARTICLE_ID},
    COUNT => $attr->{COUNT} - $attr->{DIVIDE},
    SUM   => $attr->{SUM_TOTAL} - ($attr->{SUM_TOTAL} / $attr->{COUNT}),
  );

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'storage_incoming_articles',
    DATA         => \%UPDATE
  });

  #if (! $self->{errno}) {
  #  $self->storage_log_add({ %$attr, STORAGE_MAIN_ID => $self->{INSERT_ID}  })
  #}

  return $self;
}

#**********************************************************
=head2 storage_discard($attr) Storage discard

=cut
#**********************************************************
sub storage_discard {
  my $self = shift;
  my ($attr) = @_;

  $self->query("INSERT INTO storage_discard (  storage_incoming_articles_id,
                     count, aid,  date, comments, sum )
                 VALUES ( ?, ?,  ?, NOW(), ?,  ? );",
    'do',
    { Bind => [
      $attr->{ID},
      $attr->{COUNT},
      $admin->{AID},
      $attr->{COMMENTS},
      ($attr->{SUM_TOTAL} / $attr->{COUNT_INCOMING}) * $attr->{COUNT}
    ] }
  );

  my %UPDATE = (
    ID    => $attr->{ID},
    COUNT => (($attr->{COUNT_INCOMING} - $attr->{COUNT}) == 0) ? 'NULL' : $attr->{COUNT_INCOMING} - $attr->{COUNT},
    SUM   =>(($attr->{COUNT_INCOMING} - $attr->{COUNT}) == 0) ? 'NULL' : $attr->{SUM_TOTAL} -
      (($attr->{SUM_TOTAL} / $attr->{COUNT_INCOMING}) * $attr->{COUNT})
  );

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'storage_incoming_articles',
    DATA         => \%UPDATE,
  });

  if (!$self->{errno}) {
    $self->storage_log_add({ %{$attr}, STORAGE_MAIN_ID => $attr->{MAIN_ARTICLE_ID}, ACTION => 2 });
  }

  return 0;
}

#**********************************************************
=head2 storage_discard_del()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub storage_discard_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('storage_discard', $attr);

  $self->storage_log_add({ %{$attr},
    ACTION     => 6,
    ARTICLE_ID => $attr->{ID},
    COMMENTS   => 'ID: ' . $attr->{ID} . $attr->{COMMENTS}
  });

  return $self;
}

#**********************************************************
=head2 storage_income_add($attr) Storage income add

=cut
#**********************************************************
sub storage_income_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('storage_incoming', {
    %{$attr},
    DATE      => (!$attr->{DATE} || $attr->{DATE} eq '0000-00-00 00:00:00') ? 'NOW()' : $attr->{DATE},
    IP        => $admin->{SESSION_IP} || '0.0.0.0',
    DOMAIN_ID => $admin->{DOMAIN_ID} || 0
  });

  return 0;
}

#**********************************************************
=head2 storage_income_add($attr) Storage income add

=cut
#**********************************************************
sub storage_income_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('storage_incoming', $attr);

  $self->storage_log_add({ %{$attr},
    ACTION     => 10,
    COMMENTS   => 'INVOICE ID: ' . $attr->{ID} . ' ' . $attr->{COMMENTS}
  });

  return 0;
}

#**********************************************************
=head2 storage_incoming_articles_change($attr) - Change storage incoming articles

=cut
#**********************************************************
sub storage_incoming_articles_change {
  my $self = shift;
  my ($attr) = @_;

  my $STORAGE_INCOMING_ARTICLES_ID = $attr->{ID};

  if (!$attr->{SN}) {
    if ($attr->{SERIAL} || $attr->{SN_COMMENTS}) {
      $self->query_add('storage_sn', {
        STORAGE_INCOMING_ARTICLES_ID => $attr->{ID},
        SERIAL                       => $attr->{SERIAL},
        SN_COMMENTS                  => $attr->{SN_COMMENTS},
        QRCODE_HASH                  => $attr->{QRCODE_HASH},
      });
      $attr->{SN} = $self->{INSERT_ID};
    }
  }
  else {
    $attr->{ID} = $attr->{SN};
    $self->changes({
      CHANGE_PARAM => 'ID',
      TABLE        => 'storage_sn',
      DATA         => $attr,
    });
    if ($self->{errno} && $self->{errno} == 3) {
      $self->query_add('storage_sn', {
        STORAGE_INCOMING_ARTICLES_ID => $attr->{ID},
        SERIAL                       => $attr->{SERIAL},
        SN_COMMENTS                  => $attr->{SN_COMMENTS},
        QRCODE_HASH                  => $attr->{QRCODE_HASH},
      });
      $attr->{SN} = $self->{INSERT_ID};
      delete $self->{errno};
    }
  }

  $attr->{ID} = $STORAGE_INCOMING_ARTICLES_ID;
  $attr->{STORAGE_INCOMING_ID} = $attr->{INVOICE_ID} || $attr->{STORAGE_INCOMING_ID};
  $attr->{ABON_DISTRIBUTION} //= 0;
  $attr->{PUBLIC_SALE} //= 0;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'storage_incoming_articles',
    DATA         => $attr,
  });

  $self->storage_incoming_articles_info({ ID => $attr->{ID} });
  $attr->{NEW_STORAGE_ID} = $self->{STORAGE_ID} || '';
  $attr->{ID} = $self->{STORAGE_INCOMING_ID};

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'storage_incoming',
    DATA         => $attr,
  });

  if ($attr->{MOVE_ITEMS}) {
    $self->storage_info({ ID => $attr->{NEW_STORAGE_ID}, COLS_NAME => 1 });
    my $new_storage = $self->{NAME};

    $self->storage_info({ ID => $attr->{OLD_STORAGE_ID}, COLS_NAME => 1 });
    my $old_storage = $self->{NAME};

    $self->storage_log_add({ %{$attr},
      ACTION          => 17,
      STORAGE_MAIN_ID => $STORAGE_INCOMING_ARTICLES_ID,
      COMMENTS        => "$old_storage -> $new_storage",
      COUNT           => $attr->{MOVE_ITEMS}
    });
  }

  return $self;
}

#**********************************************************
=head2 storage_incoming_articles_del($attr) - Del Storage incoming articles

=cut
#**********************************************************
sub storage_incoming_articles_del {
  my $self = shift;
  my ($attr) = @_;

  my $sn_info = $self->storage_incoming_articles_info({ ID => $attr->{ID} });

  $self->query_del('storage_incoming_articles', $attr);
  $self->query_del('storage_sn', { ID => $sn_info->{SN} }) if $sn_info->{SN} && !$self->{errstr};

  $self->storage_log_add({ %{$attr},
    ACTION     => 10,
    ARTICLE_ID => $attr->{ID},
    COMMENTS   => 'ID: ' . $attr->{ID} . $attr->{COMMENTS}
  });

  return $self;
}

#**********************************************************
=head2 storage_types_list($attr) Storage list types

=cut
#**********************************************************
sub storage_types_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  $attr->{DOMAIN_ID} ||= $admin->{DOMAIN_ID} || '_SHOW';

  my $WHERE = $self->search_former($attr, [
    [ 'ID',         'INT',        'st.id',        ],
    [ 'NAME',       'STR',        'st.name',      ],
    [ 'COMMENTS',   'STR',        'st.comments',  ],
    [ 'DOMAIN_ID',  'DOMAIN_ID',  'st.domain_id', ]
  ], { WHERE => 1 });

  $self->query("SELECT st.id,
      st.name,
      st.comments
    FROM storage_article_types AS st
    $WHERE
    ORDER BY $SORT $DESC;",
    undef, $attr
  );

  return $self->{list};
}

#**********************************************************
=head2 storage_articles_types_info($attr) Storage articles types info

=cut
#**********************************************************
sub storage_articles_types_info {
  my $self = shift;
  my ($attr) = @_;

  $self->query("SELECT * FROM storage_article_types WHERE id= ?;", undef, { INFO => 1, Bind => [ $attr->{ID} ] });

  return $self;
}

#**********************************************************
=head2 storage_types_add($attr) -  Add Storage types

=cut
#**********************************************************
sub storage_types_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('storage_article_types', { %$attr, DOMAIN_ID => $self->{admin}{DOMAIN_ID} || 0 });

  return 0;
}

#**********************************************************
=head2 storage_types_change($attr) - Change Storage articles types

=cut
#**********************************************************
sub storage_types_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'storage_article_types',
    DATA         => $attr,
  });

  return $self;
}

#**********************************************************
=head2 storage_types_del($attr) - Del Storage articles types

=cut
#**********************************************************
sub storage_types_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('storage_article_types', $attr);

  return $self->{result};
}

#**********************************************************
=head2 storage_log_list($attr) list Storage log

=cut
#**********************************************************
sub storage_log_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? 'DESC' : '';
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;

  my $EXT_TABLES = '';

  my $WHERE = $self->search_former($attr, [
    [ 'DATE',              'DATE', 'sl.date',                           1 ],
    [ 'ARTICLE_NAME',      'STR',  'sa.name', 'sa.name AS article_name'   ],
    [ 'COUNT',             'INT',  'sl.count',                          1 ],
    [ 'ARTICLE_TYPE',      'INT',  'sl.article_type',                   1 ],
    [ 'TYPE_NAME',         'STR',  'sat.name as type_name',             1 ],
    [ 'TYPE_ID',           'INT',  'sat.id as type_id',                 1 ],
    [ 'ACTION',            'INT',  'sl.action',                         1 ],
    [ 'COMMENTS',          'STR',  'sl.comments',                       1 ],
    [ 'ADMIN_NAME',        'STR',  'adm.name', 'adm.name AS admin_name'   ],
    [ 'SERIAL',            'STR',  'sn.serial',                         1 ],
    [ 'IP',                'IP',   'sl.ip',    'INET_NTOA(sl.ip) AS ip'   ],
    [ 'AID',               'INT',  'sl.aid',                            1 ],
    [ 'STORAGE_ID',        'INT',  'sl.storage_id',                     1 ],
    [ 'STORAGE_NAME',      'STR',  'sss.name AS storage_name',          1 ],
    [ 'STORAGE_MAIN_ID',   'INT',  'sl.storage_main_id',                1 ],
    [ 'ARTICLE_ID',        'INT',  'sm.article_id',                       ],
    [ 'ID',                'INT',  'sl.id',                             1 ],
    [ 'LOGIN',             'STR',  'u.id as login',                     1 ],
    [ 'UID',               'INT',  'sl.uid',                            1 ],
    [ 'MEASURE',           'INT',  'sa.measure',                        1 ],
    [ 'FROM_DATE|TO_DATE', 'DATE', "DATE_FORMAT(sl.date, '%Y-%m-%d')",  1 ],
    [ 'INVOICE_ID',        'INT',  'si.id AS invoice_id',               1 ],
    [ 'INVOICE_NUMBER',    'STR',  'si.invoice_number',                 1 ],
    ], { WHERE => 1, USE_USER_PI => 1 }
  );

  $self->query("SELECT $self->{SEARCH_FIELDS} sm.article_id, sl.aid, sl.id
    FROM storage_log AS sl
    LEFT JOIN admins adm ON ( adm.aid = sl.aid )
    LEFT JOIN storage_incoming_articles sm ON ( sm.id = sl.storage_main_id )
    LEFT JOIN storage_articles sa ON ( sa.id = sm.article_id )
    LEFT JOIN storage_article_types sat ON ( sat.id = sa.article_type )
    LEFT JOIN users u ON ( u.uid = sl.uid )
    LEFT JOIN storage_sn sn ON ( sn.id = sm.sn )
    LEFT JOIN storage_storages sss ON ( sss.id = sl.storage_id )
    LEFT JOIN storage_incoming si ON (si.id = sm.storage_incoming_id)
    $EXT_TABLES
    $WHERE
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;",
    undef, $attr
  );

  my $list = $self->{list};

  $self->query("SELECT count(*) AS total
    FROM storage_log AS sl
    LEFT JOIN admins adm ON ( adm.aid = sl.aid )
    LEFT JOIN storage_incoming_articles sm ON ( sm.id = sl.storage_main_id )
    LEFT JOIN storage_articles sa ON ( sa.id = sm.article_id )
    LEFT JOIN storage_article_types sat ON ( sat.id = sa.article_type )
    LEFT JOIN users u ON ( u.uid = sl.uid )
    LEFT JOIN storage_sn sn ON ( sn.id = sm.sn )
    LEFT JOIN storage_storages sss ON ( sss.id = sl.storage_id )
    LEFT JOIN storage_incoming si ON (si.id = sm.storage_incoming_id)
    $EXT_TABLES  $WHERE", undef, { INFO => 1 }
  );

  return $list;
}

#**********************************************************
=head2 storage_log_add($attr) add Storage log

=cut
#**********************************************************
sub storage_log_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('storage_log', { %{$attr},
    DATE => 'NOW()',
    IP   => $admin->{SESSION_IP},
    AID  => $admin->{AID},
    ID   => undef,
  });

  return 0;
}

#**********************************************************
=head2 storage_log_del($attr) del Storage log

=cut
#**********************************************************
sub storage_log_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('storage_log', $attr);

  return 0;
}

#**********************************************************
=head2 storage_accountability_add($attr) Storage accountability add

=cut
#**********************************************************
sub storage_accountability_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('storage_accountability', {
    %{$attr},
    DATE => 'NOW()',
    ID   => undef
  });

  $self->storage_log_add({ %{$attr},
    STORAGE_MAIN_ID => $attr->{STORAGE_INCOMING_ARTICLES_ID} || $attr->{ID},
    COMMENTS        => "AID: $attr->{AID} " . ($attr->{COMMENTS} || ''),
    ACTION          => 3
  }) if !$self->{errno};
  return 0;
}

#**********************************************************
=head2 storage_accountability_list($attr) Storage accountability list

=cut
#**********************************************************
sub storage_accountability_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{sort}) ? $attr->{sort} : 1;
  my $DESC = ($attr->{desc}) ? $attr->{desc} : '';
  my $EXT_TABLES = '';

  $attr->{DOMAIN_ID} ||= $admin->{DOMAIN_ID} || '_SHOW';

  my $WHERE = $self->search_former($attr, [
    [ 'AID',                           'INT',  'sa.aid',                                     1 ],
    [ 'COUNT',                         'INT',  'sa.count',                                   1 ],
    [ 'ADMIN_NAME',                    'STR',  'adm.name as admin_name',                     1 ],
    [ 'DATE',                          'STR',  'sa.date',                                    1 ],
    [ 'STORAGE_INCOMING_ARTICLES_ID',  'STR',  'sa.storage_incoming_articles_id',            1 ],
    [ 'COMMENTS',                      'STR',  'sa.comments',                                1 ],
    [ 'ARTICLE_NAME',                  'STR',  'sta.name AS article_name',                   1 ],
    [ 'TYPE_NAME',                     'STR',  'sat.name AS type_name',                      1 ],
    [ 'SA_SUM',                        'INT',  'sa.count * (sia.sum / sia.count) AS sa_sum', 1 ],
    [ 'SERIAL',                        'INT',  'sn.serial',                                  1 ],
    [ 'MEASURE',                       'INT',  'sta.measure',                                1 ],
    [ 'ID',                            'INT',  'sa.id',                                      1 ],
    [ 'ADDED_BY_ADMIN_NAME',           'STR',  'add_adm.name as added_by_admin_name',        1 ],
    [ 'ARTICLE_TYPE_ID',               'INT',  'sat.id as article_type_id',                  1 ],
    [ 'ARTICLE_ID',                    'INT',  'sta.id as article_id',                       1 ],
    ['FROM_DATE|TO_DATE',              'DATE', "DATE_FORMAT(sa.date, '%Y-%m-%d')",           1 ],
    [ 'DOMAIN_ID',                     'INT',  'si.domain_id',                                 ],
    ], { WHERE => 1 }
  );

  $self->query("SELECT  $self->{SEARCH_FIELDS} sa.id
     FROM storage_accountability AS sa
   LEFT JOIN admins adm ON ( adm.aid = sa.aid )
   LEFT JOIN storage_incoming_articles sia ON ( sia.id = sa.storage_incoming_articles_id )
   LEFT JOIN storage_articles sta ON ( sta.id = sia.article_id )
   LEFT JOIN storage_article_types sat ON ( sat.id = sta.article_type )
   LEFT JOIN storage_sn sn ON (sn.id=sia.sn)
   LEFT JOIN admins add_adm ON ( add_adm.aid = sa.added_by_aid )
   LEFT JOIN storage_incoming si ON (si.id = sia.storage_incoming_id)
   $EXT_TABLES
   $WHERE
   ORDER BY $SORT $DESC;",
    undef,
    $attr
  );

  return $self->{list};
}

#**********************************************************
=head2 storage_accountability_del($attr) Del Storage accountability

=cut
#**********************************************************
sub storage_accountability_del {
  my $self = shift;
  my ($attr) = @_;

  if ($attr->{COUNT}) {
    $self->changes({
      CHANGE_PARAM => 'ID',
      TABLE        => 'storage_accountability',
      DATA         => $attr,
    });
  }
  else {
    $self->query_del('storage_accountability', $attr);
  }

  return $self->{result};
}

#**********************************************************
=head2 storage_discard_list2($attr) Storage discard list

=cut
#**********************************************************
sub storage_discard_list2 {
  my $self = shift;
  my ($attr) = @_;

  my @WHERE_RULES = ();

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  if (defined($attr->{AID})) {
    push @WHERE_RULES, "sa.aid='$attr->{AID}'";
  }

  my $WHERE = ($#WHERE_RULES > - 1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

  $self->query("SELECT
    adm.name AS admin_name,
    sat.name AS sat_name,
    sta.name AS sta_name,
    d.count,
    d.sum,
    d.date,
    d.comments,
    d.id,
    d.storage_incoming_articles_id,
    d.aid,
    d.count * (sia.sum / sia.count) AS discard_sum,
    sta.measure,
    sn.serial
  FROM storage_discard AS d
  LEFT JOIN admins adm ON ( adm.aid = d.aid )
  LEFT JOIN storage_incoming_articles sia ON ( sia.id = d.storage_incoming_articles_id )
  LEFT JOIN storage_articles sta ON ( sta.id = sia.article_id )
  LEFT JOIN storage_article_types sat ON ( sat.id = sta.article_type )
  LEFT JOIN storage_sn sn ON ( sn.storage_incoming_articles_id = d.storage_incoming_articles_id )
  $WHERE
  ORDER BY $SORT $DESC;",
    undef, $attr
  );

  return $self->{list} || [];
}

#**********************************************************
=head2 storage_discard_list($attr) -  Storage storage incoming articles list

=cut
#**********************************************************
sub storage_discard_list {
  my $self = shift;
  my ($attr) = @_;

  my @WHERE_RULES = ();

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  $attr->{DOMAIN_ID} ||= $admin->{DOMAIN_ID} || '_SHOW';

  my $WHERE = $self->search_former($attr, [
    [ 'ADMIN_NAME',                   'STR', 'adm.name as admin_name',                         1 ],
    [ 'SAT_NAME',                     'STR', 'sat.name AS sat_name',                           1 ],
    [ 'STA_NAME',                     'STR', 'sta.name AS sta_name',                           1 ],
    [ 'COUNT',                        'INT', 'd.count',                                        1 ],
    [ 'DATE',                         'DATE', 'd.date',                                        1 ],
    [ 'SUM',                          'INT', ' d.sum',                                         1 ],
    [ 'COMMENTS',                     'STR', 'd.comments',                                     1 ],
    [ 'SERIAL',                       'STR', 'sn.serial',                                      1 ],
    [ 'ID',                           'INT', 'd.id',                                           1 ],
    [ 'STORAGE_INCOMING_ARTICLES_ID', 'INT', 'd.storage_incoming_articles_id',                 1 ],
    [ 'AID',                          'INT', 'd.aid',                                          1 ],
    [ 'DISCARD_SUM',                  'INT', 'd.count * (sia.sum / sia.count) AS discard_sum', 1 ],
    [ 'MEASURE',                      'INT', 'sta.measure',                                    1 ],
    [ 'MEASURE_NAME',                 'STR', 'sm.name as measure_name',                        1 ],
    [ 'FROM_DATE|TO_DATE',            'DATE', "DATE_FORMAT(d.date, '%Y-%m-%d')",               1 ],
    [ 'ARTICLE_TYPE_ID',              'INT',  'sat.id as article_type_id',                     1 ],
    [ 'ARTICLE_ID',                   'INT',  'sta.id as article_id',                          1 ],
    [ 'DOMAIN_ID',                    'INT',  'si.domain_id',                                  1 ]
  ], {
    WHERE             => 1,
    WHERE_RULES       => \@WHERE_RULES,
    SKIP_USERS_FIELDS => [ 'FIO', 'DOMAIN_ID' ]
  });


  $self->query("SELECT $self->{SEARCH_FIELDS} d.id
    FROM storage_discard AS d
    LEFT JOIN admins adm ON ( adm.aid = d.aid )
    LEFT JOIN storage_incoming_articles sia ON ( sia.id = d.storage_incoming_articles_id )
    LEFT JOIN storage_articles sta ON ( sta.id = sia.article_id )
    LEFT JOIN storage_article_types sat ON ( sat.id = sta.article_type )
    LEFT JOIN storage_sn sn ON ( sn.storage_incoming_articles_id = d.storage_incoming_articles_id )
    LEFT JOIN storage_measure sm ON (sm.id = sta.measure)
    LEFT JOIN storage_incoming si ON (si.id = sia.storage_incoming_id)
    $WHERE
    GROUP BY d.id
    ORDER BY $SORT $DESC;",
    undef,
    $attr
  );

  my $list = $self->{list};

  $self->query("SELECT COUNT(*) AS total FROM storage_discard AS d
    LEFT JOIN admins adm ON ( adm.aid = d.aid )
    LEFT JOIN storage_incoming_articles sia ON ( sia.id = d.storage_incoming_articles_id )
    LEFT JOIN storage_articles sta ON ( sta.id = sia.article_id )
    LEFT JOIN storage_article_types sat ON ( sat.id = sta.article_type )
    LEFT JOIN storage_sn sn ON ( sn.storage_incoming_articles_id = d.storage_incoming_articles_id )
    LEFT JOIN storage_incoming si ON (si.id = sia.storage_incoming_id)
    $WHERE;",
    undef,
    { INFO => 1 }
  );

  return $list;
}

#**********************************************************
=head2 storage_installation_list($attr) Storage installation list

=cut
#**********************************************************
sub storage_installation_list {
  my $self = shift;
  my ($attr) = @_;

  delete $self->{COL_NAMES_ARR};

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG = $attr->{PG} || '0';
  my $PAGE_ROWS = $attr->{PAGE_ROWS} || 25;

  $attr->{SKIP_DEL_CHECK} = 1;
  my $GROUP_BY = $attr->{GROUP_BY} || 'i.id';

  my $search_columns = [
    [ 'ID',                              'INT', 'i.id',                                                            1 ],
    [ 'STORAGE_INCOMING_ARTICLES_ID',    'INT', 'i.storage_incoming_articles_id',                                  1 ],
    [ 'LOCATION_ID',                     'INT', 'i.location_id',                                                   1 ],
    [ 'AID',                             'INT', 'i.aid',                                                           1 ],
    [ 'LOGIN',                           'INT', 'u.id AS login',                                                   1 ],
    [ 'NAS_ID',                          'INT', 'i.nas_id',                                                        1 ],
    [ 'STA_NAME',                        'STR', 'sta.name AS sta_name',                                            1 ],
    [ 'SAT_TYPE',                        'STR', 'sat.name AS sat_type',                                            1 ],
    [ 'COUNT',                           'INT', 'i.count',                                                         1 ],
    [ 'ACTUAL_SELL_PRICE',               'INT', 'i.actual_sell_price',                                             1 ],
    [ 'SUM',                             'INT', 'i.sum',                                                           1 ],
    [ 'ADMIN_NAME',                      'STR', 'adm.name AS admin_name',                                          1 ],
    [ 'ARTICLES_SUM',                    'INT', 'i.count * (sia.sum / sia.count)',                                 1 ],
    [ 'NAS_NAME',                        'STR', 'nas.name as nas_name',                                            1 ],
    [ 'BUILD',                           'INT', 'b.number as build',                                               1 ],
    [ 'STREET',                          'STR', 's.name as street',                                                1 ],
    [ 'STREET_ID',                       'INT', 's.id as street_id',                                               1 ],
    [ 'DISTRICT_ID',                     'INT', 'd.id as district_id',                                               1 ],
    [ 'ADDRESS_FULL',                    'STR',  "CONCAT(" . ($CONF->{ADDRESS_FULL_SHOW_DISTRICT} ? "d.name, " .
      "'$CONF->{BUILD_DELIMITER}'," : "") . "s.name, '$CONF->{BUILD_DELIMITER}', b.number) AS address_full",       1 ],
    [ 'DISTRICT',                        'STR', 'd.name as district'                                                 ],
    [ 'MAC',                             'STR', 'i.mac',                                                           1 ],
    [ 'IP',                              'IP',  'INET_NTOA(internet.ip) AS ip',                                    1 ],
    [ 'SERIAL',                          'STR', 'sn.serial AS serial',                                             1 ],
    [ 'STATUS',                          'INT', 'i.type AS status',                                                1 ],
    [ 'DATE',                            'DATE','i.date',                                                          1 ],
    [ 'INSTALLED_AID',                   'STR', 'adm.aid AS installed_aid',                                        1 ],
    [ 'INSTALLED_AID_NAME',              'STR', 'adm.name AS installed_aid_name',                                  1 ],
    [ 'RESPOSIBLE_FOR_INSTALLATION_AID', 'STR', 'resposible_adm.aid as resposible_for_installation_aid',           1 ],
    [ 'RESPOSIBLE_FOR_INSTALLATION',     'STR', 'resposible_adm.name as resposible_for_installation',              1 ],
    [ 'INSTALLATION_COMMENTS',           'STR', 'i.comments AS installation_comments',                             1 ],
    [ 'MONTHES',                         'INT', 'i.monthes',                                                       1 ],
    [ 'ARTICLE_ID',                      'INT', 'sta.id'                                                             ],
    # [ 'ADDRESS_FULL2',                   'STR', "CONCAT(str.name, ' ', install_b.number,
    #   '$CONF->{BUILD_DELIMITER}') AS address_full2",
    #   "CONCAT(str.name, ' ', install_b.number, '$attr->{BUILD_DELIMITER}') AS address_full2"                         ],
    [ 'UID',                             'INT', 'i.uid',                                                           1 ],
    [ 'STORAGE_MAIN_ID',                 'INT', 'i.storage_incoming_articles_id as storage_main_id',               1 ],
    [ 'MEASURE',                         'INT', 'sta.measure',                                                     1 ],
    [ 'STORAGE_ARTICLE_ID',              'INT', 'sta.id as storage_article_id',                                    1 ],
    [ 'MEASURE_NAME',                    'STR', 'sm.name as measure_name',                                         1 ],
    [ 'STA_ID',                          'INT', 'sta.id as sta_id',                                                1 ],
    [ 'SAT_ID',                          'INT', 'sat.id as sat_id',                                                1 ],
    [ 'ADMIN_PERCENT',                   'INT', '(i.actual_sell_price / 100 * sadmin.percent) AS admin_percent',   1 ],
    [ 'SN_ID',                           'INT', 'sn.id as sn_id',                                                  1 ],
    [ 'INCOMING_DOMAIN_ID',              'INT', 'si.domain_id as incoming_domain_id',                              1 ],
    [ 'STORAGE_ID',                      'INT', 'si.storage_id as storage_id',                                     1 ],
    [ 'STORAGE_NAME',                    'STR', 'sstor.name as storage_name',                                      1 ],
    [ 'FROM_DATE|TO_DATE',               'DATE',"DATE_FORMAT(i.date, '%Y-%m-%d')",                                 1 ],
    [ 'RENT_PRICE',                      'INT', 'sia.rent_price',                                                  1 ],
    [ 'ABON_DISTRIBUTION',               'INT', 'sia.abon_distribution',                                           1 ],
    [ 'AMOUNT_PER_MONTH',                'INT', 'i.amount_per_month',                                              1 ],
    [ 'NAS_ID',                          'INT', 'i.nas_id',                                                        1 ],
    [ 'NAS',                             'INT', 'n.name AS nas',                                                   1 ],
    [ 'DELIVERY_ID',                     'INT', ' sd.id AS delivery_id',                                           1 ],
  ];

  if ($attr->{SHOW_ALL_COLUMNS}) {
    foreach my $column (@$search_columns) {
      $attr->{$column->[0]} = '_SHOW' if (!$attr->{$column->[0]});
    }
  }

  my $WHERE = $self->search_former($attr, $search_columns, {
    WHERE             => 1,
    USERS_FIELDS      => 1,
    USE_USER_PI       => 1,
    SKIP_USERS_FIELDS => [ 'UID', 'LOGIN', 'LOCATION_ID', 'ADDRESS_STREET', 'STREET_ID', 'DISTRICT_ID', 'DOMAIN_ID', 'ADDRESS_FULL' ]
  });

  my $EXT_TABLES = $self->{EXT_TABLES} || '';

  if ($attr->{INTERNET} || $attr->{IP}) {
    $EXT_TABLES .= " LEFT JOIN internet_main internet ON ( internet.uid = i.uid )";
  }

  if ($self->{SEARCH_FIELDS} =~ /nas/) {
    $EXT_TABLES .= " LEFT JOIN nas n ON (n.id = i.nas_id)";
  }

  $self->query("SELECT $self->{SEARCH_FIELDS} i.id
        FROM storage_installation AS i
        LEFT JOIN admins adm ON ( adm.aid = i.aid )
        LEFT JOIN storage_incoming_articles sia FORCE INDEX FOR JOIN (`PRIMARY`) ON ( sia.id = i.storage_incoming_articles_id )
        LEFT JOIN storage_articles sta ON ( sta.id = sia.article_id )
        LEFT JOIN storage_article_types sat ON ( sat.id = sta.article_type )
        LEFT JOIN nas nas ON ( nas.id = i.nas_id )
        LEFT JOIN users u ON ( u.uid = i.uid )
        LEFT JOIN users_pi up ON ( u.uid = up.uid )
        LEFT JOIN builds b ON ( b.id = IF(up.location_id, up.location_id,
          IF(nas.location_id, nas.location_id, IF(i.location_id, i.location_id, 0))) )
        LEFT JOIN streets s ON ( s.id = b.street_id )
        LEFT JOIN districts d ON ( d.id = s.district_id )
        LEFT JOIN storage_sn sn ON ( sn.id = sia.sn )
        LEFT JOIN storage_measure sm ON ( sm.id = sta.measure )
        LEFT JOIN admins resposible_adm ON (resposible_adm.aid = i.installed_aid)
        LEFT JOIN storage_admins sadmin ON (sadmin.aid = i.installed_aid)
        LEFT JOIN storage_incoming si ON (si.id = sia.storage_incoming_id)
        LEFT JOIN storage_storages sstor ON (sstor.id = si.storage_id)
        LEFT JOIN storage_deliveries sd ON (sd.installation_id = i.id)
        $EXT_TABLES
        $WHERE
        GROUP BY $GROUP_BY
        ORDER BY $SORT $DESC
        LIMIT $PG, $PAGE_ROWS;",
    undef, $attr
  );
  my $list = $self->{list};

  $self->query("SELECT SUM(i.count) AS installation_count_sum
        FROM storage_installation AS i
        LEFT JOIN admins adm ON ( adm.aid = i.aid )
        LEFT JOIN storage_incoming_articles sia ON ( sia.id = i.storage_incoming_articles_id )
        LEFT JOIN storage_articles sta ON ( sta.id = sia.article_id )
        LEFT JOIN storage_article_types sat ON ( sat.id = sta.article_type )
        LEFT JOIN nas nas ON ( nas.id = i.nas_id )
        LEFT JOIN users u ON ( u.uid = i.uid )
        LEFT JOIN users_pi up ON ( u.uid = up.uid )
        LEFT JOIN builds b ON ( b.id = IF(up.location_id, up.location_id,
          IF(nas.location_id, nas.location_id, IF(i.location_id, i.location_id, 0))) )
        LEFT JOIN streets s ON ( s.id = b.street_id )
        LEFT JOIN districts d ON ( d.id = s.district_id )
        LEFT JOIN storage_sn sn ON ( i.id = sn.storage_installation_id )
        LEFT JOIN admins resposible_adm ON (resposible_adm.aid = i.installed_aid)
        LEFT JOIN storage_incoming si ON (si.id = sia.storage_incoming_id)
        $EXT_TABLES
        $WHERE;",
    undef, { INFO => 1, %{$attr} }
  );

  my $install_count = $self->{list}[0] ? $self->{list}[0]{installation_count_sum} ?
    $self->{list}[0]{installation_count_sum} : 0 : 0;

  $self->query("SELECT COUNT(i.id) AS total
        FROM storage_installation AS i
        LEFT JOIN admins adm ON ( adm.aid = i.aid )
        LEFT JOIN storage_incoming_articles sia ON ( sia.id = i.storage_incoming_articles_id )
        LEFT JOIN storage_articles sta ON ( sta.id = sia.article_id )
        LEFT JOIN storage_article_types sat ON ( sat.id = sta.article_type )
        LEFT JOIN nas nas ON ( nas.id = i.nas_id )
        LEFT JOIN users u ON ( u.uid = i.uid )
        LEFT JOIN users_pi up ON ( u.uid = up.uid )
        LEFT JOIN builds b ON ( b.id = IF(up.location_id, up.location_id,
          IF(nas.location_id, nas.location_id, IF(i.location_id, i.location_id, 0))) )
        LEFT JOIN streets s ON ( s.id = b.street_id )
        LEFT JOIN districts d ON ( d.id = s.district_id )
        LEFT JOIN storage_sn sn ON ( i.id = sn.storage_installation_id )
        LEFT JOIN admins resposible_adm ON (resposible_adm.aid = i.installed_aid)
        LEFT JOIN storage_incoming si ON (si.id = sia.storage_incoming_id)
        $EXT_TABLES
        $WHERE
        GROUP BY i.id;",
    undef, $attr
  );

  $self->{INSTALLATION_COUNT_SUM} = $install_count if $install_count != 0;

  return $list;
}

#**********************************************************
=head2 storage_installation_log($attr) - Storage installation log

=cut
#**********************************************************
sub storage_installation_log {
  my $self = shift;
  my ($attr) = @_;

  my $WHERE = $self->search_former($attr, [
      [ 'ID',              'INT', 'i.id',    ],
      [ 'AID',             'INT', 'i.aid',   ],
      [ 'UID',             'INT', 'log.uid', ],
      [ 'STATUS',          'INT', 'i.type',  ],
      [ 'DISTRICT',        'INT', 'd.id',    ],
      [ 'STREET',          'INT', 'str.id',  ],
      [ 'STORAGE_MAIN_ID', 'INT', 'log.storage_main_id', 1 ],
      [ 'IP',              'IP',  'INET_NTOA(internet.ip) AS ip', 1]
    ], {
      WHERE             => 1,
      USERS_FIELDS      => 1,
      SKIP_USERS_FIELDS => [ 'UID' ]
    }
  );

  my $EXT_TABLES = '';
  if ($attr->{INTERNET}) {
    $EXT_TABLES .= " LEFT JOIN internet_main internet ON ( internet.uid = i.uid )";
  }

  $self->query("SELECT  i.id,
        i.storage_incoming_articles_id,
        i.location_id,
        i.aid,
        log.uid,
        i.nas_id,
        i.count,
        i.comments,
        adm.name AS admin_name,
        sta.name AS sta_name,
        sat.name AS sat_name,
        i.count * (sia.sum / sia.count) AS total_sum,
        sta.measure,
        i.sum,
        u.id AS login,
        i.mac,
        i.grounds,
        i.type AS install_type,
        sn.serial,
        log.date,
        log.action,
        log.comments,
        $self->{SEARCH_FIELDS}
        sia.sn,
        sa.name AS sta2_name
      FROM storage_log AS log
      LEFT JOIN storage_installation i ON ( i.id = log.storage_installation_id )
      LEFT JOIN admins adm ON ( adm.aid = log.aid )
      LEFT JOIN storage_incoming_articles sia ON ( sia.id = i.storage_incoming_articles_id )
      LEFT JOIN storage_articles sta ON ( sta.id = sia.article_id )
      LEFT JOIN storage_article_types sat ON ( sat.id = sta.article_type )

      LEFT JOIN storage_incoming_articles sm ON ( sm.id = log.storage_main_id )
      LEFT JOIN storage_articles sa ON ( sa.id = sm.article_id )

      LEFT JOIN users u ON ( u.uid = log.uid )
      LEFT JOIN storage_sn sn ON ( i.id = sn.storage_installation_id )
      $EXT_TABLES

      $WHERE
      ORDER BY log.date DESC;",
    undef, $attr
  );

  return $self->{list} || [];
}

#**********************************************************
=head2 storage_installation_add($attr) Storage installation add

=cut
#**********************************************************
sub storage_installation_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('storage_installation', { %{$attr},
    AID                          => $admin->{AID},
    STORAGE_INCOMING_ARTICLES_ID => $attr->{MAIN_ARTICLE_ID},
    SUM                          => (($attr->{SUM_TOTAL} / $attr->{COUNT_INCOMING}) * $attr->{COUNT}),
    ID                           => undef,
  });

  my %UPDATE = (
    ID    => $attr->{MAIN_ARTICLE_ID},
    COUNT => (($attr->{COUNT_INCOMING} - $attr->{COUNT}) == 0) ? 'NULL' : $attr->{COUNT_INCOMING} - $attr->{COUNT},
    SUM   => (($attr->{COUNT_INCOMING} - $attr->{COUNT}) == 0) ? 'NULL' : $attr->{SUM_TOTAL} - (($attr->{SUM_TOTAL} / $attr->{COUNT_INCOMING}) * $attr->{COUNT})
  );

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'storage_incoming_articles',
    DATA         => \%UPDATE,
  });

  $self->storage_log_add({ %{$attr}, STORAGE_MAIN_ID => $attr->{MAIN_ARTICLE_ID}, ACTION => 11 }) if (!$self->{errno});

  return 0;
}

#**********************************************************
=head2 storage_installation_info($attr) - Storage installation info for hardware

=cut
#**********************************************************
sub storage_installation_info {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;

  my $WHERE = $self->search_former($attr, [
      [ 'ID',         'INT', 'i.id', ],
      [ 'STATUS',     'INT', 'i.type', ],
      [ 'DISTRICT',   'INT', 'd.id', ],
      [ 'STREET',     'INT', 'str.id', ],
      [ 'AID',        'INT', 'i.aid', ],
      [ 'SIA',        'INT', 'sia.article_id' ],
      [ 'UID',        'INT', 'i.uid', ],
      [ 'SELL_PRICE', 'INT', 'i.sell_price', ],
      [ 'IP',         'IP',  'INET_NTOA(internet.ip) AS ip',  1 ]
    ],
    {
      WHERE             => 1,
      USERS_FIELDS      => 1,
      USE_USER_PI       => 1,
      SKIP_USERS_FIELDS => [ 'UID' ]
    }
  );

  my $EXT_TABLES = $self->{EXT_TABLES};

  if($attr->{INTERNET}) {
    $EXT_TABLES .= "         LEFT JOIN internet_main internet ON ( internet.uid = i.uid )";
  }

  $self->query("SELECT  i.id,
                i.storage_incoming_articles_id,
                i.aid,
                i.uid,
                i.nas_id,
                i.count,
                i.comments,
                i.actual_sell_price,
                adm.name AS admin_name,
                sat.id AS article_type_id,
                sta.name AS sta_name,
                i.count * (sia.sum / sia.count) AS total_sum,
                sta.measure,
                nas.name AS nas_name,
                i.sum,
                u.id AS login,
                i.mac,
                i.grounds,
                i.date,
                sn.serial,
                i.type,
                i.mac,
                $self->{SEARCH_FIELDS}
                sia.article_id,
                sat.name AS sat_name,
                i.monthes,
                i.amount_per_month,
                i.installed_aid
                FROM storage_installation AS i
              LEFT JOIN admins adm ON ( adm.aid = i.aid )
              LEFT JOIN storage_incoming_articles sia ON ( sia.id = i.storage_incoming_articles_id )
              LEFT JOIN storage_articles sta ON ( sta.id = sia.article_id )
              LEFT JOIN storage_article_types sat ON ( sat.id = sta.article_type )
              LEFT JOIN nas nas ON ( nas.id = i.nas_id )
              LEFT JOIN builds install_b ON ( install_b.id = i.location_id )
              LEFT JOIN users u ON ( u.uid = i.uid )
              LEFT JOIN storage_sn sn ON ( i.id = sn.storage_installation_id )
              $EXT_TABLES
                $WHERE
                ORDER BY $SORT DESC;",
    undef, { INFO => 1 }
  );

  return $self;
}

#**********************************************************
# Storage get serial
#**********************************************************

#sub storage_get_serial {
#  my $self = shift;
#  my ($attr) = @_;
#
#  my @WHERE_RULES  = ();
#
#  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
#  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
#
#  my $ext_fields = '';
#  my $EXT_TABLES = '';
#
#  if(defined($attr->{AID}) and $attr->{AID} != 0) {
#      push @WHERE_RULES, "sr.aid='$attr->{AID}'";
#  }
#
#  $self->query($db, "SELECT  serial
#                FROM storage_sn sn
#                ");
#
#}

#**********************************************************
=head2 storage_installation_return($attr) Storage installation return

=cut
#**********************************************************
sub storage_installation_return {
  my $self = shift;
  my ($attr) = @_;

  my %UPDATE = (
    ID    => $attr->{MAIN_ARTICLE_ID},
    COUNT => $attr->{COUNT_INCOMING} + $attr->{COUNT},
    SUM   => $attr->{SUM_TOTAL} + $attr->{SUM},
  );

  #my %info = $self->storage_incoming_articles_info( { ID => $attr->{MAIN_ARTICLE_ID} } );

  $self->changes({ CHANGE_PARAM => 'ID', TABLE => 'storage_incoming_articles', DATA => \%UPDATE });

  my @WHERE_RULES = ();
  my $WHERE = '';

  push @WHERE_RULES, " id='$attr->{ID_INSTALLATION}' "  if defined($attr->{ID_INSTALLATION});

  if ($#WHERE_RULES > - 1) {
    $WHERE = join(' AND ', @WHERE_RULES);
    $self->query("DELETE from storage_installation WHERE $WHERE;", 'do');
  }

  if (!$self->{errno}) {
    $self->storage_log_add({
      %{$attr},
      STORAGE_MAIN_ID         => $attr->{MAIN_ARTICLE_ID},
      ACTION                  => 6,
      STORAGE_INSTALLATION_ID => $attr->{ID_INSTALLATION},
      COMMENTS                => $attr->{COMMENTS},
    });
  }

  return 0;
}

#**********************************************************
=head2 storage_reserve_add($attr) - Storage reserve add

=cut
#**********************************************************
sub storage_reserve_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('storage_reserve', {
    %{$attr},
    DATE => 'NOW()',
    AID  => $admin->{AID},
    ID   => undef
  });

  if (!$self->{errno}) {
    $self->storage_log_add({ %{$attr}, STORAGE_MAIN_ID => $attr->{STORAGE_INCOMING_ARTICLES_ID}, ACTION => 5 });
  }

  return 0;
}

#**********************************************************
=head2 storage_reserve_list($attr) - Storage reserve list

=cut
#**********************************************************
sub storage_reserve_list {
  my $self = shift;
  my ($attr) = @_;

  my @WHERE_RULES = ();

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  if (defined($attr->{AID}) and $attr->{AID} != 0) {
    push @WHERE_RULES, "sr.aid='$attr->{AID}'";
  }

  $attr->{DOMAIN_ID} ||= $admin->{DOMAIN_ID} || '_SHOW';

  my $WHERE = $self->search_former($attr, [
      [ 'AID',                           'INT',  'sr.aid',                                     1 ],
      [ 'COUNT',                         'INT',  'sr.count',                                   1 ],
      [ 'ADMIN_NAME',                    'STR',  'adm.name as admin_name',                     1 ],
      [ 'DATE',                          'STR',  'sr.date',                                    1 ],
      [ 'STORAGE_INCOMING_ARTICLES_ID',  'STR',  'sr.storage_incoming_articles_id',            1 ],
      [ 'COMMENTS',                      'STR',  'sr.comments',                                1 ],
      [ 'ARTICLE_NAME',                  'STR',  'sta.name AS article_name',                   1 ],
      [ 'TYPE_NAME',                     'STR',  'sat.name AS type_name',                      1 ],
      [ 'SR_SUM',                        'INT',  'sr.count * (sia.sum / sia.count) AS sr_sum', 1 ],
      [ 'SERIAL',                        'INT',  'sn.serial',                                  1 ],
      [ 'MEASURE',                       'INT',  'sta.measure',                                1 ],
      [ 'ID',                            'INT',  'sr.id',                                      1 ],
      [ 'ADDED_BY_ADMIN_NAME',           'STR',  'add_adm.name as added_by_admin_name',        1 ],
      [ 'ARTICLE_TYPE_ID',               'INT',  'sat.id as article_type_id',                  1 ],
      [ 'ARTICLE_ID',                    'INT',  'sta.id as article_id',                       1 ],
      ['FROM_DATE|TO_DATE',              'DATE', "DATE_FORMAT(sr.date, '%Y-%m-%d')",           1 ],
      [ 'DOMAIN_ID',                     'INT',  'si.domain_id',                               1 ]
    ],
    {
      WHERE => 1,
    }
  );

  $self->query("SELECT  $self->{SEARCH_FIELDS} sr.id
     FROM storage_reserve AS sr
   LEFT JOIN admins adm ON ( adm.aid = sr.aid )
   LEFT JOIN storage_incoming_articles sia ON ( sia.id = sr.storage_incoming_articles_id )
   LEFT JOIN storage_articles sta ON ( sta.id = sia.article_id )
   LEFT JOIN storage_article_types sat ON ( sat.id = sta.article_type )
   LEFT JOIN storage_sn sn ON (sn.id=sia.sn)
   LEFT JOIN storage_incoming si ON (si.id = sia.storage_incoming_id)
   $WHERE
   ORDER BY $SORT $DESC;",
    undef,
    $attr
  );

  return $self->{list};
}

#**********************************************************
#  Storage reserve del
#**********************************************************
sub storage_reserve_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('storage_reserve', $attr);

  return $self->{result};
}

#**********************************************************
# Storage orders list
#**********************************************************
sub storage_orders_list {
  my $self = shift;
  my ($attr) = @_;

  my @WHERE_RULES = ();

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;

  if (defined($attr->{ID}) and $attr->{ID} != 0) {
    push @WHERE_RULES, "so.id='$attr->{ID}'";
  }

  my $WHERE = ($#WHERE_RULES > - 1) ? "WHERE " . join(' AND ', @WHERE_RULES) : '';

  $self->query("SELECT  so.id,
                so.count,
                so.comments,
                sta.name,
                sta.measure,
                sat.name
                FROM storage_orders AS so
              LEFT JOIN storage_articles sta ON ( sta.id = so.id_storage_articles )
              LEFT JOIN storage_article_types sat ON ( sat.id = sta.article_type )
                $WHERE
                ORDER BY $SORT DESC;",
    undef, $attr
  );

  return $self->{list};
}

#**********************************************************
# Storage orders info
#**********************************************************
sub storage_orders_info {
  my $self = shift;
  my ($attr) = @_;

  $self->query("SELECT   so.id,
         so.id_storage_articles,
         so.count,
         so.comments,
         sta.id,
         sat.id
       FROM storage_orders so
       LEFT JOIN storage_articles sta ON ( sta.id = so.id_storage_articles )
       LEFT JOIN storage_article_types sat ON ( sat.id = sta.article_type )
       WHERE so.id= ? ;",
    undef,
    {
      INFO => 1,
      Bind => [ $attr->{ID} ]
    }
  );

  return $self;
}

#**********************************************************
=head2 storage_orders_add($attr) Storage orders add

=cut
#**********************************************************
sub storage_orders_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('storage_orders', $attr);

  return 0;
}

#**********************************************************
# Change storage orders
#**********************************************************
sub storage_orders_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'storage_orders',
    DATA         => $attr,
  });
  return $self;
}

#**********************************************************
# Del storage articles
#**********************************************************
sub storage_orders_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('storage_orders', $attr);

  return $self->{result};
}

#**********************************************************
=head2 storage_installation_user_add($attr) - Storage installation user add

=cut
#**********************************************************
sub storage_installation_user_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('storage_installation', {
    %{$attr},
    AID                          => $admin->{AID},
    STORAGE_INCOMING_ARTICLES_ID => $attr->{MAIN_ARTICLE_ID},
    SUM                          => (($attr->{SUM_TOTAL} / $attr->{COUNT_INCOMING}) * $attr->{COUNT}),
    TYPE                         => $attr->{STATUS},
    DATE                         => 'NOW()',
    ID                           => undef
  });

  return $self if ($self->{errno});

  my $storage_installation_id = $self->{INSERT_ID};

  my %UPDATE = (
    ID    => $attr->{MAIN_ARTICLE_ID},
    COUNT => (($attr->{COUNT_INCOMING} - $attr->{COUNT}) == 0) ? 'NULL' : $attr->{COUNT_INCOMING} - $attr->{COUNT},
    SUM   =>
      (($attr->{COUNT_INCOMING} - $attr->{COUNT}) == 0) ? 'NULL' : $attr->{SUM_TOTAL} - (($attr->{SUM_TOTAL} / $attr->{COUNT_INCOMING}) * $attr->{COUNT})
    ,
  );

  my %FIELDS = (
    ID    => 'id',
    COUNT => 'count',
    SUM   => 'sum',
  );

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'storage_incoming_articles',
    FIELDS       => \%FIELDS,
    OLD_INFO     => $self->storage_incoming_articles_info({ ID => $attr->{MAIN_ARTICLE_ID} }),
    DATA         => \%UPDATE,
  });

  return $self if ($self->{errno});

  $self->query_add('storage_sn', {
    %{$attr},
    STORAGE_INSTALLATION_ID => $storage_installation_id,
    ID                      => undef
  });

  if (!$self->{errno}) {
    $self->storage_incoming_articles_return({
      ID => $attr->{STORAGE_INCOMING_ARTICLES_ID},
      SN => $self->{INSERT_ID},
    });

    $self->storage_log_add({
      %{$attr},
      STORAGE_MAIN_ID         => $attr->{MAIN_ARTICLE_ID},
      ACTION                  => $attr->{ACTION} || 11,
      STORAGE_INSTALLATION_ID => $storage_installation_id
    });
  }

  $self->{INSTALLATION_ID} = $storage_installation_id;

  return 0;
}

#**********************************************************
=head2 storage_installation_change($attr) Change storage articles

=cut
#**********************************************************
sub storage_installation_change {
  my $self = shift;
  my ($attr) = @_;

  $self->storage_installation_info({ ID => $attr->{ID} });
  return $self if ($self->{TOTAL} && $self->{TYPE} && $self->{TYPE} eq '4');

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'storage_installation',
    DATA         => $attr,
  });

  $attr->{STORAGE_INSTALLATION_ID} = $attr->{ID};
  delete $attr->{ID};
  $self->changes({
    CHANGE_PARAM => 'STORAGE_INSTALLATION_ID',
    TABLE        => 'storage_sn',
    DATA         => $attr,
  });

  if ($self->{errno} && $self->{errno} eq "4") {
    my $installation_info = $self->storage_installation_info({ ID => $attr->{STORAGE_INSTALLATION_ID} });
    if ($self->{TOTAL}) {
      $self->query_add('storage_sn', {
        %{$attr},
        STORAGE_INSTALLATION_ID      => $attr->{STORAGE_INSTALLATION_ID},
        STORAGE_INCOMING_ARTICLES_ID => $installation_info->{STORAGE_INCOMING_ARTICLES_ID},
        ID                           => undef
      });

      if (!$self->{errno} && $self->{INSERT_ID}) {
        my $attr_sia;
        $attr_sia->{ID} = $installation_info->{STORAGE_INCOMING_ARTICLES_ID};
        $attr_sia->{SN} = $self->{INSERT_ID};

        $self->changes({
          CHANGE_PARAM => 'ID',
          TABLE        => 'storage_incoming_articles',
          DATA         => $attr_sia,
        });
      }
    }
  }

  if (!$self->{errno}) {
    $self->storage_log_add({
      %{$attr},
      STORAGE_MAIN_ID         => $attr->{ARTICLE_ID1},
      ACTION                  => 8,
      STORAGE_INSTALLATION_ID => $attr->{STORAGE_INSTALLATION_ID},
      COUNT                   => $attr->{COUNT1},
    });
  }

  return $self;
}

#**********************************************************
=head2 storage_rent_fees($attr) Storage rent fees

=cut
#**********************************************************
sub storage_rent_fees {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $date = $attr->{DATE} || '';

  $self->query("SELECT  i.id,
                i.uid,
                sia.*,
                i.count,
                IF(u.company_id > 0, cb.id, u.bill_id) AS bill_id,
                sa.name AS article_name,
                i.storage_incoming_articles_id,
                i.aid,
                adm.name AS admin_name,
                i.type
                FROM storage_installation AS i
              LEFT JOIN admins adm ON ( adm.aid = i.aid )
              LEFT JOIN storage_incoming_articles sia ON ( sia.id = i.storage_incoming_articles_id )
              LEFT JOIN users u ON ( u.uid = i.uid )
                LEFT JOIN companies company ON (u.company_id=company.id)
                LEFT JOIN bills b ON (u.bill_id = b.id)
                LEFT JOIN bills cb ON (company.bill_id=cb.id)
              LEFT JOIN storage_articles sa ON (sa.id = sia.article_id)
                WHERE i.type=2 and i.uid != 0 and sia.rent_price != 0 AND i.date < '$date'
                ORDER BY $SORT DESC;",
    undef, $attr
  );

  return $self->{list};
}

#**********************************************************
=head2 storage_rent_fees($attr) Storage rent fees

=cut
#**********************************************************
sub storage_by_installments_fees {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $date = $attr->{DATE};

  $self->query("SELECT  i.id,
                i.uid,
                sia.rent_price,
                i.count,
                i.monthes,
                i.amount_per_month,
                IF(u.company_id > 0, cb.id, u.bill_id) AS bill_id,
                sa.name AS article_name,
                i.storage_incoming_articles_id,
                i.aid,
                adm.name AS admin_name,
                i.type,
                sia.fees_method
                FROM storage_installation AS i
              LEFT JOIN admins adm ON ( adm.aid = i.aid )
              LEFT JOIN storage_incoming_articles sia ON ( sia.id = i.storage_incoming_articles_id )
              LEFT JOIN users u ON ( u.uid = i.uid )
                LEFT JOIN companies company ON (u.company_id=company.id)
                LEFT JOIN bills b ON (u.bill_id = b.id)
                LEFT JOIN bills cb ON (company.bill_id=cb.id)
              LEFT JOIN storage_articles sa ON (sa.id = sia.article_id)
                WHERE i.type=3 AND i.uid != 0 AND i.monthes != 0 AND i.date < '$date'
                ORDER BY $SORT DESC;",
    undef, $attr
  );

  return $self->{list};
}

#**********************************************************
=head2 storages_list($attr)

  Arguments:
    $attr - hash_ref
      ID   - id to list
      NAME - name for search

  Returns:
    arr_ref - DB_LIST

=cut
#**********************************************************
sub storages_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  $attr->{DOMAIN_ID} ||= $admin->{DOMAIN_ID} || '_SHOW';

  my $WHERE = $self->search_former($attr, [
      [ 'ID',         'INT', 'ss.id'                ],
      [ 'NAME',       'STR', 'ss.name'              ],
      [ 'DOMAIN_ID',  'INT', 'ss.domain_id',      1 ],
    ], { WHERE => 1 });

  $self->query("SELECT  ss.id, ss.name, ss.comments
                FROM storage_storages AS ss
                $WHERE
                ORDER BY $SORT $DESC;",
    undef, $attr
  );

  return $self->{list};
}

#**********************************************************
=head2 storages_names()

  Arguments:


  Returns:
    array of names for storages

=cut
#**********************************************************
sub storages_names {
  my $self = shift;

  my $list = $self->storages_list();
  my @result_list = (undef);

  foreach my $storage (@{$list}) {
    next if (!defined $storage || ref $storage ne 'ARRAY');

    push (@result_list, $storage->[1]);
  }

  return \@result_list;
}

#**********************************************************
=head2 storage_info($attr)

  Arguments:
    $attr
      ID  - id of storage you want get info for

  Returns:
    Storage object (modified caller)

=cut
#**********************************************************
sub storage_info {
  my $self = shift;
  my ($attr) = @_;

  $self->query("SELECT * FROM storage_storages WHERE id= ? ;", undef,{ INFO => 1, Bind => [ $attr->{ID} ] });

  return $self;
}

#**********************************************************
=head2 storage_add($attr)

  Arguments:
    $attr

  Returns:


=cut
#**********************************************************
sub storage_add {
  my $self = shift;

  my ($attr) = @_;

  $self->query_add('storage_storages', {%$attr, DOMAIN_ID => ($self->{admin}{DOMAIN_ID} || 0)});

  return 0;
}

#**********************************************************
=head2 storage_change($attr)

  Arguments:
    $attr - hash_ref with new values

  Returns:
    $Storage object

=cut
#**********************************************************
sub storage_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'storage_storages',
    DATA         => $attr,
  });

  return $self;
}

#**********************************************************
=head2 storage_del($attr)

  Arguments:
    $attr

  Returns:
    result?

=cut
#**********************************************************
sub storage_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('storage_storages', $attr);

  return $self->{result};
}

#**********************************************************
=head2 storage_inner_use_add()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub storage_inner_use_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query("INSERT INTO storage_inner_use (  storage_incoming_articles_id,
                     count, aid,  date, comments, sum, responsible )
                 VALUES ( ?, ?,  ?, NOW(), ?,  ?, ? );",
    'do',
    { Bind => [
        $attr->{ID},
        $attr->{COUNT},
        $admin->{AID},
        $attr->{COMMENTS},
        ($attr->{SUM_TOTAL} / $attr->{COUNT_INCOMING}) * $attr->{COUNT},
        $attr->{RESPONSIBLE},
      ] }
  );

  my %UPDATE = (
    ID    => $attr->{ID},
    COUNT => (($attr->{COUNT_INCOMING} - $attr->{COUNT}) == 0) ? 'NULL' : $attr->{COUNT_INCOMING} - $attr->{COUNT},
    SUM   =>
      (($attr->{COUNT_INCOMING} - $attr->{COUNT}) == 0) ? 'NULL' : $attr->{SUM_TOTAL} - (($attr->{SUM_TOTAL} / $attr->{COUNT_INCOMING}) * $attr->{COUNT})
    ,
  );

  #my %info = $self->storage_incoming_articles_info( { ID => $attr->{ID} } );

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'storage_incoming_articles',
    DATA         => \%UPDATE,
  });

  if (!$self->{errno}) {
    $self->storage_log_add({ %{$attr}, STORAGE_MAIN_ID => $attr->{MAIN_ARTICLE_ID}, ACTION => 14 });
  }

  return $self;
}


#**********************************************************
=head2 storage_inner_use_list($attr) -  Storage storage incoming articles list

=cut
#**********************************************************
sub storage_inner_use_list {
  my $self = shift;
  my ($attr) = @_;

  my @WHERE_RULES = ();

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  $attr->{DOMAIN_ID} ||= $admin->{DOMAIN_ID} || '_SHOW';

  my $WHERE = $self->search_former($attr, [
      [ 'RESPONSIBLE_NAME', 'STR',  'adm_responsible.name as responsible_name',   1 ],
      [ 'SAT_NAME',         'STR', 'sat.name AS sat_name',   1 ],
      [ 'STA_NAME',         'STR', 'sta.name AS sta_name',   1 ],
      [ 'COUNT',            'INT', 'siu.count',              1 ],
      [ 'DATE',             'DATE', 'siu.date',              1 ],
      [ 'SUM',              'INT', ' siu.sum',               1 ],
      [ 'COMMENTS',         'STR', 'siu.comments',           1 ],
      [ 'SERIAL',           'STR', 'sn.serial',              1 ],
      [ 'ID',               'INT', 'siu.id',                 1 ],
      [ 'STORAGE_INCOMING_ARTICLES_ID', 'INT', 'siu.storage_incoming_articles_id',  1 ],
      [ 'AID',                          'INT', 'siu.aid',                           1 ],
      [ 'DISCARD_SUM',                  'INT', 'siu.count * (sia.sum / sia.count) AS discard_sum', 1 ],
      [ 'MEASURE',                      'INT', 'sta.measure',                                      1 ],
      [ 'MEASURE_NAME',                 'STR', 'sm.name as measure_name',                          1 ],
      [ 'ARTICLE_TYPE_ID',              'INT', 'sat.id as article_type_id',                  1 ],
      [ 'ARTICLE_ID',                   'INT', 'sta.id as article_id',                       1 ],
      ['FROM_DATE|TO_DATE',             'DATE', "DATE_FORMAT(siu.date, '%Y-%m-%d')",         1 ],
      [ 'ADMIN_NAME',                   'STR',  'adm.name as admin_name',                    1 ],
      [ 'RESPONSIBLE',                  'INT',  'siu.responsible',                           1 ],
      [ 'DOMAIN_ID',                    'INT',  'si.domain_id',                                ],
    ],
    {
      WHERE             => 1,
      WHERE_RULES       => \@WHERE_RULES,
      #USERS_FIELDS=> 1,
      SKIP_USERS_FIELDS => [ 'FIO' ]
    }
  );

  $self->query("SELECT $self->{SEARCH_FIELDS}
                siu.id
                FROM storage_inner_use AS siu
  LEFT JOIN admins adm ON ( adm.aid = siu.aid )
  LEFT JOIN storage_incoming_articles sia ON ( sia.id = siu.storage_incoming_articles_id )
  LEFT JOIN storage_articles sta ON ( sta.id = sia.article_id )
  LEFT JOIN storage_article_types sat ON ( sat.id = sta.article_type )
  LEFT JOIN storage_sn sn ON ( sn.id = sia.sn )
  LEFT JOIN storage_measure sm ON (sm.id = sta.measure)
  LEFT JOIN admins adm_responsible ON ( adm_responsible.aid = siu.responsible )
  LEFT JOIN storage_incoming si ON (si.id = sia.storage_incoming_id)
                $WHERE
                ORDER BY $SORT $DESC;",
    undef,
    $attr
  );

  my $list = $self->{list};

  $self->query("SELECT COUNT(*) AS total FROM storage_inner_use AS siu
  LEFT JOIN admins adm ON ( adm.aid = siu.aid )
  LEFT JOIN storage_incoming_articles sia ON ( sia.id = siu.storage_incoming_articles_id )
  LEFT JOIN storage_articles sta ON ( sta.id = sia.article_id )
  LEFT JOIN storage_article_types sat ON ( sat.id = sta.article_type )
  LEFT JOIN storage_sn sn ON ( sn.storage_incoming_articles_id = siu.storage_incoming_articles_id )
  LEFT JOIN storage_incoming si ON (si.id = sia.storage_incoming_id)
    $WHERE
    ;",
    undef,
    { INFO => 1 }
  );

  return $list;
}
#**********************************************************
=head2 storage_inner_use_list($attr) Storage discard list

=cut
#**********************************************************
sub storage_inner_use_list2 {
  my $self = shift;
  my ($attr) = @_;

  my @WHERE_RULES = ();

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  if (defined($attr->{AID})) {
    push @WHERE_RULES, "sa.aid='$attr->{AID}'";
  }

  my $WHERE = ($#WHERE_RULES > - 1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

  $self->query("SELECT
    adm.name AS admin_name,
    sat.name AS sat_name,
    sta.name AS sta_name,
    siu.count,
    siu.sum,
    siu.date,
    siu.comments,
    sn.serial,
    siu.id,
    siu.storage_incoming_articles_id,
    siu.aid,
    siu.count * (sia.sum / sia.count) AS discard_sum,
    sta.measure
  FROM storage_inner_use AS siu
  LEFT JOIN admins adm ON ( adm.aid = siu.aid )
  LEFT JOIN storage_incoming_articles sia ON ( sia.id = siu.storage_incoming_articles_id )
  LEFT JOIN storage_articles sta ON ( sta.id = sia.article_id )
  LEFT JOIN storage_article_types sat ON ( sat.id = sta.article_type )
  LEFT JOIN storage_sn sn ON ( sn.storage_incoming_articles_id = siu.storage_incoming_articles_id )
  $WHERE
  ORDER BY $SORT $DESC;",
    undef, $attr
  );

  return $self->{list};
}

#**********************************************************
=head2 storage_discard_del()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub storage_inner_use_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('storage_inner_use', $attr);

  $self->storage_log_add({ %{$attr},
    ACTION     => 10,
    STORAGE_MAIN_ID => $attr->{STORAGE_INCOMING_ARTICLES_ID},
    COMMENTS   => 'ID: ' . $attr->{ID} . " STORAGE_MAIN_ID: " . $attr->{STORAGE_INCOMING_ARTICLES_ID} . ' ' . $attr->{COMMENTS}
  });

  return $self;
}


#**********************************************************
=head2 storage_sn_list($attr) Storage discard list

=cut
#**********************************************************
sub storage_sn_list {
  my $self = shift;
  my ($attr) = @_;

  my @WHERE_RULES = ();

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;

  if (defined($attr->{SERIAL})) {
    push @WHERE_RULES, "ssn.serial='$attr->{SERIAL}'";
  }
  elsif(defined($attr->{ID})){
    push @WHERE_RULES, "ssn.id='$attr->{ID}'";
  }
  elsif(defined($attr->{INCOMING_ARTICLES_ID})){
    push @WHERE_RULES, "ssn.storage_incoming_articles_id='$attr->{INCOMING_ARTICLES_ID}'";
  }

  my $WHERE = ($#WHERE_RULES > - 1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

  $self->query("SELECT ssn.id,
    ssn.storage_incoming_articles_id,
    ssn.storage_installation_id,
    ssn.serial,
    ssn.qrcode_hash,
    ssn.sn_comments
  FROM storage_sn AS ssn
  $WHERE
  ORDER BY $SORT DESC;",
    undef, $attr
  );

  return $self->{list};
}

#**********************************************************
=head2 storage_measure_dad() - add new measure

  Arguments:
     NAME   - name of the measure

  Returns:
    $self

  Examples:

=cut
#**********************************************************
sub storage_measure_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('storage_measure', { %$attr });

  return $self;
}

#*******************************************************************
=head2 storage_measure_change() - change measure

  Arguments:
    $attr

  Returns:
    $self object

  Examples:
    $Crm->crm_action_change({
      ID     => 1,
      NAME   => 'METER'
    });


=cut

#*******************************************************************
sub storage_measure_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'storage_measure',
    DATA         => $attr
  });

  return $self;
}

#*******************************************************************

=head2  storage_measure_delete() - delete measure

  Arguments:
    $attr

  Returns:

  Examples:
    $Storage->storage_measure_delete( {ID => 1} );

=cut

#*******************************************************************
sub storage_measure_delete {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('storage_measure', $attr);

  return $self;
}

#**********************************************************
=head2 storage_measure_list() - return list of measures

  Arguments:
    ATTRIBUTES -
  Returns:

  Examples:

=cut
#**********************************************************
sub storage_measure_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT        = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC        = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG          = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS   = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $WHERE = $self->search_former(
    $attr,
    [
      [ 'ID',       'INT', 'sm.id', 1 ],
      [ 'NAME',     'STR', 'sm.name', 1 ],
      [ 'COMMENTS', 'STR', 'sm.comments', 1 ],
    ],
    { WHERE => 1, }
  );

  $self->query(
    "SELECT
    $self->{SEARCH_FIELDS}
    sm.id
    FROM storage_measure as sm
    $WHERE
    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list};

  return $self->{list} if ($self->{TOTAL} < 1);

  $self->query(
    "SELECT COUNT(*) AS total
   FROM storage_measure",
    undef,
    { INFO => 1 }
  );

  return $list || [];
}

#**********************************************************
=head2 storage_measure_info()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub storage_measure_info {
  my $self = shift;
  my ($attr) = @_;

  my $measure_info = $self->storage_measure_list({ %$attr });

  if ($measure_info && ref $measure_info eq 'ARRAY' && scalar @{$measure_info} == 1) {
    return $measure_info->[0];
  }
  else {
    return ();
  }
}

#**********************************************************
=head2 storage_property_add() - add new propert

  Arguments:
     NAME   - name of the property

  Returns:
    $self

  Examples:

=cut
#**********************************************************
sub storage_property_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('storage_property', { %$attr, DOMAIN_ID => $self->{admin}{DOMAIN_ID} || 0 });

  return $self;
}

#*******************************************************************
=head2 storage_property_change() - change property

  Arguments:
    $attr

  Returns:
    $self object

  Examples:
    $Storage->crm_property_change({
      ID     => 1,
      NAME   => 'property 1'
    });


=cut
#*******************************************************************
sub storage_property_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'storage_property',
    DATA         => $attr
  });

  return $self;
}

#*******************************************************************
=head2  storage_property_delete() - delete property

  Arguments:
    $attr

  Returns:

  Examples:
    $Storage->storage_property_delete( {ID => 1} );

=cut
#*******************************************************************
sub storage_property_delete {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('storage_property', $attr);

  return $self;
}

#**********************************************************
=head2 storage_property_list() - return list of propertys

  Arguments:
    ATTRIBUTES -
  Returns:

  Examples:

=cut
#**********************************************************
sub storage_property_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  $attr->{DOMAIN_ID} ||= $admin->{DOMAIN_ID} || '_SHOW';

  my $WHERE = $self->search_former(
    $attr,
    [
      [ 'ID',         'INT', 'sp.id',        1 ],
      [ 'NAME',       'STR', 'sp.name',      1 ],
      [ 'COMMENTS',   'STR', 'sp.comments',  1 ],
      [ 'DOMAIN_ID',  'INT', 'sp.domain_id', 1 ],
    ],
    { WHERE => 1 }
  );

  $self->query(
    "SELECT
    $self->{SEARCH_FIELDS}
    sp.id
    FROM storage_property as sp
    $WHERE
    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list};

  return $self->{list} if ($self->{TOTAL} < 1);

  $self->query(
    "SELECT COUNT(*) AS total
   FROM storage_property",
    undef,
    { INFO => 1 }
  );

  return $list || [];
}

#**********************************************************
=head2 storage_property_info()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub storage_property_info {
  my $self = shift;
  my ($attr) = @_;

  my $property_info = $self->storage_property_list({ %$attr });

  if ($property_info && ref $property_info eq 'ARRAY' && scalar @{$property_info} == 1) {
    return $property_info->[0];
  }
  else {
    return ();
  }
}

#**********************************************************
=head2 storage_property_add() - add new propert

  Arguments:
     NAME   - name of the property

  Returns:
    $self

  Examples:

=cut
#**********************************************************
sub storage_property_value_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('storage_articles_property', { %$attr });

  return $self;
}

#*******************************************************************
=head2 storage_property_change() - change property

  Arguments:
    $attr

  Returns:
    $self object

  Examples:
    $Storage->crm_property_change({
      ID     => 1,
      NAME   => 'property 1'
    });


=cut

#*******************************************************************
sub storage_property_value_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'storage_articles_property',
    DATA         => $attr
  });

  return $self;
}

#*******************************************************************

=head2  storage_property_value_delete() - delete property

  Arguments:
    $attr

  Returns:

  Examples:
    $Storage->storage_property_delete( {ID => 1} );

=cut

#*******************************************************************
sub storage_property_value_delete {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('storage_articles_property', {}, {storage_incoming_articles_id => $attr->{STORAGE_INCOMING_ARTICLES_ID}});

  return $self;
}

#**********************************************************
=head2 storage_property_list() - return list of propertys

  Arguments:
    ATTRIBUTES -
  Returns:

  Examples:

=cut
#**********************************************************
sub storage_property_value_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $WHERE = $self->search_former(
    $attr,
    [
      [ 'ID',                          'INT', 'sap.id', 1 ],
      [ 'STORAGE_INCOMING_ARTICLES_ID','INT', 'sap.storage_incoming_articles_id', 1],
      [ 'PROPERTY_ID',                 'INT', 'sap.property_id', 1],
      [ 'VALUE',                       'STR', 'sap.value', 1],
    ],
    { WHERE => 1, }
  );

  $self->query(
    "SELECT
    $self->{SEARCH_FIELDS}
    sap.id
    FROM storage_articles_property as sap
    $WHERE
    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list};

  return $self->{list} if ($self->{TOTAL} < 1);

  $self->query(
    "SELECT COUNT(*) AS total
   FROM storage_articles_property",
    undef,
    { INFO => 1 }
  );

  return $list || [];
}

#**********************************************************
=head2 storage_property_info()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub storage_property_value_info {
  my $self = shift;
  my ($attr) = @_;

  my $property_value_info = $self->storage_property_value_list({ %$attr });

  if ($property_value_info && ref $property_value_info eq 'ARRAY' && scalar @{$property_value_info} == 1) {
    return $property_value_info->[0];
  }
  else {
    return ();
  }
}

#**********************************************************
=head2 storage_incoming_articles_info($attr) - Storage incoming articles info

=cut
#**********************************************************
sub storage_print_info {
  my $self = shift;
  my ($attr) = @_;

  my $prop_list = $self->storage_property_list({ COLS_NAME => 1 });

  my $select = '';
  my $joins  = '';

  foreach my  $prop (@$prop_list) {
    $select .= "sap_$prop->{id}.value as PROPERTY_$prop->{id}, ";
    $joins .= "LEFT JOIN storage_articles_property sap_$prop->{id} ON ( sap_$prop->{id}.storage_incoming_articles_id = sa.storage_incoming_articles_id
    AND sap_$prop->{id}.property_id = $prop->{id} ) ";
  }

  my $search_columns = [
    [ 'ID',                    'INT',  'sa.id',                           1 ],
    [ 'INCOMING_ARTICLES_ID',  'INT',  'sa.storage_incoming_articles_id', 1 ],
    [ 'COUNT',                 'INT',  'sa.count',                        1 ],
    [ 'DATE',                  'DATE', 'sa.date',                         1 ],
    [ 'COMMENTS',              'STR',  'sa.comments',                     1 ],
    [ 'ARTICLE_ID',            'INT',  'sia.article_id',                  1 ],
    [ 'SELL_PRICE',            'INT',  'sia.sell_price',                  1 ],
    [ 'RENT_PRICE',            'INT',  'sia.rent_price',                  1 ],
    [ 'IN_INSTALLMENTS_PRICE', 'INT',  'sia.in_installments_price',       1 ],
    [ 'STORAGE_INCOMING_ID',   'INT',  'sia.storage_incoming_id',         1 ],
    [ 'ARTICLE_NAME',          'STR',  'sart.name as article_name',       1 ],
    [ 'ARTICLE_TYPE',          'STR',  'sartt.name as article_type',      1 ],
    [ 'MEASURE_NAME',          'STR',  'sm.name as measure_name',         1 ],
    [ 'SERIAL',                'STR',  'ss.serial as serial',             1 ],
    [ 'STORAGE_ID',            'ID',   'si.storage_id as storage_id',     1 ],
    [ 'STORAGE_NAME',          'STR',  'sstor.name as storage_name',      1 ],
    [ 'ADMIN_NAME',            'STR',  'a.name as ADMIN_NAME',            1 ],
    [ 'TOTAL_SUM',             'INT',  'sia.sell_price * sa.count as TOTAL_SUM', 1 ],
  ];


  if ($attr->{SHOW_ALL_COLUMNS}) {
    map { $attr->{ $_->[0] } = '_SHOW' unless (exists $attr->{ $_->[0] }) } @{$search_columns};
  }

  my $WHERE = $self->search_former($attr, $search_columns, { WHERE => 1 });

  $self->query("SELECT
          $self->{SEARCH_FIELDS}
          $select
          sa.id
          FROM $attr->{TABLE_NAME} sa
          LEFT JOIN storage_incoming_articles sia ON (sia.id = sa.storage_incoming_articles_id)
          LEFT JOIN storage_articles sart ON (sart.id = sia.article_id)
          LEFT JOIN storage_article_types sartt ON (sartt.id = sart.article_type)
          LEFT JOIN storage_measure sm ON (sm.id = sart.measure)
          LEFT JOIN storage_sn ss ON (ss.id = sia.sn)
          LEFT JOIN storage_incoming si ON (si.id = sia.storage_incoming_id)
          LEFT JOIN storage_storages sstor ON (sstor.id = si.storage_id)
          LEFT JOIN admins a ON (a.aid = sa.aid)
          $joins
            $WHERE;",
    undef,
    { INFO => 1 }
  );

  return $self;
}

#**********************************************************
=head2 storage_incoming_articles_info($attr) - Storage incoming articles info

=cut
#**********************************************************
sub storage_print_incoming_info {
  my $self = shift;
  my ($attr) = @_;

  my $prop_list = $self->storage_property_list({
    COLS_NAME => 1,
  });

  my $select = '';
  my $joins  = '';

  foreach my  $prop (@$prop_list) {
    $select .= "sap_$prop->{id}.value as PROPERTY_$prop->{id}, ";
    $joins .= "LEFT JOIN storage_articles_property sap_$prop->{id} ON ( sap_$prop->{id}.storage_incoming_articles_id = sia.id
    AND sap_$prop->{id}.property_id = $prop->{id} ) ";
  }

  my $search_columns = [
    [ 'ID',                    'INT',  'sia.id',                           1 ],
    [ 'COUNT',                 'INT',  'sia.count',                        1 ],
    [ 'DATE',                  'DATE', 'si.date',                         1 ],
    [ 'COMMENTS',              'STR',  'si.comments',                     1 ],
    [ 'ARTICLE_ID',            'INT',  'sia.article_id',                  1 ],
    [ 'SELL_PRICE',            'INT',  'sia.sell_price',                  1 ],
    [ 'RENT_PRICE',            'INT',  'sia.rent_price',                  1 ],
    [ 'IN_INSTALLMENTS_PRICE', 'INT',  'sia.in_installments_price',       1 ],
    [ 'STORAGE_INCOMING_ID',   'INT',  'sia.storage_incoming_id',         1 ],
    [ 'ARTICLE_NAME',          'STR',  'sart.name as article_name',       1 ],
    [ 'ARTICLE_TYPE',          'STR',  'sartt.name as article_type',      1 ],
    [ 'MEASURE_NAME',          'STR',  'sm.name as measure_name',         1 ],
    [ 'SERIAL',                'STR',  'ss.serial as serial',             1 ],
    [ 'STORAGE_ID',            'ID',   'si.storage_id as storage_id',     1 ],
    [ 'INCOMING_DATE',         'STR',  'si.date as incoming_date',        1 ],
    [ 'STORAGE_NAME',          'STR',  'sstor.name as storage_name',      1 ],
    [ 'TOTAL_SUM',             'INT',  'sia.sell_price * sia.count as TOTAL_SUM', 1 ],
    [ 'INCOMING_SUM',          'INT',  'sia.sum as incoming_sum',          1 ],
    [ 'SUPPLIER_NAME',         'STR',  'sto_supp.name as SUPPLIER_NAME',   1 ],
    [ 'SUPPLIER_PHONE',        'STR',  'sto_supp.phone as SUPPLIER_PHONE', 1 ],
    [ 'SUPPLIER_MFO',          'STR',  'sto_supp.mfo as SUPPLIER_MFO',     1 ],
    [ 'SUPPLIER_OKPO',         'STR',  'sto_supp.okpo as SUPPLIER_OKPO',            1 ],
    [ 'SUPPLIER_BANK_NAME',    'STR',  'sto_supp.bank_name as SUPPLIER_BANK_NAME',  1 ],
    [ 'SUPPLIER_ACCOUNT',      'STR',  'sto_supp.account as SUPPLIER_ACCOUNT',      1 ],
    [ 'INVOICE_NUMBER',        'STR',  'si.invoice_number as invoice_number',                1 ],
  ];

  if ($attr->{SHOW_ALL_COLUMNS}) {
    map { $attr->{ $_->[0] } = '_SHOW' unless (exists $attr->{ $_->[0] }) } @{$search_columns};
  }

  my $WHERE = $self->search_former($attr, $search_columns, { WHERE => 1 });

  $self->query("SELECT
          $self->{SEARCH_FIELDS}
          $select
          sia.id
          FROM $attr->{TABLE_NAME} sia
          LEFT JOIN storage_articles sart ON (sart.id = sia.article_id)
          LEFT JOIN storage_article_types sartt ON (sartt.id = sart.article_type)
          LEFT JOIN storage_measure sm ON (sm.id = sart.measure)
          LEFT JOIN storage_sn ss ON (ss.id = sia.sn)
          LEFT JOIN storage_incoming si ON (si.id = sia.storage_incoming_id)
          LEFT JOIN storage_storages sstor ON (sstor.id = si.storage_id)
          LEFT JOIN storage_suppliers sto_supp ON (sto_supp.id = si.supplier_id)
          $joins
            $WHERE;",
    undef,
    { INFO => 1 }
  );

  return $self;
}

#**********************************************************
=head2 storage_incoming_articles_list2($attr) -  Storage storage incoming articles list

=cut
#**********************************************************
sub storage_incoming_articles_list2 {
  my $self = shift;
  my ($attr) = @_;

  my @WHERE_RULES = ();
  my $SORT = (defined $attr->{SORT}) ? $attr->{SORT} : 'si.date';
  my $DESC = (defined $attr->{DESC}) ? $attr->{DESC} : 'desc';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $EXT_TABLES = '';
  if (defined($attr->{HIDE_ZERO_VALUE})) {
    push @WHERE_RULES,
      "sia.count - (IF(ssub.count IS NULL, 0, (SELECT SUM(count) FROM storage_accountability WHERE storage_incoming_articles_id = sia.id GROUP BY storage_incoming_articles_id )) + if(sr.count IS NULL, 0, (SELECT SUM(count) FROM storage_reserve WHERE storage_incoming_articles_id = sia.id GROUP BY storage_incoming_articles_id )))";
  }

  if(defined($attr->{CONSIGNMENT}) && $attr->{CONSIGNMENT} ne ''){
    push @WHERE_RULES,
      "(sia.main_article_id='$attr->{CONSIGNMENT}' OR sia.id='$attr->{CONSIGNMENT}')";
  }

  my $WHERE = $self->search_former($attr, [
      [ 'ARTICLE_NAME',         'STR', 'sa.name AS article_name',        1 ],
      [ 'ARTICLE_TYPE_NAME',    'STR', 'sat.name AS article_type_name',  1 ],
      [ 'ARTICLE_TYPE_ID',      'INT', 'sat.id AS article_type_id',      1 ],
      [ 'SIA_COUNT',            'INT', 'sia.count as sia_count',         1 ],
      [ 'ARTICLE_PRICE',        'INT',  'sia.sum / sia.count AS article_price',   1 ],
      [ 'MAIN_ARTICLE_ID',      'INT', 'sia.main_article_id',            1 ],
      [ 'ARTICLE_ID',           'INT', 'sia.article_id',                 0 ],
      [ 'ARTICLE_TYPE',         'INT', 'sat.id as article_type',         1 ],
      [ 'DATE',                 'DATE', 'si.date',                       1 ],
      [ 'INVOICE_NAME',            'STR',  'si.invoice_number as invoice_name',         1 ],
      [ 'STORAGE_ID',           'INT', 'si.storage_id',                  1 ],
      [ 'SUPPLIER_ID',          'INT', 'si.supplier_id',                 1 ],
      [ 'SN',                   'INT', 'sia.sn',                         1 ],
      [ 'SERIAL',               'STR', 'sn.serial',                      1 ],
      [ 'STORAGE_INCOMING_ID',  'INT',  'sia.storage_incoming_id',       1 ],
      [ 'SI_ID',                'INT',  'si.id as si_id',                1 ],
      [ 'SI_AID',               'INT',  'si.aid AS si_aid',              1 ],
      [ 'IP',                   'STR',  'INET_NTOA(si.ip) AS ip',        1 ],
      [ 'SUPPLIER_ID',          'INT',  'si.supplier_id',                1 ],
      [ 'STORAGE_ID',           'INT',  'si.storage_id',                 1 ],
      [ 'SA_ID',                'INT',  'sa.id AS sa_id',                1 ],
      [ 'MEASURE',              'INT',  'sa.measure',                    1 ],
      [ 'MEASURE_NAME',         'STR',  'sm.name as measure_name',       1 ],
      [ 'SUPPLIER_NAME',        'STR',  'ss.name AS supplier_name',      1 ],
      [ 'SI_COMMENTS',          'STR',  'si.comments AS si_comments',    1 ],
      [ 'ADMIN_NAME',           'STR',  'a.name AS admin_name',          1 ],
      [ 'SSUB_COUNT',           'INT',  'ssub.count AS ssub_count',      1 ],
      [ 'SELL_PRICE',           'INT',  'sia.sell_price',                         1 ],
      [ 'RENT_PRICE',           'INT',  'sia.rent_price',                         1 ],
      [ 'IN_INSTALLMENTS_PRICE','INT',  'sia.in_installments_price',              1 ],
      [ 'TOTAL_SUM',            'INT',  'sia.sum as total_sum',                   1 ],
#      [ 'STORAGE_ID',           'INT',  'si.storage_id',                          1 ],
      [ 'SN_COMMENTS',          'STR',  'sn.sn_comments',                         1 ],
      [ 'STORAGE_NAME',         'STR',  'sss.name as storage_name',               1 ],
      [ 'ID',                   'INT',  'sia.id',                                 0 ],
      [ 'SIA_ID',               'INT',  'sia.id as sia_id',                       1 ],
      [ 'QRCODE_HASH',          'STR',  'sn.qrcode_hash',                         1 ],
      [ 'MAIN_ID',              'INT',  'sia.id as main_id',                      1 ],
      [ 'SIA_SUM',              'INT', 'sia.sum - ((sia.sum/sia.count) * (IF(ssub.count IS NULL, 0, (SELECT SUM(count) FROM storage_accountability WHERE storage_incoming_articles_id = sia.id GROUP BY storage_incoming_articles_id )) '
                                        .' + if(sr.count IS NULL, 0, (SELECT SUM(count) FROM storage_reserve WHERE storage_incoming_articles_id = sia.id GROUP BY storage_incoming_articles_id )))) AS sia_sum', 1],
      [ 'TOTAL',                'INT',  'sia.count - (IF(ssub.count IS NULL, 0, (SELECT sum(count) FROM storage_accountability WHERE storage_incoming_articles_id = sia.id GROUP BY storage_incoming_articles_id )) '
                                        .' + IF(sr.count IS NULL, 0, (SELECT SUM(count) FROM storage_reserve WHERE storage_incoming_articles_id = sia.id GROUP BY storage_incoming_articles_id ))) AS total',        1 ],
      [ 'ACCOUNTABILITY_COUNT', 'INT',  '(SELECT SUM(count) FROM storage_accountability WHERE storage_incoming_articles_id = sia.id GROUP BY storage_incoming_articles_id ) AS accountability_count',        1 ],
      [ 'RESERVE_COUNT',        'INT',  '(SELECT SUM(count) FROM storage_reserve WHERE storage_incoming_articles_id = sia.id GROUP BY storage_incoming_articles_id ) AS reserve_count',        1 ],
      [ 'DISCARD_COUNT',        'INT',  '(SELECT SUM(count) FROM storage_discard WHERE storage_incoming_articles_id = sia.id GROUP BY storage_incoming_articles_id ) AS discard_count',        1 ],
      [ 'INSTALATION_COUNT',    'INT',  '(SELECT SUM(count) FROM storage_installation WHERE storage_incoming_articles_id = sia.id GROUP BY storage_incoming_articles_id ) AS instalation_count',        1 ],
      [ 'INNER_USE_COUNT',      'INT',  '(SELECT SUM(count) FROM storage_inner_use WHERE storage_incoming_articles_id = sia.id GROUP BY storage_incoming_articles_id ) AS inner_use_count',        1 ],
      [ 'INVOICE_ID',           'INT',  'si.id as invoice_id',         1 ],
      [ 'DOMAIN_ID',            'INT',  'si.domain_id',                1 ],
      [ 'PUBLIC_SALE',          'INT',  'sia.public_sale',             1 ],
      [ 'IMAGE_URL',            'INT',  'em.image_url',                1 ],
    ],
    { WHERE             => 1,
      WHERE_RULES       => \@WHERE_RULES,
      #USERS_FIELDS=> 1,
      SKIP_USERS_FIELDS => [ 'FIO' ]
    }
  );

  my $HAVING = $attr->{UNINSTALL} ? "HAVING total > 0" : '';
  $SORT = 'sm.name, sia_count' if $SORT == 3 && $self->{SEARCH_FIELDS} =~ /sm.name/ && $self->{SEARCH_FIELDS} =~ /sia_count/;

  $EXT_TABLES .= ' LEFT JOIN equipment_models em ON (sa.equipment_model_id = em.id)' if $self->{SEARCH_FIELDS} =~ /em.image_url/;

  $self->query("SELECT $self->{SEARCH_FIELDS}
    sat.id
    FROM storage_incoming_articles AS sia
    LEFT JOIN storage_incoming si ON ( si.id = sia.storage_incoming_id )
    LEFT JOIN storage_articles sa ON ( sa.id = sia.article_id )
    LEFT JOIN storage_article_types sat ON ( sat.id = sa.article_type )
    LEFT JOIN storage_suppliers ss ON ( ss.id = si.supplier_id )
    LEFT JOIN admins a ON ( a.aid = si.aid )
    LEFT JOIN storage_accountability ssub ON ( ssub.storage_incoming_articles_id = sia.id )
    LEFT JOIN storage_reserve sr ON ( sr.storage_incoming_articles_id = sia.id )
    LEFT JOIN storage_sn sn ON (sn.id=sia.sn)
    LEFT JOIN storage_storages sss ON (sss.id=si.storage_id)
    LEFT JOIN storage_measure sm ON (sm.id = sa.measure)
    $EXT_TABLES
    $WHERE
    GROUP BY sia.id
    $HAVING
    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list};

  $self->query("SELECT COUNT(id) as total, SUM(total_count) AS count, SUM(sia_sum) as sum FROM (
    SELECT sia.id AS id,
      sia.count - (IF(ssub.count IS NULL, 0, (SELECT sum(count) FROM storage_accountability WHERE storage_incoming_articles_id = sia.id
      GROUP BY storage_incoming_articles_id )) + IF(sr.count IS NULL, 0, (SELECT SUM(count) FROM storage_reserve
      WHERE storage_incoming_articles_id = sia.id GROUP BY storage_incoming_articles_id ))) AS total_count,

      sia.sum - ((sia.sum/sia.count) * (IF(ssub.count IS NULL, 0, (SELECT SUM(count) FROM storage_accountability
      WHERE storage_incoming_articles_id = sia.id GROUP BY storage_incoming_articles_id )) + if(sr.count IS NULL, 0,
      (SELECT SUM(count) FROM storage_reserve WHERE storage_incoming_articles_id = sia.id GROUP BY storage_incoming_articles_id )))) AS sia_sum

    FROM storage_incoming_articles AS sia
    LEFT JOIN storage_incoming si ON ( si.id = sia.storage_incoming_id )
    LEFT JOIN storage_articles sa ON ( sa.id = sia.article_id )
    LEFT JOIN storage_article_types sat ON ( sat.id = sa.article_type )
    LEFT JOIN storage_suppliers ss ON ( ss.id = si.supplier_id )
    LEFT JOIN admins a ON ( a.aid = si.aid )
    LEFT JOIN storage_accountability ssub ON ( ssub.storage_incoming_articles_id = sia.id )
    LEFT JOIN storage_reserve sr ON ( sr.storage_incoming_articles_id = sia.id )
    LEFT JOIN storage_sn sn ON (sn.id=sia.sn)
    LEFT JOIN storage_storages sss ON (sss.id=si.storage_id)
    LEFT JOIN storage_measure sm ON (sm.id = sa.measure)
    $EXT_TABLES
    $WHERE
    GROUP BY sia.id
  ) AS sub;",
    undef,
    { INFO => 1 }
  );

  return $list;
}

#**********************************************************
=head2 storage_remnants_list()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub storage_remnants_list {
  my ($self) = shift;
  my ($attr) = @_;

  my @WHERE_RULES = ();
  my $SORT = (defined $attr->{SORT}) ? $attr->{SORT} : 'si.date';
  my $DESC = (defined $attr->{DESC}) ? $attr->{DESC} : 'desc';

  if (defined($attr->{CONSIGNMENT}) && $attr->{CONSIGNMENT} ne '') {
    push @WHERE_RULES, "(sia.main_article_id='$attr->{CONSIGNMENT}' OR sia.id='$attr->{CONSIGNMENT}')";
  }

  push @WHERE_RULES, "si.domain_id='$self->{admin}{DOMAIN_ID}'" if ($self->{admin}{DOMAIN_ID});

  my $WHERE = $self->search_former($attr, [
    [ 'ARTICLE_NAME',  'STR',  'sa.name AS article_name',                            1 ],
    [ 'STORAGE_ID',    'INT',  'si.storage_id',                                      1 ],
    [ 'REMNANTS_DATE', 'DATE', "DATE_FORMAT(si.date, '%Y-%m-%d') AS remnants_date",  1 ]
  ], { WHERE => 1, WHERE_RULES => \@WHERE_RULES, SKIP_USERS_FIELDS => [ 'FIO' ] });

  $self->query(qq{SELECT
    sia.id,
    sa.name AS name,

    sat.name AS type,

    SUM(sia.count) as count,

    (SELECT SUM(count) FROM storage_accountability WHERE storage_incoming_articles_id = sia.id GROUP BY storage_incoming_articles_id ) AS accountability_count,

    (SELECT SUM(count) FROM storage_reserve WHERE storage_incoming_articles_id = sia.id GROUP BY storage_incoming_articles_id ) AS reserve_count,

    (SELECT SUM(count) FROM storage_discard WHERE storage_incoming_articles_id = sia.id GROUP BY storage_incoming_articles_id ) AS discard_count,

    (SELECT SUM(count) FROM storage_installation WHERE storage_incoming_articles_id = sia.id GROUP BY storage_incoming_articles_id ) AS installation_count,

    sia.article_id,
    sm.name as measure_name,
    sia.main_article_id as main_article_id
    FROM storage_incoming_articles sia
    LEFT JOIN storage_articles sa ON (sa.id = sia.article_id)
    LEFT JOIN storage_article_types sat ON (sat.id = sa.article_type)
    LEFT JOIN storage_measure sm ON (sm.id = sa.measure)
    LEFT JOIN storage_incoming si ON (si.id = sia.storage_incoming_id)
    $WHERE
    GROUP BY sia.article_id
    ORDER BY $SORT $DESC;},
    undef,
    $attr
  );

  my $list = $self->{list};

  return $list;
}

#**********************************************************
=head2 storage_invoices_list($attr) Storage list types

=cut
#**********************************************************
sub storage_invoices_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  $attr->{DOMAIN_ID} ||= $admin->{DOMAIN_ID} || '_SHOW';

  my $total_sum = "SELECT SUM(IFNULL(sins.sum, 0) + IFNULL(siu.sum, 0) + IFNULL(sia.sum, 0) + IFNULL(sd.sum, 0)) AS total_marks
    FROM storage_incoming_articles sia
    LEFT JOIN storage_installation sins ON (sins.storage_incoming_articles_id = sia.id)
    LEFT JOIN storage_discard sd ON (sd.storage_incoming_articles_id = sia.id)
    LEFT JOIN storage_inner_use siu ON (siu.storage_incoming_articles_id = sia.id)
    WHERE sia.storage_incoming_id = si.id";

  my $WHERE = $self->search_former($attr, [
    [ 'ID',                'INT', 'si.id',                              1 ],
    [ 'INVOICE_NUMBER',    'STR', 'si.invoice_number',                  1 ],
    [ 'DATE',              'DATE', 'si.date',                           1 ],
    [ 'MFO',               'STR', 'ss.mfo',                             1 ],
    [ 'OKPO',              'STR', 'ss.okpo',                            1 ],
    [ 'ACCOUNT',           'STR', 'ss.account',                         1 ],
    [ 'BANK_NAME',         'STR', 'ss.bank_name',                       1 ],
    [ 'PHONE',             'STR', 'ss.phone',                           1 ],
    [ 'SUPPLIER_NAME',     'STR', 'ss.name as supplier_name',           1 ],
    [ 'PRINT_ID',          'INT', 'si.id as print_id',                  1 ],
    [ 'FROM_DATE|TO_DATE', 'DATE', "DATE_FORMAT(si.date, '%Y-%m-%d')",  1 ],
    [ 'SUPPLIER_ID',       'INT', 'si.supplier_id',                     1 ],
    [ 'DOMAIN_ID',         'INT', 'si.domain_id',                       1 ],
    [ 'PAYER_ID',          'INT', 'si.payer_id',                        1 ],
    [ 'PAYER_NAME',        'STR', 'sp.name AS payer_name',              1 ],
    [ 'TOTAL_SUM',         'INT', "($total_sum) AS total_sum",          1 ],
    [ 'STORAGE_NAME',      'STR', "sss.name AS storage_name",           1 ],
  ], { WHERE => 1 });

  $self->query("SELECT $self->{SEARCH_FIELDS} si.id
    FROM storage_incoming AS si
    LEFT JOIN storage_suppliers ss ON(ss.id = si.supplier_id)
    LEFT JOIN storage_payers sp ON (sp.id = si.payer_id)
    LEFT JOIN storage_storages sss ON (sss.id=si.storage_id)
    $WHERE
    ORDER BY $SORT $DESC;",
    undef, $attr
  );

  my $list = $self->{list} || [];

  $self->query("SELECT COUNT(*) AS total " . ($attr->{TOTAL_SUM} ? ",SUM(($total_sum)) as total_sum " : '') .
    "FROM storage_incoming AS si
    LEFT JOIN storage_suppliers ss ON(ss.id = si.supplier_id)
    LEFT JOIN storage_payers sp ON (sp.id = si.payer_id)
    $WHERE", undef, { INFO => 1 });

  return $list;
}

#**********************************************************
=head2 storage_admin_add() - add new admin

  Arguments:
     AID   - aid for settings

  Returns:
    $self

  Examples:

=cut
#**********************************************************
sub storage_admin_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('storage_admins', { %$attr, DOMAIN_ID => $self->{admin}{DOMAIN_ID} || 0 });

  return $self;
}

#*******************************************************************
=head2 storage_admin_change() - change admin settings

  Arguments:
    $attr

  Returns:
    $self object

  Examples:
    $Storage->crm_admin_change({
      ID       => 1,
      COMMENTS => 'test'
    });


=cut
#*******************************************************************
sub storage_admin_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'storage_admins',
    DATA         => $attr
  });

  return $self;
}

#*******************************************************************
=head2  storage_admin_delete() - delete admin settings

  Arguments:
    $attr

  Returns:

  Examples:
    $Storage->storage_admin_delete( {ID => 1} );

=cut
#*******************************************************************
sub storage_admin_delete {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('storage_admins', $attr);

  return $self;
}

#**********************************************************
=head2 storage_admins_list() - return list of admins

  Arguments:
    ATTRIBUTES -
  Returns:

  Examples:

=cut
#**********************************************************
sub storage_admins_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $WHERE = $self->search_former(
    $attr,
    [
      [ 'ID',         'INT', 'sadm.id',              1 ],
      [ 'ADMIN_NAME', 'STR', 'a.name as admin_name', 1 ],
      [ 'PERCENT',    'INT', 'sadm.percent',         1 ],
      [ 'AID',        'INT', 'sadm.aid',             1 ],
      [ 'COMMENTS',   'STR', 'sadm.comments',        1 ],
      [ 'DOMAIN_ID',  'INT', 'sadm.domain_id',         ],
    ],
    { WHERE => 1, }
  );

  $self->query(
    "SELECT
    $self->{SEARCH_FIELDS}
    sadm.id
    FROM storage_admins as sadm
    LEFT JOIN admins a ON (sadm.aid = a.aid)
    $WHERE
    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list};

  return $self->{list} if ($self->{TOTAL} < 1);

  $self->query(
    "SELECT COUNT(*) AS total
   FROM storage_admins",
    undef,
    { INFO => 1 }
  );

  return $list || [];
}

#**********************************************************
=head2 storage_property_info()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub storage_admin_info {
  my $self = shift;
  my ($attr) = @_;

  my $admin_info = $self->storage_admins_list({ %$attr });

  if ($admin_info && ref $admin_info eq 'ARRAY' && scalar @{$admin_info} == 1) {
    return $admin_info->[0];
  }
  else {
    return ();
  }
}

#**********************************************************
=head2 storage_install_stats()

=cut
#**********************************************************
sub storage_install_stats {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = $attr->{SORT} ? $attr->{SORT} : "si.id";
  my $DESC = $attr->{DESC} ? $attr->{DESC} : "DESC";
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $WHERE = $self->search_former(
    $attr,
    [
      [ 'ID',                     'INT',   'si.id',                       1 ],
      [ 'DATE',                   'DATE',  'si.date',                     1 ],
      [ 'COUNT',                  'INT',   'SUM(si.count) as count',      1 ],
      [ 'ARTICLE_ID',             'INT',   'sta.id as article_id',        1 ],
      [ 'TYPE_ID',                'INT',   'sat.id as type_id',           1 ],
      [ 'STA_NAME',               'STR',   'sta.name as sta_name',        1 ],
      [ 'SAT_NAME',               'STR',   'sat.name as sat_name',        1 ],
      [ 'SELL_PRICE',             'INT',   'SUM(si.actual_sell_price) as sell_price',   1 ],
      [ 'SUM_PRICE',              'INT',   'SUM(si.sum) as sum_price',    1 ],
      [ 'INSTALLED_AID',          'INT',   'si.installed_aid',            1 ],
      [ 'STORAGE_ID',             'INT',   'sinc.storage_id',             1 ],
      [ 'ADMIN_PERCENT',          'INT',   'SUM(si.actual_sell_price / 100 * sadmin.percent) AS admin_percent', 1],
      [ 'TYPE',                   'INT',   'si.type',                     1 ],
      [ 'DOMAIN_ID',              'INT',   'sinc.domain_id',              1 ],
      [ 'AMOUNT_PER_MONTH',       'INT',   'si.amount_per_month',         1 ],
      [ 'MONTHES',                'INT',   'si.monthes',                  1 ],
      [ 'IN_INSTALLMENTS_PRICE',  'INT',   'sia.in_installments_price',   1 ],
    ],
    { WHERE => 1, }
  );

  $self->query(
    "SELECT
    $self->{SEARCH_FIELDS}
    si.id
    FROM storage_installation as si
    LEFT JOIN storage_incoming_articles sia ON (sia.id = si.storage_incoming_articles_id)
    LEFT JOIN storage_incoming sinc ON (sinc.id = sia.storage_incoming_id)
    LEFT JOIN storage_articles sta ON (sta.id = sia.article_id)
    LEFT JOIN storage_article_types sat ON (sat.id = sta.article_type)
    LEFT JOIN storage_admins sadmin ON (sadmin.aid = si.installed_aid)
    $WHERE
    GROUP BY sta.id ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  return $self->{list};

}

#**********************************************************
=head2 storage_install_stats()

=cut
#**********************************************************
sub storage_in_installments_stats {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = $attr->{SORT} ? $attr->{SORT} : "si.id";
  my $DESC = $attr->{DESC} ? $attr->{DESC} : "DESC";
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $WHERE = $self->search_former(
    $attr,
    [
      [ 'ID',                     'INT',   'si.id',                       1 ],
      [ 'DATE',                   'DATE',  'si.date',                     1 ],
      [ 'COUNT',                  'INT',   'si.count',                    1 ],
      [ 'ARTICLE_ID',             'INT',   'sta.id as article_id',        1 ],
      [ 'TYPE_ID',                'INT',   'sat.id as type_id',           1 ],
      [ 'STA_NAME',               'STR',   'sta.name as sta_name',        1 ],
      [ 'SAT_NAME',               'STR',   'sat.name as sat_name',        1 ],
      [ 'SELL_PRICE',             'INT',   'si.actual_sell_price as sell_price',   1 ],
      [ 'SUM_PRICE',              'INT',   'si.sum as sum_price',         1 ],
      [ 'INSTALLED_AID',          'INT',   'si.installed_aid',            1 ],
      [ 'STORAGE_ID',             'INT',   'sinc.storage_id',             1 ],
      [ 'ADMIN_PERCENT',          'INT',   'sadmin.percent as admin_percent',  1 ],
      [ 'TYPE',                   'INT',   'si.type',                     1 ],
      [ 'DOMAIN_ID',              'INT',   'sinc.domain_id',              1 ],
      [ 'AMOUNT_PER_MONTH',       'INT',   'si.amount_per_month',         1 ],
      [ 'MONTHES',                'INT',   'si.monthes',                  1 ],
      [ 'IN_INSTALLMENTS_PRICE',  'INT',   'sia.in_installments_price',   1 ],
      [ 'TOTAL_MONTHS',           'INT',   'sia.in_installments_price / si.amount_per_month as total_months', 1 ],
      [ 'LAST_PAYMENT_DATE',      'DATE',  'DATE_ADD(si.date, INTERVAL (sia.in_installments_price / si.amount_per_month - 1) MONTH) as last_payment_date', 1],
      [ 'PAYMENTS_COUNT',         'INT',   "PERIOD_DIFF(
      DATE_FORMAT(IF(DATE_ADD(si.date, INTERVAL (sia.in_installments_price / si.amount_per_month - 1) MONTH) < '$attr->{TO_DATE}', DATE_ADD(si.date, INTERVAL (sia.in_installments_price / si.amount_per_month - 1) MONTH), '$attr->{TO_DATE}'), '%Y%m'),
      DATE_FORMAT(IF(si.date > '$attr->{FROM_DATE}', si.date, '$attr->{FROM_DATE}'), '%Y%m')) + 1 as payments_count", 1]
    ],
    { WHERE => 1, }
  );

  $self->query(
    "SELECT
    $self->{SEARCH_FIELDS}
    si.id
    FROM storage_installation as si
    LEFT JOIN storage_incoming_articles sia ON (sia.id = si.storage_incoming_articles_id)
    LEFT JOIN storage_incoming sinc ON (sinc.id = sia.storage_incoming_id)
    LEFT JOIN storage_articles sta ON (sta.id = sia.article_id)
    LEFT JOIN storage_article_types sat ON (sat.id = sta.article_type)
    LEFT JOIN storage_admins sadmin ON (sadmin.aid = si.installed_aid)
    $WHERE ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  return $self->{list};

}

#**********************************************************
=head2 storage_inventory_add() - add new inventory

  Arguments:
     AID   - aid for settings

  Returns:
    $self

  Examples:

=cut
#**********************************************************
sub storage_inventory_update {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('storage_inventory', { %$attr }, { REPLACE => 1 });

  $self->storage_log_add({
    %{$attr},
    ACTION     => 16,
    COMMENTS   => 'INCOMING_ARTICLE_ID: ' . $attr->{INCOMING_ARTICLE_ID}
  });

  return $self;
}

#**********************************************************
=head2 storage_inventory_list($attr) -  List of items in storages

=cut
#**********************************************************
sub storage_inventory_list {
  my $self = shift;
  my ($attr) = @_;

  my @WHERE_RULES = ();
  my $SORT = (defined $attr->{sort}) ? $attr->{sort} : 'si.date';
  my $DESC = (defined $attr->{desc}) ? $attr->{desc} : 'desc';

  my $EXT_TABLES = '';
  if (defined($attr->{HIDE_ZERO_VALUE})) {

    push @WHERE_RULES,
      "sia.count - (IF(ssub.count IS NULL, 0, (SELECT SUM(count) FROM storage_accountability WHERE storage_incoming_articles_id = sia.id "
    . "GROUP BY storage_incoming_articles_id )) + IF(sr.count IS NULL, 0, (SELECT SUM(count) FROM storage_reserve WHERE storage_incoming_articles_id = sia.id GROUP BY storage_incoming_articles_id )))";
  }

  $attr->{DOMAIN_ID} ||= $admin->{DOMAIN_ID} || '_SHOW';

  my $WHERE = $self->search_former($attr, [
      [ 'ARTICLE_NAME',         'STR', 'sa.name AS article_name',        1 ],
      [ 'ARTICLE_TYPE_NAME',    'STR', 'sat.name AS article_type_name',  1 ],
      [ 'SIA_COUNT',            'INT', 'sia.count as sia_count',         1 ],
      [ 'SERIAL',               'STR', 'sn.serial',                      1 ],
      [ 'STORAGE_NAME',         'STR',  'sss.name as storage_name',               1 ],
      [ 'INVENTORY_AID',        'INT',  'sinventory.aid as inventory_aid',       1 ],
      [ 'INVENTORY_ADMIN_NAME', 'STR',  'sinventorya.name as inventory_admin_name',       1 ],
      [ 'INVENTORY_DATE',       'DATE','sinventory.date as inventory_date',       1 ],
      [ 'SN',                   'INT', 'sia.sn',                         1 ],
      [ 'TOTAL',                'INT',  'sia.count - (IF(ssub.count IS NULL, 0, (SELECT SUM(count) FROM storage_accountability WHERE storage_incoming_articles_id = sia.id GROUP BY storage_incoming_articles_id ))'
                                  . '+ IF(sr.count IS NULL, 0, (SELECT SUM(count) FROM storage_reserve WHERE storage_incoming_articles_id = sia.id GROUP BY storage_incoming_articles_id ))) AS total',        1 ],
      [ 'STORAGE_ID',           'INT', 'si.storage_id',                  1 ],
      [ 'ARTICLE_PRICE',        'INT',  'sia.sum / sia.count AS article_price',   1 ],
      [ 'MAIN_ARTICLE_ID',      'INT', 'sia.main_article_id',            1 ],
      [ 'ARTICLE_ID',           'INT', 'sia.article_id',                 0 ],
      [ 'ARTICLE_TYPE',         'INT', 'sat.id as article_type',         0 ],
      [ 'DATE',                 'DATE', 'si.date',                       1 ],
      [ 'INVOICE_NAME',         'STR',  'si.invoice_number as invoice_name',         1 ],
      [ 'SUPPLIER_ID',          'INT', 'si.supplier_id',                 1 ],
      [ 'STORAGE_INCOMING_ID',  'INT',  'sia.storage_incoming_id',       1 ],
      [ 'SI_ID',                'INT',  'si.id as si_id',                1 ],
      [ 'SI_AID',               'INT',  'si.aid AS si_aid',              1 ],
      [ 'IP',                   'STR',  'INET_NTOA(si.ip) AS ip',        1 ],
      [ 'SUPPLIER_ID',          'INT',  'si.supplier_id',                1 ],
#      [ 'STORAGE_ID',           'INT',  'si.storage_id',                 1 ],
      [ 'SA_ID',                'INT',  'sa.id AS sa_id',                1 ],
      [ 'MEASURE',              'INT',  'sa.measure',                    1 ],
      [ 'MEASURE_NAME',         'STR',  'sm.name as measure_name',       1 ],
      [ 'SUPPLIER_NAME',        'STR',  'ss.name AS supplier_name',      1 ],
      [ 'SI_COMMENTS',          'STR',  'si.comments AS si_comments',    1 ],
      [ 'ADMIN_NAME',           'STR',  'a.name AS admin_name',          1 ],
      [ 'SSUB_COUNT',           'INT',  'ssub.count AS ssub_count',      1 ],
      [ 'SELL_PRICE',           'INT',  'sia.sell_price',                         1 ],
      [ 'RENT_PRICE',           'INT',  'sia.rent_price',                         1 ],
      [ 'IN_INSTALLMENTS_PRICE','INT',  'sia.in_installments_price',              1 ],
      [ 'TOTAL_SUM',            'INT',  'sia.sum as total_sum',                   1 ],

      #      [ 'STORAGE_ID',           'INT',  'si.storage_id',                          1 ],
      [ 'SN_COMMENTS',          'STR',  'sn.sn_comments',                         1 ],
      [ 'ID',                   'INT',  'sia.id',                                 0 ],
      [ 'SIA_ID',               'INT',  'sia.id as sia_id',                       1 ],
      [ 'QRCODE_HASH',          'STR',  'sn.qrcode_hash',                       1 ],
      [ 'MAIN_ID',              'INT',  'sia.id as main_id',         0 ],
      [ 'SIA_SUM',              'INT', 'sia.sum - ((sia.sum/sia.count) * (IF(ssub.count IS NULL, 0, '
                                       . '(SELECT sum(count) FROM storage_accountability WHERE storage_incoming_articles_id = sia.id GROUP BY storage_incoming_articles_id ))'
                                       . '+ IF(sr.count IS NULL, 0, (SELECT sum(count) FROM storage_reserve WHERE storage_incoming_articles_id = sia.id GROUP BY storage_incoming_articles_id )))) AS sia_sum', 1],
      [ 'ACCOUNTABILITY_COUNT', 'INT',  '(SELECT SUM(count) FROM storage_accountability WHERE storage_incoming_articles_id = sia.id GROUP BY storage_incoming_articles_id ) AS accountability_count',        1 ],
      [ 'RESERVE_COUNT',        'INT',  '(SELECT SUM(count) FROM storage_reserve WHERE storage_incoming_articles_id = sia.id GROUP BY storage_incoming_articles_id ) AS reserve_count',        1 ],
      [ 'DISCARD_COUNT',        'INT',  '(SELECT SUM(count) FROM storage_discard WHERE storage_incoming_articles_id = sia.id GROUP BY storage_incoming_articles_id ) AS discard_count',        1 ],
      [ 'INSTALATION_COUNT',    'INT',  '(SELECT SUM(count) FROM storage_installation WHERE storage_incoming_articles_id = sia.id GROUP BY storage_incoming_articles_id ) AS instalation_count',        1 ],
      [ 'INNER_USE_COUNT',      'INT',  '(SELECT SUM(count) FROM storage_inner_use WHERE storage_incoming_articles_id = sia.id GROUP BY storage_incoming_articles_id ) AS inner_use_count',        1 ],
      [ 'INVOICE_ID',           'INT',  'si.id as invoice_id',           1 ],
      [ 'DOMAIN_ID',            'INT',  'si.domain_id',                  1 ],
    ],
    { WHERE             => 1,
      WHERE_RULES       => \@WHERE_RULES,
      #USERS_FIELDS=> 1,
      SKIP_USERS_FIELDS => [ 'FIO' ]
    }
  );

  my $HAVING = '';
  if ($attr->{UNINSTALL}) {
    $HAVING = "HAVING total > 0";
  }

  $self->query("SELECT $self->{SEARCH_FIELDS}
                sat.id
                FROM storage_incoming_articles AS sia
              LEFT JOIN storage_incoming si ON ( si.id = sia.storage_incoming_id )
              LEFT JOIN storage_articles sa ON ( sa.id = sia.article_id )
              LEFT JOIN storage_article_types sat ON ( sat.id = sa.article_type )
              LEFT JOIN storage_suppliers ss ON ( ss.id = si.supplier_id )
              LEFT JOIN admins a ON ( a.aid = si.aid )
              LEFT JOIN storage_accountability ssub ON ( ssub.storage_incoming_articles_id = sia.id )
              LEFT JOIN storage_reserve sr ON ( sr.storage_incoming_articles_id = sia.id )
              LEFT JOIN storage_sn sn ON (sn.id=sia.sn)
              LEFT JOIN storage_storages sss ON (sss.id=si.storage_id)
              LEFT JOIN storage_measure sm ON (sm.id = sa.measure)
              LEFT JOIN storage_inventory sinventory ON (sinventory.incoming_article_id = sia.id)
              LEFT JOIN admins sinventorya ON ( sinventorya.aid = sinventory.aid )
                $EXT_TABLES
                $WHERE
                GROUP BY sia.id
                $HAVING
                ORDER BY $SORT $DESC;",
    undef,
    $attr
  );

  my $list = $self->{list};

  $self->query("SELECT COUNT(*) AS total, SUM(sia.count) AS count, SUM(sia.sum) as sum
       FROM storage_incoming_articles AS sia
       LEFT JOIN storage_incoming si ON ( si.id = sia.storage_incoming_id )
       LEFT JOIN storage_articles sa ON ( sa.id = sia.article_id )
       LEFT JOIN storage_article_types sat ON ( sat.id = sa.article_type )
       LEFT JOIN storage_suppliers ss ON ( ss.id = si.supplier_id )
       LEFT JOIN admins a ON ( a.aid = si.aid )
       LEFT JOIN storage_accountability ssub ON ( ssub.storage_incoming_articles_id = sia.id )
       LEFT JOIN storage_reserve sr ON ( sr.storage_incoming_articles_id = sia.id )
       LEFT JOIN storage_sn sn ON (sn.id=sia.sn)
    $EXT_TABLES
    $WHERE
    ;",
    undef,
    { INFO => 1 }
  );

  return $list;
}

#**********************************************************
=head2 storage_invoice_print_list($attr) - Storage invoice print

=cut
#**********************************************************
sub storage_invoice_print_list {
  my $self = shift;
  my ($attr) = @_;

  delete $self->{COL_NAMES_ARR};

  # my $WHERE = $self->search_former($attr, [
  #     [ 'STORAGE_INCOMING_ID', 'INT', 'sia1.storage_incoming_id as storage_incoming_id', 1 ]
  #   ],
  #   { WHERE => 1,
  #   }
  # );

  $self->query("SELECT
  sia1.id,
  sia1.storage_incoming_id,
  (IFNULL(sia1.count, 0)
   + (SELECT IFNULL(SUM(sia2.count), 0)
      FROM storage_incoming_articles sia2
      WHERE sia2.main_article_id = sia1.id)
   + (SELECT IFNULL(SUM(si2.count), 0)
      FROM storage_installation si2
      WHERE si2.storage_incoming_articles_id = sia1.id OR si2.storage_incoming_articles_id IN (SELECT sia5.id FROM storage_incoming_articles sia5 WHERE sia5.main_article_id=sia1.id))
   + (SELECT IFNULL(SUM(sd2.count), 0)
      FROM storage_discard sd2
      WHERE sd2.storage_incoming_articles_id = sia1.id OR sd2.storage_incoming_articles_id IN (SELECT sia5.id FROM storage_incoming_articles sia5 WHERE sia5.main_article_id=sia1.id))
   + (SELECT IFNULL(SUM(siu2.count), 0)
      FROM storage_inner_use siu2
      WHERE siu2.storage_incoming_articles_id = sia1.id OR siu2.storage_incoming_articles_id IN (SELECT sia5.id FROM storage_incoming_articles sia5 WHERE sia5.main_article_id=sia1.id))
  ) AS total_count,
  (IFNULL(sia1.sum, 0)
   + (SELECT IFNULL(SUM(sia3.sum), 0)
      FROM storage_incoming_articles sia3
      WHERE sia3.main_article_id = sia1.id)
   + (SELECT IFNULL(SUM(si3.sum), 0)
      FROM storage_installation si3
      WHERE si3.storage_incoming_articles_id = sia1.id OR si3.storage_incoming_articles_id IN (SELECT sia5.id FROM storage_incoming_articles sia5 WHERE sia5.main_article_id=sia1.id))
   + (SELECT IFNULL(SUM(sd3.sum), 0)
      FROM storage_discard sd3
      WHERE sd3.storage_incoming_articles_id = sia1.id OR sd3.storage_incoming_articles_id IN (SELECT sia5.id FROM storage_incoming_articles sia5 WHERE sia5.main_article_id=sia1.id))
   + (SELECT IFNULL(SUM(siu3.sum), 0)
      FROM storage_inner_use siu3
      WHERE siu3.storage_incoming_articles_id = sia1.id OR siu3.storage_incoming_articles_id IN (SELECT sia5.id FROM storage_incoming_articles sia5 WHERE sia5.main_article_id=sia1.id))
  ) AS sum,
  sa.name as article_name,
  sat.name as type_name,
  sm.name as measure_name
FROM storage_incoming_articles sia1
  LEFT JOIN storage_articles sa ON sa.id=sia1.article_id
  LEFT JOIN storage_article_types sat ON sat.id=sa.article_type
  LEFT JOIN storage_measure sm ON sm.id=sa.measure
WHERE sia1.storage_incoming_id='$attr->{INCOMING_ID}' AND sia1.main_article_id=0;",
    undef, $attr
  );

  my $list = $self->{list} || [];

  return $list;
}

#**********************************************************
=head2 storage_invoice_payments_add() - add new payment

  Arguments:
     AID   - aid for settings

  Returns:
    $self

  Examples:

=cut
#**********************************************************
sub storage_invoices_payments_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('storage_invoices_payments', {
      %$attr,
      AID  => $self->{admin}{AID},
      DATE => 'NOW()',
    });

  return $self;
}

#*******************************************************************
=head2  storage_invoice_payments_delete() - delete invoice payment

  Arguments:
    $attr

  Returns:

  Examples:
    $Storage->storage_invoice_payments_delete( {ID => 1} );

=cut

#*******************************************************************
sub storage_invoices_payments_delete {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('storage_invoices_payments', $attr);

  return $self;
}

#**********************************************************
=head2 storage_invoices_payments_list() - return list of payments

  Arguments:
    ATTRIBUTES -
  Returns:

  Examples:

=cut
#**********************************************************
sub storage_invoices_payments_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  $attr->{DOMAIN_ID} ||= $admin->{DOMAIN_ID} || '_SHOW';

  my $WHERE = $self->search_former(
    $attr,
    [
      [ 'ID',             'INT',  'sip.id',                1 ],
      [ 'INVOICE_NUMBER', 'STR',  'si.invoice_number',     1 ],
      [ 'SUM',            'INT',  'sip.sum',               1 ],
      [ 'ACTUAL_SUM',     'INT',  'sip.actual_sum',        1 ],
      [ 'ADMIN_NAME',     'STR',  'a.name as admin_name',  1 ],
      [ 'DATE',           'DATE', 'sip.date',              1 ],
      [ 'COMMENTS',       'STR',  'sip.comments',          1 ],
      [ 'DOMAIN_ID',      'INT',  'si.domain_id',          1 ],
      [ 'PAYER_ID',       'INT',  'si.payer_id',           1 ],
      [ 'PAYER_NAME',     'STR',  'sp.name AS payer_name', 1 ]
    ],
    { WHERE => 1 }
  );

  $self->query(
    "SELECT
    $self->{SEARCH_FIELDS}
    sip.id
    FROM storage_invoices_payments as sip
    LEFT JOIN admins a ON (sip.aid = a.aid)
    LEFT JOIN storage_incoming si ON (sip.invoice_id = si.id)
    LEFT JOIN storage_payers sp ON (sp.id = si.payer_id)
    $WHERE
    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list};

  return $self->{list} if ($self->{TOTAL} < 1);

  $self->query(
    "SELECT COUNT(*) AS total
   FROM storage_invoices_payments",
    undef,
    { INFO => 1 }
  );

  return $list || [];
}

#**********************************************************
=head2 storage_invoice_print_list($attr) - Storage invoice print

=cut
#**********************************************************
sub storage_incoming_report_by_date {
  my $self = shift;
  my ($attr) = @_;

  delete $self->{COL_NAMES_ARR};

  my @WHERE_RULES = ('sia1.main_article_id=0');
  push @WHERE_RULES, "si.domain_id='$self->{admin}{DOMAIN_ID}'" if $self->{admin}{DOMAIN_ID};

  my $WHERE = $self->search_former( $attr, [
    [ 'DOMAIN_ID',         'INT', 'si.domain_id',                      1 ],
    [ 'STORAGE_ID',        'INT', 'si.storage_id',                     1 ],
    [ 'INVOICE_ID',        'INT', 'si.id as invoice_id',               1 ],
    [ 'TYPE_ID',           'INT', 'sat.id as type_id',                 1 ],
    [ 'FROM_DATE|TO_DATE', 'DATE', "DATE_FORMAT(si.date, '%Y-%m-%d')", 1 ]
  ], { WHERE => 1, WHERE_RULES => \@WHERE_RULES });

  $self->query("SELECT
  sia1.id,
  sss.name AS storage_name,
  sia1.storage_incoming_id,
  (IFNULL(sia1.count, 0)
   + (SELECT IFNULL(SUM(sia2.count), 0)
      FROM storage_incoming_articles sia2
      WHERE sia2.main_article_id = sia1.id)
   + (SELECT IFNULL(SUM(si2.count), 0)
      FROM storage_installation si2
      WHERE si2.storage_incoming_articles_id = sia1.id OR si2.storage_incoming_articles_id IN (SELECT sia5.id FROM storage_incoming_articles sia5 WHERE sia5.main_article_id=sia1.id))
   + (SELECT IFNULL(SUM(sd2.count), 0)
      FROM storage_discard sd2
      WHERE sd2.storage_incoming_articles_id = sia1.id OR sd2.storage_incoming_articles_id IN (SELECT sia5.id FROM storage_incoming_articles sia5 WHERE sia5.main_article_id=sia1.id))
   + (SELECT IFNULL(SUM(siu2.count), 0)
      FROM storage_inner_use siu2
      WHERE siu2.storage_incoming_articles_id = sia1.id OR siu2.storage_incoming_articles_id IN (SELECT sia5.id FROM storage_incoming_articles sia5 WHERE sia5.main_article_id=sia1.id))
  ) AS total_count,
  (IFNULL(sia1.sum, 0)
   + (SELECT IFNULL(SUM(sia3.sum), 0)
      FROM storage_incoming_articles sia3
      WHERE sia3.main_article_id = sia1.id)
   + (SELECT IFNULL(SUM(si3.sum), 0)
      FROM storage_installation si3
      WHERE si3.storage_incoming_articles_id = sia1.id OR si3.storage_incoming_articles_id IN (SELECT sia5.id FROM storage_incoming_articles sia5 WHERE sia5.main_article_id=sia1.id))
   + (SELECT IFNULL(SUM(sd3.sum), 0)
      FROM storage_discard sd3
      WHERE sd3.storage_incoming_articles_id = sia1.id OR sd3.storage_incoming_articles_id IN (SELECT sia5.id FROM storage_incoming_articles sia5 WHERE sia5.main_article_id=sia1.id))
   + (SELECT IFNULL(SUM(siu3.sum), 0)
      FROM storage_inner_use siu3
      WHERE siu3.storage_incoming_articles_id = sia1.id OR siu3.storage_incoming_articles_id IN (SELECT sia5.id FROM storage_incoming_articles sia5 WHERE sia5.main_article_id=sia1.id))
  ) AS sum,
  sa.name as article_name,
  sat.name as type_name,
  sm.name as measure_name,
  si.date,
  si.invoice_number
  FROM storage_incoming_articles sia1
  LEFT JOIN storage_articles sa ON (sa.id=sia1.article_id)
  LEFT JOIN storage_article_types sat ON (sat.id=sa.article_type)
  LEFT JOIN storage_measure sm ON (sm.id=sa.measure)
  LEFT JOIN storage_incoming si ON (si.id=sia1.storage_incoming_id)
  LEFT JOIN storage_storages sss ON (sss.id=si.storage_id)
  $WHERE;",
    undef, $attr
  );

  my $list = $self->{list} || [];

  return $list;
}

#**********************************************************
=head2 storage_install_stats()

=cut
#**********************************************************
sub storage_rent_stats {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = $attr->{SORT} ? $attr->{SORT} : "si.id";
  my $DESC = $attr->{DESC} ? $attr->{DESC} : "DESC";
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  $attr->{DOMAIN_ID} ||= $admin->{DOMAIN_ID} || '_SHOW';

  my $WHERE = $self->search_former(
    $attr,
    [
      [ 'ID',                     'INT',   'si.id',                       1 ],
      [ 'DATE',                   'DATE',  'si.date',                     1 ],
      [ 'COUNT',                  'INT',   'si.count',                    1 ],
      [ 'ARTICLE_ID',             'INT',   'sta.id as article_id',        1 ],
      [ 'TYPE_ID',                'INT',   'sat.id as type_id',           1 ],
      [ 'STA_NAME',               'STR',   'sta.name as sta_name',        1 ],
      [ 'SAT_NAME',               'STR',   'sat.name as sat_name',        1 ],
      [ 'SELL_PRICE',             'INT',   'si.actual_sell_price as sell_price',   1 ],
      [ 'SUM_PRICE',              'INT',   'si.sum as sum_price',         1 ],
      [ 'INSTALLED_AID',          'INT',   'si.installed_aid',            1 ],
      [ 'STORAGE_ID',             'INT',   'sinc.storage_id',             1 ],
      [ 'ADMIN_PERCENT',          'INT',   'sadmin.percent as admin_percent',  1 ],
      [ 'TYPE',                   'INT',   'si.type',                     1 ],
      [ 'DOMAIN_ID',              'INT',   'sinc.domain_id',              1 ],
      [ 'AMOUNT_PER_MONTH',       'INT',   'sia.rent_price as amount_per_month',         1 ],
      [ 'PAYMENTS_COUNT',         'INT',   "PERIOD_DIFF(
      DATE_FORMAT(IF(DATE_ADD(si.date, INTERVAL (sia.in_installments_price / si.amount_per_month - 1) MONTH) < '$attr->{TO_DATE}', DATE_ADD(si.date, INTERVAL (sia.in_installments_price / si.amount_per_month - 1) MONTH), '$attr->{TO_DATE}'), '%Y%m'),
      DATE_FORMAT(IF(si.date > '$attr->{FROM_DATE}', si.date, '$attr->{FROM_DATE}'), '%Y%m')) + 1 as payments_count", 1]
    ],
    { WHERE => 1, }
  );

  $self->query(
    "SELECT
    $self->{SEARCH_FIELDS}
    si.id
    FROM storage_installation as si
    LEFT JOIN storage_incoming_articles sia ON (sia.id = si.storage_incoming_articles_id)
    LEFT JOIN storage_incoming sinc ON (sinc.id = sia.storage_incoming_id)
    LEFT JOIN storage_articles sta ON (sta.id = sia.article_id)
    LEFT JOIN storage_article_types sat ON (sat.id = sta.article_type)
    LEFT JOIN storage_admins sadmin ON (sadmin.aid = si.installed_aid)
    $WHERE ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  return $self->{list};
}

#**********************************************************
=head2 storage_payers_list($attr) Storage payers list

=cut
#**********************************************************
sub storage_payers_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  $attr->{DOMAIN_ID} ||= $admin->{DOMAIN_ID} || '_SHOW';

  my $WHERE = $self->search_former($attr, [
    [ 'ID',         'INT',        'sp.id',        ],
    [ 'NAME',       'STR',        'sp.name',      ],
    [ 'COMMENTS',   'STR',        'sp.comments',  ],
    [ 'DOMAIN_ID',  'DOMAIN_ID',  'sp.domain_id', ]
  ], { WHERE => 1 });

  $self->query("SELECT sp.id,
      sp.name,
      sp.comments
    FROM storage_payers AS sp
    $WHERE
    ORDER BY $SORT $DESC;",
    undef, $attr
  );

  return $self->{list};
}

#**********************************************************
=head2 storage_payers_info($attr) Storage payers info

=cut
#**********************************************************
sub storage_payers_info {
  my $self = shift;
  my ($attr) = @_;

  $self->query("SELECT * FROM storage_payers WHERE id = ?;", undef, { INFO => 1, Bind => [ $attr->{ID} ] });

  return $self;
}

#**********************************************************
=head2 storage_payers_add($attr) -  Add storage payers

=cut
#**********************************************************
sub storage_payers_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('storage_payers', { %$attr, DOMAIN_ID => $self->{admin}{DOMAIN_ID} || 0 });

  return 0;
}

#**********************************************************
=head2 storage_payers_change($attr) - Change payers info

=cut
#**********************************************************
sub storage_payers_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'storage_payers',
    DATA         => $attr,
  });

  return $self;
}

#**********************************************************
=head2 storage_payers_del($attr) - Del payers

=cut
#**********************************************************
sub storage_payers_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('storage_payers', $attr);

  return $self->{result};
}

#**********************************************************
=head2 storage_nas_installations($attr) - nas installations

=cut
#**********************************************************
sub storage_nas_installations {
  my $self = shift;
  my ($attr) = @_;

  my @WHERE_RULES = ('sl.nas_id > 0', 'sl.action = 11');
  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  my $WHERE = $self->search_former($attr, [
    [ 'NAS_ID',            'INT',  'sl.nas_id',                         1 ],
    [ 'TYPE_ID',           'INT',  'sat.id AS type_id',                 1 ],
    [ 'FROM_DATE|TO_DATE', 'DATE', "DATE_FORMAT(sl.date, '%Y-%m-%d')",  1 ]
  ], { WHERE => 1, WHERE_RULES => \@WHERE_RULES });

  $self->query("SELECT sl.nas_id, nas.name,
      GROUP_CONCAT(CONCAT(sat.name, ';', sa.name, ';', sl.date) SEPARATOR '||') AS total_installed,
      GROUP_CONCAT(IF(si.id IS NULL, null, CONCAT(sat.name, ';', sa.name, ';', sl.date)) SEPARATOR '||') AS current_installed,
      GROUP_CONCAT(IF(si.id IS NOT NULL, null, CONCAT(sat.name, ';', sa.name)) SEPARATOR '||') AS remove_installed
    FROM storage_log sl
    LEFT JOIN storage_incoming_articles sm ON ( sm.id = sl.storage_main_id )
    LEFT JOIN storage_articles sa ON ( sa.id = sm.article_id )
    LEFT JOIN storage_article_types sat ON ( sat.id = sa.article_type )
    LEFT JOIN storage_installation si ON (sl.storage_installation_id = si.id)
    LEFT JOIN nas ON (nas.id=sl.nas_id)
    $WHERE
    GROUP BY sl.nas_id
    ORDER BY $SORT $DESC;",
    undef, $attr
  );

  return $self->{list} || [];
}

#**********************************************************
=head2 storage_delivery_types_list($attr) Storage list delivery types

=cut
#**********************************************************
sub storage_delivery_types_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  $attr->{DOMAIN_ID} ||= $admin->{DOMAIN_ID} || '_SHOW';

  my $WHERE = $self->search_former($attr, [
    [ 'ID',         'INT',        'sdt.id',        ],
    [ 'NAME',       'STR',        'sdt.name',      ],
    [ 'COMMENTS',   'STR',        'sdt.comments',  ],
    [ 'DOMAIN_ID',  'DOMAIN_ID',  'sdt.domain_id', ]
  ], { WHERE => 1 });

  $self->query("SELECT sdt.id,
      sdt.name,
      sdt.comments
    FROM storage_delivery_types AS sdt
    $WHERE
    ORDER BY $SORT $DESC;",
    undef, $attr
  );

  return $self->{list};
}

#**********************************************************
=head2 storage_delivery_type_info($attr) Storage delivery type info

=cut
#**********************************************************
sub storage_delivery_type_info {
  my $self = shift;
  my ($attr) = @_;

  $self->query("SELECT * FROM storage_delivery_types WHERE id= ?;", undef, { INFO => 1, Bind => [ $attr->{ID} ] });

  return $self;
}

#**********************************************************
=head2 storage_delivery_types_add($attr) -  Add storage delivery types

=cut
#**********************************************************
sub storage_delivery_types_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('storage_delivery_types', { %$attr, DOMAIN_ID => $self->{admin}{DOMAIN_ID} || 0 });

  return 0;
}

#**********************************************************
=head2 storage_delivery_types_change($attr) - Change storage delivery types

=cut
#**********************************************************
sub storage_delivery_types_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'storage_delivery_types',
    DATA         => $attr,
  });

  return $self;
}

#**********************************************************
=head2 storage_delivery_types_del($attr) - Delete storage delivery types

=cut
#**********************************************************
sub storage_delivery_types_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('storage_delivery_types', $attr);

  return $self->{result};
}

#**********************************************************
=head2 storage_deliveries_list($attr) Storage list deliveries

=cut
#**********************************************************
sub storage_deliveries_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  $attr->{DOMAIN_ID} ||= $admin->{DOMAIN_ID} || '_SHOW';

  my $WHERE = $self->search_former($attr, [
    [ 'ID',              'INT',  'id',               ],
    [ 'TYPE_ID',         'INT',  'type_id',          ],
    [ 'INSTALLATION_ID', 'INT',  'installation_id',  ],
    [ 'DATE',            'DATE', 'date',             ],
    [ 'TRACKING_NUMBER', 'STR',  'tracking_number',  ],
    [ 'COMMENTS',        'STR',  'comments',         ]
  ], { WHERE => 1 });

  $self->query("SELECT $self->{SEARCH_FIELDS} id
    FROM storage_deliveries
    $WHERE
    ORDER BY $SORT $DESC;",
    undef, $attr
  );

  return $self->{list};
}

#**********************************************************
=head2 storage_delivery_info($attr) Storage delivery info

=cut
#**********************************************************
sub storage_delivery_info {
  my $self = shift;
  my ($attr) = @_;

  if ($attr->{INSTALLATION_ID}) {
    $self->query("SELECT * FROM storage_deliveries WHERE installation_id = ?;", undef, { INFO => 1, Bind => [ $attr->{INSTALLATION_ID} ] });
  }
  else {
    $self->query("SELECT * FROM storage_deliveries WHERE id = ?;", undef, { INFO => 1, Bind => [ $attr->{ID} ] });
  }

  return $self;
}

#**********************************************************
=head2 storage_delivery_add($attr) -  Add storage delivery

=cut
#**********************************************************
sub storage_delivery_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('storage_deliveries', { %$attr });

  return 0;
}

#**********************************************************
=head2 storage_delivery_change($attr) - Change storage delivery

=cut
#**********************************************************
sub storage_delivery_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'INSTALLATION_ID',
    TABLE        => 'storage_deliveries',
    DATA         => $attr,
  });

  return $self;
}

=head1 COPYRIGHT

  Copyright (с) 2003-2023 Andy Gulay (ABillS DevTeam) Ukraine
  All rights reserved.
  https://billing.axiostv.ru/

=cut

1
