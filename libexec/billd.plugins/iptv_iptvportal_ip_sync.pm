=head1 NAME

 billd plugin

 DESCRIBE:  IptvPortal - Sync users ips

 Arguments:

=cut

use strict;
use warnings;
use Iptv::Iptvportal;
use Iptv;
use Tariffs;
use AXbills::Base qw(load_pmodule in_array _bp);

our (
  $argv,
  $debug,
  %conf,
  $Admin,
  $db,
  $OS,
  $var_dir
);

our $Iptv = Iptv->new($db, $Admin, \%conf);
require Iptv::Services;

iptvportal_ips_sync();

#**********************************************************
=head2 iptvportal_ips_sync($attr)

=cut
#**********************************************************
sub iptvportal_ips_sync {

  my $service_list = $Iptv->services_list({
    NAME      => '_SHOW',
    LOGIN     => '_SHOW',
    PASSOWRD  => '_SHOW',
    MODULE    => 'Iptvportal',
    COLS_NAME => 1,
  });

  foreach my $service (@$service_list) {
    print "Service ID: $service->{id} NAME: $service->{name}\n" if ($debug > 3);

    my $Iptvportal_api = tv_load_service('', { SERVICE_ID => $service->{id} });
    my $Users_list = $Iptv->user_list({
      SERVICE_ID    => $service->{id},
      LOGIN         => '_SHOW',
      TP_ID         => '_SHOW',
      PIN           => '_SHOW',
      TP_FILTER     => '_SHOW',
      PASSWORD      => '_SHOW',
      SUBSCRIBE_ID  => '_SHOW',
      GROUP_BY      => 'GROUP BY service.subscribe_id',
      COLS_NAME     => 1,
      PAGE_ROWS     => 99999,
    });

    foreach (@{$Users_list}) {
      next if !$_->{subscribe_id};

      print "Synchronize user - $_->{login} ($_->{uid})...\n" if ($debug > 3);

      $Iptvportal_api->_insert_inet_addr({
        UID          => $_->{uid},
        SUBSCRIBE_ID => $_->{subscribe_id}
      });
    }
  }

  return 1;
}