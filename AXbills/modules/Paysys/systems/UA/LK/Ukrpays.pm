package Paysys::systems::Ukrpays;

=head1 Regulpay
  New module for Ukrpays payment system

  Date: 28.11.2018
  Update: 28.05.2020
  Version: 7.06

=cut

use strict;
use warnings;

use AXbills::Base qw(_bp in_array);
use AXbills::Misc qw(load_module);
require Paysys::Paysys_Base;

our $PAYSYSTEM_NAME       = 'Ukrpays';
our $PAYSYSTEM_SHORT_NAME = 'Upays';

our $PAYSYSTEM_ID = 46;

our $PAYSYSTEM_VERSION = '7.06';

my $CUSTOM_NAME = uc($PAYSYSTEM_NAME);
my $CUSTOM_ID   = $PAYSYSTEM_ID;

our %PAYSYSTEM_CONF = (
  'PAYSYS_UKRPAYS_ACCOUNT_KEY' => 'UID',
  'PAYSYS_UKRPAYS_SECRETKEY'   => '',
  'PAYSYS_UKRPAYS_CURRENCY'    => '',
  'PAYSYS_UKRPAYS_SERVICE_ID'  => '',
);

my $html;

#**********************************************************

=head2 new($db, $admin, $CONF)

  Arguments:
    $db    - ref to DB
    $admin - current Web session admin
    $CONF  - ref to %conf
    %ATTR  - ref to additional attributes
      CUSTOM_NAME - custom paysystem name, for inheritance
      CUSTOM_ID   - custom id, for inheritance

  Returns:
    object

  Example:
    my $Ukrpays = Ukrpays->new($db, $admin, \%conf, { %ATTR });

=cut

#**********************************************************
sub new {
  my $class = shift;

  my ($db, $admin, $CONF, $attr) = @_;

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $CONF,
    DEBUG => $CONF->{PAYSYS_DEBUG} || 0,
  };

  if ($attr->{CUSTOM_NAME}) {
    $CUSTOM_NAME = uc($attr->{CUSTOM_NAME});
    $PAYSYSTEM_SHORT_NAME = substr($CUSTOM_NAME, 0, 3);
  }

  if ($attr->{CUSTOM_ID}) {
    $CUSTOM_ID = $attr->{CUSTOM_ID};
  }

  if ($attr->{HTML}) {
    $html = $attr->{HTML};
  }

  bless($self, $class);

  return $self;
}

#**********************************************************

=head2 get_settings() - return hash of settings

  Arguments:


  Returns:
    HASH
=cut

#**********************************************************
sub get_settings {
  my %SETTINGS = ();

  $SETTINGS{VERSION} = $PAYSYSTEM_VERSION;
  $SETTINGS{ID}      = $CUSTOM_ID;
  $SETTINGS{NAME}    = $PAYSYSTEM_NAME;

  $SETTINGS{CONF} = \%PAYSYSTEM_CONF;

  return %SETTINGS;
}

#**********************************************************

=head2 proccess()

  Arguments:
     -

  Returns:

=cut

