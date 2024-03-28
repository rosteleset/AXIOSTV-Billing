=head1 NAME

  Result former

=cut

use strict;
use warnings FATAL => 'all';
use AXbills::Base qw(in_array);

our AXbills::HTML $html;
our (
  %lang,
  $admin,
  %permissions,
  %DATA_HASH,
  %FORM,
  %LIST_PARAMS,
  $index,
  @MODULES,
  %conf,
  %CHARTS,
  $SELF_URL
);

#**********************************************************
=head2 result_row_former($attr); - forming result from array_hash

  Arguments:
    $attr
      table - table object
      ROWS  - array_array
      ROW_COLORS - ref Array color. use bootstrap's table contextual classes (table-success, table-danger etc)
      EXTRA_HTML_INFO - Add extra HTML information

  Examples:

=cut
#**********************************************************
sub result_row_former {
  my ($attr) = @_;

  #Array result former
  my %PRE_SORT_HASH = ();

  my $main_arr = $attr->{ROWS};
  my $ROW_COLORS = $attr->{ROW_COLORS};
  my $sort = $FORM{sort} || 1;

  for (my $i = 0; $i <= $#{$main_arr}; $i++) {
    $PRE_SORT_HASH{$i} = $main_arr->[$i]->[$sort - 1];
  }

  my @sorted_ids = sort {
    if ($FORM{desc}) {
      length($PRE_SORT_HASH{$b}) <=> length($PRE_SORT_HASH{$a})
        || $PRE_SORT_HASH{$b} cmp $PRE_SORT_HASH{$a};
    }
    else {
      length($PRE_SORT_HASH{$a} || 0) <=> length($PRE_SORT_HASH{$b} || 0)
        || ($PRE_SORT_HASH{$a} || q{}) cmp ($PRE_SORT_HASH{$b} || q{});
    }
  } keys %PRE_SORT_HASH;

  my AXbills::HTML $table2 = $attr->{table};
  foreach my $line (@sorted_ids) {
    if ($ROW_COLORS) {
      $table2->{rowcolor} = ($ROW_COLORS->[$line]) ? $ROW_COLORS->[$line] : undef;
    }

    $table2->addrow(@{$main_arr->[$line]},);
  }

  if ($attr->{TOTAL_SHOW}) {
    print $table2->show();

    my $table = $html->table({
      width => '100%',
      rows  => [ [ "$lang{TOTAL}:", $#{$main_arr} + 1 ] ]
    });

    print $table->show();
    print $attr->{EXTRA_HTML_INFO} if ($attr->{EXTRA_HTML_INFO} && $table->{HTML}); #XXX JSON somewhy have ->{HTML}, so we write EXTRA_HTML_INFO before JSON, resulting in broken JSON. XML also somewhy have ->{HTML}
    return '';
  }

  return ($table2) ? $table2->show() : q{};
}

#**********************************************************
=head2 result_former($attr) - Make result table from different source

  Arguments:
    $attr
      DEFAULT_FIELDS  - Default fields
      HIDDEN_FIELDS   - Requested but not showed in HTML table ('FIELD1,FIELD2')
      INPUT_DATA      - DB object
      FUNCTION        - object list function name
      FUNCTION_PARAMS - params of function (hash)
      LIST            - get input data from list (array_hash)
      BASE_FIELDS     - count of default field for list ( Show first %BASE_FIELDS% $search_columns fields )
      APPEND_FIELDS   - Additional fields to extract from the sheet

      DATAHASH        - get input data from json parsed hash
      BASE_PREFIX     - Base prefix for data hash

      FUNCTION_FIELDS - function field forming
        change  - change field
        payment - payment field
        status  - status field
        del     - del field

        custon_field:
          functiom_name:name:param:ex_param

      STATUS_VALS - Value for status fields (status,disable)
      EXT_TITLES  - Translations for table header ( Necessary for column selection modal window)
        [ object_name => 'translation' ]
      SKIP_USER_TITLE - don\'t show user titles in gum menu

      MAKE_ROWS   - Show result table
      MODULE      - Module name for user link
      FILTER_COLS - Use function filter for field
        filter_function:params:params:...
      FILTER_VALUES - Implements FILTER_COLS with coderefs
      SELECT_VALUE- Select value for field
      MULTISELECT - multiselect column ( Will add checkbox for every row string 'id:line_key_for_value_name:form_id' )
        [ id => value ]

      SKIP_PAGES  - Not show table pages
      TABLE       - Table information (HASH)
        caption
        cols_align
        qs
        pages
        ID
        EXPORT
        MENU
      TOTAL         - Show table with totals
                      Multi total
                      $val_id:$name;$val_id:$name
      SHOW_MORE_THEN- Show table when rows more then SHOW_MORE_THEN

      MAP         - Make map tab
      MAP_FIELDS  - Map fields
      MAP_ICON    - Icons for map points
      MAP_SHOW_ITEMS - To show necessary items on map
        LINK_ITEMS - Link in item.
          index - index of funtion to go
          LINK_ITEM - link item (Ex. fio)
          EXTRA_PARAMS - extra params of link (Ex. &add_func=1)
        DEFAULT_VALUE - defalut value if value eq ''
          EX. subject => $lang{NO_SUBJECT}

      CHARTS      - Make charts. Coma separated column names to make chart from
      CHARTS_XTEXT- Charts x axis text
      OUTPUT2RETURN - Output to return

  Returns:
    ($table, $list)
    $table   - Table object
    $list    - result array list

  Examples:
    http://axbills.net.ua/wiki/doku.php/axbills:docs:development:modules:ru#result_former

=cut
#**********************************************************
sub result_former {
  my ($attr) = @_;

  my @cols = ();
  my @title = ();
  my @service_status_colors = ("#000000", "#FF0000", '#808080', '#0000FF', '#FF8000', '#009999');
  my @service_status = ($lang{ENABLE}, $lang{DISABLE}, $lang{NOT_ACTIVE}, $lang{HOLD_UP},
    "$lang{DISABLE}: $lang{NON_PAYMENT}", $lang{ERR_SMALL_DEPOSIT},
    $lang{VIRUS_ALERT});

  my $sort = $FORM{sort};

  $admin->settings_info($attr->{TABLE}->{ID});

  @service_status = @{$attr->{STATUS_VALS}} if ($attr->{STATUS_VALS} && ref $attr->{STATUS_VALS} eq "ARRAY");

  if ($FORM{MAP}) {
    if ($attr->{MAP_FIELDS}) {
      $attr->{DEFAULT_FIELDS} = $attr->{MAP_FIELDS};
    }
    $LIST_PARAMS{'LOCATION_ID'} = '_SHOW';
  }

  if ($attr->{HTML}) {
    $html = $attr->{HTML};
    if (!$index) {
      $index = $html->{index};
      $attr->{FUNCTION_INDEX} = $index;
    }
  }

  @cols = _result_former_columns($attr);
  # _info_fields_hide();

  _sort_table($attr->{TABLE}->{ID}, $sort, \@cols);


  my @hidden_fields = _result_former_hidden_fields($attr, \@cols);

  _result_former_append_fields($attr, \@cols);

  my $data = _result_former_data($attr, \@hidden_fields);
  return if ($data && $data->{error});

  #Make maps
  return -1, -1 if _result_former_map($attr, $data);

  my %SEARCH_TITLES = _get_search_titles($attr, $data);

  my $base_fields = $attr->{BASE_FIELDS} || 0;

  my @EX_TITLE_ARR = ();
  @EX_TITLE_ARR = @{$data->{COL_NAMES_ARR}} if ($data->{COL_NAMES_ARR} && ref $data->{COL_NAMES_ARR} eq 'ARRAY');

  if ($FORM{json}) {
    push @EX_TITLE_ARR, @hidden_fields;
    $data->{SEARCH_FIELDS_COUNT} += $#hidden_fields + 1;
  }

  my $search_fields_count = $data->{SEARCH_FIELDS_COUNT} || 0;
  my %ACTIVE_TITLES = ();

  for (my $i = 0; $i < $base_fields + $search_fields_count; $i++) {
    next if ($EX_TITLE_ARR[$i] && !$FORM{json} && in_array(uc($EX_TITLE_ARR[$i]), \@hidden_fields));

    push @title, ($EX_TITLE_ARR[$i] && $SEARCH_TITLES{ $EX_TITLE_ARR[$i] }) ||
      ($cols[$i] && $SEARCH_TITLES{$cols[$i]}) || $EX_TITLE_ARR[$i] || $cols[$i] || "$lang{SEARCH}";

    $ACTIVE_TITLES{($EX_TITLE_ARR[$i] || '')} = ($EX_TITLE_ARR[$i] && $FORM{uc($EX_TITLE_ARR[$i])}) || '_SHOW';
  }

  #data hash result former
  if (ref $attr->{DATAHASH} eq 'ARRAY') {
    @title = sort keys %{$attr->{DATAHASH}->[0]};

    if ($#hidden_fields) {
      my @title_ = grep { my $t = $_; !grep {$_ eq $t} @hidden_fields; } @title;
      @title = @title_;
    }

    $data->{COL_NAMES_ARR} = \@title;
    @EX_TITLE_ARR = @title;
  }
  elsif (!$data->{COL_NAMES_ARR}) {
    @cols = (split(/,/, $attr->{BASE_PREFIX}), @cols) if ($attr->{BASE_PREFIX});

    my $i = 0;
    for ($i = 0; $i <= $#cols + $base_fields; $i++) {
      next if ($cols[$i] && !$FORM{json} && in_array(uc($cols[$i]), \@hidden_fields));

      if ($cols[$i]) {
        $title[$i] = $SEARCH_TITLES{lc($cols[$i])} || $attr->{TABLE}->{SHOW_COLS}->{$cols[$i]} || $cols[$i] || '44';
        $ACTIVE_TITLES{$cols[$i]} = $cols[$i];
      }
    }

    if ($#cols > -1) {
      if ($cols[$i]) {
        $title[$i] = $cols[$i] || q{22};
        $ACTIVE_TITLES{$cols[$i]} = $cols[$i];
      }
    }

    $data->{COL_NAMES_ARR} = \@cols if (!$data->{COL_NAMES_ARR});
  }

  my @function_fields = split(/,\s?/, $attr->{FUNCTION_FIELDS} || '');

  $title[$#title + 1] = '' if ($#function_fields > -1);

  return \@title unless $attr->{TABLE};

  my $title_type = $attr->{TABLE}->{title_plain} ? 'title_plain' : 'title';
  $attr->{SKIP_PAGES} = 1 if ($attr->{TABLE}{DATA_TABLE} && !defined($attr->{TABLE}{SKIP_PAGES}));

  my ($multisel_id, $multisel_value, $multisel_form, $obj_info);
  my @multiselect_arr = ();
  if ($attr->{MULTISELECT}) {
    ($multisel_id, $multisel_value, $multisel_form, $obj_info) = split(/:/, $attr->{MULTISELECT});

    @multiselect_arr = split(/,\s?|;\s?/, $FORM{$multisel_id}) if ($FORM{$multisel_id});

    # First and last values are simply ignored
    $attr->{TABLE}{SELECT_ALL} //= ($multisel_form || q{}) . ":" . ($multisel_id || q{}) . ":" . ($obj_info || q{});
    $attr->{TABLE}{SHOW_MULTISELECT_ACTIONS} = scalar(@multiselect_arr);
  }

  unless ($AXbills::HTML::VERSION) {
    require AXbills::HTML;
    AXbills::HTML->import();
  }

  if ($attr->{TABLE}{DATA_TABLE} && $LIST_PARAMS{SORT}) {
    $attr->{TABLE}{DATA_TABLE} = {} if ref $attr->{TABLE}{DATA_TABLE} ne 'HASH';

    $attr->{TABLE}{DATA_TABLE}{order} = [ [ $LIST_PARAMS{SORT} - 1, lc($LIST_PARAMS{DESC}) || 'asc' ] ];
  }

  my AXbills::HTML $table = $html->table({
    SHOW_COLS           => ($attr->{TABLE}{SHOW_COLS}) ? $attr->{TABLE}{SHOW_COLS} : \%SEARCH_TITLES,
    %{$attr->{TABLE}},
    $title_type         => \@title,
    border              => 1,
    pages               => (!$attr->{SKIP_PAGES}) ? $data->{TOTAL} : undef,
    FIELDS_IDS          => $data->{COL_NAMES_ARR},
    HAS_FUNCTION_FIELDS => (defined $attr->{FUNCTION_FIELDS} && $attr->{FUNCTION_FIELDS}) ? 1 : 0,
    ACTIVE_COLS         => \%ACTIVE_TITLES,
  });

  $table->{COL_NAMES_ARR} = $data->{COL_NAMES_ARR};
  $table->{HIDDEN_FIELD_COUNT} = $#hidden_fields + 1;

  if ($attr->{MAKE_ROWS} && $data->{list}) {
    return $table if !_result_former_make_rows({ %{$attr}, EXT_ATTR => {
      SEARCH_FIELDS_COUNT   => $search_fields_count,
      BASE_FIELDS           => $base_fields,
      HIDDEN_FIELDS         => \@hidden_fields,
      SERVICE_STATUS        => \@service_status,
      SERVICE_STATUS_COLORS => \@service_status_colors,
      MULTISEL_ID           => $multisel_id,
      MULTISEL_VALUE        => $multisel_value,
      MULTISELECT_ARR       => \@multiselect_arr,
      MULTISEL_FORM         => $multisel_form,
      FUNCTION_FIELDS       => \@function_fields
    } }, $data, $table);
  }
  elsif ($attr->{DATAHASH} && ref $attr->{DATAHASH} eq 'ARRAY') {
    $data->{TOTAL} = 0;
    $table->{sub_ref} = 1;

    $attr->{EX_TITLE_ARR} = \@EX_TITLE_ARR;
    $attr->{FUNCTION_FIELDS} = \@function_fields;

    my $rows = _datahash2table($attr);
    foreach my $row (@$rows) {
      $table->addrow(@$row);
      $data->{TOTAL}++;
    }
  }

  my $result = _result_former_get_total_table($attr, $data, $table);

  return($table, $data->{list}) if (!$result);

  return $result, $data->{list} if ($attr->{OUTPUT2RETURN});

  print $result || q{} if (!$attr->{SEARCH_FORMER} || (defined($data->{TOTAL}) && $data->{TOTAL} > -1));

  return($table, $data->{list});
}

#**********************************************************
=head2 _datahash2table($attr) - Datahash to table

  Arguments:
    $attr
      EX_TITLE_ARR
      FUNCTION_FIELDS
      DATAHASH
      SELECT_VALUE
      FILTER_COLS

  Results:
    \@rows

=cut
#**********************************************************
sub _datahash2table {
  my ($attr) = @_;

  my @rows = ();
  my $EX_TITLE_ARR = $attr->{EX_TITLE_ARR};
  my $function_fields = $attr->{FUNCTION_FIELDS};
  my %PRE_SORT_HASH = ();
  my $sort = $FORM{sort} || 1;

  for (my $i = 0; $i <= $#{$attr->{DATAHASH}}; $i++) {
    $PRE_SORT_HASH{$i} = $attr->{DATAHASH}->[$i]->{ $EX_TITLE_ARR->[$sort - 1] || q{} } //= q{};
  }

  my @sorted_ids = sort {
    if ($FORM{desc}) {
      length($PRE_SORT_HASH{$b}) <=> length($PRE_SORT_HASH{$a})
        || $PRE_SORT_HASH{$b} cmp $PRE_SORT_HASH{$a};
    }
    else {
      length($PRE_SORT_HASH{$a}) <=> length($PRE_SORT_HASH{$b})
        || $PRE_SORT_HASH{$a} cmp $PRE_SORT_HASH{$b};
    }
  } keys %PRE_SORT_HASH;

  foreach my $row_num (@sorted_ids) {
    my @row = ();
    my $line = $attr->{DATAHASH}->[$row_num];

    for (my $i = 0; $i <= $#{$EX_TITLE_ARR}; $i++) {
      my $field_name = $EX_TITLE_ARR->[$i];
      my $col_data = $line->{$field_name};

      if ($attr->{FILTER_COLS} && $attr->{FILTER_COLS}->{$field_name}) {
        my ($filter_fn, @arr) = split(/:/, $attr->{FILTER_COLS}->{$field_name});
        Encode::_utf8_off($col_data);
        push @row, &{\&$filter_fn}($col_data, { PARAMS => \@arr });
      }
      elsif ($attr->{SELECT_VALUE} && $attr->{SELECT_VALUE}->{$field_name}) {
        if ($col_data && $attr->{SELECT_VALUE}->{$field_name}->{$col_data}) {
          my ($value, $color) = split(/:/, $attr->{SELECT_VALUE}->{$field_name}->{$col_data});
          push @row, ($color) ? $html->color_mark($value, $color) : $value;
        }
        else {
          Encode::_utf8_off($col_data);
          push @row, $col_data;
        }
      }
      else {
        push @row, _hash2html($col_data, $attr);
      }
    }

    push @row, @{table_function_fields($function_fields, $line, $attr)} if ($#{$function_fields} > -1);
    push @rows, \@row;
  }

  return \@rows;
}

#**********************************************************
=head2 search_link($val, $attr); - forming search link

  Arguments:
    $val  - Function name
    $attr -
      PARAMS
      VALUES
      LINK_NAME

  Returns:
    Link

=cut
#**********************************************************
sub search_link {
  my ($val, $attr) = @_;

  my $params = $attr->{PARAMS};
  my $ext_link = '';
  if ($attr->{VALUES}) {
    foreach my $k (keys %{$attr->{VALUES}}) {
      $ext_link .= "&$k=$attr->{VALUES}->{$k}";
    }
  }
  else {
    $ext_link .= '&' . "$params->[1]=" . $val;
  }

  my $result = $html->button($attr->{LINK_NAME} || $val, "index=" . get_function_index($params->[0]) . "&search_form=1&search=1" . $ext_link);

  return $result;
}

#**********************************************************
=head2 _hash2html($col_data) - JSON TO HTML formater;

  Arguments:
    $col_data - Hash variable content
    $attr
      SKIPP_UTF_OFF

  Results:
    $html_value

=cut
#**********************************************************
sub _hash2html {
  my ($col_data, $attr) = @_;

  my $result = '';

  if (ref $col_data eq 'ARRAY') {
    foreach my $key (@$col_data) {
      $result .= _hash2html($key, $attr) . $html->br();
    }
  }
  elsif (ref $col_data eq 'HASH') {
    my $val = '';
    foreach my $key (sort keys %{$col_data}) {
      $val .= $html->b($key) . ' : ' . _hash2html($col_data->{$key}, $attr) . $html->br();
    }

    $result = $val;
  }
  else {
    Encode::_utf8_off($col_data) if (!$attr->{SKIPP_UTF_OFF});
    $result = $col_data //= q{};
  }

  return $result;
}

#**********************************************************
=head2 table_function_fields($function_fields, $line, $attr) - Make function fields

  Attributes:
    $function_fields - Function fields name (array_ref)
      Each array element may be one of following:
        form_payments
        change
        cpmpany_id
        ex_info - if module Info is enabled
        print_in_new_tab
        del
      Or
        =~ /stats/
      Or
        In format "function_name:name:param:ex_param", where
          #XXX documentation
          function_name
          name
          param
          ex_param - optional
      Or
        In format "FUNCTION_NAME=function_name" - Will run function_name($line) for each line. Its result will be put to function fields as is

    $line            - array_ref of list result
    $attr            - Extra attributes
      TABLE          - Table object hash_ref
      MODULE         - Module name
      FUNCTION_INDEX -

  Result:
    Arrya_ref of cols

=cut
#**********************************************************
sub table_function_fields {
  my ($function_fields, $line, $attr) = @_;

  my @fields_array = ();
  my $query_string = ($attr->{TABLE} && $attr->{TABLE}{qs}) ? $attr->{TABLE}{qs} : q{};

  if ($line->{uid} && $query_string !~ /UID=/) {
    $query_string .= "&UID=$line->{uid}";
    $index = $attr->{FUNCTION_INDEX} || 15;
  }

  if (in_array('company_id', $function_fields)){
    $index = $attr->{FUNCTION_INDEX} || 13;
  }

  for (my $i = 0; $i <= $#{$function_fields}; $i++) {
    if ($function_fields->[$i] eq 'form_payments') {
      next if (!$line->{uid});
      push @fields_array, ($permissions{1}) ? $html->button($function_fields->[$i], "UID=$line->{uid}&index=2", { class => 'payments' }) : '-';
    }
    elsif ($function_fields->[$i] =~ /stats/) {
      push @fields_array, $html->button($function_fields->[$i],
        "&index=" . get_function_index($function_fields->[$i]) . $query_string, { class => 'stats' });
    }
    elsif ($function_fields->[$i] eq 'change') {
      push @fields_array, $html->button($lang{CHANGE}, "index=$index&chg=" . ($line->{id} || 0)
        . (($attr->{MODULE}) ? "&MODULE=$attr->{MODULE}" : '')
        . $query_string, { class => 'change' });
    }
    elsif ($function_fields->[$i] eq 'info') {
      push @fields_array, $html->button($lang{INFO}, "index=$index&info=" . ($line->{id} || q{})
        . (($attr->{MODULE}) ? "&MODULE=$attr->{MODULE}" : '')
        . $query_string, { class => 'info' });
    }
    elsif ($function_fields->[$i] eq 'company_id') {
      push @fields_array,
        $html->button($lang{CHANGE}, "index=$index&COMPANY_ID=$line->{id}"
          . ($attr->{MODULE} ? "&MODULE=$attr->{MODULE}" : '')
          . $query_string, { class => 'change' });
    }
    elsif (in_array('Info', \@MODULES) && $function_fields->[$i] eq 'ex_info') {
      $html->button($lang{CHANGE}, "index=$index&COMPANY_ID=$line->{id}"
        . ($attr->{MODULE} ? "&MODULE=$attr->{MODULE}" : '')
        . $query_string, { class => 'change' });
    }
    elsif ($function_fields->[$i] eq 'print_in_new_tab') {
      push @fields_array,
        $html->button($lang{PRINT}, "#",
          {
            NEW_WINDOW      => "$SELF_URL?qindex=$index&print=$line->{id}",
            NEW_WINDOW_SIZE => "640:750",
            class           => 'print'
          });
    }
    elsif ($function_fields->[$i] eq 'del') {
      my $two_confirmation = '';

      if ($conf{TWO_CONFIRMATION}) {
        $two_confirmation = $lang{DEL};
      }

      push @fields_array,
        $html->button($lang{DEL}, "&index=$index&del="
          . (($line->{id}) ? $line->{id} : '')
          . ($attr->{MODULE} ? "&MODULE=$attr->{MODULE}" : '')
          . $query_string, {
            class             => 'del',
            MESSAGE           => "$lang{DEL} " . ($line->{name} || $line->{id} || q{-}) . "?",
            TWO_CONFIRMATION  => $two_confirmation
          }
        );
    }
    else {
      my $qs = '';
      my $functiom_name = $function_fields->[$i];
      my $button_name = $function_fields->[$i];
      my $param = '';
      my $ex_param = '';

      my %button_params = ();

      # 0-0 in first capture group
      if ($function_fields->[$i] =~ /([a-z0-0\_\-]{0,25}):([a-zA-Z\_0-9\{\}\$]+):([a-z0-9\-\_\;]+):?(\S{0,100})/) {
        $functiom_name = $1;
        my $name = $2;
        $param = $3;
        $ex_param = $4;

        if ($name eq 'del') {
          $button_params{class} = 'del';
          $button_params{TITLE} = "$lang{DEL}";
          $button_params{MESSAGE} = "$lang{DEL} " . ($line->{name} || $line->{id} || q{-}) . "?";

          if ($conf{TWO_CONFIRMATION}) {
            $button_params{TWO_CONFIRMATION} = $lang{DEL};
          }
        }
        elsif ($name eq 'change') {
          $button_params{class} = 'change';
        }
        elsif ($name eq 'show') {
          $button_params{class} = 'show';
          $button_params{TITLE} = "$lang{SHOW}";
          $button_name = '';
        }
        elsif ($name eq 'add') {
          $button_params{class} = 'add';
        }
        else {
          $button_params{BUTTON} = 1;
          $button_name = _translate($name);
        }

        $qs .= 'index=' . (($functiom_name) ? get_function_index($functiom_name) : $index);
        $qs .= $ex_param;
      }
      elsif ($function_fields->[$i] =~ /^FUNCTION_NAME=([a-z0-9\_\-]+)$/) {
        my $function = $1;

        if (defined(&{$function})) {
          push @fields_array, &{\&$function}($line);
        }

        next;
      }
      else {
        $qs = "index=" . get_function_index($functiom_name);
      }

      if ($param) {
        foreach my $l (split(/;/, $param)) {
          if ($line->{$l}) {
            #Fixme Uncoment for omega
            my $is_utf = Encode::is_utf8($line->{$l});
            if (!$is_utf) {
              Encode::_utf8_off($line->{$l});
            }

            $qs .= '&' . uc($l) . "=$line->{$l}";
          }
        }
      }
      elsif ($line->{uid}) {
        $qs .= "&UID=$line->{uid}";
      }

      push @fields_array, $html->button($button_name, $qs, \%button_params);
    }
  }

  return \@fields_array;
}

#**********************************************************
=head2 _result_former_maps_show($list, $attr)

  Attributes:

  Result:

=cut
#**********************************************************
sub _result_former_maps_show {
  my ($list, $attr) = @_;

  load_module('Maps', $html);

  $list = [] if (ref($list) ne "ARRAY");
  my $date_list;

  foreach my $object (@{$list}) {
    $object->{location_id} ||= $object->{build_id};
    next unless $object->{location_id};
    delete $object->{message} if $object->{message};
    if ($date_list->{$object->{location_id}}){
      push @{$date_list->{$object->{location_id}}}, $object;
      next;
    }
    push @{$date_list->{$object->{location_id}}}, $object;
  }

  print maps_show_map({
    DATA           => $date_list || {},
    QUICK          => 1,
    MAP_SHOW_ITEMS => $attr->{MAP_SHOW_ITEMS},
    MAP_TYPE_ICON  => $attr->{MAP_TYPE_ICON},
    MAP_FILTERS    => $attr->{MAP_FILTERS},
    MAP_FIELDS     => $attr->{MAP_FIELDS},
    MAP_ICON       => $attr->{MAP_ICON},
    FULL_TYPE_URL  => $attr->{MAP_FULL_TYPE_URL}
  });

  return 1;
}

#**********************************************************
=head2 _result_former_columns($attr)

  Arguments:
    $attr
      DEFAULT_FIELDS

  Return:
    @cols

=cut
#**********************************************************
sub _result_former_columns {
  my ($attr) = @_;

  my @cols = ();

  if ($FORM{del_cols}) {
    $admin->settings_del($attr->{TABLE}->{ID});
    if ($attr->{DEFAULT_FIELDS}) {
      $attr->{DEFAULT_FIELDS} =~ s/[\n ]+//g;
      @cols = split(/,/, $attr->{DEFAULT_FIELDS});
    }
  }
  elsif ($FORM{show_columns}) {
    @cols = split(/,\s?/, $FORM{show_columns});
    if ($FORM{show_cols}) {
      $admin->settings_add({
        SETTING    => $FORM{show_columns},
        OBJECT     => $attr->{TABLE}->{ID},
        SORT_TABLE => "1|"
      });
    }
  }
  else {
    if (ref $admin eq 'Admins' && $admin->can('settings_info')) {
      if ($admin->{TOTAL} == 0 && $attr->{DEFAULT_FIELDS}) {
        $attr->{DEFAULT_FIELDS} =~ s/[\n ]+//g;
        @cols = split(/,/, $attr->{DEFAULT_FIELDS});
      }
      else {
        if ($admin->{SETTING}) {
          @cols = split(/, /, $admin->{SETTING});
        }
      }
    }
    elsif ($attr->{DEFAULT_FIELDS}) {
      $attr->{DEFAULT_FIELDS} =~ s/[\n ]+//g;
      @cols = split(/,/, $attr->{DEFAULT_FIELDS});
    }
  }

  return @cols;
}

#**********************************************************
=head2 _result_former_hidden_fields($attr)

  Arguments:
    $attr

  Return:

=cut
#**********************************************************
sub _result_former_hidden_fields {
  my ($attr, $cols) = @_;

  my @hidden_fields = ();

  if ($attr->{HIDDEN_FIELDS}) {
    @hidden_fields = split(/,/, $attr->{HIDDEN_FIELDS});
    for (my $i = 0; $i <= $#hidden_fields; $i++) {
      my $fld = $hidden_fields[$i];
      if (!in_array($fld, $cols)) {
        push @{$cols}, $fld;
      }
      else {
        delete $hidden_fields[$i];
      }
    }
  }

  foreach my $line (@{$cols}) {
    if (!defined($LIST_PARAMS{$line}) || $LIST_PARAMS{$line} eq '') {
      $LIST_PARAMS{$line} = '_SHOW';
    }
  }

  _column_no_permitss();

  return @hidden_fields;
}

#**********************************************************
=head2 _result_former_append_fields($attr, $cols)

  Arguments:

  Return:

=cut
#**********************************************************
sub _result_former_append_fields {
  my ($attr, $cols) = @_;

  return 0 unless $attr->{APPEND_FIELDS};

  my @arr = split(/,/, $attr->{APPEND_FIELDS});

  foreach my $line (@arr) {
    if (!in_array($line, $cols)) {
      $LIST_PARAMS{$line} = '_SHOW' if (!defined($LIST_PARAMS{$line}) || $LIST_PARAMS{$line} eq '');
    }
  }

  return 0;
}

#**********************************************************
=head2 _result_former_data($attr, $hidden_fields)

  Arguments:

  Return:

=cut
#**********************************************************
sub _result_former_data {
  my ($attr, $hidden_fields) = @_;

  my $data = $attr->{INPUT_DATA};

  if ($attr->{FUNCTION}) {
    my $fn = $attr->{FUNCTION};

    if (!$data) {
      print "No input objects data\n";
      return { error => 'No input objects data' };
    }

    delete($data->{COL_NAMES_ARR});
    $data->{debug} = 1 if ($FORM{DEBUG});
    my $list = $data->$fn({
      COLS_NAME      => 1,
      %{$attr->{FUNCTION_PARAMS} || {}},
      %LIST_PARAMS,
      SHOW_COLUMNS   => $FORM{show_columns},
      HIDDEN_COLUMNS => $hidden_fields
    });

    $data->{list} = $list;
  }
  elsif ($attr->{LIST}) {
    $data->{list} = $attr->{LIST};
  }

  return $data;
}

#**********************************************************
=head2 _result_former_data_extra_fields($data, $SEARCH_TITLES)

  Arguments:

  Return:

=cut
#**********************************************************
sub _result_former_data_extra_fields {
  my ($data, $SEARCH_TITLES) = @_;

  return $SEARCH_TITLES if (! $data->{EXTRA_FIELDS});

  foreach my $line (@{$data->{EXTRA_FIELDS}}) {
    next if (in_array('Multidoms', \@MODULES) && $admin->{DOMAIN_ID} && $admin->{DOMAIN_ID} ne $line->{domain_id});
    if (ref $line eq 'ARRAY' && $line->[0] =~ /ifu(\S+)/) {
      my $field_id = $1;
      my (undef, undef, $name, undef) = split(/:/, $line->[1]);

      $SEARCH_TITLES->{ $field_id } = ($name =~ /\$/) ? _translate($name) : $name;
    }
    elsif ($line->{id}) {
      my $field_id = $line->{sql_field};
      my $name = $line->{name};

      $SEARCH_TITLES->{ $field_id } = ($name =~ /\$/) ? _translate($name) : $name;
    }
  }

  return 0;
}

#**********************************************************
=head2 _get_search_titles($attr, $data)

  Arguments:
    $attr,
    $data

  Return:
    %SEARCH_TITLES

=cut
#**********************************************************
sub _get_search_titles {
  my ($attr, $data) = @_;

  my %SEARCH_TITLES = (
    login_status   => "$lang{LOGIN} $lang{STATUS}",
    deposit        => $lang{DEPOSIT},
    credit         => $lang{CREDIT},
    login          => $lang{LOGIN},
    fio            => $lang{FIO},
    last_payment   => $lang{LAST_PAYMENT},
    last_fees      => $lang{LAST_FEES},
    email          => 'E-Mail',
    pasport_date   => "$lang{PASPORT} $lang{DATE}",
    pasport_num    => "$lang{PASPORT} $lang{NUM}",
    pasport_grant  => "$lang{PASPORT} $lang{GRANT}",
    contract_id    => $lang{CONTRACT_ID},
    contract_date  => "$lang{CONTRACT} $lang{DATE}",
    registration   => $lang{REGISTRATION},
    comments       => $lang{COMMENTS},
    company_id     => "$lang{COMPANY} ID",
    company_name   => $lang{COMPANY},
    bill_id        => $lang{BILLS},
    activate       => $lang{ACTIVATE},
    expire         => $lang{EXPIRE},
    credit_date    => "$lang{CREDIT} $lang{DATE}",
    reduction      => $lang{REDUCTION},
    reduction_date => "$lang{REDUCTION} $lang{DATE}",

    deleted        => $lang{DELETED},
    uid            => 'UID',
    birth_date     => $lang{BIRTH_DATE},

    latitude       => $lang{LATITUDE},
    longitude      => $lang{LONGITUDE},

    telegram       => 'Telegram',
    viber          => 'Viber',
  );

  if ($permissions{0} && $permissions{0}{26}) {
    $SEARCH_TITLES{district_name} = $lang{DISTRICTS};
    $SEARCH_TITLES{address_full} = "$lang{FULL} $lang{ADDRESS}";
    $SEARCH_TITLES{address_street} = $lang{ADDRESS_STREET};
    $SEARCH_TITLES{address_build} = $lang{ADDRESS_BUILD};
    $SEARCH_TITLES{address_flat} = $lang{ADDRESS_FLAT};
    $SEARCH_TITLES{address_street2} = $lang{SECOND_NAME};
    $SEARCH_TITLES{city} = $lang{CITY};
    $SEARCH_TITLES{zip} = $lang{ZIP};
    $SEARCH_TITLES{phone} = $lang{PHONE};
    $SEARCH_TITLES{floor} = $lang{FLOOR};
    $SEARCH_TITLES{entrance} = $lang{ENTRANCE};
  }

  if ($permissions{0} && $permissions{0}{28}) {
    $SEARCH_TITLES{group_name} = "$lang{GROUP} $lang{NAME}";
    $SEARCH_TITLES{gid} = $lang{GROUP};
  }

  if (in_array('Tags', \@MODULES) && (!$admin->{MODULES} || $admin->{MODULES}{Tags})) {
    $SEARCH_TITLES{tags} = $lang{TAGS} if (!$admin->{MODULES} || $admin->{MODULES}{Tags});
  }

  if (in_array('Maps', \@MODULES) && (!$admin->{MODULES} || $admin->{MODULES}{Maps})) {
    $SEARCH_TITLES{build_id} = $lang{LOCATION};
  }

  if (in_array('Multidoms', \@MODULES) && (!$admin->{DOMAIN_ID} || $admin->{DOMAIN_ID} =~ /[,;]+/)) {
    $SEARCH_TITLES{domain_id} = 'DOMAIN ID';
    $SEARCH_TITLES{domain_name} = $lang{DOMAIN};
  }

  $SEARCH_TITLES{accept_rules} = $lang{ACCEPT_RULES} if ($conf{ACCEPT_RULES});
  $SEARCH_TITLES{ext_deposit} = "$lang{EXTRA} $lang{DEPOSIT}" if ($conf{EXT_BILL_ACCOUNT});
  $SEARCH_TITLES{cell_phone} = $lang{CELL_PHONE} if (!$attr->{SKIP_USERS_FIELDS});

  _result_former_data_extra_fields($data, \%SEARCH_TITLES);

  if ($attr->{SKIP_USER_TITLE}) {
    %SEARCH_TITLES = %{$attr->{EXT_TITLES}} if ($attr->{EXT_TITLES});
  }
  elsif ($attr->{EXT_TITLES}) {
    %SEARCH_TITLES = (%SEARCH_TITLES, %{$attr->{EXT_TITLES}});
  }

  return %SEARCH_TITLES;
}

#**********************************************************
=head2 _result_former_get_total_table($attr, $data, $table)

  Arguments:

  Return:

=cut
#**********************************************************
sub _result_former_get_total_table {
  my ($attr, $data, $table) = @_;

  return 0 unless ($attr->{TOTAL} && (!$attr->{SHOW_MORE_THEN} || $data->{TOTAL} > $attr->{SHOW_MORE_THEN}));

  my $result = $table->show();

  return $result if ($admin->{MAX_ROWS} || $attr->{SKIP_TOTAL_FORM});

  my @rows = ();

  if ($attr->{TOTAL} =~ /;/) {
    my @total_vals = split(/;/, $attr->{TOTAL});
    foreach my $line (@total_vals) {
      my ($val_id, $name) = split(/:/, $line);
      push @rows, [ $name ? ($lang{$name} || $name) : $val_id, $html->b(($val_id) ? $data->{$val_id} : q{}) ];
    }
  }
  else {
    @rows = [ "$lang{TOTAL}:", $html->b($data->{TOTAL}) ]
  }

  $table = $html->table({
    ID    => ($attr->{TABLE}->{ID}) ? "$attr->{TABLE}->{ID}_TOTAL" : q{},
    width => '100%',
    rows  => \@rows
  });

  $result .= $table->show();

  return $result;
}

#**********************************************************
=head2 _result_former_get_value($attr, $col_name, $line, $service_status, $service_status_colors)

  Arguments:

  Return:

=cut
#**********************************************************
sub _result_former_get_value {
  my ($attr, $col_name, $line, $service_status, $service_status_colors) = @_;

  return _get_login_value($attr, $line) if ($col_name eq 'login' && $line->{uid} && defined(&user_ext_menu));
  return _get_filter_cols_value($attr, $line, $col_name) if ($attr->{FILTER_COLS} && $attr->{FILTER_COLS}->{$col_name});

  if ($attr->{FILTER_VALUES} && $attr->{FILTER_VALUES}->{$col_name}) {
    if (ref $attr->{FILTER_VALUES}->{$col_name} eq 'CODE') {
      return $attr->{FILTER_VALUES}->{$col_name}->($line->{$col_name}, $line, $col_name);
    }
    else {
      warn "FILTER_VALUES expects coderef";
      return '';
    }
  }

  if ($col_name =~ /status$/ && (!$attr->{SELECT_VALUE} || !$attr->{SELECT_VALUE}->{$col_name})) {
    return _get_status_value($attr, $line, $col_name, $service_status, $service_status_colors);
  }

  if ($col_name =~ /build_id/) {
    return _get_location_value($line, $col_name);
  }

  if ($col_name =~ /deposit/) {
    return '--' if (!$permissions{0}{12});

    my $deposit = $line->{deposit} || 0;
    $deposit = sprintf("$conf{DEPOSIT_FORMAT}", $deposit) if $conf{DEPOSIT_FORMAT};
    return ($deposit + ($line->{credit} || 0) < 0) ? $html->color_mark($deposit, 'text-danger') : $deposit,
  }

  return ($line->{deleted}) ? $html->color_mark($lang{DELETED}, 'text-danger') : '' if ($col_name eq 'deleted');
  return ($line->{online}) ? $html->color_mark('Online', '#00FF00') : '' if ($col_name eq 'online');
  return ($line->{$col_name}) ? $html->color_mark($line->{$col_name}, $line->{$col_name}) : '' if ($col_name eq 'color');
  return _get_tags_value($line, $col_name) if ($col_name eq 'tags');

  if ($attr->{SELECT_VALUE} && $attr->{SELECT_VALUE}->{$col_name} && defined($line->{$col_name})) {
    my ($value, $color) = split(/:/, $attr->{SELECT_VALUE}->{$col_name}->{$line->{$col_name}} || '');

    $value = $html->color_mark($value, $color) if ($value && $color);
    return $value || $line->{$col_name};
  }

  my $val = $line->{ $col_name  } || '';
  my $brake = $html->br();
  $val =~ s/\n/$brake/g;

  return $val;
}

#**********************************************************
=head2 _get_login_value($attr, $line)

  Arguments:

  Return:

=cut
#**********************************************************
sub _get_login_value {
  my ($attr, $line) = @_;

  my $val = '';
  if (!$FORM{EXPORT_CONTENT}) {
    my $login_status_color = undef;
    if (defined($line->{login_status}) && $attr->{SELECT_VALUE} && $attr->{SELECT_VALUE}->{login_status}) {
      (undef, $login_status_color) = split(/:/, $attr->{SELECT_VALUE}->{login_status}->{ $line->{login_status} } || '');
    }
    $val = user_ext_menu($line->{uid}, $line->{login}, { NO_CHANGE => 1, EXT_PARAMS => ($attr->{MODULE} ?
      "MODULE=$attr->{MODULE}" : undef), dv_status_color => $login_status_color });
  }
  else {
    $val = $line->{login};
  }

  return $val;
}

#**********************************************************
=head2 _get_filter_cols_value($attr, $line, $col_name)

  Arguments:

  Return:

=cut
#**********************************************************
sub _get_filter_cols_value {
  my ($attr, $line, $col_name) = @_;

  my ($filter_fn, @arr) = split(/:/, $attr->{FILTER_COLS}->{$col_name});
  my %p_values = ();

  if ($arr[1] && $arr[1] =~ /,/) {
    foreach my $k (split(/,/, $arr[1])) {
      if ($k =~ /(\S+)=(.*)/) {
        $p_values{$1} = $2;
      }
      elsif (defined($line->{lc($k)})) {
        $p_values{$k} = $line->{lc($k)};
      }
    }
  }

  return &{\&$filter_fn}($line->{$col_name}, {
    PARAMS    => \@arr,
    VALUES    => \%p_values,
    LINK_NAME => ($attr->{SELECT_VALUE} && $attr->{SELECT_VALUE}->{$col_name}) ?
      $attr->{SELECT_VALUE}->{$col_name}->{$line->{$col_name}} : undef
  });
}

#**********************************************************
=head2 _get_status_value($attr, $line, $col_name, $service_status, $service_status_colors)

  Arguments:

  Return:

=cut
#**********************************************************
sub _get_status_value {
  my ($attr, $line, $col_name, $service_status, $service_status_colors) = @_;

  my $val = '';

  if ($attr->{STATUS_VALS} && ref($attr->{STATUS_VALS}) eq "HASH") {
    return $val if (!$attr->{STATUS_VALS}{$line->{$col_name} // q{}});

    my ($status_value, $status_color) = split(':', $attr->{STATUS_VALS}{$line->{$col_name}});
    $val = (defined $line->{$col_name} && $line->{$col_name} >= 0) ? $html->color_mark($status_value, $status_color) :
      (defined $status_value ? $status_value : '');
  }
  else {
    if (!$attr->{SKIP_STATUS_CHECK}) {
      $val = ($line->{$col_name} && $line->{$col_name} > 0) ? $html->color_mark($service_status->[ $line->{$col_name} ],
        $service_status_colors->[ $line->{$col_name} ]) :
        (defined $line->{$col_name} ? $service_status->[$line->{$col_name}] : '');
    }
  }

  return $val;
}

#**********************************************************
=head2 _get_tags_value($line, $col_name)

  Arguments:

  Return:

=cut
#**********************************************************
sub _get_tags_value {
  my ($line, $col_name) = @_;

  return $line->{$col_name} if (!$line->{tags} || $line->{tags} eq '');

  my @priority_colors = ('btn-secondary', 'btn-info', 'btn-success', 'btn-warning', 'btn-danger');
  my @tags_name = split(/,/, $line->{tags});
  my @tags_priority = split(/,/, $line->{priority});
  $line->{$col_name} = q{};

  for (my $tags_count = 0; $tags_count < scalar @tags_name; $tags_count++) {
    my $priority_color = ($tags_priority[$tags_count] && $priority_colors[$tags_priority[$tags_count]]) ?
      $priority_colors[$tags_priority[$tags_count]] : q{};

    $line->{$col_name} .= ' ' . $html->element('span', $tags_name[$tags_count], { class => "btn btn-xs $priority_color" });
  }

  return $line->{$col_name};
}

#**********************************************************
=head2 _get_location_value($line, $col_name)

=cut
#**********************************************************
sub _get_location_value {
  my ($line, $col_name) = @_;

  return $line->{$col_name} if (!in_array('Maps', \@MODULES) || ($admin->{MODULES} && !$admin->{MODULES}{Maps}));
  return $line->{$col_name} if (!$line->{$col_name} || $line->{$col_name} eq '');

  my $location_btn = $line->{$col_name};
  eval { $location_btn = form_add_map(undef, { BUILD_ID => $line->{$col_name} }); };

  return $location_btn;
}

#**********************************************************
=head2 _result_former_map($attr, $data)

  Arguments:

  Return:

=cut
#**********************************************************
sub _result_former_map {
  my ($attr, $data) = @_;

  return 0 unless ($attr->{MAP} && (!$attr->{SHOW_MORE_THEN} || $data->{TOTAL} > $attr->{SHOW_MORE_THEN}));

  my @header_arr = ("$lang{MAIN}:index=$index" . $attr->{TABLE}->{qs},
    "$lang{MAP}:index=$index&&MAP=1" . $attr->{TABLE}->{qs}
  );
  my $exec_function;

  if ($attr->{EXTRA_TABS}) {
    foreach my $name (keys %{$attr->{EXTRA_TABS}}) {
      my ($title, $function_name) = split(/:/, $name);
      push @header_arr, "$title:$attr->{EXTRA_TABS}->{$name}";

      my $qs = $ENV{QUERY_STRING};
      $qs =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1)) /eg;
      $exec_function = $function_name if ($ENV{QUERY_STRING} eq $attr->{EXTRA_TABS}->{$name});
    }
  }

  print $html->table_header(\@header_arr, { TABS => 1 });

  if ($FORM{MAP}) {
    if (in_array('Maps', \@MODULES)) {
      _result_former_maps_show($data->{list}, $attr);
      return 1;
    }
  }
  elsif ($exec_function) {
    if (defined($exec_function)) {
      &{\&$exec_function}();
      return 1;
    }
  }

  return 0;
}

#**********************************************************
=head2 _result_former_make_chart($attr, $line, $data, $chart_num)

  Arguments:

  Return:

=cut
#**********************************************************
sub _result_former_make_chart {
  my ($attr, $line, $dataset, $period) = @_;

  foreach my $data (@{$dataset}) {
    next if !exists $line->{$period};

    $line->{$period} //= '-';
    $DATA_HASH{$line->{$period}}{$data} = $line->{$data};
  }
}

#**********************************************************
=head2 _result_former_make_rows($attr, $data, $table)

  Arguments:
    $attr
      EXT_ATTR
        SEARCH_FIELDS_COUNT
        BASE_FIELDS
        HIDDEN_FIELDS
        SERVICE_STATUS
        SERVICE_STATUS_COLORS
        MULTISEL_ID
        MULTISEL_VALUE
        MULTISELECT_ARR
        MULTISEL_FORM
    $data,
    $table

  Return:

=cut
#**********************************************************
sub _result_former_make_rows {
  my ($attr, $data, $table) = @_;

  if ($data->{errno}) {
    _error_show($data, { MESSAGE => 'RESULT_FORMER: ' . ($attr->{TABLE}->{caption} || q{}) });
    return 0;
  }
  elsif (ref $data->{list} ne 'ARRAY') {
    print "<br></hr> ERROR: " . q{ ref $data->{list} ne 'ARRAY' };
    return 0;
  }

  my $total = $data->{TOTAL} || 0;
  my $search_color_mark = q{};
  if ($FORM{_MULTI_HIT}) {
    $FORM{_MULTI_HIT} =~ s/\*//g;
    $search_color_mark = $html->color_mark($FORM{_MULTI_HIT}, 'text-danger');
  }

  $attr->{EXT_ATTR}{SEARCH_FIELDS_COUNT} += $table->{HIDDEN_FIELD_COUNT} if ($FORM{json} && $table->{HIDDEN_FIELD_COUNT});

  foreach my $line (@{$data->{list}}) {
    my @fields_array = ();

    for (my $i = 0; $i < $attr->{EXT_ATTR}{BASE_FIELDS} + $attr->{EXT_ATTR}{SEARCH_FIELDS_COUNT}; $i++) {
      my $val = '';
      my $col_name = $data->{COL_NAMES_ARR}->[$i] || '';

      next if (!$FORM{json} && in_array(uc($col_name), $attr->{EXT_ATTR}{HIDDEN_FIELDS}));

      $val = _result_former_get_value($attr, $col_name, $line, $attr->{EXT_ATTR}{SERVICE_STATUS}, $attr->{EXT_ATTR}{SERVICE_STATUS_COLORS});

      unshift(@fields_array, $html->form_input($attr->{EXT_ATTR}{MULTISEL_ID}, $line->{$attr->{EXT_ATTR}{MULTISEL_VALUE}}, {
        TYPE    => 'checkbox',
        FORM_ID => $attr->{EXT_ATTR}{MULTISEL_FORM} // '',
        STATE   => in_array($line->{$attr->{EXT_ATTR}{MULTISEL_VALUE}}, $attr->{EXT_ATTR}{MULTISELECT_ARR})
      })) if ($i == 0 && $attr->{MULTISELECT});

      $val =~ s/(.*)$FORM{_MULTI_HIT}(.*)/$1$search_color_mark$2/g if ($search_color_mark && $val);

      push @fields_array, $val;
    }

    my $fields_count = @{$attr->{EXT_ATTR}{FUNCTION_FIELDS}};
    if ($fields_count > -1) {
      push @fields_array, join(' ', @{table_function_fields($attr->{EXT_ATTR}{FUNCTION_FIELDS}, $line, $attr)});

      if ($FORM{chg} && $line->{id} && $FORM{chg} == $line->{id}) {
        $table->{rowcolor} = 'row-active';
        $fields_array[0] = $html->element('span', '&nbsp;', { class => 'text-success fa fa-ellipsis-v', OUTPUT2RETURN => 1 }) .
          $fields_array[0];
      }
      else {
        $table->{rowcolor} = undef;
      }
    }

    if ($attr->{CHARTS} && ref $attr->{CHARTS} eq 'HASH') {
      _result_former_make_chart($attr, $line, $attr->{CHARTS}{DATASET}, $attr->{CHARTS}{PERIOD});
    }

    $table->addrow(@fields_array);
  }

  $data->{TOTAL} = $total;

  return 1;
}

#**********************************************************
=head2 _column_no_permitss()

  Arguments:
    -
  Return:
    -

=cut
#**********************************************************
sub _column_no_permitss {

  # _info_fields_hide();

  my (undef, $name_var, $fields_data) = split(/(SEARCH_FIELDS=)(.+[A-Z][0-9])/, $admin->{WEB_OPTIONS} || q{});
  my @web_options_admin = ();
  @web_options_admin = split(/, /, $fields_data) if ($fields_data);

  my %hash_fields_options = map { $_ => 1 } @web_options_admin;

  if ($permissions{0} && !$permissions{0}{28}) {
    delete $LIST_PARAMS{GID};
    delete $LIST_PARAMS{GROUP_NAME};
  }

  if ($permissions{0} && !$permissions{0}{26}) {
    delete $LIST_PARAMS{DISTRICT_ID} unless ($hash_fields_options{DISTRICT_ID});
    delete $LIST_PARAMS{STREET_ID} unless ($hash_fields_options{STREET_ID});
    delete $LIST_PARAMS{ADDRESS_BUILD} unless ($hash_fields_options{ADDRESS_BUILD});
    delete $LIST_PARAMS{ADDRESS_FLAT} unless ($hash_fields_options{ADDRESS_FLAT});
    delete $LIST_PARAMS{ADDRESS_FULL} unless ($hash_fields_options{ADDRESS_FULL});
    delete $LIST_PARAMS{ADDRESS_STREET} unless ($hash_fields_options{ADDRESS_STREET});
    delete $LIST_PARAMS{PHONE} unless ($hash_fields_options{PHONE});
  }

  if (in_array('Tags', \@MODULES) && $admin->{MODULES} && !$admin->{MODULES}{Tags}) {
    delete $LIST_PARAMS{TAGS};
  }

  return 1;
}

#**********************************************************
=head2 _info_fields_hide()

  Arguments:
    -
  Return:
    -

=cut
#**********************************************************
# sub _info_fields_hide {
#
#   return 0 unless (($admin->{SETTING} || $FORM{show_columns}));
#
#   my @info_fields = ();
#   if (!$FORM{show_columns}) {
#     @info_fields = split(', ', $admin->{SETTING});
#   }
#   else {
#     @info_fields = split(', ', $FORM{show_columns});
#   }
#
#   my %hash_fields = ();
#   foreach my $key (@info_fields) {
#     $hash_fields{$key} = 1;
#   }
#
#   foreach my $key (sort keys %LIST_PARAMS) {
#     if ($key =~ /^_/ && !$hash_fields{ $key }) {
#       delete($LIST_PARAMS{ $key });
#     }
#   }
#
#   return 1;
# }

#**********************************************************
=head2 _sort_table($name_table, $sort, $cols)

  Arguments:
    $name_table -
    $sort       - is sort

  Return:
    -

=cut
#**********************************************************
sub _sort_table {
  my ($name_table, $sort, $cols) = @_;

  if ($sort) {
    my $desc = $FORM{desc};
    _save_sort_admin({
      name_table => $name_table,
      sort       => $sort,
      desc       => $desc || '',
      cols       => $cols
    });
  }
  else {
    my ($sort, $desc) = split('\|', $admin->{SORT_TABLE}) if ($admin->{SORT_TABLE});
    if ($sort && $sort =~ /^\d+$/ && ($sort - 1) > $#{ $cols }) {
      $LIST_PARAMS{SORT} = '1';
    }
    else {
      $LIST_PARAMS{SORT} = ($sort || $LIST_PARAMS{SORT}) || '1';
    }

    $desc = $sort ? $desc : $LIST_PARAMS{DESC};

    $LIST_PARAMS{DESC} = $desc || '';
  }

  return 1;
}

#**********************************************************
=head2 _save_sort_admin($name_table, $attr)

  Arguments:
    $name_table -

    sort        - save current sort
    desc        - save current desc or no desc

  Return:
    -

=cut
#**********************************************************
sub _save_sort_admin {
  my ($attr) = @_;

  my $str_fields = '';
  foreach my $field (@{ $attr->{cols} }) {
    $str_fields .= $field . ', ';
  }

  unless ($admin->{OBJECT}) {
    $admin->settings_add({
      OBJECT      => $attr->{name_table},
      SETTING     => $str_fields,
      SORT_TABLE  => "$attr->{sort}|$attr->{desc}",
    });
  } else {
    $admin->settings_change({
      AID         => $admin->{AID},
      OBJECT      => $attr->{name_table},
      SETTING     => $str_fields,
      SORT_TABLE  => "$attr->{sort}|$attr->{desc}",
    });
  }

}

1;
