<button type='button' class='btn btn-primary btn-xs float-right' data-toggle='modal' data-target='#holdupModal'>
  _{HOLD_UP}_
</button>

<div id='form_holdup' class='text-center'>

  <div class='modal fade' id='holdupModal'>
    <div class='modal-dialog modal-sm'>
      <div class='modal-content'>
        <div class='modal-header text-center'>
          <button type='button' class='close' data-dismiss='modal' aria-label='Close'>
            <span aria-hidden='true'>&times;</span>
          </button>
          <h4>_{HOLD_UP}_</h4>
        </div>

        <div class='modal-body form form-horizontal'>
          <form action='$SELF_URL' METHOD='GET' id='holdup'>
            <fieldset>
              <input type='hidden' name='index' value='$index'>
              <input type='hidden' name='sid' value='$sid'>
              <input type='hidden' name='UID' value='$FORM{UID}'>

              <div class='form-group'>
                <label class='col-md-3 control-label'>_{FROM}_:</label>

                <div class='col-md-9'>
                  %DATE_FROM%
                </div>
              </div>
              <div class='form-group'>
                <label class='col-md-3 control-label'>_{TO}_:</label>

                <div class='col-md-9'>
                  %DATE_TO%
                </div>

              </div>
              <div class='form-group'>
                <p class='form-control-static'>%DAY_FEES%</p>
              </div>
              <div class='checkbox'>
                <label>
                  <input type='checkbox' name='ACCEPT_RULES' id='ACCEPT_RULES' value='1'>
                  <strong>_{ACCEPT}_</strong>
                </label>
              </div>

            </fieldset>
          </form>
        </div>
        <div class='modal-footer text-center'>
          <input type='submit' value='_{HOLD_UP}_' name='add' form='holdup' class='btn btn-primary'>
        </div>
      </div>
    </div>
  </div>
</div>

