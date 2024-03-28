#package Storage::Configure;
use strict;
use warnings FATAL => 'all';

our (
  $db,
  %conf,
  $admin,
  $html,
  %lang,
  %permissions
);

use Storage;
use AXbills::Base qw/_bp in_array/;

my $Storage = Storage->new($db, $admin, \%conf);

$Storage->storage_measure_list({ NAME => '_SHOW', LIST2HASH => 'id,name' });

our %measures_name = %{_storage_translate_measure(\%{$Storage->{list_hash}})};

#***********************************************************
=head2 storage_articles() - Storage articles

=cut
#***********************************************************
sub storage_articles {

  $html->message('info', $lang{INFO}, $FORM{message}) if $FORM{message};

  $Storage->{ACTION} = 'add';
  $Storage->{ACTION_LNG} = $lang{ADD};
  $Storage->{ADD_DATE} = '0000-00-00';

  if ($FORM{add}) {
    if ($FORM{NAME} && $FORM{ARTICLE_TYPE} && defined($FORM{MEASURE})) {
      $Storage->storage_articles_add({ %FORM });
      if (!$Storage->{errno}) {
        $html->tpl_show(_include('storage_redirect', 'Storage'), {
          SECTION => '',
          MESSAGE => $lang{ADDED},
        });
      }
    }
    else {
      $html->message('warn', $lang{INFO}, $lang{FIELDS_FOR_NAME_ARTICLETYPE_MEASURE_ARE_REQUIRED});
    }
  }
  elsif ($FORM{del}) {
    my $list = $Storage->storage_incoming_articles_list({ ARTICLE_ID => $FORM{del}, COLS_NAME => 1 });
    if ($Storage->{TOTAL} > 0) {
      $html->message('warning', $lang{INFO}, $lang{CANT_DELETE_ERROR1});
    }
    else {
      $Storage->storage_articles_del({ ID => $FORM{del} });
      $html->message('info', $lang{INFO}, $lang{DELETED}) if !$Storage->{errno};
    }
  }
  elsif ($FORM{change}) {
    if ($FORM{NAME} && $FORM{ARTICLE_TYPE} && defined($FORM{MEASURE})) {
      $Storage->storage_articles_change({ %FORM });
      $html->message('info', $lang{INFO}, $lang{CHANGED}) if !$Storage->{errno};
    }
    else {
      $html->message('warn', $lang{INFO}, $lang{FIELDS_FOR_NAME_ARTICLETYPE_MEASURE_ARE_REQUIRED});
    }
  }
  elsif ($FORM{chg}) {
    $Storage->{ACTION} = 'change';
    $Storage->{ACTION_LNG} = $lang{CHANGE};

    $Storage->storage_articles_info({ ID => $FORM{chg}, });
    $html->message('info', $lang{INFO}, $lang{CHANGING}) if !$Storage->{errno};
  }

  $Storage->{ARTICLE_TYPES} = $html->form_select('ARTICLE_TYPE', {
    SELECTED    => $Storage->{ARTICLE_TYPE} || 0,
    SEL_LIST    => $Storage->storage_types_list({ COLS_NAME => 1, DOMAIN_ID => ($admin->{DOMAIN_ID} || undef) }),
    NO_ID       => 1,
    SEL_OPTIONS => { '' => '--' },
    REQUIRED    => 1,
  });

  $Storage->{MEASURE_SEL} = $html->form_select('MEASURE', {
    SELECTED      => $Storage->{MEASURE} || $FORM{MEASURE} || 0,
    SEL_HASH      => _storage_translate_measure(\%measures_name),
    NO_ID         => 1,
    OUTPUT2RETURN => 1,
    REQUIRED      => 1,
  });

  if (in_array('Equipment', \@MODULES) && (!$admin->{MODULES} || $admin->{MODULES}{'Equipment'})) {
    use Equipment;
    my $Equipment = Equipment->new($db, $admin, \%conf);

    $Storage->{EQUIPMENT_MODEL_SEL} = $html->form_select('EQUIPMENT_MODEL_ID', {
      SELECTED    => $Storage->{EQUIPMENT_MODEL_ID} || 0,
      SEL_LIST    => $Equipment->model_list({ COLS_NAME => 1, PAGE_ROWS => 500 }),
      SEL_VALUE   => 'vendor_name,model_name',
      NO_ID       => 1,
      SEL_OPTIONS => { '' => '--' }
    });
    $Storage->{BASE_FIELDS} = 7;
  }

  $html->tpl_show(_include('storage_articles', 'Storage'), { %$Storage, ADD_DATE => $DATE });
  $LIST_PARAMS{DOMAIN_ID} = $admin->{DOMAIN_ID} || undef;

  result_former({
    INPUT_DATA      => $Storage,
    FUNCTION        => 'storage_articles_list',
    BASE_FIELDS     => $Storage->{BASE_FIELDS} || 6,
    FUNCTION_FIELDS => 'change,del',
    HIDDEN_FIELDS   => 'ARTICLE_TYPE,IMAGE_URL',
    SKIP_USER_TITLE => 1,
    SELECT_VALUE    => { measure => \%measures_name },
    EXT_TITLES      => {
      id         => '#',
      name       => $lang{NAME},
      type_name  => $lang{TYPE},
      measure    => $lang{MEASURE},
      model_name => $lang{MODEL},
      add_date   => $lang{DATE},
      comments   => $lang{COMMENTS},
    },
    TABLE           => {
      width   => '100%',
      caption => $lang{ARTICLES},
      qs      => $pages_qs,
      ID      => 'ARTICLES_LIST',
      EXPORT  => 1,
      MENU    => "$lang{ADD}:index=$index&add_form=1&$pages_qs:add",
    },
    MAKE_ROWS       => 1,
    SEARCH_FORMER   => 1,
    TOTAL           => 1
  });

  return 1;
}


