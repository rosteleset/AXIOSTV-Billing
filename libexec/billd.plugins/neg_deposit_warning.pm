#**********************************************************
=head1 NAME

  billd plugin

  DESCRIBE: Check run programs and run if they shutdown

=cut
#**********************************************************

use strict;
use warnings FATAL => 'all';
use AXbills::Base qw(days_in_month cmd);
our(
  $argv,
  %conf,
  $debug,
  $Nas,
  $Internet,
  $Sessions,
  $OS
);

require Internet::Negative_deposit;

neg_deposit_warning();


#**********************************************************
=head2 neg_deposit_warning()

=cut
#**********************************************************
sub neg_deposit_warning {
  #my ($attr)=@_;
  print "neg_deposit_warning\n" if ($debug > 1);

  if ($debug > 7) {
    $Nas->{debug}= 1 ;
    $Internet->{debug} = 1 ;
    $Sessions->{debug}=1;
  }
  
  my $custom_rules;
  if ($argv->{DEPOSIT}) {
  	$LIST_PARAMS{DEPOSIT}=$argv->{DEPOSIT};
  	$custom_rules=1;
  }

  if ($argv->{CREDIT}) {
  	$LIST_PARAMS{CREDIT}=$argv->{CREDIT};
  	$custom_rules=1;
  }
  my $redirected = 0;
  $Sessions->online({
    USER_NAME      => '_SHOW',
    NAS_PORT_ID    => '_SHOW',
    CONNECT_INFO   => '_SHOW',
    TP_ID          => '_SHOW',
    SPEED          => '_SHOW',
    JOIN_SERVICE   => '_SHOW',
    CLIENT_IP      => '_SHOW',
    DURATION_SEC   => '_SHOW',
    STARTED        => '_SHOW',
    CID            => '_SHOW',
    DEPOSIT        => '_SHOW',
    CREDIT         => '_SHOW',
    PAYMENT_METHOD => '_SHOW',
    GUEST          => '_SHOW',
    NAS_ID         => $LIST_PARAMS{NAS_IDS},
    TP_CREDIT      => '_SHOW',
    TP_MONTH_FEE   => '_SHOW',
    TP_DAY_FEE     => '_SHOW',
    TP_ABON_DISTRIBUTION => '_SHOW',
    #STATUS         => '1;2;3',
    %LIST_PARAMS,
  });

  if ($Sessions->{errno}) {
  	print "Error: $Sessions->{errno} $Sessions->{errstr}\n";
  }

  #my $online      = $sessions->{nas_sorted};
  foreach my $online_info (@{ $Sessions->{list} }) {
    if ($debug > 1) {
      print "Login: $online_info->{user_name} IP: $online_info->{client_ip} DEPOSIT: $online_info->{deposit} CREDIT: $online_info->{credit}\n";
    }

    if($argv->{DAYS2FINISH}) {
      $custom_rules=0;
      my $day2finish = $argv->{DAYS2FINISH};
      my $day_fee = $online_info->{tp_day_fee} || 0;
      if($online_info->{tp_month_fee} && $online_info->{tp_month_fee} > 0 && $online_info->{tp_abon_distribution}) {
        $day_fee = $online_info->{tp_month_fee} / days_in_month({ DATE => $DATE });
      }

      if($day_fee > 0) {
        my $last_days = $online_info->{deposit} + $online_info->{credit} / $day_fee;
        if($last_days > $day2finish) {
          next;
        }
        print "$online_info->{user_name} Days to new period: $last_days\n" if ($debug > 2);
        $custom_rules=1;
      }
    }

    if (($online_info->{deposit} + $online_info->{credit} <= 0 && $online_info->{payment_type} == 0) || $custom_rules) {
      print "Redirected\n" if ($debug > 1);
    	mk_redirect({ IP => $online_info->{client_ip} });
      $redirected++;
    }
  }

  if ($debug> 0) {
  	print "Total: $Sessions->{TOTAL}\n";
    print "Redirected: $redirected\n";
  }

  return 1;
}


1
