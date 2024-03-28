package GPS::Maps_info;

=head1 NAME

  GPS::Maps_info - info for map

=head1 VERSION

  VERSION: 1.00
  REVISION: 20211209

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
my ($Gps, $Maps, $Auxiliary);

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

  my $self = { db => $db, admin => $admin, conf => $CONF };

  bless($self, $class);

  $html = $attr->{HTML} if $attr->{HTML};
  $lang = $attr->{LANG} if $attr->{LANG};

  require GPS;
  GPS->import();
  $Gps = GPS->new($db, $admin, $CONF);

  require Maps;
  Maps->import();
  $Maps = Maps->new($db, $admin, $CONF);

  $Auxiliary = Maps::Auxiliary->new($db, $admin, $CONF, { HTML => $html, LANG => $lang });

  return $self;
}

#**********************************************************
=head2 maps_layers()

=cut
#**********************************************************
sub maps_layers {
  return {
    LAYERS => [ {
      id              => 9,
      name            => 'GPS',
      lang_name       => 'GPS',
      module          => 'GPS',
      structure       => 'MARKERS_POLYLINE',
      export_function => 'maps_gps_show'
    } ]
  }
}

#**********************************************************

=head2 maps_gps_route_show($attr)

=cut

#**********************************************************
sub maps_gps_show {
  my $self = shift;
  my ($attr) = @_;

  my @export_arr = ();

  my $date_from = $attr->{FROM_DATE} || '';
  my $date_to = $attr->{TO_DATE} || '';

  my $tracked_admins = $Gps->tracked_admins_list($attr->{AID} || '');
  foreach my $admin (@{$tracked_admins}) {
    my $route = $Gps->tracked_admin_route_info($admin->{aid}, undef, {
      SHOW_ALL_COLUMNS => 1,
      FROM_DATE        => $date_from,
      TO_DATE          => $date_to,
      PAGE_ROWS        => !$date_from ? 1 : 99999,
      DESC             => !$date_from ? 'DESC' : '',
    });
    next if $route == 0;

    my $result = $Gps->admins_color_info({ AID => $admin->{aid} });
    my $color = $Gps->{TOTAL} > 0 ? $result->{COLOR} : '#49bcff';


    my %coords_by_date = ();

    my @coords = ();
    my @points_info = ();
    foreach my $point ( @{$route}) {
      push @{$coords_by_date{$point->{gps_date}}{coords}}, [ $point->{coord_y}, $point->{coord_x} ];

      my $tb = "<div class='panel panel-info'>" .
        "<ul class='list-group'>" .
          _gps_info_item('far fa-user', $lang->{ADMIN}, $admin->{name}) .
          _gps_info_item('fa fa-battery-half', $lang->{BATTERY}, "$point->{battery}%") .
          _gps_info_item('far fa-calendar', $lang->{DATE}, $point->{gps_time}) .
          _gps_info_item('fa fa-tachometer-alt', $lang->{SPEED}, $point->{speed}) .
        "</ul>" .
        "</div>";
      my $info = "<div class='panel-group'>$tb</div>";
      $info .= "<button class='btn btn-default btn-sm mt-1 route-$admin->{aid}'><i class='fa fa-road'></i> $lang->{ROUTE}</button>";

      push @{$coords_by_date{$point->{gps_date}}{info}}, $info;
      push @{$coords_by_date{$point->{gps_date}}{speed}}, $point->{speed};
    }

    push @export_arr, {
      GPS      => {
        coords => \%coords_by_date,
        SVG    => _gps_car_icon($color),
        icons  => {
          point => _gps_info_icon($color)
        },
        color  => $color,
        aid    => $admin->{aid},
        locale => $html->{content_language} || 'en'
      },
      LAYER_ID => 9,
    };
  }

  my $count = @export_arr;
  return $count if $attr->{ONLY_TOTAL};

  my $export_string = JSON::to_json(\@export_arr, { utf8 => 0 });
  if ($attr->{RETURN_JSON}) {
    print $export_string;
    return 1;
  }

  return $export_string;
}

#**********************************************************
=head2 _gps_info_item()

=cut
#**********************************************************
sub _gps_info_item {
  my ($icon, $key, $value) = @_;

  return qq{
    <li class='list-group-item p-1 d-flex'>
      <i class='$icon p-2' style='font-size: 16px;min-width: 36px;'></i>
      <div><div><p class='m-0'><strong>$value</strong></p></div><div><p class='m-0 small text-muted'>$key</p></div></div>
    </li>
  }
}

