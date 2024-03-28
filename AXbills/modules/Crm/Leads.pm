=head1 NAME

 Lead functions

=cut

use strict;
use warnings FATAL => 'all';
use Tags;
use Users;
use Crm::db::Crm;
use AXbills::Sender::Core;
use AXbills::Base qw/in_array mk_unique_value json_former/;

our (
  @PRIORITY,
  %lang,
  $admin,
  %permissions,
  $db,
  %conf,
);

our AXbills::HTML $html;
my $Crm = Crm->new($db, $admin, \%conf);
my $Tags = Tags->new($db, $admin, \%conf);

require Address;
Address->import();
my $Address = Address->new($db, $admin, \%conf);

#**********************************************************
=head2 crm_lead_search()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub crm_lead_search {

  # Add new lead and redirect to profile page
  if ($FORM{add}) {
    $Crm->crm_lead_add({ %FORM });
    _error_show($Crm);

    $html->message('success', $lang{ADDED}, $lang{LEAD_ADDED_MESSAGE} . $html->button($lang{GO},
      "index=" . get_function_index('crm_lead_info') . "&LEAD_ID=$Crm->{INSERT_ID}"));

    return 1;
  }

  my $submit_button_name = $lang{SEARCH};
  my $submit_button_action = 'search';
  my $id_disabled = '';
  my $id_hidden = '';
  my $source_list = translate_list($Crm->leads_source_list({ NAME => '_SHOW', COLS_NAME => 1 }));

  my $lead_source_select = $html->form_select('SOURCE', {
    SELECTED    => $FORM{SOURCE} || q{},
    SEL_LIST    => $source_list,
    SEL_KEY     => 'id',
    SEL_VALUE   => 'name',
    NO_ID       => 1,
    SEL_OPTIONS => { '' => '' },
    MAIN_MENU   => get_function_index('crm_source_types'),
  });

  my $responsible_admin = sel_admins({ NAME => 'RESPONSIBLE' });

  my $date_range = $html->form_daterangepicker({
    NAME         => 'PERIOD',
    EX_PARAMS    => 'disabled="disabled"',
    RETURN_INPUT => 1
  });

  my $holdup_date_range = $html->form_daterangepicker({
    NAME         => 'HOLDUP_DATE_RANGE',
    EX_PARAMS    => 'disabled="disabled"',
    RETURN_INPUT => 1
  });

  my $priority_select = $html->form_select('PRIORITY', {
    SELECTED     => $FORM{PRIORITY} || q{},
    SEL_ARRAY    => \@PRIORITY,
    NO_ID        => 1,
    SEL_OPTIONS  => { "" => "" },
    ARRAY_NUM_ID => 1
  });

  my $current_step_select = _progress_bar_step_sel();

  my $tpl = $html->tpl_show(_include('crm_lead_search', 'Crm'), {
    SUBMIT_BTN_NAME     => $submit_button_name,
    SUBMIT_BTN_ACTION   => $submit_button_action,
    DISABLE_ID          => $id_disabled,
    HIDE_ID             => $id_hidden,
    LEAD_SOURCE         => $lead_source_select,
    RESPONSIBLE_ADMIN   => $responsible_admin,
    DATE                => $date_range,
    HOLDUP_DATE         => $holdup_date_range,
    CURRENT_STEP_SELECT => $current_step_select,
    PRIORITY_SEL        => $priority_select,
    COMPETITORS_SEL   => _crm_competitors_select({ %FORM }, {
      SEL_OPTIONS => { '' => '' },
      EX_PARAMS   => 'onchange="loadTps()"',
    }),
    INDEX               => get_function_index('crm_leads'),
    %FORM
  }, { OUTPUT2RETURN => 1 });

  form_search({ TPL => $tpl });

  return 1;
}

#**********************************************************
=head2 crm_lead_search_old() - search leads

  Arguments:
    $attr -

  Returns:

  Examples:
=cut
#**********************************************************
sub crm_lead_search_old {

  my $submit_button_name = $lang{SEARCH};
  my $submit_button_action = 'search';
  my $id_disabled = '';
  my $id_hidden = '';
  my $source_list = translate_list($Crm->leads_source_list({
    NAME      => '_SHOW',
    COLS_NAME => 1
  }));

  my $lead_source_select = $html->form_select('SOURCE', {
    SELECTED    => $FORM{SOURCE} || q{},
    SEL_LIST    => $source_list,
    SEL_KEY     => 'id',
    SEL_VALUE   => 'name',
    NO_ID       => 1,
    SEL_OPTIONS => { "" => "" },
    MAIN_MENU   => get_function_index('crm_source_types')
  });

  if ($FORM{search}) {
    my $leads_list = $Crm->crm_lead_list({
      FIO         => $FORM{FIO} || '_SHOW',
      ID          => $FORM{LEAD_ID} || '_SHOW',
      PHONE       => $FORM{PHONE} || '_SHOW',
      EMAIL       => $FORM{EMAIL} || '_SHOW',
      COMPANY     => $FORM{COMPANY} || '_SHOW',
      COMMENTS    => $FORM{COMMENTS} || '_SHOW',
      SOURCE      => $FORM{SOURCE} || '_SHOW',
      DATE        => $FORM{DATE} || '_SHOW',
      RESPONSIBLE => $FORM{RESPONSIBLE} || '_SHOW',
      ADDRESS     => $FORM{ADDRESS} || '_SHOW',
      #        CITY        => $FORM{CITY} || '_SHOW',
      BUILD       => $FORM{ADDRESS_BUILD} || '_SHOW',
      FLAT        => $FORM{ADDRESS_FLAT} || '_SHOW',
      COLS_NAME   => 1,
      COLS_UPPER  => 1
    });

    _error_show($Crm);

    # если нашло одного лида, кидает на страницу информации
    if ($leads_list && ref $leads_list eq 'ARRAY' && scalar @{$leads_list} == 1) {
      $html->message("info", $lang{SUCCESS}, "1 $lang{LEAD}");
      # crm_lead_info($leads_list->[0]->{ID});
      $html->redirect('?index=' . get_function_index('crm_lead_info') . "&LEAD_ID=$leads_list->[0]->{ID}",
        { WAIT => 1 });
      return 1;
    }

    # если нашло больше чем одного лида, показывает панели лидов с ссылкой на их профиль
    elsif ($leads_list && ref $leads_list eq 'ARRAY' && scalar @{$leads_list} > 1) {
      crm_lead_panels(@$leads_list);
      return 1;
    }

    # если не нашло ни одного лида, то дает возможность добавить нового с параметрами поискаы
    $html->message('info', "$lang{LEAD_NOT_FOUND}", "$lang{INPUT_DATA_TO_ADD_LEAD}");

    $submit_button_name = "$lang{ADD}";
    $submit_button_action = 'add';
    $id_disabled = 'disabled';
    $id_hidden = 'hidden';
  }

  # добавляет нового лида и перенаправляет на страницу профиля
  if ($FORM{add}) {
    $Crm->crm_lead_add({ %FORM });

    _error_show($Crm);

    $html->message('success', $lang{ADDED}, $lang{LEAD_ADDED_MESSAGE} . $html->button("тут",
      "index=" . get_function_index('crm_lead_info') . "&LEAD_ID=$Crm->{INSERT_ID}"));

    return 1;
  }

  my $responsible_admin = sel_admins({ NAME => 'RESPONSIBLE' });

  $html->tpl_show(_include('crm_lead_search', 'Crm'), {
    SUBMIT_BTN_NAME   => $submit_button_name,
    SUBMIT_BTN_ACTION => $submit_button_action,
    DISABLE_ID        => $id_disabled,
    HIDE_ID           => $id_hidden,
    LEAD_SOURCE       => $lead_source_select,
    RESPONSIBLE_ADMIN => $responsible_admin,
    %FORM
  });

  return 1;
}

