=head1 Msgs_scrub_box

  Msgs Msgs_scrub_box

=cut

use strict;
use warnings FATAL => 'all';
use AXbills::Misc;

our (
  $db,
  $admin,
  %conf,
  %lang,
  $html
);

my @priority_colors = ('#8A8A8A', $_COLORS[8], $_COLORS[9], '#E06161', $_COLORS[6]);
my @priority = ($lang{VERY_LOW}, $lang{LOW}, $lang{NORMAL}, $lang{HIGH}, $lang{VERY_HIGH});
my %panel_color = (1 => 'card-danger', 2 => 'card-success', 4 => 'card-warning');

my $Msgs = Msgs->new($db, $admin, \%conf);

#**********************************************************
=head2 msgs_scrub_box() -

=cut
#**********************************************************
sub msgs_scrub_box {

  my $statuses = $Msgs->status_list({ COLS_NAME => 1 });
  map $_->{name} = _translate($_->{name}), @{$statuses};

  my $status_sel = $html->form_select('MSGS_STATUS', {
    SELECTED    => $FORM{MSGS_STATUS},
    SEL_LIST    => $statuses,
    SEL_KEY     => 'id',
    SEL_VALUE   => 'name',
    SEL_OPTIONS => { 0 => $lang{OPEN} },
    MULTIPLE    => 1,
    NO_ID       => 1,
  });

  $html->tpl_show(_include('msgs_scrub_box_page', 'Msgs'), {
    MSGS_BODY     => _create_cards_msgs(),
    STATUS_SELECT => $status_sel,
    MSGS_INDEX    => get_function_index('msgs_admin'),
  });

  return 1;
}

#**********************************************************
=head2 _scrub_data_proccess() -

=cut
#**********************************************************
sub _scrub_data_proccess {
  my $msgs_list = $Msgs->messages_list({
    CHAPTER     => '_SHOW',
    CLIENT_ID   => '_SHOW',
    SUBJECT     => '_SHOW',
    STATE       => '_SHOW',
    DATE        => '_SHOW',
    ADMIN_LOGIN => '_SHOW',
    PRIORITY_ID => '_SHOW',
    COLS_NAME   => 1,
    PAGE_ROWS   => 30000,
  });

  my $status_select = '0,6,5,4';
  if ($FORM{MSGS_STATUS}) {
    $status_select = $FORM{MSGS_STATUS};
  }

  my $status_list = $Msgs->status_list({
    ID         => $status_select,
    _MULTI_HIT => 1,
    COLS_NAME  => 1
  });

  return ($msgs_list, $status_list);
}

#**********************************************************
=head2 _create_cards_msgs() -

=cut
#**********************************************************
sub _create_cards_msgs {

  my ($msgs_list, $msgs_status) = _scrub_data_proccess();

  my $count_status = !$FORM{MSGS_STATUS} ? 4 : $#{$msgs_status} + 1;
  my $status_template = '';
  my $messages_template = '';
  my $index_user = get_function_index('form_users');
  my $index_msgs = get_function_index('msgs_admin');

  for (my $status = 0; $status < $count_status; $status++) {
    my $status_id = $msgs_status->[ $status ]{id};

    foreach my $message (@{$msgs_list}) {
      next unless (defined($status_id) && $message->{state} eq $status_id);
      my $msgs_url = "?index=$index_msgs&UID=$message->{uid}&chg=$message->{id}#last_msg";
      my $user_card = "?index=$index_user&UID=$message->{uid}";

      $messages_template .= $html->tpl_show(_include('msgs_scrub_box_messages', 'Msgs'), {
        ID           => $message->{id},
        USER         => $message->{client_id},
        SUBJECT      => $message->{subject},
        MSGS_OPEN    => $msgs_url,
        USER_CARD    => $user_card,
        UID          => $message->{uid},
        DATE         => $message->{date},
        ADMIN        => $message->{admin_login} || $lang{RESPONSIBLE_NOT_SPECIFIED},
        STATUS_COLOR => $panel_color{ $status_id } || 'card-info',
      }, { OUTPUT2RETURN => 1 });

    }

    $status_template .= $html->tpl_show(_include('msgs_scrub_box_status', 'Msgs'), {
      STATUS_NAME => _translate($msgs_status->[ $status ]{name}),
      MSGS_CARD   => $messages_template,
      ID          => $status_id,
    }, { OUTPUT2RETURN => 1 });

    $messages_template = '';
  }

  return $status_template;
}

1;