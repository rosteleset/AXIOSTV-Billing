package Paysys::systems::Octo;
=head1 Octo
  New module for Octo payment system

  DATE: 24.07.2020
  VERSION: 0.05

=cut

use strict;
use warnings FATAL => 'all';

use AXbills::Fetcher qw/web_request/;
use AXbills::Base qw/_bp load_pmodule urlencode/;
use Paysys;
use JSON;

our $PAYSYSTEM_NAME = 'Octo';
our $PAYSYSTEM_SHORT_NAME = 'OC';
our $PAYSYSTEM_ID = 145;

our $PAYSYSTEM_VERSION = '0.05';

our %PAYSYSTEM_CONF = (
  'PAYSYS_OC_SHOP_ID'     => '',
  'PAYSYS_OC_SECRET_KEY'  => '',
  'PAYSYS_OC_CURRENCY'    => '',
  'PAYSYS_OC_LANGUAGE'    => '',
  'PAYSYS_OC_USER_DATA'   => '',
  'PAYSYS_OC_CUSTOMER_IP' => '',
  'PAYSYS_OC_TEST'        => '',
  'PAYSYS_OC_TTL'         => '',
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

  if ($attr->{TRANSACTION_ID}) {
    main::paysys_show_result({ %$attr });
    return 1;
  }

  my $shop_id = $self->{conf}{"PAYSYS_OC_SHOP_ID"};
  my $secret  = $self->{conf}{"PAYSYS_OC_SECRET_KEY"};

  my $currency  = $self->{conf}{"PAYSYS_OC_CURRENCY"};
  my $language = $self->{conf}{"PAYSYS_OC_LANGUAGE"};
  my $Paysys = Paysys->new($self->{db}, $self->{admin}, $self->{conf});

  $Paysys->add({
      SYSTEM_ID      => $attr->{PAYMENT_SYSTEM},
      SUM            => $attr->{SUM},
      UID            => $attr->{UID} || $user->{UID},
      IP             => "$attr->{IP}" || "$ENV{'REMOTE_ADDR'}",
      TRANSACTION_ID => "OC:$attr->{OPERATION_ID}",
      STATUS         => 1,
      DOMAIN_ID      => $user->{DOMAIN_ID},
      FIO            => $user->{FIO},
      PHONE          => $user->{PHONE},
      EMAIL          => $user->{EMAIL}

  });

  if ($attr->{TEST_OCTO} && $Paysys->{errno}) {
    return 'ERROR_Paysys';
  }

  if ($Paysys->{errno}) {
    $html->message('err', "ERROR", "ERROR Paysys ID: '$attr->{OPERATION_ID}'");
    return 0;
  }

  if ($self->{conf}{"PAYSYS_OC_USER_DATA"}) {
    if (!$user->{PHONE} || !$user->{EMAIL}) {
      $html->message('err', "$self->{lang}->{ERROR}", "$self->{lang}->{ERR_MESSAGE}");
      return 0;
    }
  }

  $user->{PHONE} =~ s/\+//g;

  my $url = 'https://secure.octo.uz/prepare_payment';
  my $url_env = ($ENV) ? "$ENV{PROT}://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}" : $attr->{IP};
  my $return_url = "$url_env/index.cgi?get_index=$attr->{index}&PAYMENT_SYSTEM=$attr->{PAYMENT_SYSTEM}&TRANSACTION_ID=OC:$attr->{OPERATION_ID}";

  my $ttl =  $self->{conf}{"PAYSYS_OC_TTL"} || 15;
  my $description = $attr->{DESCRIBE};
  
  require Encode;
  $description = Encode::decode('UTF-8', $description);

  my $amount = $attr->{SUM};

  my $json_hash = {
    "octo_shop_id" => $shop_id + 0,
    "octo_secret"  => "$secret",
    "shop_transaction_id" => "$attr->{OPERATION_ID}",
    "auto_capture" => JSON::false,
    "init_time"    => "$main::DATE $main::TIME",
    "total_sum"    => $amount + 0,
    "currency"     => "$currency",
    "description"  => "$description",
    "return_url"   => "$return_url",
  };

  if ($self->{conf}{"PAYSYS_OC_NOTIFY"}) {
    $json_hash->{"notify_url"} = "$self->{conf}{\"PAYSYS_OC_NOTIFY\"}";
  }

  if ($self->{conf}{"PAYSYS_OC_LANGUAGE"}) {
    $json_hash->{"language"} = "$language";
  }

  if ($self->{conf}{"PAYSYS_OC_USER_DATA"}) {
    $json_hash->{"user_data"} =
       { "user_id"     => "$user->{UID}",
         "phone"       => "$user->{PHONE}",
         "email"       => "$user->{EMAIL}"
       };
  }

  if ($self->{conf}{"PAYSYS_OC_TEST"}) {
    $json_hash->{"test"} = JSON::true;
  }

  if ($self->{conf}{"PAYSYS_OC_CUSTOMER_IP"}) {
    $json_hash->{"customer_ip"} = ($ENV{'REMOTE_ADDR'}) ? "$ENV{'REMOTE_ADDR'}" : "$attr->{'REMOTE_ADDR'}";
  }

  if ($self->{conf}{"PAYSYS_OC_TTL"}) {
    $json_hash->{"ttl"} = $ttl + 0;
  }

  my $json_request = JSON::encode_json($json_hash);

  $json_request =~ s/\n//g;
  $json_request =~ s/\"/\\\"/g;

  my $payments_result = web_request(
    $url,
    {
      CURL         => 1,
      DEBUG        => 0,
      POST         => $json_request,
      HEADERS      => [ 'Content-Type: application/json'],
      JSON_RETURN  => 1
    }
  );

  if ($attr->{TEST_OCTO}) {
    return $payments_result;
  }

  if($payments_result->{errno} || $payments_result->{error}) {
    $html->message('err', "$self->{lang}->{ERROR}", "$self->{lang}->{ERR_MESSAGE_JSON}");
    return 0;
  }

  my %TEMPLATE_ARGS = ();
  $TEMPLATE_ARGS{LINK} = $payments_result->{octo_pay_url};

  return $html->tpl_show(
    main::_include('paysys_octo_user_portal', 'Paysys'),
    {
      %TEMPLATE_ARGS
    },
    { OUTPUT2RETURN => 0 }
  );
}

