package Paysys::systems::Internet_Plategka;
=head1 NAME

  Internet_Plategka

=head2 FILENAME

  Internet_Plategka.pm

=head2 VERSION

  VERSION: 0.02
  CREATE DATE: 05.06.2020
  REVISION:

=head2 Documentation

  Documentaion: http://axbills.net.ua:8090/display/AB/Internet_Plategka.pm?preview=/46334481/46334484/protocol_plategka-10.08.17%20(2).doc
=cut

use strict;
use warnings FATAL => 'all';

use AXbills::Base qw(_bp date_format convert);
use AXbills::Misc qw(load_module);
require Paysys::Paysys_Base;
use AXbills::Base qw(_bp );
use AXbills::Misc qw();
require Paysys::Paysys_Base;

use Paysys;

our $PAYSYSTEM_NAME       = 'Internet_Plategka';
our $PAYSYSTEM_SHORT_NAME = 'INT_PL';
our $PAYSYSTEM_ID         = 141;

our $PAYSYSTEM_VERSION = '0.02';

our %PAYSYSTEM_CONF = (
  PAYSYS_INTERNET_PLATEGKA_ACCOUNT_KEY   => '',
  PAYSYS_INTERNET_PLATEGKA_SECRET_CLIENT => '',
  PAYSYS_INTERNET_PLATEGKA_SECRET_SERVER => '',
  PAYSYS_INTERNET_PLATEGKA_FASTPAY       => '',
);

my ($html);
my %status_hash = (
  0   => 'Successful completion of the operation',
  1   => 'Temporary DB error',
  2   => 'Unknown request ',
  3   => 'Payer not found',
  4   => 'Wrong format',
  5   => 'Payer account is not active',
  6   => 'Unknown txt_id',
  7   => 'Payment is not allowed for technical reasons',
);

my %axbills_int_plategka = (
 0  => '0',  # ok
 1  => '1',  # Invalid time_p
 2  => '2',  # Invalid id_p
 3  => '3',  # Invalid acc or user not exist
 4  => '4',  # Invalid sum
 5  => '5',  # Invalid digital signature
 6  => '6',  #Transaction already exists
 7  => '99', #Service unavailable
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

  if($FORM->{sum}){
    my $pay_result = $self->payment($FORM);
    $pay_result->{test} = 1 if $FORM->{test};
    return $self->_show_response($pay_result);
  }
  elsif($FORM->{id_v}){
    my $cancel_result = $self->commit_pay($FORM);
    $cancel_result->{test} = 1 if $FORM->{test};
    return $self->_show_response($cancel_result);
  }
  else{
    my $check_result = $self->check($FORM);
    $check_result->{test} = 1 if $FORM->{test};
    return $self->_show_response($check_result);
  }

  return 1;
}

#**********************************************************
=head2 check() - check if user exist

  Arguments:
     %FORM
       acc     - user ID
       time_p  - time UNIX
       md5     -

  Returns:
    REF HASH
=cut
#**********************************************************
sub check {
  my ($self) = shift;
  my ($FORM) = @_;

  _get_request_info($FORM);

  my $CHECK_FIELD = $self->{conf}->{"PAYSYS_INTERNET_PLATEGKA_ACCOUNT_KEY"} || 'LOGIN';
  my %RESULT_HASH = (status => 3);

  my ($result_code, $user_object) = main::paysys_check_user({
    CHECK_FIELD        => $CHECK_FIELD,
    USER_ID            => $FORM->{acc},
    DEBUG              => $self->{DEBUG},
    SKIP_DEPOSIT_CHECK => 1
  });

  if ($user_object->{gid}) {
    $self->account_gid_split($user_object->{gid});
  }

  my $status = ($axbills_int_plategka{$result_code}) ? $axbills_int_plategka{$result_code} : 0;

  my $md5 = Digest::MD5->new();
  $md5->reset();

  my $server = $self->{conf}{"PAYSYS_INTERNET_PLATEGKA_SECRET_SERVER"};

  if ($result_code == 1) {
    my $time_v = time;
    $RESULT_HASH{time_v} = time;

    $md5->add($time_v . $server);
    my $sign = $md5->hexdigest();
    $RESULT_HASH{md5} = $sign;

    return \%RESULT_HASH;
  }

  $RESULT_HASH{status} = $status;

  my $deposit = sprintf("%.2f", $user_object->{deposit});
  my $time_v = time;
  $RESULT_HASH{time_v} = time;
  $RESULT_HASH{balance}= $deposit;
  $RESULT_HASH{number}= $user_object->{contract_id};
  $RESULT_HASH{param} = $user_object->{address_full};

  my $fio = $user_object->{fio};

  $md5->add($time_v . $fio . $server);
  my $sign = $md5->hexdigest();
  $RESULT_HASH{md5} = $sign;

  $RESULT_HASH{fio} = $fio;

  if ($result_code == 5){
    my $time_v = time;
    $RESULT_HASH{time_v} = time;

    $md5->add($time_v . $server);
    my $sign = $md5->hexdigest();
    $RESULT_HASH{md5} = $sign;

    return \%RESULT_HASH;
  }

  return \%RESULT_HASH;
}


