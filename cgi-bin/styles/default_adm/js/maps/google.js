/**
 * Created by Anykey on 28.09.2015.
 *
 */
'use strict';
//MarkerClusterer for generated objects, e.g. ASearch results
var markerHolder;

/** Holds Markers, processed and placed on map  */
var markers = [];

/**
 * Created by Anykey on 02.10.2015.d
 */


var aDrawController;
var drawing_last_overlay = null;

var confirmModal = new AModal();
var latitude;
var longitude;

function AMap(callback) {
  
  var self = this;
  //Loading script if not downloaded
  if (!document.getElementById('google_api_script')) {
    var scriptElement = document.createElement('script');
    scriptElement.id  = 'google_api_script';
    var key_part = (MAP_KEY) ? '&key=' + MAP_KEY : '';
    scriptElement.src = 'https://maps.googleapis.com/maps/api/js?libraries=places,drawing&callback=initialize' + key_part;
    
    document.getElementsByTagName('head')[0].appendChild(scriptElement);
  }
  
  this.map = null;
  
  this.init = function (mapDiv, mapOptions, callback) {
    
    var mapOptions_       = mapOptions || {};
    mapOptions_.mapTypeId = getMapView(CONF_MAPVIEW);
    
    this.map = new google.maps.Map(
        mapDiv,
        mapOptions_
    );
    
    google.maps.event.addListener(this.map, 'click', function (event) {
      closeInfoWindows();
      
      Events.emit('mapsClick', event);
    });
    
    google.maps.event.addDomListener(window, "resize", function () {
      var center = aMap.getCenter();
      google.maps.event.trigger(map, "resize");
      map.setCenter(center);
    });
    
    if (callback) callback(this.map);
    return this.map;
  };
  
  this.createPosition = function (x, y) {
    return new google.maps.LatLng(+x, +y);
  };
  
  this.setCenter = function (x, y) {
    this.map.setCenter(this.createPosition(x, y));
  };
  
  this.getCenter = function () {
    return this.map.getCenter();
  };
  
  this.setZoom = function (zoom) {
    this.map.setZoom(parseInt(zoom));
  };
  
  this.getZoom = function () {
    return this.map.getZoom();
  };
  
  this.getBounds = function () {
    return this.map.getBounds();
  };
  
  this.addObjectToMap = function (object) {
    object.setMap(self.map);
  };
  
  this.removeObjectFromMap = function (object) {
    object.setMap(null);
  };
  
  this.addListenerToObject = function (object, event_name, listener) {
    //add custom listener
    if (isDefined(listener)) return google.maps.event.addListener(object, event_name, listener);
  };
  
  this.removeAllListenersFromObject = function (object, event_name) {
    //noinspection JSUnresolvedFunction
    google.maps.event.clearInstanceListeners(object, event_name);
  };
  
  this.removeListenerFromObject = function (object, event_name, listenerGuard) {
    if (!listenerGuard) return false;
    //noinspection JSUnresolvedFunction
    google.maps.event.removeListener(listenerGuard);
    
    return true;
  };
  
  this.getNewClusterer = function (map, clusterer_size) {
    //add new marker clusterer (For Marker Grouping)
    return new MarkerClusterer(map, [], {
      imagePath  : '/images/maps/google-cluster/m',
      maxZoom    : 18,
      zoomOnClick: true,
      gridSize   : clusterer_size
    });
  };
  
  this.getLength = function (arrayOfPoints) {
    //noinspection JSUnresolvedVariable,JSUnresolvedFunction
    return Math.round(google.maps.geometry.spherical.computeLength(arrayOfPoints));
  };
  
  this.getDistanceBeetween = function (latLng1, latLng2) {
    return google.maps.geometry.spherical.computeDistanceBetween(latLng1, latLng2);
  };
  
  this.getMapType = function () {
    return this.map.getMapTypeId();
  };
  
  this.animatePolyline = function (setup, polyline) {
    
    var polylineColor = (polyline.COLOR) ? aColorPalette.getColorHex(polyline.COLOR) : aColorPalette.getNextColorHex();
    polylineColor = polyline.HEXCOLOR ? polyline.HEXCOLOR : polylineColor;

    if (setup) {
      //Process route polyline
      var lineSymbol = {
        path       : google.maps.SymbolPath.CIRCLE,
        scale      : 8,
        strokeColor: polylineColor
      };
      
      polyline.icons = [{
        icon  : lineSymbol,
        offset: '100%'
      }];
      
      return true;
    }
    
    
    makeAnimatedCircleOnLine(polyline);
    
    function makeAnimatedCircleOnLine(line) {
      var count   = 0;
      var handler = 0;
      
      function nextTick() {
        count = (count + 1) % 200;
        
        // Get icon
        var icons = line.get('icons');
        if (!icons) {
          if (handler != 0) window.clearInterval(handler);
          return false;
        }
        
        // Modify
        icons[0].offset = (count / 2) + '%';
        
        // Set icon
        line.set('icons', icons);
      }
      
      handler = window.setInterval(nextTick, 200);
    }
  };
  
  this.getLengthForPath = function(path){
    return  google.maps.geometry.spherical.computeLength(path.getArray());
  };
  
  function getMapView(CONF_MAPVIEW) {
    switch (CONF_MAPVIEW) {
      case 'SATELLITE' :
        return google.maps.MapTypeId.SATELLITE;
        break;
      case 'HYBRID' :
        return google.maps.MapTypeId.HYBRID;
        break;
      case  'TERRAIN' :
        return google.maps.MapTypeId.TERRAIN;
        break;
      default:
        return google.maps.MapTypeId.ROADMAP;
        break;
    }
  }
}

