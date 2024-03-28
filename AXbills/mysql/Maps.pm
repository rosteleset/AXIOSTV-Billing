package Maps;
#*********************** ABillS ***********************************
# Copyright (с) 2003-2023 Andy Gulay (ABillS DevTeam) Ukraine
#
# See COPYRIGHT section in pod text below for usage and distribution rights.
#
#******************************************************************
=head2 NAME

  Maps - Geo information module

=head2 VERSION

   VERSION: 8.01
   UPDATE: 20230110

=cut

use strict;
use parent 'dbcore';
our $VERSION = 8.01;

use AXbills::Base qw/_bp/;
my ($admin, $CONF);


#**********************************************************
=head2 new($db, $admin, \%conf)

=cut
#**********************************************************
sub new {
  my $class = shift;
  my $db = shift;
  ($admin, $CONF) = @_;

  my $self = { };
  bless($self, $class);

  $self->{db} = $db;
  $self->{admin} = $admin;
  $self->{conf} = $CONF;

  return $self;
}

my %unusual_table_names = (
  'maps_texts' => 'maps_text'
);
#**********************************************************
=head2 AUTOLOAD

  Because all namings are standart, 'add', 'change', 'del', 'info' can be generated automatically.
  
=head2 SYNOPSIS

  AUTOLOAD is called when undefined function was called in Package::Foo.
  global $AUTOLOAD var is filled with full name of called undefined function (Package::Foo::some_function)
  
  Because in this module DB tables and columns are named same as template variables, in all logic for custom operations
  the only thing that changes is table name.
  
  We can parse it from called function name and generate 'add', 'change', 'del', 'info' functions on the fly
   
=head2 USAGE

  You should use this function as usual, nothing changes in webinterface logic.
  If your object has unusual logic, just define function you need to customize.
  
  Just call $Maps->wifi_info($wifi_id)
  
  Arguments:
    arguments are typical for operations, assuming we are working with ID column as primary key
    
  Returns:
    returns same result as usual operation functions ( Generally nothing )

=cut
#**********************************************************
sub AUTOLOAD {
  our $AUTOLOAD;
  return if ($AUTOLOAD =~ /::DESTROY$/);

  my ($entity_name, $operation) = $AUTOLOAD =~ /.*::(.*)_(add|del|change|info|full|count)$/;

  return 0 unless ($operation && $entity_name);

  my ($self, $data, $attr) = @_;

  my $table = lc(__PACKAGE__) . '_' . $entity_name;

  if ($self->{debug} && $self->{debug} > 1){
    _bp("$table $operation", { data => $data, attr => $attr});
  }

  # Check for not standart table namings
  if (exists $unusual_table_names{$table}){ $table = $unusual_table_names{$table} };

  if ($operation eq 'add'){
    $data->{INSTALLED} = ( exists $data->{PLANNED} && !$data->{PLANNED}
        && exists $data->{INSTALLED} && !$data->{INSTALLED}
        )
      ? '0000-00-00 00:00:00'
      : undef;

    $data->{CREATED} = (exists $data->{CREATED} && !$data->{CREATED})
      ? '0000-00-00 00:00:00'
      : undef;

    $self->query_add( $table, $data );
    return $self->{errno} ? 0 : $self->{INSERT_ID};
  }
  elsif ($operation eq 'del'){
    # Allow passing ID as $attr
    if ($data && !ref $data) { $data = { ID => $data } };

    return $self->query_del( $table, $data, $attr );
  }
  elsif ($operation eq 'change'){
    return $self->changes( {
        CHANGE_PARAM => 'ID',
        TABLE        =>  $table,
        DATA         => $data,
      } );
  }
  elsif ($operation eq 'info'){
    my $list_func_name = $entity_name . "_list";

    # Allow passing ID as $attr
    if ($data && !ref $data){ $data = { ID => $data } }

    my $list = $self->$list_func_name({
      SHOW_ALL_COLUMNS => 1,
      COLS_UPPER       => 1,
      COLS_NAME        => 1,
      PAGE_ROWS        => 1,
      %{ $data ? $data : { } }
    });
    return $list->[0] || { };
  }
  elsif ($operation eq 'full'){
    my $WHERE = '';
    my @WHERE_BIND = ();
    if ($data->{WHERE}){
      $WHERE = 'WHERE ' . join ( ' AND ', map { push (@WHERE_BIND, $data->{WHERE}{$_}); "$_ = ?" } keys %{$data->{WHERE}} );
    }
    $self->query(qq{
      SELECT * FROM $table $WHERE
    }, undef, { COLS_NAME => 1, Bind => \@WHERE_BIND });

    return [] if $self->{errno};
    return $self->{list} || [];
  }
  elsif ($operation eq 'count'){
    $self->query(qq{
      SELECT COUNT(*) FROM $table GROUP BY id
    });
    return -1 if $self->{errno};
    return $self->{list}[0];
  }
}


#**********************************************************
=head2 build_del($attr)

=cut
#**********************************************************
sub build_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query( "UPDATE builds SET
   coordy = '0', 
   coordx = '0' 
  WHERE coordx = ? AND coordy = ?;",
    'do',
    { Bind => [ $attr->{DCOORDX}, $attr->{DCOORDY} ] }
  );

  $self->query_del( 'maps_wifi_zones', undef, { coordx => $attr->{DCOORDX}, coordy => $attr->{DCOORDY} } );
  $self->query_del( 'maps_wells', undef, { coordx => $attr->{DCOORDX}, coordy => $attr->{DCOORDY} } );
  $self->query_del( 'maps_routes_coords', undef, { coordx => $attr->{DCOORDX}, coordy => $attr->{DCOORDY} } );

  return $self;
}

#**********************************************************
=head2 build_change($attr) - updates build coords

  Arguments:
    $attr -
    
  Returns:
    1 or 0 if no required arguments
    
=cut
#**********************************************************
sub build_change {
  my $self = shift;
  my ($attr) = @_;

  unless ($attr->{ID} && $attr->{COORDX} && $attr->{COORDY}){
    return 0;
  }

  $self->query( "UPDATE builds SET
   coordy = ?,
   coordx = ?
  WHERE id = ?;",
    'do',
    # Swapping coordinates
    { Bind => [ $attr->{COORDY}, $attr->{COORDX}, $attr->{ID} ] }
  );


  return !$self->{errno};
}

