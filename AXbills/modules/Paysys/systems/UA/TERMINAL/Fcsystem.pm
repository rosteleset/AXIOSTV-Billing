=head1 Fcsystem
  New module for Fcsystem payment system

  Date: 10.05.2019
  Update:03.12.2020
=cut
use strict;
use warnings;
use Encode qw(decode encode);

use AXbills::Base qw(_bp in_array);
use AXbills::Misc qw(load_module);
require Paysys::Paysys_Base;
package Paysys::systems::Fcsystem;
our $PAYSYSTEM_NAME = 'Fcsystem';
our $PAYSYSTEM_SHORT_NAME = 'Fcs';

our $PAYSYSTEM_ID = 201;

our $PAYSYSTEM_VERSION = '7.03';

my $CUSTOM_NAME = uc($PAYSYSTEM_NAME);
my $CUSTOM_ID = $PAYSYSTEM_ID;

our %PAYSYSTEM_CONF = (
  PAYSYS_FCSYSTEM_PROVIDER_ID => '',
  PAYSYS_FCSYSTEM_ACCOUNT_KEY => '',
  PAYSYS_FCSYSTEM_EXTRA_INFO  => '',
);

my %status_hash = (
  0    => 'ОК',
  10   => 'Transaction complete',
  21   => 'Account exist',
  27   => 'Transaction complete',
  80   => 'Transaction cancel',
  - 40 => 'User not exists',
  - 49 => 'Unknow Error'
);

our %lang;
#**********************************************************
=head2 new($db, $admin, $CONF)

  Arguments:
    $db    - ref to DB
    $admin - current Web session admin
    $CONF  - ref to %conf
    %ATTR  - ref to additional attributes
      CUSTOM_NAME - custom paysystem name, for inheritance
      CUSTOM_ID   - custom id, for inheritance

  Returns:
    object

  Example:
    my $Fcsystem = Fcsystem->new($db, $admin, \%conf, { %ATTR });

