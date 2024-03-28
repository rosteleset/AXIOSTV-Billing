<!DOCTYPE html>
<html>
<head>
  %REFRESH%
  <meta charset='utf-8' />
  <!-- Tell the browser to be responsive to screen width -->

  <meta content='width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no' name='viewport'>
  <meta http-equiv='X-UA-Compatible' content='IE=edge'>
  <meta http-equiv='Cache-Control' content='no-cache,no-cache,no-store,must-revalidate,private, max-age=5'/>
  <meta http-equiv='Expires' CONTENT='-1'/>
  <meta http-equiv='Pragma' CONTENT='no-cache'/>
  <meta http-equiv='Content-Type' CONTENT='text/html; charset=%CHARSET%'/>
  <meta http-equiv='Content-Language' content='%CONTENT_LANGUAGE%'/>
  <meta name='Author' content='АСР AXbills'/>
  <!-- Some new feature, need to actualize -->
  <!-- <meta name='theme-color' content="#db5945"> -->

  <title>%TITLE% %BREADCRUMB%</title>
  
  <!-- CSS -->
  <link rel="shortcut icon" type="image/x-icon" href='/img/favicon.ico'>
  <link rel='stylesheet' type='text/css' href='/styles/%HTML_STYLE%/css/select2.css'>
  <link rel='stylesheet' type='text/css' href='/styles/%HTML_STYLE%/css/adminlte.min.css'>
  <link rel='stylesheet' type='text/css' href='/styles/%HTML_STYLE%/css/bs-stepper.min.css'>

  <!-- Theme style -->
  <link rel='stylesheet' type='text/css' href='/styles/%HTML_STYLE%/css/skins/_all-skins.css'>

  <link rel='stylesheet' type='text/css' href='/styles/%HTML_STYLE%/plugins/pace/pace.min.css'>
  <link rel='stylesheet' type='text/css' href='/styles/%HTML_STYLE%/plugins/datepicker/datepicker3.css'>
  <link rel='stylesheet' type='text/css' href='/styles/%HTML_STYLE%/css/QBInfo.css'>

  <!-- Font Awesome -->
  <link rel='stylesheet' type='text/css' href='/styles/%HTML_STYLE%/css/font-awesome.min.css'>
  <!-- Pace style -->

  <!-- DataTables -->
  <link rel='stylesheet' type='text/css' href='/styles/%HTML_STYLE%/plugins/datatables/dataTables.bootstrap.css'>
  <link rel='stylesheet' type='text/css' href='/styles/%HTML_STYLE%/plugins/timepicker/bootstrap-timepicker.min.css'>
  <link rel='stylesheet' type='text/css' href='/styles/%HTML_STYLE%/plugins/daterangepicker/daterangepicker.css'>
  <link rel='stylesheet' type='text/css' href='/styles/%HTML_STYLE%/plugins/datetimepicker/datetimepicker.min.css'>
  <link rel='stylesheet' type='text/css' href='/styles/%HTML_STYLE%/css/style.css'>

  <!-- Admin's permissions clases-->
  %PERM_CLASES%

  <!-- Bootstrap -->
  <script src='/styles/%HTML_STYLE%/js/jquery.min.js'></script>
  <script src='/styles/%HTML_STYLE%/js/bootstrap.bundle.min.js'></script>
  <script src='/styles/%HTML_STYLE%/js/bs-stepper.min.js'></script>
  <script src='/styles/%HTML_STYLE%/js/adminlte.min.js'></script>

  <!-- ECMA6 functions -->
  <script src='/styles/%HTML_STYLE%/js/polyfill.js'></script>

  <!-- Cookies and LocalStorage from JavaScript -->
  <script src='/styles/%HTML_STYLE%/js/js.cookies.js'></script>
  <script src='/styles/%HTML_STYLE%/js/permanent_data.js'></script>

  <!-- temp -->
  <script src='/styles/%HTML_STYLE%/js/functions.js'></script>
  <script src='/styles/%HTML_STYLE%/js/functions-admin.js'></script>

  <!--Keyboard-->
  <script src='/styles/%HTML_STYLE%/js/keys.js'></script>

  <!-- Navigation bar saving show/hide state -->
  <script  src='/styles/%HTML_STYLE%/js/navBarCollapse.js'></script>

  <!--Javascript template engine-->
  <script src='/styles/%HTML_STYLE%/js/mustache.min.js'></script>

  <script  src='/styles/%HTML_STYLE%/js/QBinfo.js'></script>

  <!--Event PubSub-->
  <script src='/styles/%HTML_STYLE%/js/events.js'></script>

  <!-- Modal popup windows management -->
  <script src='/styles/%HTML_STYLE%/js/modals.js'></script>

  <!-- AJAX Search scripts -->
  <script src='/styles/%HTML_STYLE%/js/search.js'></script>

  <script src='/styles/%HTML_STYLE%/js/messageChecker.js'></script>

  <script src='/styles/%HTML_STYLE%/js/jquery-ui.min.js'></script>

  <!-- Textarea autosize -->
  %AUTOSIZE_INCLUDE%

  <!-- date-range-picker -->
  <script src='/styles/%HTML_STYLE%/plugins/moment/moment.min.js'></script>
  <script src='/styles/%HTML_STYLE%/plugins/datepicker/bootstrap-datepicker.js'></script>
  <script src='/styles/%HTML_STYLE%/plugins/pace/pace.js'></script>
  <script src='/styles/%HTML_STYLE%/plugins/datatables/jquery.dataTables.min.js'></script>
  <script src='/styles/%HTML_STYLE%/plugins/datatables/dataTables.bootstrap.min.js'></script>
  <script src='/styles/%HTML_STYLE%/plugins/timepicker/bootstrap-timepicker.min.js'></script>
  <script src='/styles/%HTML_STYLE%/plugins/daterangepicker/daterangepicker.js'></script>
  <script src='/styles/%HTML_STYLE%/plugins/datetimepicker/datetimepicker.min.js'></script>

  <script src='/styles/%HTML_STYLE%/plugins/datepicker/locales/bootstrap-datepicker.%CONTENT_LANGUAGE%.js'></script>
  <script src='/styles/%HTML_STYLE%/js/select2.min.js'></script>
  <script>
    window['IS_ADMIN_INTERFACE'] = true;
    window['IS_CLIENT_INTERFACE'] = false;

    window['IS_PUSH_ENABLED'] = '$admin->{SETTINGS}{PUSH_ENABLED}';

    var SELF_URL              = '$SELF_URL';
    if (SELF_URL) {
      var BASE_URL  = '$SELF_URL';
      BASE_URL = BASE_URL.match(/(https|http):\/\/.+?(?=\/)/)[0];
    }
    var INDEX                 = '$index';
    var _COMMENTS_PLEASE      = '_{COMMENTS_PLEASE}_' || 'Comments please';
    var _WORLD_PLEASE         = '_{ENTER_DEL}_' || 'Enter please';
    var _DEL                  = '_{DEL}_' || 'Delete';
    var _NO_RESULTS_FOUND = '_{NO_RESULTS_FOUND}_';
    var _SEARCH_AT_LEAST_MIN_CHARS = '_{SEARCH_AT_LEAST_MIN_CHARS}_';

    var _UNIVERSAL_SEARCH_FIELDS = '$conf{UNIVERSAL_SEARCH_FIELDS}';

    document['WEBSOCKET_URL'] = '%WEBSOCKET_URL%';

    //CHOSEN INIT PARAMS
    var CHOSEN_PARAMS = {
      no_results_text      : '_{NOT_EXIST}_',
      allow_single_deselect: true,
      placeholder_text     : '--',
      search_contains: true
    };

    var DATERANGEPICKER_LOCALE = {
      separator       : '/',
      applyLabel      : '_{APPLY}_',
      cancelLabel     : '_{CANCEL}_',
      fromLabel       : '_{FROM}_',
      toLabel         : '_{TO}_',
      'Today'         : '_{TODAY}_' || 'Today',
      'Yesterday'     : '_{YESTERDAY}_' || 'Yesterday',
      'Last 7 Days'   : '_{LAST}_ 7 _{DAYS}_',
      'Last 30 Days'  : '_{LAST}_ 30 _{DAYS}_',
      'This Month'    : '_{CURENT}_ _{MONTH}_',
      'Last Month'    : '_{PREVIOUS}_ _{MONTH}_',
      customRangeLabel: '_{OTHER}_'
    };

    var CONTENT_LANGUAGE = '%CONTENT_LANGUAGE%';
    var IS_DARK_MODE = '$admin->{SETTINGS}{BODY_SKIN}' === 'dark-mode';

    moment.locale('%CONTENT_LANGUAGE%');

    jQuery(function () {
      if (localStorage.getItem('largeText') && localStorage.getItem('largeText') === 'true') jQuery('body').removeClass('text-sm');

      if (!'%FAVICO_DISABLED%' && typeof window['initFavicon'] !== 'undefined'){
        initFavicon();
      }

      if (typeof autosize === 'function') {
        autosize(document.querySelectorAll('textarea'));
      }
    });
  </script>


  <!-- Needs WEBSOCKET_URL defined above -->
  <script src='/styles/default/js/websocket_client.js'></script>

  $conf{HOTJAR_SCRIPT_ADMIN}
