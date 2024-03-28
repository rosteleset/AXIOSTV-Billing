=head1 NAME

 IPTV Configure

=cut

use strict;
use warnings FATAL => 'all';

our(
  $Iptv,
  %lang,
  $db,
  %conf,
  $admin,
  %permissions,
  @WEEKDAYS,
);

our Conf $Conf;
our AXbills::HTML $html;
my $Tariffs = Tariffs->new( $db, \%conf, $admin );

require Control::System;

#**********************************************************
=head2 iptv_tp() - Tarif plans

=cut
#**********************************************************
sub iptv_tp{
  my $tarif_info;

  require Control::Services;

  my %payment_types = (
    0 => $lang{PREPAID},
    1 => $lang{POSTPAID}
  );

  my %bool_hash = (
    0 => $lang{NO},
    1 => $lang{YES}
  );

  $tarif_info = $Tariffs->defaults();
  $tarif_info->{LNG_ACTION} = $lang{ADD};
  $tarif_info->{ACTION} = 'ADD_TP';

  if ( $FORM{ADD_TP} ){
    if ($FORM{create_fees_type}) {
      my $Fees = Finance->fees($db, $admin, \%conf);
      $Fees->fees_type_add({ NAME => $FORM{NAME}});
      $FORM{FEES_METHOD} = $Fees->{INSERT_ID};
    }
    $FORM{ID} = $FORM{CHG_TP_ID};
    $Tariffs->add( { %FORM, MODULE => 'Iptv' } );
    if ( !$Tariffs->{errno} ){
      $html->message( 'info', $lang{ADDED}, "$lang{ADDED} $Tariffs->{TP_ID}" );
    }
  }
  elsif ( defined( $FORM{TP_ID} ) ){
    $tarif_info = $Tariffs->info( $FORM{TP_ID} );
    if ( _error_show( $Tariffs ) ){
      return 0;
    }

    $pages_qs .= "&TP_ID=" . ($FORM{TP_ID} ? $FORM{TP_ID} : q{});
    $pages_qs .= "&subf="  . ($FORM{subf}  ? $FORM{subf}  : q{});
    $LIST_PARAMS{TP} = $FORM{TP_ID};
    my %F_ARGS = (TP => $Tariffs);
    $index = get_function_index( 'iptv_tp' );

    $Tariffs->{NAME_SEL} = $html->form_main({
      CONTENT => $html->form_select('TP_ID', {
        SELECTED  => $FORM{TP_ID},
        SEL_LIST  => $Tariffs->list({ %LIST_PARAMS, NEW_MODEL_TP => 1, MODULE => 'Iptv', COLS_NAME => 1 }),
        SEL_KEY   => 'tp_id',
        SEL_VALUE => 'name',
      }),
      HIDDEN  => { index => $index },
      # SUBMIT  => { show => $lang{SHOW} },
      class   => 'ml-auto',
    });

    func_menu({ $lang{NAME} => $Tariffs->{NAME_SEL} },
      [
        $lang{INFO} . "::TP_ID=$FORM{TP_ID}",
        $lang{INTERVALS} . ':' . get_function_index( 'iptv_intervals' ) . ":TP_ID=$FORM{TP_ID}",
        $lang{NAS} . ':' . get_function_index( 'form_nas_allow' ) . ":TP_ID=$FORM{TP_ID}",
        $lang{USERS} . ':' . get_function_index( 'iptv_users_list' ) . ":TP_ID=$FORM{TP_ID}",
        $lang{SCREENS} . ':' . get_function_index( 'iptv_screens' ) . ":TP_ID=$FORM{TP_ID}",
      ],
      { f_args => { %F_ARGS } }
    );

    return 0 if ($FORM{subf});

    if ( $FORM{change} ){
      if ($FORM{create_fees_type}) {
        my $Fees = Finance->fees($db, $admin, \%conf);
        $Fees->fees_type_add({ NAME => $FORM{NAME}});
        $FORM{FEES_METHOD} = $Fees->{INSERT_ID};
      }

      $FORM{ID} = $FORM{CHG_TP_ID};
      $Tariffs->change( $FORM{TP_ID}, { %FORM, MODULE => 'Iptv' } );
      if ( !$Tariffs->{errno} ){
        $html->message( 'info', $lang{CHANGED}, "$lang{CHANGED} $Tariffs->{TP_ID}" );
      }
    }
    $tarif_info->{LNG_ACTION} = $lang{CHANGE};
    $tarif_info->{ACTION} = 'change';
    $FORM{add_form} = 1;
  }
  elsif ( defined( $FORM{del} ) && $FORM{COMMENTS} ){
    $Tariffs->del( $FORM{del} );
    if ( !$Tariffs->{errno} ){
      $html->message( 'info', $lang{DELETE}, "$lang{DELETED} $FORM{del}" );
    }
  }

  _error_show( $Tariffs );

  if ($FORM{add_form}) {

    $tarif_info->{PAYMENT_TYPE_SEL} = $html->form_select('PAYMENT_TYPE', {
      SELECTED => $tarif_info->{PAYMENT_TYPE},
      SEL_HASH => \%payment_types,
    });

    $tarif_info->{GROUPS_SEL} = $html->form_select('TP_GID', {
      SELECTED       => $tarif_info->{TP_GID} || '',
      SEL_LIST       => $Tariffs->tp_group_list({ COLS_NAME => 1 }),
      SEL_OPTIONS    => { '' => '--' },
      MAIN_MENU      => get_function_index('form_tp_groups'),
      MAIN_MENU_ARGV => "chg=". ($tarif_info->{TP_GID} || q{})
    });

    $tarif_info->{SEL_METHOD} = $html->form_select('FEES_METHOD', {
      SELECTED       => $tarif_info->{FEES_METHOD} || 1,
      SEL_HASH       => get_fees_types(),
      NO_ID          => 1,
      SORT_KEY       => 1,
      SEL_OPTIONS    => { 0 => '' },
      MAIN_MENU      => get_function_index('form_fees_types'),
      CHECKBOX       => 'create_fees_type',
      CHECKBOX_TITLE => $lang{CREATE}
    });

    if ($conf{EXT_BILL_ACCOUNT}) {
      my $checked = ($tarif_info->{EXT_BILL_ACCOUNT}) ? ' checked' : '';
      $tarif_info->{EXT_BILL_ACCOUNT} = $html->tpl_show(templates('form_row'), {
        ID    => 'EXT_BILL_ACCOUNT',
        NAME  => $lang{EXTRA_BILL},
        VALUE => "<div class='form-check text-left'>" .
          "<input type='checkbox' id='EXT_BILL_ACCOUNT' name='EXT_BILL_ACCOUNT' value='1' class='form-check-input' $checked></div>",
      }, { OUTPUT2RETURN => 1 });

      $tarif_info->{EXT_BILL_FEES_METHOD} = $html->form_select('EXT_BILL_FEES_METHOD', {
        SELECTED    => $tarif_info->{EXT_BILL_FEES_METHOD} || 1,
        SEL_HASH    => get_fees_types(),
        NO_ID       => 1,
        SORT_KEY    => 1,
        SEL_OPTIONS => { 0 => '' },
        MAIN_MENU   => get_function_index('form_fees_types'),
        # CHECKBOX    => 'create_fees_type',
        # CHECKBOX_TITLE => $lang{CREATE},
      });

      $tarif_info->{EXT_BILL_ACCOUNT} .= $html->tpl_show(templates('form_row'), {
        ID    => 'EXT_BILL_ACCOUNT',
        NAME  => "$lang{EXTRA_BILL} $lang{FEES} $lang{TYPE}",
        VALUE => $tarif_info->{EXT_BILL_FEES_METHOD},
      }, { OUTPUT2RETURN => 1 });

      if ($conf{BONUS_EXT_FUNCTIONS}) {
        my @BILL_ACCOUNT_PRIORITY = (
          "$lang{PRIMARY} $lang{BILL_ACCOUNT}",
          "$lang{EXT_BILL_ACCOUNT}, $lang{PRIMARY} $lang{BILL_ACCOUNT}",
          "$lang{EXT_BILL_ACCOUNT}"
        );

        $tarif_info->{BILLS_PRIORITY_SEL} = $html->form_select('BILLS_PRIORITY', {
          SELECTED     => $tarif_info->{BILLS_PRIORITY},
          SEL_ARRAY    => \@BILL_ACCOUNT_PRIORITY,
          ARRAY_NUM_ID => 1
        });

        $tarif_info->{BONUS} = $html->tpl_show(_include('bonus_tp_row', 'Bonus'), $tarif_info, { OUTPUT2RETURN => 1 });
      }
    }

    $tarif_info->{REDUCTION_FEE} = ($tarif_info->{REDUCTION_FEE}) ? 'checked' : '';
    $tarif_info->{POSTPAID_FEE} = ($tarif_info->{POSTPAID_FEE}) ? 'checked' : '';
    $tarif_info->{PERIOD_ALIGNMENT} = ($tarif_info->{PERIOD_ALIGNMENT}) ? 'checked' : '';
    $tarif_info->{POSTPAID_DAY_FEE} = ($tarif_info->{POSTPAID_DAY_FEE}) ? 'checked' : '';
    $tarif_info->{POSTPAID_MONTH_FEE} = ($tarif_info->{POSTPAID_MONTH_FEE}) ? 'checked' : '';
    $tarif_info->{ABON_DISTRIBUTION} = ($tarif_info->{ABON_DISTRIBUTION}) ? 'checked' : '';
    $tarif_info->{PROMOTIONAL} = ($tarif_info->{PROMOTIONAL}) ? 'checked' : '';

    $tarif_info->{SMALL_DEPOSIT_ACTION_SEL} = sel_tp({
      SELECT          => 'SMALL_DEPOSIT_ACTION',
      SMALL_DEPOSIT_ACTION => $tarif_info->{SMALL_DEPOSIT_ACTION} || 0,
      SKIP_TP         => $tarif_info->{TP_ID},
      SEL_OPTIONS     => { 0 => '--', '-1' => $lang{HOLD_UP} },
      MODULE          => 'Iptv'
    });

    $tarif_info->{NEXT_TARIF_PLAN_SEL} = sel_tp({
      SELECT          => 'NEXT_TARIF_PLAN',
      NEXT_TARIF_PLAN => $tarif_info->{NEXT_TARIF_PLAN},
      #SKIP_TP         => $tarif_info->{TP_ID},
      MODULE          => 'Iptv'
    });

    $tarif_info->{SERVICE_SEL} = tv_services_sel({ %$tarif_info, ALL => 1, EX_PARAMS => '' });

    $tarif_info->{STATUS} = "checked" if $tarif_info->{STATUS};

    $html->tpl_show(_include('iptv_tp', 'Iptv'), { %FORM, %{$tarif_info} });
  }

  my $service_name = tv_services_sel({ ALL => 1, HASH_RESULT => 1 });

  $LIST_PARAMS{NEW_MODEL_TP} = 1;
  $LIST_PARAMS{MODULE} = 'Iptv';
  my AXbills::HTML $table;
  my $list;

  ($table, $list) = result_former({
    INPUT_DATA      => $Tariffs,
    FUNCTION        => 'list',
    BASE_FIELDS     => 2,
    DEFAULT_FIELDS  => 'ID,NAME,PAYMENT_TYPE,DAY_FEE,MONTH_FEE',
    FUNCTION_FIELDS => 'intervals,change,del',
    SELECT_VALUE     => { service_name => $service_name },
    EXT_TITLES      => {
      name                 => $lang{NAME},
      time_tarifs          => $lang{HOUR_TARIF},
      traf_tarifs          => $lang{TRAFIC_TARIFS},
      name                 => $lang{NAME},
      tp_gid               => $lang{GROUP},
      uplimit              => $lang{UPLIMIT},
      day_fee              => $lang{DAY_FEE},
      month_fee            => $lang{MONTH_FEE},
      abon_distribution    => $lang{ABON_DISTRIBUTION},
      small_deposit_action => $lang{SMALL_DEPOSIT_ACTION},
      activ_price          => $lang{ACTIVATE},
      change_price         => $lang{CHANGE},
      credit               => $lang{CREDIT},
      filter_id            => $lang{FILTERS},
      age                  => "$lang{AGE} ($lang{DAYS})",
      payment_type         => $lang{PAYMENT_TYPE},
      priority             => $lang{PRIORITY},
      next_tarif_plan      => "$lang{TARIF_PLAN} $lang{NEXT_PERIOD}",
      comments             => $lang{DESCRIBE},
      service_id           => "SERVICE_ID",
      service_name         => $lang{SERVICE},
      module               => $lang{MODULE},
      inner_tp_id          => 'ID',
      ext_bill_fees_method => "EXT_BILL $lang{FEES} $lang{TYPE}",
      describe_aid         => $lang{DESCRIBE_FOR_ADMIN},
      comments             => $lang{DESCRIBE_FOR_SUBSCRIBER}
    },
    SKIP_USER_TITLE => 1,
    TABLE           => {
      width   => '100%',
      caption => $lang{TARIF_PLAN},
      qs      => $pages_qs,
      ID      => 'IPTV_TARIF_PLANS',
      MENU    => $permissions{4}{1} ? "$lang{ADD}:index=$index&add_form=1:add" : '',
      EXPORT  => 1,
    },
    MODULE          => 'Iptv',
  });

  foreach my $line ( @{$list} ){
    my $delete = $permissions{4}{3} ? $html->button($lang{DEL}, "index=$index&del=$line->{tp_id}",
      { MESSAGE => "$lang{DEL} $line->{id} $line->{name}?", class => 'del' }) : '';
    my $change = $permissions{4}{2} ? $html->button($lang{CHANGE}, "index=$index&TP_ID=$line->{tp_id}", { class => 'change' }) : '';

    if ( $FORM{TP_ID} && $FORM{TP_ID} eq $line->{tp_id} ){
      $table->{rowcolor} = 'success';
    }
    else{
      undef($table->{rowcolor});
    }
    my @fields_array = ();
    for ( my $i = 0; $i < 2 + $Tariffs->{SEARCH_FIELDS_COUNT}; $i++ ){
      my $col_name = $Tariffs->{COL_NAMES_ARR}->[$i];
      if ( $col_name =~ /time_tarifs|traf_tarifs|abon_distribution|period_alignment|fixed_fees_day/ ){
        $line->{ $col_name } = $bool_hash{ $line->{ $col_name } };
      }
      elsif ( $col_name =~ /small_deposit_action/ ){
        $line->{ $col_name } = ($line->{ $col_name } == -1) ? $lang{HOLD_UP} : $payment_types{ $line->{ $col_name } };
      }
      elsif ( $col_name =~ /service_name/ ){
        $line->{ $col_name } = $service_name->{ $line->{ $col_name } };
      }
      elsif ( $col_name =~ /payment_type/ ){
        $line->{ $col_name } = $payment_types{ $line->{ $col_name } };
      }

      push @fields_array, $line->{ $col_name };
    }
    $table->addrow( @fields_array,
      $html->button( $lang{INTERVALS}, "index=" . get_function_index( 'iptv_intervals' ) . "&TP_ID=$line->{tp_id}",
        { class => 'interval', ICON=>"fa fa-align-left" } ).' '. $change .' '. $delete );
  }

  print $table->show();

  $table = $html->table({ width => '100%', rows => [ [ "$lang{TOTAL}:", $html->b($Tariffs->{TOTAL}) ] ] });

  print $table->show();

  return 1;
}

