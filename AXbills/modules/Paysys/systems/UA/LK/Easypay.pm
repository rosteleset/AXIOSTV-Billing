=head1 Easypay
  New module for Easypay

  Documentaion: http://provider.easysoft.com.ua/

  DATE: 6.12.2018
  UPDATE: 20200805
  VERSION: 7.07

=cut

use strict;
use warnings;
use AXbills::Base qw(_bp load_pmodule encode_base64);
use AXbills::Fetcher qw(web_request);
use Paysys;

load_pmodule('JSON');
load_pmodule('Digest::SHA');
require Encode;
require Paysys::Paysys_Base;
package Paysys::systems::Easypay;
our $PAYSYSTEM_NAME = 'Easypay';
our $PAYSYSTEM_SHORT_NAME = 'Easypay';
our $PAYSYSTEM_ID = 57;
our $PAYSYSTEM_VERSION = '7.07';

my $CUSTOM_NAME = uc($PAYSYSTEM_NAME);
my $CUSTOM_ID   = $PAYSYSTEM_ID;

our %PAYSYSTEM_CONF = (
  PAYSYS_NAME_ACCOUNT_KEY    => '',
  PAYSYS_NAME_FASTPAY        => '',
  PAYSYS_NAME_PAYEE_ID       => '',
  PAYSYS_NAME_PAYEE_NAME     => '',
  PAYSYS_NAME_BANK_NAME      => '',
  PAYSYS_NAME_BANK_MFO       => '',
  PAYSYS_NAME_BANK_ACCOUNT   => '',
  PAYSYS_NAME_NARRATIVE_NAME => '',
  PAYSYS_NAME_PARTNER_KEY    => '',
  PAYSYS_NAME_SERVICE_KEY    => '',
  PAYSYS_NAME_SECRET_KEY     => '',
);

#my $tmp = '/tmp';
#my $self_private = "/usr/axbills/Certs/easysoft_private.ppk";
#my $self_public = "/usr/axbills/Certs/easysoft_public.pem";
#my $server_public = "/usr/axbills/Certs/easysoft_server_public.pem";

my ($html);
our (@payments);

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

  $self->{Paysys} = Paysys->new($self->{db}, $self->{admin}, $self->{conf});

  return $self;
}

#**********************************************************
=head2 proccess(\%FORM) - main function that managing requests
                          between Easypay_provider_protocol and Easypay_merchant_api

  Arguments:
    $FORM - HASH REF to %FORM

  Returns:

=cut
#**********************************************************
sub proccess {
  my $self = shift;
  my ($FORM) = @_;

  $FORM->{__BUFFER} = '' if (!$FORM->{__BUFFER});

  if ($FORM->{__BUFFER} =~ /<Request>/) {
    $self->proccess_easypay_provider($FORM);
    return 1;
  }
  else {
    $self->proccess_easypay_merchant($FORM);
    return 1;
  }
}

#**********************************************************
=head2 proccess_easypay_provider(\%FORM) - function that proccesing easypay payment
                          on paysys_check.cgi

  Arguments:
    $FORM - HASH REF to %FORM
    XML
  Returns:

=cut
#**********************************************************
sub proccess_easypay_provider {
  my $self = shift;
  my ($FORM) = @_;

  $FORM->{__BUFFER} = '' if (!$FORM->{__BUFFER});

  if ($self->{DEBUG} > 2) {
    print "Content-Type: text/plain\n\n";
  }
  else {
    print "Content-Type: text/xml\n\n";
  }

  my $mod_return = main::load_pmodule('XML::Simple', { SHOW_RETURN => 1 });

  if ($mod_return) {
    main::mk_log($mod_return, { PAYSYS_ID => $CUSTOM_NAME });
  }

  $FORM->{__BUFFER} =~ s/encoding="windows-1251"//g;
  my $_xml = eval {XML::Simple::XMLin("$FORM->{__BUFFER}", forcearray => 1)};

  if ($@) {
    main::mk_log("-- Content:\n" . $FORM->{__BUFFER} . "\n-- XML Error:\n" . $@ . "\n--\n",
      { PAYSYS_ID => $CUSTOM_NAME });
    return 0;
  }
  else {
    if ($self->{DEBUG} > 0) {
      main::mk_log($FORM->{__BUFFER}, { PAYSYS_ID => $CUSTOM_NAME });
    }
  }

  my %request_hash = %$_xml;

  while (my ($k, $v) = each %{$_xml}) {
    $request_hash{$k} = (ref $v eq 'ARRAY') ? $v->[0] : $v;
  }

  my $CHECK_FIELD = $self->{conf}{"PAYSYS_" . $CUSTOM_NAME . "_ACCOUNT_KEY"} || 'UID';
  my $status = 0;
  my %status_hash = (
    '0'    => 'OK',
    '-6'   => 'Payment Exist',
    '-11', => 'Payment operation disable',
    '-300' => 'SQL Error',
    '-200' => 'User not found',
    '-79'  => 'Payment not found',
    '-80'  => 'Wrong Signature',
  );

  my %status_compare = (
    0  => 0,
    1  => -200,
    2  => -300,
    3  => -6,
    8  => -79,
    11 => -11, #Disable paysys
    12 => -300
  );

  $FORM->{__BUFFER} =~ s/<Sign>(\S+)<\/Sign>/<Sign><\/Sign>/g;
  #  my $key = $1;

  if ($request_hash{Check}) {
    my $account = $request_hash{Check}{Account}->[0];
    my ($result, $user_info) = main::paysys_check_user({
      EXTRA_FIELDS => {
        CONTRACT_ID   => '_SHOW',
        CONTRACT_DATE => '_SHOW',
      },
      CHECK_FIELD  => $CHECK_FIELD,
      USER_ID      => $account,
      DEBUG        => $self->{DEBUG} || 1,
    });

    if ($status == 0) {
      if ($result == 2) {
        $status = -300;
      }
      elsif ($result == 1) {
        $status = -200;
      }
      elsif ($result == 11) {
        $status = -11;
      }
    }

    my $login = $user_info->{login} || '';
    my $fio = $user_info->{fio} || '';
    my $deposit = $user_info->{deposit} || '';
    #    my $gid = $user_object->{gid} || 0;
    my $contract_id = $user_info->{contract_id} || q{};
    my $contract_date = $user_info->{contract_date} || q{};

    if ($user_info->{gid}) {
      $self->account_gid_split($user_info->{gid});
    }

    my $account_info = $self->_make_account_info({
      CONTRACT_INFO => qq{# $contract_id $contract_date},
    });

    $self->easysoft_response(
      "<Response>
<StatusCode>$status</StatusCode>
<StatusDetail>$status_hash{$status}</StatusDetail>
<DateTime>$main::DATE" . 'T' . "$main::TIME</DateTime>
<Sign></Sign>
<AccountInfo>
<Login>$login</Login>
<Name>" . $fio . " $contract_id $contract_date</Name>
<Deposit>$deposit</Deposit>
</AccountInfo>
$account_info
</Response>"
    );

    return 1;
  }
  elsif ($request_hash{Payment}) {
    my $amount = $request_hash{Payment}{Amount}[0];
    my $account = $request_hash{Payment}{Account}[0];
    my $order_id = $request_hash{Payment}{OrderId}[0];
    my $service_id = $request_hash{Payment}{ServiceId}[0];

    my ($check_result) = main::paysys_check_user({
      EXTRA_FIELDS => {
        CONTRACT_ID   => '_SHOW',
        CONTRACT_DATE => '_SHOW',
      },
      CHECK_FIELD  => $CHECK_FIELD,
      USER_ID      => $account,
      DEBUG        => $self->{DEBUG} || 1,
    });

    if($check_result == 1 || $check_result == 2){
      $self->easysoft_response(
        "<Response>
  <StatusCode>-200</StatusCode>
  <StatusDetail>$status_hash{-200}</StatusDetail>
  <DateTime>$main::DATE" . 'T' . "$main::TIME</DateTime>
<Sign></Sign>
</Response>"
      );
      return 0;
    }
    elsif($check_result == 11){
      $self->easysoft_response(
        "<Response>
  <StatusCode>-11</StatusCode>
  <StatusDetail>$status_hash{-11}</StatusDetail>
  <DateTime>$main::DATE" . 'T' . "$main::TIME</DateTime>
<Sign></Sign>
</Response>"
      );
      return 0;
    }

    my %DATA = (
      AMOUNT     => $amount,
      ACCOUNT    => $account,
      ORDER_ID   => $order_id,
      SERVICE_ID => $service_id,
    );
    my ($status_code, $payments_id) = main::paysys_pay({
      PAYMENT_SYSTEM    => $PAYSYSTEM_SHORT_NAME,
      PAYMENT_SYSTEM_ID => $CUSTOM_ID,
      CHECK_FIELD       => $CHECK_FIELD,
      USER_ID           => $account,
      SUM               => $amount,
      EXT_ID            => $order_id,
      DATA              => \%DATA,
      DATE              => "$main::DATE $main::TIME",
      MK_LOG            => 1,
      PAYMENT_ID        => 1,
      ERROR             => 1,
      DEBUG             => $self->{DEBUG},
      PAYMENT_DESCRIBE  => $FORM->{payment_describe} || 'Easypay Payments',
    });

    if ($payments_id && $status_code == 1) {
      $self->easysoft_response(
        "<Response>
  <StatusCode>0</StatusCode>
  <StatusDetail>$status_hash{0}</StatusDetail>
  <DateTime>$main::DATE" . 'T' . "$main::TIME</DateTime>
<Sign></Sign>
<PaymentId>$payments_id</PaymentId>
</Response>"
      );
    }
    else {
      $self->easysoft_response(
        "<Response>
  <StatusCode>-6</StatusCode>
  <StatusDetail>$status_hash{-6}</StatusDetail>
  <DateTime>$main::DATE" . 'T' . "$main::TIME</DateTime>
<Sign></Sign>
<PaymentId></PaymentId>
</Response>"
      );
    }
  }
  elsif( $request_hash{Confirm}){
    my $payment_id = $request_hash{Confirm}{PaymentId}[0];
    #    my $service_id = $request_hash{Confirm}{ServiceId}[0];
    my $paysys_status = main::paysys_pay({
      PAYMENT_SYSTEM    => $PAYSYSTEM_SHORT_NAME,
      PAYMENT_SYSTEM_ID => $CUSTOM_ID,
      SUM               => 0,
      PAYSYS_ID         => $payment_id,
      #ERROR             => $error,
      #      MK_LOG            => 1

    });

    my $pay_info = main::paysys_info({ PAYSYS_ID => $payment_id });

    my $sum        = $pay_info->{SUM};
    my $order_date = $pay_info->{DATETIME};
    $order_date =~ s/ /T/;

    $status = ($status_compare{$paysys_status}) ? $status_compare{$paysys_status} : 0;

    $self->easysoft_response(
      "<Response>
<StatusCode>$status</StatusCode>
<StatusDetail>$status_hash{$status}</StatusDetail>
<DateTime>$main::DATE" . 'T' . "$main::TIME</DateTime>
<Sign></Sign>
<OrderDate>$order_date</OrderDate>
<Parameters>
<Parameter1>$sum</Parameter1>
</Parameters>
</Response>"
    );
  }
  elsif($request_hash{Cancel}){
    my $payment_id = $request_hash{Cancel}{PaymentId}[0];
    #    my $service_id = $request_hash{Cancel}{ServiceId}[0];

    my $result = main::paysys_pay_cancel({
      PAYSYS_ID => $payment_id
    });

    if($result == 0 || $result == 10){
      $status = 0;
    }

    $self->easysoft_response(
      "<Response>
<StatusCode>$status</StatusCode>
<StatusDetail>$status_hash{$status}</StatusDetail>
<DateTime>$main::DATE" . 'T' . "$main::TIME</DateTime>
<Sign></Sign>
<CancelDate>". $main::DATE. 'T' ."$main::TIME</CancelDate>
</Response>"
    );
  }
}

#**********************************************************
=head2 proccess_easypay_merchant(\%FORM) - function that proccesing easypay_merchant_api payment
                          on paysys_check.cgi

  Arguments:
    $FORM - HASH REF to %FORM
    JSON
  Returns:

=cut
#**********************************************************
sub proccess_easypay_merchant {
  my $self = shift;
  my ($FORM) = @_;

  $FORM = () if (!$FORM);

  print "Content-Type: text/html\n\n";

  if ($self->{DEBUG} > 0) {
    my $info = q{};
    while (my ($k, $v) = each %$FORM) {
      $info .= "$k => $v\n" if ($k ne '__BUFFER');
    }
    main::mk_log($info, { PAYSYS_ID => $CUSTOM_NAME });
  }

  my $responce_params = JSON::decode_json($FORM->{__BUFFER});

  if ($responce_params->{action} && $responce_params->{action} eq 'payment') {
    if ($responce_params->{details}{recurrent_id}) {
      my $payment_info = main::paysys_get_full_info({
        TRANSACTION_ID => "$PAYSYSTEM_SHORT_NAME:$responce_params->{order_id}"
      });

      if ($payment_info->{status} eq '1') {
        $self->{Paysys}->paysys_user_change({
          UID          => $payment_info->{uid},
          RECURRENT_ID => $responce_params->{details}{recurrent_id},
        });

        if ($self->{Paysys}->{errno}) {
          main::mk_log("Error payment: $self->{Paysys}->{errno}", { PAYSYS_ID => "$CUSTOM_NAME" });
          return 0;
        }

        my $status_code = main::paysys_pay({
          PAYMENT_SYSTEM    => $PAYSYSTEM_SHORT_NAME,
          PAYMENT_SYSTEM_ID => $CUSTOM_ID,
          SUM               => $responce_params->{details}{amount},
          ORDER_ID          => "$PAYSYSTEM_SHORT_NAME:$responce_params->{order_id}",
          EXT_ID            => "$responce_params->{order_id}",
          DATA              => $responce_params,
          DATE              => "$responce_params->{date}",
          MK_LOG            => 1,
          DEBUG             => $self->{DEBUG},
          PAYMENT_DESCRIBE  => $responce_params->{details}{desc} || "$CUSTOM_NAME payment",
        });

        if ($status_code == 0) {
          print "$status_code";
          main::mk_log("Payment completed: $PAYSYSTEM_SHORT_NAME:$responce_params->{order_id}", { PAYSYS_ID => "$CUSTOM_NAME" });
        }
        elsif ($status_code > 0) {
          print qq{Status: 520 Wrong Status
Content-type: text/html

<HTML>
<HEAD><TITLE>520 Wrong Status</TITLE></HEAD>
<BODY>
  <H1>Error</H1>
  <P>Wrong Status</P>
</BODY>
</HTML>
    };
          main::mk_log("ERROR: status - $status_code", { PAYSYS_ID => "$CUSTOM_NAME" });
        }
        return 1;
      }
      elsif ($payment_info->{status} eq '2') {
        my $info = $self->{Paysys}->paysys_user_info({
          RECURRENT_ID => $responce_params->{details}{recurrent_id},
        });

        if ($self->{Paysys}->{errno}) {
          main::mk_log("Error payment: $self->{Paysys}->{errno}", { PAYSYS_ID => "$CUSTOM_NAME" });
          return 0;
        }
        my $order_id = main::mk_unique_value(8, { SYMBOLS => '0123456789' });
        my ($status_code, $payments_id) = main::paysys_pay({
          PAYMENT_SYSTEM    => $PAYSYSTEM_SHORT_NAME,
          PAYMENT_SYSTEM_ID => $CUSTOM_ID,
          CHECK_FIELD       => 'UID',
          USER_ID           => $info->{UID},
          SUM               => $responce_params->{details}{amount},
          EXT_ID            => "$order_id",
          DATA              => $responce_params,
          DATE              => "$responce_params->{date}",
          PAYMENT_ID        => 1,
          DEBUG             => $self->{DEBUG},
          PAYMENT_DESCRIBE  => $responce_params->{details}{desc} || "$CUSTOM_NAME payment",
        });

        if ($status_code == 0) {
          print "$status_code";
          main::mk_log("Payment completed: $PAYSYSTEM_SHORT_NAME:$order_id", { PAYSYS_ID => "$CUSTOM_NAME" });
        }
        elsif ($status_code > 0) {
          print qq{Status: 520 Wrong Status
Content-type: text/html

<HTML>
<HEAD><TITLE>520 Wrong Status</TITLE></HEAD>
<BODY>
  <H1>Error</H1>
  <P>Wrong Status</P>
</BODY>
</HTML>
    };
          main::mk_log("ERROR: status - $status_code", { PAYSYS_ID => "$CUSTOM_NAME" });
        }
        return 1;

      }
      return 1;
    }
    else {
      return 0 if !$responce_params->{order_id};
      my $status_code = main::paysys_pay({
        PAYMENT_SYSTEM    => $PAYSYSTEM_SHORT_NAME,
        PAYMENT_SYSTEM_ID => $CUSTOM_ID,
        SUM               => $responce_params->{details}{amount},
        ORDER_ID          => "$PAYSYSTEM_SHORT_NAME:$responce_params->{order_id}",
        EXT_ID            => "$responce_params->{order_id}",
        DATA              => $responce_params,
        DATE              => "$responce_params->{date}",
        MK_LOG            => 1,
        DEBUG             => $self->{DEBUG},
        PAYMENT_DESCRIBE  => $responce_params->{details}{desc} || "$CUSTOM_NAME payment",
      });

      if ($status_code == 0) {
        print "$status_code";
        main::mk_log("Payment completed: $responce_params", { PAYSYS_ID => "$CUSTOM_NAME" });
      }
      elsif ($status_code > 0) {
        print qq{Status: 520 Wrong Status
Content-type: text/html

<HTML>
<HEAD><TITLE>520 Wrong Status</TITLE></HEAD>
<BODY>
  <H1>Error</H1>
  <P>Wrong Status</P>
</BODY>
</HTML>
    };
        main::mk_log("ERROR: status - $status_code", { PAYSYS_ID => "$CUSTOM_NAME" });
      }
      return 1;
    }
  }
  elsif ($responce_params->{action} && $responce_params->{action} eq 'refund') {
    my $result = main::paysys_pay_cancel({
      TRANSACTION_ID => "$PAYSYSTEM_SHORT_NAME:$responce_params->{order_id}"
    });

    if ($result == 0) {
      print "ok";
      main::mk_log("Payment  $responce_params->{order_id} canceled: $responce_params", { PAYSYS_ID => "$CUSTOM_NAME" });
      return 1;
    }
    else {
      main::mk_log("ERROR: Bad request - $responce_params", { PAYSYS_ID => "$CUSTOM_NAME" });

      return qq{Status: 520 Wrong Status
Content-type: text/html

<HTML>
<HEAD><TITLE>520 Wrong Status</TITLE></HEAD>
<BODY>
  <H1>Error</H1>
  <P>Wrong Status</P>
</BODY>
</HTML>
    };
    }
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
=head2 user_portal()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub user_portal {
  my $self = shift;
  my ($user, $attr) = @_;
  $self->account_gid_split($user->{GID});

  if (($self->{conf}{"PAYSYS_" . $CUSTOM_NAME . "_FASTPAY"} && $self->{conf}{"PAYSYS_" . $CUSTOM_NAME . "_PARTNER_KEY"}) && !$attr->{easypay_provider} && !$attr->{easypay_merchant}) {
    my %hidden_info = ();
    $hidden_info{INDEX} = $attr->{index};
    $hidden_info{SUM} = $attr->{SUM};
    $hidden_info{DESCRIBE} = $attr->{DESCRIBE};
    $hidden_info{OPERATION_ID} = $attr->{OPERATION_ID};
    $hidden_info{PAYMENT_SYSTEM} = $attr->{PAYMENT_SYSTEM};
    return $html->tpl_show(main::_include('paysys_easypay_choose', 'Paysys'), { %hidden_info }, { OUTPUT2RETURN => 0 });
  }
  elsif (($self->{conf}{"PAYSYS_" . $CUSTOM_NAME . "_FASTPAY"} && !$self->{conf}{"PAYSYS_" . $CUSTOM_NAME . "_PARTNER_KEY"}) || $attr->{easypay_provider}) {
    $self->user_portal_easypay_provider($user, $attr);
    return 1;
  }
  elsif (($self->{conf}{"PAYSYS_" . $CUSTOM_NAME . "_FASTPAY"} && !$self->{conf}{"PAYSYS_" . $CUSTOM_NAME . "_PARTNER_KEY"}) || $attr->{easypay_merchant}) {
    $self->user_portal_merchant_api($user, $attr);
    return 1;
  }
  else {
    $html->message('err', $attr->{LANG}->{ERROR}, "Payment system has wrong configuration");
    return 0;
  }
}

#**********************************************************
=head2 user_portal_merchant_api()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub user_portal_merchant_api {
  my $self = shift;
  my ($user, $attr) = @_;
  my $appId = q{};
  my $requestedSessionId = q{};
  my $pageId = q{};
  my @headers = ();
  my $sign = q{};
  my $request_body = ();
  my $content_length = 0;
  my $lang = $attr->{LANG};
  my %pay_params = ();

  if ($user->{GID}) {
    $self->account_gid_split($user->{GID});
  }

  if (!$self->{conf}{"PAYSYS_" . $CUSTOM_NAME . "_PARTNER_KEY"} || !$self->{conf}{"PAYSYS_" . $CUSTOM_NAME . "_SERVICE_KEY"} || !$self->{conf}{"PAYSYS_" . $CUSTOM_NAME . "_SECRET_KEY"}) {
    $html->message('err', $lang->{ERROR}, "Payment system has wrong configuration");
    return 0;
  }
  if (!$attr->{SUM} || $attr->{SUM} == 0) {
    $html->message('err', $lang->{ERROR}, "Payment sum is too small.");
    return 0;
  }

  if ($attr->{MAKE_PAYMENT}) {
    #  CreateApp
    push @headers, qq{partnerKey: $self->{conf}{"PAYSYS_" . $CUSTOM_NAME . "_PARTNER_KEY"}};
    push @headers, qq{locale: ua};
    push @headers, qq{Content-Length: 0};

    my $responce_createApp = send_request({
      URL     => qq{https://api.easypay.ua/api/system/createApp},
      HEADERS => \@headers,
      DEBUG   => $self->{DEBUG},
    });
    $appId = $responce_createApp->{appId};
    $requestedSessionId = $responce_createApp->{requestedSessionId};
    $pageId = $responce_createApp->{pageId};

    #CreateOrder
    @headers = ();
    $request_body = {
      "order" => {
        "serviceKey"  => $self->{conf}{"PAYSYS_" . $CUSTOM_NAME . "_SERVICE_KEY"},
        'orderId'     => $attr->{OPERATION_ID},
        'description' => Encode::decode('utf-8', $attr->{DESCRIBE} ),
        'amount'      => $attr->{SUM},
      },
    };
    if ($attr->{CREATE_REGULAR_PAYMENT}) {
      my $cron = q{};
      my $dateExpire = q{};
      my ($Y, $M, $D) = split(/-/, $main::DATE, 3);
      my ($H, $MIN, $S) = split(/:/, $main::TIME, 3);
      $D = 28 if ($D > 28);
      $cron = qq{$MIN $H $D * *};
      $Y = $Y + 100;
      $dateExpire = qq{$Y-$M-$D} . q{T} . $main::TIME;
      $request_body->{reccurent} = {
        'cronRule'   => $cron,
        'dateExpire' => $dateExpire,
      };

      $self->{Paysys}->paysys_user_add({
        UID              => $user->{UID},
        RECURRENT_CRON   => $cron,
        RECURRENT_MODULE => $CUSTOM_NAME,
      });

      if ($self->{Paysys}->{errno}) {
        $html->message('err', "ERROR", "Recurrent payment exists! Paysys: '$self->{Paysys}->{errstr}'");
        return 0;
      }
    }

    $request_body = JSON::encode_json($request_body);
    $content_length = length($request_body);
    $sign = AXbills::Base::encode_base64(Digest::SHA::sha256($self->{conf}{"PAYSYS_" . $CUSTOM_NAME . "_SECRET_KEY"} . $request_body));
    $sign =~ s/\n//g;
    push @headers, qq{locale: ua};
    push @headers, qq{requestedSessionId: $requestedSessionId};
    push @headers, qq{appId: $appId};
    push @headers, qq{pageId: $pageId};
    push @headers, qq{partnerKey: $self->{conf}{"PAYSYS_" . $CUSTOM_NAME . "_PARTNER_KEY"}};
    push @headers, qq{sign: $sign};
    push @headers, qq{Content-Type:application/json};
    push @headers, qq{Content-Length: $content_length};
    $request_body =~ s/"/\\\"/g;
    my $responce_createOrder = send_request({
      URL       => qq{https://api.easypay.ua/api/merchant/createOrder},
      HEADERS   => \@headers,
      POST_DATA => $request_body,
      DEBUG     => $self->{DEBUG},
    });

    my $forwardUrl = $responce_createOrder->{forwardUrl} || '';

    #Payment info to paysys_log
    $self->{Paysys}->add(
      {
        SYSTEM_ID      => $CUSTOM_ID,
        SUM            => $attr->{SUM},
        COMMISSION     => 0,
        UID            => $attr->{UID} || $user->{UID},
        IP             => $ENV{'REMOTE_ADDR'},
        TRANSACTION_ID => "$PAYSYSTEM_SHORT_NAME:$attr->{OPERATION_ID}",
        INFO           => $attr->{DESCRIBE},
        PAYSYS_IP      => "$ENV{'REMOTE_ADDR'}",
        STATUS         => 1,
        DOMAIN_ID      => $user->{DOMAIN_ID},
      }
    );

    if ($self->{Paysys}->{errno}) {
      $html->message('err', "ERROR", "ERROR Paysys ID: '$attr->{OPERATION_ID}'");
      return 0;
    }

    return $html->tpl_show(main::_include('paysys_easypay_payment', 'Paysys'), { FORWARDURL => $forwardUrl }, { OUTPUT2RETURN => 0 });
  }
  else {
    $pay_params{INDEX} = $attr->{index};
    $pay_params{PAYMENT_SYSTEM} = $attr->{PAYMENT_SYSTEM};
    $pay_params{OPERATION_ID} = $attr->{OPERATION_ID};
    $pay_params{SUM} = $attr->{SUM};
    $pay_params{DESCRIBE} = $attr->{DESCRIBE};
    $pay_params{CREATE_REGULAR_PAYMENT} = $html->form_input('CREATE_REGULAR_PAYMENT', 1, { TYPE => 'checkbox', OUTPUT2RETURN => 1 });

    return $html->tpl_show(main::_include('paysys_easypay_userportal', 'Paysys'), \%pay_params, { OUTPUT2RETURN => 0 });
  }

}

#**********************************************************
=head2 user_portal_easypay_provider()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub user_portal_easypay_provider {
  my $self = shift;
  my ($user, $attr) = @_;
  $self->account_gid_split($user->{GID});

  if (!$user->{$self->{conf}{"PAYSYS_" . $CUSTOM_NAME . "_ACCOUNT_KEY"}}) {
    $user->pi();
  }

  my $link = $self->{conf}{"PAYSYS_" . $CUSTOM_NAME . "_FASTPAY"}
    . "?account="
    . ($user->{$self->{conf}{"PAYSYS_" . $CUSTOM_NAME . "_ACCOUNT_KEY"}} || $attr->{$self->{conf}{"PAYSYS_" . $CUSTOM_NAME . "_ACCOUNT_KEY"}})
    . "&amount="
    . ($attr->{SUM} || 0);

  return $html->tpl_show(main::_include('paysys_easypay_fastpay', 'Paysys'), { LINK => $link }, { OUTPUT2RETURN => 0 });
}

#**********************************************************
=head2 easysoft_response($response, $attr)

=cut
#**********************************************************
sub easysoft_response {
  my $self = shift;
  my ($response) = @_;
  $response =~ s/[\r\n]//g;

  print $response;

  main::mk_log("$response", { PAYSYS_ID => "Answer to $CUSTOM_NAME" }) if ($self->{DEBUG} > 0);
  return 0;
}

#**********************************************************
=head2 reports()

=cut
#**********************************************************
sub report {
  my $self = shift;
  my ($attr) = @_;

  $html = $attr->{HTML};
  my $lang = $attr->{LANG};

  my $Paysys = Paysys->new($self->{db}, $self->{admin}, $self->{conf});
  my $ls = $Paysys->paysys_report_list({TABLE => 'paysys_easypay_report', COLS_NAME => 1});

  my $table = $html->table(
    {
      width      => '100%',
      caption    => "Easypay",
      title      => [ "#", "UID", "$lang->{SUM}", "$lang->{DATE}", "ID" ],
      DATA_TABLE => 1,
    }
  );

  foreach my $payment (@$ls){
    $table->addrow($payment->{id}, $payment->{uid}, $payment->{sum}, $payment->{date}, $payment->{payment_id},);
  }

  print $table->show();

  return 1;
}

#**********************************************************
=head2 periodic()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
#sub periodic {
#  my $self = shift;
#  my ($attr) = @_;
#
#  use Paysys;
#  my $Paysys = Paysys->new($self->{db}, $self->{admin}, $self->{conf});
#
##  main::load_pmodule('Net::FTPSSL');
##    main::load_pmodule('Net::FTP');
#
#  my $host = "93.183.196.26";#$self->{conf}{PAYSYS_EASYPAY_HOST};
#  my $login = "onet";#$self->{conf}{PAYSYS_EASYPAY_LOGIN};
#  my $pass = 'E$_OneT$';#$self->{conf}{PAYSYS_EASYPAY_PASSWORD};
#  my $DATE = $attr->{DATE};
#
#  use Net::SFTP;
#  my %configuration = (
#    ssh_args => [ port => 22 ], user => $login, password => $pass, debug => 10
#  );
#  my $ftp = Net::SFTP->new($host, %configuration);
#  #  my $ftp = Net::FTPSSL->new("$host", useSSL => 0, Timeout => 10, Debug => 10, Port => 29280, SSL_Client_Certificate => {
#  #      SSL_version   => 'TLSv1',
#  #    },       )
#  #    or die "Cannot connect to '$host': $@";
#  #  my $ftp = Net::FTP->new("$host", Debug => 10, Port => 29280)
#  #    or die "Cannot connect to $host: $@";
#  #  $ftp->login("$login", "$pass");
#  my @files = $ftp->ls("/reports/");
#
#  foreach my $file (@files) {
#    my $file_name = $file->{filename};
#    my $data = '2019-01-03';
#    if ($file_name =~ /$main::DATE/m) {
#      $ftp->get("/reports/$file_name", "/usr/$file_name", \&_r_file);
#
#      foreach my $payment (@payments) {
#        my @data = split('\;', $payment);
#        my $uid = $data[0];
#        my $sum = $data[1];
#        my ($date) = split('T', $data[8]);
#        my $id = $data[14];
#        $Paysys->paysys_report_add({
#          UID        => $uid,
#          SUM        => $sum,
#          DATE       => $date,
#          PAYMENT_ID => $id,
#          TABLE      => 'paysys_easypay_report',
#        });
#      }
#    }
#    else {
#      print "\nNo file for chosen date!\n"
#    }
#  }
#  #    or die "Ftp get failed '$file' ", $ftp->message;
#  #
#  #    my @csv_data = ();
#  #    open( my $fh, '<', "$file" ) or print "Can't open '$file'. $!";
#  #    while (<$fh>) {
#  #      push (@csv_data, $_);
#  #    }
#  #
#  #    foreach my $payment ( @csv_data ) {
#  #      my ($uid, $sum, undef, undef, undef, undef, undef, undef, $date) = split(';', $payment);
#  #      print "$uid - $sum - $date\n";
#  #      $Paysys->{debug}=1;
#  #      $Paysys->paysys_report_add({
#  #        TABLE => 'paysys_easypay_report',
#  #        UID   => $uid,
#  #        SUM   => $sum,
#  #        DATE  => $date,
#  #      });
#  #
#  #    }
#
#
#  return 1;
#}

#**********************************************************
=head2 account_gid_split($gid)

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

# #**********************************************************
# =head2 _r_file()
#
#   Arguments:
#      -
#
#   Returns:
#
# =cut
# #**********************************************************
# sub _r_file{
#   my($sftp, $data, $offset, $size) = @_;
#   my @data = split("\n", $data);
#
#   foreach my $line (@data){
#     #my @data = split('\;', $line);
#     push (@payments, $line);
#   }
# }

#**********************************************************
=head2 _make_account_info($attr)

  Arguments:
    $attr -

  Returns:

=cut
#**********************************************************
sub _make_account_info {
  my $self = shift;
  my ($attr) = @_;

  my $account_info = qq{};
  my $contract_info = $attr->{CONTRACT_INFO} || q{};
  my $payee_id       = $self->{conf}{"PAYSYS_" . $CUSTOM_NAME . "_PAYEE_ID"} || q{};
  my $payee_name     = $self->{conf}{"PAYSYS_" . $CUSTOM_NAME . "_PAYEE_NAME"} || q{};
  my $bank_name      = $self->{conf}{"PAYSYS_" . $CUSTOM_NAME . "_BANK_NAME"} || q{};
  my $bank_mfo       = $self->{conf}{"PAYSYS_" . $CUSTOM_NAME . "_BANK_MFO"} || q{};
  my $bank_account   = $self->{conf}{"PAYSYS_" . $CUSTOM_NAME . "_BANK_ACCOUNT"} || q{};
  my $narrative_name = $self->{conf}{"PAYSYS_" . $CUSTOM_NAME . "_NARRATIVE_NAME"} || q{};

  if ($contract_info) {
    $narrative_name =~ s/\%CONTRACT_INFO\%/$contract_info/g;
  }

  my ($year, $month, $day) = split("-", $main::DATE);
  $narrative_name =~ s/\%CUR_DATE\%/$day\.$month\.$year/g;

  $account_info = qq{<BankingDetails><Payee><Id>$payee_id</Id><Name>$payee_name</Name><Bank><Name>$bank_name</Name><Mfo>$bank_mfo</Mfo><Account>$bank_account</Account></Bank>}
    . qq{</Payee><Narrative><Name>$narrative_name</Name><Vat>0</Vat></Narrative></BankingDetails>};

  return $account_info;
}

#**********************************************************
=head2 send_request($attr)

  Arguments:
    $attr -

  Returns:

=cut
#**********************************************************
sub send_request {
  my ($attr) = @_;
  my $url = $attr->{URL} || q{};
  my $headers = $attr->{HEADERS} || '';
  my $post_data = $attr->{POST_DATA} || 1;
  my $debug = $attr->{DEBUG} || 0;

  my $responce = AXbills::Fetcher::web_request(
    $url,
    {
      CURL    => 1,
      DEBUG   => $debug > 1? $debug:0,
      POST    => $post_data,
      HEADERS => $headers,
    }
  );

  my $responce_params = JSON::decode_json($responce);

  return $responce_params;
}

#**********************************************************
=head2 recurrent_cancel($attr)

  Arguments:
    $attr -

  Returns:

=cut
#**********************************************************
sub recurrent_cancel {
  my $self = shift;
  my ($attr) = @_;
  my $appId = q{};
  my $pageId = q{};
  my @headers = ();
  my $sign = q{};

  #  CreateApp
  push @headers, qq{partnerKey: $self->{conf}{"PAYSYS_" . $CUSTOM_NAME . "_PARTNER_KEY"}};
  push @headers, qq{locale: ua};
  push @headers, qq{Content-Length: 0};

  my $responce_createApp = send_request({
    URL     => qq{https://api.easypay.ua/api/system/createApp},
    HEADERS => \@headers,
    DEBUG   => $self->{DEBUG},
  });

  $appId = $responce_createApp->{appId};
  $pageId = $responce_createApp->{pageId};
  @headers = ();
  #  Delete recurrent payment
  $sign = AXbills::Base::encode_base64(Digest::SHA::sha256($self->{conf}{"PAYSYS_" . $CUSTOM_NAME . "_SECRET_KEY"}));
  $sign =~ s/\n//g;
  push @headers, qq{partnerKey: $self->{conf}{"PAYSYS_" . $CUSTOM_NAME . "_PARTNER_KEY"}};
  push @headers, qq{locale: ua};
  push @headers, qq{appId: $appId};
  push @headers, qq{pageId: $pageId};
  push @headers, qq{Sign: $sign};

  my $url = qq{https://api.easypay.ua/api/merchant/recurrent/delete/} . qq{$attr->{RECURRENT_ID}};
  my $responce = AXbills::Fetcher::web_request(
    $url,
    {
      CURL         => 1,
      CURL_OPTIONS => '-X "DELETE"',
      DEBUG        => 5,
      STATUS_CODE  => 1,
      HEADERS      => \@headers,
    }
  );
  my $status_code;
  if ($responce) {
    ($status_code) = $responce =~ /HTTP\/\d+.\d+\s(\d+)/g;
    if ($status_code && $status_code eq '200') {
      $self->{Paysys}->paysys_main_del({ RECURRENT_ID => $attr->{RECURRENT_ID} });
      if ($self->{Paysys}->{errno}) {
        $html->message('err', "ERROR", "ERROR Paysys RECURRENT_ID: '$attr->{RECURRENT_ID}'");
        return 0;
      }
    }
  }

  return $status_code, $responce;
}

1;