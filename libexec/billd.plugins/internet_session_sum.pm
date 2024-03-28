=head1 NAME

   internet_traffic_sum();

=cut

use strict;
use warnings FATAL => 'all';
use AXbills::Base qw(days_in_month int2byte);
use POSIX qw(strftime mktime);

use Internet::Sessions;
use Fees;

our (
  $db,
  $admin,
  %conf,
  $DATE,
);

my $Sessions = Internet::Sessions->new($db, \%conf, $admin);
my $Fees = Fees->new($db, $admin, \%conf);

add_session_sum_to_fees();


#**********************************************************
=head2 add_session_sum_to_fees() count session sum per user and add to fees

=cut
#**********************************************************
sub add_session_sum_to_fees {
  my $current_month = POSIX::strftime("%m", localtime(time));
  my $month = $current_month - 1;
  my $year  = POSIX::strftime("%Y", localtime(time));
    if ($current_month == 1){
      $month = 12;
      $year -= 1;
    }
  my $previous_month_start = "$year-$month-01";
  my $previous_month_days =  days_in_month({ DATE => "$year-$month" });
  my $previous_month_end = "$year-$month-$previous_month_days";

  my $session_total_sum = $Sessions->session_sum({
    FROM_DATE => $previous_month_start,
    TO_DATE   => $previous_month_end,
    COLS_NAME => 1
  });

  my $traffic_sent = '';
  my $traffic_received = '';

  if ($session_total_sum) {
    foreach my $line (@$session_total_sum) {
      $traffic_sent = int2byte($line->{sent});
      $traffic_received = int2byte($line->{received});

      $Fees->take(
        { UID => $line->{uid} },
        $line->{sum},
        {
          BILL_ID  => $line->{bill_id},
          METHOD   => 1,
          DESCRIBE => "Monthly traffic $year-$month: sent $traffic_sent, received $traffic_received"
        }
      );
    }
  }
}