#**********************************************************
=head2 iptv_intervals($attr) -  Time intervals

=cut
#**********************************************************
sub iptv_intervals{
  my ($attr) = @_;

  my @DAY_NAMES = ($lang{ALL}, $WEEKDAYS[1], $WEEKDAYS[2], $WEEKDAYS[3], $WEEKDAYS[4], $WEEKDAYS[5], $WEEKDAYS[6],
    $WEEKDAYS[7], $lang{HOLIDAYS});

  my %visual_view = ();
  my Tariffs $tarif_plan;

  if ( defined( $attr->{TP} ) ){
    $tarif_plan  = $attr->{TP};
    $tarif_plan->{ACTION} = 'add';
    $tarif_plan->{LNG_ACTION} = $lang{ADD};
    if ( $FORM{channels} ){
      iptv_ti_channels( { TP => $attr->{TP} } );
    }
    elsif ( $FORM{add} ){
      $tarif_plan->ti_add( { %FORM } );
      if ( !$tarif_plan->{errno} ){
        $html->message( 'info', $lang{INFO}, "$lang{INTERVALS} $lang{ADDED}" );
      }
    }
    elsif ( $FORM{change} ){
      $tarif_plan->ti_change( $FORM{TI_ID}, { %FORM } );
      if ( !$tarif_plan->{errno} ){
        $html->message( 'info', $lang{INFO}, "$lang{INTERVALS} $lang{CHANGED} [$tarif_plan->{TI_ID}]" );
      }
    }
    elsif ( defined( $FORM{chg} ) ){
      $tarif_plan->ti_info( $FORM{chg} );
      if ( !$tarif_plan->{errno} ){
        $html->message( 'info', $lang{INFO}, "$lang{INTERVALS} $lang{CHANGE} [$FORM{chg}]" );
      }
      $tarif_plan->{ACTION} = 'change';
      $tarif_plan->{LNG_ACTION} = $lang{CHANGE};
    }
    elsif ( $FORM{del} && $FORM{COMMENTS} ){
      $tarif_plan->ti_del( $FORM{del} );
      if ( !$tarif_plan->{errno} ){
        $html->message( 'info', $lang{DELETED}, "$lang{DELETED} $FORM{del}" );
      }
    }
    else{
      $tarif_plan->ti_defaults();
    }

    my $list = $tarif_plan->ti_list( { %LIST_PARAMS } );
    my $table = $html->table({
      width      => '100%',
      caption    => $lang{INTERVALS},
      title      => [ '#', $lang{DAYS}, $lang{BEGIN}, $lang{END}, '-', '-', '-', '-' ],
      cols_align => [ 'left', 'left', 'right', 'right', 'right', 'center', 'center', 'center', 'center' ],
      qs         => $pages_qs,
      caption    => $lang{INTERVALS},
      ID         => 'IPTV_INTERVALS'
    });

    my $color = "AAA000";
    foreach my $line ( @{$list} ){
      my $delete = $html->button( $lang{DEL}, "index=$index$pages_qs&del=$line->[0]",
        { MESSAGE => "$lang{DEL} [$line->[0]] ?", class => 'del' } );
      $color = sprintf( "%06x", hex( '0x' . $color ) + 7000 );

      #day, $hour|$end = color
      my ($h_b, undef, undef) = split( /:/, $line->[2], 3 );
      my ($h_e, undef, undef) = split( /:/, $line->[3], 3 );
      push( @{ $visual_view{ $line->[1] } }, "$h_b|$h_e|$color|$line->[0]" );
      if ( ($FORM{tt} && $FORM{tt} eq $line->[0]) || ($FORM{chg} && $FORM{chg} eq $line->[0]) ){
        $table->{rowcolor} = $_COLORS[0];
      }
      else{
        undef($table->{rowcolor});
      }
      $table->addtd(
        $table->td( $line->[0], { rowspan => ($line->[5] > 0) ? 2 : 1 } ),
        $table->td( $html->b( $DAY_NAMES[ $line->[1] ] ) ),
        $table->td( $line->[2] ),
        $table->td( $line->[3] ),
        $table->td( $html->button( $lang{CHANNELS}, "index=$index$pages_qs&channels=$line->[0]", { BUTTON => 1 } ) ),
        $table->td( $html->button( $lang{CHANGE}, "index=$index$pages_qs&chg=$line->[0]", { class => 'change' } ) ),
        $table->td( $delete ), $table->td( "&nbsp;", { bgcolor => '#' . $color, rowspan => ($line->[5] > 0) ? 2 : 1 } )
      );
    }
    print $table->show();
  }
  elsif ( defined( $FORM{TP_ID} ) ){
    $FORM{subf} = $index;
    iptv_tp();
    return 0;
  }

  $index = $FORM{subf} if ($FORM{subf});

  _error_show( $tarif_plan );

  my $table = $html->table({
    width       => '100%',
    title_plain => [ $lang{DAYS}, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23 ],
    caption     => $lang{INTERVALS},
    rowcolor    => $_COLORS[1]
  });

  for ( my $i = 0; $i < 9; $i++ ){
    my @hours = ();
    my ($h_b, $h_e, $color, $p);
    my $link = "&nbsp;";
    my $tdcolor;
    for ( my $h = 0; $h < 24; $h++ ){
      if ( defined( $visual_view{$i} ) ){
        my $day_periods = $visual_view{$i};
        foreach my $line ( @{$day_periods} ){

          #print "$i -- $line    <br>\n";
          ($h_b, $h_e, $color, $p) = split( /\|/, $line, 4 );
          if ( ($h >= $h_b) && ($h < $h_e) ){
            $tdcolor = '#' . $color;
            $link = $html->button( '#', "index=$index&TP_ID=$FORM{TP_ID}&subf=$FORM{subf}&chg=$p", { BUTTON => 1 } );
            last;
          }
          else{
            $link = "&nbsp;";
            $tdcolor = $_COLORS[1];
          }
        }
      }
      else{
        $link = "&nbsp;";
        $tdcolor = $_COLORS[1];
      }
      push(@hours, $table->td("$link", { align => 'center', bgcolor => $tdcolor }));
    }
    $table->addtd( $table->td( $DAY_NAMES[$i] ), @hours );
  }

  print $table->show();
  my $day_id = $FORM{day} || $tarif_plan->{TI_DAY} || $FORM{TI_DAY};
  $tarif_plan->{SEL_DAYS} = $html->form_select('TI_DAY', {
    SELECTED     => $day_id,
    SEL_ARRAY    => \@DAY_NAMES,
    ARRAY_NUM_ID => 1
  });

  $html->tpl_show(_include('iptv_ti', 'Iptv'), $tarif_plan);

  return 1;
}

