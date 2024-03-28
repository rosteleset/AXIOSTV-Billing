package Paysys::systems::Global_Money;
=head1 Global_Money
  New module for Global

  DOCUMENTATION:

  DATE: 19.02.2020
  UPDATE: 20.04.2020

  VERSION: 0.02

=cut

use strict;
use warnings;
use AXbills::Base qw(cmd load_pmodule);
use Paysys;

load_pmodule('JSON');
load_pmodule('Digest::SHA');

our $PAYSYSTEM_NAME = 'Global_Money';
our $PAYSYSTEM_SHORT_NAME = 'GlMon';
our $PAYSYSTEM_ID = 140;
our $PAYSYSTEM_VERSION = '0.02';

our %PAYSYSTEM_CONF = (
  PAYSYS_GLOBAL_MONEY_ACCOUNT_KEY    => '',
  PAYSYS_GLOBAL_MONEY_FASTPAY        => '',
  PAYSYS_GLOBAL_MONEY_PAYEE_ID       => '',
  PAYSYS_GLOBAL_MONEY_PAYEE_NAME     => '',
  PAYSYS_GLOBAL_MONEY_BANK_NAME      => '',
  PAYSYS_GLOBAL_MONEY_BANK_MFO       => '',
  PAYSYS_GLOBAL_MONEY_BANK_ACCOUNT   => '',
  PAYSYS_GLOBAL_MONEY_NARRATIVE_NAME => '',
  PAYSYS_GLOBAL_MONEY_PARTNER_KEY    => '',
  PAYSYS_GLOBAL_MONEY_SERVICE_KEY    => '',
  PAYSYS_GLOBAL_MONEY_SECRET_KEY     => '',
);

my ($html);
#our (@payments);

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
    lang  => $attr->{lang},
    DEBUG => $CONF->{PAYSYS_DEBUG} || 0,
  };

  if ($attr->{HTML}) {
    $html = $attr->{HTML};
  }

  bless($self, $class);

  $self->{Paysys} = Paysys->new($self->{db}, $self->{admin}, $self->{conf});

  return $self;
}


#**********************************************************
=head2 proccess(\%FORM) - function that proccessing payment
                          on paysys_check.cgi

  Arguments:
    $FORM - HASH REF to %FORM
    XML

  Returns:

=cut
#**********************************************************
sub proccess {
  my $self = shift;
  my ($form) = @_;

  my $request_body = ($form->{__BUFFER}) ? $form->{__BUFFER} : q{};

  if ($self->{DEBUG} > 2) {
    print "Content-Type: text/plain\n\n";
  }
  else {
    print "Content-Type: text/xml\n\n";
  }

  my $mod_return = load_pmodule('XML::Simple', { SHOW_RETURN => 1 });

  if ($mod_return) {
    main::mk_log($mod_return, { PAYSYS_ID => $PAYSYSTEM_NAME });
  }

  $request_body =~ s/encoding="windows-1251"//g;
  my $_xml = eval {XML::Simple::XMLin($request_body, forcearray => 1)};

  #print "\n\nREQUEST BODY: $request_body \n\n\n";
  if ($@) {
    main::mk_log("-- Content:\n" . $request_body . "\n-- XML Error:\n" . $@ . "\n--\n",
      { PAYSYS_ID => $PAYSYSTEM_NAME });
    return 0;
  }
  else {
    if ($self->{DEBUG} > 0) {
      main::mk_log($request_body, { PAYSYS_ID => $PAYSYSTEM_NAME });
    }
  }

  my %request_hash = %$_xml;

  while (my ($k, $v) = each %{$_xml}) {
    $request_hash{$k} = (ref $v eq 'ARRAY') ? $v->[0] : $v;
  }

  my $CHECK_FIELD = $self->{conf}{"PAYSYS_GLOBAL_MONEY_ACCOUNT_KEY"} || 'LOGIN';
  my $status = 0;
  my %status_hash = (
    '0'    => 'OK',
    '-6'   => 'Payment Exist',
    '-11', => 'Payment operation disable',
    '-300' => 'SQL Error',
    '-200' => 'User not found',
    '-79'  => 'Payment not found',
    '-80'  => 'Wrong Signature',
  );

  my %status_compare = (
    0  => 0,
    1  => -200,
    2  => -300,
    3  => -6,
    8  => -79,
    11 => -11,
    12 => -300
  );

  $request_body =~ s/<Sign>(\S+)<\/Sign>/<Sign><\/Sign>/g;

  if ($request_hash{Check}) {
    my $account = $request_hash{Check}{Account}->[0];
    my ($result, $user_object) = main::paysys_check_user({
      EXTRA_FIELDS => {
        CONTRACT_ID   => '_SHOW',
        CONTRACT_DATE => '_SHOW',
      },
      CHECK_FIELD  => $CHECK_FIELD,
      USER_ID      => $account,
      DEBUG        => $self->{DEBUG} || 1,
    });

    if ($status == 0) {
      if ($result == 2) {
        $status = -300;
      }
      elsif ($result == 1) {
        $status = -200;
      }
      elsif ($result == 11) {
        $status = -11;
      }
    }

    my $login = $user_object->{login} || '';
    my $fio = $user_object->{fio} || '';
    my $deposit = $user_object->{deposit} || '';
    my $contract_id = $user_object->{contract_id} || q{};
    my $contract_date = $user_object->{contract_date} || q{};

    if ($user_object->{gid}) {
      $self->account_gid_split($user_object->{gid});
    }

    my $account_info = $self->_make_account_info({
      CONTRACT_INFO => qq{# $contract_id $contract_date},
    });

    $self->global_money_response(
      "<Response>
<StatusCode>$status</StatusCode>
<StatusDetail>$status_hash{$status}</StatusDetail>
<DateTime>$main::DATE" . 'T' . "$main::TIME</DateTime>
<Sign></Sign>
<AccountInfo>
<Login>$login</Login>
<Name>" . $fio . " $contract_id $contract_date</Name>
<Deposit>$deposit</Deposit>
</AccountInfo>
$account_info
</Response>"
    );

    return 1;
  }
  elsif ($request_hash{Payment}) {
    my $amount = $request_hash{Payment}{Amount}[0];
    my $account = $request_hash{Payment}{Account}[0];
    my $order_id = $request_hash{Payment}{OrderId}[0];
    my $service_id = $request_hash{Payment}{ServiceId}[0];

    my ($check_result) = main::paysys_check_user({
      EXTRA_FIELDS => {
        CONTRACT_ID   => '_SHOW',
        CONTRACT_DATE => '_SHOW',
      },
      CHECK_FIELD  => $CHECK_FIELD,
      USER_ID      => $account,
      DEBUG        => $self->{DEBUG} || 1,
    });

    if ($check_result == 1 || $check_result == 2) {
      $self->global_money_response(
        "<Response>
  <StatusCode>-200</StatusCode>
  <StatusDetail>$status_hash{-200}</StatusDetail>
  <DateTime>$main::DATE" . 'T' . "$main::TIME</DateTime>
<Sign></Sign>
</Response>"
      );
      return 0;
    }
    elsif ($check_result == 11) {
      $self->global_money_response(
        "<Response>
  <StatusCode>-11</StatusCode>
  <StatusDetail>$status_hash{-11}</StatusDetail>
  <DateTime>$main::DATE" . 'T' . "$main::TIME</DateTime>
<Sign></Sign>
</Response>"
      );
      return 0;
    }

    my %DATA = (
      AMOUNT     => $amount,
      ACCOUNT    => $account,
      ORDER_ID   => $order_id,
      SERVICE_ID => $service_id,
    );

    my ($status_code, $payments_id) = main::paysys_pay({
      PAYMENT_SYSTEM    => $PAYSYSTEM_SHORT_NAME,
      PAYMENT_SYSTEM_ID => $PAYSYSTEM_ID,
      CHECK_FIELD       => $CHECK_FIELD,
      USER_ID           => $account,
      SUM               => $amount,
      EXT_ID            => $order_id,
      DATA              => \%DATA,
      DATE              => "$main::DATE $main::TIME",
      MK_LOG            => 1,
      PAYMENT_ID        => 1,
      ERROR             => 1,
      DEBUG             => $self->{DEBUG},
      PAYMENT_DESCRIBE  => $form->{payment_describe} || 'Global Money',
    });

    if ($payments_id && $status_code == 1) {
      $self->global_money_response(
        "<Response>
<StatusCode>0</StatusCode>
<StatusDetail>$status_hash{0}</StatusDetail>
<DateTime>$main::DATE" . 'T' . "$main::TIME</DateTime>
<Sign></Sign>
<PaymentId>$payments_id</PaymentId>
</Response>"
      );
    }
    else {
      $self->global_money_response(
        "<Response>
  <StatusCode>-6</StatusCode>
  <StatusDetail>$status_hash{-6}</StatusDetail>
  <DateTime>$main::DATE" . 'T' . "$main::TIME</DateTime>
<Sign></Sign>
<PaymentId></PaymentId>
</Response>"
      );
    }
  }
  elsif ($request_hash{Confirm}) {
    my $payment_id = $request_hash{Confirm}{PaymentId}[0];
    my $paysys_status = main::paysys_pay({
      PAYMENT_SYSTEM    => $PAYSYSTEM_SHORT_NAME,
      PAYMENT_SYSTEM_ID => $PAYSYSTEM_ID,
      SUM               => 0,
      PAYSYS_ID         => $payment_id
    });

    my $pay_info = main::paysys_info({ PAYSYS_ID => $payment_id });

    my $sum = $pay_info->{SUM};
    my $order_date = $pay_info->{DATETIME};
    $order_date =~ s/ /T/;

    $status = ($status_compare{$paysys_status}) ? $status_compare{$paysys_status} : 0;

    $self->global_money_response(
      "<Response>
<StatusCode>$status</StatusCode>
<StatusDetail>$status_hash{$status}</StatusDetail>
<DateTime>$main::DATE" . 'T' . "$main::TIME</DateTime>
<Sign></Sign>
<OrderDate>$order_date</OrderDate>
<Parameters>
<Parameter1>$sum</Parameter1>
</Parameters>
</Response>"
    );
  }
  elsif ($request_hash{Cancel}) {
    my $payment_id = $request_hash{Cancel}{PaymentId}[0];
    #    my $service_id = $request_hash{Cancel}{ServiceId}[0];

    my $result = main::paysys_pay_cancel({
      PAYSYS_ID => $payment_id
    });

    if ($result == 0 || $result == 10) {
      $status = 0;
    }

    $self->global_money_response(
      "<Response>
<StatusCode>$status</StatusCode>
<StatusDetail>$status_hash{$status}</StatusDetail>
<DateTime>$main::DATE" . 'T' . "$main::TIME</DateTime>
<Sign></Sign>
<CancelDate>" . $main::DATE . 'T' . "$main::TIME</CancelDate>
</Response>"
    );
  }
  elsif ($request_hash{Balance}) {
    my $balance = $request_hash{Balance}{PaymentId}[0];
    my $PAY_DATE = $request_hash{DateTime};

    my $payments_extid_list = "GLMon:*";

    my $Payments = Payments->new($self->{db}, $self->{admin}, $self->{conf});
    my $payments_list = $Payments->list({
      #DATE           => $PAY_DATE,
      SUM            => '_SHOW',
      DATETIME       => '_SHOW',
      EXT_ID         => $payments_extid_list,
      COLS_NAME      => 1,
    });

    my $results = '';
    foreach my $line (@$payments_list) {
      $results += $line->{sum};
    }

    $self->global_money_response(
      "<Response>
<StatusCode>$status</StatusCode>
<StatusDetail>$status_hash{$status}</StatusDetail>
<DateTime>$PAY_DATE</DateTime>
<Sign></Sign>
<Balance>$results</Balance>
</Response>"
    );
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
=head2 easysoft_response($response)

  Arguments:
    $response

=cut
#**********************************************************
sub global_money_response {
  my $self = shift;
  my ($response) = @_;

  $response =~ s/[\r\n]//g;

  print $response;

  $self->{RESPONSE}=$response;

  main::mk_log("$response", { PAYSYS_ID => "Answer to $PAYSYSTEM_NAME" }) if ($self->{DEBUG} > 0);

  return 0;
}

#**********************************************************
=head2 account_gid_split($gid)

  Arguments:
     $gid

  Returns:

=cut
#**********************************************************
sub account_gid_split {
  my $self = shift;
  my ($gid) = @_;

  foreach my $param (keys %PAYSYSTEM_CONF) {
    if ($self->{conf}{$param . '_' . $gid}) {
      $self->{conf}{$param} = $self->{conf}{$param . '_' . $gid};
    }
  }
}


#**********************************************************
=head2 _make_account_info($attr)

  Arguments:
    $attr -

  Returns:

=cut
#**********************************************************
sub _make_account_info {
  my $self = shift;
  my ($attr) = @_;

  my $account_info = qq{};
  my $contract_info = $attr->{CONTRACT_INFO} || q{};
  my $payee_id = $self->{conf}{"PAYSYS_GLOBAL_MONEY_PAYEE_ID"} || q{};
  my $payee_name = $self->{conf}{"PAYSYS_GLOBAL_MONEY_PAYEE_NAME"} || q{};
  my $bank_name = $self->{conf}{"PAYSYS_GLOBAL_MONEY_BANK_NAME"} || q{};
  my $bank_mfo = $self->{conf}{"PAYSYS_GLOBAL_MONEY_BANK_MFO"} || q{};
  my $bank_account = $self->{conf}{"PAYSYS_GLOBAL_MONEY_BANK_ACCOUNT"} || q{};
  my $narrative_name = $self->{conf}{"PAYSYS_GLOBAL_MONEY_NARRATIVE_NAME"} || q{};

  if ($contract_info) {
    $narrative_name =~ s/\%CONTRACT_INFO\%/$contract_info/g;
  }

  my ($year, $month, $day) = split("-", $main::DATE);
  $narrative_name =~ s/\%CUR_DATE\%/$day\.$month\.$year/g;

  $account_info = qq{<BankingDetails><Payee><Id>$payee_id</Id><Name>$payee_name</Name><Bank><Name>$bank_name</Name><Mfo>$bank_mfo</Mfo><Account>$bank_account</Account></Bank>}
    . qq{</Payee><Narrative><Name>$narrative_name</Name><Vat>0</Vat></Narrative></BankingDetails>};

  return $account_info;
}

#**********************************************************
=head2 report($attr)

=cut
#**********************************************************
sub report{
  my $self = shift;
  my ($attr) = @_;

  $html = $attr->{HTML};
  my $lang = $attr->{LANG};

  my $payments_extid_list = "GLMon:*";

  my $Paysys = Paysys->new($self->{db}, $self->{admin}, $self->{conf});
  my $Payments = Payments->new($self->{db}, $self->{admin}, $self->{conf});
  my $payments_list = $Payments->list({
    #DATE           => $PAY_DATE,
    SUM            => '_SHOW',
    DATETIME       => '_SHOW',
    LOGIN          => '_SHOW',
    EXT_ID         => $payments_extid_list,
    COLS_NAME      => 1,
  });

  my $table = $html->table(
    {
      width      => '100%',
      caption    => "Global_money",
      cols_align => [ 'right', 'right', 'right', 'right', 'right' ],
      title      =>
        [ "#", "UID", "$lang->{LOGIN}", "$lang->{SUM}", "$lang->{DATE}", "ID"],
      DATA_TABLE => 1,
    }
  );

  foreach my $payment (@$payments_list){
    $table->addrow($payment->{id}, $payment->{uid}, $payment->{login}, $payment->{sum}, $payment->{datetime}, $payment->{ext_id});
  }

  print $table->show();

  return 1;
}
#**********************************************************
=head2 user_portal($user, $attr)

  Arguments:
     $user,
     $attr

  Returns:

=cut
#**********************************************************
sub user_portal {
  my $self = shift;
  my ($user, $attr) = @_;

  if(!$user->{$self->{conf}{PAYSYS_GLOBAL_MONEY_ACCOUNT_KEY}}){
    $user->pi();
  }
  my $link = $self->{conf}{PAYSYS_GLOBAL_MONEY_FASTPAY} . "&acc=" . ($user->{$self->{conf}{PAYSYS_GLOBAL_MONEY_ACCOUNT_KEY}} ) . "&amount=" . ($attr->{SUM} || 0);

  return $html->tpl_show(main::_include('paysys_global_money_fastpay', 'Paysys'), {LINK => $link}, { OUTPUT2RETURN => 0 });
}


1;