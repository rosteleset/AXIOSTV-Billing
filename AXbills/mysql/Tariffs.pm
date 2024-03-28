package Tariffs;

=head1 NAME

 Tarif plans functions
   abon payments
   intervals
   traffic tariffs

=cut

use strict;
use parent 'dbcore';
my $CONF;
my $admin;

#**********************************************************
=head2 new($db, \%conf, $admin)

=cut
#**********************************************************
sub new {
  my $class = shift;
  my $db    = shift;
  ($CONF, $admin) = @_;

  my $self = {
    db   => $db,
    admin=> $admin,
    conf => $CONF
  };

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 ti_del($id)

=cut
#**********************************************************
sub ti_del {
  my $self = shift;
  my ($id) = @_;

  $self->query_del('intervals', { ID => $id });
  $self->query_del('trafic_tarifs', undef, { interval_id => $id });

  $self->{admin}->system_action_add("TI:$id", { TYPE => 10 });
  return $self;
}

#**********************************************************
=head2 ti_add($attr) - Time interval add

=cut
#**********************************************************
sub ti_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('intervals', {
        TP_ID => $self->{TP_ID}, 
        DAY   => $attr->{TI_DAY}, 
        BEGIN => $attr->{TI_BEGIN}, 
        END   => $attr->{TI_END}, 
        TARIF => $attr->{TI_TARIF} 
      });

  $self->{INTERVAL_ID} = $self->{INSERT_ID};

  $self->{admin}->system_action_add("TI:$self->{INSERT_ID} TP:$self->{TP_ID}", { TYPE => 1 });
  return $self;
}

#**********************************************************
=head2 ti_list($attr) - Time_intervals  list

  Arguments:
    $attr
      SHOW_INTERVAL_SEC -

  Returns:
    $list

=cut
#**********************************************************
sub ti_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : "2, 3";
  my $DESC = (defined($attr->{DESC})) ? $attr->{DESC} : '';

  if ($SORT eq '1') { $SORT = "2, 3"; }

  my $begin_end = "i.begin, i.end,";
  my $TP_ID     = $self->{TP_ID} || $attr->{TP_ID};

  if ($attr->{SHOW_INTERVAL_SEC}) {
    $begin_end = "TIME_TO_SEC(i.begin) AS begin_sec, TIME_TO_SEC(i.end) AS end_sec, ";
    $TP_ID     = $attr->{TP_ID};
  }

  $self->query("SELECT i.id,
      i.day,
      $begin_end
      i.tarif,
      COUNT(tt.id) AS traffic_classes,
      i.id
    FROM intervals i
    LEFT JOIN trafic_tarifs tt ON (tt.interval_id=i.id)
    WHERE i.tp_id='$TP_ID'
    GROUP BY i.id
    ORDER BY $SORT $DESC",
    undef,
    $attr
  );

  return $self->{list};
}

#**********************************************************
=head2 ti_change($ti_id, $attr) - Time intervals change

=cut
#**********************************************************
sub ti_change {
  my $self = shift;
  my ($ti_id, $attr) = @_;

  my %FIELDS = (
    TI_DAY   => 'day',
    TI_BEGIN => 'begin',
    TI_END   => 'end',
    TI_TARIF => 'tarif',
    TI_ID    => 'id'
  );

  $self->changes(
    {
      CHANGE_PARAM => 'TI_ID',
      TABLE        => 'intervals',
      FIELDS       => \%FIELDS,
      OLD_INFO     => $self->ti_info($ti_id),
      DATA         => $attr
    }
  );

  if ($ti_id == $attr->{TI_ID}) {
    $self->ti_info($ti_id);
  }
  else {
    $self->info($attr->{TI_ID});
  }

  return $self;
}

#**********************************************************
=head2 ti_info($ti_id) - Time_intervals  info

=cut
#**********************************************************
sub ti_info {
  my $self = shift;
  my ($ti_id) = @_;

  $self->query("SELECT day AS ti_day,
     begin AS ti_begin, 
     end AS ti_end, 
     tarif AS ti_tarif, 
     id
    FROM intervals 
    WHERE id= ? ;",
    undef,
    { INFO => 1,
      Bind => [ $ti_id ] 
    }
  );

  $self->{TI_ID} = $ti_id;

  return $self;
}

#**********************************************************
# ti_defaults
#**********************************************************
sub ti_defaults {
  my $self = shift;

  my %TI_DEFAULTS = (
    TI_DAY   => 0,
    TI_BEGIN => '00:00:00',
    TI_END   => '24:00:00',
    TI_TARIF => 0
  );

  while (my ($k, $v) = each %TI_DEFAULTS) {
    $self->{$k} = $v;
  }

  return $self;
}

#**********************************************************
=head2 tp_group_del($id)

=cut
#**********************************************************
sub tp_group_del {
  my $self = shift;
  my ($id) = @_;

  $self->query_del('tp_groups', { ID => $id });

  $self->{admin}->system_action_add("TP_GROUP:$id", { TYPE => 10 });
  return $self;
}

#**********************************************************
# TP GROUP
#
#**********************************************************
sub tp_group_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('tp_groups', { %$attr,
  	                              ID => $attr->{GID} 
  	                             });

  $self->{admin}->system_action_add("TP_GROUP:$attr->{GID}", { TYPE => 1 });
  return $self;
}

#**********************************************************
=head2 tp_group_list($attr)

