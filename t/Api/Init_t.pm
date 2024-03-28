package Init_t;
=head1 NAME

  Api test Init functions

=cut

use strict;
use warnings FATAL => 'all';
use parent 'Exporter';

use Test::More;
use Test::JSON::More;
use Term::ANSIColor;
use JSON qw(decode_json encode_json);

require '../../../libexec/config.pl';

BEGIN {
  unshift(@INC, '../../../lib/');
}

use AXbills::Fetcher;
use Admins;
use Users;
use AXbills::Api::Router;

our (
  %lang,
  %conf,
  @MODULES
);

our $VERSION = 0.03;

my $db = AXbills::SQL->connect(
  $conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd},
  {
    CHARSET => ($conf{dbcharset}) ? $conf{dbcharset} : undef,
    dbdebug => $conf{dbdebug}
  }
);
my $admin = Admins->new($db, \%conf);
my Users $user = Users->new($db, $admin, \%conf);
my $Conf = Conf->new($db, $admin, \%conf);

our @EXPORT = qw(
  test_runner
  folder_list
  help
);

our @EXPORT_OK = qw(
  test_runner
  folder_list
  help
);

my %colors = (
  OK       => 'bold green',
  BAD      => 'bold red',
  CONTRAST => 'bold BRIGHT_WHITE',
  BLUE     => 'bold BRIGHT_CYAN',
  INFO     => 'bold white'
);

my $login = $conf{API_TEST_USER_LOGIN} || 'test';
my $password = $conf{API_TEST_USER_PASSWORD} || '123456';

#**********************************************************
=head2 test_runner($attr, $tests)

  Params
    $attr
      apiKey  - admin ApiKey
      debug   - level of debug

    $tests    - array of tests

  Returns
    prints result of tests
=cut
#**********************************************************
sub test_runner {
  my ($attr, $tests) = @_;
  my $url = $conf{API_TEST_URL} ? $conf{API_TEST_URL} : 'https://localhost:9443';
  my $debug = $attr->{debug} || 0;
  my ($uid, $sid) = _user_login($url, $debug);

  print color($colors{INFO});

  if (!$uid) {
    print "No user with login: " . $login .
        " with password: " . $password . "\n";
  }
  else {
    print $attr->{message} if ($attr->{message});

    my @params = ({
      %$attr,
      url => $url,
      uid => $uid,
      sid => $sid,
    }, $tests);

    if ($debug < 5) {
      _test_run_web_request(@params);
    }
    else {
      _test_run_directly(@params);
    }
  }
}

#**********************************************************
=head2 _test_run_web_request($attr, $tests)

  Params
    $attr
      apiKey  - admin ApiKey
      debug   - level of debug

    $tests    - array of tests

  Returns
    prints result of tests
=cut
#**********************************************************
sub _test_run_web_request {
  my ($attr, $tests) = @_;
  my $test_number = 0;
  my $url = $attr->{url};
  my $sid = $attr->{sid};

  foreach my $test (@{$tests}) {
    $test_number++;

    if ($test->{path} =~ /:uid/m) {
      $test->{path} =~ s/:uid/$attr->{uid}/g;
    }

    my $http_status = 0;
    my $execution_time = 0;
    my @req_headers = ('Content-Type: application/json');
    my $req_body = '';
    my $query = '';

    if ($test->{path} =~ /user\//m) {
      push @req_headers, "USERSID: $sid";
    }
    else {
      push @req_headers, "KEY: $attr->{apiKey}";
    }

    if ($test->{method} eq 'POST' || $test->{method} eq 'PUT') {
      $req_body = $test->{body};
    }
    elsif ($test->{method} eq 'GET' && $test->{params} && %{$test->{params}}) {
      my %params = %{$test->{params}};

      $query .= '?';
      foreach my $key (keys %params) {
        $query .= $key . '=' . $params{$key} . '&';
      }
    }

    my ($result, $info) = web_request($url . "/api.cgi/$test->{path}" . $query, {
      HEADERS   => \@req_headers,
      JSON_BODY => $test->{body},
      INSECURE  => 1,
      DEBUG     => $attr->{debug} ? 6 : 0,
      METHOD    => $test->{method},
      MORE_INFO => 1
    });

    $http_status = $info->{status} || $info->{response_code} || $info->{http_code};
    $execution_time = $info->{time} || $info->{time_total};

    if ($http_status == 200) {
      print color($colors{OK});
    }
    else {
      print color($colors{BAD});
    }

    print "[$test_number]-$test->{name} ($test->{method})    HTTP STATUS CODE: $http_status    RESPONSE TIME: $execution_time ms. \n";

    print color($colors{INFO}), "Checking is json valid: ", color($colors{CONTRAST});

    if (ok_json($result)) {
      my $res = decode_json($result);

      #renew sid if path users/login
      if ($test->{path} eq 'users/login/') {
        $sid = $res->{sid};
      }

      if (ref $res eq 'HASH' && (defined $res->{error} || defined $res->{errno})) {
        print color($colors{BAD}), "Error: \n";
        print "RESPONSE $result \n";
        print "ERROR NUMBER: " .
          ($res->{error} || $res->{errno} || q{UNKNOWN}) . "\nERROR STRING: " .
          ($res->{errstr} || q{UNKNOW}) . "\n", color($colors{INFO});
      }
      else {
        print color($colors{INFO}), "Does JSON belong to schema: ", color($colors{CONTRAST});
        if (!ok_json_schema($result, $test->{schema})) {
          print($result);
          print color($colors{BAD}), "\nJSON SCHEMA IS INCORRECT \n";
        }
      }
    }
    else {
      print "JSON: $result \n";
    }
    print color($colors{INFO}), "------------------------------------\n";
  }
}

