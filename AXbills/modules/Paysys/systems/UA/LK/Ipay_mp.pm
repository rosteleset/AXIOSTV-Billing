package Paysys::systems::Ipay_mp;
=head1 NAME

  Ipay Masterpass
  New module for Ipay payment system


=head1 DOCUMENTATION

  https://walletmc.ipay.ua/doc.php

=head1 IPs

  89.111.46.143
  89.111.46.144
  62.80.166.62
  109.237.93.180
  81.94.235.66
  86.111.90.144/28
  81.94.235.64/28

=head2 VERSION

  Date: 07.06.2018
  UPDATED: 20220812
  VERSION: 8.28

=cut

use strict;
use warnings FATAL => 'all';
use parent 'dbcore';
use utf8;

use Paysys;
use AXbills::Base qw(load_pmodule json_former);
use AXbills::Fetcher;
require AXbills::Templates;
require Paysys::Paysys_Base;

our $PAYSYSTEM_VERSION   = '8.28';
my $PAYSYSTEM_NAME       = 'Ipay_mp';
my $PAYSYSTEM_SHORT_NAME = 'IPAY';
my $PAYSYSTEM_ID         = 72;

my %PAYSYSTEM_CONF = (
  PAYSYS_IPAY_LANGUAGE     => 'ua',
  PAYSYS_IPAY_FAST_PAY     => '1',
  PAYSYS_IPAY_REQUEST_URL  => 'https://walletmc.ipay.ua/',
  PAYSYS_IPAY_SIGN_KEY     => '',
  PAYSYS_IPAY_MERCHANT_KEY => '',
  PAYSYS_IPAY_NOTIFY_KEY   => '', # key for Ipay web portal payment
  PAYSYS_IPAY_ACCOUNT_KEY  => 'UID',
  PAYSYS_IPAY_DESC_KEY     => ''
);

my ($json, $html, $SELF_URL);
#our (@payments);

#**********************************************************
=head2 new()

  Arguments:
     -

  Returns:

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

  if($attr->{LANG}) {
    $self->{lang} = $attr->{LANG};
  }

  if($attr->{INDEX}){
    $self->{index} = $attr->{INDEX};
  }

  if($attr->{SELF_URL}){
    $SELF_URL = $attr->{SELF_URL};
  }

  load_pmodule('JSON');
  $json = JSON->new->allow_nonref;

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 create_request_params($action, $attr) -

  Arguments:
    $action
    $attr
      USER

  Returns:

  Examples:

=cut
#**********************************************************
sub create_request_params {
  my $self = shift;
  my ($action, $attr) = @_;

  my $user = $attr->{USER};

  ($user->{PHONE}) = $user->{PHONE} =~ /(\d+)/;
  $user->{PHONE} =~ s/^0/380/;

  main::conf_gid_split({
    GID    => $user->{GID},
    PARAMS => [ keys %PAYSYSTEM_CONF ]
  });

  my $merchant_key = $self->{conf}->{PAYSYS_IPAY_MERCHANT_KEY} || q{};
  my $sign_key     = $self->{conf}->{PAYSYS_IPAY_SIGN_KEY} || q{};

  use Time::Piece;
  my $t = localtime;
  my $time = $t->epoch + (($t->isdst) ? 3 : 2) * 60 * 60;
  my $date = POSIX::strftime("%F %X", gmtime($time));
  my $sign_string = $date . $sign_key;
  my $md5 = Digest::MD5->new();
  $md5->add($sign_string);
  my $md5_sign = $md5->hexdigest();
  my $account_key = 'UID';

  my %request = ();
  $request{request}{action}        = $action;
  $request{request}{auth}{time}    = $date;
  $request{request}{auth}{login}   = $merchant_key;
  $request{request}{auth}{sign}    = $md5_sign;
  $request{request}{body}{user_id} = $account_key;
  $request{request}{body}{msisdn}  = $user->{PHONE};

  if ($action eq 'Check' || $action eq 'List') {

  }
  elsif ($action eq 'RegisterByURL') {
    $request{request}{body}{lang}        = $self->{conf}->{PAYSYS_IPAY_LANGUAGE} || 'ru';
    $request{request}{body}{success_url} = "$SELF_URL?index=$self->{index}";                 # url after success registration
    $request{request}{body}{error_url}   = "$SELF_URL?index=$self->{index}";                 # url after fail registration
  }
  elsif ($action eq 'DeleteCard') {
    $request{request}{body}{card_alias} = $attr->{CARD_ALIAS};
  }
  elsif ($action eq 'PaymentCreate') {
    $request{request}{body}{card_alias} = $attr->{CARD_ALIAS};
    $request{request}{body}{invoice}    = $attr->{INVOICE} * 100;

    # $REQUEST_HASH{request}{body}{guid}=$attr->{GUID};
    if($self->{conf}{PAYSYS_IPAY_DESC}){
      $self->{conf}{PAYSYS_IPAY_DESC}   =~ s/\%([^\%]+)\%/($user->{$1} || '')/g;
      $request{request}{body}{pmt_desc} = $self->{conf}{PAYSYS_IPAY_DESC};
    }
    else{
      $request{request}{body}{pmt_desc} = utf8::decode("Оплата услуг согласно счету " . ($user->{_PIN_ABS} || $user->{BILL_ID} || ''));
    }

    $request{request}{body}{pmt_info}{invoice} = $attr->{INVOICE} * 100;
    $request{request}{body}{pmt_info}{acc}     = $account_key;

    $request{request}{body}{threeds_info}{notification_url} = "http://$ENV{SERVER_NAME}" . (($ENV{SERVER_PORT} != 80) ? ":$ENV{SERVER_PORT}" : '') . "/paysys_check.cgi"
      ."?ipay_purchase=1&invoice=" . ($attr->{INVOICE} * 100) . "&pmt_id=$attr->{ACC}&UID=$user->{UID}";
  }
  elsif ($action eq 'AddcardByURL') {
    $request{request}{body}{lang}        = $self->{conf}->{PAYSYS_IPAY_LANGUAGE} || 'ru';
    $request{request}{body}{success_url} = "$SELF_URL?index=$self->{index}";     # url after success registration
    $request{request}{body}{error_url}   = "$SELF_URL?index=$self->{index}";     # url after fail registration
  }
  elsif ($action eq 'RegisterPurchaseByURL') {
    $request{request}{body}{lang}        = $self->{conf}->{PAYSYS_IPAY_LANGUAGE} || 'ru';
    $request{request}{body}{success_url} = "$SELF_URL?index=$self->{index}&ipay_purchase=1&invoice=" . ($attr->{INVOICE} * 100) . "&pmt_id=$attr->{ACC}&UID=$user->{UID}";    # url after success registration
    $request{request}{body}{error_url}   = "$SELF_URL?index=$self->{index}&ipay_purchase=2&&invoice=" . ($attr->{INVOICE} * 100) . "&pmt_id=$attr->{ACC}&UID=$user->{UID}";;   # url after fail registration
    $request{request}{body}{invoice}     = $attr->{INVOICE} * 100;

    if($self->{conf}{PAYSYS_IPAY_DESC}){
      $self->{conf}{PAYSYS_IPAY_DESC} =~ s/\%([^\%]+)\%/($user->{$1} || '')/eg;
      $request{request}{body}{pmt_desc}          = $self->{conf}{PAYSYS_IPAY_DESC};
    }
    else{
      $request{request}{body}{pmt_desc}  = utf8::decode("Оплата услуг согласно счету " . ($user->{_PIN_ABS} || $user->{BILL_ID} || ''));
    }
    $request{request}{body}{pmt_info}{invoice} = $attr->{INVOICE} * 100;
    $request{request}{body}{pmt_info}{acc}     = $account_key;
  }
  elsif ($action eq 'InviteByURL') {
    $request{request}{body}{lang}        = 'ua';
    $request{request}{body}{success_url} = "$SELF_URL?index=$self->{index}"; # url after success registration
    $request{request}{body}{error_url}   = "$SELF_URL?index=$self->{index}"; # url after fail registration
  }
  elsif ($action eq 'UnlinkUser') {
    delete $request{request}{body}{user_id};
  }

  my $json_request_string = json_former(\%request);
  $json_request_string =~ s/\"/\\\"/g;

  return $json_request_string;
}

