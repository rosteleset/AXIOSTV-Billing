package Paysys::systems::Liqpay;
=head1 Liqpay
  New module for Liqpay

  Documentaion: https://docs.google.com/document/d/1GHjRFyLQM_h59IyaNZVVxYE1cxMPAwb336KKpueQa1U/edit

  Date: 17.07.2020

  Version: 7.04
=cut

use strict;
use warnings;

use AXbills::Base qw(_bp load_pmodule encode_base64);
use AXbills::Misc qw(load_module);
use AXbills::Fetcher qw(web_request);
require Paysys::Paysys_Base;
use Users;
use Paysys;
use JSON qw(decode_json encode_json );

our $PAYSYSTEM_NAME = 'Liqpay';
our $PAYSYSTEM_SHORT_NAME = 'Liqpay';
our $PAYSYSTEM_ID = 62;

our $PAYSYSTEM_VERSION = '7.04';

our %PAYSYSTEM_CONF = (
  PAYSYS_LIQPAY_COMMISSION         => '',
  'PAYSYS_LIQPAY_MERCHANT_ID'      => '',
  'PAYSYS_LIQPAY_MERCHANT_PASS'    => '',
  'PAYSYS_LIQPAY_CURRENCY'         => 'UAH',
  'PAYSYS_LIQPAY_OLD'              => '',
  'PAYSYS_LIQPAY_SUBSCRIBE'        => '',
  'PAYSYS_LIQPAY_DESCRIPTION'      => '',
  #'PAYSYS_LIQPAY_SUBSCRIBE_CHANGE' => '',
);

use Paysys;
use Encode qw(encode);

our (
  $admin,
  $db,
  %conf,
);

