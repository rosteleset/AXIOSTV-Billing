package Cams::Zoneminder_new;

=head1 NAME

=head1 VERSION

  VERSION: 0.07
  Revision: 20190904

=head1 SYNOPSIS

=cut

#**********************************************************

use strict;
use warnings FATAL => 'all';

our $VERSION = 0.07;

use parent qw(dbcore);
use AXbills::Base qw(load_pmodule mk_unique_value in_array urlencode convert _bp);
use AXbills::Fetcher;
use Data::Dumper;
use Users;
use Digest::SHA qw(hmac_sha256_hex);
my $MODULE = 'Zoneminder_new';

my ($admin, $CONF, $json, $lang, $db);
my AXbills::HTML $html;
my $Cams;
my %ORIENTATIONS = (
  1 => 90,
  2 => 180,
  3 => 270,
  4 => 'hori',
  5 => 'vert',
);

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

  #  $self->{public_key} = $attr->{LOGIN} || q{};
  #  $self->{private_key} = $attr->{PASSWORD} || q{};
  $self->{URL} = $attr->{URL} || '';
  $self->{debug} = $attr->{DEBUG} || 0;
  $self->{DEBUG_FILE} = $attr->{DEBUG_FILE};
  $self->{request_count} = 0;

  $Cams = Cams->new($db, $admin, $CONF);
  $admin = $Cams->services_list({
    NAME      => $attr->{NAME},
    MODULE    => $attr->{MODULE},
    PASSWORD  => '_SHOW',
    LOGIN     => '_SHOW',
    COLS_NAME => 1
  });
  $self->{VERSION} = $VERSION;
  $self->{ADMIN_LOGIN} = $admin->[0]->{login} || "admin";
  $self->{ADMIN_PASSWORD} = $admin->[0]->{password} || "admin";
  return $self;
}

#**********************************************************
=head2 test($attr) - Test service

=cut
#**********************************************************
sub test {
  my $self = shift;

  my $result = $self->_send_request({
    ACTION => '/api/host/getVersion.json',
  });

  if (!$self->{errno} && ref $result eq 'HASH' && $result->{version}) {
    $result = 'Ok';
  }
  else {
    $self->{errno} = 1005;
    $result = 'Unknown Error';
  }

  return $result;
}

#**********************************************************
=head2 $self->auth($UID) - get auth key

=cut
#**********************************************************
sub auth {
  my $self = shift;
  my $username = shift;
  my $pass = shift;
  my $return = shift;

  my $login = $username || $self->{ADMIN_LOGIN};
  my $password = $pass || $self->{ADMIN_PASSWORD};

  return "username=$login&password=$password" if $return;

  my $result = $self->_send_request({
    ACTION => '/api/host/login.json',
    PARAMS => '-c cookies.txt -d "user=' . $login . '&pass=' . $password . '"',
    TYPE   => '-X POST',
    AUTH   => 1,
  });

  return $result->{credentials};
}

#**********************************************************
=head2 _send_request($attr)

