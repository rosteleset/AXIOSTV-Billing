=head1 NAME

  Voip Configure

=cut

use strict;
use warnings FATAL => 'all';

our (
  %lang,
  %permissions,
  @bool_vals,
  @status,
  $admin,
  $db
);

use Voip::Constants qw/TRUNK_PROTOCOLS/;
our Voip $Voip;
our AXbills::HTML $html;

my $Tariffs = Tariffs->new($db, \%conf, $admin);
my $debug //= 0;

require Control::System;

#**********************************************************
=head2 voip_tp()  - Tarif plans

=cut
#**********************************************************
sub voip_tp {
  #my ($attr) = @_;

  my @payment_types = ($lang{PREPAID}, $lang{POSTPAID});

  my $Voip_tp = $Voip->tp_defaults();
  $Voip_tp->{LNG_ACTION} = $lang{ADD};
  $Voip_tp->{ACTION} = 'ADD_TP';

  if ($FORM{ADD_TP}) {
    if (!$FORM{NAME}) {
      $html->message('err', $lang{ERROR}, $lang{ERR_WRONG_NAME});
    }
    else {
      if ($FORM{create_fees_type}) {
        my $Fees = Finance->fees($db, $admin, \%conf);
        $Fees->fees_type_add({ NAME => $FORM{NAME} });
        $FORM{FEES_METHOD} = $Fees->{INSERT_ID};
      }
      $Voip->tp_add({ %FORM });
      if (!$Voip->{errno}) {
        $html->message('info', $lang{ADDED}, "$lang{ADDED} $Voip->{TP_ID}" .
          $html->button($lang{INTERVALS}, 'index=' . get_function_index('voip_intervals') . "&TP_ID=$Voip->{TP_ID}"
            , { BUTTON => 1 }));
      }
    }
  }
  elsif ($FORM{TP_ID}) {
    $Voip_tp = $Voip->tp_info($FORM{TP_ID});
    my $tp_id = $Voip->{TP_ID} || $FORM{TP_ID} || 0;

    if (_error_show($Voip_tp)) {
      return 0;
    }

    if ($FORM{qindex}) {
      voip_tp_routes({ TP => $Voip_tp });
      return 0;
    }

    $pages_qs .= "&TP_ID=$tp_id" if ($tp_id);
    $pages_qs .= "&subf=$FORM{subf}" if ($FORM{subf});

    $LIST_PARAMS{TP} = $tp_id;
    my %F_ARGS = (TP => $Voip_tp);

    $FORM{add_form} = 1;

    $Voip_tp->{NAME_SEL} = $html->form_main({
      CONTENT => $html->form_select(
        'TP_ID',
        {
          SELECTED   => $tp_id,
          SEL_LIST   => $Voip->tp_list({ %LIST_PARAMS, COLS_NAME => 1 }),
          SEL_KEY    => 'tp_id',
          SEL_VALUE  => 'id,name',
          AUTOSUBMIT => 'form',
          NO_ID      => 1
        }
      ),
      HIDDEN  => {
        index => $index,
        show  => 1
      },
      class   => 'form-inline ml-auto flex-nowrap',
    });

    $index = get_function_index('voip_tp');
    if ($FORM{subf} && $index == $FORM{subf}) {
      delete $FORM{subf};
    }

    func_menu(
      {
        $lang{NAME} => $Voip_tp->{NAME_SEL}
      },
      [
        $lang{INFO} . ":&add_form=1&TP_ID=$tp_id",
        $lang{USERS} . ':' . get_function_index('voip_users_list') . ":TP_ID=$tp_id",
        $lang{INTERVALS} . ':' . get_function_index('voip_intervals') . ":TP_ID=$tp_id",
      ],
      { f_args => \%F_ARGS }
    );

    if ($FORM{subf}) {
      return 0;
    }
    elsif ($FORM{change}) {
      if ($FORM{create_fees_type}) {
        my $Fees = Finance->fees($db, $admin, \%conf);
        $Fees->fees_type_add({ NAME => $FORM{NAME} });
        $FORM{FEES_METHOD} = $Fees->{INSERT_ID};
      }
      $Voip->tp_change($FORM{TP_ID}, { %FORM });
      if (!$Voip->{errno}) {
        $html->message('info', $lang{CHANGED}, "$lang{CHANGED} " . $tp_id);
      }
    }

    $Voip_tp->{LNG_ACTION} = $lang{CHANGE};
    $Voip_tp->{ACTION} = 'change';
  }
  elsif ($FORM{del} && $FORM{COMMENTS}) {
    $Voip->tp_del($FORM{del});

    if (!$Voip->{errno}) {
      $html->message('info', $lang{DELETED}, "$lang{DELETED} $FORM{del}");
    }
  }

  _error_show($Voip);

  if ($FORM{add_form}) {
    $Voip_tp->{PAYMENT_TYPE_SEL} = $html->form_select('PAYMENT_TYPE', {
      SELECTED     => $Voip_tp->{PAYMENT_TYPE},
      SEL_ARRAY    => \@payment_types,
      ARRAY_NUM_ID => 1
    });

    $Voip_tp->{SEL_METHOD} = $html->form_select('FEES_METHOD', {
      SELECTED       => $Voip_tp->{FEES_METHOD} || 1,
      SEL_HASH       => get_fees_types(),
      NO_ID          => 1,
      SORT_KEY       => 1,
      SEL_OPTIONS    => { 0 => '' },
      MAIN_MENU      => get_function_index('form_fees_types'),
      CHECKBOX       => 'create_fees_type',
      CHECKBOX_TITLE => $lang{CREATE}
    });

    $Voip_tp->{GROUPS_SEL} = $html->form_select('TP_GID', {
      SELECTED       => $Voip_tp->{TP_GID} || '',
      SEL_LIST       => $Tariffs->tp_group_list({ COLS_NAME => 1 }),
      SEL_OPTIONS    => { '' => '--' },
      MAIN_MENU      => get_function_index('form_tp_groups'),
      MAIN_MENU_ARGV => "chg=" . ($Voip_tp->{TP_GID} || q{})
    });

    $Voip_tp->{POSTPAID_DAY_FEE} = ($Voip_tp->{POSTPAID_DAY_FEE}) ? 'checked' : '';
    $Voip_tp->{POSTPAID_MONTH_FEE} = ($Voip_tp->{POSTPAID_MONTH_FEE}) ? 'checked' : '';

    $html->tpl_show(_include('voip_tp', 'Voip'), $Voip_tp);
  }

  my $list = $Voip->tp_list({
    %LIST_PARAMS,
    PAYMENT_TYPE => '_SHOW',
    COLS_NAME    => 1,
    MODULE       => 'Voip'
  });

  my $table = $html->table({
    width   => '100%',
    caption => $lang{TARIF_PLANS},
    title   => [ '#', $lang{NAME}, $lang{HOUR_TARIF}, $lang{PAYMENT_TYPE}, $lang{DAY_FEE}, $lang{MONTH_FEE},
      $lang{SIMULTANEOUSLY}, $lang{AGE}, '-' ],
    ID      => 'VOIP_TP',
    MENU    => "$lang{ADD}:index=$index&add_form=1:add",
  });

  my ($delete, $change);
  foreach my $line (@{$list}) {
    my $tp_id = $line->{tp_id} || 0;
    if ($permissions{4} && $permissions{4}{1}) {
      $delete = $html->button($lang{DEL}, "index=$index&del=$tp_id",
        { MESSAGE => "$lang{DEL} ?", class => 'del' });
      $change = $html->button($lang{INFO}, "index=$index&TP_ID=$tp_id", { class => 'change' });
    }

    if ($FORM{TP_ID} && $FORM{TP_ID} eq $tp_id) {
      $table->{rowcolor} = 'table-success';
    }
    else {
      undef($table->{rowcolor});
    }

    $table->addrow(
      $html->b($line->{id}),
      $html->button($line->{name}, "index=$index&TP_ID=$tp_id"),
      $bool_vals[ $line->{time_tarifs} || 0 ],
      $payment_types[ $line->{payment_type} || 0 ],
      $line->{day_fee},
      $line->{month_fee},
      $line->{logins},
      $line->{age},
      $html->button('',
        "index=" . get_function_index('voip_intervals') . "&TP_ID=$tp_id",
        { class => 'interval', TITLE => $lang{INTERVALS}, ADD_ICON => ' fa fa-align-left' })
        . $change
        . $delete
    );
  }

  print $table->show();

  $table = $html->table({
    width => '100%',
    rows  => [ [ "$lang{TOTAL}:", $html->b($Voip->{TOTAL}) ] ]
  });

  print $table->show();

  return 1;
}