#**********************************************************
=head2 routes_list($attr)

=cut
#**********************************************************
sub routes_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  my $WHERE = $self->search_former(
    $attr,
    [
      [ 'ID', 'INT', 'r.id', 1 ],
      [ 'NAME', 'STR', 'r.name', 1 ],
      [ 'TYPE', 'INT', 'r.type', 1 ],
      [ 'TYPE_NAME', 'INT', 'rt.name AS type_name', 1 ],
      [ 'TYPE_COMMENTS', 'STR', 'rt.comments AS type_comments', 1 ],
      [ 'NAS1', 'INT', 'r.nas1', 1 ],
      [ 'NAS2', 'INT', 'r.nas2', 1 ],
      [ 'NAS1_PORT', 'INT', 'r.nas1_port', 1 ],
      [ 'NAS2_PORT', 'INT', 'r.nas2_port', 1 ],
      [ 'LENGTH', 'INT', 'r.length', 1 ],
      [ 'COLOR', 'INT', 'rt.color', 1 ],
      [ 'FIBERS_COUNT', 'INT', 'rt.fibers_count', 1 ],
      [ 'LINE_WIDTH', 'INT', 'rt.line_width', 1 ],
      [ 'PARENT_ID', 'INT', 'r.parent_id', 1 ],
      [ 'GROUP_ID', 'INT', 'r.group_id', 1 ],
      [ 'GROUP_NAME', 'INT', 'rg.name as group_name', 1 ],
      [ 'POINTS', 'INT', 'count(rc.id) AS points', 1 ],
    ],
    { WHERE => 1,

    }
  );

  my $EXT_TABLES = '';
  if ( $attr->{POINTS} ) {
    $EXT_TABLES = 'LEFT JOIN maps_routes_coords rc ON (rc.routes_id=r.id)';
  }

  $self->query( "SELECT  $self->{SEARCH_FIELDS}  r.id
                FROM maps_routes AS r
                LEFT JOIN maps_route_types rt ON (r.type=rt.id)
                LEFT JOIN maps_route_groups rg ON (r.group_id=rg.id)
                $EXT_TABLES
                $WHERE
                GROUP BY r.id
                ORDER BY $SORT $DESC;",
    undef, $attr
  );

  return $self->{list};
}

#**********************************************************
=head2 route_info()

=cut
#**********************************************************
sub route_info {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  $self->query(
    "SELECT *
      FROM maps_routes 
      WHERE id = ?
      ORDER BY $SORT $DESC;",
    undef,
    {
      INFO => 1,
      Bind => [ $attr->{ID} ]
    }
  );

  return $self;
}

#**********************************************************
=head2 routes_add()

=cut
#**********************************************************
sub routes_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add( 'maps_routes', $attr );
  return 0;
}

#**********************************************************
=head2 routes_del()

=cut
#**********************************************************
sub routes_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del( 'maps_routes', $attr );

  return $self->{result};
}

#**********************************************************
=head2 routes_change()

=cut
#**********************************************************
sub routes_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'maps_routes',
      DATA         => $attr,
    }
  );

  return $self;
}

#**********************************************************
=head2 routes_coords_add($attr)

=cut
#**********************************************************
sub routes_coords_add {
  my $self = shift;
  my ($attr) = @_;

  if ( $attr->{POINTS} ) {
    my @MULTI_QUERY = ();

    foreach my $ooords ( split(/;/, $attr->{POINTS}) ) {
      my ($coordx, $coordy) = split(/,/, $ooords);
      push @MULTI_QUERY, [
          $attr->{ROUTE_ID},
          $coordy,
          $coordx
        ];
    }

    $self->query( "INSERT INTO maps_routes_coords (routes_id, coordy, coordx)
        VALUES (?, ?, ?);",
      undef,
      { MULTI_QUERY => \@MULTI_QUERY } );
  }
  else {
    $self->query_add( 'maps_routes_coords', $attr );
  }

  return $self;
}

#**********************************************************
=head2 routes_coords_list($attr)

=cut
#**********************************************************
sub routes_coords_list {
  my $self = shift;
  my ($attr) = @_;

  my @WHERE_RULES = ();
  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  if ( defined($attr->{ID}) ) {
    push @WHERE_RULES, "rc.routes_id='$attr->{ID}'";
  }

  my $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

  $self->query( "SELECT   rc.id,
                rc.routes_id, 
                rc.coordx, 
                rc.coordy 
                FROM maps_routes_coords AS rc
              
                $WHERE
                ORDER BY $SORT $DESC;",
    undef, $attr
  );

  return $self->{list};
}

#**********************************************************
=head2 routes_coords_del($attr)

  Arguments:
    $attr - hash_ref

  Returns:
   1

=cut
#**********************************************************
sub routes_coords_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del( 'maps_routes_coords', $attr );

  return 1;
}



#**********************************************************
=head2 wifi_zones_list($attr)

=cut
#**********************************************************
sub wifi_zones_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PAGE_ROWS = $attr->{PAGE_ROWS} ? "LIMIT $attr->{PAGE_ROWS} " : '';

  my $WHERE = $self->search_former($attr, [ [ 'ID', 'STR', 'id' ] ], { WHERE => 1 });

  $self->query( "SELECT id, radius, coordx, coordy
  FROM maps_wifi_zones
  $WHERE
  ORDER BY $SORT $DESC $PAGE_ROWS;",
    undef,
    $attr
  );

  return $self->{list};
}

#**********************************************************
=head2 point_types_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut
#**********************************************************
sub point_types_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 'id';
  my $DESC = ($attr->{DESC}) ? '' : 'DESC';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $WHERE = '';

  $WHERE = $self->search_former( $attr, [
      [ 'ID',       'INT', 'id',                1 ],
      [ 'NAME',     'STR', 'name',              1 ],
      [ 'ICON',     'STR', 'icon',     'icon'     ],
      [ 'COMMENTS', 'STR', 'comments', 'comments' ],
    ],
    {
      WHERE => 1
    }
  );

  if ( $attr->{SHOW_ALL_COLUMNS} ) {
    $self->{SEARCH_FIELDS} = '*,'
  }

  $self->query(
    "SELECT $self->{SEARCH_FIELDS} id FROM maps_point_types $WHERE ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;", undef,
  { COLS_NAME => 1, %{$attr ? $attr : {} } } );

  return $self->{list};
}

