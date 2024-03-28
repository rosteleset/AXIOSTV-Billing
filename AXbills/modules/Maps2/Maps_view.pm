package Maps2::Maps_view;

=head1 NAME

  Maps2 show map

=head1 VERSION

  VERSION: 1.00
  REVISION: 20201019

=cut

use strict;
use warnings FATAL => 'all';
use parent qw(Exporter);

our $VERSION = 1.00;

our @EXPORT = qw(
  show_map
  _isPolygon
);

my $MODULE = 'Maps_view';
use Maps2::Shared qw/LAYER_ID_BY_NAME MAPS_ICONS_DIR_WEB_PATH/;
use Maps2::Auxiliary qw/maps2_load_module/;
use Maps2::Maps_info;
use AXbills::Base qw/in_array/;

our (
  $admin,
  $CONF,
  $lang,
  $db,
  $users,
  $html
);

my $Maps_info;

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

  $Maps_info = Maps2::Maps_info->new($db, $admin, $CONF, $attr);

  return $self;
}

#**********************************************************
=head2 show_map($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub show_map {
  my $self = shift;
  my ($form, $attr) = @_;
  
  return 1 if $self->maps2_get_objects_to_show($form, $attr);
  
  my ($icon, $watermark_url) = $CONF->{MAPS_WATERMARK} ? split('\|', $CONF->{MAPS_WATERMARK}) : ('', '');

  my $javascript_vars = $html->tpl_show(::_include('maps2_js_variables', 'Maps2'),
    $self->maps2_get_js_variables($form, {
      %{$attr},
      HIDE_CONTROLS       => ($attr->{QUICK}) ? 1 : '',
      MAPS_DEFAULT_TYPE   => $CONF->{MAPS_DEFAULT_TYPE} || 'OSM',
      MAPS_DEFAULT_LATLNG => $CONF->{MAPS_DEFAULT_LATLNG} || '',
      MAPS_WATERMARK_URL  => $watermark_url,
      MAPS_WATERMARK_ICON => $icon
    }), { OUTPUT2RETURN => 1 }
  );

  my $map_show = $html->tpl_show(::_include('maps2_main', 'Maps2'), {
    JS_VARIABLES => $javascript_vars,
    MAP_HEIGHT   => $attr->{MAP_HEIGHT}
  }, { OUTPUT2RETURN => 1 });

  return $map_show;
}

#**********************************************************
=head2 maps2_get_objects_to_show($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub maps2_get_objects_to_show {
  my $self = shift;
  my ($form, $attr) = @_;

  $attr->{OBJECT_ID} ||= $form->{OBJECT_ID};

  if ($attr->{DATA} && $attr->{DONE_DATA}) {
    $form->{OBJECT_TO_SHOW} = $attr->{DATA};
  }
  elsif ($attr->{DATA} && !$attr->{MSGS_MAP} && !$attr->{SKIP_OBJECTS}) {
    if (ref $attr->{DATA} eq 'ARRAY') {
      $form->{OBJECT_TO_SHOW} = $self->maps2_get_custom_array_objects($attr);
    }
    elsif (ref $attr->{DATA} eq 'HASH') {
      $form->{OBJECT_TO_SHOW} = $self->maps2_get_custom_hash_objects($attr);
    }
  }
  elsif (!$attr->{SKIP_OBJECTS}) {
    $attr->{TO_SCREEN} = 0 if $form->{RETURN_HASH_OBJECT};
    $form->{OBJECT_TO_SHOW} = $self->maps2_get_build_objects($attr);

    if ($form->{RETURN_HASH_OBJECT}) {
      print JSON::to_json($form->{OBJECT_TO_SHOW}, { utf8 => 0 });
      return 1;
    }
  }

  return 0;
}

#**********************************************************
=head2 maps2_get_js_variables() - adds javascript variables

=cut
#**********************************************************
sub maps2_get_js_variables {
  my $self = shift;
  my ($form, $attr) = @_;

  my $layers_list = $Maps_info->maps_layers_list({%{$form}, %{$attr}});

  my $default_layer_ids = JSON::to_json(LAYER_ID_BY_NAME, { utf8 => 0 });
  my $layers = JSON::to_json($layers_list->{LAYERS}, { utf8 => 0 });

  delete $attr->{USER_INFO};
  delete $attr->{__BUFFER};
  delete $form->{__BUFFER};
  my $form_json = JSON::to_json({ %{$form}, %{$attr} }, { utf8 => 0 });

  my $options = JSON::to_json({
    SHOW_ADD_BTN => $attr->{SHOW_ADD_BTN} || 0,
    ICONS_DIR    => MAPS_ICONS_DIR_WEB_PATH,
    EDIT_MODE    => $attr->{SHOW_ADD_BTN} || 0
  }, { utf8 => 0 });

  return {
    LAYERS           => $layers,
    LAYER_ID_BY_NAME => $default_layer_ids,
    FORM             => $form_json,
    OPTIONS          => $options,
    EXTRA_SCRIPTS    => $layers_list->{EXTRA_SCRIPTS},
    GOOGLE_API_KEY   => $CONF->{GOOGLE_API_KEY},
    YANDEX_API_KEY   => $CONF->{YANDEX_API_KEY},
    VISICOM_API_KEY  => $CONF->{VISICOM_API_KEY},
    %{$attr},
  };
}

#**********************************************************
=head2 maps2_get_build_objects($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub maps2_get_build_objects {
  my $self = shift;
  my ($attr) = @_;

  my $result = '';
  my @objects;

  $result = $Maps_info->maps2_builds_show({
    %{$attr},
    EXPORT      => 1,
    RETURN_HASH => 1,
    TO_SCREEN   => defined $attr->{TO_SCREEN} ? $attr->{TO_SCREEN} : 1
  });
  map(push(@objects, $_), @{$result}) if defined($result) && ref($result) eq 'ARRAY' && scalar(@{$result}) > 0;

  $result = $Maps_info->maps2_builds2_show({
    %{$attr},
    EXPORT      => 1,
    RETURN_HASH => 1,
    TO_SCREEN   => defined $attr->{TO_SCREEN} ? $attr->{TO_SCREEN} : 1
  });
  map(push(@objects, $_), @{$result}) if defined($result) && ref($result) eq 'ARRAY' && scalar(@{$result}) > 0;

  return \@objects;
}

#**********************************************************
=head2 maps2_get_custom_hash_objects($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub maps2_get_custom_hash_objects {
  my $self = shift;
  my ($attr) = @_;

  my @objects;
  my $build_objects;
  my $map_type_icon = $attr->{MAP_TYPE_ICON} || ();
  my $map_icon = $attr->{MAP_ICON};

  foreach my $key (keys %{$attr->{DATA}}) {
    $build_objects = $self->maps2_get_build_objects({
      GET_LIKE_MARKER => $attr->{FULL_TYPE_URL} ? 1 : 0,
      LOCATION_ID     => $key,
      RETURN_HASH     => 1
    });
    
    $attr->{MAP_ICON} = $map_icon;
    if (ref $attr->{DATA}{$key} eq 'ARRAY' && $attr->{DATA}{$key}[0] && $map_type_icon) {
      if ($map_type_icon->{ICON_PATH} && $map_type_icon->{ICON_FIELD} && $attr->{DATA}{$key}[0]{$map_type_icon->{ICON_FIELD}}) {
        my $file_path = "$CONF->{TPL_DIR}/" . $attr->{MAP_TYPE_ICON}{ICON_EXIST_PATH} . $attr->{DATA}{$key}[0]{$map_type_icon->{ICON_FIELD}} . ".png";
        if (-e $file_path) {
          $attr->{MAP_ICON} ||= "$map_type_icon->{ICON_PATH}$attr->{DATA}{$key}[0]{$map_type_icon->{ICON_FIELD}}.png"
        }
      }
    }

    if ($attr->{MAP_SHOW_ITEMS} && $build_objects && ref $build_objects eq 'ARRAY') {
      foreach my $build (@{$build_objects}) {
        my $info = _maps2_get_custom_info($attr->{DATA}{$key}, {
          MAP_SHOW_ITEMS => $attr->{MAP_SHOW_ITEMS},
          TO_SCREEN      => $attr->{TO_SCREEN},
          LINK_ITEMS     => $attr->{MAP_SHOW_ITEMS}{LINK_ITEMS},
          DEFAULT_VALUE  => $attr->{MAP_SHOW_ITEMS}{DEFAULT_VALUE},
        });
        if (!$map_type_icon->{ICON_PATH} && _isPolygon({ LAYER_ID => $build->{LAYER_ID} })) {
          $build->{POLYGON}{INFO} = $info;
          $build->{POLYGON}{TYPE} = $attr->{MAP_ICON} if $attr->{MAP_ICON};
          $build->{POLYGON}{FULL_TYPE_URL} = $attr->{FULL_TYPE_URL} if $attr->{FULL_TYPE_URL} && $attr->{MAP_ICON};
        }
        else {
          $build->{MARKER}{INFO} = $info;
          $build->{MARKER}{TYPE} = $attr->{MAP_ICON} if $attr->{MAP_ICON};
          $build->{MARKER}{FULL_TYPE_URL} = $attr->{FULL_TYPE_URL} if $attr->{FULL_TYPE_URL} && $attr->{MAP_ICON};
        }

        push @objects, $build;
      }
    }
  }

  return $objects[0] ? \@objects : $build_objects;
}

#**********************************************************
=head2 maps2_get_custom_array_objects($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub maps2_get_custom_array_objects {
  my $self = shift;
  my ($attr) = @_;

  my $result = '';
  my @objects;
  my %objects_hash;

  foreach my $object (@{$attr->{DATA}}) {
    $object->{LOCATION_ID} = $object->{location_id} || $object->{build_id};
    next unless $object->{LOCATION_ID} || !$objects_hash{$object->{LOCATION_ID}};

    $objects_hash{$object->{LOCATION_ID}} = 1;
    $result = $self->maps2_get_build_objects($object);
    push @objects, $result->[0] if defined($result) && ref($result) eq 'ARRAY' && scalar(@{$result}) > 0;
  }

  return \@objects;
}

#**********************************************************
=head2 _maps2_get_custom_info($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub _maps2_get_custom_info {
  my ($objects, $attr) = @_;

  foreach my $key (reverse sort keys %{$attr->{MAP_SHOW_ITEMS}}) {
    next if $key eq "LINK_ITEMS" || $key eq 'DEFAULT_VALUE';

    push @{$attr->{TABLE_TITLES}}, uc $key;
    push @{$attr->{TABLE_LANG_TITLES}}, $attr->{MAP_SHOW_ITEMS}{$key};
  }

  my $info = Maps2::Auxiliary::maps2_point_info_table($html, $lang, {
    OBJECTS           => $objects,
    TABLE_TITLES      => $attr->{TABLE_TITLES},
    TABLE_LANG_TITLES => $attr->{TABLE_LANG_TITLES},
    LINK_ITEMS        => $attr->{LINK_ITEMS},
    DEFAULT_VALUE     => $attr->{DEFAULT_VALUE},
    TO_SCREEN         => 1
  });

  return $info
}

#***************************************************************
=head2 _isPolygon($attr)

=cut
##***************************************************************
sub _isPolygon {
  my ($attr) = @_;

  return in_array($attr->{LAYER_ID}, [LAYER_ID_BY_NAME->{BUILD2}, LAYER_ID_BY_NAME->{DISTRICT}, LAYER_ID_BY_NAME->{WIFI}]);
}

1;