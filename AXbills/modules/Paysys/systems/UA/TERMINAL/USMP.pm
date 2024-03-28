package Paysys::systems::USMP;
=head1 USMP
  New module for USMP with emulation

  Documentaion:

  DATE: 15.05.2019
  UPDATE: 16.04.2020

  VERSION: 7.02
=cut


use strict;
use warnings;

use AXbills::Base qw(_bp load_pmodule );
use AXbills::Misc qw();
require Paysys::Paysys_Base;

use Paysys;


our $PAYSYSTEM_NAME = 'USMP';
our $PAYSYSTEM_SHORT_NAME = 'USMP';
our $PAYSYSTEM_ID = 47;
our $PAYSYSTEM_VERSION = '7.00';

my $CUSTOM_NAME = uc($PAYSYSTEM_NAME);
my $CUSTOM_ID   = $PAYSYSTEM_ID;

our %PAYSYSTEM_CONF = (
  PAYSYS_NAME_ACCOUNT_KEY => '',
  PAYSYS_NAME_FAST_PAY      => '',
);

my ($html);

my %comments_arr = (
  0   => 'ОК',
  1   => 'Временная ошибка. Повторите запрос позже',
  2   => 'Внутренняя ошибка системы',
  3   => 'Неверный формат идентификатора абонента',
  21  => 'Идентификатор абонента не найден (ошиблись номером)',
  22  => 'Приём платежа запрещён провайдером',
  23  => 'Приём платежа запрещён по техническим причинам (ошибка на стороне провайдера)',
  24  => 'Счёт абонента не активен',
  25  => 'Невозможно проверить состояние счета',
  100 => 'Проведение платежа не окончено',
  241 => 'Сумма слишком мала',
  242 => 'Сумма слишком велика',
  299 => 'Другая ошибка провайдера'
);

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
  $SETTINGS{ID} = $CUSTOM_ID;
  $SETTINGS{NAME} = $PAYSYSTEM_NAME;

  $SETTINGS{CONF} = \%PAYSYSTEM_CONF;

  return %SETTINGS;
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

  my $action = $FORM->{QueryType}     || '';

  if($action eq 'check'){
    my $check_result = $self->check($FORM);
    $check_result->{test} = 1 if $FORM->{test};
    return $self->_show_response($check_result);
  }
  elsif($action eq 'pay'){
    my $check_result = $self->pay($FORM);
    $check_result->{test} = 1 if $FORM->{test};
    return $self->_show_response($check_result);
  }
  elsif($action eq 'cancel'){
    my $check_result = $self->cancel($FORM);
    $check_result->{test} = 1 if $FORM->{test};
    return $self->_show_response($check_result);
  }
   else{
    my $check_result = $self->periodic($FORM);
    return $check_result;
  }
}

#**********************************************************
=head2 _show_response() - print response

  Arguments:
     RESULT_HASH

  Returns:
     text
=cut
#**********************************************************
sub _show_response {
  my ($self, $RESULT_HASH) = @_;

  my $results = '';
  while (my ($k, $v) = each %{ $RESULT_HASH }) {
    if (ref $v eq "HASH") {
      $results .= "<$k>\n";
      my $i = 1;
      foreach my $key (sort keys %$v) {
        $results .= "<field$i name='$key'>" . (defined $v->{$key} ? $v->{$key} : '') . "</field$i>\n";
        $i++;
      }
      $results .= "</$k>\n";
    }
    else {
      $results .= "<$k>" . (defined $v ? $v : '') . "</$k>\n";
    }
  }

  chomp($results);

  my $response = qq{<?xml version="1.0" encoding="UTF-8"?>
<Response>
 $results
</Response>
};

  return $response if $RESULT_HASH->{test};
  print "Content-Type: text/plain\n\n" if ($self->{DEBUG} > 3);
  print "Content-Type: text/xml\n\n";
  print $response;

  main::mk_log("$response", { PAYSYS_ID => "$CUSTOM_ID/$CUSTOM_NAME", REQUEST => 'Response' });

  return $response;
}

#**********************************************************
=head2 check() - check if user exist

  Arguments:
     %FORM
       account - user ID
       sum     - amount of money
       txn_id  - payment ID
       prv_txn -
       action  -

  Returns:
    REF HASH
