package Set_credit;

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

  return $self->{bot}{lang}{CREDIT};
}

#**********************************************************
=head2 click()

=cut
#**********************************************************
sub click {
  my $self = shift;
  my ($attr) = @_;

  use Users;
  my $Users = Users->new($self->{db}, $self->{admin}, $self->{conf});
  $Users->info($self->{bot}{uid});

  my $credit_info = $Service_control->user_set_credit({ UID => $self->{bot}{uid}, REDUCTION => $Users->{REDUCTION} });

  if ($credit_info->{errstr}) {
    $self->{bot}->send_message({
      text => $self->{bot}{lang}{$credit_info->{errstr}} || $self->{bot}{lang}{CREDIT_NOT_EXIST},
      type => 'text',
    });
    return 1;
  }

  my @inline_keyboard = ();
  my $currency = $self->{conf}{MONEY_UNIT_NAMES} || '';
  my $sum = $credit_info->{CREDIT_SUM} || 0;
  my $days = $credit_info->{CREDIT_DAYS} || 0;
  my $price = $credit_info->{CREDIT_CHG_PRICE} || 0;
  my $month_changes = $credit_info->{CREDIT_MONTH_CHANGES} || 0;

  my @message = ();
  push @message, "$self->{bot}{lang}{SET_CREDIT}: $sum $currency";
  push @message, "$self->{bot}{lang}{CREDIT_OPEN}: *$days* $self->{bot}->{lang}->{DAYS}";
  push @message, "$self->{bot}{lang}{CREDIT_PRICE}: $price $currency";
  push @message, "$self->{bot}{lang}{SET_CREDIT_ALLOW}: *$month_changes* $self->{bot}->{lang}->{COUNT}";

  my $inline_button = {
    Text       => $self->{bot}{lang}{SET_CREDIT_USER},
    ActionType => 'reply',
    ActionBody => 'fn:Set_credit&credit',
    TextSize   => 'regular'
  };
  push(@inline_keyboard, $inline_button);

  push (@inline_keyboard, {
    ActionType => 'reply',
    ActionBody => 'MENU',
    Text       => $self->{bot}->{lang}->{BACK},
    BgColor    => '#FF0000',
    TextSize   => 'regular'
  });

  $self->{bot}->send_message({
    keyboard => {
      Type          => 'keyboard',
      DefaultHeight => 'true',
      Buttons       => \@inline_keyboard
    },
    text     => join('\\n', @message),
    type     => 'text'
  });

  return 'NO_MENU';
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
    type => 'text',
  });

  return 1;
}

1;