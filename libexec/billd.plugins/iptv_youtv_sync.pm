=head1 NAME

 billd plugin

 DESCRIBE:  YouTV sync plugin

=cut

use strict;
use warnings;
use Iptv;
use AXbills::Base qw(load_pmodule in_array _bp);
our (
  $argv,
  $debug,
  %conf,
  $Admin,
  $db,
);

my %PARAMS = ();
my %Tv_services = ();

our $Iptv = Iptv->new($db, $Admin, \%conf);
require Iptv::Services;

youtv_sync();

#**********************************************************
=head2 youtv_sync()

=cut
#**********************************************************
sub youtv_sync {

  my $services = $Iptv->services_list({
    NAME      => '_SHOW',
    LOGIN     => '_SHOW',
    PASSOWRD  => '_SHOW',
    MODULE    => 'Youtv',
    ID        => $argv->{SERVICE_ID} || '_SHOW',
    COLS_NAME => 1,
    %PARAMS
  });

  return if $Iptv->{TOTAL} < 1;

  foreach my $service (@{$services}) {
    print "Service ID: $service->{id} NAME: $service->{name}\n" if $debug > 3;

    my $Service_api = tv_load_service('', { SERVICE_ID => $service->{id} });
    next if !$Service_api || !$Service_api->can('renew_subscription');

    my $users = $Iptv->user_list({
      SERVICE_ID     => $service->{id},
      LOGIN          => $argv->{LOGIN} || '_SHOW',
      TP_ID          => $argv->{TP_ID} || '_SHOW',
      SERVICE_STATUS => 0,
      TP_FILTER      => '_SHOW',
      SUBSCRIBE_ID   => '_SHOW',
      COLS_NAME      => 1,
      PAGE_ROWS      => 99999
    });

    foreach my $user (@{$users}) {
      next if !$user->{subscribe_id};

      $Service_api->user_add({
        FILTER_ID    => $user->{filter_id},
        SUBSCRIBE_ID => $user->{subscribe_id},
        UID          => $user->{uid}
      });
    }

    # my @users_id = ();
    # map push(@users_id, $_->{subscribe_id}), @{$users};

    # my @subarrays = ();
    # while (my @subarray = splice @users_id, 0, 200) {
    #   push(@subarrays, \@subarray);
    # }

    # foreach my $subarray_users (@subarrays) {
    #   $Service_api->renew_subscription($subarray_users);
    #   sleep 1;
    # }
  }
}

1;
