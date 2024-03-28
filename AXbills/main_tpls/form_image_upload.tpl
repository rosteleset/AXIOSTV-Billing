<form class='form-horizontal' action='$SELF_URL' name='users_pi' METHOD='POST' ENCTYPE='multipart/form-data'>
<input type='hidden' name='index' value='$index'>
<input type=hidden name=UID value='%UID%'>
<input type=hidden name=PHOTO value='%UID%'>
<input type='hidden' name='EXTERNAL_ID' value='%EXTERNAL_ID%'>
<br>
<div class='card card-primary card-outline box-form'>
<div class='card-body'>

<fieldset>
<legend>_{IMAGES}_</legend>

<div class='form-group'>
  <label class='col-md-3 control-label' for='IMAGE'>_{FILE}_</label>
  <div class='col-md-9'>
    <input id='IMAGE' name='IMAGE' value='%IMAGE%' placeholder='%IMAGE%' type='file'>
  </div>
</div>


<div class='col-sm-offset-2 col-sm-8'>
<input type=submit class='btn btn-primary' name='add' value='_{ADD}_'>
</div>

</fieldset>
</div>
</div>

</form>

