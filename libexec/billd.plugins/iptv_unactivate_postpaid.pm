=head1 NAME

   iptv_unactive_postpaid();

=head1 HELP

  TP_ID=
  SUM=
  LOGIN=

=cut

use strict;
use warnings;

our (
  $Admin,
  $db,
  %conf,
  $argv,
  $debug,
);

use Iptv;
use Tariffs;

my $Iptv = Iptv->new($db, $Admin, \%conf);
my $Tariffs = Tariffs->new($db, \%conf, $Admin);

iptv_unactive_postpaid();

#**********************************************************
=head2 iptv_unactive_postpaid()

=cut
#**********************************************************
sub iptv_unactive_postpaid {

  if ($debug > 1) {
    print "iptv_unactivate_postpaid\n";
    if ($debug > 6) {
      $Iptv->{debug} = 1;
      $Tariffs->{debug} = 1;
    }
  }

  if ($argv->{TP_ID}) {
    $LIST_PARAMS{INNER_TP_ID} = $argv->{TP_ID};
  }

  if ($argv->{LOGIN}) {
    $LIST_PARAMS{LOGIN} = $argv->{LOGIN};
  }

  my $sum = 0;
  if ($argv->{SUM}) {
    $sum = $argv->{SUM};
  }

  my $tp_list = $Tariffs->list({
    TP_ID                => '_SHOW',
    POSTPAID_MONTHLY_FEE => 1,
    ABON_DISTRIBUTION    => '_SHOW',
    MONTH_FEE            => '>=0',
    ID                   => '_SHOW',
    %LIST_PARAMS,
    COLS_NAME            => 1,
  });

  foreach my $tp (@$tp_list) {
    if ($debug > 1) {
      print "TP_ID: $tp->{tp_id} MONTH_FEE: $tp->{month_fee}\n";
    }

    my $month_fee = $tp->{month_fee};

    my $iptv_list = $Iptv->user_list({
      IPTV_ACTIVATE => '_SHOW',
      LOGIN         => '_SHOW',
      DEPOSIT       => '_SHOW',
      CREDIT        => '_SHOW',
      TP_CREDIT     => '_SHOW',
      REDUCTION     => '_SHOW',
      MONTH_FEE     => '>=0',
      TP_ID         => $tp->{tp_id},
      SERVICE_STATUS=> 0,
      COLS_NAME     => 1,
      PAGE_ROWS     => 10000000,
      %LIST_PARAMS
    });

    foreach my $tp_user (@$iptv_list) {
      my $uid = $tp_user->{uid};
      my $deposit = $tp_user->{deposit} || 0;
      my $sum_ = ($sum) ? $sum : -$month_fee * ( 100 - $tp_user->{reduction} ) / 100;
      if ($deposit <= $sum_) {
        if ($debug > 1) {
          print "UID: $uid ";
        }

        if ($debug < 6) {
          $Iptv->user_change({
            UID    => $uid,
            STATUS => 5,
            ID     => $tp_user->{id}
          });
        }

        print "UID: $uid status 5 \n";
      }
    }
  }

  return 1;
}

1;
