package AXbills::Api::FildsGrouper;

sub group_fields {
  my ($result) = @_;

  if(ref $result eq 'ARRAY') {
    foreach(@$result) {
      $_ = group($_)
    }
  }
  else {
    $result = group($result)
  }

  return $result;
}

sub group {
  my ($result) = @_;

  foreach my $field_name (keys %$result) {
    if($field_name =~ m/(.*)_(\d*)$/gm) {
      delete $result->{$field_name};
    }
  }

  foreach my $field_name (keys %$result) {
    if($field_name =~ m/(.*)_ALL$/gm) {
      my $old_fild_name = $field_name;
      $field_name =~ s/_ALL$//gm;

      my @list = split (', ', $result->{$old_fild_name});
      $result->{$field_name} = \@list;
      delete $result->{$old_fild_name};
    }
  }

  return $result;
}

1;