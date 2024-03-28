package AXbills::Api::Router;

use strict;
use warnings FATAL => 'all';

no if $] >= 5.017011, warnings => 'experimental::smartmatch';

use JSON;

use AXbills::Base qw(escape_for_sql in_array decamelize);
use AXbills::Api::Validator;
use AXbills::Api::Paths;

#**********************************************************
=head2 new($url, $db, $user, $admin, $conf, $query_params)

=cut
#**********************************************************
sub new {
  my ($class, $url, $db, $admin, $conf, $query_params, $lang, $modules, $debug, $html, $request_method) = @_;

  my $self = {
    db             => $db,
    admin          => $admin,
    conf           => $conf,
    lang           => $lang,
    modules        => $modules,
    html           => $html,
    debug          => ($debug || 0),
    request_method => $request_method
  };

  bless($self, $class);

  $self->preprocess($url, $query_params);

  return $self;
}

#**********************************************************
=head2 preprocess($url, $query_params) - preprocess request

  Gets params from request. Sets $self attrs

  Arguments:
    $url          - part of URL that goes after "api.cgi/" (name of API route)
    $query_params - query params. \%FORM variable goes here

  Returns:
    $self

=cut
#**********************************************************
sub preprocess {
  my $self = shift;
  my ($url, $query_params) = @_;

  $url =~ s/\?.+//g;
  my @params = split('/', $url);
  my $resource_name = $params[1] || q{};

  my $resource_name_user_api = q{};
  if ($params[2] && $params[2] =~ /\d+/) {
    $resource_name_user_api = $params[3] || q{};
  }
  else {
    $resource_name_user_api = $params[2] || q{};
  }

  my $Paths = AXbills::Api::Paths->new($self->{db}, $self->{admin}, $self->{conf}, $self->{lang}, $self->{html});

  if ($self->{request_method} ~~ [ 'GET', 'DELETE' ]) {
    $self->{query_params} = $query_params;
  }
  elsif ($ENV{CONTENT_TYPE} && $ENV{CONTENT_TYPE} =~ 'multipart/form-data') {
    $self->{query_params} = $query_params;
  }
  elsif ($query_params->{__BUFFER}) {
    my $q_params = eval {decode_json($query_params->{__BUFFER})};

    if ($@) {
      $self->{result} = {
        errno  => 1,
        errstr => 'There was an error parsing the body'
      };
      $self->{status} = 400;

      return $self;
    }
    else {
      if (ref $q_params ne 'HASH') {
        $self->{result} = {
          errno  => 6,
          errstr => 'Wrong request type. Please check of request type body.',
        };
        $self->{status} = 400;
        return $self;
      }
      $self->{query_params} = escape_for_sql($q_params);
    }
  }
  else {
    $self->{query_params} = undef;
  }

  if ($self->{query_params}->{__BUFFER}) {
    delete $self->{query_params}->{__BUFFER};
  }

  #TODO: if in future one Router object will be used for multiple queries, move this to new()
  if ($resource_name eq 'user' && $resource_name_user_api) {
    $self->{resource_own} = $Paths->load_own_resource_info({
      package           => $resource_name_user_api,
      debug             => $self->{debug},
      type              => 'user',
    });
  }
  elsif ($resource_name ne 'user') {
    $self->{resource_own} = $Paths->load_own_resource_info({
      package           => $resource_name,
      debug             => $self->{debug},
      type              => 'admin',
    });
  }

  if (!$self->{resource_own}) {
    $self->{paths} = $Paths->list();
    $self->{resource} = $self->{paths}->{$resource_name};
  }
  elsif (ref \$self->{resource_own} eq 'SCALAR' && $self->{resource_own} == 2) {
    $self->{errno} = 10;
    $self->{errstr} = 'Access denied';
    $self->{status} = 403;

    return $self;
  }

  $self->{request_path} = join('/', @params) . '/';
  $self->{allowed} = 0;
  $self->{status} = 0;

  return $self;
}

#***********************************************************
=head2 transform()

=cut
#***********************************************************
sub transform {
  my $self = shift;
  my ($transformer) = @_;

  $self->{result} = $transformer->($self->{result});
  return 1;
}

#***********************************************************
=head2 add_credential()

=cut
#***********************************************************
sub add_credential {
  my $self = shift;
  my ($credential_name, $credential_handler) = @_;

  $self->{credentials}->{$credential_name} = $credential_handler;
  return 1;
}