#**********************************************************
=head2 crm_leads() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub crm_leads {

  if ($FORM{ID} && $FORM{send} && $FORM{MSGS}) {
    my @ATTACHMENTS = ();
    for (my $i = 0; $i <= $FORM{FILE_UPLOAD_UPLOADS_COUNT}; $i++) {
      my $input_name = 'FILE_UPLOAD' . (($i > 0) ? "_$i" : '');

      next if !$FORM{ $input_name }->{filename};

      push @ATTACHMENTS, {
        FILENAME     => $FORM{ $input_name }->{filename},
        CONTENT_TYPE => $FORM{ $input_name }->{'Content-Type'},
        FILESIZE     => $FORM{ $input_name }->{Size},
        CONTENT      => $FORM{ $input_name }->{Contents},
      };
    }

    _crm_send_lead_mess({ %FORM, ATTACHMENTS => \@ATTACHMENTS });
  }
  elsif (!$FORM{ID} && $FORM{send} && $FORM{MSGS}) {
    $html->message('warn', $lang{ERROR}, $lang{NO_CLICK_USER});
  }

  return 0 if (!$permissions{0}{1});

  my $client_info = $FORM{UID} ? crm_client_to_lead() : {};
  $client_info = {} if !$client_info || ref $client_info ne 'Users';

  if ($FORM{add_form}) {
    my $submit_button_name = $lang{ADD};
    my $submit_button_action = 'add';
    my $id_disabled = 'disabled';
    my $id_hidden = 'hidden';

    my $source_list = translate_list($Crm->leads_source_list({ NAME => '_SHOW', COLS_NAME => 1 }));

    my $lead_source_select = $html->form_select('SOURCE', {
      SELECTED    => $FORM{SOURCE} || q{},
      SEL_LIST    => $source_list,
      SEL_KEY     => 'id',
      SEL_VALUE   => 'name',
      NO_ID       => 1,
      SEL_OPTIONS => { '' => '' },
      MAIN_MENU   => get_function_index('crm_source_types'),
    });

    my $priority_select = $html->form_select('PRIORITY', {
      SELECTED     => $FORM{PRIORITY} || q{},
      SEL_ARRAY    => \@PRIORITY,
      NO_ID        => 1,
      SEL_OPTIONS  => { '' => '' },
      ARRAY_NUM_ID => 1,
    });

    my $responsible_admin = sel_admins({ NAME => 'RESPONSIBLE', SELECTED => $admin->{AID} });

    $FORM{ADDRESS_FORM} = $conf{CRM_OLD_ADDRESS} ?
      $html->tpl_show(_include('crm_old_address', 'Crm'), undef, { OUTPUT2RETURN => 1 }) :
      form_address_select2({
        LOCATION_ID  => $client_info->{LOCATION_ID} || 0,
        DISTRICT_ID  => 0,
        STREET_ID    => 0,
        ADDRESS_FLAT => $client_info->{ADDRESS_FLAT} || '',
        SHOW_BUTTONS => 1
      });

    $FORM{ASSESSMENTS_SEL} = crm_assessments_select(\%FORM);

    $html->tpl_show(_include('crm_lead_search', 'Crm'), {
      %FORM,
      SUBMIT_BTN_NAME   => $submit_button_name,
      SUBMIT_BTN_ACTION => $submit_button_action,
      DISABLE_ID        => $id_disabled,
      HIDE_ID           => $id_hidden,
      LEAD_SOURCE       => $lead_source_select,
      RESPONSIBLE_ADMIN => $responsible_admin,
      DATE              => $html->form_datepicker('DATE', $DATE, { RETURN_INPUT => 1 }),
      HOLDUP_DATE       => $html->form_datepicker('HOLDUP_DATE', '0000-00-00', { RETURN_INPUT => 1 }),
      PRIORITY_SEL      => $priority_select,
      INDEX             => get_function_index('crm_leads'),
      COMPETITORS_SEL   => _crm_competitors_select({ %FORM }, {
        SEL_OPTIONS => { '' => '' },
        EX_PARAMS   => 'onchange="loadTps()"',
      }),
      INFO_FIELDS       => crm_lead_info_field_tpl($client_info),
      %{$client_info}
    });
  }
  elsif ($FORM{chg}) {
    my $lead_info = $Crm->crm_lead_info({ ID => $FORM{chg} });

    my $submit_button_name = $lang{CHANGE};
    my $submit_button_action = 'change';
    my $id_disabled = 'disabled';
    my $id_hidden = 'hidden';

    my $priority_select = $html->form_select('PRIORITY', {
      SELECTED     => (defined $lead_info->{PRIORITY}) ? $lead_info->{PRIORITY} : ($FORM{PRIORITY} || q{}),
      SEL_ARRAY    => \@PRIORITY,
      ARRAY_NUM_ID => 1,
      NO_ID        => 1,
      SEL_OPTIONS  => { '' => '' },
    });

    my $source_list = translate_list($Crm->leads_source_list({ NAME => '_SHOW', COLS_NAME => 1 }));

    my $lead_source_select = $html->form_select('SOURCE', {
      SELECTED    => $FORM{SOURCE} || $lead_info->{SOURCE},
      SEL_LIST    => $source_list,
      SEL_KEY     => 'id',
      SEL_VALUE   => 'name',
      NO_ID       => 1,
      SEL_OPTIONS => { '' => '' },
    });

    my $responsible_admin = sel_admins({
      SELECTED => $FORM{RESPONSIBLE} || $lead_info->{RESPONSIBLE},
      NAME     => 'RESPONSIBLE'
    });

    $lead_info->{ADDRESS_FORM} = $conf{CRM_OLD_ADDRESS} ? $html->tpl_show(_include('crm_old_address', 'Crm'), $lead_info, { OUTPUT2RETURN => 1 }) :
      form_address_select2({ LOCATION_ID => $lead_info->{BUILD_ID} || 0, SHOW_BUTTONS => 1, %{$lead_info} });

    $lead_info->{ASSESSMENTS_SEL} = crm_assessments_select($lead_info);

    $html->tpl_show(_include('crm_lead_search', 'Crm'), {
      SUBMIT_BTN_NAME   => $submit_button_name,
      SUBMIT_BTN_ACTION => $submit_button_action,
      DISABLE_ID        => $id_disabled,
      HIDE_ID           => $id_hidden,
      LEAD_SOURCE       => $lead_source_select,
      RESPONSIBLE_ADMIN => $responsible_admin,
      PRIORITY_SEL      => $priority_select,
      INDEX             => get_function_index('crm_leads'),
      %{$lead_info},
      DATE              => $html->form_datepicker('DATE', $lead_info->{DATE}, { RETURN_INPUT => 1 }),
      HOLDUP_DATE       => $html->form_datepicker('HOLDUP_DATE', $lead_info->{HOLDUP_DATE}, { RETURN_INPUT => 1 }),
      COMPETITORS_SEL   => _crm_competitors_select({ COMPETITOR_ID => $lead_info->{COMPETITOR_ID} }, {
        SEL_OPTIONS => { '' => '' },
        EX_PARAMS   => 'onchange="loadTps()"',
      }),
      TPS_SEL           => crm_competitor_tps_select({
        COMPETITOR_ID => $lead_info->{COMPETITOR_ID},
        TP_ID         => $lead_info->{TP_ID},
        RETURN_SELECT => 1
      }),
      TP_ID             => $lead_info->{TP_ID},
      COMPETITOR_ID     => $lead_info->{COMPETITOR_ID},
      INFO_FIELDS       => crm_lead_info_field_tpl({ %$lead_info, REGISTRATION => undef })
    });

    return 1 if ($FORM{TEMPLATE_ONLY});
  }
  elsif ($FORM{add}) {
    $Crm->crm_lead_add({ %FORM, DOMAIN_ID => ($admin->{DOMAIN_ID} || 0), CURRENT_STEP => 1 });
    if (!_error_show($Crm)) {
      $html->message('info', $lang{ADDED});
      $html->redirect("?get_index=crm_lead_info&full=1&LEAD_ID=$Crm->{INSERT_ID}", { WAIT => 1 });
    }
  }
  elsif ($FORM{del} && $FORM{COMMENTS}) {
    $Crm->crm_lead_delete({ ID => $FORM{ID} });
    delete $FORM{COMMENTS};
    $html->message('info', $lang{DELETED}) if (!_error_show($Crm));
  }
  elsif ($FORM{change}) {
    $Crm->crm_lead_change({ %FORM });
    if ($FORM{RETURN_JSON}) {
      print 'error' if $Crm->{error};
      return 1;
    }

    $html->redirect("?get_index=crm_lead_info&full=1&LEAD_ID=$FORM{ID}");
  }
  elsif ($FORM{CRM_MULTISELECT} && $FORM{ID}) {
    my @leads = split(/,\s?/, $FORM{ID});
    
    foreach my $lead (@leads) {
      $FORM{TAG_IDS} = $FORM{TAGS} if defined $FORM{TAGS};

      $Crm->crm_lead_change({ %FORM, ID => $lead });
    }
  }
  elsif ($FORM{CRM_MULTIMERGE} && $FORM{ID}) {
    _crm_merge_leads();
  }

  return 1 if $FORM{MESSAGE_ONLY};

  $LIST_PARAMS{PAGE_ROWS} = 1000000000;
  $LIST_PARAMS{SKIP_DEL_CHECK} = 1;
  my AXbills::HTML $table;

  my $index = $FORM{index} || '';

  my @header_arr = (
    "$lang{ALL}:index=$index&ALL_LEADS=1&show_columns=" . ($FORM{show_columns} || ''),
    "$lang{POTENTIAL_LEADS}:index=$index&POTENTIAL=1&show_columns=" . ($FORM{show_columns} || ''),
    "$lang{CONVERT_LEADS}:index=$index&CONVERTED=1&show_columns=" . ($FORM{show_columns} || ''),
    "$lang{WATCHING}:index=$index&WATCHING=1&show_columns=" . ($FORM{show_columns} || ''),
    "$lang{DUBLICATE_LEADS}:index=$index&DUBLICATE=1&show_columns=" . ($FORM{show_columns} || ''),
  );

  my $header = $html->table_header(\@header_arr, { SHOW_ONLY => 4 });
  $header .= $html->button('', '', {
    NO_LINK_FORMER => 1,
    JAVASCRIPT     => 1,
    SKIP_HREF      => 1,
    class          => 'btn btn-default',
    ICON           => 'fa fa-users',
    ID             => 'CHECK_LEADS_BTN',
    ex_params      => "data-tooltip-position='top' data-tooltip='$lang{MATCH_USER}'",
  });

  if ($FORM{ALL_LEADS}) {
    $LIST_PARAMS{SKIP_HOLDUP} = 1;
  }
  elsif ($FORM{CONVERTED}) {
    $LIST_PARAMS{'CL_UID'} = '!0';
  }
  elsif ($FORM{POTENTIAL}) {
    $LIST_PARAMS{'CL_UID'} = '0';
  }
  elsif ($FORM{WATCHING}) {
    $LIST_PARAMS{'WATCHER'} = $admin->{AID};
  }
  elsif ($FORM{DUBLICATE}) {
    $LIST_PARAMS{'DUBLICATE'} = 1;
  }

  %LIST_PARAMS = %FORM if ($FORM{search});

  my %ext_titles = (
    lead_id           => '#',
    fio               => $lang{FIO},
    phone             => $lang{PHONE},
    company           => $lang{COMPANY},
    email             => 'E-Mail',
    date              => "$lang{DATE} $lang{REGISTRATION}",
    admin_name        => $lang{RESPOSIBLE},
    current_step_name => $lang{STEP},
    last_action       => "$lang{LAST} $lang{ACTION}",
    priority          => $lang{PRIORITY},
    user_login        => $lang{LOGIN},
    tag_ids           => $lang{TAGS},
    tp_name           => $lang{TARIF_PLAN},
    competitor_name   => $lang{COMPETITOR},
    assessment        => $lang{CRM_ASSESSMENT},
    uid               => 'UID',
    lead_address      => $lang{ADDRESS},
    holdup_date       => $lang{HOLDUP_TO},
    source            => $lang{SOURCE}
  );

  my $fields = $Crm->fields_list({ TP_INFO_FIELDS => 1 });
  my @search_fields = ();

  foreach my $field (@{$fields}) {
    $ext_titles{$field->{SQL_FIELD}} = $field->{NAME};
    push @search_fields, [ uc $field->{SQL_FIELD}, 'STR', "cct.$field->{SQL_FIELD}", 1 ];
  }

 $fields = $Crm->fields_list();

  foreach my $field (@{$fields}) {
    $ext_titles{$field->{SQL_FIELD}} = $field->{NAME};
    push @search_fields, [ uc $field->{SQL_FIELD}, 'STR', "cl.$field->{SQL_FIELD}", 1 ];
  }

  $LIST_PARAMS{SEARCH_COLUMNS} = \@search_fields;
  $LIST_PARAMS{HOLDUP_DATE} //= $FORM{HOLDUP_DATE_RANGE} if $FORM{HOLDUP_DATE_RANGE};

  ($table, undef) = result_former({
    INPUT_DATA      => $Crm,
    FUNCTION        => 'crm_lead_list',
    BASE_FIELDS     => 0,
    DEFAULT_FIELDS  => "LEAD_ID,FIO,PHONE,EMAIL,COMPANY,ADMIN_NAME,DATE,CURRENT_STEP_NAME,LAST_ACTION,PRIORITY,UID,USER_LOGIN,TAG_IDS,",
    HIDDEN_FIELDS   => 'STEP_COLOR,CURRENT_STEP,COMPETITOR_NAME,TP_NAME,ASSESSMENT,LEAD_ADDRESS,SOURCE,HOLDUP_DATE,WATCHER',
    MULTISELECT     => 'ID:lead_id:' . ($FORM{delivery} ? 'CRM_LEADS' : 'crm_lead_multiselect'),
    FUNCTION_FIELDS => ':del:id:&del=1',
    FUNCTION_INDEX  => $index,
    FILTER_COLS     => {
      current_step_name => '_crm_current_step_color::STEP_COLOR,',
      last_action       => '_crm_last_action::LEAD_ID',
      tag_ids           => '_crm_tags_name::TAG_IDS',
      assessment        => 'crm_assessment_stars::ASSESSMENT',
      source            => '_crm_translate_source::SOURCE',
    },
    FILTER_VALUES => {
      lead_id => sub {
        my $lead_id = shift;
        return $html->button($lead_id, "get_index=crm_lead_info&full=1&LEAD_ID=$lead_id");
      },
      fio => sub {
        my ($fio, $line) = @_;
        return '' if !$fio;
        return $html->button($fio, "get_index=crm_lead_info&full=1&LEAD_ID=$line->{lead_id}");
      }
    },
    SKIP_USER_TITLE => 1,
    EXT_TITLES      => \%ext_titles,
    SKIP_PAGES      => 1,
    TABLE           => {
      width       => '100%',
      caption     => $lang{LEADS},
      qs          => $pages_qs,
      MENU        => "$lang{ADD}:index=$index&add_form=1:add;$lang{DELIVERY}:delivery=1&index=$index:",
      DATA_TABLE  => { "order" => [ [ 1, "desc" ] ] },
      title_plain => 1,
      header      => $header,
      SELECT_ALL  => "CRM_LEADS:ID:$lang{SELECT_ALL}",
      ID          => 'CRM_LEAD_LIST',
      IMPORT      => 1
    },
    SELECT_VALUE    => {
      priority => {
        0 => "$PRIORITY[0]:text-default",
        1 => "$PRIORITY[1]:text-warning",
        2 => "$PRIORITY[2]:text-danger"
      }
    },
    MAKE_ROWS       => 1,
    SEARCH_FORMER   => 1,
    MODULE          => 'Crm'
  });

  if ($FORM{delivery}) {
    $html->tpl_show(_include('crm_send_mess', 'Crm'), {
      INDEX     => $index,
      TABLE     => ($table) ? $table->show() : q{},
      TYPE_SEND => _actions_sel()
    });

    return 1;
  }

  $html->tpl_show(_include('crm_check_leads', 'Crm'));
  _crm_multiselect_form($table);

  return 1;
}

