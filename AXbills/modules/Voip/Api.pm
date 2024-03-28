package Voip::Api;
=head NAME

  Voip::Api - Voip api functions

=head VERSION

  DATE: 20221212
  UPDATE: 20221212
  VERSION: 0.01

=cut

use strict;
use warnings FATAL => 'all';

use Voip;
use Voip::Users;

use AXbills::Base qw(next_month);
use Voip::Constants qw/TRUNK_PROTOCOLS/;

my Voip $Voip;
my Voip::Users $Voip_users;

#**********************************************************
=head2 new($db, $conf, $admin, $lang)

=cut
#**********************************************************
sub new {
  my ($class, $db, $admin, $conf, $lang, $debug, $type, $html) = @_;

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $conf,
    lang  => $lang,
    debug => $debug,
    html  => $html
  };

  bless($self, $class);

  $Voip = Voip->new($db, $admin, $conf);
  $Voip_users = Voip::Users->new($db, $admin, $conf, {
    html        => $html,
    lang        => $lang,
    permissions => $admin->{permissions} || {}
  });

  $Voip->{debug} = $self->{debug};

  $self->{routes_list} = ();

  if ($type eq 'user') {
    $self->{routes_list} = $self->user_routes();
  }
  elsif ($type eq 'admin') {
    $self->{routes_list} = $self->admin_routes();
  }

  return $self;
}

#**********************************************************
=head2 user_routes() - Returns available API paths

  ARGUMENTS
    admin_routes: boolean - if true return all admin routes, false - user

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
                        # object of needed DB module (in this example - Users). used to run it's methods.
                                     # may be empty if name of module is not set.
               ) = @_;

          ->info(       # handler should return hashref or arrayref with needed data
              $path_params->{uid}
            );                       # in this example we call Users->info, and it's result are implicitly returned
          },

          module  => 'Users',        # name of DB module. it's object will be created and passed to handler a. optional.

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
sub user_routes {
  my $self = shift;

  return [
    {
      method      => 'GET',
      path        => '/user/voip/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        ::load_module('Control::Services', { LOAD_PACKAGE => 1 });
        my $tariffs = ::get_user_services({
          uid     => $path_params->{uid},
          service => 'Voip',
        });

        return ref $tariffs eq 'ARRAY' ? $tariffs->[0] : $tariffs;
      },
      credentials => [
        'USER'
      ]
    },
    {
      method      => 'GET',
      path        => '/user/voip/sessions/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        my %result = ();
        my @PERIODS = ('Today', 'Yesterday', 'Week', 'Month', 'All sessions');

        $query_params = {
          SORT      => 2,
          DESC      => 'DESC',
          PAGE_ROWS => $query_params->{PAGE_ROWS} || 25,

          #TODO: move it to base params and defined them if they are possible

          FROM_DATE => ($query_params->{TO_DATE} && !$query_params->{FROM_DATE}) ? '0000-00-00' : $query_params->{FROM_DATE} ? $query_params->{FROM_DATE} : undef,
          TO_DATE   => ($query_params->{FROM_DATE} && !$query_params->{TO_DATE}) ? '_SHOW' : $query_params->{TO_DATE} ? $query_params->{TO_DATE} : undef,
        };

        require Voip_Sessions;
        Voip_Sessions->import();
        my $Sessions = Voip_Sessions->new($self->{db}, $self->{admin}, $self->{conf});
        $Sessions->periods_totals({ %$query_params, UID => $path_params->{uid} });

        if (!defined $Sessions->{sum_4}) {
          return {
            result     => 'OK',
            warnings   => 'No sessions',
            warning_id => 30101
          };
        };

        for (my $i = 0; $i < 5; $i++) {
          $result{periods}{$PERIODS[$i]}{duration} = $Sessions->{'duration_' . $i};
          $result{periods}{$PERIODS[$i]}{sum} = $Sessions->{'sum_' . $i};
        }

        $Sessions->calculation($query_params);

        $result{periods}{stats} = {
          min => {
            sum      => $Sessions->{MIN_SUM},
            duration => $Sessions->{MIN_DUR}
          },
          max => {
            sum      => $Sessions->{MAX_SUM},
            duration => $Sessions->{MAX_DUR}
          },
          avg => {
            sum      => $Sessions->{AVG_SUM},
            duration => $Sessions->{AVG_DUR}
          },
        };

        my $sessions = $Sessions->list({
          %$query_params,
          COLS_NAME          => 1,
          TP_ID              => '_SHOW',
          CALLING_STATION_ID => '_SHOW',
          CALLED_STATION_ID  => '_SHOW',
          DURATION           => '_SHOW',
          SUM                => '_SHOW',
        });

        $result{sessions}{total} = {
          sum      => $Sessions->{SUM},
          duration => $Sessions->{DURATION}
        };

        if ($Sessions->{TOTAL} && $Sessions->{TOTAL} > 0) {
          foreach my $session (@{$sessions}) {
            delete @{$session}{qw/acct_session_id call_origin nas_id/};
          }
          $result{sessions}{list} = $sessions;
        }

        return \%result;
      },
      credentials => [
        'USER'
      ]
    },
    {
      method      => 'GET',
      path        => '/user/voip/routes/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        $Voip->user_info($path_params->{uid});

        return {
          errno  => 30011,
          errstr => 'Not active voip service'
        } if (!($Voip->{TOTAL} && $Voip->{TOTAL} > 0));

        require Tariffs;
        Tariffs->import();
        my $Voip_tp = Tariffs->new($self->{db}, $self->{conf}, $self->{admin});

        my $list = $Voip_tp->ti_list({ TP_ID => $Voip->{TP_ID} });

        my @interval_ids = ();
        foreach my $line (@{$list}) {
          push @interval_ids, $line->[0];
        }

        $query_params = {
          PAGE_ROWS => $query_params->{PAGE_ROWS} || 25,
          PG        => $query_params->{PG} || 0,
        };

        $list = $Voip->rp_list({ %$query_params, COLS_NAME => 1 });
        my %prices = ();
        foreach my $line (@{$list}) {
          $prices{$line->{interval_id}}{$line->{route_id}} = $line->{price};
        }

        $list = $Voip->routes_list($query_params);

        my @result = ();
        my $price = 0;
        foreach my $line (@{$list}) {
          for (my $i = 0; $i < $Voip_tp->{TOTAL}; $i++) {
            if (defined($prices{$interval_ids[$i]}{$line->[4]})) {
              $price = $prices{ $interval_ids[$i] }{ $line->[4] };
            }
            else {
              $price = 0;
            }
          }
          push @result, {
            prefix => $line->[0],
            name   => $line->[1],
            status => $line->[2],
            price  => $price
          };
        }

        return \@result;
      },
      credentials => [
        'USER'
      ]
    },
    {
      method      => 'GET',
      path        => '/user/voip/tariffs/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        require Control::Service_control;
        Control::Service_control->import();
        my $Service_control = Control::Service_control->new($self->{db}, $self->{admin}, $self->{conf});

        my $result = $Service_control->available_tariffs({
          SKIP_NOT_AVAILABLE_TARIFFS => 1,
          UID                        => $path_params->{uid},
          MODULE                     => 'Voip'
        });

        return {
          errno  => $result->{errno} || $result->{error},
          errstr => $result->{errstr}
        } if (ref $result eq 'HASH' && ($result->{error} || $result->{errno}));

        return $result;
      },
      credentials => [
        'USER'
      ]
    },
  ]
}

