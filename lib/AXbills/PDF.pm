package AXbills::PDF;


=head2 NAME

  PDF outputs former

=cut

use strict;
our (
  @_COLORS,
  %FORM,
  %LIST_PARAMS,
  %COOKIES,
  $index,
  $SORT,
  $PG,
  $PAGE_ROWS,
  $SELF_URL,
);

our $VERSION = 2.00;

my $debug;
my $IMG_PATH='';
my $CONF;

#my $row_number = 0;
#my $pdf_result_path = '../cgi-bin/admin/';

#**********************************************************
# Create Object
#**********************************************************
sub new{
  my $class = shift;
  my ($attr) = @_;

  require AXbills::HTML;
  AXbills::HTML->import();

  $CONF = $attr->{CONF} if (defined( $attr->{CONF} ));

  my $self = { };
  bless( $self, $class );

  if ( $attr->{NO_PRINT} ){
    $self->{NO_PRINT} = 1;
  }

  $self->{OUTPUT} = '';
  $self->{CHARSET} = (defined( $attr->{CHARSET} )) ? $attr->{CHARSET} : 'windows-1251';

  if ( $attr->{language} ){
    $self->{language} = $attr->{language};
  }
  elsif ( $COOKIES{language} ){
    $self->{language} = $COOKIES{language};
  }
  else{
    $self->{language} = $CONF->{default_language} || 'english';
  }

  eval { require PDF::API2; };
  if ( !$@ ){
    PDF::API2->import();
  }
  else{
    print "Content-Type: text/html\n\n";

    my $name = 'PDF::API2';
    print "Can't load '$name'\n" .
        " Install Perl Module <a href='http://axbills.net.ua/wiki/doku.php/axbills:docs:manual:soft:$name' target='_install'>$name</a> \n" .
        " Main Page <a href='http://axbills.net.ua/wiki/doku.php/axbills:docs:other:ru?&#ustanovka_perl_modulej' target='_install'>Perl modules installation</a>\n" .
        " or install from <a href='http://www.cpan.org'>CPAN</a>\n";
  }

  if ( defined( $FORM{xml} ) ){
    require AXbills::XML;
    $self = AXbills::XML->new(
      {
        IMG_PATH => $IMG_PATH,
        NO_PRINT => defined( $attr->{'NO_PRINT'} ) ? $attr->{'NO_PRINT'} : 1
      }
    );
  }
  else{
    $self->{pdf_output} = 1;
  }

  $self->{TYPE}='pdf' if(! $self->{TYPE});

  return $self;
}

#**********************************************************
# form_input
#**********************************************************
sub form_input{
  my $self = shift;
  my ($name, $value, $attr) = @_;

  my $type = 'text';
  my $class = '';
  my $ex_params = '';

  if ( $attr->{EX_PARAMS} ){
    $ex_params = $attr->{EX_PARAMS};
  }

  if ( defined( $attr->{TYPE} ) ){
    $type = $attr->{TYPE};
    if ( $type =~ /submit/i ){
      $class = ' class="button"';
    }
  }

  my $state = (defined( $attr->{STATE} )) ? ' checked ' : '';
  my $size = (defined( $attr->{SIZE} )) ? " SIZE=\"$attr->{SIZE}\"" : '';

  $self->{FORM_INPUT} = "<input type=\"$type\" name=\"$name\" value=\"$value\"$state$size$class$ex_params/>";

  if ( defined( $self->{NO_PRINT} ) && (!defined( $attr->{OUTPUT2RETURN} )) ){
    $self->{OUTPUT} .= $self->{FORM_INPUT};
    $self->{FORM_INPUT} = '';
  }

  return $self->{FORM_INPUT};
}

#**********************************************************
# form_main
#**********************************************************
sub form_main{
  my $self = shift;
  my ($attr) = @_;

  my $METHOD = ($attr->{METHOD}) ? $attr->{METHOD} : 'POST';
  $self->{FORM} = "<FORM ";
  $self->{FORM} .= "name=\"$attr->{NAME}\" " if ($attr->{NAME});
  $self->{FORM} .= "action=\"$SELF_URL\" METHOD=\"$METHOD\">\n";

  if ( defined( $attr->{HIDDEN} ) ){
    my $H = $attr->{HIDDEN};
    while (my ($k, $v) = each( %{$H} )) {
      $self->{FORM} .= "<input type=\"hidden\" name=\"$k\" value=\"$v\">\n";
    }
  }

  if ( defined( $attr->{CONTENT} ) ){
    $self->{FORM} .= $attr->{CONTENT};
  }

  if ( defined( $attr->{SUBMIT} ) ){
    my $H = $attr->{SUBMIT};
    while (my ($k, $v) = each( %{$H} )) {
      $self->{FORM} .= "<input type=\"submit\" name=\"$k\" value=\"$v\" class=\"button\">\n";
    }
  }

  $self->{FORM} .= "</form>\n";

  if ($attr->{OUTPUT2RETURN}) {
    return $self->{FORM};
  }
  elsif ( defined( $self->{NO_PRINT} ) ){
    $self->{OUTPUT} .= $self->{FORM};
    $self->{FORM} = '';
  }

  return $self->{FORM};
}

