/**
 * Created by Anykey on 15.09.2015.
 *
 * General logic for maps
 */
'use strict';
/*Log name*/
var MODULE = 'Maps';

/** Holds main map container */
var mapDiv;
var map;

/** Holds references to tooltip panels for markers */
var infoWindows = [];
var markers = {};

/** Holds map center as google.maps.LatLng object */
var mapCenterLatLng;

var HAS_REAL_POSITION = false;
var realPosition = null;


// Events.setDebug(1);

function fullScreenDistrict() {
    var height = window.innerHeight;
    var width = window.innerWidth;
    var newWindow = window.open("/admin/index.cgi?qindex=" + index + "&header=1&MAP=1",
        "new",
        'width=' + width + ', height=' + height);
    newWindow.focus();
}

/*Marker Builder*/
var aMarkerBuilder;

//holders for instances of A... map objects. Initialized when called;
var aNavigation;
var aSearch;
var aControls;

if (DISTRICT_POLYGONS_ENABLED && typeof DistrictPolygoner !== 'undefined') {
    var aDistrictPolygoner = new DistrictPolygoner(LAYER_ID_BY_NAME[BUILD]);
}

/**
 * MarkerClusterer for grouping points
 */
var markerClusterer;
//Set distance at which markers will be grouped in a cluster
var CLUSTERER_GRID_SIZE = 30;

//Holding global refernces;
var openedInfoWindows = []; //last opened infowindow
var chicago = {lat: 41.85, lng: -87.65};

function CenterControl(controlDiv, map) {

    // Set CSS for the control border.
    var controlUI = document.createElement('div');
    controlUI.style.backgroundColor = '#ccc';
    controlUI.style.width = '100px';
    controlUI.style.color = 'black';
    controlUI.style.border = '3px solid #fff';
    controlUI.style.borderRadius = '3px';
    controlUI.style.boxShadow = '0 2px 6px rgba(0,0,0,.3)';
    controlUI.style.cursor = 'pointer';
    controlUI.style.textAlign = 'center';
    controlDiv.appendChild(controlUI);

    // Set CSS for the control interior.
    var controlText = document.createElement('div');
    controlText.style.width = '100%';
    controlText.id = 'myBar';
    controlText.style.height = '25px';
    controlText.style.backgroundColor = '#4CAF50';
    controlText.style.color = 'black';
    controlText.style.lineHeight = '32px';
    controlText.innerText = "Loading 1%";

    controlUI.appendChild(controlText);
}


function changeProgressBar(width) {
    var elem = document.getElementById('myBar');
    var id = setInterval(frame, 10);

    function frame() {
        clearInterval(id);
        if (elem) {
            elem.innerText = "Loading " + width + "%";
        }
    }
}

