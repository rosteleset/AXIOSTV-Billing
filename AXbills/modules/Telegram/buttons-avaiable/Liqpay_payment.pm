package Liqpay_payment;
use strict;
use warnings FATAL => 'all';

use Paysys::systems::Liqpay;
use AXbills::Base qw(mk_unique_value);
use Users;
use Conf;
require AXbills::Misc;

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

  Conf->new($self->{db}, $admin, $self->{conf});

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 btn_name()

=cut
#**********************************************************
sub btn_name {
  my $self = shift;

  return $self->{bot}->{lang}->{LIQPAY_PAYMENT};
}

#**********************************************************
=head2 click()

=cut
#**********************************************************
sub click {
  my $self = shift;
  my ($attr) = @_;

  my $users = Users->new($self->{db}, $self->{admin}, $self->{conf});
  my $Liqpay = Paysys::systems::Liqpay->new($self->{db}, $self->{admin}, $self->{conf}, { lang => $self->{bot}{lang} });

  my $list = $users->list({
    UID            => $self->{bot}->{uid},
    LOGIN          => '_SHOW',
    FIO            => '_SHOW',
    DEPOSIT        => '_SHOW',
    CREDIT         => '_SHOW',
    PHONE          => '_SHOW',
    ADDRESS_FULL   => '_SHOW',
    GID            => '_SHOW',
    DOMAIN_ID      => '_SHOW',
    DISABLE_PAYSYS => '_SHOW',
    GROUP_NAME     => '_SHOW',
    DISABLE        => '_SHOW',
    CONTRACT_ID    => '_SHOW',
    ACTIVATE       => '_SHOW',
    REDUCTION      => '_SHOW',
    BILL_ID        => '_SHOW',
    COLS_NAME      => 1,
    COLS_UPPER     => 1,
    PAGE_ROWS      => 1,
  });

  my $deposit = sprintf("%.2f", $list->[0]->{DEPOSIT});
  my $amount = ::recomended_pay($list->[0]) || 1;

  my $operation_id = mk_unique_value(9, { SYMBOLS => '0123456789' });

  my $paysys_link = $Liqpay->fast_pay_link({
    SUM          => $amount,
    OPERATION_ID => $operation_id,
    USER         => $list->[0],
  });

  my $message = "$self->{bot}{lang}{LIQPAY_TELEGRAM}\n";

  if ($paysys_link->{URL}) {
    $message .= "$self->{bot}{lang}{YOUR_DEPOSIT}: <b>$deposit</b>\n";
    $message .= "$self->{bot}{lang}{UNIQUE_NUMBER}: <b>$operation_id</b>\n";
    $message .= "$self->{bot}{lang}{PAYMENT_SUM}: <b>$amount</b>\n";
  } else {
    $message .= "$self->{bot}{lang}{ERROR_PAY}\n";
  }

  my @inline_keyboard = ();
  my $inline_button = {
    text     => $self->{bot}{lang}{LIQPAY_PAYMENT},
    url      => $paysys_link->{URL} || ""
  };
  push (@inline_keyboard, [$inline_button]);

  $self->{bot}->send_message({
    text         => $message,
    reply_markup => { inline_keyboard => \@inline_keyboard },
    parse_mode   => 'HTML'
  });

  return 1;
}

1;
