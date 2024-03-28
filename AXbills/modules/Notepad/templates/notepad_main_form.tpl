<form class='form-horizontal' name='notepad_form' method='POST'>
  <input type=hidden name='index' value='$index'>
  <input type='hidden' name='%SUBMIT_BTN_ACTION%' value='1' />
  <input type=hidden name='ID' value='$FORM{chg}'>

  <div class='card card-primary card-outline container col-md-6'>
    <div class='card-header with-border'><h4 class='card-title'>_{NOTE}_</h4></div>

    <div class='card-body'>

      <div class='form-group row' data-visible='%CAN_SELECT_AID%'>
        <label class='control-label col-md-2' for='AID'>_{ADMIN}_:</label>
        <div class='col-md-9'>
          %AID_SELECT%
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-2' for='SHOW_AT'>_{DATE}_:</label>
        <div class='col-md-9'>
          %DATETIMEPICKER%
        </div>
      </div>

      <div class='form-group row'>
        <div class='col-md-7 row'>
          <label class='control-label col-md-4' for='START_STAT'>_{START}_: </label>
          <div class='col-md-5'>
            %START_STAT%
          </div>
        </div>
        <div class='col-md-5 row'>
          <label class='control-label col-md-4' for='END_STAT'>_{END}_: </label>
          <div class='col-md-7'>
            %END_STAT%
          </div>
        </div>
      </div>

      <hr/>

      %PERIODIC%

      <div class='form-group row'>
        <label class='control-label col-md-2'>_{STATUS}_:</label>
        <div class='col-md-9'>
          %STATUS_SELECT%
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-2'>_{STICKER}_:</label>
        <div class='col-md-9'>
          %STICKER_STATUS%
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-2' for='SUBJECT'>_{SUBJECT}_:</label>
        <div class='col-md-9'>
          <input class='form-control' type='text' name='SUBJECT' id='SUBJECT' required='required' value='%SUBJECT%'/>
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-2' for='TEXT'>_{TEXT}_:</label>
        <div class='col-md-9'>
          <textarea name='TEXT' id='TEXT' rows='4' class='form-control'>%TEXT%</textarea>
        </div>
      </div>

      <div class='form-group row' data-visible='%ID%'>
        <label class='control-label col-md-2'>_{LIST}_:</label>
        <div class='col-md-9'>
          %CHECKLIST%
        </div>
      </div>

    </div>
    <div class='card-footer'>
      <input class='btn btn-primary' type='submit' name='%ACTION%' value='%SUBMIT_BTN_NAME%'/>
    </div>
  </div>
</form>
