=head1 NAME

  Address Manage functions

=cut


use strict;
use warnings FATAL => 'all';
use AXbills::Base qw(in_array load_pmodule);
use Address;

our (
  $db,
  $admin,
  %conf,
  %lang,
  @bool_vals,
  $users
);

our AXbills::HTML $html;
my $Address = Address->new($db, $admin, \%conf);
my $Auxiliary;

#**********************************************************
=head2 form_districts()

=cut
#**********************************************************
sub form_districts {

  $Address->{ACTION} = 'add';
  $Address->{LNG_ACTION} = $lang{ADD};

  if ($FORM{IMPORT_ADDRESS}) {
    address_import();
    return 0;
  }
  elsif ($FORM{add} && $FORM{NAME}) {
    $Address->district_add({ %FORM });

    if (!$Address->{errno}) {
      # if ($FORM{FILE_UPLOAD}) {
      #   my $name = '';
      #   if ($FORM{FILE_UPLOAD}{filename} && $FORM{FILE_UPLOAD}{filename} =~ /\.(\S+)$/i) {
      #     $name = $Address->{INSERT_ID} . '.' . lc($1);
      #   }
      #   upload_file($FORM{FILE_UPLOAD}, { PREFIX => 'maps', FILE_NAME => $name, REWRITE => 1 });
      # }

      $html->message('info', $lang{DISTRICT}, $lang{ADDED});
    }
  }
  elsif ($FORM{change}) {
    $FORM{TYPE_ID} ||= 0;
    $Address->district_change(\%FORM);

    if (!$Address->{errno}) {
      $html->message('info', $lang{DISTRICTS}, $lang{CHANGED});
      # if ($FORM{FILE_UPLOAD}) {
      #   my $name = '';
      #   if ($FORM{FILE_UPLOAD}{filename} && $FORM{FILE_UPLOAD}{filename} =~ /\.([a-z0-9]+)$/i) {
      #     $name = $FORM{ID} . '.' . lc($1);
      #   }
      #
      #   upload_file($FORM{FILE_UPLOAD}, { PREFIX => 'maps', FILE_NAME => $name, REWRITE => 1 });
      # }
    }
  }
  elsif ($FORM{chg}) {
    $Address->district_info({ ID => $FORM{chg} });
    $Address->{DISTRICT_SEL} = sel_districts_full_path({
      DISTRICT_ID         => $Address->{PARENT_ID},
      SKIP_DISTRICT_ID    => $FORM{chg},
      DISTRICT_IDENTIFIER => 'PARENT_ID'
    });

    if (!$Address->{errno}) {
      $Address->{ACTION} = 'change';
      $Address->{LNG_ACTION} = $lang{CHANGE};
      $FORM{add_form} = 1;
      $html->message('info', $lang{DISTRICTS}, $lang{CHANGING});
    }
  }
  elsif ($FORM{del} && $FORM{COMMENTS}) {
    $Address->district_del($FORM{del});

    if (!$Address->{errno}) {
      $html->message('info', $lang{DISTRICTS}, $lang{DELETED});
    }
  }

  _error_show( $Address );

  # my $countries_hash;
  # ($countries_hash, $Address->{COUNTRY_SEL}) = sel_countries( { COUNTRY => $Address->{COUNTRY} } );

  $Address->{TYPE_SEL} = $html->form_select('TYPE_ID', {
    SELECTED    => $Address->{TYPE_ID} || '_SHOW',
    SEL_LIST    => translate_list($Address->address_type_list({ NAME => '_SHOW', COLS_NAME => 1, SORT => 'at.position' })),
    SEL_KEY     => 'id',
    SEL_VALUE   => 'name',
    NO_ID       => 1
  });

  my $list = $Address->district_list({ TYPE_NAME => '_SHOW', %LIST_PARAMS, COLS_NAME => 1,  PAGE_ROWS => 10000 });
  my $table = $html->table({
    width      => '100%',
    caption    => $lang{DISTRICTS},
    title      => [ '#', $lang{NAME}, $lang{TYPE}, $lang{ZIP}, $lang{STREETS}, $lang{MAP}, '-' ],
    ID         => 'DISTRICTS_LIST',
    FIELDS_IDS => $Address->{COL_NAMES_ARR},
    EXPORT     => 1,
    IMPORT     => "$SELF_URL?get_index=form_districts&import=1&header=2&IMPORT_ADDRESS=1",
    MENU       => "$lang{ADD}:index=$index&add_form=1:add",
  });

  my $two_confirmation = $conf{TWO_CONFIRMATION} ? $lang{DEL} : '';

  foreach my $line ( @{$list} ){
    my $map = $bool_vals[0];

    $map = form_add_map(undef, { DISTRICT_ID => $line->{id} });

    $table->addrow(
      $line->{id},
      $line->{name},
      # ($line->{country} && $countries_hash->{ $line->{country} })  ? $countries_hash->{ $line->{country} } : q{},
      # $line->{city},
      _translate($line->{type_name}),
      $line->{zip},
      $html->button( $line->{street_count},
        "index=" . get_function_index( 'form_streets' ) . "&DISTRICT_ID=$line->{id}" ),
      $map,
      $html->button( $lang{CHANGE}, "index=$index&chg=$line->{id}", { class => 'change' } )
      .' '. $html->button( $lang{DEL}, "index=$index&del=$line->{id}",
        { MESSAGE => "$lang{DEL} [$line->{id}] $line->{name}?", class => 'del', TWO_CONFIRMATION  => $two_confirmation } )
    );
  }

  if ($FORM{add_form}) {
    $Address->{DISTRICT_SEL} ||= sel_districts_full_path({ DISTRICT_IDENTIFIER => 'PARENT_ID' });
    $html->tpl_show(templates('form_district'), $Address);
  }

  print $table->show();

  return 1;
}

#**********************************************************
=head2 form_streets() - Street list

=cut
#**********************************************************
sub form_streets{

  $Address->{ACTION} = 'add';
  $Address->{LNG_ACTION} = "$lang{ADD}";

  if ( $FORM{BUILDS} ){
    form_builds();
    return 0;
  }
  elsif ($FORM{add}) {
    $Address->street_add({ %FORM });
    $html->message('info', $lang{ADDRESS_STREET}, $lang{ADDED}) if !$Address->{errno};
  }
  elsif ($FORM{change}) {
    $Address->street_change(\%FORM);
    $html->message('info', $lang{ADDRESS_STREET}, $lang{CHANGED}) if !$Address->{errno};
  }
  elsif ($FORM{chg}) {
    $Address->street_info({ ID => $FORM{chg} });

    if (!$Address->{errno}) {
      $Address->{ACTION} = 'change';
      $Address->{LNG_ACTION} = $lang{CHANGE};
      $html->message('info', $lang{ADDRESS_STREET}, $lang{CHANGING});
      $FORM{add_form} = 1;
    }
  }
  elsif ($FORM{del} && $FORM{COMMENTS}) {
    $Address->street_del($FORM{del});
    $html->message('info', $lang{ADDRESS_STREET}, $lang{DELETED}) if !$Address->{errno};
  }
  _error_show($Address);

  # $Address->{DISTRICTS_SEL} = sel_districts({ DISTRICT_ID => $Address->{DISTRICT_ID} });
  $Address->{DISTRICTS_SEL} = sel_districts_full_path({
    DISTRICT_ID => $Address->{DISTRICT_ID} || $FORM{DISTRICT_ID},
    SELECTED    => $Address->{DISTRICT_ID} || $FORM{DISTRICT_ID}
  });

  if ($FORM{add_form}) {
    if ($conf{STREET_TYPE}) {
      $Address->{STREET_TYPE_SELECT} = _street_type_select($Address->{TYPE});
      $Address->{STREET_TYPE_VISIBLE} = 1;
    }
    $Address->{DISTRICT_ID} //= $FORM{DISTRICT_ID};
    $html->tpl_show(templates('form_street'), $Address);
  }

  if ( $FORM{DISTRICT_ID} ){
    $LIST_PARAMS{DISTRICT_ID} = $FORM{DISTRICT_ID};
    $pages_qs .= "&DISTRICT_ID=$LIST_PARAMS{DISTRICT_ID}";
    $Address->district_info({ ID => $FORM{DISTRICT_ID} }) if(! $FORM{chg});
  }

  if ($FORM{search_form}) {
    form_search({
      SEARCH_FORM       => $html->tpl_show(templates('form_street_search'), { %$Address, %FORM }, { OUTPUT2RETURN => 1 }),
      PLAIN_SEARCH_FORM => 1
    });
  }

  $LIST_PARAMS{SORT} = 2 if !$FORM{sort};

  my AXbills::HTML $table;
  ($table) = result_former( {
    INPUT_DATA      => $Address,
    FUNCTION        => 'street_list',
    BASE_FIELDS     => 1,
    DEFAULT_FIELDS  => 'ID,STREET_NAME,BUILD_COUNT,USERS_COUNT',
    HIDDEN_FIELDS   => 'DISTRICT_ID',
    FUNCTION_FIELDS => 'change,del',
    SKIP_USER_TITLE => 1,
    FILTER_COLS     => {
      build_count => 'form_show_link:ID:ID,add=1',
      users_count => 'search_link:form_search:STREET_ID,type=11',
    },
    EXT_TITLES      => {
      street_name   => $lang{NAME},
      district_name => $lang{DISTRICT},
      second_name   => $lang{SECOND_NAME},
      build_count   => $lang{BUILDS},
      users_count   => $lang{USERS}
    },
    TABLE           => {
      caption => $lang{STREETS}.': '. ($Address->{NAME} || q{}),
      qs      => $pages_qs,
      ID      => 'STREETS_LIST',
      EXPORT  => 1,
      MENU    => "$lang{ADD}:index=$index&add_form=1&DISTRICT_ID=" . ($FORM{DISTRICT_ID} || '') . ":add; $lang{SEARCH}:index=$index&search_form=1&DISTRICT_ID=" . ($FORM{DISTRICT_ID} || '') . ":search",
      SHOW_COLS_HIDDEN => {
        DISTRICT_ID => $FORM{DISTRICT_ID}
      }
    },
    MAKE_ROWS       => 1,
  } );

  print $table->show();
  $table = $html->table({
    rows => [ [
      "$lang{STREETS}: " . $html->b($Address->{TOTAL}),
      "$lang{BUILDS}: " . $html->b($Address->{TOTAL_BUILDS} || 0),
      "$lang{USERS}: " . $html->b($Address->{TOTAL_USERS} || 0),
      "$lang{DENSITY_OF_CONNECTIONS}: " . $html->b($Address->{DENSITY_OF_CONNECTIONS} || 0)
    ] ]
  });

  print $table->show();

  return 1;
}

