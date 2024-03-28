=head1 NAME

  billd to import Crm data from mail

=cut

use strict;
use warnings;
use AXbills::Base qw(load_pmodule in_array _bp decode_base64 urldecode urlencode);
use AXbills::Import qw(pop3_import);
our (
  $argv,
  $debug,
  %conf,
  $Admin,
  $db
);

import_mails();

#**********************************************************
=head2 import_mails() - import data from mail with POP3

=cut
#**********************************************************
sub import_mails {

  return if !$conf{CRM_EMAIL_CHECK};

  my ($host, $admin_email, $admin_password) = split(/;/, $conf{CRM_EMAIL_CHECK});
  my $result = pop3_import($host, $admin_email, $admin_password, { SSL => $argv->{SSL}, TIMEOUT => $argv->{TIMEOUT} });

  if ($result->{errstr}) {
    print $result->{errstr} . "\n";
    return;
  }

  use Crm::Dialogue;
  my $Dialogue = Crm::Dialogue->new($db, $Admin, \%conf, { SOURCE => 'mail' });

  foreach my $message_id (keys %{$result}) {
    my $message = $result->{$message_id};
    my $message_id = $message->{header}{'message-id'} =~ /\<(.+)\>/ ? $1 : '';

    next if !$message->{body}{text} || !$message_id;

    my ($fio, $email) = $message->{header}{from} =~ '(.+)\s\<(.+)\>';
    next if $email eq $admin_email;

    # $message->{body}{text} = $message->{body}{text} =~ /([\s\S]*)\n.+\d{2}:\d{2}\s?(<$admin_email>|<$email>).+/ ? $1 : $message->{body}{text};

    my $lead_id = $Dialogue->crm_lead_by_source({ USER_ID => $message_id, FIO => $fio, EMAIL => $email });
    next if !$lead_id;

    my $dialogue_id = $Dialogue->crm_get_dialogue_id($lead_id);
    return '' if !$dialogue_id;

    $Dialogue->crm_send_message($message->{body}{text}, { DIALOGUE_ID => $dialogue_id });
  }
}

1;