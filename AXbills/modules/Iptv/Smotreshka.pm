package Iptv::Smotreshka;

=head1 NAME

  Smotreshka module


=head1 VERSION

  Version 0.24
  Revision: 20190730

=head1 SYNOPSIS

=cut

#**********************************************************

use strict;
use warnings FATAL => 'all';

our $VERSION = 0.24;

use parent 'dbcore';
use AXbills::Base qw(load_pmodule mk_unique_value in_array);
use AXbills::Fetcher;
use Encode;
use Iptv;
use utf8;
my $MODULE = 'Smotreshka';
my %services = ();

my ($admin, $CONF);
my $md5;
my $json;
my $html;

#**********************************************************
# Init
#**********************************************************
sub new {
  my $class = shift;
  my $db = shift;
  $admin = shift;
  $CONF = shift;
  my $attr = shift;

  if ($attr->{HTML}) {
    $html = $attr->{HTML};
  }

  $admin->{MODULE} = $MODULE;

  my $self = {};
  bless($self, $class);

  $self->{db} = $db;
  $self->{admin} = $admin;
  $self->{conf} = $CONF;

  load_pmodule('Digest::MD5');
  load_pmodule('JSON');

  $md5 = Digest::MD5->new();
  $json = JSON->new->allow_nonref;
  $self->{SERVICE_NAME} = $MODULE;
  $self->{VERSION} = $VERSION;

  #  $self->{SERVICE_USER_FORM}          = 'olltv_user';
  #  $self->{SERVICE_USER_SCREEN_FORM}   = 'olltv_screens';
  #  $self->{SERVICE_USER_CHANNELS_FORM} = 'olltv_sub';
  #  $self->{SERVICE_CONSOLE}            = 'olltv_console';

  #$self->{SERVICE_TP_EXPORT}           = 'olltv_console';

  $self->{LOGIN} = $attr->{LOGIN};
  $self->{PASSWORD} = $attr->{PASSWORD};
  $self->{URL} = $attr->{URL};
  $self->{DEBUG_FILE} = $attr->{DEBUG_FILE} || '';
  $self->{debug} = $attr->{DEBUG} || 0;

  if ($self->{debug} && $self->{debug} > 5) {
    print "Content-Type: text/html\n\n";
  }

  $self->{request_count} = 0;

  return $self;
}

#**********************************************************
=head2 service_info($attr) - Test service

  Arguments:
    $attr
      $attr
        FILTER_ID

  Results:
    $info

=cut
#**********************************************************
sub service_info {
  my $self = shift;
  my ($attr) = @_;

  my $result = $self->_send_request({
    ACTION => '/v2/subscriptions',
  });

  if (!%services && $result && ref $result eq 'ARRAY') {
    foreach my $line (@$result) {
      next if (!$line->{id});
      my $count = 0;
      my $channels = $line->{channels};

      $services{$line->{id}} .= '<div>';
      foreach my $channal_info (@{$channels}) {
        $services{$line->{id}} .= $html->element('div', $html->img($channal_info->{image}, '', { class => 'img-thumbnail' }),
          { class => 'col-md-2', OUTPUT2RETURN => 1 });
        Encode::_utf8_off($services{$line->{id}});
        if ($count % 4) {
          $services{$line->{id}} .= '</div><div>';
        }
        $count++;
      }
      $services{$line->{id}} .= '</div>';
    }
  }

  my $info = $services{$attr->{FILTER_ID}};

  return $info;
}

#**********************************************************
=head2 test($attr) - Test service

=cut
#**********************************************************
sub test {
  my $self = shift;
  #my ($attr) = @_;

  my $result = $self->user_list({ PAGE_ROWS => 1 });

  if (!$self->{errno} && ref $result eq 'ARRAY') {
    $result = 'Ok';
  }
  else {
    $self->{errno} = 1005;
    $result = 'Error';
  }

  return $result;
}

#**********************************************************
=head2 user_del($attr)

=cut
#**********************************************************
sub user_del {
  my $self = shift;
  my ($attr) = @_;

  if (!$attr->{SUBSCRIBE_ID}) {
    if ($self->{debug}) {
      print "Subscribe id not defined\n";
    }

    return $self;
  }

  $self->_send_request({
    ACTION  => '/v2/accounts/' . $attr->{SUBSCRIBE_ID},
    COMMAND => 'DELETE'
  });

  return $self;
}

