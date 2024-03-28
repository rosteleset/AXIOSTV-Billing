<form action='%SELF_URL%' method='POST' class='form-horizontal'>
  <input type='hidden' name='index' value='%index%'>
  <input type='hidden' name='ID' value='%ACTION_ID%'>

  <div class='card card-primary card-outline card-form'>
    <div class='card-header'>
      <h4 class='card-title'>_{ACTION}_</h4>
    </div>
    <div class='card-body'>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='NAME'>_{NAME}_:</label>
        <div class='col-md-8'>
          <input id='NAME' name='NAME' value='%NAME%' class='form-control' type='text'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='ACTION'>_{ACTION}_:</label>
        <div class='col-md-8'>
          <textarea name='ACTION' id='ACTION' class='form-control'>%ACTION%</textarea>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='SEND_MESSAGE'>_{CRM_SEND_MESSAGE}_:</label>
        <div class='col-md-8'>
          <div class='form-check'>
            <input type='checkbox' class='form-check-input' id='SEND_MESSAGE' name='SEND_MESSAGE' %SEND_MESSAGE%
                   value='1'>
          </div>
        </div>
      </div>

      <div id='MESSAGE_CARD' class='d-none'>
        <div class='form-group row'>
          <label class='col-md-4 col-form-label text-md-right' for='SUBJECT'>_{CRM_SUBJECT_MESSAGE}_:</label>
          <div class='col-md-8'>
            <input id='SUBJECT' name='SUBJECT' value='%SUBJECT%' class='form-control' type='text'>
          </div>
        </div>

        <div class='form-group row'>
          <label class='col-md-4 col-form-label text-md-right' for='MESSAGE'>_{CRM_MESSAGE}_:</label>
          <div class='col-md-8'>
            <textarea name='MESSAGE' id='MESSAGE' class='form-control'>%MESSAGE%</textarea>
          </div>
        </div>
      </div>
    </div>
    <div class='card-footer'>
      <input type='submit' class='btn btn-primary' name='%BTN_NAME%' value='%BTN_VALUE%'>
    </div>
  </div>
</form>

<script>
  jQuery(document).ready(function () {
    jQuery('#SEND_MESSAGE').on('change', function () {
      if (jQuery(this).is(':checked')) {
        jQuery('#MESSAGE_CARD').removeClass('d-none');
      } else {
        jQuery('#MESSAGE_CARD').addClass('d-none');
      }
    });
    jQuery('#SEND_MESSAGE').trigger('change');
  });
</script>