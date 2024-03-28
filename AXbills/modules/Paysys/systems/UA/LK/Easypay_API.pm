=head1 Easypay_API
  New module for Easypay_API

  Date: 18.06.2019
  UPDATE: 13.11.2019

  Version: 8.00
=cut

use strict;
use warnings;
use AXbills::Base qw(_bp load_pmodule encode_base64);
use AXbills::Fetcher qw(web_request);
use Paysys;
load_pmodule('JSON');
load_pmodule('Digest::SHA');
require Paysys::Paysys_Base;
package Paysys::systems::Easypay_API;
require Encode;
our $PAYSYSTEM_NAME = 'Easypay_API';
our $PAYSYSTEM_SHORT_NAME = 'Easypay';
our $PAYSYSTEM_ID = 58;
our $PAYSYSTEM_VERSION = '8.00';
our %PAYSYSTEM_CONF = (
  PAYSYS_EASYPAY_PARTNER_KEY => '',
  PAYSYS_EASYPAY_SERVICE_KEY => '',
  PAYSYS_EASYPAY_SECRET_KEY  => '',
);

my ($html);

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

  if ($attr->{HTML}) {
    $html = $attr->{HTML};
  }

  bless($self, $class);

  $self->{Paysys} = Paysys->new($self->{db}, $self->{admin}, $self->{conf});

  return $self;
}

#**********************************************************
=head2 proccess(\%FORM) - Make pay

  Arguments:
    $FORM - HASH REF to %FORM

  Returns:

=cut
#**********************************************************
sub proccess {
  my $self = shift;
  my ($FORM) = @_;

  $FORM = () if (!$FORM);

  print "Content-Type: text/html\n\n";

  if ($self->{DEBUG} > 0) {
    my $info = q{};
    while (my ($k, $v) = each %$FORM) {
      $info .= "$k => $v\n" if ($k ne '__BUFFER');
    }
    main::mk_log($info, { PAYSYS_ID => $PAYSYSTEM_NAME });
  }

  my $responce_params = JSON::decode_json($FORM->{__BUFFER});

  if ($responce_params->{action} && $responce_params->{action} eq 'payment') {
#     if ($responce_params->{details}{recurrent_id}) {
#       my $payment_info = main::paysys_get_full_info({
#         TRANSACTION_ID => "$PAYSYSTEM_SHORT_NAME:$responce_params->{order_id}"
#       });
#
#       if ($payment_info->{status} eq '1') {
#         $self->{Paysys}->paysys_user_change({
#           UID          => $payment_info->{uid},
#           RECURRENT_ID => $responce_params->{details}{recurrent_id},
#         });
#
#         if ($self->{Paysys}->{errno}) {
#           main::mk_log("Error payment: $self->{Paysys}->{errno}", { PAYSYS_ID => "$PAYSYSTEM_NAME" });
#           return 0;
#         }
#
#         my $status_code = main::paysys_pay({
#           PAYMENT_SYSTEM    => $PAYSYSTEM_SHORT_NAME,
#           PAYMENT_SYSTEM_ID => $PAYSYSTEM_ID,
#           SUM               => $responce_params->{details}{amount},
#           ORDER_ID          => "$PAYSYSTEM_SHORT_NAME:$responce_params->{order_id}",
#           EXT_ID            => "$responce_params->{order_id}",
#           DATA              => $responce_params,
#           DATE              => "$responce_params->{date}",
#           MK_LOG            => 1,
#           DEBUG             => $self->{DEBUG},
#           PAYMENT_DESCRIBE  => $responce_params->{details}{desc} || "$PAYSYSTEM_NAME payment",
#         });
#
#         if ($status_code == 0) {
#           main::mk_log("Payment completed: $PAYSYSTEM_SHORT_NAME:$responce_params->{order_id}", { PAYSYS_ID => "$PAYSYSTEM_NAME" });
#         }
#         elsif ($status_code > 0) {
#           print qq{Status: 520 Wrong Status
# Content-type: text/html
#
# <HTML>
# <HEAD><TITLE>520 Wrong Status</TITLE></HEAD>
# <BODY>
#   <H1>Error</H1>
#   <P>Wrong Status</P>
# </BODY>
# </HTML>
#     };
#           main::mk_log("ERROR: status - $status_code", { PAYSYS_ID => "$PAYSYSTEM_NAME" });
#         }
#         return 1;
#       }
#       elsif ($payment_info->{status} eq '2') {
#         my $info = $self->{Paysys}->paysys_user_info({
#           RECURRENT_ID => $responce_params->{details}{recurrent_id},
#         });
#
#         if ($self->{Paysys}->{errno}) {
#           main::mk_log("Error payment: $self->{Paysys}->{errno}", { PAYSYS_ID => "$PAYSYSTEM_NAME" });
#           return 0;
#         }
#         my $order_id = main::mk_unique_value(8, { SYMBOLS => '0123456789' });
#         my ($status_code, $payments_id) = main::paysys_pay({
#           PAYMENT_SYSTEM    => $PAYSYSTEM_SHORT_NAME,
#           PAYMENT_SYSTEM_ID => $PAYSYSTEM_ID,
#           CHECK_FIELD       => 'UID',
#           USER_ID           => $info->{UID},
#           SUM               => $responce_params->{details}{amount},
#           EXT_ID            => "$order_id",
#           DATA              => $responce_params,
#           DATE              => "$responce_params->{date}",
#           PAYMENT_ID        => 1,
#           DEBUG             => $self->{DEBUG},
#           PAYMENT_DESCRIBE  => $responce_params->{details}{desc} || "$PAYSYSTEM_NAME payment",
#         });
#
#         if ($status_code == 0) {
#           main::mk_log("Payment completed: $PAYSYSTEM_SHORT_NAME:$order_id", { PAYSYS_ID => "$PAYSYSTEM_NAME" });
#         }
#         elsif ($status_code > 0) {
#           print qq{Status: 520 Wrong Status
# Content-type: text/html
#
# <HTML>
# <HEAD><TITLE>520 Wrong Status</TITLE></HEAD>
# <BODY>
#   <H1>Error</H1>
#   <P>Wrong Status</P>
# </BODY>
# </HTML>
#     };
#           main::mk_log("ERROR: status - $status_code", { PAYSYS_ID => "$PAYSYSTEM_NAME" });
#         }
#         return 1;
#
#       }
#       return 1;
#     }
#     else {
      return 0 if !$responce_params->{order_id};
      my $status_code = main::paysys_pay({
        PAYMENT_SYSTEM    => $PAYSYSTEM_SHORT_NAME,
        PAYMENT_SYSTEM_ID => $PAYSYSTEM_ID,
        SUM               => $responce_params->{details}{amount},
        ORDER_ID          => "$PAYSYSTEM_SHORT_NAME:$responce_params->{order_id}",
        EXT_ID            => "$responce_params->{order_id}",
        DATA              => $responce_params,
        DATE              => "$responce_params->{date}",
        MK_LOG            => 1,
        DEBUG             => $self->{DEBUG},
        PAYMENT_DESCRIBE  => $responce_params->{details}{desc} || "$PAYSYSTEM_NAME payment",
      });

      if ($status_code == 0) {
        main::mk_log("Payment completed: $responce_params", { PAYSYS_ID => "$PAYSYSTEM_NAME" });
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
        main::mk_log("ERROR: status - $status_code", { PAYSYS_ID => "$PAYSYSTEM_NAME" });
      }
      return 1;
    # }
  }
  elsif ($responce_params->{action} && $responce_params->{action} eq 'refund') {
    my $result = main::paysys_pay_cancel({
      TRANSACTION_ID => "$PAYSYSTEM_SHORT_NAME:$responce_params->{order_id}"
    });

    if ($result == 0) {
      main::mk_log("Payment  $responce_params->{order_id} canceled: $responce_params", { PAYSYS_ID => "$PAYSYSTEM_NAME" });
    }
    elsif ($result > 0) {
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
      main::mk_log("ERROR: Bad request - $responce_params", { PAYSYS_ID => "$PAYSYSTEM_NAME" });
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
  $SETTINGS{ID} = $PAYSYSTEM_ID;
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

  if (!$self->{conf}{PAYSYS_EASYPAY_PARTNER_KEY} || !$self->{conf}{PAYSYS_EASYPAY_SERVICE_KEY} || !$self->{conf}{PAYSYS_EASYPAY_SECRET_KEY}) {
    $html->message('err', $lang->{ERROR}, "Payment system has wrong configuration");
    return 0;
  }
  if (!$attr->{SUM} || $attr->{SUM} == 0) {
    $html->message('err', $lang->{ERROR}, "Payment sum is too small.");
    return 0;
  }

  # if ($attr->{MAKE_PAYMENT}) {
    #  CreateApp
    push @headers, qq{partnerKey: $self->{conf}{PAYSYS_EASYPAY_PARTNER_KEY}};
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
        "serviceKey"  => $self->{conf}{PAYSYS_EASYPAY_SERVICE_KEY},
        'orderId'     => $attr->{OPERATION_ID},
        'description' => $attr->{DESCRIBE},
        'amount'      => $attr->{SUM},
      },
    };
    # if ($attr->{CREATE_REGULAR_PAYMENT}) {
    #   my $cron = q{};
    #   my $dateExpire = q{};
    #   my ($Y, $M, $D) = split(/-/, $main::DATE, 3);
    #   my ($H, $MIN, $S) = split(/:/, $main::TIME, 3);
    #   $D = 28 if ($D > 28);
    #   $cron = qq{$MIN $H $D * *};
    #   $Y = $Y + 100;
    #   $dateExpire = qq{$Y-$M-$D} . q{T} . $main::TIME;
    #   $request_body->{reccurent} = {
    #     'cronRule'   => $cron,
    #     'dateExpire' => $dateExpire,
    #   };
    #
    #   $self->{Paysys}->paysys_user_add({
    #     UID              => $user->{UID},
    #     RECURRENT_CRON   => $cron,
    #     RECURRENT_MODULE => $PAYSYSTEM_NAME,
    #   });
    #
    #   if ($self->{Paysys}->{errno}) {
    #     $html->message('err', "ERROR", "Recurrent payment exists! Paysys: '$self->{Paysys}->{errstr}'");
    #     return 0;
    #   }
    # }

    $request_body = JSON::encode_json($request_body);
    $content_length = length($request_body);
    $sign = AXbills::Base::encode_base64(Digest::SHA::sha256($self->{conf}{PAYSYS_EASYPAY_SECRET_KEY} . $request_body));
    $sign =~ s/\n//g;
    push @headers, qq{locale: ua};
    push @headers, qq{requestedSessionId: $requestedSessionId};
    push @headers, qq{appId: $appId};
    push @headers, qq{pageId: $pageId};
    push @headers, qq{partnerKey: $self->{conf}{PAYSYS_EASYPAY_PARTNER_KEY}};
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
        SYSTEM_ID      => $PAYSYSTEM_ID,
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
  # }
  # else {
  #   $pay_params{INDEX} = $attr->{index};
  #   $pay_params{PAYMENT_SYSTEM} = $attr->{PAYMENT_SYSTEM};
  #   $pay_params{OPERATION_ID} = $attr->{OPERATION_ID};
  #   $pay_params{SUM} = $attr->{SUM};
  #   $pay_params{DESCRIBE} = $attr->{DESCRIBE};
  #   $pay_params{CREATE_REGULAR_PAYMENT} = $html->form_input('CREATE_REGULAR_PAYMENT', 1, { TYPE => 'checkbox', OUTPUT2RETURN => 1 });
  #
  #   return $html->tpl_show(main::_include('paysys_easypay_userportal', 'Paysys'), \%pay_params, { OUTPUT2RETURN => 0 });
  # }

  return 1;
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
      DEBUG   => $debug,
      POST    => $post_data,
      HEADERS => $headers,
    }
  );

  my $responce_params = JSON::decode_json($responce);

  return $responce_params;
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

  if ($self->{conf}{'PAYSYS_EASYPAY_PARTNER_KEY_' . $gid}) {
    $self->{conf}{PAYSYS_EASYPAY_PARTNER_KEY} = $self->{conf}{'PAYSYS_EASYPAY_PARTNER_KEY_' . $gid};
  }

  if ($self->{conf}{'PAYSYS_EASYPAY_SERVICE_KEY_' . $gid}) {
    $self->{conf}{PAYSYS_EASYPAY_SERVICE_KEY} = $self->{conf}{'PAYSYS_EASYPAY_SERVICE_KEY_' . $gid};
  }

  if ($self->{conf}{'PAYSYS_EASYPAY_SECRET_KEY_' . $gid}) {
    $self->{conf}{PAYSYS_EASYPAY_SECRET_KEY} = $self->{conf}{'PAYSYS_EASYPAY_SECRET_KEY_' . $gid};
  }
}

