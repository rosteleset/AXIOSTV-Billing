package Iptv::Microimpuls;

=head1 NAME

=head1 VERSION

  VERSION: 0.17
  REVISION: 20200908

=cut

#**********************************************************

use strict;
use warnings FATAL => 'all';

our $VERSION = 0.17;

use parent qw(dbcore);
use AXbills::Base qw(load_pmodule mk_unique_value in_array urlencode convert _bp);
use AXbills::Fetcher;
use Digest::SHA qw(hmac_sha256_hex);
use MIME::Base64;

my $MODULE = 'Microimpuls';

my ($admin, $CONF, $db);
my $json;
my AXbills::HTML $html;
my $lang;

#**********************************************************
# Init
#**********************************************************
sub new {
  my $class = shift;
  $db       = shift;
  $admin    = shift;
  $CONF     = shift;
  my $attr  = shift;

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
    ACTION => '/customer/info/',
  });

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
  my $public_key  = $self->{public_key} || '';
  my $private_key = $self->{private_key} || '';

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
        $message = $key . '=' . ($attr->{PARAMS}->{$key} // q{});
      }
    }
  }

  my $api_time = time();
  my $hmac_text = $api_time . $public_key . ($message || '');
  my $api_hash = hmac_sha256_hex($hmac_text, $private_key);

  my @params = ();
  $params[0] = 'API_ID: ' . $public_key;
  $params[1] = 'API_TIME: ' . $api_time;
  $params[2] = 'API_HASH: ' . $api_hash;

  my $result = web_request($request_url,
    {
      DEBUG      => 4,
      HEADERS    => \@params,
      POST       => ($message || '""'),
      DEBUG      => $debug,
      DEBUG2FILE => $self->{DEBUG_FILE},
      CURL       => 1,
    }
  );

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
       {RESULT}->{results}

=cut
#**********************************************************
sub user_info {
  my $self = shift;
  my ($attr) = @_;

  my $signature = _shaping_signature({
    client_id => $CONF->{MICROIMPULS_CLIENT_ID},
    ext_id    => $attr->{ext_id} || $attr->{UID} || 0,
  });

  my $result = $self->_send_request({
    ACTION => '/customer/info',
    PARAMS => {
      signature => $attr->{SIGNATURE} || $signature || '',
      ext_id    => $attr->{ext_id} || $attr->{UID} || 0,
      client_id => $CONF->{MICROIMPULS_CLIENT_ID} || 0,
    },
  });

  $self->{RESULT}->{results} = [ $result ];
  $attr->{return_info} = 1;
  $attr->{ext_id} ||= $attr->{UID};
  $attr->{account_id} = $CONF->{MICROIMPULS_FEW_ACCOUNTS} ? $attr->{ID} : $attr->{ext_id};

  my $account_info = $self->account_info($attr);
  $self->{RESULT}->{results}->[0]->{ACCOUNT} = $account_info;

  return $self;
}

