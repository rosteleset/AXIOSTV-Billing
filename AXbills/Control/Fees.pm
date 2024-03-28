=head1 NAME

   Fees managment

=cut


use strict;
use warnings FATAL => 'all';
use AXbills::Base qw(date_diff in_array convert);

our(
  $db,
  $admin,
  %conf,
  %permissions,
  %lang,
  @MONTHES,
  @bool_vals,
  @state_colors
);

our AXbills::HTML $html;

#**********************************************************
=head2 form_fees($attr)

=cut
#**********************************************************
sub form_fees {
  my ($attr) = @_;
  my $period = $FORM{period} || 0;

  return 0 if (!defined($permissions{2}));

  my $Fees = Finance->fees($db, $admin, \%conf);
  my %BILL_ACCOUNTS = ();

  my $FEES_METHODS = get_fees_types();

  if (($FORM{search_form} || $FORM{search}) && $index != 7) {
    $FORM{type} = $FORM{subf} if ($FORM{subf});
    if ($FORM{search_form} || $FORM{search}) {
      form_search({
        HIDDEN_FIELDS => {
          ($FORM{DATE} ? (DATE => $FORM{DATE}) : ()),
          subf       => ($FORM{subf}) ? $FORM{subf} : undef,
          COMPANY_ID => $FORM{COMPANY_ID},
        }
      });
    }
  }

  if ($attr->{USER_INFO}) {
    my $user = $attr->{USER_INFO};
    require Shedule;
    Shedule->import();
    my $Shedule = Shedule->new($db, $admin, \%conf);

    if ($conf{EXT_BILL_ACCOUNT}) {
      $BILL_ACCOUNTS{ $attr->{USER_INFO}->{BILL_ID} } = "$lang{PRIMARY} : $attr->{USER_INFO}->{BILL_ID}" if ($attr->{USER_INFO}->{BILL_ID});
      $BILL_ACCOUNTS{ $attr->{USER_INFO}->{EXT_BILL_ID} } = "$lang{EXTRA} : $attr->{USER_INFO}->{EXT_BILL_ID}" if ($attr->{USER_INFO}->{EXT_BILL_ID});
    }

    if (! $user->{BILL_ID} || $user->{BILL_ID} < 1) {
      form_bills({ USER_INFO => $user });
      return 0;
    }

    $Fees->{UID} = $user->{UID};
    if ($FORM{take} && $FORM{SUM}) {
      $FORM{SUM} =~ s/,/\./g;

      # add to shedule
      if ($FORM{ER} && $FORM{ER} ne '') {
        my $er = $Fees->exchange_info($FORM{ER});
        $FORM{ER}  = $er->{ER_RATE};
        $FORM{SUM} = $FORM{SUM} / $FORM{ER};
      }

      if ($period == 2) {
        my $FEES_DATE = $FORM{DATE} || $DATE;
        if (date_diff($DATE, $FEES_DATE) < 1) {
          $Fees->take($user, $FORM{SUM}, \%FORM);
          if (! _error_show($Fees)) {
            $html->message( 'info', $lang{FEES}, "$lang{TAKE} $lang{SUM}: $Fees->{SUM} $lang{DATE}: $FEES_DATE" );
          }
        }
        else {
          my ($Y, $M, $D) = split(/-/, $FEES_DATE);
          $FORM{METHOD} //= 0;
          $Shedule->add({
            DESCRIBE => $FORM{DESCR},
            D        => $D,
            M        => $M,
            Y        => $Y,
            UID      => $user->{UID},
            TYPE     => 'fees',
            ACTION   => ($conf{EXT_BILL_ACCOUNT}) ? "$FORM{SUM}:$FORM{DESCRIBE}:BILL_ID=$FORM{BILL_ID}:$FORM{METHOD}" : "$FORM{SUM}:$FORM{DESCRIBE}::$FORM{METHOD}"
          });

          if(! _error_show($Shedule)) {
            $html->message( 'info', $lang{SHEDULE}, $lang{ADDED});
          }
        }
      }
      #take now
      else {
        delete $FORM{DATE};
        $FORM{DESCRIBE} = dynamic_types({FEES_METHODS_STR => $FORM{DESCRIBE}});
        $FORM{DSC} = dynamic_types({FEES_METHODS_STR => $FORM{DSC}});

        $FORM{SKIP_PRIORITY}=1;
        $Fees->take($user, $FORM{SUM}, \%FORM);
        if (! _error_show($Fees)) {
          $html->message( 'info', $lang{FEES}, "$lang{TAKE} $lang{SUM}: $Fees->{SUM}" );

          #External script
          if ($conf{external_fees}) {
            if (!_external($conf{external_fees}, {%FORM})) {
              return 0;
            }
          }
        }
      }
      if ($FORM{CREATE_FEES_INVOICE} && in_array('Docs', \@MODULES)) {
        require Docs;
        Docs->import();
        my $Docs = Docs->new($db, $admin, \%conf);
        $FORM{FEES_ID} = $Fees->{INSERT_ID};
        $Docs->invoice_add({%FORM, ORDER => $FORM{DESCRIBE}});
        if (! _error_show($Docs)) {
          $html->message('info', $lang{CREATED} . $lang{INVOICE} . $lang{FEES}, "$lang{CREATED}: $Docs->{DATE}  $lang{INVOICE}: $Docs->{INVOICE_NUM}");
        }
      }
    }
    elsif ($FORM{del} && $FORM{COMMENTS}) {
      if (!defined($permissions{2}{2})) {
        $html->message( 'err', $lang{ERROR}, "[13] $lang{ERR_ACCESS_DENY}" );
        return 0;
      }

      $Fees->del($user, $FORM{del}, { COMMENTS => $FORM{COMMENTS} });

      if (! _error_show($Fees)) {
        $html->message( 'info', $lang{FEES}, "$lang{DELETED} ID: $FORM{del}" );
      }
    }

    my $list = $Shedule->list({
      UID       => $user->{UID},
      TYPE      => 'fees',
      COLS_NAME => 1
    });

    if ($Shedule->{TOTAL} > 0) {
      my $table2 = $html->table({
        width       => '100%',
        caption     => $lang{SHEDULE},
        title_plain => [ '#', $lang{DATE}, $lang{SUM}, '-' ],
        qs          => $pages_qs,
        ID          => 'USER_SHEDULE'
      });

      foreach my $line (@$list) {
        my ($sum, undef) = split(/:/, $line->{action});
        my $delete = ($permissions{2}{2}) ? $html->button( $lang{DEL}, "index=85&del=$line->{id}",
          { MESSAGE => "$lang{DEL} ID: $line->{id}?", class => 'del' } ) : '';

        $table2->addrow($line->{admin_action} || $line->{comments}, "$line->{y}-$line->{m}-$line->{d}",
          sprintf('%.2f', $sum || 0), $delete);
      }

      $Fees->{SHEDULE_FORM} = $table2->show();
    }

    $Fees->{PERIOD_FORM} = form_period($period, { TD_EXDATA => "colspan='2'" });

    if ($permissions{2} && $permissions{2}{1}) {
      #exchange rate sel
      $Fees->{SEL_ER} = $html->form_select('ER', {
        SELECTED   => undef,
        SEL_LIST   => $Fees->exchange_list({ COLS_NAME => 1 }),
        SEL_KEY    => 'id',
        SEL_VALUE  => 'money,short_name',
        NO_ID      => 1,
        MAIN_MENU     => get_function_index('form_exchange_rate'),
        MAIN_MENU_ARGV=> "chg=". ($FORM{ER} || q{}),
        SEL_OPTIONS=> { '' => ''}
      });

      if ($conf{EXT_BILL_ACCOUNT}) {
        $Fees->{EXT_DATA_FORM} = $html->form_select('BILL_ID',
          {
            SELECTED => $FORM{BILL_ID} || $attr->{USER_INFO}->{BILL_ID},
            SEL_HASH => \%BILL_ACCOUNTS,
            NO_ID    => 1
          }
        );
      }
      if (in_array('Docs', \@MODULES) ) {
        $Fees->{DOCS_FEES_ELEMENT} = $html->tpl_show(_include('docs_create_fees', 'Docs'), {},{ OUTPUT2RETURN => 1 });
      }

      $Fees->{SEL_METHOD} = $html->form_select('METHOD', {
        SELECTED      => (defined($FORM{METHOD}) && $FORM{METHOD} ne '') ? $FORM{METHOD} : 0,
        SEL_HASH      => dynamic_types({FEES_METHODS_HASH => $FEES_METHODS}),
        NO_ID         => 1,
        SORT_KEY_NUM  => 1,
        MAIN_MENU     => get_function_index('form_fees_types'),
      });

      if (!$attr->{REGISTRATION}) {
        $Fees->table_info('fees');

        $html->tpl_show(templates('form_fees'), { DESCRIBE => $FORM{DESCRIBE} || '', %{$Fees} }, { ID => 'form_fees' });
      }
    }
  }
  elsif ($FORM{AID} && !defined($LIST_PARAMS{AID})) {
    $FORM{subf} = $index;
    require Control::Admins_mng;
    form_admins();
    return 0;
  }
  elsif ($FORM{UID} && ! $FORM{type}) {
    form_users();
    return 0;
  }

  return 0 if (!$permissions{2}{0});

  form_fees_list({
    USER_INFO    => $attr->{USER_INFO},
    FEES_METHODS => $FEES_METHODS,
    BILL_ACCOUNTS=> \%BILL_ACCOUNTS
  });

  return 1;
}


