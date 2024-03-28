#package Paysys::Reports;
use strict;
use warnings FATAL => 'all';

use AXbills::Base qw(date_inc convert);

our (
  %lang,
  @status,
  @status_color,
  $admin,
  $db,
  @MONTHES,
  @WEEKDAYS,
  %permissions
);

our AXbills::HTML $html;
our Paysys $Paysys;

#**********************************************************
=head2 paysys_log() - Show paysys operations

=cut
#**********************************************************
sub paysys_log {
  if (form_purchase_module({
    HEADER          => $user->{UID},
    MODULE          => 'Paysys',
    REQUIRE_VERSION => 9.19
  })) {
    return 0;
  }

  my %PAY_SYSTEMS = ();

  my $connected_systems = $Paysys->paysys_connect_system_list({
    PAYSYS_ID => '_SHOW',
    NAME      => '_SHOW',
    MODULE    => '_SHOW',
    COLS_NAME => 1,
  });

  foreach my $payment_system (@$connected_systems) {
    $PAY_SYSTEMS{$payment_system->{paysys_id}} = $payment_system->{name};
  }

  if ($FORM{info}) {
    $Paysys->info({ ID => $FORM{info} });
    my @info_arr = split(/\n/, $Paysys->{INFO} || q{});
    my $table = $html->table({ width => '100%' });
    foreach my $line (@info_arr) {
      my ($k, $v) = split(/,/, $line, 2);
      my $value = convert($v, { text2html => 1 });
      $table->addrow($k, $value);
    }

    $Paysys->{INFO} = $table->show();
    $table = $html->table({
      width   => '500',
      caption => $lang{INFO},
      rows    => [
        [ "ID", $Paysys->{ID} ],
        [ "$lang{LOGIN}", $Paysys->{LOGIN} ],
        [ "$lang{DATE}", $Paysys->{DATETIME} ],
        [ "$lang{SUM}", $Paysys->{SUM} ],
        [ "$lang{COMMISSION}", $Paysys->{COMMISSION} ],
        [ "$lang{PAY_SYSTEM}", $PAY_SYSTEMS{ $Paysys->{SYSTEM_ID} } ],
        [ "$lang{TRANSACTION}", $Paysys->{TRANSACTION_ID} ],
        [ "$lang{USER} IP", $Paysys->{CLIENT_IP} ],
        [ "PAYSYS IP", $Paysys->{PAYSYS_IP} ],
        [ "$lang{INFO}", $Paysys->{INFO} ],
        [ "$lang{ADD_INFO}", $Paysys->{USER_INFO} ],
        [ "$lang{STATUS}", $status[ $Paysys->{STATUS} ] ],
      ],
      ID      => 'PAYSYS_INFO'
    });

    print $table->show();
  }
  elsif (defined($FORM{del}) && ($FORM{COMMENTS} || $FORM{is_js_confirmed})) {
    $Paysys->del($FORM{del});

    if (!$Paysys->{errno}) {
      $html->message('info', $lang{DELETED}, "$lang{DELETED} $FORM{del}");
    }
  }

  _error_show($Paysys);

  my %info = ();

  if ($FORM{search_form} && !$user->{UID}) {
    my %ACTIVE_SYSTEMS = %PAY_SYSTEMS;

    $info{PAY_SYSTEMS_SEL} = $html->form_select(
      'PAYMENT_SYSTEM',
      {
        SELECTED => $FORM{PAYMENT_SYSTEM} || '',
        SEL_HASH => { '' => $lang{ALL}, %ACTIVE_SYSTEMS },
        NO_ID    => 1
      }
    );

    $info{STATUS_SEL} = $html->form_select(
      'STATUS',
      {
        SELECTED     => $FORM{STATUS} || '',
        SEL_ARRAY    => \@status,
        ARRAY_NUM_ID => 1,
        SEL_OPTIONS  => { '' => $lang{ALL} }
      }
    );

    $info{DATERANGE_PICKER} = $html->form_daterangepicker({
      NAME  => 'FROM_DATE/TO_DATE',
      VALUE => $FORM{'FROM_DATE_TO_DATE'},
    });

    form_search({
      SEARCH_FORM  => $html->tpl_show(_include('paysys_search', 'Paysys'),
        { %info, %FORM },
        { OUTPUT2RETURN => 1 }),
      ADDRESS_FORM => 1
    });
  }

  if (!defined($FORM{sort})) {
    $LIST_PARAMS{SORT} = 1;
    $LIST_PARAMS{DESC} = 'DESC';
  }
  my AXbills::HTML $table;
  my $list;
  ($table, $list) = result_former({
    INPUT_DATA      => $Paysys,
    FUNCTION        => 'list',
    BASE_FIELDS     => 7,
    FUNCTION_FIELDS => 'status, del',
    EXT_TITLES      => {
      id             => 'ID',
      system_id      => $lang{PAY_SYSTEM},
      transaction_id => $lang{TRANSACTION},
      info           => $lang{INFO},
      sum            => $lang{SUM},
      ip             => "$lang{USER} IP",
      status         => $lang{STATUS},
      date           => $lang{DATE},
      month          => $lang{MONTH},
      datetime       => $lang{DATE},
    },
    SKIP_USER_TITLE => 1,
    TABLE           => {
      width   => '100%',
      caption => "Paysys",
      qs      => $pages_qs,
      pages   => $Paysys->{TOTAL},
      ID      => 'PAYSYS_LOG',
      EXPORT  => "$lang{EXPORT} XML:&xml=1",
      MENU    => "$lang{SEARCH}:index=$index&search_form=1:search;",
    },
  });

  foreach my $line (@$list) {
    $line->{transaction_id} = convert($line->{transaction_id}, { text2html => 1 });
    my @fields_array = ($line->{id},
      $html->button($line->{login}, "index=15&UID=$line->{uid}"),
      $line->{datetime},
      $line->{sum},
      (($PAY_SYSTEMS{$line->{system_id}}) ? $PAY_SYSTEMS{$line->{system_id}} : "Unknown: " . $line->{system_id}),
      $html->button("$line->{transaction_id}", "index=2&EXT_ID=$line->{transaction_id}&search=1"),
      "$line->{status}:" . $html->color_mark($status[$line->{status}], $status_color[$line->{status}]),
    );

    for (my $i = 7; $i < 7 + $Paysys->{SEARCH_FIELDS_COUNT}; $i++) {
      push @fields_array, $line->{$Paysys->{COL_NAMES_ARR}->[$i]};
    }

    $table->addrow(
      @fields_array,
      $html->button($lang{INFO}, "index=$index&info=$line->{id}", { class => 'show' })
        . ' ' . ($user->{UID} ? '-' : $html->button($lang{DEL}, "index=$index&del=$line->{id}",
        { MESSAGE => "$lang{DEL} $line->{id}?", class => 'del' }))
    );
  }

  print $table->show();

  $table = $html->table({
    width => '100%',
    rows  => [ [ "$lang{TOTAL}:", $html->b($Paysys->{TOTAL}), "$lang{SUM}", $html->b($Paysys->{SUM}) ],
      [ "$lang{TOTAL} $lang{COMPLETE}:", $html->b($Paysys->{TOTAL_COMPLETE}), "$lang{SUM} $lang{COMPLETE}:",
        $html->b($Paysys->{SUM_COMPLETE}) ]
    ]
  });

  print $table->show() if (!$admin->{MAX_ROWS});

  return 1;
}