my ($html, $json);

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
    lang  => $attr->{lang},
    conf  => $CONF,
    DEBUG => $CONF->{PAYSYS_DEBUG} || 0,
  };

  if ($attr->{HTML}) {
    $html = $attr->{HTML};
  }

  AXbills::Base::load_pmodule('JSON');
  $json = JSON->new->allow_nonref;

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 process()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub proccess {
  my $self = shift;
  my ($FORM) = @_;

  print "Content-Type: text/plain\n\n";

  if ($self->{conf}{PAYSYS_LIQPAY_OLD} && $self->{conf}{PAYSYS_LIQPAY_OLD} == 1) {
    $self->_process_old_syle($FORM);
  }
  else {
    my $data = $FORM->{data};
    my $json_data = AXbills::Base::decode_base64($data);
    main::mk_log("$json_data", {PAYSYS_ID => 'LIQPAY JSON DATA'});
    my $result_hash = $json->decode($json_data);

    my $status = $result_hash->{status} || q{};
    my $order_id = $result_hash->{'order_id'};

    if ($FORM->{pay_way} && $FORM->{pay_way} eq 'delayed') {
      return 0;
    }

    my $Paysys = Paysys->new($self->{db}, $self->{admin}, $self->{conf});
    my $list = $Paysys->list(
      {
        TRANSACTION_ID => "$order_id",
        STATUS         => '<>2',
        GID            => '_SHOW',
        COLS_NAME      => 1,
        DOMAIN_ID      => '_SHOW',
        SORT           => 1
      }
    );

    if ($Paysys->{TOTAL} > 0) {
      my $id = $list->[0]->{id};
      my $domain_id = $list->[0]->{domain_id};
      my $gid = $list->[0]->{gid};
      my $sum = $list->[0]->{sum};

      my $sign = $self->liqpay_make_request3({
        GID       => $gid,
        DOMAIN_ID => $domain_id,
        DATA      => $data
      });

      if ($FORM->{'signature'} && $FORM->{'signature'} ne $sign) {
        $status = 5;
        return 1;
      }

      my %errors = (
        'success'     => 0,
        'failure'     => 6,
        'otp_verify'  => 6,
        '3ds_verify'  => 6,
        'wait_secure' => 12,
        'wait_accept' => 12,
        'wait_lc'     => 0,
        'processing'  => 1,
        #'subscribed'   => 0,
        #'unsubscribed' => 0,
        'sandbox'     => 12,
        'error'       => 6,
        'reversed'    => 3,
      );
      #      main::mk_log("Status - $status", {PAYSYS_ID => 'Liqpay'});
      if ($status eq 'hold_wait') {
        my ($hold_completion_sign, $hold_completion_data) = $self->liqpay_make_request3({
          GID             => $gid,
          DOMAIN_ID       => $domain_id,
          HOLD_COMPLETION => 1,
          AMOUNT          => $sum,
          ORDER_ID        => $order_id,
        });

        #   main::mk_log("$hold_completion_sign - $hold_completion_data", { PAYSYS_ID => 'Liqpay' });

        my $hold_completion_result_json = main::web_request(
          'https://www.liqpay.ua/api/request',
          {
            POST => "signature=$hold_completion_sign&data=$hold_completion_data",
          }
        );

        main::mk_log($hold_completion_result_json, { PAYSYS_ID => 'Liqpay hold completion result' });

        my $hold_completion_result = $json->decode($hold_completion_result_json);

        if($hold_completion_result->{status} && $hold_completion_result->{status} eq 'success') {

          my $paysys_status = main::paysys_pay({
            PAYMENT_SYSTEM    => $PAYSYSTEM_SHORT_NAME,
            PAYMENT_SYSTEM_ID => $PAYSYSTEM_ID,
            PAYMENT_DESCRIBE  =>
              "$result_hash->{description} # $result_hash->{sender_phone}" . (($result_hash->{state} && $result_hash->{state} eq 'test') ? ' (test)' : ''),
            #SUM               => $sum,
            PAYSYS_ID         => $id,
            DATA              => $result_hash,
            #            ERROR             => ($status eq 'success') ? undef : (($errors{$status}) ? $errors{$status} : 6),
            MK_LOG            => 1,
            CURRENCY          => $FORM->{'currency'},
            COMMISSION        => 1
          });

          main::mk_log("status - $paysys_status", { PAYSYS_ID => 'Liqpay' });

          return $paysys_status;
        }
        else{
          main::mk_log("Status not success for hold confirm", { PAYSYS_ID => 'Liqpay' });
        }
      }
    }
  }

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

  if ($self->{conf}{PAYSYS_LIQPAY_OLD} && $self->{conf}{PAYSYS_LIQPAY_OLD} == 1) {
    $self->user_portal_old_style($user, $attr);
  }
  else {
    my %info = ();

    if ($attr->{TRUE} || $attr->{status}) {
      main::paysys_show_result({ TRANSACTION_ID => $attr->{order_id} || $attr->{OPERATION_ID} });
      return 0;
    }

    my $Paysys = Paysys->new($self->{db}, $self->{admin}, $self->{conf});

    $info{COMMISSION_SUM} = 0;
    if ($attr->{SUM} <= 0) {
      $html->message('err', "ERROR", "ERROR Wrong Sum: '$attr->{SUM}'");
      return 0;
    }

    if ($self->{conf}{PAYSYS_LIQPAY_COMMISSION}) {
      $self->{conf}{PAYSYS_LIQPAY_COMMISSION} =~ /([0-9\.]+)([\%]?)/;
      $info{COMMISSION} = $1;
      my $type = $2;

      if ($type) {
        $info{COMMISSION_SUM} = sprintf("%.2f",
          ($attr->{SUM} + ($attr->{SUM} / 100 * $info{COMMISSION})) / 100 * $info{COMMISSION});
        $info{COMMISSION_SUM} = int($info{COMMISSION_SUM} * 100);
        $info{COMMISSION_SUM} = ($info{COMMISSION_SUM} + 1) / 100;
      }
      else {
        $info{COMMISSION_SUM} = sprintf("%.2f", $info{COMMISSION});
      }
    }

    #Info section
    $Paysys->add(
      {
        SYSTEM_ID      => 62,
        SUM            => $attr->{SUM},
        COMMISSION     => $info{COMMISSION_SUM},
        UID            => $attr->{UID} || $user->{UID},
        IP             => $ENV{'REMOTE_ADDR'},
        TRANSACTION_ID => "$PAYSYSTEM_SHORT_NAME:$attr->{OPERATION_ID}",
        INFO           => $attr->{DESCRIBE},
        PAYSYS_IP      => "$ENV{'REMOTE_ADDR'}",
        STATUS         => 1,
        DOMAIN_ID      => $user->{DOMAIN_ID},
      }
    );

    if ($Paysys->{errno}) {
      $html->message('err', "ERROR", "Paysys ID: '$attr->{OPERATION_ID}'");
      return 0;
    }

    $attr->{TOTAL_SUM} = sprintf("%.2f", $attr->{SUM} + $info{COMMISSION_SUM});
    my %methods = (
      'card'   => "Visa/Master Card",
      'liqpay' => "LiqPAY"
    );

    $info{PAY_WAY_SEL} = $html->form_select(
      'METHOD',
      {
        SELECTED => $attr->{METHOD},
        SEL_HASH => \%methods,
        NO_ID    => 1
      }
    );

    my $description = "\nFIO : " . ('') . ";\n UID: " . ($user->{UID} || $attr->{UID}) . ";";
    $description = Encode::decode('UTF-8', $description);
    ($info{SIGN}, $info{BODY}) = $self->liqpay_make_request3({
      DOMAIN_ID   => $user->{DOMAIN_ID},
      GID         => $user->{GID},
      DESCRIPTION => $description,
      ACTION      => 'hold',
      %$attr });

    $html->tpl_show(main::_include('paysys_liqpay_add', 'Paysys'), { %{ ($attr) ? $attr : {}}, %info, %$user },);
  }

}

