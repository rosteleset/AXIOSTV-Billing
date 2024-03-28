package AXbills::Api::Paths;

use strict;
use warnings FATAL => 'all';

use AXbills::Base qw(in_array mk_unique_value camelize);
use AXbills::Api::Helpers qw(static_string_generate caesar_cipher);
use AXbills::Api::Validations qw(POST_INTERNET_MAC_DISCOVERY);

my $VERSION = 1.21;

#**********************************************************
=head2 new($db, $conf, $admin, $lang)

=cut
#**********************************************************
sub new {
  my ($class, $db, $admin, $conf, $lang, $html) = @_;

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $conf,
    lang  => $lang,
    html  => $html,
  };

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 load_own_resource_info($attr)

  Arguments:
    $attr
      package       - package
      modules       - list of modules

  Returns:
    List of routes
=cut
#**********************************************************
sub load_own_resource_info {
  my $self = shift;
  my ($attr) = @_;

  my $extra_modules = $self->_extra_api_modules();
  my @modules = (@main::MODULES, @{$extra_modules});

  $attr->{package} = ucfirst($attr->{package} || q{});

  if (!in_array($attr->{package}, \@modules)) {
    return 0;
  }

  my $module = $attr->{package} . '::Api';
  eval "use $module";

  if ($@ || !$module->can('new')) {
    $@ = undef;
    $module = 'AXbills::Api::Paths::' . $attr->{package};
    eval "use $module";

    if ($@ || !$module->can('new')) {
      return 0;
    }
  }

  if ($attr->{type} eq 'admin' && $self->{admin}->{MODULES} && !$self->{admin}->{MODULES}->{$attr->{package}}) {
    return 2;
  }
  my $module_obj = $module->new($self->{db}, $self->{admin}, $self->{conf}, $self->{lang}, $attr->{debug}, $attr->{type}, $self->{html});
  return $module_obj->{routes_list};
}

#**********************************************************
=head2 _extra_api_modules() return extra modules files of API

  Returns:
    List of extra modules

=cut
#**********************************************************
sub _extra_api_modules {
  my $self = shift;

  my @modules_list = (
    'Contacts'
  );

  if ($self->{conf}->{VIBER_TOKEN} || $self->{conf}->{TELEGRAM_TOKEN}) {
    push @modules_list, 'Bots';
  }

  return \@modules_list;
}

