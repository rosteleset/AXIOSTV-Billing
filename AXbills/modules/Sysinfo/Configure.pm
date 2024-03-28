#package Sysinfo::Configure;
use strict;
use warnings FATAL => 'all';

=head1 NAME

  Sysinfo::Configure - 

=cut

use AXbills::Experimental;
use AXbills::Base qw/ip2int load_pmodule/;

require AXbills::Misc;

our (%conf, $db, $admin, %permissions, %lang, $html, $base_dir);

use Sysinfo;
our Sysinfo $Sysinfo;
if (!$Sysinfo) {
  $Sysinfo = Sysinfo->new($db, $admin, \%conf);
}

our %MANAGEMENT_TYPES = (
  0 => 'SSH',
  1 => 'ABillS Satellite'
);

my $certs_dir = $conf{CERTS_DIR} || ($base_dir || '/usr/axbills') . '/Certs';


#**********************************************************
=head2 sysinfo_remote_servers()

=cut
#**********************************************************
sub sysinfo_remote_servers {

  my %TEMPLATE_ARGS = ();
  my $show_add_form = $FORM{add_form} || 0;

  if ($FORM{nas_info} && $FORM{NAS_ID}) {
    return &sysinfo_nas_info;
  }
  elsif (defined $FORM{nas_check_access}) {
    return &sysinfo_check_server_access;
  }
  elsif ($FORM{set_services} && $FORM{SERVER_ID}) {
    my $services_list = $Sysinfo->server_services_list({ NAME => '_SHOW', PAGE_ROWS => 10000 });

    my $service_servers_binding = $Sysinfo->remote_server_services_full({ WHERE => {
      server_id => $FORM{SERVER_ID}
    } });
    _error_show($Sysinfo) and return 0;

    my %service_on_server = map {$_->{service_id} => 1} @{$service_servers_binding};

    print get_checkboxes_form_html('SERVICE_IDS', $services_list, \%service_on_server, {
      class  => 'form-horizontal ajax-submit-form',
      ID     => 'SYSINFO_SERVICE_SERVERS',
      HIDDEN => {
        index           => $index,
        change_services => 1,
        chg             => $FORM{SERVER_ID}
      },
      SUBMIT => { save => $lang{SAVE} },
    });

    return 1;
  }

  if ($FORM{add}) {
    $Sysinfo->remote_servers_add({ %FORM });
    $show_add_form = show_result($Sysinfo, $lang{ADDED});
  }
  elsif ($FORM{change}) {
    $Sysinfo->remote_servers_change({ %FORM });
    show_result($Sysinfo, $lang{CHANGED});
    $show_add_form = 1;
  }
  elsif ($FORM{chg}) {
    if ($FORM{change_services}) {
      # Delete all servers for this service
      $Sysinfo->remote_server_services_del({}, { server_id => $FORM{chg} });
      _error_show($Sysinfo) and return 0;

      my @service_ids = split(',\s?', $FORM{SERVICE_IDS} || '');
      foreach (grep {$_} @service_ids) {
        $Sysinfo->remote_server_services_add({
          SERVER_ID  => $FORM{chg},
          SERVICE_ID => $_
        });
      }

      show_result($Sysinfo, $lang{CHANGED});
      return 1;
    }
    my $tp_info = $Sysinfo->remote_servers_info($FORM{chg});
    if (!_error_show($Sysinfo)) {
      %TEMPLATE_ARGS = %{$tp_info};
      $show_add_form = 1;
    }
  }
  elsif ($FORM{del} && $FORM{COMMENTS}) {
    $Sysinfo->remote_servers_del({ ID => $FORM{del}, COMMENTS => $FORM{COMMENTS} });
    show_result($Sysinfo, $lang{DELETED});
  }

  if ($show_add_form) {

    $TEMPLATE_ARGS{MANAGEMENT_SELECT} = make_select_from_hash('MANAGEMENT', \%MANAGEMENT_TYPES, {
      SELECTED => $TEMPLATE_ARGS{MANAGEMENT} || 0
    });

    $TEMPLATE_ARGS{NAS_ID_SELECT} = $html->form_select(
      'NAS_ID',
      {
        SELECTED          => $TEMPLATE_ARGS{NAS_ID} || $FORM{NAS_ID},
        # Popup window
        POPUP_WINDOW      => 'form_search_nas',
        POPUP_WINDOW_TYPE => 'search',
        SEARCH_STRING     => 'POPUP=1&NAS_SEARCH=0',
        HAS_NAME          => 1
      }
    );

    my $certs = list_private_keys();
    $TEMPLATE_ARGS{PRIVATE_KEY_SELECT} = make_select_from_arr_ref('PRIVATE_KEY', $certs, {
      SELECTED => $TEMPLATE_ARGS{PRIVATE_KEY} || '',
    });

    $html->tpl_show(
      _include('sysinfo_remote_server', 'Sysinfo'),
      {
        %TEMPLATE_ARGS,
        %FORM,
        SUBMIT_BTN_ACTION => ($FORM{chg}) ? 'change' : 'add',
        SUBMIT_BTN_NAME   => ($FORM{chg}) ? $lang{CHANGE} : $lang{ADD},
      }
    );
  }

  my $services_index = get_function_index('sysinfo_server_services');

  result_former({
    INPUT_DATA      => $Sysinfo,
    FUNCTION        => 'remote_servers_list',
    DEFAULT_FIELDS  => 'ID,NAME,COMMENTS,IP,NAT,SERVICES',
    FUNCTION_FIELDS => 'change, del'
      . ',sysinfo_server_services:$lang{SERVICES}:id:&LIST_SERVER_SERVICES=1',
    BASE_FIELDS     => 0,
    SKIP_USER_TITLE => 1,
    EXT_FIELDS      => 0,
    EXT_TITLES      => {
      name     => $lang{NAME},
      ip       => 'IP',
      nat      => 'NAT',
      services => $lang{SERVICES},
      comments => $lang{COMMENTS},
    },
    SKIP_USER_TITLE => 1,
    SELECT_VALUE    => {
      nat => {
        0 => "$lang{NO}",
        1 => "$lang{YES}",
      }
    },
    FILTER_VALUES   => {
      services => sub {
        my ($services, $line) = @_;

        my $add_btn =
          $html->button($lang{CREATE},
            "index=$services_index&add_form=1&SERVER_ID=$line->{id}",
            {
              class    => 'btn btn-xs btn-success float-right',
              ADD_ICON => 'fa fa-plus'
            }
          );

        my $create_btn = $html->button($lang{CHANGE},
          "qindex=$index&header=2&add_form=1&set_services=1&SERVER_ID=$line->{id}",
          {
            class         => 'btn btn-xs btn-secondary float-right',
            ADD_ICON      => 'fa fa-pencil-alt',
            LOAD_TO_MODAL => 1
          }
        );

        ($services || '') . $add_btn . $create_btn;
      }
    },
    TABLE           => {
      width   => '100%',
      caption => $lang{REMOTE_SERVERS},
      qs      => $pages_qs,
      ID      => 'SYSINFO_SERVERS',
      MENU    => "$lang{ADD}:index=$index&add_form=1:add"
    },
    MAKE_ROWS       => 1,
    MODULE          => 'Sysinfo',
    TOTAL           => 1
  });

  print $html->element('script', '', { src => '/styles/default/js/modules/sysinfo/services.js' });

  return 1;
}

