package main;

=head1 NAME

AXbills::mysql::main - DB manipulation functions

=cut

use strict;
use DBI;
use AXbills::Base qw(int2ip in_array);

our $VERSION = 7.10;

my $CONF;
my $SORT = 1;
my $sql_errors = '/usr/axbills/var/log/sql_errors';


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
=head2 query2($query, $type, $attr) - Query maker

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

      $self->query2("DELETE FROM users WHERE uid= ?;", 'do', { Bind => [ 100 ] });

      Result:

        $self->{AFFECTED}  - Total deleted rows


    Show listing:

      $self->query2("SELECT id AS login, uid FROM users LIMIT 10;", undef, { COLS_NAME => 1 });

      Result:

        $self->{TOTAL}  - Total rows
        $self->{list}   - ARRAY of hash_refs

    Make info atributes

       $self->query2("SELECT id AS login, gid, credit FROM users WHERE uid = ? ;", undef, { INFO => 1, Bind => [ 100 ] });

      Result:

        $self->{LOGIN}
        $self->{GID}
        $self->{CREDIT}

    LIST2HASH listing

      $self->query2("SELECT id AS login, gid, credit FROM users WHERE uid = ? ;", undef, { LIST2HASH => 'login,gid' });

      $self->{list_hash} - Hash ref

