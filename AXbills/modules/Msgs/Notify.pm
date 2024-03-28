package Msgs::Notify;
=head1 NAME

  Notify admins and users

=cut

use strict;
use warnings FATAL => 'all';

use AXbills::Base qw(sendmail _bp);
use AXbills::Sender::Core;
use Users;

require AXbills::Misc;

our (
  %lang,
  $ui,
  %FORM,
  $user,
  $DATE,
  $TIME,
);

our AXbills::HTML $html;

my ($db, $admin, $CONF);
my Msgs $Msgs;
my $Sender;
my $users;

#**********************************************************
=head2 new($db, $admin, $CONF, $attr)

=cut
#**********************************************************
sub new {
  my $class = shift;
  my $attr;
  ($db, $admin, $CONF, $attr) = @_;

  my $self = {};

  if($attr->{LANG}) {
    %lang = %{$attr->{LANG}};
  }

  if($attr->{HTML}) {
    $html = $attr->{HTML};
    %FORM = %{$html->{HTML_FORM} || {}};
  }

  $Msgs = Msgs->new($db, $admin, $CONF);
  $Sender = AXbills::Sender::Core->new($db, $admin, $CONF);
  $users = Users->new($db, $admin, $CONF);

  bless($self, $class);
}

#**********************************************************
=head2 notify_admins($attr)

  Arguments:
    $attr
      STATE
      MSGS
      MSG_ID
      SENDER_AID
      SEND_TO_AID
      NEW_RESPONSIBLE
      AID

  Results:

=cut
#**********************************************************
sub notify_admins {
  my $self = shift;
  my ($attr) = @_;

  my $message_id = $attr->{MSG_ID} || $Msgs->{INSERT_ID} || '--';
  my $reply_id = $Msgs->{REPLY_ID} || '--';

  my $site = '';
  my $preview_url_without_message_id = '';
  my $referer = ($CONF->{BILLING_URL} || $ENV{HTTP_REFERER} || '');
  if ( $referer && $referer =~ /(https?:\/\/[a-zA-Z0-9:\.\-]+)\/?/g ) {
    $site = $1 || '';
    $preview_url_without_message_id = $site . "/admin/index.cgi?get_index=msgs_admin&full=1&chg=";
  }

  my $message_info = $Msgs->message_info($message_id);
  return 0 if $Msgs->{errno} || (!$attr->{AID} && !$message_info->{RESPOSIBLE});

  my $responsible_aid = $message_info->{RESPOSIBLE} || q{};
  return 1 if ($attr->{SENDER_AID} && $attr->{SENDER_AID} eq $responsible_aid && !$attr->{NEW_RESPONSIBLE});

  my $subject = ($message_info->{SUBJECT} || $FORM{SUBJECT} || q{});
  my $message = $FORM{MESSAGE} || $FORM{REPLY_TEXT} || $attr->{MESSAGE} || $message_info->{MESSAGE} || '';
  $message = ($message_info->{MESSAGE} || '') if ($attr->{NEW_RESPONSIBLE});

  # Get status name
  my $state_msg = '';
  my $status_name = $message_info->{STATE} || $attr->{STATE} || $FORM{STATE} || 0;
  if (defined $message_info->{STATE}) {
    $Msgs->status_list({
      ID          => '_SHOW',
      NAME        => '_SHOW',
      LIST2HASH   => 'id,name',
      STATUS_ONLY => 1
    });

    if (!$Msgs->{errno}) {
      my $status_hash = $Msgs->{list_hash};
      $status_name = $status_hash->{$message_info->{STATE}} || '';
      $status_name = ::_translate($status_name);
      $state_msg = "\n ($lang{STATE} : $status_name)";
    }
  }

  my $ATTACHMENTS = $attr->{ATTACHMENTS} || [];
  my $RESPONSIBLE = $message_info->{RESPONSIBLE_NAME} || $lang{NO};
  my $preview_url = ($preview_url_without_message_id && $message_id ne '--')
    ? $preview_url_without_message_id . $message_id : undef;
  $preview_url .= "&UID=$message_info->{UID}" if $message_info->{UID} && $preview_url;

  my $mail_message = $html->tpl_show(::_include('msgs_email_notify', 'Msgs'), {
    SITE        => $site,
    LOGIN       => $message_info->{LOGIN} || $FORM{LOGIN} || $ui->{LOGIN} || $user->{LOGIN} || '',
    ADMIN       => ($FORM{INNER_MSG}) ? "$lang{ADMIN}: $admin->{A_LOGIN} (" . ($admin->{A_FIO} || q{}) . '}' : '',
    UID         => $message_info->{UID} || $FORM{UID} || '',
    DATE        => $main::DATE,
    TIME        => $main::TIME,
    ID          => $message_id . (($reply_id && $reply_id ne '--') ? " / $reply_id" : ''),
    RESPONSIBLE => $RESPONSIBLE,
    SUBJECT     => $subject,
    STATUS      => $status_name,
    MESSAGE     => $message,
    ATTACHMENT  => ($FORM{FILE_UPLOAD} && $FORM{FILE_UPLOAD}->{filename}) ? $FORM{FILE_UPLOAD}->{filename} : q{},
    SUBJECT_URL => $preview_url,
  }, { OUTPUT2RETURN => 1 });

  $subject = $attr->{NEW_RESPONSIBLE} ? $lang{YOU_HAVE_BEEN_SET_AS_RESPONSIBLE_IN} . " '" . $subject . "'"
    : "#$message_id " . $lang{YOU_HAVE_NEW_REPLY} . " '" . $subject . "'" . $state_msg;
  my $aid = $attr->{NEW_RESPONSIBLE} ? $attr->{AID} : ($responsible_aid || $attr->{SEND_TO_AID});

  my $msgs_permissions = $Msgs->permissions_list($aid);
  return 1 if $msgs_permissions->{4} && !$msgs_permissions->{4}{$message_info->{CHAPTER}};
  
  if (!$attr->{NEW_RESPONSIBLE}) {
    return 1 if !$msgs_permissions->{5} || !$msgs_permissions->{6}{$message_info->{CHAPTER}};
  }

  $Sender->send_message_auto({
    AID         => $aid,
    SUBJECT     => $subject,
    MESSAGE     => $message,
    MAIL_TPL    => $mail_message,
    ATTACHMENTS => ($#{$ATTACHMENTS} > -1) ? $ATTACHMENTS : undef,
    ACTIONS     => $preview_url,
    MAIL_HEADER => [ "X-ABillS-Msg-ID: $message_id", "X-ABillS-REPLY-ID: $reply_id", "Content-Type: text/html;" ],
    MAKE_REPLY  => $message_id,
    LANG        => \%lang,
    PARSE_MODE  => 'HTML',
    ALL         => 1,
    SEND_TYPES  => join(',', keys %{$msgs_permissions->{5}})
  });

  return 1;
}

#**********************************************************
=head2 msgs_notify_user($attr)

  Arguments:
    $attr
      REPLY_ID
      MSGS
      SEND_TYPE
         1 - Msgs delivery tpl
         
      To notify single user:
      UID
      MSG_ID
      MESSAGE
      
      To notify different users with different texts
      MESSAGES_BATCH - hash_ref
        UID => {
          MSG_ID  => integer,
          MESSAGE => string
        }

  Results:

=cut
#**********************************************************
sub notify_user {
  my $self = shift;
  my ($attr) = @_;
  return 0 if ($attr->{INNER_MSG} || $attr->{REPLY_INNER_MSG});

  if ($attr->{MESSAGES_BATCH} && ref $attr->{MESSAGES_BATCH}) {
    # Call self for each message id
    my %msg_id_for_user = %{$attr->{MESSAGES_BATCH}};

    foreach my $_uid (sort keys %msg_id_for_user) {
      $self->notify_user({
        UID            => $_uid,
        MSG_ID         => $msg_id_for_user{$_uid}->{MSG_ID},
        %{$attr},
        MESSAGES_BATCH => undef,
      });
    }

    return 1;
  }

  my $message_id = $attr->{MSG_ID};
  my $reply_id = $attr->{REPLY_ID} || 0;
  my $message_params = $self->_msgs_notify_user_collect_message_content($message_id, $attr);
  return 0 if (!$message_params);

  my $message = $message_params->{MESSAGE};
  my $subject = $message_params->{SUBJECT};
  my $state   = $message_params->{STATE};
  my $uid   = $message_params->{UID};

  my $users_list = $users->list({
    LOGIN     => '_SHOW',
    FIO       => '_SHOW',
    EMAIL     => '_SHOW',
    PHONE     => '_SHOW',
    UID       => $attr->{UID} || $uid || '-1',
    COLS_NAME => 1
  });

  my $send_type = $attr->{SEND_TYPE} || 0;
  my $message_tpl = ($send_type == 1) ? 'msgs_email_delivery' : 'msgs_email_notify';

  # Make view url
  my $preview_url_without_message_id = '';
  my $site = $CONF->{CLIENT_INTERFACE_URL} || $CONF->{BILLING_URL} || $ENV{HTTP_REFERER} || q{};
  $site =~ s/admin\/?//;
  if ($site && $site =~ m/(https?:\/\/[a-zA-Z0-9:\.\-]+)\//g ) {
    $site = $1 || '';
    $preview_url_without_message_id = $site . "/index.cgi?get_index=msgs_user&ID=";
  }

  # Make attachments
  my $ATTACHMENTS = $attr->{ATTACHMENTS} || [];

  foreach my $user_info  ( @{$users_list} ) {

    my $preview_url = ($preview_url_without_message_id && $message_id ne '--')
      ? $preview_url_without_message_id . $message_id : undef;

    my $mail_message = $html->tpl_show(::_include($message_tpl, 'Msgs'), {
      SITE        => $site,
      DATE        => $DATE,
      TIME        => $TIME,
      LOGIN       => $user_info->{login},
      UID         => $user_info->{uid},
      ID          => $message_id,
      ATTACHMENT  => $attr->{FILE_UPLOAD}->{filename} || '',
      SUBJECT_URL => $preview_url,
      %$message_params,
      SUBJECT     => $subject,
      STATUS      => $state,
      MESSAGE     => $message,
    }, { OUTPUT2RETURN => 1 });

    $subject = "#$message_id ".$lang{YOU_HAVE_NEW_REPLY} . " '" . $subject . "'";

    $Sender->send_message_auto({
      UID         => $user_info->{uid},
      SUBJECT     => $subject,
      MESSAGE     => $message,
      MAIL_TPL    => $mail_message,
      ATTACHMENTS => ($#{$ATTACHMENTS} > -1) ? $ATTACHMENTS : undef,
      ACTIONS     => $preview_url,
      MAIL_HEADER => [ "X-ABillS-Msg-ID: $message_id", "X-ABillS-REPLY-ID: $reply_id" ],
      MAKE_REPLY  => $message_id,
      LANG        => \%lang,
      PARSE_MODE  => 'HTML',
      ALL         => 1,
      # USER_EMAIL  => !$CONF->{CONTACTS_NEW} ? $user_info->{email} : '',
      SEND_TYPE   => $attr->{SEND_TYPE}
    });

    $html->message('err', $lang{ERROR},  "[$Sender->{errno}] $Sender->{errstr}") if $Sender->{errno};
  }

  return 1;
}

#**********************************************************
=head2 _msgs_notify_user_collect_message_content($message_id, $attr)

   Arguments:
     $message_id
     $attr

   Returns:


=cut
#**********************************************************
sub _msgs_notify_user_collect_message_content {
  my $self = shift;
  my ($message_id, $attr) = @_;
  my $msgs_status = ::msgs_sel_status({ HASH_RESULT => 1 });

  my $subject = ($attr->{SUBJECT} || '') . (($FORM{REPLY_SUBJECT}) ? ' / ' . $FORM{REPLY_SUBJECT} : '');
  my $message = $attr->{MESSAGE} || $attr->{REPLY_TEXT};
  my $state = $attr->{STATE} || ($attr->{STATE_ID} && $msgs_status->{$attr->{STATE_ID}}
    ? $msgs_status->{$attr->{STATE_ID}}
    : ''
  );

  my $responsible_name = $attr->{RESPOSIBLE_ADMIN_LOGIN};

  my $uid = $attr->{UID};

  my $is_inner_msg = $attr->{INNER_MSG};
  return 0 if ( $is_inner_msg );

  my $reply_id = $attr->{REPLY_ID};

  my $got_required_fields_from_attr = ($subject && $message && defined($state) && $uid && defined $responsible_name);

  # If no message id, check for required fields
  if ( !$message_id ) {
    if ( $got_required_fields_from_attr ) {
      # Can send with wrong id
      $message_id = '--';
    }
    else {
      # Don't have enough params, return
      _bp('msgs_notify_user', "don't have enough params") if ( $attr->{DEBUG} );
      return 0;
    }
  }
  elsif ( !$got_required_fields_from_attr ) {
    # Create new object to fix it's dirty state
    my $msg = Msgs->new($db, $admin, $CONF);
    $msg->message_info($message_id);
    return 0 if ( $msg->{errno} || $msg->{INNER_MSG} );

    $subject = $msg->{SUBJECT};
    $message = $msg->{MESSAGE};
    $uid = $msg->{UID};
    $state = ($msg->{STATE} && $msgs_status->{$msg->{STATE}}
      ? $msgs_status->{$msg->{STATE}}
      : $msg->{STATE}
    );
    my $responsible_id = $msg->{RESPOSIBLE};
    $responsible_name = ($responsible_id)
      ? do {
        my $list = $admin->list({ AID => $responsible_id, COLS_NAME => 1 });
        my $adm = ($admin->{TOTAL} && $list)
          ? $list->[0]->{name} || $list->[0]->{login}
          : '';
        $adm;
      }
      : '';

    if ( $reply_id ) {
      my $replies_for_id = $Msgs->messages_reply_list({
        ID        => $reply_id,
        MSG_ID    => $message_id,
        INNER_MSG => '0',
        PAGE_ROWS => 1,
        COLS_NAME => 1,
      });

      my $reply = $replies_for_id->[0];

      if ( $reply && ref $reply ) {
        return 0 if ( $reply->{inner_msg} );
        $message = $reply->{text};
      }
    }
  }

  if ( !$uid ) {
    _bp('msgs_notify_user', "don't have enough params") if ( $attr->{DEBUG} );
    return 0;
  };

  if ( $attr->{SURVEY_ID} ) {
    $message = ::msgs_survey_show({
      SURVEY_ID        => $attr->{SURVEY_ID},
      MSG_ID           => $message_id,
      SHOW_SURVAY_TEXT => 1,
      MAIN_MSG         => 1,
    });
  }

  return {
    MESSAGE    => $message,
    SUBJECT    => $subject,
    STATE      => $state,
    RESPOSIBLE => $responsible_name,
    UID        => $uid,
  };
}


1;