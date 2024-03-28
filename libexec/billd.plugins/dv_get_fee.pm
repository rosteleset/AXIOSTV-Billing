=head1 NAME

   dv_get_fee();

   Activate "too small deposit"

=cut

use strict;
use warnings FATAL => 'all';

our $html = AXbills::HTML->new( { CONF => \%conf } );
our (
  $db,
  $admin,
  $Admin,
  %conf,
  %lang,
  $Internet,
  $debug,
  %LIST_PARAMS,
  $argv
);

$admin = $Admin;
#$admin->{SESSION_IP}='127.0.0.2';

$LIST_PARAMS{PAGE_ROWS} = $argv->{PAGE_ROWS} || 1000000;
$LIST_PARAMS{LOGIN} = $argv->{LOGIN} if ($argv->{LOGIN});
do $libpath . "language/$conf{default_language}.pl";
require AXbills::Misc;

dv_get_fee();

#**********************************************************
=head2 dv_get_fee();

=cut
#**********************************************************
sub dv_get_fee {

  if($debug > 1) {
    print "dv_get_fee\n";
    if($debug > 6) {
      $Internet->{debug}=1;
    }
  }

  my $dv_list = $Internet->user_list({
    LOGIN     => '_SHOW',
    DEPOSIT   => '_SHOW',
    CREDIT    => '_SHOW',
    TP_CREDIT => '_SHOW',
    MONTH_FEE => '>0',
    DV_STATUS => 5,
    COLS_NAME => 1,
    PAGE_ROWS => 10000000,
    %LIST_PARAMS
  });

  foreach my $u (@$dv_list) {
    my $uid = $u->{uid};
    if($debug > 1) {
      print "UID: $uid ";
      print "LOGIN: $u->{login} DEPOSIT: $u->{deposit} CREDIT: $u->{credit} STATUS: $u->{dv_status} MONTH_FEE: $u->{month_fee}\n";
    }

    my $credit = ($u->{tp_credit} > 0 ) ? $u->{tp_credit} : $u->{credit};

    if($u->{deposit} + $credit > $u->{month_fee}) {
      $Internet->change(
        {
          UID    => $uid,
          STATUS => 0
        }
      );
      $user = undef;
      service_get_month_fee($Internet, {
        QUITE    => 1,
        #SHEDULER => 1,
        DATE     => $DATE,
        #DEBUG    => 0
      });

      print "  UID: $uid Changed\n";
    }
  }

  return 1;
}

1;
