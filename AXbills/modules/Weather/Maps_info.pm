package Weather::Maps_info;

=head1 NAME

  Weather::Maps_info - info for map

=head1 VERSION

  VERSION: 1.00
  REVISION: 20220516

=cut

use strict;
use warnings FATAL => 'all';
use parent qw(Exporter);

our $VERSION = 1.00;

our (
  $admin,
  $CONF,
  $lang,
  $html,
  $db
);

#**********************************************************
=head2 new()

=cut
#**********************************************************
sub new {
  my $class = shift;
  $db = shift;
  $admin = shift;
  $CONF = shift;
  my $attr = shift;

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $CONF,
  };

  bless($self, $class);

  $html = $attr->{HTML} if $attr->{HTML};
  $lang = $attr->{LANG} if $attr->{LANG};

  return $self;
}

#**********************************************************
=head2 maps_layers()

=cut
#**********************************************************
sub maps_layers {
  return {
    LAYERS => [ {
      id              => '50',
      name            => 'WEATHER',
      lang_name       => $lang->{WEATHER},
      module          => 'Weather',
      structure       => 'MARKER',
      clustering      => 0,
      export_function => 'weather_show',
      add_func        => 'weather_map',
      custom_params   => {
        SAVE_AS_GEOMETRY => 1,
      },
    } ]
  };
}

#**********************************************************
=head2 weather_show()

=cut
#**********************************************************
sub weather_show {

  return 1;
}

1;