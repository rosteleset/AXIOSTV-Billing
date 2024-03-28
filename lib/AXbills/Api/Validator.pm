package AXbills::Api::Validator;

use strict;
use warnings FATAL => 'all';

use AXbills::Base qw(camelize is_number);

my (
  %conf,
);

#**********************************************************
=head2 new($db, $admin, $conf)

=cut
#**********************************************************
sub new {
  my ($class, $db, $admin, $conf) = @_;

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $conf,
  };

  bless($self, $class);

  %conf = %{$self->{conf} || {}};

  return $self;
}

#**********************************************************
=head2 validate_params($attr)

  Request
    attr: object
      query_params: object  - query or request body params
      params: object        - allowed and required params in object

  Result
    validation_result: object - result of validation errors, filtered params

      if error:

        errno?: error number
        errstr?: error string
        errobj?: detailed error info

      if ok
        filtered_result

=cut
#**********************************************************
sub validate_params {
  my $self = shift;
  my ($attr) = @_;

  my %filtered_params = ();
  my @errors = ();

  foreach my $param (keys %{$attr->{query_params}}) {
    if (exists $attr->{params}->{$param}) {
      if ($attr->{params}->{$param}->{type}) {
        my $cam_param = camelize($param);
        if (($attr->{params}->{$param}->{type} eq 'date' && $attr->{query_params}->{$param} !~ /^\d{4}-\d{2}-\d{2}$/) ||
            ($attr->{params}->{$param}->{type} eq 'unsigned_integer' && $attr->{query_params}->{$param} !~ /^(0|[1-9]\d*)$/) ||
            ($attr->{params}->{$param}->{type} eq 'integer' && $attr->{query_params}->{$param} !~ /^-?(0|[1-9]\d*)$/) ||
            ($attr->{params}->{$param}->{type} eq 'unsigned_number' && !is_number($attr->{query_params}->{$param})) ||
            ($attr->{params}->{$param}->{type} eq 'number' && !is_number($attr->{query_params}->{$param}, 0, 1))
          ) {
          push @errors, {
            errno    => 21,
            errstr   => "$cam_param is not valid",
            param    => $cam_param,
            type     => $attr->{params}->{$param}->{type}
          };
        }
        elsif ($attr->{params}->{$param}->{type} eq 'custom') {
          my $result = $attr->{params}->{$param}->{function}->($self, $attr->{query_params}->{$param});
          if (ref $result eq 'HASH' && !$result->{result}) {
            delete $result->{result};
            push @errors, {
              errno    => 21,
              param    => $cam_param,
              %$result
            };
          }
        }
      }
      $filtered_params{$param} = $attr->{query_params}->{$param};
      delete $attr->{params}->{$param};
    }
  }

  foreach my $param (sort keys %{$attr->{params}}) {
    my $cam_param = camelize($param);
    if ($attr->{params}->{$param}->{required}) {
      push @errors, {
        errno    => 20,
        errstr   => "$cam_param is required",
        param    => $cam_param,
        required => 'true'
      };
    }
    elsif (defined $attr->{params}->{$param}->{default}) {
      $filtered_params{$param} = $attr->{params}->{$param}->{default};
    }
  }

  scalar @errors ?
    return {
      errno  => 9,
      errstr => 'Validation failed',
      errors => \@errors
    } :
    return \%filtered_params;
}

1;
