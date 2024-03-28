=head1 Paysys_Base

  Paysys_Base - module for payments

=head1 SYNOPSIS

  paysys_load('Paysys_Base');

=cut

use strict;
use warnings FATAL => 'all';

use AXbills::Filters;
use AXbills::Base qw(sendmail convert in_array is_number);
use Finance;
use Users;
use Paysys;
use Encode;
use AXbills::Fetcher qw(web_request);
require AXbills::Misc;

our (
  $admin,
  $db,
  %conf,
  %PAYSYS_PAYMENTS_METHODS,
  %lang,
  $html,
  $base_dir,
  $TIME,
  $DATE,
  %FORM,
  %LIST_PARAMS,
  $index
);

my $payments = Finance->payments($db, $admin, \%conf);
my $Paysys = Paysys->new($db, $admin, \%conf);
our Users $users;

my $insert_id = 0;
my $paysys_id = 0;

my @status = ("$lang{UNKNOWN}",    #0
  "$lang{TRANSACTION_PROCESSING}", #1
  "$lang{COMPLETE}",               #2
  "$lang{CANCELED}",               #3
  "$lang{EXPIRED}",                #4
  $lang{ERR_INCORRECT_CHECKSUM},   #5
  "$lang{PAYMENT_ERROR}",          #6
  "$lang{DUPLICATE}",              #7
  "$lang{USER_ERROR}",             #8
  "$lang{USER_NOT_EXIST}",         #9
  "$lang{SMALL_PAYMENT_SUM}",      #10
  'SQL_ERROR',                     #11
  'TEST',                          #12
  'WAIT',                          #13
  'REJECT',                        #14
  'UNPAID',                        #15
  'WRONG_SUM',                     #16
  'PAYMENT_SQL_ERROR',             #17
);

#**********************************************************
=head2 paysys_pay() - make payment;

  Arguments:
    $attr
      DEBUG                   - Level of debugging;
      EXT_ID                  - External unique identifier of payment;
      CHECK_FIELD             - Synchronization field for subscriber;
      USER_ID                 - Identifier for subscriber;
      PAYMENT_SYSTEM          - Short name of payment system;
      PAYMENT_SYSTEM_ID       - ID of payment system;
      CURRENCY                - The exchange rate for the payment of the system;
      CURRENCY_ISO            -
      SUM                     - Payment amount;
      DATA                    - HASH_REF Transaction information field;
      ORDER_ID                - Transaction identifier in ABillS;
      MK_LOG                  - Logging;
      REGISTRATION_ONLY       - Add payment info without real payment
      PAYMENT_DESCRIBE        - Description of payment;
      PAYMENT_INNER_DESCRIBE  - Inner description of payment;
      PAYMENT_ID        - if this attribute is on(1), function will return two values:
                                    $status_code - status code;
                                    $payments_id - transaction identifier in ABillS;
      USER_INFO         - Additional information;
      CROSSMODULES_TIMEOUT - Crossmodules function timeout
      ERROR             - Status error;
      PAYMENT_METHOD    - Payment method;
  Returns:
    Payment status code.
    All codes:
      0   Operation was successfully completed
      1   User not present in the system
      2   The error in the database
      3   Such a payment already exists in the system, it is not present in the list of payments or the list of transactions
      5   Improper payment amount. It arises in systems with a tandem payment if the user starts a transaction with one amount but in the process of changing the amount of the transaction
      6   Too small amount
      7   The amount of the payment more than permitted
      8   The transaction is not found (Paysys list not found)
      9   Payments already exists
      10  This payment is not found in the system
      11  For this group of users not allowed to use external payment (Paysys)
      12  An unknown SQL error payment, happens when deadlock
      13  Error logging external payments (Paysys list exist transaction)
      14  User without bill account
      15  Transaction created and unpaid and canceled
      17  SQL when conducting payment
      28  Wrong exchange
      35  Wrong signature
      40  Duplicate identifier


  Examples:
    my $result_code = paysys_pay({
        PAYMENT_SYSTEM    => OP,
        PAYMENT_SYSTEM_ID => 100,
        CHECK_FIELD       => UID,
        USER_ID           => 1,
        SUM               => 50.00,
        EXT_ID            => 11111111,
        DATA              => \%FORM,
        CURRENCY          => $conf{PAYSYS_PAYNET_CURRENCY},
        PAYMENT_DESCRIBE  => 'Payment with paysystem Oplata'
        PAYMENT_ID        => 1,
        MK_LOG            => 1,
        DEBUG             => 7
    });
    $result_code - payment status code.

    my ($result_code, $payments_id ) = paysys_pay({
    PAYMENT_SYSTEM    => $payment_system,
    PAYMENT_SYSTEM_ID => $payment_system_id,
    CHECK_FIELD       => $CHECK_FIELD,
    USER_ID           => $request_params{customer_id},
    SUM               => $request_params{sum},
    EXT_ID            => $request_params{transaction_id},
    DATA              => \%request_params,
    CURRENCY          => $conf{PAYSYS_PAYNET_CURRENCY},
    MK_LOG            => 1,
    PAYMENT_ID        => 1,
    DEBUG             => $debug
    });

    Payment by ORDER_ID (without check field) Example from Lifecell:
      Most be ORDER_ID and EXT_ID.
     my $status_code = main::paysys_pay({
      PAYMENT_SYSTEM    => $PAYSYSTEM_SHORT_NAME,
      PAYMENT_SYSTEM_ID => $PAYSYSTEM_ID,
      SUM               => $FORM->{sum},
      ORDER_ID          => "$PAYSYSTEM_SHORT_NAME:$order_id",
      EXT_ID            => "$order_id",
      DATA              => $FORM,
      DATE              => "$date $time",
      MK_LOG            => 1,
      DEBUG             => $self->{DEBUG},
      PAYMENT_DESCRIBE  => $FORM->{desc} || "$PAYSYSTEM_NAME payment",
    });