#**********************************************************
=head2 storage_measures()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub storage_measure {

  my %STORAGE_MEASURE_TEMPLATE = (BTN_NAME => 'add', BTN_VALUE => $lang{ADD});

  if ($FORM{add}) {
    $Storage->storage_measure_add({ %FORM });
    _error_show($Storage);
  }
  elsif ($FORM{change}) {
    $Storage->storage_measure_change({ %FORM });
    _error_show($Storage);
  }
  elsif ($FORM{del}) {
    $Storage->storage_articles_list({ MEASURE => $FORM{del}, COLS_NAME => 1 });
    if ($Storage->{TOTAL} > 0) {
      $html->message('warn', $lang{ERROR}, $lang{CANT_DELETE_ERROR5});
    }
    else {
      $Storage->storage_measure_delete({ ID => $FORM{del} });
      _error_show($Storage);
    }
  }

  if ($FORM{chg}) {
    $STORAGE_MEASURE_TEMPLATE{BTN_NAME} = 'change';
    $STORAGE_MEASURE_TEMPLATE{BTN_VALUE} = $lang{CHANGE};

    my $action_info = $Storage->storage_measure_info({
      ID         => $FORM{chg},
      NAME       => '_SHOW',
      COMMENTS   => '_SHOW',
      COLS_NAME  => 1,
      COLS_UPPER => 1
    });
    _error_show($Storage);

    if ($action_info) {
      @STORAGE_MEASURE_TEMPLATE{keys %$action_info} = values %$action_info;
    }
  }

  $html->tpl_show(_include('storage_measure', 'Storage'), { %STORAGE_MEASURE_TEMPLATE });

  result_former({
    INPUT_DATA      => $Storage,
    FUNCTION        => 'storage_measure_list',
    BASE_FIELDS     => 0,
    DEFAULT_FIELDS  => 'ID, NAME, COMMENTS',
    FUNCTION_FIELDS => 'change,del',
    FILTER_COLS     => { name => "_storage_translate_measure::NAME," },
    SKIP_USER_TITLE => 1,
    EXT_TITLES      => {
      'id'       => 'ID',
      'name'     => $lang{NAME},
      'comments' => $lang{COMMENTS},
    },
    TABLE           => {
      width   => '100%',
      caption => $lang{MEASURE},
      qs      => $pages_qs,
      ID      => 'STORAGE_MEASURE',
    },
    MAKE_ROWS       => 1,
    SEARCH_FORMER   => 1,
    MODULE          => 'Storage',
    TOTAL           => "TOTAL:$lang{TOTAL}",
  });
}

