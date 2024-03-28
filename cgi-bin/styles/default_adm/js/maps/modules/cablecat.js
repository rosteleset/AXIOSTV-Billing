/**
 * Created by Anykey on 08.12.2016.
 *
 */

'use strict';
var CABLE_LAYER_ID = 10;
var WELL_LAYER_ID  = 11;

/**
 * Emulate drawing well on last opened infowindow position
 *
 * @param cable_id
 */
function insert_well_on_cable(cable_id) {
  var wells_layer = MapLayers.getLayer(WELL_LAYER_ID);
  
  // Get position from last_opened infowindow
  var last_infowindow = openedInfoWindows[openedInfoWindows.length - 1];
  var click_position  = last_infowindow.position;
  
  //Initialize controllers
  aDrawController = new DrawController();
  aDrawController
      .setLayerId(WELL_LAYER_ID)
      .setCallback(overlayCompleteCallback)
      .init(map)
      .setDrawingMode('MARKER');
  
  var mapObject = MapObjectTypesRefs.getMapObject(WELL_LAYER_ID);
  if (isDefined(mapObject.init)) {
    mapObject.init(MapLayers.getLayer(WELL_LAYER_ID));
  }
  
  mapObject.setCustomParams({
    add_func       : wells_layer['add_func'],
    module         : wells_layer['module'],
    INSERT_ON_CABLE: cable_id
  });
  mapObject.addCustomParams(wells_layer.custom_params);
  
  // Set COORDX and COORDY
  mapObject.emit({
    position: click_position
  });
  
  closeInfoWindows();
  aDrawController.clearDrawingMode();
  
  mapObject.send(function () {
    MapLayers.refreshLayer(CABLE_LAYER_ID);
    MapLayers.refreshLayer(WELL_LAYER_ID);
  });
}

function split_cable(cable_id) {
  // Get position from last_opened infowindow
  var last_infowindow = openedInfoWindows[openedInfoWindows.length - 1];
  var click_position  = GeoJsonExporter.encodePoint(last_infowindow);
  delete click_position.raw;
  
  var params = {
    get_index  : 'cablecat_maps_ajax',
    json       : 1,
    header     : 2,
    CABLE_ID   : cable_id,
    SPLIT_CABLE: 1,
    COORDX     : click_position['COORDX'],
    COORDY     : click_position['COORDY']
  };
  
  $.post('?', params, function (data) {
    console.log(data);
    MapLayers.refreshLayer(CABLE_LAYER_ID);
  })
}

function findClosestWellsForCable(single_overlay_arr) {
  if (!single_overlay_arr || !single_overlay_arr.length) return false;
  var polyline = single_overlay_arr[0].overlay;
  
  var path        = polyline.getPath();
  var first_point = path.getAt(0);
  var last_point  = path.getAt(path.getLength() - 1);
  
  var closest_for_start        = null;
  var wells_in_range_for_start = getPointsInRange(first_point, 200, WELL_LAYER_ID);
  if (wells_in_range_for_start.length) {
    closest_for_start = wells_in_range_for_start[0]['point']['raw']['ID']
  }
  
  var closest_for_end        = null;
  var wells_in_range_for_end = getPointsInRange(last_point, 200, WELL_LAYER_ID);
  if (wells_in_range_for_end.length) {
    closest_for_end = wells_in_range_for_end[0]['point']['raw']['ID'];
    if (closest_for_end === closest_for_start && wells_in_range_for_end.length > 1) {
      closest_for_end = wells_in_range_for_end[1]['point']['raw']['ID'];
    }
  }
  
  var length = aMap.getLength(path);
  
  return {
    WELL_1_ID        : closest_for_start,
    WELL_2_ID        : closest_for_end,
    LENGTH_CALCULATED: length
  }
}