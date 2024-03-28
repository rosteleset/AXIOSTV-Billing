=head NAME

 User Portal

=cut

use strict;
use warnings FATAL => 'all';
use Time::Piece;
use AXbills::Base qw(urlencode convert int2byte vars2lang);
use Msgs::Misc::Attachments;

our(
  $db,
  %conf,
  %lang,
  $admin,
  $SELF_URL
);

our AXbills::HTML $html;
# Todo: generalize ( Now there are separate arrays in almost each Msgs .pm file)
my @priority_colors = ('#8A8A8A', $_COLORS[8], $_COLORS[9], '#E06161', $_COLORS[6]);
my @priority = ($lang{VERY_LOW}, $lang{LOW}, $lang{NORMAL}, $lang{HIGH}, $lang{VERY_HIGH});

my $Msgs = Msgs->new($db, $admin, \%conf);
my $Notify = Msgs::Notify->new($db, $admin, \%conf, {LANG => \%lang, HTML => $html});

#**********************************************************
=head2 msgs_user_show($attr) - Show message for client

  Arguments:
    $attr
      MSGS_STATUS
      ID
      LAST_ID

=cut
#**********************************************************
sub msgs_user_show {
  my ($attr) = @_;

  my $msgs_id = $attr->{ID} || $attr->{LAST_ID} ;
  $Msgs->message_info($msgs_id, { UID => $LIST_PARAMS{UID} });
  return 1 if (_error_show($Msgs));

  my $msgs_status = $attr->{MSGS_STATUS};

  if ($FORM{reply}) {
    my %params = ();
    $params{CLOSED_DATE} = $DATE if ($FORM{STATE} && $FORM{STATE} > 0);
    $params{DONE_DATE}   = $DATE if ($FORM{STATE} && $FORM{STATE} > 1);
    $params{ADMIN_READ}  = "0000-00-00  00:00:00" if (! $FORM{INNER});

    $Msgs->message_change({
      UID            => $LIST_PARAMS{UID},
      ID             => $msgs_id,
      STATE          => $FORM{STATE},
      RATING         => $FORM{RATING}         ? $FORM{RATING}         : 0,
      RATING_COMMENT => $FORM{RATING_COMMENT} ? $FORM{RATING_COMMENT} : '',
      %params
    });

    if ($FORM{REPLY_SUBJECT} || $FORM{REPLY_TEXT} || $FORM{FILE_UPLOAD} || $FORM{SURVEY_ID}) {
      $Msgs->message_reply_add({
        AID        => 0,
        IP         => $admin->{SESSION_IP},
        UID        => $LIST_PARAMS{UID},
        REPLY_TEXT => $FORM{REPLY_TEXT},
        ID         => $FORM{ID}
      });

      if (!$Msgs->{errno}) {
        #Save signature
        msgs_receive_signature($LIST_PARAMS{UID}, $FORM{ID}, $FORM{signature}) if ($FORM{signature} && $FORM{ID});

        #Add attachment
        if ( $FORM{FILE_UPLOAD}->{filename} && $Msgs->{REPLY_ID} ) {
          my $attachment_saved = msgs_receive_attachments($msgs_id, {
            REPLY_ID => $Msgs->{REPLY_ID},
            MSG_INFO => { UID => $LIST_PARAMS{UID} }
          });

          if (!$attachment_saved) {
            _error_show($Msgs);
            $html->message('err', $lang{ERROR}, "Can't save attachment");
          }
        }
      }
      $html->message( 'info', $lang{INFO}, $lang{REPLY});

      my $attachments_list = $Msgs->attachments_list({
        REPLY_ID     => $Msgs->{INSERT_ID},
        FILENAME     => '_SHOW',
        CONTENT      => '_SHOW',
        CONTENT_TYPE => '_SHOW',
      });

      $Notify->notify_admins({
        MSG_ID        => $msgs_id,
        SENDER_UID    => $LIST_PARAMS{UID},
        MESSAGE_STATE => $FORM{STATE},
        ATTACHMENTS   => $attachments_list
      });

      # Instant redirect
      my $header_message = urlencode("$lang{MESSAGE} $lang{SENDED}" . ($Msgs->{INSERT_ID} ? " : $Msgs->{INSERT_ID}" : ''));
      $html->redirect("?index=$index&sid=".( $sid || $user->{SID} || $user->{sid} )
        ."&MESSAGE=$header_message&ID=" . ($Msgs->{MSG_ID} || $FORM{ID} || q{}) . '#last_msg');
      exit 0;
    }
    return 1;
  }
  elsif ($FORM{change}) {
    $Msgs->message_change({
      UID        => $LIST_PARAMS{UID},
      ID         => $msgs_id,
      ADMIN_READ => "0000-00-00 00:00:00",
      STATE      => $FORM{STATE} || 0
    });

    msgs_survey_show({ SURVEY_ANSWER => $FORM{SURVEY_ANSWER} }) if $FORM{SURVEY_ANSWER};
  }

  $FORM{ID} = $Msgs->{LAST_ID} if $Msgs->{LAST_ID};

  $Msgs->{ACTION} = 'reply';
  $Msgs->{LNG_ACTION} = $lang{SEND};
  $Msgs->{STATE_NAME} = $html->color_mark($msgs_status->{$Msgs->{STATE}}) if (defined($Msgs->{STATE}) && $msgs_status->{$Msgs->{STATE}});
  $Msgs->{PRIORITY_TEXT} = $html->color_mark($priority[ $Msgs->{PRIORITY} ], $priority_colors[ $Msgs->{PRIORITY} ]);

  if ($Msgs->{PRIORITY} == 4) {
    $Msgs->{MAIN_PANEL_COLOR} = 'card-danger';
  }
  elsif ($Msgs->{PRIORITY} == 3) {
    $Msgs->{MAIN_PANEL_COLOR} = 'card-warning';
  }
  elsif ($Msgs->{PRIORITY} >= 1) {
    $Msgs->{MAIN_PANEL_COLOR} = 'card-info';
  }
  else {
    $Msgs->{MAIN_PANEL_COLOR} = 'card-primary';
  }

  my @REPLIES = ();
  return if !$Msgs->{ID};

  my $main_msgs_id = $Msgs->{ID};

  my $replies_list = $Msgs->messages_reply_list({
    MSG_ID       => $main_msgs_id,
    CONTENT_SIZE => '_SHOW',
    INNER_MSG    => 0,
    CONTENT_TYPE => '_SHOW',
    COLS_NAME    => 1
  });

  my $total_reply = $Msgs->{TOTAL};
  my $reply = '';

  if ($Msgs->{SURVEY_ID}) {
    my $main_message_survey = msgs_survey_show({
      SURVEY_ID        => $Msgs->{SURVEY_ID},
      MSG_ID           => $Msgs->{ID},
      MAIN_MSG         => 1,
      NOTIFICATION_MSG => ($Msgs->{STATE} && $Msgs->{STATE} == 9) ? 1 : 0,
    });

    push @REPLIES, $main_message_survey if ($main_message_survey);
  }

  foreach my $line (@$replies_list) {
    $FORM{REPLY_ID} = $line->{id};

    if ($line->{survey_id}) {
      push @REPLIES, msgs_survey_show({
        SURVEY_ID => $line->{survey_id},
        REPLY_ID  => $line->{id},
        TEXT      => $line->{text}
      });
      next;
    }

    $reply = $line->{text} if ($FORM{QUOTING} && $FORM{QUOTING} == $line->{id} && !$FORM{json});

    # Should check multiple attachments if got at least one
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

      $attachment_html = msgs_get_attachments_view($attachments_list, { NO_COORDS => 1 });
    }

    my $quoting_button = $html->button($lang{QUOTING}, "", {
      class     => 'btn btn-default btn-xs quoting-reply-btn',
      ex_params => "quoting_id='$line->{id}'"
    });

    push @REPLIES, $html->tpl_show(_include('msgs_reply_show', 'Msgs'), {
      LAST_MSG   => ($total_reply == $#REPLIES + 2) ? 'last_msg' : '',
      REPLY_ID   => $line->{id},
      DATE       => $line->{datetime},
      CAPTION    => convert($line->{caption}, { text2html => 1, json => $FORM{json} }),
      PERSON     => ($line->{creator_fio} || $line->{creator_id}),
      MESSAGE    => msgs_text_quoting($line->{text}),
      COLOR      => (($line->{aid} > 0) ? 'fas fa-envelope bg-blue' : 'fas fa-user bg-green'),
      QUOTING    => $quoting_button,
      ATTACHMENT => $attachment_html,
    }, { OUTPUT2RETURN => 1, ID => 'REPLY_' . $line->{id} });

    if ($reply ne '') {
      $reply =~ s/^/>  /g;
      $reply =~ s/\n/> /g;
    }
  }

  $Msgs->{TIMELINE_LAST_ITEM} = $html->element('i', '', { 'class' => 'fas fa-check bg-green', OUTPUT2RETURN => 1 });
  if (!$Msgs->{ACTIVE_SURWEY} && ($Msgs->{STATE} < 1 || $Msgs->{STATE} == 6)) {
    $Msgs->{REPLY_BLOCK} = $html->tpl_show(_include('msgs_client_reply', 'Msgs'), { %$Msgs,
      REPLY_TEXT => $reply,
      MAX_FILES  => $conf{MSGS_MAX_FILES} || 3
    }, { OUTPUT2RETURN => 1, ID => 'REPLY' });
    $Msgs->{TIMELINE_LAST_ITEM} = $html->element('i', '', { 'class' => 'fas fa-clock bg-gray', OUTPUT2RETURN => 1 });
  }

  $Msgs->{MESSAGE} = convert($Msgs->{MESSAGE}, { text2html => 1, SHOW_URL => 1, json => $FORM{json} });
  $Msgs->{SUBJECT} = convert($Msgs->{SUBJECT}, { text2html => 1, json => $FORM{json} });

  if ($Msgs->{FILENAME}) {
    # Should check multiple attachments if got at least one
    my $attachments_list = $Msgs->attachments_list({
      MESSAGE_ID   => $Msgs->{ID},
      FILENAME     => '_SHOW',
      CONTENT_SIZE => '_SHOW',
      CONTENT_TYPE => '_SHOW',
      COORDX       => '_SHOW',
      COORDY       => '_SHOW',
    });

    $Msgs->{ATTACHMENT} = msgs_get_attachments_view($attachments_list, { NO_COORDS => 1 });
  }

  if ($Msgs->{STATE} == 9) {
    push @REPLIES, $html->button($lang{CLOSE}, "index=$index&STATE=10&ID=$FORM{ID}&change=1&sid=$sid",
      { class => 'btn btn-primary' });
  }

  $Msgs->{TIMELINE_LAST_ITEM} = '' if !scalar @REPLIES;
  $Msgs->{REPLY} = join(($FORM{json}) ? ',' : '', @REPLIES);

  while ($Msgs->{MESSAGE} && $Msgs->{MESSAGE} =~ /\[\[(\d+)\]\]/) {
    my $msg_button = $html->button($1, "&index=$index&ID=$1",
      { class => 'badge bg-blue' });
    $Msgs->{MESSAGE} =~ s/\[\[\d+\]\]/$msg_button/;
  }

  if (my $last_reply_index = scalar(@$replies_list)) {
    $Msgs->{UPDATED} = $replies_list->[$last_reply_index - 1]->{datetime};
  }
  else {
    $Msgs->{UPDATED} = '--';
  }

  $html->tpl_show(_include('msgs_client_show', 'Msgs'), { %{$Msgs}, ID => $main_msgs_id }, { ID => 'MSGS_CLIENT_INFO' });

  my %params = ();
  my $state = $FORM{STATE};
  $params{CLOSED_DATE} = $DATE if ($state && $state > 0);
  $params{DONE_DATE} = $DATE if ($state && $state > 1);

  $Msgs->message_change({ UID => $LIST_PARAMS{UID}, ID => $FORM{ID}, USER_READ => "$DATE $TIME", %params });

  msgs_redirect_filter({ DEL => 1, UID => $LIST_PARAMS{UID} });

  return 0;
}

