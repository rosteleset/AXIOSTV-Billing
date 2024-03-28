package Internet_info;

use strict;
use warnings FATAL => 'all';

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

  return $self->{bot}->{lang}->{INTERNET};
}

#**********************************************************
=head2 click()

=cut
#**********************************************************
sub click {
  my $self = shift;
  my ($attr) = @_;

  my $uid = $self->{bot}->{uid};
  my $money_currency = $self->{conf}->{MONEY_UNIT_NAMES} || '';

  require Internet;
  my $Internet = Internet->new($self->{db}, $self->{admin}, $self->{conf});
  require Users;
  my $Users = Users->new($self->{db}, $self->{admin}, $self->{conf});
  $Users->info($uid);
  $Users->group_info($Users->{GID});

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
  my $message = "$self->{bot}->{lang}->{CONNECTED_SERVICE}:\\n\\n";

  foreach my $line (@$list) {
    $message .= "$self->{bot}->{lang}->{TARIF_PLAN}: $line->{tp_name}\\n";
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

      if ($Shedule->{TOTAL} && $Shedule->{TOTAL} > 0) {
        my $holdup_stop_date = ($shedule_list->[0]->{d} || '*')
                       . '.' . ($shedule_list->[0]->{m} || '*')
                       . '.' . ($shedule_list->[0]->{y} || '*');
        $message .= "$self->{bot}->{lang}->{SERVICE_STOP_DATE} $holdup_stop_date\\n";
        my $inline_button = {
          text          => "$self->{bot}->{lang}->{CANCEL_STOP}",
          ActionType => 'reply',
          ActionBody => "fn:Internet_info&stop_holdup&$line->{id}&$shedule_list->[0]->{id}",
          TextSize   => 'regular'
        };
        push (@inline_keyboard, $inline_button);
      }
      else {
        $message .= "$self->{bot}->{lang}->{SERVICE_STOP}\\n";
        my $inline_button = {
          Text          => "$self->{bot}->{lang}->{CANCEL_STOP}",
          ActionType => 'reply',
          ActionBody => "fn:Internet_info&stop_holdup&$line->{id}",
          TextSize   => 'regular'
        };
        push (@inline_keyboard, $inline_button);
      }
    }
    elsif ($line->{internet_status} == 5) {
      $message .= "$self->{bot}->{lang}->{SMALL_DEPOSIT}\\n\\n";
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
            ActionBody => "fn:Internet_info&credit",
            TextSize   => 'regular'
          };
          push(@inline_keyboard, $inline_button);

          push (@inline_keyboard, {
            ActionType => 'reply',
            ActionBody => 'MENU',
            Text       => $self->{bot}->{lang}->{BACK},
            BgColor    => "#FF0000",
            TextSize   => 'regular'
          });
        }
      }
    }
    else {
      $message .= "$self->{bot}->{lang}->{SPEED}: $line->{speed}\\n" if ($line->{speed});
      $message .= "$self->{bot}->{lang}->{PRICE_MONTH}: $line->{month_fee}" if ($line->{month_fee} && $line->{month_fee} > 0);
      $message .= " $money_currency\\n"  if ($line->{month_fee} && $line->{month_fee} > 0);
      $message .= "$self->{bot}->{lang}->{PRICE_DAY}: $line->{day_fee}<" if ($line->{day_fee} && $line->{day_fee} > 0);
      $message .= " $money_currency\\n"  if ($line->{day_fee} && $line->{day_fee} > 0);
    }
    $message .= "\\n";
  }

  my $msg = {};

  $msg->{text} = $message if (!$attr->{NO_MSG});
  $msg->{type} = 'text' if (!$attr->{NO_MSG});

  $msg->{keyboard} = {
    Type          => 'keyboard',
    DefaultHeight => "true",
    Buttons       => \@inline_keyboard
  } if (@inline_keyboard);

  $self->{bot}->send_message($msg);

  main::main_menu({NO_MSG=>1}) if(!@inline_keyboard && $attr->{NO_MSG});

  return @inline_keyboard ? "NO_MENU" : 1;
}

#**********************************************************
=head2 stop_holdup()

=cut
#**********************************************************
sub stop_holdup {
  my $self = shift;
  my ($attr) = @_;

  return Services_and_account::stop_holdup($self, $attr);
}

#**********************************************************
=head2 credit()

=cut
#**********************************************************
sub credit {
  my $self = shift;
  my ($attr) = @_;

  return Services_and_account::credit($self, $attr);
}

1;
