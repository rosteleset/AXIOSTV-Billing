=head1 NAME

  send reports to e-mail

  Arguments:

   REPORTS=1,2,3 

=cut

use strict;
use warnings "all";
use AXbills::Base qw(_bp sendmail);
use Reports;


our (
  $db,
  %conf,
  $argv,
  $debug,
  $var_dir,
  %lang,
  $Reports,
);

our Admins $Admin;

$Admin->info($conf{SYSTEM_ADMIN_ID}, { IP => '127.0.0.1' });
$Reports = Reports->new($db, $Admin, \%conf);

if ($argv->{REPORTS}) {
  send_mail_reports($argv->{REPORTS});
}
else {
  send_mail_reports(get_reports_id());
}

#**********************************************************
=head2 send_reports()

=cut
#**********************************************************
sub send_mail_reports {
  my ($report_ids) = @_;
  my @reports_id = split(',', $report_ids);

  foreach my $report_id (@reports_id) {
    my $output = form_report($report_id);
    # send_mail_report($output);
  }
  return 1;  
}

#**********************************************************
=head2 form_report()

=cut
#**********************************************************
sub form_report {
  my ($report_id) = @_;
  $Reports->info({ ID => $report_id });
  require "Rwizard/webinterface";
  Rwizard::webinterface->import();
  _make_report_query();
  my ($col_names, $titles, $cols_params) = _read_titles($Reports->{FIELDS});
  my $list = $Reports->mk({
    QUERY       => $Reports->{QUERY},
    QUERY_TOTAL => $Reports->{QUERY_TOTAL},
    COLS_NAME   => 1
  });
  my $table = _make_report_table($col_names, $titles, $cols_params, $list);
  print $table;

  return $table;
}

#**********************************************************
=head2 send_mail_report()

=cut
#**********************************************************
sub send_mail_report {
  my ($message) = @_;
  sendmail("$conf{ADMIN_MAIL}", "$conf{ADMIN_MAIL}", "Report", "$message", "", "", {TEST => 0});

  return 1;
}

#**********************************************************
=head2 send_mail_reports_help()

=cut
#**********************************************************
sub send_mail_reports_help {
  print "billd send_reports REPORTS='1,2,3'\n";
  return 1;
}

#**********************************************************
=head2 get_reports_id()

=cut
#**********************************************************
sub get_reports_id {
  my @reports_arr = ();
  my $list = $Reports->list({ SEND_MAIL => 1, COLS_NAME => 1 });
  foreach my $line (@$list) {
    push (@reports_arr, $line->{id});
  }

  return join(',', @reports_arr);
}

1;