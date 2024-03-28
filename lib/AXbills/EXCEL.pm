package AXbills::EXCEL;

=head1 NAME

  EXCEL output Functions

=cut

use strict;
our (
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
);

use Encode qw(decode decode_utf8);

our $VERSION = 2.02;
my $CONF;
my $workbook;
my $IMG_PATH = '';

use Spreadsheet::WriteExcel;
my Spreadsheet::WriteExcel $worksheet;

my %text_colors = (
  'text-green'  => 'green',
  'text-red'    => 'red',
  'text-danger' => 'red',
  '#FF0000'     => 'red',
);

my %format_class = (
  'text-center' => {
    align  => 'center',
    valign => 'vcenter'
  },
  'text-right'  => {
    align => 'right'
  },
  'text-bold'   => {
    bold   => 1,
    border => 1
  },
  'vertical-rl' => {
    rotation => 0
  },
  'font-italic' => {
    italic => 1,
  },
  'table-info'  => {
    bg_color => 'silver'
  }
);

#**********************************************************
# Create Object
#**********************************************************
sub new {
  my $class = shift;
  my ($attr) = @_;

  Spreadsheet::WriteExcel->import();

  require AXbills::HTML;
  AXbills::HTML->import();

  $CONF = $attr->{CONF} if (defined($attr->{CONF}));

  my $self = {};
  bless($self, $class);

  if ($attr->{NO_PRINT}) {
    $self->{NO_PRINT} = 1;
  }

  $FORM{_export}='xml';

  if ($attr->{language}) {
    $self->{language} = $attr->{language};
  }
  elsif ($COOKIES{language}) {
    $self->{language} = $COOKIES{language};
  }
  else {
    $self->{language} = $CONF->{default_language} || 'english';
  }

  $self->{TYPE}='excel' if(! $self->{TYPE});

  return $self;
}

#**********************************************************
=head2 form_input($name, $value, $attr)

=cut
#**********************************************************
sub form_input {
  my $self = shift;
  my (undef, $value) = @_;

  return $value;

  # my $type  = (defined($attr->{TYPE}))  ? $attr->{TYPE}             : 'text';
  # my $state = (defined($attr->{STATE})) ? ' checked="1"'            : '';
  # my $size  = (defined($attr->{SIZE}))  ? " SIZE=\"$attr->{SIZE}\"" : '';
  # $self->{FORM_INPUT} = "<input type=\"$type\" name=\"$name\" value=\"$value\"$state$size/>";
  #
  # if (defined($self->{NO_PRINT}) && (!defined($attr->{OUTPUT2RETURN}))) {
  #   $self->{OUTPUT} .= $self->{FORM_INPUT};
  #   $self->{FORM_INPUT} = '';
  # }
  #
  # return $self->{FORM_INPUT};
}

#**********************************************************
=head2 form_main($attr) HTML Input form

=cut
#**********************************************************
sub form_main {
  my $self = shift;
  my ($attr) = @_;

  if ($FORM{EXPORT_CONTENT} && $FORM{EXPORT_CONTENT} ne $attr->{ID}) {
    return '';
  }

  if ($attr->{CONTENT}) {
    $self->{FORM} .= $attr->{CONTENT};
  }

  if (defined($self->{NO_PRINT})) {
    $self->{OUTPUT} .= $self->{FORM};
    $self->{FORM} = '';
  }

  return $self;
}

#**********************************************************
=head2 form_select($name, $attr)