#**********************************************************
=head2 msgs_user() - Client web interface

=cut
#**********************************************************
sub msgs_user {

  if ($FORM{edit_reply}) {
    _user_edit_reply();
    return 1;
  }

  #If User have new unread msg, open it
  #(Return msg object with LAST_ID)
  if($user->{UID} && !($FORM{ID} || $Msgs->{LAST_ID} || $Msgs->{INSERT_ID} || $Msgs->{ID}) ){

    my %SHOW_PARAMS = (
      UID        => $user->{UID},
      USER_READ  => '0000-00-00  00:00:00',
      ADMIN_READ => '>0000-00-00 00:00:00',
      INNER_MSG  => 0,
    );

    $Msgs->messages_new({ %SHOW_PARAMS });
  }

  my $msgs_status = msgs_sel_status({ HASH_RESULT => 1 });

  $Msgs->{STATE_SEL} = $html->form_select('STATE', {
    SELECTED   => $FORM{STATE} || 0,
    SEL_HASH   => !$FORM{ID} ? { 0 => $msgs_status->{0} } : {
      0 => $msgs_status->{0},
      1 => $msgs_status->{1},
      2 => $msgs_status->{2}
    },
    NO_ID      => 1,
    USE_COLORS => 1,
  });

  $Msgs->{PRIORITY_SEL} = msgs_sel_priority();

  if ($FORM{send}) {
    if ($conf{MSGS_USER_REPLY_SECONDS_LIMIT}){
      my $fresh_messages = $Msgs->messages_list({
        UID       => $user->{UID},
        STATE     => $FORM{STATE},
        GET_NEW   => $conf{MSGS_USER_REPLY_SECONDS_LIMIT},
        COLS_NAME => 1
      });

      if ($Msgs->{TOTAL} && $Msgs->{TOTAL} > 0) {
        my $message_sent = $fresh_messages->[0] || {};
        my $message_sent_id = $message_sent->{id} || 0;

        my $header_message = vars2lang($lang{MESSAGES_CAN_BE_SENT_UP_TO_ONCE}, {
          SECONDS => $conf{MSGS_USER_REPLY_SECONDS_LIMIT}
        });
        $header_message .= "\n$lang{LAST_MESSAGE_ID}: $message_sent_id\n";

        $html->redirect("?index=$index&sid=" . ($sid || $user->{SID} || $user->{sid}) . "&ID=$message_sent_id#last_msg", {
          WAIT    => 3,
          MESSAGE => $header_message
        });

        exit 0;
      }
    }

    my $chapter = $Msgs->chapter_info($FORM{CHAPTER});
    $FORM{RESPOSIBLE} = $chapter->{RESPONSIBLE} ? $chapter->{RESPONSIBLE} : 0;

    $Msgs->message_add({
      UID        => $user->{UID},
      STATE      => ($FORM{STATE}) ? $FORM{STATE} : 0,
      USER_READ  => "$DATE  $TIME",
      IP         => $ENV{'REMOTE_ADDR'},
      RESPOSIBLE => $chapter->{RESPONSIBLE} || 0,
      SUBJECT    => $FORM{SUBJECT} || '',
      CHAPTER    => $FORM{CHAPTER} || 0,
      MESSAGE    => $FORM{MESSAGE} || '',
      PRIORITY   => $FORM{PRIORITY} || 0,
      USER_SEND  => 1
    });
    return 1 if _error_show($Msgs);

    my $new_msg_id = $Msgs->{MSG_ID} || 0;
    if ($FORM{FILE_UPLOAD}->{filename} && $Msgs->{MSG_ID}) {
      my $attachment_saved = msgs_receive_attachments($Msgs->{MSG_ID}, { MSG_INFO => { UID => $user->{UID} } });

      if (!$attachment_saved) {
        _error_show($Msgs);
        $html->message('err', $lang{ERROR}, "Can't save attachment");
      }
    }

    $html->message('info', $lang{INFO}, "$lang{MESSAGE} # $Msgs->{MSG_ID}.  $lang{MSG_SENDED} ");

    $Notify->notify_admins({ MSG_ID => $new_msg_id });
    _notify_admins_by_chapter($FORM{CHAPTER}, $new_msg_id) if !$FORM{RESPOSIBLE} && $FORM{CHAPTER};
    _msgs_send_support_request_mail();

    my $message_added_text = "$lang{MESSAGE} " . ($Msgs->{MSG_ID} ? " #$Msgs->{MSG_ID} " : '') . $lang{MSG_SENDED};
    my $header_message = urlencode($message_added_text);
    my $message_link = "?index=$index&sid=" . ($sid || $user->{SID} || $user->{sid})
      . "&MESSAGE=$header_message&ID=" . ($Msgs->{MSG_ID} || q{}) . '#last_msg';

    $html->redirect($message_link, {
      MESSAGE_HTML => $html->message(
        'info',
        $lang{INFO},
        $html->button($message_added_text, $message_link, { class => 'alert-link' }), { OUTPUT2RETURN => 1 }
      ),
      WAIT         => '0'
    });
    exit 0;
  }
  elsif ($FORM{ATTACHMENT}) {
    return msgs_attachment_show(\%FORM);
  }
  elsif ($FORM{ID} || $Msgs->{LAST_ID}) {
    msgs_user_show({
      MSGS_STATUS => $msgs_status,
      ID          => $FORM{ID},
      LAST_ID     => $Msgs->{LAST_ID}
    });
  }
  elsif (!$FORM{SEARCH_MSG_TEXT}) {
    $Msgs->{CHAPTER_SEL} = $html->form_select('CHAPTER', {
      SELECTED       => $Msgs->{CHAPTER} || $conf{MSGS_USER_DEFAULT_CHAPTER} || undef,
      SEL_LIST       => $Msgs->chapters_list({ INNER_CHAPTER => 0, COLS_NAME => 1 }),
      MAIN_MENU      => get_function_index('msgs_chapters'),
      MAIN_MENU_ARGV => $Msgs->{CHAPTER} ? "chg=$Msgs->{CHAPTER}" : ''
    });

    $Msgs->{SUBJECT_SEL} = msgs_sel_subject({ EX_PARAMS => 'disabled=disabled required' });

    $html->tpl_show(_include('msgs_send_form_user', 'Msgs'),{ %$Msgs, MAX_FILES => $conf{MSGS_MAX_FILES} || 3 });
  }

  $html->message('info', '', $FORM{MESSAGE}) if ($FORM{MESSAGE});
  _error_show($Msgs, { ID => 799 });

  my %statusbar_status = (
    0 => $msgs_status->{0},
    1 => $msgs_status->{1},
    2 => $msgs_status->{2},
    3 => $msgs_status->{3},
    4 => $msgs_status->{4},
    5 => $msgs_status->{5},
    6 => $msgs_status->{6}
  );

  $pages_qs .= "&SEARCH_MSG_TEXT=$FORM{SEARCH_MSG_TEXT}" if( $FORM{SEARCH_MSG_TEXT});

  my $status_bar = msgs_status_bar({ MSGS_STATUS => \%statusbar_status, USER_UNREAD => 1 });
  if (! $FORM{sort}){
    $LIST_PARAMS{SORT} = '4, 1';
    delete $LIST_PARAMS{DESC};
    if(! defined($FORM{STATE}) && !$FORM{ALL_MSGS}) {
      $LIST_PARAMS{STATE} = '!1,!2';
    }
  }

  $LIST_PARAMS{INNER_MSG} = 0;
  delete($LIST_PARAMS{STATE}) if ($FORM{STATE} && $FORM{STATE} =~ /\d+/ && $FORM{STATE} == 3);
  delete($LIST_PARAMS{PRIORITY}) if ($FORM{PRIORITY} && $FORM{PRIORITY} == 5);

  $FORM{ALL_OPENED} = 1 if !defined($FORM{STATE}) && !$FORM{ALL_MSGS};

  $html->tpl_show(_include('msgs_user_search_form', 'Msgs'), {%$Msgs}, { ID => 'MSGS_USER_SEARCH_FORM' });

  my $table;

  if ($FORM{SEARCH_MSG_TEXT}) {
    my $request_search_word = $FORM{SEARCH_MSG_TEXT};
    $request_search_word =~ s/\\/\\\\/gi;
    $request_search_word =~ s/\%/\\%/gi;
    $request_search_word =~ s/\'/\\'/gi;

    my $list = $Msgs->messages_list({
      SUBJECT             => '_SHOW',
      CHAPTER_NAME        => '_SHOW',
      DATETIME            => '_SHOW',
      STATE               => '_SHOW',
      USER_READ           => '_SHOW',
      REPLY_TEXT          => '_SHOW',
      MESSAGE             => '_SHOW',
      SEARCH_MSGS_BY_WORD => $request_search_word,
      %LIST_PARAMS,
      COLS_NAME           => 1
    });

    $table = msgs_user_search_table({
      ID          => $FORM{ID},
      SID         => $sid,
      TOTAL_MSGS  => $Msgs->{TOTAL},
      JSON        => $FORM{json},
      STATUS_BAR  => $status_bar,
      SEARCH_TEXT => $FORM{SEARCH_MSG_TEXT},
    }, $msgs_status, $list);
  }
  else {
    my $list = $Msgs->messages_list({
      SUBJECT          => '_SHOW',
      LAST_REPLIE_DATE => '_SHOW',
      DATETIME         => '_SHOW',
      STATE            => '_SHOW',
      RESPOSIBLE       => '_SHOW',
      USER_READ        => '_SHOW',
      %LIST_PARAMS,
      COLS_NAME        => 1
    });

    $table = $html->table({
      width   => '100%',
      caption => $lang{MESSAGES},
      title   => [ '#', $lang{SUBJECT}, , $lang{ADDED}, $lang{STATUS}, $lang{LAST_ACTIVITY}, '-' ],
      qs      => $pages_qs,
      pages   => $Msgs->{TOTAL},
      ID      => 'MSGS_LIST',
      header  => $status_bar,
      FIELDS_IDS => $Msgs->{COL_NAMES_ARR},
    });

    foreach my $line (@$list) {
      $table->{rowcolor} = ($FORM{ID} && $line->{id} == $FORM{ID}) ? 'row_active' : undef;
      $line->{subject} = convert($line->{subject}, { text2html => 1, json => $FORM{json} });

      $table->addrow(
        $line->{id},
        ($line->{user_read} ne '0000-00-00 00:00:00')
        ? $html->button((($line->{subject}) ? "$line->{subject}" : $lang{NO_SUBJECT}), "index=$index&ID=$line->{id}&sid=$sid#last_msg")
        : $html->button($html->b((($line->{subject}) ? "$line->{subject}" : $lang{NO_SUBJECT})), "index=$index&ID=$line->{id}&sid=$sid#last_msg"),
        $line->{datetime},
        $html->color_mark($msgs_status->{ $line->{state} }) . (($line->{resposible} && !$line->{state}) ? " ($lang{TAKEN_TO_WORK})" : ""),
        $line->{last_replie_date},
        $html->button($lang{SHOW}, "index=$index&ID=$line->{id}&sid=$sid", { class => 'show' })
      );
    }
  }

  print $table->show();

  $Msgs->{TOTAL_MSG} = $Msgs->{TOTAL};

  $table = $html->table({
    width         => '100%',
    rows          => [
      [
        "$lang{TOTAL}:  " . $html->b($Msgs->{TOTAL_MSG}),
        "$lang{OPEN}: " . $html->b($Msgs->{OPEN}),
      ]
    ],
    ID            => 'MSGS_LIST_TOTAL',
    OUTPUT2RETURN => 1
  });
  print $table->show();

  delete $LIST_PARAMS{SORT};
  if($conf{MSGS_CHAT}) {
    require Msgs::Chat;
    show_user_chat();
  }

  return 1;
}

