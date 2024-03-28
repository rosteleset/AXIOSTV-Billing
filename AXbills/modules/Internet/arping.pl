#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';
use v5.16;

=name2 NAME

  arping.pl

=name2 SYNOPSYS

  Gets session params and does arping

=name2 CAPABILITY

  if L2=1, will find closest nas, that can do arping

=name2 EXAMPLE

  ./arping.pl ACCT_SESSION_ID=81809614
 
=cut

BEGIN {
  our $Bin;
  use FindBin '$Bin';

  if ( $Bin =~ m/\/axbills(\/)/ ){
    my $libpath = substr($Bin, 0, $-[1]);
    unshift (@INC, "$libpath/lib");
  }
  else {
    die " Should be inside /usr/axbills dir \n";
  }
}

our $base_dir = "/usr/axbills";

# Setting autoflush
$| = 1;

use AXbills::Init qw/$db $admin %conf @MODULES/;

use AXbills::Base qw(parse_arguments _bp ssh_cmd cmd in_array);
use Nas;

my $Sessions;
if (in_array('Internet', \@MODULES)){
  require Internet::Sessions;
  $Sessions = Internet::Sessions->new($db, $admin, \%conf);
}
else {
require Dv_Sessions;
  $Sessions = Dv_Sessions->new($db, $admin, \%conf);
}


my $Nas = Nas->new($db, \%conf, $admin);

my %ARGS = %{ parse_arguments(\@ARGV) };

my $DEBUG = $ARGS{DEBUG} || 0;
my $NO_ARP = $ARGS{NO_ARP} || 0;
my $SESSION_ID = $ARGS{ACCT_SESSION_ID} or die usage();
my $EXTENDED = $ARGS{EXTENDED} || 0;

my %TYPE_PING_TABLE = (
  'mikrotik_dhcp' => \&mikrotik_arping,
  'mikrotik'      => \&mikrotik_arping,
  'mpd'           => \&self_console_arping,
);

my $sess_info = get_session_info($SESSION_ID);
if ( $sess_info ) {
  arping($sess_info);
}

#**********************************************************
=head2 usage()

=cut
#**********************************************************
sub usage {
  print qq{
  Usage: ./arping.pl ACCT_SESSION_ID=81809614 [DEBUG=1] [EXTENDED=1] [ L2=1 [ NAS_TYPES=mikrotik,mikrotik_dhcp ]]
    DEBUG     - be verbose
    EXTENDED  - Mikrotik extended diagnostics
    NO_ARP    - use ping, not arpping
    L2        - find NAS, that can make arping
    NAS_TYPES - types that will be treated as smart enough to make arping

};
  exit 1;
}

#**********************************************************
=head2 get_session_info()

=cut
#**********************************************************
sub get_session_info {
  my $session_id = shift;

  require AXbills::Misc;

  print "Session id : $session_id \n" if ($DEBUG);
  my ($first, $vendor, $second) = split(/_/, $session_id);
  eval {$vendor = get_oui_info($vendor);};
  print "Vendor:" . ($vendor || "") . "\n";

  my $session = $Sessions->online_info({
    ACCT_SESSION_ID => $session_id,
    NAS_ID          => '_SHOW',
    NAS_IP_ADDRESS  => '_SHOW'
  });

  if ( $Sessions->{errno} || $Sessions->{TOTAL} < 1 ) {
    print "No session found \n";
  }

  return $session;
}

#**********************************************************
=head2 arping()

=cut
#**********************************************************
sub arping {
  my ($session_info) = shift;

  my $nas_id = $session_info->{NAS_ID};

  print "NAS_ID : $nas_id\n" if ($DEBUG);

  if ( $ARGS{L2} ) {
    print "Looking for smart NAS : $nas_id\n" if ($DEBUG);
    $nas_id = find_nas_to_make_arping($session_info, $nas_id);

    if (!$nas_id){
      print "STATUS: err\n";
      print "Failed to get NAS to ping \n";
      exit 1;
    }
    print "Will use : $nas_id\n" if ($DEBUG);

  }

  my $Nas_ = $Nas->info({ NAS_ID => $nas_id });
  if ( $Nas_->{NAS_TYPE} && exists $TYPE_PING_TABLE{$Nas_->{NAS_TYPE}} ) {
    print "Calling arping for $Nas_->{NAS_TYPE} \n" if ($DEBUG);

    $TYPE_PING_TABLE{$Nas_->{NAS_TYPE}}->($Nas_, $session_info);

  }
  else {
    print "STATUS: err\n";
    print "Don't know how to arping for $Nas_->{NAS_TYPE} \n" if ($DEBUG);
    exit 1;
  }

}

#**********************************************************
=head2 mikrotik_arping()