#**********************************************************
=head2 points_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut
#**********************************************************
sub points_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 'id';
  my $DESC = ($attr->{DESC}) ? 'DESC' : '';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 2500;

  my $WHERE = '';
  my $EXT_TABLES = '';

  my $address_query = '""';
  my $address_name_query = '""';
  my $address_join_tables = "
      LEFT JOIN builds b               ON (b.id=mp.location_id)
      LEFT JOIN streets s              ON (s.id=b.street_id)
      LEFT JOIN districts d            ON (d.id=s.district_id)
        ";

  if ($attr->{NAME_ADDRESS}){
    my $address_query_1 = qq{ IF(mp.location_id, CONCAT(d.name, ', ', s.name, ', ',  b.number), '') };
    $address_name_query = qq{ CONCAT(mp.name, ' ( ', $address_query_1, ' )') AS name };
    $EXT_TABLES .= $address_join_tables;
  }

  if ($attr->{ADDRESS_FULL}){
    $address_query = qq{ IF(mp.location_id, CONCAT(d.name, ', ', s.name, ', ',  b.number), '') AS address_full };
    $EXT_TABLES .= $address_join_tables;
  };

  my $search_columns = [
    [ 'ID',             'INT',          'mp.id'               , 1 ],
    # Alias
    [ 'OBJECT_ID',      'INT',          'mp.id'               , 1 ],
    [ 'NAME',           'STR',          'mp.name'             , 1 ],
    [ 'TYPE',           'STR',          'mt.name AS type'     , 1 ],
    [ 'PLANNED',        'DATE',         'mp.planned'          , 1 ],
    [ 'CREATED',        'DATE',         'mp.created'          , 1 ],
    [ 'COORDX',         'INT',          'mc.coordx'           , 1 ],
    [ 'COMMENTS',       'STR',          'mp.comments'         , 1 ],
    [ 'TYPE_ID',        'INT',          'mt.id as type_id'    , 1 ],
    [ 'ICON',           'STR',          'mt.icon'             , 1 ],
    [ 'COORDY',         'INT',          'mc.coordy'           , 1 ],
    [ 'LOCATION_ID',    'INT',          'mp.location_id'      , 1 ],
    [ 'ADDRESS_FULL',   'STR',          $address_query        , 1 ],
    [ 'NAME_ADDRESS',   'STR',          $address_name_query   , 1 ],
    [ 'PARENT_ID',      'INT',          'mp.parent_id'        , 1 ],
    [ 'EXTERNAL',       'INT',          'mp.external'         , 1 ],
  ];

  if ($attr->{SHOW_ALL_COLUMNS}){
    map { $attr->{$_->[0]} = '_SHOW' unless exists $attr->{$_->[0]} } @$search_columns;
  }

  $WHERE = $self->search_former( $attr, $search_columns,
    {
      WHERE => 1
    }
  );

  $self->query( " SELECT $self->{SEARCH_FIELDS} mp.id
  FROM maps_points mp
  LEFT JOIN maps_point_types mt    ON (mp.type_id=mt.id)
  LEFT JOIN maps_coords mc         ON (mp.coord_id=mc.id)
  $EXT_TABLES
  $WHERE
   ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS", undef, { COLS_NAME => 1, %{$attr ? $attr : {}} }, );

  return $self->{list};
}

#**********************************************************
=head2 points_info($id)

  Arguments:
    $id - id for custom_point

  Returns:
    hash_ref

=cut
#**********************************************************
sub points_info {
  my ($self, $id, $attr) = @_;

  my $list = $self->points_list( { ID => $id, SHOW_ALL_COLUMNS => 1, COLS_UPPER => 1, %{$attr ? $attr : {} } } );

  return $list->[0] || {};
}

#**********************************************************
=head2 points_add($attr)

  Arguments:
    $attr -

  Returns:


=cut
#**********************************************************
sub points_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add( 'maps_coords', {
      COORDX => $attr->{COORDX},
      COORDY => $attr->{COORDY}
    } );


  my $coord_id = $self->{INSERT_ID};

  if (!$attr->{CREATED} && !$attr->{PLANNED}){
    $attr->{CREATED} = 'NOW()';
  }

  $self->query_add( 'maps_points',
    {
      %{$attr},
      COORD_ID => $coord_id
    }
  );

  return $self->{errno} ? 0 : $self->{INSERT_ID};
}

#**********************************************************
=head2 points_change($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    1

=cut
#**********************************************************
sub points_change {
  my $self = shift;
  my ($attr) = @_;

  if ( $attr->{COORDX} && $attr->{COORDY} && $attr->{ID} ) {
    # Coordinates are located in another table, so need change it there
    my $current_object = $self->query( "SELECT coord_id FROM maps_points WHERE id=?", undef,
      { Bind => [ $attr->{ID} ], COLS_NAME => 1 });

    return 0 if ($self->{errno});

    $current_object = $current_object->{list}[0];
    if ( defined $current_object->{coord_id} ) {
      $self->changes({
        CHANGE_PARAM => 'ID',
        TABLE        => 'maps_coords',
        DATA         => {
          %{$attr},
          ID => $current_object->{coord_id},
        },
      });
    }
    # Can appear if added through form
    else {
      $self->query_add('maps_coords', {
        COORDX => $attr->{COORDX},
        COORDY => $attr->{COORDY}
      });
      $attr->{COORD_ID} = $self->{INSERT_ID};
    }
  }

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'maps_points',
    DATA         => $attr,
  });

  return 1;
}

#**********************************************************
=head2 points_max_ids_for_types() - returns total for each type

  Returns:
    hash_ref - { type_id => count }
    
