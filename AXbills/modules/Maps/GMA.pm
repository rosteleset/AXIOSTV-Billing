package Maps::GMA;

=name Google Maps Geocoding API

  https://developers.google.com/maps/documentation/geocoding/intro

  https://developers.google.com/maps/documentation/geocoding/get-api-key

=cut
use strict;
use warnings FATAL => 'all';

use lib 'mysql';
use parent "main";

use AXbills::Base qw(_bp);
_bp(undef, undef, { SET_ARGS => { TO_CONSOLE => 1, IN_JSON => 1 } });

use AXbills::Fetcher qw/web_request/;
use JSON;
use Address;

my $api_link = 'https://maps.googleapis.com/maps/api/geocode/json';

#**********************************************************
=head2 new($db, $admin, \%conf) - constructor for Google Maps Api

  Attributes:
    $db, $admin, \%conf -

  Returns:
    object - new Google Maps Api instance

=cut
#**********************************************************
sub new {
  my $class = shift;
  my ($db, $admin, $conf) = @_;
  
  my $self = {
    db      => $db,
    admin   => $admin,
    conf    => $conf,
    Address => Address->new(@_)
  };
  
  bless($self, $class);
  
  $self->{key} = $conf->{GOOGLE_API_KEY} || '';
  
  return $self;
}

#**********************************************************
=head2 get_unfilled_addresses()

  Returns:
    list

=cut
#**********************************************************
sub get_unfilled_addresses {
  my ($self, $attr) = @_;
  
  # Ignore district names if they are not real geographic names (e.g in small city)
  my $districts_are_not_real = $attr->{DISTRICTS_ARE_NOT_REAL};
  
  my Address $Address = $self->{Address};
  
  my $build_list = $Address->build_list({
    COORDX          => '0',
    COORDY          => '0',
    STREET_ID       => $attr->{STREET_ID} || '_SHOW',
    DISTRICT_ID     => $attr->{DISTRICT_ID} || '_SHOW',
    STREET_NAME     => '_SHOW',
    SHOW_GOOGLE_MAP => 1,
    COLS_NAME       => 1,
    PAGE_ROWS       => 10000
  });
  
  my %districts_by_id = ();
  my $districts_list = $Address->district_list({
    COLS_NAME => 1,
    PAGE_ROWS => 10000,
    %{ $attr->{DISTRICT_ID} ? { DISTRICT_ID => $attr->{DISTRICT_ID} } : {} }
  });
  
  foreach my $district ( @{ $districts_list } ) {
    $districts_by_id{$district->{id}} = $district;
  }
  
  #  _bp('Districts', \%districts_by_id,
  #    {TO_WEB_CONSOLE => ($attr->{WEB_DEBUG}) ? 1 : 0, TO_CONSOLE => ($attr->{CONS_DEBUG} ? 1 : 0)}
  #  ) if ($attr->{DEBUG});
  
  my %streets_by_id = ();
  my $streets_list = $Address->street_list({
    COLS_NAME => 1,
    PAGE_ROWS => 10000,
    %{ $attr->{DISTRICT_ID} ? { DISTRICT_ID => $attr->{DISTRICT_ID} } : {} },
    %{ $attr->{STREET_ID} ? { STREET_ID => $attr->{STREET_ID} } : {} }
  });
  
  foreach my $street ( @{ $streets_list } ) {
    $streets_by_id{$street->{id}} = $street;
  }
  #  _bp('Streets', \%streets_by_id,
  #    {TO_WEB_CONSOLE => ($attr->{WEB_DEBUG}) ? 1 : 0, TO_CONSOLE => ($attr->{CONS_DEBUG} ? 1 : 0)}
  #  ) if ($attr->{DEBUG});
  
  my @builds_without_coords = ();
  
  #Compressing all needed data in one hash
  foreach my $build ( @{$build_list} ) {
    
    # Dealing with broken DB
    # Check if street for build exists
    if ( !exists $streets_by_id{$build->{street_id}} ) {
      #      _bp('BROKEN street_id ', $build->{street_id},
      #        {TO_WEB_CONSOLE => ($attr->{WEB_DEBUG}) ? 1 : 0, TO_CONSOLE => ($attr->{CONS_DEBUG} ? 1 : 0)}
      #      ) if ($attr->{DEBUG});
      next;
    };
    
    # Check if district for this build exists
    if ( !exists $districts_by_id{$build->{district_id}} ) {
      #      _bp('BROKEN district_id ', $build->{district_id},
      #        {TO_WEB_CONSOLE => ($attr->{WEB_DEBUG}) ? 1 : 0, TO_CONSOLE => ($attr->{CONS_DEBUG} ? 1 : 0)}
      #      ) if ($attr->{DEBUG});
      next;
    };
    
    my $district = $districts_by_id{ $build->{district_id} };
    
    my $district_name = $districts_are_not_real ? '' : ($district->{name} || '') . ", ";
    my $street_name = $build->{street_name};
    
    $build->{country} = $district->{country};
    $build->{city} = $district->{city} || '';
    $build->{district_name} = $district->{name} || '';
    $build->{postalCode} = $district->{zip};
    
    $build->{full_address} = "$build->{city}, $district_name$street_name, $build->{number}";
    
    push(@builds_without_coords, $build);
  }
  
  return \@builds_without_coords;
}