=cut
#**********************************************************
sub tp_group_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT} && $attr->{SORT} =~ /^\d$/ && $attr->{SORT} < 5) ? $attr->{SORT} : "2, 3";
  my $DESC = (defined($attr->{DESC})) ? $attr->{DESC} : '';

  $self->query("SELECT tg.id, tg.name, tg.user_chg_tp, COUNT(tp.id) AS tarif_plans_count
   FROM tp_groups tg
   LEFT JOIN tarif_plans tp ON (tg.id=tp.gid)
   GROUP BY tg.id
   ORDER BY $SORT $DESC",
   undef,
   $attr
  );

  return $self->{list};
}

#**********************************************************
=head2 tp_group_change($attr)

=cut
#**********************************************************
sub tp_group_change {
  my $self = shift;
  my ($attr) = @_;

  $attr->{USER_CHG_TP} = (defined($attr->{USER_CHG_TP}) && $attr->{USER_CHG_TP} == 1) ? 1 : 0;

  $self->changes(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'tp_groups',
      DATA         => $attr
    }
  );

  $self->tp_group_info($attr->{GID});
  return $self;
}

#**********************************************************
=head2 tp_group_info($tp_group_id);

=cut
#**********************************************************
sub tp_group_info {
  my $self = shift;
  my ($tp_group_id) = @_;

  $self->query("SELECT *
    FROM tp_groups 
    WHERE id= ? ;",
    undef,
    { INFO => 1,
      Bind => [ $tp_group_id ] 
    }
  );

  $self->{GID} = $tp_group_id;

  return $self;
}

#**********************************************************
# tp_group_defaults
#**********************************************************
sub tp_group_defaults {
  my $self = shift;

  my %TG_DEFAULTS = (
    GID         => 0,
    NAME        => '',
    USER_CHG_TP => 0
  );

  while (my ($k, $v) = each %TG_DEFAULTS) {
    $self->{$k} = $v;
  }

  return $self;
}

#**********************************************************
# Default values
#**********************************************************
sub defaults {
  my $self = shift;

  my %DATA = (
    TP                      => 0,
    NAME                    => '',
    TIME_TARIF              => '0.00000',
    DAY_FEE                 => '0.00',
    MONTH_FEE               => '0.00',
    REDUCTION_FEE           => 0,
    POSTPAID_DAY_FEE        => 0,
    POSTPAID_MONTH_FEE      => 0,
    EXT_BILL_ACCOUNT        => 0,
    SIMULTANEOUSLY          => 0,
    AGE                     => 0,
    DAY_TIME_LIMIT          => 0,
    WEEK_TIME_LIMIT         => 0,
    MONTH_TIME_LIMIT        => 0,
    TOTAL_TIME_LIMIT        => 0,
    DAY_TRAF_LIMIT          => 0,
    WEEK_TRAF_LIMIT         => 0,
    MONTH_TRAF_LIMIT        => 0,
    TOTAL_TRAF_LIMIT        => 0,
    ACTIV_PRICE             => '0.00',
    CHANGE_PRICE            => '0.00',
    CREDIT_TRESSHOLD        => '0.00',
    ALERT                   => 0,
    OCTETS_DIRECTION        => 0,
    MAX_SESSION_DURATION    => 0,
    FILTER_ID               => '',
    PAYMENT_TYPE            => 0,
    MIN_SESSION_COST        => '0.00000',
    RAD_PAIRS               => '',
    TRAFFIC_TRANSFER_PERIOD => 0,
    NEG_DEPOSUT_FILTER_ID   => '',
    TP_GID                  => 0,
    MODULE                  => '',
    CREDIT                  => 0,
    USER_CREDIT_LIMIT       => 0,
    IPPOOL                  => '0',
    PERIOD_ALIGNMENT        => '0',
    MIN_USE                 => '0.00',
    ABON_DISTRIBUTION       => 0,
    DOMAIN_ID               => 0,
    PRIORITY                => 0,
    SMALL_DEPOSIT_ACTION    => 0,
    COMMENTS                => '',
    BILLS_PRIORITY          => 0,
    ACTIVE_DAY_FEE          => 0,
    NEG_DEPOSIT_IPPOOL      => 0,
    NEXT_TARIF_PLAN         => 0,
    FEES_METHOD             => 0,
    USER_CREDIT_LIMIT       => 0,
    POPULAR                 => 0,
  );

  $self = \%DATA;
  return $self;
}

#**********************************************************
=head2 add($attr) - Add tp

  Arguments:
    $attr
      NAME
      ID

=cut
#**********************************************************
sub add {
  my $self = shift;
  my ($attr) = @_;

  my $domain_id = $self->{admin}->{DOMAIN_ID} || $admin->{DOMAIN_ID} || 0;

  if (!$attr->{ID}) {
    $self->query("SELECT MAX(id) FROM tarif_plans WHERE domain_id= ? ORDER BY 1 DESC LIMIT 1",
    undef, { Bind => [ $domain_id ] } );
    if(! $self->{TOTAL}) {
      $attr->{ID} = 1;
    }
    else {
      $attr->{ID} = ($self->{list}->[0]->[0]) ? int($self->{list}->[0]->[0]) + 1 : 1;
    }
  }

  $self->query_add('tarif_plans', {
     %$attr,
     UPLIMIT        => $attr->{ALERT}, 
     LOGINS         => $attr->{SIMULTANEOUSLY}, 
     ACTIVATE_PRICE => $attr->{ACTIV_PRICE}, 
     GID            => $attr->{TP_GID}, 
     NEXT_TP_ID     => $attr->{NEXT_TARIF_PLAN},
     DOMAIN_ID      => $domain_id
  });

  if(! $self->{errno}) {
    $self->{TP_ID}  = $self->{INSERT_ID};
    $self->{TP_NUM} = $attr->{ID};

    $self->{admin}->system_action_add("TP:$self->{TP_ID} ID: $self->{TP_NUM}", { TYPE => 1 });
  }

  return $self;
}

