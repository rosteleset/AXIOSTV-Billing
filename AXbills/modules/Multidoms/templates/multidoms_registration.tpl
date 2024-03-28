<FORM action='%SELF_URL%' METHOD='POST' ID='REGISTRATION'>
  <input type='hidden' name='index' value='%index%'>
  <input type='hidden' name='module' value='Multidoms'>

  <div class='card'>
    <div class='card-header with-border'>
      <h4 class='card-title'>_{REGISTRATION}_</h4>
    </div>
    <div class='card-body'>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right required' for='FIO'>_{FIO}_:</label>
        <div class='col-md-8'>
          <input id='FIO' name='FIO' value='%FIO%' required='required' placeholder='_{FIO}_'
                 class='form-control' type='text'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right required' for='PHONE'>_{PHONE}_:</label>
        <div class='col-md-8'>
          <input id='PHONE' name='PHONE' value='%PHONE%' required='required' placeholder='_{PHONE}_'
                 class='form-control' type='text'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right required' for='EMAIL'>E-mail:</label>
        <div class='col-md-8'>
          <input id='EMAIL' name='EMAIL' value='%EMAIL%' placeholder='E-mail' class='form-control'
                 type='text' required='required'>
        </div>
      </div>

      <hr/>

      <div class='form-group text-center'>
        <label class='control-element col-md-12 ' for='RULES'>_{RULES}_</label>
        <div class='col-md-12'>
          <textarea id='RULES' cols='60' rows='8' class='form-control' readonly> %_RULES_% </textarea>
        </div>
      </div>

      <div class='form-group text-center'>
        <div class='custom-control custom-checkbox'>
          <input class='custom-control-input' type='checkbox' id='ACCEPT_RULES' required name='ACCEPT_RULES' value='1'>
          <label for='ACCEPT_RULES' class='custom-control-label'>_{ACCEPT}_</label>
        </div>
      </div>

      %CAPTCHA%

    </div>
    <div class='card-footer'>
      <input type='submit' name='reg' value='_{SEND}_' class='btn btn-primary'>
    </div>

  </div>

</FORM>
