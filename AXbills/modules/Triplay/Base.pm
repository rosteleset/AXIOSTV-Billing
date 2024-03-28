package Triplay::Base;

use strict;
use warnings FATAL => 'all';

my ($admin, $CONF, $db);
my $json;
my AXbills::HTML $html;
my $lang;
my $Triplay;

use AXbills::Base qw/days_in_month in_array next_month/;

#**********************************************************
=head2 new($html, $lang)

=cut
#**********************************************************
sub new {
  my $class = shift;
  $db = shift;
  $admin = shift;
  $CONF = shift;
  my $attr = shift;

  $html = $attr->{HTML} if $attr->{HTML};
  $lang = $attr->{LANG} if $attr->{LANG};

  my $self = {};

  require Triplay;
  Triplay->import();
  $Triplay = Triplay->new($db, $admin, $CONF);

  bless($self, $class);

  return $self;
}

#**********************************************************
=head triplay_quick_info($attr) - Quick information

  Arguments:
    $attr
      UID

  Return:

=cut
#**********************************************************
sub triplay_quick_info {
  my $self = shift;
  my ($attr) = @_;

  my $result;
  my $form = $attr->{FORM} || {};
  my $uid = $attr->{UID} || $form->{UID};

  if ($attr->{UID}) {
    my $list = $Triplay->user_list({
      UID        =>  $uid,
      TP_NAME    => '_SHOW',
      MONTH_FEE  => '_SHOW',
      CID        => '_SHOW',
      TP_COMMENTS=> '_SHOW',
      INTERNET_STATUS => '_SHOW',
      INTERNET_STATUS_ID => '_SHOW',
      COLS_NAME  => 1,
      COLS_UPPER => 1
    });

    $result = $list->[0];
    my $service_status = ::sel_status({ HASH_RESULT => 1 });
    $result->{STATUS} = (defined($result->{DISABLE})) ? $service_status->{ $result->{DISABLE} } : '';
    ($result->{STATUS}, undef) = split(/:/, $result->{STATUS});
    return $result;
  }
  elsif($attr->{GET_PARAMS}) {
    $result = {
      HEADER    => 'Triplay',
      QUICK_TPL => 'triplay_qi_box',
      FIELDS => {
        TP_NAME     => $lang->{TARIF_PLAN},
        STATUS      => $lang->{STATUS},
        MONTH_FEE   => $lang->{MONTH_FEE},
        TP_COMMENTS => $lang->{COMMENTS},
      }
    };

    return $result;
  }

  $Triplay->user_list({ UID => $uid });

  return ($Triplay->{TOTAL}) ? $Triplay->{TOTAL} : '';
}

#**********************************************************
=head2 triplay_docs($attr) - get services for invoice

  Arguments:
    UID
    FEES_INFO
    SKIP_DISABLED
    FULL_INFO

  Returns:


=cut
#**********************************************************
sub triplay_docs {
  my $self = shift;
  my ($attr) = @_;

  my $form = $attr->{FORM} || {};
  my $uid      = $attr->{UID} || $form->{UID};
  my @services = ();
  my %info     = ();

  my $service_list = $Triplay->user_list({
    UID              => $uid,
    MONTH_FEE        => '_SHOW',
    DAY_FEE          => '_SHOW',
    SERVICE_STATUS   => '_SHOW',
    ABON_DISTRIBUTION=> '_SHOW',
    TP_NAME          => '_SHOW',
    FEES_METHOD      => '_SHOW',
    TP_ID            => '_SHOW',
    TP_NUM           => '_SHOW',
    TP_FIXED_FEES_DAY=> '_SHOW',
    TP_REDUCTION_FEE => '_SHOW',
    COLS_NAME        => 1
  });

  if ($attr->{FEES_INFO} || $attr->{FULL_INFO}) {
    foreach my $service_info ( @{ $service_list } ) {
      my %FEES_DSC = (
        MODULE          => 'Triplay',
        SERVICE_NAME    => 'Triplay',
        TP_ID           => $service_info->{tp_id},
        TP_NAME         => $service_info->{tp_name},
        FEES_PERIOD_DAY => $lang->{MONTH_FEE_SHORT},
        FEES_METHOD     => $service_info->{fees_method} ? $main::FEES_METHODS{$service_info->{fees_method}} : undef,
      );

      $info{service_name}      = ::fees_dsc_former(\%FEES_DSC);
      $info{service_desc}      = q{};
      $info{tp_name}           = $service_info->{tp_name};
      $info{tp_fixed_fees_day} = $service_info->{tp_fixed_fees_day} || 0;
      $info{status}            = $service_info->{service_status};
      $info{tp_reduction_fee}  = $service_info->{tp_reduction_fee};
      $info{module_name}       = 'Triplay';

      if ($service_info->{service_status} && $service_info->{service_status} != 5 && $attr->{SKIP_DISABLED}) {
        $info{day} = 0;
        $info{month} = 0;
        $info{abon_distribution} = 0;
      }
      else {
        if ($service_info->{personal_tp} && $service_info->{personal_tp} > 0) {
          $info{day}   = $service_info->{day_fee};
          $info{month} = $service_info->{personal_tp};
          $info{abon_distribution} = $service_info->{abon_distribution};
        }
        else {
          $info{day} = $service_info->{day_fee};
          $info{month} = $service_info->{month_fee};
          $info{abon_distribution} = $service_info->{abon_distribution};
        }
      }

      return \%info if !$attr->{FULL_INFO};

      push @services, { %info };
    }
  }

  return \@services if $attr->{FULL_INFO} || $Triplay->{TOTAL} < 1;

  foreach my $service_info ( @$service_list ) {
    next if $service_info->{service_status} && $service_info->{service_status} != 5 && !$attr->{SHOW_ALL};

    if ($service_info->{month_fee} && $service_info->{month_fee} > 0) {
      my %FEES_DSC = (
        MODULE          => 'Triplay',
        TP_ID           => $service_info->{tp_id},
        TP_NAME         => $service_info->{tp_name},
        FEES_PERIOD_DAY => $lang->{MONTH_FEE_SHORT},
        FEES_METHOD     => $service_info->{fees_method} ? $main::FEES_METHODS{$service_info->{fees_method}} : undef,
      );

      #Fixme / make hash export
      push @services, ::fees_dsc_former(\%FEES_DSC) . "||$service_info->{month_fee}||$service_info->{tp_name}"
        ."|||$service_info->{service_status}";
    }

    if ($service_info->{day_fee} && $service_info->{day_fee} > 0) {
      my $days_in_month = days_in_month({ DATE => next_month({ DATE => $main::DATE }) });
      push @services, "Triplay: $lang->{MONTH_FEE_SHORT}: $service_info->{tp_name} ($service_info->{tp_id})|$days_in_month $lang->{DAY}|"
        . sprintf("%.2f", ($service_info->{day_fee} * $days_in_month)) . "||$service_info->{tp_name}"
        . "||";
    }
  }

  return \@services;
}

#**********************************************************
=head2 triplay_payments_maked($attr) - Cross module payment maked

  Arguments:
    $attr
      USER_INFO
      SUM

=cut
#**********************************************************
sub triplay_payments_maked {
  my $self = shift;
  my ($attr) = @_;

  my $user = $attr->{USER_INFO} if $attr->{USER_INFO};

  $Triplay->user_info({ UID  => $user->{UID}, });

  return 1 if !$Triplay->{UID};

  $Triplay->{MONTH_ABON} //= 0;
  $Triplay->{DAY_ABON} //= 0;

  my $deposit = (defined($user->{DEPOSIT})) ? $user->{DEPOSIT} + (($user->{CREDIT}) ? $user->{CREDIT} : ($Triplay->{TP_CREDIT} ||0)) : 0;
  my $abon_fees = (! $user->{REDUCTION}) ? $Triplay->{MONTH_ABON} + $Triplay->{DAY_ABON} :
    ($Triplay->{MONTH_ABON} + $Triplay->{DAY_ABON}) * (100 - $user->{REDUCTION}) / 100;

  if (in_array($Triplay->{DISABLE}, [4,5]) && $deposit > $abon_fees) {
    my %params = ();
    $Triplay->user_change({
      UID    => $user->{UID},
      ID     => $Triplay->{ID},
      DISABLE=> 0,
      %params
    });

    ::service_get_month_fee($Triplay, { %$attr, SERVICE_NAME => 'Triplay', MODULE => 'Triplay' });
  }

  return 1;
}

1;