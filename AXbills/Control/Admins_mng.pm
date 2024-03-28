=head1 NAME

  Admin manage functions

=cut

use strict;
use warnings FATAL => 'all';

use AXbills::Base qw(in_array load_pmodule days_in_month);
use AXbills::Defs;
use AXbills::Misc;

our (
  $db,
  $admin,
  %lang,
  %permissions,
  @WEEKDAYS,
  @MONTHES,
  %FORM,
  @status,
  $pages_qs
);

our AXbills::HTML $html;

#**********************************************************
=head2 form_admins() - Admins mange form

=cut
#**********************************************************
sub form_admins {

  my $Employees;

  if (in_array('Employees', \@MODULES)) {
    require Employees;
    Employees->import();
    $Employees = Employees->new($db, $admin, \%conf);
  }

  my $admin_form = Admins->new($db, \%conf);
  $admin_form->{ACTION} = 'add';
  $admin_form->{LNG_ACTION} = $lang{ADD};

  # Should be sent with another name to prevent authorization
  if (defined $FORM{API_KEY_NEW}) {
    $FORM{API_KEY} = $FORM{API_KEY_NEW};
  }

  if ($FORM{add} && !$FORM{subf}) {
    $admin_form->{AID} = $admin->{AID};
    if (!$FORM{A_LOGIN}) {
      $html->message('err', $lang{ERROR}, "$lang{ERR_WRONG_DATA} $lang{ADMIN} $lang{LOGIN}");
    }
    else {
      $admin_form->add({ %FORM, DOMAIN_ID => $FORM{DOMAIN_ID} || $admin->{DOMAIN_ID} });
      if (!$admin_form->{errno}) {
        $html->message('info', $lang{INFO}, "$lang{ADDED}: $FORM{A_LOGIN}");
        $FORM{AID} = $admin_form->{AID};
      }
    }

    delete $admin_form->{AID};
  }

  if ($FORM{AID}) {
    $admin_form->info($FORM{AID});
    return 0 if _error_show($admin_form);

    if (!defined($FORM{DOMAIN_ID})) {
      $FORM{DOMAIN_ID} = $admin_form->{DOMAIN_ID} if ($admin_form->{DOMAIN_ID});
    }

    $pages_qs = "&AID=$admin_form->{AID}" . (($FORM{subf}) ? "&subf=$FORM{subf}" : '');
    my $A_LOGIN = $html->form_main({
      CONTENT => sel_admins({ EX_PARAMS => { 'AUTOSUBMIT' => 'form' } }),
      HIDDEN  => {
        index => $index,
        subf  => $FORM{subf},
        show  => 1,
      },
      class   => 'form-inline ml-auto flex-nowrap',
    });

    $LIST_PARAMS{AID} = $admin_form->{AID};
    my @admin_menu = (
      $lang{INFO} . "::AID=$admin_form->{AID}:change",
      $lang{LOG} . ':' . get_function_index('form_changes') . ":AID=$admin_form->{AID}:history",
      $lang{FEES} . ":3:AID=$admin_form->{AID}:fees",
      $lang{PAYMENTS} . ":2:AID=$admin_form->{AID}:payments",
      $lang{PERMISSION} . ":52:AID=$admin_form->{AID}:permissions",
      $lang{PAYMENT_TYPE} . ":146:AID=$admin_form->{AID}:payment_type",
      $lang{PASSWD} . ":54:AID=$admin_form->{AID}:password",
    );

    push @admin_menu, $lang{GROUP} . ":58:AID=$admin_form->{AID}:users" if (!$admin->{GID} || ($permissions{0} && $permissions{0}{28}));
    push @admin_menu, $lang{ACCESS} . ":59:AID=$admin_form->{AID}:",
      'Paranoid' . ':' . get_function_index('form_admins_full_log_analyze') . ":AID=$admin_form->{AID}:",
      $lang{CONTACTS} . ":61:AID=$admin_form->{AID}:contacts";
    push @admin_menu, $lang{AUTH_HISTORY} . ":115:AID=$admin_form->{AID}:form_admin_auth_history";
    if (in_array('Multidoms', \@MODULES)) {
      push @admin_menu, $lang{DOMAINS} . ":113:AID=$admin_form->{AID}:domains";
    }
    if (in_array('Msgs', \@MODULES)) {
      push @admin_menu, "$lang{MESSAGES}:" . get_function_index('msgs_admin') . ":AID=$admin_form->{AID}:msgs";
    }


    func_menu(
      {
        $lang{NAME} => $A_LOGIN
      },
      \@admin_menu,
      { f_args => { ADMIN => $admin_form } }
    );

    delete $FORM{change} if (defined $FORM{newpassword} && !form_passwd({ ADMIN => $admin_form }));

    if ($FORM{subf}) {
      return 0;
    }
    elsif ($FORM{change}) {
      $admin_form->{MAIN_SESSION_IP} = $admin->{SESSION_IP};

      # Check it was default password
      if ($FORM{newpassword} && !$conf{DEFAULT_PASSWORD_CHANGED} && $FORM{AID} == 1 && $FORM{newpassword} ne 'axbills') {
        $Conf->config_add({ PARAM => 'DEFAULT_PASSWORD_CHANGED', VALUE => 1, REPLACE => 1 });
        _error_show($Conf);
        $conf{DEFAULT_PASSWORD_CHANGED} = 1;
      }

      $FORM{G2FA} = '' if ($FORM{g2fa_remove});

      $admin_form->change({ %FORM });
      if (!$admin_form->{errno}) {
        $html->message('info', $lang{CHANGED}, "$lang{CHANGED} ");
      }
    }
    $admin_form->{ACTION} = 'change';
    $admin_form->{LNG_ACTION} = $lang{CHANGE};
  }
  elsif ($FORM{del} && $FORM{COMMENTS}) {
    if ($FORM{del} == $conf{SYSTEM_ADMIN_ID}) {
      $html->message('err', $lang{ERROR}, "Can't delete system admin. Check " . '$conf{SYSTEM_ADMIN_ID}=1;');
    }
    else {
      $admin_form->{AID} = $admin->{AID};
      $admin_form->del($FORM{del});
      if (!$admin_form->{errno}) {
        $html->message('info', $lang{DELETED}, "$lang{DELETED}");
      }
    }
  }
  elsif ($FORM{REGISTER_TELEGRAM}) {
    $admin_form->change({ AID => $admin->{AID}, TELEGRAM_ID => $FORM{telegram_id} });
    $html->message('info', $lang{SUCCESS}, "Telegram ID $lang{ADDED}");
    return 1;
  }

  _error_show($admin_form);

  $admin_form->{PASPORT_DATE} = $html->date_fld2('PASPORT_DATE', {
    FORM_NAME       => 'admin_form',
    WEEK_DAYS       => \@WEEKDAYS,
    MONTHES         => \@MONTHES,
    DATE            => $admin_form->{PASPORT_DATE},
    NO_DEFAULT_DATE => 1
  });

  if (in_array('Employees', \@MODULES)) {
    $admin_form->{POSITIONS} = $html->form_select('POSITION', {
      SELECTED    => $FORM{POSITION} || $admin_form->{POSITION},
      SEL_LIST    => translate_list($Employees->position_list({ COLS_NAME => 1 }), 'position'),
      SEL_KEY     => 'id',
      SEL_VALUE   => 'position',
      NO_ID       => 1,
      SEL_OPTIONS => { '0' => '--' },
      MAIN_MENU   => get_function_index('employees_positions')
    });

    $admin_form->{DEPARTMENTS} = $html->form_select('DEPARTMENT', {
      SELECTED    => $FORM{DEPARTMENT} || $admin_form->{DEPARTMENT},
      SEL_LIST    => $Employees->employees_department_list({ NAME => '_SHOW', COLS_NAME => 1 }),
      SEL_KEY     => 'id',
      SEL_VALUE   => 'name',
      NO_ID       => 1,
      SEL_OPTIONS => { '0' => '--' }
    });

    $admin_form->{POSITION_ADD_LINK} = $html->button('', 'index=' . get_function_index('employees_positions'), {
      ICON           => 'fa fa-plus',
      NO_LINK_FORMER => 1,
      target         => '_blank',
    });
  }

  if ($conf{ADMIN_NEW_ADDRESS_FORM}) {
    $admin_form->{ADDRESS_FORM} = form_address_select2({ %FORM, %{$admin_form} });
    $admin_form->{OLD_ADDRESS_CLASS} = 'd-none';
  }
  else {
    $admin_form->{ADDRESS_CARD_CLASS} = 'd-none';
  }

  $admin_form->{FULL_LOG} = ($admin_form->{FULL_LOG}) ? 'checked' : '';
#  $admin_form->{DISABLE} = (defined($admin_form->{DISABLE}) && $admin_form->{DISABLE} > 0) ? 'checked' : '';
  my %admin_statuses_select = (0 => $lang{ACTIV}, 1 => $lang{DISABLE}, 2 => $lang{FIRED});
  $admin_statuses_select{'>=0'} = $lang{ALL} if $FORM{search_form} ;

  $admin_form->{DISABLE_SELECT} = $html->form_select('DISABLE', {
    SELECTED => $admin_form->{DISABLE},
    SEL_HASH => \%admin_statuses_select,
    NO_ID    => 1,
  });
  $admin_form->{GROUP_SEL} = sel_groups({ GID => $admin_form->{GID}, SKIP_MULTISELECT => 1 });

  if ($admin_form->{DOMAIN_ID} && $admin->{DOMNAIN_ID}) {
    $admin_form->{DOMAIN_SEL} = $html->button($admin_form->{DOMAIN_NAME},
      'index=' . get_function_index('multidoms_domains') . "&chg=$admin_form->{DOMAIN_ID}", { BUTTON => 1 });
  }
  elsif (in_array('Multidoms', \@MODULES)) {
    load_module('Multidoms', $html);
    $admin_form->{DOMAIN_SEL} = multidoms_domains_sel({
      SHOW_ID => 1, DOMAIN_ID => $admin_form->{DOMAIN_ID}
    });
  }
  else {
    $admin_form->{DOMAIN_SEL} = '';
  }

  $admin_form->{INDEX} = 50;
  $admin_form->{HEADER_NAME} = $lang{ADMINS};

  $admin_form->{G2FA_CHECKED} = $admin_form->{G2FA} ? "checked" : '';
  $admin_form->{G2FA} = $admin_form->{G2FA} || $FORM{G2FA} || uc(AXbills::Base::mk_unique_value(32));
  $admin_form->{PATTERN} = ($conf{ADMINNAMEREGEXP}) ? ($conf{ADMINNAMEREGEXP}) : '^\S{1,}$';

  if($FORM{show_add_form} || $FORM{AID}){
    $html->tpl_show(templates('form_admin'), $admin_form);
  }
  elsif($FORM{search_form}){
    $admin_form->{DOMAIN_HIDDEN} = 'hidden'; # hide domain div from search template
    $admin_form->{DOMAIN_SEL} = '';          # remove domain select from search template

    form_search({
      TPL => $html->tpl_show(templates('form_admin_search'), { %FORM, %$admin_form, }, { OUTPUT2RETURN => 1 }),
    })
  }

  if($FORM{search}){
    %LIST_PARAMS = %FORM;
    $LIST_PARAMS{PHONE} = "*$LIST_PARAMS{PHONE}*" if $LIST_PARAMS{PHONE};
    $LIST_PARAMS{API_KEY} = $FORM{API_KEY_NEW};
    $LIST_PARAMS{ADMIN_NAME} = $FORM{A_FIO};
    $LIST_PARAMS{LOGIN} = $FORM{ID};
  }

  if($FORM{DISABLE} && $FORM{DISABLE} != 0){
    my $admins_online_list = $admin->online_list();
    foreach my $line (@$admins_online_list) {
      if ($line->{aid} && $line->{sid} && $line->{aid} == $FORM{AID}){
        $admin_form->online_del({ SID => $line->{sid} });
      }
    }
  }

  my $list = $admin_form->admins_groups_list({ ALL => 1, COLS_NAME => 1 , SORT=>$FORM{sort}});
  my %admin_groups = ();
  foreach my $line (@$list) {
    $admin_groups{ $line->{aid} } .= ", $line->{gid}:$line->{name}";
  }

  delete($LIST_PARAMS{AID});
  delete $admin_form->{COL_NAMES_ARR};

  if (in_array('Employees', \@MODULES)) {
    $admin->{SHOW_EMPLOYEES} = 1;
  }

  my @status_bar = ("$lang{ALL}:index=$index&SHOW_ALL=1&$pages_qs", "$lang{ACTIV}:index=$index&$pages_qs");

  if(!$FORM{search}) {
    if (!$FORM{SHOW_ALL}) {
      $LIST_PARAMS{DISABLE} = 0;
    }
    else {
      $pages_qs .= "&SHOW_ALL=1";
    }
  }

  my %EXT_TITLES = (
    login            => $lang{LOGIN},
    name             => $lang{FIO},
    position         => $lang{POSITION},
    regdate          => $lang{REGISTRATION},
    disable          => $lang{STATUS},
    aid              => '#',
    g_name           => $lang{GROUPS},
    domain_name      => 'Domain',
    start_work       => $lang{BEGIN},
    gps_imei         => 'GPS IMEI',
    birthday         => $lang{BIRTHDAY},
    api_key          => 'API_KEY',
    telegram_id      => 'Telegram ID',
    rfid_number      => "RFID $lang{NUMBER}",
    department_name  => $lang{DEPARTMENT},
    pasport_num      => "$lang{PASPORT} $lang{NUM}",
    pasport_date     => "$lang{PASPORT} $lang{DATE}",
    pasport_grant    => "$lang{PASPORT} $lang{GRANT}",
    inn              => $lang{INN},
    max_rows         => $lang{MAX_ROWS},
    min_search_chars => $lang{MIN_SEARCH_CHARS},
    max_credit       => "$lang{MAX} $lang{CREDIT}",
    credit_days      => "$lang{MAX} $lang{CREDIT} $lang{DAYS}",
    comments         => $lang{COMMENTS},
    phone            => $lang{PHONE},
    # cell_phone       => $lang{CELL_PHONE},
    email            => 'Email',
    sip_number       => 'SIP',
    avatar_link      => $lang{AVATAR},
  );

  if ($conf{ADMIN_NEW_ADDRESS_FORM}) {
    $EXT_TITLES{address_full} = $lang{ADDRESS};
    $EXT_TITLES{address_flat} = $lang{ADDRESS_FLAT};
  }
  else {
    $EXT_TITLES{address} = $lang{ADDRESS};
  }

  my AXbills::HTML $table;
  my $admins_list;
  ($table, $admins_list) = result_former({
    INPUT_DATA      => $admin,
    FUNCTION        => 'list',
    BASE_FIELDS     => 4,
    FUNCTION_FIELDS => 'permission,log,passwd,info,del',
    SKIP_USER_TITLE => 1,
    EXT_TITLES      => \%EXT_TITLES,
    TABLE => {
      width          => '100%',
      caption        => $lang{ADMINS},
      qs             => $pages_qs,
      ID             => 'ADMINS_LIST',
      SHOW_FULL_LIST => 1,
      header         => \@status_bar,
      MENU           => "$lang{ADD}:index=$index&show_add_form=1:add;$lang{SEARCH}:search_form=1&index=$index:search"
    },
  });
  my $count = $admin->{TOTAL};

  foreach my $line (@$admins_list) {
    my @fields_array = ();
    for (my $i = 0; $i < 4 + $admin->{SEARCH_FIELDS_COUNT}; $i++) {
      my $field_name = $admin->{COL_NAMES_ARR}->[$i] || '';

      if ($field_name eq 'avatar_link'){
        my $avatar = ($line->{avatar_link}) ? "/images/$line->{avatar_link}" : '/styles/default/img/admin/avatar5.png';
        $line->{avatar_link} = "<img src='$avatar' class='img-circle ' alt='User Image' style='width: 40px;'>";
      }

      if ($field_name eq 'disable' && $line->{disable} =~ /\d+/) {
#        $line->{disable} = $status[ $line->{disable} ];
        my %disable_status = (
          '0'  => "$lang{ACTIV}:text-success",
          '1'  => "$lang{DISABLE}:text-danger",
          '2'  => "$lang{FIRED}:text-warning",
        );
        my($value, $color) = split(/:/, $disable_status{$line->{disable}} || ":");
        $line->{disable} = $html->color_mark($value, $color);
      }
      elsif ($field_name eq 'gname') {
        $line->{gname} .= $admin_groups{ $line->{aid} },
      }
      elsif($field_name eq 'position'){
        $line->{position} = _translate($line->{position});
      }

      push @fields_array, $line->{$field_name};
    }

    my $geo_button = '';
    if (in_array('Employees', \@MODULES)) {
      $geo_button = $html->button($lang{GEO}, "index=" . get_function_index('employees_geolocation') . "&eid=$line->{aid}", { ICON => 'fa fa-map-marker-alt' })
    }

    $table->addrow(@fields_array,
      $html->button($lang{PERMISSION}, "index=$index&subf=52&AID=$line->{aid}", { class => 'permissions', ICON => 'fa fa-check' })
        . $geo_button
        . $html->button($lang{LOG}, "index=$index&subf=51&AID=$line->{aid}", { class => 'history' })
        . $html->button($lang{PASSWD}, "index=$index&subf=54&AID=$line->{aid}", { class => 'password' })
        . $html->button($lang{INFO}, "index=$index&AID=$line->{aid}", { class => 'change' })
        . $html->button($lang{DEL}, "index=$index&del=$line->{aid}", { MESSAGE => "$lang{DEL} $line->{aid}?", class => 'del' })
    );
  }

  print $table->show();

  $table = $html->table({
    width => '100%',
    rows  => [ [ "$lang{TOTAL}:", $html->b($count) ] ]
  });

  print $table->show();

  system_info();

  return 1;
}

