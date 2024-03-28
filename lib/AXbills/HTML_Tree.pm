package AXbills::HTML_Tree;
use strict;

use v5.16;

my $name;
my $levels;

my $id_key;
my $name_key;
my $value_key;

my $has_multi_level_ids;
my $has_multi_level_names;
my $has_multi_level_values;
my $has_multi_level_checkbox_names;

my $attr;
my $items;

#**********************************************************
=head2 new() - constructor for HTML_Tree

  Attributes:

  Returns:
    object - new Tree instance

=cut
#**********************************************************
sub new {
  my $class = shift;
  my $self = { };
  
  bless( $self, $class );

  return $self;
}

  #**********************************************************
=head2 tree_menu($list, $name, $attr)

  Builds a collapsible tree menu from hashref that contains array_refs as values

  Arguments:
    $list - array_ref of hash_ref (list from DB with a COLS_NAME attr)
    $name - Name for First level of menu
    $attr
      PARENT_KEY      - hash_key for an item's  parent id. Default to PARENT_ID
      ID_KEY          - hash_key for an item's id key. Default to 'ID'

      LABEL_KEY        - hash_key for an item's label key. Default to 'NAME'
      VALUE_KEY       - hash_key for an item's value key. Default to 'ID'
      ROOT_VALUE      - Value of root (highest ieararchy level parent). Default is '';

      PARENTNESS_HASH - if  you need more complicated structure pass your own ierarchy for building menu
      LEVEL_ID_KEYS    - arr_ref of ID_KEY  for a level
      LEVEL_LABEL_KEYS - arr_ref of LABEL_KEY  for a level
      LEVEL_VALUE_KEYS - arr_ref of VALUE_KEY for a level

      LEVELS   - number of levels to display. Default is to count it automatically
      CHECKBOX - boolean, will build a checkbox at last level
      NAME     - string, name for a checkbox
      
      LAST_LEVEL_CLICKABLE - changes style of last level (cursor : pointer)

      COL_SIZE - width of menu. Default is 3 if LEVELS <= 6, and 6 otherwise

      SHOW_OPEN_TREE - show opened tree. Default is none, if value => 1 tree opened.
  Returns:
    HTML code for a menu

  Example:

   my $list = [

    { ID => '1',  NAME => 'Level1_1', VALUE => '1' , PRENT_ID => '0'},
    { ID => '2',  NAME => 'Level1_2', VALUE => '2' , PRENT_ID => '0'},
    { ID => '3',  NAME => 'Level1_3', VALUE => '3' , PRENT_ID => '0'},
    { ID => '4',  NAME => 'Level1_4', VALUE => '4' , PRENT_ID => '0'},

    { ID => '5',  NAME => 'Level2_1', VALUE => '5' , PRENT_ID => '1'},
    { ID => '6',  NAME => 'Level2_2', VALUE => '6' , PRENT_ID => '2'},
    { ID => '7',  NAME => 'Level2_3', VALUE => '7' , PRENT_ID => '3'},
    { ID => '8',  NAME => 'Level2_4', VALUE => '8' , PRENT_ID => '4'},

    { ID => '10', NAME => 'Level3_1', VALUE => '10' , PRENT_ID => '8'},
    { ID => '11', NAME => 'Level3_2', VALUE => '11' , PRENT_ID => '8'},
    { ID => '12', NAME => 'Level3_3', VALUE => '12' , PRENT_ID => '8'},
    { ID => '13', NAME => 'Level3_4', VALUE => '13' , PRENT_ID => '8'}

  ];

  print $html->tree_menu( $list, 'Menu', { PARENT_KEY => 'PRENT_ID', LABEL_KEY => 'NAME' } );


=cut
#**********************************************************
sub tree_menu {
  my $self = shift;
  my ($list, $name_, $attr_) = @_;

  $attr = $attr_;
  $name = $name_ || 'Menu';

  my $parentness_hash;
  if ($attr->{PARENTNESS_HASH}) {
    $parentness_hash = $attr->{PARENTNESS_HASH};
  }
  else {
    $parentness_hash = $self->build_parentness_tree($list, $attr);
  }
  
  return $parentness_hash if $attr->{RETURN_HASH_TREE};
  # Get number of levels
  $levels = $attr->{LEVELS} || count_levels( $parentness_hash );

  my $col_size;
  if ($attr->{COL_SIZE}) {
    $col_size = $attr->{COL_SIZE};
  }
  elsif ($levels && $levels > 6) {
    $col_size = 6;
  }
  else {
    $col_size = 3;
  }

  only_put_script($col_size, $list, $parentness_hash);
}

#**********************************************************
=head2 render_tree($list, $parentness)

  Build HTML for a given tree and list

  Arguments:
    $list         -
    $parentness   -

  Returns:

=cut
#**********************************************************
sub render_tree {
  my ($list, $parentness) = @_;

  $id_key     = $attr->{ID_KEY} || 'ID';
  $name_key   = $attr->{LABEL_KEY} || 'NAME';
  $value_key  = $attr->{VALUE_KEY} || 'ID';

  $has_multi_level_ids      = defined $attr->{LEVEL_ID_KEYS};
  $has_multi_level_names    = defined $attr->{LEVEL_LABEL_KEYS};
  $has_multi_level_values   = defined $attr->{LEVEL_VALUE_KEYS};

  $has_multi_level_checkbox_names = defined $attr->{LEVEL_CHECKBOX_NAME};

  #prepare information
  my $items_ = { };
  if (!$has_multi_level_ids) {
    foreach my $item (@{$list}) {
      $items_->{ $item->{$id_key} } = $item;
    }
  }
  else {
    render_tree_cycles($list, $items_);
  }

  $items = $items_;

  return render_branch( $name, 0, $parentness, 0 );
}


#**********************************************************
=head2 render_branch($menu_name, $level_value, $menu_list, $recursion_level)

  Arguments:
    $menu_name        -
    $level_value      -
    $menu_list        -
    $recursion_level  -

  Returns:

=cut
#**********************************************************
sub render_branch {
  my ($menu_name, $level_value, $menu_list, $recursion_level) = @_;

  my $checkbox_for_label = '';

  if ($attr->{CHECKBOX} && ($attr->{NAME} || $has_multi_level_checkbox_names) && $recursion_level != 0) {
    $checkbox_for_label = checkbox_visible($recursion_level, $level_value);
  }

  my $result = '';
  my $ul_display = ($attr->{SHOW_OPEN_TREE}) ? "block" : "none";

  $result .= "<li>$checkbox_for_label<label class='tree-toggler'>$menu_name</label>\n";
  $result .= "<ul class='nav tree' style='display: $ul_display;'>\n";

  my ($current_item_name, $current_item_value);

  foreach my $item_key (sort keys %{$menu_list}) {
    ($current_item_name, $current_item_value) = 
            branch_item($current_item_name, $recursion_level, $item_key, $current_item_value);

    my $checkbox = checkbox_tree($recursion_level, $current_item_value);

    if (ref ( $menu_list->{$item_key} ) eq 'HASH') {
      $recursion_level++;
      $result .= render_branch( $current_item_name, $current_item_value, $menu_list->{$item_key},
        $recursion_level );
      $recursion_level--;
    }
    else {
      if ($current_item_name =~ m/<\/url>/g) {
        $current_item_name =~ s/<\/url>/<\/a>/g;
      }

      $result .= "<li>$checkbox<span class='tree-item'>$current_item_name</span>\n";
    }
    $result .= "</li>\n";
  }

  $result .= "</ul>\n";
  return $result;

}


#**********************************************************
=head2 count_levels($parentness_h)

  find tree depth

  Arguments:
    $parentness_h - hash_ref

  Returns:
    number - maximal depth of a tree

=cut
#**********************************************************
sub count_levels {
  my ($parentness_h) = @_;

  my $levels_count = 0;
  my $levels_count_ref = \$levels_count;

  step_to_level( $parentness_h, 0, $levels_count_ref );

  return $levels_count;
}

#**********************************************************
=head2 step_to_level($level, $r_level)

  Arguments:
    $level,
    $r_level
    $levels_count_ref

  Returns:

=cut
#**********************************************************
sub step_to_level {
  my ($level, $r_level, $levels_count_ref) = @_;

  if ($r_level > ${$levels_count_ref}) {${$levels_count_ref} = $r_level};

  foreach my $key (keys ( %{$level} )) {
    if (ref $level->{$key} eq 'HASH') {
      step_to_level( $level->{$key}, ++$r_level, $levels_count_ref );
    }
  }

};

#**********************************************************
=head2 build_parentness_tree($array, $attr) - build hash_ref that represents ieararchy for list (Parents and children);

  Arguments:
    $array - DB list (array of hash_ref). To build parentness we need only PARENT_ID and ID, so you can pass oly this part
    $attr
      PARENT_KEY - hash_key for an item's  parent id. Default to P
      ID_KEY     - hash_key for an item's id key. Default to 'ID'
      ROOT_VALUE - Value of root (highest ieararchy level parent). Default is '';

  Returns:
    hash_ref that represents parentness

  Example:
    If given this:
      my $list = [
        { ID => 1, PARENT_ID = '0',  ... },
        { ID => 2, PARENT_ID = 1,   ... },
        { ID => 3, PARENT_ID = 2,   ... },
        { ID => 4, PARENT_ID = 2,   ... },
      ]

    Will return this:
      $result =
      {
      '1' =>
        {
          '2' =>
          {
            '3' => '',
            '4' => ''
          }
        }
      };

=cut
#**********************************************************
sub build_parentness_tree {
  my $self = shift;
  my ($array, $attr_) = @_;
  
  my $parent_key = $attr_->{PARENT_KEY} || 'PARENT_ID';
  my $id_key_    = $attr_->{ID_KEY}     || 'ID';
  my $root_value = $attr_->{ROOT_VALUE} || '0';
        
  # Builds one level hash of direct parents and children relations.
  my %parents = ();
  foreach my $hash (@{ $array }) {
    if ($parents{ $hash->{ $parent_key } }) {
      push @{ $parents{ $hash->{ $parent_key } } }, $hash->{ $id_key_ };
    }
    else {
      $parents{ $hash->{ $parent_key } } = [ $hash->{ $id_key_ } ];
    }
  }
  
  my %result_tree = ();

  foreach my $first_level_id (@{ $parents{$root_value} }) {
    build_next_level( $first_level_id, \%result_tree , \%parents );
  }

  return \%result_tree;
}

