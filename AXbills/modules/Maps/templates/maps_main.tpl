<!--Main Leaflet library-->
<link rel='stylesheet' href='/styles/default/css/modules/maps/leaflet.css'>
<script src='/styles/default/js/maps/leaflet.js'></script>

<!--Leaflet clusters-->
<link rel='stylesheet' href='/styles/default/css/modules/maps/MarkerCluster.css'>
<link rel='stylesheet' href='/styles/default/css/modules/maps/MarkerCluster.Default.css'>
<script src='/styles/default/js/maps/leaflet.markercluster.js'></script>

<!--Leaflet measure control-->
<link rel='stylesheet' href='/styles/default/css/modules/maps/Leaflet.PolylineMeasure.css'>
<script src='/styles/default/js/maps/Leaflet.PolylineMeasure.js'></script>

<!--Leaflet fullscreen-->
<link rel='stylesheet' href='/styles/default/css/modules/maps/leaflet.fullscreen.css'>
<script src='/styles/default/js/maps/Leaflet.fullscreen.min.js'></script>

<!--Leaflet.draw-->
<link rel='stylesheet' href='/styles/default/css/modules/maps/leaflet.draw.css'>
<script src='/styles/default/js/maps/Leaflet.draw.all.js'></script>

<!--Leaflet.ant-path -->
<script src='/styles/default/js/maps/leaflet-ant-path.js' type='text/javascript'></script>

<!--Google Maps-->
<script src='/styles/default/js/maps/Leaflet.GoogleMutant.js'></script>

<!--Yandex Maps-->
<script src='/styles/default/js/maps/Leaflet.YandexMap.js'></script>

<link href='/styles/default/css/font-awesome.min.css' rel='stylesheet'>

<link rel='stylesheet' href='/styles/default/css/modules/maps/maps.css'>

<script src='/styles/default/js/maps/lodash.min.js'></script>

<script src='/styles/default/js/maps/leaflet.semicircle.js'></script>

<script src='/styles/default/js/maps/Leaflet.BigImage.js'></script>
<link rel='stylesheet' href='/styles/default/css/modules/maps/Leaflet.BigImage.css'>

<script type='text/javascript' src='/styles/default/js/maps/Map.SelectArea.js'></script>

<script type='text/javascript' src='/styles/default/js/maps/Leaflet.CenterCoordinates.js'></script>
<link rel='stylesheet' href='/styles/default/css/modules/maps/Leaflet.CenterCoordinates.css'>

<script type='text/javascript' src='/styles/default/js/maps/leaflet-sidebar.min.js'></script>
<link rel='stylesheet' href='/styles/default/css/modules/maps/leaflet-sidebar.min.css'>

<script type='text/javascript' src='/styles/default/js/maps/Leaflet.MovingMarker.js'></script>

%JS_VARIABLES%

<div class='row'>
  <div class='col-sm-12 col-12'>
    <div class='card card-primary'>
      <div class='card-body' id='map-wrapper' style='padding: 5px !important;'>
        <div id='map' style='height: 85vh'></div>
      </div>
    </div>
  </div>
  <div class='clearfix'></div>
</div>

<div id='sidebar' class='leaflet-sidebar hidden'>
  <div class='leaflet-sidebar-tabs'>
    <ul role='tablist'>
      <li class='active'><a href='#home' role='tab'><i class='fa fa-bars'></i></a></li>
    </ul>
  </div>

  <div class='leaflet-sidebar-content'>
    <div class='leaflet-sidebar-pane active' id='home'>
      <h1 class='leaflet-sidebar-header'>
        <div class='leaflet-sidebar-close'><i class='fa fa-caret-left'></i></div>
      </h1>
      <div id='leaflet-sidebar-body'></div>
    </div>
  </div>
</div>

<script>

  function putScriptInHead(id, url, callback_load) {
    if (document.getElementById(id)) return 0;

    let scriptElement = document.createElement('script');

    if (callback_load) scriptElement.onload = callback_load;

    scriptElement.id = id;
    scriptElement.src = url;
    document.getElementsByTagName('head')[0].appendChild(scriptElement);
  }

  var map_height = MAP_HEIGHT || '85';
  map_height += 'vh';
  jQuery('#map').css({height: map_height});

  var selfUrl = '$SELF_URL';

  if (document.getElementById('new_maps')) {
    init_map();
    loadLayers();
  } else {
    putScriptInHead('general_requests_map', '/styles/default/js/maps/general-requests.js',
      putScriptInHead('new_maps', '/styles/default/js/maps/maps.js'));
  }
</script>