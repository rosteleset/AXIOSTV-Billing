<form action='$SELF_URL' method='post' name='reg_request_form' class='form form-horizontal'>
  <input type='hidden' name='FORGOT_PASSWD' value='1'>

  <div class='card center-block container-md'>
    <div class='card-header with-border'>
      <h4 class='card-title'>_{PASSWORD_RECOVERY}_</h4>
    </div>
    <div class='card-body'>
      <div class='form-group row'>
        <label class='col-sm-4 col-md-4' for='LOGIN'>_{LOGIN}_:</label>
        <div class='col-sm-8 col-md-8'>
          <div class='input-group'>
            <input type='text' class='form-control' id='LOGIN' name='LOGIN' value='%LOGIN%'
                   data-input-disables='UID'/>
          </div>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-sm-4 col-md-4' for='UID'>_{CONTRACT}_№:</label>
        <div class='col-sm-8 col-md-8'>
          <div class='input-group'>
            <input type='text' class='form-control' id='UID' name='UID' value='%UID%'
                   data-input-disables='LOGIN'/>
          </div>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-sm-4 col-md-4' for='EMAIL'>E-mail:</label>
        <div class='col-sm-8 col-md-8'>
          <div class='input-group'>
            <input type='text' class='form-control' id='EMAIL' name='EMAIL' value='%EMAIL%'/>
          </div>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-sm-4 col-md-4' for='PHONE'>_{CELL_PHONE}_:</label>
        <div class='col-sm-8 col-md-8'>
          <div class='input-group'>
            <input type='text' class='form-control' id='PHONE' required='required' name='PHONE'
                   value='%PHONE%' data-input-disables='EMAIL'/>
          </div>
        </div>
      </div>

      %EXTRA_PARAMS%

      <hr/>

      %CAPTCHA%
    </div>
    <div class='card-footer'>
      <input type='submit' class='btn btn-primary' name='SEND' value='_{SEND}_'/>
    </div>
  </div>
</form>