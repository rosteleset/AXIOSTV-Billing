#!/usr/bin/perl

=head1 NAME

   IPoE Shapper

=head1 VERSION

  VERSION: 0.31
  UPDATE: 20171225

=cut
#**********************************************************


use strict;
our (
  %conf,
  %log_levels,
  $DATE,
  $var_dir,
  @MODULES
);

BEGIN {
  use FindBin '$Bin';
  require $Bin . '/config.pl';
  unshift(@INC,
    $Bin . '/../AXbills/',
    $Bin . "/../AXbills/$conf{dbtype}",
    $Bin . '/../lib/');
}

our $VERSION = 0.31;

use POSIX qw(strftime);
use AXbills::Base qw(check_time parse_arguments ip2int cmd in_array);
use AXbills::Server;
use AXbills::SQL;
use Admins;
use Dhcphosts;
use Log qw(log_add);

#my $begin_time = check_time();
my $fw_guest_table = 32;

my $argv = parse_arguments(\@ARGV);

my $prog_name = $0;
if ($prog_name =~ /\/?([a-zA-Z\.\_\-]+)$/) {
  $prog_name = $1;
}

my $prog_name_short = $prog_name;
$prog_name_short =~ s/\.[a-zA-Z0-9]+$//;

my $log_dir = $var_dir . '/log';

my $UPDATE_TIME = $argv->{UPDATE_TIME} || 10;                                        # In Seconds
#my $AUTO_VERIFY = 0;
my $debug       = $argv->{DEBUG} || 3;
my $logfile     = $argv->{LOG_FILE} || $log_dir . '/' . $prog_name_short . '.log';

#my $oldstat     = 0;
#my $check_count = 0;
#my $NAS_ID      = $argv->{NAS_IDS} || 0;
my $check_time  = ($argv->{RECONFIG_PERIOD}) ? time - $argv->{RECONFIG_PERIOD} : 0;

my @START_FW = (5000, 3000, 1000);

if ($conf{FW_START_RULES}) {
	@START_FW = split(/,\s?/, $conf{FW_START_RULES});
}

my $BIT_MASK='32';
my $users_table_number = $conf{FW_TABLE_USERS} || 10;
my $IPFW   = '/sbin/ipfw';

my $Log          = Log->new(undef, \%conf);
$Log->{LOG_FILE} = $logfile;

if (! $argv->{LOG_FILE} && ! defined($argv->{'-d'})) {
  $Log->{PRINT} = 1;
}

print "Start... debug: $debug\n" if ($debug);

if (defined($argv->{'-d'})) {
  my $pid_file = daemonize();
  $Log->log_print('LOG_EMERG', '', "$prog_name Daemonize... $pid_file");
}
elsif (defined($argv->{stop})) {
  stop_server();
  exit;
}
elsif (defined($argv->{'help'})) {
  usage();
  exit;
}
elsif (make_pid() == 1) {
  exit;
}

if ($conf{DV_TURBO_MODE}) {
  require Turbo;
  Turbo->import();
}

my $all = 1;
my $TP_TRAFFIC_CLASSES = get_tp_classes();
my $Turbo;

while (1) {
  check_activity({ ALL => ($argv->{RECONFIG_PERIOD}) ? undef : $all });
  $all = 0;
  sleep $UPDATE_TIME;
}


#**********************************************************
=head2 get_tp_classes

=cut
#**********************************************************
sub get_tp_classes {

  my $db = db_connect();
  my %TP_TRAFFIC_CLASSES = ();


  my $Dhcphosts = Dhcphosts->new($db, undef, \%conf);
  # Get tp traffic classe
  $Dhcphosts->query("SELECT tp.tp_id, COUNT(DISTINCT tt.id) AS classes_count FROM
     tarif_plans tp
     INNER JOIN intervals i ON (i.tp_id=tp.tp_id)
     INNER JOIN trafic_tarifs tt ON (tt.interval_id=i.id)
     WHERE tp.module='Dv'
     GROUP BY tp.tp_id", undef, { COLS_NAME => 1 });

  foreach my $tp (@{ $Dhcphosts->{list} }) {
  	$TP_TRAFFIC_CLASSES{$tp->{tp_id}}=$tp->{classes_count};
  }

  return \%TP_TRAFFIC_CLASSES;
}

#**********************************************************
=head2 db_connect()

=cut
#**********************************************************
sub db_connect {

  return AXbills::SQL->connect($conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd});
}

