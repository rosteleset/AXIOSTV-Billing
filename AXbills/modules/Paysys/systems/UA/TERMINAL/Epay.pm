=head1 Epay

  New module for Epay payment system

    OSMP emulation
  Date: 18.04.2019
=cut
use strict;
use warnings;

use AXbills::Base qw(_bp in_array);
use AXbills::Misc qw(load_module);
require Paysys::Paysys_Base;

package Paysys::systems::Epay;
our $PAYSYSTEM_NAME = 'Epay';
our $PAYSYSTEM_SHORT_NAME = 'EPAY';

our $PAYSYSTEM_ID = 78;
our $PAYSYSTEM_VERSION = '7.00';

my $CUSTOM_NAME = uc($PAYSYSTEM_NAME);
my $CUSTOM_ID   = $PAYSYSTEM_ID;

our %PAYSYSTEM_CONF = (
  "PAYSYS_NAME_ACCOUNT_KEY" => '',
);

my %status_hash = (
  0   => 'Success',
  1   => 'Temporary DB error',
  4   => 'Wrong client indentifier',
  5   => 'User not exist', #'Failed witness a signature',
  6   => 'Unknown terminal',
  7   => 'Payments deny',

  8   => 'Double request',
  9   => 'Key Info mismatch',
  79  => 'Счёт абонента не активен',
  300 => 'Unknown error',
);

my %axbills2osmp = (
  0  => 0,   # Ok
  1  => 5,   # Not exist user
  2  => 300, # sql error
  3  => 0,   # dublicate payment
  5  => 300, # wrong sum
  11 => 7,
  13 => '0', # Paysys exist transaction
  30 => 4,   # No input
  #  => 90,  #Payments error
);

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
=head2 proccess()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub proccess {
  my $self = shift;
  my ($FORM) = @_;
  if($FORM->{command} && $FORM->{command} eq 'check'){
    my $check_result = $self->check($FORM);
    $check_result->{test} = 1 if $FORM->{test};
    return $self->_show_response($check_result);
  }
  elsif($FORM->{command} && $FORM->{command} eq 'pay'){
    my $pay_result = $self->pay($FORM);
    $pay_result->{test} = 1 if $FORM->{test};
    return $self->_show_response($pay_result);
  }
  elsif($FORM->{command} && $FORM->{command} eq 'cancel'){
    my $cancel_result = $self->cancel($FORM);
    $cancel_result->{test} = 1 if $FORM->{test};
    return $self->_show_response($cancel_result);
  }
  elsif($FORM->{command} && $FORM->{command} eq 'status'){
    my $status_result = $self->status($FORM);
    $status_result->{test} = 1 if $FORM->{test};
    return $self->_show_response($status_result)
  }

  return 1;
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
  my %RESULT_HASH = (result => 300);
  my $txn_id = 'epay_txn_id';

  my ($result_code, $user_object) = main::paysys_check_user({
    CHECK_FIELD        => $CHECK_FIELD,
    USER_ID            => $FORM->{account},
    DEBUG              => $self->{DEBUG},
    SKIP_DEPOSIT_CHECK => 1
  });

  my $status = ($axbills2osmp{$result_code}) ? $axbills2osmp{$result_code} : 0;

  $RESULT_HASH{result} = $status;

  if ($result_code == 11) {
    $RESULT_HASH{disable_paysys} = 1;
  }

  # Qiwi testing, check if exist param sum
  if (!$FORM->{sum}) {
    $RESULT_HASH{result} = 300;
  }

  # Qiwi testing, account regexp check
  if ($self->{conf}{"PAYSYS_" . $CUSTOM_NAME . "_ACCOUNT_REXEXP"} && ($FORM->{account} !~ $self->{conf}{"PAYSYS_" . $CUSTOM_NAME . "_ACCOUNT_REXEXP"})) {
    $RESULT_HASH{result} = 4;
  }


  $RESULT_HASH{$txn_id} = $FORM->{txn_id};
  $RESULT_HASH{prv_txn} = $FORM->{prv_txn} if ($FORM->{prv_txn});
  $RESULT_HASH{comment} = "Balance: $user_object->{deposit} $user_object->{fio} " if ($status == 0);


  #Result output
  $RESULT_HASH{comment} = $status_hash{ $RESULT_HASH{result} } if ($RESULT_HASH{result} && !$RESULT_HASH{comment});

  return \%RESULT_HASH;
}