#**********************************************************
#
#**********************************************************
sub form_select{
  my $self = shift;
  my ($name, $attr) = @_;

  my $ex_params = (defined( $attr->{EX_PARAMS} )) ? $attr->{EX_PARAMS} : '';

  $self->{SELECT} = "<select name=\"$name\" $ex_params>\n";

  if ( defined( $attr->{SEL_OPTIONS} ) ){
    my $H = $attr->{SEL_OPTIONS};
    while (my ($k, $v) = each %{$H}) {
      $self->{SELECT} .= "<option value='$k'";
      $self->{SELECT} .= ' selected' if (defined( $attr->{SELECTED} ) && $k eq $attr->{SELECTED});
      $self->{SELECT} .= ">$v\n";
    }
  }

  if ( defined( $attr->{SEL_ARRAY} ) ){
    my $H = $attr->{SEL_ARRAY};
    my $i = 0;
    foreach my $v ( @{$H} ){
      my $id = (defined( $attr->{ARRAY_NUM_ID} )) ? $i : $v;
      $self->{SELECT} .= "<option value='$id'";
      $self->{SELECT} .= ' selected' if ($attr->{SELECTED} && (($i eq $attr->{SELECTED}) || ($v eq $attr->{SELECTED})));
      $self->{SELECT} .= ">$v\n";
      $i++;
    }
  }
  elsif ( defined( $attr->{SEL_MULTI_ARRAY} ) ){
    my $key = $attr->{MULTI_ARRAY_KEY};
    my $value = $attr->{MULTI_ARRAY_VALUE};
    my $H = $attr->{SEL_MULTI_ARRAY};

    foreach my $v ( @{$H} ){
      $self->{SELECT} .= "<option value='$v->[$key]'";
      $self->{SELECT} .= ' selected' if (defined( $attr->{SELECTED} ) && $v->[$key] eq $attr->{SELECTED});
      $self->{SELECT} .= '>';
      $self->{SELECT} .= "$v->[$key]:" if (!$attr->{NO_ID});
      $self->{SELECT} .= "$v->[$value]\n";
    }
  }
  elsif ( defined( $attr->{SEL_HASH} ) ){
    my @H = ();

    if ( $attr->{SORT_KEY} ){
      @H = sort keys %{ $attr->{SEL_HASH} };
    }
    else{
      @H = keys %{ $attr->{SEL_HASH} };
    }

    foreach my $k ( @H ){
      $self->{SELECT} .= "<option value='$k'";
      $self->{SELECT} .= ' selected' if (defined( $attr->{SELECTED} ) && $k eq $attr->{SELECTED});

      $self->{SELECT} .= ">";
      $self->{SELECT} .= "$k:" if (!$attr->{NO_ID});
      $self->{SELECT} .= "$attr->{SEL_HASH}{$k}\n";
    }
  }

  $self->{SELECT} .= "</select>\n";

  return $self->{SELECT};
}


#**********************************************************
#
#**********************************************************
sub menu {
  my $self = shift;
  my ($menu_items, $menu_args, $permissions, $attr) = @_;

  my $menu_navigator = '';
  my $root_index = 0;
  my %tree = ();
  my %menu = ();
  my $sub_menu_array;
  my $EX_ARGS = (defined( $attr->{EX_ARGS} )) ? $attr->{EX_ARGS} : '';

  # make navigate line
  if ( $index > 0 ){
    $root_index = $index;
    my $h = $menu_items->{$root_index};

    while (my ($par_key, $name) = each( %{$h} )) {

      my $ex_params = (defined( $menu_args->{$root_index} ) && defined( $FORM{ $menu_args->{$root_index} } )) ? '&' . "$menu_args->{$root_index}=$FORM{$menu_args->{$root_index}}" : '';

      $menu_navigator = " " . $self->button( $name, "index=$root_index$ex_params" ) . '/' . $menu_navigator;
      $tree{$root_index} = 1;
      if ( $par_key > 0 ){
        $root_index = $par_key;
        $h = $menu_items->{$par_key};
      }
    }
  }

  $FORM{root_index} = $root_index;
  if ( $root_index > 0 ){
    my $ri = $root_index - 1;
    if ( defined( $permissions ) && (!defined( $permissions->{$ri} )) ){
      $self->{ERROR} = "Access deny";
      return '', '';
    }
  }

  my @s =
    sort { length( $a ) <=> length( $b ) || $a cmp $b } keys %{$menu_items};

  foreach my $ID ( @s ){
    my $VALUE_HASH = $menu_items->{$ID};
    foreach my $parent ( keys %{$VALUE_HASH} ){
      push( @{ $menu{$parent} }, "$ID:$VALUE_HASH->{$parent}" );
    }
  }

  my @last_array = ();

  my $menu_text = "<div class='menu'>
 <table border='0' width='100%'>\n";

  my $level = 0;
  my $prefix = '';

  my $parent = 0;

  label:
  $sub_menu_array = \@{ $menu{$parent} };

  while (my $sm_item = pop @{$sub_menu_array}) {
    my ($ID, $name) = split( /:/, $sm_item, 2 );
    next if ((!defined( $attr->{ALL_PERMISSIONS} )) && (!$permissions->{ $ID - 1 }) && $parent == 0);

    $name = (defined( $tree{$ID} )) ? "<b>$name</b>" : "$name";
    if ( !defined( $menu_args->{$ID} ) || (defined( $menu_args->{$ID} ) && defined( $FORM{ $menu_args->{$ID} } )) ){
      my $ext_args = "$EX_ARGS";
      if ( defined( $menu_args->{$ID} ) ){
        $ext_args = "&$menu_args->{$ID}=$FORM{$menu_args->{$ID}}";
        $name = "<b>$name</b>" if ($name !~ /<b>/);
      }

      my $link = $self->button( $name, "index=$ID$ext_args" );
      if ( $parent == 0 ){
        $menu_text .= "<tr><td bgcolor=\"$_COLORS[3]\" align=left>$prefix$link</td></tr>\n";
      }
      elsif ( defined( $tree{$ID} ) ){
        $menu_text .= "<tr><td bgcolor=\"$_COLORS[2]\" align=left>$prefix>$link</td></tr>\n";
      }
      else{
        $menu_text .= "<tr><td bgcolor=\"$_COLORS[1]\">$prefix$link</td></tr>\n";
      }
    }
    else{

      #next;
      #$link = "<a href='$SELF_URL?index=$ID&$menu_args->{$ID}'>$name</a>";
    }

    if ( defined( $tree{$ID} ) ){
      $level++;
      $prefix .= "&nbsp;&nbsp;&nbsp;";
      push @last_array, $parent;
      $parent = $ID;
      $sub_menu_array = \@{ $menu{$parent} };
    }
  }

  if ( $#last_array > -1 ){
    $parent = pop @last_array;

    #print "POP/$#last_array/$parent/<br>\n";
    $level--;
    $prefix = substr( $prefix, 0, $level * 6 * 3 );
    goto label;
  }

  #  }

  $menu_text .= "</table>\n</div>\n";

  return ($menu_navigator, $menu_text);
}

