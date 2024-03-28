package AXbills::Sender::Core;

=head1 NAME

  Sender core

=head1 DESCRIBE

  ERROR CODES:

=head1 SYNOPSIS

  use AXbills::Sender::Core;

  my $Sender = AXbills::Sender::Core->new($db, $admin, \%conf);

  $Sender->send_message({
    UID     => 1,
    SUBJECT => 'Hello',
    MESSAGE => 'Hello John'
  });

=head1 ERROR CODES

   1 => "Can't load plugin $send_type \n";
   2 => "No contact",
   3 =>

=cut

use strict;
use warnings FATAL => 'all';

use AXbills::Sender::Plugin;
use AXbills::Base qw(in_array mk_unique_value);

my Contacts $Contacts;

our ($base_dir);

our %PLUGIN_NAME_FOR_TYPE_ID = (
  0  => 'Browser',
  1  => 'Sms',
  # 2  => 'Sms',
  #  3  => 'Web redirect' # Old skype 'Skype',
  #  4  => 'ICQ',
  5  => 'Viber_bot',
  6  => 'Telegram',
  #  7  => 'Facebook',
  #  8  => 'VK',
  9  => 'Mail',
  10 => 'Push',
  11 => 'Hyber',
  12 => 'XMPP',
  13 => 'Iptv_message',
  14 => 'Viber',
  15 => 'Facebook',
  16 => 'Instagram',
);
our %TYPE_ID_FOR_PLUGIN_NAME = reverse %{PLUGIN_NAME_FOR_TYPE_ID};

# This are types that can't get contacts via TO_ADDRESS
my @special_contact_types = qw(
  Push
  Browser
);

#**********************************************************
=head2 new($db, $admin, $CONF, $attr)

  Arguments:
    $db
    $admin
    $CONF

    $attr
      SENDER_TYPE - preloads given sender plugin
      SELF_URL
      DOMAIN_ID
      BASE_DIR


=cut
#**********************************************************
sub new {
  my $class = shift;
  my ($db, $admin, $CONF, $attr) = @_;

  # Sender soft check designed to fix load performance issues (around 60-200 ms)
  # with all Senders when it's far from needed.
  # When your rule for Sender is complex for load - skip that, and check by loading.
  # (Example: Sms, Iptv)
  # Recommended for information purposes.

  my $soft_check = {
    Viber_bot => sub { $CONF->{VIBER_BOT_NAME} },
    Telegram  => sub { $CONF->{TELEGRAM_BOT_NAME} },
    Push      => sub { $CONF->{FIREBASE_SERVER_KEY} || ($CONF->{GOOGLE_PROJECT_ID} && $CONF->{FIREBASE_KEY}) },
    Hyber     => sub { $CONF->{GMS_WORLDWIDE_CLIENT_ID} },
    Viber     => sub { ($CONF->{SMS_OMNICELL_VIBER} || $CONF->{SMS_TURBOSMS_VIBER}) },
    Facebook  => sub { $CONF->{FACEBOOK_ACCESS_TOKEN} },
    Instagram => sub { $CONF->{FACEBOOK_ACCESS_TOKEN} },
  };

  my $self = {
    conf       => $CONF,
    self_url   => $attr->{SELF_URL} || q{},
    domain_id  => $attr->{DOMAIN_ID} || $CONF->{DOMAIN_ID} || 0,
    db         => $db,
    admin      => $admin,
    debug      => $attr->{DEBUG} || $CONF->{SENDER_DEBUG} || 0,
    soft_check => $soft_check
  };

  bless($self, $class);

  if ( $attr->{SENDER_TYPE} && $self->sender_load($attr->{SENDER_TYPE}, $attr) ) {
    $self->{SENDER_TYPE} = $attr->{SENDER_TYPE};
  }

  $base_dir = $attr->{BASE_DIR} if $attr->{BASE_DIR};

  if ($db) {
    require Contacts;
    Contacts->import();
    $Contacts = Contacts->new($db, $admin, $CONF);
  }

  return $self;
}

#**********************************************************
=head2 load_sender($attr)

  Arguments:

  Returns:
    $self

