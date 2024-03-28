package AXbills::Sender::Push;
=head1 NAME

  Send Push message

=cut

use strict;
use warnings;

use parent 'AXbills::Sender::Plugin';

use Contacts;
use AXbills::Fetcher qw(web_request);
use AXbills::Base qw(json_former);

#**********************************************************
=head2 new($conf) - constructor for FCM_PUSH

  Attributes:
    $conf

  Returns:
    object - new FCM_PUSH instance

=cut
#**********************************************************
sub new {
  my $class = shift;
  my ($conf, $attr) = @_;

  return 0 unless ($conf->{PUSH_ENABLED});

  die 'Bad firebase configurations' if (!$conf->{FIREBASE_SERVER_KEY} &&
    (!$conf->{GOOGLE_PROJECT_ID} || !$conf->{FIREBASE_KEY}));

  my $self = {
    db    => $attr->{db},
    admin => $attr->{admin},
    conf  => $conf,
  };

  $self->{Contacts} = Contacts->new($self->{db}, $self->{admin}, $conf);

  bless($self, $class);
  return $self;
}

#**********************************************************
=head2 send_message($attr) send message for http1 protocol

  Arguments:
    $attr - hash_ref
      UID        - user ID
      MESSAGE    - string. CANNOT CONTAIN DOUBLE QUOTES \"
      TO_ADDRESS - Push endpoint

  Returns:
    0 if success, 1 otherwise

