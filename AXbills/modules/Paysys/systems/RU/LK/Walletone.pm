=head1 Walletone

  New module for Walletone

  Date: 26.08.2018
  Change Date: 26.09.2019

  PAYSYS IP - 81.177.31.100 / 81.177.31.200

  VERSION - 8.01
 ix
=cut

# use strict;
use warnings;

use AXbills::Base qw(_bp load_pmodule encode_base64 decode_base64);
use AXbills::Misc qw();

use Digest::MD5 qw(md5_base64);

require Paysys::Paysys_Base;

package Paysys::systems::Walletone;

our %PAYSYSTEM_CONF    = (
  'PAYSYS_WALLETONE_MERCHANT_ID'       => '',
  'PAYSYS_WALLETONE_CURRENCY_ID'       => '',
  'PAYSYS_WALLETONE_SUCCESS_URL'       => '',
  'PAYSYS_WALLETONE_FAIL_URL'          => '',
  'PAYSYS_WALLETONE_ENCRIPTION_METHOD' => '',
  'PAYSYS_WALLETONE_ENCRIPTION_KEY'    => '');
our $PAYSYSTEM_IP      = '81.177.31.100-81.177.31.200';
our $PAYSYSTEM_VERSION = 8.01;
our $PAYSYSTEM_NAME    = 'Walletone';

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
=head2 proccess()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub proccess {
  my $self = shift;
  my ($FORM) = @_;

  my $payment_system    = 'Walletone';
  my $payment_system_id = 139;
  my $paysys_status     = '';
  my $check_field       = 'UID';
  my $data              = $FORM->{UID};

  print "Content-Type: text/plain\n\n";

  my $secret_key        = $self->{conf}{PAYSYS_WALLETONE_ENCRIPTION_KEY};
  my $encription_method = $self->{conf}{PAYSYS_WALLETONE_ENCRIPTION_METHOD};

  if (!$FORM->{WMI_SIGNATURE}) {
    answer("Retry", "Отсутствует параметр WMI_SIGNATURE");
  }

  if (!$FORM->{WMI_PAYMENT_NO}) {
    answer("Retry", "Отсутствует параметр WMI_PAYMENT_NO");
  }

  if (!$FORM->{WMI_ORDER_STATE}) {
    answer("Retry", "Отсутствует параметр WMI_ORDER_STATE");
  }

  my $sign_string = '';

  $sign_string .= $secret_key;

  for my $key (sort { lc($a) cmp lc($b) } keys % { $FORM } ) {
    next if ($key eq 'WMI_SIGNATURE' || $key eq 'OPERATION_ID' || $key eq 'PAYMENT_SYSTEM' || $key eq '__BUFFER' || $key eq 'index');
    if($FORM->{WMI_INVOICE_OPERATIONS}) {
        $FORM->{WMI_INVOICE_OPERATIONS} =~ s/\\//g;
      }
      $sign_string .= $FORM->{$key};
  }

  my $signature = "";

  if ($encription_method eq 'md5') {
    $signature = Digest::MD5::md5_base64($sign_string) . '==';
  }
  elsif ($encription_method eq 'sha1') {
    $signature = Digest::SHA::sha1_base64($sign_string) . '=';
  }

  if ($FORM->{LOGIN}) {
    $check_field = 'LOGIN';
    $data        = $FORM->{LOGIN};
  }

  if ($FORM->{PHONE}) {
    $check_field = 'PHONE';
    $data        = $FORM->{PHONE};
  }

  main::mk_log("$sign_string\n", {REQUEST => 'Sign string', PAYSYS_ID => 'Walletone'});
  main::mk_log("$FORM->{WMI_SIGNATURE} - $signature\n", {REQUEST => 'Signatures', PAYSYS_ID => 'Walletone'});

  if (uc($FORM->{WMI_SIGNATURE}) eq uc($signature = $FORM->{WMI_SIGNATURE})) {
    if (uc($FORM->{WMI_ORDER_STATE}) eq "ACCEPTED") {
      $paysys_status = main::paysys_pay(
        {
          PAYMENT_SYSTEM    => $payment_system,
          PAYMENT_SYSTEM_ID => $payment_system_id,
          CHECK_FIELD       => $check_field,
          USER_ID           => $data,
          SUM               => $FORM->{WMI_PAYMENT_AMOUNT},
          EXT_ID            => $FORM->{WMI_ORDER_ID},
          DATA              => { DATA => $FORM->{__BUFFER} },
          PAYMENT_DESCRIBE  => 'Оплата с помощью Walletone',
          MK_LOG => 1,
          DEBUG  => 1
        }
      );

      if ($paysys_status == 0) {
        answer("Ok", "Заказ #" . $FORM->{WMI_PAYMENT_NO} . " оплачен!");
      }
      else {
        answer("Retry", "Ошибка №" . $paysys_status . " в магазине");
      }
    }
    else {
      answer("Retry", "Неверное состояние " . $FORM->{WMI_ORDER_STATE});
    }
  }
  else {
    answer("Retry", "Неверная подпись " . $FORM->{WMI_SIGNATURE});
  }

  return $paysys_status;
}

#**********************************************************
=head2 answer()

  Arguments:
     result - result answer
     description - description answer
  Returns:

=cut
#**********************************************************
sub answer {
  my ($result, $description) = @_;
  print "WMI_RESULT=" . uc($result) . "&";
  print "WMI_DESCRIPTION=" . uc($description);
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
  use MIME::Base64;

  my $self = shift;
  my ($user, $attr) = @_;

  my %info = ();
  $info{WMI_MERCHANT_ID}    = $self->{conf}{PAYSYS_WALLETONE_MERCHANT_ID};
  $info{WMI_PAYMENT_AMOUNT} = $attr->{SUM};
  $info{WMI_CURRENCY_ID}    = $self->{conf}{PAYSYS_WALLETONE_CURRENCY_ID};
  $info{WMI_PAYMENT_NO}     = $attr->{OPERATION_ID};
  $info{WMI_DESCRIPTION}    = encode_base64('Оплата', '');
  $info{WMI_SUCCESS_URL}    = "$ENV{PROT}://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}/index.cgi?TRUE=1&index=$index&OPERATION_ID=OP:$FORM{OPERATION_ID}&PAYMENT_SYSTEM=$FORM{PAYMENT_SYSTEM}";
  $info{WMI_FAIL_URL}       = "$ENV{PROT}://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}/index.cgi";
  $info{UID}                = $user->{UID};

  my $encription_key    = $self->{conf}{PAYSYS_WALLETONE_ENCRIPTION_KEY};
  my $encription_method = $self->{conf}{PAYSYS_WALLETONE_ENCRIPTION_METHOD};

  my $sign_string = "";
  my $signature   = "";

  for my $key (sort { lc($a) cmp lc($b) } keys %info) {
    $sign_string .= $info{$key};
  }

  $sign_string = $sign_string . $encription_key;

  if ($encription_method eq 'md5') {
    $signature = Digest::MD5::md5_base64($sign_string) . '==';
  }
  elsif ($encription_method eq 'sha1') {
    $signature = Digest::SHA::sha1_base64($sign_string) . '=';
  }

  $info{WMI_SIGNATURE} = $signature;

  $html->tpl_show(main::_include('paysys_walletone_add', 'Paysys'), \%info);
}

1