#**********************************************************
=head2 _test_run_directly($attr, $tests)

  Params
    $attr
      apiKey  - admin ApiKey
      debug   - level of debug

    $tests    - array of tests

  Returns
    prints result of tests
=cut
#**********************************************************
sub _test_run_directly {
  my ($attr, $tests) = @_;
  my $test_number = 0;
  my $req_body = 'No body';

  foreach my $test (@{$tests}) {
    $test_number++;
    print color($colors{BLUE}), "[$test_number]\nSQL\n";
    my %FORM = ();
    $test->{path} = "/$test->{path}";
    if ($test->{path} =~ /:uid/m) {
      $test->{path} =~ s/:uid/$attr->{uid}/g;
    }

    if ($test->{method} eq 'POST' || $test->{method} eq 'PUT') {
      $req_body = encode_json($test->{body}) || '';
      $FORM{$req_body} = '';
      $FORM{__BUFFER} = $req_body || '';
    }
    elsif ($test->{method} eq 'GET') {
      my %params = %{$test->{params}};

      if (%params) {
        $test->{path} .= '?';
        foreach my $key (keys %params) {
          $test->{path} .= $key . '=' . $params{$key} . '&';
        }
      }
    }

    my $router = AXbills::Api::Router->new($test->{path}, $db, $admin, $Conf->{conf}, \%FORM, \%lang, \@MODULES, 1, $test->{method});
    $router->add_credential('ADMIN', sub {return 1});
    $router->add_credential('USER', sub {return 1});

    eval {$router->handle();};
    if (!$@) {
      print color($colors{INFO}), "\n\n";
      print "Request: \nMETHOD: $test->{method}\tPATH: $test->{path}\t BODY:\n$req_body\n\n";
      print color($colors{OK}), "Response: \n";
      print encode_json($router->{result});
      print "\n\n\n";
    }
  }
}

#**********************************************************
=head2 _user_login($url)

  Params
    $url - billing url

  Returns
    uid - uid of test user for tests
    sid - sid of test user for tests
=cut
#**********************************************************
sub _user_login {
  my ($url, $debug) = @_;

  my ($result) = web_request("$url/api.cgi/users/login", {
    HEADERS     => [ 'Content-Type: application/json' ],
    JSON_BODY   => {
      login    => $login,
      password => $password
    },
    DEBUG       => $debug,
    JSON_RETURN => 1,
    INSECURE    => 1,
    METHOD      => 'POST',
  });

  if ($result->{error}) {
    print "[$result->{error}] $result->{errstr}\n";
    exit;
  }
  return ($result->{uid}, $result->{sid});
}

#**********************************************************
=head2 folder_list($test, $main_dir)

  Params
    $attr     - ARGV in test
      ADMIN - use only admin schemas
      USER  - use only user schemas
    $main_dir - place where is folder

  Returns
    @test_list - list of tests
=cut
#**********************************************************
sub folder_list {
  my ($attr, $main_dir) = @_;
  my @folders = ();
  my @test_list = ();

  if ($attr->{ADMIN}) {
    push @folders, _read_dir('admin', $main_dir, ($attr->{PATH} || q{}));
    if (!@folders) {
      print color($colors{BAD}), "NO ADMIN TESTS \n";
    }
  }
  elsif ($attr->{USER}) {
    push @folders, _read_dir('user', $main_dir, ($attr->{PATH} || q{}));
    if (!@folders) {
      print color($colors{BAD}), "NO USER TESTS \n";
    }
  }
  else {
    push @folders, _read_dir('admin', $main_dir, ($attr->{PATH} || q{}));
    push @folders, _read_dir('user', $main_dir, ($attr->{PATH} || q{}));
  }

  @folders = sort @folders;
  foreach my $folder (@folders) {
    my $request_file = "$folder/request.json";
    my $schema_file = "$folder/schema.json";

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

  return @test_list;
}

#**********************************************************
=head2 _read_dir($dir, $main_dir)

  Params
    $dir      - dir name admin or user
    $main_dir - place where is folder

  Returns
    @folders - name list of folders of tests
=cut
#**********************************************************
sub _read_dir {
  my ($dir, $main_dir, $path) = @_;

  opendir(DIR, "schemas/$dir");
  my @folder_list = eval {readdir(DIR)};
  my @folders = ();
  foreach my $folder (@folder_list) {
    next if ($folder =~ /\./);
    next if ($path && $folder ne $path);
    push @folders, "$main_dir/schemas/$dir/$folder";
  }

  return @folders;
}

#*******************************************************************
=head2 help() - Help

=cut
#*******************************************************************
sub help {

  print << "[END]";
  ABillS Api test systems
  Runs tests with user with login \$conf{API_TEST_USER_LOGIN} or 'test and with password: \$conf{API_TEST_USER_PASSWORD} or '123456'
  Curl requests send to url defined in param \$conf{API_TEST_URL} or default https://localhost:9443

  default runs all available tests in selected module
    ADMIN=1 - run only admin tests
    USER=1  - run only admin tests

  run selected path:
    PATH={NAME_OF_FOLDER_WITH_TEST}

  DEBUG=[0..5]
    debug > 1 - run all tests with curl debug printing requests and responses
    debug > 5 - run all tests directly with mysql printing requests

  KEY=      - test admin API key,

  help
[END]
}

1;
