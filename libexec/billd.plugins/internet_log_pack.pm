=head1 NAME

   internet_log_pack

   Arguments:

=cut

use strict;
use warnings FATAL => 'all';

our (
  $Admin,
  $debug,
  $DATE,
);

internet_log_pack();

#**********************************************************
=head2 internet_log_pack($attr)

  Arguments:


  Returns:

=cut
#**********************************************************
sub internet_log_pack {

  use AXbills::Base qw(next_month);

  if ($debug > 2) {
    print "internet_log_pack\n";
  }

  my ($year, $month) = split(/-/, pre_month({ DATE => $DATE }));

  my @queries = ();

  push @queries, "DROP TABLE IF EXISTS internet_log_new;",
    "DROP TABLE IF EXISTS internet_" . $year . "_" . $month . ";",
    "CREATE TABLE internet_" . $year . "_" . $month . " LIKE internet_log;",
    "CREATE TABLE internet_log_new LIKE internet_log;",
    "DROP TABLE IF EXISTS internet_log_" . $year . "_" . $month . ";",
    "RENAME TABLE internet_log TO internet_log_" . $year . "_" . $month . ", internet_log_new TO internet_log;",

    "INSERT INTO internet_log(
    uid,
    `start`,
    `tp_id`,
    `duration`,
    `sent`,
    `recv`,
    `sum`,
    `port_id`,
    `nas_id`,
    `ip`,
    `sent2`,
    `recv2`,
    `acct_session_id`,
    `cid`,
    `bill_id`,
    `terminate_cause`,
    `framed_ipv6_prefix`,
    `acct_input_gigawords`,
    `acct_output_gigawords`,
    `ex_input_octets_gigawords`,
    `ex_output_octets_gigawords`
  )
  SELECT uid,
    MAX(`start`),
    `tp_id`,
    SUM(`duration`),
    SUM(`sent`),
    SUM(`recv`),
    SUM(`sum`),
    `port_id`,
    `nas_id`,
    `ip`,
    SUM(`sent2`),
    SUM(`recv2`),
    `acct_session_id`,
    `cid`,
    `bill_id`,
    `terminate_cause`,
    `framed_ipv6_prefix`,
    SUM(`acct_input_gigawords`),
    SUM(`acct_output_gigawords`),
    SUM(`ex_input_octets_gigawords`),
    SUM(`ex_output_octets_gigawords`)
  FROM `internet_log_" . $year . "_" . $month . "`
  WHERE start < DATE_FORMAT(NOW(), '%Y-%m-01 00:00:00')
  GROUP BY uid, DATE_FORMAT(start, '%Y-%m-%d');
  ",

    "INSERT INTO internet_log(
    uid,
    `start`,
    `tp_id`,
    `duration`,
    `sent`,
    `recv`,
    `sum`,
    `port_id`,
    `nas_id`,
    `ip`,
    `sent2`,
    `recv2`,
    `acct_session_id`,
    `cid`,
    `bill_id`,
    `terminate_cause`,
    `framed_ipv6_prefix`,
    `acct_input_gigawords`,
    `acct_output_gigawords`,
    `ex_input_octets_gigawords`,
    `ex_output_octets_gigawords`
  )
  SELECT uid,
    MAX(`start`),
    `tp_id`,
    SUM(`duration`),
    `sent`,
    `recv`,
    `sum`,
    `port_id`,
    `nas_id`,
    `ip`,
    `sent2`,
    `recv2`,
    `acct_session_id`,
    `cid`,
    `bill_id`,
    `terminate_cause`,
    `framed_ipv6_prefix`,
    `acct_input_gigawords`,
    `acct_output_gigawords`,
    `ex_input_octets_gigawords`,
    `ex_output_octets_gigawords`
  FROM `internet_log_" . $year . "_" . $month . "`
  WHERE start > DATE_FORMAT(NOW() - INTERVAL 1 MONTH, '%Y-%m-01 00:00:00');",

  "DELETE FROM `internet_log_" . $year . "_" . $month . "`
  WHERE start >= DATE_FORMAT(NOW(), '%Y-%m-01 00:00:00');";

  foreach my $query (@queries) {
    if($debug > 7) {
      print "$query\n";
    }
    else {
      $Admin->query("$query", 'do');
    }
  }

  return 1;
}

#**********************************************************
=head2 pre_month()

  Arguments:
    $attr
      DATE

  Return:
    $result

=cut
#**********************************************************
sub pre_month {
  my ($attr) = @_;

  my ($year, $month) = split(/\-/, $attr->{DATE});

  $month--;

  if ($month < 1) {
    $year--;
    $month=12;
  }

  return $year . "-" . sprintf("%02d", $month);
}

1;