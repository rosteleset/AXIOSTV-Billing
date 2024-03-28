use strict;
use warnings FATAL => 'all';

=head1 NAME

  Crm::Info_fields - crm leads info fields

=cut

our (
  @PRIORITY,
  %lang,
  %conf,
  $admin,
  $db,
  %permissions,
  %LIST_PARAMS,
  $users
);

use Time::Piece;
our Crm $Crm;
our AXbills::HTML $html;

my @fields_types = (
  'string',
  'integer',
  'list',
  'text',
  'flag',
  'autoincrement',
  'url',
  'language',
  'time_zone',
  'date',
);

my @fields_types_lang = (
  'String',
  'Integer',
  $lang{LIST},
  $lang{TEXT},
  'Flag',
  'AUTOINCREMENT',
  'URL',
  $lang{LANGUAGE},
  'Time zone',
  $lang{DATE},
);

my @assessments = (
  { id => 1, name => $lang{CRM_BAD} },
  { id => 2, name => $lang{CRM_UNSATISFACTORILY} },
  { id => 3, name => $lang{CRM_SATISFACTORILY} },
  { id => 4, name => $lang{CRM_GOOD} },
  { id => 5, name => $lang{CRM_IDEALLY} },
);
if ($conf{CRM_COMPETITOR_ASSESSMENT} && ref $conf{CRM_COMPETITOR_ASSESSMENT} eq 'ARRAY') {
  @assessments = ();
  while (my ($index,$value) = each @{$conf{CRM_COMPETITOR_ASSESSMENT}}) {
    push(@assessments, { id => $index + 1, name => $value });
  }
}

#**********************************************************
=head2 crm_info_fields($attr)

=cut
#**********************************************************
sub crm_info_fields {

  my %TEMPLATE_VARIABLES = ();

  if ($FORM{LIST_TABLE} && $FORM{LIST_TABLE_NAME}) {
    crm_info_lists();
    return;
  }

  if ($FORM{add}) {
    if (!$FORM{SQL_FIELD}) {
      $html->message('err', $lang{ERROR}, "$lang{ERR_WRONG_DATA} (SQL_FIELD)");
    }
    elsif (length($FORM{SQL_FIELD}) > 20) {
      $html->message('err', $lang{ERROR}, "$lang{ERR_WRONG_DATA} (Length > 20)");
    }
    else {
      $Crm->lead_field_add({
        POSITION   => $FORM{PRIORITY},
        FIELD_TYPE => $FORM{TYPE},
        FIELD_ID   => $FORM{SQL_FIELD},
        NAME       => $FORM{NAME},
      });
      $Crm->fields_add({ %FORM });
    }
  }
  elsif ($FORM{change}) {
    $Crm->fields_change({ %FORM });
  }
  elsif ($FORM{chg}) {
    $Crm->field_info($FORM{chg});
    $TEMPLATE_VARIABLES{READONLY2} = "disabled";
    $TEMPLATE_VARIABLES{READONLY} = "readonly";
    $TEMPLATE_VARIABLES{REGISTRATION} = 'checked' if $Crm->{REGISTRATION};
    $TEMPLATE_VARIABLES{TYPE_SELECT} = $html->element('input', '', {
      readonly => 'readonly',
      type     => 'text',
      class    => 'form-control',
      value    => $Crm->{TOTAL} > 0 ? $fields_types_lang[$Crm->{TYPE}] : q{},
    });
  }
  elsif ($FORM{del} && $FORM{COMMENTS}) {
    $Crm->field_info($FORM{del});
    $Crm->lead_field_del({ FIELD_ID => $Crm->{SQL_FIELD} });
    $Crm->fields_del($FORM{del}, { COMMENTS => $FORM{COMMENTS} });
  }

  $html->tpl_show(_include('crm_info_fields', 'Crm'), {
    %{$Crm},
    TYPE_SELECT       => $html->form_select('TYPE', {
      SELECTED     => $Crm->{TYPE} || 0,
      SEL_ARRAY    => \@fields_types_lang,
      ARRAY_NUM_ID => 1,
      SEL_OPTIONS  => { "" => "" }
    }),
    %TEMPLATE_VARIABLES,
    SUBMIT_BTN_ACTION => ($FORM{chg}) ? 'change' : 'add',
    SUBMIT_BTN_NAME   => ($FORM{chg}) ? $lang{CHANGE} : $lang{ADD},
  });

  _crm_info_fields_table();
}

#**********************************************************
=head2 crm_tp_info_fields($attr)

