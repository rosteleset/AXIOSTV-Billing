<form action='$SELF_URL' method='POST'>
  <input type='hidden' name='index' value='$index'>
  <input type='hidden' name='action' value='%ACTION%'>
  <input type='hidden' name='ID' value='%ID%'>
  <input type='hidden' name='sid' value='$sid'>

  <div class='card box-primary form-horizontal'>
    <div class='card-header with-border'><h4 class='card-title'>_{PUBLIC_UTILITIES}_</h4></div>
    <div class='card-body'>
      <div class='form-group row'>
        <label class='col-md-3 control-label required'>_{DATE}_</label>
        <div class='col-md-9'>
          <input type='text' name='DATE' VALUE='%DATE%' class='form-control datepicker' required='required'>
        </div>
      </div>
      <hr>
      <div class='form-group row'>
        <label class='col-md-3 control-label required'>_{LIGHT}_, _{KWT}_</label>
        <div class='col-md-9'>
          <input type='text' class='form-control' name='LIGHT' value='%LIGHT%' required='required' placeholder='_{INPUT_COUNTER}_'>
        </div>
      </div>
      <div class='form-group row'>
        <label class='col-md-3 control-label required'>_{GAS}_, _{M3}_</label>
        <div class='col-md-9'>
          <input type='text' class='form-control' name='GAS' value='%GAS%' required='required' placeholder='_{INPUT_COUNTER}_'>
        </div>
      </div>
      <div class='form-group row'>
        <label class='col-md-3 control-label required'>_{WATER}_, _{M3}_</label>
        <div class='col-md-9'>
          <input type='text' class='form-control' name='WATER' value='%WATER%' required='required' placeholder='_{INPUT_COUNTER}_'>
        </div>
      </div>
      <div class='form-group row'>
        <label class='col-md-3 control-label'>_{CALC_COST}_</label>
        <div class='form-check'>
          <input type='checkbox' name='CALC_COST'>
        </div>
      </div>
      <div class='form-group row'>
        <label class='col-md-3 control-label required'>_{COMMUNAL}_, _{GRN}_</label>
        <div class='col-md-9'>
          <input type='text' class='form-control' name='COMMUNAL' value='%COMMUNAL%' required='required' placeholder='_{INPUT_MONEY}_'>
        </div>
      </div>
      <hr>
      <div class='form-group row'>
        <label class='col-md-3 control-label'>_{COMMENTS}_</label>
        <div class='col-md-9'>
          <textarea class='form-control' name='COMMENTS' rows='3'>%COMMENTS%</textarea>
        </div>
      </div>
    </div>
    <div class='card-footer'>
      <input  type='submit' class='btn btn-primary' value='%BTN_NAME%'>
    </div>
  </div>

</form>
