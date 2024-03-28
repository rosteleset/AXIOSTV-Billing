=head1 NAME

  Yate

=cut

use strict;
use warnings;

our (
  @service_status_colors,
  $html,
  %conf,
  %lang,
  $db,
  $admin,
  %permissions,
);

use Voip::Users;

our Voip $Voip;
my $Voip_users = Voip::Users->new($db, $admin, \%conf, {
  html        => $html,
  lang        => \%lang,
  permissions => \%permissions,
});

#**********************************************************
=head2 voip_yate_online()

=cut
#**********************************************************
sub voip_yate_online {

  result_former({
    INPUT_DATA     => $Voip,
    FUNCTION       => 'trunk_list',
    DEFAULT_FIELDS => 'NAME,STATUS,PROTOCOL',
    EXT_TITLES     => {
      'name'  => $lang{NAME},
      'state' => $lang{STATUS},
    },
    TABLE          => {
      width   => '100%',
      caption => "Trunks $lang{STATUS}",
      ID      => 'VOIP_TRUNKS',
    },
    MAKE_ROWS      => 1,
    MODULE         => 'Voip',
    TOTAL          => 1
  });
  
  $LIST_PARAMS{ONLINE} = 1;
  result_former({
    INPUT_DATA     => $Voip,
    FUNCTION       => 'user_list',
    DEFAULT_FIELDS => 'NUMBER,LOCATIONS,EXPIRES',
    EXT_TITLES     => {
      'number' => $lang{NUMBER},
    },
    TABLE          => {
      width   => '100%',
      caption => "Line $lang{STATUS}",
      ID      => 'VOIP_USERS',
    },
    MAKE_ROWS      => 1,
    MODULE         => 'Voip',
    TOTAL          => 1
  });
  
  $LIST_PARAMS{NOW} = 1;
  result_former({
    INPUT_DATA     => $Voip,
    FUNCTION       => 'voip_yate_cdr',
    DEFAULT_FIELDS => 'DATETIME,CALLER,CALLED,BILLTIME,DURATION,STATUS,REASON',
    #FUNCTION_FIELDS => 'voip_yate_user:change:number;uid,form_payments',
    EXT_TITLES     => {
      'caller' => $lang{NUMBER},
    },
    TABLE          => {
      width   => '100%',
      caption => "Active CALLS",
      ID      => 'VOIP_CDR',
    },
    MAKE_ROWS      => 1,
    MODULE         => 'Voip',
    TOTAL          => 1
  });

  return 1;
}

#**********************************************************
=head2 voip_yate_users_list()