=cut
#**********************************************************
sub query2{
  my $self = shift;
  my ($query, $type, $attr) = @_;

  #if(! $CONF){
  #  print "Query2 !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! Undefined \$CONF\n";
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
        Log::log_print( undef, 'LOG_ERR', '', "\n-----". ($self->{queries_count} || q{}) ."------\n$query\n",
          { NAS => 0, LOG_FILE => "/tmp/sql_debug" } );
      }
      #sequence
      elsif ( $self->{db}->{db_debug} > 1 ){
        push @{ $self->{db}->{queries_list} }, $query;
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

  if ( !$db ){
    require Log;
    Log->import( 'log_print' );
    $self->{sql_errno} = 0 if (!$self->{sql_errno});
    $self->{sql_errstr} = '' if (!$self->{sql_errstr});

    Log::log_print( undef, 'LOG_ERR', '',
      "Query:\n$query\n Error:$self->{sql_errno}\n Error str:$self->{sql_errstr}\nundefined \$db",
      { NAS => 0, LOG_FILE => ( -w $sql_errors) ? $sql_errors : '/tmp/sql_errors' } );
    return $self;
  }

  if ( defined( $attr->{test} ) ){
    return $self;
  }

  $self->{AFFECTED} = 0;
  my $q;

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

      $self->{TOTAL} = $#{ $attr->{MULTI_QUERY}  } + 1;
      return $self;
    }
    else{
      $q->execute( @{ $attr->{Bind} } );
      $self->{TOTAL} = $q->rows;
    }
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
      require Log;
      Log->import( 'log_print' );
      Log::log_print( undef, 'LOG_ERR', '',
        "index:". $attr->{index} ."\n$query\n --$self->{sql_errno}\n --". $self->{sql_errstr}."\n --AutoCommit: ". $db->{AutoCommit}."\n"
        , { NAS => 0, LOG_FILE => ( -w $sql_errors) ? $sql_errors : '/tmp/sql_errors' } );
    }
    return $self;
  }

  if ( $self->{TOTAL} > 0 ){
    my @rows = ();

    if ( $attr->{COLS_NAME} ){
      push @{ $self->{COL_NAMES_ARR} }, @{ $q->{NAME} };

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
      my ($key, $val) = split( /,\s?/, $attr->{LIST2HASH} );
      my %list_hash = ();

      while (my $row = $q->fetchrow_hashref()) {
        $list_hash{$row->{$key}} = $row->{$val};
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
    if ( $q && defined( $q->{NAME} ) && ref $q->{NAME} eq 'ARRAY' ){
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

  my $db = $self->{db};

  if ( $self->{db}->{db} ){
    $db = $self->{db}->{db};
  }

  my $q = $db->column_info( undef, undef, $table, '%' );

  my @inserts_arr = ();
  my @values_arr = ();

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
      elsif ( $column eq 'IPV6' || $column eq 'IPV6_PD' || $column eq 'IPV6_PREFIX' ){
        push @inserts_arr, "$row->{COLUMN_NAME}=INET6_ATON( ? )";
      }
      elsif ( $values->{$column} =~ /^INET_ATON\(/i ){
        push @inserts_arr, "$row->{COLUMN_NAME}=$values->{$column}";
        next;
      }
      elsif ( $values->{$column} =~ m/^ENCODE\(/i ){
        push @inserts_arr, "$row->{COLUMN_NAME}=$values->{$column}";
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
      push @values_arr, $values->{$column};
    }
    elsif ( defined( $values->{$column} ) ){
      if ( $column eq 'COMMENTS' ){
        push @inserts_arr, "$row->{COLUMN_NAME}= ? ";
        push @values_arr, "$values->{$column}";
      }
      elsif ( $values->{$column} ne '' && $values->{$column} == 0 ){
        push @inserts_arr, "$row->{COLUMN_NAME}= ? ";
        push @values_arr, "$values->{$column}";
      }
    }
  }

  return $self if ($#inserts_arr < 0);

  my $sql = (($attr->{REPLACE}) ? 'REPLACE' : 'INSERT') . " INTO `$table` SET " . join( ",\n ", @inserts_arr );

  return $self->query2( $sql, 'do', { Bind => \@values_arr } );
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
    $self->query2( "TRUNCATE `$table`;", 'do' );
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

  $self->query2( "DELETE FROM `$table` WHERE " . join( ' AND ', @WHERE_FIELDS ),
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

  my @user_fields = (
    'LOGIN',
    'FIO',
    'DEPOSIT',
    'CREDIT',
    'CREDIT_DATE',
    'PHONE',
    'EMAIL',
    'ADDRESS_FLAT',
    'PASPORT_DATE',
    'PASPORT_NUM',
    'PASPORT_GRANT',
    'CITY',
    'ZIP',
    'GID',
    'COMPANY_ID',
    'CONTRACT_ID',
    'CONTRACT_SUFIX',
    'CONTRACT_DATE',
    'EXPIRE',
    'REDUCTION',
    'REDUCTION_DATE',
    'COMMENTS',
    'BILL_ID',
    'LOGIN_STATUS',
    'DOMAIN_ID',
    'PASSWORD',
    'ACCEPT_RULES',
    'ACTIVATE',
    'EXPIRE',
    'REGISTRATION',
    'LAST_PAYMENT',
    'LAST_FEES',
    'EXT_BILL_ID',
    'EXT_DEPOSIT',
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
        push @{$self->{SEARCH_VALUES}}, "'$data->{$param}'";
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
      @val_arr = split( /,/, $value )
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
    elsif ( $v =~ s/^!// ){
      $expr = ' <> ';
    }
    elsif ( $type eq 'STR' ){
      $expr = '=';
      if ( $v =~ /\\\*/ ){
        $v = '*';
      }
      else{
        if ( $v =~ s/\*/\%/g ){
          $expr = ' LIKE ';
        }
      }
    }
    elsif ( $v =~ s/^([<>=]{1,2})// ){
      $expr = $1;
    }

    if ( $type eq 'IP' ){
      if ( $value =~ m/\*/g ){
        $value =~ s/[<>]+//;
        my ($i, $first_ip, $last_ip);
        my @p = split( /\./, $value );
        for ( $i = 0; $i < 4; $i++ ){
          if (length($p[$i]) < 3 && $p[$i] =~ /(\d{0,2})\*/ ){
            $first_ip .= $1 || '0';
            $last_ip .= $1 || '255';
          }
          else{
            $p[$i] =~ s/\*//g;
            $first_ip .= $p[$i] || 0;
            $last_ip .= $p[$i] || 255;
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

    push @result_arr, "$field$value" if ($field);
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
      print "--- $self->{conf} // Undefined \$CONF  $package, $filename, $line !!!!!!!!!!!!!!!!!!\n";
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
    LOGIN_STATUS   => 'INT:u.disable AS login_status',
    REGISTRATION   => 'DATE:u.registration',

    COMMENTS       => 'STR:pi.comments',
    FIO            => 'STR:pi.fio',
    PHONE          => 'STR:pi.phone',
    EMAIL          => 'STR:pi.email',
    ACCEPT_RULES   => 'INT:pi.accept_rules',

    PASPORT_DATE   => 'DATE:pi.pasport_date',
    PASPORT_NUM    => 'STR:pi.pasport_num',
    PASPORT_GRANT  => 'STR:pi.pasport_grant',
    #CONTRACT_ID   => 'STR:if(u.company_id=0, concat(pi.contract_sufix,pi.contract_id), concat(company.contract_sufix,company.contract_id)) AS contract_id',
    CONTRACT_ID    => 'STR:IF(u.company_id=0, concat(pi.contract_id), concat(company.contract_id)) AS contract_id',
    CONTRACT_SUFIX => 'STR:pi.contract_sufix',
    CONTRACT_DATE  => 'DATE:pi.contract_date',

    ACTIVATE       => 'DATE:u.activate',
    EXPIRE         => 'DATE:u.expire',

    #CREDIT        => 'INT:u.credit',
    CREDIT         => 'INT:if(u.credit > 0, u.credit, if(company.id IS NULL, 0, company.credit)) AS credit',
    CREDIT_DATE    => 'DATE:u.credit_date',
    REDUCTION      => 'INT:u.reduction',
    REDUCTION_DATE => 'INT:u.reduction_date',
    COMMENTS       => 'STR:pi.comments',
    BILL_ID        => 'INT:if(company.id IS NULL,b.id,cb.id) AS bill_id',
    PASSWORD       => "STR:DECODE(u.password, '$CONF->{secretkey}') AS password",
    EXT_DEPOSIT    => 'INT:if(company.id IS NULL,ext_b.deposit,ext_cb.deposit) AS ext_deposit',
    EXT_BILL_ID    => 'INT:IF(company.id IS NULL, u.ext_bill_id, company.ext_bill_id) AS ext_bill_id',
    LAST_PAYMENT   => 'INT:(SELECT max(p.date) FROM payments p WHERE p.uid=u.uid) AS last_payment',
    LAST_FEES      => 'INT:(SELECT max(f.date) FROM fees f WHERE f.uid=u.uid) AS last_fees',
    #ADDRESS_FLAT  => 'STR:pi.address_flat',
  );

  if ( $attr->{DEPOSIT} && $attr->{DEPOSIT} ne '_SHOW' ){
    #$users_fields_hash{DEPOSIT} = 'INT:b.deposit'
    $users_fields_hash{DEPOSIT} = 'INT:IF(company.id IS NULL, b.deposit, cb.deposit) as deposit';
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
          { EXT_FIELD => in_array( $key, $attr->{EXT_FIELDS} ),
            NOTFILLED => ($attr->{'NOTFILLED_'.$key}) ? 1 : undef
          } ) };
      $filled{$key} = 1;
    }
    elsif ( !$info_field && $key =~ /^_/ ){
      $info_field = 1;
    }
  }

  #Info fields
  if ( $info_field && $self->can( 'config_list' ) ){
    my $list = $self->config_list( { PARAM => 'ifu*', SORT => 2 } );
    if ( $self->{TOTAL} > 0 ){
      foreach my $line ( @{$list} ){
        if ( $line->[0] =~ /ifu(\S+)/ ){
          my $field_name = $1;
          my $field_id   = uc($field_name);
          # $position, $type, $name
          my (undef, $type, undef) = split( /:/, $line->[1] );

          if ( defined( $attr->{uc( $field_name )} ) && $type == 4 ){
            push @fields,
              @{ $self->search_expr( $attr->{$field_id}, 'INT', "pi.$field_name", { EXT_FIELD => 1 } ) };
          }
          #Skip for bloab
          elsif ( $type == 5 ){
            next;
          }
          elsif ( $attr->{$field_id} ){
            if ( $type == 1 ){
              push @fields,
                @{ $self->search_expr( $attr->{$field_id}, 'INT', "pi.$field_name", { EXT_FIELD => 1 } ) };
            }
            elsif ( $type == 2 ){
              push @fields, @{ $self->search_expr( $attr->{$field_id}, 'INT', "pi.$field_name",
                  { EXT_FIELD => $field_name . '_list.name AS ' . $field_name } ) };
              $self->{EXT_TABLES} .= "LEFT JOIN $field_name" . "_list ON (pi.$field_name = $field_name" . "_list.id)";
            }
            elsif ( $type == 16 ){
              if($attr->{$field_id} && $attr->{$field_id} ne '_SHOW') {
                my ($sn_type, $info) = split( /, /, $attr->{$field_id} );
                push @fields, @{ $self->search_expr( "$sn_type*$info", 'STR', "pi.$field_name", { EXT_FIELD => 1 } ) };
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
      my @admin_gids = split( /, /, $admin->{GID} );
      my @attr_gids = split( /, /, $attr->{GIDS} );

      foreach my $attr_gid ( @attr_gids ){
        foreach my $admin_gid ( @admin_gids ){
          if ( $admin_gid == $attr_gid ){
            push @result_gids, $attr_gid;
            last;
          }
        }
      }

      $attr->{GIDS} = join( ', ', @result_gids );
    }

    if ($attr->{GIDS} ne '_SHOW'){
      push @fields, "u.gid IN ($attr->{GIDS})";
    }
  }
  elsif ( defined( $attr->{GID} ) && $attr->{GID} ne '' ){
    $attr->{GID} =~ s/,/;/g;
    push @fields, @{ $self->search_expr( $attr->{GID}, 'INT', 'u.gid',
        { EXT_FIELD => in_array( 'GID', $attr->{EXT_FIELDS} ) || ($attr->{GID} eq '_SHOW') ? 1 : undef } ) };
  }
  elsif ( $admin->{GID} ){
    push @fields, "u.gid IN ($admin->{GID})";
  }

  if ( $attr->{GROUP_NAME} ){
    push @fields,
      @{ $self->search_expr( "$attr->{GROUP_NAME}", 'STR', 'g.name', { EXT_FIELD => 'g.name AS group_name' } ) };

    $EXT_TABLE_JOINS_HASH{groups} = 1;

    if ( defined( $attr->{DISABLE_PAYSYS} ) ){
      push @fields, @{ $self->search_expr( "$attr->{DISABLE_PAYSYS}", 'INT', 'g.disable_paysys', { EXT_FIELD => 1 } ) };
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
    push @fields, @{ $self->search_expr( $attr->{LOCATION_ID}, 'INT', 'pi.location_id', { EXT_FIELD =>
          'streets.name AS address_street, builds.number AS address_build, pi.address_flat, builds.id AS build_id' } ) };
    $EXT_TABLE_JOINS_HASH{users_pi} = 1;
    $EXT_TABLE_JOINS_HASH{builds} = 1;
    $EXT_TABLE_JOINS_HASH{streets} = 1;
    $self->{SEARCH_FIELDS_COUNT} += 3;
  }
  elsif ( $attr->{STREET_ID} ){
    push @fields, @{ $self->search_expr( $attr->{STREET_ID}, 'INT', 'builds.street_id',
        { EXT_FIELD => 'streets.name AS address_street, builds.number AS address_build' } ) };

    $EXT_TABLE_JOINS_HASH{users_pi} = 1;
    $EXT_TABLE_JOINS_HASH{builds} = 1;
    $EXT_TABLE_JOINS_HASH{streets} = 1;
    $self->{SEARCH_FIELDS_COUNT} += 1;
  }
  elsif ( $attr->{DISTRICT_ID} ){
    push @fields, @{ $self->search_expr( $attr->{DISTRICT_ID}, 'INT', 'streets.district_id',
        { EXT_FIELD => 1 } ) }; # 'districts.name AS district_name' }) };

    $EXT_TABLE_JOINS_HASH{users_pi} = 1;
    $EXT_TABLE_JOINS_HASH{builds} = 1;
    $EXT_TABLE_JOINS_HASH{streets} = 1;
    $EXT_TABLE_JOINS_HASH{districts} = 1;
  }
  else{
    if ( $CONF->{ADDRESS_REGISTER} ){

      if ( $attr->{CITY} ){
        push @fields, @{ $self->search_expr( $attr->{CITY}, 'STR', 'districts.city', { EXT_FIELD => 1 } ) };
        $EXT_TABLE_JOINS_HASH{users_pi} = 1;
        $EXT_TABLE_JOINS_HASH{builds} = 1;
        $EXT_TABLE_JOINS_HASH{streets} = 1;
        $EXT_TABLE_JOINS_HASH{districts} = 1;
      }

      if ( $attr->{ADDRESS_FULL} ){
        my $build_delimiter = $attr->{BUILD_DELIMITER} || $self->{conf}{BUILD_DELIMITER} || ', ';
        push @fields, @{ $self->search_expr( $attr->{ADDRESS_FULL}, "STR",
            "CONCAT(streets.name, '$build_delimiter', builds.number, '$build_delimiter', pi.address_flat) AS address_full",
            { EXT_FIELD => 1 } ) };
        $EXT_TABLE_JOINS_HASH{users_pi} = 1;
        $EXT_TABLE_JOINS_HASH{builds} = 1;
        $EXT_TABLE_JOINS_HASH{streets} = 1;
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
            { EXT_FIELD => 1 } ) };
        $EXT_TABLE_JOINS_HASH{users_pi} = 1;
        $EXT_TABLE_JOINS_HASH{builds} = 1;
        $EXT_TABLE_JOINS_HASH{streets} = 1;
        $EXT_TABLE_JOINS_HASH{districts} = 1;
      }

      if ( $attr->{ADDRESS_STREET} ){
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
      }

#      elsif ( $attr->{SHOW_ADDRESS} ){
#        push @{ $self->{SEARCH_FIELDS_ARR} }, 'streets.name AS address_street', 'builds.number AS address_build',
#          'pi.address_flat', 'streets.id AS street_id';
#        $EXT_TABLE_JOINS_HASH{users_pi} = 1;
#        $EXT_TABLE_JOINS_HASH{builds} = 1;
#        $EXT_TABLE_JOINS_HASH{streets} = 1;
#      }

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
    }
    else{
      my $f_count = $self->{SEARCH_FIELDS_COUNT};

      if ( $attr->{ADDRESS_FULL} ){
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
    push @fields, @{ $self->search_expr( $attr->{ADDRESS_FLAT}, 'STR', 'pi.address_flat', { EXT_FIELD => 1 } ) };
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
    push @fields, @{ $self->search_expr( $attr->{TAGS}, 'INT', "tags_users.tag_id",
        { EXT_FIELD => 'tags.name AS tags, tags.priority' } ) };

    $self->{EXT_TABLES} .= " LEFT JOIN tags_users ON (u.uid=tags_users.uid)
                             LEFT JOIN tags ON (tags_users.tag_id=tags.id)",
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

  if ( $attr->{EXT_DEPOSIT} ){
    $EXT_TABLE_JOINS_HASH{companies} = 1;
    $EXT_TABLE_JOINS_HASH{ext_bills} = 1;
  }

  if ( $attr->{CONTRACT_ID} || $attr->{CREDIT} ){
    $EXT_TABLE_JOINS_HASH{users_pi} = 1;
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
  if ( $attr->{SORT} && $attr->{SORT} =~ /\d+/){
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
    'groups:LEFT JOIN groups g ON (g.gid=u.gid)',
    'companies:LEFT JOIN companies company ON (u.company_id=company.id)',
    "bills:LEFT JOIN bills b ON (u.bill_id = b.id)\n" .
      " LEFT JOIN bills cb ON (company.bill_id=cb.id)",
    "ext_bills:LEFT JOIN bills ext_b ON (u.ext_bill_id = ext_b.id)\n" .
      " LEFT JOIN bills ext_cb ON  (company.ext_bill_id=ext_cb.id)",
    'users_pi:LEFT JOIN users_pi pi ON (u.uid=pi.uid)',
    'builds:LEFT JOIN builds ON (builds.id=pi.location_id)',
    'streets:LEFT JOIN streets ON (streets.id=builds.street_id)',
    'districts:LEFT JOIN districts ON (districts.id=streets.district_id)',
    'admin_actions:LEFT JOIN admin_actions aa ON (u.uid=aa.uid)'
  );

  if ( $attr->{EXTRA_PRE_JOIN} ){
    if ( $attr->{EXTRA_PRE_ONLY} ){
      @EXT_TABLES_JOINS = @{ $attr->{EXTRA_PRE_JOIN} };
    }
    else{
      @EXT_TABLES_JOINS = ( @{ $attr->{EXTRA_PRE_JOIN} }, @EXT_TABLES_JOINS);
    }
  }

  my $join_tablee = '';
  foreach my $table_ ( @EXT_TABLES_JOINS ){
    my ($table_name, $join_text) = split( /:/, $table_, 2 );
    if ( $attr->{JOIN_TABLES}->{$table_name} ){
      $join_tablee .= "$join_text\n";
    }
  }

  return $join_tablee . ($self->{EXT_TABLES} || '');
}


#**********************************************************
=head2 changes2($attr) - Change values in table and make change log

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

    $self->changes2(
      {
        CHANGE_PARAM => 'ID',
        TABLE        => 'ring_rules',
        DATA         => $attr
      }
    );

=cut
#**********************************************************
sub changes2{
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

  my $admin = $self->{admin};

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

  my @change_params = ();
  foreach my $key (split(/,\s?/, $CHANGE_PARAM)) {
    if ($FIELDS && $FIELDS->{$key}) {
      push @change_params, $FIELDS->{$key}."='$DATA->{$key}'";
    }
    else {
      push @change_params, lc($key) ."= '$DATA->{$key}'";
    }
  }

  my $change_params_list = join(' AND ', @change_params);
  my $OLD_DATA = $attr->{OLD_INFO};
  if ($OLD_DATA->{errno}) {
    if (!$self->{db}->{api}) {
      print "Old date errors: $OLD_DATA->{errno} '$TABLE' $change_params_list\n";
      print %{$DATA} if ($DATA && ref $DATA eq 'HASH');
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
    elsif($attr->{OLD_WAY_ROWS}) {
      if($q->rows < 0) {
        $self->{errno} = '4';
        $self->{errstr} = "Can't get old data for change";
        return $self;
      }
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
          $self->{DISABLE} = $v;
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
      elsif ( $k eq 'IPV6_PREFIX' || $k eq 'IPV6' || $k eq 'IPV6_PD' ){
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
          $self->{CHG_STATUS} = $OLD_DATA->{$k} . '->' . $value . (($attr->{EXT_CHANGE_INFO}) ? ' ' . $attr->{EXT_CHANGE_INFO} : '');
          $self->{'STATUS'} = $value;
        }
        elsif ( $k eq 'DISABLE' ){
          if ( defined( $value ) && $value == 0 || !defined( $value ) ){
            if ( $self->{DISABLE} != 0 ){
              $self->{ENABLE} = 1;
              $self->{DISABLE} = undef;
            }
          }
          elsif ( $value > 1 ){
            $self->{'STATUS'} = $value;
          }
          else{
            $self->{DISABLE_ACTION} = 1;
          }

          $self->{CHG_STATUS} = $OLD_DATA->{$k} . '->' . $value . (($attr->{EXT_CHANGE_INFO}) ? ' ' . $attr->{EXT_CHANGE_INFO} : '');
        }
        elsif ( $k eq 'DOMAIN_ID' && $OLD_DATA->{$k} == 0 && !$value ){
        }
        elsif ( $k eq 'TP_ID' ){
          #$self->{CHG_TP} = $OLD_DATA->{$k} . '->' . $DATA{$k};
          $self->{CHG_TP} = $OLD_DATA->{$k} . '->' . $value . (($attr->{EXT_CHANGE_INFO}) ? ' ' . $attr->{EXT_CHANGE_INFO} : '');
        }
        elsif ( $k eq 'GID' ){
          $self->{CHG_GID} = $OLD_DATA->{$k} . '->' . $value;
        }
        elsif ( $k eq 'CREDIT' ){
          $self->{CHG_CREDIT} = $OLD_DATA->{$k} . '->' . $value;
        }
        else{
          push @change_log, "$k $OLD_DATA->{$k}->$value";
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
  else {
    $self->{CHANGES_LOG} = join( ';', @change_log );    
  }

  my $extended = ($attr->{EXTENDED}) ? $attr->{EXTENDED} : '';
  my $CHANGES_QUERY = join( ', ', @change_fields );

  $self->query2( "UPDATE $TABLE SET $CHANGES_QUERY WHERE $change_params_list $extended",
    'do',
    { Bind => \@bind_values } );

  $self->{AFFECTED} = sprintf( "%d", (defined ( $self->{AFFECTED} ) ? $self->{AFFECTED} : 0) );

  if ( $self->{AFFECTED} == 0 ){
    return $self;
  }
  elsif ( $self->{errno} ){
    return $self;
  }

  if($attr->{SKIP_LOG}) {
    return $self;
  }

  if ( $attr->{EXT_CHANGE_INFO} ){
    $self->{CHANGES_LOG} = $attr->{EXT_CHANGE_INFO} . ' ' . $self->{CHANGES_LOG};
  }
  else{
    $attr->{EXT_CHANGE_INFO} = '';
  }

  if ( defined( $DATA->{UID} ) && $DATA->{UID} > 0 && defined( $admin ) ){
    if ( $attr->{'ACTION_ID'} ){
      my $action_comments = ($attr->{ACTION_COMMENTS}) ? ' '.$attr->{ACTION_COMMENTS}: q{};
      $admin->action_add( $DATA->{UID}, $attr->{EXT_CHANGE_INFO}.$action_comments, { TYPE => $attr->{'ACTION_ID'} } );
      return $self->{result};
    }

    if ( $self->{CHANGES_LOG} ne '' && ($self->{CHANGES_LOG} ne $attr->{EXT_CHANGE_INFO} . ' ') ){
      $admin->action_add( $DATA->{UID}, $self->{CHANGES_LOG}, { TYPE => 2 } );
    }

    if ( $self->{'DISABLE_ACTION'} ){
      $admin->action_add( $DATA->{UID}, "$self->{CHG_STATUS}",
        { TYPE => 9, ACTION_COMMENTS => $DATA->{ACTION_COMMENTS} } );
      return $self->{result};
    }

    if ( $self->{'ENABLE'} ){
      $admin->action_add( $DATA->{UID}, $self->{CHG_STATUS}, { TYPE => 8 } );
      return $self->{result};
    }

    if ( $self->{'CHG_TP'} ){
      $admin->action_add( $DATA->{UID}, $self->{'CHG_TP'}, { TYPE => 3 } );
    }

    if ( $self->{CHG_GID} ){
      $admin->action_add( $DATA->{UID}, $self->{CHG_GID}, { TYPE => 26 } );
    }

    if ( $self->{CHG_STATUS} ){
      #if (! $admin) {
      #  print " $DATA{UID}, (($self->{CHG_STATUS}) ? $self->{CHG_STATUS} : $self->{'STATUS'}), { TYPE => ($self->{'STATUS'} == 3) ? 14 : 4 }); ";
      #}
      $admin->action_add( $DATA->{UID}, (($self->{CHG_STATUS}) ? $self->{CHG_STATUS} : $self->{'STATUS'}),
        { TYPE => ($self->{'STATUS'} == 3) ? 14 : 4 } );
    }

    if ( $self->{CHG_CREDIT} ){
      $admin->action_add( $DATA->{UID}, "$self->{'CHG_CREDIT'}", { TYPE => 5 } );
    }
  }
  elsif ( defined( $admin ) ){
    if ( $self->{'DISABLE'} ){
      $admin->system_action_add( $self->{CHANGES_LOG}, { TYPE => 9 } );
    }
    elsif ( $self->{'ENABLE'} ){
      $admin->system_action_add( $self->{CHANGES_LOG}, { TYPE => 8 } );
    }
    else{
      $admin->system_action_add( $self->{CHANGES_LOG}, { TYPE => 2 } );
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

1
