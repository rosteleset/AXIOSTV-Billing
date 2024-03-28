<form action='$SELF_URL' METHOD='post' class='form form-horizontal'>
  <input type='hidden' name='index' value='$index'/>
  <input type='hidden' name='ID' value='%GID%'/>

  <div class='card card-primary card-outline card-form'>
    <div class='card-header with-border'>
      <h4 class='card-title'>_{CHANGE}_</h4>
    </div>
    <div class='card-body'>
      <div class='form-group row'>
        <label class='control-label col-md-3'>GID:</label>
        <div class='col-md-9'>
          <input class='form-control' type='text' name='GID' value='%GID%'/>
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-3'>_{NAME}_:</label>
        <div class='col-md-9'>
          <input class='form-control' type='text' name='NAME' value='%NAME%'/>
        </div>
      </div>

      <div class='form-group custom-control custom-checkbox'>
        <input class='custom-control-input' type='checkbox' id='USER_CHG_TP' name='USER_CHG_TP'
               %USER_CHG_TP% value='1'>
        <label for='USER_CHG_TP' class='custom-control-label'>_{USER_CHG_TP}_</label>
      </div>
    </div>
    <div class='card-footer'>
      <input type='submit' name='%ACTION%' value='%LNG_ACTION%' class='btn btn-primary'/>
    </div>
  </div>
</form>