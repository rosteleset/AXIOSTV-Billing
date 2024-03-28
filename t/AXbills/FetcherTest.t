#!/usr/bin/perl
use strict;
use warnings;

use Carp::Always;
use Test::More tests => 8;
use JSON;

our $libpath;
BEGIN {
  our $Bin;
  use FindBin '$Bin';
  
  $libpath = $Bin . '/../'; # (default) assuming we are in /usr/axbills/libexec/
  if ( $Bin =~ m/\/axbills(\/)/ ) {
    $libpath = substr($Bin, 0, $-[1]);
  }
  
  unshift @INC, $libpath . '/lib';
  unshift @INC, $libpath . '/AXbills/modules';
  unshift @INC, $libpath . '/AXbills/mysql';
}

use AXbills::Fetcher qw/web_request/;
use AXbills::Base qw/_bp/;

my $SERVER_PID = 0;

my $port = 54300;
ok(install_test_http_server($port), 'Started HTTP::Simple server') || die "Can't start test server";

# Test http
my $http_url = "http://localhost:$port";
my $echo_params_url = "http://localhost:$port/echo";
my $redirect_url = "http://localhost:$port/redirect";

# Test request params in hash
my %test_hash_params = (
  PARAM1 => 'value1',
  PARAM2 => 'value2'
);

# Test request params in hash with arrayref as ine of arguments
my %test_hash_with_arrref_params = (
  PARAM1 => 'value1',
  PARAM2 => [ 'value2' ]
);

ok(web_request($http_url, { BODY_ONLY => 1 }) eq 'OK', 'HTTP request finishes normal');
ok(web_request($http_url, { CURL => 1 }) eq 'OK', 'Curl HTTP request finishes normal');


# Test request_params_json
my $echo1_res = web_request($echo_params_url, { CURL => 1, REQUEST_PARAMS => \%test_hash_params });
my $echo1_decoded = JSON::from_json($echo1_res);
is_deeply(\%test_hash_params, $echo1_decoded, "Curl HTTP sent params normal");

# Test request which returns json
my $echo2_res = web_request($echo_params_url, { CURL => 1, REQUEST_PARAMS => \%test_hash_params, JSON_RETURN => 1 });
is_deeply(\%test_hash_params, $echo2_res, "Curl HTTP sent params normal and JSON encoded ");

my $echo3_res = web_request($echo_params_url, { REQUEST_PARAMS => \%test_hash_with_arrref_params, BODY_ONLY => 1  });
my $echo3_decoded = JSON::from_json($echo3_res);
is_deeply( \%test_hash_params, $echo3_decoded, 'Sent params with arrayref inside has been flattened' );

my $echo4_res = web_request($redirect_url, { BODY_ONLY => 1 });
ok($echo4_res eq 'OK', 'Has been successfuly redirected with socket request');

my $echo5_res = web_request($redirect_url, { CURL => 1 });
ok($echo5_res eq 'OK', 'Has been successfuly redirected with curl request');

sub install_test_http_server {
  my ($server_port) = @_;
  
  eval {
    $SERVER_PID = AXbills::HTTP::Server::Simple->new($server_port)->background();
  };
  if ( $@ ) {
    die "Error while starting HTTP server : $@ \n";
  }
  
  return 1;
}
done_testing();
1;

package AXbills::HTTP::Server::Simple;
use HTTP::Server::Simple::CGI;
use base 'HTTP::Server::Simple::CGI';
use JSON;
use Data::Dumper;

#**********************************************************
=head2 handle_request($cgi) -

  Arguments:
    $cgi
    
  Returns:
  
  
=cut
#**********************************************************
sub handle_request {
  my ($self, $cgi) = @_;
  
  my $path = $cgi->path_info();

  if ($path eq '/redirect'){
    print "HTTP/1.1 302\n";
    print "Location: http://localhost:$port/\r\n\r\n";
    return 1;
  }
  
  print "HTTP/1.0 200\n";
  print "Content-Type: text/plain\n\n";
  
  if ( $path eq '/echo' ) {
   print JSON::to_json({ map { $_ => scalar $cgi->param($_) } $cgi->param() });
  }
  else {
    print "OK";
  }
  
  return 1;
}

END {
  if ( $SERVER_PID ) {
    `kill $SERVER_PID`;
  }
}

1;



