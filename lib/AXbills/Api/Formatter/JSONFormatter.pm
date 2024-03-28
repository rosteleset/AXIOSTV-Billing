package AXbills::Api::Formatter::JSONFormatter;

use JSON;

use strict;
use warnings;

use AXbills::Api::Camelize;
use AXbills::Base qw(json_former);

#**********************************************************
=head2 new($use_camelize)

   Arguments:
     $use_camelize - respons keys will be transforemed to camelCase
=cut
#**********************************************************
sub new {
  my ($class, $use_camelize, $excluded_fields) = @_;

  my %excluded_fields_hash = map {$_ => 1} @{$excluded_fields};

  my $self = {
    use_camelize    => $use_camelize,
    excluded_fields => \%excluded_fields_hash
  };

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 format($data, $type)

=cut
#**********************************************************
sub format {
  my ($self, $data, $type, $errno, $errstr) = @_;

  if ($errno && $errstr) {
    return json_former({
      errno  => $errno,
      errstr => $errstr
    })
  }

  if (ref $data eq 'ARRAY' || (defined $type && $type eq 'ARRAY')) {
    foreach (@{$data}) {
      $_ = transform_hash($self, $_);
    }

    return json_former($data);
  }
  else {
    return json_former(transform_hash($self, $data));
  }
}

#**********************************************************
=head2 transform_hash($data)

   Arguments:
     $data - ref to hash or scalar which will be transform to json

   Return:
     $modified_hash - hash without internal hash and normilized keys
=cut
#**********************************************************
sub transform_hash {
  my ($self, $data) = @_;

  my %response = ();

  unless (ref $data) {
    my $result_key = $self->{use_camelize} ? 'result' : 'RESULT';

    if ($data == 0 || $data == 1) {
      $response{ $result_key } = $data ? 'OK' : 'BAD';
    }
    else {
      $response{ $result_key } = $data;
    }
  }
  elsif ($data) {
    foreach my $data_key (keys %{$data}) {
      next if (exists($self->{excluded_fields}->{$data_key}));
      next if ($data_key eq 'conf');

      #FIXME create recursion function camelize for objects(HASHES)
      if ((!ref $data->{$data_key} eq '' || $data_key eq '' || !defined $data->{$data_key}) && !(ref $data->{$data_key} eq 'ARRAY')) {
        next;
      }

      $response{
        $self->{use_camelize} ? AXbills::Api::Camelize::camelize($data_key) : $data_key
      } = $data->{$data_key};
    }
  }

  return \%response;
}

1;