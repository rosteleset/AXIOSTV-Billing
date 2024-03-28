package User_info;

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
  
  return $self->{bot}->{lang}->{ACCOUNT};
}

#**********************************************************
=head2 click()

=cut
#**********************************************************
sub click {
  my $self = shift;
  my ($attr) = @_;

  my $uid = $self->{bot}->{uid};

  use Users;
  my $Users = Users->new($self->{db}, $self->{admin}, $self->{conf});
  
  $Users->info($uid, {SHOW_PASSWORD => 1});
  $Users->pi({UID => $uid});
  
  my $message = "$self->{bot}->{lang}->{WELLCOME}, $Users->{FIO}\n\n";
  $message .= sprintf("$self->{bot}->{lang}->{DEPOSIT}: %.2f\n", $Users->{DEPOSIT});

  if ($Users->{CELL_PHONE}) {
    $message .= "$self->{bot}->{lang}->{YOUR_PHONE_CELL}: $Users->{CELL_PHONE}\n";
  }
  if($Users->{CONTRACT_ID}){
    $message .= "$self->{bot}->{lang}->{CONTRACT_ID}: $Users->{CONTRACT_ID}\n";
  }
  if ($Users->{PHONE_ALL}) {
    $message .= "$self->{bot}->{lang}->{YOUR_PHONE}: $Users->{PHONE_ALL}\n";
  }

  if ($Users->{EMAIL}) {
    $message .= "$self->{bot}->{lang}->{EMAIL}: $Users->{EMAIL}\n";
  }

  $message .= "$self->{bot}->{lang}->{LOGIN}: $Users->{LOGIN}\n";
  $message .= "$self->{bot}->{lang}->{PASSWORD}: $Users->{PASSWORD}\n";

  $self->{bot}->send_message({
    text => $message,
  });

  return 1;
}

1;
