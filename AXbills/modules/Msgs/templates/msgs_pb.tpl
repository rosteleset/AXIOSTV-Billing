<FORM action='$SELF_URL' METHOD='POST' class='form-horizontal'>
  <input type='hidden' name='index' value='$index'/>
  <input type='hidden' name='ID' value='$FORM{chg}'/>
  <input type='hidden' name='PROGRES_BAR' value='$FORM{PROGRES_BAR}'/>


  <div class='card card-primary card-outline card-form'>
    <div class='card-header'><h4 class='card-title'>_{PROGRES_BAR}_</h4></div>
    <div class='card-body form form-horizontal'>

      <div class='form-group row'>
        <label class='control-label col-md-3' for='STEP_NUM'>_{STEP}_ _{NUM}_:</label>
        <div class='col-md-9'>
          <input type='text' id='STEP_NUM' name='STEP_NUM' value='%STEP_NUM%' class='form-control'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-3' for='STEP_NAME'>_{STEP}_ _{NAME}_:</label>
        <div class='col-md-9'>
          <input type='text' id='STEP_NAME' name='STEP_NAME' value='%STEP_NAME%' class='form-control'>
        </div>
      </div>


      <div class='form-group row'>
        <label class='control-label col-md-3' for='STEP_TIP'>_{TIPS}_:</label>
        <div class='col-md-9'>
          <textarea id='STEP_TIP' name='STEP_TIP' rows='6' cols='45' class='form-control'>%STEP_TIP%</textarea>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-3 col-form-label text-md-right' for='USER_NOTICE'>_{USER_NOTICE}_:</label>
        <div class='col-md-9'>
          <div class='form-check'>
            <input type='checkbox' class='form-check-input' id='USER_NOTICE' name='USER_NOTICE' %USER_NOTICE% value='1'>
          </div>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-3 col-form-label text-md-right' for='RESPONSIBLE_NOTICE'>_{RESPONSIBLE_NOTICE}_:</label>
        <div class='col-md-9'>
          <div class='form-check'>
            <input type='checkbox' class='form-check-input' id='RESPONSIBLE_NOTICE' name='RESPONSIBLE_NOTICE' %RESPONSIBLE_NOTICE% value='1'>
          </div>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-3 col-form-label text-md-right' for='FOLLOWER_NOTICE'>_{FOLLOWER_NOTICE}_:</label>
        <div class='col-md-9'>
          <div class='form-check'>
            <input type='checkbox' class='form-check-input' id='FOLLOWER_NOTICE' name='FOLLOWER_NOTICE' %FOLLOWER_NOTICE% value='1'>
          </div>
        </div>
      </div>

    </div>
    <div class='card-footer'>
      <input type=submit name='%ACTION%' value='%LNG_ACTION%' class='btn btn-primary'>
    </div>
  </div>

</form>
