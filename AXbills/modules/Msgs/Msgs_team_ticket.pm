=head1 Msgs_team_ticket

  Msgs: Msgs_team_ticket

=cut

use strict;
use warnings FATAL => 'all';

our (
  $db,
  $admin,
  %conf,
  %lang,
  $html
);

my $Msgs = Msgs->new($db, $admin, \%conf);

#**********************************************************
=head2 msgs_team_set_ticket() -

=cut
#**********************************************************
sub msgs_team_set_ticket {

  if ($FORM{add}) {
    my $ticket_id = $FORM{TICKET};
    my $team_id = $FORM{TEAM};

    my $ticket_state = $Msgs->message_info($ticket_id)->{STATE};
    my $responsible = $Msgs->responsible_team_info($team_id);

    $Msgs->message_team_add({
      ID          => $ticket_id,
      RESPONSIBLE => $responsible->[0]{resposible},
      STATE       => $ticket_state,
      ID_TEAM     => $team_id
    });

    if (!_error_show($Msgs)) {
      my $msgs_result = $Msgs->message_change({
        ID          => $ticket_id,
        RESPONSIBLE => $responsible,
      });

      $html->message('info', $lang{CHANGED}, "$lang{CHANGED}") if (!_error_show($msgs_result));
    }
  }
  elsif ($FORM{chg}) {
    my $data = $Msgs->responsible_team_info($FORM{TEAM});

    if ($data) {
      $Msgs->message_team_change({
        ID          => $FORM{TICKET},
        RESPONSIBLE => $data->[0]->{resposible},
        ID_TEAM     => $data->[0]->{id},
        ID_SEARCH   => $FORM{chg}
      });

      if (!_error_show($Msgs)) {
        my $msgs_result = $Msgs->message_change({
          ID          => $FORM{TICKET},
          RESPONSIBLE => $data->[0]->{resposible},
        });

        $html->message('info', $lang{CHANGED}, "$lang{CHANGED}") if (!_error_show($msgs_result));
      }
    }
  }
  elsif ($FORM{del} && $FORM{COMMENTS}) {
    $Msgs->message_team_del($FORM{del});

    if (!_error_show($Msgs)) {
      $html->message('info', $lang{CHANGED}, "$lang{CHANGED}");
    }
  }

  show_form(\%FORM);

  my $table = $html->table({
    width   => '100%',
    caption => $lang{BRIGADE},
    title   => [ "#", $lang{BRIGADE}, $lang{RESPONSIBLE}, $lang{STATE} ],
    ID      => 'BRIGADE_ID',
  });

  my $status = msgs_sel_status({ HASH_RESULT => 1 });

  my $dispatch_all = $Msgs->ticket_team_list(
    {
      RESPONSIBLE => '_SHOW',
      STATE       => '_SHOW',
      ID_TEAM     => $FORM{BRIGADE} || '_SHOW',
      NAME        => '_SHOW'
    }
  );

  foreach my $element (@$dispatch_all) {
    my $replay_button =
      $html->button('', "index=" . get_function_index('msgs_admin') . '&chg=' . $element->{id},
        { class => 'fa fa fa-list-alt' }) if ($element->{responsible} && $element->{responsible} == $admin->{AID});

    $table->addrow(
      $element->{id},
      $lang{BRIGADE} . ' №' . $element->{id_team},
      $element->{name},
      $html->color_mark($status->{ $element->{state} }),
      $replay_button,
      $html->button($element->{id},
        "index=" . get_function_index('msgs_team_set_ticket') . '&chg_id=' . $element->{id}, { class => 'change' }),
      $html->button($element->{id}, "index=" . get_function_index('msgs_team_set_ticket')
        . "&del=" . $element->{id}, { class => 'del', MESSAGE => "$lang{DEL}?" })
    )
  }

  print $table->show();

  filter_brigade();

  return 1;
}

#**********************************************************
=head2 show_form() -

    Arguments:
      CHG_ID      - change element id
      TEAM        - team responsible id
      TICKET      - ticket id

    Return:
      tpl_show    - template

=cut
#**********************************************************
sub show_form {
  my ($attr) = @_;

  my $team = $attr->{TEAM};
  my $ticket = $attr->{TICKET};
  my $button_name = $lang{ADD};
  my $param_name = "add";
  my $chg_ticket_id = $attr->{chg_id};

  my $ticket_list = $Msgs->messages_list({
    SUBJECT   => '_SHOW',
    STATE_ID  => '!2,!1',
    COLS_NAME => 1,
    PAGE_ROWS => 65000
  });

  my $dispatch_team = $Msgs->responsible_team_list();

  if ($chg_ticket_id) {
    my $date = $Msgs->respnosible_info_change($chg_ticket_id);

    $team = $date->{responsible};
    $ticket = $date->{id};
    $button_name = $lang{CHANGE};
    $param_name = "chg";
  }

  my $team_select = $html->form_select('TEAM', {
    SELECTED    => $team,
    SEL_LIST    => $dispatch_team,
    SEL_KEY     => 'id',
    SEL_VALUE   => 'name',
    SEL_OPTIONS => { '' => '--' },
    NO_ID       => 1,
  });

  my $ticket_select = $html->form_select('TICKET', {
    SELECTED    => $ticket,
    SEL_LIST    => $ticket_list,
    SEL_KEY     => 'id',
    SEL_VALUE   => 'subject',
    SEL_OPTIONS => { '' => '--' },
  });

  return $html->tpl_show(_include('msgs_team_ticket', 'Msgs'), {
    INDEX       => get_function_index('msgs_team_set_ticket'),
    TEAM        => $team_select,
    TICKET      => $ticket_select,
    SAVE_CHG    => $button_name,
    PARAM       => $param_name,
    CHG_ELEMENT => $chg_ticket_id
  });
}

#**********************************************************
=head2 filter_brigade() -

  Arguments:
    -
  
  Return:
    -

=cut
#**********************************************************
sub filter_brigade {
  my $dispatch_all = $Msgs->ticket_team_list({
    RESPONSIBLE => '_SHOW',
    STATE       => '_SHOW',
    ID_TEAM     => '_SHOW',
    NAME        => '_SHOW',
    LOGIN       => '_SHOW',
    GROUP_BY    => 1
  });

  my @list_team = _msgs_footer_row($dispatch_all, {
    NAME_SELECT => 'BRIGADE',
    ID_KEY      => 'id_team',
    ID_VALUE    => 'name',
    FOR_FORM    => 'MSGS_BRIGADE',
    NAME_BUTTON => 'SERACH_BRIGADE',
    LABEL       => $lang{BRIGADE}
  });

  my $table_footer = $html->table({
    width => '100%',
    rows  => [ [ @list_team ] ]
  });

  print $html->form_main({
    CONTENT => $table_footer->show({ OUTPUT2RETURN => 1 }),
    HIDDEN  => { index => $index },
    NAME    => 'MSGS_BRIGADE',
    ID      => 'MSGS_BRIGADE',
  });

  return 1;
}

1