=head1 Billing test



=cut

use strict;
use warnings;
use FindBin '$Bin';
use lib '../', $Bin.'/../../../lib/';
use AXbills::SQL;
use Billing;

our $Bin;
our %conf;

do $Bin. '/../../../libexec/config.pl';

my $db = AXbills::SQL->connect($conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd},
  { CHARSET => ($conf{dbcharset}) ? $conf{dbcharset} : undef,
    dbdebug => $conf{dbdebug}
  });

$conf{rt_billing}=0;
$conf{INTERNET_INTERVAL_PREPAID}=0;

my $Billing = Billing->new($db, \%conf);

my %RAD = (
  OUTBYTE        => 1000000000,
  INBYTE         => 200000000,
  SESSION_START  => '2020-04-03 00:00:00',
  'Acct-Output-Gigawords'  => 0,
  'Acct-Input-Gigawords'   => 0
);

my %TRAFFIC_PRICE = (
  TRAFFIC_PRICE => {
    LIST    => {
      in => { 0 => 1 },
      out => { 0 => 1 },
    },
    PREPAID => { 0 => 1000  },
    EXPR    => { 0 => '' }
  }
);

$Billing->{INTERNET}=1;
my $traffic_sum = $Billing->traffic_calculations(\%RAD, \%TRAFFIC_PRICE);

print $traffic_sum . "\n";

1;