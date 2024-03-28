<link rel='stylesheet' href='/styles/default_adm/css/modules/maps/maps.css'>

%JS_VARIABLES%

<div class="row">
  <div class="col-md-12">
    <div id='mapControls' class='pull-left' role='group'></div>
  </div>
  <div class="col-md-12">
    <div class='card card-primary card-outline'>
      <div class='card-body' id='map-wrapper'>
        <div id='map' class='col-md-12' style='height: 90vh'>
        </div>
      <div class='card-footer'></div>
    </div>
    <div class='clearfix'></div>
  </div>
</div>

<link rel='stylesheet' href='/styles/default_adm/css/modules/maps/maps.css'>
<link rel='stylesheet' type='text/css' href='/styles/default_adm/css/modules/maps-yandex.css'>

<script id='maps_general' src='/styles/default_adm/js/maps/general.js'></script>
<script id='maps_request' src='/styles/default_adm/js/maps/general-request.js'></script>

<!--Yandex maps specific logic-->
<!--<script id='google_clusterer_script' src='/styles/default_adm/js/maps/google-clusterer.min.js'></script>-->
<script src='https://api-maps.yandex.ru/2.1/?lang=ru_RU&onload=initialize'></script>

<script id='ymaps_script' src='/styles/default_adm/js/maps/yandex.js'></script>

<!-- General Maps logic -->
<script id='maps_script' src='/styles/default_adm/js/maps/maps.js'></script>

<!-- OBJECTS -->
<script defer> %OBJECTS% </script>
