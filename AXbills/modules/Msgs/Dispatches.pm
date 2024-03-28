=head1 NAME

  Dispatches

=cut

use strict;
use warnings FATAL => 'all';
use AXbills::Base qw(tpl_parse cmd in_array
  int2byte convert sendmail mk_unique_value
  sec2time time2sec urlencode load_pmodule decode_base64 _bp);
use Msgs;
use POSIX qw(strftime mktime);
use Time::Piece;

our ($db,
  %lang,
  $html,
  @bool_vals,
  @MONTHES,
  @WEEKDAYS,
  @_COLORS,
  %permissions,
  $ui,
  @MONTHES_LIT,
  %msgs_permissions
);

our Admins $admin;

our $Msgs = Msgs->new($db, $admin, \%conf);
my $users = Users->new($db, $admin, \%conf);
my $Admins = Admins->new($db, $admin, \%conf);
my $Address = Address->new($db, $admin, \%conf);

#**********************************************************
=head2 msgs_dispatches()

  Arguments:

=cut
#**********************************************************
sub msgs_dispatches {

  if (!$msgs_permissions{3}{0}) {
    $html->message('err', $lang{ERROR}, $lang{ERR_ACCESS_DENY});
    return;
  }

  if ($FORM{print} || $FORM{chg} || $FORM{change_modal} || $FORM{add} || $FORM{add_form} || $FORM{del_dispatch}) {
    $FORM{add_modal} = 1 if $FORM{add};
    msgs_dispatch();
    delete $FORM{STATE};
    delete $FORM{END_DATE};
    delete $FORM{START_DATE};
    delete $FORM{AID};
  }

  return 1 if $FORM{not_msgs} || $FORM{print};

  if ($FORM{MSGS_STATUS_ID} && defined $FORM{MSGS_STATUS} && !defined($FORM{NEW_STATE})) {
    $FORM{STATUS_SELECT} = msgs_sel_status({ SELECTED_ID => $FORM{MSGS_STATUS}, NAME => "NEW_STATE" });

    $html->tpl_show(_include('msgs_change_msgs', 'Msgs'), { %FORM });

    return 1;
  }

  if (defined $FORM{NEW_STATE}) {
    if (!$msgs_permissions{3}{2}) {
      $html->message('err', $lang{ERROR}, $lang{ERR_ACCESS_DENY});
    }
    else {
      $Msgs->message_change({ ID => $FORM{MSGS_STATUS_ID}, STATE => $FORM{NEW_STATE} || 0, });
      $html->message('info', $lang{INFO}, $lang{CHANGED}) if !_error_show($Msgs);
    }
  }

  my $type_select = $html->form_select('CATEGORY', {
    SELECTED    => $FORM{CATEGORY} || 0,
    SEL_LIST    => $Msgs->dispatch_category_list({ COLS_NAME => 1 }),
    SEL_KEY     => 'id',
    SEL_VALUE   => 'id,name',
    NO_ID       => 1,
    SEL_OPTIONS => { 0 => '-' },
    ID          => 'CATEGORY_MAIN'
  });

  my $chg_function = get_function_index("msgs_dispatches");
  my $add_dispatch_btn = $msgs_permissions{3}{1} ? $html->button($lang{ADD}, undef, {
    class          => 'add',
    JAVASCRIPT     => '',
    SKIP_HREF      => 1,
    NO_LINK_FORMER => 1,
    ex_params      => qq/onclick=modal_view(0,$chg_function)/
  }) : '';

  require Control::Reports;
  reports({
    NO_GROUP         => 1,
    NO_TAGS          => 1,
    DATE_RANGE       => 1,
    DATE             => $FORM{DATE},
    REPORT           => '',
    EX_PARAMS        => {
      DATE   => $lang{DATE},
      USERS  => $lang{USERS},
      ADMINS => $lang{ADMINS},
    },
    PERIOD_FORM      => 1,
    EXT_TYPE         => {
      ADMINS     => $lang{ADMINS},
      RESPOSIBLE => $lang{RESPOSIBLE},
      CHAPTERS   => $lang{CHAPTERS},
      PER_MONTH  => $lang{PER_MONTH},
      DISTRICT   => $lang{DISTRICT},
      STREET     => $lang{STREET},
      BUILD      => $lang{BUILD},
      REPLY      => $lang{REPLY},
      PER_CLOSED => $lang{CLOSED},
    },
    EXT_SELECT       => {
      ADMINS => { LABEL => $lang{HEAD}, SELECT => sel_admins({ NAME => 'AID', RESPOSIBLE => $FORM{AID} }) },
      STATES => { LABEL => $lang{STATUS}, SELECT => msgs_sel_status({ ALL => 0, SELECTED_ID => $Msgs->{STATE} || "", NAME => "STATE_FILTER" }) },
      TYPES  => { LABEL => $lang{CATEGORY}, SELECT => $type_select },
    },
    EXTRA_HEADER_BTN => $add_dispatch_btn,
  });

  if (!$FORM{show} || ($FORM{FROM_DATE} eq $FORM{TO_DATE})) {
    $FORM{TO_DATE} = POSIX::strftime("%Y-%m-%d", localtime(time + int(30) * 86400));
  }
  elsif ($FORM{FROM_DATE_TO_DATE}) {
    ($FORM{FROM_DATE}, $FORM{TO_DATE}) = split("/", $FORM{FROM_DATE_TO_DATE});
  }

  my $list = $Msgs->dispatch_list({
    SORT             => 'd.plan_date',
    COLS_NAME        => 1,
    PAGE_ROWS        => 255,
    STATE            => $FORM{STATE_FILTER} || 0,
    MSGS_DONE        => '_SHOW',
    CREATED          => '_SHOW',
    COMMENTS         => '_SHOW',
    CATEGORY_ID      => $FORM{CATEGORY} || '_SHOW',
    MESSAGE_COUNT    => '_SHOW',
    FROM_DATE        => $FORM{FROM_DATE} || $DATE,
    TO_DATE          => $FORM{TO_DATE} || $DATE,
    PLAN_DATE        => '_SHOW',
    RESPOSIBLE       => $FORM{AID} || '_SHOW',
    RESPOSIBLE_ADMIN => '_SHOW',
  });

  $html->tpl_show(_include('msgs_dispatches', 'Msgs')) if (!$Msgs->{TOTAL} || !$list);
  return 0 if (!$Msgs->{TOTAL} || !$list);

  my @dispatches = reverse @{$list};
  my $dispatches_main_tpl = "";
  my $day_month = "";

  my %dispatches_list = ();

  foreach my $dispatch (@dispatches) {
    $dispatch->{admins} = "";
    my $dispatch_admins = $Msgs->dispatch_admins_list({ DISPATCH_ID => $dispatch->{id}, COLS_NAME => 1 });
    if ($Msgs->{TOTAL}) {
      for my $admin_ (@{$dispatch_admins}) {
        $dispatch->{admins} .= " " . ($admin_->{name} || q{}) . ",";
      }

      chop $dispatch->{admins};
    }

    my ($create_date, undef) = split(/\s/, $dispatch->{plan_date});
    my (undef, $month, $day) = split(/-/, $create_date);

    if ($day_month eq ($day . $month)) {
      $dispatch->{resposible_admin} ||= "";
      $dispatches_list{$day . $month} .= _msgs_dispatches_job_list($dispatch) .
        $html->element('h6', "$lang{RESPOSIBLE}: $dispatch->{resposible_admin}", { class => 'text-center' }) . $html->br();
      next;
    }

    my $responsible_admin = $dispatch->{resposible_admin} || "";
    $dispatches_list{$day . $month} = (_msgs_dispatches_job_list($dispatch) || "") .
      $html->element('h6', "$lang{RESPOSIBLE}: $responsible_admin", { class => 'text-center' }) . $html->br();

    $day_month = $day . $month;
  }

  $day_month = "";
  foreach my $dispatch (@dispatches) {
    my ($create_date, undef) = split(/\s/, $dispatch->{plan_date});
    my (undef, $month, $day) = split(/-/, $create_date);

    if ($day_month eq ($day . $month)) {
      next;
    }

    my $day_form = Time::Piece->strptime($create_date, "%Y-%m-%d");
    my $day_type = ($day_form->day_of_week eq "6" || defined($day_form->day_of_week) && !$day_form->day_of_week) ? "red" : "blue";
    $dispatches_main_tpl .= $html->tpl_show(_include('msgs_main_dispatch', 'Msgs'), { %FORM,
      DAY_NAME    => $lang{uc $day_form->fullday . "_FULL"} || $WEEKDAYS[$day_form->day_of_week],
      DAY         => $day,
      MONTH       => $MONTHES[int $month - 1],
      DISPATCHES  => $dispatches_list{$day . $month},
      RESPOSIBLE  => $dispatch->{resposible_admin},
      DISPATCH_ID => $dispatch->{id},
      DAY_TYPE    => $day_type,
    }, { OUTPUT2RETURN => 1 });

    $day_month = $day . $month;
  }

  $html->tpl_show(_include('msgs_dispatches', 'Msgs'), { DISPATCHES => $dispatches_main_tpl });

  return 1;
}

