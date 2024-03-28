<form action='%SELF_URL%'>
  <input type=hidden name='index' value='%index%'/>
  <input type=hidden name='UID' value='%UID%'/>
  <input type=hidden name='COMPANY_ID' value='$FORM{COMPANY_ID}'/>

  <div class='card card-form card-outline card-primary'>
    <div class='card-header with-border'>
      <h4 class='card-title'>_{BILL}_: %BILL_TYPE%</h4>
    </div>
    <div class='card-body'>
      <div class='form-group row'>
        <label class='col-md-4 control-label'>_{BILL}_:</label>
        <div class='col-md-8'>%BILL_ID%:%LOGIN%</div>
      </div>
      <div class='form-group row'>
        <label class='control-label col-md-4' for='CREATE'>_{CREATE}_:</label>
        <div class='col-md-8'>
          <div class='input-group'>
            <div class='input-group-prepend'>
              <div class='input-group-text'>
                <input type='checkbox' class='form-control-static' id='CREATE' name='%CREATE_BILL_TYPE%'
                       %CREATE_BILL% checked data-input-enables='NEW_%CREATE_BILL_TYPE%' value='1'>
              </div>
            </div>
            <input id='NEW_%CREATE_BILL_TYPE%' name='NEW_%CREATE_BILL_TYPE%' class='form-control' type='text' disabled>
          </div>
        </div>
      </div>
      <div class='form-group row'>
        <label class='col-md-4 control-label'>_{TO}_:</label>
        <div class='col-md-8'>
          %SEL_BILLS%
        </div>
      </div>
    </div>
    <div class='card-footer'>
      <input type='submit' class='btn btn-primary float-left button' name='change' value='_{CHANGE}_'/>
    </div>
  </div>
</form>