#**********************************************************
=head2 build_next_level($id, $level, $parents)

  Arguments:
    $id    -
    $level -
    $parents -

  Returns:

=cut
#**********************************************************
sub build_next_level {
  my ($id, $level, $parents) = @_;

  $level->{$id} = { };

  if (exists $parents->{$id}) {
    foreach my $child_key (@{ $parents->{$id} }) {
      build_next_level( $child_key, $level->{$id}, $parents);
    }
  }
  else {
    $level->{$id} = '';
  }

  return $level;
}

#**********************************************************
=head2 only_put_script()

  Arguments:
    $col_size         - column size element
    $list             - data element list
    $parentness_hash  - if you need more complicated structure pass your own ierarchy for building menu

  Returns:
    HTML div and ul list of tree

=cut
#**********************************************************
sub only_put_script {
  my ($col_size, $list, $parentness_hash) = @_;
  state $scripts_showed = 0;

  my $tree_script = '';

  if (!$scripts_showed){
    $tree_script = "<link rel='stylesheet' type='text/css' href='/styles/default/css/tree.css'>
        <script src='/styles/default/js/tree_menu.js'></script>";
    $scripts_showed = 1;
  }
  
  my $clickable = ($attr->{LAST_LEVEL_CLICKABLE}) ? 'clickable' : '';
  
  return "<div class='col-md-$col_size text-left'>
    <ul class='nav main well tree-menu $clickable'>\n" . render_tree( $list, $parentness_hash ) . '</ul>'."
      $tree_script
    </div>";
}

#**********************************************************
=head2 render_tree_cycles()

  Arguments:
    $list     - item refferal list
    items_    - prepare information

  Returns:
    -

=cut
#**********************************************************
sub render_tree_cycles {
  my ($list, $items_) = @_;

  for (my $i = 0; $i <= $levels; $i++) {
    my $key = @{ $attr->{LEVEL_ID_KEYS} }[$i];
  
    foreach my $item (@{$list}) {
      $items_->{$i}->{ $item->{ $key } } = {
        $id_key    => $item->{ lc(@{$attr->{LEVEL_ID_KEYS}}[$i]) },
        $name_key  => $item->{ lc(@{$attr->{LEVEL_LABEL_KEYS}}[$i])},
        $value_key => $item->{ lc(@{$attr->{LEVEL_VALUE_KEYS}}[$i]) },
      };
    }
  }
}

#**********************************************************
=head2 checkbox_visible()

  Arguments:
    $recursion_level    -
    $level_value        -

  Returns:
    HTML input type checkbox

=cut
#**********************************************************
sub checkbox_visible {
  my ($recursion_level, $level_value) = @_;

  my $checkbox_for_label_name = '';

  if ($has_multi_level_checkbox_names) {
    $checkbox_for_label_name = @{$attr->{LEVEL_ID_KEYS}}[$recursion_level - 1];
  }
  else {
    $checkbox_for_label_name = $attr->{NAME};
  }

  my $checkbox_state = ($attr->{CHECKBOX_STATE}
    && $attr->{CHECKBOX_STATE}{$checkbox_for_label_name . '_' . $level_value} );
    
  return "<input type='checkbox' data-checked='$checkbox_state' 
    name='$checkbox_for_label_name'
    value='$level_value' />";
}

#**********************************************************
=head2 checkbox_tree()

  Arguments:
    $recursion_level    -
    $current_item_value -

  Returns:
    HTML input type checkbox OR empty string

=cut
#**********************************************************
sub checkbox_tree {
  my ($recursion_level, $current_item_value) = @_;

  if ($attr->{CHECKBOX} && ($attr->{NAME} || $has_multi_level_checkbox_names)) {
    my $checkbox_name = ($has_multi_level_checkbox_names) ? @{$attr->{LEVEL_ID_KEYS}}[$recursion_level] : $attr->{NAME};

    return "<input type='checkbox' 
      data-checked='$attr->{CHECKBOX_STATE}{$checkbox_name . '_' . $current_item_value}'
      name='$checkbox_name'
      value='$current_item_value' />";
  }

  return '';
}

#**********************************************************
=head2 branch_item()

  Arguments:
    $current_item_name  - 
    $recursion_level    -
    $item_key           - 
    $current_item_value -

  Returns:
    $current_item_name  -
    $current_item_value -

=cut
#**********************************************************
sub branch_item {
  my ($current_item_name, $recursion_level, $item_key, $current_item_value) = @_;

  $current_item_name = ($has_multi_level_ids)
    ? $items->{$recursion_level}->{$item_key}->{$name_key}
    : $items->{$item_key}->{$name_key};

  $current_item_value = ($has_multi_level_values)
    ? $items->{$recursion_level}->{$item_key}->{$value_key}
    : $items->{$item_key}->{$value_key};

  return ($current_item_name, $current_item_value);
}

1;