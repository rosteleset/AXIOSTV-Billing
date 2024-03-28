use strict;
use warnings FATAL => 'all';

=head1 NAME

  Crm::Reports - crm reports

=cut

our (
  $Crm,
  $html,
  %lang,
  %conf,
  $admin,
  $db,
  %permissions,
  %LIST_PARAMS
);

require Control::Address_mng;
use Address;
my $Address = Address->new($db, $admin, \%conf);

#**********************************************************
=head2 crm_start_page($attr)

  Arguments:


  Returns:

=cut
#**********************************************************
sub crm_start_page {

  my %START_PAGE_F = (
    crm_today_actions         => "$lang{ACTION} CRM",
    crm_sales_funnel_widget   => $lang{SALES_FUNNEL},
    crm_top_admins            => $lang{CRM_TOP_ADMINS},
    crm_watch_leads_report    => $lang{TRACKED_LEADS},
    crm_deferred_leads_report => $lang{DEFERRED_LEADS}
  );

  return \%START_PAGE_F;
}

#**********************************************************
=head2 crm_sales_funnel_widget()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub crm_sales_funnel_widget {
  return crm_sales_funnel({ RETURN_TABLE => 1 });
}

#**********************************************************
=head2 crm_sales_funnel($attr) - Shows sales funnel for leads

=cut
#**********************************************************
sub crm_sales_funnel {
  my ($attr) = @_;

  require Control::Reports;
  reports({
    DATE_RANGE       => 1,
    DATE             => $FORM{DATE},
    REPORT           => '',
    EX_PARAMS        => {},
    PERIOD_FORM      => 1,
    PERIODS          => 1,
    NO_TAGS          => 1,
    NO_GROUP         => 1,
    NO_ACTIVE_ADMINS => 1
  }) if (!$attr->{RETURN_TABLE});

  my ($y, $m, $d) = split('-', $DATE);
  my $from_date = "$y-$m-01";
  my $to_date = "$y-$m-" . days_in_month({ DATE => $DATE });
  my @leads_array = ();
  if ($FORM{FROM_DATE} && $FORM{TO_DATE}) {
    $from_date = $FORM{FROM_DATE};
    $to_date = $FORM{TO_DATE};
  }
  my $period = "$from_date/$to_date";
  my $list = $Crm->crm_progressbar_step_list({
    STEP_NUMBER => '_SHOW',
    NAME        => '_SHOW',
    DEAL_STEP   => '0',
    SORT        => 1,
    COLS_NAME   => 1
  });

  my $table = $html->table({
    width   => '100%',
    caption => (!$attr->{RETURN_TABLE}) ? $lang{SALES_FUNNEL} :
      $html->button($lang{SALES_FUNNEL}, 'index=' . get_function_index('crm_sales_funnel')),
    title   => [ $lang{STEP}, $lang{NAME}, $lang{NUMBER_LEADS}, $lang{LEADS_PERCENTAGE},
      $lang{NUMBER_LEADS_ON_STEP}, $lang{LEADS_PERCENTAGE_ON_STEP} ],
    ID      => 'SALES_FUNNEL_ID'
  });

  $Crm->crm_lead_list({
    PERIOD       => "$from_date/$to_date",
    CURRENT_STEP => ">=1",
  });
  my $full_count = $Crm->{TOTAL};

  foreach my $item (@$list) {
    $Crm->crm_lead_list({
      PERIOD       => "$from_date/$to_date",
      CURRENT_STEP => ">=$item->{step_number}"
    });
    my $count_for_step = $Crm->{TOTAL};
    $Crm->crm_lead_list({
      PERIOD       => "$from_date/$to_date",
      CURRENT_STEP => $item->{step_number}
    });
    my $step_count = $Crm->{TOTAL};
    my $item_name = _translate($item->{name});

    my $count_step = sprintf('%.2f', ($count_for_step / (($full_count || 1) / 100)));
    my $complete_count_step = sprintf('%.2f', ($step_count / (($full_count || 1) / 100)));

    $table->addrow(
      $item->{step_number},
      $item_name,
      $html->button($count_for_step,
        "index=" . get_function_index('crm_leads') . "&PERIOD=$period&CURRENT_STEP=>=$item->{step_number}&search=1"),
      $html->progress_bar({
        TEXT         => $attr->{RETURN_TABLE} ? $html->color_mark(($count_step ? $count_step : 0),
          (($count_step ? $count_step : 0) > 50 ? '#fff' : '#000')) : '',
        TOTAL        => $full_count,
        COMPLETE     => $count_for_step,
        COLOR        => ' bg-primary',
        PERCENT_TYPE => $attr->{RETURN_TABLE} ? 0 : 1,
      }),
      $html->button($step_count,
        "index=" . get_function_index('crm_leads') . "&PERIOD=$period&CURRENT_STEP=$item->{step_number}&search=1"),
      $html->progress_bar({
        TEXT         => $attr->{RETURN_TABLE} ? $html->color_mark(($complete_count_step ? $complete_count_step : 0),
          (($complete_count_step ? $complete_count_step : 0) > 50 ? '#fff' : '#000')) : '',
        TOTAL        => $full_count,
        COMPLETE     => $step_count,
        COLOR        => ' bg-warning',
        PERCENT_TYPE => $attr->{RETURN_TABLE} ? 0 : 1
      })
    );

    next if $attr->{RETURN_TABLE};
    push @leads_array, {
      value => $count_for_step + 0,
      title => $item_name,
    };
  }

  return $table->show() if ($attr->{RETURN_TABLE});

  print $table->show();
  my $data = AXbills::Base::json_former(\@leads_array);
  $html->tpl_show(_include('sales_funnel_chart', 'Crm'), { DATA => $data });

  return 1;
}