//Main function for setting up a map
function initialize() {
    $(function () {
        var mapOptions = ({
            rotateControls: true
        });

        mapDiv = document.getElementById('map');

        if (typeof AMessageChecker !== 'undefined') Events.on('mapsconfigured', registerMessageCheckerExtension);

        Events.on('mapsloaded', configureMap);
        Events.on('mapsloaded', function () {
            // ParseLayers
            $.each(LAYERS, function (i, layer_obj) {
                // console.log(layer_obj);
                MapLayers.createLayer(layer_obj);
            });

            Events.emit('layersready');
        });

        map = aMap.init(mapDiv, mapOptions, function (map_) {
            map = map_;
            var centerControlDiv = document.createElement('div');
            var centerControl = new CenterControl(centerControlDiv, map);

            centerControlDiv.index = 1;
            map.controls[google.maps.ControlPosition.TOP_CENTER].push(centerControlDiv);

            //Getting deal with mapCenter
            getMapCenter();

            if (form_query_search || form_type_search) {
                if (mapCenterLatLng) makeSearch(mapCenterLatLng)
            }
            if (FORM['COORDX'] && FORM['COORDY']) aMap.setCenter(FORM['COORDX'], FORM['COORDY']);
            if (FORM['ZOOM']) aMap.setZoom(FORM['ZOOM']);

            if (FORM['SHOW_BUILDS']) {
                Events.on('billingdefinedlayersshowed', function () {
                    if (
                        // If no build markers
                        !MapLayers.getLayerObjects(LAYER_ID_BY_NAME['BUILD']).length
                        // and no build polygons
                        && !MapLayers.getLayerObjects(LAYER_ID_BY_NAME['BUILD2']).length
                    ) {
                        // download builds
                        MapLayers.enableLayer(LAYER_ID_BY_NAME['BUILD']);
                    }
                });
            }

            // Show by layer id
            if (FORM['show_layer']) {
                Events.on('billingdefinedlayersshowed', function () {
                    var layer_id = FORM['show_layer'];
                    if (MapLayers.hasLayer(layer_id)) {
                        MapLayers.onLayerEnabled(layer_id, function () {
                            if (isDefined(FORM['OBJECT_ID'])) {
                                MapLayers.showObject(layer_id, FORM['OBJECT_ID']);
                            }
                        });
                        MapLayers.enableLayer(layer_id);
                    }
                    else {
                        aTooltip.displayError('show_layer on unexisting layer')
                    }
                });
            }
            // Show by layer name
            else if (FORM['show'] && LAYER_ID_BY_NAME[FORM['show']]) {
                Events.on('billingdefinedlayersshowed', function () {
                    var layer_id = LAYER_ID_BY_NAME[FORM['show']];

                    if (MapLayers.hasLayer(layer_id)) {
                        MapLayers.onLayerEnabled(layer_id, function () {

                            if (isDefined(FORM['OBJECT_ID'])) {
                                MapLayers.onLayerEnabled(layer_id, function () {
                                    MapLayers.showObject(layer_id, FORM['OBJECT_ID']);
                                });
                            }

                        });
                        console.log("hERREEE");
                        MapLayers.enableLayer(layer_id);
                    }
                    else {
                        console.warn('Show object on unexisting layer', LAYER_ID_BY_NAME, FORM['show']);
                    }
                });
            }

            if (FORM['add']) {
                Events.on('layersready', function () {
                    var layer_id = LAYER_ID_BY_NAME[FORM['add']];
                    if (isDefined(layer_id) && MapLayers.hasLayer(layer_id)) {
                        if (isDefined(FORM['OBJECT_ID'])) {
                            addNewPoint(layer_id, FORM['OBJECT_ID']);
                        }
                        else {
                            addNewPoint(layer_id);
                        }
                    }
                    else {
                        console.warn('add unknown layer')
                    }
                })
            }

            Events.on('mapsloaded', function () {

                if (form_query_search || form_type_search) {
                    if (mapCenterLatLng) makeSearch(mapCenterLatLng);
                }

                //If it is register build action
                if (FORM['LOCATION_TYPE']) {
                    if (FORM['LOCATION_ID'] || FORM['ROUTE_ID']) {
                        addNewPoint(FORM['LOCATION_TYPE']);
                    }
                }

                if (FORM['MAKE_NAVIGATION_TO']) {
                    if (form_nav_x && form_nav_y) {
                        Events.on('realpositionretrieved', function (position) {
                            var destination = aMap.createPosition(form_nav_x, form_nav_y);
                            aMap.setCenter(position[0], position[1]);
                            aNavigation = new Navigation(map);
                            aNavigation.createExtendedRoute(destination);
                        });
                    }
                }
            });

            Events.emit('mapsloaded', true);
        });

    });
}

function getMapCenter() {
    //if (form_x && form_y) { //if it is set explicitly
    //  console.log('START: ' + 'Coordinates set by FORM params ' + form_x + ', ' + form_y);
    //  setMapCenter([form_x, form_y]);
    //}
    //else
    if (mapCenter === '') {
        if (FORM['show_gps']) {
            console.log('START: Coordinates skipped. Showing GPS route');
            return true;
        }
        console.log('START: ' + 'Coordinates will be retrieved by goToRealPosition()');
        goToRealPosition(
            function (position) {
                setMapCenter(position);
                if (form_query_search || form_type_search) {
                    makeSearch(mapCenterLatLng);
                }
                Events.emit('realpositionretrieved', position);
            },
            function () {
                setMapCenter([48, 25]);
                if (form_query_search || form_type_search) {
                    makeSearch(mapCenterLatLng);
                }
                Events.emit('realpositionfailed')
            }
        );
    }
    else if (mapCenter !== '') {
        console.log('START: ' + 'Coordinates set by mapCenter');
        console.log('MapCenter: ' + mapCenter);
        var mapCenterSplitted = mapCenter.split(', ');

        var x = mapCenterSplitted[0];
        var y = mapCenterSplitted[1];
        var zoom = mapCenterSplitted[2];
        mapCenterLatLng = aMap.createPosition(x, y);

        changePosition(x, y, zoom);
    }
    else {

    }
    return true;
}