#**********************************************************
=head2 get_coords_for($build) - returns coordinates for build

  See Returns for details

  Arguments:
    $requeste_addr - full_address
    $build_id      - build hash
    $attr          - hash_ref
      ZIP_CODE     - if given, will filter rezults by postal code

  Returns:
    HASH
      STATUS - Status of response. 1 is "OK"
      COORDX - longitude
      COORDY - latitude
      formatted_address - Forrmatted address returned by Google API
      requested_address - address as it was sended to Google API

  Responce from Google API can contain multiple results. In this case returns:
    HASH
      STATUS - integer
      requested_address - address as it was sended to Google API
      formatted_address - Forrmatted address returned by Google API
      COORDS [
        COORDX, - longitude
        COORDY  - latitude
      ]

=cut
#**********************************************************
sub get_coords_for {
  my $self = shift;
  my ($requested_addr, $build_id, $attr) = @_;
  $attr //= {};
  
  # For free usage, Geocoding API receives one request in 1.5 seconds;
  unless ( $self->{conf}->{MAPS_NO_THROTTLE} ) {
    sleep 2;
  }
  
  my $responce = web_request($api_link, {
      REQUEST_PARAMS =>
      {
        address       => $requested_addr,
        key           => $self->{key},
        location_type => 'ROOFTOP',
          ($attr->{ZIP_CODE})
          ? (components => 'postal_code:' . $attr->{ZIP_CODE})
          : ()
      },
      GET            => 1,
      #      DEBUG => 3,
    });
  
  my $result = '';
  eval {$result = JSON->new->utf8->decode($responce)};
  if ( $@ ) {
    my ($error_str) = $@ =~ /\(before \"\(.*\)\"\)/;
    
    unless ( $error_str ) {
      $error_str = $@;
    }
    
    if ( $error_str =~ /Timeout/ ) {
      $error_str = 'Timeout';
    }
    
    return {
      STATUS => 500,
      ERROR  => $error_str
    };
  }
  
  #  _bp('', $result);
  
  
  # Return status 2 on fail
  unless ( defined $result->{status} && $result->{status} eq "OK" ) {
    return {
      STATUS            => 2,
      BUILD_ID          => $build_id,
      requested_address => $requested_addr
    };
  }
  
  my @results_shortcut = @{$result->{results}};
  
  # Handle multiple results
  unless ( scalar @results_shortcut == 1 ) {
    my @non_unique_results = ();
    
    # Clear all non ROOFTOP results
    my $rooftop_counter = 0;
    for ( my $i = 0; $i < scalar @results_shortcut; $i++ ) {
      if ( $results_shortcut[$i]->{geometry}->{location_type} eq 'ROOFTOP' ) {
        $rooftop_counter++;
      }
      else {
        splice(@results_shortcut, $i--, 1);
      }
    };
    
    if ( scalar @results_shortcut > 0 && $rooftop_counter > 1 ) {
      foreach my $coord ( @results_shortcut ) {
        my %res = ();
        $res{COORDX} = $coord->{geometry}->{location}->{lng};
        $res{COORDY} = $coord->{geometry}->{location}->{lat};
        $res{formatted_address} = $coord->{formatted_address};
        
        push (@non_unique_results, \%res);
      }
      
      return {
        STATUS            => 3,
        BUILD_ID          => $build_id,
        requested_address => $requested_addr,
        RESULTS           => \@non_unique_results
      };
    }
  }
  
  unless ( defined $results_shortcut[0]->{geometry}->{location_type} && $results_shortcut[0]->{geometry}->{location_type} eq 'ROOFTOP' ) {
    return {
      STATUS            => 4,
      BUILD_ID          => $build_id,
      requested_address => $requested_addr
    };
  }
  
  my $coords = $results_shortcut[0]->{geometry}->{location};
  
  return {
    STATUS            => 1,
    BUILD_ID          => $build_id,
    COORDX            => $coords->{lng},
    COORDY            => $coords->{lat},
    formatted_address => $results_shortcut[0]->{formatted_address},
    requested_address => $requested_addr
  }
};

#**********************************************************
=head2 get_address_for($latlng, $attr) - Returns address for coordinates (if it's ROOFTOP)

  Arguments:
    $latlng - hash_ref
      COORDX
      COORDY
     $attr -
    
  Returns:
    hash_ref -
     ADDRESS
    
=cut
#**********************************************************
sub get_address_for {
  my ($self, $latlng) = @_;
  
  # For free usage, Geocoding API receives one request in 1.5 seconds;
  unless ( $self->{conf}->{MAPS_NO_THROTTLE} ) {
    sleep 2;
  }
  
  my $responce = web_request($api_link, {
      REQUEST_PARAMS =>
      {
        key           => $self->{key},
        latlng        => $latlng->{COORDX} . ',' . $latlng->{COORDY},
        location_type => 'ROOFTOP',
        language      => 'RU_ru'
      },
      GET            => 1,
    });
  
  return $responce;
}

1;