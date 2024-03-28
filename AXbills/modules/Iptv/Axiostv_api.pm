package Iptv::Axiostv_api;

=head1 NAME

  Axiostv_api;

=head1 VERSION

  VERSION: 1.4
  REVISION: 20190402

=cut

use strict;
use warnings FATAL => 'all';
use AXbills::Base qw(load_pmodule _bp in_array);
use AXbills::Fetcher;
use Digest::MD5 qw(md5 md5_hex md5_base64);
use Iptv;

our $VERSION = 1.4;

my AXbills::HTML $html;
my $CONF;
my $MODULE = 'Axiostv_api';
my $db;
my $admin;
my $lang;

my ($json);

#**********************************************************
# Init
#**********************************************************
sub new {
  my $class = shift;
  $db = shift;
  $admin = shift;
  $CONF = shift;
  my $attr = shift;

  if ($attr->{HTML}) {
    $html = $attr->{HTML};
  }

  if ($attr->{LANG}) {
    $lang = $attr->{LANG};
  }

  $admin->{MODULE} = $MODULE;

  my $self = {
    db           => $db,
    conf         => $CONF,
    admin        => $admin,
    #    SERVICE_CONSOLE => 'axios_console',
    #    SEND_MESSAGE    => 1,
    SERVICE_NAME => 'Axiostv_api',
    VERSION      => $VERSION
  };

  bless($self, $class);

  load_pmodule('JSON');
  $json = JSON->new->allow_nonref;

  $self->{LOGIN} = $attr->{LOGIN};
  $self->{PASSWORD} = $attr->{PASSWORD};
  $self->{URL} = $attr->{URL};
  $self->{debug} = $attr->{DEBUG} || 0;
  $self->{DEBUG_FILE} = $attr->{DEBUG_FILE};

  if ($self->{URL} && $self->{URL} !~ /\/$/) {
    $self->{URL} .= '/';
  }

  return $self;
}


#**********************************************************
=head2 test($attr) - Test service