#**********************************************************
=head2 _crm_merge_leads()

=cut
#**********************************************************
sub _crm_merge_leads {
  my @leads = split(/,\s?/, $FORM{ID});
  my $fields = $Crm->fields_list();
  my @search_fields = ();

  foreach my $field (@{$fields}) {
    push @search_fields, [ uc $field->{SQL_FIELD}, 'STR', "cl.$field->{SQL_FIELD}", 1 ];
  }

  my $leads = $Crm->crm_lead_list({
    LEAD_ID               => join(';', @leads),
    SEARCH_COLUMNS        => \@search_fields,
    SKIP_USERS_FIELDS_PRE => \@search_fields,
    SHOW_ALL_COLUMNS      => 1,
    COLS_NAME             => 1,
    COLS_UPPER            => 1,
    SORT                  => 'cl.current_step,cl.id'
  });
  return if $Crm->{TOTAL} < 2;
  
  my $main_lead = {};
  foreach my $lead (@{$leads}) {
    foreach my $key (keys %{$lead}) {
      $main_lead->{$key} ||= $lead->{$key};
    }
  }

  _crm_merge_dialogues($main_lead->{lead_id}, \@leads);

  foreach my $lead (@{$leads}) {
    next if $lead->{LEAD_ID} eq $main_lead->{LEAD_ID};

    $Crm->crm_lead_delete({ ID => $lead->{LEAD_ID} });
  }

  $Crm->crm_lead_change($main_lead);

  $html->message('success', $lang{SUCCESS}, "$lang{LEADS_ARE_UNITED}: " . $html->button($main_lead->{FIO},
    "get_index=crm_lead_info&header=2&full=1&LEAD_ID=$main_lead->{LEAD_ID}"));
}

#**********************************************************
=head2 _crm_merge_dialogues ($main_lead_id, \@leads)

=cut
#**********************************************************
sub _crm_merge_dialogues {
  my $main_lead_id = shift;
  my ($leads) = @_;

  my $source = '';
  my $aid = '';
  my $dialogue_id = '';
  my $last_message_date = '';
  my $dialogues = $Crm->crm_dialogues_list({
    LEAD_ID           => join(';', @{$leads}),
    LAST_MESSAGE_DATE => '_SHOW',
    SOURCE            => '_SHOW',
    AID               => '_SHOW',
    COLS_NAME         => 1
  });

  foreach my $dialogue (@{$dialogues}) {
    $dialogue_id = $dialogue->{id} if $dialogue->{lead_id} eq $main_lead_id;
    if ($dialogue->{last_message_date} && $dialogue->{last_message_date} gt $last_message_date) {
      $last_message_date = $dialogue->{last_message_date};
      $source = $dialogue->{source} if $dialogue->{source};
      $aid = $dialogue->{aid} if defined $dialogue->{aid};
    }
  }

  foreach my $dialogue (@{$dialogues}) {
    next if $dialogue->{id} eq $dialogue_id;

    $Crm->crm_dialogues_del({ ID => $dialogue->{id} });
    $Crm->crm_dialogue_messages_change_dialogue_id({ OLD_DIALOGUE_ID => $dialogue->{id}, NEW_DIALOGUE_ID => $dialogue_id });
  }

  $Crm->crm_dialogues_change({ ID => $dialogue_id, SOURCE => $source, AID => $aid });
}

#**********************************************************
=head2 crm_lead_info ($lead_id) -

  Arguments:
    ATTRIBUTES -
  Returns:

  Examples:

=cut
#**********************************************************
sub crm_lead_info {
  my ($lead_id) = @_;

  _crm_tags(\%FORM) if $FORM{SAVE_TAGS};

  if ($FORM{delete_uid}) {
    $Crm->crm_lead_change({ ID => $FORM{LEAD_ID}, UID => 0 });
    $html->message('info', $lang{SUCCESS}, $lang{DELETED}) if !_error_show($Crm);
  }

  $Crm->crm_section_fields(\%FORM) if $FORM{save_fields};

  if ($FORM{SAVE}) {
    $Crm->crm_lead_change({
      PHONE         => $FORM{phone_2},
      SOURCE        => $FORM{source_2},
      EMAIL         => $FORM{email_2},
      BUILD_ID      => (defined($FORM{address_2})) ? $FORM{BUILD_ID} : '',
      ADDRESS_FLAT  => (defined($FORM{address_2})) ? $FORM{ADDRESS_FLAT} : '',
      DATE          => $FORM{date_registration_2},
      COMPANY       => $FORM{company_2},
      ID            => $FORM{TO_LEAD_ID},
    });

    $html->message('success', "$lang{SUCCESS} $lang{IMPORT}");
  }

  if ($FORM{WATCH}) {
    if ($FORM{WATCH_DEL}){
      $Crm->crm_lead_watch_del({ LEAD_ID => $FORM{LEAD_ID}, AID => $admin->{AID} });
    } else {
      $Crm->crm_lead_watch_add({ %FORM });
    }
  }

  $lead_id = $FORM{LEAD_ID} if $FORM{LEAD_ID};

  if (defined $FORM{CUR_STEP}) {
    $Crm->crm_lead_change({ ID => $FORM{LEAD_ID}, CURRENT_STEP => $FORM{CUR_STEP} || '1' });
    return 1;
  }

  if ($FORM{add_uid}) {
    $Crm->crm_lead_change({ ID => $FORM{LEAD_ID}, UID => $FORM{add_uid} });

    if ($FORM{RETURN_JSON}) {
      print json_former({ error => $Crm->{errno} || 0 });
      return;
    }

    if (!_error_show($Crm)) {
      my $lead_button = $html->button("$lang{LEAD}", "index=" . get_function_index("crm_lead_info") . "&LEAD_ID=$FORM{LEAD_ID}");
      $html->message('info', "$lang{SUCCESS}", "$lang{GO2PAGE} $lead_button");
    }
  }

  if ($FORM{change}) {
    $Crm->crm_lead_change(\%FORM);
    $html->message('info', $lang{CHANGED}) if !_error_show($Crm);
  }

  require Control::Users_mng;
  my $user_search = user_modal_search();

  return 1 if ($FORM{user_search_form} && $FORM{user_search_form} == 1);

  $Crm->crm_action_add('', { ID => $lead_id, TYPE => 3 });
  my $lead_info = $Crm->crm_lead_info({ ID => $lead_id });

  my $convert_data_button = $html->button($lang{IMPORT}, "get_index=crm_lead_convert&header=2&FROM_LEAD_ID=$lead_id", {
    LOAD_TO_MODAL => 'raw',
    class         => 'btn btn-warning btn-block',
  });
  # my $add_user_button = $html->button("$lang{ADD} $lang{USER}", "qindex=" . get_function_index("crm_lead_info") . "&TO_LEAD_ID=$lead_id&header=2", {
  #   class         => 'btn btn-warning btn-block',
  #   LOAD_TO_MODAL => 1,
  # });
  my $convert_lead_to_client = $html->button($lang{ADD_USER}, 'index=' . get_function_index('form_wizard') . "&LEAD_ID=$lead_id", {
    ID    => 'lead_to_client',
    class => 'btn btn-success btn-block',
  });

  $Crm->crm_lead_watch_list({ LEAD_ID => $lead_id, AID => $admin->{AID} });

  my $watching_button = '';
  if ($Crm->{TOTAL} >= 1) {
    $watching_button = $html->button('', "index=$index&LEAD_ID=$lead_id&WATCH=1&WATCH_DEL=1", {
      class => 'btn btn-primary btn-sm fa fa-eye-slash',
    });
  }
  else {
    $watching_button = $html->button('', "index=$index&LEAD_ID=$lead_id&WATCH=1", {
      class => 'btn btn-primary btn-sm fa fa-eye',
    });
  }

  #TODO: add tags fields
  # my $lead_tags = q{};
  # my $tags_table = q{};
  # my $tags_button = q{none};
  # if (in_array('Tags', \@MODULES)) {
  #   $lead_tags = _crm_tags({ LEAD => $lead_id, SHOW_TAGS => 1 });
  #   $tags_table = _crm_tags({ LEAD => $lead_id, SHOW => 1 });
  #   $tags_button = q{inline};
  # }

  my $fields = crm_lead_fields($lead_info,
    {
      LEAD_ID      => $lead_info->{LEAD_ID},
      DEAL_SECTION => '0',
      CHANGE_EXTRA_INFO => $html->button($lang{ALL_DATA}, 'get_index=crm_leads&full=1&chg=' . ($FORM{LEAD_ID} || ''),
        { class => 'btn btn-tool mr-1' }),
    },
    {
      WATCHING_BUTTON     => $watching_button,
      CONVERT_LEAD_BUTTON => $convert_lead_to_client,
      CONVERT_DATA_BUTTON => $convert_data_button,
    });
  my $lead_profile_panel = $html->tpl_show(_include('crm_section_panel', 'Crm'), { %$lead_info,
    # TAGS                => $lead_tags,
    # TAGS_BUTTON         => $tags_button,
    CONVERT_LEAD_BUTTON => $convert_lead_to_client,
    LOG                 => crm_lead_recent_activity($lead_id),
    %{$fields},
  }, { OUTPUT2RETURN => 1 });

  $html->tpl_show(_include('crm_lead_info', 'Crm'), {
    LEAD_PROFILE_PANEL => $lead_profile_panel,
    PROGRESSBAR        => crm_progressbar_show($lead_info->{CURRENT_STEP}, {
      DEAL_STEP    => '0',
      LEAD_ID      => $FORM{LEAD_ID},
      OBJECT_VALUE => $FORM{LEAD_ID},
      OBJECT_TYPE  => 'leads',
      TASK_URL     => "LEAD_ID=" . ($FORM{LEAD_ID} || '')
    }),
    LEAD               => $lead_id
  });

  return 1;
}

#**********************************************************
=head2 crm_lead_panels() -

  Arguments:
    ATTRIBUTES -
  Returns:

  Examples:

=cut
#**********************************************************
sub crm_lead_panels {
  my (@leads) = @_;

  my $lead_profile_panels = '';

  foreach my $each_lead (@leads) {
    my $button_to_lead_info = $html->button($lang{INFO},
      "index=" . get_function_index('crm_lead_info') . "&LEAD_ID=$each_lead->{ID}",
      { class => 'btn btn-primary btn-block' });

    $lead_profile_panels .= $html->tpl_show(_include('crm_section_panel', 'Crm'),
      { %$each_lead, BUTTON_TO_LEAD_INFO => $button_to_lead_info }, { OUTPUT2RETURN => 1, });
  }

  print $lead_profile_panels;

  return 1;
}

#**********************************************************
=head2 crm_progressbar_steps() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub crm_progressbar_steps {

  my $btn_name = 'add';
  my $btn_value = $lang{ADD};
  my $step_info = {};

  if ($FORM{add}) {
    $Crm->crm_progressbar_step_add({ %FORM, DOMAIN_ID => ($admin->{DOMAIN_ID} || 0) });
  }
  elsif ($FORM{chg}) {
    $step_info = $Crm->crm_progressbar_step_info({ ID => $FORM{chg} });
    $btn_name = 'change';
    $btn_value = $lang{CHANGE};
  }
  elsif ($FORM{del}) {
    $Crm->crm_progressbar_step_delete({ ID => $FORM{del} });
  }
  elsif ($FORM{change}) {
    $Crm->crm_progressbar_step_change({ %FORM });
  }

  _error_show($Crm);

  $html->tpl_show(_include('crm_progressbar_step_add', 'Crm'), {
    BTN_NAME  => $btn_name,
    BTN_VALUE => $btn_value,
    %{$step_info}
  });

  $LIST_PARAMS{DEAL_STEP} = '0';
  result_former({
    INPUT_DATA      => $Crm,
    FUNCTION        => 'crm_progressbar_step_list',
    BASE_FIELDS     => 0,
    DEFAULT_FIELDS  => 'ID,STEP_NUMBER,NAME,COLOR,DESCRIPTION',
    HIDDEN_FIELDS   => 'DEAL_STEP',
    FUNCTION_FIELDS => 'change,del',
    FILTER_COLS     => { name => '_translate' },
    SKIP_USER_TITLE => 1,
    EXT_TITLES      => {
      id          => 'ID',
      step_number => $lang{STEP},
      name        => $lang{NAME},
      color       => $lang{COLOR},
      description => $lang{DESCRIBE},
    },
    TABLE           => {
      width   => '100%',
      caption => $lang{STEP},
      qs      => $pages_qs,
      ID      => 'CRM_PROGRESSBAR_STEPS',
    },
    MAKE_ROWS       => 1,
    SEARCH_FORMER   => 1,
    MODULE          => 'Crm',
    TOTAL           => 1,
  });

  return 1;
}

#**********************************************************
=head2 crm_deals_progressbar_steps()

=cut
#**********************************************************
sub crm_deals_progressbar_steps {

  my $btn_name = 'add';
  my $btn_value = $lang{ADD};
  my $step_info = {};

  if ($FORM{add}) {
    $Crm->crm_progressbar_step_add({ %FORM, DOMAIN_ID => ($admin->{DOMAIN_ID} || 0), DEAL_STEP => 1 });
  }
  elsif ($FORM{chg}) {
    $step_info = $Crm->crm_progressbar_step_info({ ID => $FORM{chg} });
    $btn_name = 'change';
    $btn_value = $lang{CHANGE};
  }
  elsif ($FORM{del}) {
    $Crm->crm_progressbar_step_delete({ ID => $FORM{del} });
  }
  elsif ($FORM{change}) {
    $Crm->crm_progressbar_step_change({ %FORM });
  }

  _error_show($Crm);

  $html->tpl_show(_include('crm_progressbar_step_add', 'Crm'), {
    BTN_NAME  => $btn_name,
    BTN_VALUE => $btn_value,
    %{$step_info}
  });

  $LIST_PARAMS{DEAL_STEP} = '!';
  result_former({
    INPUT_DATA      => $Crm,
    FUNCTION        => 'crm_progressbar_step_list',
    BASE_FIELDS     => 0,
    DEFAULT_FIELDS  => 'ID,STEP_NUMBER,NAME,COLOR,DESCRIPTION',
    HIDDEN_FIELDS   => 'DEAL_STEP',
    FUNCTION_FIELDS => 'change,del',
    FILTER_COLS     => { name => '_translate' },
    SKIP_USER_TITLE => 1,
    EXT_TITLES      => {
      id          => 'ID',
      step_number => $lang{STEP},
      name        => $lang{NAME},
      color       => $lang{COLOR},
      description => $lang{DESCRIBE},
    },
    TABLE           => {
      width   => '100%',
      caption => $lang{STEPS_FOR_DEALS},
      qs      => $pages_qs,
      ID      => 'CRM_PROGRESSBAR_STEPS',
    },
    MAKE_ROWS       => 1,
    SEARCH_FORMER   => 1,
    MODULE          => 'Crm',
    TOTAL           => 1,
  });

  return 1;
}

#**********************************************************
=head2 crm_source_types() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub crm_source_types {

  my $btn_name = 'add';
  my $btn_value = $lang{ADD};
  my %source_info = ();

  if ($FORM{add}) {
    $Crm->leads_source_add({ %FORM, DOMAIN_ID => ($admin->{DOMAIN_ID} || 0) });
  }
  elsif ($FORM{chg}) {
    %source_info = %{$Crm->leads_source_info({ ID => $FORM{chg} })};
    $btn_name = 'change';
    $btn_value = $lang{CHANGE};
  }
  elsif ($FORM{del}) {
    $Crm->leads_source_delete({ ID => $FORM{del} });
  }
  elsif ($FORM{change}) {
    $Crm->leads_source_change({ %FORM });
  }

  _error_show($Crm);

  $html->tpl_show(_include('crm_leads_sources', 'Crm'), {
    BTN_NAME  => $btn_name,
    BTN_VALUE => $btn_value,
    %source_info
  });

  result_former({
    INPUT_DATA      => $Crm,
    FUNCTION        => 'leads_source_list',
    BASE_FIELDS     => 0,
    DEFAULT_FIELDS  => "ID, NAME, COMMENTS",
    FUNCTION_FIELDS => 'change,del',
    SKIP_USER_TITLE => 1,
    FILTER_COLS     => {
      name => '_translate'
    },
    EXT_TITLES      => {
      'id'       => "ID",
      'name'     => $lang{NAME},
      'comments' => $lang{COMMENTS},
    },
    TABLE           => {
      width   => '100%',
      caption => $lang{SOURCE},
      qs      => $pages_qs,
      ID      => 'CRM_SOURCE_TYPES',
    },
    MAKE_ROWS       => 1,
    SEARCH_FORMER   => 1,
    MODULE          => 'Crm',
    TOTAL           => "TOTAL:$lang{TOTAL}",
  });

  return 1;
}

