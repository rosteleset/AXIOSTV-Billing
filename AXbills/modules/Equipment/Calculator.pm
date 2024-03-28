=head1 NAME PON_Calculator

  Calculate signal

=cut

use strict;
use warnings FATAL => 'all';
use AXbills::Base qw\_bp\;
use JSON;

our (%lang, %FORM, $db, $admin, $SELF_URL);

our AXbills::HTML $html;
our $Equipment = Equipment->new($db, $admin, \%conf);

#************************************************************
=head2 calculator_main() - main function

  Returns: 1
=cut
#************************************************************
sub calculator_main {


  if($FORM{new_types}){
    $FORM{new_types} =~ s/\\"/"/g;
    my $new_types = decode_json($FORM{new_types});

    foreach my $type (keys %$new_types){
      $Equipment->calculator_delete($type);
      foreach (keys %{$new_types->{$type}}) {
          $Equipment->calculator_add({
          TYPE  => $type,
          NAME  => $_,
          VALUE => $new_types->{$type}->{$_}
        });
      }
    }

    $html->message('info', $lang{SUCCESS}, $lang{SAVED});
    $html->redirect($SELF_URL.'?index='.get_function_index("calculator_main"));
  }

  my $add_olt = $html->button('', undef,
    {
      JAVASCRIPT     => '',
      SKIP_HREF      => 1,
      NO_LINK_FORMER => 1,
      ex_params      => qq/onclick='add_row("olt")'/,
      ICON           => 'fa fa-plus text-success'
    });

  my $add_splitter = $html->button('', undef,
    {
      JAVASCRIPT     => '',
      SKIP_HREF      => 1,
      NO_LINK_FORMER => 1,
      ex_params      => qq/onclick='add_row("splitter")'/,
      ICON           => 'fa fa-plus text-success'
    });

  my $add_divider = $html->button('', undef,
    {
      JAVASCRIPT     => '',
      SKIP_HREF      => 1,
      NO_LINK_FORMER => 1,
      ex_params      => qq/onclick='add_row("divider")'/,
      ICON           => 'fa fa-plus text-success'
    });


  my $tables->{olt_table} = $html->table({
    ID      => 'OLT',
    caption => 'OLT',
    title   => [ $lang{NAME}, $lang{VALUE} ],
    MENU    => $add_olt
  });

  $tables->{splitter_table} = $html->table({
    ID      => 'SPLITTER',
    caption => $lang{SPLITTER},
    title   => [ $lang{NAME}, $lang{VALUE} ],
    MENU    => $add_splitter
  });

  $tables->{divider_table} = $html->table({
    ID      => 'DIVIDER',
    caption => $lang{DIVIDER},
    title   => [ $lang{NAME}, $lang{VALUE} ],
    MENU    => $add_divider
  });

  $tables->{connector_table} = $html->table({
    ID      => 'CONNECTOR',
    caption => $lang{CONNECTOR},
    title   => [ $lang{NAME}, $lang{VALUE} ],
  });

  my $list = $Equipment->calculator_list({
    COLS_NAME => 1
  });

  my %types = ();

  for (@$list){
    $types{$_->{type}}->{$_->{value}} = $_->{name};
  }

  foreach my $info (keys %types) {
    for my $value (keys %{$types{$info}}) {
      my $name_input = $html->form_input($types{$info}{$value}, $types{$info}{$value});
      my $value_input = $html->form_input("$info^$types{$info}{$value}", $value, { class => 'form-control v_input' });
      $tables->{$info.'_table'}->addrow($name_input, $value_input);
    }
  }


  my $content = "";
  foreach (sort keys %$tables){
    $content .= $tables->{$_}->show();
  }


  my $form = $html->form_main({
    CONTENT => $content,
    ID      => 'calculator_types',
    HIDDEN  => { index => $index, new_types=>'' },
    class   => 'form-horizontal',
    SUBMIT  => { submit => $lang{SAVE} }
  });

  $html->tpl_show(_include('equipment_calculator', 'Equipment'),
    {
      OLT       => $types{olt} ? encode_json($types{olt}) : '{}',
      SPLITTER  => $types{splitter} ? encode_json($types{splitter}) : '{}',
      DIVIDER   => $types{divider} ? encode_json($types{divider}) : '{}',
      CONNECTOR => $types{connector} ? encode_json($types{connector}) : '{}',
      FORM => $form
    });
  return 1;
}


1;