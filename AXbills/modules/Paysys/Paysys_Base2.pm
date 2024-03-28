package Paysys::Paysys_Base2;
=head1 Paysys_Base2

  Paysys_Base - module for payments

=head1 SYNOPSIS

  paysys_load('Paysys_Base');

=cut

use strict;
use warnings FATAL => 'all';

use AXbills::Base qw(in_array);
use Paysys;
use Payments;

my Paysys $Paysys;
my Payments $Payments;

#**********************************************************
=head2 new($db, $admin, $CONF)

  Arguments:
    $db    - ref to DB
    $admin - current Web session admin
    $CONF  - ref to %conf

  Returns:
    object

=cut
#**********************************************************
sub new {
  my $class = shift;
  my ($db, $admin, $conf, $attr) = @_;

  my $self = {
    db    => $db,
    admin => $admin,
    lang  => $attr->{lang},
    html  => $attr->{html},
    conf  => $conf,
    DEBUG => $conf->{PAYSYS_DEBUG} || 0,
  };

  bless($self, $class);

  $Paysys = Paysys->new($self->{db}, $self->{admin}, $self->{conf});
  $Payments = Payments->new($self->{db}, $self->{admin}, $self->{conf});

  return $self;
}

#**********************************************************
=head2 conf_gid_split($attr) - Find payment system parameters for some user group (GID)

  Arguments:
    $attr
      GID           - group identifier;
      NAME: string  - custom name of Payment system
      PARAMS        - Array of parameters
      SERVICE       - Service ID
      SERVICE2GID   - Service to gid
                        delimiter :
                        separator ;
      GET_MAIN_GID-

  Returns:
    TRUE or FALSE

  Examples:

    conf_gid_split({ GID    => 1,
                     PARAMS => [
                         'PAYSYS_UKRPAYS_SERVICE_ID',
                      ],
                 })
    convers

     $conf{PAYSYS_UKRPAYS_SERVICE_ID} => $conf{PAYSYS_UKRPAYS_SERVICE_ID_1};

=cut
#**********************************************************
sub conf_gid_split {
  my $self = shift;
  my ($attr) = @_;

  my %conf = %{$self->{conf}};

  if ($attr->{PARAMS}) {
    my $param_name = $attr->{PARAMS}->[0] || '';
    my ($paysys_name) = $param_name =~ /^PAYSYS_[^_]+/gm;
    push @{$attr->{PARAMS}}, ($paysys_name || '') . '_PAYMENT_METHOD',
      ($paysys_name || '') . '_PORTAL_DESCRIPTION', ($paysys_name || '') . '_PORTAL_COMMISSION';
  }

  my $gid = $attr->{GID};

  if (!$gid) {
    my $status = _check_max_payments({ %$attr, CONF => \%conf });

    $conf{CONF_GID_SPLIT_STATUS} = $status;
    return \%conf;
  }

  if ($attr->{SERVICE} && $attr->{SERVICE2GID}) {
    my @services_arr = split(/;/, $attr->{SERVICE2GID});
    foreach my $line (@services_arr) {
      my ($service, $gid_id) = split(/:/, $line);
      if ($attr->{SERVICE} == $service) {
        $gid = $gid_id;
        last;
      }
    }
  }

  if ($attr->{PARAMS}) {
    my $params = $attr->{PARAMS};
    foreach my $key (@$params) {
      $key =~ s/_NAME_/_$attr->{NAME}\_/ if ($attr->{NAME} && $key =~ /_NAME_/);
      if (defined $conf{$key . '_' . $gid}) {
        $conf{$key} = $conf{$key . '_' . $gid};
        if ($attr->{GET_MAIN_GID}) {
          $attr->{MAIN_GID} = $gid;
        }
      }
    }
  }

  my $status = _check_max_payments({ %$attr, CONF => \%conf });
  $conf{CONF_GID_SPLIT_STATUS} = $status;
  return \%conf;
}

#**********************************************************
=head2 _check_max_payments($attr) - Check is allowed make payment for user

  Arguments:
    $attr
      PARAMS: object     - Array of parameters
      PAYMENT_SYSTEM_ID  - ID of payment system
      MERCHANT_ID        - ID of merchant which need to check
      MERCHANTS          - list of executed merchants, prevent boot loop
      CONF               - config

  Returns:

    0 - not allowed payment
    1 - allowed payment

=cut
#**********************************************************
sub _check_max_payments {
  my ($attr) = @_;

  my $params = {};
  my $merchant_id = '--';

  if ($attr->{MERCHANT_ID}) {
    $params = $Paysys->merchant_params_info({ MERCHANT_ID => $attr->{MERCHANT_ID} });
  }
  else {
    return 1 if (!$attr->{PAYMENT_SYSTEM_ID});
    return 1 if (!$Paysys->can('gid_params'));

    my $list_params = $Paysys->gid_params({
      GID       => $attr->{GID} || 0,
      PAYSYS_ID => $attr->{PAYMENT_SYSTEM_ID},
      COLS_NAME => 1,
    });

    foreach my $param (@{$list_params}) {
      $params->{$param->{param}} = $param->{value} || '';
    }

    $merchant_id = $list_params->[0]->{merchant_id} || '--' if (scalar @{$list_params});
  }

  delete $Paysys->{errno};

  return 1 if (!scalar keys %{$params} && !$attr->{MERCHANT_ID});

  my ($max_sum_key) = grep {/PAYMENTS_MAX_SUM/g} keys %{$params};
  return 1 if ((!$max_sum_key || !$params->{$max_sum_key}) && !$attr->{MERCHANT_ID});

  my ($payment_method_key) = grep {/PAYMENT_METHOD/g} keys %{$params};
  return 1 if ((!$payment_method_key || !$params->{$payment_method_key}) && !$attr->{MERCHANT_ID});

  my $payment_method = $params->{$payment_method_key || '--'};
  my $max_sum = $params->{$max_sum_key || ''} || 0;

  if ($max_sum) {
    my ($year, $month) = $main::DATE =~ /(\d{4})\-(\d{2})\-(\d{2})/g;
    $Payments->list({
      PAYMENT_METHOD => $payment_method,
      FROM_DATE      => "$year-$month-01",
      TO_DATE        => $main::DATE,
      TOTAL_ONLY     => 1
    });

    $Payments->{SUM} //= 0;
    delete $Payments->{errno};
  }

  if (!$max_sum || (defined $Payments->{SUM} && $max_sum > $Payments->{SUM})) {
    if ($attr->{MERCHANT_ID}) {
      foreach my $param (keys %{$params}) {
        $attr->{conf}{$param} = $params->{$param};
      }
    }

    return 1;
  }

  my ($merchant_id_key) = grep {/PAYMENTS_NEXT_MERCHANT/g} keys %{$params};
  if (!$merchant_id_key || !$params->{$merchant_id_key}) {
    if ($attr->{MERCHANT_ID} || $max_sum) {
      return 0;
    }
    else {
      return 1;
    }
  }

  $attr->{MERCHANT_ID} = $params->{$merchant_id_key || ''} || '--';
  $attr->{MERCHANTS} ||= [ $merchant_id ];
  return 0 if (in_array($attr->{MERCHANT_ID}, $attr->{MERCHANTS}));
  push @{$attr->{MERCHANTS}}, $attr->{MERCHANT_ID};

  return _check_max_payments($attr);
}

1;