=cut
#**********************************************************
sub points_max_ids_for_types {
  my ($self, $type_id) = shift;

  my $WHERE = '';
  my @BIND_VALUES = ();
  if ( $type_id ) {
    $WHERE = q{ WHERE type_id = ? };
    $BIND_VALUES[0] = $type_id;
  }

  $self->query("SELECT type_id, COUNT(id) AS max_id FROM maps_points GROUP BY type_id $WHERE;", undef,
    {
      COLS_NAME => 1,
      Bind      => \@BIND_VALUES
    });

  return { } if ($self->{errno});

  my %id_max_hash_ref = ();
  map { $id_max_hash_ref{$_->{type_id}} = $_->{max_id} } @{ $self->{list} };

  return \%id_max_hash_ref;
}

#**********************************************************
=head2 route_types_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut
#**********************************************************
sub route_types_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 'id';
  my $DESC = ($attr->{DESC}) ? '' : 'DESC';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $search_columns = [
    [ 'ID', 'INT', 'id', 1 ],
    [ 'NAME', 'STR', 'name', 1 ],
    [ 'COLOR', 'STR', 'color', 1 ],
    [ 'FIBERS_COUNT', 'INT', 'fibers_count', 1 ],
    [ 'COMMENTS', 'STR', 'comments', 1 ],
  ];

  if ( $attr->{SHOW_ALL_COLUMNS} ) {
    map { $attr->{$_->[0]} = '_SHOW' unless (exists $attr->{$_->[0]}) } @{$search_columns};
  }

  my $WHERE = $self->search_former( $attr, $search_columns,
    {
      WHERE => 1
    }
  );

  $self->query(
    "SELECT $self->{SEARCH_FIELDS} id FROM maps_route_types $WHERE ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;", undef,
    {
      COLS_NAME  => 1,
      COLS_UPPER => 1,
      %{ $attr ? $attr : { }} }
  );

  return [ ] if ($self->{errno});

  return $self->{list};
}

#**********************************************************
=head2 route_groups_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut
#**********************************************************
sub route_groups_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 'id';
  my $DESC = ($attr->{DESC}) ? '' : 'DESC';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $search_columns = [
    [ 'ID', 'INT', 'rg.id', 1 ],
    [ 'NAME', 'STR', 'rg.name', 1 ],
    [ 'COMMENTS', 'STR', 'rg.comments', 1 ],
    [ 'PARENT_ID', 'INT', 'rg.parent_id', 1 ],
    [ 'PARENT_NAME', 'STR', 'rgp.name AS parent_name' ,1]
  ];

  if ( $attr->{SHOW_ALL_COLUMNS} ) {
    map { $attr->{$_->[0]} = '_SHOW' unless (exists $attr->{$_->[0]}) } @{$search_columns};
  }

  my $WHERE = $self->search_former( $attr, $search_columns, { WHERE => 1 } );

  $self->query(
    "SELECT $self->{SEARCH_FIELDS} rg.id
     FROM maps_route_groups rg
     LEFT JOIN maps_route_groups rgp ON (rg.parent_id = rgp.id)
      $WHERE ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;", undef,
    {
      COLS_NAME  => 1,
      COLS_UPPER => 1,
      %{ $attr ? $attr : { }} }
  );

  return [ ] if ($self->{errno});

  return $self->{list};
}

#**********************************************************
=head2 layers_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut
#**********************************************************
sub layers_list{
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 'id';
  my $DESC = ($attr->{DESC}) ? '' : 'DESC';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;


  my $search_columns = [
    ['ID',             'INT',        'id'                           ,1 ],
    ['NAME',           'STR',        'name'                         ,1 ],
    ['STRUCTURE',      'STR',        'structure'                    ,1 ],
    # ['COMMENTS',       'STR',        'comments'                     ,1 ],
    ['MODULE',         'STR',        'module'                       ,1 ],
    ['MARKERS_IN_CLUSTER',     'INT',        'markers_in_cluster'                   ,1 ],
  ];

  if ($attr->{SHOW_ALL_COLUMNS}){
    map { $attr->{$_->[0]} = '_SHOW' unless exists $attr->{$_->[0]} } @$search_columns;
  }

  my $WHERE =  $self->search_former($attr, $search_columns,
    {
      WHERE => 1
    }
  );

  $self->query( "SELECT $self->{SEARCH_FIELDS} id FROM maps_layers $WHERE ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;", undef, {
    COLS_NAME => 1,
    COLS_UPPER => 1,
    %{ $attr ? $attr : {}}}
  );

  return [] if $self->{errno};


  return $self->{list};
}

#**********************************************************
=head2 circles_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut
#**********************************************************
sub circles_list{
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 'id';
  my $DESC = ($attr->{DESC}) ? '' : 'DESC';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;


  my $search_columns = [
    ['ID',             'INT',         'id'                           ,1 ],
    ['NAME',           'STR',        'name'                          ,1 ],
    ['LAYER_ID',          'STR',           'layer_id'                ,1 ],
    ['COORDX',         'INT',         'coordx'   ,1 ],
    ['COORDY',         'INT',         'coordy'   ,1 ],
    ['RADIUS',          'INT',           'radius'                    ,1 ],
    ['COMMENTS',          'STR',           'comments'                ,1 ],
  ];

  if ($attr->{SHOW_ALL_COLUMNS}){
    map { $attr->{$_->[0]} = '_SHOW' unless exists $attr->{$_->[0]} } @$search_columns;
  }

  my $WHERE =  $self->search_former($attr, $search_columns,
    {
      WHERE => 1
    }
  );

  $self->query( "SELECT $self->{SEARCH_FIELDS} id FROM maps_circles $WHERE ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;", undef, {
    COLS_NAME => 1,
    COLS_UPPER => 1,
    %{ $attr ? $attr : {}}}
  );

  return [] if $self->{errno};


  return $self->{list};
}

