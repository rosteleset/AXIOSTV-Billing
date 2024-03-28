<form id='paysys-terminals-types-add' method='POST' enctype=multipart/form-data>

  <input type='hidden' name='index' value=%index%>
  <input type='hidden' name='ACTION' value='%ACTION%'>
  <input type='hidden' name='ID' value='%ID%'>

  <div class='card card-primary card-outline card-form'>
    <div class='card-header with-border'>
      <h4>_{TYPE}_</h4>
    </div>

    <div class='card-body'>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right'>_{NAME}_:</label>
        <div class='col-md-8'>
          <input type='text' class='form-control' name='NAME' value='%NAME%'>
        </div>
      </div>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right'>_{ICON}_:</label>
        <div class='col-md-8'><input type='file' name=UPLOAD_FILE></div>
      </div>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right'>_{COMMENTS}_:</label>
        <div class='col-md-8'>
          <textarea class='form-control' name='COMMENT'>%COMMENT%</textarea>
        </div>
      </div>
    </div>

    <div class='card-footer'>
      <button class='btn btn-primary' type='submit'>%BTN%</button>
    </div>

  </div>
</form>