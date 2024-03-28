<style>
  .input-group {
    margin-bottom: 15px;
  }
</style>

<div class='login-box card card-outline card-primary' style='margin: 7% auto;'>
  <div class='mb-0 login-logo card-header text-center'>
     <img src='$conf{FULL_LOGO}' class='brand-text font-weight-light'>
  </div>
  <div class='card-body'>
    <p class='login-box-msg h5 text-muted'>_{CHANGE_PASSWD}_</p>
    <div class='col-xs-12'>
      %ERROR_MESSAGE%
    </div>

    <div id='MAIN_CONTAINER'>
      <form action='$SELF_URL' METHOD='post' name='form_forgot_password_chg' id='form_forgot_password_chg'>
        <input type='hidden' name='CODE' value='%CODE%'/>
        <input type='hidden' name='FORGOT_PASSWD' value='1'>
        <div class='row p-0 m-0'>
          <div class='input-group'>
            <input type='password' id='newpassword' name='newpassword' class='form-control'
                   placeholder='_{PASSWD}_' autocomplete='off' data-check-for-pattern='%PASSWORD_PATTERN%' minlength='%PASSWORD_MIN_LENGTH%'>
            <div class='input-group-append'>
              <div class='input-group-text'>
                <span class='input-group-addon fas fa-lock'></span>
              </div>
            </div>
          </div>
        </div>

        <div class='row p-0 m-0'>
          <div class='input-group'>
            <input type='password' id='confirm' name='confirm' class='form-control'
                   placeholder='_{CONFIRM_PASSWD}_' autocomplete='off' data-check-for-pattern='%PASSWORD_PATTERN%' minlength='%PASSWORD_MIN_LENGTH%'>
            <div class='input-group-append'>
              <div class='input-group-text'>
                <span class='input-group-addon fas fa-lock'></span>
              </div>
            </div>
          </div>
        </div>

        <div class='row p-0 m-0'>
          <button
                  style='font-size: 1.1rem !important;'
                  type='submit'
                  name='CHANGE_PASSWORD'
                  value='1'
                  class='btn rounded btn-primary btn-block g-recaptcha'
          >
            _{CHANGE}_
          </button>
        </div>
      </form>
    </div>
  </div>
</div>
