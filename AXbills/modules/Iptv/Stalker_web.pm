=head2 NAME

  Stalker Web interface

=cut

use strict;
use warnings FATAL => 'all';

our (
  $Tv_service,
  $db,
  $admin,
  %lang,
  %tp_list,
  %channel_list,
  %conf,
  %FORM,
  $index,
  $users,
  $pages_qs
);

our AXbills::HTML $html;
our Iptv $Iptv;
my $Tariffs = Tariffs->new($db, \%conf, $admin);

#**********************************************************
=head2 stalker_console($attr) - Stalker user managment

  Arguments:
    $attr

=cut
#**********************************************************
sub stalker_console {

  if (!$Tv_service || $Tv_service->{SERVICE_NAME} ne 'Stalker') {
    $html->message('err', $lang{ERROR}, "Stalker not connected", { ID => 889 });
    return 0;
  }

  my $service_id = $FORM{SERVICE_ID};

  if ($FORM{hangup}) {
    iptv_account_action({ hangup => 1, UID => $FORM{UID} });
  }
  elsif ($FORM{send_message}) {
    $FORM{UID} = $Iptv->{CID};
    iptv_account_action({ send_message => 1, %$Iptv, %FORM });
    return $Tv_service->{error};
  }
  elsif ($FORM{add} || $FORM{change}) {
    return $Tv_service->{error};
  }

  my @header_arr = ("$lang{ACCOUNTS}:index=$index&SERVICE_ID=$service_id",
    "STB:index=$index&list=STB&SERVICE_ID=$service_id",
    "$lang{CHANNELS}:index=$index&list=ITV&SERVICE_ID=$service_id",
    "$lang{SUBSCRIBES}:index=$index&list=ITV_SUBSCRIPTION&SERVICE_ID=$service_id",
    "$lang{TARIF_PLANS}:index=$index&list=tariffs&SERVICE_ID=$service_id",
    "CONSOLE:index=$index&list=console&SERVICE_ID=$service_id");
  print $html->table_header(\@header_arr, { TABS => 1 });

  # Get tps
  my $list = $Tariffs->list({
    MODULE       => 'Iptv',
    NEW_MODEL_TP => 1,
    COLS_NAME    => 1
  });

  foreach my $tp (@{$list}) {
    $tp_list{ $tp->{id} } = $tp->{tp_id};
  }
  if ($FORM{register}) {
    if (!$tp_list{ $FORM{TP_ID} }) {
      $html->message('err', $lang{ERROR}, "$lang{TARIF_PLAN} $lang{NOT_EXIST}");
    }
    else {
      my $users_list = $users->list({
        LOGIN     => $FORM{LOGIN} || '-',
        COLS_NAME => 1
      });

      my $login = $FORM{LOGIN};
      if ($users->{TOTAL} && $users->{TOTAL} > 0) {
        $users->{UID} = $users_list->[0]->{uid};
      }
      else {
        $users->add({ %FORM });
      }

      $FORM{TP_ID} = $tp_list{ $FORM{TP_ID} };
      if (!_error_show($users, { MESSAGE => 'Stalker LOGIN: ' . ($FORM{LOGIN} || q{}), ID => '888' })) {
        my $id = $FORM{ID} || q{};

        if ($id !~ /^\d{1,6}$/) {
          delete $FORM{ID};
        }

        $Iptv->user_add({ %FORM, UID => $users->{UID} });
        if (!_error_show($Iptv)) {
          $html->message('info', $lang{INFO}, "$lang{ADDED} " . $html->button($login, "index=" .
            get_function_index('iptv_user') . "&UID=$users->{UID}") .
            " SERVICE: " . $Iptv->{INSERT_ID}, { BUTTON => 1 });

          if ($id !~ /^\d{1,6}$/) {
            $Tv_service->user_change({
              CID              => $FORM{CID},
              ID               => $Iptv->{INSERT_ID},
              MAIN_ACCOUNT_KEY => 'stb_mac'
            });
          }
        }
      }
    }
  }
  elsif ($FORM{tp_add}) {
    if ($FORM{EXTERNAL_ID}) {
      $FORM{ID} = $FORM{EXTERNAL_ID};
    }

    if ($FORM{ID}) {
      $Tariffs->add({ %FORM, MODULE => 'Iptv' });
      if (!_error_show($Tariffs, { MESSAGE => "ID: " . ($FORM{EXTERNAL_ID} || q{}) })) {
        $html->message('info', "Stalker",
          "$lang{TARIF_PLAN} $lang{ADDED} [ $Tariffs->{INSERT_ID} ]\n " . $html->button("$lang{CONFIG}",
            "index=" . get_function_index('iptv_tp') . "&TP_ID=$Tariffs->{INSERT_ID}", { BUTTON => 1 }));
        $tp_list{ $FORM{ID} } = $Tariffs->{INSERT_ID};
      }
    }
  }

  if ($FORM{list}) {
    iptv_stalker_show_list($FORM{list});
    return 0;
  }
  elsif ($FORM{del}) {
    if (!$FORM{list}) {
      $Tv_service->user_del({ ID => $FORM{ID}, CID => $FORM{MAC} });
      if (!_error_show($Tv_service)) {
        $html->message('info', $lang{INFO}, $lang{DELETED});
      }
    }
    return 0;
  }

  return 1 if !$Tv_service->can('get_users');

  $Tv_service->get_users();
  return 0 if _error_show($Tv_service, { MESSAGE => "Stalker : $lang{ERROR}" });

  # Get axbills users
  my %register_stb = ();
  $list = $Iptv->user_list({
    PAGE_ROWS => 1000000,
    CID       => '_SHOW',
    COLS_NAME => 1
  });

  foreach my $line (@{$list}) {
    $register_stb{ $line->{cid} } = $line->{uid};
  }

  my @TITLE = ();

  if ($Tv_service->{RESULT}->{results}) {
    @TITLE = sort keys %{$Tv_service->{RESULT}->{results}->[0]};
  }

  my $table = $html->table({
    width   => '100%',
    title   => [ @TITLE, '-' ],
    caption => $lang{ACCOUNTS},
    ID      => 'STALKER_CONSOLE'
  });
  my $total_records = 0;
  foreach my $account_info (@{$Tv_service->{RESULT}->{results}}) {
    next if (!$account_info);
    my @row = ();
    foreach my $key (@TITLE) {
      my $val = $account_info->{$key};
      Encode::_utf8_off($account_info->{login});

      if ($val) {
        Encode::_utf8_off($val);
      }
      else {
        $val //= q{};
      }

      if ($key eq 'tariff_plan') {
        if ($val && !$tp_list{$val}) {
          $val = "$val " . $html->br() . $html->color_mark($lang{NOT_EXIST}, 'red') . $html->button($lang{ADD},
            "ID=$val&index=" . get_function_index('iptv_tp'), { class => 'add' });
        }
      }
      elsif (ref $val eq 'ARRAY') {
        $val = join($html->br(), @{$val});
      }
      elsif ($key eq 'stb_mac') {
        $val = $html->button($val, "index=$index&list=STB_MODULES&MAC=$val");
      }
      elsif ($key eq 'login') {
        $val = $html->button($val, "index=7&search=1&type=11&LOGIN=$val");
      }
      elsif ($key eq 'status') {
        $val = ($val) ? $html->color_mark($lang{ENABLE}, 'success') : $html->color_mark($lang{DISABLE}, 'danger');
      }
      elsif ($key eq 'online') {
        $val = ($val) ? $html->color_mark($lang{YES}, 'success') : $html->color_mark($lang{NO}, 'danger');
      }

      push @row, $val;
    }

    my $stb_mac = $account_info->{stb_mac} || q{};
    if ($stb_mac && $register_stb{ $stb_mac }) {
      push @row, $html->button($lang{SHOW}, "index=15&UID=$register_stb{ $stb_mac }",
        { class => 'show', TITLE => $account_info->{stb_mac} });
    }
    else {
      Encode::_utf8_off($account_info->{tariff_plan});
      push @row, $html->button($lang{ADD} . ' ' . ($account_info->{login} || q{}),
        "index=$index&register=1&MAC=" . (($account_info->{login}) ? $account_info->{login} : $stb_mac)
          . (($account_info->{login}) ? "&LOGIN=$account_info->{login}" : q{})
          . "&PASSWORD="
          . "&TP_ID=" . ($account_info->{tariff_plan} || '')
          . "&STATUS=" . ($account_info->{status} || '')
          . "&CREATE_BILL=1"
          . "&ID=$account_info->{account_number}"
          . "&CID=" . $stb_mac
          . (($FORM{SERVICE_ID}) ? "&SERVICE_ID=$FORM{SERVICE_ID}" : q{})
        , { class => 'add' });
    }

    push @row, $html->button($lang{DEL}, "index=$index" . (($FORM{list}) ? "&list=$FORM{list}" : q{})
      . "&MAC=$stb_mac&ID=$account_info->{account_number}&del=1" . (($FORM{SERVICE_ID}) ? "&SERVICE_ID=$FORM{SERVICE_ID}" : q{}),
      { MESSAGE => "$lang{DEL} $stb_mac ?", class => 'del' });

    $table->addrow(@row);
    $total_records++;
  }

  print $table->show();

  $table = $html->table({ rows => [ [ $lang{TOTAL}, $total_records ] ] });
  print $table->show();

  return 1;
}

