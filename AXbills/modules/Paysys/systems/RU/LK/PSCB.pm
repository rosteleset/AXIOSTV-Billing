=head1 PSCB
  New module for PSCB

  Documentaion: https://docs.pscb.ru/oos/api.html

  Date: 24.01.2019
  UPDATE: 02.10.2019
  Version: 7.02
=cut


use strict;
use warnings;
use AXbills::Base qw(_bp load_pmodule decode_base64 encode_base64);
use AXbills::Misc qw();
require Paysys::Paysys_Base;
package Paysys::systems::PSCB;
AXbills::Base::load_pmodule('Crypt::ECB');
#AXbills::Base::load_pmodule('MIME::Base64');
AXbills::Base::load_pmodule('JSON');
use Digest::MD5 qw[md5];
use Paysys;

our $PAYSYSTEM_NAME = 'PSCB';
our $PAYSYSTEM_SHORT_NAME = 'PSCB';
our $PAYSYSTEM_ID = 132;
our $PAYSYSTEM_VERSION = '7.02';

our %PAYSYSTEM_CONF = (
  PAYSYS_PSCB_MARKET_PLACE => '',
  PAYSYS_PSCB_SECRET_KEY   => '',
);

my ($html, $json);


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

  #$json = JSON->new->allow_nonref;
  $json = JSON->new->utf8(0);

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

  if ($attr->{TRANSACTION_ID}) {
    main::paysys_show_result({ %$attr });
    return 1;
  }

  my %MESSAGE_HASH = (
    amount          => $attr->{SUM},
    orderId         => $attr->{OPERATION_ID},
    customerAccount => $user->{LOGIN},
    successUrl      => "$ENV{PROT}://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}/index.cgi?index=$attr->{index}&PAYMENT_SYSTEM=$attr->{PAYMENT_SYSTEM}&TRANSACTION_ID=PSCB:$attr->{OPERATION_ID}",
    nonce           => AXbills::Base::mk_unique_value(10)
  );


  my $json_message = $json->encode(\%MESSAGE_HASH);
  require Digest::SHA;
  Digest::SHA->import('sha256_hex');
  my $signature = Digest::SHA::sha256_hex("$json_message" . $self->{conf}{PAYSYS_PSCB_SECRET_KEY});

  my $Paysys = Paysys->new($self->{db}, $self->{admin}, $self->{conf});
  #Add paysys
  $Paysys->add(
    {
      SYSTEM_ID      => $PAYSYSTEM_ID,
      SUM            => $attr->{SUM},
      UID            => $attr->{UID} || $user->{UID},
      IP             => $ENV{'REMOTE_ADDR'},
      TRANSACTION_ID => "$PAYSYSTEM_SHORT_NAME:$attr->{OPERATION_ID}",
      INFO           => $attr->{DESCRIBE},
      PAYSYS_IP      => "$ENV{'REMOTE_ADDR'}",
      STATUS         => 1,
      DOMAIN_ID      => $user->{DOMAIN_ID},
    }
  );

  if ($Paysys->{errno}) {
    $html->message('err', "ERROR", "ERROR Paysys ID: '$attr->{OPERATION_ID}'");
    return 0;
  }

  my $base_64_str =  AXbills::Base::encode_base64($json_message);
  $base_64_str =~ s/\n//gm;
  return $html->tpl_show(main::_include('paysys_pscb_add', 'Paysys'), {
      SIGNATURE => $signature,
      MESSAGE   =>  $base_64_str,
      MARKET_PLACE => $self->{conf}{PAYSYS_PSCB_MARKET_PLACE}
    }, { OUTPUT2RETURN => 0 });
}

#**********************************************************
=head2 proccess(\%FORM) - function that proccessing payment
                          on paysys_check.cgi

  Arguments:
    $FORM - HASH REF to %FORM

  Returns:

=cut
#**********************************************************
sub proccess {
  my $self = shift;
  my ($FORM) = @_;

#  # Открытый текст для шифрования
#  my $cleartext=$FORM->{__BUFFER};
#
#  # Ваш ключ (можно найти в кабинете в профиле).
#  # Получаем хэш MD5 в байтах
#  my $key       = Digest::MD5::md5('dragon');
#
#  # Сам алгоритм. см. https://metacpan.org/pod/Crypt::ECB
#  my $cipher = Crypt::ECB->new({
#    cipher  => 'Rijndael',
#    padding => 'standard',
#    key     => $key,
#  });
#
#  # Base64 кодированный результат шифрования
#  my $encrypted64 = AXbills::Base::encode_base64($cipher->encrypt($cleartext));
#  # Он же декодированный
#  my $decrypted = $cipher->decrypt(AXbills::Base::decode_base64($encrypted64));
#
#  # Проверка результата
#  print 'Encrypted: ' . $encrypted64;
#  print 'Decrypted: ' . $decrypted;
#  print "$cleartext eq $decrypted => " . ($cleartext eq $decrypted);
#
#
#
#  return 1;
  # Encrypted payments text
  my $encrypted_payments = $FORM->{__BUFFER};
  # MD5 from your key
  my $key       = Digest::MD5::md5($self->{conf}{PAYSYS_PSCB_SECRET_KEY});

  # Algoritm https://metacpan.org/pod/Crypt::ECB
  my $cipher = Crypt::ECB->new({
    cipher  => 'Rijndael',
    padding => 'standard',
    key     => $key,
  });

  # Decode text from payment system
  my $decrypted = $cipher->decrypt($encrypted_payments);
  my $payments = $json->decode($decrypted);
  
  my @PAYMENTS_ANSWER = ();
  
  foreach my $payment (@{$payments->{payments}}){
    my $external_payment_status = $payment->{state} || '';
    my $order_id = $payment->{orderId} || 0;
    my $amount   = $payment->{amount} || 0;

    if($external_payment_status eq 'end'){
      # Make payment
      # Show result
      my ($status_code) = main::paysys_pay({
        PAYMENT_SYSTEM    => $PAYSYSTEM_SHORT_NAME,
        PAYMENT_SYSTEM_ID => $PAYSYSTEM_ID,
        ORDER_ID          => "$PAYSYSTEM_SHORT_NAME:$order_id",
        EXT_ID            => $order_id,
#        USER_ID           => $uid,
        SUM               => $amount,
        DATA              => $payment,
        DATE              => "$main::DATE $main::TIME",
        MK_LOG            => 1,
        DEBUG             => $self->{DEBUG},
        PAYMENT_DESCRIBE  => $payment->{description} || 'Payments',
      });

      if($status_code == 0 || $status_code == 13 || $status_code == 9){
        push @PAYMENTS_ANSWER, {"orderId" => $order_id, "action" => "CONFIRM"};
      }
      else {
        push @PAYMENTS_ANSWER, {"orderId" => $order_id, "action" => "REJECT"};
      }
    }
    elsif($external_payment_status eq 'err'){
      # Make payment status eq 3
      # Show result
    }
  }

  return show_answer(\@PAYMENTS_ANSWER, {test => $FORM->{test}});
}

#**********************************************************
=head2 show_answer(\@PAYMENTS_ANSWER)

  Arguments:
    \@PAYMENTS_ANSWER -

  Returns:

=cut
#**********************************************************
sub show_answer {
  my ($PAYMENTS_ANSWER, $attr) = @_;
#   my $json_payments_answer = $json->encode($PAYMENTS_ANSWER);
  my %hash_answer = ( payments => '');
  $hash_answer{payments} = $PAYMENTS_ANSWER;
  my $json_payments_answer = $json->encode(\%hash_answer);

  if($attr->{test}){
    return $json_payments_answer;
  }
  else{
    print "Content-Type: text/html\n\n";
    print $json_payments_answer;
  }

  return 1;
}

1;
