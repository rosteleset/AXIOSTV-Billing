<div class='card card-primary card-outline card-form'>
  <div class='card-header with-border'><h4 class='card-title'>_{TAX_MAGAZINE}_</h4></div>
  <div class='card-body'>
    <form name='%FORM_NAME%' id='form_%FORM_NAME%' method='GET' class='form form-horizontal'>
      <input type='hidden' name='index' value='$index'/>
      <input type='hidden' name='ID' value='%ID%'/>

      <div class="form-group row">
        <label class='col-md-3 control-label' for='RATECODE_ID'>_{CODE}_ _{_TAX}_:</label>
        <div class="col-md-9">
          <div class="input-group">
            <input type='text' class='form-control' required name='RATECODE' id='RATECODE_ID' value='%RATECODE%'/>
          </div>
        </div>
      </div>

      <div class="form-group row">
        <label class='col-md-3 control-label' for='RATEAMOUNT_ID'>_{PERCENT}_ _{_TAX}_:</label>
        <div class="col-md-9">
          <div class="input-group">
            <input type='text' class='form-control' name='RATEAMOUNT' id='RATEAMOUNT_ID' value='%RATEAMOUNT%'/>
          </div>
        </div>
      </div>

      <div class="form-group row">
        <label class='col-md-3 control-label' for='RATEDESCR_ID'>_{DESCRIBE}_:</label>
        <div class="col-md-9">
          <div class="input-group">
            <textarea rows="2" class='form-control' cols="45" name="RATEDESCR" id='RATEDESCR_ID'
                      value='%RATEDESCR%'></textarea>
          </div>
        </div>
      </div>

      <div class="form-group custom-control custom-checkbox">
        <input class="custom-control-input" type="checkbox" id="CURRENT_ID" name="CURRENT" %CURRENT%
               value='1' data-checked='%CURRENT%' data-return='1'>
        <label for="CURRENT_ID" class="custom-control-label">_{IN_USING}_</label>
      </div>

    </form>

  </div>
  <div class='card-footer'>
    <input type='submit' form='form_%FORM_NAME%' class='btn btn-primary' name='%ACTION%' value="%BTN%">
  </div>
</div>