#**********************************************************
=head2 crm_today_actions()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub crm_today_actions {

  my $today_actions = $Crm->progressbar_comment_list({
    AID          => $admin->{AID},
    PLANNED_DATE => $DATE,
    ACTION_ID    => '>0',
    STATUS       => '0',
    LEAD_ID      => '_SHOW',
    ACTION       => '_SHOW',
    LEAD_FIO     => '_SHOW',
    COLS_NAME    => 1,
    PAGE_ROWS    => 999999
  });

  my $actions_table = $html->table({
    width   => '100%',
    caption => "$lang{ACTION} CRM",
    title   => [ $lang{FIO}, $lang{ACTION}, $lang{DATE}, '' ],
    ID      => 'CRM_TODAY_ACTION',
  });

  my $leads_function_index = get_function_index('crm_lead_info');
  foreach my $action (@$today_actions) {
    my $lead_button = $html->button($lang{SHOW}, "index=$leads_function_index&LEAD_ID=$action->{lead_id}");
    $actions_table->addrow($action->{lead_fio}, $action->{action}, $action->{planned_date}, $lead_button);
  }

  return $actions_table->show();
}

#**********************************************************
=head2 crm_watch_leads_report()

=cut
#**********************************************************
sub crm_watch_leads_report {

  my $leads = $Crm->crm_lead_list({
    WATCHER           => $admin->{AID},
    LEAD_ID           => '_SHOW',
    FIO               => '_SHOW',
    CURRENT_STEP_NAME => '_SHOW',
    STEP_COLOR        => '_SHOW',
    ADMIN_NAME        => '_SHOW',
    COLS_NAME         => 1,
    PAGE_ROWS         => 999999
  });

  my $actions_table = $html->table({
    width   => '100%',
    caption => $lang{TRACKED_LEADS},
    title   => [ '#', $lang{FIO}, $lang{STEP}, $lang{RESPONSIBLE} ],
    ID      => 'CRM_TRACKED_LEADS',
  });

  foreach my $lead (@{$leads}) {
    my $fio = $html->button($lead->{fio}, "get_index=crm_lead_info&full=1&LEAD_ID=$lead->{lead_id}");
    my $step = $html->element('span', _translate($lead->{current_step_name}), {
      class => 'text-white badge',
      style => "background-color:" . ($lead->{step_color} || '')
    });
    $actions_table->addrow($lead->{lead_id}, $fio, $step, $lead->{admin_name});
  }

  return $actions_table->show();
}

#**********************************************************
=head2 crm_deferred_leads_report()

