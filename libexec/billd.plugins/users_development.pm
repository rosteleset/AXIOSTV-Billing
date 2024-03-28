=head1 NAME

 billd plugin

 DESCRIBE: fill users_development table

=cut
#**********************************************************

use strict;
use warnings FATAL => 'all';
use Tariffs;
use Users;
use Internet;
use AXbills::Base qw/parse_arguments/;

our (
  $argv,
  $DATE,
  $TIME,
  $debug,
  $db,
  %conf,
  $admin,
  $base_dir,
  %lang
);

$argv = parse_arguments(\@ARGV);

my $Internet = Internet->new($db, $admin, \%conf);

users_development();

sub users_development {

  $Internet->users_development_report($DATE, { GROUP_BY => 'districts.city' });
  return if $Internet->{TOTAL} && $Internet->{TOTAL} > 0;

  my $internet_users_list = $Internet->user_list({
    DAY_FEE         => '_SHOW',
    MONTH_FEE       => '_SHOW',
    UID             => '_SHOW',
    INTERNET_STATUS => '_SHOW',
    DISABLE         => 0,
    COLS_NAME       => 1,
    PAGE_ROWS       => 99999
  });

  foreach my $user (@{$internet_users_list}) {
    my $sum = $user->{month_fee} || $user->{day_fee} || 0;
    $Internet->users_development_add({
      UID     => $user->{uid},
      SUM     => $sum,
      DISABLE => $user->{internet_status},
      DATE    => $DATE,
    });

    print "UID: $user->{uid}, SUM: $sum\n" if $argv->{DEBUG} && !$Internet->{errno};
  }
}

1;