<style>
  .input-group {
    margin-bottom: 15px;
  }
</style>

<link rel='stylesheet' type='text/css' href='/styles/default/css/social_button.css'>

<div class='login-box card card-outline card-primary' style='margin: 7% auto;'>
  <div class='mb-0 login-logo card-header text-center'>
    <img src='$conf{FULL_LOGO}' class='brand-text font-weight-light'>
  </div>
  <div class='card-body'>
    <p class='login-box-msg h5 text-muted'>_{ENTER_PIN}_</p>
    <div class='col-xs-12'>
      %ERROR_MESSAGE%
    </div>

    <div id='MAIN_CONTAINER'>
      <form action='$SELF_URL' METHOD='post' name='form_registration' id='form_registration'>
        <input type='hidden' name='PIN_FORM' value='1'>
        <input type='hidden' name='EMAIL' value='%EMAIL%'>
        <input type='hidden' name='PHONE' value='%PHONE%'>

        <div class='row p-0 m-0'>
          <div class='input-group'>
            <input required id='PIN' name='PIN' class='form-control'
                   placeholder='PIN' autocomplete='off'>
            <div class='input-group-append'>
              <div class='input-group-text'>
                <span class='input-group-addon fas fa-key'></span>
              </div>
            </div>
          </div>
        </div>

        <div class='row p-0 m-0'>
          <button style='font-size: 1.1rem !important;' type='submit' name='REGISTRATION' value='1'
                  class='btn rounded btn-primary btn-block'
                  onclick='set_referrer()'
          >
            _{REGISTRATION}_
          </button>
        </div>
      </form>

      <a href='/'>_{AUTH}_</a>

    </div>
  </div>
</div>
