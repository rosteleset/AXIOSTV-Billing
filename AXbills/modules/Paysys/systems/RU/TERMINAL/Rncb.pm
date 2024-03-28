=head1 Rncb
  New module for Rncb

  Documentaion:

  Date: 08.04.2019

  Version: 7.00
=cut

use strict;
use warnings;

use AXbills::Base qw(_bp load_pmodule encode_base64);
use AXbills::Misc qw();
use AXbills::Fetcher qw(web_request);
require Paysys::Paysys_Base;


package Paysys::systems::Rncb;
our $PAYSYSTEM_NAME = 'Rncb';
our $PAYSYSTEM_SHORT_NAME = 'Rncb';
our $PAYSYSTEM_ID = 123;

our $PAYSYSTEM_VERSION = '7.00';

our %PAYSYSTEM_CONF = (
  PAYSYS_RNCB_ACCOUNT_KEY => '',
);

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

  my ($db, $admin, $CONF) = @_;

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $CONF,
    DEBUG => $CONF->{PAYSYS_DEBUG} || 0,
  };

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
=head2 process()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub proccess {
  my $self = shift;
  my ($FORM) = @_;

  if($self->{debug} > 1){
    print "Content-Type: text/plain\n\n";
  }
  else{
    print "Content-Type: text/xml\n\n";
  }

  my $CHECK_FIELD       = $self->{conf}{PAYSYS_RNCB_ACCOUNT_KEY} || 'UID';

  # ?QueryType=check&account=1
  if($FORM->{QueryType} && $FORM->{QueryType} eq 'check'){
    my $account = $FORM->{Account};

    my ($result, $list) = main::paysys_check_user({
      CHECK_FIELD => $CHECK_FIELD,
      USER_ID     => $account
    });

    if($result == 0){
      print qq{<?xml version="1.0" encoding="UTF-8"?>
        <CHECKRESPONSE>
        <BALANCE>$list->{DEPOSIT}</BALANCE>
        <FIO>$list->{FIO}</FIO>
        <ADDRESS>$list->{ADDRESS_FULL}</ADDRESS>
        <ERROR>0</ERROR>
        <COMMENTS>Success</COMMENTS>
      </CHECKRESPONSE>
      };
    }
    else{
      print qq{<?xml version="1.0" encoding="UTF-8"?>
        <CHECKRESPONSE>
        <COMMENTS>Wrong client identifier</COMMENTS>
        <ERROR>1</ERROR>
        </CHECKRESPONSE>
      };
    }
  }
  # QueryType=check&account=1&summa=1.00&payment_id=12345678
  elsif($FORM->{QueryType} && $FORM->{QueryType} eq 'pay'){
    my ($pay_result, $pay_id) = main::paysys_pay({
      PAYMENT_SYSTEM    => $PAYSYSTEM_SHORT_NAME,
      PAYMENT_SYSTEM_ID => $PAYSYSTEM_ID,
      CHECK_FIELD       => $CHECK_FIELD,
      USER_ID           => $FORM->{Account},
      SUM               => $FORM->{Summa},
      EXT_ID            => $FORM->{Payment_id},
      DATA              => $FORM,
      PAYMENT_ID        => 1,
      MK_LOG            => 1,
      DEBUG             => $self->{debug},
      USER_INFO         => 'Additional info',
    });

    if($pay_result == 0){
      print qq{<?xml version="1.0" encoding="UTF-8"?>
        <PAYRESPONSE>
        <ERROR>$pay_result</ERROR>
        <OUT_PAYMENT_ID>$pay_id</OUT_PAYMENT_ID>
        <COMMENTS>Success</COMMENTS>
        </PAYRESPONSE>
      };
    }
    elsif($pay_result == 13 || $pay_result == 3){
      print qq{<?xml version="1.0" encoding="UTF-8"?>
        <PAYRESPONSE>
        <ERROR>10</ERROR>
        <OUT_PAYMENT_ID>$pay_id</OUT_PAYMENT_ID>
        <COMMENTS>Double payment</COMMENTS>
        </PAYRESPONSE>
      };
    }
    else{
      print qq{<?xml version="1.0" encoding="UTF-8"?>
        <PAYRESPONSE>
        <ERROR>$pay_result</ERROR>
        <COMMENTS>Another error</COMMENTS>
        </PAYRESPONSE>
      };
    }
  }
  # ?QueryType=balance&DateFrom=2017070000000&DateTo=20170709000000
  elsif($FORM->{QueryType} eq 'balance'){
    #    my $to_date   = $FORM{DateTo};
    #    my $from_date = $FORM{DateFrom};

    my $to_date   = $FORM->{Date_to};
    my $from_date = $FORM->{Date_from};

    $to_date   =~ s/(\d{4})(\d{2})(\d{2})\d+/$1\-$2\-$3/g;
    $from_date =~ s/(\d{4})(\d{2})(\d{2})\d+/$1\-$2\-$3/g;
    $to_date = _add_days($to_date, -1);
    use Paysys;
    my $Paysys = Paysys->new($self->{db}, $self->{admin}, $self->{conf});
    my $payments_list = $Paysys->list({
      FROM_DATE => $from_date,
      TO_DATE   => $to_date,
      PAYMENT_SYSTEM => $PAYSYSTEM_ID,
      COLS_NAME => 1,
      PAGE_ROWS => 99999,
    });

    my $payments_rows = '';

    foreach my $payment_row (@$payments_list){
      $payments_rows .= "<PAYMENT_ROW>";

      my ($payment_id)     = $payment_row->{transaction_id} =~ /(\d+)/;
      my $out_payment_id = $payment_row->{id};
      my $account        = $payment_row->{uid};
      my $summa          = $payment_row->{sum};
      my $exec_date      = $payment_row->{datetime};

      $payments_rows .= "$payment_id;$out_payment_id;$account;$summa;$exec_date";

      $payments_rows .= "</PAYMENT_ROW>\n";
    }


    print qq{<?xml version="1.0" encoding="UTF-8"?>
    <REVISIONRESPONSE>
    <ERROR></ERROR>
    <FULL_SUMMA>$Paysys->{SUM_COMPLETE}</FULL_SUMMA>
    <NUMBER_OF_PAYMENTS>$Paysys->{TOTAL_COMPLETE}</NUMBER_OF_PAYMENTS>
    <PAYMENTS>
$payments_rows
    </PAYMENTS>
    </REVISIONRESPONSE>
    }
  }

  return 1;

}

#**********************************************************
=head2 _add_days($date, $days)

=cut
#**********************************************************
sub _add_days {
  my ($date, $d_days) = @_;
  my ($year, $month, $day) = split '-', $date;
  my @lastday = (31,28,31,30,31,30,31,31,30,31,30,31);

  $lastday[1] = ($year % 4) ? 28 : 29;
  $day += $d_days;

  while ($day > $lastday[$month-1]) {
    $day -= $lastday[$month-1];
    $month++;
    if ($month > 12) {
      $year++;
      $month = 1;
      $lastday[1] = ($year % 4) ? 28 : 29;
    }
  }

  while ($day < 1) {
    $month--;
    if ($month == 0) {
      $year--;
      $month = 12;
      $lastday[1] = ($year % 4) ? 28 : 29;
    }
    $day += $lastday[$month-1];
  }


  return sprintf('%04d-%02d-%02d', $year, $month, $day);
}


1;