#**********************************************************
=head2 form_admins_group($attr);

=cut
#**********************************************************
sub form_admins_groups {
  my ($attr) = @_;

  if (!defined($attr->{ADMIN})) {
    $FORM{subf} = 58;
    $index = 50;
    form_admins();
    return 1;
  }

  my Admins $admin_ = $attr->{ADMIN};

  if ($FORM{change}) {
    $admin_->admin_groups_change({ %FORM });
    if (_error_show($admin_)) {
      $html->message('info', $lang{CHANGED}, "$lang{CHANGED} GID: [$FORM{GID}]");
    }
  }

  my $table = $html->table({
    width   => '100%',
    caption => $lang{GROUP},
    title   => [ 'ID', $lang{NAME} ],
  });

  my $list = $admin_->admins_groups_list({ 
    AID => $LIST_PARAMS{AID},
    DESC      => $FORM{desc},
    SORT      => $FORM{sort}
  });
  my %admins_group_hash = ();

  foreach my $line (@$list) {
    $admins_group_hash{ $line->[0] } = 1;
  }

  $list = $users->groups_list({ 
    DOMAIN_ID => $admin_->{DOMAIN_ID} || undef, 
    DESC      => $FORM{desc},
    SORT      => $FORM{sort},
    GID             => '_SHOW',
    NAME            => '_SHOW',
    DESCR           => '_SHOW',
    ALLOW_CREDIT    => '_SHOW',
    DISABLE_PAYSYS  => '_SHOW',
    DISABLE_CHG_TP  => '_SHOW',
    USERS_COUNT     => '_SHOW',
    COLS_NAME       => 1
  });

  foreach my $line (@$list) {
    $table->addrow($html->form_input('GID', $line->{gid}, { TYPE => 'checkbox', STATE => (defined($admins_group_hash{ $line->{gid} })) ? 'checked' : undef }, ) . $line->{gid},
      $line->{name});
  }

  print $html->form_main(
    {
      CONTENT => $table->show({ OUTPUT2RETURN => 1 }),
      HIDDEN  => {
        index => $index,
        AID   => $FORM{AID},
        subf  => $FORM{subf}
      },
      SUBMIT  => { change => "$lang{CHANGE}" }
    }
  );

  return 1;
}