AMap.prototype = map;

function MarkerBuilder(map) {
  this._marker = {};
  
  this._marker.type = 'default';
  
  this._marker.map       = map;
  this._marker.position  = null;
  this._marker.draggable = false;
  this._marker.clickable = true;
  
  this.setId = function (id) {
    this._marker.id = id;
    return this;
  };
  
  this.setTitle = function (title) {
    this._marker.title = title || '';
    return this;
  };
  
  this.setLabel = function (label) {
    if (typeof label != 'undefined') {
      this._marker.label = label;
      if (this._marker.icon) //defines position of marker Label according to top-left corner
        this._marker.icon.labelOrigin = new google.maps.Point(35, 35);
    }
    return this;
  };
  
  this.setIcon = function (fileName, sizeArr, marker_color) {
    var width  = 32;
    var height = 37;
    var name   = '';
    
    if (typeof sizeArr !== 'undefined') {
      width  = sizeArr[0];
      height = sizeArr[1];
    }

    /* Strange piece of code TODO: Check if it is still required*/
    if (marker_color != null) {
      let colorIcon = new google.maps.MarkerImage(
        "http://chart.apis.google.com/chart?chst=d_map_pin_letter&chld=%E2%80%A2|" + marker_color,
        new google.maps.Size(width, height)
      );

      this._marker.icon = colorIcon;
      return this;
    }
    else if (fileName === 'default_green') {
      return this;
    }
    else if (fileName !== 'null') {
      this._marker.type = fileName;
      name              = this.getIconFileName(fileName);
    }
    else {
      name = fileName;
    }
    
    //noinspection JSUnresolvedFunction,JSUnresolvedFunction
    this._marker.icon = new google.maps.MarkerImage(
        name,
        new google.maps.Size(width, height)
    );
    
    return this;
  };
  
  this.setIconOffset = function (offsetArr) {
    if (!this._marker.icon) return this;
    
    this._marker.icon.anchor = new google.maps.Point(offsetArr[0], offsetArr[1]);
    return this;
  };
  
  this.setType = function (type, sizeArr) {
    return this.setIcon(type, sizeArr);
  };
  
  this.setPosition = function (latLng) {
    this._marker.position = latLng;
    return this;
  };
  
  this.setInfoWindow = function (infoWindow) {
    this._marker._infoWindow = infoWindow;
    return this;
  };
  
  this.setNavigation = function (address) {
    var addr = address || _MAKE_ROUTE;
    
    this._marker._infoWindow += aNavigation.getNavigationLink(addr);
    
    return this;
  };
  
  this.setAnimation = function (animationName) {
    var animation;
    switch (animationName) {
      case 'DROP':
        //noinspection JSUnresolvedVariable
        animation = google.maps.Animation.DROP;
        break;
      default:
        throw new Error('Unknown animation: ' + animationName);
    }
    this._marker.animation = animation;
    return this;
  };
  
  this.setDraggable = function (boolean) {
    this._marker.draggable = boolean;
    return this;
  };
  
  this.setDynamic = function (boolean) {
    this._marker.dynamic = boolean;
    return this;
  };
  
  this.setClickable = function (boolean) {
    this._marker.clickable = boolean;
    return this;
  };
  
  this.setMetaInformation = function (object) {
    this._marker.metaInfo = object;
    return this;
  };
  
  this.build = function () {
    if (this._marker.position === 'null') {
      throw new Error("Position not set");
    }
    
    if (this._marker.map === 'null') {
      this._marker.map = map;
    }
    
    if (this._marker.title === 'null') {
      this._marker.title = '';
    }
    
    //noinspection JSUnresolvedFunction
    var result = new google.maps.Marker(this._marker);
    
    result.latLng = {
      lat: result.position.lat,
      lng: result.position.lng
    };
    
    if (this._marker.id) {
      result.id = this._marker.id;
    }
    
    //create infowindow
    if (this._marker._infoWindow) {
      infoWindows[this._marker.id] = new InfoWindowBuilder()
          .setMarker(this._marker)
          .setContent(this._marker._infoWindow)
          .build();
    }
    
    if (this._marker.clickable && this._marker._infoWindow) {
      google.maps.event.addListener(result, 'click', function () {
        closeInfoWindows();
        
        //open _infoWindow for current marker;
        //infoWindows[id].open(map, markers[id]);
        var infoWindow = this._infoWindow;
        infoWindow.setContent(infoWindow.content);
        
        //open infowindow
        openedInfoWindows.push(infoWindow);
        infoWindow.open(map, this);
      });
      result._infoWindow = infoWindows[this._marker.id];
    }
    
    if (this._marker.draggable && this._marker.type === 'user') {
      google.maps.event.addListener(result, 'dragend', function (event) {
        mapCenterLatLng = event.latLng;
      });
    }
    
    //if this marker is not an DB object, add it to second Clusterer
    if (this._marker.dynamic) {
      if (!markerHolder) markerHolder = aMap.getNewClusterer(map, CLUSTERER_GRID_SIZE);
      markerHolder.addMarker(result);
    }
    
    //clear
    this._marker = {};
    return result;
  };
  
  this.getIconFileName = function (fileName) {
    var name = fileName;
    
    //Check if it is not an external URL
    if (fileName.indexOf('://') == -1 && fileName.indexOf('images') == -1)
      name = OPTIONS['ICONS_DIR'] + fileName + '.png';
    
    return name;
  };
  
}

