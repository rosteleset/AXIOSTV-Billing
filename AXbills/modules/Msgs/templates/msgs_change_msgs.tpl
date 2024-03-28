<form action='$SELF_URL' class='form-horizontal'>
  <input type=hidden name=index value='$index'>
  <input type=hidden name=MSGS_STATUS value='%MSGS_STATUS%'>
  <input type=hidden name=MSGS_STATUS_ID value='%MSGS_STATUS_ID%'>

  <div class='card card-primary card-outline box-form'>
    <div class='card-header'><h4 class='card-title'>_{MESSAGE}_ #%MSGS_STATUS%</h4></div>
    <div class='card-body'>
      <div class='form-group row'>
        <label class='col-form-label text-md-right col-md-4' for='STATUS_SELECT'>_{STATUS}_:</label>
        <div class='col-md-8'>
          %STATUS_SELECT%
        </div>
      </div>
    </div>
  </div>


  <div class='card-footer'>
    <input type='submit' name='save_status' value='_{CHANGE}_' class='btn btn-primary'>
  </div>

</form>