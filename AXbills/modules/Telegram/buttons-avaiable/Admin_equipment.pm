package Admin_equipment;

use strict;
use warnings FATAL => 'all';
use AXbills::Base qw(in_array int2ip);

my $Equipment;
my %icons = (
  line        => "\xE2\x9E\x96",
  wave_line   => "\xE3\x80\xB0",
  equipment   => "\xE2\x9A\x99",
  not_active  => "\xE2\x9D\x8C",
  active      => "\xE2\x9C\x85",
  number_1    => "\x31\xEF\xB8\x8F\xE2\x83\xA3",
  number_2    => "\x32\xEF\xB8\x8F\xE2\x83\xA3",
  number_3    => "\x33\xEF\xB8\x8F\xE2\x83\xA3",
  number_4    => "\x34\xEF\xB8\x8F\xE2\x83\xA3",
  number_5    => "\x35\xEF\xB8\x8F\xE2\x83\xA3",
  right_arrow => "\xE2\x9E\xA1",
  danger      => "\xE2\x9A\xA0",
  search      => "\xF0\x9F\x94\x8D",
);

my %ONU_STATUS_CODE_TO_TEXT = (
  0    => "Offline $icons{not_active}",
  1    => "Online $icons{active}",
  2    => "Authenticated $icons{active}",
  3    => "Registered $icons{active}",
  4    => "Deregistered $icons{not_active}",
  5    => "Auto_config $icons{active}",
  6    => "Unknown $icons{danger}",
  7    => "LOS $icons{not_active}",
  8    => "Synchronization $icons{not_active}",
  9    => "Dying_gasp $icons{not_active}",
  10   => "Power_Off $icons{danger}",
  11   => 'Pending',
  12   => 'Allocated',
  13   => 'Auth in progress',
  14   => 'Cfg in progress',
  15   => 'Auth failed',
  16   => 'Cfg failed',
  17   => 'Report timeout',
  18   => 'Auth ok',
  19   => 'Reset in progress',
  20   => 'Reset ok',
  21   => 'Discovered',
  22   => 'Blocked',
  23   => 'Check new fw',
  24   => 'Unidentified',
  25   => 'Unconfigured',
  26   => 'Failed',
  27   => 'Mibreset',
  28   => 'Preconfig',
  29   => 'Fw updating',
  30   => 'Unactivated',
  31   => 'Redundant',
  32   => 'Disabled',
  33   => 'Lost',
  34   => 'Standby',
  35   => 'Inactive',
  1000 => "Not expected status $icons{danger}",
);

my @service_status = ();

#**********************************************************
=head2 new()

=cut
#**********************************************************
sub new {
  my $class = shift;
  my ($db, $admin, $conf, $bot) = @_;

  my $self = {
    db         => $db,
    admin      => $admin,
    conf       => $conf,
    bot        => $bot,
    for_admins => 1,
    last_page  => 1
  };

  bless($self, $class);

  require Equipment;
  Equipment->import();
  $Equipment = Equipment->new($db, $admin, $conf);

  @service_status = ($self->{bot}{lang}{ENABLE}, $self->{bot}{lang}{DISABLE}, $self->{bot}{lang}{NOT_ACTIVE},
    $self->{bot}{lang}{ERROR}, $self->{bot}{lang}{BREAKING}, $self->{bot}{lang}{NOT_MONITORING});

  return $self;
}

#**********************************************************
=head2 btn_name()

=cut
#**********************************************************
sub btn_name {
  my $self = shift;

  return $self->{bot}{lang}{EQUIPMENT};
}

#**********************************************************
=head2 click()

=cut
#**********************************************************
sub click {
  my $self = shift;
  my ($attr) = @_;

  my $page = $attr->{argv}[2];
  my @inline_keyboard = ();
  my @equipment_buttons = ();
  my $message = "<b>$self->{bot}{lang}{EQUIPMENT}</b>\n\n" . $self->_equipments_list($page, \@equipment_buttons);

  push @inline_keyboard, \@equipment_buttons;
  push @inline_keyboard, _get_page_range($page, $self->{last_page}, 'click');

  $self->_send_message($message, $page, \@inline_keyboard, $attr);

  return 1;
}

#**********************************************************
=head2 equipment_ports($attr)

