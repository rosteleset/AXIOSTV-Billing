=head1 NAME

  OllTv web

=cut

use strict;
use warnings FATAL => 'all';
use AXbills::Base qw(in_array);
use Time::Piece;
use Time::Seconds;

our(
  $Iptv,
  $db,
  $html,
  $admin,
  %conf,
  %lang,
  %tp_list,
  %channel_list,
  %FORM,
  $user,
  $users,
  $index,
  @MODULES,
  $DATE
);

our Iptv::Olltv $Tv_service;

#**********************************************************
=head2 olltv_bundle($Iptv, $attr)

=cut
#**********************************************************
sub olltv_bundle{
  my ($Iptv_, $attr) = @_;

  my Iptv::Olltv $Tv_service_ = $attr->{EXTRA_SERVICE};

  $Tv_service_->bundle_info(
    {
      ID           => $Iptv_->{ID},
      TP_FILTER_ID => $Iptv_->{FILTER_ID} || $Iptv_->{TP_FILTER_ID}
    }
  );

  return $Tv_service_;
}

#**********************************************************
=head2 olltv_device($Iptv, $attr)

=cut
#**********************************************************
sub olltv_device{
  my ($Iptv_, $attr) = @_;

  $Tv_service = $attr->{EXTRA_SERVICE};
  delete( $Tv_service->{FORM_DEVICE} );

  if ( $FORM{del_device} ){
    if ( !$Tv_service->{serial_number} && $FORM{SERIAL_NUMBER} ){
      $Tv_service->{serial_number} = $FORM{SERIAL_NUMBER};
    }
    if ( !$FORM{TYPE} ){
      $attr->{DEL_TYPE_SEL} = $html->form_select(
        'TYPE',
        {
          SELECTED => $FORM{TYPE},
          SEL_HASH => $Tv_service->device_del_types(),
          NO_ID    => 1
        }
      );

      $html->tpl_show( _include( 'iptv_olltv_device_del', 'Iptv' ), { %{$attr}, %{$user}, %{$Tv_service}, %FORM } );
      return $Tv_service;
    }
    else{
      if ( !$FORM{SERIAL_NUMBER} && $Tv_service->{serial_number} ){
        $FORM{SERIAL_NUMBER} = $Tv_service->{serial_number};
      }

      $Tv_service->device_del( \%FORM );
      if ( !$Tv_service->{errno} ){
        $html->message( 'info', $lang{DEVICE}, "$lang{DELETED} $FORM{MAC}" );
      }
    }
  }

  if ( $Iptv_->{CID} ){
    $Tv_service->device_info( $Iptv_ );
    $Tv_service->{DEVICE_DEL} = $html->button( "$lang{DEL} $lang{DEVICE}",
      "index=$index&chg=$FORM{chg}&UID=$Iptv_->{UID}&del_device=1&SERIAL_NUMBER=" . ($Tv_service->{serial_number} || '') . "&MAC=" . ($Iptv_->{CID} || '')
      , { class => 'del' } );
  }

  my @device_types = ('stb', 'dune', 'smarttv', 'lge', 'samsung', 'ipad',);

  $Tv_service->{TYPE_SEL} = $html->form_select(
    'DEVICE_TYPE',
    {
      SELECTED    => $Tv_service->{type} || $FORM{DEVICE_TYPE} || 'stb',
      SEL_ARRAY   => \@device_types,
      SEL_OPTIONS => { '' => '--' },
    }
  );

  $Tv_service->{DEVICE_ACTIVATION_TYPE_SEL} = $html->form_select(
    'ACTIVATION_TYPE',
    {
      SELECTED => $FORM{ACTIVATION_TYPE},
      SEL_HASH => $Tv_service->device_activation_types(),
      NO_ID    => 1
    }
  );

  if ( $Tv_service->{DEVICE_BINDING_CODE} ){
    $Tv_service->{DEVICE_BINDING_CODE_FORM} = $html->tpl_show(
      templates( 'form_row' ),
      {
        ID    => "DEVICE_BINDING_CODE",
        NAME  => 'BINDING_CODE',
        VALUE => $html->form_input( 'BINDING_CODE', $Tv_service->{DEVICE_BINDING_CODE}, { OUTPUT2RETURN => 1 } ),
      },
      { OUTPUT2RETURN => 1 }
    );
  }

  if ( in_array( 'Storage', \@MODULES ) ){
    load_module( 'Storage', $html );
    my $Storage = Storage->new( $db, $admin, \%conf );
    my $storage_articles = storage_inc_articles_sel(
      $Storage,
      {
        SIA_ID          => 1,
        HIDE_ZERO_VALUE => 1,
        ARTICLE_TYPE    => 4 # for set to box
    } );

    $Tv_service->{STORAGE_FORM} = $html->tpl_show(
      templates( 'form_row' ),
      {
        ID    => 'STORAGE_ID',
        NAME  => $lang{STORAGE},
        VALUE => $storage_articles
      },
      { OUTPUT2RETURN => 1 }
    );
  }

  $Tv_service->{FORM_DEVICE} = $html->tpl_show( _include( 'iptv_olltv_device', 'Iptv' ), { %{$attr}, %{$Iptv_},
      %{$Tv_service}, %FORM }, { OUTPUT2RETURN => 1 } );
  $Tv_service->{PARENT_CONTROL} = $html->button( $lang{PARENT_CONTROL},
    "index=$index&UID=$Iptv_->{UID}&chg=$Iptv_->{ID}&PARENT_CONTROL=1", { BUTTON => 1 } ) if ($Iptv_->{ID});

  return $Tv_service;
}

