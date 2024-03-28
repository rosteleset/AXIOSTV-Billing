package Voip::Constants;
=head1 NAME

  Voip::Constants - values that have to be equal all over modules using Voip

=head2 SYNOPSIS

  This package aggregates global values of Voip module uses

=cut


use strict;
use warnings FATAL => 'all';

use Exporter;
use parent 'Exporter';

use constant {
  TRUNK_PROTOCOLS       => [
    'SIP',
    'IAX2',
    'ZAP',
    'H323',
    'local',
  ],
  ACCT_TERMINATE_CAUSES => {
    'Unknown'                      => 0,
    'User-Request'                 => 1,
    'Lost-Carrier'                 => 2,
    'Lost-Service'                 => 3,
    'Idle-Timeout'                 => 4,
    'Session-Timeout'              => 5,
    'Admin-Reset'                  => 6,
    'Admin-Reboot'                 => 7,
    'Port-Error'                   => 8,
    'NAS-Error'                    => 9,
    'NAS-Request'                  => 10,
    'NAS-Reboot'                   => 11,
    'Port-Unneeded'                => 12,
    'Port-Preempted'               => 13,
    'Port-Suspended'               => 14,
    'Service-Unavailable'          => 15,
    'Callback'                     => 16,
    'User-Error'                   => 17,
    'Host-Request'                 => 18,
    'Supplicant-Restart'           => 19,
    'Reauthentication-Failure'     => 20,
    'Port-Reinit'                  => 21,
    'Port-Disabled'                => 22,
    'Lost-Alive/Billd Calculation' => 23
  }
};

our @EXPORT = qw/
  TRUNK_PROTOCOLS
  ACCT_TERMINATE_CAUSES
/;

1;
