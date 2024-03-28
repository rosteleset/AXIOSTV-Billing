=head1 NAME

  JSON API test

=cut

use strict;
use warnings;
use Test::More;
use Test::JSON::More;
use LWP::Simple;                # From CPAN
use JSON qw( decode_json );     # From CPAN
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
sub json_test_remove {
  my ($test_list, $attr) = @_;

  open(my $FILE, '<:encoding(UTF-8)', $Bin . "/.test") or die "Could not open file .test' $!";
  my @user_data = split(/[\s\-\:]+/, <$FILE>);

  my $url = "https://demo.axbills.net.ua:9443/index.cgi?&json=1&user=$user_data[0]&passwd=$user_data[1]";

  my $test_name = $attr->{TEST_NAME} || 'Test JSON';
  my $test_ = $test_list->[0];
  $ENV{'QUERY_STRING'} = join('&', map {"$_=$test_->{params}->{$_}"} sort keys %{ $test_->{params} });

  subtest $test_name => sub {
    my $subtest_num = 0;
    foreach my $test (@$test_list) {

      my $tmp_index = $test->{params}->{get_index};
      my $trendsurl = "$url&get_index=$tmp_index";
      my $json = get( $trendsurl );
      print $json;

      delete $html->{JSON_OUTPUT};
      $subtest_num++;
      $ENV{'QUERY_STRING'} = join('&', map {"$_=$test->{params}->{$_}"} sort keys %{$test->{params}});
      if ($debug > 2) {
        print "REQUEST: $ENV{'QUERY_STRING'}\n";
      }

      %FORM = %{$test->{params}};
      %LIST_PARAMS = %{$test->{params}};

      if (defined(&quick_functions)) {
        quick_functions();
      }
      # # else {
      # #   print "NO: quick_functions\n";
      # # }

      if ($test->{valid_json}) {
        if (ok_json($json)) {
          if ($test->{schema}) {
            if (!ok_json_schema($json, $test->{schema})) {
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



