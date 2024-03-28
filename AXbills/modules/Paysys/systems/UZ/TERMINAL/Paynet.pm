=head1 Paynet

  New module for Paynet

  Documentaion: https://help.paycom.uz/ru/metody-merchant-api

  Date: 15.04.2018
  Change Date: 21.01.2021

  Version: 8.05

=cut

use strict;
use warnings;

use AXbills::Base qw(_bp load_pmodule);
use AXbills::Misc qw();
use Payments;
require Paysys::Paysys_Base;

package Paysys::systems::Paynet;
our $PAYSYSTEM_NAME = 'Paynet';
our $PAYSYSTEM_SHORT_NAME = 'Paynet';
our $PAYSYSTEM_ID = 76;

our $PAYSYSTEM_VERSION = '8.05';

my $CUSTOM_NAME = uc($PAYSYSTEM_NAME);
my $CUSTOM_ID   = $PAYSYSTEM_ID;

our %PAYSYSTEM_CONF = (
  PAYSYS_NAME_USERNAME    => '',
  PAYSYS_NAME_PASSWORD    => '',
  PAYSYS_NAME_ACCOUNT_KEY => '',
  PAYSYS_NAME_CURRENCY    => '',
);

my %axbills2paynet = (
  0  => 0, #ok
  1  => 9, #not exist user
  2  => 8, #sql error
  3  => 7, #dublicate payment
  5  => '', #wrong sum
  6  => 10, #small sum
  7  => '', #large sum
  8  => '11', #Transaction not found
  9  => 201, #Payment exist
  10 => '', #Payment not exist
  11 => '501', #Paysys disable
  12 => 102, # Paysys deadlock
  13 => '', #Payment exist
  17 => '11',
);

my $payments;
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

  $payments = Payments->new($self->{db}, $self->{admin}, $self->{conf});

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
=head2 proccess()

