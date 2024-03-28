
=head1 NAME

  Templates functions

=cut

use strict;
use warnings FATAL => 'all';
use POSIX qw(strftime);
use Internet;
require AXbills::Misc;

load_pmodule('SNMP');
$ENV{'MIBDIRS'} = "../../AXbills/MIBs";
#SNMP::initMib();
SNMP::addMibDirs("../../AXbills/MIBs/private");
SNMP::initMib();
my %snmpparms;
$snmpparms{Version} = 2;
$snmpparms{UseEnums} = 1;
$snmpparms{Retries} = 1;

our ($html,
  %lang,
  $admin,
  %conf,
  $db,
  @MONTHES,
  @WEEKDAYS,  
);

our Equipment $Equipment;
my $Internet = Internet->new( $db, $admin, \%conf );


#**********************************************************

=head2 equipment_tmpl_edit($attr)

=cut

#**********************************************************
sub equipment_tmpl_edit {
  my ($attr) = @_;

  my $tmpl = $Equipment->snmp_tpl_list(
    {
      COLS_NAME => 1,
      MODEL_ID  => $FORM{ID} || $attr->{ID},
      SECTION   => '_SHOW'
    }
  );
  my %menu;
  if ($tmpl) {
    foreach my $key ( 0..@$tmpl ) {
      $menu{$key} = $tmpl->[$key]->{section};
    }

    $pages_qs .= ($FORM{ID}) ? "&ID=$FORM{ID}" : q{};

    my $buttons;
    foreach my $key (sort keys %menu) {
      my $value = $menu{$key};
      $buttons .= $html->li($html->button($value, "index=$index&PARAM=$key$pages_qs"), { class => (defined($FORM{PARAM}) && $FORM{PARAM} eq $key) ? 'active' : '' });
    }
    $buttons .= $html->li(
      $html->button(
        (
          $lang{CREATE}, "index=$index$pages_qs",

          {
            MESSAGE => "$lang{CREATE} $lang{NEW}?",
            TEXT    => $lang{CREATE},
            class   => 'add'
          }
        )
      )
    );

    if ($buttons) {
      my $model_select = $html->form_select(
        'ID',
        {
          SELECTED => $attr->{ID} || $FORM{ID},
          SEL_LIST  => $Equipment->model_list({ MODEL_NAME => '_SHOW', MODEL_ID => '_SHOW', COLS_NAME => 1, PAGE_ROWS => 10000 }),
          SEL_KEY   => 'id',
          SEL_VALUE => 'model_name',
          NO_ID     => 1,

          #MAIN_MENU      => get_function_index( 'equipment_info' ),
          MAIN_MENU_ARGV => "ID=" . ($FORM{ID} || '')
        }
      );

      my $model_select_form = $html->form_main(
        {
          CONTENT => $model_select . $html->form_input('SHOW', $lang{SHOW}, { TYPE => 'submit' }),
          HIDDEN  => {
            'index' => $index,
            'PARAM' => $FORM{PARAM} ||= 0,
          },
          NAME  => 'model_edit_panel',
          ID    => 'equipment_edit_panel',
          class => 'navbar-form navbar-right',
        }
      );

      my $buttons_list = $html->element('ul', $buttons, { class => 'nav navbar-nav' });

      my $menu = $html->element('div', $buttons_list . $model_select_form, { class => 'navbar navbar-default' });

      print $menu;
    }

    my $cur_tmpl = ($FORM{PARAM}) ? $tmpl->[ $FORM{PARAM} ]->{parameters} : $tmpl->[0]->{parameters};
    my $values   = ($cur_tmpl)    ? JSON->new->utf8(0)->decode($cur_tmpl) : [];

    if ($FORM{ADD} || $FORM{DEL}) {
      my $sect;
      if ($FORM{ADD}) {
        my @tmp_arr;
        if (ref $values eq 'ARRAY') {
          foreach my $n (1..@$values) {
            push @tmp_arr, [ split(',', $FORM{$n}) ];
          }
          if ($FORM{OIDS}) {
            push @tmp_arr, [ $FORM{OIDS}, $FORM{NAME}, $FORM{TYPE}, $FORM{REGULAR} ];
          }
          $cur_tmpl = JSON->new->encode(\@tmp_arr);
          $cur_tmpl =~ s/\s//g;
        }
        else {
          my %tmp_hash;
          foreach my $key (sort keys %$values) {
            $tmp_hash{$key} = [ split(',', $FORM{$key}) ];
          }
          $cur_tmpl = JSON->new->encode(\%tmp_hash);
          $cur_tmpl =~ s/\s//g;
        }
      }
      elsif ($FORM{DEL}) {
        splice(@$values, $FORM{DEL} - 1, 1);
        $cur_tmpl = JSON->new->encode($values);
      }
      $Equipment->snmp_tpl_add(
        {
          MODEL_ID   => $FORM{ID},
          SECTION    => $sect || $tmpl->[ $FORM{PARAM} ||= 0 ]->{section},
          PARAMETERS => $cur_tmpl
        }
      );
    }
    $values = ($cur_tmpl) ? JSON->new->utf8(0)->decode($cur_tmpl) : [];
    my $table;
    $table = $html->table(
      {
        width       => '100%',
        title_plain => [ 'OID', $lang{NAME}, $lang{TYPE}, 'regular' ],
      }
    );

    if (ref $values eq 'ARRAY') {
      my $i = 1;
      foreach my $var (@$values) {
        my @arr;
        foreach my $vr ( 1..@$var) {
          push @arr, ($html->form_input($i, $var->[ $vr - 1 ]));
        }
        $table->addrow(
          @arr,
          $html->button(
            '',
            "index=$index$pages_qs&PARAM=$FORM{PARAM}&DEL=$i",
            {
              ICON  => 'fa fa-trash text-danger',
              title => $lang{DEL},
            }
          )
        );
        $i++;
      }

      $table->addrow($html->form_input('OIDS', ''), $html->form_input('NAME', ''), $html->form_input('TYPE', ''), $html->form_input('REGULAR', ''),);
    }
    else {
      $table = $html->table(
        {
          width => '100%',

          #title_plain => [ 'OID', $lang{NAME}, $lang{TYPE}, 'regular' ],
        }
      );
      foreach my $key (sort keys %$values) {
        my @arr;
        push @arr, $key;
        foreach my $vr (@{ $values->{$key} }) {
          push @arr, $html->form_input($key, $vr);
        }
        $table->addrow(@arr);
      }
    }
    print $html->form_main(
      {
        CONTENT => $table->show() . $html->form_input('ADD', "$lang{CHANGE}\/$lang{ADD}", { TYPE => 'SUBMIT' }),
        METHOD  => 'GET',
        class   => 'form-inline',
        HIDDEN  => {
          'index' => $index,
          'PARAM' => $FORM{PARAM} ||= 0,
          'ID'    => $FORM{ID}

        },
      }
    );
  }
  else {
    print $html->form_main(
      {
        CONTENT => "For this device no templates. Create new?" . $html->form_input('OIDS', '') . $html->form_input('NAME', '') . $html->form_input('TYPE', '') . $html->form_input('REGULAR', '') . $html->form_input('CREATE', $lang{CREATE}, { TYPE => 'SUBMIT' }),
        METHOD  => 'GET',
        class   => 'form-inline',
        HIDDEN  => {
          'index' => $index,
          'ID'    => $FORM{ID}

        },
      }
    );
  }

  return 1;
}

#**********************************************************

=head2 equipment_stats_edit()

=cut

