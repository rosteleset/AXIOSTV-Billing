#***********************************************************
=head1 NAME

  PrivatBank 24

  http://api.privatbank.ua/
  Получение выписок
  Форма пополнения

=head1 VERSION

  VERSION: 1.04
  UPDATED: 20180124

=cut
#***********************************************************


use strict;
use warnings;
use AXbills::Base qw(sendmail load_pmodule);
use AXbills::Fetcher qw(web_request);

our(
  %conf,
  $Paysys,
  %lang,
  $payments,
  %PAYSYS_PAYMENTS_METHODS
);

our %PAYSYSTEM_CONF = (
  'PAYSYS_P24_MERCHANT_ID'   => '',
  'PAYSYS_P24_MERCHANT_PASS' => '',
  'PAYSYS_P24_MERCHANT_YUR'  => ''
);

our $PAYSYSTEM_IP = '';
our $PAYSYSTEM_VERSION = 1.04;
our $PAYSYSTEM_NAME = '';

my $merchant_id   = $conf{PAYSYS_P24_MERCHANT_ID} || '';
my $merchant_pass = $conf{PAYSYS_P24_MERCHANT_PASS} || '';
my $main_url      = 'https://api.privatbank.ua/p24api';
my $debug         = $conf{PAYSYS_DEBUG} || 0;
my $operation_error = 0;

if ($debug > 1) {
  print "Content-Type: text/plain\n\n";
}

#**********************************************************
=head2 p24_check_payment($attr)

  Request:

 amt=<сумма>
 &ccy=<валюта UAH|USD|EUR>
 &details=<информация о товаре/услуге>
 &ext_details=<дополнительная информация о товаре/услуге>
 &pay_way=privat24
 &order=<id платежа в системе мерчанта>
 &merchant=<id мерчанта, принимающего платёж>
 &state=<состояние платежа: ok|fail>
 &date=<дата отправки платежа в проводку>
 &ref=<id платежа в системе банка>
 &sender_phone=<номер телефона плательщика>

 amt=<сумма>&ccy=<валюта UAH|USD|EUR>&details=<информация о товаре/услуге>&ext_details=<дополнительная информация о товаре/услуге>&pay_way=privat24&order=<id платежа в системе мерчанта>&merchant=<id мерчанта, принимающего платёж>&state=<состояние платежа: ok|fail>&date=<дата отправки платежа в проводку>&ref=<id платежа в системе банка>&sender_phone=<номер телефона плательщика>
 amt=10&ccy=USD&details=test&ext_details=test2&pay_way=privat24&order=1234&merchant=111&state=ok&date=2005-01-01&ref=54321&sender_phone=0505738096


