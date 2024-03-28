<div class='card card-primary card-outline box-form'>
  <div class='card-header with-border'><h4 class='card-title'>_{SERVICE}_</h4></div>
  <div class='card-body'>
    <form name='sysinfo_services' id='form_sysinfo_services' method='post' class='form form-horizontal'>
      <input type='hidden' name='index' value='$index'/>
      <input type='hidden' name='%SUBMIT_BTN_ACTION%' value='1'/>
      <input type='hidden' name='ID' value='%ID%'/>
      <input type='hidden' name='SERVER_ID' value='%SERVER_ID%'/>

      <div class='form-group'>
        <label class='control-label col-md-3 required' for='NAME_ID'>_{NAME}_</label>
        <div class='col-md-9'>
          <input type='text' class='form-control' value='%NAME%' required name='NAME' id='NAME_ID'/>
        </div>
      </div>
<!--

      <div class='checkbox text-center'>
        <label>
          <input type='checkbox' data-return='1' data-checked='%ENABLED%' name='ENABLED' id='ENABLED_ID'/>
          <strong>_{ENABLED}_</strong>
        </label>
      </div>
-->

      <div class='form-group'>
        <label class='control-label col-md-3' for='COMMENTS_ID'>_{COMMENTS}_</label>
        <div class='col-md-9'>
          <textarea class='form-control col-md-9' rows='5' name='COMMENTS' id='COMMENTS_ID'>%COMMENTS%</textarea>
        </div>
      </div>
    </form>

    <div class='form-group'>
      <div class='card card-primary card-outline'>
        <div class='card-header with-border' role='tab' id='_heading'>
          <h4 class='card-title text-center'>
            <a role='button' data-toggle='collapse' href='#_collapse' aria-expanded='true' aria-controls='_collapse'>
              _{EXTRA}_
            </a>
          </h4>
        </div>
        <div id='_collapse' class='card-collapse collapse' role='tabpanel' aria-labelledby='_heading'>
          <div class='card-body'>

            <div class='form-group'>
              <label class='control-label col-md-3 required'
                     for='CHECK_STATUS_COMMAND_ID'>_{CHECK_STATUS_COMMAND}_</label>
              <div class='col-md-9'>
                <input type='text' class='form-control' value='%CHECK_COMMAND%' name='CHECK_COMMAND'
                       id='CHECK_STATUS_COMMAND_ID'/>
              </div>
            </div>

          </div> <!-- end of collapse panel-body -->
        </div> <!-- end of collapse div -->
      </div> <!-- end of collapse panel -->
    </div> <!-- end of collapse form-group -->


  </div>
  <div class='card-footer'>
    <input type='submit' form='form_sysinfo_services' class='btn btn-primary' name='submit' value='%SUBMIT_BTN_NAME%'>
  </div>
</div>

