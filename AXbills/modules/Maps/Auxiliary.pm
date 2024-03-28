package Maps::Auxiliary;

=head1 NAME

  Maps::Auxiliary - Auxiliary functions for Maps

=head1 VERSION

  VERSION: 1.00
  REVISION: 20201020

=cut

use strict;
use warnings FATAL => 'all';
use parent qw(Exporter);

our $VERSION = 1.00;

use AXbills::Base qw/in_array/;
use Maps::Shared qw/LAYER_ID_BY_NAME MAPS_ICONS_DIR_WEB_PATH/;
my $Maps;

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

  if (in_array('Maps', \@::MODULES)) {
    eval { require Maps; };
    if (!$@) {
      Maps->import();
      $Maps = Maps->new($db, $admin, $CONF);
    }
  }

  return $self;
}

#**********************************************************
=head2 maps_point_color($point_count, $max_points) - get color for point

  Arguments:
    $point_count  - Point object count
    $max_points   - Points max objects

  Returns:
    string - color name

=cut
#**********************************************************
sub maps_point_color {
  my $self = shift;
  my ($point_count, $max_points) = @_;

  my $color = 'grey';

  return $color unless ($point_count);

  #Fire for top 3
  if ($point_count > 2 && $max_points->[2] && $point_count >= $max_points->[2]) {
    $color = 'fire';
  }

  #Other points by colors
  elsif ($point_count > 0 && $point_count < 3) {
    $color = 'grey';
  }
  elsif ($point_count < 5) {
    $color = 'green';
  }
  elsif ($point_count < 10) {
    $color = 'blue';
  }
  elsif ($point_count >= 10) {
    $color = 'yellow';
  }

  return $color;
}

#**********************************************************
=head2 _maps_points_count($list, $object_info, $attr) - Counts points

  Arguments:
    $list - arr_ref for DB list
    $object_info - DB list
    $attr - hash_ref
      KEY    - string, key for which to count

  Returns:
    arr_ref - array that contains sorted count

=cut
#**********************************************************
sub maps_points_count {
  my $self = shift;
  my ($list, $object_info, $attr) = @_;

  my $key = (defined $attr->{KEY}) ? $attr->{KEY} : 'id';

  my %max_objects_on_point = ();
  foreach my $line (@{$list}) {
    next if !($object_info->{$line->{$key}});

    $max_objects_on_point{ $line->{$key} } = $#{$object_info->{ $line->{$key} }} + 1;
  }

  my @max_arr = sort {$b <=> $a} values %max_objects_on_point;

  return \@max_arr;
}

#**********************************************************
=head2 maps_point_info_table($attr) - Make point info window

  Arguments:
    $html,
    $attr
      OBJECTS - Data form map Hash ref
            [{
              login   => 'test',
              deposit => 1.11
            }]

      TABLE_TITLES - array_ref Location table information fields

  Returns:
    string - HTML table with information

=cut
#**********************************************************
sub maps_point_info_table {
  my $self = shift;
  my ($attr) = @_;

  my $point_info_object = '<div class="card card-primary card-outline">';

  $point_info_object .= '<div class="card-header with-border"><h4 class="card-title">' . $attr->{TABLE_TITLE} .
    '</h4></div>' if ($attr->{TABLE_TITLE});

  $point_info_object .= '<div style="max-height: 300px;overflow-y: scroll;">' .
    '<table class="table table-condensed table-hover table-bordered">';
  my $objects = $attr->{OBJECTS};
  my $table_titles = $attr->{TABLE_TITLES};

  return q{} unless ($objects && ref $objects eq 'ARRAY' && scalar @{$objects});

  my $online_block = $html->element('span', '', {
    class => 'far fa-check-circle text-green',
    title => $lang->{ONLINE}
  });

  # Add headers
  if ($attr->{TABLE_LANG_TITLES} && ref $attr->{TABLE_LANG_TITLES} eq 'ARRAY') {
    $point_info_object .= '<tr>' . join('', map {'<th>' . ($_ || q{}) . '</th>'} @{$attr->{TABLE_LANG_TITLES}}) . '</tr>';
  }

  my $editable_fields = $attr->{EDITABLE_FIELDS} && ref($attr->{EDITABLE_FIELDS}) eq 'ARRAY' ? $attr->{EDITABLE_FIELDS} : [];

  foreach my $u (@{$objects}) {
    $point_info_object .= $u->{row_color} ? "<tr class='table-$u->{row_color}'>" : '<tr>';

    for (my $i = 0; $i <= $#{$table_titles}; $i++) {
      my $value = $table_titles->[$i];
      next unless $value;

      $value = _maps_get_value_for_table($html, {
        OBJECT        => $u,
        FIELD_ID      => lc($table_titles->[$i]),
        TITLE         => $value,
        ONLINE_BLOCK  => $online_block,
        LINK_ITEMS    => $attr->{LINK_ITEMS},
        DEFAULT_VALUE => $attr->{DEFAULT_VALUE},
      });

      next if $value eq '-1';

      my $ext_params = !$attr->{TO_SCREEN} ? "data-field='$table_titles->[$i]'" : '';

      if (in_array($table_titles->[$i], $editable_fields) && $attr->{CHANGE_FUNCTION}) {
        $ext_params .= " onclick='editField(this)'";
        $ext_params .= " data-url='?header=2&get_index=$attr->{CHANGE_FUNCTION}&RETURN_JSON=1&change=1'";
        $ext_params .= " data-id='$u->{id}'";
      }

      $point_info_object .= '<td ' . $ext_params . '>' . ($value || q{}) . '</td>';
    }

    $point_info_object .= '</tr>';
  }

  $point_info_object .= '</table></div></div>';
  $point_info_object =~ s/\"/\\\"/gm if $attr->{TO_SCREEN};

  return $point_info_object;
}

