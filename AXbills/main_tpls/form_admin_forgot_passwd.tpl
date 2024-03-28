<div class='row justify-content-center'>
  <div class='col-md-3 col-lg-2'>
    <form action='$SELF_URL' method='post' name='reg_request_form' class='form form-horizontal'>
      <input type='hidden' name='forgot_passwd' value='1'>
      <br>
      <div class='card card-primary card-outline center-block'>
        <div class='card-header with-border text-right'><h4 class='card-title'>_{PASSWORD_RECOVERY}_</h4></div>
        <div class='card-body'>
          <div class='form-group'>
            <label for='EMAIL'>E-mail</label>
            <input type='text' class='form-control' id='EMAIL' name='email'/>
          </div>
          %CAPTCHA%
        </div>
        <div class='card-footer'>
          <input type='submit' class='btn btn-primary btn-block' name='SEND' value='_{SEND}_'/>
        </div>
      </div>
    </form>
  </div>
</div>