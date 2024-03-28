<!-- Google Maps -->
<!-- Processing Perl variables to JavaScript -->
<link rel='stylesheet' href='/styles/default_adm/css/modules/maps/maps.css'>

%JS_VARIABLES%

<div class='row'>
  <div id='mapControls' class='pull-left text-left' role='group'></div>
</div>

<div class='row'>
  <div class='card card-primary card-outline'>
    <div class='card-body' id='map-wrapper'>
      <div id='map' style='height: 85vh'></div>
    </div>
    <div class='card-footer'></div>
  </div>
  <div class='clearfix'></div>
</div>


<script id='maps_general' src='/styles/default_adm/js/maps/general.js?v=7.61'></script>
<script id='maps_dynamic_forms' src='/styles/default_adm/js/dynamicForms.js'></script>
<script id='maps_request' src='/styles/default_adm/js/maps/general-request.js?v=7.61'></script>

<!--Google maps specific logic-->
<script id='google_clusterer_script' src='/styles/default_adm/js/maps/google-clusterer.min.js'></script>
<script id='maps_google_script' src='/styles/default_adm/js/maps/google.js?v=7.61'></script>
<script id='maps_google_tooltip' src='/styles/default_adm/js/maps/google-tooltip.min.js' defer></script>

<!-- General Maps logic -->
<script id='maps_script' src='/styles/default_adm/js/maps/maps.js?v=7.61'></script>

<script id='maps_print' src='/styles/default_adm/js/maps/html2canvas.min.js' async></script>

<!-- OBJECTS we want to show on map -->
<script defer>

%OBJECTS%

</script>

