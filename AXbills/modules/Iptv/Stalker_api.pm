package Iptv::Stalker_api;

=head1 NAME

  Stalker managment functions

  Stalker_api;

=head1 VERSION

  VERSION: 1.60
  REVISION: 20200610

  API:
    http://wiki.infomir.eu/doku.php/stalker:rest_api_v1
    https://docs.google.com/document/d/1Q9aK62XSGEcvYMzlcJ2cIppZhwy824JuCtCfkiIJQu4/edit

=cut

use strict;
use warnings FATAL => 'all';
use AXbills::Base qw(load_pmodule);
use AXbills::Fetcher;

our $VERSION = 1.60;

my ($CONF, $admin);
my $MODULE = 'Stalker_api';

my $json;
my $lang;

#**********************************************************
# Init
#**********************************************************
sub new {
  my $class = shift;
  my $db = shift;
  $admin = shift;
  $CONF = shift;
  my $attr = shift;

  $admin->{MODULE} = $MODULE;
  $lang = $attr->{LANG} if ($attr->{LANG});

  my $self = {
    db              => $db,
    conf            => $CONF,
    admin           => $admin,
    SERVICE_CONSOLE => 'stalker_console',
    SEND_MESSAGE    => 1,
    SERVICE_NAME    => 'Stalker',
    VERSION         => $VERSION
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

  if ($self->{debug} && $self->{debug} > 5) {
    print "Content-Type: text/html\n\n";
  }

  return $self;
}


#**********************************************************
=head2 test($attr) - Test service

=cut
#**********************************************************
sub test {
  my $self = shift;
  #my ($attr) = @_;
  my $result = $self->get_users({ PAGE_ROWS => 1 });

  if (!$self->{errno}) {
    $result = 'Ok';
  }
  else {
    $result = 'Error';
  }

  return $result;
}


#**********************************************************
=head2 change_channels($attr)

=cut
#**********************************************************
sub change_channels {
  my $self = shift;
  my ($attr) = @_;

  my $uid = $attr->{ID} || $attr->{UID};
  my $Iptv = Iptv->new($self->{db}, $admin, $CONF);
  my %change_fields = ();

  $attr->{IDS} =~ s/\,/;/g;
  my $list = $Iptv->channel_list({
    NUM       => $attr->{IDS},
    PAGE_ROWS => 1000,
    COLS_NAME => 1
  });

  my $ids_line = "";
  foreach my $line (@{$list}) {
    $ids_line .= $line->{port} . "," if $line->{port};
  }

  if ($attr->{A_IDS}) {
    $attr->{A_IDS} =~ s/\,/;/g;
    $list = $Iptv->channel_list({
      ID        => $attr->{A_IDS},
      PAGE_ROWS => 1000,
      COLS_NAME => 1
    });

    foreach my $line (@{$list}) {
      $ids_line .= $line->{port} . "," if $line->{port};
    }
  }

  chop($ids_line);

  $change_fields{ACTION} = "itv_subscription/$uid";
  $change_fields{COMMAND} = 'PUT';
  $change_fields{sub_ch} = $ids_line || $attr->{IDS} || '';
  $change_fields{additional_services_on} = 1;

  $self->_send_request({
    %change_fields
  });

  return $self;
}

#**********************************************************
=head2 get_channels()

=cut
#**********************************************************
sub get_channels {
  my $self = shift;

  return $self;
}

#**********************************************************
=head2 _send_request($attr)

  Arguments:
    $attr
      COMMAND - Extra commands


=cut
#**********************************************************
sub _send_request {
  my $self = shift;
  my ($attr) = @_;

  my $request_proto = 'http://';
  if ($self->{URL}) {
    if ($self->{URL} =~ s/http:\/\///) {
      $request_proto = $1 || q{};
    }
    if ($self->{URL} =~ s/https:\/\///) {
      $request_proto = $1 || q{};
    }
  }

  if (!$self->{LOGIN} || !$self->{PASSWORD} || !$self->{URL}) {
    $self->{errno} = 1999;
    $self->{error} = 1;
    $self->{errstr} = "Not defined LOGIN / PASSWORD / URL";
    return q{};
  }

  my $debug = (defined($attr->{DEBUG})) ? $attr->{DEBUG} : $self->{debug};
  if ($self->{DEBUG_FILE} && $debug < 2) {
    $debug = 2;
  }

  my $request_url = "$request_proto$self->{LOGIN}:$self->{PASSWORD}\@$self->{URL}";

  delete($self->{errno});
  delete($self->{error});
  delete($self->{errstr});

  if ($attr->{ACTION}) {
    $request_url .= "$attr->{ACTION}";
  }

  my $request = '';
  my @request_fields = (
    'account_balance',
    'account_number',
    'login',
    'password',
    'full_name',
    'tariff_plan',
    'status',
    'stb_mac',
    'msg',
    'event',
    'sub_ch',
    'additional_services_on'
  );

  my %request_params = ();
  foreach my $key (@request_fields) {
    if (defined($attr->{$key})) {
      if ($key eq 'sub_ch') {
        foreach my $value (split(/,\s?/, $attr->{$key})) {
          $request .= '&' . $key . '[]=' . $value;
          push @{$request_params{$key . '[]'}}, $value;
        }
      }
      else {
        $request .= "&$key=$attr->{$key}";
        $request_params{$key} = $attr->{$key};
      }
    }
  }

  my $result = web_request($request_url, {
    REQUEST_PARAMS => \%request_params, #$params,
    #POST           =>  $request,
    DEBUG          => $debug,
    DEBUG2FILE     => $self->{DEBUG_FILE},
    CURL           => 1,
    REQUEST_COUNT  => $self->{request_count},
    CURL_OPTIONS   => ($attr->{COMMAND}) ? "-X $attr->{COMMAND}" : undef,
    JSON_RETURN    => 1
  });

  $result = $attr->{_RESULT} if ($attr->{_RESULT});

  if ($result =~ /API not enabled/) {
    $self->{errno} = 3;
    $self->{error} = 3;
    $self->{errstr} = "API Not enabled";
    return $result;
  }
  elsif ($result =~ /Timeout/) {
    $self->{errno} = 50;
    $self->{error} = 50;
    $self->{errstr} = "Timeout";
    return $result;
  }
  elsif ($result =~ /Not Found/) {
    $self->{errno} = 4;
    $self->{error} = 4;
    $self->{errstr} = "Not Found";
    return $result;
  }

  return 0 if (!$result);

  my $perl_scalar = $result;
  #$json->decode( $result );
  if ($perl_scalar->{errno}) {
    $self->{errno} = '110' . $perl_scalar->{errno};
    $self->{error} = $perl_scalar->{errno};
    $self->{errstr} = $perl_scalar->{errstr};
  }
  elsif ($perl_scalar->{status} && $perl_scalar->{status} eq 'ERROR') {
    $self->{errno} = 1000;
    $self->{error} = 1;
    $self->{errstr} = $perl_scalar->{error};
  }

  $self->{RESULT} = $perl_scalar;

  return $result;
}

#**********************************************************
=head2 send_message($attr) - Send message to Set to box

  Arguments:
    UID
    MESSAGE

=cut
#**********************************************************
sub send_message {
  my $self = shift;
  my ($attr) = @_;

  $self->_send_request({
    ACTION => 'stb_msg/' . ($attr->{ID} || $attr->{UID}),
    msg    => $attr->{MESSAGE},
  });

  return $self;
}


#**********************************************************
=head2 get_users()

=cut
#**********************************************************
sub get_users {
  my $self = shift;

  $self->_send_request({
    ACTION => 'accounts',
  });

  return $self;
}

#**********************************************************
=head2 user_negdeposit($attr)

  Argumnets:
    $attr

  Results:
    $self

=cut
#**********************************************************
sub user_negdeposit {
  my $self = shift;
  my ($attr) = @_;

  if (!$CONF->{IPTV_STALKER_SINGLE_ACCOUNT}) {
    if ($attr->{LOGIN} && $attr->{ID}) {
      $attr->{BASE_LOGIN} = $attr->{LOGIN};
      $attr->{LOGIN} = $attr->{LOGIN} . '_' . $attr->{ID};
    }
  }

  $attr->{change} = 1;

  $self->user_action($attr);

  return $self;
}

#**********************************************************
=head2 subscribe_del($attr)

=cut
#**********************************************************
sub subscribe_del {
  my $self = shift;
  my ($attr) = @_;

  $self->user_action($attr);

  if ($self->{error}) {
    if ($self->{errstr} =~ /Account not found/) {
      delete $self->{error};
    }
  }

  return $self;
}

#**********************************************************
=head2 subscribe_info($attr)

=cut
#**********************************************************
sub subscribe_info {
  my $self = shift;
  my ($attr) = @_;

  $self->user_action($attr);

  return $self;
}

#**********************************************************
=head2 subscribe_change($attr)

=cut
#**********************************************************
sub subscribe_change {
  my $self = shift;
  my ($attr) = @_;

  $self->user_action($attr);

  return $self;
}


#**********************************************************
=head2 change_channels($attr)

  Arguments:
    $attr
      ID         => 'account_number',
      LOGIN      => 'login',
      PASSWORD   => 'password',
      FIO        => 'full_name',
      TP_NUM     => 'tariff_plan',
      STATUS     => 'status',
      FILTER_ID  => '',
      PIN        => '',
      VOD        => '',
      DVCRYPT_ID => '',
      CID        => 'stb_mac'

      MAIN_ACCOUNT_KEY   - User option for main account key

      change

  Retunrs:

=cut
#**********************************************************
sub user_action {
  my $self = shift;
  my ($attr) = @_;

  my %FIELDS = (
    ID         => 'account_number',
    DEPOSIT    => 'account_balance',
    #    UID        => 'account_number',
    LOGIN      => 'login',
    PASSWORD   => 'password',
    FIO        => 'full_name',
    TP_NAME     => 'tariff_plan',
    STATUS     => 'status',
    FILTER_ID  => '',
    PIN        => '',
    VOD        => '',
    DVCRYPT_ID => '',
    CID        => 'stb_mac'
  );

  my %change_fields = ();

  while (my ($key, $val) = each %FIELDS) {
    if ($attr->{$key}) {
      if ($key eq "DEPOSIT") {
        $attr->{$key} = sprintf("%.2f", $attr->{$key});
      }
      $change_fields{$val} = $attr->{$key};
    }
  }
  #  status - (1 - Active, 0 - Disable)
  if (defined($attr->{STATUS})) {
    $change_fields{status} = (!$attr->{STATUS}) ? 1 : 0;
  }
  elsif ($attr->{NEGDEPOSIT}) {
    $change_fields{status} = 0;
  }

  #stb_sn - �������� ����� ����������.
  #stb_type - ������ ����������.
  #subscribed - ������ ��������������� ������������ �������, �� ������� ���� ��������.
  my $uid = $change_fields{account_number} || $change_fields{stb_mac} || 0;

  if ($attr->{MAIN_ACCOUNT_KEY}) {
    $uid = $change_fields{$attr->{MAIN_ACCOUNT_KEY}} || 0;
  }

  if ($attr->{STATUS} && $attr->{STATUS} == 2) {
    %change_fields = ();
    $change_fields{ACTION} = "accounts/$uid";
    $change_fields{COMMAND} = 'DELETE';
  }
  elsif ($attr->{del}) {
    if (!$uid && $attr->{MAC}) {
      $uid = $attr->{MAC};
    }
    $change_fields{ACTION} = "accounts/$uid";
    $change_fields{COMMAND} = 'DELETE';
  }
  #/users/1/ping
  elsif ($attr->{PING}) {
    $change_fields{ACTION} = "user/$uid";
    $change_fields{COMMAND} = 'ping';
  }
  elsif ($attr->{change}) {
    $change_fields{ACTION} = "accounts/" . ($attr->{CID_ID} || $uid);
    $change_fields{COMMAND} = 'PUT';
    if (!$attr->{MAIN_ACCOUNT_KEY} && $attr->{CID_ID}) {
      delete($change_fields{account_number});
    }
    #delete($change_fields{password});
  }
  else {
      $change_fields{ACTION} = 'accounts',
      $change_fields{COMMAND} = 'POST';
  }

  if (defined $attr->{STATUS} && $attr->{STATUS} && $attr->{change}) {
    %change_fields = ();
    $change_fields{ACTION} = "accounts/" . ($attr->{CID_ID} || $uid);
    $change_fields{COMMAND} = 'PUT';
    $change_fields{status} = 0;
  }


  $self->_send_request(\%change_fields);

  return $self;
}

#**********************************************************
=head2 user_add($attr)

  Arguments:
    $attr
      LOGIN
      ID

  Returns:
    $self

=cut
#**********************************************************
sub user_add {
  my $self = shift;
  my ($attr) = @_;

  if (!$CONF->{IPTV_STALKER_SINGLE_ACCOUNT}) {
    if ($attr->{LOGIN} && $attr->{ID}) {
      $attr->{BASE_LOGIN} = $attr->{LOGIN};
      $attr->{LOGIN} = $attr->{LOGIN} . '_' . $attr->{ID};
    }
  }

  $self->user_action($attr);
  if ($self->{errstr}) {
    if ($self->{errstr} eq 'ACCOUNT_NOT_FOUND') {
      delete $attr->{change};
      $self->user_action(
        {
          %{$attr},
          add => 1,
        }
      );
    }
    elsif ($self->{errstr} eq 'Login already in use') {
      delete $attr->{add};
      $self->user_action(
        {
          %{$attr},
          change => 1,
          STATUS => 0,
        }
      );
    }
  }

  if ($self->{errstr} && $self->{errstr} eq 'MAC address already in use') {
    $attr->{CID_ID} = $attr->{CID};
    delete $attr->{CID};
    $self->user_info({
      %{$attr},
    });
    if (!$self->{RESULT}{results}[0]{login} && !$self->{RESULT}{results}[0]{status}) {
      $self->user_change({
        %{$attr},
      });
    }
  }

  #add user channels
  if ($attr->{CHANNELS}) {
    $self->change_channels(
      {
        ID  => $attr->{ID},
        IDS => $attr->{CHANNELS}
      }
    );
  }

  return $self;
}

#**********************************************************
=head2 user_info($attr)

=cut
#**********************************************************
sub user_info {
  my $self = shift;
  my ($attr) = @_;

  my $result = $self->_send_request({
    ACTION => "accounts/" . ($attr->{CID_ID} || $attr->{ID} || $attr->{UID}),
  });

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

  $attr->{change} = 1;
  my $login = $attr->{LOGIN};
  $self->user_add($attr);

  if ($self->{errno} && $self->{errno} == 1000) {
    delete $attr->{change};
    $attr->{LOGIN} = $login;
    $self->user_add($attr);
  }

  return $self;
}

#**********************************************************
=head2 user_del($attr)

=cut
#**********************************************************
sub user_del {
  my $self = shift;
  my ($attr) = @_;

  $self->subscribe_del({ %{$attr}, del => 1 });

  return $self;
}

#**********************************************************
=head2 hangup($attr)

=cut
#**********************************************************
sub hangup {
  my $self = shift;
  my ($attr) = @_;

  my $event = $attr->{REBOOT} ? 'reboot' : 'cut_off';
  $self->_send_request({
    ACTION => "send_event/" . ($attr->{ID} || $attr->{UID}),
    event  => $event,
  });

  return $self;
}

#**********************************************************
=head2 tp_export()

=cut
#**********************************************************
sub tp_export {
  my $self = shift;

  my $result = $self->_send_request({
    ACTION => "tariffs/",
  });


  $self->{TP_LIST} = 1;

  my @tps = ();
  if ($result) {
    foreach my $tp (@{$result->{results}}) {

     my $tp_name = $tp->{name};
     my $is_utf = Encode::is_utf8($tp_name);

    if ($is_utf) {
      Encode::_utf8_off($tp_name);
    }


      #if ($tp->{name}) {
      #  my $hexstr = Encode::decode('UTF-8', $tp->{name});
      #  $tp->{name} = $hexstr;
      #}      

      push @tps, {
        ID       => $tp->{id},
        NAME     => $tp_name,
        COMMENTS => $tp->{description}
      };
    }
  }


  return \@tps;
}

#**********************************************************
=head2 get_iptv_portal_extra_fields($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub get_iptv_portal_extra_fields {
  my $self = shift;
  my ($attr) = @_;

  my @extra_fields = ();

  my $user_info = $self->user_info($attr);

  return \@extra_fields if !$user_info->{RESULT} || !$user_info->{RESULT}{results} || ref $user_info->{RESULT}{results} ne 'ARRAY'
    || !$user_info->{RESULT}{results}[0] || !$user_info->{RESULT}{results}[0]{login};

  push @extra_fields, {
    id    => $user_info->{RESULT}{results}[0]{login},
    name  => 'IPTV ' . ($lang->{LOGIN} || 'Login'),
    value => $user_info->{RESULT}{results}[0]{login}
  };

  return \@extra_fields;
}


1
