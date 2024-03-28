package AXbills::JSON;

=head1 NAME

  JSON Visualiation Functions

=cut

use strict;
our (
  %FORM,
  %COOKIES,
  $SORT,
  $DESC,
  $PG,
  $PAGE_ROWS,
  $CONFIG_TPL_SHOW,
);

my $debug;
my %log_levels;
my $IMG_PATH='';
my $CONF;
my @table_rows = ();

#**********************************************************
# Create Object
#**********************************************************
sub new {
  my $class = shift;
  my ($attr) = @_;

  $IMG_PATH = (defined($attr->{IMG_PATH})) ? $attr->{IMG_PATH} : '../img/';
  $CONF = $attr->{CONF} if (defined($attr->{CONF}));

  my $self = { };
  bless($self, $class);

  if ($attr->{NO_PRINT}) {
    $self->{NO_PRINT} = 1;
  }

  if($attr->{FORM}) {
    %FORM = %{ $attr->{FORM} };
  }

  $self->{CHARSET} = (defined($attr->{CHARSET})) ? $attr->{CHARSET} : 'utf8';
  $self->{content_language} = $attr->{content_language} || 'en';

  if ($attr->{language}) {
    $self->{language} = $attr->{language};
  }
  elsif ($COOKIES{language}) {
    $self->{language} = $COOKIES{language};
  }
  else {
    $self->{language} = $CONF->{default_language} || 'english';
  }

  $self->{TYPE} = 'json' if (!$self->{TYPE});

  return $self;
}

#**********************************************************
=head2 form_input($name, $value)

  Arguments:
    $name,
    $value

  Results:
    Input form

=cut
#**********************************************************
sub form_input {
  my $self = shift;
  my ($name, $value) = @_;

  $value //= q{};
  $value =~ s/\\/\\\\/g;
  $value =~ s/\"/\\\\\\\"/g;

  $self->{FORM_INPUT} =  "{ \"$name\" : \"$value\" }";

  return $self->{FORM_INPUT};
}

#**********************************************************
=head2 form()

=cut
#**********************************************************
sub form {
  my $self == shift;
  my $form = shift;

  %FORM = %{ $form };

  return $self;
}

#**********************************************************
=head2 form_main($attr)

