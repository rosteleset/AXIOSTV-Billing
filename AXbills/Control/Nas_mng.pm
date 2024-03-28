=head1 NAME

  NAS managment functions

=cut

use strict;
use warnings FATAL => 'all';
use AXbills::Defs;
use AXbills::Radius_Pairs;
use AXbills::Base qw(in_array convert int2ip ip2int ssh_cmd cmd _bp);
use Nas;

my %auth_types = (
  0 => 'DB',
  1 => 'System'
);

our (
  $db,
  %conf,
  %lang,
  $base_dir,
  %permissions,
  @state_colors,
  @MODULES,
  $index,
  %FORM,
  $pages_qs,
  %LIST_PARAMS,
  $SELF_URL,
  $DATE,
);

our AXbills::HTML $html;
our Admins $admin;

my $Nas = Nas->new($db, \%conf, $admin);

#**********************************************************
=head2 form_nas() - Nas managment

=cut
#**********************************************************
sub form_nas {

  if (in_array('Equipment', \@MODULES)) {
    require Equipment;
    Equipment->import();
  }

  if ($FORM{NAS_ID} && !$FORM{del}) {
    return 1 if form_nas_mng($FORM{NAS_ID});
  }
  elsif ($FORM{add_form}) {
    $Nas->{ACTION}     = 'add';
    $Nas->{LNG_ACTION} = $lang{ADD};
    form_nas_add({ NAS => $Nas });
  }
  elsif ($FORM{search_form}) {
    form_nas_search({ STANDART => 1 });
  }
  elsif ($FORM{add} && $permissions{4} && $permissions{4}{1}) {
    if ($FORM{MAC} && $FORM{MAC} !~ /^[a-f0-9\-\.:]+$/i) {
      $html->message('err', $lang{ERROR}, "$lang{ERR_WRONG_DATA} MAC: '$FORM{MAC}'");
    }
    elsif(! $FORM{IP}) {
      $html->message('err', $lang{ERROR}, "NO_NAS_IP");
    }
    else {
      $FORM{NAS_NAME} = "NAS_". $FORM{IP} if(! $FORM{NAS_NAME});
      $FORM{NAS_MNG_HOST_PORT} = ($FORM{NAS_MNG_IP} || '') . ":" . ($FORM{COA_PORT} || '') . ":" . ($FORM{SSH_PORT} || '') . ":" . ($FORM{SNMP_PORT} || '');
      $Nas->add({ %FORM, DOMAIN_ID => $admin->{DOMAIN_ID} });

      if (!$Nas->{errno}) {
        my $nas_id = $Nas->{INSERT_ID} || 0;
        $html->message('info', $lang{INFO},
          "$lang{ADDED} $lang{NAS}\n IP: '$FORM{IP}'\n $lang{NAME}: '$FORM{NAS_NAME}'\n"
            . $html->button($lang{MANAGE}, "index=$index&NAS_ID=$Nas->{INSERT_ID}", { BUTTON => 2 }) . ' '
            . (($FORM{NAS_TYPE} && $FORM{NAS_TYPE} =~ /mikrotik/) ? $html->button($lang{CONFIGURATION}, "index=$index&NAS_ID=$nas_id&mikrotik_configure=1", { BUTTON => 2 }) : q{}));

        #Restart Section
        if ($conf{RESTART_RADIUS}) {
          cmd($conf{RESTART_RADIUS});
        }
      }
    }
  }
  elsif ($permissions{4} && $permissions{4}{3} && $FORM{del} && $FORM{COMMENTS}){
    my ($Internet, $Sessions);
    # check online users before deleting
    if (in_array('Internet', \@MODULES)) {
      require Internet;
      Internet->import();
      $Internet = Internet->new($db, $admin, \%conf);
      require Internet::Sessions;
      Internet::Sessions->import();
      $Sessions = Internet::Sessions->new($db, $admin, \%conf);
    }

    my $service = $Internet->user_list({ UID => '_SHOW', NAS_ID => $FORM{del}, COLS_NAME => 1 });
    my $session_list = $Sessions->online({ UID => '_SHOW', NAS_ID => $FORM{del},  ALL => 1, COLS_NAME => 1 });

    if ($Internet->{TOTAL} > 0){
      my $internet_users_index = get_function_index('internet_users_list');
      my $internet_quantity_users = $html->button($Internet->{TOTAL}, "index=$internet_users_index&NAS_ID=$FORM{del}",{BUTTON => 2, target => '_blank'});
      $html->message('danger', "$lang{ERROR_DELETE} ID=$FORM{del}", "$lang{NUMBER_OF_USERS}: $internet_quantity_users");
    }

    if ($Sessions->{TOTAL} > 0){
      my $online_users_index = get_function_index('internet_online');
      my $online_quantity_users = $html->button($Sessions->{TOTAL}, "index=$online_users_index&NAS_ID=$FORM{del}",{BUTTON => 2, target => '_blank'});
      $html->message('danger', "$lang{ERROR_DELETE} ID=$FORM{del}", "$lang{NUMBER_OF_USERS} $lang{ONLINE}: $online_quantity_users");
    }

    if (!$Internet->{TOTAL} && !$Sessions->{TOTAL}) {
      $Nas->del($FORM{del});

      if (!$Nas->{errno}) {
        $html->message('info', $lang{INFO}, "$lang{DELETED} [$FORM{del}]");
        if (in_array('Equipment', \@MODULES)) {
          my $Equipment = Equipment->new($db, $admin, \%conf);
          $Equipment->_del($FORM{del});
        }
      }
    }
  }
  elsif ($FORM{wrt_configure}) {
    form_wrt_configure();
    return 0;
  }

  _error_show($Nas);

  my %equipment_filter = ();
  if (in_array('Equipment', \@MODULES)) {
    my $Equipment = Equipment->new($db, $admin, \%conf);
    my $list = $Equipment->_list({ COLS_NAME => 1, PAGE_ROWS => 100000 });
    foreach my $line (@$list) {
      $equipment_filter{ $line->{nas_id} } = $lang{YES};
    }
  }

  unless ($FORM{add_form} || $FORM{NAS_ID} || $FORM{search_form}) {
    # require Control::Reports;
    # reports({
    #   PERIOD_FORM     => 1,
    #   NO_PERIOD       => 1,
    #   NO_GROUP        => 1,
    #   NO_TAGS         => 1,
    #   EXT_SELECT      => sel_nas_groups(),
    #   EXT_SELECT_NAME => $lang{GROUPS},
    # });

    $html->short_form({
      LABELED_FIELDS => {
        "$lang{GROUPS}:" => sel_nas_groups(),
      },
      FIELDS         => [
        $html->form_input('submit', $lang{SHOW}, { TYPE => 'submit' }),
        $html->form_input('index', $index, {TYPE => 'hidden'})],
      'class'        => 'form-inline',
      IN_BOX         => 1,
      NO_BOX_HEADER  => 1,
    });
  }

  form_nas_list();

  return 1;
}

#**********************************************************
=head2 form_nas_mng() - Nas managment

=cut
#**********************************************************
sub form_nas_mng {
  my ($nas_id) = @_;

  $Nas->info({ NAS_ID => $nas_id });

  return 1 if _error_show($Nas, { MESSAGE => "NAS_ID: $nas_id" });

  $pages_qs .= "&NAS_ID=$nas_id&subf=" . ($FORM{subf} || '');

  $LIST_PARAMS{NAS_ID} = $nas_id;
  my %F_ARGS = (NAS => $Nas);

  my @nas_menu = ($lang{INFO} . "::NAS_ID=$nas_id", 'IP Pools' . ":63:NAS_ID=$nas_id", $lang{STATS} . ":64:NAS_ID=$nas_id", 'RADIUS Test' . "::NAS_ID=$nas_id&radtest=1", 'Console' . "::NAS_ID=$nas_id&console=1&full=1",'MRTG' . "::NAS_ID=$nas_id&mrtg_cfg=1",);

  if ($FORM{ext_info}) {
    load_module('Equipment', $html);
    return 0;
  }
  elsif ($FORM{ssh_key}) {
    form_ssh_key($Nas);
  }
  elsif ($Nas->{NAS_TYPE} && $Nas->{NAS_TYPE} eq 'chillispot') {
    if (-f "../wrt_configure.cgi") {
      $ENV{HTTP_HOST} =~ s/\:(\d+)//g;
      $Nas->{EXTRA_PARAMS} = $html->tpl_show(
        templates('form_nas_configure'),
        {
          %$Nas,
          CONFIGURE_DATE => "wget -O /tmp/setup.sh \"http://$ENV{HTTP_HOST}/hotspot/wrt_configure.cgi?" . (($Nas->{DOMAIN_ID}) ? "DOMAIN_ID=$Nas->{DOMAIN_ID}\\\&" : '') . "NAS_ID=$Nas->{NAS_ID}\"; chmod 755 /tmp/setup.sh; /tmp/setup.sh",
          PARAM1         => "wget -O /tmp/setup.sh \"http://$ENV{HTTP_HOST}/hotspot/wrt_configure.cgi?DOMAIN_ID=$admin->{DOMAIN_ID}\\\&NAS_ID=$Nas->{NAS_ID}",
          PARAM2         => "; chmod 755 /tmp/setup.sh; /tmp/setup.sh",
        },
        { OUTPUT2RETURN => 1 }
      );
    }
    else {
      $html->message('callout', 'Install wrt_configure.cgi', $html->button("ABillS Wiki ", '', { GLOBAL_URL => 'http://axbills.net.ua/wiki/doku.php/axbills:docs:nas:chillispot:openwrt#axbills' }));
    }
  }
  elsif ($Nas->{NAS_TYPE} && $Nas->{NAS_TYPE} =~ /mikrotik/) {
    push @nas_menu, "Hotspot::NAS_ID=$Nas->{NAS_ID}&mikrotik_hotspot=1";
    push @nas_menu, "$lang{CONFIGURATION}::NAS_ID=$Nas->{NAS_ID}&mikrotik_configure=1";
    push @nas_menu, "$lang{IMPORT} $lang{USERS}::NAS_ID=$Nas->{NAS_ID}&mikrotik_configure=1&import_users=1";
  }

  $Nas->{CHANGED}  = "($lang{CHANGED}: $Nas->{CHANGED})";
  $Nas->{NAME_SEL} = $html->form_main(
    {
      CONTENT => $html->form_select(
        'NAS_ID',
        {
          SELECTED   => $FORM{NAS_ID},
          SEL_LIST   => $Nas->list({ %LIST_PARAMS, NAS_ID => undef, PAGE_ROWS => 60000, COLS_NAME => 1 }),
          SEL_KEY    => 'nas_id',
          SEL_VALUE  => 'nas_name,nas_ip',
          AUTOSUBMIT => 'form'
        }
      ),
      HIDDEN => {
        index => '62',
        AID   => $FORM{AID} || undef,
        subf  => $FORM{subf},
        show  => 1
      },
      class  => 'form-inline ml-auto flex-nowrap',
    }
  );

  if (in_array('Equipment', \@MODULES)) {
    my $equpment_index = get_function_index('equipment_info');
    $Nas->{EQUIPMENT} = $html->button($lang{EXTRA}, "index=$equpment_index&NAS_ID=$Nas->{NAS_ID}&ext_info=1", { class => 'btn btn-info btn-xs' });
    push @nas_menu, $lang{EXTRA} . ':' . $equpment_index . ":NAS_ID=$Nas->{NAS_ID}&ext_info=1::$equpment_index";
  }

  if (in_array('Snmputils', \@MODULES)) {
    load_module('Snmputils', $html);
    push @nas_menu, 'SNMP:' . (get_function_index('snmp_info_form')) . ":NAS_ID=$Nas->{NAS_ID}&console=1&full=1";
  }

  if (in_array('Storage', \@MODULES)) {
    # Maybe, we dont need fool load of Storage, because we just get an index - load at click.
    load_module('Storage', $html);
    my $storage_index = get_function_index('storage_main');
    push @nas_menu, "$lang{INVENTORY_ITEMS}:$storage_index:NAS_ID=$Nas->{NAS_ID}&show_installation=1&search=1::$storage_index";
  }

  func_menu(
    {
      $lang{NAME} => $Nas->{NAME_SEL}
    },
    \@nas_menu,
    { f_args => \%F_ARGS }
  );

  if ($FORM{subf}) {
    return 0;
  }
  elsif ($FORM{console}) {
    return form_nas_console($Nas);
  }
  elsif ($FORM{radtest}) {
    return form_nas_test($Nas);
  }
  elsif ($FORM{mikrotik_hotspot}) {
    require Control::Mikrotik_mng;
    return form_mikrotik_hotspot($Nas);
  }
  elsif ($FORM{mikrotik_configure}) {
    require Control::Mikrotik_mng;
    return form_mikrotik_configure($Nas, \%FORM);
  }
  elsif ($FORM{mikrotik_check_access}) {
    require Control::Mikrotik_mng;
    return form_mikrotik_check_access($Nas);
  }
  elsif ($FORM{mrtg_cfg}) {
    return form_mrtg_cfg($Nas);
  }
  elsif ($FORM{change} && $permissions{4} && $permissions{4}{2}) {
    if ($FORM{MAC} && $FORM{MAC} !~ /^[a-f0-9\-\.:]+$/i) {
      $html->message('err', $lang{ERROR}, "$lang{ERR_WRONG_DATA} MAC: '$FORM{MAC}'");
    }

    $FORM{NAS_MNG_IP_PORT} = ($FORM{NAS_MNG_IP} || '') . ":" . ($FORM{COA_PORT} || '') . ":" . ($FORM{SSH_PORT} || '') . ":" . ($FORM{SNMP_PORT} || '');

    $Nas->change({ %FORM, DOMAIN_ID => $admin->{DOMAIN_ID} });
    if (!$Nas->{errno}) {
      $html->message('info', $lang{CHANGED}, "$lang{CHANGED} $Nas->{NAS_ID}");

      if ($conf{RESTART_RADIUS}) {
        cmd($conf{RESTART_RADIUS});
        $html->message('info', $lang{SUCCESS}, "Freeradius $lang{RESTART}");
      }
      else{
        if($FORM{NAS_TYPE} =~ /(cisco|mikrotik|accel_ppp|mpd5|mx80|redback|other)/){
          $html->message( 'warning', $lang{TIP},
            "$lang{RESTART} Freeradius $lang{OR} $lang{ADD} \$conf{RESTART_RADIUS} $lang{IN} config.pl" );
        }
      }
    }
  }

  _error_show($Nas);

  $Nas->{LNG_ACTION} = $lang{CHANGE};
  $Nas->{ACTION}     = 'change';

  form_nas_add({ NAS => $Nas });

  return 0;
}


