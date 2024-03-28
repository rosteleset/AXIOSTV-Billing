package Cablecat::Api;
=head NAME

  Cablecat::Api - Cablecat api functions

=head VERSION

  DATE: 20230130
  UPDATE: 20230130
  VERSION: 0.01

=cut

use strict;
use warnings FATAL => 'all';

# use Cablecat;
#
# my Cablecat $Cablecat;

our %lang;
require 'AXbills/modules/Cablecat/lng_english.pl';

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
    debug => $debug
  };

  bless($self, $class);

  my %LANG = (%{$lang}, %lang);

  # $Cablecat = Cablecat->new($db, $admin, $conf);
  # $Cablecat->{debug} = $self->{debug};

  $self->{routes_list} = ();
  $self->{routes_list} = $self->admin_routes() if $type eq 'admin';

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
      method      => 'POST',
      path        => '/cablecat/attachment/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        my @file_names = ();
        foreach my $key (keys %{$query_params}) {
          next if ref $query_params->{$key} ne 'HASH' || !$query_params->{$key}{filename};

          my $file_name = $query_params->{$key}{filename};
          if ($file_name =~ /([^\.]+)\.([a-z0-9\_]+)$/i) {
            my $file_extension = $2;
            $file_name = AXbills::Base::txt2translit($1) . '_' . time() . '.' . $file_extension;
          }

          if (main::upload_file($query_params->{$key}, { FILE_NAME => $file_name, PREFIX => 'cablecat', REWRITE => 1 })) {
            push @file_names, $file_name;
          }
        }

        return { files => \@file_names };
      },
      credentials => [ 'ADMIN', 'ADMINSID' ]
    },
  ];
}

1;