#**********************************************************
=head2 user_portal_old_style()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub user_portal_old_style {
  my $self = shift;
  my ($user, $attr) = @_;
  my %info = ();

  my $Paysys = Paysys->new($self->{db}, $self->{admin}, $self->{conf});

  if($attr->{UNSUBSRIBE} == 1){

   my $test = $Paysys->paysys_user_info({
      UID          => $user->{UID},
   });

    ($info{signature}, $info{data}) = $self->liqpay_unsubscribe({
      %$attr,
      GID       => $user->{GID},
      ACTION    => 'unsubscribe',
      ORDER_ID  => $test->{ORDER_ID}
    });

    my $url = 'https://www.liqpay.ua/api/request';
    my $payments_result = web_request(
      $url,
      {
        CURL           => 1,
        DEBUG          => 0,
        REQUEST_PARAMS => \%info,
      }
    );

    my $json_request = decode_json($payments_result);
    if($json_request->{status} eq 'unsubscribed'){
      $html->message( 'info',  "" , "$self->{lang}->{SUCCESS_UNSUBSCRIBE}");
      return 0;
    }
    else{
      $html->message( 'err', "$self->{lang}->{ERROR}", "$self->{lang}->{ERROR_UNSUBSCRIBE}" );
      return 0;
    }
  }

  if ($attr->{TRUE} || $attr->{status}) {
    main::paysys_show_result({ TRANSACTION_ID => $attr->{order_id} || $attr->{OPERATION_ID} });
    return 0;
  }
  else {
    $info{COMMISSION_SUM} = 0;
    if ($attr->{SUM} <= 0) {
      $html->message('err', "ERROR", "ERROR Wrong Sum: '$attr->{SUM}'");
      return 0;
    }

    if ($self->{conf}{PAYSYS_LIQPAY_COMMISSION}) {
      $self->{conf}{PAYSYS_LIQPAY_COMMISSION} =~ /([0-9\.]+)([\%]?)/;
      $info{COMMISSION} = $1;
      my $type = $2;

      if ($type) {
        $info{COMMISSION_SUM} = sprintf("%.2f",
          ($attr->{SUM} + ($attr->{SUM} / 100 * $info{COMMISSION})) / 100 * $info{COMMISSION});
        $info{COMMISSION_SUM} = int($info{COMMISSION_SUM} * 100);
        $info{COMMISSION_SUM} = ($info{COMMISSION_SUM} + 1) / 100;
      }
      else {
        $info{COMMISSION_SUM} = sprintf("%.2f", $info{COMMISSION});
      }
    }
  }

  $attr->{TOTAL_SUM} = sprintf("%.2f", $attr->{SUM} + $info{COMMISSION_SUM});
  my %methods = (
    'card'   => "Visa/Master Card",
    'liqpay' => "LiqPAY"
  );

  $info{PAY_WAY_SEL} = $html->form_select(
    'METHOD',
    {
      SELECTED => $attr->{METHOD},
      SEL_HASH => \%methods,
      NO_ID    => 1
    }
  );

  if($self->{conf}{PAYSYS_LIQPAY_DESCRIPTION}){
    my @vars = $self->{conf}{PAYSYS_LIQPAY_DESCRIPTION} =~ /\%(.+?)\%/g;
    foreach my $var (@vars){
      $self->{conf}{PAYSYS_LIQPAY_DESCRIPTION} =~ s/\%$var\%/($user->{$var} || '')/ge;
    }
  }

  my $description = $self->{conf}{PAYSYS_LIQPAY_DESCRIPTION} || "\nFIO : " . ($user->{FIO} || $attr->{FIO} || '') . ";\n UID: " . ($user->{UID} || $attr->{UID}) . ";\n";
  require Encode;
  $description = Encode::decode('UTF-8', $description);

  use POSIX qw(strftime);

  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();

  $mday = 2;
  $mon++;
  if ($mon == 13) {
    $mon = 1;
    $year++;
  }

  if($self->{conf}{PAYSYS_LIQPAY_SUBSCRIBE}){

    if (! $user->{PHONE}) {
      $html->message( 'err', "$self->{lang}->{ERROR}", "$self->{lang}->{ERR_MESSAGE}" );
    }

    $user->{PHONE} =~ s/^0/+380/g;


    my $list_t = $Paysys->paysys_user_info({
      UID          => $user->{UID},
    });
    if(defined $list_t->{SUBSCRIBE_DATE_START}){
      $info{SUM} = sprintf("%.2f", $list_t->{SUM});
      $info{DATE} = POSIX::strftime('%Y-%m-%d', ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst));
      my $url_env = ($ENV) ? "$ENV{PROT}://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}" : $attr->{IP};
      $info{HREF} = "$url_env/index.cgi?index=$attr->{index}&PAYMENT_SYSTEM=$attr->{PAYMENT_SYSTEM}&SUM=1.00&UNSUBSRIBE=1";

      $html->tpl_show(main::_include('paysys_liqpay_delete_rec', 'Paysys'), { %{($attr) ? $attr : {}}, %info, %$user });

    }
    else {
      if (!$attr->{CHECKBOX}) {
        my $day_start = POSIX::strftime('%Y-%m-%d', ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst));

        $html->tpl_show(main::_include('paysys_liqpay_card', 'Paysys'), {
          %$attr,
          SUBSCRIBE_DATE_START => "$day_start",
          DESCRIPTION          => $description,
          PHONE                => $user->{PHONE},
        },
          { OUTPUT2RETURN => 0 }
        );

      }
      else {
        if($attr->{checkbox} == 1) {
          ($info{SIGN}, $info{BODY}) = $self->liqpay_make_request_subscribe({

            DOMAIN_ID            => $user->{DOMAIN_ID},
            GID                  => $user->{GID},
            DESCRIPTION          => $description,
            PHONE                => $user->{PHONE},
            SUM                  => sprintf(".2f", $attr->{SUM}),
            SUBSCRIBE_DATE_START => $attr->{SUBSCRIBE_DATE_START},
            %$attr
          });

          #Info section
          $Paysys->add(
            {
              SYSTEM_ID      => 62,
              SUM            => $attr->{SUM},
              COMMISSION     => $info{COMMISSION_SUM},
              UID            => $attr->{UID} || $user->{UID},
              IP             => $ENV{'REMOTE_ADDR'},
              TRANSACTION_ID => "$PAYSYSTEM_SHORT_NAME:$attr->{OPERATION_ID}",
              INFO           => $attr->{DESCRIBE},
              PAYSYS_IP      => "$ENV{'REMOTE_ADDR'}",
              STATUS         => 1,
              DOMAIN_ID      => $user->{DOMAIN_ID},
            }
          );

          if ($Paysys->{errno}) {
            $html->message('err', "ERROR", "ERROR Paysys ID: '$attr->{OPERATION_ID}'");
            return 0;
          }
          $html->tpl_show(main::_include('paysys_liqpay_add', 'Paysys'), { %{($attr) ? $attr : {}}, %info, %$user });
        }
        else{
          #Info section
          $Paysys->add(
            {
              SYSTEM_ID      => 62,
              SUM            => $attr->{SUM},
              COMMISSION     => $info{COMMISSION_SUM},
              UID            => $attr->{UID} || $user->{UID},
              IP             => $ENV{'REMOTE_ADDR'},
              TRANSACTION_ID => "$PAYSYSTEM_SHORT_NAME:$attr->{OPERATION_ID}",
              INFO           => $attr->{DESCRIBE},
              PAYSYS_IP      => "$ENV{'REMOTE_ADDR'}",
              STATUS         => 1,
              DOMAIN_ID      => $user->{DOMAIN_ID},
            }
          );

          if ($Paysys->{errno}) {
            $html->message('err', "ERROR", "ERROR Paysys ID: '$attr->{OPERATION_ID}'");
            return 0;
          }

          ($info{SIGN}, $info{BODY}) = $self->liqpay_make_request3({
            DOMAIN_ID   => $user->{DOMAIN_ID},
            GID         => $user->{GID},
            DESCRIPTION => $description,
            SUM         => sprintf(".2f", $attr->{SUM}),
            %$attr
          });

          $html->tpl_show(main::_include('paysys_liqpay_add', 'Paysys'), { %{($attr) ? $attr : {}}, %info, %$user });
        }
      }
    }
  }
  else {

    #Info section
    $Paysys->add(
      {
        SYSTEM_ID      => 62,
        SUM            => $attr->{SUM},
        COMMISSION     => $info{COMMISSION_SUM},
        UID            => $attr->{UID} || $user->{UID},
        IP             => $ENV{'REMOTE_ADDR'},
        TRANSACTION_ID => "$PAYSYSTEM_SHORT_NAME:$attr->{OPERATION_ID}",
        INFO           => $attr->{DESCRIBE},
        PAYSYS_IP      => "$ENV{'REMOTE_ADDR'}",
        STATUS         => 1,
        DOMAIN_ID      => $user->{DOMAIN_ID},
      }
    );

    if ($Paysys->{errno}) {
      $html->message('err', "ERROR", "ERROR Paysys ID: '$attr->{OPERATION_ID}'");
      return 0;
    }

    ($info{SIGN}, $info{BODY}) = $self->liqpay_make_request3({
      DOMAIN_ID   => $user->{DOMAIN_ID},
      GID         => $user->{GID},
      DESCRIPTION => $description,
      SUM         => sprintf(".2f", $attr->{SUM}),
      %$attr
    });

    $html->tpl_show(main::_include('paysys_liqpay_add', 'Paysys'), { %{($attr) ? $attr : {}}, %info, %$user });
  }
  return '';
}

