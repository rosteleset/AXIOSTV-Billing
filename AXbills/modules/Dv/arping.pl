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
my $SESSION_ID = $ARGS{ACCT_SESSION_ID} or die usage();

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
  Usage: ./arping.pl ACCT_SESSION_ID=81809614 [DEBUG=1] [ L2=1 [ NAS_TYPES=mikrotik,mikrotik_dhcp ]]
    DEBUG     - be verbose
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
  
  print "Session id : $session_id \n" if ($DEBUG);
  
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
  
  print "Will arping $session_info->{FRAMED_IP_ADDRESS} \n" if ($DEBUG);
  
  my $ssh_cmd = "ping arp-ping=yes interface=[put [ip arp get [find address=$session_info->{FRAMED_IP_ADDRESS}] interface]]"
    . " $session_info->{FRAMED_IP_ADDRESS} count=3";
  
  my $res = ssh_cmd($ssh_cmd, {
      BASE_DIR        => $base_dir,
      NAS_MNG_IP_PORT => $Nas_->{NAS_MNG_IP_PORT},
      NAS_MNG_USER    => $Nas_->{NAS_MNG_USER},
      #    DEBUG           => $DEBUG
    });
  
  if ( $res && ref $res eq 'ARRAY' ) {
    $res = join ('', @{$res});
  }
  
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
      print "Failed to get VLAN for host \n";
      return 0;
    }
    my $lease = $leases_list->[0];

    if ( !$lease->{vid} ) {
      print "Lease don't have VLAN to get IP Pool for \n";
      return 0;
    }

    $lease_vlan = $lease->{vid} || 0;
  }

  $Nas->query2("SELECT id, name FROM ippools WHERE vlan=?", undef, { Bind => [ $lease_vlan ], COLS_NAME => 1 });
  if ($Nas->{errno} || !$Nas->{list} || !(ref $Nas->{list} eq 'ARRAY' && scalar (@{$Nas->{list}}))) {
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
    print "Failed to find NAS_ID for pool $pool->{name} # $pool->{id} \n";
    return 0;
  }

  if (scalar (@{$Nas->{list}}) > 1) {
    print "Pool is linked to more than one NAS. TOTAL : " . scalar (@{$Nas->{list}}) . " \n";
    return 0;
  }

  my $nas_id = $Nas->{list}[0]->{id};

  return $nas_id;

}

1;
