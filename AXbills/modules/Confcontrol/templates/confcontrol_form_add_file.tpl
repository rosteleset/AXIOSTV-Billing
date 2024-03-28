<div class='card card-primary card-outline box-form'>
  <div class='card-header with-border'><h4 class='card-title'>_{CONFIG}_ _{FILE}_</h4></div>
  <div class='card-body'>

    <form name='CONF_CONTROL_CONTROLLED_FILES' id='form_CONF_CONTROL_CONTROLLED_FILES' method='post' class='form form-horizontal'>
      <input type='hidden' name='index' value='$index' />
      <input type='hidden' name='ID' value='%ID%' />
      <input type='hidden' name='%SUBMIT_BTN_ACTION%' value='1'/>

      <div class='form-group'>
        <label class='control-label col-md-3 required' for='NAME_id'>$lang{NAME}</label>
        <div class='col-md-9'>
          <input type='text' class='form-control' data-check-for-pattern='(?![/])' required='required' name='NAME' value='%NAME%'  id='NAME_id'  />
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3 required' for='PATH_id'>$lang{PATH}</label>
        <div class='col-md-9'>
          <input type='text' class='form-control' data-check-for-pattern='\/\$' required='required' name='PATH' value='%PATH%'  id='PATH_id'  />
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='COMMENTS_id'>$lang{COMMENTS}</label>
        <div class='col-md-9'>
          <textarea class='form-control'  rows='5'  name='COMMENTS' id='COMMENTS_id' >%COMMENTS%</textarea>
        </div>
      </div>
    </form>

  </div>
  <div class='card-footer'>
    <input type='submit' form='form_CONF_CONTROL_CONTROLLED_FILES' class='btn btn-primary' name='submit' value='%SUBMIT_BTN_NAME%'>
  </div>
</div>

