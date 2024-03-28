=head2

  Msgs push message

=cut

use strict;
use warnings FATAL => 'all';

our(
  $db,
  %conf,
  $admin,
  $html,
  %lang
);

#**********************************************************
=head2 msgs_register_push_client($attr)

  Arguments:
    $attr
      UID


  Returns:
    1
=cut
#**********************************************************
sub msgs_register_push_client {
  my ($attr) = @_;

  my $client_id = $attr->{UID} || $attr->{AID} || do {
    print qq{ {"result": "error", "message" : "No user given. Auth failed?"} };
    return 0;
  };
  my $type = ($attr->{UID}) ? '0' : '1';

  require Contacts;
  Contacts->import();
  my $Contacts = Contacts->new($db, $admin, \%conf);

  if ( $FORM{unsubscribe} ) {
    my $result = 0;

    $Contacts->push_contacts_del({
      TYPE      => $type,
      CLIENT_ID => $client_id,
      ID        => $FORM{CONTACT_ID}
    });

    my $result_str = !$Contacts->{errno} ? 'ok' : 'error';
    print qq{ {"result": "$result_str", "id" : "$client_id", "registration_id" : "unsubscribe"} };
    return $result;
  }

  my $reg_id = $FORM{ENDPOINT};

  if ( !defined $reg_id ) {
    print qq{ {"result": "error", "message" : "No required args : ENDPOINT "} };
    return 0;
  };


  # First check we don't have same endpoint in table
  my $new_contact_id = undef;
  my $contacts_with_this_reg_id = $Contacts->push_contacts_list({
    CLIENT_ID => $client_id,
    ENDPOINT  => $reg_id,
    #    AUTH      => $FORM{AUTH},
  });

  if ( $contacts_with_this_reg_id && ref $contacts_with_this_reg_id eq 'ARRAY' && scalar @{$contacts_with_this_reg_id} > 0 ) {
    $new_contact_id = $contacts_with_this_reg_id->[0]->{id};
  }
  else {
    $new_contact_id = $Contacts->push_contacts_add({
      TYPE      => $type,
      CLIENT_ID => $client_id,
      ENDPOINT  => $reg_id,
      #    AUTH      => $FORM{AUTH},
      #    KEY       => $FORM{KEY}
    });
  }

  my $result_str = !$Contacts->{errno} ? 'ok' : 'error';
  print qq{ {"result": "$result_str", "id" : "$client_id", "contact_id" : "$new_contact_id"} };

  return 1;
}

#**********************************************************
=head2 msgs_push_message_request($contact_id)

=cut
#**********************************************************
sub msgs_push_message_request {
  my ($contact_id) = @_;

  return 0 unless ( $contact_id );

  require Contacts;
  Contacts->import();
  my $Contacts = Contacts->new($db, $admin, \%conf);

  my $messages = $Contacts->push_messages_list({
    CONTACT_ID => $contact_id,
    TITLE      => '_SHOW',
    MESSAGE    => '_SHOW',
    CREATED    => '_SHOW',
    SORT       => 'created',
    PAGE_ROWS  => 1
  });

  if ( !$Contacts->{errno} && $Contacts->{TOTAL} > 0 ) {
    my $message = $messages->[0];
    $message->{title} //= '';
    $message->{message} //= '';

    my $icon = $conf{PUSH_ICON} || '/img/axbills-120x120.jpg';

    print qq{ {"message" : "$message->{message}", "title" : "$message->{title}", "icon" : "$icon"} };

    $Contacts->push_messages_del({ ID => $messages->{id} });

    return 1;
  }

  print qq{ { "error" : "error retrieving messages" } };
  return 0;
}

#**********************************************************
=head2 msgs_clear_push_messages()

=cut
#**********************************************************
sub msgs_clear_push_messages {

  require Contacts;
  Contacts->import();
  my $Contacts = Contacts->new($db, $admin, \%conf);

  my $outdated = $Contacts->push_messages_list({
    OUTDATED => 1
  });
  _error_show($Contacts);

  my @outdated_ids = map {$_->{id}} @{$outdated};

  $Contacts->push_messages_del({ ID => join(',', @outdated_ids) });
  _error_show($Contacts);

  return 1;
}


1;