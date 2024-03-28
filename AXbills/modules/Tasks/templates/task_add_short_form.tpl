<form class='form-horizontal' id='task_add_form'>
  <input type='hidden' name='index' value='%index%'>
  <input type='hidden' name='ID' value='%ID%'>
  <input type='hidden' name='MSG_ID' value='%MSG_ID%'>
  <input type='hidden' name='LEAD_ID' value='%LEAD_ID%'>
  <input type='hidden' name='DEAL_ID' value='%DEAL_ID%'>
  <input type='hidden' name='STEP_ID' value='%STEP_ID%'>

  <div class='card card-form  card-primary card-outline box-form'>
    <div class='card-header with-border'><h3 class='card-title'>%BOX_TITLE%</h3>
      <div class='card-tools float-right'>
        <button type='button' class='btn btn-tool' data-card-widget='collapse'>
          <i class='fa fa-minus'></i>
        </button>
      </div>
    </div>
    <div class='card-body' id='task_form_body'>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right required' for='task_type'>_{TASK_TYPE}_:</label>
        <div class='col-md-8'>
          %SEL_TASK_TYPE%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label  text-md-right required' for='NAME'>_{TASK_NAME}_:</label>
        <div class='col-md-8'>
          <input class='form-control' name='NAME' id='NAME' value='%NAME%' required>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='DESCR'>_{TASK_DESCRIBE}_:</label>
        <div class='col-md-8'>
          <textarea class='form-control' rows='5' name='DESCR' id='DESCR'>%DESCR%</textarea>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right required' for='responsible'>_{RESPONSIBLE}_:</label>
        <div class='col-md-8'>
          %SEL_RESPONSIBLE%
        </div>
      </div>

      <div class='col-md-12'>&nbsp;</div>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='CONTROL_DATE'>_{DUE_DATE}_:</label>
        <div class='col-md-8'>
          <input type='text' class='datepicker form-control' value='%CONTROL_DATE%' name='CONTROL_DATE' id='CONTROL_DATE'>
        </div>
      </div>
    </div>
    <div class='card-footer'>
      <input type=submit name='%BTN_ACTION%' value='%BTN_NAME%' class='btn btn-primary'>
    </div>
  </div>
</form>

<script>
  let form = jQuery('form#task_add_form')
  let submit_btn = form.find(`button[type='submit']`);

  form.on('submit', function (e) {
    e.preventDefault();

    let formData = form.serialize();
    submit_btn.prop('disabled', true);

    jQuery.post('/admin/index.cgi', `${formData}&add=1`, function (data) {
      submit_btn.prop('disabled', false);
      aModal.hide();
      location.reload();
    });
  });
</script>