#**********************************************************
# menu($type, $main_para,_name, $ex_params, \%menu_hash_ref);
#
# $type
#   0 - horizontal
#   1 - vertical
# $ex_params - extended params
# $mp_name - Menu parameter name
# $params - hash of menu items
# menu($type, $mp_name, $ex_params, $menu, $sub_menu, $attr);
#**********************************************************
sub menu2{
  my $self = shift;
  my ($type, $mp_name, $ex_params, $menu) = @_;
  my @menu_captions = sort keys %{$menu};

  $self->{menu} = "<TABLE width=\"100%\">\n";

  if ( $type == 1 ){

    foreach my $line ( @menu_captions ){
      my (undef, $file, $k) = split( /:/, $line );
      my $link = ($file eq '') ? $SELF_URL : $file;
      $link .= '?';
      $link .= "$mp_name=$k&" if ($k ne '');

      #    if ((defined($FORM{$mp_name}) && $FORM{$mp_name} eq $k) && $file eq '') {
      if ( (defined( $FORM{root_index} ) && $FORM{root_index} eq $k) && $file eq '' ){
        $self->{menu} .= "$menu->{$line} [$link$ex_params]\n";
        #while (my ($k, $v) = each %{$sub_menu}) {
          #$self->{menu} .= "<tr><td bgcolor=\"$lang{COLORS}[1]\">&nbsp;&nbsp;&nbsp;<a href='$SELF_URL?index=$k'>$v</a></td></TR>\n";
        #}
      }
      else{
        $self->{menu} .= "<tr><td><a href='$link'>" . $menu->{"$line"} . "</a></td></TR>\n";
      }
    }
  }
  else{
    $self->{menu} .= "<tr bgcolor=\"$_COLORS[0]\">\n";

    foreach my $line ( @menu_captions ){
      my (undef, $file, $k) = split( /:/, $line );
      my $link = ($file eq '') ? "$SELF_URL" : "$file";
      $link .= '?';
      $link .= "$mp_name=$k&" if ($k ne '');

      $self->{menu} .= "<th";
      if ( $FORM{$mp_name} eq $k && $file eq '' ){
        $self->{menu} .= " bgcolor=\"$_COLORS[3]\"><a href='$link$ex_params'>" . $menu->{"$line"} . "</a></th>";
      }
      else{
        $self->{menu} .= "><a href='$link'>" . $menu->{"$line"} . "</a></th>\n";
      }

    }
    $self->{menu} .= "</TR>\n";
  }

  $self->{menu} .= "</TABLE>\n";

  return $self->{menu};
}

#**********************************************************
=head2 pdf_header($attr)

  Arguments:
    $attr
      NAME - Filename

  Returns:

=cut
#**********************************************************
sub pdf_header{
  my $self = shift;
  my ($attr) = @_;

  my $filename = 'file_name';

  if ( $attr->{NAME} ){
    if ( $attr->{NAME} =~ /\/([a-z0-9\_\.]+)$/i ){
      $filename = $1;
    }
    else{
      $filename = $attr->{NAME} . '.pdf';
    }
  }
  else{
    $filename = int( rand( 32768 ) ) . '.pdf';
  }

  $self->{header} = '';

  if ( $FORM{DEBUG} ){
    $self->{header} = "Content-Type: text/plain\n\n";
    $self->{debug} = 1;
  }

  $self->{header} .= "Content-type: application/pdf; filename=$filename\n";
  $self->{header} .= "Cache-Control: no-cache\n";
  $self->{header} .= "Content-disposition: inline; name=\"$filename\"\n\n";

  return $self->{header};
}

