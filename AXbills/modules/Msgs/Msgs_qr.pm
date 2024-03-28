=head1 NAME

  Start page table

=head1 VERSION

  0.1

=cut

use strict;
use warnings FATAL => 'all';
use AXbills::Defs;

our ($db,
  %lang,
  $html,
  @bool_vals,
  @MONTHES,
  @WEEKDAYS,
  @_COLORS,
  %permissions,
  $admin,
  $ui,
  %conf,
  %msgs_permissions
);

my $Msgs = Msgs->new($db, $admin, \%conf);

my $MESSAGE_ICON = q{};
if($html && $html->{TYPE} && $html->{TYPE} eq 'html') {
  $MESSAGE_ICON = $html->element('span', '', { class => 'far fa-envelope pr-1', OUTPUT2RETURN => 1 });
}

#***************************************************************
=head2 msgs_sp_show_overdue($attr)

=cut
#***************************************************************
sub msgs_sp_show_overdue {
  msgs_sp_show_new({ STATE => 12 });
}

#***************************************************************
=head2 msgs_sp_show_new($attr)

=cut
#***************************************************************
sub msgs_sp_show_new {
  my ($attr) = @_;

  $attr ||= {};
  my $messages_list = $Msgs->messages_list({
    LOGIN          => '_SHOW',
    CLIENT_ID      => '_SHOW',
    DATETIME       => '_SHOW',
    SUBJECT        => '_SHOW',
    CHAPTER        => '_SHOW',
    CHAPTER_NAME   => '_SHOW',
    PRIORITY       => '_SHOW',
    PRIORITY_ID    => '_SHOW',
    PLAN_DATE_TIME => '_SHOW',
    CHAPTER        => $msgs_permissions{4} ? join(';', keys %{$msgs_permissions{4}}) : '_SHOW',
    STATE          => ($attr && $attr->{STATE}) ? $attr->{STATE} : 0,
    SORT           => 'id',
    DESC           => 'desc',
    PAGE_ROWS      => 5,
    COLS_NAME      => 1
  });

  my $badge = '';
  if(!$attr->{STATE}){
    use AXbills::Base qw/days_in_month/;

    my($y, $m, undef) = split("-", $DATE);

    my $start_date = "$y-$m-01";
    my $end_date = "$y-$m-" . days_in_month({DATE => $DATE});

    my $all_open_msgs = $Msgs->{OPEN};

    my $closed_in_month = $Msgs->messages_list({
      CLOSED_DATE => ">=$start_date;<=$end_date",
      SORT        => 'id',
      DESC        => 'desc',
      PAGE_ROWS   => 9999999,
    });

    my $opened_in_month = $Msgs->messages_list({
      DATE      => ">=$start_date;<=$end_date",
      SORT      => 'id',
      DESC      => 'desc',
      PAGE_ROWS => 9999999,
    });

    my $scalar_opened_in_month = $opened_in_month ? scalar (@$opened_in_month) : 0;
    my $scalar_closed_in_month = $closed_in_month ? scalar (@$closed_in_month) : 0;

    my $opened_per_month_badge = $html->element('small', ($scalar_opened_in_month), {
      class                   => 'label badge badge-warning',
      'data-tooltip'          => "$lang{OPEN} $lang{FOR_} $lang{MONTH}",
      'data-tooltip-position' => 'top'
    });
    my $closed_per_month_badge = $html->element('small', ($scalar_closed_in_month), {
      class                   => 'label badge badge-success',
      'data-tooltip'          => "$lang{CLOSED} $lang{FOR_} $lang{MONTH}",
      'data-tooltip-position' => 'top'
    });
    my $all_opend_messages = $html->element('small', $all_open_msgs, {
      class                   => 'label badge badge-primary',
      'data-tooltip'          => "$lang{ALL} $lang{OPEN}",
      'data-tooltip-position' => 'top'
    });

    $badge = $all_opend_messages . $opened_per_month_badge . $closed_per_month_badge;
  }

  return msgs_sp_table($messages_list, {
    CAPTION      => ($attr->{STATE}) ? $lang{OVERDUE} : $lang{MESSAGES},
    SKIP_ICON    => 1,
    DATE_KEY     => ($attr->{STATE}) ? 'plan_date_time' : 'datetime',
    DATA_CAPTION => ($lang{DATE}),
    BADGE        => $badge
  });
}