#**********************************************************
=head2 user_add($attr)

   Arguments:
     $attr
       ID
       UID
       TP_ID,
       FILTER_ID
       TP_FILTER_ID

   Results:

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

  if (!$attr->{SERVICE_MODULE} && !$attr->{BILLD}) {
    $self->{errno} = '10101';
    $self->{errstr} = 'Error select Service';
    return $self;
  }

  my $account_id = $CONF->{MICROIMPULS_FEW_ACCOUNTS} ? $attr->{ID} : $attr->{UID};
  my $signature = _shaping_signature({
    client_id => $CONF->{MICROIMPULS_CLIENT_ID},
    ext_id    => $attr->{UID} || 0,
  });

  my $result = $self->user_info({
    ID        => $attr->{ID} || 0,
    ext_id    => $attr->{UID} || 0,
    client_id => $CONF->{MICROIMPULS_CLIENT_ID} || 0,
    signature => $signature,
  });

  if ($result->{RESULT}{results}[0]{error} && $result->{RESULT}{results}[0]{error} eq '1') {
    $signature = _shaping_signature({
      client_id => $CONF->{MICROIMPULS_CLIENT_ID},
      comment   => $attr->{UID} || 0,
      ext_id    => $attr->{UID} || 0,
    });

    $result = $self->_send_request({
      ACTION => '/customer/create',
      PARAMS => {
        signature => $signature,
        ext_id    => $attr->{UID} || 0,
        comment   => $attr->{UID} || 0,
        client_id => $CONF->{MICROIMPULS_CLIENT_ID} || 0,
      },
    });

    if ($result->{error} ne '0') {
      $self->{errno} = '10103';
      $self->{errstr} = 'Error user add';
      return $self;
    }

    $signature = _shaping_signature({
      client_id                 => $CONF->{MICROIMPULS_CLIENT_ID},
      password                  => $attr->{PASSWORD} || '',
      parent_code               => $attr->{PIN} || 0,
      ext_id                    => $attr->{UID} || 0,
      abonement                 => $account_id || 0,
      active                    => 1,
      status_reason             => "ACTIVE",
      allow_login_by_device_uid => 1,
    });

    $result = $self->_account_add({
      password      => $attr->{PASSWORD} || '',
      parent_code   => $attr->{PIN} || 0,
      ext_id        => $attr->{UID} || 0,
      active        => 1,
      status_reason => 'ACTIVE',
      abonement     => $account_id || 0,
      signature     => $signature,
    });

    $result = $self->account_info({
      account_id => $account_id,
      ext_id     => $attr->{UID} || 0,
      client_id  => $CONF->{MICROIMPULS_CLIENT_ID} || 0,
      signature  => $signature,
    });

    $result = $self->_account_add({
      password      => $attr->{PASSWORD} || '',
      parent_code   => $attr->{PIN} || 0,
      ext_id        => $attr->{UID} || 0,
      active        => 1,
      status_reason => 'ACTIVE',
      abonement     => $account_id || 0,
      signature     => $signature,
    }) if (!$result->{RESULT}{results}[0]{abonement});

    $result = $self->_customer_tariff_assign({
      tariff_id => $attr->{TP_FILTER_ID} || 0,
      ext_id    => $attr->{UID} || 0,
    }) if (!$result->{RESULT}{results}[0]{error} && !$result->{RESULT}{results}[0]{error} eq '1');
  }
  else {
    my @tarrifs = $result->{RESULT}{results}[0]{tariffs};

    if ($result->{RESULT}{results}[0]{ACCOUNT}{error} && $result->{RESULT}{results}[0]{ACCOUNT}{error} eq '1') {
      $signature = _shaping_signature({
        client_id                 => $CONF->{MICROIMPULS_CLIENT_ID},
        password                  => $attr->{PASSWORD} || '',
        parent_code               => $attr->{PIN} || 0,
        ext_id                    => $attr->{UID} || 0,
        abonement                 => $account_id || 0,
        active                    => 1,
        status_reason             => "ACTIVE",
        allow_login_by_device_uid => 1,
      });

      $result = $self->_account_add({
        password      => $attr->{PASSWORD} || '',
        parent_code   => $attr->{PIN} || 0,
        ext_id        => $attr->{UID} || 0,
        active        => 1,
        status_reason => 'ACTIVE',
        abonement     => $account_id || 0,
        signature     => $signature,
      });
    }

    $self->_customer_tariff_assign({
      tariff_id => $attr->{TP_FILTER_ID} || 0,
      ext_id    => $attr->{UID} || 0,
    }) if (!in_array($attr->{TP_FILTER_ID}, @tarrifs));
  }

  return $self;
}

#**********************************************************
=head2 user_del($attr)

  Arguments:
    $attr

  Results:

=cut
#**********************************************************
sub user_del {
  my $self = shift;
  my ($attr) = @_;

  my $signature = _shaping_signature({
    client_id => $CONF->{MICROIMPULS_CLIENT_ID},
    ext_id    => $attr->{UID} || 0,
  });

  my $result = user_info($self, {
    ID        => $attr->{ID} || 0,
    ext_id    => $attr->{UID} || 0,
    client_id => $CONF->{MICROIMPULS_CLIENT_ID} || 0,
    signature => $signature,
  });

  if ($result->{RESULT}{results}[0]{error} eq '0') {
    my $Tarrifs = $result->{RESULT}{results}[0]{tariffs};
    my $elements = @$Tarrifs;

    $self->_account_del({ abonement => $attr->{ID} }) if $CONF->{MICROIMPULS_FEW_ACCOUNTS};

    if ($elements > 1) {
      _customer_tariff_remove($self, {
        tariff_id => $attr->{TP_FILTER_ID},
        ext_id    => $attr->{UID} || 0,
      });
    }
    else {
      $result = $self->_send_request({
        ACTION => '/customer/delete',
        PARAMS => {
          signature => $signature,
          ext_id    => $attr->{UID} || 0,
          client_id => $CONF->{MICROIMPULS_CLIENT_ID} || 0,
        },
      });
    }
  }
  else {
    $self->{errno} = '1';
    $self->{errstr} = 'Data Desynchronization Microimpuls <=> AXbills';
    return $self;
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

  my $signature = _shaping_signature({
    client_id => $CONF->{MICROIMPULS_CLIENT_ID},
    ext_id    => $attr->{UID} || 0,
  });

  my $account_id = $CONF->{MICROIMPULS_FEW_ACCOUNTS} ? $attr->{ID} : $attr->{UID};

  my $result = user_info($self, {
    ID        => $attr->{ID} || 0,
    ext_id    => $attr->{UID} || 0,
    client_id => $CONF->{MICROIMPULS_CLIENT_ID} || 0,
    signature => $signature,
  });

  if ($result->{RESULT}{results}[0]{error} eq '0') {
    my $Tariffs = $result->{RESULT}{results}[0]{tariffs} || ();

    foreach my $tariff (@{$Tariffs}) {
      _customer_tariff_remove($self, {
        tariff_id => $tariff,
        ext_id    => $attr->{UID} || 0,
        signature => $signature,
      });
    }

    _customer_tariff_assign($self, {
      tariff_id => $attr->{TP_FILTER_ID} || 0,
      ext_id    => $attr->{UID} || 0,
    });

    if ($attr->{STATUS} eq '0') {
      $self->_account_modify_status({
        active        => 1,
        abonement     => $account_id || 0,
        status_reason => "ACTIVE"
      });
    }
    elsif ($attr->{STATUS} eq '1') {
      $self->_account_modify_status({
        active        => 0,
        abonement     => $account_id || 0,
        status_reason => "INACTIVE"
      });
    }
    elsif ($attr->{STATUS} eq '3') {
      $self->_account_modify_status({
        active        => 0,
        abonement     => $account_id || 0,
        status_reason => "BLOCK",
      });
    }
    elsif ($attr->{STATUS} eq '5') {
      $self->_account_modify_status({
        active        => 0,
        abonement     => $account_id || 0,
        status_reason => "DEBT",
      });
    }

    if ($attr->{PIN} ne '') {
      $self->_account_modify_pin({
        password    => $attr->{PASSWORD},
        parent_code => $attr->{PIN} || '',
        abonement   => $account_id || 0,
        signature   => $signature,
      });
    }

  }
  else {
    $self->{errno} = '1';
    $self->{errstr} = 'Data Dissynchronization Microimpuls <=> AXbills';

    my $status_reason = $attr->{STATUS} eq "0" ? "ACTIVE" : $attr->{STATUS} eq "1" ? "INACTIVE" : $attr->{STATUS} eq "3" ?
      "BLOCK" : $attr->{STATUS} eq "5" ? "DEBT" : "ACTIVE";
    my $active = $attr->{STATUS} eq "0" ? "1" : $attr->{STATUS} eq "1" ? "0" :
      $attr->{STATUS} eq "3" ? "0" : $attr->{STATUS} eq "5" ? "0" : "1";

    $signature = _shaping_signature({
      client_id => $CONF->{MICROIMPULS_CLIENT_ID},
      comment   => $attr->{UID} || 0,
      ext_id    => $attr->{UID} || 0,
    });

    $result = $self->_send_request({
      ACTION => '/customer/create',
      PARAMS => {
        signature => $signature,
        ext_id    => $attr->{UID} || 0,
        comment   => $attr->{UID} || 0,
        client_id => $CONF->{MICROIMPULS_CLIENT_ID} || 0,
      },
    });

    if ($result->{error} eq '0') {
      $signature = _shaping_signature({
        client_id                 => $CONF->{MICROIMPULS_CLIENT_ID},
        password                  => $attr->{PASSWORD} || '',
        parent_code               => $attr->{PIN} || 0,
        ext_id                    => $attr->{UID} || 0,
        abonement                 => $account_id || 0,
        active                    => $active,
        status_reason             => $status_reason,
        allow_login_by_device_uid => 1,
      });

      $result = _account_add($self, {
        password      => $attr->{PASSWORD} || '',
        parent_code   => $attr->{PIN} || 0,
        ext_id        => $attr->{UID} || 0,
        abonement     => $account_id || 0,
        status_reason => $status_reason,
        active        => $active,
        signature     => $signature,
      });

      if ($result->{RESULT}{results}[0]{error} && $result->{RESULT}{results}[0]{error} eq '1') {
        _customer_tariff_assign($self, {
          tariff_id => $attr->{TP_FILTER_ID} || 0,
          ext_id    => $attr->{UID} || 0,
          signature => $signature,
        });
      }
    }

    return $self;
  }

  return $self;
}

#**********************************************************
=head2 _shaping_signature($attr)

  Arguments:
    $attr

  Results:

=cut
#**********************************************************
sub _shaping_signature {
  my ($attr) = @_;

  my $signature = '';

  foreach my $key (sort keys %{$attr}) {
    $signature .= $key . ':' . $attr->{$key} . ";";
  }

  $signature .= $CONF->{MICROIMPULS_API_KEY};

  # print "Sign string: $signature\n";

  my $md5 = Digest::MD5->new();

  $signature = encode_base64($signature);
  $signature =~ s/[\s]//g;
  $md5->reset;
  $md5->add($signature);
  $signature = $md5->hexdigest;

  # print "Sign: $signature\n";

  return $signature;
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

  my $signature = _shaping_signature({
    client_id => $CONF->{MICROIMPULS_CLIENT_ID},
    ext_id    => $attr->{UID} || 0,
  });

  my $account_id = $CONF->{MICROIMPULS_FEW_ACCOUNTS} ? $attr->{ID} : $attr->{UID};

  my $result = $self->user_info({
    ID        => $attr->{ID} || 0,
    ext_id    => $attr->{UID} || 0,
    client_id => $CONF->{MICROIMPULS_CLIENT_ID} || 0,
    signature => $signature,
  });

  if ($result->{RESULT}{results}[0]{error} eq '0') {
    $self->_account_modify_status({
      active        => 0,
      abonement     => $account_id || 0,
      status_reason => "DEBT",
    });
  }
  else {
    $self->{errno} = '10101';
    $self->{errstr} = 'Data Desynchronization Microimpuls <=> AXbills';
    return $self;
  }

  return $self;
}

#**********************************************************
=head2 account_info($attr)

   Arguments:
     $attr
       ID
       ext_id
       SIGNATURE
       return_info - Return information

   Results:
     $self->
       {RESULT}->{results}

=cut
#**********************************************************
sub account_info {
  my $self = shift;
  my ($attr) = @_;

  my $user_id = $attr->{ext_id} || $attr->{UID} || 0;

  my $signature = _shaping_signature({
    client_id => $CONF->{MICROIMPULS_CLIENT_ID},
    ext_id    => $user_id,
    abonement => $attr->{account_id},
  });

  my $result = $self->_send_request({
    ACTION => '/account/info',
    PARAMS => {
      signature => $attr->{SIGNATURE} || $signature || '',
      ext_id    => $user_id,
      abonement => $attr->{account_id},
      client_id => $CONF->{MICROIMPULS_CLIENT_ID} || 0,
    },
  });

  if ($attr->{return_info}) {
    return $result;
  }

  $self->{RESULT}->{results} = [ $result ];

  return $self;
}

#**********************************************************
=head2 _account_add($attr)

  Arguments:
    $attr
      signature
      password
      parent_code
      ext_id
      abonement

  Results:

=cut
#**********************************************************
sub _account_add {
  my $self = shift;
  my ($attr) = @_;

  $self->_send_request({
    ACTION => '/account/create',
    PARAMS => {
      ext_id                    => $attr->{ext_id} || 0,
      password                  => $attr->{password} || '',
      parent_code               => $attr->{parent_code} || 0,
      abonement                 => $attr->{abonement} || 0,
      active                    => $attr->{active} eq '0' ? 0 : 1,
      status_reason             => $attr->{status_reason} || "ACTIVE",
      allow_login_by_device_uid => 1,
      client_id                 => $CONF->{MICROIMPULS_CLIENT_ID} || 0,
      signature                 => $attr->{signature} || '',
    },
  });

  return $self;
}

#**********************************************************
=head2 _account_del($attr)

  Arguments:
    $attr
      abonement

  Results:

=cut
#**********************************************************
sub _account_del {
  my $self = shift;
  my ($attr) = @_;

  my $signature = _shaping_signature({
    client_id => $CONF->{MICROIMPULS_CLIENT_ID},
    abonement => $attr->{abonement} || 0,
  });

  $self->_send_request({
    ACTION => '/account/delete',
    PARAMS => {
      abonement => $attr->{abonement} || 0,
      client_id => $CONF->{MICROIMPULS_CLIENT_ID} || 0,
      signature => $signature || '',
    },
  });

  return $self;
}

#**********************************************************
=head2 _account_modify($attr)

  Arguments:
    $attr
      signature
      abonement
      active
      status_reason

  Results:

=cut
#**********************************************************
sub _account_modify_status {
  my $self = shift;
  my ($attr) = @_;

  my $signature = _shaping_signature({
    client_id     => $CONF->{MICROIMPULS_CLIENT_ID},
    active        => $attr->{active} || 0,
    abonement     => $attr->{abonement} || 0,
    status_reason => $attr->{status_reason},
  });

  $self->_send_request({
    ACTION => '/account/modify',
    PARAMS => {
      abonement     => $attr->{abonement} || 0,
      active        => $attr->{active} || 0,
      status_reason => $attr->{status_reason},
      client_id     => $CONF->{MICROIMPULS_CLIENT_ID} || 0,
      signature     => $signature || '',
    },
  });

  return $self;
}

#**********************************************************
=head2 _account_modify_pin($attr)

  Arguments:
    $attr
      signature
      parent_code
      abonement

  Results:

=cut
#**********************************************************
sub _account_modify_pin {
  my $self = shift;
  my ($attr) = @_;

  my $signature = _shaping_signature({
    client_id   => $CONF->{MICROIMPULS_CLIENT_ID},
    password    => $attr->{password} || '',
    parent_code => $attr->{parent_code} || 0,
    abonement   => $attr->{abonement} || 0,
  });

  $self->_send_request({
    ACTION => '/account/modify',
    PARAMS => {
      abonement   => $attr->{abonement} || 0,
      password    => $attr->{password} || '',
      parent_code => $attr->{parent_code} || 0,
      client_id   => $CONF->{MICROIMPULS_CLIENT_ID} || 0,
      signature   => $signature || '',
    },
  });

  return $self;
}

#**********************************************************
=head2 _customer_tariff_assign($attr)

  Arguments:
    $attr
      signature
      tarif_id
      ext_id

  Results:

=cut
#**********************************************************
sub _customer_tariff_assign {
  my $self = shift;
  my ($attr) = @_;

  my $signature = _shaping_signature({
    client_id => $CONF->{MICROIMPULS_CLIENT_ID},
    ext_id    => $attr->{ext_id} || 0,
    tariff_id => $attr->{tariff_id} || 0,
  });

  $self->_send_request({
    ACTION => '/customer/tariff/assign',
    PARAMS => {
      signature => $signature,
      tariff_id => $attr->{tariff_id} || 0,
      ext_id    => $attr->{ext_id} || 0,
      client_id => $CONF->{MICROIMPULS_CLIENT_ID} || 0,
    },
  });

  return $self;
}

#**********************************************************
=head2 _customer_tariff_remove($attr)

  Arguments:
    $attr
      signature
      tarif_id
      ext_id

  Results:

=cut
#**********************************************************
sub _customer_tariff_remove {
  my $self = shift;
  my ($attr) = @_;

  my $signature = _shaping_signature({
    client_id => $CONF->{MICROIMPULS_CLIENT_ID},
    ext_id    => $attr->{ext_id} || 0,
    tariff_id => $attr->{tariff_id} || 0,
  });

  $self->_send_request({
    ACTION => '/customer/tariff/remove',
    PARAMS => {
      signature => $signature,
      tariff_id => $attr->{tariff_id} || 0,
      ext_id    => $attr->{ext_id} || 0,
      client_id => $CONF->{MICROIMPULS_CLIENT_ID} || 0,
    },
  });

  return $self;
}

#**********************************************************
=head2 user_import($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub user_import {
  my $self = shift;
  my ($attr) = @_;

  if (!$attr->{USER_ID}) {
    $self->{errno} = '3';
    $self->{errstr} = 'Set user id in Microimpuls';
    return $self;
  }

  my $signature = _shaping_signature({
    client_id   => $CONF->{MICROIMPULS_CLIENT_ID},
    customer_id => $attr->{USER_ID},
  });

  my $result = $self->_send_request({
    ACTION => '/customer/info',
    PARAMS => {
      signature   => $signature,
      client_id   => $CONF->{MICROIMPULS_CLIENT_ID},
      customer_id => $attr->{USER_ID},
    },
  });

  if ($result->{error}) {
    $self->{errno} = '4';
    $self->{errstr} = $result->{error_message} || 'Error get user info';
    return $self;
  }

  $signature = _shaping_signature({
    customer_id => $attr->{USER_ID},
    ext_id      => $attr->{UID},
    client_id   => $CONF->{MICROIMPULS_CLIENT_ID},
  });

  $self->_send_request({
    ACTION => '/customer/modify',
    PARAMS => {
      customer_id => $attr->{USER_ID},
      ext_id      => $attr->{UID},
      client_id   => $CONF->{MICROIMPULS_CLIENT_ID},
      signature   => $signature,
    },
  });

  if ($result->{error}) {
    $self->{errno} = '5';
    $self->{errstr} = 'Error modify user';
    return $self;
  }

  return $self;
}

1;