#**********************************************************
=head2 polylines_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut
#**********************************************************
sub polylines_list{
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 'id';
  my $DESC = ($attr->{DESC}) ? '' : 'DESC';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;


  my $search_columns = [
    ['ID',             'INT',        'id'            ,1 ],
    ['NAME',           'STR',        'name'          ,1 ],
    ['COMMENTS',       'STR',        'comments'      ,1 ],
    ['LAYER_ID',       'INT',        'layer_id'      ,1 ],
    ['OBJECT_ID',      'INT',        'object_id'     ,1 ],
  ];

  if ($attr->{SHOW_ALL_COLUMNS}){
    map { $attr->{$_->[0]} = '_SHOW' unless exists $attr->{$_->[0]} } @$search_columns;
  }

  my $WHERE =  $self->search_former($attr, $search_columns,
    {
      WHERE => 1
    }
  );

  $self->query( "SELECT $self->{SEARCH_FIELDS} id FROM maps_polylines $WHERE ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;", undef, {
    COLS_NAME => 1,
    COLS_UPPER => 1,
    %{ $attr ? $attr : {}}}
  );

  return [] if $self->{errno};


  return $self->{list};
}

#**********************************************************
=head2 polyline_points_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut
#**********************************************************
sub polyline_points_list{
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 'id';
  my $DESC = ($attr->{DESC}) ? '' : 'DESC';

  my $search_columns = [
    ['ID',             'INT',        'id'            ,1 ],
    ['POLYLINE_ID',    'INT',        'polyline_id'   ,1 ],
  ];

  if ($attr->{REVERSE}){
    push(@$search_columns,
      ['COORDX',         'INT',        'coordy AS coordx'       ,1 ],
      ['COORDY',         'INT',        'coordx AS coordy'       ,1 ],
    );
  }
  else {
    push(@$search_columns,
      ['COORDX',         'INT',        'coordx'                 ,1 ],
      ['COORDY',         'INT',        'coordy'                 ,1 ],
    );
  }

  if ($attr->{SHOW_ALL_COLUMNS}){
    map { $attr->{$_->[0]} = '_SHOW' unless exists $attr->{$_->[0]} } @$search_columns;
  }

  my $WHERE =  $self->search_former($attr, $search_columns,
    {
      WHERE => 1
    }
  );

  $self->query( "SELECT $self->{SEARCH_FIELDS} id FROM maps_polyline_points $WHERE ORDER BY $SORT $DESC;", undef, {
    COLS_NAME => 1,
    COLS_UPPER => 1,
    %{ $attr ? $attr : {}}}
  );

  return $self->{list} || [];
}

#**********************************************************
=head2 polyline_points_add($attr) - adds all points in multiquery

  Arguments:
    $attr -
      POINTS      - array of points separated by ','
      POLYLINE_ID - ID of parent polyline
      
  Returns:
    1
    
=cut
#**********************************************************
sub polyline_points_add {
  my $self = shift;
  my ($attr) = @_;

  if ( $attr->{POINTS} ) {
    # Fill multi query
    my @MULTI_QUERY = ();

    if ( $attr->{REVERSE} ) {
      push (@MULTI_QUERY,
        map {[ $attr->{POLYLINE_ID}, $_->{COORDY}, $_->{COORDX} ]} @{ $attr->{POINTS} }
      );
    }
    else {
      push (@MULTI_QUERY,
        map {[ $attr->{POLYLINE_ID}, $_->{COORDX}, $_->{COORDY} ]} @{ $attr->{POINTS} }
      );
    }

    $self->query("DELETE FROM maps_polyline_points WHERE polyline_id = ?", 'do', {
      Bind => [ $attr->{POLYLINE_ID} ]
    });

    $self->query("INSERT INTO maps_polyline_points (polyline_id, coordx, coordy) VALUES (?, ?, ?);",
      undef, { MULTI_QUERY => \@MULTI_QUERY });

  }
  else {
    $self->query_add('maps_polyline_points', $attr);
  }

  return 1;
}

#**********************************************************
=head2 polygons_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut
#**********************************************************
sub polygons_list{
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 'id';
  my $DESC = ($attr->{DESC}) ? '' : 'DESC';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $search_columns = [
    ['ID',             'INT',    'id'             ,1 ],
    ['NAME',           'STR',    'name'           ,1 ],
    ['COMMENTS',       'STR',    'comments'       ,1 ],
    ['LAYER_ID',       'INT',    'layer_id'       ,1 ],
    ['OBJECT_ID',      'INT',    'object_id'      ,1 ],
    ['COLOR',          'STR',    'color'          ,1 ],
  ];

  if ($attr->{SHOW_ALL_COLUMNS}){
    map { $attr->{$_->[0]} = '_SHOW' unless exists $attr->{$_->[0]} } @$search_columns;
  }

  my $WHERE =  $self->search_former($attr, $search_columns, { WHERE => 1 });

  $self->query( "SELECT $self->{SEARCH_FIELDS} id FROM maps_polygons $WHERE ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;", undef, {
    COLS_NAME => 1,
    COLS_UPPER => 1,
    %{ $attr ? $attr : {}}}
  );

  return $self->{list} || [];
}

#**********************************************************
=head2 polygon_points_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut
#**********************************************************
sub polygon_points_list{
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 'id';
  my $DESC = ($attr->{DESC}) ? '' : 'DESC';

  my $search_columns = [
    ['ID',             'INT',        'id'            ,1 ],
    ['POLYGON_ID',     'INT',        'polygon_id'    ,1 ],
    ['COORDX',         'INT',        'coordx'        ,1 ],
    ['COORDY',         'INT',        'coordy'        ,1 ],
  ];

  if ($attr->{SHOW_ALL_COLUMNS}){
    map { $attr->{$_->[0]} = '_SHOW' unless exists $attr->{$_->[0]} } @$search_columns;
  }

  my $WHERE =  $self->search_former($attr, $search_columns, {WHERE => 1});

  $self->query( "SELECT $self->{SEARCH_FIELDS} id FROM maps_polygon_points $WHERE ORDER BY $SORT $DESC;", undef, {
    COLS_NAME => 1,
    COLS_UPPER => 1,
    %{ $attr ? $attr : {}}}
  );

  return [] if $self->{errno};


  return $self->{list};
}

#**********************************************************
=head2 polygon_points_add($attr) - adds all points in multiquery

  Arguments:
    $attr -
      POINTS      - array of points separated by ','
      POLYGON_ID - ID of parent polygon

  Returns:
    1

