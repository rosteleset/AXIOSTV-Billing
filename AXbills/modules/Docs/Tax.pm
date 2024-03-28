=head1 NAME

  Tax Documents

=cut

use strict;
use warnings FATAL => 'all';
use AXbills::Base qw(mk_unique_value convert);

our(
  $html,
  %conf,
  $db,
  %lang,
  $admin,
  %permissions,
  @MONTHES,
  @WEEKDAYS,
);

my $Docs = Docs->new( $db, $admin, \%conf );
my $Fees = Fees->new( $db, $admin, \%conf );

#**********************************************************
=head2 docs_tax_invoice_list($attr) docs_tax_invoice_list

=cut
#**********************************************************
sub docs_tax_invoice_list{
  my ($attr) = @_;

  my $debug = $attr->{DEBUG} || 0;

  if ( !$attr->{COMPANY} ){
    if ( $LIST_PARAMS{COMPANY_ID} || $FORM{COMPANY_ID} ){
      docs_tax_invoice();
      return 0 if ($FORM{'print'});
    }
    elsif ( defined( $FORM{del} ) && $FORM{COMMENTS} ){
      $Docs->tax_invoice_del( $FORM{del} );
      if ( !$Docs->{errno} ){
        $html->message( 'info', "$lang{INFO}", "$lang{DELETED} N: [$FORM{del}]" );
      }
      elsif ( _error_show( $Docs ) ){
        return 0;
      }
    }
    elsif ( $FORM{print} ){
      docs_tax_invoice();
      return 0;
    }
  }
  else{
    $index = $FORM{index};
  }

  form_search( { SEARCH_FORM =>
      ($conf{DOCS_PDF_PRINT}) ? '' : $html->tpl_show( _include( 'docs_search', 'Docs' ), { %FORM },
        { notprint => 1 } ) } );

  if ( !$FORM{sort} ){
    $LIST_PARAMS{SORT} = '2 DESC, 1 DESC';
    delete( $LIST_PARAMS{DESC} );
  }

  if ( $FORM{print_list} ){
    my $list = $Docs->tax_invoice_list(
      {
        %LIST_PARAMS,
        COMPANY_ID => $FORM{COMPANY_ID},
        FULL_INFO  => 1
      }
    );
    my @MULTI_ARR = ();
    my $doc_num = 0;

    foreach my $line ( @{$list} ){
      my %D = ();
      $D{NUMBER}       = $line->[0];
      $D{DATE}         = $line->[1];
      $D{COMPANY_NAME} = $line->[2];
      $D{ADDRESS}      = "$line->[11], $line->[12], $line->[13]";
      $D{TOTAL_SUM}    = sprintf( "%.2f", $line->[3] );

      if ( $conf{DOCS_VAT_INCLUDE} ){
        $D{ORDER_TOTAL_SUM_VAT} = sprintf( "%.2f",
          $D{TOTAL_SUM} / ((100 + $conf{DOCS_VAT_INCLUDE}) / $conf{DOCS_VAT_INCLUDE}) );
        $D{TOTAL_SUM_WITHOUT_VAT} = sprintf( "%.2f", $D{TOTAL_SUM} - $Docs->{ORDER_TOTAL_SUM_VAT} );
        $D{TOTAL_SUM_VAT} = sprintf( "%.2f", $conf{DOCS_VAT_INCLUDE} );
      }

      if ( $Docs->{TOTAL} > 0 ){
        $Docs->{FROM_DATE_LIT} = '';

        my $orders_list = $Docs->{ORDERS};
        my $i = 0;
        foreach my $order ( @{$orders_list} ){
          $i++;
          $Docs->{ORDER} .= sprintf(
            "<tr><td align=right>%d</td><td>%s</td><td align=right>%d</td><td align=right>%d</td><td align=right>%.2f</td><td align=right>%.2f</td></tr>\n"
            , $i,
            $order->[1],
            $order->[2],
            $order->[3],
            $order->[4],
            ($order->[2] * $order->[4]) ) if (!$conf{DOCS_PDF_PRINT});

          my $count = $order->[2] || 1;
          my $sum = sprintf( "%.2f", $count * $order->[4] );

          $D{ 'ORDER_NUM_' . $i } = $i;
          $D{ 'ORDER_NAME_' . $i } = $order->[1];
          $D{ 'ORDER_COUNT_' . $i } = $count;
          $D{ 'ORDER_PRICE_' . $i } = $order->[4];
          $D{ 'ORDER_SUM_' . $i } = $sum;
          $D{ 'ORDER_PRICE_WITHOUT_VAT_' . $i } = sprintf( "%.2f",
              ($conf{DOCS_VAT_INCLUDE}) ? $order->[4] - $order->[4] / ((100 + $conf{DOCS_VAT_INCLUDE}) / $conf{DOCS_VAT_INCLUDE}) : $order->[3] );
          $D{ 'ORDER_SUM_WITHOUT_VAT_' . $i } = sprintf( "%.2f",
              ($conf{DOCS_VAT_INCLUDE}) ? $sum - ($sum) / ((100 + $conf{DOCS_VAT_INCLUDE}) / $conf{DOCS_VAT_INCLUDE}) : $sum );
        }

        $D{'TOTAL_SUM_WITHOUT_VAT'} = sprintf( "%.2f",
            ($conf{DOCS_VAT_INCLUDE}) ? $D{TOTAL_SUM} - ($Docs->{TOTAL_SUM}) / ((100 + $conf{DOCS_VAT_INCLUDE}) / $conf{DOCS_VAT_INCLUDE}) : $D{TOTAL_SUM} );
        $Docs->{'TOTAL_SUM_VAT'} = sprintf( "%.2f", $D{TOTAL_SUM} - $Docs->{'TOTAL_SUM_WITHOUT_VAT'} );
      }

      push @MULTI_ARR, { %D, DOC_NUMBER => sprintf( "%.6d", $doc_num ), };
      $doc_num++;
      print "UID: LOGIN: $line->[0] FIO: $line->[1] SUM: $line->[2]\n" if ($debug > 2);
    }

    print $html->header() if ($FORM{qindex});
    $html->tpl_show(
      _include( 'docs_tax_invoice', 'Docs', { pdf => $FORM{pdf} } ),
      undef,
      {
        MULTI_DOCS => \@MULTI_ARR,
        debug      => $debug
      }
    );
    return 0;
  }

  my $list = $Docs->tax_invoice_list( { %LIST_PARAMS, COMPANY_ID => $FORM{COMPANY_ID} } );
  my $table = $html->table(
    {
      width      => '100%',
      caption    => $lang{TAX_INVOICE},
      title      => [ '#', $lang{DATE}, $lang{CUSTOMER}, $lang{SUM}, $lang{ADMIN}, $lang{TIME}, '-' ],
      qs         => $pages_qs,
      pages      => $Docs->{TOTAL},
      ID         => 'DOCS_TAX_INVOICE'
    }
  );

  foreach my $line ( @{$list} ){
    my $delete = ($permissions{1}{2}) ? $html->button( $lang{DEL},
        "index=$index&del=$line->[8]&COMPANY_ID=$line->[7]",
        { MESSAGE => "$lang{DEL} ID '$line->[8]' ?", class => 'del' } ) : '';

    $table->addrow(
      $line->[0],
      $line->[1],
      $html->button( $line->[2], "index=13&COMPANY_ID=$line->[7]" ),
      ,
      $line->[3],
      $html->button( $line->[4], "index=11&UID=$line->[7]" ),
      $line->[5],
      $html->button( $lang{PRINT},
        "qindex=$index&print=$line->[8]&UID=$line->[8]$pages_qs" . (($conf{DOCS_PDF_PRINT}) ? '&pdf=1' : ''),
        { ex_params => 'target=_new', class => 'print' } )
        .' '.$delete
    );
  }
  print $table->show();

  $table = $html->table(
    {
      width      => '100%',
      rows       => [ [ $html->button( "$lang{PRINT} $lang{LIST}",
          "qindex=$index&print_list=1$pages_qs" . (($conf{DOCS_PDF_PRINT}) ? '&pdf=1' : ''),
          { BUTTON => 1, ex_params => 'target=new' } ), "$lang{TOTAL}:", $html->b( $Docs->{TOTAL} ), "$lang{SUM}:",
        $html->b( $Docs->{SUM} ), ] ]
    }
  );

  print $table->show();

  delete( $LIST_PARAMS{SORT} );

  return 1;
}