#**********************************************************
=head2 paysys_reports()

=cut
#**********************************************************
sub paysys_reports {

  my $select = _paysys_select_connected_systems();
  my $selection_group = $html->element('div', $select, { class => 'input-group' });

  if ($permissions{4}) {
    my %debug_list = (
      1 => 1,
      2 => 2,
      3 => 3,
      4 => 4,
      5 => 5,
      6 => 6,
      7 => 7,
      8 => 8,
      9 => 9);

    my $debug_select = $html->form_select(
      'DEBUG',
      {
        SELECTED => '',
        SEL_HASH => { %debug_list, '' => $lang{DEBUG} },
        NO_ID    => 1,
      }
    );
    # $selection_group .= $html->element('div', $html->form_input('DEBUG', $FORM{DEBUG}, { EX_PARAMS => "placeholder=$lang{DEBUG}" }),
    #   { class => 'input-group' });
    $selection_group .= $debug_select;
  }

  my $date_form = $html->form_daterangepicker({
    NAME => 'DATE_FROM/DATE_TO',
    DATE => $DATE
  });
  $date_form = $html->element('div', $date_form, { class => 'input-group float-left' });

  # TODO: #3944 needs rereview
  my $systems = $html->form_main({
    CONTENT => $date_form . $selection_group,
    HIDDEN  => { index => $index },
    SUBMIT  => { show => $lang{SHOW} },
    class   => 'form-inline ml-auto flex-nowrap',
  });

  func_menu({ $lang{NAME} => $systems });

  if ($FORM{SYSTEM_ID}) {
    my $system_info = $Paysys->paysys_connect_system_info({
      ID               => $FORM{SYSTEM_ID},
      SHOW_ALL_COLUMNS => 1,
      COLS_NAME        => 1
    });

    my $Paysys_plugin = _configure_load_payment_module($system_info->{module});
    my $Pay_plugin = $Paysys_plugin->new($db, $admin, \%conf, {
      CUSTOM_NAME => $system_info->{name},
      NAME        => $system_info->{name},
      CUSTOM_ID   => $system_info->{paysys_id},
      DATE        => $DATE
    });

    if ($Pay_plugin->can('report')) {
      my $reg_payments = get_reg_payments({
        DATE_FROM => $FORM{DATE_FROM},
        DATE_TO   => $FORM{DATE_TO},
        EXT_ID    => $Pay_plugin->{SHORT_NAME}
      });

      $Pay_plugin->report({
        DEBUG        => $FORM{DEBUG},
        FORM         => \%FORM,
        LANG         => \%lang,
        HTML         => $html,
        INDEX        => $index,
        #OP_SID      => '',
        MONTHES      => \@MONTHES,
        WEEKDAYS     => \@WEEKDAYS,
        DATE         => $DATE,
        DATE_FROM    => $FORM{DATE_FROM},
        DATE_TO      => $FORM{DATE_TO},
        REG_PAYMENTS => $reg_payments
      });
    }
    else {
      $html->message("warn", "No sub report", "This module doesnt have report sub");
    }
  }

  return 1;
}