#**********************************************************
sub equipment_stats_edit {
 my ($attr) = @_;
 
 $pages_qs .= ($FORM{NAS_ID} && $FORM{PORT}) ? "&NAS_ID=$FORM{NAS_ID}&PORT=$FORM{PORT}" : q{};
 my $root_index = get_function_index('equipment_panel_new') . "&NAS_ID=$FORM{NAS_ID}&visual=PORTS";
  
  if ( $FORM{DEL} ) {
	$Equipment->graph_del( $FORM{DEL} );
	require Equipment::Graph;
	if ( $FORM{TOTAL} && $FORM{TOTAL} == 1 ){
    	del_graph_data({ NAS_ID => $FORM{NAS_ID},
    		             PORT   => $FORM{PORT},
    		             TYPE   => $FORM{TYPE}
    		        	});
    }
  }
  
  if ( $FORM{SAVE} && $FORM{ID} && $FORM{NAME} ) {
	$Equipment->graph_change( { ID           => $FORM{ID},
								PARAM        => $FORM{NAME},
								COMMENTS     => $FORM{COMMENTS},
								MEASURE_TYPE => $FORM{TYPE},
							 } );
  } elsif ( !$FORM{ID} && $FORM{NAME} ) {
  	$Equipment->graph_add({ NAS_ID       => $FORM{NAS_ID},
							PORT         => $FORM{PORT},
							COMMENTS     => $FORM{COMMENTS},
							PARAM        => $FORM{NAME},
							MEASURE_TYPE => $FORM{TYPE},
							});
  }
  my $params = $Equipment->graph_list( {
    COLS_NAME    => 1,
    ID			 => $FORM{EDIT} ||  '_SHOW',
    NAS_ID       => $attr->{NAS_ID} || $FORM{NAS_ID},
    PORT         => $attr->{PORT} || $FORM{PORT} || '_SHOW',
    PARAM        => '_SHOW',
    MEASURE_TYPE => '_SHOW',
    COMMENTS     => '_SHOW',
    TOTAL        => 1
  } );
  
  if ( !$FORM{ADD} && !$FORM{EDIT}) {
  	my $size = ($params)? @$params : 0;
  	my $table = $html->table(
    		{
      			width       => '100%',
      			caption		=> "NAS ID: $FORM{NAS_ID}  $lang{PORT}: $FORM{PORT}",
      			MENU		=> "$lang{BACK}:index=$root_index:fees;$lang{ADD}:index=$index$pages_qs&ADD=1:add",
      			title_plain => [ $lang{NAME}, $lang{TYPE}, $lang{COMMENTS} ],
      			ID          => "STATS_EDIT",
      			HAS_FUNCTION_FIELDS => 1
    		}
    	);
  	foreach my $var (@$params) {
  		$table->addrow( $var->{param}, $var->{measure_type},$var->{comments},
    					$html->button('', "index=$index$pages_qs&EDIT=$var->{id}",
      							{
    								ICON  => 'fa fa-pencil-alt text-info',
    								title => $lang{DEL},
      							}
      						).
    					$html->button('', "index=$index$pages_qs&TYPE=$var->{measure_type}&DEL=$var->{id}&TOTAL=$size",
      							{
    								ICON  => 'fa fa-trash text-danger',
    								title => $lang{DEL},
      							}
      						)
    				  );
  	}
  	print $table->show();
  } else {
	my $FIELDS_SEL = $html->form_select(
    'TYPE',
    	{
    	  SELECTED  => ( $FORM{EDIT} )?  $params->[0]->{measure_type}: $FORM{TYPE} ,
	      SEL_ARRAY => ['COUNTER', 'GAUGE', 'DERIVE'],
    	}
    );
	$html->message( 'warning', "NAS ID: $FORM{NAS_ID}  $lang{PORT}: $FORM{PORT} <span class='fa fa-cog fa-spin'> </span> " );
	
	print $html->form_main(
	  	{
        	CONTENT =>  label_w_text({ NAME => $lang{NAME},
        							   TEXT => $html->form_input('NAME', ( $FORM{EDIT} )?  $params->[0]->{param}:'') }).
        				label_w_text({ NAME => $lang{TYPE}, TEXT => $FIELDS_SEL }).
        				label_w_text({ NAME => $lang{COMMENTS},
        							   TEXT => $html->form_input('COMMENTS', ( $FORM{EDIT} )?  $params->[0]->{comments}:'') }).
    					label_w_text({ TEXT =>	$html->form_input( 'SAVE',
    															   ( $FORM{EDIT} )? $lang{CHANGE} : $lang{CREATE},
    															   { TYPE => 'SUBMIT' } ) . "	".
    											$html->button($lang{CANCEL}, "index=$index$pages_qs", {class =>"btn btn-secondary"})
    								  }),
    	    METHOD  => 'GET',
        	#class   => 'form-vertical',
        	HIDDEN  => {
          				'index' => $index,
          				'ID'    => $FORM{EDIT},
          				'NAS_ID'=> $FORM{NAS_ID},
          				'PORT'  => $FORM{PORT}
        				},
      	} );
  }

  return 1;
}

#**********************************************************

=head2 equipment_snmp_vlan_data()

=cut

#**********************************************************
sub equipment_snmp_vlan_data {

  #my ($attr) = @_;
  #my @newarr;
  # $Equipment->{debug}=1;

  my $info = $Equipment->info_list(
    {
      COLS_NAME => 1,
      NAS_ID    => $FORM{NAS_ID},
      SECTION   => 'VLAN',
      RESULT    => '_SHOW'
    }
  );

  if ($info) {
    my $vars = JSON->new->utf8(0)->decode($info->[0]->{result});

    my $table = $html->table(
      {
        width => '100%',
        title => [ 'VID', 'Vlan Name', 'UntaggedPorts', 'EgressPorts' ],
        cols_align => [ 'left', 'left', 'left' ],
        ID         => 'EQUIPMENT_VLAN',
      }
    );
    foreach my $key (sort { $a <=> $b } keys %$vars) {
      $table->addrow("<b>$key</b>", "<b>$vars->{$key}->[0]</b>", join(", ", @{ $vars->{$key}->[1] }), join(", ", @{ $vars->{$key}->[2] }));
    }

    print $table->show();
  }

  return 1;
}

#**********************************************************

=head2 equipment_snmp_port_data()

=cut

#**********************************************************
sub equipment_snmp_port_data {
  my ($attr) = @_;
  my @newarr;

  my $port_index =
  ($attr->{PORT})
  ? get_function_index('equipment_snmp_user_data') . "&UID=$attr->{UID}"
  : get_function_index('equipment_panel_new') . "&visual=PORTS";
  my $stats_index = get_function_index('equipment_stats_edit');

  my $info = $Equipment->info_list(
    {
      COLS_NAME => 1,
      NAS_ID    => $attr->{NAS_ID} || $FORM{NAS_ID},
      NAS_IP    => '_SHOW',
      SECTION   => $attr->{SECT},
      RESULT    => '_SHOW'
    }
  );
  my $tmpl = $Equipment->snmp_tpl_list(
    {
      COLS_NAME => 1,
      MODEL_ID  => $info->[0]->{model_id},
      SECTION   => $attr->{SECT}
    }
  );

  if ($info) {
    if ($FORM{test}) {
      my ($result, $status) = cable_test(
        {
          PORT     => $FORM{test},
          NAS_IP   => $info->[0]->{nas_ip},
          MODEL_ID => $info->[0]->{model_id}
        }
      );
      $html->message('info', "$lang{CABLE_TEST}: $lang{PORT} $FORM{test} <span class='fa fa-cog fa-spin'> </span> $status", "$result");
    }
    if ($tmpl && $info->[0]->{result}) {
      my $tit  = JSON->new->utf8(0)->decode($tmpl->[0]->{parameters});
      my $vars = JSON->new->utf8(0)->decode($info->[0]->{result});

      foreach my $key (@$tit) {
        push @newarr, $key->[1] || $key->[0];
      }

      my $table = $html->table(
        {
          width      => '100%',
          title      => [ '#', @newarr ],
          cols_align => [ 'left', 'left', 'left', 'left' ],
          ID         => 'EQUIPMENT_SNMP_PORTS_DATA',
        }
      );
      my %tmphash;
      foreach my $key (sort { $a <=> $b } keys %$vars) {
        if ($attr->{PORT}) {
          $tmphash{ $attr->{PORT} } = \@{ $vars->{ $attr->{PORT} } };
        }
        else {
          $tmphash{$key} = \@{ $vars->{$key} };
        }
      }
      foreach my $key (sort { $a <=> $b } keys %tmphash) {
        $table->addrow(
          $key,
          @{ $tmphash{$key} },
          $html->button(
            "$lang{CABLE_TEST}: $lang{PORT} $key",
            "index=$port_index&NAS_ID=$attr->{NAS_ID}&test=$key",
            {
              ICON  => 'fa fa-eye',
              title => "$lang{INFO}Port $key"
            }
          )
          . $html->button(
            "$lang{STATS}: $lang{PORT} $key",
            "index=$stats_index&NAS_ID=$attr->{NAS_ID}&PORT=$key",
            {
              ICON  => 'fa fa-pencil-alt',
              title => "$lang{INFO}Port $key"
            }
          )
        );
      }
      print $table->show();
    }

  }
  else {
    print $html->form_main(
      {
        CONTENT => "No Data. Check Your Settings",
        class   => 'navbar-form navbar-centr',
      }
    );
  }

  return 1;
}