=cut
#**********************************************************
sub proccess {
  my $self = shift;
  my ($FORM) = @_;

  my @result_array = ();
  my $mod_return = AXbills::Base::load_pmodule('XML::Simple', { SHOW_RETURN => 1 });

  if($mod_return) {
    main::mk_log($mod_return, { PAYSYS_ID => "$CUSTOM_ID/$CUSTOM_NAME", SHOW => 1 });
  }

  my $timezone = POSIX::strftime( "%z", localtime);
  $timezone = join(':', substr($timezone, 0, 3), substr($timezone, 3, 2));

  $FORM->{__BUFFER} = '' if (!$FORM->{__BUFFER});
  $FORM->{__BUFFER} =~ s/data=//;

  my $_xml = eval { XML::Simple::XMLin("$FORM->{__BUFFER}", forcearray => 1) };

  my %request_params = ();

  if ($@) {
    print "Content-Type: text/plain\n\n";
    my $content = $FORM->{__BUFFER};
    print "XML Error";
    main::mk_log("Error xml!\n".$content, { PAYSYS => 'Paynet' });
    open(my $fh, '>>', "/usr/axbills/var/log/paysys_xml.log") or die "Can't open file 'paysys_xml.log' $!\n";
    print $fh "----\n";
    print $fh $content;
    print $fh "\n----\n";
    print $fh $@;
    print $fh "\n----\n";
    close($fh);

    if ($self->{DEBUG} > 3) {
      print $content;
      print "\n\n";
      print $@;
      print "\n";
    }

    return 0;
  }

  my %request_hash = ();
  my $request_type = '';

  while (my ($k, undef) = each %{ $_xml->{'soapenv:Body'}->[0] }) {
    $request_type = $k;
  }

  if ($self->{DEBUG} > 1) {
    print "\n-- $request_type --\n";
  }

  my $prefix_request_type = $request_type;
  if ($prefix_request_type =~ /([a-z0-9]+:).*/) {
    $prefix_request_type = $1;
  }

  my $short_request_type = $request_type;
  $short_request_type =~ s/[a-z0-9]+://;
  my $status;

  $request_hash{'username'} = $_xml->{'soapenv:Body'}->[0]->{$request_type}->[0]->{username}->[0];
  $request_hash{'password'} = $_xml->{'soapenv:Body'}->[0]->{$request_type}->[0]->{password}->[0];

  if (!$request_hash{'username'} || !$request_hash{'password'}) {
    paynet_msg(
      '212',
      $short_request_type,
      $prefix_request_type,
      {
        REQUEST_TYPE => $request_type,
        RESULT       => $request_type
      }
    );
    return 0;
  }
  elsif ($request_hash{'username'} ne $self->{conf}{'PAYSYS_' . $CUSTOM_NAME . '_USERNAME'}) {
    paynet_msg(
      '412',
      $short_request_type,
      $prefix_request_type,
      {
        RESPONSE => $request_type,
        RESULT   => $request_type
      }
    );
    return 0;
  }
  elsif ($request_hash{'password'} ne $self->{conf}{'PAYSYS_' . $CUSTOM_NAME . '_PASSWORD'}) {
    paynet_msg(
      '412',
      $short_request_type,
      $prefix_request_type,
      {
        RESPONSE => $request_type,
        RESULT   => $request_type
      }
    );
    return 0;
  }
  elsif ($short_request_type eq 'CancelTransactionArguments') {
    #my $service_id     = $_xml->{'soapenv:Body'}->[0]->{$request_type}->[0]->{serviceId}->[0];
    my $transaction_id = $_xml->{'soapenv:Body'}->[0]->{$request_type}->[0]->{transactionId}->[0];

    my $result_code = main::paysys_pay_cancel({
      TRANSACTION_ID => "$CUSTOM_NAME:$transaction_id"
    });

    %axbills2paynet = (
      0  => 0, #ok
      2  => 1, #sql error
      3  => 7, #dublicate payment
      6  => 10, #small sum
      8  => 21, #Transaction not found
      10 => 202, #Transaction already canceled
      11 => '501', #Paysys disable
      12 => '11'
    );
    
    $status = ($axbills2paynet{$result_code}) ? $axbills2paynet{$result_code} : 0;

    cancel_transaction_msg($status)
  }
  elsif ($short_request_type eq 'PerformTransactionArguments') {
    my $CHECK_FIELD       = $FORM->{CHECK_FIELDS}      || $self->{conf}{'PAYSYS_' . $CUSTOM_NAME . '_ACCOUNT_KEY'} || 'UID';

    $request_params{sum}            = $_xml->{'soapenv:Body'}->[0]->{$request_type}->[0]->{amount}->[0];
    $request_params{transaction_id} = $_xml->{'soapenv:Body'}->[0]->{$request_type}->[0]->{transactionId}->[0];

    my @payments_arr = @{ $_xml->{'soapenv:Body'}->[0]->{$request_type}->[0]->{parameters} };

    for (my $i = 0 ; $i <= $#payments_arr ; $i++) {
      my $key   = $_xml->{'soapenv:Body'}->[0]->{$request_type}->[0]->{parameters}->[$i]->{paramKey}->[0];
      my $value = $_xml->{'soapenv:Body'}->[0]->{$request_type}->[0]->{parameters}->[$i]->{paramValue}->[0];
      $request_params{$key} = $value;
    }

    my ($transaction_check, $transaction_status) = main::paysys_pay_check({
      TRANSACTION_ID => "$CUSTOM_NAME:$request_params{transaction_id}",
    });

    if($transaction_check){
      $status = 201;

      transaction_already_exist_msg(201, $transaction_check);
      return 1;
    }

    $request_params{client} = $_xml->{'soapenv:Body'}->[0]->{'ns1:PerformTransactionArguments'}->[0]->{parameters}->[0]->{paramValue}->[0];
    my ($result_code, $payment_id) = main::paysys_pay({
      PAYMENT_SYSTEM    => $CUSTOM_NAME,
      PAYMENT_SYSTEM_ID => $CUSTOM_ID,
      CHECK_FIELD       => $CHECK_FIELD,
      USER_ID           => $request_params{client},
      SUM               => $request_params{sum} / 100,
      EXT_ID            => $request_params{transaction_id},
      DATA              => \%request_params,
      CURRENCY_ISO      => $self->{conf}{PAYSYS_PAYNET_CURRENCY},
      MK_LOG            => 1,
      PAYMENT_ID        => 1,
      DEBUG             => $self->{DEBUG}, 
    });

    $status = ($axbills2paynet{$result_code}) ? $axbills2paynet{$result_code} : 0;
    perform_transaction_msg($result_code, $payment_id);
  }
  elsif ($short_request_type eq 'CheckTransactionArguments') {
    $request_params{transaction_id} = $_xml->{'soapenv:Body'}->[0]->{$request_type}->[0]->{transactionId}->[0];

    my ($payment_id, $payment_status) = main::paysys_pay_check({
      TRANSACTION_ID => "$CUSTOM_NAME:$request_params{transaction_id}"
    });

    my $trans_state = 2;

    if ($payment_id && $payment_status == 2) {
      $status      = 0;
      $trans_state = 1;
    }
    else {
      $status = 11;
    }

    check_transaction_msg($status, $payment_id);
  }
  #Check account
  elsif ($short_request_type eq 'GetInformationArguments') {
    my $account_id = $_xml->{'soapenv:Body'}->[0]->{$request_type}->[0]->{parameters}->[0]->{paramValue}->[0];
    if ($account_id eq '') {
      paynet_msg(
        '113',
        $short_request_type,
        $prefix_request_type,
        {
          RESPONSE => $request_type,
          RESULT   => $request_type
        }
      );
      return 0;
    }

    my $CHECK_FIELD       = $FORM->{CHECK_FIELDS}      || $self->{conf}{'PAYSYS_' . $CUSTOM_NAME . '_ACCOUNT_KEY'} || 'UID';

    my ($result_code, $list) = main::paysys_check_user({
      CHECK_FIELD => $CHECK_FIELD,
      USER_ID     => $account_id
    });

    %axbills2paynet = (
      0  => 0, #ok
      1  => 113, #not exist user
      2  => 113, #sql error
      3  => 7, #dublicate payment
      5  => '', #wrong sum
      6  => 10, #small sum
      7  => '', #large sum
      8  => '11', #Transaction not found
      9  => '', #Payment exist
      10 => '', #Payment not exist
      11 => '501', #Paysys disable
      13 => '', #Payment exist
      17 => '11',
    );

    $status = ($axbills2paynet{$result_code}) ? $result_code : 0;

    push @result_array,
      {
        balance => $list->{deposit},
        name    => $list->{fio}
      };

    getinformation_msg($status, $list);
  }
  #period transaction results
  elsif ($short_request_type eq 'GetStatementArguments') {
    my $datefrom = $_xml->{'soapenv:Body'}->[0]->{$request_type}->[0]->{dateFrom}->[0];
    my $dateto   = $_xml->{'soapenv:Body'}->[0]->{$request_type}->[0]->{dateTo}->[0];
    $status      = 0;

    $datefrom =~ s/T/ /;
    $dateto   =~ s/T/ /;
    $payments->{debug}=1 if ($self->{DEBUG} > 6);
    my $list = $payments->list(
      {
        EXT_ID         => "$CUSTOM_NAME:*",
        FROM_DATE_TIME => $datefrom,
        TO_DATE_TIME   => $dateto,
        SUM            => '_SHOW',
        AMOUNT         => '_SHOW',
        PAGE_ROWS      => 10000,
        COLS_NAME      => 1
      }
    );

    if ($payments->{errno}) {
      $status = 11;
    }

    foreach my $line (@$list) {
      my $transactionid = $line->{ext_id};
      $transactionid =~ s/$CUSTOM_NAME\://g;
      $line->{datetime} =~ m/(\d+)-(\d+)-(\d+)\s(\d+)\:(\d+)\:(\d+)/;
      my $Y = $1;
      my $m = $2;
      my $d = $3;
      my $H = $4;
      my $M = $5;
      my $s = $6;
      my $fractal_secs = '00000';
      my $transaction_time = POSIX::strftime "%Y-%m-%dT%H:%M:%S$timezone", localtime(time);

      my ($provider_id, undef) = main::paysys_pay_check({ TRANSACTION_ID => $line->{ext_id} });

      push @result_array,
        {
          amount          => int(( ($self->{conf}{'PAYSYS_' . $CUSTOM_NAME . '_CURRENCY'}) ? $line->{amount} : $line->{sum}) * 100 ),
          providerTrnId   => $provider_id,
          transactionId   => $transactionid,
          transactionTime => $transaction_time
        };
    }

    paynet_msg($status, $short_request_type, $prefix_request_type, { STATEMENTS => \@result_array });
  }
  else {
  }

}

