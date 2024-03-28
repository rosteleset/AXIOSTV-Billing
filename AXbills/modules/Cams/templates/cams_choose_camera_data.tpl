<form method='POST' action='$SELF_URL' class='form-horizontal'>
  <input type='hidden' name='index' value='%index%'/>
  <input type='hidden' name='UID' value='%UID%'/>
  <input type='hidden' name='sid' value='%sid%'/>
  <div class='card card-primary card-outline'>
    <div class='card-header with-border'><h4 class='card-title'>_{CAMS_ARCHIVE}_</h4></div>
    <div class='card-body'>
      <div class='form-group row'>
        <label class='col-md-2 text-md-right'>_{CAM}_:</label>
        <div class='col-md-4'>
          %CAMS_SELECT%
        </div>
        <label class='col-md-2 text-md-right'>_{DATE}_:</label>
        <div class='col-md-4'>
          %DATE_SELECT%
        </div>
      </div>
    </div>
    <div class='card-footer'>
      <input type='submit' class='btn btn-primary' name='show_cameras' value='_{SHOW}_'>
    </div>
  </div>
</form>
