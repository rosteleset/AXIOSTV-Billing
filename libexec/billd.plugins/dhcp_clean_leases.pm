# billd plugin
#
# DESCRIBE: Clean dhcp leases table
#
#**********************************************************

use strict;

our(
  $db,
  $admin,
  %conf,
  $debug
);

dhcp_clean_leases();

#**********************************************************
=head2 dhcp_clean_leases()

=cut
#**********************************************************
sub dhcp_clean_leases {
  #my ($attr)=@_;
  print "dhcp_clean_leases\n" if ($debug > 1);

  use strict;
  use warnings;
  use Dhcphosts;
  
  my $Dhcphosts = Dhcphosts->new($db, $admin, \%conf);
  if ($debug > 6) {
    $Dhcphosts->{debug}=1;
  }

  $Dhcphosts->leases_clear({ ENDED => 1 });

  return 1;
}

1