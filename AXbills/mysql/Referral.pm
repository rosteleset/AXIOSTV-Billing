package Referral;

=head1 NAME

  Referral SQL

=cut

use strict;
use parent qw(dbcore);

my $conf;

my $conf_prefix = 'REFERRAL_';

my $default_values = {
  MAX_LEVEL          => '0',
  DISCOUNT_COEF      => '0',
  DISCOUNT_NEXT_COEF => '0',
  BONUS_AMOUNT       => '0',
  PAYMENT_ARREARS    => '0',
  BONUS_BILL         => '0',
  PERIOD             => '0',
  REPL_PERCENT       => '0',
};

#**********************************************************
=head2 new($db, $admin, $CONF)

  Arguments:
    $db    - ref to DB
    $admin - current Web session admin
    $CONF  - ref to %conf

  Returns:
    object

=cut
#**********************************************************
sub new {
  my $class = shift;
  my ($db, $admin, $CONF) = @_;

  my $self = {};
  bless($self, $class);

  $self->{db} = $db;
  $self->{admin} = $admin;
  $self->{conf} = $CONF;

  $conf = Conf->new($self->{db}, $self->{admin}, $self->{conf}, { SKIP_CONF => 1 });

  return $self;
}

#**********************************************************
=head2 settings_get()

  Arguments:
    $attr
      PARAM - specify name of the only param you want to get

  Returns:
    list

=cut
#**********************************************************
sub settings_get {
  shift;
  my ($attr) = @_;

  my $param = $attr->{PARAM} || $conf_prefix . '*';
  my $list = $conf->config_list({
    PARAM     => $param,
    CONF_ONLY => 1,
    COLS_NAME => 1
  });

  unless ($attr->{PARAM}) {
    #check for existence of all params
    if (ref $list ne 'ARRAY') {
      $list = [];
    }
    if (scalar @{$list} < scalar keys %{$default_values}) {
      _settings_define({ ALREADY_DEFINED => $list });
    }
  }
  # FIXME: maybe, this function to base?
  require Referral::Helpers;
  Referral::Helpers->import('transform_to_hash');

  return transform_to_hash($list, { NAME_KEY => 'param', VAL_KEY => 'value' });
}

#**********************************************************
=head2 max_level_set($all_params)

  Arguments:
    $all_params - arr_ref,  list of new parameters

  Returns:
    1;

  #TODO: When there will be a lot of params, check if need to change

=cut
#**********************************************************
sub settings_set{
  my $self = shift;
  my ($all_params) = @_;

  my %new_params = ();

  #filtering non existent params
  foreach my $param_name ( keys %{$all_params} ){
    if ( defined $default_values->{$param_name} ){
      $new_params{$conf_prefix . $param_name} = $all_params->{$param_name};
    }
  }

  foreach my $key ( keys %new_params ){
    my $params = {
      PARAM => $key,
      VALUE => $new_params{$key}
    };

    $params->{REPLACE} = 1;
    $conf->config_add( $params );
  }

  return $conf;
}

#**********************************************************
=head2 settings_define($attr)

  Defines unexistent configuration variables

  Arguments:
    $attr - hash_ref
      ALREADY_DEFINED - list

  Returns:
    1

=cut
#**********************************************************
sub _settings_define{
  my ($attr) = @_;

  my $defined_params = { };
  foreach my $element ( @{ $attr->{ALREADY_DEFINED} } ){
    $defined_params->{$element->{param}} = 1;
  }

  foreach my $param ( keys %{$default_values} ){
    unless ( defined $defined_params->{$conf_prefix . $param} ){
      $conf->add( {
          PARAM => $conf_prefix . $param,
          VALUE => "$default_values->{$param}"
        } );

      $conf->config_add( {
          PARAM => $conf_prefix . $param,
          VALUE => "$default_values->{$param}"
        } );
    }
  }

  return 1;
}

#**********************************************************
=head2 list($attr)

  Arguments:
    $attr - hash_ref

  Returns:

=cut
#**********************************************************
sub list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 100;

  my $WHERE = $self->search_former( $attr, [
      [ 'UID',      'INT', 'r.uid'       ],
      [ 'REFERRAL', 'INT', 'r.referrer', ],
    ],
    {
      WHERE => 1
    }
  );

  $self->query(
    "SELECT
       r.uid, r.referrer,
       rr.id AS ref_request_id,
        IF(pi.fio='', u.id, CONCAT( pi.fio, ' (', u.id, ')' )) AS id
     FROM referral_main r
       INNER JOIN users u ON (r.uid=u.uid)
       LEFT JOIN users_pi pi ON (r.uid=pi.uid)
       LEFT JOIN referral_requests rr ON (r.uid=rr.referral_uid)
    $WHERE ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;
     ",
    undef,
    $attr
  );

  return $self->{list} || [];
}

#**********************************************************
=head2 tp_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:

=cut
#**********************************************************
sub tp_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $WHERE = $self->search_former($attr, [
    [ 'ID',               'INT', 'r.id',                1 ],
    [ 'NAME',             'STR', 'r.name',              1 ],
    [ 'BONUS_AMOUNT',     'INT', 'r.bonus_amount',      1 ],
    [ 'PAYMENT_ARREARS',  'INT', 'r.payment_arrears',   1 ],
    [ 'PERIOD',           'INT', 'r.period',            1 ],
    [ 'REPL_PERCENT',     'INT', 'r.repl_percent',      1 ],
    [ 'SPEND_PERCENT',    'INT', 'r.spend_percent',     1 ],
    [ 'BONUS_BILL',       'INT', 'r.bonus_bill',        1 ],
    [ 'IS_DEFAULT',       'INT', 'r.is_default',        1 ],
    [ 'MAX_BONUS_AMOUNT', 'INT', 'r.max_bonus_amount',  1 ],
    [ 'STATIC_ACCRUAL',   'INT', 'r.static_accrual',    1 ],
    [ 'MULTI_ACCRUAL',    'INT', 'r.multi_accrual',     1 ],
    [ 'PAYMENTS_TYPE',    'STR', 'r.payments_type',     1 ],
    [ 'FEES_TYPE',        'STR', 'r.fees_type',         1 ],
    [ 'INACTIVE_DAYS',    'INT', 'r.inactive_days',     1 ]
  ], { WHERE => 1 });

  $self->query(
    "SELECT
     $self->{SEARCH_FIELDS} r.id
     FROM referral_tp r
    $WHERE ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;
     ",
    undef,
    $attr
  );

  return $self->{list} || [];
}

#**********************************************************
=head2 request_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:

=cut
#**********************************************************
sub request_list{
  my $self = shift;
  my ($attr) = @_;


  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;
  my $GROUP_BY = $attr->{GROUP_BY} || '';
  my $build_delimiter = $attr->{BUILD_DELIMITER} || $self->{conf}{BUILD_DELIMITER} || ', ';

  my $WHERE = $self->search_former( $attr, [
    [ 'ID',           'INT',   'r.id as referral_request', 1 ],
    [ 'FIO',          'STR',   'r.fio',                    1 ],
    [ 'phone',        'STR',   'r.phone',                  1 ],
    [ 'ADDRESS',      'STR',   'r.address',                1 ],
    [ 'STATUS',       'INT',   'r.status',                 1 ],
    [ 'UID',          'INT',   'r.referrer as uid',        1 ],
    [ 'REFERRER',     'INT',   'r.referrer',               1 ],
    [ 'LOGIN',        'STR',   'u.id as login',            1 ],
    [ 'DATE',         'DATE',  'r.date',                   1 ],
    [ 'TP_ID',        'INT',   'r.tp_id as referral_tp',   1 ],
    [ 'TP_NAME',      'INT',   'rt.name as tp_name',       1 ],
    [ 'REFERRAL_UID', 'INT',   'r.referral_uid',           1 ],
    [ 'REFERRAL_LOGIN','STR',  'ur.id as referral_login',  1 ],
    [ 'USER_STATUS',  'INT',   'ur.disable',               1 ],
    [ 'USER_DELETED', 'INT',   'ur.deleted',               1 ],
    [ 'LOCATION_ID',  'INT',   'r.location_id',            1 ],
    [ 'ADDRESS_FLAT', 'STR',   'r.address_flat',           1 ],
    [ 'COMMENTS',     'STR',   'r.comments',               1 ],
    [ 'INNER_COMMENTS','STR',  'r.inner_comments',         1 ],
    [ 'PAYMENTS_TYPE','STR',   'rt.payments_type',         1 ],
    [ 'FEES_TYPE',    'STR',   'rt.fees_type',             1 ],
    [ 'FROM_DATE|TO_DATE', 'DATE',  "DATE_FORMAT(r.date, '%Y-%m-%d')", 1 ],
    [ 'INACTIVE_DAYS', 'INT',  'rt.inactive_days',         1 ],
    [ 'ADDRESS_FULL',     'STR',
      "IF(r.location_id, CONCAT(districts.name, '$build_delimiter', streets.name, '$build_delimiter', builds.number, '$build_delimiter', r.address_flat), '') AS address_full",  1 ],
  ],
    {
      WHERE => 1
    }
  );
  my $EXT_TABLES = $self->{EXT_TABLES};

  if ($attr->{ADDRESS_FULL}) {
    $EXT_TABLES .= "LEFT JOIN builds ON (builds.id=r.location_id)";
    $EXT_TABLES .= "LEFT JOIN streets ON (streets.id=builds.street_id)
      LEFT JOIN districts ON (districts.id=streets.district_id) ";
  }

  $self->query(
    "SELECT
     $self->{SEARCH_FIELDS} r.id
     FROM referral_requests r
     LEFT JOIN users u ON (u.uid = r.referrer)
     LEFT JOIN users ur ON (ur.uid = r.referral_uid)
     LEFT JOIN referral_tp rt ON (r.tp_id = rt.id)
    $EXT_TABLES
    $WHERE $GROUP_BY ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;
     ",
    undef,
    $attr
  );

  return $self->{list} || [];
}

