#!/usr/bin/perl -w
=head1 NAME

  GPS Server

=head2 FILENAME

  gps_server.pl

=head2 VERSION

  VERSION: 0.2
  REVISION: 20180611

=head2 SYNOPSIS

=cut

use strict;
use warnings;
use Time::Local;
use IO::Socket::INET;

our (
  %conf,
  $DATE,
  $TIME,
);

BEGIN {
  use FindBin '$Bin';

  my $libpath = "$Bin/../";
  require "$libpath/libexec/config.pl";
  unshift(@INC,
    "$libpath/",
    "$libpath/AXbills",
    "$libpath/lib/",
    "$libpath/AXbills/$conf{dbtype}"
  );
}

use Log;
use AXbills::Base qw(parse_arguments);
use AXbills::Server;
use AXbills::SQL;
use GPS;

my $db = AXbills::SQL->connect($conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd});

my $Log = Log->new(undef, \%conf);
my $Gps = GPS->new($db, undef, \%conf);

$| = 1;

my $debug = 1;
my $prog_name = "GPS Tracker Server";

my $ARGS = parse_arguments(\@ARGV);

if (defined($ARGS->{'-d'})) {
  my $pid_file = daemonize();
  $Log->log_print('LOG_EMERG', '', "$prog_name Daemonize... $pid_file");
}
elsif (defined($ARGS->{stop})) {
  stop_server();
  exit;
}
elsif (make_pid() == 1) {
  exit;
}

if (defined($ARGS->{DEBUG})) {
  print "Debug mode on\n";
  $debug = $ARGS->{DEBUG};

  if ($debug >= 7) {$Gps->{debug} = 1};
}

my $port = $ARGS->{PORT} || '8790';

my $log_file = '/tmp/gps_tracker.log';
if (defined $ARGS->{LOG_FILE}) {
  $log_file = $ARGS->{LOG_FILE};
}
$Log->{LOG_FILE} = $log_file;

my $socket = IO::Socket::INET->new(
  LocalHost => '0.0.0.0',
  LocalPort => $port,
  Proto     => 'tcp',
  Listen    => 5,
  Reuse     => 1
);

die "cannot create socket $!\n" unless ($socket);
print "server waiting for client connection on port $port\n";

log_debug(localtime(), "SERVER STARTED", 1);

while (1) {
  # waiting for a new client connection
  my $client_socket = $socket->accept();

  # get information about a newly connected client
  my $client_address = $client_socket->peerhost();
  my $client_port = $client_socket->peerport();
  log_debug("Connection", localtime() . ". Connection from $client_address:$client_port\n", 1);

  # read up to 2048 (max GET length) characters from the connected client
  my $data = "";
  $client_socket->recv($data, 2048);

  log_debug("Raw HTTP", $data, 4);
  my $FORM = define_the_protocol($data);

  if (defined($FORM->{id}) && $FORM->{id} ne '') {
    my $mappings = get_traccar_mappings();
    my $unified_data = unify_data($FORM, $mappings);

    my $response = write_to_db($unified_data, $client_address);

    my $status = $response && $response eq 'OK' ? 200 : 406;

    # write response data to the connected client
    $client_socket->send("HTTP/1.1 $status $response\nContent-Length:0\n\n");
  }

  # notify client that response has been sent
  shutdown($client_socket, 1);
}

$socket->close();


#**********************************************************
=head2 get_admin_id_by_tracker_id()

  Arguments:
    $gps_id - GPS id

  Returns:
    Tracked admin

=cut
#**********************************************************
sub get_admin_id_by_tracker_id {
  my ($gps_id) = @_;

  return $Gps->tracked_admin_id_by_imei($gps_id);
}

#**********************************************************
=head2 write_to_db()

  Arguments:
    $attr,
    $ip_address

