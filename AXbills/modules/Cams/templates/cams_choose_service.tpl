<form method='POST' action='$SELF_URL' class='form-horizontal'>
  <input type='hidden' name='index' value='%index%'/>
  <input type='hidden' name='UID' value='%UID%'/>
  <input type='hidden' name='sid' value='%sid%'/>
  <div class='card card-primary card-outline box-form'>
    <div class='card-header with-border'><h4 class='card-title'>_{TARIF_PLANS}_</h4></div>
    <div class='card-body'>
      <div class='form-group'>
        <div class='col-md-12'>
          %TARIFF_SELECT%
        </div>
      </div>
    </div>
    <div class='card-footer'>
      <input type='submit' class='btn btn-primary' name='show_cameras' value='_{SHOW}_'>
    </div>
  </div>
</form>
