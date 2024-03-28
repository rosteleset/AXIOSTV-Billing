package AXbills::Sender::XMPP;
use strict;
use warnings FATAL => 'all';
use AXbills::Base qw(load_pmodule);
use parent 'AXbills::Sender::Plugin';
load_pmodule('AnyEvent::XMPP');

use AnyEvent::XMPP::IM::Connection;

=head1 NAME

  Send XMPP message

=cut


#**********************************************************
=head2 send_message($attr)

  Arguments:
    MESSAGE
    SUBJECT
    PRIORITY_ID
    TO_ADDRESS   - XMPP JID(s)

  Returns:
    result_hash_ref

=cut
#**********************************************************
sub send_message {
  my $self = shift;
  my ($attr) = @_;
  
  my $msg = $attr->{MESSAGE};
  my @dest = split(/,/, $attr->{TO_ADDRESS});
  
  my $cond = AnyEvent->condvar;
  my $conn = AnyEvent::XMPP::IM::Connection->new(
    jid      => $attr->{JID},
    password => $attr->{PASS},
    resource => $attr->{MODULE} || 'XMPP'
  );
  $conn->reg_cb(session_ready => sub {
      foreach my $dst ( @dest ) {
        my $message = AnyEvent::XMPP::IM::Message->new(
          type => $attr->{TYPE} || 'headline',
          to   => $dst,
          body => $msg,
        );
        
        $message->send($conn);
      }
      
      my $timer;
      $timer = AnyEvent->timer(
        after => 1,
        cb    => sub {
          undef $timer;
          $cond->send;
        },
      );
    });
  
  $conn->connect;
  $cond->recv;
  
}

#**********************************************************
=head2 support_batch() - tells Sender, we can accept more than one recepient per call

=cut
#**********************************************************
sub support_batch {
  return 1;
}

1;