=cut
#**********************************************************
sub check {
  my ($self) = shift;
  my ($FORM) = @_;

  _get_request_info($FORM);

  my $CHECK_FIELD = $self->{conf}{"PAYSYS_" . $CUSTOM_NAME . "_ACCOUNT_KEY"} || 'UID';

  my %RESULT_HASH = (
    TransactionId => $FORM->{TransactionId},
  );

  if (!$FORM->{Account}) {
    $RESULT_HASH{ResultCode}   = 21;
    $RESULT_HASH{Comment} = 'Account Not found';
  }
  else {
    my ($result_code, $user_object) = main::paysys_check_user({
      CHECK_FIELD        => $CHECK_FIELD,
      USER_ID            => $FORM->{Account},
      DEBUG              => $self->{DEBUG},
      SKIP_DEPOSIT_CHECK => 1
    });


    if ($result_code == 1) {
      $RESULT_HASH{ResultCode}   = 21;
      $RESULT_HASH{Comment} = 'Account Not found';
    }
    elsif ($result_code == 2) {
      $RESULT_HASH{ResultCode}   = 1;
      $RESULT_HASH{Comment} = 'SQL Error';
    }
    else {
      $RESULT_HASH{ResultCode} = 0;
      $RESULT_HASH{Fields}{address}  = "$user_object->{address_full}";
      $RESULT_HASH{Fields}{deposit}  = (sprintf('%.2f', $user_object->{deposit}) || '');
      $RESULT_HASH{Fields}{fio}="$user_object->{fio}";
    }
  }

  return \%RESULT_HASH;
}

#***********************************************************
=head2 get_request_info() - make a log

=cut
#***********************************************************
sub _get_request_info {
  my ($FORM) = @_;
  my $request = '';

  while (my ($k, $v) = each %{ $FORM }) {
    $request .= "$k => $v,\n" if ($k ne '__BUFFER');
  }
  main::mk_log("$request", { PAYSYS_ID => "$CUSTOM_ID/$CUSTOM_NAME", REQUEST => 'Request' });

  return $request;
}


#**********************************************************
=head2 pay() - make a payment for user

  Arguments:
     %FORM

  Returns:
    REF HASH

=cut
#**********************************************************
sub pay {
  my ($self) = shift;
  my ($FORM) = @_;

  _get_request_info($FORM);

  my $CHECK_FIELD = $self->{conf}{"PAYSYS_" . $CUSTOM_NAME . "_ACCOUNT_KEY"} || 'UID';

  my %RESULT_HASH = (
    TransactionId => $FORM->{TransactionId},
  );

  my ($status_code, $payments_id) = main::paysys_pay({
    PAYMENT_SYSTEM    => $PAYSYSTEM_SHORT_NAME,
    PAYMENT_SYSTEM_ID => $CUSTOM_ID,
    CHECK_FIELD       => $CHECK_FIELD,
    USER_ID           => $FORM->{Account},
    SUM               => $FORM->{Amount},
    EXT_ID            => $FORM->{TransactionId},
    DATA              => $FORM,
    DATE              => "$main::DATE $main::TIME",
#    CURRENCY_ISO      => $self->{conf}{"PAYSYS_USMP_CURRENCY"},
    MK_LOG            => 1,
    PAYMENT_ID        => 1,
    DEBUG             => $self->{DEBUG},
    PAYMENT_DESCRIBE  => $FORM->{payment_describe} || "$CUSTOM_NAME Payments",
  });


  $RESULT_HASH{Comment} = (defined($comments_arr{$status_code})) ? $comments_arr{$status_code} : 0;
  $RESULT_HASH{ResultCode} = $status_code;
  $RESULT_HASH{TransactionExt} = $payments_id;
  $RESULT_HASH{Amount} = $FORM->{Amount} || '';

  return \%RESULT_HASH;
}

