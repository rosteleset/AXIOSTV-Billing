#package Paysys::Configure;

use strict;
use warnings FATAL => 'all';
use Paysys::Init;
use Users;
use AXbills::Base qw(in_array vars2lang json_former);

if (form_purchase_module({
  HEADER          => $user->{UID},
  MODULE          => 'Paysys',
  REQUIRE_VERSION => 9.33
})) {
  print $@;
  exit;
}

our (
  $db,
  %conf,
  $admin,
  %lang,
  @WEEKDAYS,
  $base_dir,
  $index
);

our @TERMINAL_STATUS = ("$lang{ENABLE}", "$lang{DISABLE}");
our Paysys $Paysys;
our AXbills::HTML $html;
my $Users = Users->new($db, $admin, \%conf);

#**********************************************************
=head2 _paysys_select_systems()

=cut
#**********************************************************
sub _paysys_select_systems {
  my $systems = _paysys_read_folder_systems();

  my %HASH_TO_JSON = ();
  foreach my $system (@$systems) {
    my $Module = _configure_load_payment_module($system);
    if ($Module->can('get_settings')) {
      my %settings = $Module->get_settings();
      $HASH_TO_JSON{$system} = \%settings;
    }
  }

  my $json_list = JSON->new->utf8(0)->encode(\%HASH_TO_JSON);

  return $html->form_select('MODULE',
    {
      SELECTED    => $FORM{MODULE} || '',
      SEL_ARRAY   => $systems,
      NO_ID       => 1,
      SEL_OPTIONS => { '' => '--' },
    }), $json_list;
}

#**********************************************************
=head2 _paysys_select_payment_method()

=cut
#**********************************************************
sub _paysys_select_payment_method {
  my ($attr) = @_;
  my $checkbox = '';

  if ($attr->{CREATE_PAYMENT_METHOD}) {
    $checkbox = $html->form_input('create_payment_method', '1', {
      TYPE      => 'checkbox',
      EX_PARAMS => "data-tooltip='$lang{CREATE}' checked",
      ID        => 'create_payment_method',
      class     => 'mx-2'
    }, { OUTPUT2RETURN => 1 });
  }

  return $html->form_select('PAYMENT_METHOD',
    {
      SELECTED    => $FORM{PAYMENT_METHOD} || $attr->{PAYMENT_METHOD} || '',
      SEL_HASH    => get_payment_methods(),
      NO_ID       => 1,
      SEL_OPTIONS => { '' => '--' },
      SORT_KEY    => 1,
      EXT_BUTTON  => $checkbox,
    });
}

#**********************************************************
=head2 paysys_configure_external_commands()

=cut
#**********************************************************
sub paysys_configure_external_commands {
  my $action = 'change';
  my $action_lang = "$lang{CHANGE}";
  my %EXTERNAL_COMMANDS_SETTINGS = ();
  my $Config = Conf->new($db, $admin, \%conf);

  my @conf_params = ('PAYSYS_EXTERNAL_START_COMMAND', 'PAYSYS_EXTERNAL_END_COMMAND', 'PAYSYS_EXTERNAL_PAYMENT_MADE_COMMAND',
    'PAYSYS_EXTERNAL_ATTEMPTS', 'PAYSYS_EXTERNAL_TIME');

  if ($FORM{change}) {
    foreach my $conf_param (@conf_params) {
      $Config->config_add({ PARAM => $conf_param, VALUE => $FORM{$conf_param}, REPLACE => 1, PAYSYS => 1, DOMAIN_ID => $FORM{PAYSYS_DOMAIN_ID} || 0 });
    }
  }

  foreach my $conf_param (@conf_params) {
    my $param_information = $Config->config_info({
      PARAM     => $conf_param,
      DOMAIN_ID => $admin->{DOMAIN_ID},
    });
    $EXTERNAL_COMMANDS_SETTINGS{$conf_param} = $param_information->{VALUE};
  }

  $html->tpl_show(_include('paysys_external_commands', 'Paysys'), {
    ACTION      => $action,
    ACTION_LANG => $action_lang,
    %EXTERNAL_COMMANDS_SETTINGS
  }, { SKIP_VARS => 'IP UID' });

  return 1;
}

#**********************************************************
=head2 terminals_add() - Adding terminals with location ID