#**********************************************************
=head2 get_settings()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub get_settings {

  my %SETTINGS = (
    VERSION => $PAYSYSTEM_VERSION,
    ID      => $PAYSYSTEM_ID,
    NAME    => $PAYSYSTEM_NAME,
    CONF    => \%PAYSYSTEM_CONF,
    DOCS    => 'http://axbills.net.ua:8090/display/AB/Ipay',
    IP      => '89.111.46.143,89.111.46.144,89.21.77.5,81.94.235.66'
  );

  return %SETTINGS;
}

#**********************************************************
=head2 _request($request) - Request for IP

  Arguments:
    $request
    $attr
      TREE = Start from tree element

  Returns:
    $result_hash_ref

  Example
    my$result = _request($request_params, { TREE => 'response' });

=cut
#**********************************************************
sub _request {
  my $self = shift;
  my ($request, $attr) = @_;

  my $check_result = web_request($self->{conf}->{PAYSYS_IPAY_REQUEST_URL}, {
    POST       => $request,
    DEBUG2FILE => '/tmp/ipay.log',
    DEBUG      => 1
  });

  if (! $check_result) {
    $html->message('err', $self->{lang}->{ERROR}, $self->{lang}->{ERR_WRONG_DATA}, { ID => 1790 });
    return {};
  }
  elsif ($check_result =~ /Timeout/) {
    $html->message('err', $self->{lang}->{ERROR}, 'Timeout');
    return {};
  }

  my $result = $json->decode($check_result);

  if ($result->{response} && $result->{response}->{error} && $result->{response}->{error}) {
    if ($result->{response}->{error} eq 'user validation failed') { #user validation failed
      $html->message('error', "$self->{lang}->{IPAY_ERR_NUMBER}",
        $html->button("$self->{lang}->{UNLINK}", "index=$self->{index}&ipay_unlink_user=1"));
    } else {
      $html->message('err', $self->{lang}->{ERROR}, $result->{response}->{error}, { ID => 1793 });
    }

    return {};
  }

  if ($attr->{TREE}) {
    $result = $result->{$attr->{TREE}};
  }

  return $result;
}

#**********************************************************
=head2 user_portal_special($user, $attr)

  Arguments:
    $user
    $attr

  Returns:

=cut
#**********************************************************
sub user_portal_special {
  my $self = shift;
  my ($user_, $attr) = @_;

  my $OUTPUT2RETURN = q{};

  # Check the PHONE format
  if ($user_->{PHONE}) {
    ($user_->{PHONE}) = $user_->{PHONE} =~ /(\d+)/;
    $user_->{PHONE} =~ s/^0/380/;

    if ($user_->{PHONE} !~ /^380/ || length($user_->{PHONE}) != 12) {
      $html->message('err', "$self->{lang}->{ERR_WRONG_PHONE} $self->{lang}->{IPAY_NOT_WORKING}",
        "$self->{lang}->{PHONE}: 380XXXXXXXXX", { ID => 1788, REMINDER => 'breadcrumb', class => 'danger' });
      return 0;
    }
  }
  else {
    $html->message('err', "$self->{lang}->{ERR_WRONG_PHONE} $self->{lang}->{IPAY_NOT_WORKING}",
      "$self->{lang}->{PHONE}: 380XXXXXXXXX", { ID => 1789, REMINDER => 'breadcrumb', class => 'danger' });
    return 0;
  }

  # Card delete
  if ($attr->{DeleteCard}) {
    my $json_request_string = $self->create_request_params('DeleteCard', { CARD_ALIAS => $attr->{DeleteCard}, USER => $user_ });
    my $result = $self->_request($json_request_string, { TREE => 'response' });

    if ($result->{status} && $result->{status} eq 'OK') {
      $html->message('info', $self->{lang}->{SUCCESS}, $self->{lang}->{DELETED}, { ID => '1111' });
    }
    else {
      $html->message('err', $self->{lang}->{ERROR}, "$self->{lang}->{NOT} $self->{lang}->{DELETED}", { ID => 1112 });
    }
  }
  # make payment if registered
  elsif ($attr->{ipay_pay}) {
    my $json_create_payment_string = $self->create_request_params(
      'PaymentCreate',
      {
        CARD_ALIAS => $attr->{CARD_ALIAS},
        INVOICE    => $attr->{SUM},
        ACC        => $attr->{OPERATION_ID},
        USER       => $user_,
      }
    );

    my $result = $self->_request($json_create_payment_string, { TREE => 'response' });

    my $desc = 'IPAY MasterPass';
    if ($user_->{PAYSYS_IPAY_DESC_KEY}) {
      $desc = $self->{lang}->{IPAY_DESCRIBE} . $user_->{PAYSYS_IPAY_DESC_KEY};
    }

    if ($result->{pmt_status} && $result->{pmt_status} == 5) {
      my ($status_code) = main::paysys_pay({
        PAYMENT_SYSTEM    => $PAYSYSTEM_SHORT_NAME,
        PAYMENT_SYSTEM_ID => $PAYSYSTEM_ID,
        CHECK_FIELD       => 'UID',
        USER_ID           => $user_->{UID},
        SUM               => ($result->{invoice} / 100),
        EXT_ID            => $result->{pmt_id},
        DATA              => $attr,
        #DATE              => $DATETIME,
        MK_LOG            => 1,
        #DEBUG             => 1,
        #ERROR             => 1,
        PAYMENT_DESCRIBE  => $desc,
        USER_INFO         => $user_,
      });

      if ($status_code == 0) {
        $html->message('info', $self->{lang}->{SUCCESS}, "$self->{lang}->{SUCCESS} $self->{lang}->{TRANSACTION}: $result->{pmt_id}", { ID => 2222 });
      }
      else {
        $html->message('err', $self->{lang}->{ERROR}, "$status_code", { ID => 2223 });
      }
    }
    elsif($result->{pmt_status} && $result->{pmt_status} == 4){
      $html->message('err', $self->{lang}->{ERROR}, "$self->{lang}->{PAYMENT_ERROR}: $result->{bank_response}->{error_group}\n$self->{lang}->{TRANSACTION}: $result->{pmt_id}",
        { ID => 2224 });
    }
  }
  elsif ($attr->{ipay_purchase}) {
    if($attr->{ipay_purchase} == 1){

      my $sum = ($attr->{invoice}) ? $attr->{invoice} / 100 : 0;
      my $desc = 'IPAY MasterPass';
      if ($user_->{PAYSYS_IPAY_DESC_KEY}) {
        $desc = $self->{lang}->{IPAY_DESCRIBE} . $user_->{PAYSYS_IPAY_DESC_KEY};
      }

      my ($paysys_status) = main::paysys_pay({
        PAYMENT_SYSTEM    => $PAYSYSTEM_SHORT_NAME,
        PAYMENT_SYSTEM_ID => $PAYSYSTEM_ID,
        SUM               => $sum,
        CHECK_FIELD       => 'UID',
        USER_ID           => $user_->{UID},
        EXT_ID            => "$attr->{pmt_id}",
        DATA              => $attr,
        DATE              => "$main::DATE $main::TIME",
        MK_LOG            => 1,
        PAYMENT_DESCRIBE  => $desc,
        USER_INFO         => $user_,
      });

      $html->message('info', $self->{lang}->{SUCCESS}, "$self->{lang}->{SUCCESS} $self->{lang}->{TRANSACTION}: $attr->{pmt_id} ($paysys_status)", { ID => 3333  });
    }
    elsif($attr->{ipay_purchase} == 2){
      $html->message('err', $self->{lang}->{ERROR}, "$self->{lang}->{ERROR} $self->{lang}->{TRANSACTION}: $attr->{pmt_id}");
    }
  }
  elsif ($attr->{ipay_register_purchase}) {
    my $register_purchse_by_url_string = $self->create_request_params(
      'RegisterPurchaseByURL',
      {
        INVOICE => $attr->{SUM},
        ACC     => $attr->{OPERATION_ID},
        USER    => $user_,
      }
    );

    my $result = $self->_request($register_purchse_by_url_string, { TREE => 'response' });

    $html->tpl_show(
      main::_include('paysys_ipay_register_purchase', 'Paysys'),
      {
        URL => $result->{url}
      }
    );
  }
  elsif ($attr->{ipay_unlink_user}) {
    my $unlink_string = $self->create_request_params('UnlinkUser', { USER => $user_ });

    my $result = $self->_request($unlink_string);

    if ($result->{response} && $result->{response}->{status} eq 'success') {
      $html->message('info', "$self->{lang}->{SUCCESS} $self->{lang}->{UNLINKED}");
    }
  }

  # send REQUEST_HASH to IPAY for check
  my $json_request_string_check = $self->create_request_params('Check', { USER => $user_ });
  my $result = $self->_request($json_request_string_check);

  my $user_status = $result->{response}->{user_status} || q{};
  # EXIST PROCESSING
  if ($user_status eq 'exists') {
    my $cards_list   = '';
    my $card_checked = 0;
    my $json_list_string = $self->create_request_params('List', { USER => $user_ });
    $result = $self->_request($json_list_string, { TREE => 'response' });

    foreach my $card (keys %{$result}) {
      my $button_delete_card = $html->button($self->{lang}->{DEL},
        "index=$self->{index}&DeleteCard=$result->{$card}->{card_alias}", { ICON => 'fa fa-trash fa-2x' });

      $cards_list .= $html->tpl_show(
        main::_include('paysys_ipay_one_card', 'Paysys'),
        {
          NAME          => $result->{$card}->{card_alias},
          MASK          => $result->{$card}->{mask},
          DELETE_BUTTON => $button_delete_card,
          CHECKED       => $card_checked == 0 ? 'checked' : '',
          CARD_SELECTED => $card_checked == 0 ? 'card-selected' : '',
        },
        { OUTPUT2RETURN => 1 }
      );
      $card_checked = 1;
    }

    my $json_add_card_by_url = $self->create_request_params('AddcardByURL', { USER => $user_ });
    $result = $self->_request($json_add_card_by_url, { TREE => 'response' });

    my $add_card_by_url = $result->{url};
    $add_card_by_url =~ s/\\\//\//g;

    # button register by url
    my $button_add_card_by_url = $html->button($self->{lang}->{ADD_CARD}, '',
      { GLOBAL_URL => $add_card_by_url, class => 'btn btn-success btn-xs', ADD_ICON=> 'glyphicon glyphicon-plus'});

    $OUTPUT2RETURN = $html->tpl_show(
      main::_include('paysys_ipay_cards_list', 'Paysys'),
      {
        CARDS       => $cards_list,
        ADD_BTN     => $button_add_card_by_url,
        SUBMIT_NAME => 'ipay_pay'
      },
      { OUTPUT2RETURN => 1 }
    );
  }
  # INVITE PROCESSING
  elsif ($user_status eq 'invite') {
    # call invite by url action
    my $json_invite_by_url_string = $self->create_request_params('InviteByURL', { USER => $user_ });
    $result = $self->_request($json_invite_by_url_string, { TREE => 'response' });
    my $confirm_invite_url = $result->{url};
    $confirm_invite_url =~ s/\\\//\//g;

    $OUTPUT2RETURN = $html->tpl_show(
      main::_include('paysys_ipay_start_invite_by_url', 'Paysys'),
      {
        INVITE_BY_URL_BTN => $html->button($self->{lang}->{PLUG_IN}, '', { GLOBAL_URL => $confirm_invite_url, class => 'btn btn-success' })
      },
      { OUTPUT2RETURN => 1 }
    );
  }
  # NOT EXIST PROCESSING
  elsif ($user_status eq 'notexists') {
    $OUTPUT2RETURN = $html->tpl_show(
      main::_include('paysys_ipay_start_register_purchase', 'Paysys'),
      {
        SUBMIT_NAME => 'ipay_register_purchase'
      },
      { OUTPUT2RETURN => 1 }
    );
  }

  my $one_click_line = $html->tpl_show(
    main::_include('paysys_ipay_oneclick', 'Paysys'),
    {},
    { OUTPUT2RETURN => 1 }
  );

  $OUTPUT2RETURN = $one_click_line . ($OUTPUT2RETURN || '');

  return $OUTPUT2RETURN;
}

