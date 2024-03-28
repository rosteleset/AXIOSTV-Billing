=head2 NAME

  Tasks

=cut

use strict;
use warnings FATAL => 'all';
use Encode qw(_utf8_on);

use AXbills::Base qw(urlencode in_array int2byte convert);
use Msgs::Misc::Attachments;
use Shedule;
use Address;

our (
  $db,
  %conf,
  %lang,
  $admin,
  %permissions,
  @WEEKDAYS,
  @MONTHES,
  @MONTHES_LIT,
  %msgs_permissions
);

our AXbills::HTML $html;
#my $Address = Address->new($db, $admin, \%conf);
my $Msgs = Msgs->new($db, $admin, \%conf);
my $Notify = Msgs::Notify->new($db, $admin, \%conf, { LANG => \%lang, HTML=>$html });
my $Sender = AXbills::Sender::Core->new($db, $admin, \%conf);
my $Attachments = Msgs::Misc::Attachments->new($db, $admin, \%conf);

my @send_methods = ($lang{MESSAGE}, 'E-MAIL');
my @priority_colors = ('#8A8A8A', $_COLORS[8], $_COLORS[9], '#E06161', $_COLORS[6]);
my @priority = ($lang{VERY_LOW}, $lang{LOW}, $lang{NORMAL}, $lang{HIGH}, $lang{VERY_HIGH});

$_COLORS[6] //= 'red';
$_COLORS[8] //= '#FFFFFF';
$_COLORS[9] //= '#FFFFFF';

if ($conf{MSGS_REDIRECT_FILTER_ADD}) {
  $send_methods[3] = 'Web redirect';
}


#**********************************************************
=head2 msgs_admin_privileges($attr)

  Arguments:
    $aid

  Returns:
    \@A_CHAPTER, \%A_PRIVILEGES, \%CHAPTERS_DELIGATION

=cut
#**********************************************************
#TODO: Delete function
sub msgs_admin_privileges {
  my ($aid) = @_;

  my $admins = $Msgs->admins_list({ AID => $aid, DISABLE => 0, COLS_NAME => 1 });
  my %A_PRIVILEGES = ();
  my %CHAPTERS_DELIGATION = ();
  my @A_CHAPTER = ();

  foreach my $line (@{$admins}) {
    next if !$line->{chapter_id};

    push @A_CHAPTER, "$line->{chapter_id}:$line->{deligation_level}";
    $CHAPTERS_DELIGATION{ $line->{chapter_id} } = $line->{deligation_level};
    $A_PRIVILEGES{$line->{chapter_id}} = $line->{priority};
  }

  return \@A_CHAPTER, \%A_PRIVILEGES, \%CHAPTERS_DELIGATION;
}

#**********************************************************
=head2 msgs_admin($attr) - Admin messages

  Attributes:
    $attr

=cut
#**********************************************************
sub msgs_admin {
  my ($attr) = @_;

  $Msgs->{TAB1_ACTIVE} = 'active';

  $FORM{chg} = $FORM{CHG_MSGS} if ($FORM{CHG_MSGS});
  $FORM{del} = $FORM{DEL_MSGS} if ($FORM{DEL_MSGS});

  $Msgs->{ACTION} = 'send';
  $Msgs->{LNG_ACTION} = $lang{SEND};

  $FORM{chg} ||= $FORM{STORAGE_MSGS_ID} if $FORM{STORAGE_MSGS_ID} && $FORM{add};

  if ($FORM{chg} || $FORM{ID}) {
    $FORM{chg} =~ s/#// if ($FORM{chg});
    $Msgs->message_info($FORM{chg} || $FORM{ID});
    
    if ($msgs_permissions{1}{21} && (!$Msgs->{RESPOSIBLE} || $Msgs->{RESPOSIBLE} ne $admin->{AID})) {
      $html->message('err', $lang{ERROR}, $lang{ERR_ACCESS_DENY});
      return 1;
    }

    if ($msgs_permissions{4} && (!$Msgs->{CHAPTER} || !$msgs_permissions{4}{$Msgs->{CHAPTER}})) {
      $html->message('err', $lang{ERROR}, $lang{ERR_ACCESS_DENY});
      return 1;
    }

    if ($Msgs->{UID} && !$FORM{UID}) {
      my $user_info = user_info($Msgs->{UID});
      print $user_info->{TABLE_SHOW} || q{};
    }
    $FORM{UID} = $Msgs->{UID} || 0;
  }

  $FORM{index} = get_function_index($FORM{get_index}) if (!$FORM{index} && $FORM{get_index});

  my $uid = $FORM{UID};
  #Get admin privileges
  # my ($A_CHAPTER, $A_PRIVILEGES, $CHAPTERS_DELIGATION) = msgs_admin_privileges($admin->{AID});

  if ($FORM{ajax} && $FORM{SURVEY_ID}) {
    $Msgs->survey_subject_info($FORM{SURVEY_ID});
    print "$Msgs->{TPL}";
    return 1;
  }

  if ($FORM{PLUGIN} && ($FORM{ID} || $FORM{chg})) {
    my $plugin = msgs_get_plugin_by_name($FORM{PLUGIN});

    if ($plugin->can('plugin_show')) {
      $Msgs->message_info($FORM{chg} || $FORM{ID});
      my $result = $plugin->plugin_show({ %{$Msgs}, %FORM,
        PRIORITY_COLORS     => \@priority_colors,
        PRIORITY_ARRAY      => \@priority
      });
      delete $FORM{PLUGIN};

      return $result->{RETURN_VALUE} if $result && ref $result eq 'HASH' && $result->{RETURN_VALUE};
    }
  }

  if ($FORM{TASK}) {
    require Msgs::Tasks;
    msgs_tasks();
    return 1;
  }
  elsif ($FORM{CHANGE_SUBJECT} && $FORM{SUBJECT} ne '' && $msgs_permissions{1} && $msgs_permissions{1}{4}) {
    $Msgs->message_change({
      ID      => $FORM{chg},
      SUBJECT => $FORM{SUBJECT},
    });
    _error_show($Msgs);

    $Msgs->message_reply_add({
      ID              => $FORM{chg},
      REPLY_TEXT      => "$lang{SUBJECT_CHANGED} '$FORM{OLD_SUBJECT}' $lang{ON} '$FORM{SUBJECT}'",
      REPLY_INNER_MSG => 1,
      AID             => $admin->{AID},
    });
    _error_show($Msgs);
  }
  elsif ($FORM{NEXT_MSG}) {
    # Get next message
    my $list = $Msgs->messages_list({
      ID        => ">$FORM{NEXT_MSG}",
      STATE     => 0,
      PAGE_ROWS => 1,
      COLS_NAME => 1,
    });

    if ($Msgs->{TOTAL} > 0) {
      my $user_info = user_info($list->[0]->{uid});
      if ($user_info) {
        print $user_info->{TABLE_SHOW} || q{};
      }
      msgs_ticket_show({ ID => $list->[0]->{id} });
      return 1;
    }
  }
  elsif ($FORM{STORAGE_MSGS_ID}) {
    load_module('Storage', $html);
    if ($FORM{add}) {
      storage_hardware({ ADD_ONLY => 1 });

      if ($FORM{INSTALLATION_ID}) {
        my @installations = split(',\s?', $FORM{INSTALLATION_ID});
        foreach my $installation (@installations) {
          next if !$installation;

          $Msgs->msgs_storage_add({
            MSGS_ID         => $FORM{STORAGE_MSGS_ID},
            INSTALLATION_ID => $installation,
          });
        }
      }

      $FORM{chg} ||= $FORM{STORAGE_MSGS_ID};
      $html->redirect("?index=$index" . "&UID=" . ($FORM{UID} || q{}) . "&chg=" . ($FORM{chg} || q{}) . "#last_msg", {
        WAIT         => '0'
      });
      return;
    }
    else {
      storage_hardware();

      return 1;
    }
  }
  elsif ($FORM{reply} && $FORM{ID}) {
    my $plugin_result = _msgs_call_action_plugin('BEFORE_REPLY', { %{($attr) ? $attr : {}} });
    return $plugin_result if defined $plugin_result;

    $Msgs->{TAB2_ACTIVE} = "active";
    _msgs_reply_admin();
    return 1;
  }
  elsif ($FORM{ATTACHMENT}) {
    return msgs_attachment_show(\%FORM);
  }
  elsif ($FORM{PHOTO}) {
    my $media_return = form_image_mng({ TO_RETURN => 1 });

    if ($FORM{IMAGE}) {
      $FORM{reply} = 1;
      $FORM{ID} = $FORM{PHOTO};
      $FORM{FILE_UPLOAD} = $media_return;
      msgs_admin();
    }

    return 0;
  }
  elsif ($FORM{del} && $FORM{UPDATE_STATUS}) {
    my @id_msgs = ();
    @id_msgs = split(/, /, $FORM{del});

    my @id_error_change = ();

    foreach my $id (@id_msgs) {
      $Msgs->message_change({
        ID    => $id,
        STATE => $FORM{STATE_CHANGE} || 2
      });

      push @id_error_change, $id if ($Msgs->{errno});
    }

    if ($#id_error_change > 0) {
      $html->message('err', $lang{ERROR}, "$lang{ERROR}: " . join(', ', @id_error_change));
    }
    else {
      $html->message('info', $lang{INFO}, $lang{SUCCESS});
    }
  }
  if ($FORM{chg}) {
    $Msgs->{TAB2_ACTIVE} = (!$Msgs->{TAB1_ACTIVE}) ? "active" : "";
    msgs_ticket_show();

    return 0;
  }
  elsif ($FORM{change}) {
    my $plugin_result = _msgs_call_action_plugin('BEFORE_CHANGE', { %{($attr) ? $attr : {}} });
    msgs_ticket_change() if (!defined($plugin_result));

    msgs_ticket_show();

    return 1;
  }
  elsif ($FORM{del} && $FORM{COMMENTS} && $msgs_permissions{1} && $msgs_permissions{1}{1}) {
    msgs_redirect_filter({ DEL => 1, UID => $uid, MSG_ID => $FORM{del} });

    $Msgs->message_team_del($FORM{del});
    if (!_error_show($Msgs)) {
      $Msgs->message_del({ ID => $FORM{del}, UID => $uid });
      $html->message('info', $lang{INFO}, "$lang{DELETED} # $FORM{del}") if (!$Msgs->{errno});
    }
    else {
      $html->message('err', $lang{ERROR}, $lang{ERROR});
    }
  }

  # if (scalar keys %{$CHAPTERS_DELIGATION} > 0) {
  #   $LIST_PARAMS{CHAPTERS_DELIGATION} = $CHAPTERS_DELIGATION;
  #   $LIST_PARAMS{PRIVILEGES} = $A_PRIVILEGES;
  #   $LIST_PARAMS{UID} = undef if (!$uid);
  # }

  if ($FORM{search_form}) {
    msgs_form_search();
  }
  elsif ($FORM{add_form}) {
    my $return = msgs_admin_add();
    return ($return == 2) ? 2 : 1;
  }

  $LIST_PARAMS{STATE} = undef if ($FORM{STATE} && $FORM{STATE} =~ /^\d+$/ && $FORM{STATE} == 3);
  $LIST_PARAMS{PRIORITY} = undef if ($FORM{PRIORITY} && $FORM{PRIORITY} =~ /^\d+$/ && $FORM{PRIORITY} == 5);
  $LIST_PARAMS{CHAPTER} = $FORM{CHAPTER} if ($FORM{CHAPTER});
  $LIST_PARAMS{DESC} = 'DESC' if (!$FORM{sort});
  $LIST_PARAMS{RESPOSIBLE} = $attr->{ADMIN}->{AID} if ($attr->{ADMIN}->{AID});

  msgs_list();

  return 1;
}