#**********************************************************
=head2 olltv_user($attr)

=cut
#**********************************************************
sub olltv_user{
  my ($attr) = @_;

  if ( !$Tv_service ){
    $html->message( 'err', $lang{ERROR}, "Olltv not configured" );
    return 0;
  }
  #elsif ($FORM{screen}) {
  #return;
  #}

  if ( $FORM{del_bundle} ){
    if ( !$FORM{TYPE} ){
      $attr->{DEL_TYPE_SEL} = $html->form_select(
        'TYPE',
        {
          SELECTED => $FORM{TYPE},
          SEL_HASH => $Tv_service->bundle_del_types(),
          NO_ID    => 1
        }
      );
      $html->tpl_show( _include( 'iptv_olltv_bundle', 'Iptv' ),
        { %{$attr},
          %{$user},
          %{$Tv_service},
          %FORM,
          SUB_ID => $FORM{SUB_ID} || $Iptv->{TP_FILTER_ID}
        } );
    }
    else{
      $Tv_service->bundle_del( \%FORM );
      if ( !$Tv_service->{errno} ){
        $html->message( 'info', $lang{SUBSCRIBE}, "$lang{DELETED} MAC: ". ($FORM{MAC} || q{}) );
      }
    }
  }

  _error_show( $Tv_service, { MODULE => 'Olltv' } );

  my $bundle;

  if ( $attr->{ID} ){
    $Tv_service->user_info( { ID => $attr->{ID} } );

    for ( my $i = 0; $i <= $#{ $Tv_service->{bought_subs} }; $i++ ){
      my $label_type = 'badge-light';

      if  ($Tv_service->{bought_subs}->[$i]->{service_type} == 1) {
        $label_type = 'badge-primary';
      }
      elsif($Tv_service->{bought_subs}->[$i]->{service_type} == 4) {
        $label_type = 'badge-info';
      }

      $Tv_service->{BOUGHT_SUBSRIBES} .= $html->element('span', " ($Tv_service->{bought_subs}->[$i]->{service_type}) "
        . $Tv_service->{bought_subs}->[$i]->{sub_id}
        . ' ' . $html->button($lang{del},
        "index=$index&UID=$FORM{UID}&chg=$attr->{ID}&del_bundle=1&SUB_ID=$Tv_service->{bought_subs}->[$i]->{sub_id}",
        { class => 'del' }), {
        class          => "badge $label_type m-1",
        title          => $Tv_service->{bought_subs}->[$i]->{start_date}
          . '-' . $Tv_service->{bought_subs}->[$i]->{expiration_date},
        'data-tooltip' => "BINDING_CODE: $Tv_service->{bought_subs}->[$i]->{device_binding_code}",
        'onclick'      => "copyToBuffer(\'$Tv_service->{bought_subs}->[$i]->{device_binding_code}\', true)",
        'style'        => "cursor: pointer;"
      });

      if ( $Tv_service->{bought_subs}->[$i]->{service_type} == 1 ){
        $bundle = $Tv_service->{bought_subs}->[$i];
        $Tv_service->{DEVICE_BINDING_CODE} = $Tv_service->{bought_subs}->[$i]->{device_binding_code};
      }
    }

    if ( !$Tv_service->{BOUGHT_SUBSRIBES} ){
      $Tv_service->{BOUGHT_SUBSRIBES} = $html->color_mark( $lang{NOT_ACTIVE}, 'bg-danger' );
    }

    if ( $Tv_service->{DEVICE_BINDING_CODE} ){
      $Tv_service->{BUNDLE_DEL} = $html->button( "$lang{DEL} Bundle",
        "index=$index&UID=$Iptv->{UID}&del_bundle=1&DS_ACCOUNT=$Tv_service->{ds_account}&SUB_ID="
          . (($bundle && $bundle->{sub_id}) ? $bundle->{sub_id} : '') . (($FORM{chg}) ? "&chg=$FORM{chg}" : ''),
        { class => 'del' } );
    }
  }

  $Tv_service = olltv_device( $attr, { EXTRA_SERVICE => $Tv_service, %{$attr} } );
  $Tv_service->{BUNDLE_TYPE_SEL} = $html->form_select('BUNDLE_TYPE', {
    SELECTED => $bundle->{activation_type} || $bundle->{service_type} || $FORM{BUNDLE_TYPE},
    SEL_HASH => $Tv_service->bundle_types(),
    NO_ID    => 1
  });

  if ( !$attr->{ID} ){
    $user = $users->pi( { UID => $FORM{UID} } );
    if ( $users->{_BIRTHDAY} && !$Tv_service->{BIRTH_DAY} ){
      $Tv_service->{BIRTH_DAY} = $users->{_BIRTHDAY};
    }
    if ( $users->{_BIRTH_DATE} && !$Tv_service->{BIRTH_DATE} ){
      $Tv_service->{BIRTH_DATE} = $users->{_BIRTH_DATE};
    }
  }
  else {
    $Tv_service->user_info({
      FULL         => 1,
      SUBSCRIBE_ID => $Iptv->{SUBSCRIBE_ID},
      UID          => $users->{UID},
      ID           => $Iptv->{ID}
    });
    $Tv_service->{OLLTV_USER_ID} = $Tv_service->{ID};
  }

  $Tv_service->{EMAIL} = $Tv_service->{email} if ($Tv_service->{email});
  $Tv_service->{PHONE} = $Tv_service->{phone} if ($Tv_service->{phone});

  if ( $Tv_service->{lastname} ){
    Encode::_utf8_off( $Tv_service->{lastname} );
    $Tv_service->{FIO2} = $Tv_service->{lastname};
  }
  if ( $Tv_service->{firstname} ){
    Encode::_utf8_off( $Tv_service->{firstname} );
    $Tv_service->{FIO} = $Tv_service->{firstname};
  }
  if ( $Tv_service->{region} ){
    Encode::_utf8_off( $Tv_service->{region} );
    $Tv_service->{CITY} = $Tv_service->{region};
  }
  if ( $Tv_service->{index} ){
    $Tv_service->{ZIP} = $Tv_service->{index};
  }
  if ( $Tv_service->{birth_date} ){
    $Tv_service->{BIRTH_DATE} = $Tv_service->{birth_date};
  }
  if ( !$Tv_service->{OLLTV_USER_ID} ){
    $Tv_service->{OLLTV_USER_ID} = $lang{ERR_NOT_REGISTERED};
  }

  $attr->{GENDER_SEL} = $html->form_select(
    'GENDER',
    {
      SELECTED => $Tv_service->{gender} || $users->{_GENDER} || 'M',
      SEL_HASH => {
        'F' => $lang{FEMALE},
        'M' => $lang{MALE}
      },
    }
  );

  $attr->{SEND_NEWS} = 'checked' if ( $Tv_service->{receive_news});

  if ( $attr->{SHOW_USER_FORM} ){
    $html->tpl_show( _include( 'iptv_olltv_user', 'Iptv' ), { %{$user}, %{$attr}, %{$Tv_service}, %{$bundle} } );
  }

  return $html->tpl_show( _include( 'iptv_olltv_user', 'Iptv' ), { %{$user}, %{$attr}, %{$Tv_service}, %{$bundle} },
    { OUTPUT2RETURN => 1 } );
}