#**********************************************************
=head2 form_builds() - Build managment

=cut
#**********************************************************
sub form_builds{

  $Address->{ACTION} = 'add';
  $Address->{LNG_ACTION} = $lang{ADD};

  my $maps_enabled = in_array('Maps', \@MODULES);

  if (!$FORM{qindex} && !$FORM{xml} && $FORM{BUILDS}) {
    my @header_arr = (
      "$lang{INFO}:index=$index&BUILDS=$FORM{BUILDS}" . (($FORM{chg}) ? "&chg=$FORM{chg}" : ''),
      "Media:index=$index&media=1&BUILDS=$FORM{BUILDS}" . (($FORM{chg}) ? "&chg=$FORM{chg}" : '')
    );

    print $html->table_header(\@header_arr, { TABS => 1 });
  }

  if ($FORM{media}) {
    form_location_media();
    return 1;
  }

  if ($FORM{add}) {
    $Address->build_add({ %FORM });
    $html->message('info', $lang{ADDRESS_BUILD}, $lang{ADDED}) if !$Address->{errno};
  }
  elsif ($FORM{change}) {
    $FORM{PLANNED_TO_CONNECT} = $FORM{PLANNED_TO_CONNECT} ? $FORM{PLANNED_TO_CONNECT} : 0;
    $FORM{NUMBERING_DIRECTION} = $FORM{NUMBERING_DIRECTION} ? $FORM{NUMBERING_DIRECTION} : 0;
    $Address->build_change(\%FORM);

    $html->message('info', $lang{ADDRESS_BUILD}, $lang{CHANGED}) if !$Address->{errno};
  }
  elsif ($FORM{chg}) {
    $Address->build_info({ ID => $FORM{chg} });
    if (!$Address->{errno}) {
      $Address->{PLANNED_TO_CONNECT_CHECK} = $Address->{PLANNED_TO_CONNECT} ? 'checked' : '';
      $Address->{NUMBERING_DIRECTION_CHECK} = $Address->{NUMBERING_DIRECTION} ? 'checked' : '';
      $Address->{ACTION} = 'change';
      $Address->{LNG_ACTION} = $lang{CHANGE};
      $FORM{add_form} = 1;
      $html->message('info', $lang{ADDRESS_BUILD}, $lang{CHANGING});
    }
  }
  elsif ($FORM{del} && $FORM{COMMENTS}) {
    $Address->build_del($FORM{del});
    $html->message('info', $lang{ADDRESS_BUILD}, $lang{DELETED}) if !$Address->{errno};
  }

  _error_show($Address);

  if ($FORM{add_form}) {
    if ($maps_enabled && $FORM{chg}) {
      $Address->{MAP_BLOCK_VISIBLE} = 1;
    }
    $Address->{STREET_SEL} = sel_streets($Address);
    $Address->{TYPE_SEL} = $html->form_select('TYPE_ID', {
      SELECTED    => $Address->{TYPE_ID},
      SEL_LIST    => $Address->building_type_list({ NAME => '_SHOW', COLS_NAME => 1, PAGE_ROWS => 999999 }),
      SEL_OPTIONS => { '' => '--' },
      NO_ID       => 1,
      SEL_VALUE   => 'name',
      SEL_KEY     => 'id'
    });
    $html->tpl_show(templates('form_build'), $Address);
  }

  my $street_name = '';
  if ($FORM{BUILDS}) {
    $pages_qs .= "&BUILDS=$FORM{BUILDS}";

    my $street_list = $Address->street_list({
      ID          => $FORM{BUILDS},
      STREET_NAME => '_SHOW',
      SECOND_NAME => '_SHOW',
      PAGE_ROWS   => 1,
      COLS_NAME   => 1
    });

    if (!$Address->{errno} && $street_list && $street_list->[0]) {
      $street_name = " : " . $street_list->[0]{street_name}
        . (($street_list->[0]{second_name}) ? " ( $street_list->[0]{second_name} )" : '');
    }
  }

  $LIST_PARAMS{DISTRICT_ID} = $FORM{DISTRICT_ID} if ($FORM{DISTRICT_ID});
  $LIST_PARAMS{STREET_ID} = $FORM{BUILDS};
  $LIST_PARAMS{PLANNED_TO_CONNECT}  = $FORM{PLANNED_TO_CONNECT};
  $LIST_PARAMS{NUMBERING_DIRECTION} = $FORM{NUMBERING_DIRECTION};

  my @status_bar = (
    "$lang{PLANNED_TO_CONNECT}:index=$index&BUILDS=" . ($FORM{BUILDS} || '') . "&PLANNED_TO_CONNECT=1",
    "$lang{ALL}:index=$index&BUILDS=" . ($FORM{BUILDS} || '')
  );

  result_former( {
    INPUT_DATA      => $Address,
    FUNCTION        => 'build_list',
    MAP             => 1,
    BASE_FIELDS     => 1,
    DEFAULT_FIELDS  => 'NUMBER,BLOCK,FLORS,ENTRANCES,FLATS,STREET_NAME,USERS_COUNT,USERS_CONNECTIONS,ADDED' . ($maps_enabled ? ',COORDX' : ''),
    HIDDEN_FIELDS   => 'TYPE_NAME',
    FUNCTION_FIELDS => 'msgs_admin:$lang{MESSAGE}:location_id:&add_form=1,change,del',
    EXT_TITLES      => {
      number              => $lang{NUM},
      flors               => $lang{FLORS},
      entrances           => $lang{ENTRANCES},
      flats               => $lang{FLATS},
      street_name         => $lang{STREET},
      users_count         => $lang{USERS},
      users_connections   => "$lang{DENSITY_OF_CONNECTIONS} %",
      added               => $lang{ADDED},
      location_id         => 'LOCATION ID',
      coordx              => $lang{MAP},
      planned_to_connect  => $lang{PLANNED_TO_CONNECT},
      block               => $lang{BLOCK},
      type_name           => $lang{TYPE}
    },
    SKIP_USER_TITLE => 1,
    FILTER_COLS     => {
      users_count => 'search_link:form_search:LOCATION_ID,type=11',
      coordx      => 'form_add_map:ID:ID,',
      number      =>  in_array( 'Dom', \@MODULES )?'form_show_construct:ID:ID,':'',
    },
    # for button MESSAGE
    FILTER_VALUES => {
      street_name => sub {
        my ($number, $line) = @_;
        $line->{location_id} = $line->{id};
        return $number;
      }
    },
    TABLE           => {
      width            => '100%',
      caption          => $lang{BUILDS} . $street_name,
      qs               => $pages_qs,
      ID               => 'BUILDS_LIST',
      header           => $html->table_header(\@status_bar),
      EXPORT           => 1,
      SHOW_COLS_HIDDEN => { BUILDS => $FORM{BUILDS} },
      MENU             => "$lang{ADD}:index=$index&add_form=1&BUILDS=$FORM{BUILDS}:add",
    },
    MAKE_ROWS       => 1,
    TOTAL           => 1
  });

  return 1;
}

#**********************************************************
=head2 form_address_tree()

=cut
#**********************************************************
sub form_address_tree {

  $html->tpl_show(templates('form_address_tree'), {
    ADDRESS_TREE => geolocation_tree({
      CITY_BRANCH     => 1,
      RETURN_TREE     => 1,
      SKIP_INPUT      => 1,
      HREF_TO_ADDRESS => 1
    })
  });
}

#**********************************************************
=head2 form_show_construct()

=cut
#**********************************************************
sub form_show_construct{
  my ($id,$attr) = @_;

  return $html->button( $id, "index=". get_function_index('dom_info') ."&LOCATION_ID=$attr->{VALUES}->{ID}" );
}