#**********************************************************
=head2 paynet_msg($status, $message, $attr)

=cut
#**********************************************************
sub paynet_msg {
  my ($status, $message, $prefix_request_type, $attr) = @_;

  my %request_response_types = (
    'CancelTransactionArguments'  => 'CancelTransactionResult',
    'GetInformationArguments'     => 'GetInformationResult',
    'PerformTransactionArguments' => 'PerformTransactionResult',
    'CheckTransactionArguments'   => 'CheckTransactionResult',
    'GetStatementArguments'       => 'GetStatementResult'
  );

  my $error_msg = ($status == 0) ? 'Ok' : 'Error';
  use Time::HiRes q/gettimeofday/;

  my $fractal_secs = (gettimeofday)[1];
  my $timezone = POSIX::strftime("%z", localtime);
  $timezone = join(':', substr($timezone, 0, 3), substr($timezone, 3, 2));
  $fractal_secs = substr($fractal_secs, 0, 3);

  my $timetamp = POSIX::strftime "%Y-%m-%dT%H:%M:%S$timezone", localtime(time);

  my $body = "<errorMsg>$error_msg</errorMsg><status>$status</status><timeStamp>$timetamp</timeStamp>";

  if ($attr->{STATEMENTS}) {
    foreach my $params (@{ $attr->{STATEMENTS} }) {
      $body .= "<statements>";

      my @params_arr = ('amount',
        'providerTrnId',
        'transactionId',
        'transactionTime');

      for (my $i=0; $i<=$#params_arr; $i++) {
        my $k = $params_arr[$i];
        if ( defined($params->{$k})) {
          my $v = $params->{$k};
          $body .= "<$k>$v</$k>";
        }
      }

      $body .= "</statements>";
    }
  }
  elsif ($attr->{PARAMETERS}) {
    foreach my $params (@{ $attr->{PARAMETERS} }) {
      $body .= "<parameters>";

      while (my ($k, $v) = each(%$params)) {
        $body .= "<paramKey>$k</paramKey><paramValue>$v</paramValue>";
      }

      $body .= "</parameters>";
    }
  }

  if (defined($attr->{providerTrnId})) {
    $body .= "<providerTrnId>$attr->{providerTrnId}</providerTrnId>";
  }

  if (defined($attr->{transactionState})) {
    $body .= "<transactionState>$attr->{transactionState}</transactionState>";
  }

  if (defined($attr->{transactionStateErrorStatus})) {
    $body .= "<transactionStateErrorStatus>$attr->{transactionStateErrorStatus}</transactionStateErrorStatus>";
  }

  if ($attr->{transactionStateErrorMsg}) {
    $body .= "<transactionStateErrorMsg>$attr->{transactionStateErrorMsg}</transactionStateErrorMsg>";
  }

  $message = $prefix_request_type . $request_response_types{$message};

  my $result = qq{<?xml version="1.0" encoding="utf-8"?><soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ns1="http://uws.provider.com/"><soapenv:Body><$message>$body</$message></soapenv:Body></soapenv:Envelope>};

  _result($result);

  return 1;
}

