package AXbills::Sender::Sms;
=head1 NAME

  Send Sms message

=cut

use strict;
use warnings FATAL => 'all';

use parent 'AXbills::Sender::Plugin';

use AXbills::Sender::Plugin;
use Sms::Init;
use Sms;
use AXbills::Filters;

#**********************************************************
=head2 send_message($attr)

  Arguments:
    MESSAGE
    SUBJECT
    PRIORITY_ID
    TO_ADDRESS   - Sms addresses delimiter by (,)
    UID
    debug

  Returns:
    result_hash_ref

=cut
#**********************************************************
sub send_message {
  my $self = shift;
  my ($attr) = @_;

  if (! $attr->{TO_ADDRESS}){
    print "No recipient address given \n" if ($self->{debug});
    return 0;
  };

  $attr->{TO_ADDRESS} =  $self->{conf}->{SMS_NUMBER_EXPR} ?
    _expr($attr->{TO_ADDRESS}, $self->{conf}->{SMS_NUMBER_EXPR}) : $attr->{TO_ADDRESS};

  my $sms_pattern = $self->{conf}->{SMS_NUMBER} || "[0-9]{12}";
  if ($attr->{TO_ADDRESS} !~ /$sms_pattern/) {
    return 0;
  }

  my $Sms = Sms->new($self->{db}, $self->{admin}, $self->{conf});
  my $Sms_service = init_sms_service($self->{db}, $self->{admin}, $self->{conf}, { UID => $attr->{UID} || $self->{UID} || 0 });

  if ($Sms_service && (ref $Sms_service eq 'HASH' && $Sms_service->{errno} || !$Sms_service->can('send_sms'))) {
    $self->{errno}=10;
    $self->{errstr}='SMS_SERVICE_NOT_REGISTER';
    return 0;
  }

  my $sms_result = $Sms_service->send_sms({
    NUMBER     => $attr->{TO_ADDRESS},
    MESSAGE    => $attr->{MESSAGE}
  });

  my $DATE = POSIX::strftime("%Y-%m-%d", localtime(time));
  my $TIME = POSIX::strftime("%H:%M:%S", localtime(time));

  $Sms->add({
    UID          => $attr->{UID} || $self->{UID} || 0,
    MESSAGE      => $attr->{MESSAGE} || q{},
    PHONE        => $attr->{TO_ADDRESS},
    DATETIME     => "$DATE $TIME",
    STATUS       => $sms_result || 0,
    EXT_ID       => $Sms_service->{id} || $Sms_service->{INSERT_ID} || '',
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
