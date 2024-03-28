=head1 NAME

  Secure

  VERSION: 1
  DATETIME: 20230208

=cut

use strict;
use warnings FATAL => 'all';

our (
  %conf,
  $base_dir,
  $lib_path,
  $DATE
);

secure_log();

#**********************************************************
=head2 secure_log()

=cut
#**********************************************************
sub secure_log {

  if (!$conf{APACHE_LOGS}) {
    print "Error. Please add logs paths with ';' to \$conf{APACHE_LOGS} in config.pl \n";
    return 0;
  }

  my $search_parameters = '';
  if (open(my $params, '<', $lib_path.'secure.txt')) {
    while (my $line = <$params>) {
      $search_parameters .= $line;
    };
    close($params);
  }
  my @search_parameters = split(/\n/, $search_parameters);

  if (!@search_parameters) {
    print "Error. Please add search parameters to libexec/secure.txt \n";
    return 0;
  }

  $conf{APACHE_LOGS} =~ s/ //g;
  my @logfiles = split(/;\s?/, $conf{APACHE_LOGS});

  my $content = '';

  foreach my $logfile (@logfiles) {
    foreach my $parameter (@search_parameters) {
      if (open(my $fh, '-|', "grep -i $parameter $logfile")) {
        while (my $line = <$fh>) {
          my $change = "\033[1m$parameter\033[0m";
          $line =~ s/$parameter/$change/g;
          $content .= $line;
        };
        close($fh);
      }
    }
  }

  print $content;

  if ($content){
    open(my $fh_close, '>>', '/var/log/apache2/secure.log') or die $!;
    print $fh_close $content . "\n";
    close($fh_close);
  }

  return 1;
}