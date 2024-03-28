package Services_and_account;

use strict;
use warnings FATAL => 'all';
use AXbills::Base qw(in_array);

require Control::Service_control;
my $Service_control;

#**********************************************************
=head2 new($Botapi)

=cut
#**********************************************************
sub new {
  my $class = shift;
  my ($db, $admin, $conf, $bot) = @_;

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $conf,
    bot   => $bot,
  };

  bless($self, $class);

  $Service_control = Control::Service_control->new($self->{db}, $self->{admin}, $self->{conf});

  return $self;
}

#**********************************************************
=head2 btn_name()

=cut
#**********************************************************
sub btn_name {
  my $self = shift;

  return $self->{bot}{lang}{SERVICES};
}

#**********************************************************
=head2 click()

=cut
#**********************************************************
sub click {
  my $self = shift;
  my ($attr) = @_;

  my $uid = $self->{bot}->{uid};
  my $credit_warn = 0;
  my $money_currency = $self->{conf}->{MONEY_UNIT_NAMES} || '';

  use Users;
  my $Users = Users->new($self->{db}, $self->{admin}, $self->{conf});
  $Users->info($uid);
  $Users->pi({ UID => $uid });
  $Users->group_info($Users->{GID});
  $credit_warn = 1 if ($Users->{DEPOSIT} + $Users->{CREDIT} <= 0);

  use Payments;
  my $Payments = Payments->new($self->{db}, $self->{admin}, $self->{conf});
  my $last_payments = $Payments->list({
    UID       => $uid,
    DATETIME  => '_SHOW',
    SUM       => '_SHOW',
    DESCRIBE  => '_SHOW',
    DESC      => 'desc',
    SORT      => 1,
    PAGE_ROWS => 1,
    COLS_NAME => 1
  });

  my $message = "$self->{bot}->{lang}->{WELLCOME} $Users->{FIO}\\n";
  $message .= sprintf("$self->{bot}->{lang}->{DEPOSIT}: %.2f", $Users->{DEPOSIT});
  $message .= " $money_currency\\n";
  $message .= "\\n";
  $message .= "$self->{bot}->{lang}->{LAST_PAYMENT}:\\n";
  $message .= sprintf("$self->{bot}->{lang}->{SUM}: %.2f", $last_payments->[0]->{sum}) if ($last_payments->[0]->{sum});
  $message .= " $money_currency\\n" if ($last_payments->[0]->{sum});
  $message .= "$self->{bot}->{lang}->{DATE}: $last_payments->[0]->{datetime}\\n" if ($last_payments->[0]->{datetime});
  $message .= "$self->{bot}->{lang}->{DESCRIBE}: $last_payments->[0]->{describe}\\n" if ($last_payments->[0]->{describe});
  $message .= "\\n";

  require Internet;
  my $Internet = Internet->new($self->{db}, $self->{admin}, $self->{conf});
  my $list = $Internet->user_list({
    ID              => '_SHOW',
    TP_NAME         => '_SHOW',
    SPEED           => '_SHOW',
    MONTH_FEE       => '_SHOW',
    DAY_FEE         => '_SHOW',
    INTERNET_STATUS => '_SHOW',
    GROUP_BY        => 'internet.id',
    UID             => $uid,
    COLS_NAME       => 1,
  });

  my @inline_keyboard = ();
  $message .= "$self->{bot}->{lang}->{YOUR_SERVICE}:\\n";

  my $total_sum_month = 0;
  my $total_sum_day = 0;

  foreach my $line (@$list) {
    $message .= "$self->{bot}->{lang}->{INTERNET}: $line->{tp_name}\\n";
    if ($line->{internet_status} == 3) {
      require Shedule;
      my $Shedule = Shedule->new($self->{db}, $self->{admin}, $self->{conf});
      my $shedule_list = $Shedule->list({
        UID        => $uid,
        SERVICE_ID => $line->{id},
        MODULE     => 'Internet',
        TYPE       => 'status',
        ACTION     => '*:0',
        COLS_NAME  => 1
      });

      my $can_stop_holdup = $Service_control->user_holdup({ ID => $line->{id}, UID => $uid });
      my $inline_button = '';

      if ($Shedule->{TOTAL} && $Shedule->{TOTAL} > 0) {
        my $holdup_stop_date = ($shedule_list->[0]->{d} || '*')
          . '.' . ($shedule_list->[0]->{m} || '*')
          . '.' . ($shedule_list->[0]->{y} || '*');
        $message .= "$self->{bot}->{lang}->{SERVICE_STOP_DATE} $holdup_stop_date\\n";
        $inline_button = {
          Text       => "$self->{bot}->{lang}->{CANCEL_STOP}",
          ActionType => 'reply',
          ActionBody => "fn:Services_and_account&stop_holdup&$line->{id}&$shedule_list->[0]->{id}",
          TextSize   => 'regular'
        };
      }
      else {
        $message .= "$self->{bot}->{lang}->{SERVICE_STOP}\\n";
        $inline_button = {
          Text       => "$self->{bot}->{lang}->{CANCEL_STOP}",
          ActionType => 'reply',
          ActionBody => "fn:Services_and_account&stop_holdup&$line->{id}",
          TextSize   => 'regular'
        };
      }

      push(@inline_keyboard, $inline_button) if !$can_stop_holdup->{error} && $inline_button;
    }
    elsif ($line->{internet_status} == 5) {
      $message .= "$self->{bot}->{lang}->{SMALL_DEPOSIT}\\n\\n";
      $credit_warn = 1;
    }
    else {
      $message .= "$self->{bot}->{lang}->{SPEED}: $line->{speed}\\n" if ($line->{speed});
      $message .= "$self->{bot}->{lang}->{PRICE_MONTH}: $line->{month_fee}" if ($line->{month_fee} && $line->{month_fee} > 0);
      $message .= " $money_currency\\n" if ($line->{month_fee} && $line->{month_fee} > 0);
      $message .= "$self->{bot}->{lang}->{PRICE_DAY}: $line->{day_fee}" if ($line->{day_fee} && $line->{day_fee} > 0);
      $message .= " $money_currency\\n" if ($line->{day_fee} && $line->{day_fee} > 0);

      $total_sum_month += $line->{month_fee};
      $total_sum_day += $line->{day_fee};
    }

    $message .= "\\n";
  }

  $message .= "$self->{bot}->{lang}->{SUM_MONTH}: $total_sum_month";
  $message .= " $money_currency\\n";
  $message .= "$self->{bot}->{lang}->{SUM_DAY}: $total_sum_day";
  $message .= " $money_currency\\n";

  if ($credit_warn) {
    if ($self->{conf}{user_credit_change}) {
      my $credit_info = $Service_control->user_set_credit({ UID => $self->{bot}{uid}, REDUCTION => $Users->{REDUCTION} });
      if (!$credit_info->{errstr}) {
        my $currency = $self->{conf}{MONEY_UNIT_NAMES} || '';
        my $sum = $credit_info->{CREDIT_SUM} || 0;
        my $days = $credit_info->{CREDIT_DAYS} || 0;
        my $price = $credit_info->{CREDIT_CHG_PRICE} || 0;
        my $month_changes = $credit_info->{CREDIT_MONTH_CHANGES} || 0;

        $message .= "$self->{bot}{lang}{SET_CREDIT}: $sum $currency\\n";
        $message .= "$self->{bot}{lang}{CREDIT_OPEN}: $days $self->{bot}->{lang}->{DAYS}\\n";
        $message .= "$self->{bot}{lang}{CREDIT_PRICE}: $price $currency\\n";
        $message .= "$self->{bot}{lang}{SET_CREDIT_ALLOW}: $month_changes $self->{bot}->{lang}->{COUNT}\\n";

        my $inline_button = {
          Text       => "$self->{bot}->{lang}->{CREDIT_SET}",
          ActionType => 'reply',
          ActionBody => "fn:Services_and_account&credit",
          TextSize   => 'regular'
        };
        push(@inline_keyboard, $inline_button);
      }
    }
    else {
      $message .= "$self->{bot}->{lang}->{MESSAGE_PAYMENT}\\n";
    }
  }

  if (in_array('Equipment', \@main::MODULES)) {
    my $inline_button = {
      Text       => "$self->{bot}->{lang}->{EQUIPMENT_INFO}",
      ActionType => 'reply',
      ActionBody => "fn:Services_and_account&equipment_info_bot",
      TextSize   => 'regular'
    };
    push(@inline_keyboard, $inline_button);
  }
  else {
    my $inline_button = {
      Text       => "$self->{bot}->{lang}->{EQUIPMENT_INFO}",
      ActionType => 'reply',
      ActionBody => "fn:Services_and_account&online_info_bot",
      TextSize   => 'regular'
    };
    push(@inline_keyboard, $inline_button);
  }

  if ($self->{conf}->{VIBER_RESET_MAC}) {
    my $inline_button = {
      Text       => "$self->{bot}->{lang}->{INFO_MAC}",
      ActionType => 'reply',
      ActionBody => "fn:Services_and_account&mac_info",
      TextSize   => 'regular'
    };
    push(@inline_keyboard, $inline_button);
  }

  my $inline_button = {
    ActionType => 'reply',
    ActionBody => 'MENU',
    Text       => $self->{bot}->{lang}->{BACK},
    BgColor    => "#FF0000",
    TextSize   => 'regular'
  };
  push(@inline_keyboard, $inline_button);

  my $msg = {
    keyboard => {
      Type          => 'keyboard',
      DefaultHeight => "true",
      Buttons       => \@inline_keyboard
    },
  };

  if (!$attr->{argv}[0] && !$attr->{argv}[0] ne "back") {
    $msg->{text} = $message if (!$attr->{NO_MSG});
    $msg->{type} = 'text' if (!$attr->{NO_MSG});
  }

  $self->{bot}->send_message($msg);

  return "NO_MENU";
}

