package Abon;

=head1 NAME

  Periodic fess managment functions

=cut

use strict;
our $VERSION = 2.00;
use parent qw( dbcore );
my $MODULE = 'Abon';
my ($admin, $CONF);
#my ($SORT, $DESC, $PG, $PAGE_ROWS);

#**********************************************************
# Init
#**********************************************************
sub new{
  my $class = shift;
  my $db = shift;
  ($admin, $CONF) = @_;

  my $self = { };
  bless( $self, $class );

  $admin->{MODULE} = $MODULE;

  $self->{db} = $db;
  $self->{admin} = $admin;
  $self->{conf} = $CONF;

  return $self;
}

#**********************************************************
=head1 del(attr)

=cut
#**********************************************************
sub del{
  my $self = shift;
  my ($attr) = @_;

  $admin->{MODULE}=$MODULE;
  $self->query_del( 'abon_user_list', undef, { uid => $self->{UID} } );

  my @del_descr = ();
  if($attr->{UID}) {
    push @del_descr, "UID: $attr->{UID}";
  }
  if ($attr->{ID}) {
    push @del_descr, "ID: $attr->{ID}";
  }
  if($attr->{COMMENTS}) {
    push @del_descr, "COMMENTS: $attr->{COMMENTS}";
  }

  $admin->action_add( $self->{UID}, join(' ', @del_descr), { TYPE => 10 } );

  return $self->{result};
}

#**********************************************************
=head2 tariff_info($id)

=cut
#**********************************************************
sub tariff_info{
  my $self = shift;
  my ($id) = @_;

  my @WHERE_RULES = ("id='$id'");
  my $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join( ' and ', @WHERE_RULES ) : '';

  $self->query( "SELECT * FROM abon_tariffs
    $WHERE;",
    undef,
    { INFO => 1 }
  );

  return $self;
}

#**********************************************************
=head2 tariff_add($attr)

=cut
#**********************************************************
sub tariff_add{
  my $self = shift;
  my ($attr) = @_;

  $self->query_add( 'abon_tariffs', {
    %$attr,
    DOMAIN_ID => $admin->{DOMAIN_ID} || 0
  });

  return [] if ($self->{errno});

  $self->{ID} = $self->{INSERT_ID};

  $admin->system_action_add("ABON_ID:$attr->{ID}", { TYPE => 1 });

  return $self;
}

#**********************************************************
=head2 tariff_change($attr)

=cut
#**********************************************************
sub tariff_change{
  my $self = shift;
  my ($attr) = @_;

  $attr->{CREATE_ACCOUNT} = 0 if (!$attr->{CREATE_ACCOUNT});
  $attr->{FEES_TYPE} = 0 if (!$attr->{FEES_TYPE});
  $attr->{NOTIFICATION_ACCOUNT} = 0 if (!$attr->{NOTIFICATION_ACCOUNT});
  $attr->{ALERT} = 0 if (!$attr->{ALERT});
  $attr->{ALERT_ACCOUNT} = 0 if (!$attr->{ALERT_ACCOUNT});
  $attr->{PERIOD_ALIGNMENT} = 0 if (!$attr->{PERIOD_ALIGNMENT});
  $attr->{ACTIVATE_NOTIFICATION} = 0 if (!$attr->{ACTIVATE_NOTIFICATION});
  $attr->{VAT} = 0 if (!$attr->{VAT});
  $attr->{NONFIX_PERIOD} = 0 if (!$attr->{NONFIX_PERIOD});
  $attr->{DISCOUNT} = 0 if (!$attr->{DISCOUNT});
  $attr->{EXT_BILL_ACCOUNT} = 0 if (!$attr->{EXT_BILL_ACCOUNT});
  $attr->{USER_PORTAL} = 0 if (!$attr->{USER_PORTAL});
  $attr->{MANUAL_ACTIVATE} = 0 if (!$attr->{MANUAL_ACTIVATE});
  $attr->{PROMOTIONAL} = 0 if (!$attr->{PROMOTIONAL});

  $attr->{ID} = $attr->{ABON_ID};

  $self->changes({
    CHANGE_PARAM    => 'ID',
    TABLE           => 'abon_tariffs',
    DATA            => $attr,
    EXT_CHANGE_INFO => "ABON_ID:$attr->{ABON_ID}"
  });

  $self->tariff_info( $attr->{ABON_ID} );
  return $self->{result};
}

#**********************************************************
=head2 tariff_del($id)