#**********************************************************
=head2 header($attr) - header off main page

=cut
#**********************************************************
sub header{
  my $self = shift;
  #my ($attr) = @_;

  $self->{header} = '';

  if ( $FORM{DEBUG} ){
    $self->{header} = "Content-Type: text/plain\n\n";
    $self->{debug} = 1;

    return $self->{header};
  }

  return $self->{header};
}

#**********************************************************
=head1 table();

=cut
#**********************************************************
sub table{
  my $proto = shift;
  my $class = ref( $proto ) || $proto;
  my $parent = ref( $proto ) && $proto;
  my $self;

  $self = { };
  bless($self, $class);

  $self->{PDF}      = $parent;
  $self->{prototype}= $proto;
  $self->{NO_PRINT} = $proto->{NO_PRINT};

  my ($attr) = @_;
  $self->{rows} = '';

  my $width = (defined( $attr->{width} )) ? "width=\"$attr->{width}\"" : '';
  #my $border = (defined( $attr->{border} )) ? "border=\"$attr->{border}\"" : '';
  my $table_class = (defined( $attr->{class} )) ? "class=\"$attr->{class}\"" : '';

  if ( defined( $attr->{rowcolor} ) ){
    $self->{rowcolor} = $attr->{rowcolor};
  }
  else{
    $self->{rowcolor} = undef;
  }

  if ( defined( $attr->{rows} ) ){
    my $rows = $attr->{rows};
    foreach my $line ( @{$rows} ){
      $self->addrow( @{$line} );
    }
  }

  $self->{table} = "<TABLE $width cellspacing=\"0\" cellpadding=\"0\" border=\"0\"$table_class>\n";

  if ( defined( $attr->{caption} ) ){
    $self->{table} .= "$attr->{caption}\n";
  }

  $self->{table} .= "<tr><td bgcolor=\"$_COLORS[1]\">$attr->{header}</td></tr>\n" if ($attr->{header});

  $self->{table} .= "<TR><TD bgcolor=\"$_COLORS[4]\">
               <TABLE width=\"100%\" cellspacing=\"1\" cellpadding=\"0\" border=\"0\">\n";

  if ( defined( $attr->{title} ) ){
    $SORT = $LIST_PARAMS{SORT};
    $self->{table} .= $self->table_title( $SORT, $FORM{desc}, $PG, $attr->{title}, $attr->{qs} );
  }
  elsif ( defined( $attr->{title_plain} ) ){
    $self->{table} .= $self->table_title_plain( $attr->{title_plain} );
  }

#  if ( defined( $attr->{cols_align} ) ){
#    $self->{table} .= "<COLGROUP>";
#    my $cols_align = $attr->{cols_align};
#    my $i = 0;
#    foreach my $line ( @{$cols_align} ){
#      $class = '';
#      if ( $line =~ /:/ ){
#        ($line, $class) = split( /:/, $line, 2 );
#        $class = " class=\"$class\"";
#      }
#      $width = (defined( $attr->{cols_width} ) && defined( @{ $attr->{cols_width} }[$i] )) ? " width=\"@{$attr->{cols_width}}[$i]\"" : '';
#      $self->{table} .= " <COL align=\"$line\"$class$width>\n";
#      $i++;
#    }
#    $self->{table} .= "</COLGROUP>\n";
#  }

  if ( $attr->{pages} ){
    my $op;
    if ( $FORM{index} ){
      $op = "index=$FORM{index}";
    }

    my %ATTR = ();
    if ( defined( $attr->{recs_on_page} ) ){
      $ATTR{recs_on_page} = $attr->{recs_on_page};
    }
    $self->{pages} = $self->pages( $attr->{pages}, "$op$attr->{qs}", { %ATTR } );
  }

  return $self;
}

#**********************************************************
# addrows()
#**********************************************************
sub addrow{
  my $self = shift;
  #my (@row) = @_;

  #foreach my $val ( @row ){
  #}

  return $self->{rows};
}

#**********************************************************
# addrows()
#**********************************************************
sub addtd{
  my $self = shift;
  my (@row) = @_;

  $self->{rows} .= "<tr>";
  foreach my $val ( @row ){
    $self->{rows} .= "$val";
  }

  $self->{rows} .= "</TR>\n";

  return $self->{rows};
}

#**********************************************************
# Extendet add rows
# th()
#**********************************************************
sub th{
  #my $self = shift;
  #my ($value, $attr) = @_;

  return '';
}

#**********************************************************
# Extendet add rows
# td()
#**********************************************************
sub td{
  #my $self = shift;
  #my ($value, $attr) = @_;

  return '';
}

#**********************************************************
=head2 table_title_plain($caption)

=cut
#**********************************************************
sub table_title_plain{
  #my $self = shift;
  #my ($caption) = @_;

  return '';
}

