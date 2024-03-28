<!DOCTYPE html>
<html>
<head>
  <title>%WEB_TITLE% - Login</title>
  <meta charset='utf-8'>
  <meta http-equiv='X-UA-Compatible' content='IE=edge'>
  <meta name='viewport' content='width=device-width, initial-scale=1'>

  <!-- Bootstrap core CSS -->
  <link href='/styles/default/css/adminlte.min.css' rel='stylesheet'>
  <link href='/styles/default/css/chosen.min.css' rel='stylesheet'>
  <link href='/styles/default/css/font-awesome.min.css' rel='stylesheet'>
  <link href='login.css' rel='stylesheet'>

  <script src='/styles/default/js/jquery.min.js'></script>
  <script src='/styles/default/js/bootstrap.bundle.min.js'></script>

  <!-- HTML5 shim and Respond.js for IE8 support of HTML5 elements and media queries -->
  <!--[if lt IE 9]>
  <script src='/styles/default/js/html5shiv.min.js'></script>
  <script src='/styles/default/js/respond.min.js'></script>
  <![endif]-->

  <script src='/styles/default/js/jquery.cookie.js'></script>
  <script src='/styles/default/plugins/moment/moment.min.js'></script>

</head>
<body>
<!-- Loading modal -->
<div class='modal fade' id='loading' tabindex='-1' role='dialog' aria-hidden='true'>
  <div class='modal-dialog modal-sm'>
    <div class='modal-content'>
      <div class='modal-header'>
        <button type='button' class='close' data-dismiss='modal' aria-label='Close'><span
            aria-hidden='true'>&times;</span></button>
        <h4 class='modal-title'>Status...</h4>
      </div>
      <div class='modal-body'>
        <p class='text-center' id='status'>
          Please wait while your device is being authorized.
          <img src='/styles/default/img/ajax-loader.gif'/>
        </p>
      </div>
    </div>
  </div>
</div>
<div class='container'>
  <div class='jumbotron jumbotron-sm'>
    <div class='row'>
      <div class='col-xs-12'>
        <h2 class='h2 text-center'>
          <label>%WEB_TITLE% HotSpot</label>
        </h2>
      </div>
    </div>
  </div>

  <div class='row' id='content'>
