package AXbills::XML;
package AXbills::XML;

=head2 NAME

  XML Functions

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
  $CONFIG_TPL_SHOW,
);

#use base 'Exporter';
our $VERSION = 2.01;

#our @EXPORT = qw(
#  @_COLORS
#  %FORM
#  %LIST_PARAMS
#  %COOKIES
#  $index
#  $pages_qs
#  $SORT
#  $DESC
#  $PG
#  $PAGE_ROWS
#  $SELF_URL
#);
#
#our @EXPORT_OK   = ();
#our %EXPORT_TAGS = ();

my $debug;
my %log_levels;
my $IMG_PATH;
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

  if ($attr->{language}) {
    $self->{language} = $attr->{language};
  }
  elsif ($COOKIES{language}) {
    $self->{language} = $COOKIES{language};
  }
  else {
    $self->{language} = $CONF->{default_language} || 'english';
  }

  $FORM{_export}='xml';
  $self->{CHARSET} = (defined($attr->{CHARSET})) ? $attr->{CHARSET} : 'utf8';
  $self->{TYPE}='xml' if(! $self->{TYPE});

  return $self;
}


#**********************************************************
# form_input
#**********************************************************
sub form_input {
  my $self = shift;
  my ($name, $value, $attr) = @_;

  my $type  = (defined($attr->{TYPE}))  ? $attr->{TYPE}             : 'text';
  my $state = (defined($attr->{STATE})) ? ' checked="1"'            : '';
  my $size  = (defined($attr->{SIZE}))  ? " SIZE=\"$attr->{SIZE}\"" : '';

  $self->{FORM_INPUT} = "<input type=\"$type\" name=\"$name\" value=\"$value\"$state$size/>";

  if (defined($self->{NO_PRINT}) && (!defined($attr->{OUTPUT2RETURN}))) {
    $self->{OUTPUT} .= $self->{FORM_INPUT};
    $self->{FORM_INPUT} = '';
  }

  return $self->{FORM_INPUT};
}

#**********************************************************
# HTML Input form
#**********************************************************
sub form_main {
  my $self = shift;
  my ($attr) = @_;

  if ($FORM{EXPORT_CONTENT} && $FORM{EXPORT_CONTENT} ne $attr->{ID}) {
    return '';
  }

  $self->{FORM} = "<FORM action=\"$SELF_URL\">\n";

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

  $self->{FORM} .= "</FORM>\n";

  if (defined($self->{NO_PRINT})) {
    $self->{OUTPUT} .= $self->{FORM};
    $self->{FORM} = '';
  }

  return $self->{FORM};
}

#**********************************************************
# form_input
#**********************************************************
sub form_textarea {
  my $self = shift;
  my ($name, $value, $attr) = @_;

  $self->{FORM_INPUT} = "<textarea id='$name' name='$name'>$value</textarea>";

  if (defined($self->{NO_PRINT}) && (!defined($attr->{OUTPUT2RETURN}))) {
    $self->{OUTPUT} .= $self->{FORM_INPUT};
    $self->{FORM_INPUT} = '';
  }

  return $self->{FORM_INPUT};
}


#**********************************************************
=head2 form_select($name, $attr)

