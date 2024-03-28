package AXbills::CONSOLE;


=head2 NAME

  CONSOLE output Functions

=cut

use strict;
our (
  @_COLORS,
  %FORM,
  %LIST_PARAMS,
  %COOKIES,
  $index,
  $pages_qs,
  $SORT,
  $DESC,
  $PG,
  $PAGE_ROWS,
  $SELF_URL,
  @MONTHES,
  $COLS_SEPARATOR,
);


our $VERSION = 2.01;
my $debug;
my %log_levels;
my $row_number = 0;
my $CONF;


#**********************************************************
# Create Object
#**********************************************************
sub new {
  my $class = shift;
  my ($attr) = @_;

  require AXbills::HTML;
  AXbills::HTML->import();

  my $self = {};
  bless($self, $class);

  if ($attr->{NO_PRINT}) {
    $self->{NO_PRINT} = 1;
  }

  $CONF = $attr->{CONF};
  $FORM{_export}='csv';

  @_COLORS = (
    '#FDE302',    # 0 TH
    '#FFFFFF',    # 1 TD.1
    '#eeeeee',    # 2 TD.2
    '#dddddd',    # 3 TH.sum, TD.sum
    '#E1E1E1',    # 4 border
    '#FFFFFF',    # 5
    '#FF0000',    # 6 Error
    '#000088',    # 7 vlink
    '#0000A0',    # 8 Link
    '#000000',    # 9 Text
    '#FFFFFF',    #10 background
  );

  $COLS_SEPARATOR  = $attr->{COLS_SEPARATOR} || ';';

  if ($attr->{language}) {
    $self->{language} = $attr->{language};
  }
  elsif ($COOKIES{language}) {
    $self->{language} = $COOKIES{language};
  }
  else {
    $self->{language} = $CONF->{default_language} || 'english';
  }

  $self->{TYPE}='console' if(! $self->{TYPE});

  return $self;
}

#**********************************************************
=head2 link_former($text, $attr) - Format link

  Arguments:
    $text   -  Text for format

  Returns:
    $text  -  Formated text

=cut
#**********************************************************
sub link_former {
  shift;
  my ($text) = @_;

  #$text =~ s/\n/\\n/g;

  return $text;
}

#**********************************************************
=head2 form_input()

=cut
#**********************************************************
sub form_input {
  shift;
  my (undef, $value, undef) = @_;

  return $value;
}

#**********************************************************
=head2 form_main($attr) HTML Input form

=cut
#**********************************************************
sub form_main {
  my $self   = shift;
  my ($attr) = @_;

  if ($FORM{EXPORT_CONTENT} && $FORM{EXPORT_CONTENT} ne $attr->{ID}) {
    return '';
  }

  $self->{FORM} = "";

  if ($FORM{csv}) {
    return $attr->{CONTENT};
  }

  if (defined($attr->{HIDDEN})) {
    my $H = $attr->{HIDDEN};
    while (my ($k, $v) = each(%$H)) {
      $self->{FORM} .= "<input name=\"$k\" value=\"$v\"/>\n";
    }
  }

  if ($attr->{CONTENT}) {
    $self->{FORM} .= $attr->{CONTENT};
  }

  if (defined($attr->{SUBMIT})) {
    my $H = $attr->{SUBMIT};
    while (my ($k, $v) = each(%$H)) {
      $self->{FORM} .= "<input type=\"submit\" name=\"$k\" value=\"$v\"/>\n";
    }
  }

  $self->{FORM} .= "";

  if (defined($self->{NO_PRINT})) {
    $self->{OUTPUT} .= $self->{FORM};
    $self->{FORM} = '';
  }

  return $self->{FORM};
}

