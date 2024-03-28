#***********************************************************
# Ibox
# http://www.ibox.com.ua/
# 
#***********************************************************

$debug   = $conf{PAYSYS_DEBUG} || 1;
$version = 0.7;
our %system_params;
if ($debug > 1) {
  print "Content-Type: text/plain\n\n";
}

my $buffer = $ENV{'QUERY_STRING'};
@pairs = split(/&/, $buffer);

#$FORM{BUFFER}=$buffer if ($#pairs > -1);

foreach my $pair (@pairs) {
  my ($side, $value) = split(/=/, $pair);
  if (defined($value)) {
    $value =~ tr/+/ /;
    $value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
    $value =~ s/<!--(.|\n)*-->//g;
    $value =~ s/<([^>]|\n)*>//g;

    #Check quotes
    $value =~ s/"/\\"/g;
    $value =~ s/'/\\'/g;
  }
  else {
    $value = '';
  }

  $FORM{$side} = $value;
}

$FORM{__BUFFER} = '' if (!$FORM{__BUFFER});

#ibox(\%system_params);

#**********************************************************
# http://www.ibox.com.ua/
# Example:
#
# СПРАВОЧНИК КОДОВ ОШИБОК
#
#
#**********************************************************
sub ibox_check_payment {
  my ($attr) = @_;

  if ($conf{PAYSYS_IBOX_PASSWD}) {
    my ($user, $password) = split(/:/, $conf{PAYSYS_PEGAS_PASSWD});

    if (defined($ENV{HTTP_CGI_AUTHORIZATION})) {
      $ENV{HTTP_CGI_AUTHORIZATION} =~ s/basic\s+//i;
      my ($REMOTE_USER, $REMOTE_PASSWD) = split(/:/, decode_base64($ENV{HTTP_CGI_AUTHORIZATION}));

      if ( (!$REMOTE_PASSWD)
        || ($REMOTE_PASSWD && $REMOTE_PASSWD ne $password)
        || (!$REMOTE_USER)
        || ($REMOTE_USER   && $REMOTE_USER   ne $user))
      {
        print "WWW-Authenticate: Basic realm=\"Billing system\"\n";
        print "Status: 401 Unauthorized\n";
        print "Content-Type: text/html\n\n";
        print "Access Deny";
        exit;
      }
    }
  }

  print "Content-Type: text/xml\n\n";
  my $txn_id            = 'ibox_txn_id';
  my $payment_system    = $attr->{SYSTEM_SHORT_NAME} || 'IBOX';
  my $payment_system_id = $attr->{SYSTEM_ID} || 60;
  my $CHECK_FIELD       = $conf{PAYSYS_IBOX_ACCOUNT_KEY} || 'UID';

  my %status_hash = (
    0   => 'ОК',
    1   => 'Временная ошибка. Повторите запрос позже',
    2   => '',
    4   => 'Неверный формат идентификатора абонента',
    5   => 'Идентификатор абонента не найден (Ошиблись номером)',
    7   => 'Прием платежа запрещен провайдером',
    8   => 'Прием платежа запрещен по техническим причинам',
    79  => 'Счет абонента не активен',
    90  => 'Проведение платежа не окончено',
    241 => 'Сумма слишком мала',
    242 => 'Сумма слишком велика',
    243 => 'Невозможно проверить состояние счета',
    300 => 'Другая ошибка провайдера'
  );

  my $comments = '';
  my $command = $FORM{command} || '';
  $FORM{account} =~ s/^0+//g if ($FORM{account} && $CHECK_FIELD eq 'UID');
  my %RESULT_HASH = (result => 300);
  my $results = '';

  #Check user account
  #https://service.someprovider.ru:8443/payment_app.cgi?command=check&txn_id=1234567&account=0957835959&sum=10.45
  if ($command eq 'check') {
    if($FORM{account} eq '') {
      $FORM{account} = '1234567890abc';
    }
    my $list = $users->list({ FIO          => '_SHOW',
    	                        DEPOSIT      => '_SHOW',
    	                        $CHECK_FIELD => $FORM{account},
    	                        COLS_NAME    => 1 });

    if ($users->{errno}) {
      $status = 300;
    }
    elsif ($users->{TOTAL} < 1) {
      $status   = 5;
      $comments = 'User Not Exist';
    }
    else {
      $status = 0;
    }

    $RESULT_HASH{result}  = $status;
    $RESULT_HASH{$txn_id} = $FORM{txn_id};
    $RESULT_HASH{comment} = "$list->[0]->{fio} ($list->[0]->{login})";
    $RESULT_HASH{fields}  = "<field1 name=\"FIO\">$list->[0]->{fio}</field1>
<field2 name=\"balance\">$list->[0]->{deposit}</field2>";
  }

  #Cancel payments
  elsif ($command eq 'cancel') {
    my $prv_txn = $FORM{prv_txn} || 0;
    my $cancel_txn_id = $FORM{cancel_txn_id};
    $RESULT_HASH{prv_txn} = $prv_txn;

    my $list = $payments->list({ EXT_ID => "IBOX:$cancel_txn_id", COLS_NAME => 1 });

    if ($payments->{errno}) {
      $RESULT_HASH{result} = 1;
    }
    elsif ($payments->{TOTAL} < 1) {
      if ($conf{PAYSYS_PEGAS}) {
        $RESULT_HASH{result} = 0;
      }
      else {
        $RESULT_HASH{result} = 79;
      }
    }
    else {
      my $id   = $list->[0]{id};
      my %user = (
        BILL_DI => $list->{bill_id},
        UID     => $list->{uid}
      );

      $payments->del(\%user, $id);
      if (!$payments->{errno}) {
        $RESULT_HASH{result}        = 0;
        $RESULT_HASH{osmp_txn_id}   = $FORM{txn_id} || '';
        $RESULT_HASH{cancel_txn_id} = $FORM{cancel_txn_id} || '';
        $RESULT_HASH{prv_txn}       = $id || 0;
        $RESULT_HASH{sum}           = $FORM{sum} || 0;
        $RESULT_HASH{comment}       = 'OK';
      }
      else {
        $RESULT_HASH{result} = 1;
      }
    }
  }
  elsif ($command eq 'balance') {

  }

  #https://service.someprovider.ru:8443/payment_app.cgi?command=pay&txn_id=1234567&txn_date=20050815120133&account=0957835959&sum=10.45
  elsif ($command eq 'pay') {
    my $user;
    my $payments_id = 0;
     if($FORM{account} eq ''){
      $FORM{account} = '1234567890abc';
      }
    if ($CHECK_FIELD eq 'UID') {
      $user = $users->info($FORM{account});
    }
    else {
      my $list = $users->list({ $CHECK_FIELD => $FORM{account}, COLS_NAME => 1 });

      if (!$users->{errno} && $users->{TOTAL} > 0) {
        my $uid = $list->[0]->{uid};
        $user = $users->info($uid);
      }
    }

    if ($users->{errno}) {
      $status = ($users->{errno} == 2) ? 5 : 300;
    }
    elsif ($users->{TOTAL} < 1) {
      $status = 5;
    }
    else {

      cross_modules_call('_pre_payment', 
            {
              USER_INFO  => $user,
              SUM        => $FORM{sum},
              QUITE      => 1,
            }
       );


      #Add payments
      $payments->add(
        $user,
        {
          SUM      => $FORM{sum},
          DESCRIBE => "$payment_system",
          METHOD   => ($conf{PAYSYS_PAYMENTS_METHODS} && $PAYSYS_PAYMENTS_METHODS{$payment_system_id}) ? $payment_system_id : '2',
          ,
          EXT_ID       => "$payment_system:$FORM{txn_id}",
          CHECK_EXT_ID => "$payment_system:$FORM{txn_id}"
        }
      );

      #Exists
      if ($payments->{errno} && $payments->{errno} == 7) {
        $status      = 0;
        $payments_id = $payments->{ID};
      }
      elsif ($payments->{errno}) {
        $status = 2;
      }
      else {
        $status = 0;
        $Paysys->add(
          {
            SYSTEM_ID      => $payment_system_id,
            DATETIME       => "'$DATE $TIME'",
            SUM            => "$FORM{sum}",
            UID            => "$user->{UID}",
            IP             => '0.0.0.0',
            TRANSACTION_ID => "$payment_system:$FORM{txn_id}",
            INFO           => "TYPE: $FORM{command} PS_TIME: " . (($FORM{txn_date}) ? $FORM{txn_date} : '') . " STATUS: $status $status_hash{$status}",
            PAYSYS_IP      => "$ENV{'REMOTE_ADDR'}",
            STATUS         => 2
          }
        );

        $payments_id = ($payments->{INSERT_ID}) ? $payments->{INSERT_ID} : 0;
        cross_modules_call('_payments_maked', { USER_INFO  => $user, 
                                                SUM        => $FORM{sum}, 
                                                PAYMENT_ID => $payments->{PAYMENT_ID},
                                                QUITE      => 1 
                                              });
      }

    }

    $RESULT_HASH{result}  = $status;
    $RESULT_HASH{$txn_id} = $FORM{txn_id};
    $RESULT_HASH{prv_txn} = $payments_id;
    $RESULT_HASH{sum}     = $FORM{sum};
    $RESULT_HASH{comment} = $status_hash{$status};
  }

  #Result output
  $RESULT_HASH{comment} = $status_hash{ $RESULT_HASH{result} } if ($RESULT_HASH{result} && !$RESULT_HASH{comment});

  while (my ($k, $v) = each %RESULT_HASH) {
    $results .= "<$k>$v</$k>\n";
  }

  my $response = qq{<?xml version="1.0" encoding="UTF-8"?> 
<response>
$results
</response>
};

  print $response;
  if ($debug > 0) {
    mk_log($response);
  }

  exit;
}

1
