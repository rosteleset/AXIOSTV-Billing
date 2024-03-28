=head1 NAME

   internet_log_pack

   Arguments:

=cut

use strict;
use warnings FATAL => 'all';

our (
  $Admin,
  $debug,
  $DATE,
);

our Internet::Sessions $Sessions;
our Internet $Internet;

internet_cid_update();

#**********************************************************
=head2 internet_cid_update($attr)

  Arguments:


  Returns:

=cut
#**********************************************************
sub internet_cid_update {

  if ($debug > 7) {
    $Sessions->{debug}=1;
  }

  my $online_list = $Sessions->online({
    CID         => '_SHOW',
    SERVICE_CID => '_SHOW',
    SERVICE_ID  => '_SHOW',
    USER_NAME   => '_SHOW',
    _WHERE_RULES => 'c.cid<>service.cid'
  });

  foreach my $online ( @$online_list ) {
    if ($debug) {
      print "$online->{user_name} (SERVICE_ID: $online->{service_id}): ONLINE: $online->{cid} SERVICE_CID: $online->{service_cid}\n";
    }

    $Internet->user_change({
      CID        => $online->{cid},
      UID        => $online->{uid},
      SERVICE_ID => $online->{service_id}
    });
  }

  return 1;
}


1;