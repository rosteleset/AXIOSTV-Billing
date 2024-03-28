=head1 NAME

 billd plugin

 DESCRIBE: Check Cisco lines

=cut

use strict;
use warnings FATAL => 'all';
use AXbills::Nas::Control;

our (
  $Nas,
  $argv,
  $debug,
  $Sessions,
  %LIST_PARAMS,
  $debug_output,
  %conf,
);

cisco_checklines();

#**********************************************************
=head2 check_cisco_if($attr) check Active interfaces in Cisco

=cut
#**********************************************************
sub cisco_checklines{
  #my ($attr)       = @_;
  my %session_hash = ();

  if ( $LIST_PARAMS{NAS_IDS} ){
    my $list = $Nas->list( {
        NAS_ID    => $LIST_PARAMS{NAS_IDS},
        COLS_NAME => 1,
        NAS_TYPE  => 'cisco',
        PAGE_ROWS => 50000} );

    foreach my $nas_info ( @{$list} ){
      my $nas_mng_pass = $argv->{NAS_MNG_PASSWORD} || $nas_info->{nas_mng_password};
      $debug_output .= "NAS ID: $nas_info->{id} MNG_INFO: $nas_info->{nas_mng_user}\@$nas_info->{nas_mng_ip_port} $nas_info->{nas_rad_pairs}\n" if ($debug > 2);

      my @aaa_ses_cisco = SNMP_util::snmpwalk( $nas_mng_pass . '@' . $nas_info->{nas_ip},
        ".1.3.6.1.4.1.9.9.150.1.1.3.1.3" );
      foreach my $item ( @aaa_ses_cisco ){
        if (! $item) {
          next;
        }
        my ($sess_id, $addr) = split( ':', $item );
        if ( $addr ne '0.0.0.0' ){
          $session_hash{ $nas_info->{id} . ":$sess_id" } = $addr;
        }
      }
    }
  }

  $Sessions->{debug} = 1 if ($debug > 4);
  my $list = $Sessions->online( {
      NAS_PORT_ID => '_SHOW',
      CLIENT_IP   => '_SHOW',
      NAS_ID      => $LIST_PARAMS{NAS_IDS}
    } );

  my %online_ips = ();
  foreach my $line ( @{$list} ){
    my $sess_id = $line->{nas_port_id};
    my $ip      = $line->{client_ip};
    my $nas_id  = $line->{nas_id};
    $online_ips{$line->{client_ip}}=1;
    print "exist: $nas_id $sess_id $ip\n" if ($debug > 3);
    delete $session_hash{"$nas_id:$sess_id"};
  }

  my $unallow_ips = 0;
  while (my ($info, $ip_address) = each %session_hash) {
    if ($online_ips{$ip_address}) {
      next;
    }
    my ($nas_id, $iface) = split( /:/, $info, 2 );
    if ( $conf{DV_PPP_UNCHECKED} ){
      next if ($ip_address =~ /$conf{DV_PPP_UNCHECKED}/);
    }
    if ($debug < 5) {
      hangup_snmp(
        $Nas->info( { NAS_ID => $nas_id } ),
        {
          OID   => '.1.3.6.1.4.1.9.9.150.1.1.3.1.5.'.$iface,
          TYPE  => 'integer',
          VALUE => 1
        }
      );
    }
    print "Killed NAS: $nas_id IP: $ip_address IF: $iface ($DATE $TIME)\n";
    $unallow_ips++;
  }
  print "Unallow ips: $unallow_ips\n" if ($debug > 1);

  return 1;
}


1;