#**********************************************************
#
#**********************************************************
sub form_select {
  my $self = shift;
  my ($name, $attr) = @_;

  my $ex_params = (defined($attr->{EX_PARAMS})) ? $attr->{EX_PARAMS} : '';

  $self->{SELECT} = "<select name=\"$name\" $ex_params>\n";

  if (defined($attr->{SEL_OPTIONS})) {
    my $H = $attr->{SEL_OPTIONS};
    while (my ($k, $v) = each %$H) {
      $self->{SELECT} .= "<option value='$k'";
      $self->{SELECT} .= ' selected="1"' if (defined($attr->{SELECTED}) && $k eq $attr->{SELECTED});
      $self->{SELECT} .= ">$v</option>\n";
    }
  }

  if (defined($attr->{SEL_ARRAY})) {
    my $H = $attr->{SEL_ARRAY};
    my $i = 0;
    foreach my $v (@$H) {
      my $id = (defined($attr->{ARRAY_NUM_ID})) ? $i : $v;
      $self->{SELECT} .= "<option value='$id'";
      $self->{SELECT} .= ' selected="1"' if (defined($attr->{SELECTED}) && (($i eq $attr->{SELECTED}) || ($v eq $attr->{SELECTED})));
      $self->{SELECT} .= ">$v</option>\n";
      $i++;
    }
  }
  elsif (defined($attr->{SEL_MULTI_ARRAY})) {
    my $key   = $attr->{MULTI_ARRAY_KEY};
    my $value = $attr->{MULTI_ARRAY_VALUE};
    my $H     = $attr->{SEL_MULTI_ARRAY};

    foreach my $v (@$H) {
      $self->{SELECT} .= "<option value='$v->[$key]'";
      $self->{SELECT} .= ' selected="1"' if (defined($attr->{SELECTED}) && $v->[$key] eq $attr->{SELECTED});
      $self->{SELECT} .= '>';
      $self->{SELECT} .= "$v->[$key]:" if (!$attr->{NO_ID});
      $self->{SELECT} .= "$v->[$value]</option>\n";
    }
  }
  elsif (defined($attr->{SEL_HASH})) {
    my @H = ();

    if ($attr->{SORT_KEY}) {
      @H = sort keys %{ $attr->{SEL_HASH} };
    }
    else {
      @H = keys %{ $attr->{SEL_HASH} };
    }

    foreach my $k (@H) {
      $self->{SELECT} .= "<option value='$k'";
      $self->{SELECT} .= " selected='1'" if (defined($attr->{SELECTED}) && $k eq $attr->{SELECTED});

      if ($attr->{EXT_PARAMS}) {
        while (my ($ext_k, $ext_v) = each %{ $attr->{EXT_PARAMS} }) {
          $self->{SELECT} .= " $ext_k='";
          $self->{SELECT} .= $attr->{EXT_PARAMS}->{$ext_k}->{$k} if ($attr->{EXT_PARAMS}->{$ext_k}->{$k});
          $self->{SELECT} .= "'";
        }
      }

      $self->{SELECT} .= '>';
      $self->{SELECT} .= "$k:" if (!$attr->{NO_ID});
      $self->{SELECT} .= "$attr->{SEL_HASH}{$k}</option>\n";
    }
  }

  $self->{SELECT} .= "</select>\n";

  return $self->{SELECT};
}

#**********************************************************
# Functions list
#**********************************************************
sub menu2 {
  my $self = shift;
  my ($menu_items, $menu_args, $permissions, $attr) = @_;
  $self->menu($menu_items, $menu_args, $permissions, $attr);
}

sub menu {
  my $self = shift;
  my ($menu_items, $menu_args, $permissions, $attr) = @_;

  return 0 if ($FORM{index} > 0);

  my $menu_navigator = '';
  my $menu_text      = '';
  $menu_text = "<SID>$self->{SID}</SID>\n" if ($self->{SID});

  return $menu_navigator, $menu_text if ($FORM{NO_MENU});

  my $EX_ARGS = (defined($attr->{EX_ARGS})) ? $attr->{EX_ARGS} : '';
  my $fl = $attr->{FUNCTION_LIST};

  my %new_hash = ();
  while ((my ($findex, $hash) = each(%$menu_items))) {
    while (my ($parent, $val) = each %$hash) {
      $new_hash{$parent}{$findex} = $val;
    }
  }

  my $h          = $new_hash{0};
  my @last_array = ();

  my @menu_sorted = sort { $b cmp $a } keys %$h;

  for (my $parent = 0 ; $parent < $#menu_sorted + 1 ; $parent++) {
    my $val = $h->{ $menu_sorted[$parent] };

    my $level  = 0;
    my $prefix = '';
    my $ID     = $menu_sorted[$parent];

    next if ((!defined($attr->{ALL_PERMISSIONS})) && (!$permissions->{ $parent - 1 }) && $parent == 0);
    $menu_text .= "<MENU NAME=\"$fl->{$ID}\" ID=\"$ID\" EX_ARGS=\"" . $self->link_former($EX_ARGS) . "\" DESCRIBE=\"$val\" TYPE=\"MAIN\"/>\n ";
    if (defined($new_hash{$ID})) {
      $level++;
      $prefix .= "   ";
      label:
      my $mi = $new_hash{$ID};

      while (my ($k, undef) = each %$mi) {
        $menu_text .= "$prefix<MENU NAME=\"$fl->{$k}\" ID=\"$k\" EX_ARGS=\"" . $self->link_former("$EX_ARGS") . "\" DESCRIBE=\"$val\" TYPE=\"SUB\" PARENT=\"$ID\"/>\n ";

        if (defined($new_hash{$k})) {
          $mi = $new_hash{$k};
          $level++;
          $prefix .= "    ";
          push @last_array, $ID;
          $ID = $k;
        }
        delete($new_hash{$ID}{$k});
      }

      if ($#last_array > -1) {
        $ID = pop @last_array;
        $level--;

        $prefix = substr($prefix, 0, $level * 1 * 3);
        goto label;
      }
      delete($new_hash{0}{$parent});
    }
  }

  return ($menu_navigator, $menu_text);
}