=cut
#**********************************************************
sub crm_tp_info_fields {

  my %TEMPLATE_VARIABLES = ();

  if ($FORM{LIST_TABLE} && $FORM{LIST_TABLE_NAME}) {
    crm_info_lists({ TP_INFO_FIELDS => 1 });
    return;
  }

  if ($FORM{add}) {
    if (!$FORM{SQL_FIELD}) {
      $html->message('err', $lang{ERROR}, "$lang{ERR_WRONG_DATA} (SQL_FIELD)");
    }
    elsif (length($FORM{SQL_FIELD}) > 20) {
      $html->message('err', $lang{ERROR}, "$lang{ERR_WRONG_DATA} (Length > 20)");
    }
    else {
      $Crm->lead_field_add({
        POSITION       => $FORM{PRIORITY},
        FIELD_TYPE     => $FORM{TYPE},
        FIELD_ID       => $FORM{SQL_FIELD},
        NAME           => $FORM{NAME},
        TP_INFO_FIELDS => 1
      });
      $Crm->fields_add({ %FORM, TP_INFO_FIELDS => 1 });
    }
  }
  elsif ($FORM{change}) {
    $Crm->fields_change({ %FORM, TP_INFO_FIELDS => 1 });
  }
  elsif ($FORM{chg}) {
    $Crm->field_info($FORM{chg}, { TP_INFO_FIELDS => 1 });
    $TEMPLATE_VARIABLES{READONLY2} = "disabled";
    $TEMPLATE_VARIABLES{READONLY} = "readonly";
    $TEMPLATE_VARIABLES{TYPE_SELECT} = $html->element('input', '', {
      readonly => 'readonly',
      type     => 'text',
      class    => 'form-control',
      value    => $Crm->{TOTAL} > 0 ? $fields_types_lang[$Crm->{TYPE}] : q{},
    });
  }
  elsif ($FORM{del} && $FORM{COMMENTS}) {
    $Crm->field_info($FORM{del}, { TP_INFO_FIELDS => 1 });
    $Crm->lead_field_del({ FIELD_ID => $Crm->{SQL_FIELD}, TP_INFO_FIELDS => 1 });
    $Crm->fields_del($FORM{del}, { COMMENTS => $FORM{COMMENTS}, TP_INFO_FIELDS => 1 });
  }

  $html->tpl_show(_include('crm_info_fields', 'Crm'), {
    %{$Crm},
    TYPE_SELECT       => $html->form_select('TYPE', {
      SELECTED     => $Crm->{TYPE} || 0,
      SEL_ARRAY    => \@fields_types_lang,
      ARRAY_NUM_ID => 1,
      SEL_OPTIONS  => { "" => "" }
    }),
    %TEMPLATE_VARIABLES,
    SUBMIT_BTN_ACTION => ($FORM{chg}) ? 'change' : 'add',
    SUBMIT_BTN_NAME   => ($FORM{chg}) ? $lang{CHANGE} : $lang{ADD},
  });

  $LIST_PARAMS{TP_INFO_FIELDS} = 1;
  _crm_info_fields_table();
}

#**********************************************************
=head2 _crm_info_fields_table($attr)

=cut
#**********************************************************
sub _crm_info_fields_table {

  result_former({
    INPUT_DATA      => $Crm,
    FUNCTION        => 'fields_list',
    DEFAULT_FIELDS  => 'ID,NAME,SQL_FIELD,TYPE,PRIORITY,COMMENT',
    FUNCTION_FIELDS => 'change,del',
    SKIP_USER_TITLE => 1,
    EXT_TITLES      => {
      id        => '#',
      name      => $lang{NAME},
      sql_field => "SQL_FIELD",
      type      => $lang{TYPE},
      priority  => $lang{PRIORITY},
      comment   => $lang{COMMENTS},
    },
    FILTER_VALUES   => {
      type => sub {
        my (undef, $line) = @_;
        if ($line->{type} == 2) {
          $html->button($fields_types_lang[2], "index=$index&LIST_TABLE=$line->{id}&LIST_TABLE_NAME=$line->{sql_field}");
        }
        else {
          $fields_types_lang[$line->{type}];
        }
      }
    },
    TABLE           => {
      width   => '100%',
      caption => $lang{INFO_FIELDS},
      ID      => "CRM_INFO_FIELDS",
      MENU    => "$lang{ADD}:index=$index&add_form=1&$pages_qs:add; :index=$index&update_table=1&$pages_qs:fa fa-reply",
    },
    MAKE_ROWS       => 1,
    TOTAL           => 1
  });
}

#**********************************************************
=head2 crm_info_lists($attr)

