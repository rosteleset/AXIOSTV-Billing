=head1 OSMPv4

  New module for OSMP payment system version 4
  Requests in protocol: http://media-transfer.ru/media/Bill_payment_protocol_1.4.pdf
  Date: 07.03.2019

=cut
use strict;
use warnings;
use AXbills::Base;
use AXbills::Misc;

require Paysys::Paysys_Base;
package Paysys::systems::Osmpv4;

our $PAYSYSTEM_NAME = 'Osmpv4';
our $PAYSYSTEM_SHORT_NAME = 'OSMPV4';
our $PAYSYSTEM_ID = 61;
our $PAYSYSTEM_VERSION = '7.00';

my $CUSTOM_NAME = uc($PAYSYSTEM_NAME);
my $CUSTOM_ID = $PAYSYSTEM_ID;

our %PAYSYSTEM_CONF = (
  "PAYSYS_NAME_LOGIN"       => '',
  "PAYSYS_NAME_PASSWD"      => '',
#  "PAYSYS_NAME_EXT_PARAMS"  => '',
#  "PAYSYS_NAME_EXTRA_INFO"  => '',
  "PAYSYS_NAME_ACCOUNT_KEY" => '',
);

my $version = '0.8'; #version for response

# Transaction status code
my %status_id_hash = (
  1 => 10,  #Не обработана
  2 => 30,  #Авторизована
  3 => 60,  #Проведена
  4 => 125, #Не смогли отправить провайдеру
  5 => 130, #Отказ от провайдера
  6 => 160, #Не проведена
);

# Error code
my %result_code_hash = (
  0  => 0,   #OK
  1  => 1,   #Провайдер временно недоступен
  2  => 4,   #Неверный формат счета/телефона Неверный N счета
  3  => 10,  #Дублирование платежа Дублирование платежа
  4  => 13,  #Сервер занят, повторите запрос через минуту Подождите минуту
  5  => 150, #Неверный пароль или нет прав на этот терминал Неверный пароль
  6  => 202, #Ошибка данных запроса Ошибка данных запроса
  7  => 203, #Транзакция не найдена в базе данных Транзакция не найдена
  8  => 240, #Не проведена
  9  => 241, #Сумма слишком мала Сумма Мин
  10  => 275, #Некорректная сумма платежа Сумма некорректна
  11 => 300, #Другая (неизвестная) ошибка провайдера Ошибка пров.
);

AXbills::Base::load_pmodule('XML::Simple');
AXbills::Base::load_pmodule('Digest::MD5');
our $md5 = Digest::MD5->new();

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
=head2 proccess() - Managing payments

  Arguments:
     -

  Returns:
    process result
=cut
#**********************************************************
sub proccess {
  my $self = shift;
  my ($FORM) = @_;
  my $request_type = q{};
  my $request_info = ();
  my $status_id = 0;
  my $result_code = 0;

  print "Content-Type: text/xml\n\n";

  $FORM->{__BUFFER} = '' if (!$FORM->{__BUFFER});
  $FORM->{__BUFFER} =~ s/data=//;
  $FORM->{__BUFFER} =~ s/encoding="windows-1251"//g;
  $request_info = $self->_get_request_info($FORM->{__BUFFER});
  $request_type = $request_info->{'request_type'} || 0;

  # Password to md5
  if ($request_info->{'extra_password_md5'}) {
    $md5->reset;
    $md5->add($self->{conf}{"PAYSYS_" . $CUSTOM_NAME . "_PASSWD"});
    $self->{conf}{"PAYSYS_" . $CUSTOM_NAME . "_PASSWD"} = lc($md5->hexdigest());
  }
  # Check osmp login and pass
  if ($self->{conf}{"PAYSYS_" . $CUSTOM_NAME . "_LOGIN"} ne $request_info->{'extra_login'}
    || ($request_info->{'extra_password_md5'} && $self->{conf}{"PAYSYS_" . $CUSTOM_NAME . "_PASSWD"} ne $request_info->{'extra_password_md5'})) {
    $status_id = $status_id_hash{1};
    $result_code = $result_code_hash{5};
    return $self->error_show_responce({
      STATUS_ID   => $status_id,
      RESULT_CODE => $result_code,
      REQ_TYPE    => $request_type,
      TERM_ID     => $request_info->{'terminal_id'}
    });
  }

  if($request_type && $request_type eq '1') {
      my $check_result = $self->check($request_info);
      return $self->show_responce({ REQ_TYPE => $request_type, RESPONSE => $check_result });
    }
  elsif($request_type && $request_type eq '2'){
    my $pay_result = $self->pay($request_info);
    return $self->show_responce({ REQ_TYPE => $request_type, RESPONSE => $pay_result });
  }
  elsif($request_type && $request_type eq '3'){
    my $cancel_result = $self->cancel($request_info);
    return $self->show_responce({ REQ_TYPE => $request_type, RESPONSE => $cancel_result });
  }
  #  elsif($request_type && $request_type eq '4'){

  #  }

  return 1;
}