#**********************************************************
=head2 crm_report_leads() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub crm_reports_leads {

  my $lead_points = $Crm->crm_lead_points_list();

  my $date_range = $html->form_daterangepicker({
    NAME      => 'FROM_DATE/TO_DATE',
    FORM_NAME => 'report_panel',
    WITH_TIME => $FORM{TIME_FORM} || 0
  });

  my $source_list = translate_list($Crm->leads_source_list({
    NAME      => '_SHOW',
    COLS_NAME => 1
  }));

  my $source_select = $html->form_select('SOURCE_ID', {
    SELECTED    => $FORM{SOURCE_ID} || q{},
    SEL_LIST    => $source_list,
    SEL_KEY     => 'id',
    SEL_VALUE   => 'name',
    NO_ID       => 1,
    SEL_OPTIONS => { "" => "" },
    MAIN_MENU   => get_function_index('crm_source_types'),
  });

  $html->tpl_show(_include('crm_leads_reports', 'Crm'), {
    DATE_RANGE    => $date_range,
    SOURCE_SELECT => $source_select,
  });

  $LIST_PARAMS{SOURCE} = $FORM{SOURCE_ID} || '';
  $LIST_PARAMS{PERIOD} = ($FORM{FROM_DATE} || $DATE) . "/" . ($FORM{TO_DATE} || $DATE);

  result_former({
    INPUT_DATA      => $Crm,
    FUNCTION        => 'crm_lead_list',
    BASE_FIELDS     => 0,
    DEFAULT_FIELDS  => "ID, FIO, PERIOD, SOURCE_NAME",
    HIDDEN_FIELDS   => "SOURCE",
    FILTER_COLS     => {
      fio         => '_crm_leads_filter::id,',
      source_name => '_translate',
    },
    # FUNCTION_FIELDS => 'change,del',
    SKIP_USER_TITLE => 1,
    EXT_TITLES      => {
      'lead_id'     => "ID",
      'fio'         => $lang{FIO},
      'period'      => $lang{DATE},
      'source_name' => $lang{SOURCE},
    },
    TABLE           => {
      width   => '100%',
      caption => $lang{LEADS},
      qs      => $pages_qs,
      ID      => 'CRM_LEADS',
    },
    MAKE_ROWS       => 1,
    SEARCH_FORMER   => 1,
    MODULE          => 'Crm',
    TOTAL           => "TOTAL:$lang{TOTAL}",
  });

  return 1;
}

#**********************************************************
=head2 _crm_leads_filter() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub _crm_leads_filter {
  my ($fio, $attr) = @_;

  my $id = $attr->{VALUES}{lead_id} || $attr->{VALUES}{id};
  return $fio if !$id;

  my $params = "index=" . get_function_index('crm_lead_info') . "&LEAD_ID=$id";

  return $html->button($fio, $params);
}

#**********************************************************
=head2 crm_short_info() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub crm_short_info {

  my $lead_phone;
  if ($FORM{PHONE}) {
    $lead_phone = $FORM{PHONE};
  }
  else {
    print qq{ { "ERROR": 1, "DESCRIPTION": "NO PHONE"} };
    return 1;
  }

  # if module Callcenter turn on - add this call to calls handler
  if (in_array('Callcenter', \@MODULES)) {
    require Callcenter;
    Callcenter->import();
    my $Callcenter = Callcenter->new($db, $admin, \%conf);
    my $admin_info = $admin->info($admin->{AID});

    $Callcenter->callcenter_add_calls({
      USER_PHONE     => $lead_phone,
      OPERATOR_PHONE => $admin_info->{PHONE} || 0,
      STATUS         => 3,
      UID            => $FORM{uid} || 0,
      ID             => "AE:" . mk_unique_value(10, { SYMBOLS => '1234567890' })
    });
  }

  my $Sender = AXbills::Sender::Core->new($db, $admin, \%conf);

  # at first search user
  my $users = Users->new($db, $admin, \%conf);

  my $user_info = $users->list({
    PHONE     => $FORM{PHONE},
    FIO       => '_SHOW',
    COLS_NAME => 1,
    PAGE_ROWS => 1,
  });

  if ($users->{TOTAL} == 1) {
    my $json_user_info = JSON::to_json($user_info->[0], { utf8 => 0 });

    my $user_link = $html->button(($user_info->[0]->{fio} || "$lang{NO} $lang{FIO}"),
      "index=" . get_function_index('crm_user_service') . "&UID=$user_info->[0]->{uid}");

    $Sender->send_message({
      AID         => $admin->{AID},
      SENDER_TYPE => 'Browser',
      TITLE       => "$lang{INCOMING_CALL}",
      MESSAGE     => "$lang{FIO}: $user_link",
    });

    print $json_user_info;
    return 1;
  }

  my $lead_info = $Crm->crm_lead_list({
    PHONE_SEARCH => $lead_phone,
    CURRENT_STEP => '_SHOW',
    FIO          => '_SHOW',
    EMAIL        => '_SHOW',
    COMPANY      => '_SHOW',
    COMMENTS     => '_SHOW',
    COLS_NAME    => 1,
    PAGE_ROWS    => 1,
  });

  if (defined $Crm->{TOTAL} && $Crm->{TOTAL} == 1) {
    my $json_lead_info = JSON::to_json($lead_info->[0], { utf8 => 0 });

    $Crm->progressbar_comment_add({
      STEP_ID => $lead_info->[0]{current_step} || 1,
      MESSAGE => "Aengine call",
      LEAD_ID => $lead_info->[0]{id},
      DATE => "$DATE $TIME",
      DOMAIN_ID => ($admin->{DOMAIN_ID} || 0)
    });

    my $lead_link = $html->button(($lead_info->[0]->{fio} || "$lang{NO} $lang{FIO}"),
      "index=" . get_function_index('crm_lead_info') . "&LEAD_ID=$lead_info->[0]->{id}");

    $Sender->send_message({
      AID         => $admin->{AID},
      SENDER_TYPE => 'Browser',
      TITLE       => "$lang{INCOMING_CALL}",
      MESSAGE     => "$lang{FIO}: $lead_link",
    });

    print $json_lead_info;
  }
  elsif (defined $Crm->{TOTAL} && $Crm->{TOTAL} < 1) {
    $FORM{COMMENTS} = "$DATE $TIME - lead called through AEngineer";
    $Crm->crm_lead_add({ %FORM, DATE => $DATE, RESPONSIBLE => $admin->{AID} });

    if (!$Crm->{errno}) {
      my $lead_link = $html->button(($lead_info->[0]->{fio} || "$lang{NO} $lang{FIO}"),
        "index=" . get_function_index('crm_lead_info') . "&LEAD_ID=$Crm->{INSERT_ID}");

      $Sender->send_message({
        AID         => $admin->{AID},
        SENDER_TYPE => 'Browser',
        TITLE       => "$lang{INCOMING_CALL}",
        MESSAGE     => "$lang{LEAD} $lang{ADDED}\n$lang{FIO}: $lead_link",
      });

      print qq{ { "ERROR" : 0, "DESCRIPTION" : "NEW LEAD ADDED" } };
    }
    else {
      print qq{ { "ERROR" : 2, "CANT ADD NEW LEAD" } };
    }
  }
  elsif (defined $Crm->{TOTAL} && $Crm->{TOTAL} > 1) {
    print qq{ { "ERROR" : 3, "DESCRIPTION" : "MORE THEN 1 LEAD FOUND" } };
  }

  return 1;
}

#**********************************************************
=head2 crm_lead_progress_report() -

  Arguments:
    $att -
  Returns:

  Examples:

=cut
#**********************************************************
sub crm_leads_progress_report {

  my $date_range = $html->form_daterangepicker({
    NAME      => 'FROM_DATE/TO_DATE',
    FORM_NAME => 'report_panel',
    WITH_TIME => $FORM{TIME_FORM} || 0
  });

  $html->tpl_show(_include('crm_leads_reports', 'Crm'), {
    DATE_RANGE         => $date_range,
    HIDE_SOURCE_SELECT => 'none',
  });

  my $period = ($FORM{FROM_DATE} || $DATE) . "/" . ($FORM{TO_DATE} || $DATE);

  my $leads_list = $Crm->crm_lead_list({
    PERIOD       => $period,
    SOURCE       => $FORM{SOURCE_ID} || '_SHOW',
    COLS_NAME    => 1,
    CURRENT_STEP => '_SHOW'
  });
  _error_show($Crm);

  my $steps_list = $Crm->crm_progressbar_step_list({
    STEP_NUMBER => '_SHOW',
    NAME        => '_SHOW',
    COLOR       => '_SHOW',
    DESCRIPTION => '_SHOW',
    COLS_NAME   => 1
  });
  _error_show($Crm);

  my $last_step = 0;

  foreach my $step (@$steps_list) {
    $last_step = $step->{STEP_NUMBER};
  }

  my %HASH_BY_DATES;

  foreach my $lead (@$leads_list) {
    next if !$lead->{period};

    if (defined $HASH_BY_DATES{ $lead->{period} }{leads_comes}) {
      $HASH_BY_DATES{ $lead->{period} }{leads_comes}++;
    }
    else {
      $HASH_BY_DATES{ $lead->{period} }{leads_comes} = 1;
    }

    if (defined($last_step) && $last_step == $lead->{current_step}) {
      if (defined $HASH_BY_DATES{ $lead->{period} }{leads_finished}) {
        $HASH_BY_DATES{ $lead->{period} }{leads_finished}++;
      }
      else {
        $HASH_BY_DATES{ $lead->{period} }{leads_finished} = 1;
      }
    }
  }

  my @dates;
  my @leads_comes;
  my @leads_finished;

  foreach my $key (sort keys %HASH_BY_DATES) {
    push(@dates, $key);
    push(@leads_comes, $HASH_BY_DATES{$key}{leads_comes} || 0);
    push(@leads_finished, $HASH_BY_DATES{$key}{leads_finished} || 0);
  }

  my $leads_progress_table = $html->table({
    ID      => 'LEADS_PROGRESS_TABLE',
    width   => '100%',
    caption => "$lang{LEADS} $lang{PROGRESS}",
    title   => [ $lang{DATE}, $lang{LEADS_COMES}, $lang{LEADS_FINISHED}, $lang{PROGRESS} ]
  });

  foreach my $date (reverse sort keys %HASH_BY_DATES) {
    $leads_progress_table->addrow(
      $html->button("$date", "index=" . get_function_index('crm_reports_leads') . "&FROM_DATE=$date&TO_DATE=$date", {

      }),
      $HASH_BY_DATES{$date}{leads_comes} || 0,
      $HASH_BY_DATES{$date}{leads_finished} || 0,
      $html->progress_bar({
        TOTAL        => $HASH_BY_DATES{$date}{leads_comes} || 0,
        COMPLETE     => $HASH_BY_DATES{$date}{leads_finished} || 0,
        PERCENT_TYPE => 1,
        COLOR        => 'MAX_COLOR',
      })
    );
  }

  print $leads_progress_table->show();

  $html->chart({
    TYPE              => 'bar',
    X_LABELS          => \@dates,
    DATA              => {
      "$lang{LEADS_COMES}"    => \@leads_comes,
      "$lang{LEADS_FINISHED}" => \@leads_finished,
    },
    BACKGROUND_COLORS => {
      "$lang{LEADS_COMES}"    => 'rgba(2, 99, 2, 0.5)',
      "$lang{LEADS_FINISHED}" => 'rgba(255, 99, 255, 0.5)',
    },
    IN_CONTAINER      => 1
  });

  return 1;
}

