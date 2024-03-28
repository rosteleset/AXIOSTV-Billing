package Crm::Dialogue;

use strict;
use warnings FATAL => 'all';

my ($admin, $CONF, $db);
my $Crm;
our $DATE;

#**********************************************************
=head2 new($db, $admin, $CONF, $attr)

=cut
#**********************************************************
sub new {
  my $class = shift;
  $db = shift;
  $admin = shift;
  $CONF = shift;
  my $attr = shift;

  my $self = {};

  require Crm::db::Crm;
  Crm->import();
  $Crm = Crm->new($db, $admin, $CONF);

  bless($self, $class);

  $self->{SOURCE} = lc $attr->{SOURCE} || '';
  return $self;
}

#**********************************************************
=head2 get_lead_id_by_chat_id($chat_id)

=cut
#**********************************************************
sub crm_get_lead_id_by_chat_id {
  my $self = shift;
  my ($chat_id) = @_;

  return 0 if !$chat_id || !$self->{SOURCE};

  my @search_fields = ();
  my $source = '_crm_' . $self->{SOURCE};
  $Crm->fields_list({ SQL_FIELD => $source });
  return 0 if $Crm->{TOTAL} < 1;

  push @search_fields, [ uc $source, 'STR', 'cl.' . $source, 1 ];

  my $lead_info = $Crm->crm_lead_list({
    uc $source      => $chat_id,
    SEARCH_COLUMNS  => \@search_fields,
    SKIP_RESPOSIBLE => 1,
    COLS_NAME       => 1
  });

  return 0 if ($Crm->{TOTAL} != 1);

  return $lead_info->[0]{lead_id};
}

#**********************************************************
=head2 crm_get_dialogue_id($lead_id)

=cut
#**********************************************************
sub crm_get_dialogue_id {
  my $self = shift;
  my $lead_id = shift;

  return 0 if !$self->{SOURCE};

  my $last_active_dialog = $Crm->crm_dialogues_list({
    LEAD_ID   => $lead_id,
    STATE     => '_SHOW',
    COLS_NAME => 1,
    PAGE_ROWS => 1
  });

  my $dialogue = $last_active_dialog->[0] || {};

  if ($Crm->{TOTAL} > 0 && $dialogue->{id}) {
    if ($dialogue->{state} && $dialogue->{state} eq '1') {
      $Crm->crm_dialogues_change({ ID => $dialogue->{id}, SOURCE => $self->{SOURCE}, AID => 0 });
    }
    else {
      $Crm->crm_dialogues_change({ ID => $dialogue->{id}, SOURCE => $self->{SOURCE} });
    }
    return $dialogue->{id};
  }

  $Crm->crm_dialogues_add({ LEAD_ID => $lead_id, SOURCE => $self->{SOURCE} });
  return $Crm->{errno} ? 0 : $Crm->{INSERT_ID};
}

#**********************************************************
=head2 crm_send_message($message, $attr)

=cut
#**********************************************************
sub crm_send_message {
  my $self = shift;
  my $message = shift;
  my ($attr) = @_;

  my $dialogue_id = $attr->{DIALOGUE_ID} ? $attr->{DIALOGUE_ID} :
    $attr->{LEAD_ID} ? $self->crm_get_dialogue_id($attr->{LEAD_ID}) : 0;
  return 0 if !$dialogue_id;

  $Crm->crm_dialogue_messages_add({
    MESSAGE     => $message,
    DIALOGUE_ID => $dialogue_id,
    INNER_MSG   => $attr->{INNER_MSG} || 0,
    SKIP_CHANGE => $attr->{SKIP_CHANGE} || 0
  });

  my $message_id = $Crm->{INSERT_ID};
  return $message_id if $attr->{INNER_MSG} || !$CONF->{PUSH_ENABLED};

  $Crm->crm_dialogue_info({ ID => $dialogue_id });
  return $message_id if !$Crm->{AID};

  my $aid = $Crm->{AID};
  my $source = $Crm->{SOURCE} || '';

  my $lead_info = $Crm->crm_lead_info({ ID => $Crm->{LEAD_ID} });
  my $fio = $lead_info->{FIO} || '';

  require AXbills::Sender::Core;
  AXbills::Sender::Core->import();
  my $Sender = AXbills::Sender::Core->new($db, $admin, $CONF);

  use Encode qw(encode);
  $Sender->send_message({
    AID         => $aid,
    TITLE       => $fio . ($source ? " (" . ucfirst($source) . ")" : ''),
    MESSAGE     => Encode::encode('utf-8', $message),
    SENDER_TYPE => 'Push',
    EX_PARAMS   => {
      icon => $lead_info->{_AVATAR_URL},
      url  => $CONF->{CRM_PUSH_URL} ? "$CONF->{CRM_PUSH_URL}?get_index=crm_dialogue&full=1&ID=$dialogue_id" : ''
    }
  });

  return $message_id;
}

#**********************************************************
=head2 crm_lead_by_source($sender)

=cut
#**********************************************************
sub crm_lead_by_source {
  my $self = shift;
  my ($sender) = @_;

  return 0 if !$sender->{USER_ID} || !$self->{SOURCE};

  my @search_fields = ();
  my $source = 'crm_' . $self->{SOURCE};
  my $uc_source = uc('_crm_' . $self->{SOURCE});

  $Crm->fields_list({ SQL_FIELD => '_' . $source });
  if ($Crm->{TOTAL} < 1) {
    $Crm->lead_field_add({ FIELD_ID => $source });
    return 0 if $Crm->{errno};

    $Crm->fields_add({ FIELD_TYPE => 0, SQL_FIELD => $source, NAME => ucfirst $self->{SOURCE} });

    if ($Crm->{errno}) {
      $Crm->lead_field_del({ FIELD_ID => $source });
      return 0;
    }
  }
  push @search_fields, [ $uc_source, 'STR', 'cl._' . $source, 1 ];

  $uc_source = 'EMAIL' if $self->{SOURCE} eq 'mail';
  my $lead_info = $Crm->crm_lead_list({
    $uc_source      => $uc_source eq 'EMAIL' ? $sender->{EMAIL} : $sender->{USER_ID},
    SEARCH_COLUMNS  => \@search_fields,
    SKIP_RESPOSIBLE => 1,
    COLS_NAME       => 1
  });

  return 0 if $Crm->{TOTAL} > 1;
  return $lead_info->[0]{id} if $Crm->{TOTAL} > 0;

  if ($sender->{AVATAR}) {
    $Crm->fields_list({ SQL_FIELD => '_avatar_url' });
    if ($Crm->{TOTAL} < 1) {
      $Crm->lead_field_add({ FIELD_ID => 'avatar_url', FIELD_TYPE => 3 });

      if (!$Crm->{errno}) {
        $Crm->fields_add({
          FIELD_TYPE => 3,
          SQL_FIELD  => 'avatar_url',
          NAME       => 'Avatar URL',
        });

        $Crm->lead_field_del({ FIELD_ID => 'avatar_url' }) if $Crm->{errno};
      }
    }
  }

  $uc_source = uc('_crm_' . $self->{SOURCE}) if $self->{SOURCE} eq 'mail';
  $Crm->crm_lead_add({
    FIO          => $sender->{FIO},
    PHONE        => $sender->{PHONE} || '',
    EMAIL        => $sender->{EMAIL} || '',
    $uc_source   => $sender->{USER_ID},
    _AVATAR_URL  => $sender->{AVATAR} || '',
    PRIORITY     => 1,
    CURRENT_STEP => 1
  });

  return $Crm->{INSERT_ID} || 0;
}

1;