=cut
#**********************************************************
sub polygon_points_add {
  my $self = shift;
  my ($attr) = @_;

  if ( $attr->{POINTS} ) {
    # Fill multi query
    my @MULTI_QUERY = ();

    if ( $attr->{REVERSE} ) {
      push (@MULTI_QUERY,
        map {[ $attr->{POLYGON_ID}, $_->{COORDY}, $_->{COORDX} ]} @{ $attr->{POINTS} }
      );
    }
    else {
      push (@MULTI_QUERY,
        map {[ $attr->{POLYGON_ID}, $_->{COORDX}, $_->{COORDY} ]} @{ $attr->{POINTS} }
      );
    }

    $self->query("DELETE FROM maps_polygon_points WHERE polygon_id = ?", 'do', {
      Bind => [ $attr->{POLYGON_ID} ]
    });

    $self->query("INSERT INTO maps_polygon_points (polygon_id, coordx, coordy) VALUES (?, ?, ?);",
      undef, { MULTI_QUERY => \@MULTI_QUERY });

  }
  else {
    $self->query_add('maps_polygon_points', $attr);
  }

  return 1;
}

#**********************************************************
=head2 texts_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut
#**********************************************************
sub texts_list{
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 'id';
  my $DESC = ($attr->{DESC}) ? '' : 'DESC';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $search_columns = [
    ['ID',             'INT',        'id'              ,1 ],
    ['TEXT',           'STR',        'text'            ,1 ],
    ['LAYER_ID',       'INT',        'layer_id'        ,1 ],
    ['OBJECT_ID',      'INT',        'object_id'       ,1 ],
    ['COORDX',         'INT',        'coordx'          ,1 ],
    ['COORDY',         'INT',        'coordy'          ,1 ],
  ];

  if ($attr->{SHOW_ALL_COLUMNS}){
    map { $attr->{$_->[0]} = '_SHOW' unless exists $attr->{$_->[0]} } @$search_columns;
  }

  my $WHERE =  $self->search_former($attr, $search_columns, { WHERE => 1 } );

  $self->query( "SELECT $self->{SEARCH_FIELDS} id FROM maps_text $WHERE ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;", undef, {
    COLS_NAME => 1,
    COLS_UPPER => 1,
    %{ $attr ? $attr : {}}}
  );

  return [] if $self->{errno};


  return $self->{list};
}

#**********************************************************
=head2 icons_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut
#**********************************************************
sub icons_list{
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 'id';
  my $DESC = ($attr->{DESC}) ? '' : 'DESC';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;


  my $search_columns = [
    ['ID',             'INT',         'id'       ,1 ],
    ['NAME',           'STR',         'name'     ,1 ],
    ['COMMENTS',       'STR',         'comments' ,1 ],
    ['FILENAME',       'STR',         'filename' ,1 ],

  ];

  if ($attr->{SHOW_ALL_COLUMNS}){
    map { $attr->{$_->[0]} = '_SHOW' unless exists $attr->{$_->[0]} } @$search_columns;
  }

  my $WHERE =  $self->search_former($attr, $search_columns,{ WHERE => 1 });

  $self->query( "SELECT $self->{SEARCH_FIELDS} id FROM maps_icons $WHERE ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;", undef, {
    COLS_NAME => 1,
    COLS_UPPER => 1,
    %{ $attr ? $attr : {}}}
  );

  return [] if $self->{errno};

  return $self->{list};
}

#**********************************************************
=head2 districts_list($attr) -

  Arguments:
    $attr -
    
  Returns:
    list
    
=cut
#**********************************************************
sub districts_list {
  my ($self, $attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 'id';
  my $DESC = ($attr->{DESC}) ? '' : 'DESC';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;


  my $search_columns = [
    ['DISTRICT_ID', 'INT', 'md.district_id'     ,1 ],
    ['DISTRICT',    'STR', 'd.name as district' ,1 ],
    ['OBJECT_ID',   'INT', 'md.object_id'       ,1 ]
  ];

  if ($attr->{SHOW_ALL_COLUMNS}){
    map { $attr->{$_->[0]} = '_SHOW' unless exists $attr->{$_->[0]} } @$search_columns;
  }

  my $WHERE =  $self->search_former($attr, $search_columns, { WHERE => 1 });

  $self->query( "SELECT $self->{SEARCH_FIELDS} md.district_id
   FROM maps_districts md
   LEFT JOIN districts d ON (md.district_id=d.id)
   $WHERE ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;", undef, {
   COLS_NAME => 1,
   COLS_UPPER => 0,
   %{ $attr ? $attr : {}}}
  );

  return [] if $self->{errno};

  return $self->{list};
}

#**********************************************************
=head2 _distance_between($point1, $point2)

=cut
#**********************************************************
sub _distance_between{
  return sqrt(($_[0]->{COORDX} - $_[1]->{COORDX})**2 + ($_[0]->{COORDY} - $_[1]->{COORDY})**2);
}

#**********************************************************
=head2 _point_is_beetween($point1, $point_2, $point_3)

  Checks if point_3 lies beetween point_1 and point_2
  
=cut
#**********************************************************
sub _point_is_beetween {
  my $distance = (_distance_between($_[0], $_[2]) + _distance_between($_[1], $_[2])) - _distance_between($_[0], $_[1]);
  return $distance <= 1E-8;
}

#**********************************************************
=head2 break_polyline($object_id, $coords) - breaks_polyline in two parts

  Arguments:
    $object_id,
    $coords
    
  Returns:
     array_ref - (object_id1, object_id_2);
    
