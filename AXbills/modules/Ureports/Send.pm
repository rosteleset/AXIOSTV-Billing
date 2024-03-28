=head1 NAME

  Ureports::Send

=head2 SYNOPSIS

  This is code for sending reports

=cut


use strict;
use warnings FATAL => 'all';

use AXbills::Base qw/cmd in_array convert/;
use AXbills::Misc;
use AXbills::Templates;
use AXbills::Sender::Core;
use Ureports;

our (%conf, $db, $admin);

our AXbills::HTML $html;

my $debug = 0;

my $Sender = AXbills::Sender::Core->new($db, $admin, \%conf);

#**********************************************************
=head2 ureports_send_reports($type, $destination, $message, $attr)

  Arguments:
    $type           - sender type
    $destination    - Destination address
    $message
    $attr
       MESSAGE_TEPLATE || REPORT_ID
       UID
       TP_ID
       REPORT_ID
       SUBJECT
       DEBUG

   Returns:
     boolean

=cut
#**********************************************************
#@deprecated
sub ureports_send_reports {
  my ($type, $destination, $message, $attr) = @_;

  return 0 unless (defined $type);

  my @types = split(',\s?', $type);
  my @destinations = split(',\s?', $destination);
  $debug = $attr->{DEBUG} || 0;

  my $Ureports = $debug < 5 ? Ureports->new($db, $admin, \%conf) : undef;

  my $type_index = 0;
  my $status = 0;

  foreach my $send_type (@types) {
    # Fix old EMAIL type 0 -> 9
    $send_type = 9 if ($send_type eq '0');

    if ($attr->{MESSAGE_TEPLATE}) {
      $message = $html->tpl_show(_include($attr->{MESSAGE_TEPLATE}, 'Ureports'), $attr,
        { OUTPUT2RETURN => 1 });
    }
    elsif ($send_type == 1 && $message && $conf{UREPORTS_CUSTOM_FIRST}) {
      $attr->{MESSAGE} = $message;
      $message = $html->tpl_show(_include('ureports_sms_message', 'Ureports'), $attr, { OUTPUT2RETURN => 1 });
    }
    elsif ($attr->{REPORT_ID}) {
      $message = $html->tpl_show(_include('ureports_report_' . $attr->{REPORT_ID}, 'Ureports'), $attr,
        { OUTPUT2RETURN => 1 });
    }

    if ($debug > 6) {
      print "TYPE: $send_type DESTINATION: $destinations[$type_index] MESSAGE: $message\n";
      $type_index++;
      next;
    }

    if ($conf{UREPORTS_SMS_CMD}) {
      cmd("$conf{UREPORTS_SMS_CMD} $destinations[$type_index] $message");
    }
    else {
      if ($conf{SMS_TRANSLIT}) {
        $message = convert($message, { txt2translit => 1 });
      }

      $status = $Sender->send_message({
        UID         => $attr->{UID},
        TO_ADDRESS  => $destinations[$type_index],
        SENDER_TYPE => $send_type,
        MESSAGE     => $message,
        SUBJECT     => $attr->{SUBJECT} || '',
        DEBUG       => ($debug > 2) ? $debug - 2 : undef
      }) || $status;
    }

    if ($debug < 5) {
      $Ureports->log_add({
        DESTINATION => $destinations[$type_index],
        BODY        => $message,
        UID         => $attr->{UID},
        TP_ID       => $attr->{TP_ID} || 0,
        REPORT_ID   => $attr->{REPORT_ID} || 0,
        STATUS      => $status || 0
      });
    }
    $type_index++;
  }

  return ($debug > 6) ? 1 : $status;
}


1;