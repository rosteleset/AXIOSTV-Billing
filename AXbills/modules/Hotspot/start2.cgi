#!/usr/bin/perl

use strict;
use warnings;

our (
  %conf,
  $DATE,
  $TIME,
  $base_dir,
  %lang,
  %FORM,
  %COOKIES,
);

BEGIN {
  use FindBin '$Bin';
  require $Bin . '/../libexec/config.pl';
  unshift(@INC,
    $Bin . '/../',
    $Bin . '/../lib/',
    $Bin . '/../AXbills',
    $Bin . '/../AXbills/mysql',
    $Bin . '/../AXbills/modules',
  );
}

if (!$ENV{'REQUEST_METHOD'}) {
  print "Execute from console.\n";
  exit;
}

use AXbills::Base qw/_bp/;
use AXbills::SQL;
use Admins;
use Users;
use Internet;
use Tariffs;
use Hotspot;

require AXbills::Templates;
require AXbills::Misc;

our $html = AXbills::HTML->new(
  {
    IMG_PATH => 'img/',
    NO_PRINT => 1,
    CONF     => \%conf,
    CHARSET  => $conf{default_charset},
    METATAGS => templates('metatags'),
    COLORS   => $conf{UI_COLORS},
    STYLE    => 'default',
  }
);
$html->{show_header} = 1;

do "../language/english.pl";
if (-f "../language/$html->{language}.pl") {
  do "../language/$html->{language}.pl";
}

our $db = AXbills::SQL->connect( @conf{qw/dbtype dbhost dbname dbuser dbpasswd/},
  { CHARSET => $conf{dbcharset} });
our $admin    = Admins->new($db, \%conf);
our $users    = Users->new($db, $admin, \%conf);
our $user     = Users->new($db, $admin, \%conf);
our $Internet = Internet->new($db, $admin, \%conf);
our $Tariffs  = Tariffs->new($db, \%conf, $admin);
our $Hotspot  = Hotspot->new($db, $admin, \%conf);
Conf->new($db, $admin, \%conf);

require Hotspot::HotspotBase;

# print "Content-type:text/html\n\n";
hotspot_init();

hotspot_radius_error() if ($FORM{error});
hotspot_pre_auth();
hotspot_auth();
hotspot_registration();

print "Content-type:text/html\n\n";
print "Ok";

exit;

1;