#**********************************************************
=head2 iptv_ti_channels($attr) Time intervals channels

=cut
#**********************************************************
sub iptv_ti_channels{
  my ($attr) = @_;

  if ( defined( $attr->{TP} ) ){
    if ( $FORM{change} ){
      $Iptv->channel_ti_change( \%FORM );
      if ( !$Iptv->{errno} ){
        $html->message( 'info', $lang{INFO}, "$lang{CHANGED}" );
      }
    }
  }
  else{
    iptv_tp( { f => 'iptv_ti_channels' } );
    return 0;
  }

  _error_show( $Iptv );
  my $pages_qs = "&channels=$FORM{channels}";

  my $list = $Iptv->channel_ti_list({
    %LIST_PARAMS,
    INTERVAL_ID => $FORM{channels},
    STATUS      => 0,
    COLS_NAME   => 1
  });

  my $table = $html->table({
    width      => '100%',
    caption    => "$lang{CHANNELS}",
    title      => [ "# ", "$lang{NUM}", $lang{NAME}, $lang{DESCRIBE}, "$lang{MONTH} $lang{PRICE}", "$lang{DAY} $lang{PRICE}", "$lang{MANDATORY} " ],
    cols_align => [ 'right', 'right', 'left', 'left', 'right', 'right', 'center' ],
    qs         => $pages_qs . "&TP_ID=$FORM{TP_ID}",
    ID         => 'IPTV_INTERVAL_CHANNELS',
    EXPORT     => 1
  });

  foreach my $line ( @{$list} ){
    $table->addrow(
      $html->form_input( 'IDS', "$line->{channel_id}",
        { TYPE => 'checkbox', STATE => $line->{interval_channel_id} || undef } ),
      $line->{channel_num}, $line->{name}, $line->{comments},
      $html->form_input( "MONTH_PRICE_" . $line->{channel_id}, (($line->{month_price}) ? $line->{month_price} : 0.00),
        { SIZE => 8 } ),
      $html->form_input( "DAY_PRICE_" . $line->{channel_id}, (($line->{day_price}) ? $line->{day_price} : 0.00),
        { SIZE => 8 } ),
      $html->form_input( "MANDATORY_" . $line->{channel_id}, 1,
        { TYPE => 'checkbox', STATE => (($line->{mandatory}) ? 1 : undef) } )
    );
  }

  form_search({
    SIMPLE  => {
      $lang{NUM}      => "NUMBER",
      $lang{NAME}     => "ROUTE_NAME",
      $lang{DISABLE}  => "DISABLE",
      $lang{DESCRIBE} => "DESCRIBE",
      $lang{PORT}     => "PORT"
    },
    HIDDEN_FIELDS => {
      TP_ID    => $FORM{TP_ID},
      channels => $FORM{channels}
    }
  });

  print $html->form_main({
    CONTENT => $table->show(),
    HIDDEN  => {
      TP_ID       => "$FORM{TP_ID}",
      index       => "$index",
      subf        => $FORM{subf},
      channels    => "$FORM{channels}",
      INTERVAL_ID => "$FORM{channels}"
    },
    SUBMIT  => { change => "$lang{CHANGE}" }
  });

  $table = $html->table({
    width      => '100%',
    cols_align => [ 'right', 'right' ],
    rows       => [ [ "$lang{TOTAL}:", $html->b( $Iptv->{TOTAL} ), "$lang{ACTIV}:", $html->b( $Iptv->{ACTIVE} ), ] ]
  });

  print $table->show();

  return 1;
}