#**********************************************************
=head2 form_nas_list() - nas add

=cut
#**********************************************************
sub form_nas_list {

  if ($FORM{search}) {
    form_search({ CONTROL_FORM => 1 });
  }
  elsif ($FORM{GID}) {
    $LIST_PARAMS{GID}       = $FORM{GID};
    $LIST_PARAMS{PAGE_ROWS} = 1000;
  }
  else {
    $LIST_PARAMS{GID} = undef;
  }

  $LIST_PARAMS{DOMAIN_ID} = $admin->{DOMAIN_ID} if ($admin->{DOMAIN_ID});
  $LIST_PARAMS{SHORT} = 1;

  my %status_hash = (
    0 => $lang{ENABLE},
    1 => $lang{DISABLE},
    2 => $lang{NOT_ACTIVE}
  );

  my %ext_titles = (
    nas_id           => 'ID',
    nas_name         => $lang{NAME},
    nas_identifier   => 'NAS-Identifier',
    nas_ip           => 'IP',
    nas_type         => $lang{TYPE},
    disable          => $lang{DISABLE},
    descr            => $lang{DESCRIBE},
    nas_group_name   => $lang{GROUP},
    domain_id        => 'DOMAIN_ID',
    alive            => 'Alive',
    mac              => 'MAC',
    nas_mng_host_port=> 'NAS_MNG_HOST_PORT',
    nas_mng_user     => 'NAS_MNG_USER',
    #nas_mng_password => 'MNG_PASSWORD',
    number           => "$lang{NUM}",
    flors            => "$lang{ADDRESS} $lang{FLORS}",
    entrances        => "$lang{ADDRESS} $lang{ENTRANCES}",
    flats            => "$lang{ADDRESS} $lang{FLATS}",
    street_name      => "$lang{ADDRESS} $lang{STREETS}",
    address_full     => "$lang{FULL} $lang{ADDRESS}",

    #users_count      => "$lang{CONNECTED} $lang{USERS}",
    #users_connections=> "$lang{DENSITY_OF_CONNECTIONS}",
    added       => $lang{ADDED},
    location_id => "LOCATION ID"
  );

  if (in_array('Multidoms', \@MODULES) && !$admin->{DOMAIN_ID}) {
    $ext_titles{domain_id} = 'Domain ID';
  }

  result_former(
    {
      INPUT_DATA     => $Nas,
      FUNCTION       => 'list',
      BASE_FIELDS    => 0,
      DEFAULT_FIELDS => 'NAS_ID,NAS_NAME,NAS_IDENTIFIER,NAS_IP,NAS_TYPE,DISABLE,DESCR',
      MAP            => (!$FORM{UID}) ? 1 : undef,
      MAP_FIELDS     => 'NAS_ID,NAS_NAME,NAS_IP',
      MAP_ICON       => 'nas',

      #      MAP_FILTERS     => { id => 'search_link:msgs_admin:UID,chg={ID}' },
      FUNCTION_FIELDS => (
        (in_array('Internet', \@MODULES))
          ? 'internet_users_list:$lang{USERS}:nas_id:&PORT=*&VLAN=*&search=1&search_form=1,'
          : 'dhcphosts_hosts:$lang{USERS}:nas_id:&VIEW=1&search=1&search_form=1,'
      )
        . 'form_ip_pools:IP_Pool:nas_id,form_nas:change:nas_id,'
        . ((($permissions{4} && $permissions{4}{3})) ? 'del' : ''),
      MULTISELECT => (in_array('Equipment', \@MODULES)) ? 'NAS_ID:nas_id' : '',
      EXT_TITLES => \%ext_titles,
      SKIP_USER_TITLE => 1,
      SELECT_VALUE    => {
        auth_type => \%auth_types,
        disable   => \%status_hash,
      },
      FILTER_COLS => {
        users_count => 'search_link:form_search:LOCATION_ID,type=11',
      },
      TABLE => {
        width          => '100%',
        caption        => $lang{NAS},
        qs             => $pages_qs,
        SHOW_FULL_LIST => 1,
        ID             => 'NAS_LIST',
        EXPORT         => 1,
        SELECT_ALL     => (in_array('Equipment', \@MODULES)) ? "nas_list:NAS_ID:$lang{SELECT_ALL}" : '',
        MENU           => "$lang{ADD}:add_form=1&index=" . get_function_index('form_nas') . ':add' . ";$lang{SEARCH}:search_form=1&index=" . get_function_index('form_nas') . "&type=13:search"
      },
      MAKE_ROWS => 1,
      TOTAL     => 1
    }
  );

  return 1;
}


#**********************************************************
=head2 form_nas_add() - nas add

=cut
#**********************************************************
sub form_nas_add {
  $Nas->{SEL_TYPE} = $html->form_select(
    'NAS_TYPE',
    {
      SELECTED => $Nas->{NAS_TYPE},
      SEL_HASH => nas_types_list(),
      SORT_KEY => 1
    }
  );

    $Nas->{SEL_NAS_MODEL} = $html->form_select(
    'NAS_MODEL',
    {
      SELECTED => $Nas->{NAS_MODEL},
      SEL_HASH => undef,
      SORT_KEY => 1
    }
  );

  $Nas->{SEL_AUTH_TYPE} = $html->form_select(
    'NAS_AUTH_TYPE',
    {
      SELECTED => $Nas->{NAS_AUTH_TYPE},
      SEL_HASH => \%auth_types,
    }
  );

  $Nas->{NAS_EXT_ACCT} = $html->form_select(
    'NAS_EXT_ACCT',
    {
      SELECTED     => $Nas->{NAS_EXT_ACCT},
      SEL_ARRAY    => [ '---', 'IPN' ],
      ARRAY_NUM_ID => 1
    }
  );
  $Nas->{NAS_DISABLE}    = ($Nas->{NAS_DISABLE} && $Nas->{NAS_DISABLE} > 0) ? ' checked' : '';
  $Nas->{ADDRESS_FORM}   = form_address({
    LOCATION_ID  => $Nas->{LOCATION_ID},
    ADDRESS_FLAT => $Nas->{ADDRESS_FLAT},
    FLOOR        => $Nas->{FLOOR},
    ENTRANCE     => $Nas->{ENTRANCE}
  });
  $Nas->{NAS_GROUPS_SEL} = sel_nas_groups({ GID => $Nas->{GID} });

  if ($Nas->{NAS_ID}) {
    $Nas->{NAS_ID_FORM} = $html->tpl_show(
      templates('form_row'),
      {
        ID    => "",
        NAME  => 'ID',
        VALUE => $html->b($Nas->{NAS_ID}) . ' ' . $Nas->{CHANGED}
      },
      { OUTPUT2RETURN => 1 }
    );
  }

  if ($Nas->{NAS_MNG_IP_PORT}) {
    ($Nas->{NAS_MNG_IP}, $Nas->{COA_PORT}, $Nas->{SSH_PORT}, $Nas->{SNMP_PORT}) = split(':', $Nas->{NAS_MNG_IP_PORT});
  }

  if ($Nas->{NAS_TYPE} && $Nas->{NAS_TYPE} eq "mikrotik_dhcp") {
    $Nas->{WINBOX} = $html->button( "W", '', {
      GLOBAL_URL     => "winbox://",
      NO_LINK_FORMER => 1,
      target         => '_blank',
      class          => 'btn input-group-button rounded-left-0',
      TITLE          => "Winbox",
#      ex_params      => "data-tooltip='Winbox'",
      });
  }

  $Nas->{RAD_PAIRS_FORM} = $html->tpl_show(
    templates('form_radius_pairs'),
    {
      RAD_PAIRS => AXbills::Radius_Pairs::parse_radius_params_string(
        $Nas->{NAS_RAD_PAIRS}
      ),
      SAVE_INDEX => get_function_index('nas_radius_pairs_save'),
      ID => $Nas->{NAS_ID}
    },
    { OUTPUT2RETURN => 1 }
  );

  $html->tpl_show(templates('form_nas'), $Nas, { ID => 'form_nas' });

  return 1;
}

#**********************************************************
=head2 form_nas_console($NAS, $attr)

