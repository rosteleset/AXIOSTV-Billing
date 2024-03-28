<form action='$SELF_URL' METHOD='post' class='form-horizontal'>
  <input type='hidden' name='index' value='$index'/>
  <input type='hidden' name='UID' value='%UID%'/>
  <input type='hidden' name='BILL_ID' value='%BILL_ID%'/>
  <input type='hidden' name='bill_correction' value='1'/>


  <div class='card card-primary card-outline card-form'>
    <div class='card-header with-border'>
      <h4 class='card-title'>_{BILL}_</h4>
      <div class='card-tools float-right'>
        <button type='button' class='btn btn-tool' data-card-widget='collapse'><i class='fa fa-minus'></i></button>
      </div>
    </div>
    <div class='card-body'>
      <div class='form-group row'>
        <label class='control-label col-md-3' for='BILL_ID'>ID:</label>
        <div class='col-md-9'>
          <div class='input-group'>
            <div class='input-group-prepend'>
              <div class='input-group-text'>
                <input type='checkbox' class='form-control-static' id='CHANGE_DEPOSIT_ID' name='CHANGE_DEPOSIT_ID'
                       data-input-enables='NEW_BILL_ID' value='1' data-input-disables='DEPOSIT'>
              </div>
            </div>
            <input id='NEW_BILL_ID' name='NEW_BILL_ID' value='%BILL_ID%' class='form-control' type='text' disabled>
          </div>
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-3' for='DEPOSIT'>_{DEPOSIT}_:</label>
        <div class='col-md-9'>
          <input id='DEPOSIT' name='DEPOSIT' value='%DEPOSIT%' class='form-control' type='number' step='0.01'>
        </div>
      </div>
    </div>
    <div class='card-footer'>
      <input type=submit class='btn btn-primary' name='%ACTION%' value='%LNG_ACTION%'>
    </div>
  </div>

</form>
