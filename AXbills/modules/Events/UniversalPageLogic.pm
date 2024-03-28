#package Events::UniversalPageLogic;
use strict;
use warnings FATAL => 'all';

our (
  $Events,
  $html,
  %lang
);

=head1 NAME

  Events::UniversalPageLogic - trying to simplify work with templates and result_former

=head2 SYNOPSIS

  This package  allows to minify code that is same for simple view and change DB table info

=cut

#**********************************************************
=head2 events_uni_result_former($attr) - contains events module result former similar parameters

 Arguments:
   $attr - hash_ref

 Returns:
   list

=cut
#**********************************************************
sub events_uni_result_former {
  my ($attr) = @_;
  
  my $filter_cols = { map {$_ => 'translate_simple'} split(",", lc $attr->{DEFAULT_FIELDS}) };
  
  my AXbills::HTML $table;
  my $list;
  my @status_bar_arr = ();

  my $state_list = $Events->state_list({
    NAME => '_SHOW',
  });

  _error_show($Events) and return 0;
  # Adding all option
  unshift(@$state_list, { id => 0, name => $lang{ALL} });

  foreach my $status (@$state_list) {
    push @status_bar_arr, translate_simple($status->{name}).":index=$index&search=2&STATE_ID=".$status->{id};
  }

  ($table, $list) = result_former({
    INPUT_DATA      => $Events,
    FUNCTION        => $attr->{LIST_FUNC},
    BASE_FIELDS     => 0,
    #      DEFAULT_FIELDS  => $attr->{DEFAULT_FIELDS},
    FUNCTION_FIELDS => "change,del",
    SKIP_USER_TITLE => 1,
    EXT_FIELDS      => 0,
    EXT_TITLES      => $attr->{EXT_TITLES},
    MULTISELECT     => 'IDS:id:DELETE_EVENTS_FORM',
    TABLE           => {
      MULTISELECT_ACTIONS => $attr->{MULTISELECT_ACTIONS},
      width               => '100%',
      caption             => $attr->{READABLE_NAME},
      ID                  => uc $attr->{LIST_FUNC},
      header              => \@status_bar_arr,
      EXPORT              => 1,
      SHOW_FULL_LIST      => 1,
      MENU                =>
        "$lang{ADD}:index=$index&show_add_form=1:add;"
        . ($attr->{HAS_SEARCH} ? "$lang{SEARCH}:index=$index&search_form=1:search" : '')
      },
    MAKE_ROWS       => 1,
    SEARCH_FORMER   => 1,
    MODULE          => 'Events',
    %{ $attr // {} },
    FILTER_COLS     => {
      %{$filter_cols},
      %{ $attr->{FILTER_COLS} // {} },
    },
    OUTPUT2RETURN   => 1,
  });
  
  if ($attr->{OUTPUT2RETURN}){
    return $table->show({ OUTPUT2RETURN => 1 });
  }
  
  print $table->show() if ($table);
  
  if ( $attr->{MANAGEMENT_FORM} ) {
    print $attr->{MANAGEMENT_FORM};
  }
  
  return $list;
}


#**********************************************************
=head2 events_uni_page_logic($name, $attr)

  Arguments:
    $name - name for entity to manage
    $attr - hash_ref

  Returns:

=cut
#**********************************************************
sub events_uni_page_logic {
  my ($name, $attr) = @_;
  
  $attr = (defined $attr) ? $attr : {};
  
  my $add_func = "$name\_add";
  my $change_func = "$name\_change";
  my $info_func = "$name\_info";
  my $delete_func = "$name\_del";
  
  if ( $FORM{show_add_form} && !$FORM{MESSAGE_ONLY} ) {
    events_uni_show_template($name, $attr);
  }
  if ( $FORM{search_form} && $attr->{HAS_SEARCH} ) {
    events_fill_selects($attr, { SELECTS => $attr->{SELECTS} });
    if ( $FORM{FROM_DATE} && $FORM{TO_DATE} ) {
      $FORM{CREATED} = "$FORM{FROM_DATE}/$FORM{TO_DATE}";
    }
    form_search({
      SEARCH_FORM       => $html->tpl_show(
        _include('events_' . $name . '_search', 'Events'), { %FORM, %{$attr} }, { OUTPUT2RETURN => 1 }
      ),
      PLAIN_SEARCH_FORM => 1
    });
  }
  elsif ( $FORM{chg} ) {
    my $Events_obj = $Events->$info_func($FORM{chg});
    _error_show($Events) and return 0;
    
    # Need to translate all names
    foreach ( keys %{$Events_obj} ) {
      next if ( $_ !~ /_NAME$/ );
      if ( my $translated = translate_simple($Events_obj->{$_}) ) {
        $Events_obj->{$_ . '_TRANSLATED'} = $translated;
      }
    }
    
    $Events_obj->{CHANGE_ID} = "ID";
    
    my $tpl_name = ($attr->{HAS_VIEW}) ? $name . '_view' : $name;
    events_uni_show_template($tpl_name, { %{$Events_obj}, %{$attr} });
  }
  elsif ( $FORM{add} ) {
    $Events->$add_func(\%FORM);
    show_result($Events, $lang{ADDED});
  }
  elsif ( $FORM{change} ) {
    if ( $FORM{IDS} ) {
      foreach ( split(',\s?', $FORM{IDS}) ) {
        $FORM{ID} = $_;
        $Events->$change_func(\%FORM);
        _error_show($Events);
      }
      show_result($Events, $lang{CHANGED} . ":" . $FORM{IDS});
    }
    elsif ($FORM{ID}) {
      $Events->$change_func(\%FORM);
      show_result($Events, $lang{CHANGED});
    }
  }
  elsif ( $FORM{del} && $FORM{COMMENTS} ) {
    if ( $FORM{IDS} ) {
      $FORM{del} = $FORM{IDS};
    }
    
    $Events->$delete_func({ ID => $FORM{del} });
    show_result($Events, $lang{DELETED}, $FORM{del});
  }
  
  _error_show($Events);
  
  return 1;
}

#**********************************************************
=head2 events_uni_show_template($name, $template_args) - shows form for ADD or CHANGE operations

  Arguments:
    $name          - name for entity to manage,
    $template_args - generally this will be entity hash
  Returns:
   1

  Examples:
    events_uni_show_template ( 'events',
    {
      SELECTS =>
      {
        STATE_SELECT    => { func => 'events_state_select', argument => "STATE_ID" },
        PRIVACY_SELECT  => { func => 'events_privacy_select', argument => "PRIVACY_ID" },
        PRIORITY_SELECT => { func => 'events_priority_select', argument => "PRIORITY_ID" },
      }
    }
  );

=cut
#**********************************************************
sub events_uni_show_template {
  my ($tpl_name, $template_args) = @_;
  
  if ( $template_args->{SELECTS} ) {
    events_fill_selects($template_args, { SELECTS => $template_args->{SELECTS} });
  }

  $html->tpl_show(
    '',
    {
      %{$template_args},
      SUBMIT_BTN_NAME   => ($FORM{chg}) ? "$lang{CHANGE}" : "$lang{ADD}",
      SUBMIT_BTN_ACTION => ($FORM{chg}) ? "change" : "add"
    },
    {
      TPL    => "events_$tpl_name",
      MODULE => 'Events',
      ID     =>  uc($tpl_name),
      %{  $template_args->{HAS_HELP} ? { HELP => 1 } : {}  }
    }
  );
  
  return 1;
}

#**********************************************************
=head2 events_fill_selects($object, $attr)

  Arguments:
      $object - object, that will be passed to template
      $attr - hash_ref
        SELECTS - hash_ref to forms selects

  Examples:
    events_fill_selects( $EVENT_TEMPLATE_ARGS, {
        SELECTS => {
          STATE_SELECT    => { func => 'events_state_select', argument => "STATE_ID" },
          PRIVACY_SELECT  => { func => 'events_privacy_select', argument => "PRIVACY_ID" },
          PRIORITY_SELECT => { func => 'events_priority_select', argument => "PRIORITY_ID" },
        }
      }
    );

=cut
#**********************************************************
sub events_fill_selects {
  my ($object, $attr) = @_;
  
  my %select_hash = %{ $attr->{SELECTS} };
  
  while ( my ($select_name, $select) = each %select_hash ) {
    if (ref $select eq 'HASH'){
      $object->{$select_name} = &{ \&{$select->{func}}}({ SELECTED => $object->{ $select->{argument} } });
    }
    elsif (ref $select eq ''){
      $object->{$select_name} = $select;
    }
  }
  
  return $object;
}


1;