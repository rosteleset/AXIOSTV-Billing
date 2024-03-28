package AXbills::Api::Handle;

use strict;
use warnings FATAL => 'all';

use AXbills::Api::Router;
use AXbills::Api::FieldsGrouper;
use AXbills::Base qw(json_former xml_former gen_time in_array check_ip);

#**********************************************************
=head2 new($db, $admin, $conf)

=cut
#**********************************************************
sub new {
  my ($class, $db, $admin, $conf, $attr) = @_;

  # define db calls from api to prevent direct prints from dbcore
  $db->{api} = 1;

  my $self = {
    db             => $db,
    admin          => $admin,
    conf           => $conf,
    req_params     => $attr->{req_params},
    html           => $attr->{html},
    lang           => $attr->{lang},
    cookies        => $attr->{cookies},
    path           => $attr->{path},
    begin_time     => $attr->{begin_time},
    request_method => $attr->{request_method},
    return_type    => $attr->{return_type},
    direct         => $attr->{direct} || 0,
  };

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 _start()

=cut
#**********************************************************
sub _start {
  my $self = shift;
  my $response = q{};
  my $status = 200;
  my $content_type = q{};
  my $use_camelize = 1;
  my $router = {};

  my $request_body = $self->{req_params}->{__BUFFER} || '';

  if (!$self->{conf}->{API_ENABLE} && !$self->{direct}) {
    $status = 400;
    $response = { errstr => 'It seems that the API is currently disabled in the configuration. To enable it,  add the following line of code: $conf{API_ENABLE}=1;', errno => 301 };
  }
  else {
    #define $admin->{permissions}
    if ($self->{cookies}->{admin_sid}) {
      ::check_permissions('', '', ($self->{cookies}->{admin_sid} || q{}), {});
    }
    else {
      ::check_permissions('', '', '', { API_KEY => $ENV{HTTP_KEY} });
    }

    #TODO : Fix %FORM add make possible to paste query params with request body
    $router = AXbills::Api::Router->new($self->{path}, $self->{db}, $self->{admin}, $self->{conf}, $self->{req_params}, $self->{lang}, \@main::MODULES, 0, $self->{html}, $self->{request_method});

    if ($router->{errno}) {
      $status = $router->{errno} == 10 ? 403 : ($router->{status}) ? $router->{status} : 400;
      $response = { errstr => $router->{errstr}, errno => $router->{errno} };
    }
    else {
      $self->add_credentials($router);
      $router->handle();

      if ($router->{allowed}) {
        $router->transform(\&AXbills::Api::FieldsGrouper::group_fields);
        $router->{status} = 400 if !$router->{status} && $router->{errno};
      }
      else {
        $router->{result} = { errstr => 'Access denied', errno => 10 };
        $router->{status} = 401;
      }

      if (!$router->{status} && ref $router->{result} eq 'HASH' && ($router->{result}->{errno} || $router->{result}->{error})) {
        $router->{status} = 400;
        $router->{status} = 401 if ($router->{result}->{errno} && $router->{result}->{errno} eq 10 || ($router->{result}->{errstr} && $router->{result}->{errstr} eq 'Access denied'));
      }

      $response = $router->{result};
      $status = $router->{status};
      $content_type = q{};
      if ($router->{content_type}) {
        $content_type = ($router->{content_type} =~ /image/ && ref $response eq 'HASH') ? q{} : $router->{content_type};
      }
      $response = {} if (!defined $response || !$response);
    }

    if ($router->{error_msg} && !$self->{db}->{db}->{AutoCommit}) {
      $self->{db}->{db}->rollback();
      $self->{db}->{db}->{AutoCommit} = 1;
    }
  }

  if ($self->{return_type} && $self->{return_type} eq 'json' && !$content_type) {
    $use_camelize = ($router->{query_params}->{snakeCase} || (defined $self->{conf}{API_FILDS_CAMELIZE} && !$self->{conf}{API_FILDS_CAMELIZE})) ? 0 : 1;

    $response = json_former($response, {
      USE_CAMELIZE       => $use_camelize,
      CONTROL_CHARACTERS => 1,
      BOOL_VALUES        => 1,
      UNIQUE_KEYS        => 1
    });
  }
  elsif ($self->{return_type} && $self->{return_type} eq 'xml' && !$content_type) {
    $response = xml_former($response, { ROOT_NAME => 'response', PRETTY => 1, ENCODING => 'UTF-8' });
  }

  if ($self->{conf}->{API_LOG} && $self->{return_type}) {
    require Api;
    Api->import();

    my $begin_time = $main::begin_time || $self->{begin_time} || 0;
    my $Api = Api->new($self->{db}, $self->{admin}, $self->{conf});
    my $response_time = gen_time($begin_time, { TIME_ONLY => 1 });

    my %headers = ();
    foreach my $var (keys %ENV) {
      if ($var =~ /(?<=HTTP_).*/) {
        my ($header) = $var =~ /(?<=HTTP_).*/g;
        $headers{$header} = $ENV{$var};
      }
    }

    $Api->add({
      UID             => ($router->{handler}->{path_params}->{uid} || q{}),
      SID             => ($router->{handler}->{query_params}->{REQUEST_USERSID} || q{}),
      AID             => ($router->{admin}->{AID} || q{}),
      REQUEST_URL     => $self->{path},
      REQUEST_BODY    => $request_body,
      REQUEST_HEADERS => json_former(\%headers),
      RESPONSE_TIME   => $response_time,
      RESPONSE        => $response,
      IP              => $ENV{REMOTE_ADDR},
      HTTP_STATUS     => ($status || 200),
      HTTP_METHOD     => $self->{request_method},
      ERROR_MSG       => $router->{error_msg} || q{}
    });
  }

  return {
    status       => $status,
    response     => $response,
    content_type => $content_type,
  };
}

#**********************************************************
=head2 add_credentials()

=cut
#**********************************************************
sub add_credentials {
  my $self = shift;
  my AXbills::Api::Router $router = shift;

  $router->add_credential('ADMIN', sub {
    shift;

    return 0 if ($self->{conf}->{API_IPS} && $ENV{REMOTE_ADDR} && !check_ip($ENV{REMOTE_ADDR}, $self->{conf}->{API_IPS}));

    my $API_KEY = $ENV{HTTP_KEY} || '-';

    return ::check_permissions('', '', '', { API_KEY => $API_KEY }) == 0;
  });

  $router->add_credential('ADMINSID', sub {
    shift;
    my $admin_sid = $self->{cookies}->{admin_sid} || '';

    return 0 if ($self->{conf}->{API_IPS} && $ENV{REMOTE_ADDR} && !check_ip($ENV{REMOTE_ADDR}, $self->{conf}->{API_IPS}));

    return ::check_permissions('', '', $admin_sid, {}) == 0;
  });

  $router->add_credential('USER', sub {
    #TODO check how does it work when user have G2FA
    my $request = shift;

    $main::admin->info($self->{conf}->{USERS_WEB_ADMIN_ID} ? $self->{conf}->{USERS_WEB_ADMIN_ID} : 3, {
      DOMAIN_ID => $request->{req_params}->{DOMAIN_ID} || 0,
      IP        => $ENV{REMOTE_ADDR},
      SHORT     => 1
    });

    my $SID = $ENV{HTTP_USERSID};
    $main::FORM{external_auth} = '';
    my ($uid) = ::auth_user('', '', $SID);

    $request->{path_params}{uid} = $uid;
    $request->{query_params}{REQUEST_USERSID} = $SID;

    return 0 if ref $uid ne '';

    return $uid != 0;
  });

  $router->add_credential('PUBLIC', sub {
    return 1;
  });

  if ($ENV{REMOTE_ADDR} && $self->{conf}->{BOT_APIS} && check_ip($ENV{REMOTE_ADDR}, $self->{conf}->{BOT_APIS})) {
    return 0 if (!$ENV{HTTP_USERBOT} || !$ENV{HTTP_USERID});

    if ($self->{conf}->{BOT_SECRET}) {
      return 0 if (!$ENV{HTTP_BOTSECRET});
      return 0 if ($self->{conf}->{BOT_SECRET} ne $ENV{HTTP_BOTSECRET});
    }

    my %bot_types = ();
    $bot_types{VIBER} = 5 if ($self->{conf}->{VIBER_TOKEN});
    $bot_types{TELEGRAM} = 6 if ($self->{conf}->{TELEGRAM_TOKEN});

    return 0 if (!scalar keys %bot_types);

    my $Bot_type = $bot_types{uc($ENV{HTTP_USERBOT})} || '--';
    my $Bot_user = $ENV{HTTP_USERID} || '--';

    $router->add_credential('USERBOT', sub {
      my $request = shift;

      $main::admin->info($self->{conf}->{USERS_WEB_ADMIN_ID} ? $self->{conf}->{USERS_WEB_ADMIN_ID} : 3, {
        DOMAIN_ID => $request->{req_params}->{DOMAIN_ID},
        IP        => $ENV{REMOTE_ADDR},
        SHORT     => 1
      });

      require Contacts;
      Contacts->import();
      my $Contacts = Contacts->new($self->{db}, $self->{admin}, $self->{conf});

      my $list = $Contacts->contacts_list({
        TYPE  => $Bot_type,
        VALUE => $Bot_user,
        UID   => '_SHOW',
      });

      if ($Contacts->{TOTAL} < 1) {
        return 0
      }
      else {
        $request->{path_params}{uid} = $list->[0]->{uid};
        return 1;
      }
    });

    $router->add_credential('USERBOT_UNREG', sub {
      my $request = shift;

      $request->{query_params}{BOT} = $Bot_type;
      $request->{query_params}{USER_ID} = $Bot_user;

      return 1;
    });
  }

  return 1;
}

1;
