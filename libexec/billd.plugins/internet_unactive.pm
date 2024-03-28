=head1 NAME

   internet_unactive();

=cut

use strict;
use warnings;

our (
  $Admin,
  $db,
  %conf,
  $argv,
  $debug,
);

use Time::Piece;

my $t = localtime;

require Internet;
require Internet::Sessions;
my $Internet = Internet->new($db, $Admin, \%conf);
my $Sessions = Internet::Sessions->new($db, $Admin, \%conf);

internet_unactive();

#**********************************************************
=head2 internet_unactive()

=cut
#**********************************************************
sub internet_unactive{

  my $last_activity_date = '';
  my $date_now = $t->ymd;
  my $PAGE_ROWS = ($argv->{PAGE_ROWS}) ? $argv->{PAGE_ROWS} : 100000;

  if ($argv->{PERIOD}) {
    $last_activity_date = $argv->{PERIOD};
  }
  else {
    my $t2 = $t - 7776000;
    $last_activity_date = $t2->ymd;
  }

  if ($debug > 6) {
    $Sessions->{debug}=1;
  }

  my $sum_traffic = 0;
  if ($argv->{TRAFFIC_SUM}) {
    $sum_traffic = $argv->{TRAFFIC_SUM};
  }

  my $WHERE = qq{ WHERE i.disable=0 AND u.registration <= '$last_activity_date' };
  if ($argv->{LOGIN}) {
    $WHERE .= " AND  u.id='$argv->{LOGIN}' "
  }

   my $alive_list = $Sessions->query("SELECT
     i.id,
     u.uid,
     SUM(l.recv) AS traffic_sum,
     l.start
     FROM users u
     LEFT JOIN internet_main i ON (u.uid=i.uid)
     LEFT JOIN internet_log l ON (u.uid=l.uid AND (DATE_FORMAT(l.start, '%Y-%m-%d')>='$last_activity_date' and DATE_FORMAT(l.start, '%Y-%m-%d')<='$date_now'))
     $WHERE
     GROUP BY u.uid
     HAVING traffic_sum<=$sum_traffic
     LIMIT $PAGE_ROWS;",
     undef,
     { COLS_NAME => 1 }
   );

  if ($Sessions->{TOTAL} && $Sessions->{TOTAL} > 0) {
    foreach my $u (@{ $alive_list->{list} }) {
      my $uid = $u->{uid};
      if ($debug > 1) {
        print "UID: $uid ";
        # print "LOGIN: $u->{login} ACTIVATE: $u->{internet_activate} DEPOSIT: $u->{deposit} CREDIT: $u->{credit} STATUS: $u->{internet_status} \n";
      }

      if ($debug < 6) {
        $Internet->user_change({
          UID    => $uid,
          STATUS => 5,
          ID     => $u->{id},
        });
      }

      print "$DATE $TIME UID: $uid unactive\n";
    }
  }

  return 1;
}

1;
