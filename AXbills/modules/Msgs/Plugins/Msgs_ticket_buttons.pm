package Msgs::Plugins::Msgs_ticket_buttons;

use strict;
use warnings FATAL => 'all';

my ($admin, $CONF, $db, $msgs_permissions);
my $json;
my AXbills::HTML $html;
my $lang;
my $Msgs;

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
    PLUGIN_NAME => 'Msgs_ticket_buttons'
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
    NAME     => "Ticket interaction buttons",
    POSITION => 'RIGHT',
    DESCR    => $lang->{TICKET_INTERACTION_BUTTONS}
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

  $attr->{index} ||= $attr->{qindex};
  return '' if !$attr->{index};

  $attr->{UID} ||= 0;
  $Msgs->{ID} ||= 0;

  my $export_result = $self->_get_export_button($attr);
  return $export_result if (ref $export_result eq 'HASH');

  my $history_result = $self->_get_history_button($attr);
  return $history_result if (ref $history_result eq 'HASH');

  my $payment_result = $self->_payments_btn($attr);
  return $payment_result if (ref $payment_result eq 'HASH');

  my $info = $self->_get_watch_button($attr);
  $info .= $export_result . $history_result;
  $info .= $self->_get_delegate_buttons($attr);
  $info .= $self->_get_tags_button($attr);
  $info .= $payment_result;

  my $button_group = $html->element('div', $info, {
    class        => 'btn-group',
    role         => 'group',
    'aria-label' => 'Basic example'
  });
  my $div = $html->element('div', $info, {
    class => 'col-md-12 d-flex flex-wrap justify-content-center',
    id    => 'btn-group'
  });

  return $html->element('div', $div, { class => 'form-group' });
}

