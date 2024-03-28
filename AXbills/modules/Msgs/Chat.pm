=head2 NAME

  Chat

=cut

use strict;
use warnings FATAL => 'all';

our(
  $db,
  %conf,
  %lang,
  $admin,
  $user,
  $html,
  %permissions,
  @WEEKDAYS,
  @MONTHES,
);

require Chatdb;
Chatdb->import();
my $Chatdb = Chatdb->new($db, $admin, \%conf);

#**********************************************************
=head2 header_online_chat() Shows chats at the header main page

  Arguments:

  Returns:
    true
=cut
#**********************************************************
sub header_online_chat {
  my ($attr) = @_;
  my $list = '';
  if ($FORM{AID}) {
    my $count_messages = $Chatdb->chat_count({ AID => $FORM{AID} });
    print $count_messages;
  }
  if ($attr->{UID}) {
    my $count_user_messages = $Chatdb->chat_count({ UID => $attr->{UID} || '' });
    print $count_user_messages;
  }
  if ($attr->{US_MS_LIST}) {
    my $messages = $Chatdb->chat_message_info({ UID => $attr->{US_MS_LIST} });
    foreach my $item (@$messages) {
      $list .= $html->tpl_show(_include('msgs_chat_header', 'Msgs'), {
        SUBJECT => $item->{subject},
        LINK    => 'index.cgi?get_index=msgs_user&ID=' . $item->{id} . '&sid=' . $user->{SID}
      }, { OUTPUT2RETURN => 1 });
    }
    print $list;
  }
  if ($FORM{SH_MS_LIST}) {
    my $messages = $Chatdb->chat_message_info({ AID => $FORM{SH_MS_LIST} });
    foreach my $item (@$messages) {
      $list .= $html->tpl_show(_include('msgs_chat_header', 'Msgs'), {
        SUBJECT => $item->{subject},
        LINK    => 'index.cgi?get_index=msgs_admin&full=1&UID=' . $item->{uid} . '&chg=' . $item->{num_ticket}
      }, { OUTPUT2RETURN => 1 });
    }
    print $list;
  }
  return 1;
}

#**********************************************************
=head2 show_admin_chat() Shows chat at the admin side

  Arguments:

  Returns:
    ''
=cut
#**********************************************************
sub show_admin_chat {
  if ($FORM{ADD}) {
    msgs_chat_add();
    return 1;
  }
  if ($FORM{SHOW}) {
    msgs_chat_show();

    return 1;
  }
  if ($FORM{COUNT} && $FORM{MSG_ID}) {
    my $count = $Chatdb->chat_count({ MSG_ID => $FORM{MSG_ID}, SENDER => 'aid' });
    print $count;
    return 1;
  }
  if ($FORM{CHANGE} && $FORM{MSG_ID}) {
    $Chatdb->chat_change({ MSG_ID => $FORM{MSG_ID}, SENDER => 'aid'});
    return 1;
  }
  if ($conf{MSGS_CHAT} && $FORM{chg}) {
    my $fn_index = get_function_index('show_admin_chat');
    $html->tpl_show(_include('msgs_admin_chat', 'Msgs'), {
      F_INDEX    => $fn_index,
      AID        => $admin->{AID},
      NUM_TICKET => $FORM{chg}
    });
  }
  return '';
}

#**********************************************************
=head2 show_user_chat() - Shows chat at the user side

  Arguments:

  Returns:
    true
=cut
#**********************************************************
sub show_user_chat {
#  require Msgs::Tickets;
  if ($FORM{ADD}) {
    msgs_chat_add();
    return 1;
  }
  if ($FORM{SHOW}) {
    msgs_chat_show();
    return 1;
  }
  if ($FORM{COUNT} && $FORM{MSG_ID}) {
    my $count = $Chatdb->chat_count({ MSG_ID => $FORM{MSG_ID}, SENDER => 'uid' });
    print $count;
    return 1;
  }
  if ($FORM{CHANGE} && $FORM{MSG_ID}) {
    $Chatdb->chat_change({ MSG_ID => $FORM{MSG_ID}, SENDER => 'uid'});
    return 1;
  }
  if ($FORM{INFO} && $FORM{UID}) {
    header_online_chat({UID => $FORM{UID}});
    return 1;
  }
  if ($FORM{US_MS_LIST}) {
    header_online_chat({US_MS_LIST => $FORM{US_MS_LIST}});
    return 1;
  }
  if ($FORM{ID} && $conf{MSGS_CHAT}) {
    my $fn_index = get_function_index('show_user_chat');
    $html->tpl_show(_include('msgs_user_chat', 'Msgs'), {
      F_INDEX  => $fn_index,
      UID      => $user->{UID},
      NUM_TICKET  => $FORM{ID}
    });
  }
  return 1;
}

#**********************************************************
=head2 msgs_chat_add() Add chat message to db

  Arguments:

  Returns:
    true
=cut
#**********************************************************
sub msgs_chat_add {
  if ($FORM{MESSAGE} && $FORM{MSG_ID}) {

    $Chatdb->chat_add({
      MESSAGE     => $FORM{MESSAGE},
      UID         => $FORM{UID} || '0',
      AID         => $FORM{AID} || '0',
      NUM_TICKET  => $FORM{MSG_ID} || '0',
      MSGS_UNREAD => '0',
    });
    if (!$Chatdb->{errno}) {
      $html->message('info', $lang{INFO}, $lang{ADDED});
    }
  }
  return '';
}

#**********************************************************
=head2 msgs_chat_show() - Shows chat messages

  Arguments:

  Returns:
    true
=cut
#**********************************************************
sub msgs_chat_show {
  if (!$FORM{MSG_ID}) {
    return '';
  }
  my $list = '';
  $list = $Chatdb->chat_list({MSG_ID => $FORM{MSG_ID}});

  foreach my $line (@$list) {
    if ($FORM{ADMIN} && $line->{uid} eq '0') {
      $html->tpl_show(_include('msgs_chat_to', 'Msgs'), {
        MESSAGE => $line->{message},
        DATE    => $line->{date},
        SENDER  => 'You',
      });
    }
    elsif ($FORM{ADMIN} && $line->{aid} eq '0') {
      $html->tpl_show(_include('msgs_chat_from', 'Msgs'), {
        MESSAGE => $line->{message},
        DATE    => $line->{date},
        SENDER  => 'User',
      });
    }
    if ($FORM{USER} && $line->{uid}eq'0') {
      print $html->tpl_show(_include('msgs_chat_from', 'Msgs'), {
        MESSAGE => $line->{message},
        DATE    => $line->{date},
        SENDER  => 'Admin',
      }, {OUTPUT2RETURN => 1});
    }
    elsif ($FORM{USER} && $line->{aid}eq'0') {
      print $html->tpl_show(_include('msgs_chat_to', 'Msgs'), {
        MESSAGE => $line->{message},
        DATE    => $line->{date},
        SENDER  => 'You',
      }, {OUTPUT2RETURN => 1});
    }
  }
  return '';
}

1;