#**********************************************************
# Show table column  titles with wort derectives
# Arguments
# table_title($sort, $desc, $pg, $get_op, $caption, $qs);
# $sort - sort column
# $desc - DESC / ASC
# $pg - page id
# $caption - array off caption
#**********************************************************
sub table_title{
  my $self = shift;
  my ($sort, $desc, $pg, $caption, $qs) = @_;
  my ($op);
  my $img = '';

  $self->{table_title} = "<tr>";

  my $i = 1;
  foreach my $line ( @{$caption} ){
    $self->{table_title} .= "<th class='table_title'>$line ";
    if ( $line ne '-' ){
      if ( $sort != $i ){
        $img = '';
      }
      elsif ( $desc eq 'DESC' ){
        $img = '';
        $desc = '';
      }
      elsif ( $sort > 0 ){
        $img = '';
        $desc = 'DESC';
      }

      if ( $FORM{index} ){
        $op = "index=$FORM{index}";
      }

      if ( $FORM{index} ){
        $op = "index=$FORM{index}";
      }

      $self->{table_title} .= $self->button(
        "<img src=\"$IMG_PATH/$img\" width=\"12\" height=\"10\" border=\"0\" alt=\"Sort\" title=\"Sort\" class=\"d-print-none\">"
        , "$op$qs&pg=$pg&sort=$i&desc=$desc" );
    }
    else{
      $self->{table_title} .= "$line";
    }

    $self->{table_title} .= "</th>\n";
    $i++;
  }
  $self->{table_title} .= "</TR>\n";

  return $self->{table_title};
}

#**********************************************************
=head2 show($attr) - Table show

=cut
#**********************************************************
sub show{
  my $self = shift;
  my ($attr) = shift;

  $self->{show} = $self->{table};
  $self->{show} .= $self->{rows};

  if ( defined( $self->{pages} ) ){
    $self->{show} = $self->{pages} . $self->{show} . $self->{pages};
  }

  if ( (defined( $self->{NO_PRINT} )) && (!defined( $attr->{OUTPUT2RETURN} )) ){
    $self->{prototype}->{OUTPUT} .= $self->{show};
    $self->{show} = '';
  }

  return $self->{show};
}

#**********************************************************
=head2 link_former($params)

=cut
#**********************************************************
sub link_former{
  my ($self) = shift;
  my ($params) = @_;

  return $params;
}

#**********************************************************
#
# del_button($op, $del, $message, $attr)
#**********************************************************
sub button{
  my $self = shift;
  my ($name, $params, $attr) = @_;

  my $ex_attr = ($attr->{ex_params}) ? $attr->{ex_params} : '';

  $params = ($attr->{GLOBAL_URL}) ? $attr->{GLOBAL_URL} : "$SELF_URL?$params";
  $params = $attr->{JAVASCRIPT} if (defined( $attr->{JAVASCRIPT} ));
  $params = $self->link_former( $params );

  $ex_attr = " TITLE='$attr->{TITLE}'" if (defined( $attr->{TITLE} ));
  my $button = "$name [$params]";

  return $button;
}

#**********************************************************
=head2 message($self, $type, $caption, $message) - Show message box
   $type - info, err

=cut
#**********************************************************
sub message{
  #my $self = shift;
  #my ($type, $caption, $message, $head, $attr) = @_;

  return '';
}

#**********************************************************
# Preformated test
#**********************************************************
sub pre{
  my $self = shift;
  my ($message) = @_;

  return $message;
}

#**********************************************************
=head2 b($text) Mark Bold

=cut
#**********************************************************
sub b{
  my $self = shift;
  my ($text) = @_;

  return $text;
}

#**********************************************************
=head2 color_mark() Mark text

=cut
#**********************************************************
sub color_mark{
  #my $self = shift;
  my ($message) = @_;

  return $message;
}

#**********************************************************
# Make pages and count total records
# pages($count, $argument)
#**********************************************************
sub pages{
  my $self = shift;
  my ($count, $argument, $attr) = @_;

  if ( defined( $attr->{recs_on_page} ) ){
    $PAGE_ROWS = $attr->{recs_on_page};
  }

  my $begin = 0;

  $self->{pages} = '';
  $begin = ($PG - $PAGE_ROWS * 3 < 0) ? 0 : $PG - $PAGE_ROWS * 3;

  return $self->{pages} if ($count < $PAGE_ROWS);

  for ( my $i = $begin; ($i <= $count && $i < $PG + $PAGE_ROWS * 10); $i += $PAGE_ROWS ){
    $self->{pages} .= ($i == $PG) ? "<b>$i</b>:: " : $self->button( $i, "$argument&pg=$i" ) . ':: ';
  }

  return $self->{pages};
}

#**********************************************************
=head2 2($base_name)

=cut
#**********************************************************
sub date_fld2{
  my $self = shift;

  return q{};
}

#**********************************************************
=head2 get_pdf($filename)

 template
 variables_ref
 atrr [EX_VARIABLES]

=cut
#**********************************************************
sub get_pdf{
  my $self = shift;
  my ($filename) = @_;

  $filename = $filename . '.pdf';
  $self->{FILENAME} = $filename;
  my $pdf = PDF::API2->open( $filename );

  return $pdf;
}

