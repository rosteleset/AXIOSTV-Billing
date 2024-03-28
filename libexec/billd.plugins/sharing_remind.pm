=head NAME
  sharing sender

  Examples:

    billd sharing_reminder
=cut

use strict;
use warnings;
use AXbills::Base;
use AXbills::Sender::Core;
use Sharing;
unshift(@INC, '/usr/axbills/');
require AXbills::Templates;

our (
  %lang,
  $debug,
  %conf,
  $admin,
  $var_dir,
  $db,
  $base_dir,
  $argv
);

my $html = AXbills::HTML->new({CONF => \%conf});
my $Sharing = Sharing->new($db, $admin, \%conf);
my $Sender = AXbills::Sender::Core->new($db, $admin, \%conf);

sharing_reminder();
#**********************************************************
=head2 sharing_reminder() - Sends messages to users in remind date about the end of the subscription to the downloaded file

=cut
#**********************************************************
sub sharing_reminder {
  if ($argv->{DEBUG}) {
    $debug = $argv->{DEBUG};
  }
  if ($debug eq 6) {
    $Sharing->{debug}=1;
  }
  my $remind_data = '';
  if ($argv->{LOGIN}) {
    $remind_data = $Sharing->get_remind_date({LOGIN => $argv->{LOGIN}});
  }
  else {
    $remind_data = $Sharing->get_remind_date();
  }
  foreach my $line (@{$remind_data}) {
    my $message = $html->tpl_show('',
      {
        REMIND_FOR => $line->{remind_for},
        FILE_NAME  => $line->{name}
      },
        {
          TPL                => 'sharing_message_text',
          MODULE             => 'Sharing',
          OUTPUT2RETURN      => 1,
          SKIP_DEBUG_MARKERS => 1
        });
    if ($debug eq 7) {
      print $message;
    }
    else {
      $Sender->send_message({
        UID       => $line->{uid},
          SUBJECT => "Сообщение об окончании подписки на $line->{name}",
          MESSAGE => $message,
        SENDER_TYPE => 'Mail',
      });
    }
    if ($debug eq 1) {
      print "UID - $line->{uid}; File_name - $line->{name}; DATE_TO - $line->{date_to}\n";
    }
  }
  return 1;
}

1