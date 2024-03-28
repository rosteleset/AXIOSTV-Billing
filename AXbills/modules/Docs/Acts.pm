=head1 NAME

  ACts

=cut

use strict;
use warnings FATAL => 'all';
use AXbills::Base qw(days_in_month mk_unique_value);

our(
  %conf,
  $db,
  %lang,
  $admin,
  %permissions,
  @MONTHES,
  @WEEKDAYS,
  @units
);

my $Docs = Docs->new( $db, $admin, \%conf );
my $Fees = Fees->new( $db, $admin, \%conf );
my $Payments = Payments->new( $db, $admin, \%conf );
our AXbills::HTML $html;

#**********************************************************
=head2 docs_acts_list($attr)

  Arguments:
    $attr
      COMPANY

  Results:


=cut
#**********************************************************
sub docs_acts_list{
  my ($attr) = @_;

  if ( !$attr->{COMPANY} ){
    if ( $LIST_PARAMS{COMPANY_ID} || $FORM{COMPANY_ID} ){
      docs_acts({ COMPANY_ID => $LIST_PARAMS{COMPANY_ID} || $FORM{COMPANY_ID} });
      return 0 if ($FORM{'print'});
    }
    elsif ( defined( $FORM{del} ) && $FORM{COMMENTS} ){
      $Docs->act_del( $FORM{del} );
      if ( !$Docs->{errno} ){
        $html->message( 'info', "$lang{INFO}", "$lang{DELETED} N: [$FORM{del}]" );
      }
      elsif ( _error_show( $Docs ) ){
        return 0;
      }
    }
    elsif ( $FORM{print} || $FORM{cert} ){
      docs_acts();
      return 0;
    }
  }
  else{
    $index = $FORM{index} || 0;
  }

  if ( $FORM{search_form} ){
    form_search(
      {
        SEARCH_FORM     => ($FORM{pdf}) ? '' : $html->tpl_show( _include( 'docs_search', 'Docs' ), { %FORM },
            { notprint => 1 } ),
        HIDDEN_FIELDS => { COMPANY_ID => $FORM{COMPANY_ID} || undef }
      }
    );
  }

  #  Date  Customer  Sum  User  Administrators  Time
  if ( ! $FORM{sort} ){
    $LIST_PARAMS{SORT} = 2;
    $LIST_PARAMS{DESC} = 'DESC';
  }

  delete $LIST_PARAMS{LOGIN} if($user && $user->{UID});

  my $docs_acts = get_function_index( 'docs_acts_list' );

  # user portal
  if ($FORM{sid} ){
    require Companies;
    Companies->import();
    my $Company = Companies->new($db, $admin, \%conf);
    my $company_index = get_function_index('form_companies');

    my $company_admin = $Company->admins_list({UID => $user->{UID}, GET_ADMINS => 1, COLS_NAME => 1});

    $FORM{COMPANY_ID} = $company_admin->[0]->{company_id};
    $index = $company_index;
    $FORM{subf} = $docs_acts;
    $LIST_PARAMS{UID} = '';
  }

  my $list = $Docs->acts_list( {
    ACT_ID       => '_SHOW',
    DATE         => '_SHOW',
    COMPANY_NAME => '_SHOW',
    SUM          => '_SHOW',
    ADMIN_NAME   => '_SHOW',
    CREATED      => '_SHOW',
    START_PERIOD => '_SHOW',
    END_PERIOD   => '_SHOW',
    SKIP_DEL_CHECK=>1,
    %LIST_PARAMS,
    COMPANY_ID   => $FORM{COMPANY_ID},
    COLS_NAME    => 1
  });

  _error_show($Docs);

  my $table = $html->table({
    width      => '100%',
    caption    => $lang{ACTS},
    title      => [ '#', "$lang{ACT} $lang{DATE}", $lang{CUSTOMER}, $lang{SUM}, $lang{ADMIN}, $lang{PERIOD}, $lang{CREATED} , '-' ],
    qs         => $pages_qs,
    pages      => $Docs->{TOTAL},
    MENU       => "$lang{SEARCH}:index=" . ($index || 0)
         ."&search_form=1&COMPANY_ID=" . ($LIST_PARAMS{COMPANY_ID} || '') . ":search",
    ID         => 'DOCS_TAX_INVOICE'
  });

  if ( $FORM{subf} ){
    $pages_qs = '&subf=' . $FORM{subf};
  }

  my $total_acts_sum = 0;
  foreach my $line ( @{$list} ){
    $table->addrow(
      $line->{act_id},
      $line->{date},
      (defined($FORM{sid})) ? $line->{company_name} : $html->button( $line->{company_name} || $line->{fio}, "index=13&COMPANY_ID=$line->{company_id}" ),
      $line->{sum},
      (defined($FORM{sid})) ? $line->{admin_name} : $html->button( $line->{admin_name}, "index=11&UID=$line->{uid}" ),
      "$line->{start_period}/$line->{end_period}",
      $line->{created},
      (($conf{DOCS_CERT_CMD}) ? $html->button( $lang{SAVE_CONTROL_SUM},
        "qindex=$index&cert=$line->{id}&COMPANY_ID=". ($line->{company_id} || q{}) . (($conf{DOCS_PDF_PRINT}) ? '&pdf=1' : '') . (($pages_qs) ? $pages_qs : ""),
          { ex_params => 'target=_new', ICON => 'fa fa-certificate' } ) : q{})
        . $html->button( $lang{PRINT},
          "qindex=$index&print=$line->{id}&COMPANY_ID=". ($line->{company_id} || q{}) . (($conf{DOCS_PDF_PRINT}) ? '&pdf=1' : '') . (($pages_qs) ? $pages_qs : ""),
          { ex_params => 'target=_new', class => 'print' } )
        . (($permissions{1} && $permissions{1}{2}) ? ' '.$html->button( $lang{DEL},
          "index=$index$pages_qs&del=$line->{id}&COMPANY_ID=". ($line->{company_id} || q{})
          ,
          { MESSAGE => "$lang{DEL} ID '$line->{id}' ?", class => 'del' } ) : '')
    );

    $total_acts_sum  += $line->{sum} if ($line->{sum});
  }
  print $table->show();

  $table = $html->table({
    width      => '100%',
    rows       => [ [
      #$html->button("$lang{PRINT} $lang{LIST}", "qindex=$index&print_list=1$pages_qs" . (($conf{DOCS_PDF_PRINT}) ? '&pdf=1' : ''), { BUTTON => 1, ex_params => 'target=new' }),
      "$lang{TOTAL}:", $html->b( $Docs->{TOTAL} ), "$lang{SUM}:", $html->b( $total_acts_sum ), ] ]
  });

  print $table->show();

  return 1;
}