=cut
#**********************************************************
sub crm_info_lists {
  my ($attr) = @_;

  my $action_lng = $lang{ADD};
  my $action_value = 'add';

  if ($FORM{add}) {
    $Crm->info_list_add({ %FORM, TP_INFO_FIELDS => $attr->{TP_INFO_FIELDS} || 0 });
    $html->message('info', $lang{INFO}, "$lang{ADDED}: $FORM{NAME}") if (!_error_show($Crm));
  }
  elsif ($FORM{change}) {
    $Crm->info_list_change({ ID => $FORM{chg}, %FORM, TP_INFO_FIELDS => $attr->{TP_INFO_FIELDS} || 0 });
    $html->message('info', $lang{INFO}, "$lang{CHANGED}: $FORM{NAME}") if (!_error_show($Crm));
  }
  elsif ($FORM{chg}) {
    $action_lng = $lang{CHANGE};
    $action_value = 'change';

    $Crm->info_list_info($FORM{chg}, { %FORM, TP_INFO_FIELDS => $attr->{TP_INFO_FIELDS} || 0 });
    if (!_error_show($Crm)) {
      $FORM{INFO_NAME} = $Crm->{NAME};
      $FORM{ID} = $Crm->{ID};
    }
  }
  elsif ($FORM{del} && $FORM{COMMENTS}) {
    $Crm->info_list_del({ ID => $FORM{del}, %FORM, TP_INFO_FIELDS => $attr->{TP_INFO_FIELDS} || 0 });
    $html->message('info', $lang{INFO}, "$lang{DELETED}: $FORM{del}") if (!_error_show($Crm));
  }

  my $lists = $html->form_main({
    CONTENT => $html->form_select('LIST_TABLE', {
      SELECTED  => $FORM{LIST_TABLE},
      SEL_LIST  => $Crm->fields_list({ TYPE => 2, TP_INFO_FIELDS => $attr->{TP_INFO_FIELDS} || 0 }),
      SEL_KEY   => 'id',
      SEL_VALUE => 'name',
      NO_ID     => 1
    }),
    HIDDEN  => {
      index           => $index,
      LIST_TABLE      => $FORM{LIST_TABLE},
      LIST_TABLE_NAME => $FORM{LIST_TABLE_NAME}
    },
    SUBMIT  => { show => $lang{SHOW} },
    class   => 'navbar navbar-expand-lg',
  });

  func_menu({ $lang{NAME} => $lists });

  my $table = $html->table({
    caption => $lang{LIST},
    title   => [ '#', $lang{NAME}, '-', '-' ],
    ID      => 'LIST'
  });

  my $list = $Crm->info_lists_list({ %FORM, COLS_NAME => 1, TP_INFO_FIELDS => $attr->{TP_INFO_FIELDS} || 0 });
  foreach my $line (@{$list}) {
    my $chg_btn = $html->button($lang{CHANGE}, "index=$index&LIST_TABLE=$FORM{LIST_TABLE}" .
      "&LIST_TABLE_NAME=$FORM{LIST_TABLE_NAME}&chg=$line->{id}", { class => 'change' });
    my $del_btn = $html->button($lang{DEL}, "index=$index&LIST_TABLE=$FORM{LIST_TABLE}&LIST_TABLE_NAME=$FORM{LIST_TABLE_NAME}" .
      "&del=$line->{id}", { MESSAGE => "$lang{DEL} $line->{id} / $line->{name}?", class => 'del' });

    $table->addrow($line->{id}, $line->{name}, $chg_btn, $del_btn);
  }

  $table->addrow($FORM{ID} || '', $html->form_input('NAME', $FORM{INFO_NAME} || '', { SIZE => 80 }),
    $html->form_input($action_value, $action_lng, { TYPE => 'SUBMIT' }), '');

  print $html->form_main({
    CONTENT => $table->show(),
    HIDDEN  => {
      index           => $index,
      chg             => $FORM{chg},
      LIST_TABLE      => $FORM{LIST_TABLE},
      LIST_TABLE_NAME => $FORM{LIST_TABLE_NAME}
    },
    NAME    => 'list_add'
  });
}

#**********************************************************
=head2 crm_lead_info_field_tpl($attr) - Info fields

  Arguments:
    COMPANY                - Company info fields
    VALUES                 - Info field value hash_ref
    RETURN_AS_ARRAY        - returns hash_ref for name => $input (for custom design logic)
    CALLED_FROM_CLIENT_UI  - apply client_permission view/edit logic

  Returns:
    Return formed HTML

=cut
#**********************************************************
sub crm_lead_info_field_tpl {
  my ($attr) = @_;

  my $fields_list = $Crm->fields_list({
    SORT           => 'priority',
    TP_INFO_FIELDS => $attr->{TP_INFO_FIELDS} || 0,
    REGISTRATION   => $attr->{REGISTRATION} || '_SHOW' # ????
  });

  my @field_result = ();

  foreach my $field (@{$fields_list}) {
    next if !defined($field->{TYPE}) || !$fields_types[$field->{TYPE}];

    my $function_name = 'crm_info_field_' . $fields_types[$field->{TYPE}];
    next if !defined(&$function_name);

    my $disabled_ex_params = ($attr->{READ_ONLY} || ($attr->{CALLED_FROM_CLIENT_UI}))
      ? ' disabled="disabled" readonly="readonly"' : '';

    $field->{TITLE} ||= '';
    $field->{PLACEHOLDER} ||= '';
    $field->{SQL_FIELD} = uc $field->{SQL_FIELD} if $field->{SQL_FIELD};

    my $input = defined(&$function_name) ? &{\&{$function_name}}($field, {
      DISABLED       => $disabled_ex_params || '',
      VALUE          => $attr->{$field->{SQL_FIELD}} || '',
      TP_INFO_FIELDS => $attr->{TP_INFO_FIELDS} || 0
    }) : '';

    next if !$input;

    push @field_result, $html->tpl_show(templates('form_row'), {
      ID         => $field->{ID},
      NAME       => (_translate($field->{NAME})),
      VALUE      => $input,
      COLS_LEFT  => $attr->{COLS_LEFT},
      COLS_RIGHT => $attr->{COLS_RIGHT},
    }, { OUTPUT2RETURN => 1, ID => $field->{ID} });
  }

  return join((($FORM{json}) ? ',' : ''), @field_result);
}

#**********************************************************
=head2 crm_info_field_string($attr) - String info fields