#**********************************************************
=head2 report($attr)

  Arguments:
    $attr
      HTML
      LANG


  Results:
    $self

=cut
#**********************************************************
sub report {
  my $self = shift;
  my ($attr) = @_;

  $html = $attr->{HTML};
  my $lang = $attr->{LANG};
  my $Paysys = Paysys->new($self->{db}, $self->{admin}, $self->{conf});
  my $list = $Paysys->paysys_report_list({
    TABLE     => 'paysys_ipay_report',
    COLS_NAME => 1,
    PAGE_ROWS => 9999999
  });

  my $table = $html->table({
    width      => '100%',
    caption    => "Ipay Master Pass",
    title      => [ "#", $lang->{USER}, $lang->{SUM}, $lang->{DATE}, $lang->{TRANSACTION}  ],
    DATA_TABLE => { 'order' => [ [ 0, 'id' ] ] },
  });

  foreach my $payment (@$list) {
    $table->addrow($payment->{id},
      $html->button($payment->{user_key}, "index=15&UID=$payment->{user_key}",{ class => 'btn btn-primary btn-xs' }),
      $payment->{sum},
      $payment->{date},
      $payment->{transaction_id});
  }

  print $table->show();

  return 1;
}

#**********************************************************
=head2 has_test($attr)

  Arguments:
    $attr

  Returns:

=cut
#**********************************************************
sub has_test {
  my $self = shift;

  our @requests;
  eval { require "Paysys/t/Ipay_mp.t" };

  my %params_hash = (
    # '3PAY'  => {
    #   _POST_    => {
    #     name    => '_POST_',
    #     val     => $requests[1]->{request},
    #     tooltip => $requests[1]->{name}
    #   },
    #   signature    => {
    #     name    => 'signature',
    #     val     => $sign, #'!mk_signature:_POST_',
    #     tooltip => 'Signature'
    #   },
    #   data    => {
    #     name    => 'data',
    #     val     => $data, #'!cnf_form:_POST_',
    #     tooltip => 'data'
    #   },
    #   MODULE    => {
    #     name    => 'MODULE',
    #     val     => 'Liqpay.pm',
    #     tooltip => 'data'
    #   },
    #   result      => [
    #   ],
    #   result_type => 'xml',
    # }
  );

  return \%params_hash;
}

#**********************************************************
=head2 proccess($FORM)

  Arguments:
    $FORM

  Returns:

=cut
#**********************************************************
sub proccess {
  my $self = shift;
  my ($FORM) = @_;

  my $buffer = $FORM->{__BUFFER} || q{};
  my $xml = $buffer;
  $xml =~ s/^xml\=//;
  $xml =~ s/\\\"/"/g;
  my $debug = $self->{DEBUG} || 0;

  if ($debug > 0) {
    main::mk_log($xml, { PAYSYS_ID => 'Ipay', REQUEST => 'Request' });
  }

  load_pmodule('XML::Simple');
  my $request = eval{ XML::Simple::XMLin($xml || q{},
    #ForceArray => 1,
    KeyAttr => {},
    KeepRoot => 1
  ) };

  if ($@) {
    main::mk_log("CONTENT:\n" . $buffer . "\n-- XML Error:\n" . $@ . "\n--\n",
      { PAYSYS_ID => 'Ipay', HEADER => 1 });
    print "XML_ERROR";
    print $xml;
    return 0;
  }

  my $result = q{};
  if($request->{check}){
    my ($check_status, $user_info) = main::paysys_check_user({
      CHECK_FIELD => $self->{conf}{PAYSYS_IPAY_ACCOUNT_KEY} || 'UID',
      USER_ID     => $request->{check}{pay_account},
    });

    if($check_status == 0){
      $result = qq{<response>
<check_code>0</check_code>
<desc>ok</desc>
<datetime>$main::DATE $main::TIME</datetime>
<info>{"name":"$user_info->{FIO}","balance":"$user_info->{DEPOSIT}"}</info>
</response>};
    }
    else{
      $result = qq{<response>
<check_code>1</check_code>
<desc>Inside Error: $check_status</desc>
<datetime>$main::DATE $main::TIME</datetime>
<info></info>
</response>};
    }
  }
  elsif($request->{payment}) {
    my $payment      = $request->{payment};
    my $ipay_salt    = $payment->{salt}  || q{};
    my $payment_sign = $payment->{sign} || q{};
    my $payment_id = $payment->{id};

    # PAYSYS_IPAY_NOTIFY_KEY key for Ipay web portal payment
    if ($self->{conf}->{PAYSYS_IPAY_NOTIFY_KEY}) {
      $self->{conf}->{PAYSYS_IPAY_SIGN_KEY}=$self->{conf}->{PAYSYS_IPAY_NOTIFY_KEY};
    }

    my $signature = $self->mk_sign({ salt => $ipay_salt });
    if($ipay_salt && $signature ne $payment_sign) {
      $result = 'ERR_INCORRECT_CHECKSUM';
    }

    #($payment_id) = keys %$payment;
    my $payment_status = $payment->{status} || 0;
    my $payment_amount = ($payment->{amount}) ? $payment->{amount} / 100 :  0;

    my $transaction = $payment->{transactions}->{transaction};
    my $transaction_id = $transaction->[0]->{id};
    my $json_transaction_info = $transaction->[0]->{info};
    my $desc = $transaction->[0]->{desc};
    my $transaction_extra_info;
    if ($json_transaction_info) {
      $json_transaction_info =~ s/^"|"$//g;
      $transaction_extra_info = $json->decode($json_transaction_info);
    }

    return 9 if (defined($transaction_extra_info->{acc}) && $transaction_extra_info->{acc} eq 'UID');

    my $account = '';
    my $account_key = $self->{conf}{PAYSYS_IPAY_ACCOUNT_KEY} || 'UID';

    if ($transaction_extra_info && ref $transaction_extra_info eq 'HASH') {
      if ($transaction_extra_info->{UID}) {
        #$payment_amount = $transaction_extra_info->{step_2}{invoice};
        $account = $transaction_extra_info->{UID};
        $account_key = 'UID';
      }
      else {
        $payment_amount = $transaction_extra_info->{invoice} / 100 if ($transaction_extra_info->{invoice});
        $account = $transaction_extra_info->{step_1}->{acc} || q{};
      }
    }

    my %DATA = (
      $account_key   => $account,
      amount         => $payment_amount,
      payment_status => $payment_status,
      transaction_id => $transaction_id
    );

    if ($payment_status == 5) {
      my ($status_code) = main::paysys_pay({
        PAYMENT_SYSTEM    => $PAYSYSTEM_SHORT_NAME,
        PAYMENT_SYSTEM_ID => $PAYSYSTEM_ID,
        CHECK_FIELD       => $account_key,
        USER_ID           => $account,
        SUM               => $payment_amount,
        EXT_ID            => $payment_id,
        DATA              => \%DATA,
        DATE              => "$main::DATE $main::TIME",
        MK_LOG            => 1,
        #    PAYMENT_ID        => 1,
        DEBUG             => $debug,
        PAYMENT_DESCRIBE  => $desc || 'Ipay payment',
      });
      $result = $status_code;
    }
    elsif($payment_status == 6) {
      my ($status_code) = main::paysys_pay({
        PAYMENT_SYSTEM    => $PAYSYSTEM_SHORT_NAME,
        PAYMENT_SYSTEM_ID => $PAYSYSTEM_ID,
        CHECK_FIELD       => $account_key,
        USER_ID           => $account,
        SUM               => $payment_amount,
        EXT_ID            => $payment_id,
        DATA              => \%DATA,
        DATE              => "$main::DATE $main::TIME",
        MK_LOG            => 1,
        #    PAYMENT_ID        => 1,
        DEBUG             => $debug,
        PAYMENT_DESCRIBE  => $desc || 'Ipay',
        ERROR             => 3
      });

      $result = $status_code;
    }
  }

  $self->show_result($result);

  return 1;
}