#**********************************************************
=head2 olltv_sub($attr)

  Arguments:
    $attr
      DEL
      ADD_IF

=cut
#**********************************************************
sub olltv_sub{
  my ($attr) = @_;

  my @channels_list = ();

  if ( $attr->{DEL} ){
    @channels_list = keys %{ $attr->{DEL} };
  }

  if ( $attr->{ADD_ID} ){
    push @channels_list, @{ $attr->{ADD_ID} };
  }

  if ( $#channels_list == -1 ){
    return 0;
  }

  my $list = $Iptv->channel_list({
    ID        => join( ';', @channels_list ),
    PAGE_ROWS => 1000,
    COLS_NAME => 1
  });

  foreach my $line ( @{$list} ){
    if ( in_array( $line->{id}, $attr->{ADD_ID} ) ){
      $Tv_service->bundle_add({
        %{$users},
        %{$Iptv},
        %FORM,
        BUNDLE_TYPE  => $attr->{BUNDLE_TYPE} || 'subs_no_device',
        ID           => $attr->{ID} || $Iptv->{ID},
        TP_FILTER_ID => $line->{filter_id}
      });

      return $Tv_service if _error_show( $Tv_service, { MESSAGE => "$lang{CHANNEL}: $line->{num} $line->{name}" } );
    }
    elsif ( $attr->{DEL}->{ $line->{id} } ){
      $Tv_service->bundle_del({
        %{$users},
        %{$Iptv},
        %FORM,
        TYPE   => $attr->{BUNDLE_TYPE} || 'subs_break_contract',
        ID     => $attr->{ID} || $Iptv->{ID},
        SUB_ID => $line->{filter_id}
      });
      return $Tv_service if _error_show( $Tv_service, { MESSAGE => "$lang{CHANNEL}: $line->{num} $line->{name}" } );
    }
  }

  return 1;
}