#**********************************************************
=head2 pay() - make a payment for user

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
sub pay {
  my ($self) = shift;
  my ($FORM) = @_;

  my %RESULT_HASH = (result => 300);
  my $txn_id = 'epay_txn_id';

  if ($self->{conf}{"PAYSYS_" . $CUSTOM_NAME . "_TXN_DATE"} && $FORM->{txn_date} =~ /(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})/) {
    $main::DATE = "$1-$2-$3";
    $main::TIME = "$3-$5-$6";
  }

  _get_request_info($FORM);

  my $CHECK_FIELD = $self->{conf}{"PAYSYS_" . $CUSTOM_NAME . "_ACCOUNT_KEY"} || 'UID';

  my ($status_code, $payments_id) = main::paysys_pay({
    PAYMENT_SYSTEM    => $PAYSYSTEM_SHORT_NAME,
    PAYMENT_SYSTEM_ID => $CUSTOM_ID,
    CHECK_FIELD       => $CHECK_FIELD,
    USER_ID           => $FORM->{account},
    SUM               => $FORM->{sum},
    EXT_ID            => $FORM->{txn_id},
    DATA              => $FORM,
    DATE              => "$main::DATE $main::TIME",
    CURRENCY_ISO      => $self->{conf}{"PAYSYS_" . $CUSTOM_NAME . "_CURRENCY"},
    MK_LOG            => 1,
    PAYMENT_ID        => 1,
    DEBUG             => $self->{DEBUG},
    PAYMENT_DESCRIBE  => $FORM->{payment_describe} || "$CUSTOM_NAME Payments",
  });

  # Qiwi testing, check if exist param sum
  if (!$FORM->{sum}) {
    $status_code = 5;
  }

  my $status = (defined($axbills2osmp{$status_code})) ? $axbills2osmp{$status_code} : 90;

  $RESULT_HASH{result} = $status;
  $RESULT_HASH{$txn_id} = $FORM->{txn_id};
  $RESULT_HASH{prv_txn} = $payments_id;
  $RESULT_HASH{sum} = $FORM->{sum} || '';

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

  my %RESULT_HASH = ( result => 300 );

  my $prv_txn = $FORM->{prv_txn};
  $RESULT_HASH{prv_txn} = $prv_txn;

  my $cancel_result = main::paysys_pay_cancel({
    PAYSYS_ID => $prv_txn
  });

  $RESULT_HASH{result} = $cancel_result;

  return \%RESULT_HASH;
}

#**********************************************************
=head2 status()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub status {
  my ($self) = shift;
  my ($FORM) = @_;

  _get_request_info($FORM);

  my %RESULT_HASH = ( result => 300 );

  my $txn_id = $FORM->{txn_id};
  $RESULT_HASH{epay_txn_id} = $txn_id;

  my ($paysys_id, $paysys_status) = main::paysys_pay_check({
    TRANSACTION_ID => "$PAYSYSTEM_SHORT_NAME:$txn_id"
  });

  $RESULT_HASH{result} = $paysys_id == 0 ? 1 : 0;

  return \%RESULT_HASH;
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
      while (my ($key, $value) = each %$v) {
        my ($end_key, undef) = split(" ", $key);
        $results .= "<$key>".(defined $value ? $value : '')."</$end_key>\n";
      }
      $results .= "</$k>\n";
    }
    else {
      $results .= "<$k>".(defined $v ? $v : '')."</$k>\n";
    }
  }

  chomp($results);

  my $response = qq{<?xml version="1.0" encoding="UTF-8"?>
<response>
$results
</response>
};
  return $response if $RESULT_HASH->{test};
  print "Content-Type: text/plain\n\n" if ($self->{DEBUG} > 1);
  print "Content-Type: text/xml\n\n";
  print $response;

  main::mk_log("$response", { PAYSYS_ID => "$CUSTOM_ID/$CUSTOM_NAME", REQUEST => 'Response' });

  return $response;
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
  my %params_hash = (
    '1CHECK'  => {
      account => {
        name    => 'account',
        val     => '',
        tooltip => "Идентификатор абонента в зависимости от настроек системы.(По умолчанию вводить UID абонента)",
      },
      command => {
        name      => 'command',
        val       => 'check',
        ex_params => 'readonly="readonly"',
      },
      sum     => {
        name    => 'sum',
        val     => '1.00',
        tooltip => 'Сумма платежа',
        type    => 'number',
      },
      txn_id  => {
        name    => 'txn_id',
        val     => $random,
        tooltip => 'Transaction ID(случайный номер)',
        type    => 'number',
      },
      result  => [ '<result>0</result>' ],
    },
    '2PAY'    => {
      result  => [ '<result>0</result>' ],
      command => {
        name      => 'command',
        val       => 'pay',
        ex_params => 'readonly="readonly"',
      },
      account => {
        name    => 'account',
        val     => '',
        tooltip => "Идентификатор абонента в зависимости от настроек системы.(По умолчанию вводить UID абонента)",
      },
      sum     => {
        name    => 'sum',
        val     => '1.00',
        tooltip => 'Сумма платежа',
        type    => 'number',
      },
      txn_id  => {
        name    => 'txn_id',
        val     => $random,
        tooltip => 'Transaction ID(случайный номер)',
        type    => 'number',
      },
    },
    '3CANCEL' => {
      result  => [ '<result>0</result>' ],
      command => {
        name      => 'command',
        val       => 'cancel',
        ex_params => 'readonly="readonly"',
      },
      prv_txn => {
        name    => 'prv_txn',
        val     => 'Скопировать из ответа на проведение платежа',
        tooltip => 'Id платежа',
        type    => 'number',
      },
    },
  );

  return \%params_hash;
}
1