=cut
#**********************************************************
sub crm_info_field_string {
  my $field = shift;
  my ($attr) = @_;

  $field->{PLACEHOLDER} //= '';
  return $html->form_input($field->{SQL_FIELD}, $attr->{VALUE}, {
    ID            => $field->{ID},
    EX_PARAMS     => "$attr->{DISABLED} title='$field->{TITLE}'"
      . ($field->{PATTERN} ? " pattern='$field->{PATTERN}'" : '')
      . "' placeholder='$field->{PLACEHOLDER}'",
    OUTPUT2RETURN => 1
  });
}

#**********************************************************
=head2 crm_info_field_integer($attr) - Integer info fields

=cut
#**********************************************************
sub crm_info_field_integer {
  my $field = shift;
  my ($attr) = @_;

  return crm_info_field_string($field, $attr);
}

#**********************************************************
=head2 crm_info_field_date($attr) - Date info fields

=cut
#**********************************************************
sub crm_info_field_date {
  my $field = shift;
  my ($attr) = @_;

  return $html->form_datepicker($field->{SQL_FIELD}, $attr->{VALUE}, { TITLE => $field->{TITLE}, OUTPUT2RETURN => 1 });
}

#**********************************************************
=head2 crm_info_field_time_zone($attr) - Time-zone info fields

=cut
#**********************************************************
sub crm_info_field_time_zone {
  my $field = shift;
  my ($attr) = @_;

  my $val = $attr->{VALUE} || 0;
  my @sel_list = map {{ id => $_, name => "UTC" . sprintf("%+.2d", $_) . ":00" }} (-12 ... 12);
  my $select = $html->form_select($field->{SQL_FIELD}, {
    SEL_LIST      => \@sel_list,
    SELECTED      => $val,
    NO_ID         => 1,
    OUTPUT2RETURN => 1
  });

  my $input = $html->element('div', $select, { class => 'col-md-8', OUTPUT2RETURN => 1 });
  my Time::Piece $t = gmtime();
  $t = $t + 3600 * $val;

  $input .= $html->element('label', $t->hms, { class => 'control-label col-md-4', OUTPUT2RETURN => 1 });

  return $html->element('div', $input, { class => 'row', OUTPUT2RETURN => 1 });
}

#**********************************************************
=head2 crm_info_field_time_zone_label($attr) - Time-zone info fields label

=cut
#**********************************************************
sub crm_info_field_time_zone_label {
  my $field = shift;
  my ($attr) = @_;

  my @sel_list = map {{ id => $_, name => "UTC" . sprintf("%+.2d", $_) . ":00" }} (-12 ... 12);

  my $val = $attr->{VALUE} || 0;
  my Time::Piece $t = gmtime();
  $t = $t + 3600 * $val;

  return $sel_list[$val]{name} . $html->element('label', $t->hms, { class => 'float-right', OUTPUT2RETURN => 1 });
}

#**********************************************************
=head2 crm_info_field_language($attr) - Language info fields

=cut
#**********************************************************
sub crm_info_field_language {
  my $field = shift;
  my ($attr) = @_;

  my @lang_list = map {my ($language, $lang_name) = split(':', $_);
    { id => $language, name => $lang_name };} split(';\s*', $conf{LANGS});

  return $html->form_select($field->{SQL_FIELD}, {
    SEL_LIST      => \@lang_list,
    SELECTED      => $attr->{VALUE},
    NO_ID         => 1,
    OUTPUT2RETURN => 1
  });
}

#**********************************************************
=head2 crm_info_field_language_label($attr) - Language info fields label

=cut
#**********************************************************
sub crm_info_field_language_label {
  my $field = shift;
  my ($attr) = @_;

  my %lang_list = map { split /:/ } split(';\s*', $conf{LANGS});
  return $attr->{VALUE} && $lang_list{$attr->{VALUE}} ? $lang_list{$attr->{VALUE}} : '';
}

#**********************************************************
=head2 crm_info_field_url($attr) - Url info fields

=cut
#**********************************************************
sub crm_info_field_url {
  my $field = shift;
  my ($attr) = @_;

  my $go_button = $html->element('div', $html->button($lang{GO}, "", {
    GLOBAL_URL => '',
    ex_params  => ' target=_new',
  }), { class => 'input-group-text' });

  return $html->element('div', $html->form_input($field->{SQL_FIELD}, $attr->{VALUE}, { ID => $field->{ID}, EX_PARAMS => $attr->{DISABLED}, OUTPUT2RETURN => 1 }) .
    $html->element('div', $go_button, { class => 'input-group-append' }), { class => 'input-group' });
}

#**********************************************************
=head2 crm_info_field_url_label($attr) - Url info fields label

=cut
#**********************************************************
sub crm_info_field_url_label {
  my $field = shift;
  my ($attr) = @_;

  return '' if !$attr->{VALUE};

  return $html->element('div', $html->button($lang{GO}, '', {
    GLOBAL_URL => $attr->{VALUE},
    ex_params  => ' target=_new',
  }), { class => 'input-group-text' });
}

#**********************************************************
=head2 crm_info_field_autoincrement ($attr) - Autoincrement info fields

=cut
#**********************************************************
sub crm_info_field_autoincrement {
  my $field = shift;
  my ($attr) = @_;

  return crm_info_field_string($field, $attr);
}

#**********************************************************
=head2 crm_info_field_flag ($attr) - Flag info fields

