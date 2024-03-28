package Equipment::Maps_info;

=head1 NAME

  Equipment::Maps_info - info for map

=head1 VERSION

  VERSION: 1.00
  REVISION: 20201021

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
  $db,
  $Equipment,
  %FORM,
);

use constant {
  EQUIPMENT_MAPS_LAYER_ID => 7,
  PON_MAPS_LAYER_ID       => 20
};

our @EXPORT = qw(
  EQUIPMENT_MAPS_LAYER_ID
  PON_MAPS_LAYER_ID
);

my $Auxiliary;

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

  require Equipment;
  Equipment->import();
  $Equipment = Equipment->new($db, $admin, $CONF);

  require Maps::Auxiliary;
  Maps::Auxiliary->import();
  $Auxiliary = Maps::Auxiliary->new($db, $admin, $CONF, { HTML => $html, LANG => $lang });

  return $self;
}

#**********************************************************
=head2 location_info($attr)

=cut
#**********************************************************
sub location_info {
  my $self = shift;
  my ($attr) = @_;

  my $location_id = $attr->{LOCATION_ID};

  my $equipment_info_list = $Equipment->_list({
    LOCATION_ID => $location_id,
    COLS_NAME   => 1,
    NAS_NAME    => '_SHOW',
    NAS_IP      => '_SHOW',
    NAS_ID      => '_SHOW',
    STATUS      => '_SHOW',
    MODEL_NAME  => '_SHOW',
    MAC         => '_SHOW',
  });

  return {} if ::_error_show($Equipment);

  my $index = ::get_function_index('equipment_info');
  my %colors = (0 => 'success', 1 => 'danger', 3 => 'danger', 4 => 'warning');
  my $tb = '';
  my $st = 0;

  foreach my $equipment (@{$equipment_info_list}) {
    $st = $st + $equipment->{status};
    my $link = "<a href='index.cgi?index=$index&NAS_ID=$equipment->{nas_id}'>$equipment->{nas_name}</a>";
    $tb .= "<div class='panel panel-$colors{$equipment->{status} || 0}'>" .
      "<div class='panel-heading'><h3 class='panel-title'>$link</h3></div>" .
      "<ul class='list-group'>" .
      "<li class='list-group-item'>IP: $equipment->{nas_ip}</li>" .
      "<li class='list-group-item'>$lang->{MODEL}: $equipment->{model_name}</li>" .
      "</ul>" .
      "</div>";
  }
  my $group = "<div class='panel-group'>$tb</div>";

  return {
    HTML  => $group,
    COLOR => ($st > 0) ? 'fire' : 'green',
    COUNT => 1
  }
}

#**********************************************************
=head2 maps_layers()

=cut
#**********************************************************
sub maps_layers {
  return {
    LAYERS => [ {
      id              => '7',
      name            => 'EQUIPMENT',
      lang_name       => $lang->{EQUIPMENT},
      module          => 'Equipment',
      structure       => 'MARKER',
      clustering      => 1,
      export_function => 'equipment_maps'
    }, {
      id              => '20',
      name            => 'PON',
      lang_name       => 'PON',
      module          => 'Equipment',
      structure       => 'MARKER',
      clustering      => 1,
      export_function => 'pon_maps'
    } ]
  }
}

#**********************************************************
=head2 equipment_maps()

