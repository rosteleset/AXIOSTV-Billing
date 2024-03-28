package Internet::Api;
=head1 NAME

  Internet::Api - Internet api functions

=head VERSION

  DATE: 20220711
  UPDATE: 20220711
  VERSION: 0.01

=cut

use strict;
use warnings FATAL => 'all';

use AXbills::Api::Validations qw(POST_INTERNET_HANGUP POST_INTERNET_TARIFF PUT_INTERNET_TARIFF);
use AXbills::Base qw(json_former);
#TODO: remove next 3 lines after changing of load Internet::Users
use POSIX qw(strftime);
do 'AXbills/Misc.pm';
our $DATE = strftime "%Y-%m-%d", localtime(time);
require 'AXbills/modules/Internet/lng_english.pl';

our (
  $db,
  $admin,
  %conf,
  %permissions
);

use Internet;
my Internet $Internet;

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

  bless($self, $class);

  $self->{routes_list} = ();

  if ($type eq 'admin') {
    $self->{routes_list} = $self->admin_routes();
  }

  $Internet = Internet->new($self->{db}, $self->{admin}, $self->{conf});
  $Internet->{debug} = $self->{debug};
  %permissions = %{$Admin->{permissions} || {}};

  return $self;
}

#**********************************************************
=head2 routes_list() - Returns available API paths

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
      method      => 'POST',
      path        => '/internet/:uid/activate/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        return {
          errno  => 10,
          errstr => 'Access denied'
        } if !$self->{admin}->{permissions}{0}{18};

        return {
          errno  => 102001,
          errstr => 'No field tpId'
        } if !$query_params->{TP_ID};

        return {
          errno  => 102002,
          errstr => 'No field status'
        } if !defined $query_params->{STATUS};

        #TODO: load as ::load_module('Internet::Users', { LOAD_PACKAGE => 1 });
        require Internet::Users;
        require Users;
        Users->import();
        my $Users = Users->new($self->{db}, $self->{admin}, $self->{conf});
        $Users->pi({ UID => $path_params->{uid} });

        #TODO: fix with option $conf{MSG_REGREQUEST_STATUS}=1;
        internet_user_add({
          API              => 1,

          UID              => $path_params->{uid},
          TP_ID            => $query_params->{TP_ID},
          STATUS           => $query_params->{STATUS} || 0,
          USERS_INFO       => $Users,

          CID              => $query_params->{CID},
          IP               => $query_params->{IP} || '0.0.0.0',
          PERSONAL_TP      => $query_params->{PERSONAL_TP} || 0,
          SERVICE_EXPIRE   => $query_params->{SERVICE_EXPIRE} || '0000-00-00',
          SERVICE_ACTIVATE => $query_params->{SERVICE_ACTIVATE} || '0000-00-00',

          PORT             => $query_params->{PORT} || '',
          COMMENTS         => $query_params->{COMMENTS} || '',
          STATIC_IP_POOL   => $query_params->{STATIC_IP_POOL} || '',
          STATUS_DAYS      => $query_params->{STATUS_DAYS} || '',
          NAS_ID           => $query_params->{NAS_ID} || '',
          NAS_ID1          => $query_params->{NAS_ID1} || '',
          CPE_MAC          => $query_params->{CPE_MAC} || '',
          SERVER_VLAN      => $query_params->{SERVER_VLAN} || '',
          VLAN             => $query_params->{VLAN} || '',

          #IPV6
          IPV6_MASK        => $query_params->{IPV6_MASK} || 32,
          IPV6             => $query_params->{IPV6} || '',
          IPV6_PREFIX      => $query_params->{IPV6_PREFIX} || '',
          IPV6_PREFIX_MASK => $query_params->{IPV6_PREFIX_MASK} || 32,
          STATIC_IPV6_POOL => $query_params->{STATIC_IPV6_POOL} || '0',
        });
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'PUT',
      path        => '/internet/:uid/activate/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        return {
          errno  => 10,
          errstr => 'Access denied'
        } if !$self->{admin}->{permissions}{0}{18};

        return {
          errno  => 102003,
          errstr => 'No field id'
        } if !$query_params->{ID};

        return {
          errno  => 102004,
          errstr => 'No field status'
        } if !defined $query_params->{STATUS};

        #TODO: load as ::load_module('Internet::Users', { LOAD_PACKAGE => 1 });
        require Internet::Users;
        require Users;
        Users->import();
        my $Users = Users->new($self->{db}, $self->{admin}, $self->{conf});
        $Users->pi({ UID => $path_params->{uid} });

        #TODO: fix with option $conf{MSG_REGREQUEST_STATUS}=1;
        internet_user_change({
          API              => 1,

          UID              => $path_params->{uid},
          ID               => $query_params->{ID},
          STATUS           => $query_params->{STATUS} || 0,
          USERS_INFO       => $Users,

          CID              => $query_params->{CID},
          IP               => $query_params->{IP} || '0.0.0.0',
          PERSONAL_TP      => $query_params->{PERSONAL_TP} || '0',
          SERVICE_EXPIRE   => $query_params->{SERVICE_EXPIRE} || '0000-00-00',
          SERVICE_ACTIVATE => $query_params->{SERVICE_ACTIVATE} || '0000-00-00',

          PORT             => $query_params->{PORT} || '',
          COMMENTS         => $query_params->{COMMENTS} || '',
          STATIC_IP_POOL   => $query_params->{STATIC_IP_POOL} || '',
          STATUS_DAYS      => $query_params->{STATUS_DAYS} || '',
          NAS_ID           => $query_params->{NAS_ID} || '',
          NAS_ID1          => $query_params->{NAS_ID1} || '',
          CPE_MAC          => $query_params->{CPE_MAC} || '',
          SERVER_VLAN      => $query_params->{SERVER_VLAN} || '',
          VLAN             => $query_params->{VLAN} || '',

          #IPV6
          IPV6_MASK        => $query_params->{IPV6_MASK} || 32,
          IPV6             => $query_params->{IPV6} || '',
          IPV6_PREFIX      => $query_params->{IPV6_PREFIX} || '',
          IPV6_PREFIX_MASK => $query_params->{IPV6_PREFIX_MASK} || 32,
          STATIC_IPV6_POOL => $query_params->{STATIC_IPV6_POOL} || '0',
        });
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/internet/:uid/:id/warnings/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        require Control::Service_control;
        Control::Service_control->import();
        my $Service_control = Control::Service_control->new($self->{db}, $self->{admin}, $self->{conf});

        $Service_control->service_warning({
          UID    => $path_params->{uid},
          ID     => $path_params->{id},
          MODULE => 'Internet'
        });
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'POST',
      path        => '/internet/:uid/session/hangup/',
      params      => POST_INTERNET_HANGUP,
      handler     => sub {
        my ($path_params, $query_params) = @_;

        return {
          errno  => 10,
          errstr => 'Access denied'
        } if !$self->{admin}->{permissions}{5};

        ::load_module('Internet::Monitoring', { LOAD_PACKAGE => 1 });
        ::_internet_hangup({ %$query_params, UID => $path_params->{uid} });
      },
      credentials => [
        'ADMIN'
      ],
    },
    {
      method      => 'GET',
      path        => '/internet/tariffs/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        return {
          errno  => 10,
          errstr => 'Access denied'
        } if !$permissions{4};

        foreach my $param (keys %{$query_params}) {
          $query_params->{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0') ? $query_params->{$param} : '_SHOW';
        }

        $query_params->{ACTIV_PRICE} = $query_params->{ACTIVATE_PRICE} if ($query_params->{ACTIVATE_PRICE});

        if ($query_params->{TP_ID}) {
          $query_params->{INNER_TP_ID} = $query_params->{TP_ID};
          delete $query_params->{TP_ID};
        }
        $query_params->{TP_ID} = $query_params->{ID} if ($query_params->{ID});

        require Tariffs;
        Tariffs->import();
        my $Tariffs = Tariffs->new($self->{db}, $self->{conf}, $self->{admin});

        $Tariffs->list({
          %$query_params,
          MODULE       => 'Internet',
          COLS_NAME    => 1,
        });
      },
      credentials => [
        'ADMIN'
      ],
    },
    {
      method      => 'POST',
      path        => '/internet/tariff/',
      params      => POST_INTERNET_TARIFF,
      handler     => sub {
        my ($path_params, $query_params) = @_;

        $query_params = $self->tariff_add_preprocess($query_params);
        return $query_params if ($query_params->{errno});

        require Tariffs;
        Tariffs->import();
        my $Tariffs = Tariffs->new($self->{db}, $self->{conf}, $self->{admin});

        return $Tariffs->add({ %{$query_params}, MODULE => 'Internet' });
      },
      credentials => [
        'ADMIN'
      ],
    },
    {
      method      => 'PUT',
      path        => '/internet/tariff/:tpId/',
      params      => PUT_INTERNET_TARIFF,
      handler     => sub {
        my ($path_params, $query_params) = @_;

        $query_params = $self->tariff_add_preprocess($query_params);
        return $query_params if ($query_params->{errno});

        require Tariffs;
        Tariffs->import();
        my $Tariffs = Tariffs->new($self->{db}, $self->{conf}, $self->{admin});

        return $Tariffs->change(($path_params->{tpId} || '--'), {
          %{$query_params},
          MODULE => 'Internet',
          TP_ID  => $path_params->{tpId}
        });
      },
      credentials => [
        'ADMIN'
      ],
    },
    {
      method      => 'DELETE',
      path        => '/internet/tariff/:tpId/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        require Shedule;
        Shedule->import();
        my $Schedule = Shedule->new($self->{db}, $self->{conf}, $self->{admin});

        my $users_list = $Internet->user_list({
          TP_ID     => $path_params->{tpId},
          UID       => '_SHOW',
          COLS_NAME => 1
        });

        my $schedules = $Schedule->list({
          ACTION    => "*:$path_params->{tpId}",
          TYPE      => 'tp',
          MODULE    => 'Internet',
          COLS_NAME => 1,
        });

        if (($Internet->{TOTAL} && $Internet->{TOTAL} > 0) || ($Schedule->{TOTAL} && $Schedule->{TOTAL} > 0)) {
          my %users_msg = ();
          foreach my $user_tp (@{$users_list}) {
            $users_msg{active}{message} = 'List of users who currently have an active tariff plan';
            push @{$users_msg{active}{users}}, $user_tp->{uid};
          }

          foreach my $schedule (@{$schedules}) {
            $users_msg{schedule}{message} = 'List of users who have scheduled a change in their tariff plan';
            push @{$users_msg{schedule}{users}}, $schedule->{uid};
          }

          return {
            errno  => 102005,
            errstr => "Can not delete tariff plan with tpId $path_params->{tpId}",
            users  => \%users_msg,
          };
        }
        else {
          require Tariffs;
          Tariffs->import();
          my $Tariffs = Tariffs->new($self->{db}, $self->{conf}, $self->{admin});
          $Tariffs->del($path_params->{tpId});

          if (!$Tariffs->{errno}) {
            if ($Tariffs->{AFFECTED} && $Tariffs->{AFFECTED} =~ /^[0-9]$/) {
              return {
                result => 'Successfully deleted',
              };
            }
            else {
              return {
                errno  => 102006,
                errstr => "No tariff plan with tpId $path_params->{tpId}",
                tpId   => $path_params->{tpId},
              };
            }
          }

          return $Tariffs;
        }
      },
      credentials => [
        'ADMIN'
      ],
    },
  ];
}