#**********************************************************
=head2 liqpay_make_request3()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub liqpay_make_request3 {
  my $self = shift;
  my ($attr) = @_;

  $self->conf_gid_split({ GID => $attr->{GID},
    PARAMS             => [
      'PAYSYS_LIQPAY_MERCHANT_ID',
      'PAYSYS_LIQPAY_MERCHANT_PASS',
      'PAYSYS_LIQPAY_COMMISSION',
      'PAYSYS_LIQPAY_CURRENCY',
      '',
    ]
  });

  if ($attr->{DATA}) {
    my $sign = $self->str_to_sign(
      $self->{conf}{PAYSYS_LIQPAY_MERCHANT_PASS} . $attr->{DATA} . $self->{conf}{PAYSYS_LIQPAY_MERCHANT_PASS}
    );

    return $sign;
  }

  if ($attr->{HOLD_COMPLETION}) {
    my ($sign, undef, $body) = $self->cnb_form({
      'public_key' => $self->{conf}{PAYSYS_LIQPAY_MERCHANT_ID},
      'action'     => 'hold_completion',
      'version'    => '3',
      'amount'     => $attr->{AMOUNT},
      'order_id'   => $attr->{ORDER_ID},
    }
    );

    return $sign, $body;
  }

  my $server_url = $self->{conf}{PAYSYS_LIQPAY_SERVERURL} || "$ENV{PROT}://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}/paysys_check.cgi";
  my $result_url = "$ENV{PROT}://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}/index.cgi?TRUE=1&index=$attr->{index}&OPERATION_ID=Liqpay:$attr->{OPERATION_ID}&PAYMENT_SYSTEM=$attr->{PAYMENT_SYSTEM}";
  my ($sign, $body) = $self->cnb_form({
    'public_key'  => $self->{conf}{PAYSYS_LIQPAY_MERCHANT_ID},
    'action'      => $attr->{ACTION} || 'pay',
    'version'     => '3',
    'amount'      => $attr->{'amount'} || $attr->{TOTAL_SUM},
    'currency'    => $attr->{'currency'} || $self->{conf}{'PAYSYS_LIQPAY_CURRENCY'} || 'UAH',
    'description' => $attr->{'description'} || "Payments ID: $attr->{OPERATION_ID}" . $attr->{DESCRIPTION},
    'order_id'    => $attr->{'order_id'} || "Liqpay:$attr->{OPERATION_ID}",
    'result_url'  => $result_url,
    'server_url'  => $server_url,
    'pay_way'     => $self->{conf}{PAYSYS_LIQPAY_PAYWAY} || undef,
  }
  );

  return $sign, $body;
}