#**********************************************************
=head2 voip_trunks()

=cut
#**********************************************************
sub voip_trunks {
  $Voip->{ACTION} = 'add';
  $Voip->{LNG_ACTION} = $lang{ADD};

  if ($FORM{add}) {
    $Voip->trunk_add({ %FORM });
    if (!$Voip->{errno}) {
      $html->message('info', $lang{ADDED}, "$lang{ADDED} " . ($Voip->{TRUNK_ID} || ''));
    }
  }
  elsif ($FORM{change}) {
    $Voip->trunk_change({ %FORM });
    if (!$Voip->{errno}) {
      $html->message('info', $lang{INFO}, "$lang{CHANGED}");
    }
  }
  elsif ($FORM{chg}) {
    $Voip->trunk_info($FORM{chg});
    if (!$Voip->{errno}) {
      $html->message('info', $lang{INFO}, "$lang{CHANGING}");
    }

    $Voip->{ACTION} = 'change';
    $Voip->{LNG_ACTION} = $lang{CHANGE};
  }
  elsif ($FORM{del} && $FORM{COMMENTS}) {
    $Voip->trunk_del($FORM{del});
    if (!$Voip->{errno}) {
      $html->message('info', $lang{DELETED}, "$lang{DELETED} $FORM{del}");
    }
  }

  if (_error_show($Voip)) {
    return 0;
  }

  $Voip->{DISABLE} = ' checked' if ($Voip->{DISABLE} && $Voip->{DISABLE} == 1);
  $Voip->{FAILOVER_TRUNK_SEL} = $html->form_select('FAILOVER_TRUNK', {
    SELECTED    => $Voip->{FAILOVER_TRUNK},
    SEL_LIST    => $Voip->trunk_list({ COLS_NAME => 1 }),
    SEL_OPTIONS => { 1 => $lang{MAIN} },
  });

  $Voip->{PROTOCOL_SEL} = $html->form_select('PROTOCOL', {
    SELECTED  => $Voip->{PROTOCOL},
    SEL_ARRAY => TRUNK_PROTOCOLS,
  });

  $html->tpl_show(_include('voip_trunk', 'Voip'), $Voip);

  my $list = $Voip->trunk_list({
    ID        => '_SHOW',
    NAME      => '_SHOW',
    PROTOCOL  => '_SHOW',
    PROVNAME  => '_SHOW',
    FAILTRUNK => '_SHOW',
    %LIST_PARAMS,
  });

  my $table = $html->table({
    width   => '100%',
    caption => "$lang{TRUNKS}",
    title   => [ 'ID', $lang{NAME}, $lang{PROTOCOL}, "VOIP $lang{PROVIDER}", "$lang{FAILOVER_TRUNK}", '-', '-' ],
    qs      => $pages_qs,
    pages   => $Voip->{TOTAL},
    ID      => 'VOIP_TRUNKS',
  });

  my ($delete, $change);
  foreach my $line (@{$list}) {
    if ($permissions{4}{1}) {
      $delete = $html->button($lang{DEL}, "index=$index&del=$line->[0]",
        { MESSAGE => "$lang{DEL} $line->[0]?", class => 'del' });
      $change = $html->button($lang{CHANGE}, "index=$index&chg=$line->[0]", { class => 'change' });
    }

    $table->addrow($line->[0], $line->[1], $line->[2], $line->[3], $line->[4], $change, $delete);

  }
  print $table->show();

  $table = $html->table({
    width => '100%',
    rows  => [ [ "$lang{TOTAL}:", $html->b($Voip->{TOTAL}) ] ]
  });

  print $table->show();

  return 1;
}

