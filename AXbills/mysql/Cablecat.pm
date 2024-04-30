package Cablecat;
#*********************** ABillS ***********************************
# Copyright (с) 2003-2023 Andy Gulay (ABillS DevTeam) Ukraine
#
# See COPYRIGHT section in pod text below for usage and distribution rights.
#
#******************************************************************
=head1 NAME

Cablecat - module for cables accounting and management

=head2 VERSION

  VERSION: 7.95
  UPDATE: 20230214

=cut

use strict;
use warnings 'FATAL' => 'all';
use parent 'dbcore';
our $VERSION = 7.95;

use AXbills::Base qw/_bp in_array/;
use Equipment;
use Internet;

my %unusual_table_names = (
  'cablecat_connecters' => 'cablecat_wells'
);

my $instance = undef;
#**********************************************************
=head2 new($db, $admin, $CONF)

  Arguments:
    $db    - ref to DB
    $admin - current Web session admin
    $CONF  - ref to %conf

  Returns:
    object

=cut
#**********************************************************
sub new {
  unless (defined $instance) {
    my $class = shift;

    my ($db, $admin, $CONF) = @_;

    my $self = {
      db    => $db,
      admin => $admin,
      conf  => $CONF,
    };

    bless( $self, $class );
    $instance = $self;
  }

  return $instance;
}

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
  Just call $Cablecat->cable_types_info($cable_type_id)

  Arguments:
    arguments are typical for operations, assuming we are working with ID column as primary key

  Returns:
    returns same result as usual operation functions ( Generally nothing )

=cut
#**********************************************************
sub AUTOLOAD {
  our $AUTOLOAD;
  my ($entity_name, $operation) = $AUTOLOAD =~ /.*::(.*)_(add|del|change|info|full|count|next)$/;

  return if ( $AUTOLOAD =~ /::DESTROY$/ );

  die "Undefined function $AUTOLOAD. ()" unless ( $operation && $entity_name );

  my ($self, $data, $attr) = @_;

  my $table = lc(__PACKAGE__) . '_' . $entity_name;

  # Check for not standart table namings
  if ( exists $unusual_table_names{$table} ) {$table = $unusual_table_names{$table}};

  if ( $self->{debug} ) {
    _bp($table, { data => $data, attr => $attr });
  }

  if ( $operation eq 'add' ) {
    $data->{INSTALLED} ||= '0000-00-00 00:00:00';
    $data->{CREATED} = (exists $data->{CREATED} && !$data->{CREATED}) ? '0000-00-00 00:00:00' : undef;

    $self->query_add($table, $data);
    return $self->{errno} ? 0 : $self->{INSERT_ID};
  }
  elsif ( $operation eq 'del' ) {
    return $self->query_del($table, $data, $attr);
  }
  elsif ( $operation eq 'change' ) {
    return $self->changes({
      CHANGE_PARAM => $data->{_CHANGE_PARAM} || 'ID',
      %{ ($data->{SECOND_PARAM}) ? { SECOND_PARAM => $data->{SECOND_PARAM} } : {} },
      TABLE        => $table,
      DATA         => $data,
    });
  }
  elsif ( $operation eq 'info' ) {
    my $list_func_name = $entity_name . "_list";

    if ( $data && ref $data ne 'HASH' ) {
      $attr->{ID} = $data
    }

    my $list = $self->$list_func_name({
      SHOW_ALL_COLUMNS => 1,
      COLS_UPPER       => 1,
      COLS_NAME        => 1,
      PAGE_ROWS        => 1,
      %{ $attr ? $attr : {} }
    });

    return $list->[0] || {};
  }
  elsif ( $operation eq 'full' ) {
    my $WHERE = '';
    my @WHERE_BIND = ();
    if ( $data->{WHERE} ) {
      $WHERE = 'WHERE ' . join (' AND ', map {push (@WHERE_BIND, $data->{WHERE}->{$_});
        "$_ = ?"} keys %{$data->{WHERE}});
    }
    $self->query(qq{
      SELECT * FROM cablecat_$entity_name $WHERE
    }, undef, { COLS_NAME => 1, Bind => \@WHERE_BIND });

    return [] if ( $self->{errno} );

    return $self->{list} || [];
  }
  elsif ( $operation eq 'count' || $operation eq 'next' ) {
    my $WHERE = '';
    my $type_id = $data->{TYPE_ID};

    # After connecters was moved to wells, should change logic
    if ( $entity_name eq 'connecters' ) {
      $entity_name = 'wells';
      $type_id = 2;
    }

    if ( $type_id ) {
      $WHERE = qq{WHERE type_id=$type_id};
    }

    my $requested = ($operation eq 'count')
      ? 'COUNT(*)'
      : 'MAX(id) + 1';

    $self->query(qq{
      SELECT $requested FROM cablecat_$entity_name $WHERE
    });
    return - 1 if ( $self->{errno} );

    return $self->{list}->[0]->[0] || 0;
  }
}


#**********************************************************
=head2 _get_join_sql($alias, $join_table, $join_alias, $table_field, $join_field)

  Arguments:

    $alias        - table 1 alias
    $join_table   - table 2 full name
    $join_alias   - table 2 alias
    $table_field  - table 1 field to join on
    $join_field   - table 2 field to join on
    $attr         - hash_ref
      CHECK_SEARCH_FIELDS - boolean, will check if join is needed

  Returns:
    string - part of SQL query for join
    if $attr->{CHECK_SEARCH_FIELDS} is specified, and no join needed, will return '';

=cut
#**********************************************************
sub _get_join_sql($$$$$;$) {
  my $self = shift;
  my ( $alias, $join_table, $join_alias, $table_field, $join_field, $attr) = @_;

  $attr //= {};

  if ($attr->{CHECK_SEARCH_FIELDS} && $self->{SEARCH_FIELDS} && $self->{SEARCH_FIELDS} !~ /$join_alias\./){
    return '';
  }

  return qq{\nLEFT JOIN $join_table $join_alias ON ($alias.$table_field = $join_alias.$join_field)};

}

#**********************************************************
=head2 _join_filter() - checks if need to join

  Arguments:
     $table_alias - alias to check in SEARCH_FIELDS
     $code_for_jo

  Returns:
    SQL code to make join

=cut
#**********************************************************
sub  _join_filter{
  my ($self, $table_alias, $join_code) = @_;

  if ( $self->{SEARCH_FIELDS} =~ /$table_alias\./ ) {
    return $join_code;
  }

  return '';
}

#**********************************************************
=head2 _cablecat_list($attr)

  Abstracts code for list

  Arguments :
    $attr - list attr
      SEARCH_COLUMNS - search_columns

  Returns :
    $list

  Side effects:
    writes TOTAL to $self

=cut
#**********************************************************
sub _cablecat_list{
  my ($self, $entity, $attr) = @_;

  my $SORT = $attr->{SORT} || '1';
  my $DESC = ($attr->{DESC}) ? '' : 'DESC';
  my $PG = $attr->{PG} || '0';
  my $PAGE_ROWS = $attr->{PAGE_ROWS} || 1000;
  my $GROUP_BY = $attr->{GROUP_BY} ? "GROUP BY $attr->{GROUP_BY}" : '';

  if (!$attr->{PAGE_ROWS} && exists $self->{conf}{CABLECAT_LIST_SIZE} && $self->{conf}{CABLECAT_LIST_SIZE}){
    $PAGE_ROWS = $self->{conf}{CABLECAT_LIST_SIZE};
  }

  my @search_columns = @{ $attr->{SEARCH_COLUMNS} ? $attr->{SEARCH_COLUMNS} : [] };

  if ( $attr->{SHOW_ALL_COLUMNS} ) {
    map { $attr->{$_->[0]} = '_SHOW' unless (exists $attr->{$_->[0]}) } @search_columns;
  }
  elsif (!exists($attr->{ID}) && $search_columns[0] && $search_columns[0][0] eq 'ID') {
    $attr->{ID} = '_SHOW';
  }

  my $WHERE = $self->search_former( $attr, \@search_columns,  { WHERE => 1, WHERE_RULES => $attr->{WHERE_RULES} } );

  # Removing last comma symbol
  $self->{SEARCH_FIELDS} =~ s/, $//;

  # Calls back
  my $FROM = '';
  # Allows to apply new JOIN regarding to search fields
  if (defined $attr->{SEARCH_FIELDS_FILTER}){
    my $attr2 = $attr->{SEARCH_FIELDS_FILTER}->();
    $FROM       = "FROM $attr2->{FROM}" if exists $attr2->{FROM};
  }
  else {
    $FROM = 'FROM cablecat_' . $entity;
  }

  # Get list
  $self->query("SELECT $self->{SEARCH_FIELDS}
    $FROM
    $WHERE
    $GROUP_BY
    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;", undef, {
    COLS_NAME => 1,
    %{$attr // {}}
  });

  my $list = $self->{list};

  if ($attr->{_SKIP_TOTAL}){
    return $list || [];
  }

  if (!$self->{errno} && $self->{TOTAL}) {
    # Get total
    $self->query("SELECT COUNT(*) $FROM $WHERE");
    my $total = $self->{list}->[0]->[0];
    $self->{TOTAL} = $total;
  }

  return $list || [];
}