#**********************************************************
=head2 tp_info($id)

  Arguments:
    id

  Returns:

=cut
#**********************************************************
sub tp_info{
  my $self = shift;
  my ($id) = @_;

  $self->query("SELECT * FROM referral_tp WHERE id = ? ", undef, {
      INFO => 1,
      Bind => [ $id ],
  });

  return $self;
}

#**********************************************************
=head2 get_default_tp()

  Arguments:

  Returns:

=cut
#**********************************************************
sub get_default_tp{
  my $self = shift;

  $self->query("SELECT * FROM referral_tp WHERE is_default = ? ", undef, {
      INFO => 1,
      Bind => [ 1 ],
  });

  return $self;
}

#**********************************************************
=head2 log_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:

=cut
#**********************************************************
sub log_list{
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $WHERE = $self->search_former( $attr, [
    [ 'ID',               'INT',  'rl.id'                  ],
    [ 'UID',              'INT',  'rl.uid',              1 ],
    [ 'DATE',             'DATE', 'rl.date',             1 ],
    [ 'REFERRAL_REQUEST', 'STR',  'rl.referral_request', 1 ],
    [ 'TP_ID',            'INT',  'rr.tp_id',            1 ],
    [ 'LOG_TYPE',         'INT',  'rl.log_type',         1 ],
    [ 'REFERRER',         'INT',  'rl.referrer',         1 ],
  ], { WHERE => 1 });

  $self->query(
    "SELECT
        $self->{SEARCH_FIELDS} rl.id
     FROM referral_log rl
     LEFT JOIN referral_requests rr ON (rl.referral_request = rr.id)
    $WHERE ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;
     ",
    undef,
    $attr
  );

  return $self->{list} || [];
}

#**********************************************************
=head2 info($uid, $attr)

  Arguments:
    $uid   - uid of user
    $attr - hash_ref

  Returns:

=cut
#**********************************************************
sub info {
  my $self = shift;
  my ($uid) = @_;

  my $list = $self->list({ UID => $uid, COLS_NAME => 1 });

  return $list->[0] || {};
}

#**********************************************************
=head2 add($attr)

  Arguments:
    $attr - hash_ref

  Returns:

=cut
#**********************************************************
sub add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('referral_main', $attr, { REPLACE => 1 });

  return $self;
}

#**********************************************************
=head2 add($attr)

  Arguments:
    $attr - hash_ref

  Returns:

=cut
#**********************************************************
sub add_request {
  my $self = shift;
  my ($attr) = @_;

  return $self->query_add('referral_requests', $attr, { REPLACE => 1 });
}

