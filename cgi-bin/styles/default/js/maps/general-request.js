/**
 * Created by Anykey on 08.09.2016.
 */
'use strict';

function AObjectRegistrator(locationId) {
  
  this.locationId = locationId;
  this.aMapObject = null;
  this.callback   = this.send;
  
  this.setLocationId = function (locationId) {
    this.locationId = locationId;
    return this;
  };
  
  this.getLocationId = function () {
    return this.locationId;
  };
  
  this.setMapObject = function (aMapObject) {
    this.aMapObject = aMapObject;
  };
  
  this.getMapObject = function () {
    return this.aMapObject;
  };
  
  this.setCallback = function (callBack) {
    this.callback = callBack;
  };
  
  this.getCallback = function () {
    return this.callback;
  };
  
  this.send = function () {
    if (isDefined(this.aMapObject.ready) && this.aMapObject.ready) {
      Events.emit('currentmapobjectfinished');
      this.aMapObject.send();
    }
    else {
      Events.emit('proceedingaddingpoints');
      this.aMapObject.proceed();
    }
  };
}

var aBillingAddressManager = new ABillingLinkManager();
function ABillingLinkManager() {
  
  var self = this;
  this.$filterForm = null;
  
  $(function(){
    self.$filterForm = $('form#mapUserShow');
  });
  
  this.registerObject = function (object_params) {
    var default_params = {
      add     : 1,
      qindex  : index,
      header  : 2,
      MAP_TYPE: MAP_TYPE
    };
    
    var params = $.extend({}, default_params, object_params);
    
    return '?' + $.param(params);
  };
  
  this.registerBuild = function (location_id, coordx, coordy) {
    return 'index.cgi?qindex=' + index + '&header=2&add=1&LAYER_ID=1'
        + '&update_build=1'
        + '&LOCATION_ID=' + location_id
        + '&COORDY=' + coordy
        + '&COORDX=' + coordx
        + '&change=1&MAP_TYPE=' + MAP_TYPE;
  };
  
  this.addMarker = function (streetId, location_id, coordx, coordy) {
    return 'index.cgi?qindex=' + index + '&header=2&add=1&LAYER_ID=1'
        + '&STREET_ID=' + streetId
        + '&ADD_ADDRESS_BUILD=' + location_id
        + '&COORDY=' + coordy
        + '&COORDX=' + coordx
        + '&change=1&MAP_TYPE=' + MAP_TYPE;
  };
  
  this.addressChooseLocation = function () {
    return 'index.cgi?qindex=' + index +
        '&SHOW_ADDRESS=1&SHOW_UNREG=1&header=2';
  };
  
  this.removeObject = function (layer_id, object_id, emulate, cable_id, well_id) {

    return 'index.cgi?get_index=maps_edit&header=2'
        + '&LAYER_ID=' + layer_id
        + '&OBJECT_ID=' + object_id
        + '&del=' + 1
        + (emulate ? '&emulate=1' : '')
        + (cable_id ? ('&cable_id=' + cable_id) : '')
        + (well_id ? ('&well_id=' + well_id) : '');
  };
  
  this.getMarkersForLayer = function (TYPE) {
  
    var form_params = this.getFormParams();
    
    // Remove header, to avoid double 'Content-Type'
    delete form_params['header'];
    
    // Should add params from upper form
    if (this.$filterForm.length){
      var groups = this.$filterForm.find('select#GID').val();
      var district_id = this.$filterForm.find('select#PANEL_DISTRICT_ID').val();
      var info_module = this.$filterForm.find('select#INFO_MODULE').val();
          
      if (groups) form_params['GROUP_ID'] = groups;
      if (district_id) form_params['DISTRICT_ID'] = district_id;
      if (info_module) form_params['INFO_MODULE'] = info_module;
    }
    
    return 'index.cgi?&EXPORT_LIST=' + TYPE
        + '&' + $.param(form_params);
  };
  
  this.getForm = function (params) {
    return 'index.cgi?' + $.param(this.getFormParams()) + '&' + $.param(params);
  };
  
  this.getFormParams = function () {
    return {
      qindex       : map_edit_index,
      header       : 2,
      MAP_TYPE     : MAP_TYPE,
      EDIT_MODE: OPTIONS['EDIT_MODE'] ? 1 : 0
    }
  }
  
}