#**********************************************************
=head2 change($tp_id, $attr) - change

=cut
#**********************************************************
sub change {
  my $self = shift;
  my ($tp_id, $attr) = @_;

  my %FIELDS = (
    ID                      => 'id',
    TP_ID                   => 'tp_id',
    NAME                    => 'name',
    DAY_FEE                 => 'day_fee',
    ACTIVE_DAY_FEE          => 'active_day_fee',
    ACTIVE_MONTH_FEE        => 'active_month_fee',
    MONTH_FEE               => 'month_fee',
    FIXED_FEES_DAY          => 'fixed_fees_day',
    REDUCTION_FEE           => 'reduction_fee',
    POSTPAID_DAY_FEE        => 'postpaid_daily_fee',
    POSTPAID_MONTH_FEE      => 'postpaid_monthly_fee',
    EXT_BILL_ACCOUNT        => 'ext_bill_account',
    SIMULTANEOUSLY          => 'logins',
    AGE                     => 'age',
    DAY_TIME_LIMIT          => 'day_time_limit',
    WEEK_TIME_LIMIT         => 'week_time_limit',
    MONTH_TIME_LIMIT        => 'month_time_limit',
    TOTAL_TIME_LIMIT        => 'total_time_limit',
    DAY_TRAF_LIMIT          => 'day_traf_limit',
    WEEK_TRAF_LIMIT         => 'week_traf_limit',
    MONTH_TRAF_LIMIT        => 'month_traf_limit',
    TOTAL_TRAF_LIMIT        => 'total_traf_limit',
    ACTIV_PRICE             => 'activate_price',
    CHANGE_PRICE            => 'change_price',
    CREDIT_TRESSHOLD        => 'credit_tresshold',
    ALERT                   => 'uplimit',
    OCTETS_DIRECTION        => 'octets_direction',
    MAX_SESSION_DURATION    => 'max_session_duration',
    FILTER_ID               => 'filter_id',
    PAYMENT_TYPE            => 'payment_type',
    MIN_SESSION_COST        => 'min_session_cost',
    RAD_PAIRS               => 'rad_pairs',
    TRAFFIC_TRANSFER_PERIOD => 'traffic_transfer_period',
    NEG_DEPOSIT_FILTER_ID   => 'neg_deposit_filter_id',
    TP_GID                  => 'gid',
    MODULE                  => 'module',
    CREDIT                  => 'credit',
    IPPOOL                  => 'ippool',
    PERIOD_ALIGNMENT        => 'period_alignment',
    MIN_USE                 => 'min_use',
    ABON_DISTRIBUTION       => 'abon_distribution',
    DOMAIN_ID               => 'domain_id',
    PRIORITY                => 'priority',
    SMALL_DEPOSIT_ACTION    => 'small_deposit_action',
    COMMENTS                => 'comments',
    BILLS_PRIORITY          => 'bills_priority',
    FINE                    => 'fine',
    NEG_DEPOSIT_IPPOOL      => 'neg_deposit_ippool',
    NEXT_TARIF_PLAN         => 'next_tp_id',
    FEES_METHOD             => 'fees_method',
    USER_CREDIT_LIMIT       => 'user_credit_limit',
    SERVICE_ID              => 'service_id',
    STATUS                  => 'status',
    DESCRIBE_AID            => 'describe_aid',
    PROMOTIONAL             => 'promotional',
    EXT_BILL_FEES_METHOD    => 'ext_bill_fees_method',
    POPULAR                 => 'popular',
  );

  $attr->{REDUCTION_FEE}        = 0 if (!$attr->{REDUCTION_FEE});
  $attr->{POSTPAID_DAY_FEE}     = 0 if (!$attr->{POSTPAID_DAY_FEE});
  $attr->{POSTPAID_MONTH_FEE}   = 0 if (!$attr->{POSTPAID_MONTH_FEE});
  $attr->{EXT_BILL_ACCOUNT}     = 0 if (!$attr->{EXT_BILL_ACCOUNT});
  $attr->{PERIOD_ALIGNMENT}     = 0 if (!$attr->{PERIOD_ALIGNMENT});
  $attr->{ABON_DISTRIBUTION}    = 0 if (!$attr->{ABON_DISTRIBUTION});
  $attr->{SMALL_DEPOSIT_ACTION} = 0 if (!$attr->{SMALL_DEPOSIT_ACTION});
  $attr->{BILLS_PRIORITY}       = 0 if (!$attr->{BILLS_PRIORITY});
  $attr->{ACTIVE_DAY_FEE}       = 0 if (!$attr->{ACTIVE_DAY_FEE});
  $attr->{ACTIVE_MONTH_FEE}     = 0 if (!$attr->{ACTIVE_MONTH_FEE});
  $attr->{FIXED_FEES_DAY}       = 0 if (!$attr->{FIXED_FEES_DAY});
  $attr->{STATUS}               = 0 if (!$attr->{STATUS});
  $attr->{PROMOTIONAL}          = 0 if (!$attr->{PROMOTIONAL});
  $attr->{POPULAR}              = 0 if (!$attr->{POPULAR});

  $self->changes({
    CHANGE_PARAM    => 'TP_ID',
    TABLE           => 'tarif_plans',
    FIELDS          => \%FIELDS,
    OLD_INFO        => $self->info($tp_id),
    DATA            => $attr,
    EXTENDED        => ($attr->{MODULE}) ? "and module='$attr->{MODULE}'" : undef,
    EXT_CHANGE_INFO => "TP_ID:$tp_id"
  });

  $self->info($tp_id);

  return $self;
}