#**********************************************************
=head2 stop_holdup()

=cut
#**********************************************************
sub stop_holdup {
  my $self = shift;
  my ($attr) = @_;

  my $stop_holdup_result = $Service_control->user_holdup({
    UID => $self->{bot}->{uid},
    ID  => $attr->{argv}[0],
    del => 1,
    IDS => $attr->{argv}[2] ? $attr->{argv}[2] : 0
  });

  $self->{bot}->send_message({
    text       => $stop_holdup_result->{error} ? $self->{bot}{lang}{ACTIVATION_ERROR} : $self->{bot}{lang}{SERVICE_ACTIVATED},
    parse_mode => 'HTML'
  });

  return 1;
}

#**********************************************************
=head2 credit()

=cut
#**********************************************************
sub credit {
  my $self = shift;
  my ($attr) = @_;

  use Users;
  my $Users = Users->new($self->{db}, $self->{admin}, $self->{conf});
  $Users->info($self->{bot}->{uid});

  my $credit_info = $Service_control->user_set_credit({ UID => $self->{bot}->{uid}, REDUCTION => $Users->{REDUCTION}, change_credit => 1 });

  $self->{bot}->send_message({
    text => $credit_info->{errstr} ? ($self->{bot}{lang}{$credit_info->{errstr}} || $self->{bot}{lang}{CREDIT_NOT_EXIST}) : $self->{bot}{lang}{CREDIT_SUCCESS},
    type => 'text'
  });

  return 1;
}

