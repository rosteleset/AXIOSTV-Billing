<!DOCTYPE html>
<html lang='en'>
<head>
  <meta charset='UTF-8'>
  <!-- Tell the browser to be responsive to screen width -->
  <meta content='width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no' name='viewport'>

  <title>Hotspot Advertisement</title>
  <link rel='stylesheet' href='/styles/default/css/adminlte.min.css'>
  <script src='/styles/default/js/jquery.min.js'></script>

  <style>
    #ad_page {
      height: 100%;
      min-height: 700px;
    }

    .container {
      width: 100%;
    }
  </style>

</head>
<body>

<div class='container'>
  <div class='row'>
    <div class='well-sm'>
      <div class='col-xs-3' id='refresh_time_left'>%PERIOD%</div>
      <div class='col-xs-3 float-right'>
        <a href='%ORIGIN_URL%'>_{SKIP}_</a>
      </div>
      <div class='clearfix'></div>
    </div>
  </div>
  <div class='row' id='ad_page_container'>

    <!--Will request ad page on mikrotik, so he knows ad has been shown-->
    <iframe id='mikrotik_preload' src='%MIKROTIK_AD_URL%' width='0' height='0' onload='loadAd()'></iframe>

    <!--After that we show ad iframe-->
    <iframe id='ad_page' width='100%' height='auto' frameborder='0' seamless></iframe>
  </div>
</div>

<script>
  var ad_url = '%AD_URL%' || 'https://axiostv.ru/';
  var time      = jQuery('#refresh_time_left');
  var startTime = '%PERIOD%' || 10;

  function loadAd() {
    if (ad_url) {
      jQuery('#ad_page').attr('src', ad_url);
      reduceTime(startTime);
    }
    else {
      location.href = '%MIKROTIK_AD_URL%';
    }
  }

  function reduceTime(toTime) {
    time.text(toTime);
    setTimeout("reduceTime(" + (toTime - 1) + ")", 1000);
  }
</script>

</body>
</html>