#**********************************************************
=head2 del($id, $attr) - TP del

=cut
#**********************************************************
sub del {
  my $self = shift;
  my ($id, $attr) = @_;

  $self->query_del('tarif_plans', undef, { tp_id => $id, module => $attr->{MODULE} });

  $self->{admin}->system_action_add("TP:$id", { TYPE => 10 });

  return $self;
}

#**********************************************************
=head2 info($id, $attr) - Info

  Arguments:
    $id
    $attr
      TP_ID
      MODULES
      ID      - TP num
      NAME

  Results:
    $self

=cut
#**********************************************************
sub info {
  my $self = shift;
  my ($id, $attr) = @_;

  my @WHERE_FIELDS = ();
  my @WHERE_VALUES = ();

  if ($attr->{MODULE}) {
    push @WHERE_FIELDS, 'module = ?';
    push @WHERE_VALUES, $attr->{MODULE};
  }

  if ($attr->{TP_ID}) {
    push @WHERE_FIELDS, 'tp_id = ?';
    push @WHERE_VALUES, $attr->{TP_ID};
  }

  if ($attr->{ID}) {
    push @WHERE_FIELDS, 'id = ?';
    push @WHERE_VALUES, $attr->{ID};
  }
  elsif ($attr->{NAME}) {
    push @WHERE_FIELDS, 'name = ?';
    push @WHERE_VALUES, $attr->{NAME};
  }
  elsif(! $attr->{TP_ID}) {
    push @WHERE_FIELDS, 'tp_id = ?';
    push @WHERE_VALUES, $id;
  }

  if(defined($admin->{DOMAIN_ID})) {
    if($attr->{TP_ID} && $admin->{DOMAIN_ID}) {
      push @WHERE_FIELDS, 'domain_id = ?';
      push @WHERE_VALUES, $admin->{DOMAIN_ID};
    }
  }

  $self->query("SELECT *,
      postpaid_daily_fee AS postpaid_day_fee,
      postpaid_monthly_fee AS postpaid_month_fee,
      logins AS SIMULTANEOUSLY,
      activate_price AS activ_price,
      uplimit AS alert,
      gid AS tp_gid,
      next_tp_id AS next_tarif_plan
    FROM tarif_plans
    WHERE ". join(' AND ', @WHERE_FIELDS),
    undef,
    { INFO => 1,
      Bind => \@WHERE_VALUES }
  );

  return $self;
}

#**********************************************************
=head2 list($attr) - TP list

  Arguments:
    $attr
      NEW_MODEL_TP - Short base field input
      SHOW_DISABLED - Show all tp, by default show only enabled tp.

