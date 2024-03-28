=head1 Ckasa
  New module for Ckasa

  Documentaion:

  Date: 21.05.2019
  Update: 12.08.2019

  Version: 7.01
=cut


use strict;
use warnings;

use AXbills::Base qw(_bp load_pmodule );
use AXbills::Misc qw();
require Paysys::Paysys_Base;
package Paysys::systems::Ckasa;

use Paysys;

our $PAYSYSTEM_NAME = 'Ckasa';
our $PAYSYSTEM_SHORT_NAME = 'Ckasa';
our $PAYSYSTEM_ID = 51;
our $PAYSYSTEM_VERSION = '7.01';

our %PAYSYSTEM_CONF = (
  PAYSYS_CKASA_ACCOUNT_KEY  => '',
  PAYSYS_CKASA_PASSWORD     => '',
  PAYSYS_CKASA_REDIRECT_URL => '',
);

my ($html);
my %error_description = (
  0  => 'Успешное выполнение операции',
  1  => 'Платеж уже был проведен',
  2  => 'Платеж ожидает обработки у оператора',
  10 => 'Запрос выполнен с неразрешенного адреса',
  11 => 'Указаны не все необходимые параметры',
  12 => 'Неверный формат параметров',
  13 => 'Неверная цифровая подпись',
  20 => 'Указанный номер счета отсутствует',
  29 => 'Неверные параметры платежа.',
  30 => 'Был другой платеж с указанным номером',
  40 => 'Предварительная ошибка обработки платежа',
  41 => 'Окончательная ошибка обработки платежа',
  80 => 'Отказ на возврат платежа.',
  90 => 'Временная техническая ошибка',
  99 => 'Прочие ошибки Оператора.',
);

#my %error_description = (
#  0  => 'OK',
#  1  => 'Платеж уже был проведен',
#  2  => 'Платеж ожидает обработки у оператора',
#  10 => 'Запрос выполнен с неразрешенного адреса',
#  11 => 'Указаны не все необходимые параметры',
#  12 => 'Неверный формат параметров',
#  13 => 'SIGN NOT OK',
#  20 => 'USER NOT EXISTS',
#  29 => 'Неверные параметры платежа.',
#  30 => 'PAY_ID EXISTS',
#  40 => 'Предварительная ошибка обработки платежа',
#  41 => 'Окончательная ошибка обработки платежа',
#  80 => 'CANCEL NOT OK',
#  90 => 'SYSTEM ERROR',
#  99 => 'Прочие ошибки Оператора.',
#);

#**********************************************************
=head2 new($db, $admin, $CONF)

  Arguments:
    $db    - ref to DB
    $admin - current Web session admin
    $CONF  - ref to %conf
    $CONF->{PAYSYS_DEBUG}

  Returns:
    object

=cut
#**********************************************************
sub new {
  my $class = shift;

  my ($db, $admin, $CONF) = @_;

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $CONF,
    DEBUG => $CONF->{PAYSYS_DEBUG} || 0,
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

  $FORM->{__BUFFER} = '' if (!$FORM->{__BUFFER});
  $FORM->{__BUFFER} = AXbills::Base::urldecode($FORM->{__BUFFER});
#  print "Content-Type: text/xml\n\n";

  my $mod_return = main::load_pmodule('XML::Simple', { SHOW_RETURN => 1 });

  if ($mod_return) {
    main::mk_log($mod_return, { PAYSYS_ID => $PAYSYSTEM_NAME });
  }
  $FORM->{__BUFFER} =~ s/params=//g;
  my $_xml = eval {XML::Simple::XMLin($FORM->{__BUFFER}, ForceArray => 0, KeyAttr => 1)};

  my %request_hash = %$_xml;
  my $act = $request_hash{params}{act} || '';
  my ($params) = $FORM->{__BUFFER} =~ /<params>(.+)<\/params>/;
  my $my_sign = $self->sign($params, {FOR_VALID => 1, ACCOUNT => $request_hash{params}{account} || ''});

  my %error_sign = ();
  if ( ($my_sign ne uc($request_hash{sign})) || (!$request_hash{sign}) ) {
    $error_sign{err_code} = 13;
    $error_sign{err_text} = $error_description{13};
    return $self->_show_response(\%error_sign);
  }
  if ($act == 1) {
    my $check_result = $self->check(\%request_hash);
    $check_result->{test} = 1 if $FORM->{test};
    return $self->_show_response($check_result, { OLD_SIGN => $request_hash{sign}, ACCOUNT => $request_hash{params}{account} || '' });
  }
  elsif ($act == 2) {
    my $pay_result = $self->pay(\%request_hash);
    $pay_result->{test} = 1 if $FORM->{test};
    return $self->_show_response($pay_result, , { OLD_SIGN => $request_hash{sign}, ACCOUNT => $request_hash{params}{account} || '' });
  }
  elsif ($act == 8) {
    my $cancel_result = $self->cancel(\%request_hash);
    $cancel_result->{test} = 1 if $FORM->{test};
    return $self->_show_response($cancel_result, , { OLD_SIGN => $request_hash{sign}, ACCOUNT => $request_hash{params}{account} || '' });
  }

return 1;
}