#**********************************************************
=head2 show_result($result, $content, $attr)

  Arguments:
    $result

  Returns:
    HASH
=cut
#**********************************************************
sub show_result {
  my $self = shift;
  my ($result) = @_;

  print "Content-Type: text/plain\n\n" if ($self->{DEBUG} > 3);

  if (! $self->{TEST}) {
    print "Content-Type: text/xml\n\n";
    print $result;
  }
  else {
    $self->{RESULT}=$result;
  }

  main::mk_log($result, {
    PAYSYS_ID => $PAYSYSTEM_ID,
    REPLY     => 1
  });

  return 1;
}

#**********************************************************
=head2 mk_sign($attr)

  Argumnets:
    $attr
      salt
      test_key - MK key for testiong
      SYSTEM_KEY
      MERCHANT_KEY

  Return:
    $salt, $signature

=cut
#**********************************************************
sub mk_sign {
  my $self = shift;
  my ($attr) = @_;

  my $salt = q{};
  my $signature = q{};
  my $system_key = $attr->{SYSTEM_KEY} || $self->{conf}->{PAYSYS_IPAY_SIGN_KEY} || q{};
  my $merch_key = $attr->{MERCHANT_KEY} || $self->{conf}->{PAYSYS_IPAY_MERCHANT_KEY} || q{};

  load_pmodule('Digest::SHA');
  use Digest::SHA qw(hmac_sha512_hex);

  if($attr->{salt}){
    $signature = hmac_sha512_hex($attr->{salt}, $system_key);
    return $signature;
  }
  else {
    my $sha1 = Digest::SHA->new;
    eval {require Time::HiRes;};
    our $begin_time = 0;
    if (!$@) {
      Time::HiRes->import(qw(gettimeofday));
      $begin_time = Time::HiRes::gettimeofday();
    }

    my $time = gettimeofday();
    $sha1->add($time);
    $salt = $sha1->hexdigest();
    if ($attr->{test_key}) {
      $merch_key = $system_key;
    }

    $signature = hmac_sha512_hex($salt, $merch_key);
  }

  return ($salt, $signature);
}

1;