=cut
#**********************************************************
sub list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = $attr->{SORT} ? $attr->{SORT} : 1;
  my $DESC = $attr->{DESC} ? $attr->{DESC} : '';

  my @WHERE_RULES = ();
  $self->{SEARCH_FIELDS} = '';

  if ($attr->{CHANGE_PRICE}) {
    my $sql = '';

    if (defined($attr->{TP_CHG_PRIORITY})) {
      $sql = "tp.change_price$attr->{CHANGE_PRICE}+tp.credit";
      $sql = "($sql or (tp.priority > '$attr->{TP_CHG_PRIORITY}'))";
    }
    elsif($attr->{CHANGE_PRICE} ne '_SHOW') {
      $sql = join('', @{ $self->search_expr($attr->{CHANGE_PRICE}, 'INT', 'tp.change_price') });
    }
    push @WHERE_RULES, $sql if($sql);
  }

  my @search_columns = (
    [ 'TP_ID',               'INT', 'tp.id',                         ],
    [ 'NAME',                'STR', 'tp.name',                       ],
    [ 'TIME_TARIFS',         'INT', '', "IF(SUM(i.tarif) is NULL or sum(i.tarif)=0, 0, 1) AS time_tarifs" ],
    [ 'TRAF_TARIFS',         'INT', '', "IF(SUM(tt.in_price + tt.out_price)> 0, 1, 0) AS traf_tarifs"     ],
    [ 'TP_GID',              'INT', 'tp.gid AS tp_gid',            1 ],
    [ 'TP_GROUP_NAME',       'STR', 'tp_g.name', 'tp_g.name AS tp_group_name'],
    [ 'UPLIMIT',             'INT', 'tp.uplimit',                  1 ],
    [ 'LOGINS',              'INT', 'tp.logins',                   1 ],
    [ 'DAY_FEE',             'INT', 'tp.day_fee',                  1 ],
    [ 'ACTIVE_DAY_FEE',      'INT', 'tp.active_day_fee',           1 ],
    [ 'ACTIVE_MONTH_FEE',    'INT', 'tp.active_month_fee',         1 ],
    [ 'POSTPAID_DAY_FEE',    'INT', 'tp.postpaid_daily_fee',       1 ],
    [ 'POSTPAID_DAILY_FEE',  'INT', 'tp.postpaid_daily_fee',       1 ],
    [ 'MONTH_FEE',           'INT', 'tp.month_fee',                1 ],
    [ 'POSTPAID_MONTH_FEE',  'INT', 'tp.postpaid_monthly_fee',     1 ],
    [ 'POSTPAID_MONTHLY_FEE','INT', 'tp.postpaid_monthly_fee',     1 ],
    [ 'PERIOD_ALIGNMENT',    'INT', 'tp.period_alignment',         1 ],
    [ 'ABON_DISTRIBUTION',   'INT', 'tp.abon_distribution',        1 ],
    [ 'FIXED_FEES_DAY',      'INT', 'tp.fixed_fees_day',           1 ],
    [ 'SMALL_DEPOSIT_ACTION','INT', 'tp.small_deposit_action',     1 ],
    [ 'REDUCTION_FEE',       'INT', 'tp.reduction_fee',            1 ],
    [ 'FEES_METHOD',         'INT', 'tp.fees_method',              1 ],
    [ 'DAY_TIME_LIMIT',      'INT', 'tp.day_time_limit',           1 ],
    [ 'WEEK_TIME_LIMIT',     'INT', 'tp.week_time_limit',          1 ],
    [ 'MONTH_TIME_LIMIT',    'INT', 'tp.month_time_limit',         1 ],
    [ 'TOTAL_TIME_LIMIT',    'INT', 'tp.total_time_limit',         1 ],
    [ 'DAY_TRAF_LIMIT',      'INT', 'tp.day_traf_limit',           1 ],
    [ 'WEEK_TRAF_LIMIT',     'INT', 'tp.week_traf_limit',          1 ],
    [ 'MONTH_TRAF_LIMIT',    'INT', 'tp.month_traf_limit',         1 ],
    [ 'TOTAL_TRAF_LIMIT',    'INT', 'tp.total_traf_limit',         1 ],
    [ 'OCTETS_DIRECTION',    'INT', 'tp.octets_direction',         1 ],
    [ 'ACTIV_PRICE',         'INT', 'tp.activate_price',           1 ],
    [ 'CHANGE_PRICE',        'INT', 'tp.change_price',             1 ],
    [ 'CREDIT_TRESSHOLD',    'INT', 'tp.credit_tresshold',         1 ],
    [ 'CREDIT',              'STR', 'tp.credit',                   1 ],
    [ 'USER_CREDIT_LIMIT',   'STR', 'tp.user_credit_limit',        1 ],
    [ 'MAX_SESSION_DURATION','INT', 'tp.max_session_duration',     1 ],
    [ 'FILTER_ID',           'STR', 'tp.filter_id',                1 ],
    [ 'AGE',                 'INT', 'tp.age',                      1 ],
    [ 'PAYMENT_TYPE',        'INT', 'tp.payment_type',             1 ],
    [ 'MIN_SESSION_COST',    'STR', 'min_session_cost',            1 ],
    [ 'MIN_USE',             'INT', 'tp.min_use',                  1 ],
    [ 'TRAFFIC_TRANSFER_PERIOD','INT','traffic_transfer_period',   1 ],
    [ 'NEG_DEPOSIT_FILTER_ID','STR',  'tp.neg_deposit_filter_id',  1 ],
    [ 'NEG_DEPOSIT_IPPOOL',  'STR', 'tp.neg_deposit_ippool',       1 ],
    [ 'PRIORITY',            'INT', 'tp.priority',                 1 ],
    [ 'FINE',                'INT', 'tp.fine',                     1 ],
    [ 'NEXT_TARIF_PLAN',     'INT', 'tp.next_tp_id',               1 ],
    [ 'RAD_PAIRS',           'STR', 'tp.rad_pairs',                1 ],
    [ 'COMMENTS',            'STR', 'tp.comments',                 1 ],
    [ 'DOMAIN_ID',           'INT', 'tp.domain_id',                1 ],
    [ 'EXT_BILL_ACCOUNT',    'INT', 'tp.ext_bill_account',         1 ],
    [ 'EXT_BILL_FEES_METHOD','INT', 'tp.ext_bill_fees_method',     1 ],
    [ 'INNER_TP_ID',         'INT', 'tp.tp_id',                    1 ],
    [ 'TP_ID_',              'INT', 'tp.tp_id', 'tp.tp_id AS tp_id_' ],
    [ 'MODULE',              'STR', 'tp.module',                   1 ],
    [ 'IN_SPEED',            'INT', 'tt.in_speed',                 1 ],
    [ 'OUT_SPEED',           'INT', 'tt.out_speed',                1 ],
    [ 'PREPAID',             'INT', 'tt.prepaid',                  1 ],
    [ 'IN_PRICE',            'INT', 'tt.in_price',                 1 ],
    [ 'OUT_PRICE',           'INT', 'tt.out_price',                1 ],
    [ 'SERVICE_ID',          'INT', 'tp.service_id',               1 ],
    [ 'SERVICE_NAME',        'INT', 'tp.service_id', 'tp.service_id AS service_name' ],
    [ 'INTERVALS',           'INT', 'ti.id',   'COUNT(i.id) AS intervals' ],
    [ 'STATUS',              'INT', 'tp.status',                   1 ],
    [ 'DESCRIBE_AID',        'STR', 'tp.describe_aid',             1 ],
    [ 'IPPOOL',              'STR', 'tp.ippool',                   1 ],
    [ 'PROMOTIONAL',         'INT', 'tp.promotional',              1 ],
    [ 'POPULAR',             'INT', 'tp.popular',                  1 ],
  );

  if ($attr->{SHOW_ALL_COLUMNS}){
    map { $attr->{$_->[0]} = '_SHOW' unless exists $attr->{$_->[0]} } @search_columns;
  }

  my $WHERE = $self->search_former($attr, \@search_columns, {
    WHERE       => 1,
    WHERE_RULES => \@WHERE_RULES
  });

  my $fields = '';

  if (! $attr->{NEW_MODEL_TP} ) {
    $fields = "IF(SUM(i.tarif) is null or sum(i.tarif)=0, 0, 1) AS time_tarifs,
    IF(SUM(tt.in_price + tt.out_price)> 0, 1, 0) AS traf_tarifs,
    tp.payment_type,
    tp.day_fee, tp.month_fee,
    tp.logins,
    tp.age,
    tp_g.name AS tp_group_name,
    tp.rad_pairs,
    tp.reduction_fee,
    tp.postpaid_daily_fee,
    tp.postpaid_monthly_fee,
    tp.ext_bill_account,
    tp.credit,
    tp.min_use,
    tp.abon_distribution,
    ";
  }

  $self->query("SELECT tp.id,
    tp.name,
    $fields
    $self->{SEARCH_FIELDS}
    tp.small_deposit_action,
    tp.active_day_fee,
    tp.fine,
    tp.next_tp_id,
    tp.fees_method,
    tp.tp_id
    FROM tarif_plans tp
    LEFT JOIN intervals i ON (i.tp_id=tp.tp_id)
    LEFT JOIN trafic_tarifs tt ON (tt.interval_id=i.id)
    LEFT JOIN tp_groups tp_g ON (tp.gid=tp_g.id)
    $WHERE
    GROUP BY tp.tp_id
    ORDER BY $SORT $DESC;",
    undef,
    $attr
  );

  return $self->{list} || [];
}