#**********************************************************
=head2 form_admin_auth_history($attr);

=cut
#**********************************************************
sub form_admin_auth_history {
  my ($attr) = @_;

  my Admins $admin_ = $attr->{ADMIN};
  my $aid = $FORM{AID} || 0;
  result_former({
    INPUT_DATA      => $admin_,
    FUNCTION        => 'full_log_list',
    FUNCTION_PARAMS => {
      FUNCTION_NAME => 'ADMIN_AUTH',
    },
    DEFAULT_FIELDS  => 'DATETIME,IP,SID',
    EXT_TITLES => {
      ip       => 'IP',
      datetime => $lang{DATE},
      sid      => 'SID'
    },
    SKIP_USER_TITLE   => 1,
    TABLE           => {
      width   => '100%',
      caption => $lang{AUTH_HISTORY},
      ID      => 'ADMIN_ACCESS_LOG',
      qs      => "&AID=$aid&subf=". ($FORM{subf} || q{}),
      EXPORT  => 1,
    },
    MAKE_ROWS       => 1,
    TOTAL           => 1
  });
}

#**********************************************************
=head2 form_admins_full_log($attr) - Admin fulll log

=cut
#**********************************************************
sub form_admins_full_log {
  my ($attr) = @_;

  if (!defined($attr->{ADMIN})) {
    $FORM{subf} = get_function_index('form_admins_full_log');
    $index = 50;
    form_admins();
    return 1;
  }

  my Admins $admin_ = $attr->{ADMIN};
  $admin_->{ACTION} = 'add';
  $admin_->{LNG_ACTION} = $lang{ADD};

  if ($FORM{add}) {
    $admin_->full_log_add({ %FORM });
    if (!$admin_->{errno}) {
      $html->message('info', $lang{ADDED}, "$lang{ADDED} $FORM{IP}");
    }
  }
  elsif ($FORM{change}) {
    $admin_->full_log_change({ %FORM });
    if (!$admin_->{errno}) {
      $html->message('info', $lang{ADDED}, "$lang{CHANGED} $FORM{IP}");
    }
  }
  elsif ($FORM{chg}) {
    $admin_->full_log_info($FORM{chg}, { %FORM });
    if (!$admin_->{errno}) {
      $html->message('info', $lang{ADDED}, "$lang{INFO} $FORM{IP}");
      $admin_->{ACTION} = 'change';
      $admin_->{LNG_ACTION} = $lang{CHANGE};
    }
  }
  elsif ($FORM{del} && $FORM{COMMENTS}) {
    $admin_->full_log_del({ ID => $FORM{del} });
    if (!$admin_->{errno}) {
      $html->message('info', $lang{INFO}, "$lang{DELETED} [$FORM{del}]");
    }
  }

  _error_show($admin_);

  if ($FORM{search_form}) {
    form_search({
      HIDDEN_FIELDS => {
        subf => $FORM{subf},
        AID  => $FORM{AID}
      }
    });
  }

  if (!$FORM{sort}) {
    $LIST_PARAMS{SORT} = 1;
    $LIST_PARAMS{DESC} = 'desc';
  }

  result_former({
    INPUT_DATA      => $admin_,
    FUNCTION        => 'full_log_list',
    DEFAULT_FIELDS  => 'DATETIME,FUNCTION_NAME,PARAMS,IP,SID',
    FUNCTION_FIELDS => 'change,del',
    SELECT_VALUE    => {
      disable => { 0 => $lang{ENABLE}, 1 => $lang{DISABLE} } },
    TABLE           => {
      width   => '100%',
      caption => "Paranoid log",
      ID      => 'ADMIN_PARANOID_LOG',
      qs      => "&AID=$FORM{AID}&subf=$FORM{subf}",
      EXPORT  => 1,
      MENU    => "$lang{SEARCH}:search_form=1&index=$index&AID=$FORM{AID}&subf=$FORM{subf}:search"
    },
    MAKE_ROWS       => 1,
    TOTAL           => 1
  });

  return 1;
}