=cut
#**********************************************************
sub crm_info_field_flag {
  my $field = shift;
  my ($attr) = @_;

  return $html->form_input($field->{SQL_FIELD}, 1, {
    TYPE          => 'checkbox',
    STATE         => $attr->{VALUE} ? 1 : undef,
    ID            => $field->{ID},
    EX_PARAMS     => $attr->{DISABLED} . ((!$attr->{SKIP_DATA_RETURN}) ? " data-return='1' " : ''),
    OUTPUT2RETURN => 1
  });
}

#**********************************************************
=head2 crm_info_field_flag_label ($attr) - Flag info fields label

=cut
#**********************************************************
sub crm_info_field_flag_label {
  my $field = shift;
  my ($attr) = @_;

  return $attr->{VALUE} ? $lang{YES} : $lang{NO};
}

#**********************************************************
=head2 crm_info_field_text ($attr) - Textarea info fields

=cut
#**********************************************************
sub crm_info_field_text {
  my $field = shift;
  my ($attr) = @_;

  return $html->form_textarea($field->{SQL_FIELD}, $attr->{VALUE}, {
    ID            => $field->{SQL_FIELD},
    EX_PARAMS     => $attr->{DISABLED},
    OUTPUT2RETURN => 1
  });
}

#**********************************************************
=head2 crm_info_field_list ($attr) - List info fields

=cut
#**********************************************************
sub crm_info_field_list {
  my $field = shift;
  my ($attr) = @_;

  return $html->form_select($field->{SQL_FIELD},{
    SELECTED      => $attr->{VALUE},
    SEL_LIST      => $Crm->info_lists_list({ LIST_TABLE_NAME => lc $field->{SQL_FIELD}, TP_INFO_FIELDS => $attr->{TP_INFO_FIELDS} || 0, COLS_NAME => 1 }),
    SEL_OPTIONS   => { '' => '--' },
    NO_ID         => 1,
    ID            => $field->{SQL_FIELD},
    EX_PARAMS     => $attr->{DISABLED},
    OUTPUT2RETURN => 1
  });
}

#**********************************************************
=head2 crm_info_field_list_label ($attr) - List info fields label

=cut
#**********************************************************
sub crm_info_field_list_label {
  my $field = shift;
  my ($attr) = @_;

  my $list_info = $Crm->info_list_info($attr->{VALUE}, {
    LIST_TABLE_NAME => lc $field->{SQL_FIELD},
    TP_INFO_FIELDS => $attr->{TP_INFO_FIELDS} || 0,
    COLS_NAME => 1
  });

  return $list_info->{NAME} || _crm_empty_field();
}

#**********************************************************
=head2 crm_lead_fields ($lead, $ex_params, $ex_buttons)

