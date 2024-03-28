package Paysys::systems::Plategka;
use strict;
use warnings FATAL => 'all';

use parent 'main';

use AXbills::Base qw(load_pmodule _bp);
use AXbills::Fetcher;
require Paysys::Paysys_Base;

my $PAYSYSTEM_NAME = 'Plategka';
my $PAYSYSTEM_SHORT_NAME = 'Plategka';

my $PAYSYSTEM_ID = 126;

my $PAYSYSTEM_VERSION = '1.00';
my $DEBUG = 1;
my %PAYSYSTEM_CONF = (
  PAYSYS_PLATEGKA_MERCHANT_ID => '',
  PAYSYS_PLATEGKA_SIGN_KEY => '',
);

my ($html);
my ($db, $admin, $conf);

#**********************************************************
=head2 new()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub new2 {
  my $class = shift;
  $conf = shift;
  my $FORM = shift;
  $admin = shift;
  $db = shift;
  my $attr = shift;

  my $self = {
    CONF => $conf,
    FORM => $FORM,
  };

  if ($attr->{HTML}) {
    $html = $attr->{HTML};
  }

  bless($self, $class);

  return $self;
}

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

  bless($self, $class);

  return $self;
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

  use Paysys;
  my $Paysys = Paysys->new($self->{db}, $self->{admin}, $self->{conf});

  $Paysys->add({
    SYSTEM_ID      => $attr->{PAYMENT_SYSTEM},
    SUM            => $attr->{SUM},
    UID            => $attr->{UID} || $user->{UID},
    IP             => "$ENV{'REMOTE_ADDR'}",
    TRANSACTION_ID => "PLT:$attr->{OPERATION_ID}",
    STATUS         => 1,
    DOMAIN_ID      => $user->{DOMAIN_ID} || 0,
  });

  if ($Paysys->{errno}) {
    return $html->message('err', "Error", "ERROR Paysys ID: '$attr->{OPERATION_ID}'");
  }

  my $signature = $self->_make_signature({
    MERCHANT_ID => $self->{conf}->{PAYSYS_PLATEGKA_MERCHANT_ID},
    ORDER_ID    => $attr->{OPERATION_ID},
    AMOUNT      => $attr->{SUM} * 100,
    DATE        => "$main::DATE $main::TIME",
    DESCRIPTION => '',
    SD          => '',
    BILLERS     => '',
    VERSION     => 4,
  });

  return $html->tpl_show(
    main::_include('paysys_plategka_add', 'Paysys'),
    {
      SUM              => $attr->{SUM},
      SUM_FOR_PLATEGKA => ($attr->{SUM} * 100),
      OPERATION_ID     => $attr->{OPERATION_ID},
      MERCHANT_ID      => $self->{conf}->{PAYSYS_PLATEGKA_MERCHANT_ID},
      DATE_TIME        => "$main::DATE $main::TIME",
      SD               => '',
      BILLERS          => '',
      SIGNATURE        => $signature
    },
    {OUTPUT2RETURN => 0}
  );
}

#**********************************************************
=head2 pay()

  Arguments:
     -

  Returns:


  Request:
  curl -d "order_id=22629903&status=1&text=success" "https://192.168.1.169:9443/paysys_check.cgi"
=cut
#**********************************************************
sub pay {
  my $self = shift;
  my $attr = shift;
  print "Content-Type: text/plain\n\n";

  my $order_id = $self->{FORM}->{order_id};
  my $date = $self->{FORM}->{date};
  my $plategka_status = $self->{FORM}->{status};
  my $account = $self->{FORM}->{sd};

  if ($plategka_status == 1) {
    my ($status_code) = main::paysys_pay({
      PAYMENT_SYSTEM    => $PAYSYSTEM_SHORT_NAME,
      PAYMENT_SYSTEM_ID => $PAYSYSTEM_ID,
      CHECK_FIELD       => 'UID',
      USER_ID           => $account,
      #      SUM               => $payment_amount,
      ORDER_ID          => "$PAYSYSTEM_SHORT_NAME:$order_id",
      DATA              => $self->{FORM},
      DATE              => $date,
      MK_LOG            => 1,
      DEBUG             => $DEBUG,
      ERROR             => 13,
      PAYMENT_DESCRIBE  => 'Plategka payment',
    });

    print $status_code;
  }
}

#**********************************************************
=head2 periodic()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub periodic {
  my $self = shift;

  use Paysys;
  my $Paysys = Paysys->new($db, $admin, $conf);

  my $list = $Paysys->list(
    {
      TRANSACTION_ID => "$PAYSYSTEM_SHORT_NAME:*" || '_SHOW',
      ID             => '_SHOW',
      DATETIME       => '_SHOW',
      STATUS         => 13,
      SUM            => '_SHOW',
      COLS_NAME      => 1,
      DOMAIN_ID      => '_SHOW',
      SKIP_DEL_CHECK => 1
    }
  );

#  foreach my $payment (@$list) {
#    my $merchant_id = "";
#    my (undef, $order_id) = split(':', $payment->{transaction_id});
    my $signature = _make_signature();
#    my $responce = web_request("https://www.plategka.com/gateway",
#      { POST => "merchant=$merchant_id&order_id=$order_id&step=approve&version=4&signature=$signature" });

#    if ($responce eq 'ok') {
#
#    }
#  }

}

#**********************************************************
=head2 get_paysys_settings()

  Arguments:
     -

  Returns:

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
=head2 _make_signature()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub _make_signature {
  my $self = shift;
  my ($attr)= @_;

  my $merchant_id = $attr->{MERCHANT_ID} || '123456';
  my $order_id = $attr->{ORDER_ID} || '123456';
  my $amount = $attr->{AMOUNT} || '123456';
  my $date = $attr->{DATE} || '123456';
  my $description = $attr->{DESCRIPTION} || '123456';
  my $sd = $attr->{SD} || '123456';
  my $billers = $attr->{BILLERS} || '123456';
  my $version = $attr->{VERSION} || '123456';

  my $sign_string = "$merchant_id;$order_id;$amount;$date;$description;$sd;$billers;$version";

#  open(my $fh, '<:encoding(UTF-8)', $conf->{PAYSYS_PLATEGKA_SIGN_KEY})
#    or die "Could not open file '$conf->{PAYSYS_PLATEGKA_SIGN_KEY}' $!";
#
#  my $key_string = '';
#  while (my $row = <$fh>) {
#    chomp $row;
#    $key_string .= $row;
#  }

  my $signature = main::cmd(qq[echo "$sign_string" | openssl dgst -sha256 -sign $self->{conf}{PAYSYS_PLATEGKA_SIGN_KEY}]);
  my $b64_signature = main::encode_base64($signature);


#  print $b64_signature;

  return $b64_signature;
}
1;