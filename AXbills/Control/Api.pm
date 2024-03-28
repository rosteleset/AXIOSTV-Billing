=head1 NAME

  API Base interface

=cut

use strict;
use warnings FATAL => 'all';
use AXbills::Base qw(in_array);

our (
  $html,
);

#**********************************************************
=head2 form_system_info($request) - API and system infomation functions

  Arguments:
    $attr

  Result:
    Info

=cut
#**********************************************************
sub form_system_info {
  my ($get_info) = @_;

  print $html->header();

  my ($version, $updated) = split(/ /, get_version());

  my %functions_api = (
    system_information => {
      date    => "$DATE $TIME",
      os      => uc($^O),
      billing => 'ABillS',
      name    => 'ABillS',
      version => $version,
      updated => $updated
    },
    api_methods        => {},
    api_version        => {
      version => '0.9',
      date    => '2022-04-01'
    }
  );

  my @show_functions = keys %functions_api;

  if ($get_info && in_array($get_info, \@show_functions)) {
    @show_functions = ($get_info);
  }

  foreach my $key (@show_functions) {
    my $table = $html->table({
      width      => '100%',
      FIELDS_IDS => [ keys %{$functions_api{$key}} ],
      rows       => [ [ values %{$functions_api{$key}} ] ],
      ID         => $key
    });

    $table->show();
  }

  $html->fetch({ DEBUG => $ENV{DEBUG} });

  return 1;
}

1;
