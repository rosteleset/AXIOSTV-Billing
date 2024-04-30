=head1 Yandex Kassa

  New module for Yandex Kassa payment system

=head1 VERSION

  DATE: 20211126
  VERSION: 8.02

=cut

package Paysys::systems::Yandex_Kassa;
use strict;
use warnings FATAL => 'all';

use AXbills::Fetcher qw/web_request/;
use AXbills::Base qw/_bp load_pmodule urlencode/;
use UUID::Tiny ':std';
use Paysys;

our $PAYSYSTEM_NAME = 'YandexKassa';
our $PAYSYSTEM_SHORT_NAME = 'YK';
our $PAYSYSTEM_ID = 117;
our $PAYSYSTEM_VERSION = '8.02';

our %PAYSYSTEM_CONF = (
  'PAYSYS_YK_SHOP_ID'    => '',
  'PAYSYS_YK_SECRET_KEY' => '',
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

  my %SETTINGS = (
    VERSION => $PAYSYSTEM_VERSION,
    ID      => $PAYSYSTEM_ID,
    NAME    => $PAYSYSTEM_NAME,
    CONF    => \%PAYSYSTEM_CONF,
    IP      => '109.235.160.0/21,185.71.76.0/22,77.75.152.0/21',
    DOCS    => 'http://billing.axiostv.ru:8090/pages/viewpage.action?pageId=11404160',
  );

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

  my $Paysys = Paysys->new($self->{db}, $self->{admin}, $self->{conf});

  $Paysys->add({
    SYSTEM_ID      => $attr->{PAYMENT_SYSTEM},
    SUM            => $attr->{SUM},
    UID            => $attr->{UID} || $user->{UID},
    IP             => "$ENV{'REMOTE_ADDR'}",
    TRANSACTION_ID => "YK:$attr->{OPERATION_ID}",
    STATUS         => 1,
    DOMAIN_ID      => $user->{DOMAIN_ID},
    FIO            => $user->{FIO},
    PHONE          => $user->{PHONE},
    EMAIL          => $user->{EMAIL}
  });

  if ($Paysys->{errno}) {
    $html->message('err', "ERROR", "ERROR Paysys ID: '$attr->{OPERATION_ID}'");
    return 0;
  }

  if (!$user->{PHONE} && !$user->{EMAIL}) {
    $html->message('err', "$self->{lang}->{ERROR}", "$self->{lang}->{ERR_MESSAGE}");
  }

  $user->{PHONE} =~ s/\+//g;

  my $url = 'https://payment.yandex.net/api/v3/payments';
  my $return_url = "$ENV{PROT}://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}/index.cgi?index=$attr->{index}&PAYMENT_SYSTEM=$attr->{PAYMENT_SYSTEM}&TRANSACTION_ID=YK:$attr->{OPERATION_ID}";
  my $user_info = ($user->{EMAIL}) ? qq{"email" : "$user->{EMAIL}"} : qq{"phone": "$user->{PHONE}"};

  my $json_request = qq({
   "amount": {
       "value": "$attr->{SUM}",
       "currency": "RUB"
   },
   "confirmation": {
      "type": "redirect",
      "return_url": "$return_url"
   },
   "capture": 1,
   "metadata":{
     "order_id": "$attr->{OPERATION_ID}",
     "uid": "$user->{UID}"
   },
   "receipt": {
      "customer": {
        "full_name": "$user->{FIO}",
        $user_info
       },
       "items": [
            {
              "description": "$attr->{DESCRIBE}",
              "quantity": "1.00",
              "amount": {
                "value": "$attr->{SUM}",
                "currency": "RUB"
              },
              "vat_code": "2",
              "payment_mode": "full_prepayment",
              "payment_subject": "commodity"
            }
          ]
   }
});

  $json_request =~ s/\n//g;
  $json_request =~ s/\"/\\\"/g;

  my $uuid_key = UUID::Tiny::create_uuid_as_string(UUID_V4);
  my $login = $self->{conf}{PAYSYS_YK_SHOP_ID} || q{};
  my $password = $self->{conf}{PAYSYS_YK_SECRET_KEY} || q{};

  my $payments_result = web_request(
    $url,
    {
      CURL         => 1,
      DEBUG        => 0,
      POST         => $json_request,
      CURL_OPTIONS => " -u $login:$password -X POST",
      HEADERS      => [ 'Content-Type: application/json', "Idempotence-Key: $uuid_key" ],
      JSON_RETURN  => 1
    }
  );

  if (!$payments_result) {
    $self->{errno} = 1010;
    $self->{errstr} = 'NO_RESULT';
    $html->message('err', $self->{lang}->{'ERROR'}, $self->{errstr});
    return 0;
  }
  elsif ($payments_result->{type} && $payments_result->{type} eq 'error') {
    $self->{errno} = 1011;
    $self->{errstr} = $payments_result->{id} . "\n"
      . $payments_result->{code} . "\n"
      . $payments_result->{description};
    $html->message('err', $self->{lang}->{'ERROR'}, $self->{errstr});
    return 0;
  }

  my %TEMPLATE_ARGS = ();
  $TEMPLATE_ARGS{URL} = $payments_result->{confirmation}{confirmation_url};

  return $html->tpl_show(
    main::_include('paysys_yandexkassa_user_portal', 'Paysys'),
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
	"type": "notification",
	"event": "payment.succeeded",
	"object": {
		"id": "2285f8f1-000f-5000-a000-191400ee4206",
		"status": "succeeded",
		"paid": true,
		"amount": {
			"value": "1.00",
			"currency": "RUB"
		},
		"captured_at": "2018-05-10T06:23:38.521Z",
		"created_at": "2018-05-10T06:23:36.828Z",
		"metadata": {
			"order_id": "03931526",
			"uid": "1"
		},
		"payment_method": {
			"type": "bank_card",
			"id": "2285f8f1-000f-5000-a000-191400ee4206",
			"saved": false,
			"card": {
				"first6": "111111",
				"last4": "1026",
				"expiry_month": "12",
				"expiry_year": "2020",
				"card_type": "Unknown"
			},
			"title": "Bank card *1026"
		},
		"recipient": {
			"account_id": "507606",
			"gateway_id": "1513590"
		},
		"refunded_amount": {
			"value": "0.00",
			"currency": "RUB"
		},
		"test": true
	}
}


=cut
#**********************************************************
sub proccess {
  my $self = shift;
  my ($FORM) = @_;

  my $json_payment_result = $FORM->{__BUFFER};

  my $hash_payment_result = $json->decode($json_payment_result);

  my $status = $hash_payment_result->{object}{status};
  my $order_id = $hash_payment_result->{object}{metadata}{order_id};
  my $uid = $hash_payment_result->{object}{metadata}{uid};
  my $sum = $hash_payment_result->{object}{amount}{value};

  if ($status eq 'succeeded') {

    my ($status_code) = main::paysys_pay({
      PAYMENT_SYSTEM    => $PAYSYSTEM_SHORT_NAME,
      PAYMENT_SYSTEM_ID => $PAYSYSTEM_ID,
      ORDER_ID          => "YK:$order_id",
      EXT_ID            => $order_id,
      USER_ID           => $uid,
      SUM               => $sum,
      DATA              => $FORM,
      DATE              => "$main::DATE $main::TIME",
      MK_LOG            => 1,
      DEBUG             => $self->{DEBUG},
      PAYMENT_DESCRIBE  => $FORM->{description} || 'Payments',
    });

    if ($status_code == 0) {
      print "Content-Type: text/html\n\n";
      print '';
      return 1;
    }
    else {
      print qq{Status: 520 Something Wrong
Content-type: text/html

<HTML>
<HEAD><TITLE>520 Something wrong</TITLE></HEAD>
<BODY>
  <H1>Error</H1>
  <P>Something wrong</P>
</BODY>
</HTML>
    };
    }
  }
  else {
    print qq{Status: 520 Wrong Status
Content-type: text/html

<HTML>
<HEAD><TITLE>520 Wrong Status</TITLE></HEAD>
<BODY>
  <H1>Error</H1>
  <P>Wrong Status</P>
</BODY>
</HTML>
    };
  }

  return 1;
}

1;