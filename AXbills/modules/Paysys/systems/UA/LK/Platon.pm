=head1 Platon
  New module for Platon

  Documentaion:

  Date: 09.07.2019
  Update: 21.07.2020

  Version: 7.02
=cut


use strict;
use warnings;
use AXbills::Base qw(_bp load_pmodule);
use Paysys;
require Paysys::Paysys_Base;
package Paysys::systems::Platon;

our $PAYSYSTEM_NAME = 'Platon';
our $PAYSYSTEM_SHORT_NAME = 'PL';
our $PAYSYSTEM_ID = 108;
our $PAYSYSTEM_VERSION = '7.02';
our %PAYSYSTEM_CONF = (
  'PAYSYS_PLATON_KEY'        => '',
  'PAYSYS_PLATON_PASS'       => '',
  'PAYSYS_PLATON_COMMISSION' => '%',
  'PAYSYS_PLATON_URL'        => ''
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


  if ($attr->{TRUE}) {
    $html->message('success', $lang->{SUCCESS}, "Payment done");
    return 0;
  }
  if (!$self->{conf}{PAYSYS_PLATON_KEY}
    || !$self->{conf}{PAYSYS_PLATON_PASS}
    || !$self->{conf}{PAYSYS_PLATON_COMMISSION}
    || !$self->{conf}{PAYSYS_PLATON_URL}) {
    $html->message('err', $lang->{ERROR}, "Payment system has wrong configuration");
    return 0;
  }
  if (!$attr->{SUM} || $attr->{SUM} == 0) {
    $html->message('err', $lang->{ERROR}, "Payment sum is too small.");
    return 0;
  }


  my $commission = $self->{conf}{PAYSYS_PLATON_COMMISSION};
  my $total_sum = $attr->{SUM} * (1 / (1 - $commission / 100));

  $pay_params{KEY}          = $self->{conf}{"PAYSYS_PLATON_KEY" . "_$user->{GID}"};
  $pay_params{SUM}          = $attr->{SUM};
  #$total_sum+0.00000005 for proper rounding ex.5.125
  $pay_params{TOTAL}        = sprintf('%.2f',$total_sum+0.00000005);
  $pay_params{COMMISSION}   = $commission . "%";
  $pay_params{PAYMENT}      = 'CC';
  $pay_params{ORDER_ID}     = $attr->{OPERATION_ID};
  $pay_params{URL_OK}       = "$ENV{PROT}://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}/index.cgi?TRUE=1&index=$attr->{index}&OPERATION_ID="
  . "$attr->{OPERATION_ID}&PAYMENT_SYSTEM=$attr->{PAYMENT_SYSTEM}";
  $pay_params{PAY_URL}      = $self->{conf}{PAYSYS_PLATON_URL};
  $pay_params{UID}          = $attr->{UID} || $user->{UID};

  my $service = sprint('', $total_sum - $attr->{SUM});

  AXbills::Base::load_pmodule('Digest::MD5');
  AXbills::Base::load_pmodule('JSON');
  my %product = (
  'amount'      => sprintf('%.2f',$total_sum+0.00000005),
  'currency'    => 'UAH',
  'description' => 'Payment'
  );

  my $json_product = JSON::to_json(\%product);
  my $base_product = AXbills::Base::encode_base64($json_product);
  $base_product =~ s/\n//g;

  $pay_params{PRODUCT_DATA} = $base_product;

  my $reverse_string = reverse($pay_params{KEY}) . reverse($pay_params{PAYMENT}) . reverse($base_product) . reverse($pay_params{URL_OK}) . reverse($self->{conf}{"PAYSYS_PLATON_PASS" . "_$user->{GID}"});
  my $uc_string = uc($reverse_string);
  my $signature = Digest::MD5::md5_hex($uc_string);
  $pay_params{SIGNATURE}    = $signature;

    return $html->tpl_show(main::_include('paysys_platon_add', 'Paysys'), { %pay_params, SERVICE => $service}, { OUTPUT2RETURN => 0 });
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

  print "Content-Type: text/plain\n\n";

  my ($result_code, $user_object) = main::paysys_check_user({
    CHECK_FIELD        => "UID",
    USER_ID            => $FORM->{ext1},
    DEBUG              => $self->{DEBUG},
    SKIP_DEPOSIT_CHECK => 1
  });

  my $gid = $user_object->{GID};

  my $pass = $self->{conf}{"PAYSYS_PLATON_PASS" . "_$gid"} || '';

  my $rev_string = reverse($FORM->{email}) . $pass . $FORM->{order} . reverse(substr($FORM->{card}, 0, 6) . substr($FORM->{card}, -4));
  my $uc_string = uc($rev_string);
  AXbills::Base::load_pmodule('Digest::MD5');
  my $signature = Digest::MD5::md5_hex($uc_string);

  my $commission = $self->{conf}{PAYSYS_PLATON_COMMISSION} || 0;
  my $amount = $FORM->{amount} / (1 / (1 - $commission / 100));
  my $sum = sprintf('%.2f', $amount);


  if ($signature eq $FORM->{sign}) {
    if ($FORM->{status} eq 'SALE') {
      my $paysys_status = main::paysys_pay({
        PAYMENT_SYSTEM    => $PAYSYSTEM_SHORT_NAME,
        PAYMENT_SYSTEM_ID => $PAYSYSTEM_ID,
        CHECK_FIELD       => 'UID',
        USER_ID           => $FORM->{ext1},
        SUM               => $sum,
        EXT_ID            => $FORM->{order},
        DATA              => $FORM,
        MK_LOG            => 1,
        DEBUG             => 1,
        PAYMENT_DESCRIBE  => $FORM->{payment_description} ? $FORM->{payment_description} : "$PAYSYSTEM_NAME",
      });

      if ($paysys_status == 0) {
        print 'SUCCESS';
        main::mk_log("RESULT: status - $paysys_status", { PAYSYS_ID => "$PAYSYSTEM_NAME" });
        return 1;
      }
    }
    else {
      print qq{Status: 520 Wrong Operation
Content-type: text/html

<HTML>
<HEAD><TITLE>520 Wrong Operation</TITLE></HEAD>
<BODY>
  <H1>Error</H1>
  <P>Wrong Operation</P>
</BODY>
</HTML>
    };
      return 0;
    };
  }
  else {
    print qq{Status: 530 Wrong Operation
Content-type: text/html

<HTML>
<HEAD><TITLE>530 Wrong Operation</TITLE></HEAD>
<BODY>
  <H1>Error</H1>
  <P>Wrong Operation</P>
</BODY>
</HTML>
    };
    return 0;
  }

  print qq{Status: 540 Wrong Operation
Content-type: text/html

<HTML>
<HEAD><TITLE>540 Wrong Operation</TITLE></HEAD>
<BODY>
  <H1>Error</H1>
  <P>Wrong Operation</P>
</BODY>
</HTML>
    };

  return 1;
}
1;