#**********************************************************
=head2 docs_acts($attr) - docs_acts

  Arguments:
    $attr

  Results:

=cut
#**********************************************************
sub docs_acts{
  my ($attr) = @_;

  my $Customer = Customers->new( $db, $admin, \%conf );
  my $Company  = $Customer->company();
  my $uid      = $FORM{UID} || $LIST_PARAMS{UID};

  if($FORM{COMPANY_ID}) {
    if (!$attr->{COMPANY} && !$FORM{qindex}) {
      $FORM{subf} = $FORM{index};
      $index = 13;
      require Control::Companies_mng;
      form_companies();
      return 0;
    }
    elsif ($FORM{qindex}) {
      $Company->info($LIST_PARAMS{COMPANY_ID} || $FORM{COMPANY_ID});
    }
    else {
      $Company = $attr->{COMPANY};
    }
    $attr->{COMPANY}=$Company;
  }
  elsif($uid) {
    $users = $user if(! $users && $user);
    $users->info($uid);
  }

  #  require Dv_Sessions;
  #  Dv_Sessions->import();
  #  my $Sessions = Dv_Sessions->new( $db, $admin, \%conf );

  $Docs->{DATE} = $FORM{DATE} || $DATE;
  $Docs->{DONE_DATE} = $DATE;
  $Docs->{FROM_DATE} = $DATE;

  if ( $FORM{create} ){
    docs_acts_create({
      COMPANY  => $Company,
      USER_INFO=> $users
    });
  }
  elsif ( $FORM{print} || $FORM{cert} ){
    docs_acts_print({
      COMPANY  => $Company,
      USER_INFO=> $users,
      DOC_ID   => $FORM{cert} || $FORM{print},
      CERT     => $FORM{cert}
    });

    return 0;
  }
  elsif ( $FORM{change} ){
    $Docs->act_change( { %FORM } );

    if ( !$Docs->{errno} ){
      $html->message( 'info', "$lang{INFO}", "$lang{CHANGED} N: [$FORM{DOC_ID}]" );
    }
  }
  elsif ( $FORM{chg} ){
    $Docs->act_info( $FORM{chg} );

    if ( !$Docs->{errno} ){
      $html->message( 'info', "$lang{INFO}", "$lang{CHANGING} N: [$FORM{chg}]" );
    }
  }
  elsif ( $FORM{del} && $FORM{COMMENTS} ){
    $Docs->act_del( $FORM{del} );
    if ( !$Docs->{errno} ){
      $html->message( 'info', "$lang{INFO}", "$lang{DELETED} N: [$FORM{del}]" );
    }
  }

  if ( !$user->{UID} ){
    $Docs->{FORM_INVOICE_ID} = "<tr><td>$lang{TAX_INVOICE} $lang{NUM}:</td><td><input type='text' name='INVOICE_ID' value='%INVOICE_ID%'></td></tr>\n";
  }

  $users->pi( { UID => $uid } );
  $Docs->{CUSTOMER} = $users->{FIO} || '-';
  $Docs->{CAPTION} = $lang{INVOICE};
  $Docs->{OP_SID} = mk_unique_value( 16 );

  my ($Y, $M, undef) = split( /-/, $DATE, 3 );
  my @MONTH_ARR = ('');
  my $select_year = $Y - 1;
  for ( my $i = 1; $i < 13; $i++ ){
    push @MONTH_ARR, sprintf( "%d-%.2d", $select_year, $i );
    if($i==12 && $select_year < $Y) {
      $select_year++;
      $i=0;
    }
  }

  $FORM{MONTH} = "$Y-$M" if (!$FORM{MONTH});

  my @rows = (
    "$lang{PERIOD}: ",
    $html->form_select('MONTH', {
      SELECTED  => $FORM{MONTH},
      SEL_ARRAY => \@MONTH_ARR,
      NO_ID     => 1
    }),
    "$lang{ACT} $lang{DATE}: ",
    $html->form_input( 'DATE', $FORM{DATE}, { class => 'form-control datepicker' } ),
    $lang{PREVIEW}.': '. $html->form_input( 'PREVIEW', 1, { TYPE => 'checkbox', STATE => $FORM{PREVIEW} } ),
    $html->form_input( 'show', $lang{CREATE}, { TYPE => "SUBMIT" } ),
  );

  my %info = ();
  foreach my $val (@rows) {
    $info{ROWS} .= $html->element('div', $val, { class => 'form-group d-inline-block pr-1' });
  }

  my $report_form = $html->element('div', $info{ROWS}, {
    class => 'breadcrumb card bg-light w-100 text-center'
  });

  print $html->form_main({
    CONTENT => $report_form,
    HIDDEN  => {
      COMPANY_ID => $FORM{COMPANY_ID},
      UID        => $uid,
      subf       => $FORM{subf},
      index      => $index,
      create     => 1
    },
    METHOD  => 'get',
    class   => 'form-inline',
  });

  if ($Company) {
    $attr->{COMPANY} = $Company;
  }

  docs_acts_list( $attr );

  return 1;
}

