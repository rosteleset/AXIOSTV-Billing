package Equipment::Api;
=head1 NAME

  Equipment::Api - Equipment api functions

=head VERSION

  DATE: 20220210
  UPDATE: 20220911
  VERSION: 0.05

=cut

use strict;
use warnings FATAL => 'all';

use AXbills::Base qw(cmd in_array);
use Equipment;
use Nas;
require Equipment::Ports;

our (
  $db,
  $admin,
  %conf
);

my Equipment $Equipment;
my Nas $Nas;

#**********************************************************
=head2 new($db, $conf, $admin, $lang)

=cut
#**********************************************************
sub new {
  my ($class, $Db, $Admin, $conf, $lang, $debug, $type) = @_;

  my $self = {
    db    => $Db,
    admin => $Admin,
    conf  => $conf,
    lang  => $lang,
    debug => $debug
  };

  $db = $self->{db};
  $admin = $self->{admin};
  %conf = %{$self->{conf}};

  $self->{routes_list} = ();

  bless($self, $class);

  $Equipment = Equipment->new($self->{db}, $self->{admin}, $self->{conf});
  $Nas = Nas->new($self->{db}, $self->{conf}, $self->{admin});

  $Equipment->{debug} = $self->{debug} || 0;
  $Nas->{debug} = $self->{debug} || 0;

  if ($type eq 'admin') {
    $self->{routes_list} = $self->admin_routes();
  }

  return $self;
}

#**********************************************************
=head2 admin_routes() - Returns available API paths

  Returns:
    {
      $resource_1_name => [ # $resource_1_name, $resource_2_name - names of API resources. always equals to first path segment
        {
          method  => 'GET',          # HTTP method. Path can be queried only with this method

          path    => '/users/:uid/', # API path. May contain variables like ':uid'.
                                     # these variables will be passed to handler function as argument ($path_params).
                                     # variables are always numerical.
                                     # example: if route's path is '/users/:uid/', and queried URL
                                     # is '/users/9/', $path_params will be { uid => 9 }.
                                     # if credentials is 'USER', variable :uid will be checked to contain only
                                     # authorized user's UID.

          handler => sub {           # handler function, coderef. Arguments that are passed to handler:
            my (
                $path_params,        # params from path. look at docs of path. hashref.
                $query_params,       # params from query. for details look at AXbills::Api::Router::new(). hashref.
                                     # keys will be converted from camelCase to UPPER_SNAKE_CASE
                                     # using AXbills::Base::decamelize unless no_decamelize_params is set
                $module_obj          # object of needed DB module (in this example - Users). used to run it's methods.
                                     # may be empty if name of module is not set.
               ) = @_;

            $module_obj->info(       # handler should return hashref or arrayref with needed data
              $path_params->{uid}
            );                       # in this example we call Users->info, and it's result are implicitly returned
          },

          module  => 'Users',        # name of DB module. it's object will be created and passed to handler as $module_obj. optional.

          type    => 'HASH',         # type of returned data. may be 'HASH' or 'ARRAY'. by default (if not set) it is 'HASH'. optional.

          credentials => [           # arrayref of roles required to use this path. if API user is authorized as at least one of
                                     # these roles access to this path will be granted. optional.
            'ADMIN'                  # may be 'ADMIN' or 'USER'
          ],

          no_decamelize_params => 0, # if set, $query_params for handler will not be converted to UPPER_SNAKE_CASE. optional.

          conf_params => [ ... ]     # variables from $conf to be returned in result. arrayref.
                                     # experimental feature, currently disabled
        },
        ...
      ],
      $resource_2_name => [
        ...
      ],
      ...
    }

