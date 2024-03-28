<form action='$SELF_URL'>
  <input type=hidden name=index value=$index>
  <input type=hidden name=ID value=$FORM{chg}>

  <div class='card card-primary card-outline card-form form-horizontal'>
    <div class='card-header with-border'>_{BONUS}_ Turbo</div>
    <div class='card-body'>
      <div class='form-group row'>
        <label class='control-label col-md-3'>_{SERVICE}_ _{PERIOD}_ (_{MONTH}_):</label>
        <div class='col-md-9'>
          <input class='form-control' type=text name='SERVICE_PERIOD' value='%SERVICE_PERIOD%'>
        </div>
      </div>
      <div class='form-group row'>
        <label class='control-label col-md-3'>_{REGISTRATION}_ (_{DAYS}_):</label>
        <div class='col-md-9'>
          <input class='form-control' type=text name='REGISTRATION_DAYS' value='%REGISTRATION_DAYS%'>
        </div>
      </div>
      <div class='form-group row'>
        <label class='control-label col-md-3'>_{TURBO}_ _{COUNT}_:</label>
        <div class='col-md-9'>
          <input class='form-control' type=text name='TURBO_COUNT' value='%TURBO_COUNT%'>
        </div>
      </div>
      <div class='form-group row'>
        <label class='control-label col-md-3' for='COMMENTS'>_{DESCRIBE}_</label>
        <div class='col-md-9'>
          <textarea class='form-control' ID='COMMENTS' name=COMMENTS rows=6 cols=45>%COMMENTS%</textarea>
        </div>
      </div>
    </div>
    <div class='card-footer'>
      <input class='btn btn-primary' type=submit name=%ACTION% value='%LNG_ACTION%'>
    </div>
  </div>

</form>
