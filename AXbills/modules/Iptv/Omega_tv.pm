package Iptv::Omega_tv;

=head1 NAME

=head1 VERSION

  VERSION: 1.20
  Revision: 2020.05.22

=head1 SYNOPSIS

  https://docs.google.com/document/d/1D3Xr-RjCqVS2JDD3gfCIngNC5orr-YmWt8y6gf8N7b0/edit

=cut

#**********************************************************

use strict;
use warnings FATAL => 'all';

our $VERSION = 1.20;

use parent qw(dbcore);
use AXbills::Base qw(load_pmodule mk_unique_value in_array urlencode convert);
use AXbills::Fetcher qw(web_request);
use Digest::SHA qw(hmac_sha256_hex);
my $MODULE = 'Omega_tv';

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
    ACTION => '/stb/list_free',
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
  my $public_key = $self->{public_key} || '';
  my $private_key = $self->{private_key} || '';

  delete $self->{errno};
  delete $self->{error};
  delete $self->{errstr};

  my $debug = (defined($attr->{DEBUG})) ? $attr->{DEBUG} : $self->{debug};
  if ($self->{DEBUG_FILE} && $debug < 2) {
    $debug = 2;
  }

  if ($attr->{ACTION}) {
    $request_url .= $attr->{ACTION};
  }

  my $bundle_str = "";
  if ($attr->{bundle}) {
    my $count = 0;
    foreach my $bundl (@{$attr->{bundle}}) {
      $bundle_str .= "&bundle%5B" . $count . "%5D=$bundl";
      $count++;
    }
  }

  my $message = ();
  if ($attr->{PARAMS}) {
    foreach my $key (keys %{$attr->{PARAMS}}) {
      if ($message) {
        $message .= '&' . ($key || q{}) . '=' . ($attr->{PARAMS}->{$key} // q{});
      }
      else {
        $message = $key . '=' . ($attr->{PARAMS}->{$key} // q{});
      }
    }

    $message .= $bundle_str;
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
      DEBUG        => 4,
      HEADERS      => \@params,
      POST         => ($message || '""'),
      DEBUG        => $debug,
      DEBUG2FILE   => $self->{DEBUG_FILE},
      CURL         => 1,
      CURL_OPTIONS => "--connect-timeout 4"
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

  if ($perl_scalar->{error}) {
    $perl_scalar->{errno} = ref $perl_scalar->{error} eq 'HASH' ? $perl_scalar->{error}{code} : $perl_scalar->{error};
        $perl_scalar->{err_str} = ref $perl_scalar->{error} eq 'HASH' ? $perl_scalar->{error}{msg} : $perl_scalar->{error_msg} || '';
    $self->{errno} = 101;
    $self->{error} = 101;
    $self->{errstr} = $result;
  }

  return $perl_scalar;
}

#**********************************************************
=head2 stb_list_activated($attr)

  Arguments:
    TARIFF_NAME -
    FILTER_ID   -
    SERVICE_ID  -

  Returns:

=cut
#**********************************************************
sub reports {
  my $self = shift;
  my ($attr) = @_;

  my $result = '';

  if ($attr->{TYPE}) {
    my $type = $attr->{TYPE} || q{};
    if ($type eq 'list_activated') {
      if ($attr->{del}) {
        $self->user_device_del($attr);
      }

      $result = $self->_send_request({
        ACTION => '/device/list',
      });

      $result = \@{$result->{result}};
      $self->{FUNCTION_FIELDS} = "iptv_console:DEL:uniq;customer_id:&TYPE="
        . $type . "&del=1&COMMENTS=1"
        . (($attr->{SERVICE_ID}) ? "&SERVICE_ID=$attr->{SERVICE_ID}" : '');
      $self->{REPORT_NAME} = 'DEVICE';
    }
    elsif ($type eq 'channel_get_all') {
      $result = $self->_send_request({
        ACTION => '/tariff/bundle/list',
      });
      $result = \@{$result->{result}};
      $self->{REPORT_NAME} = 'ADDED_TP';
    }
    elsif ($type eq 'get_channel_groups') {
      if ($attr->{tp_add}) {
        require Tariffs;
        Tariffs->import();
        my $Tariffs = Tariffs->new($self->{db}, $self->{conf}, $admin);

        $Tariffs->list({ NAME => $attr->{TARIFF_NAME}, FILTER_ID => $attr->{TARIFF_ID} });

        if (!$Tariffs->{TOTAL}) {
          $Tariffs->add({
            NAME       => $attr->{TARIFF_NAME},
            MODULE     => 'Iptv',
            SERVICE_ID => $attr->{SERVICE_ID},
            FILTER_ID  => $attr->{TARIFF_ID}
          });

          if (!$Tariffs->{errno}) {
            $html->message('info', '', $lang->{ADDED} . " $attr->{TARIFF_NAME} # $Tariffs->{TP_ID} \n"
              . ' ' . $html->button($lang->{GO}, "get_index=iptv_tp&TP_ID=$Tariffs->{TP_ID}&full=1"));
          }
        }
        else {
          my $tp_list = $Tariffs->list({
            NAME       => $attr->{TARIFF_NAME},
            MODULE     => 'Iptv',
            SERVICE_ID => $attr->{SERVICE_ID},
            FILTER_ID  => $attr->{TARIFF_ID},
            COLS_NAME  => 1
          });

          $tp_list->[0]->{tp_id} ||= q{};
          $html->message('err', '', $lang->{EXIST} . ' # '
            . $tp_list->[0]->{tp_id}
            . "\n" . $html->button($lang->{GO}, "get_index=iptv_tp&TP_ID=$tp_list->[0]->{tp_id}&full=1"));
        }
      }

      $result = $self->_send_request({
        ACTION => '/tariff/base/list',
      });

      $result = \@{$result->{result}};
      $self->{FUNCTION_FIELDS} = "iptv_console:add:tariff_id;tariff_name:&TYPE="
        . $type . "&tp_add=1&COMMENTS=1"
        . (($attr->{SERVICE_ID}) ? "&SERVICE_ID=$attr->{SERVICE_ID}" : '');
      $self->{REPORT_NAME} = 'TARIF_PLANS';
    }
  }
  else {
    $result = $self->_send_request({
      ACTION => '/tariff/bundle/list',
    });
    $result = \@{$result->{result}};
    $self->{REPORT_NAME} = 'ADDED_TP';
  }

  my @menu = (
    "$lang->{DEVICE}:index=$html->{index}&TYPE=list_activated&SERVICE_ID=$html->{HTML_FORM}->{SERVICE_ID}",
    "$lang->{ADDED_TP}:index=$html->{index}&TYPE=channel_get_all&SERVICE_ID=$html->{HTML_FORM}->{SERVICE_ID}",
    "$lang->{TARIF_PLANS}:index=$html->{index}&TYPE=get_channel_groups&SERVICE_ID=$html->{HTML_FORM}->{SERVICE_ID}",
  );

  $self->{REPORT} = $result;
  $self->{MENU} = \@menu;

  return 1;
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

  my $Iptv = Iptv->new($self->{db}, $admin, $CONF);
  my $Tariff = Tariffs->new($self->{db}, $admin, $CONF);
  my $Base_tp = $Iptv->user_info($attr->{ID});

  my @channel_array = ();

  my $tp_info = $Tariff->ti_list({
    TP_ID     => $attr->{TP_ID},
    COLS_NAME => 1
  });

  if ($tp_info->[0]{id}) {
    my $channel_ti_list = $Iptv->channel_ti_list({
      MANDATORY        => 1,
      COLS_NAME        => 1,
      USER_INTERVAL_ID => $tp_info->[0]{id},
    });

    if ($Iptv->{TOTAL}) {
      foreach my $channel (@$channel_ti_list) {
        if ($attr->{IDS}) {
          $attr->{IDS} .= "," . $channel->{channel_id};
        }
        else {
          $attr->{IDS} .= $channel->{channel_id};
        }
      }
    }
  }

  if ($attr->{IDS}) {
    my @channels = split(/,/, $attr->{IDS});
    for my $channel (@channels) {
      my $chan_info = $Iptv->channel_info({
        ID => $channel,
      });
      if ($chan_info->{FILTER_ID} && !in_array($chan_info->{FILTER_ID}, \@channel_array)) {
        push @channel_array, $chan_info->{FILTER_ID};
      }
    }
  }

  my $result = $self->user_info($attr);

  $attr->{FILTER_ID} = $attr->{TP_FILTER_ID};
  if (!$result->{error} && $Base_tp->{TP_FILTER_ID}) {
    $result = $self->_send_request({
      ACTION => '/customer/tariff/set',
      PARAMS => {
        customer_id => $CONF->{OMEGA_TV_LOGIN} ? $attr->{LOGIN} : $attr->{UID},
        base        => $Base_tp->{TP_FILTER_ID},
      },
      bundle => \@channel_array,
    });
  }

  return 1;
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

  my $url = $self->{URL};
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

  $attr->{FILTER_ID} = $attr->{TP_FILTER_ID};

  $result = $self->_send_request({
    ACTION => '/customer/get',
    PARAMS => {
      customer_id => $CONF->{OMEGA_TV_LOGIN} ? $attr->{LOGIN} : $attr->{UID},
      status      => 1,
    },
  });

  if (!$result->{error}) {
    if ($result->{result}{tariff}{basic}[0]) {
      $self->{errno} = '10102';
      $self->{errstr} = "Base tariff already exist!";

      delete $self->{errno};
      $self->user_change($attr);

      return $self;
    }

    $self->_customer_tariff_assign($attr);

    if (!$attr->{STATUS} && defined($attr->{CID}) && $attr->{CID} ne "") {
      $result = $self->add_new_device($attr);

      $self->{URL} = $url;
      if (!$result->{RESULT}{results}[0]{error}) {
        $attr->{UNIQ} = $result->{RESULT}{results}[0]{success}{uniq};
        $result = $self->customer_add_device($attr);
        #        $self->{COMMENTS} = $result->{RESULT}{results}[0]{request}{uniq};
        #        $attr->{COMMENTS} = $result->{RESULT}{results}[0]{request}{uniq};
      }
    }
  }
  else {
    if ($result->{error}{msg}) {
      $self->{errno} = '10101';
      $self->{errstr} = $result->{error}{msg} || q{};
      return $self;
    }
  }

  return $self;
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

  if ($attr->{UNIQ_DEL}) {
    user_device_del($self, {
      CUSTOMER_ID => $attr->{UID},
      UNIQ        => $attr->{UNIQ_DEL},
    });
  }

  if ($attr->{chg_d} || $attr->{activ_code} || $attr->{watch}) {
    return 0;
  }

  if ($attr->{UNIQ} && $attr->{chg_device}) {
    my $result = $self->customer_add_device($attr);
    $self->{RESULT}->{results} = [ $result ];
    return $self;
  }

  my $result = $self->_send_request({
    ACTION => '/customer/get',
    PARAMS => {
      customer_id => $CONF->{OMEGA_TV_LOGIN} ? $attr->{LOGIN} : $attr->{UID},
    },
  });

  if ($result->{error}{msg}) {
    $self->{errno} = '10101';
    $self->{errstr} = "$result->{error}{msg}";
    return $self;
  }

  my $dev_result;
  my $count = 0;

  my $Module_i = $attr->{MODULE} || "Iptv";
  my $chg_ = $attr->{chg} || "";
  #my $index_ = $attr->{index};

  $self->{USER_DEVICES} = $result->{result}{devices};

  $attr->{UID} = $CONF->{OMEGA_TV_LOGIN} ? $attr->{LOGIN} : $attr->{UID};
  foreach my $device (@{$result->{result}{devices}}) {
    my $device_code = $device->{uniq} || "";
    $device->{''} = $html->button("DEL", "index=" . ($attr->{index} || main::get_function_index($attr->{get_index})) .
      "&chg=$chg_&UID=$attr->{UID}&MODULE=$Module_i&UNIQ_DEL=$device_code", { class => 'del' });
    $dev_result->{$lang->{DEVICE}}[$count] = $device;
    $count++;
  }

  $self->{RESULT}->{results} = [ $dev_result ];

  return $self;
}

#**********************************************************
=head2 get_code($attr)

   Arguments:
     $attr
       ID

   Results:
     $self->
       {RESULT}->{results}

=cut
#**********************************************************
sub get_code {
  my $self = shift;
  my ($attr) = @_;

  my $result = $self->_send_request({
    ACTION => '/customer/device/get_code',
    PARAMS => {
      customer_id => $CONF->{OMEGA_TV_LOGIN} ? $attr->{LOGIN} : $attr->{UID},
    },
  });

  if ($result->{result}{code}) {
    return $html->message('info', "$lang->{INFO}", "Activation code: " . $result->{result}{code});
  }
  else {
    if ($result->{error}{msg}) {
      return $html->message('error', "$lang->{ERROR}", $result->{error}{msg});
    }
  }

  $self->{RESULT}->{results} = [ $result ];

  return $self;
}

#**********************************************************
=head2 get_url($attr)

   Arguments:
     $attr
       ID

   Results:
     $self->
       {RESULT}->{results}

=cut
#**********************************************************
sub get_url {
  my $self = shift;
  my ($attr) = @_;

  my $result = $self->_send_request({
    ACTION => '/customer/get',
    PARAMS => {
      customer_id => $CONF->{OMEGA_TV_LOGIN} ? $attr->{LOGIN} : $attr->{UID},
    },
  });

  return $result;
}

#**********************************************************
=head2 user_change($attr) Change personal data

   Arguments:
     $attr
       ID
       STATUS
       CID

   Results:
     #self-

=cut
#**********************************************************
sub user_change {
  my $self = shift;
  my ($attr) = @_;

  my $url = $self->{URL};
  my $result = user_info($self, $attr);

  $attr->{FILTER_ID} = $attr->{TP_FILTER_ID};
  if (!$result->{error}) {
    if ($attr->{STATUS} eq '0') {
      customer_active($self, $attr);
    }
    if ($attr->{STATUS} eq '1' || $attr->{STATUS} eq '5') {
      customer_block($self, $attr);
    }

    _customer_tariff_assign($self, $attr);

    if (!$attr->{STATUS} && defined($attr->{CID}) && $attr->{CID} ne "") {
      $result = add_new_device($self, $attr);

      $self->{URL} = $url;
      if (!$result->{RESULT}{results}[0]{error}) {
        $attr->{UNIQ} = $result->{RESULT}{results}[0]{success}{uniq};
        $result = customer_add_device($self, $attr);
        #        $self->{COMMENTS} = $result->{RESULT}{results}[0]{request}{uniq};
        #        $attr->{COMMENTS} = $result->{RESULT}{results}[0]{request}{uniq};
      }
    }
  }

  return $self;
}

#**********************************************************
=head2 user_device_del($attr)

   Arguments:
     $attr
       ID

       UNIQ
       CUSTOMER_ID

   Results:
     $self->
       {RESULT}->{results}

=cut
#**********************************************************
sub user_device_del {
  my $self = shift;
  my ($attr) = @_;

  my $result = "";
  if ($attr->{UNIQ}) {
    $result = $self->_send_request({
      ACTION => '/customer/device/remove',
      PARAMS => {
        customer_id => $attr->{CUSTOMER_ID},
        uniq        => $attr->{UNIQ},
      },
    });

    if ($result->{error}{msg}) {
      $self->{errno} = '10101';
      $self->{errstr} = "$result->{error}{msg}";
      return $self;
    }

    $self->{RESULT}->{results} = [ $result ];
  }

  return $self;
}


#**********************************************************
=head2 user_del($attr)

   Arguments:
     $attr
       UID

   Results:
     $self->
       {RESULT}->{results}

=cut
#**********************************************************
sub user_del {
  my $self = shift;
  my ($attr) = @_;

  $self->user_info($attr);

  foreach my $device (@{$self->{USER_DEVICES }}) {
    $self->user_device_del({
      UNIQ        => $device->{uniq},
      CUSTOMER_ID => $CONF->{OMEGA_TV_LOGIN} ? $attr->{LOGIN} : $attr->{UID}
    });
  }

  $self->customer_block($attr);

  return $self;
}

#**********************************************************
=head2 _customer_tariff_assign($attr)

   Arguments:
     $attr
       ID

   Results:
     $self->
       {RESULT}->{results}

=cut
#**********************************************************
sub _customer_tariff_assign {
  my $self = shift;
  my ($attr) = @_;

  if (!$attr->{FILTER_ID}) {
    $self->{errno} = '10102';
    $self->{errstr} = $lang->{ERROR} . ': Filter id. ' . $lang->{SET_FILTER_ID_IN_TARIFF};
    return $self;
  }

  my $result = $self->change_channels($attr);

  $self->{RESULT}->{results} = [ $result ];

  return $self;
}

#**********************************************************
=head2 customer_block($attr)

   Arguments:
     $attr
       UID

   Results:
     $self->
       {RESULT}->{results}

=cut
#**********************************************************
sub customer_block {
  my $self = shift;
  my ($attr) = @_;

  my $result = $self->_send_request({
    ACTION => '/customer/block',
    PARAMS => {
      customer_id => $CONF->{OMEGA_TV_LOGIN} ? $attr->{LOGIN} : $attr->{UID},
    },
  });

  $self->{RESULT}->{results} = [ $result ];

  return $self;
}

#**********************************************************
=head2 add_new_device($attr)

   Arguments:
     $attr
       ID

   Results:
     $self->
       {RESULT}->{results}

=cut
#**********************************************************
sub add_new_device {
  my $self = shift;
  my ($attr) = @_;

  $self->{URL} = "https://admin.hls.tv/v3/";
  my $result = $self->_send_request({
    ACTION => '/hlsclient/auth',
    PARAMS => {
      sn       => $attr->{CID} || "",
      platform => "android",
      version  => 16,
      model    => "Model_name",
      info     => "abbils_device" . $attr->{CID},
      hash     => "abbils_device" . $attr->{CID},
    },
  });

  $self->{RESULT}->{results} = [ $result ];

  return $self;
}

#**********************************************************
=head2 customer_active($attr)

   Arguments:
     $attr
       ID

   Results:
     $self->
       {RESULT}->{results}

=cut
#**********************************************************
sub customer_active {
  my $self = shift;
  my ($attr) = @_;

  my $result = $self->_send_request({
    ACTION => '/customer/activate',
    PARAMS => {
      customer_id => $CONF->{OMEGA_TV_LOGIN} ? $attr->{LOGIN} : $attr->{UID},
    },
  });

  $self->{RESULT}->{results} = [ $result ];

  if ($result->{errno} && $result->{errno} == 2103) {
    delete $self->{errno};
  }

  return $self;
}

#**********************************************************
=head2 customer_add_device($attr)

   Arguments:
     $attr
       ID

   Results:
     $self->
       {RESULT}->{results}

=cut
#**********************************************************
sub customer_add_device {
  my $self = shift;
  my ($attr) = @_;

  if ($attr->{DEVICE}) {
    $html->tpl_show(main::_include('iptv_omega_player', 'Iptv'), {
      INDEX  => $attr->{INDEX},
      CHG    => $attr->{chg_d},
      MODULE => $attr->{MODULE},
      UID    => $attr->{UID},
    });

    return 1;
  }

  my $result = $self->_send_request({
    ACTION => '/customer/device/add',
    PARAMS => {
      customer_id => $CONF->{OMEGA_TV_LOGIN} ? $attr->{LOGIN} : $attr->{UID},
      uniq        => $attr->{UNIQ} || $attr->{uniq},
    },
  });

  if ($result->{error}{msg}) {
    $self->{errno} = '10100';
    $self->{errstr} = "$result->{error}{msg}";
    return $self;
  }

  $self->{RESULT}->{results} = [ $result ];

  return $self;
}

#**********************************************************
=head2 customer_delete_device($attr)

   Arguments:
     $attr
       ID

   Results:
     $self->
       {RESULT}->{results}

=cut
#**********************************************************
sub customer_delete_device {
  my $self = shift;
  my ($attr) = @_;

  my $result = $self->_send_request({
    ACTION => '/customer/device/remove',
    PARAMS => {
      customer_id => $CONF->{OMEGA_TV_LOGIN} ? $attr->{LOGIN} : $attr->{UID},
      uniq        => "$attr->{UNIQ}",
    },
  });

  $self->{RESULT}->{results} = [ $result ];

  return $self;
}


#**********************************************************
=head2 tp_export()

=cut
#**********************************************************
sub tp_export {
  my $self = shift;

  my $result = $self->_send_request({
    ACTION => '/tariff/base/list',
  });

  $self->{TP_LIST} = 1;
  my @tps = ();
  if ($result) {
    foreach my $tp (@{$result->{result}}) {
      push @tps, {
        ID       => $tp->{tariff_id},
        NAME     => $tp->{tariff_name},
        COMMENTS => $tp->{description}
      };
    }
  }

  return \@tps;
}

#**********************************************************
=head2 channel_export()

=cut
#**********************************************************
sub channel_export {
  my $self = shift;

  my $result = $self->_send_request({
    ACTION => '/tariff/bundle/list',
  });

  $self->{CHANNEL_LIST} = 1;

  my @channels = ();
  if ($result) {
    foreach my $tp (@{$result->{result}}) {
      my $is_utf = Encode::is_utf8($tp->{tariff_name});
      if (!$is_utf) {
        Encode::_utf8_off($tp->{tariff_name});
      }

      push @channels, {
        ID       => $tp->{tariff_id},
        NAME     => $tp->{tariff_name},
        COMMENTS => $tp->{description}
      };
    }
  }

  return \@channels;
}

#**********************************************************
=head2 get_playlist($attr)

=cut
#**********************************************************
sub get_playlist {
  my $self = shift;
  my ($attr) = @_;

  my $result = $self->_send_request({
    ACTION => '/customer/get',
    PARAMS => {
      customer_id => $CONF->{OMEGA_TV_LOGIN} ? $attr->{LOGIN} : $attr->{UID},
    },
  });

  return $result;
}

#**********************************************************
=head2 del_playlist($attr)

=cut
#**********************************************************
sub del_playlist {
  my $self = shift;
  my ($attr) = @_;

  my $result = $self->_send_request({
    ACTION => '/customer/url/remove',
    PARAMS => {
      customer_id => $attr->{UID},
      uniq        => $attr->{uniq},
    },
  });

  return $result;
}

#**********************************************************
=head2 add_playlist($attr)

=cut
#**********************************************************
sub add_playlist {
  my $self = shift;
  my ($attr) = @_;

  my $result = $self->_send_request({
    ACTION => '/customer/url/add',
    PARAMS => {
      customer_id => $CONF->{OMEGA_TV_LOGIN} ? $attr->{LOGIN} : $attr->{UID},
    },
  });

  return $result;
}


#**********************************************************
=head2 get_devices($attr)

=cut
#**********************************************************
sub get_devices {
  my $self = shift;
  my ($attr) = @_;

  my $result = $self->_send_request({
    ACTION => '/customer/get',
    PARAMS => {
      customer_id => $CONF->{OMEGA_TV_LOGIN} ? $attr->{LOGIN} : $attr->{UID},
    },
  });

  return $result;
}

#**********************************************************
=head2 del_devices($attr)

=cut
#**********************************************************
sub del_devices {
  my $self = shift;
  my ($attr) = @_;

  my $result = $self->_send_request({
    ACTION => '/customer/device/remove',
    PARAMS => {
      customer_id => $attr->{UID},
      uniq        => $attr->{uniq},
    },
  });

  return $result;
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

  $attr->{STATUS} = 5;

  customer_block($self, $attr);

  return 1;
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
    my $result = $self->del_devices({
      UID  => $CONF->{OMEGA_TV_LOGIN} ? $attr->{LOGIN} : $attr->{UID},
      uniq => $attr->{del_device}
    });
    if ($result->{status} && $result->{status} ne 'ok') {
      $html->message('err', $lang->{ERROR}, "$lang->{DEVICE}: $attr->{del_device}");
    }
    else {
      $html->message('info', $lang->{DELETED}, "$lang->{DEVICE}: $attr->{del_device}");
    }
  }
  elsif ($attr->{del_playlist}) {
    my $result = $self->del_playlist({
      UID  => $CONF->{OMEGA_TV_LOGIN} ? $attr->{LOGIN} : $attr->{UID},
      uniq => $attr->{del_playlist}
    });
    if ($result->{status} && $result->{status} ne 'ok') {
      $html->message('err', $lang->{ERROR}, "$lang->{PLAYLISTS}: $attr->{del_playlist}");
    }
    else {
      $html->message('info', $lang->{DELETED}, "$lang->{PLAYLISTS}: $attr->{del_playlist}");
    }
  }
  elsif ($attr->{add_new_playlist}) {
    my $result = $self->add_playlist($attr);
    if ($result->{status} && $result->{status} ne 'ok') {
      $html->message('err', $lang->{ERROR}, $lang->{PLAYLISTS});
    }
    else {
      $html->message('info', $lang->{ADDED}, $lang->{PLAYLISTS});
    }
  }

  my $result = $self->_send_request({
    ACTION => '/customer/get',
    PARAMS => {
      customer_id => $CONF->{OMEGA_TV_LOGIN} ? $attr->{LOGIN} : $attr->{UID},
    },
  });

  return() if ref $result ne 'HASH' || !$result->{result};

  my $tables;
  push @{$tables->{TABLES}}, _get_devices_table({ %{$attr}, %{$result->{result}} }) if $result->{result}{devices};
  push @{$tables->{TABLES}}, _get_playlists_table({ %{$attr}, %{$result->{result}} }) if $result->{result}{playlists};

  return $tables;
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
    title   => [ "Uniq", $lang->{ACTIVATION_DATA}, $lang->{MODEL}, "" ],
    ID      => 'DEVICES_OMEGA'
  });

  foreach (@{$attr->{devices}}) {
    my $del_btn = $html->button($lang->{DEL}, $attr->{URL} . "&del_device=$_->{uniq}", {
      class => 'del',
    });

    $table->addrow($_->{uniq}, $_->{activation_data}, $_->{model}, $del_btn);
  }

  return $table;
}