#**********************************************************
=head2 msgs_ticket_change($attr)

=cut
#**********************************************************
sub msgs_ticket_change {

  $Msgs->{TAB3_ACTIVE} = "active";

  $Msgs->status_info($FORM{STATE});
  if ($Msgs->{TOTAL} > 0 && $Msgs->{TASK_CLOSED}) {
    $FORM{CLOSED_DATE} = "$DATE  $TIME";
    $FORM{STATE} = 0 if $Msgs->{TASK_CLOSED} && (!$msgs_permissions{1} || !$msgs_permissions{1}{3});
  }
  $FORM{DONE_DATE} = $DATE if (defined $FORM{STATE} && $FORM{STATE} > 1);
  delete $FORM{PRIORITY} if !$msgs_permissions{1} || !$msgs_permissions{1}{13};
  delete $FORM{RESPOSIBLE} if !$msgs_permissions{1} || !$msgs_permissions{1}{16};
  delete $FORM{DISPATCH_ID} if !$msgs_permissions{1} || !$msgs_permissions{1}{26};

  if (!$FORM{PLUGIN} && !$FORM{SKIP_PLUGIN}) {
    # _msgs_change_resposible will need AID of current responsible admin,
    # so should be executed first
    # We skip changing inside to avoid unnecessary queries
    _msgs_change_responsible($FORM{ID}, $FORM{RESPOSIBLE}, { SKIP_CHANGE => 1 }) if defined $FORM{RESPOSIBLE};
    $Msgs->message_change({ %FORM, USER_READ => "0000-00-00  00:00:00" });
  }

  $html->message('info', $lang{INFO}, $lang{CHANGED}) if !_error_show($Msgs);

  if (defined $FORM{WATCHERS} && $msgs_permissions{1} && $msgs_permissions{1}{17}) {
    $Msgs->msg_watch_del({ ID => $FORM{ID} });
    map $Msgs->msg_watch({ AID => $_, ID => $FORM{ID} }), split(',\s?', $FORM{WATCHERS}) if $FORM{WATCHERS};
  }

  $FORM{chg} = $FORM{ID} if $FORM{ID};

  return 1;
}

#**********************************************************
=head2 msgs_admin_add($attr)

=cut
#**********************************************************
sub msgs_admin_add {
  my ($attr) = @_;

  return 1 if !$msgs_permissions{1}{0} && !$attr->{REGISTRATION};
  return 1 if (!$FORM{SUBJECT} || !$FORM{MESSAGE}) && defined $FORM{SUBJECT} && $attr->{REGISTRATION};

  my $msgs_status = msgs_sel_status({ HASH_RESULT => 1 });
  $FORM{send_message} = 1 if ($FORM{add} && $FORM{next});

  my $return_value = _msgs_admin_send_message($attr, $msgs_status);
  return $return_value if defined($return_value);

  print msgs_admin_add_form({ %{($attr) ? $attr : {}}, MSGS_STATUS => $msgs_status });

  return $FORM{PREVIEW_FORM} ? 2 : 1;
}