=cut
#**********************************************************
sub send_message {
  my $self = shift;
  my ($attr) = @_;

  return $self->send_message_old($attr) if ($self->{conf}->{FIREBASE_SERVER_KEY});

  my $base_dir = $main::base_dir || '/usr/axbills';

  require AXbills::Google;

  my $Google = AXbills::Google->new({
    file_path => "$base_dir/Certs/google/$self->{conf}->{FIREBASE_KEY}.json",
    scope     => [ 'https://www.googleapis.com/auth/firebase.messaging', 'https://www.googleapis.com/auth/cloud-platform' ],
  });

  my $result = $Google->access_token();

  return 1 if ($result->{errno} || !$result->{access_token});

  my $receiver_type = ($attr->{AID})
    ? 'AID'
    : (($attr->{UID}) ? 'UID' : 0);

  my $title = $attr->{TITLE} || $attr->{SUBJECT} || '';
  my $action = $title =~ /(?<=#)\d+/g;

  my %req_params = (
    message => {
      token   => $attr->{CONTACT}->{value},
      data    => {
        body         => $attr->{MESSAGE},
        title        => $title,
        action       => $action ? 'message' : 'default',
        press_action => $action ? 'message' : 'default',
        %{$attr->{EX_PARAMS} || {}},
      },
      android => {
        priority     => 'high',
      }
    },
  );

  # ios block
  if ($attr->{CONTACT} && $attr->{CONTACT}->{push_type_id} && $attr->{CONTACT}->{push_type_id} == 3) {
    my $badges = $attr->{CONTACT}->{badges} + 1;

    $self->{Contacts}->push_contacts_change({
      ID     => $attr->{CONTACT}->{id} || '--',
      BADGES => $badges,
    });

    $req_params{message}{notification} = {
      body         => $attr->{MESSAGE},
      title        => $title,
    };

    $req_params{message}{apns} = {
      payload => {
        aps => {
          'mutable-content'   => 1,
          'content-available' => 1,
          badge               => $badges,
          category            => $action ? 'message' : 'default',
        }
      },
      headers => {
        'apns-priority' => '<str_>5',
      }
    };
  }

  if ($attr->{ATTACHMENTS}) {
    my @attachments = ();
    my $protocol = (defined($ENV{HTTPS}) && $ENV{HTTPS} =~ /on/i) ? 'https' : 'http';
    my $SELF_URL = (defined($ENV{HTTP_HOST})) ? "$protocol://$ENV{HTTP_HOST}/images" : '';

    foreach my $file (@{$attr->{ATTACHMENTS}}) {
      my $content = $file->{content} || '';
      next if $content !~ /FILE/ || $content !~ /AXbills\/templates/;
      my ($file_path) = $content =~ /AXbills\/templates(\/.+)/;

      push @attachments, {
        url          => $SELF_URL . $file_path,
        size         => $file->{content_size},
        name         => $file->{filename},
        content_type => $file->{content_type}
      };
    }

    $req_params{message}{data}{attachments} = \@attachments;
  }

  my $send_result = web_request("https://fcm.googleapis.com/v1/projects/$self->{conf}->{GOOGLE_PROJECT_ID}/messages:send", {
    HEADERS     => [ "Content-Type: application/json", "Authorization: Bearer $result->{access_token}" ],
    JSON_BODY   => \%req_params,
    JSON_RETURN => 1,
    METHOD      => 'POST',
    JSON_FORMER => {
      CONTROL_CHARACTERS => 1,
    }
  });

  $self->{Contacts}->push_messages_add({
    AID        => ($receiver_type eq 'AID') ? $attr->{AID} : 0,
    UID        => ($receiver_type eq 'UID') ? $attr->{UID} : 0,
    TYPE_ID    => $attr->{CONTACT} && $attr->{CONTACT}->{push_type_id} ? $attr->{CONTACT}->{push_type_id} : 0,
    TITLE      => $title || '',
    MESSAGE    => $attr->{MESSAGE},
    RESPONSE   => json_former($send_result),
    REQUEST    => json_former(\%req_params),
    STATUS     => $send_result->{error} ? 1 : 0,
    MESSAGE_ID => $attr->{MESSAGE_ID} || 0
  });

  return $send_result->{error} ? 1 : 0;
}

#**********************************************************
=head2 dry_run($attr) dry run for http 1 protocol

  Arguments:
    $attr - hash_ref

  Returns:
    0 if success, 1 otherwise

=cut
#**********************************************************
sub dry_run {
  my $self = shift;
  my ($attr) = @_;

  return $self->dry_run_old($attr) if ($self->{conf}->{FIREBASE_SERVER_KEY});

  my $base_dir = $main::base_dir || '/usr/axbills';

  require AXbills::Google;

  my $Google = AXbills::Google->new({
    file_path => "$base_dir/Certs/google/$self->{conf}->{FIREBASE_KEY}.json",
    scope     => [ 'https://www.googleapis.com/auth/firebase.messaging', 'https://www.googleapis.com/auth/cloud-platform' ],
  });

  my $result = $Google->access_token();

  return 1 if ($result->{errno} || !$result->{access_token});

  my @registration_ids = ();

  if ($attr->{TOKEN}) {
    push @registration_ids, $attr->{TOKEN};
  }
  elsif ($attr->{TOKENS}) {
    push @registration_ids, @{$attr->{TOKENS}};
  }
  else {
    return 2;
  }

  my $results = {};

  foreach my $token (@registration_ids) {
    my $send_result = web_request("https://fcm.googleapis.com/v1/projects/$self->{conf}->{GOOGLE_PROJECT_ID}/messages:send", {
      HEADERS     => [ "Content-Type: application/json", "Authorization: Bearer $result->{access_token}" ],
      JSON_BODY   => {
        validate_only => 'true',
        message => {
          token   => $token,
        }
      },
      JSON_RETURN => 1,
      METHOD      => 'POST',
      JSON_FORMER => {
        CONTROL_CHARACTERS => 1,
        BOOL_VALUES        => 1,
      }
    });

    if ($send_result->{error}) {
      push @{$results->{results}}, { error => $send_result->{error}->{message} };
    }
    else {
      push @{$results->{results}}, { name => $send_result->{name} };
    }
  }

  return $results if ($attr->{RETURN_RESULT});

  return 3 if ($results->{errno});

  ($results->{name}) ? return 0 : return 1;
}

#**********************************************************
=head2 send_message_old($attr)

  Arguments:
    $attr - hash_ref
      UID        - user ID
      MESSAGE    - string. CANNOT CONTAIN DOUBLE QUOTES \"
      TO_ADDRESS - Push endpoint

  Returns:
    0 if success, 1 otherwise

=cut
#**********************************************************
#@deprecated
sub send_message_old {
  my $self = shift;
  my ($attr) = @_;

  my $receiver_type = ($attr->{AID})
    ? 'AID'
    : (($attr->{UID}) ? 'UID' : 0);

  my $title = $attr->{TITLE} || $attr->{SUBJECT} || '';
  my $action = $title =~ /(?<=#)\d+/g;

  my %req_params = (
    to       => $attr->{CONTACT}->{value},
    data     => {
      body   => $attr->{MESSAGE},
      title  => $title,
      action => $action ? 'message' : 'default',
      %{$attr->{EX_PARAMS} || {}},
    },
    priority => 'high',
  );

  # ios block
  if ($attr->{CONTACT} && $attr->{CONTACT}->{push_type_id} && $attr->{CONTACT}->{push_type_id} == 3) {
    my $badges = $attr->{CONTACT}->{badges} + 1;

    $self->{Contacts}->push_contacts_change({
      ID     => $attr->{CONTACT}->{id} || '--',
      BADGES => $badges
    });

    $req_params{notification} = {
      body         => $attr->{MESSAGE},
      title        => $title,
      badge        => $badges,
      click_action => $action ? 'message' : 'default'
    };

    $req_params{content_available} = 'true';
  }

  my $protocol = (defined($ENV{HTTPS}) && $ENV{HTTPS} =~ /on/i) ? 'https' : 'http';
  my $SELF_URL = (defined($ENV{HTTP_HOST})) ? "$protocol://$ENV{HTTP_HOST}/images" : '';
  my @attachments = ();

  foreach my $file (@{$attr->{ATTACHMENTS}}) {
    my $content = $file->{content} || '';
    next if $content !~ /FILE/ || $content !~ /AXbills\/templates/;
    my ($file_path) = $content =~ /AXbills\/templates(\/.+)/;

    push @attachments, {
      url          => $SELF_URL . $file_path,
      size         => $file->{content_size},
      name         => $file->{filename},
      content_type => $file->{content_type}
    };
  }

  $req_params{attachments} = \@attachments;

  my $firebase_key = $self->{conf}->{FIREBASE_SERVER_KEY} || '';

  my $result = web_request('https://fcm.googleapis.com/fcm/send', {
    HEADERS     => [ "Content-Type: application/json", "Authorization: key=$firebase_key" ],
    JSON_BODY   => \%req_params,
    JSON_RETURN => 1,
    METHOD      => 'POST',
    JSON_FORMER => {
      CONTROL_CHARACTERS => 1,
      BOOL_VALUES        => 1,
    }
  });

  return 3 if ($result->{errno});

  if (!$result->{success} && $result->{results}->[0]->{error}) {
    $self->{Contacts}->push_contacts_del({
      ID => $attr->{CONTACT}->{id} || '--',
    });

    return 1;
  }

  $self->{Contacts}->push_messages_add({
    AID        => ($receiver_type eq 'AID') ? $attr->{AID} : 0,
    UID        => ($receiver_type eq 'UID') ? $attr->{UID} : 0,
    TYPE_ID    => $attr->{CONTACT} && $attr->{CONTACT}->{push_type_id} ? $attr->{CONTACT}->{push_type_id} : 0,
    TITLE      => $title || '',
    MESSAGE    => $attr->{MESSAGE},
    RESPONSE   => json_former($result),
    REQUEST    => json_former(\%req_params),
    STATUS     => $result->{success} ? 0 : 1,
    MESSAGE_ID => $attr->{MESSAGE_ID} || 0
  });

  ($result->{success}) ? return 0 : return 1;
}

#**********************************************************
=head2 dry_run_old($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    0 if success, 1 otherwise

=cut
#**********************************************************
#@deprecated
sub dry_run_old {
  my $self = shift;
  my ($attr) = @_;

  my @registration_ids = ();

  if ($attr->{TOKEN}) {
    push @registration_ids, $attr->{TOKEN};
  }
  elsif ($attr->{TOKENS}) {
    push @registration_ids, @{$attr->{TOKENS}};
  }
  else {
    return 2;
  }

  my $firebase_key = $self->{conf}->{FIREBASE_SERVER_KEY} || '';

  my $result = web_request('https://fcm.googleapis.com/fcm/send', {
    HEADERS     => [ "Content-Type: application/json", "Authorization: key=$firebase_key" ],
    JSON_BODY   => {
      registration_ids => \@registration_ids,
      dry_run          => 'true'
    },
    JSON_RETURN => 1,
    METHOD      => 'POST',
    JSON_FORMER => {
      CONTROL_CHARACTERS => 1,
      BOOL_VALUES        => 1,
    }
  });

  return $result if ($attr->{RETURN_RESULT});

  return 3 if ($result->{errno});

  ($result->{success}) ? return 0 : return 1;
}

1;
