package Events;
use strict;
use warnings FATAL => 'all';

=head2 NAME

 Events

=head2 SYNOPSIS

   $Events->events_add( {
      # Name for module
        MODULE      => 'Test',
      # Text
        COMMENTS    => 'Generated',
      # Link to see external info
        EXTRA       => 'https://billing.axiostv.ru',
      # 1..5 Bigger is more important
        PRIORITY_ID => 1,
      } );

=cut

use Time::Local qw (timelocal);
our(
  %conf
);

our $VERSION = 1.00;

use parent 'dbcore';


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
  Info functions are working regarding to 'SHOW_ALL_COLUMNS' in table_list()
  
  Just call $Events->group_info($group_id)
  
  Arguments:
    arguments are typical for operations, assuming we are working with ID column as primary key
    
  Returns:
    returns same result as usual operation functions ( Generally nothing )

=cut
#**********************************************************
sub AUTOLOAD {
  our $AUTOLOAD;
  return if ( $AUTOLOAD =~ /::DESTROY$/ );
  
  my ($entity_name, $operation) = $AUTOLOAD =~ /.*::(.*)_(add|del|change|info)$/;
  
  die "Undefined function $AUTOLOAD" unless ( $operation && $entity_name );
  
  my ($self, $data, $attr) = @_;
  
  my $table = lc(__PACKAGE__) . '_' . $entity_name;
  
  # Check for not standart table namings
  my %unusual_names = (
    'events_events' => 'events'
  );
  if ( exists $unusual_names{$table} ) {$table = $unusual_names{$table}};
  
  if ( $operation eq 'add' ) {
    return $self->query_add($table, $data, $attr);
  }
  if ( $operation eq 'del' ) {
    return $self->query_del($table, $data);
  }
  if ( $operation eq 'change' ) {
    return $self->changes({
      CHANGE_PARAM => 'ID',
      TABLE        => $table,
      DATA         => $data,
    });
  }
  if ( $operation eq 'info' ) {
    my $list_func_name = $entity_name . '_list';
    if ( !$self->can($list_func_name) ) {
      return ;
    }
  
    my $list = $self->$list_func_name({
      ID               => $data,
      SHOW_ALL_COLUMNS => 1,
      COLS_UPPER       => 1,
      COLS_NAME        => 1,
      %{ $self->{domain_id} ? { DOMAIN_ID => $self->{domain_id} } : {} },
      %{ $attr ? $attr : {} }
    });
    
    return 0 if ($self->{errno});
    
    if ($list && ref $list eq 'ARRAY' && !scalar(@$list)){
      $self->{errno} = 4;
      $self->{errstr} = 'ERR_NOT_EXIST';
    }
    
    return $list->[0] || {};
  }
}


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
  my $class = shift;
  my ($db, $admin, $CONF) = @_;

  my $self = {
    db        => $db,
    admin     => $admin,
    conf      => $CONF,
    domain_id => $admin->{DOMAIN_ID}
  };

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 events_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut
#**********************************************************
sub events_list {
  my $self = shift;
  my ($attr) = @_;
  
  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 'e.id';
  my $DESC = ($attr->{DESC}) ? '' : 'DESC';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;
  
  my $search_columns = [
    [ 'ID',           'INT',            'e.id',                           1 ],
    [ 'TITLE',        'STR',            'e.title',                        1 ],
    [ 'COMMENTS',     'STR',            'e.comments',                     1 ],
    [ 'MODULE',       'STR',            'e.module',                       1 ],
    [ 'EXTRA',        'STR',            'e.extra',                        1 ],
    [ 'STATE_ID',     'INT',            'e.state_id',                     1 ],
    [ 'PRIVACY_ID',   'INT',            'e.privacy_id',                   1 ],
    [ 'PRIORITY_ID',  'INT',            'e.priority_id',                  1 ],
    [ 'CREATED',      'DATE',           'e.created',                      1 ],
    [ 'GROUP_ID',     'INT',            'e.group_id AS group_id',         1 ],
    [ 'GROUP_NAME',   'INT',            'eg.name AS group_name',          1 ],
    [ 'PRIVACY_NAME', 'STR',            'epriv.name AS privacy_name',     1 ],
    [ 'PRIORITY_NAME','STR',            'eprio.name AS priority_name',    1 ],
    [ 'STATE_NAME',   'STR',            'es.name AS state_name',          1 ],
    [ 'GROUP_MODULES','STR',            'eg.modules AS group_modules',    1 ],
    [ 'DOMAIN_ID',    'INT',            'e.domain_id',                    1 ],
    [ 'AID',          'INT',            'e.aid',                          1 ],
    [ 'SEND_TYPES',   'STR',            'epst.send_types',                1 ],
  ];
  
  if ( $attr->{SHOW_ALL_COLUMNS} ) {
    map {$attr->{ $_->[0] } = '_SHOW' unless ( exists $attr->{ $_->[0] } )} @{$search_columns};
  }
  
  # DELETE ME IN 2019 (when all events will have aid)
  my @WHERE_RULES = ();
  if ($attr->{AID} && $attr->{AID} ne '_SHOW'){
    push @WHERE_RULES, "e.aid=$attr->{AID} OR e.aid=0";
    delete $attr->{AID};
  }
  
  if ($self->{domain_id}){
    $attr->{DOMAIN_ID} = $self->{domain_id};
  }
  
  my $WHERE = $self->search_former($attr, $search_columns, { WHERE => 1, WHERE_RULES => \@WHERE_RULES });
  $self->query(
    "SELECT $self->{SEARCH_FIELDS} e.id
    FROM events e
    LEFT JOIN events_privacy epriv FORCE INDEX FOR JOIN (`PRIMARY`) ON (e.privacy_id = epriv.id)
    LEFT JOIN events_priority eprio FORCE INDEX FOR JOIN (`PRIMARY`) ON (e.priority_id = eprio.id)
    LEFT JOIN events_state es FORCE INDEX FOR JOIN (`PRIMARY`) ON (e.state_id = es.id)
    LEFT JOIN events_group eg ON (e.group_id = eg.id)
    LEFT JOIN events_priority_send_types epst FORCE INDEX FOR JOIN (`priority_id`) ON (e.priority_id = epst.priority_id AND e.aid = epst.aid)
    $WHERE
    GROUP BY e.id
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;",
    undef,
    {
      COLS_NAME => 1,
      %{ $attr ? $attr : {} }
    }
  );
  
  my $list = $self->{list};
  $self->query(
    "SELECT COUNT(*) AS total
    FROM events e
    LEFT JOIN events_privacy epriv FORCE INDEX FOR JOIN (`PRIMARY`) ON (e.privacy_id = epriv.id)
    LEFT JOIN events_priority eprio FORCE INDEX FOR JOIN (`PRIMARY`) ON (e.priority_id = eprio.id)
    LEFT JOIN events_state es FORCE INDEX FOR JOIN (`PRIMARY`) ON (e.state_id = es.id)
    LEFT JOIN events_group eg ON (e.group_id = eg.id)
    LEFT JOIN events_priority_send_types epst FORCE INDEX FOR JOIN (`priority_id`) ON (e.priority_id = epst.priority_id AND e.aid = epst.aid)
    $WHERE;",
    undef,
    { INFO => 1 }
  );
  
  return [] if ( $self->{errno} );
  
  return $list;
}

