package Maps::Maps_info;

=head1 NAME

  Maps::Maps_info - info for map

=head1 VERSION

  VERSION: 1.00
  REVISION: 20201022

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
my $Maps;
my $Address;

my $Auxiliary;
use Maps::Shared qw/LAYER_ID_BY_NAME/;
use AXbills::Base qw/in_array/;

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

  require Address;
  Address->import();
  $Address = Address->new($db, $admin, $CONF);

  require Maps::Auxiliary;
  Maps::Auxiliary->import();
  $Auxiliary = Maps::Auxiliary->new($db, $admin, $CONF, $attr);

  return $self;
}

#**********************************************************
=head2 maps_layers()

=cut
#**********************************************************
sub maps_layers {

  return {} if !$Maps;

  my @modules = @main::MODULES;
  my $layers_list = $Maps->layers_list({
    MODULE           => join(';', @modules),
    COLS_NAME        => 1,
    COLS_UPPER       => 0,
    SORT             => 'id',
    DESC             => 'DESC',
    SHOW_ALL_COLUMNS => 1,
  });
  return {} if ::_error_show($Maps);

  my $district_module = [ grep {$_->{id} eq LAYER_ID_BY_NAME->{DISTRICT}} @{$layers_list} ]->[0];
  if (defined $district_module) {
    $district_module->{add_func} = 'maps_districts_main';
    $district_module->{custom_params} = {
      OBJECT_TYPE_ID   => '',
      SAVE_AS_GEOMETRY => 1,
      RETURN_FORM      => 'COLOR'
    }
  }

  map $_->{module} = 'Maps', @{$layers_list};

  my %layer_export_list_name_refs = (
    LAYER_ID_BY_NAME->{BUILD}        => 'maps_builds_show',
    LAYER_ID_BY_NAME->{WIFI}         => 'maps_wifis_show',
    LAYER_ID_BY_NAME->{DISTRICT}     => 'maps_districts_show',
    LAYER_ID_BY_NAME->{ROUTE}        => 'maps_routes_show',
    LAYER_ID_BY_NAME->{TRAFFIC}      => 'maps_traffic_show',
    LAYER_ID_BY_NAME->{CUSTOM_POINT} => 'maps_objects_show',
    LAYER_ID_BY_NAME->{BUILD2}       => 'maps_builds2_show',
  );

  map $_->{export_function} = $layer_export_list_name_refs{$_->{id}}, @{$layers_list};

  return { LAYERS => $layers_list, };
}