# #**********************************************************
# =head2 recurrent_cancel($attr)
#
#   Arguments:
#     $attr -
#
#   Returns:
#
# =cut
# #**********************************************************
# sub recurrent_cancel {
#   my $self = shift;
#   my ($attr) = @_;
#   my $appId = q{};
#   my $pageId = q{};
#   my @headers = ();
#   my $sign = q{};
#
#   #  CreateApp
#   push @headers, qq{partnerKey: $self->{conf}{PAYSYS_EASYPAY_PARTNER_KEY}};
#   push @headers, qq{locale: ua};
#   push @headers, qq{Content-Length: 0};
#
#   my $responce_createApp = send_request({
#     URL     => qq{https://api.easypay.ua/api/system/createApp},
#     HEADERS => \@headers,
#     DEBUG   => $self->{DEBUG},
#   });
#   $appId = $responce_createApp->{appId};
#   $pageId = $responce_createApp->{pageId};
#   @headers = ();
# #  Delete recurrent payment
#   $sign = AXbills::Base::encode_base64(Digest::SHA::sha256($self->{conf}{PAYSYS_EASYPAY_SECRET_KEY}));
#   $sign =~ s/\n//g;
#   push @headers, qq{partnerKey: $self->{conf}{PAYSYS_EASYPAY_PARTNER_KEY}};
#   push @headers, qq{locale: ua};
#   push @headers, qq{appId: $appId};
#   push @headers, qq{pageId: $pageId};
#   push @headers, qq{Sign: $sign};
#
#   my $url = qq{https://api.easypay.ua/api/merchant/recurrent/delete/} . qq{$attr->{RECURRENT_ID}};
#   my $responce = AXbills::Fetcher::web_request(
#     $url,
#     {
#       CURL         => 1,
#       CURL_OPTIONS => '-X "DELETE"',
#       DEBUG        => 5,
#       STATUS_CODE  => 1,
#       HEADERS      => \@headers,
#     }
#   );
#   my $status_code;
#   if ($responce) {
#     ($status_code) = $responce =~ /HTTP\/\d+.\d+\s(\d+)/g;
#     if ($status_code && $status_code eq '200') {
#       $self->{Paysys}->paysys_main_del({ RECURRENT_ID => $attr->{RECURRENT_ID} });
#       if ($self->{Paysys}->{errno}) {
#         $html->message('err', "ERROR", "ERROR Paysys RECURRENT_ID: '$attr->{RECURRENT_ID}'");
#         return 0;
#       }
#     }
#   }
#
#   return $status_code, $responce;
# }
1;