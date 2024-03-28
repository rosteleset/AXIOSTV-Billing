<form method='POST'>

<input type='hidden' name='index' value='$index'>
<input type='hidden' name='ID' value='%ID%'>

<div class='card card-primary card-outline card-form'>

<div class='card-header with-border'>
  <h3 class='card-title'>_{ADD}_ _{GROUP}_</h3>
</div>

<div class='card-body'>
  <div class='form-group row'>
  <label class='col-md-3 control-label'>_{NAME}_</label>
    <div class='col-md-9'>
      <input type='text' name='NAME' value='%NAME%' class='form-control'>
    </div>
  </div>
  <div class='form-group row'>
  <label class='col-md-3 control-label'>_{COMMENTS}_</label>
    <div class='col-md-9'>
      <textarea class='form-control' name='COMMENT'>%COMMENT%</textarea>
    </div>
  </div>
</div>

<div class='card-footer'>
  <input type='submit' name='%BTN_NAME%' value='%BTN_VALUE%' class='btn btn-primary'>
</div>

</div>

</form>