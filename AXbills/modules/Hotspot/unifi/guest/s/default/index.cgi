#!/usr/bin/perl
#********************************************************************

=head1 NAME
  ABillS UniFi Controller Hotspot Portal

  This script is used to serve hotspot clients
  Uses LWP for connection to UniFi API

  Should be used with ABillS, cause of pseudo Radius authorization

  Must be placed in axbills/cgi-bin/guest/s/$conf{UNIFI_SITENAME} folder

  Uses axbills/cgi-bin/styles/default/ folder for Bootstrap, Jquery, etc assets


=head1 CONFIG
  Parameters in config.pl

  URL of your UniFi dashboard
  $conf{UNIFI_URL} = 'https://xx.xx.xx.xx:yyyy';

  IP address of UniFi controller (for Radius authorization)
  $conf{UNIFI_IP} = 'xx.xx.xx.xx';

  Administrator credentials
  $conf{UNIFI_USER} = 'UNIFI_ADMIN_USER';
  $conf{UNIFI_PASS} = 'UNIFI_ADMIN_USER_PASSWORD';

  Version of your controller
  $conf{UNIFI_VERSION} = 4;

  Name of served UniFi site
  $conf{UNIFI_SITENAME} = 'default';

  $conf{UNIFI_DEFAULT_LANGUAGE} = 'english';

  External cmd if auch 'ACCESS'
  $conf{UNIFI_EXTERNAL_CMD} = '';

=head1 VERSION

  VERSION: 0.5
  REVISION: 20161028

=cut

use strict;
use warnings FATAL => 'all';

BEGIN {
  our $libpath = '../../../../../../../';
  our %conf;
  do "$libpath/libexec/config.pl";
  my $sql_type = $conf{dbtype} || 'mysql';

  unshift(@INC, $libpath, $libpath . "AXbills/$sql_type/", $libpath . 'AXbills/modules/', $libpath . "lib/");

  eval { require Time::HiRes; };
  our $begin_time = 0;
  if (!$@) {
    Time::HiRes->import(qw(gettimeofday));
    $begin_time = Time::HiRes::gettimeofday();
  }
}

use AXbills::Defs;
use AXbills::Base qw(urldecode urlencode mk_unique_value gen_time _bp cmd);
use Nas;
use Log;
use Auth2;
use Hotspot;
use Unifi::Unifi;
use AXbills::Templates;

our %COOKIES;
our %lang;

my $db = AXbills::SQL->connect($conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd}, { %conf, CHARSET => ($conf{dbcharset}) ? $conf{dbcharset} : undef });

my $html = AXbills::HTML->new(
  {
    CONF    => \%conf,
    CHARSET => $conf{default_charset},
  }
);

$html->{language} = $conf{UNIFI_DEFAULT_LANGUAGE} || 'russian';

if (defined($FORM{language}) && $FORM{language} =~ /^[a-z_]+$/) {
  $html->{language} = $FORM{language};
}

$html->{show_header} = 1;

do "$libpath/language/$html->{language}.pl";

my $Nas = Nas->new($db, \%conf);
my $Log = Log->new($db, \%conf);
my $Hotspot = Hotspot->new($db, undef, \%conf);

$Log->{ACTION} = 'AUTH';

if ($ENV{REDIRECT_QUERY_STRING} && !$ENV{QUERY_STRING}) {
  $ENV{QUERY_STRING} = $ENV{REDIRECT_QUERY_STRING};
}

form_parse();
if ($FORM{id}) {
  $FORM{id} = urldecode($FORM{id});
}
if ($FORM{ap}) {
  $FORM{ap} = urldecode($FORM{ap});
}

my $TEST_MAC = '12:34:56:78:90:ab';