=cut
#**********************************************************
sub form_select {
  my $self = shift;
  my ($name, $attr) = @_;

  #my $ex_params = (defined($attr->{EX_PARAMS})) ? $attr->{EX_PARAMS} : '';

  $self->{SELECT} = '';

  if (defined($attr->{SEL_OPTIONS})) {
    my $H = $attr->{SEL_OPTIONS};
    while (my ($k, $v) = each %$H) {
      $self->{SELECT} .= "$k:$v\n";
    }
  }

  if (defined($attr->{SEL_ARRAY})) {
    my $H = $attr->{SEL_ARRAY};
    my $i = 0;
    foreach my $v (@$H) {
      my $id = (defined($attr->{ARRAY_NUM_ID})) ? $i : $v;
      $self->{SELECT} .= "$id:$v\n";
      $i++;
    }
  }
  elsif (defined($attr->{SEL_MULTI_ARRAY})) {
    my $key   = $attr->{MULTI_ARRAY_KEY};
    my $value = $attr->{MULTI_ARRAY_VALUE};
    my $H     = $attr->{SEL_MULTI_ARRAY};

    foreach my $v (@$H) {
      $self->{SELECT} .= "$v->[$key]:$v->[$value]\n";
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
      $self->{SELECT} .= "$k:";

      if ($attr->{EXT_PARAMS}) {
        while (my ($ext_k, $ext_v) = each %{ $attr->{EXT_PARAMS} }) {
          $self->{SELECT} .= " $ext_k='";
          $self->{SELECT} .= $attr->{EXT_PARAMS}->{$ext_k}->{$k} if ($attr->{EXT_PARAMS}->{$ext_k}->{$k});
          $self->{SELECT} .= "'";
        }
      }

      $self->{SELECT} .= "$k:" if (!$attr->{NO_ID});
      $self->{SELECT} .= "$attr->{SEL_HASH}{$k}\n";
    }
  }

  return $self->{SELECT};
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
=head2 menu($menu_items, $menu_args, $permissions, $attr)

=cut
#**********************************************************
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
    my $val1 = $h->{ $menu_sorted[$parent] };

    my $level  = 0;
    my $prefix = '';
    my $ID     = $menu_sorted[$parent];

    next if ((!defined($attr->{ALL_PERMISSIONS})) && (!$permissions->{ $parent - 1 }) && $parent == 0);
    $menu_text .= "<MENU NAME=\"$fl->{$ID}\" ID=\"$ID\" EX_ARGS=\"" . $self->link_former($EX_ARGS) . "\" DESCRIBE=\"$val1\" TYPE=\"MAIN\"/>\n ";
    if (defined($new_hash{$ID})) {
      $level++;
      $prefix .= "   ";
      label:
      my $mi = $new_hash{$ID};

      while (my ($k, $val) = each %$mi) {
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
=head2 make_charts()

=cut
#**********************************************************
sub make_charts {

}

#**********************************************************
=head2 chart()

=cut
#**********************************************************
sub chart {

}

#**********************************************************
=head2 header($attr) - header off main page

=cut
#**********************************************************
sub header {
  my $self       = shift;
  #my ($attr)     = @_;

  if ($FORM{DEBUG}) {
    print "Content-Type: text/plain\n\n";
  }

  my $filename     =  ($self->{ID}) ? $self->{ID}.'.xls' : ($FORM{EXPORT_CONTENT}) ?  $FORM{EXPORT_CONTENT}.'.xls' : int(rand(10000000)).'.xls';
  $self->{header}  = "Content-Type: application/vnd.ms-excel; filename=$filename\n";
  $self->{header} .= "Cache-Control: no-cache\n";
  $self->{header} .= "Content-disposition: attachment;filename=\"$filename\"\n\n";

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

  if (defined($attr->{rowcolor})) {
    $self->{rowcolor} = $attr->{rowcolor};
  }

  $self->{ID}=$attr->{ID};

  if ($FORM{EXPORT_CONTENT} && $FORM{EXPORT_CONTENT} ne $self->{ID}) {
    return $self;
  }

  if ($attr->{SELECT_ALL}) {
    $self->{SELECT_ALL}=$attr->{SELECT_ALL};
  }

  $self->{AUTOFIT_COLUMNS} = $attr->{AUTOFIT_COLUMNS} if $attr->{AUTOFIT_COLUMNS};
  $self->{row_number} = 1;
  $self->{col_num}    = 0;

  $self->{closest_col_num} = 0;
  $self->{most_merge_rows} = 1;

  # Create a new Excel workbook
  $workbook = Spreadsheet::WriteExcel->new(\*STDOUT);

  # Add a worksheet
  $worksheet = $workbook->add_worksheet();
  $worksheet->add_write_handler(qr/.+/, \&_store_string_widths);

  if ($attr->{title} || $attr->{title_plain}) {
    $self->{title} = $attr->{title};
    $self->table_title($SORT, $DESC, $PG, $attr->{title}, $attr->{qs});
  }

  if ($attr->{rows}) {
    foreach my $line (@{ $attr->{rows} }) {
      $self->addrow(@$line);
    }
  }

  return $self;
}

#**********************************************************
=head2 addrows(@row)

=cut
#**********************************************************
sub addrow {
  my $self = shift;
  my (@row) = @_;

  # $self->{row_number}++;

  if (! $worksheet) {
    return $self;
  }

  $worksheet->set_column(0, 3, 25);

  my $col_shift = ($self->{SELECT_ALL}) ? 1 : 0;

  for (my $col_num = 0; $col_num <= $#row; $col_num++) {
    my $val = $row[$col_num + $col_shift];
    my $format = $workbook->add_format( text_wrap => 1 );

    if (ref $val eq 'HASH') {
      if ($val->{merge_rows} || $val->{merge_cols}) {
        $self->_merge_range($val, $format);
        next;
      }
      else {
        $format = $workbook->add_format(%{$val->{format}}) if $val->{format} && ref $val->{format} eq 'HASH';
        $val = $val->{value};
      }
    }

    if (!$self->{title}->[$self->{col_num}] || ($self->{title}->[$self->{col_num}] && $self->{title}->[$self->{col_num}] eq '-')) {
      next if !$self->{skip_empty_col};
    }

    if($val =~ /\[(.+)\|(.{0,100})\]/) {
      $worksheet->write_url( $self->{row_number}, $self->{col_num}, $SELF_URL .'?'. $1, decode_utf8($2));
    }
    elsif($val =~ /_COLOR:(.+):(.+)/) {
      my $color  = $1;
      my $text   = $2;

      my $color_format = $workbook->add_format(
        color     => ($color =~ /^#(\d+)/) ? $1 : $text_colors{$color},
        size      => 10,
        text_wrap => 1,
        #bold => 1
      );

      if ($text =~ /^=/) { #to prevent writing strings starting with '=' as formulas, because we never actually use formulas
        $worksheet->write_string( $self->{row_number}, $self->{col_num}, decode_utf8( $text ), $color_format || undef );
      }
      else {
        $worksheet->write( $self->{row_number}, $self->{col_num}, decode_utf8( $text ), $color_format || undef );
      }
    }
    else {
      if($val =~ /^0/  ||
         $val =~ /^=/) { #to prevent writing strings starting with '=' as formulas, because we never actually use formulas
        $worksheet->write_string( $self->{row_number}, $self->{col_num}, decode_utf8( $val ), $format || undef );
      }
      else {
        $worksheet->write( $self->{row_number}, $self->{col_num}, decode_utf8( $val ), $format || undef );
      }
    }

    print "addrow: $self->{row_number} col: $self->{col_num} = $val\n" if ($FORM{DEBUG});
    $self->{col_num}++;
  }

  $self->{row_number}++;
  $self->{col_num} = $self->{closest_col_num} || 0;

  if ($self->{row_number} >= $self->{most_merge_rows}) {
    $self->{closest_col_num} = 0;
    $self->{most_merge_rows} = 1;
  }

  return $self;
}

#**********************************************************
=head2 td($value, $attr)

=cut
#**********************************************************
sub td {
  my $self = shift;
  my ($value, $attr) = @_;

  my $td = { value => $value, format => {} };

  if ($attr->{class}) {
    my @classes = split('\s', $attr->{class});
    foreach my $class (@classes) {
      $td->{format} = { %{$td->{format}}, %{$format_class{$class}} } if $format_class{$class};
    }
  }

  $td->{merge_cols} = $attr->{colspan} - 1 if $attr->{colspan};
  $td->{merge_rows} = $attr->{rowspan} - 1 if $attr->{rowspan};
  $td->{col_num} = $attr->{col_num} if $attr->{col_num};

  return $td;
}

#**********************************************************
=head2 addtd(@row)

=cut
#**********************************************************
sub addtd {
  my $self  = shift;
  my (@row) = @_;

  my $select_present = ($self->{SELECT_ALL}) ? 1 : 0;

  for (my $i = 0; $i <= $#row; $i++) {
    my $format = $workbook->add_format( text_wrap => 1 );
    my $val = $row[($i + $select_present)];

    if (ref $val eq 'HASH') {
      if ($val->{merge_rows} || $val->{merge_cols}) {
        $self->_merge_range($val, $format);
        next;
      }
      else {
        $format = $workbook->add_format(%{$val->{format}}) if $val->{format} && ref $val->{format} eq 'HASH';
        $val = $val->{value};
      }
    }

    if(!$self->{title}->[$self->{col_num}] || ($self->{title}->[$self->{col_num}] && $self->{title}->[$self->{col_num}] eq '-')) {
      next if !$self->{skip_empty_col};
    }

    if ($val =~ /\[(.+)\|(.{0,100})\]/) {
      $worksheet->write_url($self->{row_number}, $self->{col_num}, $SELF_URL . '?' . $1, decode('utf8', $2));
    }
    elsif ($val =~ /_COLOR:([a-z0-9\-#]+):(.+)/i) {
      my $color = $1;
      my $text = $2;

      my $color_format = $workbook->add_format(
        color     => ($color =~ /^#(\d+)/) ? $1 :$text_colors{$color},
        size      => 10,
        text_wrap => 1
      );

      if ($text =~ /^=/) { #to prevent writing strings starting with '=' as formulas, because we never actually use formulas
        $worksheet->write_string($self->{row_number}, $self->{col_num}, decode('utf8', $text), $color_format || undef);
      }
      else {
        $worksheet->write($self->{row_number}, $self->{col_num}, decode('utf8', $text), $color_format || undef);
      }
    }
    else {
      if ($val =~ /^=/) { #to prevent writing strings starting with '=' as formulas, because we never actually use formulas
        $worksheet->write_string($self->{row_number}, $self->{col_num}, decode('utf8', $val), $format || undef);
      }
      else {
        $worksheet->write($self->{row_number}, $self->{col_num}, decode('utf8', $val), $format || undef);
      }
    }
    print "addtd: $self->{row_number} col: $self->{col_num} = $val\n" if ($FORM{DEBUG});
    $self->{col_num}++;
  }

  $self->{row_number}++;
  $self->{col_num} = $self->{closest_col_num} || 0;

  if ($self->{row_number} >= $self->{most_merge_rows}) {
    $self->{closest_col_num} = 0;
    $self->{most_merge_rows} = 1;
  }

  return $self;
}

#**********************************************************
=head2 _merge_range($td)

=cut
#**********************************************************
sub _merge_range {
  my $self = shift;
  my ($td) = @_;

  my $format = $workbook->add_format( color => 'black', %{ $td->{format} // {} });

  $td->{value} = decode('utf8', $td->{value});
  $self->{col_num} = $td->{col_num} if defined $td->{col_num};
  # $td->{value} = join("\n", split('', $td->{value})) if $td->{format} && defined $td->{format}{rotation};


  $worksheet->merge_range($self->{row_number}, $self->{col_num}, $self->{row_number} + ($td->{merge_rows} || 0),
    $self->{col_num} + ($td->{merge_cols} || 0), $td->{value}, $format);

  $self->{col_num} += ($td->{merge_cols} + 1) || 1;

  if ($td->{merge_rows} && $self->{row_number} + $td->{merge_rows} >= $self->{most_merge_rows}) {
    $self->{closest_col_num} = $self->{col_num};
    $self->{most_merge_rows} = $self->{row_number} + $td->{merge_rows};
  }
}

#**********************************************************
=head2 table_title($sort, $desc, $pg, $caption, $qs)

=cut
#**********************************************************
sub table_title {
  my $self = shift;
  my (undef, undef, undef, $caption, undef) = @_;

  my $title_format = $workbook->add_format(
    color   => 'black',
    size    => 10,
    bold    => 1,
    bg_color=> 'silver',
  );

  my $i = 0;

  foreach my $line (@$caption) {
    if ($line =~ /^=/) { #to prevent writing strings starting with '=' as formulas, because we never actually use formulas
      $worksheet->write_string(0, $i, decode('utf8', $line), $title_format);
    }
    else {
      $worksheet->write(0, $i, decode('utf8', $line), $title_format);
    }
    $i++;
  }

  return $self;
}

#**********************************************************
=head2 img($img, $name, $attr)

=cut
#**********************************************************
sub img {
  my $self = shift;
  my ($img, $name) = @_;

  return "";

  # my $img_path = ($img =~ s/^://) ? "$IMG_PATH/" : '';
  # return "<img alt='$name' src='$img_path$img' border='0'>";
}

#**********************************************************
=head2 show($attr)

=cut
#**********************************************************
sub show {
  my $self = shift;
  my ($attr) = @_;

  _autofit_columns() if $self->{AUTOFIT_COLUMNS};
  $workbook->close() if ($workbook);
  $self->{show} = '';
  if ($FORM{EXPORT_CONTENT} && $FORM{EXPORT_CONTENT} ne $self->{ID}) {
    return '';
  }

  if ($self->{NO_PRINT} && (!defined($attr->{OUTPUT2RETURN}))) {
    $self->{prototype}->{OUTPUT} .= $self->{show};
    $self->{show} = '';
  }

  return $self->{show};
}

#**********************************************************
=head2 _autofit_columns() - Adjust the column widths to fit the longest string in the column.

=cut
#**********************************************************
sub _autofit_columns {
  my $col = 0;

  for my $width (@{$worksheet->{__col_widths}}) {
    $worksheet->set_column($col, $col, $width) if $width;
    $col++;
  }
}

#**********************************************************
=head2 _store_string_widths($col, $token)

=cut
#**********************************************************
sub _store_string_widths {
  my (undef, undef, $col, $token) = @_;

  # Ignore some tokens that we aren't interested in.
  return if !defined $token;          # Ignore undefs.
  return if $token eq '';             # Ignore blank cells.
  return if ref $token eq 'ARRAY';    # Ignore array refs.
  return if $token =~ /^=/;           # Ignore formula

  # Ignore numbers
  return if $token =~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/;

  return if $token =~ m{^[fh]tt?ps?://};
  return if $token =~ m{^mailto:};
  return if $token =~ m{^(?:in|ex)ternal:};

  my $old_width    = $worksheet->{__col_widths}->[$col];
  my $string_width = _string_width($token);

  if (!defined($old_width) || $string_width > $old_width) {
    $worksheet->{__col_widths}->[$col] = $string_width;
  }

  return undef;
}

#**********************************************************
=head2 _string_width($string) - Very simple conversion between string length and string width for Arial 10.

=cut
#**********************************************************
sub _string_width {
  my $str_length = length $_[0];

  return $str_length > 5 ? 1.1 * $str_length : undef;
}

#**********************************************************
=head2 button($name, $params, $attr) - Create link element

  Arguments:
    $name     - Link name
    $params   - Link params (url)
    $attr
      ONLY_IN_HTML - link will be returned if we are working with HTML, but will not be returned in export modes like xls, csv, json

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

  return "[$params|$name]";
}

#**********************************************************
# Show message box
# message($self, $type, $caption, $message)
# $type - info, err
#**********************************************************
sub message {

}

#**********************************************************
=head2 pages($count, $argument, $attr) - Make pages and count total records

=cut
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
=head2 date_fld2($base_name, $attr)

=cut
#**********************************************************
sub date_fld2 {
  my $self = shift;
  my ($base_name, $attr) = @_;

  my ($mday, $mon, $curyear) = (localtime(time))[3..5];

  my $day   = sprintf("%.2d", $FORM{ $base_name . 'D' } || 1);
  my $month = sprintf("%.2d", $FORM{ $base_name . 'M' } || $mon);
  my $year  = $FORM{ $base_name . 'Y' } || $curyear + 1900;

  my $result = sprintf("%d-%.2d-%.2d", $year, $month, $day);

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
=head2 tpl_show($tpl, $variables_ref, $attr);

=cut
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
    print $tpl;
  }
}

#**********************************************************
# letters_list();
#**********************************************************
sub letters_list {
  my ($self, $attr) = @_;

  if ($FORM{EXPORT_CONTENT} && $FORM{EXPORT_CONTENT} ne $attr->{ID}) {
    return "";
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
=head2 color_mark() Mark text

=cut
#**********************************************************
sub color_mark {
  my $self = shift;
  my ($message, $color, $attr) = @_;

  return $message if ($attr->{SKIP_XML});
  return $message if ($color eq 'code');
  my $output = ($color) ? '_COLOR:'. $color .':'.$message : $message;

  return $output;
}

#**********************************************************
=head2 br() - Break line

=cut
#**********************************************************
sub br {
  my $self = shift;

  return "\n";
}

#**********************************************************
=head2 element($name, $value, $attr)

=cut
#**********************************************************
sub element {
  my $self = shift;
  my ($name, $value, $attr) = @_;

  $self->{FORM_INPUT} = $value;
  if ($self->{NO_PRINT} && ! $attr->{OUTPUT2RETURN}) {
    $self->{OUTPUT} .= $self->{FORM_INPUT};
    $self->{FORM_INPUT} = '';
  }

  return $self->{FORM_INPUT};
}

#**********************************************************
=head2 fetch() - Fetch cache data

=cut
#**********************************************************
sub fetch  {
  my $self = shift;

  return $self;
}

#**********************************************************
=head2  AUTOLOAD Autoload secondary funtions

=cut
#**********************************************************
sub AUTOLOAD {
  our $AUTOLOAD;

  return if ($AUTOLOAD =~ /::DESTROY$/);
  my $function = $AUTOLOAD;

  if($function =~ /table_header|progress_bar/) {
    return q{};
  }

  my ($self, $data) = @_;

  return $data;
}

1
