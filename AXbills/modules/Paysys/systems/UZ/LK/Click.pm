=head1 Click

  New module for Click

  Documentaion: https://docs.click.uz/click-api-request/

  Date: 14.08.2019
  Change Date: 03.10.2019

  Version: 8.05

=cut

use strict;
use warnings;
use AXbills::Base qw(_bp load_pmodule encode_base64 decode_base64);
use AXbills::Misc qw();
require Paysys::Paysys_Base;
package Paysys::systems::Click;
our $PAYSYSTEM_NAME = 'Click';
our $PAYSYSTEM_SHORT_NAME = 'CLK';
our $PAYSYSTEM_ID = 138;

our $PAYSYSTEM_VERSION = '8.05';

our %PAYSYSTEM_CONF = (
  PAYSYS_CLICK_ACCOUNT_KEY => '',
  PAYSYS_CLICK_MERCHANT_ID => '',
  PAYSYS_CLICK_SERVICE_ID  => '',
  PAYSYS_CLICK_SECRET_KEY  => '',
);

my ($html, $json);

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

  AXbills::Base::load_pmodule('JSON');
  $json = JSON->new->allow_nonref;

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 proceess()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub proccess {
  my $self = shift;
  my ($FORM) = @_;

  print "Content-Type: text/json; charset=UTF-8\n\n";

  my $merchant_trans_id = $FORM->{merchant_trans_id} || '';
  my $merchant_prepare_id = $FORM->{merchant_prepare_id} || '';
  my $error = $FORM->{error} || '';
  my $click_trans_id = $FORM->{click_trans_id} || '';
  my $error_note = $FORM->{error_note} || '';
  my $action = $FORM->{action} || '0';
  my $service_id = $FORM->{service_id} || '';
  my $amoun = $FORM->{amount} || '';
  my $sign_time = $FORM->{sign_time} || '';
  my $sign_string = $FORM->{sign_string} || '';

  my $signature = Digest::MD5::md5_hex($click_trans_id . $service_id . $self->{conf}->{PAYSYS_CLICK_SECRET_KEY} . $merchant_trans_id . ($action eq '1' ? $merchant_prepare_id : '') . $amoun . $action . $sign_time);
  my ($payment_id, $payment_status) = main::paysys_pay_check({ TRANSACTION_ID => "$PAYSYSTEM_SHORT_NAME:$merchant_trans_id" });

  my $CHECK_FIELD = $self->{conf}{"PAYSYS_CLICK_ACCOUNT_KEY"} || 'UID';

  if ($signature ne $sign_string) {
    show_response($merchant_trans_id, '', $click_trans_id, '-1', $error_note);
    return 1;
  }
  elsif (defined $action && $action == 0) {
    if ($payment_status == 0) {
      my ($result_code, $ckeck_user) = main::paysys_check_user({
        CHECK_FIELD => $CHECK_FIELD,
        USER_ID     => $merchant_trans_id
      });

      if($result_code == 1){
        show_response($merchant_trans_id, '', $click_trans_id, '-5', $error_note);
        return 1;
      }
      else{
        show_response($merchant_trans_id, $click_trans_id, $click_trans_id, '0', $error_note);
        return 1;
      }
    }
    else {
      show_response($merchant_trans_id, $payment_id, $click_trans_id, '0', $error_note);
      return 1;
    }
  }
  elsif ($action == 1) {

    my $full_info = main::paysys_get_full_info({
      TRANSACTION_ID => "$PAYSYSTEM_SHORT_NAME:$merchant_trans_id",
    });

    if (!$full_info->{sum}) {
      my ($result_code, $ckeck_user) = main::paysys_check_user({
        CHECK_FIELD => $CHECK_FIELD,
        USER_ID     => $merchant_trans_id
      });

      if ($result_code == 1) {
        show_response($merchant_trans_id, '', $click_trans_id, '-5', $error_note);
        return 1;
      }

      my ($payment_status_, $payment_id_pay) = main::paysys_pay({
        PAYMENT_SYSTEM    => $PAYSYSTEM_SHORT_NAME,
        PAYMENT_SYSTEM_ID => $PAYSYSTEM_ID,
        SUM               => $FORM->{amount},
        CHECK_FIELD       => $CHECK_FIELD,
        USER_ID           => $merchant_trans_id,
        EXT_ID            => "$click_trans_id",
        DATA              => { DATA => $FORM->{__BUFFER} },
        DATE              => "$main::DATE $main::TIME",
        MK_LOG            => 1,
        DEBUG             => $self->{DEBUG},
        PAYMENT_DESCRIBE  => "$PAYSYSTEM_NAME payment",
        PAYMENT_ID        => 1
      });

      if ($payment_status_ == 0 || $payment_status_ == 13) {
        show_response($merchant_trans_id, $payment_id_pay, $click_trans_id, '0', $error_note);
        return 1;
      }
      else {
        show_response($merchant_trans_id, $payment_id_pay, $click_trans_id, '-4', $error_note);
        return 1;
      }
    }
    else {
      if ($amoun ne $full_info->{sum}) {
        show_response($merchant_trans_id, '', $click_trans_id, '-2', $error_note);
        return 1;
      }

      if ($error eq '-1') {
        my $result_code = main::paysys_pay_cancel({
          TRANSACTION_ID => "$PAYSYSTEM_SHORT_NAME:$merchant_trans_id"
        });

        show_response($merchant_trans_id, time() * 1000, $click_trans_id, '-4', $error_note);
        return 1;
      }

      my ($payment_status_, $payment_id_) = main::paysys_pay({
        PAYMENT_SYSTEM    => $PAYSYSTEM_SHORT_NAME,
        PAYMENT_SYSTEM_ID => $PAYSYSTEM_ID,
        SUM               => $FORM->{amount},
        ORDER_ID          => "$PAYSYSTEM_SHORT_NAME:$merchant_trans_id",
        EXT_ID            => $merchant_trans_id,
        DATA              => { DATA => $FORM->{__BUFFER} },
        DATE              => "$main::DATE",
        MK_LOG            => 1,
        DEBUG             => $self->{DEBUG},
        PAYMENT_DESCRIBE  => "$PAYSYSTEM_NAME payment",
        PAYMENT_ID        => 1
      });

      if ($payment_status_ == 0 || $payment_status_ == 13) {
        show_response($merchant_trans_id, $payment_id_, $click_trans_id, '0', $error_note);
        return 1;
      }
      else {
        show_response($merchant_trans_id, $payment_id_, $click_trans_id, '-4', $error_note);
        return 1;
      }
    }
  }

  return 1;
}

