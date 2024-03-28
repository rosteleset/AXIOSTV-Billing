package Sysinfo;
use strict;
use warnings FATAL => 'all';
use parent qw( dbcore );

=head1 NAME

  Sysinfo

=head2 SYNOPSIS

  DB functions for Sysinfo module

=cut

my %unusual_table_names = ();

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
    require AXbills::Base;
    AXbills::Base->import('_bp');
    AXbills::Base::_bp($table, { data => $data, attr => $attr });
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
    if ( $data->{WHERE} && scalar keys %{$data->{WHERE}} ) {
      $WHERE = 'WHERE ' . join (' AND ',
        map {
          # Push value to Bind array
          push (@WHERE_BIND, $data->{WHERE}->{$_});
          
          # Return binded data as string
          "$_ = ?"
        } keys %{$data->{WHERE}});
    }
    $self->query(qq{
      SELECT * FROM sysinfo_$entity_name $WHERE
    }, undef, { COLS_NAME => 1, Bind => \@WHERE_BIND });
    
    return [] if ( $self->{errno} );
    
    return $self->{list} || [];
  }
  elsif ( $operation eq 'count' || $operation eq 'next' ) {
    my $WHERE = '';
    my $type_id = $data->{TYPE_ID};
    
    if ( $type_id ) {
      $WHERE = qq{WHERE type_id=$type_id};
    }
    
    my $requested = ($operation eq 'count')
      ? 'COUNT(*)'
      : 'MAX(id) + 1';
    
    $self->query(qq{
      SELECT $requested FROM sysinfo_$entity_name $WHERE
    });
    return - 1 if ( $self->{errno} );
    
    return $self->{list}->[0]->[0] || 0;
  }
}

#**********************************************************
=head2 new($db, $admin, $CONF) - constructor for Sysinfo

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
  
  bless($self, $class);
  
  return $self;
}