=cut
#**********************************************************
sub form_nas_console {
  my ($Nas_) = @_;

  if ($FORM{SAVE} && !$FORM{change}) {
    $Nas_->nas_cmd_add({%FORM});

    if (!$Nas_->{errno}) {
      $html->message('info', "$lang{SUCCESS}", "$lang{ADDED}");
    }
  }
  elsif ($FORM{del}) {
    $Nas_->nas_cmd_del({ ID => $FORM{del} });

    if (!$Nas_->{errno}) {
      $html->message('info', "$lang{SUCCESS}", "$lang{DELETED}");
    }
  }
  elsif ($FORM{info}) {
    my $cmd_info = $Nas_->nas_cmd_info({ ID => $FORM{info}, COLS_NAME => 1 });

    $FORM{CMD}      = $cmd_info->{CMD};
    $FORM{COMMENTS} = $cmd_info->{COMMENTS};
    $FORM{TYPE}     = $cmd_info->{TYPE};
    $FORM{change}   = $FORM{info};
  }
  elsif ($FORM{change} && $FORM{SAVE}) {
    $Nas_->nas_cmd_change({ ID => $FORM{change}, %FORM });

    if (!$Nas_->{errno}) {
      $html->message('info', "$lang{SUCCESS}", "$lang{CHANGED}");
    }
  }

  _error_show($Nas_);

  if ($FORM{ACTION}) {
    form_nas_console_command($Nas_, \%FORM);
  }

  my @quick_cmd = ();
  if ($Nas_->{NAS_TYPE} eq 'mpd5') {
    @quick_cmd = ('show radsrv', 'show sessions');
  }
  elsif ($Nas_->{NAS_TYPE} =~ /accel/) {
    @quick_cmd = ('show sessions', 'show stat', 'reload');
  }
  elsif ($Nas_->{NAS_TYPE} =~ /mikrotik/) {
    @quick_cmd = ('export compact',
      '/ip firewall filter print',
      '/ip firewall nat print',
      '/queue tree print',
      '/queue type print',
      '/queue simple print',
      '/ip firewall address-list print',
      '/ip dhcp-server lease print',
      '/log print',
      '/interface pppoe-server print'
    );
  }
  elsif ($Nas_->{NAS_TYPE} =~ /cisco/) {
    @quick_cmd = ('rsh:show run', 'rsh:sh sss session', 'rsh:show log', 'rsh:show interf', 'rsh:show arp', 'rsh:show radius statistics', 'show radius server-group all', 'rsh:sh ver');
  }
  elsif ($Nas_->{NAS_TYPE} =~ /mx80/) {
    @quick_cmd = ('ssh:show system uptime', 'ssh:show bgp summary', 'ssh:show subscribers summary', 'ssh:show dhcp server binding', 'ssh:show dhcp server binding summary', 'ssh:show interfaces | match "Physical link is Up"', 'ssh:show system memory', 'ssh:show chassis environment pem');
  }

  foreach my $cmd (@quick_cmd) {
    if($FORM{CMD} && $FORM{CMD} eq $cmd){
      $Nas_->{QUICK_CMD} .= $html->button($cmd, "index=$index&console=1&NAS_ID=$FORM{NAS_ID}&full=1&CMD=$cmd&ACTION=1", { class =>'btn btn-xs btn-success' });
    }
    else {
      $Nas_->{QUICK_CMD} .= $html->button($cmd, "index=$index&console=1&NAS_ID=$FORM{NAS_ID}&full=1&CMD=$cmd&ACTION=1", { BUTTON => 2 });
    }
  }

  $Nas_->{TYPE_SEL} = $html->form_select(
    'TYPE',
    {
      SELECTED  => $FORM{TYPE},
      SEL_ARRAY => [ 'telnet', 'ssh', 'rsh' ]
    }
  );

  $html->tpl_show(templates('form_nas_console'), { %$Nas_, %FORM }, { ID => 'form_nas_console' });

  my $table = $html->table(
    {
      width   => '100%',
      caption => "NAS $lang{COMMAND}",
      title   => [ "ID", "NAS", $lang{COMMAND}, $lang{TYPE}, $lang{COMMENTS} ],
      qs      => $pages_qs,
      ID      => 'NAS_CMD',
      export  => 1
    }
  );

  my $cmd_list = $Nas_->nas_cmd_list({ COLS_NAME => 1 });

  foreach my $saved_cmd (@$cmd_list) {
    my $del_button = $html->button($lang{DEL}, "index=62&NAS_ID=$Nas_->{NAS_ID}&console=1&full=1&del=$saved_cmd->{id}", { DEL => 1 });
    my $chg_button = $html->button($lang{CHANGE}, "index=62&NAS_ID=$Nas_->{NAS_ID}&console=1&full=1&info=$saved_cmd->{id}", { CHANGE => 1 });

    $table->addrow($saved_cmd->{id}, $Nas_->{NAS_NAME}, $saved_cmd->{cmd}, $saved_cmd->{type}, $saved_cmd->{comments}, "$chg_button $del_button");
  }

  print $table->show();
  return 1;
}
#**********************************************************
=head2 form_nas_console_command($Nas_, $attr) - runs command on NAS and prints its output with HTML formatting

  Arguments
    $Nas_
      NAS_ID
      NAS_IP
      NAS_NAME
      NAS_TYPE
      NAS_MNG_IP_PORT
      NAS_MNG_USER
      NAS_MNG_PASSWORD
    $attr
      NAS_MNG_IP_PORT
      NAS_MNG_USER
      NAS_MNG_PASSWORD
      CMD - command to run on NAS
      TYPE - connection type (protocol) to connect to NAS, telnet/ssh/rsh
      SIMPLER_OUTPUT - simpler output format, <pre> instead of table
      NAS_INFO_IN_CAPTION - print NAS info (id, name, ip) in caption
      TIMEOUT - timeout. currently works only for telnet
      DEBUG

=cut
#***********************************************************
sub form_nas_console_command {
  my ($Nas_, $attr) = @_;

  my $result;
  my $col_delimeter = '';
  my $nas_id = $attr->{NAS_ID} || '';
  $pages_qs = "&console=1&NAS_ID=$nas_id&full=1&ACTION=1&CMD=$attr->{CMD}";

  $Nas_->{NAS_MNG_IP_PORT}  = $attr->{NAS_MNG_IP_PORT}  if ($attr->{NAS_MNG_IP_PORT});
  $Nas_->{NAS_MNG_USER}     = $attr->{NAS_MNG_USER}     if ($attr->{NAS_MNG_USER});
  $Nas_->{NAS_MNG_PASSWORD} = $attr->{NAS_MNG_PASSWORD} if ($attr->{NAS_MNG_PASSWORD});

  my $wait_char = ']';

  require AXbills::Nas::Control;
  AXbills::Nas::Control->import(qw/rsh_cmd/);
  AXbills::Nas::Control->new($db, \%conf);

  $admin->system_action_add("NAS_Command:$attr->{CMD}", { TYPE => 14 });

  if ($attr->{CMD} =~ /^([a-z]+):(.+)/) {
    $attr->{TYPE} = $1 || q{};
    $attr->{CMD}  = $2 || q{};
  }

  my $table = $html->table({
    caption    => "$lang{RESULT}: $attr->{CMD}" . ($attr->{NAS_INFO_IN_CAPTION} ? " (NAS $Nas_->{NAS_ID}: $Nas_->{NAS_NAME}, $Nas_->{NAS_IP})" : ''),
    ID         => 'CONSOLE_RESULT',
    qs         => $pages_qs,
    DATA_TABLE => 1,
    EXPORT     => 1,
    MENU       => "$lang{SAVE}::btn bg-olive margin export-btn", #XXX does not work
  });

  my $total_rows = 0;

  my $type = $attr->{TYPE} || '';
  my $online_index = get_function_index('internet_online');

  if ($Nas_->{NAS_TYPE} =~ /mpd|accel/ || ($type eq 'telnet')) {
    my $telnet_attr = {
      PROMPT  => ($conf{NAS_MNG_PROMPT} ? $conf{NAS_MNG_PROMPT} : '\n.*[\$%#\]>\?] ?$'),
      TIMEOUT => $attr->{TIMEOUT}
    };

    if ($Nas_->{NAS_TYPE} =~ /accel/) {
      $wait_char     = '#'; #XXX should be used as prompt for accel? test it.
    }
    elsif ($Nas_->{NAS_TYPE} =~ /mpd/) {
      $telnet_attr->{PROMPT}  = '\n\[.*\] $';
      $telnet_attr->{NO_CRLF} = 1; #mpd interprets CRLF as two newlines somewhy
    }

    $col_delimeter = '\||\+'; #XXX sometimes splits lines when it shouldn't (example: mikrotik's /system clock print, "gmt-offset: +03:00")

    my ($nas_ip, $nas_rad_port, $nas_telnet_port, undef) = split(/:/, $Nas_->{NAS_MNG_IP_PORT} || q{});

    if (!$nas_telnet_port) {
      $nas_telnet_port = $nas_rad_port || 23;
    }

    require AXbills::Telnet;
    AXbills::Telnet->import();
    my $t = AXbills::Telnet->new($telnet_attr);

    $t->set_terminal_size(256, 1000);

    if (!$t->open("$nas_ip:$nas_telnet_port")) {
      $html->message('err', $lang{ERROR} . ' Telnet', $t->errstr());
      return 0;
    }

    if (!$t->login($Nas_->{NAS_MNG_USER}, $Nas_->{NAS_MNG_PASSWORD})) {
      $html->message('err', $lang{ERROR} . ' Telnet', $t->errstr());
      return 0;
    }

    $result = [];
    $attr->{CMD} =~ s/\r//g;
    my @cmds = split '\n', $attr->{CMD};
    foreach my $cmd (@cmds) { #XXX only result of last cmd will be shown, is it ok?
      $result = $t->cmd($cmd);
      sleep 1;
      if (!$result) {
        $html->message('err', $lang{ERROR} . ' Telnet', $t->errstr());
        $result = [];
      }
    }

    if (!$attr->{SIMPLER_OUTPUT}) {
      my @caption = ();

      if($result->[0] && $result->[0] =~ /\|/) {
        if ($result && $#{$result} > -1) {
          @caption = split('\|', $result->[0]);
        }

        $result->[0] = undef;
        $result->[1] = undef;
      }

      my $ip_col = 3;
      my $acct_session_col = 2;
      if($attr->{CMD} eq "show sessions"){
        if($Nas_->{NAS_TYPE} =~ /mpd/) {
          @caption = ('IF', 'client_ip', 'BUNDLE', 'SESSION_ID', 'VLAN', '-', 'acct_session_id', $lang{LOGIN}, 'MAC', $lang{USER}, $lang{HANGUP});
          $ip_col = 1;
          $acct_session_col = 6;
        }
        else {
          push(@caption, $lang{USER}, $lang{HANGUP});
          $ip_col = 3;
        }

        my $users_online = _get_online({ NAS_ID => $nas_id });

        foreach my $line ( @{$result} ) {
          if($line){
            $line =~ s/\s+$//g;
            $line =~ s/\s+/\|/g;
            my @row = split('\|', $line || '');

            my $ip = $row[$ip_col] || q{};
            $ip =~ s/\s+//g;
            next if(! $ip);

            my $uid             = $users_online->{$ip}->{uid} || '';
            my $login           = $users_online->{$ip}->{login} || '';
            my $nas_port_id     = $users_online->{$ip}->{nas_port_id} ? $users_online->{$ip}->{nas_port_id} : '';
            my $acct_session_id = $users_online->{$ip}->{acct_session_id} || $row[$acct_session_col] || '';
            my $user_name       = $users_online->{$ip}->{user_name} || '';

            if($uid && $login){
              $line .= " |". $html->button($login, "index=15&UID=$uid");
            }
            else {
              $line .= " |";
            }
            $line .= " |". $html->button('H',
              "index=$online_index&FRAMED_IP_ADDRESS=$ip&hangup=$nas_id%2B$nas_port_id%2B$acct_session_id%2B$user_name"
              , { TITLE => 'Hangup', class => 'off',
                NO_LINK_FORMER => 1
              });

            delete $users_online->{$ip};
          }
        }
      }
      $table->{table} .= $table->table_title_plain(\@caption);
    }
  }
  elsif ($type eq 'rsh') {
    $result = AXbills::Nas::Control::rsh_cmd($attr->{CMD}, {
      DEBUG => $attr->{DEBUG} || undef,
      %$Nas_,
      RSH_CMD => $conf{RSH_CMD}
    });
  }
  elsif ($Nas_->{NAS_TYPE} =~ 'mikrotik' && $attr->{CMD} ne "export compact") {
    require AXbills::Nas::Mikrotik;
    AXbills::Nas::Mikrotik->import();
    my $Mikrotik = AXbills::Nas::Mikrotik->new(
      $Nas_,
      \%conf,
      {
        FROM_WEB         => 1,
        MESSAGE_CALLBACK => sub { $html->message('info', $_[0], $_[1]) },
        ERROR_CALLBACK   => sub { $html->message('err', $_[0], $_[1]) },
        DEBUG            => $attr->{DEBUG} || 0
      }
    );

    if(! $Mikrotik) {
      $html->message('err', $lang{ERROR}, "Not defined NAS IP address and Port");
      return 0;
    }
    elsif (! $Mikrotik->has_access() eq 1){
      $html->message('err', $lang{ERROR}, "No access to $Mikrotik->{ip_address}:$Mikrotik->{port} ($Mikrotik->{backend})"
       . (($Mikrotik->{errstr}) ? "\n$Mikrotik->{errstr}" : q{})
      );
      return 0;
    }

    my $cmd = $attr->{CMD};
    if (!$cmd){
      $html->message('err', $lang{ERROR}, "Need command to execute");
      return 0;
    }
    ######## IMPORTANT ########
    # You can't JUST add new entry
    # List command should be defined both in
    #   Nas::Mikrotik::SSH LIST_REFS
    # and
    #   Nas::Mikrotik::API LIST_REFS
    # Otherwise result will not be parseable
    my %cmd_list = (
      '/ip firewall nat print'          => 'firewall_nat',
      '/queue tree print'               => 'queue_tree',
      '/queue type print'               => 'queue_type',
      '/queue simple print'             => 'queue_simple',
      '/ip firewall filter print'       => 'firewall_filter_list',
      '/ip firewall address-list print' => 'firewall_address__list',
      '/ip dhcp-server lease print'     => 'dhcp_leases',
      '/log print'                      => 'log_print'
    );

    if (exists $cmd_list{$cmd} && $cmd_list{$cmd} && $Mikrotik->has_list_command($cmd_list{$cmd})) {
      $result = $Mikrotik->get_list($cmd_list{$cmd});
      if ($result && ref $result eq 'ARRAY' && scalar @$result) {
        $total_rows = scalar @$result;

        ## We need get all keys, but id and flag should stay first
        # So here we get all keys
        my $first_hash = $result->[0];
        my %hash_copy  = %$first_hash;

        # Delete what we don't need to see in keys %()
        delete $hash_copy{id};
        delete $hash_copy{flag};

        # And write columns in order we want
        my @columns = ('id', 'flag', sort keys %hash_copy);

        if ($cmd_list{$cmd} eq 'firewall_address__list') {
          push(@columns, $lang{USER}, $lang{DEL});

          my $users_online = _get_online({ NAS_ID => $nas_id });

          foreach my $line ( @{$result} ) {
            $line->{ $lang{USER} } =
              ($line->{address} && exists $users_online->{ $line->{address} })
                ? user_ext_menu($users_online->{ $line->{address} }->{uid},
                $users_online->{ $line->{address} }->{login})
                : '';

            $line->{ $lang{DEL} } = $html->button(
              "", undef,
              {
                class     => 'btn btn-xs btn-danger removeIpBtn',
                ex_params => "data-address-number='" . ($line->{id} || $line->{'.id'} || q{}) . "'",
                SKIP_HREF => 1,
                ICON      => 'fa fa-times'
              }
            );
          }
        }

        $table->{table} .= $table->table_title_plain(\@columns);

        #          $table = $html->table({
        #            width       => '500',
        #            caption     => "$lang{RESULT}: $attr->{CMD}",
        #            title_plain => \@columns,
        #            ID          => 'CONSOLE_RESULT',
        #            EXPORT      => 1,
        #          });
        foreach my $row (@$result) {
          # Using hash slice to get ordered values
          $table->addrow(@$row{@columns});
        }
      }
    }
    else {
      $cmd =~ s/ +/\//g;
      $result = $Mikrotik->execute([ [$cmd] ], { SHOW_RESULT => 1 });
      $html->pre($result);
    }
    $result = [];
  }
  else {
    $table->{table} .= $table->table_title_plain(["result"]);
    $attr->{CMD} =~ s/\\\"/\"/g;
    $result = ssh_cmd($attr->{CMD}, {
      DEBUG => $attr->{DEBUG},
      %$Nas_
    });
    my @result2 = ();
    my $half_string = "";
    foreach my $line (@$result) {
      if ($half_string) {
        if ($half_string =~ m/\=$/) {
          $line =~ s/^\s+//;
        }
        else {
          $line =~ s/^\s+/ /;
        }
        push (@result2, $half_string . $line);
        $half_string = "";
        next;
      }
      if ($line =~ m/\\/) {
        $half_string = $line;
        $half_string =~ s/\\//;
        $half_string =~ s/\s+$//;
        next;
      }
      else {
        push (@result2, $line);
      }
    }

    $result = \@result2;

    if (!$result) {
      $result = [];
    }
  }

  my $internet_online = {};
  if ($attr->{CMD} =~ /^sh sss session$/) {
    $col_delimeter = '\s+';
    $internet_online = _get_online({
      NAS_ID    => $nas_id,
      KEY_FIELD => 'login',
    });
  }

  if ($attr->{SIMPLER_OUTPUT}) {
    print $html->message(
      (@$result) ? 'info' : 'err',
      "$lang{RESULT}: $attr->{CMD}" . ($attr->{NAS_INFO_IN_CAPTION} ? " (NAS $Nas_->{NAS_ID}: $Nas_->{NAS_NAME}, $Nas_->{NAS_IP})" : ''),
      (@$result) ? $html->element('pre', join("\n", @$result), { class => 'border rounded bg-light' }) : $lang{ERROR}
    );
  }
  else {
    foreach my $line (@{$result}) {
      next if (!$line);
      my @row = ();

      if ($col_delimeter) {
        @row = split(/$col_delimeter/, $line || q{});
      }
      elsif ($attr->{CMD} =~ /compact/) {
        push @row, $line;
      }
      else {
        $line =~ s/\s/\&nbsp;/g;
        push @row, $html->color_mark($line, 'code');
      }

      if ($attr->{CMD} =~ /^sh sss session$/) {
        if ($#row > 6) {
          next;
        }
        if ($row[0] && $row[0] !~ /^Current/) {
          push @row, $html->button($lang{SHOW},
            "index=$index&console=1&NAS_ID=$nas_id&full=1&CMD=rsh:sh sss session uid $row[0]&ACTION=1",
            { BUTTON => 1});
        }

        if ($row[6]) {
          my $user_name = $row[6];
          if ($internet_online && $internet_online->{$user_name}) {
            my $nas_port_id = q{};
            my $acct_session_id = q{};
            my $ip = $internet_online->{$user_name}->{client_ip};
            $row[6] = $html->button($user_name,
              "index=$online_index&FRAMED_IP_ADDRESS=$ip&hangup=$nas_id%2B$nas_port_id%2B$acct_session_id%2B$user_name");

            delete $internet_online->{$user_name};
          }
        }
      }

      $table->addrow(@row);
      $total_rows++;
    }

    foreach my $user_name (keys %$internet_online) {
      my $ip = $internet_online->{$user_name}->{client_ip};
      print "$ip - ". $html->button($user_name, "index=$online_index&LOGIN=$user_name") . $html->br();
    }

    print $table->show();

    # foreach my $login (keys %$internet_online) {
    #   print "$login<br>";
    # }

    if ($total_rows) {
      $table = $html->table({
        width => '100%',
        rows  => [ [ "$lang{TOTAL}:", $html->b($total_rows) ] ]
      });
      print $table->show();
    }
  }

  return 1;
}

