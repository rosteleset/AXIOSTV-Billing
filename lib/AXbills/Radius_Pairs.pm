package AXbills::Radius_Pairs;

use strict;

#**********************************************************
=head2 build_radius_params_result_response($module)

=cut
#**********************************************************
sub build_radius_params_result_response {
  my ($module) = @_;

  my $errno = $module->{errno} || 0;
  my $err_str = $module->{err_str} || '';

  return qq[
    {
      "status": $errno,
      "message": "$err_str"
    }
  ];
}


#**********************************************************
=head2 parse_radius_params_json($pairs_json)

=cut
#**********************************************************
sub parse_radius_params_json {
  my ($pairs_json) = @_;

  if(!$pairs_json) {
    return '';
  }

  $pairs_json =~ s/\\//g;
  $pairs_json =~ s/’/'/g;

  require JSON;
  my $json = JSON->new()->utf8(0);

  my $radius_pairs = $json->decode($pairs_json);
  my $radius_pairs_string = build_radius_params_string($radius_pairs);

  return $radius_pairs_string;
}


#**********************************************************
=head2 parse_radius_params_string($radius_pairs_string)


=cut
#**********************************************************
sub parse_radius_params_string {
  my ($radius_pairs_string) = @_;


  if(!$radius_pairs_string) {
    return '[]';
  }

  my @pairs = split(", \n", $radius_pairs_string);

  foreach my $pair (@pairs) {
    my @pair_parts = $pair =~ /([0-9a-zA-Z\-:!]+)([-+=<>]{1,2})([:\-_\;\(\,\)\\'\\’\"\#= 0-9a-zA-Zа-яА-Я.]+)/;

    if(scalar @pair_parts != 3) {
      next;
    }

    my $is_ignored = substr($pair_parts[0], 0, 1 ) eq '!';

    if($is_ignored) {
      $pair_parts[0] = substr($pair_parts[0], 1)
    }

    $pair = {
      left => $pair_parts[0],
      condition => $pair_parts[1],
      right => $pair_parts[2],
      ignore => $is_ignored ? 1 : 0,
    }
  }

  require JSON;
  my $json = JSON->new()->utf8(0);

  return $json->encode(\@pairs);
}


#**********************************************************
=head2 build_radius_params_string($pairs)

=cut
#**********************************************************
sub build_radius_params_string {
  my ($pairs) = @_;
  my $params_string = '';

  foreach my $pair (@{ $pairs }) {
    if($pair->{ignore} || !$pair->{left} || !$pair->{right}) {
      $params_string .= '!';
    }

    $params_string .= $pair->{left} || 'LEFT_PART';
    $params_string .= $pair->{condition} || '=';
    $params_string .= defined($pair->{right}) ? $pair->{right} : 'RIGHT_PART';

    $params_string .= ", \n";
  }

  return substr($params_string, 0, -3);
}

1;