var CircleBuilder = (function () {
  
  function build(Circle) {
    
    return new google.maps.Circle({
      map   : null,
      center: {lat: +Circle.COORDX, lng: +Circle.COORDY},
      radius: +Circle.RADIUS
    });
    
  }
  
  return {
    build: build
  }
  
})();

var PolylineBuilder = (function () {
  
  function build(object) {
    //noinspection JSUnresolvedFunction
    var polyline = new google.maps.Polyline(object);
    var First_infowindow = '';
    var Main_info = '';
    if (isDefined(polyline['INFOWINDOW'])) {
        // onclick='addNewSomething({ layer_id : 10, object_id : $polyline->{object_id} })'>
      google.maps.event.addListener(polyline, 'click', function (event) {
        closeInfoWindows();


        if (!polyline['RESEARVE']) {
          First_infowindow = polyline['INFOWINDOW'];
        }
        var onClick = '';
        if (!polyline['RESEARVE']) {
            latitude = event.latLng.lat();
            longitude = event.latLng.lng();
            onClick = "onclick='addNewReserver({ layer_id :" + polyline['LAYER_ID'] + ", object_id :" + polyline['OBJECT_ID'] +
                ", lat :" + latitude + ", lng :" + longitude + ", link :\"" + polyline['INSIDE_LINK'] + "\"})'";
            polyline['INFOWINDOW'] += "<button class='btn btn-success'" + onClick + ">" + polyline['ADD_RESERVER'] + "</button>";
            polyline['RESEARVE'] = 1;
        }
        else {
            polyline['INFOWINDOW'] = First_infowindow;
            latitude = event.latLng.lat();
            longitude = event.latLng.lng();
            onClick = "onclick='addNewReserver({ layer_id :" + polyline['LAYER_ID'] + ", object_id :" + polyline['OBJECT_ID'] +
                ", lat :" + latitude + ", lng :" + longitude + ", link :\"" + polyline['INSIDE_LINK'] + "\"})'";
            polyline['INFOWINDOW'] += "<button class='btn btn-success'" + onClick + ">" + polyline['ADD_RESERVER'] + "</button>";
            polyline['RESEARVE'] = 1;
        }

        Main_info = polyline['INFOWINDOW'];

        if (polyline['ADD_WELL_LINK']) {
          latitude = event.latLng.lat();
          longitude = event.latLng.lng();
          var add_click = "onclick='catCableToWell({ layer_id :" + polyline['LAYER_ID'] + ", cable_id :" + polyline['CABLE_ID'] +
              ", lat :" + latitude + ", lng :" + longitude + ", link :\"" + polyline['ADD_WELL_LINK'] + "\"})'";
          polyline['INFOWINDOW'] = Main_info + " <button class='btn btn-danger'" + add_click + ">" + polyline['CABLE_CAT'] + "</button>";
        }


        var infowindow = new InfoWindowBuilder(object)
            .setPosition(event.latLng)
            .setContent(this['INFOWINDOW'])
            // Build returns maps.google.InfoWindow
            .build();

        openedInfoWindows.push(infowindow);
        infowindow.open(map);
      });
    }
    
    return polyline;
  }
  
  return {
    build: build
  }
  
})();


