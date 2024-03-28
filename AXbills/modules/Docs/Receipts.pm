=head1 NAME



=cut


use strict;
use warnings FATAL => 'all';
use AXbills::Base qw(mk_unique_value days_in_month cfg2hash);

our (
  $db,
  $admin,
  %conf,
  %lang,
  @units,
  @MONTHES,
  @WEEKDAYS,
  @MONTHES_LIT,
  %permissions,
  $users
);

my $Docs     = Docs->new( $db, $admin, \%conf );
my $Payments = Payments->new( $db, $admin, \%conf );
our AXbills::HTML $html;
my $debug    = 0;

#**********************************************************
=head2 docs_receipt_add($attr)

  Order array format
    NAME|UNIT|COUNT|PRICE

=cut
#**********************************************************
sub docs_receipt_add {
  my ($attr) = @_;

  my $PAYMENTS_METHODS;

  if ( $attr->{create} ){
    if ( defined( $FORM{OP_SID} ) and $FORM{OP_SID} eq ($COOKIES{OP_SID} || '') ){
      $html->message( 'err', $lang{ERROR}, "$lang{RECEIPT} $lang{EXIST}" );
      return 0;
    }
    elsif ( $FORM{PREVIEW} ){
      docs_preview( 'receipt', { %FORM } );
      return 0;
    }
    else{
      $Docs->{FROM} = $attr->{FROM} if ($attr->{FROM});
      $Docs->docs_receipt_add( { %{$attr}, DEPOSIT => $users->{DEPOSIT} } );
      my $date = $FORM{DATE} || $DATE;

      if ( !$Docs->{errno} ){
        my $index = get_function_index('docs_receipt_list');
        if ( $conf{DOCS_PDF_PRINT} ){
          $html->message(
            'info',
            "$lang{RECEIPT} $lang{ADDED} ",
            "$lang{RECEIPT} $lang{NUM}: [$Docs->{DOC_ID}]\n $lang{DATE}: $date\n "
              . $html->button( "$lang{SEND} E-mail",
              "qindex=$index&sendmail=$Docs->{DOC_ID}&UID=$LIST_PARAMS{UID}",
              { ex_params => 'target=_new', class => 'sendmail' } ) . ' '
              . $html->button( $lang{PRINT},
              "qindex=$index&print=$Docs->{DOC_ID}&&RECEIPT_ID=$Docs->{DOC_ID}&UID=$LIST_PARAMS{UID}&pdf=1"
              , { ex_params => 'target=_new', class => 'print' } )
          );

          delete( $FORM{create} );

          $FORM{print} = $Docs->{DOC_ID};
          $FORM{pdf} = 1;

          return docs_receipt(
            {
              GET_EMAIL_INFO => $FORM{SEND_EMAIL},
              SEND_EMAIL     => $FORM{SEND_EMAIL},
              DOC_INFO       => $Docs,
              %{$attr}
            }
          );
        }
        else{
          $html->message(
            'info',
            "$lang{RECEIPT} $lang{ADDED}",
            "$lang{RECEIPT} $lang{NUM}: [$Docs->{DOC_ID}]\n $lang{DATE}: $date\n"
              . $html->button( "$lang{SEND_MAIL}",
              "qindex=$index&sendmail=$Docs->{DOC_ID}&UID=$LIST_PARAMS{UID}",
              { ex_params => 'target=_new', class => 'sendmail' } ) . ' '
              . $html->button( $lang{PRINT},
              "qindex=$index&print=$Docs->{DOC_ID}&UID=$LIST_PARAMS{UID}",
              { ex_params => 'target=_new', class => 'print' } )
              . (defined($conf{DOCS_INVOICE_TERMO_PRINTER}) ?
                $html->button('',
              "qindex=$index&print=$Docs->{DOC_ID}&UID=$LIST_PARAMS{UID}&termo_printer_tpl=1",
              { ex_params => 'target=_new', class => 'fas fa-print text-warning', TITLE => $lang{PRINT_TERMO_PRINTER}} ) : ' ')
          );
        }
      }
      elsif ( $Docs->{errno} ){
        if ( $Docs->{errno} == 1 ){
          $html->message( 'err', "$lang{RECEIPT}:$lang{ERROR}", "$lang{ERR_NO_ORDERS}" );
        }
        else{
          _error_show( $Docs, { MESSAGE => $lang{RECEIPT} } );
        }
        return 0;
      }
    }
  }

  $Docs->{TOTAL_SUM} = 0.00;
  if ( $Docs->{ORDERS} ){
    my $i = 1;
    my @ORDERS = @{ $Docs->{ORDERS} };
    $Docs->{ORDER} = '';
    foreach my $line ( @ORDERS ){
      my $sum = sprintf( "%.2f", $line->[3] * $line->[4] );

      $Docs->{ORDER} .= "<tr><th align='right'>$i</th><td align='left'>$line->[1]</td><td align='center'>$units[$line->[2]]</td>
      <td align='right'>$line->[3]</td><td align='right'>$line->[4]</td><td align='right'>$sum</td></tr>";

      $Docs->{ 'ORDER_NUM_' . $i } = $i;
      $Docs->{ 'ORDER_NAME_' . $i } = $line->[1];
      $Docs->{ 'ORDER_COUNT_' . $i } = $line->[3];
      $Docs->{ 'ORDER_PRICE_' . $i } = $line->[4];
      $Docs->{ 'ORDER_SUM_' . $i } = $sum;
      $Docs->{ 'ORDER_PRICE_WITHOUT_VAT_' . $i } = sprintf( "%.2f",
          ($conf{DOCS_VAT_INCLUDE}) ? $line->[4] - $line->[4] / ((100 + $conf{DOCS_VAT_INCLUDE}) / $conf{DOCS_VAT_INCLUDE}) : $line->[4] );
      $Docs->{ 'ORDER_SUM_WITHOUT_VAT_' . $i } = sprintf( "%.2f",
          ($conf{DOCS_VAT_INCLUDE}) ? $sum - $sum / ((100 + $conf{DOCS_VAT_INCLUDE}) / $conf{DOCS_VAT_INCLUDE}) : $sum );
      $i++;
      $Docs->{TOTAL_SUM} += $sum;
    }
  }

  if ( $Docs->{PAYMENT_ID} ){
    my $list = $Docs->invoices_list( { PAYMENT_ID => $Docs->{PAYMENT_ID}, COLS_NAME => 1 } );
    if ( $Docs->{TOTAL} > 0 ){
      $Docs->invoice_info( $list->[0]->{id} );
    }
    $Docs->{INVOICE_ID} = $Docs->{INVOICE_ID};

    $PAYMENTS_METHODS = get_payment_methods();

    $list = $Payments->list( {
      METHOD    => '_SHOW',
      ID        => $Docs->{PAYMENT_ID},
      COLS_NAME => 1
    } );

    if ( $Payments->{TOTAL} > 0 ){
      $Docs->{PAYMENT_METHOD_ID} = $list->[0]->{method};
      my $PAYMENT_METHODS = get_payment_methods();

      if ( $conf{DOCS_PAYMENT_METHODS} ){
        my %methods_hash = %{ cfg2hash( $conf{DOCS_PAYMENT_METHODS} ) };

        if ( $Docs->{PAYMENT_METHOD_ID} && $methods_hash{ $Docs->{PAYMENT_METHOD_ID} } ){
          $Docs->{PAYMENT_METHOD} = $methods_hash{ $Docs->{PAYMENT_METHOD_ID} };
        }
        else{
          $Docs->{PAYMENT_METHOD} = $methods_hash{0};
        }
      }
      else{
        $Docs->{PAYMENT_METHOD} = $PAYMENT_METHODS->{ $Docs->{PAYMENT_METHOD_ID} };
      }
    }
  }

  $Docs->{TOTAL_SUM} = sprintf( "%.2f", $Docs->{TOTAL_SUM} );

  $Docs->{'TOTAL_SUM_WITHOUT_VAT'} = sprintf( "%.2f",
      ($conf{DOCS_VAT_INCLUDE}) ? $Docs->{TOTAL_SUM} - ($Docs->{TOTAL_SUM}) / ((100 + $conf{DOCS_VAT_INCLUDE}) / $conf{DOCS_VAT_INCLUDE}) : $Docs->{TOTAL_SUM} );
  $Docs->{'TOTAL_SUM_VAT'} = sprintf( "%.2f", $Docs->{TOTAL_SUM} - $Docs->{'TOTAL_SUM_WITHOUT_VAT'} );
  docs_print( "receipt", $Docs ) if (!$FORM{QUICK});

  return 1;
}