#**********************************************************
=head2 voip_routes() - Voip routes managment

=cut
#**********************************************************
sub voip_routes {

  $Voip->{ACTION} = 'add';
  $Voip->{LNG_ACTION} = $lang{ADD};
  $Voip->{PARENT_ID} = 0;

  if ($FORM{add}) {
    $Voip->route_add({ %FORM });
    if (!$Voip->{errno}) {
      $html->message('info', $lang{ADDED}, "$lang{ADDED} " . ($Voip->{ROUTE_ID} || q{}));
    }
  }
  elsif ($FORM{import}) {
    my $content = $FORM{ROUTE_FILE}{Contents};
    my @rows_arr = split(/\n/, $content);

    my $count = 0;

    foreach my $line (@rows_arr) {
      chop($line);
      my ($prefix, $name, $status) = split(/\t/, $line);
      $Voip->route_add(
        {
          ROUTE_PREFIX => $prefix,
          ROUTE_NAME   => $name,
          DISABLE      => $status,
          REPLACE      => 1
        }
      );
      $count++;
    }

    if (!$Voip->{errno}) {
      $html->message('info', $lang{INFO}, "$lang{IMPORT} $lang{FILE}: $FORM{ROUTE_FILE}{filename} ADDED: $count");
    }
  }
  elsif ($FORM{export}) {
    print "Content-Type: text/plain\n\n";
    my $list = $Voip->routes_list({ PAGE_ROWS => 100000 });
    printf("%-12s| %-40s| %-8s| %-10s|\n" . "---------------------------------------------------------------------\n",
      $lang{PREFIX}, $lang{NAME}, $lang{STATUS}, $lang{CHANGED});

    foreach my $line (@{$list}) {
      printf("%-12s| %-40s| %-8s| %-10s|\n", $line->[0], $line->[1], $status[ $line->[2] ], $line->[3]);
    }
    return 0;
  }
  elsif ($FORM{change}) {
    $Voip->route_change({ %FORM });
    if (!$Voip->{errno}) {
      $html->message('info', $lang{INFO}, "$lang{CHANGED}");
    }
  }
  elsif ($FORM{del}) {
    $Voip->route_del($FORM{del});
    if (!$Voip->{errno}) {
      $html->message('info', $lang{INFO}, $lang{DELETED});
    }
  }

  if ($FORM{add_route}) {
    my $list = $Voip->routes_list({ PAGE_ROWS => 100000 });

    my %route_items = ();
    foreach my $line (@{$list}) {
      $route_items{ $line->[0] }{ $line->[5] } = $line->[1];
    }

    my $root_index = $FORM{add_route};
    my $h = $route_items{$root_index};
    $Voip->{PARENT_ID} = $root_index;
    my $menu_navigator;
    my %tree;
    while (my ($par_key, $name) = each(%{$h})) {
      $menu_navigator = $html->button("$name", "index=$index&ROUTE_ID=$root_index") . $menu_navigator;
      $tree{$root_index} = 1;
      if ($par_key > 0) {
        $root_index = $par_key;
        $h = $route_items{$par_key};
      }
    }

    $Voip->{PARENT} = $menu_navigator;

  }
  elsif ($FORM{ROUTE_ID}) {
    $Voip->route_info($FORM{ROUTE_ID}, { %FORM });
    if (!$Voip->{errno}) {
      $html->message('info', $lang{INFO}, "$lang{CHANGING}");
    }

    $Voip->{ACTION} = 'change';
    $Voip->{LNG_ACTION} = $lang{CHANGE};
    $FORM{add_form} = 1;
  }
  elsif (defined($FORM{del}) && $FORM{COMMENTS}) {
    $Voip->route_del($FORM{del});
    if (!$Voip->{errno}) {
      $html->message('info', $lang{DELETED}, "$lang{DELETED} $FORM{del}");
    }
  }

  if ($Voip->{errno}) {
    if ($Voip->{errno} == 7) {
      $html->message('err', $lang{ERROR}, "$lang{PREFIX} $lang{EXIST}");
    }
    else {
      _error_show($Voip);
      return 0;
    }
  }

  $Voip->{DISABLE} = ' checked' if ($Voip->{DISABLE} && $Voip->{DISABLE} == 1);

  if ($FORM{add_form}) {
    $html->tpl_show(_include('voip_route', 'Voip'), $Voip);
  }

  my %SEARCH_FIELDS = (
    $lang{PREFIX}   => "ROUTE_PREFIX",
    $lang{NAME}     => "ROUTE_NAME",
    $lang{DISABLE}  => "DISABLE",
    $lang{DESCRIBE} => "DESCRIBE"
  );

  my $output = '';
  if ($FORM{search_form}) {
    $output .= form_search({ SIMPLE => \%SEARCH_FIELDS, });
  }

  my $list = $Voip->routes_list({ %LIST_PARAMS, COLS_NAME => 1 });

  my $table = $html->table({
    width          => '100%',
    caption        => $lang{ROUTES},
    title          => [ $lang{PREFIX}, $lang{NAME}, $lang{STATUS}, $lang{DATE}, '-', '-' ],
    qs             => $pages_qs,
    pages          => $Voip->{TOTAL},
    ID             => 'VOIP_ROUTES',
    header         => $html->button($lang{EXPORT}, "qindex=$index&export=1", { BUTTON => 1 }),
    MENU           => "$lang{ADD}:index=$index&add_form=1:add;$lang{SEARCH}:index=$index&search_form=1:search",
    SHOW_FULL_LIST => 1,
    EXPORT         => 1
  });

  my ($delete, $change);
  foreach my $line (@{$list}) {
    if ($permissions{4}{1}) {
      $delete = $html->button($lang{DEL}, "index=$index&del=$line->{id}",
        { MESSAGE => "$lang{DEL} $line->{prefix} ?", class => 'del' });
      $change = $html->button($lang{CHANGE}, "index=$index&ROUTE_ID=$line->{id}", { class => 'change' });
    }

    $table->addrow($line->{prefix},
      $line->{name},
      $status[ $line->{disable} ],
      $line->{date},
      $change . ' ' . $delete);
  }

  my $table2 = $html->table({
    width => '100%',
    rows  =>
      [ [ "$lang{IMPORT} $lang{FILE}: " . $html->form_input('ROUTE_FILE', "ROUTE_FILE",
        { TYPE => 'FILE' }) . $html->form_input(
        'import', $lang{IMPORT}, { TYPE => 'submit' }) ] ]
  });

  print $html->form_main({
    CONTENT => $table->show() . $table2->show(),
    ENCTYPE => 'multipart/form-data',
    NAME    => 'VOIP_ROUTES',
    ID      => 'VOIP_ROUTES',
    HIDDEN  => {
      index => $index,
      subf  => $FORM{subf}
    },
  });

  $table = $html->table({
    width => '100%',
    rows  => [ [ "$lang{TOTAL}:", $html->b($Voip->{TOTAL}) ] ]
  });

  print $table->show();

  return 1;
}

