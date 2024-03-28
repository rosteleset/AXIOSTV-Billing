=head1 Paykeeper1
  New module for Paykeeper1 payment system

  Version:7.02

  Date: 04.05.2018
  Updated: 09.09.2019
=cut

package Paysys::systems::Paykeeper1;
use strict;
use warnings FATAL => 'all';

use AXbills::Fetcher qw/web_request/;
use AXbills::Base qw/_bp load_pmodule urlencode/;

our $PAYSYSTEM_NAME = 'Paykeeper1';
our $PAYSYSTEM_SHORT_NAME = 'SB';
our $PAYSYSTEM_ID = 127;

our $PAYSYSTEM_VERSION = '7.02';

our %PAYSYSTEM_CONF = (
  PAYSYS_SBERBANK_USERNAME => '',
  PAYSYS_SBERBANK_PASSWORD => '',
  PAYSYS_SBERBANK_KEY      => '',
  PAYSYS_SBERBANK_URL      => '',
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

  load_pmodule('JSON');
  $json = JSON->new->allow_nonref;

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

=cut
#**********************************************************
sub user_portal {
  my $self = shift;
  my ($user, $attr) = @_;

  if ($attr->{TRANSACTION_ID}) {
    main::paysys_show_result({ %$attr });
    return 1;
  }

  use Paysys;
  my $Paysys = Paysys->new($self->{db}, $self->{admin}, $self->{conf});

  $Paysys->add({
    SYSTEM_ID      => $attr->{PAYMENT_SYSTEM},
    SUM            => $attr->{SUM},
    UID            => $attr->{UID} || $user->{UID},
    IP             => "$ENV{'REMOTE_ADDR'}",
    TRANSACTION_ID => "SB:$attr->{OPERATION_ID}",
    STATUS         => 1,
    DOMAIN_ID      => $user->{DOMAIN_ID}
  });

  my $amount = $attr->{SUM} * 100;

  my $url_conf = $self->{conf}{PAYSYS_SBERBANK_URL};
  $url_conf =~ s/\/$//;

  my $url = qq[$url_conf/payment/rest/register.do?amount=$amount&language=ru&orderNumber=$attr->{OPERATION_ID}&]
    . qq[password=] . urlencode($self->{conf}{PAYSYS_SBERBANK_PASSWORD}) . qq[&userName=$self->{conf}{PAYSYS_SBERBANK_USERNAME}&]
    . qq[jsonParams=];

  $url .= urlencode(qq[{"uid":$user->{UID}}]);
  $url .= "&returnUrl=" . urlencode("$ENV{PROT}://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}/index.cgi?index=$attr->{index}&PAYMENT_SYSTEM=$attr->{PAYMENT_SYSTEM}&TRANSACTION_ID=SB:$attr->{OPERATION_ID}");

  my $do_register_result = web_request(
    $url,
    {
      CURL => 1,
    }
  );
  
  my $RESULT_HASH = $json->decode($do_register_result);

  if ($RESULT_HASH->{errorCode}) {
    $html->message("err", "Error code $RESULT_HASH->{errorCode}", "$RESULT_HASH->{errorMessage}")
  }
  else {
    return $html->tpl_show(
      main::_include('paysys_sberbank_user_portal', 'Paysys'),
      {
        URL => $RESULT_HASH->{formUrl},
      },
      { OUTPUT2RETURN => 0 }
    );
  }
}

#**********************************************************
=head2 process()

  Payment Request:
    operation => deposited
    amount => 100
    mdOrder => 3ff6962a-7dcc-4283-ab50-a6d7dd3386fe
    orderNumber => 35351086
    status => 1
    checksum => DBBE9E54D42072D8CAF32C7F660DEB82086A25C14FD813888E231A99E1220AB3


=cut
#**********************************************************
sub proccess {
  my $self = shift;
  my ($FORM) = @_;

  if ($FORM->{operation} && $FORM->{operation} ne 'deposited') {
    print qq{Status: 520 Wrong Operation
Content-type: text/html

<HTML>
<HEAD><TITLE>520 Wrong Operation</TITLE></HEAD>
<BODY>
  <H1>Error</H1>
  <P>Wrong Operation</P>
</BODY>
</HTML>
    };

    return 0;
  }

  if (defined($FORM->{status}) && $FORM->{status} != 1) {
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

    return 0;
  }

  my $checksum = $FORM->{checksum} || '';
  my $key = $self->{conf}{PAYSYS_SBERBANK_KEY} || '';
  delete $FORM->{checksum};
  delete $FORM->{__BUFFER};

  my $checksum_raw_string = '';
#  foreach my $form_key (sort keys %{$FORM}) {
#    $checksum_raw_string .= $form_key . ";" . $FORM->{$form_key} . ";";
#  }
#  use Digest::SHA qw(hmac_sha256_hex);
#
#  my $new_checksum = Digest::SHA::hmac_sha256_hex($checksum_raw_string, $key);
#  $new_checksum = uc($new_checksum);
#
#  if ($checksum ne $new_checksum) {
#    print qq{Status: 520 Wrong Checksum
#Content-type: text/html
#
#<HTML>
#<HEAD><TITLE>520 Wrong Checksum</TITLE></HEAD>
#<BODY>
#  <H1>Error</H1>
#  <P>Wrong Checksum</P>
#</BODY>
#</HTML>
#    };
#
#    if ($self->{DEBUG} > 3) {
#      `echo "TEST" >> /tmp/buffer`;
#      _bp("My Raw String For Checksum", $checksum_raw_string);
#      _bp("My New Checksum", $new_checksum);
#      _bp("Paykeeper1 Checksum", $checksum);
#    }
#    return 0;
#  }

  my $order = $FORM->{orderNumber};

  my ($status_code) = main::paysys_pay({
    PAYMENT_SYSTEM    => $PAYSYSTEM_SHORT_NAME,
    PAYMENT_SYSTEM_ID => $PAYSYSTEM_ID,
    ORDER_ID          => "SB:$order",
    EXT_ID            => $order,
    #SUM               => $sum,
    DATA              => $FORM,
    DATE              => "$main::DATE $main::TIME",
    MK_LOG            => 1,
    DEBUG             => $self->{DEBUG},
    PAYMENT_DESCRIBE  => $FORM->{description} || 'Сбербанк',
  });

  if ($status_code == 0) {
    print "Content-Type: text/html\n\n";
    print '';
    return 1;
  }

  return 1;
}

1;
