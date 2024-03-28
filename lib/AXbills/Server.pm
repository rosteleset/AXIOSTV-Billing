package AXbills::Server;

=head1 NAME

AXbills::Server - Base server functions

=head1 SYNOPSIS

    use AXbills::Server;

=cut

no if $] >= 5.017011, warnings => 'experimental::smartmatch';

use strict;
our $VERSION = 2.00;
use POSIX qw(locale_h);
use parent 'Exporter';

our @EXPORT = qw(
  make_pid
  verify_pid
  daemonize
  stop_server
  is_running
);

our @EXPORT_OK = qw(
  make_pid
  verify_pid
  daemonize
  stop_server
);


#**********************************************************
=head2 make_pid($pid_file, $attr) - Check running program by px

  Arguments:
    $pid_file  - PID file
    $attr      - 
       clean   - Clean PID file

  Returns:
    boolean

=cut
#**********************************************************
sub make_pid {
  my ($pid_file, $attr) = @_;

  if (!$pid_file) {
    $pid_file = _get_pid_filename($attr);
  }

  if ($attr && $attr eq 'clean') {
    unlink($pid_file);
    return 0;
  }

  if (-f $pid_file) {
    my $pid = _read_pid($pid_file);
    if (verify_pid($pid)) {
      print "Process running, PID: $pid\n";
      return 1;
    }
  }

  my $pid_name = $$;
  open(my $ph, '>', "$pid_file") || die "Can't write pid file '$pid_file' $!\n";
  print $ph $pid_name;
  close($ph);

  return 0;
}

#**********************************************************
=head verify_pid($pid) -  Check running program

  Arguments:
    $pid     -   PID file

  Returns:
    TRUE or FALSE

=cut
#**********************************************************
sub verify_pid {
  my ($pid) = @_;

  return 0 if (!$pid);

  #my $me = $$;

  my @ps = split m|$/|, qx/ps -fp $pid/
    || die "ps utility not available: $!";
  s/^\s+// for (@ps); # leading spaces confuse us

  no warnings; # hate that deprecated @_ thing
  my $n = split(/\s+/, $ps[0]);
  @ps = split /\s+/, $ps[1], $n;

  return ($ps[0]) ? 1 : 0;
}

#**********************************************************
=head2 daemonize($attr) - Demonize proccess

  Arguments: 
    $attr
      PROGRAM_NAME -  Program name
      LOG_DIR      -  logdir for pid  Default: /usr/axbills/var/log/

  Returns:

=cut
#**********************************************************
sub daemonize {
  my ($attr) = @_;

  chdir '/';
  umask 0;

  my $pid_file = _get_pid_filename($attr);

  #Save old out
  my $SAVEOUT;
  open($SAVEOUT, '>&', \*STDOUT) or die "Save STDOUT error: $!";

  #Reset out
  open STDIN, '>', '/dev/null';
  open STDOUT, '>', '/dev/null';
  open STDERR, '>', '/dev/null';
  if (fork()) {
    exit;
  }
  else {
    #setsid;
    if (make_pid($pid_file) == 1) {
      #Close new out
      close(STDOUT);

      #Open old out
      open(STDOUT, ">&", $SAVEOUT);
      print "Already running!\n";
      exit;
    }
    return $pid_file;
  }
}

#**********************************************************
=head2 stop_server($pid_file, $attr) = @_;

  Argumenst:
    $pid_file - PID file
    $attr     - Extra arguments

  Returns;
    TRUE or FALSE

=cut
#**********************************************************
sub stop_server {
  my ($pid_file, $attr) = @_;

  if (!$pid_file) {
    $pid_file = _get_pid_filename($attr);
  }

  my $res = `kill \`cat $pid_file\``;

  if ($attr->{DEBUG}) {
    print "Res: $res\n";
  }

  return 1;
}

#**********************************************************
=head2 is_running($attr)

  Arguments:
    $attr - hash_ref
      PID_FILE     - PID file
        or
      LOG_DIR      - PID dir ( obviously :) )
      PROGRAM_NAME - name for PID file
      
  Returns:
    boolean
    
=cut
#**********************************************************
sub is_running {
  my ($attr) = @_;

  my $pid_file = $attr->{PID_FILE} || _get_pid_filename($attr);

  my $pid = _read_pid($pid_file);

  # verify_pid() returns inverted boolean value
  return !verify_pid($pid)
}

#**********************************************************
=head2 _get_pid_filename($attr) = @_;

  Argumenst:
    $attr     - Extra arguments

  Returns;
    PID file name

=cut
#**********************************************************
sub _get_pid_filename {
  my ($attr) = @_;

  my $program_name = $0;

  if ($attr->{PROGRAM_NAME}) {
    $program_name = $attr->{PROGRAM_NAME};
  }
  else {
    if ($program_name =~ /\/?([a-zA-Z\.\_\-]+)$/) {
      $program_name = $1;
    }
    $program_name =~ s/\.[a-zA-Z0-9]+$//;
  }

  my $log_dir = $attr->{LOG_DIR} || '/usr/axbills/var/log/';
  my $pid_file = $log_dir . '/' . $program_name . '.pid';

  return $pid_file;
}

#**********************************************************
=head2 _read_pid($pid_file)

=cut
#**********************************************************
sub _read_pid {
  my ($pid_file) = @_;

  open(my $ph, '<', "$pid_file") || die "Can't open pid file '$pid_file' $!\n";
  my @pids = <$ph>;
  close($ph);

  return $pids[0];
}

=head1 AUTHOR

АСР AXbills - https://billing.axiostv.ru

=cut

1;
