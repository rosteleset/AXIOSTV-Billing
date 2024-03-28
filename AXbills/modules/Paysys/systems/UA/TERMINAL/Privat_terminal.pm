#**********************************************************
=head1 NAME

  Privat bank termibnal interface

  version: 0.36

  $conf{PAYSYS_PRIVAT_BANK_SERVICE}
  Service describe

  $conf{PAYSYS_PRIVAT_BANK_COMPANY_ID}
  Company Number

  $conf{PAYSYS_PRIVAT_BANK_SERVICE_ID}
  Service ID


  $conf{PAYSYS_REDIRECT_UNKNOWN}=1;

=cut
#**********************************************************

#09.02.2016
our %PAYSYSTEM_CONF    = ('PAYSYS_PRIVAT_TERMINAL_SERVICE_CODE' => '101' ,
                          'PAYSYS_PRIVAT_TERMINAL_ACCOUNT_KEY'  => 'UID',
                          'PAYSYS_PRIVAT_BANK_SERVICE'          => '',
                          'PAYSYS_PRIVAT_BANK_COMPANY_ID'       => '',
                          'PAYSYS_PRIVAT_BANK_SERVICE_ID'       => '',
                          'PAYSYS_PRIVAT_TERMINAL_MFO'          => '',
                          'PAYSYS_PRIVAT_TERMINAL_OKPO'         => '',
                          'PAYSYS_PRIVAT_TERMINAL_ACCOUNT'      => '',
                          'PAYSYS_PRIVAT_TERMINAL_CODE'         => '',
                          'PAYSYS_PRIVAT_TERMINAL_NAME'         => '',);
our $PAYSYSTEM_IP      = '';
our $PAYSYSTEM_VERSION = 1.08;
our $PAYSYSTEM_NAME    = 'Privat_terminal';

our $VERSION = 0.36;
our $IPS     = '';

my $debug = $conf{PAYSYS_DEBUG} || $FORM{debug} || 1;

load_pmodule('Digest::MD5');
my $md5 = Digest::MD5->new();

if ($debug > 1) {
  print "Content-Type: text/plain\n\n";
}
else {
  print "Content-Type: text/xml\n\n";
}

if($debug>9) {
#  $FORM{__BUFFER} = qq{<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
#<Transfer xmlns="http://debt.privatbank.ua/Transfer" action="Check" interface="Debt">
#    <Data xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="Payment" cancel="false">
#        <PayerInfo billIdentifier="66111116"/>
#        <TotalSum>0.01</TotalSum>
#        <CreateTime>2014-02-26T10:24:29.813+02:00</CreateTime>
#        <ServiceGroup>
#            <Service sum="0.01" serviceCode="$service_code"/>
#        </ServiceGroup>
#    </Data>
#</Transfer>
#};

#  $FORM{__BUFFER} = qq{<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
#<Transfer xmlns="http://debt.privatbank.ua/Transfer" action="Pay" interface="Deb
#t">
#    <Data xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="Paymen
#t" id="511725272" cancel="false">
#        <PayerInfo billIdentifier="5"/>
#        <TotalSum>0.20</TotalSum>
#        <CreateTime>2014-06-12T17:37:11.506+03:00</CreateTime>
#        <ServiceGroup>
#            <Service sum="0.20" serviceCode="$service_code"/>
#        </ServiceGroup>
#    </Data>
#</Transfer>
#};

#$FORM{__BUFFER} = qq{<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
#<Transfer xmlns="http://debt.privatbank.ua/Transfer" action="Search" interface="Debt">
#    <Data xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="Payer">
#        <Unit name="bill_identifier" value="1"/>
#    </Data>
#</Transfer>
#};

#Upload
#  $FORM{__BUFFER} = qq{<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
#<Transfer xmlns="http://debt.privatbank.ua/Transfer" action="Upload" interface="Debt">
#    <Data xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="Entry" id="348990428">
#        <PaymentGroup>
#            <Payment id="511725445" cancel="false">
#                <PayerInfo billIdentifier="1"/>
#                <TotalSum>0.90</TotalSum>
#                <CreateTime>2014-09-02T15:15:02.186+03:00</CreateTime>
#                <ServiceGroup>
#                    <Service sum="0.90" serviceCode="$service_code"/>
#                </ServiceGroup>
#            </Payment>
#        </PaymentGroup>
#        <Sum>0.90</Sum>
#    </Data>
#</Transfer>
#  };

  $FORM{__BUFFER} = qq{<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Transfer xmlns="http://debt.privatbank.ua/Transfer" action="Upload" interface="Debt">
    <Data xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="Pack">
        <Unit xsi:type="Entry" id="793966736">
            <PaymentGroup>
                <Payment id="1701366900" cancel="false">
                    <CompanyInfo>
                        <CheckReference>1655</CheckReference>
                    </CompanyInfo>
                    <PayerInfo billIdentifier="1"/>
                    <TotalSum>7.00</TotalSum>
                    <CreateTime>2017-10-12T16:49:56.700+03:00</CreateTime>
                    <ServiceGroup>
                        <Service sum="1.00" serviceCode="6110"/>
                    </ServiceGroup>
                </Payment>
            </PaymentGroup>
            <Sum>7.00</Sum>
            <NumberOfPayments>1</NumberOfPayments>
        </Unit>
    </Data>
</Transfer>
  };
}

my $input_date = $FORM{__BUFFER};
my $service_code = $conf{PAYSYS_PRIVAT_TERMINAL_SERVICE_CODE} || '101';

# Приложения. Телекоммуникационные предприятия и интернет-провайдеры
if($input_date =~ /<Transfer /) {
  privat_terminal2();
}
elsif ($FORM{action}) {
  privat_payments();
}
else {
  privat_terminal();
}

#**********************************************************
=head2 payments_payments()