#**********************************************************
=head2 _maps_get_link_value($attr)

  Arguments:
    $attr

  Returns:

=cut
#**********************************************************
sub _maps_get_link_value {
  my ($object, $field_id, $attr) = @_;

  my $index_link = $attr->{LINK_ITEMS}{$field_id}{index} || "";
  return 0 if !$index_link;

  $object->{$field_id} = $attr->{DEFAULT_VALUE}{$field_id} if (!$object->{$field_id} && $attr->{DEFAULT_VALUE}{$field_id});

  my $link = '<a href="?index=' . $index_link;

  foreach my $extra_key (sort keys %{$attr->{LINK_ITEMS}{$field_id}{EXTRA_PARAMS}}) {
    my $link_value = $attr->{LINK_ITEMS}{$field_id}{EXTRA_PARAMS}->{$extra_key};
    next if !$object->{$link_value};

    $link .= "&$extra_key=$object->{$link_value}";
  }

  return $link . '" target=_blank>' . ($object->{$field_id} || '') . '</a>';
}

#**********************************************************
=head2 _maps_get_value_for_table($attr)

  Arguments:
    $html,
    $attr

  Returns:

=cut
#**********************************************************
sub _maps_get_value_for_table {
  my ($html, $attr) = @_;

  return -1 if (!$attr->{OBJECT} || !$attr->{FIELD_ID});
  my $value = '';

  if ($attr->{TITLE} eq 'LOGIN' && $attr->{OBJECT}{uid}) {
    $value = $html->button($attr->{OBJECT}{$attr->{FIELD_ID}}, "index=15&UID=$attr->{OBJECT}{uid}");
  }
  elsif ($attr->{TITLE} eq 'DEPOSIT' && defined($attr->{OBJECT}{'deposit'})) {
    my $deposit = sprintf("%.2f", $attr->{OBJECT}{'deposit'});
    $value = $attr->{OBJECT}{$attr->{FIELD_ID}} < 0 ? qq{<div class="text-danger">$deposit</div>} : $deposit;
  }
  elsif ($attr->{TITLE} eq 'ADDRESS_FLAT') {
    $value = $html->b($attr->{OBJECT}->{$attr->{FIELD_ID}});
  }
  elsif ($attr->{TITLE} eq 'ONLINE') {
    $value = ($attr->{OBJECT}{$attr->{FIELD_ID}}) ? $attr->{ONLINE_BLOCK} : 0;
  }
  elsif ($attr->{LINK_ITEMS} && $attr->{LINK_ITEMS}{$attr->{FIELD_ID}}) {
    $value = _maps_get_link_value($attr->{OBJECT}, $attr->{FIELD_ID}, $attr);
    return -1 unless $value;
  }
  else {
    $value = (ref $attr->{OBJECT} eq 'HASH' && $attr->{OBJECT}{$attr->{FIELD_ID}}) ? $attr->{OBJECT}{$attr->{FIELD_ID}} : '';
    $value =~ s/[\r\n]/ /g;
  }

  return $value;
}

#**********************************************************
=head2 maps_load_info($attr) - Loads information for location from specified module

  Arguments:
    $attr - hash_ref
      LOCATION_ID   - location id
      TYPE          - map object type

  Returns:
    hash_ref
      HTML  - Infowindow content
      COUNT - count for object

=cut

