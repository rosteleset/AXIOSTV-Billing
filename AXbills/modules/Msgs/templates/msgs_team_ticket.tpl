<form METHOD=POST name='RESPONSIBLE_BRIGADE' class='form-horizontal' >
  <input type='hidden' name='index' value='%INDEX%'>
  <input type='hidden' name='chg' value='%CHG_ELEMENT%'>

  <div class='card card-primary card-outline card-form'>
    <div class='card-header with-border'>
      <h4 class='card-title'>
        _{TICKET_BRIGADE}_
      </h4>
    </div>
    <div class='card-body'>
      <div class='form-group row'>
        <label class='control-label col-md-4 col-sm-3'>_{BRIGADE}_:</label>
        <div class='col-md-8 col-sm-9'>
          %TEAM%
        </div>
      </div>
      <div class='form-group row'>
        <label class='control-label col-md-4 col-sm-3'>_{TICKET}_:</label>
        <div class='col-md-8 col-sm-9'>
          %TICKET%
        </div>
      </div>
    </div>
    <div class='card-footer'>
      <input type='submit' class='btn btn-primary float-right' name='%PARAM%' value='%SAVE_CHG%'>
    </div>
  </div>
</form>