=cut
#**********************************************************
sub crm_deferred_leads_report {

  my $leads = $Crm->crm_action_list({
    WATCHER           => $admin->{AID},
    LAST_ACTION       => "< '$DATE'",
    LEAD_FIO          => '!',
    LID               => '_SHOW',
    CURRENT_STEP_NAME => '_SHOW',
    STEP_COLOR        => '_SHOW',
    ADMIN_NAME        => '_SHOW',
    SORT              => 'last_action',
    DESC              => 'DESC',
    GROUP_BY          => 'ca.lid',
    COLS_NAME         => 1,
    PAGE_ROWS         => 25
  });

  my $actions_table = $html->table({
    width   => '100%',
    caption => $lang{DEFERRED_LEADS},
    title   => [ '#', $lang{FIO}, $lang{STEP}, $lang{RESPONSIBLE}, "$lang{LAST} $lang{ACTION}" ],
    ID      => 'CRM_TRACKED_LEADS',
  });

  foreach my $lead (@{$leads}) {
    my $fio = $html->button($lead->{lead_fio}, "get_index=crm_lead_info&full=1&LEAD_ID=$lead->{lid}");
    my $step = $html->element('span', _translate($lead->{current_step_name}), {
      class => 'text-white badge',
      style => "background-color:" . ($lead->{step_color} || '')
    });
    $actions_table->addrow($lead->{lid}, $fio, $step, $lead->{admin_name}, $lead->{last_action});
  }

  return $actions_table->show();
}

#**********************************************************
=head2 crm_competitors_tp_report($attr)

=cut
#**********************************************************
sub crm_competitors_tp_report {

  _crm_report_form();

  my $min_tps = $Crm->crm_competitors_tps_list({
    NAME            => '_SHOW',
    SPEED           => '_SHOW',
    MONTH_FEE       => '_SHOW',
    DAY_FEE         => '_SHOW',
    COMPETITOR_NAME => '_SHOW',
    COLS_NAME       => 1,
    PAGE_ROWS       => 5,
    SORT            => 'cct.month_fee',
    %FORM
  });

  my $max_tps = $Crm->crm_competitors_tps_list({
    NAME            => '_SHOW',
    SPEED           => '_SHOW',
    MONTH_FEE       => '_SHOW',
    DAY_FEE         => '_SHOW',
    COMPETITOR_NAME => '_SHOW',
    COLS_NAME       => 1,
    PAGE_ROWS       => 5,
    SORT            => 'cct.month_fee',
    DESC            => 'desc',
    %FORM
  });

  $html->tpl_show(_include('crm_competitors_tps_report', 'Crm'), {
    MIN_PRICE_CHART => _crm_make_tps_chart($min_tps),
    MAX_PRICE_CHART => _crm_make_tps_chart($max_tps)
  });

  _crm_popular_tariff_plans();
}

#**********************************************************
=head2 crm_competitors_users_report()

=cut
#**********************************************************
sub crm_competitors_users_report {

  _crm_report_form();

  my %sort_array = (
    '2' => 'users',
    '3' => 'avg_assessment',
    '4' => 'total_assessment'
  );

  $FORM{sort} = $sort_array{$FORM{sort}} if $FORM{sort} && $sort_array{$FORM{sort}};

  my $competitors = $Crm->crm_competitors_users_list({
    COMPETITOR_NAME  => '_SHOW',
    COMPETITOR_ID    => '_SHOW',
    USERS            => '_SHOW',
    TOTAL_ASSESSMENT => '_SHOW',
    AVG_ASSESSMENT   => '_SHOW',
    COLS_NAME        => 1,
    %FORM
  });

  my $competitors_users = $html->table({
    width   => '100%',
    caption => "$lang{COMPETITORS}: $lang{LEADS}",
    title   => [ $lang{COMPETITOR}, "$lang{LEADS} ($lang{COUNT})", $lang{AVERAGE_RATING}, $lang{CRM_NUMBER_OF_RATINGS} ],
    ID      => 'CRM_COMPETITORS_USERS'
  });

  foreach my $competitor (@{$competitors}) {
    my $competitor_btn = $html->button($competitor->{competitor_name},
      "get_index=crm_competitors&header=1&full=1&chg=$competitor->{competitor_id}");

    $competitors_users->addrow($competitor_btn, _crm_get_competitor_users_button($index, $competitor->{users}, $competitor->{competitor_id}) || $competitor->{users},
      crm_assessment_stars($competitor->{avg_assessment} || 0), $competitor->{total_assessment});
  }

  print $competitors_users->show();

  _crm_competitor_users_list();
}

#**********************************************************
=head2 crm_competitors_report($attr)

