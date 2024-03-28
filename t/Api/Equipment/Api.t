=head1 NAME

  Equipment API test

=cut

use strict;
use warnings;

use lib '../';
use Test::More;
use Test::JSON::More;
use FindBin '$Bin';
use FindBin qw($RealBin);
use JSON;

require $Bin . '/../../../libexec/config.pl';

BEGIN {
  our $libpath = '../../../';
  my $sql_type = 'mysql';
  unshift(@INC, $libpath . "AXbills/$sql_type/");
  unshift(@INC, $libpath);
  unshift(@INC, $libpath . 'lib/');
  unshift(@INC, $libpath . 'libexec/');
  unshift(@INC, $libpath . 'AXbills/');
  unshift(@INC, $libpath . 'AXbills/modules/');
}

use AXbills::Defs;
use Init_t qw(test_runner folder_list help);
use AXbills::Base qw(parse_arguments);
use Admins;
use Equipment;

our (
  %conf
);

my $ARGS = parse_arguments(\@ARGV);
my $apiKey = $ARGS->{KEY} || $ARGV[$#ARGV] || q{};
my @test_list = folder_list($ARGS, $RealBin);
my $debug = $ARGS->{DEBUG} || 0;

my $Equipment = Equipment->new($db, $admin, \%conf);

my $onu_list = $Equipment->onu_list({
  COLS_NAME => 1,
});

if (lc($ARGV[0]) eq 'help') {
  help();
  exit 0;
}

foreach my $test (@test_list) {
  if ($test->{path} =~ /equipment\/onu\/:id\//g) {
    my $id = (scalar(@{$onu_list})) ? $onu_list->[0]->{id} : '';
    $test->{path} =~ s/:id/$id/g;
  }
}

test_runner({
  apiKey => $apiKey,
  debug  => $debug
}, \@test_list);

done_testing();

1;