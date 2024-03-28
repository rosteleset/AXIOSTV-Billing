=head1 NAME

  API test

=head1 VERSION

  VERSION: 0.10

=cut

use strict;
use warnings;

use lib '.';
use Test::More;
use Test::JSON::More;
use FindBin '$Bin';
use FindBin qw($RealBin);
use HTTP::Request::Common;
use Term::ANSIColor;
use LWP::Simple;
use JSON qw(decode_json encode_json);
use experimental 'smartmatch';

require $Bin . "/../libexec/config.pl";

BEGIN {
  our $libpath = '../';
  my $sql_type = 'mysql';
  unshift(@INC, $libpath . "AXbills/$sql_type/");
  unshift(@INC, $libpath);
  unshift(@INC, $libpath . 'lib/');
  unshift(@INC, $libpath . 'libexec/');
  unshift(@INC, $libpath . 'AXbills/');
  unshift(@INC, $libpath . 'AXbills/modules/');
  eval {require Time::HiRes;};
  our $global_begin_time = 0;
  if (!$@) {
    Time::HiRes->import(qw(gettimeofday));
    $global_begin_time = Time::HiRes::gettimeofday();
  }
}

use AXbills::Defs;
use AXbills::Base;
use AXbills::Fetcher;

our (
  $Bin,
  %FORM,
  %LIST_PARAMS,
  %functions,
  %conf,
  $html
);

my @test_list = ();

my %colors = (
  OK       => 'bold green',
  BAD      => 'bold red',
  CONTRAST => 'bold BRIGHT_WHITE',
  INFO     => 'bold white'
);

my $ARGS = parse_arguments(\@ARGV);
my $sid = q{};
my $uid = q{};

opendir(DIR, 'schemas');
my @folder = readdir(DIR);

foreach my $folder (@folder) {
  next if ($folder =~ /\./);
  next if ($folder =~ /admin/);

  my $request_file = "$RealBin/schemas/$folder/$folder\_request.json";
  my $schema_file = "$RealBin/schemas/$folder/$folder\_schema.json";

  open(my $request_str, $request_file);
  open(my $schema_str, $schema_file);

  my $request_plain = do {
    local $/;
    <$request_str>
  };
  my $schema = do {
    local $/;
    <$schema_str>
  };

  my $request = decode_json($request_plain);
  my %request_hash = %$request;

  $request_hash{schema} = $schema;

  push(@test_list, \%request_hash);
}

my $test_number = 0;
my $apiKey = $ARGS->{KEY} || $ARGV[$#ARGV];
my $protocol = ("--use-http" ~~ @ARGV) ? "http" : "https";

my $response;

foreach my $test (@test_list) {
  next if ($test->{name} ne 'LOGIN');

  $test->{body}->{login} = $conf{API_TEST_USER_LOGIN} || "test";
  $test->{body}->{password} = $conf{API_TEST_USER_PASSWORD} || "123456";

  test_check($test);

  if($response->{_content}){
    my $res = decode_json($response->{_content});
    $sid = $res->{sid};
    $uid = $res->{uid};
  }
}

foreach my $test (@test_list) {
  next if ($test->{name} eq 'LOGIN');
  test_check($test);
}

#**********************************************************
=head2 test_check($test)

  Params
    $test - test params hash

  Returns
    prints result of test
=cut
#**********************************************************
sub test_check {
  my ($test) = @_;
  $test_number++;

  if ($test->{path} =~ /user\//g && $test->{path} =~ /:uid/g) {
    $test->{path} =~ s/:uid/$uid/g;
    # AXbills::Base::_bp('', $test->{path}, {TO_CONSOLE => 1});
  }

  my $url = "$protocol://" . ($ARGS->{URL} ? $ARGS->{URL} : 'localhost:9443') . "/api.cgi/$test->{path}";

  my $start_time = gettimeofday();

  my $http_status = 0;
  my $execution_time = 0;

  my $Ua = LWP::UserAgent->new(
    ssl_opts => {
      verify_hostname => 0,
      SSL_verify_mode => 0
    },
  );

  $Ua->protocols_allowed([ 'http', 'https' ]);
  $Ua->default_header(KEY => $apiKey);

  if ($test->{method} eq 'POST') {
    my $header;

    if ($test->{path} =~ /user\//g) {
      $header = [ 'USERSID' => "$sid", 'Content-Type' => 'application/json; charset=UTF-8' ];
    }
    else {
      $header = [ 'Content-Type' => 'application/json; charset=UTF-8' ];
    }

    my $post_request = HTTP::Request->new('POST', $url, $header, encode_json($test->{body}));

    $response = $Ua->request($post_request);
  }
  elsif ($test->{method} eq 'GET') {
    my %params = %{$test->{params}};
    my $query = '';
    my $header;

    if ($test->{path} =~ /user\//g) {
      $header = [ 'USERSID' => "$sid", 'Content-Type' => 'application/json; charset=UTF-8' ];
    }
    else {
      $header = [ 'Content-Type' => 'application/json; charset=UTF-8' ];
    }
    foreach my $key (keys %params) {
      $query .= $key . '=' . $params{$key} . '&';
    }

    my $get_request = HTTP::Request->new('GET', "$url\?$query", $header);

    $response = $Ua->request($get_request);
  }

  $http_status = $response->code();
  $execution_time = sprintf("%d", (gettimeofday() - $start_time) * 1000);

  my $json = $response->content;

  if ($http_status == 200) {
    print color($colors{OK});
  }
  else {
    print color($colors{BAD});
  }

  print "[$test_number]-$test->{name} ($test->{method})    HTTP STATUS CODE: $http_status    RESPONSE TIME: $execution_time ms. \n";

  print color($colors{INFO}), "Checking is json valid: ", color($colors{CONTRAST});

  if (ok_json($json)) {
    print color($colors{INFO}), "Does JSON belong to schema: ", color($colors{CONTRAST});

    if (!ok_json_schema($json, $test->{schema})) {
      print($json);
      print color($colors{BAD}), "JSON SCHEMA IS INCORRECT \n";
    }

  }
  else {
    print "JSON: $json \n";
  }

  print "------------------------------------\n";
}

print "\n", color($colors{OK}), "REPORT: \n", color($colors{CONTRAST});
done_testing();

1;