=cut
#**********************************************************
sub new {
  my $class = shift;

  my ($db, $admin, $CONF, $attr) = @_;

  my $self = {
    db    => $db,
    admin => $admin,
    lang  => $attr->{lang},
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

  my $command = $FORM->{cmd} || '';
#  $FORM->{account} =~ s/^0+//g if ($FORM->{account});

  if ($command eq 'check') {
    my $check_result = $self->check($FORM);
    return $self->_show_response($check_result);
  }
  elsif($command eq 'cancel'){
    my $cancel_result = $self->cancel($FORM);
    return $self->_show_response($cancel_result);
  }
  elsif($command eq 'pay'){
    my $pay_result = $self->pay($FORM);
    return $self->_show_response($pay_result);
  }
  elsif($command eq 'verify'){
    my $verify_result = $self->verify($FORM);
    return $self->_show_response($verify_result);
  }
  elsif($command eq 'balance'){

  }

  return 1;
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
=head2 check() - check if user exist

  Arguments:
     %FORM
       id - payment ID in FC-system
       cmd     - commannd
       merchant_id = fcsistema

  Returns:
    REF HASH
=cut
#**********************************************************
sub check {
  my ($self) = shift;
  my ($FORM) = @_;
  my $id     = $FORM->{id};

  my %RESULT_HASH  = (result => - 49);
  $RESULT_HASH{id} = $id;
  $RESULT_HASH{provider_time} = "$main::DATE $main::TIME";
  my $status = 0;

  _get_request_info($FORM);

  my ($transaction_id, $transaction_status) = main::paysys_pay_check({
    TRANSACTION_ID => "$CUSTOM_NAME:$id",
  });

  if ($transaction_id != 0 && $transaction_status == 2) {
    my $list = $main::Paysys->list({
      TRANSACTION_ID => "$CUSTOM_NAME:$id",
      COLS_NAME      => 1
    });

    my (undef, $info) = main::paysys_check_user({ CHECK_FIELD => 'UID', USER_ID => $list->[0]{uid} });
    if ($info->{gid}) {
      $self->account_gid_split($info->{gid});
    }
    $RESULT_HASH{provider_time} = "$main::DATE $main::TIME"; # $list->[0]->[2];
    $RESULT_HASH{provider_id} = $transaction_id;
    $RESULT_HASH{provider_id_s} = $self->{conf}{PAYSYS_FCSYSTEM_PROVIDER_ID};
    $status = 27;
  }
  else  {
    $status = - 27;
  }

  $RESULT_HASH{result} = $status;
  $RESULT_HASH{comment} = $status_hash{$RESULT_HASH{result}} if ($RESULT_HASH{result} && !$RESULT_HASH{comment});

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

  my %RESULT_HASH = ();
  my $id = $FORM->{id} || 0;
  my $provider_id = $FORM->{providerid} || 0;
  my $status = 0;

  my $cancel_result = main::paysys_pay_cancel({
    TRANSACTION_ID => "$CUSTOM_NAME:$id",
  });

  if($cancel_result == 0){
    $status       = 80;
    $RESULT_HASH{provider_id}  = $provider_id;
    $RESULT_HASH{id}  = $id;
  }
  else{
    $status = -49;
  }

  $RESULT_HASH{result} = $status;
  $RESULT_HASH{comment}= $status_hash{$RESULT_HASH{result}} if ($RESULT_HASH{result} && ! $RESULT_HASH{comment});

  return \%RESULT_HASH;
}

#**********************************************************
=head2 verify()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub verify {
  my ($self) = shift;
  my ($FORM) = @_;

  my $status = '';
  my %RESULT_HASH = ();
  my $CHECK_FIELD = $self->{conf}{PAYSYS_FCSYSTEM_ACCOUNT_KEY} || 'UID';
  my ($result, $info) = main::paysys_check_user({CHECK_FIELD => $CHECK_FIELD, USER_ID => $FORM->{account}});

  if($result == 0){
    $status = 21;
    if($self->{conf}{PAYSYS_FCSYSTEM_EXTRA_INFO}){
      my $des_field = "Поточний баланс";
      $RESULT_HASH{text} = Encode::encode("cp1251", Encode::decode("utf8", $info->{FIO})) .  Encode::encode("cp1251", Encode::decode("utf8", $des_field )) .  ": " .sprintf("%.2f", $info->{deposit});
    }
    else {
      $RESULT_HASH{text} = Encode::encode("cp1251", Encode::decode("utf8", $info->{FIO}));
    }
  }
  else{
    $status = -40;
  }

  if ($info->{gid}) {
    $self->account_gid_split($info->{gid});
  }

  $RESULT_HASH{result} = $status;
  $RESULT_HASH{provider_id_s} = $self->{conf}{PAYSYS_FCSYSTEM_PROVIDER_ID};
  $RESULT_HASH{comment}= $status_hash{$RESULT_HASH{result}} if ($RESULT_HASH{result} && ! $RESULT_HASH{comment});

  return \%RESULT_HASH;
}

#**********************************************************
=head2 pay()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub pay {
  my ($self) = shift;
  my ($FORM) = @_;

  my $CHECK_FIELD = $self->{conf}{PAYSYS_FCSYSTEM_ACCOUNT_KEY} || 'UID';
  my ($result, $info) = main::paysys_check_user({CHECK_FIELD => $CHECK_FIELD, USER_ID => $FORM->{account}});

  my %RESULT_HASH = ();
  my ($result_code, $payments_id ) = main::paysys_pay({
    PAYMENT_SYSTEM    => $CUSTOM_NAME,
    PAYMENT_SYSTEM_ID => $CUSTOM_ID,
    CHECK_FIELD       => $CHECK_FIELD,
    USER_ID           => $FORM->{account},
    SUM               => $FORM->{sum},
    EXT_ID            => $FORM->{id},
    DATA              => $FORM,
    CURRENCY          => $self->{conf}{PAYSYS_PAYNET_CURRENCY},
    MK_LOG            => 1,
    PAYMENT_ID        => 1,
    DEBUG             => 1
  });

  if($result_code == 0 || $result_code == 13){
    $RESULT_HASH{result} = 27;
    $RESULT_HASH{provider_id} = $payments_id;
  }
  elsif($result_code == 1){
    $RESULT_HASH{result} = -40;
  }
  else{
    $RESULT_HASH{result} = -49;
  }

  if ($info->{gid}) {
    $self->account_gid_split($info->{gid});
  }
  $RESULT_HASH{provider_id_s} = $self->{conf}{PAYSYS_FCSYSTEM_PROVIDER_ID};
  $RESULT_HASH{provider_time} = "$main::DATE $main::TIME";
  $RESULT_HASH{id} = $FORM->{id};
  $RESULT_HASH{comment}= $status_hash{$RESULT_HASH{result}} if ($RESULT_HASH{result} && ! $RESULT_HASH{comment});

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
        $results .= "<$key>" . (defined $value ? $value : '') . "</$end_key>\n";
      }
      $results .= "</$k>\n";
    }
    else {
      $results .= "<$k>" . (defined $v ? $v : '') . "</$k>\n";
    }
  }

  chomp($results);

  my $response = qq{<?xml version="1.0" encoding="windows-1251"?>
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
=head2 ()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub account_gid_split {
  my $self = shift;
  my ($gid) = @_;

  if ($self->{conf}{'PAYSYS_FCSYSTEM_PROVIDER_ID_'.$gid}) {
    $self->{conf}{PAYSYS_FCSYSTEM_PROVIDER_ID}=$self->{conf}{'PAYSYS_FCSYSTEM_PROVIDER_ID_'.$gid};
  }

}

1;