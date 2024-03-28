
 
	var latlng = new GLatLng(%MAP_Y%, %MAP_X% );
	var Mcolor;
	var thOnline;
	Mcolor = 'green';

	map.addOverlay(createMarker(latlng, '<strong>_{STREET}_: </strong>%STREET_ID%<br /><strong>_{BUILD}_: </strong>%NUMBER%<br /><strong>', Mcolor));
	    