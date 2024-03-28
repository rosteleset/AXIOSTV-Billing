=head1 Cyberplat
  New module for Cyberplat payment system

  Date: 04.06.2019
=cut
use strict;
use warnings FATAL => 'all';

use AXbills::Base qw(_bp in_array);
use AXbills::Misc qw(load_module);
use Crypt::OpenSSL::RSA;
use Digest::SHA qw(sha256_hex);

require Paysys::Paysys_Base;


package Paysys::systems::Cyberplat;

our $PAYSYSTEM_NAME = 'Cyberplat';
our $PAYSYSTEM_SHORT_NAME = 'CB';

our $PAYSYSTEM_ID = 70;

our $PAYSYSTEM_VERSION = '7.00';

our %PAYSYSTEM_CONF = (
  "PAYSYS_CYBERPLAT_ACCOUNT_KEY" => '',
);

our $DATE;

my %status_hash = (
  0   => 'Success',
  14  => 'Wrong client indentifier',
  2   => 'User not exist', #'Failed witness a signature',
  6   => 'Payment not found',
  7   => 'Payments deny',
  3  => 'wrong sum',
  13  => 'Double request',
  10  => 'Payment canceled',
  9   => 'Key Info mismatch',
  79  => 'Счёт абонента не активен',
  -3  => 'Unknown error',
  -4  => 'Invalid signature',
  300 => 'Unknown error',
);

my %axbills2osmp = (
  0  => 0, # Ok
  1  => 2, # Not exist user
  2  => 0,
  5  => 12, # wrong sum
  7  => 10,
  8  => 9,
  10 => 9,
  11 => 13,
  13 => '0', # Paysys exist transaction
  30 => 14,  # No input
  90 => 2,   #Payments error
);