=cut
#**********************************************************
sub paysys_pay {
  my ($attr) = @_;

  my $debug = $attr->{DEBUG} || 0;
  my $ext_id = $attr->{EXT_ID} || '';
  my $CHECK_FIELD = $attr->{CHECK_FIELD} || 'UID';
  my $user_account = $attr->{USER_ID};
  my $payment_system = $attr->{PAYMENT_SYSTEM};
  my $payment_system_id = $attr->{PAYMENT_SYSTEM_ID};
  my $amount = $attr->{SUM};
  my $order_id = $attr->{ORDER_ID};
  $users = $attr->{USER_INFO} if ($attr->{USER_INFO});

  my $domain;
  if (defined $ENV{DOMAIN_ID}) {
    $domain = { DOMAIN_ID => $ENV{DOMAIN_ID} || 0 };
  }

  my $status = 0;
  my $payments_id = 0;
  my $uid = 0;
  $paysys_id = 0;
  my $ext_info = '';

  $user_account = _expr($user_account, $conf{PAYSYS_ACCOUNT_EXPR});

  if ($attr->{DATA}) {
    foreach my $k (sort keys %{$attr->{DATA}}) {
      if ($k eq '__BUFFER') {
        next;
      }
      # print "// $k, $attr->{DATA}->{$k} //\n";
      Encode::_utf8_off($attr->{DATA}->{$k});
      $ext_info .= "$k, $attr->{DATA}->{$k}\n" if($attr->{DATA}->{$k});
    }

    if ($attr->{MK_LOG}) {
      mk_log($ext_info, { PAYSYS_ID => "$payment_system/$payment_system_id", REQUEST => 'Request' });
    }
  }

  #Wrong sum
  if ($amount && $amount <= 0) {
    return 5;
  }
  #Small sum
  elsif ($attr->{MIN_SUM} && $amount < $attr->{MIN_SUM}) {
    return 6;
  }
  # large sum
  elsif ($attr->{MAX_SUM} && $amount > $attr->{MAX_SUM}) {
    return 7;
  }
  elsif ($ext_id eq 'no_ext_id') {
    return 29;
  }

  if ($debug > 6) {
    $users->{debug} = 1;
    $Paysys->{debug} = 1;
    $payments->{debug} = 1;
  }

  #Get transaction info
  if ($order_id || $attr->{PAYSYS_ID}) {
    print "Order: " . ($order_id || $attr->{PAYSYS_ID}) if ($debug > 1);

    my $list = $Paysys->list({
      TRANSACTION_ID => $order_id || '_SHOW',
      ID             => $attr->{PAYSYS_ID} || undef,
      DATETIME       => '_SHOW',
      STATUS         => '_SHOW',
      SUM            => '_SHOW',
      COLS_NAME      => 1,
      DOMAIN_ID      => '_SHOW',
      SKIP_DEL_CHECK => 1
    });

    # if transaction not exist
    if ($Paysys->{errno} || $Paysys->{TOTAL} < 1) {
      $status = 8;
      return $status;
    }
    #If transaction success
    elsif ($list->[0]->{status} == 2) {
      $status = 9;
      return $status, $list->[0]->{id}; # added ID for second param return 08.02.2017
    }

    if (!$order_id) {
      (undef, $ext_id) = split(/:/, $list->[0]->{transaction_id});
    }

    $uid        = $list->[0]->{uid};
    $paysys_id  = $list->[0]->{id};

    if (!$attr->{NEW_SUM}) {
      $amount = $list->[0]->{sum};
    }

    if ($amount && $list->[0]->{sum} != $amount && !$attr->{NEW_SUM}) {
      $attr->{ERROR} = 16;
      $status = 5;
    }

    #Register success payments
    if ($attr->{REGISTRATION_ONLY}) {
      if (!$attr->{ERROR}) {
        $Paysys->change({
          ID        => $paysys_id,
          STATUS    => 2,
          PAYSYS_IP => $ENV{'REMOTE_ADDR'},
          INFO      => $ext_info,
          USER_INFO => $attr->{USER_INFO} || ''
        });
        return 0;
      }
    }
  }
  else {
    if ($conf{PAYSYS_ACCOUNT_KEY}) { #FIXME Do we really use it?
      $CHECK_FIELD = _account_expression($user_account);
    }

    my $list = _paysys_extra_check_user({
      MAIN_CHECK_FIELD => $CHECK_FIELD,
      USER_ACCOUNT     => $user_account || '---',
      EXTRA_USER_IDS   => $attr->{EXTRA_USER_IDS} || [],
    });

    #TODO CHECK FOR 40 error status $users->{TOTAL} > 1
    if ($users->{errno} || $users->{TOTAL} < 1) {
      if ($conf{SECOND_BILLING_OUT} && !(defined($conf{SECOND_BILLING_OUT_GROUPS}))) {
        return paysys_pay_second_bill({
          USER_ACCOUNT => $user_account,
          SUM          => $amount,
          EXT_ID       => $ext_id,
          PAYMENT_ID   => $attr->{PAYMENT_ID} || 0
        });
      }
      else {
        return 1;
      }
    }

    if ($list->[0]->{disable_paysys} && $conf{SECOND_BILLING_DISABLE_PAYSYS}) {
      if ($list->[0]->{disable_paysys}) {
        return 11;
      }
    }

    if ($conf{SECOND_BILLING_OUT_GROUPS} && $list->[0]->{gid}) {
      my @groups = split(', ', $conf{SECOND_BILLING_OUT_GROUPS});
      foreach my $group (@groups) {
        next if ($list->[0]->{gid} != $group);
        return paysys_pay_second_bill({
          USER_ACCOUNT => $user_account,
          SUM          => $amount,
          EXT_ID       => $ext_id,
          PAYMENT_ID   => $attr->{PAYMENT_ID} || 0
        });
      }
    }

    #disable paysys
    if ($list->[0]->{disable_paysys}) {
      return 11;
    }

    $uid = $list->[0]->{uid};
  }

  # For skip license check if payment
  my $user = $users->info($uid, { USERS_AUTH => 1, %{$domain // {}} });

  # delete param for cross modules
  delete $user->{PAYMENTS_ADDED};

  #Error
  if ($attr->{ERROR}) {
    my $error_code = ($attr->{ERROR} == 35) ? 5 : $attr->{ERROR};

    if ($paysys_id) {
      $Paysys->change({
        ID        => $paysys_id,
        STATUS    => $error_code,
        PAYSYS_IP => $ENV{'REMOTE_ADDR'},
        INFO      => $ext_info,
        USER_INFO => $attr->{USER_INFO}
      });
    }
    else {
      $Paysys->add({
        SYSTEM_ID      => $payment_system_id,
        DATETIME       => $attr->{DATE} || "$DATE $TIME",
        SUM            => ($attr->{COMMISSION} && $attr->{SUM}) ? $attr->{SUM} : $amount,
        UID            => $uid,
        IP             => $attr->{IP},
        TRANSACTION_ID => "$payment_system:$ext_id",
        INFO           => $ext_info,
        USER_INFO      => $attr->{USER_INFO},
        PAYSYS_IP      => $ENV{'REMOTE_ADDR'},
        STATUS         => $error_code,
        %{$domain || {}}
      });

      $paysys_id = $Paysys->{errno} ? '' : $Paysys->{INSERT_ID};
    }

    if ($attr->{PAYMENT_ID}) {
      return $error_code, $paysys_id;
    }

    return $error_code;
  }

  my $er = '';
  my $currency = 0;

  #Exchange radte
  my $PAYMENT_SUM = 0;
  if ($attr->{CURRENCY} || $attr->{CURRENCY_ISO}) {
    $payments->exchange_info(0, {
      SHORT_NAME => $attr->{CURRENCY},
      ISO        => $attr->{CURRENCY_ISO} });
    if ($payments->{errno} && $payments->{errno} != 2) {
      return 28;
    }
    elsif ($payments->{TOTAL} > 0) {
      $er = $payments->{ER_RATE};
      $currency = $payments->{ISO};
    }
    if ($er && $er != 1) {
      $PAYMENT_SUM = sprintf("%.2f", $amount / $er);
    }
  }
  my $system_info = $Paysys->paysys_connect_system_list({
    PAYSYS_ID      => $payment_system_id,
    PAYMENT_METHOD => '_SHOW',
    COLS_NAME      => 1,
  });

  my $method = $attr->{PAYMENT_METHOD} || $system_info->[0]{payment_method} || 0;

  #TODO: delete first if condition after half year
  if (!$attr->{PAYMENT_METHOD} && $Paysys->can('gid_params')) {
    my $params = $Paysys->gid_params({
      GID       => $user->{GID},
      PAYSYS_ID => $payment_system_id,
      LIST2HASH => 'param,value'
    });

    if (scalar keys %{$params}) {
      my ($payment_method) = grep {/PAYMENT_METHOD/g} keys %{$params};
      $method = $params->{$payment_method} if ($payment_method && $params->{$payment_method});
    }
  }

  #Sucsess
  if (!$conf{PAYMENTS_POOL}) {
    my @params = ('pre_payment', {
      USER_INFO    => $user,
      SKIP_MODULES => 'Sqlcmd, Cards',
      SILENT       => 1,
      SUM          => $PAYMENT_SUM || $amount,
      AMOUNT       => $amount || $PAYMENT_SUM,
      EXT_ID       => "$payment_system:$ext_id",
      METHOD       => $method || (($conf{PAYSYS_PAYMENTS_METHODS} && $PAYSYS_PAYMENTS_METHODS{$payment_system_id}) ? $payment_system_id : '2'),
      timeout      => $attr->{CROSSMODULES_TIMEOUT} || $conf{PAYSYS_CROSSMODULES_TIMEOUT} || 4,
      FORM         => \%FORM,
    });

    if ($attr->{API}) {
      ::cross_modules(@params);
    }
    else {
      cross_modules(@params);
    }
  }

  $payments->add($user, {
    SUM            => $amount,
    DATE           => $attr->{DATE},
    DESCRIBE       => $attr->{PAYMENT_DESCRIBE} || $payment_system,
    INNER_DESCRIBE => $attr->{PAYMENT_INNER_DESCRIBE} || '',
    METHOD         => $method || (($conf{PAYSYS_PAYMENTS_METHODS} && $PAYSYS_PAYMENTS_METHODS{$payment_system_id}) ? $payment_system_id : '2'),
    EXT_ID         => "$payment_system:$ext_id",
    CHECK_EXT_ID   => "$payment_system:$ext_id",
    ER             => $er,
    CURRENCY       => $currency,
    USER_INFO      => $attr->{USER_INFO}
  });

  #Exists payments Dublicate
  if ($payments->{errno} && $payments->{errno} == 7) {
    my $list = $Paysys->list({ TRANSACTION_ID => "$payment_system:$ext_id", STATUS => '_SHOW', COLS_NAME => 1 });
    $payments_id = $payments->{ID};

    # paysys list not exist
    if ($Paysys->{TOTAL} == 0) {
      $Paysys->add({
        SYSTEM_ID      => $payment_system_id,
        DATETIME       => $attr->{DATE} || "$DATE $TIME",
        SUM            => ($attr->{COMMISSION} && $attr->{SUM}) ? $attr->{SUM} : ($PAYMENT_SUM || $amount),
        UID            => $uid,
        TRANSACTION_ID => "$payment_system:$ext_id",
        INFO           => $ext_info,
        PAYSYS_IP      => $ENV{'REMOTE_ADDR'},
        STATUS         => 2,
        USER_INFO      => $attr->{USER_INFO},
        %{$domain || {}}
      });

      $paysys_id = $Paysys->{INSERT_ID};

      if (!$Paysys->{errno}) {
        my @params = ('payments_maked', {
          USER_INFO    => $user,
          PAYMENT_ID   => $payments_id,
          SUM          => $PAYMENT_SUM || $amount,
          AMOUNT       => $amount || $PAYMENT_SUM,
          SILENT       => 1,
          QUITE        => 1,
          timeout      => $attr->{CROSSMODULES_TIMEOUT} || $conf{PAYSYS_CROSSMODULES_TIMEOUT} || 4,
          SKIP_MODULES => 'Cards',
          FORM         => \%FORM
        });
        if ($attr->{API}) {
          ::cross_modules(@params);
        }
        else {
          cross_modules(@params);
        }

        _paysys_execute_external_command($user);
      }

      $status = 3;
    }
    else {
      $paysys_id = $list->[0]->{id};

      if ($paysys_id && $list->[0]->{status} != 2) {
        if ($attr->{NEW_SUM}) {
          $Paysys->change({
            ID        => $paysys_id,
            STATUS    => 2,
            PAYSYS_IP => $ENV{'REMOTE_ADDR'},
            INFO      => $ext_info,
            USER_INFO => $attr->{USER_INFO},
            SUM       => $amount
          });
        }
        else {
          $Paysys->change({
            ID        => $paysys_id,
            STATUS    => 2,
            PAYSYS_IP => $ENV{'REMOTE_ADDR'},
            INFO      => $ext_info,
            USER_INFO => $attr->{USER_INFO}
          });
        }
      }

      $status = 13;
    }
  }
  #Payments error
  elsif ($payments->{errno}) {
    if ($debug > 3) {
      print "Payment Error: [$payments->{errno}] $payments->{errstr}\n";
    }

    if ($payments->{errno} == 14) {
      $status = 14;
    }
    else {
      # happens if deadlock
      $status = 12;
    }
  }
  else {
    if ($paysys_id) {
      if ($attr->{NEW_SUM}) {
        $Paysys->change({
          ID        => $paysys_id,
          STATUS    => 2,
          PAYSYS_IP => $ENV{'REMOTE_ADDR'},
          INFO      => $ext_info,
          USER_INFO => $attr->{USER_INFO},
          SUM       => $amount
        });
      }
      else {
        $Paysys->change({
          ID        => $paysys_id,
          STATUS    => 2,
          PAYSYS_IP => $ENV{'REMOTE_ADDR'},
          INFO      => $ext_info,
          USER_INFO => $attr->{USER_INFO}
        });
      }
    }
    else {
      $Paysys->add({
        SYSTEM_ID      => $payment_system_id,
        DATETIME       => $attr->{DATE} || "$DATE $TIME",
        SUM            => ($attr->{COMMISSION} && $attr->{SUM}) ? $attr->{SUM} : $amount,
        UID            => $uid,
        TRANSACTION_ID => "$payment_system:$ext_id",
        INFO           => $ext_info,
        PAYSYS_IP      => $ENV{'REMOTE_ADDR'},
        STATUS         => 2,
        USER_INFO      => $attr->{USER_INFO},
        %{$domain || {}}
      });

      $paysys_id = $Paysys->{INSERT_ID};
    }

    if (!$Paysys->{errno}) {
      if ($conf{PAYMENTS_POOL}) {
        $payments->pool_add({ PAYMENT_ID => $payments->{PAYMENT_ID} });
      }
      else {
        my %crossmodules_params = (
          USER_INFO  => $user,
          PAYMENT_ID => $payments->{PAYMENT_ID},
          SUM        => $amount,
          SILENT     => 1,
          QUITE      => 1,
          timeout    => $attr->{CROSSMODULES_TIMEOUT} || $conf{PAYSYS_CROSSMODULES_TIMEOUT} || 4,
        );

        if ($debug > 5) {
          delete $crossmodules_params{SILENT};
          delete $crossmodules_params{crossmodules_params};
          $crossmodules_params{DEBUG} = 1;
        }

        if ($attr->{API}) {
          ::cross_modules('payments_maked', \%crossmodules_params);
        }
        else {
          cross_modules('payments_maked', \%crossmodules_params);
        }

        _paysys_execute_external_command($user);
      }
    }
    #Transactions registration error
    else {
      if ($Paysys->{errno} && $Paysys->{errno} == 7) {
        $status = 3;
        $payments_id = $payments->{ID};
      }
      #Payments error
      elsif ($Paysys->{errno}) {
        $status = 2;
      }
    }
  }

  #Send mail
  if ($conf{PAYSYS_EMAIL_NOTICE}) {
    my $message = "\n" . "================================\n" .
      "Платёжная система: $attr->{PAYMENT_DESCRIBE}\n" .
      "================================\n\n" .
      "Дата: $DATE $TIME\n" .
      "Абонент: $user->{LOGIN} [$uid]\n" .
      "Сумма: $amount р.\n\n" .
      "Номер транзакции: $payment_system:$ext_id \n\n" .
      "================================\n" . $ext_info . "\n\n";

    sendmail("$conf{ADMIN_MAIL}", "$conf{ADMIN_MAIL}", "Пополнение счёта через $attr->{PAYMENT_DESCRIBE}", "$message", "$conf{MAIL_CHARSET}", "2 (High)");
  }

  if ($conf{SECOND_BILLING_SYNC}) {
    if ($conf{SECOND_BILLING_SYNC_GROUPS}) {
      my @groups = split(', ', $conf{SECOND_BILLING_SYNC_GROUPS});
      foreach my $group (@groups) {
        last if (!$user->{GID});
        next if ($user->{GID} != $group);

        paysys_pay_second_bill({
          USER_ACCOUNT => ($user_account || ($user->{$conf{SECOND_BILLING_SYNC_KEY}} || $user->{UID})),
          SUM          => $amount,
          EXT_ID       => $ext_id,
          PAYMENT_ID   => $attr->{PAYMENT_ID} || 0
        });
      }
    }
    else {
      paysys_pay_second_bill({
        USER_ACCOUNT => $user_account,
        SUM          => $amount,
        EXT_ID       => $ext_id,
        PAYMENT_ID   => $attr->{PAYMENT_ID} || 0
      });
    }
  }

  if ($conf{PAYSYS_EXTERN_SYNC}) {
    my $message = "\n" . "============Receive amount====================\n" .
      "LOGIN:       $user->{LOGIN} [UID: $uid]\n" .
      "DATE:        $DATE $TIME\n" .
      "SUM:         $amount \n" .
      "SYSTEM_NAME: $payment_system  \n" .
      "TRANSACTION_ID: $payment_system:$ext_id \n" .
      "DESCRIBE: $attr->{PAYMENT_DESCRIBE} \n\n" .
      "============Request Parameters===============\n" .
      $ext_info . "\n\n" .

      "================================";

    sendmail("$conf{ADMIN_MAIL}", "$conf{ADMIN_MAIL}", "$payment_system ADD", "$message", "$conf{MAIL_CHARSET}", "2 (High)");
  }

  if ($attr->{PAYMENT_ID}) {
    return $status, $paysys_id;
  }

  return $status;
}

#**********************************************************
=head2 paysys_check_user() - check user in system;

  Arguments:
    $attr
      CHECK_FIELD     - Searching field for user;
      USER_ID         - User identifier for CHECK_FIELD;
      EXTRA_FIELDS    - Extra fields
      DEBUG           - Debug mode
      SKIP_FIO_HIDE   - Skip hide fio
      RECOMENDED_PAY  - Returns total sum

  Returns:
    $result, $user_info

    $result - result code;
    $user_info - users information fields.

    Checking code.
    All codes:
      0  - User exist;
      1  - User not exist;
      2  - SQL error;
      11 - Disable paysys for group
      14 - No bill_id
      30 - Not filled user identifier in request

  Examples:
    my ($result, $list) = paysys_check_user({
     CHECK_FIELD => 'UID',
     USER_ID     => 1
    });

=cut
#**********************************************************
sub paysys_check_user {
  my ($attr) = @_;
  my $result = 0;

  my $CHECK_FIELD = $attr->{CHECK_FIELD} || 'UID';
  my $user_account = $attr->{USER_ID} || q{};

  $user_account =~ s/\*//;

  if ($conf{PAYSYS_ACCOUNT_KEY}) {
    $CHECK_FIELD = _account_expression($user_account);
  }

  $user_account = _expr($user_account, $conf{PAYSYS_ACCOUNT_EXPR});

  if (!$user_account) {
    return 30;
  }

  if ($attr->{DEBUG} && $attr->{DEBUG} > 6) {
    $users->{debug} = 1;
  }

  my $list = _paysys_extra_check_user({
    %$attr,
    USER_ACCOUNT     => $user_account,
    MAIN_CHECK_FIELD => $CHECK_FIELD,
    EXTRA_USER_IDS   => $attr->{EXTRA_USER_IDS} || [],
    COLS_UPPER       => 1
  });

  if ($users->{errno}) {
    return 2;
  }
  elsif ($users->{TOTAL} < 1) {
    if ($conf{SECOND_BILLING_OUT} && !(defined($conf{SECOND_BILLING_OUT_GROUPS}))) {
      return paysys_check_user_second_bill({USER_ACCOUNT => $user_account});
    }
    else {
      return 1;
    }
  }
  elsif ($conf{SECOND_BILLING_OUT_GROUPS} && $list->[0]->{GID}) {
    my @groups = split(', ', $conf{SECOND_BILLING_OUT_GROUPS});
    foreach my $group (@groups) {
      next if ($list->[0]->{GID} != $group);
      return paysys_check_user_second_bill({ USER_ACCOUNT => $user_account });
    }
  }
  elsif ($list->[0]->{DISABLE_PAYSYS}) {
    return 11;
  }
  elsif (!$list->[0]->{BILL_ID}) {
    return 14;
  }

  if ($list->[0]->{domain_id} > 0) {
    $admin->{DOMAIN_ID} = $list->[0]->{DOMAIN_ID};
    # Load DB %conf;
    our $Conf = Conf->new($db, $admin, \%conf);
  }

  foreach my $user (@{$list}) {
    if ($attr->{RECOMENDED_PAY}) {
      $user->{RECOMENDED_PAY} = recomended_pay($list->[0]);
    }

    if ($user->{FIO}) {
      $user->{FIO} =~ s/\'/_/g;
      $user->{FIO} =~ s/\s+$//g;
    }

    $user->{DEPOSIT} = sprintf("%.2f", $user->{DEPOSIT} || 0);

    if (!$attr->{SKIP_FIO_HIDE}) {
      $user->{FIO} = _hide_text($user->{FIO} || q{});
      $user->{PHONE} = _hide_text($user->{PHONE} || q{});
      $user->{ADDRESS_FULL} = _hide_text($user->{ADDRESS_FULL} || q{});
    }

    last if (!$attr->{MULTI_USER});
  }

  if ($attr->{MULTI_USER}) {
    return $result, $list;
  }

  return $result, $list->[0];
}

#**********************************************************
=head2 paysys_pay_cancel() - cancel payment;

  Arguments:
    $attr
      PAYSYS_ID      - Paysys ID (unique number of operation);
      TRANSACTION_ID - Paysys Transaction identifier
      RETURN_CANCELED_ID - 1 (return $result, $paysys_canceled_id)
      DEBUG

  Returns:
    Cancel code.
    All codes:
      0  - Success Delete
      2  - Error with mysql
      8  - Paysys not exist
      10 - Payments not exist

  Examples:

    my $result = paysys_pay_cancel({
                  TRANSACTION_ID => "OP:11111111"
                 });

    $result - cancel code.

=cut
#**********************************************************
sub paysys_pay_cancel {
  my ($attr) = @_;

  my $debug = $attr->{DEBUG} || 0;
  my $result = 0;
  my $status = 0;
  my $canceled_payment_id = 0;
  my $cancel_status = $attr->{CANCEL_STATUS} || 3;

  if ($debug > 6) {
    $users->{debug} = 1;
    $Paysys->{debug} = 1;
    $payments->{debug} = 1;
  }

  my $paysys_list = $Paysys->list({
    ID             => $attr->{PAYSYS_ID},
    TRANSACTION_ID => $attr->{TRANSACTION_ID} || '_SHOW',
    SUM            => '_SHOW',
    COLS_NAME      => 1
  });

  if ($Paysys->{TOTAL}) {
    my $transaction_id = $paysys_list->[0]->{transaction_id};

    my $list = $payments->list({
      ID        => '_SHOW',
      EXT_ID    => "$transaction_id",
      BILL_ID   => '_SHOW',
      COLS_NAME => 1,
      PAGE_ROWS => 1
    });

    if ($status == 0) {
      if ($payments->{errno}) {
        $result = 2;
      }
      elsif ($payments->{TOTAL} < 1) {
        $result = 10;
        # cancel transaction status if no payments
        $Paysys->change({
          ID     => $paysys_list->[0]->{id},
          STATUS => $cancel_status
        });
      }
      else {
        my %user = (
          BILL_ID => $list->[0]->{bill_id},
          UID     => $list->[0]->{uid}
        );

        $users->list({ UID => $list->[0]->{uid}, COLS_NAME => 1, COLS_UPPER => 1 }) if ($conf{PAYSYS_LOG});
        my $payment_id = $list->[0]->{id};

        $payments->del(\%user, $payment_id);
        if ($payments->{errno}) {
          $result = 2;
        }
        else {
          $Paysys->change({
            ID     => $paysys_list->[0]->{id},
            STATUS => $cancel_status
          });
          $canceled_payment_id = $paysys_list->[0]->{id};
        }
      }
    }
  }
  else {
    $result = 8;
  }

  $paysys_id = $canceled_payment_id;

  if ($attr->{RETURN_CANCELED_ID}) {
    return $result, $canceled_payment_id;
  }

  return $result;
}

#**********************************************************
=head2 paysys_pay_check() - Checking existing transaction

  Arguments:
    $attr
      PAYSYS_ID      - Payment system identifier;
      TRANSACTION_ID - Transaction identifier;
      GID            -

  Returns:
    FALSE
      0      - if transaction not found;
    TRUE
      $number - transaction ID
      $transaction_status
      \%transaction_info

  Examples:

    my $result = paysys_pay_check({
                  TRANSACTION_ID => "OP:11111111",
                  GID => '_SHOW',
             });

    $result - 0 or transaction id;

=cut
#**********************************************************
sub paysys_pay_check {
  my ($attr) = @_;
  my $result = 0;

  my $paysys_list = $Paysys->list({
    ID             => $attr->{PAYSYS_ID} || '_SHOW',
    TRANSACTION_ID => $attr->{TRANSACTION_ID} || '_SHOW',
    SUM            => '_SHOW',
    GID            => '_SHOW',
    UID            => '_SHOW',
    COLS_NAME      => 1
  });

  $users->list({ UID => $paysys_list->[0]->{uid}, COLS_NAME => 1, COLS_UPPER => 1 }) if ($conf{PAYSYS_LOG});

  if ($Paysys->{TOTAL}) {
    $paysys_id = $paysys_list->[0]->{id};
    return $paysys_list->[0]->{id}, $paysys_list->[0]->{status}, $paysys_list->[0];
  }

  return $result;
}

#**********************************************************
=head2 paysys_info() -

  Arguments:
    $attr
      PAYSYS_ID - Payment system identifier;

  Returns:

    Paysys object

  Examples:

    $Paysys->paysys_info({ PAYSYS_ID => 121 });

=cut
#**********************************************************
sub paysys_info { #TODO REMOVE THIS FUNCTION
  my ($attr) = @_;

  $Paysys->info({
    ID => $attr->{PAYSYS_ID}
    #TRANSACTION_ID => $attr->{TRANACTION_ID}
  });

  return $Paysys;
}

#**********************************************************
=head2 paysys_get_full_info($attr) -

  Arguments:
    $attr
      PAYSYS_ID - Payment system identifier;

  Returns:

    Paysys object

=cut
#**********************************************************
sub paysys_get_full_info { #TODO REMOVE THIS FUNCTION
  my ($attr) = @_;

  my $list = $Paysys->list({
    ID             => $attr->{PAYSYS_ID} || '_SHOW',
    TRANSACTION_ID => $attr->{TRANSACTION_ID} || '_SHOW',
    STATUS         => '_SHOW',
    PAYMENT_SYSTEM => '_SHOW',
    COLS_NAME      => 1,
  });

  if ($Paysys->{TOTAL} == 1) {
    return $list->[0];
  }

  return {};
}

#**********************************************************
=head2 paysys_payment_list() -

  Arguments:
    $attr
      PAYMENT_SYSTEM - Payment system identifier;
      FROM_DATE      - Payment from date;
      TO_DATE        - Payment to date;

  Returns:

    Payment list

=cut
#**********************************************************
sub paysys_payment_list { #TODO REMOVE THIS FUNCTION
  my ($attr) = @_;

  my $list = $Paysys->list({
    PAYMENT_SYSTEM => $attr->{PAYMENT_SYSTEM} || '_SHOW',
    FROM_DATE      => $attr->{FROM_DATE} || '_SHOW',
    TO_DATE        => $attr->{TO_DATE} || '_SHOW',
    COLS_NAME      => 1
  });

  return $list;
}

#**********************************************************
=head2 conf_gid_split($attr) - Find payment system parameters for some user group (GID)

  Arguments:
    $attr
      GID: int           - group identifier;
      NAME: string       - custom name of Payment system
      PARAMS: object     - Array of parameters
      SERVICE: int       - Service ID
      SERVICE2GID        - Service to gid
                             delimiter :
                             separator ;
      GET_MAIN_GID
      PAYMENT_SYSTEM_ID  - ID of payment system;

  Returns:


  Examples:

    conf_gid_split({ GID    => 1,
                     PARAMS => [
                         'PAYSYS_UKRPAYS_SERVICE_ID',
                      ],
                 })
    convers

     $conf{PAYSYS_UKRPAYS_SERVICE_ID} => $conf{PAYSYS_UKRPAYS_SERVICE_ID_1};

=cut
#**********************************************************
sub conf_gid_split {
  my ($attr) = @_;

  my $gid = $attr->{GID};

  if ($attr->{PARAMS}) {
    my $param_name = $attr->{PARAMS}->[0] || '';
    my ($paysys_name) = $param_name =~ /^PAYSYS_[^_]+/gm;
    push @{$attr->{PARAMS}}, ($paysys_name || '') . '_PAYMENT_METHOD',
      ($paysys_name || '') . '_PORTAL_DESCRIPTION', ($paysys_name || '') . '_PORTAL_COMMISSION';
  }

  if (!$gid) {
    return _check_max_payments($attr);
  }

  # FIXME: it's unused maybe delete?
  if ($attr->{SERVICE} && $attr->{SERVICE2GID}) {
    my @services_arr = split(/;/, $attr->{SERVICE2GID});
    foreach my $line (@services_arr) {
      my ($service, $gid_id) = split(/:/, $line);
      if ($attr->{SERVICE} == $service) {
        $gid = $gid_id;
        last;
      }
    }
  }

  if ($attr->{PARAMS}) {
    my $params = $attr->{PARAMS};
    foreach my $key (@$params) {
      $key =~ s/_NAME_/_$attr->{NAME}\_/ if ($attr->{NAME} && $key =~ /_NAME_/);
      if (defined $conf{$key . '_' . $gid}) {
        $conf{$key} = $conf{$key . '_' . $gid};
        if ($attr->{GET_MAIN_GID}) {
          $FORM{MAIN_GID} = $gid; # gid
        }
      }
    }
  }

  return _check_max_payments($attr);
}

#**********************************************************
=head2 _check_max_payments($attr) - Check is allowed make payment for user

  Arguments:
    $attr
      PARAMS: object     - Array of parameters
      PAYMENT_SYSTEM_ID  - ID of payment system
      MERCHANT_ID        - ID of merchant which need to check
      MERCHANTS          - list of executed merchants, prevent boot loop

  Returns:

    0 - not allowed payment
    1 - allowed payment

=cut
#**********************************************************
sub _check_max_payments {
  my ($attr) = @_;

  my $params = {};
  my $merchant_id = '--';

  if ($attr->{MERCHANT_ID}) {
    $params = $Paysys->merchant_params_info({ MERCHANT_ID => $attr->{MERCHANT_ID} });
  }
  else {
    return 1 if (!$attr->{PAYMENT_SYSTEM_ID});
    return 1 if (!$Paysys->can('gid_params'));

    my $list_params = $Paysys->gid_params({
      GID       => $attr->{GID} || 0,
      PAYSYS_ID => $attr->{PAYMENT_SYSTEM_ID},
      COLS_NAME => 1,
    });

    foreach my $param (@{$list_params}) {
      $params->{$param->{param}} = $param->{value} || '';
    }

    $merchant_id = $list_params->[0]->{merchant_id} || '--' if (scalar @{$list_params});
  }

  delete $Paysys->{errno};

  return 1 if (!scalar keys %{$params} && !$attr->{MERCHANT_ID});

  my ($max_sum_key) = grep {/PAYMENTS_MAX_SUM/g} keys %{$params};
  return 1 if ((!$max_sum_key || !$params->{$max_sum_key}) && !$attr->{MERCHANT_ID});

  my ($payment_method_key) = grep {/PAYMENT_METHOD/g} keys %{$params};
  return 1 if ((!$payment_method_key || !$params->{$payment_method_key}) && !$attr->{MERCHANT_ID});

  my $payment_method = $params->{$payment_method_key || '--'};
  my $max_sum = $params->{$max_sum_key || ''} || 0;

  if ($max_sum) {
    my ($year, $month) = $DATE =~ /(\d{4})\-(\d{2})\-(\d{2})/g;
    $payments->list({
      PAYMENT_METHOD => $payment_method,
      FROM_DATE      => "$year-$month-01",
      TO_DATE        => $DATE,
      TOTAL_ONLY     => 1
    });

    $payments->{SUM} //= 0;
    delete $payments->{errno};
  }

  if (!$max_sum || (defined $payments->{SUM} && $max_sum > $payments->{SUM})) {
    if ($attr->{MERCHANT_ID}) {
      foreach my $param (keys %{$params}) {
        $conf{$param} = $params->{$param};
      }
    }

    return 1;
  }

  my ($merchant_id_key) = grep {/PAYMENTS_NEXT_MERCHANT/g} keys %{$params};
  if (!$merchant_id_key || !$params->{$merchant_id_key}) {
    if ($attr->{MERCHANT_ID} || $max_sum) {
      return 0;
    }
    else {
      return 1;
    }
  }

  $attr->{MERCHANT_ID} = $params->{$merchant_id_key || ''} || '--';
  $attr->{MERCHANTS} ||= [ $merchant_id ];
  return 0 if (in_array($attr->{MERCHANT_ID}, $attr->{MERCHANTS}));
  push @{$attr->{MERCHANTS}}, $attr->{MERCHANT_ID};

  return _check_max_payments($attr);
}

#**********************************************************
=head2 mk_log($message, $attr) - add data to logfile;

 Make log file for paysys request

  Arguments:
    $message -
    $attr
      PAYSYS_ID     - payment system ID
      REQUEST       - System Request
      REQUEST_TYPE  - System Request
      REPLY         - ABillS Reply
      SHOW          - print message to output
      LOG_FILE      - Log file. (Default: paysys_check.log)
      HEADER        - Print header
      DATA          - Make form log
      TYPE          - Request TYPE
      STATUS        - Request ABillS Status
      ERROR         - Error during validation of request

  Returns:

     TRUE or FALSE

  Examples:
    mk_log("Data for logfile", { PAYSYS_ID => '63' });


=cut
#**********************************************************
sub mk_log {
  my ($message, $attr) = @_;

  if (!$base_dir) {
    our $Bin;
    require FindBin;
    FindBin->import('$Bin');

    if ($Bin =~ m/\/axbills(\/)/){
      $base_dir = substr($Bin, 0, $-[1]);
      $base_dir .= '/';
    }
  }

  my $paysys          = $attr->{PAYSYS_ID} || '';
  my $paysys_log_file = $attr->{LOG_FILE} || ($base_dir // '/usr/axbills/') . 'var/log/paysys_check.log';

  if ($attr->{HEADER}) {
    print "Content-Type: text/plain\n\n";
  }

  if ($attr->{REPLY}) {
    $paysys .= " REPLY: $attr->{REPLY}";
  }

  if ($attr->{TYPE}) {
    $paysys .= " TYPE: $attr->{TYPE}";
  }

  if ($attr->{STATUS}) {
    $paysys .= " STATUS: $attr->{STATUS}";
  }

  if ($attr->{DATA} && ref $attr->{DATA} eq 'HASH') {
    foreach my $key (keys %{$attr->{DATA}}) {
      next if (in_array($key, [ 'index', '__BUFFER', 'root_index' ]));
      $message .= $key . ' => ' . (defined($attr->{DATA}->{$key}) ? $attr->{DATA}->{$key} : q{}) . "\n";
    }
  }

  if ($conf{PAYSYS_LOG}) {
    my $buffer = $FORM{__BUFFER} || q{};

    if (!$insert_id) {
      my $result = $Paysys->log_add({
        REQUEST        => $buffer,
        PAYSYS_IP      => $ENV{REMOTE_ADDR},
        HTTP_METHOD    => $ENV{REQUEST_METHOD},
        SYSTEM_ID      => $attr->{PAYSYS_ID},
        ERROR          => $attr->{ERROR} || '',
        STATUS         => 1,
        TRANSACTION_ID => $paysys_id,
        REQUEST_TYPE   => $attr->{REQUEST_TYPE} || 0,
        SUM            => $attr->{SUM} || 0
      });

      $insert_id = $result->{INSERT_ID} || 0;
      delete $Paysys->{INSERT_ID};
    }
    elsif ($insert_id && $attr->{REPLY}) {
      my $uid = 0;
      if ($users->{TOTAL} && $users->{TOTAL} > 0) {
        $uid = $users->{list}->[0]->{uid} || $users->{UID} || 0;
      }

      $Paysys->log_change({
        ID             => $insert_id || '--',
        REQUEST        => $buffer,
        RESPONSE       => $message,
        IP             => $ENV{REMOTE_ADDR},
        HTTP_METHOD    => $ENV{REQUEST_METHOD},
        SYSTEM_ID      => $attr->{PAYSYS_ID},
        UID            => $uid || $attr->{UID},
        ERROR          => $attr->{ERROR} || '',
        STATUS         => 0,
        TRANSACTION_ID => $paysys_id,
        REQUEST_TYPE   => $attr->{REQUEST_TYPE} || 0,
        SUM            => $attr->{SUM} || 0
      });
    }
  }

  if (!defined($conf{PAYSYS_LOG}) || ($conf{PAYSYS_LOG} && $conf{PAYSYS_LOG} != 2)) {
    if (open(my $fh, '>>', $paysys_log_file)) {
      if ($attr->{SHOW}) {
        print "$message";
      }

      if (!$DATE) {
        require POSIX;
        POSIX->import(qw( strftime ));
        $DATE = strftime("%Y-%m-%d", localtime(time));
        $TIME = strftime("%H:%M:%S", localtime(time));
      }

      $ENV{REMOTE_ADDR} //= '127.0.0.1';
      print $fh "\n$DATE $TIME $ENV{REMOTE_ADDR} $paysys =========================\n";

      if ($attr->{REQUEST}) {
        print $fh "$attr->{REQUEST}\n=======\n";
      }

      print $fh $message || q{};
      close($fh);
    }
    else {
      print "Content-Type: text/plain\n\n";
      print "Can't open log file '$paysys_log_file' $!\n";
      print "Error:\n";
      print "================\n$message================\n";
      die "Can't open log file '$paysys_log_file' $!\n";
    }
  }

  return 1;
}

#**********************************************************
=head2 paysys_show_result($attr) - Show result

  WEB form show result

  Attributes:
    $attr
      TRANSACTION_ID
      UID
      SUM
      SHOW_TRUE_PARAMS - Hash ref
        {NAME:VALUE}
      SHOW_FALSE_PARAMS - Hash ref
        {NAME:VALUE}
      FALSE
  Results:
    TRUE or FALSE

=cut
#**********************************************************
sub paysys_show_result {
  my ($attr) = @_;

  my $transaction_true = 1;
  if ($attr->{TRANSACTION_ID}) {
    my $list = $Paysys->list({
      TRANSACTION_ID => $attr->{TRANSACTION_ID},
      UID            => $attr->{UID} || $LIST_PARAMS{UID},
      SUM            => '_SHOW',
      STATUS         => '_SHOW',
      USER_INFO      => '_SHOW',
      INFO           => '_SHOW',
      COLS_NAME      => 1,
      SKIP_DEL_CHECK => 1,
      SORT           => 'id'
    });

    if ($Paysys->{TOTAL} > 0) {
      $attr->{SUM} = sprintf("%.2f", $list->[0]->{sum} || 0);
      $FORM{PAYSYS_ID} = $list->[0]->{id};

      if ($list->[0]->{status} != 2) {
        $attr->{MESSAGE} = $status[$list->[0]->{status}];
        $transaction_true = 0;
      }
    }
    else {
      $attr->{MESSAGE} = $lang{ERR_NO_TRANSACTION};
      $attr->{FALSE} = 1;
      $transaction_true = 0;
    }

    if ($list->[0]->{info} && $list->[0]->{info} =~ /TP_ID,(\d+)/) {
      $FORM{TP_ID} = $1;
    }

    $attr->{USER_INFO} = $list->[0]->{user_info};
  }

  my $qs = '';
  foreach my $key (keys %FORM) {
    next if (in_array($key, [ 'index', '__BUFFER', 'root_index' ]));
    $qs .= '&' . $key . '=' . $FORM{$key};
  }

  $attr->{BTN_REFRESH} = $html->button($lang{REFRESH}, "index=$index" . $qs, { BUTTON => 2 });
  if ($attr->{FALSE}) {
    if ($attr->{SHOW_FALSE_PARAMS}) {
      while (my ($key, $value) = each %{$attr->{SHOW_FALSE_PARAMS}}) {
        $attr->{EXTRA_MESSAGE} .= "$key - $value" . $html->br();
      }
    }

    $html->tpl_show(_include('paysys_false', 'Paysys'), { %$attr });
    $transaction_true = 0;
  }
  else {
    if ($attr->{SHOW_TRUE_PARAMS}) {
      while (my ($key, $value) = each %{$attr->{SHOW_TRUE_PARAMS}}) {
        $attr->{EXTRA_MESSAGE} .= "$key - $value" . $html->br();
      }
    }

    $FORM{TRUE} = 1;
    $html->tpl_show(_include('paysys_complete', 'Paysys'), $attr) if (!$attr->{QUITE});
  }

  $html->set_cookies('lastindex', "", "Fri, 1-Jan-2038 00:00:01") if (!$FORM{INTERACT});

  return $transaction_true;
}

#**********************************************************
=head2 paysys_import_parse($content, $import_expr, $BINDING_FIELD) - Parce file

  Arguments:
    $content
    $import_expr
    $BINDING_FIELD
    $attr
      DEBUG
      ENCODE
      SKIP_ROWS - Skip [SKIP_ROWS] count

  Returns:
    return \@DATA_ARR, \@BINDING_IDS;

=cut
#**********************************************************
sub paysys_import_parse {
  my ($content, $import_expr, $BINDING_FIELD, $attr) = @_;

  my $debug = $attr->{DEBUG} || 0;

  my @DATA_ARR    = ();
  my @BINDING_IDS = ();

  $import_expr =~ s/ //g;
  $import_expr =~ s/\n//g;
  my ($expration, $columns) = split(/:/, $import_expr);
  my @EXPR_IDS = split(/,/, $columns);
  print "EXPRESSION: $expration\nColumns: $columns\n" if ($debug > 0);

  my @rows = split(/[\r]{0,1}\n/, $content);
  my $line_count = 1;
  my $first_row = 0;
  if ($attr->{SKIP_ROWS}) {
    $first_row = $attr->{SKIP_ROWS};
  }

  for (my $row = $first_row; $row <= $#rows; $row++) {
    my $line = $rows[$row];
    my %DATA_HASH = ();

    if ($attr->{ENCODE}) {
      $line = convert($line, { $attr->{ENCODE} => 1 });
    }

    if (my @res = ($line =~ /$expration/)) {
      for (my $i = 0; $i <= $#res; $i++) {
        my $field_name = $EXPR_IDS[$i] || q{};
        print "$field_name => $res[$i]\n" . $html->br() if ($debug > 5);
        next if ($field_name eq 'UNDEF');
        $DATA_HASH{ $field_name } = $res[$i];

        if ($field_name eq 'PHONE') {
          $DATA_HASH{ $field_name } =~ s/-//g;
        }
        elsif ($field_name eq 'CONTRACT_ID') {
          $DATA_HASH{ $field_name } =~ s/-//g;
        }
        elsif ($field_name eq 'LOGIN') {
          $DATA_HASH{ $field_name } =~ s/ //g;
        }
        elsif ($field_name eq 'SUM') {
          $DATA_HASH{ $field_name } =~ s/,/\./g;
        }
        elsif ($field_name eq 'DATE') {
          if ($DATA_HASH{DATE} =~ /^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})$/) {
            $DATA_HASH{DATE} = "$1-$2-$3";
            $DATA_HASH{TIME} = "$4:$5:$6";
          }
          elsif ($DATA_HASH{DATE} =~ /^(\d{2})[.-](\d{2})[.-](\d{4})$/) {
            $DATA_HASH{DATE} = "$3-$2-$1";
          }
          elsif ($DATA_HASH{DATE} =~ /^(\d{4})[.-](\d{2})[.-](\d{2})$/) {
            $DATA_HASH{DATE} = "$1-$2-$3";
          }
        }
      }

      push @DATA_ARR, \%DATA_HASH;
      push @BINDING_IDS, $DATA_HASH{$BINDING_FIELD} if ($DATA_HASH{$BINDING_FIELD});
    }
    elsif ($line ne '') {
      print $html->b("$lang{ERROR}: line: $line_count") . " '$line'" . $html->br();
    }

    $line_count++;
  }

  return \@DATA_ARR, \@BINDING_IDS;
}

#**********************************************************
=head2 _account_expression($user_account) -

  Arguments:
    $user_account -

  Returns:

  Examples:

=cut
#**********************************************************
sub _account_expression {
  my ($user_account) = @_;

  my @key_expressions = split(';', $conf{PAYSYS_ACCOUNT_KEY});
  my $CHECK_FIELD = q{};

  foreach my $each_key_expression (@key_expressions) {
    my ($reg_exp, $user_check_field) = split(":", $each_key_expression);
    if ($user_account =~ /$reg_exp/) {
      $CHECK_FIELD = $user_check_field;
    }
  }

  return $CHECK_FIELD;
}

#**********************************************************
=head2 _hide_text($text) - Hide text string

  Arguments:
     $text

  Returns:
    $hidden_text

=cut
#**********************************************************
sub _hide_text {
  my ($text) = @_;

  my $hidden_text = '';
  if (!$text) {
    return q{};
  }

  my @join_test = ();
  $text =~ s/\s+$//gm;
  $text =~ s/\'/_/g;
  my $str_utf8 = decode("UTF-8", $text);

  my @split_fio = split(/ /, $str_utf8);
  my @split_word = ();
  foreach my $key (@split_fio) {
    @split_word = split(//, $key);
    for (my $i = 0; $i < @split_word; $i++) {
      if ($i != 0 && ($i % 2 == 0 || $i % 3 == 0)) {
        $split_word[$i] = '*';
      }
    }
    my $fio_hiden_1 = join('', @split_word);
    push(@join_test, $fio_hiden_1);
  }

  $hidden_text = encode("UTF-8", join(' ', @join_test));

  return $hidden_text;
}

#**********************************************************
=head2 date_convert($date) - Convert fate to system format

  Arguments:
     $date
     $attr

  Returns:
    $converted_date (YYYY-MM-DD)

=cut
#**********************************************************
sub date_convert {
  my ($date, $attr) = @_;

  my $system_date = $date || $DATE;

  if (!$date) {
    if ($attr->{DATE_DMY}) {
      $attr->{DATE_DMY} =~ /^(\d{2})(\d{2})(\d{4})/;
      $system_date = "$3-$2-$1";
    }
  }
  elsif ($date =~ /^(202\d{1})(\d{2})(\d{2})/) {
    $system_date = "$1-$2-$3";
  }
  elsif ($date =~ /^(\d{2})\.(\d{2})\.(\d{4})/) {
    $system_date = "$3-$2-$1";
  }

  return $system_date;
}

#**********************************************************
=head2  function paysys_check_user_second_bill() - check user in second bill;

  Arguments:
    $attr
      USER_ACCOUNT - user account

  Returns:
    $result, $user_info

=cut
#**********************************************************
sub paysys_check_user_second_bill {
  my ($attr) = @_;
  my $request_url = $conf{SECOND_BILLING};

  my $response_second_billing = web_request($request_url, {
    REQUEST_PARAMS => {
      command => 'check',
      account => $attr->{USER_ACCOUNT},
      sum     => 1 },
    GET            => ($attr->{SOURCE}) ? undef : 1,
    CURL           => 1,
    REQUEST_COUNT  => 1,
    CURL_OPTIONS   => " -L -k -s "
  });

  $response_second_billing =~ /(?<=<result>)(\d+)(?=<\/result>)/g;
  my $response_result = $1 || q{};
  $response_second_billing =~ /((?<=<comment>)(.*)(?=<\/comment>))/g;
  my $response_comment = $2 || q{};

  mk_log("Status of Payment: " . ($response_result || q{}) . ", comment: $response_comment");

  if ($response_result eq '0') {
    return 0, { comment => $response_comment };
  }
  else {
    return 1;
  }
}

#**********************************************************
=head2  function paysys_pay_second_bill() - check user in second bill;

  Arguments:
    $attr
      USER_ACCOUNT  - user account
      SUM           - user account
      EXT_ID        - id transaction
      PAYMENT_ID    - return payment id
  Returns:
    $result, $prv_txn (prv-txn(pay_id) - id transaction in our system)

=cut
#**********************************************************
sub paysys_pay_second_bill {
  my ($attr) = @_;
  my $request_url = $conf{SECOND_BILLING};

  my $response_second_billing = web_request($request_url, {
    REQUEST_PARAMS => {
      command => 'pay',
      account => $attr->{USER_ACCOUNT},
      sum     => $attr->{SUM},
      txn_id  => $attr->{EXT_ID} },
    GET            => ($attr->{SOURCE}) ? undef : 1,
    CURL           => 1,
    REQUEST_COUNT  => 1,
    CURL_OPTIONS   => " -L -k -s "
  });

  $response_second_billing =~ /(?<=<result>)(\d+)(?=<\/result>)/g;
  my $response_result = $1;
  $response_second_billing =~ /((?<=<prv_txn>)(.*)(?=<\/prv_txn>))/g;
  my $response_pay_id = $2 || q{};

  mk_log("Status of Payment: " . ($response_result || q{}) . " PayId: $response_pay_id");

  if (defined($response_result) && $response_result eq '0') {
    if ($attr->{PAYMENT_ID}) {
      return 0, $response_pay_id;
    }
    else {
      return 0;
    }
  }
  else {
    return 1;
  }
}

#**********************************************************
=head2 _paysys_extra_check_user() - check with multi params

  USER_ACCOUNT      - for multi check fields put ARRAY:
  MAIN_CHECK_FIELD  - CHECK FIELD if present conf param PAYSYS_USER_MULTI_CHECK will be first in check
  EXTRA_USER_IDS    - If defined will be pushed to array to exist USER_ACCOUNT and CHECK_FIELD
                        Example ARRAY:
                          [{ CHECK_FIELD => 'LOGIN', USER_ACCOUNT => $FORM->{login} }, { CHECK_FIELD => 'UID', USER_ACCOUNT => $FORM->{uid} }]
  EXTRA_FIELDS      - Extra field
  COLS_UPPER        - if defined will used COLS_UPPER for $users->list function
  MAIN_GID          - main GID

=cut
#**********************************************************
sub _paysys_extra_check_user {
  my ($attr) = @_;

  my $list = [];
  my @params_array = ({
    USER_ACCOUNT => $attr->{USER_ACCOUNT},
    CHECK_FIELD  => $attr->{MAIN_CHECK_FIELD}
  });
  my %EXTRA_FIELDS = ();

  if (scalar @{$attr->{EXTRA_USER_IDS}}) {
    foreach my $user_id (@{$attr->{EXTRA_USER_IDS}}) {
      next unless ($attr->{MAIN_CHECK_FIELD} || $attr->{USER_ACCOUNT});
      my $user_account = _expr($user_id->{USER_ACCOUNT}, $conf{PAYSYS_ACCOUNT_EXPR});
      next if (!$user_account);

      push @params_array, $user_id;
    }
  }

  if ($attr->{EXTRA_FIELDS}) {
    %EXTRA_FIELDS = %{$attr->{EXTRA_FIELDS}};
  }

  foreach my $params (@params_array) {
    my @check_fields = ();

    if ($conf{PAYSYS_USER_MULTI_CHECK}) {
      my @check_arr = split(/,\s?/, uc($conf{PAYSYS_USER_MULTI_CHECK}));
      @check_fields = grep {$_ ne $params->{CHECK_FIELD}} @check_arr;
    }

    unshift @check_fields, $params->{CHECK_FIELD};

    foreach my $CHECK_FIELD (@check_fields) {

      if ($CHECK_FIELD eq 'PHONE') {
        if ($params->{USER_ACCOUNT} && $params->{USER_ACCOUNT} !~ /\d{10,}$/g) {
          $params->{USER_ACCOUNT} = '-------';
        }
        else {
          $params->{USER_ACCOUNT} = "*$params->{USER_ACCOUNT}*";
        }
      }

      $list = $users->list({
        $params->{CHECK_FIELD} => '_SHOW',
        LOGIN                  => '_SHOW',
        FIO                    => '_SHOW',
        DEPOSIT                => '_SHOW',
        CREDIT                 => '_SHOW',
        PHONE                  => '_SHOW',
        ADDRESS_FULL           => '_SHOW',
        GID                    => defined($attr->{MAIN_GID}) ? $attr->{MAIN_GID} : '_SHOW',
        DOMAIN_ID              => defined($ENV{DOMAIN_ID}) ? $ENV{DOMAIN_ID} : '_SHOW',
        DISABLE_PAYSYS         => '_SHOW',
        GROUP_NAME             => '_SHOW',
        DISABLE                => '_SHOW',
        CONTRACT_ID            => '_SHOW',
        ACTIVATE               => '_SHOW',
        REDUCTION              => '_SHOW',
        BILL_ID                => '_SHOW',
        %EXTRA_FIELDS,
        $CHECK_FIELD           => $params->{USER_ACCOUNT} || '---',
        COLS_NAME              => 1,
        COLS_UPPER             => $attr->{COLS_UPPER} ? 1 : '',
        PAGE_ROWS              => 4,
      });

      delete $users->{errno} if ($users->{errno} && $CHECK_FIELD ne $check_fields[-1]);
      last if ($users->{TOTAL} && $users->{TOTAL} > 0);
    }

    delete $users->{errno} if ($users->{errno} && $params->{CHECK_FIELD} ne $params_array[-1]->{CHECK_FIELD});
    last if ($users->{TOTAL} && $users->{TOTAL} > 0);
  }

  return $list;
}

#**********************************************************
=head2 _paysys_execute_external_command() - execute external command

  UID: int - uid of user

=cut
#**********************************************************
sub _paysys_execute_external_command {
  my ($attr) = @_;

  require Paysys::Base;
  my $Paysys_base = Paysys::Base->new($db, $admin, \%conf);

  $Paysys_base->payments_maked({ UID => $attr->{UID} });

  return 1;
}

#**********************************************************
=head2 paysys_statement_processing() - execute external command

=cut
#**********************************************************
sub paysys_statement_processing {
  my ($statement) = @_;

  return 1 if (!$conf{PAYSYS_STATEMENTS_MULTI_CHECK});

  my @check_arr = split(/;\s?/, $conf{PAYSYS_STATEMENTS_MULTI_CHECK});

  return 2 if (!scalar @check_arr);

  my $regex = $conf{PAYSYS_STATEMENTS_MULTI_CHECK_REGEX} || '\s|\;|:|№|\/';

  my @values = split(/$regex/, $statement);
  @values = grep { defined $_ && $_ ne '' } @values;

  foreach my $check_field (@check_arr) {
    my ($field_name, $field_type, $field_regex) = split(/:/, $check_field);

    next if (!$field_name);
    $field_name = uc($field_name);

    my $pattern = $field_regex ? qr/$field_regex/ : '';
    my $search_str = '';

    if ($field_type && $field_type eq 'INT') {
      foreach my $value (@values) {
        next if (!is_number($value));
        next if ($pattern && $value !~ $pattern);
        $search_str .= "$value,";
      }
    }
    else {
      foreach my $value (@values) {
        next if ($pattern && $value !~ /$pattern/);
        if ($check_field eq 'FIO') {
          $search_str .= "*$value*,";
        }
        else {
          $search_str .= "$value,";
        }
      }
    }

    my $users_list = $users->list({
      LOGIN          => '_SHOW',
      FIO            => '_SHOW',
      DEPOSIT        => '_SHOW',
      CREDIT         => '_SHOW',
      PHONE          => '_SHOW',
      ADDRESS_FULL   => '_SHOW',
      DISABLE_PAYSYS => '_SHOW',
      GROUP_NAME     => '_SHOW',
      DISABLE        => '_SHOW',
      CONTRACT_ID    => '_SHOW',
      ACTIVATE       => '_SHOW',
      REDUCTION      => '_SHOW',
      BILL_ID        => '_SHOW',
      $field_name    => $search_str || '--',
      _MULTI_HIT     => 1,
      COLS_NAME      => 1,
      COLS_UPPER     => 1,
      PAGE_ROWS      => 1000,
    });

    if ($users->{errno}) {
      delete $users->{errno};
      next;
    }

    my %users_list = ();

    foreach my $user (@{$users_list}) {
      my $key = $user->{$field_name};
      $users_list{$key} = [] if (!exists $users_list{$key});
      push @{$users_list{$key}}, $user;
    }

    foreach my $key (keys %users_list) {
      my $matches = scalar @{$users_list{$key}} || 0;
      next if (!$matches);

      return 0, $users_list{$key} if ($matches < 2);

      #TODO: add logic of advanced address search

      next if ($matches > 1 && $field_name ne 'FIO');

      my $matched_user = '';

      foreach my $user_obj (@{$users_list{$key}}) {
        my @fio = split(/\s/, lc($user_obj->{FIO}));
        @fio = grep { defined $_ && $_ ne '' } @fio;

        my $fio_pattern = '(?=.*' . join(')(?=.*', map { quotemeta } @fio) . ')';

        if (lc($statement) =~ /$fio_pattern/) {
          if ($matched_user) {
            $matched_user = '';
            last;
          }
          else {
            $matched_user = $user_obj;
          }
        }
      }

      return 0, $matched_user if ($matched_user);
    }
  }

  return 3;
}

1;
