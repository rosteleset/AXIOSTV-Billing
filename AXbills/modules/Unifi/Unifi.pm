package Unifi;

=head NAME

  UNIFI API v4

  VERSION: 0.16
  REVISION: 2016-10-25


  Useful links
  https://github.com/malle-pietje/UniFi-API-browser/blob/master/phpapi/class.unifi.php

=cut

use strict;
use warnings FATAL => 'all';

BEGIN{
  unshift ( @INC, "../../../lib/" );
}

use AXbills::Base qw( _bp load_pmodule);
use AXbills::Fetcher;

my $debug = 0;
our $VERSION = 0.16;

#Pathes inside API
my %OBJPATH = (
  WLAN    => 'list/wlanconf',
  AP      => 'stat/device',
  USERS   => 'stat/sta',
  STATS   => 'stat/alluser',
  SESSION => 'stat/session',
  SYSINFO => 'stat/sysinfo',
  ALARM   => 'list/alarm',
  DAILY_SITE => 'stat/report/daily.site'
);

load_pmodule('JSON');
my $unifi_version;

#***************************************************************
#
#***************************************************************
sub new {
  my $class = shift;
  my ($CONF) = @_;

  my $self = { };
  bless( $self, $class );

  $self->{unifi_url} = $CONF->{UNIFI_URL} || q{};
  $self->{login}     = $CONF->{UNIFI_USER} || q{};
  $self->{password}  = $CONF->{UNIFI_PASS} || q{} ;
  $unifi_version     = $CONF->{UNIFI_VERSION} || 4;
  $self->{unifi_sitename} = $CONF->{UNIFI_SITENAME} || 'default';
  $self->{FILE_CURL} = $CONF->{FILE_CURL};
  $self->{api_path}  = "$self->{unifi_url}/api/s/$self->{unifi_sitename}";
  $debug = $CONF->{unifi_debug} || 0;
  if ($debug && $debug > 2) {
    $self->{debug} = $debug;
  }
  return $self;
}

#**********************************************************
=head2 get_api_list($api_path, [ params ]) - request list from Unifi

$api_path - as defined in $OBJPATH

=cut
#**********************************************************
sub get_api_list {
  my $self=shift;
  my ($api_path, $params) = @_;

  $self->login();

  if($self->{errno}) {
    return []
  }

  my $path = $self->{unifi_url} . "/api/s/$self->{unifi_sitename}/" . $api_path;
  $self->mk_request( $path, $params );
  my $list = $self->{list} || [];

  $self->logout();
  return $list;
}

#***************************************************************
=head2 users_list() - Get connected users

=cut
#***************************************************************
sub users_list{
  my $self = shift;
  return $self->get_api_list($OBJPATH{USERS});
}

#**********************************************************
=head2 users_stats() - Get statistics for all users

  Arguments:
    $filters - hash_ref of unifi-specific parameters
      within - filter by time ( default: last 24 hours)

  Returns:
    list

=cut
#**********************************************************
sub users_stats {
  my $self = shift;
  my ($filters) = @_;

  my %default_filters = (
    conn   => 'all',      # type of client connection
    type   => 'guest',    # type of client
    within => 24          # hours
  );

  return $self->get_api_list($OBJPATH{STATS}, { %default_filters, %{ (ref $filters eq 'HASH') ? $filters : {} } });
}

#***************************************************************
=head2 devices_list() - Get device list

=cut
#***************************************************************
sub devices_list{
  my $self = shift;
  return $self->get_api_list($OBJPATH{AP});
}

#********************************************************************
=head2 login($attr) - Device auth

=cut
#********************************************************************
sub login{
  my $self = shift;

  my $login_path = "$self->{unifi_url}/api/login";

  my %request_params = (
    username => $self->{login},
    password => $self->{password},
    login    => 'login'
  );

  return $self->mk_request( $login_path, \%request_params, { LOGIN => 1 } );
}

#***************************************************************
=head2 logout() - Log out from NAS

=cut
#***************************************************************
sub logout{
  my $self = shift;
  return $self->mk_request( "$self->{unifi_url}/api/logout", undef, { CLEAR_COOKIE => 1, LOGOUT => 1 } );
}

#***************************************************************
=head2 mk_request() - Make request to NAS

  Arguments:
    $url             - Request url
    $request_params  - Request params (Hash_ref)
    $attr            - extra attr
      DEBUG
      METHOD         - string (Default: post)

  Result:
    TRUE or FALSE
      $self->{errno}
      $self->{errstr}

=cut
#***************************************************************
sub mk_request{
  my $self = shift;
  my ($url, $request_params, $attr) = @_;

  # authenticate against unifi controller
  my $json_result = web_request( $url, {
      REQUEST_PARAMS_JSON => $request_params,
      DEBUG               => $attr->{DEBUG} || $self->{debug},
      CURL                => 1,
      FILE_CURL           => $self->{FILE_CURL},
      COOKIE              => 1,
      HEADERS             => [ "Content-Type: application/json" ],
      JSON_RETURN         => 1,
      INSECURE            => 1,
      CLEAR_COOKIE        => $attr->{CLEAR_COOKIE},
      GET                 => ($attr->{METHOD} && $attr->{METHOD} eq 'get') ? 1 : undef,
      POST                => ($attr->{METHOD} && $attr->{METHOD} eq 'get') ? undef : 1
    } );

  if ( $attr->{DEBUG} ){
    _bp( "JSON REQUEST DATA", $request_params );
    _bp( "JSON RESULT", $json_result );
  }

  if ( $json_result && ref $json_result eq 'HASH' ){
    if ( $json_result->{meta} && $json_result->{meta}->{rc} && $json_result->{meta}->{rc} eq 'ok' ){
      if ( $attr->{LOGIN}  || $attr->{LOGOUT} ){
        return 1;
      }
      else{
        $self->{list} = $json_result->{data};
      }
      return 1;
    }

    $self->{errno} = $json_result->{meta}->{rc} || 0;
    $self->{errstr} = $json_result->{meta}->{msg} || q{};
  }

  return 0;
}