#**********************************************************
=head2 form_mrtg_cfg($Nas)

  Arguments:
    $Nas
  Returns:

=cut
#**********************************************************
sub form_mrtg_cfg {
  my Nas $Nas_ = shift;
  my ($attr) = @_;

  if (!$Nas_) {
    $Nas_ = Nas->new($db, \%conf, $admin);
    $Nas_->info({ NAS_ID => $attr->{NAS_ID} }) if ($attr->{NAS_ID});
  };

  #my $comments;
  $FORM{query_type} //= 1;

  my $mrtg_cfgmaker = cmd("which cfgmaker");
  $mrtg_cfgmaker =~ s/[\r\n]+$//;
#  print $mrtg_cfgmaker;
  if ($mrtg_cfgmaker) {
    my @SELECT_DATA = `ls /usr/axbills/misc/mrtg/templates/`;
    my $select = $html->form_select(
      'SELECT_NAME',
      {
        SELECTED     => $FORM{SELECT_NAME},
        SEL_ARRAY    => \@SELECT_DATA,
        ARRAY_NUM_ID => 1
      }
    );
    my $nas_name = $Nas->{NAS_NAME};
    if ( $FORM{confirm} ) {
      my $mrtg_template = $SELECT_DATA[$FORM{SELECT_NAME}];
      $mrtg_template =~ s/\s//g;;
      $html->message('info', "$lang{INFO}", "$mrtg_cfgmaker --nointerfaces \ <br>--global \"WorkDir: $FORM{WORK_DIR}\" \ <br>--host-template /usr/axbills/misc/mrtg/templates/$SELECT_DATA[$FORM{SELECT_NAME}] $FORM{COMMUNITY}\@$Nas->{NAS_IP}");
      my $mrtg_make_cfg = "$mrtg_cfgmaker --global=\'WorkDir: $FORM{WORK_DIR}\' --nointerfaces --host-template=\'/usr/axbills/misc/mrtg/templates/$mrtg_template\' $FORM{COMMUNITY}\@$Nas->{NAS_IP}";
      print $mrtg_make_cfg;
      my $result = cmd("$mrtg_make_cfg");
      my $strings_num = $result =~ tr/\n//;
      if ($strings_num == 0) {
        $html->message('error', "$lang{ERROR}", "No SNMP data received from $Nas->{NAS_IP}");
        return 1;
        }
      print "<textarea readonly cols=120 rows=$strings_num>$result</textarea>";
    }
    $html->tpl_show(templates('form_mrtg'), {SELECT => $select, NAME => $nas_name, %FORM});
   }
  else {
    $html->message('error', $lang{ERROR}, "No cfgmaker found. Is MRTG installed ?");
    return 1;
  }
 
  return 1;
}
#**********************************************************
=head2 form_nas_test($Nas, $attr)

  Arguments:
    $Nas
    $attr
      USER_TEST
      RAD_REQUEST

  Returns:

=cut
#**********************************************************
sub form_nas_test {
  my Nas $Nas_ = shift;
  my ($attr) = @_;

  if (!$Nas_) {
    $Nas_ = Nas->new($db, \%conf, $admin);
    $Nas_->info({ NAS_ID => $attr->{NAS_ID} }) if ($attr->{NAS_ID});
  }

  my $comments;
  $FORM{query_type} //= 1;

  # test start
  if ($FORM{runtest}) {
    my $ip     = $conf{RADIUS_TEST_IP}     || '127.0.0.1';
    my $secret = $conf{RADIUS_TEST_SECRET} || 'secretpass';
    my ($mng_port, $second_port) = ('1812', '1812');

    if($ip =~ /(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}):(\d+):(\d+)/) {
      $ip          = $1;
      $mng_port    = $2;
      $second_port = $3;
    }

    my $request_type = 'ACCESS_REQUEST';

    # settings for radius statistics
    if (defined $FORM{query_type} && ($FORM{query_type} >= 5 && $FORM{query_type} <= 7)) {
      $ip       = '127.0.0.1';
      $secret   = 'adminsecret';
      $mng_port = '18121';
    }
    if (defined $FORM{query_type} && $FORM{query_type} == 2) {
      $mng_port     = '1813';
      $request_type = 'ACCOUNTING_REQUEST';
    }

    # settings for COA
    elsif (defined $FORM{query_type} && ($FORM{query_type} == 4 || $FORM{query_type} == 3)) {
      if (!$Nas_->{NAS_MNG_IP_PORT}) {
        print "Can't find NAS IP and port. NAS: $Nas_->{NAS_ID}\n";
        return 'ERR:';
      }

      ($ip, $mng_port, $second_port) = split(/:/, $Nas_->{NAS_MNG_IP_PORT} || q{}, 3);
      $mng_port = 1700 if (!$mng_port);
      $secret = $Nas_->{NAS_MNG_PASSWORD};
    }

    if ($FORM{TYPE}) {
      if (!$Nas_->{NAS_MNG_IP_PORT}) {
        print "Radius Hangup failed. Can't find NAS IP and port. NAS: $Nas_->{NAS_ID}\n";
        return 'ERR:';
      }

      ($ip, $mng_port, $second_port) = split(/:/, $Nas_->{NAS_MNG_IP_PORT} || q{}, 3);
      $mng_port     = 1700 if (!$mng_port);
      $request_type = $FORM{TYPE};
      $secret       = $Nas_->{NAS_MNG_PASSWORD};
    }

    my $table = $html->table(
      {
        width   => '100%',
        caption => "RAD_REPLY $ip:$mng_port " . ((!$attr->{USER_TEST}) ? " Secret: " . ($Nas_->{NAS_MNG_PASSWORD} || q{}) : ''),
        title  => [ "KEY", "$lang{VALUE}" ],
        ID     => 'RAD_TEST_REPLY',
        class  => 'table',
        EXPORT => 1,
      }
    );

    require Radius;
    Radius->import();

    my $r = Radius->new(
      Host   => "$ip:$mng_port",
      Secret => $secret,
      Debug  => $attr->{DEBUG} || 0
    ) or print $html->message('err', $lang{ERROR}, "Can't connect '$ip:$mng_port' $!");

    $conf{'dictionary'} = $base_dir . '/lib/dictionary' if (!$conf{'dictionary'});

    if (!$r->load_dictionary($conf{'dictionary'})) {
      $html->message('err', $lang{ERROR}, "Error load dictionary");
    }

    # if query_type equel simple radius auth
    if ($FORM{query_type} < 4 || $FORM{query_info}) {
      my $type;
      if ($FORM{query_info}) {
        my $q_info = $Nas_->query_info({ ID => $FORM{query_info} });
        $FORM{RAD_REQUEST} = $q_info->{RAD_QUERY};
        $comments = $q_info->{COMMENTS};
      }
      elsif ($attr->{RAD_REQUEST}) {
        $FORM{RAD_REQUEST} = $attr->{RAD_REQUEST};
      }

      my @pairs_arr = split(/[\r\n]/, $FORM{RAD_REQUEST} || q{});
      $FORM{RAD_REQUEST} = '';
      $r->clear_attributes();

      foreach my $line (@pairs_arr) {
        my ($key, $val) = split(/=/, $line || q{}, 2);
        next if (!$key);
        $val //= q{};
        $key =~ s/\s+//g;
        $val =~ s/^\s+//g;
        $val =~ s/\s+$//g;
        $val =~ s/^\\?\"//g;
        $val =~ s/\\?\"$//g;

        $r->add_attributes({ Name => $key, Value => $val });

        $table->addrow($key, $val);
        $FORM{RAD_REQUEST} .= "$key = $val\n";
      }

      if ($FORM{RAD_REQUEST} !~ m/NAS-IP-Address/g) {
        if (!$r->add_attributes({ Name => 'NAS-IP-Address', Value => $Nas_->{NAS_IP} })) {
          print "Error";
        }
        $table->addrow('NAS-IP-Address', $Nas_->{NAS_IP});
      }

      #    my $request_type = ($attr->{COA}) ? 'COA' : 'POD';
      #    if ($attr->{COA}) {
      #      $r->send_packet(COA_REQUEST) and $type = $r->recv_packet;
      #    }
      #    else {
      #      $r->send_packet(POD_REQUEST) and $type = $r->recv_packet;
      #    }

      my $request_num = 1;

      if ($FORM{query_type} == 2) {
        $request_num = 4;
      }
      elsif ($FORM{query_type} == 4) {
        $request_num = 44;
      }
      elsif ($FORM{query_type} == 5) {
        $request_num = 40;
      }

      $r->send_packet($request_num) and $type = $r->recv_packet;
      if (!defined $type) {

        # No responce from COA/POD server
        my $message = "No responce from $request_type server '$ip:$mng_port'";
        $html->message('err', $lang{ERROR}, "$message");
      }
      else {
        if ($type == 3) {
          $table->{rowcolor} = 'bg-danger';
        }
        else {
          $table->{rowcolor} = 'bg-success';
        }

        $table->addrow("$lang{REPLY}", ($type == 3) ? 'ACCESS_REJECT' : 'ACCESS_ACCEPT');

        for my $rad_attr ($r->get_attributes()) {
          $table->addrow($rad_attr->{'Name'}, $rad_attr->{'Value'});
        }
      }
    }

    # if query_type equel statistics for radius server
    elsif ($FORM{query_type} >= 5 && $FORM{query_type} <= 7) {
      my $statistics_type = 1;

      if ($FORM{query_type} == 6) {
        $statistics_type = 2;
      }
      elsif ($FORM{query_type} == 7) {
        $statistics_type = 0x1f;
      }

      $r->clear_attributes();
      $r->add_attributes({ Name => 'FreeRADIUS-Statistics-Type', Value => $statistics_type });
      $r->add_attributes({ Name => 'Message-Authenticator',      Value => '0x00000000000000000000000000000000' });
      my $type;
      $r->send_packet(12) and $type = $r->recv_packet;

      if ($type) {
        for my $rad_attr ($r->get_attributes()) {

          # print "$rad_attr->{'Name'}, $rad_attr->{'Value'} <hr>";
          $table->{rowcolor} = 'info';
          $table->addrow($rad_attr->{'Name'}, $rad_attr->{'Value'});
        }
      }
      $FORM{RAD_REQUEST} = "FreeRADIUS-Statistics-Type = $statistics_type\n";
      $FORM{RAD_REQUEST} .= "Message-Authenticator = 0x00000000000000000000000000000000\n";
    }

    print $table->show();
  }

  if (!defined($FORM{RAD_REQUEST})) {
    $FORM{RAD_REQUEST} = 'User-Name=' . ($attr->{USER_NAME} || 'test');
  }

  if ($attr->{USER_TEST}) {
    return 1;
  }

  my %query_types = (
    '1' => 'Auth',
    '2' => 'Acct',
    '3' => 'PoD',
    '4' => 'CoA',
    '5' => "Status Auth",
    '6' => "Status Acct",
    '7' => "Status $lang{ALL}"
  );

  my $query_type_select = $html->form_select(
    'query_type',
    {
      SELECTED => $FORM{query_type} || 0,
      SEL_HASH => {%query_types},
      NO_ID    => 1,
    }
  );

  $html->tpl_show(
    templates('form_radtest'),
    {
      RAD_PAIRS  => $FORM{RAD_REQUEST},
      COMMENTS   => $comments,
      QUERY_TYPE => $query_type_select,
    }
  );

  # saving query to database
  if ($FORM{SAVE} && $FORM{query_type} == 1) {
    $Nas_->add_radtest_query(
      {
        COMMENTS  => $FORM{COMMENTS},
        RAD_QUERY => $FORM{RAD_REQUEST},
        DATETIME  => 'NOW()'
      }
    );

    _error_show($Nas_) || $html->message('info', $lang{ADDED}, "$lang{ADDED}");
  }

  # delete query from database
  if ($FORM{query_del}) {
    $Nas_->del_query({ ID => $FORM{query_del} });
    if (!_error_show($Nas_)) {
      $html->message('info', "$lang{DELETED}", "$lang{DELETED}");
    }
  }

  my $query_list = $Nas_->query_list({ COLS_NAME => 1 });

  # table with query list
  my $query_table = $html->table(
    {
      width   => '100%',
      caption => $lang{QUERY},
      title   => [ $lang{DATE}, $lang{COMMENTS}, $lang{QUERY} ],
      ID      => 'QUERY',
    }
  );

  # make query table rows
  foreach my $qr (@$query_list) {
    $query_table->addrow(
      $qr->{datetime}, $qr->{comments},
      $html->button("$lang{QUERY} . $qr->{id}", "index=$index&NAS_ID=$FORM{NAS_ID}&radtest=1&query_info=$qr->{id}&runtest=1"),
      $html->button($lang{DEL}, "index=$index&NAS_ID=$FORM{NAS_ID}&radtest=1&query_del=$qr->{id}", { MESSAGE => "$lang{DEL} $qr->{id}?", class => 'del' })
    );
  }

  print $query_table->show();

  return 1;
}

#**********************************************************
=head2 form_wrt_configure($attr)

=cut
#**********************************************************
sub form_wrt_configure {

  #my $wrt_default = "$libpath/libexec/wrt_defaults.cfg.default";
  my $content = '';

  if ($FORM{default}) {
    if (unlink("$conf{TPL_DIR}/wrt_defaults.cfg") == 1) {
      $html->message('info', $lang{DELETED}, "$lang{DELETED}: '$conf{TPL_DIR}/wrt_defaults.cfg'");
    }
    else {
      $html->message('err', $lang{DELETED}, "$lang{ERROR} $!");
    }
  }
  elsif ($FORM{change}) {
    foreach my $key (sort keys %FORM) {
      if ($key =~ /^\d+_wrt_/) {
        my $value = $FORM{$key};
        $key =~ s/^\d+_wrt_//g;
        $key =~ s/(_\d+)//;
        $key = convert($key, { html2text => 1 });
        $value =~ s/\\\\/\\/g;
        $value =~ s/\\\"/\"/g;
        $value =~ s/\\\'/\'/g;

        #$value =~ s/&rsquo;/\\\'/g;
        $content .= qq{$key "$value"\n};
      }
    }

    file_op(
      {
        WRITE    => 1,
        FILENAME => 'wrt_defaults.cfg',
        PATH     => $conf{TPL_DIR},
        CONTENT  => $content
      }
    );
  }

  my $table = $html->table({
    width   => '100%',
    caption => 'WRT CONFIGURE',
    title   => [ 'ID', $lang{VALUE}, '-' ],
    ID      => 'WRT_CONFIGURE',
    MENU    => "$lang{BACK}:NAS_ID=$FORM{nas}&index=$index:btn btn-xs btn-secondary"
  });

  my $rows = file_op(
    {
      FILENAME => (-f "$conf{TPL_DIR}/wrt_defaults.cfg") ? 'wrt_defaults.cfg' : 'wrt_defaults.cfg.default',
      PATH     => (-f "$conf{TPL_DIR}/wrt_defaults.cfg") ? $conf{TPL_DIR}     : '../../libexec/',
      ROWS     => 1
    }
  );

  my %main_hash = ();
  my $i         = 0;

  foreach my $line (@{$rows}) {
    my ($key, $value) = split(/\s+/, $line || q{}, 2);
    $key   //= '';
    $value //= '';

    $key =~ s/^\"|\"$//g;
    $value =~ s/^\"|\"$//g;

    my $input_name =
      $i . '_' . 'wrt_'
    . $key
    . (
      ($main_hash{$key})
      ? '_' . ($main_hash{$key} + 1)
      : ''
    );

    if ($key eq 'rc_startup') {
      $value = $html->form_textarea($input_name, $value);
    }
    else {
      $value = $html->form_input($input_name, $value);
    }

    $main_hash{$key}++;

    $table->addrow($key, $value);
    $i++;
  }

  print $html->form_main(
    {
      CONTENT => $table->show(),
      HIDDEN  => {
        index         => $index,
        nas           => $FORM{nas},
        wrt_configure => 1,
      },
      SUBMIT => {
        change  => $lang{CHANGE},
        default => $lang{DEFAULT}
      }
    }
  );

  return 1;
}

#**********************************************************
=head2 form_nas_groups()

