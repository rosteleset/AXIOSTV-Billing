<button type='button' class='btn btn-primary btn-xs float-right' data-toggle='modal' data-target='#holdupModal_%ID%'>
  _{HOLD_UP}_
</button>

<div id='form_holdup'>
  <div class='modal fade' id='holdupModal_%ID%'>
    <div class='modal-dialog modal-sm'>
      <div class='modal-content'>
        <div class='modal-header'>
          <h4>_{HOLD_UP}_</h4>
          <button type='button' class='close' data-dismiss='modal' aria-label='Close'>
            <span aria-hidden='true'>&times;</span>
          </button>
        </div>

        <div class='modal-body'>
          <form action='$SELF_URL' METHOD='GET' id='holdup_%ID%'>
            <fieldset>
              <input type='hidden' name='index' value='$index'>
              <input type='hidden' name='sid' value='$sid'>
              <input type='hidden' name='UID' value='$FORM{UID}'>
              <input type='hidden' name='ID' value='%ID%'>

              <div class='form-group row'>
                <label class='col-md-3 control-label' FOR='FROM_DATE'>_{FROM}_:</label>

                <div class='col-md-9'>
                  <input type='text' name='FROM_DATE' value='%FROM_DATE%' size='10' class='form-control datepicker'
                         id='FROM_DATE' form='holdup_%ID%'>
                </div>
              </div>
              <div class='form-group row'>
                <label class='col-md-3 control-label' for='TO_DATE'>_{TO}_:</label>
                <div class='col-md-9'>
                  <input type='text' name='TO_DATE' value='%TO_DATE%' size='10' class='form-control datepicker'
                         id='TO_DATE' form='holdup_%ID%'>
                </div>
              </div>
              <div class='form-group row'>
                <p class='form-control-static'>%DAY_FEES%</p>
              </div>
              <div class='checkbox text-center'>
                <label class='required' for='ACCEPT_RULES'>
                  <strong>_{ACCEPT}_</strong>
                </label>
                <input type='checkbox' name='ACCEPT_RULES' id='ACCEPT_RULES' value='1' required>
              </div>

            </fieldset>
          </form>
        </div>
        <div class='modal-footer text-center'>
          <input type='submit' value='_{HOLD_UP}_' name='add' form='holdup_%ID%' class='btn btn-primary'>
        </div>
      </div>
    </div>
  </div>
</div>

