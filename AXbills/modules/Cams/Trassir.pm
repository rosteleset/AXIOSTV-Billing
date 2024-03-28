package Cams::Trassir;

=head1 NAME

  Error ID: 21xx

=head1 VERSION

  VERSION: 0.06
  Revision: 20201123

=head1 SYNOPSIS

=cut

#**********************************************************

use strict;
use warnings FATAL => 'all';

our $VERSION = 0.06;

use parent qw(dbcore);
use AXbills::Base qw(load_pmodule mk_unique_value in_array urlencode convert _bp sec2time);
use AXbills::Fetcher;
use Digest::SHA qw(hmac_sha256_hex);
my $MODULE = 'Trassir';

my ($admin, $CONF);
my $json;
my AXbills::HTML $html;
my $lang;
my $Cams;

#**********************************************************
=head2 new() - $class, $db, $admin, $CONF, $attr

=cut
#**********************************************************
sub new {
  my $class = shift;
  my $db = shift;
  $admin = shift;
  $CONF = shift;
  my $attr = shift;

  $admin->{MODULE} = $MODULE;
  $Cams = Cams->new($db, $admin, $CONF);
  $html = $attr->{HTML} if ($attr->{HTML});
  $lang = $attr->{LANG} if ($attr->{LANG});

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
  $self->{LOGIN} = $attr->{LOGIN};
  $self->{PASSWORD} = $attr->{PASSWORD};
  $self->{VERSION} = $VERSION;
  print "Content-Type: text/html\n\n" if ($self->{debug});

  return $self;
}

#**********************************************************
=head2 test($attr) - Test service