#**********************************************************
=head2 cnb_form ()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub cnb_form {
  my $self = shift;
  my ($payment) = @_;

  my $json_payment = JSON::encode_json($payment);

  my $data = AXbills::Base::encode_base64($json_payment);

  $data =~ s/[\r\n]+//g;

  my $sign_string = $self->{conf}{PAYSYS_LIQPAY_MERCHANT_PASS} . $data . $self->{conf}{PAYSYS_LIQPAY_MERCHANT_PASS};

  use Digest::SHA1 qw/sha1_base64 sha1/;
  my $signature = AXbills::Base::encode_base64(Digest::SHA1::sha1($sign_string));
  $signature =~ s/[\r\n]+//g;

  my $form = '';
  $form .= qq[<input type="hidden" name="data" value="] . $data . qq[" />];

  return $signature, $form, $data;
}

#**********************************************************
=head2 str_to_sign()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub str_to_sign {
  my ($self, $str) = @_;

  use Digest::SHA1 qw/sha1_base64 sha1/;
  my $signature = AXbills::Base::encode_base64(Digest::SHA1::sha1($str));
  chop($signature);

  return $signature;
}

#**********************************************************
=head2 _process_old_syle()


=cut
#**********************************************************
sub _process_old_syle {
  my $self = shift;
  my ($FORM) = @_;

  my $data = $FORM->{data};
  my $result_hash = JSON::decode_json(AXbills::Base::decode_base64($data));

  my $status = $result_hash->{status} || q{};
  my $action = $result_hash->{action} || q{};
  my $order_id = $result_hash->{'order_id'};
  my $payment_id =$result_hash->{'payment_id'} || q{};
  my $amount = $result_hash->{'amount_credit'} - $result_hash->{'commission_credit'};

  if ($FORM->{pay_way} eq 'delayed') {
    return 0;
  }

  my $Paysys = Paysys->new($self->{db}, $self->{admin}, $self->{conf});
  my $list = $Paysys->list(
    {
      TRANSACTION_ID => "$order_id",
      STATUS         => '_SHOW',          #'<>2',
      GID            => '_SHOW',
      COLS_NAME      => 1,
      DOMAIN_ID      => '_SHOW',
      UID            => '_SHOW',
      SORT           => 1
    }
  );

  use POSIX qw(strftime);

  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();

  $mday = 2;
  $mon++;
  if ($mon == 13) {
    $mon = 1;
    $year++;
  }

  my $date_sub = POSIX::strftime('%Y-%m-%d', ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst));

  my $id = $list->[0]->{id};
  my $domain_id = $list->[0]->{domain_id};
  my $gid = $list->[0]->{gid};

  my $sign = $self->liqpay_make_request3({
    GID       => $gid,
    DOMAIN_ID => $domain_id,
    DATA      => $data
  });

  if ($FORM->{'signature'} && $FORM->{'signature'} ne $sign) {
    $status = 5;
    return 1;
  }

  my %errors = (
    'success'     => 0,
    'failure'     => 6,
    'otp_verify'  => 6,
    '3ds_verify'  => 6,
    'wait_secure' => 12,
    'wait_accept' => 12,
    'wait_lc'     => 0,
    'processing'  => 1,
    'subscribed'  => 1,
    #'unsubscribed' => 0,
    'sandbox'     => 12,
    'error'       => 6,
    'reversed'    => 3,
  );

  if($status eq 'subscribed'){
    $Paysys->paysys_user_add({
      UID                  => $list->[0]->{uid},
      SUM                  => $result_hash->{'amount'},
      SUBSCRIBE_DATE_START => $date_sub,
      RECURRENT_MODULE     => $PAYSYSTEM_NAME,
      ORDER_ID             => $list->[0]->{transaction_id},
      PAYSYS_ID            => $PAYSYSTEM_ID
    });

    print "STATUS = 'subscribed'; UID => $list->[0]->{uid}; DATE_SUBSCRIBE => $date_sub; SUM => $result_hash->{'amount'}; ORDER_ID =>$list->[0]->{transaction_id};";
  }
  elsif($status eq 'unsubscribed'){
    $Paysys->paysys_main_del({
      #UID                  => $list->[0]->{uid},
      order_id => "$list->[0]->{transaction_id}"
    });

    print "STATUS = 'unsubscribed'; UID => $list->[0]->{uid}; ORDER_ID =>$list->[0]->{transaction_id};";
  }
  elsif($action eq 'regular'){
    my $paysys_regular = main::paysys_pay({
      PAYMENT_SYSTEM    => $PAYSYSTEM_SHORT_NAME,
      PAYMENT_SYSTEM_ID => $PAYSYSTEM_ID,
      PAYMENT_DESCRIBE  => "Liqpay subscribe $list->[0]->{transaction_id}",
      SUM               => $amount,
      CHECK_FIELD       => 'UID',
      USER_ID           => $list->[0]->{uid},
      EXT_ID            => $payment_id,
      DATA              => $result_hash,
      DATE              => "$main::DATE $main::TIME",
      MK_LOG            => 1,
      CURRENCY          => $FORM->{'currency'},
      COMMISSION        => 1,

    });

    print $paysys_regular;
    return $paysys_regular;
  }

  if ($Paysys->{TOTAL} > 0) {
    my $paysys_status = main::paysys_pay({
      PAYMENT_SYSTEM    => $PAYSYSTEM_SHORT_NAME,
      PAYMENT_SYSTEM_ID => $PAYSYSTEM_ID,
      PAYMENT_DESCRIBE  =>
        "$result_hash->{description} # $result_hash->{sender_phone}" . (($result_hash->{state} && $result_hash->{state} eq 'test') ? ' (test)' : ''),
      SUM               => $amount,
      PAYSYS_ID         => $id,
      DATA              => $result_hash,
      ERROR             => ($status eq 'success') ? undef : (($errors{$status}) ? $errors{$status} : 6),
      MK_LOG            => 1,
      CURRENCY          => $FORM->{'currency'},
      COMMISSION        => 1
    });
    print $paysys_status;
    return $paysys_status;
  }

}