#********************************************************************
=head2 authorize($attr)

=cut
#********************************************************************
sub authorize{
  my $self = shift;
  my ($attr) = @_;

  $self->login();

  my %login_data_json = (
    cmd       => 'authorize-guest',
    'mac'     => $attr->{MAC},
    'minutes' => $attr->{TIME},
    'down'    => $attr->{DOWN},
    'up'      => $attr->{UP}
  );

  my $response = $self->mk_request( "$self->{api_path}/cmd/stamgr", \%login_data_json );

  $self->logout();

  if ( $debug ){
    _bp( "Authorize: Data: ", \%login_data_json );
    _bp( "Authorize: Response: ", $response );
  }

  return $response;
}

#********************************************************************
=head2 deauthorize($attr) - Hangup user

  Arguments:
    $attr
      MAC

  Returns:

=cut
#********************************************************************
sub deauthorize{
  my $self = shift;
  my ($attr) = @_;

  $self->login();

  my %request_params = (
    'cmd' => 'unauthorize-guest',
    'mac' => $attr->{MAC}
  );

  my $response = $self->mk_request( "$self->{api_path}/cmd/stamgr", \%request_params );

  $self->logout();

  if ( $debug ){
    _bp( "Deauthorize: Data: ", \%request_params );
    _bp( "Deauthorize: Response: ", $response );
  }

  return $self;
}

#********************************************************************
=head2 disconnect($attr) -

  Arguments:
    $attr
       MAC

=cut
#********************************************************************
sub disconnect{
  my $self = shift;
  my ($attr) = @_;
  my $usermac = $attr->{MAC} or return 0;

  $self->login();

  my %login_data = (
    'cmd' => 'kick-sta',
    'mac' => $usermac
  );

  my $response = $self->mk_request( "$self->{api_path}/cmd/stamgr", \%login_data );

  $self->logout();

  if ( $debug ){
    _bp( "Login data", \%login_data );
    _bp( "Disconnect response", $response );
  }

  return $response;
}

sub restart_ap{
  my $self = shift;
  my ($attr) = @_;

  my $ap_mac = $attr->{MAC} or return 0;

  $self->login();

  my %login_data = (
    'cmd' => 'restart',
    'mac' => $ap_mac
  )
  ;
  my $response = $self->mk_request( "$self->{api_path}/cmd/devmgr", \%login_data );

  $self->logout();

  if ( $debug ){
    _bp( "Login data", \%login_data );
    _bp( "Disconnect response", $response );
  }

  return $response;
}

#***************************************************************
=head2 sys_info() - Sysinfo

=cut
#***************************************************************
sub sys_info {
  my $self = shift;

  return $self->get_api_list($OBJPATH{SYSINFO});
}

#***************************************************************
=head2 alarms() - Sysinfo

=cut
#***************************************************************
sub alarms {
  my $self = shift;

  return $self->get_api_list($OBJPATH{ALARM});
}

#***************************************************************
=head2 daily_site() - Sysinfo

=cut
#***************************************************************
sub daily_site {
  my $self = shift;

  return $self->get_api_list($OBJPATH{DAILY_SITE});
}

#********************************************************************
=head2 convert_result($data_hash)

=cut
#********************************************************************
sub convert_result{
  my $self = shift;
  my ($data_hash) = @_;
  my ($lld_data);

  my $lld_item = 0;

  foreach my $hash_ref ( @{ $data_hash } ){
    $lld_data->{'data'}->[$lld_item]->{'{ALIAS}'} = $hash_ref->{'model'};
    $lld_data->{'data'}->[$lld_item]->{'{NAME}'} = $hash_ref->{'_name'} || $hash_ref->{'name'};
    $lld_data->{'data'}->[$lld_item]->{'{IP}'} = $hash_ref->{'ip'};
    $lld_data->{'data'}->[$lld_item]->{'{ID}'} = $hash_ref->{'_id'};
    $lld_data->{'data'}->[$lld_item]->{'{MAC}'} = $hash_ref->{'mac'};
    $lld_data->{'data'}->[$lld_item]->{'{OUI}'} = $hash_ref->{'oui'};
    $lld_data->{'data'}->[$lld_item]->{'{SIGNAL}'} = $hash_ref->{'signal'};
    $lld_data->{'data'}->[$lld_item]->{'{AUTHORIZED}'} = $hash_ref->{'authorized'};
    $lld_data->{'data'}->[$lld_item]->{'{RECEIVED}'} = $hash_ref->{'rx_bytes'};
    $lld_data->{'data'}->[$lld_item]->{'{TRANSMIT}'} = $hash_ref->{'tx_bytes'};
    $lld_data->{'data'}->[$lld_item]->{'{SPEEDDOWN}'} = $hash_ref->{'rx_rate'};
    $lld_data->{'data'}->[$lld_item]->{'{SPEEDUP}'} = $hash_ref->{'tx_rate'};
    $lld_data->{'data'}->[$lld_item]->{'{ADOPTED}'} = $hash_ref->{'adopted'};
    $lld_data->{'data'}->[$lld_item]->{'{HOSTNAME}'} = $hash_ref->{'hostname'};
    $lld_data->{'data'}->[$lld_item]->{'{UPTIME}'} = $hash_ref->{'_uptime'} || $hash_ref->{uptime};

    $lld_item++;
  }

  return $lld_data;
}


1;
