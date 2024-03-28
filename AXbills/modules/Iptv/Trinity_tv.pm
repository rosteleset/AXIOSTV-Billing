
package Iptv::Trinity_tv;

=head1 NAME

  Trinity_tv module

  Trinity_tv HTTP API

  http://Trinity_tv/
  v.1.2

=head1 VERSION

  Version 9.00
  Revision: 20210203

=head1 SYNOPSIS

=cut

#**********************************************************

use strict;
use warnings FATAL => 'all';

our $VERSION = 0.61;

use parent qw(dbcore);
use AXbills::Base qw(load_pmodule mk_unique_value in_array urlencode convert);
use AXbills::Fetcher;
use Encode qw(decode_utf8);
my $MODULE = 'Trinity_tv';

my ($admin, $CONF);
my AXbills::HTML $html;
my $md5;
my $json;

#++********************************************************
# Init
#**********************************************************
sub new {
  my $class = shift;
  my $db = shift;
  $admin = shift;
  $CONF = shift;
  my $attr = shift;

  $admin->{MODULE} = $MODULE;

  $html = $attr->{HTML} if ($attr->{HTML});

  my $self = {};
  bless($self, $class);

  load_pmodule('Digest::MD5');
  load_pmodule('JSON');

  $md5 = Digest::MD5->new();
  $json = JSON->new->allow_nonref;
  $self->{SERVICE_NAME} = $MODULE;
  $self->{VERSION} = $VERSION;
  $self->{db} = $db;

  $self->{LOGIN} = $attr->{LOGIN} || q{};
  $self->{PASSWORD} = $attr->{PASSWORD} || q{};
  $self->{URL} = $attr->{URL} || q{};
  $self->{debug} = $attr->{DEBUG};
  $self->{DEBUG_FILE} = $attr->{DEBUG_FILE};

  $self->{request_count} = 0;

  return $self;
}

#**********************************************************
=head2 test($attr) - Test service

