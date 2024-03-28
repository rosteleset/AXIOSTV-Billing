package Admin_msgs;

use strict;
use warnings FATAL => 'all';
use AXbills::Base qw(in_array int2ip);

my $Msgs;
my %icons = (
  user        => "\xF0\x9F\x91\xA4",
  date        => "\xF0\x9F\x95\x98",
  closed      => "\xE2\x9C\x85",
  open        => "\xE2\x8C\x9B",
  chapter     => "\xE2\x9C\x8E",
  line        => "\xE2\x9E\x96",
  wave_line   => "\xE3\x80\xB0",
  right_arrow => "\xE2\x9E\xA1",
  number_1    => "\x31\xEF\xB8\x8F\xE2\x83\xA3",
  number_2    => "\x32\xEF\xB8\x8F\xE2\x83\xA3",
  number_3    => "\x33\xEF\xB8\x8F\xE2\x83\xA3",
  number_4    => "\x34\xEF\xB8\x8F\xE2\x83\xA3",
  number_5    => "\x35\xEF\xB8\x8F\xE2\x83\xA3",
  search      => "\xF0\x9F\x94\x8D",
);
my %msgs_status = ();

#**********************************************************
=head2 new()

=cut
#**********************************************************
sub new {
  my $class = shift;
  my ($db, $admin, $conf, $bot) = @_;

  my $self = {
    db         => $db,
    admin      => $admin,
    conf       => $conf,
    bot        => $bot,
    for_admins => 1
  };

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 btn_name()

=cut
#**********************************************************
sub btn_name {
  my $self = shift;

  return $self->{bot}{lang}{MESSAGES};
}

#**********************************************************
=head2 click()

=cut
#**********************************************************
sub click {
  my $self = shift;
  my ($attr) = @_;

  $self->_get_statuses();

  my $page = $attr->{argv}[2];
  my $message = "\xF0\x9F\x93\x83 <b>$self->{bot}{lang}{ADMIN}:</b> $self->{admin}{A_FIO}\n\n";
  my @inline_keyboard = ();
  my @equipment_buttons = ();

  $message .= $self->messages_list($page, \@equipment_buttons);

  push @inline_keyboard, \@equipment_buttons;
  push @inline_keyboard, _get_page_range($page, $self->{last_page}, 'click');

  $self->_send_message($message, $page, \@inline_keyboard, $attr);

  return 1;
}

#**********************************************************
=head2 messages_list($page, $buttons)

=cut
#**********************************************************
sub messages_list {
  my $self = shift;
  my ($page, $buttons, $attr) = @_;

  my @info = ();

  my $messages = $Msgs->messages_list({
    SUBJECT      => '_SHOW',
    STATE_ID     => '_SHOW',
    DATETIME     => '_SHOW',
    MESSAGE      => '_SHOW',
    CHAPTER_NAME => '_SHOW',
    UID          => '_SHOW',
    LOGIN        => '_SHOW',
    FIO          => '_SHOW',
    STATE        => '!1,!2',
    RESPOSIBLE   => $self->{admin}{AID},
    PAGE_ROWS    => 5,
    PG           => $page ? (($page - 1) * 5) : 0,
    %{$attr // {}},
    COLS_NAME    => 1
  });
  $self->{last_page} = int($Msgs->{TOTAL} / 5) + ($Msgs->{TOTAL} % 5 == 0 ? 0 : 1) if $Msgs->{TOTAL} > 5;

  my $number = 1;
  foreach my $message (@{$messages}) {
    my $icon = $icons{"number_" . $number++} || '';
    $message->{subject} ||= $self->{bot}{lang}{NO_SUBJECT};
    $message->{chapter_name} ||= $self->{bot}{lang}{NO_CHAPTER};
    $message->{fio} ||= $message->{login} || '';
    $message->{status} = $msgs_status{$message->{state_id}} || '';

    my $message_info = "$icon  <b>$message->{subject}</b>\n";
    $message_info .= "$icons{chapter} $message->{chapter_name}\n";
    $message_info .= "$icons{date} $message->{datetime}\n";
    $message_info .= "$message->{status}\n";
    $message_info .= "$icons{user} $message->{fio}\n";

    push(@info, $message_info);
    push(@{$buttons}, {
      text          => $icon,
      callback_data => "Admin_msgs&msgs_info&$message->{id}"
    });
  }

  return join($icons{line} x 9 . "\n", @info);
}

#**********************************************************
=head2 msgs_info($attr)

=cut
#**********************************************************
sub msgs_info {
  my $self = shift;
  my ($attr) = @_;

  my $msg_id = $attr->{argv}[2];
  return if !$msg_id;

  $self->_get_statuses();

  my @inline_keyboard = ();
  my $msg_info = $Msgs->message_info($msg_id);
  $msg_info->{SUBJECT} ||= $self->{bot}{lang}{NO_SUBJECT};
  $msg_info->{CHAPTER_NAME} ||= $self->{bot}{lang}{NO_CHAPTER};
  $msg_info->{STATUS} = $msgs_status{$msg_info->{STATE}} || '';

  my $message = "#$msg_id <b>$msg_info->{SUBJECT}</b>\n\n";

  $message .= "$icons{chapter} $msg_info->{CHAPTER_NAME}\n";
  $message .= "$icons{date} $msg_info->{DATE}\n";
  $message .= "$msg_info->{STATUS}\n";
  $message .= "$icons{user} $msg_info->{LOGIN}\n\n";

  $message .= "$msg_info->{MESSAGE}\n";

  push(@inline_keyboard, [ {
    text          => "$icons{user} $self->{bot}{lang}{USER_INFO}",
    callback_data => "Admin_msgs&user_info&$msg_info->{UID}"
  } ]) if $msg_info->{UID};

  $self->_send_message($message, 0, \@inline_keyboard);
}

#**********************************************************
=head2 user_info($attr)

=cut
#**********************************************************
sub user_info {
  my $self = shift;
  my ($attr) = @_;

  my $uid = $attr->{argv}[2];
  return if !$uid;

  use Users;
  my $Users = Users->new($self->{db}, $self->{admin}, $self->{conf});
  my $user_info = $Users->pi({ UID => $uid });

  $user_info->{FIO} ||= '';
  $user_info->{PHONE} ||= '';
  my $message = "<b>$self->{bot}{lang}{USER_INFO}</b>\n\n";
  $message .= "<b>$self->{bot}{lang}{FIO}</b>: $user_info->{FIO}\n";
  $message .= "<b>$self->{bot}{lang}{PHONE}</b>: $user_info->{PHONE}\n";
  $message .= $icons{wave_line} x 9 . "\n";
  $message .= $self->_user_internet_info($uid);

  $self->{bot}->send_message({ text => $message, parse_mode => 'HTML' });
}

#**********************************************************
=head2 search($attr)

=cut
#**********************************************************
sub search {
  my $self = shift;
  my ($attr) = @_;

  my $search = Encode::encode_utf8($attr->{argv}[2]) || '';
  my $page = $attr->{argv}[3] || 0;

  $self->_get_statuses();

  my $search_text = "$icons{search} <b>$self->{bot}{lang}{SEARCH}: $search</b>\n\n";
  my @msgs_buttons = ();
  my @inline_keyboard = ();

  $search_text .= $self->messages_list($page, \@msgs_buttons, { SEARCH_MSGS => $search, STATE => '_SHOW' });

  push @inline_keyboard, \@msgs_buttons;
  push @inline_keyboard, _get_page_range($page, $self->{last_page}, "search&$search");

  $self->_send_message($search_text, $page, \@inline_keyboard, $attr);
}

#**********************************************************
=head2 _user_internet_info($uid)

=cut
#**********************************************************
sub _user_internet_info {
  my $self = shift;
  my $uid = shift;

  use Internet;
  my $Internet = Internet->new($self->{db}, $self->{admin}, $self->{conf});

  my $internet_info = $Internet->user_list({
    UID        => $uid,
    TP_NAME    => '_SHOW',
    IP         => '_SHOW',
    GROUP_BY   => 'internet.id',
    COLS_NAME  => 1,
    COLS_UPPER => 1
  });

  my @info = ();
  foreach my $tp (@{$internet_info}) {
    $tp->{TP_NAME} ||= '';
    $tp->{IP_NUM} = int2ip($tp->{IP_NUM});

    my $message_info = "<b>$self->{bot}{lang}{NAME}</b>: $tp->{TP_NAME}\n";
    $message_info .= "<b>IP</b>: $tp->{IP_NUM}\n";
    push(@info, $message_info);
  }

  return "<b>$self->{bot}{lang}{TARIF_PLANS}:</b> \n\n" . join($icons{line} x 9 . "\n", @info);
}

#**********************************************************
=head2 _get_page_range($page, $last_page, $path)

=cut
#**********************************************************
sub _get_page_range {
  my ($page, $last_page, $path) = @_;

  return [] if !$last_page || $last_page < 2;

  my @row = ();
  my @range = $last_page < 5 ? (1 .. $last_page) : (!$page || $page < 4) ? (1 .. 4, $last_page) :
    ($page + 2 < $last_page) ? (1, $page - 1 .. $page + 1, $last_page) : (1, $last_page - 3 .. $last_page);

  for (@range) {
    push @row, {
      text          => (!$page && $_ eq '1') || ($page && $page eq $_) ? "$icons{right_arrow} $_" : $_,
      callback_data => "Admin_msgs&$path&$_"
    }
  }

  return \@row;
}

#**********************************************************
=head2 _send_message($message, $page, $inline_keyboard, $attr)

=cut
#**********************************************************
sub _send_message {
  my $self = shift;
  my ($message, $page, $inline_keyboard, $attr) = @_;

  push @{$inline_keyboard}, [ {
    text                             => $icons{search} . ' ' . $self->{bot}{lang}{SEARCH},
    switch_inline_query_current_chat => "/msgs "
  } ];

  if ($page) {
    $self->{bot}->edit_message_text({
      text         => $message,
      message_id   => $attr->{message_id},
      reply_markup => {
        inline_keyboard => $inline_keyboard,
        resize_keyboard => "true",
      },
      parse_mode   => 'HTML'
    });
    return 1;
  }

  $self->{bot}->send_message({
    text         => $message,
    reply_markup => {
      inline_keyboard => $inline_keyboard,
      resize_keyboard => "true",
    },
    parse_mode   => 'HTML'
  });
}

#**********************************************************
=head2 _get_statuses()

=cut
#**********************************************************
sub _get_statuses {
  my $self = shift;

  require Msgs;
  Msgs->import();
  $Msgs = Msgs->new($self->{db}, $self->{admin}, $self->{conf});

  my $statuses = $Msgs->status_list({ TASK_CLOSED => '_SHOW', STATUS_ONLY => 1, NAME => '_SHOW', COLS_NAME => 1 });
  foreach my $status (@{$statuses}) {
    if ($status->{name} =~ /\$lang\{(\S+)\}/g) {
      my $marker = $1;
      $status->{name} =~ s/\$lang\{$marker\}/$self->{bot}{lang}{$marker}/;
    }

    $msgs_status{$status->{id}} = $icons{$status->{task_closed} ? 'closed' : 'open'} . ' ' . $status->{name} || '';
  }
}

1;
