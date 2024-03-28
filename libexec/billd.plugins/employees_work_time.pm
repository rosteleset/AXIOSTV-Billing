# billd plugin

=head1


=cut

#**********************************************************
use Employees;
use AXbills::Base;

# use Data::Dumper;
my $version = 0.01;
my $Employees = Employees->new($db, $admin, \%conf);    # connect Ring module

employees_work_time();
#**********************************************************
=head2 employees_work_time() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub employees_work_time {
  my ($attr) = @_;

  my $date = $attr->{DATE} || $DATE;

  my $rfid_log = $Employees->rfid_log_list({
    COLS_NAME => 1,
    DATETIME  => '_SHOW',
    # RFID      => '_SHOW',
    AID       => '_SHOW',
    ADMIN     => '_SHOW',
    SORT      => 'datetime',
    DESC      => 'desc',
    DATE      => $date,
  });
  
  my %admins_times;

  foreach my $each_admin_rfid_log (@$rfid_log){
    push (@ {$admins_times{$each_admin_rfid_log->{admin}}}, $each_admin_rfid_log->{datetime});
  }

  my $time_report = sprintf ('| %*s | %*s | %*s | %*s |',
       -20, 'admin', 
       -20, 'start time', 
        -20, 'end_time',
        -20, 'total time',
       ) . "\n";

  foreach my $key (keys %admins_times){

      my $start      = $admins_times{$key}[0];
      my $end        = "No time";
      my $total_time = "No time";

      if((scalar @{$admins_times{$key}} - 1) > 0){
        $end   = ($admins_times{$key}[scalar @{$admins_times{$key}} - 1] || '');
        my (undef, $start_time) = split(' ',$start);
        my (undef, $end_time) = split(' ',$end);
        my $start_time_in_sec = time2sec($start_time);
        my $end_time_in_sec = time2sec($end_time);
        # print "$end_time_in_sec - $start_time_in_sec\n";
        my $time_on_work_in_sec = $end_time_in_sec - $start_time_in_sec;
  
        my ($seconds, $minutes, $hours, undef) = sec2time($time_on_work_in_sec);
        $total_time = $hours . "h " . $minutes ."m " . $seconds ."s";
      }

      $time_report .= sprintf ('| %*s | %*s | %*s | %*s |',
       -20, $key, 
       -20, $start, 
        -20, $end,
        -20, $total_time,
       ) . "\n";
      # $time_report .= "| $start\t";
      # $time_report .= "| $end\t";
      # $time_report .= "| $total_time\t|\n";
      
  }

  print $time_report;
  sendmail("$conf{ADMIN_MAIL}", "$conf{ADMIN_MAIL}", "Rfid log report", "<pre>$time_report</pre>", "$conf{MAIL_CHARSET}", "2 (High)", {CONTENT_TYPE => 'text/html'});

  return 1;
}