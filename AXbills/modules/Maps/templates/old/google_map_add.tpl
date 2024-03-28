<script type='text/javascript' src='https://maps.google.com/maps/api/js?%MAP_API_KEY%sensor=false'></script>
<style type='text/css'>
	body { font-family: Arial, sans serif; font-size: 11px; }
	#hand_b { width:31px; height:31px; background-image: url(/img/google_map/Bsu.png); }
	#hand_b.selected { background-image: url(/img/google_map/Bsd.png); }
	#placemark_b { width:31px; height:31px; background-image: url(/img/google_map/Bmu.png); }
	#placemark_b.selected { background-image: url(/img/google_map/Bmd.png); }
	#placeroute_b { width:31px; height:31px; background-image: url(/img/google_map/Blu.png); }
	#placeroute_b.selected { background-image: url(/img/google_map/Bld.png); }
	#line_b { width:31px; height:31px; background-image: url(/img/google_map/Blu.png); }
	#line_b.selected { background-image: url(/img/google_map/Bld.png); }
	#placedistrict { width:31px; height:31px; background-image: url(/img/google_map/Bpu.png); }
	#placedistrict.selected { background-image: url(/img/google_map/Bpd.png); }
	#addroute { width:31px; height:31px; background-image: url(/img/google_map/addr.png); }
	#addroute:hover { width:31px; height:31px; background-image: url(/img/google_map/addrh.png); }
	#MarkerInfoWindow a {text-decoration:none;}
	#MarkerInfoWindow a:hover { font-weight:800;}
	.show {display:block;}
	.hide {display:none;}
</style>

<script type='text/javascript'>
var COLORS = [
  ['red', '#ff0000'], ['orange', '#ff8800'], ['green','#008000'],
              ['blue', '#000080'], ['purple', '#800080']];
var options = {};
var map;
var myLatlng;
var myOptions;
var PolyInfoWindow = null;
var Marker = null;
var listener = null;
var infowindow;
var MapSetCenter = '%MAPSETCENTER%' || '';

var MapView = google.maps.MapTypeId.ROADMAP; 


if('$conf{MAP_VIEW}' == 'SATELLITE'){
  MapView = google.maps.MapTypeId.SATELLITE; 
}
else if('$conf{MAP_VIEW}' == 'HYBRID') {
  MapView = google.maps.MapTypeId.HYBRID; 
}

else if('$conf{MAP_VIEW}' == 'TERRAIN') {
  MapView = google.maps.MapTypeId.TERRAIN; 
}


function select(buttonId) {
  document.getElementById('hand_b').className='unselected';
  document.getElementById('placemark_b').className='unselected';
  document.getElementById(buttonId).className='selected';
}

function stopEditing() {
	
  if(listener) {
    google.maps.event.removeListener(listener);
  }
  select('hand_b');
}

function getColor(named) {
  return COLORS[(colorIndex_++) % COLORS.length][named ? 0 : 1];
}

function getIcon(color) {
  var icon = new google.maps.MarkerImage('/img/google_map/' + color + '.png',
      new google.maps.Size(32, 32),
      new google.maps.Point(0,0),
      new google.maps.Point(15, 32));
  return icon;
}

function placeMarker() {
  select('placemark_b');

   listener = google.maps.event.addListener(map, 'click', function(e) {

   if (PolyInfoWindow) {
		PolyInfoWindow.close();
	}
   
      select('hand_b');
      google.maps.event.removeListener(listener);
      var coordx = e.latLng.lng();
      var coordy = e.latLng.lat();
      var zoom   = map.zoom;
      
      if(Marker) {
      	Marker.setMap(null);
      }
      
      Marker = new google.maps.Marker({
        position: e.latLng,
        draggable: false,
        icon: getIcon('blue'),
        map: map
      });
       var contentString =; \"<div id=\'MarkerInfoWindow\'><a href=index.cgi?index=$index\" + \"%BUILD_QUICK_ADD%\" + \"&coordx=\" + coordx + \"&coordy=\" + coordy + \" > _{ADD_HOUSE}_ </a><br><a href=index.cgi?index=$index&DCOORDX=\" + coordx + \"&DCOORDY=\" + coordy + \"&ZOOM=\" + zoom + \" > _{ADD_DISTRICT}_ </a><br><a href=index.cgi?index=$index&coordlx=\" + coordx + \"&coordly=\" + coordy + \"> _{ADD_ROUTE}_ </a><br><a href=index.cgi?index=$index&coordwx=\" + coordx + \"&coordwy=\" + coordy + \"> _{ADD_WIFI_ZONE}_ </a><br><a href=index.cgi?index=$index&coordwellx=\" + coordx + \"&coordwelly=\" + coordy + \"> _{ADD_WELL}_ </a></div>\";
 
      infowindow = new google.maps.InfoWindow({
        content: contentString
      });
      
      google.maps.event.addListener(Marker, 'click', function(e) {
	    if (PolyInfoWindow) {
          PolyInfoWindow.close();
        }
        infowindow.open(map,Marker);
	  });
	  infowindow.open(map,Marker);
  });
}
function show_wifi_optios() {
	//document.onload.getElementById('show_wifi_optios').className='show';
}

function initialize() {        
    if (MapSetCenter != '') {
       MapSetCenter = MapSetCenter.split(', ');
       myLatlng = new google.maps.LatLng(MapSetCenter[1], MapSetCenter[0]);
       myOptions = {
         zoom: parseInt(MapSetCenter[2]),
         center: myLatlng,
         mapTypeId: MapView,
       }	
	}
	else {
        myLatlng = new google.maps.LatLng(50.43185060963318, 30.47607421875);
        myOptions = {
          zoom: 5,
          center: myLatlng,
          mapTypeId: MapView
        }			
    }
	map = new google.maps.Map(document.getElementById('map'), myOptions);

 %ROUTES% 

    select('hand_b');
}
function chgposition (x, y , zoom) {
	map.setCenter(new google.maps.LatLng(y, x));
	map.setZoom(zoom);
}
google.maps.event.addDomListener(window, 'load', initialize);
</script>


<table>
  <tr style='vertical-align:top'>
    <td style='width:15em'><table>
        <tr>
          <td><div id='hand_b' onclick='stopEditing()'></div></td>
          <td><div id='placemark_b' onclick='placeMarker()' title='_{ADD_HOUSE}_'></div></td>
            <td>
                <div id='addroute' onclick=location.href='index.cgi?index=$index&route=add';
                     title='_{CREATE_EDIT_ROUTE};_'></div>
            </td>
        </tr>
      </table>
      <p> </p>
      <table id ='featuretable'>
        <tbody id='featuretbody'>
        </tbody>
      </table>
      <hr />
      <br />
      <div align=center>%DISTRICTS%</div></td>
    <td><!-- The frame used to measure the screen size -->
      
      <div id='frame'></div>
      <div id='map' style='width: 800px; height: 500px'></div></td>
  </tr>
</table>