#**********************************************************
=head2 location_info($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub location_info {
  my $self = shift;
  my ($attr) = @_;

  return unless ($attr->{LOCATION_ID});
  $attr->{TYPE} ||= 'BUILD';

  my $info = '';
  my $count = 0;
  my $color = '';

  CORE::state $users_for_location_id;
  CORE::state $online_uids;

  $online_uids = $self->_maps_get_online_users({ SHORT => 1 }) if (!$online_uids);

  if (!$users_for_location_id) {
    my $users_list = $self->_maps_get_users({ RETURN_AS_ARRAY => 1 });
    foreach my $user (@{$users_list}) {
      next unless $user->{build_id};

      my $location_id = $user->{build_id};
      $user->{online} = 1  if (exists $online_uids->{$user->{uid}});

      if ($users_for_location_id->{$location_id}) {
        push(@{$users_for_location_id->{$location_id}}, $user);
      }
      else {
        $users_for_location_id->{$location_id} = [ $user ];
      }
    }
  }

  if (defined $users_for_location_id->{ $attr->{LOCATION_ID} }) {
    $info = $Auxiliary->maps_point_info_table({
      TABLE_TITLE       => $lang->{USERS},
      OBJECTS           => $users_for_location_id->{ $attr->{LOCATION_ID} },
      TABLE_TITLES      => [ 'ONLINE', 'LOGIN', 'DEPOSIT', 'FIO', 'ADDRESS_FLAT' ],
      TABLE_LANG_TITLES => [ $lang->{ONLINE}, $lang->{LOGIN}, $lang->{DEPOSIT}, $lang->{FIO}, $lang->{FLAT} ],
      TO_SCREEN         => $attr->{TO_SCREEN}
    });
    $count = scalar @{$users_for_location_id->{ $attr->{LOCATION_ID} }};

    if ($CONF->{MAPS_BUILD_COLOR_BY_ONLINE}) {
      $color = (grep {$_->{online} && $_->{online} >= 1} @{$users_for_location_id->{ $attr->{LOCATION_ID} }}) ? 'green' : 'red';
    }

  }
  elsif ($attr->{GROUP_ID}) {
    return 0;
  }

  return {
    HTML  => $info,
    COUNT => $count,
    COLOR => $color
  }
}

#**********************************************************
=head2 maps_builds_show($attr)

  Arguments:
    $attr

  Returns:

=cut
#**********************************************************
sub maps_builds_show {
  my $self = shift;
  my ($attr) = @_;

  return '' if !$Maps;

  my $export = $attr->{EXPORT_LIST} || $attr->{EXPORT};
  my $object_info = $attr->{DATA};
  my $to_screen = $attr->{TO_SCREEN} || 0;
  my $count_object = 0;
  my @export_hash_arr = ();

  _maps_get_old_builds($attr, \$count_object, \@export_hash_arr, $object_info, $to_screen);
  _maps_get_new_builds($attr, \$count_object, \@export_hash_arr, $object_info);

  return $count_object if ($attr->{ONLY_TOTAL});
  return \@export_hash_arr if $attr->{RETURN_HASH};

  return '' if !$export;

  my $export_string = JSON::to_json(\@export_hash_arr, { utf8 => 0 });
  print $export_string;

  return $export_string;
}

#**********************************************************
=head2 maps_builds2_show($attr)

  Arguments:
    $attr

  Returns:

=cut
#**********************************************************
sub maps_builds2_show {
  my $self = shift;
  my ($attr) = @_;

  my $export = $attr->{EXPORT_LIST} || $attr->{EXPORT};
  my @export_hash_arr = ();
  my $to_screen = $attr->{TO_SCREEN} || 0;

  if ($attr->{RETURN_HASH_OBJECT}) {
    $attr->{LOCATION_ID} ||= $attr->{OBJECT_ID};
    delete $attr->{OBJECT_ID};
  }

  my $list_builds_objects = $Maps->build2_list_with_points({
    LOCATION_ID   => $attr->{LOCATION_ID} || '_SHOW',
    COORDS        => '_SHOW',
    FULL_ADDRESS  => '_SHOW',
    OBJECT_ID     => $attr->{OBJECT_ID} || '_SHOW',
    COORDX_CENTER => '_SHOW',
    COORDY_CENTER => '_SHOW',
    CREATED       => '_SHOW',
    COLS_NAME     => 1,
    PAGE_ROWS     => $attr->{NEW_OBJECT} ? 1 : ''
  });

  return $Maps->{TOTAL} if ($attr->{ONLY_TOTAL} || !$Maps->{TOTAL});

  foreach my $build (@{$list_builds_objects}) {
    next unless ($build->{object_id});

    next if $attr->{BUILD_IDS} && !in_array($build->{location_id}, $attr->{BUILD_IDS});

    my $info_hash = {};
    my $point_count = 0;

    $info_hash = $Auxiliary->maps_load_info('Maps', { LOCATION_ID => $build->{location_id}, TO_SCREEN => $to_screen }) if !$attr->{CLIENT_MAP};
    $point_count = $info_hash->{COUNT} || 0;

    my $color = $info_hash->{COLOR} || $Auxiliary->maps_point_color($point_count);
    my $info_table = $info_hash->{HTML} || '';

    my @points = split(',', $build->{coords});
    foreach my $point (@points) {
      my @point_array = split('\|', $point);
      push @{$build->{POLYGON}{POINTS}}, \@point_array;
    }

    my %regex = (
      ID        => $build->{object_id},
      OBJECT_ID => $build->{object_id},
      POLYGON   => {
        ID        => $build->{object_id},
        OBJECT_ID => $build->{object_id},
        NAME      => $build->{address_full},
        CREATED   => $build->{created},
        LAYER_ID  => LAYER_ID_BY_NAME->{BUILD2},
        INFO      => $info_table,
        COUNT     => $point_count,
        POINTS    => $build->{POLYGON}->{POINTS},
        COLOR     => $color
      },
      LAYER_ID  => LAYER_ID_BY_NAME->{BUILD2}
    );

    if ($attr->{GET_LIKE_MARKER}) {
      %regex = (
        ID        => $build->{object_id},
        OBJECT_ID => $build->{object_id},
        MARKER   => {
          ID        => $build->{object_id},
          OBJECT_ID => $build->{object_id},
          NAME      => $build->{address_full},
          LAYER_ID  => LAYER_ID_BY_NAME->{BUILD2},
          COORDX    => $build->{coordx_center},
          COORDY    => $build->{coordy_center},
          INFO      => $info_table,
          COLOR     => $color,
          TYPE      => "build_$color",
        },
        LAYER_ID  => LAYER_ID_BY_NAME->{BUILD2}
      );
    }

    push @export_hash_arr, \%regex;
  }

  return \@export_hash_arr if ($attr->{RETURN_HASH});

  return '' if !$export;

  my $export_string = JSON::to_json(\@export_hash_arr, { utf8 => 0 });
  print $export_string;

  return $export_string;
}

#**********************************************************
=head2 maps_wifis_show($attr)

=cut
#**********************************************************
sub maps_wifis_show {
  my $self = shift;
  my ($attr) = @_;

  my $list_wifi_objects = $self->_maps_get_layer_objects(LAYER_ID_BY_NAME->{WIFI}, {
    ID         => $attr->{OBJECT_ID} || '_SHOW',
    NEW_OBJECT => $attr->{NEW_OBJECT} || '',
    COLS_NAME  => 1
  });

  if ($attr->{ONLY_TOTAL}) {
    my $count = @{$list_wifi_objects};
    return $count;
  }

  my @export_arr = ();

  foreach my $wifi (@{$list_wifi_objects}) {
    next if !$wifi->{POLYGON};
    $wifi->{POLYGON}->{NAME} ||= '';
    my $points_json = JSON::to_json($wifi->{POLYGON}->{POINTS});
    $wifi->{OBJECT_ID} ||= 0;

    my %info = (
      ID        => $wifi->{POLYGON}->{ID},
      OBJECT_ID => $wifi->{OBJECT_ID},
      POLYGON   => {
        ID        => $wifi->{OBJECT_ID},
        OBJECT_ID => $wifi->{OBJECT_ID},
        NAME      => $wifi->{POLYGON}->{NAME},
        LAYER_ID  => @{[ LAYER_ID_BY_NAME->{WIFI} ]},
        POINTS    => $wifi->{POLYGON}->{POINTS},
        COLOR     => $wifi->{POLYGON}->{COLOR}
      },
      LAYER_ID  => @{[ LAYER_ID_BY_NAME->{WIFI} ]}
    );

    push @export_arr, \%info;
  }

  return \@export_arr if ($attr->{RETURN_HASH});
  return '' if !$attr->{RETURN_JSON};

  my $export_string = JSON::to_json(\@export_arr, { utf8 => 0 });
  print $export_string;

  return $export_string;
}

#**********************************************************
=head2 maps_districts_show()

=cut
#**********************************************************
sub maps_districts_show {
  my $self = shift;
  my ($attr) = @_;

  my $districts_list = $Maps->districts_list({
    OBJECT_ID   => $attr->{LAST_OBJECT_ID} ? "> $attr->{LAST_OBJECT_ID}" : $attr->{ID} ?
      $attr->{ID} : $attr->{OBJECT_ID} ? $attr->{OBJECT_ID} : '_SHOW',
    DISTRICT_ID => $attr->{DISTRICT_ID} || '_SHOW',
    DISTRICT    => '_SHOW',
    CREATED     => '_SHOW',
    LIST2HASH   => 'object_id,district_id'
  });

  my $district_for_object_id = ();
  foreach my $district (@{$districts_list}) {
    next unless ($district && $district->{object_id});
    $district_for_object_id->{$district->{object_id}} = $district;
  }

  my @object_ids = map {$_->{object_id}} @{$districts_list};

  my $layer_objects = $self->_maps_get_layer_objects(LAYER_ID_BY_NAME->{DISTRICT}, { ID => join(';', @object_ids) });
  ::_error_show($Maps);

  if ($attr->{ONLY_TOTAL}) {
    my $count = @{$layer_objects};
    return $count;
  }

  foreach my $object (@{$layer_objects}) {
    $object->{POLYGON}{name} = $district_for_object_id->{$object->{OBJECT_ID}}{district} || '';
    $object->{POLYGON}{created} = $district_for_object_id->{$object->{OBJECT_ID}}{created} || '';
    $object->{POLYGON}{NAME} = $district_for_object_id->{$object->{OBJECT_ID}}{district} || '';
  }

  return $layer_objects if ($attr->{RETURN_HASH});
  return '' if !$attr->{RETURN_JSON};

  my $export_string = JSON::to_json($layer_objects, { utf8 => 0 });
  print $export_string;

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

  return $self->_maps_wifis_report_info() if ($layer_id eq '2');
  return $self->_maps_builds_report_info() if ($layer_id eq '1');
  return $self->_maps_builds2_report_info() if ($layer_id eq '12');
  return $self->_maps_districts_report_info() if ($layer_id eq '4');
}

#**********************************************************
=head2 _maps_wifis_report_info()

=cut
#**********************************************************
sub _maps_wifis_report_info {
  my $self = shift;

  my $wifi_objects = $self->_maps_get_layer_objects(LAYER_ID_BY_NAME->{WIFI}, { ID => '_SHOW', COLS_NAME => 1 });

  my $report_table = $html->table({
    width       => '100%',
    caption     => 'Wi-Fi',
    title_plain => [ '#', $lang->{NAME}, $lang->{COLOR}, $lang->{CREATED}, $lang->{LOCATION} ],
    DATA_TABLE  => 1
  });

  foreach my $wifi (@{$wifi_objects}) {
    my $wifi_info = $wifi->{POLYGON};
    my $location_btn = $Auxiliary->maps_show_object_button(LAYER_ID_BY_NAME->{WIFI}, $wifi_info->{OBJECT_ID});
    $report_table->addrow($wifi_info->{ID}, $wifi_info->{NAME},
      $html->color_mark($wifi_info->{COLOR}, $wifi_info->{COLOR}), $wifi_info->{CREATED}, $location_btn);
  }

  return $report_table->show();
}

#**********************************************************
=head2 _maps_builds_report_info()

=cut
#**********************************************************
sub _maps_builds_report_info {
  my $self = shift;

  my $builds = $self->maps_builds_show({ RETURN_HASH => 1 });

  my $report_table = $html->table({
    width       => '100%',
    caption     => $lang->{BUILD},
    title_plain => [ '#', $lang->{ADDRESS}, $lang->{CREATED}, $lang->{LOCATION} ],
    DATA_TABLE  => 1
  });

  foreach my $build (@{$builds}) {
    my $build_info = $build->{MARKER};
    my $location_btn = $Auxiliary->maps_show_object_button(LAYER_ID_BY_NAME->{BUILD}, $build_info->{OBJECT_ID});
    $report_table->addrow($build_info->{ID}, $build_info->{NAME}, $build_info->{ADDED}, $location_btn);
  }

  return $report_table->show();
}

#**********************************************************
=head2 _maps_builds_report_info()

=cut
#**********************************************************
sub _maps_builds2_report_info {
  my $self = shift;

  my $builds = $self->maps_builds2_show({ RETURN_HASH => 1 });

  my $report_table = $html->table({
    width       => '100%',
    caption     => $lang->{PLOT},
    title_plain => [ '#', $lang->{ADDRESS}, $lang->{CREATED}, $lang->{LOCATION} ],
    DATA_TABLE  => 1
  });

  foreach my $build (@{$builds}) {
    my $build_info = $build->{POLYGON};
    my $location_btn = $Auxiliary->maps_show_object_button(LAYER_ID_BY_NAME->{BUILD2}, $build_info->{OBJECT_ID});
    $report_table->addrow($build_info->{ID}, $build_info->{NAME}, $build_info->{CREATED}, $location_btn);
  }

  return $report_table->show();
}

#**********************************************************
=head2 _maps_districts_report_info()

=cut
#**********************************************************
sub _maps_districts_report_info {
  my $self = shift;

  my $districts = $self->maps_districts_show({ RETURN_HASH => 1 });

  my $report_table = $html->table({
    width       => '100%',
    caption     => $lang->{DISTRICTS},
    title_plain => [ '#', $lang->{NAME}, $lang->{CREATED}, $lang->{LOCATION} ],
    DATA_TABLE  => 1
  });

  foreach my $district (@{$districts}) {
    my $district_info = $district->{POLYGON};
    my $location_btn = $Auxiliary->maps_show_object_button(LAYER_ID_BY_NAME->{DISTRICT}, $district_info->{object_id});
    $report_table->addrow($district_info->{id}, $district_info->{name}, $district_info->{created}, $location_btn);
  }

  return $report_table->show();
}

#**********************************************************
=head2 _maps_get_old_builds($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub _maps_get_old_builds {
  my ($attr, $count_object, $export_hash_arr, $object_info, $to_screen) = @_;

  my %ext_params = ();
  if ($attr->{NEW_OBJECT} && !$attr->{OBJECT_ID}) {
    $ext_params{DESC} = 'DESC';
    $ext_params{SORT} = 'b.id';
    $ext_params{PAGE_ROWS} = 1;
  }

  my $builds_list = $Address->build_list({
    DISTRICT_ID        => $attr->{DISTRICT_ID} || '>0',
    DISTRICT_NAME      => '_SHOW',
    NUMBER             => '_SHOW',
    PUBLIC_COMMENTS    => '_SHOW',
    PLANNED_TO_CONNECT => '_SHOW',
    STREET_NAME        => '_SHOW',
    ADDED              => '_SHOW',
    COORDX             => '!',
    COORDY             => '!',
    ZOOM               => '_SHOW',
    COLS_NAME          => 1,
    PG                 => '0',
    PAGE_ROWS          => 999999,
    LOCATION_ID        => $attr->{ID} || $attr->{OBJECT_ID} || $attr->{LOCATION_ID} || '_SHOW',
    %ext_params
  });

  $$count_object += $Address->{TOTAL} if $Address->{TOTAL};

  my $count_array = $Auxiliary->maps_points_count($builds_list, $object_info);

  foreach my $build (@{$builds_list}) {
    last if ($attr->{ONLY_TOTAL});

    next if $attr->{BUILD_IDS} && !in_array($build->{id}, $attr->{BUILD_IDS});

    my $info_hash = {};
    my $point_count = 0;

    $info_hash = $Auxiliary->maps_load_info('Maps', { LOCATION_ID => $build->{id}, TO_SCREEN => $to_screen }) if !$attr->{CLIENT_MAP};
    $point_count = $info_hash->{COUNT} || (($count_array && ref $count_array eq 'ARRAY') ? scalar @{$count_array} : 0);

    next if ($attr->{GROUP_ID} && !$info_hash->{HTML});

    my $color = $info_hash->{COLOR} || $Auxiliary->maps_point_color($point_count, $count_array);
    my $address_full = ($build->{district_name} || '') . ' ,' . ($build->{street_name} || '') . ' ,' . ($build->{number} || '');

    my $info_table = $info_hash->{HTML} || q{};

    # REVERSE COORDS
    my %regex = (
      ID        => $build->{location_id},
      OBJECT_ID => $build->{location_id},
      MARKER    => {
        ID        => $build->{location_id},
        OBJECT_ID => $build->{id},
        NAME      => $address_full,
        COORDX    => $build->{coordy},
        COORDY    => $build->{coordx},
        ADDED     => $build->{added},
        TYPE      => "build_$color",
        INFO      => $info_table,
        COUNT     => $point_count,
        LAYER_ID  => LAYER_ID_BY_NAME->{BUILD},
      },
      ADDRESS   => $address_full,
      LAYER_ID  => @{[ LAYER_ID_BY_NAME->{BUILD} ]}
    );

    push @{$export_hash_arr}, \%regex;
  }

  return 0;
}

#**********************************************************
=head2 _maps_get_new_builds($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub _maps_get_new_builds {
  my ($attr, $count_object, $export_hash_arr, $object_info) = @_;

  my $coords_list = $Maps->points_list({
    COORDX       => '!',
    COORDY       => '!',
    CREATED      => '_SHOW',
    TYPE_ID      => 3,
    LOCATION_ID  => $attr->{LAST_OBJECT_ID} ? "> $attr->{LAST_OBJECT_ID}" : '_SHOW',
    ADDRESS_FULL => '_SHOW',
    ID           => '_SHOW',
  });

  $$count_object += $Maps->{TOTAL} if $Maps->{TOTAL};

  my $count_array = $Auxiliary->maps_points_count($coords_list, $object_info);

  foreach my $build (@{$coords_list}) {

    last if ($attr->{ONLY_TOTAL});
    next if (!$build->{location_id});

    my $info_hash = {};
    my $point_count = 0;

    if (!$attr->{CLIENT_MAP}) {
      $info_hash = $Auxiliary->maps_load_info('Maps', { LOCATION_ID => $build->{location_id} });
      $point_count = $info_hash->{COUNT} || (($count_array && ref $count_array eq 'ARRAY') ? scalar @{$count_array} : 0);
    }

    next if ($attr->{GROUP_ID} && !$info_hash->{HTML});

    my $color = $info_hash->{COLOR} || $Auxiliary->maps_point_color($point_count, $count_array);
    my $address_full = $build->{address_full} || q{};

    my $info_table = $info_hash->{HTML} || q{};

    my %regex = (
      ID        => $build->{location_id},
      OBJECT_ID => $build->{location_id},
      MARKER    => {
        ID        => $build->{location_id},
        OBJECT_ID => $build->{id},
        NAME      => $address_full,
        COORDX    => $build->{coordx},
        COORDY    => $build->{coordy},
        ADDED     => $build->{created},
        TYPE      => "build_$color",
        INFO      => $info_table,
        LAYER_ID  => LAYER_ID_BY_NAME->{BUILD},
        COUNT     => $point_count
      },
      ADDRESS   => $address_full,
      LAYER_ID  => @{[ LAYER_ID_BY_NAME->{BUILD} ]}
    );

    push @{$export_hash_arr}, \%regex;
  }

  return 0;
}

#***************************************************************
=head2 _maps_get_online_users($attr)

=cut
#***************************************************************
sub _maps_get_online_users {
  my $self = shift;
  my ($attr) = @_;

  my %USERS_ONLINE = ();

  return \%USERS_ONLINE if (!in_array('Internet', \@::MODULES));

  require Internet::Sessions;
  Internet::Sessions->import();
  my $Internet = Internet::Sessions->new($db, $admin, $CONF);

  my %search_params = ($attr->{SHORT}) ? () : (CLIENT_IP => '_SHOW', USER_NAME => '_SHOW', DURATION => '_SHOW');

  my $list = $Internet->online({
    %search_params,
    COLS_NAME => 1,
    PAGE_ROWS => 1000000,
  });

  map push(@{$USERS_ONLINE{ $_->{uid} }}, $_), @{$list};

  return \%USERS_ONLINE;
}

#***************************************************************
=head2 _maps_get_users($attr)

  Arguments:
    $attr - hash_ref
      LOCATION_ID     - filter results by LOCATION_ID
      RETURN_AS_ARRAY - return raw DB list

  Returns:
    hash_ref - location_id => [ users_for_thi_location ]

=cut
#***************************************************************
sub _maps_get_users {
  my $self = shift;
  my ($attr) = @_;

  my $users = Users->new($db, $admin, $CONF);
  my $list = $users->list({
    LOGIN         => '_SHOW',
    FIO           => '_SHOW',
    DEPOSIT       => '_SHOW',
    STREET_NAME   => '_SHOW',
    BUILD_NUMBER  => '_SHOW',
    ADDRRESS_FLAT => '_SHOW',
    ACTIVATE      => '_SHOW',
    EXPIRE        => '_SHOW',
    GID           => $attr->{GROUP_ID} || '_SHOW',
    LOCATION_ID   => $attr->{LOCATION_ID} || '!',
    PAGE_ROWS     => '1000000',
    COLS_NAME     => 1,
    COLS_UPPER    => 1,
    SORT          => 'pi.address_flat',
    UID           => undef
  });

  return $list if ($attr->{RETURN_AS_ARRAY});

  my %USERS_INFO = ();
  foreach my $line (@{$list}) {
    next if (!$line->{build_id});
    push @{$USERS_INFO{ $line->{build_id} }}, $line;
  }

  return \%USERS_INFO;
}

#**********************************************************
=head2 _maps_get_layer_objects()

=cut
#**********************************************************
sub _maps_get_layer_objects {
  my $self = shift;
  my ($layer_id, $attr) = @_;

  my @main_object_types = qw/circle polygon polyline/;
  my %have_points = (polygon => 1, polyline => 1);

  my @OBJECTS = ();
  foreach my $object_type (@main_object_types) {
    my $func_name = $object_type . 's_list';

    my $this_type_objects_list = $Maps->$func_name({
      LAYER_ID         => $layer_id,
      NAME             => '_SHOW',
      SHOW_ALL_COLUMNS => 1,
      COLS_UPPER       => 1,
      OBJECT_ID        => $attr->{ID} || '_SHOW',
      PAGE_ROWS        => $attr->{NEW_OBJECT} ? 1 : 10000
    });

    next if (!$this_type_objects_list || ref $this_type_objects_list ne 'ARRAY' || scalar(@{$this_type_objects_list}) <= 0);

    if ($have_points{$object_type}) {
      my $points_func_name = $object_type . '_points_list';
      my $parent_id_name = uc($object_type . '_id');

      foreach my $map_object_row (@{$this_type_objects_list}) {
        my $points_list = $Maps->$points_func_name({
          $parent_id_name => $map_object_row->{id},
          COORDX          => '_SHOW',
          COORDY          => '_SHOW',
          CREATED         => '_SHOW',
          COLS_UPPER      => 0,
          PAGE_ROWS       => 10000
        });

        $map_object_row->{POINTS} = [ map {[ +$_->{coordx}, +$_->{coordy} ]} @{$points_list} ];
        $map_object_row->{CREATED} = $points_list->[0]{created} if $points_list->[0] && $points_list->[0]{created};
      }
    }

    push(@OBJECTS, map {{
      uc($object_type) => $_,
      LAYER_ID         => $layer_id,
      OBJECT_ID        => $_->{object_id}
    }} @{$this_type_objects_list});
  }

  return \@OBJECTS;
}

#**********************************************************
=head2 maps_get_build_objects($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub maps_get_build_objects {
  my $self = shift;
  my ($attr) = @_;

  my $result = '';
  my @objects;

  return \@objects if !$Maps;

  $result = $self->maps_builds_show({
    %{$attr},
    EXPORT      => 1,
    RETURN_HASH => 1,
    TO_SCREEN   => defined $attr->{TO_SCREEN} ? $attr->{TO_SCREEN} : 1
  });
  map(push(@objects, $_), @{$result}) if defined($result) && ref($result) eq 'ARRAY' && scalar(@{$result}) > 0;

  $result = $self->maps_builds2_show({
    %{$attr},
    EXPORT      => 1,
    RETURN_HASH => 1,
    TO_SCREEN   => defined $attr->{TO_SCREEN} ? $attr->{TO_SCREEN} : 1
  });
  map(push(@objects, $_), @{$result}) if defined($result) && ref($result) eq 'ARRAY' && scalar(@{$result}) > 0;

  return \@objects;
}

#**********************************************************
=head2 maps_layers_list() - aggregates layers from DB and external modules

    LAYERS => [ {
      id              => ''
      name            => '',
      lang_name       => '$lang->{}',
      module          => '',
      structure       => 'MARKER',
      clustering      => 0,
      export_function => '',
      filter          => '', # click on layer and show checklist by default
      button_prev_next=> 1, # click on layer and show prev-next button instead of checklist
      sublayers       => [],
      custom_params   => {
        SAVE_AS_GEOMETRY => 1,
      },
    } ]

=cut
#**********************************************************
sub maps_layers_list {
  my $self = shift;
  my ($attr) = @_;

  my $layers = ();
  my $modules_extra_layers = ();
  foreach (@main::MODULES) {
    next if $self->{admin}{MODULES} && !$self->{admin}{MODULES}{$_};

    my $module = $Auxiliary->maps_load_module($_);

    next if !$module;
    next if !$module->can('new') || !$module->can('maps_layers');

    my $module_object = $module->new($db, $admin, $CONF, { LANG => $lang });
    $modules_extra_layers->{$_} = $module_object->maps_layers();
  }

  my $extra_scripts = '';
  foreach my $module_name (keys %{$modules_extra_layers}) {
    next if (!defined $modules_extra_layers->{$module_name});

    my $result = $modules_extra_layers->{$module_name};
    next if !$result->{LAYERS};
    push @{$layers}, @{$result->{LAYERS}};

    next if !$result->{SCRIPTS};
    foreach my $script_name (@{$result->{SCRIPTS}}) {
      $extra_scripts .= "<script src='$script_name'></script>";
    }
  };

  map $_->{lang_name} //= ::_translate($_->{name}), @{$layers};

  return {
    LAYERS        => $layers,
    EXTRA_SCRIPTS => $extra_scripts
  }
}

1;