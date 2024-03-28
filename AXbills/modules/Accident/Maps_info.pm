package Accident::Maps_info;

=head1 NAME

  Accident::Maps_info - info for map

=head1 VERSION

  VERSION: 1.00
  CREATED: 20220928

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

my ($Maps, $Accident);
my $layer_id = 53;

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

  require Accident;
  Accident->import();
  $Accident = Accident->new($db, $admin, $CONF);

  require Maps;
  Maps->import();
  $Maps = Maps->new($db, $admin, $CONF);

  return $self;
}

#**********************************************************
=head2 maps_layers()

     LAYERS => [ {
      id
      name
      lang_name
      module
      structure
      clustering
      export_function
      filter
      button_prev_next  # click on layer and show prev-next button instead of checklist
      sublayers
      custom_params
    } ]

=cut
#**********************************************************
sub maps_layers {
  return {
    LAYERS => [ {
      id              => $layer_id,
      name            => 'ACCIDENTS',
      lang_name       => $lang->{ACCIDENTS},
      module          => 'Accident',
      structure       => 'MARKER',
      clustering      => 0,
      export_function => 'accidents_maps',
      filter          => 'ACCIDENTS_DATE',
      button_prev_next=> 1,
      sublayers       => [],
      custom_params   => {
        SAVE_AS_GEOMETRY => 1,
      },
    } ]
  };
}

#**********************************************************
=head2 accidents_show()

=cut
#**********************************************************
sub accidents_maps {
  my $self = shift;
  my ($attr) = @_;

  my $accident_list = $Accident->list_with_coords({
    COLS_NAME => 1,
    PAGE_ROWS => 100,
  });
  ::_error_show($Accident);

  return $Accident->{TOTAL} if $attr->{ONLY_TOTAL};

  my @export_arr = ();
  foreach my $point (@{$accident_list}) {

    my $link = "<a href='index.cgi?index=414&chg=$point->{id}' target='_blank'> $point->{name}</a>";
    my $tb = "<div class='panel panel-info'>" .
      "<ul class='list-group'>" .
      _accident_info_item('fa fa-exclamation-triangle', $point->{descr}, $link) .
      _accident_info_item('far fa-calendar', $lang->{DATE}, $point->{date}) .
      _accident_info_item('fa fa-map-marker', $lang->{ADDRESS}, $point->{full_address}) .
      "</ul>" .
      "</div>";
    my $info = "<div class='panel-group'>$tb</div>";

    my %accident = (
      MARKER   => {
        ID           => $point->{id},
        COORDX       => $point->{coordy},
        COORDY       => $point->{coordx},
        INFO         => $info,
        TYPE         => "circle_red",
        DISABLE_EDIT => 1,
        LAYER_ID     => $layer_id,
      },
      LAYER_ID => $layer_id,
      ACCIDENTS_DATE => [{ id => $point->{date}, name => $point->{date}}],
    );

      push @export_arr, \%accident;
  }

  my $export_string = JSON::to_json(\@export_arr, { utf8 => 0 });

  if ($attr->{EXPORT_LIST}) {
    if ($attr->{RETURN_JSON}) {
      print $export_string;
      return 1;
    }

    return $export_string;
  }

  return $export_string;

}

#**********************************************************
=head2 _accident_info_item()

  Attr:
    $icon
    $key
    $value

=cut
#**********************************************************
sub _accident_info_item {
  my ($icon, $key, $value) = @_;

  return qq{
    <li class='list-group-item p-1 d-flex'>
      <i class='$icon p-2' style='font-size: 16px;min-width: 36px;'></i>
      <div><div><p class='m-0'><strong>$value</strong></p></div><div><p class='m-0 small text-muted'>$key</p></div></div>
    </li>
  }
}

1;