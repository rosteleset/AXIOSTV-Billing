=head1 NAME

  User manage

=cut

use warnings FATAL => 'all';
use strict;
use AXbills::Base qw(in_array);
use AXbills::Defs;

our ($db,
  %lang,
  $admin,
  %permissions,
);

our AXbills::HTML $html;

#**********************************************************
=head2 add_company() - Add company

=cut
#**********************************************************
sub _add_company {

  my $Company;
  $Company->{ACTION}         = 'add';
  $Company->{LNG_ACTION}     = $lang{ADD};
  $Company->{BILL_ID}        = $html->form_input( 'CREATE_BILL', 1, { TYPE => 'checkbox', STATE => 1 } ) . ' ' . $lang{CREATE};
  $Company->{ADDRESS_TPL} = form_address({ %FORM, ADDRESS_HIDE => 1 });

  $Company->{INFO_FIELDS} = form_info_field_tpl({ COMPANY => 1, COLS_LEFT => 'col-md-3', COLS_RIGHT => 'col-md-9' });

  if (in_array('Docs', \@MODULES)) {
    $Company->{PRINT_CONTRACT} = $html->button( '',
      "qindex=15&UID=". ($Company->{UID} || '') ."&PRINT_CONTRACT=". ($Company->{UID} || '')  . (($conf{DOCS_PDF_PRINT}) ? '&pdf=1' : ''),
      { ex_params => ' target=new', class => 'btn input-group-button', ICON => 'fas fa-print' } );

    if ($conf{DOCS_CONTRACT_TYPES}) {
      $conf{DOCS_CONTRACT_TYPES} =~ s/\n//g;
      my (@contract_types_list) = split(/;/, $conf{DOCS_CONTRACT_TYPES});
      my %CONTRACTS_LIST_HASH = ();
      $FORM{CONTRACT_SUFIX} = '|'.($Company->{CONTRACT_SUFIX} || '');
      foreach my $line (@contract_types_list) {
        my ($prefix, $sufix, $name) = split(/:/, $line);
        $prefix =~ s/ //g;
        $CONTRACTS_LIST_HASH{"$prefix|$sufix"} = $name;
      }

      $Company->{CONTRACT_TYPE} = $html->tpl_show(templates('form_row'), {
        ID      => "",
        NAME    => $lang{TYPE},
        VALUE   => $html->form_select(
        'CONTRACT_TYPE', {
          SELECTED => $FORM{CONTRACT_SUFIX},
          SEL_HASH => { '' => '', %CONTRACTS_LIST_HASH },
          NO_ID    => 1
        })
      }, { OUTPUT2RETURN => 1 });
    }
  }

  $Company->{DOCS_TEMPLATE} = $html->tpl_show(_include('docs_form_pi_lite', 'Docs'), { %{$Company} }, { OUTPUT2RETURN => 1 });

  $html->tpl_show(templates('form_company_add'), $Company);

  return 1;
}


#**********************************************************
=head2 form_companies()

