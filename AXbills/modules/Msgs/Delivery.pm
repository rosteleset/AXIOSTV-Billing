=head1 Delivery_Msgs

  TV services

=cut

use strict;
use warnings FATAL => 'all';
use AXbills::Base qw(in_array);

our ($db,
  %lang,
  @bool_vals,
  @_COLORS,
  $admin,
  %conf,
  %msgs_permissions
);

our AXbills::HTML $html;

my $Msgs = Msgs->new($db, $admin, \%conf);
my $Sender = AXbills::Sender::Core->new($db, $admin, \%conf);
my $Attachments = Msgs::Misc::Attachments->new($db, $admin, \%conf);

my @priority = ($lang{VERY_LOW}, $lang{LOW}, $lang{NORMAL}, $lang{HIGH}, $lang{VERY_HIGH});

$_COLORS[6] //= 'red';
$_COLORS[8] //= '#FFFFFF';
$_COLORS[9] //= '#FFFFFF';

my @priority_colors = ('#8A8A8A', $_COLORS[8], $_COLORS[9], '#E06161', $_COLORS[6]);

#**********************************************************
=head2 msgs_delivery_main()

  Arguments:
  Returns:

=cut
#**********************************************************
sub msgs_delivery_main {

  if (!$msgs_permissions{2}{0}) {
    $html->message('err', $lang{ERROR}, $lang{ERR_ACCESS_DENY});
    return 1;
  };

  my $msgs_status = {
    0 => "$lang{D_ACTIVE}:#0000FF",
    1 => "$lang{DEFERRED}:#ff0638",
    2 => "$lang{DONE}:#009D00",
  };

  my $sender_send_types = $Sender->available_types(
    { HASH_RETURN => 1, CLIENT => 1, SOFT_CHECK => 1 }
  );

  my %send_methods = (
    0 => $lang{MESSAGE},
    %$sender_send_types
  );

  if ($conf{MSGS_REDIRECT_FILTER_ADD}) {
    $send_methods{3} = 'Web  redirect';
  }

  if ($FORM{add_form}) {
    $FORM{STATUS} = 1;
    $Msgs->{ACTION} = 'add';
    $Msgs->{ACTION_LNG} = $lang{ADD};
  }
  elsif ($FORM{add}) {
    if (!$msgs_permissions{2}{1}) {
      $html->message('err', $lang{ERROR}, $lang{ERR_ACCESS_DENY});
      return 1;
    };

    $Msgs->msgs_delivery_add({ %FORM });

    if (!$Msgs->{errno}) {
      _msgs_delivery_add_attachments($Msgs->{INSERT_ID});
      $html->message('success', $lang{INFO}, $lang{MESSAGE} . ' ' . $lang{ADDED});
    }
  }
  elsif ($FORM{del_delivery} && $FORM{COMMENTS}) {
    if (!$msgs_permissions{2}{3}) {
      $html->message('err', $lang{ERROR}, $lang{ERR_ACCESS_DENY});
    }
    else {
      $Msgs->msgs_delivery_del({ ID => $FORM{del_delivery} });
      $html->message('success', $lang{INFO}, join(' ', ($lang{MESSAGE}, $FORM{del_delivery}, $lang{DELETED}))) if !$Msgs->{errno};
    }
  }
  elsif ($FORM{chg}) {
    if (!$msgs_permissions{2}{2}) {
      $html->message('err', $lang{ERROR}, $lang{ERR_ACCESS_DENY});
      return 1;
    };

    $Msgs->{ACTION} = 'change';
    $Msgs->{ACTION_LNG} = $lang{CHANGE};
    $Msgs->{ATTACHMENTS} = AXbills::Base::json_former(_msgs_get_attachments($FORM{chg}) || [], { ESCAPE_DQ => 1 });

    $Msgs->msgs_delivery_info($FORM{chg});
    $FORM{STATUS} = $Msgs->{STATUS};
  }
  elsif ($FORM{show}) {
    $Msgs->{DISABLE} = 'disabled';
    $Msgs->{ACTION} = 'back';
    $Msgs->{ACTION_LNG} = $lang{BACK};
    $Msgs->msgs_delivery_info($FORM{show});
    $FORM{STATUS} = $Msgs->{STATUS};
  }
  elsif ($FORM{change}) {
    if (!$msgs_permissions{2}{2}) {
      $html->message('err', $lang{ERROR}, $lang{ERR_ACCESS_DENY});
      return 1;
    };

    $Msgs->msgs_delivery_change({ %FORM });

    if (!$Msgs->{errno}) {
      _msgs_delivery_add_attachments($FORM{ID});
      $html->message('success', $lang{INFO}, $lang{MESSAGE} . ' ' . $lang{CHANGED});
    }
  }

  if ($FORM{add_form} || $FORM{chg} || $FORM{show}) {
    $Msgs->{DATE_PIKER} = $html->form_datepicker('SEND_DATE', $Msgs->{SEND_DATE});
    $Msgs->{TIME_PIKER} = $html->form_timepicker('SEND_TIME', $Msgs->{SEND_TIME});
    $Msgs->{STATUS_SELECT} = $html->form_select('STATUS', {
      SELECTED => 0,
      SEL_HASH => {
        0 => $lang{D_ACTIVE},
        1 => $lang{DEFERRED},
        2 => $lang{DONE},
      },
      NO_ID    => 1,
      SELECTED => $Msgs->{STATUS} || 0,
    });

    $Msgs->{PRIORITY_SELECT} = $html->form_select('PRIORITY', {
      SELECTED     => defined($Msgs->{PRIORITY}) ? $Msgs->{PRIORITY} : 2,
      SEL_ARRAY    => \@priority,
      STYLE        => \@priority_colors,
      ARRAY_NUM_ID => 1
    });

    $Msgs->{SEND_METHOD_SELECT} = $html->form_select('SEND_METHOD', {
      SELECTED => defined($Msgs->{SEND_METHOD}) ? $Msgs->{SEND_METHOD} : 2,
      SEL_HASH => \%send_methods,
      NO_ID    => 1
    });

    $Msgs->{TEXT} =~ s/\%/\&#37;/g if$Msgs->{TEXT};

    if ($FORM{show} && !$msgs_permissions{2}{4}) {
      $html->message('err', $lang{ERROR}, $lang{ERR_ACCESS_DENY});
      return 1;
    };

    $html->tpl_show(_include('msgs_add_delivery', 'Msgs'), { %$Msgs });

    if ($FORM{show}) {
      if ($FORM{IDS}) {
        $Msgs->delivery_user_list_del({ ID => $FORM{IDS} });
        if (!_error_show($Msgs)) {
          $html->message('info', $lang{DELETED}, "$lang{USERS} $FORM{IDS}");
        }
      }
      msgs_delivery_user_table({
        MDELIVERY_ID   => $FORM{show},
        FUNCTION_INDEX => $index,
        PAGE_QS        => "&show=$FORM{show}"
      });
    }
  }
  else {
    #Delivery table
    my AXbills::HTML $table;
    my $list;
    ($table, $list) = result_former({
      INPUT_DATA      => $Msgs,
      FUNCTION        => 'msgs_delivery_list',
      DEFAULT_FIELDS  => 'ID, SEND_DATE, SEND_TIME, SUBJECT',
      FUNCTION_FIELDS => 'null',
      BASE_FIELDS     => 2,
      EXT_TITLES      => {
        id          => 'id',
        send_time   => $lang{SEND_TIME},
        send_date   => $lang{SEND_DATE},
        subject     => $lang{SUBJECT},
        text        => $lang{TEXT},
        send_method => $lang{MESSAGE},
        priority    => $lang{PRIORITY},
        status      => $lang{STATE},
        added       => $lang{ADDED},
        aid         => 'AID',
      },
      SKIP_USER_TITLE => 1,
      TABLE           => {
        width      => '100%',
        EXPORT     => 1,
        caption    => $lang{DELIVERY},
        qs         => $pages_qs,
        ID         => 'DILIVERY_LIST',
        MENU       => $msgs_permissions{2}{1} ? "$lang{ADD}:add_form=1&index=$index:add" : '',
        DATA_TABLE => 1
      },
    });

    my $field_count = ($FORM{json}) ? $#{ $Msgs->{COL_NAMES_ARR} } : $Msgs->{SEARCH_FIELDS_COUNT};

    foreach my $line (@{$list}) {
      my @fields_array = ();
      for (my $i = 0; $i < $field_count + 2; $i++) {
        my $val = '';
        my $field_name = $Msgs->{COL_NAMES_ARR}->[$i];
        if ($field_name eq 'send_method') {
          $val = $send_methods{$line->{send_method}};
        }
        elsif ($field_name eq 'priority') {
          $val = $html->color_mark($priority[ $line->{priority} ], $priority_colors[ $line->{priority} ]);
        }
        elsif ($field_name eq 'status') {
          $val = $html->color_mark($msgs_status->{ $line->{status} });
        }
        else {
          $val = $line->{ $field_name };
        }
        push @fields_array, $val;

      }
      my $chg_btn = $msgs_permissions{2}{2} ? $html->button($lang{CHANGE}, "index=$index&chg=$line->{id}", { class => 'change' }) : '';
      my $del_btn = $msgs_permissions{2}{3} ?
        $html->button($lang{DELETE}, "index=$index&del_delivery=$line->{id}", { MESSAGE => "$lang{DEL}",  class => 'del' }) : '';

      push @fields_array, $html->button($lang{SHOW}, "index=$index&show=$line->{id}", { class => 'user' }) . $chg_btn . $del_btn;
      $table->addrow(@fields_array);
    }

    print $html->form_main({
      CONTENT => $table->show({ OUTPUT2RETURN => 1 }),
      HIDDEN  => {
        index => $index,
      },
      NAME    => 'DILIVERY_LIST',
      ID      => 'DILIVERY_LIST',
    });

    my $total_dilivery = $Msgs->{TOTAL};

    $table = $html->table({
      width      => '100%',
      rows       => [ [ "  $lang{TOTAL}: ", $html->b($total_dilivery) ] ]
    });

    print $table->show();
  }

  return 1;
}

