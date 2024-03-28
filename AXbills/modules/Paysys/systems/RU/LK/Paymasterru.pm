package Paysys::systems::Paymasterru;
=head1 Paymaster Ru
  Module for TPaymaster Ru payment system
  Interface for Paymaster RU
  Date: 03.05.2017
  protocol: В личном кабнете Paymaster  https://paymaster.ru/docs/ru/wmi/#h1

  Date: 05.08.2019
  Update: 19.11.2020
=cut
use strict;
use warnings FATAL => 'all';

use AXbills::Base qw(_bp in_array);
use AXbills::Misc qw(load_module);

require Paysys::Paysys_Base;

our $PAYSYSTEM_NAME = 'PaymasterRU';
our $PAYSYSTEM_SHORT_NAME = 'PM';

our $PAYSYSTEM_ID = 97;
our $PAYSYSTEM_VERSION = '7.02';
our %PAYSYSTEM_CONF = (
  "PAYSYS_PAYMASTERRU_ACCOUNT_KEY"   => '',
  "PAYSYS_PAYMASTERRU_SECRET_KEY"    => '',
  "PAYSYS_PAYMASTERRU_CURRENCY"      => '',
  "PAYSYS_PAYMASTERRU_MERCHANT_ID"   => '',
  "PAYSYS_PAYMASTERRU_SIM_MODE"      => '',
  "PAYSYS_PAYMASTERRU_ITEMS_NAME"    => '',
  "PAYSYS_PAYMASTERRU_ITEMS_QTY"     => '',
  "PAYSYS_PAYMASTERRU_ITEMS_TAX"     => '',
  "PAYSYS_PAYMASTERRU_ITEMS_METHOD"  => '',
  "PAYSYS_PAYMASTERRU_ITEMS_SUBJECT" => '',
);

my $CUSTOM_NAME = uc($PAYSYSTEM_NAME);
my $CUSTOM_ID = $PAYSYSTEM_ID;
my $html;

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

  if ($attr->{CUSTOM_NAME}) {
    $CUSTOM_NAME = uc($attr->{CUSTOM_NAME});
    $PAYSYSTEM_SHORT_NAME = substr($CUSTOM_NAME, 0, 3);
  };

  if ($attr->{CUSTOM_ID}) {
    $CUSTOM_ID = $attr->{CUSTOM_ID};
  };

  bless($self, $class);

  return $self;
}
#**********************************************
=head2 proccess(\%FORM) - function that proccessing payment
                          on paysys_check.cgi

  Arguments:
    $FORM - HASH REF to %FORM
    XML

  Returns:

=cut
#**********************************************

