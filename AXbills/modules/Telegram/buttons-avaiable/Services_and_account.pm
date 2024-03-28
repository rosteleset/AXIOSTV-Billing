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

  use Users;
  my $Users = Users->new($self->{db}, $self->{admin}, $self->{conf});
  $Users->info($uid);
  $Users->pi({UID => $uid});
  $Users->group_info($Users->{GID});
  $credit_warn = 1 if ($Users->{DEPOSIT} + $Users->{CREDIT} <= 0);
  my $money_currency = $self->{conf}->{MONEY_UNIT_NAMES} || '';

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

  my $message = "$self->{bot}->{lang}->{WELLCOME} $Users->{FIO}\n";
  $message .= sprintf("$self->{bot}->{lang}->{DEPOSIT}: %.2f\n", $Users->{DEPOSIT}) . " $money_currency";
  $message .= "\n";
  $message .= "$self->{bot}->{lang}->{LAST_PAYMENT}:\n";
  $message .= sprintf("$self->{bot}->{lang}->{SUM}: %.2f", $last_payments->[0]->{sum}) if ($last_payments->[0]->{sum});
  $message .= " $money_currency\n";
  $message .= "$self->{bot}->{lang}->{DATE}: $last_payments->[0]->{datetime}\n" if ($last_payments->[0]->{datetime});
  $message .= "$self->{bot}->{lang}->{DESCRIBE}: $last_payments->[0]->{describe}\n" if ($last_payments->[0]->{describe});
  $message .= "\n";

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
  $message .= "$self->{bot}->{lang}->{YOUR_SERVICE}:\n";

  my $total_sum_month = 0;
  my $total_sum_day   = 0;
  
  foreach my $line (@$list) {
    $message .= "$self->{bot}->{lang}->{INTERNET}: <b>" . ($line->{tp_name} || q{}) . "</b>\n";
    if ($line->{internet_status} == 3) {
      require Shedule;
      my $Shedule  = Shedule->new($self->{db}, $self->{admin}, $self->{conf});
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
        $message .= "<b>$self->{bot}->{lang}->{SERVICE_STOP_DATE} $holdup_stop_date</b>\n";
        $inline_button = {
          text          => "$self->{bot}->{lang}->{CANCEL_STOP}",
          callback_data => "Services_and_account&stop_holdup&$line->{id}&$shedule_list->[0]->{id}"
        };
      }
      else {
        $message .= "<b>$self->{bot}->{lang}->{SERVICE_STOP}</b>\n";
        $inline_button = {
          text          => "$self->{bot}->{lang}->{CANCEL_STOP}",
          callback_data => "Services_and_account&stop_holdup&$line->{id}"
        };
      }

      push (@inline_keyboard, [$inline_button]) if !$can_stop_holdup->{error} && $inline_button;
    }
    elsif ($line->{internet_status} == 5) {
      $message .= "<b>$self->{bot}->{lang}->{SMALL_DEPOSIT}</b>\n\n";
      $credit_warn = 1;
    }
    else {
      $message .= "$self->{bot}->{lang}->{SPEED}: <b>$line->{speed}</b>\n" if ($line->{speed});
      $message .= "$self->{bot}->{lang}->{PRICE_MONTH}: <b>$line->{month_fee}</b>" if ($line->{month_fee} && $line->{month_fee} > 0);
      $message .= " <b>$money_currency</b>\n";
      $message .= "$self->{bot}->{lang}->{PRICE_DAY}: <b>$line->{day_fee} $money_currency</b>\n" if ($line->{day_fee} && $line->{day_fee} > 0);

      $total_sum_month += $line->{month_fee} || 0;
      $total_sum_day   += $line->{day_fee} || 0;
    }

    $message .= "\n";
  }
  
  $message .= "$self->{bot}->{lang}->{SUM_MONTH}: <b>$total_sum_month</b>";
  $message .= " <b>$money_currency</b>\n";
  $message .= "$self->{bot}->{lang}->{SUM_DAY}: <b>$total_sum_day</b>";
  $message .= " <b>$money_currency</b>\n";

  if ($credit_warn) {
    if ($self->{conf}->{user_credit_change} && $Users->{ALLOW_CREDIT}) {
      $message .= "$self->{bot}->{lang}->{MESSAGE_PAYMENT}\n";
      my $inline_button = {
        text          => "$self->{bot}->{lang}->{SET_CREDIT_USER}",
        callback_data => "Services_and_account&credit"
      };
      push (@inline_keyboard, [$inline_button]);
    }
    else {
      $message .= "$self->{bot}->{lang}->{MESSAGE_PAYMENT}\n";
    }
  }

  if (in_array('Equipment', \@main::MODULES) && $self->{conf}->{TELEGRAM_EQUIPMENT_INFO}) {
    my $inline_button = {
      text          => "$self->{bot}->{lang}->{EQUIPMENT_INFO}",
      callback_data => "Services_and_account&equipment_info_bot"
    };
    push (@inline_keyboard, [$inline_button]);
  }
  else {
    my $inline_button = {
      text          => "$self->{bot}->{lang}->{EQUIPMENT_INFO}",
      callback_data => "Services_and_account&online_info_bot"
    };
    push (@inline_keyboard, [$inline_button]);
  }

  if ($self->{conf}->{TELEGRAM_RESET_MAC}) {
    my $inline_button = {
      text          => "$self->{bot}->{lang}->{INFO_MAC}",
      callback_data => "Services_and_account&mac_info"
    };
    push (@inline_keyboard, [$inline_button]);
  }

  $self->{bot}->send_message({
    text         => $message,
    reply_markup => {
      inline_keyboard => \@inline_keyboard
    },
    parse_mode   => 'HTML'
  }); 

  return 1;
}

