=head1 NAME

   equipment ping

   Arguments:

     TIMEOUT
     NAS_IPS
     DEBUG

=cut


use warnings;
use strict;
use AXbills::Base qw(in_array);
use Equipment;
use Net::Ping;
use Events::API;

our (
  $Admin,
  $db,
  %conf,
  $argv,
  $base_dir,
  $debug,
);

my $Equipment = Equipment->new( $db, $Admin, \%conf );
my $Events = Events::API->new( $db, $Admin, \%conf );

local $ENV{PATH} = "$ENV{PATH}:/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin:/root/bin";
equipment_ping($argv);


#**********************************************************
=head2 equipment_ping($attr)

  Arguments:
    $attr
      TIMEOUT
      NAS_IPS

  Returns:
    1

=cut
#**********************************************************
sub equipment_ping {
  my ($attr) = @_;

  my $timeout = $attr->{TIMEOUT} || '4';

  if($attr->{NAS_IPS}) {
    $LIST_PARAMS{NAS_IP}=$attr->{NAS_IPS};
  }

  my $ping = Net::Ping->new( 'syn' ) or die "Can't create new ping object: $!\n";

  if($debug > 6) {
    $Equipment->{debug}=1;
  }

  my $equipment = $Equipment->_list( {
    NAS_IP    => '_SHOW',
    %LIST_PARAMS,
    COLS_NAME => 1,
    PAGE_ROWS => 100000,
    STATUS    => '0;3',
    NAS_NAME  => '_SHOW',
  } );

  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
  my $datetime = sprintf("%04d-%02d-%02d %02d:%02d:%02d", $year + 1900, $mon + 1, $mday, $hour, $min, $sec);

  my %ips = ();
  foreach my $host (@$equipment) {
    if(! $host->{nas_ip}) {
      next;
    }

    $ips{$host->{nas_ip}} = {
      NAS_ID   => $host->{nas_id},
      STATUS   => $host->{status},
      NAS_NAME => $host->{nas_name} || q{}
    };
  }

  my %syn;
  my %ret_time;
  foreach my $host_ip (keys %ips) {
    if($debug > 5) {
      print "SYN ping: trying to ping $host_ip\n";
    }

    my ($ret, $duration, $ip) = $ping->ping( $host_ip, $timeout );
    if ($ret) {
      $syn{$host_ip} = $ip;
      $ret_time{$host_ip} = $duration;
    }
    else {
      print "SYN ping: $host_ip address not found\n";
    }
  }

  my $message = '';
  while (my ($host_ip, undef, undef) = $ping->ack) {
    if ($ips{$host_ip}{STATUS} == 3) {
      print "Updating host $host_ip STATUS to AVAILABLE\n" if ( $debug > 1 );
      $message .= "$ips{$host_ip}{NAS_NAME}($host_ip) _{AVAILABLE}_\n";
    }
    $Equipment->_change({
      NAS_ID        => $ips{$host_ip}{NAS_ID},
      STATUS        => 0,
      LAST_ACTIVITY => $datetime,
      SKIP_LOG      => 1
    });

    # $Equipment->ping_log_add({
    #   DATE     => $datetime,
    #   NAS_ID   => $ips{$host_ip}{NAS_ID},
    #   STATUS   => 1,
    #   DURATION => $ret_time{$host_ip},
    # });

    print "SYN ping: $host_ip is reachable\n" if ( $debug > 1 );
    delete $syn{$host_ip};
  }

  $ping->close();

  my $fping_installed = qx/which fping/;
  if ( $fping_installed ne "" ) {
    foreach my $host_ip (keys %syn) {
      print "fping: trying to ping $host_ip\n" if ( $debug > 1 );
      my $fping = system "fping -C 2 -q $host_ip";
      print "fping: returned status $fping for host $host_ip\n" if ( $debug > 1 );
      if ( $fping != 0 ) {
        print "fping: $host_ip is unreachable\n" if ( $debug > 1 );
        if ($ips{$host_ip}{STATUS} == 0) {
          print "Updating host $host_ip STATUS to UNAVAILABLE\n" if ( $debug > 1 );
          $Equipment->_change( { NAS_ID => $ips{$host_ip}{NAS_ID}, STATUS => 3, SKIP_LOG => 1 } );
          $message .= "$ips{$host_ip}{NAS_NAME}($host_ip) _{UNAVAILABLE}_\n";
        }

        # $Equipment->ping_log_add({
        #   DATE     => $datetime,
        #   NAS_ID   => $ips{$host_ip}{NAS_ID},
        #   STATUS   => 0,
        #   DURATION => $timeout,
        # });
      }
      else {
        print "fping: $host_ip is reachable\n" if ( $debug > 1 );
        $Equipment->_change( { NAS_ID => $ips{$host_ip}{NAS_ID}, STATUS => 0, SKIP_LOG => 1, LAST_ACTIVITY => $datetime } );

        if ($ips{$host_ip}{STATUS} == 3) {
          print "Updating host $host_ip STATUS to AVAILABLE\n" if ( $debug > 1 );
          $message .= "$ips{$host_ip}{NAS_NAME}($host_ip) _{AVAILABLE}_\n";
        }

        # $Equipment->ping_log_add({
        #   DATE     => $datetime,
        #   NAS_ID   => $ips{$host_ip}{NAS_ID},
        #   STATUS   => 1,
        #   DURATION => $timeout,
        # });
      }
    }
  }
  else {
    foreach my $host_ip (keys %syn) {
      my $ping_icmp = Net::Ping->new("icmp");
      if (!$ping_icmp->ping($host_ip, 2)) {
        print "ICMP ping: $host_ip is unreachable\n" if ( $debug > 1);
        if ($ips{$host_ip}{STATUS} == 0) {
          print "Updating host $host_ip STATUS to UNAVAILABLE\n" if ( $debug > 1 );
          $Equipment->_change( { NAS_ID => $ips{$host_ip}{NAS_ID}, STATUS => 3, SKIP_LOG => 1 } );
          $message .= "$ips{$host_ip}{NAS_NAME}($host_ip) _{UNAVAILABLE}_\n";
        }
        #TODO: ping_log_add STATUS => 0 if ping_log_add will be used
      }
      else {
        $Equipment->_change( { NAS_ID => $ips{$host_ip}{NAS_ID}, STATUS => 0, SKIP_LOG => 1, LAST_ACTIVITY => $datetime } );
        print "ICMP ping: $host_ip is reachable\n" if ( $debug > 1);
        if ($ips{$host_ip}{STATUS} == 3) {
          print "Updating host $host_ip STATUS to AVAILABLE\n" if ( $debug > 1 );
          $message .= "$ips{$host_ip}{NAS_NAME}($host_ip) _{AVAILABLE}_\n";
        }
        #TODO: ping_log_add STATUS => 1 if ping_log_add will be used
      }
    }
  }

  if ($message) {
    ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
    my $datestr = sprintf("%02d:%02d:%02d %02d.%02d.%04d", $hour, $min, $sec, $mday, $mon + 1, $year + 1900);
    $message = $datestr . "\n$message";
    generate_new_event( "$message" );
  }

  return 1;
}

#**********************************************************
=head2 generate_new_event($comments)

  Arguments:
    $comments - text of message to show

  Returns:

=cut
#**********************************************************
sub generate_new_event{
  my ($comments) = @_;

  return 0 if (!in_array('Events', \@MODULES));

  print "EVENT: $comments\n" if ($debug);

  $Events->add_event({
    MODULE      => "Equipment",
    PRIORITY_ID => 5,
    STATE_ID    => 1,
    TITLE       => '_{WARNING}_',
    COMMENTS    => $comments,
  });

  return 1;
}

1