#**********************************************************
# heder off main page
# make_charts()
#**********************************************************
sub make_charts {

}

#**********************************************************
# heder off main page
# header()
#**********************************************************
sub header {
  my $self       = shift;
  #my ($attr)     = @_;

  if ($FORM{DEBUG}) {
    print "Content-Type: text/plain\n\n";
  }

  if ($FORM{csv}) {
  	my $filename     =  ($self->{ID}) ? $self->{ID}.'.csv' : ($FORM{EXPORT_CONTENT}) ?  $FORM{EXPORT_CONTENT}.'.csv' : int(rand(10000000)).'.csv';
    $self->{header}  = "Content-Type: text/csv; filename=$filename\n";
    $self->{header} .= "Cache-Control: no-cache\n";
    $self->{header} .= "Content-disposition: attachment;filename=\"$filename\"\n\n";
  }
  else {
    $self->{header} = "Content-Type: text/plain\n\n";
  }

  return $self->{header};
}

#**********************************************************
=head2 table()

=cut
#**********************************************************
sub table {
  my $proto  = shift;
  my $class  = ref($proto) || $proto;
  my $parent = ref($proto) && $proto;
  my $self;
  $self = {};

  bless($self);

  $self->{prototype} = $proto;
  $self->{NO_PRINT}  = $proto->{NO_PRINT};

  my ($attr) = @_;
  $self->{rows} = '';

  if (defined($attr->{rowcolor})) {
    $self->{rowcolor} = $attr->{rowcolor};
  }

  if ($attr->{SELECT_ALL}) {
    $self->{SELECT_ALL}=$attr->{SELECT_ALL};
  }

  if (defined($attr->{rows})) {
    my $rows = $attr->{rows};
    foreach my $line (@$rows) {
      $self->addrow(@$line);
    }
  }
  $self->{ID} = $attr->{ID};
  if ($attr->{title}) {
    $self->{title} = $attr->{title};
    $self->{table} .= $self->table_title($SORT, $DESC, $PG, $attr->{title}, $attr->{qs});
  }
  elsif ($attr->{title_plain}) {
    $self->{table} .= $self->table_title_plain($attr->{title_plain});
  }

  if ($attr->{pages} && !$FORM{EXPORT_CONTENT}) {
    my $op;
    if ($FORM{index}) {
      $op = "index=$FORM{index}";
    }

    my %ATTR = ();
    if (defined($attr->{recs_on_page})) {
      $ATTR{recs_on_page} = $attr->{recs_on_page};
    }
    $self->{pages} = $self->pages($attr->{pages}, "$op$attr->{qs}", {%ATTR});
  }

  return $self;
}

#**********************************************************
=head2 addrows(@rows)

=cut
#**********************************************************
sub addrow {
  my $self = shift;
  my (@row) = @_;

  #my $extra = (defined($self->{extra})) ? " $self->{extra}" : '';
  $row_number++;
  my $col_num=0;

  foreach my $val (@row) {
    if(! $self->{title}->[$col_num] || $self->{title}->[$col_num] eq '-') {
      next;
    }

    $val =~ s/\n/\\n/g;
    $val =~ s/\r//g;
    #$self->{rows} .= $self->link_former($val) . "$COLS_SEPARATOR";

    $self->{rows} .= $val . "$COLS_SEPARATOR";
    $col_num++;
  }

  $self->{rows} .= "\r\n";
  return $self->{rows};
}

#**********************************************************
=head2 addrows(@row)