#**********************************************************
=head2 iptv_channels() - TV channels

=cut
#**********************************************************
sub iptv_channels{

  if( $FORM{import} ){
    upload_m3u();
    return 1 if(!$FORM{import_message});
  }

  $html->message('info', $lang{INFO}, $FORM{message}) if ($FORM{message});

  $Iptv->{ACTION} = 'add';
  $Iptv->{LNG_ACTION} = $lang{ADD};
  $Iptv->{ACTION_STALKER} = 'stalker_add';
  $Iptv->{ACTION_LNG_STALKER} = $lang{ADD};

  my %tv_genres = (
    0  => '--',
    1  => $lang{INFORMATIVE},
    2  => $lang{ENTERTAINMENT},
    3  => $lang{BABY},
    4  => $lang{MOVIE},
    5  => $lang{SCIENCE},
    6  => $lang{SPORT},
    7  => $lang{MUSIC},
    8  => $lang{BUSINESS},
    9  => $lang{CULTURE},
    10 => $lang{ADULT}
  );

  my %state_hash = (
    0 => '--',
    1 => 'Disable',
    2 => 'Temporary not work',
    3 => 'Monitoring'
  );

  if ( $FORM{add} && $FORM{NAME} ){
    $Iptv->channel_add( \%FORM );
    if ( !$Iptv->{errno} ){
      $html->message( 'info', $lang{ADDED}, "$lang{ADDED} '$FORM{NAME}' " );
    }
  }
  elsif ( $FORM{stalker_export} ){
    #stalker_export();
  }
  elsif ( $FORM{change} ){
    $Iptv->channel_change( { %FORM } );
    if ( !$Iptv->{errno} ){
      $html->message( 'info', $lang{INFO}, "$lang{CHANGED}" );
    }
  }
  elsif ( $FORM{chg} ){
    $Iptv->channel_info( { %FORM, ID => $FORM{chg} } );
    if ( !$Iptv->{errno} ){
      $html->message( 'info', $lang{INFO}, "$lang{CHANGED}" );
      $FORM{add_form} = 1;
      $Iptv->{ACTION} = 'change';
      $Iptv->{LNG_ACTION} = $lang{CHANGE};
    }
  }
  elsif ( defined( $FORM{del} ) && $FORM{COMMENTS} ){
    $Iptv->channel_del( $FORM{del} );
    if ( !$Iptv->{errno} ){
      $html->message( 'info', $lang{DELETED}, "$lang{DELETED} $FORM{del}" );
    }
  }

  return 0 if (_error_show($Iptv));

  $Iptv->{DISABLE} = 'checked' if ($Iptv->{DISABLE} && $Iptv->{DISABLE} == 1);
  $Iptv->{CHANGE_PARAM} = defined( $Iptv->{CHANGE_PARAM} ) ? $Iptv->{CHANGE_PARAM} : $FORM{CHANGE_PARAM};
  $Iptv->{OLD_NUMBER} = defined( $Iptv->{OLD_NUMBER} ) ? $Iptv->{OLD_NUMBER} : $FORM{OLD_NUMBER};

  $Iptv->{GENRE_SEL} = $html->form_select("GENRE_ID", {
    SELECTED => $Iptv->{GENRE_ID} || $FORM{GENRE_ID},
    SEL_HASH => \%tv_genres,
    NO_ID    => 1,
  });

  $Iptv->{STATE_SEL} = $html->form_select("STATE", {
    SELECTED => $Iptv->{STATE} || $FORM{STATE},
    SEL_HASH => \%state_hash,
    NO_ID    => 1,
  });

  $html->tpl_show(_include('iptv_channel', 'Iptv'), $Iptv) if ($FORM{add_form});

  form_search({
    SIMPLE => {
      $lang{NUM}      => "NUM",
      $lang{NAME}     => "ROUTE_NAME",
      $lang{DISABLE}  => "DISABLE",
      $lang{DESCRIBE} => "DESCRIBE",
      $lang{PORT}     => "PORT",
      'URL'           => "URL",
    }
  }) if ($FORM{search_form});

  result_former({
    INPUT_DATA      => $Iptv,
    FUNCTION        => 'channel_list',
    BASE_FIELDS     => 6,
    FUNCTION_FIELDS => 'change,del',
    SKIP_USER_TITLE => 1,
    EXT_TITLES      => {
      id        => '#',
      name      => $lang{NAME},
      num       => $lang{NUM},
      port      => $lang{PORT},
      comments  => $lang{COMMENTS},
      filter_id => 'Filter-Id',
      status    => $lang{STATUS},
      stream    => 'Stream',
      state     => $lang{STATUS},
      genre_id  => $lang{GENRE},
    },
    SELECT_VALUE    => {
      state    => \%state_hash,
      status   => {
        0 => $lang{ENABLE},
        1 => $lang{DISABLE}
      },
      genre_id => \%tv_genres
    },
    TABLE           => {
      width   => '100%',
      caption => "$lang{CHANNELS}",
      qs      => $pages_qs,
      pages   => $Iptv->{TOTAL},
      ID      => 'IPTV_CHANNELS',
      MENU    => "$lang{ADD}:add_form=1&index=" . $index . ':add' . ";$lang{SEARCH}:index=$index&search_form=1:search",
      header  => [ "$lang{DOWNLOAD_CHANNELS}:index=$index&export=1" ],
      EXPORT  => 1,
      IMPORT  => "$SELF_URL?get_index=iptv_channels&import=1&header=2",
    },
    MAKE_ROWS       => 1,
    TOTAL           => 1
  });

  download_m3u() if ($FORM{export});

  return 1;
}