=cut
#**********************************************************
sub form_companies {
  require Customers;
  Customers->import();
  my $Customer = Customers->new($db, $admin, \%conf);
  my $Company  = $Customer->company();
  my $company_index = get_function_index('form_companies');

  if ($FORM{add_form} ) {
    if( $permissions{0}{37} ) {
      _add_company();
      return 0;
    }
  }
  elsif ($FORM{add} && !$FORM{import}) {
    if (!$permissions{0}{37}) {
      $html->message( 'err', $lang{ERROR}, "$lang{ERR_ACCESS_DENY}" );
      return 0;
    }
    if ($FORM{STREET_ID} && $FORM{ADD_ADDRESS_BUILD} && !$FORM{LOCATION_ID}) {
      require Address;
      Address->import();
      my $Address = Address->new($db, $admin, \%conf);
      $Address->build_add(\%FORM);
      $FORM{LOCATION_ID} = $Address->{LOCATION_ID};
    }

    if($FORM{LOCATION_ID}){
      require Control::Address_mng;
      $FORM{ADDRESS} = full_address_name($FORM{LOCATION_ID}). ($FORM{ADDRESS_FLAT} ? ', '. $FORM{ADDRESS_FLAT} : '');
    }

    $Company->add({%FORM});

    if (!$Company->{errno}) {
      $html->message( 'info', $lang{ADDED},
        "$lang{ADDED} " . $html->button( "$FORM{NAME}", 'index=13&COMPANY_ID=' . $Company->{COMPANY_ID}, { BUTTON => 2 } ) );
    }
  }
  elsif ($FORM{import}) {
    if (!$permissions{0}{37}) {
      $html->message( 'err', $lang{ERROR}, "$lang{ERR_ACCESS_DENY}" );
      return 0;
    }

    companies_import();
    return 1;
  }
  elsif ($FORM{change}) {
    if (!$permissions{0}{38}) {
      $html->message( 'err', $lang{ERROR}, "$lang{ERR_ACCESS_DENY}" );
      return 0;
    }
    if ($FORM{ADD_ADDRESS_BUILD}) {
      require Address;
      Address->import();
      my $Address = Address->new($db, $admin, \%conf);
      $Address->build_add({STREET_ID => $FORM{STREET_ID}, NUMBER => $FORM{ADD_ADDRESS_BUILD}});
      $FORM{LOCATION_ID} = $Address->{LOCATION_ID};
    }

    if($FORM{LOCATION_ID}){
      #require Address;
      #Address->import();
      require Control::Address_mng;
      $FORM{ADDRESS} = full_address_name($FORM{LOCATION_ID}). ($FORM{ADDRESS_FLAT} ? ', '. $FORM{ADDRESS_FLAT} : '');
    }

    if(! $FORM{ID} && $FORM{COMPANY_ID}) {
      $FORM{ID} = $FORM{COMPANY_ID};
    }

    $Company->change({%FORM});

    if (!$Company->{errno}) {
      $html->message( 'info', $lang{INFO}, $lang{CHANGED} . " # $Company->{NAME}" );
    }
  }
  elsif ($FORM{del} && $FORM{COMMENTS} && $permissions{0}{39} && !$FORM{subf}) {
    $Company->list({ COMPANY_ID => $FORM{del}, USERS_COUNT => '_SHOW', COLS_NAME => 1, });

    if ($Company->{TOTAL} > 0) {
      $html->message('err', $lang{WARNING}, "$lang{COMPANY} # $FORM{del} : $lang{NO_DELETE_COMPANY}!");
    }
    else {
      $Company->del($FORM{del});
      unless ($Company->{errno}) {
        $html->message('info', $lang{INFO}, "$lang{DELETED} # $FORM{del}");
      }
    }
  }

  _error_show($Company);

  if ($FORM{COMPANY_ID}) {
    $Company->info($FORM{COMPANY_ID} || $FORM{ID});

    if(_error_show($Company)) {
      return 1;
    }

    $Company->{COMPANY_NAME}   = $Company->{NAME};

    if ($FORM{PRINT_CONTRACT}) {
      load_module('Docs', $html);
      docs_contract({
        COMPANY_CONTRACT => 1,
        %$Company,
        SEND_EMAIL       => $FORM{SEND_EMAIL}
      });
      return 0;
    }

    $LIST_PARAMS{COMPANY_ID} = $Company->{ID};
    $FORM{COMPANY_ID}        = $Company->{ID};
    $LIST_PARAMS{BILL_ID}    = $Company->{BILL_ID} if (defined($Company->{DEPOSIT}));
    $pages_qs .= "&COMPANY_ID=$LIST_PARAMS{COMPANY_ID}" if ($LIST_PARAMS{COMPANY_ID});
    $pages_qs .= "&subf=$FORM{subf}" if ($FORM{subf} && $pages_qs !~ /subf/);

    if (in_array('Docs', \@MODULES)) {
      $Company->{PRINT_CONTRACT} = $html->button( '',
        "qindex=$index$pages_qs&PRINT_CONTRACT=$Company->{ID}" . (($conf{DOCS_PDF_PRINT}) ? '&pdf=1' : '')
        , { ex_params => ' target=new', class => 'btn input-group-button', ICON => 'fas fa-print' } );
    }

    my @menu_functions = (
      $lang{INFO}     ."::COMPANY_ID=$Company->{ID}",
      $lang{USERS}    .":11:COMPANY_ID=$Company->{ID}",
      $lang{PAYMENTS} .":2:COMPANY_ID=$Company->{ID}",
      $lang{FEES}     .":3:COMPANY_ID=$Company->{ID}",
      $lang{ADD_USER} .":24:COMPANY_ID=$Company->{ID}",
      $lang{BILL}     .":19:COMPANY_ID=$Company->{ID}"
    );

    if (in_array('Docs', \@MODULES)) {
      load_module('Docs', $html);
      push @menu_functions, "$lang{DOCS}:" . get_function_index( 'docs_acts' ) . ":COMPANY_ID=$Company->{ID}";
    }

    # TODO: #3944 rereview
    my $company_sel = '';
    $html->form_main({
      CONTENT       => $html->form_select(
        'COMPANY_ID',
        {
          SELECTED  => $FORM{COMPANY_ID},
          SEL_LIST  => $Company->list({ COLS_NAME => 1, PAGE_ROWS => 100000 }),
          SEL_KEY   => 'id',
          SEL_VALUE => 'name',
        },
      ),
      HIDDEN        => {
        index => $index,
      },
      SUBMIT        => { show => $lang{SHOW} },
      class         => 'form-inline ml-auto flex-nowrap',
      OUTPUT2RETURN => 1
    });


    my $add_args = ();

    if ($FORM{subf} && $FORM{subf} == 11) {
      require Control::Companies_users;
      my $res = company_users_total_info($FORM{COMPANY_ID});
      $add_args->{TOTAL} = $res->{TOTAL};
      $add_args->{SUM} = $res->{SUM};
      $add_args->{COMPANY_DEPOSIT} = $Company->{DEPOSIT};
    }

    func_menu(
      {
        $lang{NAME} => $company_sel
      },
      \@menu_functions,
      { f_args     => { COMPANY => $Company, ADD_ARGS => $add_args },
        MAIN_INDEX => get_function_index('form_companies'),
        SILENT     => $FORM{print}
      }
    );

    if (!$FORM{subf}) {
      if ($permissions{0}{38}) {
        $Company->{ACTION}     = 'change';
        $Company->{LNG_ACTION} = $lang{CHANGE};
      } else {
        $Company->{LNG_ACTION} = "$lang{LIST} $lang{COMPANIES}";
        $html->message( 'secondary', $lang{INFO}, $lang{NO_CHANGES} );
      }

      if ($Company->{DISABLE} > 0) {
        $Company->{DISABLE} = ' checked';
        $Company->{DISABLE_LABEL} = $lang{DISABLE};
      } else {
        $Company->{DISABLE} = '';
        $Company->{DISABLE_LABEL} = $lang{ACTIV};
      }

      $Company->{INFO_FIELDS} = form_info_field_tpl({ COMPANY => 1, VALUES  => $Company, COLS_LEFT => 'col-md-3', COLS_RIGHT => 'col-md-9' });
      $Company->{ADDRESS_FULL} = $Company->{ADDRESS};
      $Company->{ADDRESS_TPL} = form_address({ %FORM, %$Company, ADDRESS_HIDE => 1 });

      if (in_array('Docs', \@MODULES)) {
        if ($conf{DOCS_CONTRACT_TYPES}) {
          $conf{DOCS_CONTRACT_TYPES} =~ s/\n//g;
          my (@contract_types_list) = split(/;/, $conf{DOCS_CONTRACT_TYPES});

          my %CONTRACTS_LIST_HASH = ();
          $FORM{CONTRACT_SUFIX} = "|$Company->{CONTRACT_SUFIX}";
          foreach my $line (@contract_types_list) {
            my ($prefix, $sufix, $name) = split(/:/, $line);
            $prefix =~ s/ //g;
            $CONTRACTS_LIST_HASH{"$prefix|$sufix"} = $name;
          }

          $Company->{CONTRACT_TYPE} = $html->tpl_show(templates('form_row'), {
              ID    => 'CONTRACT_TYPE',
              NAME  => $lang{TYPE},
              VALUE => $html->form_select('CONTRACT_TYPE',
                {
                  SELECTED => $FORM{CONTRACT_SUFIX},
                  SEL_HASH => { '' => '--', %CONTRACTS_LIST_HASH },
                  NO_ID    => 1
                }),
              SIZE_MD => 12
            }, { OUTPUT2RETURN => 1 });
        }
      }

      my $company_deposit = $Company->{DEPOSIT} // $lang{NOT_EXIST};
      if ($company_deposit =~ /\d+/ && $company_deposit > 0) {
        $Company->{DEPOSIT_MARK} = 'badge badge-success';
      }
      elsif ($company_deposit =~ /\d+/ && $company_deposit < 0) {
        $Company->{DEPOSIT_MARK} = 'badge badge-danger';
      }
      else {
        $Company->{DEPOSIT_MARK} = 'badge badge-warning';
      }

      if ($company_deposit =~ /\d+/) {
        if ($conf{DEPOSIT_FORMAT}) {
          $Company->{SHOW_DEPOSIT} = sprintf($conf{DEPOSIT_FORMAT}, $company_deposit);
        }
        else {
          $Company->{SHOW_DEPOSIT} = sprintf("%.2f", $company_deposit);
        }

      } else {
        $Company->{SHOW_DEPOSIT} = $company_deposit;
      }

      $Company->{FORM_DISABLE} = "<input class='custom-control-input' type='checkbox' name='DISABLE' id='DISABLE' value='1' data-checked='%DISABLE%' style='display: none;'>
  <label class='custom-control-label' for='DISABLE' id='DISABLE_LABEL'>%DISABLE_LABEL%</label>";

      my $company_id = $Company->{ID};
      if ($permissions{1}) {
        $Company->{PAYMENTS_BUTTON} = $html->button('', "index=$company_index&COMPANY_ID=$company_id&subf=2",
          { class     => 'btn btn-sm btn-secondary',
            ICON      => 'fa fa-plus',
            ex_params => "data-tooltip='$lang{PAYMENTS}' data-tooltip-position='top'"
          });
      }

      if ($permissions{2}) {
        $Company->{FEES_BUTTON} = $html->button('', "index=$company_index&COMPANY_ID=$company_id&subf=3",
          { class     => 'btn btn-sm btn-secondary',
            ICON      => 'fa fa-minus',
            ex_params => "data-tooltip='$lang{FEES}' data-tooltip-position='top'" });
      }
      $Company->{EXDATA} .= $html->tpl_show(templates('form_company_exdata'), $Company, { OUTPUT2RETURN => 1});

      if ($conf{EXT_BILL_ACCOUNT} && $Company->{EXT_BILL_ID}) {
        $Company->{EXDATA} .= $html->tpl_show(templates('form_ext_bill'), $Company, { OUTPUT2RETURN => 1 });
      }

      $Company->{DOCS_TEMPLATE} = $html->tpl_show(_include('docs_form_pi_lite', 'Docs'), { %{$Company} }, { OUTPUT2RETURN => 1 });

      my $company_main = $html->tpl_show(templates('form_company'), $Company, { OUTPUT2RETURN => 1 });
      my $company_pi = $html->tpl_show(templates('form_company_pi'), $Company, { OUTPUT2RETURN => 1 });
      my $company_profile = $html->tpl_show(
        templates('form_company_profile'),
        {
          LEFT_PANEL  => $company_main,
          RIGHT_PANEL => $company_pi,
          ACTION      => $Company->{ACTION},
          LNG_ACTION  => $Company->{LNG_ACTION},
        },
        {
          OUTPUT2RETURN => 1
        }
      );
      print $company_profile;
    }
  }
  else {
    if ($FORM{letter}) {
      $LIST_PARAMS{COMPANY_NAME} = "$FORM{letter}*";
      $pages_qs .= "&letter=$FORM{letter}";
    }

    $LIST_PARAMS{SKIP_GID} = 1;

    my $add_form_button = ($permissions{0}{37}) ? ("$lang{ADD}:index=$company_index&add_form=1".':add') : '';

    result_former({
      INPUT_DATA      => $Company,
      FUNCTION        => 'list',
      DEFAULT_FIELDS  => 'NAME,DEPOSIT,CREDIT,USERS_COUNT,DISABLE',
      BASE_FIELDS     => 1,
      FUNCTION_INDEX  => $company_index,
      FUNCTION_FIELDS => defined( $permissions{0}{39} ) ? 'company_id,del' : 'company_id',
      EXT_TITLES      => {
        'name'          => $lang{NAME},
        'users_count'   => $lang{USERS},
        'status'        => $lang{STATUS},
        'tax_number'    => $lang{TAX_NUMBER},
        'deposit'       => $lang{DEPOSIT},
        'credit'        => $lang{CREDIT},
        'contract_id'   => $lang{CONTRACT},
        'contract_date' => "$lang{CONTRACT} $lang{DATE}",
        'registration'  => $lang{REGISTRATION},
        'district_name' => $lang{DISTRICTS},
        'address_full'  => "$lang{FULL} $lang{ADDRESS}",
        'address_street'=> $lang{ADDRESS_STREET},
        'address_build' => $lang{ADDRESS_BUILD},
        'address_flat'  => $lang{ADDRESS_FLAT},
        'address_street2'=> $lang{SECOND_NAME},
        'city'          => $lang{CITY},
        'zip'           => $lang{ZIP},
        'phone'         => $lang{PHONE},
        'edrpou'        => $lang{EDRPOU}
      },
      SKIP_USER_TITLE => 1,
      FILTER_COLS   => {
        users_count => ($FORM{json}) ? '' : "_company_user_link::FUNCTION=form_users,ID",
      },
      TABLE           => {
        width   => '100%',
        caption => $lang{COMPANIES},
        qs      => $pages_qs,
        ID      => 'COMPANY_ID',
        EXPORT  => 1,
        IMPORT  => "$SELF_URL?get_index=form_companies&import=1&header=2",
        MENU    => $add_form_button. ";$lang{SEARCH}:index=".get_function_index( 'form_search' )."&type=13:search",
        SHOW_COLS_HIDDEN => {
          TYPE_PAGE => $FORM{type}
        }
      },
      MAKE_ROWS       => 1,
      TOTAL           => 1
    });

  }

  _error_show($Company);

  return 1;
}