#**********************************************************
=head2 msgs_user_search_table() - Create table with find msgs

  Arguments:
    $attr -
      SEARCH_TEXT - Search word
      TOTAL_MSGS -  Total msgs
      STATUS_BAR -  Table status bar
    msgs_status  = hash reff with messages status
    list         = list of messages

  Returns:  HTML Table

  Examples:
=cut
#**********************************************************
sub msgs_user_search_table {
my ($attr, $msgs_status, $list) = @_;

  my $function_index = get_function_index('msgs_user') || $attr->{INDEX};

  my $table = $html->table({
    width       => '100%',
    caption     => $lang{MESSAGES},
    title_plain => [ '#', $lang{SUBJECT}, $lang{MESSAGE}, $lang{DATE}, $lang{STATUS}, '-' ],
    qs          => $pages_qs . "SEARCH_MSG_TEXT=$FORM{SEARCH_MSG_TEXT}",
    pages       => $attr->{TOTAL_MSGS},
    ID          => 'MSGS_LIST_SEARCH',
    header      => $attr->{STATUS_BAR}
  });

  foreach my $line (@$list) {
    $table->{rowcolor} = ($attr->{ID} && $line->{id} == $attr->{ID}) ? 'row_active' : undef;

    #Add color to search word In Subject, messegas, reply
    my $subject_color = _add_color_search($attr->{SEARCH_TEXT}, $line->{subject});
    my ($text_color, $have_word_in_text) = _add_color_search($attr->{SEARCH_TEXT}, $line->{message}, { SLICE => 1 });
    my ($reply_color, $have_word_in_reply) = _add_color_search($attr->{SEARCH_TEXT}, $line->{reply_text}, { SLICE => 1 });

    #Watch if we have word in text if not add standart text
    my $resul_text = $have_word_in_text ? $text_color : $have_word_in_reply ? $reply_color : $text_color;

    $table->addrow(
      $line->{id},
      ($line->{user_read} ne '0000-00-00 00:00:00')
        ? $html->button((($subject_color) ? " $subject_color" : $lang{NO_SUBJECT}), "index=$function_index&ID=$line->{id}&sid=$sid#last_msg")
        : $html->button($html->b((($subject_color) ? " $subject_color" : $lang{NO_SUBJECT})), "index=$function_index&ID=$line->{id}&sid=$sid#last_msg"),
      $resul_text,
      $line->{datetime},
      $html->color_mark($msgs_status->{ $line->{state} }),
      $html->button($lang{SHOW}, "index=$function_index&ID=$line->{id}&sid=$sid", { class => 'show' })
    );
  }

  return $table;
}