=cut
#**********************************************************
sub crm_lead_fields {
  my ($lead, $ex_params, $ex_buttons) = @_;

  my $fields = [
    { key => 'FIO', lang => $lang{FIO} },
    { key => 'PHONE', lang => $lang{PHONE} },
    { key => 'EMAIL', lang => 'E-mail' },
    {
      key   => 'BUILD_ID',
      lang  => $lang{ADDRESS},
      label => sub {
        my $build_id = shift;

        use Address;
        my $Address = Address->new($db, $admin, \%conf);
        $Address->address_info($build_id);
        my $full_address = join ', ', grep {$_ && length $_ > 0}
          $Address->{ADDRESS_DISTRICT}, $Address->{ADDRESS_STREET}, $Address->{ADDRESS_BUILD}, $lead->{ADDRESS_FLAT};

        my $span = $html->element('span', $lang{ADDRESS}, { class => 'text-muted' });
        my $h6 = $html->element('h6', $full_address, { class => 'font-weight-normal' });
        return $span . $h6;
      },
      input => sub {
        my $build_id = shift;

        return form_address_select2({
          LOCATION_ID  => $build_id || 0,
          SHOW_BUTTONS => 1,
          ADDRESS_FLAT => $lead->{ADDRESS_FLAT}
        }),
      }
    },
    {
      key   => 'SOURCE',
      lang  => $lang{SOURCE},
      label => sub {
        my $source_id = shift;

        my $source_info = $Crm->leads_source_info({ ID => $source_id, COLS_NAME => 1 });
        return _crm_base_label(_translate($source_info->{NAME}), $lang{SOURCE});
      },
      input => sub {
        my $source_id = shift;

        my $span = $html->element('span', $lang{SOURCE}, { class => 'text-muted' });
        my $source_sel = $html->form_select('SOURCE', {
          SELECTED    => $source_id,
          SEL_LIST    => translate_list($Crm->leads_source_list({ NAME => '_SHOW', COLS_NAME => 1 })),
          SEL_KEY     => 'id',
          SEL_VALUE   => 'name',
          NO_ID       => 1,
          SEL_OPTIONS => { "" => "" },
        });

        return $html->element('div', $span . $source_sel, { class => 'form-group mb-2' });
      }
    },
    {
      key   => 'RESPONSIBLE',
      lang  => $lang{RESPONSIBLE},
      label => sub {
        my $aid = shift;
        
        my $admin_info = $admin->list({ AID => $aid, ADMIN_NAME => '_SHOW', ID => '_SHOW', COLS_NAME => 1 })->[0];
        return _crm_base_label($admin_info->{admin_name} || $admin_info->{id}, $lang{RESPONSIBLE});
      },
      input => sub {
        my $aid = shift;

        my $span = $html->element('span', $lang{RESPONSIBLE}, { class => 'text-muted' });
        my $responsible_select = sel_admins({ SELECTED => $aid, NAME => 'RESPONSIBLE' });

        return $html->element('div', $span . $responsible_select, { class => 'form-group mb-2' });
      }
    },
    {
      key   => 'PRIORITY',
      lang  => $lang{PRIORITY},
      label => sub {
        my $priority_id = shift;
        return '' if !defined($priority_id);

        return _crm_base_label(_translate($PRIORITY[$priority_id]), $lang{PRIORITY});
      },
      input => sub {
        my $priority_id = shift;

        my $span = $html->element('span', $lang{PRIORITY}, { class => 'text-muted' });
        my $priority_select = $html->form_select('PRIORITY', {
          SELECTED     => $priority_id,
          SEL_ARRAY    => \@PRIORITY,
          NO_ID        => 1,
          SEL_OPTIONS  => { "" => "" },
          ARRAY_NUM_ID => 1
        });

        return $html->element('div', $span . $priority_select, { class => 'form-group mb-2' });
      }
    },
    {
      key   => 'COMPETITOR_ID',
      lang  => $lang{COMPETITOR},
      label => sub {
        my $competitor_id = shift;

        my $competitor_info = $Crm->crm_competitor_info({ ID => $competitor_id });
        return _crm_base_label($competitor_info->{NAME}, $lang{COMPETITOR}) .
          _crm_base_label($assessments[$lead->{ASSESSMENT} ? $lead->{ASSESSMENT} - 1 : 0 ]{name}, $lang{ASSESSMENT});
      },
      input => sub {
        my $competitor_id = shift;

        my $span = $html->element('span', $lang{COMPETITOR}, { class => 'text-muted' });
        my $competitors_select = $html->form_select('COMPETITOR_ID', {
          SELECTED       => $competitor_id || 0,
          SEL_LIST       => $Crm->crm_competitor_list({ NAME => '_SHOW', COLS_NAME => 1 }),
          SEL_KEY        => 'id',
          SEL_VALUE      => 'name',
          NO_ID          => 1,
          MAIN_MENU      => get_function_index('crm_competitors'),
          MAIN_MENU_ARGV => "chg=" . ($competitor_id || ''),
          EX_PARAMS      => 'onchange="loadTps()"',
          SEL_OPTIONS    => { '' => '' }
        });

        my $tp_span = $html->element('span', $lang{TARIF_PLAN}, { class => 'text-muted' });
        my $tp_sel = $html->form_select('TP_ID', {
          SELECTED  => $lead->{TP_ID} || 0,
          SEL_LIST  => $Crm->crm_competitors_tps_list({
            NAME          => '_SHOW',
            COMPETITOR_ID => $competitor_id || '_SHOW',
            COLS_NAME     => 1
          }),
          SEL_KEY   => 'id',
          SEL_VALUE => 'name',
          NO_ID     => 1,
        });

        my $assessment_span = $html->element('span', $lang{ASSESSMENT}, { class => 'text-muted' });
        my $assessment_sel = $html->form_select('ASSESSMENT', {
          SELECTED    => $lead->{ASSESSMENT} || q{},
          SEL_LIST    => \@assessments,
          NO_ID       => 1,
          SEL_KEY     => 'id',
          SEL_VALUE   => 'name',
          SEL_OPTIONS => { '' => '' },
        });

        return $html->element('div', $span . $competitors_select, { class => 'form-group mb-2' }) .
          $html->element('div', $tp_span . $tp_sel, { class => 'form-group mb-2 hidden', id => 'tps-row' }) .
          $html->element('div', $assessment_span . $assessment_sel, { class => 'form-group mb-2 hidden', id => 'assessment-row' });
      }
    },
    {
      key   => 'COMMENTS',
      lang  => $lang{COMMENTS},
      input => sub {
        my $value = shift;

        my $span = $html->element('span', $lang{COMMENTS}, { class => 'text-muted' });
        my $input = $html->element('textarea', $value, { rows => 5, class => 'form-control', name => 'COMMENTS' });

        return $html->element('div', $span . $input, { class => 'form-group mb-2' });
      }
    },
    {
      key   => 'DATE',
      lang  => $lang{CRM_REGISTRATION_DATE},
      input => sub {
        my $reg_date = shift;

        my $span = $html->element('span', $lang{CRM_REGISTRATION_DATE}, { class => 'text-muted' });
        my $datepicker = $html->form_datepicker('DATE', $reg_date, { RETURN_INPUT => 1 });

        return $html->element('div', $span . $html->element('div', $datepicker, { class => 'input-group' }),
          { class => 'form-group mb-2' });
      }
    },
    {
      key   => 'HOLDUP_DATE',
      lang  => $lang{HOLDUP_TO},
      input => sub {
        my $holdup_date = shift;

        my $span = $html->element('span', $lang{HOLDUP_TO}, { class => 'text-muted' });
        my $datepicker = $html->form_datepicker('HOLDUP_DATE', $holdup_date, { RETURN_INPUT => 1 });

        return $html->element('div', $span . $html->element('div', $datepicker, { class => 'input-group' }),
          { class => 'form-group mb-2' });
      }
    },
    {
      key   => 'UID',
      lang  => $lang{USER},
      label => sub {
        my $uid = shift;
        
        my $user_btn = $lang{NOT_EXIST};

        if ($uid) {
          my $user_info = $users->info($uid);
          
          $user_btn = $html->button($user_info->{LOGIN}, "get_index=form_users&header=1&full=1&UID=$uid");
          $user_btn .= $html->button("", "index=$index&delete_uid=1&LEAD_ID=$lead->{LEAD_ID}", {
            ICON  => 'fa fa-trash',
            class => 'ml-1 text-danger',
          });
        }

        return _crm_base_label($user_btn, $lang{USER});
      },
      input => sub {
        my $uid = shift;

        require Control::Users_mng;
        my $user_search = user_modal_search();
        my $user_info = $uid ? $users->info($uid) : {};

        my $span = $html->element('span', $lang{USER}, { class => 'text-muted' });
        my $user_btn = $html->tpl_show(_include('crm_lead_add_user', 'Crm'), {
          USER_SEARCH     => $user_search,
          USER_LOGIN      => $user_info->{LOGIN},
          LEAD_ID         => $lead->{LEAD_ID},
          INDEX           => get_function_index('crm_lead_info'),
          DELETE_USER_BTN => $uid ? $html->button('', "index=$index&delete_uid=1&LEAD_ID=$lead->{LEAD_ID}", {
            ICON  => 'fa fa-trash text-danger',
            class => 'btn btn-default',
          }) : ''
        }, { OUTPUT2RETURN => 1 });

        return $span . $user_btn;
      }
    },
  ];

  @{$fields} = (@{$fields}, @{crm_lead_info_fields()});

  _crm_form_section_fields($fields, $lead, $ex_params, $ex_buttons);
}