#**********************************************************
=head2 msgs_delivery_user_table ($attr) - show select user group

=cut
#**********************************************************
sub msgs_delivery_user_table {
  my ($attr) = @_;
  my @users_status = ($lang{WAIT_TO_SEND}, $lang{SENDED}, $lang{NOT_DELIVERED});

  my $user_list = $Msgs->delivery_user_list({
    MDELIVERY_ID => $attr->{MDELIVERY_ID},
    PAGE_ROWS    => 1000000,
    COLS_NAME    => 1,
  });

  my AXbills::HTML $user_table;
  my $list;
  ($user_table, $list) = result_former({
    INPUT_DATA      => $Msgs,
    LIST            => $user_list,
    DEFAULT_FIELDS  => 'LOGIN, FIO, EMAIL, STATUS, UID ',
    FUNCTION_INDEX  => $attr->{FUNCTION_INDEX} || 0,
    HIDDEN_FIELDS   => 'UID,STATUS,',
    MULTISELECT     => 'IDS:id:DELIVERY_USERS_LIST_FORM',
    BASE_FIELDS     => 5,
    SKIP_USER_TITLE => 1,
    SKIP_PAGES      => 1,
    EXT_TITLES      => {
      id     => 'id',
      login  => $lang{LOGIN},
      fio    => $lang{FIO},
      status => $lang{STATUS},
      uid    => 'UID',
      email  => 'E-mail'
    },
    TABLE           => {
      caption    => $lang{USERS},
      width      => '100%',
      ID         => 'DELIVERY_USERS_LIST',
      SELECT_ALL => "DELIVERY_USERS_LIST_FORM:IDS:$lang{SELECT_ALL}"
    }
  });

  my $field_count = ($FORM{json}) ? $#{ $Msgs->{COL_NAMES_ARR} } : $Msgs->{SEARCH_FIELDS_COUNT};

  foreach my $line (@{$list}) {
    my @fields_array = ();
    push @fields_array, $html->form_input('IDS', $line->{id}, {
      TYPE    => 'checkbox',
      FORM_ID => 'DELIVERY_USERS_LIST_FORM',
      ID      => 'IDS',
    });

    for (my $i = 0; $i < $field_count + 5; $i++) {
      my $field_name = $Msgs->{COL_NAMES_ARR}->[$i];
      my $val = $field_name eq 'status' ? $users_status[$line->{status}] : $line->{ $field_name };

      push @fields_array, $val;

    }
    push @fields_array, $html->button($lang{DELETE}, "index=$index&show=$FORM{show}&IDS=$line->{id}", { class => 'del' });

    $user_table->addrow(@fields_array);
  }

  my $total_delivery_users = $Msgs->{TOTAL};

  my $total_table = $html->table({
    width => '100%',
    rows  => [ [ "  $lang{TOTAL}: ", $html->b($total_delivery_users) ] ]
  });

	### START KTK-39
   my $delete_button_all = $html->form_input('APPLY', $lang{DEL}, { TYPE => 'submit', FORM_ID => 'DELIVERY_USERS_LIST_FORM', OUTPUT2RETURN => 1 });

  print $html->form_main({
    CONTENT => $user_table->show({ OUTPUT2RETURN => 1 }) . $total_table->show({ OUTPUT2RETURN => 1 }) .
                $html->element('div', $delete_button_all, { class => "d-flex flex-sm-row flex-column justify-content-end d-flex align-items-end pt-2 pb-2", OUTPUT2RETURN => 1 }),
     #### $html->form_input('APPLY', $lang{DEL}, { TYPE => 'submit', FORM_ID => 'DELIVERY_USERS_LIST_FORM' }),
	HIDDEN  => {
      index => $index,
      show  => $FORM{show},
    },
    NAME    => 'DELIVERY_USERS_LIST_FORM',
    ID      => 'DELIVERY_USERS_LIST_FORM',
  });
	### END KTK-39

  return 1
}

