<div class='card card-primary card-outline box-form'>
  <div class='card-header with-border'><h4 class='card-title'>_{CAMERAS}_ _{USER}_</h4></div>
  <div class='card-body'>

    <form name='CAMS_USER_ADD' id='form_CAMS_USER_ADD' method='post' class='form form-horizontal'>
      <input type='hidden' name='index' value='$index' />
      <input type='hidden' name='UID' value='%UID%' />
      <input type='hidden' name='ACTIVATION' value='%ACTIVATION%' />

      <div class='form-group'>
        <label class='control-label col-md-3 required' for='TP_ID'>_{TARIF_PLAN}_</label>
        <div class='col-md-9'>
          %TP_ID_SELECT%
        </div>
      </div>
    </form>

  </div>
  <div class='card-footer'>
    <input type='submit' form='form_CAMS_USER_ADD' class='btn btn-primary' name='action' value='%SUBMIT_BTN_NAME%'>
  </div>
</div>