#**********************************************************
=head2 docs_tax_invoice($attr)

=cut
#**********************************************************
sub docs_tax_invoice{
  my ($attr) = @_;

  my $Customer = Customers->new( $db, $admin, \%conf );
  my $Company  = $Customer->company();

  if($LIST_PARAMS{COMPANY_ID} || $FORM{COMPANY_ID}) {
    if (!$attr->{COMPANY} && !$FORM{qindex}) {
      $FORM{subf} = $FORM{index};
      require Control::Companies_mng;
      form_companies();
      return 0;
    }
    elsif ($FORM{qindex}) {
      $Company->info($FORM{COMPANY_ID});
    }
    else {
      $Company = $attr->{COMPANY};
    }
  }

  $Docs->{DATE} = $DATE;
  $Docs->{DONE_DATE} = $DATE;
  $Docs->{FROM_DATE} = $DATE;

  if ( $FORM{create} ){
    my $list = $Fees->reports(
      {
        MONTH   => $FORM{MONTH},
        BILL_ID => $Company->{BILL_ID},
        TYPE    => 'METHOD'
      }
    );

    if ( $Fees->{TOTAL} < 1 ){
      $html->message( 'info', $lang{INFO}, "$lang{FEES} $lang{NOT_EXIST}" );
    }

    my %FEES_METHODS = %{ get_fees_types() };

    my $i = 1;
    foreach my $line ( @{$list} ){
      $FORM{SUM} += $Fees->{SUM};
      $FORM{'IDS'} .= "$i, ";
      $FORM{'ORDER_' . $i } = $FEES_METHODS{ $line->[0] };
      $FORM{'COUNTS_' . $i } = '1';
      $FORM{'UNIT_' . $i } = '1';
      $FORM{'SUM_' . $i } = $line->[3];
      $i++;
    }

    #my ($y, $m) = split( /-/, $FORM{PERIOD} );
    #my $days_in_month = days_in_month( { DATE => $FORM{PERIOD} } );

    if ( defined( $FORM{OP_SID} ) and $FORM{OP_SID} eq $COOKIES{OP_SID} ){
      $html->message( 'err', $lang{ERROR}, "$lang{EXIST}" );
    }
    elsif ( !$FORM{SUM_1} && ($FORM{SUM} =~ /\d+/ && $FORM{SUM} < 0.01) ){
      $html->message( 'err', "$lang{ERROR}", $lang{WRONG_SUM} );
    }
    elsif ( $FORM{PREVIEW} ){
      docs_preview( 'tax_invoice', { %FORM } );
      return 0;
    }
    else{
      $FORM{COMPANY_ID} = $LIST_PARAMS{COMPANY_ID} if (!$FORM{COMPANY_ID});

      $Docs->tax_invoice_add( { %FORM, DATE => "$FORM{MONTH}-01" } );

      if ( !$Docs->{errno} ){
        $html->message( 'info', "$lang{ADDED}", "$lang{NUM}: [$Docs->{DOC_ID}]\n $lang{DATE}: $FORM{DATE}" );
        $Docs->tax_invoice_info( $Docs->{DOC_ID}, { COMPANY_ID => $LIST_PARAMS{COMPANY_ID} } );
        $Docs->{NUMBER} = $Docs->{DOC_ID};
        my $orders_list = $Docs->{ORDERS};
        $i = 0;

        foreach my $line ( @{$orders_list} ){
          $i++;
          $Docs->{ORDER} .= sprintf(
            "<tr><td align='right'  >%d</td><td>%s</td><td align='right'>%d</td><td align='right'>%d</td><td align='right'>%.2f</td><td align='right'>%.2f</td></tr>\n"
            , $i, $line->[1], $line->[2], $line->[3], $line->[4], ($line->[3] * $line->[4]) );

        }

        if ( $conf{DOCS_PDF_PRINT} ){
          $html->message( 'info', $lang{ADDED}, "$lang{TAX_INVOICE} $lang{ADDED}. \n" . $html->button( $lang{PRINT},
              "qindex=" . (($FORM{subf}) ? $FORM{subf} : $index) . "&print=$Docs->{DOC_ID}&UID=$LIST_PARAMS{UID}&COMPANY_ID=$FORM{COMPANY_ID}&pdf=1"
              , { ex_params => 'target=_new', class => 'print' } ) );
          return 0;
        }

        #print $html->header() if ($FORM{qindex});
        if ( $user->{UID} ){
          $FORM{qindex} = $index;
          $html->{NO_PRINT} = undef;

          docs_print( 'tax_invoice', { %{$Docs}, %{$Company} } );
          return 0;
        }
        else{
          docs_print( 'tax_invoice', { %{$Docs}, %{$Company} } );
        }

        $FORM{'print'} = 1;
        return 0;
      }
    }
  }
  elsif ( $FORM{print} ){
    docs_tax_print({ COMPENY => $Company });
    return 0;
  }
  elsif ( $FORM{change} ){
    $Docs->tax_invoice_change( { %FORM } );
    if ( !$Docs->{errno} ){
      $html->message( 'info', "$lang{INFO}", "$lang{CHANGED} N: [$FORM{DOC_ID}]" );
    }
  }
  elsif ( $FORM{chg} ){
    $Docs->tax_invoice_info( $FORM{chg} );
    if ( !$Docs->{errno} ){
      $html->message( 'info', "$lang{INFO}", "$lang{CHANGING} N: [$FORM{chg}]" );
    }
  }
  elsif ( $FORM{del} && $FORM{COMMENTS} ){
    $Docs->tax_invoice_del( $FORM{del} );
    if ( !$Docs->{errno} ){
      $html->message( 'info', "$lang{INFO}", "$lang{DELETED} N: [$FORM{del}]" );
    }
  }

  _error_show( $Docs );

  if ( !$user->{UID} ){
    $Docs->{FORM_INVOICE_ID} = "<tr><td>$lang{TAX_INVOICE} $lang{NUM}:</td><td><input type='text' name='INVOICE_ID' value='%INVOICE_ID%'></td></tr>\n";
  }

  $Docs->{SEL_ORDER} .= $html->form_select(
    'ORDER',
    {
      SELECTED  => $FORM{ORDER},
      SEL_ARRAY => ($conf{DOCS_ORDERS}) ? $conf{DOCS_ORDERS} : [ $lang{DV} ],
      NO_ID     => 1
    }
  );

  #$Docs->{COMPANY_VAT}=$user->{COMPANY_VAT}.' %';
  $Docs->{OP_SID} = mk_unique_value( 16 );
  $users->pi( { UID => $users->{UID} } );

  $Docs->{CUSTOMER} = $users->{FIO} || '-';
  $Docs->{CAPTION} = $lang{INVOICE};

  my ($Y, $M) = split( /-/, $DATE, 3 );
  my @MONTH_ARR = ('');
  for ( my $i = 1; $i < 13; $i++ ){
    my $m = sprintf( "%.2d", $i );
    push @MONTH_ARR, "$Y-$m";
  }
  $FORM{MONTH} = "$Y-$M" if (!$FORM{MONTH});

  my $table = $html->table(
    {
      width    => '100%',
      caption  => "$lang{TAX_INVOICE}",
      rowcolor => $_COLORS[0],
      rows     => [
        [
          "$lang{PERIOD}: ",
          $html->form_select(
            'MONTH',
            {
              SELECTED  => $FORM{MONTH},
              SEL_ARRAY => \@MONTH_ARR,
              NO_ID     => 1
            }
          ),
          "$lang{DATE}: ",
          $html->form_input( 'DATE', "$Y-$M-01" ),
          $html->form_input( 'show', $lang{CREATE}, { TYPE => "SUBMIT" } )
        ]
      ],
    }
  );

  print $html->form_main(
    {
      CONTENT => $table->show( { OUTPUT2RETURN => 1 } ),
      HIDDEN  => {
        COMPANY_ID => $FORM{COMPANY_ID},
        index      => $index,
        subf       => $FORM{subf},
        create     => 1
      }
    }
  );

  docs_tax_invoice_list( $attr );

  return 1;
}


