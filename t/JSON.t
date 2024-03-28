=head1 NAME

  JSON API test

=cut

use strict;
use warnings;
use Test::More;
use Test::JSON::More;
use FindBin '$Bin';

BEGIN {
  our $libpath = '../';
  my $sql_type = 'mysql';
  unshift(@INC, $libpath . "AXbills/$sql_type/");
  unshift(@INC, $libpath);
  unshift(@INC, $libpath . 'lib/');
  unshift(@INC, $libpath . 'libexec/');
  unshift(@INC, $libpath . 'AXbills/');
  unshift(@INC, $libpath . 'AXbills/modules/');
  eval { require Time::HiRes; };
  our $global_begin_time = 0;
  if (!$@) {
    Time::HiRes->import(qw(gettimeofday));
    $global_begin_time = Time::HiRes::gettimeofday();
  }
}

our (
  $Bin,
  %FORM,
  %LIST_PARAMS,
  %functions,
  %conf,
  $html
);

require $Bin ."/../libexec/config.pl";
my $debug = 3;
$conf{language}='english';
$ENV{DEBUG}=1;
$ENV{'REQUEST_METHOD'}='GET';

# Test example
my @test_list = (
  {
    params  => {
      json      => 1,
      API_KEY   => '1523615231263123',
    },
    name    => 'Blind test',
    result  => ''
  },
  {
    params  => {
      json      => 1,
      API_INFO  => 1,
      API_KEY   => '1523615231263123'
    },
    name    => 'Blind test',
    result  => ''
  },
  {
    params  => {
      get_index => 'internet_tp',
      EXPORT_CONTENT => 'INTERNET_TARIF_PLANS',
      #header    => 1,
      json      => 1,
      API_KEY   => '1523615231263123',
      PAGE_ROWS => 1,
      show_columns => 'id,name'
    },
    name    => 'Show TP',
    result  => '',
    valid_json => 1
  },
  {
    params  => {
      get_index => 'internet_users_list',
      EXPORT_CONTENT => 'INTERNET_USERS_LIST',
      #header    => 1,
      json      => 1,
      API_KEY   => '1523615231263123',
      PAGE_ROWS => 1,
      #show_columns => 'login,tp_name,tp_id'
    },
    name    => 'Show internet users',
    result  => '',
    valid_json => 1
  },
  {
    params  => {
      get_index=> 'msgs_admin',
      STATE    => 0,
      sort     => 1,
      desc     => 'DESC',
      EXPORT_CONTENT=>'MSGS_LIST',
      json     => 1,
      PAGE_ROWS=> 1
    },
    name    => 'Show msgs',
    result  => '',
    valid_json => 1
  },
  {
    params  => {
      qindex => 15,
      header => 1,
      UID    => 200000,
      json   => 1,
    },
    name    => 'Show error for not found user',
    result  => '',
    valid_json => 1
  },
  {
    params => {
      UID    => 112,
      json   => 1,
      header => 1,
      qindex => 15
    },
    name    => 'Show error for not found user',
    result  => '',
    valid_json => 1
  },
  {
    params => {
      qindex      => 15,
      UID         => 112,
      SUMMARY_SHOW=> 1,
      EXPORT      => 1,
    },
    name    => 'Show error for not found user',
    result  => '',
    valid_json => 1
  }
);


# json_test(\@test_list);
#**********************************************************
=head2 json_test($test_list, $attr) - period select

  Argumentsd:
    $test_list
    $attr
      TEST_NAME - test name
      UI   - Test user interface

  Returns:

=cut
#**********************************************************
sub json_test {
  my ($test_list, $attr) = @_;

  my $test_name = $attr->{TEST_NAME} || 'Test JSON';
  my $test_ = $test_list->[0];
  $ENV{'QUERY_STRING'} = join('&', map {"$_=$test_->{params}->{$_}"} sort keys %{ $test_->{params} });

  if($attr->{UI}) {
    eval {do "../cgi-bin/index.cgi"};
  }
  else {
    eval {do "../cgi-bin/admin/index.cgi"};
  }

  subtest $test_name => sub {
    my $subtest_num = 0;
    foreach my $test (@$test_list) {
      delete $html->{JSON_OUTPUT};
      $subtest_num++;
      $ENV{'QUERY_STRING'} = join('&', map {"$_=$test->{params}->{$_}"} sort keys %{$test->{params}});
      if ($debug > 2) {
        print "REQUEST: $ENV{'QUERY_STRING'}\n";
      }

      %FORM = %{$test->{params}};
      $html->form(\%FORM);
      %LIST_PARAMS = %{$test->{params}};

      if (defined(&quick_functions)) {
        quick_functions();
      }
      # # else {
      # #   print "NO: quick_functions\n";
      # # }
      print "RESULT: '" . ($html->{RESULT} || q{}) . "'\nEND RESULT $subtest_num\n";
      if ($test->{valid_json}) {
        if (ok_json($html->{RESULT})) {
          if ($test->{schema}) {
            if (!ok_json_schema($html->{RESULT}, $test->{schema})) {
              print "Failed schema test: $test->{name}\n";
              exit;
            }
          }
        }
        else {
          exit;
        }
      }
      else {
        $test->{result} //= q{};
        like($html->{RESULT}, qr/$test->{result}/,
          ($test->{name} || 'Test name not defined') . ': '
            . ' RESULT: ' . ($html->{RESULT} || q{})
        );
      }
      delete $html->{RESULT};
    }
  };

  done_testing();
}

1;