#**********************************************************
=head2 cables_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut
#**********************************************************
sub cables_list {
  my ($self, $attr) = @_;

  $attr->{SEARCH_COLUMNS} = [
    [ 'ID',                  'INT'          ,'cc.id'                             ,1 ],
    [ 'NAME',                'STR'          ,'cc.name'                           ,1 ],
    [ 'CABLE_TYPE',          'STR'          ,'cct.name'                          ,'cct.name AS cable_type' ],
    [ 'COMMENTS',            'STR'          ,'mp.comments'                       ,1 ],
    [ 'CREATED',             'DATE'         ,'mp.created'                        ,1 ],
    [ 'WELL_1',              'STR'          ,'cw1.name'                          ,'cw1.name AS well_1' ],
    [ 'WELL_2',              'STR'          ,'cw2.name'                          ,'cw2.name AS well_2' ],
    [ 'FIBERS_COUNT',        'INT'          ,'cct.fibers_count'                  ,1 ],
    [ 'MODULES_COUNT',       'INT'          ,'cct.modules_count'                 ,1 ],
    [ 'LENGTH',              'INT'          ,'cc.length'                         ,1 ],
    [ 'RESERVE',             'INT'          ,'cc.reserve'                        ,1 ],
    [ 'POLYLINE_ID',         'INT'          ,'mline.id AS polyline_id'           ,1 ],
    [ 'POINT_ID',            'INT'          ,'cc.point_id'                       ,1 ],
    [ 'WELL_1_ID',           'INT'          ,'cc.well_1'                         ,'cc.well_1 AS well_1_id' ],
    [ 'WELL_2_ID',           'INT'          ,'cc.well_2'                         ,'cc.well_2 AS well_2_id' ],
    [ 'TYPE_ID',             'STR'          ,'cc.type_id'                       , 1 ],
    [ 'MODULES_COLORS_NAME', 'STR'          ,'ccs_m.name AS modules_colors_name', 1 ],
    [ 'MODULES_COLORS',      'STR'          ,'ccs_m.colors AS modules_colors'   , 1 ],
    [ 'FIBERS_COLORS_NAME',  'STR'          ,'ccs_f.name AS fibers_colors_name' , 1 ],
    [ 'FIBERS_COLORS',       'STR'          ,'ccs_f.colors AS fibers_colors'    , 1 ],
    [ 'OUTER_COLOR',         'STR'          ,'cct.outer_color'                  , 1 ],
    [ 'LENGTH_CALCULATED',   'INT'          ,'mline.length AS length_calculated', 1 ],
    [ 'LINE_WIDTH',          'INT'          ,'cct.line_width'                   , 1 ],
    [ 'CAN_BE_SPLITTED',     'INT',         'cct.can_be_splitted'               , 1 ],
    [ 'WELL_1_POINT_ID',     'INT'          ,'cw1.point_id AS well_1_point_id'      ],
    [ 'WELL_2_POINT_ID',     'INT'          ,'cw2.point_id AS well_2_point_id'      ],
    [ 'DISTRICT_ID',         'INT'          ,'d.id'                             ,'d.id AS district_id' ],
    [ 'STREET_ID',           'INT'          ,'s.id'                             ,'s.id AS street_id '  ],
    [ 'LOCATION_ID',         'INT'          ,'b.id'                             ,'b.id AS builds_id'   ],

  ];

  $attr->{SEARCH_FIELDS_FILTER} = sub {
    my $EXT_TABLES = '';

    if ( $self->{SEARCH_FIELDS} =~ /(?:cw1|cw2)\./ ) {
      $EXT_TABLES .= qq{
        LEFT JOIN cablecat_wells cw1 ON (cc.well_1=cw1.id)
        LEFT JOIN cablecat_wells cw2 ON (cc.well_2=cw2.id)
      }
    }
    if ( $self->{SEARCH_FIELDS} =~ /(?:mline|mp)\./ ) {
      $EXT_TABLES .= qq{
        LEFT JOIN maps_points mp ON (cc.point_id=mp.id)
        LEFT JOIN maps_polylines mline ON (mline.object_id=mp.id)
      }
    }
    if ( $self->{SEARCH_FIELDS} =~ /cct\./ ) {
      $EXT_TABLES .= "\n LEFT JOIN cablecat_cable_types cct ON (cc.type_id=cct.id)";

      # Joining color schemes needs params from cablecat_cable_types
      if ( $self->{SEARCH_FIELDS} =~ /ccs_m\./ ) {
        $EXT_TABLES .= "\n LEFT JOIN cablecat_color_schemes ccs_m ON (ccs_m.id=cct.modules_color_scheme_id)";
      }
      if ( $self->{SEARCH_FIELDS} =~ /ccs_f\./ ) {
        $EXT_TABLES .= "\n LEFT JOIN cablecat_color_schemes ccs_f ON (ccs_f.id=cct.color_scheme_id)"
      }
    }
    if ($self->{SEARCH_FIELDS} =~ / (?:d|s|b)\./){

      # Join maps points if hasn't joined yet
      if ($EXT_TABLES !~ 'LEFT JOIN maps_points mp'){
        $EXT_TABLES .= "\n LEFT JOIN maps_points mp ON (cc.point_id=mp.id)";
      }

      $EXT_TABLES .= qq{
        LEFT JOIN builds    b ON (b.id=mp.location_id)
        LEFT JOIN streets   s ON (s.id=b.street_id)
        LEFT JOIN districts d ON (d.id=s.district_id)
      };
    }

    {
      FROM => "cablecat_cables cc $EXT_TABLES"
    }
  };

  return $self->_cablecat_list('cables', $attr);
}

#**********************************************************
=head2 cable_types_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut
#**********************************************************
sub cable_types_list {
  my ($self, $attr) = @_;

  $attr->{SEARCH_COLUMNS} = [
    [ 'ID',                      'INT', 'cct.id',                       1 ],
    [ 'NAME',                    'STR', 'cct.name',                     1 ],
    [ 'COLOR_SCHEME',            'STR', 'ccs.name AS color_scheme',     1 ],
    [ 'COMMENTS',                'STR', 'cct.comments',                 1 ],
    [ 'FIBERS_COUNT',            'INT', 'cct.fibers_count',             1 ],
    [ 'MODULES_COUNT',           'INT', 'cct.modules_count',            1 ],
    [ 'COLOR_SCHEME_ID',         'INT', 'cct.color_scheme_id ',         1 ],
    [ 'MODULES_COLOR_SCHEME_ID', 'INT', 'cct.modules_color_scheme_id ', 1 ],
    [ 'OUTER_COLOR',             'STR', 'cct.outer_color',              1 ],
    [ 'LINE_WIDTH',              'INT', 'cct.line_width',               1 ],
    [ 'CAN_BE_SPLITTED',         'INT', 'cct.can_be_splitted',          1 ],
  ];

  $attr->{SEARCH_FIELDS_FILTER} = sub {
    my $EXT_TABLES = $self->_get_join_sql('cct', 'cablecat_color_schemes', 'ccs', 'color_scheme_id', 'id', {CHECK_SEARCH_FIELDS => 1});
    {
      FROM => "cablecat_cable_types cct $EXT_TABLES"
    }
  };

  return $self->_cablecat_list('cable_types cct', $attr);
}

#**********************************************************
=head2 color_schemes_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut
#**********************************************************
sub color_schemes_list {
  my ($self, $attr) = @_;

  $attr->{SEARCH_COLUMNS} = [
    [ 'ID',     'INT', 'id',     1 ],
    [ 'NAME',   'STR', 'name',   1 ],
    [ 'COLORS', 'STR', "colors", 1 ],
  ];

  return $self->_cablecat_list('color_schemes', $attr);
}

#**********************************************************
=head2 splitter_types_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut
#**********************************************************
sub splitter_types_list{
  my ($self, $attr) = @_;

  $attr->{SEARCH_COLUMNS} = [
    ['ID',             'INT',      'id'                       ,1 ],
    ['NAME',           'STR',      'name'                     ,1 ],
    ['FIBERS_IN',      'INT',      "fibers_in"                ,1 ],
    ['FIBERS_OUT',     'INT',      "fibers_out"               ,1 ],
  ];

  return $self->_cablecat_list('splitter_types', $attr);
}

#**********************************************************
=head2 connecter_types_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut
#**********************************************************
sub connecter_types_list{
  my ($self, $attr) = @_;

  $attr->{SEARCH_COLUMNS} = [
    ['ID',             'INT',        'id'                           ,1 ],
    ['NAME',           'STR',        'name'                         ,1 ],
    ['CARTRIDGES',     'INT',        'cartridges'                   ,1 ],
  ];

  return $self->_cablecat_list('connecter_types', $attr);
}


#**********************************************************
=head2 wells_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut
#**********************************************************
sub wells_list {
  my ($self, $attr) = @_;

  $attr->{SEARCH_COLUMNS} = [
    [ 'ID',         'INT',      'cw.id',                 1 ],
    [ 'NAME',       'STR',      'cw.name',               1 ],
    [ 'TYPE',       'STR',      'cwt.name AS type',      1 ],
    [ 'ICON',       'STR',      'cwt.icon',              1 ],
    [ 'POINT_ID',   'INT',      'cw.point_id',           1 ],
    [ 'TYPE_ID',    'INT',      'cw.type_id',            1 ],
    [ 'PARENT_ID',  'INT',      'cw.parent_id',          1 ],
    [ 'COMMENTS',   'STR',      'mp.comments',           1 ],
    [ 'PICTURE',    'STR',      'cw.picture',            1 ],
  ];

  $attr->{SEARCH_FIELDS_FILTER} = sub {
    my $EXT_TABLES = '';

    $EXT_TABLES .= $self->_get_join_sql('cw', 'cablecat_well_types', 'cwt', 'type_id', 'id', { CHECK_SEARCH_FIELDS => 1 });
    $EXT_TABLES .= $self->_get_join_sql('cw', 'maps_points', 'mp', 'point_id', 'id', { CHECK_SEARCH_FIELDS => 1 });

    {
      FROM => "cablecat_wells cw $EXT_TABLES"
    }
  };

  return $self->_cablecat_list('wells', $attr);
}

#**********************************************************
=head2 coil_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut
#**********************************************************
sub coil_list {
  my ($self, $attr) = @_;

  $attr->{SEARCH_COLUMNS} = [
    [ 'ID',         'INT',      'id',                 1 ],
    [ 'NAME',       'STR',      'name',               1 ],
    [ 'POINT_ID',   'INT',      'point_id',           1 ],
    [ 'CABLE_ID',   'INT',      'cable_id',           1 ],
    [ 'LENGTH',     'INT',      'length',             1 ],
  ];

  return $self->_cablecat_list('coil', $attr);
}

#**********************************************************
=head2 well_types_list($attr) - types for wells

  Arguments:
    $attr -

  Returns:


=cut
#**********************************************************
sub well_types_list {
  my ($self, $attr) = @_;

  $attr->{SEARCH_COLUMNS} = [
    [ 'ID',       'INT', 'id',       1 ],
    [ 'NAME',     'STR', 'name',     1 ],
    [ 'ICON',     'STR', 'icon',     1 ],
    [ 'COMMENTS', 'STR', 'comments', 1 ],
  ];

  return $self->_cablecat_list('well_types', $attr);
}

#**********************************************************
=head2 connecters_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut
#**********************************************************
sub connecters_list{
  my ($self, $attr) = @_;

  my $SORT = $attr->{SORT} || 'id';
  my $DESC = ($attr->{DESC}) ? '' : 'DESC';
  my $PG = $attr->{PG} || '0';
  my $PAGE_ROWS = $attr->{PAGE_ROWS} || 25;


  my $search_columns = [
    [ 'ID',             'INT',        'cw.id'                           ,1 ],
    [ 'NAME',           'STR',        'cw.name'                         ,1 ],
    [ 'TYPE',           'STR',        'cct.name AS connecter_type'      ,1 ],
    [ 'WELL_ID',        'INT',        'cw.parent_id'                    ,'cw.parent_id AS well_id' ],
    [ 'TYPE_ID',        'INT',        'cw.connecter_type_id'            ,1 ],
    [ 'POINT_ID',       'INT',        'cw.point_id'                     ,1 ],
  ];

  if ($attr->{SHOW_ALL_COLUMNS}){
    map { $attr->{$_->[0]} = '_SHOW' unless exists $attr->{$_->[0]} } @$search_columns;
  }

  my $WHERE = $self->search_former( $attr, $search_columns);
  $WHERE = 'AND ' . $WHERE if ($WHERE);

  my $EXT_TABLES = '';
  if ($self->{SEARCH_FIELDS} =~ /cct\./){
    $EXT_TABLES .= "LEFT JOIN cablecat_connecter_types cct ON (cw.connecter_type_id=cct.id)";
  }

  $self->query( "SELECT $self->{SEARCH_FIELDS} cw.id
   FROM cablecat_wells cw
    $EXT_TABLES
   WHERE type_id=2 $WHERE ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;", undef, {
    COLS_NAME => 1,
    %{ $attr ? $attr : {} }}
  );

  if ($self->{errno}){
    $self->{TOTAL} = -1;
    return [ ]
  };

  my $list = $self->{list} || [];
  $self->{TOTAL} = $self->connecters_count();
  return $list;
}