=cut
#**********************************************************
sub equipment_ports {
  my $self = shift;
  my ($attr) = @_;

  my $nas_id = $attr->{argv}[2] || '';
  my $page = $attr->{argv}[3];
  return if !$nas_id;

  my $equipments = $Equipment->_list({
    NAS_ID    => $nas_id,
    TYPE_ID   => '_SHOW',
    NAS_NAME  => '_SHOW',
    PAGE_ROWS => 1,
    COLS_NAME => 1
  });

  return if $Equipment->{TOTAL} != 1;
  my $equipment_info = $equipments->[0];

  my @inline_keyboard = ();
  my @ports_buttons = ();
  my $message = "<b>$self->{bot}{lang}{EQUIPMENT}: $equipment_info->{nas_name}</b>\n\n";

  $message .= $equipment_info->{type_id} eq '4' ? $self->_pon_ports_list($page, $nas_id, \@ports_buttons) : '';

  push @inline_keyboard, \@ports_buttons;
  push @inline_keyboard, _get_page_range($page, $self->{last_page}, "equipment_ports&$nas_id");

  $self->_send_message($message, $page, \@inline_keyboard, $attr);
}

#**********************************************************
=head2 equipment_onu($attr)

=cut
#**********************************************************
sub equipment_onu {
  my $self = shift;
  my ($attr) = @_;

  my $port_id = $attr->{argv}[2] || '';
  my $page = $attr->{argv}[3];
  return if !$port_id;

  my $message = "<b>ONU:</b>\n\n" . $self->_onu_list($page, $port_id);
  my @inline_keyboard = ();

  push @inline_keyboard, _get_page_range($page, $self->{last_page}, "equipment_onu&$port_id");

  $self->_send_message($message, $page, \@inline_keyboard, $attr);
}


#**********************************************************
=head2 search($attr)

=cut
#**********************************************************
sub search {
  my $self = shift;
  my ($attr) = @_;

  my $search = $attr->{argv}[2] || '';
  my $page = $attr->{argv}[3] || 0;
  my $search_text = "$icons{search} <b>$self->{bot}{lang}{SEARCH}: $search</b>\n\n";
  my @info = ();
  my @equipment_buttons = ();
  my @inline_keyboard = ();
  my $total = 0;

  my $equipment_result = $self->_equipment_search($page, $search, \@equipment_buttons);
  if ($equipment_result) {
    push @info, $equipment_result;
    $total = $Equipment->{TOTAL};
    $search_text .= "$self->{bot}{lang}{TELEGRAM_FOUND} <b>$self->{bot}{lang}{EQUIPMENT}: $Equipment->{TOTAL}</b>\n";
    push @inline_keyboard, \@equipment_buttons;
  }

  my $onu_result = $self->_onu_search($page, $search, []);
  if ($onu_result) {
    push @info, $onu_result;
    $search_text .= "$self->{bot}{lang}{TELEGRAM_FOUND} <b>ONU: $Equipment->{TOTAL}</b>\n\n";
    $total = $Equipment->{TOTAL} if $total < $Equipment->{TOTAL};
  }

  $search_text .= join("\n" . $icons{line} x 9 . "\n\n", @info);

  my $last_page = $total > 5 ? int($total/ 5) + ($total % 5 == 0 ? 0 : 1) : 0;
  push @inline_keyboard, _get_page_range($page, $last_page, "search&$search");
  $self->_send_message($search_text, $page, \@inline_keyboard, $attr);
}

#**********************************************************
=head2 _equipment_search($page, $search, $buttons)

=cut
#**********************************************************
sub _equipment_search {
  my $self = shift;
  my ($page, $search, $buttons) = @_;

  my $equipment_result = $self->_equipments_list($page, $buttons, {
    NAS_NAME   => "*$search*",
    MAC        => "*$search*",
    NAS_IP     => "*$search*",
    _MULTI_HIT => 1
  });

  if ($equipment_result) {
    unshift @{$buttons}, {
      text          => $self->{bot}{lang}{EQUIPMENT} . ':',
      callback_data => " "
    };
    $equipment_result = "<b>$self->{bot}{lang}{EQUIPMENT}:</b>\n\n" . $equipment_result;
  }

  return $equipment_result;
}

#**********************************************************
=head2 _onu_search($page, $search, $buttons)