#**********************************************************
=head2 state_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut
#**********************************************************
sub state_list {
  my $self = shift;
  my ($attr) = @_;
  
  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 'id';
  my $DESC = ($attr->{DESC}) ? 'DESC' : '';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;
  
  my $search_columns = [ [ 'ID', 'INT', 'id', 1 ], [ 'NAME', 'STR', 'name', 1 ] ];
  
  if ( $attr->{SHOW_ALL_COLUMNS} ) {
    map {$attr->{ $_->[0] } = '_SHOW' unless ( exists $attr->{ $_->[0] } )} @{$search_columns};
  }
  
  my $WHERE = $self->search_former($attr, $search_columns, { WHERE => 1 });
  
  $self->query(
    "SELECT $self->{SEARCH_FIELDS} id FROM events_state $WHERE ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    {
      COLS_NAME => 1,
      %{ $attr ? $attr : {} }
    }
  );
  
  return [] if ( $self->{errno} );
  
  return $self->{list};
}

#**********************************************************
=head2 privacy_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut
#**********************************************************
sub privacy_list {
  my $self = shift;
  my ($attr) = @_;
  
  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 'id';
  my $DESC = ($attr->{DESC}) ? 'DESC' : '';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;
  
  my $search_columns = [ [ 'ID', 'INT', 'id', 1 ], [ 'NAME', 'STR', 'name', 1 ], [ 'VALUE', 'STR', 'value', 1 ], ];
  
  if ( $attr->{SHOW_ALL_COLUMNS} ) {
    map {$attr->{ $_->[0] } = '_SHOW' unless ( exists $attr->{ $_->[0] } )} @{$search_columns};
  }
  
  my $WHERE = $self->search_former($attr, $search_columns, { WHERE => 1 });
  
  $self->query(
    "SELECT $self->{SEARCH_FIELDS} id FROM events_privacy $WHERE ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    {
      COLS_NAME => 1,
      %{ $attr ? $attr : {} }
    }
  );
  
  return $self->{list} || [];
}

