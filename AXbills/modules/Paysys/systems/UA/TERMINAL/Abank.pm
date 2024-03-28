=head1 NAME

    Abank
    New module for Abank

  DATE: 07.12.2020
  UPDATE:
  VERSION: 0.01

=cut

package Paysys::systems::Abank;


use strict;
use warnings;
use Encode;

use AXbills::Base qw(_bp load_pmodule);
use AXbills::Misc qw(load_module);

require Paysys::Paysys_Base;
use Paysys;
our Paysys $Paysys;

our $PAYSYSTEM_NAME = 'Abank';
our $PAYSYSTEM_SHORT_NAME = 'AB';
our $PAYSYSTEM_ID = 151;

our $PAYSYSTEM_VERSION = '0.1';

our %PAYSYSTEM_CONF = (
  PAYSYS_ABANK_ACCOUNT_KEY  => '',
  PAYSYS_ABANK_MFO          => '',
  PAYSYS_ABANK_CODE         => '',
  PAYSYS_ABANK_OKPO         => '',
  PAYSYS_ABANK_ACC          => '',
  PAYSYS_ABANK_FAST_PAY     => '',
  PAYSYS_ABANK_NAME         => '',
  PAYSYS_ABANK_SERVICE_CODE => '',
  PAYSYS_ABANK_SERVICE_NAME => '',
  PAYSYS_ABANK_DESTINATION  => '',

);

my ($html);
#**********************************************************
=head2 new($db, $admin, $CONF)

  Arguments:
    $db    - ref to DB
    $admin - current Web session admin
    $CONF  - ref to %conf
    $attr
      HTML HTML_OBJ

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
  load_pmodule('XML::Simple');

  if(! $FORM->{__BUFFER}) {
    print "Content-Type: text/html\n\n";
    print "NO_REQUEST";
    return 0;
  }

  my $_xml = eval {XML::Simple::XMLin($FORM->{__BUFFER} || q{}, forcearray => 1)};

  if ($@) {
    main::mk_log("-- Content:\n" . ( $FORM->{__BUFFER} || q{} ) . "\n-- XML Error:\n" . $@ . "\n--\n",
      { PAYSYS_ID => 'Abank', HEADER => 1 });
    return 0;
  }
  else {
    if ($self->{DEBUG} > 0) {
      main::mk_log($FORM->{__BUFFER}, { PAYSYS_ID => 'Abank' });
    }
  }

  my %request_hash = %$_xml;

  my $request_type = $request_hash{action};

  if ($request_type eq 'Presearch') {
    $self->preseach($FORM);
  }
  elsif ($request_type eq 'Search') {
    $self->seach($FORM);
  }
  elsif ($request_type eq 'Check'){
    $self->check($FORM);
  }
  elsif ($request_type eq 'Pay'){
    $self->pay($FORM);
  }

  return 1;
}

#**********************************************************
=head2 preseach() - preseach if user exist

  Arguments:
     %FORM
       value - user ID

  Returns:
    REF HASH
=cut
#**********************************************************
sub preseach{
  my ($self) = shift;
  my ($FORM) = @_;
  load_pmodule('XML::Simple');
  my $CHECK_FIELD = $self->{conf}{PAYSYS_ABANK_ACCOUNT_KEY} || 'UID';

  my $_xml = eval {XML::Simple::XMLin($FORM->{__BUFFER} || q{}, forcearray => 1)};
  my %request_hash = %$_xml;

  my $request_type = $request_hash{action};
  my $user_account = $request_hash{Data}->[0]->{Unit}->{ls}->{value};

  my ($result_code, $user_object) = main::paysys_check_user({
    CHECK_FIELD        => $CHECK_FIELD,
    USER_ID            => $user_account,
    DEBUG              => $self->{DEBUG},
    SKIP_DEPOSIT_CHECK => 1
  });

  if ($result_code == 1) {
    $self->show_result('error', '', { error_code => 2 });
    return 1;
  }
  elsif ($result_code == 11) {
    $self->show_result('error', '', { error_code => 5 });
    return 1;
  }
  elsif ($user_object->{GID}) {
    $self->account_gid_split($user_object->{GID});
  }

  my $fio = decode('utf8', $user_object->{FIO} || q{});

  my $context1 = '';
  my $context2 = '';
  $context1 .= "<Element>$fio</Element>";
  $context2 .= "<Element>$user_object->{$CHECK_FIELD}</Element>";

  $self->show_result('ok',
    qq {<?xml version="1.0" encoding="UTF-8"?>
    <Transfer interface="Debt" action="Presearch">
      <Data xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="PayersTable">
        <Headers>
          <Header name="fio"/>
          <Header name="bill_identifier"/>
        </Headers>
        <Columns>
          <Column>
            $context1
          </Column>
          <Column>
            $context2
          </Column>
        </Columns>
      </Data>
    </Transfer>
  },
    { action => $request_type }
  );

  return 0;
}