=cut
#**********************************************************
sub admin_routes {
  my $self = shift;

  return [
    {
      method      => 'GET',
      path        => '/equipment/onu/list/',
      handler     => sub {
        my ($path_params, $query_params) = @_;
        return _get_onu_list($path_params, $query_params);
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/equipment/onu/:id/',
      handler     => sub {
        my ($path_params, $query_params) = @_;
        return _get_onu_list($path_params, $query_params, { ONE => 1 });
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/equipment/box/list/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        my %PARAMS = (
          PAGE_ROWS => $query_params->{PAGE_ROWS} ? $query_params->{PAGE_ROWS} : 25,
          SORT      => $query_params->{SORT} ? $query_params->{SORT} : 1,
          PG        => $query_params->{PG} ? $query_params->{PG} : 0,
        );

        $Equipment->equipment_box_list({
          %PARAMS,
          COLS_NAME => 1,
        });
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/equipment/used/ports/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        return {
          errno  => 200212,
          errstr => 'No parameter nasId and fullList. Required during using portsOnly parameter.',
        } if ($query_params->{PORTS_ONLY} && !$query_params->{NAS_ID});

        return {
          errno  => 200213,
          errstr => 'No parameter portsOnly. Required during using nasId parameter.',
        } if ($query_params->{NAS_ID} && !$query_params->{PORTS_ONLY});

        my @allowed_params = (
          'NAS_ID',
          'GET_MAC',
          'FULL_LIST',
          'PORTS_ONLY'
        );

        my %PARAMS = (
          COLS_UPPER => 1
        );
        foreach my $param (@allowed_params) {
          next if (!defined($query_params->{$param}));
          $PARAMS{$param} = $query_params->{$param};
        }

        equipments_get_used_ports({
          %PARAMS
        });
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/equipment/nas/types/',
      handler     => sub {
        my ($path_params, $query_params) = @_;
        require Control::Nas_mng;
        my $types = nas_types_list() || {};
        my @types_list = ();

        foreach my $type (sort keys %{$types}) {
          push @types_list, {
            name => $types->{$type} || '',
            id   => $type || ''
          };
        }

        return \@types_list;
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/equipment/nas/list/extra/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        my %PARAMS = (
          COLS_NAME => 1,
          PAGE_ROWS => $query_params->{PAGE_ROWS} ? $query_params->{PAGE_ROWS} : 25,
          SORT      => $query_params->{SORT} ? $query_params->{SORT} : 1,
          PG        => $query_params->{PG} ? $query_params->{PG} : 0,
        );

        my @address_params = ('DISTRICT_ID', 'STREET_ID', 'LOCATION_ID', 'COORDX', 'COORDY');

        foreach my $param (keys %{$query_params}) {
          $PARAMS{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0') ? $query_params->{$param} : '_SHOW';
          $PARAMS{ADDRESS_FULL} = 1 if (in_array($param, \@address_params))
        }

        $PARAMS{TYPE} = $PARAMS{TYPE_ID} if (defined $PARAMS{TYPE_ID});
        $PARAMS{TR_069_VLAN} = $PARAMS{TR069_VLAN} if (defined $PARAMS{TR069_VLAN});

        if (in_array('Multidoms', \@main::MODULES)) {
          $PARAMS{DOMAIN_ID} = $self->{admin}->{DOMAIN_ID} || 0 if (defined $PARAMS{DOMAIN_NAME});
        }
        else {
          delete $PARAMS{DOMAIN_NAME};
        }

        my $result = $Equipment->_list({
          %PARAMS
        });

        foreach my $equipment (@{$result}) {
          if (exists($equipment->{name})) {
            $equipment->{district_id} = $equipment->{name};
            delete $equipment->{name};
          }

          if ((exists $query_params->{DOMAIN_ID} || exists $query_params->{DOMAIN_NAME}) && !in_array('Multidoms', \@main::MODULES)) {
            $equipment->{domain_id} = 'null';
            $equipment->{domain_name} = 'Error. Module Multidoms disabled';
          }
        }

        return $result;
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/equipment/nas/list/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        my %PARAMS = (
          COLS_NAME => 1,
          PAGE_ROWS => $query_params->{PAGE_ROWS} ? $query_params->{PAGE_ROWS} : 25,
          SORT      => $query_params->{SORT} ? $query_params->{SORT} : 1,
          PG        => $query_params->{PG} ? $query_params->{PG} : 0,
        );

        foreach my $param (keys %{$query_params}) {
          $PARAMS{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0') ? $query_params->{$param} : '_SHOW';
        }

        $PARAMS{MNG_HOST_PORT} = $PARAMS{NAS_MNG_IP_PORT} if (defined $PARAMS{MNG_HOST_PORT});

        $Nas->list({
          %PARAMS
        });
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'POST',
      path        => '/equipment/nas/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        return {
          errno  => 200201,
          errstr => 'No field ip'
        } if !$query_params->{IP};

        return {
          errno  => 200202,
          errstr => 'No field nasName'
        } if !$query_params->{NAS_NAME};

        return {
          errno  => 200203,
          errstr => 'No field nas_type'
        } if !defined $query_params->{NAS_TYPE};

        my $result = $Nas->add($query_params);

        if ($conf{RESTART_RADIUS} && $conf{RESTART_RADIUS_API}) {
          cmd($conf{RESTART_RADIUS});
        }

        return $result;
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'DELETE',
      path        => '/equipment/nas/:id/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        my $result = $Nas->del($path_params->{id});

        if ($conf{RESTART_RADIUS} && $conf{RESTART_RADIUS_API}) {
          cmd($conf{RESTART_RADIUS});
        }

        return ($result->{nas_deleted} eq 1) ? 1 : 0;
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'PUT',
      path        => '/equipment/nas/:id/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        return {
          errno  => 200204,
          errstr => 'No field nasId'
        } if !$path_params->{id};

        return {
          errno  => 200205,
          errstr => 'No field ip'
        } if !$query_params->{IP};

        return {
          errno  => 200206,
          errstr => 'No field nasName'
        } if !$query_params->{NAS_NAME};

        return {
          errno  => 200207,
          errstr => 'No field nasType'
        } if !defined $query_params->{NAS_TYPE};

        my $result = $Nas->change({ NAS_ID => $path_params->{id}, %$query_params });

        if ($conf{RESTART_RADIUS} && $conf{RESTART_RADIUS_API} && !$Nas->{errno}) {
          cmd($conf{RESTART_RADIUS});
        }

        return $result;
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/equipment/nas/groups/list/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        my %PARAMS = (
          COLS_NAME => 1,
          PAGE_ROWS => $query_params->{PAGE_ROWS} ? $query_params->{PAGE_ROWS} : 25,
          SORT      => $query_params->{SORT} ? $query_params->{SORT} : 1,
          PG        => $query_params->{PG} ? $query_params->{PG} : 0,
        );

        $Nas->nas_group_list({
          %PARAMS
        });
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'POST',
      path        => '/equipment/nas/groups/add/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        my $validation_result = _validate_nas_group_add($query_params);
        return $validation_result if ($validation_result->{errno});

        $Nas->nas_group_add({
          NAME     => $query_params->{NAME} || '',
          COMMENTS => $query_params->{COMMENTS} || '',
          DISABLE  => $query_params->{DISABLE} ? 1 : undef,
        });
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'PUT',
      path        => '/equipment/nas/groups/:id/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        my $validation_result = _validate_nas_group_add($query_params);
        return $validation_result if ($validation_result->{errno});

        $Nas->nas_group_change({
          ID       => $path_params->{id} || '--',
          NAME     => $query_params->{NAME} || '',
          COMMENTS => $query_params->{COMMENTS} || '',
          DISABLE  => $query_params->{DISABLE} ? 1 : undef,
        });

        delete @{$Nas}{qw/AFFECTED TOTAL list/};
        return $Nas;
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'DELETE',
      path        => '/equipment/nas/groups/:id/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        $Nas->nas_group_del($path_params->{id});

        if (!$Nas->{errno}) {
          if ($Nas->{AFFECTED} && $Nas->{AFFECTED} =~ /^[0-9]$/) {
            return {
              result => 'Successfully deleted',
            };
          }
          else {
            return {
              errno  => 30031,
              errstr => "nasGroup with id $path_params->{id} not exists",
            };
          }
        }

        return $Nas;
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/equipment/nas/ip/pools/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        my %PARAMS = (
          COLS_NAME => 1,
          PAGE_ROWS => $query_params->{PAGE_ROWS} ? $query_params->{PAGE_ROWS} : 25,
          SORT      => $query_params->{SORT} ? $query_params->{SORT} : 1,
          PG        => $query_params->{PG} ? $query_params->{PG} : 0,
        );

        foreach my $param (keys %{$query_params}) {
          $PARAMS{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0') ? $query_params->{$param} : '_SHOW';
        }

        $Nas->nas_ip_pools_list({
          %PARAMS
        });
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'POST',
      path        => '/equipment/nas/ip/pools/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        return {
          errno  => 200208,
          errstr => 'No field poolId'
        } if !$query_params->{POOL_ID};

        return {
          errno  => 200209,
          errstr => 'No field nasId'
        } if !$query_params->{NAS_ID};

        $Nas->nas_ip_pools_add({
          NAS_ID  => $query_params->{NAS_ID},
          POOL_ID => $query_params->{POOL_ID},
        });
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'DELETE',
      path        => '/equipment/nas/ip/pools/:nasId/:poolId/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        $Nas->nas_ip_pools_del({
          NAS_ID  => $path_params->{nasId},
          POOL_ID => $path_params->{poolId}
        });

        if (!$Nas->{errno}) {
          if ($Nas->{AFFECTED} && $Nas->{AFFECTED} =~ /^[0-9]$/) {
            return {
              result => 'Successfully deleted',
            };
          }
          else {
            return {
              errno  => 30032,
              errstr => "nasIpPool with id $path_params->{nasId} and poolId $path_params->{poolId} not exists",
            };
          }
        }

        return $Nas;
      },
      credentials => [
        'ADMIN'
      ]
    },
  ]
}