#**********************************************************
=head2 priority_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut
#**********************************************************
sub priority_list {
  my $self = shift;
  my ($attr) = @_;
  
  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 'id';
  my $DESC = ($attr->{DESC}) ? 'DESC' : '';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;
  
  my $search_columns = [
    [ 'ID', 'INT', 'id', 1 ],
    [ 'NAME', 'STR', 'name', 1 ],
    [ 'VALUE', 'STR', 'value', 1 ]
  ];
  
  if ( $attr->{SHOW_ALL_COLUMNS} ) {
    map {$attr->{ $_->[0] } = '_SHOW' unless ( exists $attr->{ $_->[0] } )} @{$search_columns};
  }
  
  my $WHERE = $self->search_former($attr, $search_columns, { WHERE => 1 });
  
  $self->query(
    "SELECT $self->{SEARCH_FIELDS} id FROM events_priority $WHERE ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    {
      COLS_NAME => 1,
      %{ $attr ? $attr : {} }
    }
  );
  
  return $self->{list} || [];
}

#**********************************************************
=head2 priority_send_types_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut
#**********************************************************
sub priority_send_types_list {
  my ($self, $attr) = @_;
  
  my $SORT = $attr->{SORT} || 'priority_id';
  my $DESC = ($attr->{DESC}) ? '' : 'DESC';
  my $PG = $attr->{PG} || '0';
  my $PAGE_ROWS = $attr->{PAGE_ROWS} || 25;
  
  my $search_columns = [
    [ 'AID', 'INT', 'aid', 1 ],
    [ 'PRIORITY_ID', 'STR', 'priority_id', 1 ],
    [ 'SEND_TYPES', 'STR', 'send_types', 1 ],
  ];
  if ( $attr->{SHOW_ALL_COLUMNS} ) {
    map {$attr->{$_->[0]} = '_SHOW' unless ( exists $attr->{$_->[0]} )} @{$search_columns};
  }
  my $WHERE = $self->search_former($attr, $search_columns, { WHERE => 1 });
  
  $self->query("SELECT $self->{SEARCH_FIELDS} priority_id
   FROM events_priority_send_types
   $WHERE ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;", undef, {
      COLS_NAME => 1,
      %{ $attr ? $attr : {}} }
  );
  
  return $self->{list} || [];
}

