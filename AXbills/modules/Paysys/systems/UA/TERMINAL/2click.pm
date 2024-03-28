package Paysys::systems::2click;
=head1 NAME

  2click

=head2 FILENAME

  2click.pm

=head2 VERSION

  VERSION: 0.03
  CREATE DATE: 07.02.2020
  REVISION: 08.07.2020

=head2 Documentation

  Documentaion: http://axbills.net.ua:8090/pages/viewpage.action?pageId=9601151&preview=/9601151/46334182/2click_protocol_for_providers_service%202.30.pdf

=cut

use strict;
use warnings FATAL => 'all';

use AXbills::Base qw(_bp date_format convert);
use AXbills::Misc qw(load_module);
require Paysys::Paysys_Base;
use AXbills::Base qw(_bp );
use AXbills::Misc qw();
require Paysys::Paysys_Base;

use Paysys;

our $PAYSYSTEM_NAME       = '2click';
our $PAYSYSTEM_SHORT_NAME = '2cl';
our $PAYSYSTEM_ID         = 139;

our $PAYSYSTEM_VERSION = '0.03';

our %PAYSYSTEM_CONF = (
  PAYSYS_2CL_ACCOUNT_KEY => '',
  PAYSYS_2CL_SECRET      => '',
  PAYSYS_2CL_MIN_AMOUNT  => '',
  PAYSYS_2CL_MAX_AMOUNT  => '',
  PAYSYS_2CL_FASTPAY     => '',
  PAYSYS_2CL_COMPANY_ID  => '',
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
  $SETTINGS{ID}      = $PAYSYSTEM_ID;
  $SETTINGS{NAME}    = $PAYSYSTEM_NAME;

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
    main::mk_log($mod_return, { PAYSYS_ID => "2click" });
  }

  my $md5 = Digest::MD5->new();
  $md5->reset();

  my $act         = $FORM->{ACT};
  my $CHECK_FIELD = $self->{conf}{"PAYSYS_2CL_ACCOUNT_KEY"} || 'UID';
  my $status      = 0;
  my $PAY_DATE    = AXbills::Base::date_format("$main::DATE $main::TIME", '%d.%m.%Y %H:%M:%S');
  my $pay_account = $FORM->{PAY_ACCOUNT} || '';

  my %axbills_2cl = (
    0  => '0',    # ok
    1  => '-40',  #No customer found
    2  => '-41',  #Payments cannot be accepted for this client.
    3  => '-42',  #Payment for this amount is not possible for this client
    4  => '-100', #More than one payment with data found in the billing system Pay_id
    5  => '-101',
    6  => '-10', #Transaction not found
    7  => '-90',   #Service unavailable
  )
  ;
  if ($FORM->{SERVICE_ID}) {
    $self->conf_gid_split($FORM->{SERVICE_ID});

    if ($FORM->{ACT} == 1 || $FORM->{ACT} == 4 || $FORM->{ACT} == 7) {
      $md5->add($FORM->{ACT}
        . '_'
        . $pay_account
        . '_'
        . $FORM->{SERVICE_ID}
        . '_'
        . $FORM->{PAY_ID}
        . '_'
        . $self->{conf}{"PAYSYS_2CL_SECRET"});
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
        . $self->{conf}{"PAYSYS_2CL_SECRET"});
    }
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
    $status = ($axbills_2cl{$result_code}) ? $axbills_2cl{$result_code} : 0;

    if ($status == 0) {

      #Get tariff
      require Internet;
      Internet->import();
      my $Internet = Internet->new($self->{db}, $self->{admin}, $self->{conf});
      my $user_tarif_info = $Internet->info($list->{login});

      my $abonplata = $user_tarif_info->{MONTH_ABON} || 0;
      $list->{fio} =~ s/\'/_/g;
      $list->{fio} = ($self->{conf}{dbcharset} eq 'utf8') ? $list->{fio} : AXbills::Base::convert($list->{fio}, { win2utf8 => 1 });

      my $min_amount = $self->{conf}{"PAYSYS_2CL_MIN_AMOUNT"} || 0.01;
      my $max_amount = $self->{conf}{"PAYSYS_2CL_MAX_AMOUNT"} || 20000;
      my $deposit = sprintf("%.2f", $list->{deposit});

      if ($FORM->{test} && $FORM->{test} == 1) {
        if($self->{conf}{"PAYSYS_2CL_COMPANY_ID"}){
          return qq{<?xml version="1.0" encoding="UTF-8"?><pay-response>
        <balance>$deposit</balance><name>$list->{login}  $list->{fio}</name>
        <account>$FORM->{PAY_ACCOUNT}</account>
        <service_id>$FORM->{SERVICE_ID}</service_id>
        <abonplata>$abonplata</abonplata>
        <min_amount>$min_amount</min_amount>
        <max_amount>$max_amount</max_amount>
        <status_code>21</status_code>
        <parameters>$self->{conf}{"PAYSYS_2CL_COMPANY_ID"}</parameters>
        <time_stamp>$PAY_DATE</time_stamp>
        </pay-response>};
        }

        return qq{<?xml version="1.0" encoding="UTF-8"?><pay-response>
        <balance>$deposit</balance><name>$list->{login}  $list->{fio}</name>
        <account>$FORM->{PAY_ACCOUNT}</account>
        <service_id>$FORM->{SERVICE_ID}</service_id>
        <abonplata>$abonplata</abonplata>
        <min_amount>$min_amount</min_amount>
        <max_amount>$max_amount</max_amount>
        <status_code>21</status_code>
        <parameters>$list->{gid}</parameters>
        <time_stamp>$PAY_DATE</time_stamp>
        </pay-response>};
      }

      if($self->{conf}{"PAYSYS_2CL_COMPANY_ID"}){
        _2click_result(
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
<parameters>$self->{conf}{"PAYSYS_2CL_COMPANY_ID"}</parameters>
<time_stamp>$PAY_DATE</time_stamp>
</pay-response>
},
        );
        return 0;
      }

      _2click_result(
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
<time_stamp>$PAY_DATE</time_stamp>
</pay-response>
},
      );
      return 0;
    }
  }
    elsif ($act == 4) {
    $status = 0;
      my ($status_code, $payments_ids) = main::paysys_pay(
          {
              PAYMENT_SYSTEM    => $PAYSYSTEM_SHORT_NAME,
              PAYMENT_SYSTEM_ID => $PAYSYSTEM_ID,
              CHECK_FIELD       => $CHECK_FIELD,
              USER_ID           => $FORM->{PAY_ACCOUNT},
              SUM               => $FORM->{PAY_AMOUNT},
              EXT_ID            => $FORM->{PAY_ID},
              DATA              => $FORM,
              MK_LOG            => 1,
              PAYMENT_ID        => 1,
              DEBUG             => $self->{DEBUG}
          }
      );

      $status = ($axbills_2cl{$status_code}) ? $axbills_2cl{$status_code} : 0;

      if ($status == 0) {
        my ($result_code, $list) = main::paysys_check_user(
            {
                CHECK_FIELD => $CHECK_FIELD,
                USER_ID     => $FORM->{PAY_ACCOUNT},
                DEBUG       => $self->{DEBUG}
            }
        );

        $status = ($axbills_2cl{$result_code}) ? $axbills_2cl{$result_code} : 0;
        my $gid = '';
        if ($status == 0) {
          $gid = $list->{gid};
        }

        if ($FORM->{test} && $FORM->{test} == 1) {
          if($self->{conf}{"PAYSYS_2CL_COMPANY_ID"}){
            return qq{<?xml version="1.0" encoding="UTF-8" ?>
          <pay-response>
          <pay_id>$FORM->{PAY_ID}</pay_id>
          <service_id>$FORM->{SERVICE_ID}</service_id>
          <amount>$FORM->{PAY_AMOUNT}</amount>
          <status_code>22</status_code>
          <description></description>
          <parameters>$self->{conf}{"PAYSYS_2CL_COMPANY_ID"}</parameters>
          <time_stamp>$PAY_DATE</time_stamp>
          </pay-response>};
          }
          return qq{<?xml version="1.0" encoding="UTF-8" ?>
          <pay-response>
          <pay_id>$FORM->{PAY_ID}</pay_id>
          <service_id>$FORM->{SERVICE_ID}</service_id>
          <amount>$FORM->{PAY_AMOUNT}</amount>
          <status_code>22</status_code>
          <description></description>
          <parameters>$gid</parameters>
          <time_stamp>$PAY_DATE</time_stamp>
          </pay-response>};
        }

        if($self->{conf}{"PAYSYS_2CL_COMPANY_ID"}){
          _2click_result(
            qq {<?xml version="1.0" encoding="UTF-8" ?>
<pay-response>
<pay_id>$FORM->{PAY_ID}</pay_id>
<service_id>$FORM->{SERVICE_ID}</service_id>
<amount>$FORM->{PAY_AMOUNT}</amount>
<status_code>22</status_code>
<description></description>
<parameters>$self->{conf}{"PAYSYS_2CL_COMPANY_ID"}</parameters>
<time_stamp>$PAY_DATE</time_stamp>
</pay-response>
            },
          );
          return 0;
        }
        _2click_result(
            qq{<?xml version="1.0" encoding="UTF-8" ?>
<pay-response>
<pay_id>$FORM->{PAY_ID}</pay_id>
<service_id>$FORM->{SERVICE_ID}</service_id>
<amount>$FORM->{PAY_AMOUNT}</amount>
<status_code>22</status_code>
<description></description>
<parameters>$gid</parameters>
<time_stamp>$PAY_DATE</time_stamp>
</pay-response>
},
        );
        return 0;
      }
    }
    elsif ($act == 7) {
      my $Paysys = Paysys->new($self->{db}, $self->{admin}, $self->{conf});
      my $list = $Paysys->list(
          {
              INFO      => "*$FORM->{PAY_ID}*",
              SUM       => '_SHOW',
              GID       => '_SHOW',
              COLS_NAME => 1
          }
      );

      if ($Paysys->{errno}) {
        $status = -101;
      }
      elsif ($Paysys->{TOTAL} < 1) {
        $status = -10;
      }
      elsif ($Paysys->{TOTAL} > 0) {
        $list->[0]->{datetime} =~ /(\d+)\-(\d+)\-(\d+) (\d+\:\d+\:\d+)/;
        my $operation_date = "$3.$2.$1 $4";
        if ($FORM->{test} && $FORM->{test} == 1) {
          if($self->{conf}{"PAYSYS_2CL_COMPANY_ID"}){
            return qq{<?xml version="1.0" encoding="UTF-8" ?>
          <pay-response>
          <status_code>11</status_code>
          <time_stamp>$PAY_DATE</time_stamp>
          <transaction>
            <pay_id>$FORM->{PAY_ID}</pay_id >
            <amount>$list->[0]->{sum}</amount>
            <service_id>$FORM->{SERVICE_ID}</service_id>
            <status>111</status>
            <parameters>$self->{conf}{"PAYSYS_2CL_COMPANY_ID"}</parameters>
          <time_stamp>$operation_date</time_stamp>
          </transaction>
          </pay-response>
          };
          }
          return qq{<?xml version="1.0" encoding="UTF-8" ?>
          <pay-response>
          <status_code>11</status_code>
          <time_stamp>$PAY_DATE</time_stamp>
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

        if($self->{conf}{"PAYSYS_2CL_COMPANY_ID"}){
          _2click_result(
            qq{<?xml version="1.0" encoding="UTF-8" ?>
<pay-response>
<status_code>11</status_code>
<time_stamp>$PAY_DATE</time_stamp>
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
        _2click_result(
            qq{<?xml version="1.0" encoding="UTF-8" ?>
<pay-response>
<status_code>11</status_code>
<time_stamp>$PAY_DATE</time_stamp>
<transaction>
<pay_id>$FORM->{PAY_ID}</pay_id >
<amount>$list->[0]->{sum}</amount>
<service_id>$FORM->{SERVICE_ID}</service_id>
<status>111</status>
<parameters>$self->{conf}{"PAYSYS_2CL_COMPANY_ID"}</parameters>
<time_stamp>$operation_date</time_stamp>
</transaction>
</pay-response>
}
        );

        return 0;
      }
    }

    if ($FORM->{test} && $FORM->{test} == 1) {
      return qq{<?xml version="1.0" encoding="UTF-8" ?>
<pay-response>
<status_code>$status</status_code>
<time_stamp>$hash $PAY_DATE</time_stamp>
</pay-response>};
    }

    _2click_result(
        qq{<?xml version="1.0" encoding="UTF-8" ?>
<pay-response>
<status_code>$status</status_code>
<time_stamp>$hash $PAY_DATE</time_stamp>
</pay-response> }
    );
  }

#**********************************************************
=head2 _2click_result($content, $attr) - Show result

=cut
#**********************************************************
sub _2click_result {
  my ($content, $attr) = @_;

  print $content;

  main::mk_log($content, { PAYSYS_ID => "$PAYSYSTEM_ID/$PAYSYSTEM_NAME responce" });
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

  foreach my $param (keys %PAYSYSTEM_CONF) {
    if ($self->{conf}{ $param . '_' . $gid }) {
      $self->{conf}{$param} = $self->{conf}{ $param . '_' . $gid };
    }
  }
}

#**********************************************************
=head2 user_portal($user, $attr)

  Arguments:
     $user,
     $attr

  Returns:

=cut
#**********************************************************
sub user_portal {
  my $self = shift;
  my ($user, $attr) = @_;

  if(!$user->{$self->{conf}{PAYSYS_2CL_ACCOUNT_KEY}}){
    $user->pi();
  }
  my $link = $self->{conf}{PAYSYS_2CL_FASTPAY} . "account=" . ($user->{$self->{conf}{PAYSYS_2CL_ACCOUNT_KEY}} ) . "&amount=" . ($attr->{SUM} || 0);

  return $html->tpl_show(main::_include('paysys_2click_fastpay', 'Paysys'), {LINK => $link}, { OUTPUT2RETURN => 0 });
}

1;