=cut
#**********************************************************
sub mikrotik_arping {
  my ($Nas_, $session_info) = @_;
  print "mikrotik_arping called \n" if ($DEBUG);

  if ($EXTENDED && $conf{MIKROTIK_API}) {
    require AXbills::Nas::Mikrotik;
    AXbills::Nas::Mikrotik->import();
    my $Mikrotik = AXbills::Nas::Mikrotik->new(
      $Nas_,
      \%conf,
      {
        FROM_WEB         => 1,
        MESSAGE_CALLBACK => sub { print('info', $_[0], $_[1]) },
        ERROR_CALLBACK   => sub { print('err', $_[0], $_[1]) },
        API_BACKEND      => 1
      }
    );

    if (!$Mikrotik) {
      print "ERROR: Not defined NAS IP address and Port\n";
      return 0;
    }
    elsif ($Mikrotik->has_access() != 1){
      print "ERROR: No access to $Mikrotik->{ip_address}:$Mikrotik->{port} ($Mikrotik->{backend})"
      . (($Mikrotik->{errstr}) ? "\n$Mikrotik->{errstr}" : q{});
      return 0;
    }

    my $ip = $session_info->{FRAMED_IP_ADDRESS};

    my $ping_tag = $Mikrotik->start_tagged_query(
      '/ping',
      {
        'address'   => $ip,
        'count'     => 3,
        '.proplist' => 'seq,host,size,ttl,time,status,sent,received,packet-loss,min-rtt,avg-rtt,max-rtt'
      }
    );

    my $addr_list_tag = $Mikrotik->start_tagged_query(
      '/ip firewall address-list print',
      {'.proplist' => 'list,disabled'},
      {'address' => $ip}
    );

    my $queue_tag = $Mikrotik->start_tagged_query(
      '/queue simple print',
      {'.proplist' => '.id,max-limit,disabled'},
      {'target' => $ip . '/32'}
    );

    $Mikrotik->get_tagged_query_result($ping_tag);

    my $arp_tag = $Mikrotik->start_tagged_query(
      '/ip arp print',
      {'.proplist' => 'interface,mac-address'},
      {'address' => $ip}
    );

    my $arp = [$Mikrotik->get_tagged_query_result($arp_tag)];
    my $arp_interface = $arp->[1]->{interface};

    my $arp_ping_tag = $Mikrotik->start_tagged_query(
      '/ping',
      {
        'address'   => $ip,
        'count'     => 3,
        'arp-ping'  => 'yes',
        'interface' => $arp_interface,
        '.proplist' => 'seq,host,size,ttl,time,status,sent,received,packet-loss,min-rtt,avg-rtt,max-rtt'
      }
    );

    my $results = $Mikrotik->get_tagged_query_result([$addr_list_tag, $queue_tag, $ping_tag, $arp_ping_tag]);
    my ($addr_list, $queue, $ping, $arp_ping) = map {$results->{$_} if ($results->{$_}->[0] == 1);} ($addr_list_tag, $queue_tag, $ping_tag, $arp_ping_tag);

    foreach ($addr_list, $queue, $ping, $arp_ping) {
      shift @$_;
    }

    my $ping_stats = $ping->[-1];
    my $arp_ping_stats = $arp_ping->[-1];

    if($ping_stats->{received} == 0 || $arp_ping_stats->{received} == 0) {print "STATUS: err\n"}
    elsif($ping_stats->{received} == 3 || $arp_ping_stats->{received} == 3) {print "STATUS: info\n"}
    elsif(!(defined $ping_stats->{received}) || !(defined $arp_ping_stats->{received})) {print "STATUS: err\n"}
    else {print "STATUS: warn\n"};

    print "User IP: " . $ip . "\n";

    if ($addr_list) {
      print "negativ: " . ($addr_list->[0]->{list} eq 'negative' ? 'YES' : 'NO') . "\n";
      print "Address list: " . $addr_list->[0]->{list} . ($addr_list->[0]->{disabled} eq 'true' ? ' (disabled)' : '') . "\n";
    }
    else {
      print "Address list not found\n";
    }

    if ($queue) {
      my $shaper_speed = $queue->[0]->{"max-limit"};
      if ($shaper_speed =~ /(\d+)\/(\d+)/) {
        $shaper_speed = $1/1000 . 'k/' . $2/1000 . 'k';
      }
      print "Shaper speed (up/down, kbps): " . $shaper_speed . ($queue->[0]->{disabled} eq 'true' ? ' (disabled)' : '') . "\n";
    }
    else {
      print "Shaper speed not found\n";
    }
    print "\n";


    my @ping_attrs = ('seq', 'host', 'size', 'ttl', 'time', 'status');
    my @ping_stats_attrs = ('sent', 'received', 'packet-loss', 'min-rtt', 'avg-rtt', 'max-rtt');
    print "SEQ\tHOST\t\tSIZE\tTTL\tTIME\tSTATUS\n";
    foreach my $echo_reply (@$ping) {
      foreach my $ping_attr (@ping_attrs) {
        if (defined $echo_reply->{$ping_attr}) {
          print $echo_reply->{$ping_attr};
        }
        print "\t";
      }
      print "\n";
    }

    foreach my $ping_stats_attr (@ping_stats_attrs) {
      if (defined $ping_stats->{$ping_stats_attr}) {
        print "$ping_stats_attr=$ping_stats->{$ping_stats_attr} ";
      }
    }
    print "\n\n";

    print "arp record: $ip " . (($arp->[1]->{"mac-address"}) ? ($arp->[1]->{"mac-address"}) : '') . " $arp_interface\n\n";

    my @arp_ping_attrs = ('seq', 'host', 'time', 'status');
    print "SEQ\tHOST\t\t\tTIME\tSTATUS\n";
    foreach my $echo_reply (@$arp_ping) {
      foreach my $ping_attr (@arp_ping_attrs) {
        if (defined $echo_reply->{$ping_attr}) {
          print $echo_reply->{$ping_attr};
        }
        print "\t";
      }
      print "\n";
    }

    foreach my $ping_stats_attr (@ping_stats_attrs) {
      if (defined $arp_ping_stats->{$ping_stats_attr}) {
        print "$ping_stats_attr=$arp_ping_stats->{$ping_stats_attr} ";
      }
    }

    return 0;
  }

  my $ssh_cmd = '';
  if ($NO_ARP) {
    print "*** Will ping $session_info->{FRAMED_IP_ADDRESS} \n" if ($DEBUG);
    #$ssh_cmd = "ping interface=[put [ip arp get [find address=$session_info->{FRAMED_IP_ADDRESS}] interface]]" . " $session_info->{FRAMED_IP_ADDRESS} count=3";
    $ssh_cmd = "ping $session_info->{FRAMED_IP_ADDRESS} count=3";
  }
  else {
    print "Will arping $session_info->{FRAMED_IP_ADDRESS} \n" if ($DEBUG);
    if($EXTENDED){
      $ssh_cmd = '/local IP ' . $session_info->{FRAMED_IP_ADDRESS} . ";\n" .
                 '/local foundAddressList [/ip firewall address-list find address=$IP];
                 if ([len $foundAddressList] != 0) do={
                   /local foundAddressListName [ip firewall address-list get $foundAddressList list];
                   /local foundAddressListDisabled;
                   if ([ip firewall address-list get $foundAddressList disabled]) do={
                     /set foundAddressListDisabled "(disabled)";
                   };
                   /local negativ "NO";
                   if ($foundAddressListName="negative") do={
                     /set negativ "YES"
                   };
                   /put "User IP: $IP\r\nnegativ - $negativ\r\nAddress list $foundAddressListName $foundAddressListDisabled"
                 }
                 else={
                   /put "Address list not found"
                 };
                 /local foundQueue [/queue simple find target~"^$IP(/32)\?\$"];
                 /if ([len $foundQueue] != 0) do={
                   /local foundSpeed [/queue simple get $foundQueue max-limit];
                   /local foundQueueDisabled;
                   if ([/queue simple get $foundQueue disabled]) do={
                     /set foundQueueDisabled "(disabled)";
                   };
                   /put "shaper speed (up/down, kbits): $foundSpeed $foundQueueDisabled\r\n";
                 }
                 else={
                   put "shaper speed not found";
                 };
                 ping $IP count=3;
                 /local foundArp [/ip arp find address=$IP];
                 if ([len $foundArp] != 0) do={
                   /local foundMac [/ip arp get $foundArp mac];
                   /local foundInterface [/ip arp get $foundArp interface];
                   put "arp record: $IP $foundMac $foundInterface\r\n";
                   ping arp-ping=yes interface=$foundInterface $IP count=3;
                 }
                 else={
                   put "arp record not found";
                 }';
                 if ($DEBUG){
                   print "Will run:\n$ssh_cmd\n"
                 };
    }
    else{
      $ssh_cmd = "ping arp-ping=yes interface=[put [ip arp get [find address=$session_info->{FRAMED_IP_ADDRESS}] interface]]" . " $session_info->{FRAMED_IP_ADDRESS} count=3";
    }

  }

  my $res = ssh_cmd($ssh_cmd, {
      BASE_DIR        => $base_dir,
      NAS_MNG_IP_PORT => $Nas_->{NAS_MNG_IP_PORT},
      NAS_MNG_USER    => $Nas_->{NAS_MNG_USER},
      #DEBUG           => $DEBUG
    });

  if ( $res && ref $res eq 'ARRAY' ) {
    $res = join ('', @{$res});
  }

  if($res =~ /received=0/){print "STATUS: err\n"}
  elsif($res =~ /received=3/){print "STATUS: info\n"}
  elsif($res !~ /received/){print "STATUS: err\n"}
  else{print "STATUS: warn\n"};
  print $res;
}