#**********************************************************
=head2 wells_coords($well_id) - coords for well

  Arguments:
    $well_id

  Returns:
    hash_ref
     COORDX
     COORDY

=cut
#**********************************************************
sub wells_coords {
  my $self = shift;
  my ($well_id) = @_;

  $self->query( "SELECT mc.coordx, mc.coordy
  FROM cablecat_wells cw
  LEFT JOIN maps_points mp ON (cw.point_id=mp.id)
  LEFT JOIN maps_coords mc ON (mp.coord_id=mc.id)
  WHERE cw.id= ?
  LIMIT 1;", undef, {
    COLS_NAME  => 1,
    COLS_UPPER => 1,
    Bind       => [ $well_id ]
  }
  );

  return ($self->{errno}) ? {} : $self->{list}[0];
}

#**********************************************************
=head2 splitters_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut
#**********************************************************
sub splitters_list{
  my ($self, $attr) = @_;

  $attr->{SEARCH_COLUMNS} = [
    [ 'ID',                    'INT',      'cs.id'                             ,1 ],
    [ 'TYPE',                  'STR',      'cst.name AS type'                  ,1 ],
    [ 'WELL',                  'INT',      'cw.name AS well'                   ,1 ],
    [ 'POINT_ID',              'INT',      'cs.point_id'                       ,1 ],
    [ 'CREATED',               'DATE',     'mp.created'                        ,1 ],
    [ 'PLANNED',               'INT',      'mp.planned'                        ,1 ],
    [ 'INSTALLED',             'INT',      'mp.installed'                      ,1 ],
    [ 'FIBERS_IN',             'STR',      'cst.fibers_in'                     ,1 ],
    [ 'FIBERS_OUT',            'STR',      'cst.fibers_out'                    ,1 ],
    [ 'WELL_ID',               'INT',      'cs.well_id'                        ,1 ],
    [ 'TYPE_ID',               'INT',      'cs.type_id'                        ,1 ],
    [ 'COMMUTATION_ID',        'INT',      'cs.commutation_id'                 ,1 ],
    [ 'COMMUTATION_X',         'INT',      'cs.commutation_x'                  ,1 ],
    [ 'COMMUTATION_Y',         'INT',      'cs.commutation_y'                  ,1 ],
    [ 'COMMUTATION_ROTATION',  'INT',      'cs.commutation_rotation'           ,1 ],
    [ 'FIBERS_COLORS_NAME',    'STR',      'ccs_f.name AS fibers_colors_name'  ,1 ],
    [ 'FIBERS_COLORS',         'STR',      'ccs_f.colors AS fibers_colors'     ,1 ],
    [ 'COLOR_ID',              'STR',      'cs.color_scheme_id'                ,1 ],
    [ 'ATTENUATION',           'STR',      'cs.attenuation'                    ,1 ],
    [ 'NAME',                  'STR',      'cs.name'                           ,1 ],
  ];

  $attr->{SEARCH_FIELDS_FILTER} = sub {
    my $EXT_TABLES = '';

    $EXT_TABLES .= $self->_get_join_sql(
      'cs', 'cablecat_splitter_types', 'cst', 'type_id', 'id',
      { CHECK_SEARCH_FIELDS => 1 }
    );

    $EXT_TABLES .= $self->_get_join_sql(
      'cs', 'cablecat_wells', 'cw', 'well_id', 'id',
      { CHECK_SEARCH_FIELDS => 1 }
    );

    $EXT_TABLES .= $self->_get_join_sql(
      'cs', 'maps_points', 'mp', 'point_id', 'id',
      { CHECK_SEARCH_FIELDS => 1 }
    );

    $EXT_TABLES .= $self->_get_join_sql(
      'cs', 'cablecat_color_schemes', 'ccs_f', 'color_scheme_id', 'id',
      { CHECK_SEARCH_FIELDS => 1 }
    );

    {
      FROM => "cablecat_splitters cs $EXT_TABLES"
    }
  };

  return $self->_cablecat_list('splitters', $attr);
}


sub commutation_onu_list {
  my ($self, $attr) = @_;

  $attr->{SEARCH_COLUMNS} = [
    [ 'ID',                   'INT',        'co.id'                          ,1 ],
    [ 'UID',                  'INT',        'co.uid'                         ,1 ],
    [ 'SERVICE_ID',           'INT',        'co.service_id'                  ,1 ],
    [ 'COMMUTATION_ID',       'INT',        'co.commutation_id'              ,1 ],
    [ 'COMMUTATION_X',        'INT',        'co.commutation_x'               ,1 ],
    [ 'COMMUTATION_Y',        'INT',        'co.commutation_y'               ,1 ],
    [ 'COMMUTATION_ROTATION', 'INT',        'co.commutation_rotation'        ,1 ],
    [ 'WELLS_ID',             'INT',       'cc.connecter_id'        ,'cc.connecter_id as wells_id' ],
    [ 'PARENT_ID',            'INT',       'pcw.id'      ,'pcw.id as parent_id' ],
  ];

  $attr->{SEARCH_FIELDS_FILTER} = sub {
    my $EXT_TABLES = '';

    $EXT_TABLES .= $self->_get_join_sql(
      'co', 'cablecat_commutations', 'cc', 'commutation_id', 'id',
      { CHECK_SEARCH_FIELDS => 0 }
    );

    $EXT_TABLES .= $self->_get_join_sql(
      'cc', 'cablecat_wells', 'cw', 'connecter_id', 'id',
      { CHECK_SEARCH_FIELDS => 1 }
    );

    $EXT_TABLES .= $self->_get_join_sql(
      'cw', 'cablecat_wells', 'pcw', 'parent_id', 'id',
      { CHECK_SEARCH_FIELDS => 1 }
    );

    {
      FROM => "cablecat_commutation_onu co $EXT_TABLES"
    }
  };

  return $self->_cablecat_list('commutation_onu', $attr);

}

#**********************************************************
=head2 crosses_list($attr) -

=cut
#**********************************************************
sub crosses_list {
  my ($self, $attr) = @_;

  $attr->{SEARCH_COLUMNS} = [
    [ 'ID',                 'INT',      'ccr.id'                           ,1 ],
    [ 'NAME',               'STR',      'ccr.name'                         ,1 ],
    [ 'TYPE',               'STR',      'ccrt.name AS type'                ,1 ],
    [ 'WELL',               'INT',      'cw.name as well'                  ,1 ],
    [ 'POINT_ID',           'INT',      'cw.point_id'                      ,1 ],
    [ 'TYPE_ID',            'INT',      'ccr.type_id'                      ,1 ],
    [ 'WELL_ID',            'INT',      'ccr.well_id'                      ,1 ],
    [ 'CROSS_TYPE_ID',      'INT',      'ccrt.cross_type_id'               ,1 ],
    [ 'PANEL_TYPE_ID',      'INT',      'ccrt.panel_type_id'               ,1 ],
    [ 'RACK_HEIGHT',        'INT',      'ccrt.rack_height'                 ,1 ],
    [ 'PORTS_COUNT',        'INT',      'ccrt.ports_count'                 ,1 ],
    [ 'PORTS_TYPE_ID',      'INT',      'ccrt.ports_type_id'               ,1 ],
    [ 'POLISH_TYPE_ID',     'INT',      'ccrt.polish_type_id'              ,1 ],
    [ 'FIBER_TYPE_ID',      'INT',      'ccrt.fiber_type_id'               ,1 ],
    [ 'FIBER_TYPE_ID',      'INT',      'ccrt.fiber_type_id'               ,1 ],
    [ 'FIBERS_COLORS_NAME', 'STR',      'ccs_f.name AS fibers_colors_name' ,1 ],
    [ 'FIBERS_COLORS',      'STR',      'ccs_f.colors AS fibers_colors'    ,1 ],
    [ 'COLOR_ID',           'STR',      'ccr.color_scheme_id'              ,1 ],
  ];

  $attr->{SEARCH_FIELDS_FILTER} = sub {
    my $EXT_TABLES = '';
    $EXT_TABLES .= $self->_join_filter('ccrt', 'LEFT JOIN cablecat_cross_types ccrt ON (ccr.type_id=ccrt.id)');
    $EXT_TABLES .= $self->_join_filter('cw', 'LEFT JOIN cablecat_wells cw ON (ccr.well_id=cw.id)');
    $EXT_TABLES .= $self->_join_filter('ccs_f', 'LEFT JOIN cablecat_color_schemes ccs_f ON (ccr.color_scheme_id=ccs_f.id)');

    {
      FROM => "cablecat_crosses ccr $EXT_TABLES"
    }
  };

  return $self->_cablecat_list('crosses', $attr);

}

#**********************************************************
=head2 links_list($attr) - information what and where is linked

  Arguments:
    $attr -



  Returns:
    list