#**********************************************************
=head2 storage_translate_measure()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub _storage_translate_measure {
  my ($attr) = @_;

  if ($attr && ref $attr eq "HASH") {
    foreach my $key (keys %$attr) {
      $attr->{$key} = _translate($attr->{$key});
    }
  }
  else {
    $attr = _translate($attr);
  }

  return $attr;
}

#***********************************************************
=head2 storage_articles_types() - Storage articles types

=cut
#***********************************************************
sub storage_articles_types {

  $html->message('info', $lang{INFO}, $FORM{message}) if $FORM{message};

  $Storage->{ACTION} = 'add';
  $Storage->{ACTION_LNG} = $lang{ADD};

  if ($FORM{add}) {
    if ($FORM{NAME}) {
      $Storage->storage_types_add({ %FORM });
      $html->tpl_show(_include('storage_redirect', 'Storage'), {
        SECTION => '',
        MESSAGE => $lang{ADDED}
      }) if !$Storage->{errno};
    }
    else {
      $html->message('info', $lang{INFO}, $lang{FIELDS_FOR_TYPE_ARE_REQUIRED});
      $html->tpl_show(_include('storage_articles_types', 'Storage'), { %{$Storage}, %FORM });
    }
  }
  elsif ($FORM{del} && $FORM{COMMENTS}) {
    my $list_in_use = $Storage->storage_articles_list({ ARTICLE_TYPE => $FORM{del} });
    if ($Storage->{TOTAL} > 0) {
      $html->message('warn', $lang{ERROR}, $lang{CANT_DELETE_ERROR2});
    }
    else {
      $Storage->storage_types_del({ ID => $FORM{del} });

      $html->message('info', $lang{INFO}, $lang{DELETED}) if !$Storage->{errno};
    }
  }
  elsif ($FORM{change}) {
    if ($FORM{NAME}) {
      $Storage->storage_types_change({ %FORM });
      $html->tpl_show(_include('storage_redirect', 'Storage'), {
        SECTION => '',
        MESSAGE => $lang{CHANGED}
      }) if !$Storage->{errno};
    }
    else {
      $Storage->{ACTION} = 'change';
      $Storage->{ACTION_LNG} = $lang{CHANGE};
      $html->message('info', $lang{INFO}, $lang{FIELDS_FOR_TYPE_ARE_REQUIRED});
    }
  }
  elsif ($FORM{chg}) {
    $Storage->{ACTION} = 'change';
    $Storage->{ACTION_LNG} = $lang{CHANGE};
    $Storage->storage_articles_types_info({ ID => $FORM{chg} });
  }

  _error_show($Storage);

  $html->tpl_show(_include('storage_articles_types', 'Storage'), { %{$Storage}, %FORM });

  $LIST_PARAMS{DOMAIN_ID} = $admin->{DOMAIN_ID} || undef;

  result_former({
    INPUT_DATA      => $Storage,
    FUNCTION        => 'storage_types_list',
    BASE_FIELDS     => 3,
    DEFAULT_FIELDS  => 'ID,NAME,COMMENTS',
    FUNCTION_FIELDS => 'change' . ((defined($permissions{4}->{3})) ? ',del' : ''),
    SKIP_USER_TITLE => 1,
    EXT_TITLES      => {
      id       => 'ID',
      name     => $lang{NAME},
      comments => $lang{COMMENTS}
    },
    TABLE           => {
      width   => '100%',
      caption => $lang{TYPE},
      qs      => $pages_qs,
      ID      => 'STORAGE_TYPES',
      EXPORT  => 1
    },
    MAKE_ROWS       => 1,
    TOTAL           => 1
  });

  return 1;
}

#***********************************************************
=head2 suppliers_main() - Suppliers

