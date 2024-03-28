<form action='$SELF_URL' METHOD=POST class='form-horizontal'>

  <input type='hidden' name='index' value=$index>
  <input type='hidden' name='ID' value=%ID%>

  <div class='card card-outline card-big-form container-md'>

    <div class='card-header with-border'><h4 class='card-title'>_{REFERENCE_WORKS}_</h4></div>

    <div class='card-body'>
      <div class='form-group row'>
        <label class='control-label col-md-3'>_{NAME}_:</label>
        <div class='col-md-9'>
          <input type='text' class='form-control' name='NAME' value='%NAME%'>
        </div>
      </div>
      <div class='form-group row'>
        <label class='control-label col-md-3'>_{SUM}_:</label>
        <div class='col-md-9'>
          <input type='text' class='form-control' name='SUM' value='%SUM%'>
        </div>
      </div>
      <div class='form-group row'>
        <label class='control-label col-md-3'>_{TIME}_:</label>
        <div class='col-md-9'>
          <div class='input-group'>
            <input type='text' class='form-control' name='TIME' value='%TIME%'>
            <div class='input-group-append'><span class='input-group-text'>_{HOURS}_</span></div>
          </div>
        </div>
      </div>
      <div class='form-group row'>
        <label class='control-label col-md-3'>_{UNITS_}_:</label>
        <div class='col-md-9'>
          <input type='text' class='form-control' name='UNITS' value='%UNITS%'>
        </div>
      </div>

      <div class='form-group custom-control custom-checkbox' style='text-align: center;'>
        <input class='custom-control-input' type='checkbox' id='DISABLED_ID' name='DISABLED'
               data-return='1' data-checked='%DISABLED%' value='1'>
        <label for='DISABLED_ID' class='custom-control-label'>_{DISABLED}_</label>
      </div>

      <div class='form-group row'>
        <label class='col-md-3 control-label'>_{COMMENTS}_:</label>
        <div class='col-md-9'>
          <textarea class='form-control' name='COMMENTS'>%COMMENTS%</textarea>
        </div>
      </div>
    </div>

    <div class='card-footer'>
      <input type='submit' class='btn btn-primary' value='%ACTION_LANG%' name='%ACTION%'>
    </div>

  </div>

</form>