#**********************************************************
=head2 check()

  Arguments:
    $attr -

  Returns:

=cut
#**********************************************************
sub check {
  my $self = shift;
  my ($req_info) = @_;
  my $user;
  my $status_id = $status_id_hash{2};
  my $result_code = $result_code_hash{0};
  my $service_id = 0;
  my $response = '';
  my $BALANCE = 0.00;
  my $OVERDRAFT = 0.00;
  my $date = "$main::DATE" . "T" . "$main::TIME";
  my $txn_id = 0;
  my $CHECK_FIELD = $self->{conf}{"PAYSYS_" . $CUSTOM_NAME . "_ACCOUNT_KEY"} || 'UID';
  my $sum = $req_info->{to_amount};
  my $account_number = $req_info->{to_account_number};
  $service_id = $req_info->{to_service_id};
  my $transaction_number = $req_info->{'transaction_number'};
  my $terminal_id = $req_info->{'terminal_id'};

  if (!$account_number) {
    $status_id = $status_id_hash{1};
    $result_code = $result_code_hash{2};
    return $self->error_show_responce({
      STATUS_ID   => $status_id,
      RESULT_CODE => $result_code,
      REQ_TYPE    => $req_info->{'request_type'},
      TERM_ID     => $req_info->{'terminal_id'}
    });
  }

  ($result_code, $user) = main::paysys_check_user({
    CHECK_FIELD        => $CHECK_FIELD,
    USER_ID            => $account_number,
    DEBUG              => $self->{DEBUG},
    SKIP_DEPOSIT_CHECK => 1
  });

  if ($result_code > 0) {
    $status_id = $status_id_hash{1};
    $result_code = $result_code_hash{2};
    return $self->error_show_responce({
      STATUS_ID   => $status_id,
      RESULT_CODE => $result_code,
      REQ_TYPE    => $req_info->{'request_type'},
      TERM_ID     => $req_info->{'terminal_id'}
    });
  }

  my $fio = AXbills::Base::convert(($user->{FIO} || ''), { utf82win => 1 });

  $response = qq{<terminal-id>$terminal_id</terminal-id>
  <result-code>$result_code</result-code>
  <operator-id>$self->{admin}{AID}</operator-id>
  <extra name="REMOTE_ADDR">$ENV{REMOTE_ADDR}</extra>
  <extra name="serial">$version</extra>
  <extra name="BALANCE">$BALANCE</extra>
  <extra name="OVERDRAFT">$OVERDRAFT</extra>
  <extra name="user_name">$fio</extra>
  <extra name="ServerTime">$date</extra>
  <status-id>$status_id</status-id>
  <transaction-number>$transaction_number</transaction-number>
  <txn-id>$txn_id</txn-id>
  <to>
    <service-id>$service_id</service-id>
    <amount>$sum</amount>
    <account-number>$account_number</account-number>
  </to>};


  return $response;
}

#**********************************************************
=head2 pay()

  Arguments:
     -

  Returns:
    response