if ($FORM{ap}) {
  $Nas->info({ CALLED_STATION_ID => $FORM{ap} });

  if (!$Nas->{errno}) {
    # Multiple sitenames case
    $conf{UNIFI_URL}     = 'https://' . $Nas->{NAS_IP} . ':8443';
    $conf{UNIFI_USER}    = $Nas->{NAS_MNG_USER};
    $conf{UNIFI_PASS}    = $Nas->{NAS_MNG_PASSWORD};
    $conf{UNIFI_VERSION} = 4;
    $ENV{REQUEST_URI}    =~ /\/guest\/s\/(\W+)\//;
    $conf{UNIFI_SITENAME} = $1 || $Nas->{NAS_IDENTIFIER};
  }

  # General controller case
  elsif ($Nas->{errno} == 2 && $conf{UNIFI_URL}) {
    $conf{UNIFI_VERSION} = 4;
    $ENV{REQUEST_URI} =~ /\/guest\/s\/(\w+)\//;
    $conf{UNIFI_SITENAME} = $1 || 'default';
    my $list = $Nas->list({ NAS_IDENTIFIER => $conf{UNIFI_SITENAME}, COLS_NAME => 1, PAGE_ROWS => 2 });
    if($Nas->{TOTAL} > 0) {
      $Nas->info({ NAS_ID => $list->[0]->{nas_id} });
      # Multiple sitenames case
      $conf{UNIFI_URL} = 'https://'.$list->[0]->{nas_ip}.':8443';
      $conf{UNIFI_USER} = $list->[0]->{nas_mng_user};
      $conf{UNIFI_PASS} = $list->[0]->{nas_mng_password};
      $conf{UNIFI_VERSION} = 4;
    }
  }
  else {
    $html->message('err', 'ERROR', $Nas->{errno} . "UNKNOWN_NAS IP: $ENV{REMOTE_ADDR} NAS_MAC: $FORM{ap}" . "\n Script URL: $ENV{'SCRIPT_NAME'} " . "\n Redirect: " . ($ENV{'REDIRECT_URL'} || '-') . "\n Request: $ENV{'REQUEST_URI'}");

    exit 0;
  }
}
elsif (!$conf{UNIFI_URL}) {
  print $html->header();
  $html->message(
    'err', 'ERROR',
    "NOT DEFINED AP MAC UNKNOWN_NAS IP: $ENV{REMOTE_ADDR} NAS_MAC: "
    . ($FORM{ap} || '')
    . "\n Query string: ". ($ENV{QUERY_STRING}  || q{})

    #. "\n Script URL: $ENV{'SCRIPT_NAME'} "
    #. "\n Redirect: ". ($ENV{'REDIRECT_URL'} || '-')
    #. "\n Request: $ENV{'REQUEST_URI'}"
  );

  exit 0;
}

#Set to 0 to disable. Any non-zero value means full debug
my $debug = $conf{UNIFI_DEBUG} || $FORM{DEBUG} || 0;

if ($debug > 4) {
  _bp({ HEADER => 1 });
  $conf{unifi_debug} = $debug;
}
my $Unifi = Unifi->new(\%conf);

#saving Client IP
my $input          = '';
my $userip         = '';
my $usermac        = '';
my $username       = '';
my $password       = '';
my $challenge      = '';
my $apmac          = '';
my $userurl        = '';
my $ssid           = '';
my $return_url     = '';
my $res            = '';
my $clientstate    = 0;
my $userurldecode  = '';
my $operation_type = '';

my $result = read_query_parameters();

#RUN MAIN FUNCTION
print "Content-Type: text/html\n\n";
main();

#**********************************************************
=head2 main() -   MAIN FUNCTION

=cut
#**********************************************************
sub main {

  print_header();

  my $all_clients_data;
  my $current_client_data;

  if ($result == 2) {

    $all_clients_data = $Unifi->convert_result($Unifi->users_list());

    if ($Unifi->{errno}) {
      print "[$conf{UNIFI_SITENAME}] $Unifi->{errno} / $Unifi->{errstr}";
    }

    my $index = get_user_index($all_clients_data, $usermac);

    #if there's no client with such MAC at Uni-Fi response
    if ($index eq -1) {
      $html->tpl_show(_include('unifi_unrecognized_mac', 'Unifi'), { USERMAC => $usermac });
      $Log->log_print('LOG_ERR', $username, "UNRECOGNIZED MAC: $usermac IP: $userip SITE: $conf{UNIFI_SITENAME} AP: $apmac", { NAS => $Nas });
      exit(0);
    }

    $current_client_data = $all_clients_data->{'data'}[$index];

    $clientstate = $current_client_data->{'{AUTHORIZED}'};
    $userip      = $current_client_data->{'{IP}'};

    print "<br><b>clientstate: </b>'" . $clientstate . "'<br />" if ($debug);
    print "<br><b>index: </b>'" . $index . "'<br />"             if ($debug);
  }
  elsif ($result == 3) {
    $clientstate = 0;
    $userip      = '192.168.0.1';
  }

  #if unauthorized
  if ($clientstate eq 0) {
    print_login_form($current_client_data);
  }    #if authorized
  elsif ($clientstate eq 1) {
    print_status_form();
  }

  $Hotspot->visits_add({ ID => $current_client_data->{'{ID}'}, });

  $Hotspot->user_agents_add(
    {
      ID         => $current_client_data->{'{ID}'},
      USER_AGENT => $ENV{HTTP_USER_AGENT}
    }
  );

  print_footer();

  return 1;
}

