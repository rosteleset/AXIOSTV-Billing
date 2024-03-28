<form  class='form-horizontal'>

<input type='hidden' name='index' value='$index'>
<input type='hidden' name='NAS_ID' value='$FORM{NAS_ID}'>
<input type='hidden' name='radtest' value='1'>

  <div class='card card-primary card-outline box-big-form'>
    <div class='card-header with-border'>
      <h4 class='card-title'>RADIUS _{REQUEST}_</h4>
    </div>
    <div class='card-body'>
      <div class='form-group'>
        <label class='col-md-12'>RAD_PAIRS</label>
        <div class='col-md-12'>
          <textarea class='form-control' name='RAD_REQUEST' cols='45' rows='10'>%RAD_PAIRS%</textarea>
      </div>
    </div>

    <div class="form-group">
      <div class="row">
        <div class="col-sm-12 col-md-6">
          <label class='col-md-12 control-element'>_{COMMENTS}_</label>
          <div class="input-group">
            <input type='text' class='form-control' name='COMMENTS' value=%COMMENTS%>
          </div>
        </div>

        <div class="col-sm-12 col-md-6">
          <label class='col-md-3 control-element'>_{TYPE}_ _{QUERY}_</label>
          <div class="input-group">
            %QUERY_TYPE%
          </div>
        </div>
      </div>
    </div>

    <div class="form-group">
      <div class="form-check">
        <input class="form-check-input" type='checkbox' name='SAVE'>
        <label class='form-check-label'>_{SAVE}_</label>
      </div>
    </div>
    <div class='card-footer'>
      <input type='submit' class='btn btn-primary' name='runtest' value='_{SHOW}_'>
    </div>
  </div>

</form>