#**********************************************************
=head2 form_show_link()

=cut
#**********************************************************
sub form_show_link{
  my ($params, $attr) = @_;

  return $html->button( $params, "index=$index&BUILDS=$attr->{VALUES}->{ID}" );
}

#**********************************************************
=head2 form_location_media($attr)

=cut
#**********************************************************
sub form_location_media{

  if ( $FORM{show} ){
    $Address->location_media_info( { ID => $FORM{show} } );
    print "Content-Type: $Address->{CONTENT_TYPE}\n\n";
    print "$Address->{CONTENT}";
    return 1;
  }
  elsif ( $FORM{add} ){
    $Address->location_media_add( {
        %FORM,
        LOCATION_ID  => $FORM{chg},
        CONTENT      => $FORM{FILE}{Contents},
        FILESIZE     => $FORM{FILE}{Size},
        FILENAME     => $FORM{FILE}{filename},
        CONTENT_TYPE => $FORM{FILE}{'Content-Type'},
      } );

    if ( !$Address->{errno} ){
      $html->message( 'info', $lang{ADDRESS_BUILD}, "$lang{ADDED}" );
    }
  }
  elsif ( $FORM{del} && $FORM{COMMENTS} ){
    $Address->location_media_del( $FORM{del} );

    if ( !$Address->{errno} ){
      $html->message( 'info', $lang{ADDRESS_BUILD}, "$lang{DELETED}" );
    }
  }

  _error_show( $Address );

  $html->tpl_show( templates( 'form_location_media' ), $Address );

  my $list = $Address->location_media_list( { LOCATION_ID => $FORM{chg}, COLS_NAME => 1 } );

  foreach my $line ( @{$list} ){
    my $del_btn = $html->button( $lang{DEL}, "index=$index&media=1&chg=$FORM{chg}&BUILDS=$FORM{BUILDS}&del=$line->{id}",
      {
        MESSAGE => "$lang{DEL} [$line->{id}] $line->{comments}?", class => 'del' } );

    #Fixme mktpl
    print "<div class='row'>
    <div class='col-md-4'>
    ID: $line->{id} <br>
    $lang{COMMENTS}: $line->{comments} <br>
    $lang{FILE}: $line->{filename} <br>
    $del_btn
    </div>
    <div class='col-md-8 bg-success'>
      <img src='$SELF_URL?qindex=$index&media=1&chg=$FORM{chg}&BUILDS=$FORM{BUILDS}&show=$line->{id}'>
    </div>
    </div>\n";
  }

  return 1;
}

#**********************************************************
=head2 form_add_map($coordx, $attr)

=cut
#**********************************************************
sub form_add_map {
  my (undef, $attr) = @_;

  return '' if (!in_array('Maps', \@MODULES) || ($admin->{MODULES} && !$admin->{MODULES}{Maps}));

  if (!$Auxiliary) {
    require Maps::Auxiliary;
    Maps::Auxiliary->import();
    $Auxiliary = Maps::Auxiliary->new($db, $admin, \%conf, { HTML => $html, LANG => \%lang });
  }

  if ($attr->{DISTRICT_ID}) {
    eval { require Maps; };
    return '' if ($@);

    Maps->import();
    my $Maps = Maps->new($db, $admin, \%conf);

    my $district_info = $Maps->districts_list({ DISTRICT_ID => $attr->{DISTRICT_ID}, OBJECT_ID => '_SHOW' });
    my $object_id = ($Maps->{TOTAL}) ? ($district_info->[0]{object_id} || q{}) : '';

    return $Auxiliary->maps_show_object_button(4, $object_id);
  }

  my $object_id = $attr->{BUILD_ID} || $attr->{VALUES}{ID};
  $Address->build_info({ ID => $object_id });

  my %params = (CHECK_BUILD => 1, ADD_POINT => 1, LOAD_TO_MODAL => 1, BTN_CLASS => 'btn btn-sm btn-success');
  if (!$Address->{COORDX} || !$Address->{COORDY}) {
    $params{ICON} = 'fa fa-map-marker-alt';
    $params{BTN_CLASS} = 'btn btn-sm btn-primary';
  }

  return $Auxiliary->maps_show_object_button(1, $object_id, \%params);
}

#**********************************************************
=head2 form_address_sel() - Multi address form

=cut
#**********************************************************
sub form_address_sel {

  print "Content-Type: text/html\n\n";

  my $js_list   = "<option></option>";

  my $list_to_options_string = sub {
   my ($array_ref, $value_key, $name_key) = @_;
    $value_key //= 'id';
    $name_key //= 'name';

    my $res = '';
    foreach my $line (@$array_ref){
      my $value = $line->{$name_key};
      $value =~ s/\'/&rsquo;/g;
      $res .= "<option value='$line->{$value_key}'>$value</option>";
    }

    $res;
  };

  # Show builds
  if ($FORM{STREET} || $FORM{STREET_ID}) {

    my $builds_list = $Address->build_list({
      STREET_ID => $FORM{STREET} || $FORM{STREET_ID},
      BLOCK     => '_SHOW',
      COORDX    => '_SHOW',
      PAGE_ROWS => 10000,
      COLS_NAME => 1
    });

    if ($Address->{TOTAL} > 0) {
      foreach my $line (@$builds_list) {
        $line->{number} =~ s/\'/&rsquo;/g;
        my $value = $line->{number};

        if ($line->{block}){
          $value .= "-$line->{block}";
        }

        if($FORM{SHOW_UNREG} && $line->{coordx} == 0) {
          $value .= ' (+)';
        }

        $js_list .= "<option value='$line->{id}'>$value</option>";
      }

    }
    print $js_list;
  }
  # Show streets
  elsif ($FORM{DISTRICT_ID}) {
    my $streets_list = $Address->street_list({
      DISTRICT_ID => $FORM{DISTRICT_ID},
      STREET_NAME => '_SHOW',
      TYPE        => '_SHOW',
      PAGE_ROWS   => 10000,
      SORT        => 2,
      COLS_NAME   => 1
    });

    if ($conf{STREET_TYPE}) {
      my @street_type_list = split (';', $conf{STREET_TYPE});

      $streets_list = [ map {
        { %$_,
          street_name => join (' ', ($street_type_list[($_->{type} || 0)]) ? $street_type_list[$_->{type}] : q{}, ($_->{street_name} || q{}))
        };
      } @{$streets_list} ];
    }

    print $js_list . $list_to_options_string->($streets_list, 'id', 'street_name');
  }
  # Show users
  elsif ($FORM{LOCATION_ID}) {
    my $list = $users->list({
      LOCATION_ID  => $FORM{LOCATION_ID},
      ADDRESS_FLAT => '!',
      PAGE_ROWS    => 1000,
      COLS_NAME    => 1
    });

    my $json_load_error = load_pmodule("JSON", { RETURN => 1 });
    if ($json_load_error) {
      print $json_load_error;
      return 0;
    }

    my $json = JSON->new->utf8(0);
    print $json->encode({
      map {
          $_->{address_flat} =>
            {
              uid       => $_->{uid},
              user_name => $_->{login}
            }
      } @{$list}
    });
  }
  # Show districts
  else {
    my $districts_list = $Address->district_list({
      %LIST_PARAMS,
      PAGE_ROWS => 1000,
      COLS_NAME => 1,
      SORT      => 'city',
    });

    print $js_list . $list_to_options_string->($districts_list);
  }

  exit;
}

#**********************************************************
=head2 sel_countries($attr) - Country Select;

  Arguments:
    $attr
      NAME      - Select object name (Default: COUNTRY)
      COUNTRY   - Selected value
  Returns:
    \%countries_hash, $sel_form

=cut
#**********************************************************
sub sel_countries {
  my ($attr) = @_;

  my %countries_hash = ();

  my $countries = $html->tpl_show(templates('countries'), undef, { OUTPUT2RETURN => 1 });
  my @countries_arr = split(/[\r\n]/, $countries);

  foreach my $c (@countries_arr) {
    my ($id, $name) = split(/:/, $c);
    if ($id && $id =~ /^\d+$/){
      $countries_hash{ int($id) } = $name;
    }
  }

  my $sel_form = $html->form_select($attr->{NAME} || 'COUNTRY', {
    SELECTED => $attr->{COUNTRY} || $FORM{COUNTRY} || 0,
    SEL_HASH => { '' => '', %countries_hash },
    NO_ID    => 1
  });

  return \%countries_hash, $sel_form;
}