#**********************************************************
=head2 stop_holdup()

=cut
#**********************************************************
sub stop_holdup {
  my $self = shift;
  my ($attr) = @_;

  my $stop_holdup_result = $Service_control->user_holdup({
    UID => $attr->{uid},
    ID  => $attr->{argv}[2],
    del => 1,
    IDS => $attr->{argv}[3] ? $attr->{argv}[3] : 0
  });

  $self->{bot}->send_message({
    text       => $stop_holdup_result->{error} ?  $self->{bot}{lang}{ACTIVATION_ERROR} : $self->{bot}{lang}{SERVICE_ACTIVATED},
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
  $Users->info($attr->{uid});

  my $credit_info = $Service_control->user_set_credit({ UID => $attr->{uid}, REDUCTION => $Users->{REDUCTION}, change_credit => 1 });

  $self->{bot}->send_message({
    text       => $credit_info->{errstr} ? ($self->{bot}{lang}{$credit_info->{errstr}} || $self->{bot}{lang}{CREDIT_NOT_EXIST}) : $self->{bot}{lang}{CREDIT_SUCCESS},
    parse_mode => 'HTML'
  });

  return 1
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
  my $intertnet_nas = $Internet->user_list({
    NAS_ID    => '_SHOW',
    PORT      => '_SHOW',
    ONLINE    => '_SHOW',
    CID       => '_SHOW',
    ONLINE_CID => '_SHOW',
    UID        => $uid,
    COLS_NAME  => 1,
  });

  require Equipment;
  my $Equipment = Equipment->new($self->{db}, $self->{admin}, $self->{conf});
  my $onu_list = $Equipment->onu_list({
    STATUS      => '_SHOW',
    BRANCH      => '_SHOW',
    BRANCH_DESC => '_SHOW',
    ONU_DHCP_PORT => $intertnet_nas->[0]{port},
    NAS_ID        => $intertnet_nas->[0]{nas_id},
    COLS_NAME     => 1,
  });

  unless ($onu_list) {
    $message = "$self->{bot}->{lang}->{NOT_INFO}";
  }
  else {
    $message .= "$self->{bot}->{lang}->{EQUIPMENT_USER}: <b>$onu_list->[0]{branch_desc} $onu_list->[0]{branch}</b>\n";
    $message .= "$self->{bot}->{lang}->{STATUS}: <b>" . $status{ $onu_list->[0]{status} } . "</b>\n";
    if ($intertnet_nas->[0]{online}) {
      $message .= "$self->{bot}->{lang}->{CONNECTED}: <b>Online</b>\n";
    }
    else {
      $message .= "$self->{bot}->{lang}->{CONNECTED}: <b>Offline</b>\n";
    }

    if ($intertnet_nas->[0]{cid} 
        && $intertnet_nas->[0]{online_cid} 
        && $intertnet_nas->[0]{cid} ne $intertnet_nas->[0]{online_cid}) {
        $message .= "$self->{bot}->{lang}->{MAC_INVALID}\n";
        $message .= "$self->{bot}->{lang}->{ALLOW_MAC}: <b>$intertnet_nas->[0]{cid}</b>\n";
        $message .= "$self->{bot}->{lang}->{INVALID_MAC}: <b>$intertnet_nas->[0]{online_cid}</b>\n";
    }
  }

  $self->{bot}->send_message({
    text       => $message,
    parse_mode => 'HTML'
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
  
  if ($attr->{argv}[2] && $attr->{argv}[2] eq 'reset_mac') {
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
        text          => "$self->{bot}->{lang}->{RESET_MAC}",
        callback_data => "Services_and_account&mac_info&reset_mac"
      };

      push (@inline_keyboard, [$inline_button]);

      $message = "$self->{bot}->{lang}->{YOUR_MAC}: <b>$mac</b>";
    }
    else {
      $message = "$self->{bot}->{lang}->{NOT_MAC}";
    }
  }

  $self->{bot}->send_message({
    text       => $message,
    reply_markup => {
      inline_keyboard => \@inline_keyboard
    },
    parse_mode => 'HTML'
  });

  return 1;
}

#**********************************************************
=head2 online_info_bot()

=cut
#**********************************************************
sub online_info_bot {
  my $self = shift;
  my ($attr) = @_;

  my $message = "$self->{bot}->{lang}->{EQUIPMENT_INFO}\n";

  require Internet::Sessions;
  my $Sessions = Internet::Sessions->new($self->{db}, $self->{admin}, $self->{conf});
  
  my $sessions_list = $Sessions->online(
    {
      CLIENT_IP          => '_SHOW',
      CID                => '_SHOW',
      DURATION_SEC2      => '_SHOW',
      ACCT_INPUT_OCTETS  => '_SHOW',
      ACCT_OUTPUT_OCTETS => '_SHOW',
      UID                => $attr->{uid}
    }
  );

  if ($sessions_list->[0]) {
    $message .= "$self->{bot}->{lang}->{YOUR_UID} <b>($sessions_list->[0]->{uid})</b>\n";
    $message .= "$self->{bot}->{lang}->{YOUR_LOGIN}: <b>$sessions_list->[0]->{user_name}</b>\n";
    $message .= "$self->{bot}->{lang}->{ID_SESIONS}: <b>$sessions_list->[0]->{acct_session_id}</b>\n";
    $message .= "$self->{bot}->{lang}->{ID_NAS}: <b>$sessions_list->[0]->{nas_id}</b>\n";
    $message .= "$self->{bot}->{lang}->{IP_ADDRESS}: <b>$sessions_list->[0]->{client_ip}</b>\n";
    $message .= "$self->{bot}->{lang}->{CID_ADDRESS}: <b>$sessions_list->[0]->{cid}</b>\n";
  }

  $self->{bot}->send_message({
    text       => $message,
    parse_mode => 'HTML'
  });

  return 1;
}

1;
