=head1 NAME

 billd plugin

 DESCRIBE:  Microimpuls - load customers

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

microimpuls_online();


#**********************************************************
=head2 stalker_online($attr)

=cut
#**********************************************************
sub microimpuls_online {

  my %PARAMS = ();

  if ($argv->{SERVICE_ID}) {
    $PARAMS{ID} = $argv->{SERVICE_ID};
  }

  my $service_list = $Iptv->services_list({
    NAME      => '_SHOW',
    LOGIN     => '_SHOW',
    PASSOWRD  => '_SHOW',
    MODULE    => 'Microimpuls',
    COLS_NAME => 1,
    %PARAMS
  });

  foreach my $service (@$service_list) {
    if ($debug > 3) {
      print "Service ID: $service->{id} NAME: $service->{name}\n";
    }

    my $Microimpuls_api = tv_load_service('', { SERVICE_ID => $service->{id} });
    if ($argv->{PASSWORD_CHANGE}) {
      change_users_password($service->{id}, $Microimpuls_api);
      return 1;
    }
    synchronization_tariffs($service->{id}, $Microimpuls_api);
  }

  return 1;
}

#**********************************************************
=head2 synchronization_tariffs($attr)

  Arguments:
    $attr

  Results:

=cut
#**********************************************************
sub synchronization_tariffs {

  my $Service_id = shift;
  my $Microimpuls_api = shift;

  my %Current_tarrifs = ();
  my $Micro_tariffs = '';
  my @Tarrifs = ();
  my %Billing_tarrifs = ();

  my $Users = $Iptv->user_list({
    SERVICE_ID    => $Service_id,
    TP_ID         => '_SHOW',
    PIN           => '_SHOW',
    TP_FILTER     => '_SHOW',
    PASSWORD      => '_SHOW',
    COLS_NAME     => 1,
    PAGE_ROWS     => 99999,
  });

  foreach my $User (@$Users) {
    if ($User->{tp_id}) {
      $Micro_tariffs = $Microimpuls_api->user_info({
        ext_id    => $User->{uid},
        client_id => $conf{MICROIMPULS_CLIENT_ID} || 0,
      });

      if ($Micro_tariffs->{RESULT}{results}[0]{error} eq '1') {
        print "Add user - $User->{uid}...\n";
        $Micro_tariffs = $Microimpuls_api->user_add({
          TP_ID        => $User->{tp_id},
          UID          => $User->{uid},
          password     => $User->{password} || '',
          PIN          => $User->{pin},
          TP_FILTER_ID => $User->{filter_id},
          BILLD        => 1,
        });
      }
      else {
        @Tarrifs = $Micro_tariffs->{RESULT}{results}[0]{tariffs};

        if (!in_array($User->{filter_id}, \@Tarrifs)) {
          $Microimpuls_api->_customer_tariff_assign({
            tariff_id => $User->{filter_id} || 0,
            ext_id    => $User->{uid} || 0,
          });
        }

        if (!$Billing_tarrifs{$User->{uid}}) {
          my $User_tarrifs = $Iptv->user_list({
            SERVICE_ID => $Service_id,
            UID        => $User->{uid},
            TP_FILTER  => '_SHOW',
            COLS_NAME  => 1
          });

          my @tarrifs = ();
          $Billing_tarrifs{$User->{uid}} = "1";
          foreach my $tarrif (@$User_tarrifs) {
            push @tarrifs, $tarrif->{filter_id};
          }

          $Current_tarrifs{$User->{uid}} = \@tarrifs;

          foreach my $tarrif (@Tarrifs) {
            foreach my $tarrif_1 (@$tarrif) {
              if (!in_array($tarrif_1, \@tarrifs)) {
                $Microimpuls_api->_customer_tariff_remove({
                  tariff_id => $tarrif_1 || 0,
                  ext_id    => $User->{uid} || 0,
                });
              }
            }
          }
        }
      }
    }
  }

  return 1;
}

#**********************************************************
=head2 synchronization_tariffs($attr)

  Arguments:
    $attr

  Results:

=cut
#**********************************************************
sub change_users_password {

  my $Service_id = shift;
  my $Microimpuls_api = shift;

  my $Users = $Iptv->user_list({
    SERVICE_ID    => $Service_id,
    TP_ID         => '_SHOW',
    PIN           => '_SHOW',
    UID           => $argv->{UID} || '_SHOW',
    TP_FILTER     => '_SHOW',
    PASSWORD      => '_SHOW',
    COLS_NAME     => 1,
    PAGE_ROWS     => 99999,
  });

  foreach my $User (@$Users) {
    if ($User->{tp_id}) {
      print "Change user password - $User->{uid}...\n";

      $Microimpuls_api->_account_modify_pin({
        password    => $User->{password} || '',
        parent_code => $User->{pin} || '',
        abonement   => $User->{uid} || 0,
      });
    }
  }

  return 1;
}

1;
