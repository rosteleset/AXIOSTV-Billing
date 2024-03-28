package Isp_info;

use strict;
use warnings FATAL => 'all';
use Conf;

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

  return $self->{bot}->{lang}->{ABOUT};
}

#**********************************************************
=head2 click()

=cut
#**********************************************************
sub click {
  my $self = shift;

  my $Conf = Conf->new($self->{db}, $self->{admin}, $self->{conf});

  my $message = "";
  $message .= "$self->{bot}->{lang}->{COMPANY_NAME}: $Conf->{conf}->{ORGANIZATION_NAME}\n" if ($Conf->{conf}->{ORGANIZATION_NAME});
  $message .= "$self->{bot}->{lang}->{ADDRESS}: $Conf->{conf}->{ORGANIZATION_ADDRESS}\n" if ($Conf->{conf}->{ORGANIZATION_ADDRESS});
  $message .= "$self->{bot}->{lang}->{PHONE}: $Conf->{conf}->{ORGANIZATION_PHONE}\n" if ($Conf->{conf}->{ORGANIZATION_PHONE});
  $message .= "$self->{bot}->{lang}->{EMAIL}: $Conf->{conf}->{ORGANIZATION_MAIL}\n" if ($Conf->{conf}->{ORGANIZATION_MAIL});
  $message .= "$self->{bot}->{lang}->{WEB_SITE}: $Conf->{conf}->{ORGANIZATION_WEB_SITE}\n" if ($Conf->{conf}->{ORGANIZATION_WEB_SITE});

  $self->{bot}->send_message({
    text         => $message,
  });

  return 1;
}

1;
