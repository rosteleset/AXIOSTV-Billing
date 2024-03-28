package Iptv::Prosto_tv;

=head1 NAME

=head1 VERSION

  VERSION: 0.05
  Revision: 20200319

=head1 SYNOPSIS

=cut

#**********************************************************

use strict;
use warnings FATAL => 'all';

our $VERSION = 0.05;

use parent qw(dbcore);
use AXbills::Base qw(load_pmodule mk_unique_value in_array urlencode convert _bp);
use AXbills::Fetcher qw(web_request);
use Digest::SHA qw(hmac_sha256_hex);
use AXbills::Misc;
my $MODULE = 'Prosto_tv';

my ($admin, $CONF, $db);
my $json;
my AXbills::HTML $html;
my $lang;

#**********************************************************
# Init
#**********************************************************
sub new {
  my $class = shift;
  $db = shift;
  $admin = shift;
  $CONF = shift;
  my $attr = shift;

  $admin->{MODULE} = $MODULE;

  if ($attr->{HTML}) {
    $html = $attr->{HTML};
  }

  if ($attr->{LANG}) {
    $lang = $attr->{LANG};
  }

  my $self = {};
  bless($self, $class);

  load_pmodule('JSON');

  $json = JSON->new->allow_nonref;
  $self->{SERVICE_NAME} = $MODULE;
  $self->{VERSION} = $VERSION;
  $self->{db} = $db;

  $self->{public_key} = $attr->{LOGIN} || q{};
  $self->{private_key} = $attr->{PASSWORD} || q{};
  $self->{URL} = $attr->{URL} || '';
  $self->{debug} = $attr->{DEBUG} || 0;
  $self->{DEBUG_FILE} = $attr->{DEBUG_FILE};
  $self->{request_count} = 0;

  if ($self->{debug} && $self->{debug} > 5) {
    print "Content-Type: text/html\n\n";
  }

  $self->{VERSION} = $VERSION;

  return $self;
}

#**********************************************************
=head2 test($attr) - Test service

=cut
#**********************************************************
sub test {
  my $self = shift;

  my $result = $self->_get_token();

  if (!$self->{errno} && ref $result eq 'HASH') {
    $result = 'Ok';
  }
  else {
    $self->{errno} = 1005;
    $result = 'Unknown Error';
  }

  return $result;
}

#**********************************************************
=head2 _send_request($attr)