=cut
#**********************************************************
sub equipment_maps {
  my $self = shift;
  my ($attr) = @_;

  my $equipment_list = $Equipment->_list_with_coords({
    NAS_ID    => $FORM{NAS_ID} || $attr->{NAS_ID} || '_SHOW',
    STATUS    => '_SHOW',
    COLS_NAME => 1,
    PAGE_ROWS => 10000,
  });
  ::_error_show($Equipment);

  return $Equipment->{TOTAL} if $attr->{ONLY_TOTAL};

  my @export_arr = ();
  foreach my $point (@{$equipment_list}) {

    my $equipment_info = '';
    my $info = '';
    my $count = '';
    my $color = '';

    if ($attr->{RETURN_JSON}) {
      my $result = $self->location_info({ LOCATION_ID => $point->{location_id}, TYPE => 'NAS' });

      if ($result && $result->{HTML}) {
        $result->{HTML} =~ s/\n/ /gm;
        $result->{HTML} =~ s/\+"+/'/gm;
        $equipment_info = $result;
      }
    }

    if (ref $equipment_info eq 'HASH') {
      $info = $equipment_info->{HTML} || '';
      $count = $equipment_info->{COUNT} || 0;
      $color = $equipment_info->{COLOR} || 'green';
    }

    $point->{coordy} ||= $point->{coordx_2};
    $point->{coordx} ||= $point->{coordy_2};

    my $add_class = $color ne 'green' ? 'danger-equipment ' : '';

    my %equipment = (
      MARKER   => {
        ID           => $point->{nas_id},
        COORDX       => $point->{coordy},
        COORDY       => $point->{coordx},
        INFO         => $info,
        TYPE         => $color ? "nas_$color" : "nas_green",
        COUNT        => $count,
        OBJECT_ID    => $point->{location_id},
        DISABLE_EDIT => 1,
        LAYER_ID     => EQUIPMENT_MAPS_LAYER_ID,
        ADD_CLASS    => $add_class,
      },
      LAYER_ID => EQUIPMENT_MAPS_LAYER_ID
    );

    push @export_arr, \%equipment;
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
=head2 pon_maps()

   $attr
     NAS_ID
     ONLY_TOTAL
     RETURN_HASH
     EXPORT_LIST
     RETURN_JSON

=cut
#**********************************************************
sub pon_maps {
  my $self = shift;
  my ($attr) = @_;

  my $equipment_list = $Equipment->onu_list({ #XXX pay attention to DELETED status?
    NAS_ID      => ($attr->{NAS_ID}) ? $attr->{NAS_ID} : '_SHOW',
    LOCATION_ID => '!',
    MAPS_COORDS => '!',
    LOGIN       => '_SHOW',
    UID         => '_SHOW',
    RX_POWER    => '_SHOW',
    NAS_NAME    => '_SHOW',
    COLS_NAME   => 1,
    PAGE_ROWS   => 100000
  });
  ::_error_show($Equipment);

  my @export_arr = ();
  my $count = 0;
  my %builds_info = ();

  foreach my $point (@{$equipment_list}) {
    my ($color, $panel_color) = _pon_state($point->{rx_power});

    push @{$builds_info{$point->{build_id}}}, {
      rx_power  => $point->{rx_power},
      color     => $color,
      row_color => $panel_color,
      uid       => $point->{uid} || '',
      address   => "$point->{address_street}, $point->{address_build}",
      coordx    => $point->{coordx},
      coordy    => $point->{coordy}
    };
  }

  foreach my $build (keys %builds_info) {
    my $build_info = $builds_info{$build}[0];
    my $marker_info = $Auxiliary->maps_point_info_table($html, $lang, {
      OBJECTS           => $builds_info{$build},
      TABLE_TITLES      => [ 'UID', 'RX_POWER', 'ADDRESS', ],
      TABLE_LANG_TITLES => [ $lang->{USER}, $lang->{SIGNAL}, $lang->{ADDRESS} ],
      LINK_ITEMS        => {
        'uid' => {
          'index'        => 15,
          'EXTRA_PARAMS' => { 'UID' => 'uid' }
        },
      }
    });

    push @export_arr, {
      MARKER   => {
        LAYER_ID     => PON_MAPS_LAYER_ID,
        OBJECT_ID    => $build,
        COORDX       => $build_info->{coordy},
        COORDY       => $build_info->{coordx},
        TYPE         => "pon_" . $build_info->{color},
        INFOWINDOW   => $marker_info,
        NAME         => $build_info->{address},
        DISABLE_EDIT => 1
      },
      LAYER_ID => PON_MAPS_LAYER_ID
    };
  }

  my %showed_equipment = ();
  $equipment_list = $Equipment->_list({
    NAS_ID      => ($attr->{NAS_ID}) ? $attr->{NAS_ID} : '_SHOW',
    MODEL_NAME  => '_SHOW',
    NAS_NAME    => '_SHOW',
    NAS_IP      => '_SHOW',
    COORDX      => '!',
    COORDY      => '!',
    TYPE_ID     => '4',
    LOCATION_ID => '_SHOW',
    COLS_NAME   => 1,
    PAGE_ROWS   => 100000,
  });
  ::_error_show($Equipment);

  foreach my $point (@{$equipment_list}) {
    my $ports = "";
    my $equipment_ports_list = $Equipment->pon_port_list({
      NAS_ID    => $point->{nas_id},
      COLS_NAME => 1,
      PAGE_ROWS => 100000,
      SORT      => 1,
    });

    foreach my $item (@{$equipment_ports_list}) {
      $ports .= $html ? ($html->badge($item->{branch}) . " ") : "$item->{branch} ";
    }

    my $coordx = $point->{coordx};
    my $coordy = $point->{coordy};
    if ($showed_equipment{$point->{coordy} . ":" . $point->{coordx}}) {
      $coordx = $coordx + 0.000005 * + +$showed_equipment{$point->{maps_coords}};
    }
    else {
      $showed_equipment{$point->{coordy} . ":" . $point->{coordx}} = 1;
    }

    my $color = 'olt';
    my $panel_color = "success";

    my $index = ::get_function_index('equipment_info');
    my $link = "OLT:<a href='index.cgi?index=$index&NAS_ID=$point->{nas_id}' target='_blank'> $point->{nas_name}</a>";
    my $tb = "<div class='panel panel-$panel_color'>" .
      "<div class='panel-heading'><h3 class='panel-title'>$link</h3></div>" .
      "<ul class='list-group'>" .
      "<li class='list-group-item'>IP: $point->{nas_ip}</li>" .
      "<li class='list-group-item'>$lang->{MODEL}: $point->{model_name}</li>" .
      "<li class='list-group-item'>$lang->{PORTS}: $ports</li>" .
      "</ul>" .
      "</div>";
    my $info = "<div class='panel-group'>$tb</div>";

    if ($attr->{TO_VISUAL}) {
      $info =~ s/\'/\\"/g;
    }

    $count++;
    $point->{location_id} ||= $point->{build_id};

    my %pon = (
      MARKER   => {
        ID           => $point->{nas_id} . $count,
        COORDX       => $coordy,
        COORDY       => $coordx,
        INFO         => $info,
        TYPE         => $color,
        OBJECT_ID    => $point->{location_id},
        LAYER_ID     => PON_MAPS_LAYER_ID
      },
      LAYER_ID => PON_MAPS_LAYER_ID
    );

    push @export_arr, \%pon;
  }

  $count = @export_arr;
  return $count if $attr->{ONLY_TOTAL};
  return \@export_arr if $attr->{RETURN_HASH};

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
=head2 maps_report_info()

=cut
#**********************************************************
sub maps_report_info {
  my $self = shift;
  my $layer_id = shift;

  return '' if !$layer_id;

  return $self->_maps_equipments_report_info() if ($layer_id eq EQUIPMENT_MAPS_LAYER_ID);
}

#**********************************************************
=head2 _maps_equipments_report_info()

=cut
#**********************************************************
sub _maps_equipments_report_info {
  my $self = shift;

  my $equipments = $Equipment->_list_with_coords({
    STATUS    => '_SHOW',
    NAS_NAME  => '_SHOW',
    COLS_NAME => 1,
    PAGE_ROWS => 10000,
  });

  my $report_table = $html->table({
    width       => '100%',
    caption     => $lang->{EQUIPMENT},
    title_plain => [ '#', $lang->{NAME}, $lang->{CREATED}, $lang->{LOCATION} ],
    DATA_TABLE  => 1
  });

  foreach my $equipment (@{$equipments}) {
    my $location_btn = $Auxiliary->maps_show_object_button(EQUIPMENT_MAPS_LAYER_ID, $equipment->{location_id});
    $report_table->addrow($equipment->{id}, $equipment->{nas_name}, $equipment->{created}, $location_btn);
  }

  return $report_table->show();
}

#**********************************************************
=head2 _pon_state($rx_power)

=cut
#**********************************************************
sub _pon_state {
  my $rx_power = shift;

  my $color = 'normal';
  my $panel_color = "success";

  if (!$rx_power || $rx_power == 65535) {
    $color = "off";
    $panel_color = "default";
  }
  elsif ($rx_power > 0) {
    $color = "off";
    $panel_color = "default";
  }
  elsif ($rx_power < -8 && $rx_power > -27) {
    $color = "normal";
    $panel_color = "success";
  }
  elsif ($rx_power < -8 && $rx_power > -30) {
    $color = "not_normal";
    $panel_color = "danger";
  }
  else {
    $color = "off";
    $panel_color = "default";
  }

  return ( $color, $panel_color );
}

1;