#**********************************************************
=head2 _result($content)

=cut
#**********************************************************
sub _result {
  my ($content) = @_;

  print "Content-Type: text/xml\n\n";

  print $content;

  main::mk_log($content, { PAYSYS_ID => 'Paynet' });

  return 1;
}

#**********************************************************
=head2 perform_transaction_msg($status, $transaction_id)

=cut
#**********************************************************
sub perform_transaction_msg {
  my ($status, $transaction_id) = @_;

  use Time::HiRes q/gettimeofday/;

  my $fractal_secs = (gettimeofday)[1];
  my $timezone = q{+05:00};
  $fractal_secs = substr($fractal_secs, 0, 3);

  my $timetamp = POSIX::strftime "%Y-%m-%dT%H:%M:%S$timezone", gmtime(time);

  my $error_msg = ($status == 0) ? 'Ok' : 'Error';

  my %axbills2paynet_statuses = (
    0 => 0,
    1 => 302,
  );

  if(!$transaction_id){
    $transaction_id = 0;
  }

  my $content = qq{<?xml version="1.0" encoding="UTF-8"?>
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">
<soapenv:Body>
<ns2:PerformTransactionResult xmlns:ns2="http://uws.provider.com/">
<errorMsg>$error_msg</errorMsg>
<status>$axbills2paynet_statuses{$status}</status>
<timeStamp>$timetamp</timeStamp>
<providerTrnId>$transaction_id</providerTrnId>
</ns2:PerformTransactionResult>
</soapenv:Body>
</soapenv:Envelope>};

  _result($content);
}