#**********************************************************
=head2 voip_tp_routes() - TP routes

=cut
#**********************************************************
sub voip_tp_routes {
  my ($attr) = @_;

  my $Voip_tp;
  my @caption = ($lang{PREFIX}, $lang{ROUTES}, $lang{STATUS}, $lang{EXTRA_TARIFICATION}, 'TRUNK');
  my @interval_ids = ();
  my $intervals = 0;
  my $exchange_rate = 1;

  $Conf->config_info({ PARAM => 'VOIP_ER' });
  if ($Conf->{TOTAL}) {
    $exchange_rate = $Conf->{VALUE};
  }

  if (defined($attr->{TP})) {
    $Voip_tp = $attr->{TP};

    #Get time intervals
    my @DAY_NAMES = ($lang{ALL}, 'Sun', 'Mon', 'Tue', 'Wen', 'The', 'Fri', 'Sat', $lang{HOLIDAYS});
    my $list = $Voip_tp->ti_list({ %LIST_PARAMS });
    foreach my $line (@{$list}) {
      push @caption, "$lang{SUM} (Min): " . $DAY_NAMES[ $line->[1] ] . "/ $line->[2]-$line->[3]";
      push @interval_ids, $line->[0];
    }
    $intervals = $Voip_tp->{TOTAL};

    if ($FORM{change}) {
      $Voip->rp_add({ %FORM, EXCHANGE_RATE => $exchange_rate });
      if (!$Voip->{errno}) {
        $html->message('info', $lang{INFO}, "$lang{ADDED}");
      }
    }
    elsif ($FORM{import}) {
      $list = $Voip->routes_list({ %LIST_PARAMS, PAGE_ROWS => 100000 });
      my %prefix_id = ();
      foreach my $line (@{$list}) {
        $prefix_id{ $line->[0] } = $line->[4];
      }

      my $content = $FORM{ROUTE_FILE}{Contents};
      return $html->message('err', $lang{ERROR}, "$lang{EMPTY} $lang{FILE}") if (!$content);
      my @rows_arr = split(/\n/, $content);
      my %FORM2 = ();

      foreach my $line (@rows_arr) {
        chop($line);
        my ($prefix, $trunk, $et, @prices) = split(/\t/, $line);
        for (my $i = 0; $i <= $#prices; $i++) {
          $FORM2{ 't_' . $prefix_id{$prefix} . '_' . $interval_ids[$i] } = $trunk;
          $FORM2{ 'et_' . $prefix_id{$prefix} . '_' . $interval_ids[$i] } = $et;
          if ($conf{VOIP_UNIT_TARIFICATION}) {
            $FORM2{ 'up_' . $prefix_id{$prefix} . '_' . $interval_ids[$i] } = $prices[$i] || 0;
            $FORM2{ 'p_' . $prefix_id{$prefix} . '_' . $interval_ids[$i] } = $prices[$i] * $exchange_rate;
          }
          else {
            $FORM2{ 'p_' . $prefix_id{$prefix} . '_' . $interval_ids[$i] } = $prices[$i];
          }
        }
      }

      $Voip->rp_add({ %FORM2, EXCHANGE_RATE => $exchange_rate });
      if (!$Voip->{errno}) {
        $html->message('info', $lang{INFO},
          "$lang{IMPORT} $lang{FILE}: $FORM{ROUTE_FILE}{filename}\n $lang{ROWS}: $#rows_arr\n $lang{CHANGED}: $Voip->{TOTAL}");
      }
    }
    elsif ($FORM{export_rp}) {
      print "Content-Type: text/plain\n\n";
      $LIST_PARAMS{PAGE_ROWS} = 100000;
    }
    elsif ($FORM{clear}) {

    }
  }
  else {
    voip_tp({ f => 'voip_tp_routes' });
    return 0;
  }

  _error_show($Voip);

  $pages_qs = '';

  if (!$FORM{export_rp}) {
    form_search({
      SIMPLE        => {
        $lang{PREFIX}   => "ROUTE_PREFIX",
        $lang{NAME}     => "ROUTE_NAME",
        $lang{DISABLE}  => "DISABLE",
        $lang{DESCRIBE} => "DESCRIBE",
        $lang{GATEWAY}  => "GATEWAY_SEL",
        $lang{SUM}      => "PRICE"
      },
      HIDDEN_FIELDS => {
        TP_ID  => $FORM{TP_ID},
        routes => $FORM{routes},
        subf   => $FORM{subf},
      }
    });
  }

  my $list = $Voip->rp_list({ %LIST_PARAMS });
  my %prices = ();
  my %trunks = ();
  my %et = ();
  my %unit_prices = ();
  foreach my $line (@{$list}) {
    $prices{"$line->[0]"}{"$line->[1]"} = $line->[3];
    $trunks{"$line->[0]"}{"$line->[1]"} = $line->[4];
    $et{"$line->[0]"}{"$line->[1]"} = $line->[5];
    $unit_prices{"$line->[0]"}{"$line->[1]"} = $line->[6];
  }

  my $price = 0;
  my $trunk = 0;
  my $unit_price = 0;
  my @export_arr = ();
  my $TRUNKS_MARR = $Voip->trunk_list({ NAME => '_SHOW', COLS_NAME => 1 });

  _error_show($Voip);

  my $extra_tarification_list = $Voip->extra_tarification_list({ COLS_NAME => 1 });

  $pages_qs .= "&routes=$FORM{routes}";
  $list = $Voip->routes_list({ %LIST_PARAMS });

  my $table = $html->table({
    width   => '100%',
    caption => $lang{ROUTES},
    title   => \@caption,
    qs      => $pages_qs . "&TP_ID=$FORM{TP_ID}" . ($FORM{subf} ? "&subf=$FORM{subf}" : ''),
    pages   => $Voip->{TOTAL},
    ID      => 'VOIP_ROUTES_PRICES',
    header  => $html->button($lang{EXPORT}, "export_rp=1&qindex=$index&TP_ID=$FORM{TP_ID}&routes=$FORM{routes}",
      { ex_params => 'TARGET=_new', BUTTON => 1 })
  });

  foreach my $line (@{$list}) {
    my @l = ();
    my $i = 0;
    for ($i = 0; $i < $intervals; $i++) {

      if (defined($prices{"$interval_ids[$i]"}{"$line->[4]"})) {
        $price = $prices{ $interval_ids[$i] }{ $line->[4] };
        $unit_price = $unit_prices{ $interval_ids[$i] }{ $line->[4] };
        $trunk = $trunks{ $interval_ids[$i] }{ $line->[4] } || $trunks{ $interval_ids[0] }{ $line->[4] };
      }
      else {
        $price = '0.00';
        $unit_price = '0.00';
        $price .= " $interval_ids[$i] $line->[4] -0" if ($debug > 0);
      }

      if ($FORM{export_rp}) {
        push @l, $price;
      }
      else {
        push @l,
          (($conf{VOIP_UNIT_TARIFICATION}) ? $html->form_input(
            "p_$line->[4]" . '_' . "$interval_ids[$i]",
            "$unit_price", { SIZE => 10 }) . $html->br() . $price : $html->form_input(
            "p_$line->[4]" . '_' . "$interval_ids[$i]", "$price", { SIZE => 10 }))
            . (($i > 0) ? $html->form_input("t_$line->[4]" . '_' . "$interval_ids[$i]", "$trunk",
            { TYPE => 'hidden' }) : '');
      }
    }

    my $interval_id = $FORM{routes} || $interval_ids[$i];
    if ($FORM{export_rp}) {
      push @export_arr, [ $line->[0], $line->[1], $status[ $line->[2] ], $line->[3], @l ];
    }
    else {
      my $trunk_sel = $html->form_select('t_' . $line->[4] . '_' . $interval_id, {
        SELECTED    => $trunks{$interval_id}{$line->[4]} || 0,
        SEL_LIST    => $TRUNKS_MARR,
        NO_ID       => 1,
        SEL_OPTIONS => { 0 => '-' },
      });

      my $ext_tp_sel = $html->form_select('et_' . $line->[4] . '_' . $interval_id, {
        SELECTED    => $et{$interval_id}{$line->[4]} || 0,
        SEL_LIST    => $extra_tarification_list,
        NO_ID       => 1,
        SEL_OPTIONS => { 0 => '-' },
      });

      $table->addrow($line->[0], $line->[1], $status[ $line->[2] ], $ext_tp_sel, $trunk_sel, @l);
    }
  }

  if ($FORM{export_rp}) {
    foreach my $rows (@export_arr) {
      foreach my $row (@{$rows}) {
        print "$row\t";
      }
      print "\n";
    }

    return 0;
  }

  my $table2 = $html->table({
    width => '100%',
    rows  => [ [ $html->form_input('change', $lang{CHANGE}, { TYPE => 'submit' }),
      "$lang{FILE}: " . $html->form_input('ROUTE_FILE', "ROUTE_FILE", { TYPE => 'FILE' })
        . $html->form_input('import', $lang{IMPORT}, { TYPE => 'submit' }) ] ]
  });

  print $html->form_main({
    CONTENT => $table->show() . $table2->show(),
    ENCTYPE => 'multipart/form-data',
    NAME    => 'TP_ROUTES',
    ID      => 'TP_ROUTES',
    HIDDEN  => {
      TP_ID  => $FORM{TP_ID},
      index  => $index,
      routes => $FORM{routes},
      subf   => $FORM{subf}
    }
  });

  $table = $html->table({
    width => '100%',
    rows  => [ [ "$lang{TOTAL}:", $html->b($Voip->{TOTAL}) ] ]
  });
  print $table->show();

  return 1;
}

