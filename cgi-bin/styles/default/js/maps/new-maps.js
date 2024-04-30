/**
 * Created by pasichnyk on 2020-01-08.
 */
'use strict';

let map = {};
let baseMaps = {};
let drawControl = {};
let AllLayers = [];
let Layers = {};

let TempVariables = {};

//All objects on the Map
let Objects = {};
Objects['ADD_CLASS'] = {};

let ObjectsName = [];
let ObjectsById = [];

let LeafIcon = L.Icon.extend({
  options: {
    iconSize: [23, 23],
    iconAnchor: [12, 12],
    popupAnchor: [-10, -2]
  }
});

if (LAYERS && typeof(LAYERS) !== 'object') {
  LAYERS = LAYERS.split(',');
}

var Configuration = (function () {
  function getLocation() {
    if (localStorage.getItem('LAST_LNG') && localStorage.getItem('LAST_LAT')
        && localStorage.getItem('LAST_ZOOM') && !FORM['BUILD_ROUTE']) return 0;

    if (navigator.geolocation)
      navigator.geolocation.getCurrentPosition(Configuration.panToUserPosition);
    else
      console.log("Geolocation is not supported by this browser.");
  }

  function getOptions() {
    return {
      position: 'topright',            // Position to show the control. Values: 'topright', 'topleft', 'bottomright', 'bottomleft'
      unit: 'metres',                 // Show imperial or metric distances. Values: 'metres', 'landmiles', 'nauticalmiles'
      clearMeasurementsOnStop: true,  // Clear all the measurements when the control is unselected
      showBearings: false,            // Whether bearings are displayed within the tooltips
      bearingTextIn: 'In',             // language dependend label for inbound bearings
      bearingTextOut: 'Out',          // language dependend label for outbound bearings
      tooltipTextFinish: 'Click to <b>finish line</b><br>',
      tooltipTextDelete: 'Press SHIFT-key and click to <b>delete point</b>',
      tooltipTextMove: 'Click and drag to <b>move point</b><br>',
      tooltipTextResume: '<br>Press CTRL-key and click to <b>resume line</b>',
      tooltipTextAdd: 'Press CTRL-key and click to <b>add point</b>',
      // language dependend labels for point's tooltips
      measureControlTitleOn: 'Turn on PolylineMeasure',   // Title for the control going to be switched on
      measureControlTitleOff: 'Turn off PolylineMeasure', // Title for the control going to be switched off
      measureControlLabel: '&#8614;', // Label of the Measure control (maybe a unicode symbol)
      measureControlClasses: [],      // Classes to apply to the Measure control
      showClearControl: false,        // Show a control to clear all the measurements
      clearControlTitle: 'Clear Measurements', // Title text to show on the clear measurements control button
      clearControlLabel: '&times',    // Label of the Clear control (maybe a unicode symbol)
      clearControlClasses: [],        // Classes to apply to clear control button
      showUnitControl: false,         // Show a control to change the units of measurements
      distanceShowSameUnit: false,    // Keep same unit in tooltips in case of distance less then 1 km/mi/nm
      unitControlTitle: {             // Title texts to show on the Unit Control button
        text: 'Change Units',
        metres: 'metres',
        landmiles: 'land miles',
        nauticalmiles: 'nautical miles'
      },
      unitControlLabel: {             // Unit symbols to show in the Unit Control button and measurement labels
        metres: 'm',
        kilometres: 'km',
        feet: 'ft',
        landmiles: 'mi',
        nauticalmiles: 'nm'
      },
      tempLine: {                     // Styling settings for the temporary dashed line
        color: '#00f',              // Dashed line color
        weight: 2                   // Dashed line weight
      },
      fixedLine: {                    // Styling for the solid line
        color: '#006',              // Solid line color
        weight: 2                   // Solid line weight
      },
      startCircle: {                  // Style settings for circle marker indicating the starting point of the polyline
        color: '#000',              // Color of the border of the circle
        weight: 1,                  // Weight of the circle
        fillColor: '#0f0',          // Fill color of the circle
        fillOpacity: 1,             // Fill opacity of the circle
        radius: 3                   // Radius of the circle
      },
      intermedCircle: {               // Style settings for all circle markers between startCircle and endCircle
        color: '#000',              // Color of the border of the circle
        weight: 1,                  // Weight of the circle
        fillColor: '#ff0',          // Fill color of the circle
        fillOpacity: 1,             // Fill opacity of the circle
        radius: 3                   // Radius of the circle
      },
      currentCircle: {                // Style settings for circle marker indicating the latest point of the polyline during drawing a line
        color: '#000',              // Color of the border of the circle
        weight: 1,                  // Weight of the circle
        fillColor: '#f0f',          // Fill color of the circle
        fillOpacity: 1,             // Fill opacity of the circle
        radius: 3                   // Radius of the circle
      },
      endCircle: {                    // Style settings for circle marker indicating the last point of the polyline
        color: '#000',              // Color of the border of the circle
        weight: 1,                  // Weight of the circle
        fillColor: '#f00',          // Fill color of the circle
        fillOpacity: 1,             // Fill opacity of the circle
        radius: 3                   // Radius of the circle
      },
    };
  }

  function getCoordsForSend(_latlngs, type) {
    let latLngArray = [];
    let latLngCoords = [];
    if (type === 'POLYGON')
      _latlngs = _latlngs[0];

    if (type === 'MARKER') {
      return {
        coordx: _latlngs.lat,
        coordy: _latlngs.lng
      }
    }

    _latlngs.forEach(function (element) {
      latLngArray.push(element.lat + ":" + element.lng);
      latLngCoords.push([element.lat, element.lng]);
    });

    if (type === 'POLYLINE') {
      return {
        latLngStr: latLngArray.join(','),
        distance: Polylines.getDistance(_latlngs),
        latLngCoords: latLngCoords
      };
    }

    return {latLngStr: latLngArray.join(','), latLngCoords: latLngCoords};
  }

  function createControl() {

    let drawPluginOptions = {
      position: 'topright',
      draw: {
        polygon: {
          allowIntersection: false, // Restricts shapes to simple polygons
          drawError: {
            color: '#e1e100', // Color the shape will turn when intersects
          },
          shapeOptions: {
            color: '#97009c'
          }
        },
        // disable toolbar item by setting it to false
        polyline: {
          allowIntersection: false, // Restricts shapes to simple polygons
          drawError: {
            color: '#e1e100', // Color the shape will turn when intersects
          },
          shapeOptions: {
            color: '#97009c'
          }
        },
        circle: false, // Turns off this drawing tool
        rectangle: false,
        marker: {draggable: true},
      }
    };

    drawControl = new L.Control.Draw(drawPluginOptions);
    map.addControl(drawControl);

    jQuery('.leaflet-draw').hide();
  }

  function hasAddFunction(layer) {
    if (!layer)
      return 0;

    return (typeof (layer['add_func']) !== 'undefined' || layer['lang_name'] === _BUILD || layer['lang_name'] === _WIFI
      || layer['lang_name'] === _OBJECT || layer['lang_name'] === _BUILD + '2');
  }

  function removeDisabled(layer_id) {
    jQuery("#layer_" + layer_id).removeClass('disabled');
    jQuery("#disabled_layer_" + layer_id).hide();
  }

  function addDisabled(layer_id) {
    jQuery("#layer_" + layer_id).addClass('disabled');
    jQuery("#disabled_layer_" + layer_id).show().css('display', 'inline');
  }

  function createMenuButton(layer) {
    let buttonId = "layer_" + layer['id'];

    let navbar = jQuery('#navbar-button-container');
    let htmlElement = createButton(layer['lang_name'], buttonId);

    if (Configuration.hasAddFunction(layer)) {
      addBtnClick();
    } else {
      navbar.append(htmlElement);
    }
    jQuery("#disabled_layer_" + layer['id']).hide();

    jQuery('#' + buttonId).on("click", function () {
      if (AllLayers[buttonId] || (layer.sublayers && AllLayers[layer.sublayers[0]])) {
        successGetObject(layer);
        return;
      }

      Configuration.addDisabled(layer['id']);
      ObjectsConfiguration.getObjects(layer, errGetObject, successGetObject);
    });

    if (FORM['LAYER'] && FORM['LAYER'] === layer['id']) {
      Configuration.addDisabled(layer['id']);
      ObjectsConfiguration.getObjects(layer, errGetObject, successGetObject);
    } else if (LAYERS && LAYERS.includes(layer['id'])) {
      Configuration.addDisabled(layer['id']);
      ObjectsConfiguration.getObjects(layer, errGetObject, successGetObject);
    }

    function addBtnClick() {
      let addButtonId = "add_" + buttonId;
      htmlElement = createButtonWithAdd(layer['lang_name'], buttonId, addButtonId);

      navbar.append(htmlElement);
      jQuery('#' + addButtonId).on("click", function (e) {
        if (FORM['HIDE_ADD_BUTTONS'])
          return '';

        if (layer['structure'] !== undefined) {
          if (layer['structure'] === 'MARKER') {
            e.stopPropagation();
          }

          switch (layer['structure']) {
            case 'MARKER':
              Markers.drawMarker(layer);
              break;
            case 'POLYGON':
              Polygons.drawPolygon(layer);
              break;
            case 'POLYLINE':
              Polylines.drawPolyline(layer);
              break;
            default:
              console.log("Layer not found");
          }
        }
      });
    }

    function successGetObject(layer) {
      let layer_id = layer['id'];
      let buttonId = "layer_" + layer_id;
      let btn_element = jQuery('#' + buttonId);

      if (layer['multiple_update_function']) {
        map.off('areaselected');
        map.on('areaselected', e => {
          let selectedObjects = [];
          jQuery.each(Objects[layer_id], function(index, value) {
            if (!e.bounds.contains(value.getLatLng())) return;
            selectedObjects.push(index);
          });
          if (selectedObjects.length < 1) return;

          loadToModal(`index.cgi?get_index=${layer['multiple_update_function']}&header=2&IDS=${selectedObjects.join(';')}`);
        });
      }

      if (FORM['SMALL'] || btn_element.hasClass('btn_not_active')) {
        if (AllLayers[buttonId]) AllLayers[buttonId].addTo(map);

        if (layer.sublayers) {
          layer.sublayers.forEach(sublayer => {
            if (AllLayers[sublayer]) AllLayers[sublayer].addTo(map);
          });
        }

        if (Objects['ADD_CLASS'][layer_id]) {
          jQuery.each(Objects['ADD_CLASS'][layer_id], function (index, value) {
            jQuery(Objects[layer_id][index]._icon).addClass(value);
            delete Objects['ADD_CLASS'][layer_id][index];
          });
        }
        createSublayersTooltip(layer, btn_element);

        btn_element.addClass('btn_active');
        btn_element.removeClass('btn_not_active');
      }
      else {
        if (AllLayers[buttonId]) AllLayers[buttonId].remove();

        if (layer.sublayers) {
          layer.sublayers.forEach(sublayer => {
            if (AllLayers[sublayer]) AllLayers[sublayer].remove();
          });
        }

        btn_element.popover('hide');
        btn_element.popover('disable');

        btn_element.addClass('btn_not_active');
        btn_element.removeClass('btn_active');
      }
    }

    function errGetObject(layer_id) {
      displayJSONTooltip({MESSAGE: {caption: "Error. Layer not have objects.", message_type: 'err'}});
      jQuery("#layer_" + layer_id).addClass('disabled');
      jQuery("#disabled_layer_" + layer_id).hide();
    }

    function createButton(layer_name, id) {
      return "<div class='button_cont' id='button_" + id + "'>" + "<a class='btn_not_active btn_in_menu' id='" + id + "'>" +
        layer_name + "<i class='fas fa-circle-notch fa-spin spin-load' id='disabled_" + id + "'></i></a></div>";
    }

    function createButtonWithAdd(layer_name, id, add_id) {
      return "<div class='button_cont'>" + "<a class='btn_not_active btn_in_menu' id='" + id + "'>" +
        layer_name + "<i class='fas fa-circle-notch fa-spin spin-load' id='disabled_" + id + "'></i></a><button id='" +
        add_id + "' class='circle plus'></button></div>";
    }

    function createSublayersTooltip(layer, container) {
      if (!layer.sublayers) return;

      if (container.data('tooltip')) {
        container.popover('enable');
        container.popover('show');
        return;
      }

      container.attr('data-tooltip', 1);

      let content = '';
      layer.sublayers.forEach(sublayer => {
        if (!layer[sublayer]) return;

        let sublayer_info = layer[sublayer];
        let label = layer['tooltip_content'] ? layer['tooltip_content'] :
          '<label class="form-check-label">' + sublayer_info.name + '</label>';

        if (layer['tooltip_content'] ) {
          Object.keys(sublayer_info).forEach(key => {
            label = label.replace(new RegExp('%' + key + '%', "g"), sublayer_info[key]);
          });

          label = label.replace(/\\\"/g, '\"');
        }

        content += '<div class="form-group form-check mb-0">\n' +
          '<input type="checkbox" checked class="form-check-input" id="' + sublayer + '">\n' + label + '  </div>';
      });

      content += '<a class="close-button cursor-pointer" id="close_' + layer.id + '">×</a>'

      container.popover({
        container: 'body',
        html: true,
        placement: 'right',
        sanitize: false,
        content: content
      });

      jQuery(container).on('inserted.bs.popover', function () {
        jQuery('.popover').prependTo("#map");
        jQuery('#navbar-button-container').animate({scrollTop:  jQuery('#navbar-button-container').scrollTop() + 1});
      });

      jQuery(container).on('shown.bs.popover', function () {
        Array.from(document.getElementsByClassName('popover')).forEach((el) => {
          L.DomEvent.disableScrollPropagation(el);
          L.DomEvent.disableClickPropagation(el);
        });

        layer.sublayers.forEach(sublayer => {
          jQuery('#' + sublayer).on('change', function () {
            let sublayer_id = jQuery(this).prop('id');
            if (!AllLayers[sublayer_id]) return;

            if (jQuery(this).prop('checked')) {
              AllLayers[sublayer_id].addTo(map);
            }
            else {
              AllLayers[sublayer_id].remove();
            }
          })
        });

        jQuery('#close_' + layer.id).on('click', function() {
          container.popover('hide');
        });
      });
      container.popover('show');
    }
  }

  function panToUserPosition(position) {
    TempVariables['USER_COORDS'] = position.coords;
    let lat = position.coords.latitude;
    let lng = position.coords.longitude;
    let zoom = 12;

    map.setView([lat, lng], zoom);
  }

  function getCenterPointByPoints(points) {
    let x_point = 0;
    let y_point = 1;
    let x_points_sum = 0;
    let y_points_sum = 0;

    points.forEach(function (point) {
      x_points_sum += Number(point[x_point]);
      y_points_sum += Number(point[y_point]);
    });

    return [x_points_sum /= points.length, y_points_sum /= points.length];
  }

  function getDeleteButton(object, layer) {
    if (!Configuration.hasAddFunction(layer) && !object['POINT_ID'])
      return '';

    let data_point = 'data-point="' + object['POINT_ID'] + '"';
    let data_object = 'data-object="' + object['OBJECT_ID'] + '"';
    let data_layer = 'data-layer="' + layer['id'] + '"';
    let data_export_function = 'data-exportFunction="' + layer['export_function'] + '"';

    return '<button type="button" class="btn btn-sm btn-danger" onclick="ObjectsConfiguration.deleteObject(this)" ' + data_point + ' ' +
      data_object + ' ' + data_layer + ' ' + data_export_function + '>' + _DELETE + '</button>';
  }

  function onGoogleMaps() {
    if (!GOOGLE_API_KEY) return;

    putScriptInHead('google_api_script', 'https://maps.googleapis.com/maps/api/js?key=' + GOOGLE_API_KEY);
    return 1;
  }

  function onYandexMaps() {
    if (!YANDEX_API_KEY) return 0;

    putScriptInHead('yandex_api_script', 'https://api-maps.yandex.ru/2.1/?apikey=' + YANDEX_API_KEY + '&lang=ru_RU');
    return 1;
  }

  function changeIconSize(layer_id, objects, size) {
    if (Objects[layer_id]) {
      objects.forEach(function (element) {
        if (Objects[layer_id][element]) {
          var icon = Objects[layer_id][element].options.icon;
          icon.options.iconSize = [size, size];
          Objects[layer_id][element].setIcon(icon);
        }
      });
    }
  }

  function catCableToWell(object) {
    let id = object.cable_id || object.CABLE_ID;
    let layer_id = object.layer_id || object.LAYER_ID;
    let lng = window.lng;
    let lat = window.lat;

    if (!(layer_id && id && lng && lat)) {
      console.warn('No layer id, or id, or lng, or lat', layer_id, id, object, lng, lat);
      return false;
    }

    object.link += "&object_id=" + id + "&layer_id=" + layer_id + "&lng=" + lng + "&lat=" + lat;
    loadToModal(object.link, function () {
      map.closePopup();
      LayersConfiguration.refreshLayer(Layers[LAYER_ID_BY_NAME['CABLE']]);
      LayersConfiguration.refreshLayer(Layers[LAYER_ID_BY_NAME['CABLE']], object['object_id']);
      LayersConfiguration.refreshLayer(Layers[LAYER_ID_BY_NAME['WELL']]);
    });
  }

  function addAnotherWell(url, point_id) {
    mainLocation.askCustomMarker(0, 0, url, function () {
      LayersConfiguration.refreshLayer(Layers[LAYER_ID_BY_NAME['WELL']], point_id);
    }, point_id);
  }

  function sendFetch(url, err_callback, success_callback) {
    fetch(url)
      .then(response => {
        if (!response.ok) {
          throw response
        }
        if (success_callback)
          success_callback();
      })
      .catch(err => {
        console.log(err);
        if (err_callback)
          err_callback();
      });
  }

  function fitByObject(object) {
    if (object['POINTS'].length < 2)
      return 0;

    let farthest_point = {
      index: 0,
      distance: 0
    };

    jQuery.each(object['POINTS'], function (index, value) {
      let distance = Polylines.getDistance([object['POINTS'][0], value], 1);
      if (distance > farthest_point.distance) {
        farthest_point.index = index;
        farthest_point.distance = distance;
      }
    });

    let first_bound = new L.LatLng(object['POINTS'][0][0], object['POINTS'][0][1]);
    let second_bound = new L.LatLng(object['POINTS'][farthest_point.index][0], object['POINTS'][farthest_point.index][1]);

    let bounds = new L.LatLngBounds(first_bound, second_bound);
    map.fitBounds(bounds);
  }

  function fitByPoints(points, object) {
    if (points.length < 2)
      return '';

    let first_bound = new L.LatLng(points[0][0], points[0][1]);
    let second_bound = new L.LatLng(points[points.length - 1][0], points[points.length - 1][1]);

    let bounds = new L.LatLngBounds(first_bound, second_bound);
    map.fitBounds(bounds);

    if (object['layer_id'] && object['object_id']) {
      setTimeout(function () {
        Objects[object.layer_id][object.object_id].openPopup();
      }, 500);
    }
  }

  return {
    getLocation: getLocation,
    getOptions: getOptions,
    getCoordsForSend: getCoordsForSend,
    createControl: createControl,
    hasAddFunction: hasAddFunction,
    removeDisabled: removeDisabled,
    addDisabled: addDisabled,
    createMenuButton: createMenuButton,
    panToUserPosition: panToUserPosition,
    getCenterPointByPoints: getCenterPointByPoints,
    getDeleteButton: getDeleteButton,
    onGoogleMaps: onGoogleMaps,
    onYandexMaps: onYandexMaps,
    changeIconSize: changeIconSize,
    catCableToWell: catCableToWell,
    addAnotherWell: addAnotherWell,
    sendFetch: sendFetch,
    fitByPoints: fitByPoints,
    fitByObject: fitByObject
  }
})();

var ObjectsConfiguration = (function () {
  function addCustomObject(layer) {
    if (layer['structure'] === 'MARKER') {
      Markers.drawMarker(layer);
    }
    if (layer['structure'] === 'POLYLINE') {
      Polylines.drawPolyline(layer);
    }
  }

  function showCustomObjects() {
    if (!FORM['OBJECT_TO_SHOW'] || FORM['OBJECT_TO_SHOW'].length < 1)
      return 0;

    if (FORM['BUILD_ROUTE']) {
      let getPosition = function (options) {
        return new Promise(function (resolve, reject) {
          navigator.geolocation.getCurrentPosition(resolve, reject, options);
        });
      };

      getPosition()
          .then((position) => {
            Configuration.panToUserPosition(position);
            ObjectsConfiguration.showObjectToShow();
          })
          .catch((err) => {
            console.error(err.message);
          });
    }
    else {
      ObjectsConfiguration.showObjectToShow();
    }

    return 1;
  }

  function showObjectToShow() {
    let closest_object = null;

    let markers = FORM['OBJECT_TO_SHOW'].length > 1000 ? L.markerClusterGroup({
      spiderfyOnMaxZoom: 0,
      disableClusteringAtZoom: map._layersMaxZoom
    }) : new L.layerGroup();

    jQuery.each(FORM['OBJECT_TO_SHOW'], function (index, value) {
      if (value['MARKER']) {
        markers.addLayer(Markers.createMarker(value['MARKER']));
        if (FORM['OBJECT_TO_SHOW'].length === 1)
          map.setView([value['MARKER']['COORDX'], value['MARKER']['COORDY']], 18);
        closest_object = ObjectsConfiguration.getClosestObject(closest_object, value['MARKER']);
      }
      if (value['POLYGON']) {

        if (!value['POLYGON']['POINTS'] || value['POLYGON']['POINTS'].length < 1)
          return 0;

        Polygons.createPolygon(value['POLYGON']).addTo(map);
        if (FORM['OBJECT_TO_SHOW'].length === 1)
          Configuration.fitByObject(value['POLYGON']);
      }
    });

    if (markers) markers.addTo(map);

    if (closest_object && FORM['BUILD_ROUTE'])
      Routes.showRouteBetweenPoints(closest_object);

    if (FORM['OBJECT_TO_SHOW'].length > 1 && !FORM['BUILD_ROUTE']) {
      if (FORM['OBJECT_TO_SHOW'][0]['POLYGON'])
        Configuration.fitByObject(FORM['OBJECT_TO_SHOW'][0]['POLYGON']);
      else if (FORM['OBJECT_TO_SHOW'][0]['MARKER'])
        map.setView([FORM['OBJECT_TO_SHOW'][0]['MARKER']['COORDX'], FORM['OBJECT_TO_SHOW'][0]['MARKER']['COORDY']], 18);
    }
  }

  function getObjects(layer, err_callback, success_callback, object_id = 0,ext_url = '') {
    if (!layer['export_function']) return {};
    if (FORM['CLEAR_LAYERS'] && AllLayers['layer_' + layer['id']]) AllLayers['layer_' + layer['id']] = undefined;

    let url = `${selfUrl}?header=2&get_index=maps2_get_objects&EXPORT_LIST=1&RETURN_JSON=1&MODULE=` +
      `${layer['module']}&FUNCTION=${layer['export_function']}`;

    if (FORM['OBJECT_ID'] && (!FORM['LAYER'] || FORM['LAYER'] === layer['id']))
      url += `&OBJECT_ID=${FORM['OBJECT_ID']}`;
    else if (object_id !== 0)
      url += `&OBJECT_ID=${object_id}`;

    url += ext_url;

    fetch(url)
      .then(function (response) {
        if (!response.ok)
          throw Error(response.statusText);

        return response;
      })
      .then(function (response) {
        return response.json();
      })
      .then(result => async function (result) {
        ObjectsConfiguration.showObject(layer, result, err_callback, success_callback);
      }(result))
      .catch(function (error) {
        console.log(error);
        if (err_callback)
          err_callback(layer['id']);
      });
  }

  function showObject(layer, objects, err_callback, success_callback) {

    if (objects.length < 1) {
      if (FORM['ADD_POINT']) ObjectsConfiguration.addCustomObject(layer);
      else if (err_callback) err_callback(layer['id']);
    }

    if (layer.filter) {
      showFiltersMarkerObjects(layer, objects);
    }
    else if (objects[0] && objects[0]['MARKER']) {
      showMarkerObjects(layer, objects);
    }
    else if (objects[0] && objects[0]['POLYLINE']) {
      showPolylineObjects(layer, objects);
    }
    else if (objects[0] && objects[0]['POLYGON']) {
      showPolygonObjects(layer, objects);
    }
    else if (objects[0] && objects[0]['SEMICIRCLE']) {
      showSemicircleObjects(layer, objects);
    }

    if (success_callback)
      success_callback(layer);

    let items = [];
    for (let i = 0; i < ObjectsName.length; i++) {
      items.push({id: i, text: ObjectsName[i]})
    }

    fillSearchSelect(items, 50);

    Configuration.removeDisabled(layer['id']);
  }

  function showFiltersMarkerObjects(layer, objects) {
    let filter = layer.filter;
    jQuery.each(objects, function (index, object) {
      let filter_items = object[filter];
      if (!filter_items) return;

      filter_items.forEach(item => {
        let filter_name = 'layer_' + layer['id'].toString() + '_filter_' + item.id;
        if (!AllLayers[filter_name]) {
          AllLayers[filter_name] = new L.FeatureGroup();
          layer['sublayers'].push(filter_name);
          layer[filter_name] = item;
        }

        AllLayers[filter_name].addLayer(Markers.createMarker(object['MARKER'], layer));
      });
    })
  }

  function showMarkerObjects(layer, objects) {
    if (!AllLayers['layer_' + layer['id'].toString()])
      AllLayers['layer_' + layer['id'].toString()] = objects.length > 1000 ? L.markerClusterGroup({
        spiderfyOnMaxZoom: 0,
        disableClusteringAtZoom: map._layersMaxZoom
      }) : new L.layerGroup();

    let closest_object = null;
    jQuery.each(objects, function (index, object) {
      AllLayers['layer_' + layer['id'].toString()].addLayer(Markers.createMarker(object['MARKER'], layer));

      closest_object = ObjectsConfiguration.getClosestObject(closest_object, object['MARKER']);
    });

    if (closest_object && FORM['BUILD_ROUTE'])
      Routes.showRouteBetweenPoints(closest_object);

    if (FORM['OBJECT_ID'])
      map.setView([objects[0]['MARKER']['COORDX'], objects[0]['MARKER']['COORDY']], 18);
  }

  function showPolylineObjects(layer, objects) {
    if (!AllLayers['layer_' + layer['id'].toString()])
      AllLayers['layer_' + layer['id'].toString()] = new L.FeatureGroup();

    jQuery.each(objects, function (index) {
      if (objects[index]['POLYLINE']['POINTS'].length > 1) {
        AllLayers['layer_' + layer['id'].toString()].addLayer(Polylines.createPolyline(objects[index]['POLYLINE'], layer));
      }
    });

    if (FORM['OBJECT_ID'] && !FORM['ADD_POINT'])
      Configuration.fitByPoints(objects[0]['POLYLINE']['POINTS'], {
        layer_id: layer['id'],
        object_id: FORM['OBJECT_ID']
      });
  }

  function showPolygonObjects(layer, objects) {
    if (!AllLayers['layer_' + layer['id'].toString()])
      AllLayers['layer_' + layer['id'].toString()] = new L.FeatureGroup();

    jQuery.each(objects, function (index) {
      if (objects[index]['POLYGON']['POINTS'].length > 1) {
        AllLayers['layer_' + layer['id'].toString()].addLayer(Polygons.createPolygon(objects[index]['POLYGON'], layer));
      }
    });

    if (FORM['OBJECT_ID'])
      Configuration.fitByObject(objects[0]['POLYGON']);
  }

  function showSemicircleObjects(layer, objects) {
    if (!AllLayers['layer_' + layer['id'].toString()])
      AllLayers['layer_' + layer['id'].toString()] = new L.FeatureGroup();

    jQuery.each(objects, function (index, value) {
      let startAngel = value['SEMICIRCLE']['LOCATION_ANGEL'] - value['SEMICIRCLE']['ANGEL'] / 2;
      let endAngel = value['SEMICIRCLE']['LOCATION_ANGEL'] + value['SEMICIRCLE']['ANGEL'] / 2;

      let semiCircle = L.semiCircle([value['SEMICIRCLE']['COORDX'], value['SEMICIRCLE']['COORDY']], {
        radius: value['SEMICIRCLE']['LENGTH'],
        startAngle: startAngel,
        stopAngle: endAngel
      });
      AllLayers['layer_' + layer['id'].toString()].addLayer(semiCircle);
    });
  }

  function deleteObject(object) {
    let dataset = object['dataset'];

    mainLocation.delLocation(dataset, function () {
      AllLayers['layer_' + dataset['layer']].removeLayer(Objects[dataset['layer']][dataset['object']]);

      delete Objects[dataset['layer']][dataset['object']];
    });
  }

  function setObjectInArray(layer_id, object_id, content, object) {
    if (!Objects[layer_id])
      Objects[layer_id] = {};

    if (! Objects['ADD_CLASS'][layer_id])
      Objects['ADD_CLASS'][layer_id] = {};

    Objects[layer_id][object_id] = content;

    if (object['ADD_CLASS'])
      Objects['ADD_CLASS'][layer_id][object_id] = object['ADD_CLASS'];

    if (!object['NAME'])
      return;

    ObjectsName.push(Layers[layer_id]['lang_name'] + ':' + object['NAME']);
    ObjectsById.push(object);
  }

  function panToObject(layer_id, object_id) {
    if (!Objects[layer_id][object_id] || !Objects[layer_id][object_id]['_latlng'])
      return 0;

    map.setView(Objects[layer_id][object_id]['_latlng'], 18);
    setTimeout(function () {
      Objects[layer_id][object_id].openPopup();
    }, 500);
  }

  function getClosestObject(object, newObject) {
    if (!TempVariables['USER_COORDS'])
      return null;

    if (!object)
      return newObject;

    let newObjectDistance = Polylines.getDistance([[TempVariables['USER_COORDS'].latitude, TempVariables['USER_COORDS'].longitude],
      [newObject['COORDX'], newObject['COORDY']]], 1);

    let oldObjectDistance = Polylines.getDistance([[TempVariables['USER_COORDS'].latitude, TempVariables['USER_COORDS'].longitude],
      [object['COORDX'], object['COORDY']]], 1);

    return newObjectDistance < oldObjectDistance ? newObject : object;
  }

  return {
    addCustomObject: addCustomObject,
    showCustomObjects: showCustomObjects,
    getObjects: getObjects,
    showObject: showObject,
    deleteObject: deleteObject,
    setObjectInArray: setObjectInArray,
    panToObject: panToObject,
    getClosestObject: getClosestObject,
    showObjectToShow: showObjectToShow
  }
})();

var LayersConfiguration = (function () {
  function showLayers(layers) {
    jQuery.each(layers.sort((a, b) => (a.module > b.module) ? 0 : ((b.module > a.module) ? -1 : 1)), function (index) {
      Layers[layers[index].id] = layers[index];
      Configuration.createMenuButton(layers[index]);
    });

    defineTooltipLogic(jQuery('#navbar-container'));
  }

  function refreshLayer(layer, point_id) {
    if (point_id && AllLayers['layer_' + layer.id] && Objects[layer.id][point_id]) {
      AllLayers['layer_' + layer.id].removeLayer(Objects[layer.id][point_id]);
    }

    ObjectsConfiguration.getObjects(layer, undefined, undefined, point_id, '&NEW_OBJECT=1');
  }

  function setLayerVisible(layer, id) {
    let btn_element = jQuery('#' + id);
    if (!layer) {
      btn_element.click();
      return;
    }

    layer.addTo(map);
    btn_element.addClass('btn_active');
    btn_element.removeClass('btn_not_active');
    btn_element.removeClass('disabled');
  }

  return {
    showLayers: showLayers,
    refreshLayer: refreshLayer,
    setLayerVisible: setLayerVisible
  }
})();

var Builds = (function () {
  function addNewBuildMarker(lat, lng, location_id) {
    let layer_index = 'layer_1';
    if (!AllLayers[layer_index]) {
      AllLayers[layer_index] = new L.markerClusterGroup({
        spiderfyOnMaxZoom: 0,
        disableClusteringAtZoom: map._layersMaxZoom
      });
    }
    LayersConfiguration.setLayerVisible(AllLayers[layer_index], layer_index);

    mainLocation.askLocation(function (locationC) {
      if (locationC.newNumber) {
        let link = aBillingAddressManager.addMarker(locationC.streetId, locationC.newNumber, lat, lng);
        loadToModal(link, function () {
          LayersConfiguration.refreshLayer(Layers[LAYER_ID_BY_NAME['BUILD']]);
        });
      } else {
        let location = location_id || locationC.getLocationId();
        let link = aBillingAddressManager.registerBuild(location, lat, lng);
        loadToModal(link, function () {
          LayersConfiguration.refreshLayer(Layers[LAYER_ID_BY_NAME['BUILD']], location);
        });
      }
    });
  }

  function addNewBuildPolygon(coords) {
    let layer_index = 'layer_12';
    if (!AllLayers[layer_index]) {
      AllLayers[layer_index] = new L.layerGroup();
    }
    LayersConfiguration.setLayerVisible(AllLayers[layer_index], layer_index);

    mainLocation.askLocation(function (locationC, modal) {
      let link = '';

      if (locationC.newNumber) {
        link = aBillingAddressManager.addPolygon(locationC.streetId, locationC.newNumber);
      } else {
        link = aBillingAddressManager.registerBuildPolygon(locationC.getLocationId());
      }

      modal.hide();
      link += '&coords=' + coords['latLngStr'];
      Builds.addBuildAjax(link, function () {
        LayersConfiguration.refreshLayer(Layers[LAYER_ID_BY_NAME['BUILD2']]);
      });

    });
  }

  function addBuildAjax(link, callback) {
    jQuery.ajax({
      url: '/admin/index.cgi',
      type: 'POST',
      data: link,
      contentType: false,
      cache: false,
      processData: false,
      success: function (result) {
        let message_type = result === 'Error' ? 'err' : 'info';

        if (result !== 'Error' && callback) {
          callback();
        }

        displayJSONTooltip({MESSAGE: {caption: result, message_type: message_type}});
      },
      fail: function (error) {
        aTooltip.displayError(error);
      },
      complete: function () {
      }
    });
  }

  return {
    addNewBuildMarker: addNewBuildMarker,
    addNewBuildPolygon: addNewBuildPolygon,
    addBuildAjax: addBuildAjax
  }
})();

var Markers = (function () {
  function addNewMarker(layer, lat, lng, layer_index) {
    if (!AllLayers[layer_index]) {
      AllLayers[layer_index] = new L.markerClusterGroup({
        spiderfyOnMaxZoom: 0,
        disableClusteringAtZoom: map._layersMaxZoom
      });
    }
    LayersConfiguration.setLayerVisible(AllLayers[layer_index], layer_index);

    if (!FORM['ADD_POINT'] || !FORM['OBJECT_ID']) {
      let link = 'index.cgi?get_index=' + layer['add_func'] + '&header=2&add_form=1&TEMPLATE_ONLY=1&IN_MODAL=1&OBJECT_TYPE_ID=1&ADD_OBJECT=1';
      mainLocation.askCustomMarker(lat, lng, link, function () {
        LayersConfiguration.refreshLayer(Layers[layer['id']]);
      });
      return;
    }

    if (layer['id'] === LAYER_ID_BY_NAME['BUILD']) {
      let url = aBillingAddressManager.registerBuild(FORM['OBJECT_ID'], lat, lng);
      Configuration.sendFetch(url, null, function () {
        delete FORM['ADD_POINT'];
        delete FORM['OBJECT_ID'];
        LayersConfiguration.refreshLayer(Layers[layer['id']]);
      });
    } else {
      let add_func = layer['add_func'] || 'maps2_add_external_points';
      let url = 'index.cgi?get_index=' + add_func + '&header=2&add=1&ADD_EXIST_OBJECT=1&COORDX=' +
        lat + '&COORDY=' + lng + '&POINT_ID=' + FORM['OBJECT_ID'];
      Configuration.sendFetch(url, null, function () {
        delete FORM['ADD_POINT'];
        delete FORM['OBJECT_ID'];
        LayersConfiguration.refreshLayer(Layers[layer['id']]);
      });
    }
  }

  function createMarker(marker, layer) {
    let greenIcon = undefined;
    let infoPopup = marker['INFO'] || marker['INFOWINDOW'] || "";

    if (!marker['DISABLE_EDIT'] && !FORM['HIDE_EDIT_BUTTONS']) {
      infoPopup += Configuration.getDeleteButton(marker, layer);

      let change_button = "onclick='ChangeElement.changeElement({ layer_id :" + marker['LAYER_ID'] + ", object_id :"
        + marker['OBJECT_ID'] + "})'";
      infoPopup += " <button class='btn btn-sm btn-danger'" + change_button + ">" + _CHANGE + "</button>";
    }

    let return_marker;
    if (marker['TYPE']) {

      greenIcon = new LeafIcon({
        iconUrl: marker['FULL_TYPE_URL'] ? marker['TYPE'] : '/images/maps/icons/' + marker['TYPE'] + '.png'
      });

      return_marker = L.marker([marker['COORDX'], marker['COORDY']], {icon: greenIcon, highlight: 'temporary'});

      if (infoPopup)
        return_marker.bindPopup(infoPopup, {maxWidth: 400});

      if (marker['NAME'])
        return_marker.bindTooltip(marker['NAME'], {
          permanent: false
        });
    }
    else if (marker['SVG']) {
      let svg_icon = L.divIcon({
        className: "leaflet-data-marker",
        html: L.Util.template(marker['SVG']), //.replace('#','%23'),
        iconSize: [23, 23],
        iconAnchor: [12, 12],
        popupAnchor: [-10, -2]
      });

      return_marker = L.marker([marker['COORDX'], marker['COORDY']], {icon: svg_icon});

      if (infoPopup)
        return_marker.bindPopup(infoPopup, {maxWidth: 400});

      if (marker['NAME'])
        return_marker.bindTooltip(marker['NAME'], {
          permanent: false
        });
    }
    else {
      return_marker = L.marker([marker['COORDX'], marker['COORDY']], {icon: greenIcon});
      if (infoPopup)
        return_marker.bindPopup(infoPopup, {maxWidth: 400});

      if (marker['NAME'])
        return_marker.bindTooltip(marker['NAME'], {
          permanent: false
        });
    }

    if (marker['OBJECT_ID'] && layer)
      ObjectsConfiguration.setObjectInArray(layer['id'], marker['OBJECT_ID'], return_marker, marker);

    return return_marker;
  }

  function drawMarker(layer) {
    map.off(L.Draw.Event.CREATED);
    map.on(L.Draw.Event.CREATED, function (e) {
      let location_id = FORM['ADD_POINT'] || FORM['OBJECT_ID'] ? FORM['OBJECT_ID'] : undefined;
      let lat = e['layer']['_latlng']['lat'];
      let lng = e['layer']['_latlng']['lng'];

      if (!layer) return;

      if (layer['id'] == '1') {
        if (!FORM['ADD_POINT']) Builds.addNewBuildMarker(lat, lng, location_id);
        else {
          loadToModal(aBillingAddressManager.registerBuild(location_id, lat, lng), function () {
            LayersConfiguration.refreshLayer(Layers[LAYER_ID_BY_NAME['BUILD']]);
          });
        }
        return;
      }

      Markers.addNewMarker(layer, lat, lng, 'layer_' + layer['id']);
    });

    new L.Draw.Marker(map, drawControl.options.draw.marker).enable();
  }

  return {
    addNewMarker: addNewMarker,
    createMarker: createMarker,
    drawMarker: drawMarker
  }
})();

var Polylines = (function () {
  function addNewPolyline(layer, coords, layer_index) {
    if (!AllLayers[layer_index]) {
      AllLayers[layer_index] = new L.layerGroup();
    }
    LayersConfiguration.setLayerVisible(AllLayers[layer_index], layer_index);

    if (FORM['ADD_POINT'] && FORM['LAYER'] && FORM['LAYER'] === layer.id) {
      let object_id = FORM['OBJECT_ID'];
      let link = 'index.cgi?qindex=' + index + '&OBJECT_ID=' + object_id + '&change_coords=1&header=2&add_form=1&ADD_NEW=1' +
        '&TEMPLATE_ONLY=1&LAYER_ID=' + layer.id + '&TYPE=' + Layers[layer.id]['structure'] + '&coords=' + layer['latLngStr'];

      delete FORM['ADD_POINT'];
      delete FORM['OBJECT_ID'];

      Configuration.sendFetch(link, null, function () {
        ObjectsConfiguration.getObjects(Layers[layer.id], null, null, object_id);
      });

      return;
    }
    let link = 'index.cgi?get_index=' + layer['add_func'] + '&header=2&add_form=1&TEMPLATE_ONLY=1&IN_MODAL=1';
    link += '&first_coords=' + coords[0].join(':') + '&second_coords=' + coords[coords.length - 1].join(':');
    if (layer['distance'])
      link += '&LENGTH_CALCULATED=' + layer['distance'];

    mainLocation.askCustomPolyline(layer['latLngStr'], link, function () {
      LayersConfiguration.refreshLayer(Layers[layer.id]);
    });
  }

  function getDistance(_latlngs, points) {
    let previousPoint;
    let totalSum = 0;

    if (points) {
      _latlngs.forEach(function (element) {
        if (previousPoint) {
          totalSum += previousPoint.distanceTo(L.latLng(element[0], element[1]));
        }
        previousPoint = L.latLng(element[0], element[1]);
      });

      return Math.round(totalSum * 100) / 100;
    }

    _latlngs.forEach(function (element) {
      if (previousPoint) {
        totalSum += previousPoint.distanceTo(element);
      }
      previousPoint = element;
    });

    return Math.round(totalSum * 100) / 100;
  }

  function createPolyline(polyline, layer) {
    let infoPopup = polyline['INFO'] || polyline['INFOWINDOW'] || "";
    infoPopup += Configuration.getDeleteButton(polyline, layer);
    polyline['NAME'] = polyline['NAME'] || polyline['name'];

    if (polyline['ADD_WELL_LINK']) {
      let add_click = "onclick='Configuration.catCableToWell({ layer_id :" + polyline['LAYER_ID'] + ", cable_id :" + polyline['CABLE_ID'] +
        ", link :\"" + polyline['ADD_WELL_LINK'] + "\"" + ", object_id :\"" + polyline['OBJECT_ID'] + "\"})'";
      infoPopup += " <button class='btn btn-sm btn-danger'" + add_click + ">" + polyline['CABLE_CAT'] + "</button>";

      let change_button = "onclick='ChangeElement.changeElement({ layer_id :" + polyline['LAYER_ID'] + ", object_id :"
        + polyline['OBJECT_ID'] + "})'";
      infoPopup += " <button class='btn btn-sm btn-danger'" + change_button + ">" + _CHANGE + "</button>";
    }

    let color = polyline['STROKECOLOR'] || 'red';
    let return_polyline = infoPopup ? L.polyline(polyline['POINTS'],
      {color: color, opacity: polyline['OPACITY'] || 1}).bindPopup(infoPopup) :
      L.polyline(polyline['POINTS'], {color: color, opacity: polyline['OPACITY'] || 1, maxWidth: 400});

    if (polyline['NAME']) {
      let distance = Polylines.getDistance(polyline['POINTS'], 1) + "m.";
      return_polyline.bindTooltip(polyline['NAME'] + ": " + distance.fontcolor(color), {
        permanent: false
      });
    }

    return_polyline.on('mouseover', function (e) {
      if (e.latlng) {
        window.lat = e.latlng.lat;
        window.lng = e.latlng.lng;
      }

      if (polyline['REFERENCE_OBJECTS'] && polyline['REFERENCE_OBJECTS']['LAYER_ID'] && polyline['REFERENCE_OBJECTS']['OBJECTS']) {
        let layer_id = polyline['REFERENCE_OBJECTS']['LAYER_ID'];
        let objects = polyline['REFERENCE_OBJECTS']['OBJECTS'];
        Configuration.changeIconSize(layer_id, objects, 25);
      }
      this.mySavedWeight = this.options.weight;
      this.setStyle({
        weight: 5
      });
    });

    return_polyline.on('mouseout', function () {
      if (polyline['REFERENCE_OBJECTS'] && polyline['REFERENCE_OBJECTS']['LAYER_ID'] && polyline['REFERENCE_OBJECTS']['OBJECTS']) {
        let layer_id = polyline['REFERENCE_OBJECTS']['LAYER_ID'];
        let objects = polyline['REFERENCE_OBJECTS']['OBJECTS'];
        Configuration.changeIconSize(layer_id, objects, 23);
      }
      this.setStyle({
        weight: this.mySavedWeight
      });
    });

    if (polyline['OBJECT_ID'] && layer)
      ObjectsConfiguration.setObjectInArray(layer['id'], polyline['OBJECT_ID'], return_polyline, polyline);

    return return_polyline;
  }

  function drawPolyline(layer) {

    map.off(L.Draw.Event.CREATED);
    map.on(L.Draw.Event.CREATED, function (e) {

      let result = Configuration.getCoordsForSend(e.layer._latlngs, 'POLYLINE');

      layer['latLngStr'] = result['latLngStr'];
      layer['distance'] = result['distance'];

      Polylines.addNewPolyline(layer, result['latLngCoords'], 'layer_' + layer['id']);
    });

    new L.Draw.Polyline(map, drawControl.options.draw.polyline).enable();
  }

  return {
    addNewPolyline: addNewPolyline,
    getDistance: getDistance,
    createPolyline: createPolyline,
    drawPolyline: drawPolyline
  }
})();

var Polygons = (function () {
  function addNewPolygon(layer, coords, layer_index) {
    if (!AllLayers[layer_index]) {
      AllLayers[layer_index] = new L.layerGroup();
    }
    LayersConfiguration.setLayerVisible(AllLayers[layer_index], layer_index);

    if (layer['lang_name'] === _WIFI) {
      mainLocation.askWiFi(function (name, color, modal) {
        let link = aBillingAddressManager.addWifi(name, color);
        link += '&coords=' + layer['latLngStr'];
        Builds.addBuildAjax(link, function () {
          LayersConfiguration.refreshLayer(Layers[layer['id']]);
          modal.hide();
        })
      });
    } else {
      let link = 'index.cgi?get_index=' + layer['add_func'] + '&header=2&add_form=1&TEMPLATE_ONLY=1&IN_MODAL=1';

      mainLocation.askCustomPolygon(layer['latLngStr'], link, function () {
        LayersConfiguration.refreshLayer(Layers[layer['id']]);
      });
    }
  }

  function createPolygon(polygon, layer) {
    let infoPopup = polygon['INFO'] || polygon['INFOWINDOW'] || "";

    if (!FORM['HIDE_EDIT_BUTTONS']) {
      if (layer)
        infoPopup += Configuration.getDeleteButton(polygon, layer);

      let change_button = "onclick='ChangeElement.changeElement({ layer_id :" + polygon['LAYER_ID'] + ", object_id :"
        + polygon['OBJECT_ID'] + "})'";
      infoPopup += " <button class='btn btn-sm btn-danger'" + change_button + ">" + _CHANGE + "</button>";
    }

    polygon['NAME'] = polygon['NAME'] || polygon['name'];

    polygon['COLOR'] = polygon['COLOR'] || 'grey';
    let return_polygon = infoPopup ? L.polygon(polygon['POINTS'], {color: polygon['COLOR']}).bindPopup(infoPopup, {maxWidth: 400}) :
      L.polygon(polygon['POINTS'], {color: polygon['COLOR']});

    let return_polyton = polygon['NAME'] ? return_polygon.bindTooltip(polygon['NAME'], {permanent: false}) : return_polygon;

    if (polygon['OBJECT_ID'] && layer)
      ObjectsConfiguration.setObjectInArray(layer['id'], polygon['OBJECT_ID'], return_polyton, polygon);

    return return_polyton;
  }

  function drawPolygon(layer) {

    map.off(L.Draw.Event.CREATED);
    map.on(L.Draw.Event.CREATED, function (e) {

      let result = Configuration.getCoordsForSend(e.layer._latlngs, 'POLYGON');
      if (layer['id'] == '12')
        Builds.addNewBuildPolygon(result);
      else {
        layer['latLngStr'] = result['latLngStr'];

        Polygons.addNewPolygon(layer, result['latLngCoords'], 'layer_' + layer['id']);
      }
    });

    new L.Draw.Polygon(map, drawControl.options.draw.polygon).enable();
  }

  return {
    addNewPolygon: addNewPolygon,
    createPolygon: createPolygon,
    drawPolygon: drawPolygon
  }
})();

var ChangeElement = (function () {

  let newElement = undefined;
  let elementEditor = undefined;

  function changeElement(object) {
    if (TempVariables['EDITED'] !== undefined) {
      displayJSONTooltip({
        MESSAGE: {
          caption: _ERROR,
          message_type: 'err',
          messaga: _COMPLETE_PREVIOUS_CHANGE
        }
      });
      return;
    }

    TempVariables['EDITED'] = 1;
    newElement = new L.FeatureGroup();

    if (Layers[object.layer_id]['structure'] === 'POLYGON')
      AllLayers['layer_' + object.layer_id].removeLayer(Objects[object.layer_id][object.object_id]);

    let saveBtn = "<button class=\'btn btn-sm btn-success\' onClick=\'ChangeElement.saveElement({object_id:" +
      object.object_id + ", layer_id: " + object.layer_id + "})\'>" + _SAVE + "</button>";
    let cancelBtn = "<button class=\'btn btn-sm btn-danger\' onClick=\'ChangeElement.cancelElement({object_id:" +
      object.object_id + ", layer_id: " + object.layer_id + "})\'>" + _CANCEL + "</button>";
    Objects[object.layer_id][object.object_id].bindPopup(saveBtn + ' ' + cancelBtn, {maxWidth: 400});
    newElement.addLayer(Objects[object.layer_id][object.object_id]).addTo(map);

    elementEditor = new L.EditToolbar.Edit(map, {
      featureGroup: newElement
    });
    elementEditor.enable();
    map.closePopup();
  }

  function saveElement(object) {
    map.off(L.Draw.Event.EDITED);
    map.on(L.Draw.Event.EDITED, function (e) {
      TempVariables['EDITED'] = undefined;
      if (elementEditor === undefined)
        return;

      map.closePopup();
      let result = {};
      jQuery.each(e.layers._layers, function (index, value) {
        if (result['latLngStr'])
          return;

        if (value['_latlngs'] || value['_latlng']) {
          result = Configuration.getCoordsForSend(value['_latlngs'] || value['_latlng'], Layers[object.layer_id]['structure']);
        }
      });
      if (!result['latLngStr'] && Layers[object.layer_id]['structure'] !== 'MARKER') {
        ChangeElement.cancelElement(object);
        return;
      } else if (!result['coordx'] && Layers[object.layer_id]['structure'] === 'MARKER') {
        ChangeElement.cancelElement(object);
        return;
      }

      let link = 'index.cgi?qindex=' + index + '&OBJECT_ID=' + object.object_id + '&change_coords=1&header=2&add_form=1' +
        '&TEMPLATE_ONLY=1&LAYER_ID=' + object.layer_id + '&TYPE=' + Layers[object.layer_id]['structure'];

      if (result['latLngStr'])
        link += '&coords=' + result['latLngStr'];
      else if (result['coordx']) {
        link += '&coordx=' + result['coordx'] + '&coordy=' + result['coordy'];
      }

      if (result['distance'])
        link += '&LENGTH_CALCULATED=' + result['distance'];

      let oldPolyline = Objects[object.layer_id][object.object_id];
      Configuration.sendFetch(link, null, function () {
        elementEditor.disable();
        ObjectsConfiguration.getObjects(Layers[object.layer_id], null, function () {
          AllLayers['layer_' + object.layer_id].removeLayer(oldPolyline);
          map.removeLayer(newElement);
        }, object.object_id);
      });
    });
    elementEditor.save();
  }

  function cancelElement(object) {
    TempVariables['EDITED'] = undefined;
    if (elementEditor === undefined)
      return;

    elementEditor.disable();
    map.closePopup();
    let oldPolyline = Objects[object.layer_id][object.object_id];
    ObjectsConfiguration.getObjects(Layers[object.layer_id], null, function () {
      AllLayers['layer_' + object.layer_id].removeLayer(oldPolyline);
      map.removeLayer(newElement);
    }, object.object_id);
  }

  return {
    changeElement: changeElement,
    saveElement: saveElement,
    cancelElement: cancelElement
  }
})();

var Routes = (function () {
  var closeControlBtn;
  function showRouteFromONUtoOLT(button, link) {

    if (jQuery(button).hasClass('fa-spinner')) return;

    if (!AllLayers['layer_10']) LayersConfiguration.setLayerVisible(undefined, 'layer_10');

    jQuery(button).find('span').removeClass('fa-eye');
    jQuery(button).find('span').addClass('fa-spinner fa-spin');

    jQuery.ajax({
      url: link + '&RETURN_JSON=1',
      type: 'GET',
      contentType: false,
      cache: false,
      processData: false,
      success: function (result) {
        _removeTrace();
        let data = JSON.parse(result);
        if (_showError(data, button)) return;

        L.control.sidebar({
          autopan: false,
          closeButton: true,
          container: 'sidebar',
          position: 'right',
        }).addTo(map);

        closeControlBtn = createCloseTraceBtn();
        map.addControl(closeControlBtn);

        jQuery('#leaflet-sidebar-body').html('')
        drawRouteFromOltToUser(data, button).forEach(e => {
          jQuery('#leaflet-sidebar-body').append(e);
        });
        jQuery('#sidebar').removeClass('hidden').addClass('leaflet-sidebar-right');
      },
      fail: function (error) {
        aTooltip.displayError(error);
      },
    });
  }

  function showRouteFromOLT(button, link) {
    if (jQuery(button).hasClass('fa-spinner')) return;

    if (!AllLayers['layer_10']) LayersConfiguration.setLayerVisible(undefined, 'layer_10');

    jQuery(button).find('span').removeClass('fa-eye');
    jQuery(button).find('span').addClass('fa-spinner fa-spin');

    jQuery.ajax({
      url: link + '&RETURN_JSON=1',
      type: 'GET',
      contentType: false,
      cache: false,
      processData: false,
      success: function (result) {
        _removeTrace();
        let data = JSON.parse(result);
        if (_showError(data, button)) return;

        L.control.sidebar({
          autopan: false,
          closeButton: true,
          container: 'sidebar',
          position: 'right',
        }).addTo(map);

        closeControlBtn = createCloseTraceBtn();
        map.addControl(closeControlBtn);

        jQuery('#leaflet-sidebar-body').html('')
        Object.keys(data).forEach(key => {
          let commutations = document.createElement('div');
          drawRouteFromOltToUser(data[key].path, button).forEach(e => {
            commutations.appendChild(e);
          });

          jQuery('#leaflet-sidebar-body').append(createCard(`UID: ${data[key].uid}`, commutations));
        });

        jQuery('#sidebar').removeClass('hidden').addClass('leaflet-sidebar-right');
      }
    });
  }

  function drawRouteFromOltToUser(data, button) {
    let path = data['path'];
    let fiberViews = data['fiber_views'];
    let commutationsPriority = data['commutations_priority'];
    let cables = path.filter(element => element.element_type === "CABLE");
    let error = path.filter(element => element.element_type === "ERROR");
    let cables_to_glow = Array.from(new Set(cables.map(cable => cable.element_id))).map(cable => {
      return cables.find(cable_ => cable_.element_id === cable && cable_.point_id)
    });

    let antColor = error.length > 0 ? '#df4759' : '#42ba96';
    jQuery.each(cables_to_glow, function (k, v) {
      let path = new L.Polyline.AntPath(Objects[10][v.point_id]._latlngs, {
        reverse: v.reverse,
        color: antColor,
        opacity: 0.8
      });
      path.addTo(map);

      Objects['ant_path_trace'].push(path);
    });

    jQuery(button).find('span').removeClass('fa-spinner fa-spin');
    jQuery(button).find('span').addClass('fa-eye');

    let commutationBlocks = [];
    commutationsPriority.forEach(function(commutation) {

      commutationBlocks.push(createCard(`${_COMMUTATION}: ${commutation}`,
        createCommutationPath(fiberViews[commutation])));
    });

    return commutationBlocks;
  }

  function createCloseTraceBtn() {
    let closeBtn = L.Control.extend({
      options: { position: 'topright' },
      onAdd: function() {
        let container = document.createElement('div');
        container.classList.add('leaflet-bar');
        container.classList.add('leaflet-control');

        container.appendChild(this._createHrefContainer());

        return container;
      },
      _createHrefContainer: () => {
        let containerHref = document.createElement('a');
        containerHref.title = 'Remove trace';
        containerHref.id = 'remove-trace';
        containerHref.classList.add('polyline-measure-unicode-icon');

        L.DomEvent.on(containerHref, 'click', () => {
          map.removeControl(closeControlBtn);
          closeControlBtn = undefined;

          if (Objects['ant_path_trace']) {
            while (Objects['ant_path_trace'].length) {
              Objects['ant_path_trace'].pop().removeFrom(map);
            }
          }

          jQuery('#leaflet-sidebar-body').html('');
          jQuery('#sidebar').addClass('hidden').removeClass('leaflet-sidebar-right');
        });

        let _containerIcon = document.createElement('i');
        _containerIcon.classList.add('fa');
        _containerIcon.classList.add('fa-close');

        containerHref.appendChild(_containerIcon);

        return containerHref;
      }
    });

    if (closeControlBtn){
      map.removeControl(closeControlBtn);
      closeControlBtn = undefined;
    }
    return new closeBtn();
  }

  function createCard(title, body) {
    let card = document.createElement('div');
    card.classList.add('card');
    card.classList.add('collapsed-card');
    card.classList.add('m-2');

    let cardHeader = document.createElement('div');
    cardHeader.classList.add('card-header');
    cardHeader.classList.add('with-border');

    let cardTitle = document.createElement('h4');
    cardTitle.classList.add('card-title');
    cardTitle.innerHTML = title;

    let cardHeaderTool = document.createElement('div');
    cardHeaderTool.classList.add('card-tools');
    cardHeaderTool.classList.add('float-right');

    let collapseBtn = document.createElement('button');
    collapseBtn.classList.add('btn');
    collapseBtn.classList.add('btn-tool');
    collapseBtn.style.color = '#adb5bd';
    collapseBtn.dataset.cardWidget = 'collapse';

    let icon = document.createElement('i');
    icon.classList.add('fa');
    icon.classList.add('fa-plus');

    let cardBody = document.createElement('div');
    cardBody.classList.add('card-body');
    cardBody.classList.add('p-1');
    cardBody.appendChild(body);

    collapseBtn.appendChild(icon);
    cardHeaderTool.appendChild(collapseBtn);
    cardHeader.appendChild(cardTitle);
    cardHeader.appendChild(cardHeaderTool);
    card.appendChild(cardHeader);
    card.appendChild(cardBody);

    return card;
  }

  function createCommutationPath(path) {
    let mainBlock = document.createElement('div');
    mainBlock.classList.add('list-group');

    path.forEach(function(branch) {
      let listItem = document.createElement('span');
      listItem.classList.add('list-group-item');
      listItem.classList.add('p-2');

      if (typeof branch !== 'object') {
        listItem.innerHTML = branch;
        mainBlock.appendChild(listItem);
        return;
      }

      let fiber = document.createElement('span');
      fiber.classList.add('border');
      fiber.classList.add('rounded');
      fiber.classList.add('p-1');
      fiber.style.backgroundColor = branch['fiber_color'];
      fiber.innerHTML = branch['fiber_num'];

      let leftArrow = document.createElement('span');
      leftArrow.innerHTML = ' &#10229; ';

      let element = document.createElement('span');
      element.innerHTML = branch['type'] + (branch['name'] ? ` | ${branch['name']}` : '');

      listItem.appendChild(fiber);
      listItem.appendChild(leftArrow);
      listItem.appendChild(element);
      mainBlock.appendChild(listItem);
    });

    return mainBlock;
  }

  function showRouteBetweenPoints(object) {
    Markers.createMarker({
      COORDX: TempVariables['USER_COORDS']['latitude'],
      COORDY: TempVariables['USER_COORDS']['longitude'],
      TYPE: 'user',
      DISABLE_EDIT: 1
    }).addTo(map);

    let url = "https://router.project-osrm.org/route/v1/driving/";
    url += TempVariables['USER_COORDS']['longitude'] + "," + TempVariables['USER_COORDS']['latitude'] + ';';
    url += object['COORDY'] + "," + object['COORDX'];
    url += "?overview=full&geometries=geojson";

    fetch(url)
      .then(function (response) {
        if (!response.ok)
          throw Error(response.statusText);

        return response;
      })
      .then(function (response) {
        return response.json();
      })
      .then(result => async function (result) {
        let coords = result.routes[0].geometry.coordinates;
        if (coords) {
          coords.forEach(function (element) {
            let temp = element[0];
            element[0] = element[1];
            element[1] = temp;
          });

          let route = Polylines.createPolyline({
            POINTS: coords,
            STROKECOLOR: "#107dac",
            OPACITY: 0.8,
          });
          route.addTo(map);
        }
      }(result))
      .catch(function (error) {
        console.log(error);
      });
  }

  function _removeTrace() {
    if (!Objects['ant_path_trace']) {
      Objects['ant_path_trace'] = []
      return;
    }

    while (Objects['ant_path_trace'].length) {
      Objects['ant_path_trace'].pop().removeFrom(map);
    }
  }

  function _showError(data, button) {
    if (!data['error']) return 0;

    aTooltip.displayError(data['error']);
    jQuery(button).find('span').removeClass('fa-spinner fa-spin');
    jQuery(button).find('span').addClass('fa-eye');
    return 1;
  }

  return {
    showRouteBetweenPoints: showRouteBetweenPoints,
    showRouteFromONUtoOLT: showRouteFromONUtoOLT,
    showRouteFromOLT: showRouteFromOLT
  }
})();

var Controls = (function () {

  let layersControl = L.Control.extend({
    options: {
      position: 'topleft'
    },
    onAdd: function () {
      let self = this || {};
      self.hideLayers = true;

      let container = document.createElement('div');
      container.classList.add('row');
      container.id = 'navbar-container';
      container.style.width = '135px';
      container.style['border-radius'] = '5px';
      container.style.padding = '1px';

      let controlContainer = document.createElement('div');
      controlContainer.classList.add('leaflet-control-zoom');
      controlContainer.classList.add('leaflet-bar');
      controlContainer.classList.add('leaflet-control');
      controlContainer.classList.add('leaflet-custom');

      let containerHref = document.createElement('a');
      containerHref.id = 'hide-button';
      containerHref.href = '#';
      containerHref.classList.add('leaflet-control-zoom-in');
      containerHref.innerText = '-';
      controlContainer.appendChild(containerHref);

      let buttonsContainer = document.createElement('div');
      buttonsContainer.id = 'navbar-button-container';

      container.appendChild(controlContainer);
      container.appendChild(buttonsContainer);

      L.DomEvent.disableScrollPropagation(buttonsContainer);
      L.DomEvent.disableClickPropagation(buttonsContainer);

      L.DomEvent.on(containerHref, 'click', () => {
        if (self.hideLayers) {
          jQuery('#navbar-button-container').fadeOut(300);
          jQuery('a#hide-button').text('+');
          self.hideLayers = false;
        } else {
          jQuery('#navbar-button-container').fadeIn(300);
          jQuery('a#hide-button').text('-');
          self.hideLayers = true;
        }
      });

      return container;
    }
  });

  let searchControl = L.Control.extend({
    options: {
      position: 'topleft'
    },
    onAdd: function () {
      let container = document.createElement('div');
      container.classList.add('row');
      container.style.width = '14vw';

      let colContainer = document.createElement('div');
      colContainer.classList.add('col-md-12');
      colContainer.classList.add('p-0');

      let mainFlexContainer = document.createElement('div');
      mainFlexContainer.classList.add('d-flex');
      mainFlexContainer.classList.add('bd-highlight');

      let selectContainer = this._createSelectContainer();
      let spanContainer = this._createSpanContainer(selectContainer);

      mainFlexContainer.appendChild(selectContainer);
      mainFlexContainer.appendChild(spanContainer);
      colContainer.appendChild(mainFlexContainer);
      container.appendChild(colContainer);

      return container;
    },
    _createSelectContainer: () => {
      let flexContainer = document.createElement('div');
      flexContainer.classList.add('flex-fill');
      flexContainer.classList.add('bd-highlight');
      flexContainer.classList.add('d-none');

      let selectContainer = document.createElement('div');
      selectContainer.classList.add('select');

      let inputGroup = document.createElement('div');
      inputGroup.classList.add('input-group-append');
      inputGroup.classList.add('select2-append');

      let select = document.createElement('select');
      select.id = 'objects-select';
      select.style.width = '100%';

      inputGroup.appendChild(select);
      selectContainer.appendChild(inputGroup);
      flexContainer.appendChild(selectContainer);

      return flexContainer;
    },
    _createSpanContainer: (selectContainer) => {
      let bdContainer = document.createElement('div');
      bdContainer.classList.add('bd-highlight');

      let button = document.createElement('a');
      button.classList.add('btn');
      button.classList.add('btn-sm');

      let iconContainer = document.createElement('span');
      iconContainer.classList.add('fa');
      iconContainer.classList.add('fa-search');

      let inputGroupText = document.createElement('div');
      inputGroupText.classList.add('input-group-text');
      inputGroupText.classList.add('p-0');
      inputGroupText.style.height = '38px';

      let appendContainer = document.createElement('div');
      appendContainer.classList.add('input-group-append');
      L.DomEvent.on(appendContainer, 'click', () => {
        if (selectContainer.classList.contains('d-none')) {
          selectContainer.classList.remove('d-none')
          inputGroupText.classList.add('rounded-left-0');
        }
        else {
          selectContainer.classList.add('d-none');
          inputGroupText.classList.remove('rounded-left-0');
        }
      });

      button.appendChild(iconContainer);
      inputGroupText.appendChild(button);
      appendContainer.appendChild(inputGroupText);
      bdContainer.appendChild(appendContainer);

      return bdContainer;
    }
  });

  let homeControl = L.Control.extend({
    options: {
      position: 'topright'
    },
    onAdd: function() {
      let container = document.createElement('div');
      container.id = 'home-button';
      container.classList.add('leaflet-bar');
      container.classList.add('leaflet-control');

      container.appendChild(this._createHrefContainer());

      return container;
    },
    _createHrefContainer: () => {
      let containerHref = document.createElement('a');
      containerHref.id = 'home-href';
      containerHref.title = 'Go Home';
      containerHref.classList.add('polyline-measure-unicode-icon');

      L.DomEvent.on(containerHref, 'click', () => {
        if (!MAPS_DEFAULT_LATLNG)
          return 0;

        let coordsArray = MAPS_DEFAULT_LATLNG.split(';');
        if (coordsArray.length < 2)
          return 0;

        map.setView([coordsArray[0], coordsArray[1]], coordsArray[2] || 15);
      });

      let _containerIcon = document.createElement('i');
      _containerIcon.classList.add('fa');
      _containerIcon.classList.add('fa-home');

      containerHref.appendChild(_containerIcon);

      return containerHref;
    }
  });

  function showControls() {
    if (!FORM['SMALL'] && !FORM['HIDE_CONTROLS']) {
      map.addControl(new searchControl());
      map.addControl(new layersControl());
      map.addControl(new homeControl());

      jQuery("#objects-select").select2();
    }
    else if (FORM['SHOW_SEARCH']) {
      map.addControl(new searchControl());
      jQuery("#objects-select").select2();
    }

    jQuery('#objects-select').on('change', function () {
      if (!jQuery(this).val())
        return 0;

      let object = ObjectsById[jQuery(this).val()];

      if (object['COORDX']) {
        map.setView([object['COORDX'], object['COORDY']], 19);
      } else if (object['POINTS']) {
        Configuration.fitByObject(object);
      }
      setTimeout(function () {
        Objects[object['LAYER_ID']][object['OBJECT_ID']].openPopup();
      }, 300);
    });
  }

  return {
    showControls: showControls
  }
})();

var init_map = function () {
  let defaultLat = 0;
  let defaultLng = 0;

  if (MAPS_DEFAULT_LATLNG) {
    let coordsArray = MAPS_DEFAULT_LATLNG.split(';');
    if (coordsArray.length >= 2) {
      defaultLat = coordsArray[0];
      defaultLng = coordsArray[1];
    }
  }

  map = L.map('map', {
    center: [defaultLat, defaultLng],
    zoom: 6,
    measureControl: true,
    drawControl: true,
    fullscreenControl: true,
    selectArea: true
  });

  let leaflet_map = L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
    maxZoom: 19,
    useCache: true,
    crossOrigin: true
  });

  baseMaps = {"Leaflet": leaflet_map};

  if (Configuration.onGoogleMaps()) {
    baseMaps['Google'] = L.gridLayer.googleMutant({type: 'roadmap'});
    baseMaps['Satellite'] = L.gridLayer.googleMutant({type: 'satellite'});
    baseMaps['Terrain'] = L.gridLayer.googleMutant({type: 'terrain'});
    baseMaps['Hybrid'] = L.tileLayer('http://{s}.google.com/vt/lyrs=s,h&x={x}&y={y}&z={z}',{
      maxZoom: 20,
      subdomains:['mt0','mt1','mt2','mt3']
    })
  }

  if (Configuration.onYandexMaps())
    baseMaps['Yandex'] = L.yandex('yandex#map');

  if (VISICOM_API_KEY)
    baseMaps['Visicom'] = L.tileLayer('https://tms{s}.visicom.ua/2.0.0/planet3/base/{z}/{x}/{y}.png?key=' + VISICOM_API_KEY, {
      maxZoom: 19,
      tms: true,
      subdomains: '123'
    });

  baseMaps['2GIS'] = L.tileLayer('http://tile{s}.maps.2gis.com/tiles?x={x}&y={y}&z={z}&v=1', {
    maxZoom: 19,
    subdomains: '123'
  });

  if (MAPS_DEFAULT_TYPE && baseMaps[MAPS_DEFAULT_TYPE])
    setTimeout(function () {
      baseMaps[MAPS_DEFAULT_TYPE].addTo(map);
    }, 500);
  else
    baseMaps['Leaflet'].addTo(map);

  L.control.layers(baseMaps).addTo(map);

  L.Control.Watermark = L.Control.extend({
    onAdd: function () {
      let href = L.DomUtil.create('a', 'axbills_href');
      href.href = MAPS_WATERMARK_URL || 'http://billing.axiostv.ru/';
      href.target = '_blank';

      let img = L.DomUtil.create('img', 'axbills_href', href);

      img.src = '/images/maps/icons/' + (MAPS_WATERMARK_ICON || 'axbills.png');
      img.style.width = '45px';

      return href;
    }
  });

  L.control.watermark = function (opts) { return new L.Control.Watermark(opts) };
  L.control.watermark({position: 'bottomleft'}).addTo(map);

  L.control.BigImage({position: 'topright', downloadTitle: _DOWNLOAD, inputTitle: `${_SCALE}:`}).addTo(map);
  if (!FORM['HIDE_EDIT_BUTTONS']) L.control.CenterCoordinates().addTo(map);

  Configuration.createControl();

  Controls.showControls();

  if (!FORM['OBJECT_TO_SHOW'] || FORM['OBJECT_TO_SHOW'].length === 0) Configuration.getLocation();
  if (!FORM['SMALL']) L.control.polylineMeasure(Configuration.getOptions()).addTo(map);

  if (localStorage.getItem('LAST_LNG') && localStorage.getItem('LAST_LAT') && localStorage.getItem('LAST_ZOOM')) {
    map.setView([localStorage.getItem('LAST_LAT'), localStorage.getItem('LAST_LNG')], localStorage.getItem('LAST_ZOOM'));
  }

  map.on('moveend', function (e) {
    if (e.target && e.target._lastCenter && e.target._lastCenter.lng && e.target._lastCenter.lat) {
      localStorage.setItem('LAST_LNG', e.target._lastCenter.lng);
      localStorage.setItem('LAST_LAT', e.target._lastCenter.lat);
      localStorage.setItem('LAST_ZOOM', e.target._zoom);
    }
  });
};