#**********************************************************
=head2 iptv_screens() - Extra screen for tariff plan

=cut
#**********************************************************
sub iptv_screens{

  $Iptv->{ACTION} = 'add';
  $Iptv->{LNG_ACTION} = "$lang{ADD}";

  if ( $FORM{add} ){
    $Iptv->screens_add( { %FORM } );
    if ( !$Iptv->{errno} ){
      $html->message( 'info', $lang{SCREENS}, "$lang{ADDED}" );
    }
  }
  elsif ( $FORM{change} ){
    $Iptv->screens_change( \%FORM );
    if ( !_error_show( $Iptv ) ){
      $html->message( 'info', $lang{SCREENS}, "$lang{CHANGED}" );
    }
  }
  elsif ( $FORM{chg} ){
    $Iptv->screens_info( $FORM{chg} );
    if ( !$Iptv->{errno} ){
      $FORM{add_form} = 1;
      $Iptv->{ACTION} = 'change';
      $Iptv->{LNG_ACTION} = "$lang{CHANGE}";
      $html->message( 'info', $lang{SCREENS}, "$lang{CHANGING}" );
    }
  }
  elsif ( $FORM{del} && $FORM{COMMENTS} ){
    $Iptv->screens_del( "$FORM{del}" );
    if ( !$Iptv->{errno} ){
      $html->message( 'info', $lang{SCREENS}, "$lang{DELETED}" );
    }
  }

  $html->tpl_show(_include('iptv_screens_add', 'Iptv'), $Iptv) if ($FORM{add_form});

  _error_show( $Iptv );
  $LIST_PARAMS{TP_ID} = $FORM{TP_ID};

  result_former({
    INPUT_DATA        => $Iptv,
    FUNCTION        => 'screens_list',
    DEFAULT_FIELDS  => 'NUM,NAME,MONTH_FEE,DAY_FEE',
    FUNCTION_FIELDS => 'change,del',
    SKIP_USER_TITLE => 1,
    EXT_TITLES      => {
      month_fee => $lang{MONTH_FEE},
      day_fee   => $lang{DAY_FEE},
      name      => $lang{NAME},
      num       => $lang{NUM},
      filter_id => $lang{FILTERS}
    },
    TABLE           => {
      width   => '100%',
      caption => "$lang{SCREENS}",
      qs      => $pages_qs,
      ID      => 'IPTV_SCREENS',
      EXPORT  => 1,
      MENU    => "$lang{ADD}:index=$index&add_form=1&$pages_qs:add",
    },
    MAKE_ROWS       => 1,
    SEARCH_FORMER   => 1,
    TOTAL           => 1
  });

  return 1;
}


