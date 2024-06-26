package Unsubscribe;

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
  
  return $self->{bot}->{lang}->{DISABLE_MSGS};
}

#**********************************************************
=head2 click()

=cut
#**********************************************************
sub click {
  my $self = shift;
  my ($attr) = @_;
  $self->{bot}->send_message({
    text         => "TODO:Отписаться",
  }); 

  return 1;
}

1;