=cut
#***********************************************************
sub suppliers_main {

  $html->message('info', $lang{INFO}, $FORM{message}) if $FORM{message};

  $Storage->{ACTION} = 'add';
  $Storage->{ACTION_LNG} = $lang{ADD};
  $Storage->{DATE} = '0000-00-00';

  $Storage->{OKPO_PATTERN} = $conf{STORAGE_OKPO_PATTERN} || '\d{8,10}';
  $Storage->{INN_PATTERN} = $conf{STORAGE_INN_PATTERN} || '\d{12,12}';
  $Storage->{MFO_PATTERN} = $conf{STORAGE_MFO_PATTERN} || '\d{6,6}';

  if ($FORM{del}) {
    my $list = $Storage->storage_incoming_articles_list({ SUPPLIER_ID => $FORM{del}, COLS_NAME => 1 });
    _error_show($Storage);

    if (defined($list->[0]->{id})) {
      $html->message('warn', $lang{INFO}, $lang{CANT_DELETE_ERROR3});
    }
    else {
      $Storage->suppliers_del({ ID => $FORM{del} });
      $html->message('info', $lang{INFO}, $lang{DELETED}) if !$Storage->{errno};
    }
  }
  elsif ($FORM{change}) {
    if ($FORM{NAME}) {
      $Storage->suppliers_change({ %FORM });
      $html->tpl_show(_include('storage_redirect', 'Storage'), {
        SECTION => '',
        MESSAGE => $lang{CHANGED}
      }) if !$Storage->{errno};
    }
    else {
      $Storage->{ACTION} = 'change';
      $Storage->{ACTION_LNG} = $lang{CHANGE};
      $html->message('info', $lang{INFO}, $lang{FIELDS_FOR_NAME_ARE_REQUIRED});
      $Storage->{ADDRESS_FORM} = form_address_select2({
        HIDE_FLAT             => 1,
        HIDE_ADD_BUILD_BUTTON => 1,
        LOCATION_ID           => 0,
        DISTRICT_ID           => 0,
        STREET_ID             => 0
      });
      $html->tpl_show(_include('storage_suppliers_form', 'Storage'), { %{$Storage}, %FORM });
    }
  }
  elsif ($FORM{add}) {
    if ($FORM{NAME}) {
      $Storage->suppliers_add({ %FORM });
      $html->tpl_show(_include('storage_redirect', 'Storage'), {
        SECTION => '',
        MESSAGE => $lang{ADDED}
      }) if !$Storage->{errno};
    }
    else {
      $html->message('info', $lang{INFO}, $lang{FIELDS_FOR_NAME_ARE_REQUIRED});
      $Storage->{ADDRESS_FORM} = form_address_select2({
        HIDE_FLAT             => 1,
        HIDE_ADD_BUILD_BUTTON => 1,
        LOCATION_ID           => 0,
        DISTRICT_ID           => 0,
        STREET_ID             => 0
      });
      $html->tpl_show(_include('storage_suppliers_form', 'Storage'), { %{$Storage}, %FORM });
    }
  }
  elsif ($FORM{chg}) {
    $Storage->{ACTION} = 'change';
    $Storage->{ACTION_LNG} = $lang{CHANGE};
    $Storage->suppliers_info({ ID => $FORM{chg} });
    $html->message('info', $lang{INFO}, $lang{CHANGING}) if !$Storage->{errno};
  }
  if (!$FORM{add} and !$FORM{change}) {
    $Storage->{ADDRESS_FORM} = form_address_select2({
      LOCATION_ID           => $Storage->{LOCATION_ID} || 0,
      DISTRICT_ID           => $Storage->{DISTRICT_ID} || 0,
      STREET_ID             => $Storage->{STREET_ID} || 0,
      HIDE_FLAT             => 1,
      HIDE_ADD_BUILD_BUTTON => 1
    });
    $html->tpl_show(_include('storage_suppliers_form', 'Storage'), $Storage);
  }

  $LIST_PARAMS{DOMAIN_ID} = $admin->{DOMAIN_ID} || undef;

  result_former({
    INPUT_DATA      => $Storage,
    FUNCTION        => 'suppliers_list_new',
    BASE_FIELDS     => 0,
    DEFAULT_FIELDS  => 'ID,NAME,PHONE,EMAIL,DIRECTOR,ACCOUNT,COMMENT',
    FUNCTION_FIELDS => 'change,del',
    SKIP_USER_TITLE => 1,
    EXT_TITLES      => {
      id         => '#',
      name       => $lang{NAME},
      date       => $lang{DATE},
      okpo       => $lang{OKPO},
      inn        => $lang{INN},
      inn_svid   => $lang{CERTIFICATE_OF_INDIVIDUAL_TAX_NUMBER},
      account    => $lang{ACCOUNT},
      mfo        => $lang{MFO},
      phone      => "$lang{PHONE} 1",
      phone2     => "$lang{PHONE} 2",
      fax        => $lang{FAX},
      url        => $lang{SITE},
      email      => 'E-mail',
      telegram   => 'Telegram',
      accountant => $lang{POSITION_MANAGER},
      director   => $lang{DIRECTOR},
      managment  => $lang{ACCOUNTANT},
      domain_id  => 'Domain',
      comment    => $lang{COMMENTS},
    },
    TABLE           => {
      width   => '100%',
      caption => $lang{SUPPLIERS},
      qs      => $pages_qs,
      ID      => 'SUPPLIERS_LIST',
      EXPORT  => 1
    },
    MAKE_ROWS       => 1,
    SEARCH_FORMER   => 1,
    TOTAL           => 1
  });

  return 1;
}