#**********************************************************
=head2 upload_m3u() - Add new chanels from playlist

=cut
#**********************************************************
sub upload_m3u{
  #my ($attr) = @_;

  my @VARIATION = ('', "$lang{NO_CHANGES}", "$lang{DELETE_EXIST}", "$lang{CHANGE_EXIST}");
  my $select_variants = $html->form_select('SELECT_VARIANTS', {
    SELECTED     => $FORM{SELECT_VARIANTS},
    SEL_ARRAY    => \@VARIATION,
    ARRAY_NUM_ID => 1,
    SEL_OPTIONS  => { '' => '--' },
  });

  # list of channels
  my $list = $Iptv->channel_list({
    STREAM    => '_SHOW',
    GENRE_ID  => '_SHOW',
    COLS_NAME => 1,
    PAGE_ROWS => 10000
  });

  my $number = 0;    # channel num
  my $channel_name;
  foreach my $chan ( @{$list} ){
    if ( $number < $chan->{num} ){
      $number = $chan->{num};
    }
  }

  my $content = $FORM{FILE}->{Contents} || '';

  #split rows
  my @strings = split( "\n\r?", $content );
  #chop(@strings);

  # upload channels without changes
  if ( $FORM{FILE} && $FORM{SELECT_VARIANTS} && $FORM{SELECT_VARIANTS} == 1 ){
    my $count = 0;    # count of added channels
    $number = $number + 1;    # channels num
    my $genre;
    foreach my $str ( @strings ){
      # get channel name
      if ( $str =~ /^#EXTINF/ ){ 
        my ($trsh, $name) = split( ',', $str );
        $genre = 0;
        my @tags = split( ' ', $trsh );
        foreach my $t ( @tags ){
          if ( $t =~ /group-title/ ){
            my (undef, $group) = split( '=', $t );
            ($genre) = $group =~ m/"(.*)"/;
          }
        }
        $channel_name = $name;
      }

      # get channel url & add to channel list
      if ( $str =~ /^http/ ){
        my $channel_url = $str;
        $Iptv->channel_add({
          NAME     => $channel_name,
          NUM      => $number,
          PORT     => 0,
          COMMENTS => $channel_name,
          DISABLE  => 0,
          GENRE_ID => $genre,
          STREAM   => $channel_url
        });

        if ( !$Iptv->{errno} ){
          $number++;
          $count++;
        }
      }
    }
    $html->message( 'success', $lang{ADDED}, "$lang{ADDED} $count $lang{CHANNELS}" );
    return 1;
  }

  # delete channels and then upload new
  elsif ( $FORM{SELECT_VARIANTS} && $FORM{SELECT_VARIANTS} == 2 && $FORM{FILE} ){
    my $del_count = 0;    # del channels count
    $number = 1;    # channels num
    my $add_count = 0;    # add channels count
    my $genre;

    # del all channels
    foreach my $ch ( @{$list} ){
      $Iptv->channel_del( $ch->{id} );
      if ( !$Iptv->{errno} ){
        $del_count++;
      }
    }

    foreach my $str ( @strings ){
      my $channel_url;
      # get channel name
      if ( $str =~ /^#EXTINF/ ){
        $genre = 0;
        my ($trsh, $name) = split( ',', $str );
        my @tags = split( ' ', $trsh );
        foreach my $t ( @tags ){
          if ( $t =~ /^group-title/ ){
            #Tag groups
            my (undef, $group) = split( '=', $t );
            ($genre) = $group =~ m/"(.*)"/;
          }
        }
        $channel_name = $name;
      }

      # get channel url & add channel
      if ( $str =~ /^http/ ){
        $channel_url = $str;
        $Iptv->channel_add({
          NAME     => $channel_name,
          NUM      => $number,
          PORT     => 0,
          COMMENTS => $channel_name,
          DISABLE  => 0,
          GENRE_ID => $genre,
          STREAM   => $channel_url
        });

        if ( !$Iptv->{errno} ){
          $number++;
          $add_count++;
        }
      }
    }
    $html->message( 'success', $lang{ADDED}, "$lang{ADDED} $add_count $lang{CHANNELS}, $lang{DELETED} $del_count $lang{CHANNELS}" );
    return 1;
  }

  # upload channels and change channels which exist
  elsif ( $FORM{SELECT_VARIANTS} && $FORM{SELECT_VARIANTS} == 3 && $FORM{FILE} ){
    my $chg_count = 0;    # chg channels count
    my $add_count = 0;    # add channels count
    $number       = $number + 1;    # channles num
    my $genre;
    foreach my $str ( @strings ){
      my $changed = 0;        # if channel exist
      if ( $str =~ /^#EXTINF/ ){
        $genre = 0;
        my ($trsh, $name) = split( ',', $str );
        my @tags = split( ' ', $trsh );
        foreach my $t ( @tags ){
          if ( $t =~ /group-title/ ){
            #($tag, $group)
            my (undef, $group) = split( '=', $t );
            ($genre) = $group =~ m/"(.*)"/;
          }
        }
        $channel_name = $name;
      }
      if ( $str =~ /^http/ ){
        my $channel_url = $str;
        foreach my $ch ( @{$list} ){
          if ( $ch->{name} && $ch->{name} eq $channel_name ){
            if ( $ch->{stream} ne $channel_url || $ch->{comments} ne $channel_name || $ch->{genre_id} != $genre ){
              $Iptv->channel_change(
                {
                  ID       => $ch->{id},
                  COMMENTS => $channel_name,
                  STREAM   => $channel_url,
                  GENRE_ID => $genre
                }
              );
              if ( !$Iptv->{errno} ){
                $changed = 1;
                $chg_count++;
              }
            }
          }
        }
        if ( $changed == 0 ){
          $Iptv->channel_add(
            {
              NAME     => $channel_name,
              NUM      => $number,
              PORT     => 0,
              COMMENTS => $channel_name,
              DISABLE  => 0,
              GENRE_ID => $genre,
              STREAM   => $channel_url
            }
          );
          if ( !$Iptv->{errno} ){
            $number++;
            $add_count++;
          }
        }
      }
    }
    $html->message( 'success', $lang{ADDED}, "$lang{ADDED} $add_count $lang{CHANNELS}, $lang{CHANGED} $chg_count $lang{CHANNELS}" );
    return 1;
  }
  elsif ( $FORM{SELECT_VARIANTS} && $FORM{SELECT_VARIANTS} && !$FORM{FILE} ){
    $html->message( 'err', "$lang{NO_FILE}" );
  }

  $html->tpl_show(
    _include( 'iptv_upload_m3u', 'Iptv' ),
    {
      VARIANTS        => $select_variants,
      SUBMIT_BTN_NAME => $lang{ADD},
      PANEL_HEADING   => $lang{UPLOAD_CHANNELS},
      ACTION          => 'add'
    }
  );

  return 1;
}

