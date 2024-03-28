#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';

BEGIN {
  our $libpath = '../';
  my $sql_type = 'mysql';
  unshift(@INC,
    $libpath . "AXbills/$sql_type/",
    $libpath . 'AXbills/modules/',
    $libpath . '/lib/',
    $libpath . '/AXbills/',
    $libpath . '/AXbills/Api/',
    $libpath
  );

  eval {require Time::HiRes;};
  our $begin_time = 0;
  if (!$@) {
    Time::HiRes->import(qw(gettimeofday));
    $begin_time = Time::HiRes::gettimeofday();
  }
}

use AXbills::JSON;
use AXbills::Defs;
use Users;
use Admins;
use Conf;
use AXbills::Api::Handle;

require Control::Auth;

# PLEASE DO NOT DELETE THIS GLOBAL VARIABLES
our (
  %LANG,
  %lang,
  %conf,
  @MONTHES,
  @WEEKDAYS,
  $base_dir,
  @REGISTRATION,
  @MODULES,
  %functions,
  %COOKIES,
  %FORM,
  $PROGRAM,
  $DATE,
  $TIME,
  %LIST_PARAMS
);

do 'AXbills/Misc.pm';
do '../libexec/config.pl';
do $libpath . '/language/english.pl';

if ($conf{API_NGINX} && $ENV{REQUEST_URI}) {
  $ENV{REQUEST_URI} =~ s/\/api.cgi//;
  $ENV{PATH_INFO} = $ENV{REQUEST_URI};
}

our $db = AXbills::SQL->connect($conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd},
  { CHARSET   => ($conf{dbcharset}) ? $conf{dbcharset} : undef,
    dbdebug   => $conf{dbdebug},
    db_engine => 'dbcore'
  });

our $admin      = Admins->new($db, \%conf);
our Users $user = Users->new($db, $admin, \%conf);
our $Conf       = Conf->new($db, $admin, \%conf);

our $html = AXbills::HTML->new({
  IMG_PATH   => 'img/',
  NO_PRINT   => 1,
  CONF       => \%conf,
  CHARSET    => $conf{default_charset},
  HTML_STYLE => $conf{UP_HTML_STYLE},
});

if ($conf{API_CONF_LANGUAGE} && -f $libpath . "/language/$html->{language}.pl") {
  do $libpath . "/language/$html->{language}.pl";
}

if ($conf{API_SWAGGER} && $ENV{PATH_INFO} && "$ENV{PATH_INFO}" =~ /swagger/) {
  _swagger();
}
else {
  _start();
}

#**********************************************************
=head2 _start() - run main api logic

  Arguments:

  Return:
   print return of API login
=cut
#**********************************************************
sub _start {
  my $handle = AXbills::Api::Handle->new($db, $admin, $Conf->{conf}, {
    req_params     => \%FORM,
    html           => $html,
    lang           => \%lang,
    cookies        => \%COOKIES,
    path           => $ENV{PATH_INFO} || q{},
    request_method => $ENV{REQUEST_METHOD} || q{},
    return_type    => 'json'
  });

  my $result = $handle->_start();

  if ($result->{content_type}) {
    _custom_headers({
      STATUS       => $result->{status},
      CONTENT_TYPE => $result->{content_type},
    });

    print $result->{response};
  }
  else {
    print AXbills::JSON::header(undef, { STATUS => $result->{status} || '' });
    print $result->{response};
  }

  return 1;
}

#**********************************************************
=head2 _swagger() - print Swagger specification of API

  Arguments:

  Return:
   print YAML ADMIN or USER REST API
=cut
#**********************************************************
sub _swagger {
  my $swagger = q{};
  if ($ENV{PATH_INFO} && "$ENV{PATH_INFO}" =~ /swagger\/admin/) {
    $swagger = _read_swagger('misc/api/admin.yaml');
  }
  else {
    $swagger = _read_swagger('misc/api/bundle_user.yaml');
  }

  _custom_headers({ CONTENT_TYPE => 'Content-Type: application/yaml; charset=utf-8' });
  print $swagger;

  return 1;
}

#**********************************************************
=head2 _read_swagger() - read swagger file from misc swagger yaml file

  Arguments:
    path - path of file of yaml swagger specification

  Return:
   return ADMIN or USER REST API
=cut
#**********************************************************
sub _read_swagger {
  my ($path) = @_;
  my $content = '';
  open(my $fh, '<', $base_dir . $path);
  while(<$fh>) {
    $content .= $_;
  }
  close($fh);

  return $content;
}

#**********************************************************
=head2 _custom_headers() - print own content type with headers

  Arguments:
    path - path of file of yaml swagger specification

  Return:
   return ADMIN or USER REST API
=cut
#**********************************************************
sub _custom_headers {
  my ($attr) = @_;

  my $status = $attr->{STATUS} || 200;
  my $content_type = $attr->{CONTENT_TYPE} || "Content-Type: application/json; charset=utf-8";

  print "$content_type\n";
  print "Access-Control-Allow-Origin: *\n";
  print "Access-Control-Allow-Headers: *\n";
  print "Status: $status\n\n";
}

1;