#**********************************************************
=head2 equipment_info_bot()

=cut
#**********************************************************
sub equipment_info_bot {
  my $self = shift;
  my ($attr) = @_;

  my %status = (
    0 => "Offline",
    1 => "Online"
  );

  my $uid = $self->{bot}->{uid};
  my $message = '';

  require Internet;
  my $Internet = Internet->new($self->{db}, $self->{admin}, $self->{conf});
  my $internet_nas = $Internet->user_list({
    NAS_ID     => '_SHOW',
    PORT       => '_SHOW',
    ONLINE     => '_SHOW',
    CID        => '_SHOW',
    ONLINE_CID => '_SHOW',
    UID        => $uid,
    COLS_NAME  => 1,
  });

  require Equipment;
  my $Equipment = Equipment->new($self->{db}, $self->{admin}, $self->{conf});
  my $onu_list = $Equipment->onu_list({
    STATUS        => '_SHOW',
    BRANCH        => '_SHOW',
    BRANCH_DESC   => '_SHOW',
    ONU_DHCP_PORT => $internet_nas->[0]{port},
    NAS_ID        => $internet_nas->[0]{nas_id},
    COLS_NAME     => 1,
  });

  if ($Equipment->{TOTAL} < 1) {
    $message = "$self->{bot}->{lang}->{NOT_INFO}";
  }
  else {
    $message .= "$self->{bot}{lang}{EQUIPMENT_USER}: $onu_list->[0]{branch_desc} $onu_list->[0]{branch}\\n";
    $message .= "$self->{bot}{lang}{STATUS}: " . $status{ $onu_list->[0]{status} } . "\\n";
    if ($internet_nas->[0]{online}) {
      $message .= "$self->{bot}{lang}{CONNECTED}: Online\\n";
    }
    else {
      $message .= "$self->{bot}{lang}{CONNECTED}: Offline\\n";
    }

    if ($internet_nas->[0]{cid}
      && $internet_nas->[0]{online_cid}
      && $internet_nas->[0]{cid} ne $internet_nas->[0]{online_cid}) {
      $message .= "$self->{bot}{lang}{MAC_INVALID}\\n";
      $message .= "$self->{bot}{lang}{ALLOW_MAC}: $internet_nas->[0]{cid}\\n";
      $message .= "$self->{bot}{lang}{INVALID_MAC}: $internet_nas->[0]{online_cid}\\n";
    }
  }

  $self->{bot}->send_message({
    text => $message,
    type => 'text'
  });

  return 1;
}