=cut
#**********************************************************
sub crm_competitors_report {

  _crm_report_form({ HIDE_COMPETITOR_SELECT => 1 });

  my $competitors = $Crm->crm_competitor_list({
    NAME            => '_SHOW',
    DESCR           => '_SHOW',
    SITE            => '_SHOW',
    CONNECTION_TYPE => '_SHOW',
    COLS_NAME       => 1,
    %FORM
  });


  my $competitors_table = $html->table({
    width   => '100%',
    caption => $lang{COMPETITORS},
    title   => [ 'Id', $lang{NAME}, $lang{COMPETITOR_SITE}, $lang{CONNECTION_TYPE}, $lang{DESCRIBE} ],
    ID      => 'CRM_COMPETITORS',
    EXPORT  => 1
  });

  my $competitors_index = get_function_index('crm_competitors');
  foreach (@{$competitors}) {
    my $site = $_->{site} ? $html->button('', '', {
      GLOBAL_URL => $_->{site},
      target     => '_blank',
      class      => 'btn btn-sm btn-primary',
      ICON       => 'fa fa-globe',
    }) : '';

    my $competitor_button = $html->button($_->{name}, "index=$competitors_index&chg=$_->{id}", { target => '_blank' });

    $competitors_table->addrow($_->{id}, $competitor_button, $site, $_->{connection_type}, $_->{descr});
  }

  print $competitors_table->show();
}

#**********************************************************
=head2 crm_top_admins()

=cut
#**********************************************************
sub crm_top_admins {

  my $top_admins = $Crm->crm_lead_list({
    LEADS_NUMBER => '_SHOW',
    ADMIN_NAME   => '_SHOW',
    RESPONSIBLE  => '_SHOW',
    GROUP_BY     => 'cl.responsible',
    SORT         => 'leads_number',
    DESC         => 'DESC',
    COLS_NAME    => 1,
    PAGE_ROWS    => 999999
  });

  my $admins_table = $html->table({
    width   => '100%',
    caption => $lang{CRM_TOP_ADMINS},
    title   => [ '#', $lang{ADMIN}, "$lang{LEADS} ($lang{COUNT})" ],
    ID      => 'CRM_TOP_ADMINS'
  });

  foreach my $responsible (@{$top_admins}) {
    $admins_table->addrow($responsible->{responsible} || '',
      $responsible->{responsible} ? ($responsible->{admin_name} || '') : $lang{CRM_WITHOUT_RESPONSIBLE}, $responsible->{leads_number});
  }

  return $admins_table->show();
}

#**********************************************************
=head2 _crm_popularity_tariff_plans($attr)

=cut
#**********************************************************
sub _crm_popular_tariff_plans {

  my $tps = $Crm->crm_competitors_popular_tps_list({
    NAME            => '_SHOW',
    COMPETITOR_NAME => '_SHOW',
    COMPETITOR_ID   => '!',
    MONTH_FEE       => '_SHOW',
    DAY_FEE         => '_SHOW',
    SORT            => 'leads_number',
    DESC            => 'desc',
    COLS_NAME       => 1,
    PAGE_ROWS       => 25,
    %FORM
  });

  my $popular_tps = $html->table({
    width   => '100%',
    caption => $lang{CRM_POPULAR_TARIFF_PLANS},
    title   => [ $lang{NAME}, $lang{COMPETITOR}, "$lang{LEADS} ($lang{COUNT})", $lang{MONTH_FEE}, $lang{DAY_FEE} ],
    ID      => 'CRM_POPULAR_TPS'
  });

  foreach my $tp (@{$tps}) {
    my $competitor_btn = $html->button($tp->{competitor_name}, "get_index=crm_competitors&header=1&full=1&chg=$tp->{competitor_id}");
    my $tp_btn = $html->button($tp->{name}, "get_index=crm_competitors_tp&header=1&full=1&chg=$tp->{id}");
    $popular_tps->addrow($tp_btn, $competitor_btn, $tp->{leads_number}, $tp->{month_fee}, $tp->{day_fee});
  }

  print $popular_tps->show();
}

#**********************************************************
=head2 _crm_get_competitor_users_button($attr)

=cut
#**********************************************************
sub _crm_get_competitor_users_button {
  my $index = shift;
  my $users = shift;
  my $competitor = shift;

  return 0 if !$index || !$users || !$competitor;

  my @params = qw/BUILD_ID STREET_ID DISTRICT_ID COMPETITOR_ID/;

  my $url = "index=$index&COMPETITOR_USERS=$competitor";
  map $FORM{$_} ? $url .= "&$_=$FORM{$_}" : (), @params;

  return $html->button($users, $url);
}

#**********************************************************
=head2 _crm_competitor_users_list($attr)