#**********************************************************
=head2 olltv_console()

=cut
#**********************************************************
sub olltv_console {

  my @header_arr = ("$lang{ACCOUNTS}:index=$index&SERVICE_ID=$FORM{SERVICE_ID}",
    "getAllPurchases:index=$index&list=getAllPurchases&SERVICE_ID=$FORM{SERVICE_ID}",
    "getDeviceList:index=$index&list=getDeviceList&SERVICE_ID=$FORM{SERVICE_ID}",
    "CONSOLE:index=$index&list=console&SERVICE_ID=$FORM{SERVICE_ID}");

  print $html->table_header( \@header_arr, { TABS => 1 });

  my $start_date_for_request = $DATE;

  if ($FORM{list} && $FORM{list} eq 'getAllPurchases') {
    $start_date_for_request = Time::Piece->strptime($DATE, "%Y-%m-%d");
    $start_date_for_request -= ONE_MONTH;
    $start_date_for_request = $start_date_for_request->ymd;
  }

  if ($FORM{list} && $FORM{list} eq 'getDeviceList') {
    if (($FORM{del} && $FORM{COMMENTS}) || $FORM{MAC}) {
      $FORM{del_device} = 1;
      olltv_user();
    }
  }

  if ($FORM{list} && $FORM{list} eq 'getUserList') {
    if ($FORM{del} && $FORM{COMMENTS} && $Tv_service && $FORM{ACCOUNT}) {
      $Tv_service->user_del({
        ID => $FORM{ACCOUNT}
      });
    }
  }

  my $result = $Tv_service->_send_request({
    ACTION     => $FORM{list} || 'getUserList',
    DEBUG      => $conf{IPTV_OLLTV_DEBUG},
    start_date => $start_date_for_request
  });

  _error_show($Tv_service);

  if (!$result || ref $result ne 'HASH' || !$result->{data}){
    if($result && $result->{code}) {
      $html->message('err', $lang{ERROR}, "[$result->{code}] $result->{message}");
    }
    else {
      $html->message('warn', $lang{WARNING}, $lang{ERR_NO_DATA});
    }
    return 1;
  }

  result_former({
    FUNCTION_FIELDS => "iptv_console:del:mac;account;serial_number:&list="
      . ($FORM{list} || 'getUserList') . "&del=1&COMMENTS=1"
      . (($FORM{SERVICE_ID}) ? "&SERVICE_ID=$FORM{SERVICE_ID}" : ''),
    TABLE           => {
      width   => '100%',
      caption => $FORM{list} || 'getUserList',
      qs      => "&list=" . ($FORM{list} || '') . (($FORM{SERVICE_ID}) ? "&SERVICE_ID=$FORM{SERVICE_ID}" : ''),
      EXPORT  => 1,
      ID      => 'IPTV_OLLTV_LIST',
    },
    FILTER_COLS     => {
      account              => 'account_exist',
      SubscriberProviderID => 'search_link:iptv_users_list:ID',
    },
    DATAHASH        => ($FORM{list} && $FORM{list} eq 'getAllPurchases') ? $result->{data}->{purchases} : $result->{data},
    TOTAL           => 1
  });

  return 1;
}