#**********************************************************
=head2 storage_storages($attr) - Shows result former for list of storages

=cut
#**********************************************************
sub storage_storages {

  $html->message('info', $lang{INFO}, $FORM{message}) if $FORM{message};

  $Storage->{ACTION} = 'add';
  $Storage->{ACTION_LNG} = $lang{ADD};
  $Storage->{ADD_DATE} = '0000-00-00';

  if ($FORM{add}) {
    if ($FORM{NAME} && $FORM{NAME} ne '') {
      $Storage->storage_add({ %FORM });
      $html->tpl_show(_include('storage_redirect', 'Storage'), {
        SECTION => '',
        MESSAGE => $lang{ADDED},
      }) if !$Storage->{errno};
    }
    else {
      $html->message('info', $lang{INFO}, $lang{ERR_WRONG_DATA});
      $html->tpl_show(_include('storage_storages', 'Storage'), { %{$Storage}, %FORM });
    }
  }
  elsif ($FORM{del} && $FORM{COMMENTS}) {
    $Storage->storage_incoming_articles_list({ STORAGE_ID => $FORM{del}, COLS_NAME => 1 });
    if ($Storage->{TOTAL}) {
      $html->message('warn', $lang{INFO}, $lang{CANT_DELETE_ERROR1});
    }
    else {
      $Storage->storage_del({ ID => $FORM{del} });
      $html->message('info', $lang{INFO}, $lang{DELETED}) if !$Storage->{errno};
    }
  }
  elsif ($FORM{change}) {
    $Storage->storage_change({ %FORM });
    $html->tpl_show(_include('storage_redirect', 'Storage'), {
      SECTION => '',
      MESSAGE => $lang{CHANGED},
    }) if !$Storage->{errno};
  }
  elsif ($FORM{chg}) {
    $Storage->{ACTION} = 'change';
    $Storage->{ACTION_LNG} = $lang{CHANGE};
    $Storage->storage_info({ ID => $FORM{chg} });
    $html->message('info', $lang{INFO}, $lang{CHANGING}) if !$Storage->{errno};
  }

  if (!$FORM{add} and !$FORM{change}) {
    $html->tpl_show(_include('storage_storages', 'Storage'), $Storage);
  }

  $LIST_PARAMS{DOMAIN_ID} = $admin->{DOMAIN_ID} || undef;
  result_former({
    INPUT_DATA      => $Storage,
    FUNCTION        => 'storages_list',
    BASE_FIELDS     => 3,
    FUNCTION_FIELDS => 'change,del',
    SKIP_USER_TITLE => 1,
    EXT_TITLES      => {
      id       => '#',
      name     => $lang{NAME},
      comments => $lang{COMMENTS}
    },
    TABLE           => {
      width   => '100%',
      caption => $lang{STORAGE},
      qs      => $pages_qs,
      ID      => 'STORAGES_LIST',
      EXPORT  => 1
    },
    MAKE_ROWS       => 1,
    SEARCH_FORMER   => 1,
    TOTAL           => 1
  });

  return 1;
}