=cut
#**********************************************************
sub tariff_del{
  my $self = shift;
  my ($id) = @_;

  $self->query_del( 'abon_tariffs', { ID => $id } );

  $admin->system_action_add( "ABON_ID:$id", { TYPE => 10 } );
  return $self->{result};
}

#@deprecated Use tariff_list_former instead, in future delete and rename new method
#**********************************************************
=head2 tariff_list($attr)

=cut
#**********************************************************
sub tariff_list{
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  my $WHERE = $self->search_former( $attr, [
      [ 'IDS',              'INT', 'abon_tariffs.id'          ],
      [ 'EXT_BILL_ACCOUNT', 'INT', 'abon_tariffs.ext_bill_account',      1 ],
      [ 'DOMAIN_ID',        'INT', 'abon_tariffs.domain_id',  ],
      [ 'NAME',             'INT', 'abon_tariffs.name',       ],
      [ 'PLUGIN',           'STR', 'abon_tariffs.plugin',   1 ],
      [ 'ACTIVATE_PRICE',   'INT', 'abon_tariffs.activate_price',   1 ],
      [ 'EXT_SERVICE_ID',   'STR', 'abon_tariffs.ext_service_id', 1 ],
    ],
    { WHERE => 1,
    }
  );

  $self->query( "SELECT name as tp_name, price, period, payment_type,
      priority,
      period_alignment,
      COUNT(ul.uid) AS user_count,
      abon_tariffs.id AS tp_id,
      fees_type,
      create_account,
      ext_cmd,
      activate_notification,
      vat,
      description,
      abon_tariffs.discount,
      manual_activate,
      user_portal,
      promo_period,
      $self->{SEARCH_FIELDS}
      \@nextfees_date := if (nonfix_period = 1,
          if (period = 0, curdate() + INTERVAL 2 DAY,
          if (period = 1, curdate() + INTERVAL 2 MONTH,
            if (period = 2, curdate() + INTERVAL 6 MONTH,
              if (period = 3, curdate() + INTERVAL 12 MONTH,
                if (period = 4, curdate() + INTERVAL 2 YEAR,
                  '-'
                )
              )
            )
          )
        ),
        if (period = 0, CURDATE()+ INTERVAL 1 DAY,
          if (period = 1, DATE_FORMAT(curdate() + INTERVAL 2 MONTH, '%Y-%m-01'),
            if (period = 2, CONCAT(YEAR(curdate() + INTERVAL 6 MONTH), '-' ,(QUARTER((curdate() + INTERVAL 6 MONTH))*6-2), '-01'),
              if (period = 3, CONCAT(YEAR(curdate() + INTERVAL 12 MONTH), '-', if(MONTH(curdate() + INTERVAL 12 MONTH) > 12, '06', '01'), '-01'),
                if (period = 4, DATE_FORMAT(curdate() + INTERVAL 2 YEAR, '%Y-01-01'),
                  '-'
                )
              )
            )
          )
        )
      ) AS next_abon_date
      FROM abon_tariffs
      LEFT JOIN abon_user_list ul ON (abon_tariffs.id=ul.tp_id)
      $WHERE
      GROUP BY abon_tariffs.id
      ORDER BY $SORT $DESC;",
    undef,
    $attr
  );

  return $self->{list};
}

#**********************************************************
=head2 tariff_list_former($attr)

  Created to avoid legacy compatibility with tariff_list

