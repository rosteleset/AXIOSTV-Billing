#**********************************************************
=head1 NAME

  E-platezhka

 Interface for "Platezhka(E-platezhka)" payment system
 http://www.platezhka.com.ua/

=head1 VERSION

 VERSION: 0.10

=cut
#**********************************************************

#25.01.2016

our $VERSION = 0.10;

my $debug = $conf{PAYSYS_DEBUG} || 0;

if ($debug > 1) {
  print "Content-Type: text/plain\n\n";
}
else {
  print "Content-Type: text/xml\n\n";
}

platezhka();


#**********************************************************
#
#**********************************************************
sub platezhka {
  #my ($attr) = @_;

  my $payment_system       = 'Platezhka';
  my $payment_system_small = 'EP';
  my $payment_system_id    = 85;
  my $CHECK_FIELD          = $conf{PAYSYS_PLATEZHKA_ACCOUNT_KEY} || 'UID';

  my $xml =
'<?xml version="1.0" encoding="UTF-8"?><commandCall><login>platezhka</login><password>123456789</password><command>check</command><transactionID>69777</transactionID><payElementID>1</payElementID><account>12345</account></commandCall>';

  $xml = $FORM{'__BUFFER'} || '';

  if ($xml eq '') {
    mk_log("XML is empty", 
      { PAYSYS_ID => $payment_system });
  }

  load_pmodule('XML::Simple');

  my $_xml = eval { XML::Simple::XMLin($xml, forcearray => 1) };

  if ($@) {
    mk_log("Incorrect XML \n$xml\n". $@, 
      { PAYSYS_ID => $payment_system });
  }

  my $action  = $_xml->{command}->[0] || '';
  my $number  = $_xml->{account}->[0] || '';

  # my $type   = $FORM{type}   || 1;
  my $amount  = ($_xml->{amount}->[0] / 100) || 0;
  my $receipt = $_xml->{transactionID}->[0]  || 0;
  my $date    = $_xml->{payTimestamp}->[0]   || '';
  my $payId   = $_xml->{payID}->[0]          || $_xml->{cancelPayID}->[0];
  my $code;
  my $date_to_db;
  my $company_verification = 0;
  if ($date && $date =~ /^(\d{1,4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})$/) {
    $date_to_db = "$1-$2-$3 $4:$5:$6";
  }

  if ($payId == 0) {
    $payId = 1;
  }

  my $log_info = "login: $_xml->{login}->[0]
password: $_xml->{password}->[0]
command: $_xml->{command}->[0]
transactionID: $_xml->{transactionID}->[0]
payElementID: $_xml->{payElementID}->[0]
account: $_xml->{account}->[0]
payTimestamp: $_xml->{payTimestamp}->[0]
payID: $_xml->{payID}->[0]
cancelPayID: $_xml->{cancelPayID}->[0]
amount: $_xml->{amount}->[0]
";

  if ($debug > 1) {
    mk_log($log_info, { PAYSYS_ID => $payment_system });
  }

  #$conf{PAYSYS_COMPANY_INFO} = "1:user1:pass1,2:user2:pass2,3:user3:pass3";
  #$conf{PAYSYS_COMPANY_FIELD_NAME} = '_fid';

  if ($conf{PAYSYS_COMPANY_INFO}) {
    my $COMPANY_INFO = $conf{PAYSYS_COMPANY_INFO} || '';
    my @company_info = split(/,/, $COMPANY_INFO);
    my %LOGIN_INFO = ();

    my ($company_id, $company_login, $company_password);
    foreach my $val (@company_info) {
      ($company_id, $company_login, $company_password) = split(/:/, $val);
      $LOGIN_INFO{$company_login} = $company_id;
    }

    if (defined($LOGIN_INFO{ $_xml->{login}->[0] }) and defined($conf{PAYSYS_COMPANY_FIELD_NAME})) {
      $users->list({ $CHECK_FIELD                     => $number,
                     $conf{PAYSYS_COMPANY_FIELD_NAME} => $LOGIN_INFO{ $_xml->{login}->[0] }
                    });

      if ($users->{errno} || $users->{TOTAL} < 1) {
        code_message(5, $number, 0);
        return 0;
      }
      else {
        $company_verification = 1;
      }
    }
    else {
      code_message(7, $number, 0);
      return 0;
    }
  }


  if (($conf{PAYSYS_PLATEZHKA_LOGIN} eq $_xml->{login}->[0] 
       && $conf{PAYSYS_PLATEZHKA_PASSWORD} eq $_xml->{password}->[0])
       || $company_verification == 1) {

    #Check payment
    if ($action eq 'check') {
      if ($number ne '') {
        $users->list({ $CHECK_FIELD => $number });

        if ($users->{errno}) {
          $code = 1;
        }
        elsif ($users->{TOTAL} < 1) {
          $code = 5;
        }
        else {
          $code = 0;
        }

        code_message($code, $number, 0);
      }
      else {
        code_message(4, '', 0);
      }
    }

    # check in program 
    # Add payment ----------------------- #
    elsif ($action eq 'pay') {
      if ($receipt !~ /^(\d+)$/ and $amount !~ /^(\d+)?\.?(\d+)$/ and $number ne '') {
        code_message(8, $number, 0);
        return 0;
      }

      if ($CHECK_FIELD eq 'UID') {
        $user = $users->info($number);
        $user->pi({ UID => $number });
      }
      else {
        my $list = $users->list({ $CHECK_FIELD => $number, COLS_NAME => 1 });
        if (!$users->{errno} && $users->{TOTAL} > 0) {
          my $uid = $list->[0]->{uid};
          $user = $users->info($uid);
          $user->pi({ UID => $uid });        
        }
      }    

      if ($users->{TOTAL} < 1) {
        code_message(5, $number, 0);
        return 0;
      }
      else {
        cross_modules_call('_pre_payment', { 
          USER_INFO   => $user, 
          SKIP_MODULES=> 'Sqlcmd',
          QUITE       => 1, 
          SUM         => $amount,
        });       
       
        $payments->add(
          $user,
          {
            SUM            => $amount,
            DESCRIBE       => "$payment_system:$receipt",
            METHOD         => ($conf{PAYSYS_PAYMENTS_METHODS} && $PAYSYS_PAYMENTS_METHODS{$payment_system_id}) ? $payment_system_id : '2',
            EXT_ID         => "$payment_system_small:$payId",
            CHECK_EXT_ID   => "$payment_system_small:$payId",
            DATE           => $date_to_db,
            INNER_DESCRIBE => $payId,
          }

        );
        if ($payments->{errno}) {
          if ($payments->{errno} == 7) {
            my $list = $payments->list({ EXT_ID => "$payment_system:$payId", COLS_NAME => 1 });

            code_message(0, $number, $list->[0]->{id});

            $Paysys->add(
              {
                SYSTEM_ID      => $payment_system_id,
                DATETIME       => "$date_to_db",
                SUM            => "$amount",
                UID            => "$user->{UID}",
                IP             => '0.0.0.0',
                TRANSACTION_ID => "$payment_system_small:$payId",
                INFO           => "STATUS: 7 TrID: $receipt",
                PAYSYS_IP      => "$ENV{'REMOTE_ADDR'}",
                STATUS         => 7
              }
            );
            return 0;
          }
          else {
            code_message(1, $number, 0);
            mk_log($log_info, { PAYSYS_ID => $payment_system });
            return 0;
          }
        }
        else {

          cross_modules_call('_payments_maked', { 
            USER_INFO  => $user, 
            PAYMENT_ID => $payments->{PAYMENT_ID},
            SUM        => $amount,
            QUITE      => 1 
          });

          $Paysys->add(
            {
              SYSTEM_ID      => $payment_system_id,
              DATETIME       => "$date_to_db",
              SUM            => "$amount",
              UID            => "$user->{UID}",
              IP             => '0.0.0.0',
              TRANSACTION_ID => "$payment_system_small:$payId",
              INFO           => "STATUS: $code TrID: $receipt",
              PAYSYS_IP      => "$ENV{'REMOTE_ADDR'}",
              STATUS         => 2
            }
          );

          code_message(0, $number, $payments->{INSERT_ID});
          return 0;
        }
      }
    }

    # Cancel payment ----------------------- #
    elsif ($action eq 'cancel') {
      $payments->list({ EXT_ID => "$payment_system_small:$payId", COLS_NAME => 1 });

      if ($payments->{TOTAL} < 1) {
        code_message(7, $number, '');
        return 0;
      }
      else {
        my $list = $payments->list({ EXT_ID   => "$payment_system_small:$payId",
        	                           BILL_ID  => '_SHOW',
        	                           UID      => '_SHOW',
        	                           COLS_NAME=> 1 
        	                         });

        if ($payments->{errno}) {
          code_message(1, $number, '');
          return 0;
        }
        elsif ($payments->{TOTAL} < 1) {
          code_message(79, $number, '');
          return 0;
        }
        else {
          my $payment_id = $list->[0]->{id};
          my %user = (
            BILL_ID => $list->[0]->{bill_id},
            UID     => $list->[0]->{uid}
          );

          $payments->del(\%user, $payment_id);
          if (!$payments->{errno}) {
            code_message(0, $number, $payment_id);
            
            my $paysys_list = $Paysys->list({ TRANSACTION_ID => "$payment_system_small:$payId",
            	                                UID            => '_SHOW',
        	                                    COLS_NAME      => 1
            	                             });
            
            $Paysys->change({ 
              ID => $paysys_list->[0]->{uid},
              STATUS    => 3,
            });
          }
          else {
            code_message(1, $number, '');
          }
        }
      }
    }
    else {
      code_message(7);
    }
  }
  else {
    code_message(7, $number, 0);
    mk_log("Unknown username or password \n $log_info", { PAYSYS_ID => $payment_system });
    return 0;
  }

  return 1;
}