=cut
#**********************************************************
sub test {
  my $self = shift;

  my $result = $self->_send_request({
    ACTION => '/partners/user/subscriberlist',
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
=head2 user_del($attr)

  Arguments:
    $attr
      ID

  Results:
    $self

=cut
#**********************************************************
sub user_del {
  my $self = shift;
  my ($attr) = @_;

  my $local_id = $CONF->{TRINITY_USE_UID} ? $attr->{UID} : $attr->{ID};
  $self->_send_request({
    ACTION => '/partners/user/subscription',
    PARAMS => {
      localid     => $local_id,
      operationid => 'suspend',
    },
    hash   => $self->{LOGIN} . $local_id . 'suspend' . $self->{PASSWORD}
  });

  return $self;
}

#**********************************************************
=head2 user_add($attr)

   Arguments:
     $attr
       TP_NUM
       UID
       ID   - provider user id (iptv.id)
       PIN

   Results:

=cut
#**********************************************************
sub user_add {
  my $self = shift;
  my ($attr) = @_;

  $attr->{TP_NUM} = $attr->{TP_FILTER_ID} || $attr->{TP_NUM};

  my $local_id = $CONF->{TRINITY_USE_UID} ? $attr->{UID} : $attr->{ID};

  if (!$attr->{TP_NUM}) {
    $self->{errno} = '10100';
    $self->{errstr} = 'ERR_SELECT_TP';
    return $self;
  }

  my $operation = $attr->{STATUS} ? 'suspend' : 'resume';

  my $result = $self->_send_request({
    ACTION => '/partners/user/subscriptioninfo',
    PARAMS => {
      localid => $local_id
    },
    hash   => $self->{LOGIN} . $local_id . $self->{PASSWORD}
  });

  if (ref $result eq "HASH" && $result->{result} && $result->{result} eq 'success' && $result->{subscriptions}{subscrid}) {
    $self->_send_request({
      ACTION => '/partners/user/subscription',
      PARAMS => {
        localid     => $local_id,
        operationid => $operation,
      },
      hash   => $self->{LOGIN} . $local_id . $operation . $self->{PASSWORD}
    });
  }

  $result = $self->_send_request({
    ACTION => '/partners/user/create',
    PARAMS => {
      localid  => $local_id,
      subscrid => $attr->{TP_NUM},
    },
    hash   => $self->{LOGIN} . $local_id . $attr->{TP_NUM} . $self->{PASSWORD}
  });

  $attr->{retry} = $attr->{retry} || 0;
  if ($result->{result} && $result->{result} ne 'success' && $attr->{retry} < 3) {
    sleep(3);
    $attr->{retry} += 1;
    return $self->user_add($attr);
  }

  if ($result->{result} && $result->{result} ne 'success' && $attr->{retry} >= 3) {
    $self->{errno} = '10110';
    $self->{errstr} = $result->{result};
    return $self;
  }

  $self->_send_request({
    ACTION => '/partners/user/subscription',
    PARAMS => {
      localid     => $local_id,
      operationid => $operation,
    },
    hash   => $self->{LOGIN} . $local_id . $operation . $self->{PASSWORD}
  });


  #Reset PIN DB query
  if ($attr->{UID}) {
    $self->query("UPDATE iptv_main SET pin='' WHERE uid='$attr->{UID}';", 'do');
  }

  if ($attr->{CHANGE_TP}) {
    return $self;
  }

  if (!$self->{errno} && $attr->{CID}) {
    $self->mac_add($attr);
  }

  $attr->{STATUS} = 0;
  if (!$self->{errno} && $attr->{FIO}) {
    $self->user_change($attr);
  }

  # if (!$self->{errno} && $attr->{PIN}) {
  #   $self->pin_add($attr);
  # }

  return $self;
}

#**********************************************************
=head2 user_change($attr) Change personal data

  Arguments:
    $attr
      ID
      LOGIN
      CONTRACT_ID
      STATUS
      UID
      PIN

  Results:


=cut
#**********************************************************
sub user_change {
  my $self = shift;
  my ($attr) = @_;

  my $local_id = $CONF->{TRINITY_USE_UID} ? $attr->{UID} : $attr->{ID};

  #List send
  my $address_full = '-';                                        #$attr->{ADDRESS_FULL} || q{};
  my ($firstname, $lastname, $middlename) = split(/ /, '- - -'); #$attr->{FIO} || q{});

  if ($firstname eq '-') {
    $firstname = $attr->{LOGIN};
  }

  if ($lastname eq '-') {
    $firstname = $attr->{CONTRACT_ID} || $attr->{UID} || '-';
  }

  $firstname = urlencode($firstname || q{});
  $lastname = urlencode($lastname || q{});
  $middlename = urlencode($middlename || q{});

  my %params = (
    localid    => $local_id,
    firstname  => $firstname,
    lastname   => $lastname,
    middlename => $middlename,
    address    => $address_full
  );

  $attr->{CHANGE_TP} = 1 if ($attr->{TP_INFO_OLD} && $attr->{TP_INFO_OLD}{TP_ID});

  if ($attr->{CHANGE_TP}) {
    my $result = $self->user_add($attr);
    return $result;
  }

  #Reset DB query
  if ($attr->{UID}) {
    $self->query("UPDATE iptv_main SET pin='' WHERE uid='$attr->{UID}';", 'do');
  }

  my $result = $self->_send_request({
    ACTION => '/partners/user/updateuser',
    PARAMS => \%params,
    hash   => $self->{LOGIN} . $local_id . ($firstname || q{}) . ($lastname || q{}) . ($middlename || q{}) . $address_full . $self->{PASSWORD}
  });

  if ($attr->{STATUS}) {
    $self->user_del($attr);
  }

  if (!$self->{errno} && $attr->{CID}) {
    $self->mac_add($attr);
  }

  # if (!$self->{errno} && $attr->{PIN}) {
  #   $self->pin_add($attr);
  # }

  if ($attr->{OLD_STATUS} && !$attr->{STATUS}) {
    $self->_send_request({
      ACTION => '/partners/user/subscription',
      PARAMS => {
        localid     => $local_id,
        operationid => 'resume',
      },
      hash   => $self->{LOGIN} . $local_id . 'resume' . $self->{PASSWORD}
    });
  }

  return $result;
}

#**********************************************************
=head2 user_info($attr)

=cut
#**********************************************************
sub user_info {
  my $self = shift;
  my ($attr) = @_;

  my $local_id = $CONF->{TRINITY_USE_UID} ? $attr->{UID} : $attr->{ID};

  my $result = $self->_send_request({
    ACTION => '/partners/user/subscriptioninfo',
    PARAMS => {
      localid => $local_id
    },
    hash   => $self->{LOGIN} . $local_id . $self->{PASSWORD}
  });

  if ($result) {
    if ($result->{subscriptions}) {
      if (!$result->{subscriptions}->{subscrstatus}) {
        $self->{errno} = 404;
        $self->{errstr} = 'Not found';
      }
      elsif ($result->{subscriptions}->{subscrstatusid}) {
        $self->{errno} = $result->{subscriptions}->{subscrstatusid};
        $self->{errstr} = $result->{subscriptions}->{subscrstatus} || 'Blocked';
      }
    }
  }

  if ($result->{subscriptions} && $result->{subscriptions}{subscrname}) {
    my $hexstr = Encode::decode('UTF-8', $result->{subscriptions}{subscrname});
    $result->{subscriptions}{subscrname} = $hexstr;
  }

  if ($result->{subscriptions} && $result->{subscriptions}{subscrstatus}) {
    my $hexstr = Encode::decode('UTF-8', $result->{subscriptions}{subscrstatus});
    $result->{subscriptions}{subscrstatus} = $hexstr;
  }

  if ($result->{subscriptions} && $result->{subscriptions}{lastname}) {
    my $hexstr = Encode::decode('UTF-8', $result->{subscriptions}{lastname});
    $result->{subscriptions}{lastname} = $hexstr;
  }

  if ($result->{subscriptions} && $result->{subscriptions}{nextsubscrname}) {
    my $hexstr = Encode::decode('UTF-8', $result->{subscriptions}{nextsubscrname});
    $result->{subscriptions}{nextsubscrname} = $hexstr;
  }

  if ($result->{subscriptions} && $result->{subscriptions}{additionaltariff}) {
    my $hexstr = Encode::decode('UTF-8', $result->{subscriptions}{additionaltariff});
    $result->{subscriptions}{additionaltariff} = $hexstr;
  }

  $self->device_list($attr);
  $result->{mac} = $self->{result};

  $self->{RESULT}{results} = [ $result ];

  return $self;
}

#**********************************************************
=head2 user_list($attr)

=cut
#**********************************************************
sub user_list {
  my $self = shift;

  my $result = $self->_send_request({ ACTION => 'getUserList' });

  return $result;
}

#**********************************************************
=head2 _send_request($attr)

  Arguments:

  Results:

=cut
#**********************************************************
sub _send_request {
  my $self = shift;
  my ($attr) = @_;

  my $request_url = $self->{URL};
  my $result = '';
  my $params = $attr->{PARAMS};

  $params->{partnerid} = $self->{LOGIN};

  if ($attr->{ACTION}) {
    $request_url .= "$attr->{ACTION}";
  }

  if ($attr->{localid}) {
    $params->{localid} = $attr->{localid};
  }

  if ($attr->{requestid}) {
    $params->{requestid} = $attr->{requestid};
  }
  else {
    $params->{requestid} = mk_unique_value(5, { SYMBOLS => '1234567890' });
  }

  if (!$attr->{hash}) {
    $attr->{hash} = $params->{partnerid}
      . ($params->{localid} || q{})
      . $self->{PASSWORD};
  }

  $md5->reset;
  $md5->add($params->{requestid} . $attr->{hash});
  $params->{hash} = lc($md5->hexdigest());

  if ($attr->{MAC}) {
    $params->{mac} = $attr->{MAC};
  }

  if ($attr->{TYPE}) {
    $params->{type} = $attr->{TYPE};
  }

  if ($attr->{EMAIL}) {
    $params->{email} = $attr->{EMAIL};
  }

  if ($attr->{SUB_ID}) {
    $params->{sub_id} = $attr->{SUB_ID};
  }

  my $debug = (defined($attr->{DEBUG})) ? $attr->{DEBUG} : $self->{debug};
  if ($self->{DEBUG_FILE} && $debug < 2) {
    $debug = 2;
  }

  $request_url = $attr->{URL} if $attr->{URL};

  $self->{request_count}++;
  $result = web_request($request_url, {
    REQUEST_PARAMS => $params,
    GET            => 1,
    DEBUG          => $debug,
    DEBUG2FILE     => $self->{DEBUG_FILE},
    CURL           => 1,
    REQUEST_COUNT  => $self->{request_count}
  });

  return $result if $attr->{URL};

  my $perl_scalar;

  if ($result =~ /Timeout/) {
    $self->{errno} = 50;
    $self->{error} = 50;
    $self->{errstr} = "Timeout";
    return $result;
  }
  elsif ($result =~ /^{/) {
    delete $self->{status};
    delete $self->{errno};
    delete $self->{errstr};

    $perl_scalar = $json->decode($result);
    if ($perl_scalar->{status}) {
      $self->{status} = $perl_scalar->{status};
      $self->{errno} = $perl_scalar->{status};
      $self->{errstr} = $perl_scalar->{message};
    }
    elsif ($perl_scalar->{result} && !in_array($perl_scalar->{result}, [ 'successful', 'success' ])) {
      $self->{status} = $perl_scalar->{result};
      $self->{errno} = 10001;
      $self->{errstr} = $perl_scalar->{result};
      $self->{id} = $perl_scalar->{requestid};
    }

    $self->{hash} = $perl_scalar->{hash} if ($perl_scalar->{hash});
  }

  return $perl_scalar;
}

#**********************************************************
=head2 user_negdeposit($attr)

  Arguments:
    ID    - User service ID

  Results:
    $self

=cut
#**********************************************************
sub user_negdeposit {
  my $self = shift;
  my ($attr) = @_;

  $self->user_del($attr);

  return $self;
}

#**********************************************************
=head2 user_screens($attr)

  Arguments:
    $attr
      CID
      OLD_CID

  Returns:
    $self

=cut
#**********************************************************
sub user_screens {
  my $self = shift;
  my ($attr) = @_;

  if ($CONF->{IPTV_TRINITY_OLD}) {
    if ($attr->{del}) {
      if ($attr->{CID}) {
        $self->mac_del($attr);
      }
    }
    else {
      if ($attr->{OLD_CID} && $attr->{OLD_CID} ne $attr->{CID}) {
        $self->mac_del({ %$attr, CID => $attr->{OLD_CID} });
      }

      if ($attr->{CID} || $attr->{SERIAL}) {
        $self->mac_add($attr);
      }
      elsif ($attr->{PIN}) {
        $self->pin_add($attr);
      }
    }
  }
  else {
    if ($attr->{del}) {
      if ($attr->{CID} || $attr->{SERIAL}) {
        $self->device_del($attr);
      }
    }
    else {
      if ($attr->{OLD_CID} && $attr->{OLD_CID} ne $attr->{CID}) {
        $self->device_del({ %$attr, CID => $attr->{OLD_CID} });
      }

      if ($attr->{CID}) {
        $self->device_add($attr);
      }
      elsif ($attr->{PIN}) {
        $self->pin_add($attr);
      }
    }
  }

  return $self;
}

#**********************************************************
=head2 reports($attr)

=cut
#**********************************************************
sub reports {
  my $self = shift;

  my $result = $self->_send_request({
    ACTION => '/partners/user/subscriberlist',
  });

  my @report_list = ();

  foreach my $uid (keys %{$result->{subscribers}}) {
    my $uid_button = $self->account_exist($uid);
    $result->{subscribers}->{$uid}->{uid} = $uid_button || '';
    push @report_list, $result->{subscribers}->{$uid};
  }

  $self->{REPORT_NAME} = 'Subscribes';
  $self->{REPORT} = \@report_list;

  return $self;
}

#**********************************************************
=head2 pin_add($attr)

   Arguments:
     $attr
       ID
       PIN
       SCREEN_ID

   Results:
     $self

=cut
#**********************************************************
sub pin_add {
  my $self = shift;
  my ($attr) = @_;

  my $result = $self->mac_list($attr);
  my $mac_list = $self->{result} && $self->{result}{maclist} ? $self->{result}{maclist} : ();
  my $Iptv = Iptv->new($self->{db}, $admin, $CONF);

  my $user_screens = $Iptv->users_active_screens_list({
    SERVICE   => $attr->{ID},
    COLS_NAME => 1
  });
  my @active_screens = ();

  my $total = $Iptv->{TOTAL};
  if ($total > 0) {
    $Iptv->user_info($attr->{ID});
    if ($Iptv->{TOTAL}) {
      $Iptv->screens_list({ TP_ID => $Iptv->{TP_ID} });

      if ($total >= $Iptv->{TOTAL} || ($result->{RESULT}{results}[0]{subscriptions}{devicescount} &&
        $result->{RESULT}{results}[0]{subscriptions}{devicescount} >= $Iptv->{TOTAL})) {
        $self->{errno} = '10112';
        $self->{errstr} = 'Error add screen. No more screens available.';
        return $self;
      }
    }

    foreach my $screen (@{$user_screens}) {
      push @active_screens, $screen->{cid};
    }
  }

  my $local_id = $CONF->{TRINITY_USE_UID} ? $attr->{UID} : $attr->{ID};
  $result = $self->_send_request({
    ACTION => '/partners/user/autorizebycode',
    PARAMS => {
      localid => $local_id,
      code    => $attr->{PIN},
      note    => $attr->{COMMENT} || ''
    },
    hash   => $self->{LOGIN} . $local_id . $attr->{PIN} . $self->{PASSWORD}
  });

  return $self if (!$result || (!$result->{mac} && !$result->{uuid}));

  if ($mac_list && in_array($result->{mac}, $mac_list)) {
    $self->device_del({
      CID    => $result->{mac},
      SERIAL => $result->{uuid},
      ID     => $attr->{ID},
      UID    => $attr->{UID}
    });

    $self->{errno} = '10114';
    $self->{errstr} = 'Error add screen. Screen with this cid already exists.';
    return $self;
  }
  elsif (in_array($result->{mac}, \@active_screens)) {
    return $self;
  }

  if ($result) {
    $self->{SCREEN_ID} = $attr->{SCREEN_ID} || q{};
    $self->{CID} = $result->{mac} || q{};
    $self->{SERIAL} = $result->{uuid} || q{};
    $self->{COMMENT} = $attr->{COMMENT} || q{};
  }

  return $self;
}

#**********************************************************
=head2 mac_list($attr)

  Arguments:
    $attr
      ID
      LOGIN
      PASSWORD

=cut
#**********************************************************
sub mac_list {
  my $self = shift;
  my ($attr) = @_;

  my $local_id = $CONF->{TRINITY_USE_UID} ? $attr->{UID} : $attr->{ID};

  my $result = $self->_send_request({
    ACTION => '/partners/user/listmac',
    PARAMS => {
      localid => $local_id,
    },
    hash   => $self->{LOGIN} . $local_id . $self->{PASSWORD}
  });

  $self->{result} = $result;

  return $self;
}

#**********************************************************
=head2 mac_add($attr)

   Arguments:
     $attr
       ID
       CID

   Results:

=cut
#**********************************************************
sub mac_add {
  my $self = shift;
  my ($attr) = @_;

  my $local_id = $CONF->{TRINITY_USE_UID} ? $attr->{UID} : $attr->{ID};

  $attr->{CID} =~ s/://g;
  #$attr->{CID} =~ s/%3A//g;

  $self->_send_request({
    ACTION => '/partners/user/autorizemac',
    PARAMS => {
      localid => $local_id,
      mac     => $attr->{CID},
    },
    hash   => $self->{LOGIN} . $local_id . $attr->{CID} . $self->{PASSWORD}
  });

  #Reset DB query
  if ($attr->{UID}) {
    $self->query("UPDATE iptv_main SET pin='' WHERE uid='$attr->{UID}';", 'do');
  }

  return $self;
}

#**********************************************************
=head2 mac_del($attr)

  Arguemnts:
    $attr
      CID
      ID
      LOGIN
      PASSWORD

  Results:
    $self

=cut
#**********************************************************
sub mac_del {
  my $self = shift;
  my ($attr) = @_;

  my $local_id = $CONF->{TRINITY_USE_UID} ? $attr->{UID} : $attr->{ID};

  if (!$attr->{CID}) {
    return $self;
  }

  $attr->{CID} =~ s/://g;
  #$attr->{CID} =~ s/%3A//g;

  $self->_send_request({
    ACTION => '/partners/user/deletemac',
    PARAMS => {
      localid => $local_id,
      mac     => $attr->{CID},
    },
    hash   => $self->{LOGIN} . $local_id . $attr->{CID} . $self->{PASSWORD}
  });

  return $self;
}

#**********************************************************
=head2 mac_list($attr)

  Arguments:
    $attr
      ID
      LOGIN
      PASSWORD

=cut
#**********************************************************
sub conmac_list {
  my $self = shift;
  my ($attr) = @_;

  my $local_id = $CONF->{TRINITY_USE_UID} ? $attr->{UID} : $attr->{ID};

  my $result = $self->_send_request({
    ACTION => '/partners/user/listmac',
    PARAMS => {
      localid => $local_id,
    },
    hash   => $self->{LOGIN} . $local_id . $self->{PASSWORD}
  });

  $self->{result} = $result;

  return $self;
}

#**********************************************************
=head2 device_add($attr)

   Arguments:
     $attr
       ID
       CID

   Results:

=cut
#**********************************************************
sub device_add {
  my $self = shift;
  my ($attr) = @_;

  my $local_id = $CONF->{TRINITY_USE_UID} ? $attr->{UID} : $attr->{ID};

  my $result = $self->mac_list($attr);
  my $mac_list = $self->{result} && $self->{result}{maclist} ? $self->{result}{maclist} : ();

  my $Iptv = Iptv->new($self->{db}, $admin, $CONF);

  $Iptv->users_active_screens_list({
    SERVICE   => $attr->{ID},
    COLS_NAME => 1
  });

  my $trinity_total = $result->{RESULT} ? $result->{RESULT}{results}[0]{subscriptions}{devicescount} : $result->{result} ?
    @{$result->{result}{maclist}} : 0;

  my $total = $Iptv->{TOTAL};
  if ($total > 0) {
    $Iptv->user_info($attr->{ID});
    if ($Iptv->{TOTAL}) {
      $Iptv->screens_list({
        TP_ID => $Iptv->{TP_ID},
      });

      if ($total >= $Iptv->{TOTAL} || $trinity_total >= $Iptv->{TOTAL}) {
        $self->{errno} = '10112';
        $self->{errstr} = 'Error add screen. No more screens available.';
        return $self;
      }
    }
  }

  $attr->{CID} =~ s/://g;

  if (in_array($attr->{CID}, $mac_list)) {
    $self->{errno} = '10114';
    $self->{errstr} = 'Error add screen. Screen with this cid already exists.';
    return $self;
  }

  $result = $self->_send_request({
    ACTION => '/partners/user/autorizedevice_note',
    PARAMS => {
      localid => $local_id,
      mac     => $attr->{CID},
      note    => $attr->{COMMENT} || ''
    },
    hash   => $self->{LOGIN} . $local_id . $attr->{CID} . $self->{PASSWORD}
  });

  #Reset DB query
  if ($attr->{UID}) {
    $self->query("UPDATE iptv_main SET pin='' WHERE uid='$attr->{UID}';", 'do');
  }

  if (ref $result eq "HASH" && $result->{result} eq "success") {
    $self->{SCREEN_ID} = $attr->{SCREEN_ID} || q{};
    $self->{CID} = $attr->{CID} || q{};
    $self->{SERIAL} = $attr->{SERIAL} || q{};
    $self->{COMMENT} = $attr->{COMMENT} || q{};
  }

  return $self;
}

#**********************************************************
=head2 mac_list($attr)

  #/partners/user/deletedevice?requestid={requestid}&partnerid={partnerid}&localid={localid}&mac={mac}&uuid={uuid}&hash={hash}

  Arguments:
    $attr
      ID
      LOGIN
      SERIAL
      CID
      PASSWORD

  Results:
    $self

=cut
#**********************************************************
sub device_del {
  my $self = shift;
  my ($attr) = @_;

  my $local_id = $CONF->{TRINITY_USE_UID} ? $attr->{UID} : $attr->{ID};

  if (!$attr->{CID} && !$attr->{SERIAL}) {
    return $self;
  }

  $attr->{CID} =~ s/://g if $attr->{CID};
  #$attr->{CID} =~ s/%3A//g;

  my %params = (
    'localid' => $local_id,
  );
  if ($attr->{CID}) {
    $params{'mac'} = $attr->{CID} || q{};
  }
  if ($attr->{SERIAL}) {
    $params{'uuid'} = $attr->{SERIAL} || q{};
  }

  $self->_send_request({
    ACTION => '/partners/user/deletedevice',
    PARAMS => \%params,
    hash   => $self->{LOGIN} . $local_id . ($attr->{CID} || q{}) . ($attr->{SERIAL} || q{}) . $self->{PASSWORD}
  });

  return $self;
}

#**********************************************************
=head2 device_list($attr)

  Arguments:
    $attr
      ID
      LOGIN
      PASSWORD

=cut
#**********************************************************
sub device_list {
  my $self = shift;
  my ($attr) = @_;

  my $local_id = $CONF->{TRINITY_USE_UID} ? $attr->{UID} : $attr->{ID};

  my $result = $self->_send_request({
    ACTION => '/partners/user/devicelist',
    PARAMS => {
      localid => $local_id,
    },
    hash   => $self->{LOGIN} . $local_id . $self->{PASSWORD}
  });

  $self->{result} = $result;

  return $self;
}

#**********************************************************
=head2 get_playlist_m3u($attr)

=cut
#**********************************************************
sub get_playlist_m3u {
  my $self = shift;
  my ($attr) = @_;

  my $local_id = $CONF->{TRINITY_USE_UID} ? $attr->{UID} : $attr->{ID};

  my $result = $self->_send_request({
    ACTION => '/partners/user/getplaylist',
    PARAMS => {
      localid => $local_id,
    },
    hash   => $self->{LOGIN} . $local_id . $self->{PASSWORD}
  });

  return "" if (ref $result ne "HASH" && !$result->{playlist}{uuid});

  $result = $self->_send_request({
    URL => $result->{playlist}{uuid},
  });

  return $result;
}

#**********************************************************
=head2 account_exist($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub account_exist {
  my $self = shift;
  my ($id) = @_;

  my $Iptv = Iptv->new($self->{db}, $admin, $CONF);

  return '' if !$id;

  my $user_info = $Iptv->user_info($id);

  return '' if !$Iptv->{TOTAL};

  return $html->button($user_info->{UID}, "index=" . main::get_function_index('form_users') .
    "&UID=$user_info->{UID}");
}


1