#**********************************************************
=head2 voip_exchange_rate()

=cut
#**********************************************************
sub voip_exchange_rate {

  my %info = (
    ACTION     => 'add',
    LNG_ACTION => $lang{ADD}
  );

  our Conf $Conf;

  if ($FORM{add}) {
    $FORM{VOIP_ER_CHANGED} = "$DATE $TIME";
    while (my ($k, $v) = each %FORM) {
      next if ($k !~ /^VOIP_/);
      $Conf->config_add({
        PARAM => $k,
        VALUE => $v || q{}
      });
    }

    if (!$Conf->{errno}) {
      $html->message('info', $lang{INFO}, "$lang{CHANGED}");
      $admin->{MODULE} = 'Voip';
      $admin->system_action_add($FORM{VOIP_ER}, { TYPE => 41 });
      $Voip->rp_change_exhange_rate({ EXCHANGE_RATE => $FORM{VOIP_ER} });
    }
  }
  elsif ($FORM{change}) {
    $FORM{VOIP_ER_CHANGED} = "$DATE $TIME";
    while (my ($k, $v) = each %FORM) {
      next if ($k !~ /^VOIP_/);
      $Conf->config_change($k, {
        PARAM => $k,
        VALUE => $v || q{}
      });
    }

    if (!$Conf->{errno}) {
      $html->message('info', $lang{INFO}, $lang{CHANGED});
      $admin->{MODULE} = 'Voip';
      $admin->system_action_add($FORM{VOIP_ER}, { TYPE => 41 });
      $Voip->rp_change_exhange_rate({ EXCHANGE_RATE => $FORM{VOIP_ER} });
    }
  }
  _error_show($Voip);

  my $list = $Conf->config_list({ PARAM => 'VOIP_*', SORT => 2 });

  foreach my $line (@{$list}) {
    $info{ $line->[0] } = $line->[1];
  }

  if ($info{VOIP_ER}) {
    $info{ACTION} = 'change';
    $info{LNG_ACTION} = $lang{CHANGE};
  }

  $html->tpl_show(_include('voip_er', 'Voip'), \%info);

  return 1;
}

