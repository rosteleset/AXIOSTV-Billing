package Paysys::Api;
=head NAME

  Paysys::Api - Paysys api functions

=head VERSION

  DATE: 20211227
  UPDATE: 20220524
  VERSION: 0.05

=cut

use strict;
use warnings FATAL => 'all';

use Paysys;
use Paysys::Init;
use AXbills::Base qw(mk_unique_value);

my Paysys $Paysys;
our %lang;
require 'AXbills/modules/Paysys/lng_english.pl';

my %LANG = ();

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
    lang  => $lang,
    debug => $debug
  };

  bless($self, $class);

  $self->{routes_list} = ();

  if ($type eq 'user') {
    $self->{routes_list} = $self->user_routes();
  }

  %LANG = (%{$self->{lang}}, %lang);

  $Paysys = Paysys->new($self->{db}, $self->{admin}, $self->{conf});
  $Paysys->{debug} = $self->{debug};

  return $self;
}

#**********************************************************
=head2 user_routes() - Returns available API paths

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
sub user_routes {
  my $self = shift;

  return [
    {
      method      => 'GET',
      path        => '/user/:uid/paysys/systems/',
      handler     => sub {
        my ($path_params, $query_params) = @_;
        require Users;
        Users->import();
        my $Users = Users->new($self->{db}, $self->{admin}, $self->{conf});

        my $users_info = $Users->list({
          GID       => '_SHOW',
          UID       => $path_params->{uid},
          COLS_NAME => 1,
        });

        my $allowed_systems = $Paysys->groups_settings_list({
          GID       => $users_info->[0]->{gid},
          PAYSYS_ID => '_SHOW',
          COLS_NAME => 1,
          PAGE_ROWS => 50,
        });

        my $systems = $Paysys->paysys_connect_system_list({
          NAME         => '_SHOW',
          MODULE       => '_SHOW',
          ID           => '_SHOW',
          SUBSYSTEM_ID => '_SHOW',
          PAYSYS_ID    => '_SHOW',
          STATUS       => 1,
          COLS_NAME    => 1,
          SORT         => 'priority',
        });

        my @systems_list;
        foreach my $system (@{$systems}) {
          delete @{$system}{qw/status/};

          foreach my $allowed_system (@{$allowed_systems}) {
            next if ($system->{paysys_id} != $allowed_system->{paysys_id});
            my $Module = _configure_load_payment_module($system->{module}, 1);
            next if (ref $Module eq 'HASH' || (!$Module->can('fast_pay_link') && !$Module->can('google_pay') && !$Module->can('apple_pay')));

            my $Paysys_plugin = $Module->new($self->{db}, $self->{admin}, $self->{conf}, { lang => \%LANG });
            my %settings = $Module->get_settings();
            $system->{request} = $settings{REQUEST} if (%settings && $settings{REQUEST});

            if ($settings{SUBSYSTEMS} && ref $settings{SUBSYSTEMS} eq 'HASH' &&  exists($settings{SUBSYSTEMS}{$system->{subsystem_id}})) {
              $system->{module} = ucfirst(lc($settings{SUBSYSTEMS}{$system->{subsystem_id}})) . '.pm';
            }

            if ($query_params->{REQUEST_METHOD} && $system->{request} && $system->{request}->{METHOD}) {
              next if ("$query_params->{REQUEST_METHOD}" ne $system->{request}->{METHOD});
            }

            if ($system->{module} && ($system->{module} eq 'GooglePay.pm' || $system->{module} eq 'ApplePay.pm')) {
              next if ($query_params->{REQUEST_METHOD});
              my $config = $Paysys_plugin->get_config($users_info->[0]->{gid});

              my $config_name = $system->{module} eq 'GooglePay.pm' ? 'google_config' : 'apple_config';
              $system->{$config_name} = $config;
            }
            push(@systems_list, $system);
          }
        }

        return \@systems_list || [];
      },
      credentials => [
        'USER', 'USERBOT'
      ]
    },
    #@deprecated
    {
      method      => 'POST',
      path        => '/user/:uid/paysys/transaction/status/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        $Paysys->list({
          TRANSACTION_ID => $query_params->{TRANSACTION_ID} || '--',
          UID            => $path_params->{uid},
          STATUS         => '_SHOW',
          COLS_NAME      => 1,
          SORT           => 1
        })->[0] || {};
      },
      credentials => [
        'USER'
      ]
    },
    {
      method      => 'GET',
      path        => '/user/paysys/transaction/status/:string_id/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        my $transaction_info = $Paysys->list({
          TRANSACTION_ID => $path_params->{id},
          UID            => $path_params->{uid},
          STATUS         => '_SHOW',
          COLS_NAME      => 1,
          SORT           => 1
        })->[0] || {};

        if (scalar keys %{$transaction_info}) {
          return $transaction_info;
        }
        else {
          return {
            errno  => 605,
            errstr => 'Unknown transaction',
          };
        }
      },
      credentials => [
        'USER'
      ]
    },
    {
      method      => 'POST',
      path        => '/user/:uid/paysys/pay/',
      handler     => sub {
        my ($path_params, $query_params) = @_;
        my $sum = $query_params->{SUM} || 0;
        my $operation_id = $query_params->{OPERATION_ID} || '';

        if (!defined $query_params->{SYSTEM_ID}) {
          return {
            errno  => 601,
            errstr => 'No value: systemId'
          }
        }

        if (!$sum) {
          require Users;
          Users->import();
          my $Users = Users->new($self->{db}, $self->{admin}, $self->{conf});

          my $user = $Users->info($path_params->{uid});
          $sum = ::recomended_pay($user) || 1;
        }

        if (!$operation_id) {
          $operation_id = mk_unique_value(9, { SYMBOLS => '0123456789' }),
        }
        else {
          $operation_id =~ s/[<>]//gm;
        }

        my $paysys = $Paysys->paysys_connect_system_list({
          SHOW_ALL_COLUMNS => 1,
          STATUS           => 1,
          COLS_NAME        => 1,
          ID               => $query_params->{SYSTEM_ID} || '--',
        });

        return [] if (!scalar @{$paysys});

        my %pay_params = (
          UID          => $path_params->{uid},
          SUM          => $sum,
          OPERATION_ID => $operation_id,
          MODULE       => $paysys,
        );

        $pay_params{APAY} = $query_params->{APAY} if ($query_params->{APAY});
        $pay_params{GPAY} = $query_params->{GPAY} if ($query_params->{GPAY});

        return $self->paysys_pay(\%pay_params);
      },
      credentials => [
        'USER', 'USERBOT'
      ]
    },
    {
      method      => 'POST',
      path        => '/user/paysys/applePay/session/',
      handler     => sub {
        my ($path_params, $query_params) = @_;
        my $Module = _configure_load_payment_module('ApplePay.pm', 1);
        return $Module if (ref $Module eq 'HASH');

        my $Paysys_plugin = $Module->new($self->{db}, $self->{admin}, $self->{conf}, { lang => \%LANG });

        return $Paysys_plugin->create_session({
          UID => $path_params->{uid},
        });
      },
      credentials => [
        'USER'
      ]
    },
  ]
}