#**********************************************************
=head2 _msgs_send_support_request_mail()

  Arguments:
    $email

  Returns: sending status

=cut
#**********************************************************
sub _msgs_send_support_request_mail {
  my $email = shift;
  $email ||= $user->{EMAIL};

  return if !$email;

  require AXbills::Sender::Core;
  AXbills::Sender::Core->import();
  my $Sender = AXbills::Sender::Core->new($db, $admin, \%conf);

  my $img_url = $SELF_URL;
  $img_url =~ s/index\.cgi//;

  my $message_link = "$SELF_URL?index=$index&ID=" . ($Msgs->{MSG_ID} || q{});

  my $message = $html->tpl_show(_include('msgs_support_request', 'Msgs'), { %FORM, %{$Msgs},
    IMG_URL => $img_url,
    MSG_URL => $message_link,
    MSG_ID  => $Msgs->{MSG_ID}
  }, { OUTPUT2RETURN => 1 });

  return $Sender->send_message({
    TO_ADDRESS   => $email,
    MESSAGE      => $message,
    SUBJECT      => $lang{MSGS_SUPPORT_REQUEST_HEADER},
    SENDER_TYPE  => 'Mail',
    QUITE        => 1,
    CONTENT_TYPE => 'text/html'
  });
}

#**********************************************************
=head2 _add_color_search() - Add color to search word in text

  Arguments:
    $attr -
      SLICE - Slice text 80  or 95 if no search word
  Returns: format_text(String), Find word(Bool: 1 or 0)

  Examples:
=cut
#**********************************************************
sub _add_color_search {
  my ($word, $full_text, $attr) = @_;

  return '' if !$word || !$full_text;

  #Turn off special characters for regexp
  my $quote_word = quotemeta($word);

  #my $word_with_color;
  #If we didnt want full text. Slice
  if ($attr->{SLICE}) {

    #Slice and search word
    my ($result_text) = $full_text =~ m/.{0,40}$quote_word.{0,40}/gi;

    #If see search word add color else onle slice
    if ($result_text) {

      #Add color
      $result_text =~ s/($quote_word)/<span style='background:yellow'>$1<\/span>/gi;

      return $result_text, 1;
    }
    else {
      ($result_text) = $full_text =~ m/.{0,95}/g;
      return $result_text, 0;
    }
  }

  #If see search word add color
  $full_text =~ s/($quote_word)/<span style='background:yellow'>$1<\/span>/gi;

  return $full_text;
}

#**********************************************************
=head2 _user_edit_reply() 

=cut
#**********************************************************
sub _user_edit_reply {

  return 1 unless ( $FORM{edit_reply} );

  my $list = $Msgs->messages_reply_list({
    ID         => $FORM{edit_reply},
    DATETIME   => '_SHOW',
    CREATOR_ID => '_SHOW',
    COLS_NAME  => 1
  });

  return 1 unless ($list->[0]->{creator_id} eq $user->{LOGIN});

  my $n = gmtime() + 3600 * 3;
  my $d = Time::Piece->strptime($list->[0]->{datetime}, "%Y-%m-%d %H:%M:%S");
  if (($n - $d) / 60 < 5) {
    $Msgs->message_reply_change({
      ID   => $FORM{edit_reply},
      TEXT => $FORM{replyText}
    });
  };
  return 1;
}

#**********************************************************
=head2 _notify_admins_by_chapter()

=cut
#**********************************************************
sub _notify_admins_by_chapter {
  my ($chapter_id, $msg_id) = @_;

  return '' if !$chapter_id || !$msg_id;

  my $admins_permissions = $Msgs->permissions_list();

  foreach my $aid (keys %{$admins_permissions}) {
    my $admin_permission = $admins_permissions->{$aid};

    next if $admin_permission->{1}{24};
    next if !$admin_permission->{5} || !$admin_permission->{6}{$chapter_id};
    next if $admin_permission->{4} && !$admin_permission->{4}{$chapter_id};

    $Notify->notify_admins({ MSG_ID => $msg_id, SEND_TO_AID => $aid, AID => $aid });
  }

  return;
}

1;