#**********************************************************
=head2 list() - Returns available API paths

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
sub list {
  my $self = shift;

  #TODO: check how it works with groups, multidoms
  return {
    users     => [
      {
        method               => 'POST',
        path                 => '/users/login/',
        handler              => sub {
          my ($path_params, $query_params) = @_;
          return $self->_users_login($path_params, $query_params);
        },
        no_decamelize_params => 1,
      },
      {
        method      => 'GET',
        path        => '/users/all/',
        handler     => sub {
          my ($path_params, $query_params, $module_obj) = @_;

          return {
            errno  => 10,
            errstr => 'Access denied'
          } if !$self->{admin}->{permissions}{0}{2};

          foreach my $param (keys %{$query_params}) {
            $query_params->{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0') ? $query_params->{$param} : '_SHOW';
          }

          $query_params->{PAGE_ROWS} = $query_params->{PAGE_ROWS} || 25;
          $query_params->{SORT} = $query_params->{SORT} || 1;
          $query_params->{DESC} = $query_params->{DESC} || '';
          $query_params->{PG} = $query_params->{PG} || 0;

          my $users = $module_obj->list({
            %{$query_params},
            COLS_NAME => 1,
          });

          if (in_array('Tags', \@main::MODULES) && $query_params->{TAGS}) {
            foreach my $user (@{$users}) {
              my @tags = $user->{tags} ? split('\s?,\s?', $user->{tags}) : ();
              $user->{tags} = \@tags;
            }
          }

          return $users;
        },
        module      => 'Users',
        credentials => [
          'ADMIN', 'ADMINSID'
        ]
      },
      {
        method      => 'GET',
        path        => '/users/:uid/',
        handler     => sub {
          my ($path_params, $query_params, $module_obj) = @_;

          return {
            errno  => 10,
            errstr => 'Access denied'
          } if !$self->{admin}->{permissions}{0}{0};

          my @allowed_params = (
            'SHOW_PASSWORD'
          );
          my %PARAMS = ();
          foreach my $param (@allowed_params) {
            next if (!defined($query_params->{$param}));
            $PARAMS{$param} = '_SHOW';
          }

          $module_obj->info($path_params->{uid}, \%PARAMS);
        },
        module      => 'Users',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method      => 'PUT',
        path        => '/users/:uid/',
        handler     => sub {
          my ($path_params, $query_params, $module_obj) = @_;

          my $Users = $module_obj;

          return {
            errno  => 10,
            errstr => 'Access denied'
          } if !$self->{admin}->{permissions}{0}{4};

          $Users->change($path_params->{uid}, {
            %$query_params
          });

          if (!$Users->{errno}) {
            if ($query_params->{CREDIT} && $query_params->{CREDIT_DATE}) {
              ::cross_modules('payments_maked', { USER_INFO => $Users, SUM => $query_params->{CREDIT}, SILENT => 1, CREDIT_NOTIFICATION => 1 });
            }

            $Users->pi_change({
              UID => $path_params->{uid},
              %$query_params
            });
          }

          return $Users;
        },
        module      => 'Users',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method      => 'DELETE',
        path        => '/users/:uid/',
        handler     => sub {
          my ($path_params, $query_params, $Users) = @_;

          return {
            errno  => 10,
            errstr => 'Access denied'
          } if !$self->{admin}->{permissions}{0}{5};

          my @allowed_params = (
            'COMMENTS',
            'DATE',
          );
          my %PARAMS = ();
          foreach my $param (@allowed_params) {
            next if (!defined($query_params->{$param}));
            $PARAMS{$param} = '_SHOW';
          }

          $Users->del({
            %PARAMS,
            UID => $path_params->{uid}
          });

          if (!$Users->{errno}) {
            return {
              result => "Successfully deleted user with uid $path_params->{uid}",
              uid    => $path_params->{uid},
            };
          }
          else {
            return $Users;
          }
        },
        module      => 'Users',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method      => 'GET',
        path        => '/users/:uid/pi/',
        handler     => sub {
          my ($path_params, $query_params, $module_obj) = @_;

          return {
            errno  => 10,
            errstr => 'Access denied'
          } if !$self->{admin}->{permissions}{0}{0};

          $module_obj->pi({ UID => $path_params->{uid} });
        },
        module      => 'Users',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method      => 'POST',
        path        => '/users/',
        handler     => sub {
          my ($path_params, $query_params, $module_obj) = @_;

          my $Users = $module_obj;

          return {
            errno  => 10,
            errstr => 'Access denied'
          } if !$self->{admin}->{permissions}{0}{1};

          $Users->add({
            %$query_params
          });

          if (!$Users->{errno}) {
            $Users->pi_add({
              UID => $Users->{UID},
              %$query_params
            });
          }

          return $Users;
        },
        module      => 'Users',
        credentials => [
          'ADMIN'
        ]
      },
      #@deprecated
      {
        method      => 'POST',
        path        => '/users/:uid/pi/',
        handler     => sub {
          my ($path_params, $query_params, $module_obj) = @_;

          return {
            errno  => 10,
            errstr => 'Access denied'
          } if !$self->{admin}->{permissions}{0}{1};

          $module_obj->pi_add({
            %$query_params,
            UID => $path_params->{uid}
          });
        },
        module      => 'Users',
        credentials => [
          'ADMIN'
        ]
      },
      #@deprecated
      {
        method      => 'PUT',
        path        => '/users/:uid/pi/',
        handler     => sub {
          my ($path_params, $query_params, $module_obj) = @_;

          return {
            errno  => 10,
            errstr => 'Access denied'
          } if !$self->{admin}->{permissions}{0}{4};

          $module_obj->pi_change({
            %$query_params,
            UID => $path_params->{uid}
          });
        },
        module      => 'Users',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method      => 'GET',
        path        => '/users/:uid/abon/',
        handler     => sub {
          my ($path_params, $query_params, $module_obj) = @_;

          return {
            errno  => 10,
            errstr => 'Access denied'
          } if $self->{admin}->{MODULES} && !$self->{admin}->{MODULES}->{Abon};

          $module_obj->user_tariff_list($path_params->{uid}, {
            COLS_NAME => 1
          });
        },
        module      => 'Abon',
        credentials => [
          'ADMIN'
        ]
      },
      #@deprecated
      {
        method      => 'POST',
        path        => '/users/:uid/internet/',
        handler     => sub {
          my ($path_params, $query_params, $module_obj) = @_;

          return {
            errno  => 10,
            errstr => 'Access denied'
          } if ($self->{admin}->{MODULES} && !$self->{admin}->{MODULES}->{Internet}) || !$self->{admin}->{permissions}{0}{10};

          $module_obj->user_add({
            %$query_params,
            UID => $path_params->{uid}
          });
        },
        module      => 'Internet',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method      => 'GET',
        path        => '/users/internet/all/',
        handler     => sub {
          my ($path_params, $query_params, $module_obj) = @_;

          return {
            errno  => 10,
            errstr => 'Access denied'
          } if $self->{admin}->{MODULES} && !$self->{admin}->{MODULES}->{Internet};

          foreach my $param (keys %{$query_params}) {
            $query_params->{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0') ? $query_params->{$param} : '_SHOW';
          }

          $query_params->{PAGE_ROWS} = $query_params->{PAGE_ROWS} || 25;
          $query_params->{SORT} = $query_params->{SORT} || 1;
          $query_params->{DESC} = $query_params->{DESC} || '';
          $query_params->{PG} = $query_params->{PG} || 0;

          $query_params->{SIMULTANEONSLY} = $query_params->{LOGINS} if ($query_params->{LOGINS});

          my $users = $module_obj->user_list({
            %{$query_params},
            COLS_NAME => 1,
          });

          if (in_array('Tags', \@main::MODULES) && $query_params->{TAGS}) {
            foreach my $user (@{$users}) {
              my @tags = $user->{tags} ? split('\s?,\s?', $user->{tags}) : ();
              $user->{tags} = \@tags;
            }
          }

          return $users;
        },
        module      => 'Internet',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method      => 'GET',
        path        => '/users/:uid/internet/',
        handler     => sub {
          my ($path_params, $query_params, $module_obj) = @_;

          return {
            errno  => 10,
            errstr => 'Access denied'
          } if $self->{admin}->{MODULES} && !$self->{admin}->{MODULES}->{Internet};

          foreach my $param (keys %{$query_params}) {
            $query_params->{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0') ? $query_params->{$param} : '_SHOW';
          }

          $module_obj->user_list({
            %$query_params,
            UID             => $path_params->{uid},
            CID             => '_SHOW',
            INTERNET_STATUS => '_SHOW',
            TP_NAME         => '_SHOW',
            MONTH_FEE       => '_SHOW',
            DAY_FEE         => '_SHOW',
            TP_ID           => '_SHOW',
            GROUP_BY        => 'internet.id',
            COLS_NAME       => 1
          });
        },
        module      => 'Internet',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method      => 'GET',
        path        => '/users/:uid/internet/:id/',
        handler     => sub {
          my ($path_params, $query_params, $module_obj) = @_;

          return {
            errno  => 10,
            errstr => 'Access denied'
          } if $self->{admin}->{MODULES} && !$self->{admin}->{MODULES}->{Internet};

          $module_obj->user_info($path_params->{uid}, {
            %$query_params,
            ID        => $path_params->{id},
            COLS_NAME => 1
          });
        },
        module      => 'Internet',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method      => 'POST',
        path        => '/users/contacts/',
        handler     => sub {
          my ($path_params, $query_params, $module_obj) = @_;

          return {
            errno  => 10,
            errstr => 'Access denied'
          } if !$self->{admin}->{permissions}{0}{4};

          $module_obj->contacts_list({
            %$query_params,
            UID => '_SHOW'
          });
        },
        module      => 'Contacts',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method      => 'GET',
        path        => '/users/:uid/contacts/',
        handler     => sub {
          my ($path_params, $query_params, $module_obj) = @_;

          return {
            errno  => 10,
            errstr => 'Access denied'
          } if !$self->{admin}->{permissions}{0}{0};

          $module_obj->contacts_list({
            UID       => $path_params->{uid},
            VALUE     => '_SHOW',
            PRIORITY  => '_SHOW',
            TYPE      => '_SHOW',
            TYPE_NAME => '_SHOW',
          });
        },
        module      => 'Contacts',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method      => 'POST',
        path        => '/users/:uid/contacts/',
        handler     => sub {
          my ($path_params, $query_params, $module_obj) = @_;

          return {
            errno  => 10,
            errstr => 'Access denied'
          } if !$self->{admin}->{permissions}{0}{1};

          $module_obj->contacts_add({
            %$query_params,
            UID => $path_params->{uid},
          });
        },
        module      => 'Contacts',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method      => 'DELETE',
        path        => '/users/:uid/contacts/:id/',
        handler     => sub {
          my ($path_params, $query_params, $module_obj) = @_;

          return {
            errno  => 10,
            errstr => 'Access denied'
          } if !$self->{admin}->{permissions}{0}{5};

          $module_obj->contacts_del({
            ID  => $path_params->{id},
            UID => $path_params->{uid}
          });
        },
        module      => 'Contacts',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method      => 'PUT',
        path        => '/users/:uid/contacts/:id/',
        handler     => sub {
          my ($path_params, $query_params, $module_obj) = @_;

          return {
            errno  => 10,
            errstr => 'Access denied'
          } if !$self->{admin}->{permissions}{0}{4};

          $module_obj->contacts_change({
            %$query_params,
            ID  => $path_params->{id},
            UID => $path_params->{uid}
          });
        },
        module      => 'Contacts',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method      => 'GET',
        path        => '/users/:uid/iptv/',
        handler     => sub {
          my ($path_params, $query_params, $module_obj) = @_;

          return {
            errno  => 10,
            errstr => 'Access denied'
          } if $self->{admin}->{MODULES} && !$self->{admin}->{MODULES}->{Iptv};

          $module_obj->user_list({
            %$query_params,
            UID          => $path_params->{uid},
            SERVICE_ID   => '_SHOW',
            TP_FILTER    => '_SHOW',
            MONTH_FEE    => '_SHOW',
            DAY_FEE      => '_SHOW',
            TP_NAME      => '_SHOW',
            SUBSCRIBE_ID => '_SHOW',
            COLS_NAME    => 1
          });
        },
        module      => 'Iptv',
        credentials => [
          'ADMIN'
        ]
      },
      {
        #TODO: :uid is not used
        method      => 'GET',
        path        => '/users/:uid/iptv/:id/',
        handler     => sub {
          my ($path_params, $query_params, $module_obj) = @_;

          return {
            errno  => 10,
            errstr => 'Access denied'
          } if $self->{admin}->{MODULES} && !$self->{admin}->{MODULES}->{Iptv};

          $module_obj->user_info($path_params->{id}, {
            %$query_params,
            COLS_NAME => 1
          });
        },
        module      => 'Iptv',
        credentials => [
          'ADMIN'
        ]
      },
    ],
    admins    => [
      {
        method      => 'POST',
        path        => '/admins/:aid/contacts/',
        handler     => sub {
          my ($path_params, $query_params, $module_obj) = @_;

          return {
            errno  => 10,
            errstr => 'Access denied'
          } if !$self->{admin}->{permissions}{4}{4};

          $module_obj->admin_contacts_add({
            %$query_params,
            AID => $path_params->{aid},
          });
        },
        module      => 'Admins',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method      => 'PUT',
        path        => '/admins/:aid/contacts/',
        handler     => sub {
          my ($path_params, $query_params, $module_obj) = @_;

          return {
            errno  => 10,
            errstr => 'Access denied'
          } if !$self->{admin}->{permissions}{4}{4};

          $module_obj->admin_contacts_change({
            %$query_params,
            AID => $path_params->{aid}
          });
        },
        module      => 'Admins',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method      => 'GET',
        path        => '/admins/:aid/',
        handler     => sub {
          my ($path_params, $query_params, $module_obj) = @_;

          return {
            errno  => 10,
            errstr => 'Access denied'
          } if !$self->{admin}->{permissions}{4}{4};

          $module_obj->info($path_params->{aid}, {
            %$query_params
          });
        },
        module      => 'Admins',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method      => 'POST',
        path        => '/admins/',
        handler     => sub {
          my ($path_params, $query_params, $module_obj) = @_;

          return {
            errno  => 10,
            errstr => 'Access denied'
          } if !$self->{admin}->{permissions}{4}{4};

          return {
            errno  => 700,
            errstr => 'No field aLogin'
          } if !$query_params->{A_LOGIN};

          my $admin_regex = $self->{conf}->{ADMINNAMEREGEXP} || '^\S{1,}$';

          return {
            errno  => 701,
            errstr => 'Not valid login admin',
            regexp => "$admin_regex",
          } if $query_params->{A_LOGIN} !~ /$admin_regex/;

          $module_obj->{MAIN_AID} = $self->{admin}->{AID};
          $module_obj->{MAIN_SESSION_IP} = $ENV{REMOTE_ADDR};

          $module_obj->add({
            A_LOGIN          => $query_params->{A_LOGIN},
            A_FIO            => $query_params->{A_FIO} || '',
            PASPORT_GRANT    => $query_params->{PASPORT_GRANT} || '',
            BIRTHDAY         => $query_params->{BIRTHDAY} || '0000-00-00',
            GID              => $query_params->{GID} || 0,
            RFID_NUMBER      => $query_params->{RFID_NUMBER} || '',
            MIN_SEARCH_CHARS => $query_params->{MIN_SEARCH_CHARS} || 0,
            EMAIL            => $query_params->{EMAIL} || '',
            CELL_PHONE       => $query_params->{CELL_PHONE} || '',
            PASPORT_DATE     => $query_params->{PASPORT_DATE} || '0000-00-00',
            GPS_IMEI         => $query_params->{GPS_IMEI} || '',
            ADDRESS          => $query_params->{ADDRESS} || '',
            DOMAIN_ID        => $query_params->{DOMAIN_ID} || 0,
            PASPORT_NUM      => $query_params->{PASPORT_NUM} || '',
            MAX_CREDIT       => $query_params->{MAX_CREDIT} || 0,
            INN              => $query_params->{INN} || '',
            TELEGRAM_ID      => $query_params->{TELEGRAM_ID} || '',
            PHONE            => $query_params->{PHONE} || '',
            COMMENTS         => $query_params->{COMMENTS} || '',
            DISABLE          => $query_params->{DISABLE} || '',
            MAX_ROWS         => $query_params->{MAX_ROWS} || 0,
            ANDROID_ID       => $query_params->{ANDROID_ID} || '',
            EXPIRE           => $query_params->{EXPIRE} || '0000-00-00 00:00:00',
            CREDIT_DAYS      => $query_params->{CREDIT_DAYS} || 0,
            API_KEY          => $query_params->{API_KEY} || '',
            SIP_NUMBER       => $query_params->{SIP_NUMBER} || '',
          });
        },
        module      => 'Admins',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method      => 'PUT',
        path        => '/admins/:aid/',
        handler     => sub {
          my ($path_params, $query_params, $module_obj) = @_;

          return {
            errno  => 10,
            errstr => 'Access denied'
          } if !$self->{admin}->{permissions}{4}{4};

          if ($query_params->{A_LOGIN}) {
            my $admin_regex = $self->{conf}->{ADMINNAMEREGEXP} || '^\S{1,}$';

            return {
              errno  => 701,
              errstr => 'Not valid login admin',
              regexp => "$admin_regex",
            } if $query_params->{A_LOGIN} !~ /$admin_regex/;
          }

          $module_obj->{AID} = $path_params->{aid};
          $module_obj->{MAIN_AID} = $self->{admin}->{AID};
          $module_obj->{MAIN_SESSION_IP} = $ENV{REMOTE_ADDR};

          $module_obj->change({
            AID => $path_params->{aid},
            %$query_params
          });
        },
        module      => 'Admins',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method      => 'POST',
        path        => '/admins/:aid/permissions/',
        handler     => sub {
          my ($path_params, $query_params, $module_obj) = @_;

          return {
            errno  => 10,
            errstr => 'Access denied'
          } if !$self->{admin}->{permissions}{4}{4};

          $module_obj->{AID} = $path_params->{aid};
          $module_obj->{MAIN_AID} = $self->{admin}->{AID};
          $module_obj->{MAIN_SESSION_IP} = $ENV{REMOTE_ADDR};

          $module_obj->set_permissions($query_params);

          if ($module_obj->{errno}) {
            return $module_obj;
          }
          else {
            return {
              result => 'Permissions successfully set',
              aid    => $path_params->{aid}
            };
          }
        },
        module      => 'Admins',
        credentials => [
          'ADMIN'
        ]
      },
    ],
    tp        => [
      {
        method      => 'GET',
        path        => '/tp/:tpID/',
        handler     => sub {
          my ($path_params, $query_params, $module_obj) = @_;

          return {
            errno  => 10,
            errstr => 'Access denied'
          } if !$self->{admin}->{permissions}{0}{10};

          $module_obj->info(undef, {
            %$query_params,
            TP_ID => $path_params->{tpID}
          });
        },
        module      => 'Tariffs',
        credentials => [
          'ADMIN'
        ]
      },
    ],
    intervals => [
      {
        method      => 'GET',
        path        => '/intervals/:tpId/',
        handler     => sub {
          my ($path_params, $query_params, $module_obj) = @_;

          return {
            errno  => 10,
            errstr => 'Access denied'
          } if !$self->{admin}->{permissions}{0}{10};

          $module_obj->ti_info($path_params->{tpId});
        },
        module      => 'Tariffs',
        credentials => [
          'ADMIN'
        ]
      }
    ],
    groups    => [
      {
        method      => 'GET',
        path        => '/groups/',
        handler     => sub {
          my ($path_params, $query_params, $module_obj) = @_;

          return {
            errno  => 10,
            errstr => 'Access denied'
          } if !$self->{admin}->{permissions}{0}{28};

          $module_obj->groups_list({
            NAME           => '_SHOW',
            DOMAIN_ID      => '_SHOW',
            DESCR          => '_SHOW',
            DISABLE_CHG_TP => '_SHOW',
            COLS_NAME      => 1
          });
        },
        module      => 'Users',
        credentials => [
          'ADMIN'
        ]
      }
    ],
    version   => [
      {
        method  => 'GET',
        path    => '/version/',
        handler => sub {
          my $version = ::get_version();
          ($version) = $version =~ /\d+.\d+.\d+/g;
          return {
            version     => "$version",
            billing     => 'ABillS',
            api_version => $VERSION,
          };
        },
      }
    ],
    config    => [
      {
        method  => 'GET',
        path    => '/config/',
        handler => sub {
          my %config = ();
          $config{social_auth}{facebook} = 1 if ($self->{conf}->{AUTH_FACEBOOK_ID});
          $config{social_auth}{google} = 1 if ($self->{conf}->{AUTH_GOOGLE_ID});
          $config{password_recovery} = 1 if ($self->{conf}->{PASSWORD_RECOVERY});
          if ($self->{conf}->{NEW_REGISTRATION_FORM}) {
            $config{registration}{facebook} = 1 if ($self->{conf}->{FACEBOOK_REGISTRATION});
            $config{registration}{google} = 1 if ($self->{conf}->{GOOGLE_REGISTRATION});
          }
          else {
            $config{registration}{internet} = 1 if (in_array('Internet', \@main::MODULES) && in_array('Internet', \@main::REGISTRATION));
          }
          $config{login}{regx} = $self->{conf}->{USERNAMEREGEXP} if ($self->{conf}->{USERNAMEREGEXP});
          $config{login}{max_length} = $self->{conf}->{MAX_USERNAME_LENGTH} if ($self->{conf}->{MAX_USERNAME_LENGTH});
          $config{password}{symbols} = $self->{conf}->{PASSWD_SYMBOLS} if ($self->{conf}->{PASSWD_SYMBOLS});
          $config{password}{length} = $self->{conf}->{PASSWD_LENGTH} if ($self->{conf}->{PASSWD_LENGTH});
          $config{portal_news} = 1 if ($self->{conf}->{PORTAL_START_PAGE});

          return \%config;
        },
      },
    ],
    builds    => [
      {
        method      => 'GET',
        path        => '/builds/',
        handler     => sub {
          my ($path_params, $query_params, $module_obj) = @_;

          # return {
          #   errno  => 10,
          #   errstr => 'Access denied'
          # } if !$self->{admin}->{permissions}{0}{35};

          foreach my $param (keys %{$query_params}) {
            $query_params->{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0') ? $query_params->{$param} : '_SHOW';
          }

          $module_obj->build_list({
            %$query_params,
            COLS_NAME     => 1,
            DISTRICT_NAME => '_SHOW',
            STREET_NAME   => '_SHOW'
          });
        },
        module      => 'Address',
        credentials => [
          'ADMIN', 'ADMINSID'
        ]
      },
      {
        method      => 'GET',
        path        => '/builds/:id/',
        handler     => sub {
          my ($path_params, $query_params, $module_obj) = @_;

          # return {
          #   errno  => 10,
          #   errstr => 'Access denied'
          # } if !$self->{admin}->{permissions}{0}{35};

          $module_obj->build_info({
            %$query_params,
            COLS_NAME => 1,
            ID        => $path_params->{id}
          });

          delete @{$module_obj}{qw/list/};
          return $module_obj;
        },
        module      => 'Address',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method      => 'POST',
        path        => '/builds/',
        handler     => sub {
          my ($path_params, $query_params, $module_obj) = @_;

          return {
            errno  => 10,
            errstr => 'Access denied'
          } if !$self->{admin}->{permissions}{0}{35};

          return {
            errno  => 10097,
            errstr => 'No field streetId'
          } if (!$query_params->{STREET_ID});

          return {
            errno  => 10098,
            errstr => 'No field number'
          } if (!$query_params->{NUMBER});

          $module_obj->build_add({
            %$query_params
          });

          return $module_obj if ($module_obj->{errno});

          $module_obj->build_info({
            COLS_NAME => 1,
            ID        => $module_obj->{INSERT_ID}
          });

          delete @{$module_obj}{qw/list/};
          return $module_obj;
        },
        module      => 'Address',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method      => 'PUT',
        path        => '/builds/:id/',
        handler     => sub {
          my ($path_params, $query_params, $module_obj) = @_;

          return {
            errno  => 10,
            errstr => 'Access denied'
          } if !$self->{admin}->{permissions}{0}{35};

          $module_obj->build_change({
            %$query_params,
            ID => $path_params->{id},
          });

          return $module_obj if ($module_obj->{errno});

          $module_obj->build_info({
            COLS_NAME => 1,
            ID        => $path_params->{id}
          });

          delete @{$module_obj}{qw/list/};
          return $module_obj;
        },
        module      => 'Address',
        credentials => [
          'ADMIN'
        ]
      },
    ],
    streets   => [
      {
        method      => 'GET',
        path        => '/streets/',
        handler     => sub {
          my ($path_params, $query_params, $module_obj) = @_;

          foreach my $param (keys %{$query_params}) {
            $query_params->{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0') ? $query_params->{$param} : '_SHOW';
          }

          # return {
          #   errno  => 10,
          #   errstr => 'Access denied'
          # } if !$self->{admin}->{permissions}{0}{34};

          $module_obj->street_list({
            DISTRICT_ID => '_SHOW',
            %$query_params,
            COLS_NAME   => 1,
            STREET_NAME => '_SHOW',
            BUILD_COUNT => '_SHOW'
          });
        },
        module      => 'Address',
        credentials => [
          'ADMIN', 'ADMINSID'
        ]
      },
      {
        method      => 'GET',
        path        => '/streets/:id/',
        handler     => sub {
          my ($path_params, $query_params, $module_obj) = @_;

          # return {
          #   errno  => 10,
          #   errstr => 'Access denied'
          # } if !$self->{admin}->{permissions}{0}{34};

          $module_obj->street_info({
            %$query_params,
            COLS_NAME => 1,
            ID        => $path_params->{id}
          });

          delete @{$module_obj}{qw/list/};
          return $module_obj;
        },
        module      => 'Address',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method      => 'POST',
        path        => '/streets/',
        handler     => sub {
          my ($path_params, $query_params, $module_obj) = @_;

          return {
            errno  => 10095,
            errstr => 'No field districtId'
          } if (!$query_params->{DISTRICT_ID});

          return {
            errno  => 10096,
            errstr => 'No field name'
          } if (!$query_params->{NAME});

          return {
            errno  => 10,
            errstr => 'Access denied'
          } if !$self->{admin}->{permissions}{0}{34};

          $module_obj->street_add({
            %$query_params
          });

          return $module_obj if ($module_obj->{errno});

          $module_obj->street_info({
            COLS_NAME => 1,
            ID        => $module_obj->{INSERT_ID}
          });

          delete @{$module_obj}{qw/list/};
          return $module_obj;
        },
        module      => 'Address',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method      => 'PUT',
        path        => '/streets/:id/',
        handler     => sub {
          my ($path_params, $query_params, $module_obj) = @_;

          return {
            errno  => 10,
            errstr => 'Access denied'
          } if !$self->{admin}->{permissions}{0}{34};

          $module_obj->street_change({
            %$query_params,
            ID => $path_params->{id}
          });

          return $module_obj if ($module_obj->{errno});

          $module_obj->street_info({
            COLS_NAME => 1,
            ID        => $path_params->{id}
          });

          delete @{$module_obj}{qw/list/};
          return $module_obj;
        },
        module      => 'Address',
        credentials => [
          'ADMIN'
        ]
      },
    ],
    districts => [
      {
        method      => 'GET',
        path        => '/districts/',
        handler     => sub {
          my ($path_params, $query_params, $module_obj) = @_;

          # return {
          #   errno  => 10,
          #   errstr => 'Access denied'
          # } if !$self->{admin}->{permissions}{0}{35};

          foreach my $param (keys %{$query_params}) {
            $query_params->{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0') ? $query_params->{$param} : '_SHOW';
          }

          $module_obj->district_list({
            %$query_params,
            COLS_NAME => 1,
          });
        },
        module      => 'Address',
        credentials => [
          'ADMIN', 'ADMINSID'
        ]
      },
      {
        method      => 'POST',
        path        => '/districts/',
        handler     => sub {
          my ($path_params, $query_params, $module_obj) = @_;

          return {
            errno  => 10,
            errstr => 'Access denied'
          } if !$self->{admin}->{permissions}{0}{35};

          return {
            errno  => 10094,
            errstr => 'No field name'
          } if (!$query_params->{NAME});

          $module_obj->district_add({
            %$query_params
          });
        },
        module      => 'Address',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method      => 'GET',
        path        => '/districts/:id/',
        handler     => sub {
          my ($path_params, $query_params, $module_obj) = @_;

          return {
            errno  => 10,
            errstr => 'Access denied'
          } if !$self->{admin}->{permissions}{0}{35};

          $module_obj->district_info({ ID => $path_params->{id}, });

          delete @{$module_obj}{qw/list AFFECTED TOTAL/};
          return $module_obj;
        },
        module      => 'Address',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method      => 'PUT',
        path        => '/districts/:id/',
        handler     => sub {
          my ($path_params, $query_params, $module_obj) = @_;

          return {
            errno  => 10,
            errstr => 'Access denied'
          } if !$self->{admin}->{permissions}{0}{35};

          $module_obj->district_change({
            %$query_params,
            ID => $path_params->{id}
          });

          return $module_obj if ($module_obj->{errno});

          $module_obj->district_info({ ID => $path_params->{id}, });

          delete @{$module_obj}{qw/list/};
          return $module_obj;
        },
        module      => 'Address',
        credentials => [
          'ADMIN'
        ]
      },
    ],
    online    => [
      {
        method      => 'GET',
        path        => '/online/:uid/',
        handler     => sub {
          my ($path_params, $query_params, $module_obj) = @_;

          return {
            errno  => 10,
            errstr => 'Access denied'
          } if ($self->{admin}->{MODULES} && !$self->{admin}->{MODULES}->{Internet}) || !$self->{admin}->{permissions}{0}{33};

          $module_obj->online({
            UID           => $path_params->{uid},
            NAS_PORT_ID   => '_SHOW',
            CLIENT_IP_NUM => '_SHOW',
            NAS_ID        => '_SHOW',
            USER_NAME     => '_SHOW',
            CLIENT_IP     => '_SHOW',
            DURATION      => '_SHOW',
            STATUS        => '_SHOW'
          });
        },
        module      => 'Internet::Sessions',
        credentials => [
          'ADMIN'
        ]
      },
    ],
    payments  => [
      {
        method      => 'GET',
        path        => '/payments/types/',
        handler     => sub {
          my ($path_params, $query_params, $module_obj) = @_;

          return {
            errno  => 10,
            errstr => 'Access denied'
          } if !$self->{admin}->{permissions}{1}{3};

          foreach my $param (keys %{$query_params}) {
            $query_params->{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0') ? $query_params->{$param} : '_SHOW';
          }

          $module_obj->payment_type_list({
            %$query_params,
            COLS_NAME => 1
          });
        },
        module      => 'Payments',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method      => 'GET',
        path        => '/payments/',
        handler     => sub {
          my ($path_params, $query_params, $module_obj) = @_;
          return $self->_payments_user($path_params, $query_params, $module_obj);
        },
        module      => 'Payments',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method      => 'GET',
        path        => '/payments/users/:uid/',
        handler     => sub {
          my ($path_params, $query_params, $module_obj) = @_;
          return $self->_payments_user($path_params, $query_params, $module_obj);
        },
        module      => 'Payments',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method      => 'POST',
        path        => '/payments/users/:uid/',
        handler     => sub {
          my ($path_params, $query_params) = @_;

          my %extra_results = ();

          return {
            errno  => 10,
            errstr => 'Access denied'
          } if (!$self->{admin}->{permissions}{1}{1} && !$self->{admin}->{permissions}{1}{3});

          return {
            errno  => 10067,
            errstr => 'Wrong param sum, it\'s empty or must be bigger than zero',
          } if (!$query_params->{SUM} || $query_params->{SUM} !~ /[0-9\.]+/ || $query_params->{SUM} <= 0);

          my $max_payment = $self->{conf}->{MAX_ADMIN_PAYMENT} || 99999999;
          return {
            errno  => 10068,
            errstr => "Payment sum is bigger than allowed - $query_params->{SUM} > $max_payment",
          } if ($query_params->{SUM} > $max_payment);

          my $Users = $path_params->{user_object};
          require Bills;
          Bills->import();
          my $Bills = Bills->new($self->{db}, $self->{admin}, $self->{conf});

          if ($Users->{COMPANY_ID}) {
            $Bills->list({
              COMPANY_ID => $Users->{COMPANY_ID},
              BILL_ID    => $query_params->{BILL_ID},
              COLS_NAME  => 1,
            });
          }
          else {
            $Bills->list({
              UID       => $path_params->{uid},
              BILL_ID   => $query_params->{BILL_ID},
              COLS_NAME => 1,
            });
          }

          return {
            errno  => 10069,
            errstr => "User not found with uid - $path_params->{uid} and billId - $query_params->{BILL_ID}",
          } if (!$Bills->{TOTAL});

          my $payment_method = $query_params->{METHOD} || '0';
          delete $query_params->{METHOD};

          require Payments;
          Payments->import();
          my $Payments = Payments->new($self->{db}, $self->{admin}, $self->{conf});

          my $allowed_payments = $Payments->admin_payment_type_list({
            COLS_NAME => 1,
            AID       => $self->{admin}->{AID},
          });

          my @allowed_payments_ids = map {$_->{payments_type_id}} @{$allowed_payments};

          if ($payment_method !~ /[0-9]+/) {
            my $payment_methods = $Payments->payment_type_list({
              COLS_NAME       => 1,
              FEES_TYPE       => '_SHOW',
              SORT            => 'id',
              DEFAULT_PAYMENT => 1,
              IDS             => scalar @allowed_payments_ids ? \@allowed_payments_ids : undef,
            });

            if ($path_params) {
              $payment_method = $payment_methods->[0]->{id};
            }
            else {
              $payment_method = 0;
            }
          }
          else {
            if (@allowed_payments_ids && !in_array($payment_method, \@allowed_payments_ids)) {
              return {
                errno  => 10070,
                errstr => 'Payment method is not allowed',
              };
            }
          }

          $Payments->{db}->{TRANSACTION} = 1;
          my $db_ = $Payments->{db}->{db};
          $db_->{AutoCommit} = 0;

          if (in_array('Docs', \@main::MODULES) && $query_params->{CREATE_RECEIPT}) {
            $query_params->{INVOICE_ID} = 'create';
            $query_params->{CREATE_RECEIPT} //= 1;
            $query_params->{APPLY_TO_INVOICE} //= 1;

            $main::LIST_PARAMS{UID} = $path_params->{uid};
            $main::users = $Users;
            ::load_module('AXbills::Templates', { LOAD_PACKAGE => 1 });
          }

          if ($query_params->{EXCHANGE_ID}) {
            if ($query_params->{DATE}) {
              my $list = $Payments->exchange_log_list({
                DATE      => "<=$query_params->{DATE}",
                ID        => $query_params->{EXCHANGE_ID},
                SORT      => 'date',
                DESC      => 'desc',
                PAGE_ROWS => 1,
                COLS_NAME => 1,
              });
              $query_params->{ER_ID}          = $query_params->{EXCHANGE_ID};
              $query_params->{ER}             = $list->[0]->{rate} || 1;
              $query_params->{CURRENCY}       = $list->[0]->{iso} || 0;
              $extra_results{currency}{name}  = $list->[0]->{money} || q{};
            }
            else {
              my $er = $Payments->exchange_info($query_params->{EXCHANGE_ID});
              $query_params->{ER_ID}          = $query_params->{EXCHANGE_ID};
              $query_params->{ER}             = $er->{ER_RATE};
              $query_params->{CURRENCY}       = $er->{ISO};
              $extra_results{currency}{name}  = $er->{ER_NAME};
            }
            $extra_results{currency}{iso}   = $query_params->{CURRENCY};

            $extra_results{currency} = "exchangeId $query_params->{EXCHANGE_ID} not found" if (!$extra_results{currency}{iso} && !$query_params->{ER});
          }

          $query_params->{CURRENCY} = $self->{conf}->{SYSTEM_CURRENCY} if (!$query_params->{CURRENCY} && $self->{conf}->{SYSTEM_CURRENCY});

          $query_params->{DESCRIBE} //= '';
          $query_params->{METHOD} = $payment_method;
          %main::FORM = %$query_params;

          ::cross_modules('pre_payment', {
            USER_INFO    => $Users,
            SKIP_MODULES => 'Sqlcmd',
            SUM          => $query_params->{SUM},
            AMOUNT       => $query_params->{SUM},
            EXT_ID       => $query_params->{EXT_ID} || q{},
            METHOD       => $payment_method,
            FORM         => { %main::FORM },
          });

          $Payments->add({ UID => $path_params->{uid} }, {
            %$query_params,
            UID => $path_params->{uid},
          });

          if ($Payments->{errno}) {
            $db_->rollback();
            $db_->{AutoCommit} = 1;
            delete($Payments->{db}->{TRANSACTION});
            return {
              errno  => 10071,
              errstr => "Payments error - $Payments->{errno}, errstr - $Payments->{errno}",
            };
          }
          else {
            if (in_array('Employees', \@main::MODULES) && $query_params->{CASHBOX_ID}) {
              require Employees;
              Employees->import();
              my $Employees = Employees->new($self->{db}, $self->{admin}, $self->{conf});

              my $coming_type = $Employees->employees_list_coming_type({ COLS_NAME => 1 });

              my $id_type;
              foreach my $key (@$coming_type) {
                if ($key->{default_coming} == 1) {
                  $id_type = $key->{id};
                }
              }

              $Employees->employees_add_coming({
                DATE           => $main::DATE,
                AMOUNT         => $query_params->{SUM},
                CASHBOX_ID     => $query_params->{CASHBOX_ID},
                COMING_TYPE_ID => $id_type,
                COMMENTS       => $query_params->{DESCRIBE},
                AID            => $self->{admin}->{AID},
                UID            => $path_params->{uid},
              });

              if ($Employees->{errno}) {
                $extra_results{employees}{errno} = $Employees->{errno};
                $extra_results{employees}{errstr} = $Employees->{errstr};
              }
              else {
                $extra_results{employees}{result} = 'OK';
                $extra_results{employees}{insert_id} = $Employees->{INSERT_ID};
              }
            }

            ::cross_modules('payments_maked', {
              USER_INFO    => $Users,
              METHOD       => $payment_method,
              SUM          => $query_params->{SUM},
              AMOUNT       => $query_params->{SUM},
              PAYMENT_ID   => $Payments->{PAYMENT_ID},
              EXT_ID       => $query_params->{EXT_ID} || q{},
              SKIP_MODULES => 'Sqlcmd',
              FORM         => { %main::FORM },
            });

            delete($Payments->{db}->{TRANSACTION});
            $db_->commit();
            $db_->{AutoCommit} = 1;

            return {
              insert_id  => $Payments->{INSERT_ID},
              payment_id => $Payments->{INSERT_ID},
              uid        => $path_params->{uid},
              %extra_results
            };
          }
        },
        credentials => [
          'ADMIN'
        ]
      },
      {
        method      => 'DELETE',
        path        => '/payments/users/:uid/:id/',
        handler     => sub {
          my ($path_params, $query_params, $module_obj) = @_;

          return {
            errno  => 10,
            errstr => 'Access denied'
          } if (!$self->{admin}->{permissions}{1}{2} && !$self->{admin}->{permissions}{1}{3});

          $module_obj->list({
            UID => $path_params->{uid},
            ID  => $path_params->{id},
          });

          if (!$module_obj->{TOTAL}) {
            return {
              errno  => 10122,
              errstr => "Payment with id $path_params->{id} and uid $path_params->{uid} does not exist"
            };
          }

          my $comments = $query_params->{COMMENTS} || 'Deleted from API request';
          my $payment_info = $module_obj->list({
            ID         => $path_params->{id},
            UID        => '_SHOW',
            DATETIME   => '_SHOW',
            SUM        => '_SHOW',
            DESCRIBE   => '_SHOW',
            EXT_ID     => '_SHOW',
            COLS_NAME  => 1,
            COLS_UPPER => 1,
          });
          $module_obj->del($path_params->{user_object}, $path_params->{id}, { COMMENTS => $comments });

          if ($module_obj->{AFFECTED}) {
            ::cross_modules('payment_del', {
              FORM         => $query_params,
              UID          => $path_params->{uid},
              ID           => $path_params->{id},
              PAYMENT_INFO => $payment_info->[0] || {}
            });

            return {
              result     => "Successfully deleted payment for user $path_params->{uid} and payment id $path_params->{id}",
              uid        => $path_params->{uid},
              payment_id => $path_params->{id},
            };
          }
          else {
            return {
              errno  => 10121,
              errstr => "Payment with id $path_params->{id} and uid $path_params->{uid} does not exist"
            };
          }
        },
        module      => 'Payments',
        credentials => [
          'ADMIN'
        ]
      },
    ],
    fees      => [
      {
        method      => 'GET',
        path        => '/fees/',
        handler     => sub {
          my ($path_params, $query_params, $module_obj) = @_;
          return $self->_fees_user($path_params, $query_params, $module_obj);
        },
        module      => 'Fees',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method      => 'GET',
        path        => '/fees/types/',
        handler     => sub {
          my ($path_params, $query_params, $module_obj) = @_;

          return {
            errno  => 10,
            errstr => 'Access denied'
          } if !$self->{admin}->{permissions}{2}{3};

          foreach my $param (keys %{$query_params}) {
            $query_params->{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0') ? $query_params->{$param} : '_SHOW';
          }

          $module_obj->fees_type_list({
            %$query_params,
            COLS_NAME => 1
          });
        },
        module      => 'Fees',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method      => 'GET',
        path        => '/fees/users/:uid/',
        handler     => sub {
          my ($path_params, $query_params, $module_obj) = @_;
          return $self->_fees_user($path_params, $query_params, $module_obj);
        },
        module      => 'Fees',
        credentials => [
          'ADMIN'
        ]
      },
      {
        #TODO: we can send uid of one user and bill_id of other user. db will be in inconsistent state. fix it.
        method      => 'POST',
        path        => '/fees/users/:uid/:sum/',
        handler     => sub {
          my ($path_params, $query_params, $module_obj) = @_;

          return {
            errno  => 10,
            errstr => 'Access denied'
          } if (!$self->{admin}->{permissions}{2}{1} && !$self->{admin}->{permissions}{2}{3});

          $module_obj->take({ UID => $path_params->{uid} }, $path_params->{sum}, {
            %$query_params,
            UID => $path_params->{uid}
          });
        },
        module      => 'Fees',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method      => 'DELETE',
        path        => '/fees/users/:uid/:id/',
        handler     => sub {
          my ($path_params, $query_params, $module_obj) = @_;

          return {
            errno  => 10,
            errstr => 'Access denied'
          } if (!$self->{admin}->{permissions}{2}{2} && !$self->{admin}->{permissions}{2}{3});

          $module_obj->list({
            UID => $path_params->{uid},
            ID  => $path_params->{id},
          });

          if (!$module_obj->{TOTAL}) {
            return {
              errno  => 10128,
              errstr => "Fee with id $path_params->{id} and uid $path_params->{uid} does not exist"
            };
          }

          my $comments = $query_params->{COMMENTS} || 'Deleted from API request';
          $module_obj->del($path_params->{user_object}, $path_params->{id}, { COMMENTS => $comments });

          if ($module_obj->{AFFECTED}) {
            return {
              result     => "Successfully deleted fee for user $path_params->{uid} and fee id $path_params->{id}",
              uid        => $path_params->{uid},
              payment_id => $path_params->{id},
            };
          }
          else {
            return {
              errno  => 10129,
              errstr => "Fee with id $path_params->{id} and uid $path_params->{uid} does not exist"
            };
          }
        },
        module      => 'Fees',
        credentials => [
          'ADMIN'
        ]
      },
    ],
    finance   => [
      {
        method      => 'GET',
        path        => '/finance/exchange/rate/',
        handler     => sub {
          my ($path_params, $query_params, $module_obj) = @_;

          return {
            errno  => 10,
            errstr => 'Access denied'
          } if (!$self->{admin}->{permissions}{4});

          my Payments $Payments = $module_obj;

          $Payments->exchange_list({ COLS_NAME => 1 })
        },
        module      => 'Payments',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method      => 'GET',
        path        => '/finance/exchange/rate/log/',
        handler     => sub {
          my ($path_params, $query_params, $module_obj) = @_;

          return {
            errno  => 10,
            errstr => 'Access denied'
          } if (!$self->{admin}->{permissions}{4});

          my Payments $Payments = $module_obj;

          $Payments->exchange_log_list({ COLS_NAME => 1 })
        },
        module      => 'Payments',
        credentials => [
          'ADMIN'
        ]
      },
    ],
    user      => [
      {
        method      => 'DELETE',
        path        => '/user/:uid/logout/',
        handler     => sub {
          my ($path_params, $query_params, $module_obj) = @_;

          $module_obj->web_session_del({ SID => $ENV{HTTP_USERSID} });
          return {
            result => 'Success logout',
          };
        },
        module      => 'Users',
        credentials => [
          'USER', 'USERBOT'
        ]
      },
      {
        method      => 'GET',
        path        => '/user/:uid/',
        handler     => sub {
          my ($path_params, $query_params, $module_obj) = @_;

          $module_obj->info($path_params->{uid});

          delete @{$module_obj}{qw{COMPANY_NAME AFFECTED DELETED DISABLE COMPANY_VAT COMPANY_ID COMPANY_CREDIT G_NAME GID TOTAL}};
          delete @{$module_obj}{qw{REDUCTION REDUCTION_DATE}} if ($self->{conf}->{user_hide_reduction});

          if ($self->{conf}->{REGISTRATION_VERIFY_PHONE} || $self->{conf}->{REGISTRATION_VERIFY_EMAIL}) {
            $module_obj->registration_pin_info({ UID => $path_params->{uid} });
            if ($module_obj->{errno}) {
              delete @{$module_obj}{qw{errno errstr}};
              $module_obj->{is_verified} = 'true';
            }
            else {
              $module_obj->{is_verified} = $module_obj->{VERIFY_DATE} eq '0000-00-00 00:00:00' ? 'false' : 'true';
            }
          }

          return $module_obj;
        },
        module      => 'Users',
        credentials => [
          'USER', 'USERBOT'
        ]
      },
      {
        method      => 'GET',
        path        => '/user/:uid/pi/',
        handler     => sub {
          my ($path_params, $query_params) = @_;

          require Info_fields;
          Info_fields->import();
          my $Info_fields = Info_fields->new($self->{db}, $self->{admin}, $self->{conf});

          my $info_fields = $Info_fields->fields_list({
            SQL_FIELD   => '_SHOW',
            ABON_PORTAL => 0,
            COLS_NAME   => 1,
          });

          my @delete_params = (
            'AFFECTED',
            'COMMENTS',
            'CONTACTS_NEW_APPENDED',
            'CONTRACT_SUFFIX',
          );

          foreach my $info_field (@{$info_fields}) {
            push @delete_params, uc($info_field->{sql_field});
          }

          require Users;
          Users->import();
          my $users = Users->new($self->{db}, $self->{admin}, $self->{conf});
          $users->pi({ UID => $path_params->{uid} });

          $users->{ADDRESS_FULL} =~ s/,\s?$// if ($users->{ADDRESS_FULL});
          $users->{CUSTOM_ADDRESS_FULL} = $users->{ADDRESS_FULL} if ($self->{conf}->{ADDRESS_FORMAT});

          delete @{$users}{@delete_params};

          return $users;
        },
        module      => 'Users',
        credentials => [
          'USER', 'USERBOT'
        ]
      },
      {
        method      => 'PUT',
        path        => '/user/pi/',
        handler     => sub {
          my ($path_params, $query_params, $module_obj) = @_;

          return {
            errno  => 10066,
            errstr => 'Unknown operation happened',
          } if (!$self->{conf}->{user_chg_pi});

          my %result = ();

          my %allowed_params = (
            FIO          => 'FIO',
            FIO1         => 'FIO1',
            FIO2         => 'FIO2',
            FIO3         => 'FIO3',
            CELL_PHONE   => 'CELL_PHONE',
            FLOOR        => 'FLOOR',
            DISTRICT_ID  => 'DISTRICT_ID',
            BUILD_ID     => 'BUILD_ID',
            LOCATION_ID  => 'LOCATION_ID',
            STREET_ID    => 'STREET_ID',
            ADDRESS_FLAT => 'ADDRESS_FLAT',
            EMAIL        => 'EMAIL',
            PHONE        => 'PHONE',
          );

          if ($self->{conf}->{CHECK_CHANGE_PI}) {
            %allowed_params = ();
            my @allowed_params = split(',\s?', $self->{conf}->{CHECK_CHANGE_PI});
            foreach my $param (@allowed_params) {
              $allowed_params{$param} = uc $param;
              $allowed_params{$param} =~ s/^_//;
            }
          }
          else {
            if ($self->{conf}->{user_chg_info_fields}) {
              require Info_fields;
              Info_fields->import();

              my $Info_fields = Info_fields->new($self->{db}, $self->{admin}, $self->{conf});
              my $info_fields = $Info_fields->fields_list({
                SQL_FIELD   => '_SHOW',
                ABON_PORTAL => 1,
                USER_CHG    => 1,
                COLS_NAME   => 1,
              });

              foreach my $info_field (@{$info_fields}) {
                $allowed_params{uc($info_field->{sql_field})} = uc($info_field->{sql_field});
                $allowed_params{uc($info_field->{sql_field})} =~ s/^_//;
              }
            }
          }

          if ($self->{conf}->{user_chg_pi_verification}) {
            require AXbills::Sender::Core;
            AXbills::Sender::Core->import();
            my $Sender = AXbills::Sender::Core->new($self->{db}, $self->{admin}, $self->{conf});

            if ($query_params->{EMAIL}) {
              my $code = static_string_generate($query_params->{EMAIL}, $path_params->{uid});

              if ($query_params->{EMAIL_CODE} && "$query_params->{EMAIL_CODE}" ne "$code") {
                $result{email_confirm_status} = 'Wrong email code';
                delete $allowed_params{EMAIL};
              }
              elsif (!$query_params->{EMAIL_CODE}) {
                delete $allowed_params{EMAIL};

                $Sender->send_message({
                  TO_ADDRESS  => $query_params->{EMAIL},
                  MESSAGE     => "$self->{lang}->{CODE} $code",
                  SUBJECT     => $self->{lang}->{CODE},
                  SENDER_TYPE => 'Mail',
                  QUITE       => 1,
                  UID         => $path_params->{uid},
                });
              }
            }

            if (in_array('Sms', \@main::MODULES) && $query_params->{PHONE}) {
              my $code = static_string_generate($query_params->{PHONE}, $path_params->{uid});

              if ($query_params->{PHONE_CODE} && "$query_params->{PHONE_CODE}" ne "$code") {
                $result{phone_confirm_status} = 'Wrong phone code';
                delete $allowed_params{PHONE};
              }
              elsif (!$query_params->{PHONE_CODE}) {
                delete $allowed_params{PHONE};
                require Sms;
                Sms->import();
                my $Sms = Sms->new($self->{db}, $self->{admin}, $self->{conf});

                my $sms_limit = $self->{conf}->{USER_LIMIT_SMS} || 5;

                my $current_mount = POSIX::strftime("%Y-%m-01", localtime(time));
                $Sms->list({
                  COLS_NAME => 1,
                  DATETIME  => ">=$current_mount",
                  UID       => $path_params->{uid},
                  NO_SKIP   => 1,
                  PAGE_ROWS => 1000
                });

                my $sent_sms = $Sms->{TOTAL} || 0;

                if ($sms_limit <= $sent_sms) {
                  $result{phone_confirm_status} = "User sms limit has been reached - $self->{conf}->{USER_LIMIT_SMS} sms";
                }
                else {
                  $Sender->send_message({
                    TO_ADDRESS  => $query_params->{PHONE},
                    MESSAGE     => "$self->{lang}->{CODE} $code",
                    SENDER_TYPE => 'Sms',
                    UID         => $path_params->{uid},
                  });
                }
              }
            }
          }

          my %PARAMS = ();
          foreach my $param (keys %allowed_params) {
            next if (!defined $query_params->{$allowed_params{$param}});
            $PARAMS{$param} = $query_params->{$allowed_params{$param}};
          }

          my $users = $module_obj;

          $users->pi({ UID => $path_params->{uid} });

          $users->pi_change({
            UID => $path_params->{uid},
            %PARAMS,
          });

          $result{result} = 'Successfully changed ' . join(', ', map($_ = camelize($_), keys %PARAMS));

          return \%result;
        },
        module      => 'Users',
        credentials => [
          'USER', 'USERBOT'
        ]
      },
      {
        method      => 'POST',
        path        => '/user/:uid/credit/',
        handler     => sub {
          my ($path_params, $query_params, $module_obj) = @_;

          $module_obj->user_set_credit({
            UID           => $path_params->{uid},
            change_credit => 1,
          });
        },
        module      => 'Control::Service_control',
        credentials => [
          'USER', 'USERBOT'
        ]
      },
      {
        method      => 'GET',
        path        => '/user/:uid/credit/',
        handler     => sub {
          my ($path_params, $query_params, $module_obj) = @_;

          $module_obj->user_set_credit({
            UID => $path_params->{uid}
          });
        },
        module      => 'Control::Service_control',
        credentials => [
          'USER', 'USERBOT'
        ]
      },
      {
        method      => 'POST',
        path        => '/user/:uid/internet/:id/activate/',
        handler     => sub {
          my ($path_params, $query_params, $module_obj) = @_;
          require Users;
          Users->import();
          my $Users = Users->new($self->{db}, $self->{admin}, $self->{conf});
          my $user_info = $Users->info($path_params->{uid});

          $module_obj->user_info($path_params->{uid}, {
            ID        => $path_params->{id},
            DOMAIN_ID => $user_info->{DOMAIN_ID}
          });

          return {
            result => 'Already active'
          } if (defined $module_obj->{STATUS} && $module_obj->{STATUS} == 0);
          return {
            errno  => 200,
            errstr => 'Can\'t activate, not allowed'
          } unless (
            $module_obj->{STATUS} &&
              ($module_obj->{STATUS} == 2 || $module_obj->{STATUS} == 5 ||
                ($module_obj->{STATUS} == 3 && $self->{conf}->{INTERNET_USER_SERVICE_HOLDUP})));

          if ($module_obj->{STATUS} == 3) {
            require Control::Service_control;
            Control::Service_control->import();
            my $Service_control = Control::Service_control->new($self->{db}, $self->{admin}, $self->{conf});
            my $del_result = $Service_control->user_holdup({ del => 1, UID => $path_params->{uid}, ID => $path_params->{id} });
            return $del_result;
          }

          return {
            errno  => 201,
            errstr => 'Can\'t activate, not enough money'
          } if ($module_obj->{MONTH_ABON} != 0 && $module_obj->{MONTH_ABON} >= $user_info->{DEPOSIT});

          $module_obj->user_change({
            UID      => $path_params->{uid},
            ID       => $path_params->{id},
            STATUS   => 0,
            ACTIVATE => ($self->{conf}->{INTERNET_USER_ACTIVATE_DATE}) ? strftime("%Y-%m-%d", localtime(time)) : undef
          });

          if (!$module_obj->{errno}) {
            if (!$module_obj->{STATUS}) {
              require AXbills::Misc;
              ::service_get_month_fee($module_obj);
            }

            return {
              result => 'OK. Success activation'
            }
          }
          else {
            return {
              errno  => $module_obj->{errno},
              errstr => $module_obj->{errstr} || "",
            }
          }
        },
        module      => 'Internet',
        credentials => [
          'USER', 'USERBOT'
        ]
      },
      {
        method      => 'GET',
        path        => '/user/:uid/internet/',
        handler     => sub {
          my ($path_params, $query_params) = @_;

          ::load_module('Control::Services', { LOAD_PACKAGE => 1 });
          return ::get_user_services({
            uid     => $path_params->{uid},
            service => 'Internet',
          });
        },
        credentials => [
          'USER', 'USERBOT'
        ]
      },
      {
        method      => 'GET',
        path        => '/user/:uid/internet/speed/',
        handler     => sub {
          my ($path_params, $query_params, $module_obj) = @_;

          $module_obj->get_speed({
            UID       => $path_params->{uid},
            COLS_NAME => 1,
            PAGE_ROWS => 1
          });
        },
        module      => 'Internet',
        credentials => [
          'USER', 'USERBOT'
        ]
      },
      {
        method      => 'GET',
        path        => '/user/:uid/internet/speed/:tpid/',
        handler     => sub {
          my ($path_params, $query_params, $module_obj) = @_;

          $module_obj->get_speed({
            TP_NUM    => $path_params->{tpid},
            COLS_NAME => 1,
            PAGE_ROWS => 1
          });
        },
        module      => 'Internet',
        credentials => [
          'USER', 'USERBOT'
        ]
      },
      #@deprecated
      {
        method      => 'GET',
        path        => '/user/:uid/internet/:id/holdup/',
        handler     => sub {
          my ($path_params, $query_params, $module_obj) = @_;

          my $result = $module_obj->user_holdup({
            UID          => $path_params->{uid},
            ID           => $path_params->{id},
            ACCEPT_RULES => 1
          });

          return {
            errno  => $result->{errno} || $result->{error},
            errstr => $result->{errstr}
          } if (ref $result eq 'HASH' && ($result->{error} || $result->{errno}));

          return $result;
        },
        module      => 'Control::Service_control',
        credentials => [
          'USER', 'USERBOT'
        ]
      },
      #@deprecated
      {
        method      => 'POST',
        path        => '/user/:uid/internet/:id/holdup/',
        handler     => sub {
          my ($path_params, $query_params, $module_obj) = @_;

          my $result = $module_obj->user_holdup({
            %$query_params,
            UID          => $path_params->{uid},
            ID           => $path_params->{id},
            add          => 1,
            ACCEPT_RULES => 1
          });

          return {
            errno  => $result->{errno} || $result->{error},
            errstr => $result->{errstr}
          } if (ref $result eq 'HASH' && ($result->{error} || $result->{errno}));

          return $result;
        },
        module      => 'Control::Service_control',
        credentials => [
          'USER', 'USERBOT'
        ]
      },
      #@deprecated
      {
        method      => 'DELETE',
        path        => '/user/:uid/internet/:id/holdup/',
        handler     => sub {
          my ($path_params, $query_params, $module_obj) = @_;

          my $result = $module_obj->user_holdup({
            UID => $path_params->{uid},
            ID  => $path_params->{id},
            del => 1,
          });

          return {
            errno  => $result->{errno} || $result->{error},
            errstr => $result->{errstr}
          } if (ref $result eq 'HASH' && ($result->{error} || $result->{errno}));

          return $result;
        },
        module      => 'Control::Service_control',
        credentials => [
          'USER', 'USERBOT'
        ]
      },
      {
        method      => 'GET',
        path        => '/user/:uid/:id/holdup/',
        handler     => sub {
          my ($path_params, $query_params, $module_obj) = @_;

          my %params = (
            UID          => $path_params->{uid},
            ACCEPT_RULES => 1,
          );

          $params{ID} = $path_params->{id} if ($self->{conf}->{INTERNET_USER_SERVICE_HOLDUP});

          my $result = $module_obj->user_holdup(\%params);

          return {
            errno  => $result->{errno} || $result->{error},
            errstr => $result->{errstr}
          } if (ref $result eq 'HASH' && ($result->{error} || $result->{errno}));

          return $result;
        },
        module      => 'Control::Service_control',
        credentials => [
          'USER', 'USERBOT'
        ]
      },
      {
        method      => 'POST',
        path        => '/user/:uid/:id/holdup/',
        handler     => sub {
          my ($path_params, $query_params, $module_obj) = @_;

          my %params = (
            UID          => $path_params->{uid},
            add          => 1,
            ACCEPT_RULES => 1,
            FROM_DATE    => $query_params->{FROM_DATE},
            TO_DATE      => $query_params->{TO_DATE},
          );

          $params{ID} = $path_params->{id} if ($self->{conf}->{INTERNET_USER_SERVICE_HOLDUP});

          my $result = $module_obj->user_holdup(\%params);

          return {
            errno  => $result->{errno} || $result->{error},
            errstr => $result->{errstr}
          } if (ref $result eq 'HASH' && ($result->{error} || $result->{errno}));

          return $result;
        },
        module      => 'Control::Service_control',
        credentials => [
          'USER', 'USERBOT'
        ]
      },
      {
        method      => 'DELETE',
        path        => '/user/:uid/:id/holdup/',
        handler     => sub {
          my ($path_params, $query_params, $module_obj) = @_;

          my %params = (
            UID => $path_params->{uid},
            del => 1,
          );

          $params{ID} = $path_params->{id} if ($self->{conf}->{INTERNET_USER_SERVICE_HOLDUP});

          my $result = $module_obj->user_holdup(\%params);

          return {
            errno  => $result->{errno} || $result->{error},
            errstr => $result->{errstr}
          } if (ref $result eq 'HASH' && ($result->{error} || $result->{errno}));

          return $result;

        },
        module      => 'Control::Service_control',
        credentials => [
          'USER', 'USERBOT'
        ]
      },
      {
        method      => 'GET',
        path        => '/user/:uid/internet/tariffs/',
        handler     => sub {
          my ($path_params, $query_params, $module_obj) = @_;

          my $result = $module_obj->available_tariffs({
            SKIP_NOT_AVAILABLE_TARIFFS => 1,
            UID                        => $path_params->{uid},
            MODULE                     => 'Internet'
          });

          return {
            errno  => $result->{errno} || $result->{error},
            errstr => $result->{errstr}
          } if (ref $result eq 'HASH' && ($result->{error} || $result->{errno}));

          return $result;
        },
        module      => 'Control::Service_control',
        credentials => [
          'USER', 'USERBOT'
        ]
      },
      {
        method      => 'GET',
        path        => '/user/:uid/internet/tariffs/all/',
        handler     => sub {
          my ($path_params, $query_params, $module_obj) = @_;

          my $result = $module_obj->available_tariffs({
            UID    => $path_params->{uid},
            MODULE => 'Internet'
          });

          return {
            errno  => $result->{errno} || $result->{error},
            errstr => $result->{errstr}
          } if (ref $result eq 'HASH' && ($result->{error} || $result->{errno}));

          return $result;
        },
        module      => 'Control::Service_control',
        credentials => [
          'USER', 'USERBOT'
        ]
      },
      {
        method      => 'GET',
        path        => '/user/:uid/internet/:id/warnings/',
        handler     => sub {
          my ($path_params, $query_params, $module_obj) = @_;

          $module_obj->service_warning({
            UID    => $path_params->{uid},
            ID     => $path_params->{id},
            MODULE => 'Internet'
          });
        },
        module      => 'Control::Service_control',
        credentials => [
          'USER', 'USERBOT'
        ]
      },
      {
        method      => 'PUT',
        path        => '/user/:uid/internet/:id/',
        handler     => sub {
          my ($path_params, $query_params, $module_obj) = @_;

          my $result = $module_obj->user_chg_tp({
            %$query_params,
            UID    => $path_params->{uid},
            ID     => $path_params->{id}, #ID from internet main
            MODULE => 'Internet'
          });

          return {
            errno  => $result->{errno} || $result->{error},
            errstr => $result->{errstr}
          } if (ref $result eq 'HASH' && ($result->{error} || $result->{errno}));

          delete $result->{RESULT};
          $result->{result} = 'Successfully changed';

          return $result;
        },
        module      => 'Control::Service_control',
        credentials => [
          'USER', 'USERBOT'
        ]
      },
      {
        method      => 'DELETE',
        path        => '/user/:uid/internet/:id/',
        handler     => sub {
          my ($path_params, $query_params, $module_obj) = @_;

          my $result = $module_obj->del_user_chg_shedule({
            UID        => $path_params->{uid},
            SHEDULE_ID => $path_params->{id}
          });

          return {
            errno  => $result->{errno} || $result->{error},
            errstr => $result->{errstr}
          } if (ref $result eq 'HASH' && ($result->{error} || $result->{errno}));

          return $result;
        },
        module      => 'Control::Service_control',
        credentials => [
          'USER', 'USERBOT'
        ]
      },
      {
        method      => 'POST',
        path        => '/user/internet/mac/discovery/',
        params      => POST_INTERNET_MAC_DISCOVERY,
        handler     => sub {
          my ($path_params, $query_params) = @_;

          return {
            errno  => 10124,
            errstr => 'Service not available',
          } if (!$self->{conf}->{INTERNET_MAC_DICOVERY});

          require Internet;
          my $Internet = Internet->new($self->{db}, $self->{admin}, $self->{conf});
          $Internet->user_list({ UID => $path_params->{uid}, ID => $query_params->{ID}, COLS_NAME => 1 });

          return {
            errno  => 10125,
            errstr => "Not found service with id $query_params->{ID}",
          } if (!$Internet->{TOTAL});

          delete $Internet->{TOTAL};
          $Internet->user_list({ CID => $query_params->{CID} });

          return {
            errno  => 10126,
            errstr => 'This mac address already set for another user',
            cid    => $query_params->{CID},
          } if ($Internet->{TOTAL});

          $Internet->user_change({
            ID  => $query_params->{ID},
            UID => $path_params->{uid},
            CID => $query_params->{CID}
          });

          ::load_module('Internet::User_portal', { LOAD_PACKAGE => 1 });

          ::internet_hangup({
            CID   => $query_params->{CID},
            GUEST => 1,
          });

          return {
            result => 'Hangup is done',
          };
        },
        credentials => [
          'USER', 'USERBOT'
        ]
      },
      {
        method      => 'GET',
        path        => '/user/:uid/payments/',
        handler     => sub {
          my ($path_params, $query_params, $module_obj) = @_;

          my $payments = $module_obj->list({
            UID       => $path_params->{uid},
            DSC       => '_SHOW',
            SUM       => '_SHOW',
            DATETIME  => '_SHOW',
            EXT_ID    => '_SHOW',
            PAGE_ROWS => ($query_params->{PAGE_ROWS} || 10000),
            COLS_NAME => 1
          });

          foreach my $payment (@$payments) {
            delete @{$payment}{qw/inner_describe/};
          }

          return $payments;
        },
        module      => 'Payments',
        credentials => [
          'USER', 'USERBOT'
        ]
      },
      {
        method      => 'GET',
        path        => '/user/:uid/fees/',
        handler     => sub {
          my ($path_params, $query_params, $module_obj) = @_;

          my $fees = $module_obj->list({
            UID       => $path_params->{uid},
            DSC       => '_SHOW',
            SUM       => '_SHOW',
            DATETIME  => '_SHOW',
            PAGE_ROWS => ($query_params->{PAGE_ROWS} || 10000),
            COLS_NAME => 1
          });

          foreach my $fee (@$fees) {
            delete @{$fee}{qw/inner_describe/};
          }

          return $fees;
        },
        module      => 'Fees',
        credentials => [
          'USER', 'USERBOT'
        ]
      },
      {
        method      => 'GET',
        path        => '/user/:uid/internet/session/active/',
        handler     => sub {
          my ($path_params, $query_params, $module_obj) = @_;

          my $sessions = $module_obj->online({
            CLIENT_IP          => '_SHOW',
            CID                => '_SHOW',
            DURATION_SEC2      => '_SHOW',
            ACCT_INPUT_OCTETS  => '_SHOW',
            ACCT_OUTPUT_OCTETS => '_SHOW',
            UID                => $path_params->{uid}
          });

          my @result = ();

          foreach my $session (@{$sessions}) {
            push @result, {
              duration => $session->{duration_sec2},
              cid      => $session->{cid},
              input    => $session->{acct_input_octets},
              output   => $session->{acct_output_octets},
              ip       => $session->{client_ip}
            }
          }

          return \@result;
        },
        module      => 'Internet::Sessions',
        credentials => [
          'USER', 'USERBOT'
        ]
      },
      {
        method      => 'GET',
        path        => '/user/:uid/internet/sessions/',
        handler     => sub {
          my ($path_params, $query_params, $module_obj) = @_;

          my $sessions = $module_obj->list({
            UID          => $path_params->{uid},
            TP_NAME      => '_SHOW',
            TP_ID        => '_SHOW',
            IP           => '_SHOW',
            SENT         => '_SHOW',
            RECV         => '_SHOW',
            DURATION_SEC => '_SHOW',
            PAGE_ROWS    => $query_params->{PAGE_ROWS} ? $query_params->{PAGE_ROWS} : 25,
            COLS_NAME    => 1
          });

          my @result = ();

          foreach my $session (@{$sessions}) {
            push @result, {
              duration => $session->{duration_sec},
              input    => $session->{recv},
              output   => $session->{sent},
              ip       => $session->{ip},
              tp_name  => $session->{tp_name},
              tp_id    => $session->{tp_id},
            }
          }

          return \@result;
        },
        module      => 'Internet::Sessions',
        credentials => [
          'USER', 'USERBOT'
        ]
      },
      {
        method  => 'POST',
        path    => '/user/password/recovery/',
        handler => sub {
          my ($path_params, $query_params) = @_;

          require Control::Registration_mng;
          Control::Registration_mng->import();
          my $Registration_mng = Control::Registration_mng->new($self->{db}, $self->{admin}, $self->{conf}, { HTML => $self->{html}, LANG => $self->{lang} });

          return $Registration_mng->password_recovery($query_params);
        },
      },
      {
        method  => 'POST',
        path    => '/user/resend/verification/',
        handler => sub {
          my ($path_params, $query_params) = @_;

          require Control::Registration_mng;
          Control::Registration_mng->import();
          my $Registration_mng = Control::Registration_mng->new($self->{db}, $self->{admin}, $self->{conf}, { HTML => $self->{html}, LANG => $self->{lang} });

          return $Registration_mng->resend_pin($query_params);
        },
      },
      {
        method  => 'POST',
        path    => '/user/verify/',
        handler => sub {
          my ($path_params, $query_params) = @_;

          require Control::Registration_mng;
          Control::Registration_mng->import();
          my $Registration_mng = Control::Registration_mng->new($self->{db}, $self->{admin}, $self->{conf}, { HTML => $self->{html}, LANG => $self->{lang} });

          return $Registration_mng->verify_pin($query_params);
        },
      },
      {
        method      => 'POST',
        path        => '/user/reset/password/',
        handler     => sub {
          my ($path_params, $query_params, $module_obj) = @_;

          return {
            errno  => 10032,
            errstr => 'Service not available',
          } if (!$self->{conf}->{user_chg_passwd});

          require Users;
          Users->import();
          my $Users = Users->new($self->{db}, $self->{admin}, $self->{conf});

          if ($self->{conf}->{group_chg_passwd}) {
            $Users->info($path_params->{uid});

            return {
              errno  => 10033,
              errstr => 'Service not available',
            } if ("$Users->{GID}" ne "$self->{conf}->{group_chg_passwd}");
          }

          return {
            errno  => 10036,
            errstr => 'No field password',
          } if (!$query_params->{PASSWORD});

          return {
            errno  => 10034,
            errstr => "Length of password not valid minimum $self->{conf}->{PASSWD_LENGTH}",
          } if ($self->{conf}->{PASSWD_LENGTH} && $self->{conf}->{PASSWD_LENGTH} > length($query_params->{PASSWORD}));

          return {
            errno  => 10035,
            errstr => "Password not valid, allowed symbols $self->{conf}->{PASSWD_SYMBOLS}",
          } if ($self->{conf}->{PASSWD_SYMBOLS} && $query_params->{PASSWORD} !~ /[$self->{conf}->{PASSWD_SYMBOLS}]/);

          $Users->change($path_params->{uid}, {
            PASSWORD => $query_params->{PASSWORD},
            UID      => $path_params->{uid},
          });

          return {
            errno  => 10030,
            errstr => 'Failed to change user password',
          } if ($Users->{errno});

          return {
            result => 'Successfully changed password'
          };
        },
        credentials => [
          'USER', 'USERBOT'
        ]
      },
      #@deprecated
      {
        method      => 'POST',
        path        => '/user/:uid/password/reset/',
        handler     => sub {
          my ($path_params, $query_params, $module_obj) = @_;

          return {
            errno  => 10032,
            errstr => 'Service not available',
          } if (!$self->{conf}->{user_chg_passwd});

          require Users;
          Users->import();
          my $Users = Users->new($self->{db}, $self->{admin}, $self->{conf});

          if ($self->{conf}->{group_chg_passwd}) {
            $Users->info($path_params->{uid});

            return {
              errno  => 10033,
              errstr => 'Service not available',
            } if ("$Users->{GID}" ne "$self->{conf}->{group_chg_passwd}");
          }

          return {
            errno  => 10036,
            errstr => 'No field password',
          } if (!$query_params->{PASSWORD});

          return {
            errno  => 10034,
            errstr => "Length of password not valid minimum $self->{conf}->{PASSWD_LENGTH}",
          } if ($self->{conf}->{PASSWD_LENGTH} && $self->{conf}->{PASSWD_LENGTH} > length($query_params->{PASSWORD}));

          return {
            errno  => 10035,
            errstr => "Password not valid, allowed symbols $self->{conf}->{PASSWD_SYMBOLS}",
          } if ($self->{conf}->{PASSWD_SYMBOLS} && $query_params->{PASSWORD} !~ /[$self->{conf}->{PASSWD_SYMBOLS}]/);

          $Users->change($path_params->{uid}, {
            PASSWORD => $query_params->{PASSWORD},
            UID      => $path_params->{uid},
          });

          return {
            errno  => 10030,
            errstr => 'Failed to change user password',
          } if ($Users->{errno});

          return {
            result => 'Successfully changed password'
          };
        },
        credentials => [
          'USER', 'USERBOT'
        ]
      },
      {
        method  => 'POST',
        path    => '/user/registration/',
        handler => sub {
          my ($path_params, $query_params) = @_;

          require Control::Registration_mng;
          Control::Registration_mng->import();
          my $Registration_mng = Control::Registration_mng->new($self->{db}, $self->{admin}, $self->{conf}, { HTML => $self->{html}, LANG => $self->{lang} });

          return $Registration_mng->user_registration($query_params);
        },
      },
      {
        method  => 'POST',
        path    => '/user/password/reset/',
        handler => sub {
          my ($path_params, $query_params) = @_;

          require Control::Registration_mng;
          Control::Registration_mng->import();
          my $Registration_mng = Control::Registration_mng->new($self->{db}, $self->{admin}, $self->{conf}, { HTML => $self->{html}, LANG => $self->{lang} });

          return $Registration_mng->password_reset($query_params);
        },
      },
      #@deprecated
      {
        method  => 'POST',
        path    => '/user/internet/registration/',
        handler => sub {
          my ($path_params, $query_params) = @_;

          return {
            errno  => 10091,
            errstr => 'Service not available',
          } if ($self->{conf}->{NEW_REGISTRATION_FORM});

          return {
            errno  => 10011,
            errstr => 'Service not available',
          } if (!in_array('Internet', \@main::MODULES) || !in_array('Internet', \@main::REGISTRATION));

          return {
            errno  => 10040,
            errstr => 'Service not available',
          } if ($self->{conf}->{REGISTRATION_PORTAL_SKIP});

          return {
            errno  => 10012,
            errstr => 'Invalid login',
          } if (!$query_params->{LOGIN});

          return {
            errno  => 10013,
            errstr => 'Invalid email',
          } if (!$query_params->{EMAIL} || $query_params->{EMAIL} !~ /(([^<>()[\]\\.,;:\s\@\"]+(\.[^<>()[\]\\.,;:\s\@\"]+)*)|(\".+\"))\@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))/);

          return {
            errno  => 10014,
            errstr => 'Invalid phone',
          } if (!$query_params->{PHONE} || ($self->{conf}->{PHONE_FORMAT} && $query_params->{PHONE} !~ m/$self->{conf}->{PHONE_FORMAT}/));

          my $password = q{};

          if ($self->{conf}->{REGISTRATION_PASSWORD}) {
            return {
              errno  => 10037,
              errstr => 'No field password',
            } if (!$query_params->{PASSWORD});

            return {
              errno  => 10038,
              errstr => "Length of password not valid minimum $self->{conf}->{PASSWD_LENGTH}",
            } if ($self->{conf}->{PASSWD_LENGTH} && $self->{conf}->{PASSWD_LENGTH} > length($query_params->{PASSWORD}));

            return {
              errno  => 10039,
              errstr => "Password not valid, allowed symbols $self->{conf}->{PASSWD_SYMBOLS}",
            } if ($self->{conf}->{PASSWD_SYMBOLS} && $query_params->{PASSWORD} !~ /[$self->{conf}->{PASSWD_SYMBOLS}]/);

            $password = $query_params->{PASSWORD};
          }

          #TODO: add a street GET PATH and validate it if enabled $conf{INTERNET_REGISTRATION_ADDRESS}
          #TODO: add referral

          if (!$password) {
            $password = mk_unique_value($self->{conf}->{PASSWD_LENGTH} || 8, { SYMBOLS => $self->{conf}->{PASSWD_SYMBOLS} || undef });
          }

          my $cid = q{};

          if ($self->{conf}->{INTERNET_REGISTRATION_IP}) {
            return {
              errno  => 10015,
              errstr => 'Invalid ip',
            } if (!$query_params->{USER_IP} || $query_params->{USER_IP} eq '0.0.0.0');

            require Internet::Sessions;
            Internet::Sessions->import();

            my $Sessions = Internet::Sessions->new($self->{db}, $self->{admin}, $self->{conf});
            $Sessions->online({
              CLIENT_IP => $query_params->{USER_IP},
              CID       => '_SHOW',
              GUEST     => 1,
              COLS_NAME => 1
            });

            if ($Sessions->{TOTAL}) {
              $cid = $Sessions->{list}->[0]->{cid};
            }

            return {
              errno  => 10016,
              errstr => 'IP address and MAC was not found',
            } if (!$cid);
          }

          require Users;
          Users->import();
          my $Users = Users->new($self->{db}, $self->{admin}, $self->{conf});

          $Users->add({
            LOGIN       => $query_params->{LOGIN},
            CREATE_BILL => 1,
            PASSWORD    => $password,
            GID         => $self->{conf}->{REGISTRATION_GID},
            PREFIX      => $self->{conf}->{REGISTRATION_PREFIX},
          });

          if ($Users->{errno}) {
            return {
              errno  => 10023,
              errstr => 'Invalid login of user',
            } if ($Users->{errno} eq 10);

            return {
              errno  => 10024,
              errstr => 'User already exist',
            } if ($Users->{errno} eq 7);

            return {
              errno  => 10018,
              errstr => 'Error occurred during creation of user',
            };
          }

          my $uid = $Users->{UID};
          $Users->info($uid);

          $Users->pi_add({
            UID   => $uid,
            FIO   => $query_params->{FIO},
            EMAIL => $query_params->{EMAIL},
            PHONE => $query_params->{PHONE}
          });

          if ($Users->{errno}) {
            $Users->del({
              UID => $uid,
            });

            return {
              errno  => 10019,
              errstr => 'Error occurred during add pi info of user',
            };
          }

          require Internet;
          Internet->import();
          my $Internet = Internet->new($self->{db}, $self->{admin}, $self->{conf});

          if ($query_params->{TP_ID}) {
            require Tariffs;
            Tariffs->import();
            my $Tariffs = Tariffs->new($self->{db}, $self->{conf}, $self->{admin});

            my $tp_list = $Tariffs->list({
              MODULE       => 'Internet',
              TP_ID        => $query_params->{TP_ID},
              TP_GID       => '_SHOW',
              NEW_MODEL_TP => 1,
              COLS_NAME    => 1,
              STATUS       => '0',
            });

            if ($tp_list && scalar @{$tp_list} < 1) {
              $Users->del({
                UID => $uid,
              });

              return {
                errno  => 10020,
                errstr => 'No tariff plan with this tpId',
              };
            }
            elsif ($self->{conf}->{INTERNET_REGISTRATION_TP_GIDS} && !in_array($tp_list->{tp_gid}, $self->{conf}->{INTERNET_REGISTRATION_TP_GIDS})) {
              $Users->del({
                UID => $uid,
              });

              return {
                errno  => 10021,
                errstr => 'Not available tariff plan',
              };
            }
          }

          $Internet->user_add({
            UID    => $uid,
            TP_ID  => $query_params->{TP_ID} || $self->{conf}->{REGISTRATION_DEFAULT_TP} || 0,
            STATUS => 2,
            CID    => $cid
          });

          if ($query_params->{REGISTRATION_TAG} && $self->{conf}->{AUTH_ROUTE_TAG} && in_array('Tags', \@main::MODULES)) {
            require Tags;
            Tags->import();

            my $Tags = Tags->new($self->{db}, $self->{conf}, $self->{admin});
            $Tags->tags_user_change({
              IDS => $self->{conf}->{AUTH_ROUTE_TAG},
              UID => $uid,
            });
          }

          if ($Internet->{errno}) {
            $Users->del({
              UID => $uid,
            });

            return {
              errno  => 10022,
              errstr => 'Failed create Internet service',
            };
          }

          my $prot = (defined($ENV{HTTPS}) && $ENV{HTTPS} =~ /on/i) ? 'https' : 'http';
          my $addr = (defined($ENV{HTTP_HOST})) ? "$prot://$ENV{HTTP_HOST}/index.cgi" : '';

          ::load_module("AXbills::Templates", { LOAD_PACKAGE => 1 });
          my $message = $self->{html}->tpl_show(::_include('internet_reg_complete_sms', 'Internet'), {
            %$Internet, %$query_params,
            PASSWORD => "$password",
            BILL_URL => $addr
          }, { OUTPUT2RETURN => 1 });

          require AXbills::Sender::Core;
          AXbills::Sender::Core->import();
          my $Sender = AXbills::Sender::Core->new($self->{db}, $self->{admin}, $self->{conf});

          if (in_array('Sms', \@main::MODULES) && $self->{conf}->{INTERNET_REGISTRATION_SEND_SMS}) {
            $Sender->send_message({
              TO_ADDRESS  => $query_params->{PHONE},
              MESSAGE     => $message,
              SENDER_TYPE => 'Sms',
              UID         => $uid
            });
          }
          else {
            $Sender->send_message({
              TO_ADDRESS   => $query_params->{EMAIL},
              MESSAGE      => $message,
              SUBJECT      => $self->{lang}->{REGISTRATION},
              SENDER_TYPE  => 'Mail',
              QUITE        => 1,
              CONTENT_TYPE => $self->{conf}->{REGISTRATION_MAIL_CONTENT_TYPE} ? $self->{conf}->{REGISTRATION_MAIL_CONTENT_TYPE} : '',
            });
          }

          my %result = (
            result => "Successfully created user with uid: $uid",
          );

          $result{redirect_url} = $self->{conf}->{REGISTRATION_REDIRECT} if ($self->{conf}->{REGISTRATION_REDIRECT});
          $result{password} = $password if ($self->{conf}->{REGISTRATION_SHOW_PASSWD});

          return \%result;
        },
      },
      {
        method      => 'GET',
        path        => '/user/:uid/config/',
        handler     => sub {
          my ($path_params, $query_params, $module_obj) = @_;
          require Control::Service_control;
          Control::Service_control->import();
          my $Service_control = Control::Service_control->new($self->{db}, $self->{admin}, $self->{conf}, { HTML => $self->{html}, LANG => $self->{lang} });

          require AXbills::Api::Functions;
          AXbills::Api::Functions->import();
          my $Functions = AXbills::Api::Functions->new($self->{db}, $self->{admin}, $self->{conf}, {
            modules => \@main::MODULES,
            uid     => $path_params->{uid}
          });

          my $user = $module_obj->list({
            UID        => $path_params->{uid},
            COMPANY_ID => '_SHOW',
            _GOOGLE    => '_SHOW',
            _FACEBOOK  => '_SHOW',
            _APPLE     => '_SHOW',
            COLS_NAME  => 1,
            COLS_UPPER => 1
          })->[0];

          my %functions = %{$Functions->{functions}};

          if ($functions{internet_user_chg_tp}) {
            my $list = $Service_control->available_tariffs({
              UID    => $path_params->{uid},
              MODULE => 'Internet'
            });

            if (ref $list ne 'ARRAY') {
              delete $functions{internet_user_chg_tp};
            }
            else {
              $functions{internet}{now} = 0 if ($self->{conf}->{INTERNET_USER_CHG_TP_NOW});
              $functions{internet}{next_month} = 1 if ($self->{conf}->{INTERNET_USER_CHG_TP_NEXT_MONTH});
              $functions{internet}{schedule} = 2 if ($self->{conf}->{INTERNET_USER_CHG_TP_SHEDULE});
            }
          }

          if ($self->{conf}->{HOLDUP_ALL} || $self->{conf}->{INTERNET_USER_SERVICE_HOLDUP}) {
            my ($type_holdup, $holdup);

            if ($self->{conf}->{HOLDUP_ALL}) {
              $type_holdup = 'user_holdup_all';
              $holdup = $self->{conf}->{HOLDUP_ALL};
            }
            else {
              $type_holdup = 'internet_user_holdup';
              $holdup = $self->{conf}->{INTERNET_USER_SERVICE_HOLDUP};
            }

            my ($min_period, $max_period, $holdup_period, $daily_fees, undef, $active_fees) = split(/:/, $holdup);

            $functions{$type_holdup} = {
              min_period    => $min_period,
              max_period    => $max_period,
              holdup_period => $holdup_period,
              daily_fees    => $daily_fees,
              active_fees   => $active_fees
            };
          }

          if ($self->{conf}->{AUTH_GOOGLE_ID}) {
            $functions{social_auth}{google} = (($user->{_GOOGLE} || q{}) =~ /(?<=,\s).*/gm) ? 1 : 0;
          }
          if ($self->{conf}->{AUTH_FACEBOOK_ID}) {
            $functions{social_auth}{facebook} = (($user->{_FACEBOOK} || q{}) =~ /(?<=,\s).*/gm) ? 1 : 0;
          }
          if ($self->{conf}->{AUTH_APPLE_ID}) {
            $functions{social_auth}{apple} = (($user->{_APPLE} || q{}) =~ /(?<=,\s).*/gm) ? 1 : 0;
          }

          my $credit_info = $Service_control->user_set_credit({ UID => $path_params->{uid} });
          if (!exists($credit_info->{error}) && !exists($credit_info->{errno})) {
            $functions{user_credit} = '1001';
          }

          if (in_array('Iptv', \@main::MODULES)) {
            my ($subscribe_id, $subscribe_name, $subscribe_describe) = split(/:/, $self->{conf}->{IPTV_SUBSCRIBE_ID} || q{});
            $functions{iptv_config}{subscribe}{id} = $subscribe_id || 'EMAIL';
            $functions{iptv_config}{subscribe}{name} = $subscribe_name || 'E-mail';
            $functions{iptv_config}{subscribe}{describe} = $subscribe_describe || '';

            require Iptv;
            Iptv->import();
            my $Iptv = Iptv->new($self->{db}, $self->{admin}, $self->{conf});
            $Iptv->iptv_promotion_tps();

            $functions{iptv_config}{promotion_tps} = 1 if ($Iptv->{TOTAL} && $Iptv->{TOTAL} > 0);
          }

          if (in_array('Cards', \@main::MODULES)) {
            $functions{cards_user_payment}{serial} = ($self->{conf}->{CARDS_PIN_ONLY}) ? 0 : 1;
            delete $functions{cards_user_payment} if ($self->{conf}->{CARDS_SKIP_COMPANY} && $user->{COMPANY_ID});
          }

          if ($functions{iptv_user_chg_tp}) {
            $functions{iptv}{next_month} = 1;
            my $list = $Service_control->available_tariffs({
              UID    => $path_params->{uid},
              MODULE => 'Internet'
            });

            if (ref $list ne 'ARRAY') {
              delete $functions{internet_user_chg_tp};
            }
            else {
              $functions{iptv}{next_month} = 1;
              $functions{iptv}{schedule} = 2 if ($self->{conf}->{INTERNET_USER_CHG_TP_SHEDULE} && !$self->{conf}->{IPTV_USER_CHG_TP_NPERIOD});
            }
          }

          $functions{system}{currency} = $self->{conf}->{SYSTEM_CURRENCY} if ($self->{conf}->{SYSTEM_CURRENCY});
          $functions{system}{password}{regex} = $self->{conf}->{PASSWD_SYMBOLS} if ($self->{conf}->{PASSWD_SYMBOLS});
          $functions{system}{password}{symbols} = $self->{conf}->{PASSWD_LENGTH} if ($self->{conf}->{PASSWD_LENGTH});

          $functions{bots}{viber} = "viber://pa?chatURI=$self->{conf}->{VIBER_BOT_NAME}&text=/start&context=u_" if ($self->{conf}->{VIBER_TOKEN} && $self->{conf}->{VIBER_BOT_NAME});
          $functions{bots}{telegram} = "https://t.me/$self->{conf}->{TELEGRAM_BOT_NAME}?start=u_" if ($self->{conf}->{TELEGRAM_TOKEN} && $self->{conf}->{TELEGRAM_BOT_NAME});

          $functions{social_networks} = $self->{conf}->{SOCIAL_NETWORKS} if ($self->{conf}->{SOCIAL_NETWORKS});
          $functions{review_pages} = $self->{conf}->{REVIEW_PAGES} if ($self->{conf}->{REVIEW_PAGES});

          $functions{user_chg_passwd} = 1 if ($self->{conf}->{user_chg_passwd});

          return \%functions;
        },
        module      => 'Users',
        credentials => [
          'USER', 'USERBOT'
        ]
      },
      {
        method               => 'DELETE',
        path                 => '/user/:uid/social/networks/',
        handler              => sub {
          my ($path_params, $query_params, $module_obj) = @_;

          my $changed_field = '--';

          if ($self->{conf}->{AUTH_GOOGLE_ID} && $query_params->{google}) {
            $changed_field = '_GOOGLE';
          }
          elsif ($self->{conf}->{AUTH_GOOGLE_ID} && $query_params->{facebook}) {
            $changed_field = '_FACEBOOK';
          }
          elsif ($self->{conf}->{AUTH_APPLE_ID} && $query_params->{apple}) {
            $changed_field = '_APPLE';
          }
          else {
            return {
              errno  => 11004,
              errstr => 'Unknown social network'
            };
          }

          $module_obj->pi_change({ UID => $path_params->{uid}, $changed_field => '' });

          return {
            result => 'success'
          };
        },
        module               => 'Users',
        no_decamelize_params => 1,
        credentials          => [
          'USER'
        ]
      },
      {
        method               => 'POST',
        path                 => '/user/:uid/social/networks/',
        handler              => sub {
          my ($path_params, $query_params) = @_;

          %main::FORM = ();
          if ($self->{conf}->{AUTH_GOOGLE_ID} && $query_params->{google}) {
            $main::FORM{token} = $query_params->{google};
            $main::FORM{external_auth} = 'Google';
            $main::FORM{API} = 1;
          }
          elsif ($self->{conf}->{AUTH_FACEBOOK_ID} && $query_params->{facebook}) {
            $main::FORM{token} = $query_params->{facebook};
            $main::FORM{external_auth} = 'Facebook';
            $main::FORM{API} = 1;
          }
          elsif ($self->{conf}->{AUTH_APPLE_ID} && $query_params->{apple}) {
            $main::FORM{token} = $query_params->{apple};
            $main::FORM{external_auth} = 'Apple';
            $main::FORM{API} = 1;
            $main::FORM{NONCE} = $query_params->{nonce} if ($query_params->{nonce});
          }
          else {
            return {
              errno  => 11002,
              errstr => 'Unknown social network or no token'
            }
          }

          my ($uid, $sid, $login) = ::auth_user('', '', $ENV{HTTP_USERSID}, { API => 1 });

          if (ref $uid eq 'HASH') {
            return $uid;
          }

          if (!$uid) {
            return {
              errno  => 11003,
              errstr => 'Failed to set social network token. Unknown token'
            };
          }

          return {
            result => 'success'
          };
        },
        no_decamelize_params => 1,
        credentials          => [
          'USER'
        ]
      },
      {
        method      => 'GET',
        path        => '/user/services/',
        handler     => sub {
          my ($path_params, $query_params) = @_;

          my %services = ();
          ::load_module('Control::Services', { LOAD_PACKAGE => 1 });

          if (in_array('Internet', \@main::MODULES)) {
            $services{internet} = ::get_user_services({
              uid     => $path_params->{uid},
              service => 'Internet',
            });
          }
          if (in_array('Iptv', \@main::MODULES)) {
            $services{iptv} = ::get_user_services({
              uid     => $path_params->{uid},
              service => 'Iptv',
            });
          }
          if (in_array('Abon', \@main::MODULES)) {
            $services{abon} = ::get_user_services({
              uid     => $path_params->{uid},
              service => 'Abon',
            });
          }
          if (in_array('Voip', \@main::MODULES)) {
            my $tariffs = ::get_user_services({
              uid     => $path_params->{uid},
              service => 'Voip',
            });

            $services{voip} = $tariffs if (ref $tariffs eq 'ARRAY');
          }

          return \%services;
        },
        credentials => [
          'USER', 'USERBOT'
        ]
      },
      {
        method               => 'POST',
        path                 => '/user/login/',
        handler              => sub {
          my ($path_params, $query_params) = @_;
          return $self->_users_login($path_params, $query_params);
        },
        no_decamelize_params => 1,
      },
    ]
  };
}

#**********************************************************
=head2 _users_login($path_params, $query_params)

=cut
#**********************************************************
sub _users_login {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my $session_id = '';
  %main::FORM = ();

  if ($self->{conf}->{AUTH_GOOGLE_ID} && $query_params->{google}) {
    $main::FORM{token} = $query_params->{google};
    $main::FORM{external_auth} = 'Google';
    $main::FORM{API} = 1;
    $session_id = 'plug' if ($self->{conf}->{PASSWORDLESS_ACCESS});
  }
  elsif ($self->{conf}->{AUTH_FACEBOOK_ID} && $query_params->{facebook}) {
    $main::FORM{token} = $query_params->{facebook};
    $main::FORM{external_auth} = 'Facebook';
    $main::FORM{API} = 1;
    $session_id = 'plug' if ($self->{conf}->{PASSWORDLESS_ACCESS});
  }
  elsif ($self->{conf}->{AUTH_APPLE_ID} && $query_params->{apple}) {
    $main::FORM{token} = $query_params->{apple};
    $main::FORM{external_auth} = 'Apple';
    $main::FORM{API} = 1;
    $session_id = 'plug' if ($self->{conf}->{PASSWORDLESS_ACCESS});
  }

  my ($uid, $sid, $login) = ::auth_user($query_params->{login} || '', $query_params->{password} || '', $session_id, { API => 1 });

  if (ref $uid eq 'HASH') {
    return $uid;
  }

  if (!$uid) {
    return {
      errno  => 10001,
      errstr => 'Wrong login or password or auth token'
    };
  }

  my %result = (
    uid   => $uid,
    sid   => $sid,
    login => $login
  );

  if ((defined $self->{conf}->{API_LOGIN_SHOW_PASSWORD} && $main::FORM{external_auth}) ||
    ($self->{conf}->{REGISTRATION_VERIFY_PHONE} || $self->{conf}->{REGISTRATION_VERIFY_EMAIL})) {
    require Users;
    Users->import();
    my $Users = Users->new($self->{db}, $self->{admin}, $self->{conf});

    if (defined $self->{conf}->{API_LOGIN_SHOW_PASSWORD} && $main::FORM{external_auth}) {
      my $user_info = $Users->info($uid, { SHOW_PASSWORD => 1 });

      $result{password} = caesar_cipher($user_info->{PASSWORD}, $self->{conf}->{API_LOGIN_SHOW_PASSWORD});
      $result{password} = "<str_>$result{password}";
    }

    if ($self->{conf}->{REGISTRATION_VERIFY_PHONE} || $self->{conf}->{REGISTRATION_VERIFY_EMAIL}) {
      $Users->registration_pin_info({ UID => $uid });
      if ($Users->{errno}) {
        $result{is_verified} = 'true';
      }
      else {
        $result{is_verified} = $Users->{VERIFY_DATE} eq '0000-00-00 00:00:00' ? 'false' : 'true';
      }
    }
  }

  $result{login} = "<str_>$result{login}";
  return \%result;
}

#**********************************************************
=head2 _payments_user ($path_params, $query_params, $module_obj)

=cut
#**********************************************************
sub _payments_user {
  my $self = shift;
  my ($path_params, $query_params, $module_obj) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if (!$self->{admin}->{permissions}{1}{0} && !$self->{admin}->{permissions}{1}{3});

  foreach my $param (keys %{$query_params}) {
    $query_params->{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0') ? $query_params->{$param} : '_SHOW';
  }

  $query_params->{DESC} = $query_params->{DESC} || 'DESC';
  $query_params->{SUM} = $query_params->{SUM} || '_SHOW';
  $query_params->{REG_DATE} = $query_params->{REG_DATE} || '_SHOW';
  $query_params->{METHOD} = $query_params->{METHOD} || '_SHOW';
  $query_params->{UID} = $path_params->{uid} || $query_params->{UID} || '_SHOW';
  $query_params->{FROM_DATE} = ($query_params->{TO_DATE} && !$query_params->{FROM_DATE}) ? '0000-00-00' : $query_params->{FROM_DATE} ? $query_params->{FROM_DATE} : undef;
  $query_params->{TO_DATE} = ($query_params->{FROM_DATE} && !$query_params->{TO_DATE}) ? '_SHOW' : $query_params->{TO_DATE} ? $query_params->{TO_DATE} : undef;
  $query_params->{INVOICE_NUM} = '_SHOW' if ($query_params->{INVOICE_DATE} && !$query_params->{INVOICE_NUM});

  return $module_obj->list({
    %{$query_params},
    COLS_NAME => 1
  });
}

#**********************************************************
=head2 _fees_user($path_params, $query_params, $module_obj)

=cut
#**********************************************************
sub _fees_user {
  my $self = shift;
  my ($path_params, $query_params, $module_obj) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if (!$self->{admin}->{permissions}{2}{0} && !$self->{admin}->{permissions}{2}{3});

  foreach my $param (keys %{$query_params}) {
    $query_params->{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0') ? $query_params->{$param} : '_SHOW';
  }

  $query_params->{INVOICE_ID} = $query_params->{INVOICE_ID} || '_SHOW' if ($query_params->{INVOICE_NUM});
  $query_params->{DESC} = $query_params->{DESC} || 'DESC';
  $query_params->{SUM} = $query_params->{SUM} || '_SHOW';
  $query_params->{REG_DATE} = $query_params->{REG_DATE} || '_SHOW';
  $query_params->{METHOD} = $query_params->{METHOD} || '_SHOW';
  $query_params->{DSC} = $query_params->{DSC} || '_SHOW';
  $query_params->{UID} = $path_params->{uid} || $query_params->{UID} || '_SHOW';
  $query_params->{FROM_DATE} = ($query_params->{TO_DATE} && !$query_params->{FROM_DATE}) ? '0000-00-00' : $query_params->{FROM_DATE} ? $query_params->{FROM_DATE} : undef;
  $query_params->{TO_DATE} = ($query_params->{FROM_DATE} && !$query_params->{TO_DATE}) ? '_SHOW' : $query_params->{TO_DATE} ? $query_params->{TO_DATE} : undef;

  $module_obj->list({
    %{$query_params},
    COLS_NAME => 1
  });
}

1;