let loadLayers = function () {
  if (FORM['SMALL'] || FORM['HIDE_CONTROLS']) {
    if (ObjectsConfiguration.showCustomObjects())
      return 1;
  }

  if (!selfUrl.includes("/admin/"))
    selfUrl = selfUrl.replace('index.cgi', 'admin/index.cgi');

  fetch(selfUrl + '?header=2&get_index=maps2_layers_list&RETURN_JSON=1')
    .then(response => {
      if (!response.ok) {
        throw response
      }
      return response.json();
    })
    .then(result => LayersConfiguration.showLayers(result))
    .catch(err => {
      console.log(err);
    });
};

function fillSearchSelect(items, pageSize) {
  jQuery.fn.select2.amd.require(["select2/data/array", "select2/utils"], function (ArrayData, Utils) {
    function CustomData($element, options) {
      CustomData.__super__.constructor.call(this, $element, options);
    }

    Utils.Extend(CustomData, ArrayData);

    CustomData.prototype.query = function (params, callback) {

      let results = [];
      if (params.term && params.term !== '') {
        results = _.filter(items, function (e) {
          return e.text.toUpperCase().indexOf(params.term.toUpperCase()) >= 0;
        });
      } else {
        results = items;
      }

      if (!("page" in params)) {
        params.page = 1;
      }
      let data = {};
      data.results = results.slice((params.page - 1) * pageSize, params.page * pageSize);
      data.pagination = {};
      data.pagination.more = params.page * pageSize < results.length;
      callback(data);
    };

    jQuery("#objects-select").select2({
      ajax: {},
      dataAdapter: CustomData
    });
  });
}