#**********************************************************
=head2 docs_acts_create ($attr) - docs_acts

   Arguments:
     COMPANY
     DOC_ID

=cut
#**********************************************************
sub docs_acts_create {
  my ($attr) = @_;

  my $Company  = $attr->{COMPANY};
  my $User_info= $attr->{USER_INFO};
  my $FEES_METHODS = get_fees_types();

  my $debug = $FORM{DEBUG} || 0;

  if($debug > 6) {
    $Fees->{debug}=1;
    $Payments->{debug}=1;
  }

  my $list = $Fees->list( {
    MONTH     => $FORM{MONTH},
    BILL_ID   => $Company->{BILL_ID} || $User_info->{BILL_ID},
    DESCRIBE  => '_SHOW',
    SUM       => '_SHOW',
    DATETIME  => '_SHOW',
    COLS_NAME => 1
  } );

  if ( $Fees->{TOTAL} < 1 ){
    $html->message( 'info', $lang{INFO}, "$lang{FEES} $lang{NOT_EXIST}" );
    return 0;
  }

  my $i = 1;
  my @arr = ();
  my %act_information = (
    UID => $User_info->{UID},
    COMPANY_ID => $Company->{COMPANY_ID} || $attr->{USER_INFO}->{COMPANY_ID}
  );

  foreach my $line ( @{$list} ){
    push @arr, $i;
    $act_information{'FEES_ID_' . $i} = $line->{id};
    $act_information{'ORDER_' . $i} = $line->{dsc} || (($line->{method}) ? $FEES_METHODS->{$line->{method}} : '');
    $act_information{'DATE_' . $i} = $line->{datetime};
    $act_information{'SUM_' . $i} = $line->{sum};
    $i++;
  }

  #Get payments
  $list = $Payments->list( {
    MONTH     => $FORM{MONTH},
    BILL_ID   => $Company->{BILL_ID} || $User_info->{BILL_ID},
    DESCRIBE  => '_SHOW',
    SUM       => '_SHOW',
    DATE      => '_SHOW',
    METHOD    => 6,
    COLS_NAME => 1
  });

  foreach my $line ( @{$list} ){
    push @arr, $i;
    $act_information{'ORDER_' . $i} = $line->{dsc};
    $act_information{'SUM_' . $i} = '-' . $line->{sum};
    $i++;
  }

  $act_information{'IDS'} = join( ', ', @arr );

  #Get internet using
  #    my $report_list = $Sessions->reports(
  #      {
  #        INTERVAL   => $interval,
  #        TP_ID      => $TP_ID,
  #        COMPANY_ID => $FORM{COMPANY_ID}
  #      }
  #    );

  if ( $FORM{OP_SID} && $FORM{OP_SID} eq $COOKIES{OP_SID} ){
    $html->message( 'err', $lang{ERROR}, $lang{EXIST}, { ID => 571 } );
  }
  elsif ( !$act_information{SUM_1}) { # && $act_information{SUM} < 0.01 ){
    $html->message( 'err', $lang{ERROR}, $lang{WRONG_SUM}, { ID => 572 } );
  }
#  elsif ( $FORM{PREVIEW} ){
#    docs_preview( 'acts', { %FORM } );
#    return 0;
#  }
  else{
    $act_information{COMPANY_ID} = $LIST_PARAMS{COMPANY_ID} if (!$act_information{COMPANY_ID});
    $act_information{UID} = $LIST_PARAMS{UID} if (!$act_information{UID});

    if($FORM{DATE}) {
      $act_information{DATE} = $FORM{DATE};
    }
    else {
      if ($conf{DOCS_ACTS_LAST_DATE}) {
        $act_information{DATE} = "$FORM{MONTH}-" . days_in_month({ DATE => $FORM{MONTH} });
      }
      else {
        $act_information{DATE} = $FORM{DATE} || "$FORM{MONTH}-01";
      }
    }

    if($FORM{MONTH}) {
      $act_information{START_PERIOD} = "$FORM{MONTH}-01";
      $act_information{END_PERIOD} = "$FORM{MONTH}-" . days_in_month({ DATE => $FORM{MONTH} });
    }

    if($FORM{PREVIEW}) {
      my $table = $html->table({
        width   => '100%',
        caption => "$lang{ACT} ($lang{PREVIEW}) $lang{DATE}: $act_information{DATE}",
        title   => [ '#', "$lang{DATE} $lang{FEES} ", $lang{DESCRIBE}, "$lang{PAYMENTS} $lang{SUM}", "$lang{FEES} ID" ],
        qs      => $pages_qs,
        ID      => 'DOCS_ACTS'
      });

      if($act_information{IDS}) {
        foreach my $num (split(/,\s?/, $act_information{IDS})) {
          $table->addrow($num,
            $act_information{'DATE_' . $num},
            _translate($act_information{'ORDER_' . $num}),
            $act_information{'SUM_' . $num},
            ($act_information{'FEES_ID_' . $num} || q{})
          );
        }
      }

      print $table->show();
    }
    else {
      $Docs->act_add({ %act_information });
    }

    _error_show( $Docs, { ID => 573, MESSAGE => "$lang{DATE}: $FORM{MONTH}-01" } );
  }

  return 1;
}

