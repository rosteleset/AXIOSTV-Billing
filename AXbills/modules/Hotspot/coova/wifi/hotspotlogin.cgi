#!/usr/bin/perl

# chilli - ChilliSpot.org. A Wireless LAN Access Point Controller
# Copyright (C) 2003, 2004 Mondru AB.
#
# The contents of this file may be used under the terms of the GNU
# General Public License Version 2, provided that the above copyright
# notice and this permission notice is included in all copies or
# substantial portions of the software.

# Redirects from ChilliSpot daemon:
#
# Redirection when not yet or already authenticated
#   notyet:  ChilliSpot daemon redirects to login page.
#   already: ChilliSpot daemon redirects to success status page.
#
# Response to login:
#   already: Attempt to login when already logged in.
#   failed:  Login failed
#   success: Login succeded
#
# logoff:  Response to a logout

use strict;
our ($libpath);
BEGIN {
  $libpath = '../';
  my $sql_type = 'mysql';
  
  unshift(@INC,
    $libpath . "lib/",
    $libpath . "AXbills/$sql_type/",
    $libpath . 'libexec/',
    $libpath . "AXbills/modules/",
    $libpath . "AXbills/",
    $libpath,
  );
  
}

# Shared secret used to encrypt challenge with. Prevents dictionary attacks.
# You should change this to your own shared secret.
my $uamsecret = "secrete";

use Digest::MD5 qw(md5 md5_hex md5_base64);
use AXbills::HTML;
use AXbills::Base qw/_bp urlencode/;

# load_module
use Nas;
use AXbills::Misc;

our (%conf, %lang, %FORM);

require $libpath . 'libexec/config.pl';

$conf{WEB_TITLE}               //= 'ABillSpot';
$conf{GUEST_MESSAGE}           //= 'В гостевом режиме интернет предоставляется на 30 минут';

my $html = AXbills::HTML->new(
  {
    CONF    => \%conf,
    CHARSET => $conf{default_charset},
  }
);

$conf{HOTSPOT_LOGIN_URL}       //= urlencode($SELF_URL . '&' . $FORM{__BUFFER});
$conf{HOTSPOT_GUEST_LOGIN_URL} //= $conf{HOTSPOT_LOGIN_URL};

$html->{language} = (defined($FORM{language}) && $FORM{language} =~ /^[a-z_]+$/)
  ? $FORM{language}
  : 'russian';

$html->{show_header} = 1;

do "$libpath/language/english.pl";
do "$libpath/language/$html->{language}.pl";

# Some lang variables are located in Unifi module;
$html->{CONFIG_ONLY} = 1;
load_module('Unifi', $html);
delete $html->{CONFIG_ONLY};

my %COOKIES = %{ get_cookies() };

my $password = $FORM{Password} || '';
my $challenge = $FORM{challenge} || '';
my $uamip = $FORM{uamip} || '';
my $uamport = $FORM{uamport} || '';
my $userurl = $FORM{userurl} || '';
my $timeleft = $FORM{timeleft} || '';
my $redirurl = $FORM{redirurl} || '';

my $userurldecode = $userurl;
$userurldecode =~ s/\+/ /g;
$userurldecode =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/seg;

my $redirurldecode = $redirurl;
$redirurldecode =~ s/\+/ /g;
$redirurldecode =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/seg;

#my $pass = $password;
$password =~ s/\+/ /g;
$password =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/seg;

# If attempt to login
# TODO: move to browser
if ( exists $FORM{get_pass} ) {
  my $hexchal = pack "H32", $challenge;
  my $newchal = md5($hexchal, $uamsecret);
  my $pappassword = unpack "H32", ($password ^ $newchal);
  print "Content-type: text/html\n\n";
  print "$pappassword";
  exit(0);
}

# Default: It was not a form request
my $result = 0;

# If login successful
if ( $FORM{res} && $FORM{res} =~ /^.+$/ ) {
  $result = 1;
}

# Otherwise it was not a form request
# Send out an error message
if ( $result == 0 && !exists $FORM{clientState} ) {
  print "Content-type: text/html\n\n
<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\">
<html>
<head>
  <title>$conf{WEB_TITLE} - Login Failed</title>
  <meta http-equiv=\"Cache-control\" content=\"no-cache\">
  <meta http-equiv=\"Pragma\" content=\"no-cache\">
</head>
<body bgColor = '#ffffff'>
  <h1 style=\"text-align: center;\">$conf{WEB_TITLE} - Login Failed</h1>
  <center>
    Login must be performed through $conf{WEB_TITLE} - daemon.
  </center>
</body>
</html>
";
  exit(0);
}

