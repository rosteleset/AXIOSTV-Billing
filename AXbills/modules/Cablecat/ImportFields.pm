use strict;
use warnings 'FATAL' => 'all';

our (%lang, $html, %FORM);

require Cablecat::Selects;

#**********************************************************
=head2 _cablecat_well_types_select($attr)

=cut
#**********************************************************
sub cablecat_import_wells {
  my @output_fields = (
    {
      NAME       => $lang{NAME},
      FIELD_NAME => 'NAME',
      INPUT      => $html->form_input('', '', { ID => 'DEFAULT_OBJECT_NAME', EX_PARAMS => "class='float-right' placeholder='$lang{NAME} $lang{DEFAULT}'", OUTPUT2RETURN => 1 })
    },
    {
      NAME       => $lang{TYPE},
      FIELD_NAME => 'TYPE_ID',
      INPUT      => _cablecat_well_types_select()
    },
    {
      NAME       => $lang{INSTALLED},
      FIELD_NAME => 'INSTALLED',
      INPUT      =>  $html->form_datepicker(),
    },
    {
      NAME       => $lang{'OBJECT'},
      FIELD_NAME => 'ADD_OBJECT',
      INPUT      => $html->form_input('', '', { ID => 'DEFAULT_ADD_OBJECT', TYPE => 'checkbox',  EX_PARAMS => "class='float-right'", OUTPUT2RETURN => 1 })
    },
    {
      NAME       => 'COORDX',
      FIELD_NAME => 'COORDX',
    },
    {
      NAME       => 'COORDY',
      FIELD_NAME => 'COORDY',
    },
  );

  return {
    FIELDS_LIST  => cablecat_import_build_output_fields_list(\@output_fields),
    RESULT_INDEX => get_function_index('cablecat_wells'),
    IMPORT_INDEX => get_function_index('cablecat_wells'),
  }
}

#**********************************************************
=head2 cablecat_import_build_output_fields_list($fields)

=cut
#**********************************************************
sub cablecat_import_build_output_fields_list {
  my ($fields) = @_;
  my $fields_list = '';

  foreach my $output_field (@{ $fields }) {
    $fields_list .= cablecat_import_build_output_field(
      $output_field->{NAME},
      $output_field->{FIELD_NAME},
      $output_field->{INPUT},
    );
  }

  return $fields_list
}

#**********************************************************
=head2 cablecat_import_build_output_field($name, $field_name, $default_select)
  Arguments:
    $name - human readable field name
    $field_name - field name in database
    $default_select - input in field card to select default value
=cut
#**********************************************************
sub cablecat_import_build_output_field {
  my ($name, $field_name, $default_select) = @_;

  return $html->tpl_show(_include('cablecat_import_output_field', 'Cablecat'), {
    NAME       => $name,
    FIELD_NAME => $field_name,
    INPUT      => $default_select
  }, {
    OUTPUT2RETURN => 1
  });
}