=cut
#**********************************************************
sub tariff_list_former {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $next_abon_query = "if (nonfix_period = 1,
      if (period = 0, curdate() + INTERVAL 2 DAY,
        if (period = 1, curdate() + INTERVAL 2 MONTH,
          if (period = 2, curdate() + INTERVAL 6 MONTH,
            if (period = 3, curdate() + INTERVAL 12 MONTH,
              if (period = 4, curdate() + INTERVAL 2 YEAR,
                '-'
              )
            )
          )
        )
      ),
      if (period = 0, CURDATE()+ INTERVAL 1 DAY,
        if (period = 1, DATE_FORMAT(curdate() + INTERVAL 2 MONTH, '%Y-%m-01'),
          if (period = 2, CONCAT(YEAR(curdate() + INTERVAL 6 MONTH), '-' ,(QUARTER((curdate() + INTERVAL 6 MONTH))*6-2), '-01'),
            if (period = 3, CONCAT(YEAR(curdate() + INTERVAL 12 MONTH), '-', if(MONTH(curdate() + INTERVAL 12 MONTH) > 12, '06', '01'), '-01'),
              if (period = 4, DATE_FORMAT(curdate() + INTERVAL 2 YEAR, '%Y-01-01'),
                '-'
              )
            )
          )
        )
      )
    ) AS next_abon_date";

  my $WHERE = $self->search_former( $attr, [
    [ 'ABON_ID',               'INT', 'at.id',                         1 ],
    [ 'IDS',                   'INT', 'at.id'                            ],
    [ 'TP_ID',                 'INT', 'at.id AS tp_id',                1 ],
    [ 'EXT_BILL_ACCOUNT',      'INT', 'at.ext_bill_account',           1 ],
    [ 'DOMAIN_ID',             'INT', 'at.domain_id',                    ],
    [ 'TP_NAME',               'STR', 'at.name AS tp_name',            1 ],
    [ 'FEES_TYPE',             'INT', 'at.fees_type',                  1 ],
    [ 'PAYMENT_TYPE',          'INT', 'at.payment_type',               1 ],
    [ 'PLUGIN',                'STR', 'at.plugin',                     1 ],
    [ 'NEXT_ABON_DATE',        'STR', $next_abon_query,                1 ],
    [ 'EXT_SERVICE_ID',        'STR', 'at.ext_service_id',             1 ],
    [ 'DESCRIPTION',           'STR', 'at.description',                1 ],
    [ 'USER_DESCRIPTION',      'STR', 'at.user_description',           1 ],
    [ 'PRICE',                 'INT', 'at.price',                      1 ],
    [ 'PERIOD',                'INT', 'at.period',                     1 ],
    [ 'PRIORITY',              'INT', 'at.priority',                   1 ],
    [ 'PERIOD_ALIGNMENT',      'INT', 'at.period_alignment',           1 ],
    [ 'DISCOUNT',              'INT', 'at.discount',                   1 ],
    [ 'USER_COUNT',            'INT', 'COUNT(ul.uid) AS user_count',   1 ],
    [ 'CREATE_ACCOUNT',        'INT', 'at.create_account',             1 ],
    [ 'EXT_CMD',               'STR', 'at.ext_cmd',                    1 ],
    [ 'ACTIVATE_NOTIFICATION', 'INT', 'at.activate_notification',      1 ],
    [ 'VAT',                   'INT', 'at.vat',                        1 ],
    [ 'MANUAL_ACTIVATE',       'INT', 'at.manual_activate',            1 ],
    [ 'USER_PORTAL',           'INT', 'at.user_portal',                1 ],
    [ 'NONFIX_PERIOD',         'INT', 'at.nonfix_period',              1 ],
    [ 'CATEGORY_ID',           'INT', 'at.category_id',                1 ],
    [ 'ACTIVATE_PRICE',        'INT', 'at.activate_price',             1 ],
    [ 'PROMOTIONAL',           'INT', 'at.promotional',                1 ],
  ],
    { WHERE => 1 }
  );

  $self->query( "SELECT
      $self->{SEARCH_FIELDS}
      at.id
      FROM abon_tariffs at
      LEFT JOIN abon_user_list ul ON (at.id=ul.tp_id)
      LEFT JOIN abon_categories ac ON (at.category_id=ac.id)
      $WHERE
      GROUP BY at.id
      ORDER BY $SORT $DESC
      LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  return $self->{list};
}

#**********************************************************
=head2 user_list($attr)