#**********************************************************
=head2 tp_add($attr)

  Arguments:
    $attr - hash_ref

  Returns:

=cut
#**********************************************************
sub tp_add{
  my $self = shift;
  my ($attr) = @_;

  return $self->query_add( 'referral_tp', $attr );
}

#**********************************************************
=head2 add($attr)

  Arguments:
    $attr - hash_ref

  Returns:

=cut
#**********************************************************
sub add_log{
  my $self = shift;
  my ($attr) = @_;

  return $self->query_add( 'referral_log', $attr, { REPLACE => 1 } );
}

#**********************************************************
=head2 del($uid)

  Arguments:


  Returns:

=cut
#**********************************************************
sub del{
  my $self = shift;
  my ($uid) = @_;

  return $self->query_del('referral_main', undef, { UID => $uid });
}

#**********************************************************
=head2 del($id)

  Arguments:


  Returns:

=cut
#**********************************************************
sub del_request{
  my $self = shift;
  my ($id) = @_;

  return $self->query_del( 'referral_requests', { ID => $id } );
}

#**********************************************************
=head2 tp_del($id)

  Arguments:


  Returns:

=cut
#**********************************************************
sub tp_del{
  my $self = shift;
  my ($id) = @_;

  return $self->query_del( 'referral_tp', { ID => $id } );
}

#**********************************************************
=head2 change_request($attr)

  Arguments:


  Returns:

=cut
#**********************************************************
sub change_request{
  my $self = shift;
  my ($attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'referral_requests',
    DATA         => $attr
  });

  return $self;
}

#**********************************************************
=head2 tp_change($attr)

  Arguments:


  Returns:

=cut
#**********************************************************
sub tp_change{
  my $self = shift;
  my ($attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'referral_tp',
    DATA         => $attr
  });

  return $self;
}

#**********************************************************
=head2 get_user_info($uid)

  Arguments:
    $uid - Users ID

  Returns:
    hash_ref
      UID => 'FIO ( ID )'

