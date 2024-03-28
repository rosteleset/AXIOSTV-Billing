#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use lib '.';
use lib '../../';
use Paysys::t::Init_t;
require Paysys::systems::Privat_terminal;

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

my $Payment_plugin = Paysys::systems::Privat_terminal->new($db, $admin, \%conf);
if ($debug > 3) {
  $Payment_plugin->{DEBUG}=7;
}

$payment_id = int(rand(10000));
$user_id = $argv->{user} || $Payment_plugin->{conf}->{PAYSYS_TEST_USER} || '';

our @requests = (
   {
    name    => 'GET_USER',
    request => qq{<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Transfer action="Search" interface="Debt" xmlns="http://debt.privatbank.ua/Transfer">
    <Data xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="Payer">
        <Unit name="billIdentifier" value="$user_id"/>
    </Data>
</Transfer>},
    result  => qq{
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
          <Transfer xmlns="http://debt.privatbank.ua/Transfer" interface="Debt" action="Search">
          <Data xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="DebtPack" billPeriod="202105">
            <Message>Данные о задолженности можно получить в Кассе!</Message>
            <PayerInfo billIdentifier="$user_id" ls="$user_id">
              <Fio></Fio>
              <Phone></Phone>
              <Address></Address>
            </PayerInfo>
            <ServiceGroup>
              <DebtService serviceCode="" >
                <Message>Данные о задолженности можно получить в Кассе!</Message>
                <CompanyInfo okpo="" account="" >
                  <CompanyCode>1</CompanyCode>
                  <CompanyName></CompanyName>
                </CompanyInfo>
                <PayerInfo billIdentifier="$user_id" ls="$user_id"></PayerInfo>
                <DebtInfo amountToPay="-6910.00" debt="-6910.00"></DebtInfo>
              </DebtService>
            </ServiceGroup>
          </Data>
          </Transfer>
     }
   },
  {
    name    => 'CHECK_USER',
    request => qq{<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Transfer action="Check" interface="Debt" xmlns="http://debt.privatbank.ua/Transfer">
<Data xsi:type="Payment" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
<CompanyInfo/>
<PayerInfo billIdentifier="$user_id"/>
<BankInfo/>
<TotalSum>$payment_sum</TotalSum>
<CreateTime>2021-07-07T12:57:54.196+03:00</CreateTime>
<ServiceGroup>
<Service serviceCode="101" sum="$payment_sum">
<PayerInfo/>
<CompanyInfo/>
<BankInfo/>
</Service>
</ServiceGroup>
</Data>
</Transfer>},
    result  => qq{<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Transfer xmlns="http://debt.privatbank.ua/Transfer" interface="Debt" action="Check">
  <Data xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="Gateway" reference="$user_id" ></Data>
</Transfer>
     }
  },
     {
       name    => 'PAY',
       request => qq{<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Transfer action="Pay" interface="Debt" xmlns="http://debt.privatbank.ua/Transfer">
    <Data xsi:type="Payment" id="$payment_id" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
        <CompanyInfo/>
        <PayerInfo billIdentifier="$user_id"/>
        <BankInfo/>
        <TotalSum>$payment_sum</TotalSum>
        <CreateTime>2021-05-27T14:39:38.783+03:00</CreateTime>
        <ServiceGroup>
            <Service serviceCode="1" sum="$payment_sum">
                <PayerInfo/>
                <CompanyInfo/>
                <BankInfo/>
            </Service>
        </ServiceGroup>
    </Data>
</Transfer>
},
       result  => q{<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
          <Transfer xmlns="http://debt.privatbank.ua/Transfer" interface="Debt" action="Pay">
            <Data xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="Gateway" reference="856348">
            </Data>
          </Transfer>
       }
     }

);

test_runner($Payment_plugin, \@requests, { VALIDATE => 'xml_compare' });

1;

