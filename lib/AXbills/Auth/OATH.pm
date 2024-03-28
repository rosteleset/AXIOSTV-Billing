package AXbills::Auth::OATH;

=head1 OATH

 OATH Authorization

=cut

use strict;
use warnings FATAL => 'all';

use AXbills::Base qw(load_pmodule);

my $no_module = 0;
$no_module = 1 if (load_pmodule('Authen::OATH', { SHOW_RETURN => 1 }));

#**********************************************************
=head2 check_access($attr)

=cut
#**********************************************************
sub check_access {
  shift;
  my ($attr) = @_;

  return 0 if ($no_module);
  return 0 if (!$attr->{SECRET} || !$attr->{PIN});

  my $oath = Authen::OATH->new;
  my $totp = $oath->totp($attr->{SECRET});

  return $attr->{PIN} == $totp;
}

#**********************************************************
=head2 encode_base32()

=cut
#**********************************************************
sub encode_base32 {
  my $arg = shift;
  return '' unless defined($arg); # mimic MIME::Base64

  $arg = unpack('B*', $arg);
  $arg =~ s/(.....)/000$1/g;
  my $l = length($arg);

  if ($l & 7) {
    my $e = substr($arg, $l & ~7);
    $arg = substr($arg, 0, $l & ~7);
    $arg .= "000$e" . '0' x (5 - length $e);
  }

  $arg = pack('B*', $arg);
  $arg =~ tr|\0-\37|A-Z2-7|;
  return $arg;
}

1;