function configureMap() {

    aMarkerBuilder = new MarkerBuilder(map);

    aSearch = new Search();
    aSearch.init(map);

    aNavigation = new Navigation();
    aNavigation.init(map);

    if (CLUSTERING_ENABLED) {
        MapLayers.setClusteringEnabled(CLUSTERER_GRID_SIZE);
    }

    var addControls = function () {
        aControls = new MapControls(map);

        // Buttons are defined in order they will appear in Map Controls

        if (OPTIONS['SHOW_ADD_BTN'] && (typeof DrawController !== 'undefined')) {

            var add_layer_object_buttons = [
                {name: _BUILD, onclick: 'addNewPoint(' + LAYER_ID_BY_NAME[BUILD] + ')'},
                //{name: _ROUTE, onclick: 'addNewPoint(' + LAYER_ID_BY_NAME[ROUTE] + ')'},
                //{name: _DISTRICT, onclick: 'addNewPoint(' + LAYER_ID_BY_NAME[DISTRICT] + ')'},
                {name: _WIFI, onclick: 'addNewPoint(' + LAYER_ID_BY_NAME[WIFI] + ')'},
                {name: _OBJECT, onclick: 'addNewPoint(' + LAYER_ID_BY_NAME[CUSTOM_POINT] + ')'},
                {name: _BUILD2, onclick: 'addNewPoint(' + LAYER_ID_BY_NAME[BUILD2] + ')'}
            ];

            for (var j = 0; j < LAYERS.length; j++) {
                var layer_to_add = LAYERS[j];
                if (layer_to_add['id'] < 100 && typeof (layer_to_add['add_func']) === 'undefined') continue;

                add_layer_object_buttons[add_layer_object_buttons.length] = {
                    name: layer_to_add['lang_name'],
                    onclick: 'addNewPoint(' + layer_to_add['id'] + ')'
                };
            }

            aControls.addDropdown(aControls.ROW_EDIT, {
                icon: 'plus',
                options: add_layer_object_buttons,
                title: _ADD + ' ' + _POINT,
                id: 'addOperationCtrlBtn',
                'class': 'success'
            });


            aControls.addBtn(aControls.ROW_EDIT,
                {
                    icon: 'minus',
                    onclick: 'toggleRemoveMarkerMode()',
                    title: _REMOVE + ' ' + _MARKER + ' ' + _LOCATION,
                    id: 'removeLocation',
                    'class': 'danger'
                }
            );
            aControls.addBtn(aControls.ROW_EDIT,
                {
                    icon: 'remove-sign',
                    onclick: 'dropOperation()',
                    title: _DROP,
                    id: 'dropOperationCtrlBtn',
                    'class': 'default hidden'
                }
            );
        }

        if (layersCtrlEnabled) {
            var layer_name_id_array = [];
            //var btn_group_id        = aControls.createBtnGroup(aControls.ROW_LAYERS, _TOGGLE + ' ' + _MAP_OBJECT_LAYERS, 'showLayersControlBlock');

            for (var i = 0; i < LAYERS.length; i++) {
                var layer = LAYERS[i];

                // Refresh button
                var $refresh_button = $('<button></button>',
                    {
                        onclick: 'MapLayers.refreshLayer(' + layer['id'] + ');cancelEvent()',
                        'class': 'btn btn-xs btn-flat btn-secondary pull-left'
                    })
                    .html($('<i></i>', {'class': 'fa fa-refresh'}));

                var layer_btn = $('<a></a>', {
                    onclick: 'AMapLayersBtns.toggleButton(' + layer['id'] + ')',
                    'class': 'btn btn-xs btn-secondary text-left',
                    id: 'toggleLayer_' + layer.id
                })
                    .html($refresh_button[0].outerHTML + layer['lang_name']);

                aControls.addRawBtn(aControls.ROW_LAYERS, layer_btn);

                layer_name_id_array[layer_name_id_array.length] = layer['id'];
            }

            AMapLayersBtns.initButtons(layer_name_id_array);
        }

        if (searchCtrlEnabled && aSearch.isAvailable) {
            aControls.addDropdown(aControls.ROW_VIEW, {
                    icon: 'search',
                    options: [
                        {
                            name: _BY_QUERY,
                            onclick: 'showModalQuerySearch()'
                        },
                        {
                            name: _BY_TYPE,
                            onclick: 'showModalTypeSearch()'
                        }
                    ],
                    'class': '',
                    title: _SEARCH,
                    id: 'map_api_search'
                }
            );
        }

        //if (navigationCtrlEnabled)
        //  aControls.addBtn('road', 'aNavigation.showRoute()', _NAVIGATION, 'makeNavigationCtrl', 'primary');

        if (DISTRICT_POLYGONS_ENABLED) {
            aControls.addBtn(aControls.ROW_VIEW, {
                icon: 'bookmark',
                onclick: 'aDistrictPolygoner.toggle()',
                title: _TOGGLE + ' ' + _POLYGONS,
                id: 'polygonToggle'
            });
        }

        aControls.addBtn(aControls.ROW_VIEW, {
            icon: 'print',
            onclick: 'printMap()',
            title: 'Print',
            id: 'printButton'
        });

        Events.on('1_ENABLED', function () {
            window['BuildClustererControl'] = new ClustererControl(LAYER_ID_BY_NAME[BUILD], 'clusterToggle');
        });

        aControls.addBtn(aControls.ROW_VIEW, {
                icon: 'map-marker',
                onclick: 'BuildClustererControl.toggle()',
                title: _TOGGLE + ' ' + _MARKER + ' ' + _CLUSTERS,
                id: 'clusterToggle',
                class: 'success'
            }
        );

        aControls.init();
    };

    if (FORM['SHOW_CONTROLS']) {
        addControls();
    }
    else {
        Events.on('mapsconfigured', Events.emitAsCallback('controlblockcached'));
    }

//Events.on('new_point_rendered_' + LAYER_ID_BY_NAME[BUILD], function (newPoint) {
//  markers[newPoint['marker'].id] = newPoint['marker'];
//});

    Events.emit('mapsconfigured');
}

