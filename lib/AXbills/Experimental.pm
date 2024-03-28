=NAME

  AXbills::Experimental

=SYNOPSYS

  Various function for symplifying and avoiding duplicates of code
  
  Uses %lang, $html

=cut
#package AXbills::Experimental;

use strict;
use warnings FATAL => 'all';

our (
  %lang,
  $VERSION,
  %FORM,
  $admin,
#  $html,
  $index,
  @ISA,
  @EXPORT,
  @EXPORT_OK,
  %EXPORT_TAGS
);

our $html;

$VERSION = 1.00;

#**********************************************************
=head2 sort_array_to_hash($array_ref, $key_name)

  Arguments:
    $array_ref - [ {}, {}, ...]
    $key_name  -  key for grouping (unique)

  Returns:
    \%hash_ref

=cut
#**********************************************************
sub sort_array_to_hash {
  my ($array_ref, $key_name) = @_;

  $key_name ||= 'id';

  my %result_hash = ();
  foreach my $list_row ( @{$array_ref} ) {
    next unless ($list_row && $list_row->{$key_name});
    $result_hash{$list_row->{$key_name}} = $list_row;
  }

  return \%result_hash;
}

#**********************************************************
=head2 show_result($Module, $message) - shows error or success message

  Arguments:
    $Module  - Module DB object
    $message - message to show if no error

  Returns:
    boolean - 1 if success

=cut
#**********************************************************
sub show_result {
  my ($Module, $caption, $message, $attr) =  @_;

  $attr //= {};
  $caption //= '',
  $message //= '';

  return 0 if (_error_show($Module, { MESSAGE => $message }));

  if (exists $Module->{INSERT_ID}){
    $attr->{RESPONCE_PARAMS}{INSERT_ID} =  $Module->{INSERT_ID};
  }
  
  if ($FORM{ID} && $FORM{change}){
    $message .= $html->button($lang{SHOW}, "index=$index&chg=$FORM{ID}", { BUTTON => 2} ) if ($html->{TYPE} && $html->{TYPE} eq 'html');
  }
  
  $html->message('info', $caption, $message, $attr) if ($caption || $message);

  return 1;
}

#**********************************************************
=head2 translate_list_value($list, @key_names) - translates values inside list by keys

  Arguments:
    $list      - DB list
    @key_names - array of strings. Default ('name')

  Returns:
    $list - same list with translated values

=cut
#**********************************************************
sub translate_list_value {
  my ($list, @key_names) = @_;

  $key_names[0] //= 'name';

  return [] if !$list || ref $list ne 'ARRAY';
  
  if (scalar @key_names == 1){
    return [ map { $_->{$key_names[0]} = _translate($_->{$key_names[0]}); $_ } @$list ];
  }
  
  for (@$list){
    foreach my $key_name (@key_names){
      $_->{$key_name} = _translate($_->{$key_name});
    }
  }
  return $list;
}

#**********************************************************
=head2 _translate_list_simple($list, @name_keys)

  Arguments:
    $list      - list of vars to translate
    @name_keys - array of hash keys to translate. default : (name)

  Returns:
    translated list

=cut
#**********************************************************
sub translate_list_simple {
  my ($list, @name_keys) = @_;
  
  $name_keys[0] //= 'name';
  
  foreach my $line (@$list){
    foreach ( @name_keys ) {
      $line->{$_} = translate_simple($line->{$_}) if ($line->{$_});
    }
  }
  
  return $list;
}

#**********************************************************
=head2 translate_simple($text) - simple translate for template lang variables

=cut
#**********************************************************
sub translate_simple {
  my $text = shift || return '';
  
  while ( $text =~ /\_\{(\w+)\}\_/g ) {
    my $to_translate = $1 or next;
    my $translation = $lang{$to_translate} // "{$to_translate}";
    
    $text =~ s/\_\{$to_translate\}\_/$translation/sg;
  }
  
  return $text
}

#**********************************************************
=head2 is_array_ref($ref) - tests if refference is defined and is array refference

  Arguments:
    $ref - reference to test

  Returns:
    boolean

=cut
#**********************************************************
sub is_array_ref {
  return defined $_[0] && ref($_[0]) eq 'ARRAY';
}

#**********************************************************
=head2 is_not_empty_array_ref($ref)

=cut
#**********************************************************
sub is_not_empty_array_ref {
  return defined $_[0] && ref($_[0]) eq 'ARRAY' && scalar(@{$_[0]}) > 0;
}