#********************************************************************
=head2 get_user_index($list, $user_mac)

=cut
#********************************************************************
sub get_user_index {
  my ($list, $mac) = @_;
  my $index = -1;

  my $arr = $list->{data};
  for (my $i = 0 ; $i <= $#{$arr} ; $i++) {
    if ($arr->[$i]->{'{MAC}'} eq $mac) {
      $index = $i;
      last;
    }
  }

  return $index;
}

#********************************************************************

=head2 authorize_client() - Function to tell billing to authorize client


  Returns:
   JSONP
   aAuthentificator.updateStatus({
     'status' : '1' if Authorized, '0' if Unauthorized
     'message': 'Message'
   });

=cut

#********************************************************************
sub authorize_client {
  `echo "------- $usermac" >> /tmp/unifi_ap` if ($debug);
  print "Content-Type: application/javascript\n\n";    # if ($debug);
  print "/*" if ($debug);
  my $message    = '';
  my $data       = $Unifi->convert_result($Unifi->users_list());
  my $index      = get_user_index($data, $usermac);
  my $session_id = '';

  if ($index > -1) {
    $session_id = $data->{'data'}[$index]->{'{ID}'};
    $userip     = $data->{'data'}[$index]->{'{IP}'} || '';
  }
  my $lower_case_user_mac = lc($usermac);

  my $Auth = Auth2->new($db, \%conf);
  my %RAD = (
    'Acct-Status-Type'   => 1,
    'User-Name'          => $username,
    'Password'           => $password,
    'Acct-Session-Id'    => $session_id || mk_unique_value(10),
    'Framed-IP-Address'  => $userip || '',
    'Calling-Station-Id' => $lower_case_user_mac || '',
    'Called-Station-Id'  => $Nas->{NAS_MAC} || $FORM{ap},
    'NAS-IP-Address'     => $Nas->{NAS_IP} || $conf{'UNIFI_IP'},
    'Connect-Info'       => $session_id,
  );
  $Nas->{NAS_TYPE} = 'unifi';
  $Auth->{debug} = 1 if ($debug);

  my ($r, $RAD_PAIRS) = $Auth->auth(\%RAD, $Nas, { SECRETKEY => $conf{secretkey} });

  my %user_info = (
    'MAC'  => $usermac || '',
    'TIME' => ($RAD_PAIRS->{'Session-Timeout'})          ? int($RAD_PAIRS->{'Session-Timeout'})                 : 0,
    'UP'   => ($RAD_PAIRS->{'WISPr-Bandwidth-Max-Up'})   ? int($RAD_PAIRS->{'WISPr-Bandwidth-Max-Up'} / 1024)   : '',
    'DOWN' => ($RAD_PAIRS->{'WISPr-Bandwidth-Max-Down'}) ? int($RAD_PAIRS->{'WISPr-Bandwidth-Max-Down'} / 1024) : ''
  );

  #if authorize allowed
  my $GT = gen_time($begin_time);
  if ($r == 0) {
    $Log->log_print('LOG_INFO', $username, "$userip $usermac" . (($GT) ? " $GT" : ''), { NAS => $Nas });

    #send request to UniFi
    $Unifi->authorize(\%user_info);

    require Users;
    my $Users = Users->new($db, \%conf, undef);
    my $user = $Users->list({ LOGIN => $username, COLS_NAME => 1, LIMIT => 1 });

    my $uid = 0;
    if ($user && ref $user eq 'ARRAY') {
      $uid = $user->[0]->{uid};
    }

    $Hotspot->logins_add(
      {
        VISIT_ID => $session_id,
        UID      => $uid
      }
    );

    # give UniFi controller some time to authorize client
    sleep 1;
    $message = "<div class='alert alert-success'>$lang{SUCCESS}</div>";
    if ($conf{UNIFI_EXTERNAL_CMD}) {

      my $cmd = $conf{UNIFI_EXTERNAL_CMD};
      cmd($cmd, {
          DEBUG   => $debug || 0,
          PARAMS  => { %FORM },
          ARGV    => 1,
          timeout => 30
      });
    }
  }
  else {
    $Log->log_print('LOG_WARNING', $username, "$userip $usermac " . $RAD_PAIRS->{'Reply-Message'} . (($GT) ? " $GT" : ''), { NAS => $Nas });
    $message = "<div class='alert alert-danger'>$lang{ERROR}: " . $RAD_PAIRS->{'Reply-Message'} . "!</div>";
  }

  print "*/" if ($debug);

  # Normal response
  #  print "Content-Type: application/javascript\n\n" if (!$debug);
  print << "STATUS_JSON";
        aAuthentificator.updateStatus({
          "status" : "$r",
          "id" : "$usermac",
          "message" : "$message",
          "timeleft" : "$user_info{TIME}",
          "speedDown" : "$user_info{DOWN}",
          "speedUp"  : "$user_info{UP}",
          "userIP" : "$userip",
          "userName" : "$username"
        });
STATUS_JSON

  return;
}