#**********************************************************
=head2 _paysys_get_exchange_rates() - get user exchange rates

  Returns:
    @exchange_rates

=cut
#**********************************************************
sub _paysys_get_exchange_rates {
  if (defined($conf{PAYSYS_EXCHANGE_RATES})) {
    return split(/,\s?/, $conf{PAYSYS_EXCHANGE_RATES});
  }
  else {
    return ('USD', 'EUR', 'UAH', 'GBP', 'KZT');
  };
}

#**********************************************************
=head2 paysys_uah_exchange_rates($attr) - get exchange rates from nbu

  Arguments:


  Returns:
    $table

=cut
#**********************************************************
sub paysys_uah_exchange_rates {
  my $uah_data = web_request(
    "https://bank.gov.ua/NBU_Exchange/exchange?json",
    {
      CURL        => 1,
      JSON_RETURN => 1,
    }
  );

  my $uah_table = $html->table({
    width   => '100%',
    caption => "$lang{EXCHANGE_RATE} $lang{NBU}",
    title   => [ $lang{CURRENCY}, $lang{CURRENCY_BUY}, $lang{UNITS} ],
    ID      => 'UAH_CURRENCY',
  });

  my @val = _paysys_get_exchange_rates();

  if (ref $uah_data eq 'ARRAY') {
    foreach my $uinfo (@{$uah_data}) {
      foreach my $keys (@val) {
        if ($uinfo->{CurrencyCodeL} eq $keys) {
          $uah_table->addrow(
            $html->b("$uinfo->{CurrencyCodeL} / UAH"),
            sprintf('%.4f', $uinfo->{Amount}),
            sprintf('%.d', $uinfo->{Units})
          );
        }
      }
    }
  }

  return $uah_table->show();
}

