=head1 NAME

  Msgs::New

  Created for config load optimization

=cut

use strict;
use warnings FATAL => 'all';

use Msgs;

our (
  $db,
  %lang,
  @_COLORS,
  $SELF_URL,
  %msgs_permissions
);

our Admins $admin;
our AXbills::HTML $html;

use AXbills::Base qw(cmd tpl_parse);
our $Msgs = Msgs->new($db, $admin, \%conf);

#**********************************************************
=head2 msgs_redirect_filter($attr)

=cut
#**********************************************************
sub msgs_redirect_filter {
  my ($attr) = @_;

  return 0 unless ($conf{MSGS_REDIRECT_FILTER_DEL} || $conf{MSGS_REDIRECT_FILTER_ADD});

  my $Internet_service;

  if (in_array('Internet', \@MODULES)) {
    require Internet;
    $Internet_service = Internet->new($db, $admin, \%conf);
  }

  my $cmd = '';
  my $action = '';

  #Del filter
  if ($conf{MSGS_REDIRECT_FILTER_DEL} && $attr->{DEL}) {
    $action = 'del';
    $Internet_service->user_change({ UID => $attr->{UID}, FILTER_ID => '' });

    if ($conf{MSGS_REDIRECT_FILTER_DEL} =~ /EXEC:(.+)/) {
      $cmd = $1;
    }
  }

  #Add filter
  elsif ($conf{MSGS_REDIRECT_FILTER_ADD}) {
    $action = 'add';

    $conf{MSGS_REDIRECT_FILTER_ADD} =~ /(EXEC:[a-zA-Z0-9\_\-\.\/ \>\%\"\'\@\=]+)?;?(RAD:.+)?/;

    $cmd = $1;
    my $rad = $2;

    $Internet_service->user_change({ UID => $attr->{UID}, FILTER_ID => $rad }) if $rad;
  }

  if ($cmd ne '') {
    $cmd =~ s/EXEC://;
    $cmd = tpl_parse($cmd, {
      ACTION => $action,
      IP     => $ENV{REMOTE_ADDR},
      DATE   => "$DATE $TIME",
      LOGIN  => $attr->{LOGIN},
      MSG_ID => $attr->{MSG_ID},
      UIDS   => $attr->{UID}
    });
  }

  cmd($cmd) if $cmd;

  return 1;
}

#**********************************************************
=head2 msgs_new($attr) - Count New messages for user

=cut
#**********************************************************
sub msgs_new {
  my ($attr) = @_;

  my %SHOW_PARAMS = (GID => $LIST_PARAMS{GID});

  if ($attr->{ADMIN_UNREAD}) {
    %SHOW_PARAMS = (
      UID          => $attr->{ADMIN_UNREAD},
      ADMIN_UNREAD => 1,
      CHAPTER      => !$msgs_permissions{4} ? '_SHOW' : join(',', keys %{$msgs_permissions{4}}),
      STATE        => 0,
    );

    $Msgs->messages_new({ %SHOW_PARAMS });

    return $Msgs->{UNREAD} if $Msgs->{TOTAL};
  }
  elsif ($attr->{UID}) {
    %SHOW_PARAMS = (
      UID        => $attr->{UID},
      USER_READ  => '0000-00-00  00:00:00',
      ADMIN_READ => '>0000-00-00 00:00:00',
      INNER_MSG  => 0,
      STATE      => (defined($attr->{STATE})) ? $attr->{STATE} : undef,
    );

    $Msgs->messages_new({ %SHOW_PARAMS });

    return '' if $Msgs->{TOTAL} <= 0 || $Msgs->{UNREAD} <= 0;

    if ($conf{MSGS_UNREAD_FORWARD}) {
      my @RULES_ARR = split(/;/, $conf{MSGS_UNREAD_FORWARD});
      foreach my $rule (@RULES_ARR) {
        next if (!$rule);
        my ($USER_GID, $MESSAGE_CHAPTER, $URL) = split(/:/, $rule, 3);
        if (int($USER_GID) > 0 && $user->{GID} != int($USER_GID)) {
          next;
        }
        elsif (int($MESSAGE_CHAPTER) > 0 && int($MESSAGE_CHAPTER) && $Msgs->{CHAPTER} != int($MESSAGE_CHAPTER)) {
          next;
        }
        $Msgs->message_change({
          ID         => $Msgs->{MSG_ID},
          ADMIN_READ => "0000-00-00 00:00:00",
          STATE      => 2,
          USER_READ  => "$DATE $TIME",
        });

        msgs_redirect_filter({
          UID    => $LIST_PARAMS{UID},
          LOGIN  => $user->{LOGIN},
          MSG_ID => $Msgs->{MSG_ID},
          DEL    => 1
        });

        print "Location: $URL?GID=$user->{GID}&MESSAGE_CHAPTER=$Msgs->{CHAPTER}&MSG_ID=$Msgs->{MSG_ID}", "\n\n";
        exit;
      }
    }
    $html->{NEW_MSGS} = 1;
    return '(' . (($Msgs->{UNREAD} > 0) ? $html->color_mark($Msgs->{UNREAD}, $_COLORS[6],
      { SKIP_XML => 1 }) : 0) . ')';
  }
  elsif ($attr->{AID}) {
    # Optimize msgs_permissions call due to needs only in some situations
    %msgs_permissions = %{$Msgs->permissions_list($admin->{AID})} if(!%msgs_permissions);
    my $list = $Msgs->messages_new({
      ADMIN_READ    => '0000-00-00  00:00:00',
      GID           => $admin->{GID},
      CHAPTER       => !$msgs_permissions{4} ? '_SHOW' : join(',', keys %{$msgs_permissions{4}}),
      SHOW_CHAPTERS => 1,
      COLS_NAME     => 1
    });

    my $id = 11;
    $Msgs->{UNREAD} = 0;
    $Msgs->{OPENED} = 0;
    $Msgs->{TODAY} = 0;

    foreach my $line (@{$list}) {
      next if !$line->{id};

      $id++;
      my $count = '';
      if ($line->{open_count} > 0) {
        $count =
          $html->badge($line->{admin_unread_count}, { TYPE => ($line->{admin_unread_count} > 2) ? 'badge badge-danger' : '', STYLE => "TITLE='$lang{ADMIN_UNREAD}'" })
            . $html->badge($line->{today_plan_count}, { TYPE => 'badge badge-success',  STYLE => "TITLE='$lang{TODAY_PLAN}'"  })
            . $html->badge($line->{open_count}, { TYPE => 'badge badge-info',  STYLE => "TITLE='$lang{OPEN}'" })
            . $html->badge($line->{resposible_count}, { TYPE => ($line->{resposible_count} > 0) ? 'badge badge-warning' : '', STYLE => "TITLE='$lang{RESPOSIBLE}'" });

        $Msgs->{UNREAD} += $line->{admin_unread_count};
        $Msgs->{TODAY} += $line->{today_plan_count};
        $Msgs->{OPENED} += $line->{open_count};
        $Msgs->{RESPOSIBLE} += $line->{resposible_count};
      }

      my $chapter_name = $line->{name};

      # Call decode_utf to set ut8 flag on
      $chapter_name = Encode::decode_utf8($chapter_name);
      if ($chapter_name && length($chapter_name) > 25) {
        $chapter_name = join('', @{[ split(//, $chapter_name) ]}[0 ... 24]);
        $chapter_name = $html->element('span', $chapter_name . '...', { title => $line->{name} });
      }
      # Call encode_utf to set ut8 flag off ( It makes program to fall later);
      $chapter_name = Encode::encode_utf8($chapter_name);

      $chapter_name = $chapter_name || $line->{name} || '';
      $FUNCTIONS_LIST{"$id:10:$chapter_name $count:msgs_admin:CHAPTER=$line->{id}"} = 8;
    }

    $id++;
    $FUNCTIONS_LIST{ "$id:10:$lang{RESPOSIBLE}  "
      . (($Msgs->{RESPOSIBLE} && $Msgs->{RESPOSIBLE} > 0)
      ? $html->badge($Msgs->{RESPOSIBLE}, { TYPE => 'badge badge-danger', STYLE => "TITLE='$lang{RESPOSIBLE}'" })
      : ''
    ) . ":msgs_admin:STATE=8" } = 8;

    my $msg_count = '';

    if ($Msgs->{OPENED} && $Msgs->{OPENED} > 0) {
      $msg_count = $html->badge($Msgs->{UNREAD}, { TYPE => $Msgs->{UNREAD} ? 'badge badge-danger' : '', STYLE => "TITLE='$lang{ADMIN_UNREAD}'" })
        . $html->badge($Msgs->{TODAY}, { TYPE => 'badge badge-success', STYLE => "TITLE='$lang{TODAY_PLAN}'" })
        . $html->badge($Msgs->{OPENED}, { TYPE => 'badge badge-info', STYLE => "TITLE='$lang{OPEN}'" });
    }

    my $unreg_count = '';
    $Msgs->unreg_requests_count();

    if ($Msgs->{TOTAL}) {
      $unreg_count = $html->badge($Msgs->{UNREG_COUNT}, { TYPE => 'badge badge-danger', STYLE => "title='$lang{UNREG_COUNT}'" });
    }

    my $refresh_time = $conf{MSGS_REFRESH_HEADER_MENU} || 30;

    $conf{MSGS_HEADER_MENU_DYNAMIC} //= 1;
    if (!$FORM{xml} && !$FORM{json}) {
      my $url = '';
      if ($conf{API_ENABLE}) {
        my ($proto, $host, $port) = url2parts($SELF_URL);
        $url = "$proto//$host$port/api.cgi/msgs/list?snakeCase=1&pageRows=20&clientId&" .
          "chapterName&datetime&state=0&resposibleAdminLogin&priorityId&domainId&message&" .
          "adminRead&repliesCounts&chgMsgs&delMsgs&userName&adminDisable&msgsTagsIds&" .
          "closedAdmin&watchers&planTime&total&inWork&open&unmaked&closed";
      }
      else {
        $url = "$SELF_URL?get_index=msgs_admin&STATE=0&sort=1&desc=DESC&EXPORT_CONTENT=MSGS_LIST&header=1&json=1&PAGE_ROWS=20";
      }

      # Forming JSON
      $admin->{ADMIN_MSGS} = '';
      $admin->{ADMIN_MSGS} .= qq{"HEADER":"$lang{OPEN}: $Msgs->{OPENED}",} if ($Msgs->{OPENED});
      $admin->{ADMIN_MSGS} .= qq{"BADGE":$Msgs->{OPENED},} if ($Msgs->{OPENED});
      $admin->{ADMIN_MSGS} .= $conf{MSGS_HEADER_MENU_DYNAMIC} ? qq{"UPDATE":"$url",} : qq{};
      $admin->{ADMIN_MSGS} .= qq{"REFRESH":$refresh_time,};
      $admin->{ADMIN_MSGS} .= qq{"AFTER":3};
      $admin->{ADMIN_MSGS} =~ s/\r\n|\n//gm;
      $admin->{ADMIN_MSGS} =~ s/\"/\"/gm;

      $url .= "&RESPOSIBLE=$admin->{AID}" if ($admin->{AID});

      # Forming JSON
      $admin->{ADMIN_RESPONSIBLE} = '';
      $admin->{ADMIN_RESPONSIBLE} .= qq{"HEADER":"$lang{RESPOSIBLE}: $Msgs->{RESPOSIBLE}",} if ($Msgs->{RESPOSIBLE});
      $admin->{ADMIN_RESPONSIBLE} .= qq{"BADGE":$Msgs->{RESPOSIBLE},} if ($Msgs->{RESPOSIBLE});
      $admin->{ADMIN_RESPONSIBLE} .= qq{"AID":$admin->{AID},} if ($admin->{AID});
      $admin->{ADMIN_RESPONSIBLE} .= $conf{MSGS_HEADER_MENU_DYNAMIC} ? qq{"UPDATE":"$url",} : qq{};
      $admin->{ADMIN_RESPONSIBLE} .= qq{"REFRESH":$refresh_time,};
      $admin->{ADMIN_RESPONSIBLE} .= qq{"AFTER":6};
      $admin->{ADMIN_RESPONSIBLE} =~ s/\r\n|\n//gm;
      $admin->{ADMIN_RESPONSIBLE} =~ s/\"/\"/gm;
    }

    return $msg_count, $unreg_count;
  }
  return '';
}

1;