#**********************************************************
=head2 sel_deliverys($attr) - show select user group

  Attributes:
    $attr
      SELECTED
      HASH_RESULT     - Return results as hash
      SKIP_MULTISELECT  - Skip multiselect

  Returns:
    GID select form

=cut
#**********************************************************
sub sel_deliverys {
  my ($attr) = @_;

  my $list = $Msgs->msgs_delivery_list({
    SUBJECT   => '_SHOW',
    COLS_NAME => 1,
    PAGE_ROWS => 100000
  });

  my $DELIVERY_SEL = $html->form_select(
    'DELIVERY', {
      SELECTED     => $attr->{SELECTED} ? $attr->{SELECTED} : 0,
      SEL_LIST     => $list,
      SEL_VALUE    => 'subject',
      SEL_KEY      => 'id',
      SORT_KEY_NUM => 1,
      NO_ID        => 1,
      SEL_OPTIONS  => { '' => '--' },
    }
  );

  return $DELIVERY_SEL;
}

#**********************************************************
=head2 _msgs_delivery_add_attachments($id)

=cut
#**********************************************************
sub _msgs_delivery_add_attachments {
  my $id = shift;

  return if $Msgs->{errno} || !$id || !$FORM{UPLOAD_FILES};

  my $attachments = $Msgs->attachments_list({
    DELIVERY_ID  => $id,
    FILENAME     => '_SHOW',
    CONTENT_SIZE => '_SHOW'
  });

  foreach my $attachment (@{$attachments}) {
    $Attachments->delete_attachment($attachment->{id});
  }

  for (my $i = 0; $i <= 2; $i++) {
    my $input_name = 'FILE_UPLOAD' . (($i > 0) ? "_$i" : '');

    next if !$FORM{ $input_name }->{filename};

    $Attachments->attachment_add({
      DELIVERY_ID  => $id,
      FILENAME     => $FORM{ $input_name }->{filename},
      CONTENT_TYPE => $FORM{ $input_name }->{'Content-Type'},
      FILESIZE     => $FORM{ $input_name }->{Size},
      CONTENT      => $FORM{ $input_name }->{Contents},
    });
  }

  return;
}

