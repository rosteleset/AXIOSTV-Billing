package Voip::Base;

use strict;
use warnings FATAL => 'all';

use Voip;
use Voip::Users;

my ($admin, $CONF, $db);
my AXbills::HTML $html;
my $lang;
my Voip $Voip;
my Voip::Users $Voip_users;

use AXbills::Base qw/days_in_month in_array next_month dirname/;

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

  $Voip = Voip->new($db, $admin, $CONF);

  $Voip_users = Voip::Users->new($db, $admin, $CONF, {
    html => $html || {},
    lang => $lang || {}
  });

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 voip_docs($attr) - get services for invoice

  Arguments:
    $attr

  Results:


=cut
#**********************************************************
sub voip_docs {
  my $self = shift;
  my ($attr) = @_;

  my $uid = $attr->{UID};
  my @services = ();
  my %info = ();

  my $list = $Voip->user_list({
    UID             => $uid,
    SERVICE_DISABLE => 0,
    ACCOUN_DISABLE  => 0,
    MONTH_FEE       => '_SHOW',
    DAY_FEE         => '_SHOW',
    TP_ID           => '_SHOW',
    TP_NAME         => '_SHOW',
    FEES_METHOD     => '_SHOW',
    COLS_NAME       => 1
  });

  foreach my $service_info (@{$list}) {
    my %FEES_DSC = (
      MODULE          => "Voip",
      SERVICE_NAME    => 'Voip',
      TP_ID           => $service_info->{tp_id},
      TP_NAME         => $service_info->{tp_name},
      FEES_PERIOD_DAY => $lang->{MONTH_FEE_SHORT}
    );

    if ($attr->{FEES_INFO} || $attr->{FULL_INFO}) {
      $info{service_name} = ::fees_dsc_former(\%FEES_DSC);
      $info{service_desc} = q{};
      $info{tp_name} = $service_info->{tp_name};
      $info{service_activate} = $service_info->{internet_activate};
      $info{tp_fixed_fees_day} = $service_info->{tp_fixed_fees_day} || 0;
      $info{status} = $service_info->{internet_status};

      if ($service_info->{internet_status} && $service_info->{internet_status} != 5 && $attr->{SKIP_DISABLED}) {
        $info{day} = 0;
        $info{month} = 0;
        $info{abon_distribution} = 0;
      }
      else {
        if ($service_info->{personal_tp} && $service_info->{personal_tp} > 0) {
          $info{day} = $service_info->{personal_tp};
          $info{month} = $service_info->{personal_tp};
          $info{abon_distribution} = 0;
        }
        else {
          $info{day} = $service_info->{day_fee};
          $info{month} = $service_info->{month_fee};
          $info{abon_distribution} = $service_info->{abon_distribution};
        }
      }

      return \%info if (!$attr->{FULL_INFO});

      push @services, \%info;
    }
    else {
      next if !defined($service_info->{month_fee});

      if ($service_info->{month_fee} > 0) {
        push @services, ::fees_dsc_former(\%FEES_DSC) . "||$service_info->{month_fee}||$service_info->{tp_name}";
      }

      if ($service_info->{day_fee} && $service_info->{day_fee} > 0) {
        my $next_month = next_month({ DATE => $main::DATE });
        my $days_in_month = days_in_month({ DATE => $next_month });
        push @services,
          "Voip: $lang->{MONTH_FEE_SHORT}: $service_info->{tp_name} ($service_info->{tp_id})|$days_in_month $lang->{DAY}|" . 
            sprintf("%.2f", ($service_info->{day_fee} * $days_in_month)) . "||$service_info->{tp_name}";
      }
    }
  }

  return \%info if $attr->{FEES_INFO};

  return \@services;
}

#**********************************************************
=head voip_quick_info($attr) - Quick information

  Arguments:
    $attr

=cut
#**********************************************************
sub voip_quick_info {
  my $self = shift;
  my ($attr) = @_;

  my $result;
  my $form = $attr->{FORM} || {};
  my $uid = $attr->{UID} || $form->{UID};

  if ($attr->{UID}) {
    my $list = $Voip->user_list({
      UID        => $uid,
      TP_NAME    => '_SHOW',
      MONTH_FEE  => '_SHOW',
      CID        => '_SHOW',
      TP_COMMENTS=> '_SHOW',
      STATUS     => '_SHOW',
      IP         => '_SHOW',
      COLS_NAME  => 1,
      COLS_UPPER => 1
    });

    $result = $list->[0];
    my $service_status = ::sel_status({ HASH_RESULT => 1 });
    $result->{STATUS} = (defined($result->{STATUS})) ? $service_status->{ $result->{STATUS} } : '';

    return $result;
  }
  elsif($attr->{GET_PARAMS}) {
    $result = {
      HEADER    => 'Voip',
      QUICK_TPL => 'voip_qi_box',
      FIELDS => {
        TP_NAME     => $lang->{TARIF_PLAN},
        STATUS      => $lang->{STATUS},
        MONTH_FEE   => $lang->{MONTH_FEE},
        TP_COMMENTS => $lang->{COMMENTS},
      }
    };

    return $result;
  }

  $Voip->user_list({
    UID        => $uid,
    LOGIN      => (! $uid && $attr->{LOGIN}) ? $attr->{LOGIN} : undef,
    TP_NAME    => '_SHOW',
    MONTH_FEE  => '_SHOW',
    CID        => '_SHOW',
    TP_COMMENTS=> '_SHOW',
    STATUS     => '_SHOW',
    IP         => '_SHOW',
    COLS_NAME  => 1,
    COLS_UPPER => 1
  });

  return ($Voip->{TOTAL} > 0) ? $Voip->{TOTAL} : '';
}

#**********************************************************
=head2 voip_payments_maked

=cut
#**********************************************************
sub voip_payments_maked {
  my $self = shift;
  my ($attr) = @_;

  my $form = $attr->{FORM} || {};
  my $user = $attr->{USER_INFO};

  ::load_module('Voip');

  if (!$form->{DISABLE}) {
    $Voip->user_info($user->{UID});

    return 0 if $Voip->{TOTAL} < 1 || !$Voip->{TP_NUM};

    my $deposit = $user->{DEPOSIT} + (($user->{CREDIT} && $user->{CREDIT} > 0) ? $user->{CREDIT} : ($Voip->{TP_CREDIT} || 0 ));
    my $abon_fees = $Voip->{MONTH_ABON} + $Voip->{DAY_ABON};

    if ($user->{REDUCTION} && $user->{REDUCTION} > 0) {
      $abon_fees = $abon_fees * (100 - $user->{REDUCTION}) / 100;
    }

    if ($Voip->{DISABLE} > 1 && $deposit > $abon_fees) {
      $Voip->user_change({
        UID     => $attr->{USER_INFO}->{UID},
        TP_ID   => $Voip->{TP_ID},
        DISABLE => 0
      });

      $Voip->{ACCOUNT_ACTIVATE} = $user->{ACTIVATE} || '0000-00-00';
      ::service_get_month_fee($Voip, $attr);
    }
  }

  if ($CONF->{VOIP_ASTERISK_USERS}) {
    $Voip_users->voip_mk_users_conf($form);
  }

  return 1;
}

1;