# #**********************************************************
# =head2 sel_districts($attr)
#
#   Arguments:
#     $attr
#       DISTRICT_ID
#
#   Result:
#     Select form
#
# =cut
# #**********************************************************
# sub sel_districts {
#   my ($attr) = @_;
#
#   $attr ||= {};
#   $attr->{SELECT_ID} ||= 'DISTRICT_ID';
#   $attr->{SELECT_NAME} ||= 'DISTRICT_ID';
#
#   my @district_buttons = ();
#   push @district_buttons, $html->form_input('DISTRICT_MULTIPLE', '1', {
#     TYPE      => 'checkbox',
#     class     => 'form-control-static m-2',
#     EX_PARAMS => "data-select-multiple='$attr->{SELECT_ID}'",
#     STATE     => $attr->{DISTRICT_MULTIPLE} ? '1' : undef
#   }) if $attr->{MULTIPLE} && !$attr->{SKIP_MULTIPLE_BUTTON};
#
#   $attr->{DISTRICT_ID} =~ s/;/,/g if $attr->{DISTRICT_ID};
#   return $html->form_select($attr->{SELECT_NAME}, { %{$attr},
#     SELECTED    => $attr->{DISTRICT_ID} || $FORM{DISTRICT_ID},
#     SEL_LIST    => $Address->district_list({ COLS_NAME => 1, PAGE_ROWS => 999999, SORT => 'd.name' }),
#     SEL_OPTIONS => { '' => '--' },
#     NO_ID       => 1,
#     ID          => $attr->{SELECT_ID},
#     EXT_BUTTON  => \@district_buttons
#   });
# }

#**********************************************************
=head2 sel_districts($attr)

  Arguments:
    $attr
      DISTRICT_ID

  Results:
    Select form

=cut
#**********************************************************
sub sel_districts {
  my ($attr) = @_;

  $attr ||= {};
  $attr->{SELECT_ID} ||= 'DISTRICT_ID';
  $attr->{SELECT_NAME} ||= 'DISTRICT_ID';
  $attr->{DISTRICT_ID} =~ s/,/;/g if $attr->{DISTRICT_ID};

  my $districts = $Address->district_list({
    PARENT_ID   => $attr->{PARENT_ID},
    FULL_NAME   => $attr->{FULL_NAME} ? '_SHOW' : '',
    HAVING      => $attr->{ONLY_WITH_STREETS} ? 'HAVING street_count > 0' : '',
    NAME        => '_SHOW',
    PARENT_NAME => '_SHOW',
    ID          => $attr->{ID} || '_SHOW',
    PAGE_ROWS   => 10000,
    COLS_NAME   => 1
  });

  my %district_hash = ();
  foreach my $district (@{$districts}) {
    if ($district->{full_name}) {
      $district_hash{$district->{id}} = $district->{full_name};
      next;
    }

    if ($district->{parent_name}) {
      $district_hash{$district->{parent_name}}{$district->{id}} = $district->{name};
    }
    else {
      $district_hash{$district->{id}} = $district->{name};
    }
  }

  my @district_buttons = ();
  push @district_buttons, $html->form_input('DISTRICT_MULTIPLE', '1', {
    TYPE      => 'checkbox',
    class     => 'form-control-static m-2',
    EX_PARAMS => "data-select-multiple='$attr->{SELECT_ID}'",
    STATE     => $attr->{DISTRICT_MULTIPLE} ? '1' : undef,
    ID        => "DISTRICT_MULTIPLE_$attr->{SELECT_ID}",
  }) if $attr->{MULTIPLE} && !$attr->{SKIP_MULTIPLE_BUTTON};

  $attr->{DISTRICT_ID} =~ s/;/,/g if $attr->{DISTRICT_ID};
  return $html->form_select($attr->{SELECT_NAME}, { %{$attr},
    SELECTED    => $attr->{DISTRICT_ID} || $FORM{DISTRICT_ID},
    SEL_HASH    => \%district_hash,
    SEL_VALUE   => 'name',
    SEL_OPTIONS => { '' => '--' },
    NO_ID       => 1,
    ID          => $attr->{SELECT_ID},
    SORT_VALUE  => $attr->{FULL_NAME} ? 'full_name' : 'name',
    EXT_BUTTON  => \@district_buttons,
    SELECT_ID   => $attr->{SELECT_ID}
  });
}

#**********************************************************
=head2 sel_districts_full_path($attr)

  Arguments:
    $attr
      DISTRICT_ID
      SELECT_ID
      SKIP_DISTRICT_ID
      DISTRICT_MULTIPLE
      DISTRICT_IDENTIFIER

  Results:
    Select form

=cut
#**********************************************************
sub sel_districts_full_path {
  my ($attr) = @_;

  my $district_id = $attr->{DISTRICT_ID} || 0;
  my $parent_id = $district_id;
  my $parent_info = {};
  my %Address_old = %$Address;
  my @selects = ();
  my $select_id = $attr->{SELECT_ID} || 'DISTRICT_SEL';

  while ($parent_id) {
    my $address_sel = sel_districts({
      %{$attr || {}},
      ID                => $attr->{SKIP_DISTRICT_ID} ? "!$attr->{SKIP_DISTRICT_ID}" : '',
      PARENT_ID         => $parent_id,
      DISTRICT_ID       => $parent_info->{ID},
      SELECT_ID         => "$select_id$parent_id",
      DISTRICT_MULTIPLE => $parent_info->{ID} && $parent_info->{ID} =~ /,/ ? '1' : undef,
      SELECT_NAME       => 'DISTRICT_SEL'
    });
    my $total_districts = $Address->{TOTAL};

    if ($parent_id =~ /;/) {
      my $parents = $Address->district_list({ ID => $parent_id, PARENT_ID => '_SHOW', COLS_NAME => 1 });
      my @parent_ids = ();
      my @ids = ();

      foreach my $parent (@{$parents}) {
        push @parent_ids, $parent->{parent_id} if !in_array($parent->{parent_id}, \@parent_ids);
        push @ids, $parent->{id};
      }
      $parent_info->{ID} = join(',', @ids);
      $parent_id = join(';', @parent_ids);
    }
    else {
      $parent_info = $Address->district_info({ ID => $parent_id });

      last if !defined $parent_info->{PARENT_ID} || $parent_id eq $parent_info->{PARENT_ID};
      $parent_id = $parent_info->{PARENT_ID};
    }
    next if $total_districts < 1;

    push @selects, $html->element('div', $address_sel, { class => 'mt-3', OUTPUT2RETURN => 1 });
  }

  my $districts = $Address->district_list({
    ID        => $attr->{ID} || '_SHOW',
    PARENT_ID => 0,
    NAME      => '_SHOW',
    PAGE_ROWS => 999999,
    SORT      => 'd.name',
    COLS_NAME => 1
  });

  $parent_id //= '';
  my $root_sel = sel_districts({
    %{$attr || {}},
    ID                => $attr->{SKIP_DISTRICT_ID} ? "!$attr->{SKIP_DISTRICT_ID}" : '',
    PARENT_ID         => 0,
    DISTRICT_ID       => $parent_info->{ID} || $attr->{SELECTED},
    SELECT_ID         => "$select_id$parent_id",
    DISTRICT_MULTIPLE => $attr->{DISTRICT_MULTIPLE} ? '1' : undef,
    SELECT_NAME       => 'DISTRICT_SEL'
  });

  push @selects, $html->element('div', $root_sel, { OUTPUT2RETURN => 1 });

  %$Address = %Address_old if $district_id;
  return $html->tpl_show(templates('form_district_sel'), {
    DISTRICT_SEL        => join('', reverse @selects),
    DISTRICT_IDENTIFIER => $attr->{DISTRICT_IDENTIFIER} || 'DISTRICT_ID',
    DISTRICT_SELECTED   => $district_id || ''
  }, { OUTPUT2RETURN => 1 });
}

#**********************************************************
=head2 sel_cities($attr)

  Arguments:
    $attr
      CITY

  Result:
    Select form

=cut
#**********************************************************
sub sel_cities {
  my ($attr) = @_;

  $attr ||= {};
  $attr->{SELECT_ID} ||= 'CITY';
  $attr->{SELECT_NAME} ||= 'CITY';

  $attr->{CITY} =~ s/;/,/g if $attr->{CITY};
  return $html->form_select($attr->{SELECT_NAME}, { %{$attr},
    SELECTED    => $attr->{CITY} || $FORM{CITY},
    SEL_LIST    => $Address->district_list({ COLS_NAME => 1, PAGE_ROWS => 999999, GROUP_BY => 'GROUP BY d.city' }),
    SEL_OPTIONS => { '' => '--' },
    NO_ID       => 1,
    SEL_VALUE   => 'city',
    SEL_KEY     => 'city',
    ID          => $attr->{SELECT_ID},
  });
}

#**********************************************************
=head2 sel_streets($attr)

  Arguments:
    $attr
      STREET_ID
      SEL_OPTIONS
      MAIN_MENU

  Results:
    Select form