#**********************************************************
=head2 docs_receipt($attr)

  Arguments:
    DOCS_INFO   - Docs info

=cut
#**********************************************************
sub docs_receipt{
  my ($attr) = @_;

  if ( $FORM{create} ){
    docs_receipt_add( {%FORM} );
    return 0;
  }
  elsif ( $FORM{skip} ){
    return 0;
  }
  elsif ( !$FORM{print} ){
    $Docs->{SEL_ORDER} .= $html->form_select(
      'ORDER',
      {
        SELECTED  => $FORM{ORDER},
        SEL_ARRAY => ($conf{DOCS_ORDERS}) ? $conf{DOCS_ORDERS} : [ $lang{DV} ],
        NO_ID     => 1
      }
    );

    $users->pi( { UID => $users->{UID} } );
    $Docs->{OP_SID} = mk_unique_value( 16 );
    $Docs->{CUSTOMER} = $users->{FIO} || '-';
    $Docs->{CAPTION} = $lang{RECEIPT};
    $Docs->{DATE} = $html->date_fld2( 'DATE',
      { MONTHES => \@MONTHES, FORM_NAME => 'receipt_add', WEEK_DAYS => \@WEEKDAYS } );

    # Get docs info
    $Docs->user_info( $FORM{UID} );
    if ( $Docs->{TOTAL} ){
      if ( !$FORM{NEXT_PERIOD} ){
        $FORM{NEXT_PERIOD} = $Docs->{RECEIPT_PERIOD} if ($Docs->{RECEIPT_PERIOD} && $Docs->{RECEIPT_PERIOD} > 1);
      }
    }

    if ( !$FORM{INCLUDE_CUR_BILLING_PERIOD} ){
      my $Y = (split( /-/, $DATE, 3 ))[0];
      $FORM{FROM_DATE} = "$Y-01-01";
    }

    my $list = $Docs->docs_receipt_new({
      FROM_DATE => $FORM{FROM_DATE} || $html->{FROM_DATE},
      TO_DATE   => $FORM{TO_DATE} || $html->{TO_DATE} || $DATE,
      PAGE_ROWS => 500,
      UID       => $users->{UID}
    });

    my $table = $html->table({
      width       => '100%',
      caption     => $lang{ORDERS},
      title_plain => [ '#', "$lang{LOGIN}", "$lang{DATE}", "$lang{DESCRIBE}", $lang{SUM} ],
      pages       => $Docs->{TOTAL},
      ID          => 'DOCS_INVOCE_ORDERS',
    });

    if ( !$users->{DEPOSIT} ){
      $users->{DEPOSIT} = 0;
    }

    my $num = 0;
    my $total_sum = ($users->{DEPOSIT} !~ /^[0-9\.\,]+$/) ? 0  : (($users->{DEPOSIT} && $users->{DEPOSIT} < 0) ? abs( $users->{DEPOSIT} ) : 0 - $users->{DEPOSIT});
    my $amount_for_pay = 0;
    my $TO_D;
    foreach my $line ( @$list ){
      next if ($line->[5]);
      $num++;
      my $date = $line->[2];
      $date =~ s/ \d+:\d+:\d+//g;
      $table->addrow(
        $html->form_input( "ORDER_" . $line->[0] || q{}, ($line->[3] ? "$line->[3]" : q{}), { TYPE => 'hidden', OUTPUT2RETURN => 1 } )
          . $html->form_input( "SUM_" . $line->[0] || q{}, ($line->[4] ? "$line->[4]" : q{}), { TYPE => 'hidden', OUTPUT2RETURN => 1 } )
          . $html->form_input( "FEES_ID_" . $line->[0] || q{}, ($line->[0] ? "$line->[0]" : q{}), { TYPE => 'hidden', OUTPUT2RETURN => 1 } )
          . $html->form_input( "IDS", ($line->[0] ? "$line->[0]" : q{}), { TYPE => 'checkbox', STATE => 1, OUTPUT2RETURN => 1 } ) . "$num",
        ($line->[1] ? "$line->[1]" : q{}), ($line->[2] ? "$line->[2]" : q{}), ($line->[3] ? "$line->[3] $date" : "$date"), ($line->[4] ? "$line->[4]" : q{})
      );

      #$total_sum+=$line->[4];
    }

    my $date = $DATE;
    if ( $users->{ACTIVATE} && $users->{ACTIVATE} ne '0000-00-00' ){
      $date = $users->{ACTIVATE};
      $FORM{FROM_DATE} = $users->{ACTIVATE};
    }

    my ($Y, $M, $D) = split( /-/, $date );
    my $start_period_unixtime;
    if ($users->{ACTIVATE} && $users->{ACTIVATE} ne '0000-00-00' ){
      $start_period_unixtime = (POSIX::mktime( 0, 0, 0, $D, ($M - 1), ($Y - 1900), 0, 0, 0 ));
      $Docs->{CURENT_BILLING_PERIOD_START} = $users->{ACTIVATE};
      $Docs->{CURENT_BILLING_PERIOD_STOP} = POSIX::strftime( "%Y-%m-%d",
        localtime( (POSIX::mktime( 0, 0, 0, $D, ($M - 1), ($Y - 1900), 0, 0, 0 ) + 30 * 86400) ) );
    }
    else{
      $D = '01';
      $Docs->{CURENT_BILLING_PERIOD_START} = "$Y-$M-$D";
      $TO_D = days_in_month({ DATE => $Docs->{CURENT_BILLING_PERIOD_START} });
      $Docs->{CURENT_BILLING_PERIOD_STOP} = "$Y-$M-$TO_D";
    }

    #Next period payments
    if ( $FORM{NEXT_PERIOD} ){
      # Get invoces
      my %current_receipt = ();
      $list = $Docs->docs_receipt_list( {
        UID         => $FORM{UID},
        PAYMENT_ID  => 0,
        ORDERS_LIST => 1,
        COLS_NAME   => 1
      } );

      foreach my $line ( @{$list} ){
        $current_receipt{ $line->{orders} } = $line->{receipt_id};
      }

      my $cross_modules_return = cross_modules('docs');
      my $next_period = $FORM{NEXT_PERIOD};
      if ( $users->{ACTIVATE} ne '0000-00-00' ){
        ($Y, $M, $D) = split( /-/, POSIX::strftime( "%Y-%m-%d", localtime( (POSIX::mktime( 0, 0, 0, $D, ($M - 1), ($Y - 1900), 0, 0,
              0 ) + ((($start_period_unixtime > time) ? 0 : 1) + 30 * (($start_period_unixtime > time) ? 0 : 1)) * 86400) ) ) );
        $FORM{FROM_DATE} = "$Y-$M-$D";

        ($Y, $M, $D) = split( /-/, POSIX::strftime( "%Y-%m-%d", localtime( (POSIX::mktime( 0, 0, 0, $D, ($M - 1), ($Y - 1900), 0, 0,
              0 ) + ((($start_period_unixtime > time) ? 1 : (1 * $next_period - 1)) + 30 * (($start_period_unixtime > time) ? 1 : $next_period)) * 86400) ) ) );
        $FORM{TO_DATE} = "$Y-$M-$D";
      }
      else{
        $M += 1;
        if ( $M < 12 ){
          $M = sprintf( "%02d", $M );
        }
        else{
          $M = sprintf( "%02d", $M - 12 );
          $Y++;
        }
        $FORM{FROM_DATE} = "$Y-$M-$D";

        $M += $next_period - 1;
        if ( $M < 12 ){
          $M = sprintf( "%02d", $M );
        }
        else{
          $M = sprintf( "%02d", $M - 13 );
          $Y++;
        }

        if ( $users->{ACTIVATE} eq '0000-00-00' ){
          $TO_D = ($M != 2 ? (($M % 2) ^ ($M > 7)) + 30 : (!($Y % 400) || !($Y % 4) && ($Y % 25) ? 29 : 28));
        }
        else{
          $TO_D = $D;
        }

        $FORM{TO_DATE} = "$Y-$M-$TO_D";
      }

      my $period_from = $FORM{FROM_DATE};
      my $period_to   = $FORM{FROM_DATE};
      my $result_sum  = 0;

      foreach my $module ( sort keys %{$cross_modules_return} ){
        if ( ref $cross_modules_return->{$module} eq 'ARRAY' ){
          next if ($#{ $cross_modules_return->{$module} } == -1);
          $table->{extra} = "colspan='5' class='small'";
          $table->addrow( "$module" );
          $table->{extra} = undef;

          foreach my $line ( @{ $cross_modules_return->{$module} } ){
            my ($name, $describe, $sum) = split( /\|/, $line );
            next if ($sum < 0);

            #my ($Y, $M, $D) = split(/-/, $FORM{FROM_DATE}, 3);
            #$period_from = strftime "%Y-%m-%d", localtime( (POSIX::mktime(0, 0, 0, $D, ($M-1), ($Y-1900), 0, 0, 0) + 1 * 86400) );
            $period_from = $FORM{FROM_DATE};

            for ( my $i = ($FORM{NEXT_PERIOD} == -1) ? -2 : 0; $i < int( $FORM{NEXT_PERIOD} ); $i++ ){
              $result_sum = sprintf( "%.2f", $sum );
              if ( $users->{REDUCTION} && $module ne 'Abon' ){
                $result_sum = sprintf( "%.2f", $sum * (100 - $users->{REDUCTION}) / 100 );
              }

              ($Y, $M, $D) = split( /-/, $period_from, 3 );
              if ( $users->{ACTIVATE} ne '0000-00-00' ){
                ($Y, $M, $D) = split( /-/, POSIX::strftime( "%Y-%m-%d",
                    localtime( (POSIX::mktime( 0, 0, 0, $D, ($M - 1), ($Y - 1900), 0, 0, 0 )) ) ) );  #+ (31 * $i) * 86400) ));
                $period_from = "$Y-$M-$D";

                ($Y, $M, $D) = split( /-/, POSIX::strftime( "%Y-%m-%d",
                    localtime( (POSIX::mktime( 0, 0, 0, $D, ($M - 1), ($Y - 1900), 0, 0, 0 ) + (30) * 86400) ) ) );
                $period_to = "$Y-$M-$D";
              }
              else{
                $M += 1 if ($i > 0);
                if ( $M < 12 ){
                  $M = sprintf( "%02d", $M );
                }
                else{
                  $M = sprintf( "%02d", $M - 12 );
                  $Y++;
                }
                $period_from = "$Y-$M-01";

                if ( $M < 12 ){
                  $M = sprintf( "%02d", $M );
                }
                else{
                  $M = sprintf( "%02d", $M - 13 );
                  $Y++;
                }

                if ( $users->{ACTIVATE} eq '0000-00-00' ){
                  $TO_D = ($M != 2 ? (($M % 2) ^ ($M > 7)) + 30 : (!($Y % 400) || !($Y % 4) && ($Y % 25) ? 29 : 28));
                }
                else{
                  $TO_D = $D;
                }

                $period_to = "$Y-$M-$TO_D";
              }

              my $order = "$name $describe($period_from-$period_to)";

              $num++ if (!$current_receipt{$order});
              $table->addrow(
                (
                    (!$current_receipt{$order})
                  ? $html->form_input( 'ORDER_' . $num, "$order", { TYPE => 'hidden', OUTPUT2RETURN => 1 } )
                    . $html->form_input( 'SUM_' . $num, $result_sum, { TYPE => 'hidden', OUTPUT2RETURN => 1 } )
                    . $html->form_input( 'IDS', "$num",
                    { TYPE => ($user->{UID}) ? 'hidden' : 'checkbox', STATE => 'checked', OUTPUT2RETURN => 1 } )
                    . $num
                  : ''
                ),
                $users->{LOGIN},
                $period_from,
                $order . (($current_receipt{$order}) ? ' ' . $html->color_mark( $lang{EXIST}, "$_COLORS[6]" ) : ''),
                $result_sum
              );

              $total_sum += $sum if (!$current_receipt{$order});
              $period_from = POSIX::strftime( "%Y-%m-%d",
                localtime( (POSIX::mktime( 0, 0, 0, $D, ($M - 1), ($Y - 1900), 0, 0, 0 ) + 1 * 86400) ) );
            }
          }
        }
      }
    }

    my $deposit = ($users->{DEPOSIT} && $users->{DEPOSIT} =~ /^[0-9\.\,]+$/) ? $users->{DEPOSIT} : 0;

    if ( $deposit > 0 ){
      $amount_for_pay = ($total_sum < $deposit) ? 0 : $total_sum - $deposit;
    }
    else{
      $amount_for_pay = $total_sum;
    }

    $table->{extra} = " colspan='4' class='total' ";
    $table->addrow( "$lang{COUNT}: $num $lang{TOTAL} $lang{SUM}: ", sprintf( "%.2f", $total_sum ) );
    $table->addrow( $html->b( "$lang{DEPOSIT}:" ), $html->b( sprintf( "%.2f", $deposit ) ) );
    $table->addrow( $html->b( "$lang{AMOUNT_FOR_PAY}:" ), $html->b( sprintf( "%.2f", $amount_for_pay || 0 ) ) );
    $Docs->{ORDERS} = $table->show( { OUTPUT2RETURN => 1 } );
    $Docs->{FROM_DATE} = $html->date_fld2( 'FROM_DATE',
      { MONTHES => \@MONTHES, FORM_NAME => 'receipt_add', WEEK_DAYS => \@WEEKDAYS } );
    $Docs->{TO_DATE} = $html->date_fld2( 'TO_DATE',
      { MONTHES => \@MONTHES, FORM_NAME => 'receipt_add', WEEK_DAYS => \@WEEKDAYS } );

    $FORM{NEXT_PERIOD} = 0 if (!$FORM{NEXT_PERIOD} || $FORM{NEXT_PERIOD} < 0);

    if ( $attr->{REGISTRATION} ){
      $Docs->{BACK} = $html->form_input( 'back', "$lang{BACK}", { TYPE => 'submit' } );
      $Docs->{NEXT} = $html->form_input( 'skip', "$lang{NEXT}", { TYPE => 'submit' } );
    }

    #$html->tpl_show(_include('docs_receipt_add', 'Docs'), { %FORM, %$attr, %$Docs, %$users }) if (! $FORM{pdf});
  }

  docs_receipt_list( $attr );

  return 1;
}

#**********************************************************
=head2 docs_receipt_list($attr)

  Arguments:
    DOC_INFO   -  Docs obj

=cut
#**********************************************************
sub docs_receipt_list{
  my ($attr) = @_;

  my $PAYMENT_METHODS = get_payment_methods();
  my $uid = $LIST_PARAMS{UID} || $attr->{UID} || $FORM{UID};

  if ( $FORM{del} && $FORM{COMMENTS} ){
    $Docs->docs_receipt_del( $FORM{del} );
    if ( _error_show($Docs->{errno}) ){
      return 0;
    }
    else {
      $html->message( 'info', "$lang{INFO}", "$lang{DELETED} N: [$FORM{del}]" );
    }
  }
  elsif ( $FORM{print} ){
    return docs_receipt_print({
      UID             => $uid,
      PAYMENT_METHODS => $PAYMENT_METHODS,
      PRINT_ID        => $FORM{print},
      %$attr
    });
  }
  elsif ( $FORM{sendmail} ){
    $FORM{print} = $FORM{sendmail};
    if (
      docs_receipt_list(
        {
          SEND_EMAIL       => 1,
          GET_EMAIL_INFO => 1
        }
      )
    )
    {
      $html->message( 'info', "$lang{INFO}", "$lang{SEND_REG} E-Mail" );
    }
    else{
      $html->message( 'info', "$lang{ERROR}", "$lang{SEND_REG} E-Mail  Error: $FORM{ERR_MESSAGE} " );
    }
    return 1;
  }
  elsif ( !$LIST_PARAMS{UID} && $FORM{search_form} ){
    my %info = ();
    $info{PAYMENT_METHOD_SEL} = $html->form_select(
      'PAYMENT_METHOD',
      {
        SELECTED => (defined( $FORM{PAYMENT_METHOD} ) && $FORM{PAYMENT_METHOD} ne '') ? $FORM{METHOD} : '',
        SEL_HASH => { '' => $lang{ALL}, %{$PAYMENT_METHODS} },
        NO_ID    => 1,
        SORT_KEY => 1
      }
    );

    $info{ADMIN_SELECT} = sel_admins();

    form_search( { SEARCH_FORM =>
        ($FORM{pdf}) ? '' : $html->tpl_show( _include( 'docs_receipt_search', 'Docs' ), { %info, %FORM },
          { notprint => 1 } ), SHOW_PERIOD => 1 } );
  }

  if ( !$FORM{sort} ){
    $LIST_PARAMS{SORT} = 'd.date DESC, d.receipt_num DESC';
    $LIST_PARAMS{DESC} = '';
  }

  if ( $FORM{print_list} ){
    return docs_receipt_print_list({
      UID             => $uid,
      PAYMENT_METHODS => $PAYMENT_METHODS,
      %$attr
    });
  }

  my AXbills::HTML $table;
  my $list;

  if($user && $user->{UID}) {
    delete $LIST_PARAMS{LOGIN};
  }

  ($table, $list) = result_former( {
    INPUT_DATA      => $Docs,
    FUNCTION        => 'docs_receipt_list',
    DEFAULT_FIELDS  => ($LIST_PARAMS{UID}) ? 'RECEIPT_NUM,DATETIME,TOTAL_SUM' : 'DATETIME,FIO,TOTAL_SUM,LOGIN',
    BASE_FIELDS     => 1,
    FUNCTION_FIELDS => ($user && $user->{UID}) ? 'print' : 'send,print,delete',
    EXT_TITLES      => {
      receipt_num    => $lang{NUM},
      date           => $lang{DATE},
      datetime       => $lang{DATE},
      customer       => $lang{CUSTOMER},
      total_sum      => $lang{SUM},
      login          => $lang{LOGIN},
      admin_name     => $lang{ADMIN},
      created        => $lang{CREATED},
      payment_method => $lang{PAYMENT_METHOD},
      payment_id     => $lang{PAYMENTS}
    },
    TABLE           => {
      width      => '100%',
      caption    => $lang{RECEIPT},
      qs         => $pages_qs,
      ID         => ($user && $user->{UID}) ? 'DOCS_USER_INVOCE' : 'DOCS_INVOCE',
      EXPORT     => 1,
      MENU       => "$lang{SEARCH}:search_form=1&index=" . get_function_index( 'docs_receipt_list' ) . "&search=1:search"
    }
  } );

  if ( $conf{DOCS_PDF_PRINT} ){
    $pages_qs .= "&pdf=1";
  }

  foreach my $line ( @{$list} ){
    my $delete = ($permissions{1}{2}) ? ' '. $html->button( $lang{DEL},
        "index=$index&del=$line->{id}&UID=$line->{uid}",
        { MESSAGE => "$lang{DEL} ?", class => 'del' } ) : '';

    my @fields_array = ($line->{receipt_num});
    my $val = '';
    for ( my $i = 1; $i < 1 + $Docs->{SEARCH_FIELDS_COUNT}; $i++ ){
      my $col_name = $Docs->{COL_NAMES_ARR}->[$i];
      if ( $col_name eq 'payment_method' ){
        if ( $line->{payment_id} ){
          $val = $html->button( $PAYMENT_METHODS->{$line->{$col_name}},
            "index=2&ID=$line->{payment_id}&UID=$line->{uid}" ),
        }
        else{
          $val = $PAYMENT_METHODS->{(defined $line->{$col_name} ? $line->{$col_name} : '')} || '';
        }
      }
      elsif ( $col_name eq 'total_sum' ){
        $val = sprintf('%.2f', $line->{total_sum} || 0);
      }
      elsif ( $col_name eq 'login' && $line->{uid} && ! $user ){
        $val = user_ext_menu( $line->{uid}, $line->{login} );
      }
      else{
        $val = $line->{$col_name};
      }

      push @fields_array, $val;
    }

    my $function_fields = q{};

    if(! $user || ! $user->{UID}) {
      $function_fields = $html->button($lang{SEND_MAIL},
        "qindex=" . get_function_index('docs_receipt_list') . "&sendmail=$line->{id}&UID=$line->{uid}",
        { ex_params => 'target=_new', class => 'sendmail' });
    }

    $function_fields .= $html->button( $lang{PRINT},
      "qindex=" . get_function_index( 'docs_receipt_list' ) . "&print=$line->{id}&RECEIPT_ID=$line->{uid}&UID=$line->{uid}$pages_qs"
      , { ex_params => 'target=_new', class => 'print' } )
      . $delete;

    $table->addrow(
      @fields_array,
      $function_fields
    );
  }

  print $table->show();

  $table = $html->table(
    {
      width      => '100%',
      rows       => [ [
      ($user && $user->{UID}) ? q{} : $html->button( "$lang{PRINT} $lang{LIST}",
          "qindex=$index&print_list=1$pages_qs" . (($conf{DOCS_PDF_PRINT}) ? '&pdf=1' : ''),
          { BUTTON => 1, ex_params => 'target=new' } ),
        "$lang{TOTAL}:",
        $html->b( $Docs->{TOTAL} )
      ] ]
    }
  );

  print $table->show();
  $LIST_PARAMS{SORT} = 1;

  return 1;
}


#**********************************************************
=head2 docs_receipt($attr)

  Arguments:
    $attr
      UID
      PAYMENT_METHODS
      PRINT_ID
      GET_EMAIL_INFO
      DOCS_INFO   - Docs info

=cut
#**********************************************************
sub docs_receipt_print {
  my ($attr) = @_;

  my $uid = $attr->{UID};
  my $print_id = $attr->{PRINT_ID} || 0;
  my $PAYMENT_METHODS = $attr->{PAYMENT_METHODS};

  if($attr->{DOC_INFO}) {
    $Docs = $attr->{DOC_INFO};
  }
  else {
    $Docs->docs_receipt_info($print_id, { UID => $uid } );
  }

  if(! $users && $user) {
    $users = $user;
  }

  $Docs->{TOTAL_SUM} = 0.00;
  $Docs->{PAYMENT_METHOD_ID} = $Docs->{PAYMENT_METHOD};
  $Docs->{PAYMENT_METHOD} = $PAYMENT_METHODS->{ $Docs->{PAYMENT_METHOD_ID} };

  if ( $Docs->{ORDERS} ){
    my $i = 1;
    my @ORDERS = @{ $Docs->{ORDERS} };
    $Docs->{ORDER} = '';
    $Docs->{AMOUNT_FOR_PAY} = ($Docs->{DEPOSIT} < 0) ? abs( $Docs->{DEPOSIT} ) : 0 - $Docs->{DEPOSIT};

    foreach my $line ( @ORDERS ){

      my $sum = sprintf( "%.2f", $line->[3] * $line->[4] );
      $Docs->{ORDER} .= "<tr><th align='right'>$i</th><td align='left'>$line->[1]</td><td align='center'>$units[$line->[2]]</td>
          <td align='right'>$line->[3]</td><td align='right'>$line->[4]</td><td align='right'>$sum</td></tr>";

      $Docs->{ 'ORDER_NUM_' . $i } = $i;
      $Docs->{ 'ORDER_NAME_' . $i } = $line->[1];
      $Docs->{ 'ORDER_COUNT_' . $i } = $line->[3] || 1;
      $Docs->{ 'ORDER_PRICE_' . $i } = $line->[4];
      $Docs->{ 'LOGIN_' . $i } = $line->[6];
      $Docs->{ 'ORDER_SUM_' . $i } = $sum;
      $Docs->{ 'ORDER_PRICE_WITHOUT_VAT_' . $i } = sprintf( "%.2f",
          ($conf{DOCS_VAT_INCLUDE}) ? $line->[4] - $line->[4] / ((100 + $conf{DOCS_VAT_INCLUDE}) / $conf{DOCS_VAT_INCLUDE}) : $line->[4] );
      $Docs->{ 'ORDER_SUM_WITHOUT_VAT_' . $i } = sprintf( "%.2f",
          ($conf{DOCS_VAT_INCLUDE}) ? $sum - $sum / ((100 + $conf{DOCS_VAT_INCLUDE}) / $conf{DOCS_VAT_INCLUDE}) : $sum );
      $Docs->{TOTAL_SUM} += $sum;
      $Docs->{AMOUNT_FOR_PAY} += $Docs->{ 'ORDER_COUNT_' . $i } * $Docs->{ 'ORDER_PRICE_' . $i } if ($line->[5] == 0);

      #alternative currancy sum
      if ( $Docs->{EXCHANGE_RATE} > 0 ){
        $Docs->{ 'ORDER_ALT_SUM_' . $i } = sprintf( "%.2f", $Docs->{ 'ORDER_SUM_' . $i } * $Docs->{EXCHANGE_RATE} );
        $Docs->{ 'ORDER_ALT_PRICE_' . $i } = sprintf( "%.2f",
          $Docs->{ 'ORDER_PRICE_' . $i } * $Docs->{EXCHANGE_RATE} );
        $Docs->{ 'ORDER_ALT_VAT_' . $i } = sprintf( "%.2f", $Docs->{ 'ORDER_VAT_' . $i } * $Docs->{EXCHANGE_RATE} );
        $Docs->{ 'ORDER_ALT_PRICE_WITHOUT_VAT_' . $i } = sprintf( "%.2f",
          $Docs->{ 'ORDER_PRICE_WITHOUT_VAT_' . $i } * $Docs->{EXCHANGE_RATE} );
        $Docs->{ 'ORDER_ALT_SUM_WITHOUT_VAT_' . $i } = sprintf( "%.2f",
          $Docs->{ 'ORDER_SUM_WITHOUT_VAT_' . $i } * $Docs->{EXCHANGE_RATE} );
      }
      $i++;
    }
  }

  $Docs->{AMOUNT_FOR_PAY} = sprintf( "%.2f", $Docs->{AMOUNT_FOR_PAY} );
  $Docs->{TOTAL_SUM} = sprintf( "%.2f", $Docs->{TOTAL_SUM} );
  $Docs->{AMOUNT_FOR_PAY} = int( $Docs->{AMOUNT_FOR_PAY} * 100 );
  $Docs->{TOTAL_SUM_CENT} = int( $Docs->{TOTAL_SUM} * 100 );

  if ( $Docs->{EXCHANGE_RATE} > 0 ) {
    $Docs->{TOTAL_ALT_SUM} = sprintf("%.2f", $Docs->{TOTAL_SUM} * $Docs->{EXCHANGE_RATE});
    $Docs->{AMOUNT_FOR_PAY_ALT} = sprintf("%.2f", $Docs->{AMOUNT_FOR_PAY} * $Docs->{EXCHANGE_RATE});
    $Docs->{CHARGED_ALT_SUM} = sprintf("%.2f", $Docs->{CHARGED_SUM} * $Docs->{EXCHANGE_RATE});

    $Docs->{TOTAL_ALT_SUM_CENT} = int($Docs->{TOTAL_ALT_SUM} * 100);
    $Docs->{AMOUNT_FOR_PAY_ALT_CENT} = int($Docs->{AMOUNT_FOR_PAY_ALT} * 100);
    $Docs->{CHARGED_ALT_SUM_CENT} = int($Docs->{CHARGED_ALT_SUM} * 100);
  }

  if ( $Docs->{PAYMENT_ID} ){
    my $invoice_list = $Docs->invoices_list( {
      PAYMENT_ID => $Docs->{PAYMENT_ID} || '-1',
      COLS_NAME => 1
    } );

    $Docs->{INVOICE_ID} = $invoice_list->[0]->{id};

    my $payment_list = $Payments->list({
      ID        => $Docs->{PAYMENT_ID},
      METHOD    => '_SHOW',
      COLS_NAME => 1
    });

    if ( $Payments->{TOTAL} > 0 ){
      $Docs->{PAYMENT_METHOD_ID} = $payment_list->[0]->{method};

      if ( $conf{DOCS_PAYMENT_METHODS} ){
        my %methods_hash = %{ cfg2hash( $conf{DOCS_PAYMENT_METHODS} ) };

        if ( $methods_hash{ $Docs->{PAYMENT_METHOD_ID} } ){
          $Docs->{PAYMENT_METHOD} = $methods_hash{ $Docs->{PAYMENT_METHOD_ID} };
        }
        else{
          $Docs->{PAYMENT_METHOD} = $methods_hash{0};
        }
      }
      else{
        $Docs->{PAYMENT_METHOD} = $PAYMENT_METHODS->{ $Docs->{PAYMENT_METHOD_ID} };
      }
    }
  }

  if(! $Docs->{CUSTOMER} || $Docs->{CUSTOMER} eq '-') {
    $users->info($uid);
    $users->pi( { UID => $uid } );
    $Docs->{CUSTOMER} = $users->{FIO} || '-';
  }

  if ( $conf{DOCS_VAT_INCLUDE} ){
    $Docs->{ORDER_TOTAL_SUM_VAT} = sprintf( "%.2f",
      $Docs->{TOTAL_SUM} / ((100 + $conf{DOCS_VAT_INCLUDE}) / $conf{DOCS_VAT_INCLUDE}) );
    $Docs->{TOTAL_SUM_WITHOUT_VAT} = sprintf( "%.2f", $Docs->{TOTAL_SUM} - $Docs->{ORDER_TOTAL_SUM_VAT} );
    $Docs->{VAT} = sprintf( "%.2f", $conf{DOCS_VAT_INCLUDE} );

    $Docs->{ORDER_TOTAL_SUM_VAT_CENT} = int( $Docs->{ORDER_TOTAL_SUM_VAT} * 100 );
    $Docs->{TOTAL_SUM_WITHOUT_VAT_CENT} = int( $Docs->{TOTAL_SUM_WITHOUT_VAT} * 100 );
    $Docs->{VAT_CENT} = ($Docs->{VAT_CENT} && $Docs->{VAT_CENT} > 0) ? int($Docs->{VAT_CENT} * 100) : 0;
  }

  $attr->{SEND_EMAIL} = 0 if (!defined( $attr->{SEND_EMAIL} ));

  if ( $attr->{GET_EMAIL_INFO} ){
    delete $FORM{pdf};
    $attr->{EMAIL_MSG_TEXT} = $html->tpl_show( _include( 'docs_receipt_email', 'Docs' ), { %{$Docs}, %{$users} },
      { OUTPUT2RETURN => 1 } );
    $attr->{EMAIL_ATTACH_FILENAME} = 'receipt_' . $Docs->{RECEIPT_NUM} if (!$attr->{EMAIL_ATTACH_FILENAME});
    $attr->{EMAIL_MSG_SUBJECT} = "ABillS - $lang{RECEIPT}: $Docs->{RECEIPT_NUM}" if (!$attr->{EMAIL_MSG_SUBJECT});
    delete ($attr->{OUTPUT2RETURN});
    $FORM{pdf} = $conf{DOCS_PDF_PRINT};
    $attr->{SEND_EMAIL} = 1;
  }

  return docs_print( $FORM{termo_printer_tpl} ? 'invoice_termo_printer' : 'receipt', { %{$Docs}, %{$attr} } );
}

#**********************************************************
=head2 docs_receipt_print_list($attr)

  Arguments:

=cut
#**********************************************************
sub docs_receipt_print_list {
  my ($attr)=@_;

  if ( $debug > 2 ){
    print "Content-Type: text/html\n\n";
  }

  my $PAYMENT_METHODS = $attr->{PAYMENT_METHODS};

  my $receipt_list = $Docs->docs_receipt_list( {
    LOGIN          => '_SHOW',
    DATETIME       => '_SHOW',
    FIO            => '_SHOW',
    ADMIN_NAME     => '_SHOW',
    PHONE          => '_SHOW',
    PAYMENT_METHOD => '_SHOW',
    TOTAL_SUM      => '_SHOW',
    %FORM,
    %LIST_PARAMS,
    CONTRACT_ID    => '_SHOW',
    CONTRACT_DATE  => '_SHOW',
    COMPANY_ID     => '_SHOW',
    ADDRESS_FULL   => '_SHOW',
    COLS_NAME      => 1,
  } );
  my @MULTI_ARR = ();
  my $doc_num = 0;
  my %D = ();

  foreach my $line ( @{$receipt_list} ){
    $D{RECEIPT_ID} = $line->{receipt_num};
    $D{DATE} = $line->{datetime};
    my ($y, $m, $d) = split( /-/, $line->{datetime}, 3 );
    $D{FROM_DATE_LIT} = "$d " . $MONTHES_LIT[ int( $m ) - 1 ] . " $y $lang{YEAR_SHORT}";
    $D{DATE_EURO_STANDART} = "$d.$m.$y";
    $D{FIO} = $line->{fio};
    $D{LOGIN} = $line->{login};
    $D{ADDRESS_FULL} = $line->{address_full};
    $D{TOTAL_SUM} = sprintf( "%.2f", $line->{total_sum} );
    $D{CONTRACT_ID} = $line->{contract_id};
    $D{CONTRACT_DATE} = $line->{contract_date};
    $D{A_FIO} = $line->{admin_name};
    $D{PHONE} = $line->{phone};

    my $method = $line->{payment_method};

    if ( $conf{DOCS_PAYMENT_METHODS} ){
      my %methods_hash = %{ cfg2hash( $conf{DOCS_PAYMENT_METHODS} ) };

      if ( $methods_hash{$method} ){
        $D{PAYMENT_METHOD} = $methods_hash{$method};
      }
      else{
        $D{PAYMENT_METHOD} = $methods_hash{0};
      }
    }
    else{
      $D{PAYMENT_METHOD} = $PAYMENT_METHODS->{$method};
    }

    if ( $conf{DOCS_VAT_INCLUDE} ){
      $D{ORDER_TOTAL_SUM_VAT} = sprintf( "%.2f",
        $D{TOTAL_SUM} / ((100 + $conf{DOCS_VAT_INCLUDE}) / $conf{DOCS_VAT_INCLUDE}) );
      $D{TOTAL_SUM_WITHOUT_VAT} = sprintf( "%.2f", $D{TOTAL_SUM} - $D{ORDER_TOTAL_SUM_VAT} );
      $D{TOTAL_SUM_VAT} = sprintf( "%.2f", $D{TOTAL_SUM} - $D{TOTAL_SUM_WITHOUT_VAT} );
    }
    $D{ORDER_PRICE_WITHOUT_VAT_1} = $D{TOTAL_SUM_WITHOUT_VAT} || 0, 00;
    $D{ORDER_SUM_WITHOUT_VAT_1} = $D{TOTAL_SUM_WITHOUT_VAT} || 0, 00;
    $D{ORDER_TOTAL_SUM_VAT} = $D{TOTAL_SUM_VAT} || 0, 00;
    push @MULTI_ARR, { %D, DOC_NUMBER => sprintf( "%.6d", $doc_num ), };
    $doc_num++;
    print "UID: LOGIN: $line->{login} FIO: $line->{customer} SUM: $line->{sum}\n" if ($debug > 2);
  }

  print $html->header() if ($FORM{qindex});
  my $receipt_file = ($D{PAYMENT_METHOD}) ? 'docs_receipt_' . $D{PAYMENT_METHOD} : 'docs_receipt';
  my $receipt_content = _include( $receipt_file, 'Docs', { pdf => $FORM{pdf} } );

  if ( $receipt_content =~ /No such t/ ){
    $receipt_content = _include( 'docs_receipt', 'Docs', { pdf => $FORM{pdf} } );
  }
  $html->tpl_show(
    $receipt_content,
    undef,
    {
      MULTI_DOCS => \@MULTI_ARR,
      debug      => $debug
    }
  );

  return 0;
}

1;