=cut
#**********************************************************
sub links_list {
  my ($self, $attr) = @_;

  $attr->{SEARCH_COLUMNS} = [
    ['ID',             'INT',        'cl.id'               ,1 ],
    ['COMMUTATION_ID', 'INT',        'cl.commutation_id'   ,1 ],
    ['ELEMENT_1_ID',   'INT',        'cl.element_1_id'     ,1 ],
    ['ELEMENT_2_ID',   'INT',        'cl.element_2_id'     ,1 ],
    ['ELEMENT_1_TYPE', 'INT',        'cl.element_1_type'   ,1 ],
    ['ELEMENT_1_TYPE', 'INT',        'cl.element_2_type'   ,1 ],
    ['FIBER_NUM_1',    'INT',        'cl.fiber_num_1'      ,1 ],
    ['FIBER_NUM_2',    'INT',        'cl.fiber_num_2'      ,1 ],
    #    ['ELEMENT_1_SIDE', 'INT',        'element_1_side'   ,1 ],
    #    ['ELEMENT_2_SIDE', 'INT',        'element_2_side'   ,1 ],
    ['ATTENUATION',    'INT',        'cl.attenuation'      ,1 ],
    ['DIRECTION',      'INT',        'cl.direction'        ,1 ],
    ['COMMENTS',       'STR',        'cl.comments'         ,1 ],
    ['GEOMETRY',       'STR',        'cl.geometry'         ,1 ],
  ];

  $attr->{SEARCH_FIELDS_FILTER} = sub {{ FROM => "cablecat_links cl" }};

  if ($attr->{FOR_ELEMENT_AND_FIBER} && ref $attr->{FOR_ELEMENT_AND_FIBER} eq 'HASH')  {
    # Hash slice
    my ($el_type, $el_id, $fiber_num) = (@{$attr->{FOR_ELEMENT_AND_FIBER}}{qw/ELEMENT_TYPE ELEMENT_ID FIBER_NUM/});

    $attr->{WHERE_RULES} = [
      "((cl.element_1_type='$el_type' AND cl.element_1_id=$el_id" . ($fiber_num ? " AND cl.fiber_num_1=$fiber_num)" : '')
        . "  OR
        (cl.element_2_type='$el_type' AND cl.element_2_id=$el_id" . ($fiber_num ? " AND cl.fiber_num_2=$fiber_num))" : ')')
        . " AND cw.id IS NOT NULL"
    ];

    $attr->{SEARCH_FIELDS_FILTER} = sub {
      my $EXT_TABLES = '';

      $EXT_TABLES .= $self->_get_join_sql('cl', 'cablecat_commutations', 'cc', 'commutation_id', 'id' );
      $EXT_TABLES .= $self->_get_join_sql('cc', 'cablecat_wells', 'cw', 'connecter_id', 'id' );

      {
        FROM => "cablecat_links cl $EXT_TABLES"
      }
    };
  }

  return $self->_cablecat_list('links', $attr);
}

#**********************************************************
=head2 links_for_element_list($element_type, $element_id)

  Arguments:
    $element_type - string (CABLE, SPLITTER, CLIENT, CROSS, EQUIPMENT)
    $element_id   - int

  Returns:
    list

=cut
#**********************************************************
sub links_for_element_list {
  my ($self, $element_type, $element_id, $attr) = @_;

  my $search_columns = [
    ['ID',             'INT',        'cl.id'               ,1 ],
    ['COMMUTATION_ID', 'INT',        'cl.commutation_id'   ,1 ],
    ['FIBER_NUM_1',    'INT',        'cl.fiber_num_1'      ,1 ],
    ['FIBER_NUM_2',    'INT',        'cl.fiber_num_2'      ,1 ],
    ['ELEMENT_1_SIDE', 'INT',        'cl.element_1_side'   ,1 ],
    ['ELEMENT_2_SIDE', 'INT',        'cl.element_2_side'   ,1 ],
    ['ATTENUATION',    'INT',        'cl.attenuation'      ,1 ],
    ['COMMENTS',       'STR',        'cl.comments'         ,1 ],
    ['DIRECTION',      'INT',        'cl.direction'        ,1 ],
    ['GEOMETRY',       'STR',        'cl.geometry'         ,1 ],
  ];
  if ($attr->{SHOW_ALL_COLUMNS}){
    map { $attr->{$_->[0]} = '_SHOW' unless exists $attr->{$_->[0]} } @$search_columns;
  }
  my $WHERE = $self->search_former($attr // {}, $search_columns);

  $self->query("SELECT
  ? AS element_1_type,
  ? AS element_1_id,
  IF( (cl.element_1_type=? AND cl.element_1_id=?), cl.fiber_num_1,    cl.fiber_num_2  )  AS fiber_num_1,

  IF( (cl.element_1_type=? AND cl.element_1_id=?), cl.element_2_type, cl.element_1_type) AS element_2_type,
  IF( (cl.element_1_type=? AND cl.element_1_id=?), cl.element_2_id,   cl.element_1_id  ) AS element_2_id,
  IF( (cl.element_1_type=? AND cl.element_1_id=?), cl.fiber_num_2,    cl.fiber_num_1  )  AS fiber_num_2,

  IF( (cl.element_1_type=? AND cl.element_1_id=?), 1, 0) AS is_left,
  $self->{SEARCH_FIELDS}
  cl.id
FROM cablecat_links cl
WHERE
  ( cl.element_1_type=? AND cl.element_1_id=?)
      OR
      ( cl.element_2_type=? AND cl.element_2_id=?) " . ($WHERE ? "AND $WHERE" : ''),
    undef,
    {
      COLS_NAME => 1,
      Bind      => [
        $element_type, $element_id,
        $element_type, $element_id,
        $element_type, $element_id,
        $element_type, $element_id,
        $element_type, $element_id,
        $element_type, $element_id,
        $element_type, $element_id,
        $element_type, $element_id
      ]
    }
  );

  return $self->{list} || [];
}


#**********************************************************
=head2 cable_links_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut
#**********************************************************
sub cable_links_list{
  my ($self, $attr) = @_;

  my $SORT = $attr->{SORT} || 'id';
  my $DESC = ($attr->{DESC}) ? '' : 'DESC';
  my $PG = $attr->{PG} || '0';
  my $PAGE_ROWS = $attr->{PAGE_ROWS} || 25;

  my $search_columns = [
    ['ID',             'INT',        'id'               ,1 ],
    ['COMMUTATION_ID', 'INT',        'commutation_id'   ,1 ],

    ['CABLE_ID_1',     'INT',        'element_1_id'     ,1 ],
    ['FIBER_NUM_1',    'INT',        'fiber_num_1'      ,1 ],
    ['CABLE_SIDE_1',   'INT',        'element_1_side'   ,1 ],

    ['CABLE_ID_2',     'INT',        'element_2_id'     ,1 ],
    ['FIBER_NUM_2',    'INT',        'fiber_num_2'      ,1 ],
    ['CABLE_SIDE_2'  , 'INT',        'element_2_side'   ,1 ],


    ['ELEMENT_1_TYPE', 'STR',        'element_1_type'   ,1 ],
    ['ELEMENT_2_TYPE', 'STR',        'element_2_type'   ,1 ],

    ['ATTENUATION',    'INT',        'attenuation'      ,1 ],
    ['DIRECTION',      'INT',        'direction'        ,1 ],
    ['COMMENTS',       'STR',        'comments'         ,1 ],
    ['GEOMETRY',       'STR',        'geometry'         ,1 ],

  ];

  $attr->{ELEMENT_1_TYPE} = 'CABLE';
  $attr->{ELEMENT_2_TYPE} = 'CABLE';

  if ($attr->{SHOW_ALL_COLUMNS}){
    map { $attr->{$_->[0]} = '_SHOW' unless exists $attr->{$_->[0]} } @$search_columns;
  }
  my $WHERE =  $self->search_former($attr, $search_columns, { WHERE => 1 });
  my @BIND_VALUES = ();

  if ($attr->{CABLE_IDS} && ref $attr->{CABLE_IDS} eq 'ARRAY') {
    my @cable_ids = @{$attr->{CABLE_IDS}};
    $WHERE .= ($WHERE) ? ' AND ' : ' WHERE ';
    my $bind_placeholders = join (',', map { '?' } @cable_ids );

    $WHERE .= "element_1_id IN ( $bind_placeholders ) OR element_2_id IN ( $bind_placeholders )";
    push(@BIND_VALUES, @cable_ids, @cable_ids);
  }
  elsif ($attr->{FOR_ELEMENT_AND_FIBER} && ref $attr->{FOR_ELEMENT_AND_FIBER} eq 'HASH')  {
    my ($cable_id, $fiber_num) = ($attr->{FOR_ELEMENT_AND_FIBER}{ELEMENT_ID}, $attr->{FOR_ELEMENT_AND_FIBER}{FIBER_NUM});
    $WHERE .= ($WHERE) ? ' AND ' : ' WHERE ';
    $WHERE .= "(element_1_id IN (?) AND fiber_num_1 IN (?) OR "
      . "(element_2_id IN (?) AND fiber_num_2 IN (?) ";

    push(@BIND_VALUES, $cable_id, $fiber_num, $cable_id, $fiber_num);
  }

  $self->query( "SELECT $self->{SEARCH_FIELDS} id
   FROM cablecat_links
   $WHERE ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;", undef, {
    COLS_NAME => 1,
    Bind      =>  \@BIND_VALUES ,
    %{ $attr ? $attr : {}}}
  );

  if ($self->{errno}){
    $self->{TOTAL} = -1;
    return [ ]
  };

  my $list = $self->{list} || [];

  # TODO: pass WHERE
  $self->{TOTAL} = $self->links_count();

  return $list;
}

#**********************************************************
=head2 delete_links_for_element($element_type, $element_id) - deletes all links for element

  Arguments:
    $element_type, $element_id -

  Returns:
    1

