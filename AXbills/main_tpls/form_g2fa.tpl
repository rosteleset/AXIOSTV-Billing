<style>
  .st_icon {
    color: #3c8dbc;
    font-size: 1.2em;
  }
  .input-group {
    margin-bottom: 15px;
  }
  select.normal-width {
    max-width: 100%!important;
  }
  div.fixed {
    position: fixed;
    width: 50%;
    bottom: 10px;
    font-size: 1.5em;
    margin-left: 50px;
  }

  div.wrapper {
    box-shadow: none !important;
    background-color: transparent !important;
  }
  @media screen and (max-width: 768px) {
    div.fixed {
      margin-left: 20px;
    }
  }
</style>
<div class='login-box'>
  <div class='row'>
    <div class='col-md-6 col-md-offset-3'>
      %ERROR_MSG%
    </div>
  </div>
  <div class='login-box-body'>
    <p class='login-box-msg' style='font-size: large; text-transform: uppercase'>_{ONE_TIME_CODE}_</p>

    <form action='$SELF_URL' METHOD='post' name='form_g2fa' id='form_g2fa'>
      <input type='hidden' id='AUTH_G2FA' name='AUTH_G2FA' value='1'>
      <input type='hidden' name='sid' value='$FORM{sid}'>
      <input type='hidden' name='passwd' value='$FORM{passwd}'>
      <input type='hidden' name='user' value='$FORM{user}'>

      <div class="input-group">
        <span class="input-group-addon st_icon"><i class="fa fa-lock"></i></span>
        <input type='password' id='G2FA' name='G2FA' class='form-control' placeholder='_{CODE}_' autocomplete='off'>
      </div>

      <div class='form-group'>
        <button type='submit' name='logined' class='btn btn-primary btn-block btn-flat' onclick='set_referrer()'>
          _{ENTER}_
        </button>
      </div>

    </form>

  </div>
</div>

<!-- Logo -->
<div class="fixed" >
  <div style="position: absolute; bottom: 5px;">
    <img src='$conf{FULL_LOGO}' class='brand-text font-weight-light'>
  </div>
</div>

<script>
  try {
    var BACKGROUND_OPTIONS     = '%BACKGROUND_COLOR%' || false;
    var BACKGROUND_URL         = '%BACKGROUND_URL%' || false;
    var BACKGROUND_HOLIDAY_IMG = '%BACKGROUND_HOLIDAY_IMG%' || false;

    if (BACKGROUND_HOLIDAY_IMG) {
      var block = '<style>'
          + 'body {'
          + 'background-size : cover !important; \n'
          + 'background : url(' + BACKGROUND_HOLIDAY_IMG + ') no-repeat fixed !important; \n'
          + '}'
          + '</style>';
      jQuery('head').append(block);
    }
    else if (BACKGROUND_URL) {
      jQuery('body').css({
        'background': 'url(' + BACKGROUND_URL + ')'
      });
    }
    else if (BACKGROUND_OPTIONS) {
      jQuery('body').css({
        'background': BACKGROUND_OPTIONS
      });
    }

  } catch (Error) {
    console.log('Somebody pasted wrong parameters for \$conf{user_background} or \$conf{user_background_url}');
  }
</script>