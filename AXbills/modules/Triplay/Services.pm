=head2 NAME

  Services

=cut

use strict;
use warnings FATAL => 'all';
use Tariffs;
use Triplay;
#use AXbills::Base;

our (
  $db,
  %conf,
  %lang,
  $admin,
  %permissions
);

our AXbills::HTML $html;
my $Triplay = Triplay->new($db, $admin, \%conf);
our $Tariffs = Tariffs->new($db, \%conf, $admin);

#**********************************************************
=head2 test()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub triplay_users_services {
  my ($attr) = @_;

  my $users_services_list = $Triplay->user_list({
    UID         => $attr->{UID} || '_SHOW',
    #    TP_ID       => '_SHOW',
#    INTERNET_TP => '_SHOW',
#    IPTV_TP     => '_SHOW',
#    VOIP_TP     => '_SHOW',
    INTERNET_NAME => '_SHOW',
    VOIP_NAME => '_SHOW',
    IPTV_NAME => '_SHOW',
    ABONPLATA => '_SHOW',
  });

  result_former({
    INPUT_DATA     => $Triplay,
    LIST           => $users_services_list,
    BASE_FIELDS    => 0,
    DEFAULT_FIELDS => "uid, internet_name, iptv_name, voip_name, abonplata",
    FILTER_COLS    => {
      abonplata => '_triplay_abonplata_count::ABONPLATA'
    },
    #      FUNCTION_FIELDS => 'change, del',
    EXT_TITLES     => {
      'uid'           => 'UID',
      'internet_name' => "Internet",
      'iptv_name'     => "IPTV",
      'voip_name'     => "VOIP",
      'abonplata'     => $lang{ABON}
    },
    TABLE          => {
      width   => '100%',
      caption => "$lang{USERS}",
      qs      => $pages_qs,
      ID      => 'TRIPLAY_USER_SERVICES',
      header  => '',
      EXPORT  => 1,
      #        MENU    => "$lang{ADD}:index=" . get_function_index( 'triplay_main' ) . ':add' . ";",
    },
    MAKE_ROWS      => 1,
    SEARCH_FORMER  => 1,
    MODULE         => 'Triplay',
    TOTAL          => 1
  });

  return 1;
}

#**********************************************************
=head2 _triplay_abonplata_count() - count amount for all triplay services

  Arguments:
     uid  - user identifier
     attr - {

     }

  Returns:
    total_sum - amount of money to pay for all services

  Example:
    my $total_sum = _triplay_abonplata_count(1, {});

=cut
#**********************************************************
sub _triplay_abonplata_count {
  my ($uid) = @_;

  return 'This user has not services  ' if (! $uid);

  my $user_services_information = cross_modules('docs', { UID => $uid });

  my $total_sum = 0;
  if($user_services_information->{Internet}){
    foreach my $internet_service_info (@{ $user_services_information->{Internet} }){
    my (undef, undef, $amount, undef, undef, undef, undef) = split('\|', $internet_service_info);
      $total_sum += $amount;
    }
  }

  if($user_services_information->{Iptv}){
    foreach my $iptv_service_info (@{ $user_services_information->{Iptv} }){
      my (undef, undef, $amount, undef, undef, undef, undef) = split('\|', $iptv_service_info);
      $total_sum += $amount;
    }
  }

  if($user_services_information->{Voip}){
    foreach my $voip_service_info (@{ $user_services_information->{Voip} }){
      my (undef, undef, $amount, undef, undef, undef, undef) = split('\|', $voip_service_info);
      $total_sum += $amount;
    }
  }

  return sprintf('%.2f', $total_sum);
}

1;