#**********************************************************
=head2 proccess()

  Payment Request:
   {
     "status": "waiting_for_capture",
     "shop_transaction_id": 10000,
     "octo_payment_UUID": "1145df74-bb95-47cf-a616-8d6dcee2e222",
     "signature": "sd8fg5sd87f6g",
     "hash_key": "453fg54j3f6g"
  }

  Payment Responce:
  {
    "accept_status": "capture"
  }

=cut
#**********************************************************
sub proccess {
  my $self = shift;
  my ($FORM) = @_;

  print "Content-Type: application/json\n\n";

  my $json_payment_result = $FORM->{__BUFFER} || $FORM->{JSON_TEST};

  my $hash_payment_result;
  
  unless ($FORM->{JSON_TEST} && (ref($json_payment_result) eq 'HASH')) {
    $hash_payment_result = $json->decode($json_payment_result);
  }
  else {
    $hash_payment_result = $json_payment_result;
  }

  my $status = $hash_payment_result->{status};
  my $transaction_id = $hash_payment_result->{shop_transaction_id};
  my $octo_payment = $hash_payment_result->{octo_payment_UUID};
  my $hash_key = $hash_payment_result->{hash_key};
  my $secret = $self->{conf}{"PAYSYS_OC_SECRET_KEY"};

  $status = $FORM->{STATUS_TEST} if ($FORM->{JSON_TEST});
  use Digest::SHA qw(sha1_hex);

  my $signature;
  if ($FORM->{JSON_TEST}) {
    $signature = uc(sha1_hex(uc(sha1_hex('yahont' . $secret . $FORM->{HASH_KEY})) . $FORM->{UUID} . $FORM->{STATUS_TEST}))
  }
  else {
    $signature = uc(sha1_hex(uc(sha1_hex('yahont' . $secret . $hash_key)) . $octo_payment . $status));
  }

  if ($FORM->{JSON_TEST}) {
    if ($signature ne uc($FORM->{SIGNATURA_TEST})) {
      return 2; 
    }
  }
  else {
    if ($signature ne uc($hash_payment_result->{signature})) {
      print qq({ "error": "wrong signature" });
      return 0;
    }
  }
  
  my $oc_info = {
    OC_UUID => $octo_payment
  };

  if ($status eq 'waiting_for_capture') {
    if ($FORM->{JSON_TEST}) {
      return 1;
    }

    my ($status_code) = main::paysys_pay({
      PAYMENT_SYSTEM    => $PAYSYSTEM_SHORT_NAME,
      PAYMENT_SYSTEM_ID => $PAYSYSTEM_ID,
      ORDER_ID          => "OC:$transaction_id",
      EXT_ID            => $transaction_id,
      DATA              => $oc_info,
      DATE              => "$main::DATE $main::TIME",
      MK_LOG            => 1,
      DEBUG             => $self->{DEBUG},
      PAYMENT_DESCRIBE  => $FORM->{description} || 'OCTO Payments',
    });

    if ($status_code == 0) {
      print qq({ "accept_status": "capture" });
      return 1;
    }
	elsif($status eq 'canceled'){
    my $cancel_result = main::paysys_pay_cancel({
      TRANSACTION_ID => "OC:$transaction_id"
    });

    print qq({ "accept_status": "cancel" });
    }
    else {
      print qq({ "accept_status": "cancel" });
    }
  }
  else {
    print qq({ "accept_status": "cancel" });
  }

  return 1;
}

1;
