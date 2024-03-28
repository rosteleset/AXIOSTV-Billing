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
    <p class='login-box-msg h5 text-muted'>_{PASSWORD_RECOVERY}_</p>
    <div class='col-xs-12'>
      %ERROR_MESSAGE%
    </div>

    <div id='MAIN_CONTAINER'>
      <form action='$SELF_URL' METHOD='post' name='form_forgot_password' id='form_forgot_password'>
        <input type='hidden' name='FORGOT_PASSWD' value='1'>

        <div %UID_HIDDEN% class='row p-0 m-0'>
          <div class='input-group'>
            <input %UID_REQUIRED% type='number' id='UID' name='UID' value='%UID%' class='form-control' placeholder='_{USER}_ ID'
                   autocomplete='off'>
            <div class='input-group-append'>
              <div class='input-group-text'>
                <span class='input-group-addon fa fa-user'></span>
              </div>
            </div>
          </div>
        </div>

        <div %LOGIN_HIDDEN% class='row p-0 m-0'>
          <div class='input-group'>
            <input %LOGIN_REQUIRED% type='text' id='LOGIN' name='LOGIN' value='%LOGIN%' class='form-control' placeholder='_{LOGIN}_'
                   autocomplete='off' data-check-for-pattern='%LOGIN_PATTERN%' maxlength='%LOGIN_MAX_LENGTH%'>
            <div class='input-group-append'>
              <div class='input-group-text'>
                <span class='input-group-addon fa fa-user'></span>
              </div>
            </div>
          </div>
        </div>

        <div %CONTRACT_ID_HIDDEN% class='row p-0 m-0'>
          <div class='input-group'>
            <input %CONTRACT_ID_REQUIRED% type='text' id='CONTRACT_ID' name='CONTRACT_ID' value='%CONTRACT_ID%' class='form-control' placeholder='_{CONTRACT_ID}_'
                   autocomplete='off'>
            <div class='input-group-append'>
              <div class='input-group-text'>
                <span class='input-group-addon fa fa-file'></span>
              </div>
            </div>
          </div>
        </div>

        <div %EMAIL_HIDDEN% class='row p-0 m-0'>
          <div class='input-group'>
            <input %EMAIL_REQUIRED% type='email' id='EMAIL' name='EMAIL' value='%EMAIL%' class='form-control'
                   placeholder='E-mail' autocomplete='off'>
            <div class='input-group-append'>
              <div class='input-group-text'>
                <span class='input-group-addon fas fa-envelope'></span>
              </div>
            </div>
          </div>
        </div>

        <div %PHONE_HIDDEN% class='row p-0 m-0'>
          <div class='input-group'>
            <input id='PHONE_PATTERN_FIELD' name='PHONE_PATTERN_FIELD' value='%PHONE_PATTERN_FIELD%' %PHONE_REQUIRED%
                   placeholder='_{PHONE}_' class='form-control' data-phone-field='PHONE'
                   data-check-phone-pattern='%PHONE_NUMBER_PATTERN%' type='text' autocomplete='off'>
            <input id='PHONE' name='PHONE' value='' class='form-control' type='hidden'>

            <div class='input-group-append'>
              <div class='input-group-text'>
                <span class='input-group-addon fas fa-phone'></span>
              </div>
            </div>
          </div>
        </div>

        %EXTRA_PARAMS%

        <div class='row p-0 m-0'>
          <button style='font-size: 1.1rem !important;' type='submit' name='SEND_SMS' value='1'
                  class='btn rounded btn-primary btn-block g-recaptcha' %CAPTCHA_BTN%>
            _{SEND}_
          </button>
        </div>
      </form>

      <a href='/?login_page=1'>_{AUTH}_</a>
    </div>
  </div>
</div>

%CAPTCHA%