#**********************************************************
=head2 docs_acts_print($attr) - docs_acts

   Arguments:
     COMPANY
     DOC_ID

=cut
#**********************************************************
sub docs_acts_print {
  my ($attr) = @_;

  my $Company = $attr->{COMPANY};
  my $doc_id = $attr->{DOC_ID};
  my $uid = (defined($FORM{sid})) ? '' : $LIST_PARAMS{UID};

  $Docs->act_info($doc_id, { UID => $uid } );

  if ( $Docs->{TOTAL} > 0 ){
    $Docs->{TOTAL_SUM} //= 0;
    $Docs->{FROM_DATE_LIT} = '';
    $Docs->{'TOTAL_SUM'} = sprintf( "%.2f", $Docs->{TOTAL_SUM} );
    $Docs->{'TOTAL_SUM_WITHOUT_VAT'} = sprintf( "%.2f",
        ($conf{DOCS_VAT_INCLUDE}) ? $Docs->{TOTAL_SUM} - ($Docs->{TOTAL_SUM}) / ((100 + $conf{DOCS_VAT_INCLUDE}) / $conf{DOCS_VAT_INCLUDE}) : $Docs->{TOTAL_SUM} );
    $Docs->{'TOTAL_SUM_VAT'} = sprintf( "%.2f", $Docs->{TOTAL_SUM} - $Docs->{'TOTAL_SUM_WITHOUT_VAT'} );

    $Docs->{TOTAL_SUM} = 0.00;
    if ( $Docs->{ORDERS} ){
      my $i = 1;
      $Docs->{ORDER} = '';

      foreach my $line ( @{ $Docs->{ORDERS} } ){
        my $sum = sprintf( "%.2f", $line->{counts} * $line->{price} );

        $Docs->{ORDER} .= $html->tpl_show(
          _include( 'docs_act_order_row', 'Docs' ),
          {
            %{$Docs},
            NUMBER => $i,
            NAME   => $line->{orders},
            COUNT  => $line->{counts} || 1,
            UNIT   => $units[$line->{unit}] || 1,
            PRICE  => $line->{price},
            SUM    => $sum
          },
          { OUTPUT2RETURN => 1 }
        ) if (!$FORM{pdf});

        $Docs->{ 'ORDER_NUM_' . $i } = $i;
        $Docs->{ 'ORDER_NAME_' . $i } = $line->{orders};
        $Docs->{ 'ORDER_COUNT_' . $i } = $line->{counts};
        $Docs->{ 'ORDER_PRICE_' . $i } = $line->{price};
        $Docs->{ 'ORDER_SUM_' . $i } = $sum;
        $Docs->{ 'ORDER_PRICE_WITHOUT_VAT_' . $i } = sprintf( "%.2f",
            ($conf{DOCS_VAT_INCLUDE}) ? $line->{price} - $line->{price} / ((100 + $conf{DOCS_VAT_INCLUDE}) / $conf{DOCS_VAT_INCLUDE}) : $line->{price} );
        $Docs->{ 'ORDER_SUM_WITHOUT_VAT_' . $i } = sprintf( "%.2f",
            ($conf{DOCS_VAT_INCLUDE}) ? $sum - $sum / ((100 + $conf{DOCS_VAT_INCLUDE}) / $conf{DOCS_VAT_INCLUDE}) : $sum );
        $i++;

        $Docs->{TOTAL_SUM} += $sum;
      }
    }

    my ($y, $m)=split(/\-/, $Docs->{DATE}, 3);
    $Docs->{MONTH_LAST_DAY}="$y-$m-".  days_in_month({ DATE => "$y-$m" });
    $Docs->{TOTAL_SUM}     = sprintf( "%.2f", $Docs->{TOTAL_SUM} );
    $Docs->{TOTAL_ORDERS}  = $Docs->{TOTAL} || 0;

    return docs_print( 'act', {
      %{($attr) ? $attr : {}},
      %{$Docs},
      %{$Company},
      SUFIX => ($Company->{VAT} && $Company->{VAT} > 0) ? 'vat' : '',
      #FILE_NAME => 'Act_'.$Docs->{DOC_ID},
      CERT  => $attr->{CERT},
      DOCS  => $Docs
    } );
  }
  else{
    print "Content-Type: text/html\n\n";
    _error_show($Docs, { MESSAGE => "ID: $doc_id"  });
  }

  return 1;
}

1;