#**********************************************************
=head2 show_response()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub show_response {
  my ($merchant_trans_id, $merchant_prepare_id, $click_trans_id, $error, $error_note) = @_;

  print qq[

  {
      "click_trans_id" :  $click_trans_id,
      "merchant_trans_id" :  "$merchant_trans_id",
      "merchant_prepare_id" :  "$merchant_prepare_id",
      "merchant_confirm_id" :  "$merchant_prepare_id",
      "error":  $error,
      "error_note": "$error_note"
  }
];

  return 1;
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

  if($attr->{SUM} <= 0){
    $html->message('err', "ERROR". "  Введена не правильная сумма: '$attr->{SUM}'");
    return 0;
  }

  my $form_url = 'https://my.click.uz/services/pay';

  use Paysys;
  my $Paysys = Paysys->new($self->{db}, $self->{admin}, $self->{conf});

  $Paysys->add({
    SYSTEM_ID      => $attr->{PAYMENT_SYSTEM},
    SUM            => $attr->{SUM},
    UID            => $attr->{UID} || $user->{UID},
    IP             => "$ENV{'REMOTE_ADDR'}",
    TRANSACTION_ID => "$PAYSYSTEM_SHORT_NAME:$attr->{OPERATION_ID}",
    STATUS         => 1,
    DOMAIN_ID      => $user->{DOMAIN_ID} || 0,
  });

  if ($Paysys->{errno}) {
    return $html->message('err', "Error", "ERROR Paysys ID: '$attr->{OPERATION_ID}'");
  }

  $html->tpl_show(main::_include('paysys_click_add', 'Paysys'), {
    MERCHANT_ID    => $self->{conf}{PAYSYS_CLICK_MERCHANT_ID},
    UID            => $user->{UID},
    AMOUNT         => $attr->{SUM},
    TRANSACTION_ID => $attr->{OPERATION_ID},
    SERVICE_ID     => $self->{conf}{PAYSYS_CLICK_SERVICE_ID},
    URL            => $form_url,
  });

  return 1;
}

1;
