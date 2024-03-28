=head1 NAME

  Subscribes

=cut

use strict;
use warnings FATAL => 'all';
use AXbills::Base qw(cmd);

our Iptv $Iptv;
our (
  %lang,
  $html,
  $admin,
  $db,
  %conf
);

my $Tariffs = Tariffs->new( $db, \%conf, $admin );

#**********************************************************
=head2 iptv_subscribes() Iptv external subsribes

=cut
#**********************************************************
sub iptv_subscribes{
  #my ($attr) = @_;

  $Iptv->{ACTION} = 'add';
  $Iptv->{ACTION_LNG} = $lang{ADD};

  if ( $FORM{add} ){
    my $result = '';
    my $message = '';
    if ( $FORM{COUNT} ){
    }
    elsif ( $FORM{IMPORT} ){
      $result = $FORM{IMPORT}{Content};
    }
    elsif ( $conf{IPTV_SUBSCRIBE_CMD} ){
      $result = cmd(
        $conf{IPTV_SUBSCRIBE_CMD},
        {
          PARAMS => { %{$Iptv}, ACTION => 'GET_LIST' },
          debug  => $conf{IPTV_CMD_DEBUG}
        }
      );
    }
    $Iptv->subscribe_add( { %FORM, MULTI_ARR => $result } );
    if ( !$Iptv->{errno} ){
      if ( $Iptv->{TOTAL} > 1 ){
        $message = "$lang{TOTAL}: $Iptv->{TOTAL}";
      }
      $html->message( 'info', $lang{INFO}, "$lang{ADDED}\n$message" );
    }
  }
  elsif ( $FORM{change} ){
    $Iptv->subscribe_change( { %FORM } );
    if ( !$Iptv->{errno} ){
      $html->message( 'info', $lang{INFO}, "$lang{CHANGED}" );
    }
  }
  elsif ( defined( $FORM{chg} ) ){
    $Iptv->subscribe_info( $FORM{chg} );
    if ( !$Iptv->{errno} ){
      $FORM{add_form} = 1;
      $html->message( 'info', $lang{INFO}, "$lang{CHANGING}" );
    }
    $Iptv->{ACTION} = 'change';
    $Iptv->{ACTION_LNG} = $lang{CHANGE};
  }
  elsif ( defined( $FORM{del} ) && defined( $FORM{COMMENTS} ) ){
    $Iptv->subscribe_del( $FORM{del} );
    if ( !$Iptv->{errno} ){
      $html->message( 'info', $lang{INFO}, "$lang{DELETED}" );
    }
  }
  _error_show( $Iptv, { MODULE => 'Iptv' } );

  my %subscribes_status = (
    0 => $lang{ACTIVE},
    1 => $lang{DISABLE},
    2 => $lang{BLOCKED},
    3 => $lang{RETURNED},
    4 => $lang{STOLEN},
    5 => $lang{DEMAGED},
    6 => $lang{UNUSED}
  );

  $Iptv->{STATUS_SEL} = $html->form_select(
    'STATUS',
    {
      SELECTED => $Iptv->{STATUS} || $FORM{STATUS},
      SEL_HASH => \%subscribes_status,
      NO_ID    => 1
    }
  );

  $Iptv->{TP_SEL} = $html->form_select(
    'TP_ID',
    {
      SELECTED       => $Iptv->{TP_ID},
      SEL_LIST       => $Tariffs->list( { MODULE => 'Iptv', NEW_MODEL_TP => 1, COLS_NAME => 1, DOMAIN_ID => $admin->{DOMAIN_ID} } ),
      SEL_KEY        => 'tp_id',
      SEL_VALUE      => 'id,name',
      NO_ID          => 1,
      MAIN_MENU      => get_function_index( 'iptv_tp' ),
      MAIN_MENU_ARGV => "TP_ID=" . ($Iptv->{TP_ID} || '')
    }
  );
  if ( $FORM{add_form} ){
    $html->tpl_show( _include( 'iptv_subscribe', 'Iptv' ), { %{$Iptv}, %FORM } );
  }
  elsif ( $FORM{search_form} ){
    $Iptv->{ACTION_LNG} = '';
    form_search( { SEARCH_FORM =>
        $html->tpl_show( _include( 'iptv_subscribe_search', 'Iptv' ), { %FORM, %{$Iptv} }, { OUTPUT2RETURN => 1 } ) } );
  }
  my @keys = sort { $a <=> $b } keys( %subscribes_status );
  my @result_status = @subscribes_status{@keys};

  result_former(
    {
      INPUT_DATA        => $Iptv,
        FUNCTION        => 'subscribe_list',
        BASE_FIELDS     => 1,
        DEFAULT_FIELDS  => 'ID,LOGIN,STATUS,EXT_ID,TP_NAME,EXPIRE,CREATED',
        FUNCTION_FIELDS => 'change,del',
        EXT_TITLES      => {
        'tp_name' => "$lang{TARIF_PLAN}",
        'status'  => "$lang{STATUS}",
        'expire'  => "$lang{EXPIRE}",
        'created' => "$lang{CREATED}",
      },
        TABLE           => {
        width   => '100%',
        caption => "IPTV_SUBSRIBES",
        qs      => $pages_qs,
        ID      => 'IPTV_SUBSRIBES',
        EXPORT  => 1,
        MENU    => "$lang{ADD}:add_form=1&index=" . $index . ':add' . ";$lang{SEARCH}:index=$index&search_form=1:search",
      },
        STATUS_VALS     => \@result_status,
        MAKE_ROWS       => 1,
        MODULE          => 'Iptv',
        TOTAL           => 1
    }
  );
  _error_show( $Iptv );
  return 1;
}

#**********************************************************
=head2 iptv_sel_subscribes();

=cut
#**********************************************************
sub iptv_sel_subscribes{
  my ($attr) = @_;

  my $list = $Iptv->subscribe_list(
    {
      STATUS    => $Iptv->{ID} ? undef : 6,
      ID        => $Iptv->{SUBSCRIBE_ID},
      COLS_NAME => 1
    }
  );

  if ( $Iptv->{TOTAL} == 0 ){
    return '';
  }

  my $subscribe_id = $attr->{SUBSCRIBE_ID} || $FORM{SUBSCRIBE_ID} || q{};
  my $SUBSCRIBE_SEL = $html->form_select(
    'SUBSCRIBE_ID',
    {
      SELECTED       => $subscribe_id,
      SEL_LIST       => $list,
      SEL_KEY        => 'id',
      SEL_VALUE      => 'id,tp_name,ext_id',
      NO_ID          => 1,
      SEL_OPTIONS    => { '' => (($FORM{UID}) ? '--' : "$lang{ALL}") },
      MAIN_MENU      => get_function_index( 'iptv_subscribes' ),
      MAIN_MENU_ARGV => "chg=". $subscribe_id
    }
  );

  $SUBSCRIBE_SEL = $html->tpl_show(
    templates( 'form_row' ),
    {
      ID    => 'DV_LOGIN',
      NAME  => "SUBSCRIBE ",
      VALUE => $SUBSCRIBE_SEL
    },
    { OUTPUT2RETURN => 1 }
  );

  return $SUBSCRIBE_SEL;
}


1;