=cut
#**********************************************************
sub p24_check_payment {

  my $payment_system = 'P24';
  my $payment_system_id = 54;

  if ($debug) {
    my $ext_info;
    foreach my $k (sort keys %FORM) {
      if ($k eq '__BUFFER') {
        next;
      }

      $ext_info .= "$k, $FORM{$k}\n";
    }

    mk_log($ext_info, { PAYSYS_ID => $payment_system, REQUEST => 'Request' });
  }

  #Get clean variables
  my $buffer = $FORM{'payment'};
  my @pairs = split(/&/, $buffer);

  foreach my $pair (@pairs) {
    my ($side, $value) = split(/=/, $pair);
    if (defined($value)) {
      $value =~ tr/+/ /;
      $value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
      $value =~ s/<!--(.|\n)*-->//g;
      $value =~ s/<([^>]|\n)*>//g;

      #Check quotes
      $value =~ s/"/\\"/g;
      $value =~ s/'/\\'/g;
    }
    else {
      $value = '';
    }

    $FORM{$side} = $value;
  }

  $FORM{__BUFFER} = '' if (!$FORM{__BUFFER});

  my $status = 0;

  if ($debug > 7) {
    $Paysys->{debug} = 1;
  }

  my $sum          = $FORM{amt} || 0;
  my $describe     = $FORM{details};
  my $ext_describe = $FORM{ext_details};
  #my $payment_state = $FORM{state};
  my $description  = q{};

  my $list = $Paysys->list(
    {
      TRANSACTION_ID => "$payment_system:$FORM{'order'}",
      STATUS         => '_SHOW',
      COLS_NAME      => 1,
      INFO           => '_SHOW',
      GID            => '_SHOW',
      SKIP_DEL_CHECK => 1
    }
  );

  if ($Paysys->{TOTAL} > 0 && $list->[0]->{status} != 2) {
    conf_gid_split({
      GID    => $list->[0]->{gid},
      PARAMS => [
        'PAYSYS_P24_COMMISSION',
        'PAYSYS_P24_MERCHANT_ID',
        'PAYSYS_P24_MERCHANT_PASS'
      ],
    });

    my $uid = $list->[0]{uid};
    if ($FORM{state} eq 'ok' || $FORM{state} eq 'test') {
      my $user = $users->info($uid);

      if ($conf{PAYSYS_P24_COMMISSION}) {
        $sum = $list->[0]->{sum};
      }
      else {
        $description .= "$lang{PAYMENTS}: $list->[0]->{sum}";
      }

      cross_modules_call(
        '_pre_payment',
        {
          USER_INFO    => $user,
          SKIP_MODULES => 'Sqlcmd',
          QUITE        => 1
        }
      );

      $payments->add(
        $user,
        {
          SUM          => $sum,
          DESCRIBE     => "$describe/$ext_describe" . (($FORM{state} eq 'test') ? ' (test)' : ''),
          METHOD       =>
            ($conf{PAYSYS_PAYMENTS_METHODS} && $PAYSYS_PAYMENTS_METHODS{$payment_system_id}) ? $payment_system_id : '2',
          EXT_ID       => "$payment_system:$FORM{order}",
          CHECK_EXT_ID => "$payment_system:$FORM{order}"
        }
      );

      #Exists
      if ($payments->{errno} && $payments->{errno} == 7) {
        $status = 8;
      }
      elsif ($payments->{errno}) {
        $status = 4;
      }
      else {
        $Paysys->change(
          {
            ID        => $list->[0]{id},
            PAYSYS_IP => $ENV{'REMOTE_ADDR'},
            INFO      =>
            "STATE: $FORM{state}\n ext_details: $FORM{ext_details}\n pay_way:$FORM{pay_way} merchant: $FORM{merchant}\n DATE: $FORM{date}\n REF: $FORM{ref}\n sender_phone: $FORM{sender_phone}"
            ,
            STATUS    => ($FORM{state} eq 'test') ? 12 : 2
          }
        );
      }

      if ($conf{PAYSYS_EMAIL_NOTICE}) {
        my $message = "\n" . "================================" . "System: Privat Bank - Privat24\n" . "================================" . "DATE: $DATE $TIME\n" . "LOGIN: $user->{LOGIN} [$uid]\n" . "\n" . "\n" . "ID: $FORM{order}\n" . "SUM: $sum\n";

        sendmail("$conf{ADMIN_MAIL}", "$conf{ADMIN_MAIL}", "Privat Bank - Privat24 Add", "$message",
          "$conf{MAIL_CHARSET}", "2 (High)");
      }

      cross_modules_call(
        '_payments_maked',
        {
          USER_INFO    => $user,
          SUM          => $sum,
          PAYMENT_ID   => $payments->{PAYMENT_ID},
          QUITE        => 1,
          SKIP_MODULES => 'Docs,Sqlcmd'
        }
      );
    }
    else {
      $Paysys->change(
        {
          ID        => $list->[0]{id},
          PAYSYS_IP => $ENV{'REMOTE_ADDR'},
          INFO      => "STATE: $FORM{state}",
          STATUS    => ($FORM{state} eq 'wait') ? 13 : 6
        }
      );
      my $message = "Paymets Failed\n" . "================================" . "System: Privat Bank - Privat24\n" . "================================" . "DATE: $DATE $TIME\n" . "LOGIN: $user->{LOGIN} [$uid]\n" . "\n" . "\n" . "ID: $FORM{order}\n" . "SUM: $sum\n";

      sendmail("$conf{ADMIN_MAIL}", "$conf{ADMIN_MAIL}", "Privat Bank - Privat24 Add - Failed", "$message",
        "$conf{MAIL_CHARSET}", "2 (High)");
      $status = 3;
    }
  }
  else {
    $status = 1;
  }

  my $home_url = '/index.cgi';
  $home_url = $ENV{SCRIPT_NAME};

  if ($list->[0]->{info} =~ /start/) {
    $home_url =~ s/paysys_check.cgi/start.cgi/;
    if ($list->[0]->{info} =~ /TP_ID,(\d+)/) {
      $FORM{TP_ID} = $1;
    }
  }
  else {
    $home_url =~ s/paysys_check.cgi/index.cgi/;
  }

  my $content = "Location: $home_url?PAYMENT_SYSTEM=54&OrderID=$FORM{order}&OPERATION_ID=$FORM{order}&TRUE=1" . "\n\n";
  print $content;

  if ($debug > 0) {
    mk_log($content, { PAYSYS_ID => $payment_system,
        REQUEST                  => 'Reply'
      });
  }

  return $status;
}

#**********************************************************
=head2 p24($attr)

  Arguments:
    $attr
      MERCHANT_ID
      MERCHANT_PASS

  Returns:
    \%request_hash

=cut
#**********************************************************
sub p24 {
  my ($attr) = @_;

  load_pmodule('XML::Simple');

  if ($attr->{MERCHANT_ID}) {
    $merchant_id = $attr->{MERCHANT_ID};
    $merchant_pass = $attr->{MERCHANT_PASS};
  }

  my $res = '';
  if ($attr->{CARD_INFO}) {
    $res = p24_get_card_info($attr->{CARD_INFO});
  }
  elsif ($attr->{HISTORY}) {
    $res = p24_get_history($attr);
  }

  my $_xml = eval {XML::Simple::XMLin($res, forcearray => 1)};

  if ($@) {
    print "Incorrect XML\n";
    print "<textarea cols=100 rows=12>$res \n\n $@</textarea>";

    open(my $fh, '>>', "paysys_xml.log") or die "Can't open file 'paysys_xml.log' $!\n";
      print $fh "----\n";
      print $fh $res;
      print $fh "\n----\n";
      print $fh $@;
      print $fh "\n----\n";
    close($fh);

    return {};
  }

  my %request_hash = ();
  while (my ($k, $v) = each %{$_xml}) {
    $request_hash{$k} = (ref $v eq 'ARRAY') ? $v->[0] : $v;
  }

  if (1) {
    $operation_error = 1;
  }

  return \%request_hash;
}