#**********************************************************
=head2 sysinfo_server_services()

=cut
#**********************************************************
sub sysinfo_server_services {
  my %TEMPLATE_ARGS = ();
  my $show_add_form = $FORM{add_form} || 0;

  if ($FORM{set_servers} && $FORM{SERVICE_ID}) {
    my $servers_list = $Sysinfo->remote_servers_list({ NAME => '_SHOW', PAGE_ROWS => 10000 });

    my $server_services_binding = $Sysinfo->remote_server_services_full({ WHERE => {
      service_id => $FORM{SERVICE_ID}
    } });
    _error_show($Sysinfo) and return 0;

    my %service_on_server = map {$_->{server_id} => 1} @{$server_services_binding};

    print get_checkboxes_form_html('SERVER_IDS', $servers_list, \%service_on_server, {
      class  => 'form-horizontal ajax-submit-form',
      ID     => 'SYSINFO_SERVER_SERVICES',
      HIDDEN => {
        index          => $index,
        change_servers => 1,
        chg            => $FORM{SERVICE_ID}
      },
      SUBMIT => { save => $lang{SAVE} },
    });

    return 1;
  }

  if ($FORM{add}) {
    my $new_service_id = $Sysinfo->server_services_add({ %FORM });
    $show_add_form = show_result($Sysinfo, $lang{ADDED});

    if ($new_service_id && $FORM{SERVER_ID}) {
      $Sysinfo->remote_server_services_add({
        SERVER_ID  => $FORM{SERVER_ID},
        SERVICE_ID => $new_service_id
      })
    }
  }
  elsif ($FORM{change}) {
    $Sysinfo->server_services_change({ %FORM });
    show_result($Sysinfo, $lang{CHANGED});
    $show_add_form = 1;
  }
  elsif ($FORM{chg}) {
    if ($FORM{change_servers}) {
      # Delete all servers for this service
      $Sysinfo->remote_server_services_del({}, { service_id => $FORM{chg} });
      _error_show($Sysinfo) and return 0;

      my @server_ids = split('\s?', $FORM{SERVER_IDS} || '');
      $Sysinfo->remote_server_services_add({
        SERVER_ID  => $_,
        SERVICE_ID => $FORM{chg}
      }) foreach (grep {$_} @server_ids);

      show_result($Sysinfo, $lang{CHANGED});
      return 1;
    }

    my $tp_info = $Sysinfo->server_services_info($FORM{chg});
    if (!_error_show($Sysinfo)) {
      %TEMPLATE_ARGS = %{$tp_info};
      $show_add_form = 1;
    }
  }
  elsif ($FORM{del} && $FORM{COMMENTS}) {
    $Sysinfo->server_services_del({ ID => $FORM{del}, COMMENTS => $FORM{COMMENTS} });
    show_result($Sysinfo, $lang{DELETED});
  }

  if ($show_add_form) {

    $html->tpl_show(
      _include('sysinfo_server_services', 'Sysinfo'),
      {
        %TEMPLATE_ARGS,
        %FORM,
        SUBMIT_BTN_ACTION => ($FORM{chg}) ? 'change' : 'add',
        SUBMIT_BTN_NAME   => ($FORM{chg}) ? $lang{CHANGE} : $lang{ADD},
      }
    );

  }

  my $reboot_show = 0;
  if ($FORM{LIST_SERVER_SERVICES} && $FORM{ID}) {
    $LIST_PARAMS{SERVER_ID} = $FORM{ID};
    $reboot_show = $FORM{ID};
  }

  my $servers_index = get_function_index('sysinfo_remote_servers');

  my $remote_servers = $Sysinfo->remote_servers_list({ NAME => '_SHOW', PAGE_ROWS => 10000, });
  _error_show($Sysinfo) and return 0;

  my $server_by_id = sort_array_to_hash($remote_servers, 'id');
  my AXbills::HTML $table;
  my $list;
  ($table, $list) = result_former({
    INPUT_DATA      => $Sysinfo,
    FUNCTION        => 'server_services_list',
    DEFAULT_FIELDS  => 'ID,NAME,SERVER_IDS,STATUS,LAST_UPDATE,COMMENTS',
    FUNCTION_FIELDS => 'change, del'
      . ($reboot_show
      ? ",sysinfo_server_restart:RESTART_SERVICE:id;name:&RESTART_SERVICE=1&SERVER_ID=$reboot_show"
      : ''),
    ,
    BASE_FIELDS     => 0,
    SKIP_USER_TITLE => 1,
    EXT_FIELDS      => 0,
    EXT_TITLES      => {
      id              => '#',
      name            => $lang{NAME},
      'check_command' => 'Command',
      last_update     => $lang{LAST_ACTIVITY},
      status          => $lang{STATUS},
      server_ids      => $lang{SERVER} || 'Server',
      comments        => $lang{COMMENTS},
    },
    SKIP_USER_TITLE => 1,
    SELECT_VALUE    => {
      status => {
        0 => $lang{DISABLED},
        1 => $lang{ACTIVE},
      },
    },
    FILTER_VALUES   => {
      server_ids => sub {
        my ($server_ids, $line) = @_;
        my @server_ids = split(',\s?', $server_ids || '');

        my @server_buttons = ();
        foreach my $id (@server_ids) {
          next if (!$id);

          push @server_buttons, ($html->button(
            $server_by_id->{$id}->{name} || $lang{ERR_NOT_EXIST},
            "index=$servers_index&chg=$id"
          )
          );

        }

        my $edit_button = $html->button($lang{CHANGE}, "qindex=$index&header=2&set_servers=1&SERVICE_ID=$line->{id}", {
          ADD_ICON      => 'fa fa-pencil-alt',
          class         => 'btn btn-secondary btn-xs float-right',
          LOAD_TO_MODAL => 1
        });

        join(', ', @server_buttons) . '&nbsp' . $edit_button;
      }
    },
    TABLE           => {
      width   => '100%',
      caption => $lang{SERVER_SERVICES},
      qs      => $pages_qs,
      ID      => 'SYSINFO_SERVICES',
      MENU    => "$lang{ADD}:index=$index&add_form=1:add"
    },
    MAKE_ROWS       => 1,
    MODULE          => 'Sysinfo',
    TOTAL           => 1
  });

  if (!$list || ($list && ref $list eq 'HASH' && scalar @{$list} == 0)) {
    print $html->button("$lang{ADD}",
      "index=$index&add_form=1" . ($FORM{LIST_SERVER_SERVICES} && $FORM{ID} ? "&SERVER_ID=$FORM{ID}" : ''),
      {
        class    => 'btn btn-lg btn-success',
        ADD_ICON => 'fa fa-plus'
      }
    );
  }

  print $html->element('script', '', { src => '/styles/default/js/modules/sysinfo/services.js' });

  return 1;
}

