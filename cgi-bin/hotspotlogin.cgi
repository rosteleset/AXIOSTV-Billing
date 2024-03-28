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


# Shared secret used to encrypt challenge with. Prevents dictionary attacks.
# You should change this to your own shared secret.

BEGIN {
 my $libpath = '../';

 $sql_type='mysql';
 unshift(@INC, $libpath ."AXbills/$sql_type/");
 #unshift(@INC, $libpath ."AXbills/");
 unshift(@INC, $libpath ."lib/");
 unshift(@INC, $libpath);
 unshift(@INC, $libpath . 'libexec/');

 eval { require Time::HiRes; };
 if (! $@) {
    Time::HiRes->import(qw(gettimeofday));
    $begin_time = Time::HiRes::gettimeofday();
   }
 else {
    $begin_time = 0;
  }
}

use strict;
use Digest::MD5  qw(md5 md5_hex md5_base64);
use AXbills::HTML;
our(
  %conf,
  %lang
);

require "../language/russian.pl";
require "../libexec/config.pl";

my %COOKIES = get_cookies();
my $uamsecret = "secrete";

# Uncomment the following line if you want to use ordinary user-password
# for radius authentication. Must be used together with $uamsecret.
#my $userpassword=1;

# Our own path
my $loginpath = $ENV{'SCRIPT_URL'};

# Make sure that the form parameters are clean
my $OK_CHARS='-a-zA-Z0-9_.@&=%!';
$| = 1;
if ($ENV{'CONTENT_LENGTH'}) {
    read (STDIN, $_, $ENV{'CONTENT_LENGTH'});
}
s/[^$OK_CHARS]/_/go;
my $input = $_;


# Make sure that the get query parameters are clean
$OK_CHARS='-a-zA-Z0-9_.@&=%!';
my $query;
$_ = $query = $ENV{QUERY_STRING};
s/[^$OK_CHARS]/_/go;
$query = $_;

my (
  $username,
  $password,
  $challenge,
  $button,
  $logout,
  $prelogin,
  $res,
  $uamip,
  $uamport,
  $userurl,
  $timeleft,
  $redirurl,
  $getpass,
  $reply,
  $clientstate
);


#Read form parameters which we care about
my @array = split('&',$input);
foreach my $var ( @array ) {
  my @array2 = split('=',$var);
  if ($array2[0] =~ /^UserName$/)  { $username = $array2[1]; }
  if ($array2[0] =~ /^Password$/)  { $password = $array2[1]; }
  if ($array2[0] =~ /^challenge$/) { $challenge= $array2[1]; }
  if ($array2[0] =~ /^button$/)    { $button   = $array2[1]; }
  if ($array2[0] =~ /^logout$/)    { $logout   = $array2[1]; }
  if ($array2[0] =~ /^prelogin$/)  { $prelogin = $array2[1]; }
  if ($array2[0] =~ /^res$/)       { $res      = $array2[1]; }
  if ($array2[0] =~ /^uamip$/)     { $uamip    = $array2[1]; }
  if ($array2[0] =~ /^uamport$/)   { $uamport  = $array2[1]; }
  if ($array2[0] =~ /^userurl$/)   { $userurl  = $array2[1]; }
  if ($array2[0] =~ /^timeleft$/)  { $timeleft = $array2[1]; }
  if ($array2[0] =~ /^redirurl$/)  { $redirurl = $array2[1]; }
  if ($array2[0] =~ /^get_pass$/)  { $getpass  = $array2[1]; }
  if ($array2[0] =~ /^clientState$/)     { $clientstate  = $array2[1]; }
}

#Read query parameters which we care about
@array = split('&',$query);
foreach my $var ( @array ) {
  my @array2 = split('=',$var);
  if ($array2[0] =~ /^res$/)       { $res       = $array2[1]; }
  if ($array2[0] =~ /^challenge$/) { $challenge = $array2[1]; }
  if ($array2[0] =~ /^uamip$/)     { $uamip     = $array2[1]; }
  if ($array2[0] =~ /^uamport$/)   { $uamport   = $array2[1]; }
  if ($array2[0] =~ /^reply$/)     { $reply     = $array2[1]; }
  if ($array2[0] =~ /^userurl$/)   { $userurl   = $array2[1]; }
  if ($array2[0] =~ /^timeleft$/)  { $timeleft  = $array2[1]; }
  if ($array2[0] =~ /^redirurl$/)  { $redirurl  = $array2[1]; }
  if ($array2[0] =~ /^clientState$/)     { $clientstate  = $array2[1]; }
}