#********************************************************************
=head2 deauthorize_client()

=cut
#********************************************************************
sub deauthorize_client {
  $Unifi->deauthorize({ MAC => $usermac });

  sleep 1;

  print "Content-Type: application/javascript\n\n";
  print "
    aAuthentificator.updateStatus({
      \"status\" : \"-1\",
      \"message\" : \"You have been successfully loged out\"
    });";

  return 1;
}

#********************************************************************
=head2 get_status_update($mac)

=cut
#********************************************************************
sub get_status_update {
  my ($mac) = $_[0];

  $Unifi->login();
  if ($debug) {
    print "Content-Type: application/javascript\n\n";
    print "/*";
    print qq{<BR>GET STATUS<BR>};
    print qq{<b>MAC : </b> $mac <br>};
  }
  if ($mac) {
    my $data = $Unifi->convert_result($Unifi->users_list());
    my $index = get_user_index($data, $usermac);

    #if there's no client with such MAC at Uni-Fi response
    if ($index eq -1) {
      print "Content-Type: application/javascript\n\n";
      print qq{
              jQuery('#content').html('<div class='alert alert-danger'> Your device is not registered on hotspot. MAC: $mac ... </div>');
              setTimeout(function(){window.location.reload(true)}, 5*1000);
            };

      $Log->log_print('LOG_ERR', $username, "STATUS UPDATE MAC: $mac IP: $userip SITE: $conf{UNIFI_SITENAME} AP: $apmac", { NAS => $Nas });
      exit(0);
    }

    my $client_data = $data->{'data'}->[$index];

    my $signal      = $client_data->{'{SIGNAL}'};
    my $transmitted = $client_data->{'{TRANSMIT}'};
    my $received    = $client_data->{'{RECEIVED}'};

    print "*/"                                       if ($debug);
    print "Content-Type: application/javascript\n\n" if (!$debug);
    print << "JSON_UPDATE";

/* Mac : $mac ; index = $index  */

  aAuthentificator.updateStatus({
    "status"       : "2",
    "signal"       : "$signal",
    "transmitted"  : "$transmitted",
    "received"     : "$received",
    "userMAC"      : "$client_data->{'{MAC}'}",
    "userIP"       : "$client_data->{'{IP}'}"
  });

JSON_UPDATE

    return 1;
  }
}

#********************************************************************
=head2  readQueryParameters()

