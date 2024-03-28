<form id='form_contract_type' class='form form-horizontal'>
  <input type='hidden' name='index' value='$index' />
  <input type='hidden' name='chg' value='$FORM{chg}' />
  <div class='card card-primary card-outline card-form'>
    <div class='card-header with-border'>
      <h4 class='card-title'>_{TYPES}_ _{CONTRACTS}_</h4>
    </div>
    <div class='card-body'>
      <div class='form-group row'>
        <label class='control-label col-md-3' for='NAME'>_{NAME}_</label>
        <div class='input-group col-md-9'>
          <input type='text' class='form-control' value='%NAME%'  name='NAME'  id='NAME'  />
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-3' for='TEMPLATE'>_{TEMPLATE}_</label>
        <div class='input-group col-md-9'>
          <input type='text' class='form-control' value='%TEMPLATE%'  name='TEMPLATE'  id='TEMPLATE'  />
        </div>
      </div>

    </div>

    <div class='card-footer'>
      <input type='submit' class='btn btn-primary' name='%BTN_NAME%' value='%BTN_VALUE%'>
    </div>
  </div>
</form>