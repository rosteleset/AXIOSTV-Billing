=head1 NAME

  Paysys API test

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
use Paysys;

our (
  %conf
);

my $db = AXbills::SQL->connect(
  $conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd},
  {
    CHARSET => ($conf{dbcharset}) ? $conf{dbcharset} : undef,
    dbdebug => $conf{dbdebug}
  }
);
my $admin = Admins->new($db, \%conf);
my $Paysys = Paysys->new($db, $admin, \%conf);

my $ARGS = parse_arguments(\@ARGV);

if (($ARGV[0] && lc($ARGV[0]) eq 'help') || defined($ARGS->{help}) || defined($ARGS->{HELP})) {
  help();
  exit 0;
}

my $apiKey = $ARGS->{KEY} || $ARGV[$#ARGV] || q{};
my @test_list = folder_list($ARGS, $RealBin);
my $debug = $ARGS->{DEBUG} || 0;
my @tests = ();

foreach my $test (@test_list) {
  if ($test->{path} =~ /\/transaction\/status\//g) {
    my $list = $Paysys->list({
      TRANSACTION_ID => '_SHOW',
      LOGIN          => ($conf{API_TEST_USER_LOGIN} || 'test'),
      COLS_NAME      => 1
    });

    $test->{body}->{transactionId} = $list->[0]->{transaction_id};
  }
  elsif ($test->{path} =~ /\/pay\//g && $test->{name} eq 'USER_PAYSYS_PAY') {
    my $list = $Paysys->paysys_connect_system_list({
      MODULE    => '_SHOW',
      STATUS    => 1,
      COLS_NAME => 1,
    });

    foreach my $paysys_module (@{$list}) {
      my %_test = %{$test};
      my ($paysys_name) = $paysys_module->{module} =~ /(.+)\.pm/;
      my $module = "Paysys::systems::$paysys_name";
      eval "use $module";

      if ($module->can('fast_pay_link')) {
        $_test{name} = "USER_PAYSYS_PAY_$paysys_name";
        $_test{body}->{systemId} = $paysys_module->{id};
        $_test{body}->{operationId} = int(rand(1000000));
        $_test{body}->{sum} = 1;
        push @tests, \%_test;
      }
    }
  }
  push @tests, $test;
}

test_runner({
  apiKey => $apiKey,
  debug  => $debug
}, \@tests);

done_testing();

1;