#**********************************************************
=head2 form_admins_full_log_analyze($attr)

=cut
#**********************************************************
sub form_admins_full_log_analyze {

  if (!$permissions{4}{4}) {
    $html->message('err', $lang{ERROR}, $lang{ERR_ACCESS_DENY});
    return 1;
  };

  my $admin_ = Admins->new($db, \%conf);
  _error_show($admin_);

  my $date_picker = $html->form_daterangepicker({
    NAME => 'FROM_DATE/TO_DATE'
  });

  # TODO: #3944 rereview
  my $A_LOGIN = $html->form_main({
    CONTENT => $date_picker . sel_admins(),
    HIDDEN  => { index => $index },
    SUBMIT  => { show => $lang{SHOW} },
    class   => 'form-inline ml-auto flex-nowrap',
  });

  my $saved_subf = $FORM{subf};
  delete $FORM{subf};
  func_menu({ $lang{NAME} => $A_LOGIN }, {}, {});

  if (!$FORM{AID}) {
    return 1;
  }

  $LIST_PARAMS{AID} = $FORM{AID};
  $LIST_PARAMS{FROM_DATE} = $FORM{FROM_DATE};
  $LIST_PARAMS{TO_DATE} = $FORM{TO_DATE};

  if ($FORM{details}) {
    $LIST_PARAMS{FUNCTION_NAME} = $FORM{details};
  }
  else {
    $LIST_PARAMS{FUNCTION_NAME} = "!msgs_admin";
  }


  my $index_for_search = $saved_subf || $index;

  if ($FORM{search_form}) {
    # Result former may not normal working with AID, and it creates duplicates of AID
    my ($splitted_aid, undef) = split(/,\s?/, $FORM{AID} || '0', 2);

    if ($FORM{FROM_DATE} && !$FORM{TO_DATE}) {
      my ($y, $m) = split('-', $DATE);
      $FORM{TO_DATE} = "$y-$m-" . days_in_month();
    }

    my %paranoid_form = ();
    $paranoid_form{FROM_DATE} = $html->date_fld2('FROM_DATE', {
      FORM_NAME       => 'admin_form_paranoid',
      NO_DEFAULT_DATE => 1
    });

    $paranoid_form{TO_DATE} = $html->date_fld2('TO_DATE', {
      FORM_NAME       => 'admin_form_paranoid',
      NO_DEFAULT_DATE => 1
    });

    form_search({
      TPL => $html->tpl_show(templates('form_admins_paranoid_search'), {
        %FORM,
        %paranoid_form,
        AID   => $splitted_aid,
        INDEX => $index_for_search,
      }, { OUTPUT2RETURN => 1 }),
    });
  }

  if ($FORM{list} || $FORM{search_form}) {
    result_former({
      INPUT_DATA     => $admin_,
      FUNCTION       => 'full_log_list',
      DEFAULT_FIELDS => 'DATETIME,FUNCTION_NAME,PARAMS,IP,FUNCTION_INDEX,SID',
      EXT_TITLES => {
        datetime       => $lang{DATE},
        function_name  => 'function_name',
        function_index => 'function_index',
        ip             => 'IP',
        sid            => 'SID'
      },
      FILTER_COLS    => {
        function_name => '_paranoid_log_function_filter',
        params        => '_paranoid_log_params_filter'
      },
      SKIP_USER_TITLE   => 1,
      TABLE          => {
        width   => '100%',
        caption => 'Paranoid log',
        qs      => "$pages_qs&AID=$FORM{AID}&list=1",
        ID      => 'ADMIN_PARANOID_LOG_LIST',
        MENU    => "$lang{STATS}:index=$index&AID=$FORM{AID}:btn bg-olive margin;$lang{SEARCH}:index=$index_for_search&search_form=1&AID=$FORM{AID}:search;",
      },
      MAKE_ROWS      => 1,
      SKIP_TOTAL     => 1,
      TOTAL          => 1,
    });
    return 1;
  }

  my (undef, $list) = result_former({
    INPUT_DATA     => $admin_,
    FUNCTION       => 'full_log_analyze',
    DEFAULT_FIELDS => 'DATETIME,FUNCTION_NAME,PARAMS,COUNT',
    SKIP_PAGES     => 1,
    FILTER_COLS    => {
      function_name => '_paranoid_log_function_filter',
      params        => '_paranoid_log_params_filter'
    },
    TABLE          => {
      width   => '100%',
      caption => "Paranoid log",
      ID      => 'ADMIN_PARANOID_LOG',
      MENU    => "$lang{LIST}:index=$index_for_search&AID=$FORM{AID}&list=1&sort=1&desc=DESC:btn bg-olive margin;$lang{SEARCH}:index=$index_for_search&search_form=1&AID=$FORM{AID}:search;",
      qs      => "&AID=$FORM{AID}",
    },
    MAKE_ROWS      => 1,
    SKIP_TOTAL     => 1,
    TOTAL          => 1
  });

  my %chartdata = ();
  my @xtext = ();
  foreach (@$list) {
    push @{$chartdata{count}}, $_->{count};
    if ($FORM{details}) {
      $_->{params} //= '';
      $_->{params} =~ s/\n/&/g;
      push @xtext, $_->{params};
    }
    else {
      push @xtext, $_->{function_name};
    }
  };

  $html->make_charts_simple({
    DATA         => \%chartdata,
    X_TEXT       => \@xtext,
    TYPES        => { count => 'bar' },
    SKIP_COMPARE => 1,
  });

  return 1;
}

