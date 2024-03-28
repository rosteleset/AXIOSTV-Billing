#!/usr/bin/perl -w

=head1 NAME

  Leases to DB

=cut


use strict;
use warnings;

our (%conf, %log_levels, $DATE, $var_dir);

BEGIN {
  use FindBin '$Bin';
  require $Bin.'/config.pl';
  unshift(@INC, $Bin.'/../', $Bin.'/../lib/', $Bin."/../AXbills/$conf{dbtype}");
}

use AXbills::Base qw(parse_arguments check_time);
use POSIX qw(strftime);
use AXbills::SQL;
use Admins;
use Dhcphosts;
use Nas;

my $vesion = 0.7;
my $begin_time = check_time();
my $argv = parse_arguments(\@ARGV);
my $log_dir = $var_dir . '/log';

my $LEASES      = $argv->{LEASES}      || $conf{DHCPHOSTS_LEASES} || "/var/db/dhcpd/dhcpd.leases";
my $UPDATE_TIME = $argv->{UPDATE_TIME} || 30;                                                        # In Seconds
my $AUTO_VERIFY = 0;
my $debug       = $argv->{DEBUG}       || 3;
my $logfile     = $argv->{LOG_FILE}    || $log_dir . '/leases2db.log';

my $oldstat     = 0;
my $check_count = 0;
my $NAS_ID      = $argv->{NAS_ID} || 0;
my %state_hash  = (
  'unknown'   => 0,
  'free'      => 1,
  'active'    => 2,
  'abandoned' => 3
);

if (defined($argv->{stop})) {
  stop($log_dir . "/leases2db.pid");
  exit;
}
elsif (defined($argv->{'help'})) {
  usage();
  exit;
}

#**********************************************************
# log_print local function
#**********************************************************
sub mk_log {
  my ($type, $message) = @_;

  %log_levels = (
    'LOG_EMERG'   => 0,
    'LOG_ALERT'   => 1,
    'LOG_CRIT'    => 2,
    'LOG_ERR'     => 3,
    'LOG_WARNING' => 4,
    'LOG_NOTICE'  => 5,
    'LOG_INFO'    => 6,
    'LOG_DEBUG'   => 7,
    'LOG_SQL'     => 8
  );

  if ($debug < $log_levels{$type}) {
    return 0;
  }

  my $DATETIME = strftime "%Y-%m-%d %H:%M:%S", localtime(time);
  if ($argv->{LOG_FILE} || defined($argv->{'-d'})) {
    open(my $fh, '>>', $logfile) || die "Can't open file '$logfile' $!\n";
      print $fh "$DATETIME $type: $message\n";
    close($fh);
  }
  else {
    print "$DATETIME $message\n";
  }
}

print "Start... debug: $debug\n";
if (defined($argv->{'-d'})) {
  mk_log('LOG_EMERG', "leases2db.pl Daemonize...");
  daemonize();
}
else {
  if (make_pid($log_dir . "/leases2db.pid") == 1) {
    print "Already running PID: !\n";
    exit;
  }
}

while (1) {
  if (changed($LEASES)) {
    my $list = parse($LEASES);
    leases2db($list);
  }

  sleep $UPDATE_TIME;
}

#**********************************************************
# Check file change
#**********************************************************
sub changed {
  my ($file) = @_;

  if (! -f $LEASES) {
    mk_log('LOG_ERR', "Can't find leases file '$LEASES'.\n");
    exit;
  }
  my $custat = (stat($file))[9];

  if ($AUTO_VERIFY) {
    $check_count++;
  }

  $begin_time = check_time();
  if ($oldstat != $custat || (($check_count == $AUTO_VERIFY) && $AUTO_VERIFY)) {
    mk_log('LOG_DEBUG', "Leases stat - old: $oldstat cur: $custat");

    $oldstat     = $custat;
    $check_count = 0;

    mk_log('LOG_INFO', 'Timestamp change o AUTO_VERIFY tiggeed...');

    return 1;
  }
  else {
    return 0;
  }
}

#**********************************************************
#
#**********************************************************
sub daemonize {
  chdir '/';
  umask 0;

  #Save old out
  my $SAVEOUT;
  open($SAVEOUT, ">&", STDOUT) or die "XXXX: $!";

  #Reset out
  open STDIN,  '/dev/null';
  open STDOUT, '/dev/null';
  open STDERR, '/dev/null';

  if (fork()) {
    exit;
  }
  else {
    #setsid;
    if (make_pid($log_dir . "/leases2db.pid") == 1) {

      #Close new out
      close(STDOUT);

      #Open old out
      open(STDOUT, ">&", $SAVEOUT);
      print "Already running!\n";
      exit;
    }
    return;
  }
}

#**********************************************************
=head2 parse($logfile)

