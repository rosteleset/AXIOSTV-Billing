package Internet::Service_mng;

use strict;
use warnings FATAL => 'all';
use AXbills::Base qw(date_diff cmd days_in_month convert in_array);
use Tariffs;
use Shedule;

require AXbills::Misc;
require AXbills::Templates;

our %lang = ();

my $html;
my $DATE;

#***************************************************************
=head2 new($attr)

  Arguments:
    db
    admin
    conf
    lang   - Lang hash

=cut
#***************************************************************
sub new {
  my $class = shift;
  my ($attr) = @_;

  my $self = {
    db    => $attr->{db},
    admin => $attr->{admin},
    conf  => $attr->{conf}
  };

  $html = $attr->{html};

  if ($attr->{lang}) {
    %lang = %{$attr->{lang}};
  }

  if (!$DATE) {
    use POSIX qw(strftime);
    $DATE = strftime "%Y-%m-%d", localtime(time);
  }

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 service_chg_tp($attr)

  Arguments:
    $attr
        Actins
      set
      del

      SERVICE   - [Obj]
      USER      - [Obj]

      UID       -
      PERIOD    -
      DATE      -
      TP_ID     - NEW TP ID
      ACCEPT_RULES - TP chnage confirm

  Results:

=cut
#**********************************************************
sub service_chg_tp {
  my $self = shift;
  my ($attr) = @_;

  my Internet $Service = $attr->{SERVICE};
  my $user = $attr->{USER};
  my $Tariffs = Tariffs->new($self->{db}, $self->{conf}, $self->{admin});

  $self->{USER_INFO} = $user;
  $attr->{USER_INFO} = $user;

  $DATE = $attr->{DATE} if ($attr->{DATE});

  my $allow_tp_change = $self->{conf}->{INTERNET_USER_CHG_TP} || $attr->{INTERNET_USER_CHG_TP};

  if (!$allow_tp_change) {
    $self->{message} = 'NOT_ALLOW';
    $self->{errno} = 140;

    return $self;
  }

  my $uid = $attr->{UID};
  my $service_id = $attr->{ID};

  if (!$Service || ref $Service ne 'Internet') {
    $self->{message} = 'NOT_DEFINED_SERVICE_OBJ';
    $self->{errno} = 141;

    return $self;
  }

  if (!$service_id) {
    $self->{message} = 'NOT_DEFINED_SERVICE_ID';
    $self->{errno} = 142;

    return $self;
  }

  if ($uid && $Service->can('info')) {
    $Service = $Service->user_info($uid,
      {
        ID => $attr->{ID}
      });

    if ($Service->{TOTAL} < 1) {
      $self->{message} = 'SERVICE_NOT_EXIST';
      $self->{errno} = 143;
      return $self;
    }
  }
  else {
    $self->{message} = 'USER_NOT_EXIST';
    $self->{errno} = 144;
    return $self;
  }

  if ($self->{conf}->{FEES_PRIORITY} && $self->{conf}->{FEES_PRIORITY} =~ /bonus/ && $user->{EXT_BILL_DEPOSIT}) {
    $user->{DEPOSIT} += $user->{EXT_BILL_DEPOSIT};
  }

  if ($user->{GID}) {
    #Get user groups
    my $group = $user->group_info($user->{GID});
    if ($group->{DISABLE_CHG_TP}) {
      $self->{message} = 'DISABLE_CHG_TP';
      $self->{errno} = 145;
      return $self;
    }
  }

  #Get TP groups
  $Tariffs->tp_group_info($Service->{TP_GID});

  if (!$Tariffs->{USER_CHG_TP}) {
    $self->{message} = 'NOT_ALLOW_TP_CHANGE';
    $self->{errno} = 146;
    return $self;
  }

  #$Service->{ABON_DATE} = $self->get_next_abon_date();

  if ($attr->{set} && $attr->{ACCEPT_RULES}) {
    if ($user->{CREDIT} + $user->{DEPOSIT} < 0
      && !$Service->{TP_INFO}->{POSTPAID_ABON}
      && !$Service->{TP_INFO}->{PAYMENT_TYPE}) {

      $self->{message} = "$lang{ERR_SMALL_DEPOSIT} - $lang{DEPOSIT}: $user->{DEPOSIT} $lang{CREDIT}: $user->{CREDIT}";
      $self->{errno} = 152;
      return $self;
    }
    # Allow change tp for small deposit status
    elsif ($Service->{STATUS} && $Service->{STATUS} != 5) {
      $self->{message} = "SERVICE_DISABLE";
      $self->{errno} = 153;
      return $self;
    }
    elsif ($user->{DISABLE}) {
      $self->{message} = "ACCOUNT_DISABLE";
      $self->{errno} = 154;
      return $self;
    }

    $self->change_tp({
      SERVICE => $attr->{SERVICE},
      TP_ID   => $attr->{TP_ID},
      %$attr
    });
  }
  elsif ($attr->{del}) {
    my $Shedule = Shedule->new($self->{db}, $self->{admin}, $self->{conf});
    $Shedule->del({
      UID => $uid || '-',
      ID  => $attr->{SHEDULE_ID}
    });

    if (!$Shedule->{errno}) {
      $self->{errno} = 149;
      $self->{message} = 'ERR_NOT_DELETE_SHEDULE';
    }
  }
  else {
    $self->{errno} = 155;
    $self->{message} = 'NOT_DEFINED_ACTION';
  }

  return $self;
}

#**********************************************************
=head2 get_next_abon_date($attr)

  Arguments:
    $attr
      UID       -
      PERIOD    -
      DATE      -
      SERVICE   -
        EXPIRE
        MONTH_ABON
        ABON_DISTRIBUTION
        STATUS


  Results:
    $Service_mng->{ABON_DATE}


=cut
#**********************************************************
sub get_next_abon_date {
  my $self = shift;
  my ($attr) = @_;

  my $start_period_day = $attr->{START_PERIOD_DAY} || $self->{conf}->{START_PERIOD_DAY} || 1;
  my $Service = $attr->{SERVICE};
  my $service_activate = $Service->{ACTIVATE} || $attr->{ACTIVATE} || '0000-00-00';
  my $service_expire = $Service->{EXPIRE} || '0000-00-00';
  my $month_abon = $attr->{MONTH_ABON} || $Service->{MONTH_ABON} || 0;
  my $tp_age = $Service->{TP_INFO}->{AGE} || 0;
  my $service_status = $Service->{STATUS} || 0;
  my $abon_distribution = $Service->{ABON_DISTRIBUTION} || 0;
  my $fixed_fees_day = $Service->{FIXED_FEES_DAY} || $attr->{FIXED_FEES_DAY} || 0;

  if ($attr->{DATE}) {
    $DATE = $attr->{DATE};
  }

  my ($Y, $M, $D) = split(/-/, $DATE, 3);

  $self->{message} = q{};
  $self->{ABON_DATE} = $DATE;

  if ($service_status == 5) {
    $self->{message} = "STATUS_5";
    return;
  }

  if ($service_activate ne '0000-00-00' && $service_expire eq '0000-00-00') {
    ($Y, $M, $D) = split(/-/, $service_activate, 3);
  }

  # Renew expired accounts
  if ($service_expire ne '0000-00-00' && $tp_age > 0) {
    # Renew expire tarif
    if (date_diff($service_expire, $DATE) > 1) {
      my ($NEXT_EXPIRE_Y, $NEXT_EXPIRE_M, $NEXT_EXPIRE_D) = split(/-/, POSIX::strftime("%Y-%m-%d",
        localtime((POSIX::mktime(0, 0, 0, $D, ($M - 1), ($Y - 1900), 0, 0, 0) + $tp_age * 86400))));

      $self->{NEW_EXPIRE} = "$NEXT_EXPIRE_Y-$NEXT_EXPIRE_M-$NEXT_EXPIRE_D";
      $self->{message} = "RENEW EXPIRE";
      return;
    }
    else {
      $self->{ABON_DATE} = $service_expire;
    }
  }
  #Get next abon day
  elsif (!$self->{conf}->{INTERNET_USER_CHG_TP_NEXT_MONTH} && ($month_abon == 0 || $abon_distribution)) {
    ($Y, $M, $D) = split(/-/, POSIX::strftime("%Y-%m-%d", localtime((POSIX::mktime(0, 0, 0, $D, ($M - 1), ($Y - 1900), 0, 0, 0) + 86400))));

    $self->{ABON_DATE} = sprintf("%d-%02d-%02d", $Y, $M, $D);
    $self->{message} = 'MONTH_FEE_0';
  }
  # next month abon period
  elsif ($month_abon > 0) {
    if ($service_activate ne '0000-00-00') {
      if ($fixed_fees_day) {
        $M++;

        if ($M == 13) {
          $M = 1;
          $Y++;
        }

        $self->{ABON_DATE} = sprintf("%d-%02d-%02d", $Y, $M, $D);
        $self->{message} = 'FIXED_DAY';
      }
      else {
        $self->{ABON_DATE} = POSIX::strftime("%Y-%m-%d", localtime((POSIX::mktime(0, 0, 0, $D, ($M - 1), ($Y - 1900),
          0, 0, 0) + 31 * 86400 + (($start_period_day > 1) ? $start_period_day * 86400 : 0))));
        $self->{message} = 'NEXT_PERIOD_ABON';
      }

    }
    else {
      if ($start_period_day > $D) {
        $D = $start_period_day;
      }
      else {
        $M++;
        $D = '01';
      }

      if ($M == 13) {
        $M = 1;
        $Y++;
      }

      $self->{ABON_DATE} = sprintf("%d-%02d-%02d", $Y, $M, $D);
      $self->{message} = 'NEXT_MONTH_ABON';
    }
  }

  return $self->{ABON_DATE} || undef;
}


#**********************************************************
=head2 change_tp($attr)

  Arguments:
    $attr
      TP_ID     - New TP ID
      SERVICE   - Service OBJ
      UID       - UID
      ID        - Service ID

      INTERNET_NO_ABON -

      PERIOD    -
      DATE      -
      SERVICE   -

  Results:

=cut
#**********************************************************
sub change_tp {
  my $self = shift;
  my ($attr) = @_;

  my $Tariffs = Tariffs->new($self->{db}, $self->{conf}, $self->{admin});

  my $new_tp_id = $attr->{TP_ID} || 0;
  my $service_id = $attr->{ID} || 0;
  my $uid = $attr->{UID};
  my $period = $attr->{PERIOD} || 0;
  my Internet $Service = $attr->{SERVICE};

  my %CHANGE_PARAMS = ();

  if ($new_tp_id < 1) {
    $self->{message} = 'NOT_SET_TP_ID';
    $self->{errno} = 147;
    return $self;
  }
  elsif ($period == 1 && $self->{conf}->{INTERNET_USER_CHG_TP_SHEDULE}) {
    $Service->{ABON_DATE} = $attr->{DATE};
  }
  #Imidiatly change TP
  else {
    $Service->{ABON_DATE} = $self->get_next_abon_date($attr);
  }

  if (!$attr->{UID} && $Service->{UID}) {
    $attr->{UID} = $Service->{UID};
  }

  if ($Service->{ABON_DATE}) {
    $attr->{DATE} = $Service->{ABON_DATE};
    $self->shedule_chg_tp($attr);
    if (!$self->{errno} || $self->{errno} != 148) {
      return $self;
    }
  }

  if ($self->{NEW_EXPIRE}) {
    $CHANGE_PARAMS{EXPIRE} = $self->{NEW_EXPIRE};
  }

  if ($Service->{ACTIVATE} && $Service->{ACTIVATE} ne '0000-00-00') {
    $CHANGE_PARAMS{ACTIVATE} = $DATE;
  }

  $Service->user_change({
    TP_ID  => $new_tp_id,
    ID     => $service_id,
    UID    => $uid,
    STATUS => ($Service->{STATUS} == 5) ? 0 : ($attr->{STATUS} || undef),
    %CHANGE_PARAMS
  });

  $Service->{TP_INFO} = $Tariffs->info(0, { TP_ID => $new_tp_id });

  if (!$Service->{errno}) {
    #Take fees
    if (!$Service->{STATUS}) {
      service_get_month_fee($Service, $attr) if (!$attr->{INTERNET_NO_ABON});
    }
  }

  $Service->user_info($uid, { ID => $service_id });
}

#**********************************************************
=head2 shedule_chg_tp($attr)

  Arguments:
    $attr
      TP_ID     - New TP ID
      SERVICE   - Service OBJ
      UID       - UID
      ID        - Service ID

      DATE      -

  Results:

=cut
#**********************************************************
sub shedule_chg_tp {
  my $self = shift;
  my ($attr) = @_;

  my $Service = $attr->{SERVICE};
  my $service_id = $attr->{ID} || $Service->{ID};
  my $new_tp_id = $attr->{TP_ID};
  my $uid = $attr->{UID};

  my ($year, $month, $day) = split(/-/, $attr->{DATE}, 3);
  my $seltime = POSIX::mktime(0, 0, 0, $day, ($month - 1), ($year - 1900));

  if ($seltime <= time()) {
    $self->{message} = 'ERR_WRONG_SHEDULE_DATA';
    $self->{errno} = 148;
    return $self;
  }

  my $Shedule = Shedule->new($self->{db}, $self->{admin}, $self->{conf});
  $Shedule->add({
    UID      => $uid,
    TYPE     => 'tp',
    ACTION   => "$service_id:$new_tp_id",
    D        => sprintf("%02d", $day),
    M        => sprintf("%02d", $month),
    Y        => $year,
    MODULE   => $attr->{MODULE} || 'Internet',
    COMMENTS => "_{FROM}_: $Service->{TP_ID}:$Service->{TP_NAME}"
  });

  if ($Shedule->{errno}) {
    $self->{errno} = 151;
    $self->{message} = 'ADD_SHEDULE_ERROR';
  }

  return $self;
}

1;