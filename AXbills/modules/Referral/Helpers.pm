package Referral::Helpers;

use strict;
use warnings FATAL => 'all';
use parent 'Exporter';

our $VERSION = 0.01;

our @EXPORT = qw(
  transform_to_hash
);

our @EXPORT_OK = qw(
  transform_to_hash
);

#**********************************************************
=head2 transform_to_hash($list, $attr)

  Transforms arr_ref of hash_ref to one hash_ref

  Arguments:
    $list - DB list, arr_ref of hash_ref
    $attr
      NAME_KEY
      VALUE_KEY

  Returns:
    hash_ref

=cut
#**********************************************************
sub transform_to_hash {
  my ($list, $attr) = @_;

  my $name_key = $attr->{NAME_KEY};
  my $val_key = $attr->{VALUE_KEY};

  if (!defined $list || scalar @{$list} == 0) {
    return {};
  }

  my %result = ();

  foreach my $element (@{$list}) {
    next unless $element->{$name_key};
    $result{$element->{$name_key}} = $element->{$val_key};
  }

  return \%result;
}

1;
