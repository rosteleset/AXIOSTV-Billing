package City24_payment;

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

  return $self->{bot}->{lang}->{CITY24_PAYMENT};
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
  my $message = "$self->{bot}{lang}{CITY24_TELEGRAM}\n";

  use Users;
  my $Users = Users->new($self->{db}, $self->{admin}, $self->{conf});
  $Users->info($uid);

  my $users_info = $Users->pi({ UID => $uid });

  my $account_key =  $users_info->{UID};
  my $gid = $users_info->{GID};

  if(main::get_gid_conf("PAYSYS_CITY24_ACCOUNT_KEY", $gid) eq "CONTRACT_ID"){
    $account_key = $users_info->{CONTRACT_ID};
  }
  elsif(main::get_gid_conf("PAYSYS_CITY24_ACCOUNT_KEY", $gid) eq "LOGIN"){
    $account_key = $users_info->{LOGIN};
  }

  my $amount = abs($users_info->{DEPOSIT});
  my $fast_pay = main::get_gid_conf("PAYSYS_CITY24_FAST_PAY", $gid);
  my $url_pay = "$fast_pay"  . "?paymethodid=6" . "&number=" .  "$account_key" . "&amount=" . "$amount";

  if (main::get_gid_conf("PAYSYS_CITY24_ACCOUNT_KEY", $gid)) {
    $message .= "$self->{bot}{lang}{UNIQUE_NUMBER}: <b>$account_key</b>\n";
    $message .= "$self->{bot}{lang}{PAYMENT_SUM}: <b>$users_info->{DEPOSIT}</b>\n";
    $message .= "$self->{bot}{lang}{PAY_SUM_CHANGE}\n";
  }
  else{
    $message .= "$self->{bot}{lang}{ERROR_PAY}\n";
  }

  my $inline_button = {
    text     => "$self->{bot}{lang}{CITY24_PAYMENT}",
    url      => "$url_pay"
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