#**********************************************************
=head2 msgs_dispatches_job_list()

  Arguments:

=cut
#**********************************************************
sub _msgs_dispatches_job_list {
  my ($dispatch) = @_;

  my $chg_function = get_function_index("msgs_dispatches");
  my $dispatch_link = $msgs_permissions{3}{2} ? $html->button("$lang{DISPATCH} № $dispatch->{id}", undef, {
    JAVASCRIPT     => '',
    SKIP_HREF      => 1,
    NO_LINK_FORMER => 1,
    ex_params      => qq/onclick=modal_view($dispatch->{id},$chg_function) class='h5 cursor-pointer'/
  }) : $html->element('span', "$lang{DISPATCH} № $dispatch->{id}", { class => 'h5' });

  my $pdf_only = $conf{MSGS_DISPATCH_PDF} ? "&pdf=1" : "";
  my $print_btn = $msgs_permissions{3}{4} ? $html->button($lang{PRINT}, "#", {
    NEW_WINDOW      => "$SELF_URL?qindex=" . get_function_index("msgs_dispatches") . "&print=$dispatch->{id}" . $pdf_only,
    NEW_WINDOW_SIZE => "640:750",
    class           => 'print'
  }) : '';

  my $del_btn = $msgs_permissions{3}{3} ? $html->button($lang{DEL}, "&index=$index&del_dispatch=$dispatch->{id}", {
    class => 'del', MESSAGE => "$lang{DEL} $lang{DISPATCH} № $dispatch->{id}?"
  }) : '';

  my $dispatches_table = $html->table({
    caption     => "$print_btn $dispatch_link: <b>$dispatch->{admins}</b>",
    title_plain => [ "Id", $lang{TIME}, $lang{MESSAGE}, $lang{LOGIN}, $lang{ADDRESS}, $lang{STATUS}, $lang{PHONE}, $lang{RESPOSIBLE} ],
    width       => '100%',
    qs          => $pages_qs,
    ID          => 'LIST_OF_DISPATCHES',
    MENU        => [ $del_btn ]
  });

  my $messages = $Msgs->messages_list({
    SUBJECT       => '_SHOW',
    CHAPTER_NAME  => '_SHOW',
    MESSAGE       => '_SHOW',
    SUBJECT       => '_SHOW',
    STATE_ID      => '_SHOW',
    MSG_PHONE     => '_SHOW',
    REPLY_TEXT    => '_SHOW',
    PLAN_TIME     => '_SHOW',
    UID           => '_SHOW',
    STATE         => '_SHOW',
    RESPOSIBLE    => '_SHOW',
    A_NAME        => '_SHOW',
    CHAPTER_COLOR => '_SHOW',
    LOCATION_ID   => '_SHOW',
    DISPATCH_ID   => $dispatch->{id},
    MSG_ID        => '_SHOW',
    COLS_NAME     => 1,
    SORT          => 'm.plan_time',
    PAGE_ROWS     => 10000
  });

  foreach my $message (@{$messages}) {
    my $user_link = "";

    $message->{message} = $message->{message} || $lang{ERR_NO_MESSAGE} || "";
    $message->{message} =~ s/$lang{CHANGED}(.+)// if $message->{message};
    $message->{message} =~ s/Edited(.+)// if $message->{message};
    my $msg_length = length($message->{message}) || 0;

    $message->{message} = $msg_length > 300 ? substr($message->{message}, 0, 300) : $message->{message};
    $message->{message} .= "..." if $msg_length > 300;

    my $Admin_name = $Admins->list({ AID => $message->{resposible}, ADMIN_NAME => '_SHOW', COLS_NAME => 1 });
    $Msgs->message_info($message->{id});
    my $msgs_status = msgs_sel_status({ HASH_RESULT => 1 });

    my $user_address = "";
    my $build_delimiter = $conf{BUILD_DELIMITER} || ', ';
    my $user_list = "";
    if ($message->{uid}) {
      $user_list = $users->list({
        LOGIN         => '_SHOW',
        ADDRESS_FULL  => '_SHOW',
        PHONE         => '_SHOW',
        DISTRICT_NAME => '_SHOW',
        UID           => $message->{uid},
        FIO           => '_SHOW',
        COLS_NAME     => 1,
        COLS_UPPER    => 1,
        PAGE_ROWS     => 2,
      });

      next if !$users->{TOTAL};

      $user_link = $html->button($user_list->[0]{LOGIN}, "index=" . get_function_index("form_users") . "&UID=$message->{uid}", {
        TITLE => $user_list->[0]{FIO} || $user_list->[0]{LOGIN}
      });

      $user_address = $user_list->[0]{ADDRESS_FULL} || "";
    }
    elsif ($message->{location_id}) {
      my $address_info = $Address->address_info($message->{location_id});
      if ($Address->{TOTAL}) {
        $user_address = ($address_info->{ADDRESS_DISTRICT} || "") . $build_delimiter .
          ($address_info->{ADDRESS_STREET} || "") . $build_delimiter . ($address_info->{ADDRESS_BUILD} || "");
      }
    }

    my $user_main_list = $users->{TOTAL} ? $user_list : [];

    my $tooltip_btn = $html->color_mark($message->{chapter_name}, $message->{chapter_color});
    my $chapter_color = $message->{chapter_color} || "";
    $message->{uid} = $message->{uid} || "";
    my $link = $html->button($message->{message} || $lang{ERR_NO_MESSAGE},
      "index=" . get_function_index("msgs_admin") . "&UID=$message->{uid}&chg=$message->{id}",
      { ex_params => "style='color:$chapter_color'", TITLE => $message->{chapter_name} }
    );

    my ($title, $color) = split(':', $msgs_status->{ $Msgs->{STATE} });

    my $status_span = $html->element('span', '&nbsp;', {
      class                   => 'fa fa-record',
      "data-tooltip-position" => 'right',
      "data-tooltip"          => $title || "",
      style                   => "color: " . ($color || ""),
    });

    my $status_color = ($color || "black");
    $status_span = $html->button('', "qindex=$index&header=2&MSGS_STATUS_ID=$message->{id}&MSGS_STATUS=$message->{state_id}", {
      LOAD_TO_MODAL => 1,
      ADD_ICON      => 'fa fa-circle',
      TITLE         => $lang{MSGS_TAGS},
      ex_params     => "style='color:$status_color' data-tooltip-position='right' data-tooltip='$title'"
    });

    my $user_phone = ref $user_main_list eq "ARRAY" && $user_main_list->[0] ? $user_main_list->[0]{PHONE} : $message->{msg_phone} ? $message->{msg_phone} : "";
    $dispatches_table->addrow($message->{id}, $message->{plan_time}, $link, $user_link, $user_address,
      $status_span, $user_phone, $Admin_name->[0]{admin_name} || "");
  }

  return $dispatches_table->show() || "";
}

