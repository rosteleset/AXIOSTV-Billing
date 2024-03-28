<form method='POST' action='$SELF_URL' class='form-horizontal'>
  <input type='hidden' name='index' value='$index'>
  <input type='hidden' name='SERVICE_ID' value='%SERVICE_ID%'>
  <input type='hidden' name='extra_params' value=1>
  <input type='hidden' name='chg_param' value='%CHG%'>

  <div class='card card-primary card-outline card-form'>
    <div class='card-header with-border'><h4 class='card-title'>%PARAMS_ACTION%</h4></div>
    <div class='card-body'>
      <div class='form-group row'>
        <label class='control-label col-md-4'>_{GROUP}_:</label>
        <div class='col-md-8'>
          %GROUP_LIST%
        </div>
      </div>
      <div class='form-group row'>
        <label class='control-label col-md-4'>_{TARIF_PLAN}_:</label>
        <div class='col-md-8'>
          %TP_LIST%
        </div>
      </div>
      <div class='form-group row'>
        <label class='control-label col-md-4' for='PIN'>PIN: </label>
        <div class='col-md-8'>
          <input type='text' class='form-control' id='PIN' name='PIN' value='%PIN%'/>
        </div>
      </div>
      <div class='form-group row'>
        <label class='control-label col-md-4' for='IP'>IP: </label>
        <div class='col-md-8'>
          <input type='text' class='form-control' id='IP' name='IP' value='%IP%'/>
        </div>
      </div>
      <div class='form-group row'>
        <label class='control-label col-md-4' for='SEND_SMS'>_{SEND}_ SMS: </label>
        <div class='col-md-8'>
          <input type='checkbox' class='plugin_checkbox' data-checked='%SEND_SMS%' id='SEND_SMS' name='SEND_SMS'
                 value='1'/>
        </div>
      </div>
      <div class='form-group row'>
        <label class='col-md-4 control-label' for='SMS_TEXT'>SMS _{TEXT}_</label>
        <div class='col-md-8'>
          <textarea name='SMS_TEXT' id='SMS_TEXT' class='form-control'>%SMS_TEXT%</textarea>
        </div>
      </div>
      <div class='form-group row'>
        <label class='col-md-4 control-label' for='BALANCE'>_{DEPOSIT}_</label>
        <div class='col-md-8'>
          <input class='form-control' id='BALANCE' name='BALANCE' type='number' step='0.01' value='%BALANCE%'>
        </div>
      </div>
      <div class='form-group row'>
        <label class='col-md-4 control-label' for='MAX_DEVICE'>_{MAX_DEVICES}_</label>
        <div class='col-md-8'>
          <input class='form-control' id='MAX_DEVICE' name='MAX_DEVICE' type='number' step='1' value='%MAX_DEVICE%'>
        </div>
      </div>
    </div>
    <div class='card-footer'>
      <input type='submit' class='btn btn-primary' name='%BTN_ACTION%' value='%BTN_LNG%'>
    </div>
  </div>
</form>