#**********************************************************
=head2 cancel()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub cancel {
  my ($self) = shift;
  my ($FORM) = @_;

  _get_request_info($FORM);

  my %RESULT_HASH = (  );

  my ($cancel_result, $canceled_id) = main::paysys_pay_cancel({
    TRANSACTION_ID => "$PAYSYSTEM_SHORT_NAME:$FORM->{RevertId}",
    RETURN_CANCELED_ID => 1
  });

  if($cancel_result == 0){
    $RESULT_HASH{ResultCode} = 0;
  }
  else{
    $RESULT_HASH{ResultCode} = 22;
  }

  $RESULT_HASH{TransactionId} = $FORM->{TransactionId};
  $RESULT_HASH{RevertId} = $FORM->{RevertId};
  $RESULT_HASH{Amount} = $FORM->{Amount};
  $RESULT_HASH{TransactionExt} = $canceled_id;

  return \%RESULT_HASH;
}
#**********************************************************
=head2 cancel()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub periodic{
  my ($self) = shift;
  my ($FORM) = @_;

  _get_request_info($FORM);
  

  my $date_from = $FORM->{CheckDateBegin} || $main::DATE;
  my $date_to   = $FORM->{CheckDateEnd}   || $main::DATE;

  $date_from =~ s/(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})/$1-$2-$3 $4:$5:$6/;
  $date_to =~ s/(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})/$1-$2-$3 $4:$5:$6/;

  my $payments_extid_list = "$PAYSYSTEM_SHORT_NAME:*";

  my $Payments = Payments->new($self->{db}, $self->{admin}, $self->{conf});
  my $payments_list = $Payments->list({
    FROM_DATE_TIME => $date_from,
    TO_DATE_TIME   => $date_to,
    DATETIME       => '_SHOW',
    SUM            => '_SHOW',
    EXT_ID         => $payments_extid_list,
    COLS_NAME      => 1,
  });

  my $results = '';
  foreach my $line (@$payments_list) {
    $results .=
      "<Payment>
<TransactionId>$line->{ext_id}</TransactionId>
<Account>$line->{uid}</Account>
<TransactionDate>$line->{datetime}</TransactionDate>
<Amount>$line->{sum}</Amount>
</Payment>\n";
  }

  chomp($results);

  my $response = qq{<?xml version="1.0" encoding="UTF-8"?>
<Response>
 $results
</Response>
};

  print "Content-Type: text/plain\n\n" if ($self->{DEBUG} > 3);
  print "Content-Type: text/xml\n\n";
  print $response;

  return $response;
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

  if(!$user->{$self->{conf}{"PAYSYS_" . $CUSTOM_NAME . "_ACCOUNT_KEY"}}){
    $user->pi();
  }
  my $link = $self->{conf}{"PAYSYS_" . $CUSTOM_NAME . "_FAST_PAY"} . "&acc=" . ($user->{$self->{conf}{"PAYSYS_" . $CUSTOM_NAME . "_ACCOUNT_KEY"}} || $attr->{$self->{conf}{"PAYSYS_" . $CUSTOM_NAME . "_ACCOUNT_KEY"}}) . "&amount=" . ($attr->{SUM} || 0);

  return $html->tpl_show(main::_include('paysys_payberry_fastpay', 'Paysys'), {LINK => $link}, { OUTPUT2RETURN => 0 });
}

#**********************************************************
=head2 has_test()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub has_test {
  my $self = shift;
  my $random = int(rand(10000));
  my ($transaction_date) = $main::DATE . $main::TIME;
  $transaction_date =~ s/-//g;
  $transaction_date =~ s/://g;
  my %params_hash = (
    '1CHECK'  => {
      Account => {
        name    => 'Account',
        val     => '',
        tooltip => "Идентификатор абонента в зависимости от настроек системы.(По умолчанию вводить UID абонента)",
      },
      QueryType => {
        name    => 'QueryType',
        val     => 'check',
        ex_params => 'readonly="readonly"',
      },
      TransactionId  => {
        name    => 'TransactionId',
        val     => $random,
        tooltip => 'Transaction ID(случайный номер)',
      },
      result  => [ '<ResultCode>0</ResultCode>' ],
    },
    '2PAY'    => {
      result  => [ '<ResultCode>0</ResultCode>' ],
      QueryType => {
        name    => 'QueryType',
        val     => 'pay',
        ex_params => 'readonly="readonly"',
      },
      Account => {
        name    => 'Account',
        val     => '',
        tooltip => "Идентификатор абонента в зависимости от настроек системы.(По умолчанию вводить UID абонента)",
      },
      TransactionDate => {
        name    => 'TransactionDate',
        val     => "$transaction_date",
        tooltip => "Дата операции",
        ex_params => 'readonly="readonly"',
      },
      TransactionId  => {
        name    => 'TransactionId',
        val     => $random,
        tooltip => 'Transaction ID(случайный номер)',
      },
      Amount  => {
        name    => 'Amount',
        val     => '1.00',
        tooltip => 'Сумма платежа',
        type    => 'number',
      },
    },
    '3CANCEL' => {
      result  => [ '<ResultCode>0</ResultCode>' ],
      QueryType => {
        name    => 'QueryType',
        val     => 'cancel',
        ex_params => 'readonly="readonly"',
      },
      RevertDate => {
        name    => 'RevertDate',
        val     => "$transaction_date",
        tooltip => "Дата операции",
        ex_params => 'readonly="readonly"',
      },
      RevertId  => {
        name    => 'RevertId',
        val     => 'Номер транзакции скопировать из ответа PAY',
        tooltip => 'Transaction ID',
      },
      TransactionId  => {
        name    => 'TransactionId',
        val     => 'Номер транзакции скопировать из ответа PAY',
        tooltip => 'Transaction ID',
      },
      Amount  => {
        name    => 'Amount',
        val     => '1.00',
        tooltip => 'Сумма платежа',
        type    => 'number',
      },
      Account => {
        name    => 'Account',
        val     => '',
        tooltip => "Идентификатор абонента в зависимости от настроек системы.(По умолчанию вводить UID абонента)",
      },
    },
  );

  return \%params_hash;
}

1;