function ABillingLocation(LocationArray) {
  var self = this;
  
  this.locationArray = null;
  this.districtId    = null;
  this.streetId      = null;
  this.locationId    = null;
  this.newNumber     = null;
  
  if (LocationArray) this.setLocation(LocationArray);
  
  this.setLocation = function (LocationArray) {
    this.locationArray = LocationArray;
    this.districtId    = LocationArray[0];
    this.streetId      = LocationArray[1];
    this.locationId    = LocationArray[2];
    this.newNumber     = LocationArray[3];
  };
  
  this.hasLocation = function () {
    return this.locationArray != null;
  };
  
  this.getLocationId = function () {
    return this.locationId;
  };
  
  
  this.askLocation = function (callback) {
    $.get(aBillingAddressManager.addressChooseLocation(), function (data) {
      aModal.clear()
          .setId('ModalLocation')
          .setHeader('Choose address')
          .setBody(data)
          .addButton(_CANCEL, 'districtModalCancelButton', 'default')
          .addButton(_YES, 'districtModalButton', 'primary')
          .show(setUpAddressModalForm);
      
      function setUpAddressModalForm(amodal) {
        
        initChosen();
        
        //bind handlers
        $('#districtModalButton').on('click', function () {
          
          var dId = amodal.$modal.find('input[name="DISTRICT_ID"]').val();
          var sId = amodal.$modal.find('input[name="STREET_ID"]').val();
          var lId = amodal.$modal.find('input[name="LOCATION_ID"]').val();
          
          var newNumber = amodal.$modal.find('input.INPUT-ADD-BUILD').val() || null;
          
          self.setLocation([dId, sId, lId, newNumber]);
          
          if (callback) {
            callback(self);
          }
        });
        
        $('#districtModalCancelButton').on('click', function () {
          discardAddingPoint()
        })
      }
      
    }, 'text');
  };
}

function showConfirmModal(lang_name, confirmation_text, callbacks) {
  
  if (!isDefined(confirmation_text)) {
    confirmation_text = _ADD + ' ' + _NEW + ' ' + lang_name + '?';
  }
  
  var discardAction = discardAddingPoint;
  var confirmAction = confirmAddingPoint;
  
  if (isDefined(callbacks)) {
    if (isDefined(callbacks.yes)) confirmAction = callbacks.yes;
    if (isDefined(callbacks.no)) discardAction = callbacks.no;
  }
  
  function bindBtnEvents() {
    $('#confirmModalConfirmBtn').on('click', function () {
      confirmModal.hide();
      confirmAction();
      Events.emit('proceedaddingpointfinished');
    });
    
    $('#confirmModalCancelBtn').on('click', function () {
      confirmModal.hide();
      discardAction();
      Events.emit('proceedaddingpointfinished');
    });
  }
  
  // TODO: localize confirm buttons
  confirmModal = new AModal();
  confirmModal
      .setBody('<div id="confirmModalContent">' + confirmation_text + '</div>')
      .addButton(_NO, 'confirmModalCancelBtn', 'default')
      .addButton(_YES, 'confirmModalConfirmBtn', 'success')
      .show(bindBtnEvents);
  
}

