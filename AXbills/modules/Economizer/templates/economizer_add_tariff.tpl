<form action='$SELF_URL' method='POST'>
  <input type='hidden' name='index' value='$index'>
  <div class='card card-primary card-outline container-md card-form'>
  <div class='card-header with-border'><h4 class='card-title'>_{SERVICE}_</h4></div>
    <div class='card-body'>
      <div class='form-group row'>
        <label class='control-label col'>_{LIGHT}_</label>
        <div class='col-md-9'>
          <input type='text' class='form-control' name='LIGHT' value='%LIGHT%'> _{FOR}_ > 0 и < 100 _{KWT}_
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col'>_{LIGHT}_</label>
        <div class='col-md-9'>
          <input type='text' class='form-control' name='LIGHT' value='%LIGHT%'> _{FOR}_ >100 _{KWT}_
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col'>_{GAS}_</label>
        <div class='col-md-9'>
          <input type='text' class='form-control' name='GAS' value='%GAS%'> _{FOR}_ 1 _{M3}_
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col'>_{WATER}_</label>
        <div class='col-md-9'>
          <input type='text' class='form-control' name='WATER' value='%WATER%'> _{FOR}_ 1 _{M3}_
        </div>
      </div>
    </div>
    <div class='card-footer'>
      <input type='submit' class='btn btn-primary' value='%BTN_NAME%'>
    </div>
  </div>
</form>