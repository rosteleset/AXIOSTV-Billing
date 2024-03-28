package AXbills::Templates::Generator;
use strict;
use warnings FATAL => 'all';

=head1 NAME

  AXbills::Templates::Generator 

=head2 SYNOPSIS

  This package contains logic to create templates from simple template logic

  Template language and supported elements:
    Text input:              text:$label:$name:$placeholder:$required
    Hidden input:            hidden:$name
    Textarea:                textarea:$label:$name:$placeholder:$required
    Checkbox:                checkbox:$label:$name:$checked:$required
    Select:                  select:$label:$name:$required
    Start collapsing panel:  collapse:$label:$name
    End collapsing panel:    collapse_end:

  You also can use templates.cgi for convinient creating of templates

=cut
use parent 'Exporter';

our @EXPORT = qw/
  generate_template
  form_text_input_row
  form_checkbox_input_row
  form_select_row
  form_hidden_row
  form_textarea_input_row
  start_collapse_panel
  close_collapse_panel
  /;

our @EXPORT_OK = qw/
  generate_template
  /;

#**********************************************************
=head2 generate_template($template_description)

=cut
#**********************************************************
sub generate_template {
  my ($template_description) = @_;

  my @rows = split("\n+", $template_description);

  my $result = '';
  foreach my $row (@rows) {
    my @element = split(':', _trim($row));

    my $type = shift(@element);

    if ($type eq 'checkbox') {
      $result .= form_checkbox_input_row(@element);
    }
    elsif ($type eq 'textarea') {
      $result .= form_textarea_input_row(@element);
    }
    elsif ($type eq 'select') {
      $result .= form_select_row(@element);
    }
    elsif ($type eq 'hidden') {
      $result .= form_hidden_row(@element);
    }
    elsif ($type eq 'collapse') {
      $result .= start_collapse_panel(@element);
    }
    elsif ($type eq 'collapse_') {
      $result .= close_collapse_panel();
    }
    else {
      $result .= form_text_input_row(@element);
    }
  }

  return $result;
}

#**********************************************************
=head2 form_text_input_row($label, $name, $placeholder, $required)

=cut
#**********************************************************
sub form_text_input_row {
  my ($label, $name, $placeholder, $required) = @_;

  my $id = '';
  my $attr_id = '';
  my $attr_name = '';
  my $prop_required = '';

  $placeholder = _to_attr('placeholder', $placeholder);

  if ( $name ne '' ) {
    $attr_name = _to_attr('name', $name);
    $id = $name . "_ID";
    $attr_id = _to_attr('id', $id);
  }

  #    show($required);
  if ( $required eq '1' ) {
    $prop_required = ' required';
  }

  my $element = "
      <div class='form-group'>
        <label class='control-label col-md-3$prop_required' for='$id'>$label</label>
        <div class='col-md-9'>
            <input type='text' class='form-control' value='%$name%' $prop_required$attr_name$attr_id$placeholder />
        </div>
      </div>\n";

  return $element;

}

#**********************************************************
=head2 form_checkbox_input_row($label, $name, $required)

=cut
#**********************************************************
sub form_checkbox_input_row {
  my ($label, $name, $required) = @_;

  my $prop_required = '';
  my $attr_id = _to_attr('id', $name . '_ID');

  if ( $required eq '1' ) {
    $prop_required = 'required="required"';
  }

  my $element = "
      <div class='checkbox text-center'>
        <label>
            <input type='checkbox' data-return='1' data-checked='%$name%' name='$name' $prop_required $attr_id />
            <strong>$label</strong>
        </label>
      </div>\n";

  return $element;
}

#**********************************************************
=head2 form_select_row($label, $name, $required)

=cut
#**********************************************************
sub form_select_row {
  my ($label, $name, $required) = @_;

  my $prop_required = '';
  if ( $required eq '1' ) {
    $prop_required = ' required';
  }

  my $element = "
      <div class='form-group'>
        <label class='control-label col-md-3$prop_required' for='$name'>$label</label>
        <div class='col-md-9'>
            %$name\_SELECT%
        </div>
      </div>\n";

  return $element;
}

#**********************************************************
=head2 form_hidden_row($name)

=cut
#**********************************************************
sub form_hidden_row {
  my ($name) = @_;

  return "<input type='hidden' name='$name' value='%$name%' />
  ";
}

#**********************************************************
=head2 form_textarea_input_row($label, $name, $required)

=cut
#**********************************************************
sub form_textarea_input_row {
  my ($label, $name, $required) = @_;

  my $attr_rows = _to_attr('rows', 5);

  my $id = $name . '_ID';

  my $prop_required = '';
  if ( $required eq '1' ) {
    $prop_required = ' required';
  }

  my $element = "
      <div class='form-group'>
          <label class='control-label col-md-3$prop_required' for='$id'>$label</label>
          <div class='col-md-9'>
              <textarea class='form-control col-md-9' $attr_rows$prop_required name='$name' id='$id'>%$name%</textarea>
          </div>
      </div>\n";

  return $element;

}

#**********************************************************
=head2 start_collapse_panel($label, $name)

=cut
#**********************************************************
sub start_collapse_panel {
  my ($label, $name) = @_;

  $name = _trim($name);
  my $collapse_id = $name . "_collapse";
  my $heading_id = $name . "_heading";

  my $element = "
    <div class='form-group'>
      <div class='card card-primary card-outline'>
          <div class='card-header with-border' role='tab' id='$heading_id'>
            <h4 class='card-title text-center'>
              <a role='button' data-toggle='collapse' href='#$collapse_id' aria-expanded='true' aria-controls='$collapse_id'>
                $label
              </a>
            </h4>
          </div>
        <div id='$collapse_id' class='card-collapse collapse' role='tabpanel' aria-labelledby='$heading_id'>
        <div class='card-body'>
        ";

  return $element;
}

#**********************************************************
=head2 close_collapse_panel()

=cut
#**********************************************************
sub close_collapse_panel {
  return "       </div> <!-- end of collapse panel-body -->
      </div> <!-- end of collapse div -->
      </div> <!-- end of collapse panel -->
    </div> <!-- end of collapse form-group -->
";
}

#**********************************************************
=head2 _to_attr($name, $value)

=cut
#**********************************************************
sub _to_attr {
  my ($name, $value) = _trim(@_);

  if ( $value ne '' ) {
    return " $name='" . $value . "' ";
  }

  return '';
}

#**********************************************************
=head2 _trim(@input)

=cut
#**********************************************************
sub _trim {
  my @out = @_;
  for ( @out ) {
    s/^\s+//;
    s/\s+$//;
    s/\n$//;
  }
  return wantarray ? @out : $out[0];
}


1;