#**********************************************************
=head2 msgs_user_watch()

=cut
#**********************************************************
sub msgs_user_watch {

  my $watched_links = $Msgs->msg_watch_list({
    COLS_NAME => 1,
    AID       => $admin->{AID}
  });
  _error_show($Msgs);

  my $watched_messages_list = $Msgs->messages_list({
    MSG_ID           => join(';', map {$_->{main_msg}} @$watched_links) || 0,
    COLS_NAME        => 1,
    PAGE_ROWS        => 5,
    LOGIN            => '_SHOW',
    STATE            => '_SHOW',
    PRIORITY_ID      => '_SHOW',
    LAST_REPLIE_DATE => '_SHOW',
    SUBJECT          => '_SHOW',
    CHAPTER          => $msgs_permissions{4} ? join(';', keys %{$msgs_permissions{4}}) : '_SHOW',
    SORT             => 'last_replie_date',
    CHAPTER_NAME     => '_SHOW',
  });
  _error_show($Msgs);

  my $badge = $html->element('small', $Msgs->{TOTAL} || 0, { class => 'label badge badge-success' });

  return msgs_sp_table($watched_messages_list, {
    BADGE           => $badge,
    CAPTION         => $lang{WATCHED},
    DATA_CAPTION    => $lang{LAST_ACTIVITY},
    DATE_KEY        => 'last_replie_date',
    EXTRA_LINK_DATA => "&STATE=12", # state for watching messages
  });
}

#**********************************************************
=head2 msgs_dispatch_quick_report()

=cut
#**********************************************************
sub msgs_dispatch_quick_report {

  my $table = $html->table({
    width         => '100%',
    caption       =>
      $html->button($MESSAGE_ICON . $lang{DISPATCH}, "index=" . get_function_index('msgs_dispatches') . "&ALL_MSGS=1"),
    title_plain   => [ $lang{NAME}, $lang{CREATED}, $lang{EXECUTED}, $lang{TOTAL} ],
    class         => 'table',
    ID            => 'DISPATCH_QUIK_REPORT_LIST'
  });

  my $list = $Msgs->dispatch_list({
    COLS_NAME     => 1,
    PAGE_ROWS     => $conf{MSGS_QR_ROWS} || 5,
    MSGS_DONE     => '_SHOW',
    CREATED       => '_SHOW',
    COMMENTS      => '_SHOW',
    MESSAGE_COUNT => '_SHOW',
    PLAN_DATE     => '_SHOW',
    SORT          => 'd.plan_date',
    DESC          => 'DESC'
  });

  my $dispatch_index = get_function_index('msgs_dispatches');

  foreach my $message ( @{$list} ) {
    my $dispatch_comments = $message->{comments} || $lang{NO_SUBJECT};
    my $done_count = $message->{message_count}
      ? (int(($message->{msgs_done} * 100) / $message->{message_count})) : 0;
    my $dispatch_link = "index=$dispatch_index";

    $table->addrow($html->button($dispatch_comments, $dispatch_link),
      $html->button($message->{created}, $dispatch_link),
      $html->progress_bar({
        TEXT     => $done_count . "%",
        TOTAL    => $message->{msgs_done},
        COMPLETE => $message->{message_count}
      }),
      $html->button($message->{message_count}, $dispatch_link),
    );
  }

  return $table->show();
}

#**********************************************************
=head2 msgs_open_msgs()