#**********************************************************
=head2 _msgs_get_attachments($delivery_id)

=cut
#**********************************************************
sub _msgs_get_attachments {
  my $delivery_id = shift;

  my $attachments = $Msgs->attachments_list({
    DELIVERY_ID  => $delivery_id,
    FILENAME     => '_SHOW',
    CONTENT_SIZE => '_SHOW'
  });

  my @attachments_buttons = ();
  foreach my $attachment (@{$attachments}) {
    push @attachments_buttons, {
      filename => $attachment->{filename},
      url      => "?get_index=msgs_admin&ATTACHMENT=$attachment->{id}",
      size     => int2byte($attachment->{content_size})
    };
  }

  return \@attachments_buttons;
}

#**********************************************************
=head2 msgs_mu_delivery_add($attr)

=cut
#**********************************************************
sub msgs_mu_delivery_add {
  my ($attr) = @_;

  if ($attr->{DELIVERY_CREATE}) {
    $Msgs->msgs_delivery_add({ %{$attr},
      SEND_DATE => $attr->{DELIVERY_SEND_DATE},
      SEND_TIME => $attr->{DELIVERY_SEND_TIME},
      SUBJECT   => $attr->{DELIVERY_COMMENTS}
    });

    $attr->{DELIVERY} = $Msgs->{DELIVERY_ID};
    $html->message('err', $lang{ERRORS}, "$lang{DELIVERY} $lang{ADDED}") if ($Msgs->{errno});
    $html->message('info', $lang{INFO}, "$lang{DELIVERY} $lang{ADDED} ID:$attr->{DELIVERY}") if (!$Msgs->{errno});
  }

  my $delivery_info = $Msgs->msgs_delivery_info($attr->{DELIVERY});
  $Msgs->delivery_user_list_add({
    MDELIVERY_ID => $attr->{DELIVERY},
    IDS          => $attr->{IDS},
    SEND_METHOD  => $delivery_info->{SEND_METHOD},
  });

  $html->message('err', $lang{ERRORS}, $lang{ADD_USER}) if ($Msgs->{errno});
  $html->message('info', $lang{INFO}, "$Msgs->{TOTAL} $lang{USERS_ADDED_TO_DELIVERY} №:$attr->{DELIVERY}") if (!$Msgs->{errno});
}