#**********************************************************
=head2 seach() - preseach if user exist

  Arguments:
     %FORM
       value - user ID

  Returns:
    REF HASH
=cut
#**********************************************************
sub seach{
  my ($self) = shift;
  my ($FORM) = @_;
  load_pmodule('XML::Simple');
  my $CHECK_FIELD = $self->{conf}{PAYSYS_ABANK_ACCOUNT_KEY} || 'UID';

  my $_xml = eval {XML::Simple::XMLin($FORM->{__BUFFER} || q{}, forcearray => 1)};
  my %request_hash = %$_xml;

  my $request_type = $request_hash{action};
  my $user_account = $request_hash{Data}->[0]->{Unit}->{ls}->{value} || $request_hash{Data}->[0]->{presearchId};

  my ($result_code, $user_object) = main::paysys_check_user({
    CHECK_FIELD        => $CHECK_FIELD,
    USER_ID            => $user_account,
    DEBUG              => $self->{DEBUG},
    SKIP_DEPOSIT_CHECK => 1
  });

  if ($result_code == 1) {
    $self->show_result('error', '', { error_code => 2 });
    return 1;
  }
  elsif ($result_code == 11) {
    $self->show_result('error', '', { error_code => 5 });
    return 1;
  }
  elsif ($user_object->{GID}) {
    $self->account_gid_split($user_object->{GID});
  }

  $user_object->{fio} =~ s/\'/_/g;
  my $balance    = sprintf("%.2f", $user_object->{deposit});

  my $DebtPack  = $main::DATE;
  $DebtPack =~ s/(\d{4})-(\d{2})-(\d{2})/$1$2/;
  my $amount_to_pay = sprintf("%.2f", ($balance < 0) ? abs($balance) : 0 - $balance);

  my $message_my = decode('utf8',"Данные о задолженности можно получить в Кассе!");
  my $user_fio_my = decode('utf8',$user_object->{fio} || q{});
  my $user_phone_my = decode('utf8',$user_object->{phone} || q{});
  my $user_address_my = decode('utf8',$user_object->{address_full} || q{});
  my $company_name_my = decode('utf8',$self->{conf}{PAYSYS_ABANK_NAME} || q{});
  my $service_name = decode('utf8', $self->{conf}{PAYSYS_ABANK_SERVICE_NAME} || q{});
  my $destination =  decode('utf8', $self->{conf}{PAYSYS_ABANK_DESTINATION} || q{});
  
  $company_name_my =~ s/\\(.)/"/g;

  $self->show_result('ok',
    qq {<?xml version="1.0" encoding="UTF-8"?>
          <Transfer interface="Debt" action="Search">
          <Data xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="DebtPack" billPeriod="$DebtPack">
            <Message>$message_my</Message>
            <PayerInfo billIdentifier="$user_account" ls="$user_account">
              <Fio>$user_fio_my</Fio>
              <Phone>$user_phone_my</Phone>
              <Address>$user_address_my</Address>
            </PayerInfo>
            <ServiceGroup>
              <DebtService serviceCode="$self->{conf}{PAYSYS_ABANK_SERVICE_CODE}" >
                <Message>Internet</Message>
                <CompanyInfo mfo="$self->{conf}{PAYSYS_ABANK_MFO}" okpo="$self->{conf}{PAYSYS_ABANK_OKPO}" account="$self->{conf}{PAYSYS_ABANK_ACC}" >
                  <CompanyCode>$self->{conf}{PAYSYS_ABANK_CODE}</CompanyCode>
                  <CompanyName>$company_name_my</CompanyName>
                </CompanyInfo>
                <DebtInfo amountToPay="$amount_to_pay" debt="$amount_to_pay">
                  <Fio>$user_fio_my</Fio>
                  <Phone>$user_phone_my</Phone>
                </DebtInfo>
                <ServiceName>$service_name</ServiceName>
                <Destination>$destination$user_account</Destination>
                <PayerInfo billIdentifier="$user_account" ls="$user_account"></PayerInfo>
              </DebtService>
            </ServiceGroup>
          </Data>
          </Transfer>},
    { action => $request_type }
  );
  return 0;
}