function setMapCenter(position) {

    //getPosition returns Number[];
    if ($.isArray(position))
        mapCenterLatLng = aMap.createPosition(position[0], position[1]);
    else
        mapCenterLatLng = position;

    createUserMarker(mapCenterLatLng);

    aMap.map.setCenter(mapCenterLatLng);
    aMap.map.setZoom(16);
}

function createUserMarker(positionLatLng) {

    var markerBuilder = new MarkerBuilder(map);

    HAS_REAL_POSITION = true;

    markerBuilder
        .setPosition(positionLatLng)
        .setIcon('user')
        .setTitle(FORM['title'])
        .setDraggable(true)
        .setClickable(false)
        .build();
    return this;
}

function getDefinedMapCenter() {

    if (mapCenterLatLng) {
        return mapCenterLatLng;
    }
    if (mapCenter !== '') {
        var $center = mapCenter.split(', ');
        var latLng = aMap.createPosition($center[0], $center[1]);
        var zoom = parseInt($center[2]);
        return [latLng, zoom];
    }
    else {
        return [aMap.createPosition(48, 25), 7];
    }
}

//Additional
/**
 *  Change position to coords
 */
function changePosition(x, y, zoom) {
    var newPos = aMap.createPosition(x, y);
    // goto point
    map.setCenter(newPos);
    //set zoom
    map.setZoom(parseInt(zoom) || 10);
}

function showModalQuerySearch() {

    var input = getSimpleRow('modalSearch', 'modalSearchInput', _SEARCH)[0].innerHTML;

    aModal.clear()
        .setHeader(_QUERY + " " + _SEARCH)
        .setBody(input)
        .addButton(_CANCEL, 'modalCancelBtn', 'default')
        .addButton(_SEARCH, 'modalQuerySearchBtn', 'primary')
        .show();

    setTimeout(function () {
        $('#modalQuerySearchBtn').on('click', function () {
            var val = $('#modalSearchInput').val();

            aSearch.makeQuerySearch(val, mapCenterLatLng);

            aModal.hide();
        });

        $('#modalCancelBtn').on('click', aModal.hide);
    }, 500);

}

