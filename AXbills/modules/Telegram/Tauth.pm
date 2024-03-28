=head1 NAME

  Telegram auth
=cut

use strict;
use warnings FATAL => 'all';

our (
  $Contacts,
  $Users,
  $admin,
  $Bot,
  %conf,
  %lang,
  $db
);

#**********************************************************
=head2 get_uid($chat_id)

=cut
#**********************************************************
sub get_uid {
  my ($chat_id) = @_;
  my $list = $Contacts->contacts_list({
    TYPE  => 6,
    VALUE => $chat_id,
    UID   => '_SHOW',
  });

  return 0 if ($Contacts->{TOTAL} < 1);

  return $list->[0]->{uid};
}

#**********************************************************
=head2 get_aid($chat_id)

=cut
#**********************************************************
sub get_aid {
  my ($chat_id) = @_;

  my $list = $admin->admins_contacts_list({
    TYPE  => 6,
    VALUE => $chat_id,
    AID   => '_SHOW',
  });

  return 0 if ($admin->{TOTAL} < 1);

  return $list->[0]->{aid};
}

#**********************************************************
=head2 subscribe($message)

=cut
#**********************************************************
sub subscribe {
  my ($message) = @_;
  my ($type, $sid) = $message->{text} =~ m/^\/start ([uae])_([a-zA-Z0-9]+)/;

  if ($type && $sid && $type eq 'u') {
    my $uid = $Users->web_session_find($sid);
    if ($uid) {
      my $list = $Contacts->contacts_list({
        TYPE  => 6,
        VALUE => $message->{chat}{id},
      });

      if (!$Contacts->{TOTAL} || scalar(@{$list}) == 0) {
        $Contacts->contacts_add({
          UID      => $uid,
          TYPE_ID  => 6,
          VALUE    => $message->{chat}{id},
          PRIORITY => 0,
        });
      }
    }
  }
  elsif ($type && $sid && ($type eq 'e' || $type eq 'a')) {
    $admin->online_info({ SID => $sid });
    my $telegram_id = ($type eq 'e' ? 'e_' : '') . $message->{chat}{id};
    my $aid = $admin->{AID};
    if ($aid) {
      my $list = $admin->admins_contacts_list({
        TYPE  => 6,
        VALUE => $telegram_id,
      });

      if (!$admin->{TOTAL} || scalar(@{$list}) == 0) {
        $admin->admin_contacts_add({
          AID      => $aid,
          TYPE_ID  => 6,
          VALUE    => $telegram_id,
          PRIORITY => 0,
        });
        $Bot->send_message({
          text         => "Welcome admin.",
          reply_markup => {
            remove_keyboard => "true"
          },
        });
      }
      else {
        $Bot->send_message({
          text         => 'Sorry check your active subscriptions',
          reply_markup => {
            remove_keyboard => 'true'
          },
        });
      }
    }
    exit 0 if $type ne 'e';
  }
  else {
    subscribe_info();
    exit 0;
  }

  return 1;
}

#**********************************************************
=head2 subscribe_phone($message)

=cut
#**********************************************************
sub subscribe_phone {
  my ($message) = @_;

  # Веб клиент и андроид передают телефон без плюса, виндовс приложение - с плюсом.
  my $phone = $message->{contact}{phone_number};
  $phone =~ s/\D//g;

  if ($conf{TELEGRAM_NUMBER_EXPR}) {
    my ($left, $right) = split "/", $conf{TELEGRAM_NUMBER_EXPR};

    $phone =~ s/$left/$right/ge;
  }

  my $list = $Contacts->contacts_list({
    VALUE => $phone,
    UID   => '_SHOW',
  });

  my $alist = $admin->admins_contacts_list({
    VALUE => $phone,
    AID   => '_SHOW',
  });

  if ($Contacts->{TOTAL} && $list->[0]->{uid}) {
    $Contacts->contacts_add({
      UID      => $list->[0]->{uid},
      TYPE_ID  => 6,
      VALUE    => $message->{chat}{id},
      PRIORITY => 0,
    });
  }
  elsif ($admin->{TOTAL} && $alist->[0]->{aid}) {
    $admin->admin_contacts_add({
      AID      => $alist->[0]->{aid},
      TYPE_ID  => 6,
      VALUE    => $message->{chat}{id},
      PRIORITY => 0,
    });
    $Bot->send_message({
      text         => "Welcome admin.",
      reply_markup => {
        remove_keyboard => "true"
      },
    });
    exit 0;
  }
  else {
    my @inline_keyboard = ();
    my $inline_button = {
      text          => $lang{SUBMIT_YOUR_APPLICATION},
      callback_data => "Crm_new_lead&add_request&$phone",
    };
    push(@inline_keyboard, [ $inline_button ]);

    use Crm::Dialogue;
    my $Dialogue = Crm::Dialogue->new($db, $admin, \%conf, { SOURCE => 'telegram' });

    my $sender = $message->{contact};
    my $lead_id = $Dialogue->crm_lead_by_source({
      USER_ID => $sender->{user_id},
      FIO     => join(' ', (($sender->{first_name} || ''), ($sender->{last_name} || ''))),
      PHONE   => $sender->{phone_number}
    });
    exit 0 if !$lead_id;

    my $dialogue_id = $Dialogue->crm_get_dialogue_id($lead_id);
    exit 0 if !$dialogue_id;

    $Dialogue->crm_send_message('$lang{THE_USER_JOINED_VIA_TELEGRAM}', {
      INNER_MSG => 1, SKIP_CHANGE => 1, DIALOGUE_ID => $dialogue_id
    });

    $Bot->send_message({
      text         => $lang{GREETINGS_YOUR_QUESTION},
      reply_markup => { remove_keyboard => 'true' },
    });
    exit 0;
  }

  return 1;
}
#**********************************************************
=head2 subscribe_info()
  print HOWTO subscribe text

=cut
#**********************************************************
sub subscribe_info {

  my @keyboard = ();
  my $button = {
    text            => $lang{TELEGRAM_VERIFY_PHONE},
    request_contact => 'true',
  };
  push(@keyboard, [ $button ]);

  $Bot->send_message({
    text         => $lang{TELEGRAM_SUBSCRIBE_INFO},
    reply_markup => {
      keyboard        => \@keyboard,
      resize_keyboard => 'true',
    },
    parse_mode   => 'HTML'
  });

  return 1;
}

1;