=cut
#**********************************************************
sub sender_load {
  my $self = shift;
  my ($sender_type, $attr) = @_;

  $base_dir //= $self->{conf}{base_dir} || '/usr/axbills';
  return if ( !$sender_type || !-f $base_dir . "/lib/AXbills/Sender/$sender_type.pm" );

  eval {
    # Require
    my $name = "AXbills::Sender::$sender_type";
    my $path = "AXbills/Sender/$sender_type.pm";
    require $path;
    $name->import();

    # Initialize
    my $loaded_plugin = $name->new($self->{conf}, { %{$attr}, db => $self->{db}, admin => $self->{admin} });

    return 0 if ( !$loaded_plugin );

    if( ! $loaded_plugin->{conf}) {
      $loaded_plugin->{conf}=$self->{conf};
    }

    # Save
    $self->{$sender_type} = $loaded_plugin;
  };
  if ( $@ ) {
    if ( $self->{debug} || $attr->{SENDER_DEBUG} ) {
      print "Content-Type: text/html\n\n";
      print $@;
      print "<br/>\n"
    }
    return 0;
  }

  return 1;
}

#**********************************************************
=head2 send_message($attr)

  Arguments:
    $attr
      AID|UID - message receiver ID

      SENDER_TYPE - bind send to exact type
      TO_ADDRESS  - if given, should be SENDER_TYPE contact value

      MESSAGE
      PRIORITY_ID
      SUBJECT

  Returns:
    result_hash_ref

=cut
#**********************************************************
sub send_message {
  my $self = shift;
  my ($attr) = @_;

  my $send_type = $attr->{SENDER_TYPE} || $self->{SENDER_TYPE} || '';
  $attr->{MESSAGE_ID} = $attr->{MESSAGE_ID} || mk_unique_value(8, { SYMBOLS => '0123456789' });

  if ( $send_type =~ /\d+/ ) {
    $send_type = $PLUGIN_NAME_FOR_TYPE_ID{$send_type};
  }

  if ( !exists $self->{$send_type} ) {
    $self->sender_load($send_type, $attr);
    if ( !$self->{$send_type} ) {
      $self->{errstr} = "Can't load plugin: $send_type \n";
      $self->{errno} = 1;
      print $self->{errstr} if ( $self->{debug} );
      return 0;
    }
  }

  my @contacts;
  if ($attr->{TO_ADDRESS} && exists $TYPE_ID_FOR_PLUGIN_NAME{$send_type} && !in_array($send_type, \@special_contact_types)) {
    @contacts = map {
      {
        value   => $_,
        type_id => $TYPE_ID_FOR_PLUGIN_NAME{$send_type}
      };
    } split (',\s?', $attr->{TO_ADDRESS});
  }
  else {
    @contacts = $self->get_contacts_for({ %{$attr}, SENDER_TYPE => $send_type, ALL => 1 });
  }

  if (!@contacts || !$contacts[0]) {
    $self->{errstr} = "NO_CONTACT";
    $self->{errno} = 2;
    print $self->{errstr} if ($self->{debug});
    return 0;
  }

  if ($self->{debug}) {
    print "TO_ADDRESS => @{[ join(',', map {$_->{value}} @contacts) ]}, TYPE => $contacts[0]->{type_id} MESSAGE => $attr->{MESSAGE}\n";
  }

  if ($self->{debug} && $self->{debug} == 9){
    require Data::Dumper;
    require POSIX;
    POSIX->import(qw( strftime ));
    my $DATE_TIME = POSIX::strftime("%Y-%m-%d %H:%M:%S", localtime(time));

    my $dumped = join("\n\n", map {  Data::Dumper::Dumper({
        %{$attr},
        TO_ADDRESS => $_->{value},
        CONTACT    => $_
      })  } @contacts );

    `echo " $DATE_TIME \n $dumped" >> /tmp/sender_debug`;
  }

  my AXbills::Sender::Plugin $plugin = $self->{$send_type};

  $plugin->{db} = $self->{db};
  $plugin->{admin} = $self->{admin};
  $plugin->{conf} = $self->{conf};

  if (scalar @contacts > 1 && $plugin->support_batch()) {
    return $plugin->send_message({
      %{$attr},
      TO_ADDRESS => $contacts[0]{value},
      CONTACT    => \@contacts
    });
  }
  else {
    my $at_least_once_successful = 0;
    foreach my $contact ( @contacts ) {
      $at_least_once_successful ||= $plugin->send_message({
        %{$attr},
        TO_ADDRESS => $contact->{value},
        CONTACT    => $contact
      });
    }

    return $at_least_once_successful;
  }
}