=cut
#**********************************************************
sub form_nas_groups {
  $Nas->{ACTION}     = 'add';
  $Nas->{LNG_ACTION} = $lang{ADD};

  if ($FORM{add}) {
    $Nas->nas_group_add({ %FORM, DOMAIN_ID => $admin->{DOMAIN_ID} });
    if (!$Nas->{errno}) {
      $html->message('info', $lang{ADDED}, "$lang{ADDED}");
    }
  }
  elsif ($FORM{change}) {
    $Nas->nas_group_change({%FORM});
    if (!$Nas->{errno}) {
      $html->message('info', $lang{CHANGED}, "$lang{CHANGED} [$Nas->{ID}] $Nas->{NAME}");
    }
  }
  elsif ($FORM{chg}) {
    $Nas->nas_group_info({ ID => $FORM{chg} });

    $Nas->{ACTION}     = 'change';
    $Nas->{LNG_ACTION} = $lang{CHANGE};
    $FORM{add_form}    = 1;
  }
  elsif (defined($FORM{del}) && $FORM{COMMENTS}) {
    $Nas->nas_group_del($FORM{del});
    if (!$Nas->{errno}) {
      $html->message('info', $lang{DELETED}, "$lang{DELETED} $FORM{del}");
    }
  }

  _error_show($Nas, { MESSAGE => "$lang{NAS}" });

  $Nas->{DISABLE} = ($Nas->{DISABLE}) ? ' checked' : '';
  $LIST_PARAMS{DOMAIN_ID} = $admin->{DOMAIN_ID} if ($admin->{DOMAIN_ID});

  if ($FORM{add_form}) {
    $html->tpl_show(templates('form_nas_group'), $Nas);
  }

  result_former(
    {
      INPUT_DATA      => $Nas,
      FUNCTION        => 'nas_group_list',
      DEFAULT_FIELDS  => 'COUNTS',
      BASE_FIELDS     => 4,
      FUNCTION_FIELDS => 'form_nas:$lang{NAS}:gid:&search=1,change,del',
      SKIP_USER_TITLE => 1,
      SELECT_VALUE    => {
        disable => {
          0 => "$lang{ENABLE}:$state_colors[0]",
          1 => "$lang{DISABLE}:$state_colors[1]"
        },
      },
      EXT_TITLES => {
        id       => '#',
        name     => $lang{NAME},
        comments => $lang{COMMENTS},
        disable  => $lang{STATUS},
        counts   => $lang{NASS}
      },
      TABLE => {
        width   => '100%',
        caption => "$lang{NAS} $lang{GROUPS}",
        qs      => $pages_qs,
        ID      => 'NAS_GROUPS',
        EXPORT  => 1,
        MENU    => "$lang{ADD}:index=$index&add_form=1&$pages_qs:add",
      },
      MAKE_ROWS     => 1,
      SEARCH_FORMER => 1,
      TOTAL         => 1
    }
  );

  return 1;
}

#**********************************************************
=head2 form_ip_pools() - Manage ip pools

  Arguments:
    $attr

=cut
#**********************************************************
sub form_ip_pools {
  my ($attr) = @_;

  if ($FORM{import}) {
    ip_pools_import();
    return 1;
  }

  if ($FORM{NAS_ID} && !$FORM{subf}) {
    $FORM{subf} = $index;
    $index      = get_function_index('form_nas');
    return form_nas();
  }
  my @bit_masks = ('-----', 32, 31, 30, 29, 28, 27, 26, 25, 24, 23, 22, 21, 20, 19, 18, 17, 16);

  $Nas->{ACTION}     = 'add';
  $Nas->{LNG_ACTION} = $lang{ADD};

  if ($attr->{NAS}) {
    $Nas               = $attr->{NAS};
    $pages_qs          = "&NAS_ID=$Nas->{NAS_ID}";
  }

  if ($FORM{subf}) {
    $pages_qs .= "&subf=$FORM{subf}";
  }

  my $mask = 0b0000000000000000000000000000001;

  my $list_next_pool = $Nas->nas_ip_pools_list({ 
    PAGE_ROWS => 500, 
    POOL_NAME => '_SHOW', 
    COLS_NAME => 1 
  });

  if ($FORM{BIT_MASK}) {
    $FORM{NETMASK} = int2ip(4294967296 - sprintf("%d", $mask << (32 - $bit_masks[ $FORM{BIT_MASK} ])));
  }

  if ($FORM{BIT_MASK} && !$FORM{COUNTS}) {
    $FORM{COUNTS} = sprintf("%d", $mask << ($FORM{BIT_MASK} - 1)) - 2;
    my $netmask = int2ip(4294967296 - sprintf("%d", $mask << ($FORM{BIT_MASK} - 1)));

    my @addrb = split(/\./, $FORM{NAS_IP_SIP} || '0.0.0.0');
    my ($addrval) = unpack("N", pack("C4", @addrb));

    my @maskb = split(/\./, $netmask);
    my ($maskval) = unpack("N", pack("C4", @maskb));

    # calculate network address
    my $netwval = ($addrval & $maskval);

    # convert network address to IP address
    my @netwb = unpack("C4", pack("N", $netwval));
    $netwb[3]++;
    $FORM{NAS_IP_SIP} = join(".", @netwb);
  }

  if ($FORM{add}) {
    if ($FORM{POOL_SPEED} && !$FORM{BIT_MASK}) {
      $html->message('err', $lang{ERROR}, "SELECT_MASK");
    }
    elsif($FORM{NAME} || $FORM{IP}) {
      $Nas->ip_pools_add({ %FORM, GATEWAY => ip2int($FORM{GATEWAY}) });
      if (!$Nas->{errno}) {
        $Nas->divide_ips({
          FIRST   => ip2int($FORM{IP}),
          COUNT   => $FORM{COUNTS},
          POOL_ID => $Nas->{INSERT_ID},
        });

        if ($FORM{IP_SKIP}) {
          my @arr_ip_skip = split(/,\s?|;\s?/, $FORM{IP_SKIP});
          foreach my $element_ip (@arr_ip_skip) {
            $Nas->remove_ippools_ips({
              IPPOOL_ID => $Nas->{INSERT_ID},
              IP        => ip2int($element_ip)
            });
          }
        }

        $FORM{chg} = $Nas->{INSERT_ID} || 0;
        $html->message('info', $lang{INFO}, "$lang{ADDED} [$FORM{chg}]");
      }
    }
  }
  elsif ($FORM{change}) {
    if ($FORM{POOL_SPEED} && !$FORM{BIT_MASK}) {
      $html->message('err', $lang{ERROR}, "Select Mask");
    }
    else {
      $Nas->ip_pools_change(
        {
          %FORM,
          ID             => $FORM{chg},
          NAS_IP_SIP_INT => ip2int($FORM{NAS_IP_SIP}),
          GATEWAY        => ip2int($FORM{GATEWAY}),
        }
      );

      if (!$Nas->{errno}) {
        $Nas->remove_ippools_ips({
          CHG => $FORM{chg}
        });
        $Nas->divide_ips({
          FIRST   => ip2int($FORM{IP}),
          COUNT   => $FORM{COUNTS},
          POOL_ID => $FORM{chg},
        });
        $html->message('info', $lang{INFO}, $lang{CHANGED});

        if ($FORM{IP_SKIP}) {
          my @arr_ip_skip = split(/,\s?|;\s?/, $FORM{IP_SKIP});
          foreach my $element_ip (@arr_ip_skip) {
            $Nas->remove_ippools_ips({
              IPPOOL_ID => $FORM{chg},
              IP        => ip2int($element_ip)
            });
          }
        }
      }
    }
  }
  elsif ($FORM{chg}) {
    $Nas->ip_pools_info($FORM{chg});

    if (!$Nas->{errno}) {
      $html->message('info', $lang{INFO}, "$lang{CHANGING}");
      $Nas->{ACTION}  = 'change';
      $Nas->{GATEWAY} = int2ip($Nas->{GATEWAY});
      my $netmask_binary = sprintf('%032b', $Nas->{NETMASK});
      $Nas->{BIT_MASK}     = index($netmask_binary, '0');
      $Nas->{BIT_MASK_NUM} = 32 - $Nas->{BIT_MASK} + 1;
      $Nas->{LNG_ACTION}   = "$lang{CHANGE}";
      $FORM{add_form}      = 1;
    }
  }
  elsif ($FORM{set}) {
    my @arr_ids = ();
    if ($FORM{ids}) {
      @arr_ids = split(', ', $FORM{ids});
    }

    $FORM{ids} = join(', ', _uniq(@arr_ids));

    $Nas->nas_ip_pools_set(\%FORM);

    if (!$Nas->{errno}) {
      $html->message('info', $lang{INFO}, "$lang{CHANGED}");
    }
  }
  elsif ($FORM{del} && $FORM{COMMENTS}) {
    my $nas_ip_pool = $Nas->nas_ip_pools_list({
      ID                => $FORM{del},
      IP_COUNT          => '_SHOW',
      INTERNET_IP_FREE  => '_SHOW',
      COLS_NAME         => 1
    });
    $nas_ip_pool = $nas_ip_pool->[0];

    my $ip_count = ($nas_ip_pool->{ip_count}) ? $nas_ip_pool->{ip_count} : 0;
    my $ip_free = ($nas_ip_pool->{internet_ip_free}) ? $nas_ip_pool->{internet_ip_free} : 0;

    if ($ip_count == $ip_free){
      $Nas->remove_ippools_ips({
        DEL => $FORM{del}
      });
      $Nas->ip_pools_del($FORM{del});
      if (!$Nas->{errno}) {
        $html->message('info', $lang{INFO}, "$lang{DELETED} ID=$FORM{del}");
      }
    } else {
      my $ip_busy = $ip_count - $ip_free;
      my $internet_users_index = get_function_index('internet_users_list');
      my $internet_quantity_users = $html->button($ip_busy, "index=$internet_users_index&IP_POOL_ID=$FORM{del}",{BUTTON => 2, target => '_blank'});
      $html->message('danger', "$lang{ERROR_DELETE} ID=$FORM{del}", "$lang{NUMBER_OF_USERS}: $internet_quantity_users");
    }
  }

  if ($FORM{add_form}) {
    $Nas->{STATIC} = ' checked' if ($Nas->{STATIC});
    $Nas->{GUEST}  = ' checked' if ($Nas->{GUEST});

    $Nas->{BIT_MASK} = $html->form_select(
      'BIT_MASK',
      {
        SELECTED => $Nas->{BIT_MASK_NUM} || $FORM{BIT_MASK} || 9,    # 24,
        SEL_ARRAY    => \@bit_masks,
        ARRAY_NUM_ID => 1
      }
    );

    $Nas->{NEXT_POOL_ID_SEL} = $html->form_select(
      'NEXT_POOL_ID',
      {
        SELECTED  => $Nas->{NEXT_POOL_ID} || $FORM{NEXT_POLL_ID} || 0,
        SEL_LIST  => $list_next_pool,
        SEL_KEY   => 'id',
        SEL_VALUE => 'pool_name',
        NO_ID     => 1,
        MAIN_MENU => get_function_index('form_ip_pools'),
        MAIN_MENU_ARGV => "chg=" . ($Nas->{NEXT_POOL_ID} || ''),
        SEL_OPTIONS => { '--' => '' }
      }
    );

    $Nas->{IPV6_BIT_MASK} = $html->form_select(
      'IPV6_MASK',
      {
        SELECTED     => $Nas->{IPV6_MASK} || $FORM{IPV6_MASK} || 64,    # 24,
        SEL_ARRAY    => [ 32..128  ],
      }
    );

    $Nas->{IPV6_PD_BIT_MASK} = $html->form_select(
      'IPV6_PD_MASK',
      {
        SELECTED     => $Nas->{IPV6_PD_MASK} || $FORM{IPV6_PD_MASK} || 64,    # 24,
        SEL_ARRAY    => [ 32..128  ],
      }
    );

    if ($Nas->{IP} && ! $FORM{chg}) {
      $Nas->{IP}=join('.', (split(/\./, int2ip($Nas->{IP})))[0..2] ) .'.'.'2';
    }

    $html->tpl_show(templates('form_ip_pools'), {
      %FORM,
      %{$Nas},
      INDEX         => 63
    });
  }

  _error_show($Nas);
  $index = get_function_index('form_ip_pools');
  my AXbills::HTML $pools_table;

  ($pools_table, undef) = result_former({
    INPUT_DATA      => $Nas,
    FUNCTION        => 'nas_ip_pools_list',
    DEFAULT_FIELDS  => 'ID,NAS_NAME,POOL_NAME,FIRST_IP,LAST_IP,IP_COUNT,' . (in_array('Internet', \@MODULES) ? 'INTERNET_IP_FREE,INTERNET_DYNAMIC_IP_FREE,' : 'IP_FREE'),
    HIDDEN_FIELDS   => 'STATIC,ACTIVE_NAS_ID,NAS',
    FUNCTION_FIELDS => 'change, del',
    SKIP_USER_TITLE => 1,
    EXT_TITLES      => {
      id               => '#',
      nas_name         => 'NAS',
      pool_name        => $lang{NAME},
      first_ip         => $lang{BEGIN},
      last_ip          => $lang{END},
      ip_count         => $lang{COUNT},
      internet_ip_free => $lang{FREE},
      internet_dynamic_ip_free => "DYNAMIC $lang{FREE}",
      priority         => $lang{PRIORITY},
      speed            => "$lang{SPEED} (Kbits)",
      ip_skip          => $lang{IP_SKIP},
      netmask          => $lang{MASK},
      ipv6_prefix      => 'IPV6 ' . $lang{PREFIX},
      ipv6_mask        => 'IPV6 ' . $lang{MASK},
      ipv6_temp        => 'IPV6 ' . $lang{TEMPLATE},
      ipv6_pd          => 'IPV6 PD ' . $lang{PREFIX},
      ipv6_pd_mask     => 'IPV6 PD ' . $lang{MASK},
      ipv6_pd_temp     => 'IPV6 PD ' . $lang{TEMPLATE},
      guest            => $lang{GUEST},
      comments         => $lang{COMMENTS},
      static           => $lang{STATIC},
      dns              => 'DNS',
      vlan             => 'Vlan',
      next_pool        => $lang{NEXT_POOL},
      gateway          => $lang{DEFAULT_GATEWAY},
    },
    FILTER_VALUES   => {
      id        => sub {
        my ($id, $line) = @_;

        my $static = ($line->{static}) ? $html->badge('static',
          { TYPE => 'badge-secondary align-text-top' }) : '';

        my $select_checkbox = $html->form_input(
          'ids',
          $line->{id},
          {
            class   => 'checked_ippool_' . $line->{id},
            TYPE    => 'checkbox',
            FORM_ID => 'IP_POOLS_CHECKBOXES_FORM',
            STATE   => ($line->{active_nas_id}) ? 'checked' : undef
          }
        );

        my $checked_id = $id . '&nbsp;' . $select_checkbox . '&nbsp;' . $static;
        ($html && $html->{TYPE} && $html->{TYPE} eq 'html') ? $checked_id : $id;
      },
      pool_name => sub {
        my ($name, $line) = @_;

        my $internet_users_index = get_function_index('internet_users_list');
        my $users_button = $html->button($name,
          "index=$internet_users_index&IP_POOL=$line->{id}&search=1&search_form=1");

        return $line->{static} ? $users_button : $name;
      },
      nas_name  => sub {
        my ($name, $line) = @_;
        ($line->{nas_id} && $line->{active_nas_id})
          ? $html->button($name, "index=62&NAS_ID=$line->{active_nas_id}")
          : '';
      },
      netmask   => sub {
        my ($netmask) = @_;
        return int2ip($netmask);
      },
      guest     => sub {
        my ($guest) = @_;
        if ($guest) {
          return $html->element('label', '', { class => 'fa fa-check' });
        }
        else {
          return $html->element('label', '', { class => 'fa fa-times' });
        }
      },
      static    => sub {
        my ($static) = @_;
        if ($static) {
          return $html->element('label', '', { class => 'fa fa-check' });
        }
        else {
          return $html->element('label', '', { class => 'fa fa-times' });
        }
      },
      next_pool => sub {
        my ($next_pool) = @_;

        foreach my $pool_value (@$list_next_pool) {
          return $pool_value->{pool_name} if ($next_pool && $pool_value->{id} && $pool_value->{id} == $next_pool);
        }
      },
      gateway   => sub {
        my ($gateway) = @_;
        return int2ip($gateway);
      }
    },
    TABLE           => {
      width          => '100%',
      caption        => "NAS IP POOLs",
      SHOW_FULL_LIST => 1,
      qs             => $pages_qs,
      ID             => 'NAS_IP_POOLS',
      header         => '',
      EXPORT         => 1,
      IMPORT         => "$SELF_URL?get_index=form_ip_pools&import=1&header=2",
      MENU           => "$lang{ADD}:index=$index&add_form=1&$pages_qs:add",
    },
    MAKE_ROWS       => 1,
    SEARCH_FORMER   => 1,
    TOTAL           => 1,
    OUTPUT2RETURN   => 1
  });

  $html->tpl_show(templates('form_ippools_nas'), { TABLE_IPPOOLS => $pools_table });

  print $html->form_main(
    {
      ID     => 'IP_POOLS_CHECKBOXES_FORM',
      HIDDEN => {
        index  => get_function_index('form_ip_pools'),
        NAS_ID => $FORM{NAS_ID} || '',
      },
      SUBMIT => { ($FORM{NAS_ID}) ? (set => $lang{SET}) : () }
    }
  );

  return 1;
}