#**********************************************************
=head2 storage_measures()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub storage_properties {

  my %STORAGE_PROPERTY_TEMPLATE = (BTN_NAME => 'add', BTN_VALUE => $lang{ADD});

  if ($FORM{add}) {
    $Storage->storage_property_add({ %FORM });
    _error_show($Storage);
  }
  elsif ($FORM{change}) {
    $Storage->storage_property_change({ %FORM });
    _error_show($Storage);
  }
  elsif ($FORM{del}) {
    $Storage->storage_property_value_list({ PROPERTY_ID => $FORM{del} });

    if ($Storage->{TOTAL} > 0) {
      $html->message('warning', $lang{INFO}, $lang{CANT_DELETE_ERROR6});
    }
    else {
      $Storage->storage_property_delete({ ID => $FORM{del} });
      _error_show($Storage);
    }
  }

  if ($FORM{chg}) {
    $STORAGE_PROPERTY_TEMPLATE{BTN_NAME} = 'change';
    $STORAGE_PROPERTY_TEMPLATE{BTN_VALUE} = $lang{CHANGE};

    my $property_info = $Storage->storage_property_info({
      ID         => $FORM{chg},
      NAME       => '_SHOW',
      COMMENTS   => '_SHOW',
      COLS_NAME  => 1,
      COLS_UPPER => 1,
    });
    _error_show($Storage);

    if ($property_info) {
      @STORAGE_PROPERTY_TEMPLATE{keys %$property_info} = values %$property_info;
    }
  }

  $html->tpl_show(_include('storage_property', 'Storage'), { %STORAGE_PROPERTY_TEMPLATE });

  $LIST_PARAMS{DOMAIN_ID} = $admin->{DOMAIN_ID} || undef;
  result_former({
    INPUT_DATA      => $Storage,
    FUNCTION        => 'storage_property_list',
    BASE_FIELDS     => 0,
    DEFAULT_FIELDS  => 'ID, NAME, COMMENTS',
    FUNCTION_FIELDS => 'change,del',
    SKIP_USER_TITLE => 1,
    EXT_TITLES      => {
      id       => 'ID',
      name     => $lang{NAME},
      comments => $lang{COMMENTS},
    },
    TABLE           => {
      width   => '100%',
      caption => $lang{PROPERTY},
      qs      => $pages_qs,
      ID      => 'STORAGE_PROPERTY',
    },
    MAKE_ROWS       => 1,
    SEARCH_FORMER   => 1,
    MODULE          => 'Storage',
    TOTAL           => "TOTAL:$lang{TOTAL}",
  });
}

#**********************************************************
=head2 _property_list_html()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub _property_list_html {
  my ($incoming_articles_id) = @_;

  my $properties_list = $Storage->storage_property_list({
    DOMAIN_ID     => $admin->{DOMAIN_ID} || undef,
    NAME          => '_SHOW',
    COMMENTS      => '_SHOW',
    DESC          => 'desc',
    SHOW_ALL_COLS => 1,
    COLS_NAME     => 1,
    COLS_UPPER    => 1,
  });

  my $properties_values = $Storage->storage_property_value_list({
    STORAGE_INCOMING_ARTICLES_ID => $incoming_articles_id || 0,
    VALUE                        => '_SHOW',
    PROPERTY_ID                  => '_SHOW',
    DESC                         => 'desc',
    COLS_NAME                    => 1,
    COLS_UPPER                   => 1,
  });

  my %PROPERTIES_VALUES = ();
  foreach my $property_value (@$properties_values) {
    $PROPERTIES_VALUES{$property_value->{property_id}} = $property_value->{value};
  }

  my $properties_html = '';
  foreach my $property (@$properties_list) {
    $properties_html .= "<div class='form-group row'>";
    $properties_html .= "<label class='col-md-4 col-form-label text-md-right'>";
    $properties_html .= $property->{name};
    $properties_html .= ":</label>";
    $properties_html .= "<div class='col-md-8'>";
    $properties_html .= "<input type='text' name='PROPERTY_$property->{id}' class='form-control' value='" . ($PROPERTIES_VALUES{$property->{id}} || '') . "'>";
    $properties_html .= "</div>";
    $properties_html .= "</div>";
  }

  return $properties_html;
}

