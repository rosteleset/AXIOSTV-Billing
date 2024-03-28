package Cams::Axiostv_cams;

=head1 NAME

=head1 VERSION

  VERSION: 0.02
  Revision: 20191010

=head1 SYNOPSIS

=cut

#**********************************************************

use strict;
use warnings FATAL => 'all';

our $VERSION = 0.02;

use parent qw(dbcore);
use AXbills::Base qw(load_pmodule mk_unique_value in_array urlencode convert _bp);
use AXbills::Fetcher;
use Digest::SHA qw(hmac_sha256_hex);
my $MODULE = 'Axoistv_cams';

my ($admin, $CONF);
my $json;
my AXbills::HTML $html;
my $lang;
my $Cams;

#**********************************************************
# Init
#**********************************************************
sub new {
  my $class = shift;
  my $db = shift;
  $admin = shift;
  $CONF = shift;
  my $attr = shift;

  $Cams = Cams->new($db, $admin, $CONF);

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

  $self->{LOGIN} = $attr->{LOGIN};
  $self->{PASSWORD} = $attr->{PASSWORD};
  $self->{URL} = $attr->{URL} || '';
  $self->{debug} = $attr->{DEBUG} || 0;
  $self->{DEBUG_FILE} = $attr->{DEBUG_FILE};
  $self->{request_count} = 0;

  $self->{VERSION} = $VERSION;

  if ($self->{debug}) {
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

  my $result = $self->_auth();

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

  my %array_items = (
    'camera_numbers'   => 1,
    'camera_group_ids' => 1,
    'ids'              => 1,
    'streams'          => 1,
    'permissions'      => 1,
    'fields'           => 1,
    'numbers'          => 1,
  );

  if ($attr->{ACTION}) {
    $request_url .= $attr->{ACTION};
  }

  my $message = "";
  if ($attr->{PARAMS}) {
    foreach my $key (keys %{$attr->{PARAMS}}) {
      my $key_p = "\\\"$key\\\"";
      my $value = "\\\"$attr->{PARAMS}->{$key}\\\"";
      $value = $attr->{PARAMS}->{$key} if $array_items{$key};
      if ($message) {
        $message .= ',' . $key_p . ':' . $value;
      }
      else {
        $message = $key_p . ':' . ($value || q{});
      }
    }
  }

  my @params = ();

  my $result = '';
  $params[0] = 'Content-Type: application/json';
  push @params, 'Authorization: Bearer ' . $attr->{TOKEN} if ($attr->{TOKEN});

  delete $params[2] if $attr->{DEL_API};
  if ($attr->{POST}) {
    $result = web_request($request_url,
      {
        HEADERS      => \@params,
        POST         => "{" . $message . "}" || '""',
        DEBUG        => $debug,
        DEBUG2FILE   => $self->{DEBUG_FILE},
        CURL_OPTIONS => "-X POST",
        CURL         => 1,
      }
    );
  }
  else {
    if ($attr->{COMMAND} && $attr->{COMMAND} eq "PUT") {
      $result = web_request($request_url,
        {
          HEADERS      => \@params,
          DEBUG        => $debug,
          DEBUG2FILE   => $self->{DEBUG_FILE},
          CURL         => 1,
          CURL_OPTIONS => ($attr->{COMMAND}) ? "-X $attr->{COMMAND}" : undef,
          POST         => !$attr->{SQUARE_BRACKETS} ? ("[{" . $message . "}]" || '""') : ("{" . $message . "}" || '""'),
        }
      );
    }
    else {
      $result = web_request($request_url,
        {
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
    $self->{errno} = 100;
    $self->{error} = 100;
    $self->{errstr} = $result;
  }

  return $perl_scalar;
}

#**********************************************************
=head2 _auth($attr)

   Arguments:

   Results:

=cut
#**********************************************************
sub _auth {
  my $self = shift;
  my ($attr) = @_;

  my $url = '/admin/api/v0/auth/';
  if ($attr->{USER}) {
    $url = '/api/v0/auth/';
    $self->{URL} = "https://video.axiostv.ru";
  }

  my $result = $self->_send_request({
    ACTION => $url,
    PARAMS => {
      username => $attr->{USER} ? $attr->{UID} : $self->{LOGIN},
      password => $attr->{USER} ? $attr->{PASSWORD} : $self->{PASSWORD},
    },
    POST   => 1,
  });

  return ($result && ref $result eq "HASH" && $result->{token}) ? $result : {};
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

  my $auth_result = $self->_auth();

  $self->_send_request({
    ACTION => '/admin/api/v0/users/clients/',
    POST   => 1,
    TOKEN  => $auth_result->{token}
  });

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

  my $auth_result = $self->_auth();

  my $result = $self->_send_request({
    ACTION => '/admin/api/v0/users/clients/create/',
    PARAMS => {
      username => $attr->{UID},
      password => $attr->{PASSWORD}
    },
    POST   => 1,
    TOKEN  => $auth_result->{token}
  });

  if (ref $result eq "HASH" && $result->{error}) {
    _get_errors($result);
    return $self;
  }

  $self->{SUBSCRIBE_ID} = $result->{id} if ref $result eq "HASH" && $result->{id};

  return $self;
}

#**********************************************************
=head2 user_change($attr)

   Arguments:
     $attr
       ID

   Results:
     $self->
       {RESULT}->{results}

=cut
#**********************************************************
sub user_change {
  my $self = shift;
  my ($attr) = @_;

  my $auth_result = $self->_auth();
  my $result = $self->_send_request({
    ACTION => "/admin/api/v0/users/clients/edit/",
    POST   => 'true',
    PARAMS => {
      username  => $attr->{UID},
      id        => $attr->{SUBSCRIBE_ID} || 0,
      is_active => 'null',
    },
    TOKEN  => $auth_result->{token}
  });

  if (ref $result eq "HASH" && $result->{error}) {
    $self->{errno} = '10101';
    $self->{errstr} = _get_errors($result);
    return $self;
  }

  $self->_send_request({
    ACTION => "/admin/api/v0/users/clients/change_password/",
    POST   => 'true',
    PARAMS => {
      password => $attr->{PASSWORD},
      user_id  => $attr->{SUBSCRIBE_ID} || 0,
    },
    TOKEN  => $auth_result->{token}
  });

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

  my $auth_result = $self->_auth();

  $attr->{SUBSCRIBE_ID} ||= "";

  $self->_send_request({
    ACTION => '/admin/api/v0/users/clients/delete/',
    PARAMS => {
      id => $attr->{SUBSCRIBE_ID}
    },
    POST   => 1,
    TOKEN  => $auth_result->{token}
  });

  return $self;
}

#**********************************************************
=head2 camera_add($attr)

   Arguments:
     $attr
       ID

   Results:
     $self->
       {RESULT}->{results}

=cut
#**********************************************************
sub camera_add {
  my $self = shift;
  my ($attr) = @_;

  my $result = "";
  my $stream_url = "";

  my $auth_result = $self->_auth();
  $attr->{SUBGROUP_ID} ||= "";

  $stream_url = "rtsp://" . $attr->{HOST} . ":" . $attr->{RTSP_PORT} . $attr->{RTSP_PATH};

  $result = $self->_send_request({
    ACTION => "/admin/api/v0/cameras/create/",
    POST   => 'true',
    PARAMS => {
      title            => $attr->{NAME},
      camera_group_ids => "[$attr->{SUBGROUP_ID}]",
      tariff_id        => 1,
      timezone         => "Europe/Moscow",
      streams          => "[\\\"$stream_url\\\"]",
      cluster_id       => 1
    },
    TOKEN  => $auth_result->{token}
  });

  if (ref $result eq "HASH" && $result->{error}) {
    $self->{errno} = '10101';
    $self->{errstr} = _get_errors($result);
    return $self;
  }

  $self->{NUMBER_ID} = $result->{number} if ref $result eq "HASH" && $result->{number};

  return $self;
}

#**********************************************************
=head2 camera_del($attr)

   Arguments:
     $attr
       ID

   Results:
     $self->
       {RESULT}->{results}

=cut
#**********************************************************
sub camera_del {
  my $self = shift;
  my ($attr) = @_;

  my $result = "";

  my $auth_result = $self->_auth();
  $attr->{NUMBER_ID} ||= "";

  $result = $self->_send_request({
    ACTION => "/admin/api/v0/cameras/delete/",
    POST   => 'true',
    PARAMS => {
      camera_numbers => "[\\\"$attr->{NUMBER_ID}\\\"]",
    },
    TOKEN  => $auth_result->{token}
  });

  return $self;
}

#**********************************************************
=head2 camera_info($attr)

   Arguments:
     $attr
       ID

   Results:
     $self->
       {RESULT}->{results}

=cut
#**********************************************************
sub camera_info {
  my $self = shift;
  my ($attr) = @_;

  my $result = "";

  my $auth_result = $self->_auth();
  $attr->{NUMBER_ID} ||= "";

  $result = $self->_send_request({
    ACTION => "/admin/api/v0/cameras/",
    POST   => 'true',
    PARAMS => {
      camera_numbers => "[\\\"$attr->{NUMBER_ID}\\\"]",
      stream         => 'true'
    },
    TOKEN  => $auth_result->{token}
  });

  return $self;
}

#**********************************************************
=head2 camera_change($attr)

   Arguments:
     $attr
       ID

   Results:
     $self->
       {RESULT}->{results}

=cut
#**********************************************************
sub camera_change {
  my $self = shift;
  my ($attr) = @_;

  my $stream_url = "";

  my $auth_result = $self->_auth();
  $attr->{NUMBER_ID} ||= "";
  $attr->{SUBGROUP_ID} ||= "";

  $stream_url = "rtsp://" . $attr->{HOST} . ":" . $attr->{RTSP_PORT} . $attr->{RTSP_PATH};

  my $result = $self->_send_request({
    ACTION => "/admin/api/v0/cameras/edit/",
    POST   => 'true',
    PARAMS => {
      number           => "$attr->{NUMBER_ID}",
      title            => $attr->{NAME},
      camera_group_ids => "[$attr->{SUBGROUP_ID}]",
      tariff_id        => 1,
      timezone         => "Europe/Moscow",
      streams          => "[\\\"$stream_url\\\"]",
      cluster_id       => 1
    },
    TOKEN  => $auth_result->{token}
  });

  if (ref $result eq "HASH" && $result->{error}) {
    $self->{errno} = '10101';
    $self->{errstr} = _get_errors($result);
    return $self;
  }

  return $self;
}

#**********************************************************
=head2 group_add($attr)

   Arguments:
     $attr
       ID

   Results:
     $self->
       {RESULT}->{results}

=cut
#**********************************************************
sub group_add {
  my $self = shift;
  my ($attr) = @_;

  my $result = "";

  my $auth_result = $self->_auth();

  $result = $self->_send_request({
    ACTION => "/admin/api/v0/camera_groups/create/",
    POST   => 'true',
    PARAMS => {
      name                 => $attr->{NAME},
      camera_group_type_id => 1,
    },
    TOKEN  => $auth_result->{token}
  });

  if (ref $result eq "HASH" && $result->{error}) {
    $self->{errno} = '10101';
    $self->{errstr} = _get_errors($result);
    return $self;
  }

  $self->{SUBGROUP_ID} = $result->{id} if ref $result eq "HASH" && $result->{id};

  return $self;
}

#**********************************************************
=head2 group_change($attr)

   Arguments:
     $attr
       ID

   Results:
     $self->
       {RESULT}->{results}

=cut
#**********************************************************
sub group_change {
  my $self = shift;
  my ($attr) = @_;

  my $auth_result = $self->_auth();

  my $result = $self->_send_request({
    ACTION => "/admin/api/v0/camera_groups/edit/",
    POST   => 'true',
    PARAMS => {
      name                 => $attr->{NAME},
      camera_group_type_id => 1,
      id                   => $attr->{SUBGROUP_ID} || 0,
    },
    TOKEN  => $auth_result->{token}
  });

  if (ref $result eq "HASH" && $result->{error}) {
    $self->{errno} = '10101';
    $self->{errstr} = _get_errors($result);
    return $self;
  }

  $self->{SUBGROUP_ID} = $result->{id} if ref $result eq "HASH" && $result->{id};

  return $self;
}

#**********************************************************
=head2 group_del($attr)

   Arguments:
     $attr
       ID

   Results:
     $self->
       {RESULT}->{results}

=cut
#**********************************************************
sub group_del {
  my $self = shift;
  my ($attr) = @_;

  my $result = "";

  my $auth_result = $self->_auth();
  $attr->{SUBGROUP_ID} ||= "";

  $result = $self->_send_request({
    ACTION => "/admin/api/v0/camera_groups/delete/",
    POST   => 'true',
    PARAMS => {
      ids => "[$attr->{SUBGROUP_ID}]",
    },
    TOKEN  => $auth_result->{token}
  });

  return $self;
}

#**********************************************************
=head2 _get_errors($attr)

=cut
#**********************************************************
sub _get_errors {
  my ($attr) = @_;
  my $error_str = "";

  if ($attr->{fields}) {
    foreach my $key (keys %{$attr->{fields}}) {
      $error_str .= "</br>$key: $attr->{fields}{$key}[0]" if ref $attr->{fields}{$key} eq "ARRAY";
      $error_str .= "</br>$key: $attr->{fields}{$key}" if ref $attr->{fields}{$key} ne "ARRAY";
    }
  }

  return $error_str;
}

#**********************************************************
=head2 change_user_cameras($attr)

=cut
#**********************************************************
sub change_user_groups {
  my $self = shift;
  my ($attr) = @_;

  my $result = "";
  $attr->{SUBGROUP_ID} ||= "";

  return $self if !$attr->{IDS} || !$attr->{ID};

  my $user_info = $Cams->_info($attr->{ID});

  if (!$Cams->{TOTAL} && $user_info->{SUBSCRIBE_ID}) {
    $self->{errno} = '10101';
    $self->{errstr} = 'User not found';
    return $self;
  }

  my $auth_result = $self->_auth();

  foreach my $group (split(',', $attr->{IDS})) {
    my $info = $Cams->group_info($group);
    if ($Cams->{TOTAL} && $info->{SUBGROUP_ID}) {
      $result = $self->_send_request({
        ACTION => "/admin/api/v0/permissions/camera_groups/add/",
        POST   => 'true',
        PARAMS => {
          user_id     => "$user_info->{SUBSCRIBE_ID}",
          permissions => '[{\\"permission\\":\\"10\\",\\"camera_group_id\\":\\"' . $info->{SUBGROUP_ID} . '\\"}]',
          is_auto     => 'false'
        },
        TOKEN  => $auth_result->{token}
      });
    }
  }

  return $self;
}

#**********************************************************
=head2 _user_cameras($attr)

=cut
#**********************************************************
sub _user_groups {
  my $self = shift;
  my ($attr) = @_;

  my $result = "";
  $attr->{SUBGROUP_ID} ||= "";

  return $self if !$attr->{ID};

  my $user_info = $Cams->_info($attr->{ID});

  return $self if !$Cams->{TOTAL} && !$user_info->{SUBSCRIBE_ID};

  my $auth_result = $self->_auth();

  $result = $self->_send_request({
    ACTION => "/admin/api/v0/permissions/camera_groups/filters/",
    POST   => 'true',
    PARAMS => {
      user_id => "$user_info->{SUBSCRIBE_ID}",
    },
    TOKEN  => $auth_result->{token}
  });

  return $self;
}


#**********************************************************
=head2 change_user_cameras($attr)

=cut
#**********************************************************
sub change_user_cameras {
  my $self = shift;
  my ($attr) = @_;

  my $result = "";

  return $self if !$attr->{IDS};

  my $user_info = $Cams->_list({
    UID          => $attr->{UID},
    TP_ID        => $attr->{CAMS_TP_ID},
    SUBSCRIBE_ID => '_SHOW'
  });

  if (!$Cams->{TOTAL} && !$user_info->[0]{subscribe_id}) {
    $self->{errno} = '10101';
    $self->{errstr} = 'User not found';
    return $self;
  }

  my $auth_result = $self->_auth();

  foreach my $cameras (split(',', $attr->{IDS})) {
    my $info = $Cams->stream_info($cameras);
    if ($Cams->{TOTAL} && $info->{NUMBER_ID}) {
      $result = $self->_send_request({
        ACTION => "/admin/api/v0/permissions/cameras/add/",
        POST   => 'true',
        PARAMS => {
          user_id     => "$user_info->[0]{subscribe_id}",
          permissions => '[{\\"permission\\":\\"10\\",\\"camera_number\\":\\"' . $info->{NUMBER_ID} . '\\"}]',
          is_auto     => 'false'
        },
        TOKEN  => $auth_result->{token}
      });
    }
  }

  return $self;
}

#**********************************************************
=head2 get_stream($attr)

   Arguments:
     $attr
       ID

   Results:
     $self->
       {RESULT}->{results}

=cut
#**********************************************************
sub get_stream {
  my $self = shift;
  my ($attr) = @_;

  return 0 if !$attr->{number};

  my $auth_result = $self->_auth({ USER => 1, %{$attr} });

  my $result = $self->_send_request({
    ACTION => "/api/v0/cameras/my/",
    POST   => 'true',
    PARAMS => {
      fields => '[\\"number\\",\\"address\\",\\"title\\",\\"longitude\\",\\"latitude\\"]'
    },
    TOKEN  => $auth_result->{token}
  });

  $result = $self->_send_request({
    ACTION => "/api/v0/cameras/this/",
    POST   => 'true',
    PARAMS => {
      fields  => '[\\"number\\",\\"address\\",\\"server\\",\\"title\\",\\"longitude\\",\\"latitude\\",\\"token_l\\",\\"permission\\"]',
      numbers => '[\\"' . $attr->{number} . '\\"]'
    },
    TOKEN  => $auth_result->{token}
  });

  return 0 if !$result || ref $result ne "HASH";
  my $token = $result->{results}[0]{token_l};
  my $camera = qq{
    <video id='hls-example-$attr->{number}'  class="video-js vjs-default-skin" width="400" height="300" controls>
    <source type="application/x-mpegURL" src="https://$result->{results}[0]{server}{domain}/$attr->{number}/video.m3u8?token=$token">
    </video>

    <script>
      var player_$attr->{number} = videojs('hls-example-$attr->{number}');
      player_$attr->{number}.play();
    </script>
  };

  $result->{CAMERA} = $camera;

  return $result;
}

1;