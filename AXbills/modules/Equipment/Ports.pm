=head1 NAME

  Ports information and managment

=cut
use strict;
use warnings FATAL => 'all';
use AXbills::Base qw(int2byte in_array int2ip _bp);

our(
  %lang,
  $admin,
  $base_dir,
  $db,
  %conf,
  %permissions,
  @port_types,
  @skip_ports_types,
  %FORM,
  @MODULES,
  %LIST_PARAMS,
  $index,
  @_COLORS
);

our AXbills::HTML $html;

#my @service_status_colors = ($_COLORS[9], "840000", '#808080', '#0000FF', $_COLORS[6], '#009999');
my @service_status = ($lang{ENABLE}, $lang{DISABLE}, $lang{NOT_ACTIVE}, $lang{ERROR}, $lang{BREAKING}, $lang{NOT_MONITORING});

my @ports_state = ('', "Up", "Down", 'Damage', 'Corp vlan', 'Dormant', 'Not Present', 'lowerLayerDown');
#my @admin_ports_state = ('', 'Enabled', 'Disabled', 'Testing');
my @admin_ports_state = ('', 'Up', 'Down', 'Testing');
my @ports_state_color = ('', '#008000', '#FF0000');

require Equipment::Pon_mng;
require Equipment::Defs;
use Nas;

our Equipment $Equipment;
my $used_ports;

#********************************************************
=head2 equipment_ports_full($attr)

  Arguments:
    $attr
      SNMP_COMMUNITY
      NAS_INFO

  Results:

=cut
#********************************************************
sub equipment_ports_full {
  my ($attr) = @_;

  my $SNMP_COMMUNITY = $attr->{SNMP_COMMUNITY};
  my $nas_id         = $FORM{NAS_ID};
  my $Equipment_     = $attr->{NAS_INFO};

  if ($FORM{mac_info}) {
    my $result = get_oui_info($FORM{mac_info});
    $html->message('info', $lang{INFO}, "MAC: $FORM{mac_info}\n $result");
  }

  if ( $Equipment_->{TYPE_ID} && $Equipment_->{TYPE_ID} == 4 ){
    my @header_arr = (
      "$lang{MAIN}:index=$index&visual=2&NAS_ID=$nas_id",
      "PON:index=$index&visual=2&NAS_ID=$nas_id&TYPE=PON",
    );

    print $html->table_header( \@header_arr, { TABS => 1 } );
    if($FORM{TYPE} && $FORM{TYPE} eq 'PON') {
      equipment_pon_ports($attr);
      return 1;
    }
  }

  #Check snmp template
  my %tpl_fields = ();

  if ( defined( $Equipment_->{STATUS} ) && $Equipment_->{STATUS} != 1 ) { #XXX check certain equipment statuses
    my $perl_scalar = _get_snmp_oid( $Equipment_->{SNMP_TPL} );
    if ( $perl_scalar && $perl_scalar->{ports} ){
      foreach my $key ( keys %{ $perl_scalar->{ports} } ){
        next if (ref $key eq 'HASH');
        next if ($perl_scalar->{ports}->{$key}->{REQUIRES_CABLE_TEST});

        if ($perl_scalar->{ports}->{$key}->{PARSER} ne 'hidden') {
          $tpl_fields{$key} = $key;
        }
      }
    }
  }

  $tpl_fields{PORT_DESCR}   = "Description";
  $tpl_fields{NATIVE_VLAN}  = "Native VLAN dynamic";
  $tpl_fields{CABLE_TESTER} = $lang{CABLE_TESTER};

### АСР AXbills

#   my $default_fields = 'PORT_NAME,PORT_STATUS,ADMIN_PORT_STATUS,UPLINK,LOGIN,MAC,VLAN,PORT_ALIAS,TRAFFIC,PORT_IN_ERR';
  my $default_fields = 'PORT_NAME,PORT_STATUS,PORT_SPEED,ADMIN_PORT_STATUS,UPLINK,LOGIN,MAC,VLAN,PORT_ALIAS,TRAFFIC,PORT_IN_ERR';
#
  my ($table) = result_former({
    DEFAULT_FIELDS => $default_fields,
    BASE_PREFIX  => 'ID',
    TABLE        => {
      width            => '100%',
      caption          => $lang{PORTS},
      qs               => "&visual=$FORM{visual}&NAS_ID=$nas_id",
      SHOW_COLS        => {
        %tpl_fields,
        #ID           => 'ID',
        PORT_NAME         => "$lang{PORT} $lang{NAME}",
        PORT_STATUS       => $lang{PORT_STATUS},
        PORT_TYPE         => $lang{PORT_TYPE},
        ADMIN_PORT_STATUS => "Admin $lang{STATUS}",
        UPLINK            => "UPLINK",
        FIO               => $lang{FIO},
        LOGIN             => $lang{LOGIN},
        MAC               => "MAC",
        MAC_DYNAMIC       => "MAC dynamic",
        IP                => "IP",
        VLAN              => "Native VLAN static",
        ADDRESS_FULL      => $lang{ADDRESS},
        DEPOSIT           => $lang{DEPOSIT},
        TP_NAME           => $lang{TARIF_PLAN},
        PORT_ALIAS        => $lang{COMMENTS},
        TRAFFIC           => $lang{TRAFFIC},
        PORT_SPEED        => $lang{SPEED},
        PORT_COMMENTS     => $lang{COMMENTS},
        PORT_IN_ERR       => "$lang{PACKETS_WITH_ERRORS} (in/out)",
        PORT_IN_DISCARDS  => "Discarded $lang{PACKETS_} (in/out)",
        PORT_UPTIME       => $lang{PORT_UPTIME},
        DATETIME          => $lang{CHANGED}
      },
      SHOW_COLS_HIDDEN => {
        visual => $FORM{visual},
        NAS_ID => $nas_id,
      },
      ID       => 'EQUIPMENT_PORTS',
      EXPORT   => 1,
      MENU    => "$lang{ADD} $lang{PORTS}:index=$index&visual=$FORM{visual}&NAS_ID=$FORM{NAS_ID}&MK_PORTS=1" . ':add'
    },
  });

  my @cols = ();
  if ( $table->{COL_NAMES_ARR} ){
    @cols = @{ $table->{COL_NAMES_ARR} };
  }

  my $cols_list = join( ',', @cols );

  my $ports_snmp_info;
  $cols_list .= ',PORT_TYPE';
  if ($Equipment_->{AUTO_PORT_SHIFT}) {
    $cols_list .= ',PORT_INDEX';
  }

  if (in_array('PORT_IN_ERR', \@cols)) {
    $cols_list .= ',PORT_OUT_ERR';
  }

  if (in_array('PORT_IN_DISCARDS', \@cols)) {
    $cols_list .= ',PORT_OUT_DISCARDS';
  }

  #Get snmp info
  if ( ! $Equipment_->{STATUS} ) { #XXX check certain equipment statuses, not only Active
    my $run_cable_test = in_array('CABLE_TESTER', \@cols);
    $ports_snmp_info = equipment_test({
        VERSION         => $Equipment_->{SNMP_VERSION},
        SNMP_COMMUNITY  => $SNMP_COMMUNITY,
        PORT_INFO       => $cols_list,
        SNMP_TPL        => $Equipment_->{SNMP_TPL},
        RUN_CABLE_TEST  => $run_cable_test,
        AUTO_PORT_SHIFT => $Equipment_->{AUTO_PORT_SHIFT},
        %{$attr}
    });
  }
  else {
    $html->message( 'warn', $lang{INFO}, "$lang{STATUS} $service_status[$Equipment_->{STATUS}]" );
  }

  if(! $ports_snmp_info || ! scalar %$ports_snmp_info) {
    $html->message( 'warn', 'Offline mode');
  }

  my $port_shift = 0;
  if($Equipment_->{PORT_SHIFT}) {
    $port_shift = $Equipment_->{PORT_SHIFT};
  }

  foreach my $key (keys %{$ports_snmp_info}){
    if ($#skip_ports_types > -1 && in_array($ports_snmp_info->{$key}{PORT_TYPE}, \@skip_ports_types) || ! $ports_snmp_info->{$key}{PORT_TYPE}){
      delete $ports_snmp_info->{$key};
    }
  }

  my @ports_arr = keys %{ $ports_snmp_info };

  $used_ports = equipments_get_used_ports({
    NAS_ID     => $nas_id,
    PORTS_ONLY => 1,
    FULL_LIST  => 1
  });

  my $ports_db_info = $Equipment->port_list({
    NAS_ID     => $nas_id,
    TP_NAME    => '_SHOW',
    %LIST_PARAMS,
    SORT       => 1,
    PAGE_ROWS  => 100,
    COLS_UPPER => 1,
    COLS_NAME  => 1
  });

  _error_show( $Equipment );

  my $ports_info = {%$ports_snmp_info};
  foreach my $line ( @{$ports_db_info} ){
    my $port = $line->{port} || 0;
    $ports_info->{ $port } = { %{ ($ports_snmp_info->{ $port }) ? $ports_snmp_info->{ $port } : {} }, %{$line} };
    push @ports_arr, $port if (! in_array($port, \@ports_arr));
  }

  my @all_rows = ();
  my @row_colors = ();

  my %port_num_to_index = ();
  if ($Equipment_->{FDB_USES_PORT_NUMBER_INDEX} && $Equipment_->{AUTO_PORT_SHIFT}) {
    %port_num_to_index = map { $ports_info->{$_}->{PORT_INDEX} => $_ } grep { defined $ports_info->{$_}->{PORT_INDEX} } (keys %$ports_info);
  }

  my %users_mac = ();

  my $users_mac = $Equipment->mac_log_list({
    NAS_ID       => $nas_id,
    PORT         => '_SHOW',
    MAC          => '_SHOW',
    DATETIME     => '_SHOW',
    VLAN         => '_SHOW',
    ONLY_CURRENT => 1,
    PAGE_ROWS    => 1000000,
    COLS_NAME    => 1
  });

  foreach my $line (@$users_mac) {
    my $port = $line->{port};
    if ($Equipment_->{FDB_USES_PORT_NUMBER_INDEX}) {
      if ($Equipment_->{AUTO_PORT_SHIFT}) {
        $port = $port_num_to_index{ $port } || next;
      }
      else {
        $port += $Equipment_->{PORT_SHIFT} || 0;
      }
    }
    push @{$users_mac{$port}}, $line;
  }

  my %macs_dynamic;
  if (in_array('MAC_DYNAMIC', \@cols)) {
    my $fdb = get_fdb($attr);

    foreach my $key (keys %$fdb) {
      my $port = $fdb->{$key}->{2};

      if ($Equipment_->{FDB_USES_PORT_NUMBER_INDEX}) {
        if ($Equipment_->{AUTO_PORT_SHIFT}) {
          $port = $port_num_to_index{ $port } || next;
        }
        else {
          $port += $Equipment_->{PORT_SHIFT} || 0;
        }
      }

      push @{$macs_dynamic{$port}}, $fdb->{$key};
    }
  }

  foreach my $port ( @ports_arr ){
    my @row = ($port);

    my $snmp_port;
    if ($Equipment_->{AUTO_PORT_SHIFT}) {
      if ($ports_info->{$port}->{PORT_INDEX}) {
        $snmp_port = $ports_info->{$port}->{PORT_INDEX};
      }
    }
    else {
      $snmp_port = $port - $port_shift;
    }

    for ( my $i = 1; $i <= $#cols; $i++ ){
      my $col_id = $cols[$i];

      if ( $col_id eq 'ADMIN_PORT_STATUS' ){
        my $admin_port_status = ($ports_info->{$port}->{ADMIN_PORT_STATUS} && in_array($ports_info->{$port}->{ADMIN_PORT_STATUS}, [1, 2]))
                                  ? $ports_info->{$port}->{ADMIN_PORT_STATUS}
                                  : $ports_snmp_info->{$port}->{ADMIN_PORT_STATUS};
        push @row, (defined( $admin_port_status ))  ? $html->color_mark(
              $admin_ports_state[ $admin_port_status ],
              $ports_state_color[ $admin_port_status ] ) : '--';
      }
      elsif ( $col_id eq 'TRAFFIC' ){
        push @row,
          "in: " . int2byte( $ports_info->{$port}{PORT_IN} ) . $html->br() . "out: " . int2byte( $ports_info->{$port}{PORT_OUT} );
      }
      elsif ( $col_id eq 'IP' || $col_id eq 'LOGIN' || $col_id eq 'ADDRESS_FULL' || $col_id eq 'FIO' ||  $col_id eq 'TP_NAME'){
        my $value = '';
        if ($snmp_port && $used_ports->{$snmp_port}) {
          if ($col_id eq 'LOGIN') {
            $value .= show_used_info( $used_ports->{ $snmp_port } );
          }
          else {
            foreach my $uinfo (@{ $used_ports->{$snmp_port} }) {
              $value .= $html->br() if ($value);

              if ($col_id eq 'IP') {
                $value .= int2ip($uinfo->{ip_num}) || "";
              }
              elsif ($col_id eq 'ADDRESS_FULL') {
                $value .= $uinfo->{address_full} || "";
              }
              elsif ($col_id eq 'FIO') {
                $value .= $uinfo->{fio} || "";
              }
              elsif ($col_id eq 'TP_NAME') {
                $value .= $uinfo->{tp_id} || "";
                $value .= ':';
                $value .= $uinfo->{tp_name} || "";
              }
            }
          }
        }
        push @row, $value;
      }
      elsif ( $col_id eq 'MAC' ) {
        my $value = q{};
        if ($users_mac{$port}) {
          $value = join ($html->br(),
            map {
              $html->element('code',
                $_->{mac},
                {
                  'data-tooltip-position' => 'top',
                  'data-tooltip' => $html->b("$lang{LAST_ACTIVITY}:") . $html->br() . $_->{datetime} . $html->br() .
                                    $html->b('VLAN:') . $html->br() . $_->{vlan}
                }
              ) .
              $html->button($lang{VENDOR},
                "index=$index&visual=2&NAS_ID=$FORM{NAS_ID}&mac_info=$_->{mac}",
                { class => 'info', ONLY_IN_HTML => 1 }
              )
            } sort {$a->{mac} cmp $b->{mac}} @{$users_mac{$port}}
          );
        }
        push @row, $value;
      }
      elsif ( $col_id eq 'MAC_DYNAMIC' ) {
        my $value = q{};
        if ($macs_dynamic{$port}) {
          $value = join($html->br(),
            map {
              $html->element('code',
                ($_->{1} || q{-}), # 1 - mac
                {
                  'data-tooltip-position' => 'top',
                  'data-tooltip'          => $html->b('VLAN:') . $html->br() . ($_->{4} || q{-}) # 4 - vlan
                }
              ) .
                $html->button($lang{VENDOR},
                  "index=$index&visual=2&NAS_ID=$FORM{NAS_ID}&mac_info=" . ($_->{1} || q{-}), # 1 - mac
                  { class => 'info', ONLY_IN_HTML => 1 }
                )
            } sort {$a->{1} cmp $b->{1}} @{$macs_dynamic{$port}} # 1 - mac
          );
        }
        push @row, $value;
      }
      elsif ($ports_info->{$port} && defined $ports_info->{$port}->{$col_id} ){
        if ( $col_id eq 'PORT_STATUS' ){
          push @row, ($ports_info->{$port} && $ports_info->{$port}{PORT_STATUS})
            ? $html->button(
              $html->color_mark( $ports_state[ $ports_info->{$port}{PORT_STATUS} ],
                $ports_state_color[ $ports_info->{$port}{PORT_STATUS} ] ),
              "index=$index&visual=2&PORT=$port&chg=$port&NAS_ID=$nas_id",
              { TITLE => $lang{CHANGE_PORT} }
            )
            : '';
        }
        elsif ( $col_id eq 'UPLINK' ){
          my $value = '';
          if ($used_ports->{ 'sw:' . $ports_info->{$port}->{UPLINK} }) {
            $value .= show_used_info( $used_ports->{ 'sw:' . $ports_info->{$port}->{UPLINK} } );
          }
          push @row, $value;
        }
        elsif($col_id eq 'VLAN' || $col_id eq 'NATIVE_VLAN') {
          if (defined($ports_info->{$port-$port_shift}) && $ports_info->{$port-$port_shift}->{$col_id}) { #FIXME: is not working correctly. should be fixed in equipment_test(?)
            push @row, $ports_info->{$port - $port_shift}->{$col_id};
          }
          else {
            push @row, q{};
          }
        }
        elsif($col_id eq 'CABLE_TESTER') {
          my $value = cable_tester_result_former($ports_info->{$port}->{CABLE_TESTER});

          push @row, $value;
        }
        elsif($col_id eq 'PORT_IN_ERR') {
          my $value = $html->color_mark(($ports_info->{$port}->{PORT_IN_ERR} // '?')
            . '/'
            . ($ports_info->{$port}->{PORT_OUT_ERR} // '?'),
            ( $ports_info->{$port}->{PORT_OUT_ERR} || $ports_info->{$port}->{PORT_IN_ERR} ) ? 'text-danger' : undef );
          push @row, $value
        }
        elsif($col_id eq 'PORT_IN_DISCARDS') {
          my $value = $html->color_mark(($ports_info->{$port}->{PORT_IN_DISCARDS} // '?')
            . '/'
            . ($ports_info->{$port}->{PORT_OUT_DISCARDS} // '?'),
            ( $ports_info->{$port}->{PORT_OUT_DISCARDS} || $ports_info->{$port}->{PORT_IN_DISCARDS}) ? 'text-danger' : undef );
          push @row, $value
        }
        elsif($col_id eq 'PORT_SPEED') {
          my $value = 0;
          if ($ports_info->{$port}->{PORT_SPEED} == 4294967295) {
            $value = '10+ Gbps';
          }
          elsif ($ports_info->{$port}->{PORT_SPEED} == 1000000000) {
            $value = '1 Gbps';
          }
          elsif ($ports_info->{$port}->{PORT_SPEED} == 100000000) {
            $value = '100 Mbps';
          }
          else {
            $value = int2byte($ports_info->{$port}->{PORT_SPEED}) . 'ps' || $ports_info->{port}->{PORT_SPEED};
          }
          push @row, $value;
        }
        else{
          push @row, $ports_info->{$port}->{$col_id};
        }
      }
      else{
        push @row, '';
      }
    }

    push @row, $html->button( $lang{INFO}, "index=$index&visual=$FORM{visual}&PORT=$port&chg=" . $port . "&NAS_ID=$nas_id",
        { class => 'change' } )
        . $html->button( $lang{DEL}, "index=$index&visual=$FORM{visual}&PORT=$port&del=" . $port . "&NAS_ID=$nas_id",
        { MESSAGE => "$lang{DEL} $lang{PORT}: $port?", class => 'del' } );

    push @row_colors, ($FORM{HIGHLIGHT_PORT} && $snmp_port && $FORM{HIGHLIGHT_PORT} eq $snmp_port ) ? 'table-success' : '';
    push @all_rows, \@row;
  }

  print result_row_former({
    table      => $table,
    ROWS       => \@all_rows,
    ROW_COLORS => \@row_colors,
    TOTAL_SHOW => 1,
  });

  return 1;
}

#********************************************************
=head2 equipment_ports($attr)

  Arguments:
    $attr


=cut
#********************************************************
sub equipment_ports {
  my ($attr) = @_;

  my $SNMP_COMMUNITY = $attr->{SNMP_COMMUNITY} || q{};
  $Equipment->{ACTION} = 'add';
  $Equipment->{ACTION_LNG} = $lang{ADD};

  if ( $FORM{add} ){
    $Equipment->port_add( { %FORM } );

    if ( !$Equipment->{errno} ){
      $html->message( 'info', $lang{INFO}, $lang{ADDED});
      $Equipment->{ID}     = $Equipment->{INSERT_ID};
      $FORM{chg}           = $Equipment->{ID};
      $Equipment->{ACTION} = 'change';
      $Equipment->{ACTION_LNG} = $lang{CHANGE};
    }
  }
  elsif ( defined($FORM{change}) ){
    $Equipment->port_change( { %FORM } );
    if ( !$Equipment->{errno} ){
      $html->message( 'info', $lang{INFO}, "$lang{CHANGED}" );

      $Equipment->{ACTION} = 'change';
      $Equipment->{ACTION_LNG} = $lang{CHANGE};
    }
  }
  elsif ( defined( $FORM{del} ) && $FORM{COMMENTS}){
    $Equipment->port_info({ NAS_ID => $FORM{NAS_ID}, PORT => $FORM{del} } );
    if ( !$Equipment->{errno} ){
      $Equipment->port_del( $Equipment->{ID} );
      if ( !$Equipment->{errno} ){
        $html->message( 'info', $lang{INFO}, "$lang{DELETED}" );
        delete $FORM{PORT};
      }
    }
  }
  elsif ( $FORM{PORT} ){
    $Equipment->port_info({ NAS_ID => $FORM{NAS_ID}, PORT => $FORM{PORT} } );
    if ( !$Equipment->{errno} ){
      $html->message( 'info', $lang{INFO}, "$lang{CHANGING} $lang{PORT}: $FORM{PORT}" );
      $Equipment->{ACTION} = 'change';
      $Equipment->{ACTION_LNG} = $lang{CHANGE};
    }
  }
  elsif ($FORM{MK_PORTS}) {
    my $message = q{};
    if ($attr->{NAS_INFO}{PORTS}) {
      my $nas_ports = $attr->{NAS_INFO}{PORTS};
      my $main_vlan = $attr->{NAS_INFO}{INTERNET_VLAN} || 0;
      for (my $i=1; $i<=$nas_ports; $i++) {
        my $port_vlan = 0;
        if($main_vlan > 0) {
          $port_vlan = $main_vlan + $i;
        }
        $Equipment->port_add({
          NAS_ID   => $FORM{NAS_ID},
          PORT     => $i,
          COMMENTS => 'Offline Add',
          VLAN     => $port_vlan
        });

        my $error = $Equipment->{errstr} || q{};
        $message .= "$lang{PORT}: $i VLAN: $port_vlan $error\n";
      }
    }
    $html->message('info', $lang{INFO}, "PORTS_CREATED\n $message");
  }

  if ($FORM{SNMP} && $FORM{PORT} && $FORM{STATUS}) {
    my $result = equipment_change_port_status({
      PORT           => $FORM{PORT},
      PORT_STATUS    => $FORM{STATUS},
      SNMP_COMMUNITY => $SNMP_COMMUNITY,
      DEBUG          => $FORM{DEBUG}
    });

    if ($result) {
      $html->message( 'info', $lang{INFO}, "$lang{PORT_STATUS_CHANGING_SUCCESS} (SNMP)" );
    }
    else {
      $html->message( 'err', $lang{ERROR}, "$lang{PORT_STATUS_CHANGING_ERROR} (SNMP)" );
    }
  }

  _error_show( $Equipment, { ID => 451, MESSAGE => $lang{PORT} } ) ;

  $FORM{visual} = 2 if (!defined( $FORM{visual} ) && !$FORM{PORT});

  my $visual = $attr->{VISUAL} || $FORM{visual} || 0;
  if ( $visual == 0 && !$FORM{PORT} ){ #select port on abonent's page
    if ( $attr->{NAS_INFO}->{TYPE_ID} && $attr->{NAS_INFO}->{TYPE_ID} eq '4' ) { # 4 - PON
      equipment_pon_onu($attr);
    }
    else {
      equipment_ports_select($attr);
    }
  }
  #Show vlans
  elsif ( $visual == 1 ){
    equipment_vlans({
      %$attr,
      VLAN           => 1
    });
  }
  #Show ports
  elsif ( $visual == 2 && !$FORM{PORT}){
    equipment_ports_full( $attr );
  }
  # Pon information
  elsif ( $visual == 4 ){
    equipment_pon({
      %$attr,
    });
  }
  #Get FDB
  elsif ( $visual == 6 ){
    equipment_fdb($attr);
  }
  elsif ( $visual == 8 ){
    equipment_snmp_info($attr);
  }
  # Backup management
  elsif ( $visual == 9 ){
    equipment_show_snmp_backup_files("BACKUP", $FORM{NAS_ID});
  }
  elsif ( $visual == 10) {
    equipment_show_log($FORM{NAS_ID});
  }
  elsif ( $visual == 13) {
    equipment_pon_map();
  }
  elsif ( $visual == 14) {
    my $run_cmd = equipment_run_cmd_on_equipment_button({
      nas_id   => $attr->{NAS_INFO}->{NAS_ID},
      model_id => $attr->{NAS_INFO}->{MODEL_ID},
      status   => $attr->{NAS_INFO}->{STATUS},
    });
    print $html->tpl_show(_include('equipment_command_run', 'Equipment'), { CMD_RUN => $run_cmd}, { OUTPUT2RETURN => 1 });
  }
  elsif ( $visual == 2 && $FORM{PORT}) {
    $Equipment->{TYPE_SEL} = $html->form_select(
      'TYPE_ID',
      {
        SELECTED => $Equipment->{TYPE_ID},
        SEL_LIST => [ { id => 0, name => $lang{USER} }, { id => 1, name => 'UPLINK' } ],
        NO_ID    => 1,
      }
    );

    $Equipment->{STATUS_SEL} = $html->form_select(
      'STATUS',
      {
        SELECTED => $FORM{STATUS} || $Equipment->{STATUS} || 0,
        SEL_LIST => [ {}, { id => 1, name => 'Up' }, { id => 2, name => 'Down' } ],
        NO_ID    => 1,
      }
    );

    $Equipment->{UPLINK_SEL} = $html->form_select(
      'UPLINK',
      {
        SELECTED    => $FORM{UPLINK} || $Equipment->{UPLINK} || '',
        SEL_LIST    => $Equipment->_list( {
          %LIST_PARAMS,
          NAS_ID    => '_SHOW',
          NAS_NAME  => '_SHOW',
          SHORT     => 1,
          PAGE_ROWS => 9999,
          COLS_NAME => 1 } ),
        SEL_KEY     => 'nas_id',
        SEL_VALUE   => 'nas_name',
        SEL_OPTIONS => { '' => '--' },
      }
    );

    $Equipment->{VLAN_SEL} = $html->form_select(
      'VLAN',
      {
        SELECTED    => $Equipment->{VLAN} || $FORM{VLAN} || '',
        SEL_LIST    => $Equipment->vlan_list( { %LIST_PARAMS, NAME => '_SHOW', SHORT => 1, PAGE_ROWS => 9999, COLS_NAME => 1 } ),
        SEL_KEY     => 'id',
        SEL_VALUE   => 'name',
        NO_ID       => 1,
        SEL_OPTIONS => { '' => '--' },
      }
    );

    $Equipment->{ROWS_COUNT} = 1 if (! $Equipment->{ROWS_COUNT});
    $Equipment->{BLOCK_SIZE} = 4 if (! $Equipment->{BLOCK_SIZE});

    if ($Equipment->{ACTION} eq 'add') {
      $FORM{COMMENTS} = ''; #somewhy there are comments of equipment, not port
    }
    if (defined $Equipment->{VLAN} && $Equipment->{VLAN} == 0) {
      $Equipment->{VLAN} = undef; #dont display VLAN if it is 0
    }

    $html->tpl_show( _include( 'equipment_port', 'Equipment' ), { %FORM, %{$Equipment} } );
  }
#  equipment_ports_full( $attr );
  return 1;
}

#********************************************************
=head2 equipment_ports_select() - Prints modal window with ports panel. Used in port selection on abonent's page

=cut
#********************************************************
sub equipment_ports_select {
  my $nas_id = $Equipment->{NAS_ID} || $FORM{NAS_ID} || do {
    $html->message('err', $lang{ERROR}, "NO \$FORM{NAS_ID}");
    return 0;
  };

  $used_ports = equipments_get_used_ports({
    NAS_ID => $nas_id,
    #PORTS_ONLY => 1 #XXX if enable this, ports with uplinks will be considered busy
  });
  $Equipment->_info($nas_id);
  $Equipment->model_info( $Equipment->{MODEL_ID} );

  print $html->element('div', equipment_port_panel( $Equipment ), { class => 'modal-body' });
  return 1;
}

#********************************************************
=head2 equipments_get_used_ports() - Get user info from module Internet

   Arguments:
     $attr
       NAS_ID      - NAS id
       GET_MAC     - Add MAC identifier to user hash
       GET_NAS_MAC - Get NAS MAC #XXX is not used?
       FULL_LIST   - Add full list
       PORTS_ONLY  - Get only ports
       COLS_UPPER  - Upper Cols
       DEBUG       - Debug mode

   Results:
     Hash_ref

=cut
#********************************************************
sub equipments_get_used_ports{
  my ($attr) = @_;

  my %used_ports = ();
  my $list;
  my $Equipment_ = Equipment->new( $db, \%conf, $admin ); #XXX why do we need second Equipment object?

  if(in_array('Internet', \@MODULES)) {
    require Internet;
    Internet->import();
    my $Internet = Internet->new($db, $admin, \%conf);

#    require Internet::Sessions;
#    Internet::Sessions->import();
#    my $Sessions = Internet::Sessions->new($db, $admin, \%conf);

    if ($attr->{DEBUG} && $attr->{DEBUG} > 6) {
      $Internet->{debug} = 1;
    }

    $LIST_PARAMS{GROUP_BY}=' internet.id';

    $list = $Internet->user_list({
      %LIST_PARAMS,
      LOGIN           => '_SHOW',
      FIO             => '_SHOW',
      ADDRESS_FULL    => '_SHOW',
      CID             => '_SHOW',
      PORT            => '_SHOW',
      ONLINE          => '_SHOW',
      ONLINE_IP       => '_SHOW',
      ONLINE_CID      => '_SHOW',
      TP_NAME         => '_SHOW',
      IP              => '_SHOW',
      LOGIN_STATUS    => '_SHOW',
      INTERNET_STATUS => '_SHOW',
      NAS_ID          => $attr->{NAS_ID},
      COLS_UPPER      => $attr->{COLS_UPPER},
      COLS_NAME       => 1,
      PAGE_ROWS       => 1000000
    });

    foreach my $line (@{$list}) {

      if(! $attr->{PORTS_ONLY}) {
        if ($line->{online_cid}) {
          push @{ $used_ports{ $line->{cid} } }, $line; #XXX why key is $line->{cid}, not line->{online_cid}?
        }
        elsif ($line->{cid} && $line->{cid} !~ /any/ig) {
          push @{ $used_ports{ $line->{cid} } }, $line;
        }

        if ($line->{cpe_mac}) { #XXX we don't have cpe_mac in $list
          push @{ $used_ports{ $line->{cpe_mac} } }, $line;
        }
      }

      if ($attr->{NAS_ID}) {
        push @{ $used_ports{ $line->{port} } }, $line;
      }
    }
  }

  if ($attr->{PORTS_ONLY} && !$attr->{FULL_LIST}) {
    my $port_list = $Equipment_->port_list({
      NAS_ID     => $attr->{NAS_ID},
      UPLINK     => '_SHOW',
      PAGE_ROWS  => 1000,
      COLS_NAME  => 1
    });
    foreach my $line ( @{$port_list} ) {
      if ($line->{uplink}) {
        push @{ $used_ports{ $line->{port} } }, $line;
      }
    }
    return \%used_ports;
  }

  my $equipment_list = $Equipment_->_list( {
    NAS_ID          => '_SHOW',
    MAC             => '_SHOW',
    NAS_NAME        => '_SHOW',
    NAS_IP          => '_SHOW',
    STATUS          => '_SHOW',
    DISABLE         => '_SHOW',
    VENDOR_NAME     => '_SHOW',
    MODEL_NAME      => '_SHOW',
    TYPE_NAME       => '_SHOW',
    COLS_NAME       => 1,
    PAGE_ROWS       => 100000,
  } );

  my $Nas = Nas->new( $db, \%conf, $admin );
  my $nas_list = $Nas->list({
    NAS_ID    => '_SHOW',
    MAC       => '_SHOW',
    NAS_NAME  => '_SHOW',
    NAS_IP    => '_SHOW',
    NAS_TYPE  => '_SHOW',
    DISABLE   => '_SHOW',
    COLS_NAME => 1,
    PAGE_ROWS => 100000
  });
  my %ids = ();

  if ($nas_list) {
    @{$list} = (@{$equipment_list}, @{$nas_list});
  }
  else {
    @{$list} = (@{$equipment_list});
  }

  foreach my $line ( @{$list} ) {
    if (!$ids{ $line->{nas_id} }) {
      if ($attr->{FULL_LIST}) {
        if ( $attr->{GET_MAC} ) {
         #        $used_ports{ $line->{mac} } = $line;
        }
        elsif ( $attr->{PORTS_ONLY} ) {
          push @{ $used_ports{ 'sw:' . $line->{nas_id} } }, $line;
        }
        else {
          my $mac = ($line->{mac}) ? lc( $line->{mac} ) : q{};
          push @{ $used_ports{ $mac } }, $line;
        }
      }
      else {
        my $mac = ($line->{mac}) ? lc( $line->{mac} ) : q{};
        $used_ports{ $mac }  = "sw:$line->{id}:". ($line->{nas_name} || q{});
      }
    }
    $ids{ $line->{nas_id} } = 1;
  }

  return \%used_ports;
}

#********************************************************
=head2 equipment_port_panel($attr) - forms HTML representation of equipments panel

  Arguments:
    $Equipment - hash
      PORTS               - count of ports
      BLOCK_SIZE          - number representing quantity of ports in a group
      ROWS_COUNT          - number of rows on panel
      PORTS_TYPE          - type of ports
      FIRST_POSITION      - (boolean) first port is on upper or bottom row;
      PORT_NUMBERING      - (boolean) numbering by rows or by column
      ID                  - ID of model

  Returns:
    HTML div

=cut
#********************************************************
sub equipment_port_panel {
  my ($attr) = @_;

  my $port_count            = $attr->{PORTS} || 0;
  my $block_size            = $attr->{BLOCK_SIZE} || 1;
  my $rows_count            = $attr->{ROWS_COUNT} || 1;
  my $port_type             = $attr->{PORTS_TYPE} || 1;
  my $port_type_name        = $port_types[$port_type];
  my $port_numbered_by_rows = $attr->{PORT_NUMBERING};
  my $first_port_position   = $attr->{FIRST_POSITION};
  my $width                 = (defined($attr->{WIDTH}) && $attr->{WIDTH} !=0) ? ($attr->{WIDTH}*100).'px' : '100%';
  my $height                = (defined($attr->{HEIGHT}) && $attr->{HEIGHT} !=0) ? ($attr->{HEIGHT}*100).'px' : '100%';

  my $search_result = {}; #used for modal search (will be passed to js:fillSearchResults() )
  if ($attr->{NAS_ID}) {
    # Get port info
    my $port_list = $Equipment->port_list({
      NAS_ID    => $attr->{NAS_ID},
      VLAN      => '_SHOW',
      COLS_NAME => 1
    });

    my $ports_name = (in_array('Internet', \@MODULES)) ? 'PORT' : 'PORTS'; #XXX is this Dv-specific?
    my $vlan_name = (in_array('Internet', \@MODULES)) ? 'VLAN' : 'VID';
    my $server_vlan_name = (in_array('Internet', \@MODULES)) ? 'SERVER_VLAN' : 'SERVER_VID';

    # For modal search
    foreach my $line (@$port_list) {
      next if (!$line->{port});

      $search_result->{$line->{port}}
        = $ports_name . "::" . ($line->{port} || q{})
        . '#@#' . $vlan_name . "::" . ($line->{vlan} || '')
        . '#@#' . $server_vlan_name . "::" . ($Equipment->{SERVER_VLAN} || '');
    }
  }

  my $extra_ports = $Equipment->extra_ports_list( (defined($attr->{MODEL_ID})) ? $attr->{MODEL_ID} : $attr->{ID});
  _error_show( $Equipment );

  #sort by row
  my $ports_by_row = { };
  my $combo_for_non_extra_ports = { };
  foreach my $port ( @{$extra_ports} ) {
    if ($port->{port_combo_with} < 0) {
      $combo_for_non_extra_ports->{-$port->{port_combo_with}} = 1;
    }

    next if (!defined($port->{row}));
    if ( $ports_by_row->{$port->{row}} ) {
      push @{ $ports_by_row->{$port->{row}} }, $port;
    }
    else {
      $ports_by_row->{$port->{row}} = [ $port ];
    }
  }

  my $ports_in_row = $port_count / $rows_count;
  my $blocks_in_row = $ports_in_row / $block_size;

  my $number = 0;
  my $unit_border = '';
  my $main_port_number = 0;

  my $panel = "<div class='equipment-panel'>\n";

  if ($width ne '100%' || $height ne '100%'){
    $unit_border = "<div class='border border-danger p-2' style='width:$width; height:$height; margin: auto'>\n";
    $panel .= $unit_border;
  }
  $panel .= "<link rel='stylesheet' type='text/css' href='/styles/default/css/modules/equipment.css'>";

  my @reversed_rows = ();
  my $leveling = 0;
  my %combo_numeration = ();

  #############################
  #  NEW SCHEME FOR PORT ROWS
  if ($port_numbered_by_rows) {
    $panel .= "<div class='row equipment-row'>";
    for (my $block_num = 0; $block_num < $blocks_in_row; $block_num++) {
      my @new_rows = ();
      my $col = "<div class='col-auto equipment-col'>";
      for ( my $row_in_num = 0; $row_in_num < $rows_count; $row_in_num++) {
        my $row_some = "<div class='row equipment-row flex-nowrap'>";
        for ( my $port_num = 0; $port_num < $block_size; $port_num++ ) {
          $main_port_number = $row_in_num + ($rows_count * $port_num) + ($block_num * $block_size * $rows_count) + 1;
          if ( $main_port_number <= $port_count ) {
            my $class = (!$used_ports->{$main_port_number})
            ? "clickSearchResult port port-$port_type_name-free"
            : "clickSearchResult port port-$port_type_name-used port-used";

            my $title = (($combo_for_non_extra_ports->{$main_port_number}) ? $lang{COMBO_PORT} : $lang{PORT}) . " $main_port_number ($port_type_name)";
            $row_some .= _get_html_for_port( $main_port_number, $class, $title, $search_result->{$main_port_number});

          }
        }
        $row_some .= "</div>";
        push @new_rows, $row_some;
      }
      if ($first_port_position) {
        $col .= join("", reverse @new_rows);
      } else {
        $col .= join("", @new_rows);
      }
      $col .= "</div>";
      $panel .= $col;
    }

    if (%{$ports_by_row}) {
      my $extra_col .= "<div class='col-auto equipment-col'>";
      my @extra_port_rows = sort keys %{$ports_by_row};

      @extra_port_rows = 0..$extra_port_rows[-1];


      if ($first_port_position) {
        my $minimal = $extra_port_rows[0] > 0 ? 0 : $extra_port_rows[0];
        my $maximum = $extra_port_rows[-1] || $rows_count - 1;

        @extra_port_rows = $minimal..$maximum;
        @extra_port_rows = reverse @extra_port_rows;
      }

      for my $extra_row_number (@extra_port_rows) {
        my $extra_row = "<div class='row equipment-row flex-nowrap'>";
        if (!defined($ports_by_row->{$extra_row_number})) {
          $extra_row = "<div class='row equipment-row port'>";
        } else {
          foreach my $port (@{$ports_by_row->{$extra_row_number}}) {
            my $extra_port_type_name = $port_types[$port->{port_type}];
            my $class = "port port-$extra_port_type_name-free"; #TODO: add possibility to have busy extra port
            my $extra_port_number = 0;
            # continuation of the numbering of the main row
            $extra_port_number = ($attr->{CONT_NUM_EXTRA_PORTS}) ? ($port_count + $port->{port_number}) : $port->{port_number};
            $extra_port_number -= $leveling;
            $combo_numeration{$port->{port_number}} = $extra_port_number if ($port->{port_combo_with} !=0) ;

            if ($port->{port_combo_with}) {
              $leveling += 1;
              if ($port->{port_combo_with} < 0) {
                $extra_port_number = -$port->{port_combo_with};
                if ($used_ports->{$extra_port_number}) {
                  $class = "port port-$extra_port_type_name-used port-used";
                }
              }
              elsif ($port->{port_number} > $port->{port_combo_with} && $port->{port_combo_with} != 0) {
                $extra_port_number = $combo_numeration{$port->{port_combo_with}};
                $leveling -= 1;
              }
            }

            $extra_port_number = 'e'.$extra_port_number;

            # if empty port
            if ($port->{port_type} == 9){
              $leveling += 1;
              $extra_port_number = '';
            }

            my $title = (($port->{port_combo_with}) ? $lang{COMBO_PORT} : $lang{PORT}) . " $extra_port_number ($extra_port_type_name)";
            $extra_row .= _get_html_for_port($extra_port_number, $class, $title, $extra_port_number); #TODO: if extra ports will have correct number, it will be possible to fill $data_value
          }
        }
        $extra_row .= "</div>";
        $extra_col .= $extra_row;
      }
      $extra_col .= "</div>";
      $panel .= $extra_col;
    }
    if ($width ne '100%' || $height ne '100%'){
      $unit_border = "</div>";
      $panel .= $unit_border;
    }
    $panel .= "</div>";
  }
  else {
    #############################
    # OLD SCHEME FOR PORT ROWS start
    for (my $row_num = 0; $row_num < $rows_count; $row_num++) {
      my $row = "<div class='row equipment-row'>";
      for (my $block_num = 0; $block_num < $blocks_in_row; $block_num++) {
        my $block = "<div class='equipment-block'>";
        # for row building
        for (my $port_num = 0; $port_num < $block_size; $port_num++) {
          $main_port_number++;
          if ($main_port_number <= $port_count) {
            my $class = (!$used_ports->{$number})
              ? "clickSearchResult port port-$port_type_name-free"
              : "clickSearchResult port port-$port_type_name-used port-used";

            my $title = (($combo_for_non_extra_ports->{$main_port_number}) ? $lang{COMBO_PORT} : $lang{PORT}) . " $main_port_number ($port_type_name)";
            $block .= _get_html_for_port($main_port_number, $class, $title, $search_result->{$main_port_number});
          }
        }
        $block .= "</div>";
        $row .= $block;
      }

      #check for extra ports
      if ($ports_by_row->{$row_num}) {
        $row .= "<div class='equipment-block'>";
        foreach my $port (@{$ports_by_row->{$row_num}}) {
          my $extra_port_type_name = $port_types[$port->{port_type}];
          my $class = "port port-$extra_port_type_name-free"; #TODO: add possibility to have busy extra port
          my $extra_port_number = 0;

          # continuation of the numbering of the main row
          $extra_port_number = ($attr->{CONT_NUM_EXTRA_PORTS}) ? ($port_count + $port->{port_number}) : $port->{port_number};
          $extra_port_number -= $leveling;
          $combo_numeration{$port->{port_number}} = $extra_port_number if ($port->{port_combo_with} !=0) ;

          if ($port->{port_combo_with}) {
            $leveling += 1;
            if ($port->{port_combo_with} < 0) {
              $extra_port_number = -$port->{port_combo_with};
              if ($used_ports->{$extra_port_number}) {
                $class = "port port-$extra_port_type_name-used port-used";
              }
            }
            elsif ($port->{port_number} > $port->{port_combo_with} && $port->{port_combo_with} != 0) {
              $extra_port_number = $combo_numeration{$port->{port_combo_with}};
              $leveling -= 1;
            }
          }

          $extra_port_number = 'e'.($extra_port_number || 0);

          # if empty port
          if ($port->{port_type} && $port->{port_type} == 9){
            $leveling += 1;
            $extra_port_number = '';
          }

          my $title = (($port->{port_combo_with}) ? $lang{COMBO_PORT} : $lang{PORT}) . " $extra_port_number ($extra_port_type_name)";
          $row .= _get_html_for_port($extra_port_number, $class, $title, $extra_port_number); #TODO: if extra ports will have correct number, it will be possible to fill $data_value
        }
        $row .= "</div>";
      }

      $row .= "</div>";

      if ($first_port_position) {
        push(@reversed_rows, $row);
      }
      else {
        $panel .= $row;
      }
    }

    if ($first_port_position) {
      #down
      my @rows = reverse @reversed_rows;
      $panel .= join('', @rows);
    }
    if ($width ne '100%' || $height ne '100%'){
      $unit_border = "</div>";
      $panel .= $unit_border;
    }
    $panel .= "</div>";
  }
  #form extra_ports_json string
  my $extra_ports_json = "<input type='hidden' id='extraPortsJson' value='[ ";
  my @rows_json = ();
  foreach my $row( @$extra_ports ) {
    push ( @rows_json,  '{"rowNumber": ' . $row->{row} . ', "portNumber": ' . $row->{port_number} . ', "portType": ' . $row->{port_type} . ', "portComboWith": ' . $row->{port_combo_with} . ' }' );
  }

  $extra_ports_json .= join( ", ", @rows_json );
  $extra_ports_json .= " ]' >";

  $panel .= $extra_ports_json;

  return $panel;
}

#********************************************************
=head2 _get_html_for_port($number, $class, $title, $data_value) - Returns HTML of port

  Arguments:
    $number - port number. will be displayed on port
    $class - class. usually contains 'port port-$type-free' or 'port port-$type-used port-used'
    $title - title
    $data_value - value. used to set abonent's port/vlan/server_vlan

  Returns:
    HTML of port

=cut
#********************************************************
sub _get_html_for_port{
  my ($number, $class, $title, $data_value) = @_;

  $data_value ||= $number;

  return $html->element(
    'div',
    $html->b( $number ),
    {
      class => $class,
      title => $title,
      value => $data_value
    }
  );
}

#**********************************************************
=head2 equipment_port_info($attr) - Get specific port's info and create HTML of it.

  Arguments:
    $attr
      PORT - Port ID
      PORT_SHIFT - Port shift
      AUTO_PORT_SHIFT - Apply autoshift to port index. true or false
      INFO_FIELDS - List of fields to show
      attrs for equipment_test()

  Returns:
    $information_table - array ref

=cut
#**********************************************************
sub equipment_port_info {
  my ($attr) = @_;

  if (!$attr->{PORT}) {
    return [];
  }

  if ($attr->{PORT_SHIFT} && !$attr->{AUTO_PORT_SHIFT} && $attr->{PORT} =~ /^\d+$/) {
    $attr->{PORT} += $attr->{PORT_SHIFT};
  }

  my $info_fields = $attr->{INFO_FIELDS};
  if ($attr->{AUTO_PORT_SHIFT}) {
    $info_fields .= ',PORT_INDEX';
  }

  my $test_result = equipment_test({
    %{ ($attr) ? $attr : {} },
    PORT_INFO      => $info_fields,
    PORT_ID        => $attr->{PORT},
    RUN_CABLE_TEST => $FORM{RUN_CABLE_TEST}
  });

  if (ref $test_result ne 'HASH') {
    return [];
  }

  my $port_id = (keys %$test_result)[0];
  if (!$port_id) {
    return [];
  }

  return port_result_former($test_result, {
    PORT                 => $port_id,
    INFO_FIELDS          => $info_fields
  });
}

#**********************************************************
=head2 port_result_former($port_info, $attr) - Create HTML of specific port's (or ONU's) info.

  Arguments:
    $port_info
    $attr
      PORT
      INFO_FIELDS
      EXTRA_INFO

  Returns:
    $information_table

=cut
#**********************************************************
sub port_result_former {
  my($port_info, $attr) = @_;
  $html->tpl_show( _include( 'equipment_icons', 'Equipment' ));
  my $user_index = get_function_index('form_users');

  my @info        = ();
  my @info_fields = ();
  my @skip_params = ('PORT_OUT', 'PORT_OUT_ERR', 'PORT_OUT_DISCARDS', 'ONU_OUT_BYTE', 'ONU_TX_POWER',
    'OLT_RX_POWER', 'VIDEO_RX_POWER', 'CATV_PORTS_COUNT', 'ETH_ADMIN_STATE', 'ETH_DUPLEX', 'ETH_SPEED',
    'ADMIN_PORT_STATUS');

  my $port_id     = $attr->{PORT};

  if($attr->{INFO_FIELDS}) {
    @info_fields = split(/,/, $attr->{INFO_FIELDS});
  }
  else {
    @info_fields = sort keys %{ $port_info->{$port_id} };
  }

  if (in_array('ONU_PORTS_STATUS', \@info_fields)) {
    push @skip_params, 'VLAN';
  }

  foreach my $key (@info_fields) {
    next if(! defined($port_info->{$port_id}->{$key}));

    my $value = $port_info->{$port_id}->{$key};
    if(in_array($key, \@skip_params)) {
      next;
    }
### АСР AXbills
    elsif($key eq 'PORT_SPEED') {
      my $color = '';

      if ($value == 4294967295) {
         $value = '10+ Gbps';
         $color = 'text-danger';
      }
      elsif ($value == 1000000000) {
         $value = '1 Gbps';
         $color = 'text-success';
      }
      elsif ($value == 100000000) {
         $value = '100 Mbps';
         $color = 'text-success';
      }
      elsif ($value == 10000000) {
         $value = '100 Mbps';
         $color = 'text-danger';
      }
      $value = $html->element('span', $value, { class => $color });
    }
###
    elsif($key eq 'PORT_STATUS') {
      my $port_status = $value;
      my $admin_port_status = $port_info->{$port_id}->{ADMIN_PORT_STATUS};

      my $button_text = '';
      my $color = '';

      if ($ports_state[$port_status] eq 'Up') {
        $button_text = $lang{DISABLE_INFINITIVE};
        $color = 'text-success';
      }
      elsif ($ports_state[$port_status] eq 'Down') {
        $button_text = $lang{ENABLE_INFINITIVE};
        $color = 'text-danger';
      }

      $value = $html->element('span', $ports_state[$port_status], { class => $color });

      my $button_disabled;
      if ($ports_state[$port_status] ne 'Up' && $admin_ports_state[$admin_port_status] eq 'Up') {
        $value .= ' (admin status ' . $html->element('span', 'Up', { class => 'text-success' }) . ')';
        $button_disabled = 1;
      }

      if ($permissions{0}{22}) {
        my $change_to_status = ($port_status == 1) ? 2 : 1;
        $value .= $html->element('button',
          $html->element('span', '', { class => 'fa fa-power-off' }),
          {
            id => 'change_status_button',
            class => "btn px-2 py-0 $color",
            title => $button_text,
            'data-change_to_status' => $change_to_status,
            ($button_disabled ? ( disabled => 1 ) : ())
          }
        );
      }
    }
    elsif($key eq 'RF_PORT_ON') { #TODO: rename to CATV
      my ($text, $color) = split(/:/, $value);
      $value = $html->color_mark($text, $color);
    }
    elsif($key eq 'ONU_IN_BYTE') {
      $key = $lang{TRAFFIC};
      $value = $lang{RECV} .': '.int2byte($value)
        . $html->br()
        . $lang{SENDED} .': '. int2byte($port_info->{$port_id}->{ONU_OUT_BYTE});
    }
    elsif($key eq 'PORT_IN') {
      #PORT_IN and PORT_OUT is swapped because we want to show traffic from abonent's side
      $key = $lang{TRAFFIC};
      $value = $lang{RECV} .': '.int2byte($port_info->{$port_id}->{PORT_OUT})
        . $html->br()
        . $lang{SENDED} .': '. int2byte($port_info->{$port_id}->{PORT_IN});
    }
    elsif($key eq 'ONU_RX_POWER'){
      my $color_num = '';
      if($port_info->{$port_id}->{ONU_RX_POWER}) {
        $color_num = pon_tx_alerts( $value, 1 );
        $value = 'ONU_RX_POWER: ' .  pon_tx_alerts( $value );
      }
      if($port_info->{$port_id}->{ONU_TX_POWER}) {
        $value .= 'ONU_TX_POWER: ' . pon_tx_alerts($port_info->{$port_id}->{ONU_TX_POWER});
      }
      if($port_info->{$port_id}->{OLT_RX_POWER}) {
        $value .= 'OLT_RX_POWER: ' . pon_tx_alerts( $port_info->{$port_id}->{OLT_RX_POWER} );
      }
      if(defined $port_info->{$port_id}->{VIDEO_RX_POWER}) {
        $value .= 'VIDEO_RX_POWER: ' . pon_tx_alerts_video( $port_info->{$port_id}->{VIDEO_RX_POWER} );
      }
      my %color = (
        '' => '',
        1  => 'text-success',
        2  => 'text-danger',
        3  => 'text-warning'
      );
      $key = $html->element( 'i', " ", { class => "fa fa-signal $color{$color_num}"} ) . $html->element('label', "&nbsp;&nbsp;&nbsp;&nbsp;" . ($lang{POWER} || q{POWER}) );
    }
    elsif($key eq 'ONU_PORTS_STATUS') {
      $key = "$lang{PORTS}:";
      my @ports_status = split(/\n/, $value);
      $value = q{};
      foreach my $line (@ports_status) {
        my ($port, $status)=split(/ /, $line);
        $status //= 0;
        my $color       = ($status == 1) ? 'text-green' : '';
        my $description = (($status == 1) ? "State: Up " : "State: Down ") . $html->br();
        my $speed       = $port_info->{$port_id}->{ETH_SPEED}->{$port} || '';
        my $duplex      = $port_info->{$port_id}->{ETH_DUPLEX}->{$port} || '';
        my $admin_state = $port_info->{$port_id}->{ETH_ADMIN_STATE}->{$port} || '';
        my $vlan        = ($port_info->{$port_id}->{VLAN} && ref $port_info->{$port_id}->{VLAN} eq 'HASH' ) ? $port_info->{$port_id}->{VLAN}->{$port} : ($port_info->{$port_id}->{VLAN} || '');

#$admin_state = "Disble" if ($port  eq '5');
#$speed = '1Gb/s' if ($port eq '2');
#$speed = '10Gb/s' if ($port eq '3');
#$speed = '10Mb/s' if ($port eq '4');
#$status = 1 if ($port eq '3' || $port eq '4');
#$speed = '' if ($port eq '6' || $port eq '8');
#$admin_state = '' if ($port  eq '7' || $port eq '8');
#$duplex = 'Full';

        $description .= "Speed: $speed ".$html->br() if ($speed);
        $description .= "Duplex: $duplex ".$html->br() if ($duplex);
        $description .= "Native Vlan: $vlan ".$html->br() if ($vlan);

        my $btn = q{};
        if ($admin_state) {
          my $describe_state = ($admin_state eq 'Enable') ? $lang{DISABLE_PORT} : $lang{ENABLE_PORT};
          my $disable_or_enable_url_param = ($admin_state eq 'Enable') ? 'disable_eth_port' : 'enable_eth_port';
          my $badge_type = ($admin_state eq 'Enable') ? 'up' : 'down';
          $color = ($admin_state eq 'Enable') ? $color : 'text-red';
          my $badge = $html->element('span',
            $html->button("",
              "NAS_ID=$FORM{NAS_ID}" .
              "&index=" . get_function_index('equipment_info') .
              "&visual=4&$disable_or_enable_url_param=$port" .
              "&ONU=$FORM{ONU}&info_pon_onu=$FORM{info_pon_onu}&ONU_TYPE=$FORM{ONU_TYPE}",
              { ADD_ICON => 'fa fa-power-off', MESSAGE => "$describe_state $port?"}),
            { 'data-tooltip' => $describe_state, 'data-tooltip-position' => 'top' }
          );
          $btn .= $html->element('span', $badge, { class => 'badge badge-' . $badge_type });
        }
        $btn .= $html->element('span', '', { class => 'icon icon-eth ' . $color });
        $btn .= $html->element('span', $port, { class => 'port-num' });

        if ($speed) {
          my $color_bb = q{};
          if ($speed =~ /^\d+Gb\/s/ && $status == 1){
            $color_bb = 'text-green';
          }
          elsif ($speed =~ /^\d+Mb\/s/ && $status == 1){
            $color_bb = 'text-yellow';
          }
          $btn .= $html->element('span', $speed, {class => 'badge-bottom ' . $color_bb }) if ($speed);
        }
        $value .= $html->element('span', $btn, {class => 'btn-ethernet', 'data-tooltip' => $description, 'data-tooltip-position' => 'bottom'});
      }

      $value .= $html->br() . "&emsp;";

      my $help_ = q{};
      $help_ = $html->element('span', '', { class => 'fa fa-square text-dark-gray' }) . ' - Down &emsp;';
      $value .= $html->element('span', $help_, {'data-tooltip' => 'Port is Down', 'data-tooltip-position' => 'bottom'});

      $help_ = $html->element('span', '', { class => 'fa fa-square text-green' }) . ' - Up &emsp;';
      $value .= $html->element('span', $help_, {'data-tooltip' => 'Port is Up', 'data-tooltip-position' => 'bottom'});

      if (scalar keys %{ $port_info->{$port_id}->{ETH_ADMIN_STATE} }) {
        $help_ = $html->element('span', '', { class => 'fa fa-square text-red' }) . ' - Shutdown &emsp;';
        $value .= $html->element('span', $help_, {'data-tooltip' => 'Admin state shutdown', 'data-tooltip-position' => 'bottom'});
      }

    }
    elsif($key eq 'CATV_PORTS_STATUS' || $key eq 'CATV_PORTS_ADMIN_STATUS') {
      next if (defined($port_info->{$port_id}->{CATV_PORTS_COUNT}) && $port_info->{$port_id}->{CATV_PORTS_COUNT} == 0);
      next if ($key eq 'CATV_PORTS_ADMIN_STATUS' && defined $port_info->{$port_id}->{CATV_PORTS_STATUS});

      my @ports_status = split(/\n/, $value);
      $value = q{};

      foreach my $line (@ports_status) {
        my ($port, $status);
        my $admin_state;

        if (split(/ /, $line) == 2) {
          ($port, $status) = split(/ /, $line);
          $admin_state = $port_info->{$port_id}->{CATV_PORTS_ADMIN_STATUS}->{$port} || '';
        }
        else { #if we do not have multiple ports
          ($port, $status) = (1, $line);
          $admin_state = $port_info->{$port_id}->{CATV_PORTS_ADMIN_STATUS} || '';
        }

        if ($key eq 'CATV_PORTS_ADMIN_STATUS') {
          $status = ($status eq 'Enable') ? 1 : 2;
        }

        my $color = ($status == 1) ? 'text-green' : 'text-dark-gray';
        my $description;
        if ($key eq 'CATV_PORTS_STATUS') {
          $description = (($status == 1) ? 'State: Up ' : 'State: Down ') . $html->br();
        }

        my $btn = q{};
        if ($admin_state) {
          my $describe_state = ($admin_state eq 'Enable') ? $lang{DISABLE_CATV_PORT} : $lang{ENABLE_CATV_PORT};
          my $disable_or_enable_url_param = ($admin_state eq 'Enable') ? 'disable_catv_port' : 'enable_catv_port';
          my $badge_type = ($admin_state eq 'Enable') ? 'up' : 'down';
          $color = ($admin_state eq 'Enable') ? $color : 'text-red';
          my $badge = $html->element('span',
            $html->button("",
              "NAS_ID=$FORM{NAS_ID}" .
              "&index=" . get_function_index('equipment_info') .
              "&visual=4&$disable_or_enable_url_param=$port" .
              "&ONU=". ($FORM{ONU} || q{}) ."&info_pon_onu=". ($FORM{info_pon_onu} || q{}) ."&ONU_TYPE=". ($FORM{ONU_TYPE} || q{}),
              { ADD_ICON => 'fa fa-power-off', MESSAGE => "$describe_state $port?"}),
            { 'data-tooltip' => $describe_state, 'data-tooltip-position' => 'top' }
          );
          $btn .= $html->element('span', $badge, { class => 'badge badge-' . $badge_type });
        }
        $btn .= $html->element('span', '', { class => 'icon icon-television ' . $color });
        $btn .= $html->element('span', $port, { class => 'port-num ' . $color });

        $value .= $html->element('span', $btn, {class => 'btn-ethernet', 'data-tooltip' => $description, 'data-tooltip-position' => 'bottom'});
      }

      $value .= $html->br() . "&emsp;";

      my $help_ = q{};

      if ($key ne 'CATV_PORTS_ADMIN_STATUS') {
        $help_ = $html->element('span', '', { class => 'fa fa-square text-dark-gray' }) . ' - Down &emsp;';
        $value .= $html->element('span', $help_, {'data-tooltip' => 'Port is Down', 'data-tooltip-position' => 'bottom'});
      }

      $help_ = $html->element('span', '', { class => 'fa fa-square text-green' }) . ' - Up &emsp;';
      $value .= $html->element('span', $help_, {'data-tooltip' => 'Port is Up', 'data-tooltip-position' => 'bottom'});

      if ($port_info->{$port_id}->{CATV_PORTS_ADMIN_STATUS}) {
        $help_ = $html->element('span', '', { class => 'fa fa-square text-red' }) . ' - Shutdown &emsp;';
        $value .= $html->element('span', $help_, {'data-tooltip' => 'Admin state shutdown', 'data-tooltip-position' => 'bottom'});
      }

      $key = "CATV $lang{PORTS}:";
    }
    elsif($key eq 'CABLE_TESTER') {
      $key = $html->element( 'i', "", { class => 'fa fa-chart-bar' } ) . $html->element('label', "&nbsp;&nbsp;&nbsp;&nbsp;$lang{$key}" );

      if(ref $value eq 'HASH') {
        $value = cable_tester_result_former($value);
      }
      else {
        $value = $html->button(
          $lang{TEST},
          '',
          {
            class => 'btn btn-secondary',
            ID => 'run_cable_test_button',
            SKIP_HREF => 1
          }
        );
      }
    }
    elsif($key eq 'PORT_IN_ERR') {
      my $reset_errors_button = '';

      my $list = $Equipment->_list({ SNMP_TPL => '_SHOW', NAS_ID => $FORM{NAS_ID}, COLS_NAME => 1 });
      my $nas_info = $list->[0];

      if ($nas_info->{'snmp_tpl'}){
        my $TEMPLATE_DIR = $base_dir . 'AXbills/modules/Equipment/snmp_tpl/';
        my $file_content = file_op({
          FILENAME => $nas_info->{'snmp_tpl'},
          PATH     => $TEMPLATE_DIR,
        });
        $file_content =~ s#//.*$##gm;
        my $snmp = decode_json($file_content);
        if ($snmp->{ERRORS_RESET}){
          $reset_errors_button = $html->button($lang{RESET}, "index=$user_index&UID=$FORM{UID}&ERRORS_RESET=1", { class => 'btn btn-secondary btn-sm ml-2' });
        }
      }

      $key = "$lang{PACKETS_WITH_ERRORS} (in/out)";
      $value = $html->color_mark(($port_info->{$port_id}->{PORT_IN_ERR} // '?')
        . '/'
        . ($port_info->{$port_id}->{PORT_OUT_ERR} // '?') . $reset_errors_button,
        ( $port_info->{$port_id}->{PORT_OUT_ERR} || $port_info->{$port_id}->{PORT_IN_ERR} ) ? 'text-danger' : undef );
    }
    elsif($key eq 'PORT_IN_DISCARDS') {
      $key = "Discarded $lang{PACKETS_} (in/out)";
      $value = $html->color_mark(($port_info->{$port_id}->{PORT_IN_DISCARDS} // '?')
        . '/'
        . ($port_info->{$port_id}->{PORT_OUT_DISCARDS} // '?'),
        ( $port_info->{$port_id}->{PORT_OUT_DISCARDS} || $port_info->{$port_id}->{PORT_IN_DISCARDS} ) ? 'text-danger' : undef );
    }
    elsif($key eq 'TEMPERATURE') {
      $key = $html->element( 'i', "", { class => 'fa fa-thermometer-half' } ) . $html->element('label', "&nbsp;&nbsp;&nbsp;&nbsp;$lang{$key}" );
      $value = $port_info->{$port_id}->{TEMPERATURE} . " &deg;C";
    }
    elsif($key eq 'VOLTAGE') {
      $key = $html->element( 'i', "", { class => 'fa fa-flash' } ) . $html->element('label', "&nbsp;&nbsp;&nbsp;&nbsp;$lang{$key}" );
    }
    elsif($key eq 'Mac/Serial') {
      $key = $html->element( 'i', "", { class => 'fa fa-barcode' } ) . $html->element('label', "&nbsp;&nbsp;&nbsp;&nbsp;$key" );
    }
    elsif($key eq 'ONU_DESC') {
      $key = $html->element( 'i', "", { class => 'fa fa-list-alt' } ) . $html->element('label', "&nbsp;&nbsp;&nbsp;&nbsp;$lang{DESCRIBE}" );
    }
    elsif($key eq 'STATUS') {
      $key = $html->element( 'i', "", { class => "fa fa-globe $attr->{COLOR_STATUS}" } ) . $html->element('label', "&nbsp;&nbsp;&nbsp;$lang{STATUS}" );
    }
    elsif($key eq 'PORT_UPTIME') {
      $key = $html->element( 'i', "", { class => "far fa-clock" } ) . $html->element('label', "&nbsp;&nbsp;&nbsp;$lang{PORT_UPTIME}" );
    }
    elsif($key eq 'MAC_BEHIND_ONU') {
      next if (!$value);
      $value = join ($html->br(),
        (sort map { $html->color_mark($value->{$_}->{mac}, 'code') .
          (($value->{$_}->{vlan}) ? " (VLAN $value->{$_}->{vlan})" : '')
        } grep { !$value->{$_}->{old} } (keys %$value)),
        (sort map { $html->color_mark($value->{$_}->{mac}, 'code') .
          (($value->{$_}->{vlan}) ? " (VLAN $value->{$_}->{vlan})" : '') . ' (old)'
        } grep { $value->{$_}->{old} } (keys %$value))
      );
    }

    $key = ($lang{$key}) ? $lang{$key} : $key;
    push @info, [ $key, $value ];
  }

  return \@info;
}

#**********************************************************
=head2 cable_tester_result_former($cable_test_info) - generates HTML for cable test info

  Arguments:
    $cable_test_info

  Returns:
    $result - HTML of cable test info

=cut
#**********************************************************
sub cable_tester_result_former {
  my ($cable_test_info) = @_;

  my $result = '';

  if ($cable_test_info->{ERROR}) {
    $result = $html->b("$lang{ERROR}") . ": $lang{CABLE_TEST_FAILED}";
    return $result;
  }

  foreach my $field (sort keys %$cable_test_info) {
    my $field_value = $cable_test_info->{$field};
    next if (!defined $field_value);

    if ($field =~ /LENGTH_PAIR(_(.*))?/) {
      $field = $html->b("$lang{LENGTH_PAIR}" . (($2) ? " $2" : "")) . ': ';
      $field_value = $html->element('p', $field_value);
    }
    elsif ($field =~ /STATUS_PAIR(_(.*))?/) {
      $field = $html->b("$lang{STATUS_PAIR}" . (($2) ? " $2" : "")) . ': ';
      my ($text, $color) = split(/:/, $field_value);

      if ($color) {
        $field_value = $html->color_mark($text, $color);
      }
      else {
        $field_value = $html->element('p', $field_value);
      }
    }
    elsif ($field eq 'CABLE_TEST_LINK_STATUS') {
      $field = $html->b("$lang{LINK_STATUS}") . ': ';
      $field_value = $html->element('p', $field_value);
    }
    elsif ($field eq 'CABLE_TEST_PORT_TYPE') {
      $field = $html->b("$lang{PORT_TYPE}") . ': ';
      $field_value = $html->element('p', $field_value);
    }
    elsif ($field eq 'LAST_CABLE_TEST_TIME') {
      $field = $html->b("$lang{LAST_CABLE_TEST_TIME}") . ': ';
      $field_value = $html->element('p', $field_value);
    }
    else {
      $field = $html->b($field) . ': ';
      $field_value = $html->element('p', $field_value);
    }

    $result .= $field . $field_value;
  }

  return $result;
}

#********************************************************
=head2 equipment_vlans($attr) - Show VLANs

  Arguments:
    $attr
      IP

=cut
#********************************************************
sub equipment_vlans {
  my ($attr) = @_;

  if (!defined($FORM{sub}) || $FORM{sub} eq '') {
    $FORM{sub} = 1;
  }
  #=== NAV TABS ===
  if ((!$attr->{NAS_INFO}->{TYPE_ID} || ($attr->{NAS_INFO}->{TYPE_ID} && $attr->{NAS_INFO}->{TYPE_ID} != 4)) && !$conf{SKIP_UNNUMBERED_TAB}) {
    my $active_button->{$FORM{sub}} = 'active';
    my %nav_tabs = (
      1 => "Vlans",
      2 => "Unnumbered vlans",
    );

    my $buttons = '';
    foreach (sort {$a <=> $b} keys(%nav_tabs)) {
      $buttons .= $html->li(
        $html->button($nav_tabs{$_},
          "index=$index&visual=$FORM{visual}&NAS_ID=$FORM{NAS_ID}&sub=$_",
          { class => "nav-link " . ($active_button->{$_} // '') }
        ),
        { class => 'nav-item' }
      )
    }

    my $ul_nav_bar = $html->element('ul', $buttons, { class => 'nav-tabs navbar-nav' });
    print $html->element('nav', $ul_nav_bar, { class => 'axbills-navbar navbar navbar-expand-lg navbar-light' });
  }
  #=== NAV TABS END ===

  if ($FORM{sub} == 2) {
    $Equipment->_info($FORM{NAS_ID});
    $html->tpl_show(_include('equipment_unnum_vlan', 'Equipment'), { %FORM, PORTS => $Equipment->{PORTS} });

    if ($FORM{vlans_add}) {
      if ($FORM{ports_from} & !$FORM{ports_to}) {
        $FORM{ports_to} = $FORM{ports_from};
      }

      if (! $FORM{ports_to} || ($Equipment->{PORTS} && $FORM{ports_to} > $Equipment->{PORTS})) {
        $FORM{ports_to} = $Equipment->{PORTS};
      }

      if ($FORM{ports_from} && $FORM{ports_to} && $FORM{ports_from} <= $FORM{ports_to}) {

        my $port_num = $FORM{ports_from};
        my $vlan_num = $FORM{VLAN};

        $Equipment->port_list({
          NAS_ID    => $FORM{NAS_ID},
          LIST2HASH => 'port,id',
        });

        _error_show($Equipment);
        my $list_hash = $Equipment->{list_hash};
        while ($port_num <= $FORM{ports_to}) {
          if (!exists $list_hash->{$port_num}) {
            $Equipment->port_add({
              NAS_ID   => $FORM{NAS_ID},
              PORT     => $port_num++,
              VLAN     => $vlan_num++,
              COMMENTS => 'auto created vlan',
            });
          }
          else {
            $Equipment->port_change({
              ID   => $list_hash->{$port_num},
              PORT => $port_num++,
              VLAN => $vlan_num++,
            });
          }
        }
      }
    }

    my $port_list = $Equipment->port_list({
      NAS_ID     => $FORM{NAS_ID},
      VLAN       => '!0',
      SORT       => 1,
      PAGE_ROWS  => 100,
      COLS_UPPER => 1,
      COLS_NAME  => 1,
    });

    my $table = $html->table({
      width   => '100%',
      caption => "Unnumbered VLANS",
      title   => [ $lang{PORTS}, "Vlan" ],
      qs      => "&visual=$FORM{visual}&NAS_ID=$FORM{NAS_ID}&sub=2",
      ID      => 'UNNUMBERED VLANS',
    });

    foreach my $port (@$port_list) {
      $table->addrow($port->{PORT}, $port->{VLAN});
    }
    print $table->show();
  }
  else {
    my $vlan_hash;

    if (!$Equipment->{STATUS}) {
      $vlan_hash = get_vlans({ %$attr, DEBUG => $FORM{DEBUG} });
    }
    else {
      $html->message('warn', $lang{INFO}, "$lang{STATUS} $service_status[$Equipment->{STATUS}]");
    }

    my $table = $html->table({
      width   => '100%',
      caption => "VLANS:" . ($attr->{IP} || '') . (($attr->{EXT_INFO}) ? ' ' . $html->button($attr->{EXT_INFO},
        "index=" . get_function_index('form_nas') . "&NAS_ID=" . $attr->{NAS_ID}) : ''),
      title   => [ 'VLAN', $lang{NAME}, $lang{PORTS} ],
      qs      => "&visual=$FORM{visual}&NAS_ID=$FORM{NAS_ID}",
      ID      => 'EQUIPMENT_SNMP_INFO',
    });

    foreach my $key (sort {$a <=> $b} keys %{$vlan_hash}) {
      $table->addrow($key,
        $vlan_hash->{$key}{NAME},
        $vlan_hash->{$key}{PORTS});
    }

    print $table->show();
  }

  return 1;
}

#********************************************************
=head2 equipment_show_map() - Show map in visual


=cut
#********************************************************
sub equipment_pon_map {

  require Maps::Maps_view;
  Maps::Maps_view->import();
  my $Maps_view = Maps::Maps_view->new($db, $admin, \%conf, { HTML => $html, LANG => \%lang });

  require Equipment::Maps_info;
  Equipment::Maps_info->import();
  my $Maps_info = Equipment::Maps_info->new($db, $admin, \%conf, { HTML => $html, LANG => \%lang });

  my $pon_maps = $Maps_info->pon_maps({RETURN_HASH => 1, NAS_ID => $FORM{NAS_ID}, TO_VISUAL => 1});

  print $Maps_view->show_map({}, {
    DATA              => $pon_maps,
    DONE_DATA         => 1,
    OUTPUT2RETURN     => 1,
    QUICK             => 1,
    HIDE_EDIT_BUTTONS => 1,
  });

  return 1;
}
1;