var PolygonBuilder = (function () {
  
  var defaults = {
    strokeColor  : aColorPalette.getNextColorHex(),
    strokeOpacity: 0.8,
    strokeWeight : 2,
    fillColor    : aColorPalette.getCurrentColorHex(),
    fillOpacity  : 0.35
  };
  
  function build(object) {
    var res = $.extend({}, defaults, object);
    
    var polygon = new google.maps.Polygon(res);
    
    if (isDefined(object['INFO']) && object['INFO']) {
      
      google.maps.event.addListener(polygon, 'click', function (event) {
        closeInfoWindows();
        
        var infowindow = new InfoWindowBuilder(object)
            .setPosition(event.latLng)
            .setContent(this['INFO'])
            // Build returns maps.google.InfoWindow
            .build();
        
        openedInfoWindows.push(infowindow);
        infowindow.open(map);
      });
    }
    return polygon;
  }
  
  return {
    build: build
  }
  
})();

var SymbolBuilder = (function () {
  
  function build(object) {
    var objectColor = (object.COLOR) ? aColorPalette.getColorHex(object.COLOR) : aColorPalette.getNextColorHex();
    
    return {
      path       : google.maps.SymbolPath[(object.path)],
      scale      : 8,
      strokeColor: objectColor
    }
  }
  
  
  return {
    build: build
  }
  
})();