=cut
#**********************************************************
sub form_main {
  my $self = shift;
  my ($attr) = @_;

  if ($FORM{EXPORT_CONTENT}) {
    if($FORM{EXPORT_CONTENT} eq $attr->{EXPORT_CONTENT}) {
      return $attr->{CONTENT};
    }
    elsif( $FORM{EXPORT_CONTENT} ne $attr->{ID}) {
      return '';
    }
  }

  my @arr = ();
  if (defined($attr->{HIDDEN})) {
    my $H = $attr->{HIDDEN};
    while (my ($k, $v) = each(%$H)) {
      push @arr, $self->form_input($k, $v);
    }
  }

  if ($attr->{CONTENT}) {
    if ($attr->{CONTENT} !~ /^{/) {
      $attr->{CONTENT} = '{'.$attr->{CONTENT}.'}';
    }
    push @arr, $attr->{CONTENT};
  }

  if (defined($attr->{SUBMIT})) {
    my $H = $attr->{SUBMIT};
    while (my ($k, $v) = each(%$H)) {
      push @arr, $self->form_input($k, $v);
    }
  }

  my $tpl_id = $attr->{ID} || 'main_form';
  my $json_body = "[\n" . join(", \n", @arr) . "]";

  if($FORM{EXPORT_CONTENT}){
    push @{ $self->{JSON_OUTPUT} }, $attr->{CONTENT};
    return q{};
  }
  elsif (! $attr->{OUTPUT2RETURN}) {
    push @{ $self->{JSON_OUTPUT} }, {
      $tpl_id => $json_body
    };
    return q{};
  }

  return qq{ "$tpl_id" : $json_body };
}

#**********************************************************
=head2 form_textarea($name, $value, $attr)

=cut
#**********************************************************
sub form_textarea {
  my $self = shift;
  my ($name, $value, $attr) = @_;

  $self->form_input($name, $value);

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

  $self->{SELECT} = "\"$name\" : {\n";
  my @sel_arr = ();

  if (defined($attr->{SEL_OPTIONS})) {
    my $H = $attr->{SEL_OPTIONS};
    while (my ($k, $v) = each %$H) {
      push @sel_arr, "\"$k\" : \"$v\"";
    }
  }

  if (defined($attr->{SEL_ARRAY})) {
    my $H = $attr->{SEL_ARRAY};
    my $i = 0;

    foreach my $v (@$H) {
      my $id = (defined($attr->{ARRAY_NUM_ID})) ? $i : $v;
      $v =~ s/\n//g;
      push @sel_arr, "\"$id\" : \"$v\"";
      $i++;
    }
  }
  elsif (defined($attr->{SEL_MULTI_ARRAY})) {
    my $key = $attr->{MULTI_ARRAY_KEY};
    my $value = $attr->{MULTI_ARRAY_VALUE};
    my $H = $attr->{SEL_MULTI_ARRAY};

    foreach my $v (@$H) {
      my $val = "\"$v->[$key]\"";
      $val .= ": \"$v->[$value]\"";
      push @sel_arr, $val;
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
      my $val = "\"$k\" : \"";

      if ($attr->{EXT_PARAMS}) {
        while (my ($ext_k, undef) = each %{ $attr->{EXT_PARAMS} }) {
          $val .= " $ext_k=";
          $val .= $attr->{EXT_PARAMS}->{$ext_k}->{$k} if ($attr->{EXT_PARAMS}->{$ext_k}->{$k});
        }
      }

      $val .= "$k : " if (!$attr->{NO_ID});
      $val .= " $attr->{SEL_HASH}{$k}\"";
      push @sel_arr, $val;
    }
  }

  $self->{SELECT} .= join(",\n  ", @sel_arr);
  $self->{SELECT} .= "}\n";

  if ($attr->{OUTPUT2RETURN}) {
    return $self->{SELECT} || q{};
  }

  return '';
}


#**********************************************************
=head2 menu2($menu_items, $menu_args, $permissions, $attr)

=cut
#**********************************************************
sub menu2 {
  my $self = shift;
  my ($menu_items, $menu_args, $permissions, $attr) = @_;
  $self->menu($menu_items, $menu_args, $permissions, $attr);
}

#**********************************************************
=head2 menu2($menu_items, $menu_args, $permissions, $attr)

=cut
#**********************************************************
sub menu {
  my $self = shift;
  my ($menu_items, undef, $permissions, $attr) = @_;

  return 0 if ($FORM{index} > 0);

  my @menu_arr       = ();
  my $menu_navigator = '';
  my $menu_text      = '';

  return $menu_navigator, $menu_text if ($FORM{NO_MENU});

  my $EX_ARGS = (defined($attr->{EX_ARGS})) ? $attr->{EX_ARGS} : '';
  $EX_ARGS =~ s/&sid=\w+//g;
  my $fl = $attr->{FUNCTION_LIST};

  my %new_hash = ();
  while ((my ($findex, $hash) = each(%$menu_items))) {
    while (my ($parent, $val) = each %$hash) {
      $new_hash{$parent}{$findex} = $val;
    }
  }

  my $h          = $new_hash{0};
  my @last_array = ();
  my @menu_sorted = sort { $h->{$a} cmp $h->{$b} } keys %$h;

  for (my $parent = 0 ; $parent < $#menu_sorted + 1 ; $parent++) {
    my $val = $h->{ $menu_sorted[$parent] };

    my $level  = 0;
    my $prefix = '';
    my $ID     = $menu_sorted[$parent];

    next if ((!defined($attr->{ALL_PERMISSIONS})) && (!$permissions->{ $parent - 1 }) && $parent == 0);
    push @menu_arr,   " \"$fl->{$ID}\": {
      \"ID\"       : \"$ID\", "

      . (($EX_ARGS) ? "\"EX_ARGS-$EX_ARGS-\"  : \"" . $self->link_former($EX_ARGS) . "\"," : '')

      . "\"DESCRIBE\" : \"$val\",
      \"TYPE\"     : \"MAIN\"\n }";

    if (defined($new_hash{$ID})) {
      $level++;
      $prefix .= "   ";
      label:
      my $mi = $new_hash{$ID};

      while (my ($k, $val2) = each %$mi) {
        push @menu_arr, "$prefix \"sub_" . $fl->{$k} . "\": {
          \"ID\"       : \"$k\","

          . (($EX_ARGS) ? "\"EX_ARGS\"  : \"" . $self->link_former($EX_ARGS) . "\"," : q{})

          . "\"DESCRIBE\" : \"$val2\",
          \"TYPE\"     : \"SUB\",
          \"PARENT\"   : \"$ID\"\n  }";

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

  $menu_text .= qq{"SID" : { "sid" : "$self->{SID}" }, \n} if ($self->{SID});
  $menu_text .= "\"MENU\" : {" . join(",\n  ", @menu_arr) ."\n}";

  push @{ $self->{JSON_OUTPUT} }, $menu_text;

  return ('', '');
}


#**********************************************************
=head2 header($attr) - heder off main page

=cut
#**********************************************************
sub header {
  my $self       = shift;
  my ($attr)     = @_;

  my $CHARSET = (defined($attr->{CHARSET})) ? $attr->{CHARSET} : $self->{CHARSET} || 'utf8';
  $CHARSET =~ s/\s//g;

  if ($FORM{DEBUG}) {
    print "Content-Type: text/plain\n\n";
  }

  $self->{header}  = "Content-Type: application/json; charset=$CHARSET\n";
  $self->{header} .= "Access-Control-Allow-Origin: *" . "\n";
  $self->{header} .= "Access-Control-Allow-Headers: *\n";
  $self->{header} .= "Status: $attr->{STATUS}\n" if $attr->{STATUS};
  $self->{header} .= "\n";

  return $self->{header};
}

#**********************************************************
=head2 table() - Init table object

=cut
#**********************************************************
sub table {
  my $proto  = shift;
  my ($attr)    = @_;

  my $class  = ref($proto) || $proto;
  my $parent = ref($proto) && $proto;

  my $self = {};

  bless($self, $class);
  $self->{prototype} = $proto;
  $self->{HTML}      = $parent;
  $self->{NO_PRINT}  = $proto->{NO_PRINT};

  $self->{rows} = '';
  $self->{table} = '';

  if ($#table_rows > -1 ) {
    $self->{table} = '';
    @table_rows   = ();
  }

  if ($attr->{FIELDS_IDS}) {
    $self->{FIELDS_IDS}  = $attr->{FIELDS_IDS};
    $self->{TABLE_TITLE} = $attr->{title} || $attr->{title_plain};
  }

  if ($attr->{rows}) {
    foreach my $line (@{$attr->{rows}}) {
      $self->addrow(@$line);
    }
  }

  $self->{ID} = $attr->{ID} || q{};

  if ($attr->{SELECT_ALL}) {
    $self->{SELECT_ALL}=$attr->{SELECT_ALL};
  }

  unless ($self->{ID} && $FORM{EXPORT_CONTENT} eq $self->{ID}) {
    if ($attr->{MAIN_BODY}) {
      $self->{table} .= "{ \"NAME\" : \"TABLE_" . $self->{ID} . "\",";
    }
    else {
      $self->{table} .= "\"TABLE_" . $self->{ID} . "\" :{";
    }
  }

  if (defined($attr->{caption})) {
    $self->{table} .= " \"CAPTION\" : \"$attr->{caption}\",\n";
  }

  if (defined($self->{ID})) {
    $self->{table} .= " \"ID\" : \"$self->{ID}\",\n";
  }

  if (defined($attr->{title})) {
    $self->{table} .= $self->table_title($SORT, $DESC, $PG, $attr->{title}, $attr->{qs});
  }
  elsif (defined($attr->{title_plain})) {
    $self->{table} .= $self->table_title_plain($attr->{title_plain});
  }

  if (ref($self->{FIELDS_IDS}) eq 'HASH') {
    $self->{table} .= "\"EXT_DATA\" : [";

    foreach (keys %{ $self->{FIELDS_IDS} }) {
      $self->{table} .= "\"$self->{FIELDS_IDS}{$_}\",\n";
    }

    $self->{table} .= "]";
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
=head2 addrow(@row)

=cut
#**********************************************************
sub addrow {
  my $self = shift;
  my (@row) = @_;

  if ($self->{SKIP_EXPORT_CONTENT}) {
    delete ($self->{SKIP_EXPORT_CONTENT});
    return '';
  }

  my @formed_rows   = ();

  my $select_present = ($self->{SELECT_ALL}) ? 1 : 0;

  for (my $i=0; $i<=$#row; $i++) {
    my $val = $row[$i+$select_present];
    if ($self->{FIELDS_IDS}) {
      if ($self->{TABLE_TITLE}->[$i]) {
        if(! $self->{FIELDS_IDS}->[$i]) {
          next;
        }

        $val =~ s/[\n\r]/ /g;
        $val =~ s/\t/ /g;

        if ($val =~ /^{(.+) : (.+)}$/) {
          push @formed_rows, "\"$self->{FIELDS_IDS}->[$i]\" : $val";
        }
        elsif ($val =~ /^{(.+)}$/) {
          push @formed_rows, $1;
        }
        else {
          $val =~ s/\"/\\\"/g;
          push @formed_rows, "\"$self->{FIELDS_IDS}->[$i]\" : \"$val\"";
        }
      }
    }
    else {
      if ($self->{caption}[$i] && $self->{caption}[$i] !~ /\-/) {
        $val = "\"$val\"" if $val !~ /^{(.+) : (.+)}$/;
        push @formed_rows, '"' . $self->{caption}[$i] ."\" : $val";
      }
    }
  }

  push @table_rows, '{'. join(', ', @formed_rows) .'}' if($#formed_rows > -1);
  push @{ $self->{table_rows} }, '{'. join(', ', @formed_rows) .'}' if($#formed_rows > -1);

  return $self->{rows};
}

#**********************************************************
=head2 addtd(@rows)

=cut
#**********************************************************
sub addtd {
  my $self  = shift;
  my (@row) = @_;

  my @formed_rows   = ();
  my $select_present = ($self->{SELECT_ALL}) ? 1 : 0;

  for (my $i=0; $i<=$#row+$select_present+1; $i++) {
    my $val = $row[$i+$select_present];
    if ($self->{FIELDS_IDS}) {
      if ($self->{FIELDS_IDS}->[$i] && $self->{TABLE_TITLE}->[$i] && $self->{TABLE_TITLE}->[$i] ne '-' ) {
        $val =~ s/[\n\r]/ /g;
        $val =~ s/\t/ /g;
        push @formed_rows, "\"$self->{FIELDS_IDS}->[$i]\" : \"$val\"";
      }
    }
  }

  push @{ $self->{table_rows} }, '{'. join(', ', @formed_rows) .'}';

  return \@formed_rows;
}

#**********************************************************
=head2 th($value, $attr) Extendet add rows

=cut
#**********************************************************
sub th {
  my $self = shift;
  my ($value) = @_;

  return $self->td($value, { TH => 1 });
}

#**********************************************************
=head2 td($value, $attr) - Extendet add rows

=cut
#**********************************************************
sub td{
  shift;
  my ($value) = @_;

  my $td = '';
  if ( defined( $value ) ){
    $td .= $value;
    $td =~ s/\\/\\\\/g;
    $td =~ s/\"/\\\"/g;
    $td =~ s/\t/ /g;
  }

  return $td;
}

#**********************************************************
=head2 table_title_plain($caption)

  Arguments:
    $caption - ref to caption array

  Results:
    Table Title

=cut
#**********************************************************
sub table_title_plain {
  my $self = shift;
  my ($caption) = @_;

  $self->{table_title} = "\"TITLE\" : [\n";

  my @table_arr = ();
  foreach my $line (@$caption) {
    push @table_arr, "\"$line\"";
  }

  $self->{table_title} .= join(",", @table_arr) ." ],\n";

  return $self->{table_title};
}

#**********************************************************
=head2 table_title($sort, $desc, $pg, $caption, $qs) - Show table column  titles with wort derectives

  Arguments:
    $sort - sort column
    $desc - DESC / ASC
    $pg - page id
    $caption - array off caption

=cut
#**********************************************************
sub table_title {
  my $self = shift;
  my (undef, undef, undef, $caption) = @_;

  $self->{table_title} = "\"TITLE\" : [\n";

  my @table_arr = ();

  foreach my $line (@$caption) {
    if ($line) {
      push @table_arr, "\"$line\"" unless ($line =~ /\-/);
    }
  }

  $self->{table_title} .= join(",", @table_arr) ." ],\n";
  $self->{caption} = $caption;

  return $self->{table_title};
}

#**********************************************************
=head2 show($attr) - Show table content

=cut
#**********************************************************
sub show {
  my $self = shift;
  my ($attr) = @_;

  if (($FORM{EXPORT_CONTENT} && $FORM{EXPORT_CONTENT} ne $self->{ID}) || ($attr->{DUBLICATE_DATA})) {
    return '';
  }

  if($self->{table_rows}) {
    @table_rows = @{ $self->{table_rows} };
  }

  my $json_body ='';

  if (ref($self->{FIELDS_IDS}) eq 'HASH') {
    $json_body = $self->{table};
  }
  else {
    $json_body = $self->{table}
      . "\"DATA_1\" : [\n  "
      . join(",\n ", @table_rows)
      . "\n] ";
  }

  $json_body .= '}' if (!$FORM{EXPORT_CONTENT});

  if (! $attr->{OUTPUT2RETURN})  {
    push @{ $self->{HTML}{JSON_OUTPUT} }, $json_body;
    return '';
  }

  return $json_body;
}

#**********************************************************
=head2 color_mark($text, $color) - colors text

  Arguments:
    $text, $color -

  Returns:
    $text

=cut
#**********************************************************
sub color_mark {
  return $_[1] || '';
}

#**********************************************************
=head2 b($text) - colors text

  Arguments:
    $text

  Returns:
    $text

=cut
#**********************************************************
sub b {
  return $_[1] || '';
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

  $params = ($attr->{GLOBAL_URL}) ? $attr->{GLOBAL_URL} : "$params";
  $params = $self->link_former($params);

  $ex_attr = " TITLE='$attr->{TITLE}'" if (defined($attr->{TITLE}));
  my $button = "\"$name\" : {
                    \"url\" : \"$params\",
                    \"title\" : \"$attr->{TITLE}\"
                    }\n";

  $button = "$name";

  return $button;
}

#**********************************************************
=head2 message($self, $type, $caption, $message) Show message box

  $type - info, err

=cut
#**********************************************************
sub message {
  my $self = shift;
  my ($type, $caption, $message, $attr) = @_;

  if ($type eq 'warning') {
    $type='info';
  }

  if ($FORM{EXPORT_CONTENT}) {
    return q{};
  }

  my $id = ($attr->{ID}) ? qq{,"ID" : "$attr->{ID}" } : '';

  if ($attr->{RESPONCE_PARAMS} && ref $attr->{RESPONCE_PARAMS} eq 'HASH'){
    $id .= ',' . join (',', map { qq{ "$_" : "$attr->{RESPONCE_PARAMS}->{$_}" } } (keys %{$attr->{RESPONCE_PARAMS}})  );
  }

  my $tpl_id = 'MESSAGE' . (($attr->{ID}) ? '_'.$attr->{ID} : q{});
  my $json_body =  qq/{
                      "type"    : "MESSAGE",
                      "message_type" : "$type",
                      "caption" : "$caption",
                      "messaga" : "$message"
                      $id
                    }/;

  $json_body =~ s/\n/ /gm;

  if (! $attr->{OUTPUT2RETURN}) {
    push @{ $self->{JSON_OUTPUT} }, { $tpl_id => $json_body };
    return q{};
  }
  else {
    return qq{ "$tpl_id" : $json_body };
  }
}

#**********************************************************
=head2 pages($count, $argument)- Make pages and count total records

=cut
#**********************************************************
sub pages {
  my $self = shift;
  my ($count, $argument, $attr) = @_;

  if (defined($attr->{recs_on_page})) {
    $PAGE_ROWS = $attr->{recs_on_page};
  }

  my $begin = 0;
  my @tpl_arr = ();
  return '' if ($count < $PAGE_ROWS);
  $begin = ($PG - $PAGE_ROWS * 3 < 0) ? 0 : $PG - $PAGE_ROWS * 3;

  for (my $i = $begin ; ($i <= $count && $i < $PG + $PAGE_ROWS * 10) ; $i += $PAGE_ROWS) {
    push @tpl_arr, $self->button($i, "$argument&pg=$i") if ($i != $PG);
  }

  return "\"PAGES\": {" . join(",\n ", @tpl_arr) . "}\n";
}

#**********************************************************
=head2 date_fld2($base_name) - Make data field

=cut
#**********************************************************
sub date_fld2 {
  my $self = shift;
  my ($base_name, $attr) = @_;

  my ($sec, $min, $hour, $mday, $mon, $curyear, $wday, $yday, $isdst) = localtime(time);

  my $day   = sprintf("%.2d", $FORM{ $base_name . 'D' } || 1);
  my $month = sprintf("%.2d", $FORM{ $base_name . 'M' } || $mon);
  my $year  = $FORM{ $base_name . 'Y' } || $curyear + 1900;
  my $result = "$base_name Y=\'$year\' M=\'$month\' D=\'$day\' ";

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
=head2 log_print($level, $text)

=cut
#**********************************************************
sub log_print {
  shift;
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
=head2 element($name, $value, $attr)

=cut
#********************************`**************************
sub element {
  my $self = shift;
  my ($name, $value, $attr) = @_;

  if ($attr->{ID}) {
    $value = " \"$name\" : [ $value ] ";
  }

  $self->{FORM_INPUT} = "";

  if (defined($self->{NO_PRINT}) && (!defined($attr->{OUTPUT2RETURN}))) {
    $self->{OUTPUT} .= $self->{FORM_INPUT};
    $self->{FORM_INPUT} = '';
  }

  return $self->{FORM_INPUT};
}

#**********************************************************
=head2 tpl_show($tpl, $variables_ref, $attr) - show tamplate

=cut
#**********************************************************
sub tpl_show {
  my $self = shift;
  my ($tpl, $variables_ref, $attr) = @_;
  my @val_arr = ();

  if ($attr->{CONFIG_TPL}) {
    return $CONFIG_TPL_SHOW->($self, $tpl, $variables_ref, $attr);
  }

  if ($attr->{TPL} && $attr->{MODULE}) {
    $tpl = $self->get_tpl($attr->{TPL}, $attr->{MODULE});
  }

  my $tpl_name = $attr->{ID} || "";
  my $tpl_id = $tpl_name || "_INFO";
  my $no_subject = $attr->{NO_SUBJECT} || '--';

  $tpl_name = "HASH" if (! $attr->{MAIN});

  if ($FORM{EXPORT_CONTENT} && $FORM{EXPORT_CONTENT} ne $tpl_id) {
    return '';
  }

  my $xml_tpl = "";

  if ($tpl_name) {
    $xml_tpl = (($self->{tpl_num} && ! $attr->{SKIP_D}) ? "\n(,) \n" : '' ) ."\"$tpl_name\" :";
    $self->{tpl_num}++;
  }

  while ($tpl =~ /\%(\w+)\%/g) {
    my $var = $1;

    if ($var =~ /ACTION_LNG|CID_PATTERN|CPE_PATTERN/) {
      next;
    }
    elsif ($variables_ref->{$var} =~ m/^\{\n\}/i) {
      next;
    }
    elsif ($variables_ref->{$var}) {
      if ($variables_ref->{$var} !~ m/\{/g) {
        $variables_ref->{$var} =~ s/\\/\\\\/g;
        $variables_ref->{$var} =~ s/\"/\\\\\\\"/g;
        $variables_ref->{$var} =~ s/\n//g;

        my $value = "\"$var\" : \"$variables_ref->{$var}\"";
        if(! grep { $_ eq $value } @val_arr) {
          push @val_arr, $value;
        }
      }
      elsif ($variables_ref->{$var} =~ m/^\"TABLE/i) {
        push @val_arr, "\"$var\" : { $variables_ref->{$var} }";
      }
      elsif ($variables_ref->{$var} =~ m/MESSAGE/i) {
        push @val_arr, "\"__$var\" : { $variables_ref->{$var} }";
      }
      elsif (($variables_ref->{$var} !~ m/^\"\S+\" : \{/ig) || ($variables_ref->{$var} !~ m/\"\S+\" : \{/ig)) {
        push @val_arr, "\"__$var\" : [ $variables_ref->{$var} ]";
      }
      else {
        my $value = "\"_$var\" : $variables_ref->{$var}";
        push @val_arr, $value;
      }
    }
  }

  if ($variables_ref && !$variables_ref->{MESSAGE} && $no_subject) {
    push @val_arr, "\"MESSAGE\" : \"$no_subject\"";
  }

  my $json_body = q{};

  if($#val_arr > -1) {
    $json_body = "{\n";
    $json_body .= '' . join(",\n  ", @val_arr);
    $json_body .= "}\n";
  }

  $xml_tpl .= $json_body."\n";

  if (! $attr->{OUTPUT2RETURN}) {
    if($json_body) {
      push @{$self->{JSON_OUTPUT}}, {
        $tpl_id => $json_body
      };
    }
    return ;
  }
  elsif ($self->{SELECT}) {
    return '';
  }
  else {
    return qq{ "$tpl_id" : $json_body };
  }
}

#**********************************************************
=head2 table_header($header, $attr) - Show table column  titles with wort derectives

  Arguments:
    $header_arr - array of elements

=cut
#**********************************************************
sub table_header {
  my $self = shift;

  my $header = '';
  if ($FORM{EXPORT_CONTENT} && $FORM{EXPORT_CONTENT} ne $self->{ID}) {
    return '';
  }

  return $header;
}

#**********************************************************
=head2 fetch() - Fetch cache data

=cut
#**********************************************************
sub fetch  {
  my $self = shift;
  my ($attr) = @_;

  my @output_arr = ();
  my %dup_keys;

  foreach my $obj (@{$self->{JSON_OUTPUT}}) {
    if (ref $obj eq 'HASH') {
      my ($key, $val) = each %$obj;
      push(@{$dup_keys{$key}}, $val);
    }
    else {
      push @output_arr, $obj;
    }
  }

  foreach my $key (keys %dup_keys) {
    if (scalar(@{$dup_keys{$key}}) == 1) {
      push @output_arr, qq{"$key": $dup_keys{$key}->[0]};
    }
    else {
      push @output_arr, qq{"$key": [} . join(',', @{$dup_keys{$key}}) . ']';
    }
  }

  my $result = join(",\n", @output_arr);

  if ($FORM{EXPORT_CONTENT} && $#output_arr == 0) {
    $result = join(",\n\n", @output_arr);
    $result = '{' . $result . '}' if ($result !~ /^{/);
  }
  elsif($attr->{FULL_RESULT}) { #XXX what is this?
    $result = join(",\n\n", @output_arr);
    if ($result !~ /^{/) {
      $result = '{' . $result . '}';
    }
  }
  else {
    $result = "{\n". join(",\n\n", @output_arr) ."\n}";
  }

  if($attr->{DEBUG}) {
    $self->{RESULT} = $result;
  }
  else {
    print $result;
  }

  return $self;
}

#**********************************************************
=head2  AUTOLOAD Autoload secondary funtions

=cut
#**********************************************************
sub AUTOLOAD {
  our $AUTOLOAD;

  return if ($AUTOLOAD =~ /::[A-Z]+$/);
  my $function = $AUTOLOAD;

  if($function =~ /table_header|progress_bar|/) {
    return q{};
  }

  my ($self, $data) = @_;

  return $data;
}

DESTROY {}

1
