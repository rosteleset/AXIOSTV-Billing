=head1 24_non_stop
  New module for 24 NON STOP

  Documentaion: http://billing.axiostv.ru/wiki/lib/exe/fetch.php/axbills:docs:modules:paysys:24nonstop_protocol_for_providers_service_2.20.pdf

  Date: 24.10.2018
  Update: 15.05.2020
  Version: 7.05
=cut

use strict;
use warnings FATAL => 'all';

use AXbills::Base qw(_bp date_format convert);
use AXbills::Misc qw(load_module);
require Paysys::Paysys_Base;

package Paysys::systems::24_non_stop;
our $PAYSYSTEM_NAME = '24NS';
our $PAYSYSTEM_SHORT_NAME = '24NS';
our $PAYSYSTEM_ID = 52;

our $PAYSYSTEM_VERSION = '7.05';

my $CUSTOM_NAME = uc($PAYSYSTEM_NAME);
my $CUSTOM_ID   = $PAYSYSTEM_ID;

our %PAYSYSTEM_CONF = (
  PAYSYS_NAME_ACCOUNT_KEY => '',
  PAYSYS_NAME_SECRET      => '',
  PAYSYS_NAME_MIN_AMOUNT  => '',
  PAYSYS_NAME_MAX_AMOUNT  => '',
  PAYSYS_NAME_FAST_PAY    => '',
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
  $SETTINGS{ID} = $CUSTOM_ID;
  $SETTINGS{NAME} = $PAYSYSTEM_NAME;

  $SETTINGS{CONF} = \%PAYSYSTEM_CONF;

  return %SETTINGS;
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

  if ($self->{DEBUG} > 1) {
    print "Content-Type: text/plain\n\n";
  }
  elsif ($FORM->{test}) {

  }
  else {
    print "Content-Type: text/xml\n\n";
  }

  my $mod_return = main::load_pmodule('Digest::MD5', { SHOW_RETURN => 1 });

  if ($mod_return) {
    main::mk_log($mod_return, { PAYSYS_ID => "$CUSTOM_ID/$CUSTOM_NAME" });
  }

  my $md5 = Digest::MD5->new();
  $md5->reset();

  my $act = $FORM->{ACT};
  my $CHECK_FIELD = $self->{conf}{"PAYSYS_" . $CUSTOM_NAME . "_ACCOUNT_KEY"} || 'UID';
  my $status = 0;
  my $EURO_DATE = AXbills::Base::date_format("$main::DATE $main::TIME", '%d.%m.%Y %H:%M:%S');
  my $pay_account = $FORM->{PAY_ACCOUNT} || '';

  my %axbills2_24ns = (
    0  => '0', # ok
    1  => '-40', # not exist user
    2  => '-101', # sql error
    3  => '-100', # dublicate payment
    # 5 - wrong sum
    # 6 - small sum
    # 7 - large sum
    8  => '-10', # Transaction not found
    # 9 - Payment exist
    10 => '-10', # Payment not exist
    11 => '-41', # Disable paysys
    12 => '-101',
    #13 - Paysys exist transaction
    14 => '-40',
    17 => '-90',  # Payment SQL error
    #28 - Wrong exchange rate
    #30 - User not specified
  );

  #Version 2.30
  if ($FORM->{SERVICE_ID}) {
    $self->conf_gid_split($FORM->{SERVICE_ID});
    #    conf_gid_split({
    #      GID    => $FORM{SERVICE_ID},
    #      PARAMS => [
    #        'PAYSYS_24_NON_STOP_SECRET',
    #        'PAYSYS_24_NON_STOP_MIN_AMOUNT',
    #        'PAYSYS_24_NON_STOP_MAX_AMOUNT',
    #        'PAYSYS_24_NON_STOP_ACCOUNT_KEY'
    #      ]
    #    });
    if ($FORM->{ACT} == 1 || $FORM->{ACT} == 4 || $FORM->{ACT} == 7) {
      $md5->add($FORM->{ACT}
        . '_'
        . $pay_account
        . '_'
        . $FORM->{SERVICE_ID}
        . '_'
        . $FORM->{PAY_ID}
        . '_'
        . $self->{conf}{"PAYSYS_" . $CUSTOM_NAME . "_SECRET"});
    }
    else {
      $md5->add($FORM->{ACT}
        . '_'
        . $pay_account
        . '_'
        . $FORM->{SERVICE_ID}
        . '_'
        . $FORM->{PAY_ID}
        . '_'
        . $FORM->{PAY_AMOUNT}
        . '_'
        . $self->{conf}{"PAYSYS_" . $CUSTOM_NAME . "_SECRET"});
    }
    #$md5->add($FORM{ACT} . '_' . $FORM{PAY_ACCOUNT} . '_' . $FORM{SERVICE_ID} . '_' . $FORM{PAY_ID} . '_' . $conf{"PAYSYS_" . $CUSTOM_NAME . "_SECRET"}); # 2.20
  }
  #Version 2.10
  else {
    if ($FORM->{ACT} == 1 || $FORM->{ACT} == 7) {
      $md5->add($FORM->{ACT}
        . '_'
        . $pay_account
        . '_'
        . $FORM->{SERVICE_ID}
        . '_'
        . $FORM->{PAY_ID}
        . '_'
        . $self->{conf}{"PAYSYS_" . $CUSTOM_NAME . "_SECRET"});
    }
    else {
      $md5->add($FORM->{ACT}
        . '_'
        . $pay_account
        . '_'
        . $FORM->{SERVICE_ID}
        . '_'
        . $FORM->{PAY_ID}
        . '_'
        . $FORM->{PAY_AMOUNT}
        . '_'
        . $self->{conf}{"PAYSYS_" . $CUSTOM_NAME . "_SECRET"});
    }
    #    $md5->add($FORM{ACT} . '_' . $FORM{PAY_ACCOUNT} . '_' . $FORM{PAY_ID} . '_' . $conf{"PAYSYS_" . $CUSTOM_NAME . "_SECRET"});
  }

  my $hash = uc($md5->hexdigest());

  if ($hash ne uc($FORM->{SIGN})) {
    $status = - 101;
  }
  elsif($act == 1){
    my ($result_code, $list) = main::paysys_check_user({
      CHECK_FIELD => $CHECK_FIELD,
      USER_ID     => $FORM->{PAY_ACCOUNT} || '-',
      DEBUG       => $self->{DEBUG},
      MAIN_GID    => $FORM->{MAIN_GID}
    });
    $status = ($axbills2_24ns{$result_code}) ? $axbills2_24ns{$result_code} : 0;

    if ($status == 0) {

      #Get tariff
      require Internet;
      Internet->import();
      my $Internet = Internet->new($self->{db}, $self->{admin}, $self->{conf});
      my $user_tarif_info = $Internet->info($list->{uid});

      my $abonplata = $user_tarif_info->{MONTH_ABON} || 0;
      $list->{fio} =~ s/\'/_/g;
      $list->{fio} = ($self->{conf}{dbcharset} eq 'utf8') ? $list->{fio} : AXbills::Base::convert($list->{fio}, { win2utf8 => 1 });

      my $min_amount = $self->{conf}{"PAYSYS_" . $CUSTOM_NAME . "_MIN_AMOUNT"} || 0.01;
      my $max_amount = $self->{conf}{"PAYSYS_" . $CUSTOM_NAME . "_MAX_AMOUNT"} || 20000;
      my $deposit = sprintf("%.2f", $list->{deposit});

      if ($FORM->{test} && $FORM->{test} == 1) {
        return qq{<?xml version="1.0" encoding="UTF-8"?><pay-response>
        <balance>$deposit</balance><name>$list->{login}  $list->{fio}</name>
        <account>$FORM->{PAY_ACCOUNT}</account>
        <service_id>$FORM->{SERVICE_ID}</service_id>
        <abonplata>$abonplata</abonplata>
        <min_amount>$min_amount</min_amount>
        <max_amount>$max_amount</max_amount>
        <status_code>21</status_code>
        <parameters>$list->{gid}</parameters>
        <time_stamp>$EURO_DATE</time_stamp>
        </pay-response>};
      }

      _24_non_stop_result(
        qq {<?xml version="1.0" encoding="UTF-8" ?>
<pay-response>
<balance>$deposit</balance>
<name>$list->{login}  $list->{fio}</name>
<account>$FORM->{PAY_ACCOUNT}</account>
<service_id>$FORM->{SERVICE_ID}</service_id>
<abonplata>$abonplata</abonplata>
<min_amount>$min_amount</min_amount>
<max_amount>$max_amount</max_amount>
<status_code>21</status_code>
<parameters>$list->{gid}</parameters>
<time_stamp>$EURO_DATE</time_stamp>
</pay-response>
},
      );
      return 0;
    }
  }
  elsif($act == 4){
    $status = 0;
    my ($status_code, $payments_id) = main::paysys_pay({
      PAYMENT_SYSTEM    => $PAYSYSTEM_SHORT_NAME,
      PAYMENT_SYSTEM_ID => $CUSTOM_ID,
      CHECK_FIELD       => $CHECK_FIELD,
      USER_ID           => $FORM->{PAY_ACCOUNT},
      SUM               => $FORM->{PAY_AMOUNT},
      EXT_ID            => $FORM->{PAY_ID},#$FORM->{RECEIPT_NUM},
      DATA              => $FORM,
      #DATE              => "$DATE $TIME",
      CURRENCY_ISO      => $self->{conf}{"PAYSYS_" . $CUSTOM_NAME . "_CURRENCY"} || undef,
      MK_LOG            => 1,
      PAYMENT_ID        => 1,
      DEBUG             => $self->{DEBUG}
    });

    $status = ($axbills2_24ns{$status_code}) ? $axbills2_24ns{$status_code} : 0;

    if ($status == 0) {
      my ($result_code, $list) = main::paysys_check_user({
        CHECK_FIELD => $CHECK_FIELD,
        USER_ID     => $FORM->{PAY_ACCOUNT},
        DEBUG       => $self->{DEBUG}
      });

      $status = ($axbills2_24ns{$result_code}) ? $axbills2_24ns{$result_code} : 0;
      my $gid = '';
      if ($status == 0) {
        $gid = $list->{gid};
      }

      if ($FORM->{test} && $FORM->{test} == 1) {
        return qq{<?xml version="1.0" encoding="UTF-8" ?>
          <pay-response>
          <pay_id>$FORM->{PAY_ID}</pay_id>
          <service_id>$FORM->{SERVICE_ID}</service_id>
          <amount>$FORM->{PAY_AMOUNT}</amount>
          <status_code>22</status_code>
          <description></description>
          <parameters>$gid</parameters>
          <time_stamp>$EURO_DATE</time_stamp>
          </pay-response>};
      }

      _24_non_stop_result(qq {<?xml version="1.0" encoding="UTF-8" ?>
<pay-response>
<pay_id>$FORM->{PAY_ID}</pay_id>
<service_id>$FORM->{SERVICE_ID}</service_id>
<amount>$FORM->{PAY_AMOUNT}</amount>
<status_code>22</status_code>
<description></description>
<parameters>$gid</parameters>
<time_stamp>$EURO_DATE</time_stamp>
</pay-response>
},
      );
      return 0;
    }
  }
  elsif($act == 7){
    use Paysys;
    my $Paysys = Paysys->new($self->{db}, $self->{admin}, $self->{conf});
    my $list = $Paysys->list({
      INFO      => "*$FORM->{PAY_ID}*",
      SUM       => '_SHOW',
      GID       => '_SHOW',
      COLS_NAME => 1
    });

    if ($Paysys->{errno}) {
      $status = - 101;
    }
    elsif ($Paysys->{TOTAL} < 1) {
      $status = - 10;
    }
    elsif ($Paysys->{TOTAL} > 0) {
      $list->[0]->{datetime} =~ /(\d+)\-(\d+)\-(\d+) (\d+\:\d+\:\d+)/;
      my $operation_date = "$3.$2.$1 $4";
      if ($FORM->{test} && $FORM->{test} == 1) {
        return qq {<?xml version="1.0" encoding="UTF-8" ?>
          <pay-response>
          <status_code>11</status_code>
          <time_stamp>$EURO_DATE</time_stamp>
          <transaction>
            <pay_id>$FORM->{PAY_ID}</pay_id >
            <amount>$list->[0]->{sum}</amount>
            <service_id>$FORM->{SERVICE_ID}</service_id>
            <status>111</status>
            <parameters>$list->[0]->{gid}</parameters>
          <time_stamp>$operation_date</time_stamp>
          </transaction>
          </pay-response>
          };
      }
      _24_non_stop_result(
        qq {<?xml version="1.0" encoding="UTF-8" ?>
<pay-response>
<status_code>11</status_code>
<time_stamp>$EURO_DATE</time_stamp>
<transaction>
  <pay_id>$FORM->{PAY_ID}</pay_id >
  <amount>$list->[0]->{sum}</amount>
  <service_id>$FORM->{SERVICE_ID}</service_id>
  <status>111</status>
  <parameters>$list->[0]->{gid}</parameters>
<time_stamp>$operation_date</time_stamp>
</transaction>
</pay-response>
});

        return 0;
    }
  }

  if ($FORM->{test} && $FORM->{test} == 1) {
    return qq{<?xml version="1.0" encoding="UTF-8" ?>
<pay-response>
<status_code>$status</status_code>
<time_stamp>$hash $EURO_DATE</time_stamp>
</pay-response>};
  }

  _24_non_stop_result(qq {<?xml version="1.0" encoding="UTF-8" ?>
<pay-response>
<status_code>$status</status_code>
<time_stamp>$hash $EURO_DATE</time_stamp>
</pay-response> });
}

