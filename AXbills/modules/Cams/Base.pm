package Cams::Base;

use strict;
use warnings FATAL => 'all';

my ($admin, $CONF, $db);
my $json;
my AXbills::HTML $html;
my $lang;
my $Cams;

use AXbills::Base qw/days_in_month in_array/;

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

  require Cams;
  Cams->import();
  $Cams = Cams->new($db, $admin, $CONF);

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 cams_payments_maked($attr) - Cross module payment maked

=cut
#**********************************************************
sub cams_payments_maked {
  my $self = shift;
  my ($attr) = @_;

  my $user = $attr->{USER_INFO};
  my $form = $attr->{FORM} || {};

  my $list = $Cams->users_list({
    UID            => $user->{UID},
    SERVICE_STATUS => '_SHOW',
    SERVICE_ID     => '_SHOW',
    ID             => '_SHOW',
    COLS_NAME      => 1,
  });

  return 0 if $Cams->{TOTAL} < 1;

  ::load_module('Cams', $html);

  my $users_disable = $main::users->{DISABLE};
  foreach my $service_user (@{$list}) {
    $service_user->{status} = $service_user->{service_status};
    my $cams_service_info = $Cams->services_info($service_user->{service_id});
    my $cams_info_ = $Cams->_info($service_user->{id});

    if ($form->{newpassword}) {
      ::cams_account_action({
        %{($Cams && ref $Cams eq 'HASH') ? $Cams : {}},
        NEW_PASSWORD => $form->{newpassword},
        change       => 1,
        USER_INFO    => $user,
        SILENT       => 1,
        MODULE       => $cams_service_info->{MODULE} || "",
        SERVICE_ID   => $service_user->{service_id}
      });

      next;
    }

    next if defined $service_user->{status} && $service_user->{status} != 5;
    next 0 if !$cams_info_->{TP_ID};

    if ($form->{DISABLE} && !$users_disable) {
      $Cams->{STATUS} = 1;
      ::cams_account_action({
        %{($Cams && ref $Cams eq 'HASH') ? $Cams : {}},
        change    => 1,
        USER_INFO => $user,
        STATUS    => 1,
        SILENT    => 1,
        MODULE    => $cams_service_info->{MODULE} || "",
      });
    }
    else {
      ::cams_user_activate($Cams, {
        %{$cams_info_},
        USER       => $user,
        SILENT     => 0,
        MODULE     => $cams_service_info->{MODULE} || "",
        REACTIVATE => $users_disable ? 1 : 0,
        MODULE     => $cams_service_info->{MODULE} || "",
        SERVICE_ID => $service_user->{service_id}
      });
    }
  }

  return 1;
}

#**********************************************************
=head cams_quick_info($attr) - Quick information

  Arguments:
    $attr
      UID
      LOGIN

=cut
#**********************************************************
sub cams_quick_info {
  my $self = shift;
  my ($attr) = @_;

  my $result;
  my $form = $attr->{FORM} || {};

  my $uid = $attr->{UID} || $form->{UID};

  if ($attr->{GET_PARAMS}) {
    return {
      HEADER    => $lang->{CAMERAS},
      QUICK_TPL => 'cams_qi_box',
      FIELDS    => {
        TP_NAME     => $lang->{TARIF_PLAN},
        STATUS      => $lang->{STATUS},
        MONTH_FEE   => $lang->{MONTH_FEE},
        TP_COMMENTS => $lang->{COMMENTS},
      }
    };
  }

  if ($attr->{UID}) {
    my $user_info = $Cams->user_info($uid);
    return {} if $Cams->{TOTAL} < 1;

    my $service_status = ::sel_status({ HASH_RESULT => 1 });
    $user_info->{STATUS} = defined($user_info->{SERVICE_STATUS}) ? $service_status->{ $user_info->{SERVICE_STATUS} } : '';
    ($user_info->{STATUS}, undef) = split(':', $user_info->{STATUS});

    return $user_info;
  }

  my $fn_name = $main::functions{$attr->{FN_INDEX} || ''} || 0;
  return 0 if !$fn_name;

  if ($fn_name eq 'cams_user') {
    $Cams->_list({
      UID         => $uid,
      LOGIN       => (!$uid && $attr->{LOGIN}) ? $attr->{LOGIN} : '_SHOW',
      TP_NAME     => '_SHOW',
      MONTH_FEE   => '_SHOW',
      CID         => '_SHOW',
      TP_COMMENTS => '_SHOW',
      STATUS      => '_SHOW',
      IP          => '_SHOW',
      COLS_NAME   => 1,
      COLS_UPPER  => 1
    });
    return $Cams->{TOTAL} < 1 ? 0 : $Cams->{TOTAL};
  }

  return 0 if !$uid;

  $Cams->user_total_cameras($uid);
  return $Cams->{TOTAL} && $Cams->{TOTAL} < 1 ? 0 : $Cams->{TOTAL}
}

#**********************************************************
=head2 cams_docs($attr) - get services for invoice

  Arguments:
    UID
  Results:

=cut
#**********************************************************
sub cams_docs {
  my $self = shift;
  my ($attr) = @_;

  my $uid = $attr->{UID};
  my @services = ();
  my %info = ();

  my $list = $Cams->_list({
    UID             => $uid,
    ACCOUNT_DISABLE => 0,
    ACTIVATE        => '_SHOW',
    EXPIRE          => '_SHOW',
    TP_ID           => '_SHOW',
    STATUS          => '_SHOW',
    COLS_NAME       => 1,
  });

  foreach my $service_info (@{$list}) {
    my $tp_info = $Cams->tp_list({ COLS_NAME => 1, TP_ID => $service_info->{tp_id}, SHOW_ALL_COLUMNS => 1 });

    next unless $Cams->{TOTAL} || defined($tp_info->[0]{month_fee});

    next if $tp_info->[0]{month_fee} <= 0;

    my %FEES_DSC = (
      MODULE          => "Cams",
      SERVICE_NAME    => $lang->{CAMERAS},
      TP_ID           => $tp_info->[0]{tp_id},
      TP_NAME         => $tp_info->[0]{name},
      FEES_PERIOD_DAY => $lang->{MONTH_FEE_SHORT},
    );

    $info{service_name} = ::fees_dsc_former(\%FEES_DSC);
    $info{service_desc} = q{};
    $info{tp_name} = $tp_info->[0]{tp_name};
    $info{service_activate} = $service_info->{activate};
    $info{service_expire} = $service_info->{expire};
    $info{status} = $service_info->{status};
    $info{day} = $tp_info->[0]{day_fee};
    $info{month} = $tp_info->[0]{month_fee};

    if ($service_info->{status} && $service_info->{status} != 5 && $attr->{SKIP_DISABLED}) {
      $info{day} = 0;
      $info{month} = 0;
      $info{abon_distribution} = 0;
    }

    if ($attr->{FULL_INFO}) {
      push @services, { %info };
    }
    else {
      push @services, ::fees_dsc_former(\%FEES_DSC) . "||$tp_info->[0]{month_fee}||$tp_info->[0]{name}";
    }
  }

  return \%info if $attr->{FEES_INFO};

  return \@services;
}

1;