#**********************************************************
=head getinformation_msg($status, $transaction_id)

=cut
#**********************************************************
sub getinformation_msg {
  my ($status, $attr) = @_;

  use Time::HiRes q/gettimeofday/;

  my $fractal_secs = (gettimeofday)[1];
  my $timezone = q{+05:00};
  $fractal_secs = substr($fractal_secs, 0, 3);

  my $timetamp = POSIX::strftime "%Y-%m-%dT%H:%M:%S$timezone", gmtime(time);

  my $error_msg = ($status == 0) ? 'Ok' : 'Error';

  if($status == 0){
  my $content = qq{<?xml version="1.0" encoding="UTF-8"?>
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">
<soapenv:Body><ns2:GetInformationResult xmlns:ns2="http://uws.provider.com/">
<errorMsg>$error_msg</errorMsg>
<status>$status</status>
<timeStamp>2014-11-06T15:49:54.531+05:00</timeStamp>
<parameters>
<paramKey>balance</paramKey>
<paramValue>$attr->{deposit}</paramValue>
</parameters>
<parameters>
<paramKey>name</paramKey>
<paramValue>$attr->{fio}</paramValue>
</parameters>
</ns2:GetInformationResult>
</soapenv:Body>
</soapenv:Envelope>};

  _result($content);
  }
  else{
    my $content = qq{<?xml version="1.0" encoding="UTF-8"?>
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">
<soapenv:Body>
<ns2:GetInformationResult xmlns:ns2="http://uws.provider.com/">
<errorMsg>Transaction for the subscriber is not allowed</errorMsg>
<status>302</status>
<timeStamp>2014-11-06T15:50:47.557+05:00</timeStamp>
</ns2:GetInformationResult>
</soapenv:Body>
</soapenv:Envelope>};

    _result($content);
  }
}

#**********************************************************
=head2 check_transaction_msg($status, $transaction_id)