#**********************************************************
=head2 form_intervals($attr) - Time intervals

  Arguments:
    $attr
      TP

=cut
#**********************************************************
sub voip_intervals {
  my ($attr) = @_;

  my @DAY_NAMES = ($lang{ALL}, 'Sun', 'Mon', 'Tue', 'Wen', 'The', 'Fri', 'Sat', $lang{HOLIDAYS});
  my %visual_view = ();
  my Tariffs $tarif_plan;

  if ($attr->{TP}) {
    $tarif_plan = $attr->{TP};
    $tarif_plan->{ACTION} = 'add';
    $tarif_plan->{LNG_ACTION} = $lang{ADD};

    if ($FORM{routes}) {
      voip_tp_routes({ TP => $attr->{TP} });
    }
    elsif ($FORM{add}) {
      $tarif_plan->ti_add({ %FORM });
      if (!$tarif_plan->{errno}) {
        $html->message('info', $lang{INFO}, "$lang{INTERVALS} $lang{ADDED}");
      }
    }
    elsif ($FORM{change}) {
      $tarif_plan->ti_change($FORM{TI_ID}, { %FORM });

      if (!$tarif_plan->{errno}) {
        $html->message('info', $lang{INFO}, "$lang{INTERVALS} $lang{CHANGED} [$tarif_plan->{TI_ID}]");
      }
    }
    elsif (defined($FORM{chg})) {
      $tarif_plan->ti_info($FORM{chg});
      if (!$tarif_plan->{errno}) {
        $html->message('info', $lang{INFO}, "$lang{INTERVALS} $lang{CHANGE} [$FORM{chg}]");
      }

      $tarif_plan->{ACTION} = 'change';
      $tarif_plan->{LNG_ACTION} = $lang{CHANGE};
    }
    elsif ($FORM{del} && $FORM{COMMENTS}) {
      $tarif_plan->ti_del($FORM{del});
      if (!$tarif_plan->{errno}) {
        $html->message('info', $lang{DELETED}, "$lang{DELETED} $FORM{del}");
      }
    }
    else {
      $tarif_plan->ti_defaults();
    }

    my $list = $tarif_plan->ti_list({ %LIST_PARAMS });
    my $table = $html->table({
      width   => '100%',
      caption => $lang{INTERVALS},
      title   => [ '#', $lang{DAYS}, $lang{BEGIN}, $lang{END}, $lang{HOUR_TARIF}, '-', '-', '-', '-' ],
      qs      => $pages_qs,
      ID      => 'VOIP_INTERVALS',
    });

    my $color = "AAA000";
    foreach my $line (@{$list}) {
      my $delete = $html->button($lang{DEL}, "index=$index$pages_qs&del=$line->[0]",
        { MESSAGE => "$lang{DEL} [$line->[0]] ?", class => 'del' });
      $color = sprintf("%06x", hex('0x' . $color) + 7000);

      #day, $hour|$end = color
      my ($h_b) = split(/:/, $line->[2], 3);
      my ($h_e) = split(/:/, $line->[3], 3);

      push(@{$visual_view{ $line->[1] }}, "$h_b|$h_e|$color|$line->[0]");

      if (($FORM{tt} && $FORM{tt} eq $line->[0]) || ($FORM{chg} && $FORM{chg} eq $line->[0])) {
        $table->{rowcolor} = 'table-success';
      }
      else {
        delete $table->{rowcolor};
      }

      $table->addtd(
        $table->td($line->[0], { rowspan => ($line->[5] > 0) ? 2 : 1 }),
        $table->td($html->b($DAY_NAMES[ $line->[1] ])),
        $table->td($line->[2]),
        $table->td($line->[3]),
        $table->td($line->[4]),
        $table->td($html->button($lang{ROUTES}, "index=$index$pages_qs&routes=$line->[0]", { class => 'routes' })),
        $table->td($html->button($lang{CHANGE}, "index=$index$pages_qs&chg=$line->[0]", { class => 'change' })),
        $table->td($delete), $table->td("&nbsp;", { bgcolor => '#' . $color, rowspan => ($line->[5] > 0) ? 2 : 1 })
      );
    }
    print $table->show();
  }
  elsif ($FORM{TP_ID}) {
    $FORM{subf} = $index;
    voip_tp({ TP_ID => $FORM{TP_ID} });
    return 0;
  }

  _error_show($tarif_plan);

  my $table = $html->table({
    width       => '100%',
    title_plain =>
      [ $lang{DAYS}, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23 ],
    caption     => $lang{INTERVALS},
    rowcolor    => 'bg-info'
  });

  for (my $i = 0; $i < 9; $i++) {
    my @hours = ();

    my ($h_b, $h_e, $color, $p);
    my $link = "&nbsp;";
    for (my $h = 0; $h < 24; $h++) {
      my $tdcolor;
      if (defined($visual_view{$i})) {
        my $day_periods = $visual_view{$i};

        foreach my $line (@{$day_periods}) {
          ($h_b, $h_e, $color, $p) = split(/\|/, $line, 4);
          if (($h >= $h_b) && ($h < $h_e)) {
            $tdcolor = '#' . $color;
            $link = $html->button('#', "index=$index&TP_ID=$FORM{TP_ID}&subf=$FORM{subf}&chg=$p");
            last;
          }
          else {
            $link = "&nbsp;";
            $tdcolor = $_COLORS[1];
          }
        }
      }
      else {
        $link = "&nbsp;";
        $tdcolor = $_COLORS[1];
      }

      push(@hours, $table->td($link, { align => 'center', bgcolor => $tdcolor }));
    }

    $table->addtd($table->td($DAY_NAMES[$i]), @hours);
  }

  print $table->show();

  $tarif_plan->{SEL_DAYS} = $html->form_select('TI_DAY', {
    SELECTED     => $FORM{TI_DAY},
    SEL_ARRAY    => \@DAY_NAMES,
    ARRAY_NUM_ID => 1
  });

  $index = get_function_index('voip_intervals');
  $html->tpl_show(templates('form_ti'), $tarif_plan);

  return 1;
}