=cut
#**********************************************************
sub _send_request {
  my $self = shift;
  my ($attr) = @_;

  my $request_url = $self->{URL} || '';
  my $debug = (defined($attr->{DEBUG})) ? $attr->{DEBUG} : $self->{debug};
  if ($self->{DEBUG_FILE} && $debug < 2) {
    $debug = 2;
  }

  if ($attr->{ACTION}) {
    $request_url .= $attr->{ACTION};
  }

  my $message = '';
  if ($attr->{PARAMS}) {
    foreach my $key (keys %{$attr->{PARAMS}}) {
      my $key_p = "\\\"$key\\\"";
      $attr->{PARAMS}->{$key} ||= $attr->{PARAMS}->{lc $key} || '';
      my $value = "\\\"$attr->{PARAMS}->{$key}\\\"";

      if ($message ne '') {
        $message .= ',' . $key_p . ': ' . $value;
      }
      else {
        $message = $key_p . ': ' . ($value || q{});
      }
    }
  }

  my @params = ();

  push @params, "Authorization: " . $attr->{TOKEN} if $attr->{TOKEN};
  push @params, 'Content-Type: application/json';

  my $result = '';
  if ($attr->{POST}) {
    $result = web_request($request_url, {
      DEBUG        => 4,
      HEADERS      => \@params,
      POST         => ('{' . $message . '}' || '""'),
      DEBUG        => $debug,
      DEBUG2FILE   => $self->{DEBUG_FILE},
      CURL_OPTIONS => "-X POST",
      CURL         => 1,
    });
  }
  elsif ($attr->{PUT}) {
    $result = web_request($request_url, {
      DEBUG        => 4,
      HEADERS      => \@params,
      POST         => ('{' . $message . '}' || '""'),
      DEBUG        => $debug,
      DEBUG2FILE   => $self->{DEBUG_FILE},
      CURL_OPTIONS => "-X PUT",
      CURL         => 1,
    });
  }
  else {
    $result = web_request($request_url, {
      DEBUG        => 4,
      HEADERS      => \@params,
      DEBUG        => $debug,
      DEBUG2FILE   => $self->{DEBUG_FILE},
      CURL_OPTIONS => ($attr->{COMMAND}) ? "-X $attr->{COMMAND}" : undef,
      CURL         => 1,
    });
  }

  my $perl_scalar;
  if ($result =~ /\{/) {
    $perl_scalar = $json->decode($result);
  }
  else {
    $perl_scalar->{errno} = 10;
    $perl_scalar->{err_str} = $result;
    $self->{errno} = 100;
    $self->{error} = 100;
    $self->{errstr} = $result;
  }

  return $perl_scalar;
}

#**********************************************************
=head2 user_info($attr)

   Arguments:
     $attr
       ID

   Results:

=cut
#**********************************************************
sub user_info {
  my $self = shift;
  my ($attr) = @_;

  my $token = $self->_get_token({ RETURN_STR => 1 });

  return $self unless $attr->{SUBSCRIBE_ID};

  my $result = $self->_send_request({
    ACTION => '/objects/' . $attr->{SUBSCRIBE_ID},
    GET    => 'true',
    TOKEN  => $token
  });

  $result->{TOKEN} = $token;
  # $self->{RESULT}->{results} = [ $result ];

  return $result;
}

#**********************************************************
=head2 user_add($attr)

   Arguments:
     $attr
       ID
       TP_ID,
       FILTER_ID
       TP_FILTER_ID

   Results:

=cut
#**********************************************************
sub user_add {
  my $self = shift;
  my ($attr) = @_;

  my $result;

  if (!$attr->{TP_ID}) {
    $self->{errno} = '10100';
    $self->{errstr} = 'ERR_SELECT_TP';
    return $self;
  }

  if (!$attr->{SERVICE_MODULE}) {
    $self->{errno} = '10101';
    $self->{errstr} = 'Error select Service';
    return $self;
  }

  $attr->{FILTER_ID} ||= $attr->{TP_FILTER_ID};

  if (!$attr->{FILTER_ID}) {
    $self->{errno} = '10102';
    $self->{errstr} = 'Error filter id';
    return $self;
  }

  return $self if $attr->{SUBSCRIBE_ID} && $self->_user_activate({ SUBSCRIBE_ID => $attr->{SUBSCRIBE_ID} });

  my $token = $self->_get_token({ RETURN_STR => 1 });

  $result = $self->_send_request({
    ACTION => '/objects',
    POST   => 'true',
    PARAMS => {
      first_name => $attr->{FIO},
      phone      => $attr->{PHONE}
    },
    TOKEN  => $token
  });

  $self->{SUBSCRIBE_ID} = $result->{id};

  if (!$self->{SUBSCRIBE_ID}) {
    $self->{errno} = '10103';
    $self->{errstr} = 'Error. Add user.';
    return $self;
  }

  $attr->{DEPOSIT} = sprintf("%.2f", $attr->{DEPOSIT});
  $self->_set_balance({
    ID      => $self->{SUBSCRIBE_ID},
    TOKEN   => $token,
    DEPOSIT => $attr->{DEPOSIT}
  }) if $attr->{DEPOSIT} && $attr->{DEPOSIT} > 0;

  $self->_change_password({
    ID       => $self->{SUBSCRIBE_ID},
    TOKEN    => $token,
    PASSWORD => $attr->{PASSWORD}
  });

  if ($self->{SUBSCRIBE_ID}) {
    $result = $self->_set_service({
      ID         => $self->{SUBSCRIBE_ID},
      SERVICE_ID => $attr->{FILTER_ID},
      TOKEN      => $token
    });

    if ($result && ref $result eq "HASH" && $result->{code} && $result->{message}) {
      $self->user_del({ SUBSCRIBE_ID => $self->{SUBSCRIBE_ID} });
      $self->{errno} = $result->{code};
      $self->{errstr} = $result->{message};
      return $self;
    }
  }

  return $self;
}

#**********************************************************
=head2 user_change($attr)

   Arguments:
     $attr
       ID
       TP_ID,
       FILTER_ID
       TP_FILTER_ID

   Results:

=cut
#**********************************************************
sub user_change {
  my $self = shift;
  my ($attr) = @_;

  if ($attr->{STATUS} eq '5' || $attr->{STATUS} eq '1') {
    $self->_change_status({
      ID     => $attr->{SUBSCRIBE_ID},
      STATUS => 1,
      TOKEN  => $self->_get_token({
        RETURN_STR => 1
      })
    });

    return $self;
  }

  $attr->{DEPOSIT} = sprintf("%.2f", $attr->{DEPOSIT});
  $self->_set_balance({
    ID      => $self->{SUBSCRIBE_ID},
    TOKEN   => $self->_get_token({
      RETURN_STR => 1
    }),
    DEPOSIT => $attr->{DEPOSIT}
  }) if $attr->{DEPOSIT} && $attr->{DEPOSIT} > 0;

  return $self;
}

#**********************************************************
=head2 user_del($attr)

   Arguments:
     $attr
       SUBCRIBE_ID

   Results:

=cut
#**********************************************************
sub user_del {
  my $self = shift;
  my ($attr) = @_;

  return $self unless $attr->{SUBSCRIBE_ID};
  my $token = $self->_get_token({ RETURN_STR => 1 });

  $self->_send_request({
    ACTION  => '/objects/' . $attr->{SUBSCRIBE_ID},
    COMMAND => 'DELETE',
    TOKEN   => $token
  });

  return $self;
}

#**********************************************************
=head2 change_channels($attr)

  Arguments:
    ID
    IDS
    FILTER_ID

  Results:
    TRUE or FALSE

=cut
#**********************************************************
sub change_channels {
  my $self = shift;
  my ($attr) = @_;

  my $Iptv = Iptv->new($self->{db}, $self->{admin}, $CONF);
  my $user_info = $self->user_info($attr);
  my @channels;

  if ($attr->{IDS}) {
    for my $channel (split(/,/, $attr->{IDS})) {
      my $channel_info = $Iptv->channel_info({
        ID => $channel,
      });
      if ($channel_info->{FILTER_ID} && !in_array($channel_info->{FILTER_ID}, \@channels)) {
        push @channels, $channel_info->{FILTER_ID};
      }
    }
  }

  foreach my $channel (@channels) {
    $self->_set_service({
      ID         => $attr->{SUBSCRIBE_ID},
      SERVICE_ID => $channel,
      TOKEN      => $user_info->{TOKEN}
    });
  }

  my @current_bundles;
  map $_->{main} ? () : push(@current_bundles, $_->{id}), @{$user_info->{services}};

  $self->_remove_bundles({
    CURRENT_SERVICES => \@current_bundles,
    SERVICES         => \@channels,
    ID               => $attr->{SUBSCRIBE_ID},
    TOKEN            => $user_info->{TOKEN}
  });

  return $self;
}

#**********************************************************
=head2 _get_token($attr)

   Arguments:
     $self
       public_key
       private_key

   Results:
      TOKEN

=cut
#**********************************************************
sub _get_token {
  my $self = shift;
  my ($attr) = @_;

  my $result = $self->_send_request({
    ACTION => '/tokens',
    POST   => 'true',
    PARAMS => {
      login    => $self->{public_key} || '',
      password => $self->{private_key} || '',
    },
  });

  return $result->{token} ? $result->{token} : '' if $attr->{RETURN_STR};

  return $result;
}

#**********************************************************
=head2 _set_balance($attr)

   Arguments:
     $self
       ID,
       DEPOSIT,
       TOKEN

   Results:
    result

=cut
#**********************************************************
sub _set_balance {
  my $self = shift;
  my ($attr) = @_;

  my $result = $self->_send_request({
    ACTION => '/objects/' . $attr->{ID} . '/operations',
    POST   => 'true',
    PARAMS => {
      operation_id => 42,
      sum          => $attr->{DEPOSIT} || '0',
    },
    TOKEN  => $attr->{TOKEN}
  });

  return $result;
}

#**********************************************************
=head2 _change_password($attr)

   Arguments:
     $self
       ID,
       PASSWORD,
       TOKEN

   Results:
    result

=cut
#**********************************************************
sub _change_password {
  my $self = shift;
  my ($attr) = @_;

  my $result = $self->_send_request({
    ACTION => '/objects/' . $attr->{ID} . '/password',
    PUT    => 'true',
    PARAMS => {
      password => $attr->{PASSWORD} || '',
    },
    TOKEN  => $attr->{TOKEN}
  });

  return $result;
}

#**********************************************************
=head2 _set_service($attr)

   Arguments:
     $self
       ID,
       SERVICE_ID,
       TOKEN

   Results:
     $result

=cut
#**********************************************************
sub _set_service {
  my $self = shift;
  my ($attr) = @_;

  my $result = $self->_send_request({
    ACTION => '/objects/' . $attr->{ID} . '/services',
    POST   => 'true',
    PARAMS => {
      id => $attr->{SERVICE_ID},
    },
    TOKEN  => $attr->{TOKEN}
  });

  return $result;
}

#**********************************************************
=head2 _remove_bundles($attr)

   Arguments:
     $self
       CURRENT_SERVICES,
       SERVICES,
       ID,
       TOKEN

   Results:
     $result

=cut
#**********************************************************
sub _remove_bundles {
  my $self = shift;
  my ($attr) = @_;

  foreach my $service (@{$attr->{CURRENT_SERVICES}}) {
    next if (in_array($service, $attr->{SERVICES}));

    $self->_send_request({
      ACTION => '/objects/' . $attr->{ID} . '/services',
      POST   => 'true',
      PARAMS => {
        id           => $service,
        auto_renewal => 0
      },
      TOKEN  => $attr->{TOKEN}
    });
  }

  return $self;
}

#**********************************************************
=head2 _change_status($attr)

   Arguments:
     $self
       ID,
       STATUS (0 - active, 1 - disconnected),
       TOKEN

   Results:
     $result

=cut
#**********************************************************
sub _change_status {
  my $self = shift;
  my ($attr) = @_;

  $attr->{STATUS} = $attr->{STATUS} ? 'disconnected' : 'active';

  return $self->_send_request({
    ACTION => '/objects/' . $attr->{ID} . '/status',
    POST   => 'true',
    PARAMS => {
      status => $attr->{STATUS},
    },
    TOKEN  => $attr->{TOKEN}
  });
}

#**********************************************************
=head2 _user_activate($attr)

   Arguments:
     $self
       SUBSCRIBE_ID

   Results:
     1 - true, 0 - false

=cut
#**********************************************************
sub _user_activate {
  my $self = shift;
  my ($attr) = @_;

  my $user_info = $self->user_info($attr);
  if ($user_info->{id}) {
    $self->_change_status({
      ID     => $user_info->{id},
      STATUS => 0,
      TOKEN  => $user_info->{TOKEN}
    });
  }

  return $user_info->{id} ? 1 : 0;
}

#**********************************************************
=head2 user_negdeposit($attr)

  Arguments:
    $attr
      UID

  Results:

=cut
#**********************************************************
sub user_negdeposit {
  my $self = shift;
  my ($attr) = @_;

  $self->_change_status({
    ID     => $attr->{SUBSCRIBE_ID},
    STATUS => 1,
    TOKEN  => $self->_get_token({
      RETURN_STR => 1
    })
  });

  return $self;
}

#**********************************************************
=head2 tp_export()

=cut
#**********************************************************
sub tp_export {
  my $self = shift;

  my $Iptv = Iptv->new($self->{db}, $self->{admin}, $CONF);
  my $extra_params = $Iptv->extra_params_info({ SERVICE_ID => $self->{SERVICE_ID} });

  return() unless $extra_params->{PIN};

  my $result = $self->_send_request({
    ACTION => '/objects/' . $extra_params->{PIN},
    GET    => 1,
    TOKEN  => $self->_get_token({ RETURN_STR => 1 })
  });

  return() unless ref $result eq "HASH" || $result->{bundles};
  $self->{TP_LIST} = 1;
  my @tps = ();

  foreach my $tp (@{$result->{bundles}}) {
    next unless $tp->{main};

    push @tps, {
      ID        => $tp->{id},
      NAME      => $tp->{name_ru},
      FILTER_ID => $tp->{id}
    };
  }

  return \@tps;
}

#**********************************************************
=head2 additional_functions()

=cut
#**********************************************************
sub additional_functions {
  my $self = shift;
  my ($attr) = @_;

  return() if $attr->{sid};

  if ($attr->{SUBSCRIBE_ID}) {
    my $button = $html->button($lang->{GET_LOGIN_AND_PASSWD},
      "get_index=iptv_user&header=2&chg=$attr->{chg}&UID=$attr->{UID}&additional_functions=1", {
        class         => 'btn btn-sm btn-default',
        LOAD_TO_MODAL => 1,
      });

    print $button;
    return 1;
  }

  use Users;
  my $Users = Users->new($self->{db}, $self->{admin}, $CONF);
  my $Iptv = Iptv->new($self->{db}, $self->{admin}, $CONF);

  my $user_info = $Iptv->user_info($attr->{chg});
  return '' if !$Iptv->{TOTAL} || !$user_info->{SUBSCRIBE_ID};

  my $user = $Users->info($user_info->{UID}, { SHOW_PASSWORD => 1 });
  return '' unless $Users->{TOTAL};

  my $token = $self->_get_login_token({
    SUBSCRIBE_ID => $user_info->{SUBSCRIBE_ID}
  });

  my $message = "$lang->{LOGIN}: $user_info->{SUBSCRIBE_ID}\n$lang->{PASSWD}: $user->{PASSWORD}";
  $message .= "\nToken: " . $token->{token} if $token->{token};

  $html->message('info', $lang->{INFO}, $message);

  return();
}

#**********************************************************
=head2 additional_info($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub additional_info {
  my $self = shift;
  my ($attr) = @_;

  if ($attr->{del_device}) {
    my $result = $self->_del_device($attr);
    if ($result->{status} && $result->{status} ne 'ok') {
      $html->message('err', $lang->{ERROR}, "$lang->{DEVICE}: $attr->{del_device}");
    }
    else {
      $html->message('info', $lang->{DELETED}, "$lang->{DEVICE}: $attr->{del_device}");
    }
  }
  elsif ($attr->{del_playlist}) {
    my $result = $self->_del_playlist($attr);
    if (ref $result eq "HASH" && $result->{code}) {
      $html->message('err', $lang->{ERROR}, "$lang->{PROCESSING_ERROR}");
    }
    else {
      $html->message('info', $lang->{DELETED}, "$lang->{PLAYLISTS}: $attr->{del_playlist}");
    }
  }
  elsif ($attr->{add_new_playlist}) {
    my $result = $self->_add_playlist($attr);
    if ($result->{code}) {
      $html->message('err', $lang->{ERROR}, "$lang->{PROCESSING_ERROR}");
    }
    else {
      $html->message('info', $lang->{INFO}, "$lang->{ADDED}: $lang->{PLAYLISTS}");
    }
  }

  my $user_info = $self->user_info($attr);

  my $result;
  push @{$result->{TABLES}}, _get_devices_table({ %{$attr}, %{$user_info} });
  push @{$result->{TABLES}}, _get_playlists_table({ %{$attr}, %{$user_info} });

  return $result;
}

#**********************************************************
=head2 _get_devices_table($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub _get_devices_table {
  my ($attr) = @_;

  return() if !$attr->{devices} || ref $attr->{devices} ne 'ARRAY' || !$attr->{devices}[0];

  my $table = $html->table({
    width   => '100%',
    caption => $lang->{DEVICE},
    title   => [ "ID", $lang->{DEVICE}, $lang->{PASSWD}, $lang->{CREATED}, $lang->{UPDATED}, $lang->{COMMENT}, "" ],
    ID      => 'DEVICES_PROSTO'
  });

  foreach (@{$attr->{devices}}) {
    my $del_btn = $html->button($lang->{DEL}, $attr->{URL} . "&del_device=$_->{id}", {
      class => 'del',
    });
    $table->addrow($_->{id}, $_->{device}, $_->{password}, $_->{created}, $_->{updated}, $_->{comment}, $del_btn);
  }

  return $table;
}

#**********************************************************
=head2 _del_device($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub _del_device {
  my $self = shift;
  my ($attr) = @_;

  return $self unless $attr->{SUBSCRIBE_ID};
  my $token = $self->_get_token({ RETURN_STR => 1 });

  my $result = $self->_send_request({
    ACTION  => '/objects/' . $attr->{SUBSCRIBE_ID} . '/devices/' . $attr->{del_device},
    COMMAND => 'DELETE',
    TOKEN   => $token
  });

  return $result;
}

#**********************************************************
=head2 _get_devices_table($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub _get_playlists_table {
  my ($attr) = @_;

  my $table = $html->table({
    width   => '100%',
    caption => $lang->{PLAYLISTS},
    title   => [ "ID", $lang->{CREATED}, $lang->{DESCRIBE}, '', '' ],
    ID      => 'PLAYLISTS_PROSTO',
    header  => [ "$lang->{CREATE_PLAYLIST}:$attr->{URL}&add_new_playlist=1" ],
  });

  return $table if !$attr->{playlists} || ref $attr->{playlists} ne 'ARRAY';

  foreach (@{$attr->{playlists}}) {
    my $dwn_btn = $html->button($lang->{DOWNLOAD} . " M3U", '', {
      GLOBAL_URL => $_->{url} || "",
      target     => '_new',
      class      => 'btn btn-default btn-sm',
    });
    my $del_btn = $html->button($lang->{DEL}, $attr->{URL} . "&del_playlist=$_->{id}", {
      class => 'del',
    });
    $table->addrow($_->{id}, $_->{created}, $_->{comment}, $dwn_btn, $del_btn);
  }

  return $table;
}

#**********************************************************
=head2 del_playlist($attr)

=cut
#**********************************************************
sub _del_playlist {
  my $self = shift;
  my ($attr) = @_;

  my $result = $self->_send_request({
    ACTION  => '/objects/' . $attr->{SUBSCRIBE_ID} . '/playlists/' . $attr->{del_playlist},
    COMMAND => 'DELETE',
    TOKEN   => $self->_get_token({ RETURN_STR => 1 })
  });

  return $result;
}

#**********************************************************
=head2 add_playlist($attr)

=cut
#**********************************************************
sub _add_playlist {
  my $self = shift;
  my ($attr) = @_;

  return { status => 'not ok' } if !$attr->{SUBSCRIBE_ID};

  my $result = $self->_send_request({
    ACTION => '/objects/' . $attr->{SUBSCRIBE_ID} . '/playlists',
    POST   => 'true',
    TOKEN  => $self->_get_token({ RETURN_STR => 1 })
  });

  return { status => 'ok' } if $result->{id};

  return $result;
}

#**********************************************************
=head2 _get_login_token($attr)

=cut
#**********************************************************
sub _get_login_token {
  my $self = shift;
  my ($attr) = @_;

  return { status => 'not ok' } if !$attr->{SUBSCRIBE_ID};

  my $result = $self->_send_request({
    ACTION => '/objects/' . $attr->{SUBSCRIBE_ID} . '/token',
    POST   => 'true',
    TOKEN  => $self->_get_token({ RETURN_STR => 1 })
  });

  return $result;
}

sub user_params {}

1;