#**********************************************************
=head2 crm_deal_fields ($deal, $ex_params, $ex_buttons)

=cut
#**********************************************************
sub crm_deal_fields {
  my ($deal, $ex_params, $ex_buttons) = @_;

  my $fields = [
    { key => 'NAME', lang => $lang{NAME} },
    { key => 'UID', lang => $lang{LOGIN} },
    {
      key => 'PRODUCTS',
      lang => $lang{CRM_PRODUCTS},
      label => sub {
        my $products = shift;

        my $total_count = 0;
        my $total_sum = 0;
        my $products_info = $Crm->crm_deal_products_list({
          ID        => $products,
          NAME      => '_SHOW',
          COUNT     => '_SHOW',
          SUM       => '_SHOW',
          FEES_NAME => '_SHOW',
          COLS_NAME => 1
        });

        my $money_main_unit = $conf{MONEY_UNIT_NAMES} ? (split(/;/, $conf{MONEY_UNIT_NAMES}))[0] : '';
        my $products_block = '';
        foreach my $product (@{$products_info}) {
          $total_sum += $product->{sum};
          $total_count += $product->{count};

          my $product_name = $html->element('div', $product->{name}, { class => 'text-bold' });
          $product->{fees_name} = _translate($product->{fees_name});
          $product_name .= $html->element('span', "$product->{fees_name} $product->{sum}$money_main_unit - $product->{count}",
            { class => 'text-muted small' });

          $products_block .= $html->element('div', $product_name, { class => 'm-3 d-grid' });
        }
        my $label = $html->element('div', "$lang{COUNT}: $total_count") .
          $html->element('div', "$lang{SUM}: $total_sum");
        $label .= $html->button($lang{CRM_CHANGE}, "get_index=crm_users&full=1&chg=$deal->{ID}", { class => 'btn-tool' }) if $deal->{ID};
        $products_block = $html->element('div', $products_block, { class => 'crm-product-container' });

        return _crm_base_label($label . $products_block, $lang{CRM_PRODUCTS});
      },
      input => sub {
        return '';
      }
    },
    {
      key   => 'BEGIN_DATE',
      lang  => $lang{CRM_BEGIN_DATE},
      input => sub {
        my $reg_date = shift;

        my $span = $html->element('span', $lang{CRM_BEGIN_DATE}, { class => 'text-muted' });
        my $datepicker = $html->form_datepicker('BEGIN_DATE', $reg_date, { RETURN_INPUT => 1 });

        return $html->element('div', $span . $html->element('div', $datepicker, { class => 'input-group' }),
          { class => 'form-group mb-2' });
      }
    },
    {
      key   => 'CLOSE_DATE',
      lang  => $lang{CRM_CLOSE_DATE},
      input => sub {
        my $reg_date = shift;

        my $span = $html->element('span', $lang{CRM_CLOSE_DATE}, { class => 'text-muted' });
        my $datepicker = $html->form_datepicker('CLOSE_DATE', $reg_date, { RETURN_INPUT => 1 });

        return $html->element('div', $span . $html->element('div', $datepicker, { class => 'input-group' }),
          { class => 'form-group mb-2' });
      }
    },
    {
      key   => 'COMMENTS',
      lang  => $lang{COMMENTS},
      input => sub {
        my $value = shift;

        my $span = $html->element('span', $lang{COMMENTS}, { class => 'text-muted' });
        my $input = $html->element('textarea', $value, { rows => 5, class => 'form-control', name => 'COMMENTS' });

        return $html->element('div', $span . $input, { class => 'form-group mb-2' });
      }
    },
  ];

  _crm_form_section_fields($fields, $deal, $ex_params, $ex_buttons);
}