#**********************************************************
=head2 p24_get_history($attr)

=cut
#**********************************************************
sub p24_get_history {
  my ($attr) = @_;

  my ($Y, $m, $d) = split(/-/, $DATE);
  my $start_date = "01.$m.$Y";
  my $end_date = "$d.$m.$Y";

  if ($attr->{DATE_FROM} && $attr->{DATE_FROM} =~ /(\d{4})-(\d{2})-(\d{2})/) {
    $Y = $1;
    $m = $2;
    $d = $3;
    $start_date = "$d.$m.$Y";
  }

  if ($attr->{DATE_TO} && $attr->{DATE_TO} =~ /(\d{4})-(\d{2})-(\d{2})/) {
    $end_date = "$3.$2.$1";
  }

  my $data = '';

  if ($conf{PAYSYS_P24_MERCHANT_YUR}) {
    if (!$attr->{START_DATE} || $start_date eq $end_date) {
      $data = qq{<prop name="year" type="int" size="4" value="$Y" />
        <prop name="month" type="int" size="2" value="$m" />
        <prop name="day" type="int" size="2" value="$d" />};
    }
    else {
      $data = qq{<prop name="year" type="int" size="4" value="$Y" />
        <prop name="month" type="int" size="2" value="$m" />};
    }

    $data = qq{<oper>cmt</oper>
      <test>0</test>
      <wait>0</wait>
      <payment>
      $data
      </payment>};

    my $xml = '';

    if ($conf{PAYSYS_P24_TEXT_FILE} && -f $conf{PAYSYS_P24_TEXT_FILE}) {
      #debug only
      open(my $fh, '<', $conf{PAYSYS_P24_TEXT_FILE}) or print "Can't open '$conf{PAYSYS_P24_TEXT_FILE}'. $!";
      while (<$fh>) {
        $xml .= $_;
      }
      close($fh);
    }
    else {
      $xml = p24_msoap('rest_yur', $data);
    }

    if ($xml =~ s/\<(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\>/$1/) {
      return $xml;
    }

    return $xml;
  }
  else {
    $data = qq{<oper>cmt</oper>
      <test>0</test>
      <wait>0</wait>
      <payment>
      <prop name="sd" value="$start_date" />
      <prop name="ed" value="$end_date" />};

    if ($attr->{CARD_ID}) {
      $data .= qq{<prop name="card" value="$attr->{CARD_ID}" />};
    }
    $data .= qq{</payment>};

    if ($conf{PAYSYS_P24_TEXT_FILE} && -f $conf{PAYSYS_P24_TEXT_FILE}) {
      #debug only
      my $xml;
      open(my $fh, '<', $conf{PAYSYS_P24_TEXT_FILE}) or print "Can't open '$conf{PAYSYS_P24_TEXT_FILE}'. $!";
      while (<$fh>) {
        $xml .= $_;
      }
      close($fh);

      return $xml;
    }
    else {
      return p24_msoap('rest_fiz', $data);
    }
  }

}

#**********************************************************
=head2 p24_get_card_info($card_id, $attr) - Send request using curl

=cut
#**********************************************************
sub p24_get_card_info {
  my ($card_id) = @_;

  my $data = "<oper>cmt</oper><wait>0</wait>" . qq{<prop name="cardnum" value="$card_id" /><prop name="country" value="UA" />};

  return p24_msoap('balance', $data);
}

#**********************************************************
=head2 p24_msoap($point, $xml, $attr) - Send request using curl

=cut
#**********************************************************
sub p24_msoap {
  my ($point, $xml, $attr) = @_;

  $xml =~ s/[\r\n]//g;
  my $request = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" . "<request version=\"1.0\">" . "<merchant><id>$merchant_id</id><signature>" . (p24_calc_signature($xml)) . "</signature></merchant>" . "<data>" . $xml . "</data></request>";
  $request =~ s/"/\\"/g;

  my $result = web_request("$main_url/$point", {
      POST    => $request,
      DEBUG   => (defined($attr->{DEBUG})) ? $attr->{DEBUG} : 0,
      CURL    => 1,
      HEADERS => [ "Content-Type: text/xml" ],
    });

  return $result;
}

#**********************************************************
=head2 p24_calc_signature($data) - Calc signature

=cut
#**********************************************************
sub p24_calc_signature {
  my ($data) = @_;

  load_pmodule('Digest::MD5');
  load_pmodule('Digest::SHA', { IMPORT => 'sha1_hex' });

  my $md5 = Digest::MD5->new();
  $md5->reset;
  $md5->add($data . $merchant_pass);

  my $digest = Digest::SHA::sha1_hex($md5->hexdigest());

  return $digest;
}

1