#**********************************************************
=head2 _company_user_link()

=cut
#**********************************************************
sub _company_user_link{
  my ($params, $attr) = @_;

  return $html->button($params, "index=11&COMPANY_ID=$attr->{VALUES}->{ID}" );
}

# #**********************************************************
# =head2 _company_users_count()
#
# =cut
# #**********************************************************
# sub _company_users_count{
#   return "";
# }

#**********************************************************
=head2 form_companie_admins($attr)

=cut
#**********************************************************
sub form_companie_admins {
  my ($attr) = @_;

  require Customers;
  Customers->import();
  my $Customer = Customers->new($db, $admin, \%conf);
  my $Company = $Customer->company();

  $Company->info($FORM{COMPANY_ID} || $FORM{ID});
  $Company->{COMPANY_NAME}   = $Company->{NAME};

  if ($FORM{change}) {
    #ADD_ADMIN:
    $Company->admins_change({%FORM});
    if (!$Company->{errno}) {
      $html->message( 'info', $lang{INFO}, $lang{CHANGED} );
    }
    if ($attr->{REGISTRATION}) {
      return 0;
    }
  }

  _error_show($Company);

  my $name_caption = "$lang{ADMINS}  "  .  "$lang{COMPANY} - " . ($Company->{COMPANY_NAME} || '');

  my $table = $html->table(
    {
      width      => '100%',
      caption    => $name_caption,
      title      => [ $lang{ALLOW}, $lang{LOGIN}, $lang{FIO}, 'E-mail' ],
      qs         => $pages_qs,
      ID         => 'COMPANY_ADMINS'
    }
  );

  if (!defined($FORM{sort})) {
    $LIST_PARAMS{SORT} = 2;
  }

  my $list = $Company->admins_list({
    COMPANY_ID => $FORM{COMPANY_ID},
    PAGE_ROWS  => 10000
  });

  if ($attr->{REGISTRATION}) {
    if ($FORM{add} && $Company->{TOTAL} == 1 && !$list->[0]->[0]) {
      $FORM{IDS} = $FORM{UID};
    }
    return 0;
  }

  foreach my $line (@$list) {
    $table->addrow(
      $html->form_input(
        'IDS',
        $line->[4],
        {
          TYPE          => 'checkbox',
          OUTPUT2RETURN => 1,
          STATE         => ($line->[0]) ? 1 : undef
        }
      ),
      user_ext_menu($line->[4], $line->[1]),
      $line->[2],
      $line->[3]
    );
  }

  print $html->form_main(
      {
        CONTENT => $table->show({ OUTPUT2RETURN => 1 }),
        HIDDEN  => {
          index      => $index,
          COMPANY_ID => $FORM{COMPANY_ID}
        },
        SUBMIT  => { change => "$lang{CHANGE}" }
      }
    );

  return 1;
}