#**********************************************************
=head2 mac_info()

=cut
#**********************************************************
sub mac_info {
  my $self = shift;
  my ($attr) = @_;

  require Internet;
  my $Internet = Internet->new($self->{db}, $self->{admin}, $self->{conf});

  my @inline_keyboard = ();
  my $mac = '';
  my $uid = $self->{bot}->{uid};
  my $message = '';
  my $no_menu = 0;

  if ($attr->{argv}[0] && $attr->{argv}[0] eq 'reset_mac') {
    $Internet->user_change({
      UID => $uid,
      CID => '',
    });

    $message = "$self->{bot}->{lang}->{RESET_MAC_SUCCESS}";
  }
  else {
    my $intertnet_info = $Internet->user_info($uid);

    if ($intertnet_info->{CID}) {
      $mac = $intertnet_info->{CID};
      my $inline_button = {
        Text       => "$self->{bot}->{lang}->{RESET_MAC}",
        ActionType => 'reply',
        ActionBody => "fn:Services_and_account&mac_info&reset_mac",
        TextSize   => 'regular'
      };

      push(@inline_keyboard, $inline_button);

      $inline_button = {
        ActionType => 'reply',
        ActionBody => 'fn:Services_and_account&click&back',
        Text       => $self->{bot}->{lang}->{BACK},
        BgColor    => "#FF0000",
        TextSize   => 'regular'
      };
      push(@inline_keyboard, $inline_button);

      $message = "$self->{bot}->{lang}->{YOUR_MAC}: $mac";
      $no_menu = 1;
    }
    else {
      $message = "$self->{bot}->{lang}->{NOT_MAC}";
    }
  }

  my $msg = {
    text => $message,
    type => 'text',
  };

  $msg->{keyboard} = {
    Type          => 'keyboard',
    DefaultHeight => "true",
    Buttons       => \@inline_keyboard
  } if (@inline_keyboard);

  $self->{bot}->send_message($msg);

  return $no_menu ? "NO_MENU" : 1;
}

#**********************************************************
=head2 online_info_bot()

=cut
#**********************************************************
sub online_info_bot {
  my $self = shift;
  my ($attr) = @_;

  my $message = "$self->{bot}->{lang}->{EQUIPMENT_INFO}\\n";

  require Internet::Sessions;
  my $Sessions = Internet::Sessions->new($self->{db}, $self->{admin}, $self->{conf});

  my $sessions_list = $Sessions->online(
    {
      CLIENT_IP          => '_SHOW',
      CID                => '_SHOW',
      DURATION_SEC2      => '_SHOW',
      ACCT_INPUT_OCTETS  => '_SHOW',
      ACCT_OUTPUT_OCTETS => '_SHOW',
      UID                => $self->{bot}->{uid}
    }
  );

  if ($sessions_list->[0]) {
    $message .= "$self->{bot}->{lang}->{YOUR_UID} ($sessions_list->[0]->{uid})\\n";
    $message .= "$self->{bot}->{lang}->{YOUR_LOGIN}: $sessions_list->[0]->{user_name}\\n";
    $message .= "$self->{bot}->{lang}->{ID_SESIONS}: $sessions_list->[0]->{acct_session_id}\\n";
    $message .= "$self->{bot}->{lang}->{ID_NAS}: $sessions_list->[0]->{nas_id}\\n";
    $message .= "$self->{bot}->{lang}->{IP_ADDRESS}: $sessions_list->[0]->{client_ip}\\n";
    $message .= "$self->{bot}->{lang}->{CID_ADDRESS}: $sessions_list->[0]->{cid}\\n";
  }

  $self->{bot}->send_message({
    text => $message,
    type => 'text'
  });

  return 1;
}

1;
