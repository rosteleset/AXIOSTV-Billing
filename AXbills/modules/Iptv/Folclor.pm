package Iptv::Folclor;

=head1 NAME

=cut
=head1 VERSION

  VERSION: 1.03
  REVISION: 20181115


  API:

=cut

#**********************************************************

use strict;
use warnings FATAL => 'all';

our $VERSION = 1.3;

use parent qw(dbcore);
use AXbills::Base qw(load_pmodule mk_unique_value in_array urlencode convert _bp);
use AXbills::Fetcher;
use Digest::SHA qw(hmac_sha256_hex);
use MIME::Base64;

my $MODULE = 'Folclor';

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
  $self->{URL} = $attr->{URL} || "";
  $self->{debug} = $attr->{DEBUG};
  $self->{DEBUG_FILE} = $attr->{DEBUG_FILE};
  $self->{request_count} = 0;

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
    ACTION => '/packets?includes=availables&token=' . $CONF->{FOLCLOR_API_KEY} || '',
  });

  if (!$self->{errno}) {
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
  my $public_key = $self->{public_key} || 'f77da74c6b626400382c7bf96ca7902b5a244610';
  my $private_key = $self->{private_key} || '0f87ffe97757ee3cbd1e22b81d7bfa6f71e1c587';

  my $debug = (defined($attr->{DEBUG})) ? $attr->{DEBUG} : $self->{debug};
  if ($self->{DEBUG_FILE} && $debug < 2) {
    $debug = 2;
  }

  if ($attr->{ACTION}) {
    $request_url .= $attr->{ACTION};
  }

  my $message = ();
  if ($attr->{PARAMS}) {
    foreach my $key (keys %{$attr->{PARAMS}}) {

      if ($message) {
        $message .= '&' . ($key || q{}) . '=' . $attr->{PARAMS}->{$key};
      }
      else {
        $message = $key . '=' . ($attr->{PARAMS}->{$key} || q{});
      }
    }
  }

  my $api_time = time();
  my $hmac_text = $api_time . $public_key . ($message || '');
  my $api_hash = hmac_sha256_hex($hmac_text, $private_key);
  my @params = ();
  if ($attr->{SUB}) {
    if ($attr->{PARAMS}{start_at}) {
      #      $message = qq([{ \\\"packet_id\\\":" . $attr->{PARAMS}{packet_id} . ", \\\"end_at\\\":\\"$attr->{PARAMS}{end_at}\\"" . ", \\\"renew\\\":true } ]);
      $message = "[{ \\\"packet_id\\\":" . $attr->{PARAMS}{packet_id} . ", \\\"start_at\\\":\\\"$attr->{PARAMS}{start_at}\\\"" . ", \\\"renew\\\":true } ]";
    }
    else {
      $message = "[{ \\\"packet_id\\\":" . $attr->{PARAMS}{packet_id} . ", \\\"renew\\\":true } ]";
    }

    $params[0] = 'Content-Type: application/json';
    $params[1] = 'Accept: application/json';
  }
  else {
    $params[0] = 'API_ID: ' . $public_key;
    $params[1] = 'API_TIME: ' . $api_time;
    $params[2] = 'API_HASH: ' . $api_hash;
  }

  #  if ($attr->{HEADER}) {
  #    my $params1 = '[';
  #    foreach my $key (keys %{$attr->{HEADER}}) {
  #      $params1 .= " {$key: $attr->{HEADER}->{$key}} ";
  #    }
  #    $params1 .= ']';
  #    $params[3] = $params1;
  #
  #    _bp('', \$params1, {HEADER=>1});
  #  }

  my $result = '';
  if ($attr->{POST} && !$attr->{COMMAND}) {
    $result = web_request($request_url,
      {
        DEBUG      => 4,
        HEADERS    => \@params,
        POST       => ($message || '""'),
        DEBUG      => $debug,
        DEBUG2FILE => $self->{DEBUG_FILE},
        CURL       => 1,
      }
    );
  }
  else {
    if ($attr->{COMMAND} && $attr->{COMMAND} eq "PATCH") {
      $result = web_request($request_url,
        {
          DEBUG        => 4,
          HEADERS      => \@params,
          DEBUG        => $debug,
          DEBUG2FILE   => $self->{DEBUG_FILE},
          CURL         => 1,
          CURL_OPTIONS => ($attr->{COMMAND}) ? "-X $attr->{COMMAND}" : undef,
          POST         => ($message || '""'),
        }
      );
    }
    else {
      $result = web_request($request_url,
        {
          DEBUG        => 4,
          HEADERS      => \@params,
          DEBUG        => $debug,
          DEBUG2FILE   => $self->{DEBUG_FILE},
          CURL         => 1,
          CURL_OPTIONS => ($attr->{COMMAND}) ? "-X $attr->{COMMAND}" : undef,
        }
      );
    }
  }

  my $perl_scalar;
  if ($result =~ /\{/) {
    $perl_scalar = $json->decode($result);
  }
  else {
    $perl_scalar->{errno} = 10;
    $perl_scalar->{err_str} = $result;
    #    $self->{errno} = 100;
    #    $self->{error} = 100;
    #    $self->{errstr} = $result;
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
       {RESULT}->{results}

=cut
#**********************************************************
sub user_info {
  my $self = shift;
  my ($attr) = @_;

  my $uid = $attr->{SUBSCRIBE_ID} || $attr->{ext_id} || 0;
  my $result = $self->_send_request({
    ACTION => '/users/' . $uid . '?token=' . $CONF->{FOLCLOR_API_KEY} || '',
  });

  $self->{RESULT}->{results} = $result;

  return $self;
}

#**********************************************************
=head2 user_add($attr)

   Arguments:
     $attr
       ID

   Results:
     $self->
       {RESULT}->{results}

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

  my $result = user_info($self, {
    ext_id => $attr->{SUBSCRIBE_ID} || 0,
  });

  if (ref($result->{RESULT}{results}) eq 'ARRAY') {
    my $id = $result->{RESULT}{results}{id};
    $result = get_sub($self, {
      uid => $id || 0,
    });

    if (ref($result->{RESULT}{results}[0]) ne "ARRAY" || $result->{RESULT}{results}[0][0]{packet}{id} ne ($attr->{TP_INFO}{FILTER_ID} || $attr->{TP_FILTER_ID})) {
      if ($attr->{IPTV_ACTIVATE}) {
        $result = user_sub($self, {
          uid   => $id || 0,
          tp    => $attr->{TP_INFO}{FILTER_ID} || 0,
          start => $attr->{IPTV_ACTIVATE} . "T00:00:00.413Z",
        });
      }
      else {
        $result = user_sub($self, {
          uid => $id || 0,
          tp  => $attr->{TP_INFO}{FILTER_ID} || 0,
        });
      }
    }

    $self->{SUBSCRIBE_ID} = $id;
    return $self;
  }
  else {
    $result = $self->_send_request({
      ACTION => '/users?token=' . $CONF->{FOLCLOR_API_KEY} || '',
      POST   => 'true',
      PARAMS => {
        provider_uid  => $attr->{UID} || '',
        username      => $attr->{LOGIN} || '',
        password      => $attr->{PASSWORD} || '',
        first_name    => $attr->{FIO} || '',
        last_name     => $attr->{FIO2} || '',
        email         => $attr->{EMAIL} || '',
        phone         => $attr->{PHONE} || '',
        parental_code => $attr->{PIN} || '',
      },
    });

    my $id = $result->{id};
    $result = user_info($self, {
      ext_id => $id || 0,
    });

    if ($attr->{IPTV_ACTIVATE}) {
      $result = user_sub($self, {
        uid   => $id || 0,
        tp    => $attr->{TP_INFO}{FILTER_ID} || 0,
        start => $attr->{IPTV_ACTIVATE} . "T08:00:00.413Z",
      });
    }
    else {
      $result = user_sub($self, {
        uid => $id || 0,
        tp  => $attr->{TP_INFO}{FILTER_ID} || 0,
      });
    }
    $self->{SUBSCRIBE_ID} = $id;
  }

  return $self;
}

#**********************************************************
=head2 user_change($attr)

  Arguments:
    $attr

  Results:

=cut
#**********************************************************
sub user_change {
  my $self = shift;
  my ($attr) = @_;

  my $result = user_info($self, {
    ext_id => $attr->{SUBSCRIBE_ID} || 0,
  });

  if (defined($result->{RESULT}{results}{id})) {
    my $id = $result->{RESULT}{results}{id};
    $result = get_sub($self, {
      uid => $id || 0,
    });

    if (ref($result->{RESULT}{results}[0]) ne "ARRAY" || $result->{RESULT}{results}[0][0]{packet}{id} ne ($attr->{TP_INFO}{FILTER_ID} || $attr->{TP_FILTER_ID})) {
      if ($attr->{IPTV_EXPIRE}) {
        $result = user_sub($self, {
          uid => $id || 0,
          tp  => $attr->{TP_INFO}{FILTER_ID} || 0,
          end => $attr->{IPTV_EXPIRE} . "T23:00:00.413Z",
        });
      }
      else {
        $result = user_sub($self, {
          uid => $id || 0,
          tp  => $attr->{TP_INFO}{FILTER_ID} || 0,
        });
      }
    }
    else {
      if ($attr->{STATUS} eq '3') {
        my $sub_id = $result->{RESULT}{results}[0][0]{id};
        $result = $self->_send_request({
          ACTION => '/users/' . $id . '/subscriptions/' . $sub_id . '/pauses?token=' . $CONF->{FOLCLOR_API_KEY} || '',
          POST   => 'true',
        });
      }

      if ($result->{RESULT}{results}[0][0]{pauses}[0]) {
        if ($attr->{STATUS} eq '0') {
          my $sub_id = $result->{RESULT}{results}[0][0]{id};
          my $pause_id = $result->{RESULT}{results}[0][0]{pauses}[0]{id};

          $result = $self->_send_request({
            ACTION  => '/users/' . $id . '/subscriptions/' . $sub_id . '/pauses/' . $pause_id . '?token=' . $CONF->{FOLCLOR_API_KEY} || '',
            COMMAND => 'DELETE',
          });
        }
      }
    }
    $result = $self->_send_request({
      ACTION  => '/users/' . $id . '?token=' . $CONF->{FOLCLOR_API_KEY} || '',
      COMMAND => 'PATCH',
      PARAMS  => {
        provider_uid  => $attr->{UID} || '',
        username      => $attr->{LOGIN} || '',
        password      => $attr->{PASSWORD} || '',
        first_name    => $attr->{FIO} || '',
        last_name     => $attr->{FIO2} || '',
        email         => $attr->{EMAIL} || '',
        phone         => $attr->{PHONE} || '',
        parental_code => $attr->{PIN} || '',
      },
      POST    => "true",
    });

  }
  else {
    $result = user_add($self, $attr);
  }

  return $self;
}

#**********************************************************
=head2 user_login($attr)

   Arguments:
     $attr
       ID

   Results:
     $self->
       {RESULT}->{results}

=cut
#**********************************************************
sub user_login {
  my $self = shift;
  my ($attr) = @_;

  my $result = $self->_send_request({
    ACTION => '/auth/login',
    POST   => 'true',
    PARAMS => {
      login    => 'alexandru.bogdan@inbox.ru',
      password => '123456789',
    },
  });

  $self->{RESULT}->{results} = [ $result ];

  return $self;

}

#**********************************************************
=head2 user_del($attr)

   Arguments:
     $attr
       ID

   Results:
     $self->
       {RESULT}->{results}

=cut
#**********************************************************
sub user_del {
  my $self = shift;
  my ($attr) = @_;

  my $result = user_info($self, {
    ext_id => $attr->{SUBSCRIBE_ID} || 0,
  });

  if (ref($result->{RESULT}{results}) eq 'ARRAY') {
    my $id = $result->{RESULT}{results}{id};
    $result = get_sub($self, {
      uid => $id || 0,
    });

    if (ref($result->{RESULT}{results}[0]) eq "ARRAY" && $result->{RESULT}{results}[0][0]{packet}{id} eq ($attr->{TP_INFO}{FILTER_ID} || $attr->{TP_FILTER_ID})) {
      my $sub_id = $result->{RESULT}{results}[0][0]{id};
      $result = $self->_send_request({
        ACTION  => '/users/' . $id . '/subscriptions/' . $sub_id . '?token=' . $CONF->{FOLCLOR_API_KEY} || '',
        COMMAND => 'DELETE',
      });
    }
  }

  $self->{RESULT}->{results} = [ $result ];

  return $self;
}

#**********************************************************
=head2 user_sub($attr)

   Arguments:
     $attr
       ID

   Results:
     $self->
       {RESULT}->{results}

=cut
#**********************************************************
sub user_sub {
  my $self = shift;
  my ($attr) = @_;
  
  my $result = '';
  if ($attr->{start}) {
    $result = $self->_send_request({
      ACTION => '/users/' . $attr->{uid} . '/subscriptions?token=' . $CONF->{FOLCLOR_API_KEY} || '',
      POST   => 'true',
      PARAMS => {
        packet_id => $attr->{tp} || '',
        start_at  => $attr->{start},
      },
      SUB    => 1,
    });
  }
  else {
    $result = $self->_send_request({
      ACTION => '/users/' . $attr->{uid} . '/subscriptions?token=' . $CONF->{FOLCLOR_API_KEY} || '',
      POST   => 'true',
      PARAMS => {
        packet_id => $attr->{tp} || '',
      },
      SUB    => 1,
    });
  }

  $self->{RESULT}->{results} = [ $result ];

  return $self;
}

#**********************************************************
=head2 get_sub($attr)

   Arguments:
     $attr
       ID

   Results:
     $self->
       {RESULT}->{results}

=cut
#**********************************************************
sub get_sub {
  my $self = shift;
  my ($attr) = @_;

  #  my $uid = $attr->{UID} || $attr->{ext_id} || 0;
  my $result = '';

  if ($attr->{sub_id}) {
    $result = $self->_send_request({
      ACTION => '/users/' . $attr->{uid} . '/subscriptions/' . $attr->{sub_id} . '?token=' . $CONF->{FOLCLOR_API_KEY} || '',
    });
  }
  else {
    $result = $self->_send_request({
      ACTION => '/users/' . $attr->{uid} . '/subscriptions?token=' . $CONF->{FOLCLOR_API_KEY} || '',
    });
  }

  $self->{RESULT}->{results} = [ $result ];

  return $self;
}

#**********************************************************
=head2 user_balance($attr)

   Arguments:
     $attr
       ID

   Results:
     $self->
       {RESULT}->{results}

=cut
#**********************************************************
sub user_balance {
  my $self = shift;
  my ($attr) = @_;

  my $uid = $attr->{SUBSCRIBE_ID} || $attr->{ext_id} || 0;
  my $amount = $attr->{AMOUNT} || 0;
  my $result = $self->_send_request({
    ACTION => '/users/' . $uid . '/provider/account?token=' . $CONF->{FOLCLOR_API_KEY} || '',
    POST   => 'true',
    PARAMS => {
      id        => $attr->{ID},
      amount    => $amount,
      sourse_id => '2',
    },
  });

  $self->{RESULT}->{results} = [ $result ];

  return $self;
}

#**********************************************************
=head2 user_list($attr)

   Arguments:
     $attr
       ID

   Results:
     $self->
       {RESULT}->{results}

=cut
#**********************************************************
sub user_list {
  my $self = shift;
  my ($attr) = @_;

  my $result = $self->_send_request({
    ACTION => 'users?subscriptions=current&token=' . $CONF->{FOLCLOR_API_KEY} || '',
  });

  $self->{RESULT}->{results} = [ $result ];

  return $self;
}

1;