=cut
#**********************************************************
sub voip_yate_users_list {

  if (defined($FORM{UID})) {
    $LIST_PARAMS{UID} = $FORM{UID};
  }

  my @service_status = ($lang{ENABLE}, $lang{DISABLE}, $lang{ALLOW_ANSWER}, $lang{DISABLE} . ':' . $lang{NON_PAYMENT});
  if ($FORM{TP_ID}) {
    $LIST_PARAMS{TP_ID} = $FORM{TP_ID};
    $pages_qs .= "&TP_ID=$FORM{TP_ID}";
  }

  $Voip->{STATUS_SEL} = $html->form_select(
    'DISABLE',
    {
      SELECTED => $FORM{DISABLE} || '',
      SEL_HASH => {
        '' => $lang{ALL},
        0  => $service_status[0],
        1  => $service_status[1],
        2  => $service_status[2],
        3  => $service_status[3],
      },
      NO_ID => 1,
      STYLE => \@service_status_colors,
    }
  );

  $Voip->{GROUP_SEL} = sel_groups();
  $Voip->{TP_SEL}    = $html->form_select(
    'TP_ID',
    {
      SELECTED    => $FORM{TP_ID},
      SEL_LIST    => $Voip->tp_list({ COLS_NAME => 1 }),
      SEL_KEY     => 'tp_id',
      SEL_VALUE   => 'id,name',
      NO_ID       => 1,
      SEL_OPTIONS => { '' => $lang{ALL} },
      MAIN_MENU   => get_function_index('voip_tp'),
    }
  );

  if ($FORM{search_form}) {
    form_search({ SEARCH_FORM => $html->tpl_show(_include('voip_users_search', 'Voip'), { %{$Voip}, %FORM }, { OUTPUT2RETURN => 1 }) });
  }

  if ($FORM{letter}) {
    $LIST_PARAMS{LOGIN} = "$FORM{letter}*";
    $pages_qs .= "&letter=$FORM{letter}";
  }

  my $status_bar;
  for (my $i = 0 ; $i <= 2 ; $i++) {
    my $name   = $service_status[$i];
    my $active = '';
    if (defined($FORM{SERVICE_STATUS}) && $FORM{SERVICE_STATUS} == $i && $FORM{SERVICE_STATUS} ne '') {
      $LIST_PARAMS{SERVICE_STATUS} = $FORM{SERVICE_STATUS};
      $pages_qs   .= "&SERVICE_STATUS=$i";
      $status_bar .= ' ' . $html->b($name);
      $active = 'active';
    }
    else {
      my $qs = $pages_qs;
      $qs =~ s/\&SERVICE_STATUS=\d//;
      $status_bar .= ' ' . $html->button($name, $service_status_colors[$i], { class => "btn btn-secondary $active" });
    }
  }

  my $menu_add = ($FORM{"UID"}) ? "$lang{ADD}:index=" . get_function_index('voip_yate_user') . "&UID=$FORM{UID}&new=1" . ':add' : '';

  result_former({
    INPUT_DATA      => $Voip,
    FUNCTION        => 'user_list',
    BASE_FIELDS     => 1,
    DEFAULT_FIELDS  => 'LOGIN,FIO,DEPOSIT,CREDIT,NUMBER,TP_NAME,SERVICE_STATUS',
    FUNCTION_FIELDS => 'voip_yate_user:change:number;uid,form_payments',
    EXT_TITLES      => {
      'port'        => $lang{PORT},
      'cid'         => 'CID',
      'filter_id'   => 'Filter ID',
      'tp_name'     => "$lang{TARIF_PLAN}",
      'voip_status' => "$lang{STATUS}",
      'number'      => "$lang{NUM}",
    },
    TABLE           => {
      width  => '100%',
      qs     => $pages_qs,
      header => $status_bar,
      ID     => 'VOIP_USERS_LIST',
      EXPORT => 1,
      MENU   => $menu_add . ";$lang{SEARCH}:index=$index&search_form=1:search",
    },
    MAKE_ROWS       => 1,
    MODULE          => 'Voip',
    TOTAL           => 1
  });

  if (_error_show($Voip)) {
    return 0;
  }

  return 1;
}

#**********************************************************

=head2 voip_yate_user($attr)

=cut

