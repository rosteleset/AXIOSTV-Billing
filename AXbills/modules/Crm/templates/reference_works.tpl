<form action='$SELF_URL' METHOD=POST>

<input type='hidden' name='index' value=$index>
<input type='hidden' name='ID' value=%ID%>

<div class='box box-form box-primary form-horizontal'>
  
<div class='box-header with-border'><h4 class='box-title'>_{REFERENCE_WORKS}_</h4></div>

<div class='box-body'>
  <div class='form-group'>
    <label class='control-label col-md-3'>_{NAME}_</label>
    <div class='col-md-9'>
      <input type='text' class='form-control' name='NAME' value='%NAME%'>
    </div>
  </div>
  <div class='form-group'>
    <label class='control-label col-md-3'>_{SUM}_</label>
    <div class='col-md-9'>
      <input type='text' class='form-control' name='SUM' value='%SUM%'>
    </div>
  </div>
  <div class='form-group'>
    <label class='control-label col-md-3'>_{TIME}_</label>
    <div class='col-md-9'>
      <div class='input-group'>
      <input type='text' class='form-control' name='TIME' value='%TIME%'>
      <span class='input-group-addon'>_{HOURS}_</span>
      </div>
    </div>
  </div>
  <div class='form-group'>
    <label class='control-label col-md-3'>_{UNITS}_</label>
    <div class='col-md-9'>
      <input type='text' class='form-control' name='UNITS' value='%UNITS%'>
    </div>
  </div>
  <div class='checkbox text-center'>
        <label>
            <input type='checkbox' data-return='1' data-checked='%DISABLED%' name='DISABLED'   id='DISABLED_ID'  value='1'/>
            <strong>_{DISABLED}_</strong>
        </label>
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