=cut
#**********************************************************
sub msgs_open_msgs {

  my $table = $html->table({
    width       => '100%',
    caption     => $html->button($MESSAGE_ICON . $lang{RESPOSIBLE}, "index=" . get_function_index('msgs_admin') . "&STATE=0"),
    title_plain => [ $lang{RESPOSIBLE}, $lang{COUNT} ],
    class       => 'table',
    ID          => 'DISPATCH_QUIK_REPORT_LIST'
  });

  my $list = $Msgs->messages_list({
    ADMIN_LOGIN            => '_SHOW',
    RESPOSIBLE             => '_SHOW',
    RESPOSIBLE_ADMIN_LOGIN => '_SHOW',
    CHAPTER                => $msgs_permissions{4} ? join(';', keys %{$msgs_permissions{4}}) : '_SHOW',
    STATE                  => 0,
    COLS_NAME              => 1,
    PAGE_ROWS              => 10000
  });

  my %admins;
  my %responsible_admin;
  my $without_admin = 0;
  foreach my $msg_info (@$list) {
    if ($msg_info->{resposible_admin_login}) {
      $admins{ $msg_info->{resposible_admin_login} } += 1;
      $responsible_admin{ $msg_info->{resposible_admin_login} . 'resposible' } = $msg_info->{resposible};
    }
    else {
      $without_admin++;
    }
  }

  $table->{rowcolor}='bg-info';
  $table->addrow($lang{NOT_DEFINED}, $html->button($without_admin, "index=" . get_function_index('msgs_admin')
        . "&RESPOSIBLE=<1" . "&STATE=0"));

  delete $table->{rowcolor};

  foreach my $admin_info (sort { $admins{$b} <=> $admins{$a} } keys %admins) {
    $table->addrow($admin_info, $html->button($admins{$admin_info}, "index=" . get_function_index('msgs_admin')
          . "&RESPOSIBLE=$responsible_admin{$admin_info.'resposible'}" . "&STATE=0"));
  }


  return $table->show();
}

#**********************************************************
=head2 msgs_sp_table($messages_list, $attr)

=cut
#**********************************************************
sub msgs_sp_table {
  my ($messages_list, $attr) = @_;

  $messages_list = [] if (!$messages_list || ref $messages_list ne 'ARRAY');

  my $statuses_list = $Msgs->status_list({
    NAME      => '_SHOW',
    COLOR     => '_SHOW',
    LOGIN     => '_SHOW',
    ICON      => '_SHOW',
    SORT      => 'id',
    COLS_NAME => 1,
  });

  _error_show($Msgs);

  my %statuses_by_id = ();
  $statuses_by_id{$_->{id}} = $_ foreach (@$statuses_list);

  my @priority_colors_list = (
    'bg-navy disabled',
    'bg-black disabled',
    ' ',
    'bg-yellow',
    'bg-red'
  );

  my $badge = $attr->{BADGE} || '';
  my $extra_link_data = $attr->{EXTRA_LINK_DATA} || '';
  my $msgs_admin_index = get_function_index('msgs_admin');

  my $table = $html->table({
    width       => '100%',
    caption     => $html->button(($attr->{SKIP_ICON} ? '' : $MESSAGE_ICON) . ($attr->{CAPTION} || '') . "&nbsp;&nbsp;",
      "index=$msgs_admin_index&ALL_MSGS=1$extra_link_data") . $badge,
    title_plain => [ '', ($attr->{DATA_CAPTION} || $lang{DATE}), $lang{LOGIN}, $lang{SUBJECT}, $lang{CHAPTER} ],
    class       => 'table',
    ID          => 'USER_WATCH_LIST'
  });

  foreach my $msg_info ( @{$messages_list} ) {
    my $status_id = $msg_info->{state};
    my $state_icon = $statuses_by_id{$status_id}->{icon} || '';
    my $status_name = _translate($statuses_by_id{$status_id}->{name}) || $statuses_by_id{$status_id}->{name};

    $table->{rowcolor} = $priority_colors_list[$msg_info->{priority_id}] || '';

    my $chapter = ($msg_info->{chapter_name})
      ? ( length($msg_info->{chapter_name}) > 30)
        ? $html->element('span', substr($msg_info->{chapter_name}, 0, 30) . '...', { title => $msg_info->{chapter_name} })
        : $msg_info->{chapter_name}
      : $lang{NO_CHAPTER};
    
    $msg_info->{subject} = convert($msg_info->{subject}, { text2html => 1, json => $FORM{json} });
    my $subject = ($msg_info->{subject})
      ? ( length($msg_info->{subject}) > 30)
        ? $html->element('span', substr($msg_info->{subject}, 0, 30) . '...', { title => $msg_info->{subject} })
        : $msg_info->{subject}
      : $lang{NO_SUBJECT};

    $table->addrow(
      # State
      $html->element('i', '', {
          class                   => $state_icon,
          'data-tooltip'          => $status_name,
          'data-tooltip-position' => 'left'
        },
      ),

      # Date showed in moment humanized format
      $html->element('span', '', { 'data-value' => $msg_info->{($attr->{DATE_KEY} || 'date')}, class => 'moment-insert' }),

      # If have login, show link to user
      ($msg_info->{uid} ? $html->button($msg_info->{login}, "index=15&UID=$msg_info->{uid}") : '' ),

      # Subject stripped to 30 symbols
      $html->button( $subject, "index=" . $msgs_admin_index . "&UID=" . $msg_info->{uid} . "&chg=" . $msg_info->{id}),

      # Chapter stripped to 30 symbols
      $html->button( $chapter, 'index='. get_function_index('msgs_chapters') . "&chg=" . $msg_info->{chapter_id})
   );
  }

  return $table->show();
}