#**********************************************************
=head2 payment() - make a payment for user

  Arguments:
     %FORM
       acc     - user ID
       sum     - amount of money
       id_p    - payment ID
       time_p  - time UNIX
       md5     -

  Returns:
    REF HASH

=cut
#**********************************************************
sub payment {
  my ($self) = shift;
  my ($FORM) = @_;

  my %RESULT_HASH;

  my $CHECK_FIELD = $self->{conf}{"PAYSYS_INTERNET_PLATEGKA_ACCOUNT_KEY"} || 'LOGIN';

  my ($result_code, $payments_id) = main::paysys_pay({
    PAYMENT_SYSTEM    => $PAYSYSTEM_SHORT_NAME,
    PAYMENT_SYSTEM_ID => $PAYSYSTEM_ID,
    CHECK_FIELD       => $CHECK_FIELD,
    USER_ID           => $FORM->{acc},
    SUM               => $FORM->{sum},
    EXT_ID            => $FORM->{id_p},
    DATA              => $FORM,
    DATE              => "$main::DATE $main::TIME",
    MK_LOG            => 1,
    PAYMENT_ID        => 1,
    DEBUG             => $self->{DEBUG},
    PAYMENT_DESCRIBE  => $FORM->{payment_describe} || "Internet Plategka Payments",
  });

  if (!$FORM->{sum}) {
    $RESULT_HASH{status} = 4;
    return \%RESULT_HASH;
  }

  my $status = ($axbills_int_plategka{$result_code}) ? $axbills_int_plategka{$result_code} : 0;

  $RESULT_HASH{status} = $status;
  $RESULT_HASH{time_v} = time;
  $RESULT_HASH{id_v} = $payments_id;

  my $md5 = Digest::MD5->new();
  $md5->reset();

  my $server = $self->{conf}{"PAYSYS_INTERNET_PLATEGKA_SECRET_SERVER"};
  my $id_v =$payments_id;
  my $time_v = time;

  $md5->add($time_v . $id_v . $server);
  my $sign = $md5->hexdigest();

  $RESULT_HASH{md5} = $sign;

  return \%RESULT_HASH;
}

#**********************************************************
=head2 commit_pay()

   Arguments:
     %FORM
       id_v    - paysys_id
       time_p  - time UNIX
       md5     -

  Returns:
    REF HASH

=cut
#**********************************************************
sub commit_pay {
  my ($self) = shift;
  my ($FORM) = @_;

  _get_request_info($FORM);

  my %RESULT_HASH;

  my $id_v = $FORM->{id_v};

  my $result = main::paysys_pay_check({
    PAYSYS_ID => $id_v
  });

  if($result == 2){
    $RESULT_HASH{status} = 0;
  }
  elsif($result == 0){
    $RESULT_HASH{status} = 6;
  }
  else{
    $RESULT_HASH{status} = 99;
  }

  my $md5 = Digest::MD5->new();
  $md5->reset();

  my $server = $self->{conf}{"PAYSYS_INTERNET_PLATEGKA_SECRET_SERVER"};
  my $time_v = time;

  $md5->add($time_v . $server);
  my $sign = $md5->hexdigest();

  $RESULT_HASH{md5} = $sign;
  $RESULT_HASH{time_v} = time;
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

  my $response = qq{<?xml version="1.0" ?>
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

  if(!$user->{$self->{conf}{PAYSYS_INTERNET_PLATEGKA_ACCOUNT_KEY}}){
    $user->pi();
  }
  my $link = $self->{conf}{PAYSYS_INTERNET_PLATEGKA_FASTPAY} . "acc=" . ($user->{$self->{conf}{PAYSYS_INTERNET_PLATEGKA_ACCOUNT_KEY}} ) . "&sum=" . ($attr->{SUM} || 0);

  return $html->tpl_show(main::_include('paysys_internet_plategka_fastpay', 'Paysys'), {LINK => $link}, { OUTPUT2RETURN => 0 });
}

1;