#**********************************************************
=head2 storage_admins()

=cut
#**********************************************************
sub storage_admins {

  my %STORAGE_ADMINS_TEMPLATE = (BTN_NAME => 'add', BTN_VALUE => $lang{ADD});

  if ($FORM{add}) {
    $Storage->storage_admin_add({ %FORM });
    $html->message('success', $lang{SUCCESS}, $lang{ADDED}) if !_error_show($Storage);
  }
  elsif ($FORM{change}) {
    $Storage->storage_admin_change({ %FORM });
    $html->message('success', $lang{SUCCESS}, $lang{CHANGED}) if !_error_show($Storage);
  }
  elsif ($FORM{del}) {
    $Storage->storage_admin_delete({ ID => $FORM{del} });
    $html->message('success', $lang{SUCCESS}, $lang{DELETED}) if !_error_show($Storage);
  }

  if ($FORM{chg}) {
    $STORAGE_ADMINS_TEMPLATE{BTN_NAME} = "change";
    $STORAGE_ADMINS_TEMPLATE{BTN_VALUE} = $lang{CHANGE};

    my $admin_settings_info = $Storage->storage_admin_info({
      ID         => $FORM{chg},
      AID        => '_SHOW',
      PERCENT    => '_SHOW',
      COMMENTS   => '_SHOW',
      NAME       => '_SHOW',
      COLS_NAME  => 1,
      COLS_UPPER => 1,
    });
    $html->message('success', $lang{SUCCESS}, $lang{CHANGE_DATA}) if !_error_show($Storage);

    if ($admin_settings_info) {
      @STORAGE_ADMINS_TEMPLATE{keys %$admin_settings_info} = values %$admin_settings_info;
    }
  }

  $STORAGE_ADMINS_TEMPLATE{ADMINS_SELECT} = sel_admins({
    SELECTED => $STORAGE_ADMINS_TEMPLATE{AID} || '',
    DISABLE  => '0'
  });

  $html->tpl_show(_include('storage_admins', 'Storage'), { %STORAGE_ADMINS_TEMPLATE });

  $LIST_PARAMS{DOMAIN_ID} = $admin->{DOMAIN_ID} || undef;
  result_former({
    INPUT_DATA      => $Storage,
    FUNCTION        => 'storage_admins_list',
    BASE_FIELDS     => 0,
    DEFAULT_FIELDS  => "ID, ADMIN_NAME, PERCENT, COMMENTS",
    FUNCTION_FIELDS => 'change,del',
    SKIP_USER_TITLE => 1,
    EXT_TITLES      => {
      'id'         => "ID",
      'percent'    => "$lang{PERCENT}, %",
      'admin_name' => $lang{ADMIN},
      'comments'   => $lang{COMMENTS},
    },
    TABLE           => {
      width   => '100%',
      caption => $lang{ADMINS},
      qs      => $pages_qs,
      ID      => 'STORAGE_PROPERTY',
    },
    MAKE_ROWS       => 1,
    SEARCH_FORMER   => 1,
    MODULE          => 'Storage',
    TOTAL           => "TOTAL:$lang{TOTAL}",
  });
}

#***********************************************************
=head2 storage_payers() - Storage payers