#*******************************************************************
=head2 _crm_form_section_fields($fields, $info, $ex_params, $ex_buttons)

=cut
#*******************************************************************
sub _crm_form_section_fields {
  my ($fields, $info, $ex_params, $ex_buttons) = @_;

  my $result = { FIELDS => json_former($fields), SECTIONS => '' };
  my $section_checked_fields = {};
  my $aid = $admin->{AID};

  my $sections = $Crm->crm_sections_list({ %{$ex_params}, TITLE => '_SHOW', COLS_NAME => 1 });
  foreach my $section (@{$sections}) {
    $Crm->{FIELDS} = '';
    $Crm->crm_section_fields_info({ AID => $aid, SECTION_ID => $section->{id} });
    @{$section_checked_fields->{$section->{id}}} = $Crm->{FIELDS} ? split(',\s?', $Crm->{FIELDS}) : ();

    my $template_info = { LABEL => '', INPUT => '', TITLE => _translate($section->{title}), SECTION_ID => $section->{id} };
    %{$template_info} = (%{$template_info}, %{$ex_params});

    if ($ex_buttons) {
      %{$template_info} = (%{$template_info}, %{$ex_buttons});
      $ex_buttons = undef;
    }

    foreach my $field (@{$fields}) {
      my $key = $field->{key};
      next if !$key || !in_array($key, $section_checked_fields->{$section->{id}});

      my $value = $info->{$key};
      my $key_lang = $field->{lang};
      # next if !defined $value;

      $template_info->{'LABEL'} .= $field->{label} ? $field->{label}->($value, $key_lang) :
        _crm_base_label($value, $key_lang);
      $template_info->{'INPUT'} .= $field->{input} ? $field->{input}->($value, $key_lang) :
        _crm_base_input($value, $key, $key_lang);
    }
    $result->{SECTIONS} .= $html->tpl_show(_include('crm_section', 'Crm'), $template_info, { OUTPUT2RETURN => 1 });
  }

  $result->{CHECKED_FIELDS} = json_former($section_checked_fields);
  return $result;
}

#**********************************************************
=head2 crm_lead_info_field_tpl($attr) - Info fields

  Arguments:
    COMPANY                - Company info fields
    VALUES                 - Info field value hash_ref
    RETURN_AS_ARRAY        - returns hash_ref for name => $input (for custom design logic)
    CALLED_FROM_CLIENT_UI  - apply client_permission view/edit logic

  Returns:
    Return formed HTML

=cut
#**********************************************************
sub crm_lead_info_fields {
  my ($attr) = @_;

  my $fields_list = $Crm->fields_list({ SORT => 'priority' });
  my @field_result = ();

  foreach my $field (@{$fields_list}) {
    next if !defined($field->{TYPE}) || !$fields_types[$field->{TYPE}];

    my $function_name = 'crm_info_field_' . $fields_types[$field->{TYPE}];
    next if !defined(&$function_name);

    my $label_function = 'crm_info_field_' . $fields_types[$field->{TYPE}] . '_label';
    my $disabled_ex_params = ($attr->{READ_ONLY} || ($attr->{CALLED_FROM_CLIENT_UI}))
      ? ' disabled="disabled" readonly="readonly"' : '';
    $field->{SQL_FIELD} = uc $field->{SQL_FIELD} if $field->{SQL_FIELD};

    push @field_result, {
      key   => $field->{SQL_FIELD},
      lang  => $field->{NAME},
      input => sub {
        my $value = shift;

        my $span = $html->element('span', $field->{NAME}, { class => 'text-muted' });
        my $input = &{\&{$function_name}}($field, {
          DISABLED => $disabled_ex_params || '',
          VALUE    => $value
        });

        return $html->element('div', $span . $input, { class => 'form-group mb-2' });
      },
      label => !defined(&$label_function) ? undef : sub {
        my $value = shift;
        return _crm_base_label(&{\&{$label_function}}($field, { VALUE => $value }), $field->{NAME});
      }
    };
  }

  return \@field_result;
}

#**********************************************************
=head2 _crm_base_label($value, $key_lang)

=cut
#**********************************************************
sub _crm_base_label {
  my $value = shift;
  my $key_lang = shift;

  my $span = $html->element('span', $key_lang, { class => 'text-muted'});
  my $h6 = $value ? $html->element('h6', $value, { class => 'font-weight-normal' }) : _crm_empty_field();

  return $span . $h6;
}

#**********************************************************
=head2 _crm_base_input($value, $key, $key_lang)

=cut
#**********************************************************
sub _crm_base_input {
  my $value = shift;
  my $key = shift;
  my $key_lang = shift;

  $value = AXbills::Base::convert($value, { text2html => 1 });
  my $span = $html->element('span', $key_lang, { class => 'text-muted'});
  my $input = $html->element('input', '', { class => 'form-control', type => 'text', name => $key, value => $value });

  return $html->element('div', $span . $input, { class => 'form-group mb-2' });
}

#**********************************************************
=head2 _crm_empty_field()

=cut
#**********************************************************
sub _crm_empty_field {
  return $html->element('h6', $lang{CRM_NOT_SPECIFIED}, { class => 'font-weight-normal text-muted' });
}
1;