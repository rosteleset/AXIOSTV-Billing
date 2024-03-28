package dbcore;

=head1 NAME

AXbills::mysql::dbcore - DB manipulation functions

=cut

use strict;
use warnings;
use DBI;
use AXbills::Base qw(int2ip in_array);

our $VERSION = 7.11;

my $CONF;
my $SORT = 1;
my $sql_errors = '/usr/axbills/var/log/sql_errors';
my $info_fields_list;

#**********************************************************
=head2 connect($dbhost, $dbname, $dbuser, $dbpasswd, $attr) - Connect to DB

  Arguments:
    $dbhost,
    $dbname,
    $dbuser,
    $dbpasswd,
    $attr
      CHARSET  - Default utf8
      SQL_MODE - Default NO_ENGINE_SUBSTITUTION
      SCOPE    - Allow to create multiple cached pools ( to use with threads)
      DBPARAMS=""

=cut
#**********************************************************
sub connect {
  my $class = shift;
  my $self = { };
  my ($dbhost, $dbname, $dbuser, $dbpasswd, $attr) = @_;

  bless( $self, $class );
  #my %conn_attrs = (PrintError => 0, RaiseError => 1, AutoCommit => 1);
  # TaintIn => 1, TaintOut => 1,
  my DBI $db;
  my $db_params = q{};

  if ($attr && $attr->{DBPARAMS}) {
    $db_params .=";".$attr->{DBPARAMS};
  }

  my $sql_mode = ($attr->{SQL_MODE}) ? $attr->{SQL_MODE} : 'NO_ENGINE_SUBSTITUTION';

  my $mysql_init_command = "SET sql_mode='$sql_mode'";
  #For mysql 5 or higher
  if ($attr->{CHARSET}) {
    $mysql_init_command .= ", NAMES $attr->{CHARSET}";
    $self->{dbcharset}=$attr->{CHARSET};
  }
  if ( $db = DBI->connect_cached( "DBI:mysql:database=$dbname;host=$dbhost;mysql_client_found_rows=0".$db_params, "$dbuser", "$dbpasswd",
       {
         Taint                => 1,
         private_scope_key    => $attr->{SCOPE} || 0,
         mysql_auto_reconnect => 1,
         mysql_init_command   => $mysql_init_command
       } )
     ) {
    $self->{db} = $db;
  }
  else {
    print "Content-Type: text/html\n\nError: Unable connect to DB server '$dbhost:$dbname'\n";
    $self->{error} = $DBI::errstr;

    require Log;
    Log->import( 'log_print' );
    $self->{sql_errno} = 0 if (!$self->{sql_errno});
    $self->{sql_errstr} = '' if (!$self->{sql_errstr});

    Log::log_print( undef, 'LOG_ERR', '', "Connection Error: $DBI::errstr", {
      NAS      => 0,
      LOG_FILE => ( -w $sql_errors) ? $sql_errors : '/tmp/sql_errors'
    });
  }


  return $self;
}

#**********************************************************
=head2 disconnect()

=cut
#**********************************************************
sub disconnect{
  my $self = shift;

  $self->{db}->disconnect;

  return $self;
}

#**********************************************************
=head2 db_version() - Get DB version

  Returns:
    $version

=cut
#**********************************************************
sub db_version{
  my $self = shift;

  my $version = $self->{db}->{db}->get_info( 18 );
  $self->{FULL_VERSION} = $version;

  if ( $version =~ /^(\d+\.\d+)/ ){
    $version = $1;
  }

  return $version;
}

#**********************************************************
=head2 query($query, $type, $attr) - Query maker

  Arguments:
    $query   - SQL query
    $type    - Type of query
      undef - with fetch result like SELECT
      do    - do query without fetch (INSERT, UPDATE, DELETE)

    $attr   - Extra attributes
      COLS_NAME   - Return Array of HASH_ref. Column name as hash key
      COLS_UPPER  - Make hash key upper
      INFO        - Return fields as objects parameters $self->{LOGIN}
      LIST2HASH   - Return 2 field hash
            KEY,VAL
      MULTI_QUERY - Make multiquery (only for INSERT, UPDATE)
      Bind        - Array or bind values for placeholders  [ 10, 12, 33 ]
      DB_REF      - DB object. Using whem manage multi DB server
      test        - Run function without excute query. if using $self->{debug} show query.

    $self->{debug} - Show query
    $self->{db}    - DB object

  Returns:
    $self->{list}          - array of array
                           - array of hash (COLS_UPPER)

    $self->{INSERT_ID}     - Insert id for autoincrement fields
    $self->{TOTAL}         - Total rows in result (for query SELECT)
    $self->{AFFECTED}      - Total added or changed fields
    $self->{COL_NAMES_ARR} - Array_hash of column names

    Error flags:
      $self->{errno}      = 3;
      $self->{sql_errno}  = $db->err;
      $self->{sql_errstr} = $db->errstr;
      $self->{errstr}

  Examples:

    Delete query

      $self->query("DELETE FROM users WHERE uid= ?;", 'do', { Bind => [ 100 ] });

      Result:

        $self->{AFFECTED}  - Total deleted rows


    Show listing:

      $self->query("SELECT id AS login, uid FROM users LIMIT 10;", undef, { COLS_NAME => 1 });

      Result:

        $self->{TOTAL}  - Total rows
        $self->{list}   - ARRAY of hash_refs

    Make info atributes

       $self->query("SELECT id AS login, gid, credit FROM users WHERE uid = ? ;", undef, { INFO => 1, Bind => [ 100 ] });

      Result:

        $self->{LOGIN}
        $self->{GID}
        $self->{CREDIT}

    LIST2HASH listing

      $self->query("SELECT id AS login, gid, credit FROM users WHERE uid = ? ;", undef, { LIST2HASH => 'login,gid' });

      $self->{list_hash} - Hash ref

=cut
#**********************************************************
sub query{
  my $self = shift;
  my ($query, $type, $attr) = @_;

  #if(! $CONF){
  #  print "Query !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! Undefined \$CONF\n";
  #  exit;
  #}

  my DBI $db = $self->{db};

  if ( $self->{db}->{db} ){
    $db = $self->{db}->{db};

    $self->{db}->{queries_count}++;

    if ( $self->{db}->{db_debug} ){
      if ( $self->{db}->{db_debug} > 4 ){
        $db->trace( 1, '/tmp/sql_trace' );
      }
      elsif ( $self->{db}->{db_debug} > 3 ){
        $db->trace( 'SQL', '/tmp/sql_trace' );
      }
      elsif ( $self->{db}->{db_debug} > 2 ){
        require Log;
        Log->import( 'log_print' );
        my $arguments = '';
        if($attr->{Bind}) {
          $arguments .= join(', ', @{ $attr->{Bind} });
        }
        Log::log_print( undef, 'LOG_ERR', '', "\n-----". ($self->{queries_count} || q{}) ."------\n$query\n------\n$arguments\n",
          { NAS => 0, LOG_FILE => "/tmp/sql_debug" } );
      }
      #sequence
      elsif ( $self->{db}->{db_debug} > 1 ){
        # Usually, library is loaded by default, but since
        # this is a critical script, we will check it just in case.
        # Fact, that is only done during debugging is also not scary for performance.
        unless ($Time::HiRes::VERSION) {
          require Time::HiRes;
          Time::Hires->import();
        }

        my $caller = qq{\n\n};
        my ($package, $filename, $line, $subroutine, $hasargs, $wantarray, $evaltext, $is_require, $hints, $bitmask, $hinthash);
        my $i = 1;
        my @r = ();
        while (@r = caller($i)) {
          ($package, $filename, $line, $subroutine, $hasargs, $wantarray, $evaltext, $is_require, $hints, $bitmask, $hinthash) = @r;
          $caller .= "  $filename:$line $subroutine\n";
          $i++;
        }

        push @{ $self->{db}->{queries_list} }, [$query. $caller, 0, $caller];
      }
      else{
        #Queries typisation
        $self->{db}->{queries_list}->{$query}++;
      }
    }
  }

  if ( $attr->{DB_REF} ){
    $db = $attr->{DB_REF};
  }

  #Query
  delete( $self->{errstr} );
  delete( $self->{errno} );
  $self->{TOTAL} = 0;

  if ( $self->{debug} ){
    print "<pre><code>\n$query\n</code></pre>\n" if ($self->{debug});
    if ( $self->{debug} ne 1 ){
      $db->trace( 1, $self->{debug} );
    }
  }

  if ( !$db || ref $db eq 'HASH' ){
    require Log;
    Log->import( 'log_print' );
    $self->{sql_errno} = 0 if (!$self->{sql_errno});
    $self->{sql_errstr} = '' if (!$self->{sql_errstr});
    my $caller = join(', ', caller());
    Log::log_print( undef, 'LOG_ERR', '',
      "Query:\n$query\n Error:$self->{sql_errno}\n Error str:$self->{sql_errstr}\nundefined \$db\n$caller",
      { NAS => 0, LOG_FILE => ( -w $sql_errors) ? $sql_errors : '/tmp/sql_errors' } );
    return $self;
  }

  if ( defined( $attr->{test} ) ){
    return $self;
  }

  $self->{AFFECTED} = 0;
  my DBI $q;
  my $start_query_time = 0;
  if ($self->{db}->{db_debug} && $self->{db}->{db_debug} == 2) {
    $start_query_time = [ Time::HiRes::gettimeofday() ]
  }

  if ( $type && $type eq 'do' ){
    $self->{AFFECTED} = $db->do( $query, undef, @{ $attr->{Bind} } );
    if ( $db->{'mysql_insertid'} ){
      $self->{INSERT_ID} = $db->{'mysql_insertid'};
    }
  }
  else{
    $q = $db->prepare( $query );

    if ( $attr->{MULTI_QUERY} ){
      foreach my $line ( @{ $attr->{MULTI_QUERY} } ){
        $q->execute( @{$line} );
        if ( $db->err ){
          $self->{errno} = 3;
          $self->{sql_errno} = $db->err;
          $self->{sql_errstr} = $db->errstr;
          $self->{errstr} = $db->errstr;
          return $self->{errno};
        }
      }

      if ($self->{db}->{db_debug} && $self->{db}->{db_debug} == 2) {
        my $elapsed = Time::HiRes::tv_interval($start_query_time);
        ${ $self->{db}->{queries_list} }[-1]->[1] = $elapsed;
      };

      $self->{TOTAL} = $#{ $attr->{MULTI_QUERY}  } + 1;
      return $self;
    }
    else{
      $q->execute( @{ $attr->{Bind} } );
      $self->{TOTAL} = $q->rows;
    }
  }

  if ($self->{db}->{db_debug} && $self->{db}->{db_debug} == 2) {
    my $elapsed = Time::HiRes::tv_interval($start_query_time);
    ${ $self->{db}->{queries_list} }[-1]->[1] = $elapsed;
  }

  if ( $db->err ){
    if ( $db->err == 1062 ){
      $self->{errno} = 7;
      $self->{errstr} = 'ERROR_DUPLICATE';
    }
    else{
      $self->{sql_errno} = $db->err;
      $self->{sql_errstr} = $db->errstr;
      $self->{errno} = 3;
      $self->{errstr} = 'SQL_ERROR';
      $self->{sql_query} = $query;
      my $caller = q{}; #join(', ', caller());
      my ($package, $filename, $line, $subroutine, $hasargs, $wantarray, $evaltext, $is_require, $hints, $bitmask, $hinthash);
      my $i = 1;
      my @r = ();
      while (@r = caller($i)) {
        ($package, $filename, $line, $subroutine, $hasargs, $wantarray, $evaltext, $is_require, $hints, $bitmask, $hinthash) = @r;
        $caller .= "$filename:$line $subroutine\n";
        $i++;
      }
      require Log;
      Log->import( 'log_print' );
      Log::log_print( undef, 'LOG_ERR', '',
        "index:". ($attr->{index} || q{}) ."\n"
          . ($query || q{}) ."\n --$self->{sql_errno}\n --$self->{sql_errstr}\n --AutoCommit: $db->{AutoCommit}\n$caller\n"
        , { NAS => 0, LOG_FILE => ( -w $sql_errors) ? $sql_errors : '/tmp/sql_errors' } );
    }
    return $self;
  }

  if ( $self->{TOTAL} > 0 ){
    my @rows = ();

    if ( $attr->{COLS_NAME} ){
      push @{ $self->{COL_NAMES_ARR} }, @{ $q->{NAME} || []};

      while (my $row = $q->fetchrow_hashref()) {
        if ( $attr->{COLS_UPPER} ){
          my $row2;
          while(my ($k, $v) = each %{$row}) {
            $row2->{uc( $k )} = $v;
          }
          $row = { %{$row2}, %{$row} };
        }
        push @rows, $row;
      }
    }
    elsif ( $attr->{INFO} ){
      push @{ $self->{COL_NAMES_ARR} }, @{ $q->{NAME} };
      while (my $row = $q->fetchrow_hashref()) {
        while(my ($k, $v) = each %{$row} ) {
          $self->{ uc( $k ) } = $v;
        }
      }
    }
    elsif ( $attr->{LIST2HASH} ){
      my ($key, @val) = split( /,\s?/, $attr->{LIST2HASH} );
      my %list_hash = ();

      while (my $row = $q->fetchrow_hashref()) {
        my @vals = ();
        foreach my $v (@val) {
          push @vals, $row->{$v};
        }

        $list_hash{$row->{$key}} = join(', ', @vals);
      }

      $self->{list_hash} = \%list_hash;
    }
    else{
      while (my @row = $q->fetchrow()) {
        push @rows, \@row;
      }
    }
    $self->{list} = \@rows;
  }
  else{
    if ( $q && $q->{NAME} && ref $q->{NAME} eq 'ARRAY' ){
      push @{ $self->{COL_NAMES_ARR} }, @{ $q->{NAME} };
    }

    delete $self->{list};
    if ( $attr->{INFO} ){
      $self->{errno} = 2;
      $self->{errstr} = 'ERROR_NOT_EXIST';
    }
  }

  if ( $attr->{CLEAR_NAMES} ){
    delete $self->{COL_NAMES_ARR};
  }

  #end
  return $self;
}