#********************************************************

=head2 equipment_panel_new()

=cut

#********************************************************
sub equipment_panel_new {
  my ($attr) = @_;

  $pages_qs .= ($FORM{NAS_ID}) ? "&NAS_ID=$FORM{NAS_ID}" : q{};

  my $traps_index = get_function_index('equipment_traps');
  my $edit_index  = get_function_index('equipment_info');
  $index = get_function_index('equipment_panel_new');
  if (!$FORM{NAS_ID} || $attr->{UID}) {
    my $equip = $Equipment->_list(
      {
        NAS_NAME     => '_SHOW',
        NAS_IP       => $FORM{nas_ip} || '_SHOW',
        NAS_ID       => $attr->{NAS_ID} || '_SHOW',
        COLS_NAME    => 1,
        PAGE_ROWS    => 1000,
        TYPE_NAME    => '_SHOW',
        MODEL_NAME   => '_SHOW',
        ADDRESS_FULL => '_SHOW',
       # %LIST_PARAMS
      }
    );

    my $table = $html->table(
      {
        width => '100%',
        title => [ 'NAS_ID', $lang{NAME}, 'NAS_IP', $lang{TYPE}, $lang{MODEL}, $lang{ADDRESS} ],
        cols_align => [ 'left', 'left' ],
        ID         => 'EQUIPMENT_LIST',
        qs         => $pages_qs,
        HAS_FUNCTION_FIELDS => 1
      }
    );
    foreach my $key (@$equip) {
      $table->addrow(
        $key->{nas_id}, $html->button($key->{nas_name}, "index=$index&NAS_ID=$key->{nas_id}"),
        $key->{nas_ip}, $key->{type_name}, $key->{model_name}, $key->{address_full},
        $html->button($lang{TRAPS}, "index=$traps_index&NAS_IP=$key->{nas_ip}", { ICON => 'fa fa-table', }).
        $html->button($lang{EDIT},  "index=$edit_index&NAS_ID=$key->{nas_id}",  { ICON => 'far fa-pencil-alt-square', })
      );
    }
    print $html->element('div', $table->show(),);
    if (!$attr->{UID}) {
      print '<script>$(function () {
  			var $table = $(\'#EQUIPMENT_LIST_\');
  			var correct = ($table.find(\'tbody\').find(\'tr\').first().find(\'td\').length - $table.find(\'thead th\').length );
  			for (var i = 0; i < correct; i++) {
    		$table.find(\'thead th:last-child\').after(\'<th></th>\');
  			}
    		var dataTable = $table
      			.DataTable({
        			"language": {
          			paginate: {
              			first:    "«",
              			previous: "‹",
              			next:     "›",
              			last:     "»",
          			},
          			"zeroRecords":    "' . $lang{NOT_EXIST} . '",
          			"lengthMenu":     "' . $lang{SHOW} . ' _MENU_",
          			"search":         "' . $lang{SEARCH} . ':",
          			"info":           "' . $lang{SHOWING} . ' _START_ - _END_ ' . $lang{OF} . ' _TOTAL_ ",
          			"infoEmpty":      "' . $lang{SHOWING} . ' 0",
          			"infoFiltered":   "(' . $lang{TOTAL} . ' _MAX_)",
        			},
        			"ordering": false,
        			"lengthMenu": [[25, 50, -1], [25, 50, "' . $lang{ALL} . '"]]
      			});
            var column = dataTable.column("0");
            // Toggle the visibility
            column.visible( ! column.visible() );
    		});</script>';
    }

  }
  else {

    my $tmpl = $Equipment->info_list(
      {
        COLS_NAME => 1,
        NAS_ID    => $FORM{NAS_ID} || $attr->{NAS_ID},
        SECTION   => '_SHOW'
      }
    );
    if ($Equipment->mac_log_list({ NAS_ID => $FORM{NAS_ID} || $attr->{NAS_ID} })) {
      push @$tmpl, ({ section => 'FDB' });
    }
    if ($Equipment->graph_list({ NAS_ID => $FORM{NAS_ID} || $attr->{NAS_ID} })) {
      push @$tmpl, ({ section => 'STATS' });
    }

    if ($tmpl) {

      my $buttons;
      foreach my $key (@$tmpl) {
        $buttons .= $html->li($html->button($key->{section},
											"index=$index&visual=$key->{section}$pages_qs"),
											{ class => (defined($FORM{visual}) && $FORM{visual} eq $key->{section}) ? 'active' : '' }
											);
      }

      if ($buttons) {
        my $nas_select = $html->form_select(
          'NAS_ID',
          {
            SELECTED => $attr->{NAS_ID} || $FORM{NAS_ID},
            SEL_LIST => $Equipment->_list(
              {
                NAS_NAME  => '_SHOW',
                NAS_IP    => '_SHOW',
                COLS_NAME => 1,
                PAGE_ROWS => 10000
              }
            ),
            SEL_KEY        => 'nas_id',
            SEL_VALUE      => 'nas_ip,nas_name',
            NO_ID          => 1,
            MAIN_MENU      => get_function_index('equipment_info'),
            MAIN_MENU_ARGV => "NAS_ID=" . ($FORM{NAS_ID} || '')
          }
        );

        my $nas_select_form = $html->form_main(
          {
            CONTENT => $nas_select . $html->form_input('SHOW', $lang{SHOW}, { TYPE => 'submit' }),
            HIDDEN  => {
              'index'  => $index,
              'visual' => $FORM{visual} || 0,
            },
            NAME  => 'equipment_nas_panel',
            ID    => 'equipment_nas_panel',
            class => 'navbar-form navbar-right',
          }
        );

        my $buttons_list = $html->element('ul', $buttons, { class => 'nav navbar-nav' });

        print $html->element('div', $buttons_list . $nas_select_form, { class => 'navbar navbar-default' });
      }

    }
    else {
      $html->message('info', "No object for NAS: $FORM{NAS_ID}<span class='fa fa-cog fa-spin'> </span>", "Plz,  configure template");
    }

    my $visual = $FORM{visual} || 'INFO';
    if ($visual eq 'INFO') {
      equipment_snmp_data($FORM{NAS_ID});
    }
    elsif ($visual eq 'VLAN') {
      equipment_snmp_vlan_data($FORM{NAS_ID});
    }
    elsif ($visual eq 'PORTS') {
      equipment_snmp_port_data({ NAS_ID => $FORM{NAS_ID}, SECT => 'PORTS' });
    }
    elsif ($visual eq 'FDB') {
      equipment_fdb_data($FORM{NAS_ID});
    }
    elsif ($visual eq 'STATS') {
      equipment_snmp_stats({ NAS_ID => $attr->{NAS_ID} || $FORM{NAS_ID} });
    }

    # Pon ports information
    elsif ($visual eq 'PON') {
      equipment_snmp_port_data({ NAS_ID => $FORM{NAS_ID}, SECT => 'PON' });
    }

    # Pon ports setting
    elsif ($visual eq 'PON_OLT') {
      equipment_snmp_port_data({ NAS_ID => $FORM{NAS_ID}, SECT => 'PON_OLT' });
    }

    # Pon ONU if setting
    elsif ($visual eq 'PON_IF') {
      equipment_snmp_port_data({ NAS_ID => $FORM{NAS_ID}, SECT => 'PON_IF' });
    }

  }

  return 1;
}

#**********************************************************

=head2 equipment_snmp_user_data()

=cut

#**********************************************************
sub equipment_snmp_user_data {

  my $mac = $Internet->user_list({ COLS_NAME => 1, UID => $FORM{UID}, CID => '_SHOW' });

  if ($mac->[0]->{cid}) {
    my $ports = $Equipment->mac_log_list(
      {
        COLS_NAME => 1,
        NAS_ID    => $FORM{NAS_ID} || '_SHOW',
        MAC       => $mac->[0]->{cid},
        PORT      => $FORM{test} || '_SHOW'
      }
    );
    foreach my $port (@$ports) {
      equipment_panel_new({ UID => $FORM{UID}, NAS_ID => $port->{nas_id} });
      equipment_snmp_port_data({ UID => $FORM{UID}, NAS_ID => $port->{nas_id}, PORT => $port->{port} });
      equipment_snmp_stats({ UID => $FORM{UID}, NAS_ID => $port->{nas_id}, PORT => $port->{port} });
    }
  }

  return 1;
}

#**********************************************************

=head2 equipment_snmp_data()

=cut

#**********************************************************
sub equipment_snmp_data {

  #my ($attr) = @_;
  #my @newarr;

  my $equipment = $Equipment->_list(
    {
      COLS_NAME => 1,
      NAS_ID    => $FORM{NAS_ID}
    }
  );

  my $info = $Equipment->info_list(
    {
      COLS_NAME => 1,
      NAS_ID    => $FORM{NAS_ID},
      SECTION   => 'INFO',
      RESULT    => '_SHOW',
      INFOTIME  => '_SHOW'
    }
  );

  my $tmpl = $Equipment->snmp_tpl_list(
    {
      COLS_NAME => 1,
      MODEL_ID  => $equipment->[0]->{id},
      SECTION   => 'INFO'
    }
  );

  if ($tmpl && $info) {
    my $tit  = JSON->new->utf8(0)->decode($tmpl->[0]->{parameters});
    my $vars = JSON->new->utf8(0)->decode($info->[0]->{result});

    my $table = $html->table(
      {
        caption     => "$lang{LAST_UPDATE}: $info->[0]->{info_time}",
        width       => '100%',
        title_plain => [ $lang{PARAMS}, $lang{VALUE} ],
        cols_align  => [ 'left', 'left' ],
        ID          => 'EQUIPMENT_TEST',
      }
    );

    my $edit = $html->button($lang{EDIT}, "index=$index&edit=1", { ICON => 'far fa-pencil-alt-square', });

    my $rows_count = 0;
    foreach my $key (@$tit) {
      $table->addrow($html->b($key->[1] || $key->[0]), $vars->{0}->[$rows_count], $edit);
      $rows_count++;
    }
    print $table->show();
  }

  return 1;
}

#**********************************************************
=head2 cable_test()

=cut
#**********************************************************
sub cable_test {
  my ($attr) = @_;
  my $mod = $Equipment->snmp_tpl_list(
    {
      COLS_NAME  => 1,
      MODEL_ID   => $attr->{MODEL_ID},
      SECTION    => 'CABLE',
      PARAMETERS => '_SHOW'
    }
  );

  my $oids = JSON->new->utf8(0)->decode($mod->[0]->{parameters});
  my @get = split(',', $oids->{get}->[1] || 0);
  my @pair_vals;
  my $snmp_community = "$conf{EQUIPMENT_SNMP_COMMUNITY_RW}\@$attr->{NAS_IP}";
  my @arr = ("OK", "open", "short", "open-short", "crosstalk", "unknown", "count", "no-cable", "other");

  my %colors = (
    0 => [ 'success', 'The pair or cable has no error.' ],
    1 => [ 'primary', 'The cable in the error pair does not have a connection at the specified position.' ],
    2 => [ 'warning', 'The cable in the error pair has a short problem at the specified position.' ],
    3 => [ 'warning', 'The cable in the error pair has a short problem at the specified position.' ],
    4 => [ 'danger',  'The cable in the error pair has a crosstalk problem at the specified position.' ],
    5 => [ 'link',    'Unknown' ],
    6 => [ 'link',    'count' ],
    7 => [ 'link',    'The port does not have any cable connected to the remote partner.' ],
    8 => [ 'default', 'other' ]
  );

  my $test = snmpset($snmp_community, $oids->{set}->[0] . $attr->{PORT}, 'integer', '1');
  sleep(3);
  if ($test != 2) {
    my @arrn;
    foreach my $key (@get) {
      my $pr = ($key != 0) ? "$key.$attr->{PORT}" : $attr->{PORT};
      push @arrn, "$oids->{get}->[0]$pr";
    }
    @pair_vals = snmpget($snmp_community, @arrn);
  }
  my $block;
  my $status;
  if (@get > 1) {
    my $link_status = ($pair_vals[0] == 0) ? "default'> $lang{HANGUPED}" : "success'> $lang{ACTIV}";
    $status = "<span class='label label-large label-$link_status</span>";
    my @pair_butt;
    my $color = 'default';
    foreach my $key (1 .. 4) {
      $color = $colors{ $pair_vals[$key] }[0] || 'default';
      my $detail = $colors{ $pair_vals[$key] }[1] || 'oops';
      push @pair_butt, "<button type='button' data-toggle='tooltip' title='$detail' class='btn btn-$color'>$lang{PAIR} $key <span class='badge'>$pair_vals[$key+4]</span></button>";
    }
    $block = $html->element('list-group', "@pair_butt", { class => 'list-group-item list-group-item-success' });
  }
  else {
    $status = '_';
    $block = $html->element('list-group', "@pair_vals", { class => 'list-group-item list-group-item-success' });
  }

  return ($block, $status);
}

#**********************************************************

=head2 equipment_fdb_data()

=cut

#**********************************************************
sub equipment_fdb_data {

  #my ($attr) = @_;

  if ($FORM{del}) {
    $Equipment->mac_log_del({ ID => $FORM{del} });
    if (!$Equipment->{errno}) {
      $html->message('info', $lang{INFO}, "$lang{DELETED} : $FORM{del}");
    }
    else {
      $html->message('err', "MAC", "$lang{NOT} $lang{DELETED}");
    }
  }

  my $fdb = $Equipment->mac_log_list(
    {
      COLS_NAME => 1,
      NAS_ID    => $FORM{NAS_ID},
      ID        => '_SHOW',
      MAC       => '_SHOW',
      VLAN      => '_SHOW',
      PORT      => '_SHOW',
      DATETIME  => '_SHOW',
      REM_TIME  => '_SHOW',
      SORT      => 'port'
    }
  );

  my $fdb_index = get_function_index('equipment_panel_new');
  my $table     = $html->table(
    {
      width => '100%',
      title => [ $lang{PORT}, 'MAC', 'VID', $lang{LOGIN}, $lang{DATE} . "-" . $lang{ENABLE}, $lang{DATE} . "-" . $lang{DISABLED} ],
      cols_align => [ 'left', 'left' ],
      ID         => 'EQUIPMENT_TEST',
    }
  );
  foreach my $key (@$fdb) {
    my $login = $Internet->list({ COLS_NAME => 1, LOGIN => '_SHOW', CID => $key->{mac} });
    $table->addrow(
      $key->{port},
      $key->{mac},
      $key->{vlan},
      $login ? $html->button($login->[0]->{login}, "index=15&UID=$login->[0]->{uid}") : 'Unknown',
      $key->{datetime},
      $key->{rem_time},
      $html->button(
        '',
        "index=$fdb_index&visual=FDB&NAS_ID=$FORM{NAS_ID}&del=$key->{id}",
        {
          ICON    => 'fa fa-trash text-danger',
          MESSAGE => "$lang{DEL} $key->{mac}"
        }
      )
    );
  }

  print $table->show();

  return 1;
}

#**********************************************************

=head2 equipment_snmp_stats()

=cut

#**********************************************************
sub equipment_snmp_stats {
  my ($attr) = @_;
#  $Equipment->{debug}=1;
 
  my %ind;
  my $stats = $Equipment->get_stats(
    {
		TABLE     => "equipment_counter64_stats",
		COLS_NAME => 1,
        NAS_ID    => $attr->{NAS_ID} || $FORM{NAS_ID},
        IN_ID     => $attr->{PORT} || $FORM{PORT} || '_SHOW',
        NAME      => '_SHOW',
		VALUE     => '_SHOW',
		DATETIME  => '_SHOW',
		TIME      => '_SHOW',
		SORT      => ($FORM{PORT})?'name':'',
		FROM_DATE => $FORM{FROM_DATE} || strftime("%Y-%m-%d %T", localtime(time-21600)),
		TO_DATE   => $FORM{TO_DATE} || strftime("%Y-%m-%d %T", localtime(time))
       }
  );
  return 1 if !$stats;
  foreach my $st ( 1..@$stats-1 ) {
		if ( $stats->[$st]->{id} == $stats->[$st-1]->{id} && $stats->[$st]->{in_id} == $stats->[$st-1]->{in_id}){
			my $period = $stats->[$st]->{time} - $stats->[$st-1]->{time};
			my $diff = $stats->[$st]->{value} - $stats->[$st-1]->{value};
			$ind{$stats->[$st]->{in_id}}{$stats->[$st]->{name}}{$stats->[$st]->{datetime}} = sprintf("%.2f", $diff / $period / 1048576 * 8);
		}
  }

  my $PERIODS_SEL = $html->form_daterangepicker({ NAME =>'FROM/TO', FORM_NAME => 'TIMERANGE', WITH_TIME => 1 });
  my $PORT_SEL = $html->form_select(
    'PORT',
    {
      SELECTED  => $FORM{PORT},
      SEL_ARRAY => \@{ [ sort { $a <=> $b } keys %ind ] },
      NO_ID     => 1
    }
  );

  print $html->form_main(
    {
      CONTENT => "$lang{PERIOD}: $lang{FROM} &nbsp" . $html->form_datetimepicker2('FROM_DATE') .
	  "&nbsp $lang{TO} &nbsp" . $html->form_datetimepicker2('TO_DATE') .
	   "&nbsp $lang{PORT}: " . $PORT_SEL . $html->form_input('SHOW', $lang{SHOW}, { TYPE => 'SUBMIT' }),
      METHOD  => 'GET',
      class   => 'form-inline',
      HIDDEN  => {
        index  => "$index",
        visual => 'STATS',
        NAS_ID => $attr->{NAS_ID} || $FORM{NAS_ID},
      },
    }
  );

  foreach my $in (sort { $a <=> $b } keys %ind) {
	my @data;
	foreach my $vr ( keys %{$ind{$in}}){
		foreach my $val ( sort keys %{$ind{$in}{$vr}}){
			push @data, ({ y => $val, $vr => $ind{$in}{$vr}{$val} });
		}
  	}
  	my @larr = sort keys %{$ind{$in}};
  	print $html->make_charts3({DATA => \@data, XKEYS => \@larr, LABELS => \@larr, GRAPH_ID => $in, UNITS => 'Mb/s', HEADER => "$lang{PORT} $in" });
  }

  return 1;
}

#**********************************************************

=head2 equipment_snmp_json_data()

=cut

#**********************************************************
sub equipment_snmp_json_data {

  #my ($attr) = @_;
  #my @newarr;

  my $equipment = $Equipment->_list(
    {
      COLS_NAME => 1,
      NAS_ID    => $FORM{NAS_ID},
    }
  );

  my $tmpl = $Equipment->snmp_tpl_list(
    {
      COLS_NAME => 1,
      MODEL_ID  => $equipment->[0]->{id},
      SECTION   => 'PORTS'
    }
  );

  my $tit = JSON->new->utf8(0)->decode($tmpl->[0]->{parameters});
  foreach my $key (0 .. @$tit) {

    #push @newarr, $key->[0];
    my $info = $Equipment->info_port(
      {
        COLS_NAME => 1,
        NAS_ID    => $FORM{NAS_ID},
        SECTION   => 'PORTS',
        NUM       => $key,
        NAME      => $tit->[$key]->[0],
        PORT      => 5
      }
    );

    print Dumper $info;
  }
  print Dumper $tit;

  return 1;
}

#**********************************************************

=head2 equipment_obj()

=cut

#**********************************************************
sub equipment_obj {

  my ($attr) = @_;
  #my @newarr;
  SNMP::addMibFiles(glob("../../AXbills/MIBs/private" . '/*'));
 # $Equipment->{debug}=1;
   $pages_qs .= ($FORM{ID}) ? "&ID=$FORM{ID}" : q{};
 
 if (!$FORM{ID}){
 
  my %ohash;
  foreach my $oid (keys(%SNMP::MIB)) {
	if ( $SNMP::MIB{$oid}{'objectID'} =~ /.1.3.6.1.4.1./ ) {
		$ohash{$SNMP::MIB{$oid}{'objectID'}} = $SNMP::MIB{$oid}{'label'};
		foreach my $toid (@{$SNMP::MIB{$oid}{'children'}}) {
			if ( $toid->{'type'} ) {
			#	print $toid->{'label'};
			}
		}
	}
  }
  #print Dumper $SNMP::MIB{'1.3.6.1.2.1.2.1'}{'enums'};

  my $info = $Equipment->obj_values_list({
								         COLS_NAME => 1,
								         PAGE_ROWS => 10000,
								   	  	 OID_ID     => '1',
								         VALUE     => '_SHOW',
									 });
  
  my $oids = $Equipment->oids_list({
								         #COLS_NAME => 1,
								         PAGE_ROWS => 10000,
								   	  	 SECTION   => 'system',
										 LABEL     => '_SHOW',
										 OBJECTID  => '_SHOW',
								         IID       => '_SHOW',
									 });
									 
  my $li = $html->element('li', "<a href='index=$index&visual=ALL$pages_qs'>All</a>");
  $li .= dropdown('Switch', { DMENU => \@$info, IND => 'obj_id', VAL => 'value' });
  my $ul = $html->element('ul', $li, { class => 'nav navbar-nav' });
  my $container = $html->element('div', $ul, { class => 'container-fluid' });
  print $html->element('nav', $container, { class => 'navbar navbar-default' });


  $LIST_PARAMS{VALUES} = $oids;

   result_former({
     INPUT_DATA      => $Equipment,
     FUNCTION        => 'obj_list',
     DEFAULT_FIELDS  => 'IP, NAS_NAME, SYS_NAME, SYS_LOCATION, SYS_UPTIME',
     #FUNCTION_FIELDS => 'equipment_traps:change:trap_id;&pg='.($FORM{pg}||''),
 	 HIDDEN_FIELDS   => 'NAS_ID,ID,SYS_DESCR',
     EXT_TITLES      => {
       ip       => 'IP',
       name     => "$lang{NAME} NAS",
	   sysDescr => $lang{DESCRIBE},
      },
     SKIP_USER_TITLE => 1,
     FILTER_COLS  => {
       ip   => "search_link:equipment_obj:,ID",
       name => "search_link:form_nas:,NAS_ID"
     },
     #SELECT_VALUE    => { sysObjectID => \%ohash
     #				   },
	 TABLE => {
	   caption => " ",
	   qs      => $pages_qs,
       ID      => 'OBJ_LIST',
     },
     MAKE_ROWS => 1,
     TOTAL     => 1
   });

 
 } else {  
   my $buttons = $html->li($html->button('INFO',
										"index=$index&visual=INFO$pages_qs"),
										{ class => (defined($FORM{visual}) && $FORM{visual} eq 'INFO') ? 'active' : '' }
										);
	$buttons .= $html->li($html->button('HOST',
									 		"index=$index&visual=HOST$pages_qs"),
									 		{ class => (defined($FORM{visual}) && $FORM{visual} eq 'HOST') ? 'active' : '' }
									 	);
	$buttons .= $html->li($html->button('BRIDGE',
										"index=$index&visual=BRIDGE$pages_qs"),
										{ class => (defined($FORM{visual}) && $FORM{visual} eq 'BRIDGE') ? 'active' : '' }
										);
=com
   foreach my $key (@$tmpl) {
     $buttons .= $html->li($html->button($key->{section},
										"index=$index&visual=$key->{section}$pages_qs"),
										{ class => (defined($FORM{visual}) && $FORM{visual} eq $key->{section}) ? 'active' : '' }
										);
   }
=cut
   
   if ($buttons) {
     my $obj_select = $html->form_select(
       'ID',
       {
         SELECTED => $attr->{ID} || $FORM{ID},
         SEL_LIST => $Equipment->obj_list(
           {
             IP  => '_SHOW',
             COLS_NAME => 1,
             PAGE_ROWS => 10000
           }
         ),
         SEL_KEY        => 'id',
         SEL_VALUE      => 'ip',
         NO_ID          => 1,
         MAIN_MENU      => get_function_index('equipment_obj'),
         MAIN_MENU_ARGV => "ID=" . ($FORM{ID} || '')
       }
     );

     my $obj_select_form = $html->form_main(
       {
         CONTENT => $obj_select . $html->form_input('SHOW', $lang{SHOW}, { TYPE => 'submit' }),
         HIDDEN  => {
           'index'  => $index,
           'visual' => $FORM{visual} || 0,
         },
         NAME  => 'equipment_obj_panel',
         ID    => 'equipment_obj_panel',
         class => 'navbar-form navbar-right',
       }
     );

     my $buttons_list = $html->element('ul', $buttons, { class => 'nav navbar-nav' });

     print $html->element('div', $buttons_list . $obj_select_form, { class => 'navbar navbar-default' });
   }
   my $visual = $FORM{visual} || 'INFO';
   if ($visual eq 'INFO') {
   	equipment_obj_data($FORM{ID});
   } else {
   	oid_table({ ID => $FORM{ID}, SECT => lc($visual)});
   }
}

  return 1;
}

#**********************************************************

=head2 equipment_obj_data()

=cut

#**********************************************************
sub equipment_obj_data {

  my ($attr) = @_;
  #my @newarr;

  my $info = $Equipment->obj_values_list(
    {
      COLS_NAME => 1,
      OBJ_ID    => $FORM{ID}||$attr->{ID},
      OBJ_IND   => '_SHOW',
      OID_ID    => '_SHOW',
      VALUE     => '_SHOW'
    }
  );
  my $oids = $Equipment->oids_list(
    {
      LABEL     => '_SHOW',
	  LIST2HASH => 'id,label'
    }
  );

    my $table = $html->table(
      {
        #caption     => "$lang{LAST_UPDATE}: $info->[0]->{info_time}",
        width       => '100%',
        title_plain => [ $lang{PARAMS}, $lang{VALUE} ],
        cols_align  => [ 'left', 'left' ],
        ID          => 'EQUIPMENT_TEST',
      }
    );

    my $edit = $html->button($lang{EDIT}, "index=$index&edit=1", { ICON => 'far fa-pencil-alt-square', });

    foreach my $key (@$info) {
       $edit = $html->button( $lang{CHANGE}, "index=$index$pages_qs&OID=$oids->{$key->{oid_id}}",
            { MESSAGE => "$lang{CHANGE} $oids->{$key->{oid_id}}",
              TEXT    => $lang{CHANGE},
              class   => 'change'
            });
	  $table->addrow($html->b($oids->{$key->{oid_id}}), $key->{value}, ($SNMP::MIB{$oids->{$key->{oid_id}}}{'access'} eq 'ReadWrite')? $edit :'');
    }
    print $table->show();


  return 1;
}

#**********************************************************

=head2 oid_table()

=cut

#**********************************************************
sub oid_table {

  my ($attr) = @_;
  SNMP::loadModules('BRIDGE-MIB', 'Q-BRIDGE-MIB');

  #$Equipment->{debug}=1;

  my $info = $Equipment->obj_list(
    {
      COLS_NAME => 1,
      ID    => $FORM{ID}||$attr->{ID},
      IP   => '_SHOW',
    }
  );

  my $tbl = $Equipment->oids_list(
    {
      COLS_NAME => 1,
	  SECTION   => $FORM{SECT}||$attr->{SECT},
      TYPE      => 'table',
      LABEL     => '_SHOW',
    }
  );
 
  my $sess = new SNMP::Session(DestHost => $info->[0]->{ip},%snmpparms);

  my @li;
  my @panel;

  foreach my $t (@$tbl) {
	  my $rows = $Equipment->oids_rows_list({ OID_ID => $t->{id} });
	  my @vars;
	  foreach my $row (@$rows) {
		  push @vars, $row->[1]
	  }

	  my $results = $sess->gettable( $t->{label}, columns => [ @vars ]);
	#my @columns = @{$bridge{$key}};
	#for (@columns) {
	#   s/dot1q|dot1d//g;
    #} 
	my $table = $html->table(
      {
        title_plain => [ @vars ],
        ID          => "_".$t->{label},
      }
    );

    foreach my $var (sort { $a <=> $b } keys %$results) {
		my @row = ();
		foreach my $ind (@vars){
			if ( $SNMP::MIB{$ind}{'syntax'} eq 'PortList'){
				my $index = unpack( "B64", $results->{$var}->{$ind});
		        $results->{$var}->{$ind} = '';
				my $offset = 0;
		        my $result = index($index, 1, $offset);
		        while ($result != - 1) {
		          $result = index($index, 1, $offset);
		          $offset = $result + 1;
		          $results->{$var}->{$ind} .= "$offset " if ( $offset > 0 );
		        }
			}
			push @row,  $results->{$var}->{$ind};
		}
		$table->addrow(@row);
    }
	my $active = ( @panel < 1 )?'in active':'';
	push @li, $html->element('li', "<a data-toggle='tab' href='#" . $t->{label} . "'>" . $t->{label} . "</a>", { class => ( @li < 1 )?'active':'' });
	push @panel, $html->element('div', nms_snmp_table({ OID => $t->{label}, columns => [ @vars ], IP => $info->[0]->{ip} }),
									{ id => $t->{label}, class => "tab-pane fade" . (( @panel < 1 )?'in active':'') });
  
  }

  	my $edit = $html->button($lang{EDIT}, "index=$index&edit=1", { ICON => 'far fa-pencil-alt-square', });

	my $ul = $html->element('ul', "@li", { class => 'nav nav-tabs' });
	my $tab = $html->element('div', "@panel", { class => 'tab-content' });
	
    print $ul . $tab;


  return 1;
}

#**********************************************************
=head2 dropdown($attr); - return formated text with label
      
  Returns:
    String with element

=cut
#**********************************************************
sub dropdown {
	my ($name, $attr) = @_;
	my $IND = uc($attr->{IND});
	my @LI;
    foreach my $line ( @{$attr->{DMENU}} ) {
		my $link = qq(<a href='?index=$index&$IND=$line->{$attr->{IND}}'>$line->{$attr->{VAL}}</a>);
       	push @LI, $html->li($link);
     }

	my $ul = $html->element('ul', "@LI", { class => 'dropdown-menu' });
	my $a = qq(<a class="dropdown-toggle" data-toggle="dropdown" href="#">$name <span class="caret"></span></a>);
	my $drop_li = $html->element('li', $a.$ul, { class => 'dropdown' });
	
	return $drop_li;

}

#**********************************************************

=head2 oid_table_edit()

=cut

#**********************************************************
sub oid_table_edit {

  my ($attr) = @_;
  SNMP::loadModules('HOST-RESOURCES-MIB');
  if ( $FORM{del} ) {
  	$Equipment->oid_del($FORM{del});
  }
  if ( $FORM{GET} ) {
  	return nms_snmp_get({ IP => $FORM{GET}, OID => $FORM{OID}});
  } 
  if ( $FORM{add} ) {
	  mibs_browser();

  } elsif ( $FORM{ID} ) {
	  print "ADD";
  } else {
	  result_former({
	    INPUT_DATA      => $Equipment,
	    FUNCTION        => 'oids_list',
	    DEFAULT_FIELDS  => 'SECTION,LABEL,IID,TYPE,ACCESS',
	    FUNCTION_FIELDS => 'oid_table_edit:change:id;type,del',
		HIDDEN_FIELDS   => 'ID',
	    EXT_TITLES      => {
	      ip       => 'IP',
	      name     => "$lang{NAME} NAS",
	     },
	    SKIP_USER_TITLE => 1,
	    FILTER_COLS  => {
	   #   ip   => "search_link:equipment_obj:,ID",
	   #   name => "search_link:form_nas:,NAS_ID"
	    },
	    #SELECT_VALUE    => { sysObjectID => \%ohash
	    #				   },
	 	TABLE           => {
	   		qs   => $pages_qs,
	    	ID   => 'OID_LIST',
			MENU => "$lang{ADD}:index=$index$pages_qs&add=1:add",
	    },
	    MAKE_ROWS => 1,
	    TOTAL     => 1
	  });
  }
  
  return 1;
}

#**********************************************************

=head2 nms_snmp_get()

=cut

#**********************************************************
sub nms_snmp_get {

  my ($attr) = @_;
  $snmpparms{UseSprintValue} = 1;
  $snmpparms{Community} = $attr->{COMMUNITY} || $conf{EQUIPMENT_SNMP_COMMUNITY_RO};
  my $ip = $FORM{IP} || $attr->{IP};
  my $oid = $FORM{OID} || $attr->{OID};
  my $iid = $FORM{IID} || $attr->{IID} || 0;
  my $sess = new SNMP::Session(DestHost => $ip, %snmpparms);
  my $result = $sess->get([ $oid, $iid ]);
  if ( $sess->{ErrorNum} ) {
    return $html->message('err', $lang{ERROR}, $sess->{ErrStr});
  }
  my $result_tbl = $html->table({});
  my $set_button = '';
  if ( $SNMP::MIB{$oid}{access} eq 'ReadWrite'){
	  $set_button = $html->element( 'span', undef,
      							{
									ex_params  => qq/onclick=renewLeftBox($oid,'SET',$iid)/,
    								class  => 'fa fa-pencil-alt text-info',
      							}
      						);
  }
  
  $result_tbl->addrow($html->b($lang{RESULT}), $result, $set_button);
 
  return $result_tbl->show();
}

#**********************************************************

=head2 nms_snmp_walk()

=cut

#**********************************************************
sub nms_snmp_walk {

  my ($attr) = @_;
  $snmpparms{UseSprintValue} = 1;
  $snmpparms{Community} = $attr->{COMMUNITY} || $conf{EQUIPMENT_SNMP_COMMUNITY_RO};
  my $sess = new SNMP::Session(DestHost => $FORM{IP} || $attr->{IP}, %snmpparms);
  my @result = $sess->bulkwalk(0, 1,[ $FORM{OID} || $attr->{OID} ]);
  if ( $sess->{ErrorNum} ) {
    return $html->message('err', $lang{ERROR}, $sess->{ErrStr});
  }
  my $result_tbl = $html->table({});
  foreach my $val (@{$result[0]}) {
	  $result_tbl->addrow(@$val)
  }
 
  return $result_tbl->show();
}

#**********************************************************

=head2 nms_snmp_set()

=cut

#**********************************************************
sub nms_snmp_set {

  my ($attr) = @_;
  $snmpparms{UseSprintValue} = 1;
  $snmpparms{Community} = $attr->{COMMUNITY} || $conf{EQUIPMENT_SNMP_COMMUNITY_RW};
  my $sess = new SNMP::Session(DestHost => $FORM{IP} || $attr->{IP}, %snmpparms);
  my $result = $sess->set([ $FORM{OID} || $attr->{OID}, $FORM{IID} || $attr->{IID} || 0 ]);
  if ( $sess->{ErrorNum} ) {
    return $html->message('err', $lang{ERROR}, $sess->{ErrStr});
  }
  my $result_tbl = $html->table({});
  $result_tbl->addrow($html->b($lang{RESULT}), $result);
  #print $result_tbl->show();
  print $attr->{OID};
 
  return 1;
}

#**********************************************************

=head2 nms_snmp_table()

=cut

#**********************************************************
sub nms_snmp_table {

  my ($attr) = @_;
  
  $snmpparms{Community} = $attr->{COMMUNITY} || $conf{EQUIPMENT_SNMP_COMMUNITY_RO};
  my $sess = new SNMP::Session(DestHost => $attr->{IP},%snmpparms);
  SNMP::loadModules('BRIDGE-MIB', 'Q-BRIDGE-MIB');

  if (!$attr->{columns}){
	    foreach my $c (sort { $b cmp $a } @{$SNMP::MIB{$attr->{OID}}{'children'}[0]{'children'}}) {
			push @{$attr->{columns}}, $c->{'label'};
	    }
  }

  my $results = $sess->gettable( $attr->{OID}, , columns => [@{$attr->{columns}}] );
  if ( $sess->{ErrorNum} ) {
	return $html->message('err', $lang{ERROR}, $sess->{ErrStr});
  }
 
  my $table = $html->table(
      {
        title_plain => [ @{$attr->{columns}} ],
      }
    );

    foreach my $var (sort { $a <=> $b } keys %$results) {
		my @row = ();
		foreach my $ind (@{$attr->{columns}}){
			if ( $SNMP::MIB{$ind}{'syntax'} eq 'PortList'){
				my $index = unpack( "B64", $results->{$var}->{$ind});
		        $results->{$var}->{$ind} = '';
				my $offset = 0;
		        my $result = index($index, 1, $offset);
		        while ($result != - 1) {
		          $result = index($index, 1, $offset);
		          $offset = $result + 1;
		          $results->{$var}->{$ind} .= "$offset " if ( $offset > 0 );
		        }
			}
			push @row,  $results->{$var}->{$ind};
		}
		$table->addrow(@row);
    }


  return $table->show();
}

#**********************************************************

=head2 mibs_browser()

=cut

#**********************************************************
sub mibs_browser {

  my ($attr) = @_;
#$Equipment->{debug}=1;
  $pages_qs = ($attr->{KEY}) ? "&$attr->{KEY}=1" : q{};
  SNMP::initMib();
  SNMP::addMibDirs("../../AXbills/MIBs/private");
 # SNMP::addMibFiles(glob("../../AXbills/MIBs/private" . '/*'));
  if ($FORM{OID}){
	  my $table = $html->table({});
	  $table->addrow($html->b($lang{NAME}), $SNMP::MIB{$FORM{OID}}{label});
	  $table->addrow($html->b('objectID'), $SNMP::MIB{$FORM{OID}}{objectID});
	  $table->addrow($html->b($lang{TYPE}), $SNMP::MIB{$FORM{OID}}{type}) if $SNMP::MIB{$FORM{OID}}{type};
	  $table->addrow($html->b('Module'), $SNMP::MIB{$FORM{OID}}{moduleID});
	  $table->addrow($html->b($lang{ACCESS}), $SNMP::MIB{$FORM{OID}}{access});
	  $table->addrow($html->b('Syntax'), $SNMP::MIB{$FORM{OID}}{syntax}) if $SNMP::MIB{$FORM{OID}}{syntax};
  	  $table->addrow($html->b($lang{RANGE}), "$SNMP::MIB{$FORM{OID}}{ranges}[0]{low} .. $SNMP::MIB{$FORM{OID}}{ranges}[0]{high}") 
  	  	if $SNMP::MIB{$FORM{OID}}{ranges}[0];
	  $table->addrow($html->b($lang{DESCRIBE}), $SNMP::MIB{$FORM{OID}}{TCDescription}) if $SNMP::MIB{$FORM{OID}}{TCDescription};
	  $table->addrow($html->b('Reference'), $SNMP::MIB{$FORM{OID}}{reference}) if $SNMP::MIB{$FORM{OID}}{reference};
	  print $table->show();
	  if ($FORM{GET}){
	  	print nms_snmp_get({ IP => $FORM{GET}, OID => $FORM{OID}});
	  } elsif ($FORM{WALK}){
	  	print nms_snmp_walk({ IP => $FORM{WALK}, OID => $FORM{OID}});
	  } elsif ($FORM{TABLE}){
	  	print nms_snmp_table({ IP => $FORM{TABLE}, OID => $FORM{OID}});
	  } elsif ($FORM{SET}){
	  	nms_snmp_set({ IP => $FORM{SET}, OID => $FORM{OID}});
	  }
	  return 1
  }
  if (!$FORM{IP}){
	  my $obj_select = $html->form_select(
	    'IP',
	    {
	      SELECTED => $FORM{IP},
	      SEL_LIST => $Equipment->obj_list(
	        {
	          IP  => '_SHOW',
			  SYS_LOCATION => '_SHOW',
	          COLS_NAME => 1,
			  SORT      => 1,
	          PAGE_ROWS => 10000,
			  VALUES    =>  [[ 'sysLocation', '.1.3.6.1.2.1.1.6', '0', '4' ]],
	        }
	      ),
	      SEL_KEY        => 'ip',
		  SEL_VALUE      => 'ip,sysLocation',
	      NO_ID          => 1,
	      MAIN_MENU_ARGV => "IP=" . ($FORM{IP} || '')
	     }
	  );

	  print $html->element('div', $obj_select, { class => 'navbar navbar-default' });
  }
  my @tree_arr;
  foreach my $oid (keys(%SNMP::MIB)) {
	if ( $SNMP::MIB{$oid}{objectID} =~ /.1.3.6.1./ ) {
		my $prev_id = ( split(/\./,$SNMP::MIB{$oid}{objectID}) == 7 )? '0' : $SNMP::MIB{$oid}{parent}{objectID};
		my $name = $SNMP::MIB{$oid}{label};
		if ( $SNMP::MIB{$oid}{children}[0]{indexes}[0] || $SNMP::MIB{$oid}{indexes}[0]){
			$name = "<p oid='$SNMP::MIB{$oid}{objectID}' class='tree-item-table'>$SNMP::MIB{$oid}{label}</p>";
		} elsif ( $SNMP::MIB{$oid}{parent}{indexes}[0]){
			$name = "<p oid='$SNMP::MIB{$oid}{objectID}' class='tree-item-row'>$SNMP::MIB{$oid}{label}</p>";
		} elsif ( $SNMP::MIB{$oid}{syntax}){
			$name = "<p oid='$SNMP::MIB{$oid}{objectID}' class='tree-item-item'>$SNMP::MIB{$oid}{label}</p>";
		}
		push @tree_arr, ({ ID => $SNMP::MIB{$oid}{objectID},
		                   #NAME => $SNMP::MIB{$oid}{label},
						   NAME => $name,
						   VALUE => $SNMP::MIB{$oid}{objectID},
						   PARENT_ID => $prev_id
					   });
	}
  }

  my $IP = ($FORM{IP})? $FORM{IP} : 0 ;
  my $scr = qq(
  			<link rel='stylesheet' href='/styles/default/css/modules/cablecat/jquery.contextMenu.min.css'>
  			<script src='/styles/default/js/modules/cablecat/jquery.contextMenu.min.js'></script>
			<script>
				\$(function(){
					\$.contextMenu({
					        selector: '.tree-item-row', 
					        autoHide: true,
							build: function(\$trigger, e) {
  							  var oid = \$trigger.attr('oid');
								return {
					                callback: function(key, options) {
					                    //var m = "clicked: " + oid + key;
										renewLeftBox(oid,key);
					                },
					                items: {
					                    WALK: {name: "Walk", icon: "fa-list"}
					                }
					            };
					        }
					    });
					\$.contextMenu({
					        selector: '.tree-item-table', 
					        autoHide: true,
							build: function(\$trigger, e) {
  							  var oid = \$trigger.attr('oid');
								return {
					                callback: function(key, options) {
					                    //var m = "clicked: " + oid + key;
										renewLeftBox(oid,key);
					                },
					                items: {
					                    WALK: {name: "Walk", icon: "fa-list"},
					                    TABLE: {name: "Table View", icon: "fa-th-list"},
					                }
					            };
					        }
					    });
				});
			    function renewLeftBox(itemName,Action,iid){
					var ip = '$IP';
					iid = iid ? iid : 0 ;
					if ( ip == 0 ){
						ip = \$('.chosen-single').text();
						ip = ip.substring(0, ip.indexOf(' :'));
					}
					var url = 'index.cgi?qindex=$index&header=2&' + Action + '=' + ip + '&OID=' + itemName + '&IID=' + iid;
			  		\$('#RESULT').load(url);
			    };
				\$('.tree-menu').find('.tree-item-item').on('click', function(){ renewLeftBox(this.innerText,'GET') })
				\$('.tree-menu').find('.tree-item-row').on('click', function(){ renewLeftBox(this.innerText) })
				\$('.tree-menu').find('.tree-toggler').on('click', function(){ renewLeftBox(this.innerText) })
			</script>); 

  my $tree = $html->element('div', $html->tree_menu( \@tree_arr, 'OIDS',{OUTPUT2RETURN=>1}),
  							{ 
								class => 'col-md-4 text-right',
								style => 'overflow-y: scroll;height:75vh;outline: 1px solid silver'
							});
  my $res = $html->element('div', '',
  							{ 
								id => 'RESULT',
								class => 'col-md-8 text-left',
								style => 'overflow-y: scroll;height:75vh;outline: 1px solid silver'
							});
  my $brows = $html->element('div', $tree.$res );

  print $brows.$scr;
  return 1;
}

1;