#Generate the output
print qq{Access-Control-Allow-Origin : *;
Content-type: text/html\n\n
<!DOCTYPE html>
<html>
<head>
  <title>$conf{WEB_TITLE} - Login</title>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <!-- Bootstrap core CSS -->
    <link href="/hotspot/styles/default/css/adminlte.min.css" rel="stylesheet">
    <link href="/hotspot/styles/default/css/hotspotlogin.css" rel="stylesheet">
    <!-- HTML5 shim and Respond.js for IE8 support of HTML5 elements and media queries -->
    <!--[if lt IE 9]>
    <script src="/hotspot/styles/default/js/html5shiv.min.js"></script>
    <script src="/hotspot/styles/default/js/respond.min.js"></script>
    <![endif]-->
    <script src="/hotspot/styles/default/js/jquery.min.js"></script>
    <!--[if lt IE 9]>
      <script src='/hotspot/styles/default/js/jquery-1.11.3.min.js' type='text/javascript'></script>
    <![endif]-->
    <script src="/hotspot/styles/default/js/bootstrap.bundle.min.js"></script>
    <script src="/hotspot/styles/default/plugins/moment/moment.min.js"></script>
    <script type="text/javascript">
      
      jQuery(function () {
        jQuery('#login-form-link').click(function (e) {
          jQuery("#login-form").delay(100).fadeIn(100);
          jQuery("#guest-form").fadeOut(100);
          jQuery('#guest-form-link').removeClass('active');
          jQuery(this).addClass('active');
          e.preventDefault();
        });
        jQuery('#guest-form-link').click(function (e) {
          jQuery("#guest-form").delay(100).fadeIn(100);
          jQuery("#login-form").fadeOut(100);
          jQuery('#login-form-link').removeClass('active');
          jQuery(this).addClass('active');
          e.preventDefault();
        });
      });
      function popUp(result, URL, redirurl, timeleft) {
        if ((result == 1) || (result == 4) || (result == 12)) {
          UserURL = window.open(URL, 'userurl');
        }
      }
      function hide_modal() {
        jQuery('#loading').modal('hide');
      }
      function logon(username, pass) {
        jQuery.ajax({
          type   : 'POST',
          url    : 'hotspotlogin.cgi',
          data   : {Password: pass, challenge: challenge, get_pass: '1'},
          success: function (pappass) {
            var params = jQuery.param({
              username     : username,
              password     : pappass,
              chapchallenge: challenge,
              lang         : 'EN',
              callback     : 'onLogon'
            });
            
            window['onLogon'] = function (data) {
              console.log(data);
              jQuery("#status").html(data.message);
              setTimeout(hide_modal, 2000);
              challenge = data.challenge;
              if (clientState != data.clientState) {
                clientState = data.clientState;
                setTimeout(get_content, 2000);
              }
            };
            
            // CORS
            var script = document.createElement('script');
            script.src = 'http://$uamip:$uamport/json/logon?' + params;
            jQuery('head').append(script);
          }
          
        });
      }
      function get_status() {
        var interval = setInterval("status()", 10000);
        status();
      }
      function get_content() {
        var params = jQuery.param({
          uamip : '$uamip',
          clientState : clientState,
          uamport : '$uamport'
        });
        
        jQuery.get("/hotspot/hotspotlogin.cgi", params, function(data){jQuery("#content").html(data)});
      }
      function client_state() {
        jQuery.getJSON('http://$uamip:$uamport/json/status?callback=?', function (data) {
          console.log(data);
          clientState = data.clientState;
          challenge   = data.challenge;
          get_content();
        });
      }
      function status() {
        jQuery.getJSON('http://$uamip:$uamport/json/status?callback=?', function (data) {
          console.log(data);
          clientState = data.clientState;
          if (clientState == 0) {
            challenge = data.challenge;
            URL       = data.redir.originalURL;
          }
          else if (clientState == 1) {
            var inputOctets;
            var outputOctets;
            var out_type = 'B';
            var in_type  = 'B';
            if (data.accounting.outputOctets > 1000000000) {
              output   = data.accounting.outputOctets / 1000000000;
              out_type = 'Gb';
            }
            else if (data.accounting.outputOctets > 1000000) {
              output   = data.accounting.outputOctets / 1000000;
              out_type = 'Mb';
            }
            else if (data.accounting.outputOctets > 1000) {
              output   = data.accounting.outputOctets / 1000;
              out_type = 'Kb';
            }
            else {
              output = data.accounting.outputOctets;
            }
            if (data.accounting.inputOctets > 1000000000) {
              input   = data.accounting.inputOctets / 1000000000;
              in_type = 'Gb';
            }
            else if (data.accounting.inputOctets > 1000000) {
              input   = data.accounting.inputOctets / 1000000;
              in_type = 'Mb';
            }
            else if (data.accounting.inputOctets > 1000) {
              input   = data.accounting.inputOctets / 1000;
              in_type = 'Kb';
            }
            else {
              input = data.accounting.inputOctets;
            }
            output  = output.toFixed(2);
            input   = input.toFixed(2);
            var sec = data.accounting.sessionTime;
            var h   = sec / 3600 ^ 0;
            var m   = (sec - h * 3600) / 60 ^ 0;
            var s   = sec - h * 3600 - m * 60;
            jQuery('.logged-user').html('<h3 class="panel-title text-center">$lang{USER} <b>' + data.session.userName + '</b></h3><hr/>');
            jQuery("#mac").parent().remove();
            jQuery("#speed").parent().remove();
            jQuery("#connect").parent().remove();
            jQuery("#last_row").before('<tr><td id=mac>$lang{MAC}</td><td>' + data.redir.macAddress + '</td></tr>');
            jQuery("#last_row").before('<tr><td id=speed>$lang{UP}/$lang{DOWN}</td><td>' + input + '' + in_type + '/' + output + '' + out_type + ' </td></tr>');
            jQuery("#last_row").before('<tr><td id=connect>$lang{DURATION}</td><td>' + (h < 10 ? "0" + h : h) + ':' + (m < 10 ? "0" + m : m) + ':' + (s < 10 ? "0" + s : s) + '</td></tr>');
          }
        });
      }
    </script>
    <meta http-equiv="Cache-control" content="no-cache">
    <meta http-equiv="Pragma" content="no-cache">
</head>
<body>
<!-- Loading modal -->
<div class="modal fade" id="loading" tabindex="-1" role="dialog" aria-hidden="true">
  <div class="modal-dialog modal-sm">
    <div class="modal-content">
      <div class="modal-header">
        <button type="button" class="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button>
        <h4 class="modal-title">Status...</h4>
      </div>
      <div class="modal-body">
        <p class="text-center" id="status">$lang{WAIT_FOR_AUTH}<img src='/hotspot/styles/default/img/ajax-loader.gif' /></p>
      </div>
    </div>
  </div>
</div>
};
if ( $result != 0 ) {
  my $challenge_line = $FORM{challenge}
    ? qq{var challenge = '$challenge';}
    : '';
  
  print qq{
<div class="container">
  <div class="jumbotron jumbotron-sm">
    <div class="container">
      <div class="row">
        <div class="col-xs-12">
          <h2 class="h2 text-center">
            <label><span style='color: red;'></span>$conf{WEB_TITLE} HotSpot</label>
          </h2>
        </div>
      </div>
    </div>
  </div>
  <div id="content">
  </div>
</div>
  <script type="text/javascript">
    $challenge_line
    var clientState;
    var URL;
    client_state();
  </script>
</body>
</html>
};
}