#**********************************************************
=head2 msgs_dispatch()

=cut
#**********************************************************
sub msgs_dispatch {

  require Contacts;
  Contacts->import();
  my $Contacts = Contacts->new($db, $admin, \%conf);

  my $disabled_actual_time = 'disabled';
  my $dispatch_admins = q{};

  $Msgs->{ACTION} = 'add';
  $Msgs->{LNG_ACTION} = $lang{ADD};

  if ($FORM{add} || $FORM{add_modal}) {
    if (!$msgs_permissions{3}{1}) {
      $html->message('err', $lang{ERROR}, $lang{ERR_ACCESS_DENY});
      return;
    }

    $Msgs->dispatch_add({ %FORM });
    msgs_dispatch_admins({ AIDS => $FORM{AIDS}, DISPATCH_ID => $Msgs->{DISPATCH_ID}, ADD => 1 });
    $html->message('info', $lang{INFO}, "$lang{ADDED}") if (!$Msgs->{errno});
    $html->redirect('?index=' . get_function_index('msgs_dispatches'), { WAIT => 0 });
    return 1 if $FORM{add_modal};
  }
  elsif ($FORM{print}) {
    print $html->header();
    if (!$msgs_permissions{3}{4}) {
      $html->message('err', $lang{ERROR}, $lang{ERR_ACCESS_DENY});
      return;
    }
    my $dispatch_infos = $Msgs->dispatch_info($FORM{print});

    $dispatch_admins = $Msgs->dispatch_admins_list({ DISPATCH_ID => $FORM{print}, COLS_NAME => 1 });
    my $brigade = q{};
    my %ORDERS = ();
    my $count = 1;

    foreach my $line (@$dispatch_admins) {
      $brigade .= "$line->{name}";
      $brigade .= $html->br();
      $ORDERS{ 'BRIGADE_PERSON_' . $count } = $line->{name};
      $ORDERS{ 'BRIGADE_PERSON_POSITION_' . $count++ } = $line->{admin_position} || "";
    }

    my $value_list = $Conf->config_list({
      CUSTOM    => 1,
      COLS_NAME => 1
    });

    my $list = $Msgs->messages_list({
      DISPATCH_ID    => $FORM{print},
      LOGIN          => '_SHOW',
      PLAN_DATE      => '_SHOW',
      PLAN_TIME      => '_SHOW',
      ADDRESS_FULL   => '_SHOW',
      ADDRESS_STREET => '_SHOW',
      SUBJECT        => '_SHOW',
      ADDRESS_BUILD  => '_SHOW',
      CITY           => '_SHOW',
      DISTRICT_NAME  => '_SHOW',
      LOCATION_ID_MSG    => '_SHOW',
      STATE_ID       => $FORM{NO_CLOSE_MSG} ? '!(1;2)' : '*',
      ADDRESS_FLAT   => '_SHOW',
      MESSAGE        => '_SHOW',
      PASSWORD       => '_SHOW',
      USER_CONTACTS  => 1,
      FIO            => '_SHOW',
      PHONE          => '_SHOW',
      COLS_NAME      => 1,
      SORT           => 'm.plan_time',
    });

    my @message_ids;

    foreach my $message (@$list) {
      push @message_ids, $message->{id};
    }

    my $reply_list = $Msgs->messages_reply_list({
      MSGS_IDS   => join(',', @message_ids),
      MSG_ID     => '_SHOW',
      INNER_MSG  => 1,
      COLS_NAME  => 1,
    });
    
    my %work_messages;
    foreach my $msgs_order (@{ $reply_list }) {
      $work_messages{ $msgs_order->{main_msg} } = $msgs_order->{text} 
        unless ($msgs_order->{text} =~ /$lang{DELIGATE}/);
    }

    $Msgs->{PLAN_DATE_LIT} = '';
    if (in_array('Docs', \@MODULES)) {
      ($Msgs->{Y}, $Msgs->{M}, $Msgs->{D}) = split(/-/, ($Msgs->{PLAN_DATE}) || '');

      if ($Msgs->{Y} && $Msgs->{M} && $Msgs->{D}) {
        $Msgs->{PLAN_DATE_LIT} = "$Msgs->{D} " . $MONTHES_LIT[ int($Msgs->{M}) - 1 ] . " $Msgs->{Y} $lang{YEAR}";
      }
    }

    my $i = 1;
    foreach my $line (@{$value_list}) {
      $ORDERS{"$line->{param}"} = $line->{value};
    }

    foreach my $line (@{$list}) {
      my $phone_list = $Contacts->contacts_list({
        UID   => $line->{uid},
        TYPE  => '1;2',
        VALUE => '_SHOW',
      });

      foreach my $phone (@{$phone_list}) {
        $ORDERS{ 'ORDER_PERSONAL_INFO_PHONE_' . $i } .= $phone->{'value'} . "\n";
      }

      my $address_full = ($line->{city} || q{})
        . ' ' . ($line->{address_street} || q{})
        . ' ' . ($line->{address_build} || q{})
        . ', ' . ($line->{address_flat} || q{});
      if ($line->{district_name} && $line->{address_full}) {
        $address_full = $line->{address_full} || "";
      }
      $line->{message} =~ s/$lang{CHANGED}(.+)// if $line->{message};

      if ($line->{location_id_msg} && !$line->{uid}) {
        my $address_info = $Address->address_info($line->{location_id_msg});
        if ($Address->{TOTAL}) {
          my $build_delimiter = $conf{BUILD_DELIMITER} || ', ';
          $address_full = ($address_info->{ADDRESS_DISTRICT} || "") . ", " .
            ($address_info->{ADDRESS_STREET} || "") . $build_delimiter . ($address_info->{ADDRESS_BUILD} || "");
        }
      }

      $ORDERS{ 'ORDER_NUM_' . $i } = $i;
      $ORDERS{ 'ORDER_PERSONAL_INFO_' . $i } = ($line->{fio} || q{}) . ', ' . $address_full;
      $ORDERS{ 'ORDER_PERSONAL_INFO_LOGIN_' . $i } = $line->{login} || q{-};
      $ORDERS{ 'ORDER_PERSONAL_INFO_PASSWORD_' . $i } = $line->{password};
      $ORDERS{ 'ORDER_PERSONAL_INFO_FIO_' . $i } = $line->{fio};
      $ORDERS{ 'ORDER_PERSONAL_INFO_ADDRESS_' . $i } = $address_full;
      $ORDERS{ 'ORDER_JOB_' . $i } = $work_messages{ $line->{id} } || $line->{message};
      $ORDERS{ 'ORDER_SUBJECT_' . $i } = $line->{subject};
      $ORDERS{ 'ORDER_CHAPTER_' . $i } = $line->{chapter_name};
      $ORDERS{ 'ORDER_DATE_' . $i } = $line->{date};
      $ORDERS{ 'PLAN_DATE_' . $i } = $line->{plan_date};
      $ORDERS{ 'PLAN_TIME_' . $i } = $line->{plan_time};
      $ORDERS{ 'MSGS_NUM_ID_' . $i } = $line->{id};

      my $cross_modules_return = cross_modules('docs', { UID => $line->{uid} });
      
      foreach my $module (keys %{$cross_modules_return}) {
        next if ref $cross_modules_return->{$module} ne 'ARRAY';
        
        my $uc_module = uc $module;
        my $tp_number = 1;
        foreach my $tp (@{$cross_modules_return->{$module}}) {
          my (undef, undef, $sum, undef, $tp_name) = split(/\|/, $tp);

          $ORDERS{ $uc_module . '_TP_NAME_' . $i . '_' . $tp_number } = $tp_name;
          $ORDERS{ $uc_module . '_TP_SUM_' . $i . '_' . $tp_number } = $sum;
          $tp_number++;
        }
      }
      
      $i++;
    }

    my $template = 'msgs_dispatch_blank';

    if ($dispatch_infos->{CATEGORY}) {
      my $new_template = $template . '_' . $dispatch_infos->{CATEGORY};
      my $template_content = _include($new_template, 'Msgs');
      $template = $new_template if ($template_content !~ /No such / && $template_content ne '');
    }

    if ($Msgs->{RESPOSIBLE}) {
      my $resposible_info = $Admins->list({
        AID            => $Msgs->{RESPOSIBLE},
        SHOW_EMPLOYEES => 1,
        POSITION       => '_SHOW',
        COLS_NAME      => 1
      });
      $ORDERS{RESPOSIBLE_POSITION} = $resposible_info->[0]{position} || "" if $Admins->{TOTAL};
    }

    $html->tpl_show(_include($template, 'Msgs'), { %{$Msgs}, %ORDERS, BRIGADE => $brigade, pdf => $FORM{pdf}, });

    return 0;
  }
  elsif ($FORM{change} || $FORM{change_modal}) {
    if (!$msgs_permissions{3}{2}) {
      $html->message('err', $lang{ERROR}, $lang{ERR_ACCESS_DENY});
      return;
    }

    $FORM{change} = $FORM{change_modal} if $FORM{change_modal};
    if ($FORM{STATE} && $FORM{STATE} > 0) {
      $FORM{DONE_DATE} = "$DATE" if ($FORM{STATE} == 2);
      $FORM{CLOSED_DATE} = "$DATE" if ($FORM{STATE} == 1 || $FORM{STATE} == 2);
    }

    $Msgs->dispatch_change({ %FORM });
    msgs_dispatch_admins({ AIDS => $FORM{AIDS}, DISPATCH_ID => $FORM{ID}, CHANGE => 1 });
    $html->message('info', $lang{INFO}, $lang{CHANGED}) if (!$Msgs->{errno});

    return 1 if $FORM{change_modal};
  }
  elsif ($FORM{chg}) {
    $Msgs->dispatch_info($FORM{chg});

    $Msgs->{ACTION} = 'change_modal';
    $Msgs->{LNG_ACTION} = $lang{CHANGE};
    $FORM{add_form} = 1;
    $disabled_actual_time = '';
  }
  elsif (($FORM{del} || $FORM{del_dispatch}) && $FORM{COMMENTS}) {
    $Msgs->dispatch_del({ ID => $FORM{del} || $FORM{del_dispatch} });
    $html->message('info', $lang{INFO}, $lang{DELETED}) if (!$Msgs->{errno});
    return 0 if $FORM{del_dispatch};
  }

  _error_show($Msgs);

  $LIST_PARAMS{STATE} = $FORM{STATE} if (defined($FORM{STATE}) && $FORM{STATE} ne '');

  if ($FORM{add_form}) {
    $Msgs->{STATE_SEL} = msgs_sel_status({ ALL => 0, SELECTED_ID => $Msgs->{STATE} || "" });
    $Msgs->{RESPOSIBLE_SEL} = sel_admins({ NAME => 'RESPOSIBLE', RESPOSIBLE => $Msgs->{RESPOSIBLE}, DISABLE => 0 });
    $Msgs->{PLAN_DATE} = $html->form_datepicker('PLAN_DATE', $Msgs->{PLAN_DATE} || $DATE);
    $Msgs->{CREATED_BY_SEL} = sel_admins({
      NAME     => 'CREATED_BY',
      SELECTED => ($Msgs->{CREATED_BY} && $Msgs->{CREATED_BY} > '0') ? $Msgs->{CREATED_BY} : $admin->{AID},
      DISABLE  => 0
    });
    $Msgs->{START_DATE} = $html->form_datetimepicker('START_DATE', ($Msgs->{START_DATE} || ''));
    $Msgs->{END_DATE} = $html->form_datetimepicker('END_DATE', ($Msgs->{END_DATE} || ''));
    $Msgs->{ACTUAL_END_DATE} = $html->form_datetimepicker('ACTUAL_END_DATE', ($Msgs->{ACTUAL_END_DATE} || '0000-00-00 00:00:00'), { EX_PARAMS => $disabled_actual_time });

    my $aids = msgs_dispatch_admins({
      TWO_COLUMNS => 1,
    });

    $Msgs->{CATEGORY_SEL} = $html->form_select('CATEGORY', {
      SELECTED    => $Msgs->{CATEGORY} || 0,
      SEL_OPTIONS => { 0 => '--' },
      SEL_LIST    => $Msgs->dispatch_category_list({ COLS_NAME => 1 }),
    });

    if ($FORM{not_msgs}) {
      $index = get_function_index('msgs_dispatches');
    }

    $html->tpl_show(_include('msgs_dispatch', 'Msgs'), { %{$aids}, %{$Msgs}, AID => $admin->{AID} });
  }

  if ($FORM{chg}) {
    $LIST_PARAMS{DISPATCH_ID} = $FORM{chg};
    $pages_qs .= '&chg=' . $FORM{chg};
    $index = get_function_index('msgs_admin');
    delete($FORM{chg});

    return 0 if ($FORM{not_msgs});
    msgs_list({
      SELECT_ALL_ON           => 1,
      ALLOW_TO_CLEAR_DISPATCH => 1,
      DISPATCH_ID             => $LIST_PARAMS{DISPATCH_ID},
      LIST_ID                 => 'MSGS_LIST_DISPATCH'
    });

    $index = get_function_index('msgs_dispatches');

    return 0;
  }

  if (!defined($FORM{STATE}) && !$FORM{ALL_MSGS}) {
    $FORM{STATE} = 0;
    $LIST_PARAMS{STATE} = 0;
  }

  if (!defined($FORM{sort})) {
    $LIST_PARAMS{SORT} = 1;
    $LIST_PARAMS{DESC} = 'desc';
  }

  $pages_qs = '';

  if (exists $FORM{RESPOSIBLE} && $FORM{RESPOSIBLE}) {
    $LIST_PARAMS{RESPOSIBLE} = ($FORM{RESPOSIBLE} eq 'current') ? $admin->{AID} : $FORM{RESPOSIBLE};
  }

  return 0 if ($FORM{not_msgs} || $FORM{del_dispatch});

  return 1;
}


1;
