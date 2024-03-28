#!/usr/bin/perl -w

=head1 NAME

  Oschadbank

  Module for Oschadbank payment system
  Interface for Oschadbank Paysystem

=head1 VERSION

  VERSION: 1.03
  REVISION: 20190318

=cut

use strict;

our %PAYSYSTEM_CONF = (
  'PAYSYS_OSCHADBANK_SECRET_KEY'  => '',
  'PAYSYS_OSCHADBANK_CHECK_FIELD' => 'CONTRACT_ID'
);
our $PAYSYSTEM_IP      = '';
our $PAYSYSTEM_VERSION = 1.03;
our $PAYSYSTEM_NAME    = 'Oschadbank';

use AXbills::Base qw(mk_unique_value load_pmodule);

#**********************************************************
=head2 oschadbank_check_payment($attr)

  Arguments:


  Returns:

=cut
#**********************************************************
sub oschadbank_check_payment {
  #my ($attr) = @_;
  print "Content-Type: text/plain\n\n";

  load_pmodule('Digest::MD5');
  my $md5 = Digest::MD5->new();

  my $payment_system    = 'Oschad';
  my $payment_system_id = '114';
  my $paysys_status     = '';
  my $CHECK_FIELD       = $conf{PAYSYS_OSCHADBANK_CHECK_FIELD} || 'CONTRACT_ID';

  if ($FORM{num} && $FORM{sec} && !$FORM{trid}) {
    $md5->add("$FORM{num}|$conf{PAYSYS_OSCHADBANK_SECRET_KEY}");
    my $signature = $md5->hexdigest();

    if ($signature eq $FORM{sec}) {
      my $list = $users->list(
        {
          $CHECK_FIELD => $FORM{num},
          DEPOSIT      => '_SHOW',
          FIO          => '_SHOW',
          ADDRESS_FULL => '_SHOW',
          COLS_NAME    => 1
        }
      );
      if ($#{$list} < 0) {
        print abon_answer();    # user doesnt exist
        return 0;
      }

      my $uid = $list->[0]->{uid};
      use Dv;
      my $Dv         = Dv->new($db, $admin, \%conf);
      my $d_info     = $Dv->info($uid);
      my $month_abon = 0;
      if ($d_info->{STATUS} == 5) {
        $month_abon = $d_info->{MONTH_ABON};
      }
      my $fio          = $list->[0]->{fio};
      my $address_full = $list->[0]->{address_full};
      my $deposit      = sprintf("%.2f", $list->[0]->{deposit});

      print abon_answer(
        {
          FIND         => 'true',
          FIO          => $fio,
          ADDRESS_FULL => $address_full,
          DEPOSIT      => $deposit,
          MONTH_ABON   => $month_abon
        }
      );
    }
    else { print "Signature fail - $signature"; }
  }
  elsif ($FORM{num} && $FORM{sec} && $FORM{trid}) {
    $md5->add("$FORM{trid}|$FORM{num}|$FORM{amount}|$conf{PAYSYS_OSCHADBANK_SECRET_KEY}");
    my $signature = $md5->hexdigest();

    # check signatures
    if ($FORM{sec} eq $signature) {
      my $list = $users->list(
        {
          $CHECK_FIELD => $FORM{num},
          COLS_NAME    => 1
        }
      );

      if ($#{$list} < 0) {
        print payment_answer({ CODE => 2 });    # user does not exist
        return 0;
      }

      $paysys_status = paysys_pay(
        {
          PAYMENT_SYSTEM    => $payment_system,
          PAYMENT_SYSTEM_ID => $payment_system_id,
          CHECK_FIELD       => 'UID',
          USER_ID           => $list->[0]->{uid},
          SUM               => $FORM{amount},
          EXT_ID            => mk_unique_value(8, { SYMBOLS => '1234567890' }),
          DATA              => \%FORM,
          DATE              => "$DATE $TIME",
          PAYMENT_DESCRIBE  => $FORM{payment_description} ? $FORM{payment_description} : "TRID: $FORM{trid}",
          MK_LOG            => 1,
          DEBUG             => 1
        }
      );

      if ($paysys_status == 0) {
        print payment_answer({ CODE => 1 });
      }
    }
    else { print "Signature fail - $signature"; }
  }

  return 1;
}

#**********************************************************
=head2 abon_answer($attr)

  Arguments:


  Returns:

=cut
#**********************************************************
sub abon_answer {
  my ($attr) = @_;

  my $find    = $attr->{FIND}    ? $attr->{FIND}    : 'false';
  my $deposit = $attr->{DEPOSIT} ? $attr->{DEPOSIT} : 0;
  my $wait_pay     = $attr->{DEPOSIT} < 0  ? $attr->{DEPOSIT} * (-1) + $attr->{MONTH_ABON} : 0;
  my $fio          = $attr->{FIO}          ? $attr->{FIO}                                  : '';
  my $address_full = $attr->{ADDRESS_FULL} ? $attr->{ADDRESS_FULL}                         : '';

  my $answer = qq{<?xml version="1.0" encoding="UTF-8"?>
<packet>
  <boo_abonent>$find</boo_abonent>
  <name_addr>$address_full</name_addr>
  <name_abonent>$fio</name_abonent>
  <saldo>$deposit</saldo>
  <wait_pay>$wait_pay</wait_pay>
</packet>
  };

  return $answer;
}

#**********************************************************
=head2 payment_answer($attr)

return $answer
  Arguments:


  Returns:

=cut
#**********************************************************
sub payment_answer {
  my ($attr) = @_;
  my $code   = $attr->{CODE};
  my $answer = qq{<?xml version="1.0" encoding="UTF-8"?>
<packet>
$code
</packet>
  };

  return $answer;
}

1;