#**********************************************************
=head2 msgs_rating()

=cut
#**********************************************************
sub msgs_rating {

  my ($y, $m, undef) = split('-', $DATE);

  my $table = $html->table({
    width       => '100%',
    caption     => $html->button($MESSAGE_ICON . $lang{EVALUATION_OF_PERFORMANCE},
      "index=" . get_function_index('msgs_admin') . "&STATE=0"
    ),
    title_plain => [ "$lang{LOGIN}", "$lang{SUBJECT}", "$lang{ASSESSMENT}" ],
    class       => 'table',
    ID          => 'EVALUATION_OF_PERFORMANCE_TABLE',
  });

  my $list = $Msgs->messages_list({
    RATING                 => '1;2;3;4;5',
    DATE                   => ">$y-$m-01",

    ADMIN_LOGIN            => '_SHOW',
    RESPOSIBLE             => '_SHOW',
    RESPOSIBLE_ADMIN_LOGIN => '_SHOW',
    SUBJECT                => '_SHOW',
    STATE                  => '_SHOW',
    CHAPTER                => $msgs_permissions{4} ? join(';', keys %{$msgs_permissions{4}}) : '_SHOW',

    PAGE_ROWS              => 5,
    SORT                   => 'date',
    COLS_NAME              => 1,
  });

  foreach my $msg_info (@{$list}) {
    $table->addrow(
      $msg_info->{resposible_admin_login} ? $msg_info->{resposible_admin_login} : $lang{ALL},
      $html->button($msg_info->{subject} ? $msg_info->{subject} : $lang{NO_SUBJECT}, "index=" . get_function_index('msgs_admin') . "&UID=" . $msg_info->{uid} . "&chg=" . $msg_info->{id}),
      msgs_rating_icons($msg_info->{rating}),
    );
  }

  return $table->show();
}

#**********************************************************
=head2 msgs_rating_icons()

=cut
#**********************************************************
sub msgs_rating_icons {
  my ($rating) = @_;

  my $rating_icons = '';
  if ($rating && $rating > 0) {
    for (my $i = 0; $i < $rating; $i++) {
      $rating_icons .= "\n" . $html->element('i', '', { class => 'fa fa-star' });
    }
    for (my $i = 0; $i < 5 - $rating; $i++) {
      $rating_icons .= "\n" . $html->element('i', '', { class => 'far fa-star' });
    }
  }
  return $rating_icons;
}

#**********************************************************
=head2 msgs_support_stats_block()