function InfoWindowBuilder(marker) {
  
  this._infoWindow = {};
  
  if (marker)
    this._infoWindow.position = marker.position;
  
  this._infoWindow.content = '';
  
  this.setPosition = function (latLng) {
    this._infoWindow.position = latLng;
    return this;
  };
  
  this.getPosition = function () {
    return this._infoWindow.position;
  };
  
  this.setMarker = function (markerObj) {
    this._infoWindow.position = markerObj.position;
    this._infoWindow.content  = markerObj.title;
    
    return this;
  };
  
  this.setContent = function (text) {
    this._infoWindow.content = text;
    
    return this;
  };
  
  this.build = function () {
    var result = new google.maps.InfoWindow(this._infoWindow);
    
    this._infoWindow = {};
    
    return result;
  };
}


function Navigation(map) {
  var self = this;
  
  this.init = function (map) {
    this.directionsService = new google.maps.DirectionsService;
    this.directionsDisplay = new google.maps.DirectionsRenderer;
    this.directionsDisplay.setMap(map)
  };
  
  if (map) {
    this.init(map);
  }
  
  this.getNavigationLink = function (string) {
    return '<br/><hr/><br/>' + '<div class="text-center">' +
        '<a onclick="aNavigation.createNavigationRoute(mapCenterLatLng, openedInfoWindows[openedInfoWindows.length - 1].position)">' +
        '<span class="fa fa-share-alt"></span>&nbsp;' +
        string +
        '</a>' +
        '</div>';
  };
  
  this.createNavigationRoute = function (origin, destination, callback) {
    var request = ({
      origin     : origin,
      destination: destination,
      travelMode : google.maps.TravelMode.DRIVING,
      unitSystem : google.maps.UnitSystem.METRIC
    });
    
    this.directionsService.route(request, function (response, status) {
      if (status === google.maps.DirectionsStatus.OK) {
        aNavigation.directionsDisplay.setDirections(response);
        if (callback) {
          callback(response);
        }
      } else {
        window.alert('[ Navigation ] Directions request failed due to ' + status);
        console.log(google.maps.DirectionsStatus);
      }
    });
  };
  
  this.showRoute = function () {
    if (!HAS_REAL_POSITION) {
      getLocation(function (positionArr) { //success
        var lat = positionArr[0];
        var lng = positionArr[1];
        
        var latLng = aMap.createPosition(lat, lng);
        
        self.createNavigationRoute(latLng, aMap.getCenter());
      }, function () { //error
        alert("Can't get your real position");
      })
    } else {
      self.createNavigationRoute(realPosition, aMap.getCenter());
    }
  };
  
  this.createExtendedRoute = function (destination) {
    
    if (HAS_REAL_POSITION) {
      
      getLocation(function (positionArr) { //success
        var lat = positionArr[0];
        var lng = positionArr[1];
        
        var latLng = aMap.createPosition(lat, lng);
        
        self.createNavigationRoute(latLng, destination, function (response) {
          var leg = response.routes[0].legs[0];
          
          var distance = leg.distance.text;
          var duration = leg.duration.text;
          
          var start_address = leg.start_address;
          var end_address   = leg.end_address;
          
          var body = '' +
              '<label>' + _START + ':&nbsp;</label>' + '<span>' + start_address + '</span><br />' +
              '<label>' + _END + ':&nbsp;</label>' + '<span>' + end_address + '</span><br />' +
              '<label>' + _DISTANCE + ':&nbsp;</label>' + '<span>' + distance + '</span><br />' +
              '<label>' + _DURATION + ':&nbsp;</label>' + '<span>' + duration + '</span><br />';
          
          aModal.clear()
              .setHeader(_ROUTE)
              .setBody(body)
              .show();
        })
      });
    }
    else {
      console.warn('[ Navigation ]', 'No real position');
    }
  }
  
}