#**********************************************************
=head2 _msgs_admin_send_message($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub _msgs_admin_send_message {
  my ($attr, $msgs_status) = @_;

  return if !$FORM{send_message} && !$FORM{PREVIEW};

  #Multi send
  my $message = '';
  my @msgs_ids = ();
  my %NUMBERS = ();
  my @ATTACHMENTS = ();

  $FORM{LOCATION_ID} =~ s/,\s?//g if $FORM{LOCATION_ID};
  $FORM{STREET_ID} =~ s/,\s?//g if $FORM{STREET_ID};
  $FORM{DISTRICT_ID} =~ s/,\s?//g if $FORM{DISTRICT_ID};
  $FORM{ADDRESS_FLAT} =~ s/,\s?//g if $FORM{ADDRESS_FLAT};

  for (my $i = 0; $i <= 2; $i++) {
    my $input_name = 'FILE_UPLOAD' . (($i > 0) ? "_$i" : '');

    next if !$FORM{ $input_name }->{filename};

    push @ATTACHMENTS, {
      FILENAME     => $FORM{ $input_name }->{filename},
      CONTENT_TYPE => $FORM{ $input_name }->{'Content-Type'},
      FILESIZE     => $FORM{ $input_name }->{Size},
      CONTENT      => $FORM{ $input_name }->{Contents},
    };
  }

  $FORM{STATE} = 2 if ($FORM{SEND_TYPE} && ($FORM{SEND_TYPE} == 1));
  $FORM{UID} =~ s/,/;/g if ($FORM{UID});

  my %query_data = ();
  my @skip_keys = ('LOCATION_ID', 'STREET_ID');
  map $query_data{$_} = $FORM{$_} ? $FORM{$_} : in_array($_, \@skip_keys) ? undef : '_SHOW', keys %FORM;
  my $users_list = $users->list({
    LOGIN     => '_SHOW',
    FIO       => '_SHOW',
    PHONE     => '_SHOW',
    EMAIL     => '_SHOW',
    %query_data,
    UID       => ($FORM{UID} && $FORM{UID} =~ /\d+/) ? $FORM{UID} : undef,
    GID       => $FORM{GID},
    PAGE_ROWS => 1000000,
    DISABLE   => ($FORM{GID}) ? 0 : undef,
    COLS_NAME => 1,
  });

  _msgs_show_preview($users_list);
  return if $FORM{PREVIEW_FORM};

  my $plugin_result = _msgs_call_action_plugin('BEFORE_CREATE', {
    %{($attr) ? $attr : {}},
    MSGS_STATUS => $msgs_status,
    USERS_LIST  => $users_list
  });
  return $plugin_result if defined $plugin_result;

  if ($FORM{SURVEY_ID} && !$FORM{SUBJECT}) {
    $Msgs->survey_subject_info($FORM{SURVEY_ID});
    $FORM{SUBJECT} = $Msgs->{NAME} || q{};

    push(@ATTACHMENTS, {
      FILENAME     => $Msgs->{FILENAME} || q{},
      CONTENT_TYPE => $Msgs->{FILE_CONTENT_TYPE} || '',
      FILESIZE     => $Msgs->{FILE_SIZE} || '',
      CONTENT      => $Msgs->{FILE_CONTENTS} || '',
    }) if $Msgs->{FILENAME};
  }

  my @uids = ();
  my %msg_for_uid = ();
  if (!$FORM{UID} && $FORM{LOCATION_ID} && $FORM{CHECK_FOR_ADDRESS} && $msgs_permissions{1}{6}) {
    $Msgs->message_add({
      %FORM,
      MESSAGE    => $FORM{MESSAGE},
      STATE      => ((!$FORM{STATE} || $FORM{STATE} == 0) && !$FORM{INNER_MSG}) ? 6 : $FORM{STATE},
      ADMIN_READ => (!$FORM{INNER_MSG}) ? "$DATE $TIME" : '0000-00-00 00:00:00',
      USER_READ  => '0000-00-00 00:00:00',
      IP         => $admin->{SESSION_IP}
    });
    $Msgs->quick_replys_tags_add({ IDS => $FORM{TAGS_IDS}, MSG_ID => $Msgs->{MSG_ID} }) if $FORM{TAGS_IDS} && !_error_show($Msgs);
  }
  else {
    my $result = _msgs_make_delivery(\@uids, \%NUMBERS, \@msgs_ids, \%msg_for_uid, $users_list, $attr);
    return $result if $result;
    $html->message('err', $lang{ERROR}, $lang{NO_CONTACTS_FOR_TYPE}, { ID => 781 }) if ($#msgs_ids < 0);
  }

  if ($FORM{DAY}) {
    $html->message('info', $lang{SHEDULE}, "$lang{ADDED} $lang{SHEDULE}");
    return 1;
  }

  if ($users->{TOTAL} > 1) {
    $message = "$lang{TOTAL}: $users->{TOTAL}";
    $LIST_PARAMS{PAGE_ROWS} = 25;
  }

  my $msg_id = ($#msgs_ids > -1) ? $msgs_ids[0] : $Msgs->{MSG_ID};
  my $att_result = _msgs_add_attachments(\@ATTACHMENTS, $msg_id, ($#uids == 0) ? $uids[0] : '_');

  if (!$FORM{INNER_MSG}) {
    #Web redirect
    if ($FORM{SEND_TYPE} && $FORM{SEND_TYPE} == 3) {
      msgs_redirect_filter({ UID => join(',', @uids) });
    }
    else {
      my $attachments_list = $Msgs->attachments_list({
        MESSAGE_ID   => $msg_id,
        FILENAME     => '_SHOW',
        CONTENT      => '_SHOW',
        CONTENT_TYPE => '_SHOW',
        CONTENT_SIZE => '_SHOW'
      });

      $Notify->notify_user({
        STATE_ID       => $FORM{STATE},
        STATE          => ($FORM{STATE} && $msgs_status->{$FORM{STATE}}) ? $msgs_status->{$FORM{STATE}} : q{},
        REPLY_ID       => 0,
        MSGS           => $Msgs,
        SEND_TYPE      => $FORM{SEND_TYPE},
        MESSAGES_BATCH => \%msg_for_uid,
        ATTACHMENTS    => $attachments_list
      });
    }
  }
  return $att_result if $att_result;

  $Notify->notify_admins({ MSG_ID => $msg_id, %FORM })  if $FORM{RESPOSIBLE} && $FORM{INNER_MSG};

  return 0 if ($attr->{SEND_ONLY} || $attr->{REGISTRATION});

  if ($#msgs_ids > -1) {
    $FORM{ID} = join(',', @msgs_ids);
    my $header_message = urlencode("$lang{MESSAGE} $lang{SENDED}" . ($FORM{ID} ? " : $FORM{ID}" : ''));
    $html->redirect("?index=$index" . ($FORM{UID} ? "&UID=$FORM{UID}" : '') . "&MESSAGE=$header_message#last_msg");
  }

  return 0;
}

#**********************************************************
=head2 _msgs_make_delivery($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub _msgs_make_delivery {
  my ($uids, $NUMBERS, $msgs_ids, $msg_for_uid, $users_list, $attr) = @_;

  return 1 if !$users_list || ref $users_list ne 'ARRAY';

  foreach my $user_info (@{$users_list}) {
    $FORM{UID} = $user_info->{uid};
    if ($user_info->{phone}) {
      $user_info->{phone} =~ s/(.*);.*/$1/;
      $NUMBERS->{ $user_info->{phone} } = $user_info->{uid};
    }
    push @{$uids}, $user_info->{uid};

    my $user_pi = $users->pi({ UID => $user_info->{uid}, COLS_NAME => 1, COLS_UPPER => 1 });
    my $internet_info = {};
    if (in_array('Internet', \@MODULES)) {
      require Internet;
      Internet->import();
      my $Internet = Internet->new($db, $admin, \%conf);
      $internet_info = $Internet->user_info($user_info->{uid}, { COLS_NAME => 1, COLS_UPPER => 1 });
    }

    my $message = $html->tpl_show($FORM{MESSAGE}, { USER_LOGIN => $user_pi->{LOGIN}, %{$user_pi}, %{$internet_info} }, {
      OUTPUT2RETURN      => 1,
      SKIP_DEBUG_MARKERS => 1
    });

    next if _msgs_add_shedule($user_info, $message);

    $Msgs->message_add({
      %FORM,
      MESSAGE    => $message,
      STATE      => ((!$FORM{STATE} || $FORM{STATE} == 0) && !$FORM{INNER_MSG}) ? 6 : $FORM{STATE},
      ADMIN_READ => (!$FORM{INNER_MSG}) ? "$DATE $TIME" : '0000-00-00 00:00:00',
      USER_READ  => '0000-00-00 00:00:00',
      IP         => $admin->{SESSION_IP}
    });

    return 0 if _error_show($Msgs);

    $Msgs->quick_replys_tags_add({ IDS => $FORM{TAGS_IDS}, MSG_ID => $Msgs->{MSG_ID} }) if $FORM{TAGS_IDS};

    my $plugin_result = _msgs_call_action_plugin('AFTER_CREATE', { %{($attr) ? $attr : {}} }, { ID => $Msgs->{MSG_ID} });
    return $plugin_result if defined $plugin_result;

    return 1 if ($attr->{REGISTRATION});

    push @{$msgs_ids}, $Msgs->{MSG_ID};
    $msg_for_uid->{$user_info->{uid}} = { MSG_ID => $Msgs->{MSG_ID} };
  }
}

#**********************************************************
=head2 _msgs_show_preview($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub _msgs_show_preview {
  my ($users_list) = @_;

  return 0 if !$FORM{PREVIEW};

  $html->message('info', $lang{INFO}, "$lang{PRE}\n $lang{TOTAL}: $users->{TOTAL}");
  my AXbills::HTML $table;
  ($table) = result_former({
    INPUT_DATA      => $users,
    LIST            => $users_list,
    HIDDEN_FIELDS   => 'BUILD_ID',
    BASE_FIELDS     => 1,
    MULTISELECT     => 'UID:uid',
    FUNCTION_FIELDS => '',
    TABLE           => {
      width      => '100%',
      ID         => 'USERS_LIST',
      SELECT_ALL => "users_list:UID:$lang{SELECT_ALL}",
    },
    MAKE_ROWS       => 1,
  });

  $index = $FORM{index} if $FORM{index} && $index != $FORM{index};

  $FORM{PREVIEW_FORM} = $table->show();
}

#**********************************************************
=head2 _msgs_add_shedule($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub _msgs_add_shedule {
  my ($user_info, $message) = @_;

  return 0 if !$FORM{DAY};

  _utf8_on($FORM{SUBJECT});
  _utf8_on($message);

  my $args = {
    UID        => $user_info->{uid},
    CHAPTER    => $FORM{CHAPTER},
    SUBJECT    => $FORM{SUBJECT},
    PRIORITY   => $FORM{PRIORITY},
    RESPOSIBLE => $FORM{RESPOSIBLE},
    MESSAGE    => $message,
    STATE      => ((!$FORM{STATE} || $FORM{STATE} == 0) && !$FORM{INNER_MSG}) ? 6 : $FORM{STATE},
    USER_READ  => '0000-00-00 00:00:00',
    IP         => $admin->{SESSION_IP}
  };

  my %action_hash = (module => 'Msgs', function => 'message_add', args => $args);

  my $json_action = JSON::to_json(\%action_hash);
  my $Shedule = Shedule->new($db, $admin, \%conf);

  $FORM{DAY} = sprintf("%02d", $FORM{DAY}) unless ($FORM{DAY} eq '*');
  $FORM{MONTH} = sprintf("%02d", $FORM{MONTH}) unless ($FORM{MONTH} eq '*');;

  $Shedule->add({
    DESCRIBE => 'Admin message shedule',
    D        => $FORM{DAY} || '*',
    M        => $FORM{MONTH} || '*',
    Y        => $FORM{YEAR} || '*',
    TYPE     => 'call_fn',
    ACTION   => $json_action,
    COUNTS   => ($FORM{PERIODIC} ? '999' : '0'),
    UID      => $user_info->{uid},
  });

  return 1;
}

#**********************************************************
=head2 _msgs_add_attachments($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub _msgs_add_attachments {
  my ($ATTACHMENTS, $msg_id, $uid) = @_;

  return if $Msgs->{errno} || !$Msgs->{MSG_ID};

  #Add attachment
  for (my $i = 0; $i <= $#{$ATTACHMENTS}; $i++) {
    $Attachments->attachment_add({
      MSG_ID => $msg_id,
      # Do not create subdirectories if have multiple uids
      UID    => $uid,
      %{$ATTACHMENTS->[$i]}
    });
  }

  $html->message('info', $lang{MESSAGES}, "$lang{SENDED} $lang{MESSAGE}");

  if ($FORM{INNER_MSG}) {
    # $Notify->notify_admins();
    if ($FORM{SURVEY_ID}) {
      $FORM{chg} = $Msgs->{MSG_ID};
      msgs_admin();
      return 0;
    }
  }

  return;
}

#**********************************************************
=head2 msgs_admin_add_form($attr) - Show message

  Arguments:
    $attr

  Returns:

=cut
#**********************************************************
sub msgs_admin_add_form {
  my ($attr) = @_;

  my $msgs_status = $attr->{MSGS_STATUS};
  my %tpl_info = ();

  if ($attr->{ACTION}) {
    $tpl_info{ACTION} = $attr->{ACTION};
    $tpl_info{LNG_ACTION} = $attr->{LNG_ACTION};
  }
  else {
    $tpl_info{ACTION} = 'send_message';
    $tpl_info{LNG_ACTION} = $lang{SEND};
  }

  if ($msgs_permissions{3}{0} && $msgs_permissions{3}{2}) {
    $Msgs->{DISPATCH_SEL} = $html->form_select('DISPATCH_ID', {
      SELECTED    => $Msgs->{DISPATCH_ID} || '',
      SEL_LIST    => $Msgs->dispatch_list({ COMMENTS => '_SHOW', PLAN_DATE => '_SHOW', STATE => 0, COLS_NAME => 1 }),
      SEL_OPTIONS => { '' => '--' },
      SEL_KEY     => 'id',
      SEL_VALUE   => 'plan_date,comments'
    });
  }
  else {
    $tpl_info{DISPATCH_HIDE} = 'd-none';
  }

  $Msgs->{CHAPTER_SEL} =$html->form_select('CHAPTER', {
    SELECTED       => $Msgs->{CHAPTER},
    SEL_LIST => $Msgs->chapters_list({
      CHAPTER   => $msgs_permissions{4} ? join(',', keys %{$msgs_permissions{4}}) : '_SHOW',
      DOMAIN_ID => $users->{DOMAIN_ID},
      COLS_NAME => 1
    }),
    MAIN_MENU      => get_function_index('msgs_chapters'),
    MAIN_MENU_ARGV => ($Msgs->{CHAPTER}) ? "chg=$Msgs->{CHAPTER}" : ''
  });
  $tpl_info{ATTACH_ADDRESS_HIDE} = 'd-none' if $FORM{UID} || !$msgs_permissions{1}{6};
  $tpl_info{INNER_MSG_HIDE} = 'd-none' if !$msgs_permissions{1}{7};
  $tpl_info{DISPATCH_ADD_HIDE} = 'd-none' if !$msgs_permissions{3}{1};

  if ((!$FORM{UID} || $FORM{UID} =~ /;/) && !$FORM{TASK}) {
    $tpl_info{GROUP_SEL} = sel_groups({ MULTISELECT => 1 });
    $tpl_info{ADDRESS_FORM} = form_address({
      LOCATION_ID      => $FORM{LOCATION_ID} || '',
      SHOW_ADD_BUTTONS => 1,
      ADDRESS_HIDE     => 1
    });

    if (in_array('Tags', \@MODULES)) {
      if (!$admin->{MODULES} || $admin->{MODULES}{'Tags'}) {
        load_module('Tags', $html);

        $tpl_info{TAGS_FORM} = $html->tpl_show(templates('form_row'), {
          VALUE => tags_sel(),
          NAME  => $lang{TAGS},
          ID    => 'TAGS'
        }, { OUTPUT2RETURN => 1 });
      }
    }

    $tpl_info{DATE_PIKER} = $html->form_datepicker('DELIVERY_SEND_DATE');
    $tpl_info{TIME_PIKER} = $html->form_timepicker('DELIVERY_SEND_TIME');
    $tpl_info{STATUS_SELECT} = msgs_sel_status({ NAME => 'DELIVERY_STATUS' });

    $tpl_info{PRIORITY_SELECT} = $html->form_select('DELIVERY_PRIORITY', {
      SELECTED     => 2,
      SEL_ARRAY    => \@priority,
      STYLE        => \@priority_colors,
      ARRAY_NUM_ID => 1
    });

    $tpl_info{SEND_METHOD_SELECT} = $html->form_select('DELIVERY_SEND_METHOD', {
      SELECTED     => 2,
      SEL_ARRAY    => \@send_methods,
      ARRAY_NUM_ID => 1
    });
    $tpl_info{DELIVERY_ADD_HIDE} = 'd-none' if !$msgs_permissions{2}{1};

    $tpl_info{DELIVERY_SELECT_FORM} = sel_deliverys({ SKIP_MULTISELECT => 1, SELECTED => $FORM{DELIVERY} || '' });
    $tpl_info{SEND_DELIVERY_FORM} = $msgs_permissions{2}{0} && $msgs_permissions{2}{4} ?
      $html->tpl_show(_include('msgs_delivery_form', 'Msgs'),
        { %{$attr}, %FORM, %tpl_info, %{$Msgs} }, { OUTPUT2RETURN => 1 }) : '';

    $tpl_info{BACK_BUTTON} = $html->form_input('PREVIEW', $lang{PRE}, { TYPE => 'submit' });
    $tpl_info{GROUP_HIDE} = 'display: none' unless ($permissions{0}{28});

    $tpl_info{SEND_EXTRA_FORM} = $html->tpl_show(_include('msgs_send_extra', 'Msgs'),
      \%tpl_info,
      { OUTPUT2RETURN => 1, ID => 'msgs_send_extra' });
  }

  #Message send  type
  my %send_types = (0 => $lang{MESSAGE});
  my $sender_send_types = $Sender->available_types(
    { HASH_RETURN => 1, CLIENT => 1, SOFT_CHECK => 1 }
  );

  %send_types = (%send_types, %$sender_send_types);
  $send_types{3} = 'Msgs redirect' if $conf{MSGS_REDIRECT_FILTER_ADD};

  my $send_types = $html->form_select('SEND_TYPE', {
    SELECTED => $Msgs->{SEND_TYPE} || $FORM{SEND_TYPE} || 0,
    SEL_HASH => \%send_types,
    NO_ID    => 1
  });

  $tpl_info{SEND_TYPES_FORM} = $html->tpl_show(templates('form_row'), {
    ID    => 'SEND_TYPE',
    NAME  => $lang{SEND},
    VALUE => $send_types
  }, { OUTPUT2RETURN => 1 });

  $tpl_info{STATE_SEL} = $html->form_select('STATE', {
    SELECTED   => $Msgs->{STATE} || 0,
    SEL_HASH   => {
      0 => $msgs_status->{0},
      1 => $msgs_status->{1},
      2 => $msgs_status->{2},
      9 => $msgs_status->{9},
    },
    USE_COLORS => 1,
    NO_ID      => 1
  });

  $tpl_info{PRIORITY_SEL} = $html->form_select('PRIORITY', {
    SELECTED     => 2,
    SEL_ARRAY    => \@priority,
    STYLE        => \@priority_colors,
    ARRAY_NUM_ID => 1
  });

  if ($msgs_permissions{1}{19}) {
    $tpl_info{MSGS_TAGS} = msgs_quick_replys_tags({ RETURN_LIST => 1 });
  }
  else {
    $tpl_info{MSGS_TAGS_HIDE} = 'd-none';
  }
  $tpl_info{RESPOSIBLE} = sel_admins({ NAME => 'RESPOSIBLE', SELECTED => $admin->{AID}, DISABLE => 0 });
  $tpl_info{INNER_MSG} = 'checked' if ($conf{MSGS_INNER_DEFAULT});
  $tpl_info{SURVEY_SEL} = msgs_survey_sel();
  $tpl_info{SURVEY_HIDE} = !$msgs_permissions{1}{20} ? 'd-none' : '';
  $tpl_info{SUBJECT_SEL} = msgs_sel_subject({ EX_PARAMS => 'disabled=disabled required' });
  $tpl_info{PERIODIC} = 'checked' if ($FORM{PERIODIC});
  $tpl_info{PAR} = $attr->{PAR} if ($attr->{PAR});
  $tpl_info{PLAN_DATETIME_INPUT} = $html->form_datetimepicker(
    'PLAN_DATETIME',
    (
      ($Msgs->{PLAN_DATE} && $Msgs->{PLAN_DATE} ne '0000-00-00' ? $Msgs->{PLAN_DATE}
        . ' '
        . ($Msgs->{PLAN_TIME} && $Msgs->{PLAN_TIME} ne '00:00:00' ? $Msgs->{PLAN_TIME} : '00:00') : '')
    ),
    {
      ICON           => 1,
      TIME_HIDDEN_ID => 'PLAN_TIME',
      DATE_HIDDEN_ID => 'PLAN_DATE',
      EX_PARAMS      => q{pattern='^\d\d\d\d-(0?[1-9]|1[0-2])-(0?[1-9]|[12][0-9]|3[01]) (00|0?[0-9]|1[0-9]|2[0-3]):([0-9]|[0-5][0-9])$'},
    }
  );
  $FORM{CHECK_REPEAT} = $conf{MSGS_CHECK_REPEAT} ? 1 : 0;

  my $add_tpl_form = ($attr->{TASK_ADD}) ? 'msgs_task' : 'msgs_send_form';

  if ($FORM{MESSAGE}) {
    $Msgs->{TPL_MESSAGE} = $FORM{MESSAGE} || '';
    $Msgs->{TPL_MESSAGE} =~ s/\%/&#37/g;
  }

  my $message_form = $html->tpl_show(_include($add_tpl_form, 'Msgs'), { %{$attr}, %FORM, %{$Msgs}, %tpl_info }, {
    OUTPUT2RETURN => 1,
    ID            => 'MSGS_SEND_FORM'
  });

  return $message_form;
}


#**********************************************************
=head2 msgs_ticket_show($attr) - Show message

  Arguments:
    $attr
      ID

  Returns:
    TRUE or FALSE

=cut
#**********************************************************
sub msgs_ticket_show {
  my ($attr) = @_;

  my $message_id = $attr->{ID} || $FORM{chg} || 0;
  my $msgs_managment_tpl = 'msgs_managment';
  my $msgs_show_tpl = 'msgs_show';
  $FORM{UID} ||= $attr->{UID};

  $html->message('info', '', $FORM{MESSAGE}) if ($FORM{MESSAGE});

  if ($FORM{make_new} && $msgs_permissions{1} && $msgs_permissions{1}{25}) {
    my $old_reply = $Msgs->messages_reply_list({ ID => $FORM{make_new}, COLS_NAME => 1, COLS_UPPER => 1 });
    my $reply_text = $old_reply->[0]->{TEXT};
    $old_reply->[0]->{TEXT} =~ s/^/>  /g;
    $old_reply->[0]->{TEXT} =~ s/\n/\n> /g;
    $old_reply->[0]->{TEXT} .= "\n $lang{CREATE_TOPIC_MESSAGE}";

    $Msgs->message_add({
      USER_SEND => 1,
      UID       => $FORM{UID},
      MESSAGE   => "$lang{AUTO_CREATE_TEXT}: [[$FORM{chg}]]\n$reply_text",
      SUBJECT   => $FORM{COMMENTS},
      CHAPTER   => $FORM{chapter},
      PRIORITY  => 2,
      #TODO More fields maybe
    });

    $Attachments->attachment_copy($FORM{make_new}, $Msgs->{MSG_ID}, $FORM{UID});

    $old_reply->[0]->{TEXT} .= "\n$lang{NEW_TOPIC}: [[$Msgs->{MSG_ID}]]";
    $Msgs->message_reply_change($old_reply->[0]);
  }

  if ($FORM{reply_del} && $FORM{COMMENTS} && $msgs_permissions{1} && $msgs_permissions{1}{11}) {
    if ($FORM{SURVEY_ID} && $FORM{CLEAN}) {
      $Msgs->survey_answer_del(\%FORM);
    }
    else {
      $Msgs->message_reply_del({ ID => $FORM{reply_del} });
    }
    $html->message('info', $lang{INFO}, "$lang{DELETED}  [$FORM{reply_del}] ") if !$Msgs->{errno};
  }

  my $msgs_status = msgs_sel_status({ HASH_RESULT => 1, TASK_CLOSED => !$msgs_permissions{1}{3} ? 0 : undef });
  print msgs_status_bar({
    NO_UID      => ($FORM{UID}) ? undef : 1,
    TABS        => 1,
    NEXT        => 1,
    MSGS_STATUS => $msgs_status
  });

  $Msgs->message_info($message_id);
  return 1 if _error_show($Msgs);

  if ($FORM{chg} && !($Msgs->{ID})) {
    $html->message('err', $lang{ERROR}, "$lang{ERR_WRONG_DATA}");
    return 1;
  }

  $Msgs->{MAIN_ID} = $Msgs->{ID};
  $Msgs->{ACTION} = 'reply';
  $Msgs->{LNG_ACTION} = $lang{SEND};
  $Msgs->{STATE} //= 0;
  $Msgs->{PRIORITY} //= 0;
  $Msgs->{CHAPTER} //= 0;
  $Msgs->{STATE_NAME} = $html->color_mark($msgs_status->{ $Msgs->{STATE} });

  $Msgs->{EDIT} = $html->button($lang{EDIT}, '', {
    class     => 'btn btn-default btn-xs reply-edit-btn',
    ex_params => "reply_id='m$message_id'" }
  ) if $msgs_permissions{1}{5};
  $Msgs->{INNER_MSG_HIDE} = 'd-none' if !$msgs_permissions{1}{7};

  $Msgs->{STATE_SEL} = $html->form_select('STATE', {
    SELECTED     => $Msgs->{STATE} || 0,
    SEL_HASH     => $msgs_status,
    SORT_KEY_NUM => 1,
    USE_COLORS   => 1,
    NO_ID        => 1
  });

  $Msgs->{PRIORITY_TEXT} = $html->color_mark($priority[ $Msgs->{PRIORITY} ], $priority_colors[ $Msgs->{PRIORITY} ]);

  my $uid = $Msgs->{UID} || 0;

  $Msgs->{PLUGINS} = _msgs_show_right_plugins($Msgs, { %FORM,
    PRIORITY_COLORS     => \@priority_colors,
    PRIORITY_ARRAY      => \@priority
  });

  $Msgs->{EXT_INFO} = $html->tpl_show(_include($msgs_managment_tpl, 'Msgs'), { %{$users}, %{$Msgs},
    PHONE => $users->{PHONE} || $users->{CELL_PHONE} || '--' }, { OUTPUT2RETURN => 1 });

  my $REPLIES = msgs_ticket_reply($message_id);

  $Msgs->{MESSAGE} = convert($Msgs->{MESSAGE}, { text2html => 1, json => $FORM{json}, SHOW_URL => 1 });
  my $subject_before_convert = $Msgs->{SUBJECT} || '';
  $Msgs->{SUBJECT} = convert($Msgs->{SUBJECT}, { text2html => 1, json => $FORM{json} });
  if (!defined $Msgs->{TIMELINE_LAST_ITEM}) {
    $Msgs->{TIMELINE_LAST_ITEM} = $html->element('i', '', { 'class' => 'fas fa-clock bg-gray' })
  }


  my $msgs_rating_message = '';
  my $rating_icons = '';
  if ($Msgs->{RATING} && $Msgs->{RATING} > 0) {
    $rating_icons = msgs_assessment_stars($Msgs->{RATING});

    my $sig_image = '';
    if ($conf{TPL_DIR} && $Msgs->{UID} && $message_id) {
      my $sig_path = "$conf{TPL_DIR}/attach/msgs/$Msgs->{UID}/$message_id" . "_sig.png";
      if (-f $sig_path) {
        $sig_image = $html->img("/images/attach/msgs/$Msgs->{UID}/$message_id" . "_sig.png", 'signature');
      }
    }

    push @{$REPLIES}, $msgs_rating_message = $html->tpl_show(_include('msgs_rating_admin_show', 'Msgs'), {
      %{$Msgs},
      RATING_ICONS   => $rating_icons,
      RATING_COMMENT => $Msgs->{RATING_COMMENT},
      SIGNATURE      => $sig_image,
    }, { OUTPUT2RETURN => 1 });
    $Msgs->{TIMELINE_LAST_ITEM} = $html->element('i', '', { 'class' => 'fas fa-check bg-green' })
  }

  my %params = ();

  if (!$Msgs->{ACTIVE_SURWEY}) {# && _msgs_check_admin_privileges($A_PRIVILEGES, { CHAPTER => $Msgs->{CHAPTER}, HIDE_ALERT => 1 })) {

    if ($msgs_permissions{1} && $msgs_permissions{1}{8}) {
      $Msgs->{CHAPTERS_SEL} = $html->form_select('CHAPTER_ID', {
        SELECTED       => '',
        SEL_LIST       => $Msgs->chapters_list({
          DOMAIN_ID => $users->{DOMAIN_ID},
          CHAPTER   => $msgs_permissions{4} ? join(',', keys %{$msgs_permissions{4}}) : '_SHOW',
          COLS_NAME => 1
        }),
        MAIN_MENU      => get_function_index('msgs_chapters'),
        MAIN_MENU_ARGV => "chg=$Msgs->{CHAPTER}",
        SEL_OPTIONS    => { '' => '--' },
      });
    }
    else {
      $Msgs->{CHANGE_CHAPTER_HIDE} = 'd-none';
    }

    $params{REPLY_FORM} = $html->tpl_show(_include('msgs_reply', 'Msgs'), {
      %{$Msgs},
      REPLY_TEXT      => '',
      QUOTING         => $Msgs->{REPLY_QUOTE} || '',
      RUN_TIME_STATUS => 'DISABLE',
      MAIN_INNER_MSG  => $Msgs->{INNER_MSG},
      INNER_MSG       => ($FORM{INNER_MSG}) ? ' checked ' : '',
      SURVEY_SEL      => msgs_survey_sel(),
      SURVEY_HIDE     => !$msgs_permissions{1} || !$msgs_permissions{1}{20} ? 'd-none' : '',
      MAX_FILES       => $conf{MSGS_MAX_FILES} || 3
    }, { OUTPUT2RETURN => 1, ID => 'MSGS_REPLY', NO_SUBJECT => $lang{NO_SUBJECT} });
  }

  $params{REPLY} = join($FORM{json} ? ',' : '', @{$REPLIES});

  if ($Msgs->{FILENAME}) {
    my $attachments_list = $Msgs->attachments_list({
      MESSAGE_ID   => $Msgs->{ID},
      FILENAME     => '_SHOW',
      CONTENT_SIZE => '_SHOW',
      CONTENT_TYPE => '_SHOW',
      COORDX       => '_SHOW',
      COORDY       => '_SHOW',
    });

    $Msgs->{ATTACHMENT} = msgs_get_attachments_view($attachments_list);
  }

  if ($Msgs->{PRIORITY} == 4) {
    $params{MAIN_PANEL_COLOR} = 'card-danger';
  }
  elsif ($Msgs->{PRIORITY} == 3) {
    $params{MAIN_PANEL_COLOR} = 'card-warning';
  }
  elsif ($Msgs->{PRIORITY} >= 1) {
    $params{MAIN_PANEL_COLOR} = 'card-info';
  }
  else {
    $params{MAIN_PANEL_COLOR} = 'card-primary';
  }

  if ($msgs_permissions{1}{18}) {
    my $msg_tags_list = $Msgs->quick_replys_tags_list({ MSG_ID => $message_id, COLS_NAME => 1 });
    if ($Msgs->{TOTAL}) {
      foreach my $msg_tag (@{$msg_tags_list}) {
        $params{MSG_TAGS} .= ' ' . $html->element('span', $msg_tag->{reply}, {
          'class'                 => 'label new-tags mr-1',
          'style'                 => "background-color:" . ($msg_tag->{color} || q{}) . ";border-color:" . ($msg_tag->{color} || q{}) . ";font-weight: bold;",
          'data-tooltip'          => $msg_tag->{comment} || $msg_tag->{reply},
          'data-tooltip-position' => 'top'
        });
      }
    }
    elsif ($msgs_permissions{1}{19}) {
      $params{MSG_TAGS_DISPLAY_STATUS} = 1;
      $params{MSG_TAGS} = $html->button('', 'qindex=' . get_function_index('msgs_quick_replys_tags') .
        "&header=2&MSGS_ID=$message_id&UID=$uid", {
        LOAD_TO_MODAL => 1,
        class         => 'btn btn-sm btn-danger',
        ICON          => 'fa fa-tags',
        TITLE         => "$lang{ADD} $lang{TAGS}"
      });
    }
  }

  $Msgs->{ID} = $Msgs->{MAIN_ID};

  while ($Msgs->{MESSAGE} && $Msgs->{MESSAGE} =~ /\[\[(\d+)\]\]/) {
    my $msg_button = $html->button($1, "&index=$index&chg=$1", { class => 'badge bg-blue' });
    $Msgs->{MESSAGE} =~ s/\[\[\d+\]\]/$msg_button/;
  }

  # return 0 if(!_msgs_check_admin_privileges($A_PRIVILEGES, { CHAPTER => $Msgs->{CHAPTER} }));

  if ($msgs_permissions{1}{4}) {
    my $change_subject_index = get_function_index('_msgs_show_change_subject_template');
    $subject_before_convert =~ s/\'/\\\'/g;
    $params{CHANGE_SUBJECT_BUTTON} = $html->button(
      "$lang{CHANGE} $lang{SUBJECT}", "qindex=$change_subject_index&header=2&subject=$subject_before_convert&msg_id=$Msgs->{ID}",
      {
        LOAD_TO_MODAL  => 1,
        NO_LINK_FORMER => 1,
        class          => 'btn btn-sm btn-info',
        ICON           => 'fa fa-pencil-alt',
        TITLE          => $lang{SUBJECT}
      }
    );
  }

  $params{PROGRESSBAR} = msgs_progress_bar_show($Msgs);

  $params{PARENT_MSG} = $html->button('PARENT: ' . $Msgs->{PAR}, 'index=' . $index . "&chg=$Msgs->{PAR}",
      { class => 'btn btn-xs btn-default text-right' }) if ($Msgs->{PAR});
  $params{RATING_ICONS} = $html->element('div', $rating_icons, { class => 'btn btn-sm' }) if ($rating_icons);
  $params{LOGIN} = ($Msgs->{AID}) ? $html->b($Msgs->{A_NAME}) . " ($lang{ADMIN})" : $html->button($Msgs->{LOGIN}, "index=15&UID=$uid");
  $params{ADMIN_LOGIN} = $admin->{A_LOGIN};
  $params{INNER_MSG_TAG} = $html->element('span', $lang{INNER}, {
    'class' => 'label new-tags mr-1',
    'style' => "background-color:#f39c12;border-color:#f39c12;font-weight: bold;"
  }) if $Msgs->{INNER_MSG};

  $html->tpl_show(_include($msgs_show_tpl, 'Msgs'), { %{$Msgs}, %params });

  if (!$FORM{quick} && (!$Msgs->{RESPOSIBLE} || ($Msgs->{RESPOSIBLE} =~ /^\d+$/ && $Msgs->{RESPOSIBLE} == $admin->{AID}))) {
    my %msgs_params = (UID => $uid, ID => $message_id, SKIP_LOG => 1);
    $msgs_params{ADMIN_READ} = "$DATE $TIME" if !$FORM{deligate};

    $Msgs->message_change({ %msgs_params });
  }

  if ($conf{MSGS_CHAT}) {
    require Msgs::Chat;
    show_admin_chat();
  }

  my $plugins_info = _msgs_show_bottom_plugins($Msgs, { %FORM, %{$attr} });

  print $plugins_info;

  return 1;
}
#**********************************************************
=head2 msgs_ticket_reply

=cut
#**********************************************************
sub msgs_ticket_reply {
  my ($message_id) = @_;

  my $uid = $Msgs->{UID} || 0;
  my @REPLIES = ();

  if ($Msgs->{SURVEY_ID}) {
    my $main_message_survey = msgs_survey_show({
      SURVEY_ID => $Msgs->{SURVEY_ID},
      MSG_ID    => $Msgs->{ID},
      MAIN_MSG  => 1,
    });

    if ($main_message_survey) {
      push @REPLIES, $main_message_survey;
    }
  }

  my $list = $Msgs->messages_reply_list({ MSG_ID => $Msgs->{ID}, COLS_NAME => 1 });
  my $total_reply = $Msgs->{TOTAL};

  if (!$Msgs->{TOTAL} || $Msgs->{TOTAL} < 1) {
    $Msgs->{REPLY_QUOTE} = '> ' . ($Msgs->{MESSAGE} || q{});
    $Msgs->{TIMELINE_LAST_ITEM} = '';
  }

  foreach my $line (@{$list}) {
    if ($line->{survey_id}) {
      $FORM{REPLY_ID} = $line->{id};
      push @REPLIES, msgs_survey_show({
        SURVEY_ID => $line->{survey_id},
        REPLY_ID  => $line->{id},
        MSG_ID    => $Msgs->{ID},
        TEXT      => $line->{text},
      });

      delete($Msgs->{SURVEY_ID});
      next;
    }

    $Msgs->{REPLY_QUOTE} = '>' . $line->{text}  if ($FORM{QUOTING} && $FORM{QUOTING} == $line->{id});

    my $reply_color = 'fas fa-user bg-green';
    if ($line->{inner_msg}) {
      $reply_color = 'fas fa-lock bg-yellow';
    }
    elsif ($line->{aid} > 0) {
      $reply_color = 'fas fa-envelope bg-blue';
    }

    my $del_reply_button = $msgs_permissions{1}{11} ? $html->button($lang{DEL}, "&index=$index&chg=$message_id&reply_del=$line->{id}&UID=$uid", {
      MESSAGE => "$lang{DEL}  $line->{id}?",
      BUTTON  => 1,
      class   => 'btn btn-default btn-xs'
    }) : '';

    my $quote_button = $msgs_permissions{1}{12} ? $html->button($lang{QUOTING}, '', {
      class     => 'btn btn-default btn-xs quoting-reply-btn',
      ex_params => "quoting_id='$line->{id}'"
    }) : '';

    my $run_time = ($line->{run_time} && $line->{run_time} ne '00:00:00') ? "$lang{RUN_TIME}: $line->{run_time}" : '';

    my $attachment_html = '';
    if ($line->{attachment_id}) {
      my $attachments_list = $Msgs->attachments_list({
        REPLY_ID     => $line->{id},
        FILENAME     => '_SHOW',
        CONTENT_SIZE => '_SHOW',
        CONTENT_TYPE => '_SHOW',
        COORDX       => '_SHOW',
        COORDY       => '_SHOW',
      });

      $attachment_html = msgs_get_attachments_view($attachments_list);
    }

    push @REPLIES, $html->tpl_show(_include('msgs_reply_show', 'Msgs'), {
      ADMIN_MSG  => $line->{aid},
      LAST_MSG   => ($total_reply == $#REPLIES + 2) ? 'last_msg' : '',
      REPLY_ID   => $line->{id},
      DATE       => $line->{datetime},
      PERSON     => ($line->{creator_id} || q{}) . ' ' . ($line->{aid} ? " ($lang{ADMIN})" : ''),
      MESSAGE    => msgs_text_quoting($line->{text}, 1),
      QUOTING    => $quote_button,
      NEW_TOPIC  => _msgs_new_topic_button($uid, $message_id, $line->{id}, $Msgs->{CHAPTER}),
      EDIT       => _msgs_edit_reply_button($line->{id}),
      DELETE     => $del_reply_button,
      ATTACHMENT => $attachment_html,
      COLOR      => $reply_color,
      RUN_TIME   => $run_time,
    }, { OUTPUT2RETURN => 1, ID => $line->{id} });
  }

  if ($Msgs->{REPLY_QUOTE}) {
    if ($FORM{json}) {
      $Msgs->{REPLY_QUOTE} = '';
    }
    else {
      $Msgs->{REPLY_QUOTE} =~ s/\n/> /g;
    }
  }

  return \@REPLIES;
}


#**********************************************************
=head2 _msgs_change_responsible($message_id, $new_responsible_aid, $attr)

  Arguments:
    $message_id
    $new_responsible_aid
    $attr

=cut
#**********************************************************
sub _msgs_change_responsible {
  my ($message_id, $new_responsible_aid, $attr) = @_;

  # Check for test
  return 0 unless ($message_id);

  my $message_info = $attr->{MESSAGE_INFO};

  # Check we have all information we need
  my $given_message_has_all_required_info = (
    ($message_info && ref $message_info eq 'HASH')
      && (defined $message_info->{subject})
      && (defined $message_info->{resposible})
      && (defined $message_info->{message})
  );

  # If there is not enough, get it ourselves
  if (!$given_message_has_all_required_info) {
    my $message_info_list = $Msgs->messages_list({
      MSG_ID     => $message_id,
      RESPOSIBLE => '_SHOW',
      MESSAGE    => '_SHOW',
      SUBJECT    => '_SHOW',
      UID        => '_SHOW',
      COLS_NAME  => 1
    });
    return 0 if ($Msgs->{errno} || !$Msgs->{TOTAL});
    $message_info = $message_info_list->[0];
  }

  my $previous_responsible_aid = $message_info->{resposible} || 0;

  # Check if it's really changed
  return 1 if ($previous_responsible_aid eq $new_responsible_aid);

  # Change resposible in DB
  if (!$attr->{SKIP_CHANGE}) {
    $Msgs->message_change({
      ID         => $message_id,
      RESPOSIBLE => $new_responsible_aid
    });
    return 0 if ($Msgs->{errno});
  }

  # Check if now we have resposible and if this is not admin who changes
  return 1 if (!$new_responsible_aid || ($admin->{AID} eq $new_responsible_aid));

  my $attachments_list = $message_id ? $Msgs->attachments_list({
    MESSAGE_ID   => $message_id,
    FILENAME     => '_SHOW',
    CONTENT      => '_SHOW',
    CONTENT_TYPE => '_SHOW',
  }) : [];

  $Notify->notify_admins({
    SENDER_AID      => $admin->{AID},
    MSG_ID          => $message_id,
    AID             => $new_responsible_aid,
    ATTACHMENTS     => $attachments_list,
    NEW_RESPONSIBLE => 1
  });

  return 1;
}

#**********************************************************
=head1 msgs_survey_sel($attr)

=cut
#**********************************************************
sub msgs_survey_sel {

  return '' if !$msgs_permissions{1}{20};

  return $html->form_select('SURVEY_ID', {
    SELECTED       => $FORM{SURVEY_ID} || '',
    SEL_LIST       => $Msgs->survey_subjects_list({ PAGE_ROWS => 10000, COLS_NAME => 1 }),
    SEL_OPTIONS    => { '' => '' },
    MAIN_MENU      => get_function_index('msgs_survey'),
    MAIN_MENU_ARGV => $FORM{SURVEY_ID} ? "chg=$FORM{SURVEY_ID}" : ''
  });
}

#**********************************************************
=head2 msgs_progress_bar_show($Msgs)

=cut
#**********************************************************
sub msgs_progress_bar_show {
  my Msgs $Msgs_ = shift;

  my $pb_list = $Msgs_->pb_msg_list({
    MAIN_MSG   => $Msgs_->{ID},
    CHAPTER_ID => $Msgs_->{CHAPTER},
    COLS_NAME  => 1
  });

  _error_show($Msgs_);

  return '' if $Msgs_->{TOTAL} < 1;

  my $progress_name = '';
  my $cur_step = 0;
  my $tips = '';

  foreach my $line (@{$pb_list}) {
    my $step_map = $line->{step_date} || '';

    if ($line->{coorx1} && $line->{coorx1} + $line->{coordy} > 0) {
      $step_map = $html->button($line->{step_date},
        "index=" . get_function_index('maps_show_map') . "&COORDX=$line->{coordx}&COORDY=$line->{coordy}&TITLE=$line->{step_name}+$line->{step_date}");
    }

    $progress_name .= "['" . ($line->{step_name} || $line->{step_num}) . "', '$step_map' ], ";
    if ($line->{step_date}) {
      $cur_step = $line->{step_num};
      $tips = $line->{step_tip};
    }
  }

  return $html->tpl_show(_include('msgs_progressbar', 'Msgs'), {
    PROGRESS_NAMES => $progress_name,
    CUR_STEP       => $cur_step || 0,
    TIPS           => $tips,
  }, { OUTPUT2RETURN => 1 });
}

#**********************************************************
=head2 _msgs_show_change_subject_template()

=cut
#**********************************************************
sub _msgs_show_change_subject_template {

  my $subject = $FORM{subject} || '';
  my $changes_index = get_function_index('msgs_admin');
  my $msg_id = $FORM{msg_id};

  $html->tpl_show(_include('msgs_change_subject', 'Msgs'), {
    SUBJECT => $subject,
    INDEX   => $changes_index,
    ID      => $msg_id,
  });

  return 1;
}

#**********************************************************
=head2 _msgs_edit_reply()

=cut
#**********************************************************
sub _msgs_edit_reply {

  return 1 unless ($msgs_permissions{1} && $msgs_permissions{1}{2} && $FORM{edit_reply});

  my $edit_reply = $FORM{edit_reply};
  if ($edit_reply =~ s/^[m]\d+//) {
    my (undef, $msg_id) = split('m', $FORM{edit_reply});

    $Msgs->message_change({
      ID      => $msg_id,
      MESSAGE => $FORM{replyText}
    });

    return 1;
  }

  $Msgs->message_reply_change({
    ID   => $FORM{edit_reply},
    TEXT => $FORM{replyText}
  });

  return 1;
}

#**********************************************************
=head2 _msgs_reply_admin()

=cut
#**********************************************************
sub _msgs_reply_admin {

  if ($FORM{RUN_TIME}) {
    my ($h, $min, $sec) = split(/:/, $FORM{RUN_TIME}, 3);
    $FORM{RUN_TIME} = ($h || 0) * 60 * 60 + ($min || 0) * 60 + ($sec || 0);
  }
  my $reply_id;

  if ($FORM{REPLY_SUBJECT} || $FORM{REPLY_TEXT} || $FORM{FILE_UPLOAD} || $FORM{SURVEY_ID}) {
    delete $FORM{REPLY_INNER_MSG} if !$msgs_permissions{1} || !$msgs_permissions{1}{7};

    $Msgs->message_reply_add({ %FORM, AID => $admin->{AID}, IP => $admin->{SESSION_IP} });
    $reply_id = $Msgs->{INSERT_ID};
    $FORM{REPLY_ID} = $reply_id;

    if (!_error_show($Msgs)) {
      # Fixing empty attachment filename
      if ($FORM{FILE_UPLOAD} && $FORM{FILE_UPLOAD}->{'Content-Type'} && !$FORM{FILE_UPLOAD}->{filename}) {
        my $extension = 'dat';
        for my $ext ('jpg', 'jpeg', 'png', 'gif', 'txt', 'pdf') {
          if ($FORM{FILE_UPLOAD}->{'Content-Type'} =~ /$ext/i) {
            $extension = $ext;
            last;
          }
        }
        $FORM{FILE_UPLOAD}->{filename} = 'reply_img_' . $Msgs->{INSERT_ID} . q{.} . $extension
      }

      #Add attachment
      if ($FORM{FILE_UPLOAD}->{filename} && $FORM{ID}) {

        my $attachment_saved = msgs_receive_attachments($FORM{ID}, {
          REPLY_ID => $Msgs->{REPLY_ID},
          UID      => $FORM{UID},
          MSG_INFO => { %$Msgs }
        });

        if (!$attachment_saved) {
          _error_show($Msgs);
          $html->message('err', $lang{ERROR}, "Can't save attachment");
        }
      }

    }
  }

  my %params = ();
  my $msg_state = $FORM{STATE} || 0;
  $params{CHAPTER} = $FORM{CHAPTER_ID} if ($FORM{CHAPTER_ID});
  $params{STATE} = ($msg_state == 0 && !$FORM{MAIN_INNER_MESSAGE} && !$FORM{REPLY_INNER_MSG}) ? 6 : $msg_state;

  $Msgs->status_info($msg_state);
  if ($Msgs->{TOTAL} > 0 && $Msgs->{TASK_CLOSED}) {
    $params{CLOSED_DATE} = "$DATE  $TIME";
    $params{STATE} = 0 if $Msgs->{TASK_CLOSED} && (!$msgs_permissions{1} || !$msgs_permissions{1}{3});
  }
  $params{DONE_DATE} = $DATE if ($msg_state > 1);

  $Msgs->message_change({
    UID        => $LIST_PARAMS{UID},
    ID         => $FORM{ID},
    USER_READ  => "0000-00-00 00:00:00",
    ADMIN_READ => "$DATE $TIME",
    %params
  });

  if ($FORM{STEP_NUM}) {

    my $chapter = $Msgs->pb_msg_list({
      MAIN_MSG           => $FORM{ID},
      CHAPTER_ID         => $FORM{CHAPTER},
      STEP_NUM           => $FORM{STEP_NUM},
      USER_NOTICE        => '_SHOW',
      RESPONSIBLE_NOTICE => '_SHOW',
      FOLLOWER_NOTICE    => '_SHOW',
      COLS_NAME          => 1,
    });

    if (!defined($Msgs->{TOTAL})) {
      $Msgs->msg_watch_info($FORM{ID});
      my $watch_aid = $Msgs->{AID};

      my %send_msgs = (
        SUBJECT => $chapter->[0]->{step_name},
        MESSAGE => $FORM{REPLY_TEXT} || "$lang{CHAPTER} $chapter->[0]->{step_name} $lang{DONE}",
      );

      foreach my $chapter_info (@{$chapter}) {
        if ($chapter_info->{user_notice} && $FORM{UID}) {
          $Sender->send_message({ UID => $FORM{UID}, SENDER_TYPE => 'Mail', %send_msgs });
        }
        elsif ($chapter_info->{responsible_notice} && $FORM{RESPOSIBLE}) {
          $Sender->send_message({ AID => $FORM{RESPOSIBLE}, %send_msgs });
        }
        elsif ($chapter_info->{follower_notice} && $watch_aid) {
          $Sender->send_message({ AID => $watch_aid, %send_msgs });
        }
      }
    }

    $Msgs->pb_msg_change(\%FORM);
  }

  return 0 if _error_show($Msgs);

  $FORM{chg} = $FORM{ID};
  my $msgs_status = msgs_sel_status({ HASH_RESULT => 1 });
  $Msgs->message_info($FORM{ID});

  my $attachments_list = $reply_id ? $Msgs->attachments_list({
    REPLY_ID     => $reply_id,
    FILENAME     => '_SHOW',
    CONTENT      => '_SHOW',
    CONTENT_TYPE => '_SHOW',
    CONTENT_SIZE => '_SHOW'
  }) : [];

  $Notify->notify_user({
    UID         => $FORM{UID},
    STATE_ID    => $Msgs->{STATE},
    SEND_TYPE   => $Msgs->{SEND_TYPE},
    STATE       => $msgs_status->{$Msgs->{STATE}},
    REPLY_ID    => $reply_id,
    MSG_ID      => $FORM{ID},
    MSGS        => $Msgs,
    SENDER_AID  => $admin->{AID},
    ATTACHMENTS => $attachments_list
  });

  $Msgs->message_change({
    RESPOSIBLE => $admin->{AID},
    ID         => $FORM{ID},
  }) if !$FORM{RESPOSIBLE} || !$Msgs->{RESPOSIBLE};

  $Notify->notify_admins({
    SEND_TYPE   => $Msgs->{SEND_TYPE},
    STATE       => $msgs_status->{$Msgs->{STATE}},
    SENDER_AID  => $admin->{AID},
    MSG_ID      => $FORM{ID},
    MSGS        => $Msgs,
    ATTACHMENTS => $attachments_list
  });

  my $header_message = urlencode("$lang{MESSAGE} $lang{SENDED}" . ($FORM{ID} ? " : $FORM{ID}" : ''));
  $html->redirect("?index=$index" . "&UID=" . ($FORM{UID} || q{}) . "&chg=" . ($FORM{ID} || q{}) . "&MESSAGE=$header_message#last_msg", {
    MESSAGE_HTML => $html->message('info', $lang{INFO}, "$lang{REPLY}", { OUTPUT2RETURN => 1 }),
    WAIT         => '0'
  });

  return 1;
}

#**********************************************************
=head2 msgs_dispatch_admins($attr) - dispatch admins for adding dispatch

  Arguments:
    DISPATCH_ID - Dispatch id at msgs_dispatch_admins

  Returns:
    true or html code

=cut
#**********************************************************
sub msgs_dispatch_admins {
  my ($attr) = @_;
  my $admins_list = '';
  my $admins_list2 = '';

  if ($attr->{ADD} || $attr->{CHANGE}) {
    $Msgs->dispatch_admins_change($attr);
    return 1;
  }

  my $list = $Msgs->dispatch_admins_list({
    DISPATCH_ID => $attr->{DISPATCH_ID} || $FORM{chg},
    COLS_NAME   => 1
  });

  my %active_admins = ();
  foreach my $line (@$list) {
    $active_admins{ $line->{aid} } = 1;
  }

  $list = $admin->list({ %LIST_PARAMS,
    DEPARTMENT => $conf{MSGS_DISPATCH_ADMIN_DEPARTMENT} || '_SHOW',
    DISABLE    => 0,
    COLS_NAME  => 1,
    PAGE_ROWS  => 1000
  });

  my $checkbox = '';
  my $label = '';
  my $div_checkbox = '';

  my $count = 1;
  foreach my $line (@$list) {
    $checkbox = $html->form_input('AIDS', $line->{aid}, {
      class => 'list-checkbox',
      TYPE  => 'checkbox',
      STATE => ($active_admins{ $line->{aid} }) ? 1 : undef
    }) . " " . ($line->{name} || q{}) . ' : ' . ($line->{login} || q{});

    $label = $html->element('label', $checkbox);
    $div_checkbox = $html->element('li', $checkbox, { class => 'list-group-item' });
    if ($attr->{TWO_COLUMNS}) {
      $admins_list .= $div_checkbox if ($count % 2 != 0);
      $admins_list2 .= $div_checkbox if ($count % 2 == 0);
      $count++;
    }
    else {
      $admins_list .= $div_checkbox;
    }
  }

  return { AIDS => $admins_list, AIDS2 => $admins_list2 } if $attr->{TWO_COLUMNS};
  return $admins_list;
}

#**********************************************************
=head2 msgs_repeat_ticket($attr)

  Arguments:

  Returns:

=cut
#**********************************************************
sub msgs_repeat_ticket {

  my $answer = "";
  if ($FORM{LOCATION_ID} && !$FORM{UID}) {
    my $msgs_list = $Msgs->messages_list({
      DATE                   => $DATE,
      LOCATION_ID_MSG        => $FORM{LOCATION_ID},
      ADDRESS_BY_LOCATION_ID => '_SHOW',
      COLS_NAME              => 1,
    });

    $answer = $Msgs->{TOTAL} > 0 ? ":$lang{REPEAT_MSG_LOCATION_1} '$msgs_list->[0]{address_by_location_id}'" .
      "$lang{REPEAT_MSG_LOCATION_2} $lang{ADD_ANOTHER_ONE}" : "";
  }

  if ($FORM{UID}) {
    $Msgs->messages_list({
      DATE      => $DATE,
      UID       => $FORM{UID},
      COLS_NAME => 1,
    });

    $answer = $Msgs->{TOTAL} ? ":$lang{REPEAT_MSG_USER}</br>$lang{ADD_ANOTHER_ONE}" : "";
  }

  $Msgs->{TOTAL} //= '';
  print $Msgs->{TOTAL} . $answer;
  return $Msgs->{TOTAL} . $answer;
}

#**********************************************************
=head2 _msgs_call_action_plugin($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub _msgs_call_action_plugin {
  my $action = shift;
  my ($attr, $extra_params) = @_;

  my $users_list = $attr->{USERS_LIST} || ();
  my $plugins_before_create_message = _msgs_get_plugins({ ACTION => $action });

  foreach my $plugin (@{$plugins_before_create_message}) {
    next if !$plugin->{PLUGIN}->can('new') || !$plugin->{$action} || ref $plugin->{$action} ne 'ARRAY';

    my $plugin_api = $plugin->{PLUGIN}->new($db, $admin, \%conf, { HTML => $html, LANG => \%lang, MSGS => $Msgs });

    foreach my $function (@{$plugin->{$action}}) {
      next if !$plugin_api->can($function);

      my $result = $plugin_api->$function({ %FORM, USERS_OBJECT => $users, USERS_LIST => $users_list, %{($extra_params) ? $extra_params : {}} });
      next if (!$result || ref $result ne 'HASH') ;

      _msgs_action_callback($result);

      %FORM = (%FORM, %{$result->{RETURN_VARIABLES}}) if $result->{RETURN_VARIABLES} && ref $result->{RETURN_VARIABLES} eq 'HASH';

      return $result->{RETURN_VALUE} if (defined $result->{RETURN_VALUE});
    }
  }

  return;
}

#**********************************************************
=head2 _msgs_action_callback($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub _msgs_action_callback {
  my ($attr) = @_;

  return if !$attr->{CALLBACK} || ref $attr->{CALLBACK} ne 'HASH';
  my $callback = $attr->{CALLBACK};

  return if !$callback->{FUNCTION} || !$callback->{PARAMS} || ref $callback->{PARAMS} ne 'HASH';
  return if !defined(&{$callback->{FUNCTION}});

  my $function_ref = \&{$callback->{FUNCTION}};
  my $result = &{$function_ref}($callback->{PARAMS});
  print $result if $callback->{PRINT_RESULT};

  return 0;
}

#**********************************************************
=head2 _msgs_new_topic_button($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub _msgs_new_topic_button {
  my ($uid, $message_id, $make_new, $chapter) = @_;

  return '' if (!$msgs_permissions{1} || !$msgs_permissions{1}{25} || !$uid || !$message_id || !$make_new || !$chapter);

  return $html->button($lang{CREATE_NEW_TOPIC}, "&index=$index&chg=$message_id&UID=$uid&make_new=$make_new&chapter=$chapter", {
    MESSAGE => "$lang{NEW_TOPIC}?",
    BUTTON  => 1
  });
}

#**********************************************************
=head2 _msgs_edit_reply_button($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub _msgs_edit_reply_button {
  my ($reply_id) = @_;

  return '' if !$msgs_permissions{1}{10};

  return $html->button($lang{EDIT}, '', {
    class => 'btn btn-default btn-xs reply-edit-btn',
    ex_params => "reply_id='$reply_id'"
  });
}

#**********************************************************
=head2 _msgs_check_admin_privileges($privileges, $attr)

  Arguments:
    $privileges
    $attr
      CHAPTER
      ID
      HIDE_ALERT - don't show err message
      PRIVILEGE_LVL - check privilege level

  Return:
    1 or 0

=cut
#**********************************************************
sub _msgs_check_admin_privileges {
  my ($privileges) = shift;
  my ($attr) = @_;

  my $chapter = $attr->{CHAPTER};
  if (!$chapter && $attr->{ID}) {
    $Msgs->message_info($attr->{ID});
    $chapter = $Msgs->{CHAPTER};
  }

  return 1 if !$chapter;

  return 1 if scalar keys %{$privileges} == 0;
  return ($privileges->{$chapter} >= $attr->{PRIVILEGE_LVL} ? 1 : 0) if $attr->{PRIVILEGE_LVL};
  return 1 if $privileges->{$chapter};

  $html->message('err', $lang{ERROR}, $lang{ERR_ACCESS_DENY}, { ID => 791 }) if !$attr->{HIDE_ALERT};
  return 0 ;
}

1