#**********************************************************
=head2 download_m3u() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub download_m3u {
  #my ($attr) = @_;
  my %tv_genres = (
    0  => '--',
    1  => $lang{INFORMATIVE},
    2  => $lang{ENTERTAINMENT},
    3  => $lang{BABY},
    4  => $lang{MOVIE},
    5  => $lang{SCIENCE},
    6  => $lang{SPORT},
    7  => $lang{MUSIC},
    8  => $lang{BUSINESS},
    9  => $lang{CULTURE},
    10 => $lang{ADULT}
  );

  my $channels_list = $Iptv->channel_list(
    {
      STREAM    => "_SHOW",
      GENRE_ID  => "_SHOW",
      COLS_NAME => 1,
      PAGE_ROWS => 10000
    }
  );

  if($FORM{IDS}){
    my $filename = $conf{TPL_DIR} . "$FORM{FILENAME}.m3u";
    my @ids = split(',', $FORM{IDS});
    my $list_to_file = "#EXTM3U\n";

    foreach my $id (@ids){
      my $channel_information = $Iptv->channel_info({ID => $id});
      $list_to_file .= "#EXTINF:0,";
      $list_to_file .= "$channel_information->{NAME}\n";
      $list_to_file .= "$channel_information->{STREAM}\n";
    }

    if(open(my $fh, '>', $filename)) {
      print $fh $list_to_file;
      close $fh;
    }
    else {
      $html->message( 'err', $lang{ERROR},  "Can't open file '$filename' $!" );
      return 1;
    }

    $html->message("success", "$lang{CHANNELS_EXPORTED}", "$lang{SUCCESS}");
    return 1;
  }

  my $channels_table = $html->table(
    {
      width   => '100%',
      # caption => "$lang{DOWNLOAD_CHANNELS}",
      title   => [ '-', "$lang{NAME}", "Stream",$lang{GENRE}, "$lang{STATUS}"],
      ID      => 'EXPORT_CHANNELS'
    }
  );

  foreach my $channel (@$channels_list){
    $channels_table->addrow($html->form_input('IDS', $channel->{id}, { TYPE => 'checkbox' }),
      $channel->{name},
      $channel->{stream},
      $tv_genres{$channel->{genre_id}},
        $channel->{status} == 0 ? $lang{ENABLE} : $lang{DISABLE}
    );
  }

  #print $html->form_main(
  #  {
  #    CONTENT => $channels_table->show(),
  #    HIDDEN  => {
  #      index       => "$index",
  #      # OP_SID      => $op_sid,
  #      IMPORT_TYPE => $FORM{EXPORT_TYPE},
  #    },
  #    SUBMIT  => { IMPORT => "$lang{IMPORT}" },
  #    NAME    => 'FORM_EXPORT'
  #  }
  #);
  $html->tpl_show(
    _include( 'iptv_download_m3u', 'Iptv' ),
    {
      SUBMIT_BTN_NAME => $lang{ADD},
      PANEL_HEADING   => $lang{UPLOAD_CHANNELS},
      TABLE           => $channels_table->show()
    }
  );

  return 1;
}

