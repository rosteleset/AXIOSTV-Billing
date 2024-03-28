package Paysys_pay;

use strict;
use warnings FATAL => 'all';

use AXbills::Fetcher qw(web_request);

#**********************************************************
=head2 new()

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

  my $systems = $self->{bot}->fetch_api({
    method => 'GET',
    url   => ($self->{conf}->{API_URL} || '') . '/api.cgi/user/1/paysys/systems/'
  });

  if ($systems && ref $systems eq 'ARRAY') {
    my @buttons = ();
    foreach my $system (@{$systems}) {
      push @buttons,
        {
          ActionBody  => "fn:Paysys_pay&fastpay_link&$system->{id}",
          ActionType  => 'reply',
          BgMediaType => 'picture',
          Image       => "$self->{conf}->{API_URL}/styles/default/img/paysys_logo/" . lc($system->{name}) . "-logo.png",
          Rows        => 5,
          Columns     => 6
        },
        {
          Columns    => 6,
          Rows       => 2,
          Text       => "<font color=#ffffff> Перейти на швидку оплату $system->{name}</font>",
          ActionType => 'reply',
          ActionBody => "fn:Paysys_pay&fastpay_link&$system->{id}",
          TextSize   => 'large',
          TextVAlign => 'middle',
          TextHAlign => 'middle',
          BgColor    => '#7360f2',
        };
    }

    $self->{bot}->send_message({
      type       => 'rich_media',
      rich_media => {
        Type                => 'rich_media',
        ButtonsGroupColumns => 6,
        ButtonsGroupRows    => 7,
        BgColor             => '#FFFFFF',
        Buttons             => \@buttons
      }
    });
  }
  else {
    $self->{bot}->send_message({
      text => $self->{bot}->{lang}->{NO_PAYMENT_SYSTEMS},
      type => 'text',
    });
  }

  return 1;
}

#**********************************************************
=head2 fastpay_link()

=cut
#**********************************************************
sub fastpay_link {
  my $self = shift;
  my ($attr) = @_;

  my $response = $self->{bot}->fetch_api({
    method => 'POST',
    url    => ($self->{conf}->{API_URL} || '') . '/api.cgi/user/1/paysys/pay/',
    body   => {
      systemId => $attr->{argv}->[0]
    }
  });

  if ($response && $response->{errno}) {
    my $error = $response->{errno} || '999';
    $self->{bot}->send_message({
      text => "ERROR $error",
      type => 'text',
    });
  }
  else {
    $self->{bot}->send_message({
      text => "$response->{url}",
      type => 'text',
    });
  }

  return 'MAIN_MENU';
}

1;