#**********************************************************
=head2 send_message_auto($attr) - Automatic sender type choosing based on contacts priority

  Arguments:
    $attr -
      UID|AID - Receiver

      SUBJECT -
      MESSAGE -

      ALL - Send with all available methods

  Returns:
    boolean - at least one plugin returned 1

=cut
#**********************************************************
sub send_message_auto {
  my ($self, $attr) = @_;

  my $contacts_list;
  if ($attr->{UID}) {
    $contacts_list = $Contacts->contacts_list({ UID => $attr->{UID}, SHOW_ALL_COLUMNS => 1, TYPE => $attr->{SEND_TYPE} || '_SHOW' });
    push(@{$contacts_list}, { type_id => 9, value => $attr->{USER_EMAIL} }) if $attr->{USER_EMAIL};
  }
  elsif ($attr->{AID}) {
    $contacts_list = $self->{admin}->admins_contacts_list({ AID => $attr->{AID}, SHOW_ALL_COLUMNS => 1 });
  }
  else {
    return '';
  }

  my $receiver_type = ($attr->{AID}) ? 'AID' : (($attr->{UID}) ? 'UID' : 0);
  my @contacts = $self->get_push_contacts({
    AID       => ($receiver_type eq 'AID') ? $attr->{AID} : '_SHOW',
    UID       => ($receiver_type eq 'UID') ? $attr->{UID} : '_SHOW',
    VALUE     => '_SHOW',
    PAGE_ROWS => 1,
  });

  push @{$contacts_list}, @contacts;

  my $send_messages_types = ();
  if (defined $attr->{SEND_TYPES}) {
    map push(@{$send_messages_types}, $PLUGIN_NAME_FOR_TYPE_ID{$_}), split(/,\s?/, $attr->{SEND_TYPES});
  }
  else {
    @{$send_messages_types} = $self->{conf}{MSGS_SEND_MESSAGES_TYPES} ?
      split(/,\s?/, $self->{conf}{MSGS_SEND_MESSAGES_TYPES}) : values %PLUGIN_NAME_FOR_TYPE_ID;
  }

  my $at_least_one_was_successful = 0;
  foreach my $cont ( @{${contacts_list}} ) {
    next if !in_array($PLUGIN_NAME_FOR_TYPE_ID{$cont->{type_id}}, $send_messages_types);

    $at_least_one_was_successful = 1 if ($self->send_message({
      %{$attr},
      TO_ADDRESS  => $cont->{value},
      SENDER_TYPE => $PLUGIN_NAME_FOR_TYPE_ID{$cont->{type_id}},
    }));

    last if $at_least_one_was_successful && !$attr->{ALL};
  }

  #Send email if present. (no email in admins_contacts)
  if($attr->{AID} && (!$attr->{SEND_TYPES} || in_array(9, $send_messages_types))){
    my $current_aid = $self->{admin}{AID};
    my $info = $self->{admin}->info($attr->{AID});

    if ($info->{EMAIL}) {
      $at_least_one_was_successful = 1 if ($self->send_message({
        %{$attr},
        TO_ADDRESS  => $info->{EMAIL},
        SENDER_TYPE => $PLUGIN_NAME_FOR_TYPE_ID{9},
      }));
    }
    $self->{admin}->info($current_aid)
  }

  return $at_least_one_was_successful;
}

#**********************************************************
=head2 get_contacts_for($attr) - returns best matched contact for given params

  Arguments:
    $attr -
      SENDER_TYPE
      UID
      AID

  Returns:
    contact_ref
     {
       uid
       value
       priority
       type
       default
       type_name
     }

    OR 0

