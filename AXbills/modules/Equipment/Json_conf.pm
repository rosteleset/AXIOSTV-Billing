=head1 NAME Json_conf

  Creating or changing snmp templates

=cut

use strict;
use warnings FATAL => 'all';
use AXbills::Base qw\_bp\;
use JSON;
our ($db, $admin, %conf, $html, %lang, $index, %FORM, $base_dir);


#******************************************************
=head2 json_conf_main() - main function


  RETURNS 1;
=cut
#******************************************************
sub json_conf_main {

  my $TEMPLATE_DIR = $base_dir . 'AXbills/modules/Equipment/snmp_tpl/';

  $html->tpl_show(_include('equipment_json_conf_script', 'Equipment'), { INDEX => $index });
  if ($FORM{add_file} && $FORM{name}) {
    add_file({ NAME => $FORM{name} });
    return 1;
  }
  if ($FORM{remove_file}) {
    remove_file({ FILE => $FORM{remove_file} });
  }
  if ($FORM{file}) {
    if ($FORM{save}) {
      write_file({
        FILE => $FORM{file},
        JSON => $FORM{json_string}
      });
      return 1;
    }
    view_file({
      FILE => $FORM{file}
    });
    return 1;
  }

  my $add_button = $html->button('', undef,
    {
      JAVASCRIPT     => '',
      SKIP_HREF      => 1,
      NO_LINK_FORMER => 1,
      ex_params      => qq/onclick='add_file()'/,
      ICON           => 'fa fa-plus text-success'
    });

  my $table = $html->table({
    id      => 'snmp_tpl_files',
    caption => $lang{FILES_TITLE},
    title   => [ $lang{NAME} ],
    MENU    => $add_button
  });

  opendir my $dir, $TEMPLATE_DIR or $html->message('err', $lang{ERROR}, "$lang{ERROR_DIR} $!");
  my @files = readdir $dir;
  closedir $dir;
  foreach my $file (@files) {
    if ($file ne '.' && $file ne '..' && $file =~ m/.snmp/) {
      $table->addrow(
        $file,
        $html->button('edit', "index=$index&file=$file", { class => 'change' }),
        $html->button('', "index=$index&remove_file=$file", { class => 'fa fa-trash text-danger' })
      );
    }
  }

  print $table->show();
  return 1;
}


#******************************************************
=head2 view_file() - show file

  ATTRIBUTES:
    $attr:
      FILE - file name

  RETURNS: 1

=cut
#******************************************************
sub view_file {
  my ($attr) = @_;

  my $TEMPLATE_DIR = $base_dir . 'AXbills/modules/Equipment/snmp_tpl/';

  if ($attr->{FILE} =~ /\.\.\//) {
    $html->message('err', $lang{ERROR}, "Security error '$attr->{FILE}'.\n");
    return 1;
  }

  my $file_content = file_op({
    FILENAME   => $attr->{FILE},
    PATH       => $TEMPLATE_DIR
  });
  my $file_content_without_comments = $file_content;
  $file_content_without_comments =~ s#//.*$##gm;

  my $attributes = eval {decode_json($file_content_without_comments)};

  my $text_area = $html->form_textarea('json_string', $file_content, { ROWS => 15 });
  my $json_form_content = $html->tpl_show(_include('equipment_json_conf_json_form', 'Equipment'), { TEXT_AREA => $text_area }, { OUTPUT2RETURN => 1 });
  my $json_form = $html->form_main({
    ID      => 'snmp_json_form',
    CONTENT => $json_form_content,
    HIDDEN  => { index => $index, file => $attr->{FILE}, save => $lang{SAVE} },
  });

  print $json_form;

  if ($@) {
    $html->message('err', $lang{ERROR}, $lang{INVALID_JSON}.' '.$TEMPLATE_DIR . $attr->{FILE});
    print $@;
    return 1;
  }
  my $add_main = $html->button('', undef,
    {
      JAVASCRIPT     => '',
      SKIP_HREF      => 1,
      NO_LINK_FORMER => 1,
      ex_params      => qq/onclick='add_row("main")'/,
      ICON           => 'fa fa-plus text-success'
    });

  my $add_info = $html->button('', undef,
    {
      JAVASCRIPT     => '',
      SKIP_HREF      => 1,
      NO_LINK_FORMER => 1,
      ex_params      => qq/onclick='add_row("info")'/,
      ICON           => 'fa fa-plus text-success'
    });

  my $add_status = $html->button('', undef,
    {
      JAVASCRIPT     => '',
      SKIP_HREF      => 1,
      NO_LINK_FORMER => 1,
      ex_params      => qq/onclick='add_row("status")'/,
      ICON           => 'fa fa-plus text-success'
    });

  my $add_ports = $html->button('', undef,
    {
      JAVASCRIPT     => '',
      SKIP_HREF      => 1,
      NO_LINK_FORMER => 1,
      ex_params      => qq/onclick='add_row("ports")'/,
      ICON           => 'fa fa-plus text-success'
    });

  my $main_table = $html->table({
    ID      => 'MAIN',
    caption => 'MAIN',
    title   => [ $lang{NAME}, $lang{VALUE} ],
    MENU    => $add_main
  });

  my $info_table = $html->table({
    ID      => 'INFO',
    caption => 'INFO',
    title   => [ $lang{NAME}, 'OIDS', 'PARSER' ],
    MENU    => $add_info
  });

  my $status_table = $html->table({
    ID      => 'STATUS',
    caption => 'STATUS',
    title   => [ $lang{NAME}, 'OIDS', 'PARSER' ],
    MENU    => $add_status
  });

  my $ports_table = $html->table({
    ID      => 'PORTS',
    caption => 'PORTS',
    title   => [ $lang{TITLE}, $lang{NAME}, 'OIDS', 'PARSER' ],
    MENU    => $add_ports
  });

  foreach my $info (sort keys %{$attributes}) {
    if (ref $attributes->{$info} ne "HASH") {
      my $name_input = $html->form_input($info, $info);
      my $value_input = $html->form_input($info, $attributes->{$info}, { class => 'form-control v_input' });
      $main_table->addrow($name_input, $value_input);
    }
  }

  if ($attributes->{info}) {
    foreach my $info (sort keys %{$attributes->{info}}) {
      my $name_input = $html->form_input($info, $info);
      my $OIDS_input = $html->form_input('info^' . $info . '^OIDS', $attributes->{info}->{$info}->{OIDS}, { class => 'form-control v_input' });
      my $parser_input = $html->form_input('info^' . $info . '^PARSER', $attributes->{info}->{$info}->{PARSER}, { class => 'form-control v_input' });
      $info_table->addrow($name_input, $OIDS_input, $parser_input);
    }
  }

  if ($attributes->{status}) {
    foreach my $info (sort keys %{$attributes->{status}}) {
      my $name_input = $html->form_input($info, $info);
      my $OIDS_input = $html->form_input('status^' . $info . '^OIDS', $attributes->{status}->{$info}->{OIDS}, { class => 'form-control v_input' });
      my $parser_input = $html->form_input('status^' . $info . '^PARSER', $attributes->{status}->{$info}->{PARSER}, { class => 'form-control v_input' });
      $status_table->addrow($name_input, $OIDS_input, $parser_input);
    }
  }

  if ($attributes->{ports}) {
    foreach my $info (sort keys %{$attributes->{ports}}) {
      my $title_input = $html->form_input($info, $info);
      my $name_input = $html->form_input('ports^' . $info . '^NAME', $attributes->{ports}->{$info}->{NAME}, { class => 'form-control v_input' });
      my $OIDS_input = $html->form_input('ports^' . $info . '^OIDS', $attributes->{ports}->{$info}->{OIDS}, { class => 'form-control v_input' });
      my $parser_input = $html->form_input('ports^' . $info . '^PARSER', $attributes->{ports}->{$info}->{PARSER}, { class => 'form-control v_input' });
      $ports_table->addrow($title_input, $name_input, $OIDS_input, $parser_input);
    }
  }

  my $content = $main_table->show() . $info_table->show() . $status_table->show() . $ports_table->show();

  my $form = $html->form_main({
    CONTENT => $content,
    ID      => 'snmp_form',
    HIDDEN  => { index => $index, file => $attr->{FILE} },
    class   => 'form-horizontal',
    SUBMIT  => { submit => $lang{SAVE} }
  });

  print $form;
  return 1;
}