#**********************************************************
=head2 nas_list($attr) list_allow nass

=cut
#**********************************************************
sub nas_list {
  my $self = shift;
  my ($attr) = @_;

  if ($attr->{NAS_ID}) {
    $self->query("SELECT tp_id FROM tp_nas WHERE nas_id= ? ;",
    undef, { Bind => [ $self->{NAS_ID} ] });
  }
  else {
    $self->query("SELECT nas_id FROM tp_nas WHERE tp_id= ? ;",
      undef, { Bind => [ $self->{TP_ID} ] });
  }

  return $self->{list};
}

#**********************************************************
=head2 nas_add($nas)

=cut
#**********************************************************
sub nas_add {
  my $self = shift;
  my ($nas) = @_;

  $self->nas_del();
  my @MULTI_QUERY = ();

  foreach my $line (@$nas) {
    push @MULTI_QUERY, [
       $line, 
       $self->{TP_ID}
     ];
  }

  $self->query("INSERT INTO tp_nas (nas_id, tp_id)
        VALUES (?, ?);", undef,
    { MULTI_QUERY => \@MULTI_QUERY }
    );

  $self->{admin}->system_action_add("TP_NAS:$self->{TP_ID} NAS:" . (join(',', @$nas)), { TYPE => 1 });
  return $self;
}

#**********************************************************
=head2 nas_del()

=cut
#**********************************************************
sub nas_del {
  my $self = shift;
  $self->query_del('tp_nas', undef, { tp_id => $self->{TP_ID} });

  #$admin->action_add($uid, "DELETE NAS");
  return $self;
}

#**********************************************************
# tt_defaults
#**********************************************************
sub tt_defaults {
  my $self = shift;

  my %TT_DEFAULTS = (
    IN_PRICE  => '0.00000',
    OUT_PRICE => '0.00000',
    PREPAID   => 0,
    IN_SPEED  => 0,
    OUT_SPEED => 0
  );

  while (my ($k, $v) = each %TT_DEFAULTS) {
    $self->{$k} = $v;
  }

  return $self;
}

#**********************************************************
=head2 tt_list($attr)

=cut
#**********************************************************
sub tt_list {
  my $self = shift;
  my ($attr) = @_;

  if (defined($attr->{TI_ID})) {
    my $show_nets = ($attr->{SHOW_NETS}) ? ', tc.nets' : '';

    $self->query("SELECT tt.id, in_price, out_price, prepaid, in_speed,
      out_speed, descr, tc.name, expression, tt.net_id $show_nets
     FROM trafic_tarifs  tt 
     LEFT JOIN  traffic_classes tc ON (tc.id=tt.net_id)
     WHERE tt.interval_id='$attr->{TI_ID}'
     ORDER BY tt.id DESC;",
     undef,
     $attr
    );
  }
  else {
    $self->query("SELECT id, in_price, out_price, prepaid, in_speed, out_speed, descr, net_id, expression
     FROM trafic_tarifs tt
     WHERE tp_id='$self->{TP_ID}'
     ORDER BY tt.id;",
     undef,
     $attr
    );
  }

  return $self->{list};
}

#**********************************************************
=head2 tt_info($attr)

=cut
#**********************************************************
sub tt_info {
  my $self = shift;
  my ($attr) = @_;

  $self->query("SELECT *
     FROM trafic_tarifs 
     WHERE 
       interval_id= ? AND id= ? ;",
  undef,
  { INFO => 1,
    Bind => [ $attr->{TI_ID}, $attr->{TT_ID} ] } 
  );

  $self->{TT_ID}=$attr->{TT_ID};

  return $self;
}