=cut
#**********************************************************
sub get_contacts_for {
  my ($self, $attr) = @_;

  my $send_type = $attr->{SENDER_TYPE};
  my $receiver_type = ($attr->{AID}) ? 'AID' : (($attr->{UID}) ? 'UID' : 0);

  if (!$receiver_type && $send_type ne 'Push') {
    $self->{errstr} = 'Invalid receiver type. Should be AID or UID';
    $self->{errno} = 1;
    print $self->{errstr} if ($self->{debug});
    return 0;
  };

  if ($send_type eq 'Browser') {
    # This is just a dummy. Browser plugin will handle contact logic itself
    my $contact_for_browser = { value => '', type_id => 0 };
    return wantarray ? @{[ $contact_for_browser ]} : [ $contact_for_browser ];
  }
  elsif ($send_type eq 'Push') {
    my @contacts;
    if (!$receiver_type) {
      @contacts = $self->get_push_contacts({
        AID          => 0,
        UID          => 0,
        VALUE        => $attr->{TO_ADDRESS},
        PUSH_TYPE_ID => '_SHOW',
        BADGES       => '_SHOW',
        COLS_NAME    => 1,
        PAGE_ROWS    => 1,
      });
    }
    else {
      @contacts = $self->get_push_contacts({
        AID          => ($receiver_type eq 'AID') ? $attr->{AID} : '_SHOW',
        UID          => ($receiver_type eq 'UID') ? $attr->{UID} : '_SHOW',
        VALUE        => '_SHOW',
        PUSH_TYPE_ID => '_SHOW',
        BADGES       => '_SHOW',
        COLS_NAME    => 1,
        PAGE_ROWS    => 3,
      });
    }

    return wantarray ? @contacts : \@contacts;
  }

  my $plugin_contact_type = ($self->{$send_type} && $self->{$send_type}->contact_types($TYPE_ID_FOR_PLUGIN_NAME{$send_type}));

  if ( $plugin_contact_type || !$TYPE_ID_FOR_PLUGIN_NAME{$send_type} || $plugin_contact_type != $TYPE_ID_FOR_PLUGIN_NAME{$send_type} ) {
    $PLUGIN_NAME_FOR_TYPE_ID{$plugin_contact_type} = $send_type;
    $TYPE_ID_FOR_PLUGIN_NAME{$send_type} = $plugin_contact_type;
  }

  my %search_params = (
    TYPE      => $plugin_contact_type,
    TYPE_NAME => '_SHOW',
    VALUE     => '_SHOW',
    COLS_NAME => 1
  );

  my $contacts_list;
  if ( $attr->{UID} ) {
    # Get contact address
    $contacts_list = $Contacts->contacts_list({ UID => $attr->{UID}, %search_params });
  }
  elsif ($attr->{AID}) {
    if (!$self->{admin}) {
      $self->{errstr} = " \$self->{admin} is not defined \n";
      $self->{errno} = 2;
      print $self->{errstr};
      return 0;
    }

    $contacts_list = $self->{admin}->admins_contacts_list({ AID => $attr->{AID}, %search_params });
  }

  if ( $contacts_list && ref $contacts_list eq 'ARRAY' && scalar @{$contacts_list} ) {
    return wantarray ? @{$contacts_list} : $contacts_list;
  }
  else {
    print "No contacts for $receiver_type: $attr->{$receiver_type}" if ( $self->{debug} );
    return 0;
  }
}

#**********************************************************
=head2 get_push_contacts($attr) - returns contacts array in form suitable for Push plugin

  Arguments:
    $attr -

  Returns:


=cut
#**********************************************************
sub get_push_contacts {
  shift;
  my ($attr) = @_;

  my $push_list = $Contacts->push_contacts_list($attr);

  my @push_contacts = map {
    {
      %{$_},
        value   => $_->{value},
        type_id => 10
    }
  } @{$push_list};

  return wantarray ? @push_contacts : \@push_contacts;
}

#**********************************************************
=head2 available_types($attr) - Return list of plugins that can be initialized and used

  Arguments:
     -

  Returns:


=cut
#**********************************************************
sub available_types {
  my ($self, $attr) = @_;

  # Form all methods Sender can use
  my @available_methods = ();
  foreach my $method (sort keys %TYPE_ID_FOR_PLUGIN_NAME) {
    # Browser is not supported yet
    next if ($attr->{CLIENT} && $method eq 'Browser');

    if ($attr->{SOFT_CHECK}) {
      my $soft_check = $self->{soft_check}->{$method};
      if ($soft_check) {
        my $loaded = $soft_check->();
        if ($loaded) {
          push (@available_methods, $method);
        }
        next;
      }
    };

    if ($self->sender_load($method, $attr)) {
      push (@available_methods, $method);
    }
  }

  if ($attr->{HASH_RETURN}) {
    return { map { $TYPE_ID_FOR_PLUGIN_NAME{$_} => $_ } @available_methods };
  }

  return \@available_methods;
}

1;