=cut
#********************************************************************
sub read_query_parameters {

  $res = $FORM{res} || 0;
  $challenge = $FORM{challenge} || q{};
  $username  = $FORM{username} || $conf{UNIFI_GUEST_USERNAME} || q{};
  $password  = $FORM{password} || $conf{UNIFI_GUEST_PASSWORD} || q{};
  $usermac   = urldecode($FORM{id});
  $apmac     = urldecode($FORM{ap});
  $userurl   = $FORM{url} || '';
  $ssid      = $FORM{ssid} || q{};
  $userip    = $FORM{ip} || $ENV{REMOTE_ADDR};
  $operation_type = $FORM{operation_type} || q{};
  `echo "------- $operation_type" >> /tmp/unifi_ap` if ($debug);
  $userurldecode = urldecode($userurl);
  $return_url    = urlencode("$SELF_URL?operation_type=return&id=" . ($usermac || '') . '&ap=' . ($apmac || '') . "&username={LOGIN}&password={PASSWORD}&fastlogin=true");
  $password      = $conf{HOTSPOT_GUEST_PASS} if ($conf{HOTSPOT_GUEST_PASS} && $conf{HOTSPOT_GUEST_PASS} eq 'Guest');
  $password      = urldecode($password) if ($password);

  #If attempt to login (with submitted form)
  if (defined $operation_type) {
    if ($operation_type eq "login" && defined $usermac) {
      authorize_client();
      exit(0);
    }

    if ($operation_type eq "logout" && defined $usermac) {
      deauthorize_client();
      exit(0);
    }

    if ($operation_type eq "return") {
      $usermac       = urldecode($COOKIES{'hotspot_user_id'}) if ($COOKIES{'hotspot_user_id'});
      $apmac         = urldecode($COOKIES{'hotspot_ap_mac'}) if($COOKIES{'hotspot_ap_mac'});
      $userurldecode = urldecode($COOKIES{'hotspot_user_url'}) if ($COOKIES{'hotspot_user_url'});
    }

    if ($operation_type eq "update") {
      if ($usermac) {
        get_status_update($usermac);
      }
      exit(0);
    }
  }

  if ($FORM{ap} && !$COOKIES{'hotspot_ap_mac'}) {
    $html->set_cookies('hotspot_ap_mac', urlencode($FORM{ap}));
  }

  $result = 0;
  # If loglogin successful
  if ($res =~ /^.+$/) {
    $result = 1;
  }

  #Any Uni-Fi API operation needs user's MAC
  if ($usermac && $usermac =~ /^([0-9a-f]{2}\:){5}[0-9a-f]{2}$/) {
    $result = 2;
  }

  #Test MAC
  if ($usermac && $usermac eq $TEST_MAC) {
    $result = 3;
  }
  # Otherwise it was not a form request
  # Send out an error message
  if ($result == 0) {
    print_no_mac_provided();
    exit(0);
  }

  return $result;
}

#********************************************************************
=head2 print_no_mac_provided()

=cut
#********************************************************************
sub print_no_mac_provided {
  my $debug_info = '';
  if ($debug) {
    $debug_info = "
    <b></b> MAC : $usermac <br>
    <b></b> AP : $apmac <br>
    <b>GET</b> : $ENV{QUERY_STRING} <br>
    <b>POST</b> : ($input || '') <br>
    ";
  }

  print "Content-type: text/html\n\n";

  $html->tpl_show(
    _include('unifi_no_mac_provided', 'Unifi'),
    {
      WEB_TITLE  => $conf{WEB_TITLE},
      DEBUG_INFO => $debug_info
    }
  );

  return 1;
}

#********************************************************************
=head2 printLoginForm()

=cut
#********************************************************************
sub print_login_form {
  my ($user_info) = @_;

  my $hotspot_username = $FORM{username} || $conf{UNIFI_GUEST_USERNAME} || '';
  my $hotspot_password = $FORM{password} || $conf{UNIFI_GUEST_PASSWORD} || '';
  my $ssid = $FORM{ssid} || '';

  if ($COOKIES{hotspot_username}) {
    $hotspot_username = $COOKIES{hotspot_username};
    $hotspot_password = $COOKIES{hotspot_password};
    $userurl          = ($COOKIES{hotspot_userurl}) ? $COOKIES{hotspot_userurl} : '';
  }

  my $extra_info = '';
  if ($debug) {
    foreach my $key (sort keys %{$user_info}) {
      $extra_info .= "$key -> " . ((defined($user_info->{$key})) ? $user_info->{$key} : '') . $html->br();
    }
  }

  my $rules = $html->tpl_show(templates('form_accept_rules'), { FIO => $user->{FIO} || $lang{USER}, CHECKBOX => "checked" }, { OUTPUT2RETURN => 1 });
  my $show_rules_button = ($conf{HOTSPOT_SHOW_RULES}) ? 'block' : 'none';

  $conf{HOTSPOT_GUEST_MESSAGE} = '' if (!$conf{HOTSPOT_GUEST_MESSAGE});

  $html->tpl_show(
    _include('unifi_login_form', 'Unifi'),
    {
      HOTSPOT_USERNAME => $hotspot_username,
      HOTSPOT_PASSWORD => $hotspot_password,
      USER_MAC         => $usermac,
      USER_AP          => $apmac,
      UNIFI_SITENAME   => $conf{UNIFI_SITENAME},
      #USERURLDECODE    => $userurldecode,
      RETURN_URL       => urldecode($return_url),
      RULES            => $rules,
      RULES_SHOW_STYLE => $show_rules_button,
      EXTRA_INFO       => $extra_info,
      ssid             => $ssid
    }
  );

  return 1;
}