#**********************************************************
=head2 form_admins_access($attr);

=cut
#**********************************************************
sub form_admins_access {
  my ($attr) = @_;

  if (!defined($attr->{ADMIN})) {
    $FORM{subf} = 59;
    $index = 50;
    form_admins();
    return 1;
  }

  my Admins $admin_ = $attr->{ADMIN};
  $admin->{ACTION} = 'add';
  $admin->{LNG_ACTION} = $lang{ADD};

  if ($FORM{add}) {
    $admin_->access_add({ %FORM });
    if (!$admin_->{errno}) {
      $html->message('info', $lang{ADDED}, "$lang{ADDED} $FORM{IP}");
    }
  }
  elsif ($FORM{change}) {
    $admin_->access_change({ %FORM });
    if (!$admin_->{errno}) {
      $html->message('info', $lang{ADDED}, "$lang{CHANGED} $FORM{IP}");
    }
  }
  elsif ($FORM{chg}) {
    $admin_->access_info($FORM{chg}, { %FORM });
    if (!$admin_->{errno}) {
      $admin_->{ACTION} = 'change';
      $admin_->{LNG_ACTION} = $lang{CHANGE};
    }
  }
  elsif ($FORM{del} && $FORM{COMMENTS}) {
    $admin_->access_del({ ID => $FORM{del} });
    if (!$admin_->{errno}) {
      $html->message('info', $lang{INFO}, "$lang{DELETED} [$FORM{del}]");
    }
  }
  else {
    $admin_->{BEGIN} = '00:00:00';
    $admin_->{END} = '24:00:00';
    $admin_->{IP} = '0.0.0.0';
  }

  _error_show($admin_);

  my %DAY_NAMES = (
    0 => "$lang{ALL}",
    1 => "$WEEKDAYS[7]",
    2 => "$WEEKDAYS[1]",
    3 => "$WEEKDAYS[2]",
    4 => "$WEEKDAYS[3]",
    5 => "$WEEKDAYS[4]",
    6 => "$WEEKDAYS[5]",
    7 => "$WEEKDAYS[6]",
    8 => "$lang{HOLIDAYS}");

  $admin_->{SEL_DAYS} = $html->form_select('DAY', {
    SELECTED     => $admin_->{DAY} || $FORM{DAY} || 0,
    SEL_HASH     => \%DAY_NAMES,
    ARRAY_NUM_ID => 1
  });

  $admin_->{BIT_MASK_SEL} = $html->form_select('BIT_MASK', {
    SELECTED  => $admin_->{BIT_MASK} || $FORM{BIT_MASK} || 0,
    SEL_ARRAY => [ 0 .. 32 ],
  });

  $admin_->{DISABLE} = ($admin_->{DISABLE}) ? 'checked' : '';

  $html->tpl_show(templates('form_admin_access'), $admin_);

  result_former({
    INPUT_DATA      => $admin_,
    FUNCTION        => 'access_list',
    BASE_FIELDS     => 6,
    FUNCTION_FIELDS => 'change,del',
    SELECT_VALUE    => {
      day     => \%DAY_NAMES,
      disable => { 0 => $lang{ENABLE}, 1 => $lang{DISABLE} } },
    TABLE           => {
      width   => '100%',
      caption => "$lang{ADMIN} $lang{ACCESS}",
      ID      => 'ADMIN_ACCESS',
      qs      => "&AID=$FORM{AID}&subf=$FORM{subf}"
    },
    MAKE_ROWS       => 1,
    TOTAL           => 1
  });

  return 1;
}

#**********************************************************
=head2 form_admin_permissions($attr); - Admin permitions