#**********************************************************
=head2 group_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut
#**********************************************************
sub group_list {
  my $self = shift;
  my ($attr) = @_;
  
  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 'id';
  my $DESC = ($attr->{DESC}) ? 'DESC' : '';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;
  
  my $search_columns = [
    [ 'ID',      'INT', 'id', 1 ],
    [ 'NAME',    'STR', 'name', 1 ],
    [ 'MODULES', 'STR', 'modules', 1 ],
  ];
  
  if ( $attr->{SHOW_ALL_COLUMNS} ) {
    map {$attr->{ $_->[0] } = '_SHOW' unless ( exists $attr->{ $_->[0] } )} @{$search_columns};
  }
  
  my $WHERE = $self->search_former($attr, $search_columns, { WHERE => 1 });
  
  $self->query(
    "SELECT $self->{SEARCH_FIELDS} id FROM events_group $WHERE ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    {
      COLS_NAME  => 1,
      COLS_UPPER => 1,
      %{ $attr ? $attr : {} }
    }
  );
  
  return $self->{list} || [];
}

#**********************************************************
=head2 admin_group_list($attr)

  Arguments:
    $attr - hash_ref
      CONCAT - perform GROUP_CONCAT and return all values as string
  Returns:
    list
    string when $attr->{CONCAT} is true

