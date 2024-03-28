=head1 NAME

  Payments manipulation

=cut


use strict;
use warnings FATAL => 'all';
use AXbills::Base qw(in_array mk_unique_value convert);
use AXbills::Defs;

our(
  $db,
  %conf,
  $admin,
  %lang,
  %permissions,
  @MONTHES,
  @WEEKDAYS,
  %err_strs,
  @bool_vals,
  @state_colors,
  @service_status_colors,
  @service_status,
);

my $Payments = Finance->payments($db, $admin, \%conf);
our AXbills::HTML $html;

#**********************************************************
=head2 form_payments($attr) Payments form

  Arguments:
    $attr

=cut
#**********************************************************
sub form_payments {
  my ($attr) = @_;

  return 0 if (!$permissions{1});

  my $allowed_payments = $Payments->admin_payment_type_list({
    COLS_NAME => 1,
    AID => $admin->{AID},
  });

  my @allowed_payments_ids = map { $_->{payments_type_id} } @{ $allowed_payments };

  my $payment_list = $Payments->payment_type_list({
    COLS_NAME => 1,
    FEES_TYPE => '_SHOW',
    SORT      => 'id',
    IDS       => scalar @allowed_payments_ids ? \@allowed_payments_ids : undef,
  });

  foreach my $line (@$payment_list) {
    $attr->{DEFAULT_ID} = $line->{id} if ($line->{default_payment});
    $attr->{PAYMENTS_METHODS}->{$line->{id}} = _translate($line->{name});
    if ($FORM{METHOD} && $FORM{METHOD} == $line->{id} && $line->{fees_type}) {
      $attr->{GET_FEES}=$line->{fees_type};
      last;
    }
  }

  our $Docs;
  if (in_array('Docs', \@MODULES)) {
    load_module('Docs', $html);
    if ($FORM{print}) {
      if ($FORM{INVOICE_ID}) {
        docs_invoice(\%FORM);
      }
      else {
        docs_receipt(\%FORM);
      }
      exit;
    }
  }

  if (($FORM{search_form} || $FORM{search}) && $index != 7) {
    form_search({
      HIDDEN_FIELDS => {
        subf       => ($FORM{subf}) ? $FORM{subf} : undef,
        COMPANY_ID => $FORM{COMPANY_ID},
        LEAD_ID    => $FORM{LEAD_ID}
      },
      ID            => 'SEARCH_PAYMENTS',
      CONTROL_FORM  => 1
    });
  }

  if ($attr->{USER_INFO}) {
    my $user = $attr->{USER_INFO};
    $Payments->{UID} = $user->{UID};

    if (in_array('Docs', \@MODULES)) {
      $FORM{QUICK} = 1;
    }

    if (!$attr->{REGISTRATION}) {
      if (! $user->{BILL_ID}) {
        form_bills({ USER_INFO => $user });
        return 0;
      }
    }

    if ($FORM{OP_SID} && $FORM{OP_SID} eq ($COOKIES{OP_SID} || q{})) {
      $html->message( 'err', $lang{ERROR}, "$lang{EXIST}" );
    }
    elsif ($FORM{add} && $FORM{SUM}) {
      payment_add($attr);
    }
    elsif ($FORM{del} && $FORM{COMMENTS}) {
      if (!defined($permissions{1}{2})) {
        $html->message( 'err', $lang{ERROR}, "[13] $err_strs{13}" );
        return 0;
      }

      my $payment_info = $Payments->list({
        ID         => $FORM{del},
        UID        => '_SHOW',
        DATETIME   => '_SHOW',
        SUM        => '_SHOW',
        DESCRIBE   => '_SHOW',
        EXT_ID     => '_SHOW',
        COLS_NAME  => 1,
        COLS_UPPER => 1,
      });

      $Payments->del($user, $FORM{del}, { COMMENTS => $FORM{COMMENTS} });
      if ($Payments->{errno}) {
        if ($Payments->{errno} == 3) {
          $html->message( 'err', $lang{ERROR}, "$lang{ERR_DELETE_RECEIPT} " .
              $html->button( $lang{SHOW},
                "search=1&PAYMENT_ID=$FORM{del}&index=" . (get_function_index( 'docs_receipt_list' )),
                { BUTTON => 1 } ) );
        }
        else {
          _error_show($Payments);
        }
      }
      else {
        cross_modules('payment_del', { %$attr, FORM => \%FORM, ID => $FORM{del}, PAYMENT_INFO => $payment_info->[0] });
        $html->message( 'info', $lang{PAYMENTS}, "$lang{DELETED} ID: $FORM{del}" );
      }
    }

    return 1 if ($attr->{REGISTRATION} && $FORM{add});
    form_payment_add($attr);
  }
  elsif ($FORM{AID} && !defined($LIST_PARAMS{AID})) {
    $FORM{subf} = $index;
    require Control::Admins_mng;
    form_admins();
    return 0;
  }
  elsif ($FORM{UID} && ! $FORM{type}) {
    $index = get_function_index('form_payments');
    form_users();
    return 0;
  }

  form_payments_list($attr);

  return 0;
}