function showModalTypeSearch() {

    var input = '<form id="modalTypeSearch" class="form form-horizontal">' +
        getCheckboxRow('atm', 'modalTypeSearchAtm', 'ATM')[0].innerHTML +
        getCheckboxRow('bank', 'modalTypeSearchBank', 'Banks')[0].innerHTML +
        getCheckboxRow('finance', 'modalTypeSearchFinance', 'Finance')[0].innerHTML +
        '</form>';

    aModal.clear()
        .setId('modalTypeSearchModal')
        .setHeader(_QUERY + " " + _SEARCH)
        .setBody(input)
        .addButton(_CANCEL, 'modalCancelBtn', 'default')
        .addButton(_SEARCH, 'modalQuerySearchBtn', 'primary')
        .show(function (modal) {

            $('#modalQuerySearchBtn').on('click', function () {
                var types = [];

                var form = $('#modalTypeSearch');

                if (form.find('#modalTypeSearchAtm').prop('checked')) types.push('atm');
                if (form.find('#modalTypeSearchBank').prop('checked')) types.push('bank');
                if (form.find('#modalTypeSearchFinance').prop('checked')) types.push('finance');

                if (types.length > 0) {
                    aSearch.makeNearbySearch(types, mapCenterLatLng);
                }
                aModal.destroy();
            });

            $('#modalCancelBtn').on('click', modal.destroy);
        }, 500);
}

function makeSearch(position) {
    if (!aSearch.isReady()) aSearch.init(map);

    if (typeof position === 'undefined') position = mapCenterLatLng;

    if (form_query_search || form_type_search) {
        if (form_query_search) {
            var query = '';
            var $arr = form_query_search.split(";");
            $.each($arr, function (i, entry) {
                query += entry + ' OR ';
            });

            aSearch.makeQuerySearch(query, position)
        }

        if (form_type_search) {
            aSearch.makeNearbySearch(form_type_search, position);
        }
    }
}

function goToRealPosition(successCallback) {

    function errorCallback() {
        alert(_NAVIGATION_WARNING);
        changePosition(48, 30, 4);
    }

    if (!successCallback) {
        successCallback = function (position) {
            createDefaultMarker(aMap.createPosition(position[0], position[1]), 'user');

            // Reversing coords
            changePosition(position[1], position[0], 14);
        };
    }
    getLocation(successCallback, errorCallback);
}

function createDefaultMarker(place, icon) {

    //Instantiating new builder
    var markerBuilder = new MarkerBuilder(map);
    markerBuilder.setPosition(place.geometry.location);
    markerBuilder.setDynamic(true);
    //if icon defined, set icon
    if (icon) {
        markerBuilder.setIcon(icon);
    }

    //creating _infoWindow
    var content = place.name + '<br />';
    if (place['formatted_address']) content += place['formatted_address'];
    markerBuilder.setInfoWindow(content);

    // TODO: localize
    markerBuilder.setNavigation("Go to");

    if (place.id) {
        markerBuilder.setId(place.id);
    }

    var result = markerBuilder.build();

    markerBuilder = null;

    return result;
}

function closeInfoWindows() {
    var infoWindow;
    while (infoWindow = openedInfoWindows.pop()) {
        infoWindow.close();
    }
}

function registerMessageCheckerExtension() {
    var message_type = 'MAP_EVENT';

    AMessageChecker.extend({
        TYPE: message_type,
        CALLBACK: function (event_data) {
            if (isDefined(event_data['OBJECTS'])) BillingObjectParser.render(event_data['OBJECTS']);
        }
    });
}

function printMap() {

    var openWindowRenderAndPrint = function openWindowRenderAndPrint() {

        var printWin = window.open('', '', 'width=1000,height=700');
        if (printWin === null) {
            alert('Please allow popups to open map print');
        }
        //
        //try {
        //  var center = map.getCenter();
        //  map.setCenter(center);
        //}
        //catch (e){
        //  console.log("Failed to resize map : " +  e.toString());
        //}
        //

        var windowContent = '<!DOCTYPE html>';
        html2canvas(mapDiv, {
            useCORS: true,
            onrendered: function (canvas) {
                windowContent += '<html>';
                windowContent += '<head><title>Print Map</title></head>';
                windowContent += '<body>';
                windowContent += '<img src="' + canvas.toDataURL() + '" style="min-height: 100vh;min-width 100vh;">';
                windowContent += '</body>';
                windowContent += '</html>';
                printWin.document.open();
                printWin.document.write(windowContent);
                printWin.document.close();
                printWin.focus();
                setTimeout(function () {
                    printWin.print();
                    printWin.close();
                }, 500);
            }
        });
    };

    // Dirty fixes

    // Disabling controls
    map.setOptions({
        mapTypeControl: false,
        zoomControl: false,
        streetViewControl: false,
        panControl: false
    });

    var patchedStyle = $('<style media="print">')
        .text('img { max-width: none !important; }\n' + 'a[href]:after { content: ""; }')
        .appendTo('head');


    openWindowRenderAndPrint();


    // Enabling controls
    map.setOptions({
        mapTypeControl: true,
        zoomControl: true,
        streetViewControl: true,
        panControl: true
    });

    patchedStyle.remove();
}