#**********************************************************
=head2 tpl_show($filename, $variables_ref, $attr)

  Argumets:
    $filename
    $variables_ref
    $attr [EX_VARIABLES]
      EXTEND_TPL_DESCRIBE - hash_ref, extra key => value for tpl_describe
      SKIP_ERRORS
      ID
      FILENAME
      
  Returns:
    $content

=cut
#**********************************************************
sub tpl_show{
  my $self = shift;
  my ($filename, $variables_ref, $attr) = @_;

  if ($attr->{TPL} && $attr->{MODULE}) {
    $filename = $self->get_tpl($attr->{TPL}, $attr->{MODULE}, {pdf => 1});
  }

  $filename =~ s/\.[a-z]{3}$//;
  my $tpl_describe = tpl_describe( $filename, { debug => $self->{debug} } );
  $filename = $filename . '.pdf';

  if ( !-f $filename ){
    if ( !$attr->{SKIP_ERRORS} ){
      print "Content-Type: text/html\n\n";
      print "Error: File not found '$filename' ID: " . ($attr->{ID} || '') . "\n";
    }
    return 0;
  }

  my PDF::API2 $pdf = PDF::API2->open( "$filename" );
  my $tpl;

  print "Tpl File: $filename\n" if ($self->{debug});

  my $moddate .= '';
  $attr->{DOCS_IN_FILE} = 0 if (!$attr->{DOCS_IN_FILE});

  $pdf->info(
    'Author'       => "ABillS pdf manager",
    'CreationDate' => "D:20020911000000+01'00'",
    'ModDate'      => "D:$moddate" . "+02'00'",
    'Creator'      => ($attr->{ADMIN}) ? $attr->{ADMIN} : "ABillS pdf manager",
    'Producer'     => "ABillS pdf manager",
    'Title'        => $attr->{TITLE} || "Invoice",
    'Subject'      => $attr->{SUBJECT} || "Invoice",
    'Keywords'     => ""
  );

  my $multi_doc_count = 0;
  my $page_count = $pdf->pages;
  my $font_name = 'Verdana';
  my $encode = $self->{CHARSET} || 'windows-1251';
  my $font;
  my $multi_recs = 0;

  if ( $encode =~ /utf-8/ ){
    $font_name = $CONF->{TPL_DIR} . '/fonts/FreeSerif.ttf';

    eval { $font = $pdf->ttfont( $font_name, -encode => "$encode" ) };
    if ( $@ ){
      print "Error: $! '$font_name' encode: $encode";
    }
  }
  else{
    $font = $pdf->corefont( $font_name, -encode => "$encode" );
  }

  MULTIDOC_LABEL:
  my $start_position_num = 0;
  NEXT_RECORDS:

  if ($attr->{EXTEND_TPL_DESCRIBE} && ref $attr->{EXTEND_TPL_DESCRIBE} eq 'HASH'){
    $tpl_describe = { %{$tpl_describe}, %{$attr->{EXTEND_TPL_DESCRIBE}} };
  }
  
  use AXbills::Base qw/_bp/;
  
  for my $key ( sort keys %{$tpl_describe} ){
    my @patterns = ();

    if ( $tpl_describe->{$key}{PARAMS} =~ /\((.+)\)/ ){
      @patterns = split( /,/, $1 );
    }
    else{
      push @patterns, $tpl_describe->{$key}{PARAMS};
    }

    my $x = 0;
    my $y = 0;
    my $doc_page = 1;
    my $font_size = 10;
    my $font_color;
    my $align = '';
    my $text_file = '';

    for ( my $i = $start_position_num; $i <= $#patterns; $i++ ){
      my $pattern = $patterns[$i];

      $x = $1 if ($pattern =~ /x=(\d+)/);
      $y = $1 if ($pattern =~ /y=(\d+)/);
      next if ($x == 0 && $y == 0);

      my $text = '';
      $doc_page = ($pattern =~ /page=(\d+)/) ? $1 : 1;
      my $work_page = ($attr->{DOCS_IN_FILE}) ? $doc_page + $page_count * int( $multi_doc_count - 1 ) - ($page_count * $attr->{DOCS_IN_FILE} * int( ($multi_doc_count - 1) / $attr->{DOCS_IN_FILE} )) : $doc_page + (($multi_doc_count) ? $page_count * $multi_doc_count - $page_count : 0);
      my $page = $pdf->openpage( $work_page );
      if ( !$page ){
        print "Content-Type: text/plain\n\n";
        print "Can't open page: $work_page ($pattern) '$!' / $doc_page + $page_count * $multi_doc_count\n";
      }
      
      # Make img_insertion
      if ( $pattern =~ /img=([0-9a-zA-Z_\.\/]+)/ ){
        my $img_file = $1;
        if ( !-f "$CONF->{TPL_DIR}/$img_file" ){
          $text = "Img file not exists '$CONF->{TPL_DIR}/$img_file'\n";
          next;
        }
        else{
          print "make image '$CONF->{TPL_DIR}/$img_file'\n" if ($debug > 0);
          my $img_height = ($pattern =~ /img_height=([0-9a-zA-Z_\.]+)/) ? $1 : 100;
          my $img_width = ($pattern =~ /img_width=([0-9a-zA-Z_\.]+)/) ? $1 : 100;

          my $gfx = $page->gfx;
          my $img;
          if ($pattern =~ /img_type=png/) {
            $img = $pdf->image_png( "$CONF->{TPL_DIR}/$img_file" );
          }
          else {
            $img = $pdf->image_jpeg( "$CONF->{TPL_DIR}/$img_file" );    #, 200, 200);
          }
          $gfx->image( $img, $x, ($y - $img_height + 10), $img_width, $img_height );    #, 596, 842);
          $gfx->close;
          $gfx->stroke;
          next;
        }
      }

      $align = '';
      $text_file = $1 if ($pattern =~ /text=([0-9a-zA-Z_\.]+)/);
      $font_size = $1 if ($pattern =~ /font_size=(\d+)/);
      $font_color = $1 if ($pattern =~ /font_color=(\S+)/);
      $encode = $1 if ($pattern =~ /encode=(\S+)/);
      $align = $1 if ($pattern =~ /align=([a-z]+)/i);

      if ( $pattern =~ /font_name=(\S+)/ ){
        $font_name = $1;
        if ( $font_name =~ /\.ttf$/ ){
          if ( $font_name =~ /^\// && !-f $font_name ){
            print "Content-Type: text/plain\n\n";
            print "Font '$font_name' not found\n";
          }
          else{
            $font = $pdf->ttfont( $font_name, -encode => "$encode" );
          }
        }
        else{
          $font = $pdf->corefont( $font_name, -encode => "$encode" );
        }
      }

      my $txt = $page->text;
      $txt->font( $font, $font_size );
      if ( $font_color ){
        $txt->fillcolor( $font_color );
        $txt->fillstroke( $font_color );
      }

      $txt->translate( $x, $y );

      if ( defined( $variables_ref->{$key} ) ){
        $text = $variables_ref->{$key};
        if ( $tpl_describe->{$key}->{EXPR} ){
          my @expr_arr = split( /\//, $tpl_describe->{$key}->{EXPR}, 2 );
          print "Expration: $key >> $text=~s/$expr_arr[0]/$expr_arr[1]/;\n" if ($attr->{debug});
          $text =~ s/$expr_arr[0]/$expr_arr[1]/g;
        }
      }

      if ( $text_file ne '' ){
        my $text_height = ($pattern =~ /text_height=([0-9a-zA-Z_\.]+)/) ? $1 : 100;
        my $text_width = ($pattern =~ /text_width=([0-9a-zA-Z_\.]+)/) ? $1 : 100;

        if ( !-f "$CONF->{TPL_DIR}/$text_file" ){
          $text = "Text file not exists '$CONF->{TPL_DIR}/$text_file'\n";
        }
        else{
          my $content = '';
          open( my $fh, '<', "$CONF->{TPL_DIR}/$text_file" ) or die "Can't open file '$text_file' $!\n";
          while (<$fh>) {
            $content .= $_;
          }
          close( $fh );

          my $string_height = ($pattern =~ /string_height=([0-9a-zA-Z_\.]+)/) ? $1 : 15;
          $txt->lead( $string_height );
          #my ($idt, $y2) =
          $txt->paragraph(
            $content, $text_width, $text_height,
            -align     => $align || 'justified',
            -spillover => 2
          );    # ,400,14,@text);
          next;
        }
      }

      if ( $pattern =~ /step=(\S+)/ ){
        my $step = $1;
        my $len = length( $pattern );
        for ( my $c = 0; $c <= $len; $c++ ){
          $txt->translate( $x + $c * $step, $y );
          my $char = substr( $text, $c, 1 );
          $txt->text( $char );
        }
      }
      else{
        if ( $align ){
          my $text_height = ($pattern =~ /text_height=([0-9a-zA-Z_\.]+)/) ? $1 : 100;
          my $text_width = ($pattern =~ /text_width=([0-9a-zA-Z_\.]+)/) ? $1 : 100;
          my $string_height = ($pattern =~ /string_height=([0-9a-zA-Z_\.]+)/) ? $1 : 15;
          $txt->lead($string_height);
          #my ($idt, $y2) =
          $txt->paragraph(
            $text, $text_width, $text_height,
            -align     => $align,
            -spillover => 2
          );
        }
        else{
          $txt->text( $text, -align => $align || 'justified' );
        }
      }

      if ( $attr->{MULTI_DOCS_PAGE_RECS} && $i == $attr->{MULTI_DOCS_PAGE_RECS} - 1 ){
        print "$i % $attr->{MULTI_DOCS_PAGE_RECS} // $start_position_num // $variables_ref->{LOGIN}\n" if ($debug > 1);
        last;
      }
    }
  }

  if ( $attr->{MULTI_DOCS} && ($multi_doc_count * (($attr->{MULTI_DOCS_PAGE_RECS}) ? $attr->{MULTI_DOCS_PAGE_RECS} : 1 )) <= $#{ $attr->{MULTI_DOCS} } ){
    if ( $attr->{DOCS_IN_FILE} && $multi_doc_count > 0 && $multi_doc_count % $attr->{DOCS_IN_FILE} == 0 ){
      my $outfile = $attr->{SAVE_AS};
      my $filenum = int( $multi_doc_count / $attr->{DOCS_IN_FILE} );

      $outfile =~ s/\.pdf/$filenum\.pdf/;

      print "Save to: $outfile\n" if ($self->{debug});

      $pdf->saveas( "$outfile" );
      $pdf->end;

      $pdf = PDF::API2->open( $filename );

      if ( $encode =~ /utf-8/ ){
        $font_name = '/usr/axbills/AXbills/templates/fonts/FreeSerif.ttf';
        $font = $pdf->ttfont( $font_name, -encode => "$encode" );
      }
      else{
        #
        $font = $pdf->corefont( $font_name, -encode => "$encode" );
      }
    }

    my $array_num = ($multi_doc_count * (($attr->{MULTI_DOCS_PAGE_RECS}) ? $attr->{MULTI_DOCS_PAGE_RECS} : 1  )) + $multi_recs;

    $variables_ref = $attr->{MULTI_DOCS}[$array_num];
    print "Doc: $multi_doc_count : $array_num\n" if ($attr->{debug});

    if ( $attr->{MULTI_DOCS_PAGE_RECS} && $multi_doc_count / $attr->{MULTI_DOCS_PAGE_RECS} && !$multi_recs ){
      $start_position_num = 2;
      $multi_recs = 1;
      goto NEXT_RECORDS;
    }
    else{
      $multi_recs = 0;
    }

    $multi_recs = 0;

    if ( $multi_doc_count > 0 ){
      for ( my $i = 1; $i <= $page_count; $i++ ){
        #my $page =
        $pdf->importpage( $pdf, $i );
      }
    }

    $multi_doc_count++;
    goto MULTIDOC_LABEL;
  }

  if ( $attr->{SAVE_AS} ){
    $pdf->saveas( "$attr->{SAVE_AS}" );
    $pdf->end;
    return 0;
  }

  $tpl = $pdf->stringify();
  $pdf->end;
  if ( $attr->{OUTPUT2RETURN} ){
    return $tpl;
  }
  elsif ( $attr->{notprint} || $self->{NO_PRINT} ){
    if ( $FORM{qindex} ){
      $self->{OUTPUT} .= $self->pdf_header( { NAME => $attr->{FILENAME} || $filename } );
      #print $self->pdf_header( { NAME => $filename } );
    }
    $self->{OUTPUT} .= $tpl;
    return $tpl;
  }
  else{
    print $self->pdf_header( { NAME => $attr->{FILENAME} || $filename } ) if ($FORM{qindex});
    print $tpl;
    return $tpl;
  }
}

#**********************************************************
# test function
#  %FORM     - Form
#  %COOKIES  - Cookies
#  %ENV      - Enviropment
#
#**********************************************************
sub test{
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
=head2 tpl_describe($tpl_name, $attr)

   Get template describe. Variables and other
   tpl describe file format
   TPL_VARIABLE:TPL_VARIABLE_DESCRIBE:DESCRIBE_LANG:PARAMS

=cut
#**********************************************************
sub tpl_describe{
  my ($tpl_name, $attr) = @_;

  my $filename = $tpl_name . '.dsc';
  my $content = '';

  #print $tpl_name.'.dsc';
  my %TPL_DESCRIBE = ();

  if ( !-f $filename ){
    return \%TPL_DESCRIBE;
  }

  open( my $fh, '<', $filename ) or die "Can't open file '$filename' $!\n";
  while (<$fh>) {
    $content .= $_;
  }
  close( $fh );

  my @rows = split( /[\r]{0,1}\n/, $content );

  foreach my $line ( @rows ){
    if ( $line =~ /^#/ ){
      next;
    }
    else{
      my ($name, $describe, $lang, $params, $default, $expr) = split( /:/, $line );
      next if ($attr->{LANG} && $attr->{LANG} ne $lang);
      next if (!$name);
      $TPL_DESCRIBE{$name}{DESCRIBE} = $describe;
      $TPL_DESCRIBE{$name}{LANG} = $lang;
      $TPL_DESCRIBE{$name}{PARAMS} = $params;
      $TPL_DESCRIBE{$name}{DEFAULT} = $default;
      $TPL_DESCRIBE{$name}{EXPR} = $expr;
      print "$name Descr '$describe' Params '$params' Expr '$expr' Def '$default'\n" if ($attr->{debug});
    }
  }

  return \%TPL_DESCRIBE;
}

#**********************************************************
# list item
#**********************************************************
sub li{
  my $self = shift;
  #my ($item, $attr) = @_;

  return "item";
}

#***********************************************************
#
#***********************************************************
sub badge{
  my $self = shift;
  my ($text) = @_;

  return $text || q{};
}

#**********************************************************
#
#**********************************************************
sub tree_menu{
  shift;
  require HTML_Tree;
  HTML_Tree->import();

  my $tree_builder = HTML_Tree->new();

  return $tree_builder->tree_menu( @_ );
}

#**********************************************************
=head2 fetch() - Fetch cache data

=cut
#**********************************************************
sub fetch{
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

  if($function =~ /table_header|progress_bar|/) {
    return q{};
  }

  my ($self, $data) = @_;

  return $data;
}


1
