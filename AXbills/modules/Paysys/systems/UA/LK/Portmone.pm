=head1 Portmone
  New module for Portmone

  Documentaion:

  Date: 28.05.2019
  Update: 28.10.2019
  Version: 8.00
=cut


use strict;
use warnings;
use AXbills::Base qw(_bp);
use AXbills::Misc qw(load_module);
use Paysys;
require Paysys::Paysys_Base;
package Paysys::systems::Portmone;
use AXbills::Fetcher qw(web_request);

our $PAYSYSTEM_NAME = 'Portmone';
our $PAYSYSTEM_SHORT_NAME = 'PM';
our $PAYSYSTEM_ID = 45;
our $PAYSYSTEM_VERSION = '8.00';
our %PAYSYSTEM_CONF = (
  PAYSYS_PORTMONE_PAYEE_ID   => '',
  PAYSYS_PORTMONE_CURRENCY   => '',
  PAYSYS_PORTMONE_LOGIN      => '',
  PAYSYS_PORTMONE_PASSWORD   => '',
  PAYSYS_PORTMONE_COMMISSION => '',
);

my ($html);


#**********************************************************
=head2 new($db, $admin, $CONF)

  Arguments:
    $db    - ref to DB
    $admin - current Web session admin
    $CONF  - ref to %conf
    $attr  - {
      HTML - $HTML_OBJECT
    }

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
  my $lang = $attr->{LANG};
  my %pay_params = ();

  if ($user->{GID}) {
    $self->account_gid_split($user->{GID});
  }

  if (!$self->{conf}{PAYSYS_PORTMONE_PAYEE_ID} || !$self->{conf}{PAYSYS_PORTMONE_CURRENCY} || !$self->{conf}{PAYSYS_PORTMONE_COMMISSION}) {
    $html->message('err', $lang->{ERROR}, "Payment system has wrong configuration");
    return 0;
  }
  if (!$attr->{SUM} || $attr->{SUM} == 0) {
    $html->message('err', $lang->{ERROR}, "Payment sum is too small.");
    return 0;
  }

  $pay_params{PAYEE_ID} = $self->{conf}{PAYSYS_PORTMONE_PAYEE_ID};
  $pay_params{SHOP_ORDER_NUMBER} = $attr->{OPERATION_ID};
  $pay_params{BILL_AMOUNT} = (($attr->{SUM} * ($self->{conf}{PAYSYS_PORTMONE_COMMISSION} + 100)) / 100);
  $pay_params{SUM} = $attr->{SUM};
  $pay_params{COMMISSION} = $self->{conf}{PAYSYS_PORTMONE_COMMISSION};
  $pay_params{DESCRIBE} = $attr->{DESCRIBE};
  $pay_params{BILL_CURRENCY} = $self->{conf}{PAYSYS_PORTMONE_CURRENCY};
  $pay_params{URL_SUCCESS} = "$AXbills::HTML::SELF_URL";
  $pay_params{URL_FAILED} = "$AXbills::HTML::SELF_URL";
  $pay_params{UID} = $attr->{UID} || $user->{UID};

  my $Paysys = Paysys->new($self->{db}, $self->{admin}, $self->{conf});
  #Add paysys
  $Paysys->add(
    {
      SYSTEM_ID      => $PAYSYSTEM_ID,
      SUM            => $attr->{SUM},
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

  return $html->tpl_show(main::_include('paysys_portmone_add', 'Paysys'), { %pay_params }, { OUTPUT2RETURN => 0 });
}

#**********************************************************
=head2 proccess()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub proccess {
  my $self = shift;
  my ($FORM) = @_;

  $FORM->{__BUFFER} = '' if (!$FORM->{__BUFFER});

  print "Content-Type: text/xml\n\n";

  my $mod_return = main::load_pmodule('XML::Simple', { SHOW_RETURN => 1 });
  if ($mod_return) {
    main::mk_log($mod_return, { PAYSYS_ID => $PAYSYSTEM_NAME });
  }
  $FORM->{__BUFFER} =~ s/data=//g;
  my $_xml = eval {XML::Simple::XMLin($FORM->{__BUFFER}, ForceArray => 0, KeyAttr => 1)};

  my %request_hash = %$_xml;
  my $uid = $request_hash{BILL}{PAYER}{ATTRIBUTE1};
  my ($check_result, $user_info) = main::paysys_check_user({
    CHECK_FIELD => 'UID',
    USER_ID     => $uid
  });

  if ($check_result == 0) {
    $self->account_gid_split($user_info->{GID});
  }
  my $order_id = $request_hash{BILL}{BILL_NUMBER};
  my $sum = (($request_hash{BILL}{PAYED_AMOUNT} * 100) / (100 + $self->{conf}{PAYSYS_PORTMONE_COMMISSION}));

  my $paysys_status = main::paysys_pay({
    PAYMENT_SYSTEM    => $PAYSYSTEM_SHORT_NAME,
    PAYMENT_SYSTEM_ID => $PAYSYSTEM_ID,
    SUM               => $sum,
    CHECK_FIELD       => 'UID',
    USER_ID           => $uid,
    ORDER_ID          => "$PAYSYSTEM_SHORT_NAME:$order_id",
    EXT_ID            => "$order_id",
    DATA              => $FORM,
    MK_LOG            => 1
  });

  main::mk_log("RESULT: status - $paysys_status", { PAYSYS_ID => "$PAYSYSTEM_NAME" });

  return 1;
}

#**********************************************************
=head2 periodic()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub periodic {
  my $self = shift;
  my ($attr) = @_;
  my $url = qq{https://www.portmone.com.ua/gateway/};
  my $Paysys = Paysys->new($self->{db}, $self->{admin}, $self->{conf});
  my $paysystem_id = $attr->{PAYSYS_ID} || $PAYSYSTEM_ID;

  my $list_settings = $Paysys->groups_settings_list({
    GID       => '_SHOW',
    PAYSYS_ID => $paysystem_id,
    COLS_NAME => 1,
    PAGE_ROWS => 99999,
  });

  if (scalar(@$list_settings) == 0) {
    push @$list_settings, { 'GID' => '0' };
  }

  foreach my $group (@$list_settings) {
    $self->account_gid_split($group->{GID}) if ($group->{GID});

    if (!$self->{conf}{PAYSYS_PORTMONE_PAYEE_ID}
      || !$self->{conf}{PAYSYS_PORTMONE_LOGIN}
      || !$self->{conf}{PAYSYS_PORTMONE_PASSWORD}
      || !$self->{conf}{PAYSYS_PORTMONE_COMMISSION}) {
      next;
    }

    $Paysys->list({
      DATE           => $main::DATE,
      PAYMENT_SYSTEM => $paysystem_id,
      ID             => '_SHOW',
      SUM            => '_SHOW',
      TRANSACTION_ID => '_SHOW',
      STATUS         => 1,
      #    COLS_NAME      => 1,
      LIST2HASH      => 'transaction_id,status',
    });

    my $list = $Paysys->{list_hash};

    my $portmone_paymens = web_request($url, {
      REQUEST_PARAMS => {
        'method'     => 'result',
        'payee_id'   => $self->{conf}{PAYSYS_PORTMONE_PAYEE_ID},
        'login'      => $self->{conf}{PAYSYS_PORTMONE_LOGIN},
        'password'   => $self->{conf}{PAYSYS_PORTMONE_PASSWORD},
        'status'     => 'PAYED',
        'start_date' => $main::DATE,
        'end_date'   => $main::DATE,
      },
      POST           => 1,
      INSECURE       => 1,
      DEBUG          => $self->{DEBUG}
    });

    my $mod_return = main::load_pmodule('XML::Simple', { SHOW_RETURN => 1 });
    if ($mod_return) {
      main::mk_log($mod_return, { PAYSYS_ID => $PAYSYSTEM_NAME });
    }
    my $xml = eval {XML::Simple::XMLin($portmone_paymens, ForceArray => 0, KeyAttr => 1)};

    if (ref($xml->{orders}{order}) eq 'ARRAY') {
      foreach my $item (@{$xml->{orders}{order}}) {
        if ($item->{shop_order_number}) {
          if ($list->{"$PAYSYSTEM_SHORT_NAME:$item->{shop_order_number}"}) {
            my $sum = (($item->{bill_amount} * 100) / (100 + $self->{conf}{PAYSYS_PORTMONE_COMMISSION}));
            my $paysys_status = main::paysys_pay({
              PAYMENT_SYSTEM    => $PAYSYSTEM_SHORT_NAME,
              PAYMENT_SYSTEM_ID => $paysystem_id,
              SUM               => $sum,
              ORDER_ID          => "$PAYSYSTEM_SHORT_NAME:$item->{shop_order_number}",
              EXT_ID            => "$item->{shop_order_number}",
              DATA              => $item,
              MK_LOG            => 1,
              DEBUG             => 1
            });

            main::mk_log("RESULT: status - $paysys_status", { PAYSYS_ID => "$PAYSYSTEM_NAME" });
          }
        }
      }
    }
    elsif (ref($xml->{orders}{order}) eq 'HASH') {
      if ($xml->{orders}{order}{shop_order_number}) {
        if ($list->{"$PAYSYSTEM_SHORT_NAME:$xml->{orders}{order}{shop_order_number}"}) {
          my $sum = (($xml->{orders}{order}{bill_amount} * 100) / (100 + $self->{conf}{PAYSYS_PORTMONE_COMMISSION}));
          my $paysys_status = main::paysys_pay({
            PAYMENT_SYSTEM    => $PAYSYSTEM_SHORT_NAME,
            PAYMENT_SYSTEM_ID => $paysystem_id,
            SUM               => $sum,
            ORDER_ID          => "$PAYSYSTEM_SHORT_NAME:$xml->{orders}{order}{shop_order_number}",
            EXT_ID            => "$xml->{orders}{order}{shop_order_number}",
            DATA              => $xml->{orders}{order},
            MK_LOG            => 1,
            DEBUG             => 1
          });

          main::mk_log("RESULT: status - $paysys_status", { PAYSYS_ID => "$PAYSYSTEM_NAME" });
        }
      }
    }
  }

  return 1;
}

#**********************************************************
=head2 account_gid_split() - change configuration for groups

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub account_gid_split {
  my $self = shift;
  my ($gid) = @_;

  foreach my $key (keys %PAYSYSTEM_CONF) {
    if ($self->{conf}{$key . '_' . $gid}) {
      $self->{conf}{$key} = $self->{conf}{$key . '_' . $gid};
    }
  }

  return 1;
}

1;