#**********************************************************
=head2 _crm_current_step_color() -

  Arguments:
    ATTRIBUTES -
  Returns:

  Examples:

=cut
#**********************************************************
sub _crm_current_step_color {
  my ($step_name, $attr) = @_;
  return '' unless ($step_name);

  my $color = $attr->{VALUES}{STEP_COLOR};

  return $html->element('span', _translate($step_name), {
    class => 'text-white badge',
    style => "background-color:$color"
  });
}

#**********************************************************
=head2 _crm_last_action() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub _crm_last_action {
  my ($lead_id) = @_;

  my $list = $Crm->progressbar_comment_list({
    COLS_NAME => 1,
    LEAD_ID   => $lead_id,
    PAGE_ROWS => 1,
    DATE      => '_SHOW',
  });

  if (!$Crm->{errno}) {
    if (ref $list eq 'ARRAY' && scalar @$list > 0) {
      return "$list->[0]->{date}";
    }
  }

  return '';
}

#**********************************************************
=head2 crm_lead_convert() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub crm_lead_convert {

  if ($FORM{TO_LEAD_ID}) {
    my $from_lead_info = $Crm->crm_lead_info({ ID => $FORM{FROM_LEAD_ID} });

    $Address->address_info($from_lead_info->{BUILD_ID});
    $from_lead_info->{ADDRESS} = join ', ', grep {$_ && length $_ > 0}
    $Address->{ADDRESS_DISTRICT}, $Address->{ADDRESS_STREET}, $Address->{ADDRESS_BUILD}, $from_lead_info->{ADDRESS_FLAT};
    
    my $to_lead_info = $Crm->crm_lead_info({ ID => $FORM{TO_LEAD_ID} });

    my $from_lead_panel = $html->tpl_show(_include('crm_convert_panel', 'Crm'), {
      %$from_lead_info,
      POSTFIX_PANEL_ID => 1
    }, { OUTPUT2RETURN => 1 });

    my $to_lead_panel = $html->tpl_show(_include('crm_convert_panel', 'Crm'), {
      %$to_lead_info,
      POSTFIX_PANEL_ID => 2
    }, { OUTPUT2RETURN => 1 });

    $html->tpl_show(_include('crm_leads_convert', 'Crm'), {
      FROM_LEAD_PANEL     => $from_lead_panel,
      TO_LEAD_PANEL       => $to_lead_panel,
      LEFT_PANEL_POSTFIX  => 1,
      RIGHT_PANEL_POSTFIX => 2,
      INDEX               => get_function_index('crm_lead_info'),
      FROM_LEAD_ID        => $FORM{FROM_LEAD_ID},
      TO_LEAD_ID          => $FORM{TO_LEAD_ID},
      BUILD_ID            => $from_lead_info->{BUILD_ID},
      ADDRESS_FLAT        => $from_lead_info->{ADDRESS_FLAT},
    });

    return 1;
  }

  my $leads_list = $Crm->crm_lead_list({
    FIO        => $FORM{FIO} || '_SHOW',
    COLS_NAME  => 1,
    COLS_UPPER => 1,
  });

  my $to_lead_select = $html->form_select('TO_LEAD_ID', {
    SELECTED  => $FORM{TO_LEAD_ID} || q{},
    SEL_LIST  => $leads_list,
    SEL_KEY   => 'id',
    SEL_VALUE => 'fio',
    SEL_OPTIONS => { '' => '--' },
    EX_PARAMS => "data-auto-submit='form'"
  });

  $html->tpl_show(_include('crm_leads_convert_select', 'Crm'), {
    TO_LEAD_SELECT => $to_lead_select,
    FROM_LEAD_ID   => $FORM{FROM_LEAD_ID},
  });

  return 1;
}

#**********************************************************
=head2 crm_user_calling_info() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub crm_user_service {

  my $uid = $FORM{UID} || 0;
  my $msgs_box = qq{};
  my $callcenter_box = qq{};
  $FORM{NEWFORM} = 1;

  if (in_array('Msgs', \@MODULES)) {
    my @msgs_rows;
    use Msgs;
    my $Msgs = Msgs->new($db, $admin, \%conf);
    my $msgs_list = $Msgs->messages_list({
      UID                    => $uid,
      DATETIME               => '_SHOW',
      SUBJECT                => '_SHOW',
      RESPOSIBLE_ADMIN_LOGIN => '_SHOW',
      COLS_NAME              => 1,
      PAGE_ROWS              => 5,
      SORT                   => 'id',
      DESC                   => 'desc'
    });

    foreach my $msgs (@$msgs_list) {
      my $button_to_subject = $html->button(($msgs->{subject} || $lang{NO_SUBJECT} || 'NO SUBJECT'),
        "index=" . get_function_index('msgs_admin') . "&UID=$uid&chg=$msgs->{id}");
      push @msgs_rows, [ $msgs->{id}, $button_to_subject, $msgs->{datetime}, ($msgs->{resposible_admin_login} || '') ];
    }

    my $msgs_table = $html->table({
      width   => '100%',
      caption => $lang{MESSAGES},
      ID      => 'CRM_MSGS_LITE',
      title   => [ '#', $lang{SUBJECT}, $lang{DATE}, $lang{RESPOSIBLE} ],
      rows    => \@msgs_rows
    });

    $msgs_box = $msgs_table->show();
  }
  else {
    $html->message("warning", "$lang{MODULE} Msgs $lang{NOT_ADDED}");
  }

  if (in_array('Callcenter', \@MODULES)) {
    require Callcenter;
    Callcenter->import();
    my $Callcenter = Callcenter->new($db, $admin, \%conf);
    my $calls_list = $Callcenter->callcenter_list_calls({
      UID       => $uid,
      DATE      => '_SHOW',
      STATUS    => '_SHOW',
      COLS_NAME => 1,
      PAGE_ROWS => 5,
      SORT      => 'id',
      DESC      => 'desc'
    });
    my @calls_rows;
    my @STATUSES = ('', $lang{RINGING}, $lang{IN_PROCESSING}, $lang{PROCESSED}, $lang{NOT_PROCESSED});

    foreach my $call (@$calls_list) {
      push @calls_rows, [ $call->{id}, $call->{date}, $STATUSES[$call->{status}] ];
    }

    my $calls_table = $html->table({
      width   => '100%',
      caption => $lang{CALLS_HANDLER},
      ID      => 'CRM_CALLS_LITE',
      title   => [ '#', $lang{DATE}, $lang{STATUS} ],
      rows    => \@calls_rows
    });
    $callcenter_box = $calls_table->show();
  }
  else {
    $html->message('warning', "$lang{MODULE} Callcenter $lang{NOT_ADDED}");
  }

  return $msgs_box, $callcenter_box;
}

#**********************************************************
=head2 lead_actions_main ($attr)

  Arguments:
    $attr -

  Returns:

=cut
#**********************************************************
sub crm_actions_main {

  my %CRM_ACTIONS_TEMPLATE = (BTN_NAME => 'add', BTN_VALUE => $lang{ADD});

  if ($FORM{add}) {
    $Crm->crm_actions_add({ %FORM, DOMAIN_ID => ($admin->{DOMAIN_ID} || 0) });
    _error_show($Crm);
  }
  elsif ($FORM{change}) {
    $Crm->crm_actions_change({ %FORM });
    _error_show($Crm);
  }
  elsif ($FORM{del}) {
    $Crm->crm_actions_delete({ ID => $FORM{del} });
    _error_show($Crm);
  }

  if ($FORM{chg}) {
    $CRM_ACTIONS_TEMPLATE{BTN_NAME} = 'change';
    $CRM_ACTIONS_TEMPLATE{BTN_VALUE} = $lang{CHANGE};

    my $action_info = $Crm->crm_actions_info({
      ID         => $FORM{chg},
      NAME       => '_SHOW',
      ACTION     => '_SHOW',
      COLS_NAME  => 1,
      COLS_UPPER => 1,
    });
    _error_show($Crm);

    if ($action_info) {
      @CRM_ACTIONS_TEMPLATE{keys %$action_info} = values %$action_info;
      $CRM_ACTIONS_TEMPLATE{SEND_MESSAGE} = 'checked' if $action_info->{SEND_MESSAGE};
      $CRM_ACTIONS_TEMPLATE{ACTION_ID} = $action_info->{ID};
    }
  }

  my $leads_table_info = $Crm->table_info('crm_leads', { FULL_INFO => 1 });
  my $skip_vars = join(',', map { uc $_->{column_name} } @{$leads_table_info});

  $html->tpl_show(_include('crm_actions_add', 'Crm'), { %CRM_ACTIONS_TEMPLATE }, { SKIP_VARS => $skip_vars });

  result_former({
    INPUT_DATA      => $Crm,
    FUNCTION        => 'crm_actions_list',
    BASE_FIELDS     => 0,
    DEFAULT_FIELDS  => 'ID,NAME,ACTION',
    FUNCTION_FIELDS => 'change,del',
    EXT_TITLES      => {
      id     => 'ID',
      name   => $lang{NAME},
      action => $lang{ACTION},
    },
    TABLE           => {
      width   => '100%',
      caption => $lang{ACTION},
      qs      => $pages_qs,
      ID      => 'CRM_ACTIONS',
    },
    MAKE_ROWS       => 1,
    SEARCH_FORMER   => 1,
    MODULE          => 'Crm',
    TOTAL           => "TOTAL:$lang{TOTAL}",
  });

  return 1;
}