=cut
#**********************************************************
sub write_to_db {
  my ($attr, $ip_address) = @_;

  log_debug("Client ID", $attr->{GPS_IMEI}, 1);

  my $admin_id = get_admin_id_by_tracker_id($attr->{GPS_IMEI});

  if (!$admin_id) {
    log_debug("WRONG GPS ID", "Administrator with such ID not found. ID is $attr->{GPS_IMEI}", 1);
    write_unregistered({ %$attr, (IP => $ip_address) });
    return "Unregistered IMEI";
  }

  $attr->{AID} = $admin_id;

  $Gps->location_add($attr);

  return "OK";
}

#**********************************************************
=head2 write_unregistered()

  Arguments:
    $attr

  Returns:
    1

=cut
#**********************************************************
sub write_unregistered {
  my ($attr) = @_;

  $Gps->unregistered_trackers_add($attr);

  return 1;
}

#**********************************************************
=head2 parse_http_request()

  Arguments:
    $http_request

  Returns:
    $FORM

=cut
#**********************************************************
sub parse_http_request {
  my ($http_request) = @_;

  my %FORM = ();

  my $buffer = [ split(/\n/, $http_request) ]->[0];
  $buffer =~ s/^.*\?//;
  $buffer =~ s/\s.*$//;

  my @pairs = split(/&/, $buffer);
  $FORM{__BUFFER} = $buffer if ($#pairs > -1);

  foreach my $pair (@pairs) {
    my ($side, $value) = split(/=/, $pair, 2);
    if (defined($value)) {
      $value =~ tr/+/ /;
      $value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
      $value =~ s/<!--(.|\n)*-->//g;
      $value =~ s/<([^>]|\n)*>//g;
    }
    else {
      $value = '';
    }
    $FORM{$side} = $value;
  }

  return \%FORM;
}

#**********************************************************
=head2 parse_tk103_protokol()

  Arguments:
    $ps_data - data of protokol

  Returns:
    $FORM

  Examples:
    0
    27045495314
    BR05
    3553
    27045495314
    180604
    A
    4804.3391N
    02300.8468E
    000.0
    120438
    000.00
    00000000L00000000

=cut
#**********************************************************
sub parse_tk103_protokol {
  my ($ps_data) = @_;

  my $FORM = {};
  my ($ps_dev_id, $subProtocol, $x, $y, $utcDate, $ps_local_date, $ps_x, $ps_x_1, $ps_x_2, $ps_y,
    $ps_y_1, $ps_y_2, $ps_speed) = '';

  $ps_dev_id = substr($ps_data, 2, 11);

  $FORM->{id} = $ps_dev_id;

  $subProtocol = substr($ps_data, 13, 4);

  if ($subProtocol eq 'BP05') {

    $x = substr($ps_data, 39, 9);
    $y = substr($ps_data, 49, 10);

    $utcDate = '20' . substr($ps_data, 32, 2) . '-' . substr($ps_data, 34, 2) . '-' . substr($ps_data, 36, 2) . ' ' .
      substr($ps_data, 65, 2) . ':' . substr($ps_data, 67, 2) . ':' . substr($ps_data, 69, 2);
    $ps_local_date = UTC2LocalString($utcDate);

    $ps_x = int($x * 10000);
    $ps_x_1 = int($ps_x * 0.000001);
    $ps_x_2 = int(($ps_x - $ps_x_1 * 1000000) / 6 * 10);
    $ps_x = $ps_x_1 . '.' . substr("00" . $ps_x_2, -6);

    $ps_y = int($y * 10000);
    $ps_y_1 = int($ps_y * 0.000001);
    $ps_y_2 = int(($ps_y - $ps_y_1 * 1000000) / 6 * 10);
    $ps_y = $ps_y_1 . '.' . substr("00" . $ps_y_2, -6);

    $ps_speed = substr($ps_data, 60, 5);

    $FORM->{lat} = $ps_x;
    $FORM->{lon} = $ps_y;
    my ($year, $mon, $mday, $hour, $min, $sec) = split(/[\s\-\:]+/, $ps_local_date);
    my $time = timelocal($sec, $min, $hour, $mday, $mon - 1, $year);
    $FORM->{timestamp} = $time;
  }

  return $FORM;
}

#**********************************************************
=head2 get_traccar_mappings()

  Arguments:

  Returns:

  Examples:

  This is representation of data got from traccar;
  $VAR1 = {
    'speed' => '0.0',
    'lon' => '25.079458951950073',
    'batt' => '48.0',
    'lat' => '48.569440841674805',
    'altitude' => '354.0',
    'bearing' => '8.0859375',
    'id' => '617323',
    'timestamp' => '1452233539'
  };

=cut
#**********************************************************
sub get_traccar_mappings {

  return {
    'GPS_IMEI' => 'id',
    'GPS_TIME' => 'timestamp',
    'COORD_X'  => 'lat',
    'COORD_Y'  => 'lon',
    'SPEED'    => 'speed',
    'BEARING'  => 'bearing',
    'ALTITUDE' => 'altitude',
    'BATT'     => 'batt'
  };
}

#**********************************************************
=head2 unify_data()

  Arguments:
    $FORM,
    $mappings

  Returns:
    $data

=cut
#**********************************************************
sub unify_data {
  my ($FORM, $mappings) = @_;

  my $data = {};

  for my $key (keys %{$mappings}) {
    $data->{$key} = $FORM->{$mappings->{$key}};
  }

  return $data;
}

#**********************************************************
=head2 log_debug()

  Arguments:
    $name,
    $str,
    $level

=cut
#**********************************************************
sub log_debug {
  my ($name, $str, $level) = @_;

  my $log_line = '';

  if (ref $str eq 'ARRAY') {
    $str = join ", ", @{$str};
  }

  if ($debug >= $level) {
    $log_line .= "$name : $str \n";
  }

  $Log->log_print('LOG_INFO', $prog_name, $log_line, { LOG_FILE => $log_file });
}

#**********************************************************
=head2 UTC2LocalString()

  Arguments:
    $t - time

=cut
#**********************************************************
sub UTC2LocalString {
  my $t = shift;
  my ($datehour, $rest) = split(/:/, $t, 2);
  my ($year, $month, $day, $hour) = $datehour =~ /(\d+)-(\d\d)-(\d\d)\s+(\d\d)/;

  $month = $month - 1;
  if ($month eq -1) {
    return('1970-01-01 00:00:00');
  }
  my $epoch = timegm(0, 0, $hour, $day, $month, $year);

  my ($lyear, $lmonth, $lday, $lhour, undef) = (localtime($epoch))[5, 4, 3, 2, -1];

  $lyear += 1900; # year is 1900 based
  $lmonth++;      # month number is zero based

  return(sprintf("%04d-%02d-%02d %02d:%s", $lyear, $lmonth, $lday, $lhour, $rest));
}


#**********************************************************
=head2 define_the_protocol()

  Arguments:
    $pa_data,

  Returns:
    $FORM

=cut
#**********************************************************
sub define_the_protocol {
  my ($ps_data) = @_;
  my $FORM = {};

  #TK102
  if (substr($ps_data, 0, 2) eq '(0' && substr($ps_data, -9) eq '00000000)') {
    # (027043576388BR00150919A4949.6147N02402.0461E000.60650290.000000000000L00000000)
    $FORM = parse_tk103_protokol($ps_data);
  }
  elsif($conf{GPS_PROTOCOL}) {
    parse_fm_xxx($ps_data);
  }
  else {
    $FORM = parse_http_request($ps_data)
  }

  return $FORM;
}

#**********************************************************
=head2 parse_fm_xxx($ps_data) - teltonika fm_xxx

  Protocol:
    https://voxtrail.com/assets/company/Teltonika/protocol/FMXXXX_Protocols_v2.10.pdf

  Arguments:
    $pa_data,

  Returns:
    $FORM

=cut
#**********************************************************
sub parse_fm_xxx {
  my ($ps_data) = @_;

  my %FORM = ();

  my @arr = $ps_data =~ /(\S{2})/g;

  $FORM{CODEC_ID}=$arr[0];
  $FORM{NUMOFDATA}=$arr[1];
  $FORM{UNIX_TIMESTAMP}=join('', @arr[2..8]);

  while(my($k, $v)=each %FORM) {
    print "$k, $v\n";
  }

  return \%FORM;
}

1;