=cut
#**********************************************************
sub form_admin_permissions {
  my ($attr) = @_;

  my @actions = (
    [
      $lang{INFO},
      $lang{ADD},
      $lang{LIST},
      $lang{PASSWD},
      $lang{CHANGE},
      $lang{DEL},
      $lang{ALL},
      $lang{MULTIUSER_OP},
      "$lang{SHOW} $lang{DELETED}",
      $lang{CREDIT},
      $lang{TARIF_PLANS},
      $lang{REDUCTION},
      "$lang{SHOW} $lang{DEPOSIT}",
      $lang{WITHOUT_CONFIRM},
      "$lang{DELETED} $lang{SERVICE}",
      "$lang{CHANGE} $lang{BILL}",
      $lang{COMPENSATION},
      $lang{EXPORT},
      $lang{STATUS},                 # 18
      "$lang{ACTIVATE} $lang{DATE}", # 19
      "$lang{EXPIRE} $lang{DATE}",   # 20
      $lang{BONUS},
      $lang{PORT_CONTROL}, # 22
      $lang{REBOOT},
      $lang{ADDITIONAL_INFORMATION}, # 24 user extended info form
      "$lang{PERSONAL} $lang{TARIF_PLAN}",
      $lang{PERSONAL_INFO},
      "$lang{CHANGE} $lang{LOGIN}",
      "$lang{SHOW} $lang{GROUPS}",
      "", # 29 permission is empty !!!
      "$lang{SHOW} $lang{LOG}",
      "$lang{DEL} $lang{COMMENTS}",
      "$lang{ADD} $lang{SERVICE}",
      $lang{LAST_LOGIN}, # 33
      $lang{STREETS},
      $lang{BUILDS},
      "$lang{SHOW} $lang{COMPANIES}", # 36
      "$lang{ADD} $lang{COMPANIES}", # 37
      "$lang{EDIT} $lang{COMPANIES}", # 38
      "$lang{DEL} $lang{COMPANIES}", # 39
    ],
    # Users
    [ $lang{LIST}, $lang{ADD}, $lang{DEL}, $lang{ALL}, $lang{DATE}, $lang{IMPORT} ], # Payments
    [ $lang{LIST}, $lang{GET}, $lang{DEL}, $lang{ALL} ],                             # Fees
    [
      $lang{LIST},
      $lang{DEL},
      $lang{PAYMENTS},
      $lang{FEES},
      $lang{EVENTS},
      $lang{SETTINGS},
      $lang{LAST_LOGIN},
      $lang{ERROR_LOG},
      $lang{USERS}
    ], # reports view

    [
      $lang{LIST},
      $lang{ADD},
      $lang{CHANGE},
      $lang{DEL},
      $lang{ADMINS},
      "$lang{SYSTEM} $lang{LOG}",
      $lang{DOMAINS},
      "$lang{TEMPLATES} $lang{CHANGE}",
      $lang{REBOOT_SERVICE},
      "$lang{SHOW} PIN $lang{ICARDS}",
      $lang{MOBILE_PAY},
      "$lang{SEND} SMS"
    ], # system management

    [ $lang{MONITORING}, 'ZAP', $lang{HANGUP} ],

    [ $lang{SEARCH} ], # Search

    [
      $lang{ALL},
      "", # 1 permission is empty !!!
      "$lang{ADD} CRM $lang{STEP}",
      $lang{TIME_SHEET},
      $lang{CRM_SHOW_ALL_LEADS},
      "$lang{SHOW} $lang{EQUIPMENT}",
      "$lang{EDIT} $lang{EQUIPMENT}",
      "$lang{DEL} $lang{EQUIPMENT}",
      "$lang{SHOW} $lang{SALARY}",
      "$lang{SHOW} $lang{AND} $lang{ALL_SALARY} $lang{SALARY}",
    ], # Modules managments

    [ $lang{PROFILE}, $lang{SHOW_ADMINS_ONLINE} ],
    [ $lang{LIST}, $lang{ADD}, $lang{CHANGE}, $lang{DEL} ],
  );

  my %permits = ();

  if (!defined($attr->{ADMIN})) {
    $FORM{subf} = 52;
    $index = 50;
    form_admins();
    return 1;
  }

  my Admins $admin_ = $attr->{ADMIN};

  if ($FORM{del_permits} && $FORM{COMMENTS}) {
    $admin_->del_type_permits($FORM{del_permits}, COMMENTS => $FORM{COMMENTS});
    if (!_error_show($admin_)) {
      $html->message("info", $lang{DELETED}, $lang{TPL_DELETED});
    }
  }
  elsif ($FORM{add_permits} && $FORM{TYPE}) {
    while (my ($k, $v) = each(%FORM)) {
      if ($v eq '1') {
        my ($section_index, $action_index) = split(/_/, $k, 2);
        $permits{$section_index}{$action_index} = 1 if (defined($section_index) && defined($action_index));
      }
    }

    $admin_->del_type_permits($FORM{TYPE});
    delete $admin_->{errno};
    $admin_->{MAIN_AID} = $admin->{AID};
    $admin_->{MAIN_SESSION_IP} = $admin->{SESSION_IP};
    $admin_->set_type_permits(\%permits, $FORM{TYPE});

    if (!_error_show($admin_)) {
      $html->message('info', $lang{INFO}, "$lang{CHANGED}");
    }
  }
  elsif ($FORM{set}) {
    while (my ($k, $v) = each(%FORM)) {
      if ($v && $v eq '1') {
        my ($section_index, $action_index) = split(/_/, $k, 2);
        $permits{$section_index}{$action_index} = 1 if (defined($section_index) && defined($action_index));
        #if ($section_index =~ /^\d+$/ && $section_index >= 0);
      }
    }
    $admin_->{MAIN_AID} = $admin->{AID};
    $admin_->{MAIN_SESSION_IP} = $admin->{SESSION_IP};
    $admin_->set_permissions(\%permits);

    if (!_error_show($admin_)) {
      $html->message('info', $lang{INFO}, "$lang{CHANGED}");
    }
  }

  my $p = $admin_->get_permissions();
  if (_error_show($admin_)) {
    return 0;
  }

  my %ADMIN_TYPES = ();

  my $admins_type_permits_list = $admin->admin_type_permits_list({ COLS_NAME => 1 });
  if (_error_show($admin)) {
    return 0;
  }

  foreach my $item (@$admins_type_permits_list) {
    $item->{type} = _translate($item->{type});
    $ADMIN_TYPES{$item->{type}} = $item->{type} if (!$ADMIN_TYPES{$item->{type}});
  }

  if ($FORM{ADMIN_TYPE}) {
    my %admins_type_permits = ();
    my %admins_modules = ();

    foreach my $item (@$admins_type_permits_list) {
      $admins_type_permits{$item->{type}}->{$item->{section}}->{$item->{actions}} = 1;
      $admins_modules{$item->{type}}->{$item->{module}} = 1 if ($item->{module});
    }

    %permits = %{$admins_type_permits{ $FORM{ADMIN_TYPE} }};
    $admin_->{MODULES} = $admins_modules{ $FORM{ADMIN_TYPE} };

  }
  else {
    %permits = %$p;
  }
  my $buttons = '';
  if ($FORM{ADMIN_TYPE} && $FORM{ADMIN_TYPE} ne $lang{ACCOUNTANT}
    && $FORM{ADMIN_TYPE} ne $lang{SUPPORT}
    && $FORM{ADMIN_TYPE} ne $lang{MANAGER}
    && $FORM{ADMIN_TYPE} ne "$lang{ALL} $lang{PERMISSION}") {

    foreach my $k (sort keys(%ADMIN_TYPES)) {
      my $admin_type_url = $k;
      $admin_type_url =~ s/\+/%2B/g;

      my $btn_css_style = ($FORM{ADMIN_TYPE} && $k && $FORM{ADMIN_TYPE} eq $k) ? 'btn btn-info btn-sm' : 'btn btn-default btn-sm';
      my $url_btn = "index=$index" . (($FORM{subf}) ? "&subf=$FORM{subf}" : '') . "&AID=$FORM{AID}&ADMIN_TYPE=$admin_type_url";

      my $button = $html->button($ADMIN_TYPES{$k}, $url_btn, { class => $btn_css_style }) . '  ';

      my $button_del = ($FORM{ADMIN_TYPE} eq $k)
        ? $html->button("", "index=$index" .
        (($FORM{subf}) ? "&subf=$FORM{subf}" : '') . "&AID=$FORM{AID}&del_permits=$k",
        { ADD_ICON => "fa fa-times", MESSAGE => "$lang{DEL} $ADMIN_TYPES{$k}" }) : '';

      $buttons .= $button;
      $buttons .= $button_del;
    }
  }
  else {
    foreach my $k (sort keys(%ADMIN_TYPES)) {
      my $admin_type_url = $k;
      $admin_type_url =~ s/\+/%2B/g;

      my $btn_css_style = ($FORM{ADMIN_TYPE} && $k && $FORM{ADMIN_TYPE} eq $k) ? 'btn btn-info btn-sm' : 'btn btn-default btn-sm';
      my $url_btn = "index=$index" . (($FORM{subf}) ? "&subf=$FORM{subf}" : '') . "&AID=$FORM{AID}&ADMIN_TYPE=$admin_type_url";
      my $button = $html->button($ADMIN_TYPES{$k}, $url_btn, { class => $btn_css_style }) . '  ';

      $buttons .= $button;
    }
  }

  my $table = $html->table({
    width       => '90%',
    caption     => $lang{PERMISSION},
    title_plain => [ 'ID', $lang{NAME}, $lang{DESCRIBE}, '-' ],
    ID          => 'ADMIN_PERMISSIONS',
  });

  my %describe = ();
  my $content = file_op({
    FILENAME => (defined($FORM{language})) ? "permissions_$FORM{language}.info" : 'permissions_russian.info',
    PATH     => $conf{base_dir} . "/AXbills/main_tpls/",
    ROWS     => 1
  });

  if ($content) {
    foreach (@$content) {
      chomp;
      if ((my ($perm1, $perm2, $desc) = split(/:/)) == 3) {;
        $describe{$perm1}{$perm2} = $desc;
      }
    };
  }

  foreach my $k (sort keys %menu_items) {
    #my $v = $menu_items{$k};

    if (defined($menu_items{$k}{0}) && $k > 0) {
      next if ($k >= 10);

      $table->{rowcolor} = 'bg-primary';
      $table->addrow(
        $html->b("$k:"), $html->b($menu_items{$k}{0}), '', ''
      );
      $k--;

      my $actions_list = $actions[$k];
      my $action_index = 0;
      $table->{rowcolor} = undef;
      foreach my $action (@$actions_list) {
        my $action_describe = $describe{$k}{$action_index} || '';
        $table->addrow(
          $action_index,
          $action,
          $action_describe,
          $html->form_input(
            $k . '_'. $action_index,
            1,
            {
              TYPE          => 'checkbox',
              OUTPUT2RETURN => 1,
              STATE         => (defined($permits{$k}{$action_index})) ? '1' : undef
            }
          )
        );

        $action_index++;
      }
    }
  }

  if (in_array('Multidoms', \@MODULES)) {
    my $k = 10;
    $table->{rowcolor} = 'bg-primary';
    $table->addrow(
      $html->b("10:"), $html->b($lang{DOMAINS}), '', ''
    );
    my $actions_list = $actions[9];
    my $action_index = 0;
    $table->{rowcolor} = undef;
    foreach my $action (@$actions_list) {
      $table->addrow(
        "$action_index",
        "$action",
        '',
        $html->form_input(
          $k . "_$action_index",
          1,
          {
            TYPE          => 'checkbox',
            OUTPUT2RETURN => 1,
            STATE         => (defined($permits{$k}{$action_index})) ? '1' : undef
          }
        )
      );
      $action_index++;
    }
  }

  my $table2 = $html->table({
    width       => '500',
    caption     => "$lang{MODULES}",
    title_plain => [ $lang{NAME}, $lang{VERSION}, '' ],
    ID          => 'ADMIN_MODULES'
  });

  my $i = 0;
  my $version = '';
  foreach my $name (sort @MODULES) {
    $table2->addrow(
      $html->button("$name", '',
        { GLOBAL_URL => 'https://billing.axiostv.ru/' . $name}),
      $version,
      $html->form_input(
        "9_" . $i . "_" . $name,
        '1',
        {
          TYPE          => 'checkbox',
          OUTPUT2RETURN => 1,
          STATE         => ($admin_->{MODULES}{$name}) ? '1' : undef
        }
      )
    );
    $i++;
  }

  $html->tpl_show(templates('admin_add_permits'),
    {
      TABLE1 => $table->show({ OUTPUT2RETURN => 1 }),
      TABLE2 => $table2->show({ OUTPUT2RETURN => 1 }),
      AID    => $FORM{AID},
      subf   => $FORM{subf},
      BUTTONS => $buttons
    }
  );

  return 1;
}

