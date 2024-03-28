package AXbills::Sender::Viber;
=head1 Viber

  Send viber message

=cut


use strict;
use warnings FATAL => 'all';

use AXbills::Sender::Plugin;
use parent 'AXbills::Sender::Plugin';
use Sms::Init;
use Sms;

my %conf = ();
my @viber_msgs = (
  'SMS_OMNICELL_VIBER',
  'SMS_TURBOSMS_VIBER'
);

#**********************************************************
=head2 new($db, $admin, $CONF, $attr) - Create new Viber object

  Arguments:
    $attr
      CONF

  Returns:

  Examples:
    my $Telegram = AXbills::Sender::Viber->new($db, $admin, \%conf);

=cut
#**********************************************************
sub new {
  my $class = shift;
  my ($conf) = @_ or return 0;

  %conf = %{$conf};

  my $self = {};

  foreach my $viber_check (@viber_msgs) {
    if ($conf{ $viber_check }) {
      $self->{VIBER_TOKEN} = $conf{ $viber_check };
      last;
    }
  }

  die 'No Viber token ($conf{SMS_OMNICELL_VIBER} or $conf{SMS_TURBOSMS_VIBER})' if !$self->{VIBER_TOKEN};

  bless $self, $class;

  return $self;
}

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


  unless ($attr->{TO_ADDRESS}) {
    print "No recipient address given \n" if ($self->{debug});
    return 0;
  };

  my $number_pattern = $self->{conf}{SMS_NUMBER} || "[0-9]{12}";
  if ($attr->{TO_ADDRESS} !~ /$number_pattern/) {
    return 0;
  }

  my $Sms_service = init_sms_service($self->{db}, $self->{admin}, $self->{conf});

  my $sms_result = $Sms_service->send_sms({
    NUMBER  => $attr->{TO_ADDRESS},
    MESSAGE => $attr->{MESSAGE},
    VIBER   => $self->{VIBER_TOKEN}
  });

  my $DATE = POSIX::strftime("%Y-%m-%d", localtime(time));
  my $TIME = POSIX::strftime("%H:%M:%S", localtime(time));

  my $Sms = Sms->new($self->{db}, $self->{admin}, $self->{conf});

  $Sms->add({
    UID         => $attr->{UID} || $self->{UID} || 0,
    MESSAGE     => $attr->{MESSAGE} || q{},
    PHONE       => $attr->{TO_ADDRESS},
    DATETIME    => "$DATE $TIME",
    STATUS      => $sms_result || 0,
    EXT_ID      => $Sms_service->{id} || '',
    STATUS_DATE => "$DATE $TIME",
    EXT_STATUS  => $Sms_service->{status} || '',
  });

  return 1;
}

#**********************************************************
=head2 contact_types() -

=cut
#**********************************************************
sub contact_types {
  my $self = shift;

  return $self->{conf}{SMS_CONTACT_ID} || 1;
}

#**********************************************************
=head2 support_batch() - tells Sender, we can accept more than one recepient per call

=cut
#**********************************************************
sub support_batch {
  return 1;
}

1;