if ( exists $FORM{clientState} && $FORM{clientState} == 0 ) {
  my $hotspot_username = '';
  my $hotspot_password = '';
  
  if ( defined $COOKIES{hotspot_username} ) {
    $hotspot_username = $COOKIES{hotspot_username};
    $hotspot_password = $COOKIES{hotspot_password};
    $userurl = $COOKIES{hotspot_userurl};
  }
  print qq{
  <div class="container">
    <div class="row">
      <div class="col-md-6 col-md-offset-3">
        <div class="panel panel-login">
          <div class="card-header with-border">
            <div class="row text-center">
              <div class="col-xs-6">
                <a href="#" class="active btn btn-block btn-secondary" id="login-form-link">$lang{AUTH}</a>
              </div>
              <div class="col-xs-6">
                <a href="#" class="btn btn-block btn-secondary" id="guest-form-link">$lang{GUEST}</a>
              </div>
            </div>
            <hr>
          </div>
          <div class="panel-body">
            <div class="row">
              <div class="col-lg-12">
                <form id="login-form" method="post" role="form" style="display: block;" action="$SELF_URL">
                  <INPUT TYPE="hidden" NAME="userurl" VALUE="$userurldecode">
                  <INPUT TYPE="hidden" NAME="User_type" VALUE="Login">
                  <div class="form-group">
                    <div class='input-group'>
                      <span class='input-group-addon'><span class='fa fa-user'></span></span>
                      <input type="text" name="UserName" id="username" tabindex="1" class="form-control" placeholder="$lang{LOGIN}" value="$hotspot_username">
                    </div>
                  </div>
                  <div class="form-group">
                    <div class='input-group'>
                      <span class='input-group-addon'><span class='fa fa-lock'></span></span>
                      <input type="password" name="Password" id="password" tabindex="2" class="form-control" placeholder="$lang{PASSWD}" value="$hotspot_password">
                    </div>
                  </div>
                  <div class="form-group text-center">
                    <input type="checkbox" tabindex="5" class="" name="remember" id="remember">
                    <label for="remember">$lang{REMEMBER}</label>
                  </div>
                  <div class="form-group">
                    <div class="row">
                      <div class="col-md-6">
                        <input type="submit" id="login-submit" tabindex="4" class="btn btn-lg btn-block btn-info" name="login-submit" value="$lang{ENTER}">
                      </div>
                      <div class="col-md-6">
                        <a id='buy_card_link' tabindex='5' class='btn btn-lg btn-block btn-success'
                         href='$conf{BILLING_URL}/start.cgi?login_return_url=$conf{HOTSPOT_LOGIN_URL}'>$lang{BUY} $lang{ACCESS}</a>
                      </div>
                    </div>
                  </div>
                </form>
                <form id="guest-form" action="$conf{BILLING_URL}/start.cgi" method="post" role="form" style="display: none;">
                  <input type='hidden' name='usertype' value='Guest'>
                  <input type='hidden' name='GUEST_ACCOUNT' value='1'>
                  <input type='hidden' name='login_return_url' value='$conf{HOTSPOT_LOGIN_URL}'>
                  <div class="form-group text-center">
                    <label>$conf{GUEST_MESSAGE}</label>
                  </div>
                  <div class="form-group">
                    <div class="row">
                      <div class="col-sm-6 col-sm-offset-3">
                        <input type="submit" tabindex="4" class="form-control btn btn-guest" value="$lang{LOGON} $lang{DV}">
                      </div>
                    </div>
                  </div>
                </form>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
    <script type="text/javascript">
      // Login form processing
      jQuery('#login-form').submit(function(e){
        e.preventDefault();
        // Show a loading modal
        jQuery('#loading').modal('show');
         var pass = jQuery('#login-form').find('input[name=Password]').val();
         var username = jQuery('#login-form').find('input[name=UserName]').val();
         logon(username, pass);
      });
      jQuery('#loading').on('hidden.bs.modal', function () {
        jQuery("#status").html("$lang{WAIT_FOR_AUTH}. <img src='/hotspot/styles/default/img/ajax-loader.gif'/>");
      });
    </script>
</body>
</html>};
}
elsif ( $FORM{clientState} eq 1 ) {
  
  #  print "<script type='text/javascript'>\$(location).attr('href','$userurldecode');</script>";
  print "<script>popUp($result, '$userurldecode', '$redirurldecode', '$timeleft');</script>";
  print "<script>get_status();</script>";
  print qq{
<div class="container">
  <div class="row">
    <div class="col-md-4 col-md-offset-4">
      <div class="card box-success">
        <div class="card-header with-border logged-user table-logged-user"></div>
        <div class="panel-body">
          <table class="table table-bordered table-logged-user">
            <tbody>
              <tr id="last_row"></tr>
              <tr>
                <td>$lang{REFRESH}</td>
                <td>10 sec</td>
              </tr>
            </tbody>
          </table>
      </div>
      </div>
    </div>
    <div class="col-sm-4 col-sm-offset-4">
      <a href="http://$uamip:$uamport/logoff" class="form-control btn btn-logout">$lang{HANGUP}</a>
    </div>
  </div>
</div>

</div>
</body>
</html>};
  
}

exit(0);

1;

