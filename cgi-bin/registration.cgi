#!/usr/bin/perl -w

=head2 NAME

  Main registration engine

=cut

use strict;
use warnings FATAL => 'all';

BEGIN {
  our $libpath = '../';
  my $sql_type = 'mysql';
  unshift(
    @INC,
    $libpath . "AXbills/$sql_type/",
    $libpath . 'lib/',
    $libpath . 'AXbills/modules/',
    $libpath . 'AXbills/'
  );

  eval {require Time::HiRes;};
  our $begin_time = 0;
  if (!$@) {
    Time::HiRes->import(qw(gettimeofday));
    $begin_time = Time::HiRes::gettimeofday();
  }
}

use AXbills::Defs;
use AXbills::Base qw(sendmail in_array load_pmodule);
use AXbills::Fetcher qw(web_request);
use Users;
use Admins;

require AXbills::Templates;
require AXbills::Misc;

our (
  %OUTPUT,
  @REGISTRATION,
  %lang,
  %LANG,
  $base_dir,
  $CONTENT_LANGUAGE
);

do "../libexec/config.pl";

our $sid = '';
our AXbills::HTML $html = AXbills::HTML->new({ CONF => \%conf, NO_PRINT => 1, });
our $db = AXbills::SQL->connect($conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd}, { CHARSET => ($conf{dbcharset}) ? $conf{dbcharset} : undef });

if ($conf{LANGS}) {
  $conf{LANGS} =~ s/\n//g;
  my (@lang_arr) = split(/;/, $conf{LANGS});
  %LANG = ();
  foreach my $l (@lang_arr) {
    my ($lang, $lang_name) = split(/:/, $l);
    $lang =~ s/^\s+//;
    $LANG{$lang} = $lang_name;
  }
}

our $admin = Admins->new($db, \%conf);
$admin->info($conf{SYSTEM_ADMIN_ID}, { IP => '127.0.0.1' });

our $users = Users->new($db, $admin, \%conf);

if ($html->{language} ne 'english') {
  do $libpath . "/language/english.pl";
}

if (-f $libpath . "/language/$html->{language}.pl") {
  do $libpath . "/language/$html->{language}.pl";
}

if ($conf{NEW_REGISTRATION_FORM}) {
  require Control::Registration_new;
  Control::Registration_new->import();

  my $Registration =  Control::Registration_new->new($db, $admin, \%conf, {
    lang      => \%lang,
    html      => $html,
    users     => $users,
  });

  my $result = $Registration->_start(\%FORM);

  if ($result->{location}) {
    print "Location: $result->{location}\n\n";
  }
  else {
    print $html->header();
    $html->redirect(@{$result->{redirect}}) if (ref $result->{redirect} eq 'ARRAY' && scalar @{$result->{redirect}});

    my $lang_sel = $html->form_select('language', {
      EX_PARAMS => 'onChange="selectLanguage()"',
      SELECTED  => $html->{language},
      SEL_HASH  => \%LANG,
      NO_ID     => 1
    });

    my %params = (
      TITLE_TEXT       => $lang{REGISTRATION},
      TITLE            => $lang{REGISTRATION},
      DOMAIN_ID        => $FORM{DOMAIN_ID} || 1,
      HTML_STYLE       => 'default',
      CONTENT_LANGUAGE => $CONTENT_LANGUAGE,
      INDEX_NAME       => 'registration.cgi',
      TITLE            => "$conf{WEB_TITLE} - $lang{REGISTRATION}",
      SELECT_LANGUAGE  => $lang_sel,
      DATE             => $DATE,
      TIME             => $TIME,
      IP               => $ENV{REMOTE_ADDR},
    );

    my %for_output = ();
    if ($conf{user_background}) {
      $for_output{BACKGROUND_COLOR} = $conf{user_background};
    }
    elsif ($conf{user_background_url}) {
      $for_output{BACKGROUND_URL} = $conf{user_background_url};
    }

    print $html->tpl_show(templates('registration'), \%params);
    print $html->tpl_show(templates('form_client_start'), { BODY => $result->{output}, %for_output });
  }
}
else {
  require Control::Registration;
  _start();
}

1;