my $CUSTOM_NAME = uc($PAYSYSTEM_NAME);
my $CUSTOM_ID = $PAYSYSTEM_ID;

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
  if ($FORM->{action} && $FORM->{action} eq 'check') {
    my $check_result = $self->check($FORM);
    $check_result->{test} = 1 if $FORM->{test};
    return $self->_show_response($check_result);
  }
  elsif ($FORM->{action} && $FORM->{action} eq 'payment') {
    my $pay_result = $self->pay($FORM);
    $pay_result->{test} = 1 if $FORM->{test};
    return $self->_show_response($pay_result);
  }
  elsif ($FORM->{action} && $FORM->{action} eq 'cancel') {
    my $cancel_result = $self->cancel($FORM);
    $cancel_result->{test} = 1 if $FORM->{test};
    return $self->_show_response($cancel_result);
  }
  elsif ($FORM->{action} && $FORM->{action} eq 'status') {
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
       number  - user ID
       amount  - amount of money
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

    my %RESULT_HASH = (code => -4);
  if($FORM->{amount}  > 0) {
    my ($message) = $FORM->{__BUFFER} =~ /(.*?)&sign/;

    if (check_sign($FORM->{sign}, $message)) {
      my $CHECK_FIELD = $self->{conf}{"PAYSYS_" . $CUSTOM_NAME . "_ACCOUNT_KEY"} || 'UID';

      my ($result_code, $user_object) = main::paysys_check_user({
        CHECK_FIELD        => $CHECK_FIELD,
        USER_ID            => $FORM->{number},
        DEBUG              => $self->{DEBUG},
        SKIP_DEPOSIT_CHECK => 1
      });

      $result_code = 4 if($FORM->{receipt} && $FORM->{receipt} =~ /[a-zA-Zа-яА-Я_-]/);
      $result_code = -2 if(($FORM->{type}) < 0);
      my $status = ($axbills2osmp{$result_code}) ? $axbills2osmp{$result_code} : $result_code;

      $RESULT_HASH{code} = $status;

      if ($result_code == 11) {
        $RESULT_HASH{disable_paysys} = 1;
      }
    }
  } else {
    $RESULT_HASH{code} = 3;
  }
  $RESULT_HASH{message} = $status_hash{ $RESULT_HASH{code} } if (defined $RESULT_HASH{code} && !$RESULT_HASH{message});

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

  my %RESULT_HASH = (code => 300);
  if($FORM->{date}){
    if($FORM->{date} =~ /[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}/){}else {
      $RESULT_HASH{code} = 5;
      $RESULT_HASH{message} = $status_hash{ $RESULT_HASH{code} } if (defined $RESULT_HASH{code} && !$RESULT_HASH{message});
      return \%RESULT_HASH;
    }
  }
  unless ($FORM->{number} && $FORM->{type} && $FORM->{receipt} && $FORM->{amount}) {
    $RESULT_HASH{code} = 6;
    $RESULT_HASH{message} = $status_hash{ $RESULT_HASH{code} } if (defined $RESULT_HASH{code} && !$RESULT_HASH{message});
    return \%RESULT_HASH;
  }
  _get_request_info($FORM);
  my ($status_code, $payments_id);
  $status_code = 4 if($FORM->{receipt} =~ /[a-zA-Zа-яА-Я_-]/);
  $status_code = -2 if(($FORM->{type} || -1) < 0);
  if(!$status_code) {
    if ($FORM->{amount} > 0) {
      my $CHECK_FIELD = $self->{conf}{"PAYSYS_" . $CUSTOM_NAME . "_ACCOUNT_KEY"} || 'UID';

      ($status_code, $payments_id) = main::paysys_pay({
        PAYMENT_SYSTEM    => $PAYSYSTEM_SHORT_NAME,
        PAYMENT_SYSTEM_ID => $CUSTOM_ID,
        CHECK_FIELD       => $CHECK_FIELD,
        USER_ID           => $FORM->{number},
        SUM               => $FORM->{amount},
        DATA              => $FORM,
        EXT_ID            => $FORM->{receipt},
        DATE              => "$main::DATE $main::TIME",
        CURRENCY_ISO      => $self->{conf}{"PAYSYS_" . $CUSTOM_NAME . "_CURRENCY"},
        MK_LOG            => 1,
        PAYMENT_ID        => 1,
        DEBUG             => $self->{DEBUG},
        PAYMENT_DESCRIBE  => $FORM->{payment_describe} || "$CUSTOM_NAME Payments",
      });
    }
    else {
      $status_code = 3;
    }
  }

  my $status = (defined($axbills2osmp{$status_code})) ? $axbills2osmp{$status_code} : $status_code;
  $RESULT_HASH{code} = $status;
  $RESULT_HASH{authcode} = $payments_id;
  $RESULT_HASH{message} = $status_hash{ $RESULT_HASH{code} } if (defined $RESULT_HASH{code} && !$RESULT_HASH{message});
  $RESULT_HASH{date} = "$main::DATE" . 'T' . "$main::TIME";

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

  my %RESULT_HASH = (code => 300);
  unless ($FORM->{receipt}) {
    $RESULT_HASH{message} = $status_hash{ $RESULT_HASH{code} } if (defined $RESULT_HASH{code} && !$RESULT_HASH{message});
    $RESULT_HASH{code} = 6;
    return \%RESULT_HASH;
  }
  my ($cancel_result, $authcode) = main::paysys_pay_cancel({
    TRANSACTION_ID     => "$PAYSYSTEM_SHORT_NAME:$FORM->{receipt}",
    RETURN_CANCELED_ID => 1,
  });
  $cancel_result = 4 if($FORM->{receipt} =~ /[a-zA-Zа-яА-Я_-]/);
  $cancel_result = -2 if($FORM->{type} && $FORM->{type} < 0);
  my $status = ($axbills2osmp{$cancel_result}) ? $axbills2osmp{$cancel_result} : $cancel_result;

  $RESULT_HASH{code} = $status;
  $RESULT_HASH{authcode} = $authcode;

  $RESULT_HASH{message} = $status_hash{ $RESULT_HASH{code} } if (defined $RESULT_HASH{code} && !$RESULT_HASH{message});

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

  my %RESULT_HASH = (code => 300);
  unless ($FORM->{receipt}) {
    $RESULT_HASH{message} = $status_hash{ $RESULT_HASH{code} } if (defined $RESULT_HASH{code} && !$RESULT_HASH{message});
    $RESULT_HASH{code} = 6;
    return \%RESULT_HASH;
  }
  my ($id, $paysys_status) = main::paysys_pay_check({
    TRANSACTION_ID => "$PAYSYSTEM_SHORT_NAME:$FORM->{receipt}",
    TOTAL          => 1
  });
    $paysys_status = 7 if(!$paysys_status);
    $paysys_status = -2 if ($FORM->{type} && $FORM->{type} < 0);
    $paysys_status = 6 if ($paysys_status == 0);
    $paysys_status = 6 if ($paysys_status == 3);
    $paysys_status = 4 if ($FORM->{receipt} =~ /[a-zA-Zа-яА-Я_-]/);
  my $status = ($axbills2osmp{$paysys_status}) ? $axbills2osmp{$paysys_status} : $paysys_status;

  $RESULT_HASH{code} = $status;
  $RESULT_HASH{authcode} = $id if($id);
  $RESULT_HASH{message} = $status_hash{ $RESULT_HASH{code} } if (defined $RESULT_HASH{code} && !$RESULT_HASH{message});

  return \%RESULT_HASH;
}


