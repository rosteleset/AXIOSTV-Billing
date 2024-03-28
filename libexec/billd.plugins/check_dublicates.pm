
=head1 NAME
  billd plugin check_dublicates

  DESCRIBE: Check dublicate logins and hangup it

=cut
#**********************************************************

use strict;
use warnings;

our (
  $debug,
  %conf,
  $admin,
  $db,
  @MODULES
);

our Nas $Nas;

check_dublicates();

#**********************************************************
=head2 check_dublicates()

=cut
#**********************************************************
sub check_dublicates {

  print "Check dublicates\n" if ($debug > 1);

  # TOTAL : SAME CID
  $conf{DV_SIM_CONTROL} = "1:2" if (!$conf{DV_SIM_CONTROL});

  my ($unique_cid, $same_cids) = split(/:/, $conf{DV_SIM_CONTROL});

  my $sql = q{};
  if(in_array('Internet', \@MODULES)) {
    $sql = "SELECT online.user_name, INET_NTOA(framed_ip_address) AS ip,  online.nas_port_id,
   IF (internet.logins > 0, internet.logins, tp.logins), online.acct_session_id, online.uid,
   nas.id,
   nas.ip,
   nas.nas_type,
   mng_host_port,
   mng_user,
   mng_password,
   online.cid
   FROM internet_online online,
     internet_main internet,
     tarif_plans tp,
     nas
   WHERE online.uid=internet.uid
     AND online.status<11
     AND internet.tp_id=tp.id AND tp.domain_id=0
     AND online.nas_id=nas.id
     ORDER BY online.user_name, online.cid
   ;";
  }
  else {
    $sql = "SELECT c.user_name, INET_NTOA(framed_ip_address),  c.nas_port_id,
   if (dv.logins > 0, dv.logins, tp.logins), c.acct_session_id, c.uid,
   nas.id,
   nas.ip,
   nas.nas_type,
   mng_host_port,
   mng_user,
   mng_password,
   c.CID
   FROM dv_calls online,
     dv_main internet,
     tarif_plans tp,
     nas
   WHERE c.uid=dv.uid
     AND c.status<11
     AND dv.tp_id=tp.id AND tp.domain_id=0
     AND c.nas_id=nas.id
     ORDER BY c.user_name, c.CID
   ;";
  }

  $Nas->query2($sql);

  my %logins = ();
  my %CIDS   = ();

  foreach my $line (@{ $admin->{list} }) {
    print "$line->[0] $line->[1] $line->[2] $line->[3]\n" if ($debug > 1);

    my %NAS = (
      NAS_ID           => $line->[6],
      NAS_IP           => $line->[7],
      NAS_TYPE         => $line->[8],
      NAS_MNG_IP_PORT  => $line->[9],
      NAS_MNG_USER     => $line->[10],
      NAS_MNG_PASSWORD => $line->[11]
    );

    $logins{ $line->[0] }{TOTAL}++;
    if ($CIDS{ $line->[0] }{ $line->[12] }) {
      $logins{ $line->[0] }{SAME_CID}++;
    }
    else {
      $logins{ $line->[0] }{UNIQUE_CID}++;
    }

    $CIDS{ $line->[0] }{ $line->[12] }++;

    #if ($logins{$line->[0]} > $line->[3] || $CIDS{$line->[0]}{$line->[12]} > $conf{DV_SIM_CID}) {
    if (int($logins{ $line->[0] }{UNIQUE_CID}) > $unique_cid || int($CIDS{ $line->[0] }{ $line->[12] }) > $same_cids) {
      print "Hangap dublicate '$line->[0]'\n";
      hangup(
        \%NAS,
        "$line->[2]",
        "$line->[0]",
        {
          ACCT_SESSION_ID   => $line->[4],
          FRAMED_IP_ADDRESS => $line->[1],
          UID               => $line->[5],
          debug             => $debug
        }
      );
    }

  }

  return 1;
}

1