=cut
#**********************************************************
sub form_select {
  my $self = shift;
  my ($name, $attr) = @_;

  my $ex_params = ''; #(defined($attr->{EX_PARAMS})) ? $attr->{EX_PARAMS} : '';

  $self->{SELECT} = "<select name=\"$name\" $ex_params>\n";

  if (defined($attr->{SEL_OPTIONS})) {
    my $H = $attr->{SEL_OPTIONS};
    while (my ($k, $v) = each %$H) {
      if (! $k && ! $v) {
        next;
      }

      $self->{SELECT} .= "<option value='$k'";
      $self->{SELECT} .= ' selected="1"' if (defined($attr->{SELECTED}) && $k eq $attr->{SELECTED});
      $self->{SELECT} .= ">$v</option>\n";
    }
  }

  if (defined($attr->{SEL_ARRAY})) {
    my $H = $attr->{SEL_ARRAY};
    my $i = 0;
    foreach my $v (@$H) {
      my $id = ($attr->{ARRAY_NUM_ID}) ? $i : $v;
      $self->{SELECT} .= "<option value='$id'";
      $self->{SELECT} .= ' selected="1"' if (defined($attr->{SELECTED}) && (($attr->{ARRAY_NUM_ID} && $i eq $attr->{SELECTED}) || ($v eq $attr->{SELECTED})));
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
        while (my ($ext_k, undef) = each %{ $attr->{EXT_PARAMS} }) {
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
=head2 menu2($menu_items, $menu_args, $permissions, $attr) Functions list

=cut
#**********************************************************
sub menu2 {
  my $self = shift;
  my ($menu_items, $menu_args, $permissions, $attr) = @_;
  $self->menu($menu_items, $menu_args, $permissions, $attr);
}


#**********************************************************
=head2 menu($menu_items, $menu_args, $permissions, $attr) Functions list

=cut
#**********************************************************
sub menu {
  my $self = shift;
  my ($menu_items, undef, $permissions, $attr) = @_;

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
    my $val = $h->{ $menu_sorted[$parent] } || q{};

    if($val =~ /<span>(.+)<\/span>/) {
      $val = $1;
    }

    my $level  = 0;
    my $prefix = '';
    my $ID     = $menu_sorted[$parent];

    next if ((!defined($attr->{ALL_PERMISSIONS})) && (!$permissions->{ $parent - 1 }) && $parent == 0);
    my $ext_args = ($self->link_former("$EX_ARGS")) ? "EX_ARGS=\"" . $self->link_former($EX_ARGS) . "\"" : q{};
    if ($val =~ m/<.*>(.*)<\/.*>/) {
      $val = $1;
    }

    $menu_text .= "<MENU NAME=\"$fl->{$ID}\" ID=\"$ID\" $ext_args DESCRIBE=\"$val\" TYPE=\"MAIN\"/>\n ";
    if (defined($new_hash{$ID})) {
      $level++;
      $prefix .= "   ";
      label:
      my $mi = $new_hash{$ID};

      while (my ($k, undef) = each %$mi) {
        $ext_args = ($self->link_former("$EX_ARGS")) ? "EX_ARGS=\"" . $self->link_former($EX_ARGS) . "\"" : q{};
        $menu_text .= "$prefix<MENU NAME=\"$fl->{$k}\" ID=\"$k\" $ext_args DESCRIBE=\"$val\" TYPE=\"SUB\" PARENT=\"$ID\"/>\n ";

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
=head2  make_charts()

=cut
#**********************************************************
sub make_charts {
   return q{};
}

#**********************************************************
=head2  header($attr) - heder off main page

=cut
#**********************************************************
sub header {
  my $self       = shift;
  my ($attr)     = @_;

  if ($FORM{DEBUG}) {
    print "Content-Type: text/plain\n\n";
  }

  $self->{header}  = "Content-Type: text/xml\n";
  $self->{header} .= "Access-Control-Allow-Origin: *"
    . "\n\n";

  my $CHARSET = (defined($attr->{CHARSET})) ? $attr->{CHARSET} : $self->{CHARSET} || 'utf8';
  $CHARSET =~ s/ //g;
  $self->{header} .= qq{<?xml version="1.0"  encoding="$CHARSET" ?>};

  return $self->{header};
}

#**********************************************************
=head2 css()

=cut
#**********************************************************
sub css {

  return q{};
}

#**********************************************************
=head2 table() - Create tabel object

=cut
#**********************************************************
sub table {
  my $proto  = shift;
  my $class  = ref($proto) || $proto;
  my $parent = ref($proto) && $proto;
  my $self;
  $self = {};

  bless($self, $class);

  $self->{prototype} = $proto;
  $self->{NO_PRINT}  = $proto->{NO_PRINT};
  $self->{HTML}      = $parent;

  my ($attr) = @_;
  $self->{rows} = '';

  if (defined($attr->{rowcolor})) {
    $self->{rowcolor} = $attr->{rowcolor};
  }

  if (defined($attr->{rows})) {
    my $rows = $attr->{rows};
    foreach my $line (@$rows) {
      $self->addrow(@$line);
    }
  }

  $self->{ID} = $attr->{ID};
  $self->{table} = "<TABLE";

  if (defined($attr->{caption})) {
    $self->{table} .= " CAPTION=\"$attr->{caption}\" ";
  }

  if (defined($attr->{ID})) {
    $self->{table} .= " ID=\"$attr->{ID}\" ";
  }

  if ($attr->{SELECT_ALL}) {
    $self->{SELECT_ALL}=$attr->{SELECT_ALL};
  }

  $self->{table} .= ">\n";

  if (defined($attr->{title})) {
    $self->{table} .= $self->table_title($SORT, $DESC, $PG, $attr->{title}, $attr->{qs}, $attr);
  }
  elsif (defined($attr->{title_plain})) {
    $self->{table} .= $self->table_title_plain($attr->{title_plain}, $attr);
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

  $row_number++;
  $self->{rows} .= "  <ROW>";

  my $select_present = ($self->{SELECT_ALL}) ? 1 : 0;
  for (my $i=0; $i<=$#row; $i++) {
    my $val = $row[$i+$select_present];
    $val = normalize_str($val || q{});
    $self->{rows} .= "<TD>" . (($self->{SKIP_FORMER}) ? $val : $self->link_former($val, { SKIP_SPACE => 1 })) . "</TD>";
  }

  $self->{rows} .= "</ROW>\n";
  return $self->{rows};
}

#**********************************************************
=head2 addtd(@rows)

=cut
#**********************************************************
sub addtd {
  my $self  = shift;
  my (@row) = @_;

  $self->{rows} .= "<ROW>";
  my $select_present = ($self->{SELECT_ALL}) ? 1 : 0;
  for (my $i=0; $i<=$#row; $i++) {
    my $val = $row[$i+$select_present];
    $self->{rows} .= "$val";
  }

  $self->{rows} .= "</ROW>\n";
  return $self->{rows};
}

#**********************************************************
=head2 th($value) Extendet add rows

=cut
#**********************************************************
sub th {
  my $self = shift;
  my ($value) = @_;

  return $self->td($value, { TH => 1 });
}

#**********************************************************
=head2  td($value, $attr) - Extendet add rows

=cut
#**********************************************************
sub td {
  shift;
  my ($value, $attr) = @_;
  my $extra = '';

  my $td = '';
  if ($attr->{TH}) {
    $td = "<TH $extra>";
    $td .= $value if (defined($value));
    $td .= "</TH>";

  }
  else {
    $td = "<TD$extra>";
    $td .= normalize_str($value) if (defined($value));
    $td .= "</TD>";
  }
  return $td;
}

#**********************************************************
=head2 title_plain($caption)

=cut
#**********************************************************
sub table_title_plain {
  my $self = shift;
  my ($caption) = @_;

  $self->{table_title} = "<TITLE columns=\"" . ($#{$caption} + 1) . "\">\n";

  my $i = 0;
  foreach my $line (@$caption) {
    $self->{table_title} .= "  <COLUMN_" . $i . " NAME=\"$line\"/>\n";
    $i++;
  }

  $self->{table_title} .= "</TITLE>\n";
  return $self->{table_title};
}

#**********************************************************
=head2 table_title($sort, $desc, $pg, $caption, $qs) -  Show table column  titles with wort derectives

=cut
#**********************************************************
sub table_title {
  my $self = shift;
  my ($sort, $desc, $pg, $caption, $qs, $attr) = @_;

  $self->{table_title} = "<TITLE columns=\"" . ($#{$caption} + 1) . "\">\n";
  my $i = 1;
  foreach my $line (@$caption) {
    $self->{table_title} .= " <COLUMN_" . $i . " NAME=\"$line\" ";

    if ($attr->{FIELDS_IDS}) {
      if ($attr->{FIELDS_IDS}->[$i-1] && $line ne '-') {
        $self->{table_title} .= " ID='". $attr->{FIELDS_IDS}->[$i-1] ."'";
      }
    }

    $self->{table_title} .= "/>\n";
    $i++;
  }

  $self->{table_title} .= "</TITLE>\n";
  return $self->{table_title};
}

#**********************************************************
#
# img($img, $name, $attr)
#**********************************************************
sub img {
  my $self = shift;
  my ($img, $name) = @_;

  my $img_path = ($img =~ s/^://) ? "$IMG_PATH/" : '';
  $img =~ s/\&/\&amp;/g;
  return "<img alt='$name' src='$img_path$img'/>";
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
  $self->{show} .= "<DATA>\n";
  $self->{show} .= $self->{rows};
  $self->{show} .= "</DATA>\n";
  $self->{show} .= "</TABLE>\n";

  if ($self->{pages}) {
    $self->{show} = $self->{show} . $self->{pages};
  }

  if ((defined($self->{NO_PRINT})) && (!defined($attr->{OUTPUT2RETURN}))) {
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
      GLOBAL_URL   - Global link
      TITLE        -

  Returns:
    String with element

=cut
#**********************************************************
sub button {
  my $self = shift;
  my ($name, $params, $attr) = @_;
  my $ex_attr = '';

  if ($attr->{ONLY_IN_HTML}) {
    return '';
  }

  if(! $params && ! $name) {
    return '';
  }

  $params = ($attr->{GLOBAL_URL}) ? $attr->{GLOBAL_URL} : "$params";
  $params = $self->link_former($params);

  $ex_attr = " TITLE='$attr->{TITLE}'" if (defined($attr->{TITLE}));

  my $button = "<BUTTON VALUE=\"$params\"$ex_attr>$name</BUTTON>";

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

  if ($type eq 'warning') {
    $type='info';
  }

  my $output = "<MESSAGE TYPE=\"$type\" CAPTION=\"$caption\">$message</MESSAGE>\n";

  if($attr->{OUTPUT2RETURN})  {
    return $output;
  }
  elsif ($self->{NO_PRINT}) {
    $self->{OUTPUT} .= $output;
    return $output;
  }
  else {
    print $output;
  }

  return 1;
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
    $self->{pages} .= ($i == $PG) ? "<b>$i</b>" : $self->button($i, "$argument&pg=$i") . '';
  }

  return "<PAGES>" . $self->{pages} . "</PAGES>\n";
}

#**********************************************************
=head2 date_fld2($base_name, $attr) - Make data field

=cut
#**********************************************************
sub date_fld2 {
  my $self = shift;
  my ($base_name, $attr) = @_;

  my ($mon, $curyear) = (localtime(time))[4,5];

  my $day   = sprintf("%.2d", $FORM{ $base_name . 'D' } || 1);
  my $month = sprintf("%.2d", $FORM{ $base_name . 'M' } || $mon);
  my $year  = $FORM{ $base_name . 'Y' } || $curyear + 1900;
  my $result = "<$base_name Y=\"$year\" M=\"$month\" D=\"$day\" />";
  my $mday;

  if ($FORM{$base_name}) {
    my $date = $FORM{$base_name};
    $self->{$base_name} = $date;
  }
  elsif (!$attr->{NO_DEFAULT_DATE}) {
    ($mday, $mon, $curyear) = (localtime(time + (($attr->{NEXT_DAY}) ? 86400 : 0)))[3,4,5];

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
<LOG_PRINT level="$level">
$text
</LOG_PRINT>
[END]
}

#**********************************************************
=head2 element($name, $value, $attr) - HTML element

=cut
#**********************************************************
sub element {
  my $self = shift;
  my (undef, $value, $attr) = @_;

  if ($attr->{ID}) {
    $value = "<$attr->{ID}>$value</$attr->{ID}>";
  }

  $self->{FORM_INPUT} = $value;

  if (defined($self->{NO_PRINT}) && (!defined($attr->{OUTPUT2RETURN}))) {
    $self->{OUTPUT} .= $self->{FORM_INPUT};
    $self->{FORM_INPUT} = '';
  }

  return $self->{FORM_INPUT};
}

#**********************************************************
=head2 tpl_show($tpl, $variables_ref, $attr) - show tamplate

  Arguments:
    $tpl           - template
    $variables_ref - variables_ref
    $attr          - [EX_VARIABLES]

=cut
#**********************************************************
sub tpl_show {
  my $self = shift;
  my ($tpl, $variables_ref, $attr) = @_;

  if ($attr->{CONFIG_TPL}) {
    return $CONFIG_TPL_SHOW->($self, $tpl, $variables_ref, $attr);
  }

  my $tpl_name = $attr->{ID} || '';

  if ($FORM{EXPORT_CONTENT} && $FORM{EXPORT_CONTENT} ne $tpl_name) {
    return '';
  }

  if ($attr->{TPL} && $attr->{MODULE}) {
    $tpl = $self->get_tpl($attr->{TPL}, $attr->{MODULE});
  }

  my $xml_tpl = "<INFO name=\"$tpl_name\">\n";

  if ($self->{new_model}) {
    foreach my $var (sort keys %$variables_ref) {
      if($var) {
        $xml_tpl .= "<$var>$variables_ref->{$var}</$var>\n";
      }
    }
  }
  else {
    my %displayed = ();
    while ($tpl =~ /\%(\w+)\%/g) {
      my $var = $1;
      next if ($displayed{$var});

      if ($var =~ /ACTION_LNG/) {
        next;
      }
      elsif (defined($variables_ref->{$var}) && $variables_ref->{$var} ne '') {
        $xml_tpl .= "<$var>$variables_ref->{$var}</$var>\n";
      }
      else {
        $xml_tpl .= "<$var/>";
      }
      $displayed{$var}=1;
    }
  }

  $tpl =~ s/&nbsp;/&#160;/g;
  $xml_tpl .= "</INFO>\n";

  if ($attr->{OUTPUT2RETURN}) {
    return $xml_tpl;
  }

  #  elsif (defined($attr->{notprint}) || ($self->{NO_PRINT} && $self->{NO_PRINT} == 1)) {
  elsif ($attr->{notprint} || defined($self->{NO_PRINT})) {
    $self->{OUTPUT} .= $xml_tpl;
    return $xml_tpl;
  }
  else {
    print $xml_tpl;
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
# letters_list();
#**********************************************************
sub letters_list {
  my ($self) = @_;

  return "";
}

#**********************************************************
# Mark text
#**********************************************************
sub color_mark {
  my $self = shift;
  my ($message, $color, $attr) = @_;

  return $message if ($attr->{SKIP_XML});

  return qq{<color_mark color="$color">$message</color_mark>};
}

#**********************************************************
=head2 table_header($header) - Show table column  titles with wort derectives

  Arguments:
    $header_arr - array of elements

=cut
#**********************************************************
sub table_header {
  my $self = shift;
  my ($header_arr) = @_;

  if ($FORM{EXPORT_CONTENT} && $FORM{EXPORT_CONTENT} ne $self->{ID}) {
    return '';
  }

  my $header = '';

  foreach my $element ( @{ $header_arr } ) {
    my ($name, $url)= split(/:/, $element, 2);
    $header .= $self->button($name, $url);
  }

  $header = "<table_header>$header</table_header>";

  return $header;
}

#**********************************************************
=head2  normalize_str($text)

=cut
#**********************************************************
sub normalize_str {
  my ($text) = @_;

  $text =~ s/\&#37/\%/g;

  return $text;
}
#**********************************************************
=head2  b($text)

=cut
#**********************************************************
sub b {
   my $self = shift;
   my ($text) = @_;

  return $text;
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
