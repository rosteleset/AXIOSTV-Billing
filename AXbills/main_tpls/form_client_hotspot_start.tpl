<!DOCTYPE html>
<html lang='ru'>
<head>
  %REFRESH%
  <META HTTP-EQUIV='Cache-Control' content='no-cache,no-cache,no-store,must-revalidate'/>
  <META HTTP-EQUIV='Expires' CONTENT='-1'/>
  <META HTTP-EQUIV='Pragma' CONTENT='no-cache'/>
  <META HTTP-EQUIV='Content-Type' CONTENT='text/html; charset=%CHARSET%'/>
  <META name='Author' content='АСР AXbills'/>
  <META HTTP-EQUIV='content-language' content='%CONTENT_LANGUAGE%'/>

  <meta name='viewport' content='width=device-width, initial-scale=1'>

  <link rel='stylesheet' type='text/css' href='/styles/default/css/adminlte.min.css'>
  <link rel='stylesheet' type='text/css' href='/styles/default/css/font-awesome.min.css'>
  <link rel='stylesheet' href='/styles/default/css/adminlte.min.css'>

  <style>
    #dropdown_language ul {

      min-width: 80px !important;
      max-width: 80px !important;

      margin-left: -30px;
    }

    #dropdown_language ul li {
      display: inline-block;

      min-width: 80px !important;
      max-width: 80px !important;

      padding: 5px;
    }

    .top-margin {
      margin-top: 5px;
    }

    .inline {
      padding-top: 5px;
      padding-bottom: auto;
    }

    .box-header .with-border {
      font-size: 10px;
      color: red;
    }

  </style>

  <script src='/styles/default/js/jquery.min.js'></script>
  <!--[if lt IE 9]>
  <script src='/styles/default/js/jquery-1.11.3.min.js' type='text/javascript'></script>
  <![endif]-->
  <script src='/styles/default/js/bootstrap.bundle.min.js'></script>
  <script src='/styles/default/js/js.cookies.js'></script>
  <script src='/styles/default/js/modals.js'></script>
  <!-- HTML5 shim and Respond.js for IE8 support of HTML5 elements and media queries -->
  <!-- WARNING: Respond.js doesn't work if you view the page via file:// -->
  <!--[if lt IE 9]>
  <script src="https://oss.maxcdn.com/html5shiv/3.7.3/html5shiv.min.js"></script>
  <script src="https://oss.maxcdn.com/respond/1.4.2/respond.min.js"></script>
  <![endif]-->
  <!--[if (lt IE 8) & (!IEMobile)]>
  <p class="chromeframe">Sorry, our site supports Internet Explorer starting from version 9. You need to <a
      href="http://browsehappy.com/">upgrade your browser</a> or <a
      href="http://www.google.com/chromeframe/?redirect=true">activate Google Chrome Frame</a> to use the site.</p>
  <![endif]-->
</head>
<body class='skin-blue layout-top-nav layout-boxed'>

<div class='wrapper'>
  <div class='content-wrapper'>
    <div class='container'>
      <div class='row'>
        <div class='center-block'>
          <div class='card  card-primary card-outline' style='text-align:center'>
            <div class='card-header with-border'>
              <div class='row '>
                <div class='col-md-1 col-xs-2 col-sm-1 col-lg-1'>
                </div>
                <div class='col-md-10 col-xs-8 col-sm-10 col-lg-10'>
                  <h3>
                    <b>
                      <img src='$conf{FULL_LOGO}' class='brand-text font-weight-light'> HotSpot start page
                    </b>
                  </h3>
                </div>
                <div class='col-md-1 col-xs-2 col-sm-1 col-lg-1' align='left'>
                  <ul class='nav nav-pills'>
                    <li class='dropdown' id='dropdown_language'>
                      <a class='dropdown-toggle' data-toggle='dropdown' data-target='#dropdown_language'
                        id='flag_active'>
                        <img src='/styles/default/img/flags/%LANG_CURRENT%.png' alt='%LANG_CURRENT%'/>
                      </a>
                      <ul class='dropdown-menu list-unstyled' id='flag_list'>%LANG_LIST%</ul>
                    </li>
                  </ul>
                </div><!-- end of col-md-1 -->
              </div> <!-- end of row -->
            </div> <!-- end of box-header with-border -->
            <div class='card-body'>
              <!-- <p>Domain ID: %DOMAIN_ID% Domain name: %DOMAIN_NAME%</p> -->
              <div class='row center-block'>
                <a class='btn btn-success btn-lg' href='%LOGIN_URL%'>_{I_HAVE_LOGIN_AND_PASSWORD}_</a>
                <a class='btn btn-secondary top-margin' href='$SELF_URL?GUEST_ACCOUNT=1&DOMAIN_ID=%DOMAIN_ID%%PAGE_QS%'>_{I_WANT_TO_TRY}_</a>
              </div>
              %ADDRESS_STREET% %ADDRESS_BUILD% %ADDRESS_FLAT%
            </div> <!-- END OF box-BODY -->
          </div> <!-- END OF PANEL -->
        </div>
      </div>

      <div class='row'>
        <div class='center-block'>
          <div class='card card-primary card-outline'>
            <div class='card-header with-border text-center'>
              <h3 style='margin:0'>_{I_HAVE_PIN_CARD}_</h3>
            </div>
            <div class='card-body' style='text-align:center'>

              <div class='row'>
                <div class='col-hidden-xs col-sm-3 col-md-3 col-lg-3'></div>
                <div class='col-xs-12 col-sm-12 col-md-6 col-lg-6'>
                  <form action='$SELF_URL'>
                    <input type=hidden name=DOMAIN_ID value=%DOMAIN_ID%>
                    <input type=hidden name=NAS_ID value=%NAS_ID%>
                    <input type=hidden name=language value=$FORM{language}>

                    <div class='col-xs-12 col-sm-1 col-md-1 col-lg-1 '>
                      <label for='PIN' style='margin-top: 10px'>PIN:</label>
                    </div>


                    <div class=' col-xs-12 col-sm-8 col-md-8 col-lg-8'>
                      <input class='form-control top-margin' type='text' name=PIN id='PIN' value=''>
                    </div>


                    <div class=' col-xs-12 col-sm-3 col-md-3 col-lg-3'>
                      <input class='form-input btn btn-secondary top-margin' type='submit' value='_{INFO}_'>
                    </div>

                  </form>
                </div>
                <div class='col-hidden-xs col-sm-3 col-md-3 col-lg-3'></div>
              </div>

            </div>
          </div>
        </div>
      </div>

      <div class='row' id='paysys_buy_cards' style='display:none'>
        <div class='card card-primary card-outline'>
          <div class='card-header with-border' style='text-align:center;'>
            <h3 style='margin:0'>_{BUY_CARD_ONLINE}_</h3>
          </div>
          <div class='card-body'>

            %CARDS_TYPE%

          </div>
        </div>
      </div>

      <div id='sell_points' style='display: none'>
        %SELL_POINTS%
      </div>
    </div> <!--END OF CONTAINER-->
  </div>
  <footer class='main-footer'></footer>
</div>

<script type='text/javascript'>
  var language_current = '%LANG_CURRENT%' || '';
  var lang_active      = '<img src=\'/styles/default/img/flags/' + language_current + '.png\'  alt=\'' + language_current + '\' />';

  if ('%SHOW_PAYSYS_BUY%' === '1'){
    jQuery('#paysys_buy_cards').show();
  }

</script>

</body>
</html>
