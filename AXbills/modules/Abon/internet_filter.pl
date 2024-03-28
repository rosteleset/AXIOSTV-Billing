#!/usr/bin/perl
=head NAME internet_filter

  GIVE FILTER FOR USER

  ATTRIBUTES:
      UID=
      FILTER_ID=

  USEGE:

    internet_filter.pl FILTER_ID=parent_control UID=1  ACTION=ACTIVE

=cut
no if $] >= 5.017011, warnings => 'experimental::smartmatch';
use strict;

our $libpath;
BEGIN {
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
our (%conf);

use AXbills::SQL;
use AXbills::Base qw/parse_arguments/;
use Internet;
use Admins;

my $argv = parse_arguments(\@ARGV);

my $debug = 0;

if ($argv->{DEBUG}) {
  $debug=$argv->{DEBUG};
}

our $db = AXbills::SQL->connect(@conf{qw/dbtype dbhost dbname dbuser dbpasswd/},
  { CHARSET => $conf{dbcharset} });

my $Admin = Admins->new( $db, \%conf );
$Admin->info( $conf{SYSTEM_ADMIN_ID}, {
  IP    => '127.0.0.3',
  SHORT => 1
} );

my $Internet = Internet->new($db, $Admin, \%conf);

set_filter();

#********************************************************
=head2 main() - main function


=cut
#********************************************************
sub set_filter {
  if (!$argv->{'ACTION'}) {
    print <<"[END]";
Please select action
    internet_filter.pl ACTION=[ACTIVE|ALERT]
      UID=
      FILTER_ID=
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

  $Internet->filters_info($argv->{FILTER_ID});

  if ($debug > 7) {
    $Internet->{debug} = 1;
  }

  $Internet->user_change({
    UID => $argv->{UID},
    FILTER_ID => $Internet->{PARAMS},
  });

  return 1;
}

#********************************************************
=head2 alert() - remove static ip from user


=cut
#********************************************************
sub alert {
  my $list = $Internet->user_list({
    UID       => $argv->{UID},
    ID        => '_SHOW',
    COLS_NAME => 1,
  });

  $Internet->user_change({
    ID  => $list->[0]->{id},
    UID => $argv->{UID},
    FILTER_ID => '',
  });

  return 1;
}


1;