#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use lib '.';
use lib '../../';
use Paysys::t::Init_t;
require Paysys::systems::Paynet;

our (
  %conf,
  $db,
  $admin,
  $debug,
  $user_id,
  $payment_sum,
  $payment_id,
  $argv
);

my $Payment_plugin = Paysys::systems::Paynet->new($db, $admin, \%conf);
if ($debug > 3) {
  $Payment_plugin->{DEBUG} = 7;
}

$payment_id = int(rand(10000));
$user_id = $argv->{user} || $Payment_plugin->{conf}->{PAYSYS_TEST_USER} || '';
my $username = $argv->{LOGIN} || $conf{PAYSYS_PAYNET_USERNAME} || 'username';
my $password = $argv->{PASSWORD} || $conf{PAYSYS_PAYNET_PASSWORD} || 'password';
my $timezone = q{+05:00};
my $timestamp = POSIX::strftime "%Y-%m-%dT%H:%M:%S$timezone", gmtime(time);
my $transaction_start_date = POSIX::strftime('%Y-%m-%d %H:%M:%S', localtime(time - 86400 * 3));
my $transaction_end_date = POSIX::strftime('%Y-%m-%d %H:%M:%S', localtime());

our @requests = (
  {
    name    => 'CHECK_USER',
    request => qq{
<?xml version = \"1.0\" encoding=\"UTF-8\"?>
<soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\">
<soapenv:Body><ns1:GetInformationArguments xmlns:ns1=\"http://uws.provider.com/\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:type=\"ns1:GetInformationArguments\">
<password>$password</password>
<username>$username</username>
<parameters>
<paramKey>clientid</paramKey>
<paramValue>$user_id</paramValue>
</parameters>
<parameters>
<paramKey>getInfoType</paramKey>
<paramValue>CHK_PERFORM_TRN</paramValue>
</parameters>
<serviceId>1</serviceId>
</ns1:GetInformationArguments>
</soapenv:Body>
</soapenv:Envelope>
},
    result  => qq{
<?xml version="1.0" encoding="UTF-8"?>
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">
<soapenv:Body><ns2:GetInformationResult xmlns:ns2="http://uws.provider.com/">
<errorMsg>Success</errorMsg>
<status>0</status>
<timeStamp>$timestamp</timeStamp>
</ns2:GetInformationResult>
</soapenv:Body>
</soapenv:Envelope>
       },
  },
  {
    name      => 'PAY',
    request   => qq{
<?xml version="1.0" encoding="UTF-8"?>
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">
<soapenv:Body>
<ns1:PerformTransactionArguments xmlns:ns1="http://uws.provider.com/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="ns1:PerformTransactionArguments">
<password>$password</password>
<username>$username</username>
<amount>100</amount>
<parameters>
    <paramKey>terminal_id</paramKey>
    <paramValue>4075745</paramValue>
</parameters>
<parameters>
    <paramKey>clientid</paramKey>
    <paramValue>$user_id</paramValue>
</parameters>
<serviceId>1</serviceId>
<transactionId>$payment_id</transactionId>
<transactionTime>$timestamp</transactionTime>
</ns1:PerformTransactionArguments>
</soapenv:Body>
</soapenv:Envelope>},
    result    => qq{
<?xml version="1.0" encoding="UTF-8"?>
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">
<soapenv:Body>
<ns2:PerformTransactionResult xmlns:ns2="http://uws.provider.com/">
<errorMsg>Success</errorMsg>
<status>0</status>
<timeStamp>2014-11-06T15:24:33+05:00</timeStamp>
<providerTrnId>3130401334</providerTrnId>
</ns2:PerformTransactionResult>
</soapenv:Body>
</soapenv:Envelope>
     },
  },
  {
    name      => 'PAYMENT_STATUS',
    request   => qq{
<?xml version="1.0" encoding="UTF-8"?>
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">
<soapenv:Body>
<ns1:CheckTransactionArguments xmlns:ns1="http://uws.provider.com/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="ns1:CheckTransactionArguments">
<password>$password</password>
<username>$username</username>
<serviceId>1</serviceId>
<transactionId>$payment_id</transactionId>
<transactionTime>$timestamp</transactionTime>
</ns1:CheckTransactionArguments>
</soapenv:Body>
</soapenv:Envelope>
},
    result    => qq{
<?xml version="1.0" encoding="UTF-8"?>
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">
<soapenv:Body>
<ns2:CheckTransactionResult xmlns:ns2="http://uws.provider.com/">
<errorMsg>Success</errorMsg>
<status>0</status>
<timeStamp>2014-11-06T15:24:33+05:00</timeStamp>
<providerTrnId>3130401334</providerTrnId>
<transactionState>1</transactionState>
<transactionStateErrorStatus>0</transactionStateErrorStatus>
<transactionStateErrorMsg>Success</transactionStateErrorMsg>
</ns2:CheckTransactionResult>
</soapenv:Body>
</soapenv:Envelope>
     },
  },
  {
    name      => 'PAYMENTS_LIST',
    request   => qq{
<?xml version="1.0" encoding="UTF-8"?>
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">
<soapenv:Body>
<ns1:GetStatementArguments xmlns:ns1="http://uws.provider.com/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="ns1:GetStatementArguments">
<password>$password</password>
<username>$username</username>
<dateFrom>$transaction_start_date</dateFrom>
<dateTo>$transaction_end_date</dateTo>
<serviceId>1</serviceId>
</ns1:GetStatementArguments>
</soapenv:Body>
</soapenv:Envelope>
},
    result    => qq{
    <SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ns1="http://uws.provider.com/">
<SOAP-ENV:Body>
<ns1:GetStatementResult>
<errorMsg>Some message</errorMsg>
<status>0</status>
<timeStamp>2014-11-06T17:39:31+05:00</timeStamp>
<statements>
    <amount>1500000</amount>
    <providerTrnId>557</providerTrnId>
    <transactionId>2147483647</transactionId>
    <transactionTime>2014-11-06T11:20:24+05:00</transactionTime>
</statements>
<statements>
    <amount>2300000</amount>
    <providerTrnId>558</providerTrnId>
    <transactionId>2147483698</transactionId>
    <transactionTime>2014-11-06T14:39:05+05:00</transactionTime>
</statements>
</ns1:GetStatementResult>
</SOAP-ENV:Body>
</SOAP-ENV:Envelope>
     },
  },
  {
    name      => 'PAYMENT_CANCEL',
    request   => qq{
<?xml version="1.0" encoding="UTF-8"?>
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">
<soapenv:Body>
<ns1:CancelTransactionArguments xmlns:ns1="http://uws.provider.com/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="ns1:CancelTransactionArguments">
<password>$password</password>
<username>$username</username>
<serviceId>1</serviceId>
<transactionId>$payment_id</transactionId>
<transactionTime>$timestamp</transactionTime>
<parameters>
    <paramKey>terminal_id</paramKey>
    <paramValue>4075745</paramValue>
</parameters>
<parameters>
    <paramKey>cancel_reason_code</paramKey>
    <paramValue>1</paramValue>
</parameters>
<parameters>
    <paramKey>cancel_reason_note</paramKey>
    <paramValue>Testing</paramValue>
</parameters>
</ns1:CancelTransactionArguments>
</soapenv:Body>
</soapenv:Envelope>
},
    result    => qq{
<?xml version="1.0" encoding="UTF-8"?>
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">
<soapenv:Body>
<ns2:CancelTransactionResult xmlns:ns2="http://uws.provider.com/">
<errorMsg>Success</errorMsg>
<status>0</status>
<timeStamp>$timestamp</timeStamp>
<transactionState>2</transactionState>
</ns2:CancelTransactionResult>
</soapenv:Body>
</soapenv:Envelope>
     },
  },
);

test_runner($Payment_plugin, \@requests, { VALIDATE => 'xml_compare' });

1;