#**********************************************************
=head2 form_nas_stats($attr)

=cut
#**********************************************************
sub form_nas_stats {
  my ($attr) = @_;

  if ($attr->{NAS}) {
    $Nas = $attr->{NAS};
  }
  elsif ($FORM{NAS_ID}) {
    $FORM{subf} = $index;
    form_nas();
    return 0;
  }

  my $Sessions;
  if(in_array('Internet', \@MODULES)) {
    require Internet::Sessions;
    Internet::Sessions->import();
    $Sessions = Internet::Sessions->new($db, $admin, \%conf);
  }

  require Log;
  Log->import();

  my $Log = Log->new($db, \%conf);

  my $last_session = $Log->log_list({
    COLS_NAME => 1,
    NAS_ID    => $FORM{NAS_ID},
    SORT      => 1,
    LOG_TYPE  => 6,
    DESC      => 'desc',
    PAGE_ROWS => 1
  });

  my $first_session = $Log->log_list(
    {
      COLS_NAME => 1,
      NAS_ID    => $FORM{NAS_ID},
      SORT      => 1,
      LOG_TYPE  => 6,
      PAGE_ROWS => 1
    }
  );

  my $false_connect = $Log->log_list(
    {
      COLS_NAME => 1,
      NAS_ID    => $FORM{NAS_ID},
      DATE      => $FORM{DATE} || $DATE,
      LOG_TYPE  => 4
    }
  );

  my $success_connect = $Log->log_list(
    {
      COLS_NAME => 1,
      NAS_ID    => $FORM{NAS_ID},
      DATE      => $FORM{DATE} || $DATE,
      LOG_TYPE  => 6
    }
  );

  my $users_online = $Sessions->online({ COLS_NAME => 1, NAS_ID => $FORM{NAS_ID} });

  my @users_succ_connect = [];
  my $success_conects    = 0;

  if ($Log->{TOTAL}) {
    foreach my $user (@{$success_connect}) {
      if (!(in_array($user->{user}, \@users_succ_connect))) {
        $success_conects++;
        push(@users_succ_connect, $user->{user});
      }
    }
  }

  $html->tpl_show(
    templates('form_nas_stats'),
    {
      USERS_ONLINE           => $#{$users_online} + 1,
      DATE                   => $FORM{DATE} || $DATE,
      LAST_CONNECT           => $last_session->[0]->{date} || 0,
      FIRST_CONNECT          => $first_session->[0]->{date} || 0,
      SUC_CONNECTS_PER_DAY   => $success_conects || 0,
      SUC_ATTEMPTS_PER_DAY   => $#{$success_connect} + 1 || 0,
      FALSE_ATTEMPTS_PER_DAY => $#{$false_connect} + 1 || 0,
      FUNC_INDEX             => get_function_index('internet_error'),
      LOG_WARN               => 4,
      LOG_INFO               => 6,
    }
  );

  my $table = $html->table({
    width      => '100%',
    caption    => $lang{STATS},
    title      => [ "NAS", $lang{PORT}, $lang{SESSIONS}, $lang{LAST_LOGIN}, $lang{AVG}, $lang{MIN}, $lang{MAX} ],
    ID         => 'NAS_STATS',
  });

  my $list = $Nas->stats({%LIST_PARAMS, INTERNET => in_array('Internet', \@MODULES)});

  if($Nas->{TOTAL} && $Nas->{TOTAL} > 0) {
    foreach my $line (@{$list}) {
      $table->addrow($html->button($line->[0], "index=62&NAS_ID=$line->[7]"), $line->[1], $line->[2],
        $line->[3], $line->[4], $line->[5], $line->[6]);
    }

    print $table->show();
  }

  return 1;
}

# Duplicates from Radius_pairs?
sub build_radius_params_result_response {
  my ($module) = @_;

  my $errno = $module->{errno} || 0;
  my $err_str = $module->{err_str} || '';

  return qq[
    {
      "status": $errno,
      "message": "$err_str"
    }
  ];
}

# Duplicates from Radius_pairs?
sub parse_radius_params_json {
  my ($pairs_json) = @_;

  $pairs_json =~ s/\\//g;
  $pairs_json =~ s/’/'/g;

  my $json = JSON->new()->utf8(0);

  my $radius_pairs = $json->decode($pairs_json);
  my $radius_pairs_string = build_radius_params_string($radius_pairs);

  return $radius_pairs_string;
}

#**********************************************************
=head2 sel_nas_groups($attr)

  Arguments:
    GID

=cut
#**********************************************************
sub sel_nas_groups {
  my ($attr) = @_;

  my $gid = $attr->{GID} || $FORM{GID} || '';

  my $GROUPS_SEL = $html->form_select(
    'GID',
    {
      SELECTED => $gid,
      SEL_LIST => $Nas->nas_group_list({ DOMAIN_ID => $admin->{DOMAIN_ID}, COLS_NAME => 1 }),
      SEL_OPTIONS    => { '' => '' },
      MAIN_MENU      => get_function_index('form_nas_groups'),
      MAIN_MENU_ARGV => "chg=$gid"
    }
  );

  return $GROUPS_SEL;
}

#**********************************************************
=head2 nas_types_list()

  List build in nas servers

  Extra server adding using $conf{nas_servers}

=cut
#**********************************************************
sub nas_types_list {

  my %nas_descr = (
    '3com_ss'       => '3COM SuperStack Switch',
    'nortel_bs'     => 'Nortel Baystack Switch',
    'asterisk'      => 'Asterisk',
    'usr'           => 'USR Netserver 8/16',
    'pm25'          => 'LIVINGSTON portmaster 25',
    'ppp'           => 'FreeBSD ppp demon',
    'exppp'         => 'FreeBSD ppp demon with extended futures',
    'dslmax'        => 'ASCEND DSLMax',
    'celan'         => 'CeLAN Switch',
    'expppd'        => 'pppd deamon with extended futures',
    'edge_core'     => 'EdgeCore Switch',
    'eltex_smg'     => 'Eltex SMG',
    'radpppd'       => 'pppd version 2.3 patch level 5.radius.cbcp',
    'lucent_max'    => 'Lucent MAX',
    'hp'            => 'HP Switch',
    'mac_auth'      => 'MAC auth',
    'mpd5'          => 'MPD 5.xx',
    'ipcad'         => 'IP accounting daemon with Cisco-like ip accounting export',
    'lepppd'        => 'Linux PPPD IPv4 zone counters',
    'pppd'          => 'pppd + RADIUS plugin (Linux)',
    'pppd_coa'      => 'pppd + RADIUS plugin + radcoad (Linux)',
    'accel_ppp'     => 'Linux accel-ppp',
    'accel_ipoe'    => 'Linux accel-ipoe',
    'gnugk'         => 'GNU GateKeeper',
    'cid_auth'      => 'Auth clients by CID',
    'cisco'         => 'Cisco',
    'cisco_voip'    => 'Cisco Voip',
    'cisco_isg'     => 'Cisco ISG',
    'cisco_air'     => 'Cisco Aironets',
    'gpon'          => 'Huawei MA56**',
    'epon'          => 'BDCOM p3100',
    'dell'          => 'Dell Switch',
    'patton'        => 'Patton RAS 29xx',
    'bsr1000'       => 'CMTS Motorola BSR 1000',
    'mikrotik'      => 'Mikrotik (http://www.mikrotik.com)',
    'mikrotik_dhcp' => 'Mikrotik DHCP service',
    'dlink_pb'      => 'Dlink IP-MAC-Port Binding',
    'other'         => 'Other nas server',
    'chillispot'    => 'Chillispot (www.chillispot.org)',
    'openvpn'       => 'OpenVPN with RadiusPlugin',
    'vlan'          => 'Vlan managment',
    'qbridge'       => 'Q-BRIDGE',
    'dhcp'          => 'DHCP FreeRadius in DHCP mode',
    'ls_pap2t'      => 'Linksys pap2t',
    'ls_spa8000'    => 'Linksys spa8000',
    'redback'       => 'Ericsson Smart Edge SE100 (Redback)',
    'mx80'          => 'Juniper MX80',
    'ipv6'          => 'ipv6',
    'unifi'         => 'Ubiquiti Unifi controler',
    'eltex'         => 'Eltex',
    'kamailio'      => 'kamailio SIP server',
    'ipn'           => 'IPoE static nas',
    'zte_m6000'     => 'ZTE M6000',
    'huawei_me60'   => 'Huawei ME60 router',
    'wifipoint'     => 'Wifi Access point',
    'strongswan'    => 'strongSwan',
    'squid'         => 'SQUID proxy server'
  );

  if ($conf{nas_servers}) {
    %nas_descr = (%nas_descr, %{ $conf{nas_servers} });
  }

  return \%nas_descr;
}

