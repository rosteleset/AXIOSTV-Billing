package AXbills::Api::Paths::Bots;
=head NAME

  AXbills::Api::Paths::Bots - Bots api functions

=cut

use strict;
use warnings FATAL => 'all';

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

  return $self;
}

#**********************************************************
=head2 paths() - Returns available API paths

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
      method      => 'POST',
      path        => '/user/bots/subscribe/phone/',
      handler     => sub {
        my ($path_params, $query_params) = @_;
        return {
          errno  => 10040,
          errstr => 'No field phone',
        } if (!$query_params->{PHONE});

        $query_params->{PHONE} =~ s/\D//g;

        if ($self->{conf}->{TELEGRAM_NUMBER_EXPR}) {
          my ($left, $right) = split '/', $self->{conf}->{TELEGRAM_NUMBER_EXPR};

          $query_params->{PHONE} =~ s/$left/$right/ge;
        }

        require Contacts;
        Contacts->import();
        my $Contacts = Contacts->new($self->{db}, $self->{admin}, $self->{conf});

        my $check_list = $Contacts->contacts_list({
          TYPE  => $query_params->{BOT},
          VALUE => $query_params->{USER_ID},
          UID   => '_SHOW',
        });

        if ($Contacts->{TOTAL} && scalar (@{$check_list}) > 0) {
          return {
            result => 'Already subscribed',
            code   => 1,
          };
        }

        my $list = $Contacts->contacts_list({
          VALUE => $query_params->{PHONE},
          UID   => '_SHOW',
        });

        if ($Contacts->{TOTAL} && $list->[0]->{uid}) {
          $Contacts->contacts_add({
            UID      => $list->[0]->{uid},
            TYPE_ID  => $query_params->{BOT},
            VALUE    => $query_params->{USER_ID},
            PRIORITY => 0,
          });

          return {
            result => 'Successfully added',
            code   => 2,
          };
        }
        else {
          return {
            errno  => 10042,
            errstr => 'Unknown phone',
          };
        }
      },
      credentials => [
        'USERBOT_UNREG'
      ]
    },
    {
      method      => 'GET',
      path        => '/user/bots/subscribe/link/:string_bot/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        return $self->_bot_link($path_params, $query_params);
      },
      credentials => [
        'USER'
      ]
    },
    {
      method       => 'GET',
      path         => '/user/bots/subscribe/qrcode/:string_bot/',
      handler      => sub {
        my ($path_params, $query_params) = @_;

        my $bot_link = $self->_bot_link($path_params, $query_params);

        return $bot_link if ($bot_link->{errno});

        require Control::Qrcode;
        Control::Qrcode->import();

        my $QRCode = Control::Qrcode->new($self->{db}, $self->{admin}, $self->{conf}, { html => $self->{html} });
        my $qr_code_image = $QRCode->qr_make_image_from_string($bot_link->{bot_link});

        return $qr_code_image;
      },
      content_type => 'Content-Type: image/jpeg',
      credentials  => [
        'USER'
      ]
    },
    {
      method      => 'POST',
      path        => '/user/bots/subscribe/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        return {
          errno  => 10045,
          errstr => 'No field token',
        } if (!$query_params->{TOKEN});

        my ($type, $sid) = $query_params->{TOKEN} =~ m/^([u])_([a-zA-Z0-9]+)/;

        return {
          errno  => 10046,
          errstr => 'Invalid field token',
        } if (!$type || !$sid);

        require Users;
        Users->import();
        my $Users = Users->new($self->{db}, $self->{admin}, $self->{conf});
        my $uid = $Users->web_session_find($sid);

        return {
          errno  => 10047,
          errstr => 'Unknown token',
        } if (!$uid);

        require Contacts;
        Contacts->import();
        my $Contacts = Contacts->new($self->{db}, $self->{admin}, $self->{conf});

        my $list = $Contacts->contacts_list({
          TYPE  => $query_params->{BOT},
          VALUE => $query_params->{USER_ID},
          UID   => '_SHOW',
        });

        if (!$Contacts->{TOTAL} || scalar (@{$list}) == 0) {
          $Contacts->contacts_add({
            UID      => $uid,
            TYPE_ID  => $query_params->{BOT},
            VALUE    => $query_params->{USER_ID},
            PRIORITY => 0,
          });

          return {
            result => 'Successfully added',
            code   => 2,
          };
        }
        else {
          return {
            result => 'Already subscribed',
            code   => 1,
          };
        }
      },
      credentials => [
        'USERBOT_UNREG'
      ]
    },
  ],
}

#**********************************************************
=head2 _bot_link() return subscribe link for bots

  Arguments:
    $path_params: object  - hash of params from request path
    $query_params: object - hash of query params from request

  Returns:
    List of extra modules

=cut
#**********************************************************
sub _bot_link {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my $bot_link = q{};

  if (uc"$path_params->{bot}" eq 'VIBER') {
    return {
      errno  => 10043,
      errstr => 'Unknown viber bot'
    } if (!$self->{conf}->{VIBER_BOT_NAME});

    $bot_link = "viber://pa?chatURI=$self->{conf}->{VIBER_BOT_NAME}&context=u_$query_params->{REQUEST_USERSID}&text=/start";
  }
  elsif (uc"$path_params->{bot}" eq 'TELEGRAM') {
    return {
      errno  => 10044,
      errstr => 'Unknown telegram bot'
    } if (!$self->{conf}->{TELEGRAM_BOT_NAME});

    $bot_link = "https://t.me/$self->{conf}->{TELEGRAM_BOT_NAME}?start=u_$query_params->{REQUEST_USERSID}";
  }
  else {
    return {
      errno  => 10049,
      errstr => 'Unknown bot'
    }
  }

  return {
    bot_link => $bot_link
  };
}

1;