=cut
#**********************************************************
sub delete_links_for_element {
  my ($self, $element_type, $element_id, $attr) = @_;

  $self->links_del({}, {
    element_1_type => $element_type,
    element_1_id   => $element_id,
    %{$attr // {} }
  });

  $self->links_del({}, {
    element_2_type => $element_type,
    element_2_id   => $element_id,
    %{$attr // {} }
  });


  return 1;
}

#**********************************************************
=head2 has_link_for_elements_fiber($element_type, $element_id, $fiber_num) -

  Arguments:
    $element_type -
    $element_id   -
    $fiber_num    -

  Returns:
    boolean

=cut
#**********************************************************
sub has_link_for_elements_fiber {
  my ($self, $type, $id, $num) = @_;

  $self->query("
  SELECT COUNT(*)
  FROM cablecat_links
  WHERE
   (element_1_type=? OR element_2_type=?)
     AND
   (element_1_id=? OR element_2_id=?)
     AND
   (fiber_num_1=? OR fiber_num_2=?)
     ",
    undef,
    {
      Bind => [ $type, $type, $id, $id, $num, $num ]
    }
  );

  if ($self->{errno}){
    return -1;
  }

  return $self->{list}[0] || -1;
}

#**********************************************************
=head2 connecters_links_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut
#**********************************************************
sub connecters_links_list{
  my ($self, $attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 'ccl.id';
  my $DESC = ($attr->{DESC}) ? '' : 'DESC';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $search_columns = [
    ['ID',             'INT',    'ccl.id'                                ,1 ],
    ['CONNECTER_1_ID', 'INT',    'ccl.connecter_1 AS connecter_1_id'     ,1 ],
    ['CONNECTER_2_ID', 'INT',    'ccl.connecter_2 AS connecter_2_id'     ,1 ],
    ['CONNECTER_1',    'STR',    'cc1.name AS connecter_1'               ,1 ],
    ['CONNECTER_2',    'STR',    'cc2.name AS connecter_2'               ,1 ],
  ];

  if ($attr->{SHOW_ALL_COLUMNS}){
    map { $attr->{$_->[0]} = '_SHOW' unless exists $attr->{$_->[0]} } @$search_columns;
  }
  my $WHERE =  $self->search_former($attr, $search_columns, { WHERE => 1 });
  my $EXT_TABLES = '';

  if ($self->{SEARCH_FIELDS} =~ /(?:cc1|cc2)\./){
    $EXT_TABLES .= qq{
      LEFT JOIN cablecat_wells cc1 ON (cc1.id=ccl.connecter_1)
      LEFT JOIN cablecat_wells cc2 ON (cc2.id=ccl.connecter_2)
    };
  }

  $self->query( "SELECT $self->{SEARCH_FIELDS} ccl.id
   FROM cablecat_connecters_links ccl
   $EXT_TABLES
   $WHERE ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;", undef, {
    COLS_NAME => 1,
    %{ $attr ? $attr : {}}}
  );

  return [] if $self->{errno};


  return $self->{list} || [];
}

#**********************************************************
=head2 cross_types_list($attr) -

=cut
#**********************************************************
sub cross_types_list {
  my ($self, $attr) = @_;

  $attr->{SEARCH_COLUMNS} = [
    [ 'ID',             'INT',   'ccrt.id'               ,1 ],
    [ 'NAME',           'STR',   'ccrt.name'             ,1 ],
    [ 'CROSS_TYPE_ID',  'INT',   'ccrt.cross_type_id'    ,1 ],
    [ 'PANEL_TYPE_ID',  'INT',   'ccrt.panel_type_id'    ,1 ],
    [ 'RACK_HEIGHT',    'INT',   'ccrt.rack_height'      ,1 ],
    [ 'PORTS_COUNT',    'INT',   'ccrt.ports_count'      ,1 ],
    [ 'PORTS_TYPE_ID',  'INT',   'ccrt.ports_type_id'    ,1 ],
    [ 'POLISH_TYPE_ID', 'INT',   'ccrt.polish_type_id'   ,1 ],
    [ 'FIBER_TYPE_ID',  'INT',   'ccrt.fiber_type_id'    ,1 ],
  ];

  return $self->_cablecat_list('cross_types ccrt', $attr);
}


#**********************************************************
=head2 cross_links_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut
#**********************************************************
sub cross_links_list{
  my ($self, $attr) = @_;

  $attr->{SEARCH_COLUMNS} = [
    [ 'CROSS_ID',    'INT',  'cross_id'    ,1 ],
    [ 'CROSS_PORT',  'INT',  'cross_port'  ,1 ],
    [ 'LINK_TYPE',   'INT',  'link_type'   ,1 ],
    [ 'LINK_VALUE',  'STR',  'link_value'  ,1 ],
  ];

  return $self->_cablecat_list('cross_links', $attr);
}

#**********************************************************
=head2 set_cable_well_link($cable_id, $first_well, $second_well) - Sets two wells for a cable

  Arguments:
    $cable_id    - cable to operate with
    $first_well  - first well for link
    $second_well - second well for link

  Returns:
    1 - if success

=cut
#**********************************************************
sub set_cable_well_link {
  my ($self, $cable_id, $first_well_id, $second_well_id) = @_;

  $self->query("SELECT id, well_1, well_2 FROM cablecat_cables WHERE id=? ", undef, { Bind => [ $cable_id ], COLS_NAME => 1 });
  return 0 if $self->{errno} || !defined $self->{list}[0];

  my $cable = $self->{list}[0];

  # Already linked
  return 0 if ($cable->{well_1} && $cable->{well_2});

  $self->changes( {
    CHANGE_PARAM => 'ID',
    TABLE        =>  'cablecat_cables',
    DATA         => {
      ID     => $cable_id,
      WELL_1 => $first_well_id,
      WELL_2 => $second_well_id
    },
  });

  return 1;
}

#**********************************************************
=head2 break_cable($cable_id, $well_id) - breaks cable in 2 parts

  Arguments:
    $cable_id - Cable to operate with
    $well_id  - New well (optional)

  Returns:
     [ $old_cable, $cable_1_id, $cable_2_id ] - old_cable and two new cable ids

=cut
#**********************************************************
sub break_cable {
  my ($self, $cable_id, $middle_well_id) = @_;

  return 'Wrong coords' unless ($cable_id);

  # Get current
  $self->query("SELECT id, name, type_id, well_1, well_2, point_id FROM cablecat_cables WHERE id=? ", undef,
    { Bind => [ $cable_id ], COLS_NAME => 1, COLS_UPPER => 1 });
  return qq{Cant find cable $cable_id} if ($self->{errno} || !defined $self->{list}->[0]);

  my $cable = $self->{list}->[0];

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

  if ($cable->{well_1} > $cable->{well_2}) {
    ($cable->{well_1}, $cable->{well_2}) = ($cable->{well_2}, $cable->{well_1});
  }
  $self->query_add('cablecat_cables', {
    %{$cable},
    ID => undef,
    NAME   => $cable->{name} . '_a',
    WELL_1 => $cable->{well_1},
    WELL_2 => $middle_well_id
  });

  # Check for errors and save new id
  return $exit_with_error->('Can\'t add new cable 1') if $self->{errno} || !$self->{INSERT_ID};
  my $first_new_id = $self->{INSERT_ID};

  $self->query_add('cablecat_cables', {
    %{$cable},
    ID => undef,
    NAME   => $cable->{name} . '_b',
    WELL_1 => $middle_well_id,
    WELL_2 => $cable->{well_2}
  });
  # Check for errors and save new id
  return $exit_with_error->('Can\'t add new cable 2') if $self->{errno} || !$self->{INSERT_ID};
  my $second_new_id = $self->{INSERT_ID};

  $self->query_del('cablecat_cables', { ID => $cable_id });
  return $exit_with_error->('Can\'t delete old cable') if $self->{errno};

  $db->commit();
  $db->{AutoCommit} = 1;

  return [ $cable, $first_new_id, $second_new_id ];
}

#**********************************************************
=head2 get_cables_for_well($well_id) - Get list of all cables for well

  Arguments:
    $attr - hash_ref
      WELL_ID - int

  Returns:
    list [{id, name, well_1, well_2}] - cables

=cut
#**********************************************************
sub get_cables_for_well {
  my ($self, $attr) = @_;

  my $well_id = $attr->{WELL_ID} || return [];

  if ($attr->{SHORT}) {
    $self->query( qq{
      SELECT id, name, well_1 AS well_1_id, well_2 AS well_2_id
      FROM cablecat_cables
      WHERE (well_1=? OR well_2=?)
    }, undef, { Bind => [ $well_id, $well_id ], COLS_NAME => 1 } );
  }
  else {
    $self->query( qq{
      SELECT cc.id, cc.name, cc.well_1 AS well_1_id, cc.well_2 AS well_2_id, cw1.name AS well_1, cw2.name AS well_2
      FROM cablecat_cables cc
      LEFT JOIN cablecat_wells cw1 ON (cc.well_1=cw1.id)
      LEFT JOIN cablecat_wells cw2 ON (cc.well_2=cw2.id)
      WHERE (cc.well_1=? OR cc.well_2=?)
     }, undef, { Bind => [ $well_id, $well_id ], COLS_NAME => 1 } );
  }
  return [] if $self->{errno};

  return $self->{list} || [];
}

#**********************************************************
=head2 commutations_add($attr) - Add commutation scheme and cables in scheme

  Arguments:
    $attr -

  Returns:
    1

=cut
#**********************************************************
sub commutations_add {
  my ($self, $attr) = @_;

  $self->query_add( 'cablecat_commutations', $attr );

  return 0 if $self->{errno};

  my $new_id = $self->{INSERT_ID};
  if ( $attr->{CABLE_IDS} && $new_id ) {
    my @cable_ids = split(/, ?/, $attr->{CABLE_IDS});
    $self->query( "INSERT INTO cablecat_commutation_cables (commutation_id, connecter_id, cable_id)
        VALUES (?, ?, ?);",
      undef,
      { MULTI_QUERY => [ map { [ $new_id, $attr->{CONNECTER_ID}, $_ ] } @cable_ids ] } );
  }

  return !defined $self->{errno};
}


#**********************************************************
=head2 commutations_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut
#**********************************************************
sub commutations_list{
  my ($self, $attr) = @_;

  my $SORT = $attr->{SORT} || 'id';
  my $DESC = ($attr->{DESC}) ? '' : 'DESC';
  my $PG = $attr->{PG} || '0';
  my $PAGE_ROWS = $attr->{PAGE_ROWS} || 25;

  my $search_columns = [
    ['ID',             'INT',        'cc.id'                                                ,1 ],
    ['NAME',           'STR',        'cc.name'                                              ,1 ],
    ['CONNECTER_ID',   'STR',        'cc.connecter_id'                                      ,1 ],
    ['CONNECTER',      'STR',        'ccon.name as connecter'                               ,1 ],
    ['WELL',           'STR',        'cw.name as well'                                      ,1 ],
    ['WELL_ID',        'INT',        'ccon.parent_id as well_id'                            ,1 ],
    ['CABLE_IDS',      'STR',        'cmc.cable_id', 'GROUP_CONCAT(cmc.cable_id) AS cable_ids' ],
    ['CABLES',         'STR',        'GROUP_CONCAT(ccab.name) AS cables'                    ,1 ],
    ['CREATED',        'DATE',       'cc.created'                                           ,1 ],
    ['HEIGHT',         'INT',        'cc.height'                                            ,1 ],
  ];

  if ($attr->{SHOW_ALL_COLUMNS}){
    map { $attr->{$_->[0]} = '_SHOW' unless exists $attr->{$_->[0]} } @$search_columns;
  }

  my $WHERE =  $self->search_former($attr, $search_columns, { WHERE => 1 });
  my $EXT_TABLES = '';
  my $EXT_GROUP  = '';

  my $join_cables = $self->_get_join_sql(
    'cmc', 'cablecat_cables', 'ccab', 'cable_id', 'id',
    {CHECK_SEARCH_FIELDS => 1}
  );
  my $join_commutation_cables = $self->_get_join_sql(
    'cc', 'cablecat_commutation_cables', 'cmc',  'id', 'commutation_id',
    {CHECK_SEARCH_FIELDS => ($join_cables ? 0 : 1)}
  );

  if ($join_cables || $join_commutation_cables){
    $EXT_TABLES .= $join_commutation_cables;
    $EXT_TABLES .= $join_cables;
    $EXT_GROUP .= 'GROUP BY cmc.commutation_id'
  }

  $EXT_TABLES .= $self->_get_join_sql(
    'cc', 'cablecat_wells', 'ccon', 'connecter_id', 'id',
    {CHECK_SEARCH_FIELDS => 1}
  );

  $EXT_TABLES .= $self->_get_join_sql(
    'ccon', 'cablecat_wells', 'cw', 'parent_id', 'id',
    {CHECK_SEARCH_FIELDS => 1}
  );

  $self->query( "SELECT $self->{SEARCH_FIELDS} cc.id
   FROM cablecat_commutations cc
   $EXT_TABLES
   $WHERE
   $EXT_GROUP
   ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;", undef, {
    COLS_NAME => 1,
    %{ $attr ? $attr : {}}}
  );

  return [] if $self->{errno};
  my $list = $self->{list};

  $self->query( "SELECT count(*) AS total
   FROM cablecat_commutations cc
   $EXT_TABLES
   $WHERE
   ", undef, {
    COLS_NAME => 1,
    %{ $attr ? $attr : {}}}
  );

  $self->{TOTAL} = $self->{list}[0]{total};

  return $list;
}


