package Events::API;
use strict;
use warnings FATAL => 'all';

=head1 NAME

  Events::API - wrapper above Events DB operations for internal events creation

=head2 SYNOPSIS

  This package allows to create an event inside system and notify corresponding admins about it

=cut

use Events;
use AXbills::Sender::Core;

#**********************************************************
=head2 new($db, $admin, $CONF)

  Arguments:
    $db    - ref to DB
    $admin - current Web session admin
    $CONF  - ref to %conf

  Returns:
    object

=cut
#**********************************************************
sub new {
  my $class = shift;

  my ($db, $admin, $CONF) = @_;

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $CONF,
  };

  bless($self, $class);

  $self->{Events} = Events->new($self->{db}, $self->{admin}, $self->{conf});

  $self->{Sender} = AXbills::Sender::Core->new($self->{db}, $self->{admin}, $self->{conf}, { debug => 1 });

  return $self;
}

#**********************************************************
=head2 add_event($event_params) - Adds event and notifies admin subscribed for module

  Arguments:
    $event_params - hash_ref
      PRIORITY_ID - (1...5) - more is higher. Will notify admins if is normal and higher ( >=2 )
      MODULE      - name of module (will be checked when notifying admins)
      TITLE       - subject
      COMMENTS    - descruption

  Returns:
    1

  Example:
    $Events_api->add_event({
      PRIORITY_ID => 3,
      MODULE      => 'Internet',
      # GROUP_ID    => 3,

    });

=cut
#**********************************************************
sub add_event {
  my ($self, $event_params) = @_;

  return unless ( $event_params );
  my $module = $event_params->{MODULE} || 'SYSTEM';

  $event_params->{PRIORITY_ID} //= 3; # 'NORMAL'

  if ( !$event_params->{GROUP_ID} ) {
    $event_params->{GROUP_ID} = $self->{Events}->get_group_for_module($module);
  }

  my @admins_to_generate_event_for = ();
  if (!$event_params->{AID}){
    @admins_to_generate_event_for = $self->{Events}->admins_subscribed_to_module_list($module);
    if (!scalar @admins_to_generate_event_for){
      # Send to at least one admin
      @admins_to_generate_event_for = (1);
    }
  }
  else {
    @admins_to_generate_event_for = ($event_params->{AID});
  }

  foreach my $aid ( @admins_to_generate_event_for ) {
    $self->{Events}->events_add({%$event_params, AID => $aid});
  }

  if ( $event_params->{PRIORITY_ID} && $event_params->{PRIORITY_ID} >= 2 ) {
    $self->notify($event_params, @admins_to_generate_event_for);
  }

  return;
}

#**********************************************************
=head2 notify($event, @admin_aids) -

  Arguments:
    $module -
    $event  -

  Returns:


=cut
#**********************************************************
sub notify {
  my ($self, $event, @aids) = @_;


  # Load language
  our $base_dir = $main::base_dir || '/usr/axbills/';
  require AXbills::Experimental::Language;
  AXbills::Experimental::Language->import();
  my $Language = AXbills::Experimental::Language->new($base_dir || '/usr/axbills/', 'english');
  my $language_for_translation = $self->{conf}{default_language} || 'russian';
  if ($language_for_translation ne 'english'){
    $Language->load($language_for_translation);
  }
  if ($event->{MODULE} && $event->{MODULE} =~ /^[A-Z][a-z_]]+$/){
    $Language->load($language_for_translation, $event->{MODULE})
  }

  my $translated_title = $Language->translate($event->{TITLE}) || $event->{TITLE};
  my $translated_comments = $Language->translate($event->{COMMENTS}) || $event->{COMMENTS};

  my $event_priority = $event->{PRIORITY_ID} || 3; # 3 = Normal
  foreach my $aid ( @aids ) {

    # Send
    if ( $event_priority == 5 ) {
      # If priority is CRITICAL(5) send by all available methods
      $self->{Sender}->send_message_auto({
        AID     => $aid,
        SUBJECT => $translated_title,
        MESSAGE => $translated_comments,
        ALL     => 1
      });
    }
    else {
      # Form send methods
      my $priority_send_types_list = $self->{Events}->priority_send_types_list({
        AID         => $aid,
        PRIORITY_ID => $event_priority,
        SEND_TYPES  => '_SHOW',
        PAGE_ROWS   => 1,
        COLS_NAME   => 1
      });
      if ( $self->{Events}->{errno} || !$priority_send_types_list || !$self->{Events}->{TOTAL} ) {
        print "Error getting priority send types \n" if ( $self->{debug} );
        return 0;
      }

      my @priority_send_types = split(',\s?', $priority_send_types_list->[0]->{send_types} || '');

      # Each send method is Sender type name
      foreach my $sender_type ( @priority_send_types ) {
        $self->{Sender}->send_message({
          SENDER_TYPE => $sender_type,
          AID         => $aid,
          SUBJECT     => $translated_title,
          MESSAGE     => $translated_comments,
        });
      }

    }

  }

  return 1;
}

1;