#**********************************************************
=head2 _actions_sel($attr)

  Arguments:
    $attr

  Returns:

=cut
#**********************************************************
sub _actions_sel {
  my ($attr) = @_;

  my $actions_list = $Crm->crm_actions_list({
    NAME      => '_SHOW',
    ACTION    => '_SHOW',
    COLS_NAME => 1,
  });

  return $html->form_select('ACTION_ID', {
    SELECTED    => $attr->{SELECTED} || 0,
    SEL_LIST    => $actions_list,
    SEL_KEY     => 'id',
    SEL_VALUE   => 'name,action',
    NO_ID       => 1,
    SEL_OPTIONS => { '' => '--' },
    ID          => $attr->{ID} || 'ACTION_ID'
  });
}

#**********************************************************
=head2 crm_lead_add_user()

  Returns:

=cut
#**********************************************************
sub crm_lead_add_user {

  if ($FORM{add_uid}) {
    $Crm->crm_lead_change({
      ID  => $FORM{LEAD_ID},
      UID => $FORM{UID},
    });

    if(!_error_show($Crm)){
      my $lead_button = $html->button($lang{LEAD}, "index=" . get_function_index("crm_lead_info") . "&LEAD_ID=$FORM{LEAD_ID}");
      $html->message('info', $lang{SUCCESS}, "$lang{GO2PAGE} $lead_button");
    }
  }

  my $lead_id = $FORM{TO_LEAD_ID};

  # Check for search form request
  require Control::Users_mng;
  my $user_search = user_modal_search({
    EXTRA_BTN_PARAMS => "",
    CALLBACK_FN      => 'crm_lead_info',
  });
  return 1 if ($user_search && $user_search eq 2);

  $html->tpl_show(_include('crm_lead_add_user', 'Crm'), {
    USER_SEARCH => $user_search,
    LEAD_ID     => $lead_id,
    INDEX       => get_function_index('crm_lead_info'),
  });

  return 1;
}

#**********************************************************
=head2 _progress_bar_step_sel($attr)

  Arguments:
    $attr

  Returns:

=cut
#**********************************************************
sub _progress_bar_step_sel {
  my ($attr) = @_;

  my $progress_bar_steps_list = $Crm->crm_progressbar_step_list({
    ID          => '_SHOW',
    NAME        => '_SHOW',
    STEP_NUMBER => '_SHOW',
    COLS_NAME   => 1,
  });

  my $id = 1;
  foreach my $step (@$progress_bar_steps_list) {
    $step->{id} = $id++;
    $step->{name} = _translate($step->{name});
  }

  return $html->form_select('CURRENT_STEP', {
    SELECTED    => $attr->{SELECTED} || q{},
    SEL_LIST    => $progress_bar_steps_list,
    SEL_KEY     => 'step_number',
    SEL_VALUE   => 'name',
    NO_ID       => 1,
    SEL_OPTIONS => { '' => '--' },
  });
}

#**********************************************************
=head2 _crm_tags($attr)

  Arguments:
    $attr -

  Returns:

=cut
#**********************************************************
sub _crm_tags {
  my ($attr) = @_;

  if ($attr->{SHOW}) {
    my $list = $Tags->list({
      NAME      => '_SHOW',
      LIST2HASH => 'id,name'
    });

    my $lead_info = $Crm->crm_lead_list({
      LEAD_ID   => $attr->{LEAD} || 0,
      COLS_NAME => 1,
      TAG_IDS   => '_SHOW'
    });
    my @lead_checked = split(/, /, ($lead_info->[0]{tag_ids} || ''));
    my %checked_tags = ();
    foreach my $item (@lead_checked) {
      $checked_tags{$item} = $item;
    }

    my $table = $html->table({ width => '100%' });
    foreach my $item (sort keys %{$list}) {
      $table->addrow(
        $html->form_input('TAG_IDS', $item, { TYPE => 'checkbox', ID => $item, STATE => $checked_tags{$item} ? 'checked' : '' }),
        $list->{$item}
      );
    }

    return $table->show({ OUTPUT2RETURN => 1 });
  }
  elsif ($attr->{SAVE_TAGS}) {
    $Crm->crm_update_lead_tags({ LEAD_ID => $attr->{LEAD_ID}, TAG_IDS => $attr->{TAG_IDS} });
  }
  elsif ($attr->{SHOW_TAGS}) {
    my $tags = qq{};
    my @priority_colors = ('', 'btn-secondary', 'btn-info', 'btn-success', 'btn-warning', 'btn-danger');
    my $list = $Tags->list({
      NAME      => '_SHOW',
      PRIORITY  => '_SHOW',
      COLOR     => '_SHOW',
      COLS_NAME => 1
    });

    my $lead_info = $Crm->crm_lead_list({
      LEAD_ID   => $attr->{LEAD} || 0,
      COLS_NAME => 1,
      TAG_IDS   => '_SHOW'
    });

    my @lead_checked = split(/, /, ($lead_info->[0]{tag_ids} || ''));
    my %checked_tags = ();
    foreach my $item (@lead_checked) {
      $checked_tags{$item} = $item;
    }

    foreach my $item (@$list) {
      next if !$checked_tags{$item->{id}};

      my $priority_color = ($priority_colors[$item->{priority}]) ? $priority_colors[$item->{priority}] : $priority_colors[1];
      $tags .= ' ' . $html->element('span', $item->{name}, {
        class => $item->{color} ? 'label new-tags m-1' : "btn btn-xs $priority_color",
        style => $item->{color} ? "background-color: $item->{color}; border-color: $item->{color}" : ''
      });
    }
    return $tags || q{};
  }

  return 1;
}

#**********************************************************
=head2 _crm_tags_name($tags)

  Arguments:
    $tags -

  Returns:

=cut
#**********************************************************
sub _crm_tags_name {
  my ($tags) = @_;

  return '' if (! $tags);

  my $tags_named = qq{};
  my @priority_colors = ('', 'btn-secondary', 'btn-info', 'btn-success', 'btn-warning', 'btn-danger');
  my $list = $Tags->list({
    NAME      => '_SHOW',
    PRIORITY  => '_SHOW',
    COLOR     => '_SHOW',
    COLS_NAME => 1
  });

  my @lead_checked = split(/, /, ($tags || ''));
  my %checked_tags = ();
  foreach my $item (@lead_checked) {
    $checked_tags{$item} = $item;
  }

  foreach my $item (@$list) {
    next if !$checked_tags{$item->{id}};

    my $priority_color = ($priority_colors[$item->{priority}]) ? $priority_colors[$item->{priority}] : $priority_colors[1];
    $tags_named .= ' ' . $html->element('span', $item->{name}, {
      class => $item->{color} ? 'label new-tags m-1' : "btn btn-xs $priority_color",
      style => $item->{color} ? "background-color: $item->{color}; border-color: $item->{color}" : ''
    });
  }

  return $tags_named || q{};
}

#**********************************************************
=head2 _crm_send_lead_mess()

  Arguments:
    $tags -

  Returns:

=cut
#**********************************************************
sub _crm_send_lead_mess {
  my ($attr) = @_;

  my @id_leads = split(/, /, $FORM{ID});
  my $Sender = AXbills::Sender::Core->new($db, $admin, \%conf);
  my $no_email_leade = '';
  my %ids = ();

  foreach my $element (@id_leads) {
    $ids{$element} = 1;
  }

  my $step_id_hash = $Crm->crm_step_number_leads();

  my $list = $Crm->crm_lead_list({
    LEAD_ID           => '_SHOW',
    CURRENT_STEP      => '_SHOW',
    EMAIL             => '_SHOW',
    FIO               => '_SHOW',
    CURRENT_STEP_NAME => '_SHOW',
    COLS_NAME         => 1
  });

  if ($conf{ADMIN_MAIL}) {
    foreach my $iter (@$list) {
      next if (!$ids{ $iter->{lead_id} });

      if ($iter->{email}) {
        $Sender->send_message({
          TO_ADDRESS  => $iter->{email},
          MESSAGE     => $attr->{MSGS},
          SUBJECT     => $attr->{SUBJECT} || $iter->{current_step_name},
          SENDER_TYPE => 'Mail',
          DEBUG       => 5,
          ATTACHMENTS => $attr->{ATTACHMENTS} || ''
        });
      }
      else {
        $no_email_leade .= "$iter->{fio}, ";
      }

      $Crm->progressbar_comment_add({
        LEAD_ID      => $iter->{lead_id},
        MESSAGE      => $attr->{MSGS},
        DATE         => "$DATE $TIME",
        PLANNED_DATE => $DATE,
        AID          => $admin->{AID},
        STATUS       => 1,
        ACTION_ID    => $attr->{ACTION_ID},
        STEP_ID      => $step_id_hash->{ $iter->{current_step} } ? $step_id_hash->{ $iter->{current_step} } : 1,
        DOMAIN_ID    => ($admin->{DOMAIN_ID} || 0)
      });
    }

    $html->message('info', $lang{SUCCESS}, $lang{EXECUTED}) if !_error_show($Crm);
  }
  else {
    $html->message('err', $lang{ERROR}, $lang{NO_EMAIL} . ' $conf{ADMIN_MAIL}');
  }

  if ($no_email_leade ne '') {
    $html->message('warn', $lang{WARNING}, $lang{NO_EMAIL_LEAD} . ' ' . $no_email_leade);
  }

  return 0;
}