#**********************************************************
=head2 check() - check if user exist

  Arguments:
     %FORM

  Returns:
    REF HASH
=cut
#**********************************************************
sub check {
  my ($self) = shift;
  my ($FORM) = @_;
  my $params = $FORM->{params} || q{};
  my $CHECK_FIELD = $self->{conf}{"PAYSYS_CKASA_ACCOUNT_KEY"} || 'UID';
  my %RESULT_HASH = ();

  _get_request_info($FORM->{params});

  my ($result_code, $user_object) = main::paysys_check_user({
    CHECK_FIELD        => $CHECK_FIELD,
    USER_ID            => $params->{account},
    DEBUG              => $self->{DEBUG},
    SKIP_DEPOSIT_CHECK => 1
  });

  if ($result_code == 0) {
    $RESULT_HASH{err_code} = $result_code;
    $RESULT_HASH{err_text} = $error_description{$result_code};
    $RESULT_HASH{account} = $params->{account};
    $RESULT_HASH{balance} = $user_object->{deposit};
    $RESULT_HASH{client_name} = $user_object->{fio};
  }
  else {
    $RESULT_HASH{err_code} = 20;
    $RESULT_HASH{err_text} = $error_description{20};
  }

return \%RESULT_HASH;
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
  my %RESULT_HASH = ();
  my $CHECK_FIELD = $self->{conf}{"PAYSYS_CKASA_ACCOUNT_KEY"} || 'UID';
  my $params = $FORM->{params} || q{};
  my $sum = ($params->{pay_amount}/100);

  _get_request_info($FORM->{params});

  my ($status_code, $payments_id) = main::paysys_pay({
    PAYMENT_SYSTEM    => $PAYSYSTEM_SHORT_NAME,
    PAYMENT_SYSTEM_ID => $PAYSYSTEM_ID,
    CHECK_FIELD       => $CHECK_FIELD,
    USER_ID           => $params->{account},
    SUM               => $sum,
    EXT_ID            => $params->{pay_id},
    DATA              => $params,
    DATE              => "$main::DATE $main::TIME",
    MK_LOG            => 1,
    PAYMENT_ID        => 1,
    DEBUG             => $self->{DEBUG},
    PAYMENT_DESCRIBE  => "$PAYSYSTEM_NAME Payments",
  });

  if ($status_code == 0) {
    $RESULT_HASH{err_code} = $status_code;
    $RESULT_HASH{err_text} = $error_description{$status_code};
    $RESULT_HASH{reg_id} = $payments_id;
#    $RESULT_HASH{reg_date} = "$main::DATE\T$main::TIME";
  }
  elsif ($status_code == 1) {
    $RESULT_HASH{err_code} = 20;
    $RESULT_HASH{err_text} = $error_description{20};
  }
  elsif ($status_code == 13 || $status_code == 3) {
    $RESULT_HASH{err_code} = 1;
    $RESULT_HASH{err_text} = $error_description{1};
    $RESULT_HASH{reg_id} = $payments_id;
  }
  else {
    $RESULT_HASH{err_code} = 90;
    $RESULT_HASH{err_text} = $error_description{90};
  }

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
  my $params = $FORM->{params} || q{};
  my %RESULT_HASH = ();
  my $id = $params->{pay_id} || 0;

  my $cancel_result = main::paysys_pay_cancel({
    TRANSACTION_ID => "$PAYSYSTEM_SHORT_NAME:$id",
  });

  if($cancel_result == 0){
    $RESULT_HASH{err_code} = $cancel_result;
    $RESULT_HASH{err_text} = $error_description{$cancel_result};
  }
  else{
    $RESULT_HASH{err_code} = 80;
    $RESULT_HASH{err_text} = $error_description{80};
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
    $request .= "$k => $v,\n" if ($k ne 'params');
  }
  main::mk_log("$request", { PAYSYS_ID => "$PAYSYSTEM_ID/$PAYSYSTEM_NAME", REQUEST => 'Request' });

  return $request;
}

#**********************************************************
=head2 sign($params, $attr) - create sign

  Arguments:
     FOR_VALID -
     SIGN_OLD -

  Returns:

=cut
#**********************************************************
sub sign {
  my ($self) = shift;
  my ($params, $attr) = @_;
  my $sign = q{};
  my $account = $attr->{ACCOUNT} || '';
  my $mod_return = main::load_pmodule('Digest::MD5', { SHOW_RETURN => 1 });

  if ($mod_return) {
    main::mk_log($mod_return, { PAYSYS_ID => "$PAYSYSTEM_ID/$PAYSYSTEM_NAME" });
  }

  my $md5 = Digest::MD5->new();
  $md5->reset();

  my $CHECK_FIELD = $self->{conf}{"PAYSYS_CKASA_ACCOUNT_KEY"} || 'UID';
  my ($result, $info) = main::paysys_check_user({CHECK_FIELD => $CHECK_FIELD, USER_ID => $account});

  if ($info->{gid}) {
    $self->account_gid_split($info->{gid});
  }

  my $pass = $self->{conf}{"PAYSYS_CKASA_PASSWORD"} || q{};

  if ($attr->{FOR_VALID}) {
    $md5->add($params . $pass);
  }
  else {
    $md5->add($params . $attr->{SIGN_OLD} . $pass);
  }

  $sign = uc($md5->hexdigest());

  return $sign;
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
  my ($self, $RESULT_HASH, $attr) = @_;
  my $response = '';
  my $results = '';
  my $i = 1;
  while (my ($k, $v) = each %{ $RESULT_HASH }) {
    if (ref $v eq "HASH") {
      $results .= "<$k>\n";
      while (my ($key, $value) = each %$v) {
        my ($end_key, undef) = split(" ", $key);
        $results .= "<field$i name='$key'>".(defined $value ? $value : '')."</field$i>\n";
      }
      $results .= "</$k>\n";
    }
    else {
      $results .= "<$k>".(defined $v ? $v : '')."</$k>\n";
    }
  }

  chomp($results);

  $results =~ s/\n//g;

  if ($attr->{OLD_SIGN}) {
    my $sign = $self->sign($results, {SIGN_OLD => $attr->{OLD_SIGN}, ACCOUNT => $attr->{ACCOUNT}});
    $response = qq{<?xml version="1.0" encoding="windows-1251"?><response><params>$results</params><sign>$sign</sign></response>};
  }
  else {
    $response = qq{<?xml version="1.0" encoding="windows-1251"?><response><params>$results</params></response>};
  }


  return $response if $RESULT_HASH->{test};
  print "Content-Type: text/plain\n\n" if ($self->{DEBUG} > 3);
  print "Content-Type: text/xml\n\n";
  print $response;

  main::mk_log("$response", { PAYSYS_ID => "$PAYSYSTEM_ID/$PAYSYSTEM_NAME", REQUEST => 'Response' });

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
  my $lang = $attr->{LANG};
  my %pay_params = ();

  if ($user->{GID}) {
    $self->account_gid_split($user->{GID});
  }

  if ( !$self->{conf}{PAYSYS_CKASA_PASSWORD} || !$self->{conf}{PAYSYS_CKASA_REDIRECT_URL} || !$self->{conf}{PAYSYS_CKASA_ACCOUNT_KEY}  ) {
    $main::html->message('err', $lang->{ERROR}, "Payment system has wrong configuration");
    return 0;
  }
  if (!$attr->{SUM} || $attr->{SUM} == 0) {
    $main::html->message('err', $lang->{ERROR}, "Payment sum is too small.");
    return 0;
  }
  if (!$user->{$self->{conf}{PAYSYS_CKASA_ACCOUNT_KEY}}) {
    $user = $user->info($user->{UID});
  }

  my $account = qq{Л_СЧЕТ=$user->{$self->{conf}{PAYSYS_CKASA_ACCOUNT_KEY}}};
  my $amount = 'amount=' . ($attr->{SUM} * 100);
  my $fio = qq{ФИО=$user->{FIO}};
  $pay_params{LINK} = $self->{conf}{PAYSYS_CKASA_REDIRECT_URL} . "&$account&$amount&$fio";

  return $main::html->tpl_show(main::_include('paysys_ckasa_redirect', 'Paysys'), { %pay_params }, { OUTPUT2RETURN => 0 });
}

#**********************************************************
=head2 ()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub account_gid_split {
  my $self = shift;
  my ($gid) = @_;

  if ($self->{conf}{'PAYSYS_CKASA_PASSWORD_'.$gid}) {
    $self->{conf}{PAYSYS_CKASA_PASSWORD}=$self->{conf}{'PAYSYS_CKASA_PASSWORD_'.$gid};
  }

  if ($self->{conf}{'PAYSYS_CKASA_REDIRECT_URL_'.$gid}) {
    $self->{conf}{PAYSYS_CKASA_REDIRECT_URL}=$self->{conf}{'PAYSYS_CKASA_REDIRECT_URL_'.$gid};
  }

#  if ($self->{conf}{'PAYSYS_CKASA_ACCOUNT_KEY_'.$gid}) {
#    $self->{conf}{PAYSYS_CKASA_ACCOUNT_KEY}=$self->{conf}{'PAYSYS_CKASA_ACCOUNT_KEY_'.$gid};
#  }
}

1;