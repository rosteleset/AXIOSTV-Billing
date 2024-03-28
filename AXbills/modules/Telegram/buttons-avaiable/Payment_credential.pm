package Payment_credential;

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

  return $self->{bot}->{lang}->{PAYMENT_CREDENTIAL};
}

#**********************************************************
=head2 click()

=cut
#**********************************************************
sub click {
  my $self = shift;
  my ($attr) = @_;

  return 0 unless ($self->{conf}->{TELEGRAM_PAYMENT_CREDENTIAL});

  my $message = "$self->{bot}->{lang}->{PAYMENT_CREDENTIAL}:\n$self->{conf}->{TELEGRAM_PAYMENT_CREDENTIAL}";

  $self->{bot}->send_message({
    text => $message,
  });

  return 1;
}

1;