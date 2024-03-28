package Ureports::Report1;
use strict;
use warnings FATAL => 'all';

my %SYS_CONF    = (
  'REPORT_ID'       => 51,
  'REPORT_NAME'     => 'Report1 name',
  'REPORT_FUNCTION' => 'report1',
  'COMMENTS'        => 'Happy birthday',
  'TEMPLATE'        => 'ureports_report_51'
);

#**********************************************************
=head2 report1()

=cut
#**********************************************************
sub new {
  my $class = shift;
  my($db, $admin, $CONF) = @_;

  my $self = {
    db   => $db,
    admin=> $admin,
    conf => $CONF
  };

  bless($self, $class);

  $self->{SYS_CONF} = \%SYS_CONF;

  return $self;
}


#**********************************************************
=head2 report1()

=cut
#**********************************************************
sub report1 {
  my $self = shift;
  my ($user, $attr) = @_;
  my %PARAMS = ();

  require Users;
  Users->import();
  my $Users = Users->new($self->{db}, $self->{admin}, $self->{conf});

  $Users->pi({ UID => $user->{UID} });

  if ($self->{debug}) {
    print "BIRTH: $Users->{BIRTH_DATE}\n\n";
  }

  my $get_birth_date = q{};
  if ($Users->{BIRTH_DATE} =~ /(\d{2}\-\d{2})$/) {
    $get_birth_date = $1;
  }

  my $today = q{};
  if ($attr->{DATE} =~ /(\d{2}\-\d{2})$/) {
    $today = $1;
  }

  if ($get_birth_date ne $today) {
    return 0;
  }

  $PARAMS{MESSAGE} = 'Happy birthday';
  $PARAMS{SUBJECT} = 'Happy birthday ' . ($Users->{FIO}  || '');
  $self->{PARAMS}  = \%PARAMS;

  return 1;
}

1;
