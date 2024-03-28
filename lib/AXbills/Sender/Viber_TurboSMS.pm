package AXbills::Sender::Viber_TurboSMS;
=head1 Viber

  Send viber message

=cut


use strict;
use warnings FATAL => 'all';

use AXbills::Sender::Plugin;
use parent 'AXbills::Sender::Plugin';
use Sms::Init;
use Sms;

my @viber_msgs = (
  'SMS_OMNICELL_VIBER',
  'SMS_TURBOSMS_VIBER'
);

#**********************************************************
=head2 send_message($attr)

  Arguments:
    MESSAGE
    SUBJECT
    PRIORITY_ID
    TO_ADDRESS   - Sms address
    UID
    debug

  Returns:
    result_hash_ref

=cut
#**********************************************************
sub send_message {
  my $self = shift;
  my ($attr) = @_;

  my $check_viber;
  foreach my $viber_cheack (@viber_msgs) {
    if ($self->{conf}->{ $viber_cheack }) {
       $check_viber = $self->{conf}->{ $viber_cheack };
    }
  }

  return 0 unless ($check_viber);

  unless ($attr->{TO_ADDRESS}){
   print "No recipient address given \n" if ($self->{debug});
   return 0;
  };

  my $number_pattern = $self->{conf}->{SMS_NUMBER} || "[0-9]{12}";
  if ($attr->{TO_ADDRESS} !~ /$number_pattern/) {
    return 0;
  }

  my $Sms_service = init_sms_service($self->{db}, $self->{admin}, $self->{conf});
    
  my $sms_result = $Sms_service->send_sms({
    NUMBER     => $attr->{TO_ADDRESS},
    MESSAGE    => $attr->{MESSAGE},
    VIBER      => $check_viber
  });

  my $DATE = POSIX::strftime("%Y-%m-%d", localtime(time));
  my $TIME = POSIX::strftime("%H:%M:%S", localtime(time));

  my $Sms = Sms->new($self->{db}, $self->{admin}, $self->{conf});

  $Sms->add({
    UID          => $attr->{UID} || $self->{UID} || 0,
    MESSAGE      => $attr->{MESSAGE} || q{},
    PHONE        => $attr->{TO_ADDRESS},
    DATETIME     => "$DATE $TIME",
    STATUS       => $sms_result || 0,
    EXT_ID       => $Sms_service->{id} || '',
    STATUS_DATE  => "$DATE $TIME",
    EXT_STATUS   => $Sms_service->{status} || '',
  });

  return 1;
}

#**********************************************************
=head2 contact_types() -

=cut
#**********************************************************
sub contact_types {
  my $self = shift;

  return $self->{conf}->{SMS_CONTACT_ID} || 1;
}

#**********************************************************
=head2 support_batch() - tells Sender, we can accept more than one recepient per call

=cut
#**********************************************************
sub support_batch {
  return 1;
}

1;