/** Shows how Map objects are referencing to JavaScript Models of map objects*/
var MapObjectTypesRefs = (function () {
  
  
  function getMapObject(layer_id) {
    
    /**
     * Presents an object that will be registered.
     * Model
     * */
    var AMapObject = {
      type           : "null",
      id             : null,
      ready          : true,
      customParams   : null,
      create         : function (values) {
        var instance = Object.create(this);
        Object.keys(values).forEach(function (key) {
          instance[key] = values[key];
        });
        return instance;
      },
      getId          : function () {
        return this.id;
      },
      setId          : function (id_) {
        this.id = id_;
      },
      getType        : function () {
        return this.type;
      },
      setType        : function (type) {
        this.type = type;
      },
      setCustomParams: function (params) {
        this.customParams = params;
      },
      addCustomParams: function (params) {
        if (this.customParams === 'null') {
          this.setCustomParams(params);
        }
        else {
          $.extend(this.customParams, params);
        }
      },
      send           : function () {
        var params = {TYPE: this.type};
        
        delete this.encoded.raw;
        $.extend(params, this.encoded);
        
        var link = aBillingAddressManager.getForm(params);
        loadToModal(link);
      },
      update: function (object) {
        var form_params = aBillingAddressManager.getFormParams();
        var custom_params = {
          change   : 1,
          LAYER_ID : object.layer_id
        };
    
        if (object.polyline) {
          var encoded = GeoJsonExporter.encodeLine(object.polyline);
          delete encoded.raw;
      
          $.extend(custom_params, {
            TYPE     : 'polyline',
            POINTS   : JSON.stringify(encoded['POINTS']),
            ID       : object.polyline.id,
            OBJECT_ID: object.polyline.OBJECT_ID
          });
        }
        else if (object.marker) {
          var encoded = GeoJsonExporter.encodePoint(object.marker);
          delete encoded.raw;
      
          console.log(object.marker);

          $.extend(custom_params, {
            TYPE     : 'marker',
            ID       : object.marker.id,
            OBJECT_ID: object.marker.OBJECT_ID,

            COORDX   : encoded.COORDX,
            COORDY   : encoded.COORDY
          });
        }
    
        $.extend(form_params, custom_params);
        $.post('index.cgi', form_params);
        return false;
      }
    };
    
    var AMapPoint = AMapObject.create({
      latLng : null,
      encoded: null,
      emit   : function (overlay) {
        this.latLng  = overlay.position;
        this.encoded = GeoJsonExporter.encodePoint(overlay)
      }
    });
    
    var AMapBuild = AMapPoint.create({
      type: BUILD,
      send: function (callback) {
        
        var x = this.encoded.COORDX;
        var y = this.encoded.COORDY;
        
        function registerBuild(location_id, x, y) {
          var link = aBillingAddressManager.registerBuild(location_id, x, y);
          loadToModal(link);
        }
        
        function addBuild(streetId, buildNumber, x, y) {
          var link = aBillingAddressManager.addMarker(streetId, buildNumber, x, y);
          loadToModal(link);
        }
        
        if (FORM['LOCATION_ID']) {
          registerBuild(FORM['LOCATION_ID'], x, y);
        }
        else {
          var location = new ABillingLocation();
          location.askLocation(function (locationC) {
            
            console.log(locationC);
            
            if (locationC.newNumber) {
              var sId       = locationC.streetId;
              var newNumber = locationC.newNumber;
              addBuild(sId, newNumber, x, y);
            }
            else {
              var location_id = locationC.getLocationId();
              registerBuild(location_id, x, y);
            }
          });
        }
      }
    });
    
    var AMapWell = AMapPoint.create({
      type: WELL
    });
    
    var AMapCustomPoint = AMapPoint.create({
      type: CUSTOM_POINT,
      send: function () {
        
        var COORDX = this.latLng.lat();
        var COORDY = this.latLng.lng();
        
        var add_link = '?get_index=maps_show_custom_point_form&header=2&COORDX=' + COORDX + '&COORDY=' + COORDY + '&AJAX=1';
        
        if (this.id !== null) {
          add_link = '?get_index=maps_objects_main&header=2&MESSAGE_ONLY=1&'
              + 'COORDX=' + COORDX + '&COORDY=' + COORDY
              + '&change=1&ID=' + this.id;
        }
        
        // Get bounds to get all markers in it
        var build_closest = getClosestBuildsToThis(this.latLng);
        if (build_closest.length > 0) {
          var ids = build_closest.map(function (build) {
            return build.marker.id
          }).join(';');
          
          add_link += '&CLOSEST_BUILDS=' + ids;
        }
        
        // Retrieve last added type
        var last_type_id = window['LAST_ADDED_OBJECT_TYPE'];
        if (last_type_id) {
          add_link += '&TYPE_ID=' + last_type_id;
        }
        
        //aModal.hide();
        loadToModal(add_link);
      }
    });
    
    var AMapWifi = AMapPoint.create({
      type   : WIFI,
      encoded: null,

      emit: function (overlay) {

        this.object = {overlay: overlay, type: 'polygon'};
        this.ready   = true;
      },

      send: function () {

        loadToModal('index.cgi?get_index=maps_edit&header=2&LAYER_ID=2&TYPE=WIFI');

        var self = this;
        Events.once('AJAX_SUBMIT.WIFI_ADD_FORM', function (data) {
          aModal.hide();

          var wifi_id = data.MESSAGE.INSERT_ID;
          submit_geometry(wifi_id)
        });


        var submit_geometry = function (wifi_id) {
          var geoJSON = GeoJsonExporter.toGeoJSON([self.object]);
          var geoJSONEncoded = JSON.stringify(geoJSON);

          var params = {
            TYPE: WIFI,
            LAYER_ID: 2,
            OBJECT_ID: wifi_id,
            JSON: geoJSONEncoded,
            add: 1
          };

          if (self.customParams !== null) {
            $.extend(params, this.customParams);
          }

          $.extend(params, aBillingAddressManager.getFormParams());

          postAndLoadToModal('index.cgi', params);
        }
      }
    });
    
    var AMapBuild2 = AMapPoint.create({
      type   : BUILD2,
      encoded: null,

      emit: function (overlay) {

        this.object = {overlay: overlay, type: 'polygon'};
        this.ready  = false;
        if (FORM['LOCATION_ID']) {
          this.location_id = FORM['LOCATION_ID'];
          this.ready = true;
        }
      },
      
      proceed : function (callback)  {
        var self = this;
        var location = new ABillingLocation();
        location.askLocation(function (locationC) {
          if (locationC.newNumber) {
            self.sId       = locationC.streetId;
            self.newNumber = locationC.newNumber;
          }
          else {
            self.location_id = locationC.getLocationId();
          }
          if ( self.location_id || self.newNumber) {
            self.ready = true;
            confirmAddingPoint();
          }
        });
      },
      
      send: function (callback) {
        var self = this;
        aModal.hide();
        console.log(self);
        var geoJSON        = GeoJsonExporter.toGeoJSON([self.object]);
        var geoJSONEncoded = JSON.stringify(geoJSON);
          
        var params = {
          TYPE        : BUILD2,
          LAYER_ID    : 12,
          JSON        : geoJSONEncoded,
          add         : 1
        };
        if (self.location_id) {
          params.LOCATION_ID = self.location_id;
        }
        if (FORM['OBJECT_ID']) {
          params.OBJECT_ID = FORM['OBJECT_ID'];
        }
        if (self.sId) {
          params.STREET_ID = self.sId;
          params.NUMBER = self.newNumber;
          params.ADD_ADDRESS_BUILD = 1;
        }
          
        if (self.customParams !== null) {
          $.extend(params, this.customParams);
        }
          
        $.extend(params, aBillingAddressManager.getFormParams());
        
        postAndLoadToModal('index.cgi', params);
      }
    });
    
    var AMapRoute = AMapObject.create({
      type  : ROUTE,
      length: 0,
      
      emit: function (overlay) {
        this.encoded = GeoJsonExporter.encodeLine(overlay);
        this.length  = aMap.getLength(this.encoded.raw.points);
      },
      update: function(object){
        console.log(object);
        return false;
      },
      send: function () {
        // Deleting circular references
        delete this.encoded.raw;
        
        var params = {
          TYPE        : this.type,
          ROUTE_LENGTH: this.length
        };
        
        // If explicit adding route by id, pass it back
        if (FORM['ROUTE_ID']) params.ROUTE_ID = FORM['ROUTE_ID']; //TODO change to generic
        
        $.extend(params, this.encoded, aBillingAddressManager.getFormParams());
        
        postAndLoadToModal('index.cgi', params);
      }
    });
    
    var AMapCustomOverlay = AMapObject.create({
      type        : MULTIPLE,
      objects     : [],
      customParams: null,
      init        : function (layer) {
        this.lang_name = layer['lang_name'];
        this.layer_id  = layer['id'];
      },
      emit        : function (overlay) {
        var controller = aDrawController.getDrawingManager();
        var type       = controller.getDrawingMode();
        
        // Saving index inside overlay
        overlay.index = this.objects.length;
        
        // Saving to internal array
        this.objects[overlay.index] = {overlay: overlay, type: type};
        this.ready                  = false;
      },
      remove      : function (index) {
        // Remove from map
        aMap.removeObjectFromMap(objects[index].overlay);
        
        // Remove from objects
        this.objects.splice(index, 1);
      },
      proceed     : function () {
        var self = this;
        Events.once('proceedaddingpoint', function () {
          self.ready = true;
          confirmAddingPoint();
        });
        
        showConfirmModal(this.lang_name, 'Add more objects?', {
          no : function () {Events.emit('proceedaddingpoint')},
          yes: function () {}
        });
      },
      send        : function (callback) {
        var geoJSON        = GeoJsonExporter.toGeoJSON(this.objects);
        var geoJSONEncoded = JSON.stringify(geoJSON);
        
        var params = {
          TYPE    : this.type,
          LAYER_ID: this.layer_id,
          JSON    : geoJSONEncoded
        };
        
        if (this.customParams !== null) {
          $.extend(params, this.customParams);
        }
        
        $.extend(params, aBillingAddressManager.getFormParams());
        
        postAndLoadToModal('index.cgi', params, callback);
      }
    });
  
    var AMapExternalObject = AMapCustomOverlay.create({
      // Skip "Add more objects" modal
      proceed: function () {
        this.ready = true;
        confirmAddingPoint();
      },
      send   : function (callback) {
        // Get object external form
        var self = this;
      
        var params = {
          header       : 2,
          add_form     : 1,
          ADD_OBJECT   : 1,
          TEMPLATE_ONLY: 1
        };
      
        if (this.customParams !== null) {
          params['get_index'] = this.customParams['add_func'];
          // Remove from POST request params
          // Maybe should split such params later
          delete params['add_func'];
          $.extend(params, this.customParams);
          
          // Alow cable to find his closest wells
          if (this.customParams['CALCULATE_PARAMS_JS_FUNCTION']
              && isDefined(window[this.customParams['CALCULATE_PARAMS_JS_FUNCTION']])
          ){
            var calculated_params = window[this.customParams['CALCULATE_PARAMS_JS_FUNCTION']](self.objects);
            if (calculated_params){
              params = $.extend(params, calculated_params);
            }
          }
        }
      
        Events.once('maps.external_object.form_loaded', function () {
          // Wait for DOM to be ready
          $(function () {
            //Do some custom form initialization
            defineFullWidthSelect();
            defineLinkedInputsLogic();
            $('.should-be-hidden').hide();
  
            // Find form in modal
            var $form = aModal.$modal.find('form');
  
            var add_hidden = function (name, value) {
              var hidden_input = document.createElement('input');
              $(hidden_input).attr({type: 'hidden', name: name, value: value});
              $form.append(hidden_input);
            };
  
            add_hidden('ADD_OBJECT', params['OBJECT_TYPE_ID']);
  
            // Make it be submitted via AJAX
            $form.on('submit', ajaxFormSubmit);
            var form_id = $form.attr('id');
  
            // Markers are saved as objects, no need to send geometric figure
            if (params['SAVE_AS_GEOMETRY'] !== 1) {
              var geometry = GeoJsonExporter.toGeoJSON(self.objects, true);

              add_hidden('COORDX', geometry[0].OBJECT.COORDX);
              add_hidden('COORDY', geometry[0].OBJECT.COORDY);
              
              Events.once('AJAX_SUBMIT.' + form_id, function(){
                if (callback) callback();
                
                MapLayers.refreshLayer(self.layer_id);
                aModal.hide();
              });
              
            }
            // If need to send geometry, first should know object_id
            else {
              // To prevent saving id to outer closure, proxying event
              Events.off('AJAX_SUBMIT.' + form_id);
              Events.once('AJAX_SUBMIT.' + form_id, Events.emitAsCallback('maps.external_object.form_submitted'));
            }
          });
        });
      
        postAndLoadToModal('/admin/index.cgi',
            params,
            Events.emitAsCallback('maps.external_object.form_loaded'),
            Events.emitAsCallback('AJAX_SUBMIT.closed')
        );
      
        // After form above have been submitted, we receive new object ID, and can save geometry
        Events.off('maps.external_object.form_submitted');
        Events.once('maps.external_object.form_submitted', function (submit_result) {
          aModal.hide();
        
          Events.once('maps.external_object.geometry_saved', function () {
            console.log('saved');
            MapLayers.refreshLayer(self.layer_id);
          });
        
          // After adding, if has OBJECT_ID
          if (submit_result['MESSAGE'] && submit_result['MESSAGE']['INSERT_ID']) {
            var geoJSON = GeoJsonExporter.toGeoJSON(self.objects, true);
            
            delete geoJSON.raw;
            var geoJSONEncoded = JSON.stringify(geoJSON);
            
            var layer_obj = MapLayers.getLayer(self.layer_id);
          
            var geometric_params =
              {
                TYPE       : self.type,
                LAYER_ID   : self.layer_id,
                OBJECT_ID  : submit_result['MESSAGE']['INSERT_ID'],
                STRUCTURE  : layer_obj.structure,
                MODULE     : layer_obj.module,
                EXPORT_FUNC: LAYER_LIST_REFS[self.layer_id],
                JSON       : geoJSONEncoded,
                callback   : '?'
              };
          
            $.extend(geometric_params, aBillingAddressManager.getFormParams());
          
            if (submit_result['COLOR']){
              geometric_params['COLOR'] = submit_result['COLOR'];
            }
            
            postAndLoadToModal('/admin/index.cgi', geometric_params, Events.emitAsCallback('maps.external_object.geometry_saved'));
          }
          else {
            console.log(submit_result);
            aTooltip.displayError('Error happened');
          }
        });
        
      }
    });
    
    if (MapLayers.hasCustomSent(layer_id)) {
      return AMapExternalObject;
    }
    
    // All user defined layers have custom structure
    if (layer_id >= 100) {
      return AMapCustomOverlay;
    }
    
    var refs = {
      1: AMapBuild,
      2: AMapWifi,
      3: AMapRoute,
      4: AMapExternalObject,
      //3: AMapDistrict,
      6: AMapCustomPoint,
      12: AMapBuild2
    };
    
    var res = refs[layer_id];
    
    if (typeof(res) !== 'undefined') {
      return res;
    }
    
    throw new Error('undefined type : ' + layer_id);
  }
  
  return {getMapObject: getMapObject};
})();

