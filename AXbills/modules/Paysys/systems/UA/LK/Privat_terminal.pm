=head1 NAME

  Privat Terminals
  New module for Privat Terminals

  Documentaion: https://docs.google.com/document/d/1GHjRFyLQM_h59IyaNZVVxYE1cxMPAwb336KKpueQa1U/edit

  DATE: 09.01.2020
  VERSION: 8.03

=cut

package Paysys::systems::Privat_terminal;


use strict;
use warnings;
use Encode;

use AXbills::Base qw(_bp load_pmodule);
use AXbills::Misc qw(load_module);

require Paysys::Paysys_Base;

our $PAYSYSTEM_NAME = 'PrivatTerminal';
our $PAYSYSTEM_SHORT_NAME = 'PT';
our $PAYSYSTEM_ID = 65;

our $PAYSYSTEM_VERSION = '7.04';

our %PAYSYSTEM_CONF = (
  PAYSYS_PT_ACCOUNT_KEY => '',
  PAYSYS_PT_MFO  => '',
  PAYSYS_PT_CODE => '',
  PAYSYS_PT_OKPO => '',
  PAYSYS_PT_ACC  => '',
  PAYSYS_PT_FAST_PAY => '',
  PAYSYS_PT_NAME     => '',
  PAYSYS_PT_SERVICE_CODE => '',
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
      { PAYSYS_ID => 'Privat Terminal', HEADER => 1 });
    return 0;
  }
  else {
    if ($self->{DEBUG} > 0) {
      main::mk_log($FORM->{__BUFFER}, { PAYSYS_ID => 'Privat Terminal' });
    }
  }

  my %request_hash = %$_xml;

  my $request_type = $request_hash{action};

  if ($request_type eq 'Presearch') {
    my $user_account = $request_hash{Data}->[0]->{Unit}->{ls}->{value};

    #    main::_bp("", '', { TO_CONSOLE => 1, HEADER => 1 });
    my ($result_code, $user_object) = main::paysys_check_user({
      CHECK_FIELD        => $self->{conf}{PAYSYS_PT_ACCOUNT_KEY},
      USER_ID            => $user_account,
      DEBUG              => $self->{DEBUG},
      SKIP_DEPOSIT_CHECK => 1
    });

    #    main::_bp("", $user_object, { TO_CONSOLE => 1, HEADER => 1 });

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

    #my $balance = sprintf("%.2f", $user_object->{DEPOSIT});
    my $context1 = '';
    my $context2 = '';
    $context1 .= "<Element>$user_object->{FIO}</Element>";
    $context2 .= "<Element>$user_object->{$self->{conf}{PAYSYS_PT_ACCOUNT_KEY}}</Element>";

    $self->show_result('ok',
      qq {<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
          <Transfer xmlns="http://debt.privatbank.ua/Transfer" interface="Debt" action="Presearch">
          <Data xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="PayersTable">
            <Headers>
              <Header name="fio"/>
              <Header name="ls"/>
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
  elsif ($request_type eq 'Search') {
    my $user_account = $request_hash{Data}->[0]->{presearchId} || $request_hash{Data}->[0]->{Unit}->{bill_identifier}->{value} || $request_hash{Data}->[0]->{Unit}->{billIdentifier}->{value};
    #main::_bp("", '', { TO_CONSOLE => 1, HEADER => 1 });
    my ($result_code, $user_object) = main::paysys_check_user({
      CHECK_FIELD        => $self->{conf}{PAYSYS_PT_ACCOUNT_KEY},
      USER_ID            => $user_account,
      DEBUG              => $self->{DEBUG},
      SKIP_DEPOSIT_CHECK => 1
    });

#    main::_bp("", $user_object, { TO_CONSOLE => 1, HEADER => 1 });

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
    # my $context1   = '';
    # my $context2   = '';

    my $DebtPack  = $main::DATE;
    $DebtPack =~ s/(\d{4})-(\d{2})-(\d{2})/$1$2/;
    my $amount_to_pay = sprintf("%.2f", ($balance < 0) ? abs($balance) : 0 - $balance);

    my $message_my = decode('utf8',"Данные о задолженности можно получить в Кассе!");
    my $user_fio_my = decode('utf8',$user_object->{fio} || q{});
    my $user_phone_my = decode('utf8',$user_object->{phone} || q{});
    my $user_address_my = decode('utf8',$user_object->{address_full} || q{});
    my $company_name_my = decode('utf8',$self->{conf}{PAYSYS_PT_NAME} || q{});

    $self->show_result('ok',
      qq {<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
          <Transfer xmlns="http://debt.privatbank.ua/Transfer" interface="Debt" action="Search">
          <Data xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="DebtPack" billPeriod="$DebtPack">
            <Message>$message_my</Message>
            <PayerInfo billIdentifier="$user_account" ls="$user_account">
              <Fio>$user_fio_my</Fio>
              <Phone>$user_phone_my</Phone>
              <Address>$user_address_my</Address>
            </PayerInfo>
            <ServiceGroup>
              <DebtService serviceCode="$self->{conf}{PAYSYS_PT_SERVICE_CODE}" >
                <Message>Internet</Message>
                <CompanyInfo mfo="$self->{conf}{PAYSYS_PT_MFO}" okpo="$self->{conf}{PAYSYS_PT_OKPO}" account="$self->{conf}{PAYSYS_PT_ACC}" >
                  <CompanyCode>$self->{conf}{PAYSYS_PT_CODE}</CompanyCode>
                  <CompanyName>$company_name_my</CompanyName>
                </CompanyInfo>
                <PayerInfo billIdentifier="$user_account" ls="$user_account"></PayerInfo>
                <DebtInfo amountToPay="$amount_to_pay" debt="$amount_to_pay"></DebtInfo>
              </DebtService>
            </ServiceGroup>
          </Data>
          </Transfer>},
      { action => $request_type }
    );
    return 0;

  }
  elsif ($request_type eq 'Check'){
#    my ($id, @test) = keys %{$request_hash{Data}};
#    my $user_account = $request_hash{Data}->{$id}->{PayerInfo}->[0]->{billIdentifier};
#    my $sum      = $request_hash{Data}->{$id}->{TotalSum}->[0];
#    my $datetime = $request_hash{Data}->{$id}->{CreateTime}->[0];
    # ($id, @test)
    my ($id, undef) = keys %{$request_hash{Data}};
    my $user_account = $request_hash{Data}->{$id}->{PayerInfo}->[0]->{billIdentifier};
    #my $sum      = $request_hash{Data}->{$id}->{TotalSum}->[0];
    my $datetime = $request_hash{Data}->{$id}->{CreateTime}->[0];
    $datetime    =~ /(\d+)\-(\d+)\-(\d+)T(\d+\:\d+\:\d+)/;
    #my $operation_date = "$3.$2.$1 $4";

    my ($result_code, $user_object) = main::paysys_check_user({
      CHECK_FIELD        => $self->{conf}{PAYSYS_PT_ACCOUNT_KEY},
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

    my $uid            = $user_object->{uid};

    $self->show_result('ok', qq{<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Transfer xmlns="http://debt.privatbank.ua/Transfer" interface="Debt" action="Check">
  <Data xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="Gateway" reference="$uid" />
</Transfer>},
      { action => $request_type }
    );

  }
  elsif ($request_type eq 'Pay'){
    my ($transaction)= keys %{ $request_hash{Data} };
    my $ext_id       = $transaction;
    my $user_account = $request_hash{Data}->{$transaction}->{PayerInfo}->[0]->{billIdentifier};
    my $amount       = $request_hash{Data}->{$transaction}->{TotalSum}->[0];


    my ($status_code, $payments_id) = main::paysys_pay({
      PAYMENT_SYSTEM    => $PAYSYSTEM_SHORT_NAME,
      PAYMENT_SYSTEM_ID => $PAYSYSTEM_ID,
      CHECK_FIELD       => $self->{conf}{PAYSYS_PT_ACCOUNT_KEY},
      USER_ID           => $user_account,
      SUM               => $amount,
      EXT_ID            => $ext_id,
      DATA              => $request_hash{Data},
      DATE              => "$main::DATE $main::TIME",
      MK_LOG            => 1,
      PAYMENT_ID        => 1,
      DEBUG             => $self->{DEBUG},
      PAYMENT_DESCRIBE  => "Privat Terminal Payments: "."PT:$transaction",
    });

    if($status_code == 0){
      $self->show_result('ok',
        qq {<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
          <Transfer xmlns="http://debt.privatbank.ua/Transfer" interface="Debt" action="Pay">
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
  }
  elsif ($request_type eq 'Cancel'){

    my ($transaction)= keys %{ $request_hash{Data} };
    my $ext_id       = $transaction;

    my ($result, $payment_id) = main::paysys_pay_cancel({
      TRANSACTION_ID     => "$PAYSYSTEM_SHORT_NAME:$ext_id",
      RETURN_CANCELED_ID => 1,
    });

    if($result == 0){
      $self->show_result('ok',
        qq {<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
            <Transfer xmlns="http://debt.privatbank.ua/Transfer" interface="Debt" action="Cancel">
              <Data xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="Gateway" reference="$payment_id" />
            </Transfer>
        },
        { action => $request_type } );
    }
    else {
      $self->show_result('error', '', { error_code => ($result || 99),
          action     => $request_type });
    }
  }
  elsif ($request_type eq 'Upload'){
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
    98 => 'Платёж не найден',
    99 => 'Другая ошибка провайдера(Можно указать любое другое сообщение)'
  );

  if ($result eq 'error') {
    my $error_code = $attr->{error_code} || 0;
    my $action = $attr->{action} || 0;

    if (!$content && $error_code) {
      $content = $error_codes{$error_code} || '';
    }

    $content = qq{<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Transfer xmlns="http://debt.privatbank.ua/Transfer" interface="Debt" action="$action">
          <Data xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="ErrorInfo" code="$error_code">
           <Message>$content</Message>
         </Data>
       </Transfer>
    };
  }
  # Fixme Pick up if there are no errors
  #$content = encode('utf-8', $content);
  print $content;

  main::mk_log($content, { PAYSYS_ID => 'Privat Terminal' });

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

  if(!$user->{$self->{conf}{PAYSYS_PT_ACCOUNT_KEY}}){
    $user->pi();
  }
  my $link = $self->{conf}{PAYSYS_PT_FAST_PAY} . "&acc=" . ($user->{$self->{conf}{PAYSYS_PT_ACCOUNT_KEY}} || $attr->{$self->{conf}{PAYSYS_PT_ACCOUNT_KEY}}) . "&amount=" . ($attr->{SUM} || 0);

  return $html->tpl_show(main::_include('paysys_privat_terminal_fastpay', 'Paysys'), {LINK => $link}, { OUTPUT2RETURN => 0 });
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

  if ($self->{conf}{'PAYSYS_PRIVAT_BANK_COMPANY_ID_'.$gid}) {
    $self->{conf}{PAYSYS_PRIVAT_BANK_COMPANY_ID}=$self->{conf}{'PAYSYS_PRIVAT_BANK_COMPANY_ID_'.$gid};
  }

  if ($self->{conf}{'PAYSYS_PRIVAT_BANK_SERVICE_'.$gid}) {
    $self->{conf}{PAYSYS_PRIVAT_BANK_SERVICE}=$self->{conf}{'PAYSYS_PRIVAT_BANK_SERVICE_'.$gid};
  }

  if ($self->{conf}{'PAYSYS_PRIVAT_BANK_SERVICE_ID_'.$gid}) {
    $self->{conf}{PAYSYS_PRIVAT_BANK_SERVICE_ID}=$self->{conf}{'PAYSYS_PRIVAT_BANK_SERVICE_ID_'.$gid};
  }

  #version 2
  if ($self->{conf}{'PAYSYS_PT_MFO_'. $gid}) {
    $self->{conf}{'PAYSYS_PT_MFO'} = $self->{conf}{'PAYSYS_PT_MFO_'. $gid};
  }

  if ($self->{conf}{'PAYSYS_PT_OKPO_'. $gid}) {
    $self->{conf}{'PAYSYS_PT_OKPO'} = $self->{conf}{'PAYSYS_PT_OKPO_'. $gid};
  }

  if ($self->{conf}{'PAYSYS_PT_CODE_'. $gid}) {
    $self->{conf}{'PAYSYS_PT_CODE'} = $self->{conf}{'PAYSYS_PT_CODE_'. $gid};
  }

  if ($self->{conf}{'PAYSYS_PT_NAME_'. $gid}) {
    $self->{conf}{'PAYSYS_PT_NAME'} = $self->{conf}{'PAYSYS_PT_NAME_'. $gid};
  }

  if ($self->{conf}{'PAYSYS_PT_ACC_'. $gid}) {
    $self->{conf}{'PAYSYS_PT_ACC'} = $self->{conf}{'PAYSYS_PT_ACC_'. $gid};
  }

  if ($self->{conf}{'PAYSYS_PT_SERVICE_CODE_'. $gid}) {
    $self->{conf}{'PAYSYS_PT_SERVICE_CODE'} = $self->{conf}{'PAYSYS_PT_SERVICE_CODE_'. $gid};
#    $service_code = $conf{PAYSYS_PT_SERVICE_CODE};
  }

}

1;
