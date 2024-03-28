=head1 NAME

  Events checks

=cut

use strict;
use warnings FATAL => 'all';

our (
  %conf,
  $DATE,
  $argv,
  $base_dir
);

BEGIN{
  use FindBin '$Bin';
  my $libpath = "$Bin/../"; # Assuming we are in /usr/axbills/libexec/
  unshift ( @INC, $libpath );
}

use AXbills::Base qw (_bp in_array days_in_month);
require AXbills::Misc;

require "libexec/config.pl";

my $backup_dir = $conf{BACKUP_DIR} || "/usr/axbills/backup/";
$backup_dir =~ s/\/\//\//g;

events_check();

#**********************************************************
=head2 events_check() - entry point

=cut
#**********************************************************
sub events_check{

  check_backups();

  return 1;
}

#**********************************************************
=head2 check_backups() - entry point

=cut
#**********************************************************
sub check_backups{
  my $backup_files = _get_files_in( $backup_dir, {FILTER => '\.gz'});

  # Check if yesterday backup exists
  my $yesterday_date = date_dec( 1, $DATE );


  unless ( in_array( "stats-$yesterday_date.sql.gz", $backup_files ) ){
    generate_new_event( "SYSTEM", '_{YESTERDAY_BACKUP_DOES_NOT_EXISTS}_!' );
  };

  foreach my $backup_file_name ( @{$backup_files} ){
    unless ( check_backup( $backup_file_name ) ){
      generate_new_event( 'SYSTEM', '_{BACKUP_CHECK_FAILS_FOR}_ ' . $backup_file_name );
    };
  }

  return 1;
}

#**********************************************************
=head2 check_backup($filename) - checks backup is correct

  Arguments:
    $filename - path to backup to check

  Returns:
    boolean

=cut
#**********************************************************
sub check_backup{
  my ($filename) = @_;

  my $stats = _stats_for_file($backup_dir . '/' . $filename);

  # 20 is minimum Gzip packed file size;
  return 0 if (!$stats->{size} || $stats->{size} <= 20);
  return 0 if (!`zcat $backup_dir/$filename | tail -1 | grep 'Dump completed'`);
  
  return 1;
}

#**********************************************************
=head2 generate_new_event($name, $message)

  Arguments:
    $name - name for event
    $comments - text of message to show

  Returns:

=cut
#**********************************************************
sub generate_new_event{
  my ($name, $comments) = @_;

  #  print "EVENT: $name, $comments \n";
  print $comments . "\n" if ($argv->{DEBUG});
  
  my $cmd = ($base_dir || '/usr/axbills') . '/misc/events.pl ADD=events'
  ." MODULE='$name' COMMENTS='$comments' STATE_ID=1 PRIORITY_ID=5 OUTPUT=JSON TITLE='_{SYSTEM_NOTIFICATION}_'";
  
  my $add_result = `$cmd`;

  if ( !$add_result || $add_result !~ /"status":0/m ){
    print "Error adding event";
    print $add_result
  }

  return 1;
}

#**********************************************************
=head2 date_dec($num_of_days, $date_string) - decrement date

  Arguments:
    $num_of_days - days to decrement
    $date_string - date in "YYYY-MM-DD" format

  Returns:
    string in "YYYY-MM-DD" format

=cut
#**********************************************************
sub date_dec{
  my ($num_of_days, $date_string) = @_;

  return 0 if ($num_of_days < 0);
  my ($year, $month, $day) = split( "-", $date_string );

  while($num_of_days--){
    $day--;
    if ( $day == 0 ){
      $month--;
      if ( $month == 0 ){
        $year--;
        $month = 12;
      }
      $day = days_in_month( {DATE => "$year-$month-01"} );
    }
  }

  return "$year" . "-" . (length $month < 2 ? '0' : '' ) . $month . "-" . (length $day < 2 ? '0' : '' ) . $day ;
}



1;