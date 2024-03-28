<div class='card card-primary card-outline'>
  <div class='card-header with-border'>
    <h5 class='card-title'>_{IMPORT}_</h5>
  </div>
  <div class='card-body' id='ajax_upload_modal_body'>

    <form class='form' name='ajax_upload_form' id='ajax_upload_form' method='post'>

      <input type='hidden' name='get_index' value='%CALLBACK_FUNC%'/>
      <input type='hidden' name='header' value='2'/>
      <input type='hidden' name='import' value='1'/>
      <input type='hidden' name='add' value='1'/>
      <input type='hidden' name='IMPORT_ADDRESS' value='%IMPORT_ADDRESS%'/>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right required' for='IMPORT_TYPE'> _{TYPE}_:</label>
        <div class='col-md-8'>
          <select id='IMPORT_TYPE' name='IMPORT_TYPE' class='form-control'>
            <option value='tab'>(TAB)
            <option value='csv'>CSV (,)
            <option value='JSON'>JSON
          </select>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='IMPORT_FIELDS'>
          _{FIELDS}_:</label>
        <div class='col-md-8'>
          <input type='text' name='IMPORT_FIELDS' id='IMPORT_FIELDS' value='%IMPORT_FIELDS%'
                 class='form-control'/>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right required' for='UPLOAD_FILE'>_{FILE}_:</label>
        <div class='col-md-8'>
          <input type='file' name='UPLOAD_FILE' id='UPLOAD_FILE' class='control-element' required/>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='UPLOAD_PRE'>_{PRE}_:</label>
        <div class='col-md-8'>
          <input type='checkbox' name='UPLOAD_PRE' id='UPLOAD_PRE' value=1 class='control-element'/>
        </div>
      </div>

      %EXTRA_ROWS%

    </form>
  </div>

  <div class='card-footer'>
    <button type='submit' class='btn btn-primary' id='ajax_upload_submit' form='ajax_upload_form'>_{ADD}_</button>
  </div>
</div>


<script src='/styles/default/js/ajax_upload.js'></script>