#**********************************************************
=head2 check() - preseach if user exist

  Arguments:
     %FORM
       value - user ID

  Returns:
    REF HASH
=cut
#**********************************************************
sub check{
  my ($self) = shift;
  my ($FORM) = @_;
  load_pmodule('XML::Simple');

  my $CHECK_FIELD = $self->{conf}{PAYSYS_ABANK_ACCOUNT_KEY} || 'UID';

  my $_xml = eval {XML::Simple::XMLin($FORM->{__BUFFER} || q{}, forcearray => 1)};
  my %request_hash = %$_xml;

  my $request_type = $request_hash{action};
  my ($id, undef) = keys %{$request_hash{Data}};
  my $user_account = $request_hash{Data}->{$id}->{PayerInfo}->[0]->{billIdentifier};
  my $datetime = $request_hash{Data}->{$id}->{CreateTime}->[0];
  $datetime    =~ /(\d+)\-(\d+)\-(\d+)T(\d+\:\d+\:\d+)/;

  my ($result_code, $user_object) = main::paysys_check_user({
    CHECK_FIELD        => $CHECK_FIELD ,
    USER_ID            => $user_account,
    DEBUG              => $self->{DEBUG},
    SKIP_DEPOSIT_CHECK => 1
  });

  if ($result_code == 1) {
    $self->show_result('error', '', { error_code => 2 });
    return 1;
  }
  elsif ($result_code == 11) {
    $self->show_result('error', '', { error_code => 5 });
    return 1;
  }
  elsif ($user_object->{GID}) {
    $self->account_gid_split($user_object->{GID});
  }

  my $uid = $user_object->{uid};

  $self->show_result('ok', qq{<?xml version="1.0" encoding="UTF-8"?>
<Transfer interface="Debt" action="Check">
  <Data xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="Gateway" reference="$uid" />
</Transfer>},
    { action => $request_type }
  );
  return 0;
}

#**********************************************************
=head2 pay() - pay if user exist

  Arguments:
     %FORM
       value - user ID

  Returns:
    REF HASH