var SettingsSaver = (function () {

    var config = null;
    var self = this;

    function restoreSavedConfig() {
        var config_string = aStorage.getValue('maps_config', '{}');
        try {
            config = JSON.parse(config_string);
        }
        catch (JSONParseError) {
            console.warn('[ SettingsSaver ] Failed to parse config :', JSONParseError);
            return false;
        }

        if (FORM['only_one_layer']) {
            $.each(config.layers, function (index, value) {
                if (index !== FORM['show_layer']) {
                    config.layers[index] = false;
                }
            });
        }

        return config;
    }

    function restoreLayers() {
        if (FORM && FORM['HIDE_ALL_LAYERS']) {
            console.log('[ SettingsSaver ]', 'restoreLayers', 'Skipped because of $attr->{HIDE_ALL_LAYERS}');
            return true;
        }

        console.log('[ SettingsSaver ]', 'restoreLayers', config.layers);
        if (!config.layers) {
            config.layers = {};
        }
        else {
            var count_l = 0;
            for (var layer_id in config.layers) {
                if (!config.layers.hasOwnProperty(layer_id)) continue;

                // If module was disabled, and layer is absent now, should delete it from config
                if (!MapLayers.hasLayer(layer_id)) {
                    delete config['layers'][layer_id];
                    continue;
                }
                // console.log(count_l++);
                (config.layers[layer_id])
                    ? MapLayers.enableLayer(layer_id)
                    : MapLayers.disableLayer(layer_id);
            }
        }

        Events.on('layer_enabled', function (layerName) {
            console.log(layerName, 'enabled');
            config.layers[layerName] = true;
            //self.saveConfig();
        });
        Events.on('layer_disabled', function (layerName) {
            console.log(layerName, 'disabled');
            config.layers[layerName] = false;
            //self.saveConfig();
        });
    }

    function restoreMapType() {
        if (!config.maptype) {
            config.maptype = {};
        }
        else {
            if (config.maptype[MAP_TYPE]) CONF_MAPVIEW = config.maptype[MAP_TYPE];
        }

        Events.on('savingmapconfig', function () {
            var maptype_lowercase = aMap.getMapType() || '';
            config.maptype[MAP_TYPE] = maptype_lowercase.toUpperCase();
        })
    }

    function restoreMapCenter() {
        if (isDefined(config.lastCenter && !FORM['DISTRICT_ID'])) {
            mapCenter = config.lastCenter;
        }

        Events.on('savingmapconfig', function () {
            var mapCenter = aMap.getCenter();

            var x = mapCenter.lat();
            var y = mapCenter.lng();

            config.lastCenter = x + ', ' + y + ', ' + aMap.getZoom();
        })
    }

    function saveConfig() {
        if (config !== null) {
            Events.emit('savingmapconfig');
            aStorage.setValue('maps_config', JSON.stringify(config));
        }
        else {
            Events.emit('clearmapconfig', config);
            aStorage.setValue('maps_config', '');
        }
    }

    function registerListeners() {
        $(window).on('beforeunload', saveConfig);

        Events.once('onbeforemapcreate', restoreMapType);
        Events.once('onbeforemapcreate', restoreMapCenter);

        // Need to wait while buttons are displayed
        Events.once('layersready', restoreLayers);
    }

    if (!CLIENT_MAP) {
        config = restoreSavedConfig();
        if (config) registerListeners(config);
    }
    else {
        console.log('Saved settings were ignored');
    }

    return {
        clear: function () {
            config = null
        }
    }

})();

/**
 * THIS IS START POINT OF A SCRIPT
 *
 *  WHEN AMAP HAS BEEN CREATING, IT LOADS MAPS API SCRIPTS ON PAGE,
 *
 *  WHICH WHEN READY CALL initialize FUNCTION
 * */
Events.emit('onbeforemapcreate');
var aMap = new AMap();

$(function () {
    var $filterForm = $('form#mapUserShow');

    var selects = [
        $filterForm.find('select#GID'),
        $filterForm.find('select#PANEL_DISTRICT_ID'),
        $filterForm.find('select#INFO_MODULE')
    ];

    selects.forEach(function (select) {
        select.on('change', function () {
            MapLayers.refreshLayer(LAYER_ID_BY_NAME[BUILD]);
        })
    })
});