$reply =~ s/\+/ /g;
$reply =~s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/seg;

my $userurldecode = $userurl;
$userurldecode =~ s/\+/ /g;
$userurldecode =~s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/seg;

my $redirurldecode = $redirurl;
$redirurldecode =~ s/\+/ /g;
$redirurldecode =~s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/seg;

#my $pass = $password;
$password =~ s/\+/ /g;
$password =~s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/seg;

# If attempt to login
if (defined $getpass) {
  my $hexchal  = pack "H32", $challenge;
  my $newchal  = md5($hexchal, $uamsecret);
  my $pappassword = unpack "H32", ($password ^ $newchal);
  print "Content-type: text/html\n\n";
  print "$pappassword";
  exit(0);
}


# Default: It was not a form request
my $result = 0;

# If login successful
if ($res =~ /^.+$/) {
  $result = 1;
}

# Otherwise it was not a form request
# Send out an error message
if ($result == 0 && !defined $clientstate) {
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
print qq{Content-type: text/html\n\n
<!DOCTYPE html>
<html>
<head>
  <title>$conf{WEB_TITLE} - Login</title>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <!-- Bootstrap core CSS -->
    <link href="/wifi/css/adminlte.min.css" rel="stylesheet">
    <link href="/wifi/css/login.css" rel="stylesheet">
    <!-- HTML5 shim and Respond.js for IE8 support of HTML5 elements and media queries -->
    <!--[if lt IE 9]>
    <script src="/wifi/js/html5shiv.min.js"></script>
    <script src="/wifi/js/respond.min.js"></script>
    <![endif]-->
    <script src="/wifi/js/jquery.min.js"></script>
    <script src="/wifi/js/bootstrap.bundle.min.js"></script>
    <script src="/wifi/js/moment.js"></script>
    <script type="text/javascript">

    jQuery(function() {
      jQuery('#login-form-link').click(function(e) {
        jQuery("#login-form").delay(100).fadeIn(100);
        jQuery("#guest-form").fadeOut(100);
        jQuery('#guest-form-link').removeClass('active');
        jQuery(this).addClass('active');
          e.preventDefault();
       });
      jQuery('#guest-form-link').click(function(e) {
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
     alert('logining');
        jQuery.ajax({
           type: 'POST',
           url: 'hotspotlogin.cgi',
           data: {Password : pass, challenge : challenge, get_pass : '1' },
           success: function(pappass){
             jQuery.getJSON('http://$uamip:$uamport/json/logon?username='+ username +'&chapchallenge='+ challenge +'&chappassword='+ pappass +'&lang=EN&callback=?', function(data) {
             console.log(data);
             }).success(
               function(data) {
                 console.log(data);
                 jQuery("#status").html(data.message);
                 setTimeout( hide_modal, 2000);
                 challenge=data.challenge;
                 if (clientState != data.clientState) {
                   clientState = data.clientState;
                   setTimeout( get_content, 2000);
                 }
               })
               .error(
               function(status){
               console.log(error);
               });
           },
           error: function(status){
           console.log(error)
           }
         });
     }
     function get_status() {
       var interval=setInterval("status()",10000);
       status();
     }
     function get_content() {
       jQuery.post( "hotspotlogin.cgi?clientState="+ clientState +"&uamip=$uamip&uamport=$uamport", function( data ) {
         jQuery( "#content" ).html( data );
        });
     }
     function client_state() {
      jQuery.getJSON('http://$uamip:$uamport/json/status?callback=?', function(data) {
          console.log(data);
          clientState = data.clientState;
          challenge = data.challenge;
          get_content();
        });
     }
     function status() {
      jQuery.getJSON('http://$uamip:$uamport/json/status?callback=?', function(data) {
          console.log(data);
          clientState = data.clientState;
          if (clientState == 0) {
            challenge = data.challenge;
            URL = data.redir.originalURL;
          }
          else if (clientState == 1) {
            var inputOctets;
            var outputOctets;
            var out_type = 'B';
            var in_type = 'B';
            if (data.accounting.outputOctets > 1000000000) {
              output = data.accounting.outputOctets / 1000000000;
              out_type = 'Gb';
            }
            else if (data.accounting.outputOctets > 1000000) {
              output = data.accounting.outputOctets / 1000000;
              out_type = 'Mb';
            }
            else if (data.accounting.outputOctets > 1000) {
              output = data.accounting.outputOctets / 1000;
              out_type = 'Kb';
            }
            else {
              output = data.accounting.outputOctets;
            }
            if (data.accounting.inputOctets > 1000000000) {
              input = data.accounting.inputOctets / 1000000000;
              in_type = 'Gb';
            }
            else if (data.accounting.inputOctets > 1000000) {
              input = data.accounting.inputOctets / 1000000;
              in_type = 'Mb';
            }
            else if (data.accounting.inputOctets > 1000) {
              input = data.accounting.inputOctets / 1000;
              in_type = 'Kb';
            }
            else {
              input = data.accounting.inputOctets;
            }
            output = output.toFixed(2);
            input = input.toFixed(2);
            var sec = data.accounting.sessionTime;
	    var h = sec/3600 ^ 0 ;
            var m = (sec-h*3600)/60 ^ 0 ;
            var s = sec-h*3600-m*60 ;
            jQuery('.logged-user').html('<h3 class="panel-title text-center">Welcome '+ data.session.userName +'</h3>');
            jQuery("#mac").parent().remove();
            jQuery("#speed").parent().remove();
            jQuery("#connect").parent().remove();
            var i = jQuery("#last_row").before('<tr><td id=mac>MAC ADDRESS</td><td>'+ data.redir.macAddress +'</td></tr>').prev();
            i = jQuery("#last_row").before('<tr><td id=speed>UP/DOWN</td><td>'+ input + '' + in_type +'/'+ output +''+ out_type +' </td></tr>').prev();
            var i = jQuery("#last_row").before('<tr><td id=connect>CONNECTED</td><td>'+ (h<10?"0"+h:h) +':'+ (m<10?"0"+m:m) +':'+ (s<10?"0"+s:s) +'</td></tr>').prev();
          }
        });
     }
    </script>
    <meta http-equiv="Cache-control" content="no-cache">
    <meta http-equiv="Pragma" content="no-cache">
</head>
<body>
};
if ($result != 0) {
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
    var challenge = '$challenge';
    var clientState;
    var URL;
    client_state();
  </script>
</body>
</html>
};
}


if (defined $clientstate && $clientstate == 0) {
  my $hotspot_username='';
  my $hotspot_password='';

  if ($COOKIES{hotspot_username}) {
    $hotspot_username = $COOKIES{hotspot_username};
    $hotspot_password = $COOKIES{hotspot_password};
    $userurl          = $COOKIES{hotspot_userurl};
  }
  print "
  <div class=\"container\">
    <div class=\"row\">
      <div class=\"col-md-6 col-md-offset-3\">
        <div class=\"panel panel-login\">
          <div class=\"card-header with-border\">
            <div class=\"row\">
              <div class=\"col-xs-6\">
                <a href=\"#\" class=\"active\" id=\"login-form-link\">$lang{AUTH}</a>
              </div>
              <div class=\"col-xs-6\">
                <a href=\"#\" id=\"guest-form-link\">$lang{GUEST}</a>
              </div>
            </div>
            <hr>
          </div>
          <div class=\"panel-body\">
            <div class=\"row\">
              <div class=\"col-lg-12\">
                <form id=\"login-form\" method=\"post\" role=\"form\" style=\"display: block;\" action=\"$loginpath\">
                  <INPUT TYPE=\"hidden\" NAME=\"userurl\" VALUE=\"$userurldecode\">
                  <INPUT TYPE=\"hidden\" NAME=\"User_type\" VALUE=\"Login\">
                  <div class=\"form-group\">
                    <div class='input-group'>
                      <span class='input-group-addon'><span class='fa fa-user'></span></span>
                      <input type=\"text\" name=\"UserName\" id=\"username\" tabindex=\"1\" class=\"form-control\" placeholder=\"$lang{LOGIN}\" value=\"\">
                    </div>
                  </div>
                  <div class=\"form-group\">
                    <div class='input-group'>
                      <span class='input-group-addon'><span class='fa fa-lock'></span></span>
                      <input type=\"password\" name=\"Password\" id=\"password\" tabindex=\"2\" class=\"form-control\" placeholder=\"$lang{PASSWD}\">
                    </div>
                  </div>
                  <div class=\"form-group text-center\">
                    <input type=\"checkbox\" tabindex=\"5\" class=\"\" name=\"remember\" id=\"remember\">
                    <label for=\"remember\"> Remember Me</label>
                  </div>
                  <div class=\"form-group\">
                    <div class=\"row\">
                      <div class=\"col-sm-6 col-sm-offset-3\">
                        <input type=\"submit\" id=\"login-submit\" tabindex=\"4\" class=\"form-control btn btn-login\" name=\"login-submit\" value=\"$lang{ENTER}\">
                      </div>
                    </div>
                  </div>
                </form>
                <form id=\"guest-form\" action=\"$loginpath\" method=\"post\" role=\"form\" style=\"display: none;\">
                  <INPUT TYPE=\"hidden\" NAME=\"userurl\" VALUE=\"$userurldecode\">
                  <INPUT TYPE=\"hidden\" NAME=\"User_type\" VALUE=\"Guest\">
                  <INPUT TYPE=\"hidden\" NAME=\"UserName\" VALUE=\"alena\">
                  <INPUT TYPE=\"hidden\" NAME=\"Password\" VALUE=\"1234567\">
                  <div class=\"form-group text-center\">
                    <label>В гостевом режиме интернет предоставляется на 30 минут.</label>
                  </div>
                  <div class=\"form-group\">
                    <div class=\"row\">
                      <div class=\"col-sm-6 col-sm-offset-3\">
                        <input type=\"submit\" id=\"guest-submit\" tabindex=\"4\" class=\"form-control btn btn-guest\" value=\"$lang{LOGON} $lang{DV}\">
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
  <!-- Loading modal -->
  <div class=\"modal fade\" id=\"loading\" tabindex=\"-1\" role=\"dialog\" aria-hidden=\"true\">
    <div class=\"modal-dialog modal-sm\">
      <div class=\"modal-content\">
        <div class=\"modal-header\">
          <button type=\"button\" class=\"close\" data-dismiss=\"modal\" aria-label=\"Close\"><span aria-hidden=\"true\">&times;</span></button>
          <h4 class=\"modal-title\">Status...</h4>
        </div>
        <div class=\"modal-body\">
          <p class=\"text-center\" id=\"status\">Please wait while computer is being authorized. <img src='/wifi/img/ajax-loader.gif' /></p>
        </div>
      </div>
    </div>
  </div>
    <script type=\"text/javascript\">
      // Login form processing
      \$('#guest-form').submit(function(e){
        e.preventDefault();
        // Show a loading modal
        \$('#loading').modal('show');
         var pass = \$('#guest-form').find('input[name=Password]').val();
         var username = \$('#guest-form').find('input[name=UserName]').val();
         logon(username, pass);     
      });
      \$('#login-form').submit(function(e){
        e.preventDefault();
        // Show a loading modal
        \$('#loading').modal('show');
         var pass = \$('#login-form').find('input[name=Password]').val();
         var username = \$('#login-form').find('input[name=UserName]').val();
         logon(username, pass);
      });
      \$('#loading').on('hidden.bs.modal', function () {
        \$(\"#status\").html(\"Please wait your device is being authorized. <img src='/wifi/img/ajax-loader.gif'/>\");
      });
    </script>
</body>
</html>";
}
elsif ($clientstate eq 1) {
#  print "<script type='text/javascript'>\$(location).attr('href','$userurldecode');</script>";
print "<script>popUp($result, '$userurldecode', '$redirurldecode', '$timeleft');</script>";
print "<script>get_status();</script>";
print "
<div class=\"container\">
  <div class=\"row\">
    <div class=\"col-md-4 col-md-offset-4\">
      <div class=\"panel panel-success\">
        <div class=\"card-header with-border logged-user\">
        </div>
        <div class=\"table-logged-user\">
        </div>
        <table class=\"table table-bordered table-logged-user\">
          <tbody>
            <tr id=\"last_row\"></tr>
            <tr>
              <td>Status refresh</td>
              <td>10 sec</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
    <div class=\"col-sm-4 col-sm-offset-4\">
      <a href=\"http://$uamip:$uamport/logoff\" class=\"form-control btn btn-logout\">$lang{HANGUP}</a>
    </div>
  </div>
</div>

</div>
</body>
</html>";

}

##********************************************************************
## get cookie values and return hash of it
##
## getCookies()
##********************************************************************
#sub getCookies {
#  shift;
#	# cookies are seperated by a semicolon and a space, this will split
#	# them and return a hash of cookies
#	my(%cookies);
#
#  if (defined($ENV{'HTTP_COOKIE'})) {
# 	  my(@rawCookies) = split (/; /, $ENV{'HTTP_COOKIE'});
#	  foreach(@rawCookies){
#	     my ($key, $val) = split (/=/,$_);
#	     $cookies{$key} = $val;
#	  }
#   }
#
#	return %cookies;
#}

exit(0);

1

