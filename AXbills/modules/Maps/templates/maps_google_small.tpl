<link rel='stylesheet' href='/styles/default_adm/css/modules/maps/maps.css'>
<!-- Processing Perl variables to JavaScript -->

%JS_VARIABLES%

<div class='row' data-visible='%NAVIGATION_VISIBLE%'>
    <div class='btn-group btn-group-xs' role='group'>
    <button type='button' id='navigation' class='btn btn-secondary' onclick='aNavigation.showRoute()'>_{SHOW}_ _{ROUTE}_</button>
    <button type='button' id='goToMainNavigation' class='btn btn-secondary'>_{ROUTE}_</button>
    </div>
</div>
<div id='map' style='height: 85vh'></div>
<div class="clearfix"></div>
<script>
    var map_height = '%MAP_HEIGHT%' || '85';
    map_height += 'vh';
    jQuery('#map').css({height: map_height});

    jQuery('#goToMainNavigation').on('click', function () {
        //parse params we care
        var x = mapCenterLatLng.lat();
        var y = mapCenterLatLng.lng();

        //fill url
        var link = SELF_URL + '?get_index=maps_show_map&header=1&MAKE_NAVIGATION_TO=1&nav_x=' + x + '&nav_y=' + y;

        //goto
        location.replace(link);
    });
</script>


<script id='maps_general' src='/styles/default_adm/js/maps/general.js'></script>
<script id='maps_request' src='/styles/default_adm/js/maps/general-request.js'></script>

<!--Google maps specific logic-->
<script id='google_clusterer_script' src='/styles/default_adm/js/maps/google-clusterer.min.js'></script>
<script id='google_maps_script' src='/styles/default_adm/js/maps/google.js'></script>
<script id='maps_google_tooltip' src='/styles/default_adm/js/maps/google-tooltip.min.js' defer></script>


<!-- General Maps logic -->
<script id='maps_script' src='/styles/default_adm/js/maps/maps.js'></script>


<!-- OBJECTS we want to show on map -->
<script defer> %OBJECTS% </script>