#**********************************************************
=head2 commutation_cables_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut
#**********************************************************
sub commutation_cables_list{
  my ($self, $attr) = @_;

  my $SORT = $attr->{SORT} || 'commutation_id';
  my $DESC = ($attr->{DESC}) ? '' : 'DESC';
  my $PG = $attr->{PG} || '0';
  my $PAGE_ROWS = $attr->{PAGE_ROWS} || 25;

  my $search_columns = [
    ['ID',             'INT',    'comcab.id'                 ,1 ],
    ['COMMUTATION_ID', 'INT',    'comcab.commutation_id'     ,1 ],
    ['CONNECTER_ID',   'INT',    'comcab.connecter_id'       ,1 ],
    ['CONNECTER',      'INT',    'cw.name AS connecter'      ,1 ],
    ['CABLE_ID',       'INT',    'comcab.cable_id'           ,1 ],
    ['COMMUTATION_X',  'INT',    'comcab.commutation_x'      ,1 ],
    ['COMMUTATION_Y',  'INT',    'comcab.commutation_y'      ,1 ],
    ['POSITION',       'STR',    'comcab.position'           ,1 ],
  ];

  if ($attr->{SHOW_ALL_COLUMNS}){
    map { $attr->{$_->[0]} = '_SHOW' unless exists $attr->{$_->[0]} } @$search_columns;
  }
  my $WHERE =  $self->search_former($attr, $search_columns, { WHERE => 1 });

  my $EXT_TABLES = '';
  if ($self->{SEARCH_FIELDS} =~ /cc\./){
    $EXT_TABLES = "LEFT JOIN cablecat_cables cc ON (comcab.cable_id = cc.id)"
  }

  if ($self->{SEARCH_FIELDS} =~ /cw\./){
    $EXT_TABLES = "LEFT JOIN cablecat_wells cw ON (comcab.connecter_id = cw.id)"
  }

  $self->query( "SELECT $self->{SEARCH_FIELDS} comcab.commutation_id
   FROM cablecat_commutation_cables comcab
   $EXT_TABLES
   $WHERE ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;", undef, {
    COLS_NAME => 1,
    %{ $attr ? $attr : {}}}
  );

  return [] if $self->{errno};

  return $self->{list} || [];
}

#**********************************************************
=head2 commutation_equipment_list($attr) -

=cut
#**********************************************************
sub commutation_equipment_list {
  my ($self, $attr) = @_;

  $attr->{SEARCH_COLUMNS} = [
    [ 'ID',                   'INT',        'ce.id'                          ,1 ],
    [ 'NAS_ID',               'STR',        'ce.nas_id'                      ,1 ],
    [ 'MODEL_ID',             'STR',        'eq.model_id'                    ,1 ],
    [ 'PORTS_TYPE',           'STR',        'em.ports_type'                  ,1 ],
    [ 'MODEL_NAME',           'STR',        'em.model_name'                  ,1 ],
    [ 'PORTS',                'STR',        'em.ports'                       ,1 ],
    [ 'COMMUTATION_ID',       'INT',        'ce.commutation_id'              ,1 ],
    [ 'COMMUTATION_X',        'INT',        'ce.commutation_x'               ,1 ],
    [ 'COMMUTATION_Y',        'INT',        'ce.commutation_y'               ,1 ],
    [ 'COMMUTATION_ROTATION', 'INT',        'ce.commutation_rotation'        ,1 ],
    [ 'PARENT_ID',            'INT',       'pcw.id'      ,'pcw.id as parent_id' ],
    [ 'UID',                  'INT',        'i.uid'                          ,1 ],
    [ 'SERVICE_ID',           'INT',        'i.id'        ,'i.id as service_id' ],
  ];

  $attr->{SEARCH_FIELDS_FILTER} = sub {
    my $EXT_TABLES = '';

    $EXT_TABLES .= $self->_get_join_sql(
      'ce', 'equipment_infos', 'eq', 'nas_id', 'nas_id',
      { CHECK_SEARCH_FIELDS => 1 }
    );

    $EXT_TABLES .= $self->_get_join_sql(
      'eq', 'equipment_models', 'em', 'model_id', 'id',
      { CHECK_SEARCH_FIELDS => 1 }
    );

    $EXT_TABLES .= $self->_get_join_sql(
      'ce', 'cablecat_commutations', 'cc', 'commutation_id', 'id',
      { CHECK_SEARCH_FIELDS => 0 }
    );

    $EXT_TABLES .= $self->_get_join_sql(
      'cc', 'cablecat_wells', 'cw', 'connecter_id', 'id',
      { CHECK_SEARCH_FIELDS => 1 }
    );

    $EXT_TABLES .= $self->_get_join_sql(
      'cw', 'cablecat_wells', 'pcw', 'parent_id', 'id',
      { CHECK_SEARCH_FIELDS => 1 }
    );

    $EXT_TABLES .= $self->_get_join_sql(
      'ce', 'internet_main', 'i', 'nas_id', 'nas_id',
      { CHECK_SEARCH_FIELDS => 1 }
    );

    {
      FROM => "cablecat_commutation_equipment ce $EXT_TABLES"
    }
  };

  return $self->_cablecat_list('commutation_equipment', { %{$attr}, GROUP_BY => 'ce.id' });
}

#**********************************************************
=head2 commutation_equipment_ids($commutation_id) - returns ids of all equipment existing on commutation

  Arguments:
     $commutation_id - (optionally) filter by commutation

  Returns:
    array_ref

=cut
#**********************************************************
sub commutation_equipment_ids {
  my ($self, $commutation_id ) = @_;

  my $WHERE = '';
  my @BIND = ();

  if ($commutation_id){
    $WHERE = 'WHERE id=?';
    push @BIND, $commutation_id;
  }

  $self->query("SELECT nas_id FROM cablecat_commutation_equipment $WHERE;");

  # MAYBE: if will receive error for no [0] element, should additionaly use grep
  my @ids_list = map { $_->[0] } @{$self->{list} || []};

  return wantarray ? @ids_list : \@ids_list;
}

#**********************************************************
=head2 commutation_crosses_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut
#**********************************************************
sub commutation_crosses_list{
  my ($self, $attr) = @_;

  $attr->{SEARCH_COLUMNS} = [
    [ 'CROSS_ID',              'INT',        'ccc.cross_id'                     ,1 ],
    [ 'NAME',                  'STR',        'cc.name'                          ,1 ],
    [ 'COMMUTATION_ID',        'INT',        'ccc.commutation_id'               ,1 ],
    [ 'PORT_START',            'INT',        'ccc.port_start'                   ,1 ],
    [ 'PORT_FINISH',           'INT',        'ccc.port_finish'                  ,1 ],
    [ 'COMMUTATION_X',         'INT',        'ccc.commutation_x'                ,1 ],
    [ 'COMMUTATION_Y',         'INT',        'ccc.commutation_y'                ,1 ],
    [ 'COMMUTATION_ROTATION',  'INT',        'ccc.commutation_rotation'         ,1 ],
    [ 'FIBERS_COLORS_NAME',    'STR',        'ccs_f.name AS fibers_colors_name' ,1 ],
    [ 'FIBERS_COLORS',         'STR',        'ccs_f.colors AS fibers_colors'    ,1 ],
    [ 'TYPE_NAME',             'STR',        'ccrt.name AS type_name'           ,1 ],
    [ 'PORTS_TYPE_ID',         'INT',        'ccrt.ports_type_id'               ,1 ],
    [ 'POLISH_TYPE_ID',        'INT',        'ccrt.polish_type_id'              ,1 ],
    [ 'FIBER_TYPE_ID',         'INT',        'ccrt.fiber_type_id'               ,1 ],
  ];

  $attr->{SEARCH_FIELDS_FILTER} = sub {
    my $EXT_TABLES = '';

    $EXT_TABLES .= $self->_get_join_sql(
      'ccc', 'cablecat_crosses', 'cc', 'cross_id', 'id', { CHECK_SEARCH_FIELDS => 1 }
    );

    $EXT_TABLES .= $self->_get_join_sql(
      'cc', 'cablecat_color_schemes', 'ccs_f', 'color_scheme_id', 'id', { CHECK_SEARCH_FIELDS => 1 }
    );

    $EXT_TABLES .= $self->_get_join_sql(
      'cc', 'cablecat_cross_types', 'ccrt', 'type_id', 'id', { CHECK_SEARCH_FIELDS => 1 }
    );

    {
      FROM => "cablecat_commutation_crosses ccc $EXT_TABLES"
    }
  };

  if ($attr->{PORT} && $attr->{PORT} =~ /^\d+$/){
    $attr->{WHERE_RULES} = [ "($attr->{PORT} BETWEEN ccc.port_start AND ccc.port_finish)" ];
  }

  return $self->_cablecat_list('commutation_crosses', $attr);
}

#**********************************************************
=head2 commutation_crosses_ids()

  Arguments:
     $commutation_id - (optionally) filter by commutation

  Returns:
    array_ref

=cut
#**********************************************************
sub commutation_crosses_ids {
  my ($self, $commutation_id ) = @_;

  my $WHERE = '';
  my @BIND = ();

  if ($commutation_id){
    $WHERE = 'WHERE id=?';
    push @BIND, $commutation_id;
  }

  $self->query("SELECT DISTINCT cross_id FROM cablecat_commutation_crosses $WHERE;");

  # MAYBE: if will receive error for no [0] element, should additionaly use grep
  my @ids_list = map { $_->[0] } @{$self->{list} || []};

  return wantarray ? @ids_list : \@ids_list;
}


#**********************************************************
=head2 get_items_for_commutation($commutation_id)

