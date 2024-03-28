=head1 NAME

 Box mng

=cut

use strict;
use warnings FATAL => 'all';

our(
  $Equipment,
  $html,
  %lang,
);

#********************************************************
=head2 equipment_boxes()

=cut
#********************************************************
sub equipment_boxes{

  $Equipment->{ACTION} = 'add';
  $Equipment->{LNG_ACTION} = "$lang{ADD}";

  if ( $FORM{add} ){
    $Equipment->equipment_box_add( { %FORM } );
    if ( !$Equipment->{errno} ){
      $html->message( 'info', $lang{BOXES}, "$lang{ADDED}" );
    }
  }
  elsif ( $FORM{change} ){
    $Equipment->equipment_box_change( \%FORM );
    if ( !_error_show( $Equipment ) ){
      $html->message( 'info', $lang{BOXES}, "$lang{CHANGED}" );
    }
  }
  elsif ( $FORM{chg} ){
    $Equipment->equipment_box_info( "$FORM{chg}" );

    if ( !$Equipment->{errno} ){
      $Equipment->{ACTION} = 'change';
      $Equipment->{LNG_ACTION} = "$lang{CHANGE}";
      $html->message( 'info', $lang{BOXES}, "$lang{CHANGING}" );
    }
  }
  elsif ( $FORM{del} && $FORM{COMMENTS} ){
    $Equipment->equipment_box_del( "$FORM{del}" );
    if ( !$Equipment->{errno} ){
      $html->message( 'info', $lang{BOXES}, "$lang{DELETED}" );
    }
  }

  if ( $FORM{add_form} ){
    $Equipment->{TYPE_SEL} = $html->form_select(
      'TYPE_ID',
      {
        SELECTED       => $Equipment->{TYPE_ID} || 0,
        SEL_LIST       => $Equipment->equipment_box_type_list( { COLS_NAME => 1, CLEAR_NAMES => 1 } ),
        SEL_VALUE      => 'marking,units',
        NO_ID          => 1,
        MAIN_MENU      => get_function_index( 'equipment_box_types' ),
        MAIN_MENU_ARGV => "chg=$Equipment->{TYPE}"
      }
    );

    $html->tpl_show( _include( 'equipment_box', 'Equipment' ), $Equipment );
  }

  _error_show( $Equipment );
  result_former({
    INPUT_DATA        => $Equipment,
    FUNCTION        => 'equipment_box_list',
    BASE_FIELDS     => 3,
    FUNCTION_FIELDS => 'change,del',
    SKIP_USER_TITLE => 1,
    EXT_TITLES      => {
      serial   => $lang{SERIAL},
      type     => $lang{TYPE},
      datetime => $lang{DATE}
    },
    TABLE           => {
      width   => '100%',
      caption => "$lang{BOXES}",
      qs      => $pages_qs,
      ID      => 'card_LIXT',
      EXPORT  => 1,
      MENU    => "$lang{ADD}:index=$index&add_form=1&$pages_qs:add",
    },
    MAKE_ROWS       => 1,
    SEARCH_FORMER   => 1,
     TOTAL           => 1
  });

  return 1;
}

#********************************************************
=head2 equipment_box_types()

=cut
#********************************************************
sub equipment_box_types{

  $Equipment->{ACTION} = 'add';
  $Equipment->{LNG_ACTION} = "$lang{ADD}";

  if ( $FORM{add} ){
    $Equipment->equipment_box_type_add( { %FORM } );
    if ( !$Equipment->{errno} ){
      $html->message( 'info', $lang{BOXES}, "$lang{ADDED}" );
    }
  }
  elsif ( $FORM{change} ){
    $Equipment->equipment_box_type_change( \%FORM );
    if ( !_error_show( $Equipment ) ){
      $html->message( 'info', $lang{BOXES}, "$lang{CHANGED}" );
    }
  }
  elsif ( $FORM{chg} ){
    $Equipment->equipment_box_type_info( "$FORM{chg}" );

    if ( !$Equipment->{errno} ){
      $Equipment->{ACTION} = 'change';
      $Equipment->{LNG_ACTION} = "$lang{CHANGE}";
      $FORM{add_form} = 1;
      $html->message( 'info', $lang{BOXES}, "$lang{CHANGING}" );
    }
  }
  elsif ( $FORM{del} && $FORM{COMMENTS} ){
    $Equipment->equipment_box_type_del( "$FORM{del}" );
    if ( !$Equipment->{errno} ){
      $html->message( 'info', $lang{BOXES}, "$lang{DELETED}" );
    }
  }

  if ( $FORM{add_form} ){
    $html->tpl_show( _include( 'equipment_box_types', 'Equipment' ), $Equipment );
  }

  _error_show( $Equipment );

  result_former({
    INPUT_DATA        => $Equipment,
    FUNCTION        => 'equipment_box_type_list',
    BASE_FIELDS     => 5,
    FUNCTION_FIELDS => 'change,del',
    SKIP_USER_TITLE => 1,
    EXT_TITLES      => {
      marking  => $lang{MARKING},
      vendor   => $lang{VENDOR},
      units    => $lang{UNITS},
      width    => $lang{WIDTH},
      hieght   => $lang{HIEGHT},
      length   => $lang{LENGTH},
      diameter => $lang{DIAMETER},
    },
    TABLE           => {
      width   => '100%',
      caption => 'card',
      qs      => $pages_qs,
      ID      => 'EQUIPMENT_BOXES',
      EXPORT  => 1,
      MENU    => "$lang{ADD}:index=$index&add_form=1&$pages_qs:add",
    },
    MAKE_ROWS       => 1,
    SEARCH_FORMER   => 1,
    TOTAL           => 1
  });

  return 1;
}


1;