#**********************************************************
=head2 iptv_stalker_show_list($list_name)

=cut
#**********************************************************
sub iptv_stalker_show_list {
  my ($list_name) = @_;

  my $request = '';
  my %PARAMS_HASH = ();
  $pages_qs .= "&list=$FORM{list}";

  my $list_type = $FORM{list} || q{};

  if ($list_name eq 'ITV') {
    my $list = $Iptv->channel_list({ COLS_NAME => 1, PAGE_ROWS => 10000 });
    foreach my $line (@{$list}) {
      $channel_list{ $line->{num} } = $line->{name};
    }
    $request = "ITV";
  }
  elsif ($list_name eq 'console') {
    my @action_methods = ('GET', 'POST', 'PUT');
    my $action_method = $html->form_select('COMMAND',{
      SELECTED  => $FORM{COMMAND} || 'GET',
      SEL_ARRAY => \@action_methods,
    });
    print $html->form_main({
      CONTENT => "$lang{PREFIX}: " . $html->form_input('REQUEST', $FORM{REQUEST}) . "$lang{PARAMS}: " .
        $html->form_input('PARAMS', $FORM{PARAMS}) . "$lang{ACTION}: " . $action_method,
      HIDDEN  => {
        list  => "console",
        index => $index,
      },
      SUBMIT  => { show => $lang{SHOW} }
    });
    if ($FORM{REQUEST}) {
      $pages_qs .= "&REQUEST=$FORM{REQUEST}";
      $request = $FORM{REQUEST};
      $list_name .= " : $request ";
    }

    foreach my $line (split(/&/, $FORM{PARAMS} || q{})) {
      if ($line) {
        my ($k, $v) = split(/=/, $line);
        $PARAMS_HASH{$k} = $v;
      }
    }
  }
  elsif ($FORM{reboot}) {
    $request = "send_event/" . $FORM{MAC};
    $PARAMS_HASH{event} = 'reboot';
  }
  else {
    $request = "$list_name/" . ($FORM{MAC} || q{});
  }

  $Tv_service->_send_request({
    ACTION  => $request,
    COMMAND => $FORM{COMMAND},
    %PARAMS_HASH,
    DEBUG   => $FORM{DEBUG},
  });

  _error_show($Tv_service, { ID => 860, MESSAGE => $Tv_service->{errstr} });

  my $FUNCTION_FIELDS = "iptv_console:del:mac;serial_number:&list=$list_type&del=1&COMMENTS=1&SERVICE_ID=" . $FORM{SERVICE_ID}; #":$lang{DEL}:MAC:&del=1&COMMENTS=del",

  if ($list_type eq 'tariffs') {
    if (!$FORM{ID} || !$tp_list{ $FORM{ID} }) {
      $FUNCTION_FIELDS = "iptv_console:add:external_id;name:&list=$list_type&tp_add=1&SERVICE_ID=" . $FORM{SERVICE_ID};
    }
    else {
      $FUNCTION_FIELDS = q{};
    }

    foreach my $tariff (@{$Tv_service->{RESULT}->{results}}) {
      foreach my $package (@{$tariff->{packages}}) {
        Encode::_utf8_off($package->{description});
        Encode::_utf8_off($package->{name});
        Encode::_utf8_off($package->{external_id});
      }
      Encode::_utf8_off($tariff->{external_id});
      Encode::_utf8_off($tariff->{name});
    }
  }
  elsif ($list_type eq 'ITV' || $list_type eq 'itv') {
    $FUNCTION_FIELDS = '';
    if ($FORM{import_channels}) {
      $Iptv->channel_del(0, { ALL => 1 });
      my $channels_count = 0;
      foreach my $account_hash (@{$Tv_service->{RESULT}->{results}}) {
        $Iptv->channel_add({
          ID       => $account_hash->{id},
          NAME     => $account_hash->{name},
          NUM      => $account_hash->{id}, #$account_hash->{number},
          PORT     => $account_hash->{id},
          DESCRIBE => $account_hash->{name},
          DISABLE  => 0
        });
        _error_show($Iptv, { MESSAGE => "$lang{CHANNEL}: [$account_hash->{number}] $account_hash->{name}" });
        $channels_count++;
      }

      $html->message('info', $lang{INFO}, "$lang{IMPORT} # $channels_count");
    }
  }
  elsif ($list_type eq 'STB') {
    $FUNCTION_FIELDS = "iptv_console:hangup:mac;name:&list=$list_type&reboot=1&SERVICE_ID=" . $FORM{SERVICE_ID};
  }

  result_former({
    FUNCTION_FIELDS => $FUNCTION_FIELDS,
    SELECT_VALUE    => {
      online => {
        0 => "$lang{NO}:danger",
        1 => "$lang{YES}:success",
      },
      status => {
        0 => "$lang{DISABLE}:danger",
        1 => "$lang{ENABLE}:success",
      }
    },
    TABLE           => {
      width            => '100%',
      caption          => 'new ' . ($list_type || 'getUserList') . ' ' . $html->button('API', "",
        { GLOBAL_URL => 'http://wiki.infomir.eu/doku.php/stalker:rest_api_v1', target => '_new' }),
      qs               => $pages_qs,
      SHOW_COLS_HIDDEN => { visual => $FORM{visual}, },
      header           => ($list_name eq 'ITV') ? $html->button("$lang{IMPORT} $lang{CHANNELS}",
        "index=$index&list=ITV&import_channels=1&SERVICE_ID=" . $FORM{SERVICE_ID}, { BUTTON => 1 }) : '',
      ID               => 'TV_STALKER_LIST',
    },
    FILTER_COLS     => {
      account              => 'search_link:iptv_users_list:ID',
      SubscriberProviderID => 'search_link:iptv_users_list:ID',
      external_id          => 'iptv_show_tp:EXTERNAL_ID',
      number               => 'iptv_show_channels:number,name,id',
      name                 => '_utf8_encode',
      description          => '_utf8_encode',
      ls                   => 'search_link:iptv_users_list:ID',
      login                => 'search_link:form_users_list:LOGIN',
    },
    DATAHASH        => $Tv_service->{RESULT}->{results},
    TOTAL           => 1
  });

  if ($Tv_service->{RESULT} && ref $Tv_service->{RESULT}->{results} eq 'HASH') {
    my $table = $html->table({
      width   => '100%',
      title   => [ $lang{PARAMS}, $lang{VALUE} ],
      caption => "$lang{LIST}: $list_name",
      ID      => 'CLOSE_PERIOD'
    });

    while (my ($key, $val) = each %{$Tv_service->{RESULT}->{results}}) {
      my @row = ();
      if (ref $val eq 'ARRAY') {
        push @row, $key, join($html->br(), @{$val});
      }
      else {
        if ($key eq 'mac') {
          $val = $html->button($val, "index=$index&list=STB_MODULES&MAC=$val&SERVICE_ID=" . $FORM{SERVICE_ID});
        }
        push @row, $key, $val;
      }
      $table->addrow(@row);
    }
    print $table->show();
    return 0;
  }

  return 1;
}

1;