=head1 NAME

  API test

=head1 VERSION

  VERSION: 0.01

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

require $Bin . '/../libexec/config.pl';

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
use Admins;

our (
  $Bin,
  %FORM,
  %LIST_PARAMS,
  %functions,
  %conf,
  $html
);
my $db = AXbills::SQL->connect(
  $conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd},
  {
    CHARSET => ($conf{dbcharset}) ? $conf{dbcharset} : undef,
    dbdebug => $conf{dbdebug}
  }
);
my $admin = Admins->new($db, \%conf);

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
my $login = $conf{API_TEST_USER_LOGIN} || 'test';
my $password =$conf{API_TEST_USER_PASSWORD} || '123456';

opendir(DIR, 'schemas');
my @folder = readdir(DIR);

foreach my $folder (@folder) {
  next if ($folder =~ /\./);
  next if (!($folder =~ /paysys/) && !($folder =~ /login/));

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

  $test->{body}->{login} = $login;
  $test->{body}->{password} = $password;
  test_check($test);

  if($response->{_content}){
    my $res = decode_json($response->{_content});
    $sid = $res->{sid};
    $uid = $res->{uid};
  }
}

foreach my $test (@test_list) {
  next if ($test->{name} eq 'LOGIN');
  paysys_paths($test);
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

  if ($test->{path} =~ /:uid/m) {
    $test->{path} =~ s/:uid/$uid/g;
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

    if ($test->{path} =~ /user\//m) {
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

    if ($test->{path} =~ /user\//m) {
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
    my $res = decode_json($json);
    if (ref $res eq 'HASH' && defined($res->{error})) {
      print color($colors{BAD}), "Error: \n";
      print "ERROR NUMBER: $res->{error} \nERROR STRING: $res->{errstr}\n", color($colors{INFO});
    }
    else {
      print color($colors{INFO}), "Does JSON belong to schema: ", color($colors{CONTRAST});
      if (!ok_json_schema($json, $test->{schema})) {
        print($json);
        print color($colors{BAD}), "JSON SCHEMA IS INCORRECT \n";
      }
    }
  }
  else {
    print "JSON: $json \n";
  }

  print "------------------------------------\n";
}

#**********************************************************
=head2 paysys_paths($test) sub for Paysys routes

  Params
    $test - test params hash

  Returns
    new $test with edited body for this POST test
=cut
#**********************************************************
sub paysys_paths {
  my ($test) = @_;
  use Paysys;
  my $Paysys = Paysys->new($db, $admin, \%conf);

  if ($test->{path} =~ /\/transaction\/status\//g) {
    my $list = $Paysys->list({
      TRANSACTION_ID => '_SHOW',
      LOGIN          => $login,
      COLS_NAME      => 1
    });

    $test->{body}->{transactionId} = $list->[0]->{transaction_id};
    test_check($test);
  }
  elsif ($test->{path} =~ /\/pay\//g) {
    my $list = $Paysys->paysys_connect_system_list({
      MODULE    => '_SHOW',
      STATUS    => 1,
      COLS_NAME => 1,
    });

    foreach my $paysys_module (@{$list}){
      my ($paysys_name) = $paysys_module->{module} =~ /(.+)\.pm/;
      my $module = "Paysys::systems::$paysys_name";
      eval "use $module";
      if ($module->can('fast_pay_link')){
        $test->{name} = "USER_PAYSYS_PAY_$paysys_name";
        $test->{body}->{systemId} = $paysys_module->{id};
        $test->{body}->{operationId} = int(rand(1000000));
        $test->{body}->{sum} = 1;
        test_check($test);
      }
    }
  }
  else {
    test_check($test);
  }

  return 1;
}

print "\n", color($colors{OK}), "REPORT: \n", color($colors{CONTRAST});
done_testing();

1;