package Make_payment;

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
  
  return $self->{bot}->{lang}->{PAYMENT};
}

#**********************************************************
=head2 click()

=cut
#**********************************************************
sub click {
  my $self = shift;
  my ($attr) = @_;
  
  my @inline_keyboard = ();
  my $uid = $self->{bot}->{uid};
  my $message = "$self->{bot}->{lang}->{FIRST_PAYMENT}\n";
  my $money_currency = $self->{conf}->{MONEY_UNIT_NAMES} || '';
  
  use Users;
  my $Users = Users->new($self->{db}, $self->{admin}, $self->{conf});
  $Users->info($uid);
  
  use Payments;
  my $Payments = Payments->new($self->{db}, $self->{admin}, $self->{conf});
  my $last_payments = $Payments->list({
    DATETIME  => '_SHOW',
    SUM       => '_SHOW',
    DESCRIBE  => '_SHOW',
    UID       => $uid,
    DESC      => 'desc',
    SORT      => 1,
    PAGE_ROWS => 1,
    COLS_NAME => 1
  });

  my $users_info = $Users->pi({ UID => $uid });

  if ($users_info->{__UKRPAYS}) {
     $message = $self->{bot}->{lang}->{PAYMENT_NUMBER} . ': <b>' . $users_info->{__UKRPAYS} . '</b>\n';
  } 

  if ($last_payments && $last_payments > 0) {
    my $last_sum = $last_payments->[0]{sum};
    my $last_date = $last_payments->[0]{datetime};

    $message .= "$self->{bot}->{lang}->{UNIQUE_NUMBER}: <b>$users_info->{LOGIN} (UID: $users_info->{UID})</b>\n";
    $message .= "$self->{bot}->{lang}->{DEPOSIT_USER}: <b>$users_info->{DEPOSIT}</b>";
    $message .= " <b>$money_currency</b>\n";
    $message .= "$self->{bot}->{lang}->{LAST_PAYMENT_SUM}: <b>$last_sum $money_currency</b>\n$self->{bot}->{lang}->{DATE}: <b>$last_date</b>";
  }

  my $url = (%ENV) ? "https://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}" : $self->{bot}->{SELF_URL};

  my $inline_button = {
    text     => "$self->{bot}->{lang}->{PAYMENT}",
    url      => "$url/paysys_check.cgi"
  };
  push (@inline_keyboard, [$inline_button]);

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