#**********************************************************
=head2 _form_company_address($attr) get address form for companys

=cut
#**********************************************************
sub _form_company_address {
  my ($attr) = @_;

  require Address;

  my %info = ();
  Address->import();
  my $Address = Address->new($db, $admin, \%conf);

  if($attr->{LOCATION_ID}){
    $Address->address_info($attr->{LOCATION_ID});
  }
  elsif($attr->{ADDRESS}){
    my $address_input    = $html->form_input('ADDRESS', $attr->{ADDRESS});
    $info{ADDRESS_FORM} .= $html->element('label', $lang{ADDRESS}, { for => 'ADDRESS', class => 'control-label col-md-3'});
    $info{ADDRESS_FORM} .= $html->element('div',  $address_input, { class => 'col-md-9'});
    $info{ADDRESS_FORM}  = $html->element('div', $info{ADDRESS_FORM}, {class => 'form-group'});
  }

  $info{ADDRESS_FORM} .= $html->tpl_show(templates('form_address_sel'),
    {%$Address, %$attr},
    {
      OUTPUT2RETURN => 1,
      ID            => 'form_address_sel'
    }
  );

  return $info{ADDRESS_FORM};
}

#**********************************************************
=head2 companies_import($attr)

=cut
#**********************************************************
sub companies_import {

  require Customers;
  Customers->import();
  my $Customer = Customers->new($db, $admin, \%conf);
  my $Company  = $Customer->company();

  if (defined($FORM{UPLOAD_FILE})) {
    my $import_info = import_former( \%FORM );
    my $imported      = 0;
    my $imported_name = '';

    foreach my $_company (@$import_info) {
      next if ($_company->{NAME} eq '');

      $imported_name .= "$_company->{NAME}\n";
      $_company->{NAME} =~ s/'/\\'/g;
      $_company->{CREATE_BILL} = 1;

      $Company->add({ %$_company });

      if ($Company->{errno}) {
        _error_show($Company, { MESSAGE =>  "Line:$imported_name\n F$lang{COMPANY}: '$_company->{NAME}'" });
        return 0;
      }
      $imported++;
    }

    if($imported != 0){
      my $message = "$lang{FILE}:  $FORM{UPLOAD_FILE}{filename}\n" . "$lang{TOTAL}:  $imported\n" . "$lang{SIZE}: $FORM{UPLOAD_FILE}{Size} b\n\n" . "$imported_name\n";
      $html->message( 'info', $lang{INFO}, "$message" );
      return 1;
    }

  }

  my $import_fields = $html->form_select('IMPORT_FIELDS',
    {
      SELECTED  => $FORM{IMPORT_FIELDS},
      SEL_ARRAY => [
        'NAME',
        'ADDRESS',
        'PHONE',
        'REPRESENTATIVE',
        'VAT',
        'REGISTRATION',
        'TAX_NUMBER',
        'BANK_ACCOUNT',
        'BANK_NAME',
        'CONTRACT_ID',
        'CONTRACT_DATE',
        'EDRPOU',
      ],
      EX_PARAMS => 'multiple="multiple"'
    });

  my $encode = $html->form_select(
    'ENCODE',
    {
      SELECTED  => $FORM{ENCODE},
      SEL_ARRAY => [ '', 'win2utf8', 'utf82win', 'win2koi', 'koi2win', 'win2iso', 'iso2win', 'win2dos', 'dos2win' ],
    }
  );

  my $extra_row = $html->tpl_show(templates('form_row'), {
    ID    => 'ENCODE',
    NAME  => $lang{ENCODE},
    VALUE => $encode },
    { OUTPUT2RETURN => 1 });

  $html->tpl_show(templates('form_import'), {
    IMPORT_FIELDS     => $conf{COMPANY_IMPORT_FIELDS} || 'NAME,ADDRESS,PHONE,REPRESENTATIVE,VAT,REGISTRATION,TAX_NUMBER,BANK_ACCOUNT,BANK_NAME,CONTRACT_ID,CONTRACT_DATE,EDRPOU',
    CALLBACK_FUNC     => 'form_companies',
    IMPORT_FIELDS_SEL => $import_fields,
    EXTRA_ROWS        => $extra_row,
  });

  return 1;
}

1;