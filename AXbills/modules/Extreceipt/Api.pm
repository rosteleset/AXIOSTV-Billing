package Extreceipt::Api;
=head NAME

  Extreceipt::Api - Extreceipt api functions

=head VERSION

  DATE: 20220618
  UPDATE: 20220619
  VERSION: 0.01

=cut

use strict;
use warnings FATAL => 'all';

use Extreceipt::db::Extreceipt;
use Extreceipt::Base;

my Extreceipt $Receipt;

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

  $Receipt = Extreceipt->new($self->{db}, $self->{admin}, $self->{conf});
  my $Receipt_api = receipt_init($Receipt, { SKIP_INIT => 1 });
  $Receipt->{API} = $Receipt_api;
  $Receipt->{debug} = $self->{debug};

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
      path        => '/user/:uid/extreceipt/checks/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        my $list = $Receipt->list({
          UID => $path_params->{uid},
        });

        my @return = ();

        foreach my $check (@{$list}) {
          my %params = (
            date       => $check->{date},
            payment_id => $check->{payments_id},
          );
          if ($Receipt->{API}->{$check->{api_id}}->can('get_receipt')) {
            $params{check_url} = ($check->{command_id} =~ /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/gm) ?
              $Receipt->{API}->{$check->{api_id}}->get_receipt($check) : "";

            if ($check->{cancel_id} =~ /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/gm) {
              $check->{command_id} = $check->{cancel_id};
              $params{check_cancel_url} = $Receipt->{API}->{$check->{api_id}}->get_receipt($check);
            }
          }
          push @return, \%params;
        }

        return \@return;
      },
      credentials => [
        'USER'
      ]
    },
  ]
}

1;