#**********************************************************
=head2 paysys_pay($attr) function for call fast_pay_link in Paysys modules

  Arguments:
    $attr
      UID           - uid of user
      SUM           - amount of sum payment
      OPERATION_ID  - ID of transaction
      MODULE        - Paysys module

  Result:
    fastpay url or Errno

=cut
#**********************************************************
sub paysys_pay {
  my $self = shift;
  my ($attr) = @_;
  my $Module = _configure_load_payment_module($attr->{MODULE}->[0]->{module}, 1);

  return $Module if (ref $Module eq 'HASH');

  my $Users = Users->new($self->{db}, $self->{admin}, $self->{conf});
  $Users->info($attr->{UID});
  $Users->pi({ UID => $attr->{UID} });
  my %params = (
    %$attr,
    USER => $Users,
  );

  my $Paysys_plugin = $Module->new($self->{db}, $self->{admin}, $self->{conf}, {
    lang        => \%LANG,
    CUSTOM_NAME => $attr->{MODULE}->[0]->{name},
    CUSTOM_ID   => $attr->{MODULE}->[0]->{paysys_id}
  });

  if ($attr->{GPAY} && $Module->can('google_pay')) {
    return $Paysys_plugin->google_pay(\%params);
  }
  elsif ($attr->{APAY} && $Module->can('apple_pay')) {
    return $Paysys_plugin->apple_pay(\%params);
  }
  elsif ($Module->can('fast_pay_link')) {
    return $Paysys_plugin->fast_pay_link(\%params);
  }
  else {
    return {
      errno  => 610,
      errstr => 'No fast pay link for this module'
    };
  }
}

1;