#**********************************************************
=head2 _24_non_stop_result($content, $attr) - Show result

=cut
#**********************************************************
sub _24_non_stop_result {
  my ($content, $attr) = @_;

  print $content;

  main::mk_log($content, { PAYSYS_ID => "$CUSTOM_ID/$CUSTOM_NAME responce" });
}

#**********************************************************
=head2 ()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub conf_gid_split {
  my $self = shift;
  my ($gid) = @_;

  if ($self->{conf}{"PAYSYS_" . $CUSTOM_NAME . "_ACCOUNT_KEY_".$gid}) {
    $self->{conf}{"PAYSYS_" . $CUSTOM_NAME . "_ACCOUNT_KEY"}=$self->{conf}{"PAYSYS_" . $CUSTOM_NAME . "_ACCOUNT_KEY_".$gid};
  }

  if ($self->{conf}{"PAYSYS_" . $CUSTOM_NAME . "_SECRET_".$gid}) {
    $self->{conf}{"PAYSYS_" . $CUSTOM_NAME . "_SECRET"}=$self->{conf}{"PAYSYS_" . $CUSTOM_NAME . "_SECRET_".$gid};
  }

  if ($self->{conf}{"PAYSYS_" . $CUSTOM_NAME . "_SERVICE_ID_".$gid}) {
    $self->{conf}{"PAYSYS_" . $CUSTOM_NAME . "_SERVICE_ID"}=$self->{conf}{"PAYSYS_" . $CUSTOM_NAME . "_SERVICE_ID_".$gid};
  }

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

  if(!$user->{$self->{conf}{"PAYSYS_" . $CUSTOM_NAME . "_ACCOUNT_KEY"}}){
    $user->pi();
  }
  my $link = $self->{conf}{"PAYSYS_" . $CUSTOM_NAME . "_FAST_PAY"} . "&acc=" . ($user->{$self->{conf}{"PAYSYS_" . $CUSTOM_NAME . "_ACCOUNT_KEY"}}
    || $attr->{$self->{conf}{"PAYSYS_" . $CUSTOM_NAME . "_ACCOUNT_KEY"}}) . "&amount=" . ($attr->{SUM} || 0);

  return $html->tpl_show(main::_include('paysys_24non_fastpay', 'Paysys'), {LINK => $link}, { OUTPUT2RETURN => 0 });
}

1;