=cut
#**********************************************************
sub get_items_for_commutation {
  my ($self, $commutation_id) = @_;

  return 0 unless $commutation_id;

  my %result = ();

  my @commutation_entities = qw/
    cables
    splitters
    crosses
    equipment
  /;

  foreach my $entity (@commutation_entities){
    my $list_func = "$entity\_list";
    my $list = $self->$list_func({ COMMUTATION_ID => $commutation_id });

    $result{uc($entity)} = $list;
  }

  return \%result;
}

#**********************************************************
=head2 get_commutations_for_element($element_type, $element_id)

  Arguments:
    $element_type -
    $element_id   -

  Returns:
    \@commutation_ids

=cut
#**********************************************************
sub get_commutations_for_element {
  my ($self, $element_type, $element_id) =  @_;
  return unless ($element_type && $element_id);

  my @commutation_ids = ();

  if ($element_type eq 'SPLITTER'){
    $self->query("SELECT commutation_id FROM cablecat_splitters WHERE id=?", undef,{
      Bind => [ $element_id ]
    });
    return if ($self->{errno});
    my $spl_com_ids = $self->{list} || [];
    # Now should splat two dimensional array [[1], [1], [1]] to usual array
    @commutation_ids = map { $_->[0] } @$spl_com_ids if ($spl_com_ids && ref $spl_com_ids eq 'ARRAY');
  }
  else {
    my %table_for_type = (
      CABLE => 'cables',
      CROSS => 'crosses',
      EQUIPMENT => 'equipment'
    );

    my %id_col_name_for_type = (
      CABLE     => 'CABLE_ID',
      CROSS     => 'CROSS_ID',
      EQUIPMENT => 'NAS_ID',
    );

    if (!exists $table_for_type{$element_type}){
      $self->{errno}  = 1321;
      $self->{errstr} = "WRONG ELEMENT TYPE GIVEN";
    }

    my $element_id_field_name = $id_col_name_for_type{$element_type} || 'ID';
    my $table = "commutation_$table_for_type{$element_type}\_list";

    $self->query("SELECT DISTINCT commutation_id FROM $table WHERE $element_id_field_name=?", undef,{
      Bind => [ $element_id ]
    });
    return if ($self->{errno});
    my $spl_com_ids = $self->{list} || [];
    # Now should splat two dimensional array [[1], [1], [1]] to usual array
    @commutation_ids = map { $_->[0] } @$spl_com_ids if ($spl_com_ids && ref $spl_com_ids eq 'ARRAY');
  }

  return \@commutation_ids;
}

#**********************************************************
=head2 cable_list_with_points

=cut
#**********************************************************
sub cable_list_with_points {
  my $self = shift;
  my ($attr) = @_;

  my $PAGE_ROWS = $attr->{NEW_OBJECT} ? 'LIMIT 1' : '';
  my $WHERE = "WHERE cc.point_id <> ''";

  if ($attr->{OBJECT_ID}) {
    $WHERE .= " AND cc.point_id=$attr->{OBJECT_ID}";
  }
  elsif ($attr->{LAST_OBJECT_ID}) {
    $WHERE .= " AND cc.point_id > $attr->{LAST_OBJECT_ID}";
  }

  $self->query("SET SESSION group_concat_max_len = 1000000;", 'do');
  $self->query("SELECT cc.id AS cable_id, cc.name, cct.name AS cable_type, cw1.name AS well_1, cw2.name AS well_2, cc.length, cc.point_id,
    cc.well_1 AS well_1_id, cc.well_2 AS well_2_id, cct.outer_color, mline.length AS length_calculated,
    cct.line_width, cct.can_be_splitted, mp.id, mp.comments, mt.id as type_id,
    mt.icon,cw1.point_id AS well_1_point_id, cw2.point_id AS well_2_point_id,
    mp.created,
    GROUP_CONCAT(DISTINCT CONCAT(plpoints.coordx, '|' ,plpoints.coordy) ORDER BY plpoints.id DESC) AS coords
      FROM cablecat_cables cc
      LEFT JOIN cablecat_wells cw1 ON (cc.well_1=cw1.id)
      LEFT JOIN cablecat_wells cw2 ON (cc.well_2=cw2.id)
      LEFT JOIN maps_points mp ON (cc.point_id=mp.id)
      LEFT JOIN maps_point_types mt ON (mp.type_id=mt.id)
      LEFT JOIN maps_coords mc ON (mp.coord_id=mc.id)
      LEFT JOIN maps_polylines mline ON (mline.object_id=mp.id)
      LEFT JOIN maps_polyline_points plpoints ON(mline.id=plpoints.polyline_id)
      LEFT JOIN cablecat_cable_types cct ON (cc.type_id=cct.id)
    $WHERE
    GROUP BY mline.id, cc.id
    HAVING coords <> ''
    ORDER BY cc.id DESC $PAGE_ROWS", undef, { COLS_NAME => 1 }
  );

  return $self->{TOTAL} if ($attr->{ONLY_TOTAL});

  return $self->{list};
}

#**********************************************************
=head2 wells_with_coords

=cut
#**********************************************************
sub wells_with_coords {
  my $self = shift;
  my ($attr) = @_;

  my $PAGE_ROWS = $attr->{PAGE_ROWS} ? "LIMIT $attr->{PAGE_ROWS}" : '';
  my $WHERE = $self->search_former($attr, [ [ 'POINT_ID', 'INT', 'cw.point_id', 1 ], ], { WHERE => 1, });
  my $GROUP_BY = $attr->{GROUP_BY} || 'GROUP BY cw.point_id';

  $WHERE .= $WHERE ? " AND cw.point_id <> '' AND coordx <> '' AND coordy <> ''" :
    "cw.point_id <> '' AND coordx <> '' AND coordy <> ''";

  $self->query("SELECT cw.point_id, cw.type_id, COUNT(*) AS total,
    mc.coordx as coordx, mc.coordy as coordy, mp.planned, mp.comments,
    GROUP_CONCAT(DISTINCT CONCAT(cw.name)  SEPARATOR '||') AS names,
    GROUP_CONCAT(DISTINCT CONCAT(cw.picture)  SEPARATOR '||') AS pictures, mp.created, wt.name AS type_name,
    GROUP_CONCAT(DISTINCT CONCAT(cw.id)  SEPARATOR '||') AS ids, wt.icon AS icon

      FROM cablecat_wells cw
      LEFT JOIN maps_points mp ON (cw.point_id=mp.id)
      LEFT JOIN cablecat_well_types wt ON (wt.id=cw.type_id)
      LEFT JOIN maps_coords mc ON (mp.coord_id=mc.id)
    $WHERE
    $GROUP_BY
    ORDER BY cw.point_id DESC $PAGE_ROWS;",
    undef, { %{$attr}, COLS_NAME => 1 }
  );

  return $self->{TOTAL} if ($attr->{ONLY_TOTAL});

  return $self->{list};
}

