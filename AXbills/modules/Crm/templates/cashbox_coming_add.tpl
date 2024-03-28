<form action='$SELF_URL' METHOD=POST>

<input type='hidden' name='index' value=$index>
<input type='hidden' name='ID' value='%ID%'>

<div class='box box-form box-primary form-horizontal'>
<div class='box-header with-border'>_{COMING}_</div>
<div class='box-body'>
  <div class='form-group'>
    <label class='col-md-3 control-label'>_{SUM}_</label>
    <div class='col-md-9'>
      <input type='number' step='0.01' class='form-control' name='AMOUNT' value='%AMOUNT%'>
    </div>
  </div>
  <div class='form-group'>
    <label class='col-md-3 control-label'>_{COMING}_ _{TYPE}_</label>
    <div class='col-md-9'>
      %COMING_TYPE_SELECT%
    </div>
  </div>
  <div class='form-group'>
    <label class='col-md-3 control-label'>_{CASHBOX}_</label>
    <div class='col-md-9'>
      %CASHBOX_SELECT%
    </div>
  </div>
  <div class='form-group'>
    <label class='col-md-3 control-label'>_{DATE}_</label>
    <div class='col-md-9'>
      <input type='text' class='form-control datepicker' name='DATE' value='%DATE%'>
    </div>
  </div>
  <div class='form-group'>
    <label class='col-md-3 control-label'>_{COMMENTS}_</label>
    <div class='col-md-9'>
      <textarea class='form-control' name='COMMENTS'>%COMMENTS%</textarea>
    </div>
  </div>
</div>
<div class='box-footer'>
  <input type='submit' class='btn btn-primary' value='%ACTION_LANG%' name='%ACTION%'>
</div>
</div>

</form>