#**********************************************************
# log
#**********************************************************
sub platezhka_result {
  my ($content) = @_;

  print $content;

  if ($debug > 0) {
    mk_log($content, { PAYSYS_ID => 'Platezhka' });
  }
}

#**********************************************************
=head2 code_message($code, $account, $transaction_id)

=cut
#**********************************************************
sub code_message {
  my ($code, $account, $transaction_id) = @_;

  my $CHECK_FIELD = $conf{PAYSYS_PLATEZHKA_ACCOUNT_KEY} || 'UID';
  #my $personal_info;

  # check
  my %message = (
    0,   'ок',
    1,   'Временная ошибка. Повторите запрос позже',
    4,   'Неверный формат идентификатора абонента',
    5,   'Идентификатор абонента не найден (Ошиблись номером)',
    7,   'Прием платежа запрещен провайдером',
    8,   'Прием платежа запрещен по техническим причинам',
    50,  'Неверно выбраная компания',
    79,  'Счет абонента не активен',
    90,  'Проведение платежа не окончено',
    300, 'Другая ошибка провайдера'
  );

  my $list = $users->list({ 
     FIO          => '_SHOW',
     LOGIN        => '_SHOW',
     DEPOSIT      => '_SHOW',
     ADDRESS_FULL => '_SHOW',
     $CHECK_FIELD => $account, 
     COLS_NAME    => 1 
  });

  my $user = $list->[0];

  $user->{deposit} = sprintf("%.2f", $user->{deposit});

  platezhka_result(
    qq {<?xml version="1.0" encoding="UTF-8"?>
<commandResponse>
  <extTransactionID>$transaction_id</extTransactionID>
  <account>$account</account>
  <result>$code</result>
  <fields>
    <field1 name="FIO">$user->{fio}</field1>
    <field2 name="balance">$user->{deposit}</field2>
    <field3 name="address">$user->{address_full}</field2>
  </fields>    
  <comment>$message{$code}</comment>
</commandResponse>}
  );

  return 1;
}

1
