<style type="text/css">
      .copy-field-info {
            margin-top: 40px;
      }
      .append-field-info {
            margin-top: 40px;
      }

</style>

<form id='LEAD_CONVERT' action='$SELF_URL' method='POST' class='form-horizontal'>

<input type='hidden' name='index' value='%INDEX%'>

<input type='hidden' name='TO_LEAD_ID' value='%TO_LEAD_ID%'>
<input type='hidden' name='LEAD_ID' value='%FROM_LEAD_ID%'>
<input type='hidden' name='BUILD_ID' value='%BUILD_ID%'>
<input type='hidden' name='ADDRESS_FLAT' value='%ADDRESS_FLAT%'>

<div class='row'>
  <div class='col-md-5'>
  %FROM_LEAD_PANEL%
  </div>

<div class='col-md-2'>
  <div class='form-group'>
    <button id='phone' class='btn btn-primary btn-xs append-field-info'
      data-input-name='phone'>_{COPY}_</button>
  </div>
  <div class='form-group'>
    <button id='email' class='btn btn-primary btn-xs append-field-info'
      data-input-name='email'>_{COPY}_</button>
  </div>
  <div class='form-group'>
    <button id='address' class='btn btn-primary btn-xs copy-field-info'
      data-input-name='address'>_{COPY}_</button>
  </div>
  <div class='form-group'>
    <button id='source' class='btn btn-primary btn-xs copy-field-info'
      data-input-name='source'>_{COPY}_</button>
  </div>
  <div class='form-group'>
    <button id='date_registration' class='btn btn-primary btn-xs copy-field-info'
      data-input-name='date_registration'>_{COPY}_</button>
  </div>
  <div class='form-group'>
    <button id='company' class='btn btn-primary btn-xs copy-field-info'
      data-input-name='company'>_{COPY}_</button>
  </div>
</div>

<div class='col-md-5'>
%TO_LEAD_PANEL%
</div>
</div>

<div class='row'>
<input type='submit' name='SAVE' value='_{SAVE}_' class='btn btn-success'>
</div>
</form>

<script>

  var left_panel_postfix = '%LEFT_PANEL_POSTFIX%';
  var right_panel_postfix = '%RIGHT_PANEL_POSTFIX%';

  function copy_from_field_to_field(field_1_id, field_2_id){
    var first_value = jQuery('#' + field_1_id).val();
    jQuery('#' + field_2_id).val(first_value);
  }

  function append_field_to_field(field_1_id, field_2_id){
    var first_value = jQuery('#' + field_1_id).val();
    var second_value = jQuery('#' + field_2_id).val();

    jQuery('#' + field_2_id).val(first_value + ';' + second_value);
  }

  jQuery('button.copy-field-info').on('click', function(event){
      cancelEvent(event);
      var input_name = jQuery(this).data('input-name');

      copy_from_field_to_field(
        input_name + '_' + left_panel_postfix,
        input_name + '_' + right_panel_postfix,
      );

      console.log(input_name)
  })

  jQuery('button.append-field-info').on('click', function(event){
      cancelEvent(event);
      var input_name = jQuery(this).data('input-name');

      append_field_to_field(
        input_name + '_' + left_panel_postfix,
        input_name + '_' + right_panel_postfix,
      );

      console.log(input_name)
  })

</script>