function editField(element) {
  let $jelement = jQuery(element)

  let oldValue = $jelement.text();
  let newValue = oldValue;
  let fieldName = $jelement.data('field');
  let url = $jelement.data('url');
  let id = $jelement.data('id');

  if ($jelement.data('input')) return;

  $jelement.data('input', true);
  $jelement.html('<div class="input-group input-group-sm" style="min-width: 150px;">' +
    '<input name="NAME" class="form-control" value="' + oldValue + '" id="' + fieldName + '_FIELD">' +
    '<div class="input-group-append"><div class="input-group-text cursor-pointer" id="CHANGE_' + fieldName + '_BTN">' +
    '<span class="fa fa-save"></span></div></div></div>'
  );

  jQuery('#CHANGE_' + fieldName + '_BTN').on('click', function() {
    url += '&' + fieldName + '=' + jQuery('#' + fieldName + '_FIELD').val();
    url += '&ID=' + id;
    jQuery('#' + fieldName + '_FIELD').prop('disabled', true);
    jQuery('#CHANGE_' + fieldName + '_BTN').hide();

    fetch(url)
      .then(response => {
        if (!response.ok) throw response;
        return response;
      })
      .then(response => response.text())
      .then(result => {
        $jelement.data('input', false);
        if (result) {
          $jelement.html(oldValue);
          return;
        }
        newValue = jQuery('#' + fieldName + '_FIELD').val();
        $jelement.html(newValue);

        map.on('popupopen', changePopover);
      })
      .catch(err => {
        $jelement.data('input', false);
        $jelement.html(oldValue);
      });
  });

  function changePopover(e) {
    let test = jQuery(e.popup._contentNode);
    test.find(`[data-id='${id}'][data-field='${fieldName}']`).html(newValue);
    jQuery(e.popup._contentNode).html(test.html());
    map.off('popupopen', changePopover);
  }
}

init_map();
loadLayers();