#**********************************************************
=head2 conf_gid_split()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub conf_gid_split {
  my $self = shift;
  my ($attr) = @_;

  my $gid    = $attr->{GID};

  if ($attr->{SERVICE} && $attr->{SERVICE2GID}) {
    my @services_arr = split(/;/, $attr->{SERVICE2GID});
    foreach my $line (@services_arr) {
      my($service, $gid_id)=split(/:/, $line);
      if($attr->{SERVICE} == $service) {
        $gid = $gid_id;
        last;
      }
    }
  }

  if ($attr->{PARAMS}) {
    my $params = $attr->{PARAMS};
    foreach my $key ( @$params ) {
      if ($self->{conf}{$key .'_'. $gid}) {
        $self->{conf}{$key} = $self->{conf}{$key .'_'. $gid};
      }
    }

  }

  return 1;
}
#**********************************************************
=head2 liqpay_make_request_token()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub liqpay_make_request_token {
  my $self = shift;
  my ($attr) = @_;

  $self->conf_gid_split({ GID => $attr->{GID},
    PARAMS             => [
      'PAYSYS_LIQPAY_MERCHANT_ID',
      'PAYSYS_LIQPAY_MERCHANT_PASS',
      'PAYSYS_LIQPAY_COMMISSION',
      'PAYSYS_LIQPAY_CURRENCY',
      'PAYSYS_LIQPAY_SUBSCRIBE',
      '',
    ]
  });

  if ($attr->{DATA}) {
    my $sign = $self->str_to_sign(
      $self->{conf}{PAYSYS_LIQPAY_MERCHANT_PASS} . $attr->{DATA} . $self->{conf}{PAYSYS_LIQPAY_MERCHANT_PASS}
    );

    return $sign;
  }

  if ($attr->{TOKEN}) {
    my ($sign, undef, $body) = $self->cnb_form({
      'public_key' => $self->{conf}{PAYSYS_LIQPAY_MERCHANT_ID},
      'action'     => 'pay',
      'version'    => '3',
      'recurringbytoken' => '1',
      'amount'     => $attr->{AMOUNT},
      'order_id'   => $attr->{ORDER_ID},
    }
    );

    return $sign, $body;
  }

  my $server_url = $self->{conf}{PAYSYS_LIQPAY_SERVERURL} || "$ENV{PROT}://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}/paysys_check.cgi";
  my $result_url = "$ENV{PROT}://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}/index.cgi?TRUE=1&index=$attr->{index}&OPERATION_ID=Liqpay:$attr->{OPERATION_ID}&PAYMENT_SYSTEM=$attr->{PAYMENT_SYSTEM}";
  my ($sign, $body) = $self->cnb_form({
    'version'     => '3',
    'public_key'  => $self->{conf}{PAYSYS_LIQPAY_MERCHANT_ID},
    'action'      => $attr->{ACTION} || 'paytoken',
    'amount'      => $attr->{'amount'} || $attr->{TOTAL_SUM},
    'card_token'  => '',
    'currency'    => $attr->{'currency'} || $self->{conf}{'PAYSYS_LIQPAY_CURRENCY'} || 'UAH',
    'description' => $attr->{'description'} || "Payments ID: $attr->{OPERATION_ID}" . $attr->{DESCRIPTION},
    'ip'          => "$ENV{'REMOTE_ADDR'}",
    'order_id'    => $attr->{'order_id'} || "Liqpay:$attr->{OPERATION_ID}",
    'result_url'  => $result_url,
    'server_url'  => $server_url,
    'subscribe'   => '1',
    'subscribe_date_start'=> $attr->{'date_start'},
    'subscribe_periodicity' => 'month'
  }
  );

  return $sign, $body;
}