function Search() {
  this.service     = null;
  this.ready       = false;
  this.isAvailable = true;
  /**
   * Provides NearbySearch for defined types: atm, bank, etc
   * @param map
   */
  this.init = function (map) {
    //noinspection JSUnresolvedFunction,JSUnresolvedVariable
    this.service = new google.maps.places.PlacesService(map);
    this.ready   = true;
  };
  
  this.isReady = function () {
    return this.ready;
  };
  
  this.makeNearbySearch = function (objectTypes, location) {
    if (!this.ready) this.init(map);
    this.service.nearbySearch({
      location: location,
      radius  : 5000,
      types   : objectTypes
    }, callbackDefault);
    
  };
  
  /** Provides searching for a keywords
   * Query can be a text */
  this.makeQuerySearch = function (query, location) {
    if (!this.ready) this.init(map);
    if (query) {
      var request = {
        location: location,
        radius  : '5000',
        query   : query
      };
      
      this.service.textSearch(request, callbackDefault);
    }
  };
  
  /** Callback for search */
  function callbackDefault(results, status) {
    //noinspection JSUnresolvedVariable
    if (status === google.maps.places.PlacesServiceStatus.OK) {
      for (var i = 0; i < results.length; i++) {
        
        // Swap coordinates
        //var temp                         = results[i].geometry.location.lat;
        //results[i].geometry.location.lat = results[i].geometry.location.lng;
        //results[i].geometry.location.lng = temp;
        
        createDefaultMarker(results[i], FORM['ICON']);
      }
    }
  }
  
}

function TxtOverlay(pos, txt, cls, map) {
  
  // Now initialize all properties.
  this.pos  = pos;
  this.txt_ = txt;
  this.cls_ = cls;
  this.map_ = map;
  
  // We define a property to hold the image's
  // div. We'll actually create this div
  // upon receipt of the add() method so we'll
  // leave it null for now.
  this.div_ = null;
  
  // Explicitly call setMap() on this overlay
  this.setMap(map);
}

Events.on('mapsloaded', function () {
  
  //noinspection JSUnresolvedFunction
  TxtOverlay.prototype = new google.maps.OverlayView();
  
  TxtOverlay.prototype.onAdd    = function () {
    
    // Note: an overlay's receipt of onAdd() indicates that
    // the map's panes are now available for attaching
    // the overlay to the map via the DOM.
    
    // Create the DIV and set some basic attributes.
    var div       = document.createElement('DIV');
    div.className = this.cls_;
    
    div.innerHTML = this.txt_;
    
    // Set the overlay's div_ property to this DIV
    this.div_             = div;
    //noinspection JSUnresolvedFunction
    var overlayProjection = this.getProjection();
    //noinspection JSUnresolvedFunction
    var position          = overlayProjection.fromLatLngToDivPixel(this.pos);
    div.style.left        = position.x + 'px';
    div.style.top         = position.y + 'px';
    // We add an overlay to a map via one of the map's panes.
    
    var panes = this.getPanes();
    panes.floatPane.appendChild(div);
  };
  TxtOverlay.prototype.draw     = function () {
    
    //noinspection JSUnresolvedFunction
    var overlayProjection = this.getProjection();
    
    // Retrieve the southwest and northeast coordinates of this overlay
    // in latlngs and convert them to pixels coordinates.
    // We'll use these coordinates to resize the DIV.
    //noinspection JSUnresolvedFunction
    var position = overlayProjection.fromLatLngToDivPixel(this.pos);
    
    
    var div        = this.div_;
    div.style.left = position.x + 'px';
    div.style.top  = position.y + 'px';
    
    
  };
//Optional: helper methods for removing and toggling the text overlay.
  TxtOverlay.prototype.onRemove = function () {
    this.div_.parentNode.removeChild(this.div_);
    this.div_ = null;
  };
  TxtOverlay.prototype.hide     = function () {
    if (this.div_) {
      this.div_.style.visibility = "hidden";
    }
  };
  
  TxtOverlay.prototype.show = function () {
    if (this.div_) {
      this.div_.style.visibility = "visible";
    }
  };
  
  TxtOverlay.prototype.toggle = function () {
    if (this.div_) {
      if (this.div_.style.visibility == "hidden") {
        this.show();
      } else {
        this.hide();
      }
    }
  };
  
  TxtOverlay.prototype.toggleDOM = function () {
    if (this.getMap()) {
      this.setMap(null);
    } else {
      this.setMap(this.map_);
    }
  };
});


