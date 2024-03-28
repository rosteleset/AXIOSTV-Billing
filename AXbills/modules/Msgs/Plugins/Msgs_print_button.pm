package Msgs::Plugins::Msgs_print_button;

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
    PLUGIN_NAME => 'Msgs_print_button'
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
    NAME     => "Print ticket button",
    POSITION => 'RIGHT',
    DESCR    => $lang->{PRINT_TICKER_BUTTON}
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

  return '' if !$msgs_permissions->{1}{14};

  $attr->{index} ||= $attr->{qindex};
  return '' if !$attr->{index};

  $attr->{UID} ||= 0;
  $Msgs->{ID} ||= 0;

  if ($attr->{PLUGIN} && $attr->{PLUGIN} eq $self->{PLUGIN_NAME}) {
    msgs_ticket_form($attr);
    return { RETURN_VALUE => 1 };
  }

  my $url = "qindex=$attr->{index}&UID=$attr->{UID}&ID=$Msgs->{ID}&header=2";
  $url .= ($CONF->{DOCS_PDF_PRINT}) ? '&pdf=1' : '';
  $url .= "&PLUGIN=$self->{PLUGIN_NAME}";

  return $html->button('', $url, {
    class     => 'btn btn-primary group-btn',
    ICON      => 'fas fa-print print',
    TITLE     => $lang->{PRINT},
    ex_params => 'target=new, data-button-group=1'
  });
}

#**********************************************************
=head2 msgs_ticket_form() - Print information about message

  Arguments:
    $attr
      UID
      MSG_PRINT_ID
=cut
#**********************************************************
sub msgs_ticket_form {
  my ($attr) = @_;

  require Users;
  my $users = Users->new($db, $admin, $CONF);
  my $user_main_info = ();

  if ($attr->{UID}) {
    $user_main_info = $users->info($attr->{UID}, { SHOW_PASSWORD => 1 });
    $users->pi({ UID => $attr->{UID} });
  }

  my $msg_info = _msgs_user_msg_info({
    MSG_ID          => $attr->{ID},
    MSG_REPLYS_SHOW => 1,
    %{$attr}
  });

  $attr->{TABLE} = '';
  $attr->{TABLE} .= $html->element('div', $lang->{MESSAGE} . " #" . 1, { class => 'col-xs-12 border' });
  $attr->{TABLE} .= $html->element('div', $msg_info->{MESSAGE}, { class => 'col-xs-12 border' });

  $msg_info->{MESSAGE} .= ' ';
  my @arr = $msg_info->{MESSAGE} =~ m/(.{1,90}\s)/g;
  my %messages = (
    text1  => $arr[0],
    text2  => $arr[1],
    text3  => $arr[2],
    text4  => $arr[3],
    text5  => $arr[4],
    text6  => $arr[5],
    text7  => $arr[6],
    text8  => $arr[7],
    text9  => $arr[8],
    text10 => $arr[9],
    text11 => $arr[10],
    text12 => $arr[11],
  );

  for (my $i = 1; $i <= $msg_info->{TOTAL_REPLIES}; $i++) {
    $attr->{TABLE} .= $html->element('div', $lang->{MESSAGE} . " #" . ($i + 1), { class => 'col-xs-6 border' });
    $attr->{TABLE} .= $html->element('div', $msg_info->{MSG_REPLYS}->{'REPLY_CREATOR_ID_' . $i}, { class => 'col-xs-3 border' });
    $attr->{TABLE} .= $html->element('div', $msg_info->{MSG_REPLYS}->{'REPLY_DATE_' . $i}, { class => 'col-xs-3 border' });
    $attr->{TABLE} .= $html->element('div', $msg_info->{MSG_REPLYS}->{'TEXT_' . $i}, { class => 'col-xs-12 border' })
  }

  $attr = { %{$attr}, %{$msg_info}, $user_main_info ? %{$user_main_info} : (), %{$users} };

  print $html->tpl_show(main::_include("msgs_ticket_form", 'Msgs',), { %{$attr}, %messages },);

  return 1;
}