#********************************************************************
=head2 printStatusForm()

=cut
#********************************************************************
sub print_status_form {

  #  print_java_script_variables();

  my $client_data = {};

  if ($usermac) {
    my $data = $Unifi->convert_result($Unifi->users_list());
    my $index = get_user_index($data, $usermac);

    #if there's no client with such MAC at Uni-Fi response
    if ($index eq -1) {
      print "Content-Type: application/javascript\n\n";
      print qq{
              jQuery('#content').html('<div class='alert alert-danger'> Your device is not registered on hotspot. MAC: $usermac ..</div>');
              setTimeout(function(){window.location.reload(true)}, 5*1000);
            };

      $Log->log_print('LOG_ERR', $username, "STATUS SHOW MAC: $usermac IP: $userip SITE: $conf{UNIFI_SITENAME} AP: ". (($FORM{ap}) ? " AP: $FORM{ap}" : q{}), { NAS => $Nas });

      exit(0);
    }

    $client_data = $data->{'data'}->[$index];
  }

  $html->tpl_show(
    _include('unifi_status_form', 'Unifi'),
    {
      USERMAC     => $usermac,
      SIGNAL      => $client_data->{'{SIGNAL}'} || '',
      TRANSMITTED => $client_data->{'{TRANSMIT}'} || '',
      RECEIVED    => $client_data->{'{RECEIVED}'} || '',
      TIME        => '',
      DOWN        => '',
      UP          => '',
      USERIP      => $userip,
      USERNAME    => $username,
      MAC         => $usermac,
    }
  );

  return 1;
}

#********************************************************************
=head2 printHeader()

=cut
#********************************************************************
sub print_header {

  $html->tpl_show(
    _include('unifi_metategs', 'Unifi'),
    {
      WEB_TITLE => $conf{WEB_TITLE},
      SITENAME  => $conf{SITE_NAME}
    }
  );

  return 1;
}

#********************************************************************
=head2 printFooter()

=cut
#********************************************************************
sub print_footer {
  print_java_script_variables();

  my $gen_time_string = '';

  if ($begin_time > 0 && $debug) {
    $gen_time_string = gen_time($begin_time);
  }

  $html->tpl_show(_include('unifi_footer', 'Unifi'), { GENERATION_TIME => $gen_time_string });

  return 1;
}

#********************************************************************
=head2 print_java_script_variables();

=cut
#********************************************************************
sub print_java_script_variables {

  my $cookies_time = gmtime(time() + 86400) . " GMT";
  my $JS_SELF_URL  = $SELF_URL;
  if ($conf{UNIFI_SITENAME} && $conf{UNIFI_SITENAME} ne 'default') {
    $JS_SELF_URL =~ s/default/$conf{UNIFI_SITENAME}/;
  }

  $html->tpl_show(
    _include('unifi_javascript_variables', 'Unifi'),
    {
      DEBUG          => $debug,
      USERURLDECODE  => $userurldecode,
      USERURL        => $userurl,
      USERMAC        => $usermac,
      SSID           => $ssid,
      APMAC          => $apmac,
      USERIP         => $userip,
      COOKIES_TIME   => $cookies_time,
      UNIFI_SITENAME => $conf{UNIFI_SITENAME} || q{},
      HTML_DOMAIN    => $html->{domain},
      HTML_SECURE    => $html->{secure},
      SELF_URL       => $JS_SELF_URL,
    }
  );
}

1;
