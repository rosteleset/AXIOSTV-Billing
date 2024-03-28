<form name='UPLOAD_M3U' id='form_UPLOAD_M3U' method='post' class='form form-horizontal' enctype=multipart/form-data>

    <input type='hidden' name='index' value='$index' />
    <input type=hidden name='import' value='1'>
    <input type=hidden name='import_message' value='1'>

<div class='card card-primary card-outline box-form'>
<div class='card-header with-border text-center'> <h4>%PANEL_HEADING% m3u</h4> </div>
<div class='card-body'>

  <div class='form-group'>
    <label class='col-md-3 control-label'> _{OPTIONS}_ </label>
    <div class='col-md-9'> %VARIANTS% </div>
  </div>

  <div class='form-group'>
    <label class='col-md-3 control-label'> _{FILE}_ </label>
    <div class='col-md-9'> <input type='file' name='FILE' class='form-control'> </div>
  </div>


</div>
<div class='card-footer'>
  <button type='submit' class='btn btn-primary'>%SUBMIT_BTN_NAME%</button>
</div>
</div>

</form>