=cut
#**********************************************************
sub parse {
  my ($logfile) = @_;
  my (%list, $ip);

  mk_log('LOG_DEBUG', "Begin parse '$logfile'");

  open(my $fh, '<', $logfile) || print "Can't read file '$logfile' $!\n";

  my $state = '';
  while (<$fh>) {
    next if /^#|^$/;

    if (/^lease (\d+\.\d+\.\d+\.\d+)/) {
      $ip = $1;
      $list{$ip}{IP} = $ip;
    }

    # $list{$ip}{state} ne 'active' &&
    elsif (/^\s*binding state ([a-zA-Z]{4,6});/) {
      $state = $1;
      $list{$ip}{STATE} = $state_hash{$state} if ($state eq 'active');
    }
    elsif (/^\s*client-hostname "(.*)";/) {
      $list{$ip}{'HOSTNAME'} = $1;
    }
    elsif (/^\s*hardware ethernet (.*);/) {
      $list{$ip}{HARDWARE} = $1;
    }

    /^\s*starts \d (\d{4})\/(\d{1,2})\/(\d{1,2}) (\d{1,2}):(\d{1,2}):(\d{1,2});/ && ($list{$ip}{STARTS}     = "$1-$2-$3 $4:$5:$6");
    /^\s*next binding state (.*);/                                               && ($list{$ip}{NEXT_STATE} = $state_hash{$1});
    /^\s*ends \d (\d{4})\/(\d{1,2})\/(\d{1,2}) (\d{1,2}):(\d{1,2}):(\d{1,2});/   && ($list{$ip}{ENDS}       = "$1-$2-$3 $4:$5:$6");
    /^\s*(abandoned).*/                                                          && ($list{$ip}{abandoned}  = $1);
    /^\s*option agent.circuit-id ([a-f0-9:]+);/                                  && ($list{$ip}{CIRCUIT_ID} = $1);
    /^\s*option agent.remote-id ([a-f0-9:]+);/                                   && ($list{$ip}{REMOTE_ID}  = $1);
  }

  close($fh);

  return \%list;
}

#**********************************************************
=head2 leases2db($list) - Add to db

=cut
#**********************************************************
sub leases2db {
  my ($list) = @_;

  my $db = AXbills::SQL->connect($conf{dbtype}, $conf{dbhost}, $conf{dbname},
   $conf{dbuser},
   $conf{dbpasswd},
   { %conf });
  my %nas_macs = ();

  my $Dhcphosts = Dhcphosts->new($db, undef, \%conf);
  $Dhcphosts->{debug} = 1 if ($debug > 7);

  my $Nas = Nas->new($db, \%conf, undef);
  $Nas->{debug} = 1 if ($debug > 7);

  my $list2 = $Nas->list({ PAGE_ROWS  => 1,
                           MAC        => '*',
                           COLS_NAME  => 1, });

  foreach my $line (@$list2) {
    $nas_macs{$line->{mac}}=$line->{nas_id};
  }

  $Dhcphosts->leases_clear();
  if ($Dhcphosts->{errno}) {
    mk_log('LOG_ERR', "SQL error: " . $Dhcphosts->{errstr});
    return 0;
  }

  my $i          = 0;
  my $parse_info = '';
  if ($debug > 15) {
    while (my ($ip, $hash) = each(%$list)) {
      $i++;
      if ($debug > 5) {
        $parse_info .= "$ip\n";
        while (my ($k, $v) = each %{$hash}) {
          $parse_info .= "  $k, $v\n";
        }
      }
    }
  }

  $Dhcphosts->leases_update({ LEASES_HASH => $list, NAS_ID => $NAS_ID });
  my $error = '';

  if ($Dhcphosts->{errno}) {
    $error = "[$Dhcphosts->{errno}] $Dhcphosts->{errstr}";
  }

#	2	12	���	0	1:11:42:43:2d:46:36:2d:38	0:4:0:c:0:2
  mk_log('LOG_INFO', "$parse_info $error");

  my $GT = '';
  if ($begin_time > 0) {
    Time::HiRes->import(qw(gettimeofday));
    my $end_time = Time::HiRes::gettimeofday();
    my $gen_time = $end_time - $begin_time;
    $GT = sprintf(" (GT: %2.5f)", $gen_time);
  }

  mk_log('LOG_NOTICE', "Updated: $i leases $GT");

  return 1;
}

#**********************************************************
# help
#**********************************************************
sub usage {
  print <<EOF;
dhcp2ldapd v$vesion: Dynamic DNS Updates fo the Bind9 LDAP backend

Usage:
	leases2db [-d | help | ...]

-d              Runs dhcp2db in daemon mode
help            displays this help message
LOG_FILE=...    make log file
LEASES=...      lease files
UPDATE_TIME=... Update peiod (Default: 30)
DEBUG=...       Debug mode 1-7 (Default: 3)
NAS_ID=         NAS ID (Default: 0)

Please edit the config vaiables befoe unning!

EOF
}

#**********************************************************
# Stop
#**********************************************************
sub stop {
  my ($pid_file, $attr) = @_;

  `kill \`cat $pid_file\``;
}

#**********************************************************
# Check running program
#**********************************************************
sub make_pid {
  my ($pid_file, $attr) = @_;

  if ($attr && $attr eq 'clean') {
    unlink($pid_file);
    return 0;
  }

  if (-f $pid_file) {
    open(PIDFILE, "$pid_file") || die "Can't open pid file '$pid_file' $!\n";
    my @pids = <PIDFILE>;
    close(PIDFILE);

    my $pid = $pids[0];
    if (verify($pid)) {
      print "Process running, PID: $pid\n";
      return 1;
    }
  }

  my $self_pid = $$;
  open(PIDFILE, ">$pid_file") || die "Can't open pid file '$pid_file' $!\n";
  print PIDFILE $self_pid;
  close(PIDFILE);

  return 0;
}

#**********************************************************
# Check running program
#**********************************************************
sub verify {
  my ($pid) = @_;

  return 0 if ($pid eq '');

  my $me = $$;    # = $self->{verify};

  my @ps = split m|$/|, qx/ps -fp $pid/
  || die "ps utility not available: $!";
  s/^\s+// for @ps;    # leading spaces confuse us

  no warnings;         # hate that deprecated @_ thing
  my $n = split(/\s+/, $ps[0]);
  @ps = split /\s+/, $ps[1], $n;

  return ($ps[0]) ? 1 : 0;
}

1