var GeoJsonExporter = (function () {
  
  
  function toGeoJSON(overlay_type_array, delete_raw) {
    var result = [];
    
    for (var i = 0; i < overlay_type_array.length; i++) {
      var overlay_type = overlay_type_array[i];
      var encodeFunc   = getEncodeFunction(overlay_type['type']);
      if (encodeFunc === null) continue;
      
      var encoded           = encodeFunc(overlay_type['overlay']);
      if (delete_raw){
        delete encoded.raw;
      }
      result[result.length] = {TYPE: overlay_type['type'], OBJECT: encoded};
    }
    
    return result;
  }
  
  function getEncodeFunction(type) {
    
    console.log('[ GeoJSonExporter ]', 'Encoding', type);
    
    switch (type) {
      case null :
        return null;
      case 'point':
      case 'marker' :
        return encodePoint;
      case 'circle' :
        return encodeCircle;
      case 'rectangle' :
        return encodeRectangle;
      case 'polygon' :
        return encodePolygon;
      case 'line' :
      case 'polyline' :
        return encodeLine;
      default :
        console.warn('[ GeoJSonExporter ]', 'unsupported type', type);
    }
    return console.log;
  }
  
  function encodePoint(overlay) {
    return {
      raw   : {
        COORDS: overlay.position
      },

      COORDX: overlay.position.lat(),
      COORDY: overlay.position.lng()
    }
  }
  
  function encodeLine(overlay) {
    var points = overlay.getPath().getArray();
    return {
      raw   : {
        points: points
      },
      POINTS: pointsArrToPointsStr(points),
      LENGTH : (aMap.getLengthForPath(overlay.getPath())).toFixed(2)
    }
  }
  
  function encodeCircle(overlay) {
    var latLng = overlay.center;
    var radius = Math.round(overlay.radius);
    
    return {
      COORDX: latLng.lng(),
      COORDY: latLng.lat(),
      RADIUS: radius
    }
  }
  
  function encodePolygon(overlay) {
    return {
      POINTS: pointsArrToPointsStr(overlay.getPath().getArray())
    }
  }
  
  function encodeRectangle(overlay) {
    // Rectangle contains bounds (two angles coords)
    var coords = overlay.getBounds().toJSON();
    
    // Have to convert it in 4 points to emulate polygon
    return {
      POINTS: [
        coords.west + ',' + coords.north,
        coords.east + ',' + coords.north,
        coords.east + ',' + coords.south,
        coords.west + ',' + coords.south
      ].join(';')
    }
  }
  
  function pointsArrToPointsStr(points) {
    return (points.map(
        function (latLng) {
          return [ latLng.lat(), latLng.lng() ]
        })
    );
  }
  
  return {
    toGeoJSON      : toGeoJSON,
    encodePoint    : encodePoint,
    encodeLine     : encodeLine,
    encodeCircle   : encodeCircle,
    encodePolygon  : encodePolygon,
    encodeRectangle: encodeRectangle
  }
})();