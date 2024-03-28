<form method='POST' class='form-horizontal' name='CRM_LEADS' id='CRM_LEADS' enctype='multipart/form-data'>
  <input type='hidden' name='index' value='%INDEX%'>
  <input type='hidden' name='send' value='1'>

  <div class='card card-primary card-outline card-form'>
    <div class='card-header with-border'>
      <h4 class='card-title'>_{DELIVERY}_:</h4>
    </div>
    <div class='card-body'>
      <div class='form-group row'>
        <label class='col-form-label text-md-right col-md-4' for='SUBJECT'>_{SUBJECT}_:</label>
        <div class='col-md-8'>
          <div class='input-group'>
            <input type='text' class='form-control' placeholder='_{SUBJECT}_' name='SUBJECT' id='SUBJECT'
                   value='%SUBJECT%'/>
          </div>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-form-label text-md-right col-md-4'>_{TYPE}_:</label>
        <div class='col-md-8'>
          <div class='input-group'>
            %TYPE_SEND%
          </div>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-form-label text-md-right col-md-4' for='MSGS'>_{MESSAGE}_:</label>
        <div class='col-md-8'>
          <div class='input-group'>
            <textarea name='MSGS' id='MSGS' rows='6' cols='45;' class='form-control'>%MSGS%</textarea>
          </div>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-form-label text-md-right col-md-4'>_{ATTACHMENT}_:</label>
        <div class='col-md-8'>
          <div class='input-group'>
            <div id='file_upload_holder' class='border rounded w-100'>
              <div class='form-group  m-1'>
                <input name='FILE_UPLOAD' type='file' data-number='0' class='fixed'>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class='card-footer'>
        <input type='submit' name='show' value='_{SEND}_' class='btn btn-primary'>
      </div>

    </div>
  </div>
  %TABLE%
</form>

<script>
  var MAX_FILES_COUNT = 3;
  initMultifileUploadZone('file_upload_holder', 'FILE_UPLOAD', MAX_FILES_COUNT);
</script>
<script src='/styles/default/js/draganddropfile.js'></script>