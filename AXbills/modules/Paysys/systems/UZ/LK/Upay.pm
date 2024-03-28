package Paysys::systems::Upay;
=head1 Upay
  New module for Upay payment system
  Documentation: https://docs.upay.uz/

  DATE: 09.02.2021
  VERSION: 0.01

=cut

use strict;
use warnings FATAL => 'all';

use AXbills::Fetcher qw/web_request/;
use AXbills::Base qw/_bp load_pmodule urlencode/;
use Paysys;
use Digest::MD5;
use JSON;

our $PAYSYSTEM_NAME = 'UPAY';
our $PAYSYSTEM_SHORT_NAME = 'UP';
our $PAYSYSTEM_ID = 153;

our $PAYSYSTEM_VERSION = '0.01';

our %PAYSYSTEM_CONF = (
  'PAYSYS_UPAY_ACCOUNT_KEY' => '',
  'PAYSYS_UPAY_SERVICE_ID'  => '',
  'PAYSYS_UPAY_SECRET'      => ''
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
    lang  => $attr->{lang},
    DEBUG => $CONF->{PAYSYS_DEBUG} || 0,
  };

  if ($attr->{HTML}) {
    $html = $attr->{HTML};
  }

  load_pmodule('JSON');
  $json = JSON->new->allow_nonref;

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 get_settings() - return hash of settings

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

=cut
#**********************************************************
sub user_portal {
  my $self = shift;
  my ($user, $attr) = @_;

  my $Paysys = Paysys->new($self->{db}, $self->{admin}, $self->{conf});

  if ($attr->{TRANSACTION_ID}) {
    main::paysys_show_result({ %$attr });
    return 1;
  }

  my %info = ();
  my $CHECK_FIELD = $self->{conf}{PAYSYS_UPAY_ACCOUNT_KEY} || 'LOGIN';

  if($CHECK_FIELD eq 'UID'){
    $info{PERSONAL_ACCOUNT}  = $attr->{UID} || $user->{UID};
  }
  elsif($CHECK_FIELD eq 'LOGIN'){
    $info{PERSONAL_ACCOUNT}  = $user->{LOGIN};
  }
  else{
    $info{PERSONAL_ACCOUNT}  = $user->{CONTRACT_ID};
  }

  if ($attr->{SUM} < 500) {
    $html->message('err', "ERROR", "ERROR Wrong Sum: '$attr->{SUM}' Минимальная сумма оплаты 500 сум");
    return 0;
  }

  $info{AMOUNT} = $attr->{SUM};

  return $html->tpl_show(main::_include('paysys_upay_user_portal', 'Paysys'), \%info, { OUTPUT2RETURN => $attr->{OUTPUT2RETURN} });
}

#**********************************************************
=head2 proccess()

  Payment Request:
   {
     "upayTransId" : 1232145,
     "upayTransTime" : "2016-10-17 23:58:12",
     "upayPaymentAmount" : 1000,
     "personalAccount" : "998931112233",
     "accessToken" : "cf23df2207d99a74fbe169e3eba035e633b65d94"
 }

  Payment Responce:
  {
    "status" : 1,
    "message" : "Успешно"
 }

=cut
#**********************************************************
sub proccess {
  my $self = shift;
  my ($FORM) = @_;

  my $CHECK_FIELD = $self->{conf}{PAYSYS_UPAY_ACCOUNT_KEY} || 'LOGIN';
  my $secret = $self->{conf}{PAYSYS_UPAY_SECRET};
  print "Content-Type: application/json\n\n";

  my $json_payment_result = $FORM->{__BUFFER};

  my $hash_payment_result = $json->decode($json_payment_result);
  my $personalAccount = $hash_payment_result->{personalAccount};
  my $upayTransId = $hash_payment_result->{upayTransId};
  my $upayPaymentAmount = $hash_payment_result->{upayPaymentAmount};
  my $upayTransTime = $hash_payment_result->{upayTransTime};
  my $accessToken = $hash_payment_result->{accessToken};

  #Pre request section
  my $inner_status = 0;
  my $status       = 0;
  my $message      = '';

  my $md5 = Digest::MD5->new;
  $md5->add($upayTransId . $secret . $upayPaymentAmount . $personalAccount);
  my $checksum = $md5->hexdigest;

   if ($accessToken ne $checksum) {
     $status       = 74;
     $message = "Неправильные параметры";

    print qq({ "status"  : "$status",
               "message" : "$message"});

     return 1;
  }

  if (defined $accessToken) {
    my ($check_status, $user_object) = main::paysys_check_user(
      {
        CHECK_FIELD => 'LOGIN',
        USER_ID     => $personalAccount,
      }
    );

    if(!$user_object->{UID}){
      $status = 0;
      $message = "Клиент с таким номером не найден.";

      print qq({ "status"  : "$status",
                 "message" : "$message"});
    }

    #Unique id_ups
    my ($paysys_status) = main::paysys_pay(
      {
        PAYMENT_SYSTEM    => $PAYSYSTEM_SHORT_NAME,
        PAYMENT_SYSTEM_ID => $PAYSYSTEM_ID,
        CHECK_FIELD       => $CHECK_FIELD,
        USER_ID           => $personalAccount,
        EXT_ID            => $upayTransId,
        SUM               => $upayPaymentAmount,
        DATA              => $FORM,
        PAYMENT_ID        => 1,
        PAYMENT_DESCRIBE  => "Payments UPAY",
        ERROR            => $inner_status,
        MK_LOG           => 1,
        DEBUG            => 0
      }
    );

    if ($paysys_status == 0) {
      $status = 1;
      $message = "Успешно";

      print qq({ "status"  : "$status",
                 "message" : "$message"});
    }
    elsif (AXbills::Base::in_array($paysys_status, [ 3, 9, 13 ])) {
      $status = 275;
      $message = "Оплата уже произведена ранее";

      print qq({ "status"  : "$status",
                 "message" : "$message"});
    }
    else {
      $status = "Error: $paysys_status";
    }

    return 1;
  }
}

1;