#**********************************************************
=head2 admin_routes() - Returns available API paths

  ARGUMENTS
    admin_routes: boolean - if true return all admin routes, false - user

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
                        # object of needed DB module (in this example - Users). used to run it's methods.
                                     # may be empty if name of module is not set.
               ) = @_;

          ->info(       # handler should return hashref or arrayref with needed data
              $path_params->{uid}
            );                       # in this example we call Users->info, and it's result are implicitly returned
          },

          module  => 'Users',        # name of DB module. it's object will be created and passed to handler a. optional.

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

  #TODO: add API for tariff intervals, recalculation and different reports

  return [
    {
      method      => 'GET',
      path        => '/voip/users/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        foreach my $param (keys %{$query_params}) {
          $query_params->{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0') ? $query_params->{$param} : '_SHOW';
        }

        $query_params->{COLS_NAME} = 1;
        $query_params->{PAGE_ROWS} = $query_params->{PAGE_ROWS} ? $query_params->{PAGE_ROWS} : 25;
        $query_params->{PG} = $query_params->{PG} ? $query_params->{PG} : 0;
        $query_params->{DESC} = $query_params->{DESC} ? $query_params->{DESC} : '';
        $query_params->{SORT} = $query_params->{SORT} ? $query_params->{SORT} : 1;

        if (($query_params->{EXTRA_NUMBERS_DAY_FEE} || $query_params->{EXTRA_NUMBERS_MONTH_FEE}) && !$query_params->{EXTRA_NUMBER}) {
          $query_params->{EXTRA_NUMBER} = '_SHOW'
        }

        $Voip->user_list($query_params);
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'POST',
      path        => '/voip/:uid/',
      handler     => sub {
        my ($path_params, $query_params) = @_;
        delete $query_params->{UID};

        my $result = $Voip_users->voip_user_add({
          %$query_params,
          UID => $path_params->{uid},
        });

        delete @{$result}{qw/object fatal element/};
        return $result;
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'PUT',
      path        => '/voip/:uid/',
      handler     => sub {
        my ($path_params, $query_params) = @_;
        delete $query_params->{UID};

        my $result = $Voip_users->voip_user_chg({
          %$query_params,
          UID => $path_params->{uid},
        });

        delete @{$result}{qw/object fatal element/};
        return $result;
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/voip/:uid/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        $Voip->user_info($path_params->{uid});

        require Shedule;
        Shedule->import();
        my $Schedule = Shedule->new($self->{db}, $self->{admin});

        $Schedule->info({
          UID    => $path_params->{uid},
          TYPE   => 'tp',
          MODULE => 'Voip'
        });

        if ($Schedule->{TOTAL} && $Schedule->{TOTAL} > 0) {
          $Voip->{SCHEDULE_TP_CHANGE} = {
            DATE     => "$Schedule->{Y}-$Schedule->{M}-$Schedule->{D}",
            ADDED    => $Schedule->{DATE},
            ADDED_BY => $Schedule->{ADMIN_NAME},
            TP_ID    => $Schedule->{ACTION},
            ID       => $Schedule->{SHEDULE_ID},
          };
        }

        return $Voip;
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'DELETE',
      path        => '/voip/:uid/',
      handler     => sub {
        my ($path_params, $query_params) = @_;
        delete $query_params->{UID};

        my $result = $Voip_users->voip_user_del({
          %$query_params,
          UID => $path_params->{uid},
        });

        delete @{$result}{qw/object fatal element/};
        return $result;
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'PUT',
      path        => '/voip/:uid/tariff/',
      handler     => sub {
        my ($path_params, $query_params) = @_;
        delete $query_params->{UID};

        my $result = $Voip_users->voip_user_chg_tp({
          %$query_params,
          UID => $path_params->{uid},
        });

        delete @{$result}{qw/object fatal element/};
        return $result;
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'DELETE',
      path        => '/voip/:uid/tariff/',
      handler     => sub {
        my ($path_params, $query_params) = @_;
        delete $query_params->{UID};

        my $result = $Voip_users->voip_schedule_tp_del({
          %$query_params,
          UID => $path_params->{uid},
        });

        delete @{$result}{qw/object fatal element/};
        return $result;
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/voip/phone/aliases/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        $Voip->phone_aliases_list({
          NUMBER    => $query_params->{NUMBER} || '_SHOW',
          DISABLE   => $query_params->{DISABLE} || '_SHOW',
          CHANGED   => $query_params->{CHANGED} || '_SHOW',
          UID       => $query_params->{UID} || '_SHOW',
          COLS_NAME => 1,
          SORT      => $query_params->{SORT} ? $query_params->{SORT} : 1,
          DESC      => $query_params->{DESC} ? $query_params->{DESC} : '',
          PG        => $query_params->{PG} ? $query_params->{PG} : 0,
          PAGE_ROWS => $query_params->{PAGE_ROWS} ? $query_params->{PAGE_ROWS} : 25,
        });
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/voip/:uid/phone/aliases/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        $Voip->phone_aliases_list({
          NUMBER    => $query_params->{NUMBER} || '_SHOW',
          DISABLE   => $query_params->{DISABLE} || '_SHOW',
          CHANGED   => $query_params->{CHANGED} || '_SHOW',
          UID       => $path_params->{uid},
          COLS_NAME => 1,
          SORT      => $query_params->{SORT} ? $query_params->{SORT} : 1,
          DESC      => $query_params->{DESC} ? $query_params->{DESC} : '',
          PG        => $query_params->{PG} ? $query_params->{PG} : 0,
          PAGE_ROWS => $query_params->{PAGE_ROWS} ? $query_params->{PAGE_ROWS} : 25,
        });
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'POST',
      path        => '/voip/:uid/phone/aliases/',
      handler     => sub {
        my ($path_params, $query_params) = @_;
        delete $query_params->{UID};

        my $result = $Voip_users->voip_alias_add({
          %$query_params,
          UID => $path_params->{uid},
        });

        delete @{$result}{qw/object fatal element/};
        return $result;
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'DELETE',
      path        => '/voip/:uid/phone/alias/:id/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        $Voip->phone_aliases_del($path_params->{id}, { UID => $path_params->{uid} });

        if (!$Voip->{errno}) {
          if ($Voip->{AFFECTED} && $Voip->{AFFECTED} =~ /^[0-9]$/) {
            return {
              result => 'Successfully deleted',
            };
          }
          else {
            return {
              errno  => 30004,
              errstr => "Phone alias with id $path_params->{id} and user with uid $path_params->{uid} not exist",
            };
          }
        }
        return $Voip;
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/voip/tariffs/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        foreach my $param (keys %{$query_params}) {
          $query_params->{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0') ? $query_params->{$param} : '_SHOW';
        }

        $query_params->{COLS_NAME} = 1;
        $query_params->{PAGE_ROWS} = $query_params->{PAGE_ROWS} ? $query_params->{PAGE_ROWS} : 25;
        $query_params->{PG} = $query_params->{PG} ? $query_params->{PG} : 0;
        $query_params->{DESC} = $query_params->{DESC} ? $query_params->{DESC} : '';
        $query_params->{SORT} = $query_params->{SORT} ? $query_params->{SORT} : 1;

        return $Voip->tp_list($query_params);
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/voip/tariff/:id/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        $Voip->tp_info($path_params->{id});

        return {
          errno  => 30019,
          errstr => "Tariff with tpId $path_params->{id}"
        } if (!$Voip->{TP_ID} || ($Voip->{errno} && $Voip->{errno} == 2));

        return {
          errno  => $Voip->{errno},
          errstr => $Voip->{errstr},
        } if ($Voip->{errno});

        delete $Voip->{TP_INFO};
        return $Voip;
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'POST',
      path        => '/voip/tariff/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        return {
          errno  => 30001,
          errstr => 'No field id or value id not number',
        } if (!$query_params->{ID});

        return {
          errno  => 30002,
          errstr => 'No field name',
        } if (!$query_params->{NAME});

        my $PARAMS = $self->_tp_add_filter($query_params, 0);

        return $Voip->tp_add($PARAMS);
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'PUT',
      path        => '/voip/tariff/:tpId/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        my $PARAMS = $self->_tp_add_filter($query_params, 1);
        $PARAMS->{TP_ID} = $path_params->{tpId};
        $Voip->tp_change($path_params->{tpId}, $PARAMS);

        return {
          errno      => 30003,
          errstr     => $Voip->{errstr},
          voip_error => $Voip->{errno}
        } if ($Voip->{errno});

        delete $Voip->{TP_INFO};
        return $Voip;
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'DELETE',
      path        => '/voip/tariff/:tpId/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        $Voip->tp_del($path_params->{tpId});

        if (!$Voip->{errno}) {
          if ($Voip->{AFFECTED} && $Voip->{AFFECTED} =~ /^[0-9]$/) {
            return {
              result => 'Successfully deleted',
            };
          }
          else {
            return {
              errno  => 30004,
              errstr => "tpId $path_params->{tpId} not exists",
            };
          }
        }
        return $Voip;
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/voip/routes/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        foreach my $param (keys %{$query_params}) {
          $query_params->{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0') ? $query_params->{$param} : '_SHOW';
        }

        $Voip->routes_list({
          %$query_params,
          ROUTE_NAME   => $query_params->{NAME} || '_SHOW',
          DESCRIBE     => $query_params->{DESCR} || '_SHOW',
          ROUTE_PREFIX => $query_params->{PREFIX} || '_SHOW',
          SORT         => $query_params->{SORT} ? $query_params->{SORT} : 1,
          DESC         => $query_params->{DESC} ? $query_params->{DESC} : '',
          PG           => $query_params->{PG} ? $query_params->{PG} : 0,
          PAGE_ROWS    => $query_params->{PAGE_ROWS} ? $query_params->{PAGE_ROWS} : 25,
          COLS_NAME    => 1
        });
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/voip/route/:id/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        my $route = $Voip->route_info($path_params->{id});
        delete @{$route}{qw/AFFECTED TOTAL/};
        return $route;
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'POST',
      path        => '/voip/route/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        return {
          errno  => 30005,
          errstr => 'no fields prefix or name',
        } if (!$query_params->{PREFIX} || !$query_params->{NAME});

        my $validation_result = _validate_route_add($query_params);
        return $validation_result if ($validation_result->{errno});

        $Voip->route_add({
          ROUTE_PREFIX => $query_params->{PREFIX} || '',
          ROUTE_NAME   => $query_params->{NAME} || '',
          DISABLE      => $query_params->{DISABLE} || 0,
          DESCRIBE     => $query_params->{DESCRIBE} || '',
        });
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'PUT',
      path        => '/voip/route/:id/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        $query_params->{ROUTE_PREFIX} = $query_params->{PREFIX} if (defined $query_params->{PREFIX});
        $query_params->{ROUTE_NAME} = $query_params->{NAME} if (defined $query_params->{NAME});

        my $validation_result = _validate_route_add($query_params);
        return $validation_result if ($validation_result->{errno});

        $Voip->route_change({
          %$query_params,
          ROUTE_ID => $path_params->{id},
        });

        delete @{$Voip}{qw/AFFECTED TOTAL list/};
        return $Voip;
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'DELETE',
      path        => '/voip/route/:id/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        $Voip->route_del($path_params->{id});

        if (!$Voip->{errno}) {
          if ($Voip->{AFFECTED} && $Voip->{AFFECTED} =~ /^[0-9]$/) {
            return {
              result => 'Successfully deleted',
            };
          }
          else {
            return {
              errno  => 30006,
              errstr => "routeId $path_params->{id} not exists",
            };
          }
        }
        return $Voip;
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/voip/extra/tarifications/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        foreach my $param (keys %{$query_params}) {
          $query_params->{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0') ? $query_params->{$param} : '_SHOW';
        }

        $Voip->extra_tarification_list({
          %$query_params,
          SORT         => $query_params->{SORT} ? $query_params->{SORT} : 1,
          DESC         => $query_params->{DESC} ? $query_params->{DESC} : '',
          PG           => $query_params->{PG} ? $query_params->{PG} : 0,
          PAGE_ROWS    => $query_params->{PAGE_ROWS} ? $query_params->{PAGE_ROWS} : 25,
          COLS_NAME    => 1
        });
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/voip/extra/tarification/:id/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        my $route = $Voip->extra_tarification_info({ ID => $path_params->{id} });
        delete @{$route}{qw/AFFECTED TOTAL list/};
        return $route;
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'POST',
      path        => '/voip/extra/tarification/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        return {
          errno  => 30007,
          errstr => 'no fields prepaidTime or name',
        } if (!$query_params->{NAME} || !$query_params->{PREPAID_TIME});

        $Voip->extra_tarification_add({
          NAME         => $query_params->{NAME},
          PREPAID_TIME => $query_params->{PREPAID_TIME} || '',
        });
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'PUT',
      path        => '/voip/extra/tarification/:id/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        return {
          errno  => 30008,
          errstr => 'no fields prepaidTime and name, so no params to change',
        } if (!$query_params->{NAME} && !$query_params->{PREPAID_TIME});

        my $params = {};

        $params->{PREPAID_TIME} = $query_params->{PREPAID_TIME} if (defined $query_params->{PREPAID_TIME});
        $params->{NAME} = $query_params->{NAME} if (defined $query_params->{NAME});

        $Voip->extra_tarification_change({
          %$params,
          ID => $path_params->{id},
        });

        if ($Voip && $Voip->{errno}) {
          return $Voip;
        }
        else {
          return {
            result => "Successfully changed $path_params->{id}"
          };
        }
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'DELETE',
      path        => '/voip/extra/tarification/:id/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        $Voip->extra_tarification_del({ ID => $path_params->{id} });

        if (!$Voip->{errno}) {
          if ($Voip->{AFFECTED} && $Voip->{AFFECTED} =~ /^[0-9]$/) {
            return {
              result => 'Successfully deleted',
            };
          }
          else {
            return {
              errno  => 30015,
              errstr => "tarificationId $path_params->{id} not exists",
            };
          }
        }
        return $Voip;
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/voip/trunk/protocols/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        return TRUNK_PROTOCOLS;
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/voip/trunks/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        $query_params->{NAME} = $query_params->{NAME} || '_SHOW';
        $query_params->{PROTOCOL} = $query_params->{PROTOCOL} || '_SHOW';
        $query_params->{PROVNAME} = $query_params->{PROVIDER_NAME} || '_SHOW';
        $query_params->{FAILTRUNK} = $query_params->{FAILOVER_TRUNK} || '_SHOW';

        foreach my $param (keys %{$query_params}) {
          $query_params->{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0') ? $query_params->{$param} : '_SHOW';
        }

        $Voip->trunk_list({
          %$query_params,
          COLS_NAME => 1,
          PAGE_ROWS => ($query_params->{PAGE_ROWS} ? $query_params->{PAGE_ROWS} : 25),
          SORT      => ($query_params->{SORT} ? $query_params->{SORT} : 1),
          PG        => (defined($query_params->{PG}) ? $query_params->{PG} : 0),
        });
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/voip/trunk/:id/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        $Voip->trunk_info($path_params->{id});
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'POST',
      path        => '/voip/trunk/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        $Voip->trunk_add($query_params);
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'DELETE',
      path        => '/voip/trunk/:id/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        $Voip->trunk_del($path_params->{id});

        if (!$Voip->{errno}) {
          if ($Voip->{AFFECTED} && $Voip->{AFFECTED} =~ /^[0-9]$/) {
            return {
              result => 'Successfully deleted',
            };
          }
          else {
            return {
              errno  => 30010,
              errstr => "trunkId $path_params->{id} not exists",
            };
          }
        }
        return $Voip;
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'PUT',
      path        => '/voip/trunk/:id/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        delete $query_params->{ID};

        $Voip->trunk_change({ %$query_params, ID => $path_params->{id} });
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/voip/sessions/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        require Voip_Sessions;
        Voip_Sessions->import();
        my $Voip_Sessions = Voip_Sessions->new($self->{db}, $self->{admin}, $self->{conf});

        foreach my $param (keys %{$query_params}) {
          $query_params->{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0') ? $query_params->{$param} : '_SHOW';
        }

        my $list = $Voip_Sessions->list({
          %$query_params,
          FROM_DATE => ($query_params->{TO_DATE} && !$query_params->{FROM_DATE}) ? '0000-00-00' : $query_params->{FROM_DATE} ? $query_params->{FROM_DATE} : undef,
          TO_DATE   => ($query_params->{FROM_DATE} && !$query_params->{TO_DATE}) ? '_SHOW' : $query_params->{TO_DATE} ? $query_params->{TO_DATE} : undef,
          COLS_NAME => 1,
        });

        return $list;
      },
      credentials => [
        'ADMIN'
      ]
    },
  ];
}

#**********************************************************
=head2 _tp_add_filter()

=cut
#**********************************************************
sub _tp_add_filter {
  shift;
  my ($query_params, $change) = @_;

  my %PARAMS = ();
  my @allowed_params = (
    'NEXT_PERIOD_STEP',
    'AGE',
    'SIMULTANEOUSLY',
    'FILTER_ID',
    'FEES_METHOD',
    'ACTIV_PRICE',
    'CREDIT_TRESSHOLD',
    'DAY_TIME_LIMIT',
    'MONTH_FEE',
    'CHANGE_PRICE',
    'MONTH_TIME_LIMIT',
    'FIRST_PERIOD_STEP',
    'DAY_FEE',
    'EXTRA_NUMBERS_MONTH_FEE',
    'ID',
    'TIME_DIVISION',
    'ADD_TP',
    'MIN_SESSION_COST',
    'WEEK_TIME_LIMIT',
    'MAX_SESSION_DURATION',
    'FREE_TIME',
    'TIME_TARIF',
    'NAME',
    'PAYMENT_TYPE',
    'FIRST_PERIOD',
    'EXTRA_NUMBERS_DAY_FEE',
    'ALERT',
  );

  foreach my $param (@allowed_params) {
    next if (!$query_params->{$param} && $change);
    $PARAMS{$param} = $query_params->{$param} || '';
  }

  return \%PARAMS;
}

#**********************************************************
=head2 _tp_add_filter()

=cut
#**********************************************************
sub _validate_route_add {
  my ($attr) = @_;

  if ($attr->{PREFIX}) {
    my $routes = $Voip->routes_list({
      ROUTE_PREFIX => $attr->{PREFIX} || '_SHOW',
      COLS_NAME    => 1
    });

    return {
      errno  => 9,
      errstr => 'Validation failed',
      errors => [ {
        errno    => 21,
        errstr   => 'prefix is not valid',
        param    => 'prefix',
        type     => 'number',
        prefix   => $attr->{PREFIX},
        route_id => $routes->[0]->{id},
        reason   => "prefix already exists in route with id $routes->[0]->{id}"
      } ],
    } if ($routes->[0]->{id});
  }

  return {
    result => 'OK',
  };
}

1;