=cut
#**********************************************************
sub privat_payments {
  my ($attr) = @_;

  my $action            = $FORM{action};
  my $payment_system    = 'PT';
  my $payment_system_id = 65;
  my $CHECK_FIELD       = $conf{PAYSYS_PRIVAT_TERMINAL_ACCOUNT_KEY} || 'UID';

  my ($y, $m, $d) = split(/\-/, $DATE, 3);

  # DD.MM.YYYY HH24:MI:SS
  my $EURO_DATE = "$d.$m.$y";
  my $PERIOD    = "$y$m";

  $FORM{PAY_ACCOUNT} = '' if (!defined($FORM{PAY_ACCOUNT}));
  my $describe = '';
  $md5->reset;
##Version 2.20
  #if ($FORM{SERVICE_ID}) {
  #  $md5->add( $FORM{ACT}.'_'.$FORM{PAY_ACCOUNT}.'_'.$FORM{SERVICE_ID}.'_'.$FORM{PAY_ID}.'_'.$conf{PAYSYS_PRIVAT_TERMINAL_KEY} );
  #}
##Version 2.10
  #else {
  #  $md5->add( $FORM{ACT}.'_'.$FORM{PAY_ACCOUNT}.'_'.$FORM{PAY_ID}.'_'.$conf{PAYSYS_PRIVAT_TERMINAL_KEY} );
  #}
  #my $hash    = uc($md5->hexdigest());
  #
##Wrong hash
  #if ($hash ne uc($FORM{SIGN})) {
  #  if ($debug > 1) {
  #    print "Local: $hash Remote: ". uc($FORM{SIGN}). "\n";
  #   }
  #
  #  $status = -101;
  # }

  #Check user account
  #https://<host>/<path>?action=bill_search&bill_identifier=12123122121
  if ($action eq 'bill_search') {
    my $list = $users->list({ $CHECK_FIELD => $FORM{bill_identifier},
                              COLS_NAME    => 1
                            });

    if ($users->{errno}) {
      $status = 99;
      privat_terminal_result(
        qq{<ResponseDebt>
<errorResponse>
<code>$status</code>
<message>DB Error</message>
</errorResponse>
</ResponseDebt>}
      );
      return 0;
    }
    elsif ($users->{TOTAL} < 1) {
      $status = 2;

      privat_terminal_result(
        qq{<ResponseDebt>
<errorResponse>
<code>$status</code>
<message>Абонент не найден</message>
</errorResponse>
</ResponseDebt>}
      );
      return 0;
    }
    else {
      my $min_amount = 1;
      my $uid        = $list->[0]->{uid};
      $users->info($uid);
      my $deposit    = sprintf("%.2f", $users->{DEPOSIT});
      $users->pi({ UID => $uid });

      my $amount_to_pay = sprintf("%.2f", ($deposit < 0) ? abs($deposit) : 0 - $deposit);

      #if (in_array('Docs', \@MODULES)) {
      #  $FORM{ALL_SERVICES} = 1;
      #  load_module('Docs', $html);
      #  $amount_to_pay = docs_invoice({ TOTAL_ONLY => 1 });
      #}

      account_gid_split($users->{GID});

      privat_terminal_result(
        qq {<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<ResponseDebt>
<debtPayPack phone="$users->{PHONE}" fio="$users->{FIO}" bill_period="$PERIOD"
bill_identifier="$FORM{bill_identifier}" address="$users->{ADDRESS_STREET}, $users->{ADDRESS_BUILD}, $users->{ADDRESS_FLAT}">
<service>
<ks company_code="$conf{PAYSYS_PRIVAT_BANK_COMPANY_ID}" service_code="$service_code" service="$conf{PAYSYS_PRIVAT_BANK_SERVICE}"/>
<debt amount_to_pay="$amount_to_pay"/>
<payer ls="$FORM{bill_identifier}"/>
</service>
<message>Теперь оплату услуг можно производить в любой кассе города!</message>
</debtPayPack>
</ResponseDebt>
}
      );
      return 0;
    }
  }
  # Add payments
  # paysys_check.cgi?action=bill_input&bill_identifier=123123123122&sum=399.99&pkey=991310011&date=2009-10-13T09:00:00
  elsif ($action eq 'bill_input') {
    my $user;
    my $payments_id = 0;

    if (!$FORM{sum}) {
      if ($FORM{service} =~ /{sum=([0-9\.]+);service_code=(\d{0,6})/) {
        $FORM{sum}          = $1;
        $FORM{service_code} = $2;
      }
      elsif ($FORM{service} =~ /{sum=([0-9\.]+)/) {
        $FORM{sum} = $1;
      }
    }

    if ($CHECK_FIELD eq 'UID') {
      $user = $users->info($FORM{bill_identifier});
    }
    else {
      my $list = $users->list({ LOGIN        => '_SHOW',
                                FIO          => '_SHOW',
                                DEPOSIT      => '_SHOW',
                                $CHECK_FIELD => $FORM{bill_identifier},
                                COLS_NAME    => 1
                              });

      if (!$users->{errno} && $users->{TOTAL} > 0) {
        my $uid = $list->[0]->{uid};
        $user = $users->info($uid);
      }
    }

    if ($users->{errno}) {
      $status = 99;
      privat_terminal_result(
        qq{<ResponseDebt>
<errorResponse>
<code>$status</code>
<message>DB Error</message>
</errorResponse>
</ResponseDebt>}
      );
      return 0;
    }
    elsif ($users->{TOTAL} < 1) {
      $status = 2;
      privat_terminal_result(
        qq{<ResponseDebt>
<errorResponse>
<code>$status</code>
<message>Не найден  абонент</message>
</errorResponse>
</ResponseDebt>}
      );
      return 0;
    }
    else {
      cross_modules_call('_pre_payment', { USER_INFO   => $user,
                                           SKIP_MODULES=> 'Sqlcmd',
                                           QUITE       => 1,
                                           #SUM         => $FORM{sum},
                                          });

      #Add payments
      $payments->add(
        $user,
        {
          SUM          => $FORM{sum},
          DESCRIBE     => "$payment_system",
          METHOD       => ($conf{PAYSYS_PAYMENTS_METHODS} && $PAYSYS_PAYMENTS_METHODS{$payment_system_id}) ? $payment_system_id : '2',
            EXT_ID       => "$payment_system:$FORM{pkey}",
          CHECK_EXT_ID => "$payment_system:$FORM{pkey}"
        }
      );

      #Exists
      # Dublicate
      if ($payments->{errno} && $payments->{errno} == 7) {
        my $list = $Paysys->list({ INFO => "*$FORM{PAY_ID}*" });
        $payments_id = $payments->{ID};
        if ($Paysys->{TOTAL} == 0) {
          $Paysys->add(
            {
              SYSTEM_ID      => $payment_system_id,
              DATETIME       => "$DATE $TIME",
              SUM            => "$FORM{sum}",
              UID            => "$user->{UID}",
              IP             => '0.0.0.0',
              TRANSACTION_ID => "$payment_system:$FORM{pkey}",
              INFO           => "pkey: $FORM{pkey} DATE: $FORM{date}",
              PAYSYS_IP      => "$ENV{'REMOTE_ADDR'}",
              STATUS         => 7,
            }
          );

          if (!$Paysys->{errno}) {
            privat_terminal_result(
              qq{<ResponseDebt>
<errorResponse>
<code>$status</code>
<message>Оши</message>
</errorResponse>
</ResponseDebt>}
            );

            cross_modules_call('_payments_maked', {
               USER_INFO  => $user,
               PAYMENT_ID => $payments->{PAYMENT_ID},
               SUM        => $FORM{sum},
               QUITE      => 1,
               SILENT     => 0
            });

            return 0;
          }
        }
        else {
          $status   = 99;
          $describe = 'Платёж уже зарегистрирован';
        }
      }

      #Payments error
      elsif ($payments->{errno}) {
        $status   = -90;
        $describe = 'Error: ' . $payments->{errstr};
      }
      else {
        $status = 0;
        $Paysys->add(
          {
            SYSTEM_ID      => $payment_system_id,
            DATETIME       => "$DATE $TIME",
            SUM            => "$FORM{sum}",
            UID            => "$user->{UID}",
            IP             => '0.0.0.0',
            TRANSACTION_ID => "$payment_system:$FORM{pkey}",
            INFO           => "pkey: $FORM{pkey} DATE: $FORM{date}",
            ,
            PAYSYS_IP      => "$ENV{'REMOTE_ADDR'}",
            STATUS         => 2
          }
        );

        $payments_id = ($payments->{INSERT_ID}) ? $payments->{INSERT_ID} : 0;

        if (!$Paysys->{errno}) {
          privat_terminal_result(
            qq {<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<ResponseExtInputPay>
<extInputPay>
<inner_ref>$payments_id</inner_ref>
</extInputPay>
</ResponseExtInputPay>
}
          );

          #Send mail
          if ($conf{PAYSYS_EMAIL_NOTICE}) {
            my $message = "\n" . "================================" .
        "System: $payment_system\n" .
        "================================" .
        "DATE: $DATE $TIME\n" .
        "FIO: $user->{FIO}\n" . 
        "LOGIN: $user->{LOGIN}n" . 
        "SUM: $FORM{sum}" . "\n\n";

            sendmail("$conf{ADMIN_MAIL}", "$conf{ADMIN_MAIL}", "$payment_system ADD", "$message", "$conf{MAIL_CHARSET}", "2 (High)");
          }

          cross_modules_call('_payments_maked', {
               USER_INFO  => $user,
               PAYMENT_ID => $payments->{PAYMENT_ID},
               SUM        => $FORM{sum},
               QUITE      => 1,
               SILENT     => 0
          });

          return 0;
        }

        #Transactions registration error
        else {
          if ($Paysys->{errno} && $Paysys->{errno} == 7) {
            $status      = 99;
            $describe    = 'Платёж уже зарегистрирован';
            $payments_id = $payments->{ID};
          }

          #Payments error
          elsif ($Paysys->{errno}) {
            $status = -90;
          }
        }
      }
    }
  }

  privat_terminal_result(
    qq{<ResponseDebt>
<errorResponse>
<code>$status</code>
<message>$describe</message>
</errorResponse>
</ResponseDebt>}
  );

  return 1;
}

#**********************************************************
#
#**********************************************************
sub privat_terminal {
  my ($attr) = @_;

  my $act               = $FORM{ACT};
  my $payment_system    = 'PT';
  my $payment_system_id = 65;
  my $CHECK_FIELD       = $conf{PAYSYS_PRIVAT_TERMINAL_ACCOUNT_KEY} || 'UID';

  $DATE =~ /(\d+)\-(\d+)\-(\d+)/;

  # DD.MM.YYYY HH24:MI:SS
  my $EURO_DATE = "$3.$2.$1";

  $FORM{PAY_ACCOUNT} = '' if (!defined($FORM{PAY_ACCOUNT}));

  $md5->reset;

  #Version 2.20
  if ($FORM{SERVICE_ID}) {
    $md5->add($FORM{ACT} . '_' . $FORM{PAY_ACCOUNT} . '_' . $FORM{SERVICE_ID} . '_' . $FORM{PAY_ID} . '_' . $conf{PAYSYS_PRIVAT_TERMINAL_KEY});
  }

  #Version 2.10
  else {
    $md5->add($FORM{ACT} . '_' . $FORM{PAY_ACCOUNT} . '_' . $FORM{PAY_ID} . '_' . $conf{PAYSYS_PRIVAT_TERMINAL_KEY});
  }
  my $hash = uc($md5->hexdigest());

  #Wrong hash
  if ($hash ne uc($FORM{SIGN})) {
    if ($debug > 1) {
      print "Local: $hash Remote: " . uc($FORM{SIGN}) . "\n";
    }
    $status = -101;
  }
  #Check user account
  #?ACT=1&PAY_ACCOUNT=123434&PAY_ID=XXXXXXXX-XXXXXXXX-XXXX-XXXXXXXXXXXX&TRADE_POINT=term1232&SIGN=F454FR43DE32JHSAGDSSFS
  elsif ($act == 1) {
    my $list = $users->list({ LOGIN        => '_SHOW',
                              FIO          => '_SHOW',
                              DEPOSIT      => '_SHOW',
                              $CHECK_FIELD => $FORM{PAY_ACCOUNT},
                              COLS_NAME => 1 });

    if ($users->{errno}) {
      $status = -101;
    }
    elsif ($users->{TOTAL} < 1) {
      $status = -40;
    }
    else {
      $list->[0]->{fio} =~ s/\'/_/g;
      my $min_amount = 1;                               #$conf{PAYSYS_24_NON_STOP_MIN_AMOUNT} || 0.01;
      my $balance    = sprintf("%.2f", $list->[0]->{deposit});

      privat_terminal_result(
        qq {<?xml version="1.0" encoding="UTF-8" ?>
<pay-response>
<balance>$balance</balance>
<name>$list->[0]->{login}  $list->[0]->{fio}</name>
<account>$FORM{PAY_ACCOUNT}</account>
<service_id>$FORM{SERVICE_ID}</service_id>
<abonplata>0</abonplata>
<min_amount>$min_amount</min_amount>
<max_amount>20000</max_amount>
<status_code>21</status_code>
<time_stamp>$EURO_DATE $TIME</time_stamp>
</pay-response>
}
      );
      return 0;
    }
  }

  #Check payments
  # ?ACT=7&PAY_ID=XXXXXXXX-XXXX-XXXX-XXXXXXXXXXXXXXXX&SIGN=F454FR43DE32JHSAGDSSFS
  elsif ($act == 7) {
    my $list = $payments->list({ ID        => "$FORM{RECEIPT_NUM}",
                                 SUM       => '_SHOW',
                                 DATE      => '_SHOW',
                                 EXT_ID    => '_SHOW',
                                 COLS_NAME => 1 });
    if ($payments->{TOTAL} > 0) {
      my $sum = $list->[0]->{sum};
      $list->[0]->{date} =~ /(\d+)\-(\d+)\-(\d+) (\d+\:\d+\:\d+)/;
      my $operation_date = "$3.$2.$1 $4";
      $FORM{RECEIPT_NUM} = $list->[0]->{id};

      print << "[END]";
<?xml version="1.0" encoding="UTF-8" ?>
<pay-response>
<status_code>11</status_code>
<time_stamp>$EURO_DATE $TIME</time_stamp>
<transaction>
  <pay_id>$FORM{PAY_ID}</pay_id>
  <RECEIPT_NUM>$FORM{RECEIPT_NUM}</RECEIPT_NUM>
  <amount>$sum</amount>
  <service_id>$FORM{SERVICE_ID}</service_id>
  <status>111</status>
<time_stamp>$operation_date</time_stamp>
</transaction>
</pay-response>
[END]
      return 0;
    }
    else {
      $status = -10;
    }
  }

  #paysys_check.cgi?ACT=4&PAY_ACCOUNT=test&PAY_AMOUNT=10.20&RECEIPT_NUM=123568&PAY_ID=11121111-XXXX-XXXX-XXXXXXXXXXXXXXXX&TRADE_POINT=term1232&SIGN=F454FR43DE32JHSAGDSSFS
  # Add payments
  elsif ($act == 4) {
    my $user;
    my $payments_id = 0;

    if ($CHECK_FIELD eq 'UID') {
      $user = $users->info($FORM{PAY_ACCOUNT});
    }
    else {
      my $list = $users->list({ $CHECK_FIELD => $FORM{PAY_ACCOUNT}, 
                                FIO          => '_SHOW',
                                COLS_NAME    => 1  });
      if (!$users->{errno} && $users->{TOTAL} > 0) {
        my $uid = $list->[0]->{uid};

        $user = $users->info($uid);
      }
    }

    if ($users->{errno}) {
      $status = -40;
    }
    elsif ($users->{TOTAL} < 1) {
      $status = -100;
    }
    else {
      cross_modules_call('_pre_payment', { USER_INFO   => $user,
                                           SKIP_MODULES=> 'Sqlcmd',
                                           QUITE       => 1,
                                           #SUM         => $FORM{PAY_AMOUNT},
                                          });

      #Add payments
      $payments->add(
        $user,
        {
          SUM          => $FORM{PAY_AMOUNT},
          DESCRIBE     => "$payment_system",
          METHOD       => ($conf{PAYSYS_PAYMENTS_METHODS} && $PAYSYS_PAYMENTS_METHODS{$payment_system_id}) ? $payment_system_id : '2',
          EXT_ID       => "$payment_system:$FORM{RECEIPT_NUM}",
          CHECK_EXT_ID => "$payment_system:$FORM{RECEIPT_NUM}"
        }
      );

      #Exists
      # Dublicate
      if ($payments->{errno} && $payments->{errno} == 7) {
        my $list = $Paysys->list({ INFO => "*$FORM{PAY_ID}*" });
        $payments_id = $payments->{ID};
        if ($Paysys->{TOTAL} == 0) {
          $Paysys->add(
            {
              SYSTEM_ID      => $payment_system_id,
              DATETIME       => "$DATE $TIME",
              SUM            => "$FORM{PAY_AMOUNT}",
              UID            => "$user->{UID}",
              IP             => '0.0.0.0',
              TRANSACTION_ID => "$payment_system:$FORM{RECEIPT_NUM}",
              INFO           => "STATUS: $status TRADE_POINT: $FORM{TRADE_POINT} PAY_ID: $FORM{PAY_ID} RECEIPT_NUM: $FORM{RECEIPT_NUM}",
              PAYSYS_IP      => "$ENV{'REMOTE_ADDR'}",
              STATUS         => 2
            }
          );

          if (!$Paysys->{errno}) {
            privat_terminal_result(
              qq {<?xml version="1.0" encoding="UTF-8" ?>
<pay-response>
<pay_id>$payments_id</pay_id >
<service_id>$FORM{SERVICE_ID}</service_id>
<amount>$FORM{PAY_AMOUNT}</amount>
<status_code>22</status_code>
<time_stamp>$EURO_DATE $TIME</time_stamp>
</pay-response>
}
            );

            cross_modules_call('_payments_maked', {
               USER_INFO  => $user,
               PAYMENT_ID => $payments->{PAYMENT_ID},
               SUM        => $FORM{PAY_AMOUNT},
               QUITE      => 1 });

            return 0;
          }
        }
        else {
          $status = -100;
        }
      }

      #Payments error
      elsif ($payments->{errno}) {
        $status = -90;
      }
      else {
        $status = 0;
        $Paysys->add(
          {
            SYSTEM_ID      => $payment_system_id,
            DATETIME       => "$DATE $TIME",
            SUM            => "$FORM{PAY_AMOUNT}",
            UID            => "$user->{UID}",
            IP             => '0.0.0.0',
            TRANSACTION_ID => "$payment_system:$FORM{RECEIPT_NUM}",
            INFO           => "STATUS: $status TRADE_POINT: $FORM{TRADE_POINT} PAY_ID: $FORM{PAY_ID} RECEIPT_NUM: $FORM{RECEIPT_NUM}",
            PAYSYS_IP      => "$ENV{'REMOTE_ADDR'}",
            STATUS         => 2
          }
        );

        $payments_id = ($payments->{INSERT_ID}) ? $payments->{INSERT_ID} : 0;

        if (!$Paysys->{errno}) {
          privat_terminal_result(
            qq {<?xml version="1.0" encoding="UTF-8" ?>
<pay-response>
<pay_id>$payments_id</pay_id >
<service_id>$FORM{SERVICE_ID}</service_id>
<amount>$FORM{PAY_AMOUNT}</amount>
<status_code>22</status_code>
<time_stamp>$EURO_DATE $TIME</time_stamp>
</pay-response>
}
          );

          #Send mail
          if ($conf{PAYSYS_EMAIL_NOTICE}) {
            my $message = "\n" . "================================" .
        "System: $payment_system\n" .
        "================================" .
        "DATE: $DATE $TIME\n" .
        "FIO: $user->{FIO}\n" . 
        "LOGIN: $user->{LOGIN}\n" . 
        "SUM: $FORM{PAY_AMOUNT}" . "\n\n";

            sendmail("$conf{ADMIN_MAIL}", "$conf{ADMIN_MAIL}", "$payment_system ADD", "$message", "$conf{MAIL_CHARSET}", "2 (High)");
          }

          cross_modules_call('_payments_maked', {
              USER_INFO  => $user,
              PAYMENT_ID => $payments->{PAYMENT_ID},
              SUM        => $FORM{PAY_AMOUNT},
              QUITE      => 1 });

          return 0;
        }

        #Transactions registration error
        else {
          if ($Paysys->{errno} && $Paysys->{errno} == 7) {
            $status      = -100;
            $payments_id = $payments->{ID};
          }

          #Payments error
          elsif ($Paysys->{errno}) {
            $status = -90;
          }
        }
      }
    }
  }

  privat_terminal_result(
    qq {<?xml version="1.0" encoding="UTF-8" ?>
<pay-response>
<error>$status</error>
<time_stamp>$EURO_DATE $TIME</time_stamp>
</pay-response> }
  );

  return 0;
}

#**********************************************************
#
#**********************************************************
sub privat_terminal_result {
  my ($content, $result) = @_;

  print $content;

  if ($debug > 0) {
    $content = "QUERY: $ENV{QUERY_STRING}\n\n" . $content;

    mk_log($content, { PAYSYS_ID => 'privat_terminal' });
  }

}


#**********************************************************
#
#
#$conf{PAYSYS_PRIVAT_TERMINAL_MFO}
#$conf{PAYSYS_PRIVAT_TERMINAL_OKPO}
#$conf{PAYSYS_PRIVAT_TERMINAL_ACCOUNT}
#$conf{PAYSYS_PRIVAT_TERMINAL_CODE}
#$conf{PAYSYS_PRIVAT_TERMINAL_NAME}
#$conf{PAYSYS_PRIVAT_TERMINAL_ACCOUNT_KEY}
#**********************************************************
sub privat_terminal2 {
  my ($attr) = @_;

  load_pmodule('XML::Simple');

  my $act               = $FORM{ACT};
  my $payment_system    = 'PT';
  my $payment_system_id = 65;
  my $CHECK_FIELD       = $conf{PAYSYS_PRIVAT_TERMINAL_ACCOUNT_KEY} || 'UID';

  my $_xml = eval { XML::Simple::XMLin("$FORM{__BUFFER}", forcearray => 1) };

  if ($@) {
    mk_log("-- Content:\n" . $FORM{__BUFFER} . "\n-- XML Error:\n" . $@ . "\n--\n", { PAYSYS_ID => 'privat_terminal2' });
    return 0;
  }
  else {
    if ($debug > 0) {
      mk_log($FORM{__BUFFER}, { PAYSYS_ID => 'privat_terminal2' });
    }
  }

  my %request_hash = %$_xml;

  my $request_type = $request_hash{action};

  if ($debug > 2) {
    print "Request type: $request_type\n";
    while(my ( $k, $v ) = each %request_hash ) {
      print "$k, $v <br>\n";
    }
  }

  $DATE =~ /(\d+)\-(\d+)\-(\d+)/;
  # DD.MM.YYYY HH24:MI:SS
  my $EURO_DATE = "$3.$2.$1";

  $FORM{PAY_ACCOUNT} = '' if (!defined($FORM{PAY_ACCOUNT}));

  if ($request_type eq 'Presearch') {
    my $user_account = $request_hash{Data}->[0]->{Unit}->{ls}->{value};

    my $list = $users->list({ LOGIN        => '_SHOW',
                              FIO          => '_SHOW',
                              DEPOSIT      => '_SHOW',
                              GID          => '_SHOW',
                              DOMAIN_ID    => '_SHOW',
                              $CHECK_FIELD => $user_account,
                              COLS_NAME    => 1
                            });

    if ($users->{errno}) {
      privat_terminal_result2('error', '', { error_code => 99 });
    }
    elsif ($users->{TOTAL} < 1 && ! $conf{PAYSYS_REDIRECT_UNKNOWN}) {
      privat_terminal_result2('error', '', { error_code => 2 });
    }
    else {
      if ($list->[0]->{gid}) {
        $users->group_info($list->[0]->{gid});
        if ($users->{DISABLE_PAYSYS}) {
          privat_terminal_result2('error', '', { error_code => 5 });
          return 0;
        }
        account_gid_split($list->[0]->{gid});
      }
      elsif($list->[0]->{domain_id}) {
        account_gid_split($list->[0]->{domain_id});
      }


      $list->[0]->{fio} =~ s/\'/_/g;
      my $min_amount = 1;
      my $balance    = sprintf("%.2f", $list->[0]->{deposit});
      my $context1    = '';
      my $context2    = '';
      foreach my $line ( @$list ) {
        $context1    .= "<Element>$line->{fio}</Element>";
        $context2    .= "<Element>$line->{uid}</Element>";
      }

      privat_terminal_result2('ok',
        qq {<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
            <Transfer xmlns="http://debt.privatbank.ua/Transfer" interface="Debt" action="Presearch">
            <Data xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="PayersTable">
              <Headers>
                <Header name="fio"/>
                <Header name="ls"/>
              </Headers>
              <Columns>
                <Column>
                  $context1
                </Column>
                <Column>
                  $context2
                </Column>
              </Columns>
            </Data>
            </Transfer>
        },
        { action => $request_type }
      );
      return 0;
    }
  }
  # User search
  elsif ($request_type eq 'Search') {
    my $user_account = $request_hash{Data}->[0]->{presearchId} || $request_hash{Data}->[0]->{Unit}->{bill_identifier}->{value} || $request_hash{Data}->[0]->{Unit}->{billIdentifier}->{value} ;

    $users->{debug}=1 if ($debug > 7);
    my $list = $users->list({ LOGIN        => '_SHOW',
                              FIO          => '_SHOW',
                              DEPOSIT      => '_SHOW',
                              PHONE        => '_SHOW',
                              ADDRESS_FULL => '_SHOW',
                              GID          => '_SHOW',
                              DOMAIN_ID    => '_SHOW',
                              $CHECK_FIELD => $user_account || '---',
                              COLS_NAME    => 1
                            });

    if ($users->{errno}) {
      privat_terminal_result2('error', '', { error_code => 99 });
    }
    elsif ($users->{TOTAL} < 1 && ! $conf{PAYSYS_REDIRECT_UNKNOWN}) {
      privat_terminal_result2('error', '', { error_code => 2 });
    }
    else {
      $list->[0]->{fio} =~ s/\'/_/g;
      my $min_amount = 1;
      my $balance    = sprintf("%.2f", $list->[0]->{deposit});
      my $context1   = '';
      my $context2   = '';

      if($list->[0]->{domain_id}) {
        account_gid_split($list->[0]->{domain_id});
      }

      if($list->[0]->{gid}) {
        account_gid_split($list->[0]->{gid});
      }

      if ($users->{TOTAL}==0 && $conf{PAYSYS_REDIRECT_UNKNOWN}) {
        $list->[0]->{fio}='';
        $list->[0]->{phone}='';
        $list->[0]->{address_full}='';
        $user_account;
      }

      my $DebtPack  = $DATE;
      $DebtPack =~ s/(\d{4})-(\d{2})-(\d{2})/$1$2/;
      my $amount_to_pay = sprintf("%.2f", ($balance < 0) ? abs($balance) : 0 - $balance);
      use Encode;
      my $message_my = decode('utf8',"Данные о задолженности можно получить в Кассе!");
      my $user_fio_my = decode('utf8',$list->[0]->{fio});
      my $user_phone_my = decode('utf8',$list->[0]->{phone});
      my $user_address_my = decode('utf8',$list->[0]->{address_full});
      my $company_name_my = decode('utf8',$conf{PAYSYS_PRIVAT_TERMINAL_NAME});

      privat_terminal_result2('ok',
        qq {<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
            <Transfer xmlns="http://debt.privatbank.ua/Transfer" interface="Debt" action="Search">
            <Data xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="DebtPack" billPeriod="$DebtPack">
              <Message>$message_my</Message>
              <PayerInfo billIdentifier="$user_account" ls="$user_account">
                <Fio>$user_fio_my</Fio>
                <Phone>$user_phone_my</Phone>
                <Address>$user_address_my</Address>
              </PayerInfo>
              <ServiceGroup>
                <DebtService serviceCode="$service_code" >
                  <Message>Internet</Message>
                  <CompanyInfo mfo="$conf{PAYSYS_PRIVAT_TERMINAL_MFO}" okpo="$conf{PAYSYS_PRIVAT_TERMINAL_OKPO}" account="$conf{PAYSYS_PRIVAT_TERMINAL_ACCOUNT}" >
                    <CompanyCode>$conf{PAYSYS_PRIVAT_TERMINAL_CODE}</CompanyCode>
                    <CompanyName>$company_name_my</CompanyName>
                  </CompanyInfo>
                  <PayerInfo billIdentifier="$user_account" ls="$user_account"></PayerInfo>
                  <DebtInfo amountToPay="$amount_to_pay" debt="$amount_to_pay"></DebtInfo>
                </DebtService>
              </ServiceGroup>
            </Data>
            </Transfer>},
        { action => $request_type }
      );
      return 0;
    }
  }
  #Check payments
  #
  elsif ($request_type eq 'Check') {
    if ($debug > 7) {
      $payments->{debug}=1 ;
      $users->{debug}=1;
    }

     # <Data xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="Payment" number="0.0.345032104.1" id="740150719">
     # if "id" exist in attribute Data
#    my ($id, @test) = keys %{$request_hash{Data}};
#    my $user_account = $request_hash{Data}->{$id}->{PayerInfo}->[0]->{billIdentifier};
#    my $sum      = $request_hash{Data}->{$id}->{TotalSum}->[0];
#    my $datetime = $request_hash{Data}->{$id}->{CreateTime}->[0];


    my $user_account = $request_hash{Data}->[0]->{PayerInfo}->[0]->{billIdentifier};
    my $sum      = $request_hash{Data}->[0]->{TotalSum}->[0];
    my $datetime = $request_hash{Data}->[0]->{CreateTime}->[0];
    $datetime    =~ /(\d+)\-(\d+)\-(\d+) (\d+\:\d+\:\d+)/;
    my $operation_date = "$3.$2.$1 $4";

    my $list = $users->list({ $CHECK_FIELD => $user_account || '---',
                              DOMAIN_ID    => '_SHOW',
                              COLS_NAME    => 1
                            });

    if ($users->{errno}) {
      privat_terminal_result2('error', '', { error_code => 99,
                                             action     => $request_type });
      return 0;
    }
    elsif ($users->{TOTAL}<1) {
      if ($conf{PAYSYS_REDIRECT_UNKNOWN}) {
        privat_terminal_result2('ok',
        qq{<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Transfer xmlns="http://debt.privatbank.ua/Transfer" interface="Debt" action="Check">
  <Data xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="Gateway" reference="$user_account" />
</Transfer>},
        { action => $request_type });
      }
      else {
        privat_terminal_result2('error', '', { error_code => 2,
                                               action     => $request_type });

      }
      return 0;
    }

    my $uid            = $list->[0]->{uid};
    $FORM{RECEIPT_NUM} = $uid;

    privat_terminal_result2('ok', qq{<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Transfer xmlns="http://debt.privatbank.ua/Transfer" interface="Debt" action="Check">
  <Data xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="Gateway" reference="$FORM{RECEIPT_NUM}" />
</Transfer>},
        { action => $request_type }
    );

    return 0;
  }
  #
  # Add payments
  elsif ($request_type eq 'Pay') {
    my $user;
    my $payments_id = 0;
    my ($transaction)= keys %{ $request_hash{Data} };
    my $ext_id       = $transaction;
    my $user_account = $request_hash{Data}->{$transaction}->{PayerInfo}->[0]->{billIdentifier};
    my $amount       = $request_hash{Data}->{$transaction}->{TotalSum}->[0];

    if ($debug > 9) {
      foreach my $k (keys %{ $request_hash{Data} } ) {
        my $v = $request_hash{Data}->{$k};
        print "!! $k / $v\n";
      }
      print "Ext_id: $ext_id\n".
            "User_account: $user_account\n".
            "CHECK_FIELD: $CHECK_FIELD\n".
            "Amount: $amount\n";
    }

    $users->{debug}=1 if ($debug> 6);
    if ($CHECK_FIELD eq 'UID') {
      $user = $users->info($user_account);
    }
    else {
      my $list = $users->list({ $CHECK_FIELD => $user_account || '---',
                                FIO         => '_SHOW',
                                COLS_NAME    => 1  });
      if (!$users->{errno} && $users->{TOTAL} > 0) {
        my $uid = $list->[0]->{uid};
        my $fio = $list->[0]->{fio};
        $user = $users->info($uid);
        $user->{FIO} = $fio;
      }
    }

    if ($user->{errno}) {
      if ($user->{errno} == 2) {
        if ($conf{PAYSYS_REDIRECT_UNKNOWN}) {
          $payments->{PAYMENT_ID}=$user_account;
          privat_terminal_result2('ok',
            qq {<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
              <Transfer xmlns="http://debt.privatbank.ua/Transfer" interface="Debt" action="Pay">
                <Data xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="Gateway" reference="$payments->{PAYMENT_ID}">
                </Data>
              </Transfer>
            },
            { action => $request_type } );

          _external($conf{PAYSYS_REDIRECT_UNKNOWN}, { LOGIN    => $user_account,
                                                      SUM      => $amount,
                                                      DATETIME => "$DATE $TIME",
                                                      EXT_ID   => $ext_id,
                                                      QUITE    => 1
                                                     });
        }
        else {
          $status = 2;
        }
      }
      else {
         $status = 99;
      }
#
    }
    else {
      cross_modules_call('_pre_payment', { USER_INFO   => $user,
                                           SKIP_MODULES=> 'Sqlcmd',
                                           QUITE       => 1,
                                           SUM         => $amount,
                                          });

      #Add payments
      if ($debug> 6) {
        $payments->{debug}=1;
        $Paysys->{debug}=1;
      };

      $payments->add(
        $user,
        {
          SUM          => $amount,
          DESCRIBE     => "$payment_system",
          METHOD       => ($conf{PAYSYS_PAYMENTS_METHODS} && $PAYSYS_PAYMENTS_METHODS{$payment_system_id}) ? $payment_system_id : '2',
          EXT_ID       => "$payment_system:$ext_id",
          CHECK_EXT_ID => "$payment_system:$ext_id"
        }
      );

      #Exists
      # Dublicate
      if ($payments->{errno} && $payments->{errno} == 7) {
        my $list = $Paysys->list({ TRANSACTION_ID => "$payment_system:$ext_id" });
        $payments_id = $payments->{ID};
        if ($Paysys->{TOTAL} == 0) {
          $Paysys->add(
            {
              SYSTEM_ID      => $payment_system_id,
              DATETIME       => "$DATE $TIME",
              SUM            => "$amount",
              UID            => "$user->{UID}",
              IP             => '0.0.0.0',
              TRANSACTION_ID => "$payment_system:$ext_id",
              INFO           => "STATUS: $status ",
              PAYSYS_IP      => "$ENV{'REMOTE_ADDR'}",
              STATUS         => 2
            }
          );

          if (! $Paysys->{errno}) {
            cross_modules_call('_payments_maked', {
               USER_INFO  => $user,
               PAYMENT_ID => $payments->{PAYMENT_ID},
               SUM        => $amount,
               QUITE      => 1 });
          }

          $status = 7;
        }
        else {
          $status = 7;
        }
      }

      #Payments error
      elsif ($payments->{errno}) {
        $status = 99;
      }
      else {
        $status = 0;
        $Paysys->add(
          {
            SYSTEM_ID      => $payment_system_id,
            DATETIME       => "$DATE $TIME",
            SUM            => $amount,
            UID            => "$user->{UID}",
            IP             => '0.0.0.0',
            TRANSACTION_ID => "$payment_system:$ext_id",
            INFO           => "STATUS: $status",
            PAYSYS_IP      => "$ENV{'REMOTE_ADDR'}",
            STATUS         => 2
          }
        );

        $payments_id = ($payments->{INSERT_ID}) ? $payments->{INSERT_ID} : 0;

        if (!$Paysys->{errno}) {
          cross_modules_call('_payments_maked', {
              USER_INFO   => $user,
              PAYMENT_ID  => $payments->{PAYMENT_ID},
              SUM         => $amount,
              QUITE       => 1 });
        }
        #Transactions registration error
        else {
          if ($Paysys->{errno} && $Paysys->{errno} == 7) {
            $status      = 7;
            $payments_id = $payments->{ID};
          }
          #Payments error
          elsif ($Paysys->{errno}) {
            $status = 99;
          }
        }
      }
    }

    if ($status==0) {
      #Send mail
            if ($conf{PAYSYS_EMAIL_NOTICE}) {
            my $message = "\n" . "================================" .
        "System: $payment_system\n" .
        "================================" .
        "DATE: $DATE $TIME\n" .
        "FIO: $user->{FIO}\n" . 
        "LOGIN: $user->{LOGIN}\n" . 
        "SUM: $amount" . "\n\n";

            sendmail("$conf{ADMIN_MAIL}", "$conf{ADMIN_MAIL}", "$payment_system ADD", "$message", "$conf{MAIL_CHARSET}", "2 (High)");
            }

      privat_terminal_result2('ok',
        qq {<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
          <Transfer xmlns="http://debt.privatbank.ua/Transfer" interface="Debt" action="Pay">
            <Data xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="Gateway" reference="$payments->{PAYMENT_ID}">
            </Data>
          </Transfer>
        },
        { action => $request_type } );
    }
    else {
      privat_terminal_result2('error', '', { error_code => $status,
                                             action     => $request_type });
    }
  }
  #Cancel payments
  elsif ($request_type eq 'Cancel') {
    my $user;
    my $payments_id  = 0;
    my ($transaction)= keys %{ $request_hash{Data} };
    my $ext_id       = $transaction;
    my $user_account = $request_hash{Data}->{$transaction}->{PayerInfo}->[0]->{billIdentifier};
    my $amount       = $request_hash{Data}->{$transaction}->{TotalSum}->[0];
    my $id           = 0;
    my $list = $payments->list({ EXT_ID    => "$payment_system:$transaction",
                                 BILL_ID   => '_SHOW',
                                 COLS_NAME => 1 });

    if ($payments->{errno}) {
      if ($payments->{errno} == 2) {
        $status = 0;
      }
      else {
         $status = 99;
      }
    }
    elsif ($payments->{TOTAL} < 1) {
      $status = 98;
    }
    else {
      $id   = $list->[0]->{id};
      my %user = (
        BILL_DI => $list->[0]->{bill_id},
        UID     => $list->[0]->{uid}
      );

      $payments->del(\%user, $id);
      if (!$payments->{errno}) {
        $status = 0;
        my $list = $Paysys->list({ TRANSACTION_ID => "$payment_system:$transaction",
                                   COLS_NAME      => 1 });
        if ($Paysys->{TOTAL} > 0) {
          $Paysys->change(
            {
              ID             => $list->[0]->{id},
              STATUS         => 3,
            }
          );
        }
      }
      else {
        $status = 99;
      }
    }

    if ($status==0) {
      privat_terminal_result2('ok',
        qq {<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
            <Transfer xmlns="http://debt.privatbank.ua/Transfer" interface="Debt" action="Cancel">
              <Data xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="Gateway" reference="$id" />
            </Transfer>
        },
        { action => $request_type } );
    }
    else {
      privat_terminal_result2('error', '', { error_code => $status,
                                             action     => $request_type });
    }
  }
  #CALC
  elsif ($request_type eq 'Calc') {

  }
  #Upload payments
  elsif ($request_type eq 'Upload') {
    my $user;
    my $ext_id       = $transaction;
    my $user_account = $request_hash{Data}->[0]->{Unit}->{$transaction}->{PayerInfo}->[0]->{billIdentifier};
    my $amount       = $request_hash{Data}->[0]->{Unit}->{$transaction}->{TotalSum}->[0];
    my $id           = 0;

    my %payment_list = ();
    my $list = $payments->list({ EXT_ID    => "$payment_system:*",
                                 SUM       => '_SHOW',
                                 COLS_NAME => 1
                               });

    foreach my $line ( @$list ) {
      $line->{ext_id} =~ s/$payment_system://g;
      $payment_list{$line->{ext_id}}=$line->{sum};
    }

   (undef, $transaction) = keys %{ $request_hash{Data}->[0]->{Unit} };

    foreach my $info ( @{ $request_hash{Data}->[0]->{Unit}->{$transaction}->{PaymentGroup} })  {

      my ($payment_key) = keys %{ $info->{Payment} };
      my ($ext_id,
          $amount,
          $date,
          $user_account)=
         (
          $payment_key,
          $info->{Payment}->{$payment_key}->{TotalSum}->[0],
          $info->{Payment}->{$payment_key}->{CreateTime}->[0],
          $info->{Payment}->{$payment_key}->{PayerInfo}->[0]->{billIdentifier} || $info->{Payment}->{$payment_key}->{PayerInfo}->[0]->{bill_identifier}
         );

      if ($debug > 4) {
        print "===========================\n".
              "ID: $ext_id\n".
              "SUM: $amount\n".
              "DATE: $date\n".
              "ABON ID: $user_account\n";
      }

      if (! $payment_list{"$payment_system:$transaction_id"}) {
        print "Add payment" if ($debug >4);

        if ($CHECK_FIELD eq 'UID') {
          $user = $users->info($user_account);
        }
        else {
          my $list = $users->list({ $CHECK_FIELD => $user_account || '---',
                                    COLS_NAME    => 1  });

          if (!$users->{errno} && $users->{TOTAL} > 0) {
            my $uid = $list->[0]->{uid};
            $user = $users->info($uid);
          }
        }

        if ($user->{errno}) {
        	print "User defibed error\n" if ($debug > 4);
        	next;
        }

        $payments->add(
          $user,
          {
            SUM          => $amount,
            DESCRIBE     => "$payment_system",
            METHOD       => ($conf{PAYSYS_PAYMENTS_METHODS} && $PAYSYS_PAYMENTS_METHODS{$payment_system_id}) ? $payment_system_id : '2',
            EXT_ID       => "$payment_system:$ext_id",
            CHECK_EXT_ID => "$payment_system:$ext_id"
          }
        );

        #Exists
        # Dublicate
        if ($payments->{errno} && $payments->{errno} == 7) {
          my $list = $Paysys->list({ TRANSACTION_ID => "$payment_system:$ext_id" });
          $payments_id = $payments->{ID};
          if ($Paysys->{TOTAL} == 0) {
            $Paysys->add(
              {
                SYSTEM_ID      => $payment_system_id,
                DATETIME       => "$DATE $TIME",
                SUM            => "$amount",
                UID            => "$user->{UID}",
                IP             => '0.0.0.0',
                TRANSACTION_ID => "$payment_system:$ext_id",
                INFO           => "STATUS: $status ",
                PAYSYS_IP      => "$ENV{'REMOTE_ADDR'}",
                STATUS         => 2
              }
            );

            if (! $Paysys->{errno}) {
              cross_modules_call('_payments_maked', {
                 USER_INFO  => $user,
                 PAYMENT_ID => $payments->{PAYMENT_ID},
                 SUM        => $amount,
                 QUITE      => 1 });
            }

            $status = 7;
          }
          else {
            $status = 7;
          }
        }

      }
    }

    my $reference = time();
    privat_terminal_result(qq{<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Transfer xmlns="http://debt.privatbank.ua/Transfer" interface="Debt" action="Upload">
<Data xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="Gateway"
reference="$reference">
</Data></Transfer>} );

  }

#  privat_terminal_result(
#    qq {<?xml version="1.0" encoding="UTF-8" ?>
#<pay-response>
#<error>$status</error>
#<time_stamp>$EURO_DATE $TIME</time_stamp>
#</pay-response> }
#  );

  return 0;
}


#**********************************************************
#
#**********************************************************
sub privat_terminal_result2 {
  my ($result, $content, $attr) = @_;

  my %error_codes = (
    1  => 'Неизвестный тип запроса',
    2  => 'Абонент не найден',
    3  => 'Ошибка в формате денежной суммы (“Сумма платежа” или “Сумма к оплате”)',
    4  => 'Неверный формат даты',
    5  => 'Доступ с данного IP не предусмотрен',
    6  => 'Найдено более одного плательщика. Уточните параметра поиска.',
    7  => 'Дублирование платежа.*',
    98=> 'Платёж не найден',
    99=> 'Другая ошибка провайдера(Можно указать любое другое сообщение)'
  );

  if ($result eq 'error') {
    my $error_code = $attr->{error_code} || 0;
    my $action     = $attr->{action}     || 0;

    if (! $content && $error_code ) {
      $content = $error_codes{$error_code};
    }

    $content = qq{<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Transfer xmlns="http://debt.privatbank.ua/Transfer" interface="Debt" action="$action">
          <Data xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="ErrorInfo" code="$error_code">
           <Message>$content</Message>
         </Data>
       </Transfer>
    };
  }

  print $content;

  if ($debug > 0) {
    $content = "QUERY: $ENV{QUERY_STRING}\n\n" . $content;
    mk_log($content, { PAYSYS_ID => 'privat_terminal2' });
  }

  return 1;
}

#**********************************************************
#
#**********************************************************
sub account_gid_split {
  my ($gid) = @_;

if ($conf{'PAYSYS_PRIVAT_BANK_COMPANY_ID_'.$gid}) {
  $conf{PAYSYS_PRIVAT_BANK_COMPANY_ID}=$conf{'PAYSYS_PRIVAT_BANK_COMPANY_ID_'.$gid};
}

if ($conf{'PAYSYS_PRIVAT_BANK_SERVICE_'.$gid}) {
  $conf{PAYSYS_PRIVAT_BANK_SERVICE}=$conf{'PAYSYS_PRIVAT_BANK_SERVICE_'.$gid};
}

if ($conf{'PAYSYS_PRIVAT_BANK_SERVICE_ID_'.$gid}) {
  $conf{PAYSYS_PRIVAT_BANK_SERVICE_ID}=$conf{'PAYSYS_PRIVAT_BANK_SERVICE_ID_'.$gid};
}

#version 2
if ($conf{'PAYSYS_PRIVAT_TERMINAL_MFO_'. $gid}) {
  $conf{'PAYSYS_PRIVAT_TERMINAL_MFO'} = $conf{'PAYSYS_PRIVAT_TERMINAL_MFO_'. $gid};
}

if ($conf{'PAYSYS_PRIVAT_TERMINAL_OKPO_'. $gid}) {
 $conf{'PAYSYS_PRIVAT_TERMINAL_OKPO'} = $conf{'PAYSYS_PRIVAT_TERMINAL_OKPO_'. $gid};
}

if ($conf{'PAYSYS_PRIVAT_TERMINAL_CODE_'. $gid}) {
  $conf{'PAYSYS_PRIVAT_TERMINAL_CODE'} = $conf{'PAYSYS_PRIVAT_TERMINAL_CODE_'. $gid};
}

if ($conf{'PAYSYS_PRIVAT_TERMINAL_NAME_'. $gid}) {
  $conf{'PAYSYS_PRIVAT_TERMINAL_NAME'} = $conf{'PAYSYS_PRIVAT_TERMINAL_NAME_'. $gid};
}

if ($conf{'PAYSYS_PRIVAT_TERMINAL_ACCOUNT_'. $gid}) {
  $conf{'PAYSYS_PRIVAT_TERMINAL_ACCOUNT'} = $conf{'PAYSYS_PRIVAT_TERMINAL_ACCOUNT_'. $gid};
}

if ($conf{'PAYSYS_PRIVAT_TERMINAL_SERVICE_CODE_'. $gid}) {
  $conf{'PAYSYS_PRIVAT_TERMINAL_SERVICE_CODE'} = $conf{'PAYSYS_PRIVAT_TERMINAL_SERVICE_CODE_'. $gid};
  $service_code = $conf{PAYSYS_PRIVAT_TERMINAL_SERVICE_CODE};
}

}


1
