=head1 Fondy
  New module for Fondy

  Documentaion:

  Date: 09.07.2019
  Update:10.07.2019

  Version: 7.01
=cut


use strict;
use warnings;
use AXbills::Base qw(_bp load_pmodule);
use Paysys;
require Paysys::Paysys_Base;
package Paysys::systems::Fondy;

our $PAYSYSTEM_NAME = 'Fondy';
our $PAYSYSTEM_SHORT_NAME = 'FN';
our $PAYSYSTEM_ID = 109;
our $PAYSYSTEM_VERSION = '7.01';
our %PAYSYSTEM_CONF = (
  'PAYSYS_FONDY_MERCH_ID' => '',
  'PAYSYS_FONDY_PASSWORD' => '',
  'PAYSYS_FONDY_CURRENCY' => 'UAH'
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
  $SETTINGS{ID}      = $PAYSYSTEM_ID;
  $SETTINGS{NAME}    = $PAYSYSTEM_NAME;
  $SETTINGS{CONF}    = \%PAYSYSTEM_CONF;

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
  my %pay_params = ();

  if (!$self->{conf}{PAYSYS_FONDY_MERCH_ID} || !$self->{conf}{PAYSYS_FONDY_PASSWORD} || !$self->{conf}{PAYSYS_FONDY_CURRENCY}) {
    $html->message('err', $lang->{ERROR}, "Payment system has wrong configuration");
    return 0;
  }
  if (!$attr->{SUM} || $attr->{SUM} == 0) {
    $html->message('err', $lang->{ERROR}, "Payment sum is too small.");
    return 0;
  }

  $pay_params{ORDER_ID}            = $attr->{OPERATION_ID};
  $pay_params{AMOUNT}              = $attr->{SUM} * 100;
  $pay_params{ORDER_DESC}          = $attr->{DESCRIBE};
  $pay_params{CURRENCY}            = $self->{conf}{PAYSYS_FONDY_CURRENCY};
  $pay_params{MERCHANT_ID}         = $self->{conf}{PAYSYS_FONDY_MERCH_ID};
  $pay_params{MERCHANT_DATA}       = $attr->{UID} || $user->{UID};
  $pay_params{SERVER_CALLBACK_URL} = "$ENV{PROT}://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}/paysys_check.cgi";;
  #  $pay_params{RESPONSE_URL} = "$ENV{PROT}://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}/index.cgi?TRUE=1&index=$attr->{index}&OPERATION_ID="
  #    . "$attr->{OPERATION_ID}&PAYMENT_SYSTEM=$attr->{PAYMENT_SYSTEM}";

  my $signature = qq{$self->{conf}{PAYSYS_FONDY_PASSWORD}|};

  foreach my $item (sort keys %pay_params) {
    $signature .= $pay_params{$item} . "|";
  }
  $signature = substr($signature, 0, -1);

  AXbills::Base::load_pmodule('Digest::SHA');
  $pay_params{SIGNATURE}   = Digest::SHA::sha1_hex($signature);
  $pay_params{FORM_ACTION} = qq{https://api.fondy.eu/api/checkout/redirect/};
  $pay_params{SUM}         = $attr->{SUM};

  return $html->tpl_show(main::_include('paysys_fondy_add', 'Paysys'), { %pay_params }, { OUTPUT2RETURN => 0 });
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

  print "Content-Type: text/plain\n\n";
  my $pass = $self->{conf}{PAYSYS_FONDY_PASSWORD} || '';
  my $sign_string = $pass . '|';

  foreach my $name (sort keys %{$FORM}) {
    if ($name eq 'response_signature_string' || $name eq 'signature' || $FORM->{$name} eq '' || $name eq '__BUFFER') {
    }
    else {
      #      $sign_string = $sign_string . ("%-8s %s\n", $name, $FORM->{$name}) . '|';
      $sign_string = $sign_string . $FORM->{$name} . '|';
    }
  }

  $sign_string = substr($sign_string, 0, -1);
  AXbills::Base::load_pmodule('Digest::SHA');
  my $signature = Digest::SHA::sha1_hex($sign_string);

  if ($FORM->{order_status} eq 'approved') {
    if ($signature eq $FORM->{signature}) {
      my $paysys_status = main::paysys_pay(
        {
          PAYMENT_SYSTEM    => $PAYSYSTEM_SHORT_NAME,
          PAYMENT_SYSTEM_ID => $PAYSYSTEM_ID,
          CHECK_FIELD       => 'UID',
          USER_ID           => $FORM->{merchant_data},
          SUM               => $FORM->{amount} / 100,
          EXT_ID            => $FORM->{order_id},
          DATA              => $FORM,
          MK_LOG            => 1,
        }
      );
      main::mk_log("RESULT: status - $paysys_status", { PAYSYS_ID => "$PAYSYSTEM_NAME" });

    }
    else {
      main::mk_log("Bad signature - $FORM->{signature} - $signature", { PAYSYS_ID => $PAYSYSTEM_SHORT_NAME });
    }
  }

  return 1;
}
1;
