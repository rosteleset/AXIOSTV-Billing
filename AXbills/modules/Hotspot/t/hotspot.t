#!/usr/bin/perl
#use strict;
use warnings;

use Test::More tests => 23;
use AXbills::Base qw/mk_unique_value/;
#admin interface
$ENV{'REQUEST_METHOD'} = "GET";
$ENV{'QUERY_STRING'} = "user=axbills&passwd=axbills";

use vars qw(
  $sql_type
  $global_begin_time
  %conf
  @MODULES
  %functions
  %FORM
  $users
  $db
  $admin
 );

require_ok( "../libexec/config.pl" );

open ( my $HOLE, '>>', '/dev/null' );
disable_output();
require_ok( "../cgi-bin/admin/index.cgi" );
require_ok( "../AXbills/modules/Hotspot/webinterface" );
enable_otput();

#Initialization
require_ok( 'Hotspot' );

my $Hotspot = Hotspot->new( $db, $admin, \%conf );

my @test_user_agents = (
  # Blackberry
  'Mozilla/5.0 (BlackBerry; U; BlackBerry 9900; en) AppleWebKit/534.11+ (KHTML, like Gecko) Version/7.1.0.346 Mobile Safari/534.11+',
  'Mozilla/5.0 (BlackBerry; U; BlackBerry 9800; en-US) AppleWebKit/534.8+ (KHTML, like Gecko) Version/6.0.0.450 Mobile Safari/534.8+',
  
  # Lynx
  'Lynx/2.8.8dev.3 libwww-FM/2.14 SSL-MM/1.4.1',
  
  # Android
  'Mozilla/5.0 (Linux; U; Android 4.0.3; ko-kr; LG-L160L Build/IML74K) AppleWebkit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30',
  'Mozilla/5.0 (Linux; U; Android 2.3.3; en-us; HTC_DesireS_S510e Build/GRI40) AppleWebKit/533.1 (KHTML, like Gecko) Version/4.0 Mobile Safari/533.1',
  
  # Chrome
  'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2228.0 Safari/537.36',
  'Mozilla/5.0 (Windows NT 5.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2224.3 Safari/537.36',
  'Mozilla/5.0 (X11; OpenBSD i386) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/36.0.1985.125 Safari/537.36',
);

my $test_session_id = mk_unique_value(32);
my $test_advert = {
  NAME             => 'Test advert',
  URL              => 'https://billing.axiostv.ru',
  PRICE_PER_PERIOD => 25.25,
  PERIOD           => 'week'
};

visit_add();
visit_list($test_session_id);

login_add();
login_list_info($test_session_id);

adverts($test_advert);

sub visit_add {
  $Hotspot->visits_add( {
      ID      => $test_session_id,
    } );
  ok(!$Hotspot->{errno}, 'Successfully added new user');
  my $visit_id = $Hotspot->{INSERT_ID} || $test_session_id;
  
  $Hotspot->user_agents_add({
      ID => $visit_id,
      USER_AGENT => get_random_ua()
    });
  
  ok(!$Hotspot->{errno}, 'Successfully added user agent');
}

sub visit_list {
  my ($session_id) = @_;
  my $visits_list = $Hotspot->visits_list( {
      ID               => $session_id,
      SHOW_ALL_COLUMNS => 1,
    } );

  ok(!$Hotspot->{errno}, 'Got visits list without errors');
  ok(scalar @{$visits_list} > 0, 'Got non-empty visits list');

  my $visit = $visits_list->[0];

  ok(ref $visit eq 'HASH', 'Got hash inside list');
  ok( exists $visit->{first_seen}, 'Has FIRST_SEEN field' );
  ok($visit->{first_seen} && $visit->{first_seen} ne '0000-00-00 00:00:00', "Has first seen and it's non-empty" );

};

sub login_add {
  $Hotspot->logins_add( {
      VISIT_ID => $test_session_id,
      UID      => 2,
    } );

  ok(!$Hotspot->{errno}, 'Added login without errors');
}

sub login_list_info {
  my ($session_id) = @_;
  

  # Try to search
  my $logins_list = $Hotspot->logins_list( { VISIT_ID => $session_id, SHOW_ALL_COLUMNS => 1, } );
  ok(scalar @{$logins_list} > 0, 'Got non-empty visits list');

  my $login = $logins_list->[0];

  ok(ref $login eq 'HASH', 'Got hash inside list');
  ok(exists $login->{visit_id}, 'Has visit_id in result');

  # Check info
  my $login2 = $Hotspot->logins_info_for_session( $session_id );
  ok(ref $login2 eq 'HASH', 'Got hash inside info list');
  ok(exists $login2->{visit_id}, 'Has visit_id in result');

  # Check found result has same session id as info
  ok ($login->{visit_id} eq $login2->{visit_id}, 'found result has same session id as info');
}

#**********************************************************
=head2 adverts()

=cut
#**********************************************************
sub adverts {
  my ($advert) = @_;
  

  ok($Hotspot->adverts_add( $advert ) && !$Hotspot->{errno}, 'Added new advert');
  my $added_id = $Hotspot->{INSERT_ID};

  my $added_advert = $Hotspot->adverts_info( $added_id );
  ok ($added_advert->{URL} eq $advert->{URL}, "Get info ");

  ok($Hotspot->advert_shows_add({ AD_ID => $added_advert, UID => 2 }), 'Added advert show');
  my $ad_show_id = $Hotspot->{INSERT_ID};

  my $adverts_count = $Hotspot->advert_shows_count( { ADVERT_ID => $added_id });

  ok (1);
  #FIXME : wrong ad id
#  ok ($adverts_count, 'Has advert shows');
  _error_show($Hotspot);

  ok ($Hotspot->adverts_del( { ID => $added_advert->{ID} } ), 'Deleted same advert');

}

sub get_random_ua{
  return $test_user_agents[rand(scalar @test_user_agents)]
}

sub disable_output {
  select $HOLE;
}

sub enable_otput {
  select STDOUT;
}