=cut
#**********************************************************
sub check_transaction_msg {
  my ($status, $payment_id) = @_;

  use Time::HiRes q/gettimeofday/;

  my $fractal_secs = (gettimeofday)[1];
  my $timezone = q{+05:00};
  $fractal_secs = substr($fractal_secs, 0, 3);

  my $timetamp = POSIX::strftime "%Y-%m-%dT%H:%M:%S$timezone", gmtime(time);

  my $error_msg = ($status == 0) ? 'Error' : '';

  my %axbills2paynet_statuses = (
    0 => 0,
    1 => 302,
  );

  if($status != 0){
    my $content = qq{<?xml version="1.0" encoding="UTF-8"?>
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">
<soapenv:Body>
<ns2:CheckTransactionResult xmlns:ns2="http://uws.provider.com/">
<errorMsg>Success</errorMsg>
<status>$status</status>
<timeStamp>2014-11-06T15:24:33+05:00</timeStamp>
<providerTrnId>$payment_id</providerTrnId>
<transactionState>2</transactionState>
<transactionStateErrorStatus>0</transactionStateErrorStatus>
<transactionStateErrorMsg>Success</transactionStateErrorMsg>
</ns2:CheckTransactionResult>
</soapenv:Body>
</soapenv:Envelope>};

    _result($content);
  }
  else{
    my $content = qq{<?xml version="1.0" encoding="UTF-8"?>
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">
<soapenv:Body>
<ns2:CheckTransactionResult xmlns:ns2="http://uws.provider.com/">
<errorMsg>Success</errorMsg>
<status>$status</status>
<timeStamp>2014-11-06T15:24:33+05:00</timeStamp>
<providerTrnId>$payment_id</providerTrnId>
<transactionState>1</transactionState>
<transactionStateErrorStatus>0</transactionStateErrorStatus>
<transactionStateErrorMsg>Success</transactionStateErrorMsg>
</ns2:CheckTransactionResult>
</soapenv:Body>
</soapenv:Envelope>};

    _result($content);
  }
}

#**********************************************************
=head2 cancel_transaction_msg($status, $transaction_id)

=cut
#**********************************************************
sub cancel_transaction_msg {
  my ($status, $transaction_id) = @_;

  use Time::HiRes q/gettimeofday/;

  my $fractal_secs = (gettimeofday)[1];
  my $timezone = q{+05:00};
  $fractal_secs = substr($fractal_secs, 0, 3);

  my $timetamp = POSIX::strftime "%Y-%m-%dT%H:%M:%S$timezone", gmtime(time);

  my $error_msg = ($status == 0) ? 'Ok' : 'Error';

  my $content = qq{<?xml version="1.0" encoding="UTF-8"?>
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">
<soapenv:Body>
<ns2:CancelTransactionResult xmlns:ns2="http://uws.provider.com/">
<errorMsg>Success</errorMsg>
<status>$status</status>
<timeStamp>$timetamp</timeStamp>
<transactionState>2</transactionState>
</ns2:CancelTransactionResult>
</soapenv:Body>
</soapenv:Envelope>};

  _result($content)
}

#**********************************************************
=head2 transaction_already_exist_msg($status, $transaction_id)

=cut
#**********************************************************
sub transaction_already_exist_msg {
  my ($status, $transaction_id) = @_;

  use Time::HiRes q/gettimeofday/;

  my $fractal_secs = (gettimeofday)[1];
  my $timezone = q{+05:00};
  $fractal_secs = substr($fractal_secs, 0, 3);

  my $timetamp = POSIX::strftime "%Y-%m-%dT%H:%M:%S$timezone", gmtime(time);

  my $error_msg = ($status == 0) ? 'Ok' : 'Error';

  my $content = qq{<?xml version="1.0" encoding="UTF-8"?>
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">
<soapenv:Body>
<ns2:PerformTransactionResult xmlns:ns2="http://uws.provider.com/">
<errorMsg>$error_msg</errorMsg>
<status>$status</status>
<timeStamp>$timetamp</timeStamp>
<providerTrnId>$transaction_id</providerTrnId>
</ns2:PerformTransactionResult>
</soapenv:Body>
</soapenv:Envelope>};

  _result($content)
}

1;