=cut
#**********************************************************
sub sel_streets {
  my ($attr) = @_;

  $attr ||= {};
  $attr->{SELECT_ID} ||= 'STREET_ID';
  $attr->{SELECT_NAME} ||= 'STREET_ID';

  $attr->{DISTRICT_ID} =~ s/,/;/g if $attr->{DISTRICT_ID};
  my $streets = $Address->street_list({
    DISTRICT_NAME => '_SHOW',
    DISTRICT_ID   => $attr->{DISTRICT_ID} || '_SHOW',
    PAGE_ROWS     => 10000,
    STREET_NAME   => '_SHOW',
    COLS_NAME     => 1
  });

  if ($conf{STREET_TYPE}) {
    my @street_type_list = split (';', $conf{STREET_TYPE});
    $streets = [ map {
      { %$_,
        street_name => join (' ', $street_type_list[$_->{type}], $_->{street_name})
      };
    } @{$streets} ];
  }

  my %street_hash = ();
  foreach my $street (@{$streets}) {
    next if !$street->{district_id} || !$street->{district_name};
    $street_hash{$street->{district_name}}{$street->{street_id}} = $street->{street_name};
  }

  my @street_buttons = ();
  push @street_buttons, $html->form_input('STREET_MULTIPLE', '1', {
    TYPE      => 'checkbox',
    class     => 'form-control-static m-2',
    EX_PARAMS => "data-select-multiple='$attr->{SELECT_ID}'",
    STATE     => $attr->{STREET_MULTIPLE} ? '1' : undef
  }) if $attr->{MULTIPLE};

  $attr->{STREET_ID} =~ s/;/,/g if $attr->{STREET_ID};
  return $html->form_select($attr->{SELECT_NAME}, { %{$attr},
    SELECTED       => $attr->{STREET_ID} || $FORM{STREET_ID} || $FORM{BUILDS},
    SEL_HASH       => \%street_hash,
    SEL_VALUE      => 'street_name',
    NO_ID          => 1,
    SEL_OPTIONS    => $attr->{SEL_OPTIONS},
    MAIN_MENU      => $admin->{permissions}{0} && $admin->{permissions}{0}{34} ? get_function_index('form_streets') : '',
    MAIN_MENU_ARGV => ($attr->{STREET_ID} || $FORM{STREETS}) ? "chg=" . ($attr->{STREET_ID} || $FORM{BUILDS}) : '',
    ID             => $attr->{SELECT_ID},
    SORT_VALUE     => 'street_name',
    EXT_BUTTON     => \@street_buttons
  });
}

#**********************************************************
=head2 sel_builds($attr)

  Arguments:
    $attr
      BUILD_ID
      SEL_OPTIONS
      MAIN_MENU

  Results:
    Select form

=cut
#**********************************************************
sub sel_builds {
  my ($attr) = @_;

  $attr ||= {};
  $attr->{SELECT_ID} ||= 'BUILD_ID';
  $attr->{SELECT_NAME} ||= 'BUILD_ID';
  $attr->{HIDE_ADD_BUILD_BUTTON} = 1 if !$admin->{permissions}{0} || !$admin->{permissions}{0}{35};

  $attr->{STREET_ID} =~ s/,/;/g if $attr->{STREET_ID};
  my $builds = $Address->build_list({
    STREET_ID   => $attr->{STREET_ID} || '_SHOW',
    STREET_NAME => '_SHOW',
    BLOCK       => '_SHOW',
    NUMBER      => '_SHOW',
    COLS_NAME   => 1,
    PAGE_ROWS   => 999999
  });

  my %builds_hash = ();

  foreach my $build (@{$builds}) {
    next if (! $build || !$build->{street_id} || !$build->{street_name});

    push(@{$builds_hash{$build->{street_name}}}, [ $build->{id}, $build->{number} ]);
  }

  my @build_buttons = ();

  push @build_buttons, $html->button('', '', {
    ICON      => 'fa fa-plus',
    class     => 'BUTTON-ENABLE-ADD btn input-group-button rounded-left-0' . ($attr->{MULTIPLE} ? ' rounded-right-0' : ''),
    SKIP_HREF => 1,
    TITLE     => "$lang{ADD} $lang{BUILDS}",
    EX_PARAMS => "onload='test'",
  }) if !$attr->{HIDE_ADD_BUILD_BUTTON};

  push @build_buttons, $html->form_input('BUILD_MULTIPLE', '1', {
    TYPE      => 'checkbox',
    class     => 'form-control-static m-2',
    EX_PARAMS => "data-select-multiple='$attr->{SELECT_ID}'",
    STATE     => $attr->{BUILD_MULTIPLE} ? '1' : undef
  }) if $attr->{MULTIPLE};

  return $html->form_select($attr->{SELECT_NAME}, { %{$attr},
    SELECTED    => $attr->{BUILD_ID} || $FORM{BUILDS},
    SEL_HASH    => $attr->{CHECK_STREET_ID} && !$attr->{STREET_ID} ? {} : \%builds_hash,
    SEL_VALUE   => 'number,block',
    NO_ID       => 1,
    SEL_OPTIONS => $attr->{SEL_OPTIONS},
    EXT_BUTTON  => \@build_buttons,
    SORT_VALUE  => 'number',
    ID          => $attr->{SELECT_ID}
  });
}

#**********************************************************
=head2 full_address_name($location_id)

=cut
#**********************************************************
sub full_address_name {
  my ($location_id) = @_;
  return '' if !$location_id;

  my $info = $Address->address_info($location_id);
  my $street_type = '';
  if ($conf{STREET_TYPE} && $info->{STREET_TYPE}) {
    my @street_types = split (';', $conf{STREET_TYPE});
    $street_type = @street_types[$info->{STREET_TYPE}];
  }

  my @address_components = (
    $info->{CITY},
    $info->{ADDRESS_DISTRICT},
    $street_type .' '. ($info->{ADDRESS_STREET} || q{}),
    ($info->{ADDRESS_STREET2} ? "($info->{ADDRESS_STREET2})" : ''),
    $info->{ADDRESS_BUILD},
    ($info->{ADDRESS_BLOCK} ? "-$info->{ADDRESS_BLOCK}" : '')
  );

  my $build_delimiter = $conf{BUILD_DELIMITER} || ', ';
  return join("$build_delimiter", grep { $_ && $_ ne '' } @address_components);
}

#**********************************************************
=head2 short_address_name($location_id)

=cut
#**********************************************************
sub short_address_name {
  my ($location_id) = @_;

  return '' if !$location_id;

  my $info = $Address->address_info($location_id);
  my $street_type = '';
  if ($conf{STREET_TYPE}) {
    $street_type = (split (';', $conf{STREET_TYPE}))[$info->{STREET_TYPE}];
  }

  $info->{ADDRESS_STREET} =  $info->{ADDRESS_STREET} ? "($info->{ADDRESS_STREET})" : '';
  my @address_components = (
    "$street_type $info->{ADDRESS_STREET}",
    ($info->{ADDRESS_STREET2} ? "($info->{ADDRESS_STREET2})" : ''),
    $info->{ADDRESS_BUILD},
    ($info->{ADDRESS_BLOCK} ? "-$info->{ADDRESS_BLOCK}" : '')
  );

  return join(', ', grep { $_ && $_ ne '' } @address_components);
}

#**********************************************************
=head2 form_address($attr) - shows form for adding nas addrress

  Arguments:
    $attr
      LOCATION_ID         =>
      FLAT_CHECK_FREE     => 1
      FLAT_CHECK_OCCUPIED => 1
      SHOW                => 1
      SHOW_BUTTONS     => 1 - Do not show Maps, Dom, Add District and Add Street buttons
      FLOOR               => value    - Shows Extra fields entrance and floor at the address box
        and add value into floor input
      ENTRANCE            => value    - Shows Extra fields entrance and floor at the address box
        and add value into entrance input

  Results:
    return $result

  Example:

    $Nas->{ADDRESS_FORM}   = form_address({
      LOCATION_ID => $Nas->{LOCATION_ID},
      FLOOR       => $Nas->{FLOOR},
      ENTRANCE    => $Nas->{ENTRANCE}
    });