#**********************************************************
=head2 tt_add($attr)

=cut
#**********************************************************
sub tt_add {
  my $self = shift;
  my ($attr) = @_;

  $attr->{ID}=$attr->{TT_ID};
  $attr->{INTERVAL_ID}=$attr->{tt};

  $self->query_add('trafic_tarifs', $attr);

  $self->{admin}->system_action_add("TT:$self->{INSERT_ID} TI:$attr->{TI_ID}", { TYPE => 1 });

  return $self;
}

#**********************************************************
=head2 tt_change($attr)

=cut
#**********************************************************
sub tt_change {
  my $self = shift;
  my ($attr) = @_;

  $attr->{ID}=$attr->{TT_ID};
  $attr->{INTERVAL_ID}=$attr->{tt};

  $self->changes({
    CHANGE_PARAM => 'INTERVAL_ID,ID',
    TABLE        => 'trafic_tarifs',
    DATA         => $attr
  });

  return $self;
}

#**********************************************************
=head2 tt_del($attr)

=cut
#**********************************************************
sub tt_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('trafic_tarifs', undef, { interval_id=> $attr->{TI_ID},
                                             id         => $attr->{TT_ID} 
                                            });

  $self->{admin}->system_action_add("TT:$attr->{TT_ID} TI:$attr->{TI_ID}", { TYPE => 10 });

  return $self;
}

#**********************************************************
=head2 holidays_list($attr)

=cut
#**********************************************************
sub holidays_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  my $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  $self->query(
    "SELECT * FROM holidays
    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list};

  return $self->{list} if ($self->{TOTAL} < 1);

  $self->query(
    "SELECT count(*) AS total 
   FROM holidays",
    undef,
    { INFO => 1 }
  );

  return $list;
}

#**********************************************************
=head2 holidays_change($attr)

=cut
#**********************************************************
sub holidays_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes(
    {
      CHANGE_PARAM => 'DAY',
      TABLE        => 'holidays',
      DATA         => $attr
    }
  );

  return $self;
}

#**********************************************************
=head2 holiday_info($attr)

=cut
#**********************************************************
sub holidays_info {
  my $self = shift;
  my ($attr) = @_;

  if ($attr->{DAY}) {
    $self->query(
      "SELECT * FROM holidays
      WHERE day = ?;", undef, { INFO => 1, Bind => [ $attr->{DAY} ] }
    );
  }

  return $self;
}

#**********************************************************
=head2 holidays_add()

=cut
#**********************************************************
sub holidays_add {
  #my $self = shift;
  #my ($attr) = @_;
#
  #$attr->{MONTH} = (defined($attr->{MONTH})) ? $attr->{MONTH} : 1;
  #$attr->{DAY}   = (defined($attr->{DAY}))   ? $attr->{DAY}   : 1;
  #$attr->{DESCR} = (defined($attr->{DESCR}))   ? $attr->{DESCR}   : '';
  #$self->query("INSERT INTO holidays (day)
  #     VALUES ('$attr->{MONTH}-$attr->{DAY});", 'do'
  #);
  #$self->query("INSERT INTO holidays (descr)
  #     VALUES ('$attr->{DESCR});", 'do'
  #);
#
  #$admin->system_action_add("HOLIDAYS:$self->{INSERT_ID} $attr->{MONTH}-$attr->{DAY}", { TYPE => 1 });
  #return $self;

  my $self = shift;
  my ($attr) = @_;

  $self->query_add('holidays', $attr);
  $self->{admin}->system_action_add("HOLIDAYS:$self->{INSERT_ID} $attr->{MONTH}-$attr->{DAY}", { TYPE => 1 });

  return $self;
}

#**********************************************************
=head2 holidays_del($id)

=cut
#**********************************************************
sub holidays_del {
  my $self = shift;
  my ($id) = @_;

  $self->query_del('holidays', undef, { day => $id });

  $self->{admin}->system_action_add("HOLIDAYS:$id", { TYPE => 10 });
  return $self;
}

#**********************************************************
=head2 traffic_class_add($attr)

=cut
#**********************************************************
sub traffic_class_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('traffic_classes', $attr );

  return [ ] if ($self->{errno});

  $self->{admin}->system_action_add("TRAFFIC_CLASS: $attr->{NAME}", { TYPE => 1 });
  return $self;
}

#**********************************************************
=head2 traffic_class_change($attr)

=cut
#**********************************************************
sub traffic_class_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'traffic_classes',
      DATA         => $attr
    }
  );

  $self->traffic_class_info($attr->{ID});
  return $self;
}

#**********************************************************
=head2 traffic_class_del($attr)

=cut
#**********************************************************
sub traffic_class_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('traffic_classes', $attr);

  $self->{admin}->action_add($self->{UID}, $self->{UID}, { TYPE => 10 });
  return $self->{result};
}

#**********************************************************
=head2 traffic_class_list()

=cut
#**********************************************************
sub traffic_class_list {
  my $self   = shift;
  my ($attr) = @_;

  my $WHERE =  $self->search_former($attr, [
        [ 'NETS',          'STR', 'nets' ],
    ],
    { 
    	WHERE => 1
    }
  );

  $self->query("SELECT id, name, nets, comments, changed
     FROM traffic_classes
     $WHERE;",
     undef,
     $attr
  );

  my $list = $self->{list};

  return $list;
}

