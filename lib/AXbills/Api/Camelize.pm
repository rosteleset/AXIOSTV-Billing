package AXbills::Api::Camelize;

#**********************************************************
=head2 camelize($string)

  Arguments:
     $string - make snake_case string to camelCase

   Return:
     $camel_string
=cut
#**********************************************************
sub camelize {
  my ($string) = @_;

  $string =~ s{(\w+)}{
    ($a = lc $1) =~ s<(^[a-z]|_[a-z])><
      ($b = uc $1) =~ s/^_//;
      $b;
    >eg;
    $a;
  }eg;

  return lcfirst($string);
}

#**********************************************************
=head2 decamelize($string)

  Arguments:
     $string - make camelCase string to snake_case

   Return:
     $snake_case
=cut
#**********************************************************
sub decamelize {
  my ($string) = @_;

  if ($string eq uc($string)) {
    return $string;
  }

  $string = ucfirst($string);

  $string =~ s{(\w+)}{
    ($a = $1) =~ s<(^[A-Z]|(?![a-z])[A-Z])><
      "_" . lc $1
    >eg;
    substr $a, 1;
  }eg;

  return uc($string);
}

1;