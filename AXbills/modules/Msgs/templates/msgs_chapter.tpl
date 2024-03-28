<FORM action='$SELF_URL' METHOD='POST' enctype='multipart/form-data'>
  <input type='hidden' name='index' value='$index'/>
  <input type='hidden' name='ID' value='%ID%'/>

  <div class='card card-outline card-form card-primary'>
    <div class='card-header with-border'>
      <h4 class='card-title'>_{CHAPTER}_</h4>
    </div>
    <div class='card-body'>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='NAME'>_{NAME}_:</label>
        <div class='col-md-8'>
          <input class='form-control' type='text' name='NAME' id='NAME' value='%NAME%'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right'>_{RESPOSIBLE}_:</label>
        <div class='col-md-8'>
          %RESPONSIBLE_SEL%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='COLOR'>_{COLOR}_:</label>
        <div class='col-md-8'>
          <input type='color' class='form-control' name='COLOR' id='COLOR' value='%COLOR%'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='UPLOAD_FILE'>_{ICON}_:</label>
        <div class='col-md-8'>
          <div id='file_upload_holder'>
            <div class='form-group  m-1'>
              <input type='file' name='UPLOAD_FILE' id='UPLOAD_FILE' value='%UPLOAD_FILE%'>
            </div>
          </div>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='AUTOCLOSE'>_{AUTO_CLOSE}_:</label>
        <div class='col-md-8'>
          <input class='form-control' type='text' name='AUTOCLOSE' id='AUTOCLOSE' value='%AUTOCLOSE%' maxlength='20'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='INNER_CHAPTER'>_{INNER_M}_ _{CHAPTER}_:</label>
        <div class='col-md-8'>
          <div class='form-check'>
            <input type='checkbox' class='form-check-input' id='INNER_CHAPTER' name='INNER_CHAPTER' value='1'
                   %INNER_CHAPTER%>
          </div>
        </div>
      </div>
    </div>
    <div class='card-footer'>
      <input class='btn btn-primary' type=submit name='%ACTION%' value='%LNG_ACTION%'>
    </div>
  </div>
</form>
