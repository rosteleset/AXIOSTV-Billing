<div class='card card-primary card-outline box-form'>
  <div class='card-body'>

<fieldset>

<div class='form-group'>
  <label class='control-label col-md-3' for='ID'>ID</label>
  <div class='col-md-9'>
    <input id='ID' name='ID' value='%ID%' placeholder='%ID%' class='form-control' type='text'>
  </div>
</div>

<div class='form-group'>
  <label class='control-label col-md-3' for='STATUS'>_{STATUS}_</label>
  <div class='col-md-9'>
   %STATUS_SEL%
  </div>
</div>

<div class='form-group'>
  <label class='control-label col-md-3' for='TP_ID'>_{TARIF_PLAN}_</label>
  <div class='col-md-9'>
    %TP_SEL%
  </div>
</div>

<div class='form-group'>
  <label class='control-label col-md-3' for='EXT_ID'>EXT_ID</label>
  <div class='col-md-9'>
    <input id='EXT_ID' name='EXT_ID' value='%EXT_ID%' placeholder='%EXT_ID%' class='form-control' type='text'>
  </div>
</div>

<div class='form-group'>
  <label class='control-label col-md-3' for='PIN'>PIN</label>
  <div class='col-md-9'>
    <input id='PIN' name='PIN' value='%PIN%' placeholder='%PIN%' class='form-control' type='text'>
  </div>
</div>

<div class='form-group'>
  <label class='control-label col-md-3' for='EXPIRE'>_{EXPIRE}_</label>
  <div class='col-md-9 %EXPIRE_COLOR%'>
    <input id='EXPIRE' name='EXPIRE' value='%EXPIRE%' placeholder='%EXPIRE%' class='form-control datepicker' rel='tcal' type='text'>
  </div>
</div>

<div class='form-group'>
  <div class='col-sm-offset-2 col-sm-8'>
    <input type=submit name='%ACTION%' value='%ACTION_LNG%' class='btn btn-primary'>
  </div>
</div>

</fieldset>


</div>
</div>