#**********************************************************
=head2 check_activity($attr)

=cut
#**********************************************************
sub check_activity {
  my ($attr) = @_;

  my $db = db_connect();

  my $Dhcphosts = Dhcphosts->new($db, undef, \%conf);

  my $period = $UPDATE_TIME;
  if ($check_time > 0 && time - $check_time > $UPDATE_TIME) {
    $period = time - $check_time;
  }
  $Log->{db}=$db;
  $Log->log_print('LOG_DEBUG', '', "Start check online period: $period");

  $check_time = time;
  my $WHERE = '';
  if ($argv->{NAS_IDS}) {
    $WHERE = ' AND ' . join(' or ', @{  $Dhcphosts->search_expr($argv->{NAS_IDS}, 'INT', 'c.nas_id') });
  }
  if (!$attr->{ALL}) {
    $WHERE .= " AND UNIX_TIMESTAMP() - UNIX_TIMESTAMP(started) <= $period";
  }

  my $internet_tables = q{    FROM dv_calls c
    LEFT JOIN dv_main dv  ON (dv.uid=c.uid)
    LEFT JOIN tarif_plans tp  ON (tp.id=dv.tp_id AND tp.module='Dv')
  };

  if(in_array('Internet', \@MODULES)) {
    $internet_tables = q{    FROM internet_online c
      LEFT JOIN internet_main dv  ON (dv.uid=c.uid)
      LEFT JOIN tarif_plans tp  ON (tp.tp_id=dv.tp_id)
    };
  }

  my $sql = "SELECT c.user_name,
    UNIX_TIMESTAMP() - UNIX_TIMESTAMP(c.started) AS duration,
    tp.tp_id,
    INET_NTOA(c.framed_ip_address) AS ip,
    '255.255.255.255',
    c.status,
    c.nas_port_id,
    c.nas_id,
    c.uid,
    n.ip as nas_ip,
    n.nas_type,
    n.mng_host_port,
    n.mng_user,
    DECODE(n.mng_password, '$conf{secretkey}') AS mng_password,
    IF(dv.filter_id<>'', dv.filter_id, tp.filter_id) AS filter_id,
    INET_NTOA(dv.netmask) AS netmask,
    c.guest
    $internet_tables
    INNER JOIN nas n ON (n.id=c.nas_id)
    WHERE (status=1 OR status=3 OR status=10) $WHERE; ";

  if ($debug > 7) {
  	$Log->log_print('LOG_SQL', '', $sql);
  }

  $Dhcphosts->query($sql,
    undef,
    { COLS_NAME => 1 }
  );

  my $fw_step   = 1000;

  foreach my $line (@{ $Dhcphosts->{list} }) {
    my $tp_id = $line->{tp_id};
    my $ip    = $line->{ip};

    if ($ip eq '0.0.0.0') {
      $Log->log_print('LOG_EMERG', $line->{user_name}, "Duration: $line->{duration} TP: $tp_id IP: $ip Status: $line->{status} Wrong ip");
      next;
    }

    my $TRAFFIC_CLASSES = $TP_TRAFFIC_CLASSES->{$tp_id} || 1;

    $Log->log_print('LOG_INFO', $line->{user_name}, "Duration: $line->{duration} TP: $tp_id IP: $ip Status: $line->{status} TC: $TRAFFIC_CLASSES Guest: ". $line->{guest});
    my $cmd = '';

    if ($line->{netmask} ne '32') {
      my $ips = 4294967296 - ip2int($line->{netmask});
      $line->{netmask} = 32 - length(sprintf("%b", $ips)) + 1;
    }

    if (defined($argv->{IPN_SHAPPER})) {
    	$cmd = $conf{IPN_FW_START_RULE};
      $cmd =~ s/\%IP/$line->{ip}/g;
      $cmd =~ s/\%MASK/$line->{netmask}/g;
      #$cmd =~ s/\%NUM/$rule_num/g;
      #$cmd =~ s/\%SPEED_IN/$speed_in/g if ($speed_in > 0);
      #$cmd =~ s/\%SPEED_OUT/$speed_out/g if ($speed_out > 0);
      $cmd =~ s/\%LOGIN/$line->{user_name}/g;
      $cmd =~ s/\%PORT/$line->{nas_port_id}/g;
      $cmd =~ s/\%DEBUG/$line->{filter_id}/g;
      $cmd =~ s/\%STATUS/ONLINE_ENABLE/g;

      if ($line->{filter_id} && $conf{IPN_FILTER}) {
      	my $f_cmd = $conf{IPN_FILTER};
        $f_cmd =~ s/\%STATUS/ONLINE_ENABLE/g;
        $f_cmd =~ s/\%IP/$line->{ip}/g;
        $f_cmd =~ s/\%MASK/$line->{netmask}/g;
        #$cmd =~ s/\%NUM/$rule_num/g;
        #$cmd =~ s/\%SPEED_IN/$speed_in/g if ($speed_in > 0);
        #$cmd =~ s/\%SPEED_OUT/$speed_out/g if ($speed_out > 0);
        $f_cmd =~ s/\%LOGIN/$line->{user_name}/g;
        $f_cmd =~ s/\%PORT/$line->{nas_port_id}/g;
        $f_cmd =~ s/\%FILTER_ID/$line->{filter_id}/g;
        $f_cmd =~ s/\%DEBUG//g;
        $cmd .= "; $f_cmd";
      }

      $ENV{NAS_IP_ADDRESS}  = $line->{nas_ip};
      $ENV{NAS_MNG_USER}    = $line->{mng_user};
      $ENV{NAS_MNG_PASSWORD}= $line->{mng_password};
      $ENV{NAS_MNG_IP_PORT} = $line->{mng_host_port};
      $ENV{NAS_ID}          = $line->{nas_id};
      $ENV{NAS_TYPE}        = $line->{nas_type} || '';
    }
    else {
    	
   	  if ($conf{DV_TURBO_MODE}) {
        $Turbo = Turbo->new($db, undef, \%conf);
        $Turbo->list(
        {
         UID    => $line->{UID},
         ACTIVE => 1,
        }
        );
      }

      if ($Turbo && $Turbo->{TOTAL} > 0) {
        my $SPEED = $Turbo->{list}->[0]->[5];
        my $table_class = "1$SPEED";

        if ($SPEED >= 100000) {
          $table_class = $SPEED / 10 + 1;
        }
        elsif ($SPEED >= 50000) {
          $table_class = '1' . $SPEED / 10;
        }
        elsif ($SPEED >= 10000) {
          $table_class = $SPEED;
        }

        $cmd = "$IPFW table $users_table_number add $ip/$BIT_MASK $table_class;".
               "$IPFW table " . ($users_table_number + 1) . " add $ip/$BIT_MASK $table_class";
      }
    	else {
        for (my $traf_type = 0;$traf_type < $TRAFFIC_CLASSES; $traf_type++) {
          if($line->{guest}) {
            $cmd = "$IPFW -q table ".(10 + $traf_type * 2)." delete $ip; ";
            $cmd .= "$IPFW -q table ".(11 + $traf_type * 2)." delete $ip; ";
            $cmd .= "$IPFW -q table $fw_guest_table add $ip;";
          }
          else {
            my $pipe_rule_in = int($START_FW[$traf_type] + $tp_id);
            my $pipe_rule_out = int($START_FW[$traf_type] + $fw_step + $tp_id);

            $cmd = " $IPFW -q table $fw_guest_table delete $ip; "
              . " $IPFW -q table ".(10 + $traf_type * 2)." delete $ip; "
              . " $IPFW table ".(10 + $traf_type * 2)." add $ip $pipe_rule_in;"
              . " $IPFW -q table ".(11 + $traf_type * 2)." delete $ip; "
              . " $IPFW table ".(11 + $traf_type * 2)." add $ip $pipe_rule_out";
          }
        }
      }
    }

    $Log->log_print('LOG_DEBUG', '', $cmd);

    cmd($cmd);
  }
}

#**********************************************************
# help
#**********************************************************
sub usage {
  print <<EOF;
 ipoe_shapper v$VERSION: Dynamic shapper update for IPoE modules

Usage:
	$prog_name [-d | help | ...]

-d              Runs dhcp2db in daemon mode
help            displays this help message
LOG_FILE=...    make log file
UPDATE_TIME=... Update peiod (Default: 10)
RECONFIG_PERIOD=Reconfigure only last RECONFIG_PERIOD seconds
DEBUG=...       Debug mode 1-7 (Default: 3)
NAS_IDS=        NAS ID (Default: 0)
IPN_SHAPPER     Enable IPN shapper rules

Please edit the config vaiables befoe unning!

EOF
}


1