function DrawController() {
  var self = this;
  
  self.inited = false;
  
  this.aObjectRegistrator = new AObjectRegistrator();
  
  this.options = {
    drawingControl       : false,
    drawingControlOptions: {}
  };
  
  this.callback = function (e) {
    var mapObject    = this.aObjectRegistrator.getMapObject();
    mapObject.latLng = e.position;
    
    console.log('default callback');
  };
  
  this.drawingManager = null;
  this.map            = null;
  
  this.setControlsEnabled = function (boolean) {
    if (!this.inited) {
      this.options.drawingControl = boolean;
    }
    else {
      console.warn('[ DrawController ]', 'Already initialized');
      return false;
    }
    return this;
  };
  
  this.setCallback = function (callback) {
    this.callback = callback;
    return this;
  };
  
  this.getCallback = function () {
    return this.callback;
  };
  
  this.setMapObject = function (aMapObject) {
    this.aObjectRegistrator.setMapObject(aMapObject);
  };
  
  this.init = function (map) {
    this.options.map                                = map;
    this.options.drawingControlOptions.drawingModes = ['marker', 'polyline', 'rectangle', 'circle', 'polygon'];
    
    this.drawingManager = new google.maps.drawing.DrawingManager(this.options);
    
    self.inited = true;
    return this;
  };
  
  this.getObjectRegistrator = function () {
    return this.aObjectRegistrator;
  };
  
  this.clearDrawingMode = function () {
    google.maps.event.clearInstanceListeners(this.drawingManager);
    this.drawingManager.setDrawingMode(null);
    
  };
  
  this.setDrawingMode = function (string) {
    if (this.drawingManager == null)
      throw new Error("[ ADrawingManager ] drawingManager not initialized");
    
    console.log('[ ADrawingManager ]', 'setDrawingMode', string);
    
    var drawingMode = '';
    switch (string) {
      case null:
        drawingMode = null;
        google.maps.event.clearInstanceListeners(self.getDrawingManager());
        break;
      case POINT:
      case MARKER:
      case MARKERS:
      case CUSTOM_POINT:
        drawingMode = google.maps.drawing.OverlayType.MARKER;
        break;
      case LINE:
      case MARKERS_POLYLINE:
      case POLYLINE:
        drawingMode = google.maps.drawing.OverlayType.POLYLINE;
        break;
      case POLYGON:
        drawingMode = google.maps.drawing.OverlayType.POLYGON;
        break;
      case CIRCLE:
      case MARKER_CIRCLE:
        drawingMode = google.maps.drawing.OverlayType.CIRCLE;
        break;
      case MULTIPLE:
        drawingMode = MULTIPLE;
        break;
      default:
        console.warn('Unsupported drawing mode: ' + string);
    }
    this.drawingManager.setDrawingMode(drawingMode);
    
    addListener(drawingMode);
  };
  
  this.getDrawingManager = function () {
    return this.drawingManager;
  };
  
  this.setLayerId = function (layer_id) {
    this.layer_id = layer_id;
    return this;
  };
  
  this.getLayerId = function () {
    return this.layer_id;
  };
  
  this.setIcon = function (icon_string) {
    if (isDefined(icon_string)) {
      
      this.options.markerOptions = {icon: icon_string};
    }
    return this;
  };
  
  function addListener(type) {
    var objectType = type;
    
    //removing prev listeners
    google.maps.event.clearInstanceListeners(self.getDrawingManager());
    if (type == null) return true;
    
    console.log('[ ADrawingManager ]', 'Adding listener type', type);
    //adding current listener
    google.maps.event.addListener(self.getDrawingManager(), 'overlaycomplete', function (e) {
      
      console.log('[ ADrawingManager ]', 'overlaycomplete callback');
      
      //Get defined callback
      var cb = self.getCallback();
      //Call
      cb(e, objectType);
      
      //Disable drawing mode
      Events.once('currentmapobjectfinished', function () {
        self.setDrawingMode(null);
      });
    });
    
  }
}

