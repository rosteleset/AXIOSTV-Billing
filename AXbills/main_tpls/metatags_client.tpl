<!DOCTYPE html>
<html>
<head>
  <meta charset='UTF-8'>
  <meta name='viewport' content='width=device-width, initial-scale=1'>
  <meta http-equiv='X-UA-Compatible' content='IE=edge'>

  <meta content='width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no' name='viewport'>
  <meta HTTP-EQUIV='Cache-Control' content='no-cache,no-cache,no-store,must-revalidate,private, max-age=5'/>
  <meta HTTP-EQUIV='Expires' CONTENT='-1'/>
  <meta HTTP-EQUIV='Pragma' CONTENT='no-cache'/>
  <meta HTTP-EQUIV='Content-Type' CONTENT='text/html; charset=%CHARSET%'/>
  <meta HTTP-EQUIV='Content-Language' content='%CONTENT_LANGUAGE%'/>
  <meta name='Author' content='АСР AXbills'/>

  <title>%TITLE%</title>
  
  <!-- CSS -->
  <link rel="shortcut icon" type="image/x-icon" href='/img/favicon.ico'>
  <link rel='stylesheet' type='text/css' href='/styles/%HTML_STYLE%/css/select2.css'>
  <link rel='stylesheet' type='text/css' href='/styles/%HTML_STYLE%/css/adminlte.min.css'>

  <!-- Theme style -->
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

  <!-- Bootstrap -->
  <script src='/styles/%HTML_STYLE%/js/jquery.min.js'></script>
  <script src='/styles/%HTML_STYLE%/js/bootstrap.bundle.min.js'></script>
  <script src='/styles/%HTML_STYLE%/js/adminlte.min.js'></script>

  <!-- ECMA6 functions -->
  <script src='/styles/%HTML_STYLE%/js/polyfill.js'></script>

  <!-- Cookies and LocalStorage from JavaScript -->
  <script src='/styles/%HTML_STYLE%/js/js.cookies.js'></script>
  <script src='/styles/%HTML_STYLE%/js/permanent_data.js'></script>

  <!-- Navigation bar saving show/hide state -->
  <script  src='/styles/%HTML_STYLE%/js/navBarCollapse.js'></script>

  <!--Javascript template engine-->
  <script src='/styles/%HTML_STYLE%/js/mustache.min.js'></script>

  <script  src='/styles/%HTML_STYLE%/js/QBinfo.js'></script>

  <!-- Modal popup windows management -->
  <script src='/styles/%HTML_STYLE%/js/modals.js'></script>

  <!-- AJAX Search scripts -->
  <script src='/styles/%HTML_STYLE%/js/search.js'></script>

  <script src='/styles/%HTML_STYLE%/js/messageChecker.js'></script>

  <script src='/styles/%HTML_STYLE%/js/jquery-ui.min.js'></script>

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

  <!-- functions.js -->
  <script src='/styles/%HTML_STYLE%/js/functions.js'></script>
  <script src='/styles/%HTML_STYLE%/js/functions-client.js'></script>

  <script>
    window['IS_ADMIN_INTERFACE'] = false;
    window['IS_CLIENT_INTERFACE'] = true;

    var SELF_URL  = '$SELF_URL';
    if (SELF_URL) {
      var BASE_URL  = '$SELF_URL';
      BASE_URL = BASE_URL.match(/(https|http):\/\/.+?(?=\/)/)[0];
    }
    var SID = '$sid';
    var NO_DESIGN = '$FORM{NO_DESIGN}';

    var _COMMENTS_PLEASE = '_{COMMENTS_PLEASE}_' || 'Comment please';
    var EVENT_PARAMS = {
      portal  : 'client',
      link    : '/index.cgi?qindex=100002',
      disabled: ('$conf{USER_PORTAL_EVENTS_DISABLED}' === '1'),
      interval: 30000
    };

    var CONTENT_LANGUAGE = '%CONTENT_LANGUAGE%';
    var CURRENCY_ICON = '%CURRENCY_ICON%';

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
  </script>

  $conf{HOTJAR_SCRIPT_CLIENT}
</head>
