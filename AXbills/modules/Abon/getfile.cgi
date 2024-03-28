#!/usr/bin/perl

=head1 NAME
  ABillS File download script
=cut

use vars qw($begin_time %LANG $CHARSET @MODULES
$UID 
$admin
$sid
$db
);

BEGIN {
  my $libpath = '../';

  $sql_type = 'mysql';
  unshift(@INC, $libpath . "AXbills/$sql_type/");
  unshift(@INC, $libpath . "AXbills/");
  unshift(@INC, $libpath);
  unshift(@INC, $libpath . 'libexec/');
  eval { require Time::HiRes; };
  if (!$@) {
    Time::HiRes->import(qw(gettimeofday));
    $begin_time = gettimeofday();
  }
  else {
    $begin_time = 0;
  }
}

require "config.pl";

use POSIX qw(mktime strftime);

use AXbills::Base;
use AXbills::SQL;
use AXbills::HTML;

$html = AXbills::HTML->new(
  {
    IMG_PATH => 'img/',
    NO_PRINT => 1,
    CONF     => \%conf,
    CHARSET  => $conf{default_charset},
  }
);

$db = AXbills::SQL->connect($conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd}, { CHARSET => ($conf{dbcharset}) ? $conf{dbcharset} : undef });
if ($FORM{language} && $FORM{language} =~ /^[a-z_]+$/) {
  $html->{language} = $FORM{language};
  $html->setCookie('language', "$FORM{language}", "Fri, 1-Jan-2038 00:00:01", $web_path, $domain, $secure);
}

require "../language/$html->{language}.pl";
require "Misc.pm";
my $sid = $FORM{sid} || '';    # Session ID
$html->{CHARSET} = $CHARSET if ($CHARSET);

require Admins;
Admins->import();
$admin = Admins->new($db, \%conf);
$admin->info($conf{USERS_WEB_ADMIN_ID} ? $conf{USERS_WEB_ADMIN_ID} : $conf{SYSTEM_ADMIN_ID}, 
                 { DOMAIN_ID => $FORM{DOMAIN_ID}, 
                   IP        => $ENV{REMOTE_ADDR},
                   SHORT     => 1 });

$admin->{SESSION_IP} = $ENV{REMOTE_ADDR};
$conf{WEB_TITLE} = $admin->{DOMAIN_NAME} if ($admin->{DOMAIN_NAME});

require "AXbills/templates.pl";
$html->{METATAGS} = templates('metatags_client');

my $uid = 0;
my $page_qs;
my %OUTPUT = ();

#my $user = Users->new($db, $admin, \%conf);


print $html->header();

_bp({ SHOW => "tetstts" });



1
