package Abon::Api;
=head NAME

  Abon::Api - Abon api functions

=head VERSION

  DATE: 20220628
  UPDATE: 20220628
  VERSION: 0.01

=cut

use strict;
use warnings FATAL => 'all';

use Abon;
my Abon $Abon;
my $Abon_services;

use AXbills::Base qw(date_diff);

our %lang;
require 'AXbills/modules/Abon/lng_english.pl';

#**********************************************************
=head2 new($db, $conf, $admin, $lang)

=cut
#**********************************************************
sub new {
  my ($class, $db, $admin, $conf, $lang, $debug, $type) = @_;

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $conf,
    lang  => { %{$lang}, %lang },
    debug => $debug
  };

  bless($self, $class);

  $Abon = Abon->new($self->{db}, $self->{admin}, $self->{conf});
  $Abon->{debug} = $self->{debug};

  require Abon::Services;
  $Abon_services = Abon::Services->new($self->{db}, $self->{admin}, $self->{conf}, { LANG => $self->{lang} });

  $self->{routes_list} = ();
  $self->{periods} = [ 'day', 'month', 'quarter', 'six months', 'year' ];

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
      path        => '/user/:uid/abon/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        ::load_module('Control::Services', { LOAD_PACKAGE => 1 });
        return ::get_user_services({
          uid     => $path_params->{uid},
          service => 'Abon',
        });
      },
      credentials => [
        'USER', 'USERBOT'
      ]
    },
    {
      method      => 'POST',
      path        => '/user/:uid/abon/:id/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        my $services = $Abon->tariff_info($path_params->{id});

        if ($services->{USER_PORTAL} < 2 && !$services->{MANUAL_ACTIVATE}) {
          return {
            errno  => 200,
            errstr => 'Unknown operation'
          }
        }

        $Abon_services->abon_user_tariff_activate({
          %{$query_params},
          UID => $path_params->{uid},
          ID  => $path_params->{id},
        });
      },
      credentials => [
        'USER', 'USERBOT'
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

  return [
    {
      method      => 'GET',
      path        => '/abon/tariffs/',
      handler     => sub {
        my ($path_params, $query_params) = @_;
        $Abon->tariff_list({
          %$query_params,
          COLS_NAME => 1
        });
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'POST',
      path        => '/abon/tariffs/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        $Abon->tariff_add({
          %$query_params
        });
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/abon/tariffs/:id/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        $Abon->tariff_info($path_params->{id});
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'POST',
      path        => '/abon/tariffs/:id/users/:uid/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        $Abon_services->abon_user_tariff_activate({
          DEBUG => 0,
          % { $query_params },
          UID   => $path_params->{uid},
          ID    => $path_params->{id},
        });
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'DELETE',
      path        => '/abon/tariffs/:id/users/:uid/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        $Abon_services->abon_user_tariff_deactivate({
          %{$query_params},
          UID => $path_params->{uid},
          ID  => $path_params->{id},
        });
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/abon/users/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        $Abon->user_list({
          %$query_params,
          COLS_NAME => 1
        });
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/abon/plugin/:plugin_id/info/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        require Abon::Base;
        my $Abon_base = Abon::Base->new($self->{db}, $self->{admin}, $self->{conf}, { LANG => $self->{lang} });

        my $Plugin_info = $Abon->tariff_info($path_params->{plugin_id});
        my $api = $Abon_base->abon_load_plugin($Plugin_info->{PLUGIN}, { SERVICE => $Plugin_info, DEBUG => 0, RETURN_ERROR => 1 });
        return $api->info($query_params) if ($api->can('info'));
        return {};
      },
      credentials => [
        'ADMINSID'
      ]
    },
    {
      method       => 'GET',
      path         => '/abon/plugin/:plugin_id/print/',
      handler      => sub {
        my ($path_params, $query_params) = @_;

        require Abon::Base;
        my $Abon_base = Abon::Base->new($self->{db}, $self->{admin}, $self->{conf}, { LANG => $self->{lang} });

        my $Plugin_info = $Abon->tariff_info($path_params->{plugin_id});
        my $api = $Abon_base->abon_load_plugin($Plugin_info->{PLUGIN}, { SERVICE => $Plugin_info, DEBUG => 0, RETURN_ERROR => 1 });

        return $api->print($query_params) if ($api->can('print'));
      },
      credentials  => [
        'ADMINSID'
      ],
      content_type => 'Content-type: application/pdf'
    }
  ],
}

1;