</head>
<body class='hold-transition
  $admin->{SETTINGS}{FIXED_LAYOUT}
  $admin->{MENU_HIDDEN}
  %SIDEBAR_HIDDEN%
  $admin->{SETTINGS}{BODY_SKIN}
  sidebar-mini
  layout-fixed
  text-sm'
  style='height: auto'
>

<script>
  // Left sidebar closing in mobile devices
  if (document.body.clientWidth < 992) {
    document.body.classList.add('sidebar-collapse');
  }
</script>

<div class='wrapper'>
  %CALLCENTER_MENU%

  <div class='modal fade' id='comments_add' tabindex='-1' role='dialog'>
    <form id='mForm'>
      <div class='modal-dialog modal-sm'>
        <div class='modal-content'>
          <div id='mHeader' class='modal-header alert-info'>
            <h4 id='mTitle' class='modal-title'>&nbsp;</h4>
            <button type='button' class='close' data-dismiss='modal' aria-hidden='true'>&times;</button>
          </div>
          <div class='modal-body'>
            <div class='row'>
              <input type='text' class='form-control' id='mInput' placeholder='_{COMMENTS}_'>
            </div>
          </div>
          <div class='modal-body' id='mInputConfirmHide' style='display: none'>
            <div class='row'>
              <input type='text' class='form-control' id='mInputConfirm' placeholder='_{ENTER_DEL}_: _{DEL}_'>
            </div>
          </div>
          <div class='modal-footer'>
            <button type='button' class='btn btn-default' data-dismiss='modal'>_{CANCEL}_</button>
            <button type='submit' class='btn btn-danger danger' id='mButton_ok'>_{EXECUTE}_!</button>
          </div>
        </div>
      </div>
    </form>
  </div>

  <!-- Modal search -->
  <div class='modal fade' tabindex='-1' id='PopupModal' role='dialog' aria-hidden='true'>
    <div class='modal-dialog'>
      <div id='modalContent' class='modal-content'></div>
    </div>
  </div>


  <!-- -->
  <!--This div is used to get row-highlight background color-->
  <div class='bg-success' style='display: none'></div>


  <!-- -->

