<FORM action='$SELF_URL' METHOD='POST' enctype='multipart/form-data' name='add_message' id='add_message'
      class='form-horizontal'>
  <input type='hidden' name='index' value='$index'/>
  <input type='hidden' name='ID' value='$FORM{chg}'/>

  <div class='card card-primary card-outline card-form'>
    <div class='card-header with-border'>
      <h4 class='card-title'>_{TEMPLATES}_ (_{QUESTIONS}_)</h4>
    </div>
    <div class='card-body'>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='NAME'>_{NAME}_ (_{SUBJECT}_):</label>
        <div class='col-md-8'>
          <input type=text name=NAME value='%NAME%' id='NAME' class='form-control' required>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='FILE_UPLOAD_1'>_{ATTACHMENT}_ 1:</label>
        <div class='col-md-8'>
          <div id='file_upload_holder'>
            <div class='form-group  m-1'>
              <input name='FILE_UPLOAD_1' ID='FILE_UPLOAD_1' type='file' value='%FILE_UPLOAD%'
                     placeholder='%FILE_UPLOAD%'>
            </div>
          </div>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='STATUS'>_{STATUS}_:</label>
        <div class='col-md-8'>
          %STATUS_SEL%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='TPL'>_{TEXT}_:</label>
        <div class='col-md-8'>
          <textarea class='form-control' id='TPL' name='TPL' rows='6'>%TPL%</textarea>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='COMMENTS'>_{COMMENTS}_:</label>
        <div class='col-md-8'>
          <textarea class='form-control' cols='45' id='COMMENTS' name='COMMENTS' rows='6'>%COMMENTS%</textarea>
        </div>
      </div>
    </div>
    <div class='card-footer'>
      <input type=submit name='%ACTION%' value='%LNG_ACTION%' class='btn btn-primary'>
    </div>
  </div>
</form>