#*******************************************************************
=head2 iptv_close_period() - close period

=cut
#*******************************************************************
sub iptv_close_period{

  if ( $FORM{CLOSE_PERIOD} ){
    $Conf->config_del( 'IPTV_CLOSED_PERIOD' );
    $Conf->config_add(
      {
        PARAM => 'IPTV_CLOSED_PERIOD',
        VALUE => "1"
      }
    );
  }

  $Conf->config_info( { PARAM => 'IPTV_CLOSED_PERIOD' } );

  my $close_period = ($Conf->{VALUE} && $Conf->{VALUE} eq '1') ? $lang{MONTH_FEE} : $Conf->{VALUE};

  my $table = $html->table(
    {
      width      => '300',
      caption    => $lang{CLOSE_PERIOD},
      cols_align => [ 'left', 'left' ],
      rows       => [ [ "$lang{STATUS}:", $close_period ] ],
      ID         => 'CLOSE_PERIOD'
    }
  );

  my %submit = ();

  if ( defined( $users->{VALUE} ) && $users->{VALUE} ne '1' ){
    $submit{CLOSE_PERIOD} = "$lang{CLOSE_PERIOD}";
  }

  print $html->form_main(
    {
      CONTENT => $table->show(),
      HIDDEN  => { index => "$index", },
      SUBMIT  => \%submit
    }
  );

  return 1;
}

#**********************************************************
=head2 iptv_nas() - Iptv NAS

=cut
#**********************************************************
sub iptv_nas{
  $FORM{subf} = 18;
  iptv_tp();
}


1;