#***********************************************************
=head2 voip_extra_tarification()

=cut
#***********************************************************
sub voip_extra_tarification {
  $Voip->{ACTION} = 'add';
  $Voip->{LNG_ACTION} = $lang{ADD};

  if ($FORM{add} && $FORM{NAME}) {
    $Voip->extra_tarification_add({ %FORM });
    if (!$Voip->{errno}) {
      $html->message('info', $lang{INFO}, "$lang{ADDED}");
    }
  }
  elsif ($FORM{change}) {
    $Voip->extra_tarification_change({ %FORM });
    if (!$Voip->{errno}) {
      $html->message('info', $lang{INFO}, "$lang{CHANGED}");
    }
  }
  elsif ($FORM{chg}) {
    $Voip->extra_tarification_info({ %FORM, ID => $FORM{chg} });
    if (!$Voip->{errno}) {
      $html->message('info', $lang{INFO}, "$lang{CHANGING}");
    }
    $Voip->{ACTION} = 'change';
    $Voip->{LNG_ACTION} = $lang{CHANGE};
  }
  elsif ($FORM{del} && $FORM{COMMENTS}) {
    $Voip->extra_tarification_del({ ID => $FORM{del} });
    if (!$Voip->{errno}) {
      $html->message('info', $lang{INFO}, "$lang{DELETED}");
    }
  }

  _error_show($Voip);

  $html->tpl_show(_include('voip_extra_tarification', 'Voip'), $Voip);

  result_former({
    INPUT_DATA      => $Voip,
    FUNCTION        => 'extra_tarification_list',
    BASE_FIELDS     => 2,
    FUNCTION_FIELDS => 'change,del',
    SKIP_USER_TITLE => 1,
    EXT_TITLES      => {
      id           => 'ID',
      name         => $lang{NAME},
      prepaid_time => "$lang{PREPAID} $lang{TIME}"
    },
    TABLE           => {
      width   => '100%',
      caption => "$lang{PREPAID} $lang{TIME}",
      qs      => $pages_qs,
      ID      => 'EXTRA_TARIFICATION',
      EXPORT  => 1,
      MENU    => "$lang{ADD}:index=$index&add_form=1&$pages_qs:add",
    },
    MAKE_ROWS       => 1,
    SEARCH_FORMER   => 1,
    TOTAL           => 1
  });

  return 1;
}

1;