#***********************************************************
=head2 handle() - execute routed method

=cut
#***********************************************************
sub handle {
  my $self = shift;

  if ($self->{status}) {
    $self->{allowed} = 1;
    return 0;
  }

  my $handler = $self->parse_request();
  my $route = $handler->{route} if ($handler);

  if (!$route) {
    $self->{result} = {
      errno  => 2,
      errstr => 'No such route'
    };
    $self->{status} = 404;
    $self->{allowed} = 1;

    return 0;
  }

  my $cred = q{};

  if (defined $route->{credentials}) {
    foreach my $credential_name (@{$route->{credentials}}) {
      my $credential = $self->{credentials}->{$credential_name};

      if (defined $credential) {
        if ($credential->($handler)) {
          $cred = $credential_name;
          $self->{allowed} = 1;
        }
      }
    }

    return unless $self->{allowed};
  }
  else {
    $self->{allowed} = 1;
  }

  if (defined $route->{params}) {
    my $Validator = AXbills::Api::Validator->new($self->{db}, $self->{admin}, $self->{conf});
    my $validation_result = $Validator->validate_params({
      query_params => $handler->{query_params} || {},
      params       => $route->{params} || {},
    });

    if ($validation_result->{errno}) {
      $self->{result} = $validation_result;
      return 0;
    }

    $route->{query_params} = $validation_result;
  }

  if ($cred && $cred ~~ [ 'ADMIN', 'ADMIN_SID' ] && $handler->{path_params} && $handler->{path_params}->{uid}) {
    require Users;
    Users->import();
    my $Users = Users->new($self->{db}, $self->{admin}, $self->{conf});
    $Users->info($handler->{path_params}->{uid});

    if (!$Users->{TOTAL}) {
      $self->{result} = {
        errno  => 15,
        errstr => "User not found with uid $handler->{path_params}->{uid}",
        uid    => $handler->{path_params}->{uid},
      };
      return 0;
    }
    else {
      $handler->{path_params}->{user_object} = $Users;
    }
  }

  $self->{handler} = $handler;

  my $module_obj;
  if ($route->{module} && $self->{resource}) {
    if ($route->{module} !~ /^[a-zA-Z0-9_:]+$/) {
      $self->{result} = {
        errno  => 3,
        errstr => 'Module is not found'
      };
      return 0;
    }

    eval "use $route->{module}";

    if ($@ || !$route->{module}->can('new')) {
      $self->{result} = {
        errno  => 4,
        errstr => 'Module is not found'
      };
      return 0;
    }

    $module_obj = $route->{module}->new($self->{db}, $self->{admin}, $self->{conf});
    $module_obj->{debug} = $self->{debug};
  }

  my $result = '';

  eval {
    $result = $handler->{handler_fn}->(
      $handler->{path_params},
      $handler->{query_params},
      $module_obj
    );
  };

  if ($@) {
    $self->{result} = {
      errno  => 20,
      errstr => 'Unknown error, please try later'
    };
    $self->{status} = 502;

    $self->{error_msg} = $@;

    return 0;
  }

  if ($module_obj->{errno}) {
    $self->{result} = {
      errno  => $module_obj->{errno},
      errstr => $module_obj->{errstr}
    };
    $self->{status} = 400;
  }
  else {
    if (ref $result ne 'HASH' && ref $result ne 'ARRAY' && ref $result ne '') {
      foreach my $key (keys %{$result}) {
        next if (defined $self->{$key} && $key ne 'result');
        $self->{result}->{$key} = $result->{$key};
      }
    }
    else {
      $self->{result} = $result;
      $self->{content_type} = $route->{content_type} || q{};

      unless (defined($self->{result})) {
        $self->{result} = {};
      }

      if (!ref $self->{result} && !$route->{content_type}) {
        $self->{result} = {
          result => $self->{result} ? 'OK' : 'BAD'
        };
      }
    }
  }

  return 1;
}

#***********************************************************
=head2 parse_request() - parses request and returns data, required to process it

   Returns:
    {
      route        - hashref of route's info. look at docs in AXbills::Api::Paths
      handler_fn   - coderef of route's handler function
      path_params  - params from path. hashref.
                     Example: if route's path is '/users/:uid/', and queried
                     URL is '/users/9/', there will be { uid => 9 }.
                     always numerical
      query_params - params from query. for details look at sub new(). hashref.
                     keys will be converted from camelCase to UPPER_SNAKE_CASE
                     using AXbills::Base::decamelize unless
                     $route->{no_decamelize_params} is set
      conf_params  - variables from $conf to be returned in result. arrayref.
                     experimental feature, currently disabled
    }