#**********************************************************
=head2 form_payment_add($attr)

  Arguments:
    $attr
      GET_FEES

=cut
#**********************************************************
sub form_payment_add {
  my ($attr) = @_;

  my $user = $attr->{USER_INFO};
  our $Docs;

  if ($user->{GID}) {
    $user->group_info($user->{GID});
    if ($user->{DISABLE_PAYMENTS}) {
      $html->message('err', $lang{ERROR}, "$lang{DISABLE} $lang{PAYMENTS} $lang{CASHBOX}");
      return 0;
    }
  }
  my %BILL_ACCOUNTS = ();
  if ($conf{EXT_BILL_ACCOUNT}) {
    $BILL_ACCOUNTS{ $user->{BILL_ID} } = "$lang{PRIMARY} : $user->{BILL_ID}" if ($user->{BILL_ID});
    $BILL_ACCOUNTS{ $user->{EXT_BILL_ID} } = "$lang{EXTRA} : $user->{EXT_BILL_ID}" if ($user->{EXT_BILL_ID});
  }

  my $PAYMENTS_METHODS = $attr->{PAYMENTS_METHODS};

  #exchange rate sel
  my $er_list   = $Payments->exchange_list({%FORM, COLS_NAME => 1 });
  my %ER_ISO2ID = ();
  foreach my $line (@$er_list) {
    $ER_ISO2ID{ $line->{iso} } = $line->{id};
  }

  if ($FORM{ER} && $FORM{ISO}) {
    $FORM{ER} = $ER_ISO2ID{ $FORM{ISO} };
    $FORM{ER_ID} = $ER_ISO2ID{ $FORM{ISO} };
  }
  elsif($conf{SYSTEM_CURRENCY}) {
    $FORM{ER_ID} = $ER_ISO2ID{ $conf{SYSTEM_CURRENCY} };
  }

  if ($Payments->{TOTAL} > 0) {
    $Payments->{SEL_ER} = $html->form_select('ER', {
      SELECTED       => $FORM{ER_ID} || $FORM{ER},
      SEL_LIST       => $er_list,
      SEL_KEY        => 'id',
      SEL_VALUE      => 'money,rate',
      NO_ID          => 1,
      MAIN_MENU      => get_function_index('form_exchange_rate'),
      MAIN_MENU_ARGV => "chg=" . ($FORM{ER} || ''),
      SEL_OPTIONS    => { '' => '' }
    });

    $Payments->{ER_FORM} = $html->tpl_show(templates('form_row'), {
      ID         => '',
      NAME       => "$lang{CURRENCY} : $lang{EXCHANGE_RATE}",
      VALUE      => $Payments->{SEL_ER},
      COLS_LEFT  => 'col-md-3',
      COLS_RIGHT => 'col-md-9',
    }, { OUTPUT2RETURN => 1 });
  }

  $Payments->{SEL_METHOD} = $html->form_select('METHOD', {
    SELECTED => (defined($FORM{METHOD}) && $FORM{METHOD} ne '') ? $FORM{METHOD} : ($attr->{DEFAULT_ID} || 0),
    SEL_HASH => $PAYMENTS_METHODS,
    NO_ID    => 1,
  });

  if ($permissions{1} && $permissions{1}{1}) {
    $Payments->{OP_SID} = ($FORM{OP_SID}) ? $FORM{OP_SID} : mk_unique_value(16);

    if ($conf{EXT_BILL_ACCOUNT}) {
      $Payments->{EXT_DATA_FORM} = $html->tpl_show(templates('form_row'), {
        ID    => 'BILL_ID',
        NAME  => $lang{BILL},
        VALUE => $html->form_select('BILL_ID', {
          SELECTED => $FORM{BILL_ID} || $attr->{USER_INFO}->{BILL_ID},
          SEL_HASH => \%BILL_ACCOUNTS,
          NO_ID    => 1
        }),
      }, { OUTPUT2RETURN => 1 });
    }

    if ($permissions{1}{4}) {
      if ($COOKIES{hold_date}) {
        ($DATE, $TIME) = split(/ /, $COOKIES{hold_date}, 2);
      }

      if ($FORM{DATE}) {
        ($DATE, $TIME) = split(/ /, $FORM{DATE});
      }

      my $date_field = $html->form_datetimepicker('DATE', $FORM{DATE}, {
        FORM_ID => 'user_form',
        FORMAT  => 'YYYY-MM-DD HH:mm:ss'
      });

      $Payments->{VALUE} = $date_field;
      $Payments->{ADDON} = $html->form_input( 'hold_date', '1', {
        TYPE      => 'checkbox',
        EX_PARAMS => "NAME='hold_date' data-tooltip='$lang{HOLD}'",
        ID        => 'DATE',
        STATE     => (($COOKIES{hold_date}) ? 1 : undef)
      }, { OUTPUT2RETURN => 1 });

      $Payments->{DATE_FORM} = $html->tpl_show(templates('form_row_dynamic_size_input_group'), {
        ID    => 'DATE',
        NAME  => $lang{DATE} . ':',
        VALUE => $date_field,
        ADDON => $html->form_input('hold_date', '1', {
          TYPE      => 'checkbox',
          EX_PARAMS => "NAME='hold_date' data-tooltip='$lang{HOLD}'",
          ID        => 'DATE',
          STATE     => (($COOKIES{hold_date}) ? 1 : undef) }, { OUTPUT2RETURN => 1 }) },
        { OUTPUT2RETURN => 1 });
    }

    _docs_invoice_receipt($user);

    if ($attr->{ACTION}) {
      $Payments->{ACTION}     = $attr->{ACTION};
      $Payments->{LNG_ACTION} = $attr->{LNG_ACTION};
    }
    else {
      $Payments->{ACTION}     = 'add';
      $Payments->{LNG_ACTION} = $lang{ADD};
    }

    if( in_array('Employees', \@MODULES)){
      require Employees::Salary;
      Employees->import();
      my $Employees = Employees->new($db, $admin, \%conf);

      my $admin_cash = $attr->{USER_INFO}{admin}{AID};
      my $employees_cash_all;
      if($conf{EMPLOYEES_CASHBOX_ALL}){
        my @cash_all = split(',',$attr->{USER_INFO}{conf}{EMPLOYEES_CASHBOX_ALL});
        if(in_array("$admin_cash", \@cash_all)) {
          $employees_cash_all = $Employees->employees_payments_cashbox({ COLS_NAME => 1 });
        }
      }
      my $employees_cash = $Employees->employees_payments_cashbox({ COLS_NAME => 1, AID => $admin_cash});

      #  get default cash for current admin
      my $cashbox_id = '';
      for my $key (@$employees_cash){
        if ($key->{aid_default} == $admin_cash){
          $cashbox_id = $key->{id};
        }
      }

      my %params = ("" => "");

      if ($Employees->{TOTAL} == 1) {
        %params = (REQUIRED => 1);
      }

      $attr->{CASHBOX_SELECT} = $html->form_select('CASHBOX_ID', {
        SELECTED  => $conf{EMPLOYEES_DEFAULT_CASHBOX} || $FORM{CASHBOX_ID} || $attr->{CASHBOX_ID} || $cashbox_id,
        SEL_LIST  => $employees_cash_all || $employees_cash,
        SEL_KEY   => 'id',
        SEL_VALUE => 'name',
        NO_ID     => 1,
        MAIN_MENU => get_function_index('employees_cashbox_main'),
        %params
      });
    }
    else {
      $attr->{CASHBOX_HIDDEN} = 'hidden'
    }

    if(in_array('Cards', \@MODULES)) {
      $attr->{CARDS_BTN}=$html->button($lang{ICARDS},
        "index=". get_function_index('cards_user_payment'). "&UID=$Payments->{UID}",
        { BUTTON => 1 })
    }

    $Payments->{ADMIN_PAY} = $lang{ADMIN_PAY};
    $Payments->table_info('payments');

    $attr->{MAX_PAYMENT} = $conf{MAX_ADMIN_PAYMENT} || 99999999;
    if ($attr->{EXT_HTML}) {
      my $payment_template = $html->tpl_show(templates('form_payments'),
        { %FORM, %{$attr}, %{$Payments} }, { ID => 'form_payments', OUTPUT2RETURN => 1 }
      );
      print "<div class='row'><div class='col-md-6'>" . $attr->{EXT_HTML} . "</div>";
      print "<div class='col-md-6'>" . $payment_template . "</div></div>";
    }
    else {
      $html->tpl_show(templates('form_payments'), { %FORM, %{$attr}, %{$Payments} }, { ID => 'form_payments'  });
    }
  }

  return 1;
}