#**********************************************************
=head2 _get_onu_list($path_params, $query_params, $attr)

  Arguments:
    $path_params: object  - hash of params from request path
    $query_params: object - hash of query params from request
    $attr: object         - params of function example
      ONE: boolean - returns one onu with $path_params value {id}

  Returns:
    optional
      array or object

=cut
#**********************************************************
sub _get_onu_list {
  my ($path_params, $query_params, $attr) = @_;

  $query_params->{ONU_VLAN} = $query_params->{VLAN} if ($query_params->{VLAN});
  $query_params->{DATETIME} = $query_params->{DATE_TIME} if ($query_params->{DATE_TIME});

  $query_params->{PAGE_ROWS} = $query_params->{PAGE_ROWS} || 25;
  $query_params->{SORT} = $query_params->{SORT} || 1;
  $query_params->{PG} = $query_params->{PG} || 0;

  foreach my $param (keys %{$query_params}) {
    $query_params->{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0') ? $query_params->{$param} : '_SHOW';
  }

  $query_params->{ID} = ($attr && $attr->{ONE}) ? ($path_params->{id} || 0) : ($query_params->{ID} || 0);

  my $list = $Equipment->onu_list({
    %{$query_params},
    COLS_NAME => 1,
  });

  if ($attr && $attr->{ONE}) {
    return $list->[0] if (scalar @{$list});

    return {
      errno  => 200210,
      errstr => 'Unknown onu'
    };
  }
  else {
    return $list;
  }
}

#**********************************************************
=head2 _tp_add_filter()

=cut
#**********************************************************
sub _validate_nas_group_add {
  my ($attr) = @_;

  if ($attr->{NAME}) {
    my $groups = $Nas->nas_group_list({
      NAME      => $attr->{NAME} || '--',
      COLS_NAME => 1
    });

    return {
      errno  => 9,
      errstr => 'Validation failed',
      errors => [ {
        errno    => 21,
        errstr   => 'name is not valid',
        param    => 'name',
        type     => 'string',
        group_id => $groups->[0]->{id},
        name     => $attr->{NAME},
        reason   => "name already exists in group with id $groups->[0]->{id}"
      } ],
    } if (scalar @{$groups});
  }

  return {
    result => 'OK',
  };
}

1;
