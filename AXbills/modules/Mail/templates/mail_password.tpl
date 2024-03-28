<script src='/styles/default/js/modules/config/password_generator.js'></script>

<script>
  jQuery(function () {
    window['CONFIG_PASSWORD']       = '$conf{CONFIG_PASSWORD}';
    var password_configuration_string = window['CONFIG_PASSWORD'];

    var password_config_params = {
      LENGTH : '$conf{PASSWD_LENGTH}',
      SYMBOLS : '$conf{PASSWD_SYMBOLS}' || '1234567890abcdefgjhiklmnopqrstyquvwxyz'
    };

    if (password_configuration_string !== ''){
      var password_params_arr           = password_configuration_string.split(':') || [];

      password_config_params.LENGTH = password_params_arr[0] || '$conf{PASSWD_LENGTH}';

      delete password_config_params['SYMBOLS'];
      password_config_params.CASE = password_params_arr[1] || 0;
      password_config_params.CHARS = password_params_arr[2] || 0;
    }

    var gen_btn = jQuery('#GENERATE_BUTTON');
    var gen_psw = jQuery('#GENERATED_PSW');
    var cp_btn  = jQuery('#COPY_BUTTON');

    var passw_field1 = jQuery('#FIRST_PASSWORD_INPT');
    var passw_field2 = jQuery('#SECOND_PASSWORD_INPT');

    gen_btn.on('click', function () {
      var password = generatePassword(password_config_params);
      gen_psw.val(password);
    });

    cp_btn.on('click', function () {
      var generated_passw = gen_psw.val();
      passw_field1.val(generated_passw);
      passw_field2.val(generated_passw);
    });

  });
</script>

<div class='form-group row'>
  <label class='control-label col-md-4' for='FIRST_PASSWORD_INPT'>_{PASSWD}_</label>

  <div class='col-md-8'>
    <input type='password' class='form-control' id='FIRST_PASSWORD_INPT' name='newpassword' title='_{PASSWD}_' autocomplete='new-password'/>
  </div>
</div>

<div class='form-group row'>
  <label class='control-label col-md-4' for='SECOND_PASSWORD_INPT'>_{CONFIRM_PASSWD}_</label>

  <div class='col-md-8'>
    <input type='password' class='form-control' name='confirm' id='SECOND_PASSWORD_INPT' title='_{CONFIRM}_'/>
  </div>
</div>


<div class='form-group row'>
  <label class='control-label col-md-6' for='GENERATED_PSW'>
    <input type='button' id='GENERATE_BUTTON' class='btn btn-info btn-xs' value='_{GENERED_PARRWORD}_'>
    <input type='button' id='COPY_BUTTON' class='btn btn-info btn-xs' value='Copy'>

  </label>

  <div class='col-md-6'>
    <input type='text' class='form-control' name='generated_pw' id='GENERATED_PSW' autocomplete='off'/>
  </div>
</div>
