package Hotspot;

use strict;
use warnings FATAL => 'all';
use parent 'dbcore';
use POSIX;

#**********************************************************
=head2 new($db, $admin, \%conf) - constructor for Hotspot DB object

=cut
#**********************************************************
sub new {
  my $class = shift;

  my ($db, $admin, $CONF) = @_;

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $CONF,
  };

  bless( $self, $class );

  return $self;
}

#**********************************************************
=head2 visits_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut
#**********************************************************
sub visits_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 'id';
  my $DESC = ($attr->{DESC}) ? '' : 'DESC';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;
  
  my $search_columns = [
    [ 'ID',               'STR',    'hv.id'                          ,1 ],
    [ 'FIRST_SEEN',       'DATE',   'hv.first_seen'                  ,1 ],
    [ 'BROWSER_NAME',     'STR',    'hb.name AS browser_name'        ,1 ],
    [ 'COUNTRY',          'STR',    'hv.country'                     ,1 ],
    [ 'LANGUAGE',         'STR',    'hv.language'                    ,1 ],
    [ 'OS_NAME',          'STR',    'ho.name AS os_name'             ,1 ],
    [ 'OS_VERSION',       'INT',    'ho.version AS os_version'       ,1 ],
    [ 'BROWSER_VERSION',  'INT',    'hb.version as browser_version'  ,1 ],
    [ 'MOBILE',           'INT',    'ho.mobile'                      ,1 ],
    [ 'BROWSER_ID',       'INT',    'hv.browser_id'                  ,1 ],
    [ 'OS_ID',            'INT',    'hv.os_id'                       ,1 ],
  ];

  my $WHERE = '';

  if ( $attr->{SHOW_ALL_COLUMNS} ) {
    foreach my $search_column ( @$search_columns ) {
      my $name = $search_column->[0];
      $attr->{$name} = '_SHOW' if (!exists $attr->{$name});
    }
  }

  $WHERE = $self->search_former( $attr, $search_columns,
    {
      WHERE => 1
    }
  );

  $self->query(
    "SELECT $self->{SEARCH_FIELDS} hv.id
    FROM hotspot_visits hv
    LEFT JOIN hotspot_oses ho ON (hv.os_id = ho.id)
    LEFT JOIN hotspot_browsers hb ON (hv.browser_id = hb.id)
    $WHERE ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;", undef,
    {
      COLS_NAME  => 1,
      %{ $attr ? $attr : { } }
    }
  );

  return [] if $self->{errno};

  return $self->{list};
}

#**********************************************************
=head2 visits_count() - quick count

  Returns:
    Count of elements in table

=cut
#**********************************************************
sub visits_count  {
  my $self = shift;

  $self->query("SELECT COUNT(*)FROM hotspot_visits");

  return -1 if $self->{errno};

  return $self->{list}->[0];
}


#**********************************************************
=head2 visits_info($id)

  Arguments:
    $id - id for hotspot_visits

  Returns:
    hash_ref

=cut
#**********************************************************
sub visits_info {
  my $self = shift;
  my ($id) = @_;

  my $list = $self->visits_list( { COLS_NAME => 1, ID => $id, SHOW_ALL_COLUMNS => 1, COLS_UPPER => 1 } );

  return $list->[0] || {};
}

#**********************************************************
=head2 visits_add($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    1

=cut
#**********************************************************
sub visits_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add( 'hotspot_visits', $attr, { REPLACE => 1 } );

  return 1;
}

#**********************************************************
=head2 visits_del($attr)

  Arguments:
    $attr - hash_ref

  Returns:
   1

=cut
#**********************************************************
sub visits_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del( 'hotspot_visits', $attr );

  return 1;
}

#**********************************************************
=head2 visits_change($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    1

=cut
#**********************************************************
sub visits_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'hotspot_visits',
      DATA         => $attr,
    } );

  return 1;
}


