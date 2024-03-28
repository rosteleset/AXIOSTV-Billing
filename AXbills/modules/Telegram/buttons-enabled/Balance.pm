package Balance;

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
  
  return $self->{bot}->{lang}->{DEPOSIT};
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

  use Fees;
  my $Fees = Fees->new($self->{db}, $self->{admin}, $self->{conf});
  my $last_fees = $Fees->list({
    DATETIME  => '_SHOW',
    SUM       => '_SHOW',
    DESCRIBE  => '_SHOW',
    UID       => $uid,
    DESC      => 'desc',
    SORT      => 1,
    PAGE_ROWS => 1,
    COLS_NAME => 1
  });

  my $message = sprintf("$self->{bot}->{lang}->{YOUR_DEPOSIT}: %.2f\n", $Users->{DEPOSIT});
  $message .= " $money_currency\n";
  $message .= "$self->{bot}->{lang}->{CREDIT}: $Users->{CREDIT} $money_currency\n" if ($Users->{CREDIT} && $Users->{CREDIT} > 0);
  $message .= "$self->{bot}->{lang}->{CREDIT_OPEN}: $Users->{CREDIT_DATE}\n" if ($Users->{CREDIT_DATE} && $Users->{CREDIT_DATE} ne '0000-00-00');
  $message .= "\n";

  if ($last_payments) {
    $message .= "$self->{bot}->{lang}->{LAST_PAYMENT}:\n";
    $message .= sprintf("$self->{bot}->{lang}->{SUM}: %.2f", $last_payments->[0]->{sum}) if ($last_payments->[0]->{sum});
    $message .= " $money_currency\n" if ($last_payments->[0]->{sum});
    $message .= "$self->{bot}->{lang}->{DATE}: $last_payments->[0]->{datetime}\n" if ($last_payments->[0]->{datetime});
    $message .= "$self->{bot}->{lang}->{DESCRIBE}: $last_payments->[0]->{describe}\n" if ($last_payments->[0]->{describe});
    $message .= "\n";
  }
  
  if ($last_fees) {
    $message .= "$self->{bot}->{lang}->{LAST_FEES}:\n";
    $message .= sprintf("$self->{bot}->{lang}->{SUM}: %.2f", $last_fees->[0]->{sum}) if ($last_fees->[0]->{sum});
    $message .= " $money_currency\n" if ($last_fees->[0]->{sum});
    $message .= "$self->{bot}->{lang}->{DATE}: $last_fees->[0]->{datetime}\n" if ($last_fees->[0]->{datetime});
    $message .= "$self->{bot}->{lang}->{DESCRIBE }: $last_fees->[0]->{describe}\n" if ($last_fees->[0]->{describe});
  }
  $self->{bot}->send_message({
    text         => $message,
  }); 

  return 1;
}

1;