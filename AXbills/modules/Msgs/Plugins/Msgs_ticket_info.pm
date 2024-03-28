package Msgs::Plugins::Msgs_ticket_info;

use strict;
use warnings FATAL => 'all';

my ($admin, $CONF, $db, $msgs_permissions);
my $json;
my AXbills::HTML $html;
my $lang;
my $Msgs;

use AXbills::Base qw/in_array/;

require Users;
Users->import();
my $users;

#**********************************************************
=head2 new($html, $lang)

=cut
#**********************************************************
sub new {
  my $class = shift;
  $db = shift;
  $admin = shift;
  $CONF = shift;
  my $attr = shift;

  $html = $attr->{HTML} if $attr->{HTML};
  $lang = $attr->{LANG} if $attr->{LANG};
  $msgs_permissions = $attr->{MSGS_PERMISSIONS};

  my $self = {
    MODULE      => 'Msgs',
    PLUGIN_NAME => 'Msgs_ticket_info'
  };

  if ($attr->{MSGS}) {
    $Msgs = $attr->{MSGS};
  }
  else {
    require Msgs;
    Msgs->import();
    $Msgs = Msgs->new($db, $admin, $CONF);
  }

  $users = Users->new($db, $admin, $CONF);

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 plugin_info()

=cut
#**********************************************************
sub plugin_info {
  return {
    NAME     => "Ticket main info",
    POSITION => 'RIGHT',
    DESCR    => $lang->{TICKET_MAIN_INFO}
  };
}

#**********************************************************
=head2 plugin_show($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub plugin_show {
  my $self = shift;
  my ($attr) = @_;

  if ($attr->{ping}) {
    ::host_diagnostic($attr->{ping});
    return { RETURN_VALUE => 1 };
  }

  my $info = $self->_get_main_info($attr);

  $info .= $self->_get_responsible_select($attr);
  $info .= $self->_get_priority_select($attr);
  $info .= $self->_get_watchers_select($attr);
  # $info .= $self->_get_plan_date_input($attr);

  return $info;
}

#**********************************************************
=head2 _get_main_info($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub _get_main_info {
  my $self = shift;
  my ($attr) = @_;

  return '' if !$attr->{UID};

  my $user_info = $users->info($attr->{UID});
  my $user_pi = $users->pi({ UID => $attr->{UID} });
  $user_pi->{CELL_PHONE_ALL} ||= '';
  $user_pi->{PHONE_ALL} ||= '';
  $user_pi->{FIO} ||= '';

  $user_pi->{ADDRESS_STREET} ||= '';
  $user_pi->{ADDRESS_BUILD} ||= '';
  $user_pi->{ADDRESS_FLAT} ||= '';

  my $build_delimiter = $CONF->{BUILD_DELIMITER} || ', ';
  my $home = $html->element('p', "<b>$lang->{ADDRESS}:</b> $user_pi->{ADDRESS_STREET}$build_delimiter$user_pi->{ADDRESS_BUILD}$build_delimiter$user_pi->{ADDRESS_FLAT}", {
    class => 'form-control-static',
    title => $lang->{ADDRESS}
  });

  my $user_phones = join(', ', ($user_pi->{CELL_PHONE_ALL}, $user_pi->{PHONE_ALL}));
  my $phone = $html->element('p', "<b>$lang->{PHONE}:</b> $user_phones", {
    class          => 'form-control-static',
    title          => $lang->{PHONE},
    'data-visible' => $lang->{PHONE}
  });

  my $fio = $html->element('p', "<b>$lang->{FIO}:</b> $user_pi->{FIO}", {
    class          => 'form-control-static',
    title          => $lang->{FIO},
    'data-visible' => $lang->{FIO}
  });

  my $login = $html->element('p', "<b>$lang->{LOGIN}:</b> $user_info->{LOGIN}", {
    class          => 'form-control-static',
    title          => $lang->{LOGIN},
    'data-visible' => $lang->{LOGIN}
  });

  my $info_str = join '', ($login, $fio, $home, $phone, $self->_get_internet_info($attr));

  my $col_div = $html->element('div', $info_str, { class => 'col-md-12 text-left' });

  return $html->element('div', $html->element('hr') . $col_div . $html->element('hr'), { class => 'form-group' });
}

#**********************************************************
=head2 _get_plan_date_input($attr)

=cut
#**********************************************************
sub _get_plan_date_input {
  my $self = shift;
  my ($attr) = @_;

  my $plan_date = $Msgs->{PLAN_DATE} && $Msgs->{PLAN_DATE} ne '0000-00-00' ? $Msgs->{PLAN_DATE} : '';
  my $plan_time = $Msgs->{PLAN_DATE} && $Msgs->{PLAN_TIME} && $Msgs->{PLAN_TIME} ne '00:00:00' ? $Msgs->{PLAN_TIME} : '';
  my $datetimepicker = $html->form_datetimepicker('PLAN_DATETIME', join(' ', ($plan_date, $plan_time)), {
    ICON           => 1,
    TIME_HIDDEN_ID => 'PLAN_TIME',
    DATE_HIDDEN_ID => 'PLAN_DATE',
    # EX_PARAMS      => q{pattern='^\d\d\d\d-(0?[1-9]|1[0-2])-(0?[1-9]|[12][0-9]|3[01]) (00|0?[0-9]|1[0-9]|2[0-3]):([0-9]|[0-5][0-9])$'},
  });

  $datetimepicker .= $html->element('input', '', { name => 'PLAN_DATE', id => 'PLAN_DATE', type => 'hidden' });
  $datetimepicker .= $html->element('input', '', { name => 'PLAN_TIME', id => 'PLAN_TIME', type => 'hidden' });

  my $col_div = $html->element('div', $datetimepicker, { class => 'col-md-12' });
  my $label = $html->element('label', "$lang->{EXECUTION}:", { class => 'col-md-12' });

  return $html->element('div', $label . $col_div, { class => 'form-group' });
}

#**********************************************************
=head2 _get_responsible_select($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub _get_responsible_select {
  my $self = shift;
  my ($attr) = @_;

  return '' if !$msgs_permissions->{1}{16};

  my $responsible_sel = main::sel_admins({
    NAME       => 'RESPOSIBLE',
    RESPOSIBLE => $Msgs->{RESPOSIBLE},
    DISABLE    => ($Msgs->{RESPOSIBLE}) ? undef : 0,
  });

  my $col_div = $html->element('div', $responsible_sel, { class => 'col-md-12' });
  my $label = $html->element('label', "$lang->{RESPOSIBLE}:", { class => 'col-md-12' });

  return $html->element('div', $label . $col_div, { class => 'form-group' });
}

#**********************************************************
=head2 _get_responsible_select($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub _get_watchers_select {
  my $self = shift;
  my ($attr) = @_;

  return '' if !$msgs_permissions->{1}{17};

  my $watchers = $Msgs->msg_watch_list({ MAIN_MSG => $Msgs->{ID}, AID => '_SHOW', COLS_NAME => 1 });
  
  my @watchers_aids = ();

  map push(@watchers_aids, $_->{aid}), @{$watchers};

  my $watchers_sel = main::sel_admins({
    NAME      => 'WATCHERS',
    WATCHERS  => join(',', @watchers_aids),
    MULTIPLE  => 1
  });

  my $col_div = $html->element('div', $watchers_sel, { class => 'col-md-12' });
  my $label = $html->element('label', "$lang->{WATCHERS}:", { class => 'col-md-12' });

  return $html->element('div', $label . $col_div, { class => 'form-group' });
}

#**********************************************************
=head2 _get_priority_select($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub _get_priority_select {
  my $self = shift;
  my ($attr) = @_;

  return '' if !$msgs_permissions->{1}{13};

  my $priority_colors = $attr->{PRIORITY_COLORS} || ();
  my $priority = $attr->{PRIORITY_ARRAY} || ();

  my $priority_sel = $html->form_select('PRIORITY', {
    SELECTED     => $Msgs->{PRIORITY} || 2,
    SEL_ARRAY    => $priority,
    STYLE        => $priority_colors,
    ARRAY_NUM_ID => 1
  });

  my $col_div = $html->element('div', $priority_sel, { class => 'col-md-12' });
  my $label = $html->element('label', "$lang->{PRIORITY}:", { class => 'col-md-12' });

  return $html->element('div', $label . $col_div, { class => 'form-group' });
}

#**********************************************************
=head2 _get_internet_info($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub _get_internet_info {
  my $self = shift;
  my ($attr) = @_;

  return '' if (!in_array('Internet', \@::MODULES));

  $Msgs->{ID} ||= $attr->{ID};

  require Internet::Sessions;
  Internet::Sessions->import();
  my $Sessions = Internet::Sessions->new($db, $admin, $CONF);
  my $online_list = $Sessions->online({ UID => $attr->{UID}, CID => '_SHOW', CLIENT_IP => '_SHOW', LAST_ALIVE => '_SHOW' });

  return '' if $Sessions->{TOTAL} < 1 || !$online_list->[0] || !$online_list->[0]{client_ip};
  my $online_info = $online_list->[0];

  my $ping_btn = $html->button('P', "qindex=$attr->{index}&header=2&ping=$online_info->{client_ip}&ID=$Msgs->{ID}&PLUGIN=$self->{PLUGIN_NAME}", {
    class         => 'btn btn-default btn-xs',
    LOAD_TO_MODAL => 1,
    TITLE         => 'Ping',
  });

  my $ip = $html->element('p', "<b>IP:</b> $online_info->{client_ip} $ping_btn", {
    class          => 'form-control-static',
    title          => 'IP',
    'data-visible' => 'IP'
  });

  my $cid = $html->element('p', "<b>CID:</b> $online_info->{cid}", {
    class          => 'form-control-static',
    title          => 'CID',
    'data-visible' => 'CID'
  });

  my $last_alive = $html->element('p', "<b>$lang->{LAST_UPDATE}:</b> $online_info->{last_alive}", {
    class          => 'form-control-static',
    title          => $lang->{LAST_UPDATE},
    'data-visible' => $lang->{LAST_UPDATE}
  });

  return join('', ($ip, $cid, $last_alive));
}

1;