=cut
#**********************************************************
sub form_address {
  my ($attr) = @_;
  my %params = ();
  my $whatsform = 'form_show_not_hide';
  $params{BUTTON_ICON} = !$attr->{SHOW} ? 'plus' : 'minus';

  if (!$conf{ADDRESS_REGISTER} ) {
    my $countries_hash;
    ($countries_hash, $params{COUNTRY_SEL}) = sel_countries({
      NAME    => 'COUNTRY_ID',
      COUNTRY => $attr->{COUNTRY_ID}
    });

    return $html->tpl_show(templates('form_address'), { %{ ($attr) ? $attr : {} }, %params }, { OUTPUT2RETURN => 1 });
  }

  if ($attr->{LOCATION_ID}) {
    $Address->address_info($attr->{LOCATION_ID});
    if (in_array('Dom', \@MODULES)) {
      $Address->{DOM_BTN} = $html->button("", 'index=' . get_function_index('dom_info') . "&LOCATION_ID=$attr->{LOCATION_ID}", {
        class     => 'btn btn-success btn-sm',
        ex_params => "data-tooltip-position='top' data-tooltip='$lang{BUILD_SCHEMA}'", ICON => 'far fa-building '
      });
    }
    $Address->{FLAT_CHECK_FREE} = 1;

    $Address->{ADDRESS_DISTRICT} = $Address->{ADDRESS_DISTRICT_FULL} if $Address->{ADDRESS_DISTRICT_FULL};
    if ($Address->{ADDRESS_DISTRICT}) {
      my $delimiter = $conf{BUILD_DELIMITER} || ', ';

      if ($conf{STREET_TYPE}) {
        $Address->{ADDRESS_STREET_TYPE_NAME} = (split (';', $conf{STREET_TYPE}))[$Address->{STREET_TYPE}];
      }

      $Address->{ADDRESS_STREET_TYPE_NAME} //= '';
      $Address->{ADDRESS_FLAT} //= $attr->{ADDRESS_FLAT} || "";

      if ($conf{ADDRESS_FORMAT}) {
        my $address = $conf{ADDRESS_FORMAT};
        while ($address =~ /\%([A-Z\_0-9]+)\%/g) {
          my $patern = $1;
          $address =~ s/\%$patern\%/$Address->{$patern}/g;
        }
        $params{ADD_NAME} = $address;
      }
      else {
        $attr->{ADDRESS_FULL} = "$Address->{ADDRESS_STREET_TYPE_NAME} $Address->{ADDRESS_STREET}$delimiter$Address->{ADDRESS_BUILD}$delimiter$Address->{ADDRESS_FLAT}";
      }
    }
  }

  if($attr->{REGISTRATION_HIDE_ADDRESS_BUTTON}){
    $Address->{HIDE_ADD_BUILD_BUTTON}   = "style='display:none;'" if (!$conf{REGISTRATION_ADD_PLANNED_BUILDS});
    $Address->{HIDE_ADD_ADDRESS_BUTTON} = "style='display:none;'";
  }

  if (defined($attr->{FLOOR}) || defined($attr->{ENTRANCE})) {
    $Address->{EXT_ADDRESS} = $html->tpl_show(templates('form_ext_address'), {
      ENTRANCE => $attr->{ENTRANCE},
      FLOOR    => $attr->{FLOOR}
    }, { OUTPUT2RETURN => 1 });
  }

  if (! $conf{ADDRESS_FORMAT}) {
    if ($Address->{ADDRESS_DISTRICT} && $attr->{ADDRESS_FULL}) {
      if ($Address->{CITY}) {
        $params{ADD_NAME} = "$Address->{ADDRESS_DISTRICT}: $attr->{ADDRESS_FULL} / $Address->{CITY}";
      }
      else {
        $params{ADD_NAME} = "$Address->{ADDRESS_DISTRICT}: $attr->{ADDRESS_FULL}";
      }
    }
  }

  $params{ADD_NAME} //= q{};
  $params{HEADER_PARAMS} = qq{data-tooltip-position='top' data-tooltip='$lang{COPIED}!' data-tooltip-onclick='1' onclick='copyToBuffer("$params{ADD_NAME}", true)'};

  if ($attr->{ADDRESS_HIDE}) {
    $params{PARAMS} = 'mb-0 border-top';
    $whatsform = 'form_show_hide';
  }

  my $result = $html->tpl_show(templates($whatsform), {
    CONTENT => form_address_select2({ %$Address, %$attr }),
    NAME    => "$lang{ADDRESS}:",
    ID      => 'ADDRESS_FORM',
    %params
  }, { OUTPUT2RETURN => 1 });

  return $result;
}

#**********************************************************
=head2 _street_type_select

=cut
#**********************************************************
sub _street_type_select {
  my ($selected) = @_;

  my @street_types = split(';', $conf{STREET_TYPE} || '');

  my $result = $html->form_select("TYPE", {
    SELECTED     => $selected,
    SEL_ARRAY    => \@street_types,
    ARRAY_NUM_ID => 1,
  });

  return $result;
}

#**********************************************************
=head2 form_address_select2($attr)

  Arguments:
    $attr -
    SHOW_BUTTONS => 1 - Show Maps, Dom buttons
    SHOW_ADD_BUTTONS => 1 - Show Add District and Add Street buttons
    HIDE_BUILDS => 1 - Hide builds (wow!)
  Returns:

=cut
#**********************************************************
sub form_address_select2 {
  my ($attr) = @_;
  my $form = q{};

  if ($FORM{MAP_BUILT_BTN}) {
    my $map_button = form_add_map(undef, { BUILD_ID => $FORM{MAP_BUILT_BTN} });
    print $map_button if $FORM{PRINT_BUTTON};
    return $map_button;
  }

  my $district_select_name = q{DISTRICT_ID};
  my $street_select_name = q{STREET_ID};
  my $build_select_name = q{BUILD_ID};

  my $district_id = $FORM{DISTRICT_SELECT_ID} || $attr->{DISTRICT_SELECT_ID} || q{DISTRICT_ID};
  my $street_id = $FORM{STREET_SELECT_ID} || $attr->{STREET_SELECT_ID} || q{STREET_ID};
  my $build_id = $FORM{BUILD_SELECT_ID} || $attr->{BUILD_SELECT_ID} || q{BUILD_ID};

  if ($attr->{REGISTRATION_MODAL}) {
    $district_select_name = q{REG_DISTRICT_ID};
    $street_select_name = q{REG_STREET_ID};
    $build_select_name = q{REG_BUILD_ID};
  }

  if ($attr->{LOCATION_ID} && ($attr->{LOCATION_ID} !~ /;|,/ && $attr->{LOCATION_ID} != 0)) {
    my $full_address = $Address->build_list({
      LOCATION_ID => $attr->{LOCATION_ID},
      DISTRICT_ID => '_SHOW',
      STREET_ID   => '_SHOW',
      BLOCK       => '_SHOW',
      COLS_NAME   => 1
    });
    $attr->{DISTRICT_ID} = $full_address->[0]->{district_id};
    $attr->{STREET_ID} = $full_address->[0]->{street_id};
    $attr->{BUILD_ID} = $full_address->[0]->{id};
  }

  my $district_select = $conf{ADDRESS_DISTRICT_ONE_LINE} ? sel_districts({ %FORM, %{$attr},
    ID                => $attr->{SKIP_DISTRICT_ID} ? "!$attr->{SKIP_DISTRICT_ID}" : '',
    DISTRICT_ID       => $attr->{DISTRICT_ID},
    SELECT_ID         => $district_id,
    SELECT_NAME       => $district_select_name,
    EX_PARAMS         => ($attr->{DISTRICT_REQ} || '') . ' ' . 'onChange="GetStreets(this)"',
    FULL_NAME         => 1,
    ONLY_WITH_STREETS => 1
  }) : sel_districts_full_path({ %FORM, %{$attr},
    DISTRICT_ID => $attr->{DISTRICT_ID},
    SELECT_ID   => $district_id,
    SELECT_NAME => $district_select_name
  });

  my $street_select = sel_streets({ %FORM, %{$attr},
    MAIN_MENU   => undef,
    EX_PARAMS   => 'onChange="GetBuilds(this)" ' . ($attr->{STREET_REQ} || ''),
    SELECT_NAME => $street_select_name,
    SELECT_ID   => $street_id,
    SEL_OPTIONS => { '' => '--' },
  });
  my $build_select = $attr->{HIDE_BUILD} ? '' : sel_builds({ %FORM, %{$attr},
    SELECT_NAME     => $build_select_name,
    SELECT_ID       => $build_id,
    EX_PARAMS       => 'onChange="GetLoc(this)" ' . ($attr->{BUILD_REQ} || ''),
    CHECK_STREET_ID => 1,
    SEL_OPTIONS     => { '' => '--' },
  });

  my $district_button = $admin->{permissions}{4} ? $html->button("", 'get_index=form_districts&full=1&header=1', {
    class => 'btn btn-success btn-sm',
    ICON => "fa fa-street-view",
    ex_params => "data-tooltip-position='top' data-tooltip='$lang{ADD} $lang{DISTRICT}'",
  }) : '';
  my $street_button = $admin->{permissions}{0} && $admin->{permissions}{0}{34} ? $html->button("", 'get_index=form_streets&full=1&header=1', {
    class     => 'btn btn-success btn-sm',
    ICON      => "fa fa-road",
    ex_params => "data-tooltip-position='top' data-tooltip='$lang{ADD} $lang{STREET}'",
  }) : '';
  my $maps_btn = in_array('Maps', \@MODULES) ? $html->button('', 'get_index=maps_main&QUICK=1&SMALL=1&header=2&MODAL=1&CREATE_MARKER=1', {
    LOAD_TO_MODAL => 1,
    class         => 'btn btn-sm btn-success',
    title         => $lang{SHOW},
    ICON          => 'fa fa-globe',
  }) : '';

  if ($attr->{REGISTRATION_MODAL}) {
    $form = $html->tpl_show(templates('registration_modal_address'), {
      ADDRESS_DISTRICT => $district_select,
      ADDRESS_STREET   => $street_select,
      ADDRESS_BUILD    => $build_select,
      LOCATION_ID      => $attr->{LOCATION_ID} || '',
      EXT_SEL_STYLE    => $attr->{EXT_SEL_STYLE} ? $attr->{EXT_SEL_STYLE} : q{},
    }, { OUTPUT2RETURN => 1 });
  }
  else {
    $form = $html->tpl_show(templates('form_address_search2'), {
      ADDRESS_DISTRICT    => $district_select,
      # DISTRICT_ID         => $district_id,
      DISTRICT_ID         => $attr->{DISTRICT_ID},
      STREET_ID           => $street_id,
      BUILD_ID            => $build_id,
      # QINDEX              => $FORM{REG_QINDEX} || '',
      ADDRESS_STREET      => $street_select,
      ADDRESS_BUILD       => $build_select,
      ADDRESS_FLAT        => $attr->{ADDRESS_FLAT} || '',
      LOCATION_ID         => $attr->{LOCATION_ID} || '',
      HIDE_FLAT           => $attr->{HIDE_FLAT} ? 'display: none' : '',
      HIDE_BUILD          => $attr->{HIDE_BUILD} ? 'display: none' : '',
      EXT_ADDRESS         => $attr->{EXT_ADDRESS} ? $attr->{EXT_ADDRESS} : q{},
      MAP_BTN             => $attr->{MAP_BTN} && $attr->{SHOW_BUTTONS} ? $attr->{MAP_BTN} : q{},
      DOM_BTN             => $attr->{DOM_BTN} && $attr->{SHOW_BUTTONS} ? $attr->{DOM_BTN} : q{},
      EXT_SEL_STYLE       => $attr->{EXT_SEL_STYLE} ? $attr->{EXT_SEL_STYLE} : q{},
      ADDRESS_ADD_BUTTONS => $attr->{SHOW_ADD_BUTTONS} ? "$district_button $street_button" : q{},
      MAPS_BTN            => $maps_btn && $attr->{SHOW_BUTTONS} ? $maps_btn : q{},
      MAPS_SHOW_OBJECTS   => $maps_btn && $attr->{SHOW_BUTTONS} ? 1 : '',
      BUILD_SELECTED      => $attr->{LOCATION_ID} || 0,
      BUILD_REQ           => $attr->{BUILD_REQ},
      CHECK_ADDRESS_FLAT  => $attr->{CHECK_ADDRESS_FLAT} || ''
    }, { OUTPUT2RETURN => 1, ID => 'form_address_sel2' });
  }

  return $form;
}