#**********************************************************
=head2 _msgs_user_msg_info() Get information tags about user msg for docs

  Arguments:
    $attr
      MSG_ID - message id
      MSG_REPLYS_SHOW - Show message relys

  Returns:
    $hash-reff
      'MSG_DATE_CREATE'  => '2017-02-01 23:31:11',
      'MSG_SUBJECT'      => 'Надо установать модудь',
      'MSG_CHAPTER_NAME' => 'Установка оборудован',
      'MSG_STATE'        => 'Ждём ответ от пользователя',
      'MSG_PRIORITY'     => 'Нормальный'
      'RESPOSIBLE'       => 'axbills'
      'TOTAL_REPLIES'    => '2'
      'MSG_REPLY'        =>
        {
          'REPLY_CREATOR_ID_1' => 'axbills',
          'REPLY_CREATOR_ID_2' => 'axbills',
          'REPLY_DATE_1'       => '2017-03-09 17:13:27',
          'REPLY_DATE_2'       => '2017-03-09 17:13:53'
        }
=cut
#**********************************************************
sub _msgs_user_msg_info {
  my ($attr) = @_;

  my $priority_colors = $attr->{PRIORITY_COLORS} || ();
  my $priority = $attr->{PRIORITY_ARRAY} || ();

  my %result_hash = ();
  my $msg_info = $attr;

  require Admins;
  Admins->import();
  my $Admins = Admins->new($db, $admin, $CONF);
  $msg_info->{RESPOSIBLE} = $msg_info->{RESPOSIBLE} ? $msg_info->{RESPOSIBLE} : '';

  my $admin_list = $Admins->list({
    AID       => $msg_info->{RESPOSIBLE} . ';' . $msg_info->{AID},
    COLS_NAME => 1,
  });

  map $result_hash{RESPOSIBLE} = $_->{login}, @{$admin_list};

  $result_hash{MSG_DATE_CREATE} = $msg_info->{DATE};
  $result_hash{MSG_SUBJECT} = $msg_info->{SUBJECT};
  $result_hash{MSG_STATE} = $Msgs->status_info($msg_info->{STATE});
  $result_hash{MSG_STATE} = main::_translate($result_hash{MSG_STATE}->{NAME});
  $result_hash{MSG_PRIORITY} = main::_translate($priority->[$msg_info->{PRIORITY}]);
  $result_hash{MSG_CHAPTER_NAME} = $msg_info->{CHAPTER_NAME};
  $result_hash{MESSAGE} = $msg_info->{MESSAGE};

  if ($attr->{MSG_REPLYS_SHOW}) {
    ($result_hash{MSG_REPLYS}, $result_hash{TOTAL_REPLIES}) = _msgs_msg_reply_list_info($attr);
  }

  return \%result_hash;
}

#**********************************************************
=head2 _msgs_msg_reply_list_info() Get information tags about user msg replys for docs

  Arguments:
    $attr
      MSG_ID - message id

  Returns:
    1.$hash-reff
      'REPLY_CREATOR_ID_1' => 'axbills',
      'REPLY_CREATOR_ID_2' => 'axbills',
      'REPLY_DATE_1' => '2017-03-09 17:13:27',
      'REPLY_DATE_2' => '2017-03-09 17:13:53'
    2.$TOTAL_REPLYS
=cut
#**********************************************************
sub _msgs_msg_reply_list_info {
  my ($attr) = @_;

  my %result_hash = ();

  my $list = $Msgs->messages_reply_list({
    MSG_ID    => $attr->{MSG_ID},
    COLS_NAME => 1
  });

  my $total_replies = 0;

  foreach my $reply (@{$list}) {
    $total_replies++;
    $result_hash{'REPLY_CREATOR_ID_' . $total_replies} = $reply->{creator_id};
    $result_hash{'REPLY_DATE_' . $total_replies} = $reply->{datetime};
    $result_hash{'TEXT_' . $total_replies} = $reply->{text};
  }

  return(\%result_hash, $total_replies);
}


1;
