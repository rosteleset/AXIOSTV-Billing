package Set_credit;

use strict;
use warnings FATAL => 'all';

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

  my @inline_keyboard = ();
  my $message = '';
  my $credit_data_str = $self->{conf}{user_credit_change};
  my $currency = $self->{conf}{MONEY_UNIT_NAMES} || '';

  my $Users = Users->new($self->{db}, $self->{admin}, $self->{conf});
  $Users->info($self->{bot}{uid});

  if ($Users->{CREDIT} && $Users->{CREDIT} > 0) {
    $message = "$self->{bot}{lang}{END_CREDIT_SET}"
  }
  elsif ($credit_data_str) {
    my ($sum, $days, $price, $month_changes, $payments_expr) = split(/:/, $credit_data_str);

    $message = "$self->{bot}{lang}{SET_CREDIT}: <b>$sum $currency</b>\n";
    $message .= "$self->{bot}{lang}{CREDIT_OPEN}: <b>$days</b> $self->{bot}->{lang}->{DAYS}\n";
    $message .= "$self->{bot}{lang}{CREDIT_PRICE}: <b>$price $currency</b>\n";
    $message .= "$self->{bot}{lang}{SET_CREDIT_ALLOW}: <b>$month_changes</b> $self->{bot}->{lang}->{COUNT}\n";

    my $inline_button = {
      text          => "$self->{bot}->{lang}->{SET_CREDIT_USER}",
      callback_data => "Services_and_account&credit"
    };

    push(@inline_keyboard, [ $inline_button ]);
  }
  else {
    $message = "$self->{bot}{lang}{NOT_CREDIT}";
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

1;