#**********************************************************
=head2 form_fees_list($attr)

  Arguments:
    $attr
      FEES_METHODS
      BILL_ACCOUNTS

=cut
#**********************************************************
sub form_fees_list {
  my ($attr)=@_;

  my $FEES_METHODS = $attr->{FEES_METHODS};
  my $BILL_ACCOUNTS= $attr->{BILL_ACCOUNTS};

  if($FEES_METHODS) {
    $FEES_METHODS = get_fees_types();
  }

  my $Fees = Finance->fees($db, $admin, \%conf);

  my @service_status = ($lang{ENABLE}, $lang{DISABLE}, $lang{NOT_ACTIVE}, $lang{HOLD_UP},
    "$lang{DISABLE}: $lang{NON_PAYMENT}", $lang{ERR_SMALL_DEPOSIT});
  my @service_status_colors = ($_COLORS[9], $_COLORS[6], '#808080', '#0000FF', '#FF8000', '#009999');

  if (!defined($FORM{sort})) {
    $LIST_PARAMS{SORT} = 1;
    $LIST_PARAMS{DESC} = 'DESC';
  }

  my AXbills::HTML $table;
  my $fees_list;

  ($table, $fees_list) = result_former({
    INPUT_DATA      => $Fees,
    FUNCTION        => 'list',
    BASE_FIELDS     => 1,
    HIDDEN_FIELDS   => 'ADMIN_DISABLE',
    DEFAULT_FIELDS  => 'ID,LOGIN,DATETIME,DSC,SUM,LAST_DEPOSIT,METHOD,ADMIN_NAME',
    FUNCTION_FIELDS => 'del',
    EXT_TITLES      => {
      'id'           => $lang{NUM},
      'datetime'     => $lang{DATE},
      'dsc'          => $lang{DESCRIBE},
      'sum'          => $lang{SUM},
      'last_deposit' => $lang{OPERATION_DEPOSIT},
      'deposit'      => $lang{CURRENT_DEPOSIT},
      'method'       => $lang{TYPE},
      'ip'           => 'IP',
      'reg_date'     => "$lang{FEES} $lang{REGISTRATION}",
      'admin_name'   => $lang{ADMIN},
      'tax'          => $lang{TAX},
      'tax_sum'      => "$lang{TAX} $lang{SUM}",
      'invoice_id'   => $lang{INVOICE},
    },
    TABLE => {
      width            => '100%',
      caption          => $lang{FEES},
      SHOW_FULL_LIST   => ($FORM{UID}) ? 1 : undef,
      qs               => $pages_qs,
      pages            => $Fees->{TOTAL},
      ID               => 'FEES',
      EXPORT           => 1,
      MENU             => "$lang{SEARCH}:search_form=1&index=3:search",
      SHOW_COLS_HIDDEN => {
        TYPE_PAGE => $FORM{type}
      }
    },
  });

  $table->{SKIP_FORMER}=1;

  _error_show($Fees);

  my %i2p_hash = ();
  if (in_array('Docs', \@MODULES)) {

    our $Docs;
    load_module('Docs', $html);
    my @fees_ids = ();
    foreach my $p (@$fees_list) {
      push @fees_ids, $p->{id};
    }

    my $i2p_list = $Docs->invoices_list({
      FEES_ID    => join(';', @fees_ids),
      PAGE_ROWS  => ($LIST_PARAMS{PAGE_ROWS} || 25)*3,
      SUM        => '_SHOW',
      COLS_NAME  => 1
    });

    foreach my $i2p (@$i2p_list) {
      push @{ $i2p_hash{$i2p->{id}} },
        {
          payment_id  => $i2p->{payment_id} || '',
          payment_sum => $i2p->{payment_sum} || '',
          invoice_sum => $i2p->{invoice_sum} || '',
          invoice_num => $i2p->{invoice_num} || ''
        }
    }
  }

  $pages_qs .= "&subf=2" if (!$FORM{subf});
  foreach my $fee (@$fees_list) {
    my $delete = ($permissions{2}{2}) ? $html->button( $lang{DEL},
      "index=3&del=$fee->{id}$pages_qs" . (($pages_qs !~ /UID=/) ? "&UID=$fee->{uid}" : ''),
      { MESSAGE => "$lang{DEL} [$fee->{id}] ?", class => 'del' } ) : '';

    my @fields_array = ();
    for (my $i = 0; $i < 1+$Fees->{SEARCH_FIELDS_COUNT}; $i++) {
      my $field_name = $Fees->{COL_NAMES_ARR}->[$i];

      if ($conf{EXT_BILL_ACCOUNT} && $field_name eq 'ext_bill_deposit') {
        $fee->{ext_bill_deposit} = ($fee->{ext_bill_deposit} < 0) ? $html->color_mark($fee->{ext_bill_deposit}, $_COLORS[6]) : $fee->{ext_bill_deposit};
      }
      elsif($field_name eq 'deleted') {
        $fee->{deleted} //= 0;
        $fee->{deleted} = $html->color_mark($bool_vals[ $fee->{deleted} ], ($fee->{deleted} == 1) ? $state_colors[ $fee->{deleted} ] : '');
      }
      elsif($field_name eq 'login' && $fee->{uid}) {
        $fee->{login} = $html->button($fee->{login}, "index=15&UID=$fee->{uid}");
      }
      elsif($field_name eq 'dsc') {
        # fees period from-to
        $fee->{dsc} =~ s/(\d{4}-\d{2}-\d{2})-(\d{4}-\d{2}-\d{2})/$lang{FROM} $1 $lang{TO} $2/g;
        $fee->{$field_name} = AXbills::Base::convert($fee->{$field_name}, { text2html => 1 });
        $fee->{inner_describe} = AXbills::Base::convert($fee->{inner_describe}, { text2html => 1 }) if ($fee->{inner_describe});

        $fee->{dsc} //= '';
        if ($fee->{dsc} =~ /# (\d+)/ && in_array('Msgs', \@MODULES)) {
          $fee->{dsc} = $html->button($fee->{dsc}, "index=". get_function_index('msgs_admin')."&chg=$1");
        }

        $fee->{dsc} = _translate($fee->{dsc});
        $fee->{dsc} = ($fee->{dsc} || q{}) . $html->b(" ($fee->{inner_describe})") if ($fee->{inner_describe});
      }
      elsif($field_name =~ /deposit/ && defined($fee->{$field_name})) {
        $fee->{$field_name} = ($fee->{$field_name} < 0) ? $html->color_mark($fee->{$field_name}, $_COLORS[6]) : $fee->{$field_name};
      }
      elsif($field_name eq 'method') {
        $fee->{method} //= 0;
        $fee->{method} = ($FORM{METHOD_NUM}) ? $fee->{method} : ($FEES_METHODS->{ $fee->{method} } || $fee->{method} );
      }
      elsif($field_name eq 'login_status' && defined($fee->{$field_name})) {
        $fee->{login_status} = ($fee->{login_status} > 0) ? $html->color_mark($service_status[ $fee->{login_status} ], $service_status_colors[ $fee->{login_status} ]) : $service_status[$fee->{login_status}];
      }
      elsif($field_name eq 'bill_id') {
        $fee->{bill_id} = ($conf{EXT_BILL_ACCOUNT} && $attr->{USER_INFO}) ? ($BILL_ACCOUNTS->{ $fee->{bill_id} } || q{--}) : $fee->{bill_id};
      }
      elsif($field_name eq 'admin_name') {
        $fee->{admin_name} = _status_color_state($fee->{admin_name}, $fee->{admin_disable});
        delete $fee->{admin_disable};
      }
      elsif($field_name eq 'invoice_id') {
        my $invoice_id = $fee->{invoice_id} || 0;
        if ($invoice_id > 0) {
          my $payment_sum = $fee->{sum};
          my $i2p         = '';

          if ($i2p_hash{$invoice_id}) {
            foreach my $invoice ( @{ $i2p_hash{$invoice_id} }  ) {
              #my $payment_id = $invoice->{payment_id};
              my $paid_sum = $invoice->{payment_sum};
              my $invoice_num = $invoice->{invoice_num};
              #my $invoiced_sum = $invoice->{invoice_sum};

              $i2p .= sprintf("$lang{PAID}: %.2f",  $paid_sum || 0) ." $lang{INVOICE} #" . $html->button( $invoice_num,
                "index=" . get_function_index( 'docs_invoices_list' ) . "&ID=$invoice_id&search=1" ) . $html->br();
              $payment_sum -= $paid_sum || 0;
            }
          }

          if ($payment_sum > 0) {
            $i2p .= sprintf( "%.2f", $payment_sum ) . ' ' . $html->color_mark( $lang{UNAPPLIED},
              $_COLORS[6] ) . ' (' . $html->button( $lang{APPLY}, "index=2&SUM=$payment_sum"
                . "&UNINVOICED=$invoice_id&FEES_ID=$fee->{id}&UID=$fee->{uid}&INVOICE_ID=$invoice_id" ) . ')';
          }

          $fee->{invoice_id} = $i2p;
        }
        else {
          $fee->{invoice_id} = $html->button('ADD',
            'index=' . get_function_index('docs_invoices_list')
              . '&SUM_1=' . $fee->{sum}
              . '&ORDER_1=' . $fee->{dsc}
              . '&UID=' . $fee->{uid}
              . '&FEES_ID_1=' . $fee->{id},
            { BUTTON => 2, TITLE => "$lang{INVOICE} $lang{ADD}" });
        }
      }

      if ($Fees->{SEARCH_FIELDS_COUNT} == $i) {
        delete $fee->{admin_disable};
      }

      push @fields_array, $fee->{$field_name};
    }

    $table->addrow(@fields_array, $delete);
  }

  if (!$admin->{MAX_ROWS}) {
    $table->addfooter(
      '',
      "$lang{TOTAL}: " .  $Fees->{TOTAL} . $html->br()
        . (($Fees->{TOTAL_USERS} && $Fees->{TOTAL_USERS} > 1) ? "$lang{USERS}: " .  ($Fees->{TOTAL_USERS}) .$html->br() : q{})
        . "$lang{SUM}: " . format_sum($Fees->{SUM})
    );
  }

  print $table->show();

  return 1;
}