#**********************************************************
=head2 _gps_info_icon()

=cut
#**********************************************************
sub _gps_info_icon {
  my $color = shift;
  $color ||= '#49bcff';

  return qq{
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" aria-labelledby="title"
      aria-describedby="desc" role="img" xmlns:xlink="http://www.w3.org/1999/xlink">
      <title>Aim</title>
      <desc>A color styled icon from Orion Icon Library.</desc>
      <circle data-name="layer1"
      cx="32" cy="32" r="22" fill-opacity="0"></circle>
      <path data-name="opacity" d="M32 10a21.9 21.9 0 0 0-16.5 7.5 22 22 0 0 1 31 31A22 22 0 0 0 32 10z"
      fill="#000028" opacity=".15"></path>
      <path data-name="stroke" fill="none" stroke="$color" stroke-linecap="round"
      stroke-linejoin="round" stroke-width="2" d="M32 2v16m0 28v16M18 32H2m60 0H46"></path>
      <circle data-name="stroke" cx="32" cy="32" r="22" fill="none" stroke="$color"
      stroke-linecap="round" stroke-linejoin="round" stroke-width="2"></circle>
    </svg>
  };
}

#**********************************************************
=head2 _gps_car_icon()

=cut
#**********************************************************
sub _gps_car_icon {
  my $color = shift;

  $color ||= '#49bcff';
  return qq{
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" aria-labelledby="title"
      aria-describedby="desc" role="img" xmlns:xlink="http://www.w3.org/1999/xlink">
      <title>Car</title>
      <desc>A color styled icon from Orion Icon Library.</desc>
      <path data-name="layer3"
      d="M4 28h39l-5.5-10a3.7 3.7 0 0 0-3.1-2H10.3c-1 0-2 1-2.6 2S1.8 29 1.8 29A3 3 0 0 1 4 28z"
      fill="#c3d6e0"></path>
      <circle data-name="layer2" cx="14" cy="42" r="6" fill="#7b8baf"></circle>
      <circle data-name="layer2" cx="50" cy="42" r="6" fill="#7b8baf"></circle>
      <path data-name="layer1" d="M59 28H5a3 3 0 0 0-3 3v11h6a6 6 0 0 1 12 0h24a6 6 0 0 1 12 0h6V31a3 3 0 0 0-3-3z"
      fill="$color"></path>
      <circle data-name="opacity" cx="14" cy="42" r="3" fill="#000064"
      opacity=".2"></circle>
      <circle data-name="opacity" cx="50" cy="42" r="3" fill="#000064"
      opacity=".2"></circle>
      <path data-name="opacity" d="M18.2 16l-12 12H16l12-12zm19.3 2a4.1 4.1 0 0 0-2-1.8L23.7 28h5.7l8.8-8.8z"
      fill="#fff" opacity=".5"></path>
      <path data-name="opacity" d="M7 28H5a3 3 0 0 0-3 3v11h6a6 6 0 0 1 .9-3.1H7zm49 14h6v-3.1h-6.9A6 6 0 0 1 56 42zm-36
      0h24a6 6 0 0 1 .9-3.1H19.1A6 6 0 0 1 20 42z"
      fill="#000064" opacity=".15"></path>
      <path data-name="stroke" d="M44 28l-5.5-10a3.7 3.7 0 0 0-3.1-2H11.3c-1 0-2 1-2.6 2S2.8 29 2.8 29"
      fill="none" stroke="#2e4369" stroke-linecap="round" stroke-linejoin="round"
      stroke-width="2"></path>
      <path data-name="stroke" d="M56 42h6V31a3 3 0 0 0-3-3H5a3 3 0 0 0-3 3v11h6m12 0h24"
      fill="none" stroke="#2e4369" stroke-linecap="round" stroke-linejoin="round"
      stroke-width="2"></path>
      <circle data-name="stroke" cx="14" cy="42" r="6" fill="none" stroke="#2e4369"
      stroke-linecap="round" stroke-linejoin="round" stroke-width="2"></circle>
      <circle data-name="stroke" cx="50" cy="42" r="6" fill="none"
      stroke="#2e4369" stroke-linecap="round" stroke-linejoin="round" stroke-width="2"></circle>
    </svg>
  };
}

1;