#**********************************************************
=head2 docs_tax_print()

=cut
#**********************************************************
sub docs_tax_print {
  my($attr) = @_;

  my $Company = $attr->{COMPANY};

  $Docs->tax_invoice_info( $FORM{print}, { UID => $LIST_PARAMS{UID} } );

  $Docs->{TOTAL_SUM} //= 0;

  if ( $conf{DOCS_VAT_INCLUDE} ){
    $Docs->{ORDER_TOTAL_SUM_VAT} = sprintf( "%.2f",
      $Docs->{TOTAL_SUM} / ((100 + $conf{DOCS_VAT_INCLUDE}) / $conf{DOCS_VAT_INCLUDE}) );
    $Docs->{TOTAL_SUM_WITHOUT_VAT} = sprintf( "%.2f", $Docs->{TOTAL_SUM} - $Docs->{ORDER_TOTAL_SUM_VAT} );
    $Docs->{TOTAL_SUM_VAT} = sprintf( "%.2f", $conf{DOCS_VAT_INCLUDE} );
  }

  $Docs->{NUMBER} = $Docs->{DOC_ID};

  if ( $Docs->{TOTAL} > 0 ){
    $Docs->{FROM_DATE_LIT} = '';

    my $list = $Docs->{ORDERS};
    my $i = 0;
    foreach my $line ( @{$list} ){
      $i++;
      $Docs->{ORDER} .= sprintf(
        "<tr><td align=right>%d</td><td>%s</td><td align=right>%d</td><td align=right>%d</td><td align=right>%.2f</td><td align=right>%.2f</td></tr>\n"
        , $i, $line->[1], $line->[2], $line->[3], $line->[4], ($line->[2] * $line->[4]) );

      my $count = $line->[2] || 1;
      my $sum = sprintf( "%.2f", $count * $line->[4] );

      $Docs->{ 'ORDER_NUM_' . $i } = $i;
      $Docs->{ 'ORDER_NAME_' . $i } = $line->[1];
      $Docs->{ 'ORDER_COUNT_' . $i } = $count;
      $Docs->{ 'ORDER_PRICE_' . $i } = $line->[4];
      $Docs->{ 'ORDER_SUM_' . $i } = $sum;

      $Docs->{ 'ORDER_PRICE_WITHOUT_VAT_' . $i } = sprintf( "%.2f",
          ($conf{DOCS_VAT_INCLUDE}) ? $line->[4] - $line->[4] / ((100 + $conf{DOCS_VAT_INCLUDE}) / $conf{DOCS_VAT_INCLUDE}) : $line->[3] );
      $Docs->{ 'ORDER_SUM_WITHOUT_VAT_' . $i } = sprintf( "%.2f",
          ($conf{DOCS_VAT_INCLUDE}) ? $sum - ($sum) / ((100 + $conf{DOCS_VAT_INCLUDE}) / $conf{DOCS_VAT_INCLUDE}) : $sum );
    }

    $Docs->{'TOTAL_SUM'} = sprintf( "%.2f", $Docs->{TOTAL_SUM} );
    $Docs->{'TOTAL_SUM_WITHOUT_VAT'} = sprintf( "%.2f",
        ($conf{DOCS_VAT_INCLUDE}) ? $Docs->{TOTAL_SUM} - ($Docs->{TOTAL_SUM}) / ((100 + $conf{DOCS_VAT_INCLUDE}) / $conf{DOCS_VAT_INCLUDE}) : $Docs->{TOTAL_SUM} );
    $Docs->{'TOTAL_SUM_VAT'} = sprintf( "%.2f", $Docs->{TOTAL_SUM} - $Docs->{'TOTAL_SUM_WITHOUT_VAT'} );

    docs_print( 'tax_invoice', { %{$Docs}, %{$Company} } );
  }
  else{
    _error_show( $Docs );
  }

  return 1;
}


