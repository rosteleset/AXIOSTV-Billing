=head1 Tinkoff bank
  Module for Tinkoff Bank payment system
  Interface for YTinkoff Bank
  Date: 12.04.2017
  protocol: https://oplata.tinkoff.ru/documentation/?section=termins
=cut

our %PAYSYSTEM_CONF    = ('PAYSYS_TINKOFF_TERMINAL_KEY'     => '',
                          'PAYSYS_TINKOFF_SECRET_KEY'       => '',);
our $PAYSYSTEM_IP      = '';
our $PAYSYSTEM_VERSION = 1.01;
our $PAYSYSTEM_NAME    = 'Tinkoff';

#**********************************************************
=head2 tinkoff_check_payment () -

  Arguments:
    ATTRIBUTES -
  Returns:

  Examples:

=cut
#**********************************************************
sub tinkoff_check_payment {
  my ($attr) = @_;
  print "Content-Type: text/html\n\n";
  my $payment_system    = 'Tinkoff';
  my $payment_system_id = 120;


  if($FORM{Status} eq 'AUTHORIZED'){
    print 'OK';
  }
  elsif($FORM{Status} eq 'CONFIRMED'){
    my $paysys_status = paysys_pay(
          {
            PAYMENT_SYSTEM    => $payment_system,
            PAYMENT_SYSTEM_ID => $payment_system_id,
            #CHECK_FIELD       => $conf{PAYSYS_YANDEX_KASSA_ACCOUNT_KEY},
            #USER_ID           => $FORM{customerNumber},
            SUM               => ($FORM{Amount} / 100),
            ORDER_ID          => "$payment_system:$FORM{OrderId}",
            EXT_ID            => $FORM{OrderId},
            # REGISTRATION_ONLY => 1,
            DATA              => \%FORM,
            MK_LOG            => 1,
            DEBUG             => 1,
            PAYMENT_DESCRIBE  => 'Tinkoff bank',
          }
        );

    if($paysys_status == 0){
      print 'OK';
    }
    else{
      print 'ERROR';
    }
  }
  elsif($FORM{Status} eq 'REFUNDED'){
    my $result = paysys_pay_cancel({
                  TRANSACTION_ID => "$payment_system:$FORM{OrderId}"
    });

    if($result == 0){
      print 'OK';
    }
    else{
      print 'ERROR';
    }
  }
  elsif($FORM{Status} eq 'REJECTED'){
    my $paysys_status = paysys_pay(
      {
        PAYMENT_SYSTEM    => $payment_system,
        PAYMENT_SYSTEM_ID => $payment_system_id,
        #CHECK_FIELD       => $conf{PAYSYS_YANDEX_KASSA_ACCOUNT_KEY},
        #USER_ID           => $FORM{customerNumber},
#        SUM               => ($FORM{Amount} / 100),
        ORDER_ID          => "$payment_system:$FORM{OrderId}",
        EXT_ID            => $FORM{OrderId},
        # REGISTRATION_ONLY => 1,
        DATA              => \%FORM,
        MK_LOG            => 1,
        DEBUG             => 1,
        ERROR             => 3,
        PAYMENT_DESCRIBE  => 'Tinkoff bank',
      }
    );

    if($paysys_status == 3){
      print "OK";
    }

  }

  return 1;
}


1