#**********************************************************
=head2 paysys_rub_exchange_rates() - get exchange rates from nbr

  Arguments:


  Returns:
    $table

=cut
#**********************************************************
sub paysys_rub_exchange_rates {
  my $rub_data = web_request(
    "https://www.cbr-xml-daily.ru/daily_json.js",
    {
      CURL        => 1,
      JSON_RETURN => 1,
    }
  );

  my $rub_table = $html->table({
    width   => '100%',
    caption => "$lang{EXCHANGE_RATE} $lang{CBR}",
    title   => [ $lang{CURRENCY}, $lang{CURRENCY_BUY}, $lang{UNITS} ],
    ID      => 'RUB_CURRENCY',
  });

  my @val = _paysys_get_exchange_rates();

  if (ref $rub_data eq 'HASH') {
    foreach my $rinfo ($rub_data->{Valute}) {
      foreach my $keys (@val) {
        if (defined($rinfo->{$keys})) {
          $rub_table->addrow(
            $html->b("$rinfo->{$keys}{CharCode} / RUB"),
            sprintf('%.4f', $rinfo->{$keys}{Value}),
            sprintf('%.d', $rinfo->{$keys}{Nominal})
          );
        }
      }
    }
  }

  return $rub_table->show();
}

#**********************************************************
=head2 paysys_kgs_exchange_rates() - get exchange rates from nbkr

  Arguments:


  Returns:
    $table

=cut
#**********************************************************
sub paysys_kgs_exchange_rates {

  my $kgs_xml_data = web_request(
    "http://www.nbkr.kg/XML/daily.xml",
    {
      CURL        => 1,
    }
  );

  load_pmodule('XML::Simple');

  my $kgs_data = XML::Simple::XMLin("$kgs_xml_data", forcearray => 1);

  if ($@) {
    return 0;
  }

  my $kgs_table = $html->table({
    width   => '100%',
    caption => "$lang{EXCHANGE_RATE} $lang{NBKR}",
    title   => [ $lang{CURRENCY}, $lang{CURRENCY_BUY}, $lang{UNITS} ],
    ID      => 'NBKR_CURRENCY',
  });

  my @val = _paysys_get_exchange_rates();

  foreach my $currency (sort @ {$kgs_data->{Currency} }){
    foreach my $keys (@val) {
      if ($currency->{ISOCode} eq $keys) {
        $kgs_table->addrow($html->b("$currency->{ISOCode} / KGS"), $currency->{Value}->[0], $currency->{Nominal}->[0]);
      }
    }
  }

  return $kgs_table->show();
}

#**********************************************************
=head2 paysys_start_page($attr)

  Arguments:


  Returns:

=cut
#**********************************************************
sub paysys_start_page {
  my %START_PAGE_F = (
    # 'paysys_rub_exchange_rates' => "$lang{EXCHANGE_RATE} $lang{CBR}",
    'paysys_uah_exchange_rates' => "$lang{EXCHANGE_RATE} $lang{NBU}",
    'paysys_kgs_exchange_rates' => "$lang{EXCHANGE_RATE} $lang{NBKR}"
  );

  return \%START_PAGE_F;
}

#**********************************************************
=head2 paysys_select_connected_systems($attr)

  Arguments:
    $attr

  Results:
    Select_form