#**********************************************************
sub voip_yate_user {
  my ($attr) = @_;

  my $Nas = Nas->new($db, \%conf);
  $FORM{STATUS} = $FORM{DISABLE};
  $Voip->{UID} = $FORM{UID};
  $Voip->{NUMBER} = $FORM{NUMBER};
  my @service_status = ($lang{ENABLE}, $lang{DISABLE}, $lang{ALLOW_ANSWER}, $lang{DISABLE} . ':' . $lang{NON_PAYMENT});

  $Voip_users->voip_provision();

  if ($FORM{add} || $FORM{set}) {
    my $validate_result = $Voip_users->voip_user_preprocess(\%FORM);
    if ($validate_result->{errno}) {
      print $validate_result->{element};
      return 0;
    }
  }

  if ($FORM{add}) {
    $Voip->user_add({ %FORM });
    if (!$Voip->{errno}) {
      $html->message('info', $lang{INFO}, "$lang{ADDED}");
      service_get_month_fee($Voip) if (!$FORM{STATUS});

      if ($conf{VOIP_ASTERISK_USERS}) {
        $Voip_users->voip_mk_users_conf(\%FORM);
      }
    }
  }
  elsif ($FORM{set}) {
    $Voip->user_change({%FORM});
    if (!$Voip->{errno}) {
      $html->message('info', $lang{INFO}, "$lang{CHANGED}");
      $Voip->{ACCOUNT_ACTIVATE} = $attr->{USER_INFO}->{ACTIVATE};

      if (!$FORM{STATUS} && ($FORM{GET_ABON} || !$FORM{TP_ID})) {
        service_get_month_fee($Voip);
      }

      if ($conf{VOIP_ASTERISK_USERS}) {
        $Voip_users->voip_mk_users_conf(\%FORM);
      }
    }
  }
  elsif ($FORM{del} && $FORM{COMMENTS}) {
    $Voip->user_del();
    if (!$Voip->{errno}) {
      $html->message('info', $lang{INFO}, "$lang{DELETED}");
    }
  }

  _error_show($Voip);

  my $user = $Voip->user_info($FORM{UID});

  if ($user->{TOTAL} == 0 || $FORM{new}) {
    $html->message('info', $lang{INFO}, $lang{NOT_ACTIVE});
    $user               = $Voip->defaults();
    $user->{ACTION}     = 'add';
    $user->{LNG_ACTION} = $lang{ACTIVATE};
    $user->{TP_NAME}    = $html->form_select(
      'TP_ID',
      {
        SELECTED  => $FORM{TP_ID},
        SEL_LIST  => $Voip->tp_list({ COLS_NAME => 1 }),
        SEL_KEY   => 'tp_id',
        SEL_VALUE => 'id,name',
        NO_ID     => 1,
        MENU      => get_function_index('voip_tp')
      }
    );
  }
  else {
    $user->{NUMBER} = $FORM{NUMBER};
    $user->{CHANGE_TP_BUTTON} = $html->button($lang{CHANGE}, 'UID=' . $user->{UID} . "&index=" . get_function_index('voip_chg_tp'), { class => 'change' });

    $user->{DEL_BUTTON} = $html->button(
      $lang{DEL},
      "index=$index&del=1&UID=$user->{UID}",
      {
        MESSAGE => "$lang{DEL} $lang{SERVICE} Voip $lang{FOR} $lang{USER} $user->{UID}?",
        class   => 'btn btn-danger'
      }
    );

    $user->{ACTION}     = 'set';
    $user->{LNG_ACTION} = $lang{CHANGE};
  }

  $user->{ALLOW_ANSWER} = ' checked' if ($user->{ALLOW_ANSWER} && $user->{ALLOW_ANSWER} == 1);
  $user->{ALLOW_CALLS}  = ' checked' if ($user->{ALLOW_CALLS}  && $user->{ALLOW_CALLS} == 1);
  $user->{STATUS_SEL}   = $html->form_select(
    'DISABLE',
    {
      SELECTED => $user->{DISABLE} || 0,
      SEL_HASH => {
        0 => $service_status[0],
        1 => $service_status[1],
        2 => $service_status[2],
        3 => $service_status[3],
      },
      NO_ID => 1,
      STYLE => \@service_status_colors,
    }
  );

  if ($user->{DISABLE} > 0) {
    $user->{STATUS_COLOR} = $service_status_colors[ $user->{DISABLE} ];
  }

  $user->{NAS_SEL} = $html->form_select(
    'PROVISION_NAS_ID',
    {
      SELECTED => $user->{PROVISION_NAS_ID} || $FORM{PROVISION_NAS_ID} || '',
      SEL_LIST  => $Nas->list({ TYPE => 'ls_pap2t;ls_spa8000', COLS_NAME => 1, SHORT => 1, NAS_NAME => '_SHOW', PAGE_ROWS => 10000 }),
      SEL_KEY   => 'nas_id',
      SEL_VALUE => 'nas_name',
      MAIN_MENU => get_function_index('form_nas'),
      MAIN_MENU_ARGV => ($user->{NAS_ID}) ? "chg=$user->{NAS_ID}" : ''
    }
  );

  $user->{PROVISION} = $html->tpl_show(templates('form_show_hide'), {
      CONTENT     => $html->tpl_show(_include('voip_provision_user', 'Voip'), $user, { OUTPUT2RETURN => 1 }),
      NAME        => 'Provision',
      ID          => 'PROVISION',
      BUTTON_ICON => 'minus'
    },
    { OUTPUT2RETURN => 1 }
  );

  $html->tpl_show(_include('voip_user', 'Voip'), { %{$attr || {}}, %{$user} });

  if ($user->{TOTAL} && $user->{TOTAL} > 0) {
    voip_yate_users_list();
  }

  return 1;
}

1;