=cut
#**********************************************************
sub pay {
  my $self = shift;
  my ($req_info) = @_;
  my $status_id = $status_id_hash{3};
  my $result_code = $result_code_hash{0};
  my $CHECK_FIELD = $self->{conf}{"PAYSYS_" . $CUSTOM_NAME . "_ACCOUNT_KEY"} || 'UID';
  my $response = '';
  my $date = "$main::DATE" . "T" . "$main::TIME";
  my $transaction_number = $req_info->{'transaction_number'};
  my $terminal_id = $req_info->{'terminal_id'};

  if (!$req_info->{to_account_number}) {
    $status_id = $status_id_hash{6};
    $result_code = $result_code_hash{2};
    return $self->error_show_responce({
      STATUS_ID   => $status_id,
      RESULT_CODE => $result_code,
      REQ_TYPE    => $req_info->{'request_type'},
      TERM_ID     => $req_info->{'terminal_id'}
    });
  }

  my ($status_code, $payments_id) = main::paysys_pay({
    PAYMENT_SYSTEM    => $PAYSYSTEM_SHORT_NAME,
    PAYMENT_SYSTEM_ID => $CUSTOM_ID,
    CHECK_FIELD       => $CHECK_FIELD,
    USER_ID           => $req_info->{to_account_number},
    SUM               => $req_info->{to_amount},
    EXT_ID            => $req_info->{receipt_receipt_number},
    DATA              => $req_info,
    DATE              => "$main::DATE $main::TIME",
    CURRENCY_ISO      => $self->{conf}{"PAYSYS_" . $CUSTOM_NAME . "_CURRENCY"},
    MK_LOG            => 1,
    PAYMENT_ID        => 1,
    DEBUG             => $self->{DEBUG},
    PAYMENT_DESCRIBE  => "$CUSTOM_NAME Payments",
  });

  if ($status_code >0) {
    $status_id = $status_id_hash{6};
    $result_code = $result_code_hash{8};
    return $self->error_show_responce({
      STATUS_ID   => $status_id,
      RESULT_CODE => $result_code,
      REQ_TYPE    => $req_info->{'request_type'},
      TERM_ID     => $req_info->{'terminal_id'}
    });
  }


  $response = qq{<terminal-id>$terminal_id</terminal-id>
  <result-code>$result_code</result-code>
  <operator-id>$self->{admin}{AID}</operator-id>
  <extra name="REMOTE_ADDR">$ENV{REMOTE_ADDR}</extra>
  <extra name="serial">$version</extra>
  <extra name="ServerTime">$date</extra>
  <status-id>$status_id</status-id>
  <transaction-number>$transaction_number</transaction-number>
  <txn-id>$payments_id</txn-id>
  <to>1</to>};

  return $response;
}

#**********************************************************
=head2 cancel() - cansel paymen transaction

  Arguments:
     -

  Returns:
    response
=cut
#**********************************************************
sub cancel {
  my ($self, $req_info) = @_;
  my $output = q{};
  my $status_id = $status_id_hash{3};
  my $result_code = $result_code_hash{0};

  if (!$req_info->{'transaction_number'}) {
    $status_id = $status_id_hash{1};
    $result_code = $result_code_hash{6};
    return $self->error_show_responce({
      STATUS_ID   => $status_id,
      RESULT_CODE => $result_code,
      REQ_TYPE    => $req_info->{'request_type'},
      TERM_ID     => $req_info->{'terminal_id'}
    });
  }

  my $result = main::paysys_pay_cancel({
    TRANSACTION_ID => "$PAYSYSTEM_SHORT_NAME:$req_info->{'transaction_number'}"
  });

  if ($result > 0) {
    $status_id = $status_id_hash{1};
    $result_code = $result_code_hash{7};
    return $self->error_show_responce({
      STATUS_ID   => $status_id,
      RESULT_CODE => $result_code,
      REQ_TYPE    => $req_info->{'request_type'},
      TERM_ID     => $req_info->{'terminal_id'}
    });
  }

  $output = qq{<terminal-id>$req_info->{'terminal_id'}</terminal-id>
    <result-code>$result_code</result-code>
    <status-id>$status_id</status-id>
    <transaction-number>$req_info->{'transaction_number'}</transaction-number>};

  return $output;
}

#***********************************************************
=head2 get_request_info() - parse xml and make a log