=cut
#**********************************************************
sub _paysys_select_connected_systems {
  my ($attr) = @_;

  return $html->form_select('SYSTEM_ID',
    {
      SELECTED    => $attr->{SYSTEM_ID} || $FORM{SYSTEM_ID} || '',
      SEL_LIST    => $Paysys->paysys_connect_system_list({ COLS_NAME => 1, ID => '_SHOW', NAME => '_SHOW', PAGE_ROWS => => 9999 }),
      SEL_KEY     => 'id',
      SEL_VALUE   => 'name',
      NO_ID       => 1,
      SEL_OPTIONS => { '' => '--' },
    });
}

#**********************************************************
=head2 paysys_users() - Import fees from_file

=cut
#**********************************************************
sub paysys_users {

  result_former({
    INPUT_DATA      => $Paysys,
    FUNCTION        => 'user_list',
    FUNCTION_PARAMS => {
      ONLY_SUBSCRIBES => 1
    },
    BASE_FIELDS     => 0,
    DEFAULT_FIELDS  => 'LOGIN,FIO,DEPOSIT,CREDIT,PAYSYS_ID,DATE,SUBSCRIBE_DATE_START,SUM',
    EXT_TITLES      => {
      paysys_id            => 'PAYSYS ID',
      date                 => $lang{DATE},
      sum                  => $lang{SUM},
      subscribe_date_start => $lang{START},
    },
    TABLE           => {
      width   => '100%',
      caption => "$lang{USERS} - $lang{SUBSCRIBES}",
      qs      => $pages_qs,
      ID      => 'PAYSYS_USERS_LIST',
      header  => '',
      EXPORT  => 1,
    },
    MAKE_ROWS       => 1,
    MODULE          => 'Paysys',
    TOTAL           => 1,
  });

  return 1;
}

#**********************************************************
=head2 paysys_request_log() - Show paysys requests on script paysys_check.cgi

