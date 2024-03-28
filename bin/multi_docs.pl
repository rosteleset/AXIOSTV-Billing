#!/usr/bin/perl

=head1 NAME

  multi_docs

  ABillS Console document creator

=cut

use strict;
use warnings;

BEGIN {
  use FindBin '$Bin';
  our %conf;
  do $Bin . '/../libexec/config.pl';
  unshift(@INC, $Bin . '/../lib/',
    $Bin . '/../AXbills/modules/',
    $Bin . "/../AXbills/$conf{dbtype}",
    $Bin . '/../'
  );
}

our (
  @ones,
  @twos,
  @fifth,
  @one,
  @onest,
  @ten,
  @tens,
  @hundred,
  @money_unit_names,
  %conf,
  %lang
);

use Sys::Hostname;
use POSIX qw(strftime mktime);
use AXbills::Base qw(check_time parse_arguments gen_time next_month
  days_in_month int2ml in_array show_hash date_diff get_period_dates);
use AXbills::Defs;
use Customers;
use Users;
use Admins;
use Docs;
use Tariffs;
use Internet;
use Tags;
use Finance;
use Conf;
require AXbills::Templates;
require AXbills::Misc;

my $begin_time = check_time();
#my $tmp_path        = '/tmp/';
my $docs_in_file = 4000;

our $html = AXbills::HTML->new(
  {
    CONF     => \%conf,
    csv      => 1,
    NO_PRINT => 0
  }
);

our $db = AXbills::SQL->connect($conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd},
  { CHARSET => ($conf{dbcharset}) ? $conf{dbcharset} : undef });
our $admin = Admins->new($db, \%conf);
$admin->info($conf{SYSTEM_ADMIN_ID}, { IP => '127.0.0.1' });
my $Fees = Finance->fees($db, $admin, \%conf);
my $Users = Users->new($db, $admin, \%conf);
our $users = $Users;
my $Docs = Docs->new($db, $admin, \%conf);
my $Tariffs = Tariffs->new($db, \%conf, $admin);
my $Tags = Tags->new($db, $admin, \%conf);
our $Conf = Conf->new($db, $admin, \%conf);

do "language/$conf{default_language}.pl";
$html->{language} = $conf{default_language};
load_module('Docs', $html);

my $argv = parse_arguments(\@ARGV);
if (defined($argv->{help})) {
  help();
  exit;
}

my $pdf_result_path = $Bin . '/../cgi-bin/admin/pdf/';
my $debug = $argv->{DEBUG} || 0;

if ($argv->{DATE}) {
  $DATE = $argv->{DATE};
}

my ($Y, $m, $d) = split(/-/, $DATE, 3);

if ($argv->{RESULT_DIR}) {
  $pdf_result_path = $argv->{RESULT_DIR};
}
else {
  $pdf_result_path = $pdf_result_path . "/$Y-$m/";
}

my $sort = 1;

if ($argv->{SORT}) {
  if ($argv->{SORT} eq 'ADDRESS') {
    $sort = "streets.name, builds.number+1, pi.address_flat+1";
  }
  else {
    $sort = $argv->{SORT};
  }
}

$docs_in_file = $argv->{DOCS_IN_FILE} if ($argv->{DOCS_IN_FILE});

my $save_filename = $pdf_result_path . '/multidoc_.pdf';

my %LIST_PARAMS = ();

if ($argv->{LOGIN}) {
  $LIST_PARAMS{LOGIN} = $argv->{LOGIN};
}
elsif ($argv->{UID}) {
  $LIST_PARAMS{UID} = $argv->{UID};
}

if ($argv->{LIMIT}) {
  $LIST_PARAMS{PAGE_ROWS} = $argv->{LIMIT};
}

if ($argv->{TAGS_NAME}) {
  my @tags = split(/,\s?/, $argv->{TAGS_NAME});
  my %tag_hash = ();
  my @result_arr = ();
  foreach my $k (@tags) {
    if ($k =~ /^!(\S+)/) {
      $tag_hash{$1} = 1;
    }
    else {
      $tag_hash{$k} = 0;
    }
  }
  my $tags_list = $Tags->list({ NAME => join(',', keys %tag_hash), COLS_NAME => 1 });
  foreach my $line (@{$tags_list}) {
    push @result_arr, (($tag_hash{$line->{name}}) ? '!' : '') . $line->{id};
  }

  $LIST_PARAMS{TAGS} = join(',', @result_arr);
  print $LIST_PARAMS{TAGS};
}
elsif ($argv->{TAGS}) {
  $LIST_PARAMS{TAGS} = $argv->{TAGS};
}

if (defined($argv->{POSTPAID_INVOICES})) {
  postpaid_invoices();
}
elsif (defined($argv->{PERIODIC_INVOICE2})) {
  periodic_invoice2();
}
elsif (defined($argv->{PERIODIC_INVOICE})) {
  periodic_invoice();
}
elsif (defined($argv->{PREPAID_INVOICES})) {
  prepaid_invoices() if (!$argv->{COMPANY_ID});
  prepaid_invoices_company() if (!$argv->{LOGIN});
}
elsif (defined($argv->{PERIODIC_ACTS})) {
  periodic_acts();
}
else {
  help();
}

if ($debug > 0) {
  print gen_time($begin_time);
}

#**********************************************************
=head2 create_user_ivoice($docs_user);

  Arguments:
    $docs_user

  Returns:
    \%ORDERS_HASH

=cut
#**********************************************************
sub create_service_orders {
  my ($docs_user) = @_;

  my $total_sum = 0;
  my $num = 0;
  my %ORDERS_HASH = ();
  my @ids = ();
  my %current_invoice = ();

  if ($docs_user->{login_status}) {
    return 0;
  }

  my $DATE = $docs_user->{DATE};
  ($Y) = (split(/-/, $DATE))[0];
  my $invoicing_period = $docs_user->{invoicing_period} || 0;

  if ($docs_user->{activate} ne '0000-00-00') {
    $ORDERS_HASH{INVOICE_PERIOD_START} = next_month({ DATE => $docs_user->{activate} });
    $ORDERS_HASH{INVOICE_PERIOD_STOP} = next_month({ DATE => $docs_user->{activate}, END => 1 });
  }
  else {
    $ORDERS_HASH{INVOICE_PERIOD_START} = ($conf{DOCS_PRE_INVOICE_PERIOD}) ? next_month({ DATE => $DATE }) : $DATE;
    $ORDERS_HASH{INVOICE_PERIOD_STOP} = ($conf{DOCS_PRE_INVOICE_PERIOD}) ? next_month({ DATE => $DATE, END =>
      1 }) : "$Y-$m-" . days_in_month({ DATE =>
      $DATE });
  }

  my $cross_modules_return = cross_modules('docs', { %{$docs_user},
    UID          => $docs_user->{uid},
    SKIP_MODULES => 'Docs,Multidoms,BSR1000,Snmputils,Ipn'
  });

  my $period_from = $ORDERS_HASH{INVOICE_PERIOD_START};
  my $period_to = $ORDERS_HASH{INVOICE_PERIOD_STOP};

  foreach my $module (sort keys %{$cross_modules_return}) {
    if (ref $cross_modules_return->{$module} eq 'ARRAY') {
      next if ($#{$cross_modules_return->{$module}} == -1);

      foreach my $line (@{$cross_modules_return->{$module}}) {
        my ($name, $describe, $sum) = split(/\|/, $line);
        next if ($sum < 0);

        for (my $i = 0; $i < $invoicing_period; $i++) {
          my $result_sum = sprintf("%.2f", $sum);

          if ($docs_user->{discount} && $module ne 'Abon') {
            $result_sum = sprintf("%.2f", $sum * (100 - $docs_user->{discount}) / 100);
          }

          my $order = "$name $describe($period_from-$period_to)";
          if (!$current_invoice{"$order"}) {
            $num++;
            push @ids, $num;
            $ORDERS_HASH{ 'ORDER_' . $num } = $order;
            $ORDERS_HASH{ 'SUM_' . $num } = $result_sum;
            $total_sum += $result_sum;
          }

          $ORDERS_HASH{INVOICE_PERIOD_STOP} = $period_to;
          $period_to = next_month({ DATE => $period_to,
            PERIOD                       =>
              ($docs_user->{activate} && $docs_user->{activate} ne '0000-00-00') ? 30 : undef,
            END                          => 1
          });

          $period_from = next_month({ DATE => $period_from,
            PERIOD                         =>
              ($docs_user->{activate} && $docs_user->{activate} ne '0000-00-00') ? 30 : undef
          });
        }
      }
    }
  }

  if ($#ids > -1) {
    $ORDERS_HASH{IDS} = join(', ', @ids);
  }

  return \%ORDERS_HASH;
}

#**********************************************************
=head2 periodic_invoice($attr)

=cut
#**********************************************************
sub periodic_invoice2 {
  $Docs->{debug} = 1 if ($debug > 6);

  #Get period intervals for users with activate 0000-00-00
  if (!$FORM{INCLUDE_CUR_BILLING_PERIOD}) {
    $FORM{FROM_DATE} = $DATE;
  }

  #my $NEXT_MONTH = next_month({ DATE => $DATE });
  #my $TO_D = days_in_month({ DATE => $NEXT_MONTH });

  if ($conf{SYSTEM_CURRENCY}
    && $conf{DOCS_CURRENCY}
    && $conf{SYSTEM_CURRENCY} ne $conf{DOCS_CURRENCY}
  ) {
    my $Finance = Finance->new($db, $admin, \%conf);
    $Finance->exchange_info(0, { ISO => $FORM{DOCS_CURRENCY} || $conf{DOCS_CURRENCY} });
    $FORM{EXCHANGE_RATE} = $Finance->{ER_RATE};
    $FORM{DOCS_CURRENCY} = $Finance->{ISO};
  }

  my $TO_DATE = $DATE;
  if ($DATE =~ /(\d{4}\-\d{2}\-\d{2})\/(\d{4}\-\d{2}\-\d{2})/) {
    $TO_DATE = $1;
  }

  my $docs_users = $Docs->user_list(
    {
      LOGIN                => '_SHOW',
      FIO                  => '_SHOW',
      DEPOSIT              => '_SHOW',
      CREDIT               => '_SHOW',
      LOGIN_STATUS         => '_SHOW',
      INVOICE_DATE         => '_SHOW',
      NEXT_INVOICE_DATE    => '_SHOW',
      ACTIVATE             => '_SHOW',
      SEND_DOCS            => '_SHOW',
      %LIST_PARAMS,
      PRE_INVOICE_DATE     => $DATE,
      PERIODIC_CREATE_DOCS => 1,
      REDUCTION            => '>=0',
      PAGE_ROWS            => 1000000,
      COLS_NAME            => 1,
      LOGIN_STATUS         => 0
    }
  );

  foreach my $docs_user (@{$docs_users}) {
    #    my %user = (
    #      LOGIN             => $docs_user->{login},
    #      FIO               => $docs_user->{fio},
    #      DEPOSIT           => $docs_user->{deposit},
    #      CREDIT            => $docs_user->{credit},
    #      STATUS            => $docs_user->{status},
    #      INVOICE_DATE      => $docs_user->{invoice_date},
    #      NEXT_INVOICE_DATE => $docs_user->{next_invoice_date},
    #      INVOICE_PERIOD    => $docs_user->{invoicing_period},
    #      EMAIL             => $docs_user->{email},
    #      SEND_DOCS         => $docs_user->{send_docs},
    #      UID               => $docs_user->{uid},
    #      ACTIVATE          => $docs_user->{activate},
    #      DISCOUNT          => $docs_user->{reduction} || 0,
    #
    #      DOCS_CURRENCY     => $conf{DOCS_CURRENCY},
    #      EXCHANGE_RATE     => $FORM{EXCHANGE_RATE}
    #    );

    if ($debug > 0) {
      print "$docs_user->{login} [$docs_user->{uid}] DEPOSIT: $docs_user->{deposit} INVOICE_DATE: $docs_user->{invoice_date} NEXT: $docs_user->{next_invoice_date} SEND_DOCS: $docs_user->{send_docs} EMAIL: $docs_user->{email}\n";
    }

    my $ORDERS_HASH = create_service_orders({ %{$docs_user},
      DATE => $docs_user->{next_invoice_date}
    });

    my @ids = split(/, /, $ORDERS_HASH->{IDS});
    my $num = $#ids + 1;
    my $amount_for_pay = 0;
    my $total_sum = 0;
    my $total_not_invoice = 0;

    # Get invoces
    my %current_invoice = ();
    $Docs->invoices_list(
      {
        UID         => $docs_user->{uid},
        #          PAYMENT_ID  => 0,
        ORDERS_LIST => 1,
        COLS_NAME   => 1,
        PAGE_ROWS   => 1000000
      }
    );

    if ($Docs->{ORDERS}) {
      foreach my $doc_id (keys %{$Docs->{ORDERS}}) {
        foreach my $invoice (@{$Docs->{ORDERS}->{$doc_id}}) {
          $current_invoice{ $invoice->{orders} } = $invoice->{invoice_id};
        }
      }
    }

    # No invoicing service from last invoice
    my $new_invoices = $Docs->invoice_new(
      {
        FROM_DATE => '2011-01-01',
        TO_DATE   => $TO_DATE,
        PAGE_ROWS => 1000000,
        COLS_NAME => 1,
        UID       => $docs_user->{uid}
      }
    );

    foreach my $invoice (@{$new_invoices}) {
      next if ($invoice->{fees_id});
      next if ($current_invoice{$invoice->{dsc}});

      $num++;
      push @ids, $num;
      $ORDERS_HASH->{ "ORDER_" . $num } = $invoice->{dsc};
      $ORDERS_HASH->{ "SUM_" . $num } = $invoice->{sum};
      $ORDERS_HASH->{ "FEES_ID_" . $num } = $invoice->{id};
      $total_not_invoice += $invoice->{sum};
    }

    if ($#ids > -1) {
      $ORDERS_HASH->{IDS} = join(', ', @ids);
    }

    if ($debug > 3) {
      print "$docs_user->{login}: Invoice period: $ORDERS_HASH->{INVOICE_PERIOD_START} - $ORDERS_HASH->{INVOICE_PERIOD_STOP}\n";

      for (my $i = 1; $i <= $num; $i++) {
        print "$i |" . $ORDERS_HASH->{ 'ORDER_' . $i } . "| " . $ORDERS_HASH->{ 'SUM_' . $i } . "| " . ($ORDERS_HASH->{ 'FEES_ID_' . $i } || '') . "\n";
        $total_sum += $ORDERS_HASH->{ 'SUM_' . $i };
      }

      print "Total: $num  SUM: $total_sum Amount to pay: $amount_for_pay\n";
    }

    if (!defined($ORDERS_HASH->{IDS})) {
      next;
    }

    if ($debug < 5) {
      my $invoice_date = $argv->{INVOICE_DATE} || $docs_user->{next_invoice_date} || undef;
      my $invoice_id = docs_invoice({
        INVOICE_DATA => {
          %{$ORDERS_HASH},
          UID        => $docs_user->{uid},
          SEND_EMAIL => $docs_user->{send_docs} || 0,
          DATE       => $invoice_date,
          DEPOSIT    => ($argv->{INCLUDE_DEPOSIT}) ? $docs_user->{deposit} : 0,
          create     => 1
        }
      });

      if ($debug > 2) {
        print "Added: $invoice_id DATE: $invoice_date\n";
      }

      $Docs->user_change(
        {
          UID          => $docs_user->{uid},
          INVOICE_DATE => $docs_user->{next_invoice_date},
          CHANGE_DATE  => 1,
        }
      );
    }
  }

  return 1;
}


#**********************************************************
=head2 periodic_invoice($attr)

=cut
#**********************************************************
sub periodic_invoice {
  #my ($attr) = @_;

  $Docs->{debug} = 1 if ($debug > 6);

  #Get period intervals for users with activate 0000-00-00
  if (!$FORM{INCLUDE_CUR_BILLING_PERIOD}) {
    $FORM{FROM_DATE} = $DATE;
  }

  #my ($Y, $m, $D) = split( /-/, $DATE );
  #my $start_period_unixtime;

  #my $M;
  my ($TO_D);
  #my $D = '01';

  my $NEXT_MONTH = next_month({ DATE => $DATE });
  $TO_D = days_in_month({ DATE => $NEXT_MONTH });

  if ($conf{SYSTEM_CURRENCY}
    && $conf{DOCS_CURRENCY}
    && $conf{SYSTEM_CURRENCY} ne $conf{DOCS_CURRENCY}
  ) {
    my $Finance = Finance->new($db, $admin, \%conf);
    $Finance->exchange_info(0, { ISO => $FORM{DOCS_CURRENCY} || $conf{DOCS_CURRENCY} });
    $FORM{EXCHANGE_RATE} = $Finance->{ER_RATE};
    $FORM{DOCS_CURRENCY} = $Finance->{ISO};
  }

  my $TO_DATE = $DATE;
  if ($DATE =~ /(\d{4}\-\d{2}\-\d{2})\/(\d{4}\-\d{2}\-\d{2})/) {
    $TO_DATE = $1;
  }

  my $docs_users = $Docs->user_list(
    {
      LOGIN                => '_SHOW',
      FIO                  => '_SHOW',
      DEPOSIT              => '_SHOW',
      CREDIT               => '_SHOW',
      LOGIN_STATUS         => '_SHOW',
      INVOICE_DATE         => '_SHOW',
      NEXT_INVOICE_DATE    => '_SHOW',
      ACTIVATE             => '_SHOW',
      %LIST_PARAMS,
      PRE_INVOICE_DATE     => $DATE,
      PERIODIC_CREATE_DOCS => 1,
      REDUCTION            => '>=0',
      PAGE_ROWS            => 1000000,
      COLS_NAME            => 1,
      LOGIN_STATUS         => 0
    }
  );

  foreach my $docs_user (@{$docs_users}) {
    # my %user = (
    #   LOGIN             => $docs_user->{login},
    #   FIO               => $docs_user->{fio},
    #   DEPOSIT           => $docs_user->{deposit},
    #   CREDIT            => $docs_user->{credit},
    #   STATUS            => $docs_user->{status},
    #   INVOICE_DATE      => $docs_user->{invoice_date},
    #   NEXT_INVOICE_DATE => $docs_user->{next_invoice_date},
    #   INVOICE_PERIOD    => $docs_user->{invoicing_period},
    #   EMAIL             => $docs_user->{email},
    #   SEND_DOCS         => $docs_user->{send_docs},
    #   UID               => $docs_user->{uid},
    #   ACTIVATE          => $docs_user->{activate},
    #   DISCOUNT          => $docs_user->{reduction} || 0,
    #
    #   DOCS_CURRENCY     => $conf{DOCS_CURRENCY},
    #   EXCHANGE_RATE     => $FORM{EXCHANGE_RATE}
    # );

    if ($debug > 0) {
      print "$docs_user->{LOGIN} [$docs_user->{UID}] DEPOSIT: $docs_user->{DEPOSIT} INVOICE_DATE: $docs_user->{INVOICE_DATE} NEXT: $docs_user->{NEXT_INVOICE_DATE} SEND_DOCS: $docs_user->{SEND_DOCS} EMAIL: $docs_user->{EMAIL}\n";
    }

    #create_user_ivoice($docs_user);
    next;
=comments
    my $total_sum = 0;
    my $total_not_invoice = 0;
    my $amount_for_pay = 0;
    my $num = 0;
    my %ORDERS_HASH = ();
    my @ids = ();

    # Get invoces
    my %current_invoice = ();
    $Docs->invoices_list(
      {
        UID         => $docs_user->{UID},
        #          PAYMENT_ID  => 0,
        ORDERS_LIST => 1,
        COLS_NAME   => 1,
        PAGE_ROWS   => 1000000
      }
    );

    if ( $Docs->{ORDERS} ){
      foreach my $doc_id ( keys %{ $Docs->{ORDERS} } ){
        foreach my $invoice ( @{ $Docs->{ORDERS}->{$doc_id} } ){
          $current_invoice{ $invoice->{orders} } = $invoice->{invoice_id};
        }
      }
    }
    #--------------

    # No invoicing service from last invoice
    my $new_invoices = $Docs->invoice_new(
      {
        FROM_DATE => '2011-01-01',
        TO_DATE   => $TO_DATE,
        PAGE_ROWS => 1000000,
        COLS_NAME => 1,
        UID       => $user{UID}
      }
    );

    foreach my $invoice ( @{$new_invoices} ){
      next if ($invoice->{fees_id});
      next if ($current_invoice{$invoice->{dsc}});

      $num++;
      push @ids, $num;
      $ORDERS_HASH{ "ORDER_" . $num } = "$invoice->{dsc}";
      $ORDERS_HASH{ "SUM_" . $num } = "$invoice->{sum}";
      $ORDERS_HASH{ "FEES_ID_" . $num } = "$invoice->{id}";
      $total_not_invoice += $invoice->{sum};
    }
    #---------------

    if ( $docs_user->{activate} ne '0000-00-00' ){
      $FORM{NEXT_PERIOD} = $docs_user->{activate};
      ($Y, $M, $D) = split( /-/, $docs_user->{activate}, 3 );
      $start_period_unixtime = (mktime( 0, 0, 0, $D, ($M - 1), ($Y - 1900), 0, 0, 0 ) + 30 * 86400);

      $user{INVOICE_PERIOD_START} = strftime( '%Y-%m-%d',
        localtime( mktime( 0, 0, 0, $D, ($M - 1), ($Y - 1900), 0, 0, 0 ) + 31 * 86400 ) );
      $user{INVOICE_PERIOD_STOP} = strftime( '%Y-%m-%d',
        localtime( mktime( 0, 0, 0, $D, ($M - 1), ($Y - 1900), 0, 0, 0 ) + 31 * 86400 ) );
      ($Y, $M, $D) = split( /-/, $user{INVOICE_PERIOD_START}, 3 );
    }
    else{
      $user{INVOICE_PERIOD_START} = $NEXT_MONTH;
    }

    #Next period payments
    if ( $FORM{NEXT_PERIOD} ){
      if ( !$docs_user->{login_status} ){
        my $cross_modules_return = cross_modules('docs',
          { %user, SKIP_MODULES => 'Docs,Multidoms,BSR1000,Snmputils,Ipn' } );
        my $next_period = $FORM{NEXT_PERIOD};

        if ( $docs_user->{activate} ne '0000-00-00' ){
          ($Y, $M, $D) = split( /-/, strftime "%Y-%m-%d", localtime( (mktime( 0, 0, 0, $D, ($M - 1), ($Y - 1900), 0, 0,
                  0 ) + ((($start_period_unixtime > time) ? 0 : 1) + 30 * (($start_period_unixtime > time) ? 0 : 1)) * 86400) ) );
          $FORM{FROM_DATE} = "$Y-$M-$D";

          ($Y, $M, $D) = split( /-/, strftime "%Y-%m-%d", localtime( (mktime( 0, 0, 0, $D, ($M - 1), ($Y - 1900), 0, 0,
                  0 ) + ((($start_period_unixtime > time) ? 1 : (1 * $next_period - 1)) + 30 * (($start_period_unixtime > time) ? 1 : $next_period)) * 86400) ) );
          $FORM{TO_DATE} = "$Y-$M-$D";
        }
        else{
          $FORM{FROM_DATE} = $NEXT_MONTH;
        }

        my $period_from = $FORM{FROM_DATE};
        my $period_to = $FORM{FROM_DATE};

        foreach my $module ( sort keys %{$cross_modules_return} ){
          if ( ref $cross_modules_return->{$module} eq 'ARRAY' ){
            next if ($#{ $cross_modules_return->{$module} } == -1);

            foreach my $line ( @{ $cross_modules_return->{$module} } ){
              my ($name, $describe, $sum) = split( /\|/, $line );
              next if ($sum < 0);
              $period_from = $FORM{FROM_DATE};

              for ( my $i = ($FORM{NEXT_PERIOD} == -1) ? -2 : 0; $i < int( $FORM{NEXT_PERIOD} ); $i++ ){
                my $result_sum = sprintf( "%.2f", $sum );
                if ( $user{DISCOUNT} && $module ne 'Abon' ){
                  $result_sum = sprintf( "%.2f", $sum * (100 - $user{DISCOUNT}) / 100 );
                }

                ($Y, $M, $D) = split( /-/, $period_from, 3 );
                if ( $docs_user->{activate} ne '0000-00-00' ){
                  ($Y, $M, $D) = split( /-/, strftime "%Y-%m-%d",
                      localtime( (mktime( 0, 0, 0, $D, ($M - 1), ($Y - 1900), 0, 0,
                          0 )) ) );    #+ (31 * $i) * 86400) ));
                  $period_from = "$Y-$M-$D";

                  ($Y, $M, $D) = split( /-/, strftime "%Y-%m-%d",
                      localtime( (mktime( 0, 0, 0, $D, ($M - 1), ($Y - 1900), 0, 0, 0 ) + (30) * 86400) ) );
                  $period_to = "$Y-$M-$D";
                }
                else{
                  $M += 1 if ($i > 0);
                  if ( $M < 13 ){
                    $M = sprintf( "%02d", $M );
                  }
                  else{
                    $M = sprintf( "%02d", $M - 12 );
                    $Y++;
                  }
                  $period_from = "$Y-$M-01";

                  #$M+=1;
                  if ( $M < 13 ){
                    $M = sprintf( "%02d", $M );
                  }
                  else{
                    $M = sprintf( "%02d", $M - 13 );
                    $Y++;
                  }

                  if ( $user{ACTIVATE} eq '0000-00-00' ){
                    $TO_D = ($M != 2 ? (($M % 2) ^ ($M > 7)) + 30 : (!($Y % 400) || !($Y % 4) && ($Y % 25) ? 29 : 28));
                  }
                  else{
                    $TO_D = $D;
                  }

                  $period_to = "$Y-$M-$TO_D";
                }

                my $order = "$name $describe($period_from-$period_to)";
                $user{INVOICE_PERIOD_STOP} = $period_to;
                if ( !$current_invoice{"$order"} ){
                  $num++;
                  push @ids, $num;
                  $ORDERS_HASH{ 'ORDER_' . $num } = $order;
                  $ORDERS_HASH{ 'SUM_' . $num } = $result_sum;
                  $total_sum += $result_sum;
                }
                $period_from = strftime "%Y-%m-%d",
                  localtime( (mktime( 0, 0, 0, $D, ($M - 1), ($Y - 1900), 0, 0, 0 ) + 1 * 86400) );
              }
            }
          }
        }
      }
    }

    $amount_for_pay = ($total_sum < $user{DEPOSIT}) ? 0 : $total_sum - $user{DEPOSIT};
    $total_sum += $total_not_invoice;
    $ORDERS_HASH{IDS} = join( ', ', @ids );

    if ( $debug > 1 ){
      print "$docs_user->{LOGIN}: Invoice period: $user{INVOICE_PERIOD_START} - $user{INVOICE_PERIOD_STOP}\n";
      for ( my $i = 1; $i <= $num; $i++ ){
        print "$i|" . $ORDERS_HASH{ 'ORDER_' . $i } . "|" . $ORDERS_HASH{ 'SUM_' . $i } . "| " . ($ORDERS_HASH{ 'FEES_ID_' . $i } || '') . "\n";
      }
      print "Total: $num  SUM: $total_sum Amount to pay: $amount_for_pay\n";
    }

    #$Docs->{FROM_DATE} = $html->date_fld2('FROM_DATE', { MONTHES => \@MONTHES, FORM_NAME => 'invoice_add', WEEK_DAYS => \@WEEKDAYS });
    #$Docs->{TO_DATE}   = $html->date_fld2('TO_DATE',   { MONTHES => \@MONTHES, FORM_NAME => 'invoice_add', WEEK_DAYS => \@WEEKDAYS });
    $FORM{NEXT_PERIOD} = 0 if ($FORM{NEXT_PERIOD} < 0);

    #Add to DB
    next if ($num == 0);
    if ( $debug < 5 ){
      $Docs->invoice_add( { %user,
          %ORDERS_HASH,
          DATE    => $argv->{INVOICE_DATE} || undef,
          DEPOSIT => ($argv->{INCLUDE_DEPOSIT}) ? $user{DEPOSIT} : 0
        } );

      $Docs->user_change(
        {
          UID          => $user{UID},
          INVOICE_DATE => $user{NEXT_INVOICE_DATE},
          CHANGE_DATE  => 1,
        }
      );

      #Sendemail
      if ( $num > 0 && $user{SEND_DOCS} ){
        my @invoices = split( /,/, $Docs->{DOC_IDS} );
        foreach my $doc_id ( @invoices ){
          $FORM{print} = $doc_id;
          $LIST_PARAMS{UID} = $user{UID};
          docs_invoice(
            {
              GET_EMAIL_INFO => 1,
                SEND_EMAIL   => $user{SEND_DOCS} || 0,
                UID          => $user{UID},
                %user
            }
          );
        }
      }
    }
=cut
  }

  return 1;
}


#**********************************************************
=head2 send_invoices($attr)

=cut
#**********************************************************
sub send_invoices {
  my ($attr) = @_;

  foreach my $id (@{$attr->{INVOICES_IDS}}) {
    $FORM{pdf} = 1;
    $FORM{print} = $id;

    docs_invoice(
      {
        GET_EMAIL_INFO => 1,
        SEND_EMAIL     => 1,
        %{$attr}
      }
    );
    if ($debug > 3) {
      print "ID: $id Sended\n";
    }
  }

  return 1;
}

#**********************************************************
=head2 prepaid_invoices() - Make invoice for users

=cut
#**********************************************************
sub prepaid_invoices {

  my @MODULES = ('Internet');
  my Internet $mod_name = $MODULES[0];
  require $mod_name . '.pm';
  $mod_name->import();
  my Internet $Module_name = $mod_name->new($db, $admin, \%conf);

  $LIST_PARAMS{TP_ID} = $argv->{TP_ID} if ($argv->{TP_ID});
  $LIST_PARAMS{GID} = $argv->{GID} if ($argv->{GID});
  $LIST_PARAMS{DEPOSIT} = $argv->{DEPOSIT} if ($argv->{DEPOSIT});
  #my $TP_LIST = get_tps();
  my %INFO_FIELDS_SEARCH = ();
  $Module_name->{debug} = 1 if ($debug > 6);

  my $list = $Module_name->user_list({
    DISABLE        => 0,
    COMPANY_ID     => 0,
    CONTRACT_ID    => '_SHOW',
    FIO            => '_SHOW',
    LOGIN          => '_SHOW',
    ADDRESS_STREET => '_SHOW',
    ADDRESS_BUILD  => '_SHOW',
    ADDRESS_FLAT   => '_SHOW',
    TP_NAME        => '_SHOW',
    DAY_FEE        => '_SHOW',
    MONTH_FEE      => '_SHOW',
    TP_REDUCTION_FEE=> '_SHOW',
    DEPOSIT        => '_SHOW',
    REDUCTION      => '_SHOW',
    CONTRACT_DATE  => '>=0000-00-00',
    PAGE_ROWS      => 1000000,
    %INFO_FIELDS_SEARCH,
    SORT           => $sort,
    SKIP_TOTAL     => 1,
    %LIST_PARAMS,
    COLS_NAME      => 1
  });

  my $doc_num = 0;
  my $users_total = 0;

  foreach my $service (@{$list}) {
    my $uid = $service->{uid};
    my $tp_id = $service->{tp_id};

    print "UID: $uid LOGIN: $service->{login} FIO: $service->{fio} TP: $tp_id / $Module_name->{SEARCH_FIELDS_COUNT}\n" if ($debug > 2);

    $Docs->{PERIODIC_CREATE_DOCS}=0;
    $Docs->user_info($uid);

    if ($argv->{INVOICE2ALL} || !$Docs->{PERIODIC_CREATE_DOCS}) {
      print "Skip create docs INVOICE2ALL: " . ($argv->{INVOICE2ALL} || q{})
        ." PERIODIC_CREATE_DOCS: ". ($Docs->{PERIODIC_CREATE_DOCS} || q{}) ."\n" if ($debug > 2);
      next;
    }

    my %invoice_data = (
      UID        => $uid,
      create     => 1,
      SEND_EMAIL => $argv->{INVOICE2ALL} || $Docs->{SEND_DOCS},
      pdf        => 1,
      CUSTOMER   => '-',
      EMAIL      => $Docs->{EMAIL}
    );

    $users_total++;
    my @orders = ();

    #Add debetor invoice
    if ($service->{deposit} && $service->{deposit} < 0) {
      print "  DEPOSIT: $service->{deposit} SEND: $invoice_data{SEND_EMAIL}\n" if ($debug > 2);
      push @orders, {
        ORDER => $lang{DEBT},
        SUM   => abs($service->{deposit})
      };
    }

    my  $tp_name  = $service->{tp_name} || q{};
    my  $fees_sum = 0;

    #add  tp invoice
    if ($service->{month_fee} && $service->{month_fee} > 0) {
      $fees_sum = $service->{month_fee};
    }

    if ($service->{day_fee} && $service->{day_fee} > 0) {
      $fees_sum = $service->{day_fee} * days_in_month();
    }

    if ($fees_sum) {
      print "  TP_ID: $tp_id FEES: $fees_sum\n" if ($debug > 2);
      if ($service->{tp_reduction_fee} && $service->{reduction} && $service->{reduction} > 0) {
        $fees_sum = $fees_sum * (100 - $service->{reduction}) / 100;
      }

      push @orders, {
        ORDER => $lang{TARIF_PLAN}.': '.$tp_name,
        SUM   => $fees_sum
      };
    }

    if ($#orders > -1) {
      my @ids = ();
      for (my $i = 0; $i <= $#orders; $i++) {
        if ($argv->{SINGLE_ORDER}) {
          $invoice_data{ORDER} = $lang{DEBT};
          $invoice_data{SUM} += $orders[$i]->{SUM};
        }
        else {
          $invoice_data{'ORDER_' . ($i + 1)} = $orders[$i]->{ORDER};
          $invoice_data{'SUM_' . ($i + 1)} = $orders[$i]->{SUM};
          push @ids, ($i + 1);
        }
      }

      $invoice_data{'IDS'} = join(', ', @ids) if ($#ids > -1);
      if ($debug < 8) {
        docs_invoice({
          QUITE          => 1,
          SEND_EMAIL     => $invoice_data{SEND_EMAIL} || 0,
          UID            => $invoice_data{UID},
          INVOICE_DATA   => \%invoice_data,
          GET_EMAIL_INFO => 1
        });
      }

      $doc_num += $#orders + 1;
    }
  }

  print "TOTAL USERS: $users_total DOCS: $doc_num\n";

  return 1;
}

#**********************************************************
=head2 get_tps($attr)

  Arguments:
    $attr
      INTERNET
      AGE

  Results:
    \%TP_INFO(id => info)


=cut
#**********************************************************
sub get_tps {
  my ($attr) = @_;

  my %TP_LIST = ();

  if ($debug > 6) {
    $Tariffs->{debug} = 1;
  }

  my $tp_list = $Tariffs->list({
    NAME         => '_SHOW',
    MONTH_FEE    => '_SHOW',
    DAY_FEE      => '_SHOW',
    AGE          => '_SHOW',
    ACTIV_PRICE  => '_SHOW',
    %LIST_PARAMS,
    NEW_MODEL_TP => 1,
    COLS_NAME    => 1
  });

  foreach my $tp (@{$tp_list}) {
    if ($attr->{AGE}) {
      if ($tp->{age}) {
        $TP_LIST{ $tp->{tp_id} } = "$tp->{name};$tp->{age};" . ($tp->{month_fee} + $tp->{activate_price});
      }
    }
    elsif ($tp->{month_fee} > 0) {
      $TP_LIST{ $tp->{tp_id} } = "$tp->{name};$tp->{month_fee}";
    }
    elsif ($tp->{day_fee} > 0) {
      $TP_LIST{ $tp->{tp_id} } = "$tp->{name};" . ($tp->{day_fee} * 30);
    }
  }

  return \%TP_LIST;
}

#**********************************************************
=head2 prepaid_invoices_company()

=cut
#**********************************************************
sub prepaid_invoices_company {

  my $customer = Customers->new($db, $admin, \%conf);
  my $Company = $customer->company();

  our %user;

  require $MODULES[0] . '.pm';
  $MODULES[0]->import();
  $LIST_PARAMS{TP_ID} = $argv->{TP_ID} if ($argv->{TP_ID});
  $LIST_PARAMS{COMPANY_ID} = $argv->{COMPANY_ID} if ($argv->{COMPANY_ID});
  $LIST_PARAMS{DEPOSIT} = $argv->{DEPOSIT} if ($argv->{DEPOSIT});
  my $TP_LIST = get_tps();

  if ($debug > 6) {
    $Company->{debug} = 1;
  }

  my $list = $Company->list({
    DISABLE    => 0,
    PAGE_ROWS  => 1000000,
    SORT       => $sort,
    SKIP_TOTAL => 1,
    DEPOSIT    => '_SHOW',
    %LIST_PARAMS,
    COLS_NAME  => 1
  });

  my $doc_num = 0;
  my %ORDERS_HASH = ();

  foreach my $line (@{$list}) {
    my $name = $line->{name};
    my $deposit = $line->{deposit};
    my $company_id = $line->{id};

    print "COMPANY: $name ID: $company_id DEPOSIT: $deposit\n" if ($debug > 2);

    #get main user
    my $admin_login = 0;
    my $admin_user = 0;
    my $admin_user_email = '';
    my $admin_list = $Company->admins_list({
      COMPANY_ID => $company_id,
      GET_ADMINS => 1,
      COLS_NAME  => 1
    });

    if ($Company->{TOTAL} < 1) {
      print "Company don't have admin user\n";
      next;
    }
    else {
      $admin_login = $admin_list->[0]->{login};
      $admin_user = $admin_list->[0]->{uid};
      $admin_user_email = $admin_list->[0]->{email};
    }

    #Check month periodic
    $Docs->user_info($admin_user);
    if (!$Docs->{PERIODIC_CREATE_DOCS}) {
      print "Skip create docs (Not defined option) Admin user UID: $admin_user\n" if ($debug > 2);
      next;
    }

    %FORM = (
      UID        => $admin_user,
      create     => 1,
      SEND_EMAIL => $Docs->{SEND_DOCS} || undef,
      pdf        => 1,
      CUSTOMER   => '-',
      EMAIL      => $Docs->{EMAIL}
    );

    # make debt invoice
    if ($deposit < 0) {
      $FORM{SUM} = abs($deposit);
      $FORM{ORDER} = "$lang{DEBT} $lang{DATE}: $DATE";
      if ($debug < 8) {
        docs_invoice({ QUITE => 1 });
      }
    }

    my $Internet = Internet->new($db, $admin, \%conf);
    #Get company users
    if ($debug > 5) {
      $Internet->{debug} = 1;
    }

    my $internet_list = $Internet->user_list({
      DISABLE    => 0,
      COMPANY_ID => $company_id,
      PAGE_ROWS  => 1000000,
      SORT       => $sort,
      FIO        => '_SHOW',
      LOGIN      => '_SHOW',
      DEPOSIT    => '_SHOW',
      ACTIVATE   => '_SHOW',
      SKIP_TOTAL => 1,
      %LIST_PARAMS,
      COLS_NAME  => 1
    });

    my $tp_sum = 0;
    my $tp_counts = 0;
    my $position_num = 0;
    my @invoice_orders = ();
    foreach my $internet_info (@{$internet_list}) {
      my $uid = $internet_info->{uid};
      my $tp_id = $internet_info->{tp_id} || 0;
      my $fio = $internet_info->{fio} || '';
      $user->{ACTIVATE} = $internet_info->{activate};
      print "UID: $uid LOGIN: $internet_info->{login} FIO: $fio TP: $tp_id\n" if ($debug > 2);
      #Add debetor accouns
      if ($TP_LIST->{$tp_id}) {
        my ($tp_name, $fees_sum) = split(/;/, $TP_LIST->{$tp_id});
        $tp_sum += $fees_sum;
        print "  DEPOSIT: $internet_info->{deposit} ABON: $TP_LIST->{$tp_id}\n" if ($debug > 2);

        if ($argv->{MULTIPOSITION_INVOICE}) {
          $position_num++;
          #        push @invoice_orders, {
          #          'ORDER_' => $tp_name,
          #          'SUM_'   => $fees_sum,
          #          'IDS'    => $position_num
          #        };
          push @invoice_orders, $position_num;
          $FORM{'ORDER_' . $position_num} = $tp_name;
          $FORM{'SUM_' . $position_num} = $fees_sum;
        }
        $doc_num++;
        $tp_counts++;
      }
    }

    $FORM{'IDS'} = join(', ', @invoice_orders); #$position_num[1..$position_num];

    # make tps invoice
    if ($tp_sum > 0) {
      print "TP SUM: $tp_sum\n" if ($debug > 0);
      $FORM{SUM} = $tp_sum;
      $FORM{ORDER} = "$lang{INTERNET}: $lang{TARIF_PLAN} ($tp_counts) "
        . get_period_dates({
        TYPE       => 1,
        START_DATE => $argv->{DATE} || $DATE
      });

      docs_invoice({ QUITE => 1 });
    }

    my $total_sum = 0;
    my @ids = ();
    my $amount_for_pay = 0;
    my $num = 0;

    if (!$argv->{SKIP_NOT_INVOICED_FEES}) {
      if ($debug > 6) {
        $Fees->{debug} = 1;
      }

      my $date = ($argv->{DATE}) ? $argv->{DATE} : ">=$DATE";
      my $fees_list = $Fees->list({
        DATE       => $date,
        DESCRIBE   => '_SHOW',
        SUM        => '_SHOW',
        COMPANY_ID => $company_id,
        COLS_NAME  => 1
      });

      foreach my $_line (@{$fees_list}) {
        $num++;
        push @ids, $num;
        $ORDERS_HASH{ 'ORDER_' . $num } = $_line->{dsc};
        $ORDERS_HASH{ 'SUM_' . $num } = $_line->{sum};
        $ORDERS_HASH{ "FEES_ID_" . $num } = $_line->{id};
        $total_sum += $_line->{sum};
      }
    }

    $ORDERS_HASH{IDS} = join(', ', @ids);

    if ($debug > 1) {
      #print "$user{LOGIN}: Invoice period: $user{INVOICE_PERIOD_START} - $user{INVOICE_PERIOD_STOP}\n";
      for (my $i = 1; $i <= $num; $i++) {
        print "$i|" . $ORDERS_HASH{ 'ORDER_' . $i } . "|" . $ORDERS_HASH{ 'SUM_' . $i } . "| " . ($ORDERS_HASH{ 'FEES_ID_' . $i } || '') . "\n";
      }
      print "Total: $num  SUM: $total_sum Amount to pay: $amount_for_pay\n";
    }

    #Add to DB
    next if ($num == 0);
    if ($debug < 5) {
      $Docs->invoice_add({ %FORM, %ORDERS_HASH });

      $LIST_PARAMS{UID} = $user->{UID};
      $FORM{create} = undef;

      my @doc_ids = split(/,/, $Docs->{DOC_IDS});
      #Sendemail
      foreach my $doc_id (@doc_ids) {
        $FORM{print} = $doc_id;
        docs_invoice(
          {
            GET_EMAIL_INFO => 1,
            SEND_EMAIL     => $Docs->{SEND_DOCS} || 0,
            UID            => $user{UID},
            COMPANY_ID     => $company_id,
            DEBUG          => $debug,
            %user
          }
        );
        $doc_num++;
      }
    }
  }

  print "TOTAL COMPANIES: $Company->{TOTAL} DOCS: $doc_num\n" if ($debug > 0);

  return 1;
}

#**********************************************************
=head2 postpaid_invoices()

=cut
#**********************************************************
sub postpaid_invoices {

  $save_filename = $pdf_result_path . '/multidoc_postpaid_invoices.pdf';
  $Fees->{debug} = 1 if ($debug > 6);

  if (!-d $pdf_result_path) {
    print "Directory no exists '$pdf_result_path'\n" if ($debug > 0);
    if (!mkdir($pdf_result_path)) {
      print "ERROR: '$pdf_result_path' $!\n";
      exit;
    }
    else {
      print " Created.\n" if ($debug > 0);
    }
  }

  $LIST_PARAMS{DEPOSIT} = $argv->{DEPOSIT} if ($argv->{DEPOSIT});
  $LIST_PARAMS{PHONE} = $argv->{PHONE} if (defined($argv->{PHONE}));

  #Fees get month fees - abon. payments
  my $fees_list = $Fees->reports(
    {
      INTERVAL  => "$Y-$m-01/$DATE",
      METHODS   => 1,
      TYPE      => 'USERS',
      COLS_NAME => 1
    }
  );

  # UID / SUM
  my %FEES_LIST_HASH = ();
  foreach my $line (@{$fees_list}) {
    $FEES_LIST_HASH{ $line->{uid} } = $line->{sum};
  }

  #Users info
  my %INFO_FIELDS = ();

  if ($argv->{SECOND_ADDRESS}) {
    %INFO_FIELDS = (
      '_c_address' => 'ADDRESS_STREET',
      '_c_build'   => 'ADDRESS_BUILD',
      '_c_flat'    => 'ADDRESS_FLAT'
    );
  }

  my %INFO_FIELDS_SEARCH = ();

  foreach my $key (keys %INFO_FIELDS) {
    $INFO_FIELDS_SEARCH{$key} = '_SHOW';
  }

  my $user_list;
  my %USER_LIST_PARAMS = (
    LOGIN          => '_SHOW',
    FIO            => '_SHOW',
    LOGIN_STATUS   => '_SHOW',
    DEPOSIT        => '_SHOW',
    CREDIT         => '_SHOW',
    BILL_ID        => '_SHOW',
    CONTRACT_ID    => '_SHOW',
    CONTRACT_DATE  => '_SHOW',
    DISABLE        => 0,
    CONTRACT_ID    => '_SHOW',
    CONTRACT_DATE  => '_SHOW',
    ADDRESS_STREET => '_SHOW',
    ADDRESS_BUILD  => '_SHOW',
    ADDRESS_FLAT   => '_SHOW',
    CITY           => '_SHOW',
    DISTRICT       => '_SHOW',
    ZIP            => '_SHOW',
    #ADDRESS_FULL   => '_SHOW',
    PAGE_ROWS      => 1000000,
    %INFO_FIELDS_SEARCH,
    %LIST_PARAMS,
    SORT           => $sort,
    COLS_NAME      => 1
  );

  if ($argv->{MODULE}) {
    my Internet $mod_name = $argv->{MODULE};
    require $mod_name . '.pm';
    $mod_name->import();
    my Internet $Module_name = $mod_name->new($db, $admin, \%conf);

    $USER_LIST_PARAMS{TP_ID} = $argv->{TP_ID} if ($argv->{TP_ID});

    if ($debug > 6) {
      $Module_name->{debug} = 1;
    }

    $user_list = $Module_name->user_list(\%USER_LIST_PARAMS);
  }
  else {
    if ($debug > 6) {
      $Users->{debug} = 1;
    }
    $user_list = $Users->list(\%USER_LIST_PARAMS);
  }

  # if ($Users->{EXTRA_FIELDS}) {
  #   foreach my $line (@{$Users->{EXTRA_FIELDS}}) {
  #     if ($line && $line->[0] =~ /ifu(\S+)/) {
  #       #my $field_id = $1;
  #       #my ($position, $type, $name) = split( /:/, $line->[1] );
  #     }
  #   }
  # }

  my @MULTI_ARR = ({});
  my $doc_num = 0;

  foreach my $line (@{$user_list}) {
    my $full_address = '';

    my $build_delimiter = $conf{BUILD_DELIMITER} || ', ';

    if ($argv->{ADDRESS2}) {
      $full_address = $line->{address_street2} || '';
      $full_address .= $build_delimiter . ($line->{address_build2} || '');
      $full_address .= $build_delimiter . ($line->{address_flat2} || '');
    }
    else {
      $full_address = $line->{address_street} || '';
      $full_address .= $build_delimiter . ($line->{address_build} || '');
      $full_address .= $build_delimiter . ($line->{asddress_flat} || '');
    }

    my $month_fee = ($FEES_LIST_HASH{ $line->{uid} }) ? $FEES_LIST_HASH{ $line->{uid} } : '0.00';
    my $deposit = $line->{deposit} || 0;
    if ($deposit < 0) {
      push @MULTI_ARR, {
        LOGIN               => $line->{login},
        FIO                 => $line->{fio},
        #        DEPOSIT             => sprintf( "%.2f", $line->{deposit} + $month_fee ),
        DEPOSIT             => sprintf("%.2f", $deposit),
        CREDIT              => $line->{credit},
        SUM                 => sprintf("%.2f", $deposit),
        DISABLE             => 0,
        ORDER_TOTAL_SUM_VAT => ($conf{DOCS_VAT_INCLUDE}) ? sprintf("%.2f",
          abs($deposit / ((100 + $conf{DOCS_VAT_INCLUDE}) / $conf{DOCS_VAT_INCLUDE}))) : 0.00,
        NUMBER              => $line->{bill_id} . "-$m",
        ACTIVATE            => ">=$DATE",
        EXPIRE_DATE         => ($conf{DOCS_ACCOUNT_EXPIRE_PERIOD}) ? strftime('%Y-%m-%d',
          localtime(mktime(0, 0, 0, $d, ($m - 1), ($Y - 1900), 0, 0,
            0) + $conf{DOCS_ACCOUNT_EXPIRE_PERIOD} * 86400)) : '0000-00-00',
        MONTH_FEE           => $month_fee,
        TOTAL_SUM           => sprintf("%.2f", abs($deposit)),
        CONTRACT_ID         => $line->{contract_id},
        CONTRACT_DATE       => $line->{contract_date},
        DATE                => $DATE,
        FULL_ADDRESS        => $full_address,
        ADDRESS_FULL        => $full_address,
        YEAR                => $Y,
        ADDRESS_STREET      => $line->{address_street},
        ADDRESS_BUILD       => $line->{address_build},
        ADDRESS_FLAT        => $line->{address_flat},
        ZIP                 => $line->{zip},
        SUM_LIT             => int2ml(
          sprintf("%.2f", abs($deposit || 0)),
          {
            ONES             => \@ones,
            TWOS             => \@twos,
            FIFTH            => \@fifth,
            ONE              => \@one,
            ONEST            => \@onest,
            TEN              => \@ten,
            TENS             => \@tens,
            HUNDRED          => \@hundred,
            MONEY_UNIT_NAMES => $conf{MONEY_UNIT_NAMES} || \@money_unit_names
          }
        ),
        DOC_NUMBER          => sprintf("%.6d", $doc_num),
      };
      $doc_num++;

      print "UID: $line->{uid} LOGIN: $line->{login} FIO: " . ($line->{fio} || q{}) . " SUM: $deposit\n" if ($debug > 2);
      #      print "UID: $line->{uid} LOGIN: $line->{login} FIO: $line->{fio} SUM: $deposit SUMM2: ($month_fee - $deposit)\n" if ($debug > 2);
      #`echo "$doc_num\t $line->{address_street} $line->{address_build} $line->{address_flat}\t $line->{fio}" >> $pdf_result_path/reestr.txt`;
    }
  }

  #print "TOTAL: " . $Users->{TOTAL};
  if ($debug > 0) {
    print "TOTAL: " . $doc_num . "\n";
  }

  if ($debug < 5) {
    $FORM{pdf} = 1;
    multi_tpls(_include('docs_multi_invoice', 'Docs'), \@MULTI_ARR);
  }

  return 1;
}

#**********************************************************
=head2 multi_tpls($tpl, $MULTI_ARR, $attr) - Create multipage documents

  Arguments:
    $tpl       - Tpl name
    $MULTI_ARR - Params array
    $attr      - Extra params

=cut
#**********************************************************
sub multi_tpls {
  my ($tpl, $MULTI_ARR, $attr) = @_;

  require PDF::API2;
  require AXbills::PDF;
  PDF::API2->import();

  my $pdf = AXbills::PDF->new(
    {
      #IMG_PATH => $IMG_PATH,
      NO_PRINT => defined($attr->{'NO_PRINT'}) ? $attr->{'NO_PRINT'} : 1,
      CONF     => \%conf,
      CHARSET  => $conf{default_charset}
    }
  );

  $html = $pdf;

  $html->tpl_show(
    $tpl, undef,
    {
      MULTI_DOCS           => $MULTI_ARR,
      MULTI_DOCS_PAGE_RECS => $argv->{PAGE_DOCS} || undef,
      SAVE_AS              => $save_filename,
      DOCS_IN_FILE         => $docs_in_file,
      debug                => $debug
    }
  );

  return 1;
}

#**********************************************************
=head2 help()

=cut
#**********************************************************
sub help {

  print <<"[END]";
Multi documents creator Version: 1.07
  PERIODIC_INVOICE - Create periodic invoice for clients
     INCLUDE_DEPOSIT - Include deposit to invoice
     INVOICE_DATE    - Invoice create date XXXX-XX-XX (Default: curdate)
  POSTPAID_INVOICES- Created for previes month debetors
     SECOND_ADDRESS - Use Second address
  PREPAID_INVOICES - Create credit invoice and next month payments invoice
     INVOICE2ALL=1 - Create and send invoice to all users
     SINGLE_ORDER  - All order by 1 position

  PERIODIC_ACTS
    NEXT_PERIOD=1      - Generate for next period
    SKIP_PERIOD_INFO=1 - SKip period info in order name

Extra filter parameters
  LOGIN            - User login
  TP_ID            - Tariff Plan
  UID              - UID
  GID              - User Gid
  TAGS             - TAGS ID (,)
  TAGS_NAME        - TAGS name (,)
  DEPOSIT          - filter user deposit
  COMPANY_ID       - Company id. if defined company id generated only companies invoicess. U can use wilde card *

  RESULT_DIR=      - Output dir (default: axbills/cgi-bin/admin/pdf)
  DOCS_IN_FILE=    - docs in single file (default: $docs_in_file)
  ADDRESS2         - User second address (fields: _c_address, _c_build, _c_flat)
  DATE=YYYY-MM-DD  - Document create date of period "YYYY-MM-DD/YYYY-MM-DD"
  SORT=            - Sort by column number. Special symbol ADDRESS sort by address
  DEBUG=[1..5]     - Debug mode
[END]

  return 1;
}

#**********************************************************
=head2 periodic_acts_pre_period() - Act for prewios period

=cut
#**********************************************************
sub periodic_acts_pre_period {

  if ($debug > 3) {
    print "periodic_acts_pre_period\n";
  }

  require Internet;
  Internet->import();
  my $Internet = Internet->new($db, $admin, \%conf);

  if ($debug > 6) {
    $Internet->{debug} = 1;
  }

  #Get tp info
  my $tp_info = get_tps({ AGE => 1 });

  #Get user TP
  my %users_tps = ();

  my $internet_list = $Internet->user_list({
    TP_ID     => '_SHOW',
    %LIST_PARAMS,
    COLS_NAME => 1,
    PAGE_ROWS => 1000000
  });

  foreach my $line (@$internet_list) {
    $users_tps{$line->{uid}} = $line->{tp_id} || 0;
  }

  #Get fees list
  my $fees_list = $Fees->list({
    DATETIME  => '_SHOW',
    SUM       => '_SHOW',
    DSC       => '_SHOW',
    COLS_NAME => '_SHOW',
    %LIST_PARAMS,
    PAGE_ROWS => 1000000,
  });

  foreach my $line (@$fees_list) {
    my %orders = ();
    my $uid = $line->{uid} || 0;
    my $tp_id = $users_tps{$uid} || 0;

    if (!$tp_info->{$tp_id}) {
      if ($debug > 3) {
        print "UID: $uid NO_TP: $tp_id\n";
      }
      next;
    }

    my ($name, $age, undef) = split(/;/, $tp_info->{$tp_id});

    if (!$age) {
      if ($debug > 3) {
        print "UID: $uid skip age\n";
      }
      next;
    }

    my $start_period = $line->{datetime};
    my ($_date, undef) = split(/ /, $start_period, 2);
    my ($_y, $_m, $_d) = split(/-/, $_date, 3);

    my $act_date = strftime('%Y-%m-%d',
      localtime(mktime(0, 0, 0, $_d, ($_m - 1), ($_y - 1900), 0, 0, 0) + $age * 86400));

    push @{$orders{$uid}}, {
      UID          => $line->{uid},
      ORDER        => $name,
      SUM          => $line->{sum},
      PERIOD       => '',
      TP_ID        => $tp_id,
      TP_AGE       => $age,
      START_PERIOD => $_date,
      END_PERIOD   => $act_date,
      DATE         => $act_date,
      FEES_ID      => $line->{id}
    };

    create_acts(\%orders);
  }

  return 1;
  # my $list = $Internet->user_list({
  #   LOGIN          => '_SHOW',
  #   INTERNET_EXPIRE=> '_SHOW',
  #   TP_ID          => '_SHOW',
  #   GROUP_BY       => 'internet.id',
  #   PAGE_ROWS      => 1000000,
  #   REGISTRATION   => '_SHOW',
  #   COLS_NAME      => 1,
  #   %LIST_PARAMS
  # });
  #
  # foreach my $line ( @$list ) {
  #   my $expire = $line->{internet_expire};
  #
  #   if($expire eq '0000-00-00') {
  #     next;
  #   }
  #
  #   print "$line->{login} TP_ID: $line->{tp_id} EXPIRE: "
  #     . $expire
  #     . "\n" if($debug > 1);
  #
  #   my $date_diff = date_diff($line->{registration}, $expire);
  #   print "REGISTRATION: $line->{registration} EXPIRE: $expire DATEDIFF: $date_diff\n";
  #
  #   my ($name, $age, $sum);
  #   my $act_date = $DATE;
  #
  #   if($tp_info->{$line->{tp_id}} && $expire ne '0000-00-00') {
  #     ($name, $age, $sum)=split(/;/, $tp_info->{$line->{tp_id}});
  #
  #     my $periods = ($age > 0)  ? $date_diff / $age : 0;
  #     print "  TP_AGE: $tp_info->{$line->{tp_id}} PERIODS: $periods\n" if($debug > 2);
  #
  #     for(my $num=$periods; $num>=0; $num--) {
  #       my ($_y, $_m, $_d) = split(/-/, $expire);
  #
  #       my $start_period = strftime('%Y-%m-%d',
  #         localtime(mktime(0, 0, 0, $_d, ($_m - 1), ($_y - 1900), 0, 0, 0) - $age * 86400));
  #
  #       $act_date = $expire;
  #
  #       if ($debug > 2) {
  #         print "  DATE: $act_date $name ($start_period-$act_date)\n";
  #       }
  #       %orders = ();
  #       push @{ $orders{$line->{uid}} }, {
  #         ORDER        => "$name" . ((!defined($argv->{SKIP_PERIOD_INFO})) ? q{} : "($start_period/$act_date)"),
  #         SUM          => $sum || 0,
  #         DATE         => $act_date,
  #         TP_ID        => $line->{tp_id},
  #         START_PERIOD => $start_period,
  #         END_PERIOD   => $act_date,
  #       };
  #
  #       create_acts(\%orders);
  #       $expire = $start_period;
  #     }
  #   }
  # }
  #
  # return 1;
}


#**********************************************************
=head2 periodic_acts()

=cut
#**********************************************************
sub periodic_acts {

  if (defined($argv->{BACK_PERIODS})) {
    periodic_acts_pre_period();
    #create_acts()
    return 1;
  }

  require Internet;
  Internet->import();
  my $Internet = Internet->new($db, $admin, \%conf);

  my $tp_info = get_tps({
    AGE      => 1
  });

  if ($debug > 6) {
    $Internet->{debug} = 1;
  }

  my $list = $Internet->user_list({
    LOGIN           => '_SHOW',
    INTERNET_EXPIRE => '_SHOW',
    TP_ID           => '_SHOW',
    GROUP_BY        => 'internet.id',
    PAGE_ROWS       => 1000000,
    COLS_NAME       => 1,
    %LIST_PARAMS
  });

  my %orders = ();

  foreach my $line (@$list) {
    my $expire = $line->{internet_expire};
    print "$line->{login} TP_ID: $line->{tp_id} EXPIRE: "
      . $expire
      . " TP_AGE: \n" if ($debug > 1);

    my ($name, $age, $sum);
    my $act_date = $DATE;

    if ($tp_info->{$line->{tp_id}} && $expire ne '0000-00-00') {
      print "  TP_AGE: $tp_info->{$line->{tp_id}}\n" if ($debug > 2);
      ($name, $age, $sum) = split(/;/, $tp_info->{$line->{tp_id}});

      my ($_y, $_m, $_d) = split(/-/, $expire);

      my $start_period = strftime('%Y-%m-%d', localtime(mktime(0, 0, 0, $_d, ($_m - 1), ($_y - 1900), 0, 0, 0) - $age * 86400));

      $act_date = $expire;

      if ($debug > 2) {
        print "  DATE: $act_date $name ($start_period-$act_date)\n";
      }

      push @{$orders{$line->{uid}}}, {
        ORDER        => "$name" . ((!$argv->{SKIP_PERIOD_INFO}) ? "($start_period/$act_date)" : q{}),
        SUM          => $sum || 0,
        DATE         => $act_date,
        TP_ID        => $line->{tp_id},
        START_PERIOD => $start_period,
        END_PERIOD   => $act_date,
      }
    }
  }

  if ($debug > 6) {
    return 1;
  }

  if ($argv->{NEXT_PERIOD}) {
    create_acts(\%orders);
  }
  else {
    create_acts(acts_from_fees());
  }

  return 1;
}

#**********************************************************
=head2 acts_from_fees()

=cut
#**********************************************************
sub acts_from_fees {
  my ($attr) = @_;

  my %orders = ();
  my $date = $attr->{DATE} || $DATE;

  if ($debug > 6) {
    $Fees->{debug} = 1;
  }

  if ($argv->{PERIOD}) {
    ($LIST_PARAMS{FROM_DATE}, $LIST_PARAMS{TO_DATE}) = split(/\//, $argv->{PERIOD});
  }
  else {
    my ($_y, $_m) = split(/-/, $date);
    $LIST_PARAMS{FROM_DATE} = "$_y-$_m-01";
    $LIST_PARAMS{TO_DATE} = "$_y-$_m-" . days_in_month({ DATE => $date });
  }

  my $fees_list = $Fees->list({
    DATE      => $date,
    DESCRIBE  => '_SHOW',
    SUM       => '_SHOW',
    COLS_NAME => 1,
    PAGE_ROWS => 1000000,
    %LIST_PARAMS
  });

  my $num = 1;
  foreach my $_line (@{$fees_list}) {
    $num++;
    push @{$orders{$_line->{uid}}}, {
      'ORDER_' . $num   => $_line->{dsc},
      'SUM_' . $num     => $_line->{sum},
      "FEES_ID_" . $num => $_line->{id}
    };
  }

  return \%orders;
}


#**********************************************************
=head2 create_acts()

=cut
#**********************************************************
sub create_acts {
  my ($act_info) = @_;

  my $total = 0;
  foreach my $doc_uid (keys %$act_info) {
    my %doc_create_params = (
      UID             => $doc_uid,
      CHECK_DUBLICATE => 1
    );

    my $i = 0;
    my @ids = ();
    foreach my $doc (@{$act_info->{$doc_uid}}) {
      $i++;
      $doc_create_params{DATE} = $doc->{DATE};
      $doc_create_params{'ORDER_' . $i} = $doc->{ORDER};
      $doc_create_params{'SUM_' . $i} = $doc->{SUM};
      $doc_create_params{START_PERIOD} = $doc->{START_PERIOD};
      $doc_create_params{END_PERIOD} = $doc->{END_PERIOD};
      $doc_create_params{FEES_ID} = $doc->{FEES_ID};

      push @ids, $i;
    }

    $doc_create_params{IDS} = join(',', @ids);

    if ($debug > 3) {
      print "\n====== $doc_uid\n";
      show_hash(\%doc_create_params, { DELIMITER => "\n  " });
    }

    if ($debug < 6) {
      $Docs->{debug} = 1 if ($debug > 4);
      $Docs->act_add(\%doc_create_params);
      if ($Docs->{errno}) {
        print "[$Docs->{errno}] $Docs->{errstr} ID: $Docs->{DOC_ID} UID: $doc_uid \n";
      }
    }
    $total++;
  }

  if ($debug > 3) {
    print "\nTOTAL: $total\n";
  }

  return 1;
}

1
