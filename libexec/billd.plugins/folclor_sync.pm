=head1 NAME

 billd plugin

 DESCRIBE:  Folclor - Sync users and update balance

 Arguments:

=cut

use strict;
use warnings;
use Iptv::Microimpuls;
use Iptv;
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

folclor_sync();

#**********************************************************
=head2 folclor_sync($attr)

=cut
#**********************************************************
sub folclor_sync {

  my %PARAMS = ();
  my $user_deposit = '';
  require Users;
  Users->import();

  my $Users = Users->new($db, $Admin, \%conf);

  if ($argv->{SERVICE_ID}) {
    $PARAMS{ID} = $argv->{SERVICE_ID};
  }

  my $service_list = $Iptv->services_list({
    NAME      => '_SHOW',
    LOGIN     => '_SHOW',
    PASSOWRD  => '_SHOW',
    MODULE    => 'Folclor',
    COLS_NAME => 1,
    %PARAMS
  });

  foreach my $service (@$service_list) {
    if ($debug > 3) {
      print "Service ID: $service->{id} NAME: $service->{name}\n";
    }

    my $Folclor_api = tv_load_service('', { SERVICE_ID => $service->{id} });
    my $Users_list = $Iptv->user_list({
      SERVICE_ID    => $service->{id},
      LOGIN         => '_SHOW',
      TP_ID         => '_SHOW',
      PIN           => '_SHOW',
      TP_FILTER     => '_SHOW',
      PASSWORD      => '_SHOW',
      SUBSCRIBE_ID  => '_SHOW',
      COLS_NAME     => 1,
      PAGE_ROWS     => 99999,
    });

    foreach my $user (@$Users_list) {
      if ($user->{subscribe_id}) {
        $user_deposit = $Users->info($user->{uid});
        if ($Users->{TOTAL}) {
          $Folclor_api->user_balance({
            SUBSCRIBE_ID => $user->{subscribe_id},
            ID           => $user->{uid},
            AMOUNT       => sprintf("%.2f",$user_deposit->{DEPOSIT}),
          });
        }
      }
    }
  }

  return 1;
}