#**********************************************************
=head2 logins_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut
#**********************************************************
sub logins_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 'hl.id';
  my $DESC = ($attr->{DESC}) ? '' : 'DESC';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $WHERE = '';

  # TODO : user_btn from UID column

  my $search_columns = [
    [ 'ID', 'INT', 'hl.id', 1 ],
    [ 'UID', 'INT', 'hl.uid', 1 ],
    [ 'VISIT_ID', 'STR', 'hl.visit_id', 1 ],
    [ 'LOGIN_TIME', 'DATE', 'hl.login_time', 1 ],
    [ 'FIRST_SEEN', 'DATE', 'hv.first_seen', 1 ],
    [ 'SESSION_ID', 'STR', 'hv.id', 1 ],
    [ 'BROWSER_NAME', 'STR', 'IF(hb.name IS NOT NULL, hb.name, "") AS browser_name', 1 ],
  ];

  if ( $attr->{SHOW_ALL_COLUMNS} ) {
    foreach my $search_column ( @$search_columns ) {
      my $name = $search_column->[0];
      $attr->{$name} = '_SHOW' if (!exists $attr->{$name});
    }
  }

  $WHERE = $self->search_former( $attr, $search_columns,
    {
      WHERE => 1
    }
  );

  $self->query(
    "SELECT $self->{SEARCH_FIELDS} hv.id
     FROM hotspot_logins hl
     LEFT JOIN hotspot_visits hv ON (hl.visit_id = hv.id)
     LEFT JOIN hotspot_oses ho ON (hv.os_id = ho.id)
     LEFT JOIN hotspot_browsers hb ON (hv.browser_id = hb.id)
      $WHERE ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;", undef,
  {
    COLS_NAME => 1,
    COLS_UPPER => 1,
    %{ $attr ? $attr : {}}}
  );

  return [] if $self->{errno};

  return $self->{list};
}

#**********************************************************
=head2 logins_info($id)

  Arguments:
    $id - id for logins

  Returns:
    hash_ref

=cut
#**********************************************************
sub logins_info {
  my $self = shift;
  my ($id) = @_;

  my $list = $self->logins_list( { COLS_NAME => 1, ID => $id, SHOW_ALL_COLUMNS => 1, COLS_UPPER => 1 } );

  return $list->[0] || {};
}

#**********************************************************
=head2 logins_info_for_session($session_id) - Searches login by visit id

  Arguments:
    $session_id - session_id for logins as specified in hotspot_visits

  Returns:
    hash_ref

=cut
#**********************************************************
sub logins_info_for_session {
  my $self = shift;
  my ($session_id) = @_;

  my $list = $self->logins_list( { COLS_NAME => 1, VISIT_ID => $session_id, SHOW_ALL_COLUMNS => 1 } );

  return $list->[0] || {};
}