#**********************************************************
=head2 _docs_invoice_receipt()

=cut
#**********************************************************
sub _docs_invoice_receipt {
  my $user = shift;
  
  return if !in_array('Docs', \@MODULES) || $conf{DOCS_PAYMENT_DOCS_SKIP};

  if ($user->{GID}) {
    $user->group_info($user->{GID});
    return if !$user->{DOCUMENTS_ACCESS};
  }
  
  our $Docs;
  $Payments->{INVOICE_SEL} = $html->form_select('INVOICE_ID', {
    SELECTED         => $FORM{INVOICE_ID} || 'create' || 0,
    SEL_LIST         => $Docs->invoices_list({
      UID       => $FORM{UID},
      UNPAIMENT => 1,
      PAGE_ROWS => 200,
      SORT      => 2,
      DESC      => 'DESC',
      COLS_NAME => 1
    }),
    SEL_KEY          => 'id',
    SEL_VALUE        => 'invoice_num,date,total_sum,payment_sum',
    SEL_VALUE_PREFIX => "$lang{NUM}: ,$lang{DATE}: ,$lang{SUM}: ,$lang{PAYMENTS}: ",
    SEL_OPTIONS      => {
      0 => $lang{DONT_CREATE_INVOICE},
      %{(!$conf{PAYMENTS_NOT_CREATE_INVOICE}) ? { create => $lang{CREATE} } : {}}
    },
    NO_ID            => 1,
    MAIN_MENU        => get_function_index('docs_invoices_list'),
    MAIN_MENU_ARGV   => "UID=$FORM{UID}&INVOICE_ID=" . ($FORM{INVOICE_ID} || q{}),
  });

  delete($FORM{pdf});
  $Payments->{CREATE_RECEIPT_CHECKED}='checked'  if !$conf{DOCS_PAYMENT_RECEIPT_SKIP};
  $Payments->{SEND_MAIL}= $conf{DOCS_PAYMENT_SENDMAIL} ? 1 : 0;

  $Payments->{DOCS_INVOICE_RECEIPT_ELEMENT} = $html->tpl_show(_include('docs_create_invoice_receipt', 'Docs'),
    { %$Payments }, { OUTPUT2RETURN => 1 });
}

