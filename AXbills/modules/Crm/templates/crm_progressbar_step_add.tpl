<form name='CRM_PROGRESSBAR_STEP_ADD' id='form_CRM_PROGRESSBAR_STEP_ADD' method='post' class='form form-horizontal'>

  <input type='hidden' name='index' value='$index'/>
  <input type='hidden' name='ID' value='%ID%'/>

  <div class='card card-primary card-outline card-form'>
    <div class='card-header with-border'>
      <h4 class='card-title'>_{STEP}_</h4>
    </div>
    <div class='card-body'>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right required' for='STEP_NUMBER'>_{NUMBER}_:</label>
        <div class='col-md-8'>
          <input type='number' class='form-control' id='STEP_NUMBER' name='STEP_NUMBER' VALUE='%STEP_NUMBER%' min='1'
                 required>
        </div>
      </div>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='NAME'>_{NAME}_:</label>
        <div class='col-md-8'>
          <input type='text' class='form-control' id='NAME' name='NAME' VALUE='%NAME%'>
        </div>
      </div>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='COLOR'>_{COLOR}_:</label>
        <div class='col-md-8'>
          <input type='color' class='form-control' id='COLOR' name='COLOR' VALUE='%COLOR%'>
        </div>
      </div>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='DESCRIPTION'>_{DESCRIBE}_:</label>
        <div class='col-md-8'>
          <textarea name='DESCRIPTION' id='DESCRIPTION' class='form-control'>%DESCRIPTION%</textarea>
        </div>
      </div>
    </div>
    <div class='card-footer'>
      <input type='submit' class='btn btn-primary' name='%BTN_NAME%' value='%BTN_VALUE%'>
    </div>
  </div>
</form>