#**********************************************************
=head2 logins_add($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    1

=cut
#**********************************************************
sub logins_add {
  my $self = shift;
  my ($attr) = @_;
  
  $self->query_add( 'hotspot_logins', $attr, { REPLACE => 1 } );
  
  return 1;
}

#**********************************************************
=head2 logins_del($attr)

  Arguments:
    $attr - hash_ref

  Returns:
   1

=cut
#**********************************************************
sub logins_del {
  my $self = shift;
  my ($attr) = @_;
  
  $self->query_del( 'hotspot_logins', $attr );
  
  return 1;
}

#**********************************************************
=head2 logins_change($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    1

=cut
#**********************************************************
sub logins_change {
  my $self = shift;
  my ($attr) = @_;
  
  $self->changes( {
      CHANGE_PARAM => 'ID',
      TABLE        => 'hotspot_logins',
      DATA         => $attr,
    } );
  
  return 1;
}

#**********************************************************
=head2 user_agents_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut
#**********************************************************
sub user_agents_list{
  my $self = shift;
  my ($attr) = @_;
  
  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 'id';
  my $DESC = ($attr->{DESC}) ? '' : 'DESC';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;
  

  my $search_columns = [
    ['ID',             'INT',         'id'   ,1 ],
    ['USER_AGENT',     'STR',         'user_agent' ,1 ],
    
  ];

  if ($attr->{SHOW_ALL_COLUMNS}){
    map { $attr->{$_->[0]} = '_SHOW' unless exists $attr->{$_->[0]} } @$search_columns;
  }

  my $WHERE =  $self->search_former($attr, $search_columns,
    {
      WHERE => 1
    }
  );
  
  $self->query( "SELECT $self->{SEARCH_FIELDS} id FROM hotspot_user_agents $WHERE ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;", undef, {
    COLS_NAME => 1,
    %{ $attr ? $attr : {}}}
  );

  return [] if $self->{errno};

  
  return $self->{list};
}

#**********************************************************
=head2 user_agents_add($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    1

=cut
#**********************************************************
sub user_agents_add{
  my $self = shift;
  my ($attr) = @_;
  
  $self->query_add('hotspot_user_agents', $attr);
  
  return 1;
}

#**********************************************************
=head2 user_agents_del($attr)

  Arguments:
    $attr - hash_ref

  Returns:
   1

=cut
#**********************************************************
sub user_agents_del{
  my $self = shift;
  my ($attr) = @_;
  
  $self->query_del('hotspot_user_agents', $attr);
  
  return 1;
}

#**********************************************************
=head2 oses_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut
#**********************************************************
sub oses_list{
  my $self = shift;
  my ($attr) = @_;
  
  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 'id';
  my $DESC = ($attr->{DESC}) ? '' : 'DESC';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;
  

  my $search_columns = [
    ['ID',             'INT',      'id'        ,1 ],
    ['NAME',           'STR',      'name'      ,1 ],
    ['VERSION',        'INT',      'version'   ,1 ],
    ['MOBILE',         'INT',      'mobile'    ,1 ],
  ];

  if ($attr->{SHOW_ALL_COLUMNS}){
    map { $attr->{$_->[0]} = '_SHOW' unless exists $attr->{$_->[0]} } @$search_columns;
  }

  my $WHERE =  $self->search_former($attr, $search_columns,
    {
      WHERE => 1
    }
  );
  
  $self->query( "SELECT $self->{SEARCH_FIELDS} id FROM hotspot_oses $WHERE ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;", undef, {
    COLS_NAME => 1,
    COLS_UPPER => 1,
    %{ $attr ? $attr : {}}}
  );

  return [] if $self->{errno};

  
  return $self->{list};
}

#**********************************************************
=head2 oses_info($id)

  Arguments:
    $id - id for oses

  Returns:
    hash_ref

=cut
#**********************************************************
sub oses_info{
  my $self = shift;
  my ($id) = @_;
  
  my $list = $self->oses_list( { COLS_NAME => 1, ID => $id, SHOW_ALL_COLUMNS => 1, COLS_UPPER => 1 } );
  
  return $list->[0] || {};
}

#**********************************************************
=head2 oses_add($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    1

=cut
#**********************************************************
sub oses_add{
  my $self = shift;
  my ($attr) = @_;
  
  $self->query_add('hotspot_oses', $attr);
  
  return 1;
}

#**********************************************************
=head2 oses_del($attr)

  Arguments:
    $attr - hash_ref

  Returns:
   1

=cut
#**********************************************************
sub oses_del{
  my $self = shift;
  my ($attr) = @_;
  
  $self->query_del('hotspot_oses', $attr);
  
  return 1;
}

#**********************************************************
=head2 oses_change($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    1

=cut
#**********************************************************
sub oses_change{
  my $self = shift;
  my ($attr) = @_;
  
  $self->changes({
      CHANGE_PARAM => 'ID',
      TABLE        => 'hotspot_oses',
      DATA         => $attr,
    });
  
  return 1;
}

#**********************************************************
=head2 browsers_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut
#**********************************************************
sub browsers_list{
  my $self = shift;
  my ($attr) = @_;
  
  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 'id';
  my $DESC = ($attr->{DESC}) ? '' : 'DESC';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;
  

  my $search_columns = [
    ['ID',             'INT',        'id'                           ,1 ],
    ['NAME',           'STR',        'name'                         ,1 ],
    ['VERSION',        'INT',        'version'                      ,1 ],
  ];

  if ($attr->{SHOW_ALL_COLUMNS}){
    map { $attr->{$_->[0]} = '_SHOW' unless exists $attr->{$_->[0]} } @$search_columns;
  }

  my $WHERE =  $self->search_former($attr, $search_columns,
    {
      WHERE => 1
    }
  );
  
  $self->query( "SELECT $self->{SEARCH_FIELDS} id FROM hotspot_browsers $WHERE ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;", undef, {
    COLS_NAME => 1,
    COLS_UPPER => 1,
    %{ $attr ? $attr : {}}}
  );

  return [] if $self->{errno};

  
  return $self->{list};
}

#**********************************************************
=head2 browsers_info($id)

  Arguments:
    $id - id for browsers

  Returns:
    hash_ref

=cut
#**********************************************************
sub browsers_info{
  my $self = shift;
  my ($id) = @_;
  
  my $list = $self->browsers_list( { COLS_NAME => 1, ID => $id, SHOW_ALL_COLUMNS => 1, COLS_UPPER => 1 } );
  
  return $list->[0] || {};
}

#**********************************************************
=head2 browsers_add($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    1

=cut
#**********************************************************
sub browsers_add{
  my $self = shift;
  my ($attr) = @_;
  
  $self->query_add('hotspot_browsers', $attr);
  
  return 1;
}

#**********************************************************
=head2 browsers_del($attr)

  Arguments:
    $attr - hash_ref

  Returns:
   1

=cut
#**********************************************************
sub browsers_del{
  my $self = shift;
  my ($attr) = @_;
  
  $self->query_del('hotspot_browsers', $attr);
  
  return 1;
}

#**********************************************************
=head2 browsers_change($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    1

=cut
#**********************************************************
sub browsers_change{
  my $self = shift;
  my ($attr) = @_;
  
  $self->changes({
      CHANGE_PARAM => 'ID',
      TABLE        => 'hotspot_browsers',
      DATA         => $attr,
    });
  
  return 1;
}



#**********************************************************
=head2 adverts_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut
#**********************************************************
sub adverts_list{
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 'ad.id';
  my $DESC = ($attr->{DESC}) ? '' : 'DESC';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $search_columns = [
    ['ID',                'INT',         'ad.id'                        ,1 ],
    ['NAME',              'STR',         'ad.name'                      ,1 ],
    ['URL',               'STR',         'ad.url'                       ,1 ],
    ['PRICE_PER_SHOW',    'INT',         'ad.price_per_show'            ,1 ],
    ['PRICE_PER_PERIOD',  'INT',         'ad.price_per_period'          ,1 ],
    ['PERIOD',            'STR',         'ad.period'                    ,1 ],
    ['NAS_ID',            'INT',         'n.id AS nas_id'               ,1 ],
    ['NAS_NAME',          'STR',         'n.name AS nas_name'           ,1 ],
    ['COMMENTS',          'STR',         'ad.comments'                  ,1 ],
    ['SHOWS_COUNT',       'INT',         'COUNT(*) AS shows_count'      ,1 ],
    ['SHOWED',            'DATE',         'ads.showed'                      ],
  ];

  if ($attr->{SHOW_ALL_COLUMNS}){
    map { $attr->{$_->[0]} = '_SHOW' unless exists $attr->{$_->[0]} } @$search_columns;
  }

  my $WHERE =  $self->search_former($attr, $search_columns,
    {
      WHERE => 1
    }
  );

  $self->query( "SELECT $self->{SEARCH_FIELDS} ad.id
   FROM hotspot_adverts ad
    LEFT JOIN nas n ON (ad.nas_id = n.id)
    LEFT JOIN hotspot_advert_shows ads ON (ad.id = ads.ad_id)
    $WHERE
     GROUP BY ad.id ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;", undef,
    {
    COLS_NAME => 1,
    COLS_UPPER => 1,
    %{ $attr ? $attr : {}}}
  );

  return [] if $self->{errno};


  return $self->{list};
}

#**********************************************************
=head2 adverts_info($id)

  Arguments:
    $id - id for adverts

  Returns:
    hash_ref

=cut
#**********************************************************
sub adverts_info{
  my $self = shift;
  my ($id) = @_;

  my $list = $self->adverts_list( { COLS_NAME => 1, ID => $id, SHOW_ALL_COLUMNS => 1, COLS_UPPER => 1 } );

  return $list->[0] || {};
}

#**********************************************************
=head2 adverts_add($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    1

=cut
#**********************************************************
sub adverts_add{
  my $self = shift;
  my ($attr) = @_;

  $attr->{NAS_ID} = '0' if !$attr->{NAS_ID};

  $self->query_add('hotspot_adverts', $attr);

  return 1;
}

#**********************************************************
=head2 adverts_del($attr)

  Arguments:
    $attr - hash_ref

  Returns:
   1

=cut
#**********************************************************
sub adverts_del{
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('hotspot_adverts', $attr);

  return 1;
}

#**********************************************************
=head2 adverts_change($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    1

=cut
#**********************************************************
sub adverts_change{
  my $self = shift;
  my ($attr) = @_;

  $self->changes({
      CHANGE_PARAM => 'ID',
      TABLE        => 'hotspot_adverts',
      DATA         => $attr,
    });

  return 1;
}

#**********************************************************
=head2 advert_shows_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut
#**********************************************************
sub advert_shows_list{
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 'id';
  my $DESC = ($attr->{DESC}) ? '' : 'DESC';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;


  my $search_columns = [
    ['ID',             'INT',        'id'     ,1 ],
    ['ADVERT_ID',      'INT',        'ad_id'  ,1 ],
    ['SHOWED',         'STR',        'showed' ,1 ],
  ];

  if ($attr->{SHOW_ALL_COLUMNS}){
    map { $attr->{$_->[0]} = '_SHOW' unless exists $attr->{$_->[0]} } @$search_columns;
  }

  my $WHERE =  $self->search_former($attr, $search_columns,
    {
      WHERE => 1
    }
  );

  $self->query( "SELECT $self->{SEARCH_FIELDS} id FROM hotspot_advert_shows $WHERE ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;", undef, {
    COLS_NAME => 1,
    COLS_UPPER => 1,
    %{ $attr ? $attr : {}}}
  );

  return [] if $self->{errno};


  return $self->{list};
}

#**********************************************************
=head2 advert_shows_info($id)

  Arguments:
    $id - id for advert_shows

  Returns:
    hash_ref

=cut
#**********************************************************
sub advert_shows_info{
  my $self = shift;
  my ($id) = @_;

  my $list = $self->advert_shows_list( { COLS_NAME => 1, ID => $id, SHOW_ALL_COLUMNS => 1, COLS_UPPER => 1 } );

  return $list->[0] || {};
}

#**********************************************************
=head2 advert_shows_add($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    1

=cut
#**********************************************************
sub advert_shows_add{
  my $self = shift;
  my ($attr) = @_;

  if (! $attr->{SHOWED}){
    $attr->{SHOWED} = 'NOW()';
  }

  $self->query_add('hotspot_advert_shows', $attr);

  return 1;
}

#**********************************************************
=head2 advert_shows_del($attr)

  Arguments:
    $attr - hash_ref

  Returns:
   1

=cut
#**********************************************************
sub advert_shows_del{
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('hotspot_advert_shows', $attr);

  return 1;
}

#**********************************************************
=head2 advert_shows_change($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    1

=cut
#**********************************************************
sub advert_shows_change{
  my $self = shift;
  my ($attr) = @_;

  $self->changes({
      CHANGE_PARAM => 'ID',
      TABLE        => 'hotspot_advert_shows',
      DATA         => $attr,
    });

  return 1;
}

#**********************************************************
=head2 advert_shows_count($id, $attr) - get count of advert shows

  Arguments:
    $id -

  Returns:
    number - count of shows

=cut
#**********************************************************
sub advert_shows_count {
  my $self = shift;
  my ($attr) =  @_;

  my $search_columns = [
    ['ID',             'INT',        'id'     ,1 ],
    ['ADVERT_ID',      'INT',        'ad_id'  ,1 ],
    ['SHOWED',         'STR',        'showed' ,1 ],
  ];

  my $WHERE =  $self->search_former($attr, $search_columns,
    {
      WHERE => 1
    }
  );

  $self->query("SELECT COUNT(*) AS TOTAL FROM hotspot_advert_shows $WHERE GROUP by id", undef, {
    COLS_NAME => 1,
    %{ $attr ? $attr : {} }
  });

  return -1 if $self->{errno};

  return $self->{list}->[0]->{TOTAL};
}

#**********************************************************
=head2 request_random_ad($attr) - returns random ad url

  Returns:
    string - url

=cut
#**********************************************************
sub request_random_ad {
  my $self = shift;
  my ($attr) = @_;

  $self->query("SELECT id, url FROM hotspot_adverts ORDER BY RAND() LIMIT 1", undef, $attr);

  if ($self->{errno} || $self->{TOTAL} < 1){
    return '';
  };

  return $self->{list}->[0];
}


#**********************************************************
=head2 log_list($attr) - Hotspot log list

=cut
#**********************************************************
sub log_list {
  my $self   = shift;
  my ($attr) = @_;

  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 'date';
  my $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : 'DESC';
  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  $self->{EXT_TABLES}     = '';
  $self->{SEARCH_FIELDS}  = '';
  $self->{SEARCH_FIELDS_COUNT} = 0;

  if ($attr->{INTERVAL}) {
    ($attr->{FROM_DATE}, $attr->{TO_DATE}) = split(/\//, $attr->{INTERVAL}, 2);
  }

  my $WHERE =  $self->search_former($attr, [
      ['DATE',           'DATE',        'date',                1 ],
      ['CID',            'STR',         'CID',                 1 ],
      ['PHONE',          'STR',         'phone',               1 ],
      ['ACTION',         'STR',         'action',              1 ],
      ['HOTSPOT',        'STR',         'hotspot',             1 ],
      ['COMMENTS',       'STR',         'comments',            1 ],
      ['FROM_DATE|TO_DATE','DATE',"DATE_FORMAT(date, '%Y-%m-%d')"],
      ['ID',             'INT',         'id'                     ],
    ],
    { WHERE => 1 }
  );

  $self->query("SELECT 
      $self->{SEARCH_FIELDS}
      date,
      id
      FROM hotspot_log
      $WHERE
      ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  return [] if ($self->{errno});

  my $list = $self->{list};

  if ($self->{TOTAL} >= 0 && !$attr->{SKIP_TOTAL}) {
    $self->query("SELECT count( DISTINCT id) AS total FROM hotspot_log
    $WHERE",
      undef,
      { INFO => 1 }
    );
  }

  return $list;
}

#**********************************************************
=head2 log_add($attr)

  Arguments:
    $attr
    $attr

=cut
#**********************************************************
sub log_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add( 'hotspot_log', $attr );

  return 1;
}

#**********************************************************
=head2 advert_pages_list($attr) - Hotspot advert pages

=cut
#**********************************************************
sub advert_pages_list {
  my $self   = shift;
  my ($attr) = @_;

  my $WHERE =  $self->search_former($attr, [
      ['HOSTNAME',       'STR',         'hostname',            1 ],
      ['PAGE',           'STR',         'page',                1 ],
      ['ACTION',         'INT',         'action',              1 ],
      ['ID',             'INT',         'id'                     ],
    ],
    { WHERE => 1 }
  );

  $self->query("SELECT 
      $self->{SEARCH_FIELDS}
      id
      FROM hotspot_advert_pages
      $WHERE;",
    undef,
    $attr
  );

  return [] if ($self->{errno});

  return $self->{list};
}

#**********************************************************
=head2 advert_pages_add($attr)

=cut
#**********************************************************
sub advert_pages_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add( 'hotspot_advert_pages', $attr );

  return 1;
}

#**********************************************************
=head2 advert_pages_change($attr)

=cut
#**********************************************************
sub advert_pages_change{
  my $self = shift;
  my ($attr) = @_;

  $self->changes({
      CHANGE_PARAM => 'ID',
      TABLE        => 'hotspot_advert_pages',
      DATA         => $attr,
    });

  return 1;
}

#**********************************************************
=head2 advert_pages_del($attr)

=cut
#**********************************************************
sub advert_pages_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del( 'hotspot_advert_pages', $attr );

  return 1;
}

#**********************************************************
=head2 load_conf($hotspot_name)

=cut
#**********************************************************
sub load_conf {
  my $self = shift;
  my ($hotspot_name) = @_;

  $self->query("SELECT action, page
      FROM hotspot_advert_pages
      WHERE hostname = ?;",
    undef,
    { Bind => [ $hotspot_name ], COLS_NAME => 1 }
  );
  
  foreach my $line (@{$self->{list}}) {
    $self->{HOTSPOT_CONF}->{$line->{action}} = $line->{page};
  }
  
  return 1;
}

#**********************************************************
=head2 next_login

=cut
#**********************************************************
sub next_login {
  my $self = shift;
  my ($attr) = @_;

  my $login_regexp = '^' . $attr->{LOGIN_PREFIX} . '[0-9]{' . $attr->{LOGIN_LENGTH} . '}$';

  $self->query("SELECT id
      FROM users
      WHERE id REGEXP '$login_regexp'
      AND domain_id = ?
      ORDER BY id DESC
      LIMIT 1;",
    undef,
    { Bind => [ $attr->{DOMAIN_ID} ], COLS_NAME => 1 }
  );

  my $last_login = 0;

  if ($self->{list}) {
    $last_login = substr($self->{list}[0]{id}, -$attr->{LOGIN_LENGTH});
  }

  my $new_login = sprintf("%s%0*d", $attr->{LOGIN_PREFIX}, $attr->{LOGIN_LENGTH}, $last_login + 1);

  return $new_login;
}

#**********************************************************
=head2 change_tp

=cut
#**********************************************************
sub change_tp {
  my $self = shift;
  my ($attr) = @_;
  $self->changes({
    CHANGE_PARAM => 'UID',
    TABLE        => 'internet_main',
    DATA         => $attr
  });

  return 1;
}

1