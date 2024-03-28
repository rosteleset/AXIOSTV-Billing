<!-- Processing Perl variables to JavaScript -->

%JS_VARIABLES%

<div class='row'>
    <div class='btn-group btn-group-xs' role='group'>
        <button type='button' id='navigation' class='btn btn-secondary' onclick='aNavigation.showRoute()'>_{SHOW}_ _{ROUTE}_</button>
        <button type='button' id='goToMainNavigation' class='btn btn-secondary'>_{ROUTE}_</button>
    </div>
</div>
<div id='map' class='col-md-12' style='height: 85vh'></div>
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

<link rel='stylesheet' type='text/css' href='/styles/default_adm/css/modules/maps-yandex.css'>

<script id='maps_general' src='/styles/default_adm/js/maps/general.js'></script>
<script id='maps_request' src='/styles/default_adm/js/maps/general-request.js'></script>

<!--Yandex maps specific logic-->
<!--<script id='google_clusterer_script' src='/styles/default_adm/js/maps/google-clusterer.min.js'></script>-->
<script src='https://api-maps.yandex.ru/2.1/?lang=ru_RU&onload=initialize'></script>


<script id='ymaps_script' src='/styles/default_adm/js/maps/yandex.js'></script>


<!-- General Maps logic -->
<script id='maps_script' src='/styles/default_adm/js/maps/maps.js'></script>

<!--Defining markers-->
<!-- Builds -->
<script defer> %BUILDS% </script>
<!-- NAS -->
<script defer> %NAS% </script>
<!-- OBJECTS -->
<script defer> %OBJECTS% </script>
<!-- ROUTES -->
<script defer> %ROUTES% </script>
<!-- WIFI -->
<script defer> %WIFIS% </script>
<!-- WELL -->
<script defer> %WELLS% </script>
<!-- GPS -->
<script defer> %GPS% </script>