#**********************************************************
=head2 user_add($attr)

  Arguments:
    $attr
      EMAIL
      LOGIN
      FILTER_ID || TP_FILTER_ID
      UID
      ID
      PASSWORD

  Results:
    $self

=cut
#**********************************************************
sub user_add {
  my $self = shift;
  my ($attr) = @_;

  $attr->{EMAIL} ||= $attr->{EMAIL_ALL};
  if (!$attr->{EMAIL}) {
    $self->{errno} = 1004;
    $self->{errstr} = 'EMAIL_NOT_DEFINED';
    return $self;
  }
  my $tp_id = $attr->{FILTER_ID} || $attr->{TP_FILTER_ID};

  if (!$tp_id) {
    $self->{errno} = 1005;
    $self->{errstr} = 'TP_NOT_DEFINED';
    return $self;
  }

  my %request = (
    username  => ($CONF->{SMOTRESHKA_PREFIX} || "") . ($attr->{LOGIN} || $attr->{EMAIL}),
    email     => $attr->{EMAIL},
    purchases => [ $tp_id ],
    info      => { "USER_ID" => $attr->{ID}, "LOGIN" => ($CONF->{SMOTRESHKA_PREFIX} || "") . $attr->{LOGIN}, UID => $attr->{UID} }
  );

  if ($attr->{PASSWORD} && !$CONF->{IPTV_SMOTRESHKA_SKIP_PASSWORD}) {
    $request{password} = $attr->{PASSWORD};
  }

  # Create
  my $result = $self->_send_request({
    ACTION              => '/v2/accounts',
    POST                => 1,
    REQUEST_PARAMS_JSON => \%request,
  });

  if (!$result) {
    $self->{errno} = 1;
    $self->{errstr} = "USER_NOT_CREATED ";
    return $self;
  }

  if (defined $result->{created} && $result->{id}) {
    $self->{SUBSCRIBE_ID} = $result->{id};
    $attr->{SUBSCRIBE_ID} = $self->{SUBSCRIBE_ID};
    $attr->{FILTER_ID} = $tp_id;
    my $sub_result = $self->subscriptions_add($attr);

    if ($sub_result && $sub_result->{error}) {
      $self->{errno} = 1005;
      $self->{errstr} = "USER_NOT_CREATED: " . $sub_result->{error};
    }
  }
  elsif ($result->{error} && $result->{error} =~ /invalid email/) {
    $self->{errno} = 1000;
    $self->{errstr} = $result->{error};
  }
  elsif ($result->{error} && $result->{error} =~ /Username already exists/) {
    $self->{errno} = 1002;
    $self->{errstr} = $result->{id};
    $self->{id} = $attr->{ID};
  }
  else {
    $self->{errno} = 1003;
    $self->{errstr} = $result->{error};
  }

  return $self;
}

#**********************************************************
=head2 user_change($attr) Change personal data

  Arguments:
    $attr
      LOGIN
      EMAIL
      PASSWORD
      STATUS
      ID
      UID

  Results:
    $result

=cut
#**********************************************************
sub user_change {
  my $self = shift;
  my ($attr) = @_;

  #List send
  $attr->{FIO} = '1';
  $attr->{ADDRESS_FULL} = '1';

  $attr->{FILTER_ID} = $attr->{TP_FILTER_ID};

  if ($attr->{STATUS}) {
    delete($attr->{FILTER_ID});
    delete($attr->{TP_FILTER_ID});
  }

  $self->subscriptions_change($attr);

  #  if($attr->{STATUS}) {
  #    $self->user_del($attr);
  #  }
  #
  #  if(! $self->{errno} && $attr->{CID}) {
  #    $self->mac_add($attr);
  #  }
  #
  #  if(! $self->{errno} && $attr->{PIN}) {
  #    $self->pin_add($attr);
  #  }

  return $self;
}

#**********************************************************
=head2 user_info($attr)

  Arguments:
    $attr

  Returns:

=cut
#**********************************************************
sub user_info {
  my $self = shift;
  my ($attr) = @_;

  my $result = $self->_send_request({
    ACTION => '/v2/accounts/' . $attr->{SUBSCRIBE_ID},
  });

  if ($self->{errstr}) {
    if ($self->{errstr} =~ /not found/) {
      $self->{errno} = 404;
    }
    else {
      $self->{errno} = 1404;
    }
    return $self;
  }
  elsif ($result && $result->{id}) {
    $self->{$result->{id}} = $result;
  }

  my $subcribes = $self->subscriptions({ SUBSCRIBE_ID => $attr->{SUBSCRIBE_ID} });
  $result->{subcribes} = $subcribes;

  if ($self->{errstr}) {
    if ($self->{errstr} =~ /not found/) {
      $self->{errno} = 404;
    }
    else {
      $self->{errno} = 1404;
    }
  }

  $self->{RESULT}->{results} = [ $result ];

  #  if($result) {
  #    if($result->{subscriptions}) {
  #      if (!  $result->{subscriptions}->{subscrstatus} ) {
  #        $self->{errno}=404;
  #        $self->{errstr}='Not found';
  #      }
  #      elsif($result->{subscriptions}->{subscrstatusid}) {
  #        $self->{errno}=$result->{subscriptions}->{subscrstatusid};
  #        $self->{errstr}=$result->{subscriptions}->{subscrstatus} || 'Blocked';
  #      }
  #    }
  #  }

  return $self;
}

#**********************************************************
=head2 user_list($attr)

  Arguments:
    $attr
      EMAIL
      PAGE_ROWS

  Returns:


=cut
#**********************************************************
sub user_list {
  my $self = shift;
  my ($attr) = @_;

  my $pages = -1;
  if ($attr->{PAGE_ROWS}) {
    $pages = $attr->{PAGE_ROWS};
  }

  my $result = $self->_send_request({ ACTION => '/v2/accounts?page_size=' . $pages });

  if ($attr->{EMAIL} && $result) {
    foreach my $user (@{$result->{accounts}}) {
      if ($user->{email} eq lc $attr->{EMAIL}) {
        return $user->{id};
      }
    };

    return 0;
  }

  return ($result) ? $result->{accounts} : [];
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

  $request_url =~ s/\/$//;
  if ($attr->{ACTION}) {
    $request_url .= "$attr->{ACTION}";
  }

  if ($attr->{localid}) {
    $params->{localid} = $attr->{localid};
  }

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

  $self->{request_count}++;

  if ($self->{DEBUG_FILE}) {
    $self->{DEBUG_FILE} =~ s/\///g;
    $self->{DEBUG_FILE} = '/usr/axbills/var/log/' . $self->{DEBUG_FILE};
  }

  $result = web_request($request_url, {
    JSON_ARRAY_VARS     => 1,
    REQUEST_PARAMS      => $params,
    GET                 => ($attr->{POST}) ? undef : 1,
    REQUEST_PARAMS_JSON => $attr->{REQUEST_PARAMS_JSON},
    DEBUG               => $debug,
    DEBUG2FILE          => $self->{DEBUG_FILE},
    CURL_OPTIONS        => ($attr->{COMMAND}) ? "-X $attr->{COMMAND}" : undef,
    CURL                => 1,
    REQUEST_COUNT       => $self->{request_count},
    TIMEOUT => 20
  });

  my $perl_scalar;

  if ($result =~ /^{|^\[/) {
    delete $self->{status};
    delete $self->{errno};
    delete $self->{errstr};
    $perl_scalar = $json->decode($result);

    if (ref $perl_scalar eq 'HASH') {
      if ($perl_scalar->{status}) {
        $self->{status} = $perl_scalar->{status};
        $self->{errno} = $perl_scalar->{status};
        $self->{errstr} = $perl_scalar->{message};
      }
      elsif ($perl_scalar->{error}) {
        $self->{status} = $perl_scalar->{status};
        $self->{errno} = 1;
        $self->{errstr} = $perl_scalar->{error};
      }
      elsif ($perl_scalar->{result} && !in_array($perl_scalar->{result}, [ 'successful', 'success' ])) {
        $self->{status} = $perl_scalar->{result};
        $self->{errno} = 1;
        $self->{errstr} = $perl_scalar->{result};
      }

      $self->{hash} = $perl_scalar->{hash} if ($perl_scalar->{hash});
    }
  }
  elsif ($result =~ /^Timeout/) {
    $self->{status} = 'Timeout';
    $self->{errno} = 10000;
    $self->{errstr} = 'Timeout';
  }

  $perl_scalar //= '';

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

  $attr->{STATUS} = 5;

  $self->user_change($attr);

  return $self;
}

#**********************************************************
=head2 user_screens($attr)

=cut
#**********************************************************
sub user_screens {
  my $self = shift;
  my ($attr) = @_;

  if ($attr->{del}) {
    if ($attr->{CID}) {
      $self->mac_del($attr);
    }
  }
  else {
    if ($attr->{CID}) {
      $self->mac_add($attr);
    }
  }

  return $self;
}

#**********************************************************
=head2 tp_export($attr)

=cut
#**********************************************************
sub tp_export {
  my $self = shift;

  my $result = $self->_send_request({
    ACTION => '/v2/subscriptions',
  });

  my @tps = ();
  if ($result) {
    foreach my $tp (@$result) {
      Encode::_utf8_off($tp->{name});
      push @tps, {
        ID   => $tp->{id} || 0,
        NAME => $tp->{name}
      };
    }
  }

  return \@tps;
}

#**********************************************************
=head2 reports($attr)

  Arguments:
    $attr
      TYPE

  $results:

=cut
#**********************************************************
sub reports {
  my $self = shift;
  my ($attr) = @_;

  my $result;

  if ($attr->{TYPE}) {
    if ($attr->{TYPE} eq 'users') {
      if ($attr->{del}) {
        $self->user_del({ SUBSCRIBE_ID => $attr->{ID} });
      }

      $result = $self->user_list();
      $self->{FUNCTION_FIELDS} = "iptv_console:DEL:id:&TYPE="
        . ($attr->{TYPE} || '') . "&del=1&COMMENTS=1"
        . (($attr->{SERVICE_ID}) ? "&SERVICE_ID=$attr->{SERVICE_ID}" : '');
      #":$lang{DEL}:MAC:&del=1&COMMENTS=del",
    }
    elsif ($attr->{TYPE} eq 'import') {
      $result = $self->user_list();
      use AXbills::Base;
      my %users_info = ();
      foreach my $line (@$result) {
        #print "$line->{username}  	$line->{id} <br>";
        $users_info{$line->{username}}{id} = $line->{id};
        $users_info{$line->{username}}{email} = $line->{email};
        $self->subscriptions({ SUBSCRIBE_ID => $line->{id} });
        if ($self->{subcribes}) {
          foreach my $info (@{$self->{subcribes}}) {
            $users_info{$line->{username}}{subscribe} = $info->{id} || q{};
          }
        }
      }

      use Users;
      use Tariffs;
      use Iptv;
      my $Users = Users->new($self->{db}, $self->{admin}, $self->{conf});
      my $Tv = Iptv->new($self->{db}, $self->{admin}, $self->{conf});
      my $Tariffs = Tariffs->new($self->{db}, $self->{conf}, $self->{admin});

      my $tp_list = $Tariffs->list({
        FILTER_ID => '_SHOW',
        COLS_NAME => 1
      });

      my %tp_dilter_ids = ();
      foreach my $line (@$tp_list) {
        $tp_dilter_ids{$line->{filter_id}} = $line->{tp_id};
      }

      foreach my $login (keys %users_info) {
        Encode::_utf8_off($login);
        my $list = $Users->list({
          LOGIN     => $login || '-',
          COLS_NAME => 1
        });

        if ($Users->{TOTAL} == 1) {
          my $uid = $list->[0]->{uid};

          if ($self->{debug}) {
            #            print "
            #            UID          => $uid,
            #            SUBSCRIBE_ID => $users_info{$login}{id},
            #            SERVICE_ID   => $html->{HTML_FORM}->{SERVICE_ID},
            #            TP_ID        => $users_info{$login}{subscribe},
            #            EMAIL        => $users_info{$login}{email},
            #            ";
            #            if($users_info{$login}{subscribe}) {
            #              print "TP_ID =>  ".($users_info{$login}{subscribe} && $tp_dilter_ids{$users_info{$login}{subscribe}}) ? $tp_dilter_ids{$users_info{$login}{subscribe}} : q{};
            #            }
            #            print '<br>';
          }

          my $tv_user_list = $Tv->user_list({
            SUBSCRIBE_ID => $users_info{$login}{id},
            UID          => '_SHOW',
            COLS_NAME    => 1
          });

          if ($Tv->{TOTAL} < 1) {
            $Tv->user_add({
              UID          => $uid,
              SUBSCRIBE_ID => $users_info{$login}{id},
              SERVICE_ID   => $html->{HTML_FORM}->{SERVICE_ID},
              TP_ID        => ($users_info{$login}{subscribe} && $tp_dilter_ids{$users_info{$login}{subscribe}}) ? $tp_dilter_ids{$users_info{$login}{subscribe}} : undef,
              EMAIL        => $users_info{$login}{email},
            });

          }
          else {
            print "Exists id: $tv_user_list->[0]->{id} UID: $tv_user_list->[0]->{uid}\n";
          }
        }
        else {
          print "Not found: $login\n";
        }
        #show_hash($user_info, { DELIMITE => '<BR>' });
      }
    }
  }
  else {
    $result = $self->_send_request({
      ACTION => '/v2/subscriptions',
    });
  }

  #  my @report_list = ();
  #  foreach my $uid ( keys %{ $result->{subscribers} } ) {
  #    $result->{subscribers}->{$uid}->{uid}=$uid;
  #    push @report_list, $result->{subscribers}->{$uid};
  #  }

  my @menu = ("CHANNELS:index=$html->{index}&SERVICE_ID=$html->{HTML_FORM}->{SERVICE_ID}",
    "USERS:index=$html->{index}&TYPE=users&SERVICE_ID=$html->{HTML_FORM}->{SERVICE_ID}",
    "IMPORT:index=$html->{index}&TYPE=import&SERVICE_ID=$html->{HTML_FORM}->{SERVICE_ID}"
  );

  $self->{REPORT_NAME} = 'CHANNELS';
  $self->{REPORT} = $result;
  $self->{MENU} = \@menu;

  return $self;
}

#**********************************************************
=head2 subscriptions($attr)

  Arguments:
    $attr
      SUBSCRIBE_ID

=cut
#**********************************************************
sub subscriptions {
  my $self = shift;
  my ($attr) = @_;

  my $result = $self->_send_request({
    ACTION => '/v2/accounts/' . $attr->{SUBSCRIBE_ID} . '/subscriptions',
  });

  return $self->{subcribes} = $result;
}

#**********************************************************
=head2 subscriptions($attr)

  Arguments:
    $attr
      SUBSCRIBE_ID

=cut
#**********************************************************
sub subscriptions_change {
  my $self = shift;
  my ($attr) = @_;

  my $Iptv = Iptv->new($self->{db}, $admin, $CONF);

  my $subcribes_list = $self->subscriptions($attr);
  if ($subcribes_list && ref $subcribes_list eq 'ARRAY') {
    foreach my $subscribe (@$subcribes_list) {
      $self->subscriptions_del({
        FILTER_ID    => $subscribe->{id},
        SUBSCRIBE_ID => $attr->{SUBSCRIBE_ID}
      });
    }
    shift @{$subcribes_list};
  }

  return $self if !$attr->{FILTER_ID};

  my $tp_channels = $Iptv->channel_ti_list({
    INTERVAL_ID => $attr->{TP_ID},
    MANDATORY   => 1,
    FILTER_ID   => '_SHOW',
    COLS_NAME   => 1
  });
  my %enabled_channels = ();

  if ($Iptv->{TOTAL}) {
    foreach my $channel (@{$tp_channels}) {
      $enabled_channels{$channel->{filter_id}} = $channel->{channel_id};
    }
  }

  my @IDS = ();
  my $result = $self->subscriptions_add($attr);
  if ($subcribes_list && ref $subcribes_list eq 'ARRAY') {
    foreach my $subscribe (@$subcribes_list) {
      if ($enabled_channels{$subscribe->{id}}) {
        $self->subscriptions_add({
          FILTER_ID    => $subscribe->{id},
          SUBSCRIBE_ID => $attr->{SUBSCRIBE_ID}
        });
        push @IDS, $enabled_channels{$subscribe->{id}};
      }
    }
  }

  $Iptv->user_channels({
    ID    => $attr->{ID},
    TP_ID => $attr->{TP_ID},
    IDS   => join(', ', @IDS)
  });

  return $self->{subcribes} = $result;
}

#**********************************************************
=head2 subscriptions($attr)

  Arguments:
    $attr
      SUBSCRIBE_ID

=cut
#**********************************************************
sub subscriptions_add {
  my $self = shift;
  my ($attr) = @_;

  my $result = $self->_send_request({
    ACTION              => '/v2/accounts/' . $attr->{SUBSCRIBE_ID} . '/subscriptions',
    POST                => 1,
    REQUEST_PARAMS_JSON => {
      id    => $attr->{FILTER_ID},
      valid => 'true'
    },
  });

  return $self->{subcribes} = $result;
}


#**********************************************************
=head2 subscriptions_del($attr)

  Arguments:
    $attr
      SUBSCRIBE_ID
      FILTER_ID
      ALL        - DELETE ALL Subcribes

   #post http://nline.test.lfstrm.tv/v2/accounts/5895b294098f6b2811ba3b57/subscriptions {"id": "106", "valid": false}

   Delete ALL
     COMMAND => DELETE

=cut
#**********************************************************
sub subscriptions_del {
  my $self = shift;
  my ($attr) = @_;

  $self->_send_request({
    ACTION              => '/v2/accounts/' . $attr->{SUBSCRIBE_ID} . '/subscriptions',
    COMMAND             => 'POST',
    REQUEST_PARAMS_JSON => {
      id    => $attr->{FILTER_ID},
      valid => 'false'
    },
  });

  return $self;
}

#**********************************************************
=head2 channels_change($attr)

  Arguments:
    $attr
      SUBSCRIBE_ID
      FILTER_ID
      TP_FILTER_ID

=cut
#**********************************************************
sub channels_change {
  my $self = shift;
  my ($attr) = @_;

  my @filters = ();
  if ($attr->{FILTER_ID}) {
    @filters = split(',\s?', $attr->{FILTER_ID});
  }

  my $subscribes = $self->subscriptions($attr);
  my %cure_subacribes = ();
  if ($subscribes) {
    foreach my $sub (@$subscribes) {
      $cure_subacribes{$sub->{id}} = 1;
    }
  }

  if ($attr->{TP_FILTER_ID}) {
    #delete $cure_subacribes{$attr->{TP_FILTER_ID}};
    push @filters, $attr->{TP_FILTER_ID};
  }

  foreach my $filter_id (@filters) {
    if ($cure_subacribes{$filter_id}) {
      delete $cure_subacribes{$filter_id};
      next;
    }

    $attr->{FILTER_ID} = $filter_id;
    $self->subscriptions_add($attr);
  }

  #delete $cure_subacribes{$attr->{TP_FILTER_ID}};
  foreach my $subcribe_id (keys %cure_subacribes) {
    print "|DeL : $subcribe_id <br>" if ($self->{debug});
    $self->subscriptions_del({ FILTER_ID => $subcribe_id, SUBSCRIBE_ID => $attr->{SUBSCRIBE_ID} });
  }

  return $self;
}

#**********************************************************
=head2 pin_add($attr)

=cut
#**********************************************************
sub pin_add {
  my $self = shift;
  my ($attr) = @_;

  $self->_send_request({
    ACTION => '/partners/user/autorizebycode',
    PARAMS => {
      localid => $attr->{ID},
      code    => $attr->{PIN},
    },
    hash   => $self->{LOGIN} . $attr->{ID} . $attr->{PIN} . $self->{PASSWORD}
  });

  return $self;
}


#**********************************************************
=head2 mac_add($attr)

=cut
#**********************************************************
sub mac_add {
  my $self = shift;
  my ($attr) = @_;

  $self->_send_request({
    ACTION => '/partners/user/autorizemac',
    PARAMS => {
      localid => $attr->{ID},
      mac     => $attr->{CID},
    },
    hash   => $self->{LOGIN} . $attr->{ID} . $attr->{CID} . $self->{PASSWORD}
  });

  return $self;
}

#**********************************************************
=head2 mac_del($attr)

=cut
#**********************************************************
sub mac_del {
  my $self = shift;
  my ($attr) = @_;

  $self->_send_request({
    ACTION => '/partners/user/deletemac',
    PARAMS => {
      localid => $attr->{ID},
      mac     => $attr->{CID},
    },
    hash   => $self->{LOGIN} . $attr->{ID} . $attr->{CID} . $self->{PASSWORD}
  });

  return $self;
}

#**********************************************************
=head2 mac_list($attr)

=cut
#**********************************************************
sub mac_list {
  my $self = shift;
  my ($attr) = @_;

  $self->_send_request({
    ACTION => '/partners/user/listmac',
    PARAMS => {
      localid => $attr->{ID},
    },
    hash   => $self->{LOGIN} . $attr->{ID} . $self->{PASSWORD}
  });

  return $self;
}

1
