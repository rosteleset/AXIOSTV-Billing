#!/usr/bin/perl
=head NAME hosting.pl

  ACTIVE OR ALERT user_tariff
  ATTRIBUTES:
    UID= - user uid
    ACTION= - ACTIVE OR ALERT
    TP_ID= ID tariff
    COMMENTS= comments
    SUM=  sum
    DEBUG=10
  USEGE:
    hosting.pl ACTION=ACTIVE UID=1112 TP_ID=5 COMMENTS="Hosting: user.domain.com" SUM="15.5"

=cut

no if $] >= 5.017011, warnings => 'experimental::smartmatch';
use strict;

our $libpath;
BEGIN {
  use FindBin '$Bin';

  our $Bin;
  use FindBin '$Bin';

  $libpath = $Bin . '/../';
  if ($Bin =~ m/\/axbills(\/)/) {
    $libpath = substr($Bin, 0, $-[1]);
  }

  unshift(@INC, $libpath,
    $libpath . '/AXbills/',
    $libpath . '/AXbills/mysql/',
    $libpath . '/AXbills/Control/',
    $libpath . '/lib/'
  );
}
do "libexec/config.pl";

use strict;
use warnings FATAL => 'all';
use Abon;
use Fees;
use Admins;
use AXbills::Defs;
use AXbills::Base;
use AXbills::Base qw(in_array sendmail days_in_month cmd);

my $argv = parse_arguments(\@ARGV);

my $debug = 0;

if ($argv->{DEBUG}) {
  $debug=$argv->{DEBUG};
}
our (
  %conf,
  %lang,
  $html,
  $users,
  %permissions,
  @WEEKDAYS,
  @MONTHES,
  %FORM
);

our $db = AXbills::SQL->connect(@conf{qw/dbtype dbhost dbname dbuser dbpasswd/},
  { CHARSET => $conf{dbcharset} });

my $admin = Admins->new( $db, \%conf );
$admin->info( $conf{SYSTEM_ADMIN_ID}, {
  IP    => '127.0.0.3',
  SHORT => 1
} );

my $Abon = Abon->new($db, $admin, \%conf);
my $Fees = Fees->new($db, $admin, \%conf);

main();

#********************************************************
=head2 main() - main function


=cut
#********************************************************
sub main {
  if (!$argv->{'ACTION'}) {
    print <<"[END]";
Please select action
      hosting.pl ACTIVE|ALERT
      UID=
      TP_ID=
      COMMENTS=
      SUM=
[END]
  }
  elsif ($argv->{ACTION} eq 'ACTIVE') {
    active();
  }
  elsif ($argv->{ACTION} eq 'ALERT') {
    alert()
  }

  return 1;
}
#********************************************************
=head2 active() - give static ip for user


=cut
#********************************************************
sub active {
  my ($user) = @_;

  my $uid = $users->{UID} || $argv->{UID};

  require Users;

  my $users = Users->new($db, undef, \%conf);

  $users->info($uid);
  $users->pi({ UID => $uid });

  my $list = $Abon->user_tariff_list($argv->{UID}, { COLS_NAME => 1 });

  my $paysys_log_file = '/tmp/hosting.log';
  open(my $fh, '>>', "$paysys_log_file");

  foreach my $line (@{$list}) {

    if($line->{active_service}==1){
      print $fh "\n$DATE $TIME Tariff plan ID = $argv->{TP_ID} subscriber's  UID = $argv->{UID} already active or does not exist =========================\n";
      print "\n$DATE $TIME Tariff plan ID = $argv->{TP_ID} subscriber's  UID = $argv->{UID} already active or does not exist =========================\n";
    }
    else{
      if ($line->{id} eq $argv->{TP_ID}) {
        $Abon->user_tariff_add({
          TP_ID    => $line->{id},
          UID      => $argv->{UID},
          COMMENTS => $argv->{COMMENTS}
        });

        my $description = "$line->{tp_name} ($line->{id})";

        my %PARAMS = (
           DESCRIBE => $description,
           METHOD   => $line->{tp_name}
        );

        $Fees->take($users, $line->{price}, { %PARAMS });

        print $fh "\n$DATE $TIME Tariff plan ID = $argv->{TP_ID} subscriber's UID = $argv->{UID} add =========================\n";
        print "\n$DATE $TIME Tariff plan ID = $argv->{TP_ID} subscriber's UID = $argv->{UID} add =========================\n";
        return 1;
      }
    }
  }

  return 1;
}

#********************************************************
=head2 alert() - remove static ip from user


=cut
#********************************************************
sub alert {
  my ($uid) = @_;

  my $list = $Abon->user_tariff_list($argv->{UID}, { COLS_NAME => 1 });

  my $paysys_log_file = '/tmp/hosting.log';
  open(my $fh, '>>', "$paysys_log_file");

  foreach my $line (@{$list}) {
    if ($line->{id} eq $argv->{TP_ID}) {
      $Abon->user_tariff_del({
        UID    => $argv->{UID},
        TP_IDS => $line->{id},
      });
      print $fh "\n$DATE $TIME Tariff plan ID = $argv->{TP_ID} subscriber's UID = $argv->{UID} delete =========================\n";
      print "\n$DATE $TIME Tariff plan ID = $argv->{TP_ID} subscriber's UID = $argv->{UID} delete =========================\n";
      return 1;
    }
  }

  return 1;
}

1;