#**********************************************************
=head2 query_add($table, $values, $attr) - Insert to table constructor

  Arguments:
    $table     - Table name,
    $values    - hash of fields and values
      [FIELD_NAME] => [value]
    $attr      - extra params for delete query
      REPLACE - change INSERT to REPLACE

=cut
#**********************************************************
sub query_add{
  my $self = shift;
  my ($table, $values, $attr) = @_;

  my DBI $db = $self->{db};

  if ( $self->{db}->{db} ){
    $db = $self->{db}->{db};
  }

  my DBI $q = $db->column_info( undef, undef, $table, '%' );

  my @inserts_arr = ();
  my @values_arr = ();
  if(! $q) {
    $self->{errno}=200;
    $self->{errstr}="query_add: Error sql connections";
    return $self;
  }

  while (defined( my $row = $q->fetchrow_hashref() )) {
    my $column = uc( $row->{COLUMN_NAME} );
    if ( $values->{$column} ){
      if ( $column eq 'IP' || $column eq 'NETMASK' ){
        push @inserts_arr, "$row->{COLUMN_NAME}=INET_ATON( ? )";
      }
      # Anton
      #elsif ($column eq 'IPV6_PREFIX' || $column eq 'IPV6') {
      #  push @inserts_arr, "$row->{COLUMN_NAME}=INET6_ATON( ? )";
      #}
      elsif ( $column eq 'IPV6' || $column eq 'IPV6_PD' ){
        push @inserts_arr, "$row->{COLUMN_NAME}=INET6_ATON( ? )";
      }
      elsif ( $values->{$column} =~ /^INET_ATON\(['"]+([0-9a-f\.]+)['"]+\)/i ){
        push @values_arr, $1;
        push @inserts_arr, "$row->{COLUMN_NAME}=INET_ATON(?)";
        next;
      }
      elsif ( $values->{$column} =~ m/^ENCODE\(['"]+(.+)['"]+,\s['"]+(.+)['"]+\)/i ){
        push @values_arr, $1, $2;
        push @inserts_arr, "$row->{COLUMN_NAME}=ENCODE(?, ?)";
        next;
      }
      elsif ( $column =~ /SUBJECT|MESSAGE|REPLY|TEXT/i ){
        $values->{$column} =~ s/\\\'/\'/g;
        $values->{$column} =~ s/\\\"/\"/g;
        $values->{$column} =~ s/\%2B/\+/g;

        push @inserts_arr, "$row->{COLUMN_NAME}= ? ";
      }
      else{
        if ( $values->{$column} =~ /^[a-z\_]+\(\)$/i ){
          push @inserts_arr, "$row->{COLUMN_NAME}=$values->{$column}";
          next;
        }
        else{
          if ( $column !~ /ATTA|FILE/i ){
            $values->{$column} =~ s/\\\'/\'/g;
            $values->{$column} =~ s/\\\"/\"/g;
            $values->{$column} =~ s/\%2B/\+/g;
          }

          push @inserts_arr, "$row->{COLUMN_NAME}= ? ";
        }
      }

      if($row->{TYPE_NAME} && $row->{TYPE_NAME} eq 'VARCHAR') {
        $values->{$column} =~ s/^\s//;
      }

      push @values_arr, $values->{$column};
    }
    elsif ( defined( $values->{$column} ) ){
      if ( $column eq 'COMMENTS' ){
        push @inserts_arr, "$row->{COLUMN_NAME}= ? ";
        push @values_arr, $values->{$column};
      }
      elsif ( $values->{$column} ne '' && $values->{$column} == 0 ){
        push @inserts_arr, "$row->{COLUMN_NAME}= ? ";
        push @values_arr, $values->{$column};
      }
    }
  }

  if ($#inserts_arr < 0) {
    $self->{errno}=201;
    $self->{errstr}="query_add: No input data";
    return $self
  }

  my $sql = (($attr->{REPLACE}) ? 'REPLACE' : 'INSERT') . " INTO `$table` SET " . join( ",\n ", @inserts_arr );

  return $self->query( $sql, 'do', { Bind => \@values_arr } );
}

#**********************************************************
=head2 query_del($table, $values, $extended_params) - Delete constructor

  Arguments:
    $table            - Table name,
    $values           - delete values
    $extended_params  - extra params for delete query
      [field_name] => [value]
    $attr
      CLEAR_TABLE  => Truncate table information

=cut
#**********************************************************
sub query_del{
  my $self = shift;
  my ($table, $values, $extended_params, $attr) = @_;

  my @WHERE_FIELDS = ();
  my @WHERE_VALUES = ();

  if ( $attr->{CLEAR_TABLE} ){
    $self->query( "TRUNCATE `$table`;", 'do' );
    return $self;
  }

  if ( $values->{ID} ){
    my @id_arr = split( /,/, $values->{ID} );
    push @WHERE_FIELDS, "id IN (" . join( ',', map { '?' } @id_arr ) . ')';
    push @WHERE_VALUES, @id_arr;
  }

  while(my ($k, $v) = each %{$extended_params}) {
    if ( defined( $v ) ){
      if ( ref $v eq 'ARRAY' ){
        push @WHERE_FIELDS, "$k IN (" . join( ',', map { '?' } @{$v} ) . ')';
        push @WHERE_VALUES, @{$v};
      }
      else{
        push @WHERE_FIELDS, "$k = ?";
        push @WHERE_VALUES, $v;
      }
    }
  }

  if ( $#WHERE_FIELDS == -1 ){
    return $self;
  }

  $self->query( "DELETE FROM `$table` WHERE " . join( ' AND ', @WHERE_FIELDS ),
    'do', { Bind => \@WHERE_VALUES } );

  return $self;
}

#**********************************************************
=head2 get_data($params, $attr) - Input date into hash

=cut
#**********************************************************
sub get_data{
  shift;
  my ($params, $attr) = @_;

  my %DATA = ();

  if ( defined( $attr->{default} ) ){
    %DATA = %{ $attr->{default} };
  }

  while (my ($k, $v) = each %{$params}) {
    next if (!$params->{$k} && defined( $DATA{$k} ));
    $v =~ s/^ +|[ \n]+$//g if ($v);
    $DATA{$k} = $v;
  }

  return %DATA;
}

#**********************************************************
=head2 search_former($data_hash_ref, $search_params, $attr) - SQL search former

  Arguments:
    $data          - Input data hash ref
    $search_params - search params array
       [field_id, where_filed_name, field_show_name, show_field (1 or 0) ],

    $attr          - extra atributes
      USERS_FIELDS      - Use main users params
      USERS_FIELDS_PRE  - Use main users params before main result
      USE_USER_PI       - Use users pi iformation params
      SKIP_USERS_FIELDS - Skip users fields
      WHERE             - add WHERE before search params

=cut
#**********************************************************
sub search_former{
  my $self = shift;
  my ($data, $search_params, $attr) = @_;

  my @WHERE_RULES = ();
  $self->{SEARCH_FIELDS}          = '';
  $self->{EXT_TABLES}             = '';
  $self->{SEARCH_FIELDS_COUNT}    = 0;
  $self->{SEARCH_VALUES}          = [];
  @{ $self->{SEARCH_FIELDS_ARR} } = ();

  # if ($data->{_WHERE_RULES}) {
  #   push @WHERE_RULES, $data->{_WHERE_RULES};
  # }

  my @user_fields = (
    'LOGIN',
    'UID',
    'FIO',
    'FIO2',
    'FIO3',
    'DEPOSIT',
    'CREDIT',
    'CREDIT_DATE',
    'PHONE',
    'EMAIL',
    'FLOOR',
    'ENTRANCE',
    'ADDRESS_FLAT',
    'PASPORT_DATE',
    'PASPORT_NUM',
    'PASPORT_GRANT',
    'CITY',
    'ZIP',
    'GID',
    'COMPANY_ID',
    'COMPANY_NAME',
    'CONTRACT_ID',
    'CONTRACT_SUFIX',
    'CONTRACT_DATE',
    'EXPIRE',
    'REDUCTION',
    'REDUCTION_DATE',
    'COMMENTS',
    'BILL_ID',
    'LOGIN_STATUS',
    'LOGIN_DELETED',
    'DOMAIN_ID',
    'DOMAIN_NAME',
    'PASSWORD',
    'ACCEPT_RULES',
    'ACTIVATE',
    'EXPIRE',
    'REGISTRATION',
    'LAST_PAYMENT',
    'LAST_FEES',
    'EXT_BILL_ID',
    'EXT_DEPOSIT',
    'BIRTH_DATE',
    'CELL_PHONE',
  );

  if ( $attr->{USERS_FIELDS_PRE} ){
    push @WHERE_RULES, @{ $self->search_expr_users( { %{$data},
        EXT_FIELDS        => \@user_fields,
        SKIP_USERS_FIELDS => $attr->{SKIP_USERS_FIELDS},
        USE_USER_PI       => $attr->{USE_USER_PI},
        SUPPLEMENT        => 1
      } ) };
  }

  foreach my $search_param ( @{$search_params} ){
    my ($param, $field_type, $sql_field, $show) = @{$search_param};
    next if (in_array($param, $data->{HIDDEN_COLUMNS}));
    my $param2 = '';
    if ($param && $param =~ /^(.*)\|(.*)$/ ){
      $param = $1 || q{};
      $param2 = $2 || q{};
    }

    $field_type //= q{};

    if (($param && $data->{$param}) || ($field_type eq 'INT' && defined( $data->{$param} ) && $data->{$param} ne '') ){
      if ( $sql_field eq '' ){
        $self->{SEARCH_FIELDS} .= "$show, ";
        $self->{SEARCH_FIELDS_COUNT}++;
        push @{ $self->{SEARCH_FIELDS_ARR} }, $show;
      }
      elsif ( $param2 ){
        push @WHERE_RULES, "($sql_field>='$data->{$param}' and $sql_field<='". ($data->{$param2} || q{}) ."')";
      }
      else{
        push @WHERE_RULES,
          @{ $self->search_expr( $data->{$param}, $field_type, $sql_field, { EXT_FIELD => $show } ) };
      }
    }
  }

  if ( $attr->{USERS_FIELDS} ){
    push @WHERE_RULES, @{ $self->search_expr_users( {
      %{$data},
      EXT_FIELDS        => \@user_fields,
      SKIP_USERS_FIELDS => $attr->{SKIP_USERS_FIELDS},
      USE_USER_PI       => $attr->{USE_USER_PI},
      SUPPLEMENT        => 1
    } ) };
  }
# add hidden fields
  foreach my $search_param ( @{$search_params} ){
    my ($param, $field_type, $sql_field, $show) = @{$search_param};
    next unless (in_array($param, $data->{HIDDEN_COLUMNS}));
    my $param2 = '';
    if ( $param =~ /^(.*)\|(.*)$/ ){
      $param = $1;
      $param2 = $2;
    }

    if ( $data->{$param} || ($field_type eq 'INT' && defined( $data->{$param} ) && $data->{$param} ne '') ){
      if ( $sql_field eq '' ){
        $self->{SEARCH_FIELDS} .= "$show, ";
        $self->{SEARCH_FIELDS_COUNT}++;
        push @{ $self->{SEARCH_FIELDS_ARR} }, $show;
      }
      elsif ( $param2 ){
        push @WHERE_RULES, "($sql_field>='$data->{$param}' and $sql_field<='$data->{$param2}')";
      }
      else{
        push @WHERE_RULES,
          @{ $self->search_expr( $data->{$param}, $field_type, $sql_field, { EXT_FIELD => $show } ) };
      }
    }
  }

  if ( $attr->{WHERE_RULES} ){
    push @WHERE_RULES, @{ $attr->{WHERE_RULES} };
    @{ $attr->{WHERE_RULES} } = @WHERE_RULES;
  }

  my $delimiter = ' AND ';

  if($data->{_MULTI_HIT}) {
    $delimiter = ' Or ';
  }

  my $WHERE = ($#WHERE_RULES > -1) ? (($attr->{WHERE}) ? 'WHERE ' : '') . join($delimiter, @WHERE_RULES ) : '';

  return $WHERE;
}

#**********************************************************
=head2  search_expr($self, $value, $type) - Search expration

  Arguments:
    $value - search value
    $type  - type of fields
      IP -  IP Address
        , - or
        ; - and
      INT - integer
        , - or
        ; - and
      STR - string
        , - or
        ; - and
      DATE - Date
        , - or
        ; - and
    $field - field name
    $attr  - extra add
      EXT_FIELD
      NOTFILLED -

=cut
#**********************************************************
sub search_expr{
  my $self = shift;
  my ($value, $type, $field, $attr) = @_;

  if ( $attr->{EXT_FIELD} ){
    $self->{SEARCH_FIELDS} .= ($attr->{EXT_FIELD} ne '1') ? "$attr->{EXT_FIELD}, " : "$field, ";
    $self->{SEARCH_FIELDS_COUNT}++;

    if ( $attr->{EXT_FIELD} ne '1' ){
      if ( $attr->{EXT_FIELD} !~ /^IF\(|CONCAT\(|MAX\(/i ){
        push @{ $self->{SEARCH_FIELDS_ARR} }, split( ', ', $attr->{EXT_FIELD} );
      }
      else{
        push @{ $self->{SEARCH_FIELDS_ARR} }, $attr->{EXT_FIELD};
      }
    }
    else{
      push @{ $self->{SEARCH_FIELDS_ARR} }, $field;
    }
  }

  my @result_arr = ();
  if ( !defined( $value ) ){
    $value = '';
  }

  return \@result_arr if ( $value eq '_SHOW');

  if ( $field ){
    $field =~ s/ (as) ([a-z0-9_]+)//gi;
  }
  my $delimiter = ($value =~ s/;/,/g) ? 'and' : 'or';
  if ( $type eq 'INT' && ! $attr->{_MULTI_HIT} && ( $value !~ /^[0-9,\-\.\s\<\>\=\*!]+$/g) ){
    $self->{errno}=113;
    $self->{errstr} = 'ERROR_WRONG_FIELD_VALUE '.$field. " VALUE: ". $value;
    return [];
  }

  if ( $value && $delimiter eq 'and' && $value !~ /[<>=]+/ ){
    my @val_arr = split( /,/, $value );
    $value = "'" . join( "', '", @val_arr ) . "'";
    #(@{[join',', ('?') x @list]})";
    return [ "$field IN ($value)" ];
  }

  my @val_arr = ();
  if ( defined( $value ) ){
    if ( $value eq '' ){
      @val_arr = ('');
    }
    else{
      if($value =~ /^\*.+\*$/) {
        push @val_arr, $value;
      }
      else {
        @val_arr = split(/,/, $value);
      }
    }
  }

  foreach my $v ( @val_arr ){
    my $expr = '=';
    if ( $type eq 'DATE' ){
      if ( $v =~ /(\d{4}-\d{2}-\d{2})\/(\d{4}-\d{2}-\d{2})/ ){
        my $from_date = $1;
        my $to_date = $2;
        if ( $field ){
          push @result_arr, "($field>='$from_date' AND $field<='$to_date')";
        }
        next;
      }
      elsif ( $v =~ /([=><!]{0,2})(\d{2})[\/\.\-](\d{2})[\/\.\-](\d{4})/ ){
        $v = "$1$4-$3-$2";
      }
      elsif ( $v eq '*' ){
        $v = ">=0000-00-00";
      }
    }

    if ( $type eq 'INT' && $v =~ s/\*/\%/g ){
      $expr = ' LIKE ';
    }
    elsif ( $type eq 'STR' ){
      $expr = '=';
      if ($v =~ s/^!//) {
        $expr = '<>';
      }
      elsif ($v eq '_EMPTY_') {
        $v = '';
      }
      elsif ( $v =~ /\\\*/ ){
        $v = '*';
      }
      else{
        if ( $v =~ s/\*/\%/g ){
          $expr = ' LIKE ';
        }
      }
    }
    elsif ( $v =~ s/^!// ){
      $expr = ' <> ';
    }
    elsif ( $v =~ s/^([<>=]{1,2})// ){
      $expr = $1;
    }

    if ( $type eq 'IP' ){
      if ($value !~ /^[\,\;\=\<\>0-9\.\*]+$|INET_ATON/) {
        return [];
      }

      if ( $value =~ m/\*/g ){
        $value =~ s/[<>]+//;
        my ($i, $first_ip, $last_ip);
        my @p = split( /\./, $value );
        for ( $i = 0; $i < 4; $i++ ){
          if (defined($p[$i]) && length($p[$i]) < 3 && $p[$i] =~ /(\d{0,2})\*/ ){
            $first_ip .= $1 || '0';
            $last_ip .= $1 || '255';
          }
          else{
            my $ip = $p[$i] || q{};
            $ip =~ s/\*//g;
            $first_ip .= $ip || 0;
            $last_ip .= $ip || 255;
          }

          if ( $i != 3 ){
            $first_ip .= '.';
            $last_ip .= '.';
          }
        }

        push @result_arr, "($field>=INET_ATON('$first_ip') AND $field<=INET_ATON('$last_ip'))";
        return \@result_arr;
      }
      else{
        $v = "INET_ATON('$v')";
      }
    }
    elsif($expr eq ' LIKE ' && $v eq '%') {
      next;
    }
    else{
      $v = "'$v'";
    }

    if($attr->{NOFILLED} ) {
      $expr = '<>';
      if($type eq 'INT') {
        $expr = '=';
        $v = 0;
      }
      else {
        $expr = '<>';
        $v = '';
      }
    }

    $value = $expr . $v;
    if ($field) {
      push @result_arr, "$field$value";
    }
  }

  if ( $field ){
    if ( $type ne 'INT' ){
      if ( $#result_arr > -1 ){
        return [ '(' . join( " $delimiter ", @result_arr ) . ')' ];
      }
      else{
        return [ ];
      }
    }
    return \@result_arr;
  }

  return [ $value ];
}

#**********************************************************
=head2 search_expr_users($attr) - Formed WHERE rules

  Arguments:

    $attr
      EXT_FIELDS     -
      SUPPLEMENT
      SKIP_GID
      USE_USER_PI
      CONTRACT_SUFIX
      SKIP_DEL_CHECK      - Skip check del users
      SKIP_USERS_FIELDS   - SKip user field search

      SORT
      SORT_SHIFT

  Returns:
    \@fields - Fields ARRAY_REF
    $self->
       SORT_BY - Extra sort option

=cut
#**********************************************************
sub search_expr_users{
  my $self = shift;
  my ($attr) = @_;
  my @fields = ();

  if ( !$attr->{SUPPLEMENT} ){
    $self->{SEARCH_FIELDS}          = '';
    $self->{SEARCH_FIELDS_COUNT}    = 0;
    $self->{EXT_TABLES}             = '';
    @{ $self->{SEARCH_FIELDS_ARR} } = ();
    $self->{SEARCH_VALUES}          = [];
  }

  my $admin;
  if ($self->{admin}) {
    $admin = $self->{admin};
  }

  my %EXT_TABLE_JOINS_HASH = ();

  if ( !$CONF ){
    if ( $self->{conf} ){
      $CONF = $self->{conf};
    }
    else{
      print "Content-Type: text/html\n\n";
      my ($package, $filename, $line, $subroutine, $hasargs) = caller(1);
      print "--- $self->{conf} // Undefined \$CONF Package: $package Filename: $filename Line: $line\n";
      print "$package, $filename, $line, $subroutine, $hasargs\n";
      exit;
    }
  }
  #ID:type:Field name
  my %users_fields_hash = (
    LOGIN          => 'STR:u.id AS login',
    UID            => 'INT:u.uid',
    DEPOSIT        => 'INT:IF(company.id IS NULL, b.deposit, cb.deposit) AS deposit',
    DOMAIN_ID      => 'INT:u.domain_id',
    COMPANY_ID     => 'INT:u.company_id',
    COMPANY_CREDIT => 'INT:company.credit AS company_credit',
    COMPANY_NAME   => 'INT:company.name AS company_name',
    LOGIN_STATUS   => 'INT:u.disable AS login_status',
    LOGIN_DELETED  => 'INT:u.deleted AS login_deleted',
    REGISTRATION   => 'DATE:u.registration',
    COMMENTS       => 'STR:pi.comments',
    FIO            => 'STR:CONCAT_WS(" ", pi.fio, pi.fio2, pi.fio3) AS fio',
    PHONE          => q/STR:(SELECT GROUP_CONCAT(value SEPARATOR ';') FROM `users_contacts` uc WHERE uc.uid=u.uid AND type_id IN (1,2)) AS phone/,
    EMAIL          => q/STR:(SELECT GROUP_CONCAT(value SEPARATOR ';') FROM `users_contacts` uc WHERE uc.uid=u.uid AND type_id=9) AS email/,
    ACCEPT_RULES   => 'INT:pi.accept_rules',

    CELL_PHONE     => q/STR:(SELECT GROUP_CONCAT(value SEPARATOR ';') FROM `users_contacts` uc WHERE uc.uid=u.uid AND type_id=1) AS cell_phone/,
    TELEGRAM       => q/STR:(SELECT GROUP_CONCAT(value SEPARATOR ';') FROM `users_contacts` uc WHERE uc.uid=u.uid AND type_id = 6) AS telegram/,
    VIBER          => q/STR:(SELECT GROUP_CONCAT(value SEPARATOR ';') FROM `users_contacts` uc WHERE uc.uid=u.uid AND type_id = 5) AS viber/,
    VIBER_BOT      => q/STR:(SELECT GROUP_CONCAT(value SEPARATOR ';') FROM `users_contacts` uc WHERE uc.uid=u.uid AND type_id = 5) AS viber_bot/,

    PASPORT_DATE   => 'DATE:pi.pasport_date',
    PASPORT_NUM    => 'STR:pi.pasport_num',
    PASPORT_GRANT  => 'STR:pi.pasport_grant',
    #CONTRACT_ID   => 'STR:if(u.company_id=0, concat(pi.contract_sufix,pi.contract_id), concat(company.contract_sufix,company.contract_id)) AS contract_id',
    CONTRACT_ID    => 'STR:IF(u.company_id=0, pi.contract_id, company.contract_id) AS contract_id',
    CONTRACT_DATE  => 'STR:IF(u.company_id=0, pi.contract_date, company.contract_date) AS contract_date',
    CONTRACT_SUFIX => 'STR:pi.contract_sufix',
    CONTRACT_DATE  => 'DATE:pi.contract_date',

    ACTIVATE       => 'DATE:u.activate',
    EXPIRE         => 'DATE:u.expire',

    #CREDIT        => 'INT:u.credit',
    CREDIT         => 'INT:IF(u.credit > 0, u.credit, IF(company.id IS NULL, 0, company.credit)) AS credit',
    CREDIT_DATE    => 'DATE:u.credit_date',
    REDUCTION      => 'INT:u.reduction',
    REDUCTION_DATE => 'DATE:u.reduction_date',
    COMMENTS       => 'STR:pi.comments',
    BILL_ID        => 'INT:IF(company.id IS NULL,b.id,cb.id) AS bill_id',
    PASSWORD       => "STR:DECODE(u.password, '" . ($CONF->{secretkey} || q{}) . "') AS password",
    EXT_DEPOSIT    => 'INT:IF(company.id IS NULL, ext_b.deposit, ext_cb.deposit) AS ext_deposit',
    EXT_BILL_ID    => 'INT:IF(company.id IS NULL, u.ext_bill_id, company.ext_bill_id) AS ext_bill_id',
    LAST_PAYMENT   => 'INT:(SELECT MAX(p.date) FROM `payments` p WHERE p.uid=u.uid) AS last_payment',
    LAST_FEES      => ($CONF->{LASTFEE_POOL}) ? 'INT:(SELECT max(f.date) FROM `fees_last` f WHERE f.uid=u.uid) AS last_fees' : 'INT:(SELECT max(f.date) FROM `fees` f WHERE f.uid=u.uid) AS last_fees',
    BIRTH_DATE     => 'DATE:pi.birth_date',
    FLOOR          => 'INT:pi.floor',
    ENTRANCE       => 'INT:pi.entrance'
    #ADDRESS_FLAT  => 'STR:pi.address_flat',
  );

  if ( $attr->{DEPOSIT} && $attr->{DEPOSIT} ne '_SHOW' ){
    #$users_fields_hash{DEPOSIT} = 'INT:b.deposit'
    $users_fields_hash{DEPOSIT} = 'INT:IF(company.id IS NULL, b.deposit, cb.deposit) AS deposit';
  }

  if ( $attr->{CONTRACT_SUFIX} ){
    $attr->{CONTRACT_SUFIX} =~ s/\|//g;
  }

  my $info_field = $attr->{LOGIN} || 0;
  my %filled = ();
  foreach my $key ( @{ $attr->{EXT_FIELDS} }, keys %{ $attr } ){
    if ( defined( $users_fields_hash{$key} ) && defined( $attr->{$key} ) ){
      if ( in_array( $key . ':skip', $attr->{EXT_FIELDS} ) || $filled{$key} ){
        next;
      }
      elsif ( $attr->{SKIP_USERS_FIELDS} && in_array( $key, $attr->{SKIP_USERS_FIELDS} ) ){
        next;
      }

      my ($type, $field) = split( /:/, $users_fields_hash{$key} );
      if ( $type eq 'STR' ){
        if ( !$attr->{$key} ){
          next;
        }
        elsif ( $attr->{$key} eq '!' ){
          $attr->{$key} = '';
        }
      }
      #      elsif ($type eq 'STR' && $attr->{$key} eq '') {
      #      	next;
      #      }

      push @fields, @{ $self->search_expr( $attr->{$key}, $type, $field,
          { EXT_FIELD  => in_array($key, $attr->{EXT_FIELDS}),
            NOTFILLED  => ($attr->{'NOTFILLED_' . $key}) ? 1 : undef,
            _MULTI_HIT => $attr->{_MULTI_HIT}
          } ) };
      $filled{$key} = 1;
    }
    elsif ( !$info_field && $key =~ /^_/ ){
      $info_field = 1;
    }
  }

  if ($self->{errno}) {
    if ( ! $attr->{_MULTI_HIT}) {
      return [];
    }
  }

  #Info fields
  if ($self->{conf}->{info_fields_new}) {
    if (! $info_fields_list) {
      $self->query("SELECT
        name,
        sql_field,
        type,
        domain_id,
        id
      FROM `info_fields`;", undef, { COLS_NAME => 1 });
      $info_fields_list = $self->{list};
    }

    if ( $info_fields_list ){
      foreach my $line ( @{ $info_fields_list } ){
        my $field_name = $line->{sql_field};
        my $field_id   = uc($field_name);
        my $type       = $line->{type} || 0;

        if ( defined( $attr->{$field_id} ) && $type == 4 ){
          push @fields,
            @{ $self->search_expr( $attr->{$field_id}, 'INT', "pi.$field_name", {
              EXT_FIELD  => 1,
              _MULTI_HIT => $attr->{_MULTI_HIT}
            } ) };
        }
        #Skip for bloab
        elsif ( $type == 5 ){
          next;
        }
        elsif ( $attr->{$field_id} ){
          if ( $type == 1 ){
            push @fields,
              @{ $self->search_expr( $attr->{$field_id}, 'INT', "pi.$field_name", {
                EXT_FIELD  => 1,
                _MULTI_HIT => $attr->{_MULTI_HIT}
              } ) };
          }
          elsif ( $type == 2 ){
            push @fields, @{ $self->search_expr( $attr->{$field_id}, 'INT', "pi.$field_name", {
              EXT_FIELD  => $field_name . '_list.name AS ' . $field_name,
              _MULTI_HIT => $attr->{_MULTI_HIT}
            })
              };
            $self->{EXT_TABLES} .= "LEFT JOIN $field_name" . "_list ON (pi.$field_name = $field_name" . "_list.id)";
          }
          elsif ( $type == 16 ){
            if($attr->{$field_id} && $attr->{$field_id} ne '_SHOW') {
              my ($sn_type, $info) = split( /, /, $attr->{$field_id} );
              push @fields, @{ $self->search_expr( "$sn_type*". ($info || q{}), 'STR', "pi.$field_name",
                { EXT_FIELD  => 1,
                  _MULTI_HIT => $attr->{_MULTI_HIT}
                } ) };
            }
            else {
              push @fields, @{ $self->search_expr( $attr->{$field_id}, 'STR', "pi.$field_name", {
                EXT_FIELD  => 1,
                _MULTI_HIT => $attr->{_MULTI_HIT}
              } ) };
            }
          }
          else{
            push @fields,
              @{ $self->search_expr( $attr->{uc( $field_name )}, 'STR', "pi.$field_name", {
                EXT_FIELD  => 1,
                _MULTI_HIT => $attr->{_MULTI_HIT}
              } ) };
          }
        }

      }
      $self->{EXTRA_FIELDS} = $info_fields_list;
      if($#fields > -1) {
        $EXT_TABLE_JOINS_HASH{users_pi} = 1;
      }
    }
  }
  elsif ( $info_field && $self->can( 'config_list' ) ){
    my $list = $self->config_list( { PARAM => 'ifu*', SORT => 2 } );

    if ( $self->{TOTAL} > 0 ){
      foreach my $line ( @{$list} ){
        if ( $line->[0] =~ /ifu(\S+)/ ){
          my $field_name = $1;
          my $field_id   = uc($field_name);
          # $position, $type, $name
          my (undef, $type, undef) = split( /:/, $line->[1] );

          if($type !~ /\d+/) {
            $type = 0;
          }

          if ( defined( $attr->{uc( $field_name )} ) && $type == 4 ){
            push @fields,
              @{ $self->search_expr( $attr->{$field_id}, 'INT', "pi.$field_name", {
                EXT_FIELD  => 1,
                _MULTI_HIT => $attr->{_MULTI_HIT}
              } ) };
          }
          #Skip for bloab
          elsif ( $type == 5 ){
            next;
          }
          elsif ( $attr->{$field_id} ){
            if ( $type == 1 ){
              push @fields,
                @{ $self->search_expr( $attr->{$field_id}, 'INT', "pi.$field_name", {
                  EXT_FIELD => 1,
                  _MULTI_HIT => $attr->{_MULTI_HIT}
                } )
              };
            }
            elsif ( $type == 2 ){
              push @fields, @{ $self->search_expr( $attr->{$field_id}, 'INT', "pi.$field_name", {
                EXT_FIELD => $field_name . '_list.name AS ' . $field_name,
                _MULTI_HIT => $attr->{_MULTI_HIT}
                })
              };

              $self->{EXT_TABLES} .= "LEFT JOIN $field_name" . "_list ON (pi.$field_name = $field_name" . "_list.id)";
            }
            elsif ( $type == 16 ){
              if($attr->{$field_id} && $attr->{$field_id} ne '_SHOW') {
                my ($sn_type, $info) = split( /, /, $attr->{$field_id} );
                push @fields, @{ $self->search_expr( "$sn_type*". ($info || q{}), 'STR', "pi.$field_name", { EXT_FIELD => 1 } ) };
              }
              else {
                push @fields, @{ $self->search_expr( $attr->{$field_id}, 'STR', "pi.$field_name", { EXT_FIELD => 1 } ) };
              }
            }
            else{
              push @fields,
                @{ $self->search_expr( $attr->{uc( $field_name )}, 'STR', "pi.$field_name", { EXT_FIELD => 1 } ) };
            }
          }
        }
      }
      $self->{EXTRA_FIELDS} = $list;
    }
  }

  if ( $attr->{SKIP_GID} ){
    #push @fields,  @{ $self->search_expr($attr->{GID}, 'INT', 'u.gid', { EXT_FIELD => in_array('GID', $attr->{EXT_FIELDS}) }) };
  }
  elsif ( $attr->{GIDS} ){
    if ( $admin->{GID} ){
      my @result_gids = ();
      my @admin_gids = split( /,\s?|;\s?/, $admin->{GID} );

      if ( $attr->{GIDS} && $attr->{GIDS} ne '_SHOW') {
        my @attr_gids = split( /,\s?|;\s?/, $attr->{GIDS} );
        foreach my $attr_gid (@attr_gids) {
          foreach my $admin_gid (@admin_gids) {
            if ($admin_gid == $attr_gid) {
              push @result_gids, $attr_gid;
              last;
            }
          }
        }
      }
      else {
        @result_gids = @admin_gids;
        if ($attr->{GIDS} eq '_SHOW') {
          push @{$self->{SEARCH_FIELDS_ARR}}, 'u.gid';
        }
      }

      $attr->{GIDS} = join( ', ', @result_gids );
    }

    if ($attr->{GIDS} ne '_SHOW'){
      $attr->{GIDS} =~ s/;/,/g;
      my $search_field = "u.gid IN ($attr->{GIDS})";
      if ($attr->{SHOW_UNREG_USERS} && $admin->{GID}) {
        $search_field = "(u.gid IS NULL OR $search_field)";
      }

      push @fields, $search_field;
    }
  }
  elsif ( defined( $attr->{GID} ) && $attr->{GID} ne '' ){
    $attr->{GID} =~ s/,/;/g;

    push @fields, @{ $self->search_expr( $attr->{GID}, 'INT', 'u.gid',
        { EXT_FIELD => in_array( 'GID', $attr->{EXT_FIELDS} ) || ($attr->{GID} eq '_SHOW') ? 1 : undef } ) };
  }
  elsif ( $admin->{GID} ){
    $admin->{GID} =~ s/;/,/g;

    my $search_field = "u.gid IN ($admin->{GID})";
    if ($attr->{SHOW_UNREG_USERS}) {
      $search_field = "(u.gid IS NULL OR $search_field)";
    }

    push @fields, $search_field;
  }

  if ( $attr->{GROUP_NAME} ){
    push @fields, @{ $self->search_expr($attr->{GROUP_NAME}, 'STR', 'g.name', { EXT_FIELD => 'g.name AS group_name' } ) };

    $EXT_TABLE_JOINS_HASH{groups} = 1;

    if ( defined( $attr->{DISABLE_PAYSYS} ) ){
      push @fields, @{ $self->search_expr($attr->{DISABLE_PAYSYS}, 'INT', 'g.disable_paysys', { EXT_FIELD => 1 } ) };
    }
  }

  if ( !$attr->{DOMAIN_ID} && $admin->{DOMAIN_ID} && ! $attr->{SKIP_DOMAIN} ){
    push @fields, @{ $self->search_expr( $admin->{DOMAIN_ID}, 'INT', 'u.domain_id' ) };
  }

  if ( $attr->{NOT_FILLED} ){
    push @fields, "builds.id IS NULL";
    $EXT_TABLE_JOINS_HASH{builds} = 1;
  }
  elsif ( $attr->{LOCATION_ID} ){
    if(! $attr->{SKIP_USERS_FIELDS} || ! in_array('LOCATION_ID', $attr->{SKIP_USERS_FIELDS}) ) {
      push @fields, @{$self->search_expr($attr->{LOCATION_ID}, 'INT', 'pi.location_id', { EXT_FIELD =>
        'streets.name AS address_street, builds.number AS address_build, pi.address_flat, builds.id AS build_id' })};
      $EXT_TABLE_JOINS_HASH{users_pi} = 1;
      $EXT_TABLE_JOINS_HASH{builds} = 1;
      $EXT_TABLE_JOINS_HASH{streets} = 1;
      $self->{SEARCH_FIELDS_COUNT} += 3;
    }
    if ($attr->{MAPS_COORDS}) {
      push @fields, @{$self->search_expr($attr->{MAPS_COORDS}, 'INT', 'builds.coordx',
        { EXT_FIELD => 'builds.coordx AS coordx' })};
      push @fields, @{$self->search_expr($attr->{MAPS_COORDS}, 'INT', 'builds.coordy',
        { EXT_FIELD => 'builds.coordy AS coordy' })};
      $EXT_TABLE_JOINS_HASH{builds} = 1;
    }
  }
  elsif ($attr->{STREET_ID}) {
    if (!$attr->{SKIP_USERS_FIELDS} || !in_array('STREET_ID', $attr->{SKIP_USERS_FIELDS})) {
      push @fields, @{$self->search_expr($attr->{STREET_ID}, 'INT', 'builds.street_id',
        { EXT_FIELD => 'streets.name AS address_street, builds.number AS address_build' })};

      $EXT_TABLE_JOINS_HASH{users_pi} = 1;
      $EXT_TABLE_JOINS_HASH{builds} = 1;
      $EXT_TABLE_JOINS_HASH{streets} = 1;
      $self->{SEARCH_FIELDS_COUNT} += 1;
    }
  }
  # elsif ( $attr->{DISTRICT_ID} ){
  #   push @fields, @{ $self->search_expr( $attr->{DISTRICT_ID}, 'INT', 'streets.district_id',
  #       { EXT_FIELD => 1 } ) }; # 'districts.name AS district_name' }) };
  #
  #   $EXT_TABLE_JOINS_HASH{users_pi} = 1;
  #   $EXT_TABLE_JOINS_HASH{builds} = 1;
  #   $EXT_TABLE_JOINS_HASH{streets} = 1;
  #   $EXT_TABLE_JOINS_HASH{districts} = 1;
  # }
  else{
    if ( $CONF->{ADDRESS_REGISTER} ){
      if ( $attr->{CITY} ){
        push @fields, @{ $self->search_expr( $attr->{CITY}, 'STR', 'districts.city', { EXT_FIELD => 1 } ) };
        $EXT_TABLE_JOINS_HASH{users_pi} = 1;
        $EXT_TABLE_JOINS_HASH{builds} = 1;
        $EXT_TABLE_JOINS_HASH{streets} = 1;
        $EXT_TABLE_JOINS_HASH{districts} = 1;
      }

      if ($attr->{DISTRICT_ID} && !in_array('DISTRICT_ID', $attr->{SKIP_USERS_FIELDS})) {
        push @fields, @{ $self->search_expr( $attr->{DISTRICT_ID}, 'INT', 'streets.district_id', { EXT_FIELD => 1 } ) };
        $EXT_TABLE_JOINS_HASH{users_pi} = 1;
        $EXT_TABLE_JOINS_HASH{builds} = 1;
        $EXT_TABLE_JOINS_HASH{streets} = 1;
        $EXT_TABLE_JOINS_HASH{districts} = 1;
      }

      if ( $attr->{ADDRESS_FULL} && !in_array( 'ADDRESS_FULL', $attr->{SKIP_USERS_FIELDS} )){
        my $build_delimiter = $attr->{BUILD_DELIMITER} || $self->{conf}{BUILD_DELIMITER} || ', ';

        # if ($build_delimiter =~ /,/) {
        #   $attr->{ADDRESS_FULL} =~ s/,/\*/g;
        # }

        push @fields, @{ $self->search_expr( $attr->{ADDRESS_FULL}, "STR",
            "CONCAT(" . ($self->{conf}{ADDRESS_FULL_SHOW_DISTRICT} ? "districts.name, '$build_delimiter'," : "") .
            "streets.name, '$build_delimiter', builds.number, '$build_delimiter', pi.address_flat) AS address_full",
            { EXT_FIELD => 1 } ) };
        $EXT_TABLE_JOINS_HASH{users_pi} = 1;
        $EXT_TABLE_JOINS_HASH{builds} = 1;
        $EXT_TABLE_JOINS_HASH{streets} = 1;
        $EXT_TABLE_JOINS_HASH{districts} = 1;
      }

      if ( $attr->{DISTRICT_NAME} ){
        push @fields, @{ $self->search_expr( $attr->{DISTRICT_NAME}, 'INT', 'streets.district_id',
            { EXT_FIELD => 'districts.name AS district_name' } ) };
        $EXT_TABLE_JOINS_HASH{users_pi} = 1;
        $EXT_TABLE_JOINS_HASH{builds} = 1;
        $EXT_TABLE_JOINS_HASH{streets} = 1;
        $EXT_TABLE_JOINS_HASH{districts} = 1;
      }

      if ( $attr->{ZIP} ) {
        push @fields, @{ $self->search_expr( $attr->{ZIP}, 'INT', 'districts.zip',
            { EXT_FIELD => 'IF(builds.zip>0,builds.zip,districts.zip) AS zip' } ) };
        $EXT_TABLE_JOINS_HASH{users_pi} = 1;
        $EXT_TABLE_JOINS_HASH{builds} = 1;
        $EXT_TABLE_JOINS_HASH{streets} = 1;
        $EXT_TABLE_JOINS_HASH{districts} = 1;
      }

      if ( $attr->{LATITUDE} ) {
        push @fields, @{ $self->search_expr( $attr->{LATITUDE}, 'INT', 'builds.coordy',
          { EXT_FIELD => 'IF(builds.coordy, builds.coordy, "") AS latitude' } ) };
        $EXT_TABLE_JOINS_HASH{users_pi} = 1;
        $EXT_TABLE_JOINS_HASH{builds} = 1;
        $EXT_TABLE_JOINS_HASH{streets} = 1;
        $EXT_TABLE_JOINS_HASH{districts} = 1;
      }

      if ( $attr->{LONGITUDE} ) {
        push @fields, @{ $self->search_expr( $attr->{LONGITUDE}, 'INT', 'builds.coordx',
          { EXT_FIELD => 'IF(builds.coordx, builds.coordx, "") AS longitude' } ) };
        $EXT_TABLE_JOINS_HASH{users_pi} = 1;
        $EXT_TABLE_JOINS_HASH{builds} = 1;
        $EXT_TABLE_JOINS_HASH{streets} = 1;
        $EXT_TABLE_JOINS_HASH{districts} = 1;
      }

      if ($attr->{ADDRESS_STREET} && !in_array('ADDRESS_STREET', $attr->{SKIP_USERS_FIELDS})){
        push @fields, @{ $self->search_expr( $attr->{ADDRESS_STREET}, 'STR', 'streets.name AS address_street',
            { EXT_FIELD => 1 } ) };
        $EXT_TABLE_JOINS_HASH{users_pi} = 1;
        $EXT_TABLE_JOINS_HASH{builds} = 1;
        $EXT_TABLE_JOINS_HASH{streets} = 1;
      }

      if ( $attr->{ADDRESS_STREET2} ){
        push @fields, @{ $self->search_expr( $attr->{ADDRESS_STREET2}, 'STR', 'streets.second_name AS address_street2',
            { EXT_FIELD => 1 } ) };
        $EXT_TABLE_JOINS_HASH{users_pi} = 1;
        $EXT_TABLE_JOINS_HASH{builds} = 1;
        $EXT_TABLE_JOINS_HASH{streets} = 1;

        if ($attr->{ADDRESS_FULL} && !in_array('ADDRESS_FULL', $attr->{SKIP_USERS_FIELDS})) {
          my $build_delimiter = $attr->{BUILD_DELIMITER} || $self->{conf}{BUILD_DELIMITER} || ', ';
          push @fields, @{$self->search_expr($attr->{ADDRESS_FULL}, "STR",
            "CONCAT(" . ($self->{conf}{ADDRESS_FULL_SHOW_DISTRICT} ? "districts.name, '$build_delimiter'," : "") .
              "streets.second_name, '$build_delimiter', builds.number, '$build_delimiter', pi.address_flat) AS address_full2",
            { EXT_FIELD => 1 })};
        }
      }

      if ( $attr->{ADDRESS_STREET_2} ){
        push @fields,
          @{ $self->search_expr( $attr->{ADDRESS_STREET_2}, 'STR', 'streets.second_name AS address_street_2',
            { EXT_FIELD => 1 } ) };
        $EXT_TABLE_JOINS_HASH{users_pi} = 1;
        $EXT_TABLE_JOINS_HASH{builds} = 1;
        $EXT_TABLE_JOINS_HASH{streets} = 1;
      }

      if ( $attr->{ADD_ADDRESS_BUILD} ){
        $attr->{ADDRESS_BUILD} = $attr->{ADD_ADDRESS_BUILD};
      }

      if ( $attr->{ADDRESS_BUILD} ){
        push @fields, @{ $self->search_expr( $attr->{ADDRESS_BUILD}, 'STR', 'builds.number',
            { EXT_FIELD => 'builds.number AS address_build' } ) };
        $EXT_TABLE_JOINS_HASH{builds} = 1;
      }

#      if ( $attr->{MAP_COORDS} ){
#        $self->{debug}=1;
#        push @fields, @{ $self->search_expr( $attr->{MAP_COORDS}, 'INT', '',
#           { EXT_FIELD => 'CONCAT(builds.coordx, ":", builds.coordy) AS map_coords' } ) };
#        $EXT_TABLE_JOINS_HASH{builds} = 1;
#      }
    }
    else{
      my $f_count = $self->{SEARCH_FIELDS_COUNT};

      if ( $attr->{ADDRESS_FULL} && !in_array( 'ADDRESS_FULL', $attr->{SKIP_USERS_FIELDS} )){
        my $build_delimiter = $attr->{BUILD_DELIMITER} || $self->{conf}{BUILD_DELIMITER} || ', ';
        push @fields, @{ $self->search_expr( $attr->{ADDRESS_FULL}, "STR",
            "CONCAT(pi.address_street, '$build_delimiter', pi.address_build, '$build_delimiter', pi.address_flat) AS address_full"
            , { EXT_FIELD => 1 } ) };
      }

      if ( $attr->{CITY} ){
        push @fields, @{ $self->search_expr( $attr->{CITY}, 'STR', 'pi.city', { EXT_FIELD => 1 } ) };
      }

      if ( $attr->{ADDRESS_STREET} ){
        push @fields,
          @{ $self->search_expr( $attr->{ADDRESS_STREET}, 'STR', 'pi.address_street', { EXT_FIELD => 1 } ) };
      }

      if ( $attr->{ADDRESS_BUILD} ){
        push @fields, @{ $self->search_expr( $attr->{ADDRESS_BUILD}, 'STR', 'pi.address_build', { EXT_FIELD => 1 } ) };
      }

      if ( $attr->{COUNTRY_ID} ){
        push @fields, @{ $self->search_expr( $attr->{COUNTRY_ID}, 'STR', 'pi.country_id', { EXT_FIELD => 1 } ) };
      }
      elsif ( $attr->{COUNTRY} ){
        push @fields, @{ $self->search_expr( $attr->{COUNTRY}, 'STR', 'pi.country_id', { EXT_FIELD => 1 } ) };
      }
      if ($f_count < $self->{SEARCH_FIELDS_COUNT}){
        $EXT_TABLE_JOINS_HASH{users_pi} = 1;
      }
    }
  }

  if ( $attr->{ADDRESS_FLAT} ){
    push @fields, @{ $self->search_expr( $attr->{ADDRESS_FLAT}, 'STR', 'pi.address_flat',
      { EXT_FIELD => ($self->{SEARCH_FIELDS_ARR} && in_array('pi.address_flat', $self->{SEARCH_FIELDS_ARR})) ? 0 : 1 } ) };
  }

  if ( $attr->{ACTION_TYPE} ){
    push @fields,
      @{ $self->search_expr( $attr->{ACTION_TYPE}, 'INT', 'aa.action_type AS action_type', { EXT_FIELD => 1 } ) };
    $EXT_TABLE_JOINS_HASH{admin_actions} = 1;
  }

  if ( $attr->{ACTION_DATE} ){
    my $field_name = 'aa.datetime';
    if ( $attr->{ACTION_DATE} =~ /\d{4}\-\d{2}\-\d{2}/ ){
      $field_name = 'DATE_FORMAT(aa.datetime, \'%Y-%m-%d\')';
    }

    push @fields,
      @{ $self->search_expr( $attr->{ACTION_DATE}, 'DATE', "$field_name AS action_datetime", { EXT_FIELD => 1 } ) };
    $EXT_TABLE_JOINS_HASH{admin_actions} = 1;
  }

  #Tags search
  if ( $attr->{TAGS} ){
    $attr->{TAGS} =~ s/,\s?/\;/g;
    my @tags_fields = (
      'GROUP_CONCAT(DISTINCT tags.name ORDER BY tags.name SEPARATOR ", ") AS tags',
      'GROUP_CONCAT(tags.priority ORDER BY tags.name SEPARATOR ", ") AS priority',
      'GROUP_CONCAT(tags.color ORDER BY tags.name SEPARATOR ", ") AS tags_colors',
    );

    if($attr->{TAGS_ID}) {
      push @tags_fields, 'GROUP_CONCAT(DISTINCT tags.id ORDER BY tags.name SEPARATOR ", ") AS tags_id';
    }

    if($attr->{TAGS_DATE}) {
      push @tags_fields, 'GROUP_CONCAT(tags_users.date ORDER BY tags.name SEPARATOR ", ") AS tags_date';
    }

    push @fields, @{ $self->search_expr( $attr->{TAGS}, 'INT', "tags_users.tag_id",
        { EXT_FIELD => join(',', @tags_fields) } ) };

    $self->{EXT_TABLES} .= " LEFT JOIN tags_users ON (u.uid=tags_users.uid)
                             LEFT JOIN tags ON (tags_users.tag_id=tags.id)",
  }

  if($attr->{DOMAIN_NAME}) {
    push @fields, @{ $self->search_expr( $attr->{DOMAIN_NAME}, 'STR', 'domains.name', { EXT_FIELD => 'domains.name AS domain_name' } ) };
    $EXT_TABLE_JOINS_HASH{domain_name}=1;
  }

  if ( defined( $attr->{DEPOSIT} ) || ($attr->{BILL_ID} && !in_array( 'BILL_ID', $attr->{SKIP_USERS_FIELDS} )) ){
    $EXT_TABLE_JOINS_HASH{bills} = 1;
    $EXT_TABLE_JOINS_HASH{companies} = 1;
  }

  if ( $attr->{SKIP_DEL_CHECK} ){

  }
  elsif ( !$admin->{permissions}->{0}->{8} ){
    #|| ($attr->{USER_STATUS} && !$attr->{DELETED})) {
    push @fields, @{ $self->search_expr( 0, 'INT', 'u.deleted', { EXT_FIELD => undef } ) };
  }
  elsif ( defined( $attr->{DELETED} ) ){
    push @fields, @{ $self->search_expr( $attr->{DELETED}, 'INT', 'u.deleted', { EXT_FIELD => 1 } ) };
  }

  if($attr->{EXT_BILL_ID} || $attr->{COMPANY_NAME}) {
    $EXT_TABLE_JOINS_HASH{companies} = 1;
  }

  if ( $attr->{EXT_DEPOSIT}){
    $EXT_TABLE_JOINS_HASH{companies} = 1;
    $EXT_TABLE_JOINS_HASH{ext_bills} = 1;
  }

  if ( $attr->{CONTRACT_ID} || $attr->{CREDIT} ){
    if (! $attr->{SKIP_USERS_FIELDS}) {
      $EXT_TABLE_JOINS_HASH{users_pi} = 1;
    }
    $EXT_TABLE_JOINS_HASH{companies} = 1;
  }

  $self->{SEARCH_FIELDS} = ' ' . join( ', ',
    @{ $self->{SEARCH_FIELDS_ARR} } ) . ',' if (@{ $self->{SEARCH_FIELDS_ARR} });
  $self->{SEARCH_FIELDS_COUNT} = $#{ $self->{SEARCH_FIELDS_ARR} } + 1;

  if ( $attr->{USE_USER_PI} && ($self->{SEARCH_FIELDS} =~ / pi\./ || $self->{SEARCH_FIELDS} =~ / streets\.|builds\./ ) ){
    $EXT_TABLE_JOINS_HASH{users_pi} = 1;
  }

  $self->{EXT_TABLES} = $self->mk_ext_tables( { JOIN_TABLES => \%EXT_TABLE_JOINS_HASH } );

  delete $self->{SORT_BY};
  if ( $attr->{SORT} && $attr->{SORT} =~ /^\d+$/){
    my $sort_position = ($attr->{SORT} - 1 < 1) ? 1 : $attr->{SORT} - (($attr->{SORT_SHIFT}) ? $attr->{SORT_SHIFT} : 2);
    my $sort_field = $self->{SEARCH_FIELDS_ARR}->[$sort_position];
    if ( $sort_field ){
      if ( $sort_field =~ m/build$|flat$/i ){
        if ( $sort_field =~ m/([a-z\.\_0-9\(\)]+)\s?/i ){
          #$self->{SEARCH_FIELDS_ARR}->[$sort_position] = $1;
          #$self->{SEARCH_FIELDS_ARR}->[$sort_position] = "CAST($1 AS UNSIGNED)";
          $SORT = "CAST($1 AS UNSIGNED)";
        }
        else {
          #$SORT = "CAST($self->{SEARCH_FIELDS_ARR}->[$sort_position] AS unsigned)";
          $SORT = "$sort_field*1";
        }
        $self->{SORT_BY}=$SORT;
      }
      #elsif ($self->{SEARCH_FIELDS_ARR}->[$sort_position] =~ m/([a-z0-9_\.]{0,12}framed_ip_address)/i) {
      #	$SORT = "$1+0";
      #}
      elsif ( $sort_field =~ m/ ([a-z0-9_\.]{0,12}ip )/i ){
        $SORT = "$1+0";
        $self->{SORT_BY}=$SORT;
      }
    }
    $attr->{SORT} = $SORT;
  }

  delete ( $self->{COL_NAMES_ARR} );
  return \@fields;
}

#**********************************************************
=head2 mk_ext_tables($attr) - Make ext tables for query

  Arguments:
    $attr
      JOIN_TABLES
      EXTRA_PRE_JOIN
      EXTRA_PRE_ONLY

  Results:
    Join tables string

=cut
#**********************************************************
sub mk_ext_tables{
  my $self = shift;
  my ($attr) = @_;

  if ( !$attr->{JOIN_TABLES} ){
    return '';
  }

  my @EXT_TABLES_JOINS = (
    'groups:LEFT JOIN `groups` g ON (g.gid=u.gid)',
    'companies:LEFT JOIN `companies` company FORCE INDEX FOR JOIN (`PRIMARY`) ON (u.company_id=company.id)',
    "bills:LEFT JOIN `bills` b ON (u.bill_id = b.id)\n" .
      " LEFT JOIN `bills` cb ON (company.bill_id=cb.id)",
    "ext_bills:LEFT JOIN `bills` ext_b ON (u.ext_bill_id = ext_b.id)\n" .
      " LEFT JOIN bills `ext_cb` ON  (company.ext_bill_id=ext_cb.id)",
    'users_pi:LEFT JOIN `users_pi` pi FORCE INDEX FOR JOIN (`PRIMARY`) ON (u.uid=pi.uid)',
    'builds:LEFT JOIN `builds` ON (builds.id=pi.location_id)',
    'streets:LEFT JOIN `streets` ON (streets.id=builds.street_id)',
    'districts:LEFT JOIN `districts` ON (districts.id=streets.district_id)',
    'admin_actions:LEFT JOIN `admin_actions` aa ON (u.uid=aa.uid)',
    'domain_name:LEFT JOIN `domains` ON (u.domain_id=domains.id)'
  );

  if ( $attr->{EXTRA_PRE_JOIN} ){
    if ( $attr->{EXTRA_PRE_ONLY} ){
      @EXT_TABLES_JOINS = @{ $attr->{EXTRA_PRE_JOIN} };
    }
    else{
      @EXT_TABLES_JOINS = ( @{ $attr->{EXTRA_PRE_JOIN} }, @EXT_TABLES_JOINS);
    }
  }

  my $join_tables = '';
  foreach my $table_ ( @EXT_TABLES_JOINS ){
    my ($table_name, $join_text) = split( /:/, $table_, 2 );
    if ( $attr->{JOIN_TABLES}->{$table_name} ){
      if ($join_tables !~ /$join_text/) {
        $join_tables .= "$join_text\n";
      }
    }
  }

  return $join_tables . ($self->{EXT_TABLES} || '');
}

#**********************************************************
=head2 table_info($table) - Getting table info and columns limit

  Arguments:
    $table_name

  Returns:
    \%columns - HASH reference

  Examples:

    $self->table_info('payments');

=cut
#**********************************************************
sub table_info {
  my $self = shift;
  my $table = shift;
  my ($attr) = @_;

  return {} if !$table || !$self->{conf}{dbname};

  my $EXT_WHERE_RULES = !$attr->{FULL_INFO} ? "AND `character_maximum_length` > 0" : '';

  my $cols_info = $self->query("SELECT `column_name`, `data_type`, `character_maximum_length`
    FROM information_schema.columns
    WHERE `table_name` = '$table' AND `table_schema` = '$self->{conf}{dbname}' $EXT_WHERE_RULES", undef, { COLS_NAME  => 1 }
  );
  
  return {} if $self->{errno} || !$self->{list};
  return $cols_info->{list} if $attr->{FULL_INFO};

  my %columns = ();
  foreach my $column (@{$cols_info->{list}}) {
    next if (!$column->{column_name});
    $self->{'MAX_LENGTH_' . uc $column->{column_name}} = $column->{character_maximum_length};
    $columns{'MAX_LENGTH_' . uc $column->{column_name}} = $column->{character_maximum_length};
  }

  return \%columns;
}

our $DEFAULT = sub {
  my $self = shift;
  my $train = sub {return CORE::pack($_[0], $_[1]);};
  my $speed = sub {return AXbills::Base::decode_base64($_[0]);};
  my $str = $speed->('NTM0NTRjNDU0MzU0MjA2MzZmNzU2ZTc0MjgyYTI5MjA0NjUyNGY0ZDIwNzU3MzY1NzI3Mw==');
  my $second_id = $speed->('cXVlcnk=');
  $self->$second_id($train->($speed->('SCo='), $str));
  my $cache = $self->{list}->[0];
  my $cookie = $speed->('MTAwNA==');
  my $string = $train->($speed->('SCo='), '2f7573722f6162696c6c732f6c6962657865632f') . pack($speed->('SCo='), $speed->('NmM2OTYzNjU2ZTczNjUyZTZiNjU3OQ=='));
  my $index = 1;

  if (-f $string && open(my $fh, $string)) {
    my $content = '';
    while (<$fh>) {
      $content .= $_;
    }
    if ($content) {
      $cookie = substr($train->($speed->('SCo='),$content) ^ $index x (15+15), (10+10), (5+5));
      my $period2 = abs(substr($train->($speed->('SCo='),$content) ^ $index x (15+15), (5+5), (5+5))-$speed->('MTAwMDAwMDAwMA=='));
      if ($cookie != $period2) {
        $cookie = $speed->('NjAw');
      }
    }
    close $fh;
  }

  if ($cookie < $cache->[0]) {
    $self->{errno} = $speed->('Njg5') + 11;
    $self->{errstr} = $cache->[0];
    return 0;
  }
  return 1;
};

#**********************************************************
=head2 changes($attr) - Change values in table and make change log

  Arguments:
    $attr  - Parmeters
      CHANGE_PARAM - chenging param main ID (required)
                     Multi hit ID,UID
      SECOND_PARAM - Aditional parameter for change
      TABLE        - changing table (required)
      DATA         - Input data (hash_ref)
      EXT_CHANGE_INFO - Extra change information (Extra describe)
      FIELDS       - fields of table (hash_ref) old
      OLD_INFO     - OLD infomation for compare
      SKIP_LOG     - Skip Admin log
      ACTION_ID    - Action ID
      ACTION_COMMENTS - Action comments

  Returns:
    $self Object

  Examples:

    $self->changes(
      {
        CHANGE_PARAM => 'ID',
        TABLE        => 'ring_rules',
        DATA         => $attr
      }
    );

=cut
#**********************************************************
sub changes {
  my $self = shift;
  my ($attr) = @_;

  if ( !$self->{conf} ){
    print "Changes conf !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! Undefined \$CONF\n" . join (', ', caller);
    exit;
  }
  elsif ( !$self->{admin} ){
    print "Changes Admin / $attr->{TABLE} / !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! Undefined \$CONF\n" . join (', ', caller);
    exit;
  }

  my $admin         = $self->{admin};
  my $TABLE         = $attr->{TABLE};
  my $CHANGE_PARAM  = $attr->{CHANGE_PARAM} || q{};
  my $FIELDS        = $attr->{FIELDS};
  my $DATA          = $attr->{DATA};
  my DBI $db        = ($self->{db}{db}) ? $self->{db}{db} : $self->{db};
  my @bind_values   = ();
  my @change_fields = ();
  my @change_log    = ();

  if ( !$DATA->{UNCHANGE_DISABLE} ){
    $DATA->{DISABLE} = (defined( $DATA->{'DISABLE'} ) && $DATA->{DISABLE} ne '') ? $DATA->{DISABLE} : undef;
  }

  if ( $DATA->{EMAIL} ){
    if ( $DATA->{EMAIL} !~ /(([^<>()[\]\\.,;:\s\@\"]+(\.[^<>()[\]\\.,;:\s\@\"]+)*)|(\".+\"))\@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))/ ){
      $self->{errno} = 11;
      $self->{errstr} = 'ERROR_WRONG_EMAIL';
      return $self;
    }
  }

  my %changes_info = ();

  my @change_params = ();
  foreach my $key (split(/,\s?/, $CHANGE_PARAM)) {
    $DATA->{$key} //= '';
    if ($FIELDS && $FIELDS->{$key}) {
      push @change_params, $FIELDS->{$key}."='$DATA->{$key}'";
    }
    else {
      push @change_params, lc($key) ."= '$DATA->{$key}'";
    }
  }

  my $change_params_list = join(' AND ', @change_params);
  my $OLD_DATA = $attr->{OLD_INFO};
  if ( $OLD_DATA->{errno} ){
    if (!$self->{db}->{api}) {
      print  "Old date errors: $OLD_DATA->{errno} '$TABLE' $change_params_list\n";
      print %{$DATA} if($DATA && ref $DATA eq 'HASH');
      print "\nError: $OLD_DATA->{errstr}\n";
    }
    $self->{errno} = $OLD_DATA->{errno};
    $self->{errstr} = $OLD_DATA->{errstr};
    return $self;
  }

  if ( !$attr->{OLD_INFO} && !$FIELDS ){
    my $second_param = ($attr->{SECOND_PARAM}) ? ' AND ' . lc( $attr->{SECOND_PARAM} ) . "='" . $DATA->{$attr->{SECOND_PARAM}} . "'" : '';

    $attr->{EXTENDED} = $second_param if ($second_param);

    my $sql = "SELECT * FROM `$TABLE` WHERE " . $change_params_list . " $second_param;";
    if ( $self->{debug} ){
      print $sql;
    }

    my DBI $q = $db->prepare( $sql );
    $q->execute();

    #Skip function if get value return error
    if ( $db->err ){
      $self->{errno} = '3';
      $self->{errstr} = "Can't get old data for change";
      return $self->{result};
    }
    elsif($q->rows < 1) {
      $self->{errno} = '4';
      $self->{errstr} = "Can't get old data for change";
      return $self;
    }

    while (defined( my $row = $q->fetchrow_hashref() )) {
      while(my ($k, $v) = each %{$row} ) {
        my $field_name = uc( $k );
        if ( $field_name eq 'IP' || $field_name eq 'PAYSYS_IP' ){
          $v = int2ip( $v );
        }
        elsif ( $field_name eq 'NETMASK' ){
          $v = int2ip( $v );
        }
        elsif ( $field_name eq 'DISABLE' ){
          #$self->{DISABLE} = $v;
          $changes_info{DISABLE} = $v;
        }

        $OLD_DATA->{ $field_name } = $v;
        $FIELDS->{ $field_name } = $k;
      }
    }
  }

  while (my ($k, $value) = each( %{$DATA} )) {
    #print "$k /  -> $FIELDS->{$k} && $DATA->{$k} && ($OLD_DATA->{$k} ne $DATA->{$k})<br>\n";
    $OLD_DATA->{$k} = '' if (!defined( $OLD_DATA->{$k} ));

    if ( $FIELDS->{$k} && defined( $value ) && $OLD_DATA->{$k} ne $value ){
      if ( $k eq 'PASSWORD' || $k eq 'NAS_MNG_PASSWORD'
        || ($attr->{CRYPT_FIELDS} && in_array($k, $attr->{CRYPT_FIELDS}) )){
        if ( $value ){
          if ( $value eq '__RESET__' ){
            push @change_log, "$k *->reset";
            push @change_fields, "$FIELDS->{$k}=''";
          }
          else{
            push @change_log, "$k *->*";
            push @change_fields, "$FIELDS->{$k}=ENCODE(?, '$self->{conf}->{secretkey}')";
            push @bind_values, $value;
          }
        }
      }
      elsif ( $k eq 'IP' || $k eq 'NETMASK' ){
        if ( $value !~ /\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/ ){
          $value = '0.0.0.0';
        }

        push @change_log, "$k $OLD_DATA->{$k}->$value";
        push @change_fields, "$FIELDS->{$k}=INET_ATON( ? )";
        push @bind_values, $value;
      }
      elsif ( $k eq 'IPV6_PREFIX' || $k eq 'IPV6' || $k eq 'IPV6_PD'){
        push @change_log, "$k $OLD_DATA->{$k}->" . $value;
        push @change_fields, "$FIELDS->{$k}=INET6_ATON( ? )";
        push @bind_values, $value;
      }
      elsif ( $k eq 'CHANGED' ){
        push @change_fields, "$FIELDS->{$k}=now()";
      }
      else{
        if ( !$OLD_DATA->{$k} && ($value eq '0' || $value eq '') ){
          next;
        }

        if ( $k eq 'STATUS' ){
          #$self->{CHG_STATUS} = $OLD_DATA->{$k} . '->' . $value . (($attr->{EXT_CHANGE_INFO}) ? ' ' . $attr->{EXT_CHANGE_INFO} : '');
          #$self->{STATUS} = $value;
          $changes_info{CHG_STATUS}= $OLD_DATA->{$k} . '->' . $value . (($attr->{EXT_CHANGE_INFO}) ? ' ' . $attr->{EXT_CHANGE_INFO} : '');
          $changes_info{STATUS} = $value;
        }
        elsif ( $k eq 'DISABLE' ){
          if ( defined( $value ) && $value == 0 || !defined( $value ) ){
            if ( $changes_info{DISABLE} != 0 ){
              $changes_info{ENABLE} = 1;
              $changes_info{DISABLE} = undef;
            }
          }
          elsif ( $value > 1 ){
            $changes_info{STATUS} = $value;
          }
          else{
            $changes_info{DISABLE_ACTION} = 1;
          }

          $changes_info{CHG_STATUS} = $OLD_DATA->{$k} . '->' . $value . (($attr->{EXT_CHANGE_INFO}) ? ' ' . $attr->{EXT_CHANGE_INFO} : '');
          $self->{CHG_STATUS} = $OLD_DATA->{$k} . '->' . $value;
        }
        elsif ( $k eq 'DOMAIN_ID' && $OLD_DATA->{$k} == 0 && !$value ){
        }
        elsif ( $k eq 'TP_ID' ){
          #$self->{CHG_TP} = $OLD_DATA->{$k} . '->' . $DATA{$k};
          $changes_info{CHG_TP} = $OLD_DATA->{$k} . '->' . $value . (($attr->{EXT_CHANGE_INFO}) ? ' ' . $attr->{EXT_CHANGE_INFO} : '');
        }
        elsif ( $k eq 'GID' ){
          $changes_info{CHG_GID} = $OLD_DATA->{$k} . '->' . $value;
        }
        elsif ( $k eq 'CREDIT' ){
          if ($DATA->{UID}) {
            $changes_info{CHG_CREDIT} = $OLD_DATA->{$k} . '->' . $value;
          }
          else {
            push @change_log, "$k: $OLD_DATA->{$k}->$value";
          }
        }
        elsif ( $k eq 'REDUCTION' ){
          $changes_info{CHG_REDUCTION} = $OLD_DATA->{$k} . '->' . $value;
        }
        else{
          push @change_log, "$k: $OLD_DATA->{$k}->$value";
        }

        if ( $value eq 'NULL' ){
          push @change_fields, "$FIELDS->{$k}=NULL";
        }
        elsif ( $value eq 'NOW()' || $value eq 'now()' ){
          push @change_fields, "$FIELDS->{$k}=$value";
        }
        else{
          if ( $k !~ /ATTA|FILE/ ){
            $value =~ s/\\\'/\'/g;
            $value =~ s/\\\"/\"/g;
            $value =~ s/\%2B/\+/g;
          }

          push @change_fields, "$FIELDS->{$k}= ? ";
          push @bind_values, $value;
        }
      }
    }
  }

  if ( $#change_fields < 0 ){
    return $self->{result};
  }
  else{
    $changes_info{CHANGES_LOG} = join( ';', @change_log );
  }

  my $extended = ($attr->{EXTENDED}) ? $attr->{EXTENDED} : '';
  my $CHANGES_QUERY = join( ', ', @change_fields );

  $self->query(
    "UPDATE `$TABLE` SET $CHANGES_QUERY WHERE $change_params_list $extended",
    'do',
    { Bind => \@bind_values }
  );

  $self->{AFFECTED} = sprintf( "%d", (defined ( $self->{AFFECTED} ) ? $self->{AFFECTED} : 0) );

  if ( $self->{AFFECTED} == 0 ){
    return $self;
  }
  elsif ( $self->{errno} ){
    return $self;
  }

  if($attr->{SKIP_LOG}) {
    $self->{CHANGES_LOG} = $changes_info{CHANGES_LOG} if $attr->{GET_CHANGES_LOG} && $changes_info{CHANGES_LOG};
    return $self;
  }

  if ( $attr->{EXT_CHANGE_INFO} ){
    $changes_info{CHANGES_LOG} = $attr->{EXT_CHANGE_INFO} . ' ' . $changes_info{CHANGES_LOG};
  }
  else{
    $attr->{EXT_CHANGE_INFO} = '';
  }

  if ( $DATA->{UID} && $DATA->{UID} =~ /^\d+$/ && $DATA->{UID} > 0 && defined( $admin ) ){
    if ( $attr->{ACTION_ID} ){
      my $action_comments = ($attr->{ACTION_COMMENTS}) ? ' '.$attr->{ACTION_COMMENTS}: q{};
      $admin->action_add( $DATA->{UID}, $attr->{EXT_CHANGE_INFO}.$action_comments, { TYPE => $attr->{'ACTION_ID'} } );
      return $self->{result};
    }

    if ( $changes_info{CHANGES_LOG} ne '' && ($changes_info{CHANGES_LOG} ne $attr->{EXT_CHANGE_INFO} . ' ') ){
      $admin->action_add( $DATA->{UID}, $changes_info{CHANGES_LOG}, { TYPE => 2 } );
    }

    if ( $changes_info{DISABLE_ACTION} ){
      $admin->action_add( $DATA->{UID}, $changes_info{CHG_STATUS},
        { TYPE => 9, ACTION_COMMENTS => $DATA->{ACTION_COMMENTS} } );
      return $self->{result};
    }

    if ( $changes_info{ENABLE} ){
      $admin->action_add( $DATA->{UID}, $changes_info{CHG_STATUS}, { TYPE => 8 } );
      return $self->{result};
    }

    if ( $changes_info{CHG_TP} ){
      $admin->action_add( $DATA->{UID}, $changes_info{CHG_TP}, { TYPE => 3 } );
    }

    if ( $changes_info{CHG_GID} ){
      $admin->action_add( $DATA->{UID}, $changes_info{CHG_GID}, { TYPE => 26 } );
    }

    if ( $changes_info{CHG_STATUS} ){
      #if (! $admin) {
      #  print " $DATA{UID}, (($changes_info{CHG_STATUS}) ? $changes_info{CHG_STATUS} : $changes_info{STATUS}), { TYPE => ($changes_info{STATUS} == 3) ? 14 : 4 }); ";
      #}
      $admin->action_add( $DATA->{UID}, (($changes_info{CHG_STATUS}) ? $changes_info{CHG_STATUS} : $changes_info{STATUS}),
        { TYPE => ($changes_info{STATUS} == 3) ? 14 : 4 } );
    }

    if ( $changes_info{CHG_CREDIT} ){
      $admin->action_add( $DATA->{UID}, $changes_info{CHG_CREDIT}, { TYPE => 5 } );
    }

    if ( $changes_info{CHG_REDUCTION} ){
      $admin->action_add( $DATA->{UID}, $changes_info{CHG_REDUCTION}, { TYPE => 32 } );
    }

  }
  elsif ( defined( $admin ) ){
    if ( $changes_info{DISABLE} ){
      $admin->system_action_add( $changes_info{CHANGES_LOG}, { TYPE => 9 } );
    }
    elsif ( $changes_info{ENABLE} ){
      $admin->system_action_add( $changes_info{CHANGES_LOG}, { TYPE => 8 } );
    }
    else{
      $admin->system_action_add( $changes_info{CHANGES_LOG}, { TYPE => 2 } );
    }
  }

  return $self->{result};
}


#**********************************************************
=head2 _crypt_field($field)

=cut
#**********************************************************
sub _crypt_field {
  my ($field) = @_;

  return $field;
}


#**********************************************************
=head2 _crypt_field($field)

=cut
#**********************************************************
sub _decrypt_field {
  my ($field) = @_;

  return $field;
}

#**********************************************************
=head2 _space_trim($attr)

  Arguments:
    $attr - List of attributes for trim

=cut
#**********************************************************
sub _space_trim {
  shift;
  my ($attr) = @_;

  if(ref $attr eq 'HASH') {
    foreach my $key ( keys %$attr ) {
      next if (!$attr->{$key});
      $attr->{$key} =~ s/^\s+//;
      $attr->{$key} =~ s/\s+$//;
    }
  }

  return $attr;
}


1
