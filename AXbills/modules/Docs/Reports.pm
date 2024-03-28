=head1 NAME

  Docs Reports

=cut

use strict;
use warnings FATAL => 'all';
use AXbills::Base qw(date_inc);
use Docs;

our(
  %lang,
  $html,
  $db,
  $admin,
  %conf
);

my $Docs = Docs->new($db, $admin, \%conf);

#**********************************************************
=head2 docs_reports()

=cut
#**********************************************************
sub docs_reports{

  my %docs_type = (
    ACTS     => $lang{ACTS},
    INVOICES => $lang{INVOICES},
    RECEIPTS => $lang{RECEIPT}
  );

  my $doc_select = $html->form_select(
    'DOCS_TYPES',
    {
      NO_ID       => 1,
      SEL_HASH    => \%docs_type,
      SELECTED    => $FORM{DOCS_TYPES} || 'ACTS',
    }
  );

  require Control::Reports;
  reports(
    {
      DATE_RANGE        => 1,
      REPORT            => '',
      NO_GROUP          => 1,
      NO_STANDART_TYPES => 1,
      NO_TAGS           => 1,
      EXT_SELECT        => $doc_select,
      EXT_SELECT_NAME   => $lang{DOCS},
      PERIOD_FORM       => 1,
      EXT_TYPE          => { DOCS => $lang{DOCS} },
    }
  );
  my $doc_list;

  my $field_date_name = 'date';

  #Take list of select doc type. Standart type ACTS if no selected type
  if(!$FORM{DOCS_TYPES} || $FORM{DOCS_TYPES} eq 'ACTS'){

    $doc_list = $Docs->acts_list( {
      PAGE_ROWS => 1000000,
      SORT      => 'DATE',
      ACT_ID    => '_SHOW',
      DATE      => '_SHOW',
      DATETIME  => '_SHOW',
      SUM       => '_SHOW',
      COLS_NAME => 1
    });

    $FORM{DOCS_TYPES} = 'ACTS';
  }
  elsif($FORM{DOCS_TYPES} eq 'INVOICES'){

    $doc_list = $Docs->invoices_list( {
      PAGE_ROWS   => 1000000,
      SORT        => 'DATE',
      ORDERS_LIST => 1,
      DATETIME    => '_SHOW',
      DATE        => '_SHOW',
      COLS_NAME   => 1,
      COLS_UPPER  => 1
    });
  }
  elsif($FORM{DOCS_TYPES} eq 'RECEIPTS'){

    $doc_list = $Docs->docs_receipt_list({
      PAGE_ROWS => 1000000,
      SORT      => 'DATETIME',
      DATETIME  => '_SHOW',
      DATE      => '_SHOW',
      COLS_NAME => 1,
    });

    $field_date_name = 'datetime';
  }

  #my $i = -1;
  my @x_column_name;
  my %column_date;
  #my %date_list;

  if($FORM{"FROM_DATE_TO_DATE"}){
    ($FORM{FROM_DATE}, $FORM{TO_DATE}) = $FORM{"FROM_DATE_TO_DATE"} =~/(.+)\/(.+)/;
  }
  if (!($FORM{FROM_DATE} && $FORM{TO_DATE})) {
    $FORM{FROM_DATE}           = $DATE;
    $FORM{TO_DATE}             = $DATE;
    $FORM{"FROM_DATE_TO_DATE"} = "$DATE/$DATE";
  }
  my $from_date = $FORM{FROM_DATE};

  my $date_num = -1;
  my %date_chart_index;

  if ($FORM{FROM_DATE} && $FORM{TO_DATE} && $FORM{FROM_DATE} ne $FORM{TO_DATE}) {
    push @x_column_name, $FORM{FROM_DATE};
    $date_num++;
    $column_date{ $lang{ $FORM{DOCS_TYPES} } }[ $date_num ] = '0.00';
    $date_chart_index{$FORM{FROM_DATE}} = $date_num;
    my $num=0;

    while ($from_date ne $FORM{TO_DATE}) {
      $from_date = date_inc($from_date);
      push @x_column_name, $from_date;
      $date_chart_index{$from_date} = $date_num;
      $column_date{ $lang{ $FORM{DOCS_TYPES} } }[ $date_num++ ] = '0.00';
      ++$num;

      if($num > 80000){
        $from_date = $FORM{TO_DATE};
      }
    }
  }

  foreach my $line (@{$doc_list}) {
    if($date_chart_index{$line->{$field_date_name}}){
      $column_date{ $lang{ $FORM{DOCS_TYPES} } }[$date_chart_index{$line->{$field_date_name}}] += 1;
    }
  }

  my %column_type = (
    $FORM{DOCS_TYPES}  => 'COLUMN',
  );

  $html->make_charts_simple(
    {
      TRANSITION    => 1,
      TYPES         => \%column_type,
      X_TEXT        => \@x_column_name, # name x admin login
      DATA          => \%column_date,
    }
  );

  return 1;
}

#**********************************************************
=head2 docs_unpaid_invoices()

=cut
#**********************************************************
sub docs_unpaid_invoices {

  my %invoices_type = (
    ALL      => $lang{ALL},
    UNPAID   => $lang{UNPAID},
    PAID     => $lang{PAID}
  );

  my $type_select = $html->form_select(
    'INVOICES_TYPES',
    {
      NO_ID       => 1,
      SEL_HASH    => \%invoices_type,
      SELECTED    => $FORM{INVOICES_TYPES} || 'UNPAID',
    }
  );

  require Control::Reports;
  reports({
    DATE_RANGE        => 1,
    REPORT            => '',
    NO_STANDART_TYPES => 1,
    EXT_SELECT        => $type_select,
    EXT_SELECT_NAME   => $lang{INVOICES},
    PERIOD_FORM       => 1,
  });

  my $list = $Docs->docs_invoice_reports({
    LOGIN => '_SHOW',
    %FORM,
  });

  my $table = $html->table({
    caption => $lang{INVOICES},
    width   => '100%',
    qs      => $pages_qs,
    pages   => $Docs->{TOTAL},
    title   => [ $lang{NUMBER}, $lang{DATE}, $lang{USER}, $lang{SUM}, $lang{PAID} ],
    ID      => 'INVOICES_REPORT',
  });

  foreach my $line (@$list) {
    $table->addrow($line->{invoice_num}, $line->{date}, $line->{customer}, $line->{total_sum}, $line->{payment_sum} || 0);
  }

  print $table->show();

  return 1;
}

1;