=cut
#**********************************************************
sub addtd {
  my $self  = shift;
  my (@row) = @_;
  #my $extra = (defined($self->{extra})) ? $self->{extra} : '';

  my $select_present = ($self->{SELECT_ALL}) ? 1 : 0;

  for (my $i=0; $i<=$#row; $i++) {
    my $val = $row[($i + $select_present)];
    $self->{rows} .= "$val$COLS_SEPARATOR";
  }

  $self->{rows} .= "\n";
  return $self->{rows};
}

#**********************************************************
=head2 th() Extendet add rows

=cut
#**********************************************************
sub th {
  my $self = shift;
  my ($value) = @_;

  return $self->td($value, { TH => 1 });
}

#**********************************************************
# Extendet add rows
# td()
#
#**********************************************************
sub td {
  my $self = shift;
  my ($value, $attr) = @_;

  my $td = '';
  if ($attr->{TH}) {
    $td .= $value if (defined($value));
  }
  else {
    $td .= $value if (defined($value));
  }

  #$td .= $COLS_SEPARATOR;
  return $td;
}

#**********************************************************
=head2 title_plain($caption)

  Arguments:
    $caption - ref to caption array

=cut
#**********************************************************
sub table_title_plain {
  my $self = shift;
  my ($caption) = @_;

  $self->{table_title} = '';

  foreach my $line (@$caption) {
    $self->{table_title} .= "$line$COLS_SEPARATOR";
  }

  $self->{table_title}.="\n";

  return $self->{table_title};
}

#**********************************************************
=head2 table_title($sort, $desc, $pg, $caption, $qs) - Show table column  titles with wort derectives

  Arguments
    table_title($sort, $desc, $pg, $caption, $qs);
    $sort - sort column
    $desc - DESC / ASC
    $pg - page id
    $caption - array off caption

=cut
#**********************************************************
sub table_title {
  my $self = shift;
  my ($sort, $desc, $pg, $caption, $qs) = @_;

  $self->table_title_plain($caption);

  return $self->{table_title};
}

#**********************************************************
=head2 table_header($header_arr, $attr) - Table header function button

  Arguments
   $header_arr   - array of elements
   $attr         - Extra attributes

  Returns:
    $header      - Header

=cut
#**********************************************************
sub table_header {
  my $self = shift;

  if ($FORM{EXPORT_CONTENT} && $FORM{EXPORT_CONTENT} ne $self->{ID}) {
    return '';
  }

  my $header = '';

  return $header;
}


#**********************************************************
=head2 img($img, $name, $attr)

=cut
#**********************************************************
sub img {
  #my $self = shift;
  #my ($img, $name) = @_;

  return "";
}

#**********************************************************
# show
#**********************************************************
sub show {
  my $self = shift;
  my ($attr) = @_;

  if ($FORM{EXPORT_CONTENT} && $FORM{EXPORT_CONTENT} ne $self->{ID}) {
    return '';
  }

  $self->{show} = $self->{table};
  $self->{show} .= $self->{rows};

  if (defined($self->{pages})) {
    $self->{show} = $self->{show} . $self->{pages};
  }

  if (defined($self->{NO_PRINT}) && !defined($attr->{OUTPUT2RETURN})) {
    $self->{prototype}->{OUTPUT} .= $self->{show};
    $self->{show} = '';
  }

  return $self->{show};
}

#**********************************************************
=head2 button($name, $params, $attr) - Create link element

  Arguments:
    $name     - Link name
    $params   - Link params (url)
    $attr
      ONLY_IN_HTML - link will be returned if we are working with HTML, but will not be returned in export modes like xls, csv, json
      JAVASCRIPT   -
      GLOBAL_URL   - Global link
      TITLE        -

  Returns:
    String with element

=cut
#**********************************************************
sub button {
  my $self = shift;
  my ($name, $params, $attr) = @_;

  if ($attr->{ONLY_IN_HTML}) {
    return '';
  }

  return $name;
  my $ex_attr = '';

  $params = ($attr->{GLOBAL_URL}) ? $attr->{GLOBAL_URL} : "$params";

  $params = $attr->{JAVASCRIPT} if (defined($attr->{JAVASCRIPT}));
  $params = $self->link_former($params);

  $ex_attr = " TITLE='$attr->{TITLE}'" if (defined($attr->{TITLE}));

  my $button = "<BUTTON VALUE=\"$params\" $ex_attr>$name</BUTTON>";

  return $button;
}

#**********************************************************
=head2 message($self, $type, $caption, $message) - Show message box

 $type - info, err

