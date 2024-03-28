<script src='/styles/default/js/modules/config/password_generator.js'></script>


<form action='$SELF_URL' METHOD='POST'>
  <input type='hidden' name='index' value='$index'>
  %HIDDDEN_INPUT%
  <div class='card card-outline card-primary'>
    <div class='card-header with-border'><h4 class='card-title'>_{PASSWD}_: %ID%</h4></div>
    <div class='card-body'>

      %EXTRA_ROW%

<div class='form-group row'>
    <label class='control-label col-sm-4 col-md-4' for='FIRST_PASSWORD_INPUT'>_{NEW}_ _{PASSWD}_</label>
    <div class='col-sm-4 col-md-4'>
        <input type='password' class='form-control password-input' id='FIRST_PASSWORD_INPUT' name='newpassword' value='%newpassword%' autocomplete='new-password' title='_{PASSWD}_'/>
    </div>
</div>

<div class='form-group row'>
    <label class='control-label col-sm-4 col-md-4' for='SECOND_PASSWORD_INPUT'>_{CONFIRM_PASSWD}_</label>
    <div class='col-sm-4 col-md-4'>
        <input type='password' class='form-control password-input' name='confirm' value='%confirm%' id='SECOND_PASSWORD_INPUT' title='_{CONFIRM}_'/>
    </div>
</div>

<div class='form-group row'>
    <div class='col-sm-4 col-md-4'></div>
    <div class='col-sm-4 col-md-4'>
        <button class='btn btn-outline-secondary passwd-toggle-btn' type='button'>
            <i class='fa fa-eye-slash'></i>
        </button>
    </div>
</div>

      <div class='form-group row'>
        <div class='control-label col-6'>
          <input type='button' id='GENERATE_BTN' class='btn btn-info btn-xs' value='_{GENERED_PARRWORD}_'>
          <input type='button' id='COPY_BTN' class='btn btn-info btn-xs' value='_{COPY}_'>
        </div>

        <div class='col-6'>
          <input type='text' class='form-control' name='generated_pw' id='GENERATED_PW' autocomplete='off'/>
        </div>
      </div>

      <div class='form-group row' data-visible='%RESET_INPUT_VISIBLE%' style='display:none;'>
        <label class='control-label col-md-5'>_{RESET}_</label>
        <div class='col-md-7'>
          <input type='checkbox' name='RESET' class='control-element' style='margin-top: 7px;'/>
        </div>
      </div>
    </div>
    <div class='card-footer %BTN_HIDDEN%'>
      <input type=submit name='%ACTION%' value='%LNG_ACTION%' class='btn btn-primary'>
    </div>
  </div>
</form>

%G2FA_MESSAGE%

<div class='%G2FA_HIDDEN%'>
  <form action='$SELF_URL' METHOD='POST'>
    <input type='hidden' name='index' value='$index'>
    <input type='hidden' name='g2fa_secret' value='%G2FA_SECRET%'>
    <input type='hidden' name='g2fa_remove' value='%G2FA_REMOVE%'>
    %HIDDDEN_INPUT%

    <div class='card card-outline card-primary'>
      <div class='card-header with-border'><h4 class='card-title'>_{G2FA}_:</h4></div>
      <div class='card-body'>

        <div class='col-md-12 text-center mb-4'>
          %G2FA_QR%
        </div>

        <div class='form-group row %G2FA_STYLE%'>
          <div class='col-md-4 offset-3 %G2FA_INPUT_HIDDEN%'>
            <input type='password' class='form-control' id='G2FA' name='g2fa' autocomplete='new-password' placeholder='_{CODE}_' />
          </div>
          <button name='%G2FA_ACTION%' value='%G2FA_BUTTON%' class='col-md-2 btn btn-primary'>%G2FA_BUTTON%</button>
        </div>

      </div>
    </div>
  </form>
</div>

<script>
  var password_configuration_string = '%CONFIG_PASSWORD%';

  var password_config_params = {
    LENGTH: '%PW_LENGTH%',
    SYMBOLS: '%PW_CHARS%' || '1234567890abcdefgjhiklmnopqrstyquvwxyz'
  };

  if (password_configuration_string !== ''){
    var password_params_arr           = password_configuration_string.split(':') || [];

    if (password_params_arr.length === 3){
      password_config_params.CASE = password_params_arr[1] || 0;
      password_config_params.CHARS = password_params_arr[2] || 0;
    }
    else {
      password_config_params.CASE = password_params_arr[0] || 0;
      password_config_params.CHARS = password_params_arr[1] || 0;
    }

    password_config_params.LENGTH = '%PW_LENGTH%';
    delete password_config_params['SYMBOLS'];
  }

  var gen_btn = jQuery('#GENERATE_BTN');
  var gen_psw = jQuery('#GENERATED_PW');
  var cp_btn  = jQuery('#COPY_BTN');

  var passw_field1 = jQuery('#FIRST_PASSWORD_INPUT');
  var passw_field2 = jQuery('#SECOND_PASSWORD_INPUT');

  gen_btn.on('click', function () {
    var password = generatePassword(password_config_params);

    gen_psw.val(password);
  });

  cp_btn.on('click', function () {
    var generated_passw = gen_psw.val();
    passw_field1.val(generated_passw);
    passw_field2.val(generated_passw);
  });
  
</script>
<!-- <script type='text/javascript'>

  const togglePassword = document.querySelector('#togglePasswd');
  const password = document.querySelector('.PASSWORD_INPUT');

  togglePassword.addEventListener('click', function () {
    // toggle the type attribute
    const type = password.getAttribute('type') === 'password' ? 'text' : 'password';
    password.setAttribute('type', type);
    // toggle the eye icon
    this.children[0].classList.toggle('fa-eye');
    this.children[0].classList.toggle('fa-eye-slash');
  });
</script> -->

<script>
    document.addEventListener('DOMContentLoaded', function() {
        var toggleButton = document.querySelector('.passwd-toggle-btn');
        var passwordInputs = document.querySelectorAll('.password-input');
        
        toggleButton.addEventListener('click', function() {
            passwordInputs.forEach(function(input) {
                if(input.type === 'password') {
                    input.type = 'text';
                } else {
                    input.type = 'password';
                }
            });
        });
    });
</script>



<link rel='stylesheet' href='/styles/default/css/client_social_icons.css'>
<div class='row col-md-offset-2'>
  <ul class='social-network social-circle'>
    %SOCIAL_AUTH_BLOCK%
  </ul>
</div>

%EXTRA_FORM%