#**********************************************************
=head2 form_nas_search($attr)

  Arguments:
    $attr

  Results:


=cut
#**********************************************************
sub form_nas_search {
  my ($attr) = @_;

  my $sub_template   = '';
  my $results        = 'No results yet';
  my $has_result_now = 0;

  if (defined $FORM{NAS_SEARCH} && $FORM{NAS_SEARCH} == 0) {
    if ($FORM{UID}) {
      require Users;
      Users->import();
      my $users = Users->new($db, $admin, \%conf);
      # Check for location_id on this user
      my $list = $users->list(
        {
          UID            => $FORM{UID},
          LOCATION_ID    => '_SHOW',
          ADDRESS_STREET => '_SHOW',
          ADDRESS_BUILD  => '_SHOW',
          COLS_NAME      => 1
        }
      );

      if ($users->{TOTAL} && $list->[0]->{build_id}) {
        my $table_caption = ' ' . ($list->[0]->{address_street} || q{}) . ', ' . $list->[0]->{address_build};
        my $nases_list = $Nas->list(
          {
            %FORM,
            LOCATION_ID => $list->[0]->{build_id},
            COLS_NAME   => 1
          }
        );

        my $nases_table = form_nas_search_nas_table($nases_list, $table_caption);

        $has_result_now = defined $nases_table && $nases_table ne '';

        $results = $nases_table if ($has_result_now);
      }
    }
  }
  elsif (defined $FORM{NAS_SEARCH} && $FORM{NAS_SEARCH} == 1) {
    if($FORM{ADDRESS_FULL}) {
      $FORM{ADDRESS_FULL} = "*$FORM{ADDRESS_FULL}*";
    }

    my $nases_list = $Nas->list(
      {
        %FORM,
        DOMAIN_ID => ($admin->{DOMAIN_ID}) ? $admin->{DOMAIN_ID} : undef,
        PAGE_ROWS => 100000,
        COLS_NAME => 1
      }
    );

    print form_nas_search_nas_table($nases_list, '');
    return 1;
  }

  # Assembly search form
  $Nas->{SEL_TYPE} = $html->form_select(
    'NAS_TYPE',
    {
      SELECTED    => $Nas->{NAS_TYPE},
      SEL_HASH    => nas_types_list(),
      SEL_OPTIONS => { '' => $lang{ALL} },
      SORT_KEY    => 1
    }
  );
  $Nas->{NAS_GROUPS_SEL} = sel_nas_groups({ GID => $Nas->{GID} });

  $sub_template = $html->tpl_show(
    templates('form_search_nas'),
    {
      %{$Nas},
      POPUP => ($attr->{STANDART}) ? '' : 1,
      SEARCH_BTN => ($attr->{STANDART}) ? $html->form_input('search', $lang{SEARCH}, { TYPE => 'submit' }) : '',
    },
    { OUTPUT2RETURN => 1 }
  );

  if ($attr->{STANDART}) {
    print $sub_template;
    return $sub_template;
  }
  else {
    return $html->tpl_show(
      templates('form_popup_window'),
      {
        SUB_TEMPLATE     => $sub_template,
        RESULTS          => $results,
        OPEN_RESULT      => $has_result_now,
        CALLBACK_FN_NAME => ''
      }
    );
  }
}

#**********************************************************
=head2 form_nas_search_nas_table($nases_list, $table_caption)

=cut
#**********************************************************
sub form_nas_search_nas_table {
  my ($nases_list, $table_caption) = @_;

  return '' if (!($nases_list && scalar @{$nases_list}));

  my $table = $html->table(
    {
      width       => '100%',
      caption     => $lang{NAS} . ' : ' . ($table_caption // ''),
      title_plain => [ 'ID', $lang{NAME}, 'IP', $lang{TYPE}, 'mac' ],
      pages       => scalar @{$nases_list},
      ID          => 'NAS_SEARCH'
    }
  );

  foreach my $line (@{$nases_list}) {
    $table->addrow(
      $line->{nas_id},
      $html->element(
        'div',
        $line->{nas_name},
        {
          class        => 'clickSearchResult',
          'data-value' => "NAS_ID::$line->{nas_id}" . "#@#NAS_ID1::". ($line->{nas_name}||q{}) . "#@#NAS_IP::$line->{nas_ip}"
        }
      ),
      $line->{nas_ip},
      $line->{nas_type},
      $line->{mac},
      $line->{address_full}
    );
  }

  return $table->show();
}

#**********************************************************
=head2 form_ssh_key($nas_info) - Manage ssh key for control

  Arguments:
    $nas_info - NAS object

=cut
#**********************************************************
sub form_ssh_key {
  my ($nas_info) = @_;

  if (!$nas_info->{NAS_MNG_USER}) {
    print $html->header();
    $html->message('warn', "", "SELECT_USER");
    exit;
  }
  elsif ($nas_info->{NAS_MNG_USER} !~ /^[a-z0-9\_\.\-]+$/) {
    print $html->header();
    $html->message('warn', "", "WRONG_NAME");
    exit;
  }

  my $filename    = 'id_rsa.' . $nas_info->{NAS_MNG_USER} . '.pub';
  my $size        = 0;
  my $content     = q{};
  my $axbills_path = '/usr/axbills/';

  if ($FORM{create}) {
    print $html->header();
    my $result = cmd("$axbills_path/misc/certs_create.sh -silent ssh '$nas_info->{NAS_MNG_USER}'");
    $html->message('info', $lang{INFO}, "$lang{CREATE} SSH Certificate ($result)");

    exit;
  }
  elsif ($FORM{download}) {
    $content = file_op(
      {
        FILENAME => $filename,
        PATH     => $axbills_path . '/Certs/',
        QUIET    => 1
      }
    );

    if ($content eq '-1') {
      print $html->header();
      print "FILE_NOT_FOUND '$filename'";
    }
    else {
      print "Content-Type: application/octet-stream;  filename=\"$filename\"\n" . "Content-Disposition: attachment;  filename=\"$filename\";  size=$size" . "\n\n";

      print $content;
    }

    exit;
  }

  return 1;
}

#**********************************************************
=head2 nas_radius_pairs_save($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub nas_radius_pairs_save {
  #my ($attr) = @_;

  return 1 if !$FORM{ID};

  $Nas->change({
    %{$Nas->info({
      NAS_ID        => $FORM{ID}
    })},
    NAS_ID        => $FORM{ID},
    NAS_RAD_PAIRS => AXbills::Radius_Pairs::parse_radius_params_json($FORM{RADIUS_PAIRS})
  });

  print AXbills::Radius_Pairs::build_radius_params_result_response($Nas);

  return 1;
}


#**********************************************************
=head2 ip_pools_import($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub ip_pools_import {

  if ($FORM{add}) {
    my $import_info = import_former( \%FORM );
    my $total = $#{ $import_info } + 1;

    my $ip_list = $Nas->ip_pools_list({ COLS_NAME => 1 });

    my %ippools_hash = map { $_->{ip} => $_->{id} } @{$ip_list};

    if ($import_info) {
      import_ip($import_info, %ippools_hash);
    }

    $html->message( 'info', $lang{INFO},
      "$lang{ADDED}\n $lang{FILE}: $FORM{UPLOAD_FILE}{filename}\n Size: $FORM{UPLOAD_FILE}{Size}\n Count: $total" );

    return 1;
  }

  $html->tpl_show(templates('form_import'), {
    IMPORT_FIELDS     => 'IP',
    CALLBACK_FUNC     => 'form_ip_pools',
  });

  return 1;

}

#**********************************************************
=head2 import_ip($attr)

  Arguments:
    import_info   - import ip pools
    ippools_hash  - ip pools in system

  Return:
    -

=cut
#**********************************************************
sub import_ip {
  my ($import_info, %ippools_hash) = @_;

  foreach my $ip_import (@$import_info) {
    if ($ip_import) {
      add_ip_import($ip_import, %ippools_hash);
    }
  }

}

#**********************************************************
=head2 add_ip_import($attr)

  Arguments:
    ip_tmp  - ip push in system
    ip_hash - hash ip pools in system

  Return:
    -

=cut
#**********************************************************
sub add_ip_import {
  my ($ip_tmp, %ip_hash) = @_;
  my @bit_masks = (32, 31, 30, 29, 28, 27, 26, 25, 24,
                   23, 22, 21, 20, 19, 18, 17, 16);

  my @ip_and_mask;

  if (ref($ip_tmp) eq 'HASH' && $ip_tmp->{IP}) {

    $ip_tmp->{IP} =~ s/,//g;
    if ($ip_tmp->{IP} =~ /\//) {
      @ip_and_mask = split(/\//, $ip_tmp->{IP});
    }
    else {
      push @ip_and_mask, $ip_tmp->{IP};
    }
  }
  else {
    if ($ip_tmp =~ /\//) {
      @ip_and_mask = split(/\//, $ip_tmp);
    }
    else {
      push @ip_and_mask, $ip_tmp;
    }
  }

  unless ($ip_hash{ $ip_and_mask[0] }) {

    my %mask_hash = map{ $_ => $_ } @bit_masks;

    my $mask = 0b0000000000000000000000000000001;
    my $mask_network = int2ip(4294967296 - sprintf("%d", $mask << (32 - $mask_hash{ $ip_and_mask[1] || 24 } ) ) );
    my $count_ip = sprintf("%d", $mask << (32 - $ip_and_mask[1])) - 2;

    $Nas->ip_pools_add({
      IP        => $ip_and_mask[0],
      NETMASK   => $mask_network,
      COUNTS    => $count_ip,
      NAME      => "Ippools: " . $ip_and_mask[0]
    });
  }

}

#**********************************************************
=head2 _uniq() -

  Arguments:
    -
  Return:
    -

=cut
#**********************************************************
sub _uniq {
    my %seen;
    grep !$seen{$_}++, @_;
}

#**********************************************************
=head2 _get_online($attr) -

  Arguments:
    $attr
      NAS_ID
      KEY_FIELD

  Return:
    \%users_online

=cut
#**********************************************************
sub _get_online {
  my ($attr) = @_;

  if (! in_array('Internet', \@MODULES) ) {
    return {};
  }

  require Internet::Sessions;
  Internet::Sessions->import();
  my Internet::Sessions $Sessions = Internet::Sessions->new($db, $admin, \%conf);

  $Sessions->{debug}=1 if ($FORM{DEBUG});
  my $users_online_list = $Sessions->online({
    COLS_NAME       => 1,
    NAS_ID          => $attr->{NAS_ID},
    CLIENT_IP       => '_SHOW',
    LOGIN           => '_SHOW',
    #NAS_ID          => '_SHOW',
    NAS_PORT_ID     => '_SHOW',
    ACCT_SESSION_ID => '_SHOW',
    USER_NAME       => '_SHOW',
  });

  _error_show($Sessions);

  require AXbills::Experimental;
  my $key_field = $attr->{KEY_FIELD} || 'client_ip';
  my $users_online = sort_array_to_hash($users_online_list, $key_field);

  return $users_online;
}

1;