=cut
#**********************************************************
sub _send_request {
  my $self = shift;
  my ($attr) = @_;
  my $auth = "";
  if (!$attr->{AUTH}) {
    $auth = $self->auth($attr->{LOGIN}, $attr->{PASSWORD});
    return 0 if !$auth;
    $auth = $attr->{AND} ? '&' . $auth : '?' . $auth;
  }
  my $request_url = $self->{URL} || '';

  my $debug = (defined($attr->{DEBUG})) ? $attr->{DEBUG} : $self->{debug};
  if ($self->{DEBUG_FILE} && $debug < 2) {
    $debug = 2;
  }

  if ($attr->{ACTION}) {
    $request_url .= $attr->{ACTION} . $auth;
  }

  my $message = ();
  if ($attr->{PARAMS} && $attr->{POST}) {
    foreach my $key (keys %{$attr->{PARAMS}}) {
      my $key_p = $key;
      my $value = $attr->{PARAMS}->{$key};
      if ($message) {
        $message .= '&' . $key_p . '=' . $value;
      }
      else {
        $message = $key_p . '=' . ($value || q{});
      }
    }
  }

  my $result = '';
  if (!defined($attr->{PARAMS})) {
    $attr->{PARAMS} = "";
  }
  $attr->{TYPE} = $attr->{TYPE} ? $attr->{TYPE} : "";
  if ($attr->{POST}) {
    my @params = ();
    $params[0] = 'Content-Type: application/x-www-form-urlencoded';
    $result = web_request($request_url,
      {
        HEADERS      => \@params,
        POST         => ($message || '""'),
        DEBUG        => $debug,
        DEBUG2FILE   => $self->{DEBUG_FILE},
        CURL_OPTIONS => "-X POST",
        CURL         => 1,
      }
    );
  }
  else {
    $result = web_request($request_url,
      {
        DEBUG        => $debug,
        DEBUG2FILE   => $self->{DEBUG_FILE},
        CURL_OPTIONS => $attr->{TYPE} . ' ' . $attr->{PARAMS},
        CURL         => 1,
      }
    );
  }
  my $perl_scalar;
  if ($result =~ /<pre/gm) {
    return $self;
  }
  if ($result =~ /\{/) {
    $perl_scalar = $json->decode($result);
  }
  if (defined $perl_scalar->{success} && !$perl_scalar->{success}) {
    $perl_scalar->{errno} = 10;
    $perl_scalar->{errstr} = $perl_scalar->{data}->{message};
    $self->{errno} = 100;
    $self->{error} = 100;
    $self->{errstr} = $perl_scalar->{data}->{message};
  }
  return $perl_scalar;
}

#**********************************************************
=head2 get_request($attr) - get string request of add or edit

  Arguments:
     $attr
      LOGIN
      PASSWORD
      HOST
      RTSP_PORT
      RTSP_PATH
      NAME
      DISABLED
      CAM_ID (if edit)
      ORIENTATION

  Return:

    request string

=cut
#**********************************************************
sub get_request {
  my ($attr) = @_;

  my $host = $attr->{LOGIN} . ":" . $attr->{PASSWORD} . "@" . $attr->{HOST};
  my $port = $attr->{RTSP_PORT};
  my $path = 'rtsp://' . $host . ':' . $port . $attr->{RTSP_PATH};
  my $name = $attr->{NAME};
  my $enabled = !$attr->{DISABLED};
  my $id = $attr->{CAM_ID} ? 'Monitor[Id]=' . $attr->{CAM_ID} : "";
  my $orientation = "";
  if ($attr->{ORIENTATION} && $attr->{ORIENTATION} >= 1) {
    $orientation = 'Monitor[Orientation]=' . $ORIENTATIONS{$attr->{ORIENTATION}} . '&';
  }
  my $request = $id . "&" . $orientation . "Monitor[Enabled]=$enabled&Monitor[Name]=$name&Monitor[VideoWriter]=1" .
    "&Monitor[Function]=Mocord&Monitor[Type]=Ffmpeg&Monitor[Method]=simple&Monitor[Path]=$path&Monitor[Width]=480&Monitor[Height]=320&Monitor[Colours]=4&Monitor[MaxFPS]=25";

  return $request;
}

#**********************************************************
=head2 camera_add($attr)

   Arguments:
     $attr
       ID

   Return:
      result
=cut
#**********************************************************
sub camera_add {
  my $self = shift;
  my ($attr) = @_;

  my $request = get_request($attr);

  my $result = $self->_send_request({
    ACTION => '/api/monitors.json',
    PARAMS => '-d "' . $request . '"',
    TYPE   => '-X POST',
  });

  if ($result->{message} && $result->{message} eq "Saved") {
    my $uid = $attr->{UID};
    if ($uid) {
      $uid = $uid * 10;
      $result = $self->_send_request({
        ACTION => "/api/users/view/$uid.json",
      });

      my $allowed = $result->{user}->{User}->{MonitorIds};
      if ($allowed) {
        $allowed .= ',' . $attr->{CAM_ID};
      }
      else {
        $allowed = $attr->{CAM_ID};
      }
      $result = $self->_send_request({
        ACTION => "/api/users/edit/$uid.json",
        POST   => 'true',
        PARAMS => {
          'data[User][MonitorIds]' => $allowed,
          'user'                   => $self->{ADMIN_LOGIN},
          'pass'                   => $self->{ADMIN_PASSWORD},
        },
      });
    }
    else {
      $result = $self->_send_request({
        ACTION => "/api/users.json",
      });
      for my $user (@{$result->{users}}) {
        $user = $user->{User};
        if ($user->{System} eq 'None') {
          my $allowed = $user->{MonitorIds};

          if ($allowed) {
            $allowed .= ',' . $attr->{CAM_ID};
          }
          else {
            $allowed = $attr->{CAM_ID};
          }

          $uid = $user->{Id};
          $result = $self->_send_request({
            ACTION => "/api/users/edit/$uid.json",
            POST   => 'true',
            PARAMS => {
              'data[User][MonitorIds]' => $allowed,
              'user'                   => $self->{ADMIN_LOGIN},
              'pass'                   => $self->{ADMIN_PASSWORD},
            },
          });
        }
      }
    }
  }

  return $result;
}

#**********************************************************
=head2 camera_del($attr)

   Arguments:
     $attr
       ID

   Return:
     result

=cut
#**********************************************************
sub camera_del {
  my $self = shift;
  my ($attr) = @_;

  my $id = $attr->{del_cam};
  return 0 if !$id;

  my $uid = $attr->{UID};
  my $result;
  my @allowed = ();
  my $ind;

  if ($uid) {
    $uid = $uid * 10;
    $result = $self->_send_request({
      ACTION => "/api/users/view/$uid.json",
    });

    @allowed = split(',', $result->{user}->{User}->{MonitorIds});
    $ind = index($id, @allowed);

    if ($ind != -1) {
      delete $allowed[$ind];
      my $avaible = join(',', @allowed);

      $result = $self->_send_request({
        ACTION => "/api/users/edit/$uid.json",
        POST   => 'true',
        PARAMS => {
          'data[User][MonitorIds]' => $avaible,
          'user'                   => $self->{ADMIN_LOGIN},
          'pass'                   => $self->{ADMIN_PASSWORD},
        },
      });
    }
  }
  else {
    $result = $self->_send_request({
      ACTION => "/api/users.json",
    });

    for my $user (@{$result->{users}}) {
      $user = $user->{User};
      if ($user->{System} && $user->{System} eq 'None' && $user->{MonitorIds}) {
        @allowed = split(',', $user->{MonitorIds});
        $ind = index($id, @allowed);

        if ($ind != -1) {

          delete $allowed[$ind];

          my $avaible = @allowed ? join(',', @allowed) : "";

          $uid = $user->{Id};
          $result = $self->_send_request({
            ACTION => "/api/users/edit/$uid.json",
            POST   => 'true',
            PARAMS => {
              'data[User][MonitorIds]' => $avaible,
              'user'                   => $self->{ADMIN_LOGIN},
              'pass'                   => $self->{ADMIN_PASSWORD},
            },
          });
        }
      }
    }
  }

  $result = $self->_send_request({
    ACTION => '/api/monitors/' . $id . '.json',
    TYPE   => '-X DELETE',
  });

  return $result;
}

#**********************************************************
=head2 camera_change($attr)

   Arguments:
     $attr
       ID

   Return:
    result

=cut
#**********************************************************
sub camera_change {
  my $self = shift;
  my ($attr) = @_;

  my $id = $attr->{ID};

  my $request = get_request($attr);

  my $result = $self->_send_request({
    ACTION => '/api/monitors/' . $id . '.json',
    PARAMS => '-b cookies.txt -d "' . $request . '"',
    TYPE   => '-X POST',
  });

  return $result;
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

  my $result;
  my $id = $attr->{camera_id};

  if ($id) {
    my $auth = $self->auth($attr->{LOGIN}, $attr->{PASSWORD});
    return 0 if !$auth;
    my $src = $self->{URL} . "/cgi-bin/nph-zms?monitor=$id&$auth&scale=auto";

    # my $camera = "<video class='col-md-12' controls> <source src='http://nabat.com.ua/zm/?view=view_video&eid=214&$auth' type='video/mp4'></video>";
    my $camera = "<a href='$src' target='_blank'><div class='row'><img class='col-md-12' style='border: 0; width: 100%; height: 303px;' src='" . $src . "'></div></a>";
    #my $camera = "<video width='410' height='300'><source src='$src'></video>";
    # my $camera = "<iframe scrolling='no' style='width:410px; height:300px;' allowfullscreen src='" . $src . "'></iframe>";

    $result->{CAMERA} = $camera;
  }

  return $result;
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
    $self->{err_str} = 'Camera not found';

    return $self;
  }

  my $id = $attr->{list}[0]->{id};

  $cam_info->{name} =~ s/(?<=\w)\s(?=\w)/_/g;

  $self->_send_request({
    ACTION => "/api/monitors/$id.json",
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

  my $result;

  if ($attr->{PASSWORD}) {
    my $password = $self->query('SELECT PASSWORD("' . $attr->{PASSWORD} . '")')->{list}[0][0];
    $result = $self->_send_request({
      ACTION => "/api/users/add.json",
      POST   => 'true',
      PARAMS => {
        '_method'                => "POST",
        'data[User][Id]'         => $attr->{UID} * 10,
        'data[User][Username]'   => $attr->{LOGIN} || "",
        'data[User][Password]'   => $password || "test_password",
        'data[User][MonitorIds]' => '0',
        'data[User][Stream]'     => 'View',
        'data[User][Monitors]'   => 'View',
        'data[User][Events]'     => 'View',
        'user'                   => $self->{ADMIN_LOGIN},
        'pass'                   => $self->{ADMIN_PASSWORD},
      },
    });
  }

  return $result;
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

  my $uid = $attr->{UID} * 10;

  my $result;
  if (!$Cams->_list({ UID => $attr->{UID}, COLS_NAME => 1, })) {
    my $cameras = $Cams->streams_list({
      UID       => $attr->{UID},
      COLS_NAME => 1,
    });
    foreach my $cam ($cameras) {
      $self->camera_del({
        del_cam => $cam->[0]->{id},
        UID     => $attr->{UID}
      });
      $Cams->stream_del({
        ID => $cam->[0]->{id}
      })
    }

    $result = $self->_send_request({
      ACTION => "/api/users/delete/$uid.json",
      POST   => 'true',
      PARAMS => {
        'user' => $self->{ADMIN_LOGIN},
        'pass' => $self->{ADMIN_PASSWORD},
      },
    });
  }

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

  my $password = $self->query('SELECT PASSWORD("' . $attr->{PASSWORD} . '")')->{list}[0][0];
  my $uid = $attr->{UID} * 10;

  my $result = $self->_send_request({
    ACTION => "/api/users/edit/$uid.json",
    POST   => 'true',
    PARAMS => {
      'data[User][Username]' => $attr->{LOGIN} || "",
      'data[User][Password]' => $password || "test_password",
      'user'                 => $self->{ADMIN_LOGIN},
      'pass'                 => $self->{ADMIN_PASSWORD},
    },
  });

  return $result;
}

#**********************************************************
=head2 get_archive($attr)

   Arguments:
     $attr

   Results:

=cut
#**********************************************************
sub get_archive {
  my $self = shift;
  my ($attr) = @_;

  my $result;
  my $id = $attr->{id};
  my $date = "";

  if ($attr->{DATE}) {
    my @date_arr = split('/', $attr->{DATE});
    my $start_time = $date_arr[0];
    my $end_time = $date_arr[1];
    $date = "StartTime%20>=:$start_time:00/EndTime%20<=:$end_time:00.json"
  }

  if ($id) {
    my $page = 0;
    my $nextPage = 1;
    while ($nextPage) {
      $page++;
      $result = $self->_send_request({
        ACTION   => "/api/events/index/MonitorId:" . $id . "/" . $date . ".json?page=" . $page,
        TYPE     => '-X GET',
        LOGIN    => $attr->{LOGIN},
        PASSWORD => $attr->{PASSWORD},
        AND      => 1,
      });
      $nextPage = $result->{pagination}->{nextPage};
      pop @{$result->{events}};
      foreach my $event (reverse @{$result->{events}}) {
        $event = $event->{Event};

        my $auth = $self->auth($attr->{LOGIN}, $attr->{PASSWORD}, 1);

        next if !$auth;
        my $eid = $event->{Id};
        my $src = $self->{URL} . "/index.php?mode=mpeg&format=h264&eid=$eid&view=view_video&" . $auth;

        my $archive = "<video width='410' height='300' controls><source src='$src'></video>";
        push @{$result->{CAMERA}}, $archive;
      }
    }
  }
  return $result;
}

#**********************************************************
=head2 change_user_cameras($attr)

=cut
#**********************************************************
sub change_user_cameras {
  my $self = shift;
  my ($attr) = @_;

  my $uid = $attr->{UID};
  my $result = "";
  if ($uid) {
    $uid = $uid * 10;
    $result = $self->_send_request({
      ACTION => "/api/users/view/$uid.json",
    });

    my $allowed = $result->{user}->{User}->{MonitorIds};

    if ($allowed) {
      $allowed .= ',' . $attr->{IDS} if $attr->{IDS};
    }
    else {
      $allowed = $attr->{IDS} if $attr->{IDS};
    }

    $allowed =~ (s/\s//g);

    $result = $self->_send_request({
      ACTION => "/api/users/edit/$uid.json",
      POST   => 'true',
      PARAMS => {
        'data[User][MonitorIds]' => $allowed,
        'user'                   => $self->{ADMIN_LOGIN},
        'pass'                   => $self->{ADMIN_PASSWORD},
      },
    });

  }

  return 1;
}

1;