#**********************************************************
=head2 msgs_mu_delivery_form()

=cut
#**********************************************************
sub msgs_mu_delivery_form {
  my %info = ();

  return '' if !$msgs_permissions{2}{0} || !$msgs_permissions{2}{4};

  my %send_methods = (0 => $lang{MESSAGE}, 1 => 'E-MAIL');

  my $Sender = AXbills::Sender::Core->new($db, $admin, \%conf);

  my $sender_send_types = $Sender->available_types(
    { HASH_RETURN => 1, CLIENT => 1, SOFT_CHECK => 1 }
  );

  %send_methods = (
    %send_methods,
    %$sender_send_types
  );

  $send_methods{3} = 'Web redirect' if ($conf{MSGS_REDIRECT_FILTER_ADD});

  $info{DELIVERY_SPAN_ADDON_URL} = $SELF_URL . "?index=" . get_function_index('msgs_delivery_main');
  $info{DELIVERY_SELECT_FORM} = sel_deliverys({ SKIP_MULTISELECT => 1 });
  $info{DATE_PIKER} = $html->form_datepicker('DELIVERY_SEND_DATE');
  $info{TIME_PIKER} = $html->form_timepicker('DELIVERY_SEND_TIME');
  $info{STATUS_SELECT} = msgs_sel_status({ NAME => 'STATUS' });
  $info{FORM_ID} = $html->{FORM_ID};;
  $info{PRIORITY_SELECT} = $html->form_select('PRIORITY', {
    SELECTED     => 2,
    SEL_ARRAY    => \@priority,
    STYLE        => \@priority_colors,
    ARRAY_NUM_ID => 1
  });
  $info{SEND_METHOD_SELECT} = $html->form_select('SEND_METHOD', {
    SELECTED => 2,
    SEL_HASH => \%send_methods,
    NO_ID    => 1
  });
  $info{DELIVERY_ADD_HIDE} = 'd-none' if !$msgs_permissions{2}{1};

  return $html->tpl_show(templates('form_user_delivery_add'), \%info, { OUTPUT2RETURN => 1 });
}

1
