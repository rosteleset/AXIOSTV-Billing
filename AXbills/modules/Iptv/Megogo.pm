package Iptv::Megogo;

=head1 NAME

=head1 VERSION

  VERSION: 1.07
  Revision: 20210216

=head1 SYNOPSIS

=cut

#**********************************************************

use strict;
use warnings FATAL => 'all';

our $VERSION = 1.07;

use parent qw(dbcore);
use AXbills::Base qw(load_pmodule mk_unique_value in_array urlencode convert _bp);
use AXbills::Fetcher;
use Digest::SHA qw(hmac_sha256_hex);
my $MODULE = 'Megogo';

my ($admin, $CONF);
my $json;
my AXbills::HTML $html;
my $lang;

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
  $self->{URL} = $attr->{URL} || 'http://api-test.hls.tv/';
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

  my $partnerID = $CONF->{partnerID} || "";

  my $result = $self->_send_request({
    ACTION => '/partners/' . $partnerID . '/subscription/subscribe?userId=2&serviceId=1',
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
  my $public_key = $self->{public_key} || 'public_key_not_defined';
  my $private_key = $self->{private_key} || 'private_key_not_defined';

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
      my $key_p = "\\\"$key\\\"";
      my $value = "\\\"$attr->{PARAMS}->{$key}\\\"";
      if ($message) {
        $message .= ',' . $key_p . ': ' . $value;
      }
      else {
        $message = $key_p . ': ' . ($value || q{});
      }
    }

    $message .= $bundle_str;
  }

  my $api_time = time();
  my $hmac_text = $api_time . $public_key . ($message || '');
  my $api_hash = hmac_sha256_hex($hmac_text, $private_key);

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
  else {
    $params[0] = 'API_ID: ' . $public_key;
    $params[1] = 'API_TIME: ' . $api_time;
    $params[2] = 'API_HASH: ' . $api_hash;
    $result = web_request($request_url,
      {
        DEBUG      => 4,
        HEADERS    => \@params,
        DEBUG      => $debug,
        DEBUG2FILE => $self->{DEBUG_FILE},
        CURL       => 1,
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

  my $partnerID = $CONF->{partnerID} || "";
  my $Id = $attr->{UID} || "";

  $self->_send_request({
    ACTION => "/partners/$partnerID/subscription/innerId?identifier=$Id",
  });

  my $result = $self->_send_request({
    ACTION => "/partners/$partnerID/user/innerId?identifier=$Id",
  });

  $self->{RESULT}->{results} = [ $result ];

  return $self;
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

  $attr->{FILTER_ID} = $attr->{TP_FILTER_ID};

  my $partnerID = $CONF->{partnerID} || "";
  my $Id = $attr->{UID} || "";
  $result = $self->_send_request({
    ACTION => "/partners/$partnerID/subscription/subscribe?userId=$Id&serviceId=$attr->{FILTER_ID}",
  });

  my $Users = Users->new($self->{db}, $admin, $CONF);
  $Users->info($attr->{UID}, {
    SHOW_PASSWORD => 1,
  });

  my $uid_length = length $attr->{UID};
  if ($uid_length < 6) {
    while ($uid_length < 6){
      $uid_length++;
      $attr->{UID} = "0" . $attr->{UID};
    }
  }
  if ($result->{successful}) {
    $result = $self->_send_request({
      ACTION => "/partners/$partnerID/user/changeCredentials",
      POST   => 'true',
      PARAMS => {
        isdn     => $Id,
        email    => $attr->{UID} . '@' . ($CONF->{MEGOGO_EMAIL} || 'axbills.com'),
        password => $attr->{PASSWORD}  || $Users->{PASSWORD} || "",
      },
    });
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

  my $result;
  my $action = "subscribe";

  if (!$attr->{TP_ID}) {
    $self->{errno} = '10100';
    $self->{errstr} = 'ERR_SELECT_TP';
    return $self;
  }

  if ($attr->{TP_INFO_OLD}) {
    $self->_user_change_tp($attr);
    return $self;
  }

  if ($attr->{STATUS} eq '1') {
    $action = "unsubscribe";
  }
  elsif ($attr->{STATUS} eq '3') {
    $action = "suspend";
  }
  else {
    $action = "resume";
  }

  $attr->{FILTER_ID} = $attr->{TP_FILTER_ID};

  my $partnerID = $CONF->{partnerID} || "";
  my $Id = $attr->{UID} || "";
  $result = $self->_send_request({
    ACTION => "/partners/$partnerID/subscription/$action?userId=$Id&serviceId=$attr->{FILTER_ID}",
  });

  return $self;
}

#**********************************************************
=head2 _user_change_tp($attr)

   Arguments:
     $attr
       ID
       TP_ID,
       FILTER_ID
       TP_FILTER_ID

   Results:

=cut
#**********************************************************
sub _user_change_tp {
  my $self = shift;
  my ($attr) = @_;

  return 0 if !$CONF->{partnerID} || !$attr->{TP_INFO_OLD}{FILTER_ID} || !$attr->{TP_FILTER_ID};

  $self->user_del({
    FILTER_ID => $attr->{TP_INFO_OLD}{FILTER_ID},
    UID       => $attr->{UID}
  });

  $self->_send_request({
    ACTION => "/partners/$CONF->{partnerID}/subscription/subscribe?userId=$attr->{UID}&serviceId=$attr->{TP_FILTER_ID}",
  });

  return $self;
}

#**********************************************************
=head2 user_del($attr)

   Arguments:
     $attr
       ID
       FILTER_ID
       UID

   Results:

=cut
#**********************************************************
sub user_del {
  my $self = shift;
  my ($attr) = @_;

  $attr->{FILTER_ID} ||= $attr->{TP_FILTER_ID};
  return 0 if !$CONF->{partnerID} || !$attr->{UID} || !$attr->{FILTER_ID};

  my $result = $self->_send_request({
    ACTION => "/partners/$CONF->{partnerID}/subscription/unsubscribe?userId=$attr->{UID}&serviceId=$attr->{FILTER_ID}",
  });

  return 0;
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

  my $partnerID = $CONF->{partnerID} || "";
  my $Id = $attr->{UID} || "";
  my $result = $self->_send_request({
    ACTION => "/partners/$partnerID/user/innerId?identifier=$Id",
  });

  if ($result->{email}) {
    my $btn_in = $html->button($lang->{CONTINUE}, '', {
      GLOBAL_URL => "http://megogo.net/ru/login",
      target     => '_new',
      class      => 'btn btn-info',
    });
    return $html->message('info', $lang->{INFO}, "E-mail: $result->{email}" . $html->br() . "$lang->{PASSWD}: $attr->{PASSWORD}" . $html->br() . $btn_in);
  }
  else {
    return $html->message('error', $lang->{ERROR}, "E-main is not exist");
  }

  # $self->{RESULT}->{results} = [ $result ];
  #
  # return $self;
}

#**********************************************************
=head2 user_negdeposit($attr)


=cut
#**********************************************************
sub user_negdeposit {
  my $self = shift;
  my ($attr) = @_;

  my $partnerID = $CONF->{partnerID} || "";
  my $Id = $attr->{UID} || "";
  $self->_send_request({
    ACTION => "/partners/$partnerID/subscription/unsubscribe?userId=$Id&serviceId=$attr->{FILTER_ID}",
  });

  return $self;
}

1;