#**********************************************************
sub proccess {
  my $self = shift;
  my ($FORM) = @_;

  my $CHECK_FIELD = 'UID';
  print "Content-Type: text/plain\n\n";

  my %payment_methods = (
    1   => 'Visa, MasterCard',
    21  => 'Visa, MasterCard(PrivatBank)',
    12  => 'Visa, MasterCard(LiqPay)',
    17  => 'Webmoney',
    131 => 'ТСО 24nonStop',
    132 => 'ТСО Tyme',
    133 => 'ТСО EasyPay',
    134 => 'ТСО E-Pay',
    136 => 'ТСО ФК Система',
    137 => 'ТСО City24',
    139 => 'ТСО iBox',
  );

  my $mod_return = main::load_pmodule('Digest::MD5', { SHOW_RETURN => 1 });

  if ($mod_return) {
    main::mk_log($mod_return, { PAYSYS_ID => $PAYSYSTEM_NAME });
  }

  my $md5 = Digest::MD5->new();
  $md5->reset();

  #Pre request section
  my $inner_status = 0;
  my $status       = 0;

  if ($FORM->{hash}) {
    if ($FORM->{order} =~ /(\d{8}):(\d+)/) {
      $md5->reset;
      $md5->add($FORM->{id_ups});
      $md5->add($FORM->{order});
      $md5->add($FORM->{note}) if (defined($FORM->{note}));
      $md5->add($FORM->{amount});
      $md5->add($FORM->{date});
      $md5->add($self->{conf}{PAYSYS_UKRPAYS_SECRETKEY});

      my $checksum = $md5->hexdigest();

      if ($FORM->{hash} ne $checksum) {
        $status       = "ERROR: Incorect checksum '$checksum'";
        $inner_status = 35;
      }

      my ($paysys_status, $payments_id) = main::paysys_pay(
        {
          PAYMENT_SYSTEM    => $CUSTOM_NAME,
          PAYMENT_SYSTEM_ID => $CUSTOM_ID,
          SUM               => $FORM->{amount},
          EXT_ID            => $FORM->{note},

          #PAYSYS_ID         => $FORM{note},
          ORDER_ID          => "$CUSTOM_ID:$FORM->{note}",
          REGISTRATION_ONLY => 1,
          CURRENCY_ISO      => $self->{conf}{PAYSYS_UKRPAYS_CURRENCY},
          DATA              => $FORM,
          PAYMENT_ID        => 1,
          PAYMENT_DESCRIBE  => $payment_methods{ $FORM->{system} },
          ERROR             => $inner_status,
          MK_LOG            => 1,
          DEBUG             => 0
        }
      );

      $status = 'OK';

      if ($paysys_status == 0) {
        $status = 'OK';
      }
      elsif ($paysys_status == 9) {
        $status = "duplicate";
      }
      else {
        $status = "Error:$paysys_status";
      }

      print $status;
      return 0;
    }

    if ($FORM->{date} < 1448898531) {
      $FORM->{order} =~ /^\d{7}/;
      $FORM->{order} = $1;
    }

    my ($check_status, $user_object) = main::paysys_check_user(
      {
        CHECK_FIELD => 'UID',
        USER_ID     => $FORM->{order},
      }
    );

    main::conf_gid_split(
      {
        GID    => $user_object->{GID},
        PARAMS => [ 'PAYSYS_UKRPAYS_SECRETKEY', ],
      }
    );

    $md5->reset;
    $md5->add($FORM->{id_ups});
    $md5->add($FORM->{order});
    $md5->add($FORM->{note}) if (defined($FORM->{note}));
    $md5->add($FORM->{amount});
    $md5->add($FORM->{date});
    $md5->add($self->{conf}{PAYSYS_UKRPAYS_SECRETKEY});

    my $checksum = $md5->hexdigest();

    if ($FORM->{hash} ne $checksum) {
      $status       = "ERROR: Incorect checksum '$checksum'";
      $inner_status = 35;
    }

    #Unique id_ups

    my ($paysys_status) = main::paysys_pay(
      {
        PAYMENT_SYSTEM    => $PAYSYSTEM_SHORT_NAME,
        PAYMENT_SYSTEM_ID => $CUSTOM_ID,
        CHECK_FIELD       => $CHECK_FIELD,
        USER_ID           => $FORM->{login},
        EXT_ID            => $FORM->{id_ups},                          # $FORM{note} || $FORM{order},
        SUM               => $FORM->{amount},
        CURRENCY_ISO      => $self->{conf}{PAYSYS_UKRPAYS_CURRENCY},

        #PAYSYS_ID         => ($FORM{login} eq $FORM{note}) ? "$payment_system:$FORM{note}" : undef,
        #ORDER_ID          => "$payment_system:$FORM{id_ups}",  #($FORM{login} eq $FORM{note}) ? "$payment_system:$FORM{note}" : undef,
        CHECK_FIELD      => $CHECK_FIELD,
        DATA             => $FORM,
        PAYMENT_ID       => 1,
        PAYMENT_DESCRIBE => $payment_methods{ $FORM->{system} },
        ERROR            => $inner_status,
        MK_LOG           => 1,
        DEBUG            => 0
      }
    );

    if ($paysys_status == 0) {
      $status = 'OK';
    }
    elsif (AXbills::Base::in_array($paysys_status, [ 3, 9, 13 ])) {
      $status = "duplicate";
    }
    else {
      $status = "Error: $paysys_status";
    }
    main::mk_log("RESULT: status - $status", { PAYSYS_ID => "$CUSTOM_NAME" });
    print $status;
    return 1;
  }
}

#**********************************************************

=head2 user_portal()

  Arguments:
     -

  Returns:

=cut

#**********************************************************
sub user_portal {
  my $self = shift;
  my ($user, $attr) = @_;

  my $payment_system    = $attr->{SYSTEM_SHORT_NAME} || 'Upays';
  my $payment_system_id = $attr->{SYSTEM_ID}         || 46;

  my %info = ();

  use Paysys;
  my $Paysys = Paysys->new($self->{db}, $self->{admin}, $self->{conf});

  if ($attr->{FALSE}) {
    $html->message('err', "ERROR", "FAILED TRANSACTION ID: $attr->{OPERATION_ID}");
    return 0;
  }
  if ($attr->{TRUE}) {
    main::paysys_show_result({ %$attr, TRANSACTION_ID => "$CUSTOM_ID:$attr->{OPERATION_ID}" });
    return 1;
  }

  $self->conf_gid_split(
    {
      GID    => $user->{GID},
      PARAMS => [ 'PAYSYS_UKRPAYS_ACCOUNT_KEY', 'PAYSYS_UKRPAYS_SERVICE_ID', 'PAYSYS_UKRPAYS_SECRETKEY', 'PAYSYS_UKRPAYS_CURRENCY', ]
    }
  );

  $info{UID}  = $attr->{UID} || $user->{UID};
  $info{FIO}  = $user->{FIO};
  $info{DESC} = "$payment_system:$attr->{OPERATION_ID}";

  $info{AMOUNT} = sprintf("%.2f", $attr->{SUM});
  $info{SUS_URL_PARAMS} = $attr->{SUS_URL_PARAMS} || '';

  $self->{conf}{PAYSYS_UKRPAYS_URL} = 'https://ukrpays.com/frontend/frontend.php' if (!$self->{conf}{PAYSYS_UKRPAYS_URL});

  return $html->tpl_show(main::_include('paysys_ukrpays_add', 'Paysys'), \%info, { OUTPUT2RETURN => $attr->{OUTPUT2RETURN} });
}

#**********************************************************

=head2 conf_gid_split()

  Arguments:
     -

  Returns:

=cut

#**********************************************************
sub conf_gid_split {
  my $self = shift;
  my ($attr) = @_;

  my $gid = $attr->{GID};

  if ($attr->{PARAMS}) {
    my $params = $attr->{PARAMS};
    foreach my $key (@$params) {
      if ($self->{conf}{ $key . '_' . $gid }) {
        $self->{conf}{$key} = $self->{conf}{ $key . '_' . $gid };
      }
    }
  }

  return 1;
}

1;