package Paysys::systems::Paysoft;

=head1 Paysoft

  Documentaion:

  Date: 15.11.2019
  Update:

  Version: 8.00
=cut


use strict;
use warnings;
use AXbills::Base qw(_bp load_pmodule);
use Paysys;
require Paysys::Paysys_Base;
our $PAYSYSTEM_NAME = 'Paysoft';
our $PAYSYSTEM_SHORT_NAME = 'Paysoft';
our $PAYSYSTEM_ID = 97;
our $PAYSYSTEM_VERSION = '8.00';
our %PAYSYSTEM_CONF = (
  'PAYSYS_PAYSOFT_LMI_MERCHANT_ID' => '',
  'PAYSYS_PAYSOFT_SECRET'          => '',
  'PAYSYS_PAYSOFT_TESTMODE'        => '',
);

my ($html);


#**********************************************************
=head2 new($db, $admin, $CONF)

  Arguments:
    $db    - ref to DB
    $admin - current Web session admin
    $CONF  - ref to %conf
    $attr  - {
      HTML - $HTML_OBJECT
    }

  Returns:
    object

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
  $SETTINGS{ID} = $PAYSYSTEM_ID;
  $SETTINGS{NAME} = $PAYSYSTEM_NAME;
  $SETTINGS{CONF} = \%PAYSYSTEM_CONF;

  return %SETTINGS;
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
  my $lang = $attr->{LANG};

  if ($user->{GID}) {
    $self->account_gid_split($user->{GID});
  }

  if ($attr->{TRUE}) {
    $html->message('success', $lang->{SUCCESS}, "Payment done");
    return 0;
  }
  elsif ($attr->{FALSE}) {
    $html->message('err', $lang->{ERROR}, "$lang->{FAILED} $lang->{TRANSACTION} ID: $attr->{LMI_PAYMENT_NO}");
    return 0;
  }

  if (!$self->{conf}{PAYSYS_PAYSOFT_LMI_MERCHANT_ID}) {
    $html->message('err', $lang->{ERROR}, "Payment system has wrong configuration");
    return 0;
  }
  if (!$attr->{SUM} || $attr->{SUM} == 0) {
    $html->message('err', $lang->{ERROR}, "Payment sum is too small.");
    return 0;
  }

  if (!$attr->{SELECTED}) {
    my %methods = (
      12 => 'Easypay + Paymaster',
      1  => 'Webmoney + Paymaster',
      6  => 'MoneyXy + Paymaster',
      15 => 'НСМЕП + Paymaster',
      21 => 'VISA/MasterCard + Paymaster',
      17 => 'Terminal UA + Paymaster',
      20 => 'Privat24 + Paymaster',
      19 => 'Liqpay + Paymaster',
    );
    my $method_select = $html->form_select(
      'SELECT_PAYMENT_METHOD',
      {
        SELECTED => 12,
        SEL_HASH => \%methods,
        NO_ID    => 1
      }
    );
    return $html->tpl_show(main::_include('paysys_paysoft_select', 'Paysys'), { %{$attr}, SELECT => $method_select, OUTPUT2RETURN => 0 });
  }

  my %info = ();

  if ($self->{conf}{PAYSYS_PAYSOFT_TESTMODE}) {
    my ($LMI_MODE, $LMI_SIM_MODE) = split(/:/, $self->{conf}{PAYSYS_PAYSOFT_TESTMODE}, 2);
    $info{TEST_MODE} = "
   <input type='hidden' name='LMI_SIM_MODE' value='$LMI_SIM_MODE'>
   <font color='red'>$lang->{TEST_MODE} (LMI_MODE: $LMI_MODE, LMI_SIM_MODE: $LMI_SIM_MODE)</font>";
  }

  # Terminal auth type
  if ($attr->{PAYMENT_SYSTEM} == 85) {
    $info{AT} = '?at=authtype_8';
  }

  $info{LMI_MERCHANT_ID} = $self->{conf}{PAYSYS_PAYSOFT_LMI_MERCHANT_ID};
  $info{LMI_PAYMENT_NO} = $attr->{OPERATION_ID};
  $info{ACTION_URL} = 'https://lmi.paysoft.solutions/';
  $info{LMI_PAYMENT_AMOUNT} = $attr->{SUM};
  my $pay_describe = "Login: $user->{LOGIN}, UID: $user->{UID}";
  $info{DESCRIBE} = $pay_describe;
  $info{LMI_PAYMENT_DESC} = ($self->{conf}{dbcharset} eq 'utf8') ? main::convert($pay_describe, { utf82win => 1 }) : $pay_describe;
  $info{PAYSYS_LMI_RESULT_URL} = "$ENV{PROT}://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}/paysys_check.cgi";
  $info{LMI_SUCCESS_URL} = "$ENV{PROT}://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}$ENV{REQUEST_URI}?TRUE=1";
  $info{LMI_FAIL_URL} = "$ENV{PROT}://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}$ENV{REQUEST_URI}?FALSE=1&LMI_PAYMENT_NO=$attr->{OPERATION_ID}&PAYMENT_SYSTEM=$attr->{PAYMENT_SYSTEM}&index=$attr->{index}";
  $info{IP} = $ENV{REMOTE_ADDR};
  $info{SID} = $attr->{sid};
  $info{UID} = $user->{UID};
  $info{LMI_PAYMENT_SYSTEM} = $attr->{SELECT_PAYMENT_METHOD};

  return $html->tpl_show(main::_include('paysys_paysoft_add', 'Paysys'), { %info }, { OUTPUT2RETURN => 0 });
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
  my $status_code = 0;
  my $status = q{};
  my $output_content = '';

  print "Content-Type: text/html\n\n";

  #Pre request section
  if ($FORM->{'LMI_PREREQUEST'} && $FORM->{'LMI_PREREQUEST'} == 1) {
    $output_content = "YES";
  }
  #Payment notification
  elsif ($FORM->{LMI_HASH}) {

    my ($check_result, $user_info) = main::paysys_check_user({
      CHECK_FIELD => 'UID',
      USER_ID     => $FORM->{UID}
    });

    if ($check_result == 0) {
      $self->account_gid_split($user_info->{GID});
    }

    load_pmodule('Digest::SHA', { IMPORT => 'sha256_hex' });

    my $sign_string = $FORM->{LMI_MERCHANT_ID} .
    $FORM->{LMI_PAYMENT_NO}.
    $FORM->{LMI_SYS_PAYMENT_ID}.
    $FORM->{LMI_SYS_PAYMENT_DATE}.
    $FORM->{LMI_PAYMENT_AMOUNT}.
    $FORM->{LMI_PAID_AMOUNT}.
    $FORM->{LMI_PAYMENT_SYSTEM}.
    $FORM->{LMI_MODE}.
    $self->{conf}{PAYSYS_PAYSOFT_SECRET};

    my $checksum = uc(Digest::SHA::sha256_hex($sign_string));

    if (defined($FORM->{LMI_MODE}) && $FORM->{LMI_MODE} == 1) {
      $status = 'Test mode';
      $status_code = 12;
    }
    elsif ($FORM->{LMI_HASH} ne $checksum) {
      $status = "Incorect checksum '$checksum/$FORM->{LMI_HASH}'";
      $status_code = 5;
    }

    my $payment_unit = '';

    $status_code = main::paysys_pay({
      PAYMENT_SYSTEM    => $PAYSYSTEM_SHORT_NAME,
      PAYMENT_SYSTEM_ID => $PAYSYSTEM_ID,
      CHECK_FIELD       => 'UID',
      USER_ID           => $FORM->{UID},
      SUM               => $FORM->{LMI_PAYMENT_AMOUNT},
      EXT_ID            => $FORM->{LMI_PAYMENT_NO},
      IP                => $FORM->{IP},
      DATA              => $FORM,
      MK_LOG            => 1,
      ERROR             => $status_code,
      CURRENCY          => $payment_unit,
      DEBUG             => $self->{DEBUG} ? $self->{DEBUG} : 0
    });
  }

  print $output_content;

  main::mk_log($output_content . "\nSTATUS CODE: $status_code/$status",
    { PAYSYS_ID => "$PAYSYSTEM_SHORT_NAME/$PAYSYSTEM_ID" });

  return 1;

}

#**********************************************************
=head2 account_gid_split ()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub account_gid_split {
  my $self = shift;
  my ($gid) = @_;

  if ($self->{conf}{'PAYSYS_PAYSOFT_LMI_MERCHANT_ID_' . $gid}) {
    $self->{conf}{PAYSYS_PAYSOFT_LMI_MERCHANT_ID} = $self->{conf}{'PAYSYS_PAYSOFT_LMI_MERCHANT_ID_' . $gid};
  }

  if ($self->{conf}{'PAYSYS_PAYSOFT_SECRET_' . $gid}) {
    $self->{conf}{PAYSYS_PAYSOFT_SECRET} = $self->{conf}{'PAYSYS_PAYSOFT_SECRET_' . $gid};
  }

  if ($self->{conf}{'PAYSYS_PAYSOFT_TESTMODE_' . $gid}) {
    $self->{conf}{PAYSYS_PAYSOFT_TESTMODE} = $self->{conf}{'PAYSYS_PAYSOFT_TESTMODE_' . $gid};
  }

}

1;