#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use lib '.';
use lib '../../';
use Paysys::t::Init_t;
require Paysys::systems::Abank;

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

my $Payment_plugin = Paysys::systems::Abank->new($db, $admin, \%conf);
if ($debug > 3) {
  $Payment_plugin->{DEBUG} = 7;
}

$payment_id = int(rand(10000));
$user_id = $argv->{user} || $Payment_plugin->{conf}->{PAYSYS_TEST_USER} || '';

our @requests = (
  {
    name    => 'PRESEARCH_USER',
    request => qq{<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Transfer action="Search" interface="Debt" xmlns="http://debt.privatbank.ua/Transfer">
    <Data xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="Payer">
        <Unit name="billIdentifier" value="$user_id"/>
    </Data>
</Transfer>},
    result  => qq{
<?xml version="1.0" encoding="UTF-8"?>
<Transfer interface="Debt" action="Presearch">
   <Data xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="PayersTable">
      <Headers>
         <Header name="fio" />
         <Header name="ls" />
      </Headers>
      <Columns>
         <Column>
            <Element>Іванов Івае Іванович</Element>
         </Column>
         <Column>
            <Element>$user_id</Element>
         </Column>
      </Columns>
   </Data>
</Transfer>
}
  },
  {
    name    => 'SEARCH_USER',
    request => qq{<?xml version="1.0" encoding="UTF-8"?>
<Transfer  interface="Debt" action="Search">
   <Data xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="Payer" presearchId="$user_id" />
</Transfer>},
    result  => qq{
<?xml version="1.0" encoding="UTF-8"?>
<Transfer interface="Debt" action="Search">
   <Data xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="DebtPack">
      <PayerInfo billIdentifier="12102348">
         <Fio>Иванов Иван Иванович</Fio>
         <Phone>+321234214</Phone>
         <Address>пр.Ленина 10 кв 5</Address>
      </PayerInfo>
      <ServiceGroup>
         <DebtService serviceCode="101">
            <CompanyInfo mfo="1242143" okpo="23412341234" account="2600123234">
               <CompanyCode>1</CompanyCode>
               <CompanyName>КП Воддоканал</CompanyName>
            </CompanyInfo>
            <DebtInfo amountToPay="0.01" debt="0.01">
               <Balance>0.01</Balance>
            </DebtInfo>
            <ServiceName>Холодныя вода</ServiceName>
            <Destination>Оплата за услугу "Холодная вода"</Destination>
            <PayerInfo billIdentifier="$user_id" ls="$user_id">
               <Fio>Иванов Иван Иванович</Fio>
               <Phone>+321234214</Phone>
            </PayerInfo>
         </DebtService>
      </ServiceGroup>
   </Data>
</Transfer>
}
  },
  {
    name    => 'CHECK_USER',
    request => qq{
<?xml version="1.0" encoding="UTF-8"?>
<Transfer interface="Debt" action="Check">
    <Data
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="Payment" number="12432" id="$payment_id">
        <CompanyInfo companyId="412341234">
            <CompanyCode>1</CompanyCode>
            <CompanyName>КП Воддоканал</CompanyName>
            <DopData>
                <Dop name="доп информация" value="значение" />
            </DopData>
        </CompanyInfo>
        <PayerInfo billIdentifier="$user_id" ls="$user_id">
            <Fio>Иванов Иван Иванович</Fio>
            <Phone>+321234214</Phone>
            <Address>пр.Ленина 10 кв 5</Address>
        </PayerInfo>
        <TotalSum>0.01</TotalSum>
        <CreateTime>2012-01-01T08:00:00.001+03:00</CreateTime>
        <ServiceGroup>
            <Service sum="0.01" serviceCode="102">
                <CompanyInfo>
                    <CompanyCode>1</CompanyCode>
                    <CompanyName>КП Воддоканал</CompanyName>
                </CompanyInfo>
                <ServiceName>Холоднaя вода</ServiceName>
                <Destination>Оплата за услугу "Холодная вода"</Destination>
                <MeterData>
                    <Meter previosValue="213" currentValue="214" tarif="0.01" delta="1" name="Холодная вода кухня" />
                </MeterData>
                <DopData>
                    <Dop name="city_code" value="3" />
                </DopData>
            </Service>
            <Service sum="0.01" serviceCode="10">
                <CompanyInfo>
                    <CompanyCode>1</CompanyCode>
                    <CompanyName>КП Воддоканал</CompanyName>
                </CompanyInfo>
                <ServiceName>Холоднaя вода</ServiceName>
                <Destination>Оплата за услугу "Холодная вода"</Destination>
                <MeterData>
                    <Meter previosValue="213" currentValue="214" tarif="0.01" delta="1" name="Холодная вода кухня" />
                </MeterData>
                <DopData>
                    <Dop name="city_code" value="3" />
                </DopData>
            </Service>
        </ServiceGroup>
    </Data>
</Transfer>},
    result  => qq{
<?xml version="1.0" encoding="UTF-8"?>
<Transfer interface="Debt" action="Check">
   <Data xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="Gateway" reference="987456321" />
</Transfer>}
  },
  {
    name    => 'PAY',
    request => qq{
<?xml version="1.0" encoding="UTF-8"?>
<Transfer interface="Debt" action="Pay">
   <Data xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="Payment" id="$payment_id" number="12432">
      <CompanyInfo inn="00000000" companyId="412341234">
         <CompanyCode>1</CompanyCode>
         <UnitCode>2221</UnitCode>
         <CompanyName>КП Воддоканал</CompanyName>
         <DopData>
            <Dop name="доп информация" value="значение" />
         </DopData>
         <CheckReference>987456321</CheckReference>
      </CompanyInfo>
      <PayerInfo billIdentifier="$user_id" ls="$user_id">
         <Fio>Иванов Иван Иванович</Fio>
         <Phone>+321234214</Phone>
         <Address>пр.Ленина 10 кв 5</Address>
      </PayerInfo>
      <TotalSum>$payment_sum</TotalSum>
      <CreateTime>2012-01-01T08:00:00.001+03:00</CreateTime>
      <ConfirmTime>2013-08-06T16:55:04.120+03:00</ConfirmTime>
      <NumberPack>143</NumberPack>
      <SubNumberPack>1</SubNumberPack>
      <ServiceGroup>
         <Service sum="$payment_sum" serviceCode="102" id="324124213">
            <CompanyInfo>
               <CheckReference>987456321</CheckReference>
               <CompanyCode>1</CompanyCode>
               <UnitCode>2221</UnitCode>
               <CompanyName>КП Воддоканал</CompanyName>
               <DopData>
                  <Dop name="city_code" value="3" />
               </DopData>
            </CompanyInfo>
            <idinvoice>12345678</idinvoice>
            <ServiceName>Холодныя вода</ServiceName>
            <Destination>Оплата за услугу "Холодная вода"</Destination>
            <MeterData>
               <Meter previosValue="213" currentValue="214" tarif="0.01" delta="1" name="Холодная вода кухня" />
            </MeterData>
            <DopData>
               <Dop name="city_code" value="3" />
            </DopData>
            <Comissions>
               <Commision type="3" summ="0.99" />
               <Commision type="1" summ="0.10" />
            </Comissions>
         </Service>
      </ServiceGroup>
   </Data>
</Transfer>},
    result  => qq{
<?xml version="1.0" encoding="UTF-8"?>
<Transfer interface="Debt" action="Pay">
   <Data xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="Gateway" reference="987456321" />
</Transfer>}
  },
);

test_runner($Payment_plugin, \@requests, { VALIDATE => 'xml_compare' });

1;