#**********************************************************
=head2 _get_watch_button($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub _get_watch_button {
  my $self = shift;
  my ($attr) = @_;

  return '' if !$msgs_permissions->{1}{17};

  if ($attr->{PLUGIN} && $attr->{WATCH}) {
    if ($attr->{del_watch}) {
      $Msgs->msg_watch_del({ ID => $Msgs->{ID} || $attr->{ID}, AID => $admin->{AID} });
    }
    else {
      $Msgs->msg_watch($attr);
    }
  }

  $Msgs->msg_watch_list({ MAIN_MSG => $Msgs->{ID}, AID => $admin->{AID} });

  return $html->button('', "index=$attr->{index}&UID=$attr->{UID}&WATCH=1&ID=$Msgs->{ID}&chg=$Msgs->{ID}&PLUGIN=$self->{PLUGIN_NAME}", {
    class => 'btn btn-primary group-btn',
    ICON => 'fa fa-eye',
    TITLE => $lang->{WATCH}
  }) if $Msgs->{TOTAL} < 1;

  return $html->button('', "index=$attr->{index}&UID=$attr->{UID}&WATCH=1&ID=$Msgs->{ID}&chg=$Msgs->{ID}&del_watch=1&PLUGIN=$self->{PLUGIN_NAME}", {
    class   => 'btn btn-primary group-btn',
    ICON    => 'fa fa-eye-slash',
    CONFIRM => "$lang->{UNDO} $lang->{WATCH}"
  });
}

#**********************************************************
=head2 _get_export_button($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub _get_export_button {
  my $self = shift;
  my ($attr) = @_;

  return '' if !$msgs_permissions->{1}{15};
  if ($attr->{PLUGIN} && $attr->{export}) {
    $self->export_ticket($attr);
    return { RETURN_VALUE => 1 };
  }

  return $html->button('', "qindex=$attr->{index}&header=2&UID=$attr->{UID}&export=1&ID=$Msgs->{ID}&PLUGIN=$self->{PLUGIN_NAME}", {
    class         => 'btn btn-primary group-btn',
    ICON          => 'fa fa-external-link-alt',
    TITLE         => $lang->{EXPORT},
    LOAD_TO_MODAL => 1,
  });
}

#**********************************************************
=head2 _get_history_button($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub _get_history_button {
  my $self = shift;
  my ($attr) = @_;

  if ($attr->{PLUGIN} && $attr->{PLUGIN} eq $self->{PLUGIN_NAME} && $attr->{MSG_HISTORY}) {
    main::form_changes({
      SEARCH_PARAMS => {
        MODULE  => 'Msgs',
        ACTIONS => 'MSG_ID:' . $attr->{ID} . "*",
        SORT    => $attr->{sort} || 1,
        DESC    => (!$attr->{sort}) ? 'desc' : $attr->{desc},
        PG      => $attr->{pg} || 0
      },
      PAGES_QS      => "&PLUGIN=$self->{PLUGIN_NAME}&ID=$attr->{ID}&MSG_HISTORY=1"
    });

    return { RETURN_VALUE => 1 };
  }

  return $html->button('', "index=$attr->{index}&ID=$Msgs->{ID}&PLUGIN=$self->{PLUGIN_NAME}&MSG_HISTORY=1", {
    class => 'btn btn-primary group-btn',
    ICON  => 'far fa-clock',
    TITLE => $lang->{LOG}
  });
}

#**********************************************************
=head2 _get_delegate_buttons($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub _get_delegate_buttons {
  my $self = shift;
  my ($attr) = @_;

  return '' if !$msgs_permissions->{1}{9};

  my $chapter = $Msgs->{CHAPTER} || $attr->{CHAPTER} || '';
  my $uid = $attr->{UID} || '';

  if ($attr->{PLUGIN} && $attr->{PLUGIN} eq $self->{PLUGIN_NAME} && defined($attr->{deligate})) {
    $Msgs->message_change({
      ID         => $attr->{deligate},
      DELIGATION => $attr->{level},
      ADMIN_READ => "0000-00-00 00:00:00",
      RESPOSIBLE => 0,
    });

    $Msgs->message_reply_add({
      ID              => $attr->{deligate},
      AID             => $CONF->{SYSTEM_ADMIN_ID} || 2,
      IP              => $admin->{SESSION_IP},
      STATE           => 0,
      REPLY_TEXT      => "$lang->{DELIGATE} : " . ($admin->{A_FIO} || $admin->{A_LOGIN} || ''),
      REPLY_INNER_MSG => 1
    });

    $html->message('info', $lang->{INFO}, $lang->{DELIGATED}) if (!$Msgs->{errno});
  }

  $Msgs->{DELIGATED} = '-';
  $Msgs->{DELIGATED} = $msgs_permissions->{deligation_level}{$chapter} + 1 if (defined $msgs_permissions->{deligation_level}{$chapter});
  $Msgs->{DELIGATED_DOWN} = 0;

  my $delegated_down_btn = $html->button('', "index=$attr->{index}&change=1&deligate=$Msgs->{ID}&ID=$Msgs->{ID}&PLUGIN=$self->{PLUGIN_NAME}&level=$Msgs->{DELIGATED_DOWN}&UID=$uid", {
    class => 'btn btn-primary group-btn',
    ICON  => 'fa fa-hand-point-down',
    TITLE => "$lang->{COMPETENCE} $lang->{DOWN} ($Msgs->{DELIGATED_DOWN})"
  });

  my $delegated_btn = $html->button('', "index=$attr->{index}&change=1&deligate=$Msgs->{ID}&ID=$Msgs->{ID}&PLUGIN=$self->{PLUGIN_NAME}&level=$Msgs->{DELIGATED}&UID=$uid", {
    class => 'btn btn-primary group-btn',
    ICON  => 'fa fa-hand-point-up',
    TITLE => "$lang->{COMPETENCE} $lang->{UP} ($Msgs->{DELIGATED})"
  });

  return $delegated_down_btn . $delegated_btn;
}

#**********************************************************
=head2 _get_inner_msg_button($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub _get_inner_msg_button {
  my $self = shift;
  my ($attr) = @_;

  return '' if $attr->{PLUGIN} && !$attr->{change};

  return '' if !$Msgs->{INNER_MSG};

  return $html->element('span', '', {
    class => 'btn btn-warning',
    ICON => 'fa fa-sunglasses',
    title => $lang->{INNER}
  });
}

#**********************************************************
=head2 _get_tags_button($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub _get_tags_button {
  my $self = shift;
  my ($attr) = @_;

  return '' if !$msgs_permissions->{1}{18} || !$msgs_permissions->{1}{19};
  return '' if $attr->{PLUGIN} && !$attr->{change};

  return '' if (!$admin->{permissions}->{4} && !$CONF->{MSGS_TAGS_NON_PRIVILEGED});

  if ($attr->{CHANGE_MSGS_TAGS}) {
    $Msgs->{TAB1_ACTIVE} = "active";
    $Msgs->quick_replys_tags_add({ IDS => $attr->{TAGS_IDS}, MSG_ID => $Msgs->{ID} });
    $html->message('info', $lang->{INFO}, "$lang->{ADDED} $Msgs->{TOTAL} $lang->{MSGS_TAGS}") if !$Msgs->{errno};
  }

  return $html->button('', "get_index=msgs_quick_replys_tags&header=2&MSGS_ID=$Msgs->{ID}&UID=$attr->{UID}&PLUGIN=$self->{PLUGIN_NAME}", {
    LOAD_TO_MODAL => 1,
    class         => 'btn btn-primary group-btn',
    ICON          => 'fa fa-tags',
    TITLE         => $lang->{MSGS_TAGS},
  });
}

#**********************************************************
=head2 _payments_btn($attr)

=cut
#**********************************************************
sub _payments_btn {
  my $self = shift;
  my ($attr) = @_;

  return '' if !$admin->{permissions}{2} || !$admin->{permissions}{2}{1};
  return '' if !$CONF->{MSGS_TICKET_PRICE};

  my ($sum, $method) = split ':', $CONF->{MSGS_TICKET_PRICE};
  return if !defined($sum) || !defined($method);

  if ($attr->{CONFIRM_PAYMENT}) {
    my $title = $html->element('h4', $lang->{DO_YOU_REALLY_WANT_TO_CHARGE_FOR_MESSAGE}, { class => 'card-title' });
    my $card_header = $html->element('div', $title, { class => 'card-header with-border' });

    my $yes_btn = $html->button($lang->{EXECUTE}, "get_index=form_fees&header=2&full=1&SUM=$sum&METHOD=$method&UID=$attr->{UID}" .
      "&DESCRIBE=$attr->{SUBJECT} %23 $attr->{ID}", {
      class     => 'btn btn-danger ml-2',
      target    => '_blank',
      ex_params => 'onclick=aModal.hide()'
    });
    my $no_btn = $html->button($lang->{CANCEL}, '', {
      class          => 'btn btn-default',
      ex_params      => 'onclick=aModal.hide()',
      JAVASCRIPT     => 1,
      NO_LINK_FORMER => 1,
      SKIP_HREF      => 1
    });

    my $card_body = $html->element('div', $no_btn . $yes_btn, { class => 'card-body p-0 text-right' });

    print $card_header . $card_body;
    return { RETURN_VALUE => 1 };
  }

  return '' if $attr->{PLUGIN} && !$attr->{change};

  require Fees;
  Fees->import();
  my $Fees = Fees->new($db, $admin, $CONF);
  $Fees->list({ DESCRIBE  => "$Msgs->{SUBJECT} # $Msgs->{ID}", COLS_NAME => 1, PAGE_ROWS => 1 });

  if ($Fees->{TOTAL} > 0) {
    return $html->button('', "qindex=$attr->{index}&header=2&UID=$attr->{UID}&CONFIRM_PAYMENT=1&ID=$Msgs->{ID}&PLUGIN=$self->{PLUGIN_NAME}", {
      class         => 'btn btn-success group-btn',
      ICON          => 'fas fa-credit-card',
      TITLE         => $lang->{FEESs},
      LOAD_TO_MODAL => 1,
    });
  }

  return $html->button('', "get_index=form_fees&header=2&full=1&SUM=$sum&METHOD=$method&UID=$attr->{UID}" .
    "&DESCRIBE=$Msgs->{SUBJECT} %23 $Msgs->{ID}", {
    class  => 'btn group-btn btn-primary',
    ICON   => 'fas fa-credit-card',
    target => '_blank',
    TITLE  => $lang->{FEES},
  });
}

#**********************************************************
=head2 export_ticket($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub export_ticket {
  my $self = shift;
  my ($attr) = @_;

  if ($attr->{EXPORT}) {
    require Msgs::Export_redmine;
    Export_redmine->import();

    my $Export_redmine = Export_redmine->new($db, $admin, $CONF);
    $Export_redmine->export_task($attr);
    my $task_link = ($Export_redmine->{TASK_LINK}) ?
      $html->button($Export_redmine->{TASK_ID}, '', { GLOBAL_URL => $Export_redmine->{TASK_LINK} }) :
      $Export_redmine->{TASK_ID};

    if(! main::_error_show($Export_redmine, { MESSAGE => $task_link })) {
      $html->message('info', $lang->{ADDED}, "$lang->{ADDED}: " . $task_link) if $Export_redmine->{TASK_ID};
    }

    my $list = $Export_redmine->task_list();
    my $table;

    ($table, $list) = main::result_former({
      TABLE         => {
        width   => '100%',
        caption => 'Redmine tasks',
        ID      => 'MSGS_REDMINE_LIST'
      },
      DATAHASH      => $Export_redmine->{RESULT}->{issues},
      SKIPP_UTF_OFF => 1,
      TOTAL         => 1
    });
    return;
  }

  my $priority_colors = $attr->{PRIORITY_COLORS} || ();
  my $priority = $attr->{PRIORITY_ARRAY} || ();

  $Msgs->{ACTION} = '_export';
  $Msgs->{LNG_ACTION} = $lang->{EXPORT};

  $Msgs->{PRIORITY_SEL} = $html->form_select('PRIORITY', {
    SELECTED     => 2,
    SEL_ARRAY    => $priority,
    STYLE        => $priority_colors,
    ARRAY_NUM_ID => 1
  });

  $Msgs->{EXPORT_SYSTEM_SEL} = $html->form_select('EXPORT', {
    SELECTED  => 'redmine',
    SEL_ARRAY => [ 'redmine' ],
  });

  $html->tpl_show(main::_include('msgs_export', 'Msgs'), {%{$Msgs}, %{$attr} });

  return 0;
}


1;