sub proccess {
  my $self = shift;
  my ($FORM) = @_;

  my $payment_system    = 'PM_RU';
  my $payment_system_id = 122;
  main::load_pmodule('Digest::MD5');
  print "Content-Type: text/plain\n\n";

  if ( $FORM->{'LMI_PREREQUEST'} && $FORM->{'LMI_PREREQUEST'} == 1 ){
    print "YES";
  }
  elsif($FORM->{LMI_HASH}){
    my $hash = ($FORM->{LMI_MERCHANT_ID}      || '') . ';' .
      ($FORM->{LMI_PAYMENT_NO}       || '') . ';' .
      ($FORM->{LMI_SYS_PAYMENT_ID}   || '') . ';' .
      ($FORM->{LMI_SYS_PAYMENT_DATE} || '') . ';' .
      ($FORM->{LMI_PAYMENT_AMOUNT}   || '') . ';' .
      ($FORM->{LMI_CURRENCY}         || '') . ';' .
      ($FORM->{LMI_PAID_AMOUNT}      || '') . ';' .
      ($FORM->{LMI_PAID_CURRENCY}    || '') . ';' .
      ($FORM->{LMI_PAYMENT_SYSTEM}   || '') . ';' .
      (defined $FORM->{LMI_SIM_MODE} ? $FORM->{LMI_SIM_MODE} : '') . ';';
    my $secret_key = $self->{conf}{"PAYSYS_" . $CUSTOM_NAME . "_SECRET_KEY"} || '';
    $hash .= $secret_key;
    my $base64_md5_hash = Digest::MD5::md5_base64($hash).'==';

    # print $base64_md5_hash;

    main::mk_log("$base64_md5_hash - $FORM->{LMI_HASH}", { PAYSYS_ID => "$CUSTOM_ID/$CUSTOM_NAME", REQUEST => 'Check MD5' });
    main::mk_log("$hash", { PAYSYS_ID => "$CUSTOM_ID/$CUSTOM_NAME", REQUEST => 'Check MD5  HASH' });
    if($FORM->{LMI_HASH} eq $base64_md5_hash){
      my $CHECK_FIELD = $self->{conf}{"PAYSYS_" . $CUSTOM_NAME . "_ACCOUNT_KEY"} || 'UID';
      my $status_code = main::paysys_pay({

        PAYMENT_SYSTEM      => $payment_system,
        PAYMENT_SYSTEM_ID => $payment_system_id,
        CHECK_FIELD       => $CHECK_FIELD,
        USER_ID           => $FORM->{USER},
        SUM               => $FORM->{LMI_PAYMENT_AMOUNT},
        EXT_ID            => $FORM->{LMI_PAYMENT_NO},
        # IP                => $FORM{IP},
        DATA              => $FORM,
        MK_LOG            => 1,
        DEBUG             => 1,
        PAYMENT_DESCRIBE  => 'Paymaster Ru',
      });

      print "Status = $status_code";
    }
  }

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
  $SETTINGS{ID} = $CUSTOM_ID;
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
sub user_portal{
  my $self = shift;
  my ($user, $attr) = @_;

  if ($attr->{FALSE}) {
    main::paysys_show_result({ TRANSACTION_ID => "$attr->{LMI_PAYMENT_NO}", FALSE => 1 });
    return 1;
  }
  elsif ($attr->{TRUE}) {
    main::paysys_show_result({ TRANSACTION_ID =>  "PM_RU:$attr->{LMI_PAYMENT_NO}" });
    return 0;
  }

  my $MERCHANT_ID   = $self->{conf}{"PAYSYS_" . $CUSTOM_NAME . "_MERCHANT_ID"} || '';
  my $CURRENCY      = $self->{conf}{"PAYSYS_" . $CUSTOM_NAME . "_CURRENCY"} || 'RUB';
  my $ACCOUNT_KEY   = $self->{conf}{"PAYSYS_" . $CUSTOM_NAME . "_ACCOUNT_KEY"} || 'RUB';
  my $SIM_MODE      = $self->{conf}{"PAYSYS_" . $CUSTOM_NAME . "_SIM_MODE"} || '';
  my $ITEMS_NAME    = $self->{conf}{"PAYSYS_" . $CUSTOM_NAME . "_ITEMS_NAME"} || '';
  my $ITEMS_QTY     = sprintf('%.3f', $self->{conf}{"PAYSYS_" . $CUSTOM_NAME . "_ITEMS_QTY"}) || sprintf('%.3f', 1);
  my $ITEMS_TAX     = $self->{conf}{"PAYSYS_" . $CUSTOM_NAME . "_ITEMS_TAX"} || 'no_vat';
  my $ITEMS_METHOD  = $self->{conf}{"PAYSYS_" . $CUSTOM_NAME . "_ITEMS_METHOD"} || '3';
  my $ITEMS_SUBJECT = $self->{conf}{"PAYSYS_" . $CUSTOM_NAME . "_ITEMS_SUBJECT"} || '10';

  my %INFO;

  if(defined $user->{EMAIL}){
    $INFO{LMI_PAYER_EMAIL} = $user->{EMAIL};
  }

  $INFO{ORDER_ID} = $attr->{OPERATION_ID};
  $INFO{SUM}      = $attr->{SUM};
  $INFO{LMI_MERCHANT_ID} = $MERCHANT_ID;
  $INFO{CURRENCY}        = $CURRENCY;
  $INFO{USER}            = $user->{$ACCOUNT_KEY};
  $INFO{NOTIFICATION_URL} = $ENV{PROT}.'://'. $ENV{SERVER_NAME}.':'. $ENV{SERVER_PORT} . '/paysys_check.cgi';
  $INFO{FAILURE_URL} = $ENV{PROT}.'://'. $ENV{SERVER_NAME}.':'. $ENV{SERVER_PORT} . '/paysys_check.cgi?FALSE=1';
  $INFO{SUCCESS_URL} = $ENV{PROT}.'://'. $ENV{SERVER_NAME}.':'. $ENV{SERVER_PORT} . '/index.cgi?TRUE=1';
  $INFO{SIM_MODE}    = $SIM_MODE;
  $INFO{NAME}    = $ITEMS_NAME .' '. ($user->{CONTRACT_ID} || $user->{LOGIN});
  $INFO{QTY}     = $ITEMS_QTY;
  $INFO{PRICE}   = $attr->{SUM};
  $INFO{TAX}     = $ITEMS_TAX;
  $INFO{METHOD}  = $ITEMS_METHOD;
  $INFO{SUBJECT} = $ITEMS_SUBJECT;
  #AXbills::Base::_bp('', \%INFO, {HEADER=>1});
  $html->tpl_show(main::_include('paysys_paymasterru_add', 'Paysys'), {%INFO});

  return 1;
}

1;