#**********************************************************
=head2 liqpay_make_request_subscribe()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub liqpay_make_request_subscribe {
  my $self = shift;
  my ($attr) = @_;

  $self->conf_gid_split({ GID => $attr->{GID},
    PARAMS             => [
      'PAYSYS_LIQPAY_MERCHANT_ID',
      'PAYSYS_LIQPAY_MERCHANT_PASS',
      'PAYSYS_LIQPAY_COMMISSION',
      'PAYSYS_LIQPAY_CURRENCY',
      'PAYSYS_LIQPAY_SUBSCRIBE',
      '',
    ]
  });

  if ($attr->{DATA}) {
    my $sign = $self->str_to_sign(
      $self->{conf}{PAYSYS_LIQPAY_MERCHANT_PASS} . $attr->{DATA} . $self->{conf}{PAYSYS_LIQPAY_MERCHANT_PASS}
    );

    return $sign;
  }

  my $server_url = $self->{conf}{PAYSYS_LIQPAY_SERVERURL} || "$ENV{PROT}://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}/paysys_check.cgi";
  my $result_url = "$ENV{PROT}://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}/index.cgi?TRUE=1&index=$attr->{index}&OPERATION_ID=Liqpay:$attr->{OPERATION_ID}&PAYMENT_SYSTEM=$attr->{PAYMENT_SYSTEM}";

  my ($sign, $body) = $self->cnb_form({
    'version'     => '3',
    'public_key'  => $self->{conf}{PAYSYS_LIQPAY_MERCHANT_ID},
    'action'      => 'subscribe',
    'amount'      => $attr->{'amount'} || $attr->{TOTAL_SUM},
    'currency'    => $attr->{'currency'} || $self->{conf}{'PAYSYS_LIQPAY_CURRENCY'} || 'UAH',
    'description' => $attr->{DESCRIPTION} || "Payments ID: $attr->{OPERATION_ID}" . $attr->{DESCRIPTION},
    'ip'          => "$ENV{'REMOTE_ADDR'}",
    'order_id'    => $attr->{'order_id'} || "Liqpay:$attr->{OPERATION_ID}",
    'result_url'  => $result_url,
    'server_url'  => $server_url,
    'phone'       => $attr->{PHONE},
    'subscribe'   => '1',
    'subscribe_date_start'=> "$attr->{SUBSCRIBE_DATE_START}"." "."00:00:00",
    'subscribe_periodicity' => 'month',
  }
  );

  return $sign, $body;
}