#**********************************************************
=head2 address_import()

    This function is intended for
    importing addresses into the address register table from
    .json/.csv extension files

    Arguments:
      -

    Return:
      -

=cut
#**********************************************************
sub address_import {

  if ($FORM{add}) {
    if (!$FORM{IMPORT_FIELDS} &&
        ($FORM{IMPORT_TYPE} eq 'csv' || $FORM{IMPORT_TYPE} eq 'tab')) {
      $FORM{IMPORT_FIELDS}='DISTRICT,STREET,BUILD';
    }

    my $import_info = import_former( \%FORM );
    my $total = $#{ $import_info } + 1;

    my $streets_list = $Address->street_list({
      STREET_NAME   => '_SHOW',
      COLS_NAME     => 1,
      PAGE_ROWS     => 100000
    });

    # FIXME: re-review
    use utf8;

    my $districts_list = $Address->district_list({ COLS_NAME => 1, PAGE_ROWS => 1000 });
    my %district_list  = map { $_->{name} => $_->{id} } @{$districts_list};
    my %street_list    = map { $_->{street_name} => $_->{id} } @{$streets_list};

    foreach my $address_ (@$import_info) {
      address_create($address_, {
        DISTRICTS => \%district_list,
        STREETS   => \%street_list
      });
    }

    $html->message('info', $lang{INFO},
      "$lang{ADDED}\n $lang{FILE}: $FORM{UPLOAD_FILE}{filename}\n $lang{SIZE}: $FORM{UPLOAD_FILE}{Size}\n $lang{COUNT}: $total" );

    return 1;
  }

  $html->tpl_show(templates('form_import'), {
    IMPORT_ADDRESS => $FORM{IMPORT_ADDRESS},
    CALLBACK_FUNC  => 'form_districts',
  });

  return 1;
}

#**********************************************************
=head2 address_create($address_, $district, $street) - Create address and return location_id for address

  Arguments:
    $address_        - Address date add
      DISTRICT
        ZIP
        CITY
      STREET
      BUILD
        ADDRESS_COORDX
        ADDRESS_COORDY
    $attr
       DISTRICTS $districts_hash  - District, key-name, value-id district
       STREETS   $street_hash     - Street, key-name, value-id street

  Return:
    LOCATION_ID

=cut
#**********************************************************
sub address_create {
  my ($address_, $attr) = @_;

  my $district = $attr->{DISTRICTS};
  my $street = $attr->{STREETS};

  $address_->{DISTRICT} //= 'DEFAULT';

  if ($address_->{DISTRICT} && $address_->{STREET} && $address_->{BUILD}) {
    my $location_id = 0;

    my $builds_list = $Address->build_list({
      DISTRICT_NAME  => $address_->{DISTRICT},
      STREET_NAME    => $address_->{STREET},
      NUMBER         => $address_->{BUILD},
      COORDX         => '_SHOW',
      COORDY         => '_SHOW',
      COLS_NAME      => '_SHOW'
    });

    if ($Address->{TOTAL} || $Address->{TOTAL} == 1) {
      $location_id = $builds_list->[0]->{id} || 0;
      if ($address_->{ADDRESS_COORDX} && $address_->{ADDRESS_COORDY}
        && (
        ($address_->{ADDRESS_COORDX} ne $builds_list->[0]->{coordx})
          || ($address_->{ADDRESS_COORDY} ne $builds_list->[0]->{coordy})
      )
      ) {
        $Address->build_change({
          ID     => $location_id,
          COORDX => $address_->{ADDRESS_COORDX},
          COORDY => $address_->{ADDRESS_COORDY},
        });
      }

      return $location_id;
    }
  }

  if ($address_->{DISTRICT} && (! $district || !$district->{ $address_->{DISTRICT} })) {
    my $districts_id = address_district_add($address_->{DISTRICT}, $attr);
    $district->{$address_->{DISTRICT}}=$districts_id;
    my $street_id = address_street_add($address_->{STREET}, $districts_id, $attr);
    if ($street_id && $address_->{BUILD}) {
      return address_build_add($address_->{BUILD}, $street_id || $street->{ $address_->{STREET} });
    }
  }
  elsif ($address_->{STREET} && !$street->{ $address_->{STREET} }) {
    my $street_id = address_street_add($address_->{STREET}, $district->{ $address_->{DISTRICT} });
    address_build_add($address_->{BUILD}, $street_id || $street->{ $address_->{STREET} });
  }
  else {
    if ($address_->{STREET} && $address_->{BUILD}) {
      address_build_add($address_->{BUILD}, $street->{ $address_->{STREET} });
    }
  }

  return 1;
}

#**********************************************************
=head2 address_street_add($street_name, $district_id, $attr)

  Arguments:
    street_name     -
    district_id     -
    $attr - Extra attributes

  Return:
    $street_id

=cut
#**********************************************************
sub address_street_add {
  my ($street_name, $district_id, $attr) = @_;

  my $streets_list = $Address->street_list({
    %{ ($attr) ? $attr  : {} },
    STREET_NAME => $street_name,
    DISTRICT_ID => $district_id,
    COLS_NAME   => 1
  });

  my $street_id = 0;
  if($Address->{TOTAL}) {
    $street_id=$streets_list->[0]->{id};
  }
  else {
    $Address->street_add({
      NAME        => Encode::decode('UTF-8', $street_name),
      DISTRICT_ID => $district_id
    });

    if ($Address->{errno}) {
      print "ERROR: NAME => $street_name, DISTRICT_ID => $district_id\n";
    }
    else {
      $street_id = $Address->{STREET_ID};
    }
  }

  return $street_id;
}

#**********************************************************
=head2 address_build_add()

  Arguments:
    $number
    $street_id
    $attr

  Return:
    $location_id

=cut
#**********************************************************
sub address_build_add {
  my ($number, $street_id, $attr) = @_;

  my $location_id = 0;
  $Address->build_add({
    STREET_ID => $street_id,
    ADD_ADDRESS_BUILD => $number || $attr->{ADDRESS_BUILD},
    COORDX    => $attr->{ADDRESS_COORDX},
    COORDY    => $attr->{ADDRESS_COORDY},
    ZIP       => $attr->{ZIP},
    FLORS     => $attr->{ADDRESS_BUILD_FLORS},
    ENTRANCES => $attr->{ADDRESS_BUILD_ENTRANCES},
  });

  if ($Address->{errno}) {
    Encode::_utf8_off($attr->{ADDRESS_STREET});
    Encode::_utf8_off($attr->{ADDRESS_BUILD});
    print "ERROR: $street_id (". ($attr->{ADDRESS_STREET} || q{}) . ") ". ($attr->{ADDRESS_BUILD} || q{}) ."\n";
  }
  else {
    $location_id = $Address->{LOCATION_ID};
  }

  return $location_id;
}

#**********************************************************
=head2 address_district_add($district_name, $attr)

  Arguments:
    $district_name  -
    $attr

  Return:
    $district_id      - id district

=cut
#**********************************************************
sub address_district_add {
  my ($district_name, $attr) = @_;

  my $district_id = 1;

  my %district_params = ();
  $district_params{NAME} = $district_name || 'DEFAULT';

  my $districts_list = $Address->district_list({
    %district_params,
    COLS_NAME => 1
  });

  if ($Address->{TOTAL}) {
    $district_id = $districts_list->[0]->{id};
  }
  else {
    $Address->district_add({
      %{ ($attr) ? $attr : {} },
      NAME => Encode::decode('UTF-8', $district_name || 'DEFAULT')
    });

    $district_id = $Address->{DISTRICT_ID};
  }

  return $district_id;
}