=cut
#**********************************************************
sub pay{
  my ($self) = shift;
  my ($FORM) = @_;
  load_pmodule('XML::Simple');

  my $CHECK_FIELD = $self->{conf}{PAYSYS_ABANK_ACCOUNT_KEY} || 'UID';

  my $_xml = eval {XML::Simple::XMLin($FORM->{__BUFFER} || q{}, forcearray => 1)};
  my %request_hash = %$_xml;

  my $request_type = $request_hash{action};
  my ($transaction)= keys %{ $request_hash{Data} };
  my $ext_id       = $transaction;
  my $user_account = $request_hash{Data}->{$transaction}->{PayerInfo}->[0]->{billIdentifier};
  my $amount       = $request_hash{Data}->{$transaction}->{TotalSum}->[0];

  my ($status_code, $payments_id) = main::paysys_pay({
    PAYMENT_SYSTEM    => $PAYSYSTEM_SHORT_NAME,
    PAYMENT_SYSTEM_ID => $PAYSYSTEM_ID,
    CHECK_FIELD       => $CHECK_FIELD,
    USER_ID           => $user_account,
    SUM               => $amount,
    EXT_ID            => $ext_id,
    DATA              => $request_hash{Data},
    DATE              => "$main::DATE $main::TIME",
    MK_LOG            => 1,
    PAYMENT_ID        => 1,
    DEBUG             => $self->{DEBUG},
    PAYMENT_DESCRIBE  => "Abank Payments: "."Abank:$transaction",
  });

  if($status_code == 0){
    $self->show_result('ok',
      qq {<?xml version="1.0" encoding="UTF-8"?>
          <Transfer interface="Debt" action="Pay">
            <Data xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="Gateway" reference="$payments_id">
            </Data>
          </Transfer>
        },
      { action => $request_type } );
  }
  elsif($status_code == 1){
    $self->show_result('error', '', {
      error_code => 2,
      action     => $request_type
    });
  }
  elsif($status_code == 9){
    $self->show_result('error', '', {
      error_code => 7,
      action     => $request_type
    });
  }
  else{
    $self->show_result('error', '', {
      error_code => 99,
      action     => $request_type
    });
  }
  return 0;
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
=head2 _show_result -

  Arguments:


  Returns:
    HASH
=cut
#**********************************************************
sub show_result {
  my $self = shift;
  my ($result, $content, $attr) = @_;

  print "Content-Type: text/plain\n\n" if ($self->{DEBUG} > 1);
  print "Content-Type: text/xml\n\n";

  my %error_codes = (
    1  => 'Неизвестный тип запроса',
    2  => 'Абонент не найден',
    3  => 'Ошибка в формате денежной суммы (“Сумма платежа” или “Сумма к оплате”)',
    4  => 'Неверный формат даты',
    5  => 'Доступ с данного IP не предусмотрен',
    6  => 'Найдено более одного плательщика. Уточните параметра поиска.',
    7  => 'Дублирование платежа.*',
    8  => 'Платёж не найден',
    99 => 'Другая ошибка провайдера(Можно указать любое другое сообщение)'
  );

  if ($result eq 'error') {
    my $error_code = $attr->{error_code} || 0;
    my $action = $attr->{action} || 0;

    if (!$content && $error_code) {
      $content = $error_codes{$error_code} || '';
    }
    $content = decode('utf8', $content);
    
    $content = qq{<?xml version="1.0" encoding="UTF-8"?>
        <Transfer interface="Debt" action="$action">
          <Data xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="ErrorInfo" code="$error_code">
           <Message>$content</Message>
         </Data>
       </Transfer>
    };
  }
  # Fixme Pick up if there are no errors
  $content = encode('utf-8', $content);
  print $content;

  main::mk_log($content, { PAYSYS_ID => 'Abank' });

  return 1;
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

  #if(!$user->{$self->{conf}{PAYSYS_ABANK_ACCOUNT_KEY}}){
  #  $user->pi();
  #}
  #my $link = $self->{conf}{PAYSYS_ABANK_FAST_PAY} . "&acc=" . ($user->{$self->{conf}{PAYSYS_ABANK_ACCOUNT_KEY}} || $attr->{$self->{conf}{PAYSYS_ABANK_ACCOUNT_KEY}}) . "&amount=" . ($attr->{SUM} || 0);

  #return $html->tpl_show(main::_include('paysys_abank_fastpay', 'Paysys'), {LINK => $link}, { OUTPUT2RETURN => 0 });
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

  foreach my $param (keys %PAYSYSTEM_CONF) {
    if ($self->{conf}{$param . '_' . $gid}) {
      $self->{conf}{$param} = $self->{conf}{$param . '_' . $gid};
    }
  }
}

1;
