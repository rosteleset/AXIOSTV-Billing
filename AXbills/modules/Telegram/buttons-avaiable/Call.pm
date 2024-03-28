package Call;

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

  return $self->{bot}->{lang}->{CONTACT_SUPPORT};
}

#**********************************************************
=head2 click()

=cut
#**********************************************************
sub click {
  my $self = shift;
  my ($attr) = @_;

  my @inline_keyboard = ();

  if ($self->{conf}->{TELEGRAM_SUPPORT_PHONE}) {
    my $inline_button = {
      text          => "$self->{bot}->{lang}->{CONTACT_SUPPORT}",
      callback_data => "Call&contact"
    };

    push (@inline_keyboard, [$inline_button]);
  }

  if ($self->{conf}->{TELEGRAM_SITE}) {
    my $inline_button = {
      text          => "$self->{bot}->{lang}->{SITE}",
      url           => "$self->{conf}->{TELEGRAM_SITE}"
    };

    push (@inline_keyboard, [$inline_button]);
  }

  if ($self->{conf}->{TELEGRAM_LINK_URL}) {
    my $link_url = $self->{conf}->{TELEGRAM_LINK_URL};
    my @links = split(/;/, $link_url);

    foreach my $link (@links) {
      my ($name, $url) = split(/\|/, $link);
      my $inline_button = {
        text          => $name,
        url           => $url
      };

      push (@inline_keyboard, [$inline_button]);
    }
  }

  if ($self->{conf}->{TELEGRAM_CHANEL}) {
    my $inline_button = {
      text          => "$self->{bot}->{lang}->{CANAL}",
      url           => $self->{conf}->{TELEGRAM_CHANEL}
    };

    push (@inline_keyboard, [$inline_button]);
  }
  
  $self->{bot}->send_message({
    text         => "$self->{bot}->{lang}->{CUSTOMER_SUPPORT}",
    reply_markup => {
      inline_keyboard => \@inline_keyboard
    },
    parse_mode   => 'HTML'
  }); 

  return 1;
}

#**********************************************************
=head2 contact()

=cut
#**********************************************************
sub contact {
  my $self = shift;
  my ($attr) = @_;

  my $contact = $self->{conf}->{TELEGRAM_SUPPORT_PHONE};
  my @contacts = split(/;/, $contact);

  foreach my $number (@contacts) {
    my ($first_name, $call_number) = split(/\|/, $number);
    $self->{bot}->send_contact({
      first_name   => "$self->{bot}->{lang}->{TECH_NUMBER} ($first_name)",
      phone_number => $call_number,
    }); 
  }

  return 1;
}

1;