=cut
#***********************************************************
sub parse_request {
  my $self = shift;

  my $request_path = $self->{request_path};
  my $query_params = $self->{query_params};

  my $resource = ($self->{resource_own} || $self->{resource});

  foreach my $route (@{$resource}) {
    next if (!$self->{request_method} || $route->{method} ne $self->{request_method});

    my $route_handler = $route->{handler};
    next if (ref $route_handler ne 'CODE');

    my $route_path_template = $route->{path};

    my @path_keys = $route_path_template =~ m/:([a-zA-Z0-9_]+)(?=\/)/g;

    $route_path_template =~ s/:(string_[a-zA-Z0-9_]+)(?=\/)/([a-zA-Z0-9:_-]+)/gm;
    $route_path_template =~ s/:([a-zA-Z0-9_]+)(?=\/)/(\\d+)/g;
    $route_path_template =~ s/(\/)/\\\//g;
    $route_path_template = '^' . $route_path_template . '$';

    #TODO: delete next 15 rows when will be finally deprecated user api with :uid paths
    my $path_uid = 0;
    if ($route->{credentials} && in_array('USER', $route->{credentials}) && $ENV{HTTP_USERSID} && $route->{path} =~ /:uid/) {
      if ($request_path !~ $route_path_template) {
        $route_path_template = $route->{path};
        $route_path_template =~ s/:uid\///;
        $route_path_template =~ s/:(string_[a-zA-Z0-9_]+)(?=\/)/([a-zA-Z0-9:_-]+)/gm;
        $route_path_template =~ s/:([a-zA-Z0-9_]+)(?=\/)/(\\d+)/g;
        $route_path_template =~ s/(\/)/\\\//g;
        $route_path_template = '^' . $route_path_template . '$';
        next unless ($request_path =~ $route_path_template);
        $path_uid = 1;
      }
    }
    else {
      next unless ($request_path =~ $route_path_template);
    }

    #TODO: paste here row -> next unless ($request_path =~ $route_path_template);
    my @request_values = $request_path =~ $route_path_template;

    my %path_params = ();

    while (@path_keys) {
      my $key = shift(@path_keys);

      #TODO: delete next row when will be finally deprecated user api with :uid paths
      next if ($path_uid && $key && $key eq 'uid');

      $key =~ s/string_//;
      my $value = shift(@request_values);

      $path_params{$key} = $value;
    }

    my %query_params = ();

    for my $query_key (keys %{$query_params}) {
      my $key = $route->{no_decamelize_params} ? $query_key : decamelize($query_key);
      if (ref $query_params->{$query_key} ne '') {
        $query_params->{$query_key} = process_request_body($query_params->{$query_key}, { no_decamelize_params => $route->{no_decamelize_params} || '' });
      }
      else {
        if ($key eq 'SORT') {
          $query_params->{$query_key} = decamelize($query_params->{$query_key});
        }
      }
      $query_params{$key} = $query_params->{$query_key};
    }

    my $path_params = escape_for_sql(\%path_params);

    return {
      route        => $route,
      handler_fn   => $route_handler,
      path_params  => $path_params,
      query_params => \%query_params,
    };
  }
}

#***********************************************************
=head2 process_request_body($query_params)

=cut
#***********************************************************
sub process_request_body {
  my ($query_params, $attr) = @_;

  if (ref $query_params eq 'ARRAY') {
    foreach my $val (@$query_params) {
      next if (ref $val ne 'HASH');
      $val = process_request_body($val, $attr);
    }
  }
  elsif (ref $query_params eq 'HASH') {
    foreach my $query_key (keys %$query_params) {
      if (ref $query_key eq '') {
        my $key = $attr->{no_decamelize_params} ? $query_key : decamelize($query_key);
        $query_params->{$key} = $query_params->{$query_key};
        delete $query_params->{$query_key};
      }
      else {
        $query_params->{$query_key} = process_request_body($query_params->{$query_key}, $attr);
      }
    }
  }

  return $query_params;
}

1;
