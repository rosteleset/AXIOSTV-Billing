=head1 NAME

 billd plugin

 DESCRIBE:  Smotreshka - load customers id

 Arguments:

=cut

use strict;
use warnings;
use Iptv;
use Iptv::Smotreshka;
use Tariffs;
use AXbills::Base qw(load_pmodule in_array _bp);
use threads;
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

smotreshka_users();

#**********************************************************
=head2 smotreshka_users($attr)

=cut
#**********************************************************
sub smotreshka_users {

  my $service_list = $Iptv->services_list({
    NAME      => '_SHOW',
    LOGIN     => '_SHOW',
    PASSOWRD  => '_SHOW',
    MODULE    => 'Smotreshka',
    COLS_NAME => 1,
  });

  foreach my $service (@$service_list) {
    if ($debug > 3) {
      print "Service ID: $service->{id} NAME: $service->{name}\n";
    }

    my $Smotreshka_api = tv_load_service('', { SERVICE_ID => $service->{id} });
    my $result = $Smotreshka_api->user_list();
    my %users_info = ();
    foreach my $user (@{$result}) {
      $users_info{$user->{username}} = $user->{id};
    }

    my $bill_users = $Iptv->user_list({
      SERVICE_ID => $service->{id},
      IPTV_LOGIN => '_SHOW',
      ID         => '_SHOW',
      UID        => '_SHOW',
      LOGIN      => '_SHOW',
      COLS_NAME  => 1,
      PAGE_ROWS  => 65000
    });

    foreach my $bill_user (@{$bill_users}) {
      if ($bill_user->{iptv_login} && $users_info{$bill_user->{iptv_login}}) {
        $Iptv->user_change({
          ID           => $bill_user->{id},
          SUBSCRIBE_ID => $users_info{$bill_user->{iptv_login}},
        });

        if ($debug > 0) {
          print "Login: $bill_user->{login} Smotreshka id: $users_info{$bill_user->{iptv_login}}\n";
        }
      }
    }
  }
}

1;