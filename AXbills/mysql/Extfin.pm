package Extfin;

=head1 NAME

 External finance manage functions

=cut

use strict;
use parent qw(dbcore);

our $VERSION = 2.08;
my ($admin, $CONF);
my $MODULE = 'Extfin';

#**********************************************************
# Init
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

  $self->{MODULE} = $MODULE;

  $CONF->{BUILD_DELIMITER} = ', ' if (!defined($CONF->{BUILD_DELIMITER}));

  bless($self, $class);

  return $self;
}

#**********************************************************
# defauls user settings
#**********************************************************
sub defaults{
  my $self = shift;

  my %DATA = (
    LOGIN          => '',
    ACTIVATE       => '0000-00-00',
    EXPIRE         => '0000-00-00',
    CREDIT         => 0,
    REDUCTION      => '0.00',
    SIMULTANEONSLY => 0,
    DISABLE        => 0,
    COMPANY_ID     => 0,
    GID            => 0,
    DISABLE        => 0,
    PASSWORD       => ''
  );

  $self = \%DATA;
  return $self;
}

#**********************************************************
# list()
#**********************************************************
sub customers_list{
  my $self = shift;
  my ($attr) = @_;

  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  my $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 100000;

  $self->{SEARCH_FIELDS} = '';
  $self->{SEARCH_FIELDS_COUNT} = 0;

  my @WHERE_RULES = ();

  if ( $attr->{INFO_FIELDS} ){
    my @info_arr = split( /, /, $attr->{INFO_FIELDS} );
    $self->{SEARCH_FIELDS} .= ', pi.' . join( ', pi.', @info_arr );
    $self->{SEARCH_FIELDS_COUNT} += $#info_arr;
  }

  if ( $attr->{INFO_FIELDS_COMPANIES} ){
    my @info_arr = split( /, /, $attr->{INFO_FIELDS_COMPANIES} );
    $self->{SEARCH_FIELDS} .= ', company.' . join( ', company.', @info_arr );
    $self->{SEARCH_FIELDS_COUNT} += $#info_arr;
  }

  # Show debeters
  if ( $attr->{DEBETERS} ){
    push @WHERE_RULES, "b.deposit<0";
  }

  # Show groups
  if ( $attr->{GIDS} ){
    push @WHERE_RULES, "u.gid IN ($attr->{GIDS})";
  }
  elsif ( $attr->{GID} ){
    push @WHERE_RULES, "u.gid='$attr->{GID}'";
  }

  if ( defined( $attr->{USER_TYPE} ) && $attr->{USER_TYPE} ne '' ){
    push @WHERE_RULES, ($attr->{USER_TYPE} == 1) ? "u.company_id>'0'" : "u.company_id='0'";
  }

  my $WHERE = $self->search_former( $attr, [
      [ 'DISABLE', 'INT', 'u.disable', 1 ],
      [ 'ACTIVATE', 'DATE', 'u.activate', 1 ],
      [ 'EXPIRE', 'STR', 'u.expire', 1 ],
      [ 'COMPANY_ID', 'INT', 'u.company_id' ],
      [ 'LOGIN', 'STR', 'u.id' ],
      [ 'PHONE', 'STR', 'pi.phone', 1 ],
      [ 'ADDRESS_STREET', 'STR', 'pi.address_street', 1 ],
      [ 'ADDRESS_BUILD', 'STR', 'pi.address_build', 1 ],
      [ 'ADDRESS_FLAT', 'STR', 'pi.address_flat', 1 ],
      [ 'CONTRACT_ID', 'STR', 'pi.contract_id', 1 ],
      [ 'REGISTRATION', 'INT', 'u.registration', 1 ],
      [ 'DEPOSIT', 'INT', 'b.deposit' ],
      [ 'CREDIT', 'STR', 'u.credit' ],
      [ 'COMMENTS', 'STR', 'pi.comments', 1 ],
    ],
    { WHERE       => 1,
      WHERE_RULES => \@WHERE_RULES
    }
  );

  #Show last paymenst
  # Group, Kod, ������������, ��� �����������, ������ ������������, ����������� �����, �������� �����,
  # ����� ��������, ���, �������� �������, �������� ����,
  #$conf{ADDRESS_REGISTER}=1;

  my $ADDRESS_FULL = ($CONF->{ADDRESS_REGISTER}) ? "if(u.company_id > 0, company.address, concat(streets.name, '$CONF->{BUILD_DELIMITER}', builds.number, '$CONF->{BUILD_DELIMITER}', pi.address_flat)) AS ADDRESS" : "if(u.company_id > 0, company.address, concat(pi.address_street, '$CONF->{BUILD_DELIMITER}', pi.address_build, '$CONF->{BUILD_DELIMITER}', pi.address_flat)) AS ADDRESS";

  $self->query( "SELECT
                         u.uid, 
                         if(u.company_id > 0, company.name, 
                            if(pi.fio<>'', pi.fio, u.id)) AS login,
                         if(u.company_id > 0, company.name, 
                            if(pi.fio<>'', pi.fio, u.id)) AS name,
                         u.gid,
                         g.name,
                         if(company.id IS NULL, 0, company.id) AS company_id,
                         $ADDRESS_FULL,
                         if(u.company_id > 0, company.phone, pi.phone),
                         if(u.company_id > 0, company.contract_sufix, pi.contract_sufix) AS contract_sufix,
                         if(u.company_id > 0, company.contract_id, pi.contract_id) AS contract_id,
                         if(u.company_id > 0, company.contract_date, pi.contract_date) AS contract_date,
                         if(u.company_id > 0, company.bill_id, u.bill_id) AS bill_id,
                         if(u.company_id > 0, company.bank_account, '') AS bank_account,
                         if(u.company_id > 0, company.bank_name, '') AS bank_name,
                         if(u.company_id > 0, company.cor_bank_account, '') AS cor_bank_account,
                         u.uid
                       $self->{SEARCH_FIELDS}

     FROM `users` u
     LEFT JOIN `users_pi` pi ON (u.uid = pi.uid)
     LEFT JOIN `companies` company ON  (u.company_id=company.id)
     LEFT JOIN `bills` b ON (u.bill_id = b.id)
     LEFT JOIN `bills` cb ON  (company.bill_id=cb.id)
     LEFT JOIN `groups` g ON  (u.gid=g.gid)

     LEFT JOIN `builds` ON (builds.id=pi.location_id)
     LEFT JOIN `streets` ON (streets.id=builds.street_id)

     $WHERE
     GROUP BY 12
     ORDER BY $SORT $DESC 
     LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  return [ ] if ($self->{errno});
  my $list = $self->{list};

  return $list;
}

#**********************************************************
=head2 payment_deed($attr)

=cut
#**********************************************************
sub payment_deed{
  my $self = shift;
  my ($attr) = @_;

  my %PAYMENT_DEED = ();
  my @WHERE_RULES_DV = ();
  my @WHERE_RULES = ();
  my %NAMES = ();
  my $LIMIT = '';

  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  my $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  if ( $attr->{PAGE_ROWS} ){
    $LIMIT = " LIMIT $attr->{PAGE_ROWS}";
  }

  if ( $attr->{FROM_DATE} ){
    push @WHERE_RULES,
      "DATE_FORMAT(f.date, '%Y-%m-%d')>='$attr->{FROM_DATE}' AND DATE_FORMAT(f.date, '%Y-%m-%d')<='$attr->{TO_DATE}'";
    push @WHERE_RULES_DV,
      "DATE_FORMAT(internet.start, '%Y-%m-%d')>='$attr->{FROM_DATE}' AND DATE_FORMAT(internet.start, '%Y-%m-%d')<='$attr->{TO_DATE}'";
  }
  elsif ( $attr->{MONTH} ){
    push @WHERE_RULES, "DATE_FORMAT(f.date, '%Y-%m')='$attr->{MONTH}'";
    push @WHERE_RULES_DV, "DATE_FORMAT(internet.start, '%Y-%m')='$attr->{MONTH}'";
  }

  # Show groups
  if ( $attr->{GIDS} ){
    push @WHERE_RULES, "u.gid IN ($attr->{GIDS})";
    push @WHERE_RULES_DV, "u.gid IN ($attr->{GIDS})";
  }
  elsif ( $attr->{GID} ){
    push @WHERE_RULES, "u.gid='$attr->{GID}'";
    push @WHERE_RULES_DV, "u.gid IN ($attr->{GIDS})";
  }

  if ( defined( $attr->{USER_TYPE} ) && $attr->{USER_TYPE} ne '' ){
    push @WHERE_RULES, ($attr->{USER_TYPE} == 1) ? "u.company_id>'0'" : "u.company_id='0'";
    push @WHERE_RULES_DV, ($attr->{USER_TYPE} == 1) ? "u.company_id>'0'" : "u.company_id='0'";
  }

  my $WHERE = ($#WHERE_RULES > -1) ? join( ' and ', @WHERE_RULES ) : '';
  my $WHERE_DV = ($#WHERE_RULES > -1) ? join( ' and ', @WHERE_RULES_DV ) : '';

  my $info_fields = '';
  my $info_fields_count = 0;
  if ( $attr->{INFO_FIELDS} ){
    my @info_arr = split( /, /, $attr->{INFO_FIELDS} );
    $info_fields = ', pi.' . join( ', pi.', @info_arr );
    $info_fields_count = $#info_arr;
  }

  if ( $attr->{INFO_FIELDS_COMPANIES} ){
    my @info_arr = split( /, /, $attr->{INFO_FIELDS} );
    $info_fields .= ', company.' . join( ', company.', @info_arr );
    $info_fields_count += $#info_arr;
  }

  #Get fees
  $self->query( "SELECT
  IF(u.company_id > 0, company.bill_id, u.bill_id) AS bill_id,
  SUM(f.sum) AS sum,
  IF(u.company_id > 0, company.name, if(pi.fio<>'', pi.fio, u.id)) AS fio,
  IF(u.company_id > 0, 1, 0) AS is_company,
  IF(u.company_id > 0, company.vat, 0) AS vat,
  u.uid,
  MAX(f.date) AS max_date
  $info_fields
     FROM users u
     INNER JOIN fees f ON (u.uid=f.uid)
     LEFT JOIN users_pi pi ON (u.uid = pi.uid)
     LEFT JOIN companies company ON  (u.company_id=company.id)
     WHERE $WHERE
     GROUP BY u.uid
     ORDER BY $SORT $DESC
     $LIMIT;",
    undef,
    { COLS_NAME => 1 }
  );

  foreach my $line ( @{ $self->{list} } ){
    next if (!$line->{bill_id});

    $PAYMENT_DEED{ $line->{bill_id} } = $line->{sum};

    #Name|Type|VAT
    $NAMES{ $line->{bill_id} } = "$line->{fio}|$line->{is_company}|$line->{vat}";
    if ( $info_fields_count > 0 ){
      for ( my $i = 0; $i <= $info_fields_count; $i++ ){
        $NAMES{ $line->{bill_id} } .= "|" . $line->{ $self->{COL_NAMES_ARR}->[ 7 + $i ] };
      }
    }
  }

  #Get Dv use
  $self->query( "SELECT
   IF(u.company_id > 0, company.bill_id, u.bill_id) AS bill_id,
   SUM(internet.sum) AS sum,
   IF(u.company_id > 0, company.name, IF(pi.fio<>'', pi.fio, u.id)) AS fio,
   IF(u.company_id > 0, 1, 0) AS is_company,
   IF(u.company_id > 0, company.vat, 0) AS vat,
  u.uid 
  $info_fields
     FROM users u
     INNER JOIN internet_log internet ON (u.uid=internet.uid)
     LEFT JOIN users_pi pi ON (u.uid = pi.uid)
     LEFT JOIN companies company ON  (u.company_id=company.id)
     WHERE $WHERE_DV
     GROUP BY 1
     ORDER BY 2 DESC
  $LIMIT;",
    undef,
    { COLS_NAME => 1 }
  );

  foreach my $line ( @{ $self->{list} } ){
    if ( !$PAYMENT_DEED{ $line->{bill_id} } ){
      $PAYMENT_DEED{ $line->{bill_id} } += $line->{sum};

      #Name|Type|VAT
      $NAMES{ $line->{bill_id} } = "$line->{fio}|$line->{is_company}|$line->{vat}";

      if ( $info_fields_count > 0 ){
        for ( my $i = 0; $i <= $info_fields_count; $i++ ){
          $NAMES{ $line->{bill_id} } .= "|" . $line->{ $self->{COL_NAMES_ARR}->[ 7 + $i ] };
        }
      }
    }
    else{
      $PAYMENT_DEED{ $line->{bill_id} } += $line->{sum};
    }
  }

  $self->{PAYMENT_DEED} = \%PAYMENT_DEED;
  $self->{NAMES} = \%NAMES;

  return $self;
}

#**********************************************************
=head2 summary_add($attr)

=cut
#**********************************************************
sub summary_add{
  my $self = shift;
  my ($attr) = @_;

  $self->query_add( 'extfin_reports', { %{$attr},
      AID => $admin->{AID}
    } );

  return $self;
}

#**********************************************************
=head2 balances_add($attr)

=cut
#**********************************************************
sub balances_add{
  my $self = shift;
  my ($attr) = @_;

  if ($CONF->{DAILE_PERIOD}) {
    $self->query_add('extfin_balance_reports', $attr);
  }
  else {
    $self->query( "INSERT INTO extfin_balance_reports (period, bill_id, sum, date, aid)
    SELECT '$attr->{PERIOD}', id, deposit, now(), $admin->{AID} FROM bills;", 'do'
    );
  }

  return $self;
}

#**********************************************************
=head2 extfin_report_balances()  Show full reports

=cut
#**********************************************************
sub extfin_report_balances{
  my $self = shift;
  my ($attr) = @_;

  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  my $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my @WHERE_RULES = ("u.id IS NOT NULL");
  my @FEES_WHERE_RULES = ();
  my @PAYMENTS_WHERE_RULES = ();


  if ( $attr->{MONTH} ){
    #push @FEES_WHERE_RULES, "DATE_FORMAT(f.date, '%Y-%m')='$attr->{MONTH}'";
    #push @PAYMENTS_WHERE_RULES, "DATE_FORMAT(p.date, '%Y-%m')='$attr->{MONTH}' ";
    push @FEES_WHERE_RULES, "(f.date>='$attr->{MONTH}-01 00:00:00' AND f.date<='$attr->{MONTH}-31 24:00:00')";
    push @PAYMENTS_WHERE_RULES, "(p.date>='$attr->{MONTH}-01 00:00:00' AND p.date<='$attr->{MONTH}-31 24:00:00')";
  }

  if ( defined( $attr->{USER_TYPE} ) && $attr->{USER_TYPE} ne '' ){
    push @WHERE_RULES, ($attr->{USER_TYPE} == 1) ? "company.name is not null" : "u.company_id='0'";
  }

  my $GROUP = 1;
  my $report_sum = 'report.sum';
  if ( $attr->{TOTAL_ONLY} ){
    $GROUP = 5;
    $report_sum = 'sum(report.sum)';
  }

  my $WHERE = $self->search_former( $attr, [
      [ 'MONTH',             'DATE', 'report.period' ],
      [ 'FROM_DATE|TO_DATE', 'DATE', 'report.period' ],
      [ 'GID',               'STR', 'u.gid', ]
    ],
    { WHERE       => 1,
      WHERE_RULES => \@WHERE_RULES
    }
  );

  my $FEES_WHERE = ($#FEES_WHERE_RULES > -1) ? "AND " . join( ' AND ', @FEES_WHERE_RULES ) : '';
  my $PAYMENTS_WHERE = ($#PAYMENTS_WHERE_RULES > -1) ? "AND " . join( ' AND ', @PAYMENTS_WHERE_RULES ) : '';

  $self->query( "SELECT report.id,
   u.id,
   IF(company.name is not null, company.name, IF(pi.fio<>'', pi.fio, u.id)) AS user_name,
   \@a := if ((SELECT SUM(p.sum) FROM payments p WHERE (u.uid = p.uid) $PAYMENTS_WHERE) is not null, $report_sum + (SELECT SUM(p.sum) FROM payments p WHERE (u.uid = p.uid) $PAYMENTS_WHERE), $report_sum) AS payment_sum,
   \@b := (SELECT SUM(f.sum) FROM fees f WHERE (u.uid = f.uid) $FEES_WHERE) AS fees_sum,
   \@a,
   u.uid
  FROM extfin_balance_reports report
  INNER JOIN bills b ON (report.bill_id = b.id)
  LEFT JOIN users u ON (b.id = u.bill_id)
  LEFT JOIN users_pi pi ON (u.uid = pi.uid)
  LEFT JOIN companies company ON (b.id=company.bill_id)
  $WHERE
  GROUP BY $GROUP
  ORDER BY $SORT $DESC 
   ;",
    undef,
    $attr
  );

  my $list = $self->{list} || [];

  $self->query( "SELECT
    \@a := SUM(if ((SELECT SUM(p.sum) FROM payments p WHERE (u.uid = p.uid) $PAYMENTS_WHERE) is not null, $report_sum + (SELECT SUM(p.sum) FROM payments p WHERE (u.uid = p.uid) $PAYMENTS_WHERE), $report_sum)) AS total_debit,
    SUM((SELECT SUM(f.sum) FROM fees f WHERE (u.uid = f.uid) $FEES_WHERE)) AS total_credit,
    \@a - SUM($report_sum) AS total_saldo

  FROM extfin_balance_reports report
  INNER JOIN bills b ON (report.bill_id = b.id)
  LEFT JOIN users u ON (b.id = u.bill_id)
  LEFT JOIN users_pi pi ON (u.uid = pi.uid)
  LEFT JOIN companies company ON (b.id=company.bill_id)
  $WHERE;",
    undef, { INFO => 1 }
  );

  return $list;
}

#**********************************************************
# del
#**********************************************************
sub summary_del{
  my $self = shift;
  my ($attr) = @_;

  $self->query_del( 'extfin_reports', $attr );

  return $self;
}

#**********************************************************
# Show full reports
#**********************************************************
sub extfin_report_deeds{
  my $self = shift;
  my ($attr) = @_;

  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  my $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my @WHERE_RULES = ();

  if ( defined( $attr->{USER_TYPE} ) && $attr->{USER_TYPE} ne '' ){
    push @WHERE_RULES, ($attr->{USER_TYPE} == 1) ? "company.name is not null" : "u.company_id='0'";
  }

  my $GROUP = 1;
  my $report_sum = 'report.sum';
  if ( $attr->{TOTAL_ONLY} ){
    $GROUP = 5;
    $report_sum = 'SUM(report.sum)';
  }

  my $WHERE = $self->search_former( $attr, [
      [ 'MONTH', 'DATE', 'report.period' ],
      [ 'FROM_DATE|TO_DATE', 'DATE', 'report.period' ],
      [ 'GID', 'STR', 'u.gid', ]
    ],
    { WHERE       => 1,
      WHERE_RULES => \@WHERE_RULES
    }
  );

  $self->query( "SELECT report.id,
   report.period,
   report.bill_id,
   IF(company.name is not null, company.name,
    IF(pi.fio<>'', pi.fio, u.id)),
   IF(company.name is not null, 1, 0),
   $report_sum,
   IF(company.name is not null, company.vat, 0),
   report.date,
   report.aid, 
   u.uid
  FROM extfin_reports report
  INNER JOIN bills b ON (report.bill_id = b.id)
  LEFT JOIN users u ON (b.id = u.bill_id)
  LEFT JOIN users_pi pi ON (u.uid = pi.uid)
  LEFT JOIN companies company ON (b.id=company.bill_id)
  $WHERE
   GROUP BY $GROUP
  ORDER BY $SORT $DESC 
   ;",
    undef,
    $attr
  );

  return $self->{list} || [];
}

#**********************************************************
=head2 paid_add($attr)

=cut
#**********************************************************
sub paid_add{
  my $self = shift;
  my ($attr) = @_;

  my $status_date = ($attr->{STATUS} && $attr->{STATUS} > 0) ? 'NOW()' : '0000-00-00';

  $self->query( "INSERT INTO extfin_paids
   (date, sum, comments, uid, aid, status, type_id, ext_id, status_date, maccount_id)
  VALUES ('$attr->{DATE}', '$attr->{SUM}', '$attr->{DESCRIBE}', '$attr->{UID}', '$admin->{AID}',
  '$attr->{STATUS}', '$attr->{TYPE}', '$attr->{EXT_ID}', $status_date,
  '$attr->{MACCOUNT_ID}');",
    'do'
  );

  return $self;
}

#**********************************************************
=head2 paid_periodic_add($attr)

=cut
#**********************************************************
sub paid_periodic_add{
  my $self = shift;
  my ($attr) = @_;

  $admin->{MODULE} = $MODULE;

  my @ids_arr = split( /, /, $attr->{IDS} );

  $self->paid_periodic_del( { UID => $attr->{UID} } );

  foreach my $id (@ids_arr) {
    $self->query( "INSERT INTO extfin_paids_periodic
     (uid,
      type_id,
      comments,
      sum,
      date,
      activate,
      expire,
      aid,
      maccount_id)
    VALUES
     (?, ?, ?, ?, NOW(), ?, ?, ?, ?);",
      undef,
      {
        Bind => [
          $attr->{UID},
          $id,
          $attr->{'COMMENTS_'.$id},
          $attr->{'SUM_'.$id },
          $attr->{'ACTIVATE_'.$id},
          $attr->{'EXPIRE_'.$id},
          $admin->{AID},
          $attr->{'MACCOUNT_ID_'.$id}
        ]
      }
    );

    $admin->action_add($attr->{UID}, "ADDED_PERIODIC_ACCRUAL: " .  $id . ": ". "->". ($attr->{'SUM_'.$id} || q{}), { TYPE => 1 });
  }


  return $self;
}

#**********************************************************
=head2 paid_periodic_del($attr)

=cut
#**********************************************************
sub paid_periodic_del{
  my $self = shift;
  my ($attr) = @_;
  my %where = ();
  if (defined($attr->{UID})) {
    $where{UID} = $attr->{UID};
  }

  if (defined($attr->{ID})) {
    $where{ID} = $attr->{ID};
  }
  $self->query_del( 'extfin_paids_periodic', undef,
    \%where );

  return $self;
}

#**********************************************************
=head paid_periodic_list($attr)

=cut
#**********************************************************
sub paid_periodic_list{
  my $self = shift;
  my ($attr) = @_;

  my $JOIN_WHERE = '';
  if ($attr->{UID}) {
    $JOIN_WHERE = " AND pp.uid='$attr->{UID}'";
  }

  my @WHERE_RULES = ("pt.periodic='1'");

  my $WHERE = $self->search_former( $attr, [
      defined($attr->{ACTIVE}) ? [ 'UID',      'INT',  'pp.uid'] : [],
      [ 'SUM',      'INT',  'pp.sum'      ],
      [ 'EXPIRE',   'DATE', 'pp.expire'   ],
      [ 'ACTIVATE', 'DATE', 'pp.activate' ],
      [ 'DISABLE',  'INT',  'u.disable', 1 ],
      [ 'DELETED',  'INT',  'u.deleted', 1 ]
    ],
    {
      WHERE       => 1,
      WHERE_RULES => \@WHERE_RULES
    }
  );

  $self->query( "SELECT
     pt.id,
     pt.name,
     IF(pp.id IS NULL, pt.sum, pp.sum) AS sum,
     pp.comments,
     pp.maccount_id,
     a.id as admin,
     pp.date,
     pp.expire,
     pp.aid,
     pp.uid,
     pp.id AS pt_id,
     pp.activate,
     u.id AS login,
     u.disable
   FROM extfin_paids_types pt
   LEFT JOIN extfin_paids_periodic pp FORCE INDEX FOR JOIN (`type_id`) ON (pt.id=pp.type_id $JOIN_WHERE)
   LEFT JOIN admins a ON (pp.aid=a.aid)
   LEFT JOIN users u FORCE INDEX FOR JOIN (`PRIMARY`) ON (u.uid=pp.uid)
   $WHERE;",
    undef,
    $attr
  );

  my $list = $self->{list};

  if ($attr->{UID} && $self->{TOTAL} >= 0 && !$attr->{SKIP_TOTAL}) {
    $self->query(
      "SELECT
        COUNT(DISTINCT u.id) AS total_services,
        COUNT(u.id) AS total_services
      FROM users u
        INNER JOIN extfin_paids_periodic pp ON (u.uid=pp.uid)
        LEFT JOIN extfin_paids_types pt ON (pt.id=pp.type_id)
      WHERE u.uid = '$attr->{UID}';",
      undef,
      { INFO => 1 }
    );
  }

  return $list;
}

#**********************************************************
# fees
#**********************************************************
sub paid_change{
  my $self = shift;
  my ($attr) = @_;

  my %FIELDS = (
    ID          => 'id',
    DATE        => 'date',
    SUM         => 'sum',
    DESCRIBE    => 'comments',
    UID         => 'uid',
    AID         => 'aid',
    STATUS      => 'status',
    TYPE        => 'type_id',
    EXT_ID      => 'ext_id',
    STATUS_DATE => 'status_date',
    MACCONT_ID  => 'maccount_id'
  );

  $attr->{STATUS} = 0 if (!$attr->{STATUS});

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'extfin_paids',
    FIELDS       => \%FIELDS,
    OLD_INFO     => $self->paid_info($attr),
    DATA         => $attr
  });

  return $self;
}

#**********************************************************
# fees
#**********************************************************
sub paid_del{
  my $self = shift;
  my ($attr) = @_;

  $self->query_del( 'extfin_paids', $attr );

  return $self;
}

#**********************************************************
=head2 paid_info($attr)

=cut
#**********************************************************
sub paid_info{
  my $self = shift;
  my ($attr) = @_;

  $self->query( "SELECT date, sum, `comments` AS `describe`, uid, aid,
  status, status_date, type_id AS type, ext_id, maccount_id
   FROM extfin_paids
   WHERE id= ? ;",
    undef,
    { INFO => 1,
      Bind => [ $attr->{ID} ] }
  );

  return $self;
}

#**********************************************************
=head2 paids_list($attr)

=cut
#**********************************************************
sub paids_list{
  my $self = shift;
  my ($attr) = @_;

  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  my $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 100;

  if ( $attr->{INTERVAL} ){
    ($attr->{FROM_DATE}, $attr->{TO_DATE}) = split( /\//, $attr->{INTERVAL}, 2 );
  }

  my $GROUP = '';

  if ( $attr->{GROUP} ){
    $GROUP = "GROUP BY $attr->{GROUP}";
  }

  my $WHERE = $self->search_former( $attr, [
      [ 'ID',                 'INT',  'p.id',                              ],
      [ 'LOGIN',              'STR',  'u.id AS login',                    1],
      [ 'PT_NAME',            'STR',  'pt.name as pt_name',               1],
      [ 'UID',                'INT',  'p.uid',                             ],
      [ 'DATE',               'DATE', 'p.date',                           1],
      [ 'SUM',                'INT',  'p.sum',                            1],
      [ 'FROM_DATE|TO_DATE',  'DATE', "DATE_FORMAT(p.date, '%Y-%m-%d')",  1],
      [ 'STATUS',             'INT',  'p.status',                         1],
      [ 'TYPE',               'INT',  'p.type_id as type',                1],
      [ 'METHOD',             'INT',  'p.maccount_id as method',          1],
      [ 'COMMENTS',           'STR',  'p.comments as comments',           1],
      [ 'ADMIN',              'INT',  'a.id as admin',                    1],
      [ 'TOTAL_SUM',          'INT',  'SUM(p.sum) as total_sum',           ],
      [ 'EXT_ID',             'STR',  'p.ext_id',                         1],
      [ 'CLOSED',             'DATE', 'p.status_date as closed',          1],
    ],
    {
      WHERE        => 1,
      USE_USERS_PI => 1,
      SKIP_USERS_FIELDS => ['COMMENTS']
    }
  );

  my $EXT_TABLES = $self->{EXT_TABLES} || '';

  $self->query(
    "SELECT
      p.id,
    $self->{SEARCH_FIELDS}
      p.uid
    FROM extfin_paids p
    INNER JOIN admins a ON (a.aid=p.aid)
    INNER JOIN users u ON (u.uid=p.uid)
    LEFT JOIN extfin_paids_types pt ON (p.type_id=pt.id)
    $EXT_TABLES
    $WHERE
    $GROUP
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;",
      undef,
      $attr
  );

  my $list = $self->{list};

  if ( $self->{TOTAL} > 0 || $PG > 0 ){
    $self->query(
    "SELECT COUNT(p.id) AS total, SUM(p.sum) AS total_sum
      FROM extfin_paids p
    INNER JOIN admins a ON (a.aid=p.aid)
    LEFT JOIN extfin_paids_types pt ON (p.type_id=pt.id)
    INNER JOIN users u ON (u.uid=p.uid)
    $EXT_TABLES
    $WHERE;",
      undef,
      { INFO => 1 }
    );
  }

  return $list;
}

#**********************************************************
# fees
#**********************************************************
sub paid_reports{
  my $self = shift;
  my ($attr) = @_;

  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  my $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 100;

  my @WHERE_RULES = ("p.uid=u.uid and p.aid=a.aid");

  my $date = 'p.date';

  if ( $attr->{TYPE} ){
    if ( $attr->{TYPE} eq 'PAYMENT_METHOD' ){
      $date = "p.maccount_id";
    }
    elsif ( $attr->{TYPE} eq 'PAYMENT_TYPE' ){
      $date = "p.type_id";
    }
    elsif ( $attr->{TYPE} eq 'USER' ){
      $date = "u.id";
    }
    elsif ( $attr->{TYPE} eq 'ADMINS' ){
      $date = "a.id";
    }
  }

  if ( $attr->{INTERVAL} ){
    ($attr->{FROM_DATE}, $attr->{TO_DATE}) = split( /\//, $attr->{INTERVAL}, 2 );
  }
  elsif ( $attr->{MONTH} ){
    $date = "DATE_FORMAT(p.date, '%Y-%m-%d')";
  }
  else{
    $date = "DATE_FORMAT(p.date, '%Y-%m')";
  }

  my $WHERE = $self->search_former( $attr, [
      [ 'SUM', 'DATE', 'p.sum' ],
      [ 'FROM_DATE|TO_DATE', 'DATE', "DATE_FORMAT(p.date, '%Y-%m-%d')" ],
      [ 'DATE', 'DATE', "p.date" ],
      [ 'MONTH', 'DATE', "DATE_FORMAT(p.date, '%Y-%m')" ],
      [ 'STATUS', 'INT', 'p.status', ],
      [ 'TYPE', 'INT', 'p.type_id' ],
      [ 'PAYMENT_METHOD', 'INT', 'p.maccount_id' ],
      [ 'DESCRIBE', 'STR', 'p.descr' ],
      [ 'FIELDS', 'INT', 'p.type_id' ]
    ],
    { WHERE        => 1,
      WHERE_RULES  => \@WHERE_RULES,
      USERS_FIELDS => 1
    }
  );

  $self->query( "SELECT $date,
   SUM(if(p.status=0, 0, 1)),
   SUM(if(p.status=0, 0, p.sum)),
   count(p.id), 
   SUM(p.sum),
   p.uid
   FROM extfin_paids p, users u, admins a
  $WHERE
  GROUP BY 1
  ORDER BY $SORT $DESC ",
    undef,
    $attr
  );

  #  LIMIT $PG, $PAGE_ROWS;");

  my $list = $self->{list};

  if ( $self->{TOTAL} > 0 || $PG > 0 ){
    $self->query( "SELECT count(p.id) AS total, SUM(sum) AS sum
     FROM extfin_paids p, admins a, users u 
    WHERE p.uid=u.uid and p.aid=a.aid;",
      undef,
      { INFO => 1 }
    );
  }

  return $list;
}

#**********************************************************
=head2 paid_type_add($attr)

=cut
#**********************************************************
sub paid_type_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add( 'extfin_paids_types', \%{$attr} );

  return $self;
}

#**********************************************************
=head2 paid_type_change($attr)

=cut
#**********************************************************
sub paid_type_change{
  my $self = shift;
  my ($attr) = @_;

  $attr->{PERIODIC} = 0 if (!$attr->{PERIODIC});
  $attr->{MONTH_ALIGNMENT} = 0 if(!$attr->{MONTH_ALIGNMENT});

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'extfin_paids_types',
    DATA         => $attr
  });

  return $self;
}

#**********************************************************
=head2 paid_type_del($attr)

=cut
#**********************************************************
sub paid_type_del{
  my $self = shift;
  my ($attr) = @_;

  $self->query_del( 'extfin_paids_types', $attr );

  return $self;
}

#**********************************************************
# fees
#**********************************************************
sub paid_type_info{
  my $self = shift;
  my ($attr) = @_;

  $self->query( "SELECT id, name, sum, periodic, month_alignment
   FROM extfin_paids_types WHERE id=  ? ;",
    undef,
    { INFO => 1,
      Bind => [ $attr->{ID} ] }
  );

  return $self;
}

#**********************************************************
=head2 paid_types_list($attr)

=cut
#**********************************************************
sub paid_types_list{
  my $self = shift;
  my ($attr) = @_;

  my $WHERE = ($attr->{PERIODIC}) ? "WHERE periodic='$attr->{PERIODIC}'" : '';
  if (defined($attr->{ID})) {
    $WHERE = "WHERE id='$attr->{ID}'"
  }
  $self->query(
    "SELECT id, name, sum, periodic, month_alignment FROM extfin_paids_types
   $WHERE",
    undef,
    $attr
  );

  my $list = $self->{list};

  return $list;
}

#**********************************************************
=head2 extfin_debetors($attr)

=cut
#**********************************************************
sub extfin_debetors{
  my $self = shift;
  my ($attr) = @_;

  my @WHERE_RULES = ();

  my $ext_field = '';
  my %deposits = ();

  if ( $attr->{DATE} ){
    push @WHERE_RULES, "DATE_FORMAT(f.date, '%Y-%m-%d')<='$attr->{DATE}'";
    push @WHERE_RULES, "(f.last_deposit-f.sum<0) ";
    $attr->{DATE} = "'$attr->{DATE}'";
    $ext_field = "\@A:=(SELECT f.last_deposit-f.sum FROM fees f WHERE f.uid=\@uid and f.date<'2009-03-31' ORDER BY f.id DESC limit 1) AS debet,";
    $self->{DEPOSITS} = \%deposits;
  }
  else{
    push @WHERE_RULES, "( b.deposit < 0 or cb.deposit < 0 ) ";    # and (f.last_deposit >=0 and f.last_deposit-sum<0)";
    $ext_field = "\@A:=if(company.id IS NULL,b.deposit,cb.deposit) AS debet,";
    $attr->{DATE} = 'CURDATE()';
  }

  my $WHERE = $self->search_former( $attr, [
      [ 'STATUS', 'INT', 'u.disable' ],
    ],
    { WHERE        => 1,
      WHERE_RULES  => \@WHERE_RULES,
      USERS_FIELDS => 1
    }
  );

  $self->query( "SELECT \@uid:=u.uid, u.id, pi.contract_id,
   pi.fio,
   IF(pi.contract_date = '0000-00-00', u.registration, pi.contract_date) AS start_date,
   u.disable,
   internet.tp_id,
   $ext_field
   IF(DATEDIFF($attr->{DATE}, f.date) < 32, \@A, ''),
   IF(DATEDIFF($attr->{DATE}, f.date) > 33 AND DATEDIFF($attr->{DATE}, f.date) < 54 , \@A, ''),
   IF(DATEDIFF($attr->{DATE}, f.date) > 65 AND DATEDIFF($attr->{DATE}, f.date) < 96 , \@A, ''),
   IF(DATEDIFF($attr->{DATE}, f.date) > 97 AND DATEDIFF($attr->{DATE}, f.date) < 183 , \@A, ''),
   IF(DATEDIFF($attr->{DATE}, f.date) > 184 AND DATEDIFF($attr->{DATE}, f.date) < 365 , \@A, ''),
   IF(DATEDIFF($attr->{DATE}, f.date) > 365 , \@A, ''),

   u.uid
  FROM users u
     INNER JOIN fees f ON (u.uid = f.uid)
     LEFT JOIN users_pi pi ON (u.uid = pi.uid)
     LEFT JOIN bills b ON (u.bill_id = b.id)
     LEFT JOIN companies company ON  (u.company_id=company.id)
     LEFT JOIN bills cb ON  (company.bill_id=cb.id)
     LEFT JOIN internet_main internet ON  (u.uid=internet.uid)
$WHERE
GROUP BY f.uid
HAVING debet < 0
ORDER BY f.date DESC;",
    undef,
    $attr
  );

  my $list = $self->{list};

  return $list;
}

#**********************************************************
=head2 report_payments_fees()

=cut
#**********************************************************
sub report_payments_fees{
  my $self = shift;
  my ($attr) = @_;

  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  my $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $date = '';
  my @WHERE_RULES = ();
  my @FEES_WHERE_RULES = ();
  my @PAYMENTS_WHERE_RULES = ();

  if ( $attr->{GIDS} ){
    push @WHERE_RULES, "u.gid IN ( $attr->{GIDS} )";
  }
  elsif ( $attr->{GID} ){
    push @WHERE_RULES, "u.gid='$attr->{GID}'";
  }

  if ( $attr->{BILL_ID} ){
    push @WHERE_RULES, "f.BILL_ID IN ( $attr->{BILL_ID} )";
  }

  if ( $attr->{DATE} ){
    push @FEES_WHERE_RULES, "(f.date >= '$attr->{DATE} 00:00:00' AND f.date <= '$attr->{DATE} 24:00:00')";
    push @PAYMENTS_WHERE_RULES, "(p.date >= '$attr->{DATE} 00:00:00' AND p.date <= '$attr->{DATE} 24:00:00')";
  }
  elsif ( $attr->{INTERVAL} ){
    my ($from, $to) = split( /\//, $attr->{INTERVAL}, 2 );
    push @FEES_WHERE_RULES, @{ $self->search_expr( ">=$from", 'DATE', 'DATE_FORMAT(f.date, \'%Y-%m-%d\')' ) },
      @{ $self->search_expr( "<=$to", 'DATE', 'DATE_FORMAT(f.date, \'%Y-%m-%d\')' ) };

    push @PAYMENTS_WHERE_RULES, @{ $self->search_expr( ">=$from", 'DATE', 'DATE_FORMAT(p.date, \'%Y-%m-%d\')' ) },
      @{ $self->search_expr( "<=$to", 'DATE', 'DATE_FORMAT(p.date, \'%Y-%m-%d\')' ) };
  }
  elsif ( defined( $attr->{MONTH} ) ){
    push @FEES_WHERE_RULES, "(f.date>='$attr->{MONTH}-01 00:00:00' AND f.date<='$attr->{MONTH}-31 24:00:00')";
    push @PAYMENTS_WHERE_RULES, "(p.date>='$attr->{MONTH}-01 00:00:00' AND p.date<='$attr->{MONTH}-31 24:00:00')";
    $date = "DATE_FORMAT(p.date, '%Y-%m-%d')";
  }
  else{
    $date = "DATE_FORMAT(p.date, '%Y-%m')";
  }

  my $GROUP = 1;
  my $type = $attr->{TYPE} || q{};
  my $ext_tables = '';

  if ( $type eq 'HOURS' ){
    $date = "DATE_FORMAT(p.date, '%H')";
  }
  elsif ( $type eq 'DAYS' ){
    $date = "DATE_FORMAT(f.date, '%Y-%m-%d')";
  }
  elsif ( $type eq 'METHOD' ){
    $date = "f.method";
  }
  elsif ( $type eq 'ADMINS' ){
    $date = "a.id";
  }
  elsif ( $type eq 'FIO' ){
    $ext_tables = 'LEFT JOIN users_pi pi ON (u.uid=pi.uid)';
    $date = "pi.fio";
    $GROUP = 5;
  }
  elsif ( $type eq 'COMPANIES' ){
    $ext_tables = 'LEFT JOIN companies c ON (u.company_id=c.id)';
    $date = "c.name";
  }
  elsif ( $date eq '' ){
    $date = "u.id";
  }

  if ( defined( $attr->{METHODS} ) and $attr->{METHODS} ne '' ){
    push @WHERE_RULES, "f.method IN ($attr->{METHODS}) ";
  }

  my $WHERE = ($#WHERE_RULES > -1) ? "AND " . join( ' AND ', @WHERE_RULES ) : '';
  my $FEES_WHERE = ($#FEES_WHERE_RULES > -1) ? "AND " . join( ' AND ', @FEES_WHERE_RULES ) : '';
  my $PAYMENTS_WHERE = ($#PAYMENTS_WHERE_RULES > -1) ? "AND " . join( ' AND ', @PAYMENTS_WHERE_RULES ) : '';

  $GROUP = 'u.uid';
  $self->query( "SELECT '', u.id,  pi.fio,
      (SELECT SUM(p.sum) FROM payments p
         WHERE u.uid=p.uid $PAYMENTS_WHERE),
      SUM(f.sum) AS sum, u.uid
      FROM users u
      LEFT JOIN users_pi pi  ON (u.uid=pi.uid)
      LEFT JOIN fees f  ON (u.uid=f.uid $FEES_WHERE)
      $ext_tables
      WHERE u.deleted=0 $WHERE
      GROUP BY $GROUP
      ORDER BY $SORT $DESC;",
    undef,
    $attr
  );

  my $list = $self->{list};

  $self->{USERS_TOTAL} = '0.00';
  $self->{PAYMENTS_TOTAL} = '0.00';
  $self->{FEES_TOTAL} = '0.00';

  if ( $self->{TOTAL} > 0 || $PG > 0 ){
    $PAYMENTS_WHERE =~ s/AND//;
    $FEES_WHERE = $PAYMENTS_WHERE;
    $FEES_WHERE =~ s/p\./f\./g;
    $self->query( "SELECT count(DISTINCT u.uid) AS users_total,
      (SELECT SUM(p.sum) FROM payments p WHERE $PAYMENTS_WHERE) AS payments_total,
      (SELECT SUM(f.sum) FROM fees f WHERE $FEES_WHERE) AS fees_sum
      FROM users u
      WHERE u.deleted=0 $WHERE;",
      undef,
      { INFO => 1 }
    );
  }

  return $list;
}

#**********************************************************
# report
#**********************************************************
sub report_users_balance{
  my $self = shift;
  my ($attr) = @_;

  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  my $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $date = '';
  my @WHERE_RULES = ();
  my @FEES_WHERE_RULES = ();
  my @PAYMENTS_WHERE_RULES = ();

  if ( $attr->{GIDS} ){
    push @WHERE_RULES, "u.gid IN ( $attr->{GIDS} )";
  }
  elsif ( $attr->{GID} ){
    push @WHERE_RULES, "u.gid='$attr->{GID}'";
  }

  if ( $attr->{BILL_ID} ){
    push @WHERE_RULES, "f.bill_id IN ( $attr->{BILL_ID} )";
  }

  if ( $attr->{DATE} ){
    push @FEES_WHERE_RULES, "DATE_FORMAT(f.date, '%Y-%m-%d')='$attr->{DATE}'";
    push @PAYMENTS_WHERE_RULES, "DATE_FORMAT(f.date, '%Y-%m-%d')='$attr->{DATE}'";
  }
  elsif ( $attr->{INTERVAL} ){
    my ($from, $to) = split( /\//, $attr->{INTERVAL}, 2 );
    push @FEES_WHERE_RULES, @{ $self->search_expr( ">=$from", 'DATE', 'DATE_FORMAT(f.date, \'%Y-%m-%d\')' ) },
      @{ $self->search_expr( "<=$to", 'DATE', 'DATE_FORMAT(f.date, \'%Y-%m-%d\')' ) };

    push @PAYMENTS_WHERE_RULES, @{ $self->search_expr( ">=$from", 'DATE', 'DATE_FORMAT(p.date, \'%Y-%m-%d\')' ) },
      @{ $self->search_expr( "<=$to", 'DATE', 'DATE_FORMAT(p.date, \'%Y-%m-%d\')' ) };
  }
  elsif ( defined( $attr->{MONTH} ) ){
    push @FEES_WHERE_RULES, "(f.date>='$attr->{MONTH}-01 00:00:00' AND f.date<='$attr->{MONTH}-31 24:00:00')";
    push @PAYMENTS_WHERE_RULES, "(p.date>='$attr->{MONTH}-01 00:00:00' AND p.date<='$attr->{MONTH}-31 24:00:00')";
    $date = "DATE_FORMAT(f.date, '%Y-%m-%d')";
  }
  else{
    $date = "DATE_FORMAT(f.date, '%Y-%m')";
  }

  my $GROUP = 1;
  my $type = $attr->{TYPE} || q{};
  my $ext_tables = '';

  if ( $type eq 'HOURS' ){
    $date = "DATE_FORMAT(f.date, '%H')";
  }
  elsif ( $type eq 'DAYS' ){
    $date = "DATE_FORMAT(f.date, '%Y-%m-%d')";
  }
  elsif ( $type eq 'METHOD' ){
    $date = "f.method";
  }
  elsif ( $type eq 'ADMINS' ){
    $date = "a.id";
  }
  elsif ( $type eq 'FIO' ){
    $ext_tables = 'LEFT JOIN users_pi pi ON (u.uid=pi.uid)';
    $date = "pi.fio";
    $GROUP = 5;
  }
  elsif ( $type eq 'COMPANIES' ){
    $ext_tables = 'LEFT JOIN companies c ON (u.company_id=c.id)';
    $date = "c.name";
  }
  elsif ( $date eq '' ){
    $date = "u.id";
  }

  if ( defined( $attr->{METHODS} ) and $attr->{METHODS} ne '' ){
    push @WHERE_RULES, "f.method IN ($attr->{METHODS}) ";
  }

  my $WHERE = ($#WHERE_RULES > -1) ? "AND " . join( ' AND ', @WHERE_RULES ) : '';
  my $PAYMENTS_WHERE = ($#PAYMENTS_WHERE_RULES > -1) ? "AND " . join( ' AND ', @PAYMENTS_WHERE_RULES ) : '';

  $GROUP = 'u.uid';
  $self->query( "SELECT u.id, pi.fio, \@payments := (select SUM(p.sum) FROM payments p WHERE u.uid=p.uid $PAYMENTS_WHERE),
       \@fees := SUM(f.sum),
       (select SUM(p.sum) FROM payments p WHERE u.uid=p.uid $PAYMENTS_WHERE) - SUM(f.sum),
       u.uid
      FROM users u 
     LEFT JOIN users_pi pi ON (u.uid = pi.uid)
     LEFT JOIN bills b ON (u.bill_id = b.id)
     LEFT JOIN companies company ON  (u.company_id=company.id) 
     LEFT JOIN bills cb ON  (company.bill_id=cb.id)
     LEFT JOIN fees f ON  (f.uid=u.uid)
      $ext_tables
      WHERE u.deleted=0 $WHERE 
      GROUP BY $GROUP
      ORDER BY $SORT $DESC;",
    undef,
    $attr
  );

  my $list = $self->{list};

  $self->{USERS_TOTAL} = '0.00';
  $self->{PAYMENTS_TOTAL} = '0.00';
  $self->{FEES_TOTAL} = '0.00';
  if ( $self->{TOTAL} > 0 || $PG > 0 ){
    $self->query( "SELECT count(DISTINCT u.uid) AS users_total,
       SUM(if(company.id IS NULL, b.deposit, cb.deposit)) AS payments_total,
       SUM(if(u.company_id=0, u.credit,
          if (u.credit=0, company.credit, u.credit))) AS fees_sum
     FROM users u
     LEFT JOIN bills b ON (u.bill_id = b.id)
     LEFT JOIN companies company ON  (u.company_id=company.id) 
     LEFT JOIN bills cb ON  (company.bill_id=cb.id)
    WHERE u.deleted=0 $WHERE;",
      undef,
      { INFO => 1 }
    );
  }

  return $list;
}


#**********************************************************
#
#**********************************************************
sub company_reports{
#  my $self = shift;
#
#  my $sql = "SELECT c.id, c.name
#    FROM companies c
#    INNER JOIN users u ON (u.company_id=c.id)
#    ";
}





#**********************************************************
=head2 extfin_report_balance_info() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub extfin_report_balance_info {
  my $self = shift;
  my ($attr) = @_;

  $self->query( "SELECT *
   FROM extfin_balance_reports
  WHERE bill_id = ?  and period = ? ;",
    undef,
    { INFO => 1,
      Bind => [ $attr->{BILL_ID}, $attr->{PERIOD} ] }
  );

  return $self;
}

#**********************************************************
=head2 extfin_report_balance_list() -

  Arguments:
    ATTRIBUTES -
  Returns:

  Examples:

=cut
#**********************************************************
sub extfin_report_balance_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  my $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my @WHERE_RULES = ();
  if($attr->{PERIOD}){
    push @WHERE_RULES, "ebr.period = '$attr->{PERIOD}'";
  }

  if($attr->{GID}){
    my @groups = split(',', $attr->{GID});
    push @WHERE_RULES, '(u.gid =' . join(" or u.gid =", @groups) . ')';
  }

  my $WHERE = $self->search_former(
    $attr,
    [
      [ 'ID',      'INT',  'ebr.id',      1 ],
      [ 'PERIOD',  'STR',  'ebr.period',  1 ],
      [ 'SUM',     'STR',  'ebr.sum',     1 ],
      [ 'BILL_ID', 'STR',  'ebr.bill_id', 1 ],
      [ 'AID',     'STR',  'ebr.aid',     1 ],
      [ 'DATE',    'STR',  'ebr.date',    1 ],
    ],
    { WHERE => 1,
      WHERE_RULES => \@WHERE_RULES
    }
  );

  $self->query(
    "SELECT
    ebr.id,
    ebr.period,
    ebr.sum,
    ebr.bill_id,
    ebr.aid,
    ebr.date,
    b.uid,
    pi.fio,
    pi.contract_id,
    u.gid,
    (select SUM(p.sum) FROM payments p WHERE p.uid = b.uid AND p.date>='$attr->{PERIOD}-01 00:00:00' AND p.date<='$attr->{PERIOD}-31 23:59:59')  as payments_sum,
    (select SUM(f.sum) FROM fees f WHERE f.uid = b.uid AND f.date>='$attr->{PERIOD}-01 00:00:00' AND f.date<='$attr->{PERIOD}-31 23:59:59')  as fees_sum
    FROM extfin_balance_reports ebr
    LEFT JOIN bills b ON (b.id = ebr.bill_id)
    LEFT JOIN users_pi pi ON (pi.uid = b.uid)
    LEFT JOIN users u ON (u.uid = b.uid)
    $WHERE
    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list};

  return $self->{list} if ($self->{TOTAL} < 1);

  $self->query(
    "SELECT COUNT(*) AS total, SUM(ebr.sum) AS total_sum
   FROM extfin_balance_reports ebr
   $WHERE",
    undef,
    { INFO => 1 }
  );

  return $list;
}

#*******************************************************************

=head2 function extfin_report_balance_del() - delete cashbox

  Arguments:
    $attr

  Returns:

  Examples:
    $Crm->extfin_report_balance_del( {PERIOD => 1} );

=cut

#*******************************************************************
sub extfin_report_balance_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('extfin_balance_reports', $attr, { PERIOD => $attr->{PERIOD} });

  return $self;
}

#**********************************************************
=head2 extfin_report_balance_add() - add new balance

  Arguments:
    $attr  -
  Returns:

  Examples:

=cut
#**********************************************************
sub extfin_report_balance_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('extfin_balance_reports', {%$attr, DATE => $attr->{DATE} || 'NOW()'});

  return $self;
}


1
