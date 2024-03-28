package Equipment_info;

use strict;
use warnings FATAL => 'all';
use AXbills::Fetcher qw(web_request);

my %icons = (
  not_active => "\xE2\x9D\x8C",
  active     => "\xE2\x9C\x85",
);

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

  return $self->{bot}{lang}{EQUIPMENT_CONNECTION_CHECK};
}

#**********************************************************
=head2 click()

=cut
#**********************************************************
sub click {
  my $self = shift;
  my ($attr) = @_;

  my $uid = $self->{bot}->{uid};

  $self->{bot}->send_message({
    text   => $self->{bot}{lang}{EQUIPMENT_WAIT},
    type   => 'text',
    sender => { name => 'AXbills bot' }
  });

  use AXbills::HTML;
  my $html = AXbills::HTML->new({ CONF => $self->{conf} });
  my $custom_error_text = $html->tpl_show(main::_include('viber_equipment_info_error', 'Viber'), {}, { OUTPUT2RETURN => 1 });

  my $result = $self->fetch_api({
    method => 'GET',
    url   => ($self->{conf}->{API_URL} || '') . '/api.cgi/user/equipment/'
  });

  if ($result && ref $result eq 'HASH') {
    if ($result->{errno}) {
      $self->{bot}->send_message({
        text   => $self->{bot}{lang}{EQUIPMENT_ERROR},
        type   => 'text',
        sender => { name => 'AXbills bot' }
      });
      return 1;
    }

    my $id = (keys %{$result})[0];
    if (!$id) {
      $self->{bot}->send_message({
        text   => $self->{bot}{lang}{EQUIPMENT_ERROR},
        type   => 'text',
        sender => { name => 'AXbills bot' }
      });
      return 1;
    }

    my $equipment_info = $result->{$id};

    if (!defined($equipment_info->{status}) || $equipment_info->{status} ne '1') {
      $self->{bot}->send_message({
        text   => "$icons{not_active} $self->{bot}{lang}{EQUIPMENT_OPTICAL_TERMINAL_NOT_WORKING}",
        type   => 'text',
        sender => { name => 'AXbills bot' }
      });
      if ($custom_error_text) {
        $self->{bot}->send_message({ text => $custom_error_text, type => 'text', sender => { name => 'AXbills bot' } });
      }
      return 1;
    }

    $self->{bot}->send_message({
      text   => "$icons{active} $self->{bot}{lang}{EQUIPMENT_OPTICAL_TERMINAL_WORKING}",
      type   => 'text',
      sender => { name => 'AXbills bot' }
    });

    $equipment_info->{onu_ports_status} //= $equipment_info->{onuPortsStatus};
    if (defined $equipment_info->{onu_ports_status}) {
      my @ports_status = split(/\n/, $equipment_info->{onu_ports_status});
      my $port_info = pop @ports_status;
      my ($port, $status) = split(/ /, $port_info);
      $status //= 0;

      if (!$status || $status != 1) {
        $self->{bot}->send_message({
          text   => "$icons{not_active} $self->{bot}{lang}{EQUIPMENT_ROUTER_NOT_WORKING}",
          type   => 'text',
          sender => { name => 'AXbills bot' }
        });
        if ($custom_error_text) {
          $self->{bot}->send_message({ text => $custom_error_text, type => 'text', sender => { name => 'AXbills bot' } });
        }
        return 1;
      }
      $self->{bot}->send_message({
        text   => "$icons{active} $self->{bot}{lang}{EQUIPMENT_ROUTER_WORKING}",
        type   => 'text',
        sender => { name => 'AXbills bot' }
      });
    }

    $self->{bot}->send_message({
      text   => $self->{bot}{lang}{EQUIPMENT_CHECK_COMPLETED},
      type   => 'text',
      sender => { name => 'AXbills bot' }
    });
    return 1;
  }

  $self->{bot}->send_message({
    text   => $self->{bot}{lang}{EQUIPMENT_ERROR},
    type   => 'text',
    sender => { name => 'AXbills bot' }
  });
  if ($custom_error_text) {
    $self->{bot}->send_message({ text => $custom_error_text, type => 'text', sender => { name => 'AXbills bot' } });
  }

  return 1;
}

#**********************************************************
=head2 fetch_api($attr)

=cut
#**********************************************************
sub fetch_api {
  my $self = shift;
  my ($attr) = @_;

  return {} if !$self->{bot} || !$self->{bot}{receiver};
  my @req_headers = ('Content-Type: application/json', 'USERBOT: VIBER', "USERID: $self->{bot}{receiver}");
  my $req_body = q{};

  if ($attr->{method} ne 'GET') {
    $req_body = $attr->{body};
  }

  my $result = web_request($attr->{url}, {
    HEADERS     => \@req_headers,
    JSON_BODY   => $req_body,
    JSON_RETURN => 1,
    INSECURE    => 1,
    METHOD      => $attr->{method}
  });

  return $result;
}

1;
