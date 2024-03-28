=head1 NAME

 Abon Configure

=cut

use strict;
use warnings FATAL => 'all';

our(
  $db,
  %conf,
  $admin,
  %lang,
  %permissions,
  @bool_vals
);

our AXbills::HTML $html;
my $Abon = Abon->new($db, $admin, \%conf);

require Abon::Base;
my $Abon_base = Abon::Base->new($db, $admin, \%conf, { HTML => $html, LANG => \%lang });

#*******************************************************************
=head2 abon_tariffs() - Change user tp form

=cut
#*******************************************************************
sub abon_tariffs {

  use Abon::Misc::Attachments;
  my $Attachments = Abon::Misc::Attachments->new($db, $admin, \%conf);
  my @PERIODS = ($lang{DAY}, $lang{MONTH}, $lang{QUARTER}, $lang{SIX_MONTH}, $lang{YEAR});

  $Abon->{ACTION} = 'add';
  $Abon->{ACTION_LNG} = $lang{ADD};
  my @Payment_Types = ($lang{PREPAID}, $lang{POSTPAID});

  if ($FORM{add}) {
    # if (!$FORM{PRICE} || $FORM{PRICE} < 0) {
    #   $html->message('err', $lang{ERROR}, "$lang{ERR_WRONG_SUM}");
    # }
    # else {
      my $picture_name = $Attachments->save_picture($FORM{SERVICE_IMG});
      $Abon->tariff_add({ %FORM, SERVICE_IMG => $picture_name });
      $html->message('info', $lang{INFO}, "$lang{ADDED}") if (!$Abon->{errno});
    # }
  }
  elsif ($FORM{ABON_ID}) {
    $Abon = $Abon->tariff_info($FORM{ABON_ID});
    return 0 if _error_show($Abon);

    $FORM{PERIOD} = $Abon->{PERIOD} if (!defined($FORM{PERIOD}));
    $Abon->{ACTION} = 'change';
    $Abon->{ACTION_LNG} = $lang{CHANGE};

    $pages_qs .= "&ABON_ID=$FORM{ABON_ID}" . (($FORM{subf}) ? "&subf=$FORM{subf}" : '');

    $LIST_PARAMS{ABON_ID} = $FORM{ABON_ID};
    $Abon->{ABON_ID} = $FORM{ABON_ID};
    my %F_ARGS = (ABON_ID => $Abon->{ID} || $FORM{ABON_ID});

    $Abon->{NAME_SEL} = $html->form_main({
      CONTENT => $html->form_select('ABON_ID', {
        SELECTED   => $Abon->{ID} || $FORM{ABON_ID},
        SEL_LIST   => $Abon->tariff_list({ COLS_NAME => 1 }),
        SEL_KEY    => 'tp_id',
        SEL_VALUE  => 'tp_name',
        AUTOSUBMIT => 'form'
      }),
      HIDDEN => {
        index => $index,
        subf  => $FORM{subf},
        show  => 1
      },
      class   => 'form-inline ml-auto flex-nowrap',
    });

    func_menu(
      {
        $lang{NAME} => $Abon->{NAME_SEL}
      },
      [
        $lang{INFO} . "::ABON_ID=$FORM{ABON_ID}",
        $lang{USERS} . ':' . get_function_index('abon_user_list') . ":ABON_ID=$FORM{ABON_ID}"
      ],
      { f_args => { %F_ARGS } }
    );

    if ($FORM{subf}) {
      return 0;
    }
    elsif ($FORM{change}) {
      if ($FORM{SERVICE_IMG}) {
        my $picture_name = $Attachments->save_picture($FORM{SERVICE_IMG}, $FORM{ABON_ID});
        $FORM{SERVICE_IMG} = $picture_name;
      }
      $Abon->tariff_change({ %FORM });
      $html->message('info', $lang{INFO}, $lang{CHANGED}) if !$Abon->{errno};
    }

    $Abon->{PROMOTIONAL} = $Abon->{PROMOTIONAL} ? 'checked' : '';
    if (my $api = $Abon_base->abon_load_plugin($Abon->{PLUGIN}, { SERVICE => $Abon  })) {

      if ( $api->can('test')) {
        $Abon->{API_TEST} = $html->button($lang{TEST}, "index=$index&test=1&ABON_ID=$FORM{ABON_ID}",
          { class => 'btn btn-secondary btn-success' });

        if ($FORM{test}) {
          $api->test();

          if (! _error_show($api)) {
            $html->message('info', $lang{INFO}, "Test OK\nAPI Connected");
          }
        }
      }

      if($api->can('tp_export')) {
        $Abon->{API_IMPORT} = $html->button($lang{IMPORT}, "index=$index&tp_import=1&ABON_ID=$FORM{ABON_ID}",
          { class => 'btn btn-secondary btn-success' });

        if ($FORM{tp_import}) {
          abon_import_tp($api);
        }
      }

      if($api->can('reports')) {
        $Abon->{API_REPORTS} = $html->button($lang{REPORTS}, "index=". get_function_index('abon_plugin_reports') ."&SERVICE_ID=$FORM{ABON_ID}",
          { class => 'btn btn-secondary btn-success' });
      }
    }

  }
  elsif (defined($FORM{del}) && $FORM{COMMENTS}) {
    $Abon->tariff_del($FORM{del});
    $html->message('info', $lang{INFO}, $lang{DELETED}) if !$Abon->{errno};
  }

  _error_show($Abon);

  $Abon->{PERIOD_SEL} = $html->form_select('PERIOD', {
    SELECTED     => $FORM{PERIOD},
    SEL_ARRAY    => \@PERIODS,
    ARRAY_NUM_ID => 1
  });

  $Abon->{PAYMENT_TYPE_SEL} = $html->form_select('PAYMENT_TYPE', {
    SELECTED     => $Abon->{PAYMENT_TYPE} || $FORM{PAYMENT_TYPE},
    SEL_ARRAY    => [ $lang{PREPAID}, $lang{POSTPAID} ],
    ARRAY_NUM_ID => 1
  });

  $Abon->{PRIORITY} = $html->form_select('PRIORITY', {
    SELECTED     => $Abon->{PRIORITY} || 0,
    SEL_ARRAY    => [ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 13, 13, 14, 15 ],
    ARRAY_NUM_ID => 1
  });

  my @ACCOUNT_PRIORITY = ($lang{MAIN}, "$lang{EXTRA} $lang{BILL}", "$lang{MAIN}, $lang{EXTRA} $lang{BILL}");

  $Abon->{ACCOUNT_SEL} = $html->form_select('ACCOUNT', {
    SELECTED     => $Abon->{ACCOUNT} || 0,
    SEL_ARRAY    => \@ACCOUNT_PRIORITY,
    ARRAY_NUM_ID => 1
  });

  $Abon->{PERIOD_ALIGNMENT} = ($Abon->{PERIOD_ALIGNMENT}) ? 'checked' : '';
  $Abon->{NONFIX_PERIOD} = ($Abon->{NONFIX_PERIOD}) ? 'checked' : '';

  if ($conf{EXT_BILL_ACCOUNT}) {

    my $checkbox = $html->element('input', '', {
      class          => 'form-check-input',
      type           => 'checkbox',
      value          => '1',
      name           => 'EXT_BILL_ACCOUNT',
      'data-checked' => ($Abon->{EXT_BILL_ACCOUNT}) ? 'checked' : ''
    });

    my $checkbox_container = $html->element('div', $html->element('div', $checkbox, { class => 'form-check' }), { class => 'col-md-8' });
    my $label = $html->element('label', "$lang{EXTRA} $lang{BILL}:", { class => 'col-md-4 col-form-label text-md-right' });

    $Abon->{EXT_BILL_ACCOUNT} = $label . $checkbox_container;
  }
  else {
    $Abon->{EXT_BILL_ACCOUNT} = '';
  }

  my $FEES_METHODS = get_fees_types();

  $Abon->{FEES_TYPES_SEL} = $html->form_select('FEES_TYPE', {
    SELECTED => $Abon->{FEES_TYPE},
    SEL_HASH => { '' => '', %$FEES_METHODS },
    NO_ID    => 1,
    SORT_KEY => 1
  });

  $Abon->{DEBUG_SEL} = $html->form_select('DEBUG', {
    SELECTED  => $Abon->{DEBUG} || $FORM{DEBUG} || 0,
    SEL_ARRAY => [ 0, 1, 2, 3, 4, 5, 6, 7 ],
  });

  my @recovery_plans = (
    $lang{NOT_RECOVERY},
    $lang{RECOVERY_NOW},
    $lang{RECOVERY_FROM_HOLDUP}
  );

  $Abon->{SERVICE_RECOVERY_SEL} = $html->form_select('SERVICE_RECOVERY', {
    SELECTED     => $Abon->{SERVICE_RECOVERY} || $FORM{SERVICE_RECOVERY} || 0,
    SEL_ARRAY    => \@recovery_plans,
    ARRAY_NUM_ID => 1
  });

  my %USER_PORTAL_TYPES = (
    0 => $lang{USER_PORTAL_NO},
    1 => $lang{USER_PORTAL_READ},
    2 => $lang{USER_PORTAL_EDIT}
  );

  $Abon->{USER_PORTAL} = $html->form_select('USER_PORTAL', {
    SELECTED => $Abon->{USER_PORTAL} || $FORM{USER_PORTAL},
    SEL_HASH => \%USER_PORTAL_TYPES,
    NO_ID    => 1,
    SORT_KEY => 1
  });

  my $categories = $Abon->category_list({ VISIBLE => 1, HASH_RETURN => 1, COLS_NAME => 1 });

  $Abon->{CATEGORY} = $html->form_select('CATEGORY_ID', {
    SELECTED => $Abon->{CATEGORY_ID} || $FORM{CATEGORY_ID} || '',
    SEL_HASH => $categories,
    NO_ID    => 1,
    SORT_KEY => 1
  });

  $Abon->{FEES_TYPE} = ($Abon->{FEES_TYPE}) ? 'checked' : '';
  $Abon->{NOTIFICATION_ACCOUNT} = ($Abon->{NOTIFICATION_ACCOUNT}) ? 'checked' : '';
  $Abon->{ALERT} = ($Abon->{ALERT}) ? 'checked' : '';
  $Abon->{ALERT_ACCOUNT} = ($Abon->{ALERT_ACCOUNT}) ? 'checked' : '';
  $Abon->{CREATE_ACCOUNT} = ($Abon->{CREATE_ACCOUNT}) ? 'checked' : '';
  $Abon->{ACTIVATE_NOTIFICATION} = ($Abon->{ACTIVATE_NOTIFICATION}) ? 'checked' : '';
  $Abon->{VAT} = ($Abon->{VAT}) ? 'checked' : '';
  $Abon->{DISCOUNT} = ($Abon->{DISCOUNT}) ? 'checked' : '';
  $Abon->{MANUAL_ACTIVATE} = ($Abon->{MANUAL_ACTIVATE}) ? 'checked' : '';

  if ($FORM{add} || $FORM{chg} || $FORM{change} || $FORM{ABON_ID} || $FORM{add_form}) {
    $html->tpl_show(_include('abon_tp', 'Abon'), $Abon);
  }

  my $user_index = get_function_index('abon_user_list');

  my %EXT_TITLES = (
    tp_name               => $lang{NAME},
    price                 => $lang{SUM},
    period                => $lang{PERIOD},
    fees_type             => "$lang{TYPE} $lang{FEES}",
    payment_type          => $lang{PAYMENT_TYPE},
    priority              => $lang{PRIORITY},
    description           => $lang{DESCRIBE},
    user_description      => "$lang{USER} $lang{DESCRIBE}",
    user_count            => $lang{USERS},
    ext_bill_account      => "$lang{EXTRA} $lang{BILL}",
    plugin                => $lang{PLUGIN},
    next_abon_date        => $lang{NEXT_ABON},
    ext_service_id        => "SERVICE_ID",
    period_alignment      => $lang{PERIOD_ALIGNMENT},
    discount              => $lang{REDUCTION},
    create_account        => "$lang{CREATE} $lang{SEND_ACCOUNT}",
    ext_cmd               => $lang{EXT_CMD},
    activate_notification => $lang{SERVICE_ACTIVATE_NOTIFICATION},
    manual_activate       => $lang{MANUAL_ACTIVATE},
    user_portal           => $lang{USER_PORTAL},
    vat                   => $lang{VAT},
    category_id           => $lang{CATEGORY},
  );

  delete $LIST_PARAMS{ABON_ID};
  my ($table, $list) = result_former({
    INPUT_DATA     => $Abon,
    FUNCTION       => 'tariff_list_former',
    DEFAULT_FIELDS => 'TP_NAME,DESCRIPTION,USER_DESCRIPTION,PERIOD,PRICE,COMMENTS,PAYMENT_TYPE,USER_COUNT',
    EXT_TITLES     => \%EXT_TITLES,
    TABLE          => {
      width      => '100%',
      caption    => "$lang{ABON} - $lang{TARIF_PLANS}",
      qs         => $pages_qs,
      ID         => 'ABON_TARIFFS_RESFORMER',
      FIELDS_IDS => $Abon->{COL_NAMES_ARR},
      MENU       => "$lang{ADD}:index=$index&add_form=1:add",
      EXPORT     => 1
    },
    SKIP_USER_TITLE => 1,
    MODULE         => 'Abon',
  });

  my @bool_values = ('manual_activate', 'nonfix_period', 'discount', 'vat', 'create_account', 'activate_notification', 'period_alignment', 'ext_bill_account');
  for my $line (@{$list}) {
    my @function_fields = (
      $html->button($lang{CHANGE}, "index=$index&ABON_ID=$line->{id}", { class => 'change' })
    );
    if ($permissions{4}{1}) {
      push (@function_fields,
        $html->button($lang{DEL}, "index=$index&del=$line->{id}", { MESSAGE => "$lang{DEL} $line->{tp_name}?", class => 'del' })
      );
    }
    my @fields = ();

    for (my $i = 0; $i < $Abon->{SEARCH_FIELDS_COUNT}; $i++) {
      my $col_name =  $Abon->{COL_NAMES_ARR}->[$i];
      my $value = $line->{$col_name};
      if ($col_name eq 'tp_name') {
        $value = $html->button($value, "index=$index&ABON_ID=$line->{id}");
      }
      elsif ($col_name eq 'payment_type') {
        $value = $Payment_Types[$value];
      }
      elsif ($col_name eq 'fees_type') {
        $value = $FEES_METHODS->{$value};
      }
      elsif ($col_name eq 'user_count') {
        $value = $html->button($value, "index=$index&ABON_ID=$line->{id}&subf=$user_index");
      }
      elsif ($col_name eq 'period') {
        $value = $PERIODS[$value],
      }
      elsif ($col_name eq 'user_portal') {
        $value = $USER_PORTAL_TYPES{$value};
      }
      elsif (grep { $col_name eq $_ } @bool_values) {
        $value = $bool_vals[$value];
      }
      elsif ($col_name eq 'category_id') {
        $value = $categories->{$value};
      }

      push @fields, $value;
    }

    $table->{rowcolor} = ($FORM{ABON_ID} && $FORM{ABON_ID} == $line->{id}) ? 'table-info' : undef;

    $table->addrow(
      @fields,
      join(' ', @function_fields)
    );
  }

  print $table->show();

  return 1;
}