#**********************************************************
=head2 remote_servers_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut
#**********************************************************
sub remote_servers_list {
  my ($self, $attr) = @_;
  
  my $SORT = $attr->{SORT} || 'id';
  my $DESC = ($attr->{DESC}) ? '' : 'DESC';
  my $PG = $attr->{PG} || '0';
  my $PAGE_ROWS = $attr->{PAGE_ROWS} || 25;
  
  my $search_columns = [
    [ 'ID', 'INT', 'srs.id', 1 ],
    [ 'NAME', 'STR', 'srs.name', 1 ],
    [ 'NAS_ID', 'INT', 'srs.nas_id', 1 ],
    [ 'MNG_HOST_PORT', 'INT', 'n.mng_host_port', 1 ],
    [ 'IP', 'INT', 'INET_NTOA(srs.ip) AS ip', 1 ],
    [ 'IP_INT', 'INT', 'srs.ip AS ip_int', 1 ],
    [ 'PORT', 'INT', 'srs.port', 1 ],
    [ 'SERVICES', 'STR', 'GROUP_CONCAT(DISTINCT sss.name SEPARATOR ", ") AS services', 1 ],
    [ 'SERVICE_IDS', 'STR', 'GROUP_CONCAT(DISTINCT sss.id SEPARATOR ", ") AS service_ids', 1 ],
    
    [ 'COMMENTS', 'STR', 'srs.comments', 1 ],
    [ 'NAT', 'INT', 'srs.nat', 1 ],
    [ 'LOGIN', 'STR', 'n.mng_user', 1 ],
    [ 'PRIVATE_KEY', 'STR', 'srs.private_key' ],
  ];
  if ( $attr->{SHOW_ALL_COLUMNS} ) {
    map {$attr->{$_->[0]} = '_SHOW' unless ( exists $attr->{$_->[0]} )} @{$search_columns};
  }
  my $WHERE = $self->search_former($attr, $search_columns, { WHERE => 1 });
  
  my $EXT_TABLES = '';
  if ( $self->{SEARCH_FIELDS} =~ /n\./ ) {
    $EXT_TABLES .= "LEFT JOIN nas n ON (srs.nas_id = n.id)";
  }
  if ( $self->{SEARCH_FIELDS} =~ /sss\./ ) {
    $EXT_TABLES .= q"
    LEFT JOIN sysinfo_remote_server_services srss ON (srss.server_id = srs.id)
    LEFT JOIN sysinfo_server_services sss ON (srss.service_id = sss.id)";
  }
  
  $self->query("SELECT $self->{SEARCH_FIELDS} srs.id
   FROM sysinfo_remote_servers srs
   $EXT_TABLES
   $WHERE
   GROUP BY srs.id ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS   ;", undef, {
      COLS_NAME => 1,
      %{ $attr // {}} }
  );
  
  return [] if ( $self->{errno} );
  
  return $self->{list};
}

#**********************************************************
=head2 sysinfo_nases_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut
#**********************************************************
sub sysinfo_nases_list {
  my ($self, $attr) = @_;
  
  my $SORT = $attr->{SORT} || 'id';
  my $DESC = ($attr->{DESC}) ? '' : 'DESC';
  my $PG = $attr->{PG} || '0';
  my $PAGE_ROWS = $attr->{PAGE_ROWS} || 25;
  
  my $search_columns = [
    [ 'ID', 'INT', 'id', 1 ],
    [ 'NAME', 'STR', 'name', 1 ],
    [ 'IP', 'STR', 'mng_host_port', 1 ],
    [ 'PORT', 'STR', 'mng_host_port', 1 ],
  ];
  if ( $attr->{SHOW_ALL_COLUMNS} ) {
    map {$attr->{$_->[0]} = '_SHOW' unless ( exists $attr->{$_->[0]} )} @{$search_columns};
  }
  my $WHERE = $self->search_former($attr, $search_columns, { WHERE => 1 });
  
  $self->query("SELECT $self->{SEARCH_FIELDS} id
   FROM nas n
   $WHERE ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;", undef, {
      COLS_NAME => 1,
      %{ $attr // {}} }
  );
  
  return [] if ( $self->{errno} || !$self->{list} );
  
  my $list = $self->{list};
  
  my @normalized_list = map {
    $_->{mng_host_port} && do {
      my ($ip, $coa_port, $ssh_port, $snmp_port) = split (':', $_->{mng_host_port});
      $_->{ip} = $ip || '';
      $_->{ssh_port} = $ssh_port // '22';
      $_->{coa_port} = $coa_port // '1700';
      $_->{snmp_port} = $snmp_port // '161';
    };
    $_;
  } @{$list};
  
  return wantarray ? @normalized_list : \@normalized_list;
}

#**********************************************************
=head2 server_services_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut
#**********************************************************
sub server_services_list {
  my ($self, $attr) = @_;
  
  my $SORT = $attr->{SORT} || 'id';
  my $DESC = ($attr->{DESC}) ? '' : 'DESC';
  my $PG = $attr->{PG} || '0';
  my $PAGE_ROWS = $attr->{PAGE_ROWS} || 25;
  
  my $search_columns = [
    [ 'ID', 'INT', 'sss.id', 1 ],
    [ 'NAME', 'STR', 'sss.name', 1 ],
    [ 'CHECK_COMMAND', 'STR', 'sss.check_command', 1 ],
    [ 'STATUS', 'INT', 'sss.status', 1 ],
    [ 'LAST_UPDATE', 'DATE', 'sss.last_update', 1 ],
    [ 'SERVERS', 'STR', 'GROUP_CONCAT(srs.name) AS servers', 1 ],
    [ 'SERVER_IDS', 'STR', 'GROUP_CONCAT(DISTINCT srs.id SEPARATOR ", ") AS server_ids', 1 ],
    [ 'COMMENTS', 'STR', 'sss.comments', 1 ],
    [ 'SERVER_ID', 'INT', 'srs.id AS server_id', ],
  ];
  if ( $attr->{SHOW_ALL_COLUMNS} ) {
    map {$attr->{$_->[0]} = '_SHOW' unless ( exists $attr->{$_->[0]} )} @{$search_columns};
  }
  my $WHERE = $self->search_former($attr, $search_columns, { WHERE => 1 });
  
  my $EXT_TABLES = '';
  if ( $self->{SEARCH_FIELDS} =~ /srs\./ ) {
    $EXT_TABLES .= q"
    LEFT JOIN sysinfo_remote_server_services srss ON (srss.service_id=sss.id)
    LEFT JOIN sysinfo_remote_servers srs ON (srss.server_id=srs.id)";
  }
  
  $self->query("SELECT $self->{SEARCH_FIELDS} sss.id
   FROM sysinfo_server_services sss
   $EXT_TABLES
   $WHERE
   GROUP BY sss.id
   ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef, {
      COLS_NAME => 1,
      %{ $attr // {}} }
  );
  
  return [] if ( $self->{errno} );
  
  return $self->{list};
}

#**********************************************************
=head2 services_for_server($server_id) -

  Arguments:
    $server_id -
    
  Returns:
  
  
=cut
#**********************************************************
sub services_for_server {
  my ($self, $server_id) = @_;
  
  my $search_columns = [
    [ 'SERVER_ID', 'INT', 'srs.id', 1 ],
  ];
  
  my $WHERE = $self->search_former({ SERVER_ID => $server_id }, $search_columns, { WHERE => 1 });
  
  $self->query("SELECT $self->{SEARCH_FIELDS} sss.id, sss.name, sss.check_command
    FROM sysinfo_remote_servers srs
    LEFT JOIN sysinfo_remote_server_services srss ON (srss.server_id = srs.id)
    LEFT JOIN sysinfo_server_services sss ON (srss.service_id = sss.id)
   $WHERE GROUP BY sss.id", undef, { COLS_NAME => 1 }
  );
  
  return $self->{list} || [];
}

sub DESTROY {};

1;