#**********************************************************
=head2 new($, $admin, $CONF)

  Arguments:
    $query_params: object - hash of query params from request

  Returns:
    updated $query_params

=cut
#**********************************************************
sub tariff_add_preprocess {
  my $self = shift;
  my ($query_params) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if !$permissions{4};

  $query_params->{SIMULTANEOUSLY} = $query_params->{SIMULTANEOUSLY} if ($query_params->{LOGINS});
  $query_params->{ALERT} = $query_params->{UPLIMIT} if ($query_params->{UPLIMIT});
  $query_params->{ACTIV_PRICE} = $query_params->{ACTIVATE_PRICE} if ($query_params->{ACTIVATE_PRICE});
  $query_params->{NEXT_TARIF_PLAN} = $query_params->{NEXT_TP_ID} if ($query_params->{NEXT_TP_ID});

  if ($query_params->{CREATE_FEES_TYPE}) {
    require Fees;
    Fees->import();
    my $Fees = Fees->new($self->{db}, $self->{admin}, $self->{conf});
    $Fees->fees_type_add({ NAME => $query_params->{NAME}});
    $query_params->{FEES_METHOD} = $Fees->{INSERT_ID};
  }

  if ($query_params->{RAD_PAIRS}) {
    require AXbills::Radius_Pairs;
    AXbills::Radius_Pairs->import();
    $query_params->{RAD_PAIRS} = AXbills::Radius_Pairs::parse_radius_params_json(json_former($query_params->{RAD_PAIRS}));
  }

  if ($query_params->{PERIOD_ALIGNMENT} || $query_params->{ABON_DISTRIBUTION} || $query_params->{FIXED_FEES_DAY}) {
    my $period = $query_params->{PERIOD_ALIGNMENT} ? $query_params->{PERIOD_ALIGNMENT} > 0 : 0;
    my $distribution = $query_params->{ABON_DISTRIBUTION} ? $query_params->{ABON_DISTRIBUTION} > 0 : 0;
    my $fixed = $query_params->{FIXED_FEES_DAY} ? $query_params->{FIXED_FEES_DAY} > 0 : 0;
    return {
      errno  => 102007,
      errstr => "Can not use params periodAlignment, abonDistribution and fixedFeesDay",
    } if (($period + $distribution + $fixed) > 1);
  }

  return $query_params;
}

1;