#**********************************************************
=head2 olltv_screens($attr)

=cut
#**********************************************************
sub olltv_screens {
  my ($attr) = @_;

  $Tv_service = olltv_bundle($Iptv, { EXTRA_SERVICE => $Tv_service, %$attr });

  for ( my $i = 0; $i <= $#{ $Tv_service->{bought_subs} }; $i++ ){
    $Tv_service->{BOUGHT_SUBSRIBES} .= " ($Tv_service->{bought_subs}->[$i]->{service_type}) " . $Tv_service->{bought_subs}->[$i]->{sub_id};
    if ( $Tv_service->{bought_subs}->[$i]->{service_type} == 2
      && $Tv_service->{bought_subs}->[$i]->{sub_id}
      && $Tv_service->{bought_subs}->[$i]->{sub_id} eq $Iptv->{FILTER_ID} )
    {
      #my $bundle = $Tv_service->{bought_subs}->[$i]->{sub_id};
      $Tv_service->{DEVICE_BINDING_CODE} = $Tv_service->{bought_subs}->[$i]->{device_binding_code};
    }
  }

  $Tv_service = olltv_device( $Iptv, { EXTRA_SERVICE => $Tv_service, %{$attr} } );

  $Iptv->{FORM_DEVICE} = $Tv_service->{FORM_DEVICE};

  $html->tpl_show( _include( 'iptv_olltv_screens', 'Iptv' ), $Iptv );

  return 1;
}


#**********************************************************
=head2 account_exist($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub account_exist {
  my ($id) = @_;

  return '' if !$id;

  my $user_info = $Iptv->user_info($id);
  
  return '' if !$Iptv->{TOTAL};

  return $html->button($id, "index=" . get_function_index('iptv_users_list') . "&search_form=1&search=1&ID=$id");
}

1;