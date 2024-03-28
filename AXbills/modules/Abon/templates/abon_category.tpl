<form action='$SELF_URL' method='POST' class='form-horizontal'>
  <input type='hidden' name='index' value='$index'>
  <input type='hidden' name='ID' value='%ID%'>

  <div class='card card-primary card-outline card-form'>
    <div class='card-header'>
      <h4 class='card-title'>_{ACTION}_</h4>
    </div>
    <div class='card-body'>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right required' for='NAME'>_{NAME}_:</label>
        <div class='col-md-8'>
          <input id='NAME' name='NAME' value='%NAME%' class='form-control' type='text' required>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='DSC'>_{DESCRIBE}_:</label>
        <div class='col-md-8'>
          <textarea name='DSC' id='DSC' class='form-control'>%DSC%</textarea>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='PUBLIC_DSC'>_{PUBLIC_DESCRIPTION}_:</label>
        <div class='col-md-8'>
          <textarea name='PUBLIC_DSC' id='PUBLIC_DSC' class='form-control'>%PUBLIC_DSC%</textarea>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='VISIBLE'>_{USER_PORTAL_YES}_:</label>
        <div class='col-md-8 p-2'>
          <div class='form-check'>
            <input type='checkbox' data-return='1' class='form-check-input' id='VISIBLE' name='VISIBLE' %VISIBLE%
                   value='1'>
          </div>
        </div>
      </div>

    </div>
    <div class='card-footer'>
      <input type='submit' class='btn btn-primary' name='%BTN_NAME%' value='%BTN_VALUE%'>
    </div>
  </div>

</form>