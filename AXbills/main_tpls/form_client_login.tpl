<style>
  .st_icon {
    color: #3c8dbc;
    font-size: 1.2em;
  }

  .input-group {
    margin-bottom: 15px;
  }

  select.normal-width {
    max-width: 100% !important;
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

  .cookieAcceptBar {
    right: 0;
    text-align: center;
    background-color: #333;
    color: #fff;
    padding: 20px 0;
    z-index: 99999;
    position: fixed;
    width: 100%;
    height: 100px;
    bottom: 0;
    left: 0;
  }

  .cookieAcceptBar a {
    color: #fff;
    text-decoration: none;
    font-weight: bold;
  }

  button .cookieAcceptBarConfirm {
    cursor: pointer;
    border: none;
    background-color: #2387c0;
    color: #fff;
    text-transform: uppercase;
    margin-top: 10px;
    height: 40px;
    line-height: 40px;
    padding: 0 20px;
  }

  .passwd-toggle-icon {
    margin: -3px;
	  min-width: 18.25px;
  }
</style>

<link rel='stylesheet' type='text/css' href='/styles/default/css/social_button.css'>

<!-- Login Form -->
<div class='login-box card card-outline card-primary' style='margin: 7% auto 4%;'>
  <div class='mb-0 login-logo card-header text-center'>
	<img src='$conf{FULL_LOGO}' class='brand-text font-weight-light'>
  </div>
  <div class='card-body'>
    <p class='login-box-msg h5 text-muted'>%TITLE%</p>
    <div class='col-xs-12'>
      <div class='info-box bg-yellow' style='display: none;' id='tech_works_block'>
          <span class='info-box-icon'>
            <i class='fa fa-wrench'></i>
          </span>
        <div class='info-box-content'>
          <span class='info-box-number'>%TECH_WORKS_MESSAGE%</span>
        </div>
      </div>
    </div>
    <div class='col-xs-12'>
      %LOGIN_ERROR_MESSAGE%
    </div>

    <div id='MAIN_CONTAINER'>
      <form action='$SELF_URL' METHOD='post' name='form_login' id='form_login'>
        <input type='hidden' name='DOMAIN_ID' value='$FORM{DOMAIN_ID}'>
        <input type='hidden' ID='REFERER' name='REFERER' value='$FORM{REFERER}'>
        <input type='hidden' id='HIDDEN_COOKIE' name='HIDDEN_COOKIE' value='%COOKIE_POLICY_VISIBLE%'>
        <input type='hidden' id='location_x' name='coord_x'>
        <input type='hidden' id='location_y' name='coord_y'>

        <div class='form-group row ml-0 mr-0 has-feedback'>
          %SEL_LANGUAGE%
        </div>

        <div class='row p-0 m-0'>
          <div class='input-group'>
            <input type='text' id='user' name='user' value='%user%' class='form-control' placeholder='_{LOGIN}_'
                   autocomplete='off'>
          </div>
        </div>

        <div class='row p-0 m-0'>
          <div class='input-group'>
            <input type='password' id='passwd' name='passwd' value='%password%' class='form-control'
                   placeholder='_{PASSWD}_' autocomplete='off'>
            <div class='input-group-append'>
              <div id='togglePasswd' class='input-group-text cursor-pointer'>
                <span class='input-group-addon passwd-toggle-icon fa fa-eye-slash'></span>
              </div>
            </div>
          </div>
        </div>

        <div class='row p-0 m-0  %G2FA_hidden%'>
          <div class='input-group'>
            <input type='password' id='g2fa' name='g2fa' value='%g2fa%' class='form-control'
                   placeholder='_{CODE}_' autocomplete='off'>
          </div>
        </div>

        <div class='row p-0 m-0'>
          <button style='font-size: 1.1rem !important;' type='submit' name='logined'
                  class='btn rounded btn-primary btn-block' onclick='set_referrer()'>
            _{ENTER}_
          </button>
        </div>
      </form>

      <a data-visible='%PASSWORD_RECOVERY%' style='display: none; float: right' href='/registration.cgi?FORGOT_PASSWD=1'>_{FORGOT_PASSWORD}_</a>
      <a data-visible='%REGISTRATION_ENABLED%' style='display: none;' href='/registration.cgi'>_{REGISTRATION}_</a>
      <br/>

      <div class='row row p-0 m-0'>
        <div class='col-md-12'>
          <a class='btn %AUTH_BY_PHONE% phone' id='LOGIN_BY_PHONE'>
            <i class='fa fa-phone fa-fw'></i> _{LOGIN_BY_PHONE_NUMBER}_
          </a>
          <a href='%GOOGLE%' class='google btn' style='%AUTH_GOOGLE_ID%;'>
            <img src='/styles/default/img/social/google.png' alt='google'> _{SIGN_IN_WITH}_ Google
          </a>
          <a href='%FACEBOOK%' class='fb btn' style='%AUTH_FACEBOOK_ID%;'>
            <i class='fab fa-facebook fa-fw'></i> _{SIGN_IN_WITH}_ Facebook
          </a>
          <a href='%APPLE%' class='apple btn' style='%AUTH_APPLE_ID%;'>
            <i class='fab fa-apple fa-fw'></i> _{SIGN_IN_WITH}_ Apple
          </a>
          <a href='%TWITTER%' class='twitter btn' style='%AUTH_TWITTER_ID%;'>
            <i class='fab fa-twitter fa-fw'></i> _{SIGN_IN_WITH}_ Twitter
          </a>
          <a href='%VK%' class='vk btn' style='%AUTH_VK_ID%'>
            <i class='fab fa-vk fa-fw'></i> _{SIGN_IN_WITH}_ VK
          </a>
          <a href='%INSTAGRAM%' class='instagram btn' style='%AUTH_INSTAGRAM_ID%'>
            <i class='fab fa-instagram fa-fw'></i> _{SIGN_IN_WITH}_ Instagram
          </a>

          <a href='%TELEGRAM%' class='telegram btn' style='%AUTH_TELEGRAM_ID%'>
            <i class='fab fa-telegram fa-fw'></i> _{SIGN_IN_WITH}_ Telegram
          </a>

          %TELEGRAM_SCRIPT%

        </div>
      </div>
    </div>

    %LOGIN_BY_PHONE%
  </div>
</div>

<div class='login-box row flex-nowrap' style='margin: 0 auto 4%; gap: 10px;'>
  %APP_LINK_GOOGLE_PLAY%
  %APP_LINK_APP_STORE%
</div>

<!-- Accept cookie -->
<div id='cookieAcceptBar' class='cookieAcceptBar' style='display: none;'>
  _{COOKIE_AGREEMENTS}_
  <a href='%COOKIE_URL_DOC%' target='_blank'>_{COOKIE_URL}_</a>
  <br>
  <button id='cookieAcceptBarConfirm' class='btn btn-success' onclick='hideBanner()'>_{SUCCESS}_</button>
</div>

<script>

  /* Geolocation */
  jQuery(function () {
    if (/Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent)) {
      jQuery('#language_mobile').on('change', selectLanguage);
    } else {
      jQuery('#language').on('change', selectLanguage);
    }

    if ('$conf{CLIENT_LOGIN_GEOLOCATION}') {
      var loginBtn = jQuery('#login_btn');

      /* Disable login button */
      loginBtn.addClass('disabled');

      /* Enable button in 3 seconds in any case (If navigation has error) */
      setTimeout(enableButton, 3000);

      getLocation(enableButton);

      function enableButton() {
        loginBtn.removeClass('disabled');
      }
    } else {
      console.log('Geolocation is disabled');
    }

    if ('$conf{CLIENT_LOGIN_NIGHTMODE}') {
      var D = new Date(), Hour = D.getHours();
      if (Hour >= 18) {
        var div = document.createElement('div');
        div.className = 'modal-backdrop';
        div.style.zIndex = -2;

        jQuery('body').prepend(div);
        jQuery('.wrapper').addClass('modal-content');
      } else {
        console.log('Night mode is enabled, but it\'s not evening ( Hour < 18)');
      }
    }

    if ('%TECH_WORKS_BLOCK_VISIBLE%' === '1') {
      jQuery('#tech_works_block').css('display', 'block');
    }

  }());

  jQuery(document).on('ready', function () {
    var successCookie = localStorage.getItem('successCookie');

    if (successCookie != '1') {
      jQuery('#cookieAcceptBar').show();

      var checkVisibleCookie = jQuery('#HIDDEN_COOKIE').val();
      jQuery('#cookieAcceptBar').css('display', checkVisibleCookie)
    }
  }());

  function hideBanner() {
    var banner = document.getElementById('cookieAcceptBar');

    if (banner.style.display === 'none') {
      banner.style.display = 'block';
    } else {
      banner.style.display = 'none';
      localStorage.setItem('successCookie', 1);
    }
  }

  const togglePassword = document.querySelector('#togglePasswd');
  const password = document.querySelector('#passwd');

  togglePassword.addEventListener('click', function () {
    // toggle the type attribute
    const type = password.getAttribute('type') === 'password' ? 'text' : 'password';
    password.setAttribute('type', type);
    // toggle the eye icon
    this.children[0].classList.toggle('fa-eye');
    this.children[0].classList.toggle('fa-eye-slash');
  });
</script>