=cut
#**********************************************************
sub user_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my @WHERE_RULES = ("u.uid=ul.uid", "at.id=ul.tp_id");
  $self->{EXT_TABLES} = '';

  my $next_abon_query = "if (at.nonfix_period = 1,
      if (at.period = 0, ul.date+ INTERVAL 1 DAY,
        if (at.period = 1, ul.date + INTERVAL 1 MONTH,
          if (at.period = 2, ul.date + INTERVAL 3 MONTH,
            if (at.period = 3, ul.date + INTERVAL 6 MONTH,
              if (at.period = 4, ul.date + INTERVAL 1 YEAR,
                '-'
              )
            )
          )
        )
      )
      ,

      if (at.period = 0, ul.date+ INTERVAL 1 DAY,
        if (at.period = 1, DATE_FORMAT(ul.date + INTERVAL 1 MONTH, '%Y-%m-01'),
          if (at.period = 2, CONCAT(YEAR(ul.date + INTERVAL 3 MONTH), '-' ,(QUARTER((ul.date + INTERVAL 3 MONTH))*3-2), '-01'),
            if (at.period = 3, CONCAT(YEAR(ul.date + INTERVAL 6 MONTH), '-', if(MONTH(ul.date + INTERVAL 6 MONTH) > 6, '06', '01'), '-01'),
              if (at.period = 4, DATE_FORMAT(ul.date + INTERVAL 1 YEAR, '%Y-01-01'),
                '-'
                )
              )
            )
          )
        )
      ) AS next_abon";
  my $WHERE = $self->search_former( $attr, [
      [ 'ABON_ID',    'INT', 'at.id',               1 ],
      [ 'COMMENTS',   'STR', 'ul.comments',         1 ],
      [ 'DATE',       'INT', 'ul.date',             1 ],
      [ 'FEES_PERIOD','INT', 'ul.fees_period',      1 ],
      [ 'MANUAL_FEE', 'INT', 'ul.manual_fee',       1 ],
      [ 'TP_NAME',    'STR', 'at.name AS tp_name',  1 ],
      [ 'TP_ID',      'INT', 'at.id AS tp_id',      1 ],
      [ 'NEXT_ABON',  'STR', $next_abon_query,      1 ],
      [ 'PRICE',        'INT', 'at.price',          1 ],
      [ 'PERIOD',     'STR', 'at.period',           1 ],
      [ 'SERVICE_COUNT', 'STR', 'ul.service_count', 1 ]
    ],
    {
      WHERE             => 1,
      WHERE_RULES       => \@WHERE_RULES,
      USE_USER_PI      => 1,
      USERS_FIELDS_PRE => 1,
      SKIP_USERS_FIELDS => [ 'COMMENTS' ]
    }
  );

  if ($attr->{TP_ID}) {
    if ($attr->{TP_ID} =~ /, /) {
      $WHERE .= " AND ul.tp_id IN ($attr->{TP_ID})";
    }
    else {
      $WHERE .= " AND ul.tp_id = $attr->{TP_ID}";
    }
  }

  my $EXT_TABLE = $self->{EXT_TABLES};

  $self->query( "SELECT $self->{SEARCH_FIELDS} u.uid
    FROM (users u, abon_user_list ul, abon_tariffs at)
    $EXT_TABLE
    $WHERE
    GROUP BY ul.uid, ul.tp_id
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list} || [];

  if ( $self->{TOTAL} > 0 ){
    $self->query( "SELECT COUNT(u.uid) AS total
      FROM (users u, abon_user_list ul, abon_tariffs at)
      $WHERE",
      undef,
      { INFO => 1 }
    );
  }

  return $list;
}

#**********************************************************
=head2  user_tariff_list($uid, $attr)