=cut
#***********************************************************
sub storage_payers {

  $html->message('info', $lang{INFO}, $FORM{message}) if $FORM{message};

  $Storage->{ACTION} = 'add';
  $Storage->{ACTION_LNG} = $lang{ADD};

  if ($FORM{add}) {
    $Storage->storage_payers_add({ %FORM });
    $html->tpl_show(_include('storage_redirect', 'Storage'), {
      SECTION => '',
      MESSAGE => $lang{ADDED}
    }) if !_error_show($Storage);
  }
  elsif ($FORM{del} && $FORM{COMMENTS}) {
    $Storage->storage_payers_del({ ID => $FORM{del} });
    $html->message('info', $lang{INFO}, $lang{DELETED}) if !_error_show($Storage);
  }
  elsif ($FORM{change}) {
    $Storage->storage_payers_change({ %FORM });
    $html->tpl_show(_include('storage_redirect', 'Storage'), {
      SECTION => '',
      MESSAGE => $lang{CHANGED},
    }) if !_error_show($Storage);
  }
  elsif ($FORM{chg}) {
    $Storage->{ACTION} = 'change';
    $Storage->{ACTION_LNG} = $lang{CHANGE};
    $Storage->storage_payers_info({ ID => $FORM{chg} });
  }

  $html->tpl_show(_include('storage_payers', 'Storage'), { %{$Storage}, %FORM });

  $LIST_PARAMS{DOMAIN_ID} = $admin->{DOMAIN_ID} || undef;

  result_former({
    INPUT_DATA      => $Storage,
    FUNCTION        => 'storage_payers_list',
    BASE_FIELDS     => 3,
    DEFAULT_FIELDS  => 'ID,NAME,COMMENTS',
    HIDDEN_FIELDS   => 'DOMAIN_ID',
    FUNCTION_FIELDS => 'change' . ((defined($permissions{4}->{3})) ? ',del' : ''),
    SKIP_USER_TITLE => 1,
    EXT_TITLES      => {
      id       => 'ID',
      name     => $lang{NAME},
      comments => $lang{COMMENTS}
    },
    TABLE           => {
      width   => '100%',
      caption => $lang{PAYERS},
      qs      => $pages_qs,
      ID      => 'STORAGE_PAYERS',
      EXPORT  => 1
    },
    MAKE_ROWS       => 1,
    TOTAL           => 1
  });

  return 1;
}

#***********************************************************
=head2 storage_delivery_types() - Storage delivery types

=cut
#***********************************************************
sub storage_delivery_types {

  $html->message('info', $lang{INFO}, $FORM{message}) if $FORM{message};

  $Storage->{ACTION} = 'add';
  $Storage->{ACTION_LNG} = $lang{ADD};

  if ($FORM{add}) {
    $Storage->storage_delivery_types_add(\%FORM);
    $html->tpl_show(_include('storage_redirect', 'Storage'), {
      SECTION => '',
      MESSAGE => $lang{ADDED}
    }) if !_error_show($Storage);
  }
  elsif ($FORM{del} && $FORM{COMMENTS}) {
    $Storage->storage_delivery_types_del({ ID => $FORM{del} });
    $html->message('info', $lang{INFO}, $lang{DELETED}) if !_error_show($Storage);
  }
  elsif ($FORM{change}) {
    $Storage->storage_delivery_types_change({ %FORM });
    $html->tpl_show(_include('storage_redirect', 'Storage'), {
      SECTION => '',
      MESSAGE => $lang{CHANGED}
    }) if !_error_show($Storage);
  }
  elsif ($FORM{chg}) {
    $Storage->{ACTION} = 'change';
    $Storage->{ACTION_LNG} = $lang{CHANGE};
    $Storage->storage_delivery_type_info({ ID => $FORM{chg} });
  }

  $html->tpl_show(_include('storage_delivery_types', 'Storage'), { %{$Storage}, %FORM });

  $LIST_PARAMS{DOMAIN_ID} = $admin->{DOMAIN_ID} || undef;

  result_former({
    INPUT_DATA      => $Storage,
    FUNCTION        => 'storage_delivery_types_list',
    BASE_FIELDS     => 3,
    DEFAULT_FIELDS  => 'ID,NAME,COMMENTS',
    FUNCTION_FIELDS => 'change' . ((defined($permissions{4}->{3})) ? ',del' : ''),
    SKIP_USER_TITLE => 1,
    EXT_TITLES      => {
      id       => 'ID',
      name     => $lang{NAME},
      comments => $lang{COMMENTS}
    },
    TABLE           => {
      width   => '100%',
      caption => $lang{DELIVERY_TYPES},
      qs      => $pages_qs,
      ID      => 'STORAGE_DELIVERY_TYPES',
      EXPORT  => 1,
      MENU    => "$lang{ADD}:index=$index&add_form=1:add"
    },
    MAKE_ROWS       => 1,
    TOTAL           => 1
  });

  return 1;
}

1;