=cut
#**********************************************************
sub paysys_request_log {
  if ($FORM{search_form} && !$user->{UID}) {
    if($FORM{FROM_DATE_TO_DATE}){
      ($FORM{FROM_DATE}, $FORM{TO_DATE}) = $FORM{"FROM_DATE_TO_DATE"} =~/(.+)\/(.+)/;
    }
    $FORM{SYSTEM_ID} = $FORM{PAYMENT_SYSTEM};
    my %PAY_SYSTEMS = ();

    my $connected_systems = $Paysys->paysys_connect_system_list({
      PAYSYS_ID => '_SHOW',
      NAME      => '_SHOW',
      MODULE    => '_SHOW',
      COLS_NAME => 1,
    });

    foreach my $payment_system (@$connected_systems) {
      $PAY_SYSTEMS{$payment_system->{paysys_id}} = $payment_system->{name};
    }

    my %ACTIVE_SYSTEMS = %PAY_SYSTEMS;
    $ACTIVE_SYSTEMS{'0'} = $lang{UNKNOWN};
    my %info = ();

    $info{PAY_SYSTEMS_SEL} = $html->form_select(
      'PAYMENT_SYSTEM',
      {
        SELECTED => $FORM{PAYMENT_SYSTEM} || '',
        SEL_HASH => { '' => $lang{ALL}, %ACTIVE_SYSTEMS },
        NO_ID    => 1
      }
    );

    $info{STATUS_SEL} = $html->form_select(
      'STATUS',
      {
        SELECTED     => $FORM{STATUS} || '',
        SEL_ARRAY    => [$lang{SUCCESS}, $lang{ERROR}],
        ARRAY_NUM_ID => 1,
        SEL_OPTIONS  => { '' => $lang{ALL} }
      }
    );

    $info{REQUEST_TYPE_SEL} = $html->form_select(
      'REQUEST_TYPE',
      {
        SELECTED     => $FORM{REQUEST_TYPE} || '',
        SEL_ARRAY    => [ 'Unknown', 'Presearch', 'Search', 'Check', 'Pay', 'Confirm', 'Cancel', 'Status' ],
        ARRAY_NUM_ID => 1,
        SEL_OPTIONS  => { '' => $lang{ALL} }
      }
    );

    $info{DATERANGE_PICKER} = $html->form_daterangepicker({
      NAME  => 'FROM_DATE/TO_DATE',
      VALUE => $FORM{'FROM_DATE_TO_DATE'},
    });

    form_search({ SEARCH_FORM => $html->tpl_show(_include('paysys_search_log', 'Paysys'),
      { %info, %FORM },
      { OUTPUT2RETURN => 1 })
    });
  }

  if ($FORM{del}) {
    $Paysys->log_del($FORM{del});

    if ($Paysys->{errno}) {
      $html->message('err', $lang{ERROR}, "$Paysys->{errno} $Paysys->{errstr}");
    }
    else {
      $html->message('info', $lang{INFO}, "$lang{DELETED} # $FORM{del}");
    }
  }

  my ($table) = result_former({
    INPUT_DATA        => $Paysys,
    FUNCTION          => 'log_list',
    BASE_FIELDS       => 0,
    FUNCTION_FIELDS   => 'del',
    DEFAULT_FIELDS    => 'ID,SYSTEM_ID,LOGIN,EXT_ID,TRANSACTION_ID,SUM,DATETIME',
    FILTER_COLS       => {
      transaction_id => '_paysys_log_filter::transaction_id,id',
      request        => '_paysys_log_filter::',
      response       => '_paysys_log_filter::',
      system_id      => '_paysys_log_filter::system_id,paysys_name',
      status         => '_paysys_log_filter::id,status',
      request_type   => '_paysys_log_filter::id,request_type',
    },
    EXT_TITLES        => {
      id             => 'ID',
      login          => $lang{LOGIN},
      request        => $lang{REQUEST},
      response       => $lang{RESPONSE},
      http_method    => "HTTP $lang{METHOD}",
      datetime       => $lang{DATE},
      ip             => 'IP',
      error          => $lang{ERROR},
      status         => $lang{STATUS},
      system_id      => $lang{PAY_SYSTEM},
      ext_id         => $lang{EXTERNAL_ID},
      transaction_id => "$lang{TRANSACTION} ID",
      sum            => $lang{SUM},
      request_type   => "$lang{REQUEST} $lang{TYPE}",
    },
    SKIP_USER_TITLE   => 1,
    SKIP_STATUS_CHECK => 1,
    TABLE             => {
      width   => '100%',
      caption => $lang{LOG_REQUESTS},
      qs      => $pages_qs,
      ID      => 'PAYSYS_REQUEST_LOG',
      pages   => $Paysys->{TOTAL},
      MENU    => "$lang{SEARCH}:index=$index&search_form=1:search;",
      EXPORT  => 1,
    },
    MODULE            => 'Paysys',
    MAKE_ROWS         => 1,
  });

  print $table->show();

  return 1;
}

#**********************************************************
=head2 _extreceipt_payment_filter()

=cut
#**********************************************************
sub _paysys_log_filter {
  my ($string, $values) = @_;

  if (defined $values->{VALUES}->{status}) {
    $values->{VALUES}->{status} ? return $lang{ERROR} : return $lang{SUCCESS};
  }
  elsif (defined $values->{VALUES}->{request_type}) {
    my %statuses = (
      0 => 'Unknown',
      1 => 'Presearch',
      2 => 'Search',
      3 => 'Check',
      4 => 'Pay',
      5 => 'Confirm',
      6 => 'Cancel',
      7 => 'Status',
    );

    return $statuses{$values->{VALUES}->{request_type} || 0};
  }
  elsif (defined $values->{VALUES}->{transaction_id}) {
    return $html->button($string, 'index=' . get_function_index('paysys_log') . "&search_form=1&search=1&ID=$values->{VALUES}->{transaction_id}");
  }
  elsif (defined $values->{VALUES}->{system_id}) {
    return $values->{VALUES}->{paysys_name} || $lang{UNKNOWN};
  }
  elsif ($string) {
    $string =~ s/</&lt;/gm;
    $string =~ s/>/&gt;/gm;
    $string = '<pre>' . $string . '</pre>';
  }

  return $string;
}

1;
