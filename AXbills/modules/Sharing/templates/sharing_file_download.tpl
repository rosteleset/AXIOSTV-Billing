<form method='POST'>

<input type='hidden' name='DOWNLOAD' value='%FILE_ID%'>
<input type='hidden' name='qindex'   value='%QINDEX%'>
<input type='hidden' name='hash'   value='%HASH%'>
<input type='hidden' name='TIMESTAMP' value='%TIMESTAMP%'>
<input type='hidden' name='link_time' value='%LINK_TIME%'>

<div class='card card-primary card-outline'>
<div class='card-header with-border text-center'>_{DOWNLOAD}_ _{FILE}_</div>
<div class='card-body'>


  <label class='col-md-3'>URL</label>
  <div class='col-md-9'>
    <input type='text' class='form-control' name='URL' value='%URL%'>
  </div>


</div>
<div class='card-footer'>
  <input type='submit' name='DOWNLOAD_FILE' value='_{DOWNLOAD}_' class='btn btn-primary'>
</div>
</div>

</form>
