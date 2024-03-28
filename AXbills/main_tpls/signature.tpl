<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Signature Pad</title>
  <meta name="description" content="Signature Pad - HTML5 canvas based smooth signature drawing using variable width spline interpolation.">

  <meta name="viewport" content="width=device-width, initial-scale=1, minimum-scale=1, maximum-scale=1, user-scalable=no">

  <meta name="apple-mobile-web-app-capable" content="yes">
  <meta name="apple-mobile-web-app-status-bar-style" content="black">
  <link rel="stylesheet" href="../styles/default/css/signature-pad.css">

  <!--[if IE]>
    <link rel="stylesheet" type="text/css" href="css/ie9.css">
  <![endif]-->

</head>
<body onselectstart="return false">
  <div id="signature-pad" class="signature-pad">
    <div class="signature-pad--body">
      <canvas></canvas>
    </div>
    <div class="signature-pad--footer">
      <div class="description">Sign above</div>

      <div class="signature-pad--actions">
        <div>
          <button type="button" class="button clear" data-action="clear">Clear</button>
        </div>
        <div>
          <button type="button" class="button save" data-action="sign">Sign</button>
        </div>
      </div>
    </div>
  </div>
  <form id='signForm' method='POST'>
    <input type='hidden' name='index' value='$index' />
    <input type='hidden' name='UID' value='$FORM{UID}' />
    <input type='hidden' name='sign' value='$FORM{sign}' />
    <input type='hidden' name='signature' id='signData' value='' />
  </form>

  <script src="../styles/default/js/signature_pad.js"></script>
  <script src="../styles/default/js/signature_app.js"></script>
</body>
</html>