=cut
#**********************************************************
sub break_polyline {
  my $self = shift;
  my ($polyline_id, $coords) = @_;

  # In transaction, add two new cables and delete old one
  my DBI $db = $self->{db}->{db};
  $db->{AutoCommit} = 0;
  $self->{db}->{TRANSACTION} = 1;

  # Rollback transaction and return error string
  my $exit_with_error = sub {
    $db->rollback();
    $db->{AutoCommit} = 1;
    return $_[0];
  };

  my $new_point = $coords;

  # Get polylines by custom_points ids
  my $old_polyline = $self->polylines_info($polyline_id);

  # Get points for polyline
  my $points_list = $self->polyline_points_list({
    POLYLINE_ID => $old_polyline->{id},
    COORDX      => '_SHOW',
    COORDY      => '_SHOW',
  });

  ## Calculate points that are siblings to given coords
  my $points_count = scalar(@{$points_list});
  # Find index of siblings
  my $center = - 1;
  for ( my $i = 1; $i < $points_count; $i++ ) {
    if ( _point_is_beetween($points_list->[$i - 1], $points_list->[$i], $new_point ) ) {
      $center = $i;
      last;
    }
  }
  return $exit_with_error->('Cant find siblings for point') if ($center == - 1);

  my @points = @{$points_list};

  # Divide in two arrays
  my @points_before = @points[0 .. ($center - 1)];
  my @points_after = @points[$center .. $#points];

  ## Append new coords to each array
  # As last for first line
  push @points_before, $new_point;
  # As first for second line
  unshift @points_after, $new_point;

  ## Add new objects for polylines
  # Retrieve info for object
  my $old_object = $self->points_info($old_polyline->{OBJECT_ID});
  return $exit_with_error->('Cant find points for old polyline') if ($self->{errno});

  $self->points_del($old_polyline->{OBJECT_ID});
  return $exit_with_error->('Cant delete object fo old polyline') if ($self->{errno});

  delete $old_object->{ID};
  delete $old_object->{COORD_ID};

  my $add_polyline_with_points = sub {
    # Add same info points
    my $point_id = $self->points_add($old_object);
    return $exit_with_error->('Cant add object for new polyline') if ($self->{errno});

    # Add new polylines with new object
    my $new_id = $self->polylines_add({ OBJECT_ID => $point_id, LAYER_ID => $old_polyline->{LAYER_ID}});
    return $exit_with_error->('Cant add polyline for new polyline') if ($self->{errno});

    # Add points for this polylines
    $self->polyline_points_add({ POLYLINE_ID => $new_id, POINTS => $_[0]});
    return $exit_with_error->('Cant add points for new polyline') if ($self->{errno});

    $point_id;
  };

  my $point_id_1 = $add_polyline_with_points->(\@points_before);
  my $point_id_2 = $add_polyline_with_points->(\@points_after);

  # Delete old polyline
  $self->polylines_del($old_polyline->{ID});
  return $exit_with_error->('Cant delete old polyline') if ($self->{errno});

  $self->polyline_points_del({POLYLINE_ID => $old_polyline->{ID}});
  return $exit_with_error->('Cant delete old polyline points') if ($self->{errno});

  $db->{AutoCommit} = 1;
#  $db->commit();

  return [ $point_id_1, $point_id_2 ];
}


#**********************************************************
=head2 _mercator_to_meters($x1, $y1, $x2, $y2) - converts Mercator projection distance to meters

  http://www.avislab.com/blog/gps-distance/

=cut
#**********************************************************
sub _mercator_to_meters{
  use Math::Trig;
  my $EarthRadius = 6378137;
  my ($long1, $lat1, $long2, $lat2) = @_;

  my $dlong = deg2rad($long2 - $long1);
  my $dlat = deg2rad($lat2 - $lat1);

  my $sin_dlat = (sin($dlat/2.00))**2.00 + cos(deg2rad($lat1)) * cos(deg2rad($lat2)) * (sin($dlong/2.00))**2.00;
  my $c = 2.00 * atan2(sqrt($sin_dlat), sqrt(1.00 - $sin_dlat));

  return $EarthRadius * $c;
}

#**********************************************************
=head2 align_polyline_to_coords($object_id, $coords) - move end of polyline to $coords

  Arguments:
    $object_id,
    $coords
    
  Returns:
     nothing
=cut
#**********************************************************
sub align_polyline_to_coords {
  my ($self, $object_id, $coords) = @_;

  # REVERSING POINT coords
  my $new_point = {COORDX => $coords->{COORDY}, COORDY => $coords->{COORDX}};

  # Get polylines by custom_points ids
  my $polyline = $self->polylines_info({ OBJECT_ID => $object_id });

  # Get points for polyline
  my $points_list = $self->polyline_points_list({
    POLYLINE_ID => $polyline->{id},
    REVERSE     => 1,
    COORDX      => '_SHOW',
    COORDY      => '_SHOW',
  });

  my @points = @{$points_list};
  my $new_point_id = 0;

  if (_distance_between($points[0], $new_point) > _distance_between($points[$#points], $new_point)) {
    $new_point_id = $points[$#points]->{id};
  }
  else {
    $new_point_id = $points[0]->{id};
  }

  $self->polyline_points_change($new_point_id, $new_point);
}

#**********************************************************
=head2 decode_points($points) - adapter for legacy type

  Arguments:
    $points - one of
      'x,y;x,y;x,y'
      [ [x, y], [x, y], [x, y] ]
      [ {COORDX => x, COORDY => y}, {COORDX => x, COORDY => y}, {COORDX => x, COORDY => y} ]
    
  Returns:
    [ {COORDX => x, COORDY => y}, {COORDX => x, COORDY => y}, {COORDX => x, COORDY => y} ]
    
=cut
#**********************************************************
sub decode_points {
  my ($self, $points_input) =  @_;

  my @points = ();
  # Can be stored in legacy way

  if ( !ref $points_input ) {
    @points = map {
      my ($coordx, $coordy) = split(/,/, $_);
      { COORDX => $coordx, COORDY => $coordy }
    } split(/;/, $points_input);
  }
  elsif ( ref $points_input eq 'ARRAY' ) {
    @points = @{ $points_input };

    # Points can be stored as [[ x, y ], [ x, y ]]
    if ($points[0] && ref $points[0] eq 'ARRAY'){
      @points = map { { COORDX => $_->[0], COORDY => $_->[1] } } @points;
    }

  }

  return \@points;
}

#**********************************************************
=head2 build2_list_with_points

=cut
#**********************************************************
sub build2_list_with_points {
  my $self = shift;
  my ($attr) = @_;

  my $PAGE_ROWS = $attr->{PAGE_ROWS} ? "LIMIT $attr->{PAGE_ROWS}" : '';
  my $WHERE = $self->search_former($attr,
    [
      [ 'LOCATION_ID',   'INT', 'b.id as location_id',                                              1 ],
      [ 'NUMBER',        'STR', 'b.number',                                                         1 ],
      [ 'FULL_ADDRESS',  'STR', "CONCAT(d.name, ', ' ,s.name, ', ', b.number) AS address_full",     1 ],
      [ 'OBJECT_ID',     'INT', 'mp.id as object_id',                                               1 ],
      [ 'COORDX_CENTER', 'STR', 'SUM(plpoints.coordx)/COUNT(plpoints.polygon_id) AS coordx_center', 1 ],
      [ 'COORDY_CENTER', 'STR', 'SUM(plpoints.coordy)/COUNT(plpoints.polygon_id) AS coordy_center', 1 ],
      [ 'COORDS', 'STR', "GROUP_CONCAT(DISTINCT CONCAT(plpoints.coordx, '|' " .
        ",plpoints.coordy) ORDER BY plpoints.id DESC) AS coords", 1 ],
    ],
    { WHERE => 1, }
  );

  $self->query("SET SESSION group_concat_max_len = 1000000;", 'do');
  $self->query("SELECT $self->{SEARCH_FIELDS} b.id
    FROM builds b
    LEFT JOIN streets s ON (s.id=b.street_id)
    LEFT JOIN districts d ON (d.id=s.district_id)
    LEFT JOIN maps_points mp FORCE INDEX FOR JOIN (`location_id`) ON (b.id=mp.location_id)
    LEFT JOIN maps_point_types mt ON (mp.type_id=mt.id)
    LEFT JOIN maps_coords mc ON (mp.coord_id=mc.id)
    LEFT JOIN maps_polygons mgone ON (mgone.object_id=mp.id)
    LEFT JOIN maps_polygon_points plpoints ON(mgone.id=plpoints.polygon_id)
    $WHERE
    GROUP BY mgone.id, b.id
    HAVING coords <> ''
    ORDER BY mp.id DESC $PAGE_ROWS;",
    undef, $attr
  );

  return $self->{list};
}

#**********************************************************
=head2 build_list_without_coords($attr)

=cut
#**********************************************************
sub build_list_without_coords {
  my $self = shift;
  my ($attr) = @_;
  
  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  my $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $WHERE = $self->search_former($attr,
    [
      [ 'LOCATION_ID',        'INT', 'b.id as location_id',                                          1 ],
      [ 'NUMBER',             'STR', 'b.number',                                                     1 ],
      [ 'FULL_ADDRESS',       'STR', "CONCAT(d.name, ', ' ,s.name, ', ', b.number) AS address_full", 1 ],
      [ 'OBJECT_ID',          'INT', 'mp.id as object_id',                                           1 ],
      [ 'STREET_ID',          'INT', 'b.street_id',                                                  1 ],
      [ 'STREET_NAME',        'STR', 's.name as street_name',                                        1 ],
      [ 'STREET_SECOND_NAME', 'STR', 's.second_name as street_second_name',                          1 ],
      [ 'DISTRICT_ID',        'INT', 's.district_id',                                                1 ],
      [ 'DISTRICT_NAME',      'STR', 'd.name as district_name',                                      1 ],
    ],
    { WHERE => 1 }
  );

  $WHERE .= $WHERE ? ' AND ' : 'WHERE ';
  $WHERE .= 'b.coordx = 0 AND b.coordy = 0 AND mp.location_id IS NULL OR mp.location_id = 0';

  $self->query("SELECT $self->{SEARCH_FIELDS} b.id
    FROM builds b
    LEFT JOIN streets s ON (s.id=b.street_id)
    LEFT JOIN districts d ON (d.id=s.district_id)
    LEFT JOIN maps_points mp FORCE INDEX FOR JOIN (`location_id`) ON (b.id=mp.location_id)
    LEFT JOIN maps_point_types mt ON (mp.type_id=mt.id)
    LEFT JOIN maps_coords mc ON (mp.coord_id=mc.id)
    LEFT JOIN maps_polygons mgone ON (mgone.object_id=mp.id)
    LEFT JOIN maps_polygon_points plpoints ON(mgone.id=plpoints.polygon_id)
    $WHERE
    GROUP BY mgone.id, b.id
    ORDER BY b.id DESC;", undef, { COLS_NAME => 1, %{$attr} });

  return $self->{list};
}

#**********************************************************
=head2 users_monitoring_list

=cut
#**********************************************************
sub users_monitoring_list {
  my $self = shift;
  my ($attr) = @_;

  $self->query("SET SESSION group_concat_max_len = 1000000;", 'do');
  $self->query("SELECT SUM(plpoints.coordx)/COUNT(plpoints.polygon_id) AS coordx_center,
      bd.coordx as coordx, bd.id AS build_id
    FROM internet_online io
    LEFT JOIN users u ON (io.uid=u.uid)
    LEFT JOIN bills b ON (u.bill_id = b.id)
    LEFT JOIN users_pi pi FORCE INDEX FOR JOIN (`PRIMARY`) ON (u.uid=pi.uid)
    LEFT JOIN builds bd ON (bd.id=pi.location_id)
    LEFT JOIN streets s ON (s.id=bd .street_id)
    LEFT JOIN districts d ON (d.id=s.district_id)
    LEFT JOIN maps_points mp FORCE INDEX FOR JOIN (`location_id`) ON (bd.id=mp.location_id)
    LEFT JOIN maps_point_types mt ON (mp.type_id=mt.id)
    LEFT JOIN maps_coords mc ON (mp.coord_id=mc.id)
    LEFT JOIN maps_polygons mgone ON (mgone.object_id=mp.id)
    LEFT JOIN maps_polygon_points plpoints ON(mgone.id=plpoints.polygon_id)
    GROUP BY bd.id
    HAVING coordx_center <> '' OR coordx <> '';",
    undef, $attr
  );

  return $self->{list};
}

sub DESTROY{};

=head1 COPYRIGHT

  Copyright (с) 2003-2023 Andy Gulay (ABillS DevTeam) Ukraine
  All rights reserved.
  https://axbills.net.ua/

=cut

1;