#**********************************************************
sub maps_load_info {
  my $self = shift;
  my ($module_name, $attr) = @_;

  my $module = $self->maps_load_module($module_name);

  return {} if !$module;
  return {} if !$module->can('new') || !$module->can('location_info');

  my $module_object = $module->new($db, $admin, $CONF, { HTML => $html, LANG => $lang });
  my $result = $module_object->location_info($attr);

  return {} if !$result || ref $result ne 'HASH' || !$result->{HTML};

  $result->{HTML} =~ s/\n/ /gm;
  $result->{HTML} =~ s/\+"+/'/gm;

  return $result;
}

#**********************************************************
=head2 maps_load_module($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub maps_load_module {
  my $self = shift;
  my $module_name = shift;

  return if $module_name !~ /^[\w.]+$/;

  my $package_name = $module_name . "/Maps_info.pm";
  my $module = $module_name . '::Maps_info';

  eval { require $package_name };
  return 0 if $@;

  eval { $module->import() };
  return 0 if $@;

  return $module;
}

#**********************************************************
=head2 maps_show_object_button()

=cut
#**********************************************************
sub maps_show_object_button {
  my $self = shift;
  my ($layer_id, $object_id, $attr) = @_;

  return '' if !$Maps;

  $layer_id = $layer_id ? (LAYER_ID_BY_NAME->{$layer_id} || $layer_id) : 0;
  my $params = '';

  my %button_params = (
    class  => $attr->{BTN_CLASS} || 'btn btn-xs btn-primary',
    title  => $lang->{SHOW},
    ICON   => $attr->{ICON} || 'fa fa-globe',
    target => '_blank'
  );

  if ($attr->{CHECK_POINT} && $object_id) {
    my $point_info = $Maps->points_info($object_id);
    $attr->{ADD_POINT} = 1 if $Maps->{TOTAL} > 0 && !($point_info->{coordx} && $point_info->{coordy});
  }

  if ($attr->{CHECK_BUILD} && $object_id) {
    my $build2 = $Maps->build2_list_with_points({
      LOCATION_ID   => $object_id || '_SHOW',
      COORDS        => '_SHOW',
      OBJECT_ID     => '_SHOW',
      COLS_NAME     => 1,
    });

    if ($Maps->{TOTAL} > 0) {
      $layer_id = 12;
      $object_id = $build2->[0]{object_id};
      $attr->{ADD_POINT} = 0;
      $button_params{class} = 'btn btn-xs btn-success';
      $button_params{ICON} = 'fa fa-globe';
    }
  }

  $button_params{class} = 'btn btn-xs btn-warning disabled' if (exists $attr->{POINT_ID} && !$attr->{POINT_ID});

  if ($attr->{SHOW_IN_MAP}) {
    $button_params{ex_params} = qq/onclick="ObjectsConfiguration.panToObject($layer_id, $object_id)"/;
    $button_params{class} .= ' float-right';
    $button_params{JAVASCRIPT} = '';
    $button_params{SKIP_HREF} = 1;
    $button_params{NO_LINK_FORMER} = 1;
  }
  else {
    my $maps_index = ::get_function_index('maps_main');
    $params = "index=$maps_index&LAYER=$layer_id";
    $params .= "&OBJECT_ID=$object_id" if $object_id;
    $params .= "&ADD_POINT=1" if $attr->{ADD_POINT};

    return $params if ($attr->{RETURN_HREF});
  }

  my $name = ($attr && $attr->{NAME}) ? $attr->{NAME} : '';
  if ($name) {
    $button_params{ADD_ICON} = $button_params{ICON};
    delete $button_params{ICON}
  }

  if ($attr->{LOAD_TO_MODAL}) {
    $button_params{LOAD_TO_MODAL} = 1;
    $params =~ s/index=\d+/get_index=maps_main/;
    $params .= '&header=2&SMALL=1&MODAL=1&CLEAR_LAYERS=1';
  }

  return (!$html || ref $html eq 'HASH') ? '' : $html->button($name, $params, \%button_params);
}

#**********************************************************
=head2 maps_add_external_object()

=cut
#**********************************************************
sub maps_add_external_object {
  my $self = shift;
  my ($type_id, $attr) = @_;

  return if !$Maps;

  return if (!$type_id || ref $type_id);

  my $type_info = $Maps->point_types_info($type_id);
  ::_error_show($Maps);

  my $name = $attr->{NAME} || do {
    my $max_ids = $Maps->points_max_ids_for_types($type_id);
    ::_error_show($Maps);

    my $max_id = $max_ids->{$type_id} || '';
    ::_translate($type_info->{NAME}) . $max_id;
  };

  delete $attr->{ID};

  $Maps->points_add({
    %{$attr},
    EXTERNAL => 1,
    NAME     => $name,
    TYPE_ID  => $type_id,
  });
  ::_error_show($Maps);

  return $Maps->{errno} ? 0 : $Maps->{INSERT_ID};
}

1;