=cut
#***********************************************************
sub _get_request_info {
  my $self = shift;
  my ($xml) = @_;
  my %request_hash = ();

  my $req_xml = eval {XML::Simple::XMLin("$xml", SuppressEmpty => 1, forcearray => 1 )};

  if ($@) {
    main::mk_log("---- Content:\n" . $xml . "\n----XML Error:\n" . $@ . "\n----\n");
    print "Content-Type: text/xml\n\n";
    print qq{<?xml version="1.0" encoding="UTF-8" ?> <ERROR>999</ERROR>};
    return 0;
  }
  else {
    if ($self->{DEBUG} == 1) {
      main::mk_log($xml, { PAYSYS_ID => "$CUSTOM_ID/$CUSTOM_NAME", REQUEST => 'Request' });
    }
  }
  $request_hash{'request_type'} = $req_xml->{'request-type'}[0] || 0;
  $request_hash{'from_amount'} = $req_xml->{'from'}[0]{'amount'}[0]{'content'} || '';
  $request_hash{'from_amount_currency_code'} = $req_xml->{'from'}[0]{amount}[0]{'currency-code'} || '';
  $request_hash{'protocol_version'} = $req_xml->{'protocol-version'}[0] || '';
  $request_hash{'transaction_number'} = $req_xml->{'transaction-number'}[0] || '';
  $request_hash{'to_account_number'} = $req_xml->{'to'}[0]{'account-number'}[0] || '';
  $request_hash{'to_amount'} = $req_xml->{'to'}[0]{'amount'}[0]{'content'} || '';
  $request_hash{'to_amount_currency_code'} = $req_xml->{'to'}[0]{'amount'}[0]{'currency-code'} || '';
  $request_hash{'to_service_id'} = $req_xml->{'to'}[0]{'service-id'}[0] || '';
  $request_hash{'receipt_receipt_number'} = $req_xml->{receipt}[0]{'receipt-number'}[0] || '';
  $request_hash{'receipt_datetime'} = $req_xml->{receipt}[0]{'datetime'}[0] || '';
  $request_hash{'terminal_id'} = $req_xml->{'terminal-id'}[0] || '';
  $request_hash{'extra_client_software'} = $req_xml->{'extra'}{'client-software'}{'content'} || '';
  $request_hash{'extra_login'} = $req_xml->{'extra'}{'login'}{'content'} || '';
  $request_hash{'extra_password_md5'} = $req_xml->{'extra'}{'password-md5'}{'content'} || '';

  main::mk_log("$xml", { PAYSYS_ID => "$CUSTOM_ID/$CUSTOM_NAME", REQUEST => 'Request' });

  return \%request_hash;
}

#**********************************************************
=head2 error_show_responce($resp) - print error and make log

  Arguments:
    STATUS_ID   - status code
    RESULT_CODE - result code
    REQ_TYPE - request type
    TERM_ID - terminal id

  Returns:
    true
=cut
#**********************************************************
sub error_show_responce {
  my ($attr) = @_;

  my $output = qq{<terminal-id>$attr->{TERM_ID}</terminal-id>
    <status-id>$attr->{STATUS_ID}</status-id>
    <txn-id>0</txn-id>
    <result-code>$attr->{RESULT_CODE}</result-code>};

return $output;
}

#**********************************************************
=head2 show_responce($attr) - print response and make log

  Arguments:
    REQ_TYPE - request type
    RESPONCE - response body

  Returns:
    true
=cut
#**********************************************************
sub show_responce {
  my $self = shift;
  my ($attr) = @_;

  my $output = qq{<?xml version="1.0" encoding="UTF-8" ?>
    <response>
    <protocol-version>4.00</protocol-version>
    <request-type>$attr->{REQ_TYPE}</request-type>
    $attr->{RESPONSE}
    </response>};

  print "Content-Type: text/plain\n\n" if ($self->{DEBUG} > 1);
  print "Content-Type: text/xml\n\n";
  print $output;

  main::mk_log("RESPONSE:\n" . $output, { PAYSYS_ID => "$CUSTOM_ID/$CUSTOM_NAME", REQUEST => 'Response' });

  return 1;
}

1;