<form class='form-horizontal' action='$SELF_URL' method='post' ENCTYPE='multipart/form-data'>
  <input type=hidden name='index' value='$index'>
  <input type=hidden name='ID' value='$FORM{chg}'>

  <div class='card card-primary card-outline card-form'>
    <div class='card-header with-border'>
      <h4 class='card-title'>_{SUBSCRIBES}_</h4>
    </div>
    <div class='card-body'>
      %ID_FIELD%

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='COUNT'>_{COUNT}_:</label>
        <div class='col-md-8'>
          <input id='COUNT' name='COUNT' value='%COUNT%' placeholder='%COUNT%' class='form-control' type='text'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='STATUS'>_{STATUS}_:</label>
        <div class='col-md-8'>
          %STATUS_SEL%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='TP_ID'>_{TARIF_PLAN}_:</label>
        <div class='col-md-8'>
          %TP_SEL%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='EXT_ID'>EXT_ID:</label>
        <div class='col-md-8'>
          <input id='EXT_ID' name='EXT_ID' value='%EXT_ID%' placeholder='%EXT_ID%' class='form-control' type='text'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='PIN'>PIN:</label>
        <div class='col-md-8'>
          <input id='PIN' name='PIN' value='%PIN%' placeholder='%PIN%' class='form-control' type='text'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='IMPORT'>_{IMPORT}_:</label>
        <div class='col-md-8'>
          <input type='file' name='IMPORT' id='IMPORT' class='control-element' value='%IMPORT%'/>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='EXPIRE'>_{EXPIRE}_:</label>
        <div class='col-md-8 %EXPIRE_COLOR%'>
          <input id='EXPIRE' name='EXPIRE' value='%EXPIRE%' placeholder='%EXPIRE%' class='form-control datepicker'
                 rel='tcal' type='text'>
        </div>
      </div>

    </div>
    <div class='card-footer'>
      <input type=submit name='%ACTION%' value='%ACTION_LNG%' class='btn btn-primary'>
    </div>
  </div>

</form>