=cut
#**********************************************************
sub message {
  my $self = shift;
  my ($type, $caption, $message, $attr) = @_;
  my $id = $attr->{ID} || q{};
  my $output = "$type: $id $caption $message\n";

  if (defined($self->{NO_PRINT})) {
    $self->{OUTPUT} .= $output;
    return $output;
  }
  else {
    print $output;
  }
}

#**********************************************************
# Make pages and count total records
# pages($count, $argument)
#**********************************************************
sub pages {
  my $self = shift;
  my ($count, $argument, $attr) = @_;

  if (defined($attr->{recs_on_page})) {
    $PAGE_ROWS = $attr->{recs_on_page};
  }

  my $begin = 0;

  return '' if ($count < $PAGE_ROWS);

  $self->{pages} = '';
  $begin = ($PG - $PAGE_ROWS * 3 < 0) ? 0 : $PG - $PAGE_ROWS * 3;

  for (my $i = $begin ; ($i <= $count && $i < $PG + $PAGE_ROWS * 10) ; $i += $PAGE_ROWS) {
    $self->{pages} .= ($i == $PG) ? "[$i] " : $i. '';
  }

  return $self->{pages} . "\n";
}

#**********************************************************
=head2 date_fld2($base_name) - Make data field

=cut
#**********************************************************
sub date_fld2 {
  my $self = shift;
  my ($base_name, $attr) = @_;

  my ($sec, $min, $hour, $mday, $mon, $curyear, $wday, $yday, $isdst) = localtime(time);

  my $day   = $FORM{ $base_name . 'D' } || 1;
  my $month = $FORM{ $base_name . 'M' } || $mon;
  my $year  = $FORM{ $base_name . 'Y' } || $curyear + 1900;
  my $result = "$year-$month-$day";

  if ($FORM{$base_name}) {
    my $date = $FORM{$base_name};
    $self->{$base_name} = $date;
  }
  elsif (!$attr->{NO_DEFAULT_DATE}) {
    ($sec, $min, $hour, $mday, $mon, $curyear, $wday, $yday, $isdst) = localtime(time + (($attr->{NEXT_DAY}) ? 86400 : 0));

    $month = $mon + 1;
    $year  = $curyear + 1900;
    $day   = $mday;

    if ($base_name =~ /to/i) {
      $day = ($month != 2 ? (($month % 2) ^ ($month > 7)) + 30 : (!($year % 400) || !($year % 4) && ($year % 25) ? 29 : 28));
    }
    elsif ($base_name =~ /from/i && !$attr->{NEXT_DAY}) {
      $day = 1;
    }
    my $date = sprintf("%d-%.2d-%.2d", $year, $month, $day);
    $self->{$base_name} = $date;
  }

  return $result;
}

#**********************************************************
# log_print()
#**********************************************************
sub log_print {
  my $self = shift;
  my ($level, $text) = @_;

  if ($debug < $log_levels{$level}) {
    return 0;
  }

print << "[END]";
$text
[END]
}

