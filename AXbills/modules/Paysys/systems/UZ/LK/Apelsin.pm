package Paysys::systems::Apelsin;
=head1 Apelsin
  A module for Apelsin (Kapital Bank) payment system

  Date: 11.02.2020
  UPDATE: 20.04.2020
  
  VERSION: 7.05
  
=cut

use strict;
use warnings;

use AXbills::Base qw(_bp in_array);
use AXbills::Misc qw(load_module);
require Paysys::Paysys_Base;

our $PAYSYSTEM_NAME = 'Apelsin';
our $PAYSYSTEM_SHORT_NAME = 'Apelsin';

our $PAYSYSTEM_ID = 143;

our $PAYSYSTEM_VERSION = '7.04';

my $CUSTOM_NAME = uc($PAYSYSTEM_NAME);
my $CUSTOM_ID   = $PAYSYSTEM_ID;

our %PAYSYSTEM_CONF = (
  "PAYSYS_NAME_ACCOUNT_KEY"  => '',
  "PAYSYS_NAME_CASH_ID"      => '',
  "PAYSYS_NAME_CURRENCY"     => '',
  "PAYSYS_NAME_EXT_PARAMS"   => '',
  "PAYSYS_NAME_EXTRA_INFO"   => '',
  "PAYSYS_NAME_LOGIN"        => '',
  "PAYSYS_NAME_PASSWD"       => '',
  "PAYSYS_NAME_REDIRECT_URL" => '',
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
  12 => 1,   # deadlock in payment
  13 => '0', # Paysys exist transaction
  30 => 4,   # No input
  #  => 90,  #Payments error
);

my $html;

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
  # AXbills::Base::_bp('', $FORM, {HEADER => 1});
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
  my $txn_id = 'osmp_txn_id';

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

  if (!$self->{conf}{PAYSYS_PEGAS} && !$self->{conf}{"PAYSYS_" . $CUSTOM_NAME . "_EXT_PARAMS"}) {
    $RESULT_HASH{$txn_id} = $FORM->{txn_id};
    $RESULT_HASH{prv_txn} = $FORM->{prv_txn} if ($FORM->{prv_txn});
    $RESULT_HASH{comment} = "Balance: $user_object->{deposit} $user_object->{fio} " if ($status == 0);
  }
  #For pegas
  elsif ($self->{conf}{PAYSYS_PEGAS}) {
    $RESULT_HASH{$txn_id} = $FORM->{txn_id};
    $RESULT_HASH{prv_txn} = $FORM->{prv_txn} if ($FORM->{prv_txn});
    $RESULT_HASH{balance} = "$user_object->{deposit}";
    $RESULT_HASH{fio} = "$user_object->{fio}";
  }
  #Use Extra params
  elsif ($self->{conf}{"PAYSYS_" . $CUSTOM_NAME . "_EXT_PARAMS"}) {
    if ($CUSTOM_ID == 99 || $CUSTOM_ID == 67) {
      my @arr = split(/,[\r\n\s]?/, $self->{conf}{"PAYSYS_" . $CUSTOM_NAME . "_EXT_PARAMS"});
      my $i = 1;
      foreach my $param  (@arr) {
        $RESULT_HASH{'fields'}{"field" . $i . " name='$param'"} = $FORM->{$param} || $user_object->{$param};
        $i++;
      }
    }
    #for million
    elsif($CUSTOM_ID == 193){
      my @arr = split(/,[\r\n\s]?/, $self->{conf}{"PAYSYS_" . $CUSTOM_NAME . "_EXT_PARAMS"});
      my $add_info = '';
      foreach my $param  (@arr) {
        $add_info .= "||" if ($add_info);
        $add_info .= $FORM->{$param} || $user_object->{$param};
      }
      $RESULT_HASH{addinfo} = $add_info;
      $RESULT_HASH{$txn_id} = $FORM->{txn_id};
    }
    else {
      my @arr = split(/,[\r\n\s]?/, $self->{conf}{"PAYSYS_" . $CUSTOM_NAME . "_EXT_PARAMS"});
      foreach my $param  (@arr) {
        $RESULT_HASH{$param} = $FORM->{$param} || $user_object->{$param};
      }
      # add 'osmp_txn _id' param with txn_id value
      $RESULT_HASH{$txn_id} = $FORM->{txn_id};
    }
  }
  # extra info tag
  if ($self->{conf}{"PAYSYS_" . $CUSTOM_NAME . "_EXTRA_INFO"}) {
    $RESULT_HASH{'extra_info'}{'deposit'} = $user_object->{'deposit'};
    $RESULT_HASH{'extra_info'}{'fee'} = $user_object->{'fee'};
    if (main::in_array('Dv', \@main::MODULES)) {
      main::load_module('Dv');
      my ($message, undef) = dv_warning({ USER => $user_object });
      my ($date, undef) = (defined $message && $message ne '') ? split("\n", $message) : ('no date', '');
      ($RESULT_HASH{'extra_info'}{'next_fee_date'}) = $date =~ /\((\d{4}-\d{2}-\d{2})\)/g;
    }
  }

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
  $RESULT_HASH{osmp_txn_id} = $txn_id;

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
  #print "Content-Length: " . length($response) . "\n";
  print "Content-Type: text/plain\n\n" if ($self->{DEBUG} > 1);
  print "Content-Type: text/xml\n\n";
  print $response;
  #$| = 1;

  main::mk_log("$response", { PAYSYS_ID => "$CUSTOM_ID/$CUSTOM_NAME", REQUEST => 'Response' });

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
  my $CHECK_FIELD = $self->{conf}{"PAYSYS_" . $CUSTOM_NAME . "_ACCOUNT_KEY"} || 'UID';
  my $form_url = 'https://oplata.kapitalbank.uz';

  return $html->tpl_show(main::_include('paysys_apelsin_add', 'Paysys'), {
    AMOUNT         => $attr->{SUM} * 100,
    CASH_ID        => $self->{conf}{"PAYSYS_" . $CUSTOM_NAME . "_CASH_ID"},
    DESCRIBE	   => $attr->{DESCRIBE},
    REDIRECT_URL   => $self->{conf}{"PAYSYS_" . $CUSTOM_NAME . "_REDIRECT_URL"},
    URL            => $form_url,
    USER_ID        => $user->{$CHECK_FIELD},
  }, { OUTPUT2RETURN => 0 });
}

1;