=cut
#**********************************************************
sub user_tariff_list{
  my $self = shift;
  my ($uid, $attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my @WHERE_RULES = ();

  if($admin->{DOMAIN_ID}) {
    push @WHERE_RULES, "at.domain_id='$admin->{DOMAIN_ID}'";
  }

  if ( $attr->{ACTIVE_ONLY} ){
    push @WHERE_RULES, "ul.uid>0";
  }

  my $WHERE = $self->search_former( $attr, [
      [ 'USER_PORTAL',  'INT', 'at.user_portal',  1 ],
      [ 'PAYMENT_TYPE', 'INT', 'at.payment_type', 1 ],
      [ 'SERVICE_LINK', 'STR', 'at.service_link', 1 ],
      [ 'SERVICE_IMG',  'STR', 'at.service_img',  1 ],
      [ 'FEES_PERIOD',  'INT', 'at.fees_period',  1 ],
      [ 'PERIOD_ALIGNMENT', 'INT', 'at.period_alignment',  1 ],
      [ 'SERVICE_RECOVERY', 'INT', 'at.service_recovery',  1 ],
      [ 'ID',            'STR', 'at.id',             ],
      [ 'CATEGORY_ID',   'INT', 'at.category_id',  1 ],
      #[ 'UID',          'INT', 'ul.uid',          1 ],
    ],
    { WHERE       => 1,
      WHERE_RULES => \@WHERE_RULES
    }
  );

  $self->query( "SELECT
      at.name as tp_name,
      IF(ul.comments <> '', ul.comments, '') AS comments,
      at.price,
      at.period,
      at.discount as reduction_fee,
      at.description,
      at.user_description,
      SUM(ul.service_count) AS service_count,
      ul.fees_period,
      MAX(ul.date) AS date,
      IF (at.nonfix_period = 1,
      IF (at.period = 0, ul.date+ INTERVAL 1 DAY,
        IF (at.period = 1, ul.date + INTERVAL 1 MONTH,
          IF (at.period = 2, ul.date + INTERVAL 3 MONTH,
            IF (at.period = 3, ul.date + INTERVAL 6 MONTH,
              IF (at.period = 4, ul.date + INTERVAL 1 YEAR,
                '-'
                )
              )
            )
          )
        ),
        \@next_abon := if (at.period = 0, ul.date+ INTERVAL 1 DAY,
        IF (at.period = 1, DATE_FORMAT(ul.date + INTERVAL 1 MONTH, '%Y-%m-01'),
          IF (at.period = 2, CONCAT(YEAR(ul.date + INTERVAL 3 MONTH), '-' ,(QUARTER((ul.date + INTERVAL 3 MONTH))*3-2), '-01'),
            IF (at.period = 3, CONCAT(YEAR(ul.date + INTERVAL 6 MONTH), '-', if(MONTH(ul.date + INTERVAL 6 MONTH) > 6, '06', '01'), '-01'),
              IF (at.period = 4, DATE_FORMAT(ul.date + INTERVAL 1 YEAR, '%Y-01-01'),
                '-'
                )
              )
            )
          )
        )
        ) AS next_abon,
    ul.manual_fee,
    MAX(ul.discount) AS discount,
    COUNT(ul.uid) AS active_service,
    ul.notification1,
    ul.notification1_account_id,
    ul.notification2,
    ul.create_docs,
    ul.send_docs,
    ul.personal_description,
    at.manual_activate,
    at.plugin,
    at.promo_period,
    $self->{SEARCH_FIELDS}
    at.id,
    IF (\@next_abon < CURDATE(), 1, 0) AS missing
      FROM abon_tariffs at
      LEFT JOIN abon_user_list ul ON (at.id=ul.tp_id AND ul.uid='$uid')
      LEFT JOIN abon_categories ac ON (at.category_id=ac.id)
      $WHERE
      GROUP BY at.id
      ORDER BY $SORT $DESC;",
    undef,
    $attr
  );

  my $list = $self->{list} || [];

  return $list;
}

#**********************************************************
=head2 user_tariff_summary($attr)

=cut
#**********************************************************
sub user_tariff_summary{
  my $self = shift;
  my ($attr) = @_;

  my $WHERE = $self->search_former( $attr, [
      [ 'UID', 'INT', 'uid', 1 ],
    ],
    { WHERE => 1 }
  );

  $self->query( "SELECT COUNT(*) AS total_active,
    SUM(IF(date<CURDATE() - INTERVAL 30 DAY, 1, 0)) AS lost_fee
    FROM abon_user_list $WHERE;",
    undef,
    { INFO => 1 } );

  return $self;
}

#**********************************************************
=head1 user_tariff_add()

  Attributes:
    $attr

=cut
#**********************************************************
sub user_tariff_add {
  my $self = shift;
  my ($attr) = @_;

  my $date = 'CURDATE()';
  my $tp_id = $attr->{TP_ID};
  $admin->{MODULE} = $MODULE;

  if ($attr->{DATE} && $attr->{DATE} ne '0000-00-00') {
    $date = !$attr->{PERIOD} ? $attr->{DATE} : "
      if ($attr->{PERIOD} = 0, '$attr->{DATE}' -  INTERVAL 1 DAY,
        if ($attr->{PERIOD} = 1, '$attr->{DATE}' - INTERVAL 1 MONTH,
          if ($attr->{PERIOD} = 2, '$attr->{DATE}' - INTERVAL 3 MONTH,
            if ($attr->{PERIOD} = 3, '$attr->{DATE}' - INTERVAL 6 MONTH,
              if ($attr->{PERIOD} = 4, '$attr->{DATE}' - INTERVAL 1 YEAR,
                CURDATE()
              )
            )
          )
        )
      )";
  }

  $self->query("INSERT INTO abon_user_list SET
        uid = ?,
        tp_id = ?,
        comments = ?,
        date = $date,
        discount = ?,
        create_docs = ?,
        send_docs = ?,
        service_count = ?,
        fees_period = ?,
        manual_fee = ?,
        personal_description = ?;",
    'do',
    {
      Bind => [
        $attr->{UID},
        $tp_id,
        ($attr->{COMMENTS} || ''),
        $attr->{DISCOUNT} || 0,
        $attr->{CREATE_DOCS} || 0,
        $attr->{SEND_DOCS} || 0,
        $attr->{SERVICE_COUNT} || 1,
        $attr->{FEES_PERIOD} || 0,
        $attr->{MANUAL_FEE} || 0,
        $attr->{PERSONAL_DESCRIPTION} || '',
      ]
    }
  );

  return $self if $self->{errno};

  $admin->action_add($attr->{UID}, 'ADD:' . $tp_id . ($attr->{PERSONAL_DESCRIPTION} || ''), { TYPE => 3 });
  return $self;
}

#**********************************************************
=head1 user_tariff_change()

  Attributes:
    $attr

=cut
#**********************************************************
sub user_tariff_change{
  my $self = shift;
  my ($attr) = @_;

  $attr->{CREATE_DOCS} = 0 if !$attr->{CREATE_DOCS};
  $attr->{SEND_DOCS} = 0 if !$attr->{SEND_DOCS};
  $attr->{MANUAL_FEE} = 0 if !$attr->{MANUAL_FEE};

  $self->changes({
    CHANGE_PARAM => 'UID,TP_ID',
    TABLE        => 'abon_user_list',
    DATA         => $attr,
  });

  return $self;
}

#**********************************************************
=head2 user_tariff_activate($attr)

=cut
#**********************************************************
sub user_tariff_activate{
  my $self = shift;
  my ($attr) = @_;

  $self->query("UPDATE abon_user_list SET date = ? WHERE uid = ? AND tp_id = ? ;", 'do', {
    Bind => [
      $attr->{ABON_DATE},
      $attr->{UID},
      $attr->{TP_ID}
    ]
  });

  return $self;
}

#**********************************************************
=head2 user_tariffs()

=cut
#**********************************************************
sub user_tariff_del{
  my $self = shift;
  my ($attr) = @_;

  my $tp_info = $self->user_tariff_list($attr->{UID}, { ID => $attr->{TP_ID}, COLS_NAME => 1 });
  my $personal_desc = '';

  if ($self->{TOTAL} && $self->{TOTAL} > 0 && $tp_info->[0] && $tp_info->[0]{personal_description}) {
    $personal_desc = $tp_info->[0]{personal_description};
  }

  $self->query_del('abon_user_list', undef, {
    uid   => $attr->{UID},
    tp_id => ($attr->{TP_IDS}) ? $attr->{TP_IDS} : $attr->{TP_ID}
  });

  $personal_desc = ($attr->{TP_IDS} || $attr->{TP_ID}) . ($personal_desc ? ": $personal_desc" : '');

  $admin->action_add($attr->{UID}, $personal_desc, { TYPE => 10 });
  return $self;
}

#**********************************************************
=head2 user_tariff_update($attr)

=cut
#**********************************************************
sub user_tariff_update{
  my $self = shift;
  my ($attr) = @_;

  $attr->{DATE} = "NOW()" if (! $attr->{DATE});

  if ($attr->{NOTIFICATION} && $attr->{NOTIFICATION} == 1)  {
    $attr->{NOTIFICATION1} = $attr->{DATE};
    $attr->{NOTIFICATION_ACCOUNT_ID} = 1;
    delete $attr->{DATE};
  }

  if ($attr->{NOTIFICATION} && $attr->{NOTIFICATION} == 2) {
    $attr->{NOTIFICATION2} = $attr->{DATE};
    delete $attr->{DATE};
  }

  $admin->{MODULE} = $MODULE;
  $self->changes({
    CHANGE_PARAM => 'UID,TP_ID',
    TABLE        => 'abon_user_list',
    DATA         => $attr
  });

  return $self;
}

#**********************************************************
=head2 periodic_list($attr)

=cut
#**********************************************************
sub periodic_list{
  my $self = shift;
  my ($attr) = @_;

  my @WHERE_RULES = ();
  my $EXT_TABLES = '';

  my $WHERE = $self->search_former( $attr, [
      [ 'LOGIN',        'STR', 'u.id  ',           ],
      [ 'TP_ID',        'INT', 'ul.tp_id',         ],
      [ 'DELETED',      'INT', 'u.deleted',      1 ],
      [ 'LOGIN_STATUS', 'INT', 'u.disable',      1 ],
      [ 'MANUAL_FEE',   'INT', 'ul.manual_fee',  1 ],
      [ 'LAST_DEPOSIT', 'INT', 'f.last_deposit', 1 ],
      [ 'FEES_PERIOD',  'INT', 'ul.fees_period', 1 ],
      [ 'PLUGIN',       'STR', 'at.plugin',      1 ],
      [ 'UID',          'INT', 'u.uid',          1 ],
      [ 'GID',          'INT', 'u.gid',          1 ],
      [ 'COMPANY_ID',   'INT', 'u.company_id',   1 ]
    ],
    { WHERE       => 1,
      WHERE_RULES => \@WHERE_RULES
    }
  );

  $EXT_TABLES .= $self->{EXT_TABLES} if ($self->{EXT_TABLES});

  if ( $CONF->{EXT_BILL_ACCOUNT} ){
    $EXT_TABLES = " LEFT JOIN bills ext_b ON (u.ext_bill_id = ext_b.id)
      LEFT JOIN bills ext_cb ON  (company.ext_bill_id=ext_cb.id)";
    $self->{SEARCH_FIELDS} .= 'IF(company.id IS NULL,ext_b.deposit,ext_cb.deposit) AS ext_deposit,';
  }

  $self->query("SELECT at.period, at.price, u.uid,
  IF(u.company_id > 0, company.bill_id, u.bill_id) AS bill_id,
  u.id AS login,
  at.id AS tp_id,
  at.name AS tp_name,
  IF(company.name IS NULL, b.deposit, cb.deposit) AS deposit,
  IF(u.credit, u.credit,
    IF (company.credit <> 0, company.credit, 0) ) AS credit,
  u.disable,
  at.payment_type,
  ul.comments,
  \@last_fees_date := IF(ul.date='0000-00-00', CURDATE(), ul.date),
  \@fees_date := if (at.nonfix_period = 1,
      IF (at.period = 0, \@last_fees_date+ INTERVAL 1 DAY,
        IF (at.period = 1, \@last_fees_date + INTERVAL 1 MONTH,
          IF (at.period = 2, \@last_fees_date + INTERVAL 3 MONTH,
            IF (at.period = 3, \@last_fees_date + INTERVAL 6 MONTH,
              IF (at.period = 4, \@last_fees_date + INTERVAL 1 YEAR,
                '-'
              )
            )
          )
        )
      ),
      IF (at.period = 0, \@last_fees_date + INTERVAL 1 DAY,
        IF (at.period = 1, DATE_FORMAT(\@last_fees_date + INTERVAL 1 MONTH, '%Y-%m-01'),
          IF (at.period = 2, CONCAT(YEAR(\@last_fees_date + INTERVAL 3 MONTH), '-' ,(QUARTER((\@last_fees_date + INTERVAL 3 MONTH))*3-2), '-01'),
            IF (at.period = 3, CONCAT(YEAR(\@last_fees_date + INTERVAL 6 MONTH), '-', if(MONTH(\@last_fees_date + INTERVAL 6 MONTH) > 6, '06', '01'), '-01'),
              IF (at.period = 4, DATE_FORMAT(\@last_fees_date + INTERVAL 1 YEAR, '%Y-01-01'),
                '-'
              )
            )
          )
        )
      )
    ) AS abon_date,
    at.ext_bill_account,
    IF(u.company_id > 0, company.ext_bill_id, u.ext_bill_id) AS ext_bill_id,
    at.priority,

    fees_type,
    create_account,
    IF (at.notification1>0, \@fees_date - interval at.notification1 day, '0000-00-00') AS notification1,
    IF (at.notification2>0, \@fees_date - interval at.notification2 day, '0000-00-00') AS notification2,
    at.notification_account,
    IF (at.alert > 0, \@fees_date, '0000-00-00'),
    at.alert_account,
    pi.email,
    ul.notification1_account_id,
    at.ext_cmd,
    at.activate_notification,
    at.vat,
    \@nextfees_date := if (at.nonfix_period = 1,
        IF (at.period = 0, \@last_fees_date+ INTERVAL 2 DAY,
        IF (at.period = 1, \@last_fees_date + INTERVAL 2 MONTH,
          IF (at.period = 2, \@last_fees_date + INTERVAL 6 MONTH,
            IF (at.period = 3, \@last_fees_date + INTERVAL 12 MONTH,
              IF (at.period = 4, \@last_fees_date + INTERVAL 2 YEAR,
                '-'
              )
            )
          )
        )
      ),
      IF (at.period = 0, \@last_fees_date+ INTERVAL 1 DAY,
        IF (at.period = 1, DATE_FORMAT(\@last_fees_date + INTERVAL 2 MONTH, '%Y-%m-01'),
          IF (at.period = 2, CONCAT(YEAR(\@last_fees_date + INTERVAL 6 MONTH), '-' ,(QUARTER((\@last_fees_date + INTERVAL 6 MONTH))*6-2), '-01'),
            IF (at.period = 3, CONCAT(YEAR(\@last_fees_date + INTERVAL 12 MONTH), '-', if(MONTH(\@last_fees_date + INTERVAL 12 MONTH) > 12, '06', '01'), '-01'),
              IF (at.period = 4, DATE_FORMAT(\@last_fees_date + INTERVAL 2 YEAR, '%Y-01-01'),
                '-'
              )
            )
          )
        )
      )
    ) AS next_abon_date,
    IF(ul.discount>0, ul.discount,
    IF(at.discount=1, u.reduction, 0)) AS discount,
    ul.create_docs,
    ul.send_docs,
    ul.service_count,
    $self->{SEARCH_FIELDS}
    ul.manual_fee
    FROM abon_tariffs at
      INNER JOIN abon_user_list ul ON (at.id=ul.tp_id)
      INNER JOIN users u ON (ul.uid=u.uid)
      LEFT JOIN bills b ON (u.bill_id=b.id)
      LEFT JOIN companies company ON (u.company_id=company.id)
      LEFT JOIN bills cb ON (company.bill_id=cb.id)
      LEFT JOIN users_pi pi ON (pi.uid=u.uid)
      $EXT_TABLES
    $WHERE
    ORDER BY at.priority;",
    undef,
    $attr
  );

  my $list = $self->{list};

  return $list;
}

#**********************************************************
=head2 subscribe_add($uid, $abon_tp_id) - TODO

  Arguments:
    $uid        - user ID
    $abon_tp_id - subscription identifier

  Returns:
    1 - if successfuly added subscription for user

=cut
#**********************************************************
sub subscribe_add {
  my $self = shift;
  my ($uid, $abon_tp_id) = @_;
  return 0 unless ($uid && $abon_tp_id);

  # TODO: add subscription

  return 1;
}

#**********************************************************
=head2 subscribe_del($uid, $abon_tp_id)() - TODO

  Arguments:
    $uid        - user ID
    $abon_tp_id - subscription identifier

  Returns:
    1 - if successfuly deleted user subscribe

=cut
#**********************************************************
sub subscribe_del {
  my $self = shift;
  my ($uid, $abon_tp_id ) =  @_;
  return 0 unless ($uid && $abon_tp_id);

  # TODO: delete subscription

  return 1;
}


#**********************************************************
=head2 category_add () - add new category

  Arguments:
    $attr

  Returns:
    $self

=cut
#**********************************************************
sub category_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('abon_categories', $attr);

  return $self;
}