#**********************************************************
=head2 traffic_class_info($id)

=cut
#**********************************************************
sub traffic_class_info {
  my $self = shift;
  my ($id) = @_;

  $self->query("SELECT *
     FROM traffic_classes
   WHERE id=?;",
   undef,
   { INFO => 1,
     Bind => [ $id ] 
   }
  );

  return $self;
}

#*******************************************************************
=head2 add_tp_geo($attr) - add tp geo info

  Arguments:
    %$attr
      NAME             - position's name;

  Returns:
    $self object

  Examples:
    $Internet->add_tp_geo({
      STREET_ID          => 1,
      GID        => 2,

    });

=cut
#*******************************************************************
sub add_tp_geo {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('tp_geolocation', { %$attr });

  return $self;
}

#*******************************************************************
=head2 del_tp_geo() - delete tp geolocation from db

  Arguments:
    $attr

  Returns:

  Examples:
    $Internet->del_tp_geo( {GID => 1} );

=cut
#*******************************************************************
sub del_tp_geo {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('tp_geolocation', undef, { tp_gid => $attr->{TP_GID} });

  return $self;
}

#**********************************************************
=head2 tp_geo_list() - get geo list

  Arguments:
    $attr
  Returns:
    @list

  Examples:
    my $list = $Internet->tp_geo_list({COLS_NAME=>1});

=cut
#**********************************************************
sub tp_geo_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  my $EXT_TABLE = '';
  my $EXT_COLUMNS = '';
  my @WHERE_RULES = ();

  if ($attr->{EMPTY_GEOLOCATION}) {
    $self->query(
      "SELECT id AS gid FROM tp_groups WHERE id NOT IN(SELECT tp_gid FROM tp_geolocation GROUP BY tp_gid)
      ORDER BY $SORT $DESC;", undef, $attr
    );

    return $self->{list};
  }

  my $WHERE = $self->search_former($attr, [
    [ 'TP_GID',      'INT', 'tpg.tp_gid',      1 ],
    [ 'STREET_ID',   'INT', 'tpg.street_id',   1 ],
    [ 'BUILD_ID',    'INT', 'tpg.build_id',    1 ],
    [ 'DISTRICT_ID', 'INT', 'tpg.district_id', 1 ],
  ], { WHERE => 1, WHERE_RULES => \@WHERE_RULES });

  $self->query(
    "SELECT tpg.tp_gid, tpg.street_id, tpg.build_id, tpg.district_id $EXT_COLUMNS FROM tp_geolocation AS tpg
    $EXT_TABLE
    $WHERE
    ORDER BY $SORT $DESC;", undef, $attr
  );

  return $self->{list};
}

#*******************************************************************
=head2 add_tp_group_users_groups($attr) -

  Arguments:
    %$attr
      NAME             - position's name;

  Returns:
    $self object

=cut
#*******************************************************************
sub add_tp_group_users_groups {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('tp_groups_users_groups', { %$attr });

  return $self;
}

#*******************************************************************
=head2 del_tp_group_users_groups() -

  Arguments:
    $attr

  Returns:

=cut
#*******************************************************************
sub del_tp_group_users_groups {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('tp_groups_users_groups', undef, { tp_gid => $attr->{TP_GID} });

  return $self;
}

#**********************************************************
=head2 tp_group_users_groups_info() - get geo list

  Arguments:
    $attr
  Returns:
    @list

=cut
#**********************************************************
sub tp_group_users_groups_info {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $GROUP_BY = ($attr->{GROUP_BY}) ? $attr->{GROUP_BY} : 'GROUP BY tpug.id';

  my $EXT_TABLE = '';
  my $EXT_COLUMNS = '';
  my @WHERE_RULES = ();

  if ($attr->{EMPTY_GROUP}) {
    push @WHERE_RULES, "tpug.tp_gid IS NULL";
    $EXT_COLUMNS .= ', g.id AS g_gid';
    $GROUP_BY = '';
  }

  my $WHERE = $self->search_former($attr, [
    [ 'TP_GID',  'INT', 'tpug.tp_gid',                                      1 ],
    [ 'TP_GID2', 'INT', 'g.id',                                             1 ],
    [ 'GID',     'INT', 'tpug.gid',                                         1 ],
    [ 'TP_GIDS', 'INT', 'GROUP_CONCAT(DISTINCT tpug.tp_gid) AS tp_gids',    1 ],
    [ 'GIDS',    'INT', 'GROUP_CONCAT(DISTINCT tpug.gid) AS gids',          1 ],
  ], { WHERE => 1, WHERE_RULES => \@WHERE_RULES });

  if ($attr->{EMPTY_GROUP}) {
    $self->query(
      "SELECT $self->{SEARCH_FIELDS} tpug.id $EXT_COLUMNS
    FROM tp_groups g
    LEFT JOIN tp_groups_users_groups tpug ON (tpug.tp_gid=g.id)
    $WHERE
    $GROUP_BY
    ORDER BY $SORT $DESC;", undef, $attr
    );

    return $self->{list} || [];
  }

  $self->query(
    "SELECT $self->{SEARCH_FIELDS} tpug.id $EXT_COLUMNS
    FROM tp_groups_users_groups tpug
    $EXT_TABLE
    $WHERE
    $GROUP_BY
    ORDER BY $SORT $DESC;", undef, $attr
  );

  return $self->{list} || [];
}


1
