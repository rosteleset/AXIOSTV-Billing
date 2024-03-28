package Paysys::systems::Payme;
=head1 Payme

  New module for Payme

  Documentaion: https://help.paycom.uz/ru/metody-merchant-api

  Date: 26.08.2018
  Change Date: 19.02.2020

  Version: 8.05

  ID: 5b711efbc157777e4a2b678b
  Key: zIozid@RTEHXujqfxy#@%KejJEh7&4V%SXY7
  Test key: d9mdBj8Y72ImZFn%Xv1oHaSs&&8ZhJ?68XxC

=cut

use strict;
use warnings;
use Time::Local;

use AXbills::Base qw(_bp load_pmodule encode_base64 decode_base64);
use AXbills::Misc qw();
load_pmodule('JSON');

require Paysys::Paysys_Base;
our $PAYSYSTEM_NAME = 'Payme';
our $PAYSYSTEM_SHORT_NAME = 'Payme';
our $PAYSYSTEM_ID = 131;

our $PAYSYSTEM_VERSION = '8.05';

our %PAYSYSTEM_CONF = (
  PAYSYS_PAYME_LOGIN       => '',
  PAYSYS_PAYME_PASSWD      => '',
  PAYSYS_PAYME_MERCHANT_ID => '',
  PAYSYS_PAYME_TEST_MODE   => '',
  PAYSYS_PAYME_ACCOUNT_KEY => '',
);

my ($html, $json);

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

  AXbills::Base::load_pmodule('JSON');
  $json = JSON->new->allow_nonref;

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 proccess()

  Arguments:
     -

  Returns:
s
=cut
#**********************************************************
sub proccess {
  my $self = shift;
  my ($FORM) = @_;

  print "Content-Type: text/json; charset=UTF-8\n\n";
  my $payme_request = $json->decode($FORM->{__BUFFER});
  my $CHECK_FIELD = $self->{conf}{PAYSYS_PAYME_ACCOUNT_KEY} || 'UID';

  my $method = $payme_request->{method};
  my $id = $payme_request->{id};

   if ($ENV{HTTP_CGI_AUTHORIZATION}) {
     $ENV{HTTP_CGI_AUTHORIZATION} =~ s/basic\s+//i;
     my ($REMOTE_LOGIN, $REMOTE_PASSWD) = split(/:/, main::decode_base64($ENV{HTTP_CGI_AUTHORIZATION}));
  
     if ($self->{conf}{PAYSYS_PAYME_LOGIN} ne $REMOTE_LOGIN || $self->{conf}{PAYSYS_PAYME_PASSWD} ne $REMOTE_PASSWD) {
       _error_response('-32504', 'Недостаточно привилегий для выполнения метода.', 'auth', $id);
       main::mk_log("Wrong Auth\n", { PAYSYS_ID => 'Payme' });
       return 1;
     }
   }
   else {
     _error_response('-32504', 'Недостаточно привилегий для выполнения метода.', 'auth', $id);
     main::mk_log("Wrong Auth\n", { PAYSYS_ID => 'Payme' });
     return 1;
   }

  if ($method eq 'CheckPerformTransaction') {
    my $amount = $payme_request->{params}{amount} / 100;
    my $user_id = $payme_request->{params}{account}{$CHECK_FIELD};

    if ($amount < 0
      || ($self->{conf}{PAYSYS_MIN_SUM} && $amount < $self->{conf}{PAYSYS_MIN_SUM})
      || ($self->{conf}{PAYSYS_MAX_SUM} && $amount > $self->{conf}{PAYSYS_MAX_SUM})
    ) {
      _error_response('-31001', 'Неверная сумма', 'amount', $id);
      main::mk_log("Wrong Amount\n", { PAYSYS_ID => 'Payme' });
      return 1;
    }

    my ($check_user_status) = main::paysys_check_user({
      CHECK_FIELD => $CHECK_FIELD,
      USER_ID     => $user_id
    });

    if ($check_user_status != 0) {
      _error_response('-31099', 'Пользователя не существует', 'user', $id);
      main::mk_log("User not exist\n", { PAYSYS_ID => 'Payme' });
      return 1;
    }

    _allow_trasnactions();

  }
  elsif ($method eq 'CreateTransaction') {
    my $amount = $payme_request->{params}{amount} / 100;
    my $params_id = $payme_request->{params}{id};
    my $user_id = $payme_request->{params}{account}{$CHECK_FIELD};

    if ($amount < 0
      || ($self->{conf}{PAYSYS_MIN_SUM} && $amount < $self->{conf}{PAYSYS_MIN_SUM})
      || ($self->{conf}{PAYSYS_MAX_SUM} && $amount > $self->{conf}{PAYSYS_MAX_SUM})
    ) {
      _error_response('-31001', 'Неверная сумма', 'amount', $id);
      main::mk_log("Wrong Amount\n", { PAYSYS_ID => 'Payme' });
      return 1;
    }

    my ($check_user_status) = main::paysys_check_user({
      CHECK_FIELD => $CHECK_FIELD,
      USER_ID     => $user_id
    });

    if ($check_user_status != 0) {
      _error_response('-31099', 'Пользователя не существует', 'user', $id);
      main::mk_log("User not exist\n", { PAYSYS_ID => 'Payme' });
      return 1;
    }

    my ($paysys_id, $check_status) = main::paysys_pay_check({
      TRANSACTION_ID => "$PAYSYSTEM_SHORT_NAME:$params_id",
    });

    if ($paysys_id) {
      my $tmp = main::paysys_get_full_info({
        TRANSACTION_ID => "$PAYSYSTEM_SHORT_NAME:$params_id",
      });
      my $create_time = convert_to_timestamp($tmp->{datetime});
      _success_create_transaction_response($paysys_id, $check_status, $create_time * 1000);

      return 1;
    }
    elsif ($check_status && $check_status == 2) {
      _error_response("-31060", 'Оплата уже произведена', 'exist', $id);
    }

    ($check_status, $paysys_id) = main::paysys_pay({
      PAYMENT_SYSTEM    => $PAYSYSTEM_SHORT_NAME,
      PAYMENT_SYSTEM_ID => $PAYSYSTEM_ID,
      CHECK_FIELD       => $CHECK_FIELD || 'UID',
      USER_ID           => $user_id,
      SUM               => $amount,
      EXT_ID            => $params_id,
      DATA              => { DATA => $FORM->{__BUFFER} },
      DATE              => "$main::DATE $main::TIME",
      MK_LOG            => 1,
      PAYMENT_ID        => $PAYSYSTEM_ID,
      ERROR             => 1,
      DEBUG             => $self->{DEBUG},
      PAYMENT_DESCRIBE  => $FORM->{payment_describe} || 'Payme Payments',
    });

    if ($check_status == 1 && $paysys_id) {
      my $tmp = main::paysys_get_full_info({
        TRANSACTION_ID => "$PAYSYSTEM_SHORT_NAME:$params_id",
      });
      my $create_time = convert_to_timestamp($tmp->{datetime});
      _success_create_transaction_response($paysys_id, $check_status, $create_time * 1000);
    }

  }
  elsif ($method eq 'PerformTransaction') {
    my $params_id = $payme_request->{params}{id};
    my $params_transaction_id = $payme_request->{id};

    my ($pay_status, $paysys_id) = main::paysys_pay({
      PAYMENT_SYSTEM    => $PAYSYSTEM_SHORT_NAME,
      PAYMENT_SYSTEM_ID => $PAYSYSTEM_ID,
      #      CHECK_FIELD       => $self->{conf}{PAYSYS_EPAY_ACCOUNT_KEY} || 'UID',
      #      USER_ID           => $uid,
      #      SUM               => $amount,
      EXT_ID            => $params_id,
      ORDER_ID          => "$PAYSYSTEM_SHORT_NAME:$params_id",
      DATA              => { DATA => $FORM->{__BUFFER} },
      DATE              => "$main::DATE $main::TIME",
      MK_LOG            => 1,
      PAYMENT_ID        => 1,
      DEBUG             => $self->{DEBUG},
      PAYMENT_DESCRIBE  => $FORM->{payment_describe} || 'Payme Payments',
    });

    if ($pay_status == 0 || $pay_status == 9) {
      my $tmp = main::paysys_get_full_info({
        TRANSACTION_ID => "$PAYSYSTEM_SHORT_NAME:$params_id",
      });

      my $now_time = convert_to_timestamp($tmp->{datetime});
      _success_perform_transaction_response($paysys_id, 2, $now_time * 1000 + 2000, $params_transaction_id);
    }
  }
  elsif ($method eq 'CancelTransaction') {
    my $params_id = $payme_request->{params}{id};

    my ($paysys_check_id, $check_status) = main::paysys_pay_check({
      TRANSACTION_ID => "$PAYSYSTEM_SHORT_NAME:$params_id",
    });

    my $tmp = main::paysys_get_full_info({
      TRANSACTION_ID => "$PAYSYSTEM_SHORT_NAME:$params_id",
    });

    if ($paysys_check_id && $check_status && $check_status == 3) {
      my $create_time = convert_to_timestamp($tmp->{datetime});
      _success_cancel_transaction_responce($paysys_check_id, '-2', $create_time * 1000 + 10000);

      return 1;
    }
    elsif ($paysys_check_id && $check_status && $check_status == 1) {
      my ($cancel_result, $paysys_cancel_id) = main::paysys_pay_cancel({
        TRANSACTION_ID     => "$PAYSYSTEM_SHORT_NAME:$params_id",
        RETURN_CANCELED_ID => 1,
        CANCEL_STATUS      => 15,
      });

      my $create_time = convert_to_timestamp($tmp->{datetime});
      _success_cancel_transaction_responce($paysys_cancel_id, ($cancel_result == 10 ? '-1' : $cancel_result), $create_time * 1000 + 10000);

      return 1;
    }
    elsif ($paysys_check_id && $check_status && $check_status == 15) {
      my $create_time = convert_to_timestamp($tmp->{datetime});
      _success_cancel_transaction_responce($paysys_check_id, '-1', $create_time * 1000 + 10000);

      return 1;
    }
    else {
      my ($cancel_result, $paysys_cancel_id) = main::paysys_pay_cancel({
        TRANSACTION_ID     => "$PAYSYSTEM_SHORT_NAME:$params_id",
        RETURN_CANCELED_ID => 1,
      });

      my $create_time = convert_to_timestamp($tmp->{datetime});
      _success_cancel_transaction_responce($paysys_cancel_id, ($cancel_result == 10 ? '-2' : $cancel_result), $create_time * 1000 + 10000);

      return 1;
    }
  }
  elsif ($method eq 'CheckTransaction') {
    my $params_id = $payme_request->{params}{id};
    my ($paysys_id, $check_status) = main::paysys_pay_check({
      TRANSACTION_ID => "$PAYSYSTEM_SHORT_NAME:$params_id",
    });

    if ($paysys_id) {
      my $tmp = main::paysys_get_full_info({
        TRANSACTION_ID => "$PAYSYSTEM_SHORT_NAME:$params_id",
      });
      my $create_time = convert_to_timestamp($tmp->{datetime});

      my $create_timestamp = $create_time * 1000;
      my $perform_timestamp = 0;
      my $cancel_timestamp = 0;
      my $reason = 'null';

      if ($check_status == 2) {
        $perform_timestamp = $create_time * 1000 + 2000;
      }
      elsif ($check_status == 3) {
        $cancel_timestamp = $create_time * 1000 + 10000;
        $perform_timestamp = $create_time * 1000 + 2000;
        $check_status = -2;
        $reason = 5;
      }
      elsif ($check_status == 15) {
        $cancel_timestamp = $create_time * 1000 + 10000;
        $check_status = -1;
        $reason = 3;
      }

      _success_check_transaction_response($create_timestamp, $perform_timestamp, $cancel_timestamp, $paysys_id, $check_status, $reason, $id);
      return 1;
    }
    elsif ($check_status && $check_status == 2) {
      _error_response("-31003", 'Транзакция не найдена', 'transaction not exist', $id);
    }
  }
  elsif ($method eq 'GetStatement') {
    my $from_date = POSIX::strftime("%Y-%m-%d", localtime(substr($payme_request->{params}->{from}, 0, 10)));
    my $to_date = POSIX::strftime("%Y-%m-%d", localtime(substr($payme_request->{params}->{to}, 0, 10)));

    $from_date = '2019-08-19';
    $to_date = '2019-12-31';

    my $paysys_from_to_data = main::paysys_payment_list({
      PAYMENT_SYSTEM => $PAYSYSTEM_ID,
      FROM_DATE      => $from_date,
      TO_DATE        => $to_date,
    });

    my @arr_answer = ();
    foreach my $iter (@$paysys_from_to_data) {
      my $answer = {
        id           => $iter->{id},
        time         => $iter->{datetime},
        amount       => $iter->{sum},
        create_time  => $iter->{datetime},
        perform_time => $iter->{datetime},
        cancel_time  => $iter->{datetime},
        transaction  => $iter->{transaction_id},
        state        => $iter->{status}
      };
      push @arr_answer, $answer;
    }

    my $result = JSON::encode_json(\@arr_answer);

    print qq[
    {
      "result":{
      "transaction":
        $result,
        "id":"$id"
    }
    }
    ];
    return 1;
  }
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
=head2 _error_response()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub _error_response {
  my ($code, $message, $data, $id) = @_;

  print qq[ {"error" : {"code" : $code,"message" : "$message","data" : "$data"},"id" : $id } ];
  return 1;
}


#**********************************************************
=head2 _success_response()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub _success_create_transaction_response {
  my ($paysys_id, $status, $timestamp) = @_;

  print qq[ {"result" : { "create_time" : $timestamp, "transaction" : "$paysys_id", "state" : $status } } ];

  return 1;
}

#**********************************************************
=head2 _success_perform_transaction_response()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub _success_perform_transaction_response {
  my ($paysys_id, $status, $timestamp, $merchant_id) = @_;
  print qq[
{
    "result" : {
        "id" : $merchant_id,
        "perform_time" : $timestamp,
        "transaction" : "$paysys_id",
        "state" : $status
    }
}
];

  return 1;
}

#**********************************************************
=head2 _success_cancel_transaction_responce()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub _success_cancel_transaction_responce {
  my ($paysys_id, $status, $timestamp) = @_;

  print qq[{ "result" : { "cancel_time" : $timestamp,"transaction" : "$paysys_id","state" : $status}}];

  return 1;
}

#**********************************************************
=head2 _allow_trasnactions()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub _allow_trasnactions {
  print qq[{
    "result" : {
        "allow" : true
    }
}];
  return 1;
}

#**********************************************************
=head2 _success_check_transaction_response()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub _success_check_transaction_response {
  my ($create_time, $perform_time, $cancel_time, $transaction_id, $state, $reason, $id) = @_;
  print qq/{ "result" : {"create_time" : $create_time,"perform_time" : $perform_time,"cancel_time" : $cancel_time,"transaction" : "$transaction_id","state" : $state, "reason" : $reason}, "id" : $id }/;

  return 1;
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
  my $CHECK_FIELD = $self->{conf}{PAYSYS_PAYME_ACCOUNT_KEY} || 'UID';

  my $form_url = 'https://checkout.paycom.uz';
    if ($self->{conf}{PAYSYS_PAYME_TEST_MODE}) {
     $form_url = 'https://test.paycom.uz';
    }
 
  return $html->tpl_show(main::_include('paysys_payme_add', 'Paysys'), {
    MERCHANT_ID    => $self->{conf}{PAYSYS_PAYME_MERCHANT_ID},
    CHECK_FIELD    => $CHECK_FIELD,
    USER_ID        => $user->{$CHECK_FIELD},
    AMOUNT         => $attr->{SUM} * 100,
    DESCRIBE       => $attr->{DESCRIBE},
    TRANSACTION_ID => $attr->{OPERATION_ID},
    URL            => $form_url,
   }, { OUTPUT2RETURN => 0 });
 }
#**********************************************************
=head2 convert_to_timestamp()

  Arguments:
     $time - Date to unix time (timestamp)

  Returns:
    $now_time - Unix date (timestamp)

=cut
#**********************************************************
sub convert_to_timestamp {
  my ($time) = @_;

  return 0 if (!$time);

  my ($year, $month, $day, $hours, $minutes, $seconds) = split(/[\s\-\:]+/, $time);
  my $now_time = Time::Local::timelocal(int($seconds), int($minutes), int($hours), int($day), int($month - 1), int($year));

  return $now_time;
}

1;