#**********************************************************
=head2 docs_tax_exports()

=cut
#**********************************************************
sub docs_tax_exports{

  if ( $FORM{d} ){
    my ($y, $m, undef) = split( /-/, ($FORM{MONTH}) ? $FORM{MONTH} . '-01' : $DATE );
    my $file_prefix = "26590025388695J120150510000000011";
    my $filename = $file_prefix . "$m$y" . '2659.xml';

    my ($fill_y, $fill_m, $fill_d) = split( /-/, ($FORM{DATE}) ? $FORM{DATE} : $DATE );
    $Docs->{FILL_DATE} = "$fill_d$fill_m$fill_y";

    $Docs->{YEAR} = $y;
    $Docs->{MONTH} = $m;

    my $doc = '';

    $LIST_PARAMS{PAGE_ROWS} = 1000000;
    $LIST_PARAMS{MONTH} = $FORM{MONTH} || "$y-$m";

    my $list = $Docs->tax_invoice_reports( { %LIST_PARAMS } );
    my %invoice_hash = ();

    my $num = 1;
    foreach my $line ( @{$list} ){
      push @{ $invoice_hash{T1RXXXXG1} }, $num;
      push @{ $invoice_hash{T1RXXXXG2D} }, $line->[1];
      push @{ $invoice_hash{T1RXXXXG3S} }, $line->[2];
      push @{ $invoice_hash{T1RXXXXG4S} }, 'ПН02';
      push @{ $invoice_hash{T1RXXXXG5S} }, $line->[3];

      push @{ $invoice_hash{T1RXXXXG6} }, '';                            # | $line->[3];
      push @{ $invoice_hash{T1RXXXXG7} }, sprintf( "%.2f", $line->[5] );
      push @{ $invoice_hash{T1RXXXXG8} }, sprintf( "%.2f", $line->[6] );
      push @{ $invoice_hash{T1RXXXXG9} }, sprintf( "%.2f", $line->[7] );

      push @{ $invoice_hash{T1RXXXXG10} }, '';
      push @{ $invoice_hash{T1RXXXXG11} }, '';
      push @{ $invoice_hash{T1RXXXXG12} }, '';
      $invoice_hash{R011G7} += $line->[5];
      $invoice_hash{R011G8} += $line->[6];
      $invoice_hash{R011G9} += $line->[7];
      $num++;
    }

    my @arr = ('T1RXXXXG1', 'T1RXXXXG2D', 'T1RXXXXG3S', 'T1RXXXXG4S', 'T1RXXXXG5S', 'T1RXXXXG7', 'T1RXXXXG8',
      'T1RXXXXG9', 'T1RXXXXG13', 'T1RXXXXG14', 'T1RXXXXG15', 'T1RXXXXG16',);

    foreach my $key ( @arr ){
      my $i = 1;
      foreach my $value ( @{ $invoice_hash{$key} } ){
        $doc .= ($value) ? "<$key ROWNUM=\"$i\">$value</$key>\n" : "<$key xsi:nil=\"true\" ROWNUM=\"$i\" />\n";
        $i++;
      }
    }

    $doc .= "
<R011G7>" . sprintf( "%.2f", $invoice_hash{R011G7} || 0) . "</R011G7>
<R011G8>" . sprintf( "%.2f", $invoice_hash{R011G8} || 0) . "</R011G8>
<R011G9>" . sprintf( "%.2f", $invoice_hash{R011G9} || 0) . "</R011G9>
<R011G12 xsi:nil=\"true\" />
<R012G7 xsi:nil=\"true\" />
<R012G8 xsi:nil=\"true\" />
<R012G9 xsi:nil=\"true\" />
<R012G10 xsi:nil=\"true\" />
<R012G11 xsi:nil=\"true\" />
<R012G12 xsi:nil=\"true\" />
<R021G8 xsi:nil=\"true\" />
<R021G9 xsi:nil=\"true\" />
<R021G10 xsi:nil=\"true\" />
<R021G11 xsi:nil=\"true\" />
<R021G12 xsi:nil=\"true\" />
<R021G13 xsi:nil=\"true\" />
<R021G14 xsi:nil=\"true\" />
<R021G15 xsi:nil=\"true\" />
<R021G16 xsi:nil=\"true\" />
<R022G8 xsi:nil=\"true\" />
<R022G9 xsi:nil=\"true\" />
<R022G10 xsi:nil=\"true\" />
<R022G11 xsi:nil=\"true\" />
<R022G12 xsi:nil=\"true\" />
<R022G13 xsi:nil=\"true\" />
<R022G14 xsi:nil=\"true\" />
<R022G15 xsi:nil=\"true\" />
<R022G16 xsi:nil=\"true\" />
<HFILL>$fill_d$m$y</HFILL>
";

    $doc = $html->tpl_show( _include( 'docs_tax_export', 'Docs' ), { %{$Docs}, BODY => $doc },
      { OUTPUT2RETURN => 1, SKIP_QUOTE => 1 } );
    $doc = convert( $doc, { utf82win => 1 } );

    my $filesize = length( $doc );
    print "Content-Type: text/plain; filename=\"$filename\"\n"
      . "Content-Disposition: attachment; filename=\"$filename\" size=$filesize;"
      . "\n\n";

    print $doc;

    return 0;
  }

  my @MONTH_ARR = ('');
  my ($Y, $M, undef) = split( /-/, $DATE, 3 );
  for ( my $year = 2009; $year <= $Y; $year++ ){
    for ( my $i = 1; $i < 13; $i++ ){
      my $m = sprintf( "%.2d", $i );
      push @MONTH_ARR, "$year-$m";
    }
  }

  $FORM{MONTH} = "$Y-$M" if (!$FORM{MONTH});

  my $table = $html->table(
    {
      width    => '500',
      caption  => "$lang{EXPORT} - $lang{TAX_INVOICE}",
      rowcolor => $_COLORS[0],
      rows     => [
        [
          "$lang{PERIOD}: ",
          $html->form_select(
            'MONTH',
            {
              SELECTED  => $FORM{MONTH},
              SEL_ARRAY => \@MONTH_ARR,
              NO_ID     => 1
            }
          ),
          "$lang{CREATED}: ",
          $html->date_fld2( 'DATE',
            { MONTHES => \@MONTHES, FORM_NAME => 'TAX_EXPORT', WEEK_DAYS => \@WEEKDAYS, DATE => "$Y-$M-01" } ),
          $html->form_input( 'show', $lang{CREATE}, { TYPE => "SUBMIT" } )
        ]
      ],
    }
  );

  print $html->form_main(
    {
      CONTENT => $table->show( { OUTPUT2RETURN => 1 } ),
      HIDDEN  => {
        qindex => $index,
        subf   => $FORM{subf},
        create => "1",
        d      => 1
      },
      NAME    => 'TAX_EXPORT'
    }
  );

  return 1;
}


1;