=cut
#**********************************************************
sub _crm_competitor_users_list {

  return 0 if !$FORM{COMPETITOR_USERS};

  my $leads = $Crm->crm_competitors_users_list({
    COMPETITOR_NAME => '_SHOW',
    COMPETITOR_ID   => $FORM{COMPETITOR_USERS},
    LEAD_ID         => '_SHOW',
    FIO             => '_SHOW',
    PHONE           => '_SHOW',
    ASSESSMENT      => '_SHOW',
    COLS_NAME       => 1,
    GROUP_BY        => 'cl.id',
    'sort'          => 1,
    %FORM
  });

  return '' if $Crm->{TOTAL} < 1;

  my $competitor_leads = $html->table({
    width      => '100%',
    caption    => "$leads->[0]{competitor_name}: $lang{LEADS}",
    title      => [ 'Id', $lang{FIO}, $lang{PHONE}, $lang{ASSESSMENT} ],
    ID         => 'CRM_COMPETITOR_USERS',
    DATA_TABLE => 1
  });

  foreach my $lead (@{$leads}) {
    my $lead_id = $html->button($lead->{lead_id},
      "get_index=crm_lead_info&header=2&full=1&LEAD_ID=$lead->{lead_id}");

    $competitor_leads->addrow($lead_id, $lead->{fio}, $lead->{phone}, crm_assessment_stars($lead->{assessment} || 0));
  }

  print $competitor_leads->show();
}

#**********************************************************
=head2 _crm_make_chart($attr)

=cut
#**********************************************************
sub _crm_make_tps_chart {
  my $tps = shift;

  my @data = ();
  my @labels = ();

  foreach my $tp (@{$tps}) {
    push @data, $tp->{month_fee};
    push @labels, $tp->{name};
  }

  return $html->chart({
    TYPE              => 'bar',
    X_LABELS          => \@labels,
    DATA              => {
      $lang{PRICE} => \@data
    },
    BACKGROUND_COLORS => {
      $lang{PRICE} => '#337ab7'
    },
    FILL              => 'true',
    OUTPUT2RETURN     => 1,
  });
}

#**********************************************************
=head2 _crm_make_chart($attr)

=cut
#**********************************************************
sub _crm_report_form {
  my ($attr) = @_;

  my $builds_sel = $html->form_select('BUILD_ID', {
    SELECTED    => $FORM{BUILD_ID} || 0,
    NO_ID       => 1,
    SEL_LIST    => !$FORM{STREET_ID} ? [] : $Address->build_list({
      STREET_ID => $FORM{STREET_ID},
      NUMBER    => '_SHOW',
      COLS_NAME => 1,
      SORT      => 'b.number+0',
      PAGE_ROWS => 999999
    }),
    SEL_KEY     => 'id',
    SEL_VALUE   => 'number',
    SEL_OPTIONS => { '' => '--' },
  });

  my $EXT_SELECT = {
    DISTRICT => { LABEL => $lang{DISTRICT}, SELECT => sel_districts({
      SEL_OPTIONS          => { '' => '--' },
      DISTRICT_ID          => $FORM{DISTRICT_ID},
      SKIP_MULTIPLE_BUTTON => 1,
      FULL_NAME            => 1,
      ONLY_WITH_STREETS    => 1
    }) },
    STREET   => { LABEL => $lang{STREET}, SELECT => sel_streets({
      SEL_OPTIONS => { '' => '--' },
      STREET_ID   => $FORM{STREET_ID},
      DISTRICT_ID => $FORM{DISTRICT_ID}
    }) },
    _BUILD   => { LABEL => $lang{BUILD}, SELECT => $builds_sel }
  };

  $EXT_SELECT->{COMPETITOR} = {
    LABEL  => $lang{COMPETITOR},
    SELECT => _crm_competitors_select({ %FORM })
  } if !$attr->{HIDE_COMPETITOR_SELECT};

  require Control::Reports;
  reports({
    PERIOD_FORM => 1,
    NO_PERIOD   => 1,
    NO_GROUP    => 1,
    NO_TAGS     => 1,
    EXT_SELECT  => $EXT_SELECT
  });
  
### АСР KTK-39
#without require
#  reports({
#    PERIOD_FORM => 1,
#    NO_PERIOD   => 1,
#    NO_GROUP    => 1,
#    NO_TAGS     => 1,
#    EXT_SELECT  => $EXT_SELECT
#  });
###

  $html->tpl_show(_include('crm_report_address_script', 'Crm'));
}

1;