<!DOCTYPE html>
<html>
<head>
  <meta http-equiv='Content-Type' content='text/html; charset=utf-8'/>
  <title>$conf{WEB_TITLE} - Portal</title>

  <style>
    .brand-logo {
      padding: 2px;
      margin-right: 4em;
    }

    .login-button {
      margin: 5px 5px;
    }

    .logo-mini {
      justify-content: center;
      display: flex;
      margin-top: -8px;
    }

    .timeline {
      margin-top: 15px;
    }

    body {
      background-color: #f4f6f9;
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

    .article {
      padding-bottom: 0px;
    }

    .socials-header {
      display: inline-block;
      word-spacing: 16px;
      padding: 3px 0;
    }

    .socials-header i {
      color: white;
    }

    .picture {
      max-height: 600px;
      max-width: 100%;
    }
  </style>

</head>
<body class='skin-blue-light sidebar-collapse layout-boxed '>
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

<div class='top-header navbar-light bg-gradient-primary main-header'>
  <div class='top-nav container-xl px-3'>
    <div class='d-flex justify-content-between'>
      <div>
        <!-- Your custom content for left top header -->
      </div>
      <div class='socials-header'>
        %SOCIAL_LINKS_HEADER%
      </div>
    </div>
  </div>
</div>

<header class='main-header navbar navbar-expand-lg navbar-light navbar-white sticky-top'>
  <nav class='container-xl bd-gutter navbar-expand-lg flex-wrap flex-lg-nowrap'>
    <a href='index.cgi' class='navbar-brand pl-2'>
      <span class='logo-mini' title='АСР КАЗНА 39'>
        <img src='/styles/default/img/logo/logo-mini.png' height='40'>
      </span>
    </a>

    <span>
      %REGISTRATION_MOBILE%

      <a href='%SELF_URL%?login_page=1' class='d-lg-none btn btn-primary my-2 my-sm-0 ml-auto mr-3' title='_{USER_PORTAL}_'>
        <i class='fa fa-user'></i>
        <span class='d-none d-xxsm-inline d-xsm-none'>_{USER_PORTAL_SHORTER}_</span>
        <span class='d-none d-xsm-inline'>_{USER_PORTAL}_</span>
      </a>
    </span>
    <button
      class='navbar-toggler'
      type='button'
      data-toggle='collapse'
      data-target='#navbarContent'
      aria-controls='navbarContent'
      aria-expanded='false'
      aria-label='Toggle navigation'
    >
      <span class='navbar-toggler-icon'></span>
    </button>

    <div class='collapse navbar-collapse' id='navbarContent'>
      <ul class='navbar-nav mr-auto'>
        %MENU%
      </ul>

      <div class='form-inline my-2 my-lg-0'>
        %REGISTRATION%
        <a href='%SELF_URL%?login_page=1' class='d-none d-lg-block btn btn-primary my-2 my-sm-0' title='_{USER_PORTAL}_'>
          <i class='fa fa-user'></i>
          _{USER_PORTAL}_
        </a>
      </div>
    </div>
  </nav>
</header>

<div id='bodyPan' class='mt-3 container-xl'>
    <ul class='list-unstyled'>
      %CONTENT%
    </ul>
  </div>

  <div id='bodyMiddlePan'>
  </div>

  <div id='footermainPan'>
    <div id='footerPan'>
    </div>
  </div>

</div>
  <div id='cookieAcceptBar' class='cookieAcceptBar' style='display: none;'>
    _{COOKIE_AGREEMENTS}_
    <a href='%COOKIE_URL_DOC%' target='_blank'>_{COOKIE_URL}_</a>
    <br>
    <button id='cookieAcceptBarConfirm' class='btn btn-success' onclick='hideBanner()'>_{SUCCESS}_</button>
  </div>
</body>
</html>

<script>
  jQuery(document).on('ready', function() {
    var successCookie = localStorage.getItem('successCookie');

    if (successCookie != '1') {
      jQuery('#cookieAcceptBar').show();

      var checkVisibleCookie = jQuery('#HIDDE_COOKIE').val();
      jQuery('#cookieAcceptBar').css('display', checkVisibleCookie)
    }
  });

  function hideBanner() {
    var banner = document.getElementById('cookieAcceptBar');

    if (banner.style.display === 'none') {
      banner.style.display = 'block';
    } else {
      banner.style.display = 'none';
      localStorage.setItem('successCookie', 1);
    }
  }

</script>