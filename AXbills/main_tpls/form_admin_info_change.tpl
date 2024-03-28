<form class='form-horizontal' action='%SELF_URL%' method='post' enctype='multipart/form-data' id='admin_info'>
  <input type='hidden' name='index' value='%index%'>
  <input type='hidden' name='aedit' value='1'>

  <div class='card card-primary card-outline card-form'>
    <div class='card-header with-border'>
      <h3 class='card-title'>_{ADMIN}_</h3>
      <div class='card-tools float-right'>
        %CLEAR_SETTINGS%
        %CHG_PSW%
        <button type='button' class='btn btn-tool' data-card-widget='collapse'>
          <i class='fa fa-minus'></i>
        </button>
      </div>
    </div>

    <div class='card-body'>
      <div class='form-group row'>
        <label class='control-label col-md-3' for='email'>E-mail:</label>
        <div class='col-md-9'>
          <input id='email' name='email' value='%EMAIL%' class='form-control' type='text'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-3' for='FIO'>_{FIO}_:</label>
        <div class='col-md-9'>
          <input id='FIO' name='name' value='%A_FIO%' class='form-control' type='text'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-3 control-label' for='UPLOAD_FILE'>_{AVATAR}_:</label>
        <div class='col-md-9'>
          <input type='file' name='UPLOAD_FILE' id='UPLOAD_FILE' value='%UPLOAD_FILE%'>
        </div>
      </div>

      <div class='form-group row'>
       %G2FA%
      </div>
    </div>

    <div class='card-footer'>
      <input type='submit' name='change' value='_{CHANGE}_' class='btn btn-primary'>
    </div>
  </div>
</form>
