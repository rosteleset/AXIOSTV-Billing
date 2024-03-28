<form>
  <input type='hidden' name='index' value='$index'>
  <input type='hidden' name='DATE' value='%DATE%'>

  <div class='card card-primary card-outline card-form form-horizontal'>
    <div class='card-body'>

      <div class='form-group row'>
        <label class='col-md-3 control-label'>_{EMPLOYEE}_</label>
        <div class='col-md-9'>
          %ADMIN_SELECT%
        </div>
      </div>
      <div class='form-group row'>
        <label class='col-md-3 control-label'>_{POSITION}_</label>
        <div class='col-md-9'>
          %POSITION_SELECT%
        </div>
      </div>

    </div>
    <div class='card-footer'>
      <input type='submit' name='FILTER' value='_{SHOW}_' class='btn btn-primary'>
    </div>
  </div>

</form>