#**********************************************************
=head2 closest_wells($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub closest_wells {
  my $self = shift;
  my ($attr) = @_;

  return () if !$attr->{COORDX} && !$attr->{COORDY};

  $self->query("SELECT cw.name, cw.id as well_id, coordx, coordy,
    (ABS(mc.coordx - $attr->{COORDX}) + ABS(mc.coordy - $attr->{COORDY})) AS coords_difference
      FROM cablecat_wells cw
      LEFT JOIN maps_points mp ON (cw.point_id=mp.id)
      LEFT JOIN maps_coords mc ON (mp.coord_id=mc.id)
    WHERE mc.coordx <> 0 AND mc.coordy <> 0
    ORDER BY coords_difference LIMIT 2;",
    undef, { %{$attr}, COLS_NAME => 1 }
  );

  return $self->{TOTAL} if ($attr->{ONLY_TOTAL});

  return $self->{list};
}

#**********************************************************
=head2 schemes_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut
#**********************************************************
sub schemes_list {
  my ($self, $attr) = @_;

  $attr->{SEARCH_COLUMNS} = [
    [ 'ID',             'INT',      'id',             1 ],
    [ 'COMMUTATION_ID', 'INT',      'commutation_id', 1 ],
    [ 'COMMUTATION_X',  'INT',      'commutation_x',  1 ],
    [ 'COMMUTATION_Y',  'INT',      'commutation_y',  1 ],
    [ 'HEIGHT',         'INT',      'height',         1 ],
    [ 'WIDTH',          'INT',      'width',          1 ]
  ];

  return $self->_cablecat_list('schemes', $attr);
}

#**********************************************************
=head2 scheme_elements_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut
#**********************************************************
sub scheme_elements_list {
  my ($self, $attr) = @_;

  $attr->{SEARCH_COLUMNS} = [
    [ 'ID',             'INT',      'id',             1 ],
    [ 'TYPE',           'STR',      'type',           1 ],
    [ 'COMMUTATION_X',  'INT',      'commutation_x',  1 ],
    [ 'COMMUTATION_Y',  'INT',      'commutation_y',  1 ]
  ];

  return $self->_cablecat_list('scheme_elements', $attr);
}

#**********************************************************
=head2 scheme_splitters_list($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub scheme_splitters_list {
  my $self = shift;
  my ($attr) = @_;

  my $WHERE = $self->search_former($attr, [ [ 'COMMUTATION_ID', 'INT', 'cs.commutation_id', 1 ], ], { WHERE => 1, });

  $self->query("SELECT cs.id, cst.name AS type, cw.name AS well, cs.point_id, mp.created, mp.planned,
      mp.installed, cst.fibers_in, cst.fibers_out, cs.well_id, cs.type_id, cs.commutation_id,
      cs.commutation_rotation, ccs_f.name AS fibers_colors_name, ccs_f.colors AS fibers_colors, cs.color_scheme_id,
      cs.attenuation, if (cse.commutation_x<>'', cse.commutation_x, cs.commutation_x) AS commutation_x,
      if (cse.commutation_y<>'', cse.commutation_y, cs.commutation_y) AS commutation_y,
      if ((cse.commutation_y<>'' AND cse.commutation_x<>''), 1, 0) AS changed_coords
    FROM cablecat_splitters cs
    LEFT JOIN cablecat_splitter_types cst ON (cs.type_id = cst.id)
    LEFT JOIN cablecat_wells cw ON (cs.well_id = cw.id)
    LEFT JOIN maps_points mp ON (cs.point_id = mp.id)
    LEFT JOIN cablecat_color_schemes ccs_f ON (cs.color_scheme_id = ccs_f.id)
    LEFT JOIN cablecat_scheme_elements cse ON (cse.id=cs.id AND cse.type='splitter')
    $WHERE;",
    undef, { %{$attr}, COLS_NAME => 1 }
  );

  return $self->{list};
}

#**********************************************************
=head2 scheme_cables_list($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub scheme_cables_list {
  my $self = shift;
  my ($attr) = @_;

  my $WHERE = $self->search_former($attr, [ [ 'COMMUTATION_ID', 'INT', 'cmc.commutation_id', 1 ], ], { WHERE => 1 });

  $self->query("SELECT cc.id, cc.name, cct.name AS cable_type, mp.comments, mp.created, cw1.name AS well_1,
  cw2.name AS well_2, cct.fibers_count, cct.modules_count, cc.length, cc.reserve, mline.id AS polyline_id,
  cc.point_id, cc.well_1 AS well_1_id, cc.well_2 AS well_2_id, cc.type_id, ccs_m.name AS modules_colors_name,
  ccs_m.colors AS modules_colors, ccs_f.name AS fibers_colors_name, ccs_f.colors AS fibers_colors, cct.outer_color,
  mline.length AS length_calculated, cse.commutation_x, cse.commutation_y
    FROM cablecat_commutation_cables cmc
    LEFT JOIN cablecat_commutations ccm ON (ccm.id = cmc.commutation_id)
    LEFT JOIN  cablecat_cables cc ON (cc.id = cmc.cable_id)
    LEFT JOIN cablecat_wells cw1 ON (cc.well_1=cw1.id)
    LEFT JOIN cablecat_wells cw2 ON (cc.well_2=cw2.id)
    LEFT JOIN maps_points mp ON (cc.point_id=mp.id)
    LEFT JOIN maps_polylines mline ON (mline.object_id=mp.id)
    LEFT JOIN cablecat_cable_types cct ON (cc.type_id=cct.id)
    LEFT JOIN cablecat_color_schemes ccs_m ON (ccs_m.id=cct.modules_color_scheme_id)
    LEFT JOIN cablecat_color_schemes ccs_f ON (ccs_f.id=cct.color_scheme_id)
    LEFT JOIN cablecat_scheme_elements cse ON (cc.id=cse.id AND cse.type='cable')
    $WHERE ORDER BY 1 DESC;",
    undef, { %{$attr}, COLS_NAME => 1 }
  );

  return $self->{list};
}

#**********************************************************
=head2 scheme_equipments_list($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub scheme_equipments_list {
  my $self = shift;
  my ($attr) = @_;

  my $WHERE = $self->search_former($attr, [ [ 'COMMUTATION_ID', 'INT', 'ce.commutation_id', 1 ], ], { WHERE => 1 });

  $self->query("SELECT ce.id, ce.nas_id, eq.model_id, em.model_name, em.ports, ce.commutation_id, ce.commutation_rotation,
      if (cse.commutation_x<>'', cse.commutation_x, ce.commutation_x) AS commutation_x,
      if (cse.commutation_y<>'', cse.commutation_y, ce.commutation_y) AS commutation_y,
      if ((cse.commutation_y<>'' AND cse.commutation_x<>''), 1, 0) AS changed_coords
    FROM cablecat_commutation_equipment ce
    LEFT JOIN equipment_infos eq ON (ce.nas_id = eq.nas_id)
    LEFT JOIN equipment_models em ON (eq.model_id = em.id)
    LEFT JOIN cablecat_scheme_elements cse ON (ce.nas_id=cse.id AND cse.type='equipment')
    $WHERE ORDER BY 1 DESC;",
    undef, { %{$attr}, COLS_NAME => 1 }
  );

  return $self->{list};
}

#**********************************************************
=head2 scheme_crosses_list($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub scheme_crosses_list {
  my $self = shift;
  my ($attr) = @_;

  my $WHERE = $self->search_former($attr, [ [ 'COMMUTATION_ID', 'INT', 'ccc.commutation_id', 1 ], ], { WHERE => 1 });

  $self->query("SELECT ccc.cross_id, cc.name, ccc.commutation_id, ccc.port_start, ccc.port_finish,
      ccc.commutation_rotation, ccs_f.name AS fibers_colors_name, ccs_f.colors AS fibers_colors,
      if (cse.commutation_x<>'', cse.commutation_x, ccc.commutation_x) AS commutation_x,
      if (cse.commutation_y<>'', cse.commutation_y, ccc.commutation_y) AS commutation_y,
      if ((cse.commutation_y<>'' AND cse.commutation_x<>''), 1, 0) AS changed_coords
    FROM cablecat_commutation_crosses ccc
    LEFT JOIN cablecat_crosses cc ON (ccc.cross_id = cc.id)
    LEFT JOIN cablecat_color_schemes ccs_f ON (cc.color_scheme_id = ccs_f.id)
    LEFT JOIN cablecat_scheme_elements cse ON (ccc.cross_id=cse.id AND cse.type='cross')
    $WHERE ORDER BY 1 DESC;",
    undef, { %{$attr}, COLS_NAME => 1 }
  );

  return $self->{list};
}

#**********************************************************
=head2 scheme_links_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut
#**********************************************************
sub scheme_links_list {
  my ($self, $attr) = @_;

  if ($attr->{ONLY_SCHEME_LINKS}) {
    $attr->{SEARCH_COLUMNS} = [
      [ 'ID',       'INT', 'id',        1 ],
      [ 'GEOMETRY', 'STR', 'geometry',  1 ]
    ];

    return $self->_cablecat_list('scheme_links', $attr);
  }

  my $WHERE = $self->search_former($attr, [ [ 'COMMUTATION_ID', 'INT', 'cl.commutation_id', 1 ], ], { WHERE => 1 });

  $self->query("SELECT cl.id, cl.commutation_id, cl.element_1_id, cl.element_2_id, cl.element_1_type,
      cl.element_2_type, cl.fiber_num_1, cl.fiber_num_2, cl.attenuation, cl.direction, cl.comments,
      if (csl.geometry <> '', csl.geometry, cl.geometry) as geometry,
      if ((csl.geometry <> ''), 1, 0) AS changed_coords
    FROM cablecat_links cl
    LEFT JOIN cablecat_scheme_links csl ON (csl.id=cl.id)
    $WHERE ORDER BY 1 DESC;",
    undef, { %{$attr}, COLS_NAME => 1 }
  );

  return $self->{list};
}

#**********************************************************
=head2 import_presets_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut
#**********************************************************
sub import_presets_list {
  my ($self, $attr) = @_;

  $attr->{SEARCH_COLUMNS} = [
    ['ID',                  'INT',      'id'         ,          1 ],
    ['DEFAULT_OBJECT_NAME', 'STR',      'default_object_name',  1 ],
    ['PRESET_NAME',         'STR',      'preset_name',          1 ],
    ['OBJECT_NAME',         'STR',      'object_name',          1 ],
    ['DEFAULT_TYPE_ID',     'INT',      'default_type_id',      1 ],
    ['TYPE_ID',             'STR',      'type_id',              1 ],
    ['OBJECT',              'STR',      'object',               1 ],
    ['OBJECT_ADD',          'INT',      'object_add',           1 ],
    ['COORDX',              'STR',      'coordx',               1 ],
    ['COORDY',              'STR',      'coordy',               1 ],
    ['LOAD_URL',            'STR',      'load_url',             1 ],
    ['JSON_PATH',           'STR',      'json_path',            1 ],
    ['FILTERS',             'STR',      'filters',              1 ]
  ];

  return $self->_cablecat_list('import_presets', $attr);
}

#**********************************************************
=head2 users_list_by_equipment($nas_id)

  Arguments:
    nas_id - equipment id

  Returns:
    list

=cut
#**********************************************************
sub users_list_by_equipment {
  my ($self, $nas_id) = @_;

  return [] if !$nas_id;

  $self->query("SELECT im.uid, im.id AS service_id FROM cablecat_commutation_equipment cce
    LEFT JOIN internet_main im ON (cce.nas_id=im.nas_id)
    LEFT JOIN cablecat_commutation_onu cco ON (cco.service_id=im.id)
    WHERE cco.uid IS NOT NULL AND cce.nas_id = $nas_id
    ORDER BY 1 DESC;",
    undef, { COLS_NAME => 1 }
  );

  return $self->{list} || [];
}

#**********************************************************
=head2 users_list_by_equipment($nas_id)

  Arguments:
    nas_id - equipment id

  Returns:
    list

=cut
#**********************************************************
sub ports_type_by_equipment {
  my ($self, $nas_id) = @_;

  return [] if !$nas_id;

  $self->query("SELECT COUNT(pon_type) AS total, pon_type AS type_name
    FROM equipment_pon_ports WHERE nas_id = $nas_id GROUP BY pon_type ORDER BY total DESC",
    undef, { COLS_NAME => 1 }
  );

  return $self->{list} || [ ];
}

#**********************************************************
=head2 cablecat_storage_add()

  Arguments:
    CABLE_ID                     - Identifier of cable
    STORAGE_INCOMING_ARTICLES_ID - ID from storage_incoming_articles table

  Returns:

=cut
#**********************************************************
sub cablecat_storage_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('cablecat_storage', {
    %{$attr},
    AID  => $self->{admin}{AID},
    DATE => 'NOW()'
  });

  return $self;
}

#**********************************************************
=head2 cablecat_storage_list()

=cut
#**********************************************************
sub cablecat_storage_list {
  my ($self, $attr) = @_;

  $attr->{SEARCH_COLUMNS} = [
    [ 'ID',                'INT',  'cs.id',                         1 ],
    [ 'DATE',              'DATE', 'cs.date',                       1 ],
    [ 'CABLE_ID',          'INT',  'cs.cable_id',                   1 ],
    [ 'INSTALLATION_ID',   'INT',  'cs.installation_id',            1 ],
    [ 'ARTICLE_TYPE_NAME', 'STR',  'sat.name as article_type_name', 1 ],
    [ 'ARTICLE_NAME',      'STR',  'sta.name as article_name',      1 ],
    [ 'COUNT',             'STR',  'si.count',                      1 ]
  ];

  $attr->{SEARCH_FIELDS_FILTER} = sub {
    my $EXT_TABLES = '';

    $EXT_TABLES .= $self->_get_join_sql('cs', 'storage_installation', 'si', 'installation_id', 'id', { CHECK_SEARCH_FIELDS => 1 });
    $EXT_TABLES .= $self->_get_join_sql('si', 'storage_incoming_articles', 'sia', 'storage_incoming_articles_id', 'id');
    $EXT_TABLES .= $self->_get_join_sql('sia', 'storage_articles', 'sta', 'article_id', 'id', { CHECK_SEARCH_FIELDS => 1 });
    $EXT_TABLES .= $self->_get_join_sql('sta', 'storage_article_types', 'sat', 'article_type', 'id', { CHECK_SEARCH_FIELDS => 1 });

    { FROM => "cablecat_storage cs $EXT_TABLES" }
  };

  return $self->_cablecat_list('storage', $attr);
}

sub DESTROY{};


=head1 COPYRIGHT

  Copyright (с) 2003-2023 Andy Gulay (ABillS DevTeam) Ukraine
  All rights reserved.
  https://billing.axiostv.ru/

=cut

1;