#**********************************************************
# show tamplate
# tpl_show
#
# template
# variables_ref
# atrr [EX_VARIABLES]
#**********************************************************
sub tpl_show {
  my $self = shift;
  my ($tpl, $variables_ref, $attr) = @_;

  if ($FORM{EXPORT_CONTENT} && $FORM{EXPORT_CONTENT} ne $attr->{ID}) {
    return '';
  }

  if (!$attr->{SOURCE}) {
    while ($tpl =~ /\%(\w+)(\=?)([A-Za-z0-9\_\.\/\\\]\[:\-]{0,50})\%/g) {
      my $var       = $1;
      my $delimiter = $2;
      my $default   = $3;

      #    if ($var =~ /$\{exec:.+\}$/) {
      #      my $exec = $1;
      #      if ($exec !~ /$\/usr/axbills\/\misc\/ /);
      #      my $exec_content = system("$1");
      #      $tpl =~ s/\%$var\%/$exec_content/g;
      #     }
      #    els

      if ($attr->{SKIP_VARS} && $attr->{SKIP_VARS} =~ /$var/) {
      }
      elsif ($default && $default =~ /expr:(.*)/) {
        my @expr_arr = split(/\//, $1, 2);
        $variables_ref->{$var} =~ s/$expr_arr[0]/$expr_arr[1]/g;
        $default               =~ s/\//\\\//g;
        $default               =~ s/\[/\\\[/g;
        $default               =~ s/\]/\\\]/g;
        $tpl                   =~ s/\%$var$delimiter$default%/$variables_ref->{$var}/g;
      }
      elsif (defined($variables_ref->{$var})) {
        if ($variables_ref->{$var} !~ /\=\'|\' | \'/ && !$attr->{SKIP_QUOTE}) {
          $variables_ref->{$var} =~ s/\'/&rsquo;/g;
        }
        $tpl =~ s/\%$var$delimiter$default%/$variables_ref->{$var}/g;
      }
      else {
        $tpl =~ s/\%$var$delimiter$default\%/$default/g;
      }
    }
  }

  if ($attr->{OUTPUT2RETURN}) {
    return $tpl;
  }
  elsif ($attr->{MAIN}) {
    $self->{OUTPUT} .= "$tpl";
    return $tpl;
  }
  elsif ($attr->{notprint} || $self->{NO_PRINT}) {
    $self->{OUTPUT} .= $tpl;

    return $tpl;
  }
  else {
    print "$tpl";
  }
}

#**********************************************************
# test function
#  %FORM     - Form
#  %COOKIES  - Cookies
#  %ENV      - Enviropment
#
#**********************************************************
sub test {
  my $output = '';

  while (my ($k, $v) = each %FORM) {
    $output .= "$k | $v\n" if ($k ne '__BUFFER');
  }

  $output .= "\n";
  while (my ($k, $v) = each %COOKIES) {
    $output .= "$k | $v\n";
  }
}

#**********************************************************
=head2 b($text) - Bold text;

=cut
#**********************************************************
sub b {
  my ($self) = shift;
  my ($text) = @_;

  return $text;
}

#**********************************************************
# b();
#**********************************************************
sub p {
  my ($self) = shift;
  my ($text) = @_;

  return $text;
}

#**********************************************************
# letters_list();
#**********************************************************
sub letters_list {
  my ($self, $attr) = @_;

  if ($FORM{EXPORT_CONTENT} && $FORM{EXPORT_CONTENT} ne $attr->{ID}) {
    return "";    #"<a> $FORM{EXPORT_CONTENT} </a>";
  }

  $pages_qs = $attr->{pages_qs} if (defined($attr->{pages_qs}));

  my $output = '<LETTERS>' . $self->button('All ', "index=$index");
  for (my $i = 97 ; $i < 123 ; $i++) {
    my $l = chr($i);
    if ($FORM{letter} && $FORM{letter} eq $l) {
      $output .= "<b>$l </b>";
    }
    else {
      $output .= $self->button("$l", "index=$index&letter=$l$pages_qs") . "\n";
    }
  }
  $output .= '</LETTERS>';

  if (defined($self->{NO_PRINT})) {
    $self->{OUTPUT} .= $output;
    return '';
  }
  else {
    print $output;
  }

}

#**********************************************************
=head2 color_mark($message, $color, $attr)

=cut
#**********************************************************
sub color_mark {
  my $self = shift;
  my ($message, $color, $attr) = @_;

  if(! $self->{COLOR_MARKS}) {
    return $message;
  }

  return $message if ($attr->{SKIP_XML});

  my $output = "!! $message !!";
  return $output;
}

#**********************************************************
=head2 br() Break line

=cut
#**********************************************************
sub br {
  my $self = shift;

  return "\n";
}


#**********************************************************
# element
#**********************************************************
sub element {
  my $self = shift;
  my ($name, $value, $attr) = @_;

  my $params = '';
  if (ref $attr eq 'HASH') {
    while(my($k, $v)=each %$attr) {
      $params .= "$k='$v' ";
    }
  }

  $self->{FORM_INPUT} = "<$name $params>$value</$name>";

  if (defined($self->{NO_PRINT}) && (!defined($attr->{OUTPUT2RETURN}))) {
    $self->{OUTPUT} .= $self->{FORM_INPUT};
    $self->{FORM_INPUT} = '';
  }

  return $self->{FORM_INPUT};
}

#**********************************************************
=head2

=cut
#**********************************************************
sub pre {
  shift;
  my ($text) = @_;

  return "\n====\n$text\n====\n\n";
}

#**********************************************************
=head2  AUTOLOAD Autoload secondary funtions

=cut
#**********************************************************
sub AUTOLOAD {
  our $AUTOLOAD;

  return if ($AUTOLOAD =~ /::DESTROY$/);
  my $function = $AUTOLOAD;

  if($function =~ /table_header|progress_bar|/) {
    return q{};
  }

  my ($self, $data) = @_;

  return $data;
}


1