=cut
#**********************************************************
sub admin_group_list {
  my ($self, $attr) = @_;
  
  my $SORT = $attr->{SORT} || 'id';
  my $DESC = ($attr->{DESC}) ? '' : 'DESC';
  my $PG = $attr->{PG} || '0';
  my $PAGE_ROWS = $attr->{PAGE_ROWS} || 25;
  
  my $search_columns = [
    [ 'AID', 'INT', 'aid', 1 ],
    [ 'GROUP_ID', 'INT', 'group_id', 1 ],
    [ 'CONCAT', 'STR', 'CONCAT(`group_id`) AS group_id' ]
  ];
  
  if ( $attr->{CONCAT} ) {
    my $lc_concat = lc $attr->{CONCAT};
    push (@{$search_columns},
      [ 'CONCAT', 'STR', "GROUP_CONCAT(`$lc_concat`) AS $lc_concat" ]
    );
  }
  
  if ( $attr->{SHOW_ALL_COLUMNS} ) {
    map {$attr->{$_->[0]} = '_SHOW' unless ( exists $attr->{$_->[0]} )} @{$search_columns};
  }
  my $WHERE = $self->search_former($attr, $search_columns, { WHERE => 1 });
  
  $self->query("SELECT $self->{SEARCH_FIELDS} aid
   FROM events_admin_group
   $WHERE ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;", undef, {
      COLS_NAME => 1,
      %{ $attr // {}} }
  );
  
  return $self->{list} || [];
}

#**********************************************************
=head2 admin_group_add($data, $attr)

  Arguments:
     $data - hash_ref
       AID
       GROUP_ID - may be comma separated string
     $attr - hash_ref
       REPLACE - boolean
       
  Returns:
    1
    
=cut
#**********************************************************
sub admin_group_add {
  my ($self, $data, $attr ) = @_;
  
  return unless ($data->{AID} && defined $data->{GROUP_ID});
  
  my @groups = split(',\s?', $data->{GROUP_ID});
  
  if ($attr->{REPLACE}){
    $self->query_del('events_admin_group', undef, { AID => $data->{AID} });
  }
  
  $self->query(
    "INSERT INTO `events_admin_group` (`aid`, `group_id`)
     VALUES (?, ?);",
    undef,
    { MULTI_QUERY => [ map { [ $data->{AID}, $_ ] } @groups ] }
  );
  
  return 1;
}

#**********************************************************
=head2 admins_for_group($group_id) - get all admin_aids for group

  Arguments:
    $group_id -
    
  Returns:
    wantarray ? @$list : string
    0 on error
    
=cut
#**********************************************************
sub admins_for_group {
  my ($self, $group_id) = @_;
  
  return 0 if ( !$group_id );
  
  $self->query(
    "SELECT GROUP_CONCAT(`group_id` SEPARATOR ', ')
     FROM `events_admin_group`
     WHERE group_id=?",
    undef, { Bind => [ $group_id ] });
  
  if ( $self->{list} && ref $self->{list} eq 'ARRAY' && scalar(@{$self->{list}}) ) {
    return wantarray ? split(',', $self->{list}->[0]->[0] || '') : $self->{list}->[0]->[0];
  }
  
  return 0;
}

#**********************************************************
=head2 groups_for_admin($aid) - get all groups for admin

  Arguments:
    $aid -
    
  Returns:
    wantarray ? @$list : string
    0 on error
    
=cut
#**********************************************************
sub groups_for_admin {
  my ($self, $aid) = @_;
  
  return 0 if ( !$aid );
  
  $self->query(
    "SELECT GROUP_CONCAT(`group_id` SEPARATOR ', ')
     FROM `events_admin_group`
     WHERE aid=?",
    undef, { Bind => [ $aid ] });
  
  if ( $self->{list} && ref $self->{list} eq 'ARRAY' && scalar(@{$self->{list}}) ) {
    return wantarray ? split(',', $self->{list}->[0]->[0] || '') : $self->{list}->[0]->[0];
  }
  
  return 0;
}


#**********************************************************
=head2 admins_subscribed_to_module_list($module, $attr) - returns list of admins subscribed to groups for module

  Arguments:
    $module - name of module
    
  Returns:
    list
    
=cut
#**********************************************************
sub admins_subscribed_to_module_list {
  my ($self, $module) = @_;
  
  return 0 unless $module;
  
  $self->query("SELECT GROUP_CONCAT(DISTINCT `aid` SEPARATOR ', ')
    FROM `events_group` `eg` LEFT JOIN `events_admin_group` `eag` ON (`eg`.`id` = `eag`.`group_id`)
    WHERE eg.modules LIKE ?;",
    undef,
    { Bind => [ "%$module%" ] }
  );
  
  if ( $self->{list} && ref $self->{list} eq 'ARRAY' && scalar(@{$self->{list}}) ) {
    return wantarray ? split(', ', $self->{list}->[0]->[0] || '') : $self->{list}->[0]->[0];
  }
  
  return 0;
}

#**********************************************************
=head2 get_group_for_module($module) -

  Arguments:
    $modules - name of module (Events|Equipment)
    
  Returns:
    group_id
    
=cut
#**********************************************************
sub get_group_for_module {
  my ($self, $module) = @_;
  
  return 1 unless $module; # 1 is BASE
  
  my $groups_list = $self->group_list({
    MODULES    => "*$module*",
    PAGE_ROWS => 1,
    COLS_NAME => 1,
    COLS_UPPER => 0,
  });

  if ( $groups_list && ref $groups_list eq 'ARRAY' && scalar(@{$groups_list}) ) {
    return $groups_list->[0]->{id};
  }
  
  # Here 1 stays for BASE group
  return 1;
}

#**********************************************************
=head2 log_rotate($attr) - Rotate events logs

  Arguments:
    $attr
      MONTHLY

=cut
#**********************************************************
sub log_rotate{
  my $self = shift;
  my ($attr) = @_;

  my @rq = ();

  if($conf{USE_PARTITIONING}) {
    return $self;
  }

  push @rq, 'CREATE TABLE IF NOT EXISTS events_new LIKE events;',
      'RENAME TABLE events TO events_old, events_new TO events;',
      "INSERT INTO events SELECT * FROM events_old WHERE created>=(NOW() - INTERVAL 31 DAY) ORDER BY 1;",
      'DROP TABLE events_old;',
  ;

  foreach my $query (@rq) {
    $self->query($query, 'do');
  }

  return $self;
}


sub DESTROY{};

1;
