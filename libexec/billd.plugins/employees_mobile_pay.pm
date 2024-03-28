=head1 NAME

  Mobile replenishment at this date

  Arguments:
    PAY - for making payment
    CHECK - for cheking payment status
    DEBUG: 4 - show list
           6 - debug web request
=cut

use strict;
use warnings "all";
use Employees;
require Employees::Mobile_payment;
use Digest::MD5 qw(md5_hex);
use Digest::SHA qw(sha1_hex);
use AXbills::Fetcher qw/web_request/;
use XML::Simple qw(:strict);

our (
  $db,
  %conf,
  $argv,
  $Admin,
  %lang,
);

my $debug = $argv->{DEBUG} || 0;
my $Employees = Employees->new($db, $Admin, \%conf);

if ($argv->{PAY}) {
  employees_date_mobile_pay();
}
elsif ($argv->{CHECK}) {
  employees_date_mobile_check();
}


#**********************************************************
=head2 employees_date_mobile_pay() - makes mobile payment at date

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub employees_date_mobile_pay {
  my $list = q{};
  my (undef, undef, $d) = split(/\-/, $DATE);

  $list = $Employees->employees_ext_params_list({
    PHONE     => '_SHOW',
    AID       => '_SHOW',
    SUM       => '_SHOW',
    DAY_NUM   => "$d",
    STATUS    => '1',
    COLS_NAME => 1,
  });

  unless ($list) {
    print "Do not any employee for this date.\n";
    return 1;
  }

  if ($debug eq 4) {
    AXbills::Base::_bp('employees list', $list,{TO_CONSOLE => 1});
    return 1;
  }

  foreach my $item (@$list) {
    next unless ($item->{phone} && $item->{aid} && $item->{sum});

    employees_mobile_pay({
      AID          => $item->{aid},
      CELL         => $item->{phone},
      SUM          => $item->{sum},
      DEBUG        => $debug,
      FOR_CONSOLE  => 1,
      ADMIN_OBJECT => $Admin,
    });
  }
  return 1;
}

#**********************************************************
=head2 employees_date_mobile_check()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub employees_date_mobile_check {
  my $checklist = $Employees->employees_mobile_report_list({
    STATUS         => 1,
    TRANSACTION_ID => '_SHOW',
    COLS_NAME      => 1,
  });

  unless ($checklist) {
    print "Do not any payments.\n";
    return 1;
  }

  unless ($conf{MOBILE_PAY_PASS_MERCHANT} && $conf{MOBILE_PAY_ID_MERCHANT}) {
    print "WRONG Merchant password or ID.\n";
    return 1;
  }

  if ($debug eq 4) {
    AXbills::Base::_bp('check', $checklist, {TO_CONSOLE => 1});
    return 1;
  }

  my $payment_id = q{};
  my $text = qq{};
  my $data = qq{};
  my $responce_state = q{};
  my $signature = qq{};
  my $url = qq{https://api.privatbank.ua/p24api/check_directfill};
  my %statuses = (
    'err' => 0,
    'snd' => 1,
    'ok'  => 2,
    'no'  => 3,
  );
  my $result = q{};
  my $responce = q{};

  foreach (@$checklist) {
    next unless ($_->{transaction_id});

    $payment_id = $_->{transaction_id};
    $text = qq{<oper>cmt</oper><wait>0</wait><test>0</test>};
    $text .= qq{<payment><prop name="id" value="$payment_id"/></payment>};

    $signature = md5_hex($text . $conf{MOBILE_PAY_PASS_MERCHANT});
    $signature = sha1_hex($signature);

    $data = qq{<?xml version="1.0" encoding="UTF-8"?>
            <request version="1.0">
                <merchant>
                    <id>$conf{MOBILE_PAY_ID_MERCHANT}</id>
                    <signature>$signature</signature>
                </merchant>
                <data>
                  $text
                </data>
            </request>};
    $data =~ s/"/\\\"/g;
    $data =~ s/\n//g;
    $result = web_request($url, { DEBUG => $debug, POST => $data });
    $responce = XML::Simple::XMLin($result, ForceArray => 1, KeyAttr => 1);
    $responce_state = $responce->{data}[0]{payment}[0]{state};

    $Employees->employees_mobile_report_change({
      ID            => $_->{id},
      STATUS         => $statuses{$responce_state},
    });

    if ($Employees->{errno}) {
      print "Wrong request state.\n";
    }
  }

return 1;
}

1;