#******************************************************
=head2 write_file() - write new json to file

  ATTRIBUTES:
    $attr:
      FILE - file name
      JSON - JSON string

  RETURNS: 1

=cut
#******************************************************
sub write_file {
  my ($attr) = @_;

  my $TEMPLATE_DIR = $base_dir . 'AXbills/modules/Equipment/snmp_tpl';

  if ($attr->{FILE} =~ /\.\.\//) {
    $html->message('err', $lang{ERROR}, "Security error '$attr->{FILE}'.\n");
    return 1;
  }

  $attr->{JSON} =~ s/\\"/"/g;

  file_op({
    FILENAME   => $attr->{FILE},
    PATH       => $TEMPLATE_DIR,
    WRITE      => 1,
    CONTENT    => $attr->{JSON},
  });

  view_file({ FILE => $attr->{FILE} });

  return 1;
}


#******************************************************
=head2 add_file() - create new file

  ATTRIBUTES:
    $attr:
      NAME - name of new file


  RETURNS: 1

=cut
#******************************************************
sub add_file {
  my ($attr) = @_;

  my $TEMPLATE_DIR = $base_dir . 'AXbills/modules/Equipment/snmp_tpl';

  if ($attr->{NAME} =~ /\.\.\//) {
    $html->message('err', $lang{ERROR}, "Security error '$attr->{NAME}'.\n");
    return 1;
  }

  file_op({
    FILENAME   => $attr->{NAME} . '.snmp',
    PATH       => $TEMPLATE_DIR,
    WRITE      => 1,
    CONTENT    => '{}',
  });

  view_file({ FILE => $attr->{NAME} . '.snmp' });

  return 1;
}


#******************************************************
=head2 remove_file() - removing file

  ATTRIBUTES:
    $attr:
      FILE - file name


  RETURNS: 1

=cut
#******************************************************
sub remove_file {
  my ($attr) = @_;

  my $TEMPLATE_DIR = $base_dir . 'AXbills/modules/Equipment/snmp_tpl/';

  if ($attr->{FILE} =~ /\.\.\//) {
    $html->message('err', $lang{ERROR}, "Security error '$attr->{FILE}'.\n");
    return 1;
  }

  if (unlink $TEMPLATE_DIR . $attr->{FILE}) {
    $html->message('info', $lang{SUCCESS}, $lang{FILE_REMOVED});
  }
  else {
    $html->message('err', $lang{ERROR}, $lang{FILE_NOT_REMOVED});
  }

  return 1;
}



1;