#***********************************************************
=head2 get_request_info() - make a log

=cut
#***********************************************************
sub _get_request_info {
  my ($FORM) = @_;
  my $request = '';

  while (my ($k, $v) = each %{$FORM}) {
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
  while (my ($k, $v) = each %{$RESULT_HASH}) {
    if (ref $v eq "HASH") {
      $results .= "<$k>";
      while (my ($key, $value) = each %$v) {
        my ($end_key, undef) = split(" ", $key);
        $results .= "<$key>" . (defined $value ? $value : '') . "</$end_key>";
      }
      $results .= "</$k>";
    }
    else {
      $results .= "<$k>" . (defined $v ? $v : '') . "</$k>";
    }
  }

  chomp($results);

  my $response_no_sign = qq{<?xml version="1.0" encoding="windows-1251"?><response>$results</response>};

  my $sing = generate_sign($response_no_sign);

  my $response = qq{<?xml version="1.0" encoding="windows-1251"?><response>$results<sign>$sing</sign></response>};

  return $response if $RESULT_HASH->{test};
  print "Content-Type: text/plain\n\n" if ($self->{DEBUG} > 1);
  print "Content-Type: text/xml\n\n";
  print $response;

  main::mk_log("$response", { PAYSYS_ID => "$CUSTOM_ID/$CUSTOM_NAME", REQUEST => 'Response' });

  return $response;
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
=head2 has_test()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub test {
  return 'HELLO';
}

#**********************************************************
=head2 read_file($path_to_file)

  Arguments:
     $path_to_file

  Returns:
    $content or 0 if error
=cut
#**********************************************************
sub read_file {
  my $path_to_file = shift;

  my $content = '';
  open(my $fh, '<', $path_to_file) or return 0;

  while (my $row = <$fh>) {
    $content .= $row;
  }

  return $content;
}


#**********************************************************
=head2 check_sign($sign_string, $message)

  Arguments:
     $sign_string
     $message

  Returns:
    1 or 0

=cut
#**********************************************************
sub check_sign {
  my $sign_string = shift;
  my $message = shift;
  return 0 unless ($sign_string && $message);

  my $signature_bin = pack('H*', $sign_string);
  my $public = read_file($main::base_dir . 'Certs/cyberplat_public.pem');

  return 0 if (!$public);

  my $rsa_pub = Crypt::OpenSSL::RSA->new_public_key($public);

  $rsa_pub->use_sha256_hash();


  return 1 if ($rsa_pub->verify($message, $signature_bin));
  return 0;
}

#**********************************************************
=head2 generate_sign($message)

  Arguments:
     $message

  Returns:
    $signature_hex

=cut
#**********************************************************
sub generate_sign {
  my $message = shift;

  my $private = read_file($main::base_dir . 'Certs/cyberplat_private.pem');

  my $rsa_private = Crypt::OpenSSL::RSA->new_private_key($private);
  $rsa_private->use_sha256_hash();

  my $signature = $rsa_private->sign($message);
  my $signature_hex = unpack("H*", $signature);

  return $signature_hex;
}

1;