=cut
#**********************************************************
sub _onu_search {
  my $self = shift;
  my ($page, $search, $buttons) = @_;

  my $onu_result = $self->_onu_list($page, '_SHOW', {
    ONU_DESC      => "*$search*",
    MAC_SERIAL    => "*$search*",
    ONU_DHCP_PORT => "*$search*",
    SKIP_ICON     => 1,
    _MULTI_HIT    => 1
  });

  if ($onu_result) {
    $onu_result = "<b>ONU:</b>\n\n" . $onu_result;
  }

  return $onu_result;
}

#**********************************************************
=head2 _onu_list($page, $port_id, $attr)

=cut
#**********************************************************
sub _onu_list {
  my $self = shift;
  my ($page, $port_id, $attr) = @_;

  my $message = '';
  my @info = ();

  my $onus = $Equipment->onu_list({
    OLT_PORT   => $port_id,
    TYPE_ID    => '_SHOW',
    RX_POWER   => '_SHOW',
    NAS_NAME   => '_SHOW',
    ONU_DESC   => '_SHOW',
    STATUS     => '_SHOW',
    FIO        => '_SHOW',
    MAC_SERIAL => '_SHOW',
    PAGE_ROWS  => 5,
    PG         => $page ? (($page - 1) * 5) : 0,
    SORT       => 'dhcp_port',
    %{ $attr // {} },
    COLS_NAME  => 1
  });
  $self->{last_page} = int($Equipment->{TOTAL} / 5) + ($Equipment->{TOTAL} % 5 == 0 ? 0 : 1) if $Equipment->{TOTAL} > 5;

  my $number = 1;
  foreach my $onu (@{$onus}) {
    my $icon = $attr && $attr->{SKIP_ICON} ? '' : $icons{"number_" . $number++} || '';
    my $status = $ONU_STATUS_CODE_TO_TEXT{$onu->{status}} || '';

    $onu->{mac_serial} ||= '';
    $onu->{onu_desc} ||= '';
    $onu->{fio} ||= '';
    my $onu_info = "$icon <i>$onu->{dhcp_port}</i>\n";
    $onu_info .= "<b>$self->{bot}{lang}{ONU_STATUS}</b>: $status\n";
    $onu_info .= "<b>MAC</b>: $onu->{mac_serial}\n";
    $onu_info .= "<b>RX Power</b>: $onu->{rx_power} " . _onu_state($onu->{rx_power}) . "\n";
    $onu_info .= "<b>$self->{bot}{lang}{DESCRIBE}</b>: $onu->{onu_desc}\n";
    $onu_info .= "<b>$self->{bot}{lang}{USER}</b>: $onu->{fio}\n";
    $onu_info .= "<b>$self->{bot}{lang}{EQUIPMENT}</b>: $onu->{nas_name}\n";
    push(@info, $onu_info);
  }
  $message .= join($icons{line} x 9 . "\n", @info);

  return $message;
}

#**********************************************************
=head2 _equipments_list($page)

=cut
#**********************************************************
sub _equipments_list {
  my $self = shift;
  my $page = shift;
  my ($equipment_buttons, $attr) = @_;

  my $message = '';
  my @info = ();

  my $equipments = $Equipment->_list({
    NAS_IP       => '_SHOW',
    STATUS       => '_SHOW',
    NAS_NAME     => '_SHOW',
    MAC          => '_SHOW',
    NAS_IP       => '_SHOW',
    ADDRESS_FULL => '_SHOW',
    PAGE_ROWS    => 5,
    PG           => $page ? (($page - 1) * 5) : 0,
    %{$attr // {}},
    COLS_NAME    => 1
  });

  $self->{last_page} = int($Equipment->{TOTAL} / 5) + ($Equipment->{TOTAL} % 5 == 0 ? 0 : 1) if $Equipment->{TOTAL} > 5;

  my $number = 1;
  foreach my $equipment (@{$equipments}) {
    my $icon = $icons{"number_" . $number++} || '';
    my $status = $service_status[$equipment->{status}] || $service_status[3];
    $status .= ' ' . $icons{$equipment->{status} ? 'not_active' : 'active'};

    $equipment->{address_full} ||= '';
    $equipment->{mac} ||= '';
    my $equipment_info = "$icon <i>$equipment->{nas_name}</i>\n";
    $equipment_info .= "<b>IP</b>: $equipment->{nas_ip}\n";
    $equipment_info .= "<b>MAC</b>: $equipment->{mac}\n";
    $equipment_info .= "<b>$self->{bot}{lang}{STATUS}</b>: $status\n";
    $equipment_info .= "<b>$self->{bot}{lang}{ADDRESS}</b>: $equipment->{address_full}\n";
    push(@info, $equipment_info);
    push(@{$equipment_buttons}, {
      text          => $icon,
      callback_data => "Admin_equipment&equipment_ports&$equipment->{nas_id}"
    });
  }

  $message .= join($icons{line} x 9 . "\n", @info);

  return $message;
}

#**********************************************************
=head2 _pon_ports_list($page)

=cut
#**********************************************************
sub _pon_ports_list {
  my $self = shift;
  my ($page, $nas_id, $ports_buttons) = @_;

  my $message = "<b>$self->{bot}{lang}{PORTS}:</b>\n\n";
  my $ports = $Equipment->pon_port_list({
    NAS_ID    => $nas_id,
    ONU_COUNT => '_SHOW',
    PAGE_ROWS => 5,
    PG        => $page ? (($page - 1) * 5) : 0,
    SORT      => 'p.snmp_id',
    COLS_NAME => 1
  });
  $self->{last_page} = int($Equipment->{TOTAL} / 5) + ($Equipment->{TOTAL} % 5 == 0 ? 0 : 1) if $Equipment->{TOTAL} > 5;

  my @info = ();
  my $number = 1;
  foreach my $port (@{$ports}) {
    my $icon = $icons{"number_" . $number++} || '';
    $port->{onu_count} ||= 0;

    my $port_info = "$icon <b>$port->{branch}</b>\n";
    $port_info .= "<b>$self->{bot}{lang}{DESCRIBE}</b>: $port->{branch_desc}\n";
    $port_info .= "<b>$self->{bot}{lang}{ONU_COUNT}</b>: $port->{onu_count}\n";

    push(@info, $port_info);
    push(@{$ports_buttons}, {
      text          => $icon,
      callback_data => "Admin_equipment&equipment_onu&$port->{id}"
    });
  }
  $message .= join($icons{line} x 9 . "\n", @info);

  return $message;
}

#**********************************************************
=head2 _onu_state($rx_power)

=cut
#**********************************************************
sub _onu_state {
  my $rx_power = shift;

  return '' if (!$rx_power || $rx_power == 65535 || $rx_power > 0);
  return $icons{active} if ($rx_power < -8 && $rx_power > -27);
  return $icons{danger} if ($rx_power < -8 && $rx_power > -30);

  return '';
}

#**********************************************************
=head2 _send_message($message, $page, $inline_keyboard, $attr)

=cut
#**********************************************************
sub _send_message {
  my $self = shift;
  my ($message, $page, $inline_keyboard, $attr) = @_;

  push @{$inline_keyboard}, [ {
    text                             => $icons{search} . ' ' . $self->{bot}{lang}{SEARCH},
    switch_inline_query_current_chat => "/equipment "
  } ];

  if ($page) {
    $self->{bot}->edit_message_text({
      text       => $message,
      message_id => $attr->{message_id},
      reply_markup => {
        inline_keyboard => $inline_keyboard,
        resize_keyboard => "true",
      },
      parse_mode => 'HTML'
    });
    return 1;
  }

  $self->{bot}->send_message({
    text       => $message,
    reply_markup => {
      inline_keyboard => $inline_keyboard,
      resize_keyboard => "true",
    },
    parse_mode => 'HTML'
  });
}

#**********************************************************
=head2 _get_page_range($page, $last_page, $path)

=cut
#**********************************************************
sub _get_page_range {
  my ($page, $last_page, $path) = @_;

  return [] if $last_page < 2;

  my @row = ();
  my @range = $last_page < 5 ? (1 .. $last_page) : (!$page || $page < 4) ? (1 .. 4, $last_page) :
    ($page + 2 < $last_page) ? (1, $page - 1 .. $page + 1, $last_page) : (1, $last_page - 3 .. $last_page);

  for (@range) {
    push @row, {
      text          => (!$page && $_ eq '1') || ($page && $page eq $_) ? "$icons{right_arrow} $_" : $_,
      callback_data => "Admin_equipment&$path&$_"
    }
  }

  return \@row;
}

1;