#**********************************************************
=head2 arrays_array2table() - transforms arrays array to simple table

  Arguments:
    $lines_array - array_ref
      #0
      [ 'caption', 'value' ],
      #1
      [ 'caption, 'value' ]
    $attr - hash_ref
    
  Returns:
    string - HTML
     
=cut
#**********************************************************
sub arrays_array2table {
  my ($lines_array) = @_;
  
  my $table = '<table class="table table-hover">';
  
  $table .= join('', map {
      "<tr><td><strong>$_->[0]</strong></td><td>" . ($_->[1] || q{}) . ' </td></tr>'
    } @{ $lines_array });

  $table .= '</table>'
}

#**********************************************************
=head2 compare_hashes_deep(\%hash1, \%hash2) - deeply comparing two hashes
  
  Assuming values are scalars or hash ref
  
=cut
#**********************************************************
sub compare_hashes_deep {
  my ($hash1, $hash2) = @_;
  return 0 unless ($hash1 && $hash2);
  
  my @differences = ();
  
  my @keys1 = sort keys (%{$hash1});
  my @keys2 = sort keys (%{$hash2});
  
  if ( $#keys1 != $#keys2 ) {
    return [ 'Number of keys differs ' . join(',', @keys1) . ' -  ' . join(',', @keys2) ];
  }
  
  for ( 0 .. $#keys1 ) {
    my $first_val = $hash1->{$keys1[$_]};
    my $second_val = $hash2->{$keys2[$_]};
    
    if ( ref $first_val && ref $second_val ) {
      my $diff2 = compare_hashes_deep($first_val, $second_val);
      push @differences, @{$diff2} if scalar(@{$diff2} > 0);
    }
    elsif ( !ref $first_val && !ref $second_val ) {
      if ( $first_val ne $second_val ) {
        push @differences, "hash1->{$keys1[$_]}($first_val) ne hash2->{$keys2[$_]}($second_val)";
      }
    }
  }
  
  return \@differences;
}
#**********************************************************
=head2 make_select_from_db_table()

=cut
#**********************************************************
sub make_select_from_db_table {
  my ($module_obj, $module_name, $entity_name, $select_name, $attr_) = @_;
  
  return sub {
    my $attr  = { %{$attr_ || {} }, %{ shift || {} } };
    
    my $name = ($attr->{NAME} || $attr_->{NAME} || $select_name || 'INVALID_SELECT_NAME');
    
    my $selected = $attr->{SELECTED} || $FORM{$name} || '';
    my $object_list_function = $entity_name . "_list";
    
    my $list = $module_obj->$object_list_function({
      ID        => '_SHOW',
      NAME      => '_SHOW',
      %{ $attr_->{FILTERS} // {} },
      PAGE_ROWS => 10000
    });
    _error_show($module_obj);
    
    if ($attr->{FORMAT_LIST} && ref $attr->{FORMAT_LIST} eq 'CODE'){
      $list = $attr->{FORMAT_LIST}->($list);
    }
    
    if ($attr->{_TRANSLATE}){
      $list = translate_list($list);
    }
    
    if (!$attr->{NO_EMPTY_FIRST}){
      $attr->{SEL_OPTIONS} = {'' => ''};
    }
    
    
    return $html->form_select(
      $select_name,
      {
        SELECTED       => $selected,
        SEL_LIST       => $list,
        NO_ID          => 1,
        MAIN_MENU      => !$attr->{NO_EXT_MENU} ? get_function_index(lc($module_name) . '_' . $entity_name) : '',
        MAIN_MENU_ARGV => !$attr->{NO_EXT_MENU} ? ($selected ? 'chg=' . $selected : '') : '',
        %{ $attr // {} }
      }
    );
    
  }
}

#**********************************************************
=head2 make_select_from_hash($name, $hash_ref, $attr) - a shortcut to form_select builded from hash with def attrs

  Arguments:
    $name     - FORM input name
    $hash_ref - options
    $attr     - usual form_select_options
    
  Returns:
    html
  
=cut
#**********************************************************
sub make_select_from_hash {
  my ( $name, $hash_ref, $attr ) = @_;
  
  $html->form_select($name, {
      SELECTED => $FORM{$name} || '',
      SEL_HASH => $hash_ref,
      SORT_KEY => 1,
      NO_ID       => 1,
      %{ $attr // {} }
    });
}

#**********************************************************
=head2 make_select_from_list($name, $arr_ref, $attr) - a shortcut to form_select builded from hash with def attrs

  Arguments:
    $name     - FORM input name
    $arr_ref - options
    $attr     - usual form_select_options
    
  Returns:
    html
  
=cut
#**********************************************************
sub make_select_from_list {
  my ( $name, $arr_ref, $attr ) = @_;
  
  $html->form_select($name, {
      SELECTED => $FORM{$name} || '',
      SEL_LIST => $arr_ref,
      NO_ID       => 1,
      %{ $attr // {} }
    });
}

#**********************************************************
=head2 make_select_from_arr_ref($name, $arr_ref, $attr) - a shortcut to form_select builded from array_ref

  Arguments:
    $name     - FORM input name
    $arr_ref - options
    $attr     - usual form_select_options
    
  Returns:
    html
  
=cut
#**********************************************************
sub make_select_from_arr_ref {
  my ( $name, $arr_ref, $attr ) = @_;
  
  $html->form_select($name, {
      SELECTED  => $FORM{$name} || '',
      SEL_ARRAY => $arr_ref,
      NO_ID       => 1,
      %{ $attr // {} }
    });
}

#**********************************************************
=head2 function_button($text, $fn_name, $chg_id, $attr) - makes link to function

=cut
#**********************************************************
sub function_button {
  my ($text, $fn_name, $chg_id, $attr) = @_;
  
  my $fn_index = get_function_index($fn_name);
  if (!$fn_index){
    return "$lang{ERROR} : $lang{FUNCTION} $fn_name $lang{ERR_NOT_EXISTS}";
  }
  
  my $link_params = '';
  my $chg_param = $attr->{ID_PARAM} || 'chg';
  if ( $chg_id ) {
    $link_params = "&$chg_param=$chg_id";
  }
  
  return $html->button($text, "index=$fn_index$link_params", $attr);
}


#**********************************************************
=head2 run_in_background() - runs a command via Backend Server, and shows notification to admin

  Command will be runned via AXbills::Base::cmd, so $command, and $args are described there

  Arguments:
    $command - program name
    $args    - AXbills::Base::cmd $attr
    $attr    - hash_ref
      SUCCESS  - Text for notification or hash_ref with Sender::Message
      ERROR    - Text for notification or hash_ref with Sender::Message
      SILENT   - do not show callout
      
      ID       - id for this task (will be returned with notification)

  Returns:
    1

=cut
#**********************************************************
sub run_in_background {
  my ($command, $args, $attr) = @_;
  
  require AXbills::Sender::Browser;
  AXbills::Sender::Browser->import();
  
  my AXbills::Sender::Browser $Browser = AXbills::Sender::Browser->new(\%conf);
  
  my $sended = $Browser->json_request( {
    MESSAGE => {
      TYPE    => 'COMMAND',
      AID     => $admin->{AID},
      PROGRAM => $command,
      ARGS    => $args,
      %{ $attr || {} }
    }
  });
  
  if ($sended && !$attr->{SILENT}){
    $html->message('callout', $lang{SENT}, $command);
  }
  
  return 1;
}

#**********************************************************
=head2 get_checkboxes_form_html($checkbox_name, $list, $checked_hash, $form_main_attr, $attr)

  Arguments:
    $checkbox_name  - name for %FORM param
    $list           - [ {id => '', name => ''}, {id => '', name => ''}, ... ]
    $checked_hash   - { id1 => 1, id2 => 0, ... }
    $form_main_attr - arguments for HTML::form_main
    $attr           - hash_ref
      SKIP_FORM - do not wrap in <form>

  Returns:
    string - html (checkboxes and labels)

=cut
#**********************************************************
sub get_checkboxes_form_html {
  my ($checkbox_name, $list, $checked_hash, $form_main_attr, $attr) = @_;
  
  $attr //= {};
  
  my $checkboxes_html = join('',
    map {
      $html->element('div',
        $html->element('label',
          $html->form_input($checkbox_name, $_->{id}, {
              TYPE          => 'checkbox',
              STATE         => $checked_hash->{$_->{id}},
              OUTPUT2RETURN => 1
            })
            . $html->element('strong', $_->{name}, { OUTPUT2RETURN => 1 })
        ),
        { class => 'checkbox', OUTPUT2RETURN => 1 }
      )
    } @{$list}
  );
  
  return $checkboxes_html if ($attr->{SKIP_FORM});
  
  return $html->form_main({
    CONTENT       => $checkboxes_html,
    OUTPUT2RETURN => 1,
    %$form_main_attr,
  });
}

1;