#**********************************************************
=head2 category_info (ID) - Show info of category

  Arguments:
    ID

  Returns:
    $self

=cut
#**********************************************************
sub category_info {
  my $self = shift;
  my ($attr) = @_;

  $self->query("SELECT *
   FROM abon_categories
   WHERE id = ?;",
    undef,
    { INFO => 1,
      Bind => [ $attr->{ID} ]
    }
  );

  return $self;
}

#*******************************************************************
=head2 category_change($attr) - change category

  Arguments:
   $attr

  Returns:
    $self

=cut
#*******************************************************************
sub category_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'abon_categories',
    DATA         => $attr
  });

  return $self;
}

#*******************************************************************
=head2  category_del(ID) - delete template

  Arguments:
    ID

  Returns:
   $self

=cut
#*******************************************************************
sub category_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('abon_categories', $attr);

  return $self;
}

#*******************************************************************

=head2  category_list($attr) - list of categories

  Arguments:
    $attr
      VISIBLE - show visible categories
      HASH_RETURN - return categories as a hash (ID => NAME)

  Returns:
    $list or $list_hash

=cut

#*******************************************************************
sub category_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 100;

  my $search_columns = [
    [ 'ID',               'INT', 'ac.id',              1 ],
    [ 'NAME',             'STR', 'ac.name',            1 ],
    [ 'DESCRIBE',         'STR', 'ac.dsc',             1 ],
    [ 'PUBLIC_DESCRIBE',  'STR', 'ac.public_dsc',      1 ],
    [ 'VISIBLE',          'INT', 'ac.visible',         1 ],
  ];

  my $WHERE = $self->search_former($attr, $search_columns, {
    WHERE => 1,
  });

  $self->query("
    SELECT *
    FROM abon_categories ac
    $WHERE
    GROUP BY ac.id
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;",
    undef, $attr
  );

  my $list = $self->{list};

  if ($attr->{HASH_RETURN}){
    my %list_hash = ();
    foreach my $line (@$list) {
      $list_hash{$line->{id}} = $line->{name};
    }
    return \%list_hash;
  }

  $self->query("
    SELECT COUNT(*) AS total
    FROM abon_categories
    $WHERE;",
    undef,
    { INFO => 1 }
  );

  return $list;
}




1