#**********************************************************
=head2 form_admin_payment_types($attr);

=cut
#**********************************************************
sub form_admin_payment_types {
  my ($attr) = @_;
  require Payments;
  Payments->import();
  my $Payments = Payments->new($db, $admin, \%conf);

  if (!defined($attr->{ADMIN})) {
    $FORM{subf} = 146;
    $index = 50;
    form_admins();
    return 1;
  }

  my Admins $admin_ = $attr->{ADMIN};

  if($FORM{set}) {
    $Payments->admin_payment_type_del({
      AID => $FORM{AID}
    });

    if(defined($FORM{ADMIN_PAYMENTS_TYPE})) {
      my @payments_type_ids = split(',', $FORM{ADMIN_PAYMENTS_TYPE});

      foreach (@payments_type_ids) {
        $Payments->admin_payment_type_add({
          AID => $FORM{AID},
          PAYMENTS_TYPE_ID => $_
        });
      }
    }
    if(!$admin_->{errno}) {
      $html->message('info', $lang{CHANGED});
    }
  }

  my $payments_type_list = $Payments->payment_type_list({
    COLS_NAME => 1,
    AID => $admin_->{AID},
  });

  my $table = $html->table({
    width       => '90%',
    caption     => $lang{PAYMENT_TYPE},
    title_plain => [ $lang{NAME}, '-' ],
    ID          => 'ADMIN_PERMISSIONS',
  });

  foreach my $payments_type(@{ $payments_type_list }) {
    $table->addrow(
      _translate($payments_type->{name}),
      $html->form_input(
        'ADMIN_PAYMENTS_TYPE',
        $payments_type->{id},
        { TYPE => 'checkbox', STATE => $payments_type->{allowed} ? 'checked' : undef }),
    );
  }

  print $html->form_main(
    {
      CONTENT => $table->show({ OUTPUT2RETURN => 1 }),
      HIDDEN  => {
        index => $index,
        AID   => $FORM{AID},
        subf  => $FORM{subf}
      },
      SUBMIT  => { set => $lang{CHANGE} }
    }
  );

  return 1;
}