=cut
#**********************************************************
sub get_user_info {
  my $self = shift;
  my ($uid) = @_;

  delete $self->{COLS_NAME_ARR};
  delete $self->{COL_NAMES_ARR};

  $self->query( "
  SELECT
     u.uid,
     u.id AS login,
     pi.fio AS fio,
     IF(pi.fio='', u.id, CONCAT( pi.fio, ' (', u.id, ')' )) AS id
   FROM users u
   INNER JOIN users_pi pi ON (u.uid=pi.uid)
   WHERE u.uid = ?
  ", undef, { COLS_NAME => 1, Bind => [ $uid ] } );

  my $list = $self->{list};

  if (ref $list eq 'ARRAY' && scalar @{$list} > 0) {
    return $list->[0] || {};
  }

  return {};
}

#**********************************************************
=head2 get_referrers_list() - get all users who are referrers

  Arguments:


  Returns:
    list of all users who are referrers

=cut
#**********************************************************
sub get_referrers_list {
  my $self = shift;

  delete $self->{COL_NAMES_ARR};

  $self->query( "
  SELECT DISTINCT(u.uid),
     u.id AS login,
     pi.fio AS fio,
     IF(pi.fio='', u.id, CONCAT( pi.fio, ' (', u.id, ')' )) AS id
   FROM users u
   INNER JOIN referral_main r ON (r.referrer=u.uid)
   LEFT JOIN users_pi pi ON (u.uid=pi.uid)
  ", undef, { COLS_NAME => 1 } );

  return $self->{list} || [];
}

#**********************************************************
=head2 referral_bonus_add($attr) save new counted bonus

  Arguments:
    UID
    REFERRER
    SUM
    PAYMENT_ID
    FEE_ID

  Returns:
    $self

=cut
#**********************************************************
sub referral_bonus_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('referral_users_bonus', $attr);

  return $self;
}

#**********************************************************
=head2 referral_bonus_add($attr) save new counted bonus

  Arguments:
    UID
    REFERRER
    SUM
    PAYMENT_ID
    FEE_ID

  Returns:
    $self

=cut
#**********************************************************
sub referral_bonus_multi_add {
  my $self = shift;
  my ($attr) = @_;

  return $self if (!$attr->{BONUSES} || ref $attr->{BONUSES} ne 'ARRAY');

  my @MULTI_QUERY = ();

  foreach my $bonus (@{$attr->{BONUSES}}) {
    push @MULTI_QUERY, [ $bonus->{UID}, $bonus->{REFERRER}, $bonus->{SUM}, $bonus->{PAYMENT_ID}, $bonus->{FEE_ID} ];
  }

  $self->query("INSERT INTO referral_users_bonus (`uid`, `referrer`, `sum`, `payment_id`, `fee_id`) VALUES (?, ?, ?, ?, ?);",
    undef, { MULTI_QUERY => \@MULTI_QUERY });

  return $self;
}

#**********************************************************
=head2 get_payments_bonus($uid) get all new payments

  Arguments:
    attr

  Returns:
    list of payments

=cut
#**********************************************************
sub get_payments_bonus {
  my $self = shift;
  my ($attr) = @_;
  my $payments_type = $attr->{PAYMENTS_TYPE} ? $attr->{PAYMENTS_TYPE} : 0;

  $self->query("
    SELECT p.uid, p.date, p.sum, p.id
    FROM payments p
    WHERE p.id NOT IN
    (SELECT rub.payment_id FROM referral_users_bonus rub WHERE rub.payment_id = p.id)
    AND DATE(p.date) >= DATE(NOW())- INTERVAL 2 DAY
    AND p.method IN ($payments_type)
    AND p.uid = ?;
  ", undef, { COLS_NAME => 1, Bind => [ $attr->{UID} ] } );

  return $self->{list} || [];
}

#**********************************************************
=head2 get_fees_bonus($uid) get all new fees

  Arguments:
    UID

  Returns:
    list of fess

=cut
#**********************************************************
sub get_fees_bonus {
  my $self = shift;
  my ($attr) = @_;
  my $fees_type = $attr->{FEES_TYPE} ? $attr->{FEES_TYPE} : 0;

  $self->query("
    SELECT f.uid, f.date, f.sum, f.id
    FROM fees f
    WHERE f.id NOT IN
    (SELECT rub.fee_id FROM referral_users_bonus rub WHERE rub.fee_id = f.id)
    AND DATE(f.date) >= DATE(NOW())- INTERVAL 2 DAY
    AND f.method IN ($fees_type)
    AND f.uid = ?;
  ", undef, { COLS_NAME => 1, Bind => [ $attr->{UID} ] } );

  return $self->{list} || [];
}

#**********************************************************
=head2 get_single_bonus($uid) get is received single bonus

  Arguments:
    UID

  Returns:
    list of fess

=cut
#**********************************************************
sub get_single_bonus {
  my $self = shift;
  my ($uid) = @_;

  $self->query("
    SELECT *
    FROM referral_users_bonus rub
    WHERE rub.fee_id = 0 AND rub.payment_id = 0 AND rub.uid = ?;
  ", undef, { COLS_NAME => 1, Bind => [ $uid ] } );

  return $self->{list} || [];
}

#**********************************************************
=head2 get_bonus_history($uid) get bonus history

  Arguments:
    UID

  Returns:
    list of fess

=cut
#**********************************************************
sub get_bonus_history {
  my $self = shift;
  my ($referrer) = @_;

  $self->query("
    SELECT rub.date, rub.sum, rr.id, rr.fio, rr.address, rr.comments
    FROM referral_users_bonus rub
    LEFT JOIN referral_requests rr ON (rub.uid = rr.referral_uid)
    WHERE rub.referrer = ?;
  ", undef, { COLS_NAME => 1, Bind => [ $referrer ] } );

  return $self->{list} || [];
}

#**********************************************************
=head2 get_total_bonus($uid) get total bonus on referral

  Arguments:
    UID

  Returns:
    list of fess

=cut
#**********************************************************
sub get_total_bonus {
  my $self = shift;
  my ($uid) = @_;

  $self->query("SELECT COUNT(*) AS total, SUM(rub.sum) AS total_sum
    FROM referral_users_bonus rub
    WHERE rub.uid = ?;",
    undef, { INFO => 1, Bind => [ $uid ] } );

  return $self;
}

1;