=cut
#**********************************************************
sub msgs_support_stats_block {
  return msgs_support_stats({
    QUICK_REPORT  => 1,
    DISPLAY_CHART => 'd-none',
    BLOCKS_COL    => 'col-md-12',
    AID           => $admin->{AID}
  });
}

#**********************************************************
=head2 msgs_support_stats_chart()

=cut
#**********************************************************
sub msgs_support_stats_chart {

  my $card_body = $html->element('div', msgs_support_stats({
    QUICK_REPORT   => 1,
    DISPLAY_BLOCKS => 'd-none',
    CHART_COL      => 'col-md-12',
    AID           => $admin->{AID}
  }), { class => 'card-body p-0' });

  my $icon = $html->element('i', '', { class => 'fa fa-minus'});
  my $btn_tool = $html->element('button', $icon, { class => 'btn btn-tool', type => 'button', 'data-card-widget' => 'collapse' });
  my $header_tools = $html->element('div', $btn_tool, { class => 'card-tools'});
  my $card_title = $html->element('h4', $lang{RESPONSE_TIME}, { class => 'card-title'});

  my $card_header = $html->element('div', $card_title . $header_tools, { class => 'card-header'});

  return $html->element('div', $card_header . $card_body, { class => 'card card-primary card-outline' });
}

#**********************************************************
=head2 msgs_dynamics_of_messages_and_replies()

=cut
#**********************************************************
sub msgs_dynamics_of_messages_and_replies {

  my $messages_and_replies = $Msgs->messages_and_replies_for_two_weeks();

  my $data_by_days = {};
  foreach my $data (@{$messages_and_replies}) {
    if ($data_by_days->{$data->{day}}) {
      $data_by_days->{$data->{day}}{MESSAGES} += $data->{messages} || 0;
      $data_by_days->{$data->{day}}{REPLIES} += $data->{replies} || 0;
      next;
    }
    $data_by_days->{$data->{day}} = {
      MESSAGES => $data->{messages} || 0,
      REPLIES  => $data->{replies} || 0,
      CLOSED   => 0
    };
  }

  my $closed_messages = $Msgs->messages_and_replies_for_two_weeks(join(',', map { "'$_'" } keys %{$data_by_days}));
  foreach my $closed_message (@{$closed_messages}) {
    $data_by_days->{$closed_message->{day}}{CLOSED} = $closed_message->{closed_messages};
  }

  my $chart = $html->chart({
    TYPE              => 'bar',
    X_LABELS          => [ sort keys %{$data_by_days} ],
    DATA              => {
      $lang{MESSAGES} => [ map $data_by_days->{$_}{MESSAGES}, sort keys %{$data_by_days} ],
      $lang{REPLYS}   => [ map $data_by_days->{$_}{REPLIES}, sort keys %{$data_by_days} ],
      $lang{CLOSED}   => [ map $data_by_days->{$_}{CLOSED}, sort keys %{$data_by_days} ]
    },
    BACKGROUND_COLORS => {
      $lang{MESSAGES} => 'rgba(2, 99, 2, 0.8)',
      $lang{REPLYS}   => 'rgba(54, 123, 245, 0.8)',
      $lang{CLOSED}   => 'rgba(255, 193, 7, 0.8)'
    },
    OUTPUT2RETURN     => 1,
  });


  my $card_body = $html->element('div', $chart, { class => 'card-body p-1' });

  my $icon = $html->element('i', '', { class => 'fa fa-minus'});
  my $btn_tool = $html->element('button', $icon, { class => 'btn btn-tool', type => 'button', 'data-card-widget' => 'collapse' });
  my $header_tools = $html->element('div', $btn_tool, { class => 'card-tools'});
  my $card_title = $html->element('h4', $lang{DYNAMICS_OF_MESSAGES_AND_REPLIES}, { class => 'card-title'});

  my $card_header = $html->element('div', $card_title . $header_tools, { class => 'card-header'});

  my $card = $html->element('div', $card_header . $card_body, { class => 'card card-primary card-outline' });

  return $card
}

1