#**********************************************************
=head2 payment_add($attr)

=cut
#**********************************************************
sub payment_add {
  my ($attr) = @_;

  if(! $permissions{1} || ! $permissions{1}{1}) {
    $html->message('err', $lang{ERROR}, $lang{ERR_ACCESS_DENY});
    return 0;
  }

  our $Docs;
  my $er;
  my $user = $attr->{USER_INFO};
  #$Payments->{AUTOFOCUS}  = '';
  $FORM{SUM} =~ s/,/\./g;

  $db->{TRANSACTION}=1;
  my DBI $db_ = $db->{db};
  $db_->{AutoCommit} = 0;

  if ($FORM{SUM} !~ /[0-9\.]+/) {
    $html->message( 'err', $lang{ERROR}, "$lang{ERR_WRONG_SUM} SUM: $FORM{SUM}", { ID => 22 });
    return 0 if ($attr->{REGISTRATION});
  }
  else {
    my $max_payment = $conf{MAX_ADMIN_PAYMENT} || 99999999;
    if ($FORM{SUM} > $max_payment) {
      $html->message('err', "$lang{PAYMENTS}: $lang{ERR_WRONG_SUM}", "$lang{ALLOW} $lang{SUM}: < $max_payment \n$lang{PAYMENTS} $lang{SUM}: $FORM{SUM}");
      return 0;
    }

    $FORM{CURRENCY} = $conf{SYSTEM_CURRENCY};

    if ($FORM{ER}) {
      if ($FORM{DATE}) {
        my $list = $Payments->exchange_log_list({
          DATE      => "<=$FORM{DATE}",
          ID        => $FORM{ER},
          SORT      => 'date',
          DESC      => 'desc',
          PAGE_ROWS => 1
        });
        $FORM{ER_ID}    = $FORM{ER};
        $FORM{ER}       = $list->[0]->[2] || 1;
        $FORM{CURRENCY} = $list->[0]->[4] || 0;
      }
      else {
        $er = $Payments->exchange_info($FORM{ER});
        $FORM{ER_ID}    = $FORM{ER};
        $FORM{ER}       = $er->{ER_RATE};
        $FORM{CURRENCY} = $er->{ISO};
      }
    }

    $attr->{AMOUNT} = $FORM{SUM};
    if ($FORM{ER} && $FORM{ER} != 1 && $FORM{ER} > 0) {
      $FORM{PAYMENT_SUM} = sprintf("%.2f", $FORM{SUM} / $FORM{ER});
    }
    else {
      $FORM{PAYMENT_SUM} = $FORM{SUM};
    }

    my $uid = $user->{UID};
    #Make pre payments functions in all modules
    cross_modules('pre_payment', { %$attr, FORM => \%FORM });

    if (!$conf{PAYMENTS_NOT_CHECK_INVOICE_SUM} && ($FORM{INVOICE_SUM} && $FORM{INVOICE_SUM} != $FORM{PAYMENT_SUM})) {
      $html->message( 'err', "$lang{PAYMENTS}: $lang{ERR_WRONG_SUM}",
        " $lang{INVOICE} $lang{SUM}: " . ($Docs->{TOTAL_SUM} || 0) . "\n $lang{PAYMENTS} $lang{SUM}: $FORM{SUM}" );
    }
    else {
      $user->{UID} = $uid;
      $Payments->add($user, { %FORM, INNER_DESCRIBE => ($FORM{INNER_DESCRIBE} || q{})
        . (($FORM{DATE} && $COOKIES{hold_date}) ? " $DATE $TIME" : '') });

      if (_error_show($Payments)) {
        return 0 if ($attr->{REGISTRATION});
      }
      else {
        if( in_array('Employees', \@MODULES) && $FORM{CASHBOX_ID}){
          require Employees::Salary;
          Employees->import();
          my $Employees = Employees->new($db, $admin, \%conf);
          my $coming_type = $Employees->employees_list_coming_type({ COLS_NAME => 1});

          my $id_type;
          foreach my $key (@$coming_type) {
            if ($key->{default_coming} == 1){
              $id_type = $key->{id};
            }
          }

          $Employees->employees_add_coming({
            DATE           => $FORM{DATE} || $DATE,
            AMOUNT         => $FORM{SUM},
            CASHBOX_ID     => $FORM{CASHBOX_ID},
            COMING_TYPE_ID => $id_type,
            COMMENTS       => $FORM{DESCRIBE},
            AID            => $admin->{AID},
            UID            => $user->{UID},
          });

          _error_show($Employees);
        }

        $FORM{SUM} = $Payments->{SUM};
        $html->message( 'info', $lang{PAYMENTS}, "$lang{ADDED} $lang{SUM}: $FORM{SUM} ". ($er->{ER_SHORT_NAME} || q{}) );

        if ($conf{external_payments}) {
          if (!_external($conf{external_payments}, { %FORM  })) {
            return 0;
          }
        }

        #Make cross modules Functions
        $FORM{PAYMENTS_ID} = $Payments->{PAYMENT_ID};

        cross_modules('payments_maked', {
          %$attr,
          METHOD       => $FORM{METHOD},
          SUM          => $FORM{SUM},
          AMOUNT       => $attr->{AMOUNT},
          PAYMENT_ID   => $Payments->{PAYMENT_ID},
          SKIP_MODULES => 'Sqlcmd',
          FORM         => \%FORM
        });
      }
    }

    if ($attr->{GET_FEES}) {
      my $Fees = Finance->fees($db, $admin, \%conf);
      $Fees->take($user, $FORM{SUM}, {
        DESCRIBE => ($FORM{DESCRIBE} || q{}) . " PAYMENT: $Payments->{PAYMENT_ID}",
        METHOD   => $attr->{GET_FEES}
      });
    }
  }

  if (! $attr->{REGISTRATION} && ! $db->{db}->{AutoCommit}) {
    $db_->commit();
    $db_->{AutoCommit}=1;
  }

  return 1;
}


