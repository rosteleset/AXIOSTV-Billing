package Paysys::systems::Sberbank_online;
=head1 Sberbank_online

  New module for Global

=head1  DOCUMENTATION


=head1 VERSION

  DATE: 05.05.2020
  UPDATE: 20220222
  VERSION: 8.03

=cut

use strict;
use warnings;

require Paysys::Paysys_Base;

our $PAYSYSTEM_NAME = 'Sberbank_online';
our $PAYSYSTEM_SHORT_NAME = 'SBO';
our $PAYSYSTEM_ID = 144;
our $PAYSYSTEM_VERSION = '8.03';

our %PAYSYSTEM_CONF = (
  "PAYSYS_SBERBANK_ONLINE_EXTRA_INFO"  => '',
  "PAYSYS_SBERBANK_ONLINE_ACCOUNT_KEY" => '',
  "PAYSYS_SBERBANK_ONLINE_INFO"        => '',
  "PAYSYS_SBERBANK_ONLINE_EXTRA_INFO"  => 1,
);

my %status_hash = (
  0   => 'Successful completion of the operation',
  1   => 'Temporary DB error',
  2   => 'Unknown request ',
  3   => 'Payer not found',
  4   => 'Wrong format',
  5   => 'Payer account is not active',
  6   => 'Unknown txt_id',
  7   => 'Payment is not allowed for technical reasons',
  8   => 'Transaction duplication',
  9   => 'Invalid payment amount',
  10  => 'Amount is too small',
  11  => 'Amount too large ',
  12  => 'Wrong txn_date',
  300 => 'Unknown error',
);

my %axbills2osmp = (
  0  => 0,   # Ok
  1  => 3,   # Not exist user
  2  => 300, # sql error
  3  => 0,   # dublicate payment
  5  => 300, # wrong sum
  11 => 7,
  12 => 1,   # deadlock in payment
  13 => '0', # Paysys exist transaction
  30 => 4,   # No input
  #  => 90,  #Payments error
);


my ($html);

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

  my $CHECK_FIELD = $self->{conf}{"PAYSYS_SBERBANK_ONLINE_ACCOUNT_KEY"} || 'UID';
  my %RESULT_HASH = (result => 3);
  my $txn_id = 'txn_id';

  my ($result_code, $user_object) = main::paysys_check_user({
    CHECK_FIELD        => $CHECK_FIELD,
    USER_ID            => $FORM->{account},
    DEBUG              => $self->{DEBUG},
    SKIP_DEPOSIT_CHECK => 1
  });

  my $status = ($axbills2osmp{$result_code}) ? $axbills2osmp{$result_code} : 0;

  if ($result_code == 1) {
    $RESULT_HASH{comment} = "Not exist user";
    return \%RESULT_HASH;
  }

  my $info =  $self->{conf}{"PAYSYS_SBERBANK_ONLINE_INFO"} || "Оплата интернет услуг";

  $RESULT_HASH{result} = $status;

  require AXbills::Misc;
  my $abon2 = sprintf("%.2f", ($user_object->{fee} || 0));
  my $deposit = sprintf("%.2f", ($user_object->{deposit} || 0));

  $RESULT_HASH{prv_txn} = $FORM->{prv_txn} if ($FORM->{prv_txn});
  $RESULT_HASH{$txn_id} = $FORM->{txn_id};
  $RESULT_HASH{comment} = "account exists";
  $RESULT_HASH{fio} = $user_object->{fio};
  $RESULT_HASH{balance}= $deposit;
  $RESULT_HASH{address} = $user_object->{address_full};
  $RESULT_HASH{rec_sum} = $abon2;
  $RESULT_HASH{info} = $info;

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
  my $txn_id = 'osmp_txn_id';

  if ($self->{conf}{"PAYSYS_SBERBANK_ONLINE_TXN_DATE"} && $FORM->{txn_date} =~ /(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})/) {
    $main::DATE = "$1-$2-$3";
    $main::TIME = "$3-$5-$6";
  }

  _get_request_info($FORM);

  my $description = $FORM->{payment_describe} || "Сбербанк онлайн";
  # FOR EMANAT
  my %servicetype = (
    1 => 'Domofon',
    2 => 'Internet',
    3 => 'Telephone',
    4 => 'TV'
  );
  if ($FORM->{servicetype}) {
    $description = $servicetype{$FORM->{servicetype}};
  }
  my $CHECK_FIELD = $self->{conf}{"PAYSYS_SBERBANK_ONLINE_ACCOUNT_KEY"} || 'UID';

  my ($status_code, $payments_id) = main::paysys_pay({
    PAYMENT_SYSTEM    => $PAYSYSTEM_SHORT_NAME,
    PAYMENT_SYSTEM_ID => $PAYSYSTEM_ID,
    CHECK_FIELD       => $CHECK_FIELD,
    USER_ID           => $FORM->{account},
    SUM               => $FORM->{sum},
    EXT_ID            => $FORM->{txn_id},
    DATA              => $FORM,
    DATE              => "$main::DATE $main::TIME",
    CURRENCY_ISO      => $self->{conf}{"PAYSYS_SBERBANK_ONLINE_CURRENCY"},
    MK_LOG            => 1,
    PAYMENT_ID        => 1,
    DEBUG             => $self->{DEBUG},
    PAYMENT_DESCRIBE  => $description,
  });

  # Qiwi testing, check if exist param sum
  if (!$FORM->{sum}) {
    $status_code = 5;
  }

  my $status = (defined($axbills2osmp{$status_code})) ? $axbills2osmp{$status_code} : 90;

  $RESULT_HASH{result} = $status;
  $RESULT_HASH{$txn_id} = $FORM->{txn_id};
  $RESULT_HASH{ext_id} = $payments_id;
  $RESULT_HASH{comment} = "payment successful";
  $RESULT_HASH{sum} = $FORM->{sum} || '';

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
  $SETTINGS{ID} = $PAYSYSTEM_ID;
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
  main::mk_log("$request", { PAYSYS_ID => "$PAYSYSTEM_ID/$PAYSYSTEM_NAME", REQUEST => 'Request' });

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

  foreach my $k (sort keys %{ $RESULT_HASH }) {
    my $v = $RESULT_HASH->{$k};
    $results .= "<$k>".(defined $v ? $v : '')."</$k>\n";
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

  main::mk_log("$response", { PAYSYS_ID => "$PAYSYSTEM_ID/$PAYSYSTEM_NAME", REQUEST => 'Response' });

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
  shift;

  my $random = int(rand(10000));
  my %params_hash = (
    '1_CHECK'  => {
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
      result  => [],
    },
    '2_PAY'    => {
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
      result  => [],
    }
  );

  return \%params_hash;
}

1;
