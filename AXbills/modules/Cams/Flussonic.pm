package Cams::Flussonic;

=head1 NAME

  Error ID: 24xx

=head1 VERSION

  VERSION: 0.16
  Revision: 20210217

=head1 SYNOPSIS

=cut

#**********************************************************

use strict;
use warnings FATAL => 'all';

our $VERSION = 0.16;

use parent qw(dbcore);
use AXbills::Base qw(load_pmodule mk_unique_value in_array urlencode convert _bp);
use AXbills::Fetcher;
use Digest::SHA qw(hmac_sha256_hex);
my $MODULE = 'Flussonic';

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

  $admin->{MODULE} = $MODULE;
  $Cams = Cams->new($db, $admin, $CONF);

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

  $self->{URL} = $attr->{URL} || '';
  $self->{debug} = $attr->{DEBUG} || 0;
  $self->{DEBUG_FILE} = $attr->{DEBUG_FILE};
  $self->{request_count} = 0;
  $self->{LOGIN} = $CONF->{FLUSSONIC_LOGIN} || $attr->{LOGIN};
  $self->{PASSWORD} = $CONF->{FLUSSONIC_PASSWORD} || $attr->{PASSWORD};

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

  my $result = $self->_send_request({
    ACTION => '/vsaas/api/v2/users',
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

  my $request_url = $self->{URL} || '';
  my $api_key = $CONF->{FLUSSONIC_API_KEY} || $self->{PASSWORD} || "";

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
      my $key_p = "\\\"$key\\\"";
      my $value = "\\\"$attr->{PARAMS}->{$key}\\\"";
      if (defined $message) {
        $message .= ',' . $key_p . ':' . $value;
      }
      else {
        $message = $key_p . ':' . ($value || q{});
      }
    }
  }

  my @params = ();

  my $result = '';
  push @params, 'Content-Type: application/json';
  push @params, 'x-vsaas-session: ' . $attr->{SESSION} if ($attr->{SESSION});
  push @params, 'X-Vsaas-Api-Key: ' . $api_key if !$attr->{SESSION};

  delete $params[2] if $attr->{DEL_API} && $attr->{SESSION};
  delete $params[1] if $attr->{DEL_API} && !$attr->{SESSION};

  push @params, 'force: 1' if $attr->{FORCE};

  if ($attr->{POST}) {
    $result = web_request($request_url, {
      HEADERS      => \@params,
      POST         => !$attr->{SQUARE_BRACKETS} ? ("[{" . $message . "}]" || '""') : ("{" . $message . "}" || '""'),
      DEBUG        => $debug,
      DEBUG2FILE   => $self->{DEBUG_FILE},
      CURL_OPTIONS => "-X POST -k",
      CURL         => 1,
    });
  }
  else {
    if ($attr->{COMMAND} && $attr->{COMMAND} eq "PUT") {
      $result = web_request($request_url, {
        HEADERS      => \@params,
        DEBUG        => $debug,
        DEBUG2FILE   => $self->{DEBUG_FILE},
        CURL         => 1,
        CURL_OPTIONS => ($attr->{COMMAND}) ? "-X $attr->{COMMAND} -k" : '-k',
        POST         => !$attr->{SQUARE_BRACKETS} ? ("[{" . $message . "}]" || '""') : ("{" . $message . "}" || '""'),
      });
    }
    else {
      $result = web_request($request_url, {
        HEADERS      => \@params,
        DEBUG        => $debug,
        DEBUG2FILE   => $self->{DEBUG_FILE},
        CURL         => 1,
        CURL_OPTIONS => ($attr->{COMMAND}) ? "-X $attr->{COMMAND} -k" : '-k',
      });
    }
  }

  my $perl_scalar;
  if ($result =~ /\{/) {
    $perl_scalar = $json->decode($result);
  }
  else {
    $perl_scalar->{errno} = 2401;
    $perl_scalar->{err_str} = $result;
    $self->{errno} = 2401;
    $self->{error} = 2401;
    $self->{errstr} = $result;
  }

  return $perl_scalar;
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

  my $result = $self->_send_request({
    ACTION          => "/vsaas/api/v2/auth/login",
    POST            => "true",
    PARAMS          => {
      password => $self->{PASSWORD},
      login    => $self->{LOGIN},
    },
    SQUARE_BRACKETS => 1,
    DEL_API         => 1,
  });

  my %params = (
    login    => $attr->{LOGIN} || "",
    enabled  => "true",
    password => $attr->{PASSWORD} || "test_password",
  );

  $params{phone} = $attr->{PHONE} if $attr->{PHONE};
  $params{notification_email} = $attr->{EMAIL_ALL} if $attr->{EMAIL_ALL};
  $params{name} = $attr->{FIO} if $attr->{FIO};

  if ($attr->{PAYMENTS_ADDED}) {
    $self->user_change({ %{$attr}, STATUS => 0, LOGIN => $attr->{USER}{LOGIN} });
    return $self;
  }

  $result = $self->_send_request({
    ACTION  => "/vsaas/api/v2/users/import",
    POST    => 'true',
    PARAMS  => {
      %params
    },
    SESSION => $result->{session},
  });

  if (ref $result eq "HASH" && $result->{error_message}) {
    $self->{errno} = '2402';
    $self->{errstr} = $result->{error_message};
    return $self;
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

  my $result = $self->_send_request({
    ACTION => "/vsaas/api/v2/users?search=" . ($attr->{LOGIN} || $attr->{UID}),
  });

  return $result;
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

  my $result = $self->user_info($attr);

  if (ref $result eq "HASH" && $result->{error_message}) {
    $self->{errno} = '2403';
    $self->{errstr} = $result->{error_message};
    return $self;
  }

  my %params = (
    login    => $attr->{LOGIN} || "",
    enabled  => $attr->{STATUS} ? 'false' : 'true',
    password => $attr->{PASSWORD} || "test_password",
  );

  $params{phone} = $attr->{PHONE} if $attr->{PHONE};
  $params{notification_email} = $attr->{EMAIL_ALL} if $attr->{EMAIL_ALL};
  $params{name} = $attr->{FIO} if $attr->{FIO};

  $self->_send_request({
    ACTION          => "/vsaas/api/v2/users/" . $result->[0]{id},
    PARAMS          => { %params },
    COMMAND         => "PUT",
    SQUARE_BRACKETS => 1,
  });

  if (ref $result eq "HASH" && $result->{error_message}) {
    $self->{errno} = '2404';
    $self->{errstr} = $result->{error_message};
    return $self;
  }

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

  my $result = $self->_send_request({
    ACTION => "/vsaas/api/v2/users?search=" . ($attr->{LOGIN} || $attr->{UID}),
  });

  if (ref($result) eq "ARRAY" && $result->[0]{id}) {
    $self->_send_request({
      ACTION  => "/vsaas/api/v2/users/" . $result->[0]{id},
      COMMAND => "DELETE",
    });
  }

  return $self;
}

#**********************************************************
=head2 group_add_old($attr)

   Arguments:
     $attr
       ID

   Results:
     $self->
       {RESULT}->{results}

=cut
#**********************************************************
sub group_add_old {
  my $self = shift;
  my ($attr) = @_;

  my $result = "";

  if ($attr->{MAX_CAMERAS} && $attr->{MAX_USERS}) {
    $result = $self->_send_request({
      ACTION => "/vsaas/api/v2/groups",
      PARAMS => {
        id             => $attr->{GROUP_ID},
        note           => $attr->{COMMENT} || "",
        title          => $attr->{NAME},
        max_cam_slots  => $attr->{MAX_CAMERAS},
        max_user_slots => $attr->{MAX_USERS},
      },
      POST   => "true",
    });
  }

  if ($attr->{MAX_CAMERAS} && !$attr->{MAX_USERS}) {
    $result = $self->_send_request({
      ACTION => "/vsaas/api/v2/groups",
      PARAMS => {
        id            => $attr->{GROUP_ID},
        note          => $attr->{COMMENT} || "",
        title         => $attr->{NAME},
        max_cam_slots => $attr->{MAX_CAMERAS},
      },
      POST   => "true",
    });
  }

  if ($attr->{MAX_USERS} && !$attr->{MAX_CAMERAS}) {
    $result = $self->_send_request({
      ACTION => "/vsaas/api/v2/groups",
      PARAMS => {
        id             => $attr->{GROUP_ID},
        note           => $attr->{COMMENT} || "",
        title          => $attr->{NAME},
        max_user_slots => $attr->{MAX_USERS},
      },
      POST   => "true",
    });
  }

  if (!$attr->{MAX_USERS} && !$attr->{MAX_CAMERAS}) {
    $result = $self->_send_request({
      ACTION => "/vsaas/api/v2/groups",
      PARAMS => {
        id    => $attr->{GROUP_ID},
        note  => $attr->{COMMENT} || "",
        title => $attr->{NAME},
      },
      POST   => "true",
    });
  }

  if (ref $result eq "HASH" && $result->{error_message}) {
    $self->{errno} = '2405';
    $self->{errstr} = $result->{error_message};
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

  my $result = $self->_send_request({
    ACTION          => "/vsaas/api/v2/auth/login",
    POST            => "true",
    PARAMS          => {
      password => $self->{PASSWORD},
      login    => $self->{LOGIN},
    },
    SQUARE_BRACKETS => 1,
    DEL_API         => 1,
  });

  my %params = (
    note     => $attr->{COMMENT} || "",
    title    => $attr->{NAME},
    owner_id => $result->{id} || ""
  );

  $params{camera_limit} = $attr->{MAX_CAMERAS} if $attr->{MAX_CAMERAS};
  $params{user_limit} = $attr->{MAX_USERS} if $attr->{MAX_USERS};

  $result = $self->_send_request({
    ACTION          => "/vsaas/api/v2/organizations/",
    PARAMS          => \%params,
    POST            => "true",
    SESSION         => $result->{session},
    DEL_API         => 1,
    SQUARE_BRACKETS => 1,
  });

  if (ref $result eq "HASH" && $result->{error_message}) {
    $self->{errno} = '2406';
    $self->{errstr} = $result->{error_message};
    return $self;
  }

  $self->{SUBGROUP_ID} = $result->{id} if (ref $result eq "HASH" && $result->{id});

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

  $attr->{SUBGROUP_ID} ||= 0;

  my $result = $self->_send_request({
    ACTION          => "/vsaas/api/v2/auth/login",
    POST            => "true",
    PARAMS          => {
      password => $self->{PASSWORD},
      login    => $self->{LOGIN},
    },
    SQUARE_BRACKETS => 1,
    DEL_API         => 1,
  });

  my %params = (
    note  => $attr->{COMMENT} || "",
    title => $attr->{NAME}
  );

  $params{camera_limit} = $attr->{MAX_CAMERAS} if $attr->{MAX_CAMERAS};
  $params{user_limit} = $attr->{MAX_USERS} if $attr->{MAX_USERS};

  $result = $self->_send_request({
    ACTION          => "/vsaas/api/v2/organizations/$attr->{SUBGROUP_ID}/",
    PARAMS          => \%params,
    COMMAND         => "PUT",
    SESSION         => $result->{session},
    DEL_API         => 1,
    SQUARE_BRACKETS => 1,
  });

  if (ref $result eq "HASH" && $result->{error_message}) {
    $self->{errno} = '2407';
    $self->{errstr} = $result->{error_message};
    return $self;
  }

  $self->{SUBGROUP_ID} = $result->{id} if (ref $result eq "HASH" && $result->{id});

  return $self;
}


#**********************************************************
=head2 group_info($attr)

   Arguments:
     $attr
       ID

   Results:
     $self->
       {RESULT}->{results}

=cut
#**********************************************************
sub group_info {
  my $self = shift;
  my ($attr) = @_;

  $attr->{SUBGROUP_ID} ||= 0;

  my $result = $self->_send_request({
    ACTION          => "/vsaas/api/v2/auth/login",
    POST            => "true",
    PARAMS          => {
      password => $self->{PASSWORD},
      login    => $self->{LOGIN},
    },
    SQUARE_BRACKETS => 1,
    DEL_API         => 1,
  });

  if (ref $result && $result->{session}) {
    $self->_send_request({
      ACTION          => "/vsaas/api/v2/organizations/$attr->{SUBGROUP_ID}",
      SESSION         => $result->{session},
      DEL_API         => 1,
      SQUARE_BRACKETS => 1,
    });
  }

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

  $attr->{SUBGROUP_ID} ||= 0;

  my $result = $self->_send_request({
    ACTION          => "/vsaas/api/v2/auth/login",
    POST            => "true",
    PARAMS          => {
      password => $self->{PASSWORD},
      login    => $self->{LOGIN},
    },
    SQUARE_BRACKETS => 1,
    DEL_API         => 1,
  });

  return $self if !$result->{session};

  if (ref $result && $result->{session}) {
    $self->_send_request({
      ACTION          => "/vsaas/api/v2/organizations/$attr->{SUBGROUP_ID}/",
      SESSION         => $result->{session},
      DEL_API         => 1,
      SQUARE_BRACKETS => 1,
      COMMAND         => "DELETE",
      FORCE           => 1,
    });
  }

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

  my $stream_url = "";
  my $add_func = $attr->{ONLY_VIDEO} ? " tracks=1" : "";

  if ($attr->{LOGIN} && $attr->{PASSWORD}) {
    $stream_url = "rtsp://" . "$attr->{LOGIN}:$attr->{PASSWORD}@" . $attr->{HOST} . ":" . $attr->{RTSP_PORT} . $attr->{RTSP_PATH} . $add_func;
  }
  else {
    $stream_url = "rtsp://" . $attr->{HOST} . ":" . $attr->{RTSP_PORT} . $attr->{RTSP_PATH};
  }

  $attr->{NAME} =~ s/(?<=\w)\s(?=\w)/_/g;

  my $result = $self->_send_request({
    ACTION => "/vsaas/api/v2/cameras/import",
    POST   => 'true',
    PARAMS => {
      name            => $attr->{NAME} || "",
      stream_url      => $stream_url,
      access          => $attr->{TYPE} && $attr->{TYPE} eq "1" ? "public" : "private",
      enabled         => "true",
      rtsp_port       => $attr->{RTSP_PORT},
      title           => $attr->{TITLE},
      owner           => $attr->{UID} || "",
      substream_url   => $attr->{EXTRA_URL} ? $attr->{EXTRA_URL} . ($add_func || "") : "",
      thumbnails_url  => $attr->{SCREENSHOT_URL} || "",
      dvr_depth       => $attr->{ARCHIVE} || "",
      dvr_protected   => $attr->{LIMIT_ARCHIVE} ? "true" : "false",
      static          => $attr->{CONSTANTLY_WORKING} ? "true" : "false",
      thumbnails      => $attr->{PRE_IMAGE} ? "true" : "false",
      thumbnails_url  => $attr->{PRE_IMAGE_URL} || "",
      organization_id => $attr->{SUBGROUP_ID} || "",
      folder_id       => $attr->{SUBFOLDER_ID} || $attr->{FOLDER_ID} || ""
    },
  });

  if (ref $result eq "HASH" && $result->{error_message}) {
    $self->{errno} = '2415';
    $self->{errstr} = $result->{error_message};
    return $self;
  }

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

  return 1 if !$attr->{ID};
  my $stream_url = "";

  my $add_func = $attr->{ONLY_VIDEO} ? " tracks=1" : "";

  if ($attr->{LOGIN} && $attr->{PASSWORD}) {
    $stream_url = "rtsp://" . "$attr->{LOGIN}:$attr->{PASSWORD}@" . $attr->{HOST} . ":" . $attr->{RTSP_PORT} . $attr->{RTSP_PATH} . $add_func;
  }
  else {
    $stream_url = "rtsp://" . $attr->{HOST} . ":" . $attr->{RTSP_PORT} . $attr->{RTSP_PATH};
  }
  $attr->{NAME} =~ s/(?<=\w)\s(?=\w)/_/g;

  my $session = $self->_send_request({
    ACTION          => "/vsaas/api/v2/auth/login",
    POST            => "true",
    PARAMS          => {
      password => $self->{PASSWORD},
      login    => $self->{LOGIN},
    },
    SQUARE_BRACKETS => 1,
    DEL_API         => 1,
  });

  my $result = $self->_send_request({
    ACTION          => "/vsaas/api/v2/cameras/" . $attr->{NAME},
    PARAMS          => {
      stream_url      => $stream_url,
      access          => $attr->{TYPE} eq "1" ? "public" : "private",
      enabled         => "true",
      rtsp_port       => $attr->{RTSP_PORT},
      title           => $attr->{TITLE},
      owner           => $attr->{UID} || "",
      substream_url   => $attr->{EXTRA_URL} ? $attr->{EXTRA_URL} . ($add_func || "") : "",
      thumbnails_url  => $attr->{SCREENSHOT_URL} || "",
      dvr_depth       => $attr->{ARCHIVE} || "",
      dvr_protected   => $attr->{LIMIT_ARCHIVE} ? "true" : "false",
      static          => $attr->{CONSTANTLY_WORKING} ? "true" : "false",
      thumbnails      => $attr->{PRE_IMAGE} ? "true" : "false",
      thumbnails_url  => $attr->{PRE_IMAGE_URL} || "",
      organization_id => $attr->{SUBGROUP_ID} || "",
      folder_id       => $attr->{SUBFOLDER_ID} || $attr->{FOLDER_ID} || "",
    },
    COMMAND         => "PUT",
    SQUARE_BRACKETS => 1,
    SESSION         => $session->{session},
    DEL_API         => 1
  });

  if (ref $result eq "HASH" && $result->{error_message}) {
    $self->{errno} = '2416';
    $self->{errstr} = $result->{error_message};
    return $self;
  }

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

  my $cam_info = "";

  if ($attr->{list}[0]) {
    $cam_info = $attr->{list}[0];
  }
  else {
    $self->{errno} = 1006;
    $self->{errstr} = 'Camera not found';

    return $self;
  }

  my $session = $self->_send_request({
    ACTION          => "/vsaas/api/v2/auth/login",
    POST            => "true",
    PARAMS          => {
      password => $self->{PASSWORD},
      login    => $self->{LOGIN},
    },
    SQUARE_BRACKETS => 1,
    DEL_API         => 1,
  });

  $cam_info->{name} =~ s/(?<=\w)\s(?=\w)/_/g;

  $self->_send_request({
    ACTION  => "/vsaas/api/v2/cameras/" . $cam_info->{name},
    SESSION => $session->{session},
    DEL_API => 1
  });

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

  if (!$attr->{CAM_NAME}) {
    $self->{errno} = 2408;
    $self->{errstr} = 'Camera not found';

    return $self;
  }

  $attr->{CAM_NAME} =~ s/(?<=\w)\s(?=\w)/_/g;

  my $session = $self->_send_request({
    ACTION          => "/vsaas/api/v2/auth/login",
    POST            => "true",
    PARAMS          => {
      password => $self->{PASSWORD},
      login    => $self->{LOGIN},
    },
    SQUARE_BRACKETS => 1,
    DEL_API         => 1,
  });

  my $result = $self->_send_request({
    ACTION  => "/vsaas/api/v2/cameras/" . $attr->{CAM_NAME},
    COMMAND => "DELETE",
    SESSION => $session->{session},
    DEL_API => 1
  });

  if (!$result->{success}) {
    $self->{errno} = 2409;
    $self->{errstr} = 'Camera was not deleted';
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

  my $result = $self->_send_request({
    ACTION          => "/vsaas/api/v2/auth/login",
    POST            => "true",
    PARAMS          => {
      password => $attr->{PASSWORD},
      login    => $attr->{LOGIN},
    },
    SQUARE_BRACKETS => 1,
    DEL_API         => 1,
  });

  return 0 if !$result->{session} || !$attr->{camera_name};

  $attr->{camera_name} =~ s/(?<=\w)\s(?=\w)/_/g;

  $result = $self->_send_request({
    ACTION  => "/vsaas/api/v2/cameras/" . ($attr->{camera_name} || $attr->{NAME}),
    SESSION => $result->{session},
  });

  return 0 if !$result->{playback_config};

  my $src = $self->{URL} . "/vsaas/embed/" . $result->{name} . "?token=" . ($result->{playback_config}{token});

  my $camera = "<iframe style='-moz-box-shadow: 0 2px 3px rgba(0, 0, 0, 0.5); -webkit-box-shadow: 0 2px 3px rgba(0, 0, 0, 0.5);
    box-shadow: 0 2px 3px rgba(0, 0, 0, 0.5); border: 0; width: 100%; height: 303px;' allowfullscreen src='" .
    $src . "'></iframe>";

  $result->{CAMERA} = $camera;

  return $result;
}

#**********************************************************
=head2 change_user_groups($attr)


=cut
#**********************************************************
sub change_user_groups {
  my $self = shift;
  my ($attr) = @_;

  my $result = $self->_send_request({
    ACTION => "/vsaas/api/v2/users?search=" . ($attr->{LOGIN} || $attr->{UID}),
  });

  if (ref($result) eq "ARRAY" && $result->[0]{id}) {
    foreach my $group (@{$result->[0]{groups}}) {
      $self->_send_request({
        ACTION  => "/vsaas/api/v2/groups/$group->{group_id}/users/$result->[0]{id}",
        COMMAND => "DELETE",
      });
    }

    return $self if !$attr->{IDS};
    $attr->{IDS} =~ s/\s+//g;
    my @groups = split(/,/, $attr->{IDS});
    foreach my $group (@groups) {
      $self->_send_request({
        ACTION => "/vsaas/api/v2/groups/$group/users",
        POST   => 'true',
        PARAMS => {
          user_id => $result->[0]{id},
          can_dvr => $attr->{DVR} ? "true" : "false",
          can_ptz => $attr->{PTZ} ? "true" : "false",
        },
      });
    }
  }

  return $self;
}

#**********************************************************
=head2 user_negdeposit($attr)


=cut
#**********************************************************
sub user_negdeposit {
  my $self = shift;
  my ($attr) = @_;

  my $result = $self->user_info($attr);

  if (ref $result eq "HASH" && $result->{error_message} || ref $result ne "ARRAY") {
    $self->{errno} = '2410';
    $self->{errstr} = $result->{error_message} || "Error negdeposit";
    return $self;
  }

  $self->_send_request({
    ACTION          => "/vsaas/api/v2/users/" . $result->[0]{id},
    PARAMS          => {
      login    => $attr->{LOGIN} || "",
      enabled  => "false",
      password => $attr->{PASSWORD} || "test_password",
    },
    COMMAND         => "PUT",
    SQUARE_BRACKETS => 1,
  });

  return $self;
}

#**********************************************************
=head2 folder_add($attr)

   Arguments:

   Results:

=cut
#**********************************************************
sub folder_add {
  my $self = shift;
  my ($attr) = @_;

  my $result = $self->_send_request({
    ACTION          => "/vsaas/api/v2/auth/login",
    POST            => "true",
    PARAMS          => {
      password => $self->{PASSWORD},
      login    => $self->{LOGIN},
    },
    SQUARE_BRACKETS => 1,
    DEL_API         => 1,
  });

  $self->_send_request({
    ACTION          => "/vsaas/api/v2/organizations/$attr->{SUBGROUP_ID}/folders/",
    SESSION         => $result->{session},
    DEL_API         => 1,
    SQUARE_BRACKETS => 1,
  });

  if (!$attr->{PARENT_ID}) {

    my $folders = $self->_send_request({
      ACTION          => "/vsaas/api/v2/organizations/$attr->{SUBGROUP_ID}/folders/",
      SESSION         => $result->{session},
      DEL_API         => 1,
      SQUARE_BRACKETS => 1,
    });

    if (ref $folders ne "ARRAY") {
      $self->{errno} = '2411';
      $self->{errstr} = "Not found parent_id";
      return $self;
    }

    my $parent_null = 0;

    foreach my $folder (@{$folders}) {
      if (!$folder->{parent_id}) {
        $attr->{PARENT_ID} = $folder->{id};
        $parent_null = 1;
        last;
      }
    }

    if ($parent_null == 0) {
      $self->{errno} = '2411';
      $self->{errstr} = "Not found parent_id";
      return $self;
    }
  }

  my %params = (
    # id        => $attr->{INSERT_ID} || '',
    title     => $attr->{TITLE},
    parent_id => $attr->{PARENT_ID} || $attr->{SUBGROUP_ID}
  );

  $result = $self->_send_request({
    ACTION          => "/vsaas/api/v2/organizations/$attr->{SUBGROUP_ID}/folders",
    PARAMS          => \%params,
    POST            => "true",
    SESSION         => $result->{session},
    DEL_API         => 1,
    SQUARE_BRACKETS => 1,
  });

  if (ref $result eq "HASH" && $result->{error_message}) {
    $self->{errno} = '2412';
    $self->{errstr} = $result->{error_message};
    return $self;
  }

  $self->{SUBFOLDER_ID} = $result->{id};

  return $self;
}

#**********************************************************
=head2 folder_info($attr)

   Arguments:

   Results:

=cut
#**********************************************************
sub folder_info {
  my $self = shift;
  my ($attr) = @_;

  my $result = $self->_send_request({
    ACTION          => "/vsaas/api/v2/auth/login",
    POST            => "true",
    PARAMS          => {
      password => $self->{PASSWORD},
      login    => $self->{LOGIN},
    },
    SQUARE_BRACKETS => 1,
    DEL_API         => 1,
  });

  $result = $self->_send_request({
    ACTION          => "/vsaas/api/v2/organizations/$attr->{SUBGROUP_ID}/folders/" . ($attr->{SUBFOLDER_ID} || $attr->{ID}),
    SESSION         => $result->{session},
    DEL_API         => 1,
    SQUARE_BRACKETS => 1,
  });

  if (ref $result eq "HASH" && $result->{error_message}) {
    $self->{errno} = '2413';
    $self->{errstr} = $result->{error_message};
    return $self;
  }

  return $self;
}

#**********************************************************
=head2 folder_change($attr)

   Arguments:

   Results:

=cut
#**********************************************************
sub folder_change {
  my $self = shift;
  my ($attr) = @_;

  my $result = $self->_send_request({
    ACTION          => "/vsaas/api/v2/auth/login",
    POST            => "true",
    PARAMS          => {
      password => $self->{PASSWORD},
      login    => $self->{LOGIN},
    },
    SQUARE_BRACKETS => 1,
    DEL_API         => 1,
  });

  if (!$attr->{PARENT_ID}) {
    my $group = $self->_send_request({
      ACTION          => "/vsaas/api/v2/organizations/$attr->{SUBGROUP_ID}/folders",
      SESSION         => $result->{session},
      DEL_API         => 1,
      SQUARE_BRACKETS => 1,
    });

    $attr->{PARENT_ID} = $group->[0]{id};
  }

  my %params = (
    title     => $attr->{TITLE},
    parent_id => $attr->{PARENT_ID} || $attr->{SUBGROUP_ID}
  );

  $result = $self->_send_request({
    ACTION          => "/vsaas/api/v2/organizations/$attr->{SUBGROUP_ID}/folders/" . ($attr->{SUBFOLDER_ID} || $attr->{ID}),
    SESSION         => $result->{session},
    PARAMS          => \%params,
    COMMAND         => "PUT",
    DEL_API         => 1,
    SQUARE_BRACKETS => 1,
  });

  if (ref $result eq "HASH" && $result->{error_message}) {
    $self->{errno} = '2414';
    $self->{errstr} = $result->{error_message};
    return $self;
  }

  return $self;
}

#**********************************************************
=head2 folder_del($attr)

   Arguments:

   Results:

=cut
#**********************************************************
sub folder_del {
  my $self = shift;
  my ($attr) = @_;

  my $result = $self->_send_request({
    ACTION          => "/vsaas/api/v2/auth/login",
    POST            => "true",
    PARAMS          => {
      password => $self->{PASSWORD},
      login    => $self->{LOGIN},
    },
    SQUARE_BRACKETS => 1,
    DEL_API         => 1,
  });

  if (ref $result eq "HASH" && $result->{session}) {
    my $session = $result->{session};
    $result = $self->_send_request({
      ACTION          => "/vsaas/api/v2/organizations/$attr->{SUBGROUP_ID}/folders/",
      SESSION         => $result->{session},
      DEL_API         => 1,
      SQUARE_BRACKETS => 1,
    });

    $self->del_folders_tree({
      ARRAY       => $result,
      ID          => $attr->{SUBFOLDER_ID} || $attr->{ID},
      SESSION     => $session,
      SUBGROUP_ID => $attr->{SUBGROUP_ID},
    });
  }

  return $self;
}

#**********************************************************
=head2 change_user_folders($attr)

   Arguments:

   Results:

=cut
#**********************************************************
sub change_user_folders {
  my $self = shift;
  my ($attr) = @_;
  
  return $self if !$attr->{IDS};

  my $result = $self->_send_request({
    ACTION          => "/vsaas/api/v2/auth/login",
    POST            => "true",
    PARAMS          => {
      password => $self->{PASSWORD},
      login    => $self->{LOGIN},
    },
    SQUARE_BRACKETS => 1,
    DEL_API         => 1,
  });

  my $session = $result->{session};

  $result = $self->_send_request({
    ACTION => "/vsaas/api/v2/users?search=" . ($attr->{LOGIN} || $attr->{UID}),
  });

  if (ref($result) eq "ARRAY" && $result->[0]{id}) {

    return $self if !$attr->{IDS};
    $attr->{IDS} =~ s/\s+//g;
    my @folders = split(/,/, $attr->{IDS});
    foreach my $folder (@folders) {
      my $folder_info = $Cams->folder_info($folder);

      $self->_send_request({
        ACTION          => "/vsaas/api/v2/organizations/$folder_info->{SUBGROUP_ID}/users",
        POST            => 'true',
        PARAMS          => {
          user_id => $result->[0]{id},
        },
        SESSION         => $session,
        SQUARE_BRACKETS => 1,
      });

      my $subfolder_id = $folder_info->{SUBFOLDER_ID} || $folder;

      $self->_send_request({
        ACTION          => "/vsaas/api/v2/organizations/$folder_info->{SUBGROUP_ID}/folders/$subfolder_id/users",
        POST            => 'true',
        PARAMS          => {
          user_id     => $result->[0]{id},
          can_view_dvr => $attr->{DVR} ? "1" : "0",
          can_use_ptz => $attr->{PTZ} ? "1" : "0",
        },
        SESSION         => $session,
        SQUARE_BRACKETS => 1,
      });
    }
  }

  return $self;
}

#**********************************************************
=head2 del_folders_tree($attr)

   Arguments:

   Results:

=cut
#**********************************************************
sub del_folders_tree {
  my $self = shift;
  my ($attr) = @_;

  foreach my $folder (@{$attr->{ARRAY}}) {
    if ($folder->{parent_id} && $folder->{parent_id} eq $attr->{ID}) {
      $self->del_folders_tree({
        ARRAY       => $attr->{ARRAY},
        ID          => $folder->{id},
        SESSION     => $attr->{SESSION},
        SUBGROUP_ID => $attr->{SUBGROUP_ID}
      });
    }
  }

  $self->_send_request({
    ACTION          => "/vsaas/api/v2/organizations/$attr->{SUBGROUP_ID}/folders/$attr->{ID}",
    SESSION         => $attr->{SESSION},
    DEL_API         => 1,
    SQUARE_BRACKETS => 1,
    COMMAND         => "DELETE",
  });

  return 1;
}

1;