=cut
#**********************************************************
sub test {
  my $self = shift;

  my $result = $self->_login({ GET_SID => 1 });

  if (!$self->{errno} && $result) {
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
  $debug = 2 if ($self->{DEBUG_FILE} && $debug < 2);

  $request_url .= $attr->{ACTION} if ($attr->{ACTION});

  my $message = ();
  if ($attr->{PARAMS}) {
    foreach my $key (keys %{$attr->{PARAMS}}) {
      my $key_p = "\\\"$key\\\"";
      my $value = "\\\"$attr->{PARAMS}->{$key}\\\"";

      $key_p ||= '';
      $value ||= '';

      $message = defined $message ? "$message,$key_p:$value" : "$key_p:$value";
    }
  }

  my @params = ();

  my $result = '';
  push @params, 'Content-Type: application/json';

  $result = web_request($request_url, {
    HEADERS      => \@params,
    DEBUG        => $debug,
    DEBUG2FILE   => $self->{DEBUG_FILE},
    CURL         => 1,
    CURL_OPTIONS => '-k',
  });

  $result =~ s/\/\*[\s\S]*\*\///gm if ($result =~ /\/\*[\s\S]*\*\//gm);

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
=head2 user_info($attr) - user info

=cut
#**********************************************************
sub user_info {
  my $self = shift;
  my ($attr) = @_;

  return $self if !$attr->{SUBSCRIBE_ID};

  my $sid = $self->_login({ GET_SID => 1 });

  if ($sid eq '') {
    $self->{errno} = '2102';
    $self->{errstr} = "Error get sid";
    return $self;
  }

  $self->_send_request({
    ACTION => "settings/users/?sid=" . $sid,
  });

  return $self;
}

#**********************************************************
=head2 user_add($attr) - add user

=cut
#**********************************************************
sub user_add {
  my $self = shift;
  my ($attr) = @_;

  my $sid = $self->_login({ GET_SID => 1 });

  if ($sid eq '') {
    $self->{errno} = '2102';
    $self->{errstr} = "Error get sid";
    return $self;
  }

  my $old_users = $self->_get_users();

  $self->_send_request({
    ACTION => 'settings/users/user_add/new_user_name=' . $attr->{LOGIN} . '?sid=' . $sid,
  });

  $self->_send_request({
    ACTION => 'settings/users/user_add/new_user_password=' . $attr->{PASSWORD} . '?sid=' . $sid,,
  });

  my $result = $self->_send_request({
    ACTION => 'settings/users/user_add/create_now=1?sid=' . $sid,
  });

  if (ref $result ne "HASH" || !$result->{success} || $result->{success} ne '1') {
    $self->{errno} = '2103';
    $self->{errstr} = "Error user add";
    return $self;
  }

  $self->{SUBSCRIBE_ID} = $self->_get_new_user($old_users);

  return $self;
}

#**********************************************************
=head2 _login($attr) - login

=cut
#**********************************************************
sub _login {
  my $self = shift;
  my ($attr) = @_;

  return { errno => 2101 } if !$self->{LOGIN} && !$self->{PASSWORD};

  my $result = $self->_send_request({
    ACTION => 'login?username=' . $self->{LOGIN} . '&password=' . $self->{PASSWORD},
  });

  return $attr->{GET_SID} ? $result->{sid} ? $result->{sid} : '' : $result;
}

#**********************************************************
=head2 _get_users($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub _get_users {
  my $self = shift;
  my ($attr) = @_;

  my $sid = $self->_login({ GET_SID => 1 });

  if ($sid eq '') {
    $self->{errno} = '2102';
    $self->{errstr} = "Error get sid";
    return $self;
  }

  my $result = $self->_send_request({
    ACTION => 'settings/users/?sid=' . $sid,
  });

  return $result->{subdirs} || ();
}

#**********************************************************
=head2 _get_new_user$attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub _get_new_user {
  my $self = shift;
  my ($old_users) = @_;

  my $new_users = $self->_get_users();

  foreach (@{$new_users}) {
    return $_ if !in_array($_, $old_users);
  }

  return 0;
}

#**********************************************************
=head2 camera_info$attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub camera_info {
  my $self = shift;
  my ($attr) = @_;

  my $sid = $self->_login({ GET_SID => 1 });

  if ($sid eq '') {
    $self->{errno} = '2102';
    $self->{errstr} = "Error get sid";
    return $self;
  }

  $attr->{NUMBER_ID} ||= '';

  my $result = $self->_send_request({
    ACTION => "settings/ip_cameras/$attr->{NUMBER_ID}/?sid=$sid",
  });

  return $result;
}

#**********************************************************
=head2 camera_add$attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub camera_add {
  my $self = shift;
  my ($attr) = @_;

  if (!$attr->{CAMERA_MODEL}) {
    $self->{errno} = '2106';
    $self->{errstr} = "Error camera model";
    return $self;
  }

  my ($vendor, $model) = split(':\s?', $attr->{CAMERA_MODEL});

  if (!$vendor || !$model) {
    $self->{errno} = '2107';
    $self->{errstr} = "Error camera model/vendor";
    return $self;
  }

  my $sid = $self->_login({ GET_SID => 1 });

  if ($sid eq '') {
    $self->{errno} = '2102';
    $self->{errstr} = "Error get sid";
    return $self;
  }

  my $old_cameras = $self->_get_cameras();

  my $result = $self->_send_request({
    ACTION => "settings/ip_cameras/ip_camera_add/$vendor/create_model=$model?sid=" . $sid,
  });

  if (!$result->{success} && $result->{error_code}) {
    $self->{errno} = '2108';
    $self->{errstr} = $result->{error_code};
    return $self;
  }

  $self->_send_request({
    ACTION => "settings/ip_cameras/ip_camera_add/$vendor/autodetect=1?sid=" . $sid,
  });

  $self->_send_request({
    ACTION => "settings/ip_cameras/ip_camera_add/$vendor/create_address=$attr->{HOST}?sid=" . $sid,
  });

  $self->_send_request({
    ACTION => "settings/ip_cameras/ip_camera_add/$vendor/create_port=$attr->{RTSP_PORT}?sid=" . $sid,
  });

  $self->_send_request({
    ACTION => "settings/ip_cameras/ip_camera_add/$vendor/create_password=$attr->{PASSWORD}?sid=" . $sid,
  });

  $self->_send_request({
    ACTION => "settings/ip_cameras/ip_camera_add/$vendor/create_username=$attr->{LOGIN}?sid=" . $sid,
  });

  $self->_send_request({
    ACTION => "settings/ip_cameras/ip_camera_add/$vendor/autodetect_result?sid=" . $sid,
  });

  $self->_send_request({
    ACTION => "settings/ip_cameras/ip_camera_add/$vendor/create_now=1?sid=" . $sid,
  });

  $self->{NUMBER_ID} = $self->_get_new_camera($old_cameras);

  if (!$self->{NUMBER_ID}) {
    $self->{errno} = '2104';
    $self->{errstr} = "Error create camera";
  }

  $self->_send_request({
    ACTION => "settings/ip_cameras/$self->{NUMBER_ID}/name=$attr->{NAME}?sid=$sid",
  });

  my $guid = $self->_get_channels($self->{NUMBER_ID});


  return $self;
}

#**********************************************************
=head2 camera_add$attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub camera_change {
  my $self = shift;
  my ($attr) = @_;

  my $sid = $self->_login({ GET_SID => 1 });

  if ($sid eq '') {
    $self->{errno} = '2102';
    $self->{errstr} = "Error get sid";
    return $self;
  }

  if (!$attr->{NUMBER_ID} || $attr->{NUMBER_ID} eq '') {
    $self->{errno} = '2105';
    $self->{errstr} = "Error camera number";
    return $self;
  }

  $self->_send_request({ ACTION => "settings/ip_cameras/$attr->{NUMBER_ID}/name=$attr->{NAME}?sid=$sid" });

  $self->_send_request({ ACTION => "settings/ip_cameras/$attr->{NUMBER_ID}/connection_username=$attr->{LOGIN}?sid=$sid" });

  $self->_send_request({ ACTION => "settings/ip_cameras/$attr->{NUMBER_ID}/connection_password=$attr->{PASSWORD}?sid=$sid" });

  $self->_send_request({ ACTION => "settings/ip_cameras/$attr->{NUMBER_ID}/connection_port=$attr->{RTSP_PORT}?sid=$sid" });

  $self->_send_request({ ACTION => "settings/ip_cameras/$attr->{NUMBER_ID}/connection_ip=$attr->{HOST}?sid=$sid" });

  return $self;
}

#**********************************************************
=head2 camera_del$attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub camera_del {
  my $self = shift;
  my ($attr) = @_;

  my $sid = $self->_login({ GET_SID => 1 });

  if ($sid eq '') {
    $self->{errno} = '2102';
    $self->{errstr} = "Error get sid";
    return $self;
  }

  $attr->{NUMBER_ID} ||= '';

  $self->_send_request({
    ACTION => "settings/ip_cameras/grabber_delete=$attr->{NUMBER_ID}?sid=$sid",
  });

  return $self;
}

#**********************************************************
=head2 _get_cameras($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub _get_cameras {
  my $self = shift;
  my ($attr) = @_;

  my $sid = $self->_login({ GET_SID => 1 });

  if ($sid eq '') {
    $self->{errno} = '2102';
    $self->{errstr} = "Error get sid";
    return $self;
  }

  my $result = $self->_send_request({
    ACTION => 'settings/ip_cameras/?sid=' . $sid,
  });

  return $result->{subdirs} || ();
}

#**********************************************************
=head2 _get_new_camera$attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub _get_new_camera {
  my $self = shift;
  my ($old_cameras) = @_;

  my $new_cameras = $self->_get_cameras();

  foreach (@{$new_cameras}) {
    return $_ if !in_array($_, $old_cameras);
  }

  return 0;
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

  return() if !$attr->{number};
  my $result = ();

  my $guid = $self->_get_channels($attr->{number});
  return () if !$guid;

  my $sid = $self->_login({ GET_SID => 1 });

  if ($sid eq '') {
    $self->{errno} = '2102';
    $self->{errstr} = "Error get sid";
    return $self;
  }

  my $container = $CONF->{CAMS_EXTRA_LINKS} ? 'hls' : 'mjpeg';

  my $token = $self->_send_request({
    ACTION => "get_video?channel=$guid&container=$container&stream=main&sid=$sid",
  });

  return() if !$token->{token};

  if ($container eq 'mjpeg') {
    my $url = $self->{URL};
    $url =~ s/:\d{1,}/:555/g;
    $url =~ s/https/http/g;

    my $src = "$url$token->{token}";

    $result->{CAMERA} = "<a href='$src' target='_blank'><div class='row'><img class='col-md-12' " .
      "style='border: 0; width: 100%; height: 33%;' src='" . $src . "'></div></a>";
  }
  else {
    my $src = "$self->{URL}hls/$token->{token}/master.m3u8";

    my $camera = "<video id='$attr->{number}' muted autoplay controls style='width: 100%'></video>";
    $result->{CAMERA} = $camera . $self->get_script($attr->{number}, $src);
  }

  return { TOKEN => $token->{token}, SID => $sid } if ($attr->{GET_SID_TOKEN});

  return $result;
}

#**********************************************************
=head2 get_script($attr)

   Arguments:
     $number

   Results:

=cut
#**********************************************************
sub get_script {
  my $self = shift;
  my ($number, $url) = @_;

  return qq{
    <script>
      var video = document.getElementById('$number');
      var videoSrc = '$url';
      if (Hls.isSupported()) {
        var hls = new Hls();
        hls.loadSource(videoSrc);
        hls.attachMedia(video);
        hls.on(Hls.Events.MANIFEST_PARSED, function() {
          video.play();
        });
      }
      else if (video.canPlayType('application/vnd.apple.mpegurl')) {
        video.src = videoSrc;
        video.addEventListener('loadedmetadata', function() {
          video.play();
        });
      }
    </script>
  }
}

#**********************************************************
=head2 _get_channels($number)

  Arguments:

  Return:

=cut
#**********************************************************
sub _get_channels {
  my $self = shift;
  my $number = shift;

  my $sid = $self->_login({ GET_SID => 1 });

  if ($sid eq '') {
    $self->{errno} = '2102';
    $self->{errstr} = "Error get sid";
    return $self;
  }

  my $result = $self->_send_request({
    ACTION => "settings/ip_cameras/$number/?sid=$sid",
  });

  return '' if !$result->{values};

  my @channels = ();
  map $_ =~ /channel\d+_guid/ ? push(@channels, $_) : (), sort @{$result->{values}};

  foreach my $channel (@channels) {
    my $channel_info = $self->_send_request({
      ACTION => "settings/ip_cameras/$number/$channel?sid=$sid",
    });

    return $channel_info->{value} if ($channel_info->{value});
  }

  return '';
}

#**********************************************************
=head2 import_models($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub import_models {
  my $self = shift;
  my ($attr) = @_;

  my $sid = $self->_login({ GET_SID => 1 });

  if ($sid eq '') {
    $self->{errno} = '2102';
    $self->{errstr} = "Error get sid";
    return $self;
  }

  my $vendors = $self->_send_request({
    ACTION => "settings/ip_cameras/ip_camera_add/?sid=" . $sid,
  });

  my $return_vendors = ();

  foreach my $vendor (@{$vendors->{subdirs}}) {
    my $vendor_models = $self->_send_request({
      ACTION => "settings/ip_cameras/ip_camera_add/$vendor/available_models?sid=" . $sid,
    });

    next if !$vendor_models->{value} || $vendor_models->{value} eq '';

    $vendor_models->{value} =~ s/Autodetect,//g;
    @{$return_vendors->{$vendor}} = split(',', $vendor_models->{value});
  }

  return $return_vendors;
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

  return () if !$attr->{DATE};

  my $result = ();
  $result->{CAMERA} = ();

  my $guid = $self->_get_channels($attr->{NUMBER_ID});
  return () if !$guid;

  my $sid = $self->_login({ GET_SID => 1 });

  if ($sid eq '') {
    $self->{errno} = '2102';
    $self->{errstr} = "Error get sid";
    return $self;
  }

  my $token = $self->_send_request({
    ACTION => "get_video?channel=$guid&container=mjpeg&stream=archive_main&sid=$sid",
  });

  return() if !$token->{token};

  my @date_arr = split('/', $attr->{DATE});
  my $start = $date_arr[0];
  my $end = $date_arr[1];

  my ($start_date, $start_time) = split('\s', $start);
  my ($end_date, $end_time) = split('\s', $end);
  $start_date =~ s/\-//g;
  $start_time =~ s/\://g;
  $start_time .= '00';

  $end_date =~ s/\-//g;
  $end_time =~ s/\://g;
  $end_time .= '00';

  my $url = $self->{URL};
  $url =~ s/:\d{1,}/:555/g;
  $url =~ s/https/http/g;

  my $src = "$url$token->{token}";

  my $camera = "<a href='$src' target='_blank'><div class='row'><img class='col-md-12' " .
    "style='border: 0; width: 100%; height: 33%;' src='" . $src . "'></div></a>";

  push @{$result->{CAMERA}}, $camera;

  my $link = "$self->{URL}archive_command?command=play&start=$start_date" . "T$start_time&stop=$end_date" .
    "T$end_time&speed=1&sid=$sid&token=$token->{token}";

  $result->{ADDITIONAL_SCRIPT} = qq{
      jQuery.get("$link");
  };

  return $result;
}

#**********************************************************
=head2 service_report($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub service_report {
  my $self = shift;
  my ($attr) = @_;

  return '' if !$lang || !$html;

  my $sid = $self->_login({ GET_SID => 1 });
  return '' if !$sid;

  my $result = $self->_send_request({ ACTION => "health/?sid=" . $sid });

  return '' if !$result || ref($result) ne 'HASH' || !$result->{channels_total};

  my AXbills::HTML $table = $html->table({
    ID          => 'TRASSIR_REPORT',
    width       => '100%',
    caption     => $lang->{REPORT} . ': ' . ($self->{SERVICE_NAME} || ''),
    title_plain => [ $lang->{NAME}, $lang->{CAMS_DISKS}, $lang->{CAMS_DB}, $lang->{NETWORK}, $lang->{CAMS_ONLINE_CHANNELS},
      $lang->{CAMS_UPTIME}, $lang->{CAMS_CPU_LOAD}, $lang->{CAMS_ARCHIVE} ]
  });

  my %span_params = (
    '1' => 'glyphicon glyphicon-ok-circle text-green',
    '0' => 'glyphicon glyphicon-remove-circle text-red'
  );

  $result->{disks} = $html->element('span', '', { class => $span_params{$result->{disks}}, title => $lang->{CAMS_DISKS} });
  $result->{database} = $html->element('span', '', { class => $span_params{$result->{database}}, title => $lang->{CAMS_DB} });
  $result->{network} = $html->element('span', '', { class => $span_params{$result->{network}}, title => $lang->{NETWORK} });

  $table->addrow($self->{SERVICE_NAME}, $result->{disks}, $result->{database}, $result->{network},
    ($result->{channels_total} || '') . ' / ' . ($result->{channels_online} || ''), sec2time($result->{uptime}, { str => 1 }),
    ($result->{cpu_load} || '') . '%', ($result->{disks_stat_main_days} || '') . ' / ' . ($result->{disks_stat_subs_days} || ''));
  
  return $table->show();
}

1;