#**********************************************************
=head2 sysinfo_nas_info()

=cut
#**********************************************************
sub sysinfo_nas_info {
  my $nas_id = $FORM{NAS_ID} || return;

  my $nas_list = $Sysinfo->sysinfo_nases_list({
    ID               => $nas_id,
    SHOW_ALL_COLUMNS => 1,
    PAGE_ROWS        => 1
  });
  _error_show($Sysinfo);

  if (!$nas_list || !ref $nas_list eq 'ARRAY' || !scalar @{$nas_list}) {
    return '';
  }

  my $nas_info = $nas_list->[0];

  if (my $module_load_error = load_pmodule("JSON", { SHOW_RETURN => 1 })) {
    print $module_load_error;
    return 0;
  }

  require JSON;
  JSON->import(qw/from_json to_json/);

  print JSON::to_json($nas_info);

  return 1;
}

#**********************************************************
=head2 list_private_keys() - returns available keys from Certs dir

=cut
#**********************************************************
sub list_private_keys {
  my $files_list = _get_files_in($certs_dir, {
    FILTER    => '^id_[rdec]sa\.[a-z_]+(?!\.pub)$',
    FULL_PATH => 1
  });

  my @available_keys = grep {-r $_} @{$files_list};

  return \@available_keys;
}

#**********************************************************
=head2 sysinfo_server_restart()

=cut
#**********************************************************
sub sysinfo_server_restart {
  return if (!$FORM{ID});

  require AXbills::Backend::API;
  AXbills::Backend::API->import();

  my $api = AXbills::Backend::API->new(\%conf);

  my $res = $api->call_plugin('Satellite', {
    TYPE         => 'SERVICE_REBOOT',
    SERVICE_NAME => $FORM{NAME},
    SERVER_ID    => $FORM{SERVER_ID}
  });

  if (!$res || !ref $res eq 'HASH') {
    require Data::Dumper;
    Data::Dumper->import();

    print Dumper $res;
    $html->message("err", $lang{ERROR});
  }
  $html->message("info", $lang{SUCCESS});

  my $services_index = get_function_index('sysinfo_server_services');
  $html->redirect("$SELF_URL?index=$services_index");

  return 1;
}
1;