=cut
#**********************************************************
sub test {
  my $self = shift;

  my $result = $self->_send_request({
    ACTION => 'api/provider/accounts',
  });

  if (!$self->{errno}) {
    $result = 'Ok';
  }
  else {
    $result = 'Error';
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

  my $request_url = "$request_proto$self->{LOGIN}:$self->{PASSWORD}\@$self->{URL}";

  if ($attr->{ACTION}) {
    $request_url .= $attr->{ACTION};
  }

  my $message = ();
  if ($attr->{PARAMS}) {
    foreach my $key (keys %{$attr->{PARAMS}}) {
      my $key_p = "\\\"$key\\\"";
      my $value = "\\\"$attr->{PARAMS}->{$key}\\\"";
      if ($key eq "enabled" || $key eq "tarif" || $key eq "id" || $key eq "account" || $key eq "stop" || $key eq "account_dto" ||
        $key eq "tarif_dto") {
        if ($attr->{PARAMS}->{$key}) {
          $value = $attr->{PARAMS}->{$key} || "0";
        }
        else {
          $value = "0";
        }
      }

      if ($message) {
        $message .= ',' . $key_p . ': ' . $value;
      }
      else {
        if ($key eq "enabled") {
          $message = $key_p . ': ' . ($value || "0");
        }
        else {
          $message = $key_p . ': ' . ($value || q{});
        }
      }
    }
  }

  my @params = ();

  my $result = '';
  if ($attr->{POST}) {
    $params[0] = 'Content-Type: application/json';
    $result = web_request($request_url,
      {
        DEBUG        => 4,
        HEADERS      => \@params,
        POST         => ("{" . $message . "}" || '""'),
        DEBUG        => $debug,
        DEBUG2FILE   => $self->{DEBUG_FILE},
        CURL_OPTIONS => "-X POST",
        CURL         => 1,
      }
    );
  }
  elsif ($attr->{PUT}) {
    $params[0] = 'Content-Type: application/json';
    $result = web_request($request_url,
      {
        DEBUG        => 4,
        HEADERS      => \@params,
        POST         => ("{" . $message . "}" || '""'),
        DEBUG        => $debug,
        DEBUG2FILE   => $self->{DEBUG_FILE},
        CURL_OPTIONS => "-X PUT",
        CURL         => 1,
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
        CURL_OPTIONS => ($attr->{COMMAND}) ? "-X $attr->{COMMAND}" : undef,
        CURL         => 1,
      }
    );
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

=cut
#**********************************************************
sub user_info {
  my $self = shift;
  my ($attr) = @_;

  my $result = $self->_send_request(
    {
      ACTION => "api/provider/accounts/" . $attr->{SUBSCRIBE_ID},
    }
  );

  $self->{RESULT} = $result;

  return $self;
}

#**********************************************************
=head2 user_add($attr)

=cut
#**********************************************************
sub user_add {
  my $self = shift;
  my ($attr) = @_;

  if ($attr->{PAYMENTS_ADDED}) {
    $self->_send_request({
      ACTION => 'api/provider/accounts/' . $attr->{SUBSCRIBE_ID},
      PUT    => 1,
      PARAMS => {
        enabled => 1,
      },
    });

    return $self;
  }
  if ($attr->{OLD_STATUS}) {
    return $self;
  }

  my $Iptv = Iptv->new($db, $admin, $CONF);

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

  my $result = "";
  my $Iptv_user = $Iptv->user_list({
    SERVICE_ID   => $attr->{SERVICE_ID},
    UID          => $attr->{UID},
    SUBSCRIBE_ID => '_SHOW',
    COLS_NAME    => 1,
    PAGE_ROWS    => 99999,
  });

  if ($Iptv->{TOTAL} && ($Iptv_user->[0]{subscribe_id} || $Iptv_user->[1]{subscribe_id}) && !$attr->{NEW_USER}) {
    #    $result = user_sub($self, {
    #      SUBSCRIBE_ID => $Iptv_user->[0]{subscribe_id} || $Iptv_user->[1]{subscribe_id} || 0,
    #      TARIFF       => $attr->{TP_FILTER_ID},
    #    });
    #
    #    $self->{SUBSCRIBE_ID} = $Iptv_user->[0]{subscribe_id} || $Iptv_user->[1]{subscribe_id};
    #
    #    $self->{RESULT} = $result;
    $self->{errno} = '10102';
    $self->{errstr} = "Base tariff already exist!";
    return $self;
  }

  my $password_md5 = md5_hex($attr->{PASSWORD});

  $result = $self->_send_request({
    ACTION => 'api/provider/accounts',
    POST   => 1,
    PARAMS => {
      fullname     => $attr->{FIO} || "",
      login        => $attr->{LOGIN} || "",
      enabled      => $attr->{STATUS} eq "0" ? 1 : 0,
      pin_md5      => $password_md5 || "",
      main_address => $attr->{ADDRESS_FULL} || "",
    },
  });

  if (!$result->{statusCode}) {
    $self->{SUBSCRIBE_ID} = $result->{id};
  }

  $result = user_sub($self, {
    SUBSCRIBE_ID => $result->{id} || 0,
    TARIFF       => $attr->{TP_FILTER_ID},
  });

  $self->{RESULT} = $result;

  return $self;
}

#**********************************************************
=head2 user_del($attr)

=cut
#**********************************************************
sub user_del {
  my $self = shift;
  my ($attr) = @_;

  my $Iptv = Iptv->new($db, $admin, $CONF);

  #  $Iptv->user_list({
  #    SERVICE_ID   => $attr->{SERVICE_ID},
  #    UID          => $attr->{UID},
  #    SUBSCRIBE_ID => '_SHOW',
  #    COLS_NAME    => 1,
  #    PAGE_ROWS    => 99999,
  #  });

  my $result = "";

  #  if ($Iptv->{TOTAL}) {
  #    $result = $self->_send_request(
  #      {
  #        ACTION => "/api/provider/account_subscriptions/",
  #      }
  #    );
  #
  #    foreach my $element (@{$result->{data}}) {
  #      if ($element->{account} eq $attr->{SUBSCRIBE_ID} && $element->{tarif} eq $attr->{TP_FILTER_ID}) {
  #        $result = $self->_send_request(
  #          {
  #            ACTION  => "/api/provider/account_subscriptions/" . $element->{id},
  #            COMMAND => "DELETE",
  #          }
  #        );
  #
  #        $self->{RESULT} = $result;
  #
  #        return $self;
  #      }
  #    }
  #  }
  #  else {
  $result = $self->_send_request(
    {
      ACTION  => "api/provider/accounts/" . $attr->{SUBSCRIBE_ID},
      COMMAND => "DELETE",
    }
  );
  #  }

  $self->{RESULT} = $result;

  return $self;
}

#**********************************************************
=head2 user_change($attr)

=cut
#**********************************************************
sub user_change {
  my $self = shift;
  my ($attr) = @_;

  my $password_md5 = md5_hex($attr->{PASSWORD});

  my $result = $self->_send_request({
    ACTION => 'api/provider/accounts/' . $attr->{SUBSCRIBE_ID},
    PUT    => 1,
    PARAMS => {
      fullname     => $attr->{FIO} || "",
      login        => $attr->{LOGIN} || "",
      enabled      => $attr->{STATUS} eq "0" ? 1 : "0",
      pin_md5      => $password_md5 || "",
      main_address => $attr->{ADDRESS_FULL} || "",
    },
  });

  if ($result->{cause}) {
    $attr->{NEW_USER} = 1;
    $result = user_add($self, $attr);

    $self->{RESULT} = $result;

    return $self;
  }

  $result = $self->_send_request({
    ACTION => 'api/provider/account_subscriptions'
  });

  foreach my $element (@{$result->{data}}) {
    if ($attr->{SUBSCRIBE_ID} && $element->{account} eq $attr->{SUBSCRIBE_ID} && $element->{tarif} eq $attr->{TP_FILTER_ID}) {
      $self->{RESULT} = $result;

      return $self;
    }
  }

  my $old_tp = $attr->{TP_INFO_OLD}{FILTER_ID} || "";

  $self->_send_request(
    {
      ACTION  => "api/provider/account_subscriptions/" . $old_tp,
      COMMAND => "DELETE",
    }
  );

  $result = user_sub($self, {
    SUBSCRIBE_ID => $attr->{SUBSCRIBE_ID},
    TARIFF       => $attr->{TP_FILTER_ID},
  });


  $self->{RESULT} = $result;

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
  my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime();
  my $datetime = sprintf("%04d-%02d-%02dT%02d:%02d:%02d+0300", $year + 1900, $mon + 1, $mday, $hour, $min, $sec);

  $result = $self->_send_request({
    ACTION => 'api/provider/account_subscriptions',
    POST   => 1,
    PARAMS => {
      account => $attr->{SUBSCRIBE_ID},
      tarif   => $attr->{TARIFF},
      start   => $datetime,
    },
  });

  $self->{RESULT} = $result;

  return $self;
}

##**********************************************************
#=head2 reports($attr)
#
#=cut
##**********************************************************
#sub reports {
#  my $self = shift;
#  my ($attr) = @_;
#
#  my $result = '';
#
#  if ($attr->{TYPE}) {
#    my $type = $attr->{TYPE} || q{};
#    if ($type eq 'list_activated') {
#      #      if ($attr->{del}) {
#      #        $self->user_del($attr);
#      #      }
#
#      $result = $self->_send_request({
#        ACTION => 'api/provider/devices/',
#      });
#
#      #      _bp('', $result->{data});
#
#      $result = \@{$result->{data}};
#      $self->{FUNCTION_FIELDS} = "iptv_console:DEL:uniq;customer_id:&TYPE="
#        . $type . "&del=1&COMMENTS=1"
#        . (($attr->{SERVICE_ID}) ? "&SERVICE_ID=$attr->{SERVICE_ID}" : '');
#      $self->{REPORT_NAME} = 'DEVICE';
#    }
#    #    elsif ($type eq 'channel_get_all') {
#    #      $result = $self->_send_request({
#    #        ACTION => '/tariff/bundle/list',
#    #      });
#    #      $result = \@{$result->{result}};
#    #      $self->{REPORT_NAME} = 'ADDED_TP';
#    #    }
#    #    elsif ($type eq 'get_channel_groups') {
#    #      if ($attr->{tp_add}) {
#    #        require Tariffs;
#    #        Tariffs->import();
#    #        my $Tariffs = Tariffs->new($self->{db}, $self->{conf}, $admin);
#    #
#    #        $Tariffs->list({ NAME => $attr->{TARIFF_NAME}, FILTER_ID  => $attr->{TARIFF_ID} });
#    #
#    #        if (!$Tariffs->{TOTAL}) {
#    #          $Tariffs->add({
#    #            NAME       => $attr->{TARIFF_NAME},
#    #            MODULE     => 'Iptv',
#    #            SERVICE_ID => $attr->{SERVICE_ID},
#    #            FILTER_ID  => $attr->{TARIFF_ID}
#    #          });
#    #
#    #          if (!$Tariffs->{errno}) {
#    #            $html->message('info', '', $lang->{ADDED});
#    #          }
#    #        }
#    #        else {
#    #          my $tp_list = $Tariffs->list({
#    #            NAME       => $attr->{TARIFF_NAME},
#    #            MODULE     => 'Iptv',
#    #            SERVICE_ID => $attr->{SERVICE_ID},
#    #            FILTER_ID  => $attr->{TARIFF_ID},
#    #            COLS_NAME  => 1
#    #          });
#    #
#    #          $html->message('err', '', $lang->{EXIST} . ' # ' . ($tp_list->[0]->{tp_id} || q{}));
#    #        }
#    #      }
#    #
#    #      $result = $self->_send_request({
#    #        ACTION => '/tariff/base/list',
#    #      });
#    #
#    #      $result = \@{$result->{result}};
#    #
#    #      $self->{FUNCTION_FIELDS} = "iptv_console:ADD:tariff_id;tariff_name:&TYPE="
#    #        . $type . "&tp_add=1&COMMENTS=1"
#    #        . (($attr->{SERVICE_ID}) ? "&SERVICE_ID=$attr->{SERVICE_ID}" : '');
#    #      $self->{REPORT_NAME} = 'TARIF_PLANS';
#    #    }
#  }
#  else {
#    my $type = 'list_activated';
#    $result = $self->_send_request({
#      ACTION => 'api/provider/devices/',
#    });
#
#    $result = \@{$result->{data}};
#    $self->{FUNCTION_FIELDS} = "iptv_console:DEL:uniq;customer_id:&TYPE="
#      . $type . "&del=1&COMMENTS=1"
#      . (($attr->{SERVICE_ID}) ? "&SERVICE_ID=$attr->{SERVICE_ID}" : '');
#    $self->{REPORT_NAME} = 'DEVICE';
#  }
#
#  my @menu = (
#    "$lang->{DEVICE}:index=$html->{index}&TYPE=list_activated&SERVICE_ID=$html->{HTML_FORM}->{SERVICE_ID}",
#    "$lang->{ADDED_TP}:index=$html->{index}&TYPE=channel_get_all&SERVICE_ID=$html->{HTML_FORM}->{SERVICE_ID}",
#    "$lang->{TARIF_PLANS}:index=$html->{index}&TYPE=get_channel_groups&SERVICE_ID=$html->{HTML_FORM}->{SERVICE_ID}",
#  );
#
#  $self->{REPORT} = $result;
#  $self->{MENU} = \@menu;
#
#  return 1;
#}

#**********************************************************
=head2 change_channels($attr)

=cut
#**********************************************************
sub change_channels {
  my $self = shift;
  my ($attr) = @_;

  my $Iptv = Iptv->new($self->{db}, $admin, $CONF);
  my $Base_tp = $Iptv->user_info($attr->{ID});

  my @Channel_array = ();
  my @Not_use_array = ();

  my @channels = split(/,/, $attr->{IDS});
  for my $channel (@channels) {
    my $chan_info = $Iptv->channel_info({
      ID => $channel,
    });
    if (!in_array($chan_info->{FILTER_ID}, \@Channel_array)) {
      push @Channel_array, $chan_info->{FILTER_ID};
    }
  }

  my $result = "";

  $result = $self->_send_request({
    ACTION => 'api/provider/account_subscriptions'
  });

  foreach my $element (@{$result->{data}}) {
    if ($attr->{SUBSCRIBE_ID} && $element->{account} eq $attr->{SUBSCRIBE_ID} && $element->{tarif} ne $Base_tp->{TP_FILTER_ID}) {
      if (!in_array($element->{tarif}, \@Channel_array)) {
        $self->_send_request(
          {
            ACTION  => "api/provider/account_subscriptions/" . $element->{id},
            COMMAND => "DELETE",
          }
        );
      }
      else {
        push @Not_use_array, $element->{tarif};
      }
    }
  }

  foreach my $element (@Channel_array) {
    if (!in_array($element, \@Not_use_array)) {
      user_sub($self, {
        SUBSCRIBE_ID => $attr->{SUBSCRIBE_ID},
        TARIFF       => $element,
      });
    }
  }

  return 1;
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

  if ($attr->{SUBSCRIBE_ID}) {
    $self->_send_request({
      ACTION => 'api/provider/accounts/' . $attr->{SUBSCRIBE_ID},
      PUT    => 1,
      PARAMS => {
        enabled => "0",
      },
    });
  }
  elsif ($attr->{UID}) {
    my $Iptv = Iptv->new($self->{db}, $admin, $CONF);
    my $user_info = $Iptv->user_info($attr->{ID});

    if ($user_info->{SUBSCRIBE_ID}) {
      $self->_send_request({
        ACTION => 'api/provider/accounts/' . $user_info->{SUBSCRIBE_ID},
        PUT    => 1,
        PARAMS => {
          enabled => "0",
        },
      });
    }
  }

  return 1;
}

1;