#**********************************************************
=head2 form_payments_list()

=cut
#**********************************************************
sub form_payments_list {
  my ($attr) = @_;

  return 0 if (! $permissions{1}{0});

  my $PAYMENTS_METHODS = get_payment_methods();
  my $user = $attr->{USER_INFO};
  my %BILL_ACCOUNTS = ();
  if ($conf{EXT_BILL_ACCOUNT}) {
    $BILL_ACCOUNTS{ $user->{BILL_ID} } = "$lang{PRIMARY} : $user->{BILL_ID}" if ($user->{BILL_ID});
    $BILL_ACCOUNTS{ $user->{EXT_BILL_ID} } = "$lang{EXTRA} : $user->{EXT_BILL_ID}" if ($user->{EXT_BILL_ID});
  }

  if (! $FORM{sort}) {
    $LIST_PARAMS{SORT} = 1;
    $LIST_PARAMS{DESC} = 'DESC';
  }

  $LIST_PARAMS{ID} = $FORM{ID} if ($FORM{ID});

  if ($conf{SYSTEM_CURRENCY}) {
    $LIST_PARAMS{AMOUNT}='_SHOW' if (! $FORM{AMOUNT});
    $LIST_PARAMS{CURRENCY}='_SHOW' if (! $FORM{CURRENCY});
  }

  if ($FORM{INVOICE_NUM}) {
    $LIST_PARAMS{INVOICE_NUM} = $FORM{INVOICE_NUM};
  }

  if ($FORM{DESCRIBE}) {
    $LIST_PARAMS{DSC} = $FORM{DESCRIBE};
  }

  my AXbills::HTML $table;
  my $payments_list;

  ($table, $payments_list) = result_former({
    INPUT_DATA      => $Payments,
    FUNCTION        => 'list',
    BASE_FIELDS     => 1,
    HIDDEN_FIELDS   => 'ADMIN_DISABLE',
    DEFAULT_FIELDS  => 'DATETIME,LOGIN,DSC,SUM,LAST_DEPOSIT,METHOD,EXT_ID',
    FUNCTION_FIELDS => 'del',
    EXT_TITLES      => {
      'id'              => $lang{NUM},
      'datetime'        => $lang{DATE},
      'dsc'             => $lang{DESCRIBE},
      'dsc2'            => "$lang{DESCRIBE} 2",
      'inner_describe2' => "$lang{INNER}",
      'sum'             => $lang{SUM},
      'last_deposit'    => $lang{OPERATION_DEPOSIT},
      'deposit'         => $lang{CURRENT_DEPOSIT},
      'method'          => $lang{PAYMENT_METHOD},
      'ext_id'          => 'EXT ID',
      'reg_date'        => "$lang{PAYMENTS} $lang{REGISTRATION}",
      'ip'              => 'IP',
      'admin_name'      => $lang{ADMIN},
      'invoice_num'     => $lang{INVOICE},
      amount            => "$lang{ALT} $lang{SUM}",
      currency          => $lang{CURRENCY},
      after_deposit     => $lang{AFTER_OPERATION_DEPOSIT}
    },
    TABLE           => {
      width            => '100%',
      SHOW_FULL_LIST   => ($FORM{UID}) ? 1 : undef,
      caption          => $lang{PAYMENTS},
      qs               => $pages_qs,
      EXPORT           => 1,
      ID               => 'PAYMENTS',
      MENU             => "$lang{SEARCH}:search_form=1&index=2" . (($FORM{UID}) ? "&UID=$FORM{UID}&LOGIN=" . ($users->{LOGIN} || q{}) : q{}) . ":search",
      SHOW_COLS_HIDDEN => {
        TYPE_PAGE => $FORM{type}
      }
    },
  });

  $table->{SKIP_FORMER}=1;

  my %i2p_hash = ();
  if (in_array('Docs', \@MODULES)) {

    our $Docs;
    load_module('Docs', $html);
    my @payment_id_arr = ();
    foreach my $p (@$payments_list) {
      push @payment_id_arr, $p->{id};
    }

    my $i2p_list = $Docs->invoices2payments_list({
      PAYMENT_ID => join(';', @payment_id_arr),
      PAGE_ROWS  => ($LIST_PARAMS{PAGE_ROWS} || 25)*3,
      COLS_NAME  => 1
    });

    foreach my $i2p (@$i2p_list) {
      push @{ $i2p_hash{$i2p->{payment_id}} }, ($i2p->{invoice_id} || '') .':'. ($i2p->{invoiced_sum} || '') .':'. ($i2p->{invoice_num} || '');
    }
  }

  $pages_qs .= "&subf=2" if (!$FORM{subf});

  foreach my $line (@$payments_list) {
    my $delete = ($permissions{1}{2}) ? $html->button( $lang{DEL},
        "index=2&del=$line->{id}$pages_qs". (($pages_qs !~ /UID=/) ? "&UID=$line->{uid}" : q{} ),
        { MESSAGE => "$lang{DEL} [$line->{id}] ?", class => 'del' } ) : '';

    my @fields_array = ();
    for (my $i = 0; $i < 1+$Payments->{SEARCH_FIELDS_COUNT}; $i++) {
      my $field_name = $Payments->{COL_NAMES_ARR}->[$i] || q{};

      if ($conf{EXT_BILL_ACCOUNT} && $field_name eq 'ext_bill_deposit') {
        $line->{ext_bill_deposit} = ($line->{ext_bill_deposit} < 0) ? $html->color_mark($line->{ext_bill_deposit}, $_COLORS[6]) : $line->{ext_bill_deposit};
      }
      elsif($field_name eq 'deleted') {
        if (defined($line->{deleted})){
          $line->{deleted} = $html->color_mark( $bool_vals[ $line->{deleted} ],
              ($line->{deleted} && $line->{deleted} == 1) ? $state_colors[ $line->{deleted} ] : '' );
        }
      }
      elsif ($field_name eq 'ext_id' && $line->{ext_id}) {
        $line->{ext_id} = convert($line->{ext_id}, { text2html => 1 });
      }
      elsif($field_name eq 'login' && $line->{uid}) {
        $line->{login} = $html->button($line->{login}, "index=15&UID=$line->{uid}");
      }
      elsif($field_name eq 'dsc') {
        if ($line->{dsc}) {
          $line->{$field_name} = convert($line->{$field_name}, { text2html => 1 });
        }

        $line->{dsc} = ($line->{dsc} || q{}) . $html->b("($line->{inner_describe})") if ($line->{inner_describe});
      }
      elsif($field_name =~ /deposit/ && defined($line->{$field_name})) {
        $line->{$field_name} = ($line->{$field_name} < 0) ? $html->color_mark( format_sum($line->{$field_name}), $_COLORS[6] ) :  format_sum($line->{$field_name});
      }
      elsif($field_name eq 'method') {
        $line->{method} = ($FORM{METHOD_NUM}) ? $line->{method} : (defined($line->{method}) && $PAYMENTS_METHODS->{ defined($line->{method}) }) ? $PAYMENTS_METHODS->{ $line->{method} } : $line->{method};
      }
      elsif($field_name eq 'login_status' && defined($line->{login_status})) {
        $line->{login_status} = ($line->{login_status} > 0) ? $html->color_mark($service_status[ $line->{login_status} ], $service_status_colors[ $line->{login_status} ]) : $service_status[$line->{login_status}];
      }
      elsif ($field_name eq 'bill_id') {
        $line->{bill_id} = ($conf{EXT_BILL_ACCOUNT} && $attr->{USER_INFO}) ? $BILL_ACCOUNTS{ $line->{bill_id} } : $line->{bill_id};
      }
      elsif($field_name eq 'invoice_num') {
        if (in_array('Docs', \@MODULES) && ! $FORM{xml}) {
          my $payment_sum = $line->{sum};
          my $i2p         = '';

          if ($i2p_hash{$line->{id}}) {
            foreach my $val ( @{ $i2p_hash{$line->{id}} }  ) {
              my ($invoice_id, $invoiced_sum, $invoice_num)=split(/:/, $val);
              $i2p .= "$lang{PAID}: $invoiced_sum $lang{INVOICE} #" . $html->button( $invoice_num,
                "index=" . get_function_index( 'docs_invoices_list' ) . "&ID=$invoice_id&search=1" ) . $html->br();
              $payment_sum -= $invoiced_sum;
            }
          }
          if ($payment_sum > 0) {
            $i2p .= sprintf( "%.2f", $payment_sum ) . ' ' . $html->color_mark( "$lang{UNAPPLIED}",
              $_COLORS[6] ) . ' (' . $html->button( $lang{APPLY},
              "index=" . get_function_index( 'docs_invoices_list' ) . "&UNINVOICED=1&PAYMENT_ID=$line->{id}&UID=$line->{uid}" ) . ')';
          }

          $line->{invoice_num} = $i2p;
        }
      }
      elsif($field_name eq 'admin_name') {
        $line->{admin_name} = _status_color_state($line->{admin_name}, $line->{admin_disable});
        delete $line->{admin_disable};
      }
      
      if ($Payments->{SEARCH_FIELDS_COUNT} == $i) {
        delete $line->{admin_disable};
      }

      push @fields_array, $line->{$field_name};
    }

    $table->addrow(@fields_array, $delete);
  }

  if (!$admin->{MAX_ROWS}) {
    $table->addfooter(
       '',
       "$lang{TOTAL}: " .  $Payments->{TOTAL} . $html->br()
       . (($Payments->{TOTAL_USERS} && $Payments->{TOTAL_USERS} > 1) ? "$lang{USERS}: " .  ($Payments->{TOTAL_USERS}) .$html->br() : q{})
       . "$lang{SUM}: " . format_sum($Payments->{SUM})
    );
  }

  print $table->show();
  return 1;
}

1;