#**********************************************************
=head2 self_console_arping()

=cut
#**********************************************************
sub self_console_arping {
  my $arping = `which arping` || '';
  chomp($arping);

  if ( !$arping ) {
    die "No arping installed \n";
  }

  die "Not implemented \n";
  #  print cmd("$arping")

}

#**********************************************************
=head2 get_nas_to_make_arping()

=cut
#**********************************************************
sub find_nas_to_make_arping {
  my ( $session_info, $current_nas_id) = @_;

  # Find a vlan
  my $lease_vlan = -1;
  if (in_array('Internet', \@MODULES)) {
    print "Looking for VLAN via Internet+ \n" if ($DEBUG);
    require Internet;
    Internet->import();

    my $Internet = Internet->new($db, $admin, \%conf);
    my $leases_list = $Internet->user_list({
      ONLINE_IP => $session_info->{FRAMED_IP_ADDRESS},
      VLAN      => '_SHOW',
      COLS_NAME => 1
    });

    if ($Internet->{errno} || !$leases_list || ref $leases_list ne 'ARRAY' || !(scalar @{$leases_list})) {
      print "Failed to get VLAN for host \n";
      return 0;
    }
    my $lease = $leases_list->[0];

    if (!$lease->{vlan}) {
      print "STATUS: err\n";
      print "Lease don't have VLAN to get IP Pool for \n";
      return 0;
    }

    $lease_vlan = $lease->{vlan} || 0;
  }
  else {
    print "Looking for VLAN via Dhcphosts \n" if ($DEBUG);

    require Dhcphosts;
    Dhcphosts->import();

    my $Dhcphosts = Dhcphosts->new($db, $admin, \%conf);
    my $leases_list = $Dhcphosts->hosts_list({
      IP        => $session_info->{FRAMED_IP_ADDRESS},
      VID       => '_SHOW',
      COLS_NAME => 1
    });

    if ( $Dhcphosts->{errno} || !$leases_list || ref $leases_list ne 'ARRAY' || !(scalar @{$leases_list}) ) {
      print "STATUS: err\n";
      print "Failed to get VLAN for host \n";
      return 0;
    }
    my $lease = $leases_list->[0];

    if ( !$lease->{vid} ) {
      print "STATUS: err\n";
      print "Lease don't have VLAN to get IP Pool for \n";
      return 0;
    }

    $lease_vlan = $lease->{vid} || 0;
  }

  $Nas->query2("SELECT id, name FROM ippools WHERE vlan=?", undef, { Bind => [ $lease_vlan ], COLS_NAME => 1 });
  if ($Nas->{errno} || !$Nas->{list} || !(ref $Nas->{list} eq 'ARRAY' && scalar (@{$Nas->{list}}))) {
    print "STATUS: err\n";
    print "Failed to find ip pool for VLAN $lease_vlan \n";
    return 0;
  }

  my $pool = $Nas->{list}->[0];
  my @BIND_VARS = ($pool->{id});

  my $by_nas_type = '';
  if ($ARGS{NAS_TYPES}) {
    my $type_placeholders = '';

    push (@BIND_VARS, split(",", $ARGS{NAS_TYPES}));
    $type_placeholders = join(',', map {'?'} split(",", $ARGS{NAS_TYPES}));

    $by_nas_type = ($ARGS{NAS_TYPES}) ? "AND nas_type IN ( $type_placeholders )" : '';
  }

  $Nas->query2("SELECT id FROM nas WHERE id IN (SELECT nas_id FROM nas_ippools WHERE pool_id=?) $by_nas_type;", undef,
    { Bind => \@BIND_VARS, COLS_NAME => 1 });
  if ($Nas->{errno} || !$Nas->{list} || !(ref $Nas->{list} eq 'ARRAY')) {
    print "STATUS: err\n";
    print "Failed to find NAS_ID for pool $pool->{name} # $pool->{id} \n";
    return 0;
  }

  if (scalar (@{$Nas->{list}}) > 1) {
    print "STATUS: err\n";
    print "Pool is linked to more than one NAS. TOTAL : " . scalar (@{$Nas->{list}}) . " \n";
    return 0;
  }

  my $nas_id = $Nas->{list}[0]->{id};

  return $nas_id;

}

1;