#**********************************************************
=head2 form_admins_contacts($attr);

=cut
#**********************************************************
sub form_admins_contacts {
  require Contacts;
  Contacts->import();
  my $contacts = Contacts->new($db, $admin, \%conf);

  #my @priority = ($lang{VERY_LOW}, $lang{LOW}, $lang{NORMAL}, $lang{HIGH}, $lang{VERY_HIGH});
  #my @priority_colors = ('#8A8A8A', '#3d3938', '#1456a8', '#E06161', 'red');

  if (!defined($FORM{AID})) {
    $FORM{subf} = 61;
    form_admins();
    return 1;
  }

  #  if ( $FORM{CONTACTS} ){
  #    return admin_contacts_renew();
  #  }

  my $list = $admin->admins_contacts_list(
    {
      AID      => $FORM{AID},
      VALUE    => '_SHOW',
      PRIORITY => '_SHOW',
      TYPE     => '_SHOW',
      HIDDEN   => '0'
    }
  );

  my $contacts_type_list = $contacts->contact_types_list(
    {
      SHOW_ALL_COLUMNS => 1,
      COLS_NAME        => 1,
      HIDDEN           => '0',
    }
  );

  map {$_->{name} = $lang{$_->{name}} || $_->{name}} @{$contacts_type_list};

  $admin->{CONTACTS} = _build_admin_contacts_form($list, $contacts_type_list);

  return 1;
}

#**********************************************************
=head2 form_admins_contacts_save()

=cut
#**********************************************************
sub form_admins_contacts_save {

  my $message = $lang{ERROR};
  my $status = 1;

  return 0 unless ($FORM{AID} && $FORM{CONTACTS});

  if (my $error = load_pmodule("JSON", { RETURN => 1 })) {
    print $error;
    return 0;
  }

  my $json = JSON->new();

  $FORM{CONTACTS} =~ s/\\\"/\"/g;

  my $contacts = $json->decode($FORM{CONTACTS});

  my DBI $db_ = $admin->{db}->{db};
  if (ref $contacts eq 'ARRAY') {
    $db_->{AutoCommit} = 0;

    $admin->admin_contacts_del({ AID => $FORM{AID} });
    if ($admin->{errno}) {
      $db_->rollback();
      $status = $admin->{errno};
      $message = $admin->{sql_errstr};
    }
    else {
      foreach my $contact (@{$contacts}) {
        $admin->admin_contacts_add({ %{$contact}, AID => $FORM{AID} });
      }

      if ($admin->{errno}) {
        $db_->rollback();
        $status = $admin->{errno};
        $message = $admin->{sql_errstr};
      }
      else {
        $db_->commit();
        $db_->{AutoCommit} = 1;
      }

      $message = $lang{CHANGED};
      $status = 0;
    }
  }

  my $admin_contacts_list = $admin->admins_contacts_list(
    {
      AID      => $FORM{AID},
      VALUE    => '_SHOW',
      DEFAULT  => '_SHOW',
      PRIORITY => '_SHOW',
      TYPE     => '_SHOW',
      HIDDEN   => '0'
    }
  );

  my $contacts_json = JSON->new()->utf8(0)->encode({
    contacts => $admin_contacts_list,
  });

  print qq[
    {
      "contacts" : $contacts_json,
      "status" : $status,
      "message" :  "$message"
    }
  ];

  return 1;
}

#**********************************************************
=head2 _build_user_contacts_form($user_contacts_list)

  Arguments:
    $user_contacts_list -

  Returns:

=cut
#**********************************************************
sub _build_admin_contacts_form {
  my ($admin_contacts_list, $admin_contacts_types_list) = @_;
  load_pmodule('JSON');
  my $json = JSON->new()->utf8(0);

  $html->tpl_show(templates('form_contacts_admin'), {
    JSON       => $json->encode({
      contacts => $admin_contacts_list,
      options  => {
        callback_index => get_function_index('form_admins_contacts_save'),
        types          => $admin_contacts_types_list,
        AID            => $FORM{AID},
      }
    }),
    SIZE_CLASS => 'col-md-6 col-md-push-3'
  });

  return 1;
}

#**********************************************************
=head2 form_admins_domains($attr);

=cut
#**********************************************************
sub form_admins_domains {
  my ($attr) = @_;

  if (!defined($attr->{ADMIN})) {
    $FORM{subf} = 113;
    form_admins();
    return 1;
  }

  require Multidoms;
  Multidoms->import();
  my $Domains = Multidoms->new($db, $admin, \%conf);

  if ($FORM{change}) {
    $Domains->admin_change({ %FORM, DOMAIN_ID => $FORM{NEW_DOMAIN} });
    if (_error_show($Domains)) {
      $html->message('info', $lang{CHANGED}, "$lang{CHANGED}");
    }
  }

  my $table = $html->table(
    {
      width   => '100%',
      caption => $lang{DOMAINS},
      title   => [ 'ID', $lang{NAME} ],
    }
  );

  my $list = $Domains->admins_list({ AID => $LIST_PARAMS{AID}, COLS_NAME => 1 });
  my %admins_domain_hash = ();

  foreach my $line (@$list) {
    $admins_domain_hash{ $line->{domain_id} } = 1;
  }

  $list = $Domains->multidoms_domains_list({ COLS_NAME => 1 });
  foreach my $line (@$list) {
    $table->addrow($html->form_input('NEW_DOMAIN', $line->{id}, { TYPE => 'checkbox', STATE => (defined($admins_domain_hash{ $line->{id} })) ? 'checked' : undef }) . $line->{id},
      $line->{name});
  }

  print $html->form_main(
    {
      CONTENT => $table->show({ OUTPUT2RETURN => 1 }),
      HIDDEN  => {
        index => $index,
        AID   => $FORM{AID},
        subf  => $FORM{subf}
      },
      SUBMIT  => { change => $lang{CHANGE} }
    }
  );

  return 1;
}

#**********************************************************
=head2 _paranoid_log_function_filter;

=cut
#**********************************************************
sub _paranoid_log_function_filter {
  my ($function_name) = @_;

  return 'undef' if !($function_name);

  my $params = "index=60&AID=$FORM{AID}&details=$function_name";
  if ($FORM{FROM_DATE}) {
    $params = $params . "&FROM_DATE=$FORM{FROM_DATE}&TO_DATE=$FORM{TO_DATE}";
  }

  return $html->button($function_name, $params);
}

#**********************************************************
=head2 _paranoid_log_params_filter;

=cut
#**********************************************************
sub _paranoid_log_params_filter {
  my ($params) = @_;

  if ($params) {
    $params =~ s/\n/&/g;
  }

  return $params;
}

1
