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

  if ($self->{conf}->{VIBER_SUPPORT_PHONE}) {
    my $inline_button = {
        ActionType => 'reply',
        ActionBody => "fn:Call&contact",
        Text       => $self->{bot}->{lang}->{CONTACT_SUPPORT},
        TextSize   => 'regular'
    };

    push (@inline_keyboard, $inline_button);
  }

  if ($self->{conf}->{VIBER_SITE}) {
    my $inline_button = {
      ActionType => 'open-url',
      ActionBody => $self->{conf}->{VIBER_SITE},
      Text       => $self->{bot}->{lang}->{SITE},
      TextSize   => 'regular'
    };

    push (@inline_keyboard, $inline_button);
  }

  if ($self->{conf}->{VIBER_LINK_URL}) {
    my $link_url = $self->{conf}->{VIBER_LINK_URL};
    my @links = split(/;/, $link_url);

    foreach my $link (@links) {
      my ($name, $url) = split(/\|/, $link);
      my $inline_button = {
        ActionType => 'open-url',
        ActionBody => $url,
        Text       => $name,
        TextSize   => 'regular'
      };

      push (@inline_keyboard, $inline_button);
    }
  }

  if ($self->{conf}->{TELEGRAM_CHANEL}) {
    my $inline_button = {
      ActionType => 'open-url',
        ActionBody => $self->{conf}->{VIBER_CHANEL},
        Text       => $self->{bot}->{lang}->{CANAL},
        TextSize   => 'regular'
    };

    push (@inline_keyboard, $inline_button);
  }

  my $inline_button = {
    ActionType => 'reply',
    ActionBody => 'MENU',
    Text       => $self->{bot}->{lang}->{BACK},
    BgColor    => "#FF0000",
    TextSize   => 'regular'
  };
  push (@inline_keyboard, $inline_button);

  my $message = {
      keyboard => {
        Type          => 'keyboard',
        DefaultHeight => "true",
        Buttons => \@inline_keyboard
      }
  };


  $message->{text} = "$self->{bot}->{lang}->{CUSTOMER_SUPPORT}" if(!$attr->{NO_MSG});
  $message->{type} = 'text' if(!$attr->{NO_MSG});

  $self->{bot}->send_message($message);

  return "NO_MENU";
}

#**********************************************************
=head2 contact()

=cut
#**********************************************************
sub contact {
  my $self = shift;
  my ($attr) = @_;

  my $contact = $self->{conf}->{VIBER_SUPPORT_PHONE};
  my @contacts = split(/;/, $contact);

  foreach my $number (@contacts) {
    my ($first_name, $call_number) = split(/\|/, $number);
    $self->{bot}->send_message({
      type => 'contact',
      sender => {
        name => 'AXbills bot',
      },
      contact => {
        name   => "$self->{bot}->{lang}->{TECH_NUMBER} ($first_name)",
        phone_number => $call_number,
      }
    }); 
  }

  return 1;
}

1;