=cut
#**********************************************************
sub paysys_configure_terminals {

  my %TERMINALS = ();

  $TERMINALS{ACTION} = 'add';
  $TERMINALS{BTN} = $lang{ADD};

  $FORM{WORK_DAYS} = 0;
  if ($FORM{WEEK_DAYS}) {
    my @enabled_days = split(', ', $FORM{WEEK_DAYS});
    foreach my $day (@enabled_days) {
      $FORM{WORK_DAYS} += (64 / (2 ** ($day - 1)));
    }
  }

  # if we want to add new terminal
  if ($FORM{ACTION} && $FORM{ACTION} eq 'add') {
    $Paysys->terminal_add({
      %FORM,
      TYPE => $FORM{TERMINAL},
    });
    if (!$Paysys->{errno}) {
      $html->message('success', $lang{ADDED}, "$lang{ADDED} $lang{TERMINAL}");
    }
  }

  # if we want to change terminal
  elsif ($FORM{ACTION} && $FORM{ACTION} eq 'change') {
    $Paysys->terminal_change({
      %FORM,
      TYPE => $FORM{TERMINAL},
    });
    if (!$Paysys->{errno}) {
      $html->message('success', $lang{CHANGED}, "$lang{CHANGED} $lang{TERMINAL}");
    }
  }

  # get info about terminl into page
  if ($FORM{chg}) {
    my $terminal_info = $Paysys->terminal_info($FORM{chg});

    $TERMINALS{ACTION} = 'change';
    $TERMINALS{COMMENT} = $terminal_info->{COMMENT};
    $TERMINALS{DESCRIPTION} = $terminal_info->{DESCRIPTION};
    $TERMINALS{WORK_DAYS} = $terminal_info->{WORK_DAYS};
    $TERMINALS{START_WORK} = $terminal_info->{START_WORK};
    $TERMINALS{END_WORK} = $terminal_info->{END_WORK};
    $TERMINALS{TYPE} = $terminal_info->{TYPE_ID};
    $TERMINALS{BTN} = "$lang{CHANGE}";
    $TERMINALS{ID} = $FORM{chg};
    $TERMINALS{STATUS} = $terminal_info->{STATUS};
    $TERMINALS{DISTRICT_ID} = $terminal_info->{DISTRICT_ID};
    $TERMINALS{STREET_ID} = $terminal_info->{STREET_ID};
    $TERMINALS{LOCATION_ID} = $terminal_info->{LOCATION_ID};
  }

  if ($FORM{del}) {
    $Paysys->terminal_del({ ID => $FORM{del} });
    if (!$Paysys->{errno}) {
      $html->message('success', $lang{DELETED}, "$lang{TERMINAL} $lang{DELETED}");
    }
  }

  $TERMINALS{TERMINAL_TYPE} = $html->form_select('TERMINAL', {
    SELECTED    => $TERMINALS{TYPE},
    SEL_LIST    => $Paysys->terminal_type_list({ NAME => '_SHOW' }),
    SEL_KEY     => 'id',
    SEL_VALUE   => 'name',
    # ARRAY_NUM_ID => 1,
    NO_ID       => 1,
    SEL_OPTIONS => { '' => '--' },
    MAIN_MENU   => get_function_index('terminals_type_add'),
  });

  $TERMINALS{STATUS} = $html->form_select('STATUS', {
    SELECTED     => $TERMINALS{STATUS},
    SEL_ARRAY    => \@TERMINAL_STATUS,
    ARRAY_NUM_ID => 1,
    SEL_OPTIONS  => { '' => '--' },
    # MAIN_MENU    => get_function_index('terminals_type_add'),
  });

  require Address;
  Address->import();
  my $Address = Address->new($db, $admin, \%conf);
  my %user_pi = ();
  if ($TERMINALS{DISTRICT_ID}) {
    $user_pi{ADDRESS_DISTRICT} = ($Address->district_info({ ID => $TERMINALS{DISTRICT_ID} }))->{NAME};
  }

  if ($TERMINALS{STREET_ID}) {
    $user_pi{ADDRESS_STREET} = ($Address->street_info({ ID => $TERMINALS{STREET_ID} }))->{NAME};
  }

  if ($TERMINALS{LOCATION_ID}) {
    $user_pi{ADDRESS_BUILD} = ($Address->build_info({ ID => $TERMINALS{LOCATION_ID} }))->{NUMBER};
  }

  $TERMINALS{ADRESS_FORM} = $html->tpl_show(
    templates('form_address_search'),
    {
      %user_pi,
      DISTRICT_ID => $TERMINALS{DISTRICT_ID},
      STREET_ID   => $TERMINALS{STREET_ID},
      LOCATION_ID => $TERMINALS{LOCATION_ID},
    },
    { OUTPUT2RETURN => 1 }
  );

  my @WEEKDAYS_WORK = ();
  if ($TERMINALS{WORK_DAYS}) {
    my $bin = sprintf("%b", int $TERMINALS{WORK_DAYS});
    @WEEKDAYS_WORK = split(//, $bin);
  }

  my $count = 1;
  foreach my $day (@WEEKDAYS) {
    next if (length $day > 4);
    my $checkbox = $html->form_input('WEEK_DAYS', $count, {
      class => 'list-checkbox',
      TYPE  => 'checkbox',
      STATE => $WEEKDAYS_WORK[$count - 1] ? $WEEKDAYS_WORK[$count - 1] : 0,
    }) . " " . $day;

    my $div_checkbox = $html->element('li', $checkbox, { class => 'list-group-item' });

    $TERMINALS{WEEK_DAYS1} .= $div_checkbox if ($count < 5);
    $TERMINALS{WEEK_DAYS2} .= $div_checkbox if ($count > 4);
    $count++;
  }

  $TERMINALS{START_WORK} = $html->form_timepicker('START_WORK', $TERMINALS{START_WORK});
  $TERMINALS{END_WORK} = $html->form_timepicker('END_WORK', $TERMINALS{END_WORK});

  $html->tpl_show(_include('paysys_terminals_add', 'Paysys'), \%TERMINALS);
  result_former({
    INPUT_DATA      => $Paysys,
    FUNCTION        => 'terminal_list',
    DEFAULT_FIELDS  => 'ID, TYPE, COMMENT, STATUS, DIS_NAME, ST_NAME, BD_NUMBER',
    FUNCTION_FIELDS => 'change,del',
    SKIP_USER_TITLE => 1,
    EXT_TITLES      => {
      id        => '#',
      type      => $lang{TYPE},
      comment   => $lang{COMMENTS},
      status    => $lang{STATUS},
      dis_name  => $lang{DISTRICT},
      st_name   => $lang{STREET},
      bd_number => $lang{BUILD},
    },
    TABLE           => {
      width   => '100%',
      caption => "$lang{TERMINALS}",
      qs      => $pages_qs,
      pages   => $Paysys->{TOTAL},
      ID      => 'PAYSYS_TERMINLS',
      MENU    => "$lang{ADD}:add_form=1&index=" . $index . ':add' . ";",
      EXPORT  => 1
    },
    MAKE_ROWS       => 1,
    TOTAL           => 1
  });

  return 1;
}

#**********************************************************
=head2 terminals_type_add() - add new terminal types

=cut
#**********************************************************
sub paysys_configure_terminals_type {
  my %TERMINALS = ();

  $TERMINALS{ACTION} = 'add';
  $TERMINALS{BTN} = $lang{ADD};

  if ($FORM{ACTION} && $FORM{ACTION} eq 'add') {
    $Paysys->terminals_type_add({ %FORM });

    if (!$Paysys->{errno}) {
      $html->message('info', $lang{ADDED}, $lang{SUCCESS});

      if ($FORM{UPLOAD_FILE}) {
        upload_file($FORM{UPLOAD_FILE}, {
          PREFIX    => '/terminals/',
          FILE_NAME => 'terminal_' . $Paysys->{INSERT_ID} . '.png', });
      }
    }
    else {
      $html->message('err', $lang{ERROR});
    }
  }
  elsif ($FORM{ACTION} && $FORM{ACTION} eq 'change') {
    $Paysys->terminal_type_change({ %FORM });

    if (!$Paysys->{errno}) {
      $html->message('info', $lang{CHANGED}, $lang{SUCCESS});
      if ($FORM{UPLOAD_FILE}) {
        upload_file($FORM{UPLOAD_FILE}, {
          PREFIX    => '/terminals/',
          FILE_NAME => 'terminal_' . $FORM{ID} . '.png',
          REWRITE   => 1
        });
      }
    }
    else {
      $html->message('err', $lang{ERROR});
    }
  }

  if ($FORM{del}) {
    $Paysys->terminal_type_delete({ ID => $FORM{del} });

    if (!$Paysys->{errno}) {
      $html->message('info', $lang{DELETED}, $lang{SUCCESS});
      my $filename = "$conf{TPL_DIR}/terminals/terminal_$FORM{del}.png";
      if (-f $filename) {
        unlink("$filename") or die "Can't delete $filename:  $!\n";
      }
    }
    else {
      $html->message('err', $lang{ERROR});
    }
  }

  if ($FORM{chg}) {
    $TERMINALS{ACTION} = 'change';
    $TERMINALS{BTN} = "$lang{CHANGE}";

    my $type_info = $Paysys->terminal_type_info($FORM{chg});

    $TERMINALS{COMMENT} = $type_info->{COMMENT};
    $TERMINALS{NAME} = $type_info->{NAME};
    $TERMINALS{ID} = $FORM{chg}
  }

  $html->tpl_show(_include('paysys_terminals_type_add', 'Paysys'), \%TERMINALS);

  result_former({
    INPUT_DATA      => $Paysys,
    FUNCTION        => 'terminal_type_list',
    DEFAULT_FIELDS  => 'ID, NAME, COMMENT',
    FUNCTION_FIELDS => 'change,del',
    SKIP_USER_TITLE => 1,
    EXT_TITLES      => {
      id      => '#',
      name    => $lang{NAME},
      comment => $lang{COMMENTS},

    },
    TABLE           => {
      width   => '100%',
      caption => "$lang{TERMINALS} $lang{TYPE}",
      qs      => $pages_qs,
      pages   => $Paysys->{TOTAL},
      ID      => 'PAYSYS_TERMINLS_TYPES',
      EXPORT  => 1
    },
    MAKE_ROWS       => 1,
    TOTAL           => 1
  });

  return 1;
}

#**********************************************************
=head2 paysys_configure_main()

=cut
#**********************************************************
sub paysys_configure_main {
  if ($FORM{migrate_v3_to_v2}) {
    paysysV2_toV3();
  }

  if (!$conf{PAYSYS_NEW_SETTINGS} && !$FORM{migrate_v3_to_v2}) {
    $html->message('error', $lang{PAYSYS_V3},
      $html->button($lang{CHANGE}, "index=$index&migrate_v3_to_v2=1", {ex_params => "style='font-weight: bold;font-size:20px;'"}));
    return 1;
  }

  my $btn_value = $lang{ADD};
  my $btn_name = 'add_paysys';
  my $connect_system_info = {};

  if ($FORM{create_payment_method}) {
    require Payments;
    Payments->import();
    my $Payments = Payments->new($db, $admin, \%conf);

    my $list_type = translate_list($Payments->payment_type_list({ COLS_NAME => 1 }));
    my @all_payment_types = map {$_->{name}} @$list_type;

    if (!in_array($FORM{NAME}, \@all_payment_types)) {
      $Payments->payment_type_add({
        NAME  => $FORM{NAME} || '',
        COLOR => '#000000'
      });
    }

    $FORM{PAYMENT_METHOD} = $Payments->{INSERT_ID} if ($Payments->{INSERT_ID});
  }

  if ($FORM{add_paysys}) {
    my $list = $Paysys->paysys_connect_system_list({
      SHOW_ALL_COLUMNS => '_SHOW',
      STATUS           => 1,
      COLS_NAME        => 1,
      PAGE_ROWS        => 100
    });

    foreach my $item (@$list) {
      if ($item->{paysys_id} eq $FORM{PAYSYS_ID}) {
        $html->message('error', $lang{ERROR}, "$lang{EXIST} ID");
        return 0;
      }

      if (uc $item->{name} eq uc $FORM{NAME}) {
        $html->message('error', $lang{ERROR}, "$lang{EXIST} $lang{NAME}");
        return 0;
      }
    }

    $Paysys->paysys_connect_system_add({
      %FORM,
      PAYSYS_IP => $FORM{IP},
    });

    if (!_error_show($Paysys)) {
      $html->message('info', $lang{SUCCESS}, $lang{ADDED});
    }
  }
  elsif ($FORM{change}) {
    my $list = $Paysys->paysys_connect_system_list({
      SHOW_ALL_COLUMNS => '_SHOW',
      STATUS           => 1,
      COLS_NAME        => 1,
      PAGE_ROWS        => 100
    });

    my $payment_system = {};

    foreach my $item (@$list) {
      if ($FORM{PAYSYS_ID} && $item->{paysys_id} eq $FORM{PAYSYS_ID} && $FORM{ID} != $item->{id}) {
        $html->message('error', $lang{ERROR}, "$lang{EXIST} ID");
        return 0;
      }

      if ($FORM{NAME} && $payment_system->{name} && uc $item->{name} eq uc $FORM{NAME} && $FORM{ID} != $item->{id}) {
        $html->message('error', $lang{ERROR}, "$lang{EXIST} $lang{NAME}");
        return 0;
      }

      $payment_system = $item if ($FORM{ID} && $FORM{ID} == $item->{id});
    }

    $Paysys->paysys_connect_system_change({
      %FORM,
      PAYSYS_IP => $FORM{IP},
    });

    if (!_error_show($Paysys)) {
      $html->message('info', $lang{SUCCESS}, $lang{CHANGED});
      if ($FORM{NAME} && $payment_system->{name} && uc $payment_system->{name} ne uc $FORM{NAME}) {
        _paysys_system_name_change({
          id     => $FORM{ID},
          name   => $FORM{NAME},
          module => $payment_system->{module},
        });
      }
    }
  }
  elsif ($FORM{chg}) {
    $btn_value = $lang{CHANGE};
    $btn_name = 'change';
    $FORM{add_form} = 1;

    $connect_system_info = $Paysys->paysys_connect_system_info({
      ID               => $FORM{chg},
      SHOW_ALL_COLUMNS => 1,
      COLS_NAME        => 1,
      COLS_UPPER       => 1,
    });
  }
  elsif ($FORM{del} && $FORM{COMMENTS}) {
    $Paysys->paysys_connect_system_delete({
      ID => $FORM{del},
      %FORM
    });

    if (!_error_show($Paysys)) {
      $html->message('info', $lang{SUCCESS}, $lang{DELETED});
    }
  }

  if ($FORM{add_form}) {
    my %params = ();

    if ($btn_name eq 'add_paysys') {
      my ($paysys_select, $json_list) = _paysys_select_systems();
      %params = (
        PAYSYS_SELECT => $paysys_select,
        JSON_LIST     => $json_list,
      );
    }
    else {
      %params = (
        ACTIVE      => ($connect_system_info) ?  $connect_system_info->{status} : undef,
        IP          => ($connect_system_info) ? $connect_system_info->{paysys_ip} : undef,
        PRIORITY    => ($connect_system_info) ? $connect_system_info->{priority} : undef,
        HIDE_SELECT => 'hidden',
        ID          => $FORM{chg},
        DOCS        => $FORM{DOCS}
      );
    }

    $html->tpl_show(_include('paysys_connect_system', 'Paysys'), {
      BTN_VALUE          => $btn_value,
      BTN_NAME           => $btn_name,
      ($connect_system_info && ref $connect_system_info eq "HASH" ? %$connect_system_info : ()),
      PAYMENT_METHOD_SEL => _paysys_select_payment_method({
        PAYMENT_METHOD        => $connect_system_info->{payment_method},
        CREATE_PAYMENT_METHOD => $btn_name eq 'add_paysys' ? 1 : 0,
      }),
      %params
    });
  }

  # table to show all systems in folder
  my $table_for_systems = $html->table({
    width      => '100%',
    title      =>
      [ '#', $lang{PAY_SYSTEM}, $lang{MODULE}, $lang{VERSION}, $lang{STATUS}, 'IP', $lang{PRIORITY}, $lang{PERIODIC}, $lang{REPORT}, $lang{TEST}, '', '', '' ],
    MENU       => "$lang{ADD}:index=$index&add_form=1:add",
    DATA_TABLE => 1,
    ID         => 'PAYSYS_SYSTEMS'
  });

  my $systems = $Paysys->paysys_connect_system_list({
    SHOW_ALL_COLUMNS => 1,
    COLS_NAME        => 1,
    PAGE_ROWS        => 100,
  });

  foreach my $payment_system (@$systems) {
    my $Paysys_plugin = _configure_load_payment_module($payment_system->{module});
    # check if module already on new version and has get_settings sub
    if ($Paysys_plugin->can('get_settings')) {
      my %settings = $Paysys_plugin->get_settings();

      my $status = $payment_system->{status} || 0;
      my $paysys_name = $payment_system->{name} || '';
      my $id = $payment_system->{id} || 0;
      my $paysys_id = $payment_system->{paysys_id} || 0;
      my $paysys_ip = $payment_system->{paysys_ip} || '';
      my $priority = $payment_system->{priority} || 0;

      $status = (!($status) ? $html->color_mark($lang{DISABLE}, 'danger') : $html->color_mark($lang{ENABLE}, 'success'));

      my $merch_index = get_function_index('paysys_add_configure_groups');
      my $merchant_button = $html->button($lang{MERCHANT_BUTTON},
        "index=$merch_index&MODULE=$payment_system->{module}&PAYSYSTEM_ID=$paysys_id",
        { class => 'btn btn-primary btn-sm' });
      my $change_button = $html->button($lang{CHANGE},
        "index=$index&MODULE=$payment_system->{module}&chg=$id&PAYSYSTEM_ID=$paysys_id&DOCS=" . ($settings{DOCS} || q{}),
        { class => 'change' });
      my $delete_button = $html->button($lang{DEL},
        "index=$index&MODULE=$payment_system->{module}&del=$id&PAYSYSTEM_ID=$paysys_id",
        { class => 'del', MESSAGE => "$lang{DEL} $paysys_name", });
      my $test_button = '';
      if ($Paysys_plugin->can('has_test') && $payment_system->{status} == 1) {
        my $test_index = get_function_index('paysys_main_test');
        $test_button = $html->button($lang{START_PAYSYS_TEST},
          "index=$test_index&MODULE=$payment_system->{module}&PAYSYSTEM_ID=$paysys_id",
          { class => 'btn btn-success btn-sm' });
      }
      elsif ($Paysys_plugin->can('has_test')) {
        $test_button = $lang{PAYSYS_MODULE_NOT_TURNED_ON};
      }
      else {
        $test_button = $lang{NOT_EXIST};
      }

      $table_for_systems->addrow(
        $paysys_id,
        $paysys_name,
        $payment_system->{module},
        $settings{VERSION},
        $status,
        $paysys_ip,
        $priority,
        $Paysys_plugin->can('periodic') ? $html->color_mark($lang{YES}, 'success') : $html->color_mark($lang{NO}, '#f04'),
        $Paysys_plugin->can('report') ? $html->color_mark($lang{YES}, 'success') : $html->color_mark($lang{NO}, '#f04'),
        $test_button,
        $merchant_button,
        $change_button,
        $delete_button,
      );
    }
  }

  print $table_for_systems->show();

  return 1;
}

#**********************************************************
=head2 paysys_add_configure_groups()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub paysys_add_configure_groups {

  my $btn_value = $lang{ADD};
  my $btn_name = 'add_merchant';
  if ($FORM{add_merchant}) {
    if ($FORM{MERCHANT_NAME} && $FORM{SYSTEM_ID}) {
      $Paysys->merchant_settings_add({
        MERCHANT_NAME => $FORM{MERCHANT_NAME},
        SYSTEM_ID     => $FORM{SYSTEM_ID},
        DOMAIN_ID     => $FORM{PAYSYS_DOMAIN_ID} || 0,
      });

      if (!$Paysys->{errno}) {
        my $merchant_id = $Paysys->{INSERT_ID};
        foreach my $key (keys %FORM) {
          next if (!$key);
          if ($key =~ /PAYSYS_/) {
            $FORM{$key} =~ s/[\n\r]//g;
            $FORM{$key} =~ s/"/\\"/g;
            $Paysys->merchant_params_add({
              PARAM       => $key,
              VALUE       => $FORM{$key},
              MERCHANT_ID => $merchant_id,
              DOMAIN_ID   => $FORM{PAYSYS_DOMAIN_ID} || 0,
            });

            if ($Paysys->{errno}) {
              return $html->message('err', $lang{ERROR}, "Error with $key : $FORM{$key}");
            }
          }
        }
      }
    }

    $html->message('info', $lang{ADDED});
  }
  elsif ($FORM{change}) {
    if ($FORM{MERCHANT_NAME} && $FORM{SYSTEM_ID}) {
      $Paysys->merchant_settings_change({
        ID            => $FORM{MERCHANT_ID},
        MERCHANT_NAME => $FORM{MERCHANT_NAME},
        SYSTEM_ID     => $FORM{SYSTEM_ID},
        DOMAIN_ID     => $FORM{PAYSYS_DOMAIN_ID} || 0,
      });

      my $merchant_id = $FORM{MERCHANT_ID};
      if (!$Paysys->{errno}) {
        _paysys_event_notify({
          TITLE    => $lang{EVENT_MERCHANT_ADDED_TITLE},
          COMMENTS => vars2lang($lang{EVENT_MERCHANT_ADDED_MESSAGE}, { MERCHANT_ID => $merchant_id, MERCHANT_NAME => $FORM{MERCHANT_NAME} || '' }),
        });
        del_settings_to_config({ MERCHANT_ID => $merchant_id, DEL_ALL => 1 });
        $Paysys->merchant_params_delete({ MERCHANT_ID => $merchant_id });
        if (!$Paysys->{errno}) {
          foreach my $key (keys %FORM) {
            next if (!$key);
            if ($key =~ /PAYSYS_/) {
              $FORM{$key} =~ s/[\n\r]//g;
              $FORM{$key} =~ s/"/\\"/g;

              $Paysys->merchant_params_add({
                PARAM       => $key,
                VALUE       => $FORM{$key},
                MERCHANT_ID => $merchant_id,
                DOMAIN_ID   => $FORM{PAYSYS_DOMAIN_ID} || 0,
              });

              if ($Paysys->{errno}) {
                return $html->message('err', $lang{ERROR}, "Error with $key : $FORM{$key}");
              }
            }
          }

          add_settings_to_config({
            MERCHANT_ID    => $merchant_id,
            SYSTEM_ID      => $FORM{SYSTEM_ID},
            PARAMS_CHANGED => 1
          });

          $html->message('info', $lang{CHANGED});
        }
        else {
          return $html->message('err', $lang{ERROR}, "Error : $Paysys->{errno}");
        }
      }
    }
  }
  elsif ($FORM{chgm}) {
    $btn_value = $lang{CHANGE};
    $btn_name = 'change';
    $FORM{add_form} = 1;
    $FORM{merchant_name} =~ s/\\(['"]+)/$1/g;
  }
  elsif ($FORM{del_merch} && $FORM{COMMENTS}) {
    _paysys_event_notify({
      TITLE    => $lang{EVENT_MERCHANT_DELETED_TITLE},
      COMMENTS => vars2lang($lang{EVENT_MERCHANT_DELETED_MESSAGE}, { MERCHANT_ID => $FORM{del_merch}, COMMENTS => $FORM{COMMENTS} }),
    });
    del_settings_to_config({ MERCHANT_ID => $FORM{del_merch}, DEL_ALL => 1 });
    $Paysys->merchant_settings_delete({ ID => $FORM{del_merch} });
    $Paysys->merchant_params_delete({ MERCHANT_ID => $FORM{del_merch} });

    if (!$Paysys->{errno}) {
      $html->message('info', $lang{DELETED});
    }
  }

  if ($FORM{add_form}) {
    my ($paysys_select, $json_list) = _paysys_select_merchant_config($FORM{system_name}, $FORM{chgm}, { change => $FORM{chgm} });
    my %params = (HIDE_DOMAIN_SEL => 'hidden', DOMAIN_SEL => '');

    if ($FORM{chgm}) {
      %params = (
        MERCHANT_NAME   => $FORM{merchant_name} || '',
        HIDE_SELECT     => 'hidden',
        MERCHANT_ID     => $FORM{chgm} || '',
        HIDE_DOMAIN_SEL => 'hidden',
        DOMAIN_SEL      => ''
      );
    }

    my $acc_keys = $html->form_select('KEYS', {
      SELECTED    => '',
      NO_ID       => 1,
      SEL_OPTIONS => { '' => '--' },
    });

    if ($conf{MULTIDOMS_DOMAIN_ID} && !$admin->{DOMAIN_ID}) {
      require Multidoms;
      Multidoms->import();

      my $domain = 0;
      if ($FORM{chgm}) {
        my $list = $Paysys->merchant_settings_list({
          ID        => $FORM{chgm},
          COLS_NAME => 1,
          DOMAIN_ID => '_SHOW'
        });

        $domain = $list->[0]->{domain_id} || 0;
      }

      my $Domains = Multidoms->new($db, $admin, \%conf);
      $params{HIDE_DOMAIN_SEL} = '';
      $params{DOMAIN_SELECT} = $html->form_select('PAYSYS_DOMAIN_ID', {
        SELECTED    => $domain,
        SEL_LIST    => $Domains->multidoms_domains_list({
          ID        => ($admin->{DOMAIN_ID}) ? $admin->{DOMAIN_ID} : undef,
          PAGE_ROWS => 100000,
          COLS_NAME => 1 }),
        SEL_OPTIONS => { 0 => $lang{ALL} },
        NO_ID       => 0
      });
    }

    my $payment_methods = get_payment_methods();
    $payment_methods->{' '} = ' ';

    my $payment_methods_sel = $html->form_select('PAYMENT_METHOD', {
      SEL_HASH => $payment_methods,
      NO_ID    => 1,
      ID       => 'PAYMENT_METHOD',
      SELECTED => ' '
    });

    $payment_methods_sel =~ s/[\n\r]//gm;
    $html->tpl_show(_include('paysys_merchant_config_add', 'Paysys'), {
      BTN_VALUE             => $btn_value,
      BTN_NAME              => $btn_name,
      PAYSYS_SELECT         => $paysys_select,
      JSON_LIST             => $json_list,
      ACCOUNT_KEYS_SELECT   => $acc_keys,
      PAYMENT_METHOD_SELECT => $payment_methods_sel,
      %params
    });

    return 1;
  }

  my $connected_payment_systems = $Paysys->paysys_connect_system_list({
    SHOW_ALL_COLUMNS => 1,
    STATUS           => 1,
    COLS_NAME        => 1,
    PAGE_ROWS        => 40
  });

  if (ref $connected_payment_systems ne 'ARRAY' || !scalar(@$connected_payment_systems)) {
    $html->message('err', 'No payments system connected');
    return 1;
  }

  my $PAYSYSTEM_ID = 0;
  if($FORM{PAYSYSTEM_ID}){
    $PAYSYSTEM_ID = $FORM{PAYSYSTEM_ID};
  }

  my $list = $Paysys->merchant_settings_list({
    ID             => '_SHOW',
    MERCHANT_NAME  => '_SHOW',
    SYSTEM_ID      => '_SHOW',
    PAYSYSTEM_NAME => '_SHOW',
    MODULE         => '_SHOW',
    PAYSYS_ID      => $PAYSYSTEM_ID,
    COLS_NAME      => 1
  });

  my $table = $html->table({
    ID         => 'MERCHANT_TABLE',
    caption    => $html->button("", "get_index=paysys_add_configure_groups&add_form=1&header=2",
      {
        LOAD_TO_MODAL => 1,
        class         => 'btn-sm fa fa-plus login_b text-success no-padding',
      }) . " $lang{PAYSYS_SETTINGS_FOR_MERCHANTS}",
    width      => '100%',
    title      => [ '#', $lang{MERCHANT_NAME2}, $lang{PAY_SYSTEM}, $lang{MODULE}, "$lang{PARAMS} $lang{PAY_SYSTEM}", '', '' ],
    DATA_TABLE => 1,
  });

  foreach my $system (@$connected_payment_systems) {
    foreach my $item (@$list) {
      next if (!$item->{id});
      next if (!$item->{system_id} || !$system->{id} || $item->{system_id} != $system->{id});

      my $params = $Paysys->merchant_params_info({ MERCHANT_ID => $item->{id} });
      my $table_params = $html->table({
        width      => '100%',
        ID         => 'PAYSYS_MERCHANT_PARAMS',
        caption    => "$lang{PARAMS} $lang{PAY_SYSTEM}",
        HIDE_TABLE => 1
      });

      foreach my $param (keys %$params) {
        next if (!$param);
        $table_params->addrow($param, $params->{$param});
      }

      my $system_id = $item->{system_id} || $item->{paysys_id};
      my $merchant_name = $item->{merchant_name} || $item->{name};

      my $change_link = "get_index=paysys_add_configure_groups&chgm=$item->{id}&systen_id=$system_id&merchant_name=$merchant_name&"
        . "system_name=$item->{name}&header=2";

      $change_link =~ s/'/\%27/g;
      $table->addrow(
        $item->{id},
        $item->{merchant_name},
        $item->{name},
        $item->{module},
        $table_params->show(),
        $html->button("", $change_link,
          { LOAD_TO_MODAL => 1,
            ADD_ICON      => "fa fa-pencil-alt",
            CONFIRM       => $lang{CONFIRM},
            ex_params     => "data-tooltip='$lang{CHANGE}' data-tooltip-position='top'"
          }),
        $html->button($lang{DEL}, "index=$index&del_merch=$item->{id}", { MESSAGE => "$lang{DEL} $merchant_name?", class => 'del' })
      );
    }
  }

  print $table->show();

  print paysys_configure_groups(\%FORM);
  print paysys_group_settings(\%FORM);

  return 1;
}

#**********************************************************
=head2 _paysys_select_merchant_config($name, $id, $attr)

  Arguments:
    $name
    $id
    $attr

=cut
#**********************************************************
sub _paysys_select_merchant_config {
  my ($name, $id, $attr) = @_;

  my @array = ();
  my $list = $Paysys->paysys_connect_system_list({
    SHOW_ALL_COLUMNS => 1,
    STATUS           => 1,
    COLS_NAME        => 1,
  });

  my %HASH_TO_JSON = ();
  foreach my $system (@$list) {
    next if ($attr->{change} && $system->{name} ne $name);
    my $Module = _configure_load_payment_module($system->{module});
    if ($Module->can('get_settings')) {
      my $is_inheritance = 0;

      # deep-copy for inheritance modules
      my %settings = $Module->get_settings();
      my %configuration = %{$settings{CONF}};
      $settings{CONF} = \%configuration;

      foreach my $key (keys %{$settings{CONF}}) {
        if ($system->{name} && $key =~ /_NAME_/) {
          $is_inheritance = 1;
          my $name_up = uc($system->{name});
          delete $settings{CONF}{$key};
          $key =~ s/_NAME_/_$name_up\_/;
          $settings{CONF}{$key} = '';
        }
      }

      my $paysys_name = q{};
      if ($is_inheritance) {
        $paysys_name = 'PAYSYS_' . uc $system->{name};
      }
      else {
        my $param_name = (keys %{$settings{CONF}})[0];
        ($paysys_name) = $param_name =~ /^PAYSYS_[^_]+/gm;
      }

      if ($paysys_name) {
        $settings{CONF}{$paysys_name . '_PAYMENT_METHOD'} = $system->{payment_method} || '';
        if ($Module->can('user_portal')) {
          $settings{CONF}{$paysys_name . '_PORTAL_DESCRIPTION'} = '';
          $settings{CONF}{$paysys_name . '_PORTAL_COMMISSION'} = '';
        }
      }

      if ($attr->{change}) {
        my $params = $Paysys->merchant_params_info({ MERCHANT_ID => $id });
        @{$settings{CONF}}{keys %{$settings{CONF}}} = @{$params}{keys %{$settings{CONF}}};
      }

      $settings{SYSTEM_ID} = $system->{id};

      foreach my $key (keys %{$settings{CONF}}) {
        if ($settings{CONF}{$key}) {
          $settings{CONF}{$key} =~ s/\%/&#37;/g;
        }
      }
      $HASH_TO_JSON{$system->{name}} = \%settings;
    }

    if ($system->{name}) {
      push @array, $system->{name};
    }
  }

  my $systems = \@array;
  my $json_list = JSON->new->utf8(0)->encode(\%HASH_TO_JSON);

  return $html->form_select('MODULE', {
    SELECTED    => $name || '',
    SEL_ARRAY   => $systems,
    NO_ID       => 1,
    SEL_OPTIONS => { '' => '--' },
  }), $json_list;
}

#**********************************************************
=head2 paysys_group_settings($attr)

  Arguments:
    $attr -

  Returns:

=cut
#**********************************************************
sub paysys_group_settings {
  my ($attr) = @_;
  if ($attr->{add_settings}) {
    _error_show($Paysys);
  }

  my $connected_payment_systems = $Paysys->paysys_connect_system_list({
    SHOW_ALL_COLUMNS => 1,
    STATUS           => 1,
    COLS_NAME        => 1,
  });

  if (ref $connected_payment_systems ne 'ARRAY' || !scalar(@$connected_payment_systems)) {
    $html->message('err', 'No payments system connected');
    return 1;
  }

  my $groups_list = $Users->groups_list({
    COLS_NAME      => 1,
    DISABLE_PAYSYS => 0,
    GID            => '_SHOW',
    NAME           => '_SHOW',
    DESCR          => '_SHOW',
    ALLOW_CREDIT   => '_SHOW',
    DISABLE_PAYSYS => '_SHOW',
    DISABLE_CHG_TP => '_SHOW',
    USERS_COUNT    => '_SHOW',
    DOMAIN_ID      => $admin->{DOMAIN_ID} || '_SHOW',
  });

  unshift (@{$groups_list}, {
    allow_credit   => '0',
    descr          => 'default',
    disable_chg_tp => '0',
    disable_paysys => '0',
    domain_id      => '0',
    gid            => '0',
    name           => 'default',
    users_count    => '0'
  });

  my @connected_payment_systems = ('#', $lang{GROUPS});
  foreach my $system (@$connected_payment_systems) {
    my $Module = _configure_load_payment_module($system->{module});
    if ($Module->can('user_portal') || $Module->can('user_portal_special')) {
      push(@connected_payment_systems, $system->{name});
    }
  }

  # Show systems in user portal
  my $table_UsPor = $html->table({
    ID      => 'GROUPS_USER_PORTAL_TABLE',
    caption => $lang{SHOW_PAYSYSTEM_IN_USER_PORTAL},
    width   => '100%',
    title   => \@connected_payment_systems,
    # DATA_TABLE => 1 #FIX DATA_TABLE FOR SWITCHES
  });

  my $list_settings = $Paysys->groups_settings_list({
    GID       => '_SHOW',
    PAYSYS_ID => '_SHOW',
    COLS_NAME => 1,
    PAGE_ROWS => 99999,
  });

  my %groups_settings = ();
  foreach my $gid_settings (@$list_settings) {
    $groups_settings{"SETTINGS_$gid_settings->{gid}_$gid_settings->{paysys_id}"} = 1;
  }

  # form rows for table
  foreach my $group (@$groups_list) {
    next if (!$group->{id} && $group->{name} ne 'default');
    next if $group->{disable_paysys} == 1;
    my @rows = ();

    foreach my $system (@$connected_payment_systems) {
      my $Module = _configure_load_payment_module($system->{module});
      if ($Module->can('user_portal') || $Module->can('user_portal_special')) {
        my $input_name = "SETTINGS_$group->{gid}_$system->{paysys_id}";
        if ($attr->{add_settings}) {

          foreach my $gid_settings (@$list_settings) {
            if ($gid_settings->{gid} == $group->{gid} && $gid_settings->{paysys_id} == $system->{paysys_id}) {
              $Paysys->groups_settings_del({
                GID       => $group->{gid},
                PAYSYS_ID => $system->{paysys_id},
              });
            }
            $groups_settings{$input_name} = 0 if (!$Paysys->{errno});
          }
          if (defined $attr->{$input_name} && $attr->{$input_name} == 1) {
            $Paysys->groups_settings_add_user_portal({
              GID       => $group->{gid},
              PAYSYS_ID => $system->{paysys_id},
              REPLACE   => 1
            });
            $groups_settings{$input_name} = 1 if (!$Paysys->{errno});
          }
        }
        my $checkbox .= $html->tpl_show(_include('paysys_group_checkbox', 'Paysys'),
          {
            NAME    => $input_name,
            VALUE   => 1,
            CHECKED => (($groups_settings{$input_name}) ? 'checked' : '')
          },
          { OUTPUT2RETURN => 1 }
        );
        push(@rows, '&nbsp;' . $checkbox);
      }
    }
    $table_UsPor->addrow($group->{gid}, $group->{name}, @rows);
  }
  $table_UsPor->addcardfooter($html->form_input('add_settings', $lang{SAVE}, { TYPE => 'submit' }));

  $html->tpl_show(_include('paysys_group_settings', 'Paysys'));

  return $html->form_main({
    CONTENT => $table_UsPor->show(),
    HIDDEN  => {
      index => "$index",
    },
    NAME    => 'PAYSYS_GROUPS_SETTINGS'
  });
}

#**********************************************************
=head2 paysys_configure_groups($attr)

  Arguments:
    $attr -

  Returns:

=cut
#**********************************************************
sub paysys_configure_groups {

  if (defined $FORM{chg}) {
    return paysys_merchant_select(\%FORM);
  }

  if ($FORM{save_merch_gr}) {
    my $is_first = 1;
    foreach my $key (keys %FORM) {
      next if (!$key);
      if ($key =~ /SETTINGS_/) {
        my (undef, $gid, $system_id) = split('_', $key);
        $Paysys->paysys_merchant_to_groups_delete({ PAYSYS_ID => $system_id, GID => (defined $gid && $gid == 0) ? '0' : $gid, DOMAIN_ID => $admin->{DOMAIN_ID} });

        if ($is_first) {
          _del_group_to_config({ GID => $gid });
          _paysys_event_notify({
            TITLE    => $lang{EVENT_PAYSYS_GROUP_CHANGED_TITLE},
            COMMENTS => vars2lang($lang{EVENT_PAYSYS_GROUP_CHANGED_MESSAGE}, { GID => $gid }),
          });
          $is_first = 0;
        }

        next if ($FORM{"SETTINGS_$gid" . "_$system_id"} eq '');
        $Paysys->paysys_merchant_to_groups_add({
          GID       => $gid,
          PAYSYS_ID => $system_id,
          MERCH_ID  => $FORM{"SETTINGS_$gid" . "_$system_id"}
        });
        if ($Paysys->{errno}) {
          return $html->message('err', $lang{ERROR}, "Error with $key : $FORM{$key}");
        }
        else {
          add_settings_to_config({
            MERCHANT_ID => $FORM{"SETTINGS_$gid" . "_$system_id"},
            GID         => $gid
          });
        }
      }
    }
  }

  if (defined $FORM{clear_set}) {
    _paysys_event_notify({
      TITLE    => $lang{EVENT_PAYSYS_GROUP_DELETED_TITLE},
      COMMENTS => vars2lang($lang{EVENT_PAYSYS_GROUP_DELETED_MESSAGE}, { GID => $FORM{clear_set} }),
    });
    my $_list = $Paysys->merchant_for_group_list({
      PAYSYS_ID => '_SHOW',
      MERCH_ID  => '_SHOW',
      GID       => "$FORM{clear_set}",
      LIST2HASH => 'paysys_id,merch_id'
    });

    foreach my $key (keys %{$_list}) {
      next if (!$key);
      del_settings_to_config({
        MERCHANT_ID => $_list->{$key},
        GID         => (defined $FORM{clear_set} && $FORM{clear_set} == 0) ? '0' : $FORM{clear_set}
      });
      $Paysys->paysys_merchant_to_groups_delete({ PAYSYS_ID => $key, GID => (defined $FORM{clear_set} && $FORM{clear_set} == 0) ? '0' : $FORM{clear_set} });
    }
    $html->message('info', $lang{DELETED});
  }

  my $connected_payment_systems = $Paysys->paysys_connect_system_list({
    SHOW_ALL_COLUMNS => 1,
    STATUS           => 1,
    COLS_NAME        => 1,
  });

  if (ref $connected_payment_systems ne 'ARRAY' || !scalar(@$connected_payment_systems)) {
    $html->message('err', 'No payments system connected');
    return 1;
  }

  my $groups_list = $Users->groups_list({
    COLS_NAME      => 1,
    DISABLE_PAYSYS => 0,
    GID            => '_SHOW',
    NAME           => '_SHOW',
    DESCR          => '_SHOW',
    ALLOW_CREDIT   => '_SHOW',
    DISABLE_PAYSYS => '_SHOW',
    DISABLE_CHG_TP => '_SHOW',
    USERS_COUNT    => '_SHOW',
    DOMAIN_ID      => $admin->{DOMAIN_ID} || '_SHOW',
  });

  push(@{$groups_list}, {
    allow_credit   => '0',
    descr          => 'default',
    disable_chg_tp => '0',
    disable_paysys => '0',
    domain_id      => '0',
    gid            => '0',
    name           => 'default',
    users_count    => '0'
  });

  my @connected_payment_systems = ('#', $lang{GROUPS});
  foreach my $system (@$connected_payment_systems) {
    push(@connected_payment_systems, $system->{name});
  }

  push(@connected_payment_systems, '', '');
  # Table of merchants for groups
  my $table = $html->table({
    ID         => 'GROUPS_GROUP_SETTINGS',
    caption    => "$lang{SELECT_MERCHANT_FOR_GROUP}",
    width      => '100%',
    title      => \@connected_payment_systems,
    DATA_TABLE => 1
  });

  my $list = $Paysys->paysys_merchant_to_groups_info({ COLS_NAME => 1 });

  my %settings_hash = ();
  foreach my $item (@$list) {
    next unless (defined($item->{gid}) && $item->{paysys_id});
    if ($item->{merchant_name}) {
      $settings_hash{$item->{gid}}{$item->{paysys_id}} = $item->{merchant_name};
    }
    else {
      $settings_hash{$item->{gid}}{$item->{paysys_id}} = $item->{name};
    }
  }

  foreach my $group (@$groups_list) {
    next if (!$group->{id} && $group->{name} ne 'default');
    my @rows = ();
    next if ($group->{disable_paysys} && $group->{disable_paysys} == 1);
    foreach my $system (@$connected_payment_systems) {
      if ($settings_hash{$group->{gid}}{$system->{id}}) {
        push(@rows, $settings_hash{$group->{gid}}{$system->{id}});
      }
      else {
        push(@rows, $lang{NOT_EXIST});
      }
    }

    $table->addrow(
      $group->{gid},
      $group->{name},
      @rows,
      $html->button("", "get_index=paysys_configure_groups&header=2&chg=$group->{gid}",
        { LOAD_TO_MODAL => 1,
          ADD_ICON      => "fa fa-pencil-alt",
          CONFIRM       => $lang{CONFIRM},
          ex_params     => "data-tooltip='$lang{CHANGE}' data-tooltip-position='top'"
        }),
      $html->button($lang{DEL}, "index=$index&clear_set=$group->{gid}", { MESSAGE => "$lang{DEL} $lang{FOR} $group->{name}?", class => 'del' }));
  }

  return $html->form_main({
    CONTENT => $table->show(),
    HIDDEN  => {
      index => "$index",
    },
    NAME    => 'PAYSYS_GROUP_SETTINGS'
  });
}

#**********************************************************
=head2 paysys_merchant_select()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub paysys_merchant_select {
  my ($attr) = @_;
  my $group = ();

  if (defined $attr->{chg} && $attr->{chg} != 0) {
    $group = $Users->groups_list({
      GID            => '_SHOW',
      NAME           => '_SHOW',
      DESCR          => '_SHOW',
      ALLOW_CREDIT   => '_SHOW',
      DISABLE_PAYSYS => '_SHOW',
      DISABLE_CHG_TP => '_SHOW',
      USERS_COUNT    => '_SHOW',
      GID            => $attr->{chg},
      DOMAIN_ID      => $admin->{DOMAIN_ID} || '_SHOW',
      COLS_NAME      => 1,
    });
    $group = $group->[0];
  }
  else {
    $group->{name} = 'default';
  }

  my $connected_payment_systems = $Paysys->paysys_connect_system_list({
    SHOW_ALL_COLUMNS => 1,
    STATUS           => 1,
    COLS_NAME        => 1,
  });

  my $list = $Paysys->merchant_settings_list({
    ID             => '_SHOW',
    MERCHANT_NAME  => '_SHOW',
    SYSTEM_ID      => '_SHOW',
    PAYSYSTEM_NAME => '_SHOW',
    MODULE         => '_SHOW',
    COLS_NAME      => 1
  });

  my $paysystem_sel = qq{};
  foreach my $system (@$connected_payment_systems) {
    next if (!$system);
    my %merch_select_hash = ();
    my $select_name = qq{};
    my $selected_val = qq{};
    my $selected_values = $Paysys->merchant_for_group_list({
      GID       => $attr->{chg},
      PAYSYS_ID => $system->{id},
      MERCH_ID  => '_SHOW',
      LIST2HASH => 'paysys_id,merch_id'
    });

    foreach my $merch (@$list) {
      if ($merch->{system_id} && $merch->{system_id} eq $system->{id}) {
        $selected_val = $selected_values->{$merch->{system_id}} || '';
        $select_name = qq{SETTINGS_$attr->{chg}_$system->{id}};
        $merch_select_hash{$merch->{id}} = $merch->{merchant_name};
      }
    }

    $paysystem_sel .= $html->tpl_show(_include('paysys_select_for_group', 'Paysys'), {
      LABEL_NAME      => $system->{name},
      MERCHANT_SELECT => $html->form_select(
        $select_name,
        {
          SELECTED => $selected_val,
          SEL_HASH => { '' => '', %merch_select_hash },
          NO_ID    => 1
        }
      )
    }, { OUTPUT2RETURN => 1 });
  }

  $html->tpl_show(_include('paysys_merchants_for_groups', 'Paysys'), {
    GROUP_NAME    => $group->{name},
    GROUP_ID      => $attr->{chg},
    PAYSYSTEM_SEL => $paysystem_sel,
    INDEX         => get_function_index('paysys_add_configure_groups')
  });

  return 1;
}

#**********************************************************s
=head2 add_settings_to_config($attr)

  Arguments:
    $attr -
      SYSTEM_ID
      PARAMS_CHANGED
      MERCHANT_ID
      GID

  Returns:

=cut
#**********************************************************
sub add_settings_to_config {
  my ($attr) = @_;

  my $Config = Conf->new($db, $admin, \%conf);

  if ($attr->{SYSTEM_ID} && $attr->{PARAMS_CHANGED}) {
    my $gr_list = $Paysys->merchant_for_group_list({
      PAYSYS_ID => $attr->{SYSTEM_ID},
      MERCH_ID  => $attr->{MERCHANT_ID},
      GID       => '_SHOW',
      LIST2HASH => 'gid,merch_id'
    });

    while (my ($gid, $merch_id) = each(%{$gr_list})) {
      add_settings_to_config({
        MERCHANT_ID => $merch_id,
        GID         => $gid
      });
    }

    return 1;
  }

  my $list = $Paysys->merchant_params_info({ MERCHANT_ID => $attr->{MERCHANT_ID} });

  foreach my $key (keys %{$list}) {
    if (defined $attr->{GID} && $attr->{GID} != 0) {
      $Config->config_add({
        PARAM     => $key . "_$attr->{GID}",
        VALUE     => $list->{$key},
        REPLACE   => 1,
        PAYSYS    => 1
      });
    }
    else {
      $Config->config_add({
        PARAM     => $key,
        VALUE     => $list->{$key},
        REPLACE   => 1,
        PAYSYS    => 1
      });
    }
  }

  return 1;
}

#**********************************************************
=head2 del_settings_to_config($attr)

  Arguments:
    $attr -
      GID
      MERCHANT_ID
      DEL_ALL

  Returns:

=cut
#**********************************************************
sub del_settings_to_config {
  my ($attr) = @_;
  my $Config = Conf->new($db, $admin, \%conf);

  my $list = $Paysys->merchant_params_info({ MERCHANT_ID => $attr->{MERCHANT_ID} });

  if ($attr->{DEL_ALL}) {
    my $gr_list = $Paysys->merchant_for_group_list({
      MERCH_ID  => $attr->{MERCHANT_ID},
      GID       => '_SHOW',
      COLS_NAME => 1
    });

    foreach my $group (@{$gr_list}) {
      foreach my $key (keys %{$list}) {
        my $del_val = $key . (($group->{gid}) ? "_$group->{gid}" : '');
        $Config->config_del($del_val, { DEL_WITH_DOMAIN => 1, DOMAIN_ID => $FORM{PAYSYS_DOMAIN_ID} || 0 });
      }
    }
  }
  else {
    foreach my $key (keys %{$list}) {
      if (defined $attr->{GID} && $attr->{GID} != 0) {
        $Config->config_del($key . "_$attr->{GID}", { DEL_WITH_DOMAIN => 1, DOMAIN_ID => $FORM{PAYSYS_DOMAIN_ID} || 0 });
      }
      else {
        $Config->config_del($key, { DEL_WITH_DOMAIN => 1, DOMAIN_ID => $FORM{PAYSYS_DOMAIN_ID} || 0 });
      }
    }
  }

  return 1;
}

#**********************************************************
=head2 _del_group_to_config($attr)

  Arguments:
    $attr -
      GID

  Returns:

=cut
#**********************************************************
sub _del_group_to_config {
  my ($attr) = @_;
  my $Config = Conf->new($db, $admin, \%conf);

  my $list_systems = $Paysys->paysys_connect_system_list({
    PAYSYS_ID => '_SHOW',
    COLS_NAME        => 1,
  });

  foreach my $systems (@{$list_systems}) {
    my $list_merchants = $Paysys->merchant_settings_list({
      ID             => '_SHOW',
      PAYSYS_ID      => $systems->{paysys_id},
      COLS_NAME      => 1
    });

    if ($list_merchants) {
      my $params_list = $Paysys->merchant_params_info({ MERCHANT_ID => $list_merchants->[0]->{id} });
      foreach my $param (keys %{$params_list}) {
        $Config->config_del($param . "_$attr->{GID}", { DEL_WITH_DOMAIN => 1, DOMAIN_ID => $FORM{PAYSYS_DOMAIN_ID} || 0 });
      }
    }
  }
  return 1;
}

#**********************************************************
=head2 _paysys_read_folder_systems()

  Arguments:
     -

  Returns:
    \@systems - present modules in folder
=cut
#**********************************************************
sub _paysys_read_folder_systems {
  my $paysys_folder = "$base_dir" . 'AXbills/modules/Paysys/systems/';

  # read all .pm in folder
  my @systems = ();
  opendir(my $folder, $paysys_folder);
  while (my $filename = readdir $folder) {
    if ($filename =~ /pm$/) {
      push(@systems, $filename);
    }
  }
  closedir $folder;

  return \@systems
}

#**********************************************************
=head2 paysysV2_toV3() function for migration from V2 to V3

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub paysysV2_toV3 {

  if (_create_paysys_tables()) {
    my $list = $Paysys->paysys_connect_system_list({
      SHOW_ALL_COLUMNS => 1,
      STATUS           => 1,
      COLS_NAME        => 1,
    });

    my $Config = Conf->new($db, $admin, \%conf);

    $Config->config_add({
      PARAM   => 'PAYSYS_NEW_SETTINGS',
      VALUE   => 1,
      REPLACE => 1
    });

    foreach my $system (@$list) {
      my %merchants = ();
      my $Module = _configure_load_payment_module($system->{module});
      if ($Module->can('get_settings')) {
        my $name = uc($system->{name});
        my $config_list_params = $Config->config_list({ PARAM => "PAYSYS_$name\_*", COLS_NAME => 1 });

        foreach my $param (@{$config_list_params}) {
          my ($group) = $param->{param} =~ /(\d+)(?!.*\d)/;
          $param->{param} =~ s/_(\d+)(?!.*\d)//;
          $merchants{$group || 0}{$param->{param}} = $param->{value};
        }

        foreach my $merchant (keys %merchants) {
          $Paysys->merchant_settings_add({
            MERCHANT_NAME => $name . int(rand(1000)),
            SYSTEM_ID     => $system->{id},
          });

          my $merchant_id = $Paysys->{INSERT_ID};
          foreach my $key (keys %{$merchants{$merchant}}) {
            next if (!$key);
            if ($key =~ /PAYSYS_/) {
              $merchants{$merchant}{$key} =~ s/[\n\r]//g;
              $merchants{$merchant}{$key} =~ s/"/\\"/g;
              $Paysys->merchant_params_add({
                PARAM       => $key,
                VALUE       => $merchants{$merchant}{$key},
                MERCHANT_ID => $merchant_id
              });
            }
          }

          $Paysys->paysys_merchant_to_groups_add({
            GID       => $merchant || 0,
            PAYSYS_ID => $system->{id},
            MERCH_ID  => $merchant_id
          });
        }
      }
    }
  }

  return 1;
}

#**********************************************************
=head2 _create_paysys_tables() create Paysys sql tables

=cut
#**********************************************************
sub _create_paysys_tables {
  my $paysys_dump = "$base_dir" . 'db/Paysys.sql';
  my $content = '';

  if (-e $paysys_dump) {
    open(my $fh, '<', $paysys_dump);
    while (<$fh>) {
      $_ = "\n" if ($_ =~ /(?:REPLACE|INSERT|SET SESSION|COMMIT).*;/);
      $_ = "\n" if ($_ =~ /^DELIMITER/);
      $content .= $_;
    }

    $content =~ s/^CREATE FUNCTION(.*?) END\|$//gms;
    $content =~ s/^CREATE UNIQUE(.*?);\s?$//gms;
    $content =~ s/^CREATE INDEX(.*?);\s?$//gms;
    $content =~ s/^REPLACE INTO(.*?);\s?$//gms;
    $content =~ s/^INSERT INTO(.*?);\s?$//gms;
    $content =~ s/^UPDATE(.*?);\s?$//gms;
    $content =~ s/^DELETE(.*?);\s?$//gms;
    $content =~ s/\,\s*FOREIGN KEY \(\`.*\`\) REFERENCES \`.*\` \(\`.*?\`\)(?: ON  ?(?:UPDATE|DELETE) ?(?:CASCADE|DELETE|RESTRICT))?//g;
    $content =~ s/\,\s*FOREIGN KEY(.*) ?(?:DELETE)? (?:CASCADE|DELETE|RESTRICT)//gms;
    $content =~ s/DEFAULT NOW\(\)/DEFAULT NOW/gms;

    if ($content !~ /CREATE TABLE/) {
      return 0;
    }

    my @tables = $content =~ /((^|[^-])CREATE TABLE [^;]*;)/sg;

    foreach my $table (@tables) {
      $admin->query($table, 'do', {});
    }
    return 1;
  } else {
    return 0;
  }
}

#**********************************************************
=head2 _paysys_event_notify() notify about change merchant config change

=cut
#**********************************************************
sub _paysys_event_notify {
  my ($attr) = @_;

  if (in_array('Events', \@MODULES)) {
    require Events::API;
    Events::API->import();

    my $API = Events::API->new($db, $admin, \%conf);

    $API->add_event({
      MODULE      => 'Paysys',
      TITLE       => $attr->{TITLE},
      COMMENTS    => $attr->{COMMENTS},
      PRIORITY_ID => 4
    });
  }

  return 1;
}

#**********************************************************
=head2 _paysys_system_name_change() handle renaming of payment system

=cut
#**********************************************************
sub _paysys_system_name_change {
  my ($payment_system) = @_;
  return 0 if (!$payment_system || ref $payment_system ne 'HASH');
  return 1 if (!$payment_system->{name});

  my $Paysys_plugin = _configure_load_payment_module($payment_system->{module});
  return 0 if (!$Paysys_plugin->can('get_settings'));

  my %settings = $Paysys_plugin->get_settings();

  my $Pay_plugin = $Paysys_plugin->new($db, $admin, \%conf, {
    CUSTOM_NAME => $payment_system->{name},
    NAME        => $payment_system->{name},
    DATE        => $DATE
  });

  my %settings_new = $Pay_plugin->get_settings();

  return 1 if ($settings_new{NAME} eq $settings{NAME});

  my $name = uc $payment_system->{name};
  my $merchants = $Paysys->merchant_settings_list({
    ID             => '_SHOW',
    MERCHANT_NAME  => '_SHOW',
    SYSTEM_ID      => $payment_system->{id},
    PAYSYSTEM_NAME => '_SHOW',
    MODULE         => '_SHOW',
    COLS_NAME => 1,
  });

  return 1 if (!scalar @{$merchants});

  my $old_name = '';

  foreach my $merchant (@{$merchants}) {
    my $params = $Paysys->merchant_params_list({
      MERCHANT_ID => $merchant->{id},
      COLS_NAME   => 1,
    });

    next if (!scalar @{$params});

    foreach my $param (@{$params}) {
      if (!$old_name) {
        ($old_name) = $param->{param} =~ /(?<=PAYSYS_).+?(?=_)/gm;
        return 1 if ($old_name eq $name);
      }

      if ($param->{param} =~ /(?<=PAYSYS_).+?(?=_)/gm) {
        $param->{param} =~ s/(?<=PAYSYS_).+?(?=_)/$name/gm;
        $Paysys->merchant_params_change({
          ID    => $param->{id},
          PARAM => $param->{param},
        });
      }
    }
  }

  if ($old_name) {
    my $Config = Conf->new($db, $admin, \%conf);
    my $list = $Config->config_list({ PARAM => "PAYSYS_$old_name\_*", COLS_NAME => 1, PAGE_ROWS => 10000 });

    return 1 if (!scalar @{$list});

    foreach my $conf_param (@{$list}) {
      if ($conf_param->{param} =~ /(?<=PAYSYS_)$old_name(?=_)/gm) {
        $Config->config_del($conf_param->{param});
        $conf_param->{param} =~ s/(?<=PAYSYS_)$old_name(?=_)/$name/gm;
        $Config->config_add({
          PARAM     => $conf_param->{param},
          VALUE     => $conf_param->{value},
          REPLACE   => 1,
          PAYSYS    => 1
        });
      }
    }
  }

  return 1;
}

1;