function addNewReserver(marker) {
    var id       = marker.object_id || marker.OBJECT_ID;
    var layer_id = marker.layer_id || marker.LAYER_ID;
    var lng = marker.lng;
    var lat = marker.lat;

    if (!(layer_id && id && lng && lat)) {
        console.warn('No layer id or id or lng or lat', layer_id, id, marker, lng, lat);
        return false;
    }

    marker.link += "&object_id=" + id + "&layer_id=" + layer_id + "&lng=" + lng + "&lat=" + lat;
    loadToModal(marker.link);
    MapLayers.refreshLayer(WELL_LAYER_ID);
    MapLayers.refreshLayer(CABLE_LAYER_ID);
}

function catCableToWell(marker) {
    var id       = marker.cable_id || marker.CABLE_ID;
    var layer_id = marker.layer_id || marker.LAYER_ID;
    var lng = marker.lng;
    var lat = marker.lat;

    if (!(layer_id && id && lng && lat)) {
        console.warn('No layer id or id or lng or lat', layer_id, id, marker, lng, lat);
        return false;
    }

    marker.link += "&object_id=" + id + "&layer_id=" + layer_id + "&lng=" + lng + "&lat=" + lat;
    loadToModal(marker.link);
    MapLayers.refreshLayer(WELL_LAYER_ID);
    MapLayers.refreshLayer(CABLE_LAYER_ID);
}

function drawDistanceGoogle (objects, lat, lng) {
    var directionsService = new google.maps.DirectionsService;
    var directionsDisplay = new google.maps.DirectionsRenderer;

    var distance_main = {
        'index': 0,
        'distance': 0,
        'routes': '',
        'responce': ''
    };

    $.each(objects, function (i, mapObject) {
        directionsService.route({
            origin: new google.maps.LatLng(mapObject['MARKER'].COORDX, mapObject['MARKER'].COORDY),
            destination: new google.maps.LatLng(lat,lng),
            travelMode: 'WALKING'
        }, function (response, status) {
            if (status == google.maps.DirectionsStatus.OK) {
                let distance_one = response.routes[0].legs[0].distance.value;
                if (distance_one < distance_main.distance || !distance_main.distance){
                    distance_main.distance = distance_one;
                    distance_main.index = i;
                    distance_main.routes = response.routes[0].legs[0];
                    distance_main.responce = response;
                }

                if (i === objects.length - 1) {
                    directionsDisplay.setDirections(distance_main.responce);
                    directionsDisplay.setOptions({
                        draggable: false,
                        suppressInfoWindows: false,
                        suppressMarkers: true
                    });

                    var infowindow = new google.maps.InfoWindow();
                    infowindow.setContent(distance_main.routes.distance.text + "<br>" + distance_main.routes.duration.text + " ");
                    infowindow.setPosition(distance_main.routes.steps[0].end_location);
                    infowindow.open(aMap.map);

                    directionsDisplay.setMap(aMap.map);
                    directionsDisplay.setOptions( { suppressMarkers: true } );
                }
            }
        });
    });
}
