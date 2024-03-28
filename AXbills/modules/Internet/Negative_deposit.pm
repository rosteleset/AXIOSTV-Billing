=head2 NAME

  Negative deposit

=cut

use strict;
use warnings;
use AXbills::Base qw(cmd);

our(
  %conf,
  $OS,
  $debug
);

#**********************************************************
=head2 mk_redirect($attr)

  Arguments:
    $attr
      IP

=cut
#**********************************************************
sub mk_redirect {
  my ($attr)=@_;

  my $cmd = '';

  if ($conf{NEG_DEPOSIT_WARNING_CMD}) {
    $cmd = $conf{NEG_DEPOSIT_WARNING_CMD};
    $cmd =~ s/\%IP\%/$attr->{IP}/g;
  }
  elsif ($OS eq 'FreeBSD') {
    $cmd = "/usr/local/bin/sudo /sbin/ipfw table 32 add $attr->{IP}";
    #/usr/local/bin/sudo /sbin/ipfw table 10 delete $attr->{IP};
    #/usr/local/bin/sudo /sbin/ipfw table 11 delete $attr->{IP};";
  }
  elsif($OS eq 'Linux') {

  }

  cmd($cmd, { DEBUG => $debug });

  return 1;
}

1;