#**********************************************************
=head2 liqpay_unsubscribe()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub liqpay_unsubscribe {
  my $self = shift;
  my ($attr) = @_;

  $self->conf_gid_split({ GID => $attr->{GID},
    PARAMS             => [
      'PAYSYS_LIQPAY_MERCHANT_ID',
      'PAYSYS_LIQPAY_MERCHANT_PASS',
      'PAYSYS_LIQPAY_COMMISSION',
      'PAYSYS_LIQPAY_CURRENCY',
      'PAYSYS_LIQPAY_SUBSCRIBE',
      '',
    ]
  });

  if ($attr->{DATA}) {
    my $sign = $self->str_to_sign(
      $self->{conf}{PAYSYS_LIQPAY_MERCHANT_PASS} . $attr->{DATA} . $self->{conf}{PAYSYS_LIQPAY_MERCHANT_PASS}
    );
    return $sign;
  }

  my ($sign, $body, $for) = $self->cnb_form({
    'version'     => '3',
    'public_key'  => $self->{conf}{PAYSYS_LIQPAY_MERCHANT_ID},
    'action'      => 'unsubscribe',
    'order_id'    => "$attr->{ORDER_ID}",
  }
  );

  return $sign, $for;
}

#**********************************************************
=head2 liqpay_subscribe_update()

  Arguments:
    -

  Returns:

=cut
#**********************************************************
sub liqpay_subscribe_update {
  my $self = shift;
  my ($attr) = @_;

  $self->conf_gid_split({ GID => $attr->{GID},
    PARAMS             => [
      'PAYSYS_LIQPAY_MERCHANT_ID',
      'PAYSYS_LIQPAY_MERCHANT_PASS',
      'PAYSYS_LIQPAY_COMMISSION',
      'PAYSYS_LIQPAY_CURRENCY',
      'PAYSYS_LIQPAY_SUBSCRIBE',
      '',
    ]
  });

 if ($attr->{DATA}) {
    my $sign = $self->str_to_sign(
      $self->{conf}->{conf}{PAYSYS_LIQPAY_MERCHANT_PASS} . $attr->{DATA} . $self->{conf}->{conf}{PAYSYS_LIQPAY_MERCHANT_PASS}
    );

    return $sign;
  }

  my ($sign, $body) = $self->cnb_form({
    'version'     => '3',
    'public_key'  => $self->{conf}->{conf}{PAYSYS_LIQPAY_MERCHANT_ID},
    'action'      => 'subscribe_update',
    'amount'      => $attr->{SUM},
    'order_id'    => "$attr->{ORDER_ID}",
    'currency'    => $attr->{'currency'} || $self->{conf}->{conf}{'PAYSYS_LIQPAY_CURRENCY'} || 'UAH',
    'description' => "subscribe_update"
  }
  );

  return $sign, $body;
}
#**********************************************************
=head2 paysys_subscribe_pay()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub paysys_subscribe_pay{
  my $self = shift;
  my ($attr) = @_;
  my ($uid, $sum, $order_id, $fee, $gid) = @_;

  my $Paysys = Paysys->new($self->{db}, $self->{admin}, $self->{conf});

  # заполняем поля данными
  my %info = ();
  my $payment_new;

  if ($fee > $sum){
     $payment_new = $fee;
  }
  elsif($fee == 0){
     $payment_new = sprintf("%.2f", 0.1);
  }
  else{
    return 0;
  }

  ($info{signature}, $info{data}) = $self->liqpay_subscribe_update({
    ORDER_ID => $order_id,
    SUM      => $payment_new,
    UID      => $uid,
    GID      => $gid
 });

  my $url = "https://www.liqpay.ua/api/checkout";
  my $payments_result = web_request(
    $url,
   {
      CURL           => 1,
      DEBUG          => 0,
      REQUEST_PARAMS => \%info,
    }
  );

  if($payments_result->{errno} || $payments_result->{error}) {
     $html->message('err', "$self->{lang}->{ERROR}", "$self->{lang}->{ERR_MESSAGE_JSON}");
    return 0;
  }

}
1;