#**********************************************************
=head2 _crm_lead_to_client($attr)

  Arguments:
    lead_id     - Lead id

  Returns:

=cut
#**********************************************************
sub _crm_lead_to_client {
  my ($lead_id) = @_;

  my $lead_info = $Crm->crm_lead_info({ ID => $lead_id });

  map { $lead_info->{$_} && $_ ne 'PHONE' && $_ ne 'EMAIL' ? $FORM{$_} = $lead_info->{$_} : () } keys %{$lead_info};

  my %contacts = ();
  push @{$contacts{1}}, $lead_info->{PHONE} if $lead_info->{PHONE};
  push @{$contacts{9}}, $lead_info->{EMAIL} if $lead_info->{EMAIL};

  $FORM{CONTACTS_ENTERED} = json_former(\%contacts);

  if ($lead_info->{COMPANY}) {
    $FORM{company} = 1;
    $FORM{company_name} = $lead_info->{COMPANY};
  }

  if ($lead_info->{BUILD_ID}) {
    $FORM{LOCATION_ID} = $lead_info->{BUILD_ID};
    return;
  }

  my $builds = $Address->build_list({
    STREET_ID     => '_SHOW',
    STREET_NAME   => '_SHOW',
    DISTRICT_ID   => '_SHOW',
    DISTRICT_NAME => '_SHOW',
    CITY          => '_SHOW',
    NUMBER        => '_SHOW',
    COLS_NAME     => 1,
    PAGE_ROWS     => 999999
  });


  foreach my $address_element (@$builds) {
    if ($address_element->{city} && $address_element->{city} eq $lead_info->{CITY}) {
      $FORM{DISTRICT_ID} = $address_element->{district_id};
    }

    if ($address_element->{street_name} && $address_element->{street_name} eq $lead_info->{ADDRESS}) {
      $FORM{STREET_ID} = $address_element->{street_id};
    }
  }

  return 1;
}

#**********************************************************
=head2 _crm_create_client($attr)

  Arguments:
    lead_id     - Lead id

  Returns:

=cut
#**********************************************************
sub _crm_create_client {
  my ($uid, $lead_id) = @_;

  $Crm->crm_lead_change({ ID => $lead_id, UID => $uid });

  $html->message('err', $lang{ERROR}, '') if _error_show($Crm);

  return 1;
}

#**********************************************************
=head2 _crm_multiselect_form($attr)

  Arguments:
    lead_id     - Lead id

  Returns:

=cut
#**********************************************************
sub _crm_multiselect_form {
  my $table = shift;

  if (in_array('Tags', \@MODULES) && (!$admin->{MODULES} || $admin->{MODULES}{'Tags'})) {
    load_module('Tags', $html);
    $Crm->{TAGS_SEL} = tags_sel();
  }

  $Crm->{RESPONSIBLE_ADMIN} = sel_admins({ NAME => 'RESPONSIBLE' });

  print $table->show() if $table;
  print $html->form_main({
    CONTENT => $html->tpl_show(_include('crm_lead_multiselect', 'Crm'), $Crm, { OUTPUT2RETURN => 1 }),
    HIDDEN  => {
      index           => $index,
      CRM_MULTISELECT => 1
    },
    NAME    => 'crm_lead_multiselect',
    class   => 'hidden-print',
    ID      => 'crm_lead_multiselect',
  });

  return 1;
}

#**********************************************************
=head2 _crm_translate_source($attr)

  Arguments:
    source_id - Source id

  Returns:
    Source name

=cut
#**********************************************************
sub _crm_translate_source {
  my $source_id = shift;

  return '' if !$source_id;

  my $source_info = $Crm->leads_source_info({ ID => $source_id, COLS_NAME => 1 });
  return $Crm->{TOTAL} > 0 ? _translate($source_info->{NAME}) : '';
}

#**********************************************************
=head2 crm_find_user_by_email()

=cut
#**********************************************************
sub crm_users_by_lead_email {

  return 1 if !$FORM{ID};

  $Crm->crm_users_by_lead_email($FORM{ID});

  return if $Crm->{TOTAL} < 1 || !$Crm->{UID};

  print json_former({ UID => $Crm->{UID}, EXIST => $Crm->{LEAD_UID} ? 1 : 0, LOGIN => $Crm->{LOGIN} });
}

#**********************************************************
=head2 crm_lead_map_multiple_update()

=cut
#**********************************************************
sub crm_lead_map_multiple_update {

  if ($FORM{CRM_MULTISELECT}) {
    $FORM{MESSAGE_ONLY} = 1;
    crm_leads();

    return 1;
  }

  my $leads = $Crm->crm_lead_list({
    FIO               => '_SHOW',
    ADMIN_NAME        => '_SHOW',
    CURRENT_STEP_NAME => '_SHOW',
    STEP_COLOR        => '_SHOW',
    TAG_IDS           => '_SHOW',
    BUILD_ID          => $FORM{IDS},
    COLS_NAME         => 1,
    SORT              => 'cl.id'
  });

  my $lead_table = $html->table({
    width      => '100%',
    caption    => $lang{LEADS},
    ID         => 'CRM_LEAD_LIST',
    title      => [ '#', $lang{FIO}, $lang{RESPOSIBLE}, $lang{STEP}, $lang{TAGS} ],
    HIDE_TABLE => 1
  });

  my @leads_id = ();
  foreach my $lead (@{$leads}) {
    my $step = _crm_current_step_color($lead->{current_step_name}, { VALUES => { STEP_COLOR => $lead->{step_color} } });
    my $tags = _crm_tags_name($lead->{tag_ids});

    $lead_table->addrow($lead->{id}, $lead->{fio}, $lead->{admin_name}, $step, $tags);
    push @leads_id, $lead->{id};
  }

  if (in_array('Tags', \@MODULES) && (!$admin->{MODULES} || $admin->{MODULES}{'Tags'})) {
    load_module('Tags', $html);
    $Crm->{TAGS_SEL} = tags_sel();
  }

  $html->tpl_show(_include('crm_lead_map_multiple_update', 'Crm'), { %{$Crm},
    LEADS_TABLE       => $lead_table->show(),
    RESPONSIBLE_ADMIN => sel_admins({ NAME => 'RESPONSIBLE' }),
    IDS               => join(',', @leads_id)
  });
}

#**********************************************************
=head2 crm_response_templates()

  Arguments:
  Returns:

=cut
#**********************************************************
sub crm_response_templates {

  if ($FORM{add}) {
    $Crm->crm_response_templates_add(\%FORM);
    $html->message('success', $lang{ADDED} ) if (!_error_show($Crm));
  }
  elsif ($FORM{chg}) {
    $Crm->{BTN_NAME} = 'change';
    $Crm->{BTN_VALUE} = $lang{CHANGE};
    $Crm->crm_response_templates_info({ ID => $FORM{chg} });
  }
  elsif ($FORM{change}) {
    $Crm->crm_response_templates_change(\%FORM);
    $html->message('success', $lang{CHANGED}) if (!_error_show($Crm));
  }
  elsif ($FORM{del}) {
    $Crm->crm_response_templates_del({ ID => $FORM{del} });
    $html->message('success', $lang{DELETED})  if (!_error_show($Crm));
  }

  if ($FORM{add_form} || $FORM{chg} ) {
    print $html->tpl_show(_include('crm_response_template', 'Crm'), {
      INDEX => $index,
      BTN_NAME => 'add',
      BTN_VALUE => $lang{ADD},
      %$Crm
    }, { OUTPUT2RETURN => 1 });
  }

  result_former({
  INPUT_DATA      => $Crm,
    FUNCTION        => 'crm_response_templates_list',
    BASE_FIELDS     => 0,
    DEFAULT_FIELDS  => "ID, NAME, TEXT",
    FUNCTION_FIELDS => 'change,del',
    EXT_TITLES      => {
      'id'     => "ID",
      'name'   => $lang{NAME},
      'text'   => $lang{TEXT},
    },
    TABLE           => {
      width   => '100%',
      caption => $lang{TEMPLATES_RESPONSE},
      qs      => $pages_qs,
      ID      => 'TEMPLATE_RESPONSE_LIST',
      MENU    => "$lang{ADD}:index=$index&add_form=1:add",
    },
    MAKE_ROWS       => 1,
    SEARCH_FORMER   => 1,
    MODULE          => 'Crm',
    TOTAL           => "TOTAL:$lang{TOTAL}",
  });

  return 1;
}

#**********************************************************
=head2 crm_leads_import()

=cut
#**********************************************************
sub crm_leads_import {
  my @output_fields = ();
  my $crm_leads_table_info = $Crm->table_info('crm_leads', { FULL_INFO => 1 });

  foreach my $leads_column (@{$crm_leads_table_info}) {
    my $column_name = $leads_column->{column_name};
    my $type = $leads_column->{data_type};
    
    push @output_fields, {
      NAME       => $lang{uc $column_name} || ucfirst $column_name,
      FIELD_NAME => uc $column_name,
    };
  }

  $html->tpl_show(_include('crm_import', 'Crm'), {
    RESULT_INDEX     => get_function_index('crm_leads') || $index,
    OUTPUT_STRUCTURE => _crm_import_build_output_fields_list(\@output_fields),
  });
}

#**********************************************************
=head2 _crm_import_build_output_fields_list($fields)

=cut
#**********************************************************
sub _crm_import_build_output_fields_list {
  my ($fields) = @_;
  my $fields_list = '';

  foreach my $output_field (@{ $fields }) {
    $fields_list .= _crm_import_build_output_field(
      $output_field->{NAME},
      $output_field->{FIELD_NAME},
      $output_field->{INPUT},
    );
  }

  return $fields_list
}

#**********************************************************
=head2 _crm_import_build_output_field($name, $field_name, $default_select)
  Arguments:
    $name - human readable field name
    $field_name - field name in database
    $default_select - input in field card to select default value
=cut
#**********************************************************
sub _crm_import_build_output_field {
  my ($name, $field_name, $default_select) = @_;

  return $html->tpl_show(_include('crm_import_output_field', 'Crm'), {
    NAME       => $name,
    FIELD_NAME => $field_name,
    INPUT      => $default_select
  }, { OUTPUT2RETURN => 1 });
}

1;