#**********************************************************
=head2 abon_import_form($tp_list)

  Arguments:
    $Tv_service
    $tp_list
    $attr

  Results:

=cut
#**********************************************************
sub abon_import_form {
  my ($Plugin, $tp_list) = @_;

  my %SUBCRIBES_TYPE = (
    0 => $lang{TARIF_PLAN},
    1 => $lang{CHANNELS}
  );

  my $table = $html->table({
    width       => '100%',
    caption     => $lang{SUBSCRIBES},
    title_plain => [ '#', $lang{NUM}, $lang{NAME}, $lang{PRICE}, $lang{PERIOD}, $lang{TYPE} ],
    ID          => 'IPTV_EXPORT_TPS',
    EXPORT      => 1
  });

  foreach my $tp (@$tp_list) {
    my $tp_type = q{};

    if ($Plugin->{TP_LIST}) {
      $tp_type = $lang{TARIF_PLAN} . $html->form_input('TP_TYPE_' . $tp->{ID}, 0, { EX_PARAMS => 'readonly', TYPE => 'hidden' });
    }
    else {
      $tp_type = $html->form_select('TP_TYPE_' . $tp->{ID}, {
        SELECTED => 0,
        SEL_HASH => \%SUBCRIBES_TYPE,
        NO_ID    => 1
      });
    }

    my $tp_name = $tp->{NAME};
    my $is_utf = Encode::is_utf8($tp_name);
    if (!$is_utf) {
      Encode::_utf8_off($tp_name);
    }

    $table->addrow(
      $html->form_input('IDS', $tp->{ID}, { TYPE => 'checkbox' }),
      $tp->{ID},
      $html->form_input('NAME_' . $tp->{ID}, $tp_name, { EX_PARAMS => 'readonly' }),
      $html->form_input('PRICE_' . $tp->{ID}, $FORM{'PRICE_' . $tp->{ID}}),
      $html->form_input('PAYMENT_TYPE_' . $tp->{ID}, $FORM{'PAYMENT_TYPE_' . $tp->{ID}}),
      $tp_type
    );
  }

  my %extra_option = (tp_import => 2);

  if ($Plugin->{CHANNEL_LIST}) {
    %extra_option = (channel_import => 1);
  }

  print $html->form_main({
    CONTENT => $table->show({ OUTPUT2RETURN => 1 }),
    HIDDEN  => {
      index   => $index,
      %extra_option,
      chg     => $FORM{ABON_ID},
      ABON_ID => $FORM{ABON_ID},
    },
    METHOD  => 'post',
    SUBMIT  => { import => $lang{IMPORT} }
  });

  return 1;
}

