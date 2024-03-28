package Iptv::24tv;

=head1 NAME

=head1 VERSION

  VERSION: 0.04
  Revision: 20191202

=head1 SYNOPSIS

=cut

#**********************************************************

use strict;
use warnings FATAL => 'all';

our $VERSION = 0.04;

use parent qw(dbcore);
use AXbills::Base qw(load_pmodule mk_unique_value in_array urlencode convert _bp);
use AXbills::Fetcher qw(web_request);
use Digest::SHA qw(hmac_sha256_hex);
my $MODULE = '24tv';

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

  my $result = $self->_send_request({
    ACTION => '/users?token=' . ($CONF->{TV24_TOKEN} || ""),
  });

  if (!$self->{errno} && ref $result eq 'ARRAY') {
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

  my $request_proto = 'https://';
  if ($self->{URL}) {
    if ($self->{URL} =~ s/https:\/\///) {
      $request_proto = "https://";
    }
  }
  my $debug = (defined($attr->{DEBUG})) ? $attr->{DEBUG} : $self->{debug};
  if ($self->{DEBUG_FILE} && $debug < 2) {
    $debug = 2;
  }

  my $request_url = $self->{URL} || '';

  if ($attr->{ACTION}) {
    $request_url .= $attr->{ACTION};
  }

  my $message = ();
  if ($attr->{PARAMS}) {
    foreach my $key (keys %{$attr->{PARAMS}}) {
      my $key_p = "\\\"$key\\\"";
      my $value = "\\\"$attr->{PARAMS}->{$key}\\\"";
      $message .= ',' . $key_p . ': ' . $value if $message;
      $message .= $key_p . ': ' . $value if !$message;
      if ($attr->{SUBSCRIBE_M}) {
        $message = "[{ \\\"packet_id\\\":" . $attr->{PARAMS}{packet_id} . ", \\\"renew\\\":true }]";
      }
    }
  }

  my @params = ();
  $params[0] = 'Content-Type: application/json';

  my $result = '';
  if ($attr->{COMMAND}) {
    $result = web_request($request_url, {
      HEADERS      => \@params,
      POST         => $attr->{SUBSCRIBE_M} ? $message : "{" . ($message || "") . "}" || '""',
      DEBUG        => $debug,
      DEBUG2FILE   => $self->{DEBUG_FILE},
      CURL_OPTIONS => ($attr->{COMMAND}) ? "-X $attr->{COMMAND}" : undef,
      CURL         => 1,
    });
  }
  else {
    $result = web_request($request_url, {
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
     $self->
       {RESULT}

=cut
#**********************************************************
sub user_info {
  my $self = shift;
  my ($attr) = @_;

  my $uid = $attr->{SUBSCRIBE_ID} || $attr->{ext_id} || 0;
  my $result = $self->_send_request({
    ACTION => '/users/' . $uid . '?token=' . ($CONF->{TV24_TOKEN} || ''),
  });

  $self->get_sub({
    UID => $uid,
  });

  $self->{RESULT} = $result;

  return $self;
}

#**********************************************************
=head2 user_add($attr) - add user

=cut
#**********************************************************
sub user_add {
  my $self = shift;
  my ($attr) = @_;

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

  my $result = $self->_send_request({
    ACTION => '/users?provider_uid=' . ($attr->{UID} || 0) . '&token=' . ($CONF->{TV24_TOKEN} || ''),
  });

  if (ref($result) eq 'ARRAY' && $result->[0]{id}) {
    $attr->{SUBSCRIBE_ID} = $result->[0]{id};
    $attr->{DEL_BASE_SUBS} = 1;
    return $self->user_change($attr);
  }

  $result = $self->_send_request({
    ACTION  => '/users?token=' . ($CONF->{TV24_TOKEN} || ''),
    COMMAND => 'POST',
    PARAMS  => {
      %{_get_params($attr)},
    },
  });

  if ($result->{error}) {
    $self->{errno} = $result->{status_code} || 400;
    $self->{errstr} = $result->{error}{message};
    return $self;
  }

  if ($self->{errstr} && $self->{errstr} eq "[]") {
    delete $self->{errstr};
    delete $self->{error};
    delete $result->{error};
  }
  else {
    delete $self->{error};
    delete $result->{error};
  }

  my $id = $result->{id};
  $self->{SUBSCRIBE_ID} = $id;

  $self->user_sub({
    UID => $id,
    TP  => $attr->{TP_FILTER_ID},
  }) if defined($attr->{STATUS}) && !$attr->{STATUS};

  delete $self->{errno};
  delete $self->{errstr};

  $self->user_delete_sub({
    UID => $id,
    TP  => $attr->{TP_FILTER_ID},
  }) if $attr->{STATUS};

  return $result;
}

#**********************************************************
=head2 user_del($attr)

   Arguments:
     $attr
       ID

   Results:
     $self->
       {RESULT}

=cut
#**********************************************************
sub user_del {
  my $self = shift;
  my ($attr) = @_;

  my $result = user_info($self, {
    ext_id => $attr->{SUBSCRIBE_ID} || 0,
  });

  if (ref($result->{RESULT}) eq 'HASH' && $result->{RESULT}{id}) {
    $self->user_delete_sub({
      UID => $attr->{SUBSCRIBE_ID},
      TP  => $attr->{TP_FILTER_ID},
    });

    $self->user_delete_add_subs({
      UID => $attr->{SUBSCRIBE_ID},
    });

    $result = $self->_send_request({
      ACTION  => '/users/' . ($attr->{SUBSCRIBE_ID} || 0) . '?token=' . ($CONF->{TV24_TOKEN} || ''),
      COMMAND => "DELETE",
    });
  }

  $self->{RESULT} = $result;

  if ($self->{errstr} && $self->{errstr} eq "[]") {
    delete $self->{errstr};
    delete $self->{error};
  }
  else {
    delete $self->{error};
  }

  return $self;
}

#**********************************************************
=head2 user_change($attr)

   Arguments:
     $attr
       ID

   Results:
     $self->
       {RESULT}

=cut
#**********************************************************
sub user_change {
  my $self = shift;
  my ($attr) = @_;

  my $result = user_info($self, {
    ext_id => $attr->{SUBSCRIBE_ID} || 0,
  });

  if (ref($result->{RESULT}) eq 'HASH' && $result->{RESULT}{error}) {
    $attr->{errno} = $result->{RESULT}{status_code} || 400;
    $attr->{errstr} = $result->{RESULT}{error}{message};

    $result = $self->_send_request({
      ACTION => '/users?provider_uid=' . ($attr->{UID} || 0) . '&token=' . ($CONF->{TV24_TOKEN} || ''),
    });

    if (ref($result) eq 'ARRAY' && $result->[0]{id}) {
      $attr->{SUBSCRIBE_ID} = $result->[0]{id};
    }
    else {
      $self->{errno} = $attr->{errno};
      $self->{errstr} = $attr->{errstr};

      return $self;
    }
  }

  $result = $self->_send_request({
    ACTION  => '/users/' . ($attr->{SUBSCRIBE_ID} || 0) . '?token=' . ($CONF->{TV24_TOKEN} || ''),
    COMMAND => 'PATCH',
    PARAMS  => {
      %{_get_params($attr)},
    },
  });

  $self->{SUBSCRIBE_ID} = $result->{id} ? $result->{id} : 0;

  if (ref($result) eq 'HASH' && $result->{error}) {
    $self->{errno} = $result->{status_code} || 400;
    $self->{errstr} = $result->{error}{message};
    return $self;
  }

  if ($attr->{STATUS} && $attr->{STATUS} == 3) {
    return $self->user_sub_pause({
      UID => $self->{SUBSCRIBE_ID},
      TP  => $attr->{TP_FILTER_ID},
    });
  }

  if ($attr->{DEL_BASE_SUBS} || ($attr->{TP_INFO_OLD} && ref $attr->{TP_INFO_OLD} eq "HASH")) {
    $self->user_delete_base_subs({
      UID => $self->{SUBSCRIBE_ID},
    });
  }

  $self->user_sub({
    UID => $self->{SUBSCRIBE_ID},
    TP  => $attr->{TP_FILTER_ID},
  }) if (defined($attr->{STATUS}) && !$attr->{STATUS}) || $attr->{BUNDLE_TYPE};

  $self->user_sub_pause_del({
    UID => $self->{SUBSCRIBE_ID},
    TP  => $attr->{TP_FILTER_ID},
  }) if (defined($attr->{STATUS}) && !$attr->{STATUS} && ($self->{RESULT} eq "HASH") && $self->{RESULT}{error}) || $attr->{BUNDLE_TYPE};

  $self->user_delete_sub({
    UID => $self->{SUBSCRIBE_ID},
    TP  => $attr->{TP_FILTER_ID},
  }) if $attr->{STATUS} && !$attr->{BUNDLE_TYPE};

  $self->{RESULT} = $result;

  if ($self->{errstr} && $self->{errstr} eq "[]") {
    delete $self->{errstr};
    delete $self->{error};
    delete $self->{errno};
  }
  else {
    delete $self->{error};
    delete $self->{errno};
  }

  return $self;
}

#**********************************************************
=head2 _get_params($attr)

   Arguments:
     $attr

   Results:
     $params

=cut
#**********************************************************
sub _get_params {
  my ($attr) = @_;

  my $params = ();
  if ($attr->{FIO}) {
    $attr->{FIO} = length $attr->{FIO} > 30 ? substr($attr->{FIO}, 30) : $attr->{FIO};
  }

  $params->{provider_uid} = $attr->{UID} if $attr->{UID};
  $params->{username} = $attr->{PHONE} || $attr->{LOGIN};
  $params->{password} = $attr->{UID} if $attr->{PASSWORD};
  $params->{first_name} = $attr->{FIO} if $attr->{FIO};
  $params->{last_name} = $attr->{FIO2} if $attr->{FIO2};
  $params->{email} = $attr->{EMAIL} if $attr->{EMAIL};
  $params->{phone} = $attr->{PHONE} if $attr->{PHONE};
  $params->{parental_code} = $attr->{PIN} if $attr->{PIN};
  $params->{is_active} = defined($attr->{STATUS}) && !$attr->{STATUS} ? "true" : "false";

  return $params;
}

#**********************************************************
=head2 get_sub($attr)

   Arguments:
     $attr
       ID

   Results:
     $self->
       {RESULT}

=cut
#**********************************************************
sub get_sub {
  my $self = shift;
  my ($attr) = @_;

  my $result = '';

  if ($attr->{SUB_ID}) {
    $result = $self->_send_request({
      ACTION => '/users/' . $attr->{UID} . '/subscriptions/' . $attr->{SUB_ID} . '?types=current&token=' . ($CONF->{TV24_TOKEN} || ''),
    });
  }
  else {
    $result = $self->_send_request({
      ACTION => '/users/' . $attr->{UID} . '/subscriptions?types=current&token=' . ($CONF->{TV24_TOKEN} || ''),
    });
  }

  $self->{RESULT} = $result;

  return $result || $self;
}

#**********************************************************
=head2 user_sub($attr)

   Arguments:
     $attr
       ID

   Results:
     $self->
       {RESULT}

=cut
#**********************************************************
sub user_sub {
  my $self = shift;
  my ($attr) = @_;

  my $params = ();
  $params->{packet_id} = $attr->{TP} || "";
  $params->{start_at} = $attr->{START} if $attr->{START};
  $params->{renew} = "true";

  if ($attr->{DEL_BASE}) {
    $self->user_delete_base_subs({
      UID => $attr->{UID},
    });
  }

  my $result = $self->_send_request({
    ACTION      => '/users/' . $attr->{UID} . '/subscriptions?token=' . ($CONF->{TV24_TOKEN} || ''),
    COMMAND     => 'POST',
    PARAMS      => {
      %{$params},
    },
    SUBSCRIBE_M => 1,
  });

  return $result;
}

#**********************************************************
=head2 get_pauses($attr)

   Arguments:
     $attr
       ID

   Results:
     $self->
       {RESULT}

=cut
#**********************************************************
sub get_pauses {
  my $self = shift;
  my ($attr) = @_;

  my $result = $self->_send_request({
    ACTION => '/users/' . $attr->{UID} . '/subscriptions/' . ($attr->{SUB_ID} || "") . '/pauses?token=' . ($CONF->{TV24_TOKEN} || ''),
  });

  return $result || [];
}

#**********************************************************
=head2 user_delete_sub($attr)

   Arguments:
     $attr
       ID

   Results:
     $self->
       {RESULT}

=cut
#**********************************************************
sub user_delete_sub {
  my $self = shift;
  my ($attr) = @_;

  my $packets = $self->get_sub({
    UID => $attr->{UID},
  });

  if (ref($packets) eq "ARRAY") {
    foreach my $packet (@{$packets}) {
      if ($packet->{packet} && $packet->{packet}{id} && $packet->{packet}{id} eq $attr->{TP}) {
        $attr->{SUB_ID} = $packet->{id};
      }
    }
  }

  $attr->{SUB_ID} //= "";

  return $self if !$attr->{SUB_ID};

  my $result = $self->_send_request({
    ACTION  => '/users/' . $attr->{UID} . '/subscriptions/' . $attr->{SUB_ID} . '?token=' . ($CONF->{TV24_TOKEN} || ''),
    COMMAND => 'DELETE',
  });

  $self->{RESULT} = $result;

  return $self;
}

#**********************************************************
=head2 user_delete_base_subs($attr)

   Arguments:
     $attr
       ID

   Results:
     $self->
       {RESULT}

=cut
#**********************************************************
sub user_delete_base_subs {
  my $self = shift;
  my ($attr) = @_;

  my $packets = $self->get_sub({
    UID => $attr->{UID},
  });

  if (ref($packets) eq "ARRAY") {
    foreach my $packet (@{$packets}) {
      $self->_send_request({
        ACTION  => '/users/' . $attr->{UID} . '/subscriptions/' . $packet->{id} . '?token=' . ($CONF->{TV24_TOKEN} || ''),
        COMMAND => 'DELETE',
      }) if ($packet->{packet} && $packet->{packet}{base});
    }
  }

  return $self;
}

#**********************************************************
=head2 user_delete_add_subs($attr)

   Arguments:
     $attr
       ID

   Results:
     $self->
       {RESULT}

=cut
#**********************************************************
sub user_delete_add_subs {
  my $self = shift;
  my ($attr) = @_;

  my $packets = $self->get_sub({
    UID => $attr->{UID},
  });

  if (ref($packets) eq "ARRAY") {
    foreach my $packet (@{$packets}) {
      $self->_send_request({
        ACTION  => '/users/' . $attr->{UID} . '/subscriptions/' . $packet->{id} . '?token=' . ($CONF->{TV24_TOKEN} || ''),
        COMMAND => 'DELETE',
      }) if ($packet->{packet} && !$packet->{packet}{base});
    }
  }

  return $self;
}

#**********************************************************
=head2 user_sub_pause($attr)

   Arguments:
     $attr
       ID

   Results:
     $self->
       {RESULT}

=cut
#**********************************************************
sub user_sub_pause {
  my $self = shift;
  my ($attr) = @_;

  my $packet = $self->user_get_sub_by_id($attr);

  if (!$packet->{packet}) {
    $self->{errno} = 401;
    $self->{errstr} = "User is not subscribed to this tariff.";
    return $self;
  }

  my $result = $self->_send_request({
    ACTION  => '/users/' . $attr->{UID} . '/subscriptions/' . $packet->{packet}{id} . '/pauses?token=' . ($CONF->{TV24_TOKEN} || ''),
    COMMAND => 'POST',
    PARAMS  => {
      start_at => $packet->{packet}{start_at},
      end_at   => $packet->{packet}{end_at},
    }
  });

  $self->{RESULT} = $result;

  return $self;
}

#**********************************************************
=head2 user_sub_pause_del($attr)

   Arguments:
     $attr
       ID

   Results:
     $self->
       {RESULT}

=cut
#**********************************************************
sub user_sub_pause_del {
  my $self = shift;
  my ($attr) = @_;

  my $packet = $self->user_get_sub_by_id($attr);

  if (!$packet->{packet}) {
    $self->{errno} = 401;
    $self->{errstr} = "User is not subscribed to this tariff.";
    return $self;
  }

  if (!$packet->{packet}{pauses} && !$packet->{packet}{pauses}[0]{id}) {
    $self->{errno} = 401;
    $self->{errstr} = "Tariff is no paused.";
    return $self;
  }

  my $result = $self->_send_request({
    ACTION  => '/users/' . ($attr->{UID} || 0) . '/subscriptions/' . ($packet->{packet}{id}) . '/pauses/' . ($packet->{packet}{pauses}[0]{id} || 0) . '?token=' . ($CONF->{TV24_TOKEN} || ''),
    COMMAND => 'DELETE',
  });

  $self->{RESULT} = $result;

  return $self;
}

#**********************************************************

=head2 user_params($attr)

   Arguments:

   Results:

=cut
#**********************************************************
sub user_get_sub_by_id {
  my $self = shift;
  my ($attr) = @_;

  my $packets = $self->get_sub({
    UID => $attr->{UID},
  });

  if (ref($packets) eq "ARRAY") {
    foreach my $packet (@{$packets}) {
      if ($packet->{packet} && $packet->{packet}{id} && $packet->{packet}{id} eq $attr->{TP}) {
        return { packet => $packet };
      }
    }
  }

  return {};
}

#**********************************************************
=head2 user_params($attr)

   Arguments:

   Results:

=cut
#**********************************************************
sub user_params {}

#**********************************************************
=head2 change_channels($attr)

=cut
#**********************************************************
sub change_channels {
  my $self = shift;
  my ($attr) = @_;

  my $Iptv = Iptv->new($self->{db}, $admin, $CONF);

  $attr->{IDS} =~ s/\,/;/g;
  my $channels = $Iptv->channel_list({
    ID        => $attr->{IDS},
    PAGE_ROWS => 1000,
    COLS_NAME => 1
  });
  my %user_sub_channels = ();

  foreach my $channel (@{$channels}) {
    $user_sub_channels{$channel->{filter_id}} = $channel->{id};
  }

  my $user_channels = $self->get_sub({
    UID => $attr->{SUBSCRIBE_ID} || 0,
  });

  foreach my $user_channel (@{$user_channels}) {
    next if $user_channel->{packet}{base};
    if (!$user_sub_channels{$user_channel->{packet}{id}}){
      $self->user_delete_sub({
        UID => $attr->{SUBSCRIBE_ID},
        TP  => $user_channel->{packet}{id},
      })
    }
    else {
      delete $user_sub_channels{$user_channel->{packet}{id}};
    }
  }

  foreach my $key (keys %user_sub_channels) {
    my $result = $self->user_sub({
      UID => $attr->{SUBSCRIBE_ID} || 0,
      TP  => $key
    });

    if (ref($result) eq 'HASH' && $result->{error}) {
      $self->{errno} = $result->{status_code} || 400;
      $self->{errstr} = $result->{error}{message};
      return $self;
    }
  }

  return $self;
}

#**********************************************************
=head2 user_unsub($attr)

   Arguments:
     $attr
       ID

   Results:
     $self->
       {RESULT}

=cut
#**********************************************************
sub user_unsub {
  my $self = shift;
  my ($attr) = @_;

  my $result = $self->_send_request({
    ACTION  => '/users/' . $attr->{UID} . '/subscriptions/' . $attr->{SUB_ID} . '?token=' . ($CONF->{TV24_TOKEN} || ''),
    COMMAND => 'PATCH',
    PARAMS  => {
      renew => 'false'
    }
  });

  $self->{RESULT} = $result;

  return $self;
}

#**********************************************************
=head2 user_negdeposit($attr)

   Arguments:

   Results:

=cut
#**********************************************************
sub user_negdeposit {
  my $self = shift;
  my ($attr) = @_;

  $self->user_delete_base_subs({
    UID => $attr->{SUBSCRIBE_ID},
  });

  $self->user_delete_add_subs({
    UID => $attr->{SUBSCRIBE_ID},
  });

  my $Iptv = Iptv->new($self->{db}, $admin, $CONF);

  $Iptv->user_channels({
      ID    => $attr->{ID},
      TP_ID => $attr->{TP_ID},
      IDS   => 0
  });

  return $self;
}

1;