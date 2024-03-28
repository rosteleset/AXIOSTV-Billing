<form action='$SELF_URL' method='POST' class='form-horizontal'>
  <input type='hidden' name='index' value='$index'>
  <input type='hidden' name='ID' value='%ID%'>

  <div class='card card-primary card-outline card-form'>
    <div class='card-header with-border'>
      <h4 class='card-title'>_{ADMINS}_</h4>
    </div>
    <div class='card-body'>
      <div class='form-group row'>
        <label class='col-md-4 control-label'>_{ADMINS}_:</label>
        <div class='col-md-8'>
          %ADMINS_SELECT%
        </div>
      </div>
      <div class='form-group row'>
        <label class='col-md-4 control-label'>_{PERCENT}_, %:</label>
        <div class='col-md-8'>
          <input name='PERCENT' value='%PERCENT%' class='form-control'>
        </div>
      </div>
      <div class='form-group row'>
        <label class='col-md-4 control-label'>_{COMMENTS}_:</label>
        <div class='col-md-8'>
          <textarea name='COMMENTS' class='form-control'>%COMMENTS%</textarea>
        </div>
      </div>
    </div>
    <div class='card-footer'>
      <input type='submit' class='btn btn-primary' name='%BTN_NAME%' value='%BTN_VALUE%'>
    </div>
  </div>
</form>