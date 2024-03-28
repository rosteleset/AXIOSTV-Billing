=head1 NAME

 billd plugin

 DESCRIBE:  Iptv sync plugin

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

my %Tv_services = ();

our $Iptv = Iptv->new($db, $Admin, \%conf);
require Iptv::Services;

screen_sync();

#**********************************************************
=head2 screen_sync($attr)

=cut
#**********************************************************
sub screen_sync {

  my $users = $Iptv->user_list({
    SERVICE_ID      => '_SHOW',
    IPTV_LOGIN      => '_SHOW',
    ID              => '_SHOW',
    UID             => '_SHOW',
    LOGIN           => '_SHOW',
    TV_SERVICE_NAME => '_SHOW',
    SUBSCRIBE_ID    => '_SHOW',
    COLS_NAME       => 1,
    COLS_UPPER      => 1,
    PAGE_ROWS       => 65000
  });

  foreach my $user (@{$users}) {
    $Tv_services{$user->{SERVICE_ID}} = tv_load_service('', { SERVICE_ID => $user->{SERVICE_ID} }) if !$Tv_services{$user->{SERVICE_ID}};

    next if !$Tv_services{$user->{SERVICE_ID}};
    next if !$Tv_services{$user->{SERVICE_ID}}->can('screen_sync');

    my $service_screens = $Tv_services{$user->{service_id}}->screen_sync($user);
    my $user_screens = $Iptv->users_screens_list({
      TP_ID            => $user->{TP_ID},
      NUM              => '_SHOW',
      CID              => '_SHOW',
      SERIAL           => '_SHOW',
      USERS_SERVICE_ID => $user->{ID},
      COLS_NAME        => 1,
      COLS_UPPER       => 1,
      SHOW_ASSIGN      => 1
    });

    my %user_screens_hash = ();
    foreach my $screen (@{$user_screens}) {
      $user_screens_hash{$screen->{CID}} = { CID => $screen->{CID}, SERIAL => $screen->{SERIAL} };
    }
    _check_screens(\%user_screens_hash, $service_screens, $user);
  }
}

#**********************************************************
=head2 _check_screens($attr)

=cut
#**********************************************************
sub _check_screens {
  my ($user_screens, $service_screens, $attr) = @_;

  return 0 if ref $service_screens ne 'HASH' || ref $user_screens ne 'HASH';
  return 0 if !$attr->{ID} || !$attr->{TP_ID};

  $attr->{LOGIN} ||= '';
  my %screens_only_on_service = ();
  my %screens_only_on_billing = ();

  foreach my $user_screen (keys %{$user_screens}) {
    $screens_only_on_billing{$user_screen} = $user_screens->{$user_screen} if !$service_screens->{$user_screen};
  }

  foreach my $service_screen (keys %{$service_screens}) {
    $screens_only_on_service{$service_screen} = $service_screens->{$service_screen} if !$user_screens->{$service_screen};
  }

  my $next_screen = $Iptv->users_next_screen({ SERVICE_ID => $attr->{ID}, TP_ID => $attr->{TP_ID} });
  foreach my $screen (keys %screens_only_on_service) {
    if (!$next_screen->{num}) {
      _log('LOG_INFO', "Login: $attr->{LOGIN}. Screen: $screen. Can't create screen. Tariff plan does not have enough screens");
      next;
    }

    $Iptv->users_screens_add({ %{$screens_only_on_service{$screen}},
      SCREEN_ID  => $next_screen->{num},
      SERVICE_ID => $attr->{ID},
      UID        => $attr->{UID},
    });

    if (!$Iptv->{errno}) {
      _log('LOG_INFO', "Login: $attr->{LOGIN}. Screen created: $screen.");
      $next_screen = $Iptv->users_next_screen({ SERVICE_ID => $attr->{ID}, TP_ID => $attr->{TP_ID} });
    }
    else {
      _log('LOG_INFO', "Login: $attr->{LOGIN}. Error screen create: $screen.");
    }
  }

  foreach my $screen (keys %screens_only_on_billing) {
    _log('LOG_INFO', "Login: $attr->{LOGIN}. Service id: $attr->{ID}. Screen: $screen exist only in billing!");
  }
}

1;