=head1 NAME

   ipn_snapshot_start();

=cut

use strict;
use warnings;
use AXbills::Base qw(mk_unique_value in_array);

our (
  $db,
  $admin,
  $Admin,
  %conf,
  %lang,
  $Sessions,
  $debug,
  %LIST_PARAMS,
  $argv,
  $base_dir,
  $Nas,
  $Internet
);



$admin = $Admin;
$LIST_PARAMS{PAGE_ROWS} = $argv->{PAGE_ROWS} || 1000000;
$LIST_PARAMS{LOGIN} = $argv->{LOGIN} if ($argv->{LOGIN});

my $Auth;
my $Ipn;

if(in_array('Internet', \@MODULES)) {
  require Auth2;
  Auth2->import();
  require Internet::Ipoe;
  Internet::Ipoe->import();
  $Auth = Auth2->new( $db, \%conf );
  $Ipn = Internet::Ipoe->new( $db, \%conf );
}
else {
  require Ipn;
  Ipn->import();
  require Auth;
  Auth->import();
  $Auth = Auth->new( $db, \%conf );
  $Ipn = Ipn->new( $db, \%conf );
}

require AXbills::Misc;
load_module('Ipn');


my $online_file = $base_dir .'/var/log/online_snapshot.txt';
my %nas_info = ();

if(defined($argv->{start})) {
  ipn_snapshot_start();
}
else {
  ipn_snapshot_save();
}

#**********************************************************
=head2 ipn_snapshot_save();

=cut
#**********************************************************
sub ipn_get_online {

  if($debug > 6) {
    $Sessions->{debug}=1;
  }

  my $online_list = $Sessions->online({
    LOGIN     => '_SHOW',
    NAS_ID    => '_SHOW',
    TP_ID     => '_SHOW',
    CID       => '_SHOW',
    NAS_ID    => '_SHOW',
    CLIENT_IP => '_SHOW',
    COLS_NAME => 1,
    PAGE_ROWS => 10000000,
    %LIST_PARAMS
  });

  my $online_info = ();
  foreach my $line (@$online_list) {
    my $cid = $line->{CID} || $line->{cid};
    $online_info .= "$line->{uid}\t$line->{login}\t$line->{client_ip}\t$line->{nas_id}\t$line->{tp_id}\t$cid\n";
    if($debug > 2) {
      print "$line->{uid}\t$line->{login}\t$line->{client_ip}\t$line->{nas_id}\t$line->{tp_id}\t$cid\n";
    }
  }

  return $online_info;
}

#**********************************************************
=head2 ipn_snapshot_save();

=cut
#**********************************************************
sub ipn_snapshot_save {

  if($debug > 2) {
    print "Save online sessions '$online_file'\n";
  }

  my $online_info = ipn_get_online();

  if(open(my $fh, '>', $online_file)){
    print $fh $online_info ."\n";
    close($fh);
  }
  else {
    print "Can't open file '$online_file' $!";
  }

  return 1;
}


#**********************************************************
=head2 ipn_snapshot_read();

=cut
#**********************************************************
sub ipn_snapshot_read {

  if($debug > 2) {
    print "Read online sessions";
  }

  my $content = q{};
  if(open(my $fh, '<', $online_file)){
    while(<$fh>) {
      $content .= $_;
    }
    close($fh);
  }
  else {
    print "Can't open file '$online_file' $!";
  }

  my @result = split(/\n/, $content);

  return \@result;
}


#**********************************************************
=head2 ipn_snapshot_start();

=cut
#**********************************************************
sub ipn_snapshot_start {

  if($debug > 1) {
    print "ipn_snaptshot\n";
    if($debug > 6) {
      #$Dv->{debug}=1;
    }
  }

  my $nas_list = $Nas->list(
    {
      PAGE_ROWS  => 10000,
      COLS_NAME  => 1,
      COLS_UPPER => 1
    }
  );

  %nas_info = ();
  foreach my $line ( @{$nas_list} ){
    $nas_info{ $line->{NAS_ID} } = $line;
  }

  my $online_cur_info = ipn_get_online();
  my @online_arr = split(/\n/, $online_cur_info);
  my %online_ = ();
  foreach my $info ( @online_arr ) {
    my ($uid, $login, $ip, $nas_id, undef) =split(/\t/, $info);
    $online_{$login.'_'.$ip.'_'.$nas_id.'_'.$uid} = 1;
  }

  my $online_info = ipn_snapshot_read();

  foreach my $info  ( @$online_info ) {
    my ($uid, $login, $ip, $nas_id, $tp_id, $cid) =split(/\t/, $info);
    if($debug > 1) {
      print "$uid, $login, $ip, $nas_id, $tp_id, $cid\n";
    }

    if($online_{$login.'_'.$ip.'_'.$nas_id.'_'.$uid}) {
      if($debug > 1) {
        print "Online now\n";
      }
    }
    else {
      if($debug > 1) {
        print "Activate:\n";
      }

      ipn_activate({
        user_name => $login,
        client_ip => $ip,
        nas_id    => $nas_id,
        uid       => $uid
      });
    }
  }

  return 1;
}


#**********************************************************
=head2 ipn_snapshot_start();

=cut
#**********************************************************
sub ipn_activate {
  my ($attr) = @_;

  my $nas_id = $attr->{nas_id};
  $Internet->user_info($attr->{uid});

  my %DATA = (
    ACCT_STATUS_TYPE     => 1,
    'User-Name'          => $attr->{user_name},
    USER_NAME            => $attr->{user_name},
    SESSION_START        => 0,
    ACCT_SESSION_ID      => mk_unique_value(10),
    'Acct-Session-Id'    => mk_unique_value(10),
    FRAMED_IP_ADDRESS    => $attr->{client_ip},
    'Framed-IP-Address'  => $attr->{client_ip},
    NETMASK              => $attr->{netmask} || '255.255.255.255',
    #NAS_ID_SWITCH        => $nas_id_switch || 0,
    NAS_ID               => $attr->{nas_id} || 0,
    NAS_TYPE             => $nas_info{$nas_id}{NAS_TYPE} || 'ipcad',
    NAS_IP_ADDRESS       => $nas_info{$nas_id}{NAS_IP},
    'NAS-IP-Address'     => $nas_info{$nas_id}{NAS_IP},
    NAS_MNG_USER         => $nas_info{$nas_id}{NAS_MNG_USER},
    NAS_MNG_IP_PORT      => $nas_info{$nas_id}{NAS_MNG_IP_PORT},
    TP_ID                => $Internet->{TP_ID},
    CALLING_STATION_ID   => $attr->{CID} || $attr->{cid} || $attr->{client_ip},
    'Calling-Station-Id' => $attr->{CID} || $attr->{cid} || $attr->{client_ip},
    CONNECT_INFO         => $attr->{connect_info} || 0,
    UID                  => $attr->{uid},
    QUICK                => 1,
    NAS_PORT             => $attr->{nas_port_id} || 0,
    'Nas-Port'           => $attr->{nas_port_id} || 0,
    HINT                 => 'NOPASS',
    DEBUG                => $debug,
    FILTER_ID            => $attr->{filter_id} || '',
  );

  $Auth->{UID} = $attr->{uid};
  $Auth->{IPOE_IP} = $attr->{client_ip};

  my ($r, $RAD_PAIRS);

  if(in_array('Internet', \@MODULES)) {
    ($r, $RAD_PAIRS) = $Auth->internet_auth(\%DATA, $nas_info{$nas_id}, { SECRETKEY => $conf{secretkey} });
  }
  else {
    ($r, $RAD_PAIRS) = $Auth->dv_auth(\%DATA, $nas_info{$nas_id}, { SECRETKEY => $conf{secretkey} });
  }

  if ($r == 1) {
    print "ACTIVE_IP: LOGIN: $attr->{user_name} $RAD_PAIRS->{'Reply-Message'}\n" if($debug > 1);
  }
  else {
    $Ipn->user_status({ %DATA });
    ipn_change_status({ STATUS => 'ONLINE_ENABLE', %DATA });
    #$debug_output .= "ACTIVATE IP: $attr->{client_ip}\n" if ($debug > 1);
  }

  #$activated_ips{$online->{client_ip}} = 1;

  return 1;
}

1;