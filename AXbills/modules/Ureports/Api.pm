package Ureports::Api;
use strict;
use warnings FATAL => 'all';

use Ureports;

my Ureports $Ureports;
require AXbills::Sender::Core;
my %send_methods = %AXbills::Sender::Core::PLUGIN_NAME_FOR_TYPE_ID;

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

  $Ureports = Ureports->new($db, $admin, $conf);

  $Ureports->{debug} = $self->{debug};

  $self->{routes_list} = ();

  if ($type && $type eq 'admin') {
    $self->{routes_list} = $self->admin_routes();
  }

  return $self;
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
      path        => '/ureports/user/list/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        foreach my $param (keys %{$query_params}) {
          $query_params->{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0') ? $query_params->{$param} : '_SHOW';
        }

        my $users = $Ureports->user_list({
          %$query_params,
          DESTINATION => '_SHOW',
          TYPE        => '_SHOW',
          COLS_NAME   => 1,
        });

        if ($users && scalar @{$users}) {
          foreach my $user (@{$users}) {
            my @types = split(',', ($user->{type} || ''));
            my @destination = split(',', ($user->{destination} || ''));
            delete $user->{type};
            $user->{destinations} = [];
            delete @{$user}{qw/destination type/};
            if (scalar @types) {
              for (my $i = 0; $i <= $#types; $i++) {
                push @{$user->{destinations}}, {
                  type        => $types[$i],
                  name        => $send_methods{$types[$i]},
                  destination => $destination[$i],
                };
              }
            }
          }
        }

        return $users;
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/ureports/user/:uid/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        foreach my $param (keys %{$query_params}) {
          $query_params->{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0') ? $query_params->{$param} : '_SHOW';
        }

        my $user = $Ureports->user_list({
          UID            => $path_params->{uid},
          TP_ID          => '_SHOW',
          TP_NAME        => '_SHOW',
          DESTINATION    => '_SHOW',
          DESTINATION_ID => '_SHOW',
          TYPE           => '_SHOW',
          STATUS         => '_SHOW',
          REPORTS_COUNT  => '_SHOW',
          COLS_NAME      => 1,
        });

        if ($user && scalar @{$user}) {
          $user = $user->[0];
          my @types = split(',', ($user->{type} || ''));
          my @destination = split(',', ($user->{destination} || ''));
          $user->{destinations} = [];
          delete @{$user}{qw/destination type/};
          if (scalar @types) {
            for (my $i = 0; $i <= $#types; $i++) {
              push @{$user->{destinations}}, {
                type        => $types[$i],
                name        => $send_methods{$types[$i]},
                destination => $destination[$i],
              };
            }
          }
        }

        return $user;
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'POST',
      path        => '/ureports/user/:uid/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        return {
          errno  => 10,
          errstr => 'Access denied'
        } if !$self->{admin}->{permissions}{0}{4};

        return {
          errno  => 10,
          errstr => 'Access denied'
        } if !$self->{admin}->{permissions}{0}{10};

        return {
          errno  => 103001,
          errstr => 'No field tpId'
        } if !$query_params->{TP_ID};

        return {
          errno  => 103002,
          errstr => 'No field destinations'
        } if !defined $query_params->{DESTINATIONS};

        return {
          errno  => 103015,
          errstr => 'Destinations must be array'
        } if ref $query_params->{DESTINATIONS} ne 'ARRAY';

        my $list = $Ureports->user_list({
          UID       => $path_params->{uid},
          COLS_NAME => 1,
        });

        if ($list && scalar @{$list}) {
          return {
            errno  => 103003,
            errstr => 'User info exists'
          };
        }

        my %destinations = (
          TYPE => '',
        );

        foreach my $destination (@{$query_params->{DESTINATIONS}}) {
          next if (ref $destination ne 'HASH');
          next if (!$destination->{ID});
          $destinations{TYPE} .= "$destination->{ID},";
          $destinations{'DESTINATION_' . $destination->{ID}} = $destination->{VALUE} || 0;
        }

        $Ureports->user_add({
          %{$query_params || {}},
          %destinations,
          UID => $path_params->{uid},
        });

        $Ureports->user_info($path_params->{uid});

        my %destinations_ = $Ureports->{DESTINATIONS} ? split /[|,]/, $Ureports->{DESTINATIONS} : ();
        my $destinations;

        foreach my $dest (keys %destinations_) {
          push @{$destinations}, {
            id    => $dest,
            value => $destinations_{$dest},
          };
        }

        $Ureports->{DESTINATIONS} = $destinations;
        delete @{$Ureports}{qw/list AFFECTED TOTAL TP_INFO TYPES/};
        return $Ureports;
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'PUT',
      path        => '/ureports/user/:uid/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        return {
          errno  => 10,
          errstr => 'Access denied'
        } if !$self->{admin}->{permissions}{0}{4};

        return {
          errno  => 10,
          errstr => 'Access denied'
        } if !$self->{admin}->{permissions}{0}{10};

        return {
          errno  => 103016,
          errstr => 'Destinations must be array'
        } if $query_params->{DESTINATIONS} && ref $query_params->{DESTINATIONS} ne 'ARRAY';

        my %destinations = ();

        if ($query_params->{DESTINATIONS}) {
          $destinations{TYPE} = '';

          foreach my $destination (@{$query_params->{DESTINATIONS}}) {
            next if (ref $destination ne 'HASH');
            next if (!$destination->{ID});
            $destinations{TYPE} .= "$destination->{ID},";
            $destinations{'DESTINATION_' . $destination->{ID}} = $destination->{VALUE} || 0;
          }
        }
        else {
          $query_params->{SKIP_ADD_SEND_TYPES} = 1;
        }

        $Ureports->user_change({
          %{$query_params || {}},
          %destinations,
          UID => $path_params->{uid},
        });

        $Ureports->user_info($path_params->{uid});

        my %destinations_ = $Ureports->{DESTINATIONS} ? split /[|,]/, $Ureports->{DESTINATIONS} : ();
        my $destinations;

        foreach my $dest (keys %destinations_) {
          push @{$destinations}, {
            id    => $dest,
            value => $destinations_{$dest},
          };
        }

        $Ureports->{DESTINATIONS} = $destinations;
        delete @{$Ureports}{qw/list AFFECTED TOTAL TYPES/};
        return $Ureports;
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'DELETE',
      path        => '/ureports/user/:uid/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        return {
          errno  => 10,
          errstr => 'Access denied'
        } if !$self->{admin}->{permissions}{0}{4};

        return {
          errno  => 10,
          errstr => 'Access denied'
        } if !$self->{admin}->{permissions}{0}{10};

        $Ureports->{UID} = $path_params->{uid};
        $Ureports->user_del({ UID => $path_params->{uid} });

        if (!$Ureports->{errno}) {
          if ($Ureports->{AFFECTED} && $Ureports->{AFFECTED} =~ /^[0-9]$/) {
            return {
              result => 'Successfully deleted',
            };
          }
          else {
            return {
              errno  => 103006,
              errstr => "No user with uid $path_params->{uid}",
            };
          }
        }

        return $Ureports;
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/ureports/user/:uid/reports/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        my $active_reports = $Ureports->tp_user_reports_list({
          UID       => $path_params->{uid},
          REPORT_ID => '_SHOW',
          COLS_NAME => 1
        });

        if ($active_reports && !scalar @{$active_reports}) {
          return {
            errno  => 103007,
            errstr => 'No user with report service'
          };
        }

        my %report_names = (
          '1'  => 'Deposit below',
          '2'  => 'Deposit + Credit Below',
          '3'  => 'Prepaid Traffic Below',
          '4'  => 'Day: Traffic more then',
          '5'  => 'Month: Deposit + Credit + Traffic',
          '6'  => 'Day: Deposit + Credit + Traffic',
          '7'  => 'Credit Expired',
          '8'  => 'Login Disable ',
          '9'  => 'Internet: Days To Expire',
          '10' => 'Too small deposit for next month',
          '11' => 'Too small deposit for next month v2',
          '12' => 'Payments information',
          '13' => 'All Service expired through XX days',
          '14' => 'Send deposit before user payment',
          '15' => 'Internet Service disabled',
          '16' => 'Next period tariff plan',
          '17' => 'Happy Birthday',
        );

        my %user_reports = (
          active_reports    => [],
          available_reports => [],
        );

        foreach my $report (@{$active_reports}) {
          $report->{report_name} = $report_names{$report->{report_id}} || '';

          $report->{uid} ? push @{$user_reports{active_reports}}, $report
            : push @{$user_reports{available_reports}}, $report;
        }

        return \%user_reports;
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'POST',
      path        => '/ureports/user/:uid/reports/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        return {
          errno  => 10,
          errstr => 'Access denied'
        } if !$self->{admin}->{permissions}{0}{4};

        return {
          errno  => 10,
          errstr => 'Access denied'
        } if !$self->{admin}->{permissions}{0}{10};

        return {
          errno  => 103010,
          errstr => 'No field reports'
        } if !$query_params->{REPORTS};

        return {
          errno  => 103012,
          errstr => 'Field reports not array'
        } if ref $query_params->{REPORTS} ne 'ARRAY';

        my $active_reports = $Ureports->tp_user_reports_list({
          UID       => $path_params->{uid},
          REPORT_ID => '_SHOW',
          TP_ID     => '_SHOW',
          COLS_NAME => 1
        });

        if ($active_reports && !scalar @{$active_reports}) {
          return {
            errno  => 103007,
            errstr => 'No user with report service'
          };
        }

        #TODO: maybe Do not delete existing reports and add logic to operate old reports?

        my %report_params = (
          IDS => '',
        );

        foreach my $report (@{$query_params->{REPORTS}}) {
          next if (ref $report ne 'HASH');
          next if (!$report->{ID});
          $report_params{IDS} .= "$report->{ID},";
          $report_params{'VALUE_' . $report->{ID}} = $report->{VALUE} || 0;
        }

        $Ureports->tp_user_reports_change({
          %report_params,
          UID   => $path_params->{uid},
          TP_ID => $active_reports->[0]->{tp_id},
        });

        if (!$Ureports->{errno}) {
          if ($Ureports->{TOTAL} && $Ureports->{TOTAL} =~ /^[0-9]$/) {
            return {
              result => 'Successfully added reports',
            };
          }
          else {
            return {
              warn => 'No reports added',
              code => 103013
            };
          }
        }

        return $Ureports;
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'DELETE',
      path        => '/ureports/user/:uid/reports/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        return {
          errno  => 10,
          errstr => 'Access denied'
        } if !$self->{admin}->{permissions}{0}{4};

        return {
          errno  => 10,
          errstr => 'Access denied'
        } if !$self->{admin}->{permissions}{0}{10};

        $Ureports->tp_user_reports_del({
          UID => $path_params->{uid} || '--'
        });

        if (!$Ureports->{errno}) {
          if ($Ureports->{AFFECTED} && $Ureports->{AFFECTED} =~ /^[0-9]$/) {
            return {
              result => 'Successfully deleted',
            };
          }
          else {
            return {
              errno  => 103008,
              errstr => "User with uid $path_params->{uid} has no reports",
            };
          }
        }

        return $Ureports;
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'DELETE',
      path        => '/ureports/user/:uid/reports/:id/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        return {
          errno  => 10,
          errstr => 'Access denied'
        } if !$self->{admin}->{permissions}{0}{4};

        return {
          errno  => 10,
          errstr => 'Access denied'
        } if !$self->{admin}->{permissions}{0}{10};

        $Ureports->tp_user_reports_del({
          UID       => $path_params->{uid} || '--',
          REPORT_ID => $path_params->{id} || '--'
        });

        if (!$Ureports->{errno}) {
          if ($Ureports->{AFFECTED} && $Ureports->{AFFECTED} =~ /^[0-9]$/) {
            return {
              result => 'Successfully deleted',
            };
          }
          else {
            return {
              errno  => 103008,
              errstr => "User with uid $path_params->{uid} has no report with id $path_params->{id}",
            };
          }
        }

        return $Ureports;
      },
      credentials => [
        'ADMIN'
      ]
    },
  ];
}

1;