#**********************************************************
=head2 _get_playlists_table($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub _get_playlists_table {
  my ($attr) = @_;

  my $table = $html->table({
    width   => '100%',
    caption => $lang->{PLAYLISTS},
    title   => [ "Uniq", $lang->{ACTIVATION_DATA}, $lang->{MODEL}, '', '' ],
    ID      => 'PLAYLISTS_OMEGA',
    header  => [ "$lang->{CREATE_PLAYLIST}:$attr->{URL}&add_new_playlist=1" ],
  });

  return $table if !$attr->{playlists} || ref $attr->{playlists} ne 'ARRAY';

  foreach (@{$attr->{playlists}}) {
    my $dwn_btn = $html->button($lang->{DOWNLOAD} . " M3U", '', {
      GLOBAL_URL => $_->{url} || "",
      target     => '_new',
      class      => 'btn btn-default btn-sm',
    });
    my $del_btn = $html->button($lang->{DEL}, $attr->{URL} . "&del_playlist=$_->{uniq}", {
      class => 'del',
    });

    $table->addrow($_->{uniq}, $_->{activation_data}, $_->{model}, $dwn_btn, $del_btn);
  }

  return $table;
}

package Iptv::Omega_tv_old;

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
=head2 playlist_create($attr)

=cut
#**********************************************************
#@deprecated
sub playlist_create {
  my $self = shift;
  my ($attr) = @_;

  my $result = $self->_send_request({
    ACTION => '/playlist/create',
    PARAMS => {
      customer_id      => $attr->{CUSTOMER_ID},
      channel_group_id => $attr->{CHANNEL_GROUP_ID},
    },
  });

  return $result
}

#**********************************************************
=head2 playlist_get_for_customer($attr)

=cut
#**********************************************************
#@deprecated
sub playlist_get_for_customer {
  my $self = shift;
  my ($attr) = @_;

  my $result = $self->_send_request({
    ACTION => '/playlist/get_for_customer',
    PARAMS => {
      customer_id => $attr->{CUSTOMER_ID},
    },
  });

  return $result
}

#**********************************************************
=head2 playlist_remove_playlist($attr)

=cut
#**********************************************************
#@deprecated
sub playlist_remove_playlist {
  my $self = shift;
  my ($attr) = @_;

  my $result = $self->_send_request({
    ACTION => '/playlist/remove_playlist',
    PARAMS => {
      playlist_id => $attr->{PLAYLIST_ID},
    },
  });

  return $result
}

#**********************************************************
=head2 playlist_toggle_playlist($attr)

=cut
#**********************************************************
#@deprecated
sub playlist_toggle_playlist {
  my $self = shift;
  my ($attr) = @_;

  my $result = $self->_send_request({
    ACTION => '/playlist/toggle_playlist',
    PARAMS => {
      playlist_id => $attr->{PLAYLIST_ID},
      status      => $attr->{STATUS},
    },
  });

  return $result
}

#**********************************************************
=head2 stb_set_playlist($attr)

  Arguments:
    $attr
      PLAYLIST_ID
      STB_UNIQ

  Returns:


=cut
#**********************************************************
sub stb_set_playlist {
  my $self = shift;
  my ($attr) = @_;

  my $result = $self->_send_request({
    ACTION => '/stb/set_playlist',
    PARAMS => {
      playlist_id => $attr->{PLAYLIST_ID},
      stb_uniq    => $attr->{STB_UNIQ},
    },
  });

  return $result
}

#**********************************************************
=head2 stb_register($attr)

=cut
#**********************************************************
sub stb_register {
  my $self = shift;
  my ($attr) = @_;

  my $result = $self->_send_request({
    ACTION => '/stb/register',
    PARAMS => {
      stb_uniq         => $attr->{STB_UNIQ},
      customer_id      => $attr->{CUSTOMER_ID},
      channel_group_id => $attr->{CHANNEL_GROUP_ID},
    },
  });

  return $result
}

#**********************************************************
=head2 stb_list_free($attr)

=cut
#**********************************************************
sub stb_list_free {
  my $self = shift;

  my $result = $self->_send_request({
    ACTION => '/stb/list_free',
  });

  return $result
}

#**********************************************************
=head2 stb_list_activated($attr)

=cut
#**********************************************************
sub stb_list_activated {
  my $self = shift;

  my $result = $self->_send_request({
    ACTION => '/stb/list_activated',
  });

  return $result
}

#**********************************************************
=head2 stb_get_for_customer($attr)

=cut
#**********************************************************
sub stb_get_for_customer {
  my $self = shift;
  my ($attr) = @_;

  my $result = $self->_send_request({
    ACTION => '/stb/get_for_customer',
    PARAMS => {
      customer_id => $attr->{CUSTOMER_ID},
    },
  });

  return $result
}

#**********************************************************
=head2 channel_get_all($attr)

=cut
#**********************************************************
sub channel_get_all {
  my $self = shift;
  my ($attr) = @_;

  my $result = $self->_send_request({
    ACTION => '/channel/get_all',
    PARAMS => {
      lang => $attr->{LANG},
    },
  });

  return $result
}

#**********************************************************
=head2 channel_get_channel_groups($attr)

=cut
#**********************************************************
sub channel_get_channel_groups {
  my $self = shift;
  my ($attr) = @_;

  my $result = $self->_send_request({
    ACTION => '/channel/get_channel_groups',
    PARAMS => {
      lang => $attr->{LANG},
    },
  });

  return $result
}

#**********************************************************
=head2 hls_device_list($attr)

=cut
#**********************************************************
sub hls_device_list {
  my $self = shift;
  #my ($attr) = @_;

  my $result = $self->_send_request({
    ACTION => '/hls_device/list',
  });

  return $result
}

#**********************************************************
=head2 hls_device_set_playlist($attr)

=cut
#**********************************************************
sub hls_device_set_playlist {
  my $self = shift;
  my ($attr) = @_;

  my $result = $self->_send_request({
    ACTION => '/hls_device/set_playlist',
    PARAMS => {
      code        => $attr->{CODE},
      playlist_id => $attr->{PLAYLIST_ID},
    },
  });

  return $result
}

#**********************************************************
=head2 hls_device_register($attr)

=cut
#**********************************************************
sub hls_device_register {
  my $self = shift;
  my ($attr) = @_;

  my $result = $self->_send_request({
    ACTION => '/hls_device/register',
    PARAMS => {
      code        => $attr->{CODE},
      customer_id => $attr->{CUSTOMER_ID},
    },
  });

  return $result
}

#**********************************************************
=head2 hls_device_attach_playlist($attr)

=cut
#**********************************************************
sub hls_device_attach_playlist {
  my $self = shift;
  my ($attr) = @_;

  my $result = $self->_send_request({
    ACTION => '/hls_device/attach_playlist',
    PARAMS => {
      uniq        => $attr->{UNIQ},
      playlist_id => $attr->{PLAYLIST_ID},
    },
  });

  return $result
}

#**********************************************************
=head2 hls_device_register_by_uniq($attr)

=cut
#**********************************************************
sub hls_device_register_by_uniq {
  my $self = shift;
  my ($attr) = @_;

  my $result = $self->_send_request({
    ACTION => '/hls_device/register_by_uniq',
    PARAMS => {
      uniq             => $attr->{UNIQ},
      customer_id      => $attr->{CUSTOMER_ID},
      channel_group_id => $attr->{CHANNEL_GROUP_ID},
    },
  });

  return $result
}

#**********************************************************
=head2 hls_client_add($attr)

  Arguments:
    $attr
      SERIAL_NUM
      MODEL
      INFO

  Results:

=cut
#**********************************************************
sub hls_client_add {
  my $self = shift;
  my ($attr) = @_;

  my $result = $self->_send_request({
    ACTION => '/hls_device/get_for_customer',
    PARAMS => {
      sn    => $attr->{SERIAL_NUM},
      model => $attr->{MODEL},
      info  => $attr->{INFO}
    },
  });

  return $result
}

#**********************************************************
=head2 hls_device_get_for_customer($attr)

=cut
#**********************************************************
sub hls_device_get_for_customer {
  my $self = shift;
  my ($attr) = @_;

  my $result = $self->_send_request({
    ACTION => '/hls_device/get_for_customer',
    PARAMS => {
      customer_id => $attr->{CUSTOMER_ID},
    },
  });

  return $result
}

#**********************************************************
=head2 user_add($attr)

   Arguments:
     $attr
       ID
       TP_ID,
       FILTER_ID
       TP_FILTER_ID
       PIN

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

  $attr->{FILTER_ID} = $attr->{TP_FILTER_ID};

  if (!$self->{errno} && $attr->{FIO}) {
    $self->user_change($attr);
  }

  if (!$self->{errno} && $attr->{PIN}) {
    $self->pin_add($attr);
  }

  my $result = $self->_send_request({
    ACTION => '/playlist/create',
    PARAMS => {
      customer_id      => $attr->{ID},
      channel_group_id => $attr->{FILTER_ID},
    },
  });

  if ($attr->{CHANGE_TP}) {
    return $self;
  }

  $self->{SUBSCRIBE_ID} = $result->{result}{playlist_id};

  if (!$self->{errno} && $attr->{CID}) {
    $self->stb_set_playlist({
      PLAYLIST_ID => $self->{SUBSCRIBE_ID},
      STB_UNIQ    => $attr->{CID},
    });
  }

  if (!$self->{errno} && $attr->{FIO}) {
    $self->user_change($attr);
  }

  #  if(! $self->{errno} && $attr->{PIN}) {
  #    $self->pin_add($attr);
  #  }

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
sub user_info {
  my $self = shift;
  my ($attr) = @_;

  my $result = $self->_send_request({
    ACTION => '/playlist/get_for_customer',
    PARAMS => {
      customer_id => $attr->{ID},
    },
  });

  $self->{RESULT}->{results} = [ $result ];

  return $self;
}

#**********************************************************
=head2 user_change($attr) Change personal data

   Arguments:
     $attr
       ID
       STATUS

   Results:
     #self-

=cut
#**********************************************************
sub user_change {
  my $self = shift;
  my ($attr) = @_;

  #status  1 - active, 0 - disable
  my $status = ($attr->{STATUS}) ? 0 : 1;

  my $result = $self->_send_request({
    ACTION => '/playlist/toggle_playlist',
    PARAMS => {
      playlist_id => $attr->{SUBSCRIBE_ID},
      status      => $status,
    },
  });

  if ($attr->{STATUS}) {
    delete($attr->{TP_FILTER_ID});
  }

  #  if($attr->{STATUS}) {
  #    $self->user_del($attr);
  #  }
  #

  if (!$self->{errno} && $attr->{CID}) {
    $self->stb_set_playlist({
      PLAYLIST_ID => $attr->{SUBSCRIBE_ID},
      STB_UNIQ    => $attr->{CID},
    });
  }

  #  if(! $self->{errno} && $attr->{PIN}) {
  #    $self->pin_add($attr);
  #  }

  return $result;
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

  $self->_send_request({
    ACTION => '/playlist/remove_playlist',
    PARAMS => {
      playlist_id => $attr->{SUBCRIBE_ID},
    },
  });

  return $self;
}

1