#**********************************************************
=head2 geolocation_tree($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub geolocation_tree {
  my ($attr, $checked_list) = @_;

  my $builds = $attr->{BUILDS} && ref($attr->{BUILDS}) eq 'ARRAY' ? $attr->{BUILDS} : $Address->build_list({
    ID                => '_SHOW',
    STREET_NAME       => '_SHOW',
    DISTRICT_NAME     => '_SHOW',
    DISTRICT_ID       => '_SHOW',
    NUMBER            => '_SHOW',
    CITY              => '_SHOW',
    COLS_NAME         => 1,
    WITH_STREETS_ONLY => 1,
    SORT              => 'district_name,street_name,number+0',
    PAGE_ROWS         => 999999
  });

  my %address = ();
  foreach (@{$checked_list}) {
    if ($_->{city_id}) {
      $address{"CITY_ID_$_->{city_id}"} = 1;
    }
    elsif ($_->{street_id}) {
      $address{"STREET_ID_$_->{street_id}"} = 1;
    }
    elsif ($_->{build_id}) {
      $address{"BUILD_ID_$_->{build_id}"} = 1;
    }
    elsif ($_->{district_id}) {
      $address{"DISTRICT_ID_$_->{district_id}"} = 1;
    }
  }

  my $street_index = get_function_index('form_streets');
  my $keys = ($attr->{CITY_BRANCH} ? 'city_check,' : '') . "district_name_check,street_name_check,number_check";

  foreach my $build (@{$builds}) {
    my $build_input = $attr->{SKIP_INPUT} ? '' : $html->form_input("BUILD_ID", $build->{id}, {
      TYPE      => 'checkbox',
      class     => 'tree_box',
      EX_PARAMS => "data-parent-id='STREET_$build->{street_id}' ". ($address{"BUILD_ID_$build->{id}"} ? 'checked' : ''),
      ID        => 'BUILD_' . $build->{id}
    });
    $build->{number} = $html->button($build->{number} || '', "index=$street_index&BUILDS=$build->{street_id}&chg=$build->{id}",
      { target => '_blank', class => 'text-info' }) if $attr->{HREF_TO_ADDRESS};
    $build->{number_check} = $html->element('label', ($build_input || q{}) . ' ' . ($build->{number} || q{}));

    my $street_input = $attr->{SKIP_INPUT} ? '' : $html->form_input("STREET_ID", $build->{street_id}, {
      TYPE      => 'checkbox',
      class     => 'tree_box',
      EX_PARAMS => "data-parent-id='DISTRICT_$build->{district_id}' " . ($address{"STREET_ID_$build->{street_id}"} ? 'checked' : ''),
      ID        => 'STREET_' . $build->{street_id}
    });
    $build->{street_name} = $html->button($build->{street_name} || '',
      "index=$street_index&BUILDS=$build->{street_id}", { target => '_blank', class => 'text-info' }) if $attr->{HREF_TO_ADDRESS};
    $build->{street_name_check} = $html->element('label', ($street_input || q{}) . ' ' . ($build->{street_name} || q{}));

    my $district_input = $attr->{SKIP_INPUT} ? '' : $html->form_input("DISTRICT_ID", $build->{district_id}, {
      TYPE      => 'checkbox',
      class     => 'tree_box',
      EX_PARAMS => ($build->{city} ? "data-parent-id='CITY_$build->{city}' " : '') .
        ($address{"DISTRICT_ID_$build->{district_id}"} ? 'checked' : ''),
      ID        => 'DISTRICT_' . $build->{district_id}
    });
    $build->{district_name} = $html->button($build->{district_name} || '',
      "index=$street_index&DISTRICT_ID=$build->{district_id}", { target => '_blank', class => 'text-info' }) if $attr->{HREF_TO_ADDRESS};
    $build->{district_name_check} = $html->element('label', ($district_input || q{}) . ' ' . ($build->{district_name} || q{}));

    next if !$build->{city} || !$attr->{CITY_BRANCH};
    my $city_input = $attr->{SKIP_INPUT} ? '' : $html->form_input("CITY_ID", $build->{city}, {
      TYPE      => 'checkbox',
      class     => 'tree_box',
      EX_PARAMS => $address{"CITY_ID_$build->{city}"} ? 'checked' : '',
      ID        => 'CITY_' . $build->{city}
    });
    $build->{city_check} = $html->element('label', ($city_input || q{}) . ' ' . ($build->{city} || q{}));
  }

  my $geolocation_tree = $html->html_tree($builds, $keys);
  return $geolocation_tree if $attr->{RETURN_TREE};

  return $html->tpl_show(templates('form_geolocation_tree'), {
    GEOLOCATION_TREE => $geolocation_tree,
    TITLE            => $attr->{TITLE},
    index            => $attr->{INDEX},
    BTN_LNG          => $attr->{BTN_LNG},
    BTN_ACTION       => $attr->{BTN_ACTION},
    HIDDEN_INPUTS    => $attr->{HIDDEN_INPUTS}
  }, { OUTPUT2RETURN => 1 });
}

#**********************************************************
=head2 form_address_types()

=cut
#**********************************************************
sub form_address_types {

  $Address->{ACTION} = 'add';
  $Address->{LNG_ACTION} = $lang{ADD};

  if ($FORM{add}) {
    $Address->address_type_add({ %FORM });
    $html->message('info', $lang{ADDED}, $lang{ADDED}) if !$Address->{errno};
  }
  elsif ($FORM{change}) {
    $Address->address_type_change(\%FORM);
    $html->message('info', $lang{CHANGED}, $lang{CHANGED}) if !$Address->{errno};
  }
  elsif ($FORM{chg}) {
    $Address->address_type_info({ ID => $FORM{chg} });

    if (!$Address->{errno}) {
      $Address->{ACTION} = 'change';
      $Address->{LNG_ACTION} = $lang{CHANGE};
      $FORM{add_form} = 1;
    }
  }
  elsif ($FORM{del} && $FORM{COMMENTS}) {
    $Address->address_type_del($FORM{del});
    $html->message('info', $lang{DELETED}, $lang{DELETED}) if !$Address->{errno};
  }
  _error_show($Address);

  my AXbills::HTML $table;
  ($table) = result_former({
    INPUT_DATA      => $Address,
    FUNCTION        => 'address_type_list',
    BASE_FIELDS     => 0,
    DEFAULT_FIELDS  => 'ID,NAME,POSITION',
    FUNCTION_FIELDS => 'change,del',
    SKIP_USER_TITLE => 1,
    FILTER_COLS     => { name => '_translate' },
    EXT_TITLES      => {
      id       => '#',
      name     => $lang{NAME},
      position => $lang{ADDRESS_POSITION}
    },
    TABLE           => {
      caption => $lang{ADDRESS_UNIT_TYPES},
      qs      => $pages_qs,
      ID      => 'ADDRESS_TYPES_LIST',
      EXPORT  => 1,
      MENU    => "$lang{ADD}:index=$index&add_form=1:add"
    },
    MAKE_ROWS       => 1,
  });

  if ($FORM{add_form}) {
    $Address->{POSITION} = $Address->{TOTAL} + 1 if !$FORM{chg};
    $html->tpl_show(templates('form_address_type'), $Address);
  }

  print $table->show();

  return 1;
}

#**********************************************************
=head2 form_building_types()

=cut
#**********************************************************
sub form_building_types {

  $Address->{ACTION} = 'add';
  $Address->{LNG_ACTION} = $lang{ADD};

  if ($FORM{add}) {
    $Address->building_type_add({ %FORM });
    $html->message('info', $lang{ADDED}, $lang{ADDED}) if !$Address->{errno};
  }
  elsif ($FORM{change}) {
    $Address->building_type_change(\%FORM);
    $html->message('info', $lang{CHANGED}, $lang{CHANGED}) if !$Address->{errno};
  }
  elsif ($FORM{chg}) {
    $Address->building_type_info({ ID => $FORM{chg} });

    if (!$Address->{errno}) {
      $Address->{ACTION} = 'change';
      $Address->{LNG_ACTION} = $lang{CHANGE};
      $FORM{add_form} = 1;
    }
  }
  elsif ($FORM{del} && $FORM{COMMENTS}) {
    $Address->building_type_del($FORM{del});
    $html->message('info', $lang{DELETED}, $lang{DELETED}) if !$Address->{errno};
  }
  _error_show($Address);

  $html->tpl_show(templates('form_building_type'), $Address) if ($FORM{add_form});

  result_former({
    INPUT_DATA      => $Address,
    FUNCTION        => 'building_type_list',
    BASE_FIELDS     => 0,
    DEFAULT_FIELDS  => 'ID,NAME',
    FUNCTION_FIELDS => 'change,del',
    SKIP_USER_TITLE => 1,
    EXT_TITLES      => {
      id       => '#',
      name     => $lang{NAME}
    },
    TABLE           => {
      caption => $lang{BUILDING_TYPES},
      qs      => $pages_qs,
      ID      => 'BUILDING_TYPE_LIST',
      EXPORT  => 1,
      MENU    => "$lang{ADD}:index=$index&add_form=1:add"
    },
    MAKE_ROWS       => 1,
    TOTAL           => 1
  });

  return 1;
}

1;