#**********************************************************
=head2 dynamic_types($attr) - change {TEXT} to current value

  Arguments:
    $attr:
      FEES_METHODS_HASH - hash of fees types
      FEES_METHODS_STR - string(one fees type)
    
  Returns:
    return fees_method

  Example:
    dynamic_types({FEES_METHODS_STR => $fees_info->{DEFAULT_DESCRIBE}})
=cut
#**********************************************************
sub dynamic_types {
  my ($attr) = @_;

  my ($y, $m, $d) = split(/-/, $DATE, 3);
  my $m_lit = $MONTHES[ int($m) - 1 ];
  my $y_lit = "$y $lang{YEAR_SHORT}";

  my $my_dynamic_types = {
    MONTH => $m_lit,
    DAY   => $d,
    YEAR  => $y_lit,
    ADMIN => $admin->{ADMIN}
  };

  if ($attr->{FEES_METHODS_HASH}) {
    foreach my $item (values %{$attr->{FEES_METHODS_HASH}}) {
      $item =~ s/\{(\w+)\}/($my_dynamic_types->{$1} || $1)/ge;
    }
    return $attr->{FEES_METHODS_HASH} || q{};
  }

  if ($attr->{FEES_METHODS_STR}) {
    $attr->{FEES_METHODS_STR} =~ s/\{(\w+)\}/($my_dynamic_types->{$1} || $1)/ge;
    return $attr->{FEES_METHODS_STR} || q{};
  }

  return q{};
}


1;