#**********************************************************
=head2 abon_import_tp($attr)

  Arguments:

  Returns:

=cut
#**********************************************************
sub abon_import_tp {
  my ($Plugin) = @_;

  if ($FORM{tp_import}) {
    my %SUBCRIBES_TYPE = (
      0 => $lang{TARIF_PLAN},
      1 => $lang{CHANNELS}
    );

    $Plugin->{SERVICE_ID} = $FORM{chg} if ($FORM{chg});

    my $tp_list = $Plugin->tp_export();

    $Abon->{debug}=1;
    $Abon->tariff_info($FORM{ABON_ID});

    if($Plugin->{errno}) {
      _error_show($Plugin, { MESSAGE => "$lang{TARIF_PLANS} $lang{IMPORT}" });
      return 0;
    }

    if ($FORM{tp_import} == 2) {
      my $message = '';
      my @tp_ids = split(/,\s?/, $FORM{IDS} || q{});
      foreach my $tp_id (@tp_ids) {
        $Abon->tariff_add({
          #  SERVICE_ID => $Iptv->{ID},
          NAME         => $FORM{'NAME_' . $tp_id},
          PRICE        => $FORM{'PRICE_' . $tp_id},
          PAYMENT_TYPE => $FORM{'PAYMENT_TYPE_'. $tp_id} || 0,
          EXT_SERVICE_ID  => $tp_id,
          #  ID         => $tp_id,
          #  MODULE     => 'Iptv'
          PLUGIN       => $Abon->{PLUGIN},
          URL          => $Abon->{URL},
          LOGIN        => $Abon->{LOGIN},
          PASSWORD     => $Abon->{PASSWORD}
        });

        my $iptv_tp_id = $Abon->{ID} || 0;

        _error_show($Abon, { MESSAGE => "$lang{TARIF_PLAN}: " . $tp_id });

        $message .= "$Abon->{ABON_ID} $tp_id - $FORM{'NAME_' . $tp_id} $lang{TYPE}:"
          . $SUBCRIBES_TYPE{$FORM{'TP_TYPE_' . $tp_id}}
          . (($iptv_tp_id) ? ' ' . $html->button('', "index=" . get_function_index('iptv_tp') . "&TP_ID=" . $iptv_tp_id, { class => 'change' }) : '')
          . "\n\nPLUGIN: $Abon->{PLUGIN} \n"
          . "URL: $Abon->{URL}\n"
          . "LOGIN: $Abon->{LOGIN} \n"
          . "PASSWORD: $Abon->{PASSWORD}\n"
          . "\n";
      }

      $html->message('info', $lang{INFO}, $message);
    }
    else {
      abon_import_form($Plugin, $tp_list);
      return 0;
    }
  }

  return 1;
}

#**********************************************************
=head2 _plugin_sel($attr)

  Arguments:
     SERVICE_ID
     FORM_ROW
     USER_PORTAL
     HASH_RESULT
     ALL
     SKIP_DEF_SERVICE
     UNKNOWN

  Returns:

=cut
#**********************************************************
sub _plugin_sel {
  my ($attr) = @_;

  my %params = ();

  $params{SEL_OPTIONS} = { '' => $lang{ALL} } if ($attr->{ALL} || $FORM{search_form});
  $params{SEL_OPTIONS}->{0} = $lang{UNKNOWN} if ($attr->{UNKNOWN});
  $params{NO_ID} = $attr->{NO_ID};
  $params{AUTOSUBMIT} = $attr->{AUTOSUBMIT} if (defined($attr->{AUTOSUBMIT}));

  my $active_service = $attr->{SERVICE_ID} || $FORM{SERVICE_ID};

  my $service_list = $Abon->tariff_list({
    STATUS      => 0,
    NAME        => '_SHOW',
    PLUGIN      => '_SHOW',
    COLS_NAME   => 1,
    PAGE_ROWS   => 1,
  });

  if ($attr->{HASH_RESULT}) {
    my %service_name = ();

    foreach my $line (@$service_list) {
      if ($line->{plugin}) {
        $service_name{$line->{id}} = "$line->{name}:$line->{plugin}";
      }
    }

    return \%service_name;
  }

  if ($Abon->{TOTAL} && $Abon->{TOTAL} > 0) {
    if($Abon->{TOTAL} == 1) {
      delete $params{SEL_OPTIONS};
      $Abon->{SERVICE_ID} = $service_list->[0]->{id};
    }
    else {
      if (!$FORM{SERVICE_ID} && !$active_service) {
        $FORM{SERVICE_ID} = $service_list->[0]->{id};
        $active_service = $service_list->[0]->{id};
      }
    }
  }

  if (!$attr->{HIDE_MENU_BTN} && $permissions{4} && $permissions{4}{2}) {
    $params{MAIN_MENU} = get_function_index('abon_tariffs');
    $params{MAIN_MENU_ARGV} = ($active_service) ? "ABON_ID=$active_service" : q{};
  }

  my $result = $html->form_select('SERVICE_ID', {
    SELECTED  => $active_service,
    SEL_LIST  => $service_list,
    SEL_KEY   => 'tp_id',
    SEL_VALUE => 'tp_name,plugin',
    EX_PARAMS => defined($attr->{EX_PARAMS}) ? $attr->{EX_PARAMS} : "onchange='autoReload()'",
    %params
  });

  return $result if $attr->{RETURN_SELECT};

  if (!$active_service && $service_list->[0] && !$FORM{search_form} && ! $attr->{SKIP_DEF_SERVICE}) {
    $FORM{SERVICE_ID} = $service_list->[0]->{id};
  }

  $result = $html->tpl_show(templates('form_row'), {
    ID    => 'SERVICE_ID',
    NAME  => $lang{SERVICE},
    VALUE => $result
  }, { OUTPUT2RETURN => 1 }) if ($attr->{FORM_ROW});

  return $result;
}


#**********************************************************
=head2 abon_plugin_reports($plugin_name, $attr) - Load plugin module

  Argumnets:
    $plugin_name  - service modules name
    $attr
       SERVICE_ID
       SOFT_EXCEPTION
       RETURN_ERROR

  Returns:
    Module object

=cut
#**********************************************************
sub abon_plugin_reports {
  my($attr) = @_;

  my $services = $html->form_main({
    CONTENT => _plugin_sel({ AUTOSUBMIT => 'form' }),
    HIDDEN  => {
      index => $index,
      show => 1
    },
    class   => 'form-inline ml-auto flex-nowrap',
  });

  func_menu({ $lang{NAME} => $services });

  return 1 if (! $FORM{SERVICE_ID}) ;

  $Abon = $Abon->tariff_info($FORM{SERVICE_ID});

  my $Plugin = $Abon_base->abon_load_plugin($FORM{PLUGIN}, { SERVICE_ID => $FORM{SERVICE_ID}, SERVICE => $Abon });
  return 1 if (!$Plugin);

  if ($Plugin->{SERVICE_CONSOLE}) {
    my $fn = $Plugin->{SERVICE_CONSOLE};
    &{\&$fn}({ %FORM, %{$attr}, %{$Abon}, SERVICE_ID => $FORM{SERVICE_ID} });
  }
  elsif ($Plugin->can('reports')) {
    $LIST_PARAMS{TYPE} = $FORM{TYPE} if ($FORM{TYPE});

    $Plugin->reports({ %FORM, %LIST_PARAMS, SERVICE_ID => $FORM{SERVICE_ID} });
    _error_show($Plugin);

    return 0 unless $Plugin->{REPORT};
    result_former({
      FUNCTION_FIELDS => $Plugin->{FUNCTION_FIELDS},
      SKIP_USER_TITLE => 1,
      EXT_TITLES      => {
        id   => 'ID',
        name => $lang{NAME}
      },
      TABLE           => {
        width   => '100%',
        caption => ($Plugin->{REPORT_NAME} && $lang{$Plugin->{REPORT_NAME}}) ? $lang{$Plugin->{REPORT_NAME}} : $Plugin->{REPORT_NAME},
        qs      => "&list=" . ($FORM{list} || '') . (($FORM{SERVICE_ID}) ? "&SERVICE_ID=$FORM{SERVICE_ID}" : ''),
        EXPORT  => 1,
        ID      => 'TV_REPORTS',
        header  => $Plugin->{MENU}
      },
      DATAHASH        => $Plugin->{REPORT},
      SKIPP_UTF_OFF   => ($Plugin && $Plugin->{SERVICE_NAME} eq 'Smotreshka') ? undef : 1,
      TOTAL           => 1
    });
  }

  return 1;
}


#*******************************************************************
=head2 abon_categories() - Managing categories of abon tariffs

=cut
#*******************************************************************
sub abon_categories {

  if ($FORM{add}) {
    $Abon->category_add(\%FORM);
    $html->message('success', $lang{ADDED} ) if (!_error_show($Abon));
  }
  elsif ($FORM{chg}) {
    $Abon->{BTN_NAME} = 'change';
    $Abon->{BTN_VALUE} = $lang{CHANGE};
    $Abon->category_info({ ID => $FORM{chg} });
    $Abon->{VISIBLE} = ($Abon->{VISIBLE}) ? 'checked' : '';
  }
  elsif ($FORM{change}) {
    $Abon->category_change(\%FORM);
    $html->message('success', $lang{CHANGED}) if (!_error_show($Abon));
  }
  elsif ($FORM{del}) {
    $Abon->category_del({ ID => $FORM{del} });
    $html->message('success', $lang{DELETED})  if (!_error_show($Abon));
  }

  if ($FORM{add_form} || $FORM{chg} ) {
    print $html->tpl_show(_include('abon_category', 'Abon'), {
      INDEX => $index,
      BTN_NAME => 'add',
      BTN_VALUE => $lang{ADD},
      %$Abon
    }, { OUTPUT2RETURN => 1 });
  }

  my $category_list = $Abon->category_list({
    ALL       => 1,
    COLS_NAME => 1,
    SORT      => $FORM{sort},
    DESC      => $FORM{desc},
  });

  my $table = $html->table({
    width      => '100%',
    caption    => $lang{CATEGORIES},
    title      => [ "#", $lang{NAME}, $lang{DESCRIPTION}, $lang{PUBLIC_DESCRIPTION}, $lang{USER_PORTAL_YES}],
    qs         => $pages_qs,
    ID         => 'ABON_CATEGORIES_LIST',
    MENU       => "$lang{ADD}:index=$index&add_form=1:add"
  });

  foreach my $line (@$category_list) {
    $table->addrow(
      $line->{id},
      $line->{name},
      $line->{dsc},
      $line->{public_dsc},
      ($line->{visible} && $line->{visible} == 1) ? '<i class="fa fa-check text-success"></i>' : '<i class="fa fa-times"></i>',
      $html->button($lang{CHANGE}, "index=$index&chg=$line->{id}", { class => 'change' }),
      $html->button($lang{DEL}, "index=$index&del=$line->{id}", { MESSAGE => "$lang{DEL} $line->{name}?", class => 'del' })
    );
  }

  print $table->show();

  return 1;
}


1;