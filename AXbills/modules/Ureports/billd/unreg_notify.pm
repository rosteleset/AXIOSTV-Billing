#**********************************************************
=head1 NAME

  Plugin for notify users which not registered
    /usr/axbills/libexec/billd unreg_notify

=cut
#**********************************************************

use strict;
use warnings FATAL => 'all';

push @INC, $Bin.'/../', $Bin.'/../AXbills/';

our (
  $db,
  $Admin,
  %conf,
  $argv,
  %lang,
  $base_dir
);

my $html = AXbills::HTML->new({ CONF => \%conf });

my $dir = $base_dir || '/usr/axbills/';
require "$dir/AXbills/modules/Ureports/lng_$conf{default_language}.pl";

require AXbills::Templates;

use POSIX;
use Ureports::Base;
use Contacts;

my $Ureports_base = Ureports::Base->new($db, $Admin, \%conf, { HTML => $html, LANG => \%lang });
my $Contacts = Contacts->new($db, $Admin, \%conf);

notify_unreg();

#**********************************************************
=head2 notify_unreg()

=cut
#**********************************************************
sub notify_unreg {

  #TODO: move to _get_unreg_push if will be used for another destinations except push
  if (!$conf{PUSH_ENABLED} || (!$conf{FIREBASE_SERVER_KEY} &&
    (!$conf{GOOGLE_PROJECT_ID} || !$conf{FIREBASE_KEY}))) {
    return 1;
  }

  my ($types, $tokens) = _get_unreg_push();

  return 1 if (!$types || !$tokens);

  $Ureports_base->ureports_send_reports($types, $tokens, '', {
    REPORT_ID        => 200,
    SUBJECT_TEMPLATE => 'ureports_report_200_title',
    UID              => 0
  });
}

#**********************************************************
=head2 _get_unreg_push()

=cut
#**********************************************************
sub _get_unreg_push {

  my $date;
  if ($argv->{DATE}) {
    $date = $argv->{DATE};
  }
  else {
    my $current_time = time();
    my $yesterday_time = $current_time - 24 * 60 * 60;

    $date = POSIX::strftime('%Y-%m-%d %H:%M:%S', localtime($yesterday_time));
  }

  my $tokens = $Contacts->push_contacts_list({
    UID       => 0,
    AID       => 0,
    VALUE     => '_SHOW',
    COLS_NAME => 1,
    DATE      => ">$date",
    PAGE_ROWS => 1000000,
  });

  my $types = q{};
  my $destinations = q{};

  foreach my $token (@{$tokens}) {
    $types .= '10,';
    $destinations .= "$token->{value},";
  }

  return $types, $destinations;
}

1;
