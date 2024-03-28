package AXbills::Api::Helpers;

use strict;
use warnings FATAL => 'all';
use parent 'Exporter';

our $VERSION = 0.01;

our @EXPORT = qw(
  static_string_generate
  caesar_cipher
);

our @EXPORT_OK = qw(
  static_string_generate
  caesar_cipher
);

#**********************************************************
=head2 static_string_generate($string, $integer)

=cut
#**********************************************************
sub static_string_generate {
  my ($string, $integer) = @_;

  return length($string) * 21 * $integer;
}

#**********************************************************
=head2 caesar_cipher($string, $integer)

=cut
#**********************************************************
sub caesar_cipher {
  my ($string, $integer) = @_;

  my $MIN = ord '!';

  return join '',
    map {
      my $let = ord($_) - $integer;
      if ($let < $MIN) {
        my $delta